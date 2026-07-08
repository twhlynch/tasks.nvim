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
--- @param runner Tasks.Options.options.runner
function M.open_window(runner)
	-- close previous buffer
	if term_state.buf and vim.api.nvim_buf_is_valid(term_state.buf) then
		vim.api.nvim_buf_delete(term_state.buf, { force = true })
		term_state.buf = nil
	end
	-- close previous window
	if term_state.win and vim.api.nvim_win_is_valid(term_state.win) then
		vim.api.nvim_win_close(term_state.win, true)
		term_state.win = nil
	end

	-- create new buffer
	term_state.buf = vim.api.nvim_create_buf(false, true)
	vim.bo[term_state.buf].bufhidden = "wipe"

	-- open window based on runner type
	if runner == "split" then
		term_state.win = vim.api.nvim_open_win(term_state.buf, true, {
			split = "below",
			win = 0,
		})
	elseif runner == "vsplit" then
		term_state.win = vim.api.nvim_open_win(term_state.buf, true, {
			split = "right",
			win = 0,
		})
	else
		local cols = vim.o.columns
		local lines = vim.o.lines
		local width = math.floor(cols * 0.8)
		local height = math.floor(lines * 0.8)
		local row = math.floor((lines - height) / 2)
		local col = math.floor((cols - width) / 2)

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
	end

	return term_state.buf
end

--- executes a list of commands
--- @param cmds command[]
--- @param env env
--- @param cwd string
function M.execute_commands(cmds, env, cwd)
	local runner = require("tasks.options").get().runner

	if type(runner) == "function" then
		M.run_custom(cmds, runner)
	elseif runner == "background" then
		M.run_background(cmds, env, cwd)
	else
		M.run_visible(cmds, env, cwd, runner)
	end
end

--- executes a list of commands in a visible terminal window
--- @param cmds command[]
--- @param env env
--- @param cwd string
--- @param runner Tasks.Options.options.runner
function M.run_visible(cmds, env, cwd, runner)
	local current_idx = 1

	local function run_next()
		local cmd = cmds[current_idx]
		if not cmd then
			return
		end

		M.open_window(runner)
		local job_opts = {
			env = env,
			term = true,
			cwd = cwd,
		}

		if current_idx < #cmds then
			job_opts.on_exit = function(_, exit_code)
				if exit_code == 0 then
					current_idx = current_idx + 1
					vim.defer_fn(run_next, 50)
				else
					vim.notify(string.format(consts.strings.task_failed, exit_code), vim.log.levels.ERROR)
				end
			end
		end

		vim.fn.jobstart(cmd, job_opts)
		vim.cmd("startinsert")
	end

	run_next()
end

--- executes a list of commands in the background
--- @param cmds command[]
--- @param env env
--- @param cwd string
function M.run_background(cmds, env, cwd)
	local current_idx = 1

	local function run_next()
		local cmd = cmds[current_idx]
		if not cmd then
			return
		end

		local job_opts = {
			env = env,
			cwd = cwd,
		}

		if current_idx < #cmds then
			job_opts.on_exit = function(_, exit_code)
				if exit_code == 0 then
					current_idx = current_idx + 1
					vim.defer_fn(run_next, 50)
				else
					vim.notify(string.format(consts.strings.task_failed, exit_code), vim.log.levels.ERROR)
				end
			end
		else
			job_opts.on_exit = function(_, exit_code)
				if exit_code ~= 0 then
					vim.notify(string.format(consts.strings.task_failed, exit_code), vim.log.levels.ERROR)
				end
			end
		end

		vim.fn.jobstart(cmd, job_opts)
	end

	run_next()
end

--- executes a list of commands in a new tmux window
--- @param cmds command[]
--- @param runner fun(cmd: string)
function M.run_custom(cmds, runner)
	-- escape and join commands
	local full_command = vim.fn.join(
		vim.fn.map(cmds, function(_, cmd)
			return type(cmd) == "table" and vim.fn.join(
				-- escape args lists
				vim.fn.map(cmd, function(_, c)
					return vim.fn.shellescape(c)
				end),
				" "
			) or cmd
		end),
		" && "
	)

	runner(full_command)
end

return M
