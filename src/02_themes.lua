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
local THEME_MORPH_STEP = 1 / 40 -- seconds between palette applies while a theme cross-fades

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

-- Wraps a gradient builder so it hands back the same sequence object for as long as its inputs are
-- unchanged. Gradients bound to the palette then compare equal to what they already show, and a re-apply
-- (a new accent, a font change, most frames of a theme morph for tokens that aren't moving) skips them
-- instead of rebuilding and rewriting every one.
local function cachedSequence(build)
    local lastA, lastB, lastC, last
    return function(a, b, c)
        if last == nil or a ~= lastA or b ~= lastB or c ~= lastC then
            lastA, lastB, lastC = a, b, c
            last = build(a, b, c)
        end
        return last
    end
end

local buildPaneGradient = cachedSequence(function(top, mid, bottom)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, top),
        ColorSequenceKeypoint.new(0.5, mid),
        ColorSequenceKeypoint.new(1.0, bottom),
    })
end)
local function paneGradientColor()
    return buildPaneGradient(Glass.PaneTop, Glass.PaneMid, Glass.PaneBottom)
end

local buildEdgeGradient = cachedSequence(function(mid, low)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(0.40, mid),
        ColorSequenceKeypoint.new(1.00, low),
    })
end)
local function edgeGradientColor()
    return buildEdgeGradient(Glass.EdgeMid, Glass.EdgeLow)
end

local buildSheen = cachedSequence(function(top)
    return NumberSequence.new({
        NumberSequenceKeypoint.new(0, top),
        NumberSequenceKeypoint.new(0.55, top + (1 - top) * 0.65),
        NumberSequenceKeypoint.new(1, 1),
    })
end)
local function sheenTransparency()
    return buildSheen(Glass.SheenTransparency)
end
