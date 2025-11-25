return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	dependencies = {
		"kkharji/sqlite.lua",
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},
		"nvim-telescope/telescope-live-grep-args.nvim",
		"nvim-telescope/telescope-smart-history.nvim",
	},
	config = function()
		local telescope = require("telescope")
		telescope.setup({
			defaults = {
				history = {
					path = "~/.local/share/nvim/databases/telescope_history.sqlite3",
					limit = 100,
				},
				mappings = {
					i = {
						["<C-Down>"] = require("telescope.actions").cycle_history_next,
						["<C-Up>"] = require("telescope.actions").cycle_history_prev,
					},
				},
			},
			pickers = {
				oldfiles = {
					cwd_only = true,
				},
			},
		})
		telescope.load_extension("fzf")
		telescope.load_extension("live_grep_args")
		telescope.load_extension("smart_history")
	end,
}
