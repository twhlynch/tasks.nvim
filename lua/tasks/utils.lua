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

--- parse a jsonc buffer to a json table
--- @param bufnr integer
--- @return nil | table
function M.parse_json(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local content = table.concat(lines, "\n")
	content = M.strip_json_comments(content)
	content = M.normalise_json_commas(content)

	local ok, data = pcall(vim.json.decode, content)
	if not ok then
		return nil
	end

	if type(data) ~= "table" then
		return nil
	end

	return data
end

return M
