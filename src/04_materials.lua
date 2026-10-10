-------------------------------------------------------------------------------------------------------
-- Materials
--
-- Liquid glass is built from a few layers, each standing for one thing light does at a real pane:
--   body      the tinted glass, denser toward the shaded side
--   rim       a hairline that is brightest where it faces the light (the key), dims across the sides and
--             picks up again on the far edge, where light that crossed the glass leaves it (the bounce),
--             with a faint prismatic fringe off each lobe
--   edge      the lensed edge: crisp at the boundary and falling away inward, so the surface reads thick
--   band      (panes) a softer second rim just inside the first on the far side, lit by light refracted
--             through the glass; it is what makes a pane read as a slab rather than a sticker
--   specular  a glint along the top edge, peaked toward the light
--   glare     (window) a soft reflection that drifts toward the pointer while it is over the glass
--
-- One light lights everything (LIGHT_ANGLE). How strongly each layer shows comes from the theme's
-- material tokens, so the matte themes (Onyx, Midnight) stay matte: no fringe, no band, no glare.
-------------------------------------------------------------------------------------------------------

-- The UIGradient rotation that runs away from the light, so the 0 end of every lighting gradient faces
-- it. The light sits high and a little to the right, where the pane gradient has always put it.
local LIGHT_ANGLE = 110
local LIGHT_SWING = 34 -- the most the window's light leans toward the pointer, in degrees

local QUALITY_RANK = { Low = 1, Balanced = 2, High = 3 }
local function qualityRank()
    return QUALITY_RANK[Library.GlassQuality] or 3
end

-- A Visible binding for a decorative layer that is only drawn at `rank` and above.
local function atQuality(rank)
    return function() return qualityRank() >= rank end
end

-- How strongly the theme's glass bends and splits light, 0..1, read off its edge token: the clear glasses
-- (Glacier, Frost, Neon) sit near 1, the house glasses about half way, the matte ones (Onyx, Midnight) at 0.
local function clarity()
    return math.clamp((0.92 - Glass.EdgeTransparency) / 0.5, 0, 1)
end

-- Rim light along the light axis: the key lobe, a dark terminator across the sides, the bounce lobe.
local RIM_LIGHT = NumberSequence.new({
    NumberSequenceKeypoint.new(0.00, 0),
    NumberSequenceKeypoint.new(0.20, 0.34),
    NumberSequenceKeypoint.new(0.50, 0.86),
    NumberSequenceKeypoint.new(0.80, 0.52),
    NumberSequenceKeypoint.new(1.00, 0.2),
})

-- The lensed edge stays visible all the way round (the glass is thick everywhere) but follows the light.
local EDGE_LIGHT = NumberSequence.new({
    NumberSequenceKeypoint.new(0.00, 0),
    NumberSequenceKeypoint.new(0.50, 0.4),
    NumberSequenceKeypoint.new(1.00, 0.1),
})

-- The refraction band is the rim's mirror image: nothing on the lit side, strongest on the far one.
local BAND_LIGHT = NumberSequence.new({
    NumberSequenceKeypoint.new(0.00, 1),
    NumberSequenceKeypoint.new(0.45, 0.92),
    NumberSequenceKeypoint.new(1.00, 0.25),
})
local BAND_INSET = 2

-- A glint peaked toward the light and fading out at both ends.
local SPECULAR_LINE = NumberSequence.new({
    NumberSequenceKeypoint.new(0.00, 1),
    NumberSequenceKeypoint.new(0.35, 0.5),
    NumberSequenceKeypoint.new(0.62, 0),
    NumberSequenceKeypoint.new(1.00, 1),
})

-- Colour along a rim, multiplied over the rim's own tint. A curved edge splits light a little: a cool
-- fringe trails the key highlight and a warm one the bounce. Barely there, but it is the difference
-- between a lit edge and a white line. Quantised so a theme morph rebuilds it a handful of times, not
-- once per frame per rim.
local PRISM_COOL = Color3.fromRGB(186, 224, 255)
local PRISM_WARM = Color3.fromRGB(255, 206, 228)
local buildPrism = cachedSequence(function(strength)
    local white = Color3.new(1, 1, 1)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, white),
        ColorSequenceKeypoint.new(0.24, white:Lerp(PRISM_COOL, strength)),
        ColorSequenceKeypoint.new(0.50, white),
        ColorSequenceKeypoint.new(0.76, white:Lerp(PRISM_WARM, strength)),
        ColorSequenceKeypoint.new(1.00, white),
    })
