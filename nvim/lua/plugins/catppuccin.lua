vim.pack.add {
  { src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
}

require("catppuccin").setup {
  flavour = "mocha",
}

-- Don't grey out "unnecessary"/unreachable code (e.g. pyright's false-positive
-- unreachable reports). Fully clearing the group lets the underlying syntax
-- highlight show through; pyright's underline/sign still appears.
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "catppuccin*",
  callback = function()
    vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", {})
  end,
})

vim.cmd.colorscheme "catppuccin-mocha"
