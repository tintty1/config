#!/bin/bash
tmp=$(mktemp /tmp/edit.XXXXXX.txt)
wl-paste --no-newline > "$tmp" 2>/dev/null
kitty --class edit-popup nvim "$tmp"
wl-copy < "$tmp"
rm -f "$tmp"
