-------------------------------------------------------------------------------------------------------
-- Dropdown: an etched field that pours open into a glass drawer. A liquid lens follows the pointer from
-- item to item; single picks carry a bead of light, multi picks draw a check mark. Long lists get a
-- search field.
-------------------------------------------------------------------------------------------------------
local DROPDOWN_ITEM_HEIGHT = 28
local DROPDOWN_MAX_VISIBLE = 7
local DROPDOWN_SEARCH_AFTER = 8

function Container:AddDropdown(idx, info)
    info = info or {}
    local W = self.W
    local Dropdown = {
        Type = "Dropdown",
        Values = info.Values or {},
        Multi = info.Multi == true,
        AllowNull = info.AllowNull == true,
        SpecialType = info.SpecialType,
        Text = info.Text,
        Disabled = info.Disabled == true,
        Tooltip = info.Tooltip,
        Callback = info.Callback,
        Changed = nil,
    }
    Dropdown.Value = Dropdown.Multi and {} or nil

    -- Values may be an array, or a dictionary (key -> display text). Special types list live players/teams.
    local function entries()
        local list = {}
        if Dropdown.SpecialType == "Player" then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= Players.LocalPlayer or info.ExcludeLocalPlayer == false then
                    table.insert(list, { Key = player.Name, Label = player.DisplayName })
                end
            end
        elseif Dropdown.SpecialType == "Team" then
            for _, team in ipairs(service("Teams"):GetTeams()) do
                table.insert(list, { Key = team.Name, Label = team.Name })
            end
        elseif #Dropdown.Values > 0 then
            for _, value in ipairs(Dropdown.Values) do
                table.insert(list, { Key = value, Label = tostring(value) })
            end
        else
            local keys = {}
            for key in pairs(Dropdown.Values) do table.insert(keys, key) end
            table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
            for _, key in ipairs(keys) do
                table.insert(list, { Key = key, Label = tostring(Dropdown.Values[key]) })
            end
        end
        return list
    end

    local holder = New("Frame", {
        Name = "Dropdown",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, Dropdown.Text and 54 or 32),
        LayoutOrder = self:NextOrder(),
    }, self.Frame)

    local label
    if Dropdown.Text then
        label = Themed(Text(holder, {
            Text = Dropdown.Text,
            FontFace = FONT_MEDIUM,
            TextSize = 13,
            Size = UDim2.new(1, 0, 0, 18),
        }), { TextColor3 = "TextSecondary" })
    end

    local field = New("TextButton", {
        Name = "Field",
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 32),
        ZIndex = 2,
    }, holder)
    local fieldStroke = FieldMaterial(field, 9)

    local display = Text(field, {
        Text = "",
        FontFace = FONT_MEDIUM,
        TextSize = 13,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -60, 1, 0),
        ZIndex = 3,
    })
    local countBadge = Themed(New("Frame", {
        Name = "Count",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -30, 0.5, 0),
        Size = UDim2.fromOffset(18, 16),
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 3,
    }, field), { BackgroundColor3 = "Accent" })
    Corner(countBadge, 8)
    local countText = Themed(Text(countBadge, {
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 4,
    }), { TextColor3 = "Knob" })

    local chevron, chevronLines = Chevron(field, 3)
    chevron.Position = UDim2.new(1, -14, 0.5, 0)
    chevron.Rotation = 90
    for _, line in ipairs(chevronLines) do Themed(line, { BackgroundColor3 = "TextSecondary" }) end

    local function isSelected(key)
        if Dropdown.Multi then return Dropdown.Value[key] == true end
        return Dropdown.Value == key
    end

    local function refreshDisplay()
        local names = {}
        for _, entry in ipairs(entries()) do
            if isSelected(entry.Key) then table.insert(names, entry.Label) end
        end
        if #names == 0 then
            display.Text = info.Placeholder or "Select..."
            display.TextColor3 = Glass.TextMuted
        else
            display.Text = table.concat(names, ", ")
            display.TextColor3 = Glass.TextPrimary
        end
        countBadge.Visible = Dropdown.Multi and #names > 1
        countText.Text = tostring(#names)
    end
    Themed(display, { TextColor3 = function()
        return display.Text == (info.Placeholder or "Select...") and Glass.TextMuted or Glass.TextPrimary
    end })

    local function fire()
        refreshDisplay()
        Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
        Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
        Library:UpdateDependencyBoxes()
    end

    -------------------------------------------------------------------------------------------------
    -- Drawer
    -------------------------------------------------------------------------------------------------
    local open = false

    local function openDrawer()
        if open or Dropdown.Disabled then return end
        open = true
        local list = entries()
        local searchable = info.Searchable == true or #list > DROPDOWN_SEARCH_AFTER
        local searchHeight = searchable and 36 or 0
        local width = field.AbsoluteSize.X / W.Scale.Scale
        local listHeight = math.min(#list, DROPDOWN_MAX_VISIBLE) * DROPDOWN_ITEM_HEIGHT
        local height = 10 + searchHeight + math.max(listHeight, DROPDOWN_ITEM_HEIGHT)

        local panel = New("Frame", {
            Name = "DropdownDrawer",
            Size = UDim2.fromOffset(width, 0),
            ClipsDescendants = true,
            ZIndex = 1,
        }, nil)
        PopupMaterial(panel, 10, 40)
        W:PlacePopup(panel, field, 6, height)

        local search
        if searchable then
            local well = New("Frame", {
                Position = UDim2.fromOffset(6, 6),
                Size = UDim2.new(1, -12, 0, 28),
                ZIndex = 2,
            }, panel)
            FieldMaterial(well, 8)
            search = Themed(New("TextBox", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -20, 1, 0),
                Text = "",
                PlaceholderText = "Search",
                FontFace = FONT_MEDIUM,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                ZIndex = 3,
            }, well), { TextColor3 = "TextPrimary", PlaceholderColor3 = "TextMuted" })
        end

        local scroller = New("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, 5 + searchHeight),
            Size = UDim2.new(1, 0, 1, -(10 + searchHeight)),
            CanvasSize = UDim2.new(),
            ScrollBarThickness = 2,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ZIndex = 2,
        }, panel)
        Themed(scroller, { ScrollBarImageColor3 = "Accent" })

        local lensTrack = New("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(6, 0),
            Size = UDim2.new(1, -12, 0, DROPDOWN_ITEM_HEIGHT),
            Visible = false,
            ZIndex = 2,
        }, scroller)
        local lensBody = GlassLens(lensTrack, 7, 2)
        local lens = LiquidMover(lensTrack, lensBody, Springs.ListLens)

        local rows = {}
        local function build(filter)
            for _, row in ipairs(rows) do row:Destroy() end
            table.clear(rows)
            local y = 0
            for _, entry in ipairs(list) do
                if not filter or filter == "" or entry.Label:lower():find(filter:lower(), 1, true) then
                    local rowY = y
                    local item = New("TextButton", {
                        Name = entry.Label,
                        Text = "",
                        AutoButtonColor = false,
                        BackgroundTransparency = 1,
                        Position = UDim2.fromOffset(6, rowY),
                        Size = UDim2.new(1, -12, 0, DROPDOWN_ITEM_HEIGHT),
                        ZIndex = 3,
                    }, scroller)
                    table.insert(rows, item)
                    local itemLabel = Text(item, {
                        Text = entry.Label,
                        FontFace = FONT_MEDIUM,
                        TextSize = 13,
                        Position = UDim2.fromOffset(10, 0),
                        Size = UDim2.new(1, -40, 1, 0),
                        TextColor3 = isSelected(entry.Key) and Glass.TextPrimary or Glass.TextSecondary,
                        ZIndex = 4,
                    })

                    local mark, reveal
                    if Dropdown.Multi then
                        mark = New("Frame", {
                            AnchorPoint = Vector2.new(1, 0.5),
                            Position = UDim2.new(1, -8, 0.5, 0),
                            Size = UDim2.fromOffset(16, 16),
                            ZIndex = 4,
                        }, item)
                        FieldMaterial(mark, 5)
                        local markFill = New("Frame", {
                            Size = UDim2.fromScale(1, 1),
                            BackgroundColor3 = Glass.Accent,
                            BackgroundTransparency = isSelected(entry.Key) and 0 or 1,
                            BorderSizePixel = 0,
                            ZIndex = 5,
                        }, mark)
                        Corner(markFill, 5)
                        local _, draw = CheckGlyph(mark, 6)
                        draw(isSelected(entry.Key), true)
                        reveal = function(on)
                            Tween(markFill, Motion.Hover, { BackgroundTransparency = on and 0 or 1 })
                            draw(on)
                        end
                    else
                        mark = New("Frame", {
                            AnchorPoint = Vector2.new(1, 0.5),
                            Position = UDim2.new(1, -12, 0.5, 0),
                            Size = UDim2.fromOffset(6, 6),
                            BackgroundColor3 = Glass.Accent,
                            BackgroundTransparency = isSelected(entry.Key) and 0 or 1,
                            BorderSizePixel = 0,
                            ZIndex = 4,
                        }, item)
                        Corner(mark, 3)
                        reveal = function(on) Tween(mark, Motion.Hover, { BackgroundTransparency = on and 0 or 1 }) end
                    end

                    item.MouseEnter:Connect(function()
                        lensTrack.Visible = true
                        lens:SetTarget(rowY)
                        if not isSelected(entry.Key) then
                            Tween(itemLabel, Motion.Hover, { TextColor3 = Glass.TextPrimary })
                        end
                    end)
                    item.MouseLeave:Connect(function()
                        if not isSelected(entry.Key) then
                            Tween(itemLabel, Motion.Hover, { TextColor3 = Glass.TextSecondary })
                        end
                    end)
                    item.MouseButton1Click:Connect(function()
                        if Dropdown.Multi then
                            Dropdown.Value[entry.Key] = (not Dropdown.Value[entry.Key]) or nil
                            reveal(isSelected(entry.Key))
                            fire()
                        else
                            if Dropdown.Value == entry.Key and Dropdown.AllowNull then
                                Dropdown.Value = nil
                            else
                                Dropdown.Value = entry.Key
                            end
                            fire()
                            W:ClosePopup()
                        end
                    end)

                    if isSelected(entry.Key) and not lensTrack.Visible then
                        lensTrack.Visible = true
                        lens:SetTarget(rowY)
                        lens:Snap()
                    end
                    y += DROPDOWN_ITEM_HEIGHT
                end
            end
            scroller.CanvasSize = UDim2.fromOffset(0, y)
        end
        build(nil)
        if search then
            search:GetPropertyChangedSignal("Text"):Connect(function()
                lensTrack.Visible = false
                build(search.Text)
            end)
        end

        Tween(fieldStroke, Motion.Hover, { Transparency = 0.35 })
        Tween(chevron, Motion.Settle, { Rotation = -90 })
        W:OpenPopup(panel, function()
            open = false
            Tween(fieldStroke, Motion.Hover, { Transparency = 0.82 })
            Tween(chevron, Motion.Settle, { Rotation = 90 })
            Tween(panel, Motion.FadeOut, { Size = UDim2.fromOffset(width, 0) })
            task.delay(Motion.FadeOut.Time, function() panel:Destroy() end)
        end)
        Tween(panel, Motion.Reveal, { Size = UDim2.fromOffset(width, height) })
    end

    field.MouseButton1Click:Connect(function()
        if open then W:ClosePopup() else openDrawer() end
    end)
    field.MouseEnter:Connect(function()
        if not open then Tween(fieldStroke, Motion.Hover, { Transparency = 0.6 }) end
    end)
    field.MouseLeave:Connect(function()
        if not open then Tween(fieldStroke, Motion.Hover, { Transparency = 0.82 }) end
    end)
    bindTooltip(W, field, function()
        if Dropdown.Disabled and info.DisabledTooltip then return info.DisabledTooltip end
        return Dropdown.Tooltip
    end)

    -------------------------------------------------------------------------------------------------
    -- API
    -------------------------------------------------------------------------------------------------
    function Dropdown:SetValue(value)
        if Dropdown.Multi then
            local selected = {}
            if typeof(value) == "table" then
                for key, flag in pairs(value) do
                    if typeof(key) == "number" then
                        selected[flag] = true
                    elseif flag then
                        selected[key] = true
                    end
                end
            end
            Dropdown.Value = selected
        else
            Dropdown.Value = value
        end
        fire()
    end

    function Dropdown:SetValues(values)
        Dropdown.Values = values or {}
        -- Selections that no longer exist have to go, or the field keeps naming entries that are gone
        -- and GetActiveValues keeps reporting them. An open drawer is closed because its rows were
        -- built from the old list.
        local valid = {}
        for _, entry in ipairs(entries()) do valid[entry.Key] = true end
        if Dropdown.Multi then
            for key in pairs(Dropdown.Value) do
                if not valid[key] then Dropdown.Value[key] = nil end
            end
        elseif Dropdown.Value ~= nil and not valid[Dropdown.Value] then
            Dropdown.Value = nil
        end
        if open then W:ClosePopup() end
        refreshDisplay()
    end

    function Dropdown:GetActiveValues()
        if not Dropdown.Multi then return Dropdown.Value ~= nil and 1 or 0 end
        local active = {}
        for key in pairs(Dropdown.Value) do table.insert(active, key) end
        return active
    end

    function Dropdown:OnChanged(callback)
        Dropdown.Changed = callback
    end

    function Dropdown:SetText(text)
        Dropdown.Text = text
        if label then label.Text = text end
    end

    function Dropdown:SetDisabled(disabled)
        Dropdown.Disabled = disabled
        display.TextTransparency = disabled and 0.5 or 0
    end

    function Dropdown:SetVisible(visible)
        holder.Visible = visible
    end

    -- Defaults: an index into an array, a value, or for multi a set / array of values.
    local default = info.Default
    if Dropdown.Multi then
        if typeof(default) == "table" then
            for key, flag in pairs(default) do
                if typeof(key) == "number" then Dropdown.Value[flag] = true elseif flag then Dropdown.Value[key] = true end
            end
        end
    elseif typeof(default) == "number" and #Dropdown.Values > 0 and Dropdown.Values[default] ~= nil then
        Dropdown.Value = Dropdown.Values[default]
    elseif default ~= nil then
        Dropdown.Value = default
    end

    if Dropdown.SpecialType then
        local function refresh() refreshDisplay() end
        Library:GiveSignal(Players.PlayerAdded:Connect(refresh))
        Library:GiveSignal(Players.PlayerRemoving:Connect(refresh))
    end

    refreshDisplay()
    Dropdown:SetDisabled(Dropdown.Disabled)
    if info.Visible == false then holder.Visible = false end

    if idx then Library.Options[idx] = Dropdown end
    return Dropdown
end
