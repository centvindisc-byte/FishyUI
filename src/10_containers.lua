-------------------------------------------------------------------------------------------------------
-- Containers
--
-- Groupboxes, tabbox tabs and dependency boxes are all containers: a vertical stack of elements. The
-- element builders (Elements.Toggle, Elements.Slider, ...) live in the files that follow this one.
--
-- Every container carries `W`, the window's internal context. Elements use it for:
--   W.Scale                        the window UIScale (absolute sizes divide by W.Scale.Scale)
--   W:OpenPopup(frame, onClose)    show a floating panel above everything; one at a time
--   W:ClosePopup()
--   W:PlacePopup(frame, anchor, gap)  position a popup under an element, flipping above if needed
--   W:ShowTooltip(target, text) / W:HideTooltip(target)
-------------------------------------------------------------------------------------------------------
local Elements = {}
local Container = {}
Container.__index = Container

local function newContainer(W, frame)
    return setmetatable({ W = W, Frame = frame, Order = 0 }, Container)
end

function Container:NextOrder()
    self.Order += 1
    return self.Order
end

local function stackLayout(frame, padding)
    return New("UIListLayout", {
        Padding = UDim.new(0, padding),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    }, frame)
end

local function bindTooltip(W, target, getText)
    target.MouseEnter:Connect(function()
        local text = getText()
        if text and text ~= "" then W:ShowTooltip(target, text) end
    end)
    target.MouseLeave:Connect(function() W:HideTooltip(target) end)
end

-- A row with the label on the left and an accessory strip on the right that keypickers, colour orbs
-- and the element's own control share. The label gives up width as accessories are added.
local function AccessoryRow(container, height)
    local row = New("Frame", {
        Name = "Row",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, height),
        LayoutOrder = container:NextOrder(),
    }, container.Frame)
    local accessories = New("Frame", {
        Name = "Accessories",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromScale(0, 1),
        AutomaticSize = Enum.AutomaticSize.X,
        ZIndex = 3,
    }, row)
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    }, accessories)
    local label = Themed(Text(row, {
        Name = "Label",
        FontFace = FONT_MEDIUM,
        TextSize = 13,
        RichText = true,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2,
    }), { TextColor3 = "TextSecondary" })
    local W = container.W
    local function fit()
        label.Size = UDim2.new(1, -(accessories.AbsoluteSize.X / W.Scale.Scale) - 10, 1, 0)
    end
    accessories:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
    fit()
    return { Row = row, Label = label, Accessories = accessories }
end

local function attachAccessories(element, container, accessories)
    function element:AddKeyPicker(idx, info)
        Elements.KeyPicker(container, accessories, element, idx, info)
        return element
    end
    function element:AddColorPicker(idx, info)
        Elements.ColorPicker(container, accessories, element, idx, info)
        return element
    end
end

-------------------------------------------------------------------------------------------------------
-- Groupbox: a card with a header, a thin line of accent light beneath it, and the element stack.
-------------------------------------------------------------------------------------------------------
local function CardHeader(parent, title, icon)
    local header = New("Frame", {
        Name = "Header",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        LayoutOrder = 1,
    }, parent)
    local image = resolveIcon(icon)
    local textX = 14
    if image then
        Themed(New("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 1,
            Image = image,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 3,
        }, header), { ImageColor3 = "Accent" })
        textX = 22
    else
        local bead = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.fromOffset(4, 12),
            BorderSizePixel = 0,
            ZIndex = 3,
        }, header), { BackgroundColor3 = "Accent" })
        Corner(bead, 2)
    end
    local label = Themed(Text(header, {
        Text = title,
        TextSize = 13,
        Position = UDim2.fromOffset(textX, 0),
        Size = UDim2.new(1, -textX, 1, 0),
        ZIndex = 3,
    }), { TextColor3 = "TextPrimary" })

    local leak = Themed(New("Frame", {
        Name = "LightLeak",
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        LayoutOrder = 2,
    }, parent), { BackgroundColor3 = "Accent" })
    New("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.45, 0.75),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }, leak)
    return header, label
end

-- The card is a bare decorated surface; everything that stacks lives in Body.
--
-- Keeping the layout off the card itself matters: CardMaterial's lensed edge is sized to the whole card,
-- and a UIListLayout on the card would treat that edge as a stacked item. Its height would then feed back
-- into the card's AutomaticSize, growing the card, which grows the edge, and so on until the card settles
-- hundreds of pixels tall with its content stranded inside.
local function newCard(column, name, order)
    local card = New("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = order,
    }, column)
    CardMaterial(card, L.CardRadius)
    local body = New("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, card)
    New("UIPadding", {
        PaddingTop = UDim.new(0, L.CardPadding),
        PaddingBottom = UDim.new(0, L.CardPadding + 2),
        PaddingLeft = UDim.new(0, L.CardPadding),
        PaddingRight = UDim.new(0, L.CardPadding),
    }, body)
    stackLayout(body, 9)
    return card, body
end

local function newGroupbox(W, column, title, icon, order)
    local card, body = newCard(column, "Groupbox_" .. title, order)
    CardHeader(body, title, icon)
    local content = New("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 3,
    }, body)
    stackLayout(content, L.ElementGap)
    local groupbox = newContainer(W, content)
    groupbox.Card = card
    groupbox.Name = title
    return groupbox
