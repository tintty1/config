vim.pack.add {
  { src = "https://github.com/coder/claudecode.nvim" },
}

local M = {}
local started = false

-- Start the Claude bridge lazily: WebSocket server + lock file, export the IDE env
-- vars, and register the send/diff keymaps. Idempotent.
--
-- This deliberately does NOT run at startup. nvim is the $EDITOR / pager for many
-- throwaway tasks (git commit, kubectl edit, kitty scrollback) and there is no point
-- spinning up a server + writing ~/.claude/ide/<port>.lock for those. Instead it
-- fires the first time a toggleterm terminal opens (see lua/plugins/toggleterm.lua).
--
-- Call it BEFORE the terminal's shell spawns so tmux/claude inherit CLAUDE_CODE_SSE_PORT
-- and auto-connect; the toggleterm helpers do exactly that. A terminal opened via the
-- bare <c-\> mapping starts the bridge slightly too late for its own shell, so that
-- claude connects with the `/ide` command instead.
function M.start()
  if started then
    return
  end
  started = true

  local cc = require("claudecode")
  cc.setup {
    auto_start = false, -- started manually below, on demand
    terminal = { provider = "none" }, -- claude runs in your tmux/toggleterm, not nvim
  }
  cc.start()

  if cc.state and cc.state.port then
    vim.env.ENABLE_IDE_INTEGRATION = "true"
    vim.env.CLAUDE_CODE_SSE_PORT = tostring(cc.state.port)
  end

  local map = vim.keymap.set

  -- Send code context (filename + line range; claude reads the snippet over the bridge).
  map("v", "<leader>as", "<cmd>ClaudeCodeSend<cr>", { desc = "Claude: send selection" })
  map("n", "<leader>as", function()
    local l = vim.fn.line(".")
    vim.cmd(string.format("ClaudeCodeAdd %s %d %d", vim.fn.fnameescape(vim.fn.expand("%:p")), l, l))
  end, { desc = "Claude: send current line" })
  map("n", "<leader>aa", function()
    vim.api.nvim_feedkeys(":ClaudeCodeAdd " .. vim.fn.expand("%:p") .. " ", "n", false)
  end, { desc = "Claude: add file (type line range)" })

  -- Review the diffs claude proposes.
  map("n", "<leader>ay", "<cmd>ClaudeCodeDiffAccept<cr>", { desc = "Claude: accept diff" })
  map("n", "<leader>an", "<cmd>ClaudeCodeDiffDeny<cr>", { desc = "Claude: deny diff" })
  map("n", "<leader>a?", "<cmd>ClaudeCodeStatus<cr>", { desc = "Claude: status" })

  -- After a send completes, surface the tmux+claude session as a vertical split
  -- without stealing focus. Helper lives in plugins/toggleterm.lua.
  vim.api.nvim_create_autocmd("User", {
    pattern = "ClaudeCodeSendComplete",
    callback = function()
      if _G.toggleterm_show then
        pcall(_G.toggleterm_show, "vertical")
      end
    end,
  })
end

-- Escape hatch: start the bridge manually (e.g. when running claude outside toggleterm).
vim.api.nvim_create_user_command("ClaudeStart", function()
  M.start()
end, { desc = "Start the Claude Code bridge" })

return M
