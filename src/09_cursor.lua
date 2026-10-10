-------------------------------------------------------------------------------------------------------
-- Cursors: six glass pointers drawn from shapes, plus the system default. The chosen one replaces the
-- Roblox mouse icon and follows it every frame, tinted by the active theme.
-------------------------------------------------------------------------------------------------------
local CURSOR_STYLES = { "Default", "Dot", "Ring", "Halo", "Crosshair", "Diamond", "Beam" }

Prefs.Cursor = "Default"
Library.Cursor = "Default"
Library.CursorStyles = CURSOR_STYLES

-- Each builder draws its shape into `parent` and returns nothing; all shapes are theme-bound.
local function drawCursor(style, parent, zIndex)
    if style == "Dot" then
        local glow = Themed(New("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1,
            Image = Assets.Spark, ImageTransparency = 0.45, ZIndex = zIndex,
        }, parent), { ImageColor3 = "Accent" })
        local dot = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(8, 8), BorderSizePixel = 0, ZIndex = zIndex + 1,
        }, parent), { BackgroundColor3 = "Knob" })
        Corner(dot, 4)
        return glow
    elseif style == "Ring" then
        local ring = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, ZIndex = zIndex,
        }, parent)
        Corner(ring, 8)
        Themed(New("UIStroke", { Thickness = 2, Transparency = 0.05 }, ring), { Color = "Accent" })
    elseif style == "Halo" then
        local ring = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, ZIndex = zIndex,
        }, parent)
        Corner(ring, 10)
        Themed(New("UIStroke", { Thickness = 1.5, Transparency = 0.35 }, ring), { Color = "Rim" })
        local core = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, ZIndex = zIndex + 1,
        }, parent), { BackgroundColor3 = "Accent" })
        Corner(core, 3)
    elseif style == "Crosshair" then
        for _, spec in ipairs({
            { UDim2.fromOffset(2, 8), UDim2.new(0.5, 0, 0.5, -9) },
            { UDim2.fromOffset(2, 8), UDim2.new(0.5, 0, 0.5, 9) },
            { UDim2.fromOffset(8, 2), UDim2.new(0.5, -9, 0.5, 0) },
            { UDim2.fromOffset(8, 2), UDim2.new(0.5, 9, 0.5, 0) },
        }) do
            local bar = Themed(New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = spec[2], Size = spec[1],
                BorderSizePixel = 0, ZIndex = zIndex,
            }, parent), { BackgroundColor3 = "Accent" })
            Corner(bar, 1)
        end
        local centre = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(3, 3), BorderSizePixel = 0, ZIndex = zIndex + 1,
        }, parent), { BackgroundColor3 = "Knob" })
        Corner(centre, 2)
    elseif style == "Diamond" then
        local diamond = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(11, 11), Rotation = 45, BackgroundTransparency = 0.15,
            BorderSizePixel = 0, ZIndex = zIndex,
        }, parent), { BackgroundColor3 = "Accent" })
        Corner(diamond, 2)
        Themed(New("UIStroke", { Thickness = 1, Transparency = 0.3 }, diamond), { Color = "Rim" })
    elseif style == "Beam" then
        local beam = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(3, 20), Rotation = 24, BorderSizePixel = 0, ZIndex = zIndex,
        }, parent), { BackgroundColor3 = "Accent" })
        Corner(beam, 2)
        local tip = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(5, 5), BorderSizePixel = 0, ZIndex = zIndex + 1,
        }, parent), { BackgroundColor3 = "Knob" })
        Corner(tip, 3)
    end
    return nil
end

