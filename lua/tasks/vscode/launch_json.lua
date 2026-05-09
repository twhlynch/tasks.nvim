local utils = require("tasks.utils")

local M = {}

--- @param bufnr integer
--- @return Tasks.Task[]
function M.tasks(bufnr)
	local json = utils.parse_json(bufnr)

	if json == nil then
		return {}
	end

	vim.notify(vim.inspect(json))

	return {}
end

return M
