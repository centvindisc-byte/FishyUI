-------------------------------------------------------------------------------------------------------
-- Attachments
--
-- Small glass pods carrying live info. Nothing is deployed by default: the Attachments button in the
-- header opens a dock of every pod, and you either click a tile to deploy it or drag the tile straight
-- out to place it yourself.
--
-- A docked pod hangs off one of the window's four sides on a bridge of liquid glass and trails the
-- window on a spring. Pull it far enough and the bridge tears; fling it and it flies to the nearest
-- screen corner as a pill; drop it on another pod and the two stack. Clicking a pod cycles it between
-- its card, expanded and pill forms. Minimise the window and the docked pods fall into orbit around the
-- bubble as small moons. If a side has no room on screen a pod crosses to the opposite side, and if
-- neither fits it is clamped into view without a bridge, so a pod is never shown tethered to nothing.
--
-- Pods are built the first time they are deployed and draw through a property cache, so a pod that is
-- out but still costs nothing, and one that is never used costs nothing at all. What a pod shows is its
-- kind: the built-in kinds live in 26_podkinds.lua; pinned controls and script-made pods are made here.
-------------------------------------------------------------------------------------------------------
local POD_W, POD_H = 176, 100
local POD_GAP = 10 -- window edge to a docked pod
local POD_STACK_GAP = 10
local POD_EDGE_INSET = 16 -- first pod's offset along the window edge
local POD_MAGNET = 110 -- screen px: a carried pod this close to a side docks there
local GRAPH_BARS, GRAPH_HEIGHT, GRAPH_GAP = 28, 28, 2
local PILL_W, PILL_H, EXPANDED_H, MOON_SIZE = 136, 30, 178, 50
local TETHER_SNAP = 150 -- px a docked pod can be pulled from its slot before its bridge tears
local THROW_SPEED = 1500 -- px/s at release that counts as a throw rather than a drop
local CORNER_MARGIN, CORNER_GAP = 12, 6
local SIDES = { "Right", "Left", "Top", "Bottom" }

-- Pods float over gameplay rather than over the window's own glass, so the muted greys that read fine
-- inside a card wash out here. Every pod label is lifted toward the primary text colour, which is what
-- rescues the flatter, lower-contrast themes (Midnight, Onyx, Smoke) without touching the rest of the UI.
-- Pushed most of the way to the primary colour rather than a little: a pod's glass is darker than a card
-- inside the window, and the muted greys that survive there read as switched-off out here even when the
-- measured contrast says otherwise.
local POD_LABEL = mixToken("TextMuted", "TextPrimary", 0.8)
local POD_SUB = mixToken("TextSecondary", "TextPrimary", 0.55)

local function isVertical(side)
    return side == "Left" or side == "Right"
end

-------------------------------------------------------------------------------------------------------
-- Kinds
--
-- A kind is what a pod shows. Every field is optional except Build:
--   Title, Side, Moon       heading, default dock side, the short caption under a moon's number
--   Build(pod, layer)       makes the card's content in `layer` (POD_W wide; y >= POD_H is the part only
--                           the expanded form reveals) and returns a table handed back to the others
--   Expands                 the kind has an expanded form worth cycling to
--   Refresh(pod, inst)      once a second while the pod is showing
--   Live(pod, inst, dt)     every frame while the pod is showing; throttle inside if need be
--   Summary(pod)            value, unit, short: the pill's and the dock's readout and the moon's number.
--                           Called on pods that aren't built yet, so it reads the world, never `inst`.
-- The helpers below are shared by every kind; they sit on PodKinds so they cost no top-level locals.
-------------------------------------------------------------------------------------------------------
local PodKinds = { List = {}, Order = {}, Pins = {}, MonoBold = Font.new(FONT_MONO.Family, Enum.FontWeight.Bold) }

function PodKinds.Define(name, kind)
    kind.Name = name
    PodKinds.List[name] = kind
    table.insert(PodKinds.Order, name)
    return kind
end

-- A primary readout. `color` is a theme token or a function, like Themed takes.
function PodKinds.Value(parent, props, color)
    local merged = { Text = "", TextSize = 20, TextTruncate = Enum.TextTruncate.None, ZIndex = 3 }
    for key, value in pairs(props) do merged[key] = value end
    return Themed(Text(parent, merged), { TextColor3 = color or "TextPrimary" })
end

-- A caption, lifted for legibility over the game like every pod label.
function PodKinds.Label(parent, props, color)
    local merged = { Text = "", FontFace = FONT_MEDIUM, TextSize = 11, ZIndex = 3 }
    for key, value in pairs(props) do merged[key] = value end
    return Themed(Text(parent, merged), { TextColor3 = color or POD_LABEL })
end

function PodKinds.Dot(parent, size, position, color, zIndex)
    local dot = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = position,
        Size = UDim2.fromOffset(size, size),
        BorderSizePixel = 0,
        ZIndex = zIndex or 3,
    }, parent)
    Corner(dot, size / 2)
    if color then Themed(dot, { BackgroundColor3 = color }) end
    return dot
end

-- A row of bars over a hairline baseline. Set draws the newest `count` values, right-aligned, and only
-- starts a tween toward a height that actually changed.
function PodKinds.Bars(parent, x, y, width, height, count, gap)
    local graph = New("Frame", {
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(width, height),
        BackgroundTransparency = 1,
        ZIndex = 3,
    }, parent)
    Themed(New("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, graph), { BackgroundColor3 = "Rim" })
    local barWidth = (width - (count - 1) * gap) / count
    local bars = {}
    for i = 1, count do
        local bar = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, (i - 1) * (barWidth + gap), 1, -2),
            Size = UDim2.fromOffset(barWidth, 2),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 4,
        }, graph)
        Corner(bar, 1)
        bars[i] = bar
    end
    local put, goals = PropertyCache(), {}
    local object = { Frame = graph }
    function object:Set(values, ceiling, colorOf)
        local n = #values
        for i, bar in ipairs(bars) do
            local value = values[n - count + i]
            if value and value > 0 then
                put(bar, "BackgroundColor3", colorOf(value))
                put(bar, "BackgroundTransparency", if i == count then 0.05 else 0.45)
                local size = UDim2.fromOffset(barWidth, math.max(2, math.min(1, value / ceiling) * (height - 4)))
                if goals[bar] ~= size then
                    goals[bar] = size
                    Tween(bar, Motion.Hover, { Size = size })
                end
            else
                put(bar, "BackgroundTransparency", 1)
            end
        end
    end
    return object
end

-- A polyline made of thin rotated segments. Set draws the newest `count` values left to right.
function PodKinds.Line(parent, x, y, width, height, count, color)
    local holder = New("Frame", {
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(width, height),
        BackgroundTransparency = 1,
        ZIndex = 3,
    }, parent)
    local segments = {}
    for i = 1, count - 1 do
        local segment = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 4,
        }, holder), { BackgroundColor3 = color })
        Corner(segment, 1)
        segments[i] = segment
    end
    local put = PropertyCache()
    local line = { Frame = holder }
    function line:Set(values, ceiling)
        local n = #values
        local px, py
        for i = 1, count do
            local value = values[n - count + i]
            local cx = (i - 1) / (count - 1) * width
            local cy = value and (height - 2 - math.clamp(value / math.max(ceiling, 1e-6), 0, 1) * (height - 4))
            local segment = segments[i - 1]
            if segment then
                if value and px then
                    local dx, dy = cx - px, cy - py
                    put(segment, "Position", UDim2.fromOffset((cx + px) / 2, (cy + py) / 2))
                    put(segment, "Size", UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + 1, 1.5))
                    put(segment, "Rotation", math.deg(math.atan2(dy, dx)))
                    put(segment, "BackgroundTransparency", 0.05)
                else
                    put(segment, "BackgroundTransparency", 1)
                end
            end
            px, py = if value then cx else nil, cy
        end
    end
    return line
end

-- Dots laid along an arc, lit up to a fraction: Roblox has no conic gradients, so gauges and rings are
-- drawn this way. Angles are in degrees, 0 pointing right and growing clockwise.
function PodKinds.DotArc(parent, cx, cy, radius, count, from, to, size)
    local dots = {}
    for i = 1, count do
        local angle = math.rad(from + (to - from) * (i - 1) / math.max(1, count - 1))
        local dot = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(cx + math.cos(angle) * radius, cy + math.sin(angle) * radius),
            Size = UDim2.fromOffset(size, size),
            BackgroundColor3 = Glass.Rim,
            BackgroundTransparency = 0.78,
            BorderSizePixel = 0,
            ZIndex = 4,
        }, parent)
        Corner(dot, size / 2)
        dots[i] = dot
    end
    local put = PropertyCache()
    local arc = { Dots = dots }
    function arc:Set(fraction, color)
        local lit = math.floor(math.clamp(fraction, 0, 1) * count + 0.5)
        for i, dot in ipairs(dots) do
            local on = i <= lit
            put(dot, "BackgroundColor3", if on then (color or Glass.Accent) else Glass.Rim)
            put(dot, "BackgroundTransparency", if on then 0 else 0.78)
        end
    end
    return arc
end

-- Numbers roll to a new value instead of jumping. Text is only written when the shown integer changes;
-- low graphics mode sets it straight away. `onWrite(text)` runs after each write (to place a unit).
function PodKinds.Roller(label, format, onWrite)
    local roller = { from = 0, to = 0, t = 1, shown = nil }
    function roller:Step(dt)
        self.t = math.min(1, self.t + dt / 0.35)
        return self.t < 1
    end
    function roller:Render()
        local eased = 1 - (1 - self.t) ^ 3
        local value = math.floor(self.from + (self.to - self.from) * eased + 0.5)
        if value ~= self.shown then
            self.shown = value
            label.Text = format(value)
            if onWrite then onWrite(label.Text) end
        end
    end
    function roller:Set(target)
        target = math.floor(target + 0.5)
        if target == self.to and self.t >= 1 and self.shown == target then return end
        if Library.LowGraphics or self.shown == nil then
            self.from, self.to, self.t = target, target, 1
            self:Render()
            return
        end
        self.from, self.to, self.t = self.shown, target, 0
        Animator.Wake(self)
    end
    return roller
end

-- A small glass button drawn inside the card, with its hit area on the pod's frame above the body.
function PodKinds.Chip(pod, layer, x, y, width, height, text, expandedOnly)
    local face = Themed(New("Frame", {
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(width, height),
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
        ZIndex = 4,
    }, layer), { BackgroundColor3 = "LensTint" })
    Corner(face, 7)
    Themed(New("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = 1,
        Transparency = 0.72,
    }, face), { Color = "Rim" })
    local label = PodKinds.Label(face, {
        Text = text,
        TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.fromOffset(4, 0),
        Size = UDim2.new(1, -8, 1, 0),
        ZIndex = 5,
    }, "TextPrimary")
    local hit = pod:Control({ Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(width, height) }, expandedOnly)
    hit.MouseEnter:Connect(function()
        Tween(face, Motion.Hover, { BackgroundTransparency = 0.76 })
        playSound("Hover")
    end)
    hit.MouseLeave:Connect(function() Tween(face, Motion.Hover, { BackgroundTransparency = 0.88 }) end)
    local chip = { Face = face, Label = label, Hit = hit }
    function chip:Flash()
        face.BackgroundColor3 = Glass.Accent
        face.BackgroundTransparency = 0.55
        Tween(face, Motion.Settle, { BackgroundColor3 = Glass.LensTint, BackgroundTransparency = 0.88 })
    end
    function chip:Destroy()
        face:Destroy()
        pod:RemoveControl(hit)
    end
    return chip
end

-- 12,345 / 1.23M: compact enough for a pill, exact while it fits.
function PodKinds.Number(value)
    if typeof(value) ~= "number" then return tostring(value) end
    local magnitude = math.abs(value)
    if magnitude >= 1e9 then return string.format("%.2fB", value / 1e9) end
    if magnitude >= 1e6 then return string.format("%.2fM", value / 1e6) end
    if value % 1 ~= 0 then return (string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", "")) end
    local text = tostring(math.floor(magnitude))
    local grouped = text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return (if value < 0 then "-" else "") .. grouped
end

-------------------------------------------------------------------------------------------------------
-- Pinned controls
--
-- Right-clicking a toggle, slider, dropdown or label pops it out as its own pod, so a HUD can be built
-- from the handful of controls actually being used. (Buttons go to the Quick actions pod instead.) A
-- pinned pod is a real pod: it docks, stacks, flies and is carried like any other, and it sits in the
-- dock alongside the rest. Its controls get their own hit areas over the card, so the pod is dragged by
-- its title bar and used everywhere else.
-------------------------------------------------------------------------------------------------------
PodKinds.Pins.Toggle = {
    Moon = "PIN",
    Build = function(pod, layer)
        local object = pod.Object
        local CAP_W, CAP_H, KNOB = 46, 26, 20
        local capsule = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromOffset(12, 62),
            Size = UDim2.fromOffset(CAP_W, CAP_H),
            ZIndex = 3,
        }, layer)
        FieldMaterial(capsule, CAP_H / 2)
        local fill = New("Frame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 4,
        }, capsule)
        Corner(fill, CAP_H / 2)
        Themed(New("UIGradient", { Rotation = 8 }, fill), { Color = accentSequence })
        local knob = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(KNOB, KNOB),
            BorderSizePixel = 0,
            ZIndex = 5,
        }, capsule), { BackgroundColor3 = "Knob" })
        Corner(knob, KNOB / 2)
        local state = Themed(Text(layer, {
            Text = "",
            TextSize = 14,
            Position = UDim2.fromOffset(12 + CAP_W + 12, 49),
            Size = UDim2.fromOffset(POD_W - CAP_W - 46, 26),
            ZIndex = 3,
        }), { TextColor3 = function() return object.Value and Glass.Accent or Glass.TextMuted end })

        local travel = Spring(520, 0.62, object.Value and 1 or 0, function(value)
            local inset = (CAP_H - KNOB) / 2
            local left = inset + KNOB / 2
            knob.Position = UDim2.fromOffset(left + (CAP_W - inset - KNOB / 2 - left) * value, CAP_H / 2)
        end, 0.002)

        local function render(instant)
            local on = object.Value
            state.Text = on and "ON" or "OFF"
            state.TextColor3 = on and Glass.Accent or Glass.TextMuted
            if instant then
                travel:Snap(on and 1 or 0)
                fill.BackgroundTransparency = on and 0 or 1
            else
                travel:Set(on and 1 or 0)
                Tween(fill, Motion.Hover, { BackgroundTransparency = on and 0 or 1 })
            end
        end
        render(true)

        pod:Control({ Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, -26, 0, 64) }).MouseButton1Click:Connect(function()
            if object.Disabled then return end
            object:SetValue(not object.Value)
            playSound(object.Value and "ToggleOn" or "ToggleOff")
            Library:Log(string.format("%s %s", tostring(object.Text or "Toggle"), object.Value and "on" or "off"))
        end)
        object.Mirror = function()
            render(false)
            pod:RefreshSummary()
        end
        pod.Unbind = function() object.Mirror = nil end
        return {}
    end,
    Summary = function(pod) return (if pod.Object.Value then "ON" else "OFF"), tostring(pod.Object.Text or "") end,
}

