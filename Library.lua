-- FishyUI | generated from src/ by tools/build.sh. Edit the files in src/, not this one.

-- ===== 01_header.lua =====
--[[
    FishyUI — liquid glass UI library by Fishy Studios
    Drop-in API replacement for deividcomsono/Obsidian

    Target : Roblox client, Luau, any executor. Also previews in Studio edit mode.
    Load   : loadstring(game:HttpGet("https://raw.githubusercontent.com/centvindisc-byte/FishyUI/main/Library.lua"))()
]]

local cloneref = (typeof(cloneref) == "function" and cloneref) or function(obj) return obj end
local function service(name) return cloneref(game:GetService(name)) end

local CoreGui = service("CoreGui")
local GuiService = service("GuiService")
local HttpService = service("HttpService")
local Lighting = service("Lighting")
local LocalizationService = service("LocalizationService")
local Players = service("Players")
local RunService = service("RunService")
local StarterGui = service("StarterGui")
local Stats = service("Stats")
local TextService = service("TextService")
local TweenService = service("TweenService")
local UserInputService = service("UserInputService")
local Workspace = service("Workspace")

-- Studio edit mode has no executor and no LocalPlayer; the window mounts under StarterGui so it renders in the viewport.
local IS_STUDIO_PREVIEW = RunService:IsStudio() and not RunService:IsRunning()
local ENV = (typeof(getgenv) == "function" and getgenv()) or _G

local FONT_BOLD = Font.fromEnum(Enum.Font.GothamBold)
local FONT_MEDIUM = Font.new(FONT_BOLD.Family, Enum.FontWeight.Medium)
local FONT_MONO = Font.fromEnum(Enum.Font.RobotoMono)

-- The live font roles. Every label built through Text() binds to its role, so picking a font in setup
-- re-applies across the whole interface, including UI that already exists.
local Fonts = { Bold = FONT_BOLD, Medium = FONT_MEDIUM, Mono = FONT_MONO }

-- ===== 02_themes.lua =====
-------------------------------------------------------------------------------------------------------
-- Themes
--
-- Every theme defines the same tokens. Colours tint the glass; the numeric tokens change the material
-- itself (how clear the pane is, how much light the edge catches, whether there is a sheen at all),
-- so a theme can be frosted, matte, glowing or flat rather than only a different hue.
-------------------------------------------------------------------------------------------------------
local Themes = {
    -- Violet glass, the house look.
    Amethyst = {
        PaneTop = Color3.fromRGB(38, 22, 66), PaneMid = Color3.fromRGB(15, 9, 27), PaneBottom = Color3.fromRGB(7, 3, 15),
        Rim = Color3.fromRGB(226, 210, 255), EdgeMid = Color3.fromRGB(232, 224, 255), EdgeLow = Color3.fromRGB(192, 166, 248),
        LensTint = Color3.fromRGB(222, 206, 255), Field = Color3.fromRGB(0, 0, 0),
        Accent = Color3.fromRGB(205, 145, 255), AccentDeep = Color3.fromRGB(157, 91, 255), Knob = Color3.fromRGB(255, 255, 255),
        Glyph = Color3.fromRGB(178, 160, 205), Shadow = Color3.fromRGB(3, 1, 8),
        TextPrimary = Color3.fromRGB(248, 246, 253), TextSecondary = Color3.fromRGB(192, 183, 216), TextMuted = Color3.fromRGB(150, 139, 180),
        PaneTransparency = 0.3, EdgeTransparency = 0.66, BorderTransparency = 0.5, SheenTransparency = 0.9,
        CardTransparency = 0.94, FieldTransparency = 0.72, ShadowTransparency = 0.55,
    },

    -- Clear ice: thinner, brighter glass with a pale cyan edge that catches much more light.
    Glacier = {
        PaneTop = Color3.fromRGB(24, 50, 80), PaneMid = Color3.fromRGB(10, 21, 38), PaneBottom = Color3.fromRGB(4, 7, 18),
        Rim = Color3.fromRGB(206, 234, 255), EdgeMid = Color3.fromRGB(222, 240, 255), EdgeLow = Color3.fromRGB(148, 198, 244),
        LensTint = Color3.fromRGB(200, 230, 255), Field = Color3.fromRGB(0, 8, 20),
        Accent = Color3.fromRGB(124, 208, 255), AccentDeep = Color3.fromRGB(62, 150, 238), Knob = Color3.fromRGB(255, 255, 255),
        Glyph = Color3.fromRGB(154, 184, 210), Shadow = Color3.fromRGB(1, 4, 10),
        TextPrimary = Color3.fromRGB(244, 250, 255), TextSecondary = Color3.fromRGB(180, 204, 226), TextMuted = Color3.fromRGB(128, 154, 180),
        PaneTransparency = 0.44, EdgeTransparency = 0.46, BorderTransparency = 0.34, SheenTransparency = 0.82,
        CardTransparency = 0.93, FieldTransparency = 0.66, ShadowTransparency = 0.62,
    },

    -- Blossom at night: rose glass over deep plum.
    Sakura = {
        PaneTop = Color3.fromRGB(78, 30, 56), PaneMid = Color3.fromRGB(28, 10, 24), PaneBottom = Color3.fromRGB(11, 4, 12),
        Rim = Color3.fromRGB(255, 216, 234), EdgeMid = Color3.fromRGB(255, 228, 240), EdgeLow = Color3.fromRGB(246, 162, 204),
        LensTint = Color3.fromRGB(255, 210, 230), Field = Color3.fromRGB(10, 0, 6),
        Accent = Color3.fromRGB(255, 142, 194), AccentDeep = Color3.fromRGB(232, 82, 152), Knob = Color3.fromRGB(255, 255, 255),
        Glyph = Color3.fromRGB(214, 170, 192), Shadow = Color3.fromRGB(8, 2, 6),
        TextPrimary = Color3.fromRGB(255, 247, 251), TextSecondary = Color3.fromRGB(230, 192, 210), TextMuted = Color3.fromRGB(178, 138, 158),
        PaneTransparency = 0.3, EdgeTransparency = 0.62, BorderTransparency = 0.48, SheenTransparency = 0.9,
        CardTransparency = 0.94, FieldTransparency = 0.72, ShadowTransparency = 0.55,
    },

    -- Northern lights: teal glass deepening into violet, with a mint glow.
    Aurora = {
        PaneTop = Color3.fromRGB(16, 66, 62), PaneMid = Color3.fromRGB(9, 24, 34), PaneBottom = Color3.fromRGB(13, 6, 24),
        Rim = Color3.fromRGB(198, 255, 236), EdgeMid = Color3.fromRGB(214, 255, 242), EdgeLow = Color3.fromRGB(150, 206, 238),
        LensTint = Color3.fromRGB(190, 250, 228), Field = Color3.fromRGB(0, 8, 8),
        Accent = Color3.fromRGB(98, 242, 194), AccentDeep = Color3.fromRGB(38, 198, 150), Knob = Color3.fromRGB(255, 255, 255),
        Glyph = Color3.fromRGB(154, 206, 192), Shadow = Color3.fromRGB(1, 6, 6),
        TextPrimary = Color3.fromRGB(242, 255, 250), TextSecondary = Color3.fromRGB(176, 222, 208), TextMuted = Color3.fromRGB(124, 170, 158),
        PaneTransparency = 0.3, EdgeTransparency = 0.6, BorderTransparency = 0.45, SheenTransparency = 0.88,
        CardTransparency = 0.94, FieldTransparency = 0.72, ShadowTransparency = 0.55,
    },

    -- Matte black stone with gold inlay: nearly opaque, no sheen, the edge barely catches light.
    Onyx = {
        PaneTop = Color3.fromRGB(36, 34, 31), PaneMid = Color3.fromRGB(19, 18, 17), PaneBottom = Color3.fromRGB(10, 10, 9),
        Rim = Color3.fromRGB(150, 136, 110), EdgeMid = Color3.fromRGB(210, 196, 170), EdgeLow = Color3.fromRGB(150, 132, 104),
        LensTint = Color3.fromRGB(236, 212, 164), Field = Color3.fromRGB(0, 0, 0),
        Accent = Color3.fromRGB(234, 194, 120), AccentDeep = Color3.fromRGB(198, 150, 70), Knob = Color3.fromRGB(252, 246, 234),
        Glyph = Color3.fromRGB(172, 162, 146), Shadow = Color3.fromRGB(0, 0, 0),
        TextPrimary = Color3.fromRGB(246, 241, 232), TextSecondary = Color3.fromRGB(192, 183, 168), TextMuted = Color3.fromRGB(138, 130, 118),
        PaneTransparency = 0.04, EdgeTransparency = 0.9, BorderTransparency = 0.7, SheenTransparency = 1,
        CardTransparency = 0.95, FieldTransparency = 0.6, ShadowTransparency = 0.35,
    },

    -- Light frosted glass with dark ink: the one light theme.
    Frost = {
        PaneTop = Color3.fromRGB(252, 253, 255), PaneMid = Color3.fromRGB(234, 239, 248), PaneBottom = Color3.fromRGB(214, 222, 238),
        Rim = Color3.fromRGB(160, 174, 204), EdgeMid = Color3.fromRGB(255, 255, 255), EdgeLow = Color3.fromRGB(206, 216, 236),
        LensTint = Color3.fromRGB(46, 64, 116), Field = Color3.fromRGB(46, 64, 116),
        Accent = Color3.fromRGB(64, 112, 240), AccentDeep = Color3.fromRGB(40, 82, 214), Knob = Color3.fromRGB(255, 255, 255),
        Glyph = Color3.fromRGB(96, 106, 132), Shadow = Color3.fromRGB(30, 40, 72),
        TextPrimary = Color3.fromRGB(22, 26, 40), TextSecondary = Color3.fromRGB(70, 80, 104), TextMuted = Color3.fromRGB(122, 132, 152),
        PaneTransparency = 0.16, EdgeTransparency = 0.3, BorderTransparency = 0.42, SheenTransparency = 0.78,
        CardTransparency = 0.95, FieldTransparency = 0.93, ShadowTransparency = 0.72,
    },

    -- Synthwave: a hot magenta edge that glows, cyan light, and a coloured halo instead of a shadow.
    Neon = {
        PaneTop = Color3.fromRGB(36, 8, 54), PaneMid = Color3.fromRGB(13, 4, 25), PaneBottom = Color3.fromRGB(4, 2, 12),
        Rim = Color3.fromRGB(255, 84, 204), EdgeMid = Color3.fromRGB(255, 140, 222), EdgeLow = Color3.fromRGB(92, 222, 255),
        LensTint = Color3.fromRGB(255, 122, 222), Field = Color3.fromRGB(0, 0, 0),
        Accent = Color3.fromRGB(72, 236, 255), AccentDeep = Color3.fromRGB(255, 72, 192), Knob = Color3.fromRGB(255, 255, 255),
        Glyph = Color3.fromRGB(204, 152, 224), Shadow = Color3.fromRGB(150, 20, 150),
        TextPrimary = Color3.fromRGB(255, 244, 252), TextSecondary = Color3.fromRGB(222, 182, 232), TextMuted = Color3.fromRGB(162, 122, 178),
        PaneTransparency = 0.2, EdgeTransparency = 0.42, BorderTransparency = 0.08, SheenTransparency = 1,
        CardTransparency = 0.95, FieldTransparency = 0.58, ShadowTransparency = 0.62,
    },

    -- Smoked amber glass, warm like a banked fire.
    Ember = {
        PaneTop = Color3.fromRGB(82, 38, 16), PaneMid = Color3.fromRGB(31, 14, 8), PaneBottom = Color3.fromRGB(12, 6, 4),
        Rim = Color3.fromRGB(255, 214, 178), EdgeMid = Color3.fromRGB(255, 228, 204), EdgeLow = Color3.fromRGB(240, 160, 100),
        LensTint = Color3.fromRGB(255, 208, 162), Field = Color3.fromRGB(8, 2, 0),
        Accent = Color3.fromRGB(255, 158, 74), AccentDeep = Color3.fromRGB(232, 106, 40), Knob = Color3.fromRGB(255, 250, 244),
        Glyph = Color3.fromRGB(214, 176, 146), Shadow = Color3.fromRGB(10, 4, 2),
        TextPrimary = Color3.fromRGB(255, 248, 240), TextSecondary = Color3.fromRGB(232, 196, 168), TextMuted = Color3.fromRGB(176, 138, 110),
        PaneTransparency = 0.28, EdgeTransparency = 0.62, BorderTransparency = 0.5, SheenTransparency = 0.88,
        CardTransparency = 0.94, FieldTransparency = 0.72, ShadowTransparency = 0.55,
    },

    -- OLED black: flat and fully opaque, a crisp hairline instead of lensed glass.
    Midnight = {
        PaneTop = Color3.fromRGB(8, 8, 10), PaneMid = Color3.fromRGB(3, 3, 4), PaneBottom = Color3.fromRGB(0, 0, 0),
        Rim = Color3.fromRGB(72, 72, 84), EdgeMid = Color3.fromRGB(120, 120, 130), EdgeLow = Color3.fromRGB(80, 80, 90),
        LensTint = Color3.fromRGB(255, 255, 255), Field = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(142, 162, 255), AccentDeep = Color3.fromRGB(98, 112, 242), Knob = Color3.fromRGB(242, 242, 248),
        Glyph = Color3.fromRGB(142, 142, 152), Shadow = Color3.fromRGB(0, 0, 0),
        TextPrimary = Color3.fromRGB(238, 238, 244), TextSecondary = Color3.fromRGB(162, 162, 172), TextMuted = Color3.fromRGB(102, 102, 112),
        PaneTransparency = 0.02, EdgeTransparency = 1, BorderTransparency = 0.25, SheenTransparency = 1,
        CardTransparency = 0.965, FieldTransparency = 0.95, ShadowTransparency = 0.3,
    },

    -- Neutral smoked glass in greyscale, with a dark knob so white accents still read.
    Smoke = {
        PaneTop = Color3.fromRGB(48, 48, 54), PaneMid = Color3.fromRGB(21, 21, 24), PaneBottom = Color3.fromRGB(8, 8, 10),
        Rim = Color3.fromRGB(236, 236, 242), EdgeMid = Color3.fromRGB(240, 240, 246), EdgeLow = Color3.fromRGB(178, 178, 190),
        LensTint = Color3.fromRGB(240, 240, 248), Field = Color3.fromRGB(0, 0, 0),
        Accent = Color3.fromRGB(238, 238, 246), AccentDeep = Color3.fromRGB(170, 170, 184), Knob = Color3.fromRGB(28, 28, 32),
        Glyph = Color3.fromRGB(170, 170, 178), Shadow = Color3.fromRGB(0, 0, 0),
        TextPrimary = Color3.fromRGB(248, 248, 250), TextSecondary = Color3.fromRGB(192, 192, 198), TextMuted = Color3.fromRGB(140, 140, 148),
        PaneTransparency = 0.34, EdgeTransparency = 0.6, BorderTransparency = 0.55, SheenTransparency = 0.88,
        CardTransparency = 0.94, FieldTransparency = 0.72, ShadowTransparency = 0.55,
    },
}

local ThemeOrder = { "Amethyst", "Glacier", "Sakura", "Aurora", "Onyx", "Frost", "Neon", "Ember", "Midnight", "Smoke" }

-- Live palette: the current theme's tokens plus a few fixed status colours. SetTheme morphs it in place.
local Glass = {
    Warning = Color3.fromRGB(255, 198, 112),
    Danger = Color3.fromRGB(255, 112, 132),
    Success = Color3.fromRGB(110, 232, 160),
}
for key, value in pairs(Themes.Amethyst) do Glass[key] = value end

local THEME_FILE_FOLDER = "FishyUI"
local THEME_FILE = THEME_FILE_FOLDER .. "/theme.txt"
local THEME_MORPH_TIME = 0.45

local function saveThemeChoice(name)
    if typeof(writefile) ~= "function" then return end
    pcall(function()
        if typeof(isfolder) == "function" and typeof(makefolder) == "function" and not isfolder(THEME_FILE_FOLDER) then
            makefolder(THEME_FILE_FOLDER)
        end
        writefile(THEME_FILE, name)
    end)
end

local function loadThemeChoice()
    if typeof(readfile) ~= "function" or typeof(isfile) ~= "function" then return nil end
    local ok, name = pcall(function()
        return isfile(THEME_FILE) and readfile(THEME_FILE) or nil
    end)
    if ok and typeof(name) == "string" and Themes[name] then return name end
    return nil
end

local function paneGradientColor()
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Glass.PaneTop),
        ColorSequenceKeypoint.new(0.5, Glass.PaneMid),
        ColorSequenceKeypoint.new(1.0, Glass.PaneBottom),
    })
end

local function edgeGradientColor()
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(0.40, Glass.EdgeMid),
        ColorSequenceKeypoint.new(1.00, Glass.EdgeLow),
    })
end

local function sheenTransparency()
    local top = Glass.SheenTransparency
    return NumberSequence.new({
        NumberSequenceKeypoint.new(0, top),
        NumberSequenceKeypoint.new(0.55, top + (1 - top) * 0.65),
        NumberSequenceKeypoint.new(1, 1),
    })
end

-- ===== 03_core.lua =====
-------------------------------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------------------------------
local Assets = {
    GlassEdge = "rbxassetid://108437916503362",
    GlassGlow = "rbxassetid://99623734860368",
    Spark = "rbxassetid://86707188750389",
}

local Motion = {
    Reflow = TweenInfo.new(0.46, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    DragReflow = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Settle = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Hover = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Press = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Pop = TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    Drop = TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    Collapse = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut),
    Expand = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Reveal = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    FadeIn = TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    FadeOut = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Blur = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Scroll = TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    -- Entrances and exits: things arrive on a long, soft curve and leave quickly.
    Intro = TweenInfo.new(0.52, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    IntroSoft = TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Outro = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
    Slide = TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
}

local L = {
    ViewportFill = 0.94,
    MinWindow = Vector2.new(600, 400),
    FooterHeight = 28,
    ResizeGrip = 18,
    HeaderButton = 28,
    HeaderButtons = 5, -- minimise, themes, palette, attachments, cursor
    SliceBaseRadius = 18, -- GlassEdge / GlassGlow textures are authored for an 18px corner
    GlowRingInset = 28, -- GlassGlow's hollow centre starts this far in (at SliceScale 1)

    SidebarWidth = 208,
    SidebarInset = 12,
    BrandHeight = 56,
    TabHeight = 38,
    TabGap = 4,
    TabRadius = 10,
    IconX = 12,
    IconSize = 16,
    SubHeight = 28,
    DrawerPadTop = 2,
    DrawerPadBottom = 6,
    BeadWidth = 4,
    BeadHeight = 14,

    DragSlop = 8, -- a press that moves this far picks a tab up; less than this is a click
    LiftScale = 1.05,
    MagnetRange = 44, -- within this distance of its gap, in any direction, a carried tab is pulled in

    PageHeaderHeight = 60,
    PagePadding = 14,
    ColumnGap = 12,
    CardPadding = 12,
    CardRadius = 12,
    ElementGap = 10,

    BubbleHeight = 44,
    BubbleMargin = 12,
    BubbleEdgeMagnet = 72, -- screen px: the bubble and floating pods dock onto an edge released this close
    WindowEdgeMagnet = 72, -- the same for the window
    WindowMargin = 12,
    TapSlop = 6,
    SignalBarWidth = 3,
    SignalBarGap = 2,
    SignalBarHeights = { 5, 9, 13 },
    PingGood = 100,
    PingFair = 200,
}
L.RailX = L.IconX + L.IconSize / 2 -- the sub-tab rail runs straight down from the tab icon's centre
L.SubLabelX = L.RailX + 14
-- Width a page header must leave clear on the right so its title never runs under the header buttons.
L.HeaderReserve = 14 + L.HeaderButtons * L.HeaderButton + (L.HeaderButtons - 1) * 6 + 14
L.EdgeRailWidth = 52 -- the slim icon rail the window collapses into at a screen edge
L.RailPushDepth = 0.42 -- fraction of the window dragged off-screen that triggers rail mode

local Springs = {
    TabLens = { Height = L.TabHeight, Stiffness = 170, Damping = 0.8, MaxStretch = 22, StretchPerSpeed = 0.045, Squash = 5, PressX = 4, PressY = 2, FlareRest = 0.62, FlarePeak = 0.24 },
    Bead = { Height = L.BeadHeight, Stiffness = 210, Damping = 0.75, MaxStretch = 9, StretchPerSpeed = 0.035, Squash = 1, PressX = 0, PressY = 0 },
    Slot = { Height = L.TabHeight, Stiffness = 260, Damping = 0.78, MaxStretch = 12, StretchPerSpeed = 0.04, Squash = 3, PressX = 0, PressY = 0 },
    ListLens = { Height = 28, Stiffness = 320, Damping = 0.82, MaxStretch = 10, StretchPerSpeed = 0.03, Squash = 3, PressX = 0, PressY = 0 },
}

-------------------------------------------------------------------------------------------------------
-- Library
-------------------------------------------------------------------------------------------------------
local Library = {
    LocalPlayer = Players.LocalPlayer,
    IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,
    ScreenGui = nil,
    Window = nil,
    KeybindFrame = nil,

    Toggled = false,
    Unloaded = false,

    Options = {},
    Toggles = {},
    Labels = {},
    Buttons = {},
    DependencyBoxes = {},
    Signals = {},
    UnloadSignals = {},

    -- Lucide icon name -> image. Names that aren't mapped fall back to a small ring.
    Icons = {},

    Themes = Themes,
    ThemeOrder = ThemeOrder,
    Theme = "Amethyst",
    Language = "en",
    FontFamily = "Gotham",
    AccentGradient = nil, -- a custom ColorSequence for accent fills; nil follows the theme
    Registry = {}, -- instance -> { property = token name | function }

    ActivityLog = {}, -- newest-first { time, title }
    ActivityListeners = {},

    CornerRadius = 14,
    DPIScale = 1,
    NotifySide = "Right",
    ShowCustomCursor = true,
    ForceCheckbox = false,
    ShowToggleFrameInKeybinds = true,
    ToggleKeybind = Enum.KeyCode.RightControl,

    -- Obsidian scheme keys, kept in sync with the active theme so ThemeManager keeps working.
    Scheme = {
        BackgroundColor = Glass.PaneMid,
        MainColor = Glass.PaneTop,
        AccentColor = Glass.AccentDeep,
        OutlineColor = Glass.PaneTop,
        FontColor = Glass.TextPrimary,
        RedColor = Glass.Danger,
        DarkColor = Glass.PaneBottom,
        WhiteColor = Color3.new(1, 1, 1),
        Font = FONT_BOLD,
    },
}

-------------------------------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------------------------------
local function New(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local function Tween(inst, info, goal)
    local t = TweenService:Create(inst, info, goal)
    t:Play()
    return t
end

local function Corner(parent, radius)
    return New("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

-- Declared here, defined in 07_sound.lua. The files are concatenated in name order, so materials and
-- elements built before that point would otherwise compile their calls as a nil global.
local playSound

local function resolveToken(source)
    if typeof(source) == "function" then return source() end
    return Glass[source]
end

-- The value the registry last wrote to each bound property. Every property write crosses into the engine
-- and costs the same whether or not the value is new, and most of what a palette edit or a theme morph
-- frame would write is unchanged (fonts, the tokens two themes share), so repaints check here first.
local ThemeWritten = {}

-- Destroyed instances are only pruned when the registry is walked, and some UI is rebuilt constantly
-- (notifications, dropdown rows, popups), so without a periodic sweep the registry grows for the whole
-- session holding every destroyed instance alive. The sweep is deferred so it never runs while a popup
-- that is still being built (and so not yet parented) is half-registered.
local REGISTRY_SWEEP_EVERY = 1000
local registryAdds, sweepQueued = 0, false

local function pruneRegistry()
    local registry = Library.Registry
    for inst in pairs(registry) do
        if inst.Parent == nil then
            registry[inst] = nil -- closed popups and destroyed rows
            ThemeWritten[inst] = nil
        end
    end
end

-- Binds instance properties to the live palette. Each property maps to a token name, or to a function
-- for values that also depend on state (the active tab's label, a toggle that is on, ...).
-- The registry keeps strong references: Roblox can collect the Lua proxy of an instance that is still on
-- screen, which would silently drop it from a weak table. Destroyed instances are pruned instead.
local function Themed(inst, props)
    local bound = Library.Registry[inst]
    local written = ThemeWritten[inst]
    if not bound then
        bound = {}
        Library.Registry[inst] = bound
        registryAdds += 1
        if registryAdds >= REGISTRY_SWEEP_EVERY and not sweepQueued then
            sweepQueued = true
            task.defer(function()
                sweepQueued, registryAdds = false, 0
                if not Library.Unloaded then pruneRegistry() end
            end)
        end
    end
    if not written then
        written = {}
        ThemeWritten[inst] = written
    end
    for property, source in pairs(props) do
        local value = resolveToken(source)
        bound[property] = source
        written[property] = value
        inst[property] = value
    end
    return inst
end

-- `changedOnly` is for repaints that run often: a palette drag or each frame of a theme morph. It skips
-- properties whose bound value is what was last written, and skips the destroyed-instance check (a write
-- to a destroyed instance is harmless; the sweep and full repaints prune them). A full repaint writes
-- every bound property, exactly as it always has.
local function applyTheme(changedOnly)
    local registry = Library.Registry
    for inst, bound in pairs(registry) do
        if not changedOnly and inst.Parent == nil then
            registry[inst] = nil -- closed popups and destroyed rows
            ThemeWritten[inst] = nil
        else
            local written = ThemeWritten[inst]
            if not written then
                written = {}
                ThemeWritten[inst] = written
            end
            for property, source in pairs(bound) do
                local value = resolveToken(source)
                if not changedOnly or written[property] ~= value then
                    written[property] = value
                    inst[property] = value
                end
            end
        end
    end
end

-- A write-through cache for properties that a single renderer owns. Per-frame renderers push the same
-- value most frames (a settled fade, a docked pod's rotation); this drops the writes that would change
-- nothing. Only use it where nothing else ever sets that property, or the cache would go stale.
local function PropertyCache()
    local last = {}
    return function(inst, property, value)
        local seen = last[inst]
        if not seen then
            seen = {}
            last[inst] = seen
        elseif seen[property] == value then
            return
        end
        seen[property] = value
        inst[property] = value
    end
end

-- The gradient used by accent fills (toggles, sliders, bars). A custom gradient from the palette editor
-- overrides the theme's two-stop accent.
local function accentSequence()
    return Library.AccentGradient or ColorSequence.new(Glass.AccentDeep, Glass.Accent)
end

-- A theme token nudged toward another one. Satellites float over the game rather than over the window's
-- own glass, so their muted text needs lifting toward the primary colour to stay readable on the flatter,
-- lower-contrast themes (Midnight, Onyx, Smoke).
local function mixToken(from, to, alpha)
    return function() return Glass[from]:Lerp(Glass[to], alpha) end
end

function Library:SetAccentGradient(sequence)
    self.AccentGradient = sequence
    -- The palette editor calls this on every pointer move while a stop is dragged; only accent-bound
    -- properties actually change.
    applyTheme(true)
end

-- A short line for the Activity satellite. Notifications feed it too.
function Library:Log(title)
    table.insert(self.ActivityLog, 1, { time = os.date("%H:%M:%S"), title = tostring(title) })
    while #self.ActivityLog > 20 do table.remove(self.ActivityLog) end
    for _, listener in ipairs(self.ActivityListeners) do
        self:SafeCallback(listener)
    end
end

local function syncScheme()
    local scheme = Library.Scheme
    scheme.BackgroundColor = Glass.PaneMid
    scheme.MainColor = Glass.PaneTop
    scheme.AccentColor = Glass.AccentDeep
    scheme.OutlineColor = Glass.PaneTop:Lerp(Glass.AccentDeep, 0.35)
    scheme.FontColor = Glass.TextPrimary
    scheme.DarkColor = Glass.PaneBottom
end

local function Text(parent, props)
    local label = New("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        FontFace = FONT_BOLD,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, nil)
    for k, v in pairs(props) do label[k] = v end
    label.Parent = parent
    -- Bind to the font role it was built with, so a later font change reaches it.
    local role = "Bold"
    if label.FontFace == FONT_MONO then
        role = "Mono"
    elseif label.FontFace == FONT_MEDIUM then
        role = "Medium"
    end
    Themed(label, { FontFace = function() return Fonts[role] end })
    return label
end

local function textWidth(text, size, font)
    return TextService:GetTextSize(text, size, font, Vector2.new(4000, 200)).X
end

local function merge(defaults, overrides)
    local out = {}
    for k, v in pairs(defaults) do out[k] = v end
    for k, v in pairs(overrides or {}) do out[k] = v end
    return out
end

local function without(list, excluded)
    local out = {}
    for _, item in ipairs(list) do
        if item ~= excluded then table.insert(out, item) end
    end
    return out
end

local function viewportSize()
    local cam = Workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local function toPixels(udim2)
    local vp = viewportSize()
    return Vector2.new(udim2.X.Scale * vp.X + udim2.X.Offset, udim2.Y.Scale * vp.Y + udim2.Y.Offset)
end

local function resolveIcon(icon)
    if typeof(icon) == "number" then return "rbxassetid://" .. icon end
    if typeof(icon) == "string" then
        if icon:match("^rbxasset") or icon:match("^https?://") then return icon end
        if tonumber(icon) then return "rbxassetid://" .. icon end
        return Library.Icons[icon]
    end
    return nil
end

local function resolveKeyCode(bind)
    if typeof(bind) == "EnumItem" then return bind end
    local name = bind
    if typeof(bind) == "table" then name = bind.Value end
    if typeof(name) == "string" then
        local ok, key = pcall(function() return Enum.KeyCode[name] end)
        if ok then return key end
    end
    return nil
end

local KEY_SHORT_NAMES = {
    LeftShift = "LShift", RightShift = "RShift", LeftControl = "LCtrl", RightControl = "RCtrl",
    LeftAlt = "LAlt", RightAlt = "RAlt", LeftSuper = "LCmd", RightSuper = "RCmd", Return = "Enter",
    Backspace = "Back", CapsLock = "Caps", Escape = "Esc", PageUp = "PgUp", PageDown = "PgDn",
    MB1 = "MB1", MB2 = "MB2", MB3 = "MB3",
    Zero = "0", One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9",
}
local function keyDisplayName(name)
    if not name or name == "" or name == "None" then return "None" end
    return KEY_SHORT_NAMES[name] or name
end

local function isPointer(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local function readPingMs()
    local ok, value = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if ok and typeof(value) == "number" and value > 0 then return value end
    local player = Players.LocalPlayer
    if player then
        local okPing, seconds = pcall(player.GetNetworkPing, player)
        if okPing and typeof(seconds) == "number" and seconds > 0 then return seconds * 1000 end
    end
    return nil
end

local function mountGui(gui)
    local candidates = {}
    if IS_STUDIO_PREVIEW then
        table.insert(candidates, StarterGui)
    else
        if typeof(gethui) == "function" then
            local ok, hui = pcall(gethui)
            if ok and typeof(hui) == "Instance" then table.insert(candidates, hui) end
        end
        table.insert(candidates, CoreGui)
        if Players.LocalPlayer then
            table.insert(candidates, Players.LocalPlayer:WaitForChild("PlayerGui"))
        end
    end
    for _, parent in ipairs(candidates) do
        if pcall(function() gui.Parent = parent end) and gui.Parent == parent then return end
    end
end

function Library:GiveSignal(connection)
    table.insert(self.Signals, connection)
    return connection
end

function Library:SafeCallback(callback, ...)
    if typeof(callback) ~= "function" then return end
    local ok, err = pcall(callback, ...)
    if not ok then warn("[FishyUI] callback error: " .. tostring(err)) end
end

-------------------------------------------------------------------------------------------------------
-- Animator
--
-- One Heartbeat drives every spring in the library. Objects join with Animator.Wake and leave on their
-- own once :Step(dt) reports they have come to rest, so idle UI costs nothing.
--
-- Step only integrates. A frame is split into small substeps to keep stiff springs stable, but only the
-- state after the last one is ever seen, so an object that has a :Render() draws once per frame after its
-- substeps instead of on every one of them. That matters most on slow devices: at 20 fps a frame is
-- twelve substeps, and drawing in each multiplied every property write by twelve.
-------------------------------------------------------------------------------------------------------
local Animator = { active = {}, pending = {}, stepping = false, connection = nil, frame = 0 }
local ANIMATOR_MAX_STEP = 1 / 240

function Animator.Wake(object)
    if Library.Unloaded then return end
    if Animator.stepping then
        Animator.pending[object] = true -- tables must not grow while they are being iterated
    else
        Animator.active[object] = true
    end
    if Animator.connection then return end
    Animator.connection = RunService.Heartbeat:Connect(function(dt)
        dt = math.min(dt, 1 / 20)
        local steps = math.max(1, math.ceil(dt / ANIMATOR_MAX_STEP))
        local step = dt / steps
        Animator.frame += 1
        Animator.stepping = true
        for object in pairs(Animator.active) do
            local moving = false
            for _ = 1, steps do
                moving = object:Step(step)
                if not moving then break end
            end
            if object.Render then object:Render() end
            if not moving then Animator.active[object] = nil end
        end
        Animator.stepping = false
        for object in pairs(Animator.pending) do
            Animator.active[object] = true
            Animator.pending[object] = nil
        end
        if next(Animator.active) == nil then
            Animator.connection:Disconnect()
            Animator.connection = nil
        end
    end)
end

function Animator.Stop()
    if Animator.connection then Animator.connection:Disconnect() end
    Animator.connection = nil
    table.clear(Animator.active)
    table.clear(Animator.pending)
end

-- A 1D spring rendered through `onStep(value, velocity)`. `epsilon` is the rest tolerance in value units.
local function Spring(stiffness, dampingRatio, value, onStep, epsilon)
    epsilon = epsilon or 0.01
    local damping = 2 * math.sqrt(stiffness) * dampingRatio
    local spring = { value = value, velocity = 0, target = value }

    function spring:Step(dt)
        self.velocity += (stiffness * (self.target - self.value) - damping * self.velocity) * dt
        self.value += self.velocity * dt
        if math.abs(self.target - self.value) < epsilon and math.abs(self.velocity) < epsilon * 10 then
            self.value, self.velocity = self.target, 0
            return false
        end
        return true
    end

    function spring:Render()
        onStep(self.value, self.velocity)
    end

    function spring:Set(target)
        -- Already resting there (a press released over and over, a mirror re-sent the same value): waking
        -- would only redraw what is already on screen.
        if target == self.target and self.value == target and self.velocity == 0 then return end
        self.target = target
        Animator.Wake(self)
    end

    function spring:Snap(target)
        self.value, self.target, self.velocity = target, target, 0
        onStep(target, 0)
    end

    onStep(value, 0)
    return spring
end

-- ===== 04_materials.lua =====
-------------------------------------------------------------------------------------------------------
-- Materials
-------------------------------------------------------------------------------------------------------

-- A transparency argument may be a fixed number or a theme token / function, in which case it follows
-- the theme (materials like Onyx or Midnight dial the edge light right down).
local function themedTransparency(inst, property, source)
    if typeof(source) == "number" then
        inst[property] = source
    else
        Themed(inst, { [property] = source })
    end
end

-- 9-sliced rim: crisp on the boundary, falling away inward, so a surface reads as lensed glass.
local function GlassEdge(parent, radius, transparency, zIndex)
    local edge = Themed(New("ImageLabel", {
        Name = "GlassEdge",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = Assets.GlassEdge,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(50, 50, 78, 78),
        SliceScale = math.max(radius, 1) / L.SliceBaseRadius,
        ZIndex = zIndex or 1,
    }, parent), { ImageColor3 = "Rim" })
    themedTransparency(edge, "ImageTransparency", transparency)
    Themed(New("UIGradient", {
        Rotation = 104,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0.00, 0),
            NumberSequenceKeypoint.new(0.50, 0.30),
            NumberSequenceKeypoint.new(1.00, 0.08),
        }),
    }, edge), { Color = edgeGradientColor })
    return edge
end

-- Soft halo around a glass surface. GlassGlow is a hollow ring, so its inner edge has to line up with
-- the surface edge: `spread` px of halo per side needs SliceScale = spread / GlowRingInset.
local function GlassShadow(parent, spread, transparency, zIndex)
    local shadow = Themed(New("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, spread * 2, 1, spread * 2),
        BackgroundTransparency = 1,
        Image = Assets.GlassGlow,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(50, 50, 78, 78),
        SliceScale = spread / L.GlowRingInset,
        ZIndex = zIndex or 0,
    }, parent), { ImageColor3 = "Shadow" })
    themedTransparency(shadow, "ImageTransparency", transparency)
    return shadow
end

local function Specular(parent, inset, transparency, zIndex)
    local line = New("Frame", {
        Name = "Specular",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 1),
        Size = UDim2.new(1, -inset, 0, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = transparency,
        BorderSizePixel = 0,
        ZIndex = zIndex or 1,
    }, parent)
    New("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, line)
    return line
end

-- Window-grade glass: theme-tinted body lit from the top-left, rim, top-edge specular and lensed edge.
-- The window, bubble, popups and notifications all use it so they read as one material.
local function PaneMaterial(frame, radius, edgeZ)
    frame.BackgroundColor3 = Color3.new(1, 1, 1)
    frame.BorderSizePixel = 0
    Themed(frame, { BackgroundTransparency = "PaneTransparency" })
    local corner = Corner(frame, radius)
    Themed(New("UIGradient", {
        Rotation = 115,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(1, 0.2),
        }),
    }, frame), { Color = paneGradientColor })

    local border = Themed(New("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = 1,
        LineJoinMode = Enum.LineJoinMode.Round,
    }, frame), { Color = "Rim", Transparency = "BorderTransparency" })
    New("UIGradient", {
        Rotation = 110,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0.00, 0),
            NumberSequenceKeypoint.new(0.45, 0.72),
            NumberSequenceKeypoint.new(1.00, 0.4),
        }),
    }, border)

    local specular = Specular(frame, radius * 4, 0.35, edgeZ - 1)
    local edge = GlassEdge(frame, radius, "EdgeTransparency", edgeZ)
    return { Corner = corner, Border = border, Specular = specular, Edge = edge }
end

-- Popups sit over busy content, so they use the same glass nearly opaque.
local function PopupMaterial(frame, radius, edgeZ)
    local pane = PaneMaterial(frame, radius, edgeZ)
    Themed(frame, { BackgroundTransparency = function() return math.min(Glass.PaneTransparency, 0.08) end })
    return pane
end

-- Groupbox card: a lighter layer of glass sitting on the pane. Floored a little so a card always reads
-- as a distinct surface rather than dissolving into a transparent pane.
local function CardMaterial(frame, radius)
    frame.BorderSizePixel = 0
    Themed(frame, {
        BackgroundColor3 = "LensTint",
        BackgroundTransparency = function() return math.min(Glass.CardTransparency, 0.9) end,
    })
    Corner(frame, radius)
    New("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.45),
        }),
    }, frame)
    local stroke = Themed(New("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = 1,
    }, frame), {
        Color = "Rim",
        Transparency = function() return 0.6 + Glass.BorderTransparency * 0.5 end,
    })
    New("UIGradient", {
        Rotation = 100,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.5, 0.8),
            NumberSequenceKeypoint.new(1, 0.45),
        }),
    }, stroke)
    GlassEdge(frame, radius, function() return math.min(1, Glass.EdgeTransparency + 0.2) end, 2)
    return stroke
end

-- Etched well for inputs, dropdown fields and slider tubes: darker than its surroundings, shaded at the
-- top where the lip casts a shadow and catching a thin line of light along the bottom lip. Kept at least
-- half-opaque so the field stays visible over busy content on see-through themes.
local function FieldMaterial(frame, radius)
    frame.BorderSizePixel = 0
    Themed(frame, {
        BackgroundColor3 = "Field",
        BackgroundTransparency = function() return math.min(Glass.FieldTransparency, 0.5) end,
    })
    Corner(frame, radius)
    New("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.35),
        }),
    }, frame)
    local stroke = Themed(New("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = 1,
        Transparency = 0.82,
    }, frame), { Color = "Rim" })
    local lip = New("Frame", {
        Name = "Lip",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(1, -radius * 2, 0, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, frame)
    New("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, lip)
    return stroke
end

-- Selection lens: nearly clear glass, brighter at the top, lit rim and a hairline specular.
local function GlassLens(parent, radius, zIndex)
    local body = Themed(New("Frame", {
        Name = "Lens",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 0.86,
        BorderSizePixel = 0,
        ZIndex = zIndex,
    }, parent), { BackgroundColor3 = "LensTint" })
    Corner(body, radius)
    New("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.55),
        }),
    }, body)
    local rim = Themed(New("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = 1,
        Transparency = 0.5,
    }, body), { Color = "Rim" })
    New("UIGradient", {
        Rotation = 102,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.02),
            NumberSequenceKeypoint.new(0.5, 0.75),
            NumberSequenceKeypoint.new(1, 0.3),
        }),
    }, rim)
    local edge = GlassEdge(body, radius, 0.62, zIndex + 1)
    Specular(body, radius * 2, 0.4, zIndex + 2)
    return body, edge
end

-- A soft ring of light that swells out from the centre of `parent` and fades: the press response.
local function Pulse(parent, zIndex)
    local size = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y)
    local ring = Themed(New("Frame", {
        Name = "Pulse",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
        ZIndex = zIndex or 5,
    }, parent), { BackgroundColor3 = "Accent" })
    Corner(ring, 999)
    Tween(ring, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(size * 1.3, size * 1.3),
        BackgroundTransparency = 1,
    })
    task.delay(0.6, function() ring:Destroy() end)
end

-- Small round glass button for the window's top-right corner.
local function HeaderButton(parent, name, rightOffset)
    local button = New("TextButton", {
        Name = name,
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, rightOffset, 0, 14),
        Size = UDim2.fromOffset(L.HeaderButton, L.HeaderButton),
        ZIndex = 20,
    }, parent)
    local plate = Themed(New("Frame", {
        Name = "Plate",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        ZIndex = 20,
    }, button), { BackgroundColor3 = "LensTint" })
    Corner(plate, L.HeaderButton / 2)
    local rim = Themed(New("UIStroke", { Thickness = 1, Transparency = 0.7 }, plate), { Color = "Rim" })
    local scale = New("UIScale", { Scale = 1 }, button)
    button.MouseEnter:Connect(function()
        Tween(plate, Motion.Hover, { BackgroundTransparency = 0.8 })
        Tween(rim, Motion.Hover, { Transparency = 0.4 })
        Tween(scale, Motion.Pop, { Scale = 1.08 })
        playSound("Hover")
    end)
    button.MouseLeave:Connect(function()
        Tween(plate, Motion.Hover, { BackgroundTransparency = 0.9 })
        Tween(rim, Motion.Hover, { Transparency = 0.7 })
        Tween(scale, Motion.Pop, { Scale = 1 })
    end)
    button.MouseButton1Down:Connect(function() Tween(scale, Motion.Press, { Scale = 0.9 }) end)
    button.MouseButton1Up:Connect(function() Tween(scale, Motion.Pop, { Scale = 1.08 }) end)
    button.MouseButton1Click:Connect(function() playSound("Press") end)
    return button
end

-- The small "−" in a popup's top corner. Popups still close on an outside click, but anything you dial
-- in by dragging — a colour, a gradient stop — takes the pointer well outside the panel, so there has to
-- be a deliberate way out that doesn't depend on where you let go.
local function PopupClose(panel, W)
    local button = New("TextButton", {
        Name = "Close",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 10),
        Size = UDim2.fromOffset(18, 18),
        ZIndex = 30,
    }, panel)
    local plate = Themed(New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        ZIndex = 30,
    }, button), { BackgroundColor3 = "LensTint" })
    Corner(plate, 9)
    local bar = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(9, 2),
        BorderSizePixel = 0,
        ZIndex = 31,
    }, button), { BackgroundColor3 = "TextSecondary" })
    Corner(bar, 1)
    button.MouseEnter:Connect(function()
        Tween(plate, Motion.Hover, { BackgroundTransparency = 0.76 })
        Tween(bar, Motion.Hover, { Size = UDim2.fromOffset(11, 2), BackgroundColor3 = Glass.TextPrimary })
        playSound("Hover")
    end)
    button.MouseLeave:Connect(function()
        Tween(plate, Motion.Hover, { BackgroundTransparency = 0.9 })
        Tween(bar, Motion.Hover, { Size = UDim2.fromOffset(9, 2), BackgroundColor3 = Glass.TextSecondary })
    end)
    button.MouseButton1Click:Connect(function() W:ClosePopup() end)
    return button
end

-- Liquid lens motion. A spring pulls the lens toward its target; the faster it travels the more it
-- stretches along the path (mostly at the trailing end) and thins across it, then it relaxes to a
-- perfectly still rest. Retargeting mid-flight bends the motion instead of restarting it, and a target
-- function lets the lens follow something that is itself animating.
-- `track` owns position and length along the axis; `body`, centred inside it, owns the squash and press.
local function LiquidMover(track, body, config, flare)
    local vertical = config.Axis ~= "X"
    local baseA, baseB = vertical and track.Position.X or track.Position.Y, vertical and track.Size.X or track.Size.Y
    local mover = {
        value = 0,
        velocity = 0,
        target = 0,
        targetFn = nil,
        length = config.Height or config.Width,
        press = 0,
        pressVelocity = 0,
        pressTarget = 0,
        holdUntil = 0,
    }

    local function currentTarget()
        if mover.targetFn then return mover.targetFn() end
        return mover.target
    end

    local function render()
        local speed = math.abs(mover.velocity)
        local stretch = math.min(config.MaxStretch, speed * config.StretchPerSpeed)
        local start = mover.value - stretch * (mover.velocity >= 0 and 0.65 or 0.35)
        local thin = (stretch / config.MaxStretch) * config.Squash
        local press = math.max(0, mover.press)
        if vertical then
            track.Position = UDim2.new(baseA.Scale, baseA.Offset, 0, start)
            track.Size = UDim2.new(baseB.Scale, baseB.Offset, 0, mover.length + stretch)
            body.Size = UDim2.new(1, -(thin + press * config.PressX) * 2, 1, -press * config.PressY * 2)
        else
            track.Position = UDim2.new(0, start, baseA.Scale, baseA.Offset)
            track.Size = UDim2.new(0, mover.length + stretch, baseB.Scale, baseB.Offset)
            body.Size = UDim2.new(1, -press * config.PressX * 2, 1, -(thin + press * config.PressY) * 2)
        end
        if flare then
            local glow = math.min(1, speed / 700)
            flare.ImageTransparency = config.FlareRest - (config.FlareRest - config.FlarePeak) * glow
        end
    end

    -- The target can only move between frames (it follows tweens and layout), so a target function is
    -- read once per frame rather than once per substep; the indicator's reads an instance property.
    local targetFrame, frameTarget = -1, 0

    function mover:Step(dt)
        if targetFrame ~= Animator.frame then
            targetFrame, frameTarget = Animator.frame, currentTarget()
        end
        local target = frameTarget
        local damping = 2 * math.sqrt(config.Stiffness) * config.Damping
        self.velocity += (config.Stiffness * (target - self.value) - damping * self.velocity) * dt
        self.value += self.velocity * dt

        -- Press has its own looser spring so a release springs back with a little give.
        local pressDamping = 2 * math.sqrt(420) * 0.45
        self.pressVelocity += (420 * (self.pressTarget - self.press) - pressDamping * self.pressVelocity) * dt
        self.press += self.pressVelocity * dt

        -- holdUntil keeps the lens awake while its target is still being tweened, so it can't fall
        -- asleep on the first frame of a move before the target has started going anywhere.
        if os.clock() >= self.holdUntil
            and math.abs(target - self.value) < 0.05 and math.abs(self.velocity) < 0.5
            and math.abs(self.pressTarget - self.press) < 0.002 and math.abs(self.pressVelocity) < 0.02 then
            self.value, self.velocity = target, 0
            self.press, self.pressVelocity = self.pressTarget, 0
            return false
        end
        return true
    end

    mover.Render = render

    function mover:SetTarget(value)
        if typeof(value) == "function" then
            self.targetFn = value
        else
            self.targetFn, self.target = nil, value
        end
        targetFrame = -1 -- a new target takes effect on the very next step
        Animator.Wake(self)
    end

    function mover:Wake(holdFor)
        if holdFor then self.holdUntil = math.max(self.holdUntil, os.clock() + holdFor) end
        Animator.Wake(self)
    end

    function mover:Snap()
        self.value, self.velocity = currentTarget(), 0
        render()
    end

    function mover:SetPressed(pressed)
        self.pressTarget = pressed and 1 or 0
        Animator.Wake(self)
    end

    return mover
end

-- Right-pointing chevron drawn from two hairlines; rotate the returned frame to 90 to point down.
local function Chevron(parent, zIndex)
    local holder = New("Frame", {
        Name = "Chevron",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(10, 10),
        ZIndex = zIndex,
    }, parent)
    local lines = {}
    for i, rotation in ipairs({ 45, -45 }) do
        lines[i] = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, i == 1 and -2 or 2),
            Size = UDim2.fromOffset(6, 1.5),
            Rotation = rotation,
            BorderSizePixel = 0,
            ZIndex = zIndex,
        }, holder)
    end
    return holder, lines
end

-- Check mark drawn from a short and a long stroke; `reveal(visible)` draws or erases it.
local function CheckGlyph(parent, zIndex)
    local holder = New("Frame", {
        Name = "Check",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(12, 12),
        ZIndex = zIndex,
    }, parent)
    local short = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromOffset(1.5, 6.5),
        Size = UDim2.fromOffset(0, 2),
        Rotation = 45,
        BorderSizePixel = 0,
        ZIndex = zIndex,
    }, holder), { BackgroundColor3 = "Knob" })
    local long = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromOffset(4.2, 9.2),
        Size = UDim2.fromOffset(0, 2),
        Rotation = -50,
        BorderSizePixel = 0,
        ZIndex = zIndex,
    }, holder), { BackgroundColor3 = "Knob" })
    Corner(short, 1)
    Corner(long, 1)
    local token = 0
    local function reveal(visible, instant)
        token += 1
        local my = token
        if instant then
            short.Size = UDim2.fromOffset(visible and 4.5 or 0, 2)
            long.Size = UDim2.fromOffset(visible and 9 or 0, 2)
            return
        end
        if visible then
            Tween(short, TweenInfo.new(0.1, Enum.EasingStyle.Quad), { Size = UDim2.fromOffset(4.5, 2) })
            task.delay(0.08, function()
                if my == token then Tween(long, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { Size = UDim2.fromOffset(9, 2) }) end
            end)
        else
            Tween(long, Motion.FadeOut, { Size = UDim2.fromOffset(0, 2) })
            Tween(short, Motion.FadeOut, { Size = UDim2.fromOffset(0, 2) })
        end
    end
    return holder, reveal
end

-- ===== 05_telemetry.lua =====
-------------------------------------------------------------------------------------------------------
-- Telemetry: live session and network numbers shared by the bubble and the satellite pods. Samples once
-- a second; listeners registered with OnTick run right after each sample.
-------------------------------------------------------------------------------------------------------
local Telemetry = {
    SessionStart = os.clock(),
    Fps = 0,
    Ping = nil,
    PingSamples = {},
    Region = "--",
    Executor = "Unknown",
    Listeners = {},
    Running = false,
}
local TELEMETRY_SAMPLES = 32

function Telemetry.Strength(ping)
    if not ping or ping <= 0 then return 0 end
    if ping <= L.PingGood then return 3 end
    if ping <= L.PingFair then return 2 end
    return 1
end

function Telemetry.StrengthColor(strength)
    if strength >= 3 then return Glass.Accent end
    if strength == 2 then return Glass.Warning end
    return Glass.Danger
end

-- 00:12:45
function Telemetry.Clock(seconds)
    seconds = math.max(0, math.floor(seconds))
    return string.format("%02d:%02d:%02d", math.floor(seconds / 3600), math.floor(seconds % 3600 / 60), seconds % 60)
end

-- 2h 14m, or 14m 05s under an hour
function Telemetry.Duration(seconds)
    seconds = math.max(0, math.floor(seconds))
    local hours, minutes = math.floor(seconds / 3600), math.floor(seconds % 3600 / 60)
    if hours > 0 then return string.format("%dh %02dm", hours, minutes) end
    return string.format("%dm %02ds", minutes, seconds % 60)
end

function Telemetry.OnTick(callback)
    table.insert(Telemetry.Listeners, callback)
end

function Telemetry.Start()
    if Telemetry.Running then return end
    Telemetry.Running = true

    if typeof(identifyexecutor) == "function" then
        local ok, name = pcall(identifyexecutor)
        if ok and name then Telemetry.Executor = tostring(name) end
    elseif RunService:IsStudio() then
        Telemetry.Executor = "Studio"
    end

    -- The player's country/region as Roblox reports it. The server's region isn't visible to clients.
    task.spawn(function()
        local player = Players.LocalPlayer
        if not player then return end
        local ok, code = pcall(function() return LocalizationService:GetCountryRegionForPlayerAsync(player) end)
        if ok and typeof(code) == "string" and code ~= "" then Telemetry.Region = code end
    end)

    local function sample()
        Telemetry.Ping = readPingMs()
        table.insert(Telemetry.PingSamples, Telemetry.Ping or 0)
        if #Telemetry.PingSamples > TELEMETRY_SAMPLES then table.remove(Telemetry.PingSamples, 1) end
        for _, listener in ipairs(Telemetry.Listeners) do
            Library:SafeCallback(listener)
        end
    end

    local frames, elapsed = 0, 0
    Library:GiveSignal(RunService.Heartbeat:Connect(function(dt)
        frames += 1
        elapsed += dt
        if elapsed < 1 then return end
        Telemetry.Fps = math.floor(frames / elapsed + 0.5)
        frames, elapsed = 0, 0
        sample()
    end))
    task.defer(sample)
end

-- ===== 06_prefs.lua =====
-------------------------------------------------------------------------------------------------------
-- Preferences: language, font family, and which setup steps to skip. Saved alongside the theme choice so
-- a returning user drops straight into the interface. A factory reset clears all of it.
-------------------------------------------------------------------------------------------------------
local PREFS_FILE = THEME_FILE_FOLDER .. "/setup.json"

local Prefs = {
    Language = "en",
    FontFamily = "Gotham",
    SkipLanguage = false,
    SkipTheme = false,
    SkipFont = false,
}

local function savePrefs()
    if typeof(writefile) ~= "function" then return end
    pcall(function()
        if typeof(isfolder) == "function" and typeof(makefolder) == "function" and not isfolder(THEME_FILE_FOLDER) then
            makefolder(THEME_FILE_FOLDER)
        end
        writefile(PREFS_FILE, HttpService:JSONEncode(Prefs))
    end)
end

local function loadPrefs()
    if typeof(readfile) ~= "function" or typeof(isfile) ~= "function" then return end
    pcall(function()
        if not isfile(PREFS_FILE) then return end
        local decoded = HttpService:JSONDecode(readfile(PREFS_FILE))
        if typeof(decoded) ~= "table" then return end
        for key, value in pairs(decoded) do
            if Prefs[key] ~= nil then Prefs[key] = value end
        end
    end)
end

local function clearPrefs()
    Prefs.Language, Prefs.FontFamily = "en", "Gotham"
    Prefs.SkipLanguage, Prefs.SkipTheme, Prefs.SkipFont = false, false, false
    if typeof(delfile) == "function" and typeof(isfile) == "function" then
        pcall(function()
            if isfile(PREFS_FILE) then delfile(PREFS_FILE) end
            if isfile(THEME_FILE) then delfile(THEME_FILE) end
        end)
    else
        savePrefs()
    end
end

-------------------------------------------------------------------------------------------------------
-- Languages: the ten most spoken on Roblox, English first.
-------------------------------------------------------------------------------------------------------
local Languages = {
    { Code = "en", Name = "English", Native = "English" },
    { Code = "es", Name = "Spanish", Native = "Español" },
    { Code = "pt", Name = "Portuguese", Native = "Português" },
    { Code = "fr", Name = "French", Native = "Français" },
    { Code = "de", Name = "German", Native = "Deutsch" },
    { Code = "ru", Name = "Russian", Native = "Русский" },
    { Code = "tr", Name = "Turkish", Native = "Türkçe" },
    { Code = "ja", Name = "Japanese", Native = "日本語" },
    { Code = "ko", Name = "Korean", Native = "한국어" },
    { Code = "zh", Name = "Chinese", Native = "中文" },
}

local Strings = {
    en = {
        title_language = "Choose your language", title_theme = "Choose your theme", title_font = "Choose your font",
        subtitle = "You can change this anytime in Settings.", continue_ = "Continue",
        dont_show_again = "Don't show this again", attachments = "Attachments",
        deploy = "Deploy", stow = "Stow", factory_reset = "Factory Reset",
    },
    es = {
        title_language = "Elige tu idioma", title_theme = "Elige tu tema", title_font = "Elige tu fuente",
        subtitle = "Puedes cambiarlo cuando quieras en Ajustes.", continue_ = "Continuar",
        dont_show_again = "No mostrar de nuevo", attachments = "Accesorios",
        deploy = "Desplegar", stow = "Guardar", factory_reset = "Restablecer",
    },
    pt = {
        title_language = "Escolha seu idioma", title_theme = "Escolha seu tema", title_font = "Escolha sua fonte",
        subtitle = "Você pode mudar isso quando quiser nas Configurações.", continue_ = "Continuar",
        dont_show_again = "Não mostrar novamente", attachments = "Anexos",
        deploy = "Abrir", stow = "Guardar", factory_reset = "Redefinir",
    },
    fr = {
        title_language = "Choisissez votre langue", title_theme = "Choisissez votre thème", title_font = "Choisissez votre police",
        subtitle = "Vous pouvez le changer à tout moment dans les Paramètres.", continue_ = "Continuer",
        dont_show_again = "Ne plus afficher", attachments = "Modules",
        deploy = "Déployer", stow = "Ranger", factory_reset = "Réinitialiser",
    },
    de = {
        title_language = "Wähle deine Sprache", title_theme = "Wähle dein Design", title_font = "Wähle deine Schriftart",
        subtitle = "Du kannst das jederzeit in den Einstellungen ändern.", continue_ = "Weiter",
        dont_show_again = "Nicht mehr anzeigen", attachments = "Module",
        deploy = "Anzeigen", stow = "Verstauen", factory_reset = "Zurücksetzen",
    },
    ru = {
        title_language = "Выберите язык", title_theme = "Выберите тему", title_font = "Выберите шрифт",
        subtitle = "Это можно изменить в настройках в любое время.", continue_ = "Продолжить",
        dont_show_again = "Больше не показывать", attachments = "Модули",
        deploy = "Открыть", stow = "Убрать", factory_reset = "Сброс",
    },
    tr = {
        title_language = "Dilini seç", title_theme = "Temanı seç", title_font = "Yazı tipini seç",
        subtitle = "Bunu istediğin zaman Ayarlar'dan değiştirebilirsin.", continue_ = "Devam",
        dont_show_again = "Bir daha gösterme", attachments = "Ekler",
        deploy = "Çıkar", stow = "Kaldır", factory_reset = "Sıfırla",
    },
    ja = {
        title_language = "言語を選択", title_theme = "テーマを選択", title_font = "フォントを選択",
        subtitle = "設定からいつでも変更できます。", continue_ = "続ける",
        dont_show_again = "次回から表示しない", attachments = "アタッチメント",
        deploy = "表示", stow = "収納", factory_reset = "初期化",
    },
    ko = {
        title_language = "언어 선택", title_theme = "테마 선택", title_font = "글꼴 선택",
        subtitle = "설정에서 언제든지 변경할 수 있습니다.", continue_ = "계속",
        dont_show_again = "다시 표시 안 함", attachments = "부착물",
        deploy = "꺼내기", stow = "넣기", factory_reset = "초기화",
    },
    zh = {
        title_language = "选择语言", title_theme = "选择主题", title_font = "选择字体",
        subtitle = "你可以随时在设置中更改。", continue_ = "继续",
        dont_show_again = "不再显示", attachments = "附件",
        deploy = "展开", stow = "收起", factory_reset = "恢复默认",
    },
}

local function T(key)
    local table_ = Strings[Library.Language] or Strings.en
    return table_[key] or Strings.en[key] or key
end

function Library:SetLanguage(code)
    if not Strings[code] then return false end
    self.Language = code
    Prefs.Language = code
    savePrefs()
    return true
end

function Library:T(key)
    return T(key)
end

-------------------------------------------------------------------------------------------------------
-- Fonts
-------------------------------------------------------------------------------------------------------
local FontFamilies = {
    { Name = "Gotham", Font = Enum.Font.Gotham, Sample = "Aa" },
    { Name = "Roboto", Font = Enum.Font.Roboto, Sample = "Aa" },
    { Name = "Nunito", Font = Enum.Font.Nunito, Sample = "Aa" },
    { Name = "Ubuntu", Font = Enum.Font.Ubuntu, Sample = "Aa" },
    { Name = "Josefin", Font = Enum.Font.JosefinSans, Sample = "Aa" },
    { Name = "Oswald", Font = Enum.Font.Oswald, Sample = "Aa" },
    { Name = "Merriweather", Font = Enum.Font.Merriweather, Sample = "Aa" },
    { Name = "Mono", Font = Enum.Font.RobotoMono, Sample = "Aa" },
}

local function familyByName(name)
    for _, entry in ipairs(FontFamilies) do
        if entry.Name == name then return entry end
    end
    return FontFamilies[1]
end

function Library:SetFontFamily(name)
    local entry = familyByName(name)
    local base = Font.fromEnum(entry.Font)
    Fonts.Bold = Font.new(base.Family, Enum.FontWeight.Bold)
    Fonts.Medium = Font.new(base.Family, Enum.FontWeight.Medium)
    Fonts.Mono = if entry.Name == "Mono" then Fonts.Bold else FONT_MONO
    self.FontFamily = entry.Name
    self.Scheme.Font = Fonts.Bold
    Prefs.FontFamily = entry.Name
    savePrefs()
    applyTheme()
    return true
end

-- Applies whatever was saved last run. Called before the window is built.
local function applyPrefs()
    loadPrefs()
    Library.Language = Strings[Prefs.Language] and Prefs.Language or "en"
    local entry = familyByName(Prefs.FontFamily)
    local base = Font.fromEnum(entry.Font)
    Fonts.Bold = Font.new(base.Family, Enum.FontWeight.Bold)
    Fonts.Medium = Font.new(base.Family, Enum.FontWeight.Medium)
    Fonts.Mono = if entry.Name == "Mono" then Fonts.Bold else FONT_MONO
    Library.FontFamily = entry.Name
    Library.Scheme.Font = Fonts.Bold
end

-- ===== 07_sound.lua =====
-------------------------------------------------------------------------------------------------------
-- Sound: soft glass feedback. One built-in click is retuned per voice (pitch + level) rather than
-- pulling remote assets, so it always loads and costs nothing to stream.
-------------------------------------------------------------------------------------------------------
local SoundService = service("SoundService")
local CLICK_ASSET = "rbxasset://sounds/electronicpingshort.wav"

Prefs.SoundEnabled = true
Prefs.SoundVolume = 0.6

local VOICES = {
    ToggleOn = { Speed = 1.65, Volume = 0.30 },
    ToggleOff = { Speed = 1.12, Volume = 0.24 },
    Tick = { Speed = 2.30, Volume = 0.07, MinGap = 0.035 }, -- slider steps
    Tab = { Speed = 0.72, Volume = 0.26 }, -- the low "whoosh" on page changes
    Open = { Speed = 0.95, Volume = 0.32 },
    Close = { Speed = 0.66, Volume = 0.26 },
    Hover = { Speed = 2.60, Volume = 0.045, MinGap = 0.05 },
    Deploy = { Speed = 1.35, Volume = 0.24 },
    Press = { Speed = 1.90, Volume = 0.16 },
}

local voiceSounds, lastPlayed = {}, {}

local function voiceSound(name)
    local existing = voiceSounds[name]
    if existing and existing.Parent then return existing end
    local voice = VOICES[name]
    local sound = New("Sound", {
        Name = "FishyUI_" .. name,
        SoundId = CLICK_ASSET,
        PlaybackSpeed = voice.Speed,
        Volume = voice.Volume,
        RollOffMaxDistance = 0,
    }, SoundService)
    voiceSounds[name] = sound
    return sound
end

-- Plays a UI voice. Silently does nothing when sound is off or the asset failed to load.
-- Assigns the upvalue declared in 03_core.lua rather than shadowing it with a new local.
function playSound(name)
    -- After an unload a stray callback would otherwise mint a fresh Sound that nothing ever cleans up.
    if not Library.SoundEnabled or Library.Unloaded then return end
    local voice = VOICES[name]
    if not voice then return end
    local now = os.clock()
    if voice.MinGap and now - (lastPlayed[name] or 0) < voice.MinGap then return end
    lastPlayed[name] = now
    pcall(function()
        local sound = voiceSound(name)
        sound.Volume = voice.Volume * Library.SoundVolume
        sound.TimePosition = 0
        sound:Play()
    end)
end

Library.SoundEnabled = true
Library.SoundVolume = 0.6

function Library:SetSoundEnabled(enabled)
    self.SoundEnabled = enabled == true
    Prefs.SoundEnabled = self.SoundEnabled
    savePrefs()
end

function Library:SetSoundVolume(volume)
    self.SoundVolume = math.clamp(tonumber(volume) or 0.6, 0, 1)
    Prefs.SoundVolume = self.SoundVolume
    savePrefs()
end

function Library:PlaySound(name)
    playSound(name)
end

local function applySoundPrefs()
    Library.SoundEnabled = Prefs.SoundEnabled ~= false
    Library.SoundVolume = tonumber(Prefs.SoundVolume) or 0.6
end

-- ===== 08_ambient.lua =====
-------------------------------------------------------------------------------------------------------
-- Ambient: a living backdrop inside the glass, chosen by theme. Motes drift through Amethyst, ribbons
-- sweep across Aurora, scanlines crawl down Neon, embers rise through Ember. It sits under the content
-- and only animates while the window is on screen.
-------------------------------------------------------------------------------------------------------
local AmbientKinds = {
    Amethyst = "motes",
    Aurora = "aurora",
    Neon = "scanlines",
    Ember = "embers",
    Glacier = "snow",
    Sakura = "petals",
    Midnight = "stars",
    Smoke = "motes",
    Onyx = "none",
    Frost = "none",
}

local function randomBetween(low, high)
    return low + math.random() * (high - low)
end

local function BuildAmbient(W)
    local Main = W.Main
    local layer = New("Frame", {
        Name = "Ambient",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        ZIndex = 2,
    }, Main)
    -- Clipping is rectangular, so without a matching corner the motes drift into the window's rounded
    -- corner cut-outs and read as floating just outside the glass.
    W.AmbientCorner = Corner(layer, Library.CornerRadius)

    local kind, particles, bands, lines = "none", {}, {}, {}

    local function clear()
        for _, child in ipairs(layer:GetChildren()) do child:Destroy() end
        table.clear(particles)
        table.clear(bands)
        table.clear(lines)
    end

    -- Drifting specks: motes, embers, snow, petals and stars all share this shape with different motion.
    -- Each particle's position and spin live here rather than being read back off the frame every
    -- frame: reading an instance property costs about as much as writing one.
    local function buildParticles(count, rising, petal)
        for i = 1, count do
            local size = randomBetween(2, if petal then 7 else 4)
            local x, y = math.random(), math.random()
            local base = randomBetween(0.45, 0.85)
            local rotation = if petal then math.random(0, 180) else 0
            local dot = Themed(New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(x, y),
                Size = UDim2.fromOffset(size, if petal then size * 0.6 else size),
                BackgroundTransparency = base,
                BorderSizePixel = 0,
                Rotation = rotation,
                ZIndex = 2,
            }, layer), { BackgroundColor3 = if kind == "embers" then "Warning" else "Accent" })
            Corner(dot, if petal then 2 else 8)
            particles[i] = {
                Frame = dot,
                X = x,
                Y = y,
                Rotation = rotation,
                Speed = randomBetween(0.008, 0.03) * (if rising then -1 else 1),
                Sway = randomBetween(0.003, 0.012),
                Phase = math.random() * math.pi * 2,
                Base = base,
                Spin = if petal then randomBetween(-20, 20) else 0,
            }
        end
    end

    local function buildAurora()
        for i = 1, 3 do
            local band = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(math.random(), randomBetween(0.15, 0.7)),
                Size = UDim2.fromScale(randomBetween(0.7, 1.2), randomBetween(0.12, 0.26)),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Rotation = randomBetween(-14, 14),
                ZIndex = 2,
            }, layer)
            Corner(band, 40)
            local gradient = Themed(New("UIGradient", {
                Rotation = 0,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.5, randomBetween(0.72, 0.88)),
                    NumberSequenceKeypoint.new(1, 1),
                }),
            }, band), { Color = accentSequence })
            local position = band.Position
            bands[i] = {
                Frame = band, Gradient = gradient, X = position.X.Scale, Y = position.Y.Scale,
                Speed = randomBetween(0.01, 0.035), Phase = math.random() * 6,
            }
        end
    end

    local function buildScanlines()
        for i = 1, 22 do
            local line = Themed(New("Frame", {
                Position = UDim2.new(0, 0, (i - 1) / 22, 0),
                Size = UDim2.new(1, 0, 0, 2),
                BackgroundTransparency = 0.88,
                BorderSizePixel = 0,
                ZIndex = 2,
            }, layer), { BackgroundColor3 = "Accent" })
            lines[i] = { Frame = line, Offset = (i - 1) / 22 }
        end
    end

    local function rebuild()
        clear()
        kind = AmbientKinds[Library.Theme] or "none"
        if kind == "motes" then
            buildParticles(16, true, false)
        elseif kind == "embers" then
            buildParticles(18, true, false)
        elseif kind == "snow" then
            buildParticles(18, false, false)
        elseif kind == "petals" then
            buildParticles(14, false, true)
        elseif kind == "stars" then
            buildParticles(22, true, false)
        elseif kind == "aurora" then
            buildAurora()
        elseif kind == "scanlines" then
            buildScanlines()
        end
    end

    local clock = 0
    Library:GiveSignal(RunService.Heartbeat:Connect(function(dt)
        if not W.Holder.Visible or kind == "none" then return end
        clock += dt
        for _, particle in ipairs(particles) do
            local y = particle.Y + particle.Speed * dt * 6
            if y < -0.05 then y = 1.05 elseif y > 1.05 then y = -0.05 end
            local x = particle.X + math.sin(clock * 0.6 + particle.Phase) * particle.Sway * dt * 6
            if x < -0.05 then x = 1.05 elseif x > 1.05 then x = -0.05 end
            particle.X, particle.Y = x, y
            particle.Frame.Position = UDim2.fromScale(x, y)
            if particle.Spin ~= 0 then
                particle.Rotation += particle.Spin * dt
                particle.Frame.Rotation = particle.Rotation
            end
            -- Gentle breathing so the field never looks static.
            particle.Frame.BackgroundTransparency = math.clamp(particle.Base + math.sin(clock * 1.3 + particle.Phase) * 0.18, 0.3, 0.97)
        end
        for _, band in ipairs(bands) do
            local x = band.X + band.Speed * dt
            if x > 1.3 then x = -0.3 end
            band.X = x
            band.Y += math.sin(clock * 0.35 + band.Phase) * 0.0009
            band.Frame.Position = UDim2.fromScale(x, band.Y)
            band.Gradient.Rotation = math.sin(clock * 0.2 + band.Phase) * 18
        end
        for _, line in ipairs(lines) do
            local y = (line.Offset + clock * 0.035) % 1
            line.Frame.Position = UDim2.new(0, 0, y, 0)
        end
    end))

    local previousTheme = W.OnThemeChanged
    W.OnThemeChanged = function(selfRef)
        if previousTheme then previousTheme(selfRef) end
        rebuild()
    end

    rebuild()
    W.Ambient = layer
end

-- ===== 09_cursor.lua =====
-------------------------------------------------------------------------------------------------------
-- Cursors: six glass pointers drawn from shapes, plus the system default. The chosen one replaces the
-- Roblox mouse icon and follows it every frame, tinted by the active theme.
-------------------------------------------------------------------------------------------------------
local CURSOR_STYLES = { "Default", "Dot", "Ring", "Halo", "Crosshair", "Diamond", "Beam" }

Prefs.Cursor = "Default"
Library.Cursor = "Default"
Library.CursorStyles = CURSOR_STYLES

-- Each builder draws its shape into `parent` and returns nothing; all shapes are theme-bound.
local function drawCursor(style, parent, zIndex)
    if style == "Dot" then
        local glow = Themed(New("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1,
            Image = Assets.Spark, ImageTransparency = 0.45, ZIndex = zIndex,
        }, parent), { ImageColor3 = "Accent" })
        local dot = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(8, 8), BorderSizePixel = 0, ZIndex = zIndex + 1,
        }, parent), { BackgroundColor3 = "Knob" })
        Corner(dot, 4)
        return glow
    elseif style == "Ring" then
        local ring = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, ZIndex = zIndex,
        }, parent)
        Corner(ring, 8)
        Themed(New("UIStroke", { Thickness = 2, Transparency = 0.05 }, ring), { Color = "Accent" })
    elseif style == "Halo" then
        local ring = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, ZIndex = zIndex,
        }, parent)
        Corner(ring, 10)
        Themed(New("UIStroke", { Thickness = 1.5, Transparency = 0.35 }, ring), { Color = "Rim" })
        local core = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, ZIndex = zIndex + 1,
        }, parent), { BackgroundColor3 = "Accent" })
        Corner(core, 3)
    elseif style == "Crosshair" then
        for _, spec in ipairs({
            { UDim2.fromOffset(2, 8), UDim2.new(0.5, 0, 0.5, -9) },
            { UDim2.fromOffset(2, 8), UDim2.new(0.5, 0, 0.5, 9) },
            { UDim2.fromOffset(8, 2), UDim2.new(0.5, -9, 0.5, 0) },
            { UDim2.fromOffset(8, 2), UDim2.new(0.5, 9, 0.5, 0) },
        }) do
            local bar = Themed(New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = spec[2], Size = spec[1],
                BorderSizePixel = 0, ZIndex = zIndex,
            }, parent), { BackgroundColor3 = "Accent" })
            Corner(bar, 1)
        end
        local centre = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(3, 3), BorderSizePixel = 0, ZIndex = zIndex + 1,
        }, parent), { BackgroundColor3 = "Knob" })
        Corner(centre, 2)
    elseif style == "Diamond" then
        local diamond = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(11, 11), Rotation = 45, BackgroundTransparency = 0.15,
            BorderSizePixel = 0, ZIndex = zIndex,
        }, parent), { BackgroundColor3 = "Accent" })
        Corner(diamond, 2)
        Themed(New("UIStroke", { Thickness = 1, Transparency = 0.3 }, diamond), { Color = "Rim" })
    elseif style == "Beam" then
        local beam = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(3, 20), Rotation = 24, BorderSizePixel = 0, ZIndex = zIndex,
        }, parent), { BackgroundColor3 = "Accent" })
        Corner(beam, 2)
        local tip = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(5, 5), BorderSizePixel = 0, ZIndex = zIndex + 1,
        }, parent), { BackgroundColor3 = "Knob" })
        Corner(tip, 3)
    end
    return nil
end

local function BuildCursor(W)
    local holder = New("Frame", {
        Name = "Cursor",
        Active = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(32, 32),
        Visible = false,
        ZIndex = 9000,
    }, W.ScreenGui)
    -- The cursor rides directly under the pointer at the very top of the stack, so it must be completely
    -- transparent to input: anything else and it swallows every click aimed at what is beneath it.
    -- Interactable is the explicit switch and covers descendants too; it is pcall'd because older clients
    -- predate the property, where Active = false on a Frame is already the correct behaviour.
    pcall(function() holder.Interactable = false end)
    local holderScale = New("UIScale", { Scale = 1 }, holder)

    local current = "Default"
    local function rebuild()
        for _, child in ipairs(holder:GetChildren()) do
            if not child:IsA("UIScale") then child:Destroy() end
        end
        if current ~= "Default" then drawCursor(current, holder, 9000) end
        -- Interactable on the holder is meant to cover descendants, but the shapes are rebuilt on every
        -- style change and sit exactly under the pointer, so each one is switched off explicitly too.
        -- A cursor that eats clicks is worse than no cursor at all.
        for _, part in ipairs(holder:GetDescendants()) do
            if part:IsA("GuiObject") then
                part.Active = false
                pcall(function() part.Interactable = false end)
            end
        end
    end

    local function apply(style)
        current = if table.find(CURSOR_STYLES, style) then style else "Default"
        Library.Cursor = current
        Prefs.Cursor = current
        savePrefs()
        rebuild()
        holder.Visible = current ~= "Default"
        pcall(function() UserInputService.MouseIconEnabled = current == "Default" end)
    end
    W.ApplyCursor = apply
    function Library:SetCursor(style)
        apply(style)
        return true
    end

    -- GetMouseLocation excludes the top bar, while this ScreenGui ignores the inset, so add it back.
    -- Most frames the pointer hasn't moved, so the write is skipped unless the spot actually changed.
    local lastX, lastY
    Library:GiveSignal(RunService.Heartbeat:Connect(function()
        if current == "Default" then return end
        local inset = GuiService:GetGuiInset()
        local mouse = UserInputService:GetMouseLocation()
        local x, y = mouse.X + inset.X, mouse.Y + inset.Y
        if x == lastX and y == lastY then return end
        lastX, lastY = x, y
        holder.Position = UDim2.fromOffset(x, y)
    end))
    Library:GiveSignal(UserInputService.InputBegan:Connect(function(input)
        if holder.Visible and input.UserInputType == Enum.UserInputType.MouseButton1 then
            Tween(holderScale, Motion.Press, { Scale = 0.8 })
        end
    end))
    Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
        if holder.Visible and input.UserInputType == Enum.UserInputType.MouseButton1 then
            Tween(holderScale, Motion.Pop, { Scale = 1 })
        end
    end))

    Library:OnUnload(function()
        pcall(function() UserInputService.MouseIconEnabled = true end)
    end)

    apply(Prefs.Cursor or "Default")

    -- The picker, opened from the header.
    function W.OpenCursors(anchor)
        local rowHeight, width = 34, 176
        local height = 12 + #CURSOR_STYLES * (rowHeight + 4) + 6
        local panel = New("Frame", { Name = "CursorPicker", Size = UDim2.fromOffset(width, 0), ClipsDescendants = true }, nil)
        PopupMaterial(panel, 12, 40)
        W:PlacePopup(panel, anchor, 8, height)
        for i, style in ipairs(CURSOR_STYLES) do
            local row = New("TextButton", {
                Name = style, Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
                Position = UDim2.fromOffset(6, 6 + (i - 1) * (rowHeight + 4)),
                Size = UDim2.new(1, -12, 0, rowHeight), ZIndex = 2,
            }, panel)
            local plate = Themed(New("Frame", {
                Size = UDim2.fromScale(1, 1), BackgroundTransparency = if style == current then 0.84 else 0.94,
                BorderSizePixel = 0, ZIndex = 2,
            }, row), { BackgroundColor3 = "LensTint" })
            Corner(plate, 8)
            local preview = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0),
                Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1, ZIndex = 3,
            }, row)
            if style == "Default" then
                Themed(Text(preview, {
                    Text = "A", TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center,
                    Size = UDim2.fromScale(1, 1), ZIndex = 4,
                }), { TextColor3 = "TextMuted" })
            else
                drawCursor(style, preview, 4)
            end
            Themed(Text(row, {
                Text = style, FontFace = FONT_MEDIUM, TextSize = 12,
                Position = UDim2.fromOffset(44, 0), Size = UDim2.new(1, -54, 1, 0), ZIndex = 3,
            }), { TextColor3 = if style == current then "TextPrimary" else "TextSecondary" })
            row.MouseEnter:Connect(function()
                Tween(plate, Motion.Hover, { BackgroundTransparency = 0.84 })
                playSound("Hover")
            end)
            row.MouseLeave:Connect(function()
                if style ~= current then Tween(plate, Motion.Hover, { BackgroundTransparency = 0.94 }) end
            end)
            row.MouseButton1Click:Connect(function()
                apply(style)
                playSound("Press")
                W:ClosePopup()
            end)
        end
        W:OpenPopup(panel, function()
            Tween(panel, Motion.FadeOut, { Size = UDim2.fromOffset(width, 0) })
            task.delay(Motion.FadeOut.Time, function() panel:Destroy() end)
        end)
        Tween(panel, Motion.Reveal, { Size = UDim2.fromOffset(width, height) })
    end
end

-- ===== 10_containers.lua =====
-------------------------------------------------------------------------------------------------------
-- Containers
--
-- Groupboxes, tabbox tabs and dependency boxes are all containers: a vertical stack of elements. The
-- element builders (Elements.Toggle, Elements.Slider, ...) live in the files that follow this one.
--
-- Every container carries `W`, the window's internal context. Elements use it for:
--   W.Scale                        the window UIScale (absolute sizes divide by W.Scale.Scale)
--   W:OpenPopup(frame, onClose)    show a floating panel above everything; one at a time
--   W:ClosePopup()
--   W:PlacePopup(frame, anchor, gap)  position a popup under an element, flipping above if needed
--   W:ShowTooltip(target, text) / W:HideTooltip(target)
-------------------------------------------------------------------------------------------------------
local Elements = {}
local Container = {}
Container.__index = Container

local function newContainer(W, frame)
    return setmetatable({ W = W, Frame = frame, Order = 0 }, Container)
end

function Container:NextOrder()
    self.Order += 1
    return self.Order
end

local function stackLayout(frame, padding)
    return New("UIListLayout", {
        Padding = UDim.new(0, padding),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    }, frame)
end

local function bindTooltip(W, target, getText)
    target.MouseEnter:Connect(function()
        local text = getText()
        if text and text ~= "" then W:ShowTooltip(target, text) end
    end)
    target.MouseLeave:Connect(function() W:HideTooltip(target) end)
end

-- A row with the label on the left and an accessory strip on the right that keypickers, colour orbs
-- and the element's own control share. The label gives up width as accessories are added.
local function AccessoryRow(container, height)
    local row = New("Frame", {
        Name = "Row",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height),
        LayoutOrder = container:NextOrder(),
    }, container.Frame)
    local accessories = New("Frame", {
        Name = "Accessories",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromScale(0, 1),
        AutomaticSize = Enum.AutomaticSize.X,
        ZIndex = 3,
    }, row)
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    }, accessories)
    local label = Themed(Text(row, {
        Name = "Label",
        FontFace = FONT_MEDIUM,
        TextSize = 13,
        RichText = true,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2,
    }), { TextColor3 = "TextSecondary" })
    local W = container.W
    local function fit()
        label.Size = UDim2.new(1, -(accessories.AbsoluteSize.X / W.Scale.Scale) - 10, 1, 0)
    end
    accessories:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
    fit()
    return { Row = row, Label = label, Accessories = accessories }
end

local function attachAccessories(element, container, accessories)
    function element:AddKeyPicker(idx, info)
        Elements.KeyPicker(container, accessories, element, idx, info)
        return element
    end
    function element:AddColorPicker(idx, info)
        Elements.ColorPicker(container, accessories, element, idx, info)
        return element
    end
end

-------------------------------------------------------------------------------------------------------
-- Groupbox: a card with a header, a thin line of accent light beneath it, and the element stack.
-------------------------------------------------------------------------------------------------------
local function CardHeader(parent, title, icon)
    local header = New("Frame", {
        Name = "Header",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        LayoutOrder = 1,
    }, parent)
    local image = resolveIcon(icon)
    local textX = 14
    if image then
        Themed(New("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 1,
            Image = image,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 3,
        }, header), { ImageColor3 = "Accent" })
        textX = 22
    else
        local bead = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.fromOffset(4, 12),
            BorderSizePixel = 0,
            ZIndex = 3,
        }, header), { BackgroundColor3 = "Accent" })
        Corner(bead, 2)
    end
    local label = Themed(Text(header, {
        Text = title,
        TextSize = 13,
        Position = UDim2.fromOffset(textX, 0),
        Size = UDim2.new(1, -textX, 1, 0),
        ZIndex = 3,
    }), { TextColor3 = "TextPrimary" })

    local leak = Themed(New("Frame", {
        Name = "LightLeak",
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        LayoutOrder = 2,
    }, parent), { BackgroundColor3 = "Accent" })
    New("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.45, 0.75),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, leak)
    return header, label
end

-- The card is a bare decorated surface; everything that stacks lives in Body.
--
-- Keeping the layout off the card itself matters: CardMaterial's lensed edge is sized to the whole card,
-- and a UIListLayout on the card would treat that edge as a stacked item. Its height would then feed back
-- into the card's AutomaticSize, growing the card, which grows the edge, and so on until the card settles
-- hundreds of pixels tall with its content stranded inside.
local function newCard(column, name, order)
    local card = New("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = order,
    }, column)
    CardMaterial(card, L.CardRadius)
    local body = New("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, card)
    New("UIPadding", {
        PaddingTop = UDim.new(0, L.CardPadding),
        PaddingBottom = UDim.new(0, L.CardPadding + 2),
        PaddingLeft = UDim.new(0, L.CardPadding),
        PaddingRight = UDim.new(0, L.CardPadding),
    }, body)
    stackLayout(body, 9)
    return card, body
end

local function newGroupbox(W, column, title, icon, order)
    local card, body = newCard(column, "Groupbox_" .. title, order)
    CardHeader(body, title, icon)
    local content = New("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 3,
    }, body)
    stackLayout(content, L.ElementGap)
    local groupbox = newContainer(W, content)
    groupbox.Card = card
    groupbox.Name = title
    return groupbox
end

-------------------------------------------------------------------------------------------------------
-- Tabbox: a card whose header is a segmented glass track; a liquid lens slides between the segments.
-------------------------------------------------------------------------------------------------------
local function newTabbox(W, column, order)
    local card, body = newCard(column, "Tabbox", order)
    local track = New("Frame", {
        Name = "Segments",
        Size = UDim2.new(1, 0, 0, 30),
        LayoutOrder = 1,
    }, body)
    FieldMaterial(track, 9)

    local lensTrack = New("Frame", {
        Name = "Lens",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 3),
        Size = UDim2.new(0, 0, 1, -6),
        ZIndex = 3,
    }, track)
    local lensBody = GlassLens(lensTrack, 7, 3)
    local lens = LiquidMover(lensTrack, lensBody, {
        Axis = "X", Width = 0, Stiffness = 260, Damping = 0.8, MaxStretch = 16, StretchPerSpeed = 0.04,
        Squash = 2, PressX = 0, PressY = 0,
    })

    local tabbox = { Card = card, Tabs = {}, ActiveTab = nil, Name = "Tabbox" }

    local function segmentGeometry(index)
        local inner = track.AbsoluteSize.X / W.Scale.Scale - 6
        local width = inner / math.max(1, #tabbox.Tabs)
        return 3 + (index - 1) * width, width
    end

    local function relayout(instant)
        for i, tab in ipairs(tabbox.Tabs) do
            local x, width = segmentGeometry(i)
            tab.Button.Position = UDim2.fromOffset(x, 0)
            tab.Button.Size = UDim2.new(0, width, 1, 0)
        end
        local active = tabbox.ActiveTab
        if active then
            local x, width = segmentGeometry(table.find(tabbox.Tabs, active))
            lens.length = width
            lens:SetTarget(x)
            if instant then lens:Snap() end
        end
    end
    track:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() relayout(true) end)

    function tabbox:AddTab(name)
        local content = New("Frame", {
            Name = "Tab_" .. name,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 3,
            Visible = false,
        }, body)
        stackLayout(content, L.ElementGap)
        local tab = newContainer(W, content)
        tab.Name = name

        tab.Button = New("TextButton", {
            Name = name,
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            ZIndex = 4,
        }, track)
        tab.Label = Themed(Text(tab.Button, {
            Text = name,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 5,
        }), { TextColor3 = function() return tabbox.ActiveTab == tab and Glass.TextPrimary or Glass.TextMuted end })

        function tab:Show()
            if tabbox.ActiveTab == tab then return end
            tabbox.ActiveTab = tab
            playSound("Tab")
            for _, other in ipairs(tabbox.Tabs) do
                other.Frame.Visible = other == tab
                Tween(other.Label, Motion.Hover, { TextColor3 = other == tab and Glass.TextPrimary or Glass.TextMuted })
            end
            relayout(false)
        end
        tab.Button.MouseButton1Click:Connect(function() tab:Show() end)

        table.insert(tabbox.Tabs, tab)
        if not tabbox.ActiveTab then
            tabbox.ActiveTab = tab
            content.Visible = true
            tab.Label.TextColor3 = Glass.TextPrimary
        end
        relayout(true)
        return tab
    end

    return tabbox
end

-------------------------------------------------------------------------------------------------------
-- Dependency boxes: containers that only show while other elements hold given values.
-------------------------------------------------------------------------------------------------------
function Container:AddDependencyBox()
    local frame = New("Frame", {
        Name = "DependencyBox",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = self:NextOrder(),
    }, self.Frame)
    stackLayout(frame, L.ElementGap)
    local box = newContainer(self.W, frame)
    box.Dependencies = {}

    function box:SetupDependencies(dependencies)
        box.Dependencies = dependencies
        box:Update()
    end

    function box:Update()
        for _, dependency in ipairs(box.Dependencies) do
            local element, expected = dependency[1], dependency[2]
            if element and element.Value ~= expected then
                frame.Visible = false
                return
            end
        end
        frame.Visible = true
    end

    table.insert(Library.DependencyBoxes, box)
    return box
end

function Library:UpdateDependencyBoxes()
    for _, box in ipairs(self.DependencyBoxes) do box:Update() end
end

-------------------------------------------------------------------------------------------------------
-- Label
-------------------------------------------------------------------------------------------------------
function Container:AddLabel(first, second)
    local idx, info
    if typeof(first) == "table" then
        info = first
    elseif typeof(second) == "table" then
        idx, info = first, second
    else
        info = { Text = first, DoesWrap = second }
    end

    local Label = { Type = "Label", Text = info.Text or "" }
    local textInst
    if info.DoesWrap then
        textInst = Themed(Text(self.Frame, {
            Name = "Label",
            Text = Label.Text,
            FontFace = FONT_MEDIUM,
            TextSize = 13,
            RichText = true,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.None,
            TextYAlignment = Enum.TextYAlignment.Top,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LineHeight = 1.15,
            LayoutOrder = self:NextOrder(),
        }), { TextColor3 = "TextSecondary" })
        Label.Instance = textInst
    else
        local row = AccessoryRow(self, 22)
        textInst = row.Label
        textInst.Text = Label.Text
        Label.Instance = row.Row
        attachAccessories(Label, self, row.Accessories)
    end

    function Label:SetText(text)
        Label.Text = text
        textInst.Text = text
    end

    function Label:SetVisible(visible)
        Label.Instance.Visible = visible
    end

    if idx then Library.Labels[idx] = Label end
    return Label
end

-------------------------------------------------------------------------------------------------------
-- Divider: two hairlines drawing in toward a small glass diamond.
-------------------------------------------------------------------------------------------------------
function Container:AddDivider()
    local row = New("Frame", {
        Name = "Divider",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 10),
        LayoutOrder = self:NextOrder(),
    }, self.Frame)
    for side = 0, 1 do
        local line = Themed(New("Frame", {
            AnchorPoint = Vector2.new(side, 0.5),
            Position = UDim2.new(side, 0, 0.5, 0),
            Size = UDim2.new(0.5, -9, 0, 1),
            BackgroundTransparency = 0.55,
            BorderSizePixel = 0,
        }, row), { BackgroundColor3 = "Rim" })
        New("UIGradient", {
            Rotation = side == 0 and 0 or 180,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0.3),
            }),
        }, line)
    end
    local diamond = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(5, 5),
        Rotation = 45,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
    }, row), { BackgroundColor3 = "Accent" })
    Corner(diamond, 1)
end

-------------------------------------------------------------------------------------------------------
-- Button: a glass key. It dips under the finger, sends a pulse of light through itself, and a
-- DoubleClick button asks for a second press while a fuse burns down underneath.
-------------------------------------------------------------------------------------------------------
local CONFIRM_WINDOW = 1.6

function Container:AddButton(first, second)
    local info
    if typeof(first) == "table" then
        info = first
    elseif typeof(second) == "table" then
        info = second
    else
        info = { Text = first, Func = second }
    end

    local W = self.W
    local strip = New("Frame", {
        Name = "Buttons",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        LayoutOrder = self:NextOrder(),
    }, self.Frame)
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
    }, strip)

    local buttons = {}
    -- Width is shared between the buttons that are actually showing, so hiding one lets the rest
    -- expand to fill the strip instead of leaving a gap.
    local function relayout()
        local visible = {}
        for _, button in ipairs(buttons) do
            if button.Holder.Visible then table.insert(visible, button) end
        end
        local count = math.max(1, #visible)
        for _, button in ipairs(visible) do
            button.Holder.Size = UDim2.new(1 / count, -(8 * (count - 1)) / count, 1, 0)
        end
    end

    local function makeButton(buttonInfo)
        local Button = {
            Type = "Button",
            Text = buttonInfo.Text or "Button",
            Func = buttonInfo.Func or buttonInfo.Callback,
            Disabled = buttonInfo.Disabled == true,
            Risky = buttonInfo.Risky == true,
            DoubleClick = buttonInfo.DoubleClick == true,
            Tooltip = buttonInfo.Tooltip,
        }
        local tone = function() return Button.Risky and Glass.Danger or Glass.Rim end

        local holder = New("TextButton", {
            Name = "Button",
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            LayoutOrder = #buttons + 1,
            ClipsDescendants = false,
        }, strip)
        local scale = New("UIScale", { Scale = 1 }, holder)
        local body = Themed(New("Frame", {
            Name = "Body",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 0.9,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        }, holder), { BackgroundColor3 = "LensTint" })
        Corner(body, 9)
        New("UIGradient", {
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 0.5),
            }),
        }, body)
        local rim = Themed(New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Thickness = 1,
            Transparency = 0.55,
        }, body), { Color = tone })
        New("UIGradient", {
            Rotation = 100,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.05),
                NumberSequenceKeypoint.new(0.5, 0.7),
                NumberSequenceKeypoint.new(1, 0.3),
            }),
        }, rim)
        Specular(body, 18, 0.5, 3)

        local label = Themed(Text(body, {
            Text = Button.Text,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.new(1, -12, 1, 0),
            Position = UDim2.fromOffset(6, 0),
            ZIndex = 4,
        }), { TextColor3 = function() return Button.Risky and Glass.Danger or Glass.TextPrimary end })

        local fuse = Themed(New("Frame", {
            Name = "Fuse",
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(0, 0, 0, 2),
            BorderSizePixel = 0,
            ZIndex = 4,
        }, body), { BackgroundColor3 = "Warning" })

        local armedToken
        local function disarm()
            armedToken = nil
            label.Text = Button.Text
            Tween(label, Motion.Hover, { TextColor3 = Button.Risky and Glass.Danger or Glass.TextPrimary })
            Tween(fuse, Motion.FadeOut, { Size = UDim2.new(0, 0, 0, 2) })
        end

        local function paintDisabled()
            label.TextTransparency = Button.Disabled and 0.55 or 0
            rim.Transparency = Button.Disabled and 0.8 or 0.55
        end
        paintDisabled()

        holder.MouseEnter:Connect(function()
            if Button.Disabled then return end
            Tween(body, Motion.Hover, { BackgroundTransparency = 0.8 })
            Tween(rim, Motion.Hover, { Transparency = 0.3 })
            playSound("Hover")
        end)
        holder.MouseLeave:Connect(function()
            Tween(body, Motion.Hover, { BackgroundTransparency = 0.9 })
            Tween(rim, Motion.Hover, { Transparency = Button.Disabled and 0.8 or 0.55 })
            Tween(scale, Motion.Pop, { Scale = 1 })
        end)
        holder.MouseButton1Down:Connect(function()
            if Button.Disabled then return end
            Tween(scale, Motion.Press, { Scale = 0.965 })
        end)
        holder.MouseButton1Up:Connect(function() Tween(scale, Motion.Pop, { Scale = 1 }) end)
        holder.MouseButton1Click:Connect(function()
            if Button.Disabled then return end
            Pulse(body, 3)
            playSound(Button.Risky and "Close" or "Press")
            if Button.DoubleClick and not armedToken then
                local token = {}
                armedToken = token
                label.Text = "Click again to confirm"
                Tween(label, Motion.Hover, { TextColor3 = Glass.Warning })
                fuse.Size = UDim2.new(1, 0, 0, 2)
                Tween(fuse, TweenInfo.new(CONFIRM_WINDOW, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) })
                task.delay(CONFIRM_WINDOW, function()
                    if armedToken == token then disarm() end
                end)
                return
            end
            if armedToken then disarm() end
            Library:SafeCallback(Button.Func)
        end)
        bindTooltip(W, holder, function()
            if Button.Disabled and buttonInfo.DisabledTooltip then return buttonInfo.DisabledTooltip end
            return Button.Tooltip
        end)

        Button.Holder = holder
        function Button:SetText(text)
            Button.Text = text
            if not armedToken then label.Text = text end
        end
        function Button:SetDisabled(disabled)
            Button.Disabled = disabled
            paintDisabled()
        end
        function Button:SetVisible(visible)
            -- Buttons share one horizontal strip, so hiding a sub-button must not take its siblings
            -- with it; the strip itself only disappears once every button in it is hidden.
            holder.Visible = visible
            local anyVisible = false
            for _, other in ipairs(buttons) do
                if other.Holder.Visible then
                    anyVisible = true
                    break
                end
            end
            strip.Visible = anyVisible
            relayout()
        end
        function Button:AddButton(a, b)
            local subInfo = typeof(a) == "table" and a or (typeof(b) == "table" and b or { Text = a, Func = b })
            return makeButton(subInfo)
        end

        table.insert(buttons, Button)
        relayout()
        return Button
    end

    return makeButton(info)
end

-- ===== 11_toggle.lua =====
-------------------------------------------------------------------------------------------------------
-- Toggle: a liquid capsule. The knob is a drop of glass that stretches as it slides across and lands
-- with a small bounce; the track floods with accent light behind it. Checkbox mode draws a check mark
-- stroke by stroke inside an etched well.
-------------------------------------------------------------------------------------------------------
local CAPSULE_WIDTH, CAPSULE_HEIGHT, KNOB_SIZE = 40, 22, 16

function Container:AddToggle(idx, info)
    info = info or {}
    local W = self.W
    local row = AccessoryRow(self, 30)
    local Toggle = {
        Type = "Toggle",
        Value = info.Default == true,
        Text = info.Text or tostring(idx),
        Risky = info.Risky == true,
        Disabled = info.Disabled == true,
        Tooltip = info.Tooltip,
        Callback = info.Callback,
        Changed = nil,
    }
    local checkbox = info.Checkbox == true or Library.ForceCheckbox
    row.Label.Text = Toggle.Text

    local hit = New("TextButton", {
        Name = "Hitbox",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 1,
    }, row.Row)
    -- The hover plate has to stay inside the card's padding and be round enough to read as a lozenge:
    -- a plate as tall as the row with a small radius looks like a hard-edged square pasted behind the row,
    -- and one wider than the padding gets clipped square by the card's own rounded corner.
    local hover = Themed(New("Frame", {
        Name = "Hover",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 8, 1, 6),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 1,
    }, row.Row), { BackgroundColor3 = "LensTint" })
    Corner(hover, 12)

    Themed(row.Label, {
        TextColor3 = function()
            if Toggle.Risky then return Glass.Danger end
            return Toggle.Value and Glass.TextPrimary or Glass.TextSecondary
        end,
    })

    local render
    if checkbox then
        local box = New("Frame", {
            Name = "Checkbox",
            Size = UDim2.fromOffset(20, 20),
            LayoutOrder = 1000,
            ZIndex = 3,
        }, row.Accessories)
        FieldMaterial(box, 6)
        local fill = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 4,
        }, box), { BackgroundColor3 = "Accent" })
        Corner(fill, 6)
        local fillScale = New("UIScale", { Scale = 0.6 }, fill)
        local _, reveal = CheckGlyph(box, 5)

        render = function(instant)
            local on = Toggle.Value
            if instant then
                fill.BackgroundTransparency = on and 0 or 1
                fillScale.Scale = on and 1 or 0.6
            else
                Tween(fill, Motion.Hover, { BackgroundTransparency = on and 0 or 1 })
                Tween(fillScale, on and Motion.Pop or Motion.FadeOut, { Scale = on and 1 or 0.6 })
            end
            reveal(on, instant)
        end
    else
        local capsule = New("Frame", {
            Name = "Capsule",
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(CAPSULE_WIDTH, CAPSULE_HEIGHT),
            LayoutOrder = 1000,
            ZIndex = 3,
        }, row.Accessories)
        local glow = Themed(New("ImageLabel", {
            Name = "Glow",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, 26, 1, 22),
            BackgroundTransparency = 1,
            Image = Assets.Spark,
            ImageTransparency = 1,
            ZIndex = 2,
        }, capsule), { ImageColor3 = "Accent" })
        local track = New("Frame", { Name = "Track", Size = UDim2.fromScale(1, 1), ZIndex = 3 }, capsule)
        FieldMaterial(track, CAPSULE_HEIGHT / 2)
        local fill = New("Frame", {
            Name = "Fill",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 4,
        }, capsule)
        Corner(fill, CAPSULE_HEIGHT / 2)
        Themed(New("UIGradient", { Rotation = 8 }, fill), { Color = accentSequence })
        -- A diagonal gloss across the lit fill, and a soft top-lip shadow so it reads as a filled tube.
        local fillGloss = New("Frame", {
            Size = UDim2.fromScale(1, 0.5),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 5,
        }, fill)
        -- Must carry the capsule's own radius. ClipsDescendants on the fill clips to a rectangle, not to
        -- its rounded corner, so an unrounded gloss shows two hard square corners poking out of the top
        -- of the pill — which reads as a stray square plate sitting behind the toggle.
        Corner(fillGloss, CAPSULE_HEIGHT / 2)
        New("UIGradient", {
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.55),
                NumberSequenceKeypoint.new(1, 1),
            }),
        }, fillGloss)
        local knob = Themed(New("Frame", {
            Name = "Knob",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(KNOB_SIZE, KNOB_SIZE),
            BorderSizePixel = 0,
            ZIndex = 6,
        }, capsule), { BackgroundColor3 = "Knob" })
        Corner(knob, KNOB_SIZE / 2)
        New("UIGradient", {
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 0.12),
            }),
        }, knob)
        Themed(New("UIStroke", { Thickness = 1, Transparency = 0.55 }, knob), { Color = "Shadow" })

        -- The knob's shape comes from two springs: travel (0 = off, 1 = on) and press.
        local travel, travelVelocity, press = Toggle.Value and 1 or 0, 0, 0
        local function drawKnob()
            local stretch = math.min(8, math.abs(travelVelocity) * 1.6) + press * 5
            local width = KNOB_SIZE + stretch
            local height = KNOB_SIZE - math.min(3, stretch * 0.3)
            local inset = (CAPSULE_HEIGHT - KNOB_SIZE) / 2
            local left = inset + KNOB_SIZE / 2
            local right = CAPSULE_WIDTH - inset - KNOB_SIZE / 2
            local center = left + (right - left) * travel
            -- stretch toward the side the knob is heading, so it reads as being pulled across
            center += (travel > 0.5 and -1 or 1) * (width - KNOB_SIZE) / 2 * (press > 0.01 and 1 or 0)
            knob.Position = UDim2.fromOffset(center, CAPSULE_HEIGHT / 2)
            knob.Size = UDim2.fromOffset(width, height)
        end
        local travelSpring = Spring(520, 0.62, travel, function(value, velocity)
            travel, travelVelocity = value, velocity
            drawKnob()
        end, 0.002)
        local pressSpring = Spring(600, 0.7, 0, function(value)
            press = value
            drawKnob()
        end, 0.002)
        Toggle._press = pressSpring

        render = function(instant)
            local on = Toggle.Value
            if instant then
                travelSpring:Snap(on and 1 or 0)
                fill.BackgroundTransparency = on and 0 or 1
                fillGloss.BackgroundTransparency = on and 0 or 1
                glow.ImageTransparency = on and 0.5 or 1
            else
                travelSpring:Set(on and 1 or 0)
                Tween(fill, Motion.Hover, { BackgroundTransparency = on and 0 or 1 })
                Tween(fillGloss, Motion.Hover, { BackgroundTransparency = on and 0 or 1 })
                Tween(glow, Motion.Settle, { ImageTransparency = on and 0.5 or 1 })
            end
        end
    end

    local function paintDisabled()
        row.Label.TextTransparency = Toggle.Disabled and 0.5 or 0
    end

    hit.MouseEnter:Connect(function()
        if not Toggle.Disabled then
            Tween(hover, Motion.Hover, { BackgroundTransparency = 0.95 })
            playSound("Hover")
        end
    end)
    hit.MouseLeave:Connect(function()
        Tween(hover, Motion.Hover, { BackgroundTransparency = 1 })
        if Toggle._press then Toggle._press:Set(0) end
    end)
    hit.MouseButton1Down:Connect(function()
        if not Toggle.Disabled and Toggle._press then Toggle._press:Set(1) end
    end)
    hit.MouseButton1Up:Connect(function()
        if Toggle._press then Toggle._press:Set(0) end
    end)
    hit.MouseButton1Click:Connect(function()
        if Toggle.Disabled then return end
        Toggle:SetValue(not Toggle.Value)
        playSound(Toggle.Value and "ToggleOn" or "ToggleOff")
    end)
    -- Right-click pops the control out as its own satellite, so a HUD can be built from the controls
    -- actually being used. Pinning twice just re-deploys the pod that already exists.
    hit.MouseButton2Click:Connect(function()
        if Toggle.Disabled or not W.PinControl then return end
        W.PinControl({ Kind = "Toggle", Key = tostring(idx or Toggle.Text), Title = Toggle.Text, Object = Toggle })
    end)
    bindTooltip(W, hit, function()
        if Toggle.Disabled and info.DisabledTooltip then return info.DisabledTooltip end
        return Toggle.Tooltip
    end)

    function Toggle:SetValue(value)
        Toggle.Value = value == true
        render(false)
        Tween(row.Label, Motion.Hover, {
            TextColor3 = Toggle.Risky and Glass.Danger or (Toggle.Value and Glass.TextPrimary or Glass.TextSecondary),
        })
        Library:SafeCallback(Toggle.Callback, Toggle.Value)
        Library:SafeCallback(Toggle.Changed, Toggle.Value)
        Library:SafeCallback(Toggle.Mirror, Toggle.Value) -- a pinned satellite showing this toggle
        Library:UpdateDependencyBoxes()
    end

    function Toggle:OnChanged(callback)
        Toggle.Changed = callback
    end

    function Toggle:SetText(text)
        Toggle.Text = text
        row.Label.Text = text
    end

    function Toggle:SetDisabled(disabled)
        Toggle.Disabled = disabled
        paintDisabled()
    end

    function Toggle:SetVisible(visible)
        row.Row.Visible = visible
    end

    attachAccessories(Toggle, self, row.Accessories)
    render(true)
    paintDisabled()
    if info.Visible == false then row.Row.Visible = false end

    Toggle.Container = row.Row
    if idx then Library.Toggles[idx] = Toggle end
    return Toggle
end

function Container:AddCheckbox(idx, info)
    info = info or {}
    info.Checkbox = true
    return self:AddToggle(idx, info)
end

-- ===== 12_slider.lua =====
-------------------------------------------------------------------------------------------------------
-- Slider: a liquid level. Accent light fills an etched tube and pools in a soft glow at its surface; a
-- glass bead rides the surface, stretching as it's dragged, and a value bubble floats above it while
-- held. Small step counts get tick marks that light up as the level passes them.
-------------------------------------------------------------------------------------------------------
local SLIDER_TUBE_HEIGHT = 6
local SLIDER_BEAD = 14

function Container:AddSlider(idx, info)
    info = info or {}
    local W = self.W
    local Slider = {
        Type = "Slider",
        Min = info.Min or 0,
        Max = info.Max or 100,
        Rounding = info.Rounding or 0,
        Suffix = info.Suffix or "",
        Prefix = info.Prefix or "",
        Text = info.Text or tostring(idx),
        Compact = info.Compact == true,
        Disabled = info.Disabled == true,
        Tooltip = info.Tooltip,
        Callback = info.Callback,
        Changed = nil,
    }

    local compact = Slider.Compact
    local holder = New("Frame", {
        Name = "Slider",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, compact and 26 or 44),
        LayoutOrder = self:NextOrder(),
    }, self.Frame)

    local label = Themed(Text(holder, {
        Name = "Label",
        Text = Slider.Text,
        FontFace = FONT_MEDIUM,
        TextSize = 13,
        Size = compact and UDim2.new(0.36, 0, 1, 0) or UDim2.new(1, -90, 0, 18),
        ZIndex = 2,
    }), { TextColor3 = "TextSecondary" })

    -- Value chip
    local chip = Themed(New("Frame", {
        Name = "Value",
        AnchorPoint = Vector2.new(1, compact and 0.5 or 0),
        Position = compact and UDim2.new(1, 0, 0.5, 0) or UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, holder), { BackgroundColor3 = "LensTint" })
    Corner(chip, 9)
    New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, chip)
    local chipRim = Themed(New("UIStroke", { Thickness = 1, Transparency = 0.8 }, chip), { Color = "Rim" })
    local chipText = Themed(Text(chip, {
        Text = "",
        TextSize = 11,
        FontFace = FONT_BOLD,
        TextTruncate = Enum.TextTruncate.None,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromScale(0, 1),
        ZIndex = 3,
    }), { TextColor3 = "TextPrimary" })

    -- Tube area
    local area = New("Frame", {
        Name = "Area",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 1),
        Position = compact and UDim2.new(0.36, 8, 1, -4) or UDim2.new(0, 0, 1, 0),
        Size = compact and UDim2.new(0.64, -78, 0, 18) or UDim2.new(1, 0, 0, 20),
        ZIndex = 2,
    }, holder)
    local tube = New("Frame", {
        Name = "Tube",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, SLIDER_BEAD / 2, 0.5, 0),
        Size = UDim2.new(1, -SLIDER_BEAD, 0, SLIDER_TUBE_HEIGHT),
        ZIndex = 2,
    }, area)
    FieldMaterial(tube, SLIDER_TUBE_HEIGHT / 2)

    local fill = New("Frame", {
        Name = "Fill",
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Size = UDim2.fromScale(0, 1),
        ZIndex = 3,
    }, tube)
    Corner(fill, SLIDER_TUBE_HEIGHT / 2)
    -- The gradient is drawn across the whole tube's width and revealed by the fill's clip, so the colour
    -- ramp stays fixed as the level rises rather than squashing into the filled portion.
    local fillGradient = New("Frame", {
        Name = "Ramp",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 3,
    }, fill)
    -- Same trap as the toggle: the fill clips to a rectangle rather than to its rounded corner, so every
    -- opaque child inside it needs the tube's own radius or the level shows square ends.
    Corner(fillGradient, SLIDER_TUBE_HEIGHT / 2)
    Themed(New("UIGradient", {}, fillGradient), { Color = accentSequence })
    local fillGloss = New("Frame", {
        Size = UDim2.new(1, 0, 0.5, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
        ZIndex = 4,
    }, fillGradient)
    Corner(fillGloss, SLIDER_TUBE_HEIGHT / 2)
    New("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.4),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, fillGloss)

    local surfaceGlow = Themed(New("ImageLabel", {
        Name = "SurfaceGlow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(34, 22),
        BackgroundTransparency = 1,
        Image = Assets.Spark,
        ImageTransparency = 0.45,
        ZIndex = 4,
    }, tube), { ImageColor3 = "Accent" })

    -- Tick marks for coarse sliders
    local ticks = {}
    local steps = (Slider.Max - Slider.Min)
    if Slider.Rounding == 0 and steps >= 2 and steps <= 12 then
        for i = 0, steps do
            local pct = i / steps
            local tick = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(pct, 0, 0.5, 0),
                Size = UDim2.fromOffset(2, 2),
                BorderSizePixel = 0,
                ZIndex = 4,
            }, tube)
            Corner(tick, 1)
            table.insert(ticks, { Frame = tick, Pct = pct })
        end
    end

    local bead = Themed(New("Frame", {
        Name = "Bead",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(SLIDER_BEAD, SLIDER_BEAD),
        BorderSizePixel = 0,
        ZIndex = 6,
    }, tube), { BackgroundColor3 = "Knob" })
    Corner(bead, SLIDER_BEAD / 2)
    Themed(New("UIStroke", { Thickness = 1.5, Transparency = 0.1 }, bead), { Color = "Accent" })
    local beadCore = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(4, 4),
        BorderSizePixel = 0,
        ZIndex = 7,
    }, bead), { BackgroundColor3 = "Accent" })
    Corner(beadCore, 2)

    -- Floating value bubble
    local bubble = Themed(New("Frame", {
        Name = "Bubble",
        AnchorPoint = Vector2.new(0.5, 1),
        Size = UDim2.fromOffset(0, 20),
        AutomaticSize = Enum.AutomaticSize.X,
        BorderSizePixel = 0,
        ZIndex = 8,
    }, tube), { BackgroundColor3 = "Accent" })
    Corner(bubble, 6)
    New("UIPadding", { PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) }, bubble)
    local bubbleScale = New("UIScale", { Scale = 0 }, bubble)
    local bubbleText = Themed(Text(bubble, {
        Text = "",
        TextSize = 11,
        TextTruncate = Enum.TextTruncate.None,
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromScale(0, 1),
        ZIndex = 9,
    }), { TextColor3 = "Knob" })

    local hit = New("TextButton", {
        Name = "Hitbox",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, -6),
        Size = UDim2.new(1, 0, 1, 12),
        ZIndex = 10,
    }, area)

    local function round(value)
        local multiplier = 10 ^ Slider.Rounding
        return math.floor(value * multiplier + 0.5) / multiplier
    end

    local function format(value)
        local text = Slider.Rounding > 0 and string.format("%." .. Slider.Rounding .. "f", value) or tostring(math.floor(value + 0.5))
        return Slider.Prefix .. text .. Slider.Suffix
    end

    local function percentOf(value)
        if Slider.Max == Slider.Min then return 0 end
        return math.clamp((value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1)
    end

    -- The colour ramp spans the whole tube, so it only needs resizing when the tube does, not on every
    -- frame of the level's motion. This also keeps it right after a window resize; it used to stay at the
    -- old width until the slider next moved, leaving the fill's bare white showing past its end.
    local function fitRamp()
        fillGradient.Size = UDim2.new(0, math.max(1, tube.AbsoluteSize.X / W.Scale.Scale), 1, 0)
    end
    tube:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitRamp)
    fitRamp()

    -- Ticks only change when the level crosses one (or the theme has changed since they were painted).
    local paintTick = PropertyCache()

    local hovered, dragging = false, false
    local level, levelVelocity = 0, 0
    local function draw()
        local stretch = math.min(7, math.abs(levelVelocity) * 3)
        local size = SLIDER_BEAD + (dragging and 4 or (hovered and 2 or 0))
        fill.Size = UDim2.fromScale(level, 1)
        surfaceGlow.Position = UDim2.fromScale(level, 0.5)
        bead.Position = UDim2.fromScale(level, 0.5)
        bead.Size = UDim2.fromOffset(size + stretch, size - math.min(3, stretch * 0.35))
        bubble.Position = UDim2.new(level, 0, 0, -12)
        for _, tick in ipairs(ticks) do
            local lit = tick.Pct <= level + 0.001
            paintTick(tick.Frame, "BackgroundColor3", lit and Glass.Knob or Glass.Rim)
            paintTick(tick.Frame, "BackgroundTransparency", lit and 0.25 or 0.55)
        end
    end
    local levelSpring = Spring(420, 0.85, 0, function(value, velocity)
        level, levelVelocity = value, velocity
        draw()
    end, 0.0005)

    function Slider:SetValue(value)
        value = tonumber(value)
        if not value then return end
        value = round(math.clamp(value, Slider.Min, Slider.Max))
        local changed = value ~= Slider.Value
        Slider.Value = value
        chipText.Text = format(value)
        bubbleText.Text = format(value)
        levelSpring:Set(percentOf(value))
        if changed then
            if dragging then playSound("Tick") end -- a fine grain of glass per step while sliding
            Library:SafeCallback(Slider.Callback, value)
            Library:SafeCallback(Slider.Changed, value)
            Library:SafeCallback(Slider.Mirror, value) -- a pinned satellite showing this slider
            Library:UpdateDependencyBoxes()
        end
    end

    local function setFromScreenX(x)
        local left, width = tube.AbsolutePosition.X, tube.AbsoluteSize.X
        if width <= 0 then return end
        local pct = math.clamp((x - left) / width, 0, 1)
        Slider:SetValue(Slider.Min + (Slider.Max - Slider.Min) * pct)
    end

    local function setDragging(active)
        dragging = active
        playSound(active and "Press" or "ToggleOff")
        Tween(bubbleScale, active and Motion.Pop or Motion.FadeOut, { Scale = active and 1 or 0 })
        Tween(chipRim, Motion.Hover, { Transparency = active and 0.35 or 0.8 })
        draw()
    end

    hit.MouseEnter:Connect(function()
        hovered = true
        playSound("Hover")
        draw()
    end)
    hit.MouseButton2Click:Connect(function()
        if Slider.Disabled or not W.PinControl then return end
        W.PinControl({ Kind = "Slider", Key = tostring(idx or Slider.Text), Title = Slider.Text, Object = Slider })
    end)
    hit.MouseLeave:Connect(function()
        hovered = false
        draw()
    end)
    hit.InputBegan:Connect(function(input)
        if not isPointer(input) or Slider.Disabled then return end
        setDragging(true)
        setFromScreenX(input.Position.X)
        local moveConnection, endConnection
        moveConnection = UserInputService.InputChanged:Connect(function(changed)
            if isMove(changed) then setFromScreenX(changed.Position.X) end
        end)
        endConnection = input.Changed:Connect(function()
            if input.UserInputState ~= Enum.UserInputState.End then return end
            moveConnection:Disconnect()
            endConnection:Disconnect()
            setDragging(false)
        end)
    end)
    bindTooltip(W, hit, function()
        if Slider.Disabled and info.DisabledTooltip then return info.DisabledTooltip end
        return Slider.Tooltip
    end)

    function Slider:OnChanged(callback)
        Slider.Changed = callback
    end

    function Slider:SetMin(min)
        Slider.Min = min
        Slider:SetValue(Slider.Value)
    end

    function Slider:SetMax(max)
        Slider.Max = max
        Slider:SetValue(Slider.Value)
    end

    function Slider:SetText(text)
        Slider.Text = text
        label.Text = text
    end

    function Slider:SetDisabled(disabled)
        Slider.Disabled = disabled
        label.TextTransparency = disabled and 0.5 or 0
        chipText.TextTransparency = disabled and 0.5 or 0
    end

    function Slider:SetVisible(visible)
        holder.Visible = visible
    end

    local start = round(math.clamp(tonumber(info.Default) or Slider.Min, Slider.Min, Slider.Max))
    Slider.Value = start
    chipText.Text = format(start)
    bubbleText.Text = format(start)
    levelSpring:Snap(percentOf(start))
    Slider:SetDisabled(Slider.Disabled)
    if info.Visible == false then holder.Visible = false end

    if idx then Library.Options[idx] = Slider end
    return Slider
end

-- ===== 13_dropdown.lua =====
-------------------------------------------------------------------------------------------------------
-- Dropdown: an etched field that pours open into a glass drawer. A liquid lens follows the pointer from
-- item to item; single picks carry a bead of light, multi picks draw a check mark. Long lists get a
-- search field.
-------------------------------------------------------------------------------------------------------
local DROPDOWN_ITEM_HEIGHT = 28
local DROPDOWN_MAX_VISIBLE = 7
local DROPDOWN_SEARCH_AFTER = 8

function Container:AddDropdown(idx, info)
    info = info or {}
    local W = self.W
    local Dropdown = {
        Type = "Dropdown",
        Values = info.Values or {},
        Multi = info.Multi == true,
        AllowNull = info.AllowNull == true,
        SpecialType = info.SpecialType,
        Text = info.Text,
        Disabled = info.Disabled == true,
        Tooltip = info.Tooltip,
        Callback = info.Callback,
        Changed = nil,
    }
    Dropdown.Value = Dropdown.Multi and {} or nil

    -- Values may be an array, or a dictionary (key -> display text). Special types list live players/teams.
    local function entries()
        local list = {}
        if Dropdown.SpecialType == "Player" then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= Players.LocalPlayer or info.ExcludeLocalPlayer == false then
                    table.insert(list, { Key = player.Name, Label = player.DisplayName })
                end
            end
        elseif Dropdown.SpecialType == "Team" then
            for _, team in ipairs(service("Teams"):GetTeams()) do
                table.insert(list, { Key = team.Name, Label = team.Name })
            end
        elseif #Dropdown.Values > 0 then
            for _, value in ipairs(Dropdown.Values) do
                table.insert(list, { Key = value, Label = tostring(value) })
            end
        else
            local keys = {}
            for key in pairs(Dropdown.Values) do table.insert(keys, key) end
            table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
            for _, key in ipairs(keys) do
                table.insert(list, { Key = key, Label = tostring(Dropdown.Values[key]) })
            end
        end
        return list
    end

    local holder = New("Frame", {
        Name = "Dropdown",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, Dropdown.Text and 54 or 32),
        LayoutOrder = self:NextOrder(),
    }, self.Frame)

    local label
    if Dropdown.Text then
        label = Themed(Text(holder, {
            Text = Dropdown.Text,
            FontFace = FONT_MEDIUM,
            TextSize = 13,
            Size = UDim2.new(1, 0, 0, 18),
        }), { TextColor3 = "TextSecondary" })
    end

    local field = New("TextButton", {
        Name = "Field",
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 32),
        ZIndex = 2,
    }, holder)
    local fieldStroke = FieldMaterial(field, 9)

    local display = Text(field, {
        Text = "",
        FontFace = FONT_MEDIUM,
        TextSize = 13,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -60, 1, 0),
        ZIndex = 3,
    })
    local countBadge = Themed(New("Frame", {
        Name = "Count",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -30, 0.5, 0),
        Size = UDim2.fromOffset(18, 16),
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 3,
    }, field), { BackgroundColor3 = "Accent" })
    Corner(countBadge, 8)
    local countText = Themed(Text(countBadge, {
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 4,
    }), { TextColor3 = "Knob" })

    local chevron, chevronLines = Chevron(field, 3)
    chevron.Position = UDim2.new(1, -14, 0.5, 0)
    chevron.Rotation = 90
    for _, line in ipairs(chevronLines) do Themed(line, { BackgroundColor3 = "TextSecondary" }) end

    local function isSelected(key)
        if Dropdown.Multi then return Dropdown.Value[key] == true end
        return Dropdown.Value == key
    end

    local function refreshDisplay()
        local names = {}
        for _, entry in ipairs(entries()) do
            if isSelected(entry.Key) then table.insert(names, entry.Label) end
        end
        if #names == 0 then
            display.Text = info.Placeholder or "Select..."
            display.TextColor3 = Glass.TextMuted
        else
            display.Text = table.concat(names, ", ")
            display.TextColor3 = Glass.TextPrimary
        end
        countBadge.Visible = Dropdown.Multi and #names > 1
        countText.Text = tostring(#names)
    end
    Themed(display, { TextColor3 = function()
        return display.Text == (info.Placeholder or "Select...") and Glass.TextMuted or Glass.TextPrimary
    end })

    local function fire()
        refreshDisplay()
        Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
        Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
        Library:UpdateDependencyBoxes()
    end

    -------------------------------------------------------------------------------------------------
    -- Drawer
    -------------------------------------------------------------------------------------------------
    local open = false

    local function openDrawer()
        if open or Dropdown.Disabled then return end
        open = true
        local list = entries()
        local searchable = info.Searchable == true or #list > DROPDOWN_SEARCH_AFTER
        local searchHeight = searchable and 36 or 0
        local width = field.AbsoluteSize.X / W.Scale.Scale
        local listHeight = math.min(#list, DROPDOWN_MAX_VISIBLE) * DROPDOWN_ITEM_HEIGHT
        local height = 10 + searchHeight + math.max(listHeight, DROPDOWN_ITEM_HEIGHT)

        local panel = New("Frame", {
            Name = "DropdownDrawer",
            Size = UDim2.fromOffset(width, 0),
            ClipsDescendants = true,
            ZIndex = 1,
        }, nil)
        PopupMaterial(panel, 10, 40)
        W:PlacePopup(panel, field, 6, height)

        local search
        if searchable then
            local well = New("Frame", {
                Position = UDim2.fromOffset(6, 6),
                Size = UDim2.new(1, -12, 0, 28),
                ZIndex = 2,
            }, panel)
            FieldMaterial(well, 8)
            search = Themed(New("TextBox", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -20, 1, 0),
                Text = "",
                PlaceholderText = "Search",
                FontFace = FONT_MEDIUM,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                ZIndex = 3,
            }, well), { TextColor3 = "TextPrimary", PlaceholderColor3 = "TextMuted" })
        end

        local scroller = New("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, 5 + searchHeight),
            Size = UDim2.new(1, 0, 1, -(10 + searchHeight)),
            CanvasSize = UDim2.new(),
            ScrollBarThickness = 2,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ZIndex = 2,
        }, panel)
        Themed(scroller, { ScrollBarImageColor3 = "Accent" })

        local lensTrack = New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(6, 0),
            Size = UDim2.new(1, -12, 0, DROPDOWN_ITEM_HEIGHT),
            Visible = false,
            ZIndex = 2,
        }, scroller)
        local lensBody = GlassLens(lensTrack, 7, 2)
        local lens = LiquidMover(lensTrack, lensBody, Springs.ListLens)

        -- Rows are built only as they scroll into view, plus a couple either side. Opening a long list used
        -- to build every row at once (a multi-select row is ~18 instances) and each search keystroke rebuilt
        -- them all, a visible hitch on a slow device; the rows on screen come out exactly the same.
        local VIEW_HEIGHT = height - (10 + searchHeight)
        local rows, shown, built = {}, {}, {}

        local function buildRow(index)
            local entry = shown[index]
            local rowY = (index - 1) * DROPDOWN_ITEM_HEIGHT
            local item = New("TextButton", {
                Name = entry.Label,
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(6, rowY),
                Size = UDim2.new(1, -12, 0, DROPDOWN_ITEM_HEIGHT),
                ZIndex = 3,
            }, scroller)
            table.insert(rows, item)
            local itemLabel = Text(item, {
                Text = entry.Label,
                FontFace = FONT_MEDIUM,
                TextSize = 13,
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -40, 1, 0),
                TextColor3 = isSelected(entry.Key) and Glass.TextPrimary or Glass.TextSecondary,
                ZIndex = 4,
            })

            local mark, reveal
            if Dropdown.Multi then
                mark = New("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.fromOffset(16, 16),
                    ZIndex = 4,
                }, item)
                FieldMaterial(mark, 5)
                local markFill = New("Frame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = Glass.Accent,
                    BackgroundTransparency = isSelected(entry.Key) and 0 or 1,
                    BorderSizePixel = 0,
                    ZIndex = 5,
                }, mark)
                Corner(markFill, 5)
                local _, draw = CheckGlyph(mark, 6)
                draw(isSelected(entry.Key), true)
                reveal = function(on)
                    Tween(markFill, Motion.Hover, { BackgroundTransparency = on and 0 or 1 })
                    draw(on)
                end
            else
                mark = New("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -12, 0.5, 0),
                    Size = UDim2.fromOffset(6, 6),
                    BackgroundColor3 = Glass.Accent,
                    BackgroundTransparency = isSelected(entry.Key) and 0 or 1,
                    BorderSizePixel = 0,
                    ZIndex = 4,
                }, item)
                Corner(mark, 3)
                reveal = function(on) Tween(mark, Motion.Hover, { BackgroundTransparency = on and 0 or 1 }) end
            end

            item.MouseEnter:Connect(function()
                lensTrack.Visible = true
                lens:SetTarget(rowY)
                if not isSelected(entry.Key) then
                    Tween(itemLabel, Motion.Hover, { TextColor3 = Glass.TextPrimary })
                end
            end)
            item.MouseLeave:Connect(function()
                if not isSelected(entry.Key) then
                    Tween(itemLabel, Motion.Hover, { TextColor3 = Glass.TextSecondary })
                end
            end)
            item.MouseButton1Click:Connect(function()
                if Dropdown.Multi then
                    Dropdown.Value[entry.Key] = (not Dropdown.Value[entry.Key]) or nil
                    reveal(isSelected(entry.Key))
                    fire()
                else
                    if Dropdown.Value == entry.Key and Dropdown.AllowNull then
                        Dropdown.Value = nil
                    else
                        Dropdown.Value = entry.Key
                    end
                    fire()
                    W:ClosePopup()
                end
            end)
        end

        local function fillView()
            local maxTop = math.max(0, #shown * DROPDOWN_ITEM_HEIGHT - VIEW_HEIGHT)
            -- Clamped here too: after a filter shrinks the list the scroller may not have pulled its own
            -- position back in yet, and the rows that will be in view must exist before that happens.
            local top = math.clamp(scroller.CanvasPosition.Y, 0, maxTop)
            local first = math.max(1, math.floor(top / DROPDOWN_ITEM_HEIGHT) - 1)
            local last = math.min(#shown, math.ceil((top + VIEW_HEIGHT) / DROPDOWN_ITEM_HEIGHT) + 2)
            for index = first, last do
                if not built[index] then
                    built[index] = true
                    buildRow(index)
                end
            end
        end

        local function build(filter)
            for _, row in ipairs(rows) do row:Destroy() end
            table.clear(rows)
            table.clear(shown)
            table.clear(built)
            local needle = filter and filter ~= "" and filter:lower() or nil
            for _, entry in ipairs(list) do
                if not needle or entry.Label:lower():find(needle, 1, true) then
                    table.insert(shown, entry)
                    if isSelected(entry.Key) and not lensTrack.Visible then
                        lensTrack.Visible = true
                        lens:SetTarget((#shown - 1) * DROPDOWN_ITEM_HEIGHT)
                        lens:Snap()
                    end
                end
            end
            scroller.CanvasSize = UDim2.fromOffset(0, #shown * DROPDOWN_ITEM_HEIGHT)
            fillView()
        end
        scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(fillView)
        build(nil)
        if search then
            search:GetPropertyChangedSignal("Text"):Connect(function()
                lensTrack.Visible = false
                build(search.Text)
            end)
        end

        Tween(fieldStroke, Motion.Hover, { Transparency = 0.35 })
        Tween(chevron, Motion.Settle, { Rotation = -90 })
        W:OpenPopup(panel, function()
            open = false
            Tween(fieldStroke, Motion.Hover, { Transparency = 0.82 })
            Tween(chevron, Motion.Settle, { Rotation = 90 })
            Tween(panel, Motion.FadeOut, { Size = UDim2.fromOffset(width, 0) })
            task.delay(Motion.FadeOut.Time, function() panel:Destroy() end)
        end)
        Tween(panel, Motion.Reveal, { Size = UDim2.fromOffset(width, height) })
    end

    field.MouseButton1Click:Connect(function()
        if open then W:ClosePopup() else openDrawer() end
    end)
    field.MouseEnter:Connect(function()
        if not open then Tween(fieldStroke, Motion.Hover, { Transparency = 0.6 }) end
    end)
    field.MouseLeave:Connect(function()
        if not open then Tween(fieldStroke, Motion.Hover, { Transparency = 0.82 }) end
    end)
    bindTooltip(W, field, function()
        if Dropdown.Disabled and info.DisabledTooltip then return info.DisabledTooltip end
        return Dropdown.Tooltip
    end)

    -------------------------------------------------------------------------------------------------
    -- API
    -------------------------------------------------------------------------------------------------
    function Dropdown:SetValue(value)
        if Dropdown.Multi then
            local selected = {}
            if typeof(value) == "table" then
                for key, flag in pairs(value) do
                    if typeof(key) == "number" then
                        selected[flag] = true
                    elseif flag then
                        selected[key] = true
                    end
                end
            end
            Dropdown.Value = selected
        else
            Dropdown.Value = value
        end
        fire()
    end

    function Dropdown:SetValues(values)
        Dropdown.Values = values or {}
        -- Selections that no longer exist have to go, or the field keeps naming entries that are gone
        -- and GetActiveValues keeps reporting them. An open drawer is closed because its rows were
        -- built from the old list.
        local valid = {}
        for _, entry in ipairs(entries()) do valid[entry.Key] = true end
        if Dropdown.Multi then
            for key in pairs(Dropdown.Value) do
                if not valid[key] then Dropdown.Value[key] = nil end
            end
        elseif Dropdown.Value ~= nil and not valid[Dropdown.Value] then
            Dropdown.Value = nil
        end
        if open then W:ClosePopup() end
        refreshDisplay()
    end

    function Dropdown:GetActiveValues()
        if not Dropdown.Multi then return Dropdown.Value ~= nil and 1 or 0 end
        local active = {}
        for key in pairs(Dropdown.Value) do table.insert(active, key) end
        return active
    end

    function Dropdown:OnChanged(callback)
        Dropdown.Changed = callback
    end

    function Dropdown:SetText(text)
        Dropdown.Text = text
        if label then label.Text = text end
    end

    function Dropdown:SetDisabled(disabled)
        Dropdown.Disabled = disabled
        display.TextTransparency = disabled and 0.5 or 0
    end

    function Dropdown:SetVisible(visible)
        holder.Visible = visible
    end

    -- Defaults: an index into an array, a value, or for multi a set / array of values.
    local default = info.Default
    if Dropdown.Multi then
        if typeof(default) == "table" then
            for key, flag in pairs(default) do
                if typeof(key) == "number" then Dropdown.Value[flag] = true elseif flag then Dropdown.Value[key] = true end
            end
        end
    elseif typeof(default) == "number" and #Dropdown.Values > 0 and Dropdown.Values[default] ~= nil then
        Dropdown.Value = Dropdown.Values[default]
    elseif default ~= nil then
        Dropdown.Value = default
    end

    if Dropdown.SpecialType then
        local function refresh() refreshDisplay() end
        Library:GiveSignal(Players.PlayerAdded:Connect(refresh))
        Library:GiveSignal(Players.PlayerRemoving:Connect(refresh))
    end

    refreshDisplay()
    Dropdown:SetDisabled(Dropdown.Disabled)
    if info.Visible == false then holder.Visible = false end

    if idx then Library.Options[idx] = Dropdown end
    return Dropdown
end

-- ===== 14_input.lua =====
-------------------------------------------------------------------------------------------------------
-- Input: an etched glass field. Focusing it draws a line of accent light out from the centre along the
-- bottom lip and brightens the rim; a numeric field that's handed a letter shakes it off.
-------------------------------------------------------------------------------------------------------
function Container:AddInput(idx, info)
    info = info or {}
    local W = self.W
    local Input = {
        Type = "Input",
        Value = tostring(info.Default or ""),
        Numeric = info.Numeric == true,
        Finished = info.Finished == true,
        MaxLength = info.MaxLength,
        Text = info.Text,
        Disabled = info.Disabled == true,
        Tooltip = info.Tooltip,
        Callback = info.Callback,
        Changed = nil,
    }

    local holder = New("Frame", {
        Name = "Input",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, Input.Text and 56 or 34),
        LayoutOrder = self:NextOrder(),
    }, self.Frame)

    local label, counter
    if Input.Text then
        label = Themed(Text(holder, {
            Text = Input.Text,
            FontFace = FONT_MEDIUM,
            TextSize = 13,
            Size = UDim2.new(1, -50, 0, 18),
        }), { TextColor3 = "TextSecondary" })
    end
    if Input.MaxLength then
        counter = Themed(Text(holder, {
            TextSize = 11,
            FontFace = FONT_MEDIUM,
            TextXAlignment = Enum.TextXAlignment.Right,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.fromOffset(50, 18),
        }), { TextColor3 = "TextMuted" })
    end

    local field = New("Frame", {
        Name = "Field",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 34),
        ClipsDescendants = true,
        ZIndex = 2,
    }, holder)
    local fieldStroke = FieldMaterial(field, 9)

    local box = Themed(New("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -24, 1, 0),
        Text = Input.Value,
        PlaceholderText = info.Placeholder or "",
        FontFace = FONT_MEDIUM,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ClearTextOnFocus = info.ClearTextOnFocus == true,
        ZIndex = 3,
    }, field), { TextColor3 = "TextPrimary", PlaceholderColor3 = "TextMuted" })

    local focusLine = Themed(New("Frame", {
        Name = "FocusLine",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(0, 0, 0, 2),
        BorderSizePixel = 0,
        ZIndex = 4,
    }, field), { BackgroundColor3 = "Accent" })
    New("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.2, 0),
            NumberSequenceKeypoint.new(0.8, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, focusLine)
    local focusGlow = Themed(New("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(0.8, 0, 0, 22),
        BackgroundTransparency = 1,
        Image = Assets.Spark,
        ImageTransparency = 1,
        ZIndex = 3,
    }, field), { ImageColor3 = "Accent" })

    local function updateCounter()
        if counter then counter.Text = string.format("%d/%d", #box.Text, Input.MaxLength) end
    end

    local shakeToken = 0
    local function shake()
        shakeToken += 1
        local token = shakeToken
        for i, offset in ipairs({ -4, 4, -3, 2, 0 }) do
            task.delay((i - 1) * 0.04, function()
                -- Typing several rejected characters quickly starts overlapping shakes; without the
                -- token whichever step lands last wins and the field can be left parked off-centre.
                if token ~= shakeToken then return end
                field.Position = UDim2.new(0, offset, 1, 0)
            end)
        end
    end

    local function commit(text)
        Input.Value = text
        Library:SafeCallback(Input.Callback, text)
        Library:SafeCallback(Input.Changed, text)
        Library:UpdateDependencyBoxes()
    end

    local sanitizing = false
    box:GetPropertyChangedSignal("Text"):Connect(function()
        if sanitizing then return end
        local text = box.Text
        local clean = text
        if Input.Numeric then
            clean = clean:gsub("[^%d%.%-]", "")
        end
        if Input.MaxLength and #clean > Input.MaxLength then
            clean = clean:sub(1, Input.MaxLength)
        end
        if clean ~= text then
            sanitizing = true
            box.Text = clean
            sanitizing = false
            if Input.Numeric then shake() end
        end
        updateCounter()
        if not Input.Finished and clean ~= Input.Value then commit(clean) end
    end)

    box.Focused:Connect(function()
        Tween(focusLine, Motion.Settle, { Size = UDim2.new(1, 0, 0, 2) })
        Tween(focusGlow, Motion.Settle, { ImageTransparency = 0.7 })
        Tween(fieldStroke, Motion.Hover, { Transparency = 0.4 })
    end)
    box.FocusLost:Connect(function(enterPressed)
        Tween(focusLine, Motion.FadeOut, { Size = UDim2.new(0, 0, 0, 2) })
        Tween(focusGlow, Motion.FadeOut, { ImageTransparency = 1 })
        Tween(fieldStroke, Motion.Hover, { Transparency = 0.82 })
        if Input.Finished and enterPressed and box.Text ~= Input.Value then commit(box.Text) end
    end)
    bindTooltip(W, field, function()
        if Input.Disabled and info.DisabledTooltip then return info.DisabledTooltip end
        return Input.Tooltip
    end)

    function Input:SetValue(text)
        text = tostring(text or "")
        sanitizing = true
        box.Text = text
        sanitizing = false
        updateCounter()
        commit(text)
    end

    function Input:OnChanged(callback)
        Input.Changed = callback
    end

    function Input:SetText(text)
        Input.Text = text
        if label then label.Text = text end
    end

    function Input:SetDisabled(disabled)
        Input.Disabled = disabled
        box.TextEditable = not disabled
        box.TextTransparency = disabled and 0.5 or 0
    end

    function Input:SetVisible(visible)
        holder.Visible = visible
    end

    updateCounter()
    Input:SetDisabled(Input.Disabled)
    if info.Visible == false then holder.Visible = false end

    if idx then Library.Options[idx] = Input end
    return Input
end

-- ===== 15_keypicker.lua =====
-------------------------------------------------------------------------------------------------------
-- KeyPicker: a glass keycap that sits on a label or toggle. It dips when the bind fires, breathes
-- accent light while it's listening for a new key, and right-click opens its mode (Toggle/Hold/Always).
-- Active binds are listed in Library.KeybindFrame.
-------------------------------------------------------------------------------------------------------
local KeybindEntries = {}
local MOUSE_BIND_NAMES = {
    [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2",
    [Enum.UserInputType.MouseButton3] = "MB3",
}

local function inputBindName(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then return input.KeyCode.Name end
    return MOUSE_BIND_NAMES[input.UserInputType]
end

-- One row per listed bind, kept between updates and repainted in place. The list used to be torn down and
-- rebuilt on every keypress and every new keypicker, which made each press cost a handful of new
-- instances and building a script with many binds quadratic.
local keybindRows = {} -- picker -> { Row, State, Label, Mode }
local keybindDirty, keybindQueued = false, false

local function keybindRow(rows, picker)
    local existing = keybindRows[picker]
    if existing and existing.Row.Parent == rows then return existing end
    local row = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
    }, rows)
    local state = New("Frame", {
        Name = "State",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(6, 6),
        BorderSizePixel = 0,
    }, row)
    Corner(state, 3)
    local label = Text(row, {
        FontFace = FONT_MEDIUM,
        TextSize = 12,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -60, 1, 0),
    })
    local mode = Text(row, {
        FontFace = FONT_MEDIUM,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 50, 1, 0),
    })
    local entry = { Row = row, State = state, Label = label, Mode = mode, Paint = PropertyCache() }
    keybindRows[picker] = entry
    return entry
end

local function refreshKeybindFrame()
    keybindQueued = false
    local frame = Library.KeybindFrame
    if Library.Unloaded or not frame or not frame:FindFirstChild("Rows") then return end
    -- Hidden: nothing to show. The list is brought up to date the moment it is made visible.
    if not frame.Visible then
        keybindDirty = true
        return
    end
    keybindDirty = false
    local rows = frame.Rows
    local listed, order = {}, 0
    for _, picker in ipairs(KeybindEntries) do
        if not picker.NoUI and picker.Value ~= "None" then
            order += 1
            listed[picker] = true
            local active = picker:GetState()
            local entry = keybindRow(rows, picker)
            local paint = entry.Paint
            paint(entry.Row, "LayoutOrder", order)
            paint(entry.State, "BackgroundColor3", active and Glass.Accent or Glass.Glyph)
            paint(entry.State, "BackgroundTransparency", active and 0 or 0.6)
            paint(entry.Label, "Text", string.format("[%s]  %s", keyDisplayName(picker.Value), picker.Text))
            paint(entry.Label, "TextColor3", active and Glass.TextPrimary or Glass.TextSecondary)
            paint(entry.Mode, "Text", picker.Mode)
            paint(entry.Mode, "TextColor3", Glass.TextMuted)
        end
    end
    for picker, entry in pairs(keybindRows) do
        if not listed[picker] then
            entry.Row:Destroy()
            keybindRows[picker] = nil
        end
    end
end

-- Several things can ask for an update in one go (a bind firing also flips its toggle, which fires
-- again); they are folded into a single repaint before the frame is drawn.
function Library:UpdateKeybindFrame()
    if keybindQueued then return end
    keybindQueued = true
    task.defer(refreshKeybindFrame)
end

local function BuildKeybindFrame(screenGui)
    local frame = New("Frame", {
        Name = "Keybinds",
        Position = UDim2.new(0, 16, 0.4, 0),
        Size = UDim2.fromOffset(210, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 150,
    }, screenGui)
    PopupMaterial(frame, 12, 20)
    New("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
    }, frame)
    stackLayout(frame, 6)
    local title = Themed(Text(frame, {
        Text = "Keybinds",
        TextSize = 12,
        Size = UDim2.new(1, 0, 0, 18),
        LayoutOrder = 1,
    }), { TextColor3 = "TextPrimary" })
    title.Active = true
    local rows = New("Frame", {
        Name = "Rows",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2,
    }, frame)
    stackLayout(rows, 2)
    frame:GetPropertyChangedSignal("Visible"):Connect(function()
        if frame.Visible and keybindDirty then refreshKeybindFrame() end
    end)

    -- Drag by the title.
    title.InputBegan:Connect(function(input)
        if not isPointer(input) then return end
        local start, origin = input.Position, frame.Position
        local moveConnection, endConnection
        moveConnection = UserInputService.InputChanged:Connect(function(changed)
            if not isMove(changed) then return end
            local delta = changed.Position - start
            frame.Position = UDim2.new(origin.X.Scale, origin.X.Offset + delta.X, origin.Y.Scale, origin.Y.Offset + delta.Y)
        end)
        endConnection = input.Changed:Connect(function()
            if input.UserInputState ~= Enum.UserInputState.End then return end
            moveConnection:Disconnect()
            endConnection:Disconnect()
        end)
    end)
    return frame
end

Elements.KeyPicker = function(container, accessories, parent, idx, info)
    info = info or {}
    local W = container.W
    local default = info.Default
    if typeof(default) == "EnumItem" then default = default.Name end
    local KeyPicker = {
        Type = "KeyPicker",
        Value = default or "None",
        Mode = info.Mode or "Toggle",
        Modes = info.Modes or { "Always", "Toggle", "Hold" },
        Text = info.Text or (parent and parent.Text) or tostring(idx),
        NoUI = info.NoUI == true,
        SyncToggleState = info.SyncToggleState == true,
        Callback = info.Callback,
        ChangedCallback = info.ChangedCallback,
        Toggled = false,
        Changed = nil,
        Clicked = nil,
    }

    local cap = New("TextButton", {
        Name = "Keycap",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(34, 22),
        LayoutOrder = 500,
        ZIndex = 4,
    }, accessories)
    local base = Themed(New("Frame", {
        Name = "Depth",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        ZIndex = 4,
    }, cap), { BackgroundColor3 = "Shadow" })
    Corner(base, 6)
    local face = Themed(New("Frame", {
        Name = "Face",
        Size = UDim2.new(1, 0, 1, -3),
        BackgroundTransparency = 0.84,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, cap), { BackgroundColor3 = "LensTint" })
    Corner(face, 6)
    New("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.5),
        }),
    }, face)
    local faceStroke = Themed(New("UIStroke", { Thickness = 1, Transparency = 0.55 }, face), { Color = "Rim" })
    local capLabel = Themed(Text(face, {
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.None,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 6,
    }), { TextColor3 = "TextPrimary" })

    local listening, listenStart = false, 0
    local function showKey(text)
        capLabel.Text = text
        cap.Size = UDim2.fromOffset(math.max(34, textWidth(text, 11, Enum.Font.GothamBold) + 16), 22)
    end

    local function tap()
        Tween(face, Motion.Press, { Position = UDim2.fromOffset(0, 2) })
        task.delay(0.1, function() Tween(face, Motion.Pop, { Position = UDim2.fromOffset(0, 0) }) end)
    end

    function KeyPicker:GetState()
        if KeyPicker.Mode == "Always" then return true end
        if KeyPicker.SyncToggleState and parent and parent.Type == "Toggle" then return parent.Value end
        return KeyPicker.Toggled
    end

    local function fire(state)
        KeyPicker.Toggled = state
        if KeyPicker.SyncToggleState and parent and parent.Type == "Toggle" and parent.Value ~= state then
            parent:SetValue(state)
        end
        tap()
        Library:SafeCallback(KeyPicker.Callback, state)
        Library:SafeCallback(KeyPicker.Clicked, state)
        Library:UpdateKeybindFrame()
    end

    function KeyPicker:SetValue(data)
        local key, mode = data, nil
        if typeof(data) == "table" then key, mode = data[1], data[2] end
        if typeof(key) == "EnumItem" then key = key.Name end
        KeyPicker.Value = key or "None"
        if mode and table.find(KeyPicker.Modes, mode) then KeyPicker.Mode = mode end
        showKey(keyDisplayName(KeyPicker.Value))
        Library:SafeCallback(KeyPicker.ChangedCallback, KeyPicker.Value)
        Library:SafeCallback(KeyPicker.Changed, KeyPicker.Value)
        Library:UpdateKeybindFrame()
    end

    function KeyPicker:OnClick(callback) KeyPicker.Clicked = callback end
    function KeyPicker:OnChanged(callback) KeyPicker.Changed = callback end

    -- Listening: the rim breathes until a key or mouse button arrives. Escape cancels, Backspace clears.
    local breathe
    local function stopListening()
        listening = false
        if breathe then breathe:Cancel() end
        faceStroke.Transparency = 0.55
        faceStroke.Color = Glass.Rim
        showKey(keyDisplayName(KeyPicker.Value))
    end
    cap.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        listenStart = os.clock()
        showKey("...")
        faceStroke.Color = Glass.Accent
        breathe = TweenService:Create(faceStroke, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.05 })
        breathe:Play()
    end)

    -- Mode menu
    cap.MouseButton2Click:Connect(function()
        local width, rowHeight = 110, 26
        local height = 8 + #KeyPicker.Modes * rowHeight
        local panel = New("Frame", { Name = "ModeMenu", Size = UDim2.fromOffset(width, 0), ClipsDescendants = true }, nil)
        PopupMaterial(panel, 9, 30)
        W:PlacePopup(panel, cap, 6, height)
        for i, mode in ipairs(KeyPicker.Modes) do
            local item = New("TextButton", {
                Text = "",
                AutoButtonColor = false,
                BackgroundColor3 = Glass.LensTint,
                BackgroundTransparency = mode == KeyPicker.Mode and 0.86 or 1,
                Position = UDim2.fromOffset(4, 4 + (i - 1) * rowHeight),
                Size = UDim2.new(1, -8, 0, rowHeight),
                ZIndex = 2,
            }, panel)
            Corner(item, 6)
            Text(item, {
                Text = mode,
                FontFace = FONT_MEDIUM,
                TextSize = 12,
                TextColor3 = mode == KeyPicker.Mode and Glass.TextPrimary or Glass.TextSecondary,
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -20, 1, 0),
                ZIndex = 3,
            })
            item.MouseButton1Click:Connect(function()
                KeyPicker.Mode = mode
                KeyPicker.Toggled = false
                Library:UpdateKeybindFrame()
                W:ClosePopup()
            end)
        end
        W:OpenPopup(panel, function()
            Tween(panel, Motion.FadeOut, { Size = UDim2.fromOffset(width, 0) })
            task.delay(Motion.FadeOut.Time, function() panel:Destroy() end)
        end)
        Tween(panel, Motion.Reveal, { Size = UDim2.fromOffset(width, height) })
    end)

    Library:GiveSignal(UserInputService.InputBegan:Connect(function(input)
        local name = inputBindName(input)
        if not name then return end
        if listening then
            -- Left click is how the keycap was opened, so the opening click itself must be ignored, or
            -- every click in the UI would fire this keybind. A later left click means the user clicked
            -- away, which cancels instead of leaving the cap stuck on "..." forever. MB2/MB3 still bind.
            if name == "MB1" then
                if os.clock() - listenStart > 0.25 then stopListening() end
                return
            end
            if name == "Escape" then
                stopListening()
            elseif name == "Backspace" then
                stopListening()
                KeyPicker:SetValue({ "None", KeyPicker.Mode })
            else
                stopListening()
                KeyPicker:SetValue({ name, KeyPicker.Mode })
            end
            return
        end
        if UserInputService:GetFocusedTextBox() or name ~= KeyPicker.Value then return end
        if KeyPicker.Mode == "Toggle" then
            fire(not KeyPicker:GetState())
        elseif KeyPicker.Mode == "Hold" then
            fire(true)
        end
    end))
    Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
        if listening or KeyPicker.Mode ~= "Hold" then return end
        if inputBindName(input) == KeyPicker.Value then fire(false) end
    end))

    showKey(keyDisplayName(KeyPicker.Value))
    table.insert(KeybindEntries, KeyPicker)
    Library:UpdateKeybindFrame()
    if idx then Library.Options[idx] = KeyPicker end
    return KeyPicker
end

-- ===== 16_colorpicker.lua =====
-------------------------------------------------------------------------------------------------------
-- ColorPicker: a glossy colour orb. It opens a glass panel with a saturation/brightness field, a hue
-- rail, an optional transparency rail, and a hex field; the orb previews the colour live.
-------------------------------------------------------------------------------------------------------
local PICKER_WIDTH = 232
local PICKER_INNER = PICKER_WIDTH - 24
local PICKER_FIELD_HEIGHT = 140

local function hueSequence()
    local keypoints = {}
    for i = 0, 6 do
        table.insert(keypoints, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
    end
    return ColorSequence.new(keypoints)
end

local function railThumb(parent)
    local thumb = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(6, 18),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 5,
    }, parent)
    Corner(thumb, 3)
    New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0.5 }, thumb)
    return thumb
end

-- Drags a GUI region, reporting the pointer as 0..1 fractions of its width and height.
local function trackPointer(region, onMove)
    region.InputBegan:Connect(function(input)
        if not isPointer(input) then return end
        local function report(position)
            local topLeft, size = region.AbsolutePosition, region.AbsoluteSize
            onMove(
                math.clamp((position.X - topLeft.X) / math.max(1, size.X), 0, 1),
                math.clamp((position.Y - topLeft.Y) / math.max(1, size.Y), 0, 1)
            )
        end
        report(input.Position)
        local moveConnection, endConnection
        moveConnection = UserInputService.InputChanged:Connect(function(changed)
            if isMove(changed) then report(changed.Position) end
        end)
        endConnection = input.Changed:Connect(function()
            if input.UserInputState ~= Enum.UserInputState.End then return end
            moveConnection:Disconnect()
            endConnection:Disconnect()
        end)
    end)
end

Elements.ColorPicker = function(container, accessories, parent, idx, info)
    info = info or {}
    local W = container.W
    local ColorPicker = {
        Type = "ColorPicker",
        Value = info.Default or Color3.new(1, 1, 1),
        Transparency = info.Transparency,
        Title = info.Title or (parent and parent.Text) or tostring(idx),
        Callback = info.Callback,
        Changed = nil,
    }
    local hue, saturation, brightness = ColorPicker.Value:ToHSV()

    local orbButton = New("TextButton", {
        Name = "ColorOrb",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(22, 22),
        LayoutOrder = 600,
        ZIndex = 4,
    }, accessories)
    local orb = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = ColorPicker.Value,
        BorderSizePixel = 0,
        ZIndex = 4,
    }, orbButton)
    Corner(orb, 9)
    Themed(New("UIStroke", { Thickness = 1.5, Transparency = 0.35 }, orb), { Color = "Rim" })
    local gloss = New("Frame", {
        Size = UDim2.new(1, 0, 0.55, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 5,
    }, orb)
    Corner(gloss, 9)
    New("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.45),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, gloss)
    local orbScale = New("UIScale", { Scale = 1 }, orb)
    orbButton.MouseEnter:Connect(function() Tween(orbScale, Motion.Pop, { Scale = 1.12 }) end)
    orbButton.MouseLeave:Connect(function() Tween(orbScale, Motion.Pop, { Scale = 1 }) end)

    local panelRefs -- live widgets while the panel is open

    local function render()
        orb.BackgroundColor3 = ColorPicker.Value
        orb.BackgroundTransparency = ColorPicker.Transparency or 0
        if not panelRefs then return end
        panelRefs.Field.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        panelRefs.Cursor.Position = UDim2.fromScale(saturation, 1 - brightness)
        panelRefs.HueThumb.Position = UDim2.fromScale(hue, 0.5)
        panelRefs.Preview.BackgroundColor3 = ColorPicker.Value
        if panelRefs.AlphaThumb then
            panelRefs.AlphaThumb.Position = UDim2.fromScale(ColorPicker.Transparency or 0, 0.5)
            panelRefs.AlphaGradient.Color = ColorSequence.new(ColorPicker.Value)
        end
        if not panelRefs.Hex:IsFocused() then
            panelRefs.Hex.Text = "#" .. ColorPicker.Value:ToHex():upper()
        end
    end

    local function commit()
        ColorPicker.Value = Color3.fromHSV(hue, saturation, brightness)
        render()
        Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
        Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
    end

    local function openPanel()
        local hasAlpha = ColorPicker.Transparency ~= nil
        local height = 12 + 18 + 8 + PICKER_FIELD_HEIGHT + 12 + 12 + (hasAlpha and 22 or 0) + 12 + 30 + 12
        local panel = New("Frame", { Name = "ColorPanel", Size = UDim2.fromOffset(PICKER_WIDTH, 0), ClipsDescendants = true }, nil)
        PopupMaterial(panel, 12, 30)
        W:PlacePopup(panel, orbButton, 8, height)

        Themed(Text(panel, {
            Text = ColorPicker.Title,
            TextSize = 12,
            Position = UDim2.fromOffset(12, 12),
            Size = UDim2.new(1, -42, 0, 18),
            ZIndex = 2,
        }), { TextColor3 = "TextPrimary" })
        PopupClose(panel, W)

        local y = 38
        local field = New("Frame", {
            Position = UDim2.fromOffset(12, y),
            Size = UDim2.fromOffset(PICKER_INNER, PICKER_FIELD_HEIGHT),
            BorderSizePixel = 0,
            ZIndex = 2,
        }, panel)
        Corner(field, 8)
        local whiteWash = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3 }, field)
        Corner(whiteWash, 8)
        New("UIGradient", { Transparency = NumberSequence.new(0, 1) }, whiteWash)
        local blackWash = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 4 }, field)
        Corner(blackWash, 8)
        New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, blackWash)
        local cursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 1,
            ZIndex = 6,
        }, field)
        Corner(cursor, 7)
        New("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }, cursor)
        local cursorShade = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, 4, 1, 4),
            BackgroundTransparency = 1,
            ZIndex = 5,
        }, cursor)
        Corner(cursorShade, 9)
        New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0.6 }, cursorShade)
        y += PICKER_FIELD_HEIGHT + 12

        local hueRail = New("Frame", {
            Position = UDim2.fromOffset(12, y),
            Size = UDim2.fromOffset(PICKER_INNER, 12),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 2,
        }, panel)
        Corner(hueRail, 6)
        New("UIGradient", { Color = hueSequence() }, hueRail)
        local hueThumb = railThumb(hueRail)
        y += 12 + 10

        local alphaThumb, alphaGradient
        if hasAlpha then
            local alphaRail = New("Frame", {
                Position = UDim2.fromOffset(12, y),
                Size = UDim2.fromOffset(PICKER_INNER, 12),
                ZIndex = 2,
            }, panel)
            FieldMaterial(alphaRail, 6)
            local alphaFill = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3 }, alphaRail)
            Corner(alphaFill, 6)
            alphaGradient = New("UIGradient", { Color = ColorSequence.new(ColorPicker.Value), Transparency = NumberSequence.new(0, 1) }, alphaFill)
            alphaThumb = railThumb(alphaRail)
            trackPointer(alphaRail, function(x)
                ColorPicker.Transparency = x
                commit()
            end)
            y += 12 + 10
        end
        y += 2

        local preview = New("Frame", {
            Position = UDim2.fromOffset(12, y + 2),
            Size = UDim2.fromOffset(26, 26),
            BackgroundColor3 = ColorPicker.Value,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, panel)
        Corner(preview, 13)
        Themed(New("UIStroke", { Thickness = 1, Transparency = 0.4 }, preview), { Color = "Rim" })
        local hexWell = New("Frame", {
            Position = UDim2.fromOffset(46, y),
            Size = UDim2.fromOffset(PICKER_INNER - 34, 30),
            ZIndex = 2,
        }, panel)
        FieldMaterial(hexWell, 8)
        local hex = Themed(New("TextBox", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -20, 1, 0),
            FontFace = FONT_MONO,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            ZIndex = 3,
        }, hexWell), { TextColor3 = "TextPrimary" })
        hex.FocusLost:Connect(function()
            local ok, color = pcall(Color3.fromHex, (hex.Text:gsub("#", "")))
            if ok and color then
                hue, saturation, brightness = color:ToHSV()
                commit()
            else
                render()
            end
        end)

        panelRefs = {
            Field = field, Cursor = cursor, HueThumb = hueThumb, Preview = preview,
            AlphaThumb = alphaThumb, AlphaGradient = alphaGradient, Hex = hex,
        }
        trackPointer(field, function(x, fraction)
            saturation, brightness = x, 1 - fraction
            commit()
        end)
        trackPointer(hueRail, function(x)
            hue = x
            commit()
        end)
        render()

        W:OpenPopup(panel, function()
            panelRefs = nil
            Tween(panel, Motion.FadeOut, { Size = UDim2.fromOffset(PICKER_WIDTH, 0) })
            task.delay(Motion.FadeOut.Time, function() panel:Destroy() end)
        end)
        Tween(panel, Motion.Reveal, { Size = UDim2.fromOffset(PICKER_WIDTH, height) })
    end
    orbButton.MouseButton1Click:Connect(openPanel)
    ColorPicker.Open = openPanel

    function ColorPicker:SetValueRGB(color, transparency)
        hue, saturation, brightness = color:ToHSV()
        if transparency ~= nil then ColorPicker.Transparency = transparency end
        commit()
    end

    function ColorPicker:SetValue(hsv, transparency)
        hue, saturation, brightness = hsv[1], hsv[2], hsv[3]
        if transparency ~= nil then ColorPicker.Transparency = transparency end
        commit()
    end

    function ColorPicker:OnChanged(callback)
        ColorPicker.Changed = callback
    end

    render()
    if idx then Library.Options[idx] = ColorPicker end
    return ColorPicker
end

-- ===== 17_notify.lua =====
-------------------------------------------------------------------------------------------------------
-- Notifications: glass toasts that glide in from the notify side, carry a fuse of accent light that
-- burns down over their lifetime, then fold away. Toasts are short-lived, so they take the current
-- palette at creation instead of joining the theme registry.
-------------------------------------------------------------------------------------------------------
local NOTIFY_WIDTH = 292
local notifyStack, notifyGui

local function getNotifyStack()
    if notifyStack and notifyStack.Parent then return notifyStack end
    local gui = Library.ScreenGui
    if not gui then
        -- Kept in a file-local so Unload can destroy it. Notifying before CreateWindow (or after an
        -- unload) used to mint a fresh ScreenGui that nothing held a reference to, leaking one per call.
        if notifyGui and notifyGui.Parent then
            gui = notifyGui
        else
            gui = New("ScreenGui", { Name = "FishyUINotifications", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1001 }, nil)
            mountGui(gui)
            notifyGui = gui
        end
    end
    local right = Library.NotifySide ~= "Left"
    notifyStack = New("Frame", {
        Name = "Notifications",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(right and 1 or 0, 0),
        Position = UDim2.new(right and 1 or 0, right and -16 or 16, 0, GuiService:GetGuiInset().Y + 16),
        Size = UDim2.new(0, NOTIFY_WIDTH, 1, -32),
        ZIndex = 300,
    }, gui)
    New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = right and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left,
    }, notifyStack)
    return notifyStack
end

local notifyOrder = 0
function Library:Notify(info, duration)
    if typeof(info) ~= "table" then
        info = { Title = "", Description = tostring(info), Time = duration }
    end
    local lifetime = tonumber(info.Time or duration) or 4
    self:Log(info.Title ~= nil and info.Title ~= "" and info.Title or info.Description)
    local stack = getNotifyStack()
    local fromRight = self.NotifySide ~= "Left"
    notifyOrder += 1

    local slot = New("Frame", {
        Name = "Toast",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        LayoutOrder = notifyOrder,
    }, stack)
    local toast = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.fromOffset(fromRight and NOTIFY_WIDTH + 40 or -(NOTIFY_WIDTH + 40), 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = math.min(Glass.PaneTransparency, 0.08),
        BorderSizePixel = 0,
        ZIndex = 2,
    }, slot)
    Corner(toast, 12)
    New("UIGradient", { Rotation = 115, Color = paneGradientColor() }, toast)
    New("UIStroke", { Color = Glass.Rim, Transparency = Glass.BorderTransparency, Thickness = 1 }, toast)
    -- The accent bar is placed freely on the toast; the text stacks inside its own padded body.
    local bar = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0),
        Size = UDim2.new(0, 3, 1, -22),
        BackgroundColor3 = Glass.Accent,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, toast)
    Corner(bar, 2)

    local body = New("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 3,
    }, toast)
    New("UIPadding", {
        PaddingTop = UDim.new(0, 11),
        PaddingBottom = UDim.new(0, 13),
        PaddingLeft = UDim.new(0, 20),
        PaddingRight = UDim.new(0, 14),
    }, body)
    New("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, body)

    if info.Title and info.Title ~= "" then
        Text(body, {
            Text = info.Title,
            TextSize = 13,
            TextColor3 = Glass.TextPrimary,
            Size = UDim2.new(1, 0, 0, 18),
            LayoutOrder = 1,
            ZIndex = 3,
        })
    end
    if info.Description and info.Description ~= "" then
        Text(body, {
            Text = info.Description,
            FontFace = FONT_MEDIUM,
            TextSize = 12,
            RichText = true,
            TextColor3 = Glass.TextSecondary,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.None,
            TextYAlignment = Enum.TextYAlignment.Top,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2,
            ZIndex = 3,
        })
    end
    local fuse = New("Frame", {
        Name = "Fuse",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = Glass.Accent,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        ZIndex = 4,
    }, slot)
    Corner(fuse, 1)

    local closed = false
    local notification = {}
    function notification:Destroy()
        if closed then return end
        closed = true
        Tween(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.fromOffset(fromRight and NOTIFY_WIDTH + 40 or -(NOTIFY_WIDTH + 40), 0),
        })
        Tween(fuse, Motion.FadeOut, { BackgroundTransparency = 1 })
        task.delay(0.22, function()
            Tween(slot, Motion.Reveal, { Size = UDim2.new(1, 0, 0, 0) })
            task.delay(Motion.Reveal.Time, function() slot:Destroy() end)
        end)
    end

    task.defer(function()
        if closed then return end
        local height = toast.AbsoluteSize.Y
        Tween(slot, Motion.Reveal, { Size = UDim2.new(1, 0, 0, height) })
        Tween(toast, Motion.Drop, { Position = UDim2.fromOffset(0, 0) })
        Tween(fuse, TweenInfo.new(lifetime, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) })
        task.delay(lifetime, function() notification:Destroy() end)
    end)
    return notification
end

function Library:SetNotifySide(side)
    self.NotifySide = side
    if notifyStack then
        notifyStack:Destroy()
        notifyStack = nil
    end
end

-- ===== 18_palette.lua =====
-------------------------------------------------------------------------------------------------------
-- Palette: the accent gradient editor.
--
-- A preview card at the top shows the gradient the way the interface will wear it (a toggle, a slider, a
-- checkbox, a meter), sitting in a glow of its own colours. Beneath it, the gradient track carries a glass
-- knob for every stop: drag a knob to slide its stop, click to select it, right-click to remove it, or
-- click empty track to drop a new stop there. The selected stop is recoloured with the shade square, the
-- hue rail or the hex field and placed exactly with the position field; the segmented control adds,
-- removes, flips or evenly spaces stops, and a preset replaces the whole ramp.
--
-- Endpoints stay pinned at 0 and 1 so the ColorSequence is always valid. Every edit recolours the whole
-- interface live through Library:SetAccentGradient.
-------------------------------------------------------------------------------------------------------
local PALETTE_WIDTH = 360
local PALETTE_MAX_STOPS = 8
local PALETTE_KNOB = 22

-- Sorted stops -> a valid ColorSequence (endpoints pinned; equal times nudged apart).
local function stopsToSequence(stops)
    local ordered = table.clone(stops)
    table.sort(ordered, function(a, b) return a.position < b.position end)
    local keypoints, last = {}, -1
    for i, stop in ipairs(ordered) do
        local time = i == 1 and 0 or (i == #ordered and 1 or math.clamp(stop.position, 0, 1))
        time = math.clamp(time, math.min(1, last + 0.001), 1)
        last = time
        table.insert(keypoints, ColorSequenceKeypoint.new(time, stop.color))
    end
    return ColorSequence.new(keypoints)
end

local function sequenceToStops(sequence)
    local stops = {}
    for _, keypoint in ipairs(sequence.Keypoints) do
        table.insert(stops, { color = keypoint.Value, position = keypoint.Time })
    end
    return stops
end

local function toHex(color)
    return string.format("%02X%02X%02X",
        math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
end

local function fromHex(text)
    local hex = tostring(text):gsub("#", ""):gsub("%s", "")
    if #hex == 3 then
        hex = hex:sub(1, 1):rep(2) .. hex:sub(2, 2):rep(2) .. hex:sub(3, 3):rep(2)
    end
    if #hex ~= 6 or hex:match("[^0-9a-fA-F]") then return nil end
    return Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
end

-- Ramps offered as one-tap starting points. Each is a plain list of colours, spread evenly.
local PALETTE_PRESETS = {
    { Name = "Violet", Colors = { Color3.fromRGB(126, 66, 245), Color3.fromRGB(214, 150, 255) } },
    { Name = "Ocean", Colors = { Color3.fromRGB(28, 108, 222), Color3.fromRGB(72, 214, 236) } },
    { Name = "Mint", Colors = { Color3.fromRGB(24, 178, 134), Color3.fromRGB(150, 255, 208) } },
    { Name = "Aurora", Colors = { Color3.fromRGB(0, 196, 166), Color3.fromRGB(120, 236, 196), Color3.fromRGB(160, 110, 255) } },
    { Name = "Sunset", Colors = { Color3.fromRGB(255, 94, 91), Color3.fromRGB(255, 176, 84), Color3.fromRGB(255, 231, 142) } },
    { Name = "Candy", Colors = { Color3.fromRGB(255, 92, 170), Color3.fromRGB(168, 120, 255), Color3.fromRGB(96, 214, 255) } },
    { Name = "Neon", Colors = { Color3.fromRGB(72, 236, 255), Color3.fromRGB(255, 72, 192) } },
    { Name = "Mono", Colors = { Color3.fromRGB(72, 72, 82), Color3.fromRGB(240, 240, 248) } },
}

local function presetSequence(colors)
    local keypoints = {}
    for i, color in ipairs(colors) do
        table.insert(keypoints, ColorSequenceKeypoint.new((i - 1) / math.max(1, #colors - 1), color))
    end
    return ColorSequence.new(keypoints)
end

-- A small painter's-palette glyph (blob, thumb notch, three dabs) for the header button. Kept low
-- contrast so it reads as an icon rather than a bright plate stuck on the glass.
local function PaletteGlyph(parent, size, zIndex)
    local blob = Themed(New("Frame", {
        Name = "PaletteGlyph",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(size, size * 0.84),
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
        ZIndex = zIndex,
    }, parent), { BackgroundColor3 = "TextPrimary" })
    New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, blob)
    local notch = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.72, 0.68),
        Size = UDim2.fromOffset(size * 0.26, size * 0.26),
        BorderSizePixel = 0,
        ZIndex = zIndex + 1,
    }, blob), { BackgroundColor3 = "PaneMid" })
    New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, notch)
    for i, spot in ipairs({ { 0.3, 0.36 }, { 0.54, 0.27 }, { 0.76, 0.4 } }) do
        local dab = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(spot[1], spot[2]),
            Size = UDim2.fromOffset(size * 0.22, size * 0.22),
            BorderSizePixel = 0,
            ZIndex = zIndex + 1,
        }, blob), { BackgroundColor3 = ({ "Accent", "Warning", "AccentDeep" })[i] })
        New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, dab)
    end
    return blob
end

-- The soft top-half sheen every gradient surface in the palette carries, so it reads as lit glass.
local function paletteGloss(parent, radius, zIndex, strength)
    local sheen = New("Frame", {
        Name = "Gloss",
        Size = UDim2.fromScale(1, 0.55),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = zIndex,
    }, parent)
    Corner(sheen, radius)
    New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(strength or 0.55, 1) }, sheen)
    return sheen
end

-- A glass knob: a softly shaded white ring around a colour well, lifted by a small drop shadow. The stop
-- handles and the hue thumb share it.
local function paletteKnob(parent, size, zIndex)
    local holder = New("Frame", {
        Name = "Knob",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        ZIndex = zIndex,
    }, parent)
    local drop = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 1.5),
        Size = UDim2.fromOffset(size + 2, size + 2),
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        ZIndex = zIndex,
    }, holder), { BackgroundColor3 = "Shadow" })
    Corner(drop, size)
    local ring = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(size, size),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = zIndex + 1,
    }, holder)
    Corner(ring, size)
    New("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(214, 220, 232)) }, ring)
    local well = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(size - 8, size - 8),
        BorderSizePixel = 0,
        ZIndex = zIndex + 2,
    }, holder)
    Corner(well, size)
    New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0.8 }, well)
    return holder, well
end

-- Opens the editor near `anchor`. `stops` is the working set (mutated); `onLive(sequence)` fires on every
-- change; `onReset()` reseeds from the theme.
local function openPaletteEditor(W, anchor, stops, onLive, onReset)
    -- Derived rather than hardcoded so the panel stays consistent when a block is resized. The whole
    -- thing has to clear the 400px minimum window height, since a popup taller than the window would
    -- hang off the bottom no matter where it is anchored.
    local PAD = 14
    local INNER = PALETTE_WIDTH - PAD * 2
    local HERO_Y, HERO_H = 40, 52
    local TRACK_Y, TRACK_H = HERO_Y + HERO_H + 21, 16
    local EDIT_Y = TRACK_Y + TRACK_H + 21
    -- The track is inset by half a knob, so the end knobs line up with the edges of everything else.
    local TRACK_X, TRACK_W = PAD + PALETTE_KNOB / 2, INNER - PALETTE_KNOB
    local SB = 96
    local RIGHT_X = PAD + SB + 14
    local RIGHT_W = PALETTE_WIDTH - PAD - RIGHT_X
    local POSITION_W = 76
    local PRESET_LABEL_Y = EDIT_Y + SB + 14
    local PRESET_Y, PRESET_H = PRESET_LABEL_Y + 16, 22
    local FOOTER_Y, FOOTER_H = PRESET_Y + PRESET_H + 14, 30
    local editorHeight = FOOTER_Y + FOOTER_H + 14

    local selected = stops[1]
    local render -- defined once every widget it touches exists
    local put = PropertyCache()
    local liveGradients = {} -- every UIGradient that shows the ramp being edited

    local function live(parent, rotation)
        local gradient = New("UIGradient", { Rotation = rotation or 0 }, parent)
        table.insert(liveGradients, gradient)
        return gradient
    end

    local panel = New("Frame", { Name = "PalettePanel", Size = UDim2.fromOffset(PALETTE_WIDTH, 0), ClipsDescendants = true }, nil)
    PopupMaterial(panel, 14, 40)
    W:PlacePopup(panel, anchor, 8, editorHeight)

    Themed(Text(panel, {
        Text = "Gradient",
        TextSize = 13,
        Position = UDim2.fromOffset(PAD, 12),
        Size = UDim2.new(1, -150, 0, 18),
        ZIndex = 2,
    }), { TextColor3 = "TextPrimary" })
    local countLabel = Themed(Text(panel, {
        Text = "",
        FontFace = FONT_MEDIUM,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -38, 0, 12),
        Size = UDim2.fromOffset(130, 18),
        ZIndex = 2,
    }), { TextColor3 = "TextMuted" })
    PopupClose(panel, W)

    ---------------------------------------------------------------------------------------------------
    -- Preview: the ramp worn by a toggle, a slider, a checkbox and a meter, glowing in its own colours.
    ---------------------------------------------------------------------------------------------------
    local HALO = 10
    live(New("ImageLabel", {
        Name = "Halo",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(PAD + INNER / 2, HERO_Y + HERO_H / 2),
        Size = UDim2.fromOffset(INNER + HALO * 2, HERO_H + HALO * 2),
        BackgroundTransparency = 1,
        Image = Assets.GlassGlow,
        ImageColor3 = Color3.new(1, 1, 1),
        ImageTransparency = 0.45,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(50, 50, 78, 78),
        SliceScale = HALO / L.GlowRingInset,
        ZIndex = 2,
    }, panel))

    local hero = Themed(New("Frame", {
        Name = "Preview",
        Position = UDim2.fromOffset(PAD, HERO_Y),
        Size = UDim2.fromOffset(INNER, HERO_H),
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, panel), { BackgroundColor3 = "PaneBottom" })
    Corner(hero, 12)
    New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0, 0.3) }, hero)
    Themed(New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1, Transparency = 0.7 }, hero), { Color = "Rim" })
    Specular(hero, 48, 0.55, 9)

    -- Toggle, switched on
    local capsule = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 14, 0.5, 0),
        Size = UDim2.fromOffset(40, 22),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 4,
    }, hero)
    Corner(capsule, 11)
    live(capsule, 8)
    paletteGloss(capsule, 11, 5)
    local capsuleKnob = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -11, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        BorderSizePixel = 0,
        ZIndex = 6,
    }, capsule), { BackgroundColor3 = "Knob" })
    Corner(capsuleKnob, 8)
    Themed(New("UIStroke", { Thickness = 1, Transparency = 0.55 }, capsuleKnob), { Color = "Shadow" })

    -- Slider, two-thirds full, with the glow pooled at its surface
    local LEVEL, TUBE_W = 0.68, 122
    local tube = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 70, 0.5, 0),
        Size = UDim2.fromOffset(TUBE_W, 6),
        ZIndex = 4,
    }, hero)
    FieldMaterial(tube, 3)
    local tubeFill = New("Frame", {
        Size = UDim2.fromScale(LEVEL, 1),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 5,
    }, tube)
    local tubeRamp = New("Frame", {
        Size = UDim2.fromOffset(TUBE_W, 6),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 5,
    }, tubeFill)
    Corner(tubeRamp, 3)
    live(tubeRamp)
    local beadGlow = New("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(LEVEL, 0.5),
        Size = UDim2.fromOffset(32, 22),
        BackgroundTransparency = 1,
        Image = Assets.Spark,
        ImageTransparency = 0.4,
        ZIndex = 6,
    }, tube)
    local bead = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(LEVEL, 0.5),
        Size = UDim2.fromOffset(13, 13),
        BorderSizePixel = 0,
        ZIndex = 7,
    }, tube), { BackgroundColor3 = "Knob" })
    Corner(bead, 7)
    local beadRing = New("UIStroke", { Thickness = 1.5, Transparency = 0.05 }, bead)

    -- Checkbox, ticked
    local check = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 210, 0.5, 0),
        Size = UDim2.fromOffset(20, 20),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 4,
    }, hero)
    Corner(check, 6)
    live(check, 45)
    local _, drawCheck = CheckGlyph(check, 5)
    drawCheck(true, true)

    -- Meter: bars coloured from across the ramp, left to right
    local meterBars = {}
    for i, height in ipairs({ 12, 22, 30, 18, 26 }) do
        local bar = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 250 + (i - 1) * 14, 0.5, 15),
            Size = UDim2.fromOffset(8, height),
            BorderSizePixel = 0,
            ZIndex = 4,
        }, hero)
        Corner(bar, 3)
        paletteGloss(bar, 3, 5, 0.6)
        meterBars[i] = bar
    end

    ---------------------------------------------------------------------------------------------------
    -- The gradient track, with a glass knob riding it for every stop.
    ---------------------------------------------------------------------------------------------------
    local track = New("TextButton", {
        Name = "Track",
        Text = "",
        AutoButtonColor = false,
        Position = UDim2.fromOffset(TRACK_X, TRACK_Y),
        Size = UDim2.fromOffset(TRACK_W, TRACK_H),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 3,
    }, panel)
    Corner(track, TRACK_H / 2)
    live(track)
    paletteGloss(track, TRACK_H / 2, 4, 0.6)
    Themed(New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1, Transparency = 0.5 }, track), { Color = "Rim" })
    local knobLayer = New("Frame", {
        Name = "Stops",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(TRACK_X, TRACK_Y),
        Size = UDim2.fromOffset(TRACK_W, TRACK_H),
        ZIndex = 6,
    }, panel)

    ---------------------------------------------------------------------------------------------------
    -- Shade square, hue rail, hex and position fields, and the stop actions.
    ---------------------------------------------------------------------------------------------------
    local sb = New("Frame", {
        Position = UDim2.fromOffset(PAD, EDIT_Y),
        Size = UDim2.fromOffset(SB, SB),
        BorderSizePixel = 0,
        ZIndex = 3,
    }, panel)
    Corner(sb, 10)
    local sbWhite = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 4 }, sb)
    Corner(sbWhite, 10)
    New("UIGradient", { Transparency = NumberSequence.new(0, 1) }, sbWhite)
    local sbBlack = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 5 }, sb)
    Corner(sbBlack, 10)
    New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, sbBlack)
    Themed(New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1, Transparency = 0.55 }, sb), { Color = "Rim" })
    local sbCursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(15, 15),
        BorderSizePixel = 0,
        ZIndex = 7,
    }, sb)
    Corner(sbCursor, 8)
    New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Color3.new(1, 1, 1), Thickness = 2.5 }, sbCursor)
    local sbCursorShade = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(21, 21),
        BackgroundTransparency = 1,
        ZIndex = 7,
    }, sbCursor)
    Corner(sbCursorShade, 11)
    New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0.55 }, sbCursorShade)

    local hueRail = New("Frame", {
        Position = UDim2.fromOffset(RIGHT_X, EDIT_Y + 1),
        Size = UDim2.fromOffset(RIGHT_W, 14),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 3,
    }, panel)
    Corner(hueRail, 7)
    New("UIGradient", { Color = hueSequence() }, hueRail)
    Themed(New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1, Transparency = 0.6 }, hueRail), { Color = "Rim" })
    local hueThumb, hueWell = paletteKnob(hueRail, 18, 5)

    local ROW_Y = EDIT_Y + 26
    local hexWell = New("Frame", {
        Position = UDim2.fromOffset(RIGHT_X, ROW_Y),
        Size = UDim2.fromOffset(RIGHT_W - POSITION_W - 6, 28),
        ZIndex = 3,
    }, panel)
    FieldMaterial(hexWell, 8)
    local hexSwatch = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BorderSizePixel = 0,
        ZIndex = 4,
    }, hexWell)
    Corner(hexSwatch, 7)
    Themed(New("UIStroke", { Thickness = 1, Transparency = 0.45 }, hexSwatch), { Color = "Rim" })
    Themed(Text(hexWell, {
        Text = "#",
        FontFace = FONT_MONO,
        TextSize = 12,
        Position = UDim2.fromOffset(28, 0),
        Size = UDim2.new(0, 10, 1, 0),
        ZIndex = 4,
    }), { TextColor3 = "TextMuted" })
    local hexBox = Themed(New("TextBox", {
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        FontFace = FONT_MONO,
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(38, 0),
        Size = UDim2.new(1, -44, 1, 0),
        ZIndex = 4,
    }, hexWell), { TextColor3 = "TextPrimary" })

    local positionWell = New("Frame", {
        Position = UDim2.fromOffset(RIGHT_X + RIGHT_W - POSITION_W, ROW_Y),
        Size = UDim2.fromOffset(POSITION_W, 28),
        ZIndex = 3,
    }, panel)
    FieldMaterial(positionWell, 8)
    local positionBox = Themed(New("TextBox", {
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        FontFace = FONT_MONO,
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.new(1, -26, 1, 0),
        ZIndex = 4,
    }, positionWell), { TextColor3 = "TextPrimary" })
    Themed(Text(positionWell, {
        Text = "%",
        FontFace = FONT_MONO,
        TextSize = 12,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -8, 0, 0),
        Size = UDim2.new(0, 10, 1, 0),
        ZIndex = 4,
    }), { TextColor3 = "TextMuted" })
    bindTooltip(W, positionWell, function() return "Where the selected stop sits along the ramp" end)

    -- Segmented control: one etched well split into four glass keys.
    local SEG_Y, SEG_H = EDIT_Y + SB - 30, 30
    local segTrack = New("Frame", {
        Position = UDim2.fromOffset(RIGHT_X, SEG_Y),
        Size = UDim2.fromOffset(RIGHT_W, SEG_H),
        ZIndex = 3,
    }, panel)
    FieldMaterial(segTrack, 9)
    local SEG_W = (RIGHT_W - 6) / 4

    local function segment(index, text, tone, tip, onClick)
        local seg = { Enabled = true }
        local button = New("TextButton", {
            Name = text,
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(3 + (index - 1) * SEG_W, 3),
            Size = UDim2.fromOffset(SEG_W, SEG_H - 6),
            ZIndex = 4,
        }, segTrack)
        local plate = Themed(New("Frame", {
            Position = UDim2.fromOffset(1, 0),
            Size = UDim2.new(1, -2, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 4,
        }, button), { BackgroundColor3 = "LensTint" })
        Corner(plate, 7)
        local scale = New("UIScale", { Scale = 1 }, button)
        seg.Label = Themed(Text(button, {
            Text = text,
            FontFace = FONT_MEDIUM,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 5,
        }), { TextColor3 = tone })
        if index > 1 then
            Themed(New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.fromOffset(1, 12),
                BackgroundTransparency = 0.8,
                BorderSizePixel = 0,
                ZIndex = 4,
            }, button), { BackgroundColor3 = "Rim" })
        end
        button.MouseEnter:Connect(function()
            if not seg.Enabled then return end
            Tween(plate, Motion.Hover, { BackgroundTransparency = 0.86 })
            playSound("Hover")
        end)
        button.MouseLeave:Connect(function()
            Tween(plate, Motion.Hover, { BackgroundTransparency = 1 })
            Tween(scale, Motion.Pop, { Scale = 1 })
        end)
        button.MouseButton1Down:Connect(function()
            if seg.Enabled then Tween(scale, Motion.Press, { Scale = 0.94 }) end
        end)
        button.MouseButton1Up:Connect(function() Tween(scale, Motion.Pop, { Scale = 1 }) end)
        button.MouseButton1Click:Connect(function()
            if seg.Enabled then onClick() end
        end)
        bindTooltip(W, button, function() return tip end)
        seg.Plate = plate
        return seg
    end

    local function setEnabled(seg, enabled)
        if seg.Enabled == enabled then return end
        seg.Enabled = enabled
        seg.Label.TextTransparency = enabled and 0 or 0.6
        if not enabled then seg.Plate.BackgroundTransparency = 1 end
    end

    ---------------------------------------------------------------------------------------------------
    -- Editing
    ---------------------------------------------------------------------------------------------------
    local function sortStops()
        table.sort(stops, function(a, b) return a.position < b.position end)
        stops[1].position, stops[#stops].position = 0, 1
    end

    local function isEndpoint(stop)
        return stop == stops[1] or stop == stops[#stops]
    end

    -- The ramp's colour at `t`, sampled from the stops themselves.
    local function colorAt(t)
        for i = 1, #stops - 1 do
            local a, b = stops[i], stops[i + 1]
            if t <= b.position then
                local span = b.position - a.position
                return a.color:Lerp(b.color, if span > 0 then math.clamp((t - a.position) / span, 0, 1) else 0)
            end
        end
        return stops[#stops].color
    end

    local function selectStop(stop)
        if selected == stop then return end
        selected = stop
        playSound("Press")
        render()
    end

    local function addStopAt(position)
        if #stops >= PALETTE_MAX_STOPS then return end
        sortStops()
        local fresh = { color = colorAt(position), position = position }
        table.insert(stops, fresh)
        selected = fresh
        playSound("Open")
        render(true)
    end

    -- Into the widest gap, coloured by sampling the ramp right there.
    local function addStop()
        sortStops()
        local gapAt, gapSize = 0.5, -1
        for i = 1, #stops - 1 do
            local size = stops[i + 1].position - stops[i].position
            if size > gapSize then gapSize, gapAt = size, (stops[i].position + stops[i + 1].position) / 2 end
        end
        addStopAt(gapAt)
    end

    local function removeStop(stop)
        if #stops <= 2 or isEndpoint(stop) then return end
        local index = table.find(stops, stop)
        if not index then return end
        table.remove(stops, index)
        selected = stops[math.max(1, index - 1)]
        playSound("Close")
        render(true)
    end

    -- Mirror the ramp end to end. The selection follows its colour to the other side.
    local function flip()
        sortStops()
        local count = #stops
        local mirrored = count - table.find(stops, selected) + 1
        local colors, positions = {}, {}
        for i = 1, count do
            colors[i] = stops[count - i + 1].color
            positions[i] = 1 - stops[count - i + 1].position
        end
        for i, stop in ipairs(stops) do
            stop.color, stop.position, stop.hue = colors[i], positions[i], nil
        end
        selected = stops[mirrored]
        playSound("Tab")
        render()
    end

    local function spaceEvenly()
        sortStops()
        for i, stop in ipairs(stops) do stop.position = (i - 1) / (#stops - 1) end
        playSound("Tab")
        render()
    end

    local function replaceStops(fresh, quiet)
        for i = #stops, 1, -1 do stops[i] = nil end
        for _, stop in ipairs(fresh) do table.insert(stops, stop) end
        selected = stops[1]
        render(true, quiet)
    end

    local addSeg = segment(1, "Add", "TextPrimary", "Add a stop in the widest gap", addStop)
    local removeSeg = segment(2, "Remove", "Danger", "Remove the selected stop", function() removeStop(selected) end)
    segment(3, "Flip", "TextPrimary", "Mirror the gradient end to end", flip)
    local evenSeg = segment(4, "Even", "TextPrimary", "Space the stops out evenly", spaceEvenly)

    -- The colour is edited in HSV. Each stop remembers its hue, so dragging the shade cursor into the grey
    -- column or down to black (where a colour has no hue left) doesn't snap the hue rail back to red.
    trackPointer(sb, function(x, y)
        local hue = selected.hue or select(1, selected.color:ToHSV())
        selected.hue = hue
        selected.color = Color3.fromHSV(hue, x, 1 - y)
        render()
    end)
    trackPointer(hueRail, function(x)
        local _, sat, val = selected.color:ToHSV()
        selected.hue = x
        selected.color = Color3.fromHSV(x, sat, val)
        render()
    end)

    local hexFocused, positionFocused = false, false
    hexBox.Focused:Connect(function() hexFocused = true end)
    hexBox.FocusLost:Connect(function()
        hexFocused = false
        local color = fromHex(hexBox.Text)
        if color then
            selected.color, selected.hue = color, nil
            playSound("Press")
        end
        render()
    end)
    positionBox.Focused:Connect(function() positionFocused = true end)
    positionBox.FocusLost:Connect(function()
        positionFocused = false
        local value = tonumber((positionBox.Text:gsub("%%", "")))
        if value and not isEndpoint(selected) then
            selected.position = math.clamp(value / 100, 0.02, 0.98)
            playSound("Press")
        end
        render()
    end)

    -- Clicking bare track drops a new stop right there.
    track.InputBegan:Connect(function(input)
        if not isPointer(input) then return end
        local left, width = track.AbsolutePosition.X, track.AbsoluteSize.X
        if width <= 0 then return end
        addStopAt(math.clamp((input.Position.X - left) / width, 0.02, 0.98))
    end)

    ---------------------------------------------------------------------------------------------------
    -- Stop knobs. Each belongs to a stop rather than to an index, so a knob dragged past its neighbour
    -- keeps its own colour and selection while the stops re-sort around it.
    ---------------------------------------------------------------------------------------------------
    local knobs = {} -- stop -> knob

    local function paintKnob(knob)
        local on, hovered = knob.Stop == selected, knob.Hovered
        if knob.On == on and knob.WasHovered == hovered then return end
        knob.On, knob.WasHovered = on, hovered
        Tween(knob.Scale, Motion.Pop, { Scale = (on and 1.12 or 1) + (hovered and 0.06 or 0) })
        Tween(knob.Glow, Motion.Hover, { BackgroundTransparency = on and 0.55 or 1 })
        knob.Button.ZIndex = on and 7 or 6
    end

    local function buildKnob(stop)
        local button = New("TextButton", {
            Name = "Stop",
            Text = "",
            AutoButtonColor = false,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(stop.position, 0, 0.5, 0),
            Size = UDim2.fromOffset(PALETTE_KNOB + 6, PALETTE_KNOB + 6),
            BackgroundTransparency = 1,
            ZIndex = 6,
        }, knobLayer)
        local scale = New("UIScale", { Scale = 1 }, button)
        -- The selection halo glows in the stop's own colour (set in render), not the theme accent, which
        -- would clash with whatever ramp is being built.
        local glow = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(PALETTE_KNOB + 10, PALETTE_KNOB + 10),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 6,
        }, button)
        Corner(glow, PALETTE_KNOB)
        local _, well = paletteKnob(button, PALETTE_KNOB, 7)
        local knob = { Stop = stop, Button = button, Scale = scale, Glow = glow, Well = well, Hovered = false }

        button.MouseEnter:Connect(function()
            knob.Hovered = true
            paintKnob(knob)
            playSound("Hover")
        end)
        button.MouseLeave:Connect(function()
            knob.Hovered = false
            paintKnob(knob)
        end)
        button.MouseButton2Click:Connect(function() removeStop(stop) end)
        button.InputBegan:Connect(function(input)
            if not isPointer(input) then return end
            selectStop(stop)
            if isEndpoint(stop) then return end -- endpoints can be recoloured but never moved
            local moveConnection, endConnection
            moveConnection = UserInputService.InputChanged:Connect(function(changed)
                if not isMove(changed) then return end
                local left, width = track.AbsolutePosition.X, track.AbsoluteSize.X
                if width <= 0 or not table.find(stops, stop) then return end
                stop.position = math.clamp((changed.Position.X - left) / width, 0.02, 0.98)
                playSound("Tick")
                render()
            end)
            endConnection = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then return end
                moveConnection:Disconnect()
                endConnection:Disconnect()
            end)
        end)
        knobs[stop] = knob
        return knob
    end

    -- Knobs for stops that are gone are dropped, and stops that are new get one.
    local function syncKnobs()
        local present = {}
        for _, stop in ipairs(stops) do
            present[stop] = true
            if not knobs[stop] then buildKnob(stop) end
        end
        for stop, knob in pairs(knobs) do
            if not present[stop] then
                knob.Button:Destroy()
                knobs[stop] = nil
            end
        end
    end

    ---------------------------------------------------------------------------------------------------
    -- Rendering
    ---------------------------------------------------------------------------------------------------
    -- `quiet` draws without handing the ramp to onLive: opening the editor, or resetting to the theme,
    -- changes nothing yet, and pushing the theme's own colours back as a custom ramp would stop the UI
    -- following the theme.
    function render(restructured, quiet)
        sortStops()
        if not table.find(stops, selected) then selected = stops[1] end
        if restructured then syncKnobs() end

        local sequence = stopsToSequence(stops)
        for _, gradient in ipairs(liveGradients) do gradient.Color = sequence end
        for i, bar in ipairs(meterBars) do
            put(bar, "BackgroundColor3", colorAt((i - 1) / (#meterBars - 1)))
        end
        local surface = colorAt(LEVEL)
        put(beadRing, "Color", surface)
        put(beadGlow, "ImageColor3", surface)

        for stop, knob in pairs(knobs) do
            put(knob.Button, "Position", UDim2.new(stop.position, 0, 0.5, 0))
            put(knob.Well, "BackgroundColor3", stop.color)
            put(knob.Glow, "BackgroundColor3", stop.color)
            paintKnob(knob)
        end

        local hue, sat, val = selected.color:ToHSV()
        if sat > 0.001 and val > 0.001 and not selected.hue then selected.hue = hue end
        hue = selected.hue or hue
        put(sb, "BackgroundColor3", Color3.fromHSV(hue, 1, 1))
        put(sbCursor, "Position", UDim2.fromScale(sat, 1 - val))
        put(sbCursor, "BackgroundColor3", selected.color)
        put(hueThumb, "Position", UDim2.fromScale(hue, 0.5))
        put(hueWell, "BackgroundColor3", Color3.fromHSV(hue, 1, 1))
        put(hexSwatch, "BackgroundColor3", selected.color)
        -- The text fields are written straight through: the person typing in them changes their Text too.
        if not hexFocused then hexBox.Text = toHex(selected.color) end
        local endpoint = isEndpoint(selected)
        if not positionFocused then positionBox.Text = tostring(math.floor(selected.position * 100 + 0.5)) end
        put(positionBox, "TextEditable", not endpoint)
        put(positionBox, "TextTransparency", endpoint and 0.5 or 0)

        put(countLabel, "Text", string.format("Stop %d of %d", table.find(stops, selected), #stops))
        setEnabled(addSeg, #stops < PALETTE_MAX_STOPS)
        setEnabled(removeSeg, not endpoint and #stops > 2)
        setEnabled(evenSeg, #stops > 2)
        if not quiet then onLive(sequence) end
    end

    ---------------------------------------------------------------------------------------------------
    -- Presets
    ---------------------------------------------------------------------------------------------------
    Themed(Text(panel, {
        Text = "PRESETS",
        TextSize = 10,
        Position = UDim2.fromOffset(PAD, PRESET_LABEL_Y),
        Size = UDim2.fromOffset(INNER, 12),
        ZIndex = 2,
    }), { TextColor3 = "TextMuted" })
    local presetW = (INNER - (#PALETTE_PRESETS - 1) * 6) / #PALETTE_PRESETS
    for i, preset in ipairs(PALETTE_PRESETS) do
        local pill = New("TextButton", {
            Name = preset.Name,
            Text = "",
            AutoButtonColor = false,
            Position = UDim2.fromOffset(PAD + (i - 1) * (presetW + 6), PRESET_Y),
            Size = UDim2.fromOffset(presetW, PRESET_H),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 3,
        }, panel)
        Corner(pill, PRESET_H / 2)
        New("UIGradient", { Color = presetSequence(preset.Colors) }, pill)
        paletteGloss(pill, PRESET_H / 2, 4, 0.6)
        Themed(New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1, Transparency = 0.6 }, pill), { Color = "Rim" })
        local pillScale = New("UIScale", { Scale = 1 }, pill)
        pill.MouseEnter:Connect(function()
            Tween(pillScale, Motion.Pop, { Scale = 1.08 })
            playSound("Hover")
        end)
        pill.MouseLeave:Connect(function() Tween(pillScale, Motion.Pop, { Scale = 1 }) end)
        pill.MouseButton1Click:Connect(function()
            local fresh = {}
            for index, color in ipairs(preset.Colors) do
                table.insert(fresh, { color = color, position = (index - 1) / math.max(1, #preset.Colors - 1) })
            end
            playSound("Open")
            replaceStops(fresh)
        end)
        bindTooltip(W, pill, function() return preset.Name end)
    end

    ---------------------------------------------------------------------------------------------------
    -- Footer: a quiet reset, and Done with a rim lit by the gradient itself.
    ---------------------------------------------------------------------------------------------------
    local function footerButton(text, x, width, lit, onClick)
        local button = New("TextButton", {
            Name = text,
            Text = "",
            AutoButtonColor = false,
            Position = UDim2.fromOffset(x, FOOTER_Y),
            Size = UDim2.fromOffset(width, FOOTER_H),
            BackgroundTransparency = 0.9,
            BorderSizePixel = 0,
            ZIndex = 3,
        }, panel)
        Themed(button, { BackgroundColor3 = "LensTint" })
        Corner(button, 9)
        New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0, 0.5) }, button)
        local stroke = New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Thickness = lit and 1.5 or 1,
            Transparency = lit and 0.05 or 0.6,
        }, button)
        if lit then
            stroke.Color = Color3.new(1, 1, 1)
            live(stroke)
        else
            Themed(stroke, { Color = "Rim" })
        end
        Specular(button, 18, 0.55, 4)
        Themed(Text(button, {
            Text = text,
            FontFace = lit and FONT_BOLD or FONT_MEDIUM,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 5,
        }), { TextColor3 = lit and "TextPrimary" or "TextSecondary" })
        local scale = New("UIScale", { Scale = 1 }, button)
        button.MouseEnter:Connect(function()
            Tween(button, Motion.Hover, { BackgroundTransparency = 0.78 })
            Tween(scale, Motion.Pop, { Scale = 1.02 })
            playSound("Hover")
        end)
        button.MouseLeave:Connect(function()
            Tween(button, Motion.Hover, { BackgroundTransparency = 0.9 })
            Tween(scale, Motion.Pop, { Scale = 1 })
        end)
        button.MouseButton1Down:Connect(function() Tween(scale, Motion.Press, { Scale = 0.97 }) end)
        button.MouseButton1Up:Connect(function() Tween(scale, Motion.Pop, { Scale = 1.02 }) end)
        button.MouseButton1Click:Connect(onClick)
        return button
    end

    local RESET_W = 124
    footerButton("Reset to theme", PAD, RESET_W, false, function()
        playSound("Close")
        replaceStops(onReset(), true)
    end)
    footerButton("Done", PAD + RESET_W + 8, INNER - RESET_W - 8, true, function() W:ClosePopup() end)

    render(true, true)
    playSound("Open")
    W:OpenPopup(panel, function()
        playSound("Close")
        Tween(panel, Motion.FadeOut, { Size = UDim2.fromOffset(PALETTE_WIDTH, 0) })
        task.delay(Motion.FadeOut.Time, function() panel:Destroy() end)
    end)
    Tween(panel, Motion.Reveal, { Size = UDim2.fromOffset(PALETTE_WIDTH, editorHeight) })
end

-------------------------------------------------------------------------------------------------------
-- AddPalette element: the accent ramp itself is the button that opens the editor.
-------------------------------------------------------------------------------------------------------
-- Stop times of the live accent ramp, rebuilt only when the ramp itself is replaced. The element's stop
-- markers are bound to the theme registry, so this is asked for on every repaint.
local accentTimesFor, accentTimes = false, nil
local function accentStopTimes()
    local custom = Library.AccentGradient
    if custom ~= accentTimesFor or not accentTimes then
        accentTimesFor = custom
        accentTimes = { 0, 1 }
        if custom then
            accentTimes = {}
            for i, keypoint in ipairs(custom.Keypoints) do accentTimes[i] = keypoint.Time end
        end
    end
    return accentTimes
end

function Container:AddPalette(idx, info)
    info = info or {}
    local W = self.W
    local Palette = { Type = "Palette", Text = info.Text or "Accent Gradient" }
    local RAMP_H = 22

    local holder = New("Frame", {
        Name = "Palette",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 46),
        LayoutOrder = self:NextOrder(),
    }, self.Frame)
    Themed(Text(holder, {
        Text = Palette.Text,
        FontFace = FONT_MEDIUM,
        TextSize = 13,
        Size = UDim2.new(1, -96, 0, 18),
    }), { TextColor3 = "TextSecondary" })
    -- What the ramp follows right now: the theme's own accent, or a custom ramp of so many stops.
    Themed(Text(holder, {
        FontFace = FONT_MEDIUM,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(96, 18),
    }), {
        TextColor3 = "TextMuted",
        Text = function()
            local custom = Library.AccentGradient
            return if custom then string.format("%d stops", #custom.Keypoints) else "Theme accent"
        end,
    })

    local ramp = New("TextButton", {
        Name = "Ramp",
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, RAMP_H),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 2,
    }, holder)
    Corner(ramp, RAMP_H / 2)
    Themed(New("UIGradient", {}, ramp), { Color = accentSequence })
    paletteGloss(ramp, RAMP_H / 2, 3, 0.5)
    local rampRim = Themed(New("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = 1,
        Transparency = 0.6,
    }, ramp), { Color = "Rim" })
    Specular(ramp, 24, 0.45, 4)
    local rampScale = New("UIScale", { Scale = 1 }, ramp)

    -- A marker for every stop between the ends, so a custom ramp shows its shape at a glance. Inset by the
    -- cap radius so the markers stay on the straight part of the pill.
    for i = 1, PALETTE_MAX_STOPS - 2 do
        local marker = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(6, 6),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 5,
        }, ramp), {
            Visible = function() return i + 1 < #accentStopTimes() end,
            Position = function()
                local t = accentStopTimes()[i + 1] or 0
                return UDim2.new(t, (RAMP_H / 2) * (1 - 2 * t), 0.5, 0)
            end,
        })
        Corner(marker, 3)
        New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0.6 }, marker)
    end

    -- The door into the editor: a dark glass chip with a chevron at the right end of the ramp.
    local chip = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -RAMP_H / 2, 0.5, 0),
        Size = UDim2.fromOffset(RAMP_H - 6, RAMP_H - 6),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, ramp), { BackgroundColor3 = "PaneBottom" })
    Corner(chip, RAMP_H)
    Themed(New("UIStroke", { Thickness = 1, Transparency = 0.55 }, chip), { Color = "Rim" })
    local chipScale = New("UIScale", { Scale = 1 }, chip)
    local chevron, chevronLines = Chevron(chip, 6)
    chevron.Position = UDim2.new(0.5, 1, 0.5, 0)
    for _, line in ipairs(chevronLines) do Themed(line, { BackgroundColor3 = "TextPrimary" }) end

    ramp.MouseEnter:Connect(function()
        Tween(rampScale, Motion.Pop, { Scale = 1.015 })
        Tween(rampRim, Motion.Hover, { Transparency = 0.25 })
        Tween(chipScale, Motion.Pop, { Scale = 1.15 })
        playSound("Hover")
    end)
    ramp.MouseLeave:Connect(function()
        Tween(rampScale, Motion.Pop, { Scale = 1 })
        Tween(rampRim, Motion.Hover, { Transparency = 0.6 })
        Tween(chipScale, Motion.Pop, { Scale = 1 })
    end)

    local function themeStops()
        return { { color = Glass.AccentDeep, position = 0 }, { color = Glass.Accent, position = 1 } }
    end

    function Palette:Open()
        local stops = Library.AccentGradient and sequenceToStops(Library.AccentGradient) or themeStops()
        openPaletteEditor(W, ramp, stops,
            function(sequence) Library:SetAccentGradient(sequence) end,
            function() Library:SetAccentGradient(nil) return themeStops() end)
    end
    ramp.MouseButton1Click:Connect(function() Palette:Open() end)
    bindTooltip(W, ramp, function() return info.Tooltip or "Open the gradient editor" end)

    function Palette:SetVisible(visible) holder.Visible = visible end
    if idx then Library.Options[idx] = Palette end
    return Palette
end

-- ===== 20_window.lua =====
-------------------------------------------------------------------------------------------------------
-- Window
--
-- CreateWindow builds the glass shell and the shared context `W`, then hands W to BuildTabs (sidebar,
-- pages, magnetic tabs) and BuildBubble (minimise-to-bubble), which are defined in the next files.
-------------------------------------------------------------------------------------------------------
-- assigned in 21_tabs.lua, 22_bubble.lua, 23_satellites.lua, 24_themeselect.lua, 25_rail.lua
-- (BuildAmbient and BuildCursor are plain locals from 08/09, already in scope by the time we get here)
local BuildTabs, BuildBubble, BuildSatellites, BuildSetupFlow, BuildRail

local WindowDefaults = {
    Title = "",
    Footer = "",
    Icon = nil,
    Position = UDim2.fromOffset(6, 6),
    Size = UDim2.fromOffset(760, 600),
    AutoShow = true,
    Center = true,
    AlwaysOnTop = false,
    CornerRadius = 14,
    NotifySide = "Right",
    ShowCustomCursor = true,
    ToggleKeybind = Enum.KeyCode.RightControl,

    -- FishyUI extras
    Brand = "Fishy Studios", -- subtitle under the window title in the sidebar header; "" hides it
    Theme = nil, -- starting theme; defaults to the last one picked (saved to disk when possible)
    ThemeSelect = nil, -- true = always show the theme picker first; nil = only on first run; false = never
    Blur = true,
    BlurSize = 18,
    Bubble = true, -- minimise into a draggable glass bubble instead of vanishing
    Satellites = true, -- magnetic info pods (session, performance, server) docked to the window's side
    BubbleText = nil, -- defaults to Title, or "Menu" when there is no title
}

local THEME_TILE_WIDTH, THEME_TILE_HEIGHT, THEME_TILE_GAP = 98, 62, 8

function Library:CreateWindow(info)
    info = merge(WindowDefaults, info)

    self.CornerRadius = info.CornerRadius
    self.NotifySide = info.NotifySide
    self.ShowCustomCursor = info.ShowCustomCursor
    self.ToggleKeybind = info.ToggleKeybind

    applyPrefs() -- language and font chosen on a previous run, before anything is built
    applySoundPrefs()
    local savedTheme = loadThemeChoice()
    local startTheme = info.Theme or savedTheme
    if startTheme and Themes[startTheme] then
        self.Theme = startTheme
        for key, value in pairs(Themes[startTheme]) do Glass[key] = value end
    end
    syncScheme()

    local Window = {
        AlwaysOnTop = info.AlwaysOnTop,
        Tabs = {},
        ActiveTab = nil,
        OnTabOrderChanged = nil,
        OnThemeChanged = nil,
    }
    local W = { Info = info, Window = Window }
    self.Window = Window

    local size = toPixels(info.Size)
    size = Vector2.new(math.max(size.X, L.MinWindow.X), math.max(size.Y, L.MinWindow.Y))

    local ScreenGui = New("ScreenGui", {
        Name = "FishyUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = info.AlwaysOnTop and 1000 or 100,
    }, nil)
    mountGui(ScreenGui)
    self.ScreenGui = ScreenGui

    -- Holder carries position, size and scale; the pane inside it clips. Shadow and overlays sit outside the clip.
    local Holder = New("Frame", {
        Name = "Window",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = info.Center and UDim2.fromScale(0.5, 0.5) or (info.Position + UDim2.fromOffset(size.X / 2, size.Y / 2)),
        Size = UDim2.fromOffset(size.X, size.Y),
        Visible = false,
        ZIndex = 1,
    }, ScreenGui)
    local Scale = New("UIScale", { Scale = 1 }, Holder)
    GlassShadow(Holder, 22, "ShadowTransparency", 0)

    local Main = New("Frame", {
        Name = "Main",
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        ZIndex = 1,
    }, Holder)
    local MainPane = PaneMaterial(Main, info.CornerRadius, 50)

    local Sheen = New("Frame", {
        Name = "Sheen",
        Size = UDim2.new(1, 0, 0.55, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 2,
    }, Main)
    local SheenCorner = Corner(Sheen, info.CornerRadius)
    Themed(New("UIGradient", { Rotation = 90 }, Sheen), { Transparency = sheenTransparency })

    W.ScreenGui, W.Holder, W.Scale, W.Main = ScreenGui, Holder, Scale, Main

    ---------------------------------------------------------------------------------------------------
    -- Overlay: popups, the scrim that closes them, and tooltips. Lives outside the pane so nothing clips it.
    ---------------------------------------------------------------------------------------------------
    local Overlay = New("Frame", {
        Name = "Overlay",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 150,
    }, Holder)
    local Scrim = New("TextButton", {
        Name = "Scrim",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(-4000, -4000),
        Size = UDim2.new(1, 8000, 1, 8000),
        Visible = false,
        ZIndex = 1,
    }, Overlay)
    W.Overlay = Overlay

    local activePopup
    function W:OpenPopup(frame, onClose)
        if activePopup then W:ClosePopup() end
        frame.ZIndex = 10
        frame.Parent = Overlay
        -- Only GuiButtons sink input. A popup's own body and its Frame-based controls (a colour field, a
        -- hue rail, a gradient ramp) let the click fall straight through to the scrim behind them, which
        -- closes the popup the instant you touch it. This catcher sits at the back of every popup and
        -- swallows anything the panel itself didn't sink, so the scrim only ever sees genuine outside
        -- clicks. It is behind everything, so the controls above it still receive their own input.
        if not frame:FindFirstChild("PopupCatcher") then
            New("TextButton", {
                Name = "PopupCatcher",
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                ZIndex = 0,
            }, frame)
        end
        Scrim.Visible = true
        activePopup = { Frame = frame, OnClose = onClose }
    end

    function W:ClosePopup()
        local popup = activePopup
        if not popup then return end
        activePopup = nil
        Scrim.Visible = false
        if popup.OnClose then popup.OnClose() else popup.Frame:Destroy() end
    end
    Scrim.MouseButton1Click:Connect(function() W:ClosePopup() end)
    Scrim.MouseButton2Click:Connect(function() W:ClosePopup() end)

    function W:ToLocal(absolute)
        return (absolute - Holder.AbsolutePosition) / Scale.Scale
    end

    -- Puts a popup under `anchor` (or above it when there isn't room), aligned to the anchor's left edge
    -- when the popup is at least as wide, otherwise to its right edge. Popups above grow upward.
    function W:PlacePopup(frame, anchor, gap, height)
        local topLeft = W:ToLocal(anchor.AbsolutePosition)
        local anchorSize = anchor.AbsoluteSize / Scale.Scale
        local width = frame.Size.X.Offset
        local windowSize = Holder.Size
        local x = width >= anchorSize.X - 1 and topLeft.X or (topLeft.X + anchorSize.X - width)
        x = math.clamp(x, 8, math.max(8, windowSize.X.Offset - width - 8))
        local below = topLeft.Y + anchorSize.Y + gap
        if below + height > windowSize.Y.Offset - 8 and topLeft.Y - gap - height > 8 then
            frame.AnchorPoint = Vector2.new(0, 1)
            -- Growing upward: keep the top edge inside the window.
            frame.Position = UDim2.fromOffset(x, math.max(height + 8, topLeft.Y - gap))
        else
            frame.AnchorPoint = Vector2.new(0, 0)
            -- Growing downward: a tall popup (the gradient editor) under a low anchor would otherwise
            -- hang off the bottom of the window, so pull it up until it fits.
            frame.Position = UDim2.fromOffset(x, math.clamp(below, 8, math.max(8, windowSize.Y.Offset - height - 8)))
        end
    end

    local Tooltip = New("Frame", {
        Name = "Tooltip",
        Size = UDim2.fromOffset(0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        Visible = false,
        ZIndex = 50,
    }, Overlay)
    PopupMaterial(Tooltip, 8, 20)
    New("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 9),
        PaddingRight = UDim.new(0, 9),
    }, Tooltip)
    local TooltipText = Themed(Text(Tooltip, {
        FontFace = FONT_MEDIUM,
        TextSize = 12,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromOffset(0, 0),
        ZIndex = 51,
    }), { TextColor3 = "TextSecondary" })
    New("UISizeConstraint", { MaxSize = Vector2.new(240, 400) }, TooltipText)
    local TooltipScale = New("UIScale", { Scale = 1 }, Tooltip)

    local tooltipTarget, tooltipToken = nil, 0
    function W:ShowTooltip(target, text)
        tooltipTarget = target
        tooltipToken += 1
        local token = tooltipToken
        task.delay(0.35, function()
            if token ~= tooltipToken or tooltipTarget ~= target or not target.Parent then return end
            TooltipText.Text = text
            local topLeft = W:ToLocal(target.AbsolutePosition)
            local targetSize = target.AbsoluteSize / Scale.Scale
            Tooltip.Position = UDim2.fromOffset(
                math.clamp(topLeft.X, 8, math.max(8, Holder.Size.X.Offset - 260)),
                topLeft.Y + targetSize.Y + 6
            )
            TooltipScale.Scale = 0.94
            Tooltip.Visible = true
            Tween(TooltipScale, Motion.Pop, { Scale = 1 })
        end)
    end

    function W:HideTooltip(target)
        if target and target ~= tooltipTarget then return end
        tooltipTarget = nil
        tooltipToken += 1
        Tooltip.Visible = false
    end

    ---------------------------------------------------------------------------------------------------
    -- Sidebar header: the window title with the brand beneath it
    ---------------------------------------------------------------------------------------------------
    local BrandHeader = New("Frame", {
        Name = "BrandHeader",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(L.SidebarInset + 8, 14),
        Size = UDim2.new(0, L.SidebarWidth - L.SidebarInset * 2 - 8, 0, L.BrandHeight - 14),
        ZIndex = 6,
    }, Main)
    local hasBrand = info.Brand ~= ""
    local TitleLabel = Themed(Text(BrandHeader, {
        Name = "Title",
        Text = info.Title ~= "" and info.Title or "FishyUI",
        TextSize = 16,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, hasBrand and -8 or 0),
        Size = UDim2.new(1, 0, 0, 20),
        ZIndex = 6,
    }), { TextColor3 = "TextPrimary" })
    if hasBrand then
        Themed(Text(BrandHeader, {
            Name = "Brand",
            Text = info.Brand,
            FontFace = FONT_MEDIUM,
            TextSize = 11,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 10),
            Size = UDim2.new(1, 0, 0, 14),
            ZIndex = 6,
        }), { TextColor3 = "TextMuted" })
    end

    ---------------------------------------------------------------------------------------------------
    -- Sidebar, divider and content area
    ---------------------------------------------------------------------------------------------------
    local sidebarTop = L.BrandHeight + 12
    local Sidebar = New("ScrollingFrame", {
        Name = "Sidebar",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(L.SidebarInset, sidebarTop),
        Size = UDim2.new(0, L.SidebarWidth - L.SidebarInset * 2, 1, -(sidebarTop + L.FooterHeight + 6)),
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 5,
    }, Main)

    local Divider = Themed(New("Frame", {
        Name = "Divider",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0, L.SidebarWidth, 0, 22),
        Size = UDim2.new(0, 1, 1, -(22 + L.FooterHeight + 10)),
        BorderSizePixel = 0,
        ZIndex = 4,
    }, Main), { BackgroundColor3 = "Rim" })
    New("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0.00, 1),
            NumberSequenceKeypoint.new(0.15, 0.86),
            NumberSequenceKeypoint.new(0.85, 0.86),
            NumberSequenceKeypoint.new(1.00, 1),
        }),
    }, Divider)

    local Content = New("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(L.SidebarWidth, 0),
        Size = UDim2.new(1, -L.SidebarWidth, 1, -L.FooterHeight),
        ClipsDescendants = true,
        ZIndex = 5,
    }, Main)

    -- Carried tabs float here: above the pane and unclipped, so they can be taken anywhere.
    local DragLayer = New("Frame", {
        Name = "DragLayer",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 100,
    }, Holder)

    W.Sidebar, W.Content, W.DragLayer = Sidebar, Content, DragLayer

    ---------------------------------------------------------------------------------------------------
    -- Footer text and resize grip
    ---------------------------------------------------------------------------------------------------
    local FooterLabel = Themed(Text(Main, {
        Name = "Footer",
        Text = info.Footer,
        FontFace = FONT_MEDIUM,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(1, -160, 0, L.FooterHeight),
        ZIndex = 15,
    }), { TextColor3 = "TextMuted" })

    local ResizeGrip = New("TextButton", {
        Name = "ResizeGrip",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -5, 1, -5),
        Size = UDim2.fromOffset(L.ResizeGrip, L.ResizeGrip),
        ZIndex = 25,
    }, Main)
    local gripLines = {}
    -- Shaft from (6,6) to the tip at (13,13), plus the two arrowhead strokes meeting at the tip.
    for _, stroke in ipairs({
        { center = Vector2.new(9.5, 9.5), size = Vector2.new(9, 1.5), rotation = 45 },
        { center = Vector2.new(10.75, 13), size = Vector2.new(5, 1.5), rotation = 0 },
        { center = Vector2.new(13, 10.75), size = Vector2.new(1.5, 5), rotation = 0 },
    }) do
        table.insert(gripLines, Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(stroke.center.X, stroke.center.Y),
            Size = UDim2.fromOffset(stroke.size.X, stroke.size.Y),
            Rotation = stroke.rotation,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            ZIndex = 26,
        }, ResizeGrip), { BackgroundColor3 = "Glyph" }))
    end

    local windowResize
    local function paintGrip(active)
        for _, line in ipairs(gripLines) do
            Tween(line, Motion.Hover, {
                BackgroundColor3 = active and Glass.Accent or Glass.Glyph,
                BackgroundTransparency = active and 0 or 0.35,
            })
        end
    end
    ResizeGrip.MouseEnter:Connect(function() paintGrip(true) end)
    ResizeGrip.MouseLeave:Connect(function()
        if not windowResize then paintGrip(false) end
    end)
    ResizeGrip.InputBegan:Connect(function(input)
        if not isPointer(input) then return end
        windowResize = { start = input.Position, size = Holder.Size, pos = Holder.Position }
        paintGrip(true)
        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState ~= Enum.UserInputState.End then return end
            connection:Disconnect()
            windowResize = nil
            paintGrip(false)
        end)
    end)
    Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
        if not windowResize or not isMove(input) then return end
        local scale = Scale.Scale
        local vp = viewportSize()
        local delta = input.Position - windowResize.start
        local startW, startH = windowResize.size.X.Offset, windowResize.size.Y.Offset
        local w = math.clamp(startW + delta.X / scale, L.MinWindow.X, math.max(L.MinWindow.X, vp.X * L.ViewportFill / scale))
        local h = math.clamp(startH + delta.Y / scale, L.MinWindow.Y, math.max(L.MinWindow.Y, vp.Y * L.ViewportFill / scale))
        -- Anchored at the centre, so shift by half the growth to keep the top-left corner put.
        local p = windowResize.pos
        Holder.Size = UDim2.fromOffset(w, h)
        Holder.Position = UDim2.new(p.X.Scale, p.X.Offset + (w - startW) * scale / 2, p.Y.Scale, p.Y.Offset + (h - startH) * scale / 2)
    end))

    ---------------------------------------------------------------------------------------------------
    -- Window drag: from the sidebar header or any page header. Released near a screen edge, the window
    -- is drawn flush onto it.
    ---------------------------------------------------------------------------------------------------
    local function dockWindow()
        local ss = ScreenGui.AbsoluteSize
        local p = Holder.Position
        local half = Vector2.new(Holder.Size.X.Offset, Holder.Size.Y.Offset) * Scale.Scale / 2
        local center = Vector2.new(p.X.Scale * ss.X + p.X.Offset, p.Y.Scale * ss.Y + p.Y.Offset)
        local top = GuiService:GetGuiInset().Y
        local x, y = center.X, center.Y

        -- Shoved most of the way off the left or right: collapse into the edge rail rather than snapping
        -- back. Nudging it a little past the edge still just docks, so this only fires on a real shove.
        if W.EnterRail and Window.ActiveTab then
            local depth = half.X * 2 * L.RailPushDepth
            if half.X - center.X > depth then
                W.EnterRail("Left")
                return
            elseif (center.X + half.X) - ss.X > depth then
                W.EnterRail("Right")
                return
            end
        end
        if center.X - half.X < L.WindowEdgeMagnet then
            x = half.X + L.WindowMargin
        elseif ss.X - (center.X + half.X) < L.WindowEdgeMagnet then
            x = ss.X - half.X - L.WindowMargin
        end
        if center.Y - half.Y - top < L.WindowEdgeMagnet then
            y = top + L.WindowMargin + half.Y
        elseif ss.Y - (center.Y + half.Y) < L.WindowEdgeMagnet then
            y = ss.Y - half.Y - L.WindowMargin
        end
        if math.abs(x - center.X) > 0.5 or math.abs(y - center.Y) > 0.5 then
            Tween(Holder, Motion.Drop, { Position = UDim2.fromOffset(x, y) })
        end
    end

    function W:BindDrag(handle)
        handle.InputBegan:Connect(function(input)
            if not isPointer(input) then return end
            local start, origin = input.Position, Holder.Position
            local moved = false
            local moveConnection, endConnection
            moveConnection = UserInputService.InputChanged:Connect(function(changed)
                if not isMove(changed) then return end
                local delta = changed.Position - start
                moved = moved or delta.Magnitude > 2
                Holder.Position = UDim2.new(origin.X.Scale, origin.X.Offset + delta.X, origin.Y.Scale, origin.Y.Offset + delta.Y)
            end)
            endConnection = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then return end
                moveConnection:Disconnect()
                endConnection:Disconnect()
                if moved then dockWindow() end
            end)
        end)
    end
    BrandHeader.Active = true
    W:BindDrag(BrandHeader)

    ---------------------------------------------------------------------------------------------------
    -- Header buttons: minimise, and the theme gallery next to it
    ---------------------------------------------------------------------------------------------------
    local MinimizeButton = HeaderButton(Main, "Minimize", -14)
    local MinimizeBar = Themed(New("Frame", {
        Name = "Bar",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(11, 2),
        BorderSizePixel = 0,
        ZIndex = 21,
    }, MinimizeButton), { BackgroundColor3 = "TextPrimary" })
    Corner(MinimizeBar, 1)
    MinimizeButton.MouseEnter:Connect(function() Tween(MinimizeBar, Motion.Hover, { Size = UDim2.fromOffset(13, 2) }) end)
    MinimizeButton.MouseLeave:Connect(function() Tween(MinimizeBar, Motion.Hover, { Size = UDim2.fromOffset(11, 2) }) end)
    MinimizeButton.MouseButton1Click:Connect(function() Library:Toggle(false) end)

    local ThemeButton = HeaderButton(Main, "Themes", -14 - L.HeaderButton - 6)
    for i = 1, 4 do
        local column, row = (i - 1) % 2, math.floor((i - 1) / 2)
        local dot = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, column == 0 and -3.5 or 3.5, 0.5, row == 0 and -3.5 or 3.5),
            Size = UDim2.fromOffset(5, 5),
            BackgroundColor3 = Themes[ThemeOrder[i]].Accent,
            BorderSizePixel = 0,
            ZIndex = 21,
        }, ThemeButton)
        Corner(dot, 3)
    end

    local themeTiles = {}
    local function openThemeGallery()
        local rows = math.ceil(#ThemeOrder / 2)
        local width = 12 * 2 + THEME_TILE_WIDTH * 2 + THEME_TILE_GAP
        local height = 12 + 18 + 10 + rows * THEME_TILE_HEIGHT + (rows - 1) * THEME_TILE_GAP + 12
        local panel = New("Frame", { Name = "ThemeGallery", Size = UDim2.fromOffset(width, 0), ClipsDescendants = true }, nil)
        PopupMaterial(panel, 12, 40)
        W:PlacePopup(panel, ThemeButton, 8, height)
        Themed(Text(panel, {
            Text = "Themes",
            TextSize = 12,
            Position = UDim2.fromOffset(14, 12),
            Size = UDim2.new(1, -28, 0, 18),
            ZIndex = 2,
        }), { TextColor3 = "TextPrimary" })

        table.clear(themeTiles)
        for i, name in ipairs(ThemeOrder) do
            local theme = Themes[name]
            local column, row = (i - 1) % 2, math.floor((i - 1) / 2)
            local tile = New("TextButton", {
                Name = name,
                Text = "",
                AutoButtonColor = false,
                Position = UDim2.fromOffset(12 + column * (THEME_TILE_WIDTH + THEME_TILE_GAP), 40 + row * (THEME_TILE_HEIGHT + THEME_TILE_GAP)),
                Size = UDim2.fromOffset(THEME_TILE_WIDTH, THEME_TILE_HEIGHT),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 2,
            }, panel)
            Corner(tile, 9)
            New("UIGradient", {
                Rotation = 115,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, theme.PaneTop),
                    ColorSequenceKeypoint.new(0.5, theme.PaneMid),
                    ColorSequenceKeypoint.new(1, theme.PaneBottom),
                }),
            }, tile)
            local ring = Themed(New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Thickness = Library.Theme == name and 2 or 1,
            }, tile), {
                Color = function() return Library.Theme == name and Glass.Accent or theme.Rim end,
                Transparency = function() return Library.Theme == name and 0 or 0.55 end,
            })
            -- A miniature of the theme: a lens bar and an accent bead, as they'd appear in the sidebar.
            local lens = New("Frame", {
                Position = UDim2.fromOffset(8, 8),
                Size = UDim2.new(0.62, 0, 0, 10),
                BackgroundColor3 = theme.LensTint,
                BackgroundTransparency = 0.8,
                BorderSizePixel = 0,
                ZIndex = 3,
            }, tile)
            Corner(lens, 4)
            New("UIStroke", { Color = theme.Rim, Transparency = 0.5, Thickness = 1 }, lens)
            local bead = New("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -8, 0, 9),
                Size = UDim2.fromOffset(8, 8),
                BackgroundColor3 = theme.Accent,
                BorderSizePixel = 0,
                ZIndex = 3,
            }, tile)
            Corner(bead, 4)
            Text(tile, {
                Text = name,
                TextSize = 11,
                TextColor3 = theme.TextPrimary,
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 8, 1, -6),
                Size = UDim2.new(1, -16, 0, 14),
                ZIndex = 3,
            })
            local tileScale = New("UIScale", { Scale = 1 }, tile)
            tile.MouseEnter:Connect(function() Tween(tileScale, Motion.Pop, { Scale = 1.04 }) end)
            tile.MouseLeave:Connect(function() Tween(tileScale, Motion.Pop, { Scale = 1 }) end)
            tile.MouseButton1Click:Connect(function() Library:SetTheme(name) end)
            themeTiles[name] = ring
        end

        W:OpenPopup(panel, function()
            table.clear(themeTiles)
            Tween(panel, Motion.FadeOut, { Size = UDim2.fromOffset(width, 0) })
            task.delay(Motion.FadeOut.Time, function() panel:Destroy() end)
        end)
        Tween(panel, Motion.Reveal, { Size = UDim2.fromOffset(width, height) })
    end
    ThemeButton.MouseButton1Click:Connect(openThemeGallery)

    -- Palette button: opens the gradient editor directly, seeded from the current accent.
    local PaletteButton = HeaderButton(Main, "Palette", -14 - (L.HeaderButton + 6) * 2)
    PaletteGlyph(PaletteButton, 18, 21)
    local function themeStops()
        return { { color = Glass.AccentDeep, position = 0 }, { color = Glass.Accent, position = 1 } }
    end
    PaletteButton.MouseButton1Click:Connect(function()
        local stops = Library.AccentGradient and sequenceToStops(Library.AccentGradient) or themeStops()
        openPaletteEditor(W, PaletteButton, stops,
            function(sequence) Library:SetAccentGradient(sequence) end,
            function() Library:SetAccentGradient(nil) return themeStops() end)
    end)

    -- Cursor button: six drawn pointers plus the system default.
    local CursorButton = HeaderButton(Main, "Cursor", -14 - (L.HeaderButton + 6) * 4)
    local cursorGlyphA = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(3, 13),
        Rotation = 26,
        BorderSizePixel = 0,
        ZIndex = 21,
    }, CursorButton), { BackgroundColor3 = "TextPrimary" })
    Corner(cursorGlyphA, 2)
    local cursorGlyphB = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 3, 0.5, 4),
        Size = UDim2.fromOffset(4, 4),
        BorderSizePixel = 0,
        ZIndex = 22,
    }, CursorButton), { BackgroundColor3 = "Accent" })
    Corner(cursorGlyphB, 2)
    CursorButton.MouseButton1Click:Connect(function()
        if W.OpenCursors then W.OpenCursors(CursorButton) end
    end)

    -- Attachments button: the launcher for the info pods. Nothing is deployed until it's picked here.
    local AttachButton = HeaderButton(Main, "Attachments", -14 - (L.HeaderButton + 6) * 3)
    AttachButton.Visible = info.Satellites ~= false
    for i = 0, 2 do
        local bar = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0.5, -7 + i * 5),
            Size = UDim2.fromOffset(if i == 1 then 9 else 13, 3),
            BorderSizePixel = 0,
            ZIndex = 21,
        }, AttachButton), { BackgroundColor3 = "TextPrimary" })
        Corner(bar, 1)
    end
    AttachButton.MouseButton1Click:Connect(function()
        if W.OpenAttachments then W.OpenAttachments(AttachButton) end
    end)

    function W:OnThemeChanged()
        for name, ring in pairs(themeTiles) do
            ring.Thickness = Library.Theme == name and 2 or 1
        end
    end

    ---------------------------------------------------------------------------------------------------
    -- Keybind list, blur and scale
    ---------------------------------------------------------------------------------------------------
    self.KeybindFrame = BuildKeybindFrame(ScreenGui)

    local Blur
    if info.Blur then
        Blur = New("BlurEffect", { Name = "FishyUIBlur", Size = 0 }, Lighting)
    end
    W.Blur = Blur

    function W:FitScale()
        local vp = viewportSize()
        local s = Holder.Size
        local fit = math.min(1, vp.X * L.ViewportFill / s.X.Offset, vp.Y * L.ViewportFill / s.Y.Offset)
        return math.max(0.4, fit) * Library.DPIScale
    end

    function Window:_rescale()
        Scale.Scale = W:FitScale()
    end

    Telemetry.Start()
    BuildTabs(W)
    BuildBubble(W)
    if info.Satellites then BuildSatellites(W) end
    BuildAmbient(W) -- wraps W.OnThemeChanged, so it has to come after that is defined
    BuildCursor(W)
    BuildRail(W)

    local camera = Workspace.CurrentCamera
    if camera then
        Library:GiveSignal(camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            Window:_rescale()
            if W.OnViewportChanged then W.OnViewportChanged() end
        end))
    end

    Library:GiveSignal(UserInputService.InputBegan:Connect(function(input)
        if UserInputService:GetFocusedTextBox() then return end
        local key = resolveKeyCode(Library.ToggleKeybind)
        if key and input.KeyCode == key then Library:Toggle() end
    end))

    ---------------------------------------------------------------------------------------------------
    -- Public window API
    ---------------------------------------------------------------------------------------------------
    function Window:SetCornerRadius(radius)
        Library.CornerRadius = radius
        MainPane.Corner.CornerRadius = UDim.new(0, radius)
        MainPane.Specular.Size = UDim2.new(1, -radius * 4, 0, 1)
        MainPane.Edge.SliceScale = math.max(radius, 1) / L.SliceBaseRadius
        SheenCorner.CornerRadius = UDim.new(0, radius)
        -- The ambient layer clips its particles to this same corner.
        if W.AmbientCorner then W.AmbientCorner.CornerRadius = UDim.new(0, radius) end
    end

    function Window:SetFooter(text)
        FooterLabel.Text = text
    end

    function Window:SetTitle(text)
        TitleLabel.Text = text
    end

    function Window:SetAlwaysOnTop(value)
        Window.AlwaysOnTop = value
        ScreenGui.DisplayOrder = value and 1000 or 100
    end

    Window._W = W
    Window.Holder = Holder
    Window.Main = Main

    function Window:ShowSetup(callback)
        BuildSetupFlow(W, callback or function() Library:Toggle(true) end)
    end

    if info.AutoShow then
        if info.ThemeSelect == false then
            Library:Toggle(true)
        else
            -- The flow skips any step already dismissed with "Don't show this again", and opens the
            -- window immediately once every step has been.
            BuildSetupFlow(W, function() Library:Toggle(true) end)
        end
    end
    return Window
end

-- ===== 21_tabs.lua =====
-------------------------------------------------------------------------------------------------------
-- Tabs
--
-- The sidebar lists tabs; each tab opens a drawer of sub-tabs, one per groupbox or tabbox on its page.
-- Clicking a sub-tab glides the page to that card, and scrolling the page moves the sub-tab bead along.
-- Tabs are magnetic: press one and pull, and it lifts off the sidebar to be carried anywhere; the other
-- tabs part to open a gap, and on release it flies back and snaps in.
-------------------------------------------------------------------------------------------------------
BuildTabs = function(W)
    local Window, Sidebar, Content, DragLayer, Scale = W.Window, W.Sidebar, W.Content, W.DragLayer, W.Scale
    local CHIP_WIDTH = L.SidebarWidth - L.SidebarInset * 2
    local TabDrag -- the lifted tab, if any

    ---------------------------------------------------------------------------------------------------
    -- Active-tab lens and drop slot
    ---------------------------------------------------------------------------------------------------
    local IndicatorTrack = New("Frame", {
        Name = "Indicator",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, L.TabHeight),
        Visible = false,
        ZIndex = 6,
    }, Sidebar)
    local IndicatorLens, IndicatorEdge = GlassLens(IndicatorTrack, L.TabRadius, 6)
    local Indicator = LiquidMover(IndicatorTrack, IndicatorLens, Springs.TabLens, IndicatorEdge)
    Indicator:SetTarget(function()
        local tab = Window.ActiveTab
        if not tab then return 0 end
        -- While the active tab is carried, the lens waits in the gap where it will land.
        if TabDrag and TabDrag.tab == tab then return tab.SlotY end
        return tab.Entry.Position.Y.Offset
    end)

    local SlotTrack = New("Frame", {
        Name = "DropSlot",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, L.TabHeight),
        ZIndex = 5,
    }, Sidebar)
    local SlotBody = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, SlotTrack), { BackgroundColor3 = "LensTint" })
    Corner(SlotBody, L.TabRadius)
    local SlotRim = Themed(New("UIStroke", { Thickness = 1, Transparency = 1 }, SlotBody), { Color = "Rim" })
    local DropSlot = LiquidMover(SlotTrack, SlotBody, Springs.Slot)
    DropSlot:SetTarget(function() return TabDrag and TabDrag.tab.SlotY or 0 end)

    ---------------------------------------------------------------------------------------------------
    -- Layout
    ---------------------------------------------------------------------------------------------------
    local function drawerHeight(tab)
        if not tab.Open or #tab.Sections == 0 then return 0 end
        return L.DrawerPadTop + #tab.Sections * L.SubHeight + L.DrawerPadBottom
    end

    local function beadY(index)
        return L.DrawerPadTop + (index - 1) * L.SubHeight + (L.SubHeight - L.BeadHeight) / 2
    end

    -- Stacks tabs with each open drawer pushing the rest down. A `floating` tab (being carried) keeps a
    -- tab-height gap reserved but its entry is left where it is.
    local function layout(animate, order, floating, tweenInfo)
        local y = 0
        for _, tab in ipairs(order or Window.Tabs) do
            tab.SlotY = y
            if tab == floating then
                y += L.TabHeight + L.TabGap
            else
                local drawer = drawerHeight(tab)
                local entryGoal = { Position = UDim2.new(0.5, 0, 0, y), Size = UDim2.new(1, 0, 0, L.TabHeight + drawer) }
                local drawerGoal = { Size = UDim2.new(1, 0, 0, drawer) }
                if tab.EntryTween then
                    tab.EntryTween:Cancel()
                    tab.EntryTween = nil
                end
                if animate then
                    tab.EntryTween = Tween(tab.Entry, tweenInfo or Motion.Reflow, entryGoal)
                    Tween(tab.Drawer, tweenInfo or Motion.Reflow, drawerGoal)
                else
                    tab.Entry.Position, tab.Entry.Size = entryGoal.Position, entryGoal.Size
                    tab.Drawer.Size = drawerGoal.Size
                end
                y += L.TabHeight + drawer + L.TabGap
            end
        end
        Sidebar.CanvasSize = UDim2.fromOffset(0, math.max(0, y - L.TabGap))
        if animate then Indicator:Wake(0.7) else Indicator:Snap() end
    end

    local function paintTab(tab)
        local on = tab == Window.ActiveTab
        Tween(tab.Label, Motion.Hover, { TextColor3 = on and Glass.TextPrimary or Glass.TextSecondary })
        if tab.IconImage then
            Tween(tab.IconImage, Motion.Hover, { ImageColor3 = on and Glass.TextPrimary or Glass.Glyph })
        end
        for _, line in ipairs(tab.ChevronLines) do
            Tween(line, Motion.Hover, { BackgroundColor3 = on and Glass.TextSecondary or Glass.TextMuted })
        end
        Tween(tab.Hover, Motion.Hover, { BackgroundTransparency = 1 })
    end

    local function paintTabs()
        for _, tab in ipairs(Window.Tabs) do paintTab(tab) end
    end

    -- Drawer effects carry a per-tab token so delayed steps from an earlier open/close never land on top
    -- of a newer one when a tab is clicked quickly.
    local function openDrawerEffects(tab)
        tab.EffectToken += 1
        local token = tab.EffectToken
        Tween(tab.Chevron, Motion.Settle, { Rotation = 90 })
        Tween(tab.Rail, Motion.FadeIn, { BackgroundTransparency = 0.8 })
        for i, section in ipairs(tab.Sections) do
            local label = section.Label
            label.TextTransparency = 1
            label.Position = UDim2.fromOffset(L.SubLabelX + 8, 0)
            task.delay(0.06 + i * 0.035, function()
                if tab.EffectToken ~= token then return end
                Tween(label, Motion.FadeIn, { TextTransparency = 0, Position = UDim2.fromOffset(L.SubLabelX, 0) })
            end)
        end
        tab.BeadBody.BackgroundTransparency = 1
        tab.BeadGlow.ImageTransparency = 1
        task.delay(0.14, function()
            if tab.EffectToken ~= token then return end
            Tween(tab.BeadBody, Motion.FadeIn, { BackgroundTransparency = 0 })
            Tween(tab.BeadGlow, Motion.FadeIn, { ImageTransparency = 0.5 })
        end)
    end

    local function closeDrawerEffects(tab)
        tab.EffectToken += 1
        Tween(tab.Chevron, Motion.Settle, { Rotation = 0 })
        Tween(tab.Rail, Motion.FadeOut, { BackgroundTransparency = 1 })
        Tween(tab.BeadBody, Motion.FadeOut, { BackgroundTransparency = 1 })
        Tween(tab.BeadGlow, Motion.FadeOut, { ImageTransparency = 1 })
        for _, section in ipairs(tab.Sections) do
            Tween(section.Label, Motion.FadeOut, { TextTransparency = 1, Position = UDim2.fromOffset(L.SubLabelX, 0) })
        end
    end

    -- Cards materialise one after another when a page is opened, top of each column first, so the page
    -- assembles itself instead of appearing all at once. Only the glass fades — nothing here touches
    -- layout, so the cards never shift while they arrive.
    local function playPageIntro(tab)
        tab.IntroToken += 1
        local token = tab.IntroToken
        for i, section in ipairs(tab.Sections) do
            local card = section.Card
            local stroke = card:FindFirstChildOfClass("UIStroke")
            -- Rest values come from the theme tokens, never from the card's current transparency: a
            -- second intro starting while the first is still tweening would otherwise capture a
            -- mid-animation value and make that the card's permanent resting state.
            local function restCard() return math.min(Glass.CardTransparency, 0.9) end
            local function restStroke() return 0.6 + Glass.BorderTransparency * 0.5 end
            card.BackgroundTransparency = 1
            if stroke then stroke.Transparency = 1 end
            task.delay(0.03 + (i - 1) * 0.045, function()
                if tab.IntroToken ~= token then
                    -- Switched away before this card's turn: snap it back rather than strand it invisible.
                    card.BackgroundTransparency = restCard()
                    if stroke then stroke.Transparency = restStroke() end
                    return
                end
                Tween(card, Motion.Intro, { BackgroundTransparency = restCard() })
                if stroke then Tween(stroke, Motion.Intro, { Transparency = restStroke() }) end
            end)
        end
    end

    local function selectSection(tab, section, instant)
        local previous = tab.ActiveSection
        if previous == section then return end
        tab.ActiveSection = section
        if previous then Tween(previous.Label, Motion.Hover, { TextColor3 = Glass.TextMuted }) end
        tab.Bead:SetTarget(beadY(section.Index))
        if instant then
            section.Label.TextColor3 = Glass.TextPrimary
            tab.Bead:Snap()
        else
            Tween(section.Label, Motion.Hover, { TextColor3 = Glass.TextPrimary })
        end
    end

    ---------------------------------------------------------------------------------------------------
    -- Magnetic tabs
    ---------------------------------------------------------------------------------------------------
    -- Top-left of a tab slot in the window's own (unscaled) coordinates, allowing for sidebar scroll.
    local function slotInWindow(slotY)
        return Vector2.new(Sidebar.Position.X.Offset, Sidebar.Position.Y.Offset + slotY - Sidebar.CanvasPosition.Y)
    end

    -- Carries the lifted tab on a 2D spring so it has a little weight and leans into sideways motion like a
    -- card in hand. On release it homes in on its gap with a looser, bouncier spring, then lands.
    local Carrier = { entry = nil, x = 0, y = 0, vx = 0, vy = 0, tx = 0, ty = 0, rotation = 0, homing = nil, onLanded = nil }
    function Carrier:Step(dt)
        if self.homing then
            local home = self.homing()
            self.tx, self.ty = home.X, home.Y
        end
        local stiffness = self.homing and 240 or 700
        local damping = 2 * math.sqrt(stiffness) * (self.homing and 0.6 or 0.85)
        self.vx += (stiffness * (self.tx - self.x) - damping * self.vx) * dt
        self.vy += (stiffness * (self.ty - self.y) - damping * self.vy) * dt
        self.x += self.vx * dt
        self.y += self.vy * dt
        local lean = math.clamp(self.vx * 0.01, -7, 7)
        self.rotation += (lean - self.rotation) * math.min(1, dt * 14)

        local settled = math.abs(self.tx - self.x) < 0.3 and math.abs(self.ty - self.y) < 0.3
            and math.abs(self.vx) < 3 and math.abs(self.vy) < 3 and math.abs(self.rotation) < 0.1
        if not settled then return true end
        if self.homing then
            self.homing = nil
            local landed = self.onLanded
            self.onLanded = nil
            if landed then landed() end
        end
        return false
    end

    -- Landing hands the entry back to the sidebar and clears `entry`, so a chip that just landed is left
    -- where the sidebar put it.
    function Carrier:Render()
        if self.entry then
            self.entry.Position = UDim2.fromOffset(self.x + CHIP_WIDTH / 2, self.y)
            self.entry.Rotation = self.rotation
        end
        Indicator:Wake(0.1)
        DropSlot:Wake(0.1)
    end

    local function showDropSlot(visible)
        if visible then
            DropSlot:Snap()
            Tween(SlotBody, Motion.FadeIn, { BackgroundTransparency = 0.94 })
            Tween(SlotRim, Motion.FadeIn, { Transparency = 0.55 })
        else
            Tween(SlotBody, Motion.FadeOut, { BackgroundTransparency = 1 })
            Tween(SlotRim, Motion.FadeOut, { Transparency = 1 })
        end
    end

    -- Gap index for the carried tab's centre, measured against the other tabs laid out without it so the
    -- answer doesn't flicker as the gap opens and closes.
    local function slotFor(centerY, others)
        local y = 0
        for i, tab in ipairs(others) do
            local height = L.TabHeight + drawerHeight(tab)
            if centerY < y + height / 2 then return i end
            y += height + L.TabGap
        end
        return #others + 1
    end

    local function beginTabDrag(tab)
        if TabDrag then return end
        W:ClosePopup()
        local wasOpen = tab.Open
        if wasOpen then
            tab.Open = false
            tab.EffectToken += 1
            Tween(tab.Chevron, Motion.Settle, { Rotation = 0 })
        end
        -- A rotated frame stops clipping its children, so the drawer's contents are hidden outright.
        tab.Rail.BackgroundTransparency = 1
        tab.BeadBody.BackgroundTransparency = 1
        tab.BeadGlow.ImageTransparency = 1
        for _, section in ipairs(tab.Sections) do section.Label.TextTransparency = 1 end
        tab.Drawer.Size = UDim2.new(1, 0, 0, 0)
        if tab.EntryTween then
            tab.EntryTween:Cancel()
            tab.EntryTween = nil
        end

        local start = slotInWindow(tab.Entry.Position.Y.Offset)
        TabDrag = { tab = tab, wasOpen = wasOpen, start = start, order = table.clone(Window.Tabs) }
        TabDrag.slot = table.find(TabDrag.order, tab)

        tab.Entry.Parent = DragLayer
        tab.Entry.Size = UDim2.fromOffset(CHIP_WIDTH, L.TabHeight)
        tab.Entry.Position = UDim2.fromOffset(start.X + CHIP_WIDTH / 2, start.Y)

        Tween(tab.EntryScale, Motion.Pop, { Scale = L.LiftScale })
        Tween(tab.LiftShadow, Motion.Pop, { ImageTransparency = 0.35 })
        Tween(tab.LiftPlate, Motion.Pop, { BackgroundTransparency = 0.84 })
        Tween(tab.LiftRim, Motion.Pop, { Transparency = 0.35 })
        Tween(tab.Label, Motion.Hover, { TextColor3 = Glass.TextPrimary })
        Tween(tab.Hover, Motion.Hover, { BackgroundTransparency = 1 })
        Indicator:SetPressed(false)
        Sidebar.ScrollingEnabled = false
        if Window.ActiveTab ~= tab then showDropSlot(true) end

        Carrier.entry, Carrier.homing, Carrier.onLanded = tab.Entry, nil, nil
        Carrier.x, Carrier.y, Carrier.tx, Carrier.ty = start.X, start.Y, start.X, start.Y
        Carrier.vx, Carrier.vy, Carrier.rotation = 0, 0, 0
        Animator.Wake(Carrier)
        layout(true, TabDrag.order, tab, Motion.DragReflow)
    end

    -- `dx`/`dy`: pointer movement since the press, in unscaled window pixels.
    local function moveTabDrag(dx, dy)
        local drag = TabDrag
        if not drag or drag.releasing then return end
        local tab = drag.tab
        local x, y = drag.start.X + dx, drag.start.Y + dy

        local others = without(Window.Tabs, tab)
        local listCenter = y - Sidebar.Position.Y.Offset + Sidebar.CanvasPosition.Y + L.TabHeight / 2
        local slot = slotFor(listCenter, others)
        if slot ~= drag.slot then
            drag.slot = slot
            table.insert(others, slot, tab)
            drag.order = others
            layout(true, drag.order, tab, Motion.DragReflow)
            Tween(tab.EntryScale, Motion.Press, { Scale = L.LiftScale + 0.025 })
            task.delay(Motion.Press.Time, function()
                if TabDrag == drag and not drag.releasing then Tween(tab.EntryScale, Motion.Pop, { Scale = L.LiftScale }) end
            end)
        end

        -- Within MagnetRange of its gap the chip is pulled in, harder the closer it gets.
        local home = slotInWindow(tab.SlotY)
        local pull = math.clamp(1 - (Vector2.new(x, y) - home).Magnitude / L.MagnetRange, 0, 1)
        pull *= pull
        Carrier.tx, Carrier.ty = x + (home.X - x) * pull, y + (home.Y - y) * pull
        Animator.Wake(Carrier)
    end

    -- Flies the chip home and settles it back into the sidebar. `instant` lands it at once.
    local function endTabDrag(instant)
        local drag = TabDrag
        if not drag then return end
        local tab = drag.tab

        local function land()
            if TabDrag ~= drag then return end
            TabDrag = nil
            Carrier.entry, Carrier.homing, Carrier.onLanded = nil, nil, nil

            local changed = false
            for i, t in ipairs(drag.order) do
                if Window.Tabs[i] ~= t then
                    changed = true
                    break
                end
            end
            Window.Tabs = drag.order

            tab.Entry.Parent = Sidebar
            tab.Entry.Rotation = 0
            tab.Entry.Size = UDim2.new(1, 0, 0, L.TabHeight)
            tab.Entry.Position = UDim2.new(0.5, 0, 0, tab.SlotY)
            Tween(tab.EntryScale, Motion.Drop, { Scale = 1 })
            Tween(tab.LiftShadow, Motion.Settle, { ImageTransparency = 1 })
            Tween(tab.LiftPlate, Motion.Settle, { BackgroundTransparency = 1 })
            Tween(tab.LiftRim, Motion.Settle, { Transparency = 1 })
            showDropSlot(false)
            Sidebar.ScrollingEnabled = true

            if drag.wasOpen and Window.ActiveTab == tab and #tab.Sections > 0 then
                tab.Open = true
                openDrawerEffects(tab)
            end
            layout(true)
            paintTabs()
            if changed and Window.OnTabOrderChanged then
                task.spawn(Window.OnTabOrderChanged, Window:GetTabOrder())
            end
        end

        if instant then
            land()
            return
        end
        if drag.releasing then return end
        drag.releasing = true
        Tween(tab.EntryScale, Motion.Settle, { Scale = 1.02 })
        Carrier.homing = function() return slotInWindow(tab.SlotY) end
        Carrier.onLanded = land
        Animator.Wake(Carrier)
    end
    W.EndTabDrag = function() endTabDrag(true) end

    ---------------------------------------------------------------------------------------------------
    -- Tabs
    ---------------------------------------------------------------------------------------------------
    function Window:AddTab(name, icon, description)
        if typeof(name) == "table" then
            icon, description, name = name.Icon, name.Description, name.Name
        end

        local Tab = { Name = name, Description = description, Sections = {}, Open = false, EffectToken = 0, IntroToken = 0, SlotY = 0, CardOrder = 0 }
        local function isActive() return Window.ActiveTab == Tab end

        -----------------------------------------------------------------------------------------------
        -- Sidebar entry
        -----------------------------------------------------------------------------------------------
        local Entry = New("Frame", {
            Name = "Tab_" .. name,
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, L.TabHeight),
            ZIndex = 10,
        }, Sidebar)
        Tab.EntryScale = New("UIScale", { Scale = 1 }, Entry)
        Tab.LiftShadow = GlassShadow(Entry, 14, 1, 8)

        local Button = New("TextButton", {
            Name = "Button",
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, L.TabHeight),
            ZIndex = 10,
        }, Entry)

        Tab.LiftPlate = Themed(New("Frame", {
            Name = "LiftPlate",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 9,
        }, Button), { BackgroundColor3 = "LensTint" })
        Corner(Tab.LiftPlate, L.TabRadius)
        Tab.LiftRim = Themed(New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1, Transparency = 1 }, Tab.LiftPlate), { Color = "Rim" })

        local Hover = Themed(New("Frame", {
            Name = "Hover",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 9,
        }, Button), { BackgroundColor3 = "LensTint" })
        Corner(Hover, L.TabRadius)

        local image = resolveIcon(icon)
        if image then
            Tab.IconImage = Themed(New("ImageLabel", {
                Name = "Icon",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, L.RailX, 0.5, 0),
                Size = UDim2.fromOffset(L.IconSize, L.IconSize),
                BackgroundTransparency = 1,
                Image = image,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 11,
            }, Button), { ImageColor3 = function() return isActive() and Glass.TextPrimary or Glass.Glyph end })
        else
            local ring = New("Frame", {
                Name = "Icon",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, L.RailX, 0.5, 0),
                Size = UDim2.fromOffset(6, 6),
                BackgroundTransparency = 1,
                ZIndex = 11,
            }, Button)
            Corner(ring, 3)
            Themed(New("UIStroke", { Thickness = 1.2, Transparency = 0.2 }, ring), { Color = "Glyph" })
        end

        Tab.Label = Themed(Text(Button, {
            Name = "Label",
            Text = name,
            TextSize = 14,
            Position = UDim2.fromOffset(L.IconX + L.IconSize + 12, 0),
            Size = UDim2.new(1, -(L.IconX + L.IconSize + 12 + 28), 1, 0),
            ZIndex = 11,
        }), { TextColor3 = function() return isActive() and Glass.TextPrimary or Glass.TextSecondary end })

        Tab.Chevron, Tab.ChevronLines = Chevron(Button, 11)
        Tab.Chevron.Position = UDim2.new(1, -16, 0.5, 0)
        Tab.Chevron.Visible = false
        for _, line in ipairs(Tab.ChevronLines) do
            Themed(line, { BackgroundColor3 = function() return isActive() and Glass.TextSecondary or Glass.TextMuted end })
        end

        local Drawer = New("Frame", {
            Name = "Drawer",
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Position = UDim2.fromOffset(0, L.TabHeight),
            Size = UDim2.new(1, 0, 0, 0),
            ZIndex = 10,
        }, Entry)
        Tab.Rail = Themed(New("Frame", {
            Name = "Rail",
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.fromOffset(L.RailX, 0),
            Size = UDim2.fromOffset(1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 10,
        }, Drawer), { BackgroundColor3 = "Rim" })

        local BeadTrack = New("Frame", {
            Name = "Bead",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(L.RailX - L.BeadWidth / 2, 0),
            Size = UDim2.fromOffset(L.BeadWidth, L.BeadHeight),
            ZIndex = 11,
        }, Drawer)
        Tab.BeadGlow = Themed(New("ImageLabel", {
            Name = "Glow",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, 18, 1, 16),
            BackgroundTransparency = 1,
            Image = Assets.Spark,
            ImageTransparency = 1,
            ZIndex = 11,
        }, BeadTrack), { ImageColor3 = "Accent" })
        Tab.BeadBody = Themed(New("Frame", {
            Name = "Body",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 12,
        }, BeadTrack), { BackgroundColor3 = "Accent" })
        Corner(Tab.BeadBody, 2)
        Tab.Bead = LiquidMover(BeadTrack, Tab.BeadBody, Springs.Bead)

        Tab.Entry, Tab.Button, Tab.Hover, Tab.Drawer = Entry, Button, Hover, Drawer

        -----------------------------------------------------------------------------------------------
        -- Page: header, warning box, two columns of cards
        -----------------------------------------------------------------------------------------------
        local Page = New("Frame", {
            Name = "Page_" .. name,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Visible = false,
            ZIndex = 5,
        }, Content)
        local PageHeader = New("Frame", {
            Name = "Header",
            BackgroundTransparency = 1,
            Active = true,
            Size = UDim2.new(1, 0, 0, L.PageHeaderHeight),
            ZIndex = 5,
        }, Page)
        W:BindDrag(PageHeader)
        Themed(Text(PageHeader, {
            Text = name,
            TextSize = 20,
            Position = UDim2.fromOffset(L.PagePadding + 4, description and 12 or 0),
            -- Clears the header buttons (cursor, attachments, palette, themes, minimise) on the right.
            Size = UDim2.new(1, -(L.PagePadding + L.HeaderReserve), 0, description and 24 or L.PageHeaderHeight),
            ZIndex = 6,
        }), { TextColor3 = "TextPrimary" })
        if description then
            Themed(Text(PageHeader, {
                Text = description,
                FontFace = FONT_MEDIUM,
                TextSize = 12,
                Position = UDim2.fromOffset(L.PagePadding + 4, 36),
                Size = UDim2.new(1, -(L.PagePadding + L.HeaderReserve), 0, 16),
                ZIndex = 6,
            }), { TextColor3 = "TextMuted" })
        end

        local Scroller = New("ScrollingFrame", {
            Name = "Scroller",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, L.PageHeaderHeight),
            Size = UDim2.new(1, 0, 1, -L.PageHeaderHeight),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageTransparency = 0.5,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ZIndex = 5,
        }, Page)
        Themed(Scroller, { ScrollBarImageColor3 = "Accent" })
        New("UIPadding", {
            PaddingTop = UDim.new(0, 2),
            PaddingBottom = UDim.new(0, L.PagePadding),
            PaddingLeft = UDim.new(0, L.PagePadding),
            PaddingRight = UDim.new(0, L.PagePadding),
        }, Scroller)
        New("UIListLayout", { Padding = UDim.new(0, L.ColumnGap), SortOrder = Enum.SortOrder.LayoutOrder }, Scroller)

        local WarningBox = New("Frame", {
            Name = "WarningBox",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Glass.Warning,
            BackgroundTransparency = 0.9,
            BorderSizePixel = 0,
            LayoutOrder = 1,
            Visible = false,
        }, Scroller)
        Corner(WarningBox, L.CardRadius)
        local warningStroke = New("UIStroke", { Color = Glass.Warning, Transparency = 0.45, Thickness = 1 }, WarningBox)
        New("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 40),
            PaddingRight = UDim.new(0, 12),
        }, WarningBox)
        stackLayout(WarningBox, 2)
        local warningGlyph = New("TextLabel", {
            BackgroundColor3 = Glass.Warning,
            BorderSizePixel = 0,
            Position = UDim2.new(0, -28, 0, 1),
            Size = UDim2.fromOffset(18, 18),
            Text = "!",
            FontFace = FONT_BOLD,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(30, 20, 5),
            ZIndex = 3,
        }, WarningBox)
        Corner(warningGlyph, 9)
        local warningTitle = Text(WarningBox, { TextSize = 13, TextColor3 = Glass.Warning, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1 })
        local warningText = Themed(Text(WarningBox, {
            FontFace = FONT_MEDIUM,
            TextSize = 12,
            RichText = true,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.None,
            TextYAlignment = Enum.TextYAlignment.Top,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2,
        }), { TextColor3 = "TextSecondary" })

        local Columns = New("Frame", {
            Name = "Columns",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2,
        }, Scroller)
        local function column(side)
            local frame = New("Frame", {
                Name = side,
                BackgroundTransparency = 1,
                Position = UDim2.new(side == "Left" and 0 or 0.5, side == "Left" and 0 or L.ColumnGap / 2, 0, 0),
                Size = UDim2.new(0.5, -L.ColumnGap / 2, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
            }, Columns)
            New("UIListLayout", { Padding = UDim.new(0, L.ColumnGap), SortOrder = Enum.SortOrder.LayoutOrder }, frame)
            return frame
        end
        local LeftColumn, RightColumn = column("Left"), column("Right")
        Tab.Page, Tab.Scroller = Page, Scroller

        -- Scroll spy: the sub-tab bead follows whichever card has reached the top of the page.
        local programmaticScroll = 0
        Scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            if os.clock() < programmaticScroll or #Tab.Sections == 0 then return end
            -- Runs on every scrolled frame: each card's position is read once, not once per comparison.
            local top, scale = Scroller.AbsolutePosition.Y, Scale.Scale
            local current = Tab.Sections[1]
            local currentY = current.Card.AbsolutePosition.Y
            for _, section in ipairs(Tab.Sections) do
                local y = if section == Tab.Sections[1] then currentY else section.Card.AbsolutePosition.Y
                if (y - top) / scale <= 48 and y >= currentY then
                    current, currentY = section, y
                end
            end
            selectSection(Tab, current, false)
        end)

        local function scrollToSection(section)
            local offset = (section.Card.AbsolutePosition.Y - Scroller.AbsolutePosition.Y) / Scale.Scale + Scroller.CanvasPosition.Y - 2
            local maxScroll = math.max(0, Scroller.AbsoluteCanvasSize.Y / Scale.Scale - Scroller.AbsoluteSize.Y / Scale.Scale)
            programmaticScroll = os.clock() + Motion.Scroll.Time + 0.05
            Tween(Scroller, Motion.Scroll, { CanvasPosition = Vector2.new(0, math.clamp(offset, 0, maxScroll)) })
        end

        -----------------------------------------------------------------------------------------------
        -- Show / interaction
        -----------------------------------------------------------------------------------------------
        function Tab:Show()
            if TabDrag then return end
            W:ClosePopup()
            W:HideTooltip()
            if Window.ActiveTab == Tab then
                if #Tab.Sections > 0 then
                    Tab.Open = not Tab.Open
                    if Tab.Open then openDrawerEffects(Tab) else closeDrawerEffects(Tab) end
                    layout(true)
                end
                return
            end

            Window.ActiveTab = Tab
            playSound("Tab")
            for _, other in ipairs(Window.Tabs) do
                if other ~= Tab and other.Open then
                    other.Open = false
                    closeDrawerEffects(other)
                end
                other.Page.Visible = other == Tab
            end
            Scroller.Position = UDim2.fromOffset(0, L.PageHeaderHeight + 10)
            Tween(Scroller, Motion.Settle, { Position = UDim2.fromOffset(0, L.PageHeaderHeight) })
            playPageIntro(Tab)
            if #Tab.Sections > 0 then
                Tab.Open = true
                openDrawerEffects(Tab)
            end
            layout(true)
            paintTabs()
        end

        Button.MouseEnter:Connect(function()
            if Window.ActiveTab ~= Tab and not TabDrag then
                Tween(Hover, Motion.Hover, { BackgroundTransparency = 0.94 })
                Tween(Tab.Label, Motion.Hover, { TextColor3 = Glass.TextPrimary })
            end
        end)
        Button.MouseLeave:Connect(function()
            Tween(Hover, Motion.Hover, { BackgroundTransparency = 1 })
            if Window.ActiveTab ~= Tab and not (TabDrag and TabDrag.tab == Tab) then
                Tween(Tab.Label, Motion.Hover, { TextColor3 = Glass.TextSecondary })
            end
            Indicator:SetPressed(false)
        end)
        Button.MouseButton1Down:Connect(function()
            if Window.ActiveTab == Tab and not TabDrag then Indicator:SetPressed(true) end
        end)
        Button.MouseButton1Up:Connect(function() Indicator:SetPressed(false) end)
        Button.MouseButton1Click:Connect(function()
            -- The release that ends a carry also fires a click; that one must not switch tabs.
            if Tab.SuppressClick then
                Tab.SuppressClick = false
                return
            end
            Tab:Show()
        end)

        -- Press and pull past DragSlop to pick the tab up; a press that doesn't travel is a plain click.
        Button.InputBegan:Connect(function(input)
            if not isPointer(input) or TabDrag then return end
            Tab.SuppressClick = false
            local start = input.Position
            local lifted = false
            local moveConnection, endConnection
            moveConnection = UserInputService.InputChanged:Connect(function(changed)
                if not isMove(changed) then return end
                local delta = changed.Position - start
                if not lifted then
                    if delta.Magnitude < L.DragSlop or TabDrag then return end
                    lifted = true
                    Tab.SuppressClick = true
                    beginTabDrag(Tab)
                end
                moveTabDrag(delta.X / Scale.Scale, delta.Y / Scale.Scale)
            end)
            endConnection = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then return end
                moveConnection:Disconnect()
                endConnection:Disconnect()
                if lifted then endTabDrag() end
            end)
        end)

        -----------------------------------------------------------------------------------------------
        -- Sections (sub-tabs)
        -----------------------------------------------------------------------------------------------
        local function addSection(sectionName, card)
            local index = #Tab.Sections + 1
            local Section = { Name = sectionName, Index = index, Card = card }

            local SubButton = New("TextButton", {
                Name = "Sub_" .. sectionName,
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, L.DrawerPadTop + (index - 1) * L.SubHeight),
                Size = UDim2.new(1, 0, 0, L.SubHeight),
                ZIndex = 11,
            }, Drawer)
            Section.Label = Themed(Text(SubButton, {
                Name = "Label",
                Text = sectionName,
                FontFace = FONT_MEDIUM,
                TextSize = 13,
                TextTransparency = Tab.Open and 0 or 1,
                Position = UDim2.fromOffset(L.SubLabelX, 0),
                Size = UDim2.new(1, -(L.SubLabelX + 8), 1, 0),
                ZIndex = 12,
            }), { TextColor3 = function() return Tab.ActiveSection == Section and Glass.TextPrimary or Glass.TextMuted end })

            SubButton.MouseEnter:Connect(function()
                if Tab.ActiveSection ~= Section then Tween(Section.Label, Motion.Hover, { TextColor3 = Glass.TextSecondary }) end
            end)
            SubButton.MouseLeave:Connect(function()
                if Tab.ActiveSection ~= Section then Tween(Section.Label, Motion.Hover, { TextColor3 = Glass.TextMuted }) end
            end)
            SubButton.MouseButton1Click:Connect(function()
                selectSection(Tab, Section, false)
                scrollToSection(Section)
            end)

            table.insert(Tab.Sections, Section)
            Tab.Rail.Size = UDim2.fromOffset(1, L.DrawerPadTop + (index - 0.5) * L.SubHeight)
            Tab.Chevron.Visible = true

            if not Tab.ActiveSection then selectSection(Tab, Section, true) end
            if Window.ActiveTab == Tab and not Tab.Open then
                Tab.Open = true
                Tab.Chevron.Rotation = 90
                Tab.Rail.BackgroundTransparency = 0.8
                Tab.BeadBody.BackgroundTransparency = 0
                Tab.BeadGlow.ImageTransparency = 0.5
                for _, s in ipairs(Tab.Sections) do s.Label.TextTransparency = 0 end
            end
            layout(false)
            return Section
        end

        local function nextCardOrder()
            Tab.CardOrder += 1
            return Tab.CardOrder
        end

        function Tab:AddLeftGroupbox(groupName, groupIcon)
            local groupbox = newGroupbox(W, LeftColumn, groupName, groupIcon, nextCardOrder())
            addSection(groupName, groupbox.Card)
            return groupbox
        end

        function Tab:AddRightGroupbox(groupName, groupIcon)
            local groupbox = newGroupbox(W, RightColumn, groupName, groupIcon, nextCardOrder())
            addSection(groupName, groupbox.Card)
            return groupbox
        end

        local function addTabbox(columnFrame, tabboxName)
            local tabbox = newTabbox(W, columnFrame, nextCardOrder())
            local section = addSection(tabboxName or "Tabbox", tabbox.Card)
            local addTab = tabbox.AddTab
            function tabbox:AddTab(tabName)
                local tab = addTab(tabbox, tabName)
                if not tabboxName then
                    local names = {}
                    for _, t in ipairs(tabbox.Tabs) do table.insert(names, t.Name) end
                    section.Label.Text = table.concat(names, " / ")
                end
                return tab
            end
            return tabbox
        end

        function Tab:AddLeftTabbox(tabboxName) return addTabbox(LeftColumn, tabboxName) end
        function Tab:AddRightTabbox(tabboxName) return addTabbox(RightColumn, tabboxName) end

        function Tab:UpdateWarningBox(warning)
            warning = warning or {}
            WarningBox.Visible = warning.Visible ~= false
            local tone = warning.IsNormal and Glass.Accent or Glass.Warning
            WarningBox.BackgroundColor3 = tone
            warningStroke.Color = tone
            warningGlyph.BackgroundColor3 = tone
            warningGlyph.Text = warning.IsNormal and "i" or "!"
            warningTitle.TextColor3 = tone
            warningTitle.Text = warning.Title or "Notice"
            warningText.Text = warning.Text or ""
        end

        function Tab:SelectSection(sectionName)
            for _, section in ipairs(Tab.Sections) do
                if section.Name == sectionName then
                    selectSection(Tab, section, false)
                    scrollToSection(section)
                    return
                end
            end
        end

        table.insert(Window.Tabs, Tab)
        if not Window.ActiveTab then
            Window.ActiveTab = Tab
            Page.Visible = true
            IndicatorTrack.Visible = true
        end
        layout(false)
        -- Adding a tab never changes which one is active, so only the new tab needs painting. Repainting
        -- them all made building N tabs start N² tweens.
        paintTab(Tab)
        return Tab
    end

    function Window:GetTabOrder()
        local names = {}
        for i, tab in ipairs(Window.Tabs) do names[i] = tab.Name end
        return names
    end

    -- Reorders tabs by name (e.g. an order saved from OnTabOrderChanged). Unknown names are ignored and
    -- tabs missing from the list keep their relative order at the end.
    function Window:SetTabOrder(names)
        if TabDrag then return end
        local byName, ordered, used = {}, {}, {}
        for _, tab in ipairs(Window.Tabs) do byName[tab.Name] = tab end
        for _, tabName in ipairs(names) do
            local tab = byName[tabName]
            if tab and not used[tab] then
                table.insert(ordered, tab)
                used[tab] = true
            end
        end
        for _, tab in ipairs(Window.Tabs) do
            if not used[tab] then table.insert(ordered, tab) end
        end
        Window.Tabs = ordered
        layout(true)
    end
end

-- ===== 22_bubble.lua =====
-------------------------------------------------------------------------------------------------------
-- Bubble
--
-- Minimising hands the glass to a bubble at the window's exact size and shrinks it into a draggable pill
-- showing signal strength, ping and region. Hovering the pill widens it to reveal FPS and session time;
-- tapping it grows it back out into the window. Released near a screen edge, it docks onto that edge.
-------------------------------------------------------------------------------------------------------
BuildBubble = function(W)
    local Window, Holder, Scale, ScreenGui, info = W.Window, W.Holder, W.Scale, W.ScreenGui, W.Info

    local bubbleText = info.BubbleText or ((info.Title ~= "" and info.Title) or "Menu")
    local signalWidth = L.SignalBarWidth * 3 + L.SignalBarGap * 2
    local labelX = 16 + signalWidth + 10
    local dividerX = labelX + textWidth(bubbleText, 14, Enum.Font.GothamBold) + 12
    local pingX = dividerX + 13
    local regionX = pingX + textWidth("999 ms", 12, Enum.Font.GothamMedium) + 8
    local collapsedWidth = regionX + textWidth("WW", 12, Enum.Font.GothamMedium) + 16
    local extraDividerX = collapsedWidth - 4
    local fpsX = extraDividerX + 13
    local sessionX = fpsX + textWidth("240 fps", 12, Enum.Font.GothamMedium) + 10
    local expandedWidth = sessionX + textWidth("00:00:00", 12, Enum.Font.RobotoMono) + 18
    local bubbleRadius = L.BubbleHeight / 2

    local BubbleHolder = New("Frame", {
        Name = "Bubble",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(collapsedWidth, L.BubbleHeight),
        Visible = false,
        ZIndex = 200,
    }, ScreenGui)
    local BubbleScale = New("UIScale", { Scale = 1 }, BubbleHolder)
    local ContentAlpha = New("NumberValue", { Name = "ContentAlpha", Value = 0 }, BubbleHolder)
    local ExtraAlpha = New("NumberValue", { Name = "ExtraAlpha", Value = 0 }, BubbleHolder)
    GlassShadow(BubbleHolder, 17, "ShadowTransparency", 1)

    local Body = New("Frame", {
        Name = "Body",
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        ZIndex = 2,
    }, BubbleHolder)
    local Pane = PaneMaterial(Body, bubbleRadius, 50)
    -- Kept fairly opaque so the readout stays legible over the game on see-through themes.
    Themed(Body, { BackgroundTransparency = function() return math.min(Glass.PaneTransparency, 0.12) end })

    local signalBars = {}
    for i, height in ipairs(L.SignalBarHeights) do
        local bar = New("Frame", {
            Name = "SignalBar" .. i,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 16 + (i - 1) * (L.SignalBarWidth + L.SignalBarGap), 0.5, 7),
            Size = UDim2.fromOffset(L.SignalBarWidth, height),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 60,
        }, Body)
        Corner(bar, 1)
        signalBars[i] = { Frame = bar, Height = height }
    end

    local function divider(x)
        return Themed(New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, x, 0.5, 0),
            Size = UDim2.fromOffset(1, 18),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 60,
        }, Body), { BackgroundColor3 = "Rim" })
    end

    local function stat(name, text, x, width, font, token)
        return Themed(Text(Body, {
            Name = name,
            Text = text,
            FontFace = font,
            TextSize = 12,
            TextTransparency = 1,
            TextTruncate = Enum.TextTruncate.None,
            Position = UDim2.fromOffset(x, 0),
            Size = UDim2.new(0, width, 1, 0),
            ZIndex = 60,
        }), { TextColor3 = token })
    end

    local Label = Themed(Text(Body, {
        Name = "Label",
        Text = bubbleText,
        TextSize = 14,
        TextTransparency = 1,
        Position = UDim2.fromOffset(labelX, 0),
        Size = UDim2.new(0, dividerX - labelX - 6, 1, 0),
        ZIndex = 60,
    }), { TextColor3 = "TextPrimary" })
    local Divider = divider(dividerX)
    local PingLabel = stat("Ping", "-- ms", pingX, regionX - pingX, FONT_MEDIUM, "TextPrimary")
    local RegionLabel = stat("Region", "--", regionX, collapsedWidth - regionX, FONT_MEDIUM, "TextSecondary")
    local ExtraDivider = divider(extraDividerX)
    local FpsLabel = stat("Fps", "0 fps", fpsX, sessionX - fpsX, FONT_MEDIUM, "TextSecondary")
    local SessionLabel = stat("Session", "00:00:00", sessionX, expandedWidth - sessionX, FONT_MONO, "TextPrimary")

    local Hitbox = New("TextButton", {
        Name = "Hitbox",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 70,
    }, Body)

    local strength = 0
    local function refresh()
        local ping = Telemetry.Ping
        PingLabel.Text = ping and string.format("%d ms", math.floor(ping + 0.5)) or "-- ms"
        strength = Telemetry.Strength(ping)
        RegionLabel.Text = Telemetry.Region
        FpsLabel.Text = string.format("%d fps", Telemetry.Fps)
        SessionLabel.Text = Telemetry.Clock(os.clock() - Telemetry.SessionStart)
    end
    Telemetry.OnTick(function()
        if BubbleHolder.Visible then refresh() end
    end)

    -- Content fades through ContentAlpha (extras also through ExtraAlpha), and every couple of seconds a
    -- pulse of light runs up the lit signal bars, like a signal being received.
    --
    -- The bubble is what stays on screen while you play, so this runs for as long as the menu is tucked
    -- away. Once the fades settle almost nothing here changes from frame to frame (only a bar mid-pulse),
    -- so writes go through a cache and the unchanged ones are dropped.
    local clock = 0
    local put = PropertyCache()
    local function fade(rest, a) return 1 - (1 - rest) * a end
    Library:GiveSignal(RunService.Heartbeat:Connect(function(dt)
        if not BubbleHolder.Visible then return end
        clock += dt
        local alpha = ContentAlpha.Value
        local extra = alpha * ExtraAlpha.Value
        put(Label, "TextTransparency", fade(0, alpha))
        put(PingLabel, "TextTransparency", fade(0, alpha))
        put(RegionLabel, "TextTransparency", fade(0.15, alpha))
        put(Divider, "BackgroundTransparency", fade(0.78, alpha))
        put(ExtraDivider, "BackgroundTransparency", fade(0.78, extra))
        put(FpsLabel, "TextTransparency", fade(0.1, extra))
        put(SessionLabel, "TextTransparency", fade(0, extra))

        local color = Telemetry.StrengthColor(strength)
        for i, bar in ipairs(signalBars) do
            local lit = i <= strength
            local phase = (clock * 1.1 - (i - 1) * 0.16) % 1.8
            local pulse = if phase < 0.4 then math.sin(phase / 0.4 * math.pi) else 0
            put(bar.Frame, "Size", UDim2.fromOffset(L.SignalBarWidth, bar.Height + (if lit then pulse * 2 else 0)))
            put(bar.Frame, "BackgroundColor3", if lit then color else Glass.Glyph)
            put(bar.Frame, "BackgroundTransparency", fade(if lit then 0.12 * (1 - pulse) else 0.72, alpha))
        end
    end))

    local function screenSize() return ScreenGui.AbsoluteSize end

    local function clampCenter(center, width)
        local ss = screenSize()
        local halfW, halfH = (width or collapsedWidth) / 2 + L.BubbleMargin, L.BubbleHeight / 2 + L.BubbleMargin
        return Vector2.new(
            math.clamp(center.X, halfW, math.max(halfW, ss.X - halfW)),
            math.clamp(center.Y, halfH, math.max(halfH, ss.Y - halfH))
        )
    end

    -- Released near a screen edge, the bubble is drawn flush onto it.
    local function dock(center)
        local ss = screenSize()
        local halfW, halfH = expandedWidth / 2 + L.BubbleMargin, L.BubbleHeight / 2 + L.BubbleMargin
        local x, y = center.X, center.Y
        if x - halfW < L.BubbleEdgeMagnet then x = halfW elseif ss.X - halfW - x < L.BubbleEdgeMagnet then x = ss.X - halfW end
        if y - halfH < L.BubbleEdgeMagnet then y = halfH elseif ss.Y - halfH - y < L.BubbleEdgeMagnet then y = ss.Y - halfH end
        return clampCenter(Vector2.new(x, y))
    end

    local function defaultCenter()
        return clampCenter(Vector2.new(screenSize().X / 2, GuiService:GetGuiInset().Y + L.BubbleMargin + L.BubbleHeight / 2))
    end

    local function windowShape()
        local ss, p, s, scale = screenSize(), Holder.Position, Holder.Size, W:FitScale()
        local center = Vector2.new(p.X.Scale * ss.X + p.X.Offset, p.Y.Scale * ss.Y + p.Y.Offset)
        return center, Vector2.new(s.X.Offset, s.Y.Offset) * scale, Library.CornerRadius * scale
    end

    local function shape(center, shapeSize, radius, tweenInfo)
        local goals = {
            { BubbleHolder, { Position = UDim2.fromOffset(center.X, center.Y), Size = UDim2.fromOffset(shapeSize.X, shapeSize.Y) } },
            { Pane.Corner, { CornerRadius = UDim.new(0, radius) } },
            { Pane.Edge, { SliceScale = math.max(radius, 1) / L.SliceBaseRadius } },
            { Pane.Specular, { Size = UDim2.new(1, -radius * 4, 0, 1) } },
        }
        for _, pair in ipairs(goals) do
            if tweenInfo then
                Tween(pair[1], tweenInfo, pair[2])
            else
                for property, value in pairs(pair[2]) do pair[1][property] = value end
            end
        end
    end

    local bubbleCenter
    local expanded, morphing = false, false
    local shownOnce = false
    local morphToken = 0

    local function displayCenter()
        return if expanded then clampCenter(bubbleCenter, expandedWidth) else bubbleCenter
    end

    local function setExpanded(on)
        if expanded == on or morphing or not BubbleHolder.Visible or not bubbleCenter then return end
        expanded = on
        local width = on and expandedWidth or collapsedWidth
        local center = displayCenter()
        Tween(BubbleHolder, Motion.Reveal, {
            Size = UDim2.fromOffset(width, L.BubbleHeight),
            Position = UDim2.fromOffset(center.X, center.Y),
        })
        Tween(ExtraAlpha, on and Motion.FadeIn or Motion.FadeOut, { Value = on and 1 or 0 })
    end

    local function notifyVisibility(visible)
        if W.OnWindowVisibility then W.OnWindowVisibility(visible) end
    end

    function Window:_setVisible(visible)
        morphToken += 1
        local token = morphToken
        if W.Blur then Tween(W.Blur, Motion.Blur, { Size = visible and info.BlurSize or 0 }) end
        if not visible then
            W:ClosePopup()
            W:HideTooltip()
        end

        if not info.Bubble or not shownOnce then
            if visible then
                shownOnce = true
                Scale.Scale = W:FitScale()
            end
            Holder.Visible = visible
            notifyVisibility(visible)
            return
        end

        W.EndTabDrag()
        bubbleCenter = bubbleCenter or defaultCenter()
        local center, shapeSize, radius = windowShape()
        morphing = true
        -- The bubble rests fully open; hovering it tucks the extra stats away.
        expanded = true

        if not visible then
            if Holder.Visible then
                shape(center, shapeSize, radius)
                ContentAlpha.Value = 0
                ExtraAlpha.Value = 0
                BubbleScale.Scale = 1
            end
            refresh()
            Holder.Visible = false
            notifyVisibility(false)
            BubbleHolder.Visible = true
            shape(clampCenter(bubbleCenter, expandedWidth), Vector2.new(expandedWidth, L.BubbleHeight), bubbleRadius, Motion.Collapse)
            task.delay(Motion.Collapse.Time * 0.55, function()
                if token == morphToken then
                    Tween(ContentAlpha, Motion.FadeIn, { Value = 1 })
                    Tween(ExtraAlpha, Motion.FadeIn, { Value = 1 })
                end
            end)
            task.delay(Motion.Collapse.Time, function()
                if token == morphToken then morphing = false end
            end)
        else
            if Holder.Visible then
                morphing = false
                return
            end
            Tween(ContentAlpha, Motion.FadeOut, { Value = 0 })
            Tween(ExtraAlpha, Motion.FadeOut, { Value = 0 })
            shape(center, shapeSize, radius, Motion.Expand)
            task.delay(Motion.Expand.Time, function()
                if token ~= morphToken then return end
                morphing = false
                BubbleHolder.Visible = false
                local target = W:FitScale()
                Scale.Scale = target * 0.985
                Holder.Visible = true
                Tween(Scale, Motion.Hover, { Scale = target })
                notifyVisibility(true)
            end)
        end
    end

    -- Tap to restore; drag to move it anywhere. A drag that ends near an edge docks.
    local press
    Hitbox.InputBegan:Connect(function(input)
        if not isPointer(input) then return end
        press = { start = input.Position, center = bubbleCenter or defaultCenter(), moved = false }
        Tween(BubbleScale, Motion.Press, { Scale = 0.94 })
        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState ~= Enum.UserInputState.End then return end
            connection:Disconnect()
            local released = press
            press = nil
            if not released then return end
            Tween(BubbleScale, Motion.Drop, { Scale = 1 })
            if released.moved then
                bubbleCenter = dock(bubbleCenter)
                local center = displayCenter()
                Tween(BubbleHolder, Motion.Drop, { Position = UDim2.fromOffset(center.X, center.Y) })
            else
                Library:Toggle(true)
            end
        end)
    end)
    Hitbox.MouseEnter:Connect(function()
        Tween(Pane.Edge, Motion.Hover, { ImageTransparency = 0.22 })
        setExpanded(false)
    end)
    Hitbox.MouseLeave:Connect(function()
        Tween(Pane.Edge, Motion.Hover, { ImageTransparency = Glass.EdgeTransparency })
        if not press then setExpanded(true) end
    end)
    Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
        if not press or not isMove(input) then return end
        local delta = input.Position - press.start
        if not press.moved and delta.Magnitude < L.TapSlop then return end
        press.moved = true
        bubbleCenter = clampCenter(press.center + Vector2.new(delta.X, delta.Y))
        local center = displayCenter()
        BubbleHolder.Position = UDim2.fromOffset(center.X, center.Y)
    end))

    local previousViewport = W.OnViewportChanged
    W.OnViewportChanged = function()
        if previousViewport then previousViewport() end
        if not bubbleCenter then return end
        bubbleCenter = clampCenter(bubbleCenter)
        if BubbleHolder.Visible and not morphing then
            local center = displayCenter()
            BubbleHolder.Position = UDim2.fromOffset(center.X, center.Y)
        end
    end

    Window.Bubble = BubbleHolder
end

-- ===== 23_satellites.lua =====
-------------------------------------------------------------------------------------------------------
-- Satellites
--
-- Small glass pods carrying live info. Nothing is deployed by default: the Attachments button in the
-- header opens a launcher, and you either click a row to deploy it or drag the row straight out of the
-- list to place it yourself.
--
-- A deployed pod can dock to any of the window's four sides, trailing it on a spring as it moves. If a
-- side has no room on screen the pod crosses to the opposite side, and if neither fits it is clamped
-- into view and its connectors fade out, so a pod is never shown tethered to nothing.
-------------------------------------------------------------------------------------------------------
local POD_W, POD_H = 176, 100
local POD_GAP = 10 -- window edge to a docked pod
local POD_STACK_GAP = 10
local POD_EDGE_INSET = 16 -- first pod's offset along the window edge
local POD_MAGNET = 110 -- screen px: a carried pod this close to a side docks there
local GRAPH_BARS, GRAPH_HEIGHT, GRAPH_GAP = 28, 28, 2
local SIDES = { "Right", "Left", "Top", "Bottom" }

-- Pods float over gameplay rather than over the window's own glass, so the muted greys that read fine
-- inside a card wash out here. Every pod label is lifted toward the primary text colour, which is what
-- rescues the flatter, lower-contrast themes (Midnight, Onyx, Smoke) without touching the rest of the UI.
-- Pushed most of the way to the primary colour rather than a little: a pod's glass is darker than a card
-- inside the window, and the muted greys that survive there read as switched-off out here even when the
-- measured contrast says otherwise.
local POD_LABEL = mixToken("TextMuted", "TextPrimary", 0.8)
local POD_SUB = mixToken("TextSecondary", "TextPrimary", 0.55)

local function isVertical(side)
    return side == "Left" or side == "Right"
end

BuildSatellites = function(W)
    local ScreenGui, Holder, Scale = W.ScreenGui, W.Holder, W.Scale
    local pods = {}
    local carry -- { pod, side, index, slot }

    -- The screen, window and inset numbers every placement starts from. A docking pass needs them for every
    -- pod and side, so it reads them once and passes them down; the other callers just read them fresh.
    local function geometry()
        return {
            screen = ScreenGui.AbsoluteSize,
            position = Holder.Position,
            size = Holder.Size,
            k = Scale.Scale,
            top = GuiService:GetGuiInset().Y,
        }
    end

    local function windowRect(g)
        g = g or geometry()
        local ss, p, s, k = g.screen, g.position, g.size, g.k
        local size = Vector2.new(s.X.Offset, s.Y.Offset) * k
        local center = Vector2.new(p.X.Scale * ss.X + p.X.Offset, p.Y.Scale * ss.Y + p.Y.Offset)
        return center - size / 2, size
    end

    -- Top-left of the first slot on a side, and the step between slots.
    local function sideGeometry(side, g)
        g = g or geometry()
        local topLeft, size = windowRect(g)
        local k = g.k
        if side == "Right" then
            return Vector2.new(topLeft.X + size.X + POD_GAP * k, topLeft.Y + POD_EDGE_INSET * k), Vector2.new(0, (POD_H + POD_STACK_GAP) * k)
        elseif side == "Left" then
            return Vector2.new(topLeft.X - (POD_W + POD_GAP) * k, topLeft.Y + POD_EDGE_INSET * k), Vector2.new(0, (POD_H + POD_STACK_GAP) * k)
        elseif side == "Top" then
            return Vector2.new(topLeft.X + POD_EDGE_INSET * k, topLeft.Y - (POD_H + POD_GAP) * k), Vector2.new((POD_W + POD_STACK_GAP) * k, 0)
        end
        return Vector2.new(topLeft.X + POD_EDGE_INSET * k, topLeft.Y + size.Y + POD_GAP * k), Vector2.new((POD_W + POD_STACK_GAP) * k, 0)
    end

    local function opposite(side)
        if side == "Left" then return "Right" end
        if side == "Right" then return "Left" end
        if side == "Top" then return "Bottom" end
        return "Top"
    end

    local function fitsOnScreen(position, g)
        g = g or geometry()
        local ss, k = g.screen, g.k
        return position.X >= 0 and position.Y >= g.top
            and position.X + POD_W * k <= ss.X and position.Y + POD_H * k <= ss.Y
    end

    -- The side a pod actually renders on: its own, or the opposite one when there's no room.
    local function renderSide(side, g)
        g = g or geometry()
        local anchor = sideGeometry(side, g)
        if fitsOnScreen(anchor, g) then return side end
        local other = opposite(side)
        if fitsOnScreen((sideGeometry(other, g)), g) then return other end
        return side
    end

    local function clampToScreen(position, g)
        g = g or geometry()
        local ss, k = g.screen, g.k
        local margin = L.BubbleMargin
        local top = g.top + margin
        return Vector2.new(
            math.clamp(position.X, margin, math.max(margin, ss.X - POD_W * k - margin)),
            math.clamp(position.Y, top, math.max(top, ss.Y - POD_H * k - margin))
        )
    end

    -- Deployed, docked pods grouped by the side they render on.
    local function columns(g)
        g = g or geometry()
        local result = {}
        for _, side in ipairs(SIDES) do result[side] = {} end
        for _, pod in ipairs(pods) do
            if pod.Deployed and pod.Docked and pod ~= (carry and carry.pod) then
                table.insert(result[renderSide(pod.Side, g)], pod)
            end
        end
        for _, side in ipairs(SIDES) do
            table.sort(result[side], function(a, b) return a.Order < b.Order end)
        end
        return result
    end

    -- Where each docked pod belongs right now, plus a reserved gap for a pod being carried onto a side.
    local function dockTargets(g)
        g = g or geometry()
        local targets, attached = {}, {}
        local grouped = columns(g)
        for _, side in ipairs(SIDES) do
            local column = grouped[side]
            if carry and carry.side == side then
                table.insert(column, math.clamp(carry.index, 1, #column + 1), carry)
            end
            local origin, step = sideGeometry(side, g)
            for i, item in ipairs(column) do
                local ideal = origin + step * (i - 1)
                local clamped = clampToScreen(ideal, g)
                if item == carry then
                    carry.slot = clamped
                else
                    targets[item] = clamped
                    attached[item] = (clamped - ideal).Magnitude < 0.5
                    item.RenderSide = side
                end
            end
        end
        return targets, attached
    end

    -- Pods read their dock slots on every physics substep, and computing them walks every pod and reads the
    -- window and screen geometry each time. Nothing those slots depend on can change partway through an
    -- animator frame, so the result is shared by every pod and substep of that frame.
    local frameAt, frameGeometry, frameTargets, frameAttached = -1, nil, nil, nil
    local function geometryThisFrame()
        if frameAt ~= Animator.frame then
            frameAt, frameGeometry, frameTargets, frameAttached = Animator.frame, geometry(), nil, nil
        end
        return frameGeometry
    end
    local function dockTargetsThisFrame()
        local g = geometryThisFrame()
        if not frameTargets then frameTargets, frameAttached = dockTargets(g) end
        return frameTargets, frameAttached
    end

    local function wakeAll()
        for _, pod in ipairs(pods) do Animator.Wake(pod) end
    end

    ---------------------------------------------------------------------------------------------------
    -- Pod shell
    ---------------------------------------------------------------------------------------------------
    local function makePod(name, title, side)
        local pod = {
            Name = name, Title = title, Side = side or "Right", RenderSide = side or "Right",
            Order = #pods + 1, -- position within its side's stack; drag-and-drop rewrites it
            Deployed = false, Docked = true, Carried = false, Landing = false, Attached = false,
            x = 0, y = 0, vx = 0, vy = 0, tx = 0, ty = 0, rotation = 0, lift = 0, alpha = 0, alphaTarget = 0,
        }

        local frame = New("Frame", {
            Name = "Satellite_" .. name,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(POD_W, POD_H),
            Visible = false,
            ZIndex = 90,
        }, ScreenGui)
        local frameScale = New("UIScale", { Scale = Scale.Scale }, frame)
        local shadow = GlassShadow(frame, 14, 1, 0)

        -- Two connectors bridging the gap. They fade to nothing at both ends so the pod and the window
        -- read as joined rather than bolted together, and they only appear once the pod is truly docked.
        local clamps = {}
        for i = 1, 2 do
            local clamp = Themed(New("Frame", {
                Name = "Clamp",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.fromOffset(POD_GAP + 6, 5),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 1,
            }, frame), { BackgroundColor3 = "LensTint" })
            New("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.5, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
            }, clamp)
            local core = Themed(New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.new(1, -2, 0, 2),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 2,
            }, clamp), { BackgroundColor3 = "Accent" })
            New("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.5, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
            }, core)
            clamps[i] = { Frame = clamp, Core = core }
        end

        -- The body is a CanvasGroup purely so the pod can fade in and out as one object via
        -- GroupTransparency. Nothing decorative may be attached to it directly: a UIGradient parented to a
        -- CanvasGroup multiplies over everything the group renders, children included, so PaneMaterial's
        -- pane gradient (near-black on most themes) would crush the pod's own readout to black no matter
        -- how bright the text colour is. The glass therefore lives on an inner Frame, where the gradient
        -- only tints that frame's background, exactly as it does on the window.
        local body = New("CanvasGroup", {
            Name = "Body",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            GroupTransparency = 1,
            ZIndex = 2,
        }, frame)
        local surface = New("Frame", {
            Name = "Surface",
            Size = UDim2.fromScale(1, 1),
            ZIndex = 1,
        }, body)
        PaneMaterial(surface, 12, 40)
        -- Pods float over the game, so keep the glass mostly opaque or the readout washes out on
        -- see-through themes (Glacier, Smoke, Aurora) and light ones (Frost).
        Themed(surface, { BackgroundTransparency = function() return math.min(Glass.PaneTransparency, 0.04) end })
        -- A flat wash of the theme's deepest pane colour under the content. The pane gradient alone runs
        -- bright at the top on several themes, which is exactly where a pod's title sits.
        local wash = Themed(New("Frame", {
            Name = "Wash",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 0.62,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, body), { BackgroundColor3 = "PaneBottom" })
        Corner(wash, 12)

        local dot = Themed(New("Frame", {
            Position = UDim2.fromOffset(12, 14),
            Size = UDim2.fromOffset(5, 5),
            BorderSizePixel = 0,
            ZIndex = 3,
        }, body), { BackgroundColor3 = "Accent" })
        Corner(dot, 3)
        local titleLabel = Themed(Text(body, {
            Text = title,
            TextSize = 11,
            Position = UDim2.fromOffset(23, 8),
            Size = UDim2.new(1, -50, 0, 16),
            ZIndex = 3,
        }), { TextColor3 = POD_LABEL })
        pod.TitleLabel = titleLabel
        for i = 0, 2 do
            local grip = Themed(New("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.fromOffset(POD_W - 12 - i * 5, 15),
                Size = UDim2.fromOffset(3, 3),
                BackgroundTransparency = 0.35,
                BorderSizePixel = 0,
                ZIndex = 3,
            }, body), { BackgroundColor3 = "Glyph" })
            Corner(grip, 2)
        end

        local hit = New("TextButton", {
            Name = "Hitbox",
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 20,
        }, frame)

        -- Everything the pod draws goes through this cache. A docked pod that is only being trailed along
        -- has a constant rotation, scale, fade and connector layout; only its position changes.
        local put = PropertyCache()

        local function renderAlpha()
            put(body, "GroupTransparency", 1 - pod.alpha)
            put(shadow, "ImageTransparency", 1 - (1 - Glass.ShadowTransparency) * pod.alpha)
            put(frame, "Visible", pod.alpha > 0.01)
        end

        -- `alpha` is passed in rather than read from the pod: at rest the connectors keep the fade they had
        -- on the last moving step, while the body snaps to its final fade.
        local function layoutClamps(hold, alpha)
            local side = pod.RenderSide
            local vertical = isVertical(side)
            local along = if vertical then POD_H else POD_W
            local first, second = along * 0.25, along * 0.75
            for i, clamp in ipairs(clamps) do
                local at = if i == 1 then first else second
                if vertical then
                    put(clamp.Frame, "Size", UDim2.fromOffset(POD_GAP + 6, 5))
                    put(clamp.Core, "Size", UDim2.new(1, -2, 0, 2))
                    put(clamp.Frame, "Position", UDim2.fromOffset(if side == "Left" then POD_W + POD_GAP / 2 else -POD_GAP / 2, at))
                else
                    put(clamp.Frame, "Size", UDim2.fromOffset(5, POD_GAP + 6))
                    put(clamp.Core, "Size", UDim2.new(0, 2, 1, -2))
                    put(clamp.Frame, "Position", UDim2.fromOffset(at, if side == "Top" then POD_H + POD_GAP / 2 else -POD_GAP / 2))
                end
                put(clamp.Frame, "BackgroundTransparency", 1 - 0.35 * hold * alpha)
                put(clamp.Core, "BackgroundTransparency", 1 - 0.9 * hold * alpha)
            end
        end

        -- Step integrates; Render draws once the frame's substeps are done. These carry what the last
        -- step decided about the connectors over to Render.
        local clampHold, clampAlpha = 0, 0

        function pod:Render()
            put(frame, "Position", UDim2.fromOffset(self.x, self.y))
            put(frame, "Rotation", self.rotation)
            put(frameScale, "Scale", Scale.Scale * (1 + 0.04 * self.lift))
            renderAlpha()
            layoutClamps(clampHold, clampAlpha)
        end

        function pod:Step(dt)
            local target
            if self.Docked and not self.Carried then
                local targets, attached = dockTargetsThisFrame()
                target = targets[self] or Vector2.new(self.x, self.y)
                self.Attached = attached[self] == true
            else
                target = clampToScreen(Vector2.new(self.tx, self.ty), geometryThisFrame())
                self.Attached = false
            end

            local stiffness, ratio = 260, 0.74
            if self.Carried then
                stiffness, ratio = 700, 0.85
            elseif self.Landing then
                stiffness, ratio = 240, 0.58
            end
            local damping = 2 * math.sqrt(stiffness) * ratio
            self.vx += (stiffness * (target.X - self.x) - damping * self.vx) * dt
            self.vy += (stiffness * (target.Y - self.y) - damping * self.vy) * dt
            self.x += self.vx * dt
            self.y += self.vy * dt

            local lean = if self.Carried then math.clamp(self.vx * 0.012, -8, 8) else 0
            self.rotation += (lean - self.rotation) * math.min(1, dt * 14)
            local liftTarget = if self.Carried then 1 else 0
            self.lift += (liftTarget - self.lift) * math.min(1, dt * 16)
            self.alpha += (self.alphaTarget - self.alpha) * math.min(1, dt * 12)

            local distance = (target - Vector2.new(self.x, self.y)).Magnitude
            clampHold = if self.Attached and not self.Carried then math.clamp(1 - distance / 24, 0, 1) else 0
            clampAlpha = self.alpha

            local resting = distance < 0.3 and math.abs(self.vx) < 2 and math.abs(self.vy) < 2
                and math.abs(self.rotation - lean) < 0.05 and math.abs(self.lift - liftTarget) < 0.01
                and math.abs(self.alpha - self.alphaTarget) < 0.01
            if not resting then return true end
            self.x, self.y = target.X, target.Y
            self.alpha, self.Landing = self.alphaTarget, false
            return false
        end

        -----------------------------------------------------------------------------------------------
        -- Deploying, carrying and stowing
        -----------------------------------------------------------------------------------------------
        function pod:Deploy(atPosition)
            local wasDeployed = self.Deployed
            self.Deployed = true
            self.alphaTarget = 1
            if not wasDeployed then playSound("Deploy") end
            if atPosition then
                self.Docked = false
                self.tx, self.ty = atPosition.X, atPosition.Y
                self.x, self.y = atPosition.X, atPosition.Y
            else
                self.Docked = true
                local targets = dockTargets()
                local target = targets[self]
                if target then
                    -- Start tucked under the window edge so the pod slides out of it.
                    local k, side = Scale.Scale, self.RenderSide
                    self.x, self.y = target.X, target.Y
                    if side == "Left" then
                        self.x = target.X + POD_W * 0.4 * k
                    elseif side == "Right" then
                        self.x = target.X - POD_W * 0.4 * k
                    elseif side == "Top" then
                        self.y = target.Y + POD_H * 0.4 * k
                    else
                        self.y = target.Y - POD_H * 0.4 * k
                    end
                    self.vx, self.vy = 0, 0
                end
            end
            wakeAll()
        end

        function pod:Stow()
            if self.Deployed then playSound("Close") end
            self.Deployed = false
            self.Carried = false
            self.alphaTarget = 0
            if carry and carry.pod == self then carry = nil end
            wakeAll()
        end

        -- Pinned pods are made on demand and can be thrown away again; the built-in five never are.
        function pod:Remove()
            self:Stow()
            local index = table.find(pods, self)
            if index then table.remove(pods, index) end
            Animator.Wake(self)
            task.delay(0.35, function() frame:Destroy() end)
        end

        local function beginCarry()
            pod.Docked, pod.Carried, pod.Landing = false, true, false
            pod.tx, pod.ty = pod.x, pod.y
            carry = { pod = pod, side = nil, index = 1 }
            wakeAll()
        end
        pod.BeginCarry = beginCarry

        local function moveCarry(topLeft)
            if not carry or carry.pod ~= pod then return end
            carry.side = nil
            local g = geometry()
            local best
            for _, side in ipairs(SIDES) do
                local rendered = renderSide(side, g)
                local origin = sideGeometry(rendered, g)
                local distance = if isVertical(rendered) then math.abs(topLeft.X - origin.X) else math.abs(topLeft.Y - origin.Y)
                if distance < POD_MAGNET and (not best or distance < best.distance) then
                    best = { side = rendered, distance = distance, origin = origin }
                end
            end
            if best then
                carry.side = best.side
                local grouped = columns(g)[best.side]
                local origin, step = sideGeometry(best.side, g)
                local index = #grouped + 1
                for i = 1, #grouped do
                    local slot = origin + step * (i - 1)
                    local ahead = if isVertical(best.side) then topLeft.Y < slot.Y + step.Y / 2 else topLeft.X < slot.X + step.X / 2
                    if ahead then
                        index = i
                        break
                    end
                end
                carry.index = index
                dockTargets(g) -- fills carry.slot
                local offset = carry.slot - topLeft
                local pull = math.clamp(1 - offset.Magnitude / POD_MAGNET, 0, 1)
                topLeft += offset * pull * pull
            end
            pod.tx, pod.ty = topLeft.X, topLeft.Y
            wakeAll()
        end
        pod.MoveCarry = moveCarry

        local function endCarry()
            if not carry or carry.pod ~= pod then return end
            local side, index = carry.side, carry.index
            carry = nil
            pod.Carried, pod.Landing = false, true
            if side then
                pod.Side, pod.Docked = side, true
                -- Slot it between its new neighbours, then renumber the column so the order sticks.
                pod.Order = index - 0.5
                local column = columns()[side]
                for position, member in ipairs(column) do member.Order = position end
            else
                pod.Docked = false
                local settled = clampToScreen(Vector2.new(pod.tx, pod.ty))
                pod.tx, pod.ty = settled.X, settled.Y
            end
            wakeAll()
        end
        pod.EndCarry = endCarry

        hit.InputBegan:Connect(function(input)
            if not isPointer(input) or carry then return end
            local start, origin = input.Position, Vector2.new(pod.x, pod.y)
            local lifted = false
            local moveConnection, endConnection
            moveConnection = UserInputService.InputChanged:Connect(function(changed)
                if not isMove(changed) then return end
                local delta = changed.Position - start
                if not lifted then
                    if delta.Magnitude < L.DragSlop or carry then return end
                    lifted = true
                    beginCarry()
                end
                moveCarry(origin + Vector2.new(delta.X, delta.Y))
            end)
            endConnection = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then return end
                moveConnection:Disconnect()
                endConnection:Disconnect()
                if lifted then endCarry() end
            end)
        end)

        pod.Frame, pod.Body = frame, body
        table.insert(pods, pod)
        return pod, body
    end

    ---------------------------------------------------------------------------------------------------
    -- Session
    ---------------------------------------------------------------------------------------------------
    local MONO_BOLD = Font.new(FONT_MONO.Family, Enum.FontWeight.Bold)
    local _, sessionBody = makePod("Session", "SESSION", "Right")
    local sessionTime = Themed(Text(sessionBody, {
        Text = "00:00:00", FontFace = MONO_BOLD, TextSize = 20,
        Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -56, 0, 26), ZIndex = 3,
    }), { TextColor3 = "TextPrimary" })
    local serverUp = Themed(Text(sessionBody, {
        FontFace = FONT_MEDIUM, TextSize = 11,
        Position = UDim2.fromOffset(12, 56), Size = UDim2.new(1, -24, 0, 14), ZIndex = 3,
    }), { TextColor3 = POD_LABEL })
    local ring = New("Frame", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromOffset(POD_W - 12, 30),
        Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, ZIndex = 3,
    }, sessionBody)
    Corner(ring, 12)
    Themed(New("UIStroke", { Thickness = 1.5, Transparency = 0.7 }, ring), { Color = "Rim" })
    local orbit = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 3,
    }, ring)
    local orbitBead = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0),
        Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, ZIndex = 4,
    }, orbit), { BackgroundColor3 = "Accent" })
    Corner(orbitBead, 3)

    ---------------------------------------------------------------------------------------------------
    -- Performance
    ---------------------------------------------------------------------------------------------------
    local _, perfBody = makePod("Performance", "PERFORMANCE", "Right")
    local fpsValue = Themed(Text(perfBody, {
        Text = "0", TextSize = 22, TextTruncate = Enum.TextTruncate.None,
        Position = UDim2.fromOffset(12, 26), Size = UDim2.fromOffset(60, 28), ZIndex = 3,
    }), { TextColor3 = "TextPrimary" })
    local fpsUnit = Themed(Text(perfBody, {
        Text = "fps", FontFace = FONT_MEDIUM, TextSize = 11,
        Position = UDim2.fromOffset(40, 34), Size = UDim2.fromOffset(30, 16), ZIndex = 3,
    }), { TextColor3 = POD_LABEL })
    local pingText = Themed(Text(perfBody, {
        Text = "-- ms", FontFace = FONT_MEDIUM, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromOffset(POD_W - 12, 32), Size = UDim2.fromOffset(64, 16), ZIndex = 3,
    }), { TextColor3 = POD_SUB })
    local pingDot = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(POD_W - 80, 40),
        Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Glass.Glyph, BorderSizePixel = 0, ZIndex = 3,
    }, perfBody)
    Corner(pingDot, 3)
    local graph = New("Frame", {
        Position = UDim2.fromOffset(12, 62), Size = UDim2.fromOffset(POD_W - 24, GRAPH_HEIGHT),
        BackgroundTransparency = 1, ZIndex = 3,
    }, perfBody)
    Themed(New("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1),
        BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 3,
    }, graph), { BackgroundColor3 = "Rim" })
    local barWidth = (POD_W - 24 - (GRAPH_BARS - 1) * GRAPH_GAP) / GRAPH_BARS
    local graphBars = {}
    for i = 1, GRAPH_BARS do
        local bar = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, (i - 1) * (barWidth + GRAPH_GAP), 1, -2),
            Size = UDim2.fromOffset(barWidth, 2), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 4,
        }, graph)
        Corner(bar, 1)
        graphBars[i] = bar
    end

    ---------------------------------------------------------------------------------------------------
    -- Server
    ---------------------------------------------------------------------------------------------------
    local _, serverBody = makePod("Server", "SERVER", "Right")
    local playersValue = Themed(Text(serverBody, {
        Text = "0", TextSize = 20, TextTruncate = Enum.TextTruncate.None,
        Position = UDim2.fromOffset(12, 26), Size = UDim2.fromOffset(80, 26), ZIndex = 3,
    }), { TextColor3 = "TextPrimary" })
    local playersUnit = Themed(Text(serverBody, {
        Text = "players", FontFace = FONT_MEDIUM, TextSize = 11,
        Position = UDim2.fromOffset(60, 33), Size = UDim2.fromOffset(60, 16), ZIndex = 3,
    }), { TextColor3 = POD_LABEL })
    local capacity = New("Frame", {
        Position = UDim2.fromOffset(12, 56), Size = UDim2.fromOffset(POD_W - 24, 6), ZIndex = 3,
    }, serverBody)
    FieldMaterial(capacity, 3)
    local capacityFill = Themed(New("Frame", {
        Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, ZIndex = 4,
    }, capacity), { BackgroundColor3 = "Accent" })
    Corner(capacityFill, 3)
    local serverMeta = Themed(Text(serverBody, {
        FontFace = FONT_MEDIUM, TextSize = 11,
        Position = UDim2.fromOffset(12, 68), Size = UDim2.new(1, -24, 0, 14), ZIndex = 3,
    }), { TextColor3 = POD_LABEL })

    ---------------------------------------------------------------------------------------------------
    -- Location
    ---------------------------------------------------------------------------------------------------
    local locPod, locBody = makePod("Location", "LOCATION", "Left")
    local coordLabels = {}
    for i, axis in ipairs({ "X", "Y", "Z" }) do
        Themed(Text(locBody, {
            Text = axis, FontFace = MONO_BOLD, TextSize = 10,
            Position = UDim2.fromOffset(12, 26 + (i - 1) * 18), Size = UDim2.fromOffset(12, 14), ZIndex = 3,
        }), { TextColor3 = POD_LABEL })
        coordLabels[i] = Themed(Text(locBody, {
            Text = "0", FontFace = FONT_MONO, TextSize = 12,
            Position = UDim2.fromOffset(26, 26 + (i - 1) * 18), Size = UDim2.fromOffset(78, 14), ZIndex = 3,
        }), { TextColor3 = "TextPrimary" })
    end
    local compass = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(POD_W - 14, 54),
        Size = UDim2.fromOffset(48, 48), BackgroundTransparency = 1, ZIndex = 3,
    }, locBody)
    Corner(compass, 24)
    Themed(New("UIStroke", { Thickness = 1.5, Transparency = 0.65 }, compass), { Color = "Rim" })
    Themed(Text(compass, {
        Text = "N", TextSize = 9, TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.fromOffset(0, 1), Size = UDim2.new(1, 0, 0, 10), ZIndex = 4,
    }), { TextColor3 = POD_LABEL })
    local needle = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 4,
    }, compass)
    local needleN = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(3, 17), BorderSizePixel = 0, ZIndex = 5,
    }, needle), { BackgroundColor3 = "Accent" })
    Corner(needleN, 2)
    local needleS = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(3, 15), BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 5,
    }, needle), { BackgroundColor3 = "Glyph" })
    Corner(needleS, 2)

    ---------------------------------------------------------------------------------------------------
    -- Radar
    ---------------------------------------------------------------------------------------------------
    local RADAR_RANGE = 220
    local radarPod, radarBody = makePod("Radar", "RADAR", "Left")
    local dish = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(POD_W - 54, POD_H / 2 + 6),
        Size = UDim2.fromOffset(72, 72), BackgroundTransparency = 1, ZIndex = 3,
    }, radarBody)
    FieldMaterial(dish, 36)
    Corner(dish, 36)
    for _, scale in ipairs({ 1, 0.6 }) do
        local rangeRing = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(scale, scale), BackgroundTransparency = 1, ZIndex = 4,
        }, dish)
        Corner(rangeRing, 36)
        Themed(New("UIStroke", { Thickness = 1, Transparency = 0.72 }, rangeRing), { Color = "Rim" })
    end
    for _, rot in ipairs({ 0, 90 }) do
        Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = if rot == 0 then UDim2.new(0, 1, 1, -6) else UDim2.new(1, -6, 0, 1),
            BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 4,
        }, dish), { BackgroundColor3 = "Rim" })
    end
    local sweepPivot = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5,
    }, dish)
    Themed(New("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1,
        Image = Assets.Spark, ImageTransparency = 0.4, ZIndex = 5,
    }, sweepPivot), { ImageColor3 = "Accent" })
    local blipHolder = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 6 }, dish)
    local selfBlip = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(5, 5), BorderSizePixel = 0, ZIndex = 7,
    }, dish), { BackgroundColor3 = "Knob" })
    Corner(selfBlip, 3)
    local countValue = Themed(Text(radarBody, {
        Text = "0", TextSize = 22, Position = UDim2.fromOffset(12, 26), Size = UDim2.fromOffset(40, 26), ZIndex = 3,
    }), { TextColor3 = "TextPrimary" })
    Themed(Text(radarBody, {
        Text = "nearby", FontFace = FONT_MEDIUM, TextSize = 11,
        Position = UDim2.fromOffset(12, 52), Size = UDim2.fromOffset(70, 14), ZIndex = 3,
    }), { TextColor3 = POD_LABEL })
    Themed(Text(radarBody, {
        Text = string.format("%dm range", RADAR_RANGE), FontFace = FONT_MEDIUM, TextSize = 10,
        Position = UDim2.fromOffset(12, 70), Size = UDim2.fromOffset(90, 14), ZIndex = 3,
    }), { TextColor3 = POD_LABEL })
    local blips = {}
    local function radarBlip(i)
        if blips[i] then return blips[i] end
        local blip = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(5, 5),
            BackgroundColor3 = Glass.Danger, BorderSizePixel = 0, Visible = false, ZIndex = 7,
        }, blipHolder)
        Corner(blip, 3)
        blips[i] = blip
        return blip
    end

    ---------------------------------------------------------------------------------------------------
    -- Live data
    ---------------------------------------------------------------------------------------------------
    local function anyVisible()
        for _, pod in ipairs(pods) do
            if pod.alpha > 0.01 or pod.alphaTarget > 0 then return true end
        end
        return false
    end

    local function refresh()
        local session = os.clock() - Telemetry.SessionStart
        sessionTime.Text = Telemetry.Clock(session)
        serverUp.Text = "Server up " .. Telemetry.Duration(Workspace.DistributedGameTime)
        Tween(orbit, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Rotation = math.floor(session) * 6 })

        fpsValue.Text = tostring(Telemetry.Fps)
        fpsUnit.Position = UDim2.fromOffset(12 + textWidth(fpsValue.Text, 22, Enum.Font.GothamBold) + 5, 34)
        local ping = Telemetry.Ping
        pingText.Text = if ping then string.format("%d ms", math.floor(ping + 0.5)) else "-- ms"
        pingDot.Position = UDim2.fromOffset(POD_W - 12 - textWidth(pingText.Text, 12, Enum.Font.GothamMedium) - 6, 40)
        Tween(pingDot, Motion.Hover, { BackgroundColor3 = if ping then Telemetry.StrengthColor(Telemetry.Strength(ping)) else Glass.Glyph })

        local samples = Telemetry.PingSamples
        local ceiling = 150
        for _, value in ipairs(samples) do ceiling = math.max(ceiling, value * 1.15) end
        for i, bar in ipairs(graphBars) do
            local value = samples[#samples - GRAPH_BARS + i]
            if value and value > 0 then
                bar.BackgroundColor3 = Telemetry.StrengthColor(Telemetry.Strength(value))
                bar.BackgroundTransparency = if i == GRAPH_BARS then 0.05 else 0.45
                Tween(bar, Motion.Hover, { Size = UDim2.fromOffset(barWidth, math.max(2, value / ceiling * (GRAPH_HEIGHT - 4))) })
            else
                bar.BackgroundTransparency = 1
            end
        end

        local count, max = #Players:GetPlayers(), Players.MaxPlayers
        playersValue.Text = if max > 0 then string.format("%d/%d", count, max) else tostring(count)
        playersUnit.Position = UDim2.fromOffset(12 + textWidth(playersValue.Text, 20, Enum.Font.GothamBold) + 5, 33)
        Tween(capacityFill, Motion.Settle, { Size = UDim2.fromScale(if max > 0 then math.clamp(count / max, 0, 1) else 0, 1) })
        serverMeta.Text = Telemetry.Region .. "  ·  " .. Telemetry.Executor
    end
    Telemetry.OnTick(function()
        if anyVisible() then refresh() end
    end)

    -- Runs every frame whether or not anything is deployed, so the open check uses the pods' own fade
    -- (the body's GroupTransparency is drawn from it) instead of reading two instance properties.
    local locationAccrued, sweepAngle = 0, 0
    -- At 15 Hz most of these come out the same as last time (standing still, players out of range).
    local live = PropertyCache()
    Library:GiveSignal(RunService.Heartbeat:Connect(function(dt)
        local locOpen = 1 - locPod.alpha < 0.99
        local radarOpen = 1 - radarPod.alpha < 0.99
        if radarOpen then
            sweepAngle = (sweepAngle + dt * 150) % 360
            sweepPivot.Rotation = sweepAngle
        end
        if not (locOpen or radarOpen) then return end
        locationAccrued += dt
        if locationAccrued < 1 / 15 then return end
        locationAccrued = 0

        local character = Players.LocalPlayer and Players.LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local camera = Workspace.CurrentCamera

        if locOpen then
            if root then
                local p = root.Position
                live(coordLabels[1], "Text", string.format("%.1f", p.X))
                live(coordLabels[2], "Text", string.format("%.1f", p.Y))
                live(coordLabels[3], "Text", string.format("%.1f", p.Z))
            end
            if camera then
                local look = camera.CFrame.LookVector
                live(needle, "Rotation", math.deg(math.atan2(look.X, look.Z)))
            end
        end

        if radarOpen and root then
            local look = root.CFrame.LookVector
            local facing = math.atan2(look.X, look.Z)
            local cos, sin = math.cos(facing), math.sin(facing)
            local origin = root.Position
            local radius = dish.AbsoluteSize.X / 2 / Scale.Scale - 5
            local nearby = 0
            local list = Players:GetPlayers()
            for i, player in ipairs(list) do
                local blip = radarBlip(i)
                local otherRoot = player ~= Players.LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local offset = otherRoot and (otherRoot.Position - origin)
                local distance = offset and offset.Magnitude
                if distance and distance <= RADAR_RANGE then
                    nearby += 1
                    local rx = (offset.X * cos - offset.Z * sin) / RADAR_RANGE * radius
                    local ry = (offset.X * sin + offset.Z * cos) / RADAR_RANGE * radius
                    live(blip, "Position", UDim2.new(0.5, rx, 0.5, ry))
                    live(blip, "BackgroundColor3", if distance < RADAR_RANGE * 0.5 then Glass.Danger else Glass.Warning)
                    live(blip, "Visible", true)
                else
                    live(blip, "Visible", false)
                end
            end
            for i = #list + 1, #blips do live(blips[i], "Visible", false) end
            live(countValue, "Text", tostring(nearby))
        end
    end))

    ---------------------------------------------------------------------------------------------------
    -- Launcher: the Attachments shelf in the header
    --
    -- Each row is a live miniature of the pod itself, cloned out of the real thing at the moment the
    -- shelf opens, so you pick an attachment by looking at it rather than by reading its name. Click a
    -- tile to deploy or stow it; drag one off the shelf to place it by hand.
    ---------------------------------------------------------------------------------------------------
    local PREVIEW_SCALE = 0.78
    local TILE_W = math.floor(POD_W * PREVIEW_SCALE)
    local STAGE_H = math.floor(POD_H * PREVIEW_SCALE)
    local TILE_H = STAGE_H + 20
    local TILE_GAP = 10

    function W.OpenAttachments(anchor)
        local width = 12 * 2 + TILE_W * 2 + TILE_GAP
        local rows = math.ceil(#pods / 2)
        local height = 40 + rows * (TILE_H + TILE_GAP) - TILE_GAP + 12

        local panel = New("Frame", { Name = "AttachmentShelf", Size = UDim2.fromOffset(width, 0), ClipsDescendants = true }, nil)
        PopupMaterial(panel, 14, 40)
        W:PlacePopup(panel, anchor, 8, height)

        Themed(Text(panel, {
            Text = T("attachments"),
            TextSize = 12,
            Position = UDim2.fromOffset(14, 12),
            Size = UDim2.new(1, -28, 0, 18),
            ZIndex = 2,
        }), { TextColor3 = "TextPrimary" })
        local deployedCount = 0
        for _, pod in ipairs(pods) do
            if pod.Deployed then deployedCount += 1 end
        end
        Themed(Text(panel, {
            Text = string.format("%d / %d out", deployedCount, #pods),
            FontFace = FONT_MEDIUM,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Right,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -14, 0, 12),
            Size = UDim2.fromOffset(110, 18),
            ZIndex = 2,
        }), { TextColor3 = "TextMuted" })

        for i, pod in ipairs(pods) do
            local column, row = (i - 1) % 2, math.floor((i - 1) / 2)
            local tile = New("TextButton", {
                Name = pod.Name,
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(12 + column * (TILE_W + TILE_GAP), 40 + row * (TILE_H + TILE_GAP)),
                Size = UDim2.fromOffset(TILE_W, TILE_H),
                ZIndex = 2,
            }, panel)
            local tileScale = New("UIScale", { Scale = 1 }, tile)

            -- The miniature. A clone is a frozen snapshot, which is fine: the shelf is rebuilt every time
            -- it opens, so what you see is the pod as it reads right now.
            local stage = New("Frame", {
                Name = "Stage",
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(TILE_W, STAGE_H),
                ClipsDescendants = true,
                ZIndex = 2,
            }, tile)
            Corner(stage, 10)
            local preview = pod.Body:Clone()
            preview.Name = "Preview"
            preview.AnchorPoint = Vector2.new(0, 0)
            preview.Position = UDim2.fromOffset(0, 0)
            preview.Size = UDim2.fromOffset(POD_W, POD_H)
            preview.GroupTransparency = pod.Deployed and 0 or 0.55
            New("UIScale", { Scale = PREVIEW_SCALE }, preview)
            preview.Parent = stage

            -- A stowed tile reads as switched off: the miniature dims and the glass behind it goes flat.
            local veil = Themed(New("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = pod.Deployed and 1 or 0.72,
                BorderSizePixel = 0,
                ZIndex = 4,
            }, stage), { BackgroundColor3 = "PaneBottom" })
            Corner(veil, 10)
            local ring = Themed(New("UIStroke", {
                Thickness = pod.Deployed and 1.5 or 1,
                Transparency = pod.Deployed and 0.2 or 0.7,
            }, stage), { Color = function() return pod.Deployed and Glass.Accent or Glass.Rim end })

            local nameLabel = Themed(Text(tile, {
                Text = pod.Title,
                FontFace = FONT_MEDIUM,
                TextSize = 11,
                Position = UDim2.fromOffset(2, STAGE_H + 2),
                Size = UDim2.fromOffset(TILE_W - 46, 18),
                ZIndex = 3,
            }), { TextColor3 = "TextSecondary" })
            local stateLabel = Themed(Text(tile, {
                Text = "",
                FontFace = FONT_MEDIUM,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Right,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -2, 0, STAGE_H + 2),
                Size = UDim2.fromOffset(44, 18),
                ZIndex = 3,
            }), { TextColor3 = function() return pod.Deployed and Glass.Accent or Glass.TextMuted end })

            local function paint()
                stateLabel.Text = pod.Deployed and T("stow") or T("deploy")
                stateLabel.TextColor3 = pod.Deployed and Glass.Accent or Glass.TextMuted
                Tween(veil, Motion.Hover, { BackgroundTransparency = pod.Deployed and 1 or 0.72 })
                Tween(preview, Motion.Hover, { GroupTransparency = pod.Deployed and 0 or 0.55 })
                Tween(ring, Motion.Hover, {
                    Thickness = pod.Deployed and 1.5 or 1,
                    Transparency = pod.Deployed and 0.2 or 0.7,
                    Color = pod.Deployed and Glass.Accent or Glass.Rim,
                })
            end
            paint()

            tile.MouseEnter:Connect(function()
                Tween(tileScale, Motion.Pop, { Scale = 1.04 })
                Tween(nameLabel, Motion.Hover, { TextColor3 = Glass.TextPrimary })
                playSound("Hover")
            end)
            tile.MouseLeave:Connect(function()
                Tween(tileScale, Motion.Pop, { Scale = 1 })
                Tween(nameLabel, Motion.Hover, { TextColor3 = Glass.TextSecondary })
            end)

            -- Click toggles it; dragging the tile out carries the pod straight to where you drop it.
            tile.InputBegan:Connect(function(input)
                if not isPointer(input) then return end
                local start = input.Position
                local dragged = false
                local moveConnection, endConnection
                moveConnection = UserInputService.InputChanged:Connect(function(changed)
                    if not isMove(changed) then return end
                    local delta = changed.Position - start
                    if not dragged then
                        if delta.Magnitude < L.DragSlop then return end
                        dragged = true
                        W:ClosePopup()
                        local k = Scale.Scale
                        pod:Deploy(Vector2.new(changed.Position.X - POD_W * k / 2, changed.Position.Y - POD_H * k / 2))
                        pod.BeginCarry()
                    end
                    pod.MoveCarry(Vector2.new(changed.Position.X - POD_W * Scale.Scale / 2, changed.Position.Y - POD_H * Scale.Scale / 2))
                end)
                endConnection = input.Changed:Connect(function()
                    if input.UserInputState ~= Enum.UserInputState.End then return end
                    moveConnection:Disconnect()
                    endConnection:Disconnect()
                    if dragged then
                        pod.EndCarry()
                    else
                        if pod.Deployed then pod:Stow() else pod:Deploy() end
                        paint()
                    end
                end)
            end)
        end

        W:OpenPopup(panel, function()
            playSound("Close")
            Tween(panel, Motion.FadeOut, { Size = UDim2.fromOffset(width, 0) })
            task.delay(Motion.FadeOut.Time, function() panel:Destroy() end)
        end)
        playSound("Open")
        Tween(panel, Motion.Reveal, { Size = UDim2.fromOffset(width, height) })
    end

    ---------------------------------------------------------------------------------------------------
    -- Pinned controls
    --
    -- Right-clicking a toggle or slider pops it out as its own satellite, so a HUD can be built from the
    -- handful of controls actually being used. A pinned pod is a real pod: it docks, stacks and is
    -- carried like the built-in five, and it shows up on the shelf alongside them.
    --
    -- The pod's own hitbox owns dragging, and it sits above everything inside the body, so the miniature
    -- control gets its own hitbox on the frame below the title bar. That splits the pod cleanly: drag it
    -- by the header, use it everywhere else.
    ---------------------------------------------------------------------------------------------------
    local pinned = {}

    local function unpinButton(pod)
        local button = New("TextButton", {
            Name = "Unpin",
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -8, 1, -8),
            Size = UDim2.fromOffset(14, 14),
            ZIndex = 26,
        }, pod.Frame)
        local bars = {}
        for i, rotation in ipairs({ 45, -45 }) do
            bars[i] = Themed(New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(10, 1.5),
                Rotation = rotation,
                BackgroundTransparency = 0.45,
                BorderSizePixel = 0,
                ZIndex = 26,
            }, button), { BackgroundColor3 = "Glyph" })
            Corner(bars[i], 1)
        end
        button.MouseEnter:Connect(function()
            for _, bar in ipairs(bars) do
                Tween(bar, Motion.Hover, { BackgroundTransparency = 0, BackgroundColor3 = Glass.Danger })
            end
        end)
        button.MouseLeave:Connect(function()
            for _, bar in ipairs(bars) do
                Tween(bar, Motion.Hover, { BackgroundTransparency = 0.45, BackgroundColor3 = Glass.Glyph })
            end
        end)
        button.MouseButton1Click:Connect(function()
            pinned[pod.PinKey] = nil
            if pod.Unbind then pod.Unbind() end
            pod:Remove()
        end)
    end

    -- The area of a pinned pod that belongs to the control rather than to dragging.
    local function controlSurface(pod)
        return New("TextButton", {
            Name = "Control",
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 30),
            Size = UDim2.new(1, -26, 1, -36),
            ZIndex = 25,
        }, pod.Frame)
    end

    local function buildPinnedToggle(pod, body, object)
        local CAP_W, CAP_H, KNOB = 46, 26, 20
        local capsule = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromOffset(12, 62),
            Size = UDim2.fromOffset(CAP_W, CAP_H),
            ZIndex = 3,
        }, body)
        FieldMaterial(capsule, CAP_H / 2)
        local fill = New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 4,
        }, capsule)
        Corner(fill, CAP_H / 2)
        Themed(New("UIGradient", { Rotation = 8 }, fill), { Color = accentSequence })
        local knob = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(KNOB, KNOB),
            BorderSizePixel = 0,
            ZIndex = 5,
        }, capsule), { BackgroundColor3 = "Knob" })
        Corner(knob, KNOB / 2)
        local state = Themed(Text(body, {
            Text = "",
            TextSize = 14,
            Position = UDim2.fromOffset(12 + CAP_W + 12, 49),
            Size = UDim2.fromOffset(POD_W - CAP_W - 46, 26),
            ZIndex = 3,
        }), { TextColor3 = function() return object.Value and Glass.Accent or Glass.TextMuted end })

        local travel = Spring(520, 0.62, object.Value and 1 or 0, function(value)
            local inset = (CAP_H - KNOB) / 2
            local left = inset + KNOB / 2
            knob.Position = UDim2.fromOffset(left + (CAP_W - inset - KNOB / 2 - left) * value, CAP_H / 2)
        end, 0.002)

        local function render(instant)
            local on = object.Value
            state.Text = on and "ON" or "OFF"
            state.TextColor3 = on and Glass.Accent or Glass.TextMuted
            if instant then
                travel:Snap(on and 1 or 0)
                fill.BackgroundTransparency = on and 0 or 1
            else
                travel:Set(on and 1 or 0)
                Tween(fill, Motion.Hover, { BackgroundTransparency = on and 0 or 1 })
            end
        end
        render(true)

        controlSurface(pod).MouseButton1Click:Connect(function()
            object:SetValue(not object.Value)
            playSound(object.Value and "ToggleOn" or "ToggleOff")
        end)
        object.Mirror = function() render(false) end
        pod.Unbind = function() object.Mirror = nil end
    end

    local function buildPinnedSlider(pod, body, object)
        local TUBE_H, BEAD = 6, 14
        local value = Themed(Text(body, {
            Text = "",
            TextSize = 22,
            TextTruncate = Enum.TextTruncate.None,
            Position = UDim2.fromOffset(12, 30),
            Size = UDim2.fromOffset(POD_W - 24, 26),
            ZIndex = 3,
        }), { TextColor3 = "TextPrimary" })
        local tube = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromOffset(12 + BEAD / 2, 74),
            Size = UDim2.fromOffset(POD_W - 24 - BEAD - 18, TUBE_H),
            ZIndex = 3,
        }, body)
        FieldMaterial(tube, TUBE_H / 2)
        local fill = New("Frame", {
            Size = UDim2.fromScale(0, 1),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 4,
        }, tube)
        Corner(fill, TUBE_H / 2)
        Themed(New("UIGradient", {}, fill), { Color = accentSequence })
        local bead = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(BEAD, BEAD),
            BorderSizePixel = 0,
            ZIndex = 5,
        }, tube), { BackgroundColor3 = "Knob" })
        Corner(bead, BEAD / 2)
        Themed(New("UIStroke", { Thickness = 1.5, Transparency = 0.1 }, bead), { Color = "Accent" })

        local function percent()
            if object.Max == object.Min then return 0 end
            return math.clamp((object.Value - object.Min) / (object.Max - object.Min), 0, 1)
        end
        local level = Spring(420, 0.85, percent(), function(v)
            fill.Size = UDim2.fromScale(v, 1)
            bead.Position = UDim2.fromScale(v, 0.5)
        end, 0.0005)

        local function render(instant)
            local text = object.Rounding > 0
                and string.format("%." .. object.Rounding .. "f", object.Value)
                or tostring(math.floor(object.Value + 0.5))
            value.Text = (object.Prefix or "") .. text .. (object.Suffix or "")
            if instant then level:Snap(percent()) else level:Set(percent()) end
        end
        render(true)

        local surface = controlSurface(pod)
        local function setFromX(x)
            local left, width = tube.AbsolutePosition.X, tube.AbsoluteSize.X
            if width <= 0 then return end
            object:SetValue(object.Min + (object.Max - object.Min) * math.clamp((x - left) / width, 0, 1))
        end
        surface.InputBegan:Connect(function(input)
            if not isPointer(input) then return end
            setFromX(input.Position.X)
            playSound("Press")
            local moveConnection, endConnection
            moveConnection = UserInputService.InputChanged:Connect(function(changed)
                if isMove(changed) then
                    setFromX(changed.Position.X)
                    playSound("Tick")
                end
            end)
            endConnection = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then return end
                moveConnection:Disconnect()
                endConnection:Disconnect()
            end)
        end)
        object.Mirror = function() render(false) end
        pod.Unbind = function() object.Mirror = nil end
    end

    -- `spec` is { Kind = "Toggle" | "Slider", Key, Title, Object }.
    function W.PinControl(spec)
        local existing = pinned[spec.Key]
        if existing then
            if not existing.Deployed then existing:Deploy() end
            return existing
        end

        local title = (spec.Title or "Control"):upper()
        local pod, body = makePod("Pin_" .. spec.Key, title, "Right")
        pod.PinKey = spec.Key
        pod.Pinned = true
        if spec.Kind == "Slider" then
            buildPinnedSlider(pod, body, spec.Object)
        else
            buildPinnedToggle(pod, body, spec.Object)
        end
        unpinButton(pod)
        pinned[spec.Key] = pod
        pod:Deploy()
        Library:Notify({ Title = "Pinned", Description = spec.Title .. " is now an attachment.", Time = 3 })
        return pod
    end

    ---------------------------------------------------------------------------------------------------
    -- Window hooks
    ---------------------------------------------------------------------------------------------------
    W.OnWindowVisibility = function(visible)
        for _, pod in ipairs(pods) do
            if pod.Deployed and (pod.Docked or visible) then
                pod.alphaTarget = if pod.Docked then (if visible then 1 else 0) else 1
            end
            Animator.Wake(pod)
        end
        if visible then refresh() end
    end

    W.Pods = pods -- scripts (and the launcher) can deploy, stow or re-side a pod directly

    Holder:GetPropertyChangedSignal("Position"):Connect(wakeAll)
    Holder:GetPropertyChangedSignal("Size"):Connect(wakeAll)
    Scale:GetPropertyChangedSignal("Scale"):Connect(wakeAll)

    local previousViewport = W.OnViewportChanged
    W.OnViewportChanged = function()
        if previousViewport then previousViewport() end
        for _, pod in ipairs(pods) do
            if not pod.Docked and not pod.Carried then
                local settled = clampToScreen(Vector2.new(pod.tx, pod.ty))
                pod.tx, pod.ty = settled.X, settled.Y
            end
        end
        wakeAll()
    end
end

-- ===== 24_themeselect.lua =====
-------------------------------------------------------------------------------------------------------
-- Setup flow: language, then theme, then font — shown before the window opens.
--
-- Every step carries a "Don't show this again" box; ticking it and continuing means that step is skipped
-- on later runs, so a returning user drops straight into the interface. A factory reset clears the lot
-- and brings the whole flow back.
-------------------------------------------------------------------------------------------------------
local SETUP_CARD_W, SETUP_CARD_H, SETUP_GAP = 148, 92, 14
local SETUP_COLUMNS = 5

-- A miniature of a theme: pane wash, sidebar rail with tab pills, accent bar and bead.
local function themeMock(parent, theme, width, height)
    local mock = New("Frame", {
        Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 503,
    }, parent)
    Corner(mock, 12)
    New("UIGradient", {
        Rotation = 115,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, theme.PaneTop),
            ColorSequenceKeypoint.new(0.5, theme.PaneMid),
            ColorSequenceKeypoint.new(1, theme.PaneBottom),
        }),
    }, mock)
    local ring = New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = theme.Rim, Thickness = 1, Transparency = 0.6 }, mock)
    New("ImageLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Image = Assets.GlassEdge,
        ImageColor3 = theme.Rim,
        ImageTransparency = math.min(1, theme.EdgeTransparency),
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(50, 50, 78, 78),
        SliceScale = 12 / 18,
        ZIndex = 505,
    }, mock)
    for t = 0, 2 do
        local pill = New("Frame", {
            Position = UDim2.fromOffset(12, 14 + t * 16),
            Size = UDim2.fromOffset(46, 9),
            BackgroundColor3 = t == 0 and theme.LensTint or theme.Glyph,
            BackgroundTransparency = t == 0 and 0.55 or 0.7,
            BorderSizePixel = 0,
            ZIndex = 504,
        }, mock)
        Corner(pill, 4)
        if t == 0 then New("UIStroke", { Color = theme.Rim, Transparency = 0.4, Thickness = 1 }, pill) end
    end
    New("Frame", { Position = UDim2.fromOffset(70, 12), Size = UDim2.fromOffset(1, height - 24), BackgroundColor3 = theme.Rim, BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 504 }, mock)
    local bar = New("Frame", { Position = UDim2.fromOffset(82, 16), Size = UDim2.fromOffset(width - 96, 10), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 504 }, mock)
    Corner(bar, 5)
    New("UIGradient", { Color = ColorSequence.new(theme.AccentDeep, theme.Accent) }, bar)
    local bead = New("Frame", { Position = UDim2.fromOffset(82, 34), Size = UDim2.fromOffset(10, 10), BackgroundColor3 = theme.Accent, BorderSizePixel = 0, ZIndex = 504 }, mock)
    Corner(bead, 5)
    return mock, ring
end

BuildSetupFlow = function(W, onDone)
    local ScreenGui = W.ScreenGui

    -- Only the steps that haven't been dismissed.
    local steps = {}
    if not Prefs.SkipLanguage then table.insert(steps, "language") end
    if not Prefs.SkipTheme then table.insert(steps, "theme") end
    if not Prefs.SkipFont then table.insert(steps, "font") end
    if #steps == 0 then
        if onDone then onDone() end
        return
    end

    local rows = math.ceil(#ThemeOrder / SETUP_COLUMNS)
    local gridW = SETUP_COLUMNS * SETUP_CARD_W + (SETUP_COLUMNS - 1) * SETUP_GAP
    local designW = gridW + 72
    local designH = 104 + rows * (SETUP_CARD_H + 22 + SETUP_GAP) + 16 + 52 + 34

    if W.Blur then Tween(W.Blur, Motion.Blur, { Size = W.Info.BlurSize }) end

    local overlay = New("Frame", {
        Name = "Setup",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 500,
    }, ScreenGui)
    Tween(overlay, Motion.FadeIn, { BackgroundTransparency = 0.35 })

    local panel = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(designW, designH),
        ZIndex = 501,
    }, overlay)
    local panelScale = New("UIScale", { Scale = 1 }, panel)
    GlassShadow(panel, 40, "ShadowTransparency", 500)
    PopupMaterial(panel, 20, 560)

    local function fitScale()
        local vp = viewportSize()
        return math.min(1, vp.X * 0.92 / designW, vp.Y * 0.92 / designH)
    end
    panelScale.Scale = fitScale() * 0.96
    Tween(panelScale, Motion.Expand, { Scale = fitScale() })
    W.OnSetupViewport = function() panelScale.Scale = fitScale() end

    local title = Themed(Text(panel, {
        Text = "",
        TextSize = 22,
        TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.fromOffset(0, 30),
        Size = UDim2.new(1, 0, 0, 28),
        ZIndex = 502,
    }), { TextColor3 = "TextPrimary" })
    local subtitle = Themed(Text(panel, {
        Text = "",
        FontFace = FONT_MEDIUM,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.fromOffset(0, 60),
        Size = UDim2.new(1, 0, 0, 18),
        ZIndex = 502,
    }), { TextColor3 = "TextMuted" })

    -- Step dots
    local dots = {}
    local dotRow = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(designW / 2, 84),
        Size = UDim2.fromOffset(#steps * 18, 8),
        ZIndex = 502,
    }, panel)
    for i = 1, #steps do
        local dot = Themed(New("Frame", {
            Position = UDim2.fromOffset((i - 1) * 18, 0),
            Size = UDim2.fromOffset(8, 8),
            BorderSizePixel = 0,
            ZIndex = 502,
        }, dotRow), { BackgroundColor3 = "Accent" })
        Corner(dot, 4)
        dots[i] = dot
    end

    local content = New("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.fromOffset(designW / 2, 104),
        Size = UDim2.fromOffset(gridW, designH - 104 - 86),
        ZIndex = 502,
    }, panel)

    -- "Don't show this again"
    local skipBox = New("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(36, designH - 62),
        Size = UDim2.fromOffset(260, 26),
        ZIndex = 502,
    }, panel)
    local skipMark = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        ZIndex = 503,
    }, skipBox)
    FieldMaterial(skipMark, 5)
    local skipFill = Themed(New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 504,
    }, skipMark), { BackgroundColor3 = "Accent" })
    Corner(skipFill, 5)
    local _, skipCheck = CheckGlyph(skipMark, 505)
    local skipLabel = Themed(Text(skipBox, {
        Text = "",
        FontFace = FONT_MEDIUM,
        TextSize = 12,
        Position = UDim2.fromOffset(26, 0),
        Size = UDim2.new(1, -26, 1, 0),
        ZIndex = 503,
    }), { TextColor3 = "TextMuted" })

    local skipChecked = false
    skipBox.MouseButton1Click:Connect(function()
        skipChecked = not skipChecked
        Tween(skipFill, Motion.Hover, { BackgroundTransparency = skipChecked and 0 or 1 })
        skipCheck(skipChecked)
    end)

    local continueButton = New("TextButton", {
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromOffset(designW - 36, designH - 68),
        Size = UDim2.fromOffset(190, 42),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 502,
    }, panel)
    Corner(continueButton, 12)
    Themed(New("UIGradient", { Rotation = 25 }, continueButton), { Color = accentSequence })
    Themed(New("UIStroke", { Thickness = 1, Transparency = 0.5 }, continueButton), { Color = "Rim" })
    local continueScale = New("UIScale", { Scale = 1 }, continueButton)
    local continueLabel = Themed(Text(continueButton, {
        Text = "",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 503,
    }), { TextColor3 = "Knob" })
    continueButton.MouseEnter:Connect(function() Tween(continueScale, Motion.Pop, { Scale = 1.03 }) end)
    continueButton.MouseLeave:Connect(function() Tween(continueScale, Motion.Pop, { Scale = 1 }) end)

    ---------------------------------------------------------------------------------------------------
    -- Steps
    ---------------------------------------------------------------------------------------------------
    local index = 1
    local refreshLabels

    local function clearContent()
        for _, child in ipairs(content:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
    end

    local function selectable(x, y, width, height, onClick)
        local card = New("TextButton", {
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(width, height),
            ZIndex = 502,
        }, content)
        local scale = New("UIScale", { Scale = 1 }, card)
        card.MouseEnter:Connect(function() Tween(scale, Motion.Pop, { Scale = 1.04 }) end)
        card.MouseLeave:Connect(function() Tween(scale, Motion.Pop, { Scale = 1 }) end)
        card.MouseButton1Click:Connect(onClick)
        return card
    end

    local function buildLanguage()
        local rings = {}
        local cardW, cardH = 148, 68
        local function paint()
            for code, ring in pairs(rings) do
                local on = Library.Language == code
                Tween(ring, Motion.Hover, { Thickness = on and 2 or 1, Transparency = on and 0 or 0.6 })
            end
        end
        for i, entry in ipairs(Languages) do
            local column, row = (i - 1) % SETUP_COLUMNS, math.floor((i - 1) / SETUP_COLUMNS)
            local card = selectable(column * (cardW + SETUP_GAP), row * (cardH + SETUP_GAP + 8), cardW, cardH, function()
                Library:SetLanguage(entry.Code)
                paint()
                refreshLabels()
            end)
            local plate = Themed(New("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 0.88,
                BorderSizePixel = 0,
                ZIndex = 503,
            }, card), { BackgroundColor3 = "LensTint" })
            Corner(plate, 12)
            rings[entry.Code] = Themed(New("UIStroke", { Thickness = 1, Transparency = 0.6 }, plate), { Color = "Accent" })
            Themed(Text(plate, {
                Text = entry.Native,
                TextSize = 15,
                TextXAlignment = Enum.TextXAlignment.Center,
                Position = UDim2.fromOffset(0, 14),
                Size = UDim2.new(1, 0, 0, 20),
                ZIndex = 504,
            }), { TextColor3 = "TextPrimary" })
            Themed(Text(plate, {
                Text = entry.Name,
                FontFace = FONT_MEDIUM,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Center,
                Position = UDim2.fromOffset(0, 36),
                Size = UDim2.new(1, 0, 0, 16),
                ZIndex = 504,
            }), { TextColor3 = "TextMuted" })
        end
        paint()
    end

    local function buildTheme()
        local rings = {}
        local function paint()
            for name, ring in pairs(rings) do
                local on = Library.Theme == name
                Tween(ring, Motion.Hover, { Thickness = on and 2 or 1, Transparency = on and 0 or 0.6 })
            end
        end
        for i, name in ipairs(ThemeOrder) do
            local theme = Themes[name]
            local column, row = (i - 1) % SETUP_COLUMNS, math.floor((i - 1) / SETUP_COLUMNS)
            local card = selectable(column * (SETUP_CARD_W + SETUP_GAP), row * (SETUP_CARD_H + 22 + SETUP_GAP),
                SETUP_CARD_W, SETUP_CARD_H + 22, function()
                    Library:SetTheme(name)
                    paint()
                end)
            local _, ring = themeMock(card, theme, SETUP_CARD_W, SETUP_CARD_H)
            rings[name] = ring
            Themed(Text(card, {
                Text = name,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Center,
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, 18),
                ZIndex = 503,
            }), { TextColor3 = function() return Library.Theme == name and Glass.TextPrimary or Glass.TextSecondary end })
        end
        paint()
    end

    local function buildFont()
        local rings = {}
        local cardW, cardH = 180, 84
        local columns = 4
        local function paint()
            for name, ring in pairs(rings) do
                local on = Library.FontFamily == name
                Tween(ring, Motion.Hover, { Thickness = on and 2 or 1, Transparency = on and 0 or 0.6 })
            end
        end
        for i, entry in ipairs(FontFamilies) do
            local column, row = (i - 1) % columns, math.floor((i - 1) / columns)
            local offsetX = (gridW - (columns * cardW + (columns - 1) * SETUP_GAP)) / 2
            local card = selectable(offsetX + column * (cardW + SETUP_GAP), row * (cardH + SETUP_GAP), cardW, cardH, function()
                Library:SetFontFamily(entry.Name)
                paint()
                refreshLabels()
            end)
            local plate = Themed(New("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 0.88,
                BorderSizePixel = 0,
                ZIndex = 503,
            }, card), { BackgroundColor3 = "LensTint" })
            Corner(plate, 12)
            rings[entry.Name] = Themed(New("UIStroke", { Thickness = 1, Transparency = 0.6 }, plate), { Color = "Accent" })
            local base = Font.fromEnum(entry.Font)
            New("TextLabel", {
                BackgroundTransparency = 1,
                Text = "Aa",
                FontFace = Font.new(base.Family, Enum.FontWeight.Bold),
                TextSize = 28,
                TextColor3 = Glass.TextPrimary,
                Position = UDim2.fromOffset(0, 10),
                Size = UDim2.new(1, 0, 0, 34),
                ZIndex = 504,
            }, plate)
            New("TextLabel", {
                BackgroundTransparency = 1,
                Text = entry.Name,
                FontFace = Font.new(base.Family, Enum.FontWeight.Medium),
                TextSize = 12,
                TextColor3 = Glass.TextMuted,
                Position = UDim2.fromOffset(0, 50),
                Size = UDim2.new(1, 0, 0, 18),
                ZIndex = 504,
            }, plate)
        end
        paint()
    end

    function refreshLabels()
        local step = steps[index]
        title.Text = T("title_" .. step)
        subtitle.Text = T("subtitle")
        continueLabel.Text = T("continue_")
        skipLabel.Text = T("dont_show_again")
        for i, dot in ipairs(dots) do
            dot.BackgroundTransparency = i == index and 0 or 0.65
        end
    end

    local function showStep(newIndex)
        index = newIndex
        clearContent()
        skipChecked = false
        skipFill.BackgroundTransparency = 1
        skipCheck(false, true)
        local step = steps[index]
        if step == "language" then
            buildLanguage()
        elseif step == "theme" then
            buildTheme()
        else
            buildFont()
        end
        refreshLabels()
        content.Position = UDim2.fromOffset(designW / 2, 116)
        Tween(content, Motion.Settle, { Position = UDim2.fromOffset(designW / 2, 104) })
    end

    local closed = false
    local function finish()
        if closed then return end
        closed = true
        W.OnSetupViewport = nil
        savePrefs()
        Tween(panelScale, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Scale = fitScale() * 0.9 })
        Tween(overlay, Motion.FadeOut, { BackgroundTransparency = 1 })
        task.delay(0.28, function()
            overlay:Destroy()
            if onDone then onDone() end
        end)
    end

    continueButton.MouseButton1Click:Connect(function()
        if closed then return end
        local step = steps[index]
        if skipChecked then
            if step == "language" then Prefs.SkipLanguage = true
            elseif step == "theme" then Prefs.SkipTheme = true
            else Prefs.SkipFont = true end
        end
        if index < #steps then
            showStep(index + 1)
        else
            finish()
        end
    end)

    showStep(1)

    local previousViewport = W.OnViewportChanged
    W.OnViewportChanged = function()
        if previousViewport then previousViewport() end
        if W.OnSetupViewport then W.OnSetupViewport() end
    end
end

-- ===== 25_rail.lua =====
-------------------------------------------------------------------------------------------------------
-- Edge rail
--
-- Shove the window off the left or right side of the screen and it collapses into a slim strip of glass
-- carrying one icon per tab. Click an icon to come back on that tab; double-tap the rail to come back
-- where you left off. It is the "keep it up while playing" mode: the interface is still there, but it
-- costs 52 pixels instead of half the screen.
-------------------------------------------------------------------------------------------------------
local RAIL_ICON = 30
local RAIL_PAD = 9

BuildRail = function(W)
    local ScreenGui, Holder, Window = W.ScreenGui, W.Holder, W.Window

    local Rail = New("Frame", {
        Name = "EdgeRail",
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(L.EdgeRailWidth, 120),
        Visible = false,
        ZIndex = 180,
    }, ScreenGui)
    local RailScale = New("UIScale", { Scale = 1 }, Rail)
    GlassShadow(Rail, 16, "ShadowTransparency", 0)

    -- CanvasGroup only for the fade; the glass goes on an inner Frame. A UIGradient parented to a
    -- CanvasGroup multiplies over every child it renders, which would black out the tab icons.
    local Body = New("CanvasGroup", {
        Name = "Body",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        GroupTransparency = 1,
        ZIndex = 2,
    }, Rail)
    local Surface = New("Frame", {
        Name = "Surface",
        Size = UDim2.fromScale(1, 1),
        ZIndex = 1,
    }, Body)
    local RailPane = PaneMaterial(Surface, 16, 40)
    -- The rail sits on top of gameplay, not on the window's glass, so it stays close to opaque.
    Themed(Surface, { BackgroundTransparency = function() return math.min(Glass.PaneTransparency, 0.1) end })

    local Hit = New("TextButton", {
        Name = "Hitbox", Text = "", AutoButtonColor = false,
        BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 40,
    }, Rail)

    local side, active, icons = "Left", false, {}

    -- The grabber: a short bar on the screen-facing side, the handle you'd pull to open it again.
    local Grabber = Themed(New("Frame", {
        Name = "Grabber",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(3, 26),
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        ZIndex = 30,
    }, Body), { BackgroundColor3 = "Accent" })
    Corner(Grabber, 2)

    local function clearIcons()
        for _, icon in ipairs(icons) do icon.Button:Destroy() end
        table.clear(icons)
    end

    -- One button per tab, in the sidebar's current order. Rebuilt on every entry so a reordered or
    -- newly added tab is always represented.
    local function buildIcons()
        clearIcons()
        for i, tab in ipairs(Window.Tabs) do
            local button = New("TextButton", {
                Name = "Rail_" .. tab.Name,
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, RAIL_PAD + (i - 1) * (RAIL_ICON + 6)),
                Size = UDim2.fromOffset(RAIL_ICON + 6, RAIL_ICON),
                ZIndex = 20,
            }, Body)
            local plate = Themed(New("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = Window.ActiveTab == tab and 0.86 or 1,
                BorderSizePixel = 0,
                ZIndex = 20,
            }, button), { BackgroundColor3 = "LensTint" })
            Corner(plate, 9)
            local scale = New("UIScale", { Scale = 1 }, button)

            local glyph
            if tab.IconImage then
                glyph = Themed(New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(L.IconSize, L.IconSize),
                    BackgroundTransparency = 1,
                    Image = tab.IconImage.Image,
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 21,
                }, button), { ImageColor3 = function() return Window.ActiveTab == tab and Glass.TextPrimary or Glass.Glyph end })
            else
                -- No icon: the tab's initial stands in for it.
                glyph = Themed(Text(button, {
                    Text = tab.Name:sub(1, 1):upper(),
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Size = UDim2.fromScale(1, 1),
                    ZIndex = 21,
                }), { TextColor3 = function() return Window.ActiveTab == tab and Glass.TextPrimary or Glass.Glyph end })
            end

            button.MouseEnter:Connect(function()
                Tween(plate, Motion.Hover, { BackgroundTransparency = 0.86 })
                Tween(scale, Motion.Pop, { Scale = 1.12 })
                playSound("Hover")
                W:ShowTooltip(button, tab.Name)
            end)
            button.MouseLeave:Connect(function()
                if Window.ActiveTab ~= tab then Tween(plate, Motion.Hover, { BackgroundTransparency = 1 }) end
                Tween(scale, Motion.Pop, { Scale = 1 })
                W:HideTooltip(button)
            end)
            button.MouseButton1Click:Connect(function()
                W.ExitRail()
                tab:Show()
            end)
            icons[i] = { Button = button, Plate = plate, Glyph = glyph, Tab = tab }
        end
        Rail.Size = UDim2.fromOffset(L.EdgeRailWidth, RAIL_PAD * 2 + math.max(1, #Window.Tabs) * (RAIL_ICON + 6) - 6)
    end

    -- Where the rail rests, and where it starts from so it appears to slide in out of the screen edge.
    local function restingX()
        if side == "Left" then return 0 end
        return ScreenGui.AbsoluteSize.X - L.EdgeRailWidth
    end
    local function hiddenX()
        if side == "Left" then return -L.EdgeRailWidth end
        return ScreenGui.AbsoluteSize.X
    end

    function W.EnterRail(toSide)
        if active or not Window.ActiveTab then return end
        side = toSide == "Right" and "Right" or "Left"
        active = true
        W.RailActive = true
        W:ClosePopup()
        W:HideTooltip()
        W.EndTabDrag()

        buildIcons()
        -- Round off only the two corners facing the screen; the edge-facing side runs flush off it.
        Grabber.Position = UDim2.new(side == "Left" and 1 or 0, side == "Left" and -6 or 6, 0.5, 0)

        Holder.Visible = false
        if W.OnWindowVisibility then W.OnWindowVisibility(false) end
        if W.Blur then Tween(W.Blur, Motion.Blur, { Size = 0 }) end

        Rail.Visible = true
        Rail.Position = UDim2.new(0, hiddenX(), 0.5, 0)
        RailScale.Scale = 0.9
        Tween(Rail, Motion.Slide, { Position = UDim2.new(0, restingX(), 0.5, 0) })
        Tween(RailScale, Motion.Pop, { Scale = 1 })
        Tween(Body, Motion.IntroSoft, { GroupTransparency = 0 })
        playSound("Close")

        -- Icons arrive one after another rather than all at once.
        for i, icon in ipairs(icons) do
            icon.Button.Position = UDim2.new(0.5, side == "Left" and -14 or 14, 0, RAIL_PAD + (i - 1) * (RAIL_ICON + 6))
            task.delay(0.06 + i * 0.04, function()
                if not active then return end
                Tween(icon.Button, Motion.Intro, {
                    Position = UDim2.new(0.5, 0, 0, RAIL_PAD + (i - 1) * (RAIL_ICON + 6)),
                })
            end)
        end
    end

    function W.ExitRail()
        if not active then return end
        active = false
        W.RailActive = false
        W:HideTooltip()
        Tween(Rail, Motion.Outro, { Position = UDim2.new(0, hiddenX(), 0.5, 0) })
        Tween(Body, Motion.Outro, { GroupTransparency = 1 })
        playSound("Open")
        task.delay(Motion.Outro.Time, function()
            if active then return end
            Rail.Visible = false
            clearIcons()
        end)

        -- Come back tucked just inside the edge the rail was on, not wherever the window was shoved to.
        local ss = ScreenGui.AbsoluteSize
        local half = Vector2.new(Holder.Size.X.Offset, Holder.Size.Y.Offset) * W.Scale.Scale / 2
        local x = if side == "Left" then half.X + L.WindowMargin else ss.X - half.X - L.WindowMargin
        Holder.Position = UDim2.fromOffset(
            if side == "Left" then x - 40 else x + 40,
            math.clamp(Holder.Position.Y.Offset, half.Y, math.max(half.Y, ss.Y - half.Y))
        )
        Library:Toggle(true)
        Tween(Holder, Motion.Intro, { Position = UDim2.fromOffset(x, Holder.Position.Y.Offset) })
    end

    -- Double-tap anywhere on the rail brings the window back as it was.
    local lastTap = 0
    Hit.MouseButton1Click:Connect(function()
        local now = os.clock()
        if now - lastTap < 0.35 then
            lastTap = 0
            W.ExitRail()
        else
            lastTap = now
            -- A single tap just leans the rail out, as a hint that there is more here.
            Tween(RailScale, Motion.Pop, { Scale = 1.05 })
            task.delay(0.18, function()
                if active then Tween(RailScale, Motion.Pop, { Scale = 1 }) end
            end)
        end
    end)
    Hit.MouseEnter:Connect(function()
        Tween(RailPane.Edge, Motion.Hover, { ImageTransparency = 0.25 })
        Tween(Grabber, Motion.Hover, { BackgroundTransparency = 0.1, Size = UDim2.fromOffset(3, 34) })
    end)
    Hit.MouseLeave:Connect(function()
        Tween(RailPane.Edge, Motion.Hover, { ImageTransparency = Glass.EdgeTransparency })
        Tween(Grabber, Motion.Hover, { BackgroundTransparency = 0.45, Size = UDim2.fromOffset(3, 26) })
    end)

    local previousViewport = W.OnViewportChanged
    W.OnViewportChanged = function()
        if previousViewport then previousViewport() end
        if active then Rail.Position = UDim2.new(0, restingX(), 0.5, 0) end
    end

    W.Rail = Rail
end

-- ===== 30_api.lua =====
-------------------------------------------------------------------------------------------------------
-- Library API
-------------------------------------------------------------------------------------------------------
function Library:Toggle(value)
    if self.Unloaded or not self.Window then return end
    -- In edge-rail mode the window is parked off-screen: any toggle brings it back rather than trying to
    -- show a window that is not where the user left it. ExitRail clears the flag before calling back in.
    local W = self.Window._W
    if W and W.RailActive then
        W.ExitRail()
        return
    end
    if value == nil then value = not self.Toggled end
    self.Toggled = value
    self.Window:_setVisible(value)
end

-- Morphs the whole palette to the named theme, colours and material alike, and remembers the choice.
function Library:SetTheme(name)
    local theme = Themes[name]
    if not theme or self.Unloaded then return false end
    self.Theme = name
    self.AccentGradient = nil -- a new theme starts from its own accent; the palette can recustomise after

    local from = {}
    for key in pairs(theme) do from[key] = Glass[key] end
    if self.ThemeMorph then self.ThemeMorph:Disconnect() end

    -- In-between frames only repaint what moved (the shared tokens and every font binding stay put); the
    -- last frame repaints everything, so the end state is exactly what a full apply produces.
    local function blend(alpha, final)
        for key, target in pairs(theme) do
            local start = from[key]
            if typeof(start) == "number" then
                Glass[key] = start + (target - start) * alpha
            else
                Glass[key] = start:Lerp(target, alpha)
            end
        end
        applyTheme(not final)
    end

    local elapsed = 0
    self.ThemeMorph = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        local t = math.min(1, elapsed / THEME_MORPH_TIME)
        blend(TweenService:GetValue(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), t >= 1)
        if t >= 1 then
            self.ThemeMorph:Disconnect()
            self.ThemeMorph = nil
            syncScheme()
            self:UpdateKeybindFrame()
        end
    end)

    saveThemeChoice(name)
    local window = self.Window
    if window and window._W then
        window._W:OnThemeChanged()
        if window.OnThemeChanged then task.spawn(window.OnThemeChanged, name) end
    end
    return true
end

-- Wipes the saved language, font, theme and "don't show again" choices, then walks the setup flow again.
function Library:FactoryReset()
    clearPrefs()
    self.AccentGradient = nil
    self:SetLanguage("en")
    self:SetFontFamily("Gotham")
    self:SetTheme("Amethyst")
    local window = self.Window
    if window and window.ShowSetup then
        self:Toggle(false)
        task.delay(0.35, function() window:ShowSetup() end)
    end
    return true
end

-- Obsidian's five scheme keys map onto the closest FishyUI tokens; any token can also be named directly,
-- which is how a custom theme carries material values (PaneTransparency, EdgeTransparency, ...) that the
-- five-colour scheme has no room for. ThemeManager uses this for themes that aren't one of the built-ins.
local SCHEME_TO_TOKEN = {
    BackgroundColor = "PaneMid",
    MainColor = "PaneTop",
    AccentColor = "AccentDeep",
    OutlineColor = "Rim",
    FontColor = "TextPrimary",
    RedColor = "Danger",
    DarkColor = "PaneBottom",
}

function Library:ApplyScheme(scheme)
    if typeof(scheme) ~= "table" then return false end
    for key, value in pairs(scheme) do
        local token = SCHEME_TO_TOKEN[key] or key
        local current = Glass[token]
        if current ~= nil and typeof(value) == typeof(current) then
            Glass[token] = value
        end
    end
    applyTheme()
    syncScheme()
    self:UpdateKeybindFrame()
    return true
end

-- A flat copy of the live palette, suitable for writing to disk and handing back to ApplyScheme.
function Library:GetScheme()
    local copy = {}
    for key, value in pairs(Glass) do copy[key] = value end
    return copy
end

function Library:SetDPIScale(percent)
    self.DPIScale = percent / 100
    if self.Window then self.Window:_rescale() end
end

function Library:OnUnload(callback)
    table.insert(self.UnloadSignals, callback)
end

function Library:Unload()
    if self.Unloaded then return end
    self.Unloaded = true
    if self.ThemeMorph then self.ThemeMorph:Disconnect() end
    Animator.Stop()
    for _, connection in ipairs(self.Signals) do
        pcall(function() connection:Disconnect() end)
    end
    for _, callback in ipairs(self.UnloadSignals) do
        task.spawn(callback)
    end
    local W = self.Window and self.Window._W
    if W and W.Blur then pcall(function() W.Blur:Destroy() end) end
    if self.ScreenGui then pcall(function() self.ScreenGui:Destroy() end) end
    if notifyStack then pcall(function() notifyStack:Destroy() end) end
    if notifyGui then pcall(function() notifyGui:Destroy() end) end
    -- The UI voices live in SoundService, outside the ScreenGui, so nothing above takes them with it;
    -- every re-execution used to leave another set behind.
    for name, sound in pairs(voiceSounds) do
        pcall(function() sound:Destroy() end)
        voiceSounds[name] = nil
    end
    table.clear(self.Registry)
    table.clear(ThemeWritten)
end

ENV.Library = Library
return Library
