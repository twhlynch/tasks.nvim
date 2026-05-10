local utils = require("tasks.utils")
local terminal = require("tasks.terminal")
local vsutils = require("tasks.vscode.utils")
local consts = require("tasks.vscode.consts")

local M = {}

--- @param bufnr integer
--- @return Tasks.Task[]
function M.tasks(bufnr)
	local json = utils.parse_json(bufnr)
	if not json then
		return {}
	end

	if json.version ~= consts.tasks_version then
		vim.notify(string.format(consts.strings.bad_version, json.version, consts.tasks_version), vim.log.levels.WARN)
	end

	if type(json.tasks) ~= "table" then
		return {}
	end

	local tasks = {}

	for _, task in ipairs(json.tasks) do
		if task.label then
			local lnum = utils.find_line(bufnr, "label", task.label)
			if lnum then
				table.insert(tasks, {
					lnum = lnum,
					run = function()
						M.run(task, json.inputs)
					end,
				})
			end
		end
	end

	return tasks
end

--- @param task vscode.TaskConfig
--- @param inputs vscode.UserInput[]
function M.run(task, inputs)
	local inputs_map = vsutils.extract_inputs(inputs)

	local env = vsutils.build_env({}, inputs_map)
	local cwd = vim.fn.getcwd()

	if task.options then
		if task.options.env then
			env = vsutils.build_env(task.options.env, inputs_map)
		end
		if task.options.cwd then
			cwd = vsutils.resolve_vars(task.options.cwd, inputs_map, env) or cwd
		end
	end

	local cmd = M.build_cmd(task, inputs_map, env)
	if not cmd then
		return
	end

	terminal.execute_commands({ cmd }, env, cwd)
end

--- build command for a task config
--- @param config vscode.TaskConfig
--- @param inputs table<string, vscode.UserInput>
--- @param env env
--- @return command | nil
function M.build_cmd(config, inputs, env)
	local command, args

	if config.type == "npm" then
		if not config.script then
			vim.notify(consts.strings.missing_script, vim.log.levels.ERROR)
			return nil
		end
		command = "npm"
		args = vim.list_extend({ "run", config.script }, config.args or {})
	elseif config.type == "shell" or config.type == "process" then
		if not config.command then
			vim.notify(consts.strings.missing_command, vim.log.levels.ERROR)
			return nil
		end
		command = config.command
		args = config.args
	end

	if command then
		return vsutils.build_cmd(command, args, inputs, env)
	end
end

return M
