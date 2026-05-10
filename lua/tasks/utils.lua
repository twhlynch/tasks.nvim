local M = {}

--- strip json comments without breaking urls
--- @param content string
--- @return string
function M.strip_json_comments(content)
	return (
		content
			:gsub("://", "___URL_PROTOCOL___") -- save urls
			:gsub("//.-\n", "\n") -- line comments
			:gsub("/%*.-%*/", "") -- multiline comments
			:gsub("___URL_PROTOCOL___", "://") -- restore urls
	)
end

--- remove trailing commas from json
--- @param content string
--- @return string
function M.normalise_json_commas(content)
	-- remove commas from , } and , ]
	return (content:gsub(",%s*}", "}"):gsub(",%s*%]", "]"))
end

--- @param content string
--- @return nil | table
function M.parse_json_content(content)
	content = M.strip_json_comments(content)
	content = M.normalise_json_commas(content)

	local ok, data = pcall(vim.json.decode, content)
	if not ok or type(data) ~= "table" then
		return nil
	end

	return data
end

--- @param bufnr integer
--- @return nil | table
function M.parse_json(bufnr)
	local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
	return M.parse_json_content(content)
end

--- find the line number of a specific key-value pair
--- @param bufnr integer
--- @param key string
--- @param value string
--- @return integer | nil
function M.find_line(bufnr, key, value)
	local pattern = '"' --
		.. vim.pesc(key:gsub('"', '\\"'))
		.. '"%s*:%s*"'
		.. vim.pesc(value:gsub('"', '\\"'))
		.. '"'

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	for lnum, line in ipairs(lines) do
		if line:match(pattern) then
			return lnum
		end
	end

	return nil
end

return M
