vim.pack.add {
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
}

require("mason").setup()

-- Ensure non-LSP tools (formatters, linters) are installed via Mason.
local packages_to_install = { "stylua", "prettier" }
local registry = require("mason-registry")
for _, pkg_name in ipairs(packages_to_install) do
  local ok, pkg = pcall(registry.get_package, pkg_name)
  if ok and not pkg:is_installed() then
    pkg:install()
  end
end

require("mason-lspconfig").setup {
  ensure_installed = { "lua_ls", "pyright", "ruff", "ts_ls" },
}
