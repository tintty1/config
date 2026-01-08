#!/bin/bash

EDITOR_CMD="kitty --single-instance --title edit-with-vim nvim"

TMPFILE=$(mktemp /tmp/edit_field_XXXXXX.txt)
CLIPBOARD_BACKUP=$(mktemp /tmp/clipboard_backup_XXXXXX.txt)

xclip -selection clipboard -o > "$CLIPBOARD_BACKUP" 2>/dev/null

WINDOW_ID=$(xdotool getactivewindow)

xdotool windowfocus "$WINDOW_ID"
sleep 0.05

xdotool key --window "$WINDOW_ID" ctrl+a
sleep 0.05
xdotool key --window "$WINDOW_ID" ctrl+c
sleep 0.05

xclip -selection clipboard -o > "$TMPFILE"

$EDITOR_CMD "$TMPFILE"

xclip -selection clipboard -i < "$TMPFILE"

rm -f "$TMPFILE"

# to make sure kitty window is closed
sleep 0.1

xdotool windowactivate "$WINDOW_ID"
sleep 0.1

xdotool key --window "$WINDOW_ID" ctrl+a
sleep 0.1
xdotool key --window "$WINDOW_ID" ctrl+v

if [ -s "$CLIPBOARD_BACKUP" ]; then
    cat "$CLIPBOARD_BACKUP" | xclip -selection clipboard
fi

rm -f "$CLIPBOARD_BACKUP"
