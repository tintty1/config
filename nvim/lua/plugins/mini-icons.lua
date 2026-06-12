vim.pack.add {
  { src = "https://github.com/nvim-mini/mini.icons" },
}

require("mini.icons").setup {}

-- Let plugins that expect nvim-web-devicons use mini.icons instead.
require("mini.icons").mock_nvim_web_devicons()
