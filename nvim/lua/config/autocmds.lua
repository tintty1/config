-- Auto-check for file changes when gaining focus, entering buffer, or after idle
vim.api.nvim_create_autocmd({"FocusGained", "BufEnter", "CursorHold"}, {
  pattern = "*",
  command = "checktime"
})

-- Terminal windows inherit the global editor chrome (list/listchars, number column),
-- which looks wrong for a shell/tmux buffer. Turn it off for terminals.
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    vim.opt_local.list = false
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
  end,
})