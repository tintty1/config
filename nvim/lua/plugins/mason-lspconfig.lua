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

-- Full LSP restart: force-stop every client, then re-attach to all loaded
-- buffers so fresh servers reindex the project from disk. Use this after an
-- external tool (e.g. an AI agent) writes new code to disk — Neovim only syncs
-- open buffers to the server, so its index goes stale and `gd`/diagnostics
-- break until a brand-new server scans the files again.
local function lsp_full_restart()
  local clients = vim.lsp.get_clients()
  for _, client in ipairs(clients) do
    vim.lsp.stop_client(client.id, true) -- force = true: don't wait for graceful shutdown
  end

  -- Wait for the clients to actually exit, then reload + re-attach every
  -- real file buffer. `:edit` re-reads the file from disk and re-fires
  -- FileType, which restarts the server (via vim.lsp.enable) and reindexes.
  vim.defer_fn(function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" then
        local name = vim.api.nvim_buf_get_name(buf)
        if name ~= "" and not vim.bo[buf].modified then
          vim.api.nvim_buf_call(buf, function()
            vim.cmd "edit"
          end)
        end
      end
    end
    vim.notify("LSP: full restart complete", vim.log.levels.INFO)
  end, 500)
end

vim.api.nvim_create_user_command("LspFullRestart", lsp_full_restart, {
  desc = "Force-stop all LSP servers and reattach buffers (reindex from disk)",
})
vim.keymap.set("n", "<leader>lr", lsp_full_restart, { desc = "LSP full restart" })

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