local function sliderText(object)
    local text = object.Rounding > 0
        and string.format("%." .. object.Rounding .. "f", object.Value)
        or tostring(math.floor(object.Value + 0.5))
    return (object.Prefix or "") .. text .. (object.Suffix or "")
end

PodKinds.Pins.Slider = {
    Moon = "PIN",
    Build = function(pod, layer)
        local object = pod.Object
        local TUBE_H, BEAD = 6, 14
        local value = PodKinds.Value(layer, {
            TextSize = 22,
            Position = UDim2.fromOffset(12, 30),
            Size = UDim2.fromOffset(POD_W - 24, 26),
        })
        local tube = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromOffset(12 + BEAD / 2, 74),
            Size = UDim2.fromOffset(POD_W - 24 - BEAD - 18, TUBE_H),
            ZIndex = 3,
        }, layer)
        FieldMaterial(tube, TUBE_H / 2)
        local fill = New("Frame", {
            Size = UDim2.fromScale(0, 1),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 4,
        }, tube)
        Corner(fill, TUBE_H / 2)
        Themed(New("UIGradient", {}, fill), { Color = accentSequence })
        local bead = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(BEAD, BEAD),
            BorderSizePixel = 0,
            ZIndex = 5,
        }, tube), { BackgroundColor3 = "Knob" })
        Corner(bead, BEAD / 2)
        Themed(New("UIStroke", { Thickness = 1.5, Transparency = 0.1 }, bead), { Color = "Accent" })

        local function percent()
            if object.Max == object.Min then return 0 end
            return math.clamp((object.Value - object.Min) / (object.Max - object.Min), 0, 1)
        end
        local level = Spring(420, 0.85, percent(), function(v)
            fill.Size = UDim2.fromScale(v, 1)
            bead.Position = UDim2.fromScale(v, 0.5)
        end, 0.0005)

        local function render(instant)
            value.Text = sliderText(object)
            if instant then level:Snap(percent()) else level:Set(percent()) end
        end
        render(true)

        local surface = pod:Control({ Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, -26, 0, 64) })
        local function setFromX(x)
            local left, width = tube.AbsolutePosition.X, tube.AbsoluteSize.X
            if width <= 0 or object.Disabled then return end
            object:SetValue(object.Min + (object.Max - object.Min) * math.clamp((x - left) / width, 0, 1))
        end
        surface.InputBegan:Connect(function(input)
            if not isPointer(input) then return end
            setFromX(input.Position.X)
            playSound("Press")
            local moveConnection, endConnection
            moveConnection = UserInputService.InputChanged:Connect(function(changed)
                if isMove(changed) then
                    setFromX(changed.Position.X)
                    playSound("Tick")
                end
            end)
            endConnection = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then return end
                moveConnection:Disconnect()
                endConnection:Disconnect()
            end)
        end)
        object.Mirror = function()
            render(false)
            pod:RefreshSummary()
        end
        pod.Unbind = function() object.Mirror = nil end
        return {}
    end,
    Summary = function(pod) return sliderText(pod.Object), tostring(pod.Object.Text or "") end,
}

-- The options a dropdown offers, as { Key, Label }. Dropdowns expose their own list (special types and
-- dictionaries included); a plain array is the fallback.
local function dropdownEntries(object)
    if typeof(object.Entries) == "function" then
        local ok, list = pcall(object.Entries)
        if ok and typeof(list) == "table" then return list end
    end
    local list = {}
    for _, value in ipairs(object.Values or {}) do table.insert(list, { Key = value, Label = tostring(value) }) end
    return list
end

local function dropdownText(object)
    local names = {}
    for _, entry in ipairs(dropdownEntries(object)) do
        local selected = if object.Multi then object.Value[entry.Key] == true else object.Value == entry.Key
        if selected then table.insert(names, entry.Label) end
    end
    if #names == 0 then return "None" end
    return table.concat(names, ", ")
end

