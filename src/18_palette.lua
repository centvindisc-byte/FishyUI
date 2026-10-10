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
