vim.pack.add({
	{ src = "https://github.com/ibhagwan/fzf-lua" },
})

local fzf = require("fzf-lua")

fzf.setup({
	winopts = {
		-- The fzf query is a terminal prompt, not a Neovim buffer, so the normal
		-- i_CTRL-R register paste is unavailable. Emulate it: press <C-r>, then a
		-- register name, to paste its contents into the query. Briefly drops to
		-- terminal-normal mode, kastes the register into the job, and returns.
		on_create = function()
			vim.keymap.set("t", "<C-r>", [['<C-\><C-N>"'.nr2char(getchar()).'pi']], { expr = true, buffer = true })
		end,
	},
	keymap = {
		builtin = {
			-- inherit the default builtin keymaps (e.g. <S-up>/<S-down> page scroll)
			true,
			["<C-d>"] = "preview-page-down",
			["<C-u>"] = "preview-page-up",
		},
	},
	oldfiles = {
		cwd_only = true,
	},
	buffers = {
		sort_lastused = true,
	},
})

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
map("<leader>fR", fzf.resume, "Resume last picker")
map("<leader>fc", fzf.grep_cword, "Find word under cursor")
map("<leader>fs", fzf.lsp_document_symbols, "Document symbols")
map("<leader>fS", fzf.lsp_workspace_symbols, "Workspace symbols")
map("<leader>fd", fzf.diagnostics_document, "Diagnostics")