local function BuildCursor(W)
    local holder = New("Frame", {
        Name = "Cursor",
        Active = false,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(32, 32),
        Visible = false,
        ZIndex = 9000,
    }, W.ScreenGui)
    -- The cursor rides directly under the pointer at the very top of the stack, so it must be completely
    -- transparent to input: anything else and it swallows every click aimed at what is beneath it.
    -- Interactable is the explicit switch and covers descendants too; it is pcall'd because older clients
    -- predate the property, where Active = false on a Frame is already the correct behaviour.
    pcall(function() holder.Interactable = false end)
    local holderScale = New("UIScale", { Scale = 1 }, holder)

    local current = "Default"
    local function rebuild()
        for _, child in ipairs(holder:GetChildren()) do
            if not child:IsA("UIScale") then child:Destroy() end
        end
        if current ~= "Default" then drawCursor(current, holder, 9000) end
        -- Interactable on the holder is meant to cover descendants, but the shapes are rebuilt on every
        -- style change and sit exactly under the pointer, so each one is switched off explicitly too.
        -- A cursor that eats clicks is worse than no cursor at all.
        for _, part in ipairs(holder:GetDescendants()) do
            if part:IsA("GuiObject") then
                part.Active = false
                pcall(function() part.Interactable = false end)
            end
        end
    end

    local function apply(style)
        current = if table.find(CURSOR_STYLES, style) then style else "Default"
        Library.Cursor = current
        Prefs.Cursor = current
        savePrefs()
        rebuild()
        holder.Visible = current ~= "Default"
        pcall(function() UserInputService.MouseIconEnabled = current == "Default" end)
    end
    W.ApplyCursor = apply
    function Library:SetCursor(style)
        apply(style)
        return true
    end

    -- GetMouseLocation excludes the top bar, while this ScreenGui ignores the inset, so add it back.
    -- Most frames the pointer hasn't moved, so the write is skipped unless the spot actually changed.
    local lastX, lastY
    Library:GiveSignal(RunService.Heartbeat:Connect(function()
        if current == "Default" then return end
        local inset = GuiService:GetGuiInset()
        local mouse = UserInputService:GetMouseLocation()
        local x, y = mouse.X + inset.X, mouse.Y + inset.Y
        if x == lastX and y == lastY then return end
        lastX, lastY = x, y
        holder.Position = UDim2.fromOffset(x, y)
    end))
    Library:GiveSignal(UserInputService.InputBegan:Connect(function(input)
        if holder.Visible and input.UserInputType == Enum.UserInputType.MouseButton1 then
            Tween(holderScale, Motion.Press, { Scale = 0.8 })
        end
    end))
    Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
        if holder.Visible and input.UserInputType == Enum.UserInputType.MouseButton1 then
            Tween(holderScale, Motion.Pop, { Scale = 1 })
        end
    end))

    Library:OnUnload(function()
        pcall(function() UserInputService.MouseIconEnabled = true end)
    end)

    apply(Prefs.Cursor or "Default")

    -- The picker, opened from the header.
    function W.OpenCursors(anchor)
        local rowHeight, width = 34, 176
        local height = 12 + #CURSOR_STYLES * (rowHeight + 4) + 6
        local panel = New("Frame", { Name = "CursorPicker", Size = UDim2.fromOffset(width, 0), ClipsDescendants = true }, nil)
        PopupMaterial(panel, 12, 40)
        W:PlacePopup(panel, anchor, 8, height)
        for i, style in ipairs(CURSOR_STYLES) do
            local row = New("TextButton", {
                Name = style, Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
                Position = UDim2.fromOffset(6, 6 + (i - 1) * (rowHeight + 4)),
                Size = UDim2.new(1, -12, 0, rowHeight), ZIndex = 2,
            }, panel)
            local plate = Themed(New("Frame", {
                Size = UDim2.fromScale(1, 1), BackgroundTransparency = if style == current then 0.84 else 0.94,
                BorderSizePixel = 0, ZIndex = 2,
            }, row), { BackgroundColor3 = "LensTint" })
            Corner(plate, 8)
            local preview = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0),
                Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1, ZIndex = 3,
            }, row)
            if style == "Default" then
                Themed(Text(preview, {
                    Text = "A", TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center,
                    Size = UDim2.fromScale(1, 1), ZIndex = 4,
                }), { TextColor3 = "TextMuted" })
            else
                drawCursor(style, preview, 4)
            end
            Themed(Text(row, {
                Text = style, FontFace = FONT_MEDIUM, TextSize = 12,
                Position = UDim2.fromOffset(44, 0), Size = UDim2.new(1, -54, 1, 0), ZIndex = 3,
            }), { TextColor3 = if style == current then "TextPrimary" else "TextSecondary" })
            row.MouseEnter:Connect(function()
                Tween(plate, Motion.Hover, { BackgroundTransparency = 0.84 })
                playSound("Hover")
            end)
            row.MouseLeave:Connect(function()
                if style ~= current then Tween(plate, Motion.Hover, { BackgroundTransparency = 0.94 }) end
            end)
            row.MouseButton1Click:Connect(function()
                apply(style)
                playSound("Press")
                W:ClosePopup()
            end)
        end
        W:OpenPopup(panel, function()
            Tween(panel, Motion.FadeOut, { Size = UDim2.fromOffset(width, 0) })
            task.delay(Motion.FadeOut.Time, function() panel:Destroy() end)
        end)
        Tween(panel, Motion.Reveal, { Size = UDim2.fromOffset(width, height) })
    end
end
