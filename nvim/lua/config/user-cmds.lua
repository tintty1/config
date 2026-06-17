vim.api.nvim_create_user_command("CopyText", function()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local start_row, start_col = start_pos[2] - 1, start_pos[3] - 1
	local end_row, end_col = end_pos[2] - 1, end_pos[3]

	local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)

	if #lines == 0 then
		return
	end

	if #lines == 1 then
		lines[1] = string.sub(lines[1], start_col + 1, end_col)
	else
		lines[1] = string.sub(lines[1], start_col + 1)
		lines[#lines] = string.sub(lines[#lines], 1, end_col)
	end

	vim.fn.setreg("+", table.concat(lines, "\n"))
	vim.notify("Copied selection to clipboard", vim.log.levels.INFO)
end, { desc = "Copy text to + register", range = true })

-- Encode/decode the visual selection in place.
local function transform_selection(fn)
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local start_row, start_col = start_pos[2] - 1, start_pos[3] - 1
	local end_row, end_col = end_pos[2] - 1, end_pos[3]

	local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
	if #lines == 0 then
		return
	end

	-- Clamp end column to the last line's length (handles linewise / past-EOL selections).
	end_col = math.min(end_col, #lines[#lines])

	local text
	if #lines == 1 then
		text = string.sub(lines[1], start_col + 1, end_col)
	else
		lines[1] = string.sub(lines[1], start_col + 1)
		lines[#lines] = string.sub(lines[#lines], 1, end_col)
		text = table.concat(lines, "\n")
	end

	local ok, result = pcall(fn, text)
	if not ok then
		vim.notify(result, vim.log.levels.ERROR)
		return
	end

	vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, vim.split(result, "\n", { plain = true }))
	vim.fn.setreg("+", result)
	vim.notify("Transformed selection and copied to clipboard", vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("Base64Encode", function()
	transform_selection(function(text)
		return vim.base64.encode(text)
	end)
end, { desc = "Base64-encode the visual selection", range = true })

vim.api.nvim_create_user_command("Base64Decode", function()
	transform_selection(function(text)
		return vim.base64.decode(text)
	end)
end, { desc = "Base64-decode the visual selection", range = true })

vim.api.nvim_create_user_command("UrlEncode", function()
	transform_selection(function(text)
		return (text:gsub("[^%w%-%_%.%~]", function(c)
			return string.format("%%%02X", string.byte(c))
		end))
	end)
end, { desc = "URL-encode the visual selection", range = true })

vim.api.nvim_create_user_command("UrlDecode", function()
	transform_selection(function(text)
		return (text:gsub("%%(%x%x)", function(hex)
			return string.char(tonumber(hex, 16))
		end))
	end)
end, { desc = "URL-decode the visual selection", range = true })

-- Git blame commands
vim.api.nvim_create_user_command("Blame", function()
	require("gitsigns").blame()
end, { desc = "Open gitsigns blame buffer" })
