-------------------------------------------------------------------------------------------------------
-- Setup flow: language, then theme, then font — shown before the window opens.
--
-- Every step carries a "Don't show this again" box; ticking it and continuing means that step is skipped
-- on later runs, so a returning user drops straight into the interface. A factory reset clears the lot
-- and brings the whole flow back.
-------------------------------------------------------------------------------------------------------
local SETUP_CARD_W, SETUP_CARD_H, SETUP_GAP = 148, 92, 14
local SETUP_COLUMNS = 5

-- A miniature of a theme: pane wash, sidebar rail with tab pills, accent bar and bead.
local function themeMock(parent, theme, width, height)
    local mock = New("Frame", {
        Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 503,
    }, parent)
    Corner(mock, 12)
    New("UIGradient", {
        Rotation = 115,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, theme.PaneTop),
            ColorSequenceKeypoint.new(0.5, theme.PaneMid),
            ColorSequenceKeypoint.new(1, theme.PaneBottom),
        }),
    }, mock)
    local ring = New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = theme.Rim, Thickness = 1, Transparency = 0.6 }, mock)
    New("ImageLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Image = Assets.GlassEdge,
        ImageColor3 = theme.Rim,
        ImageTransparency = math.min(1, theme.EdgeTransparency),
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(50, 50, 78, 78),
        SliceScale = 12 / 18,
        ZIndex = 505,
    }, mock)
    for t = 0, 2 do
        local pill = New("Frame", {
            Position = UDim2.fromOffset(12, 14 + t * 16),
            Size = UDim2.fromOffset(46, 9),
            BackgroundColor3 = t == 0 and theme.LensTint or theme.Glyph,
            BackgroundTransparency = t == 0 and 0.55 or 0.7,
            BorderSizePixel = 0,
            ZIndex = 504,
        }, mock)
        Corner(pill, 4)
        if t == 0 then New("UIStroke", { Color = theme.Rim, Transparency = 0.4, Thickness = 1 }, pill) end
    end
    New("Frame", { Position = UDim2.fromOffset(70, 12), Size = UDim2.fromOffset(1, height - 24), BackgroundColor3 = theme.Rim, BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 504 }, mock)
    local bar = New("Frame", { Position = UDim2.fromOffset(82, 16), Size = UDim2.fromOffset(width - 96, 10), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 504 }, mock)
    Corner(bar, 5)
    New("UIGradient", { Color = ColorSequence.new(theme.AccentDeep, theme.Accent) }, bar)
    local bead = New("Frame", { Position = UDim2.fromOffset(82, 34), Size = UDim2.fromOffset(10, 10), BackgroundColor3 = theme.Accent, BorderSizePixel = 0, ZIndex = 504 }, mock)
    Corner(bead, 5)
    return mock, ring
end

