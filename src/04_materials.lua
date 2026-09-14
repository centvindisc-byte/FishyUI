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

    function mover:Step(dt)
        local target = currentTarget()
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
            render()
            return false
        end
        render()
        return true
    end

    function mover:SetTarget(value)
        if typeof(value) == "function" then
            self.targetFn = value
        else
            self.targetFn, self.target = nil, value
        end
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
