-------------------------------------------------------------------------------------------------------
-- Palette: a paint-palette-shaped gradient editor.
--
-- The palette blob at the top carries one glossy dab per gradient stop, arranged along its arc. Beneath
-- it the live ramp shows the gradient itself, with a draggable chip for every stop sitting right on it —
-- drag a chip to slide the stop, click to select, right-click to remove. The selected dab is repainted
-- with the shade square, the hue rail, a hex field or one of the preset ramps.
--
-- Endpoints stay pinned at 0 and 1 so the ColorSequence is always valid. Every edit recolours the whole
-- interface live through Library:SetAccentGradient.
-------------------------------------------------------------------------------------------------------
local PALETTE_WIDTH = 340
local PALETTE_MAX_STOPS = 8

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
    { Name = "Sunset", Colors = { Color3.fromRGB(255, 94, 91), Color3.fromRGB(255, 176, 84), Color3.fromRGB(255, 231, 142) } },
    { Name = "Ocean", Colors = { Color3.fromRGB(28, 108, 222), Color3.fromRGB(72, 214, 236) } },
    { Name = "Mint", Colors = { Color3.fromRGB(24, 178, 134), Color3.fromRGB(150, 255, 208) } },
    { Name = "Candy", Colors = { Color3.fromRGB(255, 92, 170), Color3.fromRGB(168, 120, 255), Color3.fromRGB(96, 214, 255) } },
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

