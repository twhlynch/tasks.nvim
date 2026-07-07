--- @type Tasks.Provider
local M = {}

function M.get_pattern()
	return { "*/package.json" }
end

function M.get_ignore()
	return { "node_modules/" }
end

function M.get_tasks(bufnr)
	local path = vim.api.nvim_buf_get_name(bufnr)

	if path:match("package%.json$") then
		return require("tasks.npm.package_json").tasks(bufnr)
	end

	return {}
end

return M
