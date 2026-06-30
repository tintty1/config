#!/bin/bash
# Maximize the focused window to fill the workspace.
#
# niri's layout: a workspace holds columns left-to-right; a column may stack
# several windows top-to-bottom. A window that is alone in its column is
# already full-height, so maximizing the column width fills the screen.
#
#   - floating window      -> move it to the tiling layout first, then proceed.
#   - stacked in a column   -> expel it into its own column (consume-or-expel
#     keeps focus on it, so it becomes full-height), then maximize the width.
#   - already alone         -> just maximize the column.
#   - nothing focused       -> nothing to do.

# If the focused window is floating, tile it first so the logic below applies.
if [ "$(niri msg --json focused-window | jq -r '.is_floating')" = "true" ]; then
    niri msg action move-window-to-tiling
fi

wins=$(niri msg --json windows)

# Focused window's workspace id and column index (pos_in_scrolling_layout[0]).
read -r ws col < <(echo "$wins" | jq -r '
    .[] | select(.is_focused) |
    "\(.workspace_id) \(.layout.pos_in_scrolling_layout[0] // "none")"')

# Nothing focused, or still no scrolling position.
[ -z "$ws" ] || [ "$col" = "none" ] && exit 0

# How many windows live in that same column of that workspace.
count=$(echo "$wins" | jq --argjson ws "$ws" --argjson col "$col" '
    [.[] | select(.workspace_id == $ws
        and (.layout.pos_in_scrolling_layout[0] // -1) == $col)] | length')

if [ "$count" -gt 1 ]; then
    niri msg action consume-or-expel-window-right
fi
niri msg action maximize-column
