---
name: niri-computer-use
description: Drive GUI applications on a niri Wayland desktop through an isolated nested niri session - launch a sandboxed compositor, start apps inside it, then see and act through the bundled `gui` helper (one shell call per semantic action - click/type/scroll/ask - with vision offloaded to a cheap model, plus `gui run` for autonomous multi-step subtasks). Use this whenever the user wants an agent to see the screen and click/type/scroll in GUI apps on niri, or mentions automating desktop apps on Wayland. Only works on niri, not X11.
---

# Nested-niri GUI Agent

Run a nested niri as a sandbox, launch apps inside it, drive them with the bundled `scripts/gui` helper — one shell call per semantic action. The parent desktop stays untouched.

Tools: `scripts/gui` (next to this SKILL.md), `niri` (compositor + IPC), `grim`, `wtype`, `wlrctl`, `wl-copy`/`wl-paste`, `jq`, `identify` (imagemagick), the `ai` CLI.

**Every command must target the nested session.** `WAYLAND_DISPLAY=$NESTED_DISPLAY` for grim/wtype/wlrctl/wl-copy and app launches; `NIRI_SOCKET=$NESTED_SOCKET` for `niri msg`. Omitting one silently hits the parent session instead — the main failure mode.

## 1. Start the session

Detect an existing nested niri first (any niri socket that isn't the parent's `$NIRI_SOCKET`):

```bash
ls /run/user/$(id -u)/niri.*.sock | grep -v "^$NIRI_SOCKET$"
```

If found, ask whether to reuse it. Otherwise start one and read its socket from the log:

```bash
niri -c ~/.config/niri/nested.kdl > /tmp/nested-niri.log 2>&1 &
sleep 1
grep "IPC listening" /tmp/nested-niri.log   # -> /run/user/1000/niri.wayland-2.XXXXXXX.sock
export NESTED_DISPLAY=wayland-2
export NESTED_SOCKET=/run/user/1000/niri.wayland-2.XXXXXXX.sock
```

`nested.kdl` is tuned for automation: key-repeat off, hot corners off, `gaps 0`, and a catch-all window rule that opens **every window full width** — a fresh window is exactly screen-sized, so vision coordinates need no correction.

When the task is finished, tear the whole sandbox down (apps die with the compositor):

```bash
pkill -f 'niri -c .*nested.kdl'
```

## 2. Launch apps

```bash
WAYLAND_DISPLAY=$NESTED_DISPLAY alacritty &
WAYLAND_DISPLAY=$NESTED_DISPLAY google-chrome --ozone-platform=wayland --no-default-browser-check --user-data-dir=$HOME/.config/chrome-agent &
```

Single-instance apps (browsers) otherwise open in the parent's running instance. Force a new instance with a separate profile: Chrome/Electron `--user-data-dir=...` (no `--new-instance` flag), Firefox `-P name --new-instance`. Chromium/Electron also need `--ozone-platform=wayland` or they land in the parent's Xwayland. Verify placement: `NIRI_SOCKET=$NESTED_SOCKET niri msg --json windows | jq '.[].app_id'`.

**The D-Bus session bus is shared with the parent** — `WAYLAND_DISPLAY` does not isolate it. D-Bus single-instance apps (Thunar, most GNOME/XFCE apps) will hand off to an existing daemon instead of opening in the sandbox — including a *stale* daemon from a previous nested session, which makes the launch silently do nothing. Launch such apps with a private bus:

```bash
WAYLAND_DISPLAY=$NESTED_DISPLAY dbus-run-session -- thunar &
```

## 3. Acting: the `gui` helper (default path)

**Use `scripts/gui` (next to this SKILL.md) for all seeing and acting — one call per semantic action.** It bundles settle → `grim` → vision-locate → 0-1000→pixel rescale → anchor → `wlrctl`/`wtype` → re-screenshot → one-line verify into a single command. One tool call and a one-line result per action, instead of ~6 round-trips whose intermediate output permanently bloats your context. Sections 4–7 document the primitives it wraps — drop to them only for interactions the helper can't express (interleaved mid-drag actions, exotic input) or to debug it.

