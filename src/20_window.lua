-------------------------------------------------------------------------------------------------------
-- Window
--
-- CreateWindow builds the glass shell and the shared context `W`, then hands W to BuildTabs (sidebar,
-- pages, magnetic tabs) and BuildBubble (minimise-to-bubble), which are defined in the next files.
-------------------------------------------------------------------------------------------------------
-- assigned in 21_tabs.lua, 22_bubble.lua, 23_satellites.lua, 24_themeselect.lua, 25_rail.lua
-- (BuildAmbient and BuildCursor are plain locals from 08/09, already in scope by the time we get here)
local BuildTabs, BuildBubble, BuildSatellites, BuildSetupFlow, BuildRail

local WindowDefaults = {
    Title = "",
    Footer = "",
    Icon = nil,
    Position = UDim2.fromOffset(6, 6),
    Size = UDim2.fromOffset(760, 600),
    AutoShow = true,
    Center = true,
    AlwaysOnTop = false,
    CornerRadius = 14,
    NotifySide = "Right",
    ShowCustomCursor = true,
    ToggleKeybind = Enum.KeyCode.RightControl,

    -- FishyUI extras
    Brand = "Fishy Studios", -- subtitle under the window title in the sidebar header; "" hides it
    Theme = nil, -- starting theme; defaults to the last one picked (saved to disk when possible)
    ThemeSelect = nil, -- true = always show the theme picker first; nil = only on first run; false = never
    Blur = true,
    BlurSize = 18,
    Bubble = true, -- minimise into a draggable glass bubble instead of vanishing
    Satellites = true, -- magnetic info pods (session, performance, server) docked to the window's side
    BubbleText = nil, -- defaults to Title, or "Menu" when there is no title
}

local THEME_TILE_WIDTH, THEME_TILE_HEIGHT, THEME_TILE_GAP = 98, 62, 8

