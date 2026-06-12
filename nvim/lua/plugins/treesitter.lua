vim.pack.add {
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
  -- Detects Helm charts and sets `filetype=helm` for their templates.
  { src = "https://github.com/towolf/vim-helm" },
}

local parsers = {
  "python",
  "markdown",
  "lua",
  "javascript",
  "yaml",
  "typescript",
  "html",
  "css",
  "jsonc",
  "tsx",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "gotmpl",
  "jinja",
  "jinja_inline",
}

-- Filetype detection for templates not recognized by Neovim out of the box.
vim.filetype.add {
  extension = {
    j2 = "jinja",
    jinja = "jinja",
    jinja2 = "jinja",
  },
}

-- Helm templates (filetype `helm`, set by vim-helm) are Go templates.
vim.treesitter.language.register("gotmpl", "helm")

-- Install missing parsers (async, no-op if already installed).
require("nvim-treesitter").install(parsers)

-- Keep parsers in sync with the plugin whenever it's updated.
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "nvim-treesitter" and ev.data.kind == "update" then
      vim.cmd("TSUpdate")
    end
  end,
})

-- Enable treesitter highlighting for any filetype that has an installed parser.
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})
