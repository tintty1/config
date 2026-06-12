vim.pack.add {
  { src = "https://github.com/stevearc/conform.nvim" },
}

require("conform").setup {
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_format" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    html = { "prettier" },
    css = { "prettier" },
    scss = { "prettier" },
    markdown = { "prettier" },
  },
  default_format_opts = {
    lsp_format = "fallback",
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
}

-- Manual format. conform falls back to the LSP formatter when no formatter is
-- configured for the filetype (default_format_opts.lsp_format = "fallback").
vim.keymap.set({ "n", "x" }, "<leader>f", function()
  require("conform").format { async = true }
end, { desc = "Format buffer/selection" })
