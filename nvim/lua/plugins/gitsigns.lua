vim.pack.add({
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
})

require("gitsigns").setup({})

vim.keymap.set("n", "]c", "<cmd>Gitsigns nav_hunk next<cr>", { desc = "Next git hunk" })
vim.keymap.set("n", "[c", "<cmd>Gitsigns nav_hunk prev<cr>", { desc = "Previous git hunk" })
vim.keymap.set("n", "<leader>hs", "<cmd>Gitsigns stage_hunk<cr>", { desc = "Stage hunk" })
vim.keymap.set("n", "<leader>hr", "<cmd>Gitsigns reset_hunk<cr>", { desc = "Reset hunk" })
vim.keymap.set("n", "<leader>hp", "<cmd>Gitsigns preview_hunk<cr>", { desc = "Preview hunk" })
