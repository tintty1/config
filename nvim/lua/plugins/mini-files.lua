vim.pack.add {
  { src = "https://github.com/nvim-mini/mini.files" },
}

require("mini.files").setup {
  windows = {
    preview = true,
  },
}

-- Open the explorer focused on the current file (falls back to cwd).
vim.keymap.set("n", "<leader>fe", function()
  local buf_name = vim.api.nvim_buf_get_name(0)
  local path = (buf_name ~= "" and vim.bo.buftype == "") and buf_name or nil
  require("mini.files").open(path)
end, { desc = "File explorer (mini.files)" })
