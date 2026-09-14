-------------------------------------------------------------------------------------------------------
-- Input: an etched glass field. Focusing it draws a line of accent light out from the centre along the
-- bottom lip and brightens the rim; a numeric field that's handed a letter shakes it off.
-------------------------------------------------------------------------------------------------------
function Container:AddInput(idx, info)
    info = info or {}
    local W = self.W
    local Input = {
        Type = "Input",
        Value = tostring(info.Default or ""),
        Numeric = info.Numeric == true,
        Finished = info.Finished == true,
        MaxLength = info.MaxLength,
        Text = info.Text,
        Disabled = info.Disabled == true,
        Tooltip = info.Tooltip,
        Callback = info.Callback,
        Changed = nil,
    }

    local holder = New("Frame", {
        Name = "Input",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, Input.Text and 56 or 34),
        LayoutOrder = self:NextOrder(),
    }, self.Frame)

    local label, counter
    if Input.Text then
        label = Themed(Text(holder, {
            Text = Input.Text,
            FontFace = FONT_MEDIUM,
            TextSize = 13,
            Size = UDim2.new(1, -50, 0, 18),
        }), { TextColor3 = "TextSecondary" })
    end
    if Input.MaxLength then
        counter = Themed(Text(holder, {
            TextSize = 11,
            FontFace = FONT_MEDIUM,
            TextXAlignment = Enum.TextXAlignment.Right,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.fromOffset(50, 18),
        }), { TextColor3 = "TextMuted" })
    end

    local field = New("Frame", {
        Name = "Field",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 34),
        ClipsDescendants = true,
        ZIndex = 2,
    }, holder)
    local fieldStroke = FieldMaterial(field, 9)

    local box = Themed(New("TextBox", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -24, 1, 0),
        Text = Input.Value,
        PlaceholderText = info.Placeholder or "",
        FontFace = FONT_MEDIUM,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ClearTextOnFocus = info.ClearTextOnFocus == true,
        ZIndex = 3,
    }, field), { TextColor3 = "TextPrimary", PlaceholderColor3 = "TextMuted" })

    local focusLine = Themed(New("Frame", {
        Name = "FocusLine",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(0, 0, 0, 2),
        BorderSizePixel = 0,
        ZIndex = 4,
    }, field), { BackgroundColor3 = "Accent" })
    New("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.2, 0),
            NumberSequenceKeypoint.new(0.8, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, focusLine)
    local focusGlow = Themed(New("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.new(0.8, 0, 0, 22),
        BackgroundTransparency = 1,
        Image = Assets.Spark,
        ImageTransparency = 1,
        ZIndex = 3,
    }, field), { ImageColor3 = "Accent" })

    local function updateCounter()
        if counter then counter.Text = string.format("%d/%d", #box.Text, Input.MaxLength) end
    end

    local shakeToken = 0
    local function shake()
        shakeToken += 1
        local token = shakeToken
        for i, offset in ipairs({ -4, 4, -3, 2, 0 }) do
            task.delay((i - 1) * 0.04, function()
                -- Typing several rejected characters quickly starts overlapping shakes; without the
                -- token whichever step lands last wins and the field can be left parked off-centre.
                if token ~= shakeToken then return end
                field.Position = UDim2.new(0, offset, 1, 0)
            end)
        end
    end

    local function commit(text)
        Input.Value = text
        Library:SafeCallback(Input.Callback, text)
        Library:SafeCallback(Input.Changed, text)
        Library:UpdateDependencyBoxes()
    end

    local sanitizing = false
    box:GetPropertyChangedSignal("Text"):Connect(function()
        if sanitizing then return end
        local text = box.Text
        local clean = text
        if Input.Numeric then
            clean = clean:gsub("[^%d%.%-]", "")
        end
        if Input.MaxLength and #clean > Input.MaxLength then
            clean = clean:sub(1, Input.MaxLength)
        end
        if clean ~= text then
            sanitizing = true
            box.Text = clean
            sanitizing = false
            if Input.Numeric then shake() end
        end
        updateCounter()
        if not Input.Finished and clean ~= Input.Value then commit(clean) end
    end)

    box.Focused:Connect(function()
        Tween(focusLine, Motion.Settle, { Size = UDim2.new(1, 0, 0, 2) })
        Tween(focusGlow, Motion.Settle, { ImageTransparency = 0.7 })
        Tween(fieldStroke, Motion.Hover, { Transparency = 0.4 })
    end)
    box.FocusLost:Connect(function(enterPressed)
        Tween(focusLine, Motion.FadeOut, { Size = UDim2.new(0, 0, 0, 2) })
        Tween(focusGlow, Motion.FadeOut, { ImageTransparency = 1 })
        Tween(fieldStroke, Motion.Hover, { Transparency = 0.82 })
        if Input.Finished and enterPressed and box.Text ~= Input.Value then commit(box.Text) end
    end)
    bindTooltip(W, field, function()
        if Input.Disabled and info.DisabledTooltip then return info.DisabledTooltip end
        return Input.Tooltip
    end)

    function Input:SetValue(text)
        text = tostring(text or "")
        sanitizing = true
        box.Text = text
        sanitizing = false
        updateCounter()
        commit(text)
    end

    function Input:OnChanged(callback)
        Input.Changed = callback
    end

    function Input:SetText(text)
        Input.Text = text
        if label then label.Text = text end
    end

    function Input:SetDisabled(disabled)
        Input.Disabled = disabled
        box.TextEditable = not disabled
        box.TextTransparency = disabled and 0.5 or 0
    end

    function Input:SetVisible(visible)
        holder.Visible = visible
    end

    updateCounter()
    Input:SetDisabled(Input.Disabled)
    if info.Visible == false then holder.Visible = false end

    if idx then Library.Options[idx] = Input end
    return Input
end