end)
local function prismColor()
    if qualityRank() < 2 then return buildPrism(0) end
    return buildPrism(math.floor(clarity() * 0.85 * 20 + 0.5) / 20)
end

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
-- Returns the image and its lighting gradient (which a live light can turn).
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
    }, parent), { ImageColor3 = "Rim", Visible = atQuality(2) })
    themedTransparency(edge, "ImageTransparency", transparency)
    local light = Themed(New("UIGradient", {
        Rotation = LIGHT_ANGLE,
        Transparency = EDGE_LIGHT,
    }, edge), { Color = edgeGradientColor })
    return edge, light
end

-- The refraction band: the same lensed edge drawn again a couple of pixels inside the first, in the edge's
-- light tint, and lit only on the side away from the light. Returns the image and its lighting gradient.
local function RefractionBand(parent, radius, zIndex)
    local band = Themed(New("ImageLabel", {
        Name = "Refraction",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -BAND_INSET * 2, 1, -BAND_INSET * 2),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = Assets.GlassEdge,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(50, 50, 78, 78),
        SliceScale = math.max(radius - BAND_INSET, 1) / L.SliceBaseRadius,
        ZIndex = zIndex,
    }, parent), {
        ImageColor3 = "EdgeMid",
        ImageTransparency = function() return 1 - clarity() * 0.42 end,
        Visible = function() return qualityRank() >= 3 and clarity() > 0.02 end,
    })
    local light = New("UIGradient", { Rotation = LIGHT_ANGLE, Transparency = BAND_LIGHT }, band)
    return band, light
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
    local line = Themed(New("Frame", {
        Name = "Specular",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 1),
        Size = UDim2.new(1, -inset, 0, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = transparency,
        BorderSizePixel = 0,
        ZIndex = zIndex or 1,
    }, parent), { Visible = atQuality(2) })
    New("UIGradient", { Transparency = SPECULAR_LINE }, line)
    return line
end

-- A hairline rim lit by the shared light: the dual-lobe highlight with its prismatic fringe. Returns the
-- lighting gradient so a live light can turn it.
local function RimLight(stroke)
    return Themed(New("UIGradient", { Rotation = LIGHT_ANGLE, Transparency = RIM_LIGHT }, stroke), { Color = prismColor })
end

