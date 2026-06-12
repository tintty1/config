vim.pack.add({
	{ src = "https://github.com/stevearc/conform.nvim" },
})

require("conform").setup({
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
		go = { "goimports", "gofmt" },
		-- helm = { "helmfmt" },
		-- Run on filetypes that have no other formatter configured: strips
		-- trailing whitespace on save (other formatters handle it themselves).
		["_"] = { "trim_whitespace" },
	},
	formatters = {
		-- helmfmt is not a conform built-in. It formats Go-template indentation in
		-- Helm charts in place via its `--files` mode; stdin=false makes conform
		-- pass it a temp file (keeping the .yaml/.tpl extension it filters on).
		-- helmfmt = {
		-- 	command = "helmfmt",
		-- 	args = { "--files", "$FILENAME" },
		-- 	stdin = false,
		-- },
	},
	default_format_opts = {
		lsp_format = "fallback",
	},
	format_on_save = {
		timeout_ms = 500,
		lsp_format = "fallback",
	},
})

-- Manual format. conform falls back to the LSP formatter when no formatter is
-- configured for the filetype (default_format_opts.lsp_format = "fallback").
vim.keymap.set({ "n", "x" }, "<leader>f", function()
	require("conform").format({ async = true })
end, { desc = "Format buffer/selection" })
