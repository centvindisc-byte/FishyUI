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
    -- Half the height, not a fixed radius: the bead swells and stretches and must stay a round drop.
    New("UICorner", { CornerRadius = UDim.new(0.5, 0) }, bead)
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

    local hovered, dragging = false, false
    local level, levelVelocity = 0, 0
    local function draw()
        local stretch = math.min(7, math.abs(levelVelocity) * 3)
        -- Held, the bead swells into a clear lens over the tube (see setDragging).
        local size = SLIDER_BEAD + (dragging and 8 or (hovered and 2 or 0))
        fill.Size = UDim2.fromScale(level, 1)
        fillGradient.Size = UDim2.new(0, math.max(1, tube.AbsoluteSize.X / W.Scale.Scale), 1, 0)
        surfaceGlow.Position = UDim2.fromScale(level, 0.5)
        bead.Position = UDim2.fromScale(level, 0.5)
        bead.Size = UDim2.fromOffset(size + stretch, size - math.min(3, stretch * 0.35))
        bubble.Position = UDim2.new(level, 0, 0, -12)
        for _, tick in ipairs(ticks) do
            local lit = tick.Pct <= level + 0.001
            tick.Frame.BackgroundColor3 = lit and Glass.Knob or Glass.Rim
            tick.Frame.BackgroundTransparency = lit and 0.25 or 0.55
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
        -- While held, the bead turns to clear glass, so the level shows through it under its accent rim,
        -- and settles back to a solid bead when released.
        Tween(bead, Motion.Hover, { BackgroundTransparency = active and 0.74 or 0 })
        Tween(beadCore, Motion.Hover, { BackgroundTransparency = active and 1 or 0 })
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
