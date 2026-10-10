-------------------------------------------------------------------------------------------------------
-- Bubble
--
-- Minimising hands the glass to a bubble at the window's exact size and shrinks it into a draggable pill
-- showing signal strength, ping and region. Hovering the pill widens it to reveal FPS and session time;
-- tapping it grows it back out into the window. Released near a screen edge, it docks onto that edge.
-------------------------------------------------------------------------------------------------------
BuildBubble = function(W)
    local Window, Holder, Scale, ScreenGui, info = W.Window, W.Holder, W.Scale, W.ScreenGui, W.Info

    local bubbleText = info.BubbleText or ((info.Title ~= "" and info.Title) or "Menu")
    local signalWidth = L.SignalBarWidth * 3 + L.SignalBarGap * 2
    local labelX = 16 + signalWidth + 10
    local dividerX = labelX + textWidth(bubbleText, 14, Enum.Font.GothamBold) + 12
    local pingX = dividerX + 13
    local regionX = pingX + textWidth("999 ms", 12, Enum.Font.GothamMedium) + 8
    local collapsedWidth = regionX + textWidth("WW", 12, Enum.Font.GothamMedium) + 16
    local extraDividerX = collapsedWidth - 4
    local fpsX = extraDividerX + 13
    local sessionX = fpsX + textWidth("240 fps", 12, Enum.Font.GothamMedium) + 10
    local expandedWidth = sessionX + textWidth("00:00:00", 12, Enum.Font.RobotoMono) + 18
    local bubbleRadius = L.BubbleHeight / 2

    local BubbleHolder = New("Frame", {
        Name = "Bubble",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(collapsedWidth, L.BubbleHeight),
        Visible = false,
        ZIndex = 200,
    }, ScreenGui)
    local BubbleScale = New("UIScale", { Scale = 1 }, BubbleHolder)
    local ContentAlpha = New("NumberValue", { Name = "ContentAlpha", Value = 0 }, BubbleHolder)
    local ExtraAlpha = New("NumberValue", { Name = "ExtraAlpha", Value = 0 }, BubbleHolder)
    GlassShadow(BubbleHolder, 17, "ShadowTransparency", 1)

    local Body = New("Frame", {
        Name = "Body",
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        ZIndex = 2,
    }, BubbleHolder)
    local Pane = PaneMaterial(Body, bubbleRadius, 50)
    -- Kept fairly opaque so the readout stays legible over the game on see-through themes.
    Themed(Body, { BackgroundTransparency = function() return math.min(Glass.PaneTransparency, 0.12) end })

    local signalBars = {}
    for i, height in ipairs(L.SignalBarHeights) do
        local bar = New("Frame", {
            Name = "SignalBar" .. i,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 16 + (i - 1) * (L.SignalBarWidth + L.SignalBarGap), 0.5, 7),
            Size = UDim2.fromOffset(L.SignalBarWidth, height),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 60,
        }, Body)
        Corner(bar, 1)
        signalBars[i] = { Frame = bar, Height = height }
    end

    local function divider(x)
        return Themed(New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, x, 0.5, 0),
            Size = UDim2.fromOffset(1, 18),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 60,
        }, Body), { BackgroundColor3 = "Rim" })
    end

    local function stat(name, text, x, width, font, token)
        return Themed(Text(Body, {
            Name = name,
            Text = text,
            FontFace = font,
            TextSize = 12,
            TextTransparency = 1,
            TextTruncate = Enum.TextTruncate.None,
            Position = UDim2.fromOffset(x, 0),
            Size = UDim2.new(0, width, 1, 0),
            ZIndex = 60,
        }), { TextColor3 = token })
    end

    local Label = Themed(Text(Body, {
        Name = "Label",
        Text = bubbleText,
        TextSize = 14,
        TextTransparency = 1,
        Position = UDim2.fromOffset(labelX, 0),
        Size = UDim2.new(0, dividerX - labelX - 6, 1, 0),
        ZIndex = 60,
    }), { TextColor3 = "TextPrimary" })
    local Divider = divider(dividerX)
    local PingLabel = stat("Ping", "-- ms", pingX, regionX - pingX, FONT_MEDIUM, "TextPrimary")
    local RegionLabel = stat("Region", "--", regionX, collapsedWidth - regionX, FONT_MEDIUM, "TextSecondary")
    local ExtraDivider = divider(extraDividerX)
    local FpsLabel = stat("Fps", "0 fps", fpsX, sessionX - fpsX, FONT_MEDIUM, "TextSecondary")
    local SessionLabel = stat("Session", "00:00:00", sessionX, expandedWidth - sessionX, FONT_MONO, "TextPrimary")

    local Hitbox = New("TextButton", {
        Name = "Hitbox",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 70,
    }, Body)

    local strength = 0
    local function refresh()
        local ping = Telemetry.Ping
        PingLabel.Text = ping and string.format("%d ms", math.floor(ping + 0.5)) or "-- ms"
        strength = Telemetry.Strength(ping)
        RegionLabel.Text = Telemetry.Region
        FpsLabel.Text = string.format("%d fps", Telemetry.Fps)
        SessionLabel.Text = Telemetry.Clock(os.clock() - Telemetry.SessionStart)
    end
    Telemetry.OnTick(function()
        if BubbleHolder.Visible then refresh() end
    end)

    -- Content fades through ContentAlpha (extras also through ExtraAlpha), and every couple of seconds a
    -- pulse of light runs up the lit signal bars, like a signal being received.
    -- Everything is written only when it changes: the fades only move while the bubble opens or closes, and
    -- the signal pulse rests for most of its cycle, so a bubble sitting on screen costs almost nothing.
    local clock = 0
    local drawnAlpha, drawnExtra
    local function fade(rest, a) return 1 - (1 - rest) * a end
    Library:GiveSignal(RunService.Heartbeat:Connect(function(dt)
        if not BubbleHolder.Visible then return end
        clock += dt
        local alpha = ContentAlpha.Value
        local extra = alpha * ExtraAlpha.Value
        if alpha ~= drawnAlpha or extra ~= drawnExtra then
            drawnAlpha, drawnExtra = alpha, extra
            Label.TextTransparency = fade(0, alpha)
            PingLabel.TextTransparency = fade(0, alpha)
            RegionLabel.TextTransparency = fade(0.15, alpha)
            Divider.BackgroundTransparency = fade(0.78, alpha)
            ExtraDivider.BackgroundTransparency = fade(0.78, extra)
            FpsLabel.TextTransparency = fade(0.1, extra)
            SessionLabel.TextTransparency = fade(0, extra)
        end

        local color = Telemetry.StrengthColor(strength)
        for i, bar in ipairs(signalBars) do
            local lit = i <= strength
            local phase = (clock * 1.1 - (i - 1) * 0.16) % 1.8
            local pulse = if phase < 0.4 then math.sin(phase / 0.4 * math.pi) else 0
            local height = bar.Height + (if lit then pulse * 2 else 0)
            local tint = if lit then color else Glass.Glyph
            local transparency = fade(if lit then 0.12 * (1 - pulse) else 0.72, alpha)
            if bar.DrawnHeight ~= height then
                bar.DrawnHeight = height
                bar.Frame.Size = UDim2.fromOffset(L.SignalBarWidth, height)
            end
            if bar.DrawnTint ~= tint then
                bar.DrawnTint = tint
                bar.Frame.BackgroundColor3 = tint
            end
            if bar.DrawnTransparency ~= transparency then
                bar.DrawnTransparency = transparency
                bar.Frame.BackgroundTransparency = transparency
            end
        end
    end))

    local function screenSize() return ScreenGui.AbsoluteSize end

    local function clampCenter(center, width)
        local ss = screenSize()
        local halfW, halfH = (width or collapsedWidth) / 2 + L.BubbleMargin, L.BubbleHeight / 2 + L.BubbleMargin
        return Vector2.new(
            math.clamp(center.X, halfW, math.max(halfW, ss.X - halfW)),
            math.clamp(center.Y, halfH, math.max(halfH, ss.Y - halfH))
        )
    end

    -- Released near a screen edge, the bubble is drawn flush onto it.
    local function dock(center)
        local ss = screenSize()
        local halfW, halfH = expandedWidth / 2 + L.BubbleMargin, L.BubbleHeight / 2 + L.BubbleMargin
        local x, y = center.X, center.Y
        if x - halfW < L.BubbleEdgeMagnet then x = halfW elseif ss.X - halfW - x < L.BubbleEdgeMagnet then x = ss.X - halfW end
        if y - halfH < L.BubbleEdgeMagnet then y = halfH elseif ss.Y - halfH - y < L.BubbleEdgeMagnet then y = ss.Y - halfH end
        return clampCenter(Vector2.new(x, y))
    end

    local function defaultCenter()
        return clampCenter(Vector2.new(screenSize().X / 2, GuiService:GetGuiInset().Y + L.BubbleMargin + L.BubbleHeight / 2))
    end

    local function windowShape()
        local ss, p, s, scale = screenSize(), Holder.Position, Holder.Size, W:FitScale()
        local center = Vector2.new(p.X.Scale * ss.X + p.X.Offset, p.Y.Scale * ss.Y + p.Y.Offset)
        return center, Vector2.new(s.X.Offset, s.Y.Offset) * scale, Library.CornerRadius * scale
    end

    local function shape(center, shapeSize, radius, tweenInfo)
        local goal = { Position = UDim2.fromOffset(center.X, center.Y), Size = UDim2.fromOffset(shapeSize.X, shapeSize.Y) }
        if tweenInfo then
            Tween(BubbleHolder, tweenInfo, goal)
        else
            BubbleHolder.Position, BubbleHolder.Size = goal.Position, goal.Size
        end
        ReshapePane(Pane, radius, tweenInfo)
    end

    local bubbleCenter
    local expanded, morphing = false, false
    local shownOnce = false
    local morphToken = 0

    local function displayCenter()
        return if expanded then clampCenter(bubbleCenter, expandedWidth) else bubbleCenter
    end

    local function setExpanded(on)
        if expanded == on or morphing or not BubbleHolder.Visible or not bubbleCenter then return end
        expanded = on
        local width = on and expandedWidth or collapsedWidth
        local center = displayCenter()
        Tween(BubbleHolder, Motion.Reveal, {
            Size = UDim2.fromOffset(width, L.BubbleHeight),
            Position = UDim2.fromOffset(center.X, center.Y),
        })
        Tween(ExtraAlpha, on and Motion.FadeIn or Motion.FadeOut, { Value = on and 1 or 0 })
    end

    local function notifyVisibility(visible)
        if W.OnWindowVisibility then W.OnWindowVisibility(visible) end
    end

    function Window:_setVisible(visible)
        morphToken += 1
        local token = morphToken
        if W.Blur then Tween(W.Blur, Motion.Blur, { Size = visible and info.BlurSize or 0 }) end
        if not visible then
            W:ClosePopup()
            W:HideTooltip()
        end

        if not info.Bubble or not shownOnce then
            if visible then
                shownOnce = true
                Scale.Scale = W:FitScale()
            end
            Holder.Visible = visible
            notifyVisibility(visible)
            return
        end

        W.EndTabDrag()
        bubbleCenter = bubbleCenter or defaultCenter()
        local center, shapeSize, radius = windowShape()
        morphing = true
        -- The bubble rests fully open; hovering it tucks the extra stats away.
        expanded = true

        if not visible then
            if Holder.Visible then
                shape(center, shapeSize, radius)
                ContentAlpha.Value = 0
                ExtraAlpha.Value = 0
                BubbleScale.Scale = 1
            end
            refresh()
            Holder.Visible = false
            notifyVisibility(false)
            BubbleHolder.Visible = true
            shape(clampCenter(bubbleCenter, expandedWidth), Vector2.new(expandedWidth, L.BubbleHeight), bubbleRadius, Motion.Collapse)
            task.delay(Motion.Collapse.Time * 0.55, function()
                if token == morphToken then
                    Tween(ContentAlpha, Motion.FadeIn, { Value = 1 })
                    Tween(ExtraAlpha, Motion.FadeIn, { Value = 1 })
                end
            end)
            task.delay(Motion.Collapse.Time, function()
                if token == morphToken then morphing = false end
            end)
        else
            if Holder.Visible then
                morphing = false
                return
            end
            Tween(ContentAlpha, Motion.FadeOut, { Value = 0 })
            Tween(ExtraAlpha, Motion.FadeOut, { Value = 0 })
            shape(center, shapeSize, radius, Motion.Expand)
            task.delay(Motion.Expand.Time, function()
                if token ~= morphToken then return end
                morphing = false
                BubbleHolder.Visible = false
                local target = W:FitScale()
                Scale.Scale = target * 0.985
                Holder.Visible = true
                Tween(Scale, Motion.Hover, { Scale = target })
                notifyVisibility(true)
            end)
        end
    end

    -- Tap to restore; drag to move it anywhere. A drag that ends near an edge docks.
    local press
    Hitbox.InputBegan:Connect(function(input)
        if not isPointer(input) then return end
        press = { start = input.Position, center = bubbleCenter or defaultCenter(), moved = false }
        Tween(BubbleScale, Motion.Press, { Scale = 0.94 })
        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState ~= Enum.UserInputState.End then return end
            connection:Disconnect()
            local released = press
            press = nil
            if not released then return end
            Tween(BubbleScale, Motion.Drop, { Scale = 1 })
            if released.moved then
                bubbleCenter = dock(bubbleCenter)
                local center = displayCenter()
                Tween(BubbleHolder, Motion.Drop, { Position = UDim2.fromOffset(center.X, center.Y) })
            else
                Library:Toggle(true)
            end
        end)
    end)
    Hitbox.MouseEnter:Connect(function()
        Tween(Pane.Edge, Motion.Hover, { ImageTransparency = 0.22 })
        setExpanded(false)
    end)
    Hitbox.MouseLeave:Connect(function()
        Tween(Pane.Edge, Motion.Hover, { ImageTransparency = Glass.EdgeTransparency })
        if not press then setExpanded(true) end
    end)
    Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
        if not press or not isMove(input) then return end
        local delta = input.Position - press.start
        if not press.moved and delta.Magnitude < L.TapSlop then return end
        press.moved = true
        bubbleCenter = clampCenter(press.center + Vector2.new(delta.X, delta.Y))
        local center = displayCenter()
        BubbleHolder.Position = UDim2.fromOffset(center.X, center.Y)
    end))

    local previousViewport = W.OnViewportChanged
    W.OnViewportChanged = function()
        if previousViewport then previousViewport() end
        if not bubbleCenter then return end
        bubbleCenter = clampCenter(bubbleCenter)
        if BubbleHolder.Visible and not morphing then
            local center = displayCenter()
            BubbleHolder.Position = UDim2.fromOffset(center.X, center.Y)
        end
    end

    Window.Bubble = BubbleHolder
end
