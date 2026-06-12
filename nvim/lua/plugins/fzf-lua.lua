vim.pack.add {
  { src = "https://github.com/ibhagwan/fzf-lua" },
}

local fzf = require("fzf-lua")

fzf.setup {
  oldfiles = {
    cwd_only = true,
  },
  buffers = {
    sort_lastused = true,
  },
}

-- Route vim.ui.select (code actions, etc.) through fzf-lua.
fzf.register_ui_select()

local function map(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { desc = desc })
end

map("<leader><Space>", fzf.builtin, "Fzf builtin pickers")
map("<leader>ff", fzf.files, "Find files")
map("<leader>fg", fzf.live_grep, "Live grep")
map("<leader>fb", fzf.buffers, "Find buffers")
map("<leader>fh", fzf.helptags, "Help tags")
map("<leader>fr", fzf.oldfiles, "Recent files")
map("<leader>fc", fzf.grep_cword, "Find word under cursor")
map("<leader>fs", fzf.lsp_document_symbols, "Document symbols")
map("<leader>fS", fzf.lsp_workspace_symbols, "Workspace symbols")
map("<leader>fd", fzf.diagnostics_document, "Diagnostics")
