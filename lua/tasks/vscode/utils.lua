local M = {}

local function get_selected_text()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local ls, cs = start_pos[2], start_pos[3]
	local le, ce = end_pos[2], end_pos[3]

	if ls == 0 or le == 0 then
		return ""
	end

	local lines = vim.api.nvim_buf_get_lines(0, ls - 1, le, false)
	if #lines == 0 then
		return ""
	end

	lines[1] = lines[1]:sub(cs)
	if #lines == 1 then
		lines[1] = lines[1]:sub(1, ce - cs + 1)
	else
		lines[#lines] = lines[#lines]:sub(1, ce)
	end

	return table.concat(lines, "\n")
end

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

	local cwd = vim.fn.getcwd()
	local filepath = vim.fn.expand("%:p")
	local ext = vim.fn.expand("%:e")
	local relpath = vim.fn.expand("%:.")
	local filedir = vim.fn.fnamemodify(filepath, ":h")

	local replacements = {
		["${userHome}"] = vim.fn.expand("~"),
		["${workspaceFolder}"] = cwd,
		["${workspaceFolderBasename}"] = vim.fn.fnamemodify(cwd, ":t"),
		["${file}"] = filepath,
		["${fileWorkspaceFolder}"] = cwd,
		["${relativeFile}"] = relpath,
		["${relativeFileDirname}"] = vim.fn.fnamemodify(relpath, ":h"),
		["${fileBasename}"] = vim.fn.expand("%:t"),
		["${fileBasenameNoExtension}"] = vim.fn.expand("%:t:r"),
		["${fileExtname}"] = ext ~= "" and "." .. ext or "",
		["${fileDirname}"] = filedir,
		["${fileDirnameBasename}"] = vim.fn.fnamemodify(filedir, ":t"),
		["${cwd}"] = cwd,
		["${lineNumber}"] = tostring(vim.fn.line(".")),
		["${columnNumber}"] = tostring(vim.fn.col(".")),
		["${selectedText}"] = get_selected_text(),
		["${execPath}"] = vim.v.progpath,
		["${pathSeparator}"] = "/",
		["${/}"] = "/",
		["${workspaceRoot}"] = cwd,
	}

	for pattern, replacement in pairs(replacements) do
		str = str:gsub(vim.pesc(pattern), replacement)
	end

	-- env variables: ${env:NAME} and $NAME syntax
	str = str:gsub("%${env:([^}]+)}", function(env_var)
		return env[env_var] or ""
	end)
	str = str:gsub("$([%w_]+)", function(env_var)
		return env[env_var] or ""
	end)

	-- find an input option
	str = str:gsub("${input:([^}]+)}", function(id)
		local input = inputs[id]
		if not input then
			return ""
		end
		return M.resolve_input(input)
	end)

	return str
end

--- @param input vscode.UserInput
function M.resolve_input(input)
	-- prompt for user input
	if input.type == "promptString" then
		local prompt = (input.description or input.id) .. ": "

		if input.password then
			local result = vim.fn.inputsecret(prompt)
			return result ~= "" and result or input.default or ""
		end

		local ok, result = pcall(vim.fn.input, prompt, input.default or "")
		if ok then
			return result
		end

		return input.default or ""
	end

	-- prompt to choose an option
	if input.type == "pickString" then
		local items = {}

		for _, opt in ipairs(input.options or {}) do
			if type(opt) == "table" then
				table.insert(items, {
					label = opt.label or tostring(opt.value),
					value = opt.value,
				})
			else
				table.insert(items, {
					label = tostring(opt),
					value = opt,
				})
			end
		end

		local lines = { (input.description or input.id) .. ":" }

		for i, item in ipairs(items) do
			table.insert(lines, "[" .. i .. "] " .. item.label)
		end

		local idx = vim.fn.inputlist(lines)

		if idx >= 1 and idx <= #items then
			return items[idx].value
		end

		return input.default or ""
	end

	return ""
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
