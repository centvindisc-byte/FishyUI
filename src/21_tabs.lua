-------------------------------------------------------------------------------------------------------
-- Tabs
--
-- The sidebar lists tabs; each tab opens a drawer of sub-tabs, one per groupbox or tabbox on its page.
-- Clicking a sub-tab glides the page to that card, and scrolling the page moves the sub-tab bead along.
-- Tabs are magnetic: press one and pull, and it lifts off the sidebar to be carried anywhere; the other
-- tabs part to open a gap, and on release it flies back and snaps in.
-------------------------------------------------------------------------------------------------------
BuildTabs = function(W)
    local Window, Sidebar, Content, DragLayer, Scale = W.Window, W.Sidebar, W.Content, W.DragLayer, W.Scale
    local CHIP_WIDTH = L.SidebarWidth - L.SidebarInset * 2
    local TabDrag -- the lifted tab, if any

    ---------------------------------------------------------------------------------------------------
    -- Active-tab lens and drop slot
    ---------------------------------------------------------------------------------------------------
    local IndicatorTrack = New("Frame", {
        Name = "Indicator",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, L.TabHeight),
        Visible = false,
        ZIndex = 6,
    }, Sidebar)
    local IndicatorLens, IndicatorEdge = GlassLens(IndicatorTrack, L.TabRadius, 6)
    local Indicator = LiquidMover(IndicatorTrack, IndicatorLens, Springs.TabLens, IndicatorEdge)
    Indicator:SetTarget(function()
        local tab = Window.ActiveTab
        if not tab then return 0 end
        -- While the active tab is carried, the lens waits in the gap where it will land.
        if TabDrag and TabDrag.tab == tab then return tab.SlotY end
        return tab.Entry.Position.Y.Offset
    end)

    local SlotTrack = New("Frame", {
        Name = "DropSlot",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, L.TabHeight),
        ZIndex = 5,
    }, Sidebar)
    local SlotBody = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, SlotTrack), { BackgroundColor3 = "LensTint" })
    Corner(SlotBody, L.TabRadius)
    local SlotRim = Themed(New("UIStroke", { Thickness = 1, Transparency = 1 }, SlotBody), { Color = "Rim" })
    local DropSlot = LiquidMover(SlotTrack, SlotBody, Springs.Slot)
    DropSlot:SetTarget(function() return TabDrag and TabDrag.tab.SlotY or 0 end)

    ---------------------------------------------------------------------------------------------------
    -- Layout
    ---------------------------------------------------------------------------------------------------
    local function drawerHeight(tab)
        if not tab.Open or #tab.Sections == 0 then return 0 end
        return L.DrawerPadTop + #tab.Sections * L.SubHeight + L.DrawerPadBottom
    end

    local function beadY(index)
        return L.DrawerPadTop + (index - 1) * L.SubHeight + (L.SubHeight - L.BeadHeight) / 2
    end

    -- Stacks tabs with each open drawer pushing the rest down. A `floating` tab (being carried) keeps a
    -- tab-height gap reserved but its entry is left where it is.
    local function layout(animate, order, floating, tweenInfo)
        local y = 0
        for _, tab in ipairs(order or Window.Tabs) do
            tab.SlotY = y
            if tab == floating then
                y += L.TabHeight + L.TabGap
            else
                local drawer = drawerHeight(tab)
                local entryGoal = { Position = UDim2.new(0.5, 0, 0, y), Size = UDim2.new(1, 0, 0, L.TabHeight + drawer) }
                local drawerGoal = { Size = UDim2.new(1, 0, 0, drawer) }
                if tab.EntryTween then
                    tab.EntryTween:Cancel()
                    tab.EntryTween = nil
                end
                if animate then
                    tab.EntryTween = Tween(tab.Entry, tweenInfo or Motion.Reflow, entryGoal)
                    Tween(tab.Drawer, tweenInfo or Motion.Reflow, drawerGoal)
                else
                    tab.Entry.Position, tab.Entry.Size = entryGoal.Position, entryGoal.Size
                    tab.Drawer.Size = drawerGoal.Size
                end
                y += L.TabHeight + drawer + L.TabGap
            end
        end
        Sidebar.CanvasSize = UDim2.fromOffset(0, math.max(0, y - L.TabGap))
        if animate then Indicator:Wake(0.7) else Indicator:Snap() end
    end

    local function paintTab(tab)
        local on = tab == Window.ActiveTab
        Tween(tab.Label, Motion.Hover, { TextColor3 = on and Glass.TextPrimary or Glass.TextSecondary })
        if tab.IconImage then
            Tween(tab.IconImage, Motion.Hover, { ImageColor3 = on and Glass.TextPrimary or Glass.Glyph })
        end
        for _, line in ipairs(tab.ChevronLines) do
            Tween(line, Motion.Hover, { BackgroundColor3 = on and Glass.TextSecondary or Glass.TextMuted })
        end
        Tween(tab.Hover, Motion.Hover, { BackgroundTransparency = 1 })
    end

    local function paintTabs()
        for _, tab in ipairs(Window.Tabs) do paintTab(tab) end
    end

    -- Drawer effects carry a per-tab token so delayed steps from an earlier open/close never land on top
    -- of a newer one when a tab is clicked quickly.
    local function openDrawerEffects(tab)
        tab.EffectToken += 1
        local token = tab.EffectToken
        Tween(tab.Chevron, Motion.Settle, { Rotation = 90 })
        Tween(tab.Rail, Motion.FadeIn, { BackgroundTransparency = 0.8 })
        for i, section in ipairs(tab.Sections) do
            local label = section.Label
            label.TextTransparency = 1
            label.Position = UDim2.fromOffset(L.SubLabelX + 8, 0)
            task.delay(0.06 + i * 0.035, function()
                if tab.EffectToken ~= token then return end
                Tween(label, Motion.FadeIn, { TextTransparency = 0, Position = UDim2.fromOffset(L.SubLabelX, 0) })
            end)
        end
        tab.BeadBody.BackgroundTransparency = 1
        tab.BeadGlow.ImageTransparency = 1
        task.delay(0.14, function()
            if tab.EffectToken ~= token then return end
            Tween(tab.BeadBody, Motion.FadeIn, { BackgroundTransparency = 0 })
            Tween(tab.BeadGlow, Motion.FadeIn, { ImageTransparency = 0.5 })
        end)
    end

    local function closeDrawerEffects(tab)
        tab.EffectToken += 1
        Tween(tab.Chevron, Motion.Settle, { Rotation = 0 })
        Tween(tab.Rail, Motion.FadeOut, { BackgroundTransparency = 1 })
        Tween(tab.BeadBody, Motion.FadeOut, { BackgroundTransparency = 1 })
        Tween(tab.BeadGlow, Motion.FadeOut, { ImageTransparency = 1 })
        for _, section in ipairs(tab.Sections) do
            Tween(section.Label, Motion.FadeOut, { TextTransparency = 1, Position = UDim2.fromOffset(L.SubLabelX, 0) })
        end
    end

    -- Cards materialise one after another when a page is opened, top of each column first, so the page
    -- assembles itself instead of appearing all at once. Only the glass fades — nothing here touches
    -- layout, so the cards never shift while they arrive.
    local function playPageIntro(tab)
        tab.IntroToken += 1
        local token = tab.IntroToken
        for i, section in ipairs(tab.Sections) do
            local card = section.Card
            local stroke = card:FindFirstChildOfClass("UIStroke")
            -- Rest values come from the theme tokens, never from the card's current transparency: a
            -- second intro starting while the first is still tweening would otherwise capture a
            -- mid-animation value and make that the card's permanent resting state.
            local function restCard() return math.min(Glass.CardTransparency, 0.9) end
            local function restStroke() return 0.6 + Glass.BorderTransparency * 0.5 end
            card.BackgroundTransparency = 1
            if stroke then stroke.Transparency = 1 end
            task.delay(0.03 + (i - 1) * 0.045, function()
                if tab.IntroToken ~= token then
                    -- Switched away before this card's turn: snap it back rather than strand it invisible.
                    card.BackgroundTransparency = restCard()
                    if stroke then stroke.Transparency = restStroke() end
                    return
                end
                Tween(card, Motion.Intro, { BackgroundTransparency = restCard() })
                if stroke then Tween(stroke, Motion.Intro, { Transparency = restStroke() }) end
            end)
        end
    end

    local function selectSection(tab, section, instant)
        local previous = tab.ActiveSection
        if previous == section then return end
        tab.ActiveSection = section
        if previous then Tween(previous.Label, Motion.Hover, { TextColor3 = Glass.TextMuted }) end
        tab.Bead:SetTarget(beadY(section.Index))
        if instant then
            section.Label.TextColor3 = Glass.TextPrimary
            tab.Bead:Snap()
        else
            Tween(section.Label, Motion.Hover, { TextColor3 = Glass.TextPrimary })
        end
    end

    ---------------------------------------------------------------------------------------------------
    -- Magnetic tabs
    ---------------------------------------------------------------------------------------------------
    -- Top-left of a tab slot in the window's own (unscaled) coordinates, allowing for sidebar scroll.
    local function slotInWindow(slotY)
        return Vector2.new(Sidebar.Position.X.Offset, Sidebar.Position.Y.Offset + slotY - Sidebar.CanvasPosition.Y)
    end

    -- Carries the lifted tab on a 2D spring so it has a little weight and leans into sideways motion like a
    -- card in hand. On release it homes in on its gap with a looser, bouncier spring, then lands.
    local Carrier = { entry = nil, x = 0, y = 0, vx = 0, vy = 0, tx = 0, ty = 0, rotation = 0, homing = nil, onLanded = nil }
    function Carrier:Step(dt)
        if self.homing then
            local home = self.homing()
            self.tx, self.ty = home.X, home.Y
        end
        local stiffness = self.homing and 240 or 700
        local damping = 2 * math.sqrt(stiffness) * (self.homing and 0.6 or 0.85)
        self.vx += (stiffness * (self.tx - self.x) - damping * self.vx) * dt
        self.vy += (stiffness * (self.ty - self.y) - damping * self.vy) * dt
        self.x += self.vx * dt
        self.y += self.vy * dt
        local lean = math.clamp(self.vx * 0.01, -7, 7)
        self.rotation += (lean - self.rotation) * math.min(1, dt * 14)

        local settled = math.abs(self.tx - self.x) < 0.3 and math.abs(self.ty - self.y) < 0.3
            and math.abs(self.vx) < 3 and math.abs(self.vy) < 3 and math.abs(self.rotation) < 0.1
        if not settled then return true end
        if self.homing then
            self.homing = nil
            local landed = self.onLanded
            self.onLanded = nil
            if landed then landed() end
        end
        return false
    end

    -- Landing hands the entry back to the sidebar and clears `entry`, so a chip that just landed is left
    -- where the sidebar put it.
    function Carrier:Render()
        if self.entry then
            self.entry.Position = UDim2.fromOffset(self.x + CHIP_WIDTH / 2, self.y)
            self.entry.Rotation = self.rotation
        end
        Indicator:Wake(0.1)
        DropSlot:Wake(0.1)
    end

    local function showDropSlot(visible)
        if visible then
            DropSlot:Snap()
            Tween(SlotBody, Motion.FadeIn, { BackgroundTransparency = 0.94 })
            Tween(SlotRim, Motion.FadeIn, { Transparency = 0.55 })
        else
            Tween(SlotBody, Motion.FadeOut, { BackgroundTransparency = 1 })
            Tween(SlotRim, Motion.FadeOut, { Transparency = 1 })
        end
    end

    -- Gap index for the carried tab's centre, measured against the other tabs laid out without it so the
    -- answer doesn't flicker as the gap opens and closes.
    local function slotFor(centerY, others)
        local y = 0
        for i, tab in ipairs(others) do
            local height = L.TabHeight + drawerHeight(tab)
            if centerY < y + height / 2 then return i end
            y += height + L.TabGap
        end
        return #others + 1
    end

    local function beginTabDrag(tab)
        if TabDrag then return end
        W:ClosePopup()
        local wasOpen = tab.Open
        if wasOpen then
            tab.Open = false
            tab.EffectToken += 1
            Tween(tab.Chevron, Motion.Settle, { Rotation = 0 })
        end
        -- A rotated frame stops clipping its children, so the drawer's contents are hidden outright.
        tab.Rail.BackgroundTransparency = 1
        tab.BeadBody.BackgroundTransparency = 1
        tab.BeadGlow.ImageTransparency = 1
        for _, section in ipairs(tab.Sections) do section.Label.TextTransparency = 1 end
        tab.Drawer.Size = UDim2.new(1, 0, 0, 0)
        if tab.EntryTween then
            tab.EntryTween:Cancel()
            tab.EntryTween = nil
        end

        local start = slotInWindow(tab.Entry.Position.Y.Offset)
        TabDrag = { tab = tab, wasOpen = wasOpen, start = start, order = table.clone(Window.Tabs) }
        TabDrag.slot = table.find(TabDrag.order, tab)

        tab.Entry.Parent = DragLayer
        tab.Entry.Size = UDim2.fromOffset(CHIP_WIDTH, L.TabHeight)
        tab.Entry.Position = UDim2.fromOffset(start.X + CHIP_WIDTH / 2, start.Y)

        Tween(tab.EntryScale, Motion.Pop, { Scale = L.LiftScale })
        Tween(tab.LiftShadow, Motion.Pop, { ImageTransparency = 0.35 })
        Tween(tab.LiftPlate, Motion.Pop, { BackgroundTransparency = 0.84 })
        Tween(tab.LiftRim, Motion.Pop, { Transparency = 0.35 })
        Tween(tab.Label, Motion.Hover, { TextColor3 = Glass.TextPrimary })
        Tween(tab.Hover, Motion.Hover, { BackgroundTransparency = 1 })
        Indicator:SetPressed(false)
        Sidebar.ScrollingEnabled = false
        if Window.ActiveTab ~= tab then showDropSlot(true) end

        Carrier.entry, Carrier.homing, Carrier.onLanded = tab.Entry, nil, nil
        Carrier.x, Carrier.y, Carrier.tx, Carrier.ty = start.X, start.Y, start.X, start.Y
        Carrier.vx, Carrier.vy, Carrier.rotation = 0, 0, 0
        Animator.Wake(Carrier)
        layout(true, TabDrag.order, tab, Motion.DragReflow)
    end

    -- `dx`/`dy`: pointer movement since the press, in unscaled window pixels.
    local function moveTabDrag(dx, dy)
        local drag = TabDrag
        if not drag or drag.releasing then return end
        local tab = drag.tab
        local x, y = drag.start.X + dx, drag.start.Y + dy

        local others = without(Window.Tabs, tab)
        local listCenter = y - Sidebar.Position.Y.Offset + Sidebar.CanvasPosition.Y + L.TabHeight / 2
        local slot = slotFor(listCenter, others)
        if slot ~= drag.slot then
            drag.slot = slot
            table.insert(others, slot, tab)
            drag.order = others
            layout(true, drag.order, tab, Motion.DragReflow)
            Tween(tab.EntryScale, Motion.Press, { Scale = L.LiftScale + 0.025 })
            task.delay(Motion.Press.Time, function()
                if TabDrag == drag and not drag.releasing then Tween(tab.EntryScale, Motion.Pop, { Scale = L.LiftScale }) end
            end)
        end

        -- Within MagnetRange of its gap the chip is pulled in, harder the closer it gets.
        local home = slotInWindow(tab.SlotY)
        local pull = math.clamp(1 - (Vector2.new(x, y) - home).Magnitude / L.MagnetRange, 0, 1)
        pull *= pull
        Carrier.tx, Carrier.ty = x + (home.X - x) * pull, y + (home.Y - y) * pull
        Animator.Wake(Carrier)
    end

    -- Flies the chip home and settles it back into the sidebar. `instant` lands it at once.
    local function endTabDrag(instant)
        local drag = TabDrag
        if not drag then return end
        local tab = drag.tab

        local function land()
            if TabDrag ~= drag then return end
            TabDrag = nil
            Carrier.entry, Carrier.homing, Carrier.onLanded = nil, nil, nil

            local changed = false
            for i, t in ipairs(drag.order) do
                if Window.Tabs[i] ~= t then
                    changed = true
                    break
                end
            end
            Window.Tabs = drag.order

            tab.Entry.Parent = Sidebar
            tab.Entry.Rotation = 0
            tab.Entry.Size = UDim2.new(1, 0, 0, L.TabHeight)
            tab.Entry.Position = UDim2.new(0.5, 0, 0, tab.SlotY)
            Tween(tab.EntryScale, Motion.Drop, { Scale = 1 })
            Tween(tab.LiftShadow, Motion.Settle, { ImageTransparency = 1 })
            Tween(tab.LiftPlate, Motion.Settle, { BackgroundTransparency = 1 })
            Tween(tab.LiftRim, Motion.Settle, { Transparency = 1 })
            showDropSlot(false)
            Sidebar.ScrollingEnabled = true

            if drag.wasOpen and Window.ActiveTab == tab and #tab.Sections > 0 then
                tab.Open = true
                openDrawerEffects(tab)
            end
            layout(true)
            paintTabs()
            if changed and Window.OnTabOrderChanged then
                task.spawn(Window.OnTabOrderChanged, Window:GetTabOrder())
            end
        end

        if instant then
            land()
            return
        end
        if drag.releasing then return end
        drag.releasing = true
        Tween(tab.EntryScale, Motion.Settle, { Scale = 1.02 })
        Carrier.homing = function() return slotInWindow(tab.SlotY) end
        Carrier.onLanded = land
        Animator.Wake(Carrier)
    end
    W.EndTabDrag = function() endTabDrag(true) end

    ---------------------------------------------------------------------------------------------------
    -- Tabs
    ---------------------------------------------------------------------------------------------------
    function Window:AddTab(name, icon, description)
        if typeof(name) == "table" then
            icon, description, name = name.Icon, name.Description, name.Name
        end

        local Tab = { Name = name, Description = description, Sections = {}, Open = false, EffectToken = 0, IntroToken = 0, SlotY = 0, CardOrder = 0 }
        local function isActive() return Window.ActiveTab == Tab end

        -----------------------------------------------------------------------------------------------
        -- Sidebar entry
        -----------------------------------------------------------------------------------------------
        local Entry = New("Frame", {
            Name = "Tab_" .. name,
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, L.TabHeight),
            ZIndex = 10,
        }, Sidebar)
        Tab.EntryScale = New("UIScale", { Scale = 1 }, Entry)
        Tab.LiftShadow = GlassShadow(Entry, 14, 1, 8)

        local Button = New("TextButton", {
            Name = "Button",
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, L.TabHeight),
            ZIndex = 10,
        }, Entry)

        Tab.LiftPlate = Themed(New("Frame", {
            Name = "LiftPlate",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 9,
        }, Button), { BackgroundColor3 = "LensTint" })
        Corner(Tab.LiftPlate, L.TabRadius)
        Tab.LiftRim = Themed(New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1, Transparency = 1 }, Tab.LiftPlate), { Color = "Rim" })

        local Hover = Themed(New("Frame", {
            Name = "Hover",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 9,
        }, Button), { BackgroundColor3 = "LensTint" })
        Corner(Hover, L.TabRadius)

        local image = resolveIcon(icon)
        if image then
            Tab.IconImage = Themed(New("ImageLabel", {
                Name = "Icon",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, L.RailX, 0.5, 0),
                Size = UDim2.fromOffset(L.IconSize, L.IconSize),
                BackgroundTransparency = 1,
                Image = image,
                ScaleType = Enum.ScaleType.Fit,
                ZIndex = 11,
            }, Button), { ImageColor3 = function() return isActive() and Glass.TextPrimary or Glass.Glyph end })
        else
            local ring = New("Frame", {
                Name = "Icon",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, L.RailX, 0.5, 0),
                Size = UDim2.fromOffset(6, 6),
                BackgroundTransparency = 1,
                ZIndex = 11,
            }, Button)
            Corner(ring, 3)
            Themed(New("UIStroke", { Thickness = 1.2, Transparency = 0.2 }, ring), { Color = "Glyph" })
        end

        Tab.Label = Themed(Text(Button, {
            Name = "Label",
            Text = name,
            TextSize = 14,
            Position = UDim2.fromOffset(L.IconX + L.IconSize + 12, 0),
            Size = UDim2.new(1, -(L.IconX + L.IconSize + 12 + 28), 1, 0),
            ZIndex = 11,
        }), { TextColor3 = function() return isActive() and Glass.TextPrimary or Glass.TextSecondary end })

        Tab.Chevron, Tab.ChevronLines = Chevron(Button, 11)
        Tab.Chevron.Position = UDim2.new(1, -16, 0.5, 0)
        Tab.Chevron.Visible = false
        for _, line in ipairs(Tab.ChevronLines) do
            Themed(line, { BackgroundColor3 = function() return isActive() and Glass.TextSecondary or Glass.TextMuted end })
        end

        local Drawer = New("Frame", {
            Name = "Drawer",
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Position = UDim2.fromOffset(0, L.TabHeight),
            Size = UDim2.new(1, 0, 0, 0),
            ZIndex = 10,
        }, Entry)
        Tab.Rail = Themed(New("Frame", {
            Name = "Rail",
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.fromOffset(L.RailX, 0),
            Size = UDim2.fromOffset(1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 10,
        }, Drawer), { BackgroundColor3 = "Rim" })

        local BeadTrack = New("Frame", {
            Name = "Bead",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(L.RailX - L.BeadWidth / 2, 0),
            Size = UDim2.fromOffset(L.BeadWidth, L.BeadHeight),
            ZIndex = 11,
        }, Drawer)
        Tab.BeadGlow = Themed(New("ImageLabel", {
            Name = "Glow",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, 18, 1, 16),
            BackgroundTransparency = 1,
            Image = Assets.Spark,
            ImageTransparency = 1,
            ZIndex = 11,
        }, BeadTrack), { ImageColor3 = "Accent" })
        Tab.BeadBody = Themed(New("Frame", {
            Name = "Body",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 12,
        }, BeadTrack), { BackgroundColor3 = "Accent" })
        Corner(Tab.BeadBody, 2)
        Tab.Bead = LiquidMover(BeadTrack, Tab.BeadBody, Springs.Bead)

        Tab.Entry, Tab.Button, Tab.Hover, Tab.Drawer = Entry, Button, Hover, Drawer

        -----------------------------------------------------------------------------------------------
        -- Page: header, warning box, two columns of cards
        -----------------------------------------------------------------------------------------------
        local Page = New("Frame", {
            Name = "Page_" .. name,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Visible = false,
            ZIndex = 5,
        }, Content)
        local PageHeader = New("Frame", {
            Name = "Header",
            BackgroundTransparency = 1,
            Active = true,
            Size = UDim2.new(1, 0, 0, L.PageHeaderHeight),
            ZIndex = 5,
        }, Page)
        W:BindDrag(PageHeader)
        Themed(Text(PageHeader, {
            Text = name,
            TextSize = 20,
            Position = UDim2.fromOffset(L.PagePadding + 4, description and 12 or 0),
            -- Clears the header buttons (cursor, attachments, palette, themes, minimise) on the right.
            Size = UDim2.new(1, -(L.PagePadding + L.HeaderReserve), 0, description and 24 or L.PageHeaderHeight),
            ZIndex = 6,
        }), { TextColor3 = "TextPrimary" })
        if description then
            Themed(Text(PageHeader, {
                Text = description,
                FontFace = FONT_MEDIUM,
                TextSize = 12,
                Position = UDim2.fromOffset(L.PagePadding + 4, 36),
                Size = UDim2.new(1, -(L.PagePadding + L.HeaderReserve), 0, 16),
                ZIndex = 6,
            }), { TextColor3 = "TextMuted" })
        end

        local Scroller = New("ScrollingFrame", {
            Name = "Scroller",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(0, L.PageHeaderHeight),
            Size = UDim2.new(1, 0, 1, -L.PageHeaderHeight),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageTransparency = 0.5,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ZIndex = 5,
        }, Page)
        Themed(Scroller, { ScrollBarImageColor3 = "Accent" })
        New("UIPadding", {
            PaddingTop = UDim.new(0, 2),
            PaddingBottom = UDim.new(0, L.PagePadding),
            PaddingLeft = UDim.new(0, L.PagePadding),
            PaddingRight = UDim.new(0, L.PagePadding),
        }, Scroller)
        New("UIListLayout", { Padding = UDim.new(0, L.ColumnGap), SortOrder = Enum.SortOrder.LayoutOrder }, Scroller)

        local WarningBox = New("Frame", {
            Name = "WarningBox",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Glass.Warning,
            BackgroundTransparency = 0.9,
            BorderSizePixel = 0,
            LayoutOrder = 1,
            Visible = false,
        }, Scroller)
        Corner(WarningBox, L.CardRadius)
        local warningStroke = New("UIStroke", { Color = Glass.Warning, Transparency = 0.45, Thickness = 1 }, WarningBox)
        New("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 40),
            PaddingRight = UDim.new(0, 12),
        }, WarningBox)
        stackLayout(WarningBox, 2)
        local warningGlyph = New("TextLabel", {
            BackgroundColor3 = Glass.Warning,
            BorderSizePixel = 0,
            Position = UDim2.new(0, -28, 0, 1),
            Size = UDim2.fromOffset(18, 18),
            Text = "!",
            FontFace = FONT_BOLD,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(30, 20, 5),
            ZIndex = 3,
        }, WarningBox)
        Corner(warningGlyph, 9)
        local warningTitle = Text(WarningBox, { TextSize = 13, TextColor3 = Glass.Warning, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1 })
        local warningText = Themed(Text(WarningBox, {
            FontFace = FONT_MEDIUM,
            TextSize = 12,
            RichText = true,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.None,
            TextYAlignment = Enum.TextYAlignment.Top,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2,
        }), { TextColor3 = "TextSecondary" })

        local Columns = New("Frame", {
            Name = "Columns",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2,
        }, Scroller)
        local function column(side)
            local frame = New("Frame", {
                Name = side,
                BackgroundTransparency = 1,
                Position = UDim2.new(side == "Left" and 0 or 0.5, side == "Left" and 0 or L.ColumnGap / 2, 0, 0),
                Size = UDim2.new(0.5, -L.ColumnGap / 2, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
            }, Columns)
            New("UIListLayout", { Padding = UDim.new(0, L.ColumnGap), SortOrder = Enum.SortOrder.LayoutOrder }, frame)
            return frame
        end
        local LeftColumn, RightColumn = column("Left"), column("Right")
        Tab.Page, Tab.Scroller = Page, Scroller

        -- Scroll spy: the sub-tab bead follows whichever card has reached the top of the page.
        local programmaticScroll = 0
        Scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            if os.clock() < programmaticScroll or #Tab.Sections == 0 then return end
            -- Runs on every scrolled frame: each card's position is read once, not once per comparison.
            local top, scale = Scroller.AbsolutePosition.Y, Scale.Scale
            local current = Tab.Sections[1]
            local currentY = current.Card.AbsolutePosition.Y
            for _, section in ipairs(Tab.Sections) do
                local y = if section == Tab.Sections[1] then currentY else section.Card.AbsolutePosition.Y
                if (y - top) / scale <= 48 and y >= currentY then
                    current, currentY = section, y
                end
            end
            selectSection(Tab, current, false)
        end)

        local function scrollToSection(section)
            local offset = (section.Card.AbsolutePosition.Y - Scroller.AbsolutePosition.Y) / Scale.Scale + Scroller.CanvasPosition.Y - 2
            local maxScroll = math.max(0, Scroller.AbsoluteCanvasSize.Y / Scale.Scale - Scroller.AbsoluteSize.Y / Scale.Scale)
            programmaticScroll = os.clock() + Motion.Scroll.Time + 0.05
            Tween(Scroller, Motion.Scroll, { CanvasPosition = Vector2.new(0, math.clamp(offset, 0, maxScroll)) })
        end

        -----------------------------------------------------------------------------------------------
        -- Show / interaction
        -----------------------------------------------------------------------------------------------
        function Tab:Show()
            if TabDrag then return end
            W:ClosePopup()
            W:HideTooltip()
            if Window.ActiveTab == Tab then
                if #Tab.Sections > 0 then
                    Tab.Open = not Tab.Open
                    if Tab.Open then openDrawerEffects(Tab) else closeDrawerEffects(Tab) end
                    layout(true)
                end
                return
            end

            Window.ActiveTab = Tab
            playSound("Tab")
            for _, other in ipairs(Window.Tabs) do
                if other ~= Tab and other.Open then
                    other.Open = false
                    closeDrawerEffects(other)
                end
                other.Page.Visible = other == Tab
            end
            Scroller.Position = UDim2.fromOffset(0, L.PageHeaderHeight + 10)
            Tween(Scroller, Motion.Settle, { Position = UDim2.fromOffset(0, L.PageHeaderHeight) })
            playPageIntro(Tab)
            if #Tab.Sections > 0 then
                Tab.Open = true
                openDrawerEffects(Tab)
            end
            layout(true)
            paintTabs()
        end

        Button.MouseEnter:Connect(function()
            if Window.ActiveTab ~= Tab and not TabDrag then
                Tween(Hover, Motion.Hover, { BackgroundTransparency = 0.94 })
                Tween(Tab.Label, Motion.Hover, { TextColor3 = Glass.TextPrimary })
            end
        end)
        Button.MouseLeave:Connect(function()
            Tween(Hover, Motion.Hover, { BackgroundTransparency = 1 })
            if Window.ActiveTab ~= Tab and not (TabDrag and TabDrag.tab == Tab) then
                Tween(Tab.Label, Motion.Hover, { TextColor3 = Glass.TextSecondary })
            end
            Indicator:SetPressed(false)
        end)
        Button.MouseButton1Down:Connect(function()
            if Window.ActiveTab == Tab and not TabDrag then Indicator:SetPressed(true) end
        end)
        Button.MouseButton1Up:Connect(function() Indicator:SetPressed(false) end)
        Button.MouseButton1Click:Connect(function()
            -- The release that ends a carry also fires a click; that one must not switch tabs.
            if Tab.SuppressClick then
                Tab.SuppressClick = false
                return
            end
            Tab:Show()
        end)

        -- Press and pull past DragSlop to pick the tab up; a press that doesn't travel is a plain click.
        Button.InputBegan:Connect(function(input)
            if not isPointer(input) or TabDrag then return end
            Tab.SuppressClick = false
            local start = input.Position
            local lifted = false
            local moveConnection, endConnection
            moveConnection = UserInputService.InputChanged:Connect(function(changed)
                if not isMove(changed) then return end
                local delta = changed.Position - start
                if not lifted then
                    if delta.Magnitude < L.DragSlop or TabDrag then return end
                    lifted = true
                    Tab.SuppressClick = true
                    beginTabDrag(Tab)
                end
                moveTabDrag(delta.X / Scale.Scale, delta.Y / Scale.Scale)
            end)
            endConnection = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then return end
                moveConnection:Disconnect()
                endConnection:Disconnect()
                if lifted then endTabDrag() end
            end)
        end)

        -----------------------------------------------------------------------------------------------
        -- Sections (sub-tabs)
        -----------------------------------------------------------------------------------------------
        local function addSection(sectionName, card)
            local index = #Tab.Sections + 1
            local Section = { Name = sectionName, Index = index, Card = card }

            local SubButton = New("TextButton", {
                Name = "Sub_" .. sectionName,
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, L.DrawerPadTop + (index - 1) * L.SubHeight),
                Size = UDim2.new(1, 0, 0, L.SubHeight),
                ZIndex = 11,
            }, Drawer)
            Section.Label = Themed(Text(SubButton, {
                Name = "Label",
                Text = sectionName,
                FontFace = FONT_MEDIUM,
                TextSize = 13,
                TextTransparency = Tab.Open and 0 or 1,
                Position = UDim2.fromOffset(L.SubLabelX, 0),
                Size = UDim2.new(1, -(L.SubLabelX + 8), 1, 0),
                ZIndex = 12,
            }), { TextColor3 = function() return Tab.ActiveSection == Section and Glass.TextPrimary or Glass.TextMuted end })

            SubButton.MouseEnter:Connect(function()
                if Tab.ActiveSection ~= Section then Tween(Section.Label, Motion.Hover, { TextColor3 = Glass.TextSecondary }) end
            end)
            SubButton.MouseLeave:Connect(function()
                if Tab.ActiveSection ~= Section then Tween(Section.Label, Motion.Hover, { TextColor3 = Glass.TextMuted }) end
            end)
            SubButton.MouseButton1Click:Connect(function()
                selectSection(Tab, Section, false)
                scrollToSection(Section)
            end)

            table.insert(Tab.Sections, Section)
            Tab.Rail.Size = UDim2.fromOffset(1, L.DrawerPadTop + (index - 0.5) * L.SubHeight)
            Tab.Chevron.Visible = true

            if not Tab.ActiveSection then selectSection(Tab, Section, true) end
            if Window.ActiveTab == Tab and not Tab.Open then
                Tab.Open = true
                Tab.Chevron.Rotation = 90
                Tab.Rail.BackgroundTransparency = 0.8
                Tab.BeadBody.BackgroundTransparency = 0
                Tab.BeadGlow.ImageTransparency = 0.5
                for _, s in ipairs(Tab.Sections) do s.Label.TextTransparency = 0 end
            end
            layout(false)
            return Section
        end

        local function nextCardOrder()
            Tab.CardOrder += 1
            return Tab.CardOrder
        end

        function Tab:AddLeftGroupbox(groupName, groupIcon)
            local groupbox = newGroupbox(W, LeftColumn, groupName, groupIcon, nextCardOrder())
            addSection(groupName, groupbox.Card)
            return groupbox
        end

        function Tab:AddRightGroupbox(groupName, groupIcon)
            local groupbox = newGroupbox(W, RightColumn, groupName, groupIcon, nextCardOrder())
            addSection(groupName, groupbox.Card)
            return groupbox
        end

        local function addTabbox(columnFrame, tabboxName)
            local tabbox = newTabbox(W, columnFrame, nextCardOrder())
            local section = addSection(tabboxName or "Tabbox", tabbox.Card)
            local addTab = tabbox.AddTab
            function tabbox:AddTab(tabName)
                local tab = addTab(tabbox, tabName)
                if not tabboxName then
                    local names = {}
                    for _, t in ipairs(tabbox.Tabs) do table.insert(names, t.Name) end
                    section.Label.Text = table.concat(names, " / ")
                end
                return tab
            end
            return tabbox
        end

        function Tab:AddLeftTabbox(tabboxName) return addTabbox(LeftColumn, tabboxName) end
        function Tab:AddRightTabbox(tabboxName) return addTabbox(RightColumn, tabboxName) end

        function Tab:UpdateWarningBox(warning)
            warning = warning or {}
            WarningBox.Visible = warning.Visible ~= false
            local tone = warning.IsNormal and Glass.Accent or Glass.Warning
            WarningBox.BackgroundColor3 = tone
            warningStroke.Color = tone
            warningGlyph.BackgroundColor3 = tone
            warningGlyph.Text = warning.IsNormal and "i" or "!"
            warningTitle.TextColor3 = tone
            warningTitle.Text = warning.Title or "Notice"
            warningText.Text = warning.Text or ""
        end

        function Tab:SelectSection(sectionName)
            for _, section in ipairs(Tab.Sections) do
                if section.Name == sectionName then
                    selectSection(Tab, section, false)
                    scrollToSection(section)
                    return
                end
            end
        end

        table.insert(Window.Tabs, Tab)
        if not Window.ActiveTab then
            Window.ActiveTab = Tab
            Page.Visible = true
            IndicatorTrack.Visible = true
        end
        layout(false)
        -- Adding a tab never changes which one is active, so only the new tab needs painting. Repainting
        -- them all made building N tabs start N² tweens.
        paintTab(Tab)
        return Tab
    end

    function Window:GetTabOrder()
        local names = {}
        for i, tab in ipairs(Window.Tabs) do names[i] = tab.Name end
        return names
    end

    -- Reorders tabs by name (e.g. an order saved from OnTabOrderChanged). Unknown names are ignored and
    -- tabs missing from the list keep their relative order at the end.
    function Window:SetTabOrder(names)
        if TabDrag then return end
        local byName, ordered, used = {}, {}, {}
        for _, tab in ipairs(Window.Tabs) do byName[tab.Name] = tab end
        for _, tabName in ipairs(names) do
            local tab = byName[tabName]
            if tab and not used[tab] then
                table.insert(ordered, tab)
                used[tab] = true
            end
        end
        for _, tab in ipairs(Window.Tabs) do
            if not used[tab] then table.insert(ordered, tab) end
        end
        Window.Tabs = ordered
        layout(true)
    end
end
