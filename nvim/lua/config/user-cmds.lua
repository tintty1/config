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

-- Git blame commands
vim.api.nvim_create_user_command("Blame", function()
	require("gitsigns").blame()
end, { desc = "Open gitsigns blame buffer" })
