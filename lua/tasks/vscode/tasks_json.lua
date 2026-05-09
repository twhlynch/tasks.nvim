local utils = require("tasks.utils")
local consts = require("tasks.vscode.consts")

local M = {}

--- @param bufnr integer
--- @return Tasks.Task[]
function M.tasks(bufnr)
	local json = utils.parse_json(bufnr)

	if json == nil then
		return {}
	end

	if json.version ~= consts.tasks_version then
		---@diagnostic disable-next-line: redundant-parameter
		vim.notify(vim.fn.printf(consts.strings.bad_version, json.version, consts.tasks_version), vim.log.levels.WARN)
	end

	if json.tasks == nil or type(json.tasks) ~= "table" then
		return {}
	end

	local tasks = {}

	for _, task in ipairs(json.tasks) do
		if task.label then
			local lnum = utils.find_line(bufnr, "label", task.label)
			if lnum then
				tasks[#tasks + 1] = {
					lnum = lnum,
					run = function()
						M.run(task, json.inputs)
					end,
				}
			end
		end
	end

	return tasks
end

--- @param task vscode.TaskConfig
--- @param inputs vscode.UserInput[]
function M.run(task, inputs)
	vim.notify(vim.inspect(task) .. tostring(#inputs))
end

return M