-- Window-grade glass: theme-tinted body lit from above, rim, top-edge specular, refraction band and lensed
-- edge. The window, bubble, pods, popups and notifications all use it so they read as one material.
-- `withBand = false` leaves the refraction band off surfaces too small to show it (tooltips).
-- `Lights` lists the lighting gradients, which the window hands to its live light.
local function PaneMaterial(frame, radius, edgeZ, withBand)
    frame.BackgroundColor3 = Color3.new(1, 1, 1)
    frame.BorderSizePixel = 0
    Themed(frame, { BackgroundTransparency = "PaneTransparency" })
    local corner = Corner(frame, radius)
    Themed(New("UIGradient", {
        Rotation = LIGHT_ANGLE + 5,
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
    local lights = { RimLight(border) }

    local specular = Specular(frame, radius * 4, 0.35, edgeZ - 1)
    local band
    if withBand ~= false then
        local bandLight
        band, bandLight = RefractionBand(frame, radius, edgeZ - 1)
        table.insert(lights, bandLight)
    end
    local edge, edgeLight = GlassEdge(frame, radius, "EdgeTransparency", edgeZ)
    table.insert(lights, edgeLight)
    return { Corner = corner, Border = border, Specular = specular, Edge = edge, Band = band, Lights = lights }
end

-- Re-fits a pane's radius-dependent layers after its corner radius changes. With `tweenInfo`, it tweens.
local function ReshapePane(pane, radius, tweenInfo)
    local goals = {
        { pane.Corner, { CornerRadius = UDim.new(0, radius) } },
        { pane.Edge, { SliceScale = math.max(radius, 1) / L.SliceBaseRadius } },
        { pane.Specular, { Size = UDim2.new(1, -radius * 4, 0, 1) } },
    }
    if pane.Band then
        table.insert(goals, { pane.Band, { SliceScale = math.max(radius - BAND_INSET, 1) / L.SliceBaseRadius } })
    end
    for _, pair in ipairs(goals) do
        if tweenInfo then
            Tween(pair[1], tweenInfo, pair[2])
        else
            for property, value in pairs(pair[2]) do pair[1][property] = value end
        end
    end
end

-- Popups sit over busy content, so they use the same glass nearly opaque. Small ones (tooltips) skip the
-- refraction band; `withBand = false` also keeps it off a frame that stacks its own children with a layout.
local function PopupMaterial(frame, radius, edgeZ, withBand)
    local pane = PaneMaterial(frame, radius, edgeZ, withBand ~= false and radius >= 10)
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
    RimLight(stroke)
    GlassEdge(frame, radius, function() return math.min(1, Glass.EdgeTransparency + 0.2) end, 2)
    return stroke
end

-- An etched well's rim: in shadow along the top, where the lip overhangs it, and catching a line of light
-- along the bottom lip. One gradient on the stroke draws both, where this used to take a separate lip
-- frame and its own gradient per field.
local WELL_RIM = NumberSequence.new({
    NumberSequenceKeypoint.new(0.00, 0.7),
    NumberSequenceKeypoint.new(0.55, 0.6),
    NumberSequenceKeypoint.new(1.00, 0),
})

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
        Transparency = 0.76,
    }, frame), { Color = "Rim" })
    New("UIGradient", { Rotation = 90, Transparency = WELL_RIM }, stroke)
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
    RimLight(rim)
    local edge = GlassEdge(body, radius, 0.62, zIndex + 1)
    Specular(body, radius * 2, 0.4, zIndex + 2)
    return body, edge
end

