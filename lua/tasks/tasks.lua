local consts = require("tasks.consts")

--- @class Tasks.Provider
--- @field get_tasks fun(bufnr: integer): Tasks.Task[]
--- @field get_pattern fun(): string[]

--- @class Tasks.Task
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
			providers[#providers + 1] = provider
		end
	end

	return providers
end

--- get all providers patterns
--- @return string[]
function M.get_pattern()
	local pattern = {}

	local providers = M.get_providers()

	for _, provider in ipairs(providers) do
		local files = provider.get_pattern()

		for _, file in ipairs(files) do
			pattern[#pattern + 1] = file
		end
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

--- @param tasks Tasks.Task[]
function M.run(tasks)
	local line = vim.api.nvim_win_get_cursor(0)[1]

	for _, task in ipairs(tasks) do
		if task.lnum == line then
			task.run()
			return
		end
	end

	vim.notify(consts.strings.no_target, vim.log.levels.WARN)
end

--- @param bufnr number
function M.attach(bufnr)
	local providers = M.get_providers()

	local all_tasks = {}

	for _, provider in ipairs(providers) do
		local tasks = provider.get_tasks(bufnr)
		for _, task in ipairs(tasks) do
			all_tasks[#all_tasks + 1] = task
		end
	end

	if #all_tasks ~= 0 then
		M.render(bufnr, all_tasks)

		-- keymap
		vim.keymap.set("n", require("tasks.options").get().keybind, function()
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

	-- attach on read and write
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
		pattern = M.get_pattern(),
		callback = function(args)
			M.attach(args.buf)
		end,
	})
end

return M
