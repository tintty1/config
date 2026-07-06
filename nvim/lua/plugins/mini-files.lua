vim.pack.add {
  { src = "https://github.com/nvim-mini/mini.files" },
}

local MiniFiles = require("mini.files")

MiniFiles.setup {
  windows = {
    preview = true,
  },
}

-- Open the explorer focused on the current file (falls back to cwd).
vim.keymap.set("n", "<leader>fe", function()
  local buf_name = vim.api.nvim_buf_get_name(0)
  local path = (buf_name ~= "" and vim.bo.buftype == "") and buf_name or nil
  MiniFiles.open(path)
end, { desc = "File explorer (mini.files)" })

-- Map <CR> as an additional key for `go_in_plus` (alongside the default `L`).
-- Map `p` to preview image files with imv-wayland.
local image_exts = {
  png = true,
  jpg = true,
  jpeg = true,
  gif = true,
  bmp = true,
  webp = true,
  tiff = true,
  tif = true,
  svg = true,
  avif = true,
  jxl = true,
  ico = true,
}

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesBufferCreate",
  callback = function(args)
    vim.keymap.set("n", "<CR>", function()
      MiniFiles.go_in { close_on_file = true }
    end, { buffer = args.data.buf_id, desc = "Go in entry (and close on file)" })

    vim.keymap.set("n", "p", function()
      local entry = MiniFiles.get_fs_entry()
      if not entry or entry.fs_type ~= "file" then
        return
      end
      local ext = entry.name:match("%.([^.]+)$")
      if not (ext and image_exts[ext:lower()]) then
        vim.notify("Not an image file: " .. entry.name, vim.log.levels.WARN)
        return
      end
      vim.system { "imv-wayland", entry.path }
    end, { buffer = args.data.buf_id, desc = "Preview image with imv-wayland" })
  end,
})

-- ---------------------------------------------------------------------------
-- Git status integration: color entry names and show a status glyph based on
-- `git status` for the repo of the directory being shown.
-- ---------------------------------------------------------------------------

local augroup = vim.api.nvim_create_augroup("MiniFilesGit", { clear = true })
local ns = vim.api.nvim_create_namespace("MiniFilesGit")

local function set_git_hl()
  local links = {
    MiniFilesGitUntracked = "DiagnosticHint",
    MiniFilesGitAdded = "DiagnosticOk",
    MiniFilesGitModified = "DiagnosticWarn",
    MiniFilesGitDeleted = "DiagnosticError",
    MiniFilesGitRenamed = "DiagnosticWarn",
    MiniFilesGitCopied = "DiagnosticWarn",
    MiniFilesGitConflict = "DiagnosticError",
  }
  for from, to in pairs(links) do
    vim.api.nvim_set_hl(0, from, { link = to, default = true })
  end
end
set_git_hl()
vim.api.nvim_create_autocmd("ColorScheme", { group = augroup, callback = set_git_hl })

-- Map a 2-char `git status --porcelain` code to a glyph + highlight group.
local function git_symbol(code)
  if code == "!!" then
    return nil
  end
  if code == "??" then
    return "?", "MiniFilesGitUntracked"
  end
  if code:find("U", 1, true) or code == "AA" or code == "DD" then
    return "!", "MiniFilesGitConflict"
  end
  local x, y = code:sub(1, 1), code:sub(2, 2)
  if x == "R" then
    return "→", "MiniFilesGitRenamed"
  end
  if x == "C" then
    return "→", "MiniFilesGitCopied"
  end
  if x == "A" or y == "A" then
    return "+", "MiniFilesGitAdded"
  end
  if x == "D" or y == "D" then
    return "-", "MiniFilesGitDeleted"
  end
  return "~", "MiniFilesGitModified"
end

local git_cache = {}
local cached_root = nil

local function git_root(dir)
  local out = vim.fn.system { "git", "-C", dir, "rev-parse", "--show-toplevel" }
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return vim.trim(out)
end

local function build_cache(root)
  local cache = {}
  local out = vim.fn.systemlist {
    "git",
    "-C",
    root,
    "-c",
    "core.quotepath=false",
    "status",
    "--porcelain",
    "--ignored=no",
  }
  if vim.v.shell_error ~= 0 then
    return cache
  end
  for _, line in ipairs(out) do
    if #line > 3 then
      local code = line:sub(1, 2)
      local rel = line:sub(4)
      -- For renames/copies ("old -> new") keep the new path.
      local arrow = rel:find(" -> ", 1, true)
      if arrow then
        rel = rel:sub(arrow + 4)
      end
      rel = rel:gsub('^"(.*)"$', "%1"):gsub("/$", "")
      local abs = root .. "/" .. rel
      cache[abs] = code
      -- Propagate to ancestor directories so changed dirs are flagged too.
      local parent = vim.fs.dirname(abs)
      while parent and parent ~= root and #parent > #root do
        if not cache[parent] then
          cache[parent] = code
        end
        parent = vim.fs.dirname(parent)
      end
    end
  end
  return cache
end

local function ensure_cache(dir)
  local root = git_root(dir)
  if not root then
    git_cache, cached_root = {}, nil
    return
  end
  if root ~= cached_root then
    git_cache = build_cache(root)
    cached_root = root
  end
end

local function apply(buf_id)
  if not vim.api.nvim_buf_is_valid(buf_id) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
  for i, line in ipairs(lines) do
    local entry = MiniFiles.get_fs_entry(buf_id, i)
    if entry then
      local code = git_cache[entry.path]
      if code then
        local sym, hl = git_symbol(code)
        if sym then
          local opts = {
            virt_text = { { sym, hl } },
            virt_text_pos = "right_align",
            hl_mode = "combine",
          }
          local s = line:find(entry.name, 1, true)
          if s then
            opts.end_col = s - 1 + #entry.name
            opts.hl_group = hl
            vim.api.nvim_buf_set_extmark(buf_id, ns, i - 1, s - 1, opts)
          else
            vim.api.nvim_buf_set_extmark(buf_id, ns, i - 1, 0, opts)
          end
        end
      end
    end
  end
end

local function on_update(buf_id)
  local entry = MiniFiles.get_fs_entry(buf_id, 1)
  if not entry then
    return
  end
  ensure_cache(vim.fs.dirname(entry.path))
  apply(buf_id)
end

vim.api.nvim_create_autocmd("User", {
  group = augroup,
  pattern = "MiniFilesExplorerOpen",
  callback = function()
    cached_root = nil
  end,
})

vim.api.nvim_create_autocmd("User", {
  group = augroup,
  pattern = "MiniFilesBufferUpdate",
  callback = function(args)
    on_update(args.data.buf_id)
  end,
})

-- Rebuild the cache after any file system manipulation.
for _, action in ipairs { "Create", "Delete", "Rename", "Copy", "Move" } do
  vim.api.nvim_create_autocmd("User", {
    group = augroup,
    pattern = "MiniFilesAction" .. action,
    callback = function()
      cached_root = nil
    end,
  })
end
