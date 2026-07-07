--- @type Tasks.Provider
local M = {}

function M.get_pattern()
	return { "*/.vscode/tasks.json", "*/.vscode/launch.json" }
end

function M.get_ignore()
	return {}
end

function M.get_tasks(bufnr)
	local path = vim.api.nvim_buf_get_name(bufnr)

	if path:match("tasks%.json$") then
		return require("tasks.vscode.tasks_json").tasks(bufnr)
	end

	if path:match("launch%.json$") then
		return require("tasks.vscode.launch_json").tasks(bufnr)
	end

	return {}
end

return M