end

-------------------------------------------------------------------------------------------------------
-- Tabbox: a card whose header is a segmented glass track; a liquid lens slides between the segments.
-------------------------------------------------------------------------------------------------------
local function newTabbox(W, column, order)
    local card, body = newCard(column, "Tabbox", order)
    local track = New("Frame", {
        Name = "Segments",
        Size = UDim2.new(1, 0, 0, 30),
        LayoutOrder = 1,
    }, body)
    FieldMaterial(track, 9)

    local lensTrack = New("Frame", {
        Name = "Lens",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 3),
        Size = UDim2.new(0, 0, 1, -6),
        ZIndex = 3,
    }, track)
    local lensBody = GlassLens(lensTrack, 7, 3)
    local lens = LiquidMover(lensTrack, lensBody, {
        Axis = "X", Width = 0, Stiffness = 260, Damping = 0.8, MaxStretch = 16, StretchPerSpeed = 0.04,
        Squash = 2, PressX = 0, PressY = 0,
    })

    local tabbox = { Card = card, Tabs = {}, ActiveTab = nil, Name = "Tabbox" }

    local function segmentGeometry(index)
        local inner = track.AbsoluteSize.X / W.Scale.Scale - 6
        local width = inner / math.max(1, #tabbox.Tabs)
        return 3 + (index - 1) * width, width
    end

    local function relayout(instant)
        for i, tab in ipairs(tabbox.Tabs) do
            local x, width = segmentGeometry(i)
            tab.Button.Position = UDim2.fromOffset(x, 0)
            tab.Button.Size = UDim2.new(0, width, 1, 0)
        end
        local active = tabbox.ActiveTab
        if active then
            local x, width = segmentGeometry(table.find(tabbox.Tabs, active))
            lens.length = width
            lens:SetTarget(x)
            if instant then lens:Snap() end
        end
    end
    track:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() relayout(true) end)

    function tabbox:AddTab(name)
        local content = New("Frame", {
            Name = "Tab_" .. name,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 3,
            Visible = false,
        }, body)
        stackLayout(content, L.ElementGap)
        local tab = newContainer(W, content)
        tab.Name = name

        tab.Button = New("TextButton", {
            Name = name,
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            ZIndex = 4,
        }, track)
        tab.Label = Themed(Text(tab.Button, {
            Text = name,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 5,
        }), { TextColor3 = function() return tabbox.ActiveTab == tab and Glass.TextPrimary or Glass.TextMuted end })

        function tab:Show()
            if tabbox.ActiveTab == tab then return end
            tabbox.ActiveTab = tab
            playSound("Tab")
            for _, other in ipairs(tabbox.Tabs) do
                other.Frame.Visible = other == tab
                Tween(other.Label, Motion.Hover, { TextColor3 = other == tab and Glass.TextPrimary or Glass.TextMuted })
            end
            relayout(false)
        end
        tab.Button.MouseButton1Click:Connect(function() tab:Show() end)

        table.insert(tabbox.Tabs, tab)
        if not tabbox.ActiveTab then
            tabbox.ActiveTab = tab
            content.Visible = true
            tab.Label.TextColor3 = Glass.TextPrimary
        end
        relayout(true)
        return tab
    end

    return tabbox
end

-------------------------------------------------------------------------------------------------------
-- Dependency boxes: containers that only show while other elements hold given values.
-------------------------------------------------------------------------------------------------------
function Container:AddDependencyBox()
    local frame = New("Frame", {
        Name = "DependencyBox",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = self:NextOrder(),
    }, self.Frame)
    stackLayout(frame, L.ElementGap)
    local box = newContainer(self.W, frame)
    box.Dependencies = {}

    function box:SetupDependencies(dependencies)
        box.Dependencies = dependencies
        box:Update()
    end

    function box:Update()
        for _, dependency in ipairs(box.Dependencies) do
            local element, expected = dependency[1], dependency[2]
            if element and element.Value ~= expected then
                frame.Visible = false
                return
            end
        end
        frame.Visible = true
    end

    table.insert(Library.DependencyBoxes, box)
    return box
