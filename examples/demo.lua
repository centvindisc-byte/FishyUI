-------------------------------------------------------------------------------------------------------
-- FishyUI — generic example
--
-- Nothing here is tied to a game. Every control is a placeholder that reports what it did, so the file
-- doubles as a reference for the whole API: each element type, every option that changes how it behaves,
-- and the library-level settings underneath.
--
-- Run it straight off the repo:
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/centvindisc-byte/FishyUI/main/examples/demo.lua"))()
--
-- Things worth trying that no line of this file can show you:
--   · press and pull a sidebar tab to carry it anywhere, then let go to snap it back
--   · right-click any toggle or slider to pop it out as its own floating attachment
--   · shove the window into the left or right edge of the screen to collapse it into the icon rail
--   · the five buttons top-right: cursor, attachments, gradient palette, themes, minimise
-------------------------------------------------------------------------------------------------------

-- Works both ways: bundled after the library (the test build concatenates the two, so `Library` is
-- already in scope) and run on its own, where it has to fetch the library itself. HttpGet is the
-- executor's; GetAsync is the fallback so the file also runs in Studio.
local Library = Library or (function()
    local url = "https://raw.githubusercontent.com/centvindisc-byte/FishyUI/main/Library.lua"
    -- HttpGet is injected by the executor and simply isn't a member of DataModel otherwise, and
    -- indexing an Instance for a member it doesn't have raises rather than returning nil — so the
    -- probe has to be wrapped. GetAsync is the fallback, which is what runs in Studio.
    local hasHttpGet, httpGet = pcall(function() return game.HttpGet end)
    local source
    if hasHttpGet and typeof(httpGet) == "function" then
        source = game:HttpGet(url)
    else
        source = game:GetService("HttpService"):GetAsync(url)
    end
    return loadstring(source)()
end)()

local Options, Toggles = Library.Options, Library.Toggles

local function report(what)
    return function(value)
        if typeof(value) == "table" then
            local parts = {}
            for key, flag in pairs(value) do
                table.insert(parts, flag == true and tostring(key) or string.format("%s=%s", key, tostring(flag)))
            end
            value = #parts > 0 and table.concat(parts, ", ") or "none"
        end
        Library:Notify({ Title = what, Description = "Value: " .. tostring(value), Time = 3 })
    end
end

local Window = Library:CreateWindow({
    Title = "FishyUI",
    Footer = "generic example",
    ToggleKeybind = Enum.KeyCode.RightShift,
    Center = true,
    AutoShow = true,
})

-------------------------------------------------------------------------------------------------------
-- ELEMENTS — one of everything that stacks inside a groupbox
-------------------------------------------------------------------------------------------------------
local Elements = Window:AddTab("Elements", nil, "Every control type, with the options that change them")

local TogglesBox = Elements:AddLeftGroupbox("Toggles")
TogglesBox:AddToggle("BasicToggle", {
    Text = "Basic toggle",
    Default = true,
    Tooltip = "Hover text appears after a short delay",
    Callback = report("Basic toggle"),
})
TogglesBox:AddToggle("RiskyToggle", {
    Text = "Risky toggle",
    Risky = true,
    Tooltip = "Risky draws the label in the danger colour",
})
TogglesBox:AddToggle("DisabledToggle", {
    Text = "Disabled toggle",
    Disabled = true,
    DisabledTooltip = "Disabled elements explain themselves on hover",
})
TogglesBox:AddCheckbox("BasicCheckbox", { Text = "Checkbox variant", Default = true })
TogglesBox:AddCheckbox("SecondCheckbox", { Text = "Another checkbox" })

local SlidersBox = Elements:AddLeftGroupbox("Sliders")
SlidersBox:AddSlider("WholeNumbers", {
    Text = "Whole numbers",
    Default = 50, Min = 0, Max = 100,
    Suffix = "%",
    Callback = report("Whole numbers"),
})
SlidersBox:AddSlider("Decimals", {
    Text = "Two decimals",
    Default = 1.25, Min = 0, Max = 5, Rounding = 2,
    Suffix = "x",
})
SlidersBox:AddSlider("Prefixed", {
    Text = "Prefixed",
    Default = 250, Min = 0, Max = 1000,
    Prefix = "$",
})
SlidersBox:AddSlider("Stepped", {
    Text = "Few steps (tick marks)",
    Default = 3, Min = 1, Max = 6,
    Tooltip = "Sliders with a small range draw ticks",
})
SlidersBox:AddSlider("Compact", {
    Text = "Compact",
    Default = 4, Min = 1, Max = 10,
    Compact = true,
})

