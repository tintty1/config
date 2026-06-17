-- Auto-check for file changes when gaining focus, entering buffer, or after idle
vim.api.nvim_create_autocmd({"FocusGained", "BufEnter", "CursorHold"}, {
  pattern = "*",
  command = "checktime"
})