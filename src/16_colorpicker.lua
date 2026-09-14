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