local ButtonsBox = Elements:AddRightGroupbox("Buttons")
ButtonsBox:AddButton({
    Text = "Primary",
    Func = function() Library:Notify({ Title = "Button", Description = "Primary pressed.", Time = 3 }) end,
}):AddButton({
    Text = "Secondary",
    Func = function() Library:Notify("Secondary pressed", 3) end,
})
ButtonsBox:AddButton({
    Text = "Destructive (confirm)",
    DoubleClick = true,
    Risky = true,
    Tooltip = "Asks for a second press while a fuse burns down",
    Func = function() Library:Notify({ Title = "Confirmed", Description = "Destructive action ran.", Time = 3 }) end,
})
ButtonsBox:AddButton({ Text = "Disabled", Disabled = true, DisabledTooltip = "Turned off for now" })

local TextBox = Elements:AddRightGroupbox("Labels")
TextBox:AddLabel("A plain single-line label")
TextBox:AddLabel("Rich text works too: <font color=\"#8be9a0\">success</font>, <font color=\"#ff7084\">danger</font>.")
TextBox:AddDivider()
TextBox:AddLabel("A wrapping label carries a longer explanation across as many lines as it needs, which is the right place for a sentence or two about what a section actually does.", true)

local Tabbox = Elements:AddRightTabbox()
local TabOne = Tabbox:AddTab("First")
TabOne:AddToggle("TabboxToggleA", { Text = "Inside tab one" })
TabOne:AddSlider("TabboxSliderA", { Text = "Amount", Default = 2, Min = 0, Max = 10, Compact = true })
local TabTwo = Tabbox:AddTab("Second")
TabTwo:AddToggle("TabboxToggleB", { Text = "Inside tab two" })
local TabThree = Tabbox:AddTab("Third")
TabThree:AddLabel("Tabboxes share one card between several panels.", true)

-------------------------------------------------------------------------------------------------------
-- INPUTS — dropdowns, text fields, keybinds, colours and dependencies
-------------------------------------------------------------------------------------------------------
local Inputs = Window:AddTab("Inputs", nil, "Pickers, fields and conditional sections")

local DropdownBox = Inputs:AddLeftGroupbox("Dropdowns")
DropdownBox:AddDropdown("SingleChoice", {
    Text = "Single choice",
    Values = { "Alpha", "Bravo", "Charlie" },
    Default = 1,
    Callback = report("Single choice"),
})
DropdownBox:AddDropdown("NullableChoice", {
    Text = "Clearable",
    Values = { "One", "Two", "Three" },
    AllowNull = true,
    Tooltip = "Picking the active item again clears it",
})
DropdownBox:AddDropdown("MultiChoice", {
    Text = "Multi select",
    Values = { "Red", "Green", "Blue", "Violet" },
    Multi = true,
    Default = { "Red", "Blue" },
    Callback = report("Multi select"),
})
DropdownBox:AddDropdown("SearchableChoice", {
    Text = "Searchable (long list)",
    Values = { "Ash", "Birch", "Cedar", "Elm", "Fir", "Hazel", "Larch", "Maple", "Oak", "Pine", "Rowan", "Willow" },
    Default = "Maple",
})
DropdownBox:AddDropdown("PlayerChoice", {
    Text = "Players in server",
    SpecialType = "Player",
    Tooltip = "Rebuilds itself as players join and leave",
})

local FieldBox = Inputs:AddLeftGroupbox("Text fields")
FieldBox:AddInput("PlainText", {
    Text = "Plain text",
    Placeholder = "Type anything",
    Callback = report("Plain text"),
})
FieldBox:AddInput("LimitedText", {
    Text = "With a length limit",
    Placeholder = "Up to 16 characters",
    MaxLength = 16,
})
FieldBox:AddInput("NumbersOnly", {
    Text = "Numbers only",
    Numeric = true,
    Placeholder = "0",
    Tooltip = "Letters are rejected and the field shakes them off",
})
FieldBox:AddInput("OnEnter", {
    Text = "Commit on Enter",
    Finished = true,
    Placeholder = "Press Enter to apply",
    Callback = report("Commit on Enter"),
})

