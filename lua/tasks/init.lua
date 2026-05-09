local M = {}

--- plugin setup
--- @param opts Tasks.Options.options option overrides
function M.setup(opts)
	require("tasks.options").set(opts)
	require("tasks.tasks").setup()
end

return M
