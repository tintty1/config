vim.pack.add {
  { src = "https://github.com/tintty1/toggleterm.nvim" },
}

require("toggleterm").setup {
  size = 20,
  open_mapping = [[<c-\>]],
  hide_numbers = true,
  shade_filetypes = {},
  shade_terminals = true,
  shading_factor = 2,
  start_in_insert = true,
  insert_mappings = true,
  persist_size = true,
  direction = "float",
  close_on_exit = true,
  shell = vim.o.shell,
  float_opts = {
    border = "curved",
    winblend = 0,
    highlights = {
      border = "Normal",
      background = "Normal",
    },
  },
}

-- Function to set terminal keymaps
function _G.set_terminal_keymaps()
  local opts = { buffer = 0 }
  vim.keymap.set("n", "<esc>", "<cmd>close<cr>", opts)
  vim.keymap.set("n", "q", "<cmd>close<cr>", opts)
end

-- Apply terminal keymaps when terminal opens
vim.cmd("autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()")
