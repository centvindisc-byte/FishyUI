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
