vim.pack.add {
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
}

require("mason").setup()

-- Ensure non-LSP tools (formatters, linters) are installed via Mason.
local packages_to_install = { "stylua", "prettier", "goimports" }
local registry = require("mason-registry")
for _, pkg_name in ipairs(packages_to_install) do
  local ok, pkg = pcall(registry.get_package, pkg_name)
  if ok and not pkg:is_installed() then
    pkg:install()
  end
end

require("mason-lspconfig").setup {
  ensure_installed = { "lua_ls", "pyright", "ruff", "ts_ls", "gopls" },
}

-- Buffer-local LSP keymaps, set only when a server attaches to the buffer.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
    end

    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("gD", vim.lsp.buf.declaration, "Go to declaration")
    map("gr", vim.lsp.buf.references, "Go to references")
    map("gi", vim.lsp.buf.implementation, "Go to implementation")
    map("K", vim.lsp.buf.hover, "Show hover documentation")
    map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    map("<leader>ca", vim.lsp.buf.code_action, "Code actions")
    -- <leader>f formatting is handled by conform (with LSP fallback).
  end,
})