```bash
GUI=<this skill's dir>/scripts/gui           # NESTED_DISPLAY + NESTED_SOCKET must be exported (§1)

$GUI click "the blue Next button"            # → clicked (742,310) '...' + one-line verify
$GUI isolate Alacritty                       # move target alone to an empty workspace (when clutter accumulates)
$GUI click "the Close button" --button right --no-verify
$GUI type "hello world" --enter              # clipboard-paste (avoids key-repeat), then Return
$GUI type "ls -la" --terminal --enter        # terminals need ctrl+shift+v
$GUI type "/etc/fonts" --replace --enter     # field already has content (path bar, search box):
                                             #   select-all first so the text REPLACES instead of
                                             #   mixing into the old text at the caret
$GUI type "/etc/fonts" --via ctrl+l --replace --enter   # focus the field by ITS shortcut, type, Enter —
                                             #   the reliable recipe for GTK location bars (see §6)
$GUI key ctrl+s Escape                       # shortcuts / named keys (libxkbcommon names)
$GUI scroll 5 --at "the results list"        # positive = down; moves cursor there first
$GUI drag "the volume slider" 120 0          # locate start, then drag by (dx,dy)
$GUI ask "is the login form visible and focused?"
$GUI ask --window Alacritty "what error is shown?"   # window-buffer shot: clutter-free, even if partly off-screen
$GUI locate "the search box"                 # debug: prints real pixel coords
$GUI shot [--window <id|app_id>]             # debug: screenshot only
```

Knobs (env): `GUI_MODEL` (default `google/gemini-3.1-flash-lite-preview`), `GUI_SETTLE` (0.6 s repaint settle), `GUI_VERIFY=0` (skip the verify screenshot), `GUI_WINDOW` (default `--window` for ask/shot), `GUI_MAX_STEPS` (run cap, 15), `GUI_TEMP` (1.0), `GUI_DIR` (`/tmp/niri-gui`, keeps last screenshots + `ai-stderr.log` for debugging).

`--window` is **perception only**: it uses niri's builtin `screenshot-window`, whose pixels are window-relative — there is no way to map those to screen coordinates for clicking (§4). So `click`/`locate`/`run` always shoot the full screen.

**`gui isolate <win>` dissolves that split**: moved alone to an empty workspace at full width, the full-screen shot *is* the window view — clutter-free like a buffer shot, but its pixels are native screen coordinates, so clicks land without any mapping. `nested.kdl` already opens **every** window full width with `gaps 0` (window pixels == screen pixels), so a fresh window needs no prep — reach for `isolate` once other windows have accumulated on the workspace.

### Multi-step subtasks: `gui run`

For a well-defined flow, push the whole loop down to the cheap vision model: each step it sees the current screenshot plus the action history and picks the next action itself; the script executes it. One tool call per *subtask* — you get back the action log and a `RESULT:` line, with per-step screenshots in `$GUI_DIR/step-*.png` for post-mortem.

```bash
$GUI run "open example.com and accept the cookie banner" --max-steps 15
```

Exit 0 = the model declared success. Treat that as a claim, not proof: spot-check the end state (`$GUI ask ...`) when it matters. If a run flails (same action repeated, gave-up RESULT), take over and step manually with `$GUI click`/`type` — you're the planner; `run` is for flows the cheap model can sequence on its own.

## 4. Window state (niri IPC)

```bash
NIRI_SOCKET=$NESTED_SOCKET niri msg --json windows          # id, app_id, title, layout
NIRI_SOCKET=$NESTED_SOCKET niri msg action focus-window --id <ID>   # does NOT move the cursor
```

Per-window `layout` has sizes only: `tile_size`, `window_size`, `window_offset_in_tile`, `pos_in_scrolling_layout` [column,row]. **There is no window *position* in the IPC** — `tile_pos_in_workspace_view` exists but is always `null` on niri ≥ 26.04 (verified), so on-screen pixel positions must come from vision, never from IPC math. IPC is still free structured state for "which windows exist / which is focused".