end

function Library:UpdateDependencyBoxes()
    for _, box in ipairs(self.DependencyBoxes) do box:Update() end
end

-------------------------------------------------------------------------------------------------------
-- Label
-------------------------------------------------------------------------------------------------------
function Container:AddLabel(first, second)
    local idx, info
    if typeof(first) == "table" then
        info = first
    elseif typeof(second) == "table" then
        idx, info = first, second
    else
        info = { Text = first, DoesWrap = second }
    end

    local Label = { Type = "Label", Text = info.Text or "" }
    local textInst
    if info.DoesWrap then
        textInst = Themed(Text(self.Frame, {
            Name = "Label",
            Text = Label.Text,
            FontFace = FONT_MEDIUM,
            TextSize = 13,
            RichText = true,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.None,
            TextYAlignment = Enum.TextYAlignment.Top,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LineHeight = 1.15,
            LayoutOrder = self:NextOrder(),
        }), { TextColor3 = "TextSecondary" })
        Label.Instance = textInst
    else
        local row = AccessoryRow(self, 22)
        textInst = row.Label
        textInst.Text = Label.Text
        Label.Instance = row.Row
        attachAccessories(Label, self, row.Accessories)
    end

    function Label:SetText(text)
        Label.Text = text
        textInst.Text = text
    end

    function Label:SetVisible(visible)
        Label.Instance.Visible = visible
    end

    if idx then Library.Labels[idx] = Label end
    return Label
end

-------------------------------------------------------------------------------------------------------
-- Divider: two hairlines drawing in toward a small glass diamond.
-------------------------------------------------------------------------------------------------------
function Container:AddDivider()
    local row = New("Frame", {
        Name = "Divider",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 10),
        LayoutOrder = self:NextOrder(),
    }, self.Frame)
    for side = 0, 1 do
        local line = Themed(New("Frame", {
            AnchorPoint = Vector2.new(side, 0.5),
            Position = UDim2.new(side, 0, 0.5, 0),
            Size = UDim2.new(0.5, -9, 0, 1),
            BackgroundTransparency = 0.55,
            BorderSizePixel = 0,
        }, row), { BackgroundColor3 = "Rim" })
        New("UIGradient", {
            Rotation = side == 0 and 0 or 180,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0.3),
            }),
        }, line)
    end
    local diamond = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(5, 5),
        Rotation = 45,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
    }, row), { BackgroundColor3 = "Accent" })
    Corner(diamond, 1)
end

-------------------------------------------------------------------------------------------------------
-- Button: a glass key. It dips under the finger, sends a pulse of light through itself, and a
-- DoubleClick button asks for a second press while a fuse burns down underneath.
-------------------------------------------------------------------------------------------------------
local CONFIRM_WINDOW = 1.6