BuildSetupFlow = function(W, onDone)
    local ScreenGui = W.ScreenGui

    -- Only the steps that haven't been dismissed.
    local steps = {}
    if not Prefs.SkipLanguage then table.insert(steps, "language") end
    if not Prefs.SkipTheme then table.insert(steps, "theme") end
    if not Prefs.SkipFont then table.insert(steps, "font") end
    if #steps == 0 then
        if onDone then onDone() end
        return
    end

    local rows = math.ceil(#ThemeOrder / SETUP_COLUMNS)
    local gridW = SETUP_COLUMNS * SETUP_CARD_W + (SETUP_COLUMNS - 1) * SETUP_GAP
    local designW = gridW + 72
    local designH = 104 + rows * (SETUP_CARD_H + 22 + SETUP_GAP) + 16 + 52 + 34

    if W.Blur then Tween(W.Blur, Motion.Blur, { Size = W.Info.BlurSize }) end

    local overlay = New("Frame", {
        Name = "Setup",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 500,
    }, ScreenGui)
    Tween(overlay, Motion.FadeIn, { BackgroundTransparency = 0.35 })

    local panel = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(designW, designH),
        ZIndex = 501,
    }, overlay)
    local panelScale = New("UIScale", { Scale = 1 }, panel)
    GlassShadow(panel, 40, "ShadowTransparency", 500)
    PopupMaterial(panel, 20, 560)

    local function fitScale()
        local vp = viewportSize()
        return math.min(1, vp.X * 0.92 / designW, vp.Y * 0.92 / designH)
    end
    panelScale.Scale = fitScale() * 0.96
    Tween(panelScale, Motion.Expand, { Scale = fitScale() })
    W.OnSetupViewport = function() panelScale.Scale = fitScale() end

    local title = Themed(Text(panel, {
        Text = "",
        TextSize = 22,
        TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.fromOffset(0, 30),
        Size = UDim2.new(1, 0, 0, 28),
        ZIndex = 502,
    }), { TextColor3 = "TextPrimary" })
    local subtitle = Themed(Text(panel, {
        Text = "",
        FontFace = FONT_MEDIUM,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.fromOffset(0, 60),
        Size = UDim2.new(1, 0, 0, 18),
        ZIndex = 502,
    }), { TextColor3 = "TextMuted" })

    -- Step dots
    local dots = {}
    local dotRow = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(designW / 2, 84),
        Size = UDim2.fromOffset(#steps * 18, 8),
        ZIndex = 502,
    }, panel)
    for i = 1, #steps do
        local dot = Themed(New("Frame", {
            Position = UDim2.fromOffset((i - 1) * 18, 0),
            Size = UDim2.fromOffset(8, 8),
            BorderSizePixel = 0,
            ZIndex = 502,
        }, dotRow), { BackgroundColor3 = "Accent" })
        Corner(dot, 4)
        dots[i] = dot
    end

    local content = New("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.fromOffset(designW / 2, 104),
        Size = UDim2.fromOffset(gridW, designH - 104 - 86),
        ZIndex = 502,
    }, panel)

    -- "Don't show this again"
    local skipBox = New("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(36, designH - 62),
        Size = UDim2.fromOffset(260, 26),
        ZIndex = 502,
    }, panel)
    local skipMark = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        ZIndex = 503,
    }, skipBox)
    FieldMaterial(skipMark, 5)
    local skipFill = Themed(New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 504,
    }, skipMark), { BackgroundColor3 = "Accent" })
    Corner(skipFill, 5)
    local _, skipCheck = CheckGlyph(skipMark, 505)
    local skipLabel = Themed(Text(skipBox, {
        Text = "",
        FontFace = FONT_MEDIUM,
        TextSize = 12,
        Position = UDim2.fromOffset(26, 0),
        Size = UDim2.new(1, -26, 1, 0),
        ZIndex = 503,
    }), { TextColor3 = "TextMuted" })

    local skipChecked = false
    skipBox.MouseButton1Click:Connect(function()
        skipChecked = not skipChecked
        Tween(skipFill, Motion.Hover, { BackgroundTransparency = skipChecked and 0 or 1 })
        skipCheck(skipChecked)
    end)

    local continueButton = New("TextButton", {
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromOffset(designW - 36, designH - 68),
        Size = UDim2.fromOffset(190, 42),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 502,
    }, panel)
    Corner(continueButton, 12)
    Themed(New("UIGradient", { Rotation = 25 }, continueButton), { Color = accentSequence })
    Themed(New("UIStroke", { Thickness = 1, Transparency = 0.5 }, continueButton), { Color = "Rim" })
    local continueScale = New("UIScale", { Scale = 1 }, continueButton)
    local continueLabel = Themed(Text(continueButton, {
        Text = "",
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 503,
    }), { TextColor3 = "Knob" })
    continueButton.MouseEnter:Connect(function() Tween(continueScale, Motion.Pop, { Scale = 1.03 }) end)
    continueButton.MouseLeave:Connect(function() Tween(continueScale, Motion.Pop, { Scale = 1 }) end)

    ---------------------------------------------------------------------------------------------------
    -- Steps
    ---------------------------------------------------------------------------------------------------
    local index = 1
    local refreshLabels

    local function clearContent()
        for _, child in ipairs(content:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
    end

    local function selectable(x, y, width, height, onClick)
        local card = New("TextButton", {
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(width, height),
            ZIndex = 502,
        }, content)
        local scale = New("UIScale", { Scale = 1 }, card)
        card.MouseEnter:Connect(function() Tween(scale, Motion.Pop, { Scale = 1.04 }) end)
        card.MouseLeave:Connect(function() Tween(scale, Motion.Pop, { Scale = 1 }) end)
        card.MouseButton1Click:Connect(onClick)
        return card
    end

    local function buildLanguage()
        local rings = {}
        local cardW, cardH = 148, 68
        local function paint()
            for code, ring in pairs(rings) do
                local on = Library.Language == code
                Tween(ring, Motion.Hover, { Thickness = on and 2 or 1, Transparency = on and 0 or 0.6 })
            end
        end
        for i, entry in ipairs(Languages) do
            local column, row = (i - 1) % SETUP_COLUMNS, math.floor((i - 1) / SETUP_COLUMNS)
            local card = selectable(column * (cardW + SETUP_GAP), row * (cardH + SETUP_GAP + 8), cardW, cardH, function()
                Library:SetLanguage(entry.Code)
                paint()
                refreshLabels()
            end)
            local plate = Themed(New("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 0.88,
                BorderSizePixel = 0,
                ZIndex = 503,
            }, card), { BackgroundColor3 = "LensTint" })
            Corner(plate, 12)
            rings[entry.Code] = Themed(New("UIStroke", { Thickness = 1, Transparency = 0.6 }, plate), { Color = "Accent" })
            Themed(Text(plate, {
                Text = entry.Native,
                TextSize = 15,
                TextXAlignment = Enum.TextXAlignment.Center,
                Position = UDim2.fromOffset(0, 14),
                Size = UDim2.new(1, 0, 0, 20),
                ZIndex = 504,
            }), { TextColor3 = "TextPrimary" })
            Themed(Text(plate, {
                Text = entry.Name,
                FontFace = FONT_MEDIUM,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Center,
                Position = UDim2.fromOffset(0, 36),
                Size = UDim2.new(1, 0, 0, 16),
                ZIndex = 504,
            }), { TextColor3 = "TextMuted" })
        end
        paint()
    end

    local function buildTheme()
        local rings = {}
        local function paint()
            for name, ring in pairs(rings) do
                local on = Library.Theme == name
                Tween(ring, Motion.Hover, { Thickness = on and 2 or 1, Transparency = on and 0 or 0.6 })
            end
        end
        for i, name in ipairs(ThemeOrder) do
            local theme = Themes[name]
            local column, row = (i - 1) % SETUP_COLUMNS, math.floor((i - 1) / SETUP_COLUMNS)
            local card = selectable(column * (SETUP_CARD_W + SETUP_GAP), row * (SETUP_CARD_H + 22 + SETUP_GAP),
                SETUP_CARD_W, SETUP_CARD_H + 22, function()
                    Library:SetTheme(name)
                    paint()
                end)
            local _, ring = themeMock(card, theme, SETUP_CARD_W, SETUP_CARD_H)
            rings[name] = ring
            Themed(Text(card, {
                Text = name,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Center,
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, 18),
                ZIndex = 503,
            }), { TextColor3 = function() return Library.Theme == name and Glass.TextPrimary or Glass.TextSecondary end })
        end
        paint()
    end

    local function buildFont()
        local rings = {}
        local cardW, cardH = 180, 84
        local columns = 4
        local function paint()
            for name, ring in pairs(rings) do
                local on = Library.FontFamily == name
                Tween(ring, Motion.Hover, { Thickness = on and 2 or 1, Transparency = on and 0 or 0.6 })
            end
        end
        for i, entry in ipairs(FontFamilies) do
            local column, row = (i - 1) % columns, math.floor((i - 1) / columns)
            local offsetX = (gridW - (columns * cardW + (columns - 1) * SETUP_GAP)) / 2
            local card = selectable(offsetX + column * (cardW + SETUP_GAP), row * (cardH + SETUP_GAP), cardW, cardH, function()
                Library:SetFontFamily(entry.Name)
                paint()
                refreshLabels()
            end)
            local plate = Themed(New("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 0.88,
                BorderSizePixel = 0,
                ZIndex = 503,
            }, card), { BackgroundColor3 = "LensTint" })
            Corner(plate, 12)
            rings[entry.Name] = Themed(New("UIStroke", { Thickness = 1, Transparency = 0.6 }, plate), { Color = "Accent" })
            local base = Font.fromEnum(entry.Font)
            New("TextLabel", {
                BackgroundTransparency = 1,
                Text = "Aa",
                FontFace = Font.new(base.Family, Enum.FontWeight.Bold),
                TextSize = 28,
                TextColor3 = Glass.TextPrimary,
                Position = UDim2.fromOffset(0, 10),
                Size = UDim2.new(1, 0, 0, 34),
                ZIndex = 504,
            }, plate)
            New("TextLabel", {
                BackgroundTransparency = 1,
                Text = entry.Name,
                FontFace = Font.new(base.Family, Enum.FontWeight.Medium),
                TextSize = 12,
                TextColor3 = Glass.TextMuted,
                Position = UDim2.fromOffset(0, 50),
                Size = UDim2.new(1, 0, 0, 18),
                ZIndex = 504,
            }, plate)
        end
        paint()
    end

    function refreshLabels()
        local step = steps[index]
        title.Text = T("title_" .. step)
        subtitle.Text = T("subtitle")
        continueLabel.Text = T("continue_")
        skipLabel.Text = T("dont_show_again")
        for i, dot in ipairs(dots) do
            dot.BackgroundTransparency = i == index and 0 or 0.65
        end
    end

    local function showStep(newIndex)
        index = newIndex
        clearContent()
        skipChecked = false
        skipFill.BackgroundTransparency = 1
        skipCheck(false, true)
        local step = steps[index]
        if step == "language" then
            buildLanguage()
        elseif step == "theme" then
            buildTheme()
        else
            buildFont()
        end
        refreshLabels()
        content.Position = UDim2.fromOffset(designW / 2, 116)
        Tween(content, Motion.Settle, { Position = UDim2.fromOffset(designW / 2, 104) })
    end

    local closed = false
    local function finish()
        if closed then return end
        closed = true
        W.OnSetupViewport = nil
        savePrefs()
        Tween(panelScale, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Scale = fitScale() * 0.9 })
        Tween(overlay, Motion.FadeOut, { BackgroundTransparency = 1 })
        task.delay(0.28, function()
            overlay:Destroy()
            if onDone then onDone() end
        end)
    end

    continueButton.MouseButton1Click:Connect(function()
        if closed then return end
        local step = steps[index]
        if skipChecked then
            if step == "language" then Prefs.SkipLanguage = true
            elseif step == "theme" then Prefs.SkipTheme = true
            else Prefs.SkipFont = true end
        end
        if index < #steps then
            showStep(index + 1)
        else
            finish()
        end
    end)

    showStep(1)

    local previousViewport = W.OnViewportChanged
    W.OnViewportChanged = function()
        if previousViewport then previousViewport() end
        if W.OnSetupViewport then W.OnSetupViewport() end
    end
end