niri also has builtin screenshot actions (what `gui --window` uses):

```bash
NIRI_SOCKET=$NESTED_SOCKET niri msg action screenshot-window --id <ID> --path /abs/path.png
NIRI_SOCKET=$NESTED_SOCKET niri msg action screenshot-screen --path /abs/path.png   # grim alternative
```

`screenshot-window` captures the window's **full buffer** regardless of on-screen position — including parts hanging off-screen — which makes it ideal for reading a specific window on a cluttered workspace. Two traps: the action returns **before** the file is written (async — poll for the file), and every screenshot action also copies the image to the nested clipboard (harmless to `gui type`, which re-copies text immediately before each paste).

Sizing acts on the focused window (`focus-window --id` first): `set-window-width 800` (also `+100`/`50%`), `set-window-height`, `maximize-column`, `fullscreen-window` (toggle). `nested.kdl`'s catch-all window rule opens everything full width already; these are for deliberately shrinking a window.

## 5. Mouse (wlrctl)

`wlrctl pointer` drives a virtual mouse using **relative displacements only** — there is no absolute-position command. Each arg is a pixel displacement, positive = right/down, negatives allowed:

- `move <dx> <dy>` — move cursor by (dx right, dy down)
- `scroll <dy> <dx>` — **vertical first**: positive dy scrolls down, dx scrolls horizontally
- `click [button]` — `left` (default), `right`, or `middle`
- `drag <dx> <dy> [button:left] [steps:20] [interval:10]` — press, move by (dx,dy) as interpolated steps, release — all in one process
- `press [button]` / `release [button]` — hold / let go of a button; the hold persists across separate invocations (niri keeps the button state after the wlrctl process exits)

Reach an absolute point by anchoring: move by a huge negative displacement so the compositor clamps the cursor at the top-left corner (0,0), then move by exactly (X,Y). Re-anchor before every positioned action, since you never know where the cursor currently is:

```bash
WAYLAND_DISPLAY=$NESTED_DISPLAY wlrctl pointer move -9999 -9999   # anchor: clamp to (0,0)
WAYLAND_DISPLAY=$NESTED_DISPLAY wlrctl pointer move <X> <Y>       # now at absolute (X,Y)
WAYLAND_DISPLAY=$NESTED_DISPLAY wlrctl pointer click              # or: click right / click middle
WAYLAND_DISPLAY=$NESTED_DISPLAY wlrctl pointer scroll 5 0         # scroll down 5
```

Target pixels come from vision on a full-screen screenshot (§7) — window-relative math is not possible, see §4. Scroll targets whatever is under the cursor, so move into the box first. Rescale coordinates by `actual/image` if the screenshot was downscaled.

### Dragging (text selection, sliders, drag-and-drop)

Anchor + move to the start point, then `drag` by the displacement to the end point. `drag` holds one connection for press → interpolated motion → release, so it works where a plain press/jump/release doesn't: apps that only start a drag after several motion events while pressed (DnD thresholds, kinetic scrolling, canvas/slider apps).

```bash
# select a line of text: start at its left edge, drag right across it
WAYLAND_DISPLAY=$NESTED_DISPLAY wlrctl pointer move -9999 -9999
WAYLAND_DISPLAY=$NESTED_DISPLAY wlrctl pointer move <startX> <startY>
WAYLAND_DISPLAY=$NESTED_DISPLAY wlrctl pointer drag 215 0      # dx,dy = end - start
```

- The endpoint lands exactly `(dx, dy)` from the start regardless of `steps` (rounding is accumulated, not dropped per step).
- Bump `steps`/`interval` for stubborn apps (e.g. `steps:40 interval:15` ≈ a slower, smoother drag); `interval:0` is clamped up to 1ms.
- `drag` is a single process — **preferred**. Use `press`/`release` separately only when you must interleave other actions mid-drag (move, screenshot, focus). A `press` with no matching `release` leaves the button stuck; recover by running a bare `wlrctl pointer release`.

