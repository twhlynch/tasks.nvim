local utils = require("tasks.utils")
local vsutils = require("tasks.vscode.utils")
local consts = require("tasks.vscode.consts")
local tasks = require("tasks.vscode.tasks_json")
local terminal = require("tasks.terminal")

local M = {}

--- @param bufnr integer
--- @return Tasks.Task[]
function M.tasks(bufnr)
	local json = utils.parse_json(bufnr)
	if not json then
		return {}
	end

	if json.version ~= consts.launch_version then
		---@diagnostic disable-next-line: redundant-parameter
		vim.notify(string.format(consts.strings.bad_version, json.version, consts.launch_version), vim.log.levels.WARN)
	end

	if type(json.configurations) ~= "table" then
		return {}
	end

	local all_tasks = {}

	for _, task in ipairs(json.configurations) do
		if task.name then
			local lnum = utils.find_line(bufnr, "name", task.name)
			if lnum then
				table.insert(all_tasks, {
					name = task.name,
					lnum = lnum,
					run = function()
						M.run(task, bufnr)
					end,
				})
			end
		end
	end

	return all_tasks
end

--- @param config vscode.LaunchConfig
--- @param bufnr integer
function M.run(config, bufnr)
	local tasks_json = M.load_tasks_json(bufnr)
	local inputs_map = {}

	local commands = {}

	local env = vsutils.build_env(config.env or vim.fn.environ(), inputs_map)
	local cwd = vsutils.resolve_vars(config.cwd, inputs_map, env) or vim.fn.getcwd()

	-- queue preLaunchTask entry
	if config.preLaunchTask then
		local task_label = config.preLaunchTask

		-- resolve the special ${defaultBuildTask} variable
		if task_label == "${defaultBuildTask}" then
			task_label = M.resolve_default_build_task(tasks_json)
			if not task_label then
				vim.notify(consts.strings.no_default_build_task, vim.log.levels.WARN)
				return
			end
		end

		local pre_task = tasks_json[task_label]
		if pre_task then
			local pre_cmd = tasks.build_cmd(pre_task, inputs_map, env)
			if pre_cmd then
				table.insert(commands, pre_cmd)
			end
		else
			vim.notify(string.format(consts.strings.task_not_found, config.preLaunchTask), vim.log.levels.WARN)
		end
	end

	-- queue actual launch command
	local launch_cmd = M.build_cmd(config, inputs_map, env)
	if launch_cmd then
		table.insert(commands, launch_cmd)
	end

	if vim.tbl_isempty(commands) then
		return
	end

	terminal.execute_commands(commands, env, cwd)
end

--- load tasks.json from the same folder as the launch config
--- @param bufnr integer
--- @return table<string, vscode.TaskConfig>
function M.load_tasks_json(bufnr)
	-- get matching tasks.json
	local filepath = vim.api.nvim_buf_get_name(bufnr)
	local dir = vim.fn.fnamemodify(filepath, ":h")
	local tasks_path = dir .. "/tasks.json"

	local ok_lines, lines = pcall(vim.fn.readfile, tasks_path)
	if not ok_lines then
		return {}
	end

	local json = utils.parse_json_content(table.concat(lines, "\n"))
	if not json or not json.tasks then
		return {}
	end

	local tasks_map = {}
	for _, task in ipairs(json.tasks) do
		if task.label then
			tasks_map[task.label] = task
		end
	end
	return tasks_map
end

--- find the default build task from the project tasks cache
--- @param project_tasks table<string, vscode.TaskConfig>
--- @return string | nil
function M.resolve_default_build_task(project_tasks)
	return vim.iter(project_tasks):find(function(_, task)
		return type(task.group) == "table" --
			and task.group.kind == "build"
			and task.group.isDefault
	end)
end

--- build command for a launch config
--- @param config vscode.LaunchConfig
--- @param inputs table<string, vscode.UserInput>
--- @param env env
--- @return command | nil
function M.build_cmd(config, inputs, env)
	local exec, args

	if config.type == "extensionHost" then
		exec = config.runtimeExecutable or "code"
		args = config.args
	elseif config.type == "python" or config.type == "debugpy" then
		exec = config.runtimeExecutable or "python3"
		args = vim.list_extend({ config.program }, config.args or {})
	elseif config.type == "cppdbg" then
		exec = config.program
		args = config.args
	else
		exec = config.runtimeExecutable or config.program
		args = config.args
	end

	if not exec then
		vim.notify(consts.strings.missing_program, vim.log.levels.ERROR)
		return nil
	end

	return vsutils.build_cmd(exec, args, inputs, env)
end

return M
