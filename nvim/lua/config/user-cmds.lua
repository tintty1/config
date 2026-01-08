vim.api.nvim_create_user_command("DumpOptions", function()
	-- Create a scratch buffer
	local buf = vim.api.nvim_create_buf(false, true) -- [listed=false, scratch=true]

	-- Get all options info
	local opts_info = vim.api.nvim_get_all_options_info()
	local lines = {}

	for name, _ in pairs(opts_info) do
		local ok, value = pcall(vim.api.nvim_get_option_value, name, { scope = "local" })
		if ok then
			table.insert(lines, string.format("%-20s = %s", name, vim.inspect(value)))
		end
	end

	-- Set lines to buffer
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Open in a new split window
	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = math.floor(vim.o.columns * 0.8),
		height = math.floor(vim.o.lines * 0.8),
		row = math.floor(vim.o.lines * 0.1),
		col = math.floor(vim.o.columns * 0.1),
		style = "minimal",
		border = "single",
	})
end, {})

vim.api.nvim_create_user_command("FloatTerm", function(opts)
	require("toggleterm").toggle(nil, nil, nil, "float")
end, {})

vim.api.nvim_create_user_command("CopyRelPath", function()
	local filepath = vim.fn.expand("%")
	if filepath == "" then
		vim.notify("No file in current buffer", vim.log.levels.WARN)
		return
	end
	vim.fn.setreg("+", filepath)
	vim.notify("Copied relative path: " .. filepath)
end, {})

vim.api.nvim_create_user_command("CopyAbsPath", function()
	local filepath = vim.fn.expand("%:p")
	if filepath == "" then
		vim.notify("No file in current buffer", vim.log.levels.WARN)
		return
	end
	vim.fn.setreg("+", filepath)
	vim.notify("Copied absolute path: " .. filepath)
end, {})

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

vim.api.nvim_create_user_command("BlameLine", function()
	require("gitsigns").blame_line({ full = true })
end, { desc = "Show blame for current line" })

-- Neo-tree commands
vim.api.nvim_create_user_command("FloatTree", function()
	vim.cmd("Neotree float reveal_file=" .. vim.fn.expand("%:p") .. " reveal_force_cwd")
end, { desc = "Open Neo-tree in float mode revealing current file" })

vim.api.nvim_create_user_command("FloatSymbols", function()
	vim.cmd("Neotree float document_symbols")
end, { desc = "Open Neo-tree document symbols in float mode" })

-- Filetype commands
vim.api.nvim_create_user_command("Json", function()
	vim.bo.filetype = "json"
end, { desc = "Set buffer filetype to JSON" })

vim.api.nvim_create_user_command("Md", function()
	vim.bo.filetype = "markdown"
end, { desc = "Set buffer filetype to Markdown" })

vim.api.nvim_create_user_command("Python", function()
	vim.bo.filetype = "python"
end, { desc = "Set buffer filetype to Python" })

vim.api.nvim_create_user_command("Js", function()
	vim.bo.filetype = "javascript"
end, { desc = "Set buffer filetype to JavaScript" })

vim.api.nvim_create_user_command("Ts", function()
	vim.bo.filetype = "typescript"
end, { desc = "Set buffer filetype to TypeScript" })

vim.api.nvim_create_user_command("Jinja", function()
	vim.bo.filetype = "jinja"
end, { desc = "Set buffer filetype to Jinja" })

-- Filetype abbreviations
vim.cmd([[cnoreabbrev json Json]])
vim.cmd([[cnoreabbrev md Md]])
vim.cmd([[cnoreabbrev python Python]])
vim.cmd([[cnoreabbrev js Js]])
vim.cmd([[cnoreabbrev ts Ts]])
vim.cmd([[cnoreabbrev jinja Jinja]])