```bash
# manual drag across separate invocations (button stays held between them)
WAYLAND_DISPLAY=$NESTED_DISPLAY wlrctl pointer move <startX> <startY>
WAYLAND_DISPLAY=$NESTED_DISPLAY wlrctl pointer press
WAYLAND_DISPLAY=$NESTED_DISPLAY wlrctl pointer move 100 0
WAYLAND_DISPLAY=$NESTED_DISPLAY wlrctl pointer move 100 0
WAYLAND_DISPLAY=$NESTED_DISPLAY wlrctl pointer release
```

To confirm a text-selection drag worked, read the primary selection: `WAYLAND_DISPLAY=$NESTED_DISPLAY wl-paste --primary` (terminals put mouse selections there).

## 6. Keyboard (wtype + clipboard)

`wtype` simulates keyboard input (like `xdotool type`). Bare text types it verbatim; flags do the rest:

- `-k KEY` — press+release a named key (libxkbcommon names: `Return`, `Tab`, `Escape`, `Left`, `Home`, …)
- `-M MOD` / `-m MOD` — press / release a modifier (`ctrl`, `shift`, `alt`, `logo`, `altgr`); a `-M` before a `-k` on the same line holds it for that keypress, and all modifiers auto-release when wtype exits
- `-d MS` — delay between keystrokes when typing text

How to type depends on the target — all verified against Thunar (GTK) and alacritty:

- **Terminals**: clipboard paste. `wl-copy` the text, then `wtype -M ctrl -M shift -k v` (+ `-k Return` in the same invocation to run it). Fast and multiline-safe.
- **GUI/GTK apps**: literal typing, `wtype -d 15 "text"`. Key-repeat mangling isn't a concern because `nested.kdl` sets `repeat-delay 10000`.
- **Enter/activation in GUI apps**: `wlrctl keyboard type $'\n'` — **`wtype -k Return` is silently ignored by GTK entries** (it works in terminals, which is exactly why it looks fine until you hit a GTK app). Other named keys and chords (`-k Escape`, `-M ctrl -k s`) work via wtype.

**Three GTK quirks with wtype's virtual keyboards** (terminals are immune to all of them; manual input through the parent compositor is a real, persistent keyboard and never hits these):

1. **Cold start**: GTK decodes the *first* wtype invocation after a fresh compositor start with the wrong keymap — a chord like ctrl+v arrives as ctrl+*digit*, text as garbage. Warm the session up once with a modifier-only call, `wtype -M shift -m shift` (modifier events are a semantic bitmask, immune to mistranslation). `gui` does this automatically per session.
2. **Paste abort**: GTK fetches the clipboard *asynchronously*; wtype exiting right after ctrl+v destroys its virtual keyboard and the fetch is cancelled. Paste works if the process lingers (e.g. trailing `-d 2000 -k Shift_L`), but literal typing avoids the hack entirely — that's why it's the GUI default.
3. **Return activation**: even warm and in-process, `wtype -k Return` types fine in terminals but never fires GTK's entry-activate. `wlrctl keyboard type $'\n'` does (wlrctl uses a standard keymap for its virtual keyboard).

Chain one widget interaction — focusing chord, select-all, text — into one wtype process anyway: fewer round-trips, no chance of focus changing mid-interaction:

```bash
# navigate a GTK file manager: ctrl+l (focus location bar) + select-all + path, ONE process…
WAYLAND_DISPLAY=$NESTED_DISPLAY wtype -M ctrl -k l -m ctrl -M ctrl -k a -m ctrl -d 15 "/etc/fonts"
WAYLAND_DISPLAY=$NESTED_DISPLAY wlrctl keyboard type $'\n'   # …then Enter via wlrctl
```

**Pre-filled fields:** clicking into a text box (path bar, search box) places the caret but keeps the old content — typing there produces a mangled mix. Clear it in-process: `ctrl+a` select-all in GUI fields, `ctrl+e` + `ctrl+u` in terminals/readline (where ctrl+a means beginning-of-line). Prefer focusing such fields by their keyboard shortcut (`ctrl+l` for location/URL bars) over clicking them.

