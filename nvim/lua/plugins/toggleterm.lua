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
	-- Terminal mode -> normal mode. Note: a single <esc> now waits `timeoutlen` before
	-- passing through to the program in the terminal (tmux/claude).
	vim.keymap.set("t", "<esc><esc>", [[<C-\><C-n>]], opts)
	vim.keymap.set("n", "<esc>", "<cmd>close<cr>", opts)
	vim.keymap.set("n", "q", "<cmd>close<cr>", opts)
end

-- Apply terminal keymaps when terminal opens
vim.cmd("autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()")

-- ===== Singleton terminal =====
-- One terminal per nvim instance (id 1). The commands below create-or-toggle it and
-- switch its layout. The terminal buffer is persistent, so switching layout just
-- re-displays the SAME session in a new layout (tmux/claude keeps running).
local terms = require("toggleterm.terminal")
local TERM_ID = 1
local CYCLE = { "vertical", "horizontal", "float" }

-- Layout sizes: vertical width = 40% of columns, horizontal height = 30% of lines;
-- float uses float_opts above (size is ignored).
local function size_for(direction)
	if direction == "vertical" then
		return math.floor(vim.o.columns * 0.4)
	elseif direction == "horizontal" then
		return math.floor(vim.o.lines * 0.3)
	end
	return nil
end

-- The single terminal, creating it (unspawned) on first use.
local function get_term()
	return terms.get(TERM_ID, true) or terms.get_or_create_term(TERM_ID)
end

-- Create-or-toggle the singleton term in `direction`:
--   * not created yet  -> create + open in `direction`
--   * open in same dir -> hide
--   * open in other dir (or hidden) -> (re)show in `direction`
local function term_to(direction)
	-- Pre-start the Claude bridge so the env vars are set BEFORE the shell spawns --
	-- a claude launched in this terminal then auto-connects without needing `/ide`.
	require("plugins.claudecode").start()
	local term = get_term()
	if term:is_open() and term.direction == direction then
		term:close()
		return
	end
	if term:is_open() then
		term:close()
	end
	term:open(size_for(direction), direction)
end

-- Cycle the layout vertical -> horizontal -> float and (re)show the term.
local function term_cycle()
	require("plugins.claudecode").start()
	local term = get_term()
	local cur = term.direction or CYCLE[#CYCLE]
	local nxt = CYCLE[1]
	for i, dir in ipairs(CYCLE) do
		if dir == cur then
			nxt = CYCLE[(i % #CYCLE) + 1]
			break
		end
	end
	if term:is_open() then
		term:close()
	end
	term:open(size_for(nxt), nxt)
end

-- Ensure the term is visible in `direction` WITHOUT stealing focus.
-- Used by the claudecode "show on send" autocmd.
function _G.toggleterm_show(direction)
	local term = terms.get(TERM_ID, true)
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
	term:open(size_for(direction), direction)
	if vim.api.nvim_win_is_valid(prev) then
		vim.api.nvim_set_current_win(prev)
	end
end

-- Commands: create-or-toggle per layout + cycle.
vim.api.nvim_create_user_command("Vterm", function()
	term_to("vertical")
end, { desc = "Term: vertical (create/toggle)" })
vim.api.nvim_create_user_command("Hterm", function()
	term_to("horizontal")
end, { desc = "Term: horizontal (create/toggle)" })
vim.api.nvim_create_user_command("Fterm", function()
	term_to("float")
end, { desc = "Term: float (create/toggle)" })
vim.api.nvim_create_user_command("TermCycle", function()
	term_cycle()
end, { desc = "Term: cycle layout (vertical -> horizontal -> float)" })

-- Keymaps mirroring the commands.
vim.keymap.set("n", "<leader>v", function()
	term_to("vertical")
end, { desc = "Term: vertical" })
vim.keymap.set("n", "<leader>th", function()
	term_to("horizontal")
end, { desc = "Term: horizontal" })
vim.keymap.set("n", "<leader>tf", function()
	term_to("float")
end, { desc = "Term: float" })
vim.keymap.set("n", "<leader>tc", term_cycle, { desc = "Term: cycle layout" })

-- Ergonomic cycle: Ctrl+` (grave) from normal OR terminal mode. Needs the kitty
-- keyboard protocol for nvim to receive a Ctrl+<non-letter> combo (kitty supports it).
vim.keymap.set({ "n", "t" }, "<C-`>", term_cycle, { desc = "Term: cycle layout" })
