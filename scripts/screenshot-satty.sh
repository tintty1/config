#!/bin/sh
# Capture a screenshot (region via slurp, or the focused monitor) and open
# satty to annotate. On save, satty writes to ~/Pictures/Screenshots and
# copies the result to the clipboard.
set -eu

mode="${1:-region}"
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
out="$dir/Screenshot from %Y-%m-%d %H-%M-%S.png"

case "$mode" in
  screen)
    output=$(niri msg --json focused-output | jq -r '.name')
    grim -o "$output" - > /tmp/screenshot-satty.png
    ;;
  region | *)
    # slurp exits non-zero when the selection is cancelled (Escape) -> bail out.
    geom=$(slurp) || exit 0
    grim -g "$geom" - > /tmp/screenshot-satty.png
    ;;
esac

satty --filename /tmp/screenshot-satty.png \
  --output-filename "$out" \
  --copy-command wl-copy \
  --actions-on-enter save-to-file \
  --early-exit
