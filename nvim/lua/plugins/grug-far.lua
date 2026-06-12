vim.pack.add {
  { src = "https://github.com/MagicDuck/grug-far.nvim" },
}

local grug = require("grug-far")

grug.setup {}

vim.keymap.set("n", "<leader>sr", function()
  grug.open()
end, { desc = "Search & replace (grug-far)" })

vim.keymap.set("n", "<leader>sw", function()
  grug.open { prefills = { search = vim.fn.expand "<cword>" } }
end, { desc = "Search & replace word under cursor" })

vim.keymap.set("n", "<leader>sf", function()
  grug.open { prefills = { paths = vim.fn.expand "%" } }
end, { desc = "Search & replace in current file" })

vim.keymap.set("x", "<leader>sr", function()
  grug.with_visual_selection()
end, { desc = "Search & replace visual selection" })
