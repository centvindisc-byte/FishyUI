# FishyUI

A glass-styled Roblox UI library for Fishy Hub, built as a drop-in replacement for
[deividcomsono/Obsidian](https://github.com/deividcomsono/Obsidian).

Same file layout, same API. Existing Obsidian scripts switch over by changing one URL:

```lua
local repo = "https://raw.githubusercontent.com/centvindisc-byte/FishyUI/main/"

local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
```

## Layout

| Path | What |
|------|------|
| `Library.lua` | The library (single file, loadstring target) |
| `addons/ThemeManager.lua` | Theme presets and theme settings tab |
| `addons/SaveManager.lua` | Config save / load / autoload |
| `examples/` | Example scripts |

## Status

Work in progress.
