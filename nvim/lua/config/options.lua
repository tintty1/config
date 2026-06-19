vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.wrap = false
vim.o.linebreak = true
vim.o.list = true
vim.o.listchars = [[tab:> ,trail:-,nbsp:+]]

vim.o.messagesopt = "hit-enter,history:1000"

-- Shorten the wait for multi-key maps (e.g. terminal <esc><esc>) so a lone <esc>
-- passes through to tmux/claude quickly.
vim.o.timeoutlen = 300

-- Open new splits to the right and below
vim.o.splitright = true
vim.o.splitbelow = true

-- Auto-reload files when changed outside Neovim
vim.opt.autoread = true
