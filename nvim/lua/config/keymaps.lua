-- Editor-level keymaps only. Anything that references a plugin lives in that
-- plugin's file; buffer-local LSP maps live in an LspAttach autocmd.

-- Terminal mode
vim.keymap.set("t", "<C-q>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("t", "<C-Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Jump to window N by number (Ctrl+1..Ctrl+9). If the target is a terminal buffer,
-- drop straight into terminal mode. Works from normal and terminal mode (kitty
-- keyboard protocol is needed to receive Ctrl+<digit>).
local function goto_window(n)
	local win = vim.fn.win_getid(n)
	if win == 0 then
		return
	end
	vim.api.nvim_set_current_win(win)
	if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "terminal" then
		vim.cmd("startinsert")
	end
end
for i = 1, 9 do
	vim.keymap.set({ "n", "t" }, "<C-" .. i .. ">", function()
		goto_window(i)
	end, { desc = "Go to window " .. i })
end

-- Buffer navigation
vim.keymap.set("n", "[b", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
vim.keymap.set("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

-- Diagnostics (vim.diagnostic is built in, always available)
vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({ count = -1 })
end, { desc = "Previous diagnostic" })
vim.keymap.set("n", "]d", function()
	vim.diagnostic.jump({ count = 1 })
end, { desc = "Next diagnostic" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostic quickfix" })

-- Clear search highlight with <Esc> (only when search highlight is active)
vim.keymap.set("n", "<Esc>", function()
	if vim.v.hlsearch == 1 then
		vim.cmd("nohlsearch")
	else
		return "<Esc>"
	end
end, { expr = true, desc = "Clear search highlight" })

-- Copy text
vim.keymap.set({ "v", "x" }, "<C-c>", ":CopyText<CR>", {
	desc = "Copy visual selection to clipboard",
})
