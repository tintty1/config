-- load plugin manager
require("config.lazy")

-- load config
require("config.options")
require("config.keymaps")
require("config.ft")
require("config.autocmds")
require("config.user-cmds")

-- set default colorscheme
vim.cmd.colorscheme("catppuccin")
