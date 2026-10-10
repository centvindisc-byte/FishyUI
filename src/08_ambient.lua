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