function Library:CreateWindow(info)
    info = merge(WindowDefaults, info)

    self.CornerRadius = info.CornerRadius
    self.NotifySide = info.NotifySide
    self.ShowCustomCursor = info.ShowCustomCursor
    self.ToggleKeybind = info.ToggleKeybind

    applyPrefs() -- language and font chosen on a previous run, before anything is built
    applySoundPrefs()
    local savedTheme = loadThemeChoice()
    local startTheme = info.Theme or savedTheme
    if startTheme and Themes[startTheme] then
        self.Theme = startTheme
        for key, value in pairs(Themes[startTheme]) do Glass[key] = value end
    end
    syncScheme()

    local Window = {
        AlwaysOnTop = info.AlwaysOnTop,
        Tabs = {},
        ActiveTab = nil,
        OnTabOrderChanged = nil,
        OnThemeChanged = nil,
    }
    local W = { Info = info, Window = Window }
    self.Window = Window

    local size = toPixels(info.Size)
    size = Vector2.new(math.max(size.X, L.MinWindow.X), math.max(size.Y, L.MinWindow.Y))

    local ScreenGui = New("ScreenGui", {
        Name = "FishyUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = info.AlwaysOnTop and 1000 or 100,
    }, nil)
    mountGui(ScreenGui)
    self.ScreenGui = ScreenGui

    -- Holder carries position, size and scale; the pane inside it clips. Shadow and overlays sit outside the clip.
    local Holder = New("Frame", {
        Name = "Window",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = info.Center and UDim2.fromScale(0.5, 0.5) or (info.Position + UDim2.fromOffset(size.X / 2, size.Y / 2)),
        Size = UDim2.fromOffset(size.X, size.Y),
        Visible = false,
        ZIndex = 1,
    }, ScreenGui)
    local Scale = New("UIScale", { Scale = 1 }, Holder)
    GlassShadow(Holder, 22, "ShadowTransparency", 0)

    local Main = New("Frame", {
        Name = "Main",
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        ZIndex = 1,
    }, Holder)
    local MainPane = PaneMaterial(Main, info.CornerRadius, 50)

    local Sheen = New("Frame", {
        Name = "Sheen",
        Size = UDim2.new(1, 0, 0.55, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 2,
    }, Main)
    local SheenCorner = Corner(Sheen, info.CornerRadius)
    Themed(Sheen, { Visible = atQuality(2) })
    Themed(New("UIGradient", { Rotation = 90 }, Sheen), { Transparency = sheenTransparency })

    -- The glare drifts toward the pointer over the glass. Its layer clips to the pane's rounded corner the
    -- same way the ambient layer does, so the reflection never shows in the corner cut-outs.
    local GlareLayer = New("Frame", {
        Name = "Glare",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        ZIndex = 3,
    }, Main)
    local GlareCorner = Corner(GlareLayer, info.CornerRadius)
    local Light = LiveLight(Main, MainPane.Lights, GlareLayer)
    W.Light = Light
    -- Mouse only: a touch has no hover, and a light that jumps to every tap would read as a glitch.
    Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement or not Holder.Visible then return end
        Light:Point(input.Position)
    end))
    -- A window hidden under the pointer comes back with its light at rest, not leaning at a stale spot.
    Holder:GetPropertyChangedSignal("Visible"):Connect(function()
        if not Holder.Visible then Light:Point(nil) end
    end)

    W.ScreenGui, W.Holder, W.Scale, W.Main = ScreenGui, Holder, Scale, Main

    ---------------------------------------------------------------------------------------------------
    -- Overlay: popups, the scrim that closes them, and tooltips. Lives outside the pane so nothing clips it.
    ---------------------------------------------------------------------------------------------------
    local Overlay = New("Frame", {
        Name = "Overlay",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 150,
    }, Holder)
    local Scrim = New("TextButton", {
        Name = "Scrim",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(-4000, -4000),
        Size = UDim2.new(1, 8000, 1, 8000),
        Visible = false,
        ZIndex = 1,
    }, Overlay)
    W.Overlay = Overlay

    local activePopup
    function W:OpenPopup(frame, onClose)
        if activePopup then W:ClosePopup() end
        frame.ZIndex = 10
        frame.Parent = Overlay
        -- Only GuiButtons sink input. A popup's own body and its Frame-based controls (a colour field, a
        -- hue rail, a gradient ramp) let the click fall straight through to the scrim behind them, which
        -- closes the popup the instant you touch it. This catcher sits at the back of every popup and
        -- swallows anything the panel itself didn't sink, so the scrim only ever sees genuine outside
        -- clicks. It is behind everything, so the controls above it still receive their own input.
        if not frame:FindFirstChild("PopupCatcher") then
            New("TextButton", {
                Name = "PopupCatcher",
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                ZIndex = 0,
            }, frame)
        end
        Scrim.Visible = true
        activePopup = { Frame = frame, OnClose = onClose }
    end

    function W:ClosePopup()
        local popup = activePopup
        if not popup then return end
        activePopup = nil
        Scrim.Visible = false
        if popup.OnClose then popup.OnClose() else popup.Frame:Destroy() end
    end
    Scrim.MouseButton1Click:Connect(function() W:ClosePopup() end)
    Scrim.MouseButton2Click:Connect(function() W:ClosePopup() end)

    function W:ToLocal(absolute)
        return (absolute - Holder.AbsolutePosition) / Scale.Scale
    end

    -- Puts a popup under `anchor` (or above it when there isn't room), aligned to the anchor's left edge
    -- when the popup is at least as wide, otherwise to its right edge. Popups above grow upward.
    function W:PlacePopup(frame, anchor, gap, height)
        local topLeft = W:ToLocal(anchor.AbsolutePosition)
        local anchorSize = anchor.AbsoluteSize / Scale.Scale
        local width = frame.Size.X.Offset
        local windowSize = Holder.Size
        local x = width >= anchorSize.X - 1 and topLeft.X or (topLeft.X + anchorSize.X - width)
        x = math.clamp(x, 8, math.max(8, windowSize.X.Offset - width - 8))
        local below = topLeft.Y + anchorSize.Y + gap
        if below + height > windowSize.Y.Offset - 8 and topLeft.Y - gap - height > 8 then
            frame.AnchorPoint = Vector2.new(0, 1)
            -- Growing upward: keep the top edge inside the window.
            frame.Position = UDim2.fromOffset(x, math.max(height + 8, topLeft.Y - gap))
        else
            frame.AnchorPoint = Vector2.new(0, 0)
            -- Growing downward: a tall popup (the gradient editor) under a low anchor would otherwise
            -- hang off the bottom of the window, so pull it up until it fits.
            frame.Position = UDim2.fromOffset(x, math.clamp(below, 8, math.max(8, windowSize.Y.Offset - height - 8)))
        end
    end

    local Tooltip = New("Frame", {
        Name = "Tooltip",
        Size = UDim2.fromOffset(0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        Visible = false,
        ZIndex = 50,
    }, Overlay)
    PopupMaterial(Tooltip, 8, 20)
    New("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 9),
        PaddingRight = UDim.new(0, 9),
    }, Tooltip)
    local TooltipText = Themed(Text(Tooltip, {
        FontFace = FONT_MEDIUM,
        TextSize = 12,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.fromOffset(0, 0),
        ZIndex = 51,
    }), { TextColor3 = "TextSecondary" })
    New("UISizeConstraint", { MaxSize = Vector2.new(240, 400) }, TooltipText)
    local TooltipScale = New("UIScale", { Scale = 1 }, Tooltip)

    local tooltipTarget, tooltipToken = nil, 0
    function W:ShowTooltip(target, text)
        tooltipTarget = target
        tooltipToken += 1
        local token = tooltipToken
        task.delay(0.35, function()
            if token ~= tooltipToken or tooltipTarget ~= target or not target.Parent then return end
            TooltipText.Text = text
            local topLeft = W:ToLocal(target.AbsolutePosition)
            local targetSize = target.AbsoluteSize / Scale.Scale
            Tooltip.Position = UDim2.fromOffset(
                math.clamp(topLeft.X, 8, math.max(8, Holder.Size.X.Offset - 260)),
                topLeft.Y + targetSize.Y + 6
            )
            TooltipScale.Scale = 0.94
            Tooltip.Visible = true
            Tween(TooltipScale, Motion.Pop, { Scale = 1 })
        end)
    end

    function W:HideTooltip(target)
        if target and target ~= tooltipTarget then return end
        tooltipTarget = nil
        tooltipToken += 1
        Tooltip.Visible = false
    end

    ---------------------------------------------------------------------------------------------------
    -- Sidebar header: the window title with the brand beneath it
    ---------------------------------------------------------------------------------------------------
    local BrandHeader = New("Frame", {
        Name = "BrandHeader",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(L.SidebarInset + 8, 14),
        Size = UDim2.new(0, L.SidebarWidth - L.SidebarInset * 2 - 8, 0, L.BrandHeight - 14),
        ZIndex = 6,
    }, Main)
    local hasBrand = info.Brand ~= ""
    local TitleLabel = Themed(Text(BrandHeader, {
        Name = "Title",
        Text = info.Title ~= "" and info.Title or "FishyUI",
        TextSize = 16,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, hasBrand and -8 or 0),
        Size = UDim2.new(1, 0, 0, 20),
        ZIndex = 6,
    }), { TextColor3 = "TextPrimary" })
    if hasBrand then
        Themed(Text(BrandHeader, {
            Name = "Brand",
            Text = info.Brand,
            FontFace = FONT_MEDIUM,
            TextSize = 11,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 10),
            Size = UDim2.new(1, 0, 0, 14),
            ZIndex = 6,
        }), { TextColor3 = "TextMuted" })
    end

    ---------------------------------------------------------------------------------------------------
    -- Sidebar, divider and content area
    ---------------------------------------------------------------------------------------------------
    local sidebarTop = L.BrandHeight + 12
    local Sidebar = New("ScrollingFrame", {
        Name = "Sidebar",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(L.SidebarInset, sidebarTop),
        Size = UDim2.new(0, L.SidebarWidth - L.SidebarInset * 2, 1, -(sidebarTop + L.FooterHeight + 6)),
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 5,
    }, Main)

    local Divider = Themed(New("Frame", {
        Name = "Divider",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0, L.SidebarWidth, 0, 22),
        Size = UDim2.new(0, 1, 1, -(22 + L.FooterHeight + 10)),
        BorderSizePixel = 0,
        ZIndex = 4,
    }, Main), { BackgroundColor3 = "Rim" })
    New("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0.00, 1),
            NumberSequenceKeypoint.new(0.15, 0.86),
            NumberSequenceKeypoint.new(0.85, 0.86),
            NumberSequenceKeypoint.new(1.00, 1),
        }),
    }, Divider)

    local Content = New("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(L.SidebarWidth, 0),
        Size = UDim2.new(1, -L.SidebarWidth, 1, -L.FooterHeight),
        ClipsDescendants = true,
        ZIndex = 5,
    }, Main)

    -- Carried tabs float here: above the pane and unclipped, so they can be taken anywhere.
    local DragLayer = New("Frame", {
        Name = "DragLayer",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 100,
    }, Holder)

    W.Sidebar, W.Content, W.DragLayer = Sidebar, Content, DragLayer

    ---------------------------------------------------------------------------------------------------
    -- Footer text and resize grip
    ---------------------------------------------------------------------------------------------------
    local FooterLabel = Themed(Text(Main, {
        Name = "Footer",
        Text = info.Footer,
        FontFace = FONT_MEDIUM,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(1, -160, 0, L.FooterHeight),
        ZIndex = 15,
    }), { TextColor3 = "TextMuted" })

    local ResizeGrip = New("TextButton", {
        Name = "ResizeGrip",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -5, 1, -5),
        Size = UDim2.fromOffset(L.ResizeGrip, L.ResizeGrip),
        ZIndex = 25,
    }, Main)
    local gripLines = {}
    -- Shaft from (6,6) to the tip at (13,13), plus the two arrowhead strokes meeting at the tip.
    for _, stroke in ipairs({
        { center = Vector2.new(9.5, 9.5), size = Vector2.new(9, 1.5), rotation = 45 },
        { center = Vector2.new(10.75, 13), size = Vector2.new(5, 1.5), rotation = 0 },
        { center = Vector2.new(13, 10.75), size = Vector2.new(1.5, 5), rotation = 0 },
    }) do
        table.insert(gripLines, Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(stroke.center.X, stroke.center.Y),
            Size = UDim2.fromOffset(stroke.size.X, stroke.size.Y),
            Rotation = stroke.rotation,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            ZIndex = 26,
        }, ResizeGrip), { BackgroundColor3 = "Glyph" }))
    end

    local windowResize
    local function paintGrip(active)
        for _, line in ipairs(gripLines) do
            Tween(line, Motion.Hover, {
                BackgroundColor3 = active and Glass.Accent or Glass.Glyph,
                BackgroundTransparency = active and 0 or 0.35,
            })
        end
    end
    ResizeGrip.MouseEnter:Connect(function() paintGrip(true) end)
    ResizeGrip.MouseLeave:Connect(function()
        if not windowResize then paintGrip(false) end
    end)
    ResizeGrip.InputBegan:Connect(function(input)
        if not isPointer(input) then return end
        windowResize = { start = input.Position, size = Holder.Size, pos = Holder.Position }
        paintGrip(true)
        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState ~= Enum.UserInputState.End then return end
            connection:Disconnect()
            windowResize = nil
            paintGrip(false)
        end)
    end)
    Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
        if not windowResize or not isMove(input) then return end
        local scale = Scale.Scale
        local vp = viewportSize()
        local delta = input.Position - windowResize.start
        local startW, startH = windowResize.size.X.Offset, windowResize.size.Y.Offset
        local w = math.clamp(startW + delta.X / scale, L.MinWindow.X, math.max(L.MinWindow.X, vp.X * L.ViewportFill / scale))
        local h = math.clamp(startH + delta.Y / scale, L.MinWindow.Y, math.max(L.MinWindow.Y, vp.Y * L.ViewportFill / scale))
        -- Anchored at the centre, so shift by half the growth to keep the top-left corner put.
        local p = windowResize.pos
        Holder.Size = UDim2.fromOffset(w, h)
        Holder.Position = UDim2.new(p.X.Scale, p.X.Offset + (w - startW) * scale / 2, p.Y.Scale, p.Y.Offset + (h - startH) * scale / 2)
    end))

    ---------------------------------------------------------------------------------------------------
    -- Window drag: from the sidebar header or any page header. Released near a screen edge, the window
    -- is drawn flush onto it.
    ---------------------------------------------------------------------------------------------------
    local function dockWindow()
        local ss = ScreenGui.AbsoluteSize
        local p = Holder.Position
        local half = Vector2.new(Holder.Size.X.Offset, Holder.Size.Y.Offset) * Scale.Scale / 2
        local center = Vector2.new(p.X.Scale * ss.X + p.X.Offset, p.Y.Scale * ss.Y + p.Y.Offset)
        local top = GuiService:GetGuiInset().Y
        local x, y = center.X, center.Y

        -- Shoved most of the way off the left or right: collapse into the edge rail rather than snapping
        -- back. Nudging it a little past the edge still just docks, so this only fires on a real shove.
        if W.EnterRail and Window.ActiveTab then
            local depth = half.X * 2 * L.RailPushDepth
            if half.X - center.X > depth then
                W.EnterRail("Left")
                return
            elseif (center.X + half.X) - ss.X > depth then
                W.EnterRail("Right")
                return
            end
        end
        if center.X - half.X < L.WindowEdgeMagnet then
            x = half.X + L.WindowMargin
        elseif ss.X - (center.X + half.X) < L.WindowEdgeMagnet then
            x = ss.X - half.X - L.WindowMargin
        end
        if center.Y - half.Y - top < L.WindowEdgeMagnet then
            y = top + L.WindowMargin + half.Y
        elseif ss.Y - (center.Y + half.Y) < L.WindowEdgeMagnet then
            y = ss.Y - half.Y - L.WindowMargin
        end
        if math.abs(x - center.X) > 0.5 or math.abs(y - center.Y) > 0.5 then
            Tween(Holder, Motion.Drop, { Position = UDim2.fromOffset(x, y) })
        end
    end

    function W:BindDrag(handle)
        handle.InputBegan:Connect(function(input)
            if not isPointer(input) then return end
            local start, origin = input.Position, Holder.Position
            local moved = false
            local moveConnection, endConnection
            moveConnection = UserInputService.InputChanged:Connect(function(changed)
                if not isMove(changed) then return end
                local delta = changed.Position - start
                moved = moved or delta.Magnitude > 2
                Holder.Position = UDim2.new(origin.X.Scale, origin.X.Offset + delta.X, origin.Y.Scale, origin.Y.Offset + delta.Y)
            end)
            endConnection = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then return end
                moveConnection:Disconnect()
                endConnection:Disconnect()
                if moved then dockWindow() end
            end)
        end)
    end
    BrandHeader.Active = true
    W:BindDrag(BrandHeader)

    ---------------------------------------------------------------------------------------------------
    -- Header buttons: minimise, and the theme gallery next to it
    ---------------------------------------------------------------------------------------------------
    local MinimizeButton = HeaderButton(Main, "Minimize", -14)
    local MinimizeBar = Themed(New("Frame", {
        Name = "Bar",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(11, 2),
        BorderSizePixel = 0,
        ZIndex = 21,
    }, MinimizeButton), { BackgroundColor3 = "TextPrimary" })
    Corner(MinimizeBar, 1)
    MinimizeButton.MouseEnter:Connect(function() Tween(MinimizeBar, Motion.Hover, { Size = UDim2.fromOffset(13, 2) }) end)
    MinimizeButton.MouseLeave:Connect(function() Tween(MinimizeBar, Motion.Hover, { Size = UDim2.fromOffset(11, 2) }) end)
    MinimizeButton.MouseButton1Click:Connect(function() Library:Toggle(false) end)

    local ThemeButton = HeaderButton(Main, "Themes", -14 - L.HeaderButton - 6)
    for i = 1, 4 do
        local column, row = (i - 1) % 2, math.floor((i - 1) / 2)
        local dot = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, column == 0 and -3.5 or 3.5, 0.5, row == 0 and -3.5 or 3.5),
            Size = UDim2.fromOffset(5, 5),
            BackgroundColor3 = Themes[ThemeOrder[i]].Accent,
            BorderSizePixel = 0,
            ZIndex = 21,
        }, ThemeButton)
        Corner(dot, 3)
    end

    local themeTiles = {}
    local function openThemeGallery()
        local rows = math.ceil(#ThemeOrder / 2)
        local width = 12 * 2 + THEME_TILE_WIDTH * 2 + THEME_TILE_GAP
        local height = 12 + 18 + 10 + rows * THEME_TILE_HEIGHT + (rows - 1) * THEME_TILE_GAP + 12
        local panel = New("Frame", { Name = "ThemeGallery", Size = UDim2.fromOffset(width, 0), ClipsDescendants = true }, nil)
        PopupMaterial(panel, 12, 40)
        W:PlacePopup(panel, ThemeButton, 8, height)
        Themed(Text(panel, {
            Text = "Themes",
            TextSize = 12,
            Position = UDim2.fromOffset(14, 12),
            Size = UDim2.new(1, -28, 0, 18),
            ZIndex = 2,
        }), { TextColor3 = "TextPrimary" })

        table.clear(themeTiles)
        for i, name in ipairs(ThemeOrder) do
            local theme = Themes[name]
            local column, row = (i - 1) % 2, math.floor((i - 1) / 2)
            local tile = New("TextButton", {
                Name = name,
                Text = "",
                AutoButtonColor = false,
                Position = UDim2.fromOffset(12 + column * (THEME_TILE_WIDTH + THEME_TILE_GAP), 40 + row * (THEME_TILE_HEIGHT + THEME_TILE_GAP)),
                Size = UDim2.fromOffset(THEME_TILE_WIDTH, THEME_TILE_HEIGHT),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 2,
            }, panel)
            Corner(tile, 9)
            New("UIGradient", {
                Rotation = 115,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, theme.PaneTop),
                    ColorSequenceKeypoint.new(0.5, theme.PaneMid),
                    ColorSequenceKeypoint.new(1, theme.PaneBottom),
                }),
            }, tile)
            local ring = Themed(New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Thickness = Library.Theme == name and 2 or 1,
            }, tile), {
                Color = function() return Library.Theme == name and Glass.Accent or theme.Rim end,
                Transparency = function() return Library.Theme == name and 0 or 0.55 end,
            })
            -- A miniature of the theme: a lens bar and an accent bead, as they'd appear in the sidebar.
            local lens = New("Frame", {
                Position = UDim2.fromOffset(8, 8),
                Size = UDim2.new(0.62, 0, 0, 10),
                BackgroundColor3 = theme.LensTint,
                BackgroundTransparency = 0.8,
                BorderSizePixel = 0,
                ZIndex = 3,
            }, tile)
            Corner(lens, 4)
            New("UIStroke", { Color = theme.Rim, Transparency = 0.5, Thickness = 1 }, lens)
            local bead = New("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -8, 0, 9),
                Size = UDim2.fromOffset(8, 8),
                BackgroundColor3 = theme.Accent,
                BorderSizePixel = 0,
                ZIndex = 3,
            }, tile)
            Corner(bead, 4)
            Text(tile, {
                Text = name,
                TextSize = 11,
                TextColor3 = theme.TextPrimary,
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 8, 1, -6),
                Size = UDim2.new(1, -16, 0, 14),
                ZIndex = 3,
            })
            local tileScale = New("UIScale", { Scale = 1 }, tile)
            tile.MouseEnter:Connect(function() Tween(tileScale, Motion.Pop, { Scale = 1.04 }) end)
            tile.MouseLeave:Connect(function() Tween(tileScale, Motion.Pop, { Scale = 1 }) end)
            tile.MouseButton1Click:Connect(function() Library:SetTheme(name) end)
            themeTiles[name] = ring
        end

        W:OpenPopup(panel, function()
            table.clear(themeTiles)
            Tween(panel, Motion.FadeOut, { Size = UDim2.fromOffset(width, 0) })
            task.delay(Motion.FadeOut.Time, function() panel:Destroy() end)
        end)
        Tween(panel, Motion.Reveal, { Size = UDim2.fromOffset(width, height) })
    end
    ThemeButton.MouseButton1Click:Connect(openThemeGallery)

    -- Palette button: opens the gradient editor directly, seeded from the current accent.
    local PaletteButton = HeaderButton(Main, "Palette", -14 - (L.HeaderButton + 6) * 2)
    PaletteGlyph(PaletteButton, 18, 21)
    local function themeStops()
        return { { color = Glass.AccentDeep, position = 0 }, { color = Glass.Accent, position = 1 } }
    end
    PaletteButton.MouseButton1Click:Connect(function()
        local stops = Library.AccentGradient and sequenceToStops(Library.AccentGradient) or themeStops()
        openPaletteEditor(W, PaletteButton, stops,
            function(sequence) Library:SetAccentGradient(sequence) end,
            function() Library:SetAccentGradient(nil) return themeStops() end)
    end)

    -- Cursor button: six drawn pointers plus the system default.
    local CursorButton = HeaderButton(Main, "Cursor", -14 - (L.HeaderButton + 6) * 4)
    local cursorGlyphA = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(3, 13),
        Rotation = 26,
        BorderSizePixel = 0,
        ZIndex = 21,
    }, CursorButton), { BackgroundColor3 = "TextPrimary" })
    Corner(cursorGlyphA, 2)
    local cursorGlyphB = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 3, 0.5, 4),
        Size = UDim2.fromOffset(4, 4),
        BorderSizePixel = 0,
        ZIndex = 22,
    }, CursorButton), { BackgroundColor3 = "Accent" })
    Corner(cursorGlyphB, 2)
    CursorButton.MouseButton1Click:Connect(function()
        if W.OpenCursors then W.OpenCursors(CursorButton) end
    end)

    -- Attachments button: the launcher for the info pods. Nothing is deployed until it's picked here.
    local AttachButton = HeaderButton(Main, "Attachments", -14 - (L.HeaderButton + 6) * 3)
    AttachButton.Visible = info.Satellites ~= false
    for i = 0, 2 do
        local bar = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0.5, -7 + i * 5),
            Size = UDim2.fromOffset(if i == 1 then 9 else 13, 3),
            BorderSizePixel = 0,
            ZIndex = 21,
        }, AttachButton), { BackgroundColor3 = "TextPrimary" })
        Corner(bar, 1)
    end
    AttachButton.MouseButton1Click:Connect(function()
        if W.OpenAttachments then W.OpenAttachments(AttachButton) end
    end)

    function W:OnThemeChanged()
        for name, ring in pairs(themeTiles) do
            ring.Thickness = Library.Theme == name and 2 or 1
        end
    end

    ---------------------------------------------------------------------------------------------------
    -- Keybind list, blur and scale
    ---------------------------------------------------------------------------------------------------
    self.KeybindFrame = BuildKeybindFrame(ScreenGui)

    local Blur
    if info.Blur then
        -- Low glass quality turns the blur off: a full-screen blur is one of the costliest things the
        -- interface asks of the device.
        Blur = New("BlurEffect", { Name = "FishyUIBlur", Size = 0, Enabled = qualityRank() >= 2 }, Lighting)
    end
    W.Blur = Blur

    function W:FitScale()
        local vp = viewportSize()
        local s = Holder.Size
        local fit = math.min(1, vp.X * L.ViewportFill / s.X.Offset, vp.Y * L.ViewportFill / s.Y.Offset)
        return math.max(0.4, fit) * Library.DPIScale
    end

    function Window:_rescale()
        Scale.Scale = W:FitScale()
    end

    Telemetry.Start()
    BuildTabs(W)
    BuildBubble(W)
    if info.Satellites then BuildSatellites(W) end
    BuildAmbient(W) -- wraps W.OnThemeChanged, so it has to come after that is defined
    BuildCursor(W)
    BuildRail(W)

    local camera = Workspace.CurrentCamera
    if camera then
        Library:GiveSignal(camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            Window:_rescale()
            if W.OnViewportChanged then W.OnViewportChanged() end
        end))
    end

    Library:GiveSignal(UserInputService.InputBegan:Connect(function(input)
        if UserInputService:GetFocusedTextBox() then return end
        local key = resolveKeyCode(Library.ToggleKeybind)
        if key and input.KeyCode == key then Library:Toggle() end
    end))

    ---------------------------------------------------------------------------------------------------
    -- Public window API
    ---------------------------------------------------------------------------------------------------
    function Window:SetCornerRadius(radius)
        Library.CornerRadius = radius
        ReshapePane(MainPane, radius)
        SheenCorner.CornerRadius = UDim.new(0, radius)
        GlareCorner.CornerRadius = UDim.new(0, radius)
        -- The ambient layer clips its particles to this same corner.
        if W.AmbientCorner then W.AmbientCorner.CornerRadius = UDim.new(0, radius) end
    end

    function Window:SetFooter(text)
        FooterLabel.Text = text
    end

    function Window:SetTitle(text)
        TitleLabel.Text = text
    end

    function Window:SetAlwaysOnTop(value)
        Window.AlwaysOnTop = value
        ScreenGui.DisplayOrder = value and 1000 or 100
    end

    Window._W = W
    Window.Holder = Holder
    Window.Main = Main

    function Window:ShowSetup(callback)
        BuildSetupFlow(W, callback or function() Library:Toggle(true) end)
    end

    if info.AutoShow then
        if info.ThemeSelect == false then
            Library:Toggle(true)
        else
            -- The flow skips any step already dismissed with "Don't show this again", and opens the
            -- window immediately once every step has been.
            BuildSetupFlow(W, function() Library:Toggle(true) end)
        end
    end
    return Window
end
