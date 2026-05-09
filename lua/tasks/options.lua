local M = {}

--- @class Tasks.Options.options plugin options
--- @field keybind string keybind to run the task at the cursor line

--- @type Tasks.Options.options
M.option = {
	keybind = "<leader><CR>",
}

--- sets plugin options keeping defaults if unspecified
--- @param opts? Tasks.Options.options new options to override defaults
function M.set(opts)
	M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

--- get current options
--- @return Tasks.Options.options
function M.get()
	return M.options
end

return M
