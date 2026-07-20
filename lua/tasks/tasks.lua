local consts = require("tasks.consts")

--- @class Tasks.Provider
--- @field get_tasks fun(bufnr: integer): Tasks.Task[]
--- @field get_files fun(): string[]

--- @class Tasks.Task
--- @field name string
--- @field lnum? integer
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
	local patterns = {}

	for _, provider in ipairs(M.get_providers()) do
		vim.list_extend(patterns, provider.get_files())
	end

	return vim.fn.map(patterns, function(_, pattern)
		return "*/" .. pattern
	end)
end

--- @param bufnr integer
--- @param tasks Tasks.Task[]
function M.render(bufnr, tasks)
	-- clear
	vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)
	vim.fn.sign_unplace(consts.sign_group, { buffer = bufnr })

	-- place signs
	for i, task in ipairs(tasks) do
		if task.lnum then
			vim.fn.sign_place(i, consts.sign_group, consts.sign_name, bufnr, {
				lnum = task.lnum,
				priority = 10,
			})
		end
	end
end

function M.find_tasks()
	local all_tasks = {}

	for _, provider in ipairs(M.get_providers()) do
		local files = provider.get_files()

		for _, file in ipairs(files) do
			local readable = vim.fn.filereadable(file)

			if readable then
				local bufnr = vim.fn.bufadd(file)
				vim.fn.bufload(bufnr)
				vim.list_extend(all_tasks, provider.get_tasks(bufnr))
				vim.bo[bufnr].bufhidden = "hide"
				vim.bo[bufnr].buflisted = false
			end
		end
	end

	return all_tasks
end

function M.pick()
	local tasks = M.find_tasks()

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
		if keybind then
			vim.keymap.set("n", keybind, function()
				M.run(all_tasks)
			end, { buf = bufnr, desc = consts.strings.keybind_desc })
		end
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
	if options.keybind_picker then
		vim.keymap.set("n", options.keybind_picker, function()
			M.pick()
		end, { desc = consts.strings.picker_desc })
	end

	-- attach on read and write
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
		pattern = M.get_pattern(),
		callback = function(args)
			M.attach(args.buf)
		end,
	})
end

return M