-- A soft ring of light that swells out through `parent` and fades: the press response. Light enters the
-- glass where it is touched, so the ring starts at `at` (an absolute pointer position) when given, and
-- grows far enough to reach the far side from there.
local function Pulse(parent, zIndex, at)
    local topLeft, extent = parent.AbsolutePosition, parent.AbsoluteSize
    local size = math.max(extent.X, extent.Y)
    local origin = Vector2.new(0.5, 0.5)
    if at and extent.X > 0 and extent.Y > 0 then
        origin = Vector2.new(
            math.clamp((at.X - topLeft.X) / extent.X, 0, 1),
            math.clamp((at.Y - topLeft.Y) / extent.Y, 0, 1)
        )
    end
    local reach = math.max(1, 2 * math.max(origin.X, 1 - origin.X, origin.Y, 1 - origin.Y))
    local ring = Themed(New("Frame", {
        Name = "Pulse",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(origin.X, origin.Y),
        Size = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
        ZIndex = zIndex or 5,
    }, parent), { BackgroundColor3 = "Accent" })
    Corner(ring, 999)
    Tween(ring, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(size * 1.3 * reach, size * 1.3 * reach),
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
    RimLight(rim)
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

-- How bright the window's glare is: a share of the theme's sheen, so the matte and flat themes (Onyx,
-- Neon, Midnight) have none. `presence` is 0 at rest and 1 while the pointer is over the glass.
local function glareStrength()
    return (1 - Glass.SheenTransparency) * 0.9
end
local function glareTransparency(presence)
    return 1 - glareStrength() * (0.35 + 0.65 * presence)
end
local GLARE_REST = Vector2.new(0.66, 0.04) -- where the reflection of the light sits when nothing moves it
local GLARE_SIZE = 440

-- The window's live light. While the pointer is over `surface` the light leans toward it (the rim's key
-- highlight slides round toward the pointer, the bounce opposite it) and a soft glare drifts after it, all
-- on springs, like tilting a pane of glass under a lamp. `lights` are the lighting gradients to turn;
-- the glare is built inside `glareParent`. It only runs at High quality, and it only wakes when the
-- pointer moves over the glass or leaves it, so a still pointer or a hidden window costs nothing.
local function LiveLight(surface, lights, glareParent)
    local light = {
        angle = LIGHT_ANGLE, angleVelocity = 0, angleTarget = LIGHT_ANGLE,
        glare = GLARE_REST, glareVelocity = Vector2.zero, glareTarget = GLARE_REST,
        presence = 0, presenceVelocity = 0, presenceTarget = 0,
        hovering = false,
    }

    local glare = Themed(New("ImageLabel", {
        Name = "Reflection",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(GLARE_REST.X, GLARE_REST.Y),
        Size = UDim2.fromOffset(GLARE_SIZE, GLARE_SIZE),
        BackgroundTransparency = 1,
        Image = Assets.Spark,
        ZIndex = glareParent.ZIndex,
    }, glareParent), {
        ImageColor3 = "EdgeMid",
        ImageTransparency = function() return glareTransparency(light.presence) end,
        Visible = function() return qualityRank() >= 3 and glareStrength() > 0.005 end,
    })

    function light:Step(dt)
        local k = 70
        self.angleVelocity += (k * (self.angleTarget - self.angle) - 2 * math.sqrt(k) * 0.9 * self.angleVelocity) * dt
        self.angle += self.angleVelocity * dt

        local kg = 110
        self.glareVelocity += ((self.glareTarget - self.glare) * kg - self.glareVelocity * (2 * math.sqrt(kg) * 0.85)) * dt
        self.glare += self.glareVelocity * dt

        local kp = 90
        self.presenceVelocity += (kp * (self.presenceTarget - self.presence) - 2 * math.sqrt(kp) * self.presenceVelocity) * dt
        self.presence += self.presenceVelocity * dt

        if math.abs(self.angleTarget - self.angle) < 0.05 and math.abs(self.angleVelocity) < 0.5
            and (self.glareTarget - self.glare).Magnitude < 0.0005 and self.glareVelocity.Magnitude < 0.005
            and math.abs(self.presenceTarget - self.presence) < 0.002 and math.abs(self.presenceVelocity) < 0.02 then
            self.angle, self.angleVelocity = self.angleTarget, 0
            self.glare, self.glareVelocity = self.glareTarget, Vector2.zero
            self.presence, self.presenceVelocity = self.presenceTarget, 0
            return false
        end
        return true
    end

    function light:Render()
        for _, gradient in ipairs(lights) do
            gradient.Rotation = self.angle
        end
        glare.Position = UDim2.fromScale(self.glare.X, self.glare.Y)
        glare.ImageTransparency = glareTransparency(self.presence)
    end

    -- `position` is the pointer in absolute pixels, or nil to let the light settle back to rest.
    function light:Point(position)
        local hovering, at = false, nil
        if position and qualityRank() >= 3 then
            local topLeft, size = surface.AbsolutePosition, surface.AbsoluteSize
            if size.X > 0 and size.Y > 0 then
                at = Vector2.new((position.X - topLeft.X) / size.X, (position.Y - topLeft.Y) / size.Y)
                hovering = at.X >= 0 and at.X <= 1 and at.Y >= 0 and at.Y <= 1
            end
        end
        if not hovering and not self.hovering then return end
        self.hovering = hovering
        if hovering then
            -- The light comes from the pointer's side, so the gradients run from it through the centre.
            -- It leans at most LIGHT_SWING from rest, and less the nearer the pointer is to the centre,
            -- where its direction means nothing.
            local size = surface.AbsoluteSize
            local dx, dy = (0.5 - at.X) * size.X, (0.5 - at.Y) * size.Y
            local pull = math.clamp(math.sqrt(dx * dx + dy * dy) / (math.min(size.X, size.Y) / 2), 0, 1)
            local delta = (math.deg(math.atan2(dy, dx)) - LIGHT_ANGLE + 180) % 360 - 180
            self.angleTarget = LIGHT_ANGLE + math.clamp(delta, -LIGHT_SWING, LIGHT_SWING) * pull
            self.glareTarget = at
            self.presenceTarget = 1
        else
            self.angleTarget, self.glareTarget, self.presenceTarget = LIGHT_ANGLE, GLARE_REST, 0
        end
        Animator.Wake(self)
    end

    return light
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
            return false
        end
        return true
    end

    function mover:Render()
        render()
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
