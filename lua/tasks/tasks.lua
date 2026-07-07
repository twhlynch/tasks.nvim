local consts = require("tasks.consts")

--- @class Tasks.Provider
--- @field get_tasks fun(bufnr: integer): Tasks.Task[]
--- @field get_pattern fun(): string[]
--- @field get_ignore fun(): string[]

--- @class Tasks.Task
--- @field name string
--- @field lnum integer
--- @field run fun()

local M = {}

--- @return Tasks.Provider[]
function M.get_providers()
	local providers = {}

	local names = require("tasks.options").get().providers

	for _, name in ipairs(names) do
		local ok, provider = pcall(require, "tasks." .. name)
		if ok then
			table.insert(providers, provider)
		end
	end

	return providers
end

--- get all providers patterns
--- @return string[]
function M.get_pattern()
	local pattern = {}

	for _, provider in ipairs(M.get_providers()) do
		vim.list_extend(pattern, provider.get_pattern())
	end

	return pattern
end

--- @param bufnr integer
--- @param tasks Tasks.Task[]
function M.render(bufnr, tasks)
	-- clear
	vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)
	vim.fn.sign_unplace(consts.sign_group, { buffer = bufnr })

	-- place signs
	for i, task in ipairs(tasks) do
		vim.fn.sign_place(i, consts.sign_group, consts.sign_name, bufnr, {
			lnum = task.lnum,
			priority = 10,
		})
	end
end

function M.find_tasks_globally()
	local all_tasks = {}

	for _, provider in ipairs(M.get_providers()) do
		local patterns = provider.get_pattern()

		local ignore = vim.list_extend(provider.get_ignore(), require("tasks.options").get().ignore)

		for _, pattern in ipairs(patterns) do
			local files = vim.fn.glob(pattern:gsub("^%*/", "**/"), false, true)

			for _, filepath in ipairs(files) do
				if not vim.iter(ignore):find(function(p)
					return filepath:match(p)
				end) then
					local bufnr = vim.fn.bufadd(filepath)
					vim.fn.bufload(bufnr)
					vim.list_extend(all_tasks, provider.get_tasks(bufnr))
					vim.bo[bufnr].bufhidden = "hide"
					vim.bo[bufnr].buflisted = false
				end
			end
		end
	end

	return all_tasks
end

--- @param tasks? Tasks.Task[]
function M.pick(tasks)
	tasks = tasks or M.find_tasks_globally()

	if vim.tbl_isempty(tasks) then
		vim.notify("No tasks found", vim.log.levels.WARN)
		return
	end

	local items = vim.iter(tasks)
		:map(function(t)
			return { task = t, display = t.name }
		end)
		:totable()

	vim.ui.select(items, {
		prompt = consts.strings.picker_desc,
		format_item = function(item)
			return item.display
		end,
	}, function(choice)
		if choice then
			choice.task.run()
		end
	end)
end

--- @param tasks Tasks.Task[]
function M.run(tasks)
	local line = vim.api.nvim_win_get_cursor(0)[1]

	local task = vim.iter(tasks):find(function(t)
		return t.lnum == line
	end)

	if task then
		task.run()
	else
		vim.notify(consts.strings.no_target, vim.log.levels.WARN)
	end
end

--- @param bufnr integer
function M.attach(bufnr)
	local all_tasks = {}

	for _, provider in ipairs(M.get_providers()) do
		vim.list_extend(all_tasks, provider.get_tasks(bufnr))
	end

	if not vim.tbl_isempty(all_tasks) then
		M.render(bufnr, all_tasks)

		-- keymap
		local keybind = require("tasks.options").get().keybind
		vim.keymap.set("n", keybind, function()
			M.run(all_tasks)
		end, { buf = bufnr, desc = consts.strings.keybind_desc })
	end
end

function M.setup()
	local options = require("tasks.options").get()

	-- namespace
	M.ns = vim.api.nvim_create_namespace(consts.namespace_name)

	-- play icon
	vim.fn.sign_define(consts.sign_name, {
		text = options.sign_icon,
		texthl = options.sign_hl,
	})

	-- global keybind for task picker
	vim.keymap.set("n", options.keybind_picker, function()
		M.pick()
	end, { desc = consts.strings.picker_desc })

	-- attach on read and write
	local pattern = M.get_pattern()
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
		pattern = pattern,
		callback = function(args)
			M.attach(args.buf)
		end,
	})
end

return M
