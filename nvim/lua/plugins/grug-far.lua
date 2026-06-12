vim.pack.add {
  { src = "https://github.com/MagicDuck/grug-far.nvim" },
}

local grug = require("grug-far")

grug.setup {}

vim.keymap.set("n", "<leader>sr", function()
  grug.open()
end, { desc = "Search & replace (grug-far)" })

vim.keymap.set("n", "<leader>sw", function()
  grug.open { prefills = { search = vim.fn.expand "<cword>" } }
end, { desc = "Search & replace word under cursor" })

vim.keymap.set("n", "<leader>sf", function()
  grug.open { prefills = { paths = vim.fn.expand "%" } }
end, { desc = "Search & replace in current file" })

vim.keymap.set("x", "<leader>sr", function()
  grug.with_visual_selection()
end, { desc = "Search & replace visual selection" })

-- mini.files integration: `gs` opens grug-far scoped to the focused directory
-- (the entry's own path if it's a directory, otherwise its parent). Reuses a
-- single named "explorer" instance, updating its paths on repeat invocations.
vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("GrugFarMiniFiles", { clear = true }),
  pattern = "MiniFilesBufferCreate",
  callback = function(args)
    vim.keymap.set("n", "gs", function()
      local entry = require("mini.files").get_fs_entry()
      if not entry then
        return
      end
      local path = entry.fs_type == "directory" and entry.path or vim.fs.dirname(entry.path)
      local prefills = { paths = path }
      if not grug.has_instance "explorer" then
        grug.open {
          instanceName = "explorer",
          prefills = prefills,
          staticTitle = "Find and Replace from Explorer",
        }
      else
        grug.get_instance("explorer"):open()
        -- update paths without clearing search/replace/other fields
        grug.get_instance("explorer"):update_input_values(prefills, false)
      end
    end, { buffer = args.data.buf_id, desc = "Search & replace in directory (grug-far)" })
  end,
})
