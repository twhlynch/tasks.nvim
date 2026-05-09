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

	if json.version ~= consts.launch_version then
		---@diagnostic disable-next-line: redundant-parameter
		vim.notify(vim.fn.printf(consts.strings.bad_version, json.version, consts.launch_version), vim.log.levels.WARN)
	end

	if json.configurations == nil or type(json.configurations) ~= "table" then
		return {}
	end

	local tasks = {}

	for _, task in ipairs(json.configurations) do
		if task.name then
			local lnum = utils.find_line(bufnr, "name", task.name)
			if lnum then
				tasks[#tasks + 1] = {
					lnum = lnum,
					run = function()
						M.run(task)
					end,
				}
			end
		end
	end

	return tasks
end

--- @param task vscode.LaunchConfig
function M.run(task)
	vim.notify(vim.inspect(task))
end

return M
