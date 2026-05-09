local consts = require("tasks.consts")

local M = {}

-- single terminal state across runners
local term_state = {
	---@type integer | nil
	buf = nil,
	---@type integer | nil
	win = nil,
}

--- recreate terminal buffer and show in window
--- @return integer | nil
function M.open_terminal()
	if term_state.buf and vim.api.nvim_buf_is_valid(term_state.buf) then
		vim.api.nvim_buf_delete(term_state.buf, { force = true })
	end

	term_state.buf = vim.api.nvim_create_buf(false, true)
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	if not (term_state.win and vim.api.nvim_win_is_valid(term_state.win)) then
		term_state.win = vim.api.nvim_open_win(term_state.buf, true, {
			relative = "editor",
			width = width,
			height = height,
			row = row,
			col = col,
			style = "minimal",
			border = "rounded",
			title = consts.strings.term_title,
			title_pos = "center",
		})
	else
		vim.api.nvim_win_set_buf(term_state.win, term_state.buf)
		vim.api.nvim_set_current_win(term_state.win)
	end

	vim.bo[term_state.buf].bufhidden = "wipe"
	return term_state.buf
end

--- sequentially executes a list of commands
--- @param cmds command[]
--- @param env env
--- @param cwd string
function M.execute_commands(cmds, env, cwd)
	local current_idx = 1

	local function run_next()
		local cmd = cmds[current_idx]
		if not cmd then
			return
		end

		M.open_terminal()
		local job_opts = {
			env = env,
			term = true,
		}
		if cwd then
			job_opts.cwd = cwd
		end

		if current_idx < #cmds then
			job_opts.on_exit = function(_, exit_code)
				if exit_code == 0 then
					current_idx = current_idx + 1
					vim.defer_fn(run_next, 50)
				else
					vim.notify(vim.fn.printf(consts.strings.task_failed, exit_code), vim.log.levels.ERROR)
				end
			end
		end

		vim.fn.jobstart(cmd, job_opts)
		vim.cmd("startinsert")
	end

	run_next()
end

return M