local BindBox = Inputs:AddRightGroupbox("Keybinds and colours")
BindBox:AddLabel("Standalone keybind"):AddKeyPicker("StandaloneKey", {
    Default = "K",
    Mode = "Toggle",
    Text = "Standalone",
    Tooltip = "Right-click the cap to change Toggle / Hold / Always",
})
BindBox:AddToggle("BoundToggle", { Text = "Toggle driven by a key" })
    :AddKeyPicker("BoundKey", { Default = "J", Mode = "Toggle", Text = "Bound toggle", SyncToggleState = true })
BindBox:AddLabel("Solid colour"):AddColorPicker("SolidColor", {
    Default = Color3.fromRGB(157, 91, 255),
    Title = "Solid colour",
    Callback = report("Solid colour"),
})
BindBox:AddLabel("Colour with alpha"):AddColorPicker("AlphaColor", {
    Default = Color3.fromRGB(98, 242, 194),
    Transparency = 0.35,
    Title = "Colour with alpha",
})

local DependBox = Inputs:AddRightGroupbox("Dependencies")
DependBox:AddToggle("MasterSwitch", { Text = "Reveal the section below" })
local Dependent = DependBox:AddDependencyBox()
Dependent:AddSlider("DependentSlider", { Text = "Only visible when on", Default = 30, Min = 0, Max = 100 })
Dependent:AddDropdown("DependentDropdown", { Text = "Also hidden", Values = { "Left", "Right" }, Default = 1 })
Dependent:SetupDependencies({ { Toggles.MasterSwitch, true } })

-------------------------------------------------------------------------------------------------------
-- INTERFACE — the library's own settings
-------------------------------------------------------------------------------------------------------
local Interface = Window:AddTab("Interface", nil, "Theme, typography, feedback and window behaviour")

local AppearanceBox = Interface:AddLeftGroupbox("Appearance")
AppearanceBox:AddDropdown("ThemePick", {
    Text = "Theme",
    Values = Library.ThemeOrder,
    Default = Library.Theme,
    Callback = function(value) Library:SetTheme(value) end,
})
AppearanceBox:AddPalette("AccentGradient", { Text = "Accent gradient" })
AppearanceBox:AddLabel("Some themes change the material, not just the colour: Frost is light, Onyx is matte, Neon glows, Midnight is flat OLED black.", true)

local TypographyBox = Interface:AddLeftGroupbox("Language and type")
TypographyBox:AddDropdown("FontPick", {
    Text = "Font",
    Values = { "Gotham", "Roboto", "Nunito", "Ubuntu", "Josefin", "Oswald", "Merriweather", "Mono" },
    Default = Library.FontFamily,
    Callback = function(value) Library:SetFontFamily(value) end,
})
TypographyBox:AddDropdown("LanguagePick", {
    Text = "Language",
    Values = { "en", "es", "pt", "fr", "de", "ru", "tr", "ja", "ko", "zh" },
    Default = Library.Language,
    Callback = function(value) Library:SetLanguage(value) end,
})

local FeelBox = Interface:AddRightGroupbox("Feel")
FeelBox:AddToggle("SoundEnabled", {
    Text = "Interface sounds",
    Default = true,
    Tooltip = "Glass ticks on toggles, a grain per slider step, a low sweep on tab changes",
    Callback = function(value) Library:SetSoundEnabled(value) end,
})
FeelBox:AddSlider("SoundVolume", {
    Text = "Master volume",
    Default = 60, Min = 0, Max = 100, Suffix = "%",
    Callback = function(value) Library:SetSoundVolume(value / 100) end,
})
FeelBox:AddDropdown("CursorStyle", {
    Text = "Cursor",
    Values = Library.CursorStyles,
    Default = Library.Cursor,
    Callback = function(value) Library:SetCursor(value) end,
})
FeelBox:AddToggle("LowGraphics", {
    Text = "Low graphics",
    Default = Library.LowGraphics,
    Tooltip = "For slower devices: drops the blur, backdrop particles and glass highlights",
    Callback = function(value) Library:SetLowGraphics(value) end,
})

local WindowBox = Interface:AddRightGroupbox("Window")
WindowBox:AddDropdown("DPI", {
    Text = "Interface scale",
    Values = { "75%", "100%", "125%", "150%" },
    Default = "100%",
    Callback = function(value) Library:SetDPIScale(tonumber((value:gsub("%%", "")))) end,
})
WindowBox:AddDropdown("NotifySide", {
    Text = "Notifications",
    Values = { "Left", "Right" },
    Default = "Right",
    Callback = function(value) Library:SetNotifySide(value) end,
})
WindowBox:AddLabel("Menu keybind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu" })
Library.ToggleKeybind = Options.MenuKeybind
WindowBox:AddToggle("ShowKeybinds", {
    Text = "Show keybind list",
    Callback = function(value) Library.KeybindFrame.Visible = value end,
})
WindowBox:AddButton({ Text = "Notify", Func = function()
    Library:Notify({ Title = "Notification", Description = "Toasts stack and burn down a fuse.", Time = 4 })
end })

