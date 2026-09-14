-------------------------------------------------------------------------------------------------------
-- KeyPicker: a glass keycap that sits on a label or toggle. It dips when the bind fires, breathes
-- accent light while it's listening for a new key, and right-click opens its mode (Toggle/Hold/Always).
-- Active binds are listed in Library.KeybindFrame.
-------------------------------------------------------------------------------------------------------
local KeybindEntries = {}
local MOUSE_BIND_NAMES = {
    [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2",
    [Enum.UserInputType.MouseButton3] = "MB3",
}

local function inputBindName(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then return input.KeyCode.Name end
    return MOUSE_BIND_NAMES[input.UserInputType]
end

function Library:UpdateKeybindFrame()
    local frame = self.KeybindFrame
    if not frame or not frame:FindFirstChild("Rows") then return end
    local rows = frame.Rows
    for _, child in ipairs(rows:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    local order = 0
    for _, picker in ipairs(KeybindEntries) do
        if not picker.NoUI and picker.Value ~= "None" then
            order += 1
            local active = picker:GetState()
            local row = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20),
                LayoutOrder = order,
            }, rows)
            New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.fromOffset(6, 6),
                BackgroundColor3 = active and Glass.Accent or Glass.Glyph,
                BackgroundTransparency = active and 0 or 0.6,
                BorderSizePixel = 0,
            }, row).Name = "State"
            Corner(row.State, 3)
            Text(row, {
                Text = string.format("[%s]  %s", keyDisplayName(picker.Value), picker.Text),
                FontFace = FONT_MEDIUM,
                TextSize = 12,
                TextColor3 = active and Glass.TextPrimary or Glass.TextSecondary,
                Position = UDim2.fromOffset(14, 0),
                Size = UDim2.new(1, -60, 1, 0),
            })
            Text(row, {
                Text = picker.Mode,
                FontFace = FONT_MEDIUM,
                TextSize = 11,
                TextColor3 = Glass.TextMuted,
                TextXAlignment = Enum.TextXAlignment.Right,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.new(0, 50, 1, 0),
            })
        end
    end
end

local function BuildKeybindFrame(screenGui)
    local frame = New("Frame", {
        Name = "Keybinds",
        Position = UDim2.new(0, 16, 0.4, 0),
        Size = UDim2.fromOffset(210, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 150,
    }, screenGui)
    PopupMaterial(frame, 12, 20)
    New("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
    }, frame)
    stackLayout(frame, 6)
    local title = Themed(Text(frame, {
        Text = "Keybinds",
        TextSize = 12,
        Size = UDim2.new(1, 0, 0, 18),
        LayoutOrder = 1,
    }), { TextColor3 = "TextPrimary" })
    title.Active = true
    local rows = New("Frame", {
        Name = "Rows",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2,
    }, frame)
    stackLayout(rows, 2)

    -- Drag by the title.
    title.InputBegan:Connect(function(input)
        if not isPointer(input) then return end
        local start, origin = input.Position, frame.Position
        local moveConnection, endConnection
        moveConnection = UserInputService.InputChanged:Connect(function(changed)
            if not isMove(changed) then return end
            local delta = changed.Position - start
            frame.Position = UDim2.new(origin.X.Scale, origin.X.Offset + delta.X, origin.Y.Scale, origin.Y.Offset + delta.Y)
        end)
        endConnection = input.Changed:Connect(function()
            if input.UserInputState ~= Enum.UserInputState.End then return end
            moveConnection:Disconnect()
            endConnection:Disconnect()
        end)
    end)
    return frame
end

