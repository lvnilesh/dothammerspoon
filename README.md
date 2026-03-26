# Hammerspoon Window Manager (Ultra-Wide Edition)

Window management configuration optimized for the **Dell U5226KW** (6144x2560, 2.4:1 ultra-wide) on an M1 Mac Mini. Also works on standard 16:9 displays.

## Setup

1. Install [Hammerspoon](https://www.hammerspoon.org/)
2. Clone/copy this repo to `~/.hammerspoon/`
3. Reload config: click the Hammerspoon menu bar icon -> Reload Config, or press `Hyper+R`

**Requires Karabiner-Elements** for:
- CapsLock -> Hyper (`Shift+Ctrl+Alt+Cmd`), tap alone for Escape
- Vim navigation: Hyper+H/J/K/L -> arrow keys
- App launchers: O+key combos (N=Notion, B=Brave, C=VSCode, I=iTerm, etc.)

Hammerspoon uses one modifier combo:

| Name | Keys | Used for |
|---|---|---|
| **Hyper** | `Shift+Ctrl+Alt+Cmd` (CapsLock) | Window management, system, music, cheatsheet |

## How It Works

The screen is divided using a 24x24 grid. On a 2.4:1 ultra-wide, 1/3 width (~1024pt) is the sweet spot -- roughly equivalent to a standard 16:9 monitor.

```
|------------ full screen (3072 pt) ------------|
|    1/3    |    1/3    |    1/3    |              <- column zones (1/2/3 keys)
|      2/3      |    1/3    |                     <- wide + narrow (4 + 3 keys)
|    1/3    |      2/3      |                     <- narrow + wide (1 + 5 keys)
```

Most zone keys **cycle through sizes** when pressed repeatedly (e.g. `Hyper+1` cycles the left column through 1/3 -> 1/4 -> 1/6 width).

The 2x3 grid keys are laid out spatially:

```
U  I  O      (top row)
7  8  9      (bottom row)
```

(Bottom row uses number keys because Hyper+J/K/L are consumed by Karabiner for vim navigation.)

## Keybinding Reference

All keybindings are listed in [cheatsheets/default.md](cheatsheets/default.md), which also powers the in-app cheatsheet overlay (`Hyper+S`).

## Suggested Workflows

**3-column development** -- editor, terminal, docs side by side:
```
Hyper+1        Hyper+2        Hyper+3
```

**Focused coding** with reference material:
```
Hyper+4 (left 2/3)    Hyper+3 (right 1/3)
```

**Research** -- browser + notes:
```
Hyper+1 (left 1/3)    Hyper+5 (right 2/3)
```

**6-window dashboard:**
```
Hyper+U  Hyper+I  Hyper+O
Hyper+7  Hyper+8  Hyper+9
```

**Centered focus** -- grow/shrink a single window in the center:
```
Hyper+6 (press repeatedly: 1/3 -> 1/2 -> 2/3)
```

## Icon Credits

- Tomato Timer by Nick Bluth from the Noun Project
- mug by Rohith M S from the Noun Project
- Climacons by Adam Whitcroft
