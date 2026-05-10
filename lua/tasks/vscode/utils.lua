local M = {}

--- build a command string or array from a command and args
--- @param command string
--- @param args? string[]
--- @param inputs vscode.UserInput
--- @param env env
--- @return command
function M.build_cmd(command, args, inputs, env)
	local cmd = { M.resolve_vars(command, inputs, env) }

	if vim.tbl_isempty(args or {}) then
		-- just the command as a string
		return cmd[1]
	end

	-- add each argument
	for _, arg in ipairs(args or {}) do
		table.insert(cmd, M.resolve_vars(arg, inputs, env))
	end

	-- list of command and args
	return cmd
end

--- resolve vscode, input, and env variables in a string
--- @param str string
--- @param inputs table<string, vscode.UserInput>
--- @param env env
--- @return string | nil
function M.resolve_vars(str, inputs, env)
	if not str then
		return nil
	end

	-- stylua: ignore
	local replacements = {
		["${workspaceFolder}"] =         vim.fn.getcwd(),
		["${file}"] =                    vim.fn.expand("%:p"),
		["${fileDirname}"] =             vim.fn.expand("%:p:h"),
		["${fileBasename}"] =            vim.fn.expand("%:t"),
		["${fileBasenameNoExtension}"] = vim.fn.expand("%:t:r"),
		["${workspaceFolderBasename}"] = vim.fn.fnamemodify(vim.fn.getcwd(), ":t"),
	}

	for pattern, replacement in pairs(replacements) do
		str = str:gsub(vim.pesc(pattern), replacement)
	end

	-- env variables
	str = str:gsub("$([%w_]+)", function(env_var)
		return env[env_var] or ""
	end)

	-- find an input option
	str = str:gsub("${input:([^}]+)}", function(id)
		local input = inputs[id]
		if not input then
			return ""
		end

		if input.type == "promptString" then
			return vim.fn.input((input.description or id) .. ": ", input.default or "")
		end
		return ""
	end)

	return str
end

--- resolve variables in env and add to a merged env
--- @param source_env env
--- @param inputs table<string, vscode.UserInput>
--- @return env
function M.build_env(source_env, inputs)
	---@type env
	local merged = vim.fn.environ()

	for k, v in pairs(source_env) do
		merged[k] = M.resolve_vars(v, inputs, merged)
	end

	return merged
end

--- extract inputs into a mapping
--- @param inputs vscode.UserInput[]
--- @return table<string, vscode.UserInput>
function M.extract_inputs(inputs)
	local map = {}
	for _, input in ipairs(inputs or {}) do
		map[input.id] = input
	end
	return map
end

return M
