#!/bin/bash
# Toggle the "scratch" workspace: focus it, or return to the previous
# workspace if scratch is already focused.
focused=$(niri msg --json workspaces | jq -r '.[] | select(.is_focused) | .name')

if [ "$focused" = "scratch" ]; then
    niri msg action focus-workspace-previous
else
    niri msg action focus-workspace "scratch"
fi
