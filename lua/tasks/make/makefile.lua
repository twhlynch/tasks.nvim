local M = {}

--- @param bufnr integer
--- @return Tasks.Task[]
function M.tasks(bufnr) ---@diagnostic disable-line: unused-local
	--- incredible https://stackoverflow.com/a/26339924
	local output = vim.fn.systemlist([=[
		LC_ALL=C make -pRrq : 2>/dev/null \
			| awk -v RS= -F: '/(^|\n)# Files(\n|$)/,/(^|\n)# Finished Make data base/ {
				if ($1 !~ "^[#.]") {print $1}
			}' \
			| sort \
			| grep -E -v -e '^[^[:alnum:]]'
	]=])

	local tasks = {}

	for _, target in ipairs(output) do
		target = target:gsub("^%s+", ""):gsub("%s+$", "")
		if target ~= "" then
			table.insert(tasks, {
				name = target,
				run = function()
					local terminal = require("tasks.terminal")
					terminal.execute_commands({ "make " .. target }, vim.fn.environ(), vim.fn.getcwd())
				end,
			})
		end
	end

	return tasks
end

return M
