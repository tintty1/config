" Minimal nvim init, used only as kitty's scrollback pager.
" Launched via `nvim -u this-file --noplugin -i NONE -`, so it gets none of the
" real nvim config or plugins. nvim_open_term re-renders the piped stdin buffer
" through nvim's terminal emulator, preserving ANSI colors. Plain vim motions
" work for navigation; q quits.

set nomodified nolist nonumber norelativenumber
set laststatus=0 showtabline=0 signcolumn=no

" Yank straight to the system clipboard (wl-copy/xclip provider).
set clipboard=unnamedplus

nnoremap q ZQ

" Base64 encode/decode and copy the result to the clipboard. The pager buffer
" is read-only, so we never touch it.
"   <space>be / :Base64Encode -> encode to clipboard
"   <space>bd / :Base64Decode -> decode to clipboard
" The visual mappings act on the charwise selection; the :commands act on their
" line range (e.g. :'<,'>Base64Encode, or :% for the whole buffer).
lua << EOF
vim.g.mapleader = ' '

local function b64_copy(text, decode)
  if decode then
    text = text:gsub('%s+', '') -- base64 carries no whitespace; drop stray newlines
  end
  local ok, result = pcall(decode and vim.base64.decode or vim.base64.encode, text)
  if not ok then
    vim.notify(result, vim.log.levels.ERROR)
    return
  end
  vim.fn.setreg('+', result)
  vim.notify(('Base64-%s and copied to clipboard'):format(decode and 'decoded' or 'encoded'))
end

-- Live visual selection (works in a read-only/terminal buffer).
local function selection_text()
  local mode = vim.fn.mode()
  local region = vim.fn.getregion(vim.fn.getpos('v'), vim.fn.getpos('.'), { type = mode })
  vim.cmd('normal! \27') -- leave visual mode
  return table.concat(region, '\n')
end

-- Full lines covered by a command's range, minus the blank terminal padding.
local function range_text(opts)
  local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
  while #lines > 1 and lines[#lines]:match('^%s*$') do
    table.remove(lines)
  end
  return table.concat(lines, '\n')
end

vim.keymap.set('x', '<leader>be', function() b64_copy(selection_text(), false) end, { silent = true, desc = 'Base64 encode -> clipboard' })
vim.keymap.set('x', '<leader>bd', function() b64_copy(selection_text(), true) end, { silent = true, desc = 'Base64 decode -> clipboard' })

vim.api.nvim_create_user_command('Base64Encode', function(o) b64_copy(range_text(o), false) end, { range = '%', desc = 'Base64 encode range -> clipboard' })
vim.api.nvim_create_user_command('Base64Decode', function(o) b64_copy(range_text(o), true) end, { range = '%', desc = 'Base64 decode range -> clipboard' })
EOF

" Render the loaded scrollback once startup is done, then jump to the bottom
" (the most recent output).
autocmd VimEnter * call nvim_open_term(0, {}) | normal! G