function Container:AddButton(first, second)
    local info
    if typeof(first) == "table" then
        info = first
    elseif typeof(second) == "table" then
        info = second
    else
        info = { Text = first, Func = second }
    end

    local W = self.W
    local strip = New("Frame", {
        Name = "Buttons",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        LayoutOrder = self:NextOrder(),
    }, self.Frame)
    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
    }, strip)

    local buttons = {}
    -- Width is shared between the buttons that are actually showing, so hiding one lets the rest
    -- expand to fill the strip instead of leaving a gap.
    local function relayout()
        local visible = {}
        for _, button in ipairs(buttons) do
            if button.Holder.Visible then table.insert(visible, button) end
        end
        local count = math.max(1, #visible)
        for _, button in ipairs(visible) do
            button.Holder.Size = UDim2.new(1 / count, -(8 * (count - 1)) / count, 1, 0)
        end
    end

    local function makeButton(buttonInfo)
        local Button = {
            Type = "Button",
            Text = buttonInfo.Text or "Button",
            Func = buttonInfo.Func or buttonInfo.Callback,
            Disabled = buttonInfo.Disabled == true,
            Risky = buttonInfo.Risky == true,
            DoubleClick = buttonInfo.DoubleClick == true,
            Tooltip = buttonInfo.Tooltip,
        }
        local tone = function() return Button.Risky and Glass.Danger or Glass.Rim end

        local holder = New("TextButton", {
            Name = "Button",
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            LayoutOrder = #buttons + 1,
            ClipsDescendants = false,
        }, strip)
        local scale = New("UIScale", { Scale = 1 }, holder)
        local body = Themed(New("Frame", {
            Name = "Body",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 0.9,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        }, holder), { BackgroundColor3 = "LensTint" })
        Corner(body, 9)
        New("UIGradient", {
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 0.5),
            }),
        }, body)
        local rim = Themed(New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Thickness = 1,
            Transparency = 0.55,
        }, body), { Color = tone })
        New("UIGradient", {
            Rotation = 100,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.05),
                NumberSequenceKeypoint.new(0.5, 0.7),
                NumberSequenceKeypoint.new(1, 0.3),
            }),
        }, rim)
        Specular(body, 18, 0.5, 3)

        local label = Themed(Text(body, {
            Text = Button.Text,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.new(1, -12, 1, 0),
            Position = UDim2.fromOffset(6, 0),
            ZIndex = 4,
        }), { TextColor3 = function() return Button.Risky and Glass.Danger or Glass.TextPrimary end })

        local fuse = Themed(New("Frame", {
            Name = "Fuse",
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, 0),
            Size = UDim2.new(0, 0, 0, 2),
            BorderSizePixel = 0,
            ZIndex = 4,
        }, body), { BackgroundColor3 = "Warning" })

        local armedToken
        local function disarm()
            armedToken = nil
            label.Text = Button.Text
            Tween(label, Motion.Hover, { TextColor3 = Button.Risky and Glass.Danger or Glass.TextPrimary })
            Tween(fuse, Motion.FadeOut, { Size = UDim2.new(0, 0, 0, 2) })
        end

        local function paintDisabled()
            label.TextTransparency = Button.Disabled and 0.55 or 0
            rim.Transparency = Button.Disabled and 0.8 or 0.55
        end
        paintDisabled()

        holder.MouseEnter:Connect(function()
            if Button.Disabled then return end
            Tween(body, Motion.Hover, { BackgroundTransparency = 0.8 })
            Tween(rim, Motion.Hover, { Transparency = 0.3 })
            playSound("Hover")
        end)
        holder.MouseLeave:Connect(function()
            Tween(body, Motion.Hover, { BackgroundTransparency = 0.9 })
            Tween(rim, Motion.Hover, { Transparency = Button.Disabled and 0.8 or 0.55 })
            Tween(scale, Motion.Pop, { Scale = 1 })
        end)
        holder.MouseButton1Down:Connect(function()
            if Button.Disabled then return end
            Tween(scale, Motion.Press, { Scale = 0.965 })
        end)
        holder.MouseButton1Up:Connect(function() Tween(scale, Motion.Pop, { Scale = 1 }) end)
        holder.MouseButton1Click:Connect(function()
            if Button.Disabled then return end
            Pulse(body, 3)
            playSound(Button.Risky and "Close" or "Press")
            if Button.DoubleClick and not armedToken then
                local token = {}
                armedToken = token
                label.Text = "Click again to confirm"
                Tween(label, Motion.Hover, { TextColor3 = Glass.Warning })
                fuse.Size = UDim2.new(1, 0, 0, 2)
                Tween(fuse, TweenInfo.new(CONFIRM_WINDOW, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) })
                task.delay(CONFIRM_WINDOW, function()
                    if armedToken == token then disarm() end
                end)
                return
            end
            if armedToken then disarm() end
            Library:SafeCallback(Button.Func)
        end)
        bindTooltip(W, holder, function()
            if Button.Disabled and buttonInfo.DisabledTooltip then return buttonInfo.DisabledTooltip end
            return Button.Tooltip
        end)

        Button.Holder = holder
        function Button:SetText(text)
            Button.Text = text
            if not armedToken then label.Text = text end
        end
        function Button:SetDisabled(disabled)
            Button.Disabled = disabled
            paintDisabled()
        end
        function Button:SetVisible(visible)
            -- Buttons share one horizontal strip, so hiding a sub-button must not take its siblings
            -- with it; the strip itself only disappears once every button in it is hidden.
            holder.Visible = visible
            local anyVisible = false
            for _, other in ipairs(buttons) do
                if other.Holder.Visible then
                    anyVisible = true
                    break
                end
            end
            strip.Visible = anyVisible
            relayout()
        end
        function Button:AddButton(a, b)
            local subInfo = typeof(a) == "table" and a or (typeof(b) == "table" and b or { Text = a, Func = b })
            return makeButton(subInfo)
        end

        table.insert(buttons, Button)
        relayout()
        return Button
    end

    return makeButton(info)
end