`gui type` handles all of the above: `--terminal` picks the paste path, `--replace` the right clear idiom, `--via ctrl+l` chains the focus shortcut in-process, `--enter` uses the injector that actually works for the mode. `gui key` routes bare `Return`/`Enter` through wlrctl automatically.

## 7. Seeing the screen (offloaded vision)

> `gui` implements everything below (including the 0-1000 rescale). This section is for one-off questions, debugging the helper, or swapping the model.

Loading a screenshot into _this_ context is expensive and grows it fast across a loop. Offload it: a one-shot `ai` CLI call consumes the image and returns **only text**, which is all that enters this context. The model behind it is swappable without changing the loop.

**IMPORTANT: Default to the `ai` CLI, not your own vision.** Even if you (the driving model) are vision-capable, do NOT `Read` the screenshot yourself as the default path — that's the same context-bloat problem the offload exists to avoid, and it defeats the point of a swappable, cheap vision step. ONLY read the image yourself when you genuinely need to see it firsthand: verifying a subtle rendering/layout bug, judging visual quality, or a case where the `ai` CLI's answer was ambiguous/wrong and you need to double-check. That should be the EXCEPTION per task, not a per-step habit.

Always pass `-m` explicitly — default to `google/gemini-3.1-flash-lite-preview`, and use a different model only if the user asks for one. (Benchmarked on coordinate-localization + text-extraction tasks; top 3 by accuracy were gemini-3.1-flash-lite-preview, xiaomi/mimo-v2.5, and minimax/minimax-m3 — gemini-3.1-flash-lite-preview won on cost predictability.)

```bash
WAYLAND_DISPLAY=$NESTED_DISPLAY grim /tmp/screen.png

# describe / answer
ai text -m google/gemini-3.1-flash-lite-preview -t 1.0 --image /tmp/screen.png \
  "What is on screen? Is a password field visible and focused?"

# locate an element -> normalized coords for wlrctl (rescale below)
ai text -m google/gemini-3.1-flash-lite-preview -t 1.0 --image /tmp/screen.png \
  -s 'Return ONLY JSON {"x":int,"y":int}, the element center on a 0-1000 normalized grid (each axis scaled independently), or {"x":null} if absent.' \
  "the blue Next button"
```

Capture stdout (`R=$(ai text ...)`) and act on it. To read one window on a cluttered screen, screenshot just its buffer with `screenshot-window` (§4). For accurate *click* pixels, isolate the target window on an empty workspace first (`gui isolate`, §3) — clicks need full-screen coordinates.

**Coordinates are normalized, not raw pixels — always rescale.** Despite being asked for "image pixels," these vision models internally normalize both axes to a 0–1000 grid *independently of the image's actual aspect ratio* (confirmed even when the image was already exactly 1000px wide — x came back correct but y was still on a separate 0–1000 scale). Never trust the raw numbers directly:

```
real_x = model_x / 1000 * image_width
real_y = model_y / 1000 * image_height
```

Sanity-check this conversion once per session against a known element before trusting it in a loop.

**Verification questions must not be answerable from labels.** Asked "what directory is shown?", the vision model read `/etc/fonts` in Thunar's path bar and confidently listed `conf.d, fonts.conf, fonts.dtd` — plausible contents it *inferred*, while the pane actually still showed the home directory (and fonts.dtd wasn't even there). When verifying that an action took effect, ask about state the model can't derive from visible text (concrete unexpected entries, counts), or better, cross-check free IPC ground truth: window titles from `niri msg --json windows` update on navigation.

## The loop

Plan in this context; execute through `gui`. Scriptable flows → one `gui run` per subtask; exploratory or high-stakes steps → `gui click`/`type`/`key`, reading each one-line result before the next. Every `gui` action re-screenshots before locating, so stale-coordinate bugs can't happen; the settle delay (0.3–1 s, nested sessions repaint lazily) is built in via `GUI_SETTLE`. Only drop to the raw grim/ai/wlrctl primitives (§5–7) when the helper can't express the interaction. Never `Read` screenshots into this context unless a `gui ask`/verify answer is ambiguous and you must see for yourself.
