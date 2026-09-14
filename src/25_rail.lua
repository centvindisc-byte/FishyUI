-------------------------------------------------------------------------------------------------------
-- Edge rail
--
-- Shove the window off the left or right side of the screen and it collapses into a slim strip of glass
-- carrying one icon per tab. Click an icon to come back on that tab; double-tap the rail to come back
-- where you left off. It is the "keep it up while playing" mode: the interface is still there, but it
-- costs 52 pixels instead of half the screen.
-------------------------------------------------------------------------------------------------------
local RAIL_ICON = 30
local RAIL_PAD = 9

BuildRail = function(W)
    local ScreenGui, Holder, Window = W.ScreenGui, W.Holder, W.Window

    local Rail = New("Frame", {
        Name = "EdgeRail",
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(L.EdgeRailWidth, 120),
        Visible = false,
        ZIndex = 180,
    }, ScreenGui)
    local RailScale = New("UIScale", { Scale = 1 }, Rail)
    GlassShadow(Rail, 16, "ShadowTransparency", 0)

    -- CanvasGroup only for the fade; the glass goes on an inner Frame. A UIGradient parented to a
    -- CanvasGroup multiplies over every child it renders, which would black out the tab icons.
    local Body = New("CanvasGroup", {
        Name = "Body",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        GroupTransparency = 1,
        ZIndex = 2,
    }, Rail)
    local Surface = New("Frame", {
        Name = "Surface",
        Size = UDim2.fromScale(1, 1),
        ZIndex = 1,
    }, Body)
    local RailPane = PaneMaterial(Surface, 16, 40)
    -- The rail sits on top of gameplay, not on the window's glass, so it stays close to opaque.
    Themed(Surface, { BackgroundTransparency = function() return math.min(Glass.PaneTransparency, 0.1) end })

    local Hit = New("TextButton", {
        Name = "Hitbox", Text = "", AutoButtonColor = false,
        BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 40,
    }, Rail)

    local side, active, icons = "Left", false, {}

    -- The grabber: a short bar on the screen-facing side, the handle you'd pull to open it again.
    local Grabber = Themed(New("Frame", {
        Name = "Grabber",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(3, 26),
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        ZIndex = 30,
    }, Body), { BackgroundColor3 = "Accent" })
    Corner(Grabber, 2)

    local function clearIcons()
        for _, icon in ipairs(icons) do icon.Button:Destroy() end
        table.clear(icons)
    end

    -- One button per tab, in the sidebar's current order. Rebuilt on every entry so a reordered or
    -- newly added tab is always represented.
    local function buildIcons()
        clearIcons()
        for i, tab in ipairs(Window.Tabs) do
            local button = New("TextButton", {
                Name = "Rail_" .. tab.Name,
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, RAIL_PAD + (i - 1) * (RAIL_ICON + 6)),
                Size = UDim2.fromOffset(RAIL_ICON + 6, RAIL_ICON),
                ZIndex = 20,
            }, Body)
            local plate = Themed(New("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = Window.ActiveTab == tab and 0.86 or 1,
                BorderSizePixel = 0,
                ZIndex = 20,
            }, button), { BackgroundColor3 = "LensTint" })
            Corner(plate, 9)
            local scale = New("UIScale", { Scale = 1 }, button)

            local glyph
            if tab.IconImage then
                glyph = Themed(New("ImageLabel", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    Size = UDim2.fromOffset(L.IconSize, L.IconSize),
                    BackgroundTransparency = 1,
                    Image = tab.IconImage.Image,
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 21,
                }, button), { ImageColor3 = function() return Window.ActiveTab == tab and Glass.TextPrimary or Glass.Glyph end })
            else
                -- No icon: the tab's initial stands in for it.
                glyph = Themed(Text(button, {
                    Text = tab.Name:sub(1, 1):upper(),
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Size = UDim2.fromScale(1, 1),
                    ZIndex = 21,
                }), { TextColor3 = function() return Window.ActiveTab == tab and Glass.TextPrimary or Glass.Glyph end })
            end

            button.MouseEnter:Connect(function()
                Tween(plate, Motion.Hover, { BackgroundTransparency = 0.86 })
                Tween(scale, Motion.Pop, { Scale = 1.12 })
                playSound("Hover")
                W:ShowTooltip(button, tab.Name)
            end)
            button.MouseLeave:Connect(function()
                if Window.ActiveTab ~= tab then Tween(plate, Motion.Hover, { BackgroundTransparency = 1 }) end
                Tween(scale, Motion.Pop, { Scale = 1 })
                W:HideTooltip(button)
            end)
            button.MouseButton1Click:Connect(function()
                W.ExitRail()
                tab:Show()
            end)
            icons[i] = { Button = button, Plate = plate, Glyph = glyph, Tab = tab }
        end
        Rail.Size = UDim2.fromOffset(L.EdgeRailWidth, RAIL_PAD * 2 + math.max(1, #Window.Tabs) * (RAIL_ICON + 6) - 6)
    end

    -- Where the rail rests, and where it starts from so it appears to slide in out of the screen edge.
    local function restingX()
        if side == "Left" then return 0 end
        return ScreenGui.AbsoluteSize.X - L.EdgeRailWidth
    end
    local function hiddenX()
        if side == "Left" then return -L.EdgeRailWidth end
        return ScreenGui.AbsoluteSize.X
    end

    function W.EnterRail(toSide)
        if active or not Window.ActiveTab then return end
        side = toSide == "Right" and "Right" or "Left"
        active = true
        W.RailActive = true
        W:ClosePopup()
        W:HideTooltip()
        W.EndTabDrag()

        buildIcons()
        -- Round off only the two corners facing the screen; the edge-facing side runs flush off it.
        Grabber.Position = UDim2.new(side == "Left" and 1 or 0, side == "Left" and -6 or 6, 0.5, 0)

        Holder.Visible = false
        if W.OnWindowVisibility then W.OnWindowVisibility(false) end
        if W.Blur then Tween(W.Blur, Motion.Blur, { Size = 0 }) end

        Rail.Visible = true
        Rail.Position = UDim2.new(0, hiddenX(), 0.5, 0)
        RailScale.Scale = 0.9
        Tween(Rail, Motion.Slide, { Position = UDim2.new(0, restingX(), 0.5, 0) })
        Tween(RailScale, Motion.Pop, { Scale = 1 })
        Tween(Body, Motion.IntroSoft, { GroupTransparency = 0 })
        playSound("Close")

        -- Icons arrive one after another rather than all at once.
        for i, icon in ipairs(icons) do
            icon.Button.Position = UDim2.new(0.5, side == "Left" and -14 or 14, 0, RAIL_PAD + (i - 1) * (RAIL_ICON + 6))
            task.delay(0.06 + i * 0.04, function()
                if not active then return end
                Tween(icon.Button, Motion.Intro, {
                    Position = UDim2.new(0.5, 0, 0, RAIL_PAD + (i - 1) * (RAIL_ICON + 6)),
                })
            end)
        end
    end

    function W.ExitRail()
        if not active then return end
        active = false
        W.RailActive = false
        W:HideTooltip()
        Tween(Rail, Motion.Outro, { Position = UDim2.new(0, hiddenX(), 0.5, 0) })
        Tween(Body, Motion.Outro, { GroupTransparency = 1 })
        playSound("Open")
        task.delay(Motion.Outro.Time, function()
            if active then return end
            Rail.Visible = false
            clearIcons()
        end)

        -- Come back tucked just inside the edge the rail was on, not wherever the window was shoved to.
        local ss = ScreenGui.AbsoluteSize
        local half = Vector2.new(Holder.Size.X.Offset, Holder.Size.Y.Offset) * W.Scale.Scale / 2
        local x = if side == "Left" then half.X + L.WindowMargin else ss.X - half.X - L.WindowMargin
        Holder.Position = UDim2.fromOffset(
            if side == "Left" then x - 40 else x + 40,
            math.clamp(Holder.Position.Y.Offset, half.Y, math.max(half.Y, ss.Y - half.Y))
        )
        Library:Toggle(true)
        Tween(Holder, Motion.Intro, { Position = UDim2.fromOffset(x, Holder.Position.Y.Offset) })
    end

    -- Double-tap anywhere on the rail brings the window back as it was.
    local lastTap = 0
    Hit.MouseButton1Click:Connect(function()
        local now = os.clock()
        if now - lastTap < 0.35 then
            lastTap = 0
            W.ExitRail()
        else
            lastTap = now
            -- A single tap just leans the rail out, as a hint that there is more here.
            Tween(RailScale, Motion.Pop, { Scale = 1.05 })
            task.delay(0.18, function()
                if active then Tween(RailScale, Motion.Pop, { Scale = 1 }) end
            end)
        end
    end)
    Hit.MouseEnter:Connect(function()
        Tween(RailPane.Edge, Motion.Hover, { ImageTransparency = 0.25 })
        Tween(Grabber, Motion.Hover, { BackgroundTransparency = 0.1, Size = UDim2.fromOffset(3, 34) })
    end)
    Hit.MouseLeave:Connect(function()
        Tween(RailPane.Edge, Motion.Hover, { ImageTransparency = Glass.EdgeTransparency })
        Tween(Grabber, Motion.Hover, { BackgroundTransparency = 0.45, Size = UDim2.fromOffset(3, 26) })
    end)

    local previousViewport = W.OnViewportChanged
    W.OnViewportChanged = function()
        if previousViewport then previousViewport() end
        if active then Rail.Position = UDim2.new(0, restingX(), 0.5, 0) end
    end

    W.Rail = Rail
end
