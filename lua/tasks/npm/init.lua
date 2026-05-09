--- @type Tasks.Provider
local M = {}

function M.get_pattern()
	return { "*/package.json" }
end

function M.get_tasks(bufnr)
	local tasks = {}

	return tasks
end

return M