PodKinds.Pins.Dropdown = {
    Moon = "PICK",
    Build = function(pod, layer)
        local object = pod.Object
        local value = PodKinds.Value(layer, {
            TextSize = 15,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Position = UDim2.fromOffset(12, 28),
            Size = UDim2.fromOffset(POD_W - 24, 20),
        })
        local sub = PodKinds.Label(layer, { Position = UDim2.fromOffset(12, 48), Size = UDim2.fromOffset(POD_W - 24, 14) })
        local back = PodKinds.Chip(pod, layer, 12, 68, 30, 22, "‹")
        local forward = PodKinds.Chip(pod, layer, 48, 68, 30, 22, "›")
        local pick = object.Multi and PodKinds.Chip(pod, layer, 84, 68, 62, 22, "Select") or nil
        local cursor = 1

        local function render()
            local entries = dropdownEntries(object)
            if object.Multi then
                cursor = math.clamp(cursor, 1, math.max(1, #entries))
                local entry = entries[cursor]
                local count = 0
                for _ in pairs(object.Value) do count += 1 end
                value.Text = if entry then ((object.Value[entry.Key] and "✓ " or "") .. entry.Label) else "No options"
                sub.Text = string.format("%d of %d selected", count, #entries)
                if pick then pick.Label.Text = if entry and object.Value[entry.Key] then "Remove" else "Select" end
            else
                value.Text = dropdownText(object)
                sub.Text = string.format("%d options", #entries)
            end
        end
        render()

        local function step(direction)
            local entries = dropdownEntries(object)
            if #entries == 0 or object.Disabled then return end
            if object.Multi then
                cursor = (cursor - 1 + direction) % #entries + 1
                render()
            else
                local index = 0
                for i, entry in ipairs(entries) do
                    if entry.Key == object.Value then index = i end
                end
                local nextEntry = entries[(index - 1 + direction) % #entries + 1]
                if index == 0 then nextEntry = entries[if direction > 0 then 1 else #entries] end
                object:SetValue(nextEntry.Key)
                Library:Log(string.format("%s: %s", tostring(object.Text or "Dropdown"), nextEntry.Label))
            end
            playSound("Tick")
        end
        back.Hit.MouseButton1Click:Connect(function() back:Flash() step(-1) end)
        forward.Hit.MouseButton1Click:Connect(function() forward:Flash() step(1) end)
        if pick then
            pick.Hit.MouseButton1Click:Connect(function()
                local entry = dropdownEntries(object)[cursor]
                if not entry or object.Disabled then return end
                pick:Flash()
                local selected = table.clone(object.Value)
                selected[entry.Key] = (not selected[entry.Key]) or nil
                object:SetValue(selected)
                playSound("Press")
            end)
        end
        object.Mirror = function()
            render()
            pod:RefreshSummary()
        end
        pod.Unbind = function() object.Mirror = nil end
        return {}
    end,
    Summary = function(pod) return dropdownText(pod.Object), "" end,
}

PodKinds.Pins.Label = {
    Moon = "NOTE",
    Build = function(pod, layer)
        local object = pod.Object
        local text = PodKinds.Label(layer, {
            Text = tostring(object.Text or ""),
            TextSize = 12,
            RichText = true,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextYAlignment = Enum.TextYAlignment.Top,
            Position = UDim2.fromOffset(12, 28),
            Size = UDim2.fromOffset(POD_W - 30, 62),
        }, "TextPrimary")
        object.Mirror = function()
            text.Text = tostring(object.Text or "")
            pod:RefreshSummary()
        end
        pod.Unbind = function() object.Mirror = nil end
        return {}
    end,
    Summary = function(pod)
        local plain = tostring(pod.Object.Text or ""):gsub("<[^>]->", "")
        return plain, ""
    end,
}

-------------------------------------------------------------------------------------------------------
-- Script-made pods: Window:AddAttachment({ Title, Kind = "Stat" | "Graph" | "List" | "Custom", ... })
-------------------------------------------------------------------------------------------------------
function PodKinds.Custom(spec)
    local style = spec.Kind or "Stat"
    local title = tostring(spec.Title or "Custom")
    local kind = {
        Title = title:upper(),
        Side = spec.Side or "Right",
        Moon = spec.MoonLabel or title:sub(1, 4):upper(),
        Expands = style == "List" or style == "Graph" or spec.Expands == true,
    }

    local function format(value)
        if spec.Format then
            local ok, text = pcall(spec.Format, value)
            if ok and text ~= nil then return tostring(text) end
        end
        if value == nil then return "--" end
        return PodKinds.Number(value)
    end
    kind.Format = format

    -- Polling: Update runs on its own thread every Interval seconds while the pod is out, so a slow or
    -- yielding callback never stalls a frame.
    if typeof(spec.Update) == "function" then
        local interval = math.max(0.05, tonumber(spec.Interval) or 1)
        kind.Live = function(pod)
            local state = pod.state
            local now = os.clock()
            if state.busy or now - (state.polled or 0) < interval then return end
            state.polled, state.busy = now, true
            task.spawn(function()
                local ok, value = pcall(spec.Update)
                state.busy = false
                if ok and value ~= nil then pod:Push(value) end
            end)
        end
    end

    kind.Build = function(pod, layer)
        local inst = {}
        if style == "List" then
            inst.rows = {}
            for i = 1, 8 do
                local y = 28 + (i - 1) * 18
                inst.rows[i] = {
                    Left = PodKinds.Label(layer, { Position = UDim2.fromOffset(12, y), Size = UDim2.fromOffset(POD_W - 80, 16) }, "TextPrimary"),
                    Right = PodKinds.Label(layer, {
                        TextXAlignment = Enum.TextXAlignment.Right,
                        AnchorPoint = Vector2.new(1, 0),
                        Position = UDim2.fromOffset(POD_W - 12, y),
                        Size = UDim2.fromOffset(66, 16),
                    }),
                }
            end
        elseif style == "Custom" then
            if typeof(spec.Build) == "function" then
                local area = New("Frame", {
                    Name = "Content",
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 26),
                    Size = UDim2.fromOffset(POD_W, EXPANDED_H - 26),
                    ZIndex = 3,
                }, layer)
                local ok, result = pcall(spec.Build, area, pod.Handle)
                if ok and typeof(result) == "function" then inst.update = result end
                if not ok then warn("[FishyUI] attachment build error: " .. tostring(result)) end
            end
        else
            local graph = style == "Graph"
            inst.value = PodKinds.Value(layer, {
                Text = "--",
                TextSize = if graph then 18 else 22,
                Position = UDim2.fromOffset(12, 26),
                Size = UDim2.fromOffset(POD_W - 24, 26),
            })
            inst.unit = PodKinds.Label(layer, { Text = spec.Unit or "", Position = UDim2.fromOffset(60, 34), Size = UDim2.fromOffset(70, 16) })
            if graph then
                inst.graph = PodKinds.Bars(layer, 12, 56, POD_W - 24, 34, GRAPH_BARS, GRAPH_GAP)
                inst.low = PodKinds.Label(layer, { Position = UDim2.fromOffset(12, 104), Size = UDim2.fromOffset(POD_W - 24, 14) })
                inst.wide = PodKinds.Bars(layer, 12, 122, POD_W - 24, 46, GRAPH_BARS, GRAPH_GAP)
            else
                inst.sub = PodKinds.Label(layer, { Text = spec.Subtitle or "", Position = UDim2.fromOffset(12, 56), Size = UDim2.fromOffset(POD_W - 24, 14) })
                inst.trend = PodKinds.Label(layer, { Position = UDim2.fromOffset(12, 74), Size = UDim2.fromOffset(POD_W - 24, 14) })
            end
        end
        return inst
    end

    kind.Refresh = function(pod, inst)
        local state = pod.state
        local value = state.value
        if style == "List" then
            local items = if typeof(value) == "table" then value else {}
            for i, row in ipairs(inst.rows) do
                local item = items[i]
                local left, right = "", ""
                if typeof(item) == "table" then
                    left, right = tostring(item.Text or item[1] or ""), tostring(item.Value or item[2] or "")
                elseif item ~= nil then
                    left = tostring(item)
                end
                row.Left.Text, row.Right.Text = left, right
            end
        elseif style == "Custom" then
            if inst.update then
                local ok, err = pcall(inst.update, value)
                if not ok then warn("[FishyUI] attachment update error: " .. tostring(err)) end
            end
        else
            local text = format(value)
            inst.value.Text = text
            inst.unit.Position = UDim2.fromOffset(12 + textWidth(text, inst.value.TextSize, Enum.Font.GothamBold) + 5, 34)
            local history = state.history or {}
            if inst.graph then
                local ceiling, low, high = 1e-6, math.huge, -math.huge
                for _, v in ipairs(history) do
                    ceiling = math.max(ceiling, math.abs(v) * 1.15)
                    low, high = math.min(low, v), math.max(high, v)
                end
                local colorOf = function() return Glass.Accent end
                inst.graph:Set(history, ceiling, colorOf)
                inst.wide:Set(history, ceiling, colorOf)
                inst.low.Text = if #history > 0 then string.format("Low %s  ·  High %s", format(low), format(high)) else ""
            elseif inst.trend then
                local count = #history
                if count >= 2 and history[count] ~= history[count - 1] then
                    local delta = history[count] - history[count - 1]
                    inst.trend.Text = string.format("%s %s", if delta > 0 then "▲" else "▼", format(math.abs(delta)))
                    inst.trend.TextColor3 = if delta > 0 then Glass.Success else Glass.Danger
                end
            end
        end
    end

    kind.Summary = function(pod)
        local value = pod.state.value
        if style == "List" then
            return (if typeof(value) == "table" then tostring(#value) else "0"), "items"
        end
        if style == "Custom" and spec.Summary then
            local ok, text, unit = pcall(spec.Summary, value)
            if ok then return text, unit end
        end
        return format(value), spec.Unit or ""
    end
    return kind
end

-------------------------------------------------------------------------------------------------------
-- The engine
-------------------------------------------------------------------------------------------------------
BuildSatellites = function(W)
    local ScreenGui, Holder, Scale, Window = W.ScreenGui, W.Holder, W.Scale, W.Window
    local Bubble = Window.Bubble
    local useBubble = W.Info.Bubble ~= false
    local pods, byName = {}, {}
    local carry -- { pod, held, side, index, slot, stackOn, samples }
    local windowShown, bubbleHover = false, false
    local pointer -- the mouse in screen px, for the light that follows it
    local insetY = GuiService:GetGuiInset().Y
    W.QuickActions = {} -- buttons pinned to the Quick actions pod
    Prefs.PodLayouts = if typeof(Prefs.PodLayouts) == "table" then Prefs.PodLayouts else {}

    local FORM_SIZE = {
        card = Vector2.new(POD_W, POD_H),
        expanded = Vector2.new(POD_W, EXPANDED_H),
        pill = Vector2.new(PILL_W, PILL_H),
        moon = Vector2.new(MOON_SIZE, MOON_SIZE),
    }
    local FORM_RADIUS = { card = 12, expanded = 12, pill = PILL_H / 2, moon = MOON_SIZE / 2 }
    local CORNERS = { TopLeft = true, TopRight = true, BottomLeft = true, BottomRight = true }
    local SIZE_K, SIZE_D = 260, 2 * math.sqrt(260) * 0.62
    local SQUASH_K, SQUASH_D = 520, 2 * math.sqrt(520) * 0.3

    local function easeOut(t)
        t = math.clamp(t, 0, 1)
        return 1 - (1 - t) ^ 3
    end

    -- Input positions leave out the top bar; this ScreenGui ignores the inset, so add it back.
    local function screenPoint(input)
        return Vector2.new(input.Position.X, input.Position.Y + insetY)
    end

    ---------------------------------------------------------------------------------------------------
    -- Geometry
    ---------------------------------------------------------------------------------------------------
    local function geometry()
        local ss, p, s, k = ScreenGui.AbsoluteSize, Holder.Position, Holder.Size, Scale.Scale
        local size = Vector2.new(s.X.Offset, s.Y.Offset) * k
        local center = Vector2.new(p.X.Scale * ss.X + p.X.Offset, p.Y.Scale * ss.Y + p.Y.Offset)
        insetY = GuiService:GetGuiInset().Y
        return { screen = ss, k = k, top = insetY, tl = center - size / 2, size = size }
    end

    local function clampBox(position, w, h, g)
        local ss, margin = g.screen, L.BubbleMargin
        local top = g.top + margin
        return Vector2.new(
            math.clamp(position.X, margin, math.max(margin, ss.X - w - margin)),
            math.clamp(position.Y, top, math.max(top, ss.Y - h - margin))
        )
    end

    -- Top-left of the first slot on a side for a pod `w` by `h` screen px.
    local function sideOrigin(side, w, h, g)
        local tl, size, k = g.tl, g.size, g.k
        if side == "Right" then return Vector2.new(tl.X + size.X + POD_GAP * k, tl.Y + POD_EDGE_INSET * k) end
        if side == "Left" then return Vector2.new(tl.X - POD_GAP * k - w, tl.Y + POD_EDGE_INSET * k) end
        if side == "Top" then return Vector2.new(tl.X + POD_EDGE_INSET * k, tl.Y - POD_GAP * k - h) end
        return Vector2.new(tl.X + POD_EDGE_INSET * k, tl.Y + size.Y + POD_GAP * k)
    end

    local function opposite(side)
        if side == "Left" then return "Right" end
        if side == "Right" then return "Left" end
        if side == "Top" then return "Bottom" end
        return "Top"
    end

    local function fits(position, w, h, g)
        return position.X >= 0 and position.Y >= g.top and position.X + w <= g.screen.X and position.Y + h <= g.screen.Y
    end

    -- The side a pod actually renders on: its own, or the opposite one when there's no room.
    local function renderSide(side, g)
        g.sides = g.sides or {}
        local known = g.sides[side]
        if known then return known end
        local w, h = POD_W * g.k, POD_H * g.k
        local result = side
        if not fits(sideOrigin(side, w, h, g), w, h, g) then
            local other = opposite(side)
            if fits(sideOrigin(other, w, h, g), w, h, g) then result = other end
        end
        g.sides[side] = result
        return result
    end

    ---------------------------------------------------------------------------------------------------
    -- Placement
    --
    -- Every deployed pod is in exactly one place: docked to a side, parked in a screen corner, floating,
    -- in orbit (docked, while the window is minimised to the bubble) or stacked behind another pod. A
    -- stack is a host pod and its guests; it sits where the host would, and its members share the host's
    -- form so they line up.
    ---------------------------------------------------------------------------------------------------
    local function hostOf(pod)
        return pod.Host or pod
    end

    local function byOrder(a, b)
        return a.Order < b.Order
    end

    -- How far behind the front of its stack a pod sits (0 = in front, or not stacked).
    local function stackDepth(pod)
        local host = pod.Host or pod
        local stack = host.Stack
        if not stack then return 0 end
        local index = table.find(stack, pod) or 1
        return (index - host.Front) % #stack
    end

    -- Where each docked stack sits, by the side it renders on, with a gap held open for a carried pod
    -- that is about to dock and the old slot of one that is still tethered to it.
    local function dockSlots(g)
        local grouped = { Right = {}, Left = {}, Top = {}, Bottom = {} }
        for _, pod in ipairs(pods) do
            if pod.Deployed and pod.Docked and not pod.Host and not pod.Flying
                and (not pod.Carried or (carry and carry.pod == pod and carry.held)) then
                table.insert(grouped[renderSide(pod.Side, g)], pod)
            end
        end
        local slots, k = {}, g.k
        for _, side in ipairs(SIDES) do
            local column = grouped[side]
            table.sort(column, byOrder)
            if carry and not carry.held and carry.side == side then
                table.insert(column, math.clamp(carry.index, 1, #column + 1), carry)
            end
            local vertical, along = isVertical(side), 0
            for _, item in ipairs(column) do
                local pod = if item == carry then carry.pod else item
                local size = FORM_SIZE[pod.Form] * k
                local origin = sideOrigin(side, size.X, size.Y, g)
                local ideal = if vertical then origin + Vector2.new(0, along) else origin + Vector2.new(along, 0)
                along += (if vertical then size.Y else size.X) + POD_STACK_GAP * k
                local clamped = clampBox(ideal, size.X, size.Y, g)
                local slot = { pos = clamped, side = side, attached = (clamped - ideal).Magnitude < 0.5 }
                if item == carry then carry.slot = slot else slots[pod] = slot end
            end
        end
        return slots
    end

    -- Corners hold a column of pods, the newest nearest the corner. A pod still flying in already has
    -- its slot, so it knows where to land.
    local function cornerSlots(g)
        local lists = { TopLeft = {}, TopRight = {}, BottomLeft = {}, BottomRight = {} }
        for _, pod in ipairs(pods) do
            if pod.Deployed and pod.Corner and not pod.Host and not pod.Carried then
                table.insert(lists[pod.Corner], pod)
            end
        end
        local slots, k, ss = {}, g.k, g.screen
        for name, list in pairs(lists) do
            table.sort(list, function(a, b) return a.CornerOrder < b.CornerOrder end)
            local right = name == "TopRight" or name == "BottomRight"
            local bottom = name == "BottomLeft" or name == "BottomRight"
            local along = 0
            for _, pod in ipairs(list) do
                local size = FORM_SIZE[pod.Form] * k
                local x = if right then ss.X - CORNER_MARGIN - size.X else CORNER_MARGIN
                local y = if bottom then ss.Y - CORNER_MARGIN - size.Y - along else g.top + CORNER_MARGIN + along
                along += size.Y + CORNER_GAP
                slots[pod] = { pos = Vector2.new(x, y) }
            end
        end
        return slots
    end

    local function bubbleInfo(g)
        if g.bubbleRead then return g.bubble end
        g.bubbleRead = true
        if useBubble and Bubble and Bubble.Visible then
            local p, s = Bubble.Position, Bubble.Size
            g.bubble = { center = Vector2.new(p.X.Offset, p.Y.Offset), w = s.X.Offset, h = s.Y.Offset }
        end
        return g.bubble
    end

    -- Moons circle the bubble on an ellipse, the near ones larger and drawn over it. Hovering the bubble,
    -- or low graphics mode, holds them still in a fan above it instead.
    local function orbitSlots(g)
        if windowShown then return nil, false end
        local list = {}
        for _, pod in ipairs(pods) do
            if pod.Deployed and pod.Docked and not pod.Host and not pod.Carried then table.insert(list, pod) end
        end
        if #list == 0 then return nil, false end
        local b = bubbleInfo(g)
        if not b then return nil, false end
        table.sort(list, byOrder)
        local slots, n = {}, #list
        local still = bubbleHover or Library.LowGraphics
        local half = Vector2.new(MOON_SIZE / 2, MOON_SIZE / 2)
        if still then
            local below = b.center.Y - b.h / 2 - g.top < MOON_SIZE + 34
            local spacing = MOON_SIZE + 12
            for i, pod in ipairs(list) do
                local offset = (i - (n + 1) / 2) * spacing
                local lift = b.h / 2 + 16 + MOON_SIZE / 2 + math.abs(offset) * 0.12
                local center = b.center + Vector2.new(offset, if below then lift else -lift)
                slots[pod] = { pos = clampBox(center - half, MOON_SIZE, MOON_SIZE, g), scale = 1, front = true }
            end
        else
            local rx, ry = b.w / 2 + 58, b.h / 2 + 40
            local spin = os.clock() * 0.45
            -- The bubble usually sits at the top of the screen; drop the ellipse until its top fits.
            local room = b.center.Y - g.top - MOON_SIZE / 2 - 6
            local hub = b.center + Vector2.new(0, math.max(0, ry - room))
            for i, pod in ipairs(list) do
                local angle = -math.pi / 2 + (i - 1) * (2 * math.pi / n) + spin
                local depth = math.sin(angle) * 0.5 + 0.5
                local center = hub + Vector2.new(math.cos(angle) * rx, math.sin(angle) * ry)
                slots[pod] = { pos = center - half, scale = 0.86 + 0.18 * depth, front = math.sin(angle) > 0 }
            end
        end
        return slots, still
    end

    -- Slots depend only on the window, the screen and the pods' own state, none of which changes partway
    -- through an animator frame, so they are worked out once a frame and shared by every pod and substep.
    -- Anything that moves a pod between places calls invalidate() so the next read starts fresh.
    local stateFrame, state = -1, nil
    local function invalidate()
        stateFrame = -1
    end
    local function frameState()
        if state and stateFrame == Animator.frame then return state end
        stateFrame = Animator.frame
        local g = geometry()
        state = { g = g, dock = dockSlots(g), corner = cornerSlots(g) }
        state.orbit, state.still = orbitSlots(g)
        return state
    end

    local function wakeAll()
        for _, pod in ipairs(pods) do
            if pod.Built and (pod.Deployed or pod.alpha > 0.005) then Animator.Wake(pod) end
        end
    end

    -- Where a pod is heading this frame, and how it should look there.
    local function place(pod, fs)
        local out = pod.place
        if out.fs == fs then return out end
        out.fs = fs
        local g = fs.g
        local host = hostOf(pod)
        local alpha = if pod.Deployed then 1 else 0
        local form, base, depth, z, dim, slot = host.Form, g.k, 1, 92, 0, nil
        local pos
        if pod.Carried then
            local size = FORM_SIZE[pod.Form] * g.k
            pos = clampBox(Vector2.new(pod.tx, pod.ty), size.X, size.Y, g)
            z = 98
            if carry and carry.pod == pod then
                if carry.held then slot = fs.dock[pod] elseif carry.side then slot = carry.slot end
            end
        elseif host.Flying then
            local target = fs.corner[host]
            pos = if target then target.pos else Vector2.new(host.x, host.y)
            z = 97
        elseif host.Docked then
            local orbit = fs.orbit and fs.orbit[host]
            if orbit then
                pos, form, base, depth = orbit.pos, "moon", 1, orbit.scale
                z = if orbit.front then 201 else 90
            else
                local s = fs.dock[host]
                pos = if s then s.pos else Vector2.new(host.x, host.y)
                slot = s
                if not windowShown then alpha = 0 end
            end
        elseif host.Corner then
            local s = fs.corner[host]
            pos = if s then s.pos else Vector2.new(host.x, host.y)
        else
            local size = FORM_SIZE[host.Form] * g.k
            pos = clampBox(Vector2.new(host.tx, host.ty), size.X, size.Y, g)
        end
        if not pod.Carried and host.Stack then
            local behind = stackDepth(pod)
            if behind > 0 then
                local shown = math.min(behind, 2)
                pos = pos - Vector2.new(0, 7 * shown * base)
                depth *= 0.92 ^ shown
                dim = math.min(1, 0.5 * behind)
                z -= shown
                slot = nil
                if behind > 2 or form == "moon" then alpha = 0 end
            else
                z += 1
            end
        end
        out.pos, out.form, out.base, out.depth, out.z, out.dim, out.alpha, out.slot = pos, form, base, depth, z, dim, alpha, slot
        out.moon = form == "moon"
        return out
    end

    ---------------------------------------------------------------------------------------------------
    -- Tethers: a bridge of liquid glass from the window edge to a docked pod. Two round feet and a
    -- capsule in two halves meeting at a midpoint that sways with the pod's motion; low graphics draws
    -- one straight capsule. The halves are near-opaque so where they overlap the feet nothing doubles up.
    ---------------------------------------------------------------------------------------------------
    local function tetherEnds(pod, fs)
        local g = fs.g
        local tl, size, k = g.tl, g.size, g.k
        local scale = pod.base * pod.depth
        local w, h = pod.w * scale, pod.h * scale
        local cx, cy = pod.x + pod.w * pod.base / 2, pod.y + pod.h * pod.base / 2
        local inset = 18 * k
        local side = pod.tetherSide or "Right"
        if side == "Right" or side == "Left" then
            local ay = math.clamp(cy, tl.Y + inset, math.max(tl.Y + inset, tl.Y + size.Y - inset))
            if side == "Right" then return tl.X + size.X - 1, ay, cx - w / 2 + 1, cy end
            return tl.X + 1, ay, cx + w / 2 - 1, cy
        end
        local ax = math.clamp(cx, tl.X + inset, math.max(tl.X + inset, tl.X + size.X - inset))
        if side == "Top" then return ax, tl.Y + 1, cx, cy + h / 2 - 1 end
        return ax, tl.Y + size.Y - 1, cx, cy - h / 2 + 1
    end

    local function snapTether(pod, fs)
        local t = pod.tether
        if t.mode ~= "on" and t.mode ~= "reach" then return end
        local ax, ay, bx, by = tetherEnds(pod, fs)
        t.mode, t.time = "snap", 0
        t.ax, t.ay, t.mx, t.my = ax, ay, (ax + bx) / 2, (ay + by) / 2
        if not Library.LowGraphics then
            t.drop = { x = t.mx, y = t.my, vx = pod.vx * 0.15, vy = -40, t = 0 }
        end
        playSound("Close")
    end

    local function tetherFill(inst)
        return Themed(inst, { BackgroundColor3 = function() return Glass.PaneTop:Lerp(Glass.LensTint, 0.42) end })
    end

    local function buildTether(pod)
        local root = New("Frame", {
            Name = "Tether_" .. pod.Name,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(0, 0),
            Visible = false,
            ZIndex = 89,
        }, ScreenGui)
        local function half()
            local frame = tetherFill(New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 1,
            }, root))
            Corner(frame, 999)
            local core = Themed(New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 2,
            }, frame), { BackgroundColor3 = "Accent" })
            Corner(core, 999)
            return frame, core
        end
        local function foot()
            local frame = tetherFill(New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 3,
            }, root))
            Corner(frame, 999)
            local stroke = Themed(New("UIStroke", { Thickness = 1, Transparency = 1 }, frame), { Color = "Rim" })
            return frame, stroke
        end
        local parts = { Root = root, shown = false }
        parts.HalfA, parts.CoreA = half()
        parts.HalfB, parts.CoreB = half()
        parts.FootA, parts.StrokeA = foot()
        parts.FootB, parts.StrokeB = foot()
        parts.Drop = tetherFill(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 4,
        }, root))
        Corner(parts.Drop, 999)
        pod.tetherParts = parts
        return parts
    end

    local function capsule(put, frame, x1, y1, x2, y2, thick)
        local dx, dy = x2 - x1, y2 - y1
        put(frame, "Position", UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2))
        put(frame, "Size", UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + thick, thick))
        put(frame, "Rotation", math.deg(math.atan2(dy, dx)))
    end

    local function footAt(put, frame, stroke, x, y, diameter, alpha)
        put(frame, "Position", UDim2.fromOffset(x, y))
        put(frame, "Size", UDim2.fromOffset(diameter, diameter))
        put(frame, "BackgroundTransparency", 1 - 0.9 * alpha)
        put(stroke, "Transparency", 1 - 0.5 * alpha)
    end

    local function renderTether(pod, fs)
        local t = pod.tether
        local parts = pod.tetherParts
        if t.mode == "off" and not t.drop then
            if parts and parts.shown then
                parts.Root.Visible = false
                parts.shown = false
            end
            return
        end
        parts = parts or buildTether(pod)
        if not parts.shown then
            parts.Root.Visible = true
            parts.shown = true
        end
        local put = pod.put
        local k = fs.g.k
        local foot = (math.min(8, pod.h * 0.25) + 3) * k
        if t.mode == "snap" then
            -- The bridge has torn: each stub retracts into its foot and the feet shrink away.
            local q = easeOut(t.time / 0.42)
            local _, _, bx, by = tetherEnds(pod, fs)
            local alpha = pod.alpha * (1 - q)
            capsule(put, parts.HalfA, t.ax, t.ay, t.mx + (t.ax - t.mx) * q, t.my + (t.ay - t.my) * q, 2.2 * k)
            capsule(put, parts.HalfB, bx, by, t.mx + (bx - t.mx) * q, t.my + (by - t.my) * q, 2.2 * k)
            put(parts.HalfB, "Visible", true)
            put(parts.HalfA, "BackgroundTransparency", 1 - 0.9 * alpha)
            put(parts.HalfB, "BackgroundTransparency", 1 - 0.9 * alpha)
            put(parts.CoreA, "BackgroundTransparency", 1)
            put(parts.CoreB, "BackgroundTransparency", 1)
            footAt(put, parts.FootA, parts.StrokeA, t.ax, t.ay, foot * (1 - 0.6 * q), alpha)
            footAt(put, parts.FootB, parts.StrokeB, bx, by, foot * (1 - 0.6 * q), alpha)
        elseif t.mode ~= "off" then
            local ax, ay, bx, by = tetherEnds(pod, fs)
            local footB = foot
            if t.mode == "reach" then
                -- Reaching out: the bridge grows from the window edge to the pod.
                local q = easeOut(t.time / 0.32)
                bx, by = ax + (bx - ax) * q, ay + (by - ay) * q
                footB = 4 * k + (foot - 4 * k) * q
            end
            local alpha = pod.alpha * t.fade
            local dx, dy = bx - ax, by - ay
            local len = math.max(math.sqrt(dx * dx + dy * dy), 0.001)
            -- Stretching thins it out, like the neck of a drop pulled out of a puddle.
            local thick = math.clamp(240 / math.max(len / k, 1), 2.2, 7) * k
            local glow = 0.35 + 0.4 * math.clamp(1 - len / (TETHER_SNAP * k), 0, 1)
            local coreSize = UDim2.new(1, -thick, 0, math.max(0.8, thick * 0.22))
            if Library.LowGraphics then
                capsule(put, parts.HalfA, ax, ay, bx, by, thick)
                put(parts.HalfB, "Visible", false)
            else
                local nx, ny = -dy / len, dx / len
                local sway = math.clamp((pod.vx * nx + pod.vy * ny) * 0.03, -9, 9) * k
                local mx, my = (ax + bx) / 2 + nx * sway, (ay + by) / 2 + ny * sway
                capsule(put, parts.HalfA, ax, ay, mx, my, thick)
                capsule(put, parts.HalfB, mx, my, bx, by, thick)
                put(parts.HalfB, "Visible", true)
                put(parts.CoreB, "Size", coreSize)
                put(parts.CoreB, "BackgroundTransparency", 1 - glow * alpha)
            end
            put(parts.CoreA, "Size", coreSize)
            put(parts.CoreA, "BackgroundTransparency", 1 - glow * alpha)
            put(parts.HalfA, "BackgroundTransparency", 1 - 0.9 * alpha)
            put(parts.HalfB, "BackgroundTransparency", 1 - 0.9 * alpha)
            footAt(put, parts.FootA, parts.StrokeA, ax, ay, foot, alpha)
            footAt(put, parts.FootB, parts.StrokeB, bx, by, footB, alpha)
        end
        local drop = t.drop
        if drop then
            local fade = 1 - math.clamp(drop.t / 0.9, 0, 1)
            put(parts.Drop, "Visible", true)
            put(parts.Drop, "Position", UDim2.fromOffset(drop.x, drop.y))
            put(parts.Drop, "Size", UDim2.fromOffset(7 * k, 7 * k))
            put(parts.Drop, "BackgroundTransparency", 1 - 0.85 * fade)
        else
            put(parts.Drop, "Visible", false)
        end
    end

    ---------------------------------------------------------------------------------------------------
    -- Drawing a pod
    ---------------------------------------------------------------------------------------------------
    local function paintSummary(pod)
        local kind = pod.kind
        if not pod.Built or not kind.Summary then return end
        local ok, value, unit, short = pcall(kind.Summary, pod)
        if not ok then return end
        value, unit = tostring(if value == nil then "--" else value), tostring(unit or "")
        local put = pod.put
        put(pod.PillValue, "Text", value)
        put(pod.PillUnit, "Text", unit)
        if unit ~= "" and pod.pillMeasured ~= value then
            pod.pillMeasured = value
            put(pod.PillUnit, "Position", UDim2.fromOffset(24 + textWidth(value, 13, Enum.Font.GothamBold) + 5, 0))
        end
        put(pod.MoonValue, "Text", tostring(short or value))
    end

    local function applyLayer(pod)
        local form = pod.layer
        local put = pod.put
        put(pod.Card, "Visible", form == "card" or form == "expanded")
        put(pod.Pill, "Visible", form == "pill")
        put(pod.Moon, "Visible", form == "moon")
        local radius = FORM_RADIUS[form]
        for _, corner in ipairs(pod.Corners) do put(corner, "CornerRadius", UDim.new(0, radius)) end
        put(pod.Material.Edge, "SliceScale", math.max(radius, 1) / L.SliceBaseRadius)
        pod.layerDrawn = form
        if form == "pill" or form == "moon" then paintSummary(pod) end
    end

    -- Controls only take input while their form is showing and the pod is in front.
    local function applyControls(pod, interactive)
        local put = pod.put
        local form = pod.layer
        local open = interactive and (form == "card" or form == "expanded")
        put(pod.Hit, "Visible", interactive)
        for _, control in ipairs(pod.controls) do
            put(control.Button, "Visible", open and (not control.Expanded or form == "expanded"))
        end
        put(pod.DotsHit, "Visible", open and hostOf(pod).Stack ~= nil)
    end

    local function squash(pod, sideWall, speed)
        local amount = math.clamp(speed / 1600, 0.3, 1)
        if sideWall then
            pod.sxv -= 9 * amount
            pod.syv += 7 * amount
        else
            pod.syv -= 9 * amount
            pod.sxv += 7 * amount
        end
    end

    local function podStep(self, dt)
        local fs = frameState()
        local p = place(self, fs)
        local g = fs.g
        local busy = false
        self.alphaTarget = p.alpha

        -- Position: flying free after a throw, otherwise on a spring toward its place.
        if self.Flying then
            self.flight += dt
            local speed = math.sqrt(self.vx * self.vx + self.vy * self.vy)
            if self.flight < 0.6 and speed > 260 then
                local drag = math.exp(-2.4 * dt)
                self.vx *= drag
                self.vy *= drag
                self.x += self.vx * dt
                self.y += self.vy * dt
                local w, h = self.w * self.base, self.h * self.base
                local minX, maxX = 6, math.max(6, g.screen.X - 6 - w)
                local minY, maxY = g.top + 6, math.max(g.top + 6, g.screen.Y - 6 - h)
                if self.x < minX then
                    self.x = minX
                    if self.vx < 0 then self.vx = -self.vx * 0.45 squash(self, true, speed) end
                elseif self.x > maxX then
                    self.x = maxX
                    if self.vx > 0 then self.vx = -self.vx * 0.45 squash(self, true, speed) end
                end
                if self.y < minY then
                    self.y = minY
                    if self.vy < 0 then self.vy = -self.vy * 0.45 squash(self, false, speed) end
                elseif self.y > maxY then
                    self.y = maxY
                    if self.vy > 0 then self.vy = -self.vy * 0.45 squash(self, false, speed) end
                end
            else
                self.Flying, self.Landing = false, true
                invalidate()
            end
            busy = true
        else
            local target = p.pos
            local stiffness, ratio = 260, 0.74
            if self.Carried then
                stiffness, ratio = 700, 0.85
            elseif p.moon then
                stiffness, ratio = 150, 0.7
            elseif self.Landing then
                stiffness, ratio = 200, 0.55
            end
            local damping = 2 * math.sqrt(stiffness) * ratio
            self.vx += (stiffness * (target.X - self.x) - damping * self.vx) * dt
            self.vy += (stiffness * (target.Y - self.y) - damping * self.vy) * dt
            self.x += self.vx * dt
            self.y += self.vy * dt
            local dx, dy = target.X - self.x, target.Y - self.y
            if dx * dx + dy * dy > 0.09 or math.abs(self.vx) > 2 or math.abs(self.vy) > 2 then busy = true end
        end

        -- Size morphs between forms; a wall hit squashes it for a moment.
        local size = FORM_SIZE[p.form]
        self.wv += (SIZE_K * (size.X - self.w) - SIZE_D * self.wv) * dt
        self.hv += (SIZE_K * (size.Y - self.h) - SIZE_D * self.hv) * dt
        self.w += self.wv * dt
        self.h += self.hv * dt
        if math.abs(size.X - self.w) > 0.2 or math.abs(size.Y - self.h) > 0.2 or math.abs(self.wv) > 1 or math.abs(self.hv) > 1 then
            busy = true
        end
        self.sxv += (SQUASH_K * (1 - self.sx) - SQUASH_D * self.sxv) * dt
        self.syv += (SQUASH_K * (1 - self.sy) - SQUASH_D * self.syv) * dt
        self.sx += self.sxv * dt
        self.sy += self.syv * dt
        if math.abs(1 - self.sx) > 0.002 or math.abs(1 - self.sy) > 0.002 or math.abs(self.sxv) > 0.02 or math.abs(self.syv) > 0.02 then
            busy = true
        end

        -- Content swaps form behind a quick veil, so the glass morphs while the readout changes.
        if p.form ~= self.layer then
            if self.alpha < 0.05 then
                self.layer = p.form
            else
                self.fade = math.max(0, self.fade - dt * 10)
                if self.fade <= 0.1 then self.layer = p.form end
            end
            busy = true
        elseif self.fade < 1 then
            self.fade = math.min(1, self.fade + dt * 7)
            busy = true
        end

        local lean = if self.Carried then math.clamp(self.vx * 0.012, -8, 8) else 0
        self.rotation += (lean - self.rotation) * math.min(1, dt * 14)
        local liftTarget = if self.Carried then 1 else 0
        self.lift += (liftTarget - self.lift) * math.min(1, dt * 16)
        self.alpha += (self.alphaTarget - self.alpha) * math.min(1, dt * 12)
        self.base += (p.base - self.base) * math.min(1, dt * 14)
        self.depth += (p.depth - self.depth) * math.min(1, dt * 12)
        self.dim += (p.dim - self.dim) * math.min(1, dt * 12)
        self.z = p.z
        if math.abs(self.rotation - lean) > 0.05 or math.abs(self.lift - liftTarget) > 0.01
            or math.abs(self.alpha - self.alphaTarget) > 0.01 or math.abs(self.base - p.base) > 0.001
            or math.abs(self.depth - p.depth) > 0.001 or math.abs(self.dim - p.dim) > 0.01 then
            busy = true
        end

        -- A soft light under the pointer.
        local shineTarget = 0
        if pointer and not Library.LowGraphics and self.alpha > 0.5 and not self.Carried then
            local dx = pointer.X - (self.x + self.w * self.base / 2)
            local dy = pointer.Y - (self.y + self.h * self.base / 2)
            shineTarget = math.clamp(1 - math.sqrt(dx * dx + dy * dy) / 170, 0, 1)
        end
        self.shine += (shineTarget - self.shine) * math.min(1, dt * 10)
        if math.abs(shineTarget - self.shine) > 0.004 then busy = true else self.shine = shineTarget end

        -- Tether
        local t = self.tether
        local slot = p.slot
        local want = slot ~= nil and slot.attached and p.alpha > 0 and self.alpha > 0.05
        if want then self.tetherSide = slot.side end
        if t.mode == "snap" then
            t.time += dt
            if t.time >= 0.42 then t.mode, t.fade = "off", 0 end
            busy = true
        elseif want then
            if t.mode == "off" then t.mode, t.time, t.fade = "reach", 0, 1 end
            if t.mode == "reach" then
                t.time += dt
                if t.time >= 0.32 then t.mode = "on" end
                busy = true
            end
            if t.fade < 1 then
                t.fade = math.min(1, t.fade + dt * 8)
                busy = true
            end
        elseif t.mode ~= "off" then
            t.fade = math.max(0, t.fade - dt * 8)
            if t.fade <= 0 then t.mode = "off" end
            busy = true
        end
        -- Tear away: a tethered pod pulled too far from its slot breaks free and its slot closes up.
        if t.mode == "on" and carry and carry.pod == self and carry.held then
            local ax, ay, bx, by = tetherEnds(self, fs)
            local limit = TETHER_SNAP * g.k
            if (bx - ax) ^ 2 + (by - ay) ^ 2 > limit * limit then
                carry.held = false
                self.Docked = false
                snapTether(self, fs)
                invalidate()
            end
        end
        local drop = t.drop
        if drop then
            drop.vy += 520 * dt
            drop.x += drop.vx * dt
            drop.y += drop.vy * dt
            drop.t += dt
            if drop.t >= 0.9 then t.drop = nil end
            busy = true
        end

        if p.moon and not fs.still then busy = true end -- orbiting never rests
        if busy then return true end
        if not self.Flying then
            self.x, self.y, self.vx, self.vy = p.pos.X, p.pos.Y, 0, 0
        end
        self.w, self.h, self.wv, self.hv = size.X, size.Y, 0, 0
        self.sx, self.sy, self.sxv, self.syv = 1, 1, 0, 0
        self.alpha, self.base, self.depth, self.dim = self.alphaTarget, p.base, p.depth, p.dim
        self.rotation, self.lift, self.Landing = lean, liftTarget, false
        return false
    end

    local function podRender(self)
        local put = self.put
        local fs = frameState()
        local frame = self.Frame
        local base, w, h = self.base, self.w, self.h
        local scale = base * self.depth * (1 + 0.04 * self.lift)
        local cx, cy = self.x + w * base / 2, self.y + h * base / 2
        put(frame, "Position", UDim2.fromOffset(cx, cy))
        put(frame, "Size", UDim2.fromOffset(w * self.sx, h * self.sy))
        put(self.FrameScale, "Scale", scale)
        put(frame, "Rotation", self.rotation)
        put(frame, "ZIndex", self.z)
        put(frame, "Visible", self.alpha > 0.01)
        put(self.Body, "GroupTransparency", 1 - self.alpha)
        put(self.Shadow, "ImageTransparency", 1 - (1 - Glass.ShadowTransparency) * self.alpha)
        put(self.Veil, "BackgroundTransparency", 1 - math.max(0.55 * self.dim, 0.92 * (1 - self.fade)))
        if self.layer ~= self.layerDrawn then applyLayer(self) end
        local interactive = self.Deployed and self.alpha > 0.3 and self.dim < 0.5
        local key = (if interactive then self.layer else "none") .. (if hostOf(self).Stack then "+" else "")
        if key ~= self.interactiveDrawn then
            self.interactiveDrawn = key
            applyControls(self, interactive)
        end
        if self.shine > 0.002 and pointer then
            local lx, ly = (pointer.X - cx) / scale + w / 2, (pointer.Y - cy) / scale + h / 2
            put(self.Shine, "Position", UDim2.fromOffset(lx, ly))
            put(self.Shine, "ImageTransparency", 1 - 0.5 * self.shine)
            local nx = math.clamp((lx - w / 2) * -0.02, -2, 2) * self.shine
            local ny = math.clamp((ly - h / 2) * -0.02, -2, 2) * self.shine
            put(self.Card, "Position", UDim2.fromOffset(nx, ny))
            self.shineDrawn = true
        elseif self.shineDrawn then
            put(self.Shine, "ImageTransparency", 1)
            put(self.Card, "Position", UDim2.fromOffset(0, 0))
            self.shineDrawn = false
        end
        renderTether(self, fs)
    end

    ---------------------------------------------------------------------------------------------------
    -- Stacks
    ---------------------------------------------------------------------------------------------------
    local function paintStackDots(pod)
        if not pod.Built then return end
        local host = hostOf(pod)
        local stack = host.Stack
        pod.Grip.Visible = stack == nil and not pod.Tag
        if pod.Tag then pod.Tag.Visible = stack == nil end
        pod.StackDots.Visible = stack ~= nil
        if not stack then return end
        local dots = pod.stackDotFrames
        local count = math.min(#stack, 6)
        for i = 1, math.max(count, #dots) do
            local dot = dots[i]
            if i <= count then
                if not dot then
                    dot = New("Frame", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Size = UDim2.fromOffset(5, 5),
                        BorderSizePixel = 0,
                        ZIndex = 4,
                    }, pod.StackDots)
                    Corner(dot, 3)
                    dots[i] = dot
                end
                local active = i == host.Front
                dot.Visible = true
                dot.Position = UDim2.new(1, -(count - i) * 9, 0.5, 0)
                dot.BackgroundColor3 = if active then Glass.Accent else Glass.Glyph
                dot.BackgroundTransparency = if active then 0 else 0.45
            elseif dot then
                dot.Visible = false
            end
        end
    end

    local function rebuildStack(host)
        local list = { host }
        for _, guest in ipairs(host.Guests or {}) do table.insert(list, guest) end
        if #list == 1 then
            host.Guests, host.Stack, host.Front = nil, nil, 1
        else
            host.Stack = list
            host.Front = math.clamp(host.Front or 1, 1, #list)
        end
        for _, member in ipairs(list) do paintStackDots(member) end
    end

    local function joinStack(pod, target)
        local host = hostOf(target)
        if host == pod or pod.Guests then return false end
        pod.Host = host
        pod.Docked, pod.Corner, pod.Flying = false, nil, false
        host.Guests = host.Guests or {}
        table.insert(host.Guests, pod)
        host.Front = #host.Guests + 1 -- the newcomer goes on top
        rebuildStack(host)
        invalidate()
        return true
    end

    -- Takes a pod out of its stack. If it was the host, the next pod inherits its place.
    local function leaveStack(pod)
        if pod.Host then
            local host = pod.Host
            local index = table.find(host.Guests, pod)
            if index then table.remove(host.Guests, index) end
            if host.Front and host.Front > (index or 0) + 1 then host.Front -= 1 end
            pod.Host = nil
            pod.Form = host.Form
            rebuildStack(host)
            paintStackDots(pod)
        elseif pod.Guests and #pod.Guests > 0 then
            local heir = table.remove(pod.Guests, 1)
            heir.Host = nil
            heir.Guests = pod.Guests
            for _, guest in ipairs(heir.Guests) do guest.Host = heir end
            heir.Docked, heir.Side, heir.Order = pod.Docked, pod.Side, pod.Order
            heir.Corner, heir.CornerOrder, heir.Form = pod.Corner, pod.CornerOrder, pod.Form
            heir.tx, heir.ty = pod.tx, pod.ty
            heir.Front = math.max(1, (pod.Front or 1) - 1)
            pod.Guests, pod.Stack, pod.Front = nil, nil, 1
            rebuildStack(heir)
            paintStackDots(pod)
        end
        invalidate()
    end

    local function cycleStack(pod, step)
        local host = hostOf(pod)
        local stack = host.Stack
        if not stack then return end
        host.Front = (host.Front - 1 + step) % #stack + 1
        for _, member in ipairs(stack) do paintStackDots(member) end
        playSound("Hover")
        invalidate()
        wakeAll()
    end

    ---------------------------------------------------------------------------------------------------
    -- Live data
    ---------------------------------------------------------------------------------------------------
    local function refreshPod(pod)
        if not pod.Built then return end
        local kind = pod.kind
        if kind.Refresh then
            local ok, err = pcall(kind.Refresh, pod, pod.inst)
            if not ok and not pod.refreshFailed then
                pod.refreshFailed = true
                warn("[FishyUI] attachment " .. pod.Name .. ": " .. tostring(err))
            end
        end
        if pod.layerDrawn == "pill" or pod.layerDrawn == "moon" then paintSummary(pod) end
    end

    local function showing(pod)
        return pod.Built and (pod.alpha > 0.01 or pod.alphaTarget > 0)
    end

    -- Kinds that move every frame (radar sweep, coordinates, the speed gauge) share one Heartbeat, which
    -- only exists while a pod with live data is deployed.
    local liveConnection
    local function syncLive()
        local any = false
        for _, pod in ipairs(pods) do
            if pod.Deployed and pod.kind.Live then
                any = true
                break
            end
        end
        if any and not liveConnection and not Library.Unloaded then
            liveConnection = Library:GiveSignal(RunService.Heartbeat:Connect(function(dt)
                for _, pod in ipairs(pods) do
                    local live = pod.kind.Live
                    if live and pod.Built and pod.alpha > 0.01 and not pod.liveFailed then
                        local ok, err = pcall(live, pod, pod.inst, dt)
                        if not ok then
                            pod.liveFailed = true
                            warn("[FishyUI] attachment " .. pod.Name .. ": " .. tostring(err))
                        end
                    end
                end
            end))
        elseif not any and liveConnection then
            liveConnection:Disconnect()
            liveConnection = nil
        end
    end

    ---------------------------------------------------------------------------------------------------
    -- Carrying, dropping, throwing
    ---------------------------------------------------------------------------------------------------
    local function podGlow(pod, on, color)
        if not pod.Built then return end
        local stroke = pod.RingStroke
        if on then stroke.Color = color or Glass.Accent end
        Tween(stroke, Motion.Hover, { Transparency = if on then 0.15 elseif pod.Alert then 0.45 else 1 })
    end

    -- The pod under a screen point, ignoring cards at the back of a stack and moons.
    local function podAt(point, except)
        local found
        for _, pod in ipairs(pods) do
            if pod ~= except and pod.Built and pod.Deployed and pod.alpha > 0.5 and pod.layer ~= "moon"
                and not pod.Carried and not pod.Flying and stackDepth(pod) == 0 then
                local scale = pod.base * pod.depth
                local dx = point.X - (pod.x + pod.w * pod.base / 2)
                local dy = point.Y - (pod.y + pod.h * pod.base / 2)
                if math.abs(dx) <= pod.w * scale / 2 and math.abs(dy) <= pod.h * scale / 2 then found = hostOf(pod) end
            end
        end
        return found
    end

    local function renumber(side)
        local g = geometry()
        local column = {}
        for _, other in ipairs(pods) do
            if other.Deployed and other.Docked and not other.Host and renderSide(other.Side, g) == side then
                table.insert(column, other)
            end
        end
        table.sort(column, byOrder)
        for i, member in ipairs(column) do member.Order = i end
    end

    local function beginCarry(pod)
        if carry then return end
        -- Lifting a pod out of a stack leaves the stack where it is; the next pod inherits its place.
        local stacked = pod.Host ~= nil or pod.Guests ~= nil
        if stacked then leaveStack(pod) end
        local moon = pod.layer == "moon"
        -- A pod lifted off its dock stays tethered, and its slot stays open, until the bridge tears.
        local held = not stacked and pod.Docked and windowShown and not moon and pod.tether.mode == "on"
        pod.Carried, pod.Landing, pod.Flying = true, false, false
        pod.Corner = nil
        if not held then pod.Docked = false end
        pod.tx, pod.ty = pod.x, pod.y
        carry = { pod = pod, held = held, side = nil, index = 1, samples = {} }
        invalidate()
        wakeAll()
    end

    local function moveCarry(pod, topLeft, point)
        if not carry or carry.pod ~= pod then return end
        local samples = carry.samples
        table.insert(samples, { t = os.clock(), p = topLeft })
        if #samples > 10 then table.remove(samples, 1) end
        local over = point and podAt(point, pod)
        if carry.held and over then
            -- Carried onto another pod while still tethered: the bridge tears so the two can stack.
            carry.held = false
            pod.Docked = false
            snapTether(pod, frameState())
        end
        if not carry.held then
            local g = geometry()
            if over ~= carry.stackOn then
                if carry.stackOn then podGlow(carry.stackOn, false) end
                carry.stackOn = over
                if over then
                    podGlow(over, true)
                    playSound("Hover")
                end
            end
            carry.side = nil
            if not over and windowShown then
                local size = FORM_SIZE[pod.Form] * g.k
                local best, bestDistance
                for _, side in ipairs(SIDES) do
                    local rendered = renderSide(side, g)
                    local origin = sideOrigin(rendered, size.X, size.Y, g)
                    local vertical = isVertical(rendered)
                    local distance = if vertical then math.abs(topLeft.X - origin.X) else math.abs(topLeft.Y - origin.Y)
                    local alongside = if vertical
                        then topLeft.Y > g.tl.Y - size.Y - 40 and topLeft.Y < g.tl.Y + g.size.Y + 40
                        else topLeft.X > g.tl.X - size.X - 40 and topLeft.X < g.tl.X + g.size.X + 40
                    if alongside and distance < POD_MAGNET and (not best or distance < bestDistance) then
                        best, bestDistance = rendered, distance
                    end
                end
                if best then
                    carry.side, carry.index = best, math.huge
                    local vertical = isVertical(best)
                    local mine = if vertical then topLeft.Y + size.Y / 2 else topLeft.X + size.X / 2
                    local index = 1
                    for member, slot in pairs(dockSlots(g)) do
                        if slot.side == best then
                            local s = FORM_SIZE[member.Form] * g.k
                            local middle = if vertical then slot.pos.Y + s.Y / 2 else slot.pos.X + s.X / 2
                            if mine > middle then index += 1 end
                        end
                    end
                    carry.index = index
                    dockSlots(g) -- fills carry.slot for that index
                    local offset = carry.slot.pos - topLeft
                    local pull = math.clamp(1 - offset.Magnitude / POD_MAGNET, 0, 1)
                    topLeft += offset * pull * pull
                end
            end
        end
        pod.tx, pod.ty = topLeft.X, topLeft.Y
        invalidate()
        wakeAll()
    end

    -- Release speed from the last tenth of a second of the drag. A pointer that stopped before letting
    -- go has no speed, however fast it moved earlier.
    local function releaseVelocity(samples)
        local last = samples[#samples]
        if not last or os.clock() - last.t > 0.1 then return Vector2.zero end
        local first = last
        for i = #samples, 1, -1 do
            if last.t - samples[i].t > 0.1 then break end
            first = samples[i]
        end
        local span = last.t - first.t
        if span < 1 / 120 then return Vector2.zero end
        return (last.p - first.p) / span
    end

    local function throw(pod, velocity)
        local speed = velocity.Magnitude
        if speed > 3200 then velocity *= 3200 / speed end
        local fs = frameState()
        snapTether(pod, fs)
        pod.Flying, pod.flight, pod.Landing, pod.Docked = true, 0, false, false
        pod.vx, pod.vy = velocity.X, velocity.Y
        local g = fs.g
        local cx = pod.x + pod.w * pod.base / 2 + velocity.X * 0.3
        local cy = pod.y + pod.h * pod.base / 2 + velocity.Y * 0.3
        local corner = (if cy > g.screen.Y / 2 then "Bottom" else "Top") .. (if cx > g.screen.X / 2 then "Right" else "Left")
        local first = 0
        for _, other in ipairs(pods) do
            if other ~= pod and other.Corner == corner then first = math.min(first, other.CornerOrder) end
        end
        pod.Corner, pod.CornerOrder = corner, first - 1
        pod.Form = "pill"
        playSound("Open")
    end

    local function endCarry(pod)
        if not carry or carry.pod ~= pod then return end
        local c = carry
        carry = nil
        if c.stackOn then podGlow(c.stackOn, false) end
        local velocity = releaseVelocity(c.samples)
        pod.Carried = false
        if c.stackOn and not c.held and joinStack(pod, c.stackOn) then
            playSound("Deploy")
        elseif velocity.Magnitude > THROW_SPEED then
            throw(pod, velocity)
        elseif c.held then
            pod.Landing = true -- springs back into its slot
        elseif c.side then
            pod.Side, pod.Docked, pod.Landing = c.side, true, true
            pod.Order = c.index - 0.5 -- between its new neighbours; renumbered so the order sticks
            renumber(c.side)
        else
            pod.Docked, pod.Landing = false, true
            local g = geometry()
            local size = FORM_SIZE[pod.Form] * g.k
            local settled = clampBox(Vector2.new(pod.tx, pod.ty), size.X, size.Y, g)
            pod.tx, pod.ty = settled.X, settled.Y
        end
        invalidate()
        wakeAll()
    end

    -- Clicking a pod cycles its form; a moon restores the window instead.
    local function tapPod(pod)
        if pod.layer == "moon" then
            Library:Toggle(true)
            return
        end
        local host = hostOf(pod)
        local front = (host.Stack and host.Stack[host.Front]) or host
        local order = if front.kind.Expands then { "card", "expanded", "pill" } else { "card", "pill" }
        local index = table.find(order, host.Form) or 0
        host.Form = order[index % #order + 1]
        playSound("Press")
        invalidate()
        wakeAll()
        if host.Form ~= "pill" then refreshPod(front) end
    end

    ---------------------------------------------------------------------------------------------------
    -- Building a pod
    ---------------------------------------------------------------------------------------------------
    local function wireInput(pod)
        pod.Hit.InputBegan:Connect(function(input)
            if not isPointer(input) or carry then return end
            local start = input.Position
            local grab = screenPoint(input) - Vector2.new(pod.x, pod.y)
            local lifted = false
            local moveConnection, endConnection
            moveConnection = UserInputService.InputChanged:Connect(function(changed)
                if not isMove(changed) then return end
                local delta = changed.Position - start
                if not lifted then
                    if delta.Magnitude < L.DragSlop or carry then return end
                    lifted = true
                    if pod.layer == "moon" then grab = Vector2.new(POD_W / 2, 14) * Scale.Scale end
                    beginCarry(pod)
                end
                local point = screenPoint(changed)
                moveCarry(pod, point - grab, point)
            end)
            endConnection = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then return end
                moveConnection:Disconnect()
                endConnection:Disconnect()
                if lifted then endCarry(pod) else tapPod(pod) end
            end)
        end)
        pod.Hit.MouseWheelForward:Connect(function() cycleStack(pod, -1) end)
        pod.Hit.MouseWheelBackward:Connect(function() cycleStack(pod, 1) end)
        pod.DotsHit.MouseButton1Click:Connect(function() cycleStack(pod, 1) end)
    end

    local function unpinButton(pod)
        local button = pod:Control({
            Name = "Unpin",
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -8, 1, -8),
            Size = UDim2.fromOffset(14, 14),
            ZIndex = 26,
        })
        local bars = {}
        for i, rotation in ipairs({ 45, -45 }) do
            bars[i] = Themed(New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(10, 1.5),
                Rotation = rotation,
                BackgroundTransparency = 0.45,
                BorderSizePixel = 0,
                ZIndex = 26,
            }, button), { BackgroundColor3 = "Glyph" })
            Corner(bars[i], 1)
        end
        button.MouseEnter:Connect(function()
            for _, bar in ipairs(bars) do
                Tween(bar, Motion.Hover, { BackgroundTransparency = 0, BackgroundColor3 = Glass.Danger })
            end
        end)
        button.MouseLeave:Connect(function()
            for _, bar in ipairs(bars) do
                Tween(bar, Motion.Hover, { BackgroundTransparency = 0.45, BackgroundColor3 = Glass.Glyph })
            end
        end)
        button.MouseButton1Click:Connect(function() pod:Remove() end)
    end

    local function buildShell(pod)
        if pod.Built then return end
        pod.Built = true
        pod.put = PropertyCache()
        local frame = New("Frame", {
            Name = "Satellite_" .. pod.Name,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(POD_W, POD_H),
            Visible = false,
            ZIndex = 92,
        }, ScreenGui)
        pod.Frame = frame
        pod.FrameScale = New("UIScale", { Scale = Scale.Scale }, frame)
        pod.Shadow = GlassShadow(frame, 14, 1, 0)

        -- The body is a CanvasGroup purely so the pod can fade in and out as one object via
        -- GroupTransparency. Nothing decorative may be attached to it directly: a UIGradient parented to a
        -- CanvasGroup multiplies over everything the group renders, children included, so PaneMaterial's
        -- pane gradient (near-black on most themes) would crush the pod's own readout to black no matter
        -- how bright the text colour is. The glass therefore lives on an inner Frame, where the gradient
        -- only tints that frame's background, exactly as it does on the window.
        local body = New("CanvasGroup", {
            Name = "Body",
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            GroupTransparency = 1,
            ZIndex = 2,
        }, frame)
        pod.Body = body
        local surface = New("Frame", { Name = "Surface", Size = UDim2.fromScale(1, 1), ZIndex = 1 }, body)
        pod.Material = PaneMaterial(surface, 12, 40)
        -- Pods float over the game, so keep the glass mostly opaque or the readout washes out on
        -- see-through themes (Glacier, Smoke, Aurora) and light ones (Frost).
        Themed(surface, { BackgroundTransparency = function() return math.min(Glass.PaneTransparency, 0.04) end })
        -- A flat wash of the theme's deepest pane colour under the content. The pane gradient alone runs
        -- bright at the top on several themes, which is exactly where a pod's title sits.
        local wash = Themed(New("Frame", {
            Name = "Wash",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 0.62,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, body), { BackgroundColor3 = "PaneBottom" })
        -- The veil darkens a card at the back of a stack and covers the content while it changes form.
        local veil = Themed(New("Frame", {
            Name = "Veil",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 30,
        }, body), { BackgroundColor3 = "PaneBottom" })
        pod.Veil = veil
        local shine = Themed(New("ImageLabel", {
            Name = "Specular", -- decorative: low graphics mode hides it with the other glints
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(240, 240),
            BackgroundTransparency = 1,
            Image = Assets.Spark,
            ImageTransparency = 1,
            ZIndex = 29,
        }, body), { ImageColor3 = "LensTint" })
        decor(shine)
        pod.Shine = shine
        -- A ring of light just inside the rim, for stacking targets and reactive pods.
        local ring = New("Frame", {
            Name = "Ring",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, -3, 1, -3),
            BackgroundTransparency = 1,
            ZIndex = 31,
        }, body)
        pod.RingStroke = New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Thickness = 1.5,
            Transparency = 1,
            Color = Glass.Accent,
        }, ring)
        pod.Corners = { pod.Material.Corner, Corner(wash, 12), Corner(veil, 12), Corner(ring, 11) }

        -- Card: the title row and the kind's content. It is as tall as the expanded form; the body clips
        -- whatever the current form has no room for.
        local card = New("Frame", {
            Name = "Card",
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(POD_W, EXPANDED_H),
            ZIndex = 3,
        }, body)
        pod.Card = card
        local alertColor = function() return pod.Alert and Glass.Warning or Glass.Accent end
        pod.TitleDot = Themed(New("Frame", {
            Position = UDim2.fromOffset(12, 14),
            Size = UDim2.fromOffset(5, 5),
            BorderSizePixel = 0,
            ZIndex = 3,
        }, card), { BackgroundColor3 = alertColor })
        Corner(pod.TitleDot, 3)
        pod.TitleLabel = Themed(Text(card, {
            Text = pod.Title,
            TextSize = 11,
            Position = UDim2.fromOffset(23, 8),
            Size = UDim2.new(1, -50, 0, 16),
            ZIndex = 3,
        }), { TextColor3 = POD_LABEL })
        pod.Grip = New("Frame", { Name = "Grip", BackgroundTransparency = 1, Size = UDim2.fromOffset(POD_W, 24), ZIndex = 3 }, card)
        for i = 0, 2 do
            local grip = Themed(New("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.fromOffset(POD_W - 12 - i * 5, 15),
                Size = UDim2.fromOffset(3, 3),
                BackgroundTransparency = 0.35,
                BorderSizePixel = 0,
                ZIndex = 3,
            }, pod.Grip), { BackgroundColor3 = "Glyph" })
            Corner(grip, 2)
        end
        -- An optional short readout at the right of the title row, in place of the grip.
        if pod.kind.Tag then
            pod.TitleLabel.Size = UDim2.new(1, -60, 0, 16)
            pod.Tag = PodKinds.Label(card, {
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Right,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.fromOffset(POD_W - 12, 8),
                Size = UDim2.fromOffset(70, 16),
            })
        end
        pod.StackDots = New("Frame", {
            Name = "StackDots",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.fromOffset(POD_W - 12, 13),
            Size = UDim2.fromOffset(60, 6),
            BackgroundTransparency = 1,
            Visible = false,
            ZIndex = 3,
        }, card)
        pod.stackDotFrames = {}

        -- Pill: one live number.
        local pill = New("Frame", { Name = "Pill", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 3 }, body)
        pod.Pill = pill
        pod.PillDot = Themed(New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 12, 0.5, 0),
            Size = UDim2.fromOffset(6, 6),
            BorderSizePixel = 0,
            ZIndex = 3,
        }, pill), { BackgroundColor3 = alertColor })
        Corner(pod.PillDot, 3)
        pod.PillValue = PodKinds.Value(pill, { TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -34, 1, 0) })
        pod.PillUnit = PodKinds.Label(pill, { Position = UDim2.fromOffset(60, 0), Size = UDim2.new(0, 70, 1, 0) })

        -- Moon: a number and a caption, for orbiting the bubble.
        local moon = New("Frame", { Name = "Moon", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 3 }, body)
        pod.Moon = moon
        pod.MoonValue = PodKinds.Value(moon, {
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Center,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, -5),
            Size = UDim2.new(1, -6, 0, 16),
        })
        PodKinds.Label(moon, {
            Text = pod.kind.Moon or pod.Title:sub(1, 4),
            TextSize = 8,
            TextXAlignment = Enum.TextXAlignment.Center,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 9),
            Size = UDim2.new(1, -6, 0, 10),
        })

        pod.Hit = New("TextButton", {
            Name = "Hitbox",
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 20,
        }, frame)
        pod.DotsHit = New("TextButton", {
            Name = "StackCycle",
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -4, 0, 2),
            Size = UDim2.fromOffset(72, 24),
            Visible = false,
            ZIndex = 26,
        }, frame)
        wireInput(pod)

        local ok, result = pcall(pod.kind.Build, pod, card)
        pod.inst = if ok and typeof(result) == "table" then result else {}
        if not ok then warn("[FishyUI] attachment " .. pod.Name .. " failed to build: " .. tostring(result)) end
        if pod.Pinned then unpinButton(pod) end
        paintStackDots(pod)
    end

    ---------------------------------------------------------------------------------------------------
    -- Pods
    ---------------------------------------------------------------------------------------------------
    local function podDeploy(self, atPosition)
        buildShell(self)
        local was = self.Deployed
        self.Deployed = true
        if atPosition then
            if self.Host or self.Guests then leaveStack(self) end
            self.Docked, self.Corner, self.Flying = false, nil, false
            self.tx, self.ty = atPosition.X, atPosition.Y
            if not was then
                local size = FORM_SIZE[self.Form]
                self.x, self.y, self.vx, self.vy = atPosition.X, atPosition.Y, 0, 0
                self.w, self.h, self.wv, self.hv = size.X, size.Y, 0, 0
                self.base, self.depth, self.layer = Scale.Scale, 1, self.Form
            end
        elseif not was then
            self.Docked, self.Corner, self.Flying = true, nil, false
            invalidate()
            local p = place(self, frameState())
            local size = FORM_SIZE[p.form]
            self.w, self.h, self.wv, self.hv = size.X, size.Y, 0, 0
            self.base, self.depth, self.layer = p.base, p.depth, p.form
            self.x, self.y, self.vx, self.vy = p.pos.X, p.pos.Y, 0, 0
            -- Start tucked under the window edge so the pod slides out of it.
            local slot = p.slot
            if slot then
                local side, k = slot.side, p.base
                if side == "Left" then
                    self.x += size.X * 0.4 * k
                elseif side == "Right" then
                    self.x -= size.X * 0.4 * k
                elseif side == "Top" then
                    self.y += size.Y * 0.4 * k
                else
                    self.y -= size.Y * 0.4 * k
                end
            end
        end
        if not was then
            playSound("Deploy")
            self.tether.mode, self.tether.fade = "off", 0
            refreshPod(self)
            syncLive()
        end
        invalidate()
        wakeAll()
        return self
    end

    local function podStow(self)
        if self.Deployed then playSound("Close") end
        if self.Host or self.Guests then leaveStack(self) end
        if carry and carry.pod == self then
            if carry.stackOn then podGlow(carry.stackOn, false) end
            carry = nil
        end
        self.Deployed, self.Carried, self.Flying = false, false, false
        syncLive()
        invalidate()
        wakeAll()
        return self
    end

    -- Pinned and script-made pods can be thrown away again; the built-in kinds never are.
    local function podRemove(self)
        podStow(self)
        if self.Unbind then self.Unbind() end
        if self.Name == "QuickActions" then return end
        local index = table.find(pods, self)
        if index then table.remove(pods, index) end
        byName[self.Name] = nil
        self.Removed = true
        if self.Built then
            Animator.Wake(self)
            task.delay(0.4, function()
                self.Frame:Destroy()
                if self.tetherParts then self.tetherParts.Root:Destroy() end
            end)
        end
    end

    local function makePod(name, kind, options)
        options = options or {}
        local side = options.Side or kind.Side
        local pod = {
            Name = name,
            kind = kind,
            Title = options.Title or kind.Title or name:upper(),
            Side = if table.find(SIDES, side) then side else "Right",
            Order = #pods + 1, -- position within its side's column; drag-and-drop rewrites it
            Form = "card",
            Deployed = false, Docked = true, Corner = nil, CornerOrder = 0,
            Carried = false, Flying = false, Landing = false,
            Object = options.Object, Pinned = options.Pinned == true, W = W,
            state = {}, controls = {}, place = {},
            x = 0, y = 0, vx = 0, vy = 0, tx = 0, ty = 0, rotation = 0, lift = 0, alpha = 0, alphaTarget = 0,
            w = POD_W, h = POD_H, wv = 0, hv = 0, sx = 1, sy = 1, sxv = 0, syv = 0,
            base = Scale.Scale, depth = 1, dim = 0, z = 92, fade = 1, shine = 0, layer = "card", flight = 0,
            tether = { mode = "off", time = 0, fade = 0 },
        }
        pod.Step, pod.Render = podStep, podRender
        pod.Deploy, pod.Stow, pod.Remove = podDeploy, podStow, podRemove
        pod.BeginCarry = function() beginCarry(pod) end
        pod.MoveCarry = function(topLeft, point) moveCarry(pod, topLeft, point) end
        pod.EndCarry = function() endCarry(pod) end

        -- A transparent button over part of the card that belongs to a control rather than to dragging.
        function pod:Control(props, expandedOnly)
            local button = New("TextButton", {
                Name = "Control",
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Visible = false,
                ZIndex = 25,
            }, nil)
            for key, value in pairs(props) do button[key] = value end
            button.Parent = self.Frame
            table.insert(self.controls, { Button = button, Expanded = expandedOnly == true })
            self.interactiveDrawn = nil
            if self.Deployed then Animator.Wake(self) end
            return button
        end
        function pod:RemoveControl(button)
            for i, control in ipairs(self.controls) do
                if control.Button == button then
                    table.remove(self.controls, i)
                    break
                end
            end
            button:Destroy()
        end
        function pod:RefreshSummary()
            if self.layerDrawn == "pill" or self.layerDrawn == "moon" then paintSummary(self) end
        end
        function pod:Refresh()
            if showing(self) then refreshPod(self) end
        end
        function pod:Push(value) -- a new value for a script-made pod
            local state = self.state
            state.value = value
            if typeof(value) == "number" then
                state.history = state.history or {}
                table.insert(state.history, value)
                if #state.history > GRAPH_BARS then table.remove(state.history, 1) end
            end
            if showing(self) then refreshPod(self) end
        end
        function pod:SetForm(form)
            if form ~= "card" and form ~= "expanded" and form ~= "pill" then return end
            hostOf(self).Form = form
            invalidate()
            wakeAll()
        end
        function pod:SetAlert(on)
            on = on == true
            if self.Alert == on then return end
            self.Alert = on
            if not self.Built then return end
            local color = if on then Glass.Warning else Glass.Accent
            self.TitleDot.BackgroundColor3 = color
            self.PillDot.BackgroundColor3 = color
            self.RingStroke.Color = Glass.Warning
            Tween(self.RingStroke, Motion.Settle, { Transparency = if on then 0.45 else 1 })
        end
        function pod:Flash(color)
            if not self.Built then return end
            local stroke = self.RingStroke
            stroke.Color = color or Glass.Accent
            stroke.Transparency = 0.05
            Tween(stroke, TweenInfo.new(0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Transparency = if self.Alert then 0.45 else 1,
            })
        end
        -- A ring of light swelling out from a point on the card. Two are reused in turn.
        function pod:Ripple(x, y, color)
            if not self.Built or Library.LowGraphics or self.alpha < 0.5 then return end
            self.ripples = self.ripples or {}
            self.rippleIndex = (self.rippleIndex or 0) % 2 + 1
            local ripple = self.ripples[self.rippleIndex]
            if not ripple then
                local frame = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    ZIndex = 28,
                }, self.Body)
                Corner(frame, 999)
                ripple = { Frame = frame, Stroke = New("UIStroke", { Thickness = 1.5, Transparency = 1 }, frame) }
                self.ripples[self.rippleIndex] = ripple
            end
            ripple.Frame.Position = UDim2.fromOffset(x, y)
            ripple.Frame.Size = UDim2.fromOffset(8, 8)
            ripple.Stroke.Color = color or Glass.Accent
            ripple.Stroke.Transparency = 0.2
            Tween(ripple.Frame, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(120, 120) })
            Tween(ripple.Stroke, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1 })
        end

        table.insert(pods, pod)
        byName[name] = pod
        return pod
    end

    for _, name in ipairs(PodKinds.Order) do
        makePod(name, PodKinds.List[name])
    end

    Telemetry.OnTick(function()
        for _, pod in ipairs(pods) do
            if showing(pod) then refreshPod(pod) end
        end
        if W.DockTick then W.DockTick() end
    end)

    -- The light that follows the pointer only wakes pods near it.
    Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement or Library.LowGraphics then return end
        local point = screenPoint(input)
        pointer = point
        for _, pod in ipairs(pods) do
            if pod.Built and pod.alpha > 0.5 then
                local dx = point.X - (pod.x + pod.w * pod.base / 2)
                local dy = point.Y - (pod.y + pod.h * pod.base / 2)
                if dx * dx + dy * dy < 48400 or pod.shine > 0.002 then Animator.Wake(pod) end
            end
        end
    end))

    ---------------------------------------------------------------------------------------------------
    -- Pinning controls
    ---------------------------------------------------------------------------------------------------
    -- `spec` is { Kind = "Toggle" | "Slider" | "Dropdown" | "Label" | "Button", Key, Title, Object }.
    function W.PinControl(spec)
        if spec.Kind == "Button" then
            local list = W.QuickActions
            local pod = byName.QuickActions
            if not table.find(list, spec.Object) then
                if #list >= 10 then
                    Library:Notify({ Title = "Quick actions", Description = "The pad is full; right-click a shortcut on it to remove one.", Time = 3 })
                    return pod
                end
                table.insert(list, spec.Object)
            end
            if pod then
                pod:Deploy()
                refreshPod(pod)
            end
            if not spec.Quiet then
                Library:Notify({ Title = "Pinned", Description = tostring(spec.Title) .. " is on the Quick actions pad.", Time = 3 })
            end
            return pod
        end
        local kind = PodKinds.Pins[spec.Kind]
        if not kind or not spec.Object then return nil end
        local name = "Pin_" .. tostring(spec.Key)
        local existing = byName[name]
        if existing then
            if not existing.Deployed then existing:Deploy() end
            return existing
        end
        local title = tostring(spec.Title or "Control"):gsub("<[^>]->", "")
        local pod = makePod(name, kind, { Title = title:upper():sub(1, 28), Object = spec.Object, Pinned = true })
        pod.PinSpec = { Kind = spec.Kind, Key = spec.Key }
        pod:Deploy()
        if not spec.Quiet then
            Library:Notify({ Title = "Pinned", Description = title .. " is now an attachment.", Time = 3 })
        end
        return pod
    end

    ---------------------------------------------------------------------------------------------------
    -- Script-made pods
    ---------------------------------------------------------------------------------------------------
    function W.AddAttachment(spec)
        spec = if typeof(spec) == "table" then spec else { Title = tostring(spec) }
        local name = "Custom_" .. tostring(spec.Name or spec.Title or ("Pod " .. (#pods + 1)))
        local existing = byName[name]
        if existing and existing.Handle then return existing.Handle end
        local kind = PodKinds.Custom(spec)
        local pod = makePod(name, kind, { Title = kind.Title, Side = kind.Side })
        local handle = { Pod = pod, Name = name }
        pod.Handle = handle
        function handle:SetValue(value) pod:Push(value) return self end
        function handle:GetValue() return pod.state.value end
        function handle:Deploy(position) pod:Deploy(position) return self end
        function handle:Stow() pod:Stow() return self end
        function handle:Remove() pod:Remove() end
        function handle:SetForm(form) pod:SetForm(form) return self end
        function handle:SetTitle(text)
            pod.Title = tostring(text):upper()
            if pod.Built then pod.TitleLabel.Text = pod.Title end
            return self
        end
        if spec.Default ~= nil then pod:Push(spec.Default) end
        if spec.Deploy then pod:Deploy() end
        syncLive()
        return handle
    end

    ---------------------------------------------------------------------------------------------------
    -- Saved layouts: where every pod sits, its form and its stack, by name
    ---------------------------------------------------------------------------------------------------
    local MAX_LAYOUTS = 8

    local function layoutNames()
        local names = {}
        for name in pairs(Prefs.PodLayouts) do table.insert(names, name) end
        table.sort(names)
        return names
    end

    local function captureLayout()
        local g = geometry()
        local sx, sy = math.max(1, g.screen.X), math.max(1, g.screen.Y)
        local data = {}
        for _, pod in ipairs(pods) do
            if pod.Deployed then
                local entry = {
                    Form = pod.Form, Side = pod.Side, Order = pod.Order, Docked = pod.Docked == true,
                    Corner = pod.Corner, CornerOrder = pod.CornerOrder,
                    X = pod.tx / sx, Y = pod.ty / sy,
                    Host = pod.Host and pod.Host.Name or nil,
                    Front = if pod.Stack then pod.Front else nil,
                }
                if pod.Carried then entry.Docked = pod.Docked or (carry ~= nil and carry.held) end
                if pod.PinSpec then entry.Pin = { Kind = pod.PinSpec.Kind, Key = pod.PinSpec.Key } end
                data[pod.Name] = entry
            end
        end
        return data
    end

    local function applyLayout(data)
        if carry then
            local pod = carry.pod
            if carry.stackOn then podGlow(carry.stackOn, false) end
            carry = nil
            pod.Carried = false
        end
        for _, pod in ipairs(pods) do
            pod.Host, pod.Guests, pod.Stack, pod.Front = nil, nil, nil, 1
            paintStackDots(pod)
        end
        -- Pinned controls named by the layout that this session hasn't pinned yet.
        for name, entry in pairs(data) do
            if not byName[name] and typeof(entry) == "table" and typeof(entry.Pin) == "table" then
                local key = entry.Pin.Key
                local object = Library.Toggles[key] or Library.Options[key] or Library.Labels[key]
                if object then
                    W.PinControl({ Kind = entry.Pin.Kind, Key = key, Title = object.Text, Object = object, Quiet = true })
                end
            end
        end
        local g = geometry()
        for _, pod in ipairs(pods) do
            local entry = data[pod.Name]
            if typeof(entry) == "table" then
                if not pod.Deployed then pod:Deploy() end
                pod.Form = if entry.Form == "expanded" or entry.Form == "pill" then entry.Form else "card"
                pod.Side = if table.find(SIDES, entry.Side) then entry.Side else pod.Side
                pod.Order = tonumber(entry.Order) or pod.Order
                pod.Docked = entry.Docked == true
                pod.Corner = if CORNERS[entry.Corner] then entry.Corner else nil
                pod.CornerOrder = tonumber(entry.CornerOrder) or 0
                pod.Flying, pod.Landing = false, true
                local x, y = tonumber(entry.X), tonumber(entry.Y)
                if x and y then pod.tx, pod.ty = x * g.screen.X, y * g.screen.Y end
            elseif pod.Deployed then
                pod:Stow()
            end
        end
        for _, pod in ipairs(pods) do
            local entry = data[pod.Name]
            if typeof(entry) == "table" and entry.Host and byName[entry.Host] then joinStack(pod, byName[entry.Host]) end
        end
        for _, pod in ipairs(pods) do
            local entry = data[pod.Name]
            if pod.Stack and typeof(entry) == "table" and tonumber(entry.Front) then
                pod.Front = math.clamp(tonumber(entry.Front), 1, #pod.Stack)
                for _, member in ipairs(pod.Stack) do paintStackDots(member) end
            end
        end
        invalidate()
        wakeAll()
    end

    function W.SaveLayout(name)
        name = tostring(name or ""):match("^%s*(.-)%s*$"):sub(1, 24)
        local layouts = Prefs.PodLayouts
        if name == "" then name = "Layout " .. (#layoutNames() + 1) end
        if not layouts[name] and #layoutNames() >= MAX_LAYOUTS then
            Library:Notify({ Title = "Layouts", Description = "Eight layouts saved already; right-click one to delete it.", Time = 3 })
            return false
        end
        layouts[name] = captureLayout()
        savePrefs()
        return name
    end

    function W.LoadLayout(name)
        local data = Prefs.PodLayouts[name]
        if typeof(data) ~= "table" then return false end
        applyLayout(data)
        return true
    end

    function W.DeleteLayout(name)
        if Prefs.PodLayouts[name] == nil then return false end
        Prefs.PodLayouts[name] = nil
        savePrefs()
        return true
    end

    ---------------------------------------------------------------------------------------------------
    -- The dock: the Attachments popup in the header
    --
    -- Every pod as a small live tile. Hovering magnifies a tile and nudges its neighbours; click a tile to
    -- deploy or stow it, or drag it off the dock to place it by hand. Saved layouts sit along the bottom.
    ---------------------------------------------------------------------------------------------------
    local DOCK_COLUMNS, DOCK_TILE_W, DOCK_TILE_H, DOCK_GAP, DOCK_ROWS = 4, 92, 60, 8, 4

    function W.OpenAttachments(anchor)
        local list = table.clone(pods)
        local rows = math.max(1, math.ceil(#list / DOCK_COLUMNS))
        local shownRows = math.min(rows, DOCK_ROWS)
        local gridW = DOCK_COLUMNS * DOCK_TILE_W + (DOCK_COLUMNS - 1) * DOCK_GAP
        local gridH = shownRows * DOCK_TILE_H + (shownRows - 1) * DOCK_GAP
        local scrolls = rows > DOCK_ROWS
        local width = 12 + gridW + (if scrolls then 22 else 12)
        local height = 40 + gridH + 14 + 26 + 12

        local panel = New("Frame", { Name = "AttachmentDock", Size = UDim2.fromOffset(width, 0), ClipsDescendants = true }, nil)
        PopupMaterial(panel, 14, 40)
        W:PlacePopup(panel, anchor, 8, height)

        Themed(Text(panel, {
            Text = T("attachments"),
            TextSize = 12,
            Position = UDim2.fromOffset(14, 12),
            Size = UDim2.new(1, -28, 0, 18),
            ZIndex = 2,
        }), { TextColor3 = "TextPrimary" })
        local countLabel = Themed(Text(panel, {
            Text = "",
            FontFace = FONT_MEDIUM,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Right,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -14, 0, 12),
            Size = UDim2.fromOffset(200, 18),
            ZIndex = 2,
        }), { TextColor3 = "TextMuted" })

        local grid
        if scrolls then
            grid = New("ScrollingFrame", {
                Position = UDim2.fromOffset(6, 34),
                Size = UDim2.fromOffset(gridW + 22, gridH + 12),
                CanvasSize = UDim2.fromOffset(0, rows * (DOCK_TILE_H + DOCK_GAP) + 4),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 3,
                ScrollingDirection = Enum.ScrollingDirection.Y,
                ZIndex = 2,
            }, panel)
            Themed(grid, { ScrollBarImageColor3 = "Rim" })
        else
            grid = New("Frame", {
                Position = UDim2.fromOffset(6, 34),
                Size = UDim2.fromOffset(gridW + 12, gridH + 12),
                BackgroundTransparency = 1,
                ZIndex = 2,
            }, panel)
        end

        local tiles = {}
        local function paintTile(tile)
            local pod = tile.Pod
            local on = pod.Deployed
            tile.Ring.Color = if on then Glass.Accent else Glass.Rim
            tile.Ring.Transparency = if on then 0.25 else 0.72
            tile.Face.BackgroundTransparency = if on then 0.8 else 0.9
            tile.Dot.BackgroundColor3 = if on then Glass.Accent else Glass.Glyph
            tile.Dot.BackgroundTransparency = if on then 0 else 0.5
            local ok, value, unit = pcall(pod.kind.Summary or function() return "", "" end, pod)
            if ok then
                tile.Value.Text = tostring(if value == nil then "--" else value)
                tile.Unit.Text = tostring(unit or "")
            end
        end
        local function paintAll()
            local out = 0
            for _, pod in ipairs(pods) do
                if pod.Deployed then out += 1 end
            end
            countLabel.Text = string.format("%d / %d out", out, #pods)
            for _, tile in ipairs(tiles) do paintTile(tile) end
        end

        local hovered
        local function magnify(index)
            hovered = index
            for i, tile in ipairs(tiles) do
                local target = 1
                if index then
                    local sameRow = math.floor((i - 1) / DOCK_COLUMNS) == math.floor((index - 1) / DOCK_COLUMNS)
                    if i == index then
                        target = 1.1
                    elseif sameRow and math.abs(i - index) == 1 then
                        target = 1.04
                    end
                end
                if tile.target ~= target then
                    tile.target = target
                    Tween(tile.Scale, Motion.Pop, { Scale = target })
                end
                tile.Button.ZIndex = if i == index then 4 else 2
            end
        end

        for i, pod in ipairs(list) do
            local column, row = (i - 1) % DOCK_COLUMNS, math.floor((i - 1) / DOCK_COLUMNS)
            local button = New("TextButton", {
                Name = pod.Name,
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromOffset(6 + column * (DOCK_TILE_W + DOCK_GAP) + DOCK_TILE_W / 2, 6 + row * (DOCK_TILE_H + DOCK_GAP) + DOCK_TILE_H / 2),
                Size = UDim2.fromOffset(DOCK_TILE_W, DOCK_TILE_H),
                ZIndex = 2,
            }, grid)
            local tile = { Pod = pod, Button = button, Scale = New("UIScale", { Scale = 1 }, button), target = 1 }
            tile.Face = Themed(New("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 0.9,
                BorderSizePixel = 0,
                ZIndex = 2,
            }, button), { BackgroundColor3 = "LensTint" })
            Corner(tile.Face, 10)
            tile.Ring = New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1 }, tile.Face)
            tile.Dot = New("Frame", { Position = UDim2.fromOffset(9, 10), Size = UDim2.fromOffset(5, 5), BorderSizePixel = 0, ZIndex = 3 }, tile.Face)
            Corner(tile.Dot, 3)
            PodKinds.Label(tile.Face, {
                Text = pod.Title,
                TextSize = 9,
                Position = UDim2.fromOffset(18, 5),
                Size = UDim2.fromOffset(DOCK_TILE_W - 24, 14),
            }, "TextMuted")
            tile.Value = PodKinds.Value(tile.Face, {
                TextSize = 14,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Position = UDim2.fromOffset(9, 21),
                Size = UDim2.fromOffset(DOCK_TILE_W - 16, 18),
            })
            tile.Unit = PodKinds.Label(tile.Face, {
                TextSize = 10,
                Position = UDim2.fromOffset(9, 39),
                Size = UDim2.fromOffset(DOCK_TILE_W - 16, 14),
            }, "TextMuted")
            tiles[i] = tile

            button.MouseEnter:Connect(function()
                magnify(i)
                playSound("Hover")
            end)
            button.MouseLeave:Connect(function()
                if hovered == i then magnify(nil) end
            end)
            button.MouseButton2Click:Connect(function()
                if pod.Pinned then
                    pod:Remove()
                    W:ClosePopup()
                end
            end)
            -- Click toggles it; dragging the tile out carries the pod straight to where you drop it.
            button.InputBegan:Connect(function(input)
                if not isPointer(input) then return end
                local start = input.Position
                local dragged = false
                local grab
                local moveConnection, endConnection
                moveConnection = UserInputService.InputChanged:Connect(function(changed)
                    if not isMove(changed) then return end
                    local point = screenPoint(changed)
                    if not dragged then
                        if (changed.Position - start).Magnitude < L.DragSlop or carry then return end
                        dragged = true
                        W:ClosePopup()
                        local k = Scale.Scale
                        local size = FORM_SIZE[pod.Form]
                        grab = Vector2.new(size.X * k / 2, 14 * k)
                        pod:Deploy(point - grab)
                        beginCarry(pod)
                    end
                    moveCarry(pod, point - grab, point)
                end)
                endConnection = input.Changed:Connect(function()
                    if input.UserInputState ~= Enum.UserInputState.End then return end
                    moveConnection:Disconnect()
                    endConnection:Disconnect()
                    if dragged then
                        endCarry(pod)
                    else
                        if pod.Deployed then pod:Stow() else pod:Deploy() end
                        paintAll()
                    end
                end)
            end)
        end
        paintAll()

        -- Layouts
        local rowY = 34 + gridH + 12 + 6
        local strip = New("Frame", {
            Name = "Layouts",
            Position = UDim2.fromOffset(12, rowY),
            Size = UDim2.fromOffset(width - 24, 26),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            ZIndex = 2,
        }, panel)
        local buildStrip
        local function chip(x, text, accent)
            local w = math.max(44, textWidth(text, 11, Enum.Font.GothamMedium) + 20)
            local button = New("TextButton", {
                Text = "",
                AutoButtonColor = false,
                Position = UDim2.fromOffset(x, 1),
                Size = UDim2.fromOffset(w, 24),
                BackgroundTransparency = 0.88,
                BorderSizePixel = 0,
                ZIndex = 3,
            }, strip)
            Themed(button, { BackgroundColor3 = if accent then "Accent" else "LensTint" })
            Corner(button, 12)
            Themed(New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1, Transparency = 0.7 }, button), { Color = "Rim" })
            Themed(Text(button, {
                Text = text,
                FontFace = FONT_MEDIUM,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Center,
                Size = UDim2.fromScale(1, 1),
                ZIndex = 4,
            }), { TextColor3 = "TextPrimary" })
            button.MouseEnter:Connect(function() Tween(button, Motion.Hover, { BackgroundTransparency = 0.76 }) end)
            button.MouseLeave:Connect(function() Tween(button, Motion.Hover, { BackgroundTransparency = 0.88 }) end)
            return button, w
        end
        buildStrip = function()
            for _, child in ipairs(strip:GetChildren()) do child:Destroy() end
            Themed(Text(strip, {
                Text = "LAYOUTS",
                FontFace = FONT_MEDIUM,
                TextSize = 10,
                Position = UDim2.fromOffset(2, 0),
                Size = UDim2.fromOffset(56, 26),
                ZIndex = 3,
            }), { TextColor3 = "TextMuted" })
            local x = 60
            for _, name in ipairs(layoutNames()) do
                local button, w = chip(x, name)
                button.MouseButton1Click:Connect(function()
                    W.LoadLayout(name)
                    playSound("Open")
                    paintAll()
                end)
                button.MouseButton2Click:Connect(function()
                    W.DeleteLayout(name)
                    playSound("Close")
                    buildStrip()
                end)
                x += w + 6
            end
            local save = chip(x, "+ Save", true)
            save.MouseButton1Click:Connect(function()
                save:Destroy()
                local box = New("TextBox", {
                    Text = "",
                    PlaceholderText = "Layout name",
                    ClearTextOnFocus = false,
                    FontFace = FONT_MEDIUM,
                    TextSize = 11,
                    Position = UDim2.fromOffset(x, 1),
                    Size = UDim2.fromOffset(120, 24),
                    BackgroundTransparency = 0.82,
                    BorderSizePixel = 0,
                    ZIndex = 3,
                }, strip)
                Themed(box, { BackgroundColor3 = "Field", TextColor3 = "TextPrimary", PlaceholderColor3 = "TextMuted" })
                Corner(box, 12)
                box.FocusLost:Connect(function(entered)
                    if entered then
                        if W.SaveLayout(box.Text) then playSound("Deploy") end
                    end
                    if strip.Parent then buildStrip() end
                end)
                box:CaptureFocus()
            end)
        end
        buildStrip()

        W.DockTick = paintAll
        W:OpenPopup(panel, function()
            W.DockTick = nil
            playSound("Close")
            Tween(panel, Motion.FadeOut, { Size = UDim2.fromOffset(width, 0) })
            task.delay(Motion.FadeOut.Time, function() panel:Destroy() end)
        end)
        playSound("Open")
        Tween(panel, Motion.Reveal, { Size = UDim2.fromOffset(width, height) })
    end

    ---------------------------------------------------------------------------------------------------
    -- Window hooks
    ---------------------------------------------------------------------------------------------------
    W.OnWindowVisibility = function(visible)
        windowShown = visible
        invalidate()
        wakeAll()
        if visible then
            for _, pod in ipairs(pods) do
                if showing(pod) then refreshPod(pod) end
            end
        end
    end

    W.OnBubbleHover = function(on)
        bubbleHover = on
        invalidate()
        wakeAll()
    end

    W.OnLowGraphics = function()
        invalidate()
        wakeAll()
    end

    W.Pods = pods -- scripts (and the dock) can deploy, stow or re-side a pod directly
    W.PodsByName = byName

    Holder:GetPropertyChangedSignal("Position"):Connect(wakeAll)
    Holder:GetPropertyChangedSignal("Size"):Connect(wakeAll)
    Scale:GetPropertyChangedSignal("Scale"):Connect(wakeAll)
    if Bubble then
        -- Moons follow the bubble while it morphs and while it is dragged.
        local function followBubble()
            if not windowShown then wakeAll() end
        end
        Bubble:GetPropertyChangedSignal("Position"):Connect(followBubble)
        Bubble:GetPropertyChangedSignal("Size"):Connect(followBubble)
        Bubble:GetPropertyChangedSignal("Visible"):Connect(followBubble)
    end

    local previousViewport = W.OnViewportChanged
    W.OnViewportChanged = function()
        if previousViewport then previousViewport() end
        invalidate()
        wakeAll()
    end

    function Window:AddAttachment(spec) return W.AddAttachment(spec) end
    function Window:GetAttachment(name)
        local pod = byName[name] or byName["Custom_" .. tostring(name)]
        return pod and (pod.Handle or pod)
    end
    function Window:SaveAttachmentLayout(name) return W.SaveLayout(name) end
    function Window:LoadAttachmentLayout(name) return W.LoadLayout(name) end
    function Window:DeleteAttachmentLayout(name) return W.DeleteLayout(name) end
    function Window:GetAttachmentLayouts() return layoutNames() end
end
