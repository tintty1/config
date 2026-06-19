vim.pack.add({
	{ src = "https://github.com/tintty1/toggleterm.nvim" },
})

require("toggleterm").setup({
	size = 20,
	open_mapping = [[<c-\>]],
	hide_numbers = true,
	shade_filetypes = {},
	shade_terminals = true,
	shading_factor = 2,
	start_in_insert = true,
	insert_mappings = true,
	persist_size = true,
	direction = "float",
	close_on_exit = true,
	shell = vim.o.shell,
	-- Catch-all: start the Claude bridge the first time any terminal opens, so sends
	-- work even for a float opened with the bare <c-\> mapping. (Fires after the shell
	-- spawns, so that first claude connects via `/ide`; the helpers below pre-start it.)
	on_open = function()
		require("plugins.claudecode").start()
	end,
	float_opts = {
		border = "curved",
		winblend = 0,
		highlights = {
			border = "Normal",
			background = "Normal",
		},
	},
})

-- Function to set terminal keymaps
function _G.set_terminal_keymaps()
	local opts = { buffer = 0 }
	vim.keymap.set("n", "<esc>", "<cmd>close<cr>", opts)
	vim.keymap.set("n", "q", "<cmd>close<cr>", opts)
end

-- Apply terminal keymaps when terminal opens
vim.cmd("autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()")

-- Re-layout the running terminal (e.g. the tmux+claude session) between float and
-- a vertical split. The terminal buffer is persistent, so switching direction just
-- re-displays the SAME session in a new layout -- tmux/claude keeps running.
local function main_term()
	local terms = require("toggleterm.terminal")
	return terms.get_last_focused() or terms.get(1, true)
end

local function vert_size()
	return math.floor(vim.o.columns * 0.4)
end

-- Toggle the terminal into `direction`. Same direction while open => hide it.
function _G.toggleterm_toggle(direction)
	-- Pre-start the bridge so the env vars are set BEFORE the shell spawns -- a claude
	-- opened in a terminal launched this way auto-connects without needing `/ide`.
	require("plugins.claudecode").start()
	local term = main_term()
	if not term then
		vim.cmd("ToggleTerm direction=" .. direction)
		return
	end
	if term:is_open() and term.direction == direction then
		term:close()
		return
	end
	if term:is_open() then
		term:close()
	end
	term:open(direction == "vertical" and vert_size() or nil, direction)
end

-- Ensure the terminal is visible in `direction` without stealing focus.
function _G.toggleterm_show(direction)
	local term = main_term()
	if not term then
		return
	end
	if term:is_open() and term.direction == direction then
		return
	end
	local prev = vim.api.nvim_get_current_win()
	if term:is_open() then
		term:close()
	end
	term:open(direction == "vertical" and vert_size() or nil, direction)
	if vim.api.nvim_win_is_valid(prev) then
		vim.api.nvim_set_current_win(prev)
	end
end

vim.keymap.set("n", "<leader>v", function()
	_G.toggleterm_toggle("vertical")
end, { desc = "Terminal: vertical split" })
vim.keymap.set("n", "<leader>tf", function()
	_G.toggleterm_toggle("float")
end, { desc = "Terminal: float" })
