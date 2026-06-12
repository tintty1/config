vim.pack.add {
  { src = "https://github.com/hrsh7th/nvim-cmp" },
  { src = "https://github.com/hrsh7th/cmp-nvim-lsp" },
  { src = "https://github.com/hrsh7th/cmp-nvim-lua" },
  { src = "https://github.com/hrsh7th/cmp-path" },
  { src = "https://github.com/hrsh7th/cmp-buffer" },
  { src = "https://github.com/L3MON4D3/LuaSnip" },
  { src = "https://github.com/saadparwaiz1/cmp_luasnip" },
  { src = "https://github.com/onsails/lspkind.nvim" },
}

local cmp = require("cmp")
local luasnip = require("luasnip")
local lspkind = require("lspkind")

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },

  mapping = cmp.mapping.preset.insert {
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm { select = true },
  },

  sources = cmp.config.sources {
    { name = "nvim_lsp", priority = 1000 },
    { name = "nvim_lua", priority = 900 },
    { name = "path", priority = 800 },
    { name = "luasnip", priority = 750 },
    { name = "buffer", priority = 500 },
  },

  formatting = {
    format = lspkind.cmp_format {
      mode = "symbol_text", -- Display both symbol and text
      maxwidth = 50, -- Limit the width of the completion item
    },
  },

  experimental = {
    ghost_text = true, -- shows a preview of completion inline
  },
}

-- Advertise cmp's completion capabilities to all LSP servers. Applies as a
-- default to every server enabled via `vim.lsp.enable()` (e.g. by mason-lspconfig).
vim.lsp.config("*", {
  capabilities = require("cmp_nvim_lsp").default_capabilities(),
})
