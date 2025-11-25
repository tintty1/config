return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons", -- optional, but recommended
		},
		lazy = false, -- neo-tree will lazily load itself
		opts = {
			sources = { "filesystem", "buffers", "git_status", "document_symbols" },
			filesystem = {
				follow_current_file = {
					enabled = true,
					leave_dirs_open = false,
				},
			},
			document_symbols = {
				follow_cursor = true,
				client_filters = "first",
				renderers = {
					symbol = {
						{ "indent", with_expanders = true },
						{ "kind_icon", default = "?" },
						{
							"container",
							content = {
								{ "name", zindex = 10 },
								{
									"kind_name",
									zindex = 20,
									align = "right",
								},
							},
						},
					},
				},
			},
		},
	},
}