Elements.KeyPicker = function(container, accessories, parent, idx, info)
    info = info or {}
    local W = container.W
    local default = info.Default
    if typeof(default) == "EnumItem" then default = default.Name end
    local KeyPicker = {
        Type = "KeyPicker",
        Value = default or "None",
        Mode = info.Mode or "Toggle",
        Modes = info.Modes or { "Always", "Toggle", "Hold" },
        Text = info.Text or (parent and parent.Text) or tostring(idx),
        NoUI = info.NoUI == true,
        SyncToggleState = info.SyncToggleState == true,
        Callback = info.Callback,
        ChangedCallback = info.ChangedCallback,
        Toggled = false,
        Changed = nil,
        Clicked = nil,
    }

    local cap = New("TextButton", {
        Name = "Keycap",
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(34, 22),
        LayoutOrder = 500,
        ZIndex = 4,
    }, accessories)
    local base = Themed(New("Frame", {
        Name = "Depth",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        ZIndex = 4,
    }, cap), { BackgroundColor3 = "Shadow" })
    Corner(base, 6)
    local face = Themed(New("Frame", {
        Name = "Face",
        Size = UDim2.new(1, 0, 1, -3),
        BackgroundTransparency = 0.84,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, cap), { BackgroundColor3 = "LensTint" })
    Corner(face, 6)
    New("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.5),
        }),
    }, face)
    local faceStroke = Themed(New("UIStroke", { Thickness = 1, Transparency = 0.55 }, face), { Color = "Rim" })
    local capLabel = Themed(Text(face, {
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.None,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 6,
    }), { TextColor3 = "TextPrimary" })

    local listening, listenStart = false, 0
    local function showKey(text)
        capLabel.Text = text
        cap.Size = UDim2.fromOffset(math.max(34, textWidth(text, 11, Enum.Font.GothamBold) + 16), 22)
    end

    local function tap()
        Tween(face, Motion.Press, { Position = UDim2.fromOffset(0, 2) })
        task.delay(0.1, function() Tween(face, Motion.Pop, { Position = UDim2.fromOffset(0, 0) }) end)
    end

    function KeyPicker:GetState()
        if KeyPicker.Mode == "Always" then return true end
        if KeyPicker.SyncToggleState and parent and parent.Type == "Toggle" then return parent.Value end
        return KeyPicker.Toggled
    end

    local function fire(state)
        KeyPicker.Toggled = state
        if KeyPicker.SyncToggleState and parent and parent.Type == "Toggle" and parent.Value ~= state then
            parent:SetValue(state)
        end
        tap()
        Library:SafeCallback(KeyPicker.Callback, state)
        Library:SafeCallback(KeyPicker.Clicked, state)
        Library:UpdateKeybindFrame()
    end

    function KeyPicker:SetValue(data)
        local key, mode = data, nil
        if typeof(data) == "table" then key, mode = data[1], data[2] end
        if typeof(key) == "EnumItem" then key = key.Name end
        KeyPicker.Value = key or "None"
        if mode and table.find(KeyPicker.Modes, mode) then KeyPicker.Mode = mode end
        showKey(keyDisplayName(KeyPicker.Value))
        Library:SafeCallback(KeyPicker.ChangedCallback, KeyPicker.Value)
        Library:SafeCallback(KeyPicker.Changed, KeyPicker.Value)
        Library:UpdateKeybindFrame()
    end

    function KeyPicker:OnClick(callback) KeyPicker.Clicked = callback end
    function KeyPicker:OnChanged(callback) KeyPicker.Changed = callback end

    -- Listening: the rim breathes until a key or mouse button arrives. Escape cancels, Backspace clears.
    local breathe
    local function stopListening()
        listening = false
        if breathe then breathe:Cancel() end
        faceStroke.Transparency = 0.55
        faceStroke.Color = Glass.Rim
        showKey(keyDisplayName(KeyPicker.Value))
    end
    cap.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        listenStart = os.clock()
        showKey("...")
        faceStroke.Color = Glass.Accent
        breathe = TweenService:Create(faceStroke, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.05 })
        breathe:Play()
    end)

    -- Mode menu
    cap.MouseButton2Click:Connect(function()
        local width, rowHeight = 110, 26
        local height = 8 + #KeyPicker.Modes * rowHeight
        local panel = New("Frame", { Name = "ModeMenu", Size = UDim2.fromOffset(width, 0), ClipsDescendants = true }, nil)
        PopupMaterial(panel, 9, 30)
        W:PlacePopup(panel, cap, 6, height)
        for i, mode in ipairs(KeyPicker.Modes) do
            local item = New("TextButton", {
                Text = "",
                AutoButtonColor = false,
                BackgroundColor3 = Glass.LensTint,
                BackgroundTransparency = mode == KeyPicker.Mode and 0.86 or 1,
                Position = UDim2.fromOffset(4, 4 + (i - 1) * rowHeight),
                Size = UDim2.new(1, -8, 0, rowHeight),
                ZIndex = 2,
            }, panel)
            Corner(item, 6)
            Text(item, {
                Text = mode,
                FontFace = FONT_MEDIUM,
                TextSize = 12,
                TextColor3 = mode == KeyPicker.Mode and Glass.TextPrimary or Glass.TextSecondary,
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -20, 1, 0),
                ZIndex = 3,
            })
            item.MouseButton1Click:Connect(function()
                KeyPicker.Mode = mode
                KeyPicker.Toggled = false
                Library:UpdateKeybindFrame()
                W:ClosePopup()
            end)
        end
        W:OpenPopup(panel, function()
            Tween(panel, Motion.FadeOut, { Size = UDim2.fromOffset(width, 0) })
            task.delay(Motion.FadeOut.Time, function() panel:Destroy() end)
        end)
        Tween(panel, Motion.Reveal, { Size = UDim2.fromOffset(width, height) })
    end)

    Library:GiveSignal(UserInputService.InputBegan:Connect(function(input)
        local name = inputBindName(input)
        if not name then return end
        if listening then
            -- Left click is how the keycap was opened, so the opening click itself must be ignored, or
            -- every click in the UI would fire this keybind. A later left click means the user clicked
            -- away, which cancels instead of leaving the cap stuck on "..." forever. MB2/MB3 still bind.
            if name == "MB1" then
                if os.clock() - listenStart > 0.25 then stopListening() end
                return
            end
            if name == "Escape" then
                stopListening()
            elseif name == "Backspace" then
                stopListening()
                KeyPicker:SetValue({ "None", KeyPicker.Mode })
            else
                stopListening()
                KeyPicker:SetValue({ name, KeyPicker.Mode })
            end
            return
        end
        if UserInputService:GetFocusedTextBox() or name ~= KeyPicker.Value then return end
        if KeyPicker.Mode == "Toggle" then
            fire(not KeyPicker:GetState())
        elseif KeyPicker.Mode == "Hold" then
            fire(true)
        end
    end))
    Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
        if listening or KeyPicker.Mode ~= "Hold" then return end
        if inputBindName(input) == KeyPicker.Value then fire(false) end
    end))

    showKey(keyDisplayName(KeyPicker.Value))
    table.insert(KeybindEntries, KeyPicker)
    Library:UpdateKeybindFrame()
    if idx then Library.Options[idx] = KeyPicker end
    return KeyPicker
end
