local M = {}

--- @alias Tasks.Options.options.runner "floating"|"split"|"vsplit"|"background"|fun(cmd: string)

--- @class Tasks.Options.options plugin options
--- @field keybind string keybind to run the task at the cursor line
--- @field keybind_picker string keybind to open the task picker
--- @field sign_icon string icon to use for signs at runnable lines
--- @field sign_hl string highlight group to use for signs
--- @field providers string[] task providers to enable
--- @field ignore string[] folders to ignore when searching for tasks
--- @field runner Tasks.Options.options.runner how to run tasks

--- @type Tasks.Options.options
M.options = {
	keybind = "<leader><CR>",
	keybind_picker = "<leader>B",
	sign_icon = "▶",
	sign_hl = "DiagnosticFloatingOk",
	providers = {},
	ignore = { "%.git/" },
	runner = "floating",
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
