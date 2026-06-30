#!/bin/bash
# Directional focus that spills into the adjacent workspace at the edge.
# Move focus in the given direction; if focus didn't move (we were already
# at the edge of the workspace), jump to the adjacent workspace and focus
# its first window in that direction.
#
# Usage: focus-spill.sh <left|right|up|down>

case "$1" in
    right) move="focus-column-right"; spill="focus-workspace-down"; edge="focus-column-first" ;;
    left)  move="focus-column-left";  spill="focus-workspace-up";   edge="focus-column-last"  ;;
    down)  move="focus-window-down";  spill="focus-workspace-down"; edge="focus-window-top"    ;;
    up)    move="focus-window-up";    spill="focus-workspace-up";   edge="focus-window-bottom" ;;
    *) echo "usage: $0 <left|right|up|down>" >&2; exit 1 ;;
esac

before=$(niri msg --json focused-window | jq -r '.id // empty')
niri msg action "$move"
after=$(niri msg --json focused-window | jq -r '.id // empty')

if [ "$before" = "$after" ]; then
    niri msg action "$spill"
    niri msg action "$edge"
fi
