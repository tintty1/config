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

-- Buffer navigation
vim.keymap.set("n", "[b", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
vim.keymap.set("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

-- Diagnostics (vim.diagnostic is built in, always available)
vim.keymap.set("n", "[d", function()
  vim.diagnostic.jump { count = -1 }
end, { desc = "Previous diagnostic" })
vim.keymap.set("n", "]d", function()
  vim.diagnostic.jump { count = 1 }
end, { desc = "Next diagnostic" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostic quickfix" })

-- Clear search highlight with <Esc> (only when search highlight is active)
vim.keymap.set("n", "<Esc>", function()
  if vim.v.hlsearch == 1 then
    vim.cmd "nohlsearch"
  else
    return "<Esc>"
  end
end, { expr = true, desc = "Clear search highlight" })
