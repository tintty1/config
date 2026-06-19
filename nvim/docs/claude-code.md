# Claude Code integration

This Neovim config integrates [coder/claudecode.nvim](https://github.com/coder/claudecode.nvim)
to send code context from Neovim to a `claude` session running in tmux inside a
toggleterm terminal.

## How it works

`claude` talks to an "IDE" over a local WebSocket. Rather than letting the plugin
spawn and manage a terminal, this setup uses `terminal.provider = "none"`:

- Neovim hosts the WebSocket **bridge** + editor tools (selections, diffs, diagnostics).
- When the bridge starts it writes a lock file to `~/.claude/ide/<port>.lock` and exports
  `ENABLE_IDE_INTEGRATION=true` and `CLAUDE_CODE_SSE_PORT=<port>` into Neovim's env.
- `claude` is launched manually in tmux (inside a toggleterm window).
- Sends (`:ClaudeCodeSend` / `:ClaudeCodeAdd`) travel over the bridge to whatever
  `claude` instance is connected — the plugin sends `filename + line range` and
  `claude` reads the snippet itself.

### Lazy start (no cost in throwaway nvims)

The bridge is **not** started at Neovim startup. Since nvim is the `$EDITOR` / pager
for many short-lived tasks (`git commit`, `kubectl edit`, kitty scrollback), starting
a server and writing a lock file for those would be wasted work (~8 ms + a socket + a
disk write each, plus lock-file clutter in `~/.claude/ide/`).

Instead the bridge starts the **first time a toggleterm terminal opens**:

- `terminal.on_open` (in `lua/plugins/toggleterm.lua`) is a catch-all that calls
  `require("plugins.claudecode").start()` — so sends work even for a float opened with
  the bare `<c-\>` mapping.
- The `_G.toggleterm_toggle` helpers (`<leader>v` / `<leader>tf`) call `start()`
  *before* spawning the shell, so a claude opened that way inherits the env and
  auto-connects with no `/ide` step.
- `start()` is idempotent and also registers the keymaps below.

A throwaway nvim that never opens a terminal pays only ~1 ms (the plugin's load guard)
and writes no lock file. Start the bridge manually anytime with `:ClaudeStart`.

### Files

| File | Role |
|------|------|
| `lua/plugins/claudecode.lua` | Lazy `start()` (setup + server + env export + send/diff keymaps + auto-show autocmd), `:ClaudeStart` command |
| `lua/plugins/toggleterm.lua` | Singleton terminal: `:Vterm`/`:Hterm`/`:Fterm`/`:TermCycle` commands, `on_open` bridge trigger, `_G.toggleterm_show` (used by the send autocmd) |
| `init.lua` | `require("plugins.claudecode")` |

## Connecting claude to Neovim

Since `claude` is launched manually, it must connect to the bridge. Whether it
auto-connects depends on how the terminal was opened (the env vars must be set
*before* the shell spawns):

- **Terminal opened via `<leader>v` / `<leader>tf`** (or after `:ClaudeStart`): the
  bridge is already up, so a freshly spawned tmux/claude inherits
  `CLAUDE_CODE_SSE_PORT` and **auto-connects**.
- **Float opened with bare `<c-\>`**: the bridge starts a moment too late for that
  shell, so run `/ide` inside `claude` once to connect (it discovers the lock file in
  `~/.claude/ide/`).
- **Pre-existing/persistent tmux server**: it has a stale environment regardless, so
  use `/ide`.

Verify the bridge and connection with:

```vim
:checkhealth claudecode
:ClaudeCodeStatus
```

## Keymaps

### Sending context (`<leader>a` — "AI")

> The `<leader>a` prefix is used because `<leader>ca` is already the LSP code-action map.

| Key | Mode | Action |
|-----|------|--------|
| `<leader>as` | visual | Send the selection (file + line range) |
| `<leader>as` | normal | Send the current line |
| `<leader>aa` | normal | Prefill `:ClaudeCodeAdd <file> ` — type a line range, then `<CR>` |
| `<leader>ay` | normal | Accept a diff claude proposes |
| `<leader>an` | normal | Deny a diff claude proposes |
| `<leader>a?` | normal | Show connection status |

### Terminal layout

There is a **single terminal per nvim instance** (id 1). Each command creates it if
missing, hides it if already shown in that layout, or switches it to that layout
otherwise. Switching layout re-displays the **same** persistent buffer, so the
tmux/claude session never restarts. Sizes: vertical width = 40% of columns,
horizontal height = 30% of lines, float uses `float_opts`.

| Command | Key | Action |
|---------|-----|--------|
| `:Vterm` | `<leader>v` | Vertical split (create/toggle) |
| `:Hterm` | `<leader>th` | Horizontal split (create/toggle) |
| `:Fterm` | `<leader>tf` | Float (create/toggle) |
| `:TermCycle` | `<leader>tc` | Cycle layout: vertical → horizontal → float |
| | `<c-\>` | Toggle the term (toggleterm's `open_mapping`, unchanged) |

After a send completes, the vertical panel auto-appears **without stealing focus**
(via the `User ClaudeCodeSendComplete` autocmd in `lua/plugins/claudecode.lua`) so
claude's reaction stays visible. Remove that autocmd to show the panel manually instead.

## Typical workflow

1. Open Neovim and open the terminal with `<leader>v` (vertical) or `<leader>tf`
   (float) — this starts the bridge. Then `tmux`, then `claude`.
   - Opening with bare `<c-\>` also works; just run `/ide` in `claude` once to connect.
2. Edit code. Select lines and press `<leader>as` to send context.
3. Press `<leader>v` (or let the auto-show do it) to view claude in a side panel.
4. Review claude's edits with `<leader>ay` (accept) / `<leader>an` (deny).

## Notes & caveats

- **Multiple claude instances**: `:ClaudeCodeSend` broadcasts to **all** connected
  clients. Connect only the desired instance via `/ide` when this matters.
- **provider = "none"**: features that write directly to a terminal's job channel
  (e.g. typing text into the terminal) are unavailable — claude runs outside Neovim.
  At-mention sends, diffs, and tools all still work over the bridge.
- `nvim-pack-lock.json` pins the installed `claudecode.nvim` revision; commit it
  alongside config changes.

## Reference

- Plugin: <https://github.com/coder/claudecode.nvim>
- Lock files: `~/.claude/ide/<port>.lock` (or `$CLAUDE_CONFIG_DIR/ide/`)
- Useful commands: `:ClaudeCode`, `:ClaudeCodeFocus`, `:ClaudeCodeSend`,
  `:ClaudeCodeAdd`, `:ClaudeCodeStatus`, `:ClaudeCodeStart`, `:ClaudeCodeStop`,
  `:ClaudeCodeDiffAccept`, `:ClaudeCodeDiffDeny`, `:ClaudeCodeSelectModel`
