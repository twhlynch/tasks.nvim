local utils = require("tasks.utils")

local M = {}

--- @param bufnr integer
--- @return Tasks.Task[]
function M.tasks(bufnr)
	local json = utils.parse_json(bufnr)
	if not json then
		return {}
	end

	local scripts = json.scripts
	if type(scripts) ~= "table" then
		return {}
	end

	local tasks = {}

	for key, command in pairs(scripts) do
		if type(command) == "string" then
			local lnum = utils.find_line(bufnr, key, command)

			if lnum then
				table.insert(tasks, {
					name = key,
					lnum = lnum,
					run = function()
						local terminal = require("tasks.terminal")
						terminal.execute_commands({ command }, vim.fn.environ(), vim.fn.getcwd())
					end,
				})
			end
		end
	end

	return tasks
end

return M
