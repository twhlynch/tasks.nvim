--- @type Tasks.Provider
local M = {}

--- @return string[]
function M.get_files()
	return { "Makefile" }
end

--- @param bufnr integer
--- @return Tasks.Task[]
function M.get_tasks(bufnr)
	local path = vim.api.nvim_buf_get_name(bufnr)

	if path:match("Makefile$") then
		return require("tasks.make.makefile").tasks(bufnr)
	end

	return {}
end

return M
