# FishyUI

A liquid-glass Roblox UI library by Fishy Studios, built as a drop-in replacement for
[deividcomsono/Obsidian](https://github.com/deividcomsono/Obsidian).

Same file layout, same API. An existing Obsidian script switches over by changing one URL.

```lua
local repo = "https://raw.githubusercontent.com/centvindisc-byte/FishyUI/main/"

local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
```

## Quick start

```lua
local Window = Library:CreateWindow({
    Title = "My Hub",
    Footer = "v1.0",
    ToggleKeybind = Enum.KeyCode.RightShift,
})

local Main = Window:AddTab("Main", nil, "Core features")
local Box = Main:AddLeftGroupbox("Automation")

Box:AddToggle("AutoFarm", {
    Text = "Auto Farm",
    Default = false,
    Callback = function(value) print("auto farm:", value) end,
})
Box:AddSlider("Radius", { Text = "Radius", Default = 45, Min = 10, Max = 120, Suffix = " studs" })

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
ThemeManager:SetFolder("MyHub")
SaveManager:SetFolder("MyHub")

local Settings = Window:AddTab("Settings")
ThemeManager:ApplyToTab(Settings)
SaveManager:BuildConfigSection(Settings)
SaveManager:LoadAutoloadConfig()
```

A complete, game-agnostic showcase of every element and setting lives in
[`examples/demo.lua`](examples/demo.lua).

## What makes it different

Beyond API parity, FishyUI adds a set of things most Roblox UI libraries don't have:

- **Liquid glass throughout** — a nine-sliced lensed edge, specular highlights and spring-driven motion.
  Every animation runs on one shared `Heartbeat` driver that sleeps when nothing is moving.
- **Ten themes that change material, not just colour** — Frost is light, Onyx is matte stone, Neon glows,
  Midnight is flat OLED black, Glacier is clearer glass.
- **Magnetic tabs** — press and pull a sidebar tab to carry it anywhere; the others part to leave a gap
  and it flies back on release.
- **Attachments** — floating info pods (session clock, performance graph, server capacity, coordinates,
  radar) that dock to any of the window's four sides and trail it on a spring.
- **Pin any control** — right-click a toggle or slider to pop it out as its own attachment, building a
  HUD from the handful of controls you actually use.
- **Edge rail** — shove the window into a screen edge and it collapses into a slim strip of tab icons.
- **Gradient palette** — a glass gradient editor with a live preview of the controls it recolours,
  draggable stop knobs (click the track to add one), shade, hue, hex and exact-position fields, add /
  remove / flip / even-spacing actions and eight presets. Every accent fill updates live as you edit.
- **Sound design** — soft glass ticks on toggles, a grain per slider step, a low sweep on tab changes,
  with a master volume.
- **Six custom cursors**, a per-theme ambient backdrop, and a first-run language → theme → font flow.

## API

### Window

```lua
Library:CreateWindow({
    Title = "",            -- sidebar heading
    Footer = "",           -- centred footer text
    Brand = "Fishy Studios", -- subtitle under the title; "" hides it
    Center = true,
    AutoShow = true,
    Size = UDim2.fromOffset(760, 600),
    CornerRadius = 14,
    NotifySide = "Right",
    ToggleKeybind = Enum.KeyCode.RightControl,
    Blur = true,           -- blur the game behind the window
    Bubble = true,         -- minimise into a draggable status pill
    Satellites = true,     -- enable the attachment pods
    LowGraphics = nil,     -- true/false forces low graphics mode; nil keeps the player's saved choice
})
```

`Window:AddTab(name, icon, description)`, `Window:SetTitle`, `Window:SetFooter`,
`Window:SetCornerRadius`, `Window:SetAlwaysOnTop`, `Window:GetTabOrder`, `Window:SetTabOrder`,
`Window.OnTabOrderChanged`.

### Tabs and containers

`Tab:AddLeftGroupbox(name, icon)`, `Tab:AddRightGroupbox(name, icon)`,
`Tab:AddLeftTabbox(name)`, `Tab:AddRightTabbox(name)`, `Tab:UpdateWarningBox({ Visible, Title, Text })`,
`Tab:SelectSection(name)`.

### Elements

| Call | Notable options |
|------|-----------------|
| `AddToggle(idx, info)` | `Text`, `Default`, `Risky`, `Disabled`, `Tooltip`, `Callback` |
| `AddCheckbox(idx, info)` | same as toggle, drawn as a checkbox |
| `AddSlider(idx, info)` | `Min`, `Max`, `Default`, `Rounding`, `Prefix`, `Suffix`, `Compact` |
| `AddDropdown(idx, info)` | `Values`, `Default`, `Multi`, `AllowNull`, `Searchable`, `SpecialType` |
| `AddInput(idx, info)` | `Placeholder`, `Numeric`, `Finished`, `MaxLength`, `ClearTextOnFocus` |
| `AddButton(info)` | `Text`, `Func`, `DoubleClick`, `Risky`, `Disabled`; chain `:AddButton` for a row |
| `AddLabel(text, wrap)` | `wrap = true` for a multi-line paragraph |
| `AddDivider()` | hairline with a glass diamond |
| `AddPalette(idx, info)` | the accent gradient editor |
| `AddDependencyBox()` | `:SetupDependencies({ { Toggles.X, true } })` |

Labels and toggles accept accessories: `:AddKeyPicker(idx, info)` and `:AddColorPicker(idx, info)`.

Every element registers into `Library.Options` / `Library.Toggles` and exposes `SetValue`, `OnChanged`,
`SetText`, `SetVisible` and `SetDisabled`.

### Library

`Library:Notify({ Title, Description, Time })`, `Library:Toggle(bool)`, `Library:Unload()`,
`Library:OnUnload(fn)`, `Library:SetTheme(name)`, `Library:SetAccentGradient(sequence)`,
`Library:ApplyScheme(table)`, `Library:GetScheme()`, `Library:SetDPIScale(percent)`,
`Library:SetNotifySide(side)`, `Library:SetLanguage(code)`, `Library:SetFontFamily(name)`,
`Library:SetSoundEnabled(bool)`, `Library:SetSoundVolume(0-1)`, `Library:SetCursor(style)`,
`Library:SetLowGraphics(bool)`, `Library:FactoryReset()`.

### Performance

Animations draw once per frame however many physics substeps they take, idle UI costs nothing, and
repaints skip properties whose value hasn't changed. For weak devices, `Library:SetLowGraphics(true)`
turns off what is purely decorative and costly to draw: the full-screen blur, the animated backdrop, the
lensed rims, halos and specular lines on glass surfaces, the bubble's signal pulse and the theme morph
(themes switch instantly). It is off by default and saved like the sound and cursor settings.

## Addons

**ThemeManager** — `SetLibrary`, `SetFolder`, `ApplyToTab`, `ApplyToGroupbox`, `ApplyTheme`,
`SaveCustomTheme`, `GetCustomTheme`, `Delete`, `LoadDefault`, `SaveDefault`.

**SaveManager** — `SetLibrary`, `SetFolder`, `SetSubFolder`, `SetIgnoreIndexes`, `IgnoreThemeSettings`,
`BuildConfigSection`, `Save`, `Load`, `Delete`, `RefreshConfigList`, `SetAutoloadConfig`,
`LoadAutoloadConfig`.

Both degrade gracefully: without executor file functions they simply no-op, so the UI still runs in Studio.

## Layout

| Path | What |
|------|------|
| `Library.lua` | The library as one file — the loadstring target. Generated; do not edit by hand. |
| `addons/ThemeManager.lua` | Themes, custom theme save/load |
| `addons/SaveManager.lua` | Config save / load / autoload |
| `examples/demo.lua` | Generic showcase of every element and setting |
| `src/` | The library's actual source, split by concern |
| `tools/build.sh` | Concatenates `src/*.lua` into `Library.lua` |

## Building

`Library.lua` is generated. Edit the files in `src/`, then:

```bash
./tools/build.sh
```

The files in `src/` are concatenated in filename order and share one scope, so anything referenced must
be defined in an earlier file. The build gates on that: it runs `luau-analyze` and fails on a syntax
error or on an unknown global that isn't a known Roblox, Luau or executor name — which is what catches a
call to something defined further down the list.

The build also writes `build/FishyUI_test.lua`, the library plus the demo in one pasteable file.

## Licence

MIT.