-- Opens the editor near `anchor`. `stops` is the working set (mutated); `onLive(sequence)` fires on every
-- change; `onReset()` reseeds from the theme.
local function openPaletteEditor(W, anchor, stops, onLive, onReset)
    local selected = 1

    -- Derived rather than hardcoded so the panel stays consistent when a block is resized. The whole
    -- thing has to clear the 400px minimum window height, since a popup taller than the window would
    -- hang off the bottom no matter where it is anchored.
    local BLOB_Y, BLOB_H = 36, 86
    local RAMP_Y, RAMP_H = BLOB_Y + BLOB_H + 12, 24
    local EDIT_Y = RAMP_Y + RAMP_H + 16
    local SB = 104
    local RIGHT_X = 14 + SB + 12
    local RIGHT_W = PALETTE_WIDTH - 28 - SB - 12
    local ACTION_Y = EDIT_Y + SB + 16
    local FOOTER_Y = ACTION_Y + 26 + 8
    local editorHeight = FOOTER_Y + 28 + 12

    local panel = New("Frame", { Name = "PalettePanel", Size = UDim2.fromOffset(PALETTE_WIDTH, 0), ClipsDescendants = true }, nil)
    PopupMaterial(panel, 14, 40)
    W:PlacePopup(panel, anchor, 8, editorHeight)

    Themed(Text(panel, {
        Text = "Gradient",
        TextSize = 12,
        Position = UDim2.fromOffset(14, 12),
        Size = UDim2.new(1, -28, 0, 18),
        ZIndex = 2,
    }), { TextColor3 = "TextPrimary" })
    local countLabel = Themed(Text(panel, {
        Text = "",
        FontFace = FONT_MEDIUM,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -36, 0, 12),
        Size = UDim2.fromOffset(140, 18),
        ZIndex = 2,
    }), { TextColor3 = "TextMuted" })
    PopupClose(panel, W)

    ---------------------------------------------------------------------------------------------------
    -- The palette blob: the gradient washed across a painter's palette, with a dab per stop.
    ---------------------------------------------------------------------------------------------------
    local blob = New("Frame", {
        Position = UDim2.fromOffset(14, BLOB_Y),
        Size = UDim2.fromOffset(PALETTE_WIDTH - 28, BLOB_H),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, panel)
    New("UICorner", { CornerRadius = UDim.new(0, 44) }, blob)
    local blobWash = New("UIGradient", { Rotation = 12, Transparency = NumberSequence.new(0.4) }, blob)
    Themed(New("UIStroke", { Thickness = 1, Transparency = 0.45 }, blob), { Color = "Rim" })
    Specular(blob, 60, 0.45, 3)
    local thumbHole = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.87, 0.74),
        Size = UDim2.fromOffset(28, 28),
        BorderSizePixel = 0,
        ZIndex = 3,
    }, blob), { BackgroundColor3 = "PaneBottom" })
    New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, thumbHole)
    Themed(New("UIStroke", { Thickness = 1, Transparency = 0.6 }, thumbHole), { Color = "Rim" })
    local dabHolder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 4 }, blob)

    ---------------------------------------------------------------------------------------------------
    -- The live ramp, with a draggable chip per stop sitting on it.
    ---------------------------------------------------------------------------------------------------
    local ramp = New("Frame", {
        Position = UDim2.fromOffset(14, RAMP_Y),
        Size = UDim2.fromOffset(PALETTE_WIDTH - 28, RAMP_H),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 2,
    }, panel)
    Corner(ramp, 10)
    local rampGradient = New("UIGradient", {}, ramp)
    Themed(New("UIStroke", { Thickness = 1, Transparency = 0.55 }, ramp), { Color = "Rim" })
    local chipHolder = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, RAMP_Y - 5),
        Size = UDim2.fromOffset(PALETTE_WIDTH - 28, RAMP_H + 10),
        ZIndex = 6,
    }, panel)

    ---------------------------------------------------------------------------------------------------
    -- Shade square, hue rail, hex field and presets for the selected stop.
    ---------------------------------------------------------------------------------------------------
    local sb = New("Frame", {
        Position = UDim2.fromOffset(14, EDIT_Y),
        Size = UDim2.fromOffset(SB, SB),
        BorderSizePixel = 0,
        ZIndex = 2,
    }, panel)
    Corner(sb, 9)
    local sbWhite = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3 }, sb)
    Corner(sbWhite, 9)
    New("UIGradient", { Transparency = NumberSequence.new(0, 1) }, sbWhite)
    local sbBlack = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 4 }, sb)
    Corner(sbBlack, 9)
    New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, sbBlack)
    Themed(New("UIStroke", { Thickness = 1, Transparency = 0.6 }, sb), { Color = "Rim" })
    local sbCursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(13, 13),
        BackgroundTransparency = 1,
        ZIndex = 6,
    }, sb)
    Corner(sbCursor, 7)
    New("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }, sbCursor)
    New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0.65 }, sbCursor)

    local hueRail = New("Frame", {
        Position = UDim2.fromOffset(RIGHT_X, EDIT_Y),
        Size = UDim2.fromOffset(RIGHT_W, 14),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 2,
    }, panel)
    Corner(hueRail, 7)
    New("UIGradient", { Color = hueSequence() }, hueRail)
    local hueThumb = railThumb(hueRail)

    -- Hex field: a swatch of the live colour next to an editable value.
    local hexField = New("Frame", {
        Position = UDim2.fromOffset(RIGHT_X, EDIT_Y + 24),
        Size = UDim2.fromOffset(RIGHT_W, 26),
        ZIndex = 2,
    }, panel)
    FieldMaterial(hexField, 7)
    local hexSwatch = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 6, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BorderSizePixel = 0,
        ZIndex = 3,
    }, hexField)
    Corner(hexSwatch, 4)
    Themed(New("UIStroke", { Thickness = 1, Transparency = 0.5 }, hexSwatch), { Color = "Rim" })
    local hexBox = Themed(New("TextBox", {
        BackgroundTransparency = 1,
        ClearTextOnFocus = false,
        FontFace = FONT_MONO,
        Text = "",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(26, 0),
        Size = UDim2.new(1, -32, 1, 0),
        ZIndex = 3,
    }, hexField), { TextColor3 = "TextPrimary" })

    Themed(Text(panel, {
        Text = "Presets",
        FontFace = FONT_MEDIUM,
        TextSize = 11,
        Position = UDim2.fromOffset(RIGHT_X, EDIT_Y + 58),
        Size = UDim2.fromOffset(RIGHT_W, 12),
        ZIndex = 2,
    }), { TextColor3 = "TextMuted" })

    ---------------------------------------------------------------------------------------------------
    -- Buttons
    ---------------------------------------------------------------------------------------------------
    local function smallButton(text, x, width, y, tone)
        local button = New("TextButton", {
            Text = "",
            AutoButtonColor = false,
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(width, 26),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.88,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, panel)
        Corner(button, 7)
        Themed(button, { BackgroundColor3 = tone or "LensTint" })
        local stroke = Themed(New("UIStroke", { Thickness = 1, Transparency = 0.6 }, button), { Color = tone or "Rim" })
        local label = Themed(Text(button, {
            Text = text,
            FontFace = FONT_MEDIUM,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 3,
        }), { TextColor3 = tone or "TextPrimary" })
        button.MouseEnter:Connect(function()
            Tween(button, Motion.Hover, { BackgroundTransparency = 0.76 })
            playSound("Hover")
        end)
        button.MouseLeave:Connect(function() Tween(button, Motion.Hover, { BackgroundTransparency = 0.88 }) end)
        return button, label, stroke
    end

    local actionWidth = (PALETTE_WIDTH - 28 - 12) / 3
    local addButton = smallButton("+ Stop", 14, actionWidth, ACTION_Y)
    local removeButton, removeLabel = smallButton("Remove", 14 + actionWidth + 6, actionWidth, ACTION_Y)
    local reverseButton = smallButton("Reverse", 14 + (actionWidth + 6) * 2, actionWidth, ACTION_Y)
    Themed(removeLabel, { TextColor3 = "Danger" })
    local resetButton = smallButton("Reset to theme", 14, 124, FOOTER_Y)
    local applyButton, applyLabel = smallButton("Done", 146, PALETTE_WIDTH - 28 - 132, FOOTER_Y, "Accent")
    Themed(applyLabel, { TextColor3 = "Knob" })

    ---------------------------------------------------------------------------------------------------
    -- Rendering
    ---------------------------------------------------------------------------------------------------
    local render
    local dabs, chips = {}, {}

    local function selectStop(index)
        selected = math.clamp(index, 1, #stops)
        playSound("Press")
        render()
    end

    local function removeStop(index)
        if index == 1 or index == #stops or #stops <= 2 then return end
        table.remove(stops, index)
        selected = math.max(1, index - 1)
        playSound("Close")
        render(true)
    end

    -- One dab on the blob and one chip on the ramp per stop; both are rebuilt when the set changes.
    local function rebuildStops()
        for _, dab in ipairs(dabs) do dab.Frame:Destroy() end
        for _, chip in ipairs(chips) do chip.Frame:Destroy() end
        table.clear(dabs)
        table.clear(chips)

        for i, stop in ipairs(stops) do
            local index = i
            local t = stop.position

            -- Dab: sits along a gentle arc across the palette, ordered by position.
            local dab = New("TextButton", {
                Name = "Dab" .. i,
                Text = "",
                AutoButtonColor = false,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.09 + t * 0.62, 0, 0.46 + math.sin(t * math.pi) * -0.16, 0),
                Size = UDim2.fromOffset(30, 30),
                BackgroundColor3 = stop.color,
                BorderSizePixel = 0,
                ZIndex = 5,
            }, dabHolder)
            New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, dab)
            local gloss = New("Frame", { Size = UDim2.new(1, 0, 0.55, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 6 }, dab)
            New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, gloss)
            New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.45, 1) }, gloss)
            local dabRing = New("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1, Transparency = 0.5 }, dab)
            local dabScale = New("UIScale", { Scale = 1 }, dab)
            dab.MouseEnter:Connect(function() Tween(dabScale, Motion.Pop, { Scale = 1.12 }) end)
            dab.MouseLeave:Connect(function() Tween(dabScale, Motion.Pop, { Scale = index == selected and 1.08 or 1 }) end)
            dab.MouseButton1Click:Connect(function() selectStop(index) end)
            dab.MouseButton2Click:Connect(function() removeStop(index) end)
            dabs[i] = { Frame = dab, Ring = dabRing, Scale = dabScale }

            -- Chip: the same stop, sitting on the ramp where it actually lands.
            local chip = New("TextButton", {
                Name = "Chip" .. i,
                Text = "",
                AutoButtonColor = false,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(t, 0, 0.5, 0),
                Size = UDim2.fromOffset(16, RAMP_H + 8),
                BackgroundColor3 = stop.color,
                BorderSizePixel = 0,
                ZIndex = 7,
            }, chipHolder)
            Corner(chip, 6)
            local chipRing = New("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1.5, Transparency = 0.35 }, chip)
            New("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0.7 }, chip)
            chips[i] = { Frame = chip, Ring = chipRing }

            chip.MouseButton2Click:Connect(function() removeStop(index) end)
            -- Endpoints can be selected and recoloured but never moved.
            chip.InputBegan:Connect(function(input)
                if not isPointer(input) then return end
                selectStop(index)
                if index == 1 or index == #stops then return end
                local moveConnection, endConnection
                moveConnection = UserInputService.InputChanged:Connect(function(changed)
                    if not isMove(changed) then return end
                    local left = chipHolder.AbsolutePosition.X
                    local width = chipHolder.AbsoluteSize.X
                    if width <= 0 then return end
                    local pct = math.clamp((changed.Position.X - left) / width, 0.03, 0.97)
                    local mine = stops[selected]
                    if not mine then return end
                    mine.position = pct
                    table.sort(stops, function(a, b) return a.position < b.position end)
                    selected = table.find(stops, mine) or selected
                    playSound("Tick")
                    render()
                end)
                endConnection = input.Changed:Connect(function()
                    if input.UserInputState ~= Enum.UserInputState.End then return end
                    moveConnection:Disconnect()
                    endConnection:Disconnect()
                    render(true) -- re-seat the dabs and chips in their new order
                end)
            end)
        end
    end

    local hexFocused = false
    hexBox.Focused:Connect(function() hexFocused = true end)
    hexBox.FocusLost:Connect(function()
        hexFocused = false
        local color = fromHex(hexBox.Text)
        if color then
            stops[selected].color = color
            playSound("Press")
        end
        render()
    end)

    function render(rebuild)
        selected = math.clamp(selected, 1, #stops)
        if rebuild then rebuildStops() end

        local sequence = stopsToSequence(stops)
        rampGradient.Color = sequence
        blobWash.Color = sequence

        for i, stop in ipairs(stops) do
            local dab, chip = dabs[i], chips[i]
            if dab then
                dab.Frame.BackgroundColor3 = stop.color
                dab.Frame.Position = UDim2.new(0.09 + stop.position * 0.62, 0, 0.46 + math.sin(stop.position * math.pi) * -0.16, 0)
                dab.Ring.Thickness = i == selected and 2.5 or 1
                dab.Ring.Transparency = i == selected and 0 or 0.5
                dab.Scale.Scale = i == selected and 1.08 or 1
            end
            if chip then
                chip.Frame.BackgroundColor3 = stop.color
                chip.Frame.Position = UDim2.new(stop.position, 0, 0.5, 0)
                chip.Ring.Thickness = i == selected and 2.5 or 1.5
                chip.Ring.Transparency = i == selected and 0 or 0.35
            end
        end

        local stop = stops[selected]
        local hue, sat, val = stop.color:ToHSV()
        sb.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        sbCursor.Position = UDim2.fromScale(sat, 1 - val)
        hueThumb.Position = UDim2.fromScale(hue, 0.5)
        hexSwatch.BackgroundColor3 = stop.color
        if not hexFocused then hexBox.Text = toHex(stop.color) end

        local endpoint = selected == 1 or selected == #stops
        removeButton.Visible = not endpoint and #stops > 2
        addButton.Visible = #stops < PALETTE_MAX_STOPS
        countLabel.Text = string.format("%d stop%s · stop %d", #stops, #stops == 1 and "" or "s", selected)
        onLive(sequence)
    end

    ---------------------------------------------------------------------------------------------------
    -- Presets
    ---------------------------------------------------------------------------------------------------
    local PRESET_W, PRESET_H, PRESET_GAP = (RIGHT_W - 12) / 3, 20, 6
    for i, preset in ipairs(PALETTE_PRESETS) do
        local column, row = (i - 1) % 3, math.floor((i - 1) / 3)
        local swatch = New("TextButton", {
            Name = preset.Name,
            Text = "",
            AutoButtonColor = false,
            Position = UDim2.fromOffset(RIGHT_X + column * (PRESET_W + PRESET_GAP), EDIT_Y + 74 + row * (PRESET_H + PRESET_GAP)),
            Size = UDim2.fromOffset(PRESET_W, PRESET_H),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 2,
        }, panel)
        Corner(swatch, 6)
        New("UIGradient", { Color = presetSequence(preset.Colors) }, swatch)
        Themed(New("UIStroke", { Thickness = 1, Transparency = 0.6 }, swatch), { Color = "Rim" })
        local swatchScale = New("UIScale", { Scale = 1 }, swatch)
        swatch.MouseEnter:Connect(function()
            Tween(swatchScale, Motion.Pop, { Scale = 1.07 })
            playSound("Hover")
        end)
        swatch.MouseLeave:Connect(function() Tween(swatchScale, Motion.Pop, { Scale = 1 }) end)
        swatch.MouseButton1Click:Connect(function()
            for index = #stops, 1, -1 do stops[index] = nil end
            for index, color in ipairs(preset.Colors) do
                table.insert(stops, { color = color, position = (index - 1) / math.max(1, #preset.Colors - 1) })
            end
            selected = 1
            playSound("Open")
            render(true)
        end)
    end

    ---------------------------------------------------------------------------------------------------
    -- Editing
    ---------------------------------------------------------------------------------------------------
    local function editSelectedHSV(hue, sat, val)
        stops[selected].color = Color3.fromHSV(hue, sat, val)
        render()
    end
    trackPointer(sb, function(x, y)
        local hue = select(1, stops[selected].color:ToHSV())
        editSelectedHSV(hue, x, 1 - y)
    end)
    trackPointer(hueRail, function(x)
        local _, sat, val = stops[selected].color:ToHSV()
        editSelectedHSV(x, sat, val)
    end)

    addButton.MouseButton1Click:Connect(function()
        if #stops >= PALETTE_MAX_STOPS then return end
        -- Insert into the widest gap, coloured by sampling the ramp right there.
        table.sort(stops, function(a, b) return a.position < b.position end)
        local gapAt, gapSize = 0.5, -1
        for i = 1, #stops - 1 do
            local size = stops[i + 1].position - stops[i].position
            if size > gapSize then gapSize, gapAt = size, (stops[i].position + stops[i + 1].position) / 2 end
        end
        local blended = stops[1].color
        for i = 1, #stops - 1 do
            if gapAt >= stops[i].position and gapAt <= stops[i + 1].position then
                local span = stops[i + 1].position - stops[i].position
                blended = stops[i].color:Lerp(stops[i + 1].color, span > 0 and (gapAt - stops[i].position) / span or 0.5)
                break
            end
        end
        local fresh = { color = blended, position = gapAt }
        table.insert(stops, fresh)
        table.sort(stops, function(a, b) return a.position < b.position end)
        selected = table.find(stops, fresh) or selected
        playSound("Open")
        render(true)
    end)
    removeButton.MouseButton1Click:Connect(function() removeStop(selected) end)
    reverseButton.MouseButton1Click:Connect(function()
        table.sort(stops, function(a, b) return a.position < b.position end)
        local colors = {}
        for i, stop in ipairs(stops) do colors[i] = stop.color end
        for i, stop in ipairs(stops) do
            stop.color = colors[#colors - i + 1]
            stop.position = 1 - stops[#stops - i + 1].position
        end
        table.sort(stops, function(a, b) return a.position < b.position end)
        playSound("Tab")
        render(true)
    end)
    resetButton.MouseButton1Click:Connect(function()
        local fresh = onReset()
        for i = #stops, 1, -1 do stops[i] = nil end
        for _, stop in ipairs(fresh) do table.insert(stops, stop) end
        selected = 1
        playSound("Close")
        render(true)
    end)
    applyButton.MouseButton1Click:Connect(function() W:ClosePopup() end)

    render(true)
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
function Container:AddPalette(idx, info)
    info = info or {}
    local W = self.W
    local Palette = { Type = "Palette", Text = info.Text or "Accent Gradient" }

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
        Size = UDim2.new(1, 0, 0, 18),
    }), { TextColor3 = "TextSecondary" })

    local ramp = New("TextButton", {
        Name = "Ramp",
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 2,
    }, holder)
    Corner(ramp, 10)
    Themed(New("UIGradient", {}, ramp), { Color = accentSequence })
    local rampRim = Themed(New("UIStroke", { Thickness = 1, Transparency = 0.6 }, ramp), { Color = "Rim" })
    Specular(ramp, 24, 0.45, 3)
    local rampScale = New("UIScale", { Scale = 1 }, ramp)

    -- Three dabs at the right end: the only hint that the ramp is a door into the palette.
    for i = 0, 2 do
        local dab = Themed(New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8 - i * 8, 0.5, 0),
            Size = UDim2.fromOffset(5, 5),
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            ZIndex = 3,
        }, ramp), { BackgroundColor3 = "Knob" })
        Corner(dab, 3)
    end

    ramp.MouseEnter:Connect(function()
        Tween(rampScale, Motion.Pop, { Scale = 1.015 })
        Tween(rampRim, Motion.Hover, { Transparency = 0.25 })
        playSound("Hover")
    end)
    ramp.MouseLeave:Connect(function()
        Tween(rampScale, Motion.Pop, { Scale = 1 })
        Tween(rampRim, Motion.Hover, { Transparency = 0.6 })
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
    bindTooltip(W, ramp, function() return info.Tooltip or "Open the gradient palette" end)

    function Palette:SetVisible(visible) holder.Visible = visible end
    if idx then Library.Options[idx] = Palette end
    return Palette
end
