-------------------------------------------------------------------------------------------------------
-- Attachment kinds
--
-- What each pod shows. Every kind reads only what any game exposes to its own client (the library's
-- telemetry, the player list, your character, the lighting clock, network stats) or the library's own
-- state, so they work everywhere. None of them reads game-specific data such as leaderstats, which
-- differs from game to game. The engine and the shared helpers are in 23_satellites.lua.
-------------------------------------------------------------------------------------------------------
do
    local K = PodKinds
    local Value, Label = K.Value, K.Label
    local HEADINGS = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }

    local function rootOf(player)
        local character = player and player.Character
        return character and character:FindFirstChild("HumanoidRootPart")
    end

    -- A hairline between the card and the part only the expanded form shows.
    local function detailRule(layer)
        Themed(New("Frame", {
            Position = UDim2.fromOffset(12, POD_H + 2),
            Size = UDim2.fromOffset(POD_W - 24, 1),
            BackgroundTransparency = 0.82,
            BorderSizePixel = 0,
            ZIndex = 3,
        }, layer), { BackgroundColor3 = "Rim" })
    end

    -- A caption on the left and its value on the right, for the expanded form.
    local function detailRow(layer, y, caption)
        Label(layer, { Text = caption, Position = UDim2.fromOffset(12, y), Size = UDim2.fromOffset(64, 16) })
        return Label(layer, {
            TextXAlignment = Enum.TextXAlignment.Right,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.fromOffset(POD_W - 12, y),
            Size = UDim2.fromOffset(POD_W - 24 - 64, 16),
        }, "TextPrimary")
    end

    local function throttle(state, dt, rate)
        state.accrued = (state.accrued or 0) + dt
        if state.accrued < 1 / rate then return false end
        state.accrued = 0
        return true
    end

    -- 4:12, or 1:04:12 past an hour; `tenths` adds 4:12.3 for a running stopwatch.
    local function clockText(seconds, tenths)
        seconds = math.max(0, seconds)
        local whole = math.floor(seconds)
        local hours, minutes, secs = math.floor(whole / 3600), math.floor(whole % 3600 / 60), whole % 60
        if hours > 0 then return string.format("%d:%02d:%02d", hours, minutes, secs) end
        if tenths then return string.format("%d:%02d.%d", minutes, secs, math.floor(seconds * 10) % 10) end
        return string.format("%d:%02d", minutes, secs)
    end

    -------------------------------------------------------------------------------------------------------
    -- Session: how long you've been here and how long the server has been up.
    -------------------------------------------------------------------------------------------------------
    K.Define("Session", {
        Title = "SESSION", Side = "Right", Moon = "TIME", Expands = true,
        Build = function(pod, layer)
            local inst = {}
            inst.time = Value(layer, {
                Text = "00:00:00", FontFace = K.MonoBold, TextTruncate = Enum.TextTruncate.AtEnd,
                Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -56, 0, 26),
            })
            inst.serverUp = Label(layer, { Position = UDim2.fromOffset(12, 56), Size = UDim2.new(1, -24, 0, 14) })
            local ring = New("Frame", {
                AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromOffset(POD_W - 12, 30),
                Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, ZIndex = 3,
            }, layer)
            Corner(ring, 12)
            Themed(New("UIStroke", { Thickness = 1.5, Transparency = 0.7 }, ring), { Color = "Rim" })
            inst.orbit = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 3,
            }, ring)
            local bead = Themed(New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0),
                Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, ZIndex = 4,
            }, inst.orbit), { BackgroundColor3 = "Accent" })
            Corner(bead, 3)
            detailRule(layer)
            inst.joined = detailRow(layer, 110, "Joined")
            inst.clock = detailRow(layer, 130, "Local time")
            inst.date = detailRow(layer, 150, "Date")
            inst.joined.Text = os.date("%H:%M", os.time() - math.floor(os.clock() - Telemetry.SessionStart))
            return inst
        end,
        Refresh = function(pod, inst)
            local session = os.clock() - Telemetry.SessionStart
            inst.time.Text = Telemetry.Clock(session)
            inst.serverUp.Text = "Server up " .. Telemetry.Duration(Workspace.DistributedGameTime)
            Tween(inst.orbit, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Rotation = math.floor(session) * 6 })
            if pod.layer == "expanded" then
                inst.clock.Text = os.date("%H:%M:%S")
                pod.put(inst.date, "Text", os.date("%a %d %b"))
            end
        end,
        Summary = function()
            local session = os.clock() - Telemetry.SessionStart
            local whole = math.floor(session)
            local hours, minutes = math.floor(whole / 3600), math.floor(whole % 3600 / 60)
            local short = if hours > 0 then string.format("%d:%02d", hours, minutes) else string.format("%d:%02d", minutes, whole % 60)
            return Telemetry.Clock(session), "", short
        end,
    })

    -------------------------------------------------------------------------------------------------------
    -- Performance: frame rate, ping and a ping history. Reactive: a frame-rate drop turns it amber and
    -- sends ripples out from the number.
    -------------------------------------------------------------------------------------------------------
    K.Define("Performance", {
        Title = "PERFORMANCE", Side = "Right", Moon = "FPS", Expands = true,
        Build = function(pod, layer)
            local inst = {}
            inst.fps = Value(layer, {
                Text = "0", TextSize = 22, Position = UDim2.fromOffset(12, 26), Size = UDim2.fromOffset(60, 28),
            }, function() return pod.Alert and Glass.Warning or Glass.TextPrimary end)
            inst.unit = Label(layer, { Text = "fps", Position = UDim2.fromOffset(40, 34), Size = UDim2.fromOffset(30, 16) })
            inst.roll = K.Roller(inst.fps, tostring, function(text)
                inst.unit.Position = UDim2.fromOffset(12 + textWidth(text, 22, Enum.Font.GothamBold) + 5, 34)
            end)
            inst.ping = Label(layer, {
                Text = "-- ms", TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.fromOffset(POD_W - 12, 32), Size = UDim2.fromOffset(64, 16),
            }, POD_SUB)
            inst.pingDot = New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(POD_W - 80, 40),
                Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Glass.Glyph, BorderSizePixel = 0, ZIndex = 3,
            }, layer)
            Corner(inst.pingDot, 3)
            inst.graph = K.Bars(layer, 12, 62, POD_W - 24, GRAPH_HEIGHT, GRAPH_BARS, GRAPH_GAP)
            detailRule(layer)
            Label(layer, { Text = "FRAME RATE", TextSize = 10, Position = UDim2.fromOffset(12, 108), Size = UDim2.fromOffset(100, 14) })
            inst.fpsGraph = K.Bars(layer, 12, 124, POD_W - 24, 30, GRAPH_BARS, GRAPH_GAP)
            inst.stats = Label(layer, { Position = UDim2.fromOffset(12, 158), Size = UDim2.fromOffset(POD_W - 24, 14) })
            return inst
        end,
        Refresh = function(pod, inst)
            local fps = Telemetry.Fps
            inst.roll:Set(fps)
            local ping = Telemetry.Ping
            local pingText = if ping then string.format("%d ms", math.floor(ping + 0.5)) else "-- ms"
            if pingText ~= inst.lastPing then
                inst.lastPing = pingText
                inst.ping.Text = pingText
                inst.pingDot.Position = UDim2.fromOffset(POD_W - 12 - textWidth(pingText, 12, Enum.Font.GothamMedium) - 6, 40)
            end
            local color = if ping then Telemetry.StrengthColor(Telemetry.Strength(ping)) else Glass.Glyph
            if inst.pingGoal ~= color then
                inst.pingGoal = color
                Tween(inst.pingDot, Motion.Hover, { BackgroundColor3 = color })
            end
            local samples = Telemetry.PingSamples
            local ceiling = 150
            for _, value in ipairs(samples) do ceiling = math.max(ceiling, value * 1.15) end
            inst.graph:Set(samples, ceiling, function(value) return Telemetry.StrengthColor(Telemetry.Strength(value)) end)

            local history = Telemetry.FpsSamples
            if pod.layer == "expanded" and #history > 0 then
                local top, low, high, sum = 60, math.huge, 0, 0
                for _, value in ipairs(history) do
                    top = math.max(top, value * 1.1)
                    low, high, sum = math.min(low, value), math.max(high, value), sum + value
                end
                inst.fpsGraph:Set(history, top, function(value) return if value < 40 then Glass.Warning else Glass.Accent end)
                pod.put(inst.stats, "Text", string.format("Low %d  ·  Avg %d  ·  High %d", low, math.floor(sum / #history + 0.5), high))
            end

            local alert = fps > 0 and fps < 40
            if alert ~= inst.alert then
                inst.alert = alert
                inst.fps.TextColor3 = if alert then Glass.Warning else Glass.TextPrimary
                pod:SetAlert(alert)
            end
            if alert then pod:Ripple(30, 40, Glass.Warning) end
        end,
        Summary = function()
            return tostring(Telemetry.Fps), "fps", tostring(Telemetry.Fps)
        end,
    })

    -------------------------------------------------------------------------------------------------------
    -- Server: players and capacity. Reactive: someone joining pulses the glass.
    -------------------------------------------------------------------------------------------------------
    K.Define("Server", {
        Title = "SERVER", Side = "Right", Moon = "PLRS", Expands = true,
        Build = function(pod, layer)
            local inst = {}
            inst.players = Value(layer, { Text = "0", Position = UDim2.fromOffset(12, 26), Size = UDim2.fromOffset(80, 26) })
            inst.unit = Label(layer, { Text = "players", Position = UDim2.fromOffset(60, 33), Size = UDim2.fromOffset(60, 16) })
            inst.roll = K.Roller(inst.players, function(count)
                local max = Players.MaxPlayers
                return if max > 0 then string.format("%d/%d", count, max) else tostring(count)
            end, function(text)
                inst.unit.Position = UDim2.fromOffset(12 + textWidth(text, 20, Enum.Font.GothamBold) + 5, 33)
            end)
            local capacity = New("Frame", {
                Position = UDim2.fromOffset(12, 56), Size = UDim2.fromOffset(POD_W - 24, 6), ZIndex = 3,
            }, layer)
            FieldMaterial(capacity, 3)
            inst.fill = Themed(New("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, ZIndex = 4 }, capacity), { BackgroundColor3 = "Accent" })
            Corner(inst.fill, 3)
            inst.meta = Label(layer, { Position = UDim2.fromOffset(12, 68), Size = UDim2.new(1, -24, 0, 14) })
            detailRule(layer)
            Label(layer, { Text = "RECENT", TextSize = 10, Position = UDim2.fromOffset(12, 108), Size = UDim2.fromOffset(100, 14) })
            inst.events = {}
            for i = 1, 3 do
                inst.events[i] = Label(layer, { Position = UDim2.fromOffset(12, 108 + i * 18), Size = UDim2.fromOffset(POD_W - 24, 16) }, "TextPrimary")
            end

            local state = pod.state
            state.events = state.events or {}
            local function record(player, verb)
                table.insert(state.events, 1, { time = os.date("%H:%M"), text = tostring(player.DisplayName) .. " " .. verb })
                while #state.events > 3 do table.remove(state.events) end
                if pod.alpha > 0.01 then
                    if verb == "joined" then pod:Flash(Glass.Accent) end
                    pod:Refresh()
                end
            end
            Library:GiveSignal(Players.PlayerAdded:Connect(function(player) record(player, "joined") end))
            Library:GiveSignal(Players.PlayerRemoving:Connect(function(player) record(player, "left") end))
            return inst
        end,
        Refresh = function(pod, inst)
            local count, max = #Players:GetPlayers(), Players.MaxPlayers
            inst.roll:Set(count)
            local fill = UDim2.fromScale(if max > 0 then math.clamp(count / max, 0, 1) else 0, 1)
            if inst.fillGoal ~= fill then
                inst.fillGoal = fill
                Tween(inst.fill, Motion.Settle, { Size = fill })
            end
            pod.put(inst.meta, "Text", Telemetry.Region .. "  ·  " .. Telemetry.Executor)
            for i, label in ipairs(inst.events) do
                local event = pod.state.events[i]
                local text = if event then event.time .. "   " .. event.text elseif i == 1 then "Nobody has come or gone yet" else ""
                pod.put(label, "Text", text)
            end
        end,
        Summary = function()
            local count, max = #Players:GetPlayers(), Players.MaxPlayers
            return (if max > 0 then string.format("%d/%d", count, max) else tostring(count)), "players", tostring(count)
        end,
    })

    -------------------------------------------------------------------------------------------------------
    -- Location: coordinates and a compass. Expanded adds the distance travelled and a copy button.
    -------------------------------------------------------------------------------------------------------
    K.Define("Location", {
        Title = "LOCATION", Side = "Left", Moon = "HDG", Expands = true,
        Build = function(pod, layer)
            local inst = { coords = {} }
            for i, axis in ipairs({ "X", "Y", "Z" }) do
                Label(layer, {
                    Text = axis, FontFace = K.MonoBold, TextSize = 10,
                    Position = UDim2.fromOffset(12, 26 + (i - 1) * 18), Size = UDim2.fromOffset(12, 14),
                })
                inst.coords[i] = Value(layer, {
                    Text = "0", FontFace = FONT_MONO, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd,
                    Position = UDim2.fromOffset(26, 26 + (i - 1) * 18), Size = UDim2.fromOffset(78, 14),
                })
            end
            local compass = New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(POD_W - 14, 54),
                Size = UDim2.fromOffset(48, 48), BackgroundTransparency = 1, ZIndex = 3,
            }, layer)
            Corner(compass, 24)
            Themed(New("UIStroke", { Thickness = 1.5, Transparency = 0.65 }, compass), { Color = "Rim" })
            Label(compass, {
                Text = "N", FontFace = FONT_BOLD, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Center,
                Position = UDim2.fromOffset(0, 1), Size = UDim2.new(1, 0, 0, 10), ZIndex = 4,
            })
            inst.needle = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 4,
            }, compass)
            local north = Themed(New("Frame", {
                AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(3, 17), BorderSizePixel = 0, ZIndex = 5,
            }, inst.needle), { BackgroundColor3 = "Accent" })
            Corner(north, 2)
            local south = Themed(New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(3, 15), BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 5,
            }, inst.needle), { BackgroundColor3 = "Glyph" })
            Corner(south, 2)

            detailRule(layer)
            inst.travelled = detailRow(layer, 110, "Travelled")
            local copy = K.Chip(pod, layer, 12, 136, POD_W - 24, 26, "Copy position", true)
            copy.Hit.MouseButton1Click:Connect(function()
                copy:Flash()
                playSound("Press")
                local root = rootOf(Players.LocalPlayer)
                if not root then return end
                local p = root.Position
                local text = string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z)
                if typeof(setclipboard) == "function" and pcall(setclipboard, text) then
                    Library:Notify({ Title = "Copied", Description = text, Time = 2 })
                else
                    Library:Notify({ Title = "Position", Description = text, Time = 4 })
                end
            end)
            return inst
        end,
        Live = function(pod, inst, dt)
            local state = pod.state
            if not throttle(state, dt, 15) then return end
            local put = pod.put
            local root = rootOf(Players.LocalPlayer)
            if root then
                local p = root.Position
                put(inst.coords[1], "Text", string.format("%.1f", p.X))
                put(inst.coords[2], "Text", string.format("%.1f", p.Y))
                put(inst.coords[3], "Text", string.format("%.1f", p.Z))
                if state.last then
                    local step = (p - state.last).Magnitude
                    if step < 120 then state.travelled = (state.travelled or 0) + step end -- a teleport isn't travel
                end
                state.last = p
                put(inst.travelled, "Text", K.Number(math.floor(state.travelled or 0)) .. " studs")
            end
            local camera = Workspace.CurrentCamera
            if camera then
                local look = camera.CFrame.LookVector
                put(inst.needle, "Rotation", math.deg(math.atan2(look.X, look.Z)))
            end
        end,
        Summary = function()
            local root = rootOf(Players.LocalPlayer)
            local value = "--"
            if root then
                local p = root.Position
                value = string.format("%d, %d, %d", math.floor(p.X + 0.5), math.floor(p.Y + 0.5), math.floor(p.Z + 0.5))
            end
            local short = "--"
            local camera = Workspace.CurrentCamera
            if camera then
                local look = camera.CFrame.LookVector
                local heading = (math.deg(math.atan2(look.X, -look.Z)) + 360) % 360
                short = HEADINGS[math.floor(heading / 45 + 0.5) % 8 + 1]
            end
            return value, "", short
        end,
    })

    -------------------------------------------------------------------------------------------------------
    -- Radar: players around you, turned with you. Expanded lists the closest three.
    -------------------------------------------------------------------------------------------------------
    local RADAR_RANGE = 220
    local function nearbyPlayers(range)
        local origin = rootOf(Players.LocalPlayer)
        local list = {}
        if not origin then return list, nil end
        for _, player in ipairs(Players:GetPlayers()) do
            local other = player ~= Players.LocalPlayer and rootOf(player)
            if other then
                local offset = other.Position - origin.Position
                local distance = offset.Magnitude
                if distance <= range then table.insert(list, { player = player, root = other, offset = offset, distance = distance }) end
            end
        end
        table.sort(list, function(a, b) return a.distance < b.distance end)
        return list, origin
    end

    K.Define("Radar", {
        Title = "RADAR", Side = "Left", Moon = "NEAR", Expands = true,
        Build = function(pod, layer)
            local inst = { blips = {} }
            local dish = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(POD_W - 54, POD_H / 2 + 6),
                Size = UDim2.fromOffset(72, 72), BackgroundTransparency = 1, ZIndex = 3,
            }, layer)
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
            inst.sweep = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5,
            }, dish)
            Themed(New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1,
                Image = Assets.Spark, ImageTransparency = 0.4, ZIndex = 5,
            }, inst.sweep), { ImageColor3 = "Accent" })
            inst.blipHolder = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 6 }, dish)
            local selfBlip = Themed(New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(5, 5), BorderSizePixel = 0, ZIndex = 7,
            }, dish), { BackgroundColor3 = "Knob" })
            Corner(selfBlip, 3)
            inst.count = Value(layer, {
                Text = "0", TextSize = 22, TextTruncate = Enum.TextTruncate.AtEnd,
                Position = UDim2.fromOffset(12, 26), Size = UDim2.fromOffset(40, 26),
            })
            Label(layer, { Text = "nearby", Position = UDim2.fromOffset(12, 52), Size = UDim2.fromOffset(70, 14) })
            Label(layer, {
                Text = string.format("%dm range", RADAR_RANGE), TextSize = 10,
                Position = UDim2.fromOffset(12, 70), Size = UDim2.fromOffset(90, 14),
            })
            detailRule(layer)
            Label(layer, { Text = "CLOSEST", TextSize = 10, Position = UDim2.fromOffset(12, 108), Size = UDim2.fromOffset(100, 14) })
            inst.closest = {}
            for i = 1, 3 do inst.closest[i] = detailRow(layer, 108 + i * 18, "") end
            return inst
        end,
        Live = function(pod, inst, dt)
            local state = pod.state
            state.sweep = ((state.sweep or 0) + dt * 150) % 360
            inst.sweep.Rotation = state.sweep
            if not throttle(state, dt, 15) then return end
            local put = pod.put
            local list, origin = nearbyPlayers(RADAR_RANGE)
            if not origin then return end
            local look = origin.CFrame.LookVector
            local facing = math.atan2(look.X, look.Z)
            local cos, sin = math.cos(facing), math.sin(facing)
            local radius = 31
            for i, item in ipairs(list) do
                local blip = inst.blips[i]
                if not blip then
                    blip = New("Frame", {
                        AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(5, 5),
                        BackgroundColor3 = Glass.Danger, BorderSizePixel = 0, Visible = false, ZIndex = 7,
                    }, inst.blipHolder)
                    Corner(blip, 3)
                    inst.blips[i] = blip
                end
                local offset = item.offset
                local rx = (offset.X * cos - offset.Z * sin) / RADAR_RANGE * radius
                local ry = (offset.X * sin + offset.Z * cos) / RADAR_RANGE * radius
                put(blip, "Position", UDim2.new(0.5, rx, 0.5, ry))
                put(blip, "BackgroundColor3", if item.distance < RADAR_RANGE * 0.5 then Glass.Danger else Glass.Warning)
                put(blip, "Visible", true)
            end
            for i = #list + 1, #inst.blips do put(inst.blips[i], "Visible", false) end
            put(inst.count, "Text", tostring(#list))
            if pod.layer == "expanded" then
                for i, row in ipairs(inst.closest) do
                    local item = list[i]
                    put(row, "Text", if item then string.format("%s  %dm", item.player.DisplayName, math.floor(item.distance + 0.5)) elseif i == 1 then "Nobody in range" else "")
                end
            end
        end,
        Summary = function()
            local count = #(nearbyPlayers(RADAR_RANGE))
            return tostring(count), "nearby", tostring(count)
        end,
    })

    -------------------------------------------------------------------------------------------------------
    -- Speedometer: your speed on an arc gauge, height above the ground, grounded or in the air.
    -------------------------------------------------------------------------------------------------------
    local function speedOf()
        local root = rootOf(Players.LocalPlayer)
        if not root then return nil end
        local ok, velocity = pcall(function() return root.AssemblyLinearVelocity end)
        if not ok or typeof(velocity) ~= "Vector3" then return 0 end
        return velocity.Magnitude
    end

    K.Define("Speedometer", {
        Title = "SPEED", Side = "Left", Moon = "SPD", Expands = true,
        Build = function(pod, layer)
            local inst = {}
            local cx, cy, radius = 50, 68, 32
            inst.arc = K.DotArc(layer, cx, cy, radius, 13, 180, 360, 5)
            inst.pivot = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy),
                Size = UDim2.fromOffset(radius * 2, radius * 2), BackgroundTransparency = 1, Rotation = -90, ZIndex = 5,
            }, layer)
            local needle = Themed(New("Frame", {
                AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(2, radius - 6), BorderSizePixel = 0, ZIndex = 5,
            }, inst.pivot), { BackgroundColor3 = "Knob" })
            Corner(needle, 1)
            K.Dot(layer, 7, UDim2.fromOffset(cx, cy), "Knob", 6)
            inst.value = Value(layer, { Text = "0.0", TextSize = 20, Position = UDim2.fromOffset(96, 32), Size = UDim2.fromOffset(70, 24) })
            Label(layer, { Text = "studs / s", Position = UDim2.fromOffset(96, 55), Size = UDim2.fromOffset(70, 14) })
            inst.height = Label(layer, { Text = "Height --", Position = UDim2.fromOffset(12, 80), Size = UDim2.fromOffset(80, 14) })
            inst.state = Label(layer, {
                Text = "", TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.fromOffset(POD_W - 12, 80), Size = UDim2.fromOffset(80, 14),
            }, "TextPrimary")
            detailRule(layer)
            inst.top = detailRow(layer, 110, "Top speed")
            inst.walk = detailRow(layer, 130, "Walk speed")
            inst.jump = detailRow(layer, 150, "Jump")
            return inst
        end,
        Live = function(pod, inst, dt)
            local state = pod.state
            if not throttle(state, dt, 10) then return end
            local put = pod.put
            local player = Players.LocalPlayer
            local character = player and player.Character
            local root = rootOf(player)
            if not root then return end
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local speed = speedOf() or 0
            state.speed = speed
            state.top = math.max(state.top or 0, speed)
            local walk = humanoid and humanoid.WalkSpeed or 16
            local ceiling = math.max(32, walk * 2)
            local fraction = math.clamp(speed / ceiling, 0, 1)
            inst.arc:Set(fraction, if speed > walk * 1.5 then Glass.Warning else Glass.Accent)
            put(inst.pivot, "Rotation", -90 + 180 * fraction)
            put(inst.value, "Text", string.format("%.1f", speed))
            local airborne = humanoid ~= nil and humanoid.FloorMaterial == Enum.Material.Air
            put(inst.state, "Text", if airborne then "In the air" else "Grounded")
            -- Height above whatever is below you, ignoring your own character.
            local ok, hit = pcall(function()
                state.params = state.params or RaycastParams.new()
                state.params.FilterType = Enum.RaycastFilterType.Exclude
                state.params.FilterDescendantsInstances = { character }
                return Workspace:Raycast(root.Position, Vector3.new(0, -500, 0), state.params)
            end)
            if ok and hit then
                local hip = (humanoid and humanoid.HipHeight or 2) + root.Size.Y / 2
                put(inst.height, "Text", string.format("Height %d", math.max(0, math.floor(root.Position.Y - hit.Position.Y - hip + 0.5))))
            elseif ok then
                put(inst.height, "Text", "Height --")
            end
            if pod.layer == "expanded" then
                put(inst.top, "Text", string.format("%.1f", state.top))
                put(inst.walk, "Text", string.format("%d", walk))
                local jump = humanoid and (if humanoid.UseJumpPower then humanoid.JumpPower else humanoid.JumpHeight) or 0
                put(inst.jump, "Text", string.format("%d", math.floor(jump + 0.5)))
            end
        end,
        Summary = function()
            local speed = speedOf()
            if not speed then return "--", "studs/s", "--" end
            return string.format("%.1f", speed), "studs/s", tostring(math.floor(speed + 0.5))
        end,
    })

    -------------------------------------------------------------------------------------------------------
    -- Nearby players: the closest players, sorted as they move, each with a health bar.
    -------------------------------------------------------------------------------------------------------
    local NEARBY_RANGE = 300
    K.Define("Nearby", {
        Title = "NEARBY", Side = "Left", Moon = "NEAR", Expands = true, Tag = true,
        Build = function(pod, layer)
            local inst = { rows = {}, layer = layer }
            pod.Tag.Text = string.format("within %d", NEARBY_RANGE)
            inst.empty = Label(layer, { Text = "No one nearby", Position = UDim2.fromOffset(12, 30), Size = UDim2.fromOffset(POD_W - 24, 16) })
            Library:GiveSignal(Players.PlayerRemoving:Connect(function(player)
                local row = inst.rows[player]
                if row then
                    row.Frame:Destroy()
                    inst.rows[player] = nil
                end
            end))
            return inst
        end,
        Live = function(pod, inst, dt)
            local state = pod.state
            if not throttle(state, dt, 4) then return end
            local put = pod.put
            local list = nearbyPlayers(NEARBY_RANGE)
            local seen = {}
            for rank, item in ipairs(list) do
                if rank > 8 then break end
                local player = item.player
                local row = inst.rows[player]
                if not row then
                    local frame = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(POD_W, 18), ZIndex = 3 }, inst.layer)
                    local ok, teamColor = pcall(function() return player.Team and player.TeamColor.Color end)
                    K.Dot(frame, 6, UDim2.fromOffset(15, 9), nil, 4).BackgroundColor3 = if ok and teamColor then teamColor else Glass.Accent
                    local name = Label(frame, { Text = player.DisplayName, Position = UDim2.fromOffset(24, 1), Size = UDim2.fromOffset(78, 16) }, "TextPrimary")
                    local distance = Label(frame, {
                        TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.fromOffset(POD_W - 50, 1), Size = UDim2.fromOffset(40, 16),
                    })
                    local bar = New("Frame", {
                        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(POD_W - 12, 9),
                        Size = UDim2.fromOffset(32, 4), ZIndex = 4,
                    }, frame)
                    FieldMaterial(bar, 2)
                    local fill = New("Frame", { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundColor3 = Glass.Success, ZIndex = 5 }, bar)
                    Corner(fill, 2)
                    row = { Frame = frame, Name = name, Distance = distance, Fill = fill }
                    inst.rows[player] = row
                end
                seen[player] = true
                local y = 26 + (rank - 1) * 18
                if row.rank ~= rank then
                    if row.rank and not Library.LowGraphics then
                        Tween(row.Frame, Motion.Hover, { Position = UDim2.fromOffset(0, y) })
                    else
                        row.Frame.Position = UDim2.fromOffset(0, y)
                    end
                    row.rank = rank
                end
                put(row.Frame, "Visible", true)
                put(row.Distance, "Text", string.format("%dm", math.floor(item.distance + 0.5)))
                local humanoid = item.root.Parent and item.root.Parent:FindFirstChildOfClass("Humanoid")
                local health = if humanoid and humanoid.MaxHealth > 0 then math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1) else 0
                put(row.Fill, "Size", UDim2.fromScale(health, 1))
                put(row.Fill, "BackgroundColor3", if health > 0.5 then Glass.Success elseif health > 0.25 then Glass.Warning else Glass.Danger)
            end
            for player, row in pairs(inst.rows) do
                if not seen[player] then
                    put(row.Frame, "Visible", false)
                    row.rank = nil
                end
            end
            put(inst.empty, "Visible", #list == 0)
        end,
        Summary = function()
            local list = nearbyPlayers(NEARBY_RANGE)
            local closest = list[1]
            if not closest then return "--", "nobody near", "--" end
            return string.format("%dm", math.floor(closest.distance + 0.5)), closest.player.DisplayName, tostring(math.floor(closest.distance + 0.5))
        end,
    })

    -------------------------------------------------------------------------------------------------------
    -- Day cycle: the game's time of day as a sun or moon crossing the sky, next to your own clock.
    -------------------------------------------------------------------------------------------------------
    local function gameClock()
        local ok, value = pcall(function() return Lighting.ClockTime end)
        return if ok and typeof(value) == "number" then value % 24 else 12
    end
    local function phaseOf(clock)
        if clock >= 5 and clock < 7 then return "Dawn" end
        if clock >= 7 and clock < 17 then return "Day" end
        if clock >= 17 and clock < 19 then return "Dusk" end
        return "Night"
    end
    local function hhmm(clock)
        return string.format("%02d:%02d", math.floor(clock), math.floor(clock % 1 * 60))
    end
    -- The sky is a quadratic curve from one end of the horizon to the other.
    local SKY_X0, SKY_X1, SKY_TOP, SKY_FLOOR = 18, 158, 2, 62
    local function skyPoint(s)
        local u = 1 - s
        return u * u * SKY_X0 + 2 * u * s * (SKY_X0 + SKY_X1) / 2 + s * s * SKY_X1, u * u * SKY_FLOOR + 2 * u * s * SKY_TOP + s * s * SKY_FLOOR
    end

    K.Define("DayCycle", {
        Title = "DAY CYCLE", Side = "Right", Moon = "GAME", Expands = true, Tag = true,
        Build = function(pod, layer)
            local inst = {}
            for i = 0, 12 do
                local x, y = skyPoint(i / 12)
                K.Dot(layer, 2, UDim2.fromOffset(x, y), "Rim", 3).BackgroundTransparency = 0.6
            end
            Themed(New("Frame", {
                Position = UDim2.fromOffset(12, SKY_FLOOR), Size = UDim2.fromOffset(POD_W - 24, 1),
                BackgroundTransparency = 0.72, BorderSizePixel = 0, ZIndex = 3,
            }, layer), { BackgroundColor3 = "Rim" })
            inst.glow = New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(34, 34), BackgroundTransparency = 1,
                Image = Assets.Spark, ImageTransparency = 0.45, ImageColor3 = Glass.Warning, ZIndex = 4,
            }, layer)
            inst.sun = K.Dot(layer, 11, UDim2.fromOffset(88, 32), nil, 5)
            inst.game = Label(layer, { Text = "Game --:--", Position = UDim2.fromOffset(12, 76), Size = UDim2.fromOffset(80, 16) })
            inst.real = Label(layer, {
                Text = "", TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.fromOffset(POD_W - 12, 76), Size = UDim2.fromOffset(80, 16),
            })
            detailRule(layer)
            inst.next = detailRow(layer, 110, "Next")
            inst.rate = detailRow(layer, 130, "Game hour")
            inst.today = detailRow(layer, 150, "Your date")
            return inst
        end,
        Refresh = function(pod, inst)
            local put = pod.put
            local state = pod.state
            local clock = gameClock()
            local day = clock >= 6 and clock < 18
            local s = if day then (clock - 6) / 12 else ((clock - 18) % 24) / 12
            local x, y = skyPoint(s)
            local color = if day then Glass.Warning else Glass.LensTint
            put(inst.sun, "Position", UDim2.fromOffset(x, y))
            put(inst.sun, "BackgroundColor3", color)
            put(inst.glow, "Position", UDim2.fromOffset(x, y))
            put(inst.glow, "ImageColor3", color)
            local phase = phaseOf(clock)
            put(pod.Tag, "Text", phase)
            put(pod.Tag, "TextColor3", if day then Glass.Warning else Glass.Accent)
            put(inst.game, "Text", "Game " .. hhmm(clock))
            put(inst.real, "Text", "You " .. os.date("%H:%M"))

            -- How fast the game's clock runs, from successive samples.
            local now = os.clock()
            if state.lastClock then
                local elapsed = now - state.lastTime
                local moved = (clock - state.lastClock) % 24
                if elapsed > 0.5 and moved < 6 then
                    local rate = moved / elapsed -- game hours per real second
                    state.rate = if state.rate then state.rate * 0.7 + rate * 0.3 else rate
                end
            end
            state.lastClock, state.lastTime = clock, now
            if pod.layer == "expanded" then
                local rate = state.rate
                if rate and rate > 1e-5 then
                    local untilChange = ((if day then 18 else 6) - clock) % 24
                    put(inst.next, "Text", string.format("%s in %s", if day then "Sunset" else "Sunrise", Telemetry.Duration(untilChange / rate)))
                    put(inst.rate, "Text", Telemetry.Duration(1 / rate) .. " real")
                else
                    put(inst.next, "Text", if day then "Sunset at 18:00" else "Sunrise at 06:00")
                    put(inst.rate, "Text", if rate then "Clock is still" else "Measuring...")
                end
                put(inst.today, "Text", os.date("%a %d %b"))
            end
        end,
        Summary = function()
            local clock = gameClock()
            return hhmm(clock), phaseOf(clock), string.format("%dh", math.floor(clock))
        end,
    })

    -------------------------------------------------------------------------------------------------------
    -- Activity feed: what the script did, newest first. Notifications and your clicks feed it.
    -------------------------------------------------------------------------------------------------------
    K.Define("Activity", {
        Title = "ACTIVITY", Side = "Left", Moon = "LOG", Expands = true,
        Build = function(pod, layer)
            local inst = { lines = {} }
            for i = 1, 8 do
                local y = 28 + (i - 1) * 18
                inst.lines[i] = {
                    Time = Label(layer, { FontFace = FONT_MONO, TextSize = 10, Position = UDim2.fromOffset(12, y), Size = UDim2.fromOffset(54, 16) }, "TextMuted"),
                    Text = Label(layer, { Position = UDim2.fromOffset(66, y), Size = UDim2.fromOffset(POD_W - 78, 16) }, "TextPrimary"),
                }
            end
            table.insert(Library.ActivityListeners, function()
                if pod.alpha > 0.01 then pod:Refresh() end
            end)
            return inst
        end,
        Refresh = function(pod, inst)
            local put = pod.put
            local log = Library.ActivityLog
            for i, line in ipairs(inst.lines) do
                local entry = log[i]
                put(line.Time, "Text", if entry then entry.time else "")
                put(line.Text, "Text", if entry then entry.title elseif i == 1 then "Nothing yet" else "")
            end
        end,
        Summary = function()
            local latest = Library.ActivityLog[1]
            return (if latest then latest.title else "Nothing yet"), "", tostring(#Library.ActivityLog)
        end,
    })

    -------------------------------------------------------------------------------------------------------
    -- Network: data in and out as two live lines, with the game's memory use.
    -------------------------------------------------------------------------------------------------------
    local function readStat(read)
        local ok, value = pcall(read)
        return if ok and typeof(value) == "number" then value else nil
    end
    local function memoryText(mb)
        if not mb then return "--" end
        if mb >= 1024 then return string.format("%.2f GB", mb / 1024) end
        return string.format("%d MB", math.floor(mb + 0.5))
    end

    K.Define("Network", {
        Title = "NETWORK", Side = "Left", Moon = "KB/S", Expands = true, Tag = true,
        Build = function(pod, layer)
            local inst = {}
            pod.state.down, pod.state.up = pod.state.down or {}, pod.state.up or {}
            inst.down = K.Line(layer, 12, 28, POD_W - 24, 44, 24, "Accent")
            inst.up = K.Line(layer, 12, 28, POD_W - 24, 44, 24, "Success")
            Label(layer, { Text = "In", Position = UDim2.fromOffset(12, 78), Size = UDim2.fromOffset(16, 14) }, "Accent")
            inst.downText = Label(layer, { Position = UDim2.fromOffset(28, 78), Size = UDim2.fromOffset(60, 14) }, "TextPrimary")
            inst.upText = Label(layer, {
                TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.fromOffset(POD_W - 12, 78), Size = UDim2.fromOffset(60, 14),
            }, "TextPrimary")
            Label(layer, {
                Text = "Out", TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.fromOffset(POD_W - 76, 78), Size = UDim2.fromOffset(24, 14),
            }, "Success")
            detailRule(layer)
            inst.memory = detailRow(layer, 110, "Memory")
            inst.peakDown = detailRow(layer, 130, "Peak in")
            inst.peakUp = detailRow(layer, 150, "Peak out")
            return inst
        end,
        Refresh = function(pod, inst)
            local put = pod.put
            local state = pod.state
            local down = readStat(function() return Stats.DataReceiveKbps end) or 0
            local up = readStat(function() return Stats.DataSendKbps end) or 0
            table.insert(state.down, down)
            table.insert(state.up, up)
            if #state.down > 32 then table.remove(state.down, 1) end
            if #state.up > 32 then table.remove(state.up, 1) end
            local ceiling = 1
            for i = 1, #state.down do ceiling = math.max(ceiling, state.down[i] * 1.2, state.up[i] * 1.2) end
            inst.down:Set(state.down, ceiling)
            inst.up:Set(state.up, ceiling)
            put(inst.downText, "Text", string.format("%.1f kB/s", down))
            put(inst.upText, "Text", string.format("%.1f kB/s", up))
            state.peakDown = math.max(state.peakDown or 0, down)
            state.peakUp = math.max(state.peakUp or 0, up)
            local memory = readStat(function() return Stats:GetTotalMemoryUsageMb() end)
            put(pod.Tag, "Text", memoryText(memory))
            if pod.layer == "expanded" then
                put(inst.memory, "Text", memoryText(memory))
                put(inst.peakDown, "Text", string.format("%.1f kB/s", state.peakDown))
                put(inst.peakUp, "Text", string.format("%.1f kB/s", state.peakUp))
            end
        end,
        Summary = function()
            local down = readStat(function() return Stats.DataReceiveKbps end)
            if not down then return "--", "kB/s in", "--" end
            return string.format("%.1f", down), "kB/s in", tostring(math.floor(down + 0.5))
        end,
    })

    -------------------------------------------------------------------------------------------------------
    -- Friends here: friends in this server with their avatars. Someone joining lights up.
    -------------------------------------------------------------------------------------------------------
    local function friendsHere(state)
        local list = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if state.friends and state.friends[player.UserId] == true then table.insert(list, player) end
        end
        return list
    end

    K.Define("Friends", {
        Title = "FRIENDS HERE", Side = "Right", Moon = "FRND", Tag = true,
        Build = function(pod, layer)
            local inst = { avatars = {} }
            local state = pod.state
            state.friends, state.thumbs = state.friends or {}, state.thumbs or {}
            for i = 1, 4 do
                local holder = New("Frame", {
                    Position = UDim2.fromOffset(12 + (i - 1) * 39, 28), Size = UDim2.fromOffset(36, 50),
                    BackgroundTransparency = 1, Visible = false, ZIndex = 3,
                }, layer)
                local image = Themed(New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(30, 30),
                    BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 4,
                }, holder), { BackgroundColor3 = "LensTint" })
                Corner(image, 15)
                local ring = New("UIStroke", { Thickness = 2, Transparency = 1, Color = Glass.Accent }, image)
                local initials = Label(image, {
                    TextSize = 10, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 5,
                }, "TextPrimary")
                local name = Label(holder, {
                    TextSize = 9, TextXAlignment = Enum.TextXAlignment.Center,
                    Position = UDim2.fromOffset(-2, 33), Size = UDim2.fromOffset(40, 12),
                })
                inst.avatars[i] = { Holder = holder, Image = image, Ring = ring, Initials = initials, Name = name }
            end
            inst.note = Label(layer, { Position = UDim2.fromOffset(12, 80), Size = UDim2.fromOffset(POD_W - 24, 14) })

            -- Friendship and headshots are web calls that yield, so they run on their own threads and
            -- are asked once per player.
            local function check(player, joined)
                if player == Players.LocalPlayer then return end
                local id = player.UserId
                if state.friends[id] ~= nil then
                    if joined and state.friends[id] then
                        state.note, state.pulse = player.DisplayName .. " joined", player
                        pod:Refresh()
                    end
                    return
                end
                state.friends[id] = false
                task.spawn(function()
                    local ok, friend = pcall(function() return Players.LocalPlayer:IsFriendsWith(id) end)
                    state.friends[id] = ok and friend == true
                    if not state.friends[id] then return end
                    local okThumb, thumb = pcall(function()
                        return Players:GetUserThumbnailAsync(id, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                    end)
                    if okThumb then state.thumbs[id] = thumb end
                    if joined then state.note, state.pulse = player.DisplayName .. " joined", player end
                    pod:Refresh()
                end)
            end
            for _, player in ipairs(Players:GetPlayers()) do check(player, false) end
            Library:GiveSignal(Players.PlayerAdded:Connect(function(player) check(player, true) end))
            Library:GiveSignal(Players.PlayerRemoving:Connect(function(player)
                if state.friends[player.UserId] then
                    state.note = player.DisplayName .. " left"
                    task.defer(function() pod:Refresh() end)
                end
            end))
            return inst
        end,
        Refresh = function(pod, inst)
            local put = pod.put
            local state = pod.state
            local list = friendsHere(state)
            for i, avatar in ipairs(inst.avatars) do
                local player = list[i]
                put(avatar.Holder, "Visible", player ~= nil)
                if player then
                    put(avatar.Image, "Image", state.thumbs[player.UserId] or "")
                    put(avatar.Initials, "Text", if state.thumbs[player.UserId] then "" else player.DisplayName:sub(1, 2):upper())
                    put(avatar.Name, "Text", player.DisplayName)
                    if state.pulse == player and not Library.LowGraphics then
                        avatar.Ring.Transparency = 0
                        Tween(avatar.Ring, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Transparency = 1 })
                        pod:Flash(Glass.Accent)
                    end
                end
            end
            state.pulse = nil
            put(pod.Tag, "Text", tostring(#list))
            put(inst.note, "Text", state.note or (if #list == 0 then "No friends in this server" elseif #list > 4 then string.format("and %d more", #list - 4) else ""))
        end,
        Summary = function(pod)
            if not pod.state.friends then return "--", "friends here", "--" end
            local count = #friendsHere(pod.state)
            return tostring(count), "friends here", tostring(count)
        end,
    })

    -------------------------------------------------------------------------------------------------------
    -- Quick actions: buttons pinned from the window with a right-click, one click away.
    -------------------------------------------------------------------------------------------------------
    local ACTION_W, ACTION_H, ACTION_GAP = (POD_W - 24 - 6) / 2, 24, 6
    K.Define("QuickActions", {
        Title = "QUICK ACTIONS", Side = "Right", Moon = "ACTS", Expands = true, Tag = true,
        Build = function(pod, layer)
            local inst = { chips = {}, built = {}, layer = layer }
            inst.hint = Label(layer, {
                Text = "Right-click any button in the window to pin it here.",
                TextWrapped = true, TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top,
                Position = UDim2.fromOffset(12, 30), Size = UDim2.fromOffset(POD_W - 24, 48),
            })
            return inst
        end,
        Refresh = function(pod, inst)
            local list = pod.W.QuickActions
            local same = #list == #inst.built
            for i, button in ipairs(list) do
                if inst.built[i] ~= button then same = false end
            end
            if not same then
                for _, chip in ipairs(inst.chips) do chip:Destroy() end
                inst.chips, inst.built = {}, table.clone(list)
                for i, button in ipairs(list) do
                    local column, row = (i - 1) % 2, math.floor((i - 1) / 2)
                    local chip = K.Chip(pod, inst.layer, 12 + column * (ACTION_W + ACTION_GAP), 30 + row * (ACTION_H + ACTION_GAP),
                        ACTION_W, ACTION_H, tostring(button.Text), row >= 2)
                    local armed = false
                    chip.Hit.MouseButton1Click:Connect(function()
                        if button.Disabled then return end
                        if button.DoubleClick and not armed then
                            armed = true
                            chip.Label.Text = "Confirm?"
                            task.delay(1.5, function()
                                armed = false
                                chip.Label.Text = tostring(button.Text)
                            end)
                            return
                        end
                        armed = false
                        chip.Label.Text = tostring(button.Text)
                        chip:Flash()
                        playSound("Press")
                        Library:Log("Pressed " .. tostring(button.Text))
                        Library:SafeCallback(button.Func)
                    end)
                    chip.Hit.MouseButton2Click:Connect(function()
                        local index = table.find(list, button)
                        if index then table.remove(list, index) end
                        playSound("Close")
                        pod:Refresh()
                    end)
                    inst.chips[i] = chip
                end
            end
            for i, chip in ipairs(inst.chips) do
                local button = list[i]
                if button then pod.put(chip.Label, "TextTransparency", if button.Disabled then 0.5 else 0) end
            end
            pod.put(inst.hint, "Visible", #list == 0)
            pod.put(pod.Tag, "Text", string.format("%d / 10", #list))
        end,
        Summary = function(pod)
            local count = #pod.W.QuickActions
            return tostring(count), if count == 1 then "action" else "actions", tostring(count)
        end,
    })

    -------------------------------------------------------------------------------------------------------
    -- Timer: a stopwatch or countdown you run from the pod. Click the dial to start or pause it,
    -- right-click to reset. It keeps time while the window is closed.
    -------------------------------------------------------------------------------------------------------
    local PRESETS = { { "Watch", 0 }, { "1m", 60 }, { "5m", 300 }, { "10m", 600 } }
    local function timerElapsed(state)
        return (state.accumulated or 0) + (if state.running then os.clock() - state.started else 0)
    end

    K.Define("Timer", {
        Title = "TIMER", Side = "Right", Moon = "TIMER", Expands = true, Tag = true,
        Build = function(pod, layer)
            local inst = {}
            local state = pod.state
            state.duration = state.duration or 0 -- 0 = stopwatch
            state.laps = state.laps or {}
            state.token = state.token or 0
            local cx, cy = 42, 62
            inst.ring = K.DotArc(layer, cx, cy, 26, 20, -90, 252, 4)
            inst.glyph = Label(layer, {
                Text = "▶", TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromOffset(cx, cy), Size = UDim2.fromOffset(30, 20),
            }, "TextPrimary")
            inst.time = Value(layer, { Text = "0:00.0", TextSize = 20, Position = UDim2.fromOffset(80, 36), Size = UDim2.fromOffset(POD_W - 92, 24) })
            inst.laps = Label(layer, { Text = "Laps 0", Position = UDim2.fromOffset(80, 62), Size = UDim2.fromOffset(40, 14) })
            inst.action = K.Chip(pod, layer, POD_W - 12 - 40, 64, 40, 22, "Lap")

            local function finish(token)
                if token ~= state.token or not state.running then return end
                state.accumulated, state.running = state.duration, false
                Library:Notify({ Title = "Timer", Description = clockText(state.duration) .. " countdown finished", Time = 5 })
                Library:Log("Timer finished")
                playSound("Open")
                pod:Flash(Glass.Warning)
                pod:Refresh()
            end
            local function start()
                state.running, state.started = true, os.clock()
                state.token += 1
                if state.duration > 0 then
                    local token = state.token
                    task.delay(math.max(0, state.duration - timerElapsed(state)), function() finish(token) end)
                end
            end
            local function pause()
                state.accumulated = timerElapsed(state)
                state.running = false
                state.token += 1
            end
            local function reset()
                state.running, state.accumulated, state.laps = false, 0, {}
                state.token += 1
            end
            inst.reset = reset

            local dial = pod:Control({ Position = UDim2.fromOffset(10, 28), Size = UDim2.fromOffset(110, 64) })
            dial.MouseButton1Click:Connect(function()
                if state.running then
                    pause()
                else
                    if state.duration > 0 and timerElapsed(state) >= state.duration then state.accumulated = 0 end
                    start()
                end
                playSound(if state.running then "ToggleOn" else "ToggleOff")
                pod:Refresh()
            end)
            dial.MouseButton2Click:Connect(function()
                reset()
                playSound("Close")
                pod:Refresh()
            end)
            inst.action.Hit.MouseButton1Click:Connect(function()
                inst.action:Flash()
                playSound("Press")
                if state.duration > 0 then
                    -- Countdown: add a minute.
                    state.duration += 60
                    if state.running then
                        state.token += 1
                        local token = state.token
                        task.delay(math.max(0, state.duration - timerElapsed(state)), function() finish(token) end)
                    end
                else
                    table.insert(state.laps, 1, timerElapsed(state))
                end
                pod:Refresh()
            end)

            detailRule(layer)
            inst.presets = {}
            local presetW = (POD_W - 24 - 3 * 5 - 46) / 3
            for i, preset in ipairs(PRESETS) do
                local x = if i == 1 then 12 else 12 + 46 + 5 + (i - 2) * (presetW + 5)
                local chip = K.Chip(pod, layer, x, 110, if i == 1 then 46 else presetW, 22, preset[1], true)
                chip.Hit.MouseButton1Click:Connect(function()
                    chip:Flash()
                    reset()
                    state.duration = preset[2]
                    playSound("Press")
                    pod:Refresh()
                end)
                inst.presets[i] = chip
            end
            inst.lapRows = { detailRow(layer, 140, ""), detailRow(layer, 158, "") }
            return inst
        end,
        Live = function(pod, inst, dt)
            local state = pod.state
            if state.running and throttle(state, dt, 10) then pod:Refresh() end
        end,
        Refresh = function(pod, inst)
            local put = pod.put
            local state = pod.state
            local elapsed = timerElapsed(state)
            local countdown = state.duration > 0
            local shown = if countdown then math.max(0, state.duration - elapsed) else elapsed
            put(inst.time, "Text", clockText(shown, true))
            put(inst.glyph, "Text", if state.running then "❚❚" else "▶")
            local fraction = if countdown then shown / state.duration else (elapsed % 60) / 60
            inst.ring:Set(fraction, if countdown and shown <= 10 and state.running then Glass.Warning else Glass.Accent)
            put(pod.Tag, "Text", if countdown then clockText(state.duration) .. " timer" else "Stopwatch")
            put(inst.action.Label, "Text", if countdown then "+1m" else "Lap")
            put(inst.laps, "Text", if countdown then (if state.running then "Running" elseif elapsed > 0 then "Paused" else "Ready") else "Laps " .. #state.laps)
            if pod.layer == "expanded" then
                for i, row in ipairs(inst.lapRows) do
                    local lap = state.laps[i]
                    put(row, "Text", if lap then string.format("Lap %d   %s", #state.laps - i + 1, clockText(lap, true)) else "")
                end
            end
        end,
        Summary = function(pod)
            local state = pod.state
            local elapsed = timerElapsed(state)
            local duration = state.duration or 0
            local shown = if duration > 0 then math.max(0, duration - elapsed) else elapsed
            return clockText(shown), (if state.running then "running" elseif elapsed > 0 then "paused" else "ready"), clockText(shown)
        end,
    })

    -------------------------------------------------------------------------------------------------------
    -- Keybinds: every bind with its key and a light for whether it is on, hold binds included.
    -------------------------------------------------------------------------------------------------------
    local function listedBinds()
        local list = {}
        for _, picker in ipairs(KeybindEntries) do
            if not picker.NoUI and picker.Value ~= "None" then table.insert(list, picker) end
        end
        return list
    end
    local function bindActive(picker)
        local ok, active = pcall(function() return picker:GetState() end)
        return ok and active == true
    end

    K.Define("Keybinds", {
        Title = "KEYBINDS", Side = "Left", Moon = "BINDS", Expands = true, Tag = true,
        Build = function(pod, layer)
            local inst = { rows = {} }
            for i = 1, 8 do
                local y = 28 + (i - 1) * 18
                local cap = New("Frame", {
                    Position = UDim2.fromOffset(12, y + 1), Size = UDim2.fromOffset(28, 14), BackgroundTransparency = 0.86,
                    BorderSizePixel = 0, Visible = false, ZIndex = 3,
                }, layer)
                Themed(cap, { BackgroundColor3 = "LensTint" })
                Corner(cap, 4)
                Themed(New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1, Transparency = 0.6 }, cap), { Color = "Rim" })
                local key = Label(cap, {
                    FontFace = FONT_MONO, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 4,
                }, "TextPrimary")
                local name = Label(cap, { Position = UDim2.fromOffset(34, -1), Size = UDim2.fromOffset(POD_W - 24 - 34 - 46, 16) }, "TextPrimary")
                local mode = Label(cap, {
                    TextSize = 9, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.fromOffset(POD_W - 24 - 12, -1), Size = UDim2.fromOffset(40, 16),
                })
                local light = K.Dot(cap, 6, UDim2.fromOffset(POD_W - 24 - 3, 7), nil, 4)
                inst.rows[i] = { Cap = cap, Key = key, Name = name, Mode = mode, Light = light }
            end
            inst.empty = Label(layer, { Text = "No keybinds set", Position = UDim2.fromOffset(12, 30), Size = UDim2.fromOffset(POD_W - 24, 16) })
            table.insert(Library.KeybindListeners, function()
                if pod.alpha > 0.01 then pod:Refresh() end
            end)
            return inst
        end,
        Refresh = function(pod, inst)
            local put = pod.put
            local list = listedBinds()
            local on = 0
            for i, row in ipairs(inst.rows) do
                local picker = list[i]
                put(row.Cap, "Visible", picker ~= nil)
                if picker then
                    local active = bindActive(picker)
                    put(row.Key, "Text", keyDisplayName(picker.Value))
                    put(row.Name, "Text", tostring(picker.Text or ""))
                    put(row.Mode, "Text", if picker.Mode == "Toggle" then "" else string.lower(tostring(picker.Mode)))
                    put(row.Light, "BackgroundColor3", if active then Glass.Accent else Glass.Glyph)
                    put(row.Light, "BackgroundTransparency", if active then 0 else 0.6)
                end
            end
            for _, picker in ipairs(list) do
                if bindActive(picker) then on += 1 end
            end
            put(inst.empty, "Visible", #list == 0)
            put(pod.Tag, "Text", string.format("%d on", on))
        end,
        Summary = function()
            local list = listedBinds()
            local on = 0
            for _, picker in ipairs(list) do
                if bindActive(picker) then on += 1 end
            end
            return string.format("%d on", on), string.format("of %d", #list), tostring(on)
        end,
    })
end