local ResetBox = Interface:AddRightGroupbox("Reset")
ResetBox:AddButton({
    Text = "Factory reset",
    Risky = true,
    DoubleClick = true,
    Tooltip = "Clears language, font, theme and gradient, then reopens first-run setup",
    Func = function() Library:FactoryReset() end,
})
ResetBox:AddButton({
    Text = "Unload",
    Risky = true,
    DoubleClick = true,
    Func = function() Library:Unload() end,
})

-------------------------------------------------------------------------------------------------------
-- ABOUT — the parts that aren't controls
-------------------------------------------------------------------------------------------------------
local About = Window:AddTab("About", nil, "What this library does that others don't")
About:UpdateWarningBox({
    Visible = true,
    Title = "Generic example",
    Text = "Nothing on these tabs touches the game. Replace them with your own sections.",
})

local FeatureBox = About:AddLeftGroupbox("Try these")
FeatureBox:AddLabel("Magnetic tabs — press a sidebar tab and pull. It lifts out, the others part to leave a gap, and it flies back when you let go.", true)
FeatureBox:AddDivider()
FeatureBox:AddLabel("Pin a control — right-click any toggle, slider, dropdown or label to pop it out as its own floating attachment, or a button to put it on the Quick actions pad. Build a HUD from the handful you actually use.", true)
FeatureBox:AddDivider()
FeatureBox:AddLabel("Edge rail — drag the window hard into the left or right edge of the screen and it collapses to a slim strip of icons. Double-tap the rail to bring it back.", true)

local PodBox = About:AddRightGroupbox("Attachments")
PodBox:AddLabel("The attachments button top-right opens a dock of live pods: session, performance, server, location, radar, speed, nearby players, day cycle, activity, network, friends, quick actions, a timer and your keybinds. Click a tile to dock it, or drag it out to place it.", true)
PodBox:AddDivider()
PodBox:AddLabel("Click a pod to switch between card, expanded and pill. Pull a docked pod away and its bridge tears; fling it and it lands in a corner; drop it on another pod to stack them (scroll to flip through). Minimise the window and docked pods orbit the bubble.", true)
PodBox:AddDivider()
-- A pod made by the script. It sits in the dock with the built-in ones until you deploy it.
local demoPod = Window:AddAttachment({
    Title = "Demo graph",
    Kind = "Graph",
    Unit = "per sec",
    Update = function() return math.random(20, 60) end,
})
PodBox:AddButton({ Text = "Deploy the demo graph", Func = function() demoPod:Deploy() end })
PodBox:AddButton({ Text = "Save layout", Func = function()
    local name = Window:SaveAttachmentLayout("Demo")
    if name then Library:Notify({ Title = "Layout saved", Description = "Load it again from the dock.", Time = 3 }) end
end }):AddButton({ Text = "Load layout", Func = function()
    if not Window:LoadAttachmentLayout("Demo") then
        Library:Notify({ Title = "No layout yet", Description = "Save one first.", Time = 3 })
    end
end })

local ApiBox = About:AddRightGroupbox("Reading values")
ApiBox:AddLabel("Every element registers itself, so a script reads state without keeping its own copy.", true)
ApiBox:AddButton({ Text = "Print current values", Func = function()
    Library:Notify({
        Title = "Current values",
        Description = string.format("Basic toggle: %s\nWhole numbers: %s\nSingle choice: %s",
            tostring(Toggles.BasicToggle.Value),
            tostring(Options.WholeNumbers.Value),
            tostring(Options.SingleChoice.Value)),
        Time = 6,
    })
end })

-------------------------------------------------------------------------------------------------------
-- Library-level hooks
-------------------------------------------------------------------------------------------------------
Window.OnTabOrderChanged = function(order)
    print("[FishyUI] tab order:", table.concat(order, ", "))
end

Library:OnUnload(function()
    print("[FishyUI] unloaded")
end)

Library:Notify({ Title = "FishyUI", Description = "Generic example loaded. RightShift toggles the menu.", Time = 5 })
