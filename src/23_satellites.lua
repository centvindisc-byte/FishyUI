-------------------------------------------------------------------------------------------------------
-- Satellites
--
-- Small glass pods carrying live info. Nothing is deployed by default: the Attachments button in the
-- header opens a launcher, and you either click a row to deploy it or drag the row straight out of the
-- list to place it yourself.
--
-- A deployed pod can dock to any of the window's four sides, trailing it on a spring as it moves. If a
-- side has no room on screen the pod crosses to the opposite side, and if neither fits it is clamped
-- into view and its connectors fade out, so a pod is never shown tethered to nothing.
-------------------------------------------------------------------------------------------------------
local POD_W, POD_H = 176, 100
local POD_GAP = 10 -- window edge to a docked pod
local POD_STACK_GAP = 10
local POD_EDGE_INSET = 16 -- first pod's offset along the window edge
local POD_MAGNET = 110 -- screen px: a carried pod this close to a side docks there
local GRAPH_BARS, GRAPH_HEIGHT, GRAPH_GAP = 28, 28, 2
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

BuildSatellites = function(W)
    local ScreenGui, Holder, Scale = W.ScreenGui, W.Holder, W.Scale
    local pods = {}
    local carry -- { pod, side, index, slot }

    -- The screen, window and inset numbers every placement starts from. A docking pass needs them for every
    -- pod and side, so it reads them once and passes them down; the other callers just read them fresh.
    local function geometry()
        return {
            screen = ScreenGui.AbsoluteSize,
            position = Holder.Position,
            size = Holder.Size,
            k = Scale.Scale,
            top = GuiService:GetGuiInset().Y,
        }
    end

    local function windowRect(g)
        g = g or geometry()
        local ss, p, s, k = g.screen, g.position, g.size, g.k
        local size = Vector2.new(s.X.Offset, s.Y.Offset) * k
        local center = Vector2.new(p.X.Scale * ss.X + p.X.Offset, p.Y.Scale * ss.Y + p.Y.Offset)
        return center - size / 2, size
    end

    -- Top-left of the first slot on a side, and the step between slots.
    local function sideGeometry(side, g)
        g = g or geometry()
        local topLeft, size = windowRect(g)
        local k = g.k
        if side == "Right" then
            return Vector2.new(topLeft.X + size.X + POD_GAP * k, topLeft.Y + POD_EDGE_INSET * k), Vector2.new(0, (POD_H + POD_STACK_GAP) * k)
        elseif side == "Left" then
            return Vector2.new(topLeft.X - (POD_W + POD_GAP) * k, topLeft.Y + POD_EDGE_INSET * k), Vector2.new(0, (POD_H + POD_STACK_GAP) * k)
        elseif side == "Top" then
            return Vector2.new(topLeft.X + POD_EDGE_INSET * k, topLeft.Y - (POD_H + POD_GAP) * k), Vector2.new((POD_W + POD_STACK_GAP) * k, 0)
        end
        return Vector2.new(topLeft.X + POD_EDGE_INSET * k, topLeft.Y + size.Y + POD_GAP * k), Vector2.new((POD_W + POD_STACK_GAP) * k, 0)
    end

    local function opposite(side)
        if side == "Left" then return "Right" end
        if side == "Right" then return "Left" end
        if side == "Top" then return "Bottom" end
        return "Top"
    end

    local function fitsOnScreen(position, g)
        g = g or geometry()
        local ss, k = g.screen, g.k
        return position.X >= 0 and position.Y >= g.top
            and position.X + POD_W * k <= ss.X and position.Y + POD_H * k <= ss.Y
    end

    -- The side a pod actually renders on: its own, or the opposite one when there's no room.
    local function renderSide(side, g)
        g = g or geometry()
        local anchor = sideGeometry(side, g)
        if fitsOnScreen(anchor, g) then return side end
        local other = opposite(side)
        if fitsOnScreen((sideGeometry(other, g)), g) then return other end
        return side
    end

    local function clampToScreen(position, g)
        g = g or geometry()
        local ss, k = g.screen, g.k
        local margin = L.BubbleMargin
        local top = g.top + margin
        return Vector2.new(
            math.clamp(position.X, margin, math.max(margin, ss.X - POD_W * k - margin)),
            math.clamp(position.Y, top, math.max(top, ss.Y - POD_H * k - margin))
        )
    end

    -- Deployed, docked pods grouped by the side they render on.
    local function columns(g)
        g = g or geometry()
        local result = {}
        for _, side in ipairs(SIDES) do result[side] = {} end
        for _, pod in ipairs(pods) do
            if pod.Deployed and pod.Docked and pod ~= (carry and carry.pod) then
                table.insert(result[renderSide(pod.Side, g)], pod)
            end
        end
        for _, side in ipairs(SIDES) do
            table.sort(result[side], function(a, b) return a.Order < b.Order end)
        end
        return result
    end

    -- Where each docked pod belongs right now, plus a reserved gap for a pod being carried onto a side.
    local function dockTargets(g)
        g = g or geometry()
        local targets, attached = {}, {}
        local grouped = columns(g)
        for _, side in ipairs(SIDES) do
            local column = grouped[side]
            if carry and carry.side == side then
                table.insert(column, math.clamp(carry.index, 1, #column + 1), carry)
            end
            local origin, step = sideGeometry(side, g)
            for i, item in ipairs(column) do
                local ideal = origin + step * (i - 1)
                local clamped = clampToScreen(ideal, g)
                if item == carry then
                    carry.slot = clamped
                else
                    targets[item] = clamped
                    attached[item] = (clamped - ideal).Magnitude < 0.5
                    item.RenderSide = side
                end
            end
        end
        return targets, attached
    end

    -- Pods read their dock slots on every physics substep, and computing them walks every pod and reads the
    -- window and screen geometry each time. Nothing those slots depend on can change partway through an
    -- animator frame, so the result is shared by every pod and substep of that frame.
    local frameAt, frameGeometry, frameTargets, frameAttached = -1, nil, nil, nil
    local function geometryThisFrame()
        if frameAt ~= Animator.frame then
            frameAt, frameGeometry, frameTargets, frameAttached = Animator.frame, geometry(), nil, nil
        end
        return frameGeometry
    end
    local function dockTargetsThisFrame()
        local g = geometryThisFrame()
        if not frameTargets then frameTargets, frameAttached = dockTargets(g) end
        return frameTargets, frameAttached
    end

    local function wakeAll()
        for _, pod in ipairs(pods) do Animator.Wake(pod) end
    end

    ---------------------------------------------------------------------------------------------------
    -- Pod shell
    ---------------------------------------------------------------------------------------------------
    local function makePod(name, title, side)
        local pod = {
            Name = name, Title = title, Side = side or "Right", RenderSide = side or "Right",
            Order = #pods + 1, -- position within its side's stack; drag-and-drop rewrites it
            Deployed = false, Docked = true, Carried = false, Landing = false, Attached = false,
            x = 0, y = 0, vx = 0, vy = 0, tx = 0, ty = 0, rotation = 0, lift = 0, alpha = 0, alphaTarget = 0,
        }

        local frame = New("Frame", {
            Name = "Satellite_" .. name,
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(POD_W, POD_H),
            Visible = false,
            ZIndex = 90,
        }, ScreenGui)
        local frameScale = New("UIScale", { Scale = Scale.Scale }, frame)
        local shadow = GlassShadow(frame, 14, 1, 0)

        -- Two connectors bridging the gap. They fade to nothing at both ends so the pod and the window
        -- read as joined rather than bolted together, and they only appear once the pod is truly docked.
        local clamps = {}
        for i = 1, 2 do
            local clamp = Themed(New("Frame", {
                Name = "Clamp",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Size = UDim2.fromOffset(POD_GAP + 6, 5),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 1,
            }, frame), { BackgroundColor3 = "LensTint" })
            New("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.5, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
            }, clamp)
            local core = Themed(New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.new(1, -2, 0, 2),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 2,
            }, clamp), { BackgroundColor3 = "Accent" })
            New("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.5, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
            }, core)
            clamps[i] = { Frame = clamp, Core = core }
        end

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
        local surface = New("Frame", {
            Name = "Surface",
            Size = UDim2.fromScale(1, 1),
            ZIndex = 1,
        }, body)
        PaneMaterial(surface, 12, 40)
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
        Corner(wash, 12)

        local dot = Themed(New("Frame", {
            Position = UDim2.fromOffset(12, 14),
            Size = UDim2.fromOffset(5, 5),
            BorderSizePixel = 0,
            ZIndex = 3,
        }, body), { BackgroundColor3 = "Accent" })
        Corner(dot, 3)
        local titleLabel = Themed(Text(body, {
            Text = title,
            TextSize = 11,
            Position = UDim2.fromOffset(23, 8),
            Size = UDim2.new(1, -50, 0, 16),
            ZIndex = 3,
        }), { TextColor3 = POD_LABEL })
        pod.TitleLabel = titleLabel
        for i = 0, 2 do
            local grip = Themed(New("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.fromOffset(POD_W - 12 - i * 5, 15),
                Size = UDim2.fromOffset(3, 3),
                BackgroundTransparency = 0.35,
                BorderSizePixel = 0,
                ZIndex = 3,
            }, body), { BackgroundColor3 = "Glyph" })
            Corner(grip, 2)
        end

        local hit = New("TextButton", {
            Name = "Hitbox",
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 20,
        }, frame)

        -- Everything the pod draws goes through this cache. A docked pod that is only being trailed along
        -- has a constant rotation, scale, fade and connector layout; only its position changes.
        local put = PropertyCache()

        local function renderAlpha()
            put(body, "GroupTransparency", 1 - pod.alpha)
            put(shadow, "ImageTransparency", 1 - (1 - Glass.ShadowTransparency) * pod.alpha)
            put(frame, "Visible", pod.alpha > 0.01)
        end

        -- `alpha` is passed in rather than read from the pod: at rest the connectors keep the fade they had
        -- on the last moving step, while the body snaps to its final fade.
        local function layoutClamps(hold, alpha)
            local side = pod.RenderSide
            local vertical = isVertical(side)
            local along = if vertical then POD_H else POD_W
            local first, second = along * 0.25, along * 0.75
            for i, clamp in ipairs(clamps) do
                local at = if i == 1 then first else second
                if vertical then
                    put(clamp.Frame, "Size", UDim2.fromOffset(POD_GAP + 6, 5))
                    put(clamp.Core, "Size", UDim2.new(1, -2, 0, 2))
                    put(clamp.Frame, "Position", UDim2.fromOffset(if side == "Left" then POD_W + POD_GAP / 2 else -POD_GAP / 2, at))
                else
                    put(clamp.Frame, "Size", UDim2.fromOffset(5, POD_GAP + 6))
                    put(clamp.Core, "Size", UDim2.new(0, 2, 1, -2))
                    put(clamp.Frame, "Position", UDim2.fromOffset(at, if side == "Top" then POD_H + POD_GAP / 2 else -POD_GAP / 2))
                end
                put(clamp.Frame, "BackgroundTransparency", 1 - 0.35 * hold * alpha)
                put(clamp.Core, "BackgroundTransparency", 1 - 0.9 * hold * alpha)
            end
        end

        -- Step integrates; Render draws once the frame's substeps are done. These carry what the last
        -- step decided about the connectors over to Render.
        local clampHold, clampAlpha = 0, 0

        function pod:Render()
            put(frame, "Position", UDim2.fromOffset(self.x, self.y))
            put(frame, "Rotation", self.rotation)
            put(frameScale, "Scale", Scale.Scale * (1 + 0.04 * self.lift))
            renderAlpha()
            layoutClamps(clampHold, clampAlpha)
        end

        function pod:Step(dt)
            local target
            if self.Docked and not self.Carried then
                local targets, attached = dockTargetsThisFrame()
                target = targets[self] or Vector2.new(self.x, self.y)
                self.Attached = attached[self] == true
            else
                target = clampToScreen(Vector2.new(self.tx, self.ty), geometryThisFrame())
                self.Attached = false
            end

            local stiffness, ratio = 260, 0.74
            if self.Carried then
                stiffness, ratio = 700, 0.85
            elseif self.Landing then
                stiffness, ratio = 240, 0.58
            end
            local damping = 2 * math.sqrt(stiffness) * ratio
            self.vx += (stiffness * (target.X - self.x) - damping * self.vx) * dt
            self.vy += (stiffness * (target.Y - self.y) - damping * self.vy) * dt
            self.x += self.vx * dt
            self.y += self.vy * dt

            local lean = if self.Carried then math.clamp(self.vx * 0.012, -8, 8) else 0
            self.rotation += (lean - self.rotation) * math.min(1, dt * 14)
            local liftTarget = if self.Carried then 1 else 0
            self.lift += (liftTarget - self.lift) * math.min(1, dt * 16)
            self.alpha += (self.alphaTarget - self.alpha) * math.min(1, dt * 12)

            local distance = (target - Vector2.new(self.x, self.y)).Magnitude
            clampHold = if self.Attached and not self.Carried then math.clamp(1 - distance / 24, 0, 1) else 0
            clampAlpha = self.alpha

            local resting = distance < 0.3 and math.abs(self.vx) < 2 and math.abs(self.vy) < 2
                and math.abs(self.rotation - lean) < 0.05 and math.abs(self.lift - liftTarget) < 0.01
                and math.abs(self.alpha - self.alphaTarget) < 0.01
            if not resting then return true end
            self.x, self.y = target.X, target.Y
            self.alpha, self.Landing = self.alphaTarget, false
            return false
        end

        -----------------------------------------------------------------------------------------------
        -- Deploying, carrying and stowing
        -----------------------------------------------------------------------------------------------
        function pod:Deploy(atPosition)
            local wasDeployed = self.Deployed
            self.Deployed = true
            self.alphaTarget = 1
            if not wasDeployed then playSound("Deploy") end
            if atPosition then
                self.Docked = false
                self.tx, self.ty = atPosition.X, atPosition.Y
                self.x, self.y = atPosition.X, atPosition.Y
            else
                self.Docked = true
                local targets = dockTargets()
                local target = targets[self]
                if target then
                    -- Start tucked under the window edge so the pod slides out of it.
                    local k, side = Scale.Scale, self.RenderSide
                    self.x, self.y = target.X, target.Y
                    if side == "Left" then
                        self.x = target.X + POD_W * 0.4 * k
                    elseif side == "Right" then
                        self.x = target.X - POD_W * 0.4 * k
                    elseif side == "Top" then
                        self.y = target.Y + POD_H * 0.4 * k
                    else
                        self.y = target.Y - POD_H * 0.4 * k
                    end
                    self.vx, self.vy = 0, 0
                end
            end
            wakeAll()
        end

        function pod:Stow()
            if self.Deployed then playSound("Close") end
            self.Deployed = false
            self.Carried = false
            self.alphaTarget = 0
            if carry and carry.pod == self then carry = nil end
            wakeAll()
        end

        -- Pinned pods are made on demand and can be thrown away again; the built-in five never are.
        function pod:Remove()
            self:Stow()
            local index = table.find(pods, self)
            if index then table.remove(pods, index) end
            Animator.Wake(self)
            task.delay(0.35, function() frame:Destroy() end)
        end

        local function beginCarry()
            pod.Docked, pod.Carried, pod.Landing = false, true, false
            pod.tx, pod.ty = pod.x, pod.y
            carry = { pod = pod, side = nil, index = 1 }
            wakeAll()
        end
        pod.BeginCarry = beginCarry

        local function moveCarry(topLeft)
            if not carry or carry.pod ~= pod then return end
            carry.side = nil
            local g = geometry()
            local best
            for _, side in ipairs(SIDES) do
                local rendered = renderSide(side, g)
                local origin = sideGeometry(rendered, g)
                local distance = if isVertical(rendered) then math.abs(topLeft.X - origin.X) else math.abs(topLeft.Y - origin.Y)
                if distance < POD_MAGNET and (not best or distance < best.distance) then
                    best = { side = rendered, distance = distance, origin = origin }
                end
            end
            if best then
                carry.side = best.side
                local grouped = columns(g)[best.side]
                local origin, step = sideGeometry(best.side, g)
                local index = #grouped + 1
                for i = 1, #grouped do
                    local slot = origin + step * (i - 1)
                    local ahead = if isVertical(best.side) then topLeft.Y < slot.Y + step.Y / 2 else topLeft.X < slot.X + step.X / 2
                    if ahead then
                        index = i
                        break
                    end
                end
                carry.index = index
                dockTargets(g) -- fills carry.slot
                local offset = carry.slot - topLeft
                local pull = math.clamp(1 - offset.Magnitude / POD_MAGNET, 0, 1)
                topLeft += offset * pull * pull
            end
            pod.tx, pod.ty = topLeft.X, topLeft.Y
            wakeAll()
        end
        pod.MoveCarry = moveCarry

        local function endCarry()
            if not carry or carry.pod ~= pod then return end
            local side, index = carry.side, carry.index
            carry = nil
            pod.Carried, pod.Landing = false, true
            if side then
                pod.Side, pod.Docked = side, true
                -- Slot it between its new neighbours, then renumber the column so the order sticks.
                pod.Order = index - 0.5
                local column = columns()[side]
                for position, member in ipairs(column) do member.Order = position end
            else
                pod.Docked = false
                local settled = clampToScreen(Vector2.new(pod.tx, pod.ty))
                pod.tx, pod.ty = settled.X, settled.Y
            end
            wakeAll()
        end
        pod.EndCarry = endCarry

        hit.InputBegan:Connect(function(input)
            if not isPointer(input) or carry then return end
            local start, origin = input.Position, Vector2.new(pod.x, pod.y)
            local lifted = false
            local moveConnection, endConnection
            moveConnection = UserInputService.InputChanged:Connect(function(changed)
                if not isMove(changed) then return end
                local delta = changed.Position - start
                if not lifted then
                    if delta.Magnitude < L.DragSlop or carry then return end
                    lifted = true
                    beginCarry()
                end
                moveCarry(origin + Vector2.new(delta.X, delta.Y))
            end)
            endConnection = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then return end
                moveConnection:Disconnect()
                endConnection:Disconnect()
                if lifted then endCarry() end
            end)
        end)

        pod.Frame, pod.Body = frame, body
        table.insert(pods, pod)
        return pod, body
    end

    ---------------------------------------------------------------------------------------------------
    -- Session
    ---------------------------------------------------------------------------------------------------
    local MONO_BOLD = Font.new(FONT_MONO.Family, Enum.FontWeight.Bold)
    local _, sessionBody = makePod("Session", "SESSION", "Right")
    local sessionTime = Themed(Text(sessionBody, {
        Text = "00:00:00", FontFace = MONO_BOLD, TextSize = 20,
        Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -56, 0, 26), ZIndex = 3,
    }), { TextColor3 = "TextPrimary" })
    local serverUp = Themed(Text(sessionBody, {
        FontFace = FONT_MEDIUM, TextSize = 11,
        Position = UDim2.fromOffset(12, 56), Size = UDim2.new(1, -24, 0, 14), ZIndex = 3,
    }), { TextColor3 = POD_LABEL })
    local ring = New("Frame", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromOffset(POD_W - 12, 30),
        Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, ZIndex = 3,
    }, sessionBody)
    Corner(ring, 12)
    Themed(New("UIStroke", { Thickness = 1.5, Transparency = 0.7 }, ring), { Color = "Rim" })
    local orbit = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 3,
    }, ring)
    local orbitBead = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0),
        Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, ZIndex = 4,
    }, orbit), { BackgroundColor3 = "Accent" })
    Corner(orbitBead, 3)

    ---------------------------------------------------------------------------------------------------
    -- Performance
    ---------------------------------------------------------------------------------------------------
    local _, perfBody = makePod("Performance", "PERFORMANCE", "Right")
    local fpsValue = Themed(Text(perfBody, {
        Text = "0", TextSize = 22, TextTruncate = Enum.TextTruncate.None,
        Position = UDim2.fromOffset(12, 26), Size = UDim2.fromOffset(60, 28), ZIndex = 3,
    }), { TextColor3 = "TextPrimary" })
    local fpsUnit = Themed(Text(perfBody, {
        Text = "fps", FontFace = FONT_MEDIUM, TextSize = 11,
        Position = UDim2.fromOffset(40, 34), Size = UDim2.fromOffset(30, 16), ZIndex = 3,
    }), { TextColor3 = POD_LABEL })
    local pingText = Themed(Text(perfBody, {
        Text = "-- ms", FontFace = FONT_MEDIUM, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.fromOffset(POD_W - 12, 32), Size = UDim2.fromOffset(64, 16), ZIndex = 3,
    }), { TextColor3 = POD_SUB })
    local pingDot = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(POD_W - 80, 40),
        Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Glass.Glyph, BorderSizePixel = 0, ZIndex = 3,
    }, perfBody)
    Corner(pingDot, 3)
    local graph = New("Frame", {
        Position = UDim2.fromOffset(12, 62), Size = UDim2.fromOffset(POD_W - 24, GRAPH_HEIGHT),
        BackgroundTransparency = 1, ZIndex = 3,
    }, perfBody)
    Themed(New("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1),
        BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 3,
    }, graph), { BackgroundColor3 = "Rim" })
    local barWidth = (POD_W - 24 - (GRAPH_BARS - 1) * GRAPH_GAP) / GRAPH_BARS
    local graphBars = {}
    for i = 1, GRAPH_BARS do
        local bar = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, (i - 1) * (barWidth + GRAPH_GAP), 1, -2),
            Size = UDim2.fromOffset(barWidth, 2), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 4,
        }, graph)
        Corner(bar, 1)
        graphBars[i] = bar
    end

    ---------------------------------------------------------------------------------------------------
    -- Server
    ---------------------------------------------------------------------------------------------------
    local _, serverBody = makePod("Server", "SERVER", "Right")
    local playersValue = Themed(Text(serverBody, {
        Text = "0", TextSize = 20, TextTruncate = Enum.TextTruncate.None,
        Position = UDim2.fromOffset(12, 26), Size = UDim2.fromOffset(80, 26), ZIndex = 3,
    }), { TextColor3 = "TextPrimary" })
    local playersUnit = Themed(Text(serverBody, {
        Text = "players", FontFace = FONT_MEDIUM, TextSize = 11,
        Position = UDim2.fromOffset(60, 33), Size = UDim2.fromOffset(60, 16), ZIndex = 3,
    }), { TextColor3 = POD_LABEL })
    local capacity = New("Frame", {
        Position = UDim2.fromOffset(12, 56), Size = UDim2.fromOffset(POD_W - 24, 6), ZIndex = 3,
    }, serverBody)
    FieldMaterial(capacity, 3)
    local capacityFill = Themed(New("Frame", {
        Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, ZIndex = 4,
    }, capacity), { BackgroundColor3 = "Accent" })
    Corner(capacityFill, 3)
    local serverMeta = Themed(Text(serverBody, {
        FontFace = FONT_MEDIUM, TextSize = 11,
        Position = UDim2.fromOffset(12, 68), Size = UDim2.new(1, -24, 0, 14), ZIndex = 3,
    }), { TextColor3 = POD_LABEL })

    ---------------------------------------------------------------------------------------------------
    -- Location
    ---------------------------------------------------------------------------------------------------
    local locPod, locBody = makePod("Location", "LOCATION", "Left")
    local coordLabels = {}
    for i, axis in ipairs({ "X", "Y", "Z" }) do
        Themed(Text(locBody, {
            Text = axis, FontFace = MONO_BOLD, TextSize = 10,
            Position = UDim2.fromOffset(12, 26 + (i - 1) * 18), Size = UDim2.fromOffset(12, 14), ZIndex = 3,
        }), { TextColor3 = POD_LABEL })
        coordLabels[i] = Themed(Text(locBody, {
            Text = "0", FontFace = FONT_MONO, TextSize = 12,
            Position = UDim2.fromOffset(26, 26 + (i - 1) * 18), Size = UDim2.fromOffset(78, 14), ZIndex = 3,
        }), { TextColor3 = "TextPrimary" })
    end
    local compass = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromOffset(POD_W - 14, 54),
        Size = UDim2.fromOffset(48, 48), BackgroundTransparency = 1, ZIndex = 3,
    }, locBody)
    Corner(compass, 24)
    Themed(New("UIStroke", { Thickness = 1.5, Transparency = 0.65 }, compass), { Color = "Rim" })
    Themed(Text(compass, {
        Text = "N", TextSize = 9, TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.fromOffset(0, 1), Size = UDim2.new(1, 0, 0, 10), ZIndex = 4,
    }), { TextColor3 = POD_LABEL })
    local needle = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 4,
    }, compass)
    local needleN = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(3, 17), BorderSizePixel = 0, ZIndex = 5,
    }, needle), { BackgroundColor3 = "Accent" })
    Corner(needleN, 2)
    local needleS = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(3, 15), BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 5,
    }, needle), { BackgroundColor3 = "Glyph" })
    Corner(needleS, 2)

    ---------------------------------------------------------------------------------------------------
    -- Radar
    ---------------------------------------------------------------------------------------------------
    local RADAR_RANGE = 220
    local radarPod, radarBody = makePod("Radar", "RADAR", "Left")
    local dish = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(POD_W - 54, POD_H / 2 + 6),
        Size = UDim2.fromOffset(72, 72), BackgroundTransparency = 1, ZIndex = 3,
    }, radarBody)
    FieldMaterial(dish, 36)
    Corner(dish, 36)
    for _, scale in ipairs({ 1, 0.6 }) do
        local rangeRing = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(scale, scale), BackgroundTransparency = 1, ZIndex = 4,
        }, dish)
        Corner(rangeRing, 36)
        Themed(New("UIStroke", { Thickness = 1, Transparency = 0.72 }, rangeRing), { Color = "Rim" })
    end
    for _, rot in ipairs({ 0, 90 }) do
        Themed(New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = if rot == 0 then UDim2.new(0, 1, 1, -6) else UDim2.new(1, -6, 0, 1),
            BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 4,
        }, dish), { BackgroundColor3 = "Rim" })
    end
    local sweepPivot = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5,
    }, dish)
    Themed(New("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1,
        Image = Assets.Spark, ImageTransparency = 0.4, ZIndex = 5,
    }, sweepPivot), { ImageColor3 = "Accent" })
    local blipHolder = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 6 }, dish)
    local selfBlip = Themed(New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(5, 5), BorderSizePixel = 0, ZIndex = 7,
    }, dish), { BackgroundColor3 = "Knob" })
    Corner(selfBlip, 3)
    local countValue = Themed(Text(radarBody, {
        Text = "0", TextSize = 22, Position = UDim2.fromOffset(12, 26), Size = UDim2.fromOffset(40, 26), ZIndex = 3,
    }), { TextColor3 = "TextPrimary" })
    Themed(Text(radarBody, {
        Text = "nearby", FontFace = FONT_MEDIUM, TextSize = 11,
        Position = UDim2.fromOffset(12, 52), Size = UDim2.fromOffset(70, 14), ZIndex = 3,
    }), { TextColor3 = POD_LABEL })
    Themed(Text(radarBody, {
        Text = string.format("%dm range", RADAR_RANGE), FontFace = FONT_MEDIUM, TextSize = 10,
        Position = UDim2.fromOffset(12, 70), Size = UDim2.fromOffset(90, 14), ZIndex = 3,
    }), { TextColor3 = POD_LABEL })
    local blips = {}
    local function radarBlip(i)
        if blips[i] then return blips[i] end
        local blip = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(5, 5),
            BackgroundColor3 = Glass.Danger, BorderSizePixel = 0, Visible = false, ZIndex = 7,
        }, blipHolder)
        Corner(blip, 3)
        blips[i] = blip
        return blip
    end

    ---------------------------------------------------------------------------------------------------
    -- Live data
    ---------------------------------------------------------------------------------------------------
    local function anyVisible()
        for _, pod in ipairs(pods) do
            if pod.alpha > 0.01 or pod.alphaTarget > 0 then return true end
        end
        return false
    end

    -- Runs once a second while any pod is out. Most seconds the ping, its colour and the player count
    -- haven't moved, and starting a tween toward the value a property already has only allocates a tween;
    -- so tweens are only started toward a new goal, and plain writes go through a cache.
    local goals, put = {}, PropertyCache()
    local function tweenTo(inst, info, property, goal)
        local last = goals[inst]
        if last and last[property] == goal then return end
        goals[inst] = goals[inst] or {}
        goals[inst][property] = goal
        Tween(inst, info, { [property] = goal })
    end

    local function refresh()
        local session = os.clock() - Telemetry.SessionStart
        sessionTime.Text = Telemetry.Clock(session)
        serverUp.Text = "Server up " .. Telemetry.Duration(Workspace.DistributedGameTime)
        Tween(orbit, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Rotation = math.floor(session) * 6 })

        fpsValue.Text = tostring(Telemetry.Fps)
        fpsUnit.Position = UDim2.fromOffset(12 + textWidth(fpsValue.Text, 22, Enum.Font.GothamBold) + 5, 34)
        local ping = Telemetry.Ping
        pingText.Text = if ping then string.format("%d ms", math.floor(ping + 0.5)) else "-- ms"
        pingDot.Position = UDim2.fromOffset(POD_W - 12 - textWidth(pingText.Text, 12, Enum.Font.GothamMedium) - 6, 40)
        tweenTo(pingDot, Motion.Hover, "BackgroundColor3", if ping then Telemetry.StrengthColor(Telemetry.Strength(ping)) else Glass.Glyph)

        local samples = Telemetry.PingSamples
        local ceiling = 150
        for _, value in ipairs(samples) do ceiling = math.max(ceiling, value * 1.15) end
        for i, bar in ipairs(graphBars) do
            local value = samples[#samples - GRAPH_BARS + i]
            if value and value > 0 then
                put(bar, "BackgroundColor3", Telemetry.StrengthColor(Telemetry.Strength(value)))
                put(bar, "BackgroundTransparency", if i == GRAPH_BARS then 0.05 else 0.45)
                tweenTo(bar, Motion.Hover, "Size", UDim2.fromOffset(barWidth, math.max(2, value / ceiling * (GRAPH_HEIGHT - 4))))
            else
                put(bar, "BackgroundTransparency", 1)
            end
        end

        local count, max = #Players:GetPlayers(), Players.MaxPlayers
        playersValue.Text = if max > 0 then string.format("%d/%d", count, max) else tostring(count)
        playersUnit.Position = UDim2.fromOffset(12 + textWidth(playersValue.Text, 20, Enum.Font.GothamBold) + 5, 33)
        tweenTo(capacityFill, Motion.Settle, "Size", UDim2.fromScale(if max > 0 then math.clamp(count / max, 0, 1) else 0, 1))
        serverMeta.Text = Telemetry.Region .. "  ·  " .. Telemetry.Executor
    end
    Telemetry.OnTick(function()
        if anyVisible() then refresh() end
    end)

    -- Runs every frame whether or not anything is deployed, so the open check uses the pods' own fade
    -- (the body's GroupTransparency is drawn from it) instead of reading two instance properties.
    local locationAccrued, sweepAngle = 0, 0
    -- At 15 Hz most of these come out the same as last time (standing still, players out of range).
    local live = PropertyCache()
    Library:GiveSignal(RunService.Heartbeat:Connect(function(dt)
        local locOpen = 1 - locPod.alpha < 0.99
        local radarOpen = 1 - radarPod.alpha < 0.99
        if radarOpen then
            sweepAngle = (sweepAngle + dt * 150) % 360
            sweepPivot.Rotation = sweepAngle
        end
        if not (locOpen or radarOpen) then return end
        locationAccrued += dt
        if locationAccrued < 1 / 15 then return end
        locationAccrued = 0

        local character = Players.LocalPlayer and Players.LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local camera = Workspace.CurrentCamera

        if locOpen then
            if root then
                local p = root.Position
                live(coordLabels[1], "Text", string.format("%.1f", p.X))
                live(coordLabels[2], "Text", string.format("%.1f", p.Y))
                live(coordLabels[3], "Text", string.format("%.1f", p.Z))
            end
            if camera then
                local look = camera.CFrame.LookVector
                live(needle, "Rotation", math.deg(math.atan2(look.X, look.Z)))
            end
        end

        if radarOpen and root then
            local look = root.CFrame.LookVector
            local facing = math.atan2(look.X, look.Z)
            local cos, sin = math.cos(facing), math.sin(facing)
            local origin = root.Position
            local radius = dish.AbsoluteSize.X / 2 / Scale.Scale - 5
            local nearby = 0
            local list = Players:GetPlayers()
            for i, player in ipairs(list) do
                local blip = radarBlip(i)
                local otherRoot = player ~= Players.LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                local offset = otherRoot and (otherRoot.Position - origin)
                local distance = offset and offset.Magnitude
                if distance and distance <= RADAR_RANGE then
                    nearby += 1
                    local rx = (offset.X * cos - offset.Z * sin) / RADAR_RANGE * radius
                    local ry = (offset.X * sin + offset.Z * cos) / RADAR_RANGE * radius
                    live(blip, "Position", UDim2.new(0.5, rx, 0.5, ry))
                    live(blip, "BackgroundColor3", if distance < RADAR_RANGE * 0.5 then Glass.Danger else Glass.Warning)
                    live(blip, "Visible", true)
                else
                    live(blip, "Visible", false)
                end
            end
            for i = #list + 1, #blips do live(blips[i], "Visible", false) end
            live(countValue, "Text", tostring(nearby))
        end
    end))

    ---------------------------------------------------------------------------------------------------
    -- Launcher: the Attachments shelf in the header
    --
    -- Each row is a live miniature of the pod itself, cloned out of the real thing at the moment the
    -- shelf opens, so you pick an attachment by looking at it rather than by reading its name. Click a
    -- tile to deploy or stow it; drag one off the shelf to place it by hand.
    ---------------------------------------------------------------------------------------------------
    local PREVIEW_SCALE = 0.78
    local TILE_W = math.floor(POD_W * PREVIEW_SCALE)
    local STAGE_H = math.floor(POD_H * PREVIEW_SCALE)
    local TILE_H = STAGE_H + 20
    local TILE_GAP = 10

    function W.OpenAttachments(anchor)
        local width = 12 * 2 + TILE_W * 2 + TILE_GAP
        local rows = math.ceil(#pods / 2)
        local height = 40 + rows * (TILE_H + TILE_GAP) - TILE_GAP + 12

        local panel = New("Frame", { Name = "AttachmentShelf", Size = UDim2.fromOffset(width, 0), ClipsDescendants = true }, nil)
        PopupMaterial(panel, 14, 40)
        W:PlacePopup(panel, anchor, 8, height)

        Themed(Text(panel, {
            Text = T("attachments"),
            TextSize = 12,
            Position = UDim2.fromOffset(14, 12),
            Size = UDim2.new(1, -28, 0, 18),
            ZIndex = 2,
        }), { TextColor3 = "TextPrimary" })
        local deployedCount = 0
        for _, pod in ipairs(pods) do
            if pod.Deployed then deployedCount += 1 end
        end
        Themed(Text(panel, {
            Text = string.format("%d / %d out", deployedCount, #pods),
            FontFace = FONT_MEDIUM,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Right,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -14, 0, 12),
            Size = UDim2.fromOffset(110, 18),
            ZIndex = 2,
        }), { TextColor3 = "TextMuted" })

        for i, pod in ipairs(pods) do
            local column, row = (i - 1) % 2, math.floor((i - 1) / 2)
            local tile = New("TextButton", {
                Name = pod.Name,
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(12 + column * (TILE_W + TILE_GAP), 40 + row * (TILE_H + TILE_GAP)),
                Size = UDim2.fromOffset(TILE_W, TILE_H),
                ZIndex = 2,
            }, panel)
            local tileScale = New("UIScale", { Scale = 1 }, tile)

            -- The miniature. A clone is a frozen snapshot, which is fine: the shelf is rebuilt every time
            -- it opens, so what you see is the pod as it reads right now.
            local stage = New("Frame", {
                Name = "Stage",
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(TILE_W, STAGE_H),
                ClipsDescendants = true,
                ZIndex = 2,
            }, tile)
            Corner(stage, 10)
            local preview = pod.Body:Clone()
            preview.Name = "Preview"
            preview.AnchorPoint = Vector2.new(0, 0)
            preview.Position = UDim2.fromOffset(0, 0)
            preview.Size = UDim2.fromOffset(POD_W, POD_H)
            preview.GroupTransparency = pod.Deployed and 0 or 0.55
            New("UIScale", { Scale = PREVIEW_SCALE }, preview)
            preview.Parent = stage

            -- A stowed tile reads as switched off: the miniature dims and the glass behind it goes flat.
            local veil = Themed(New("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = pod.Deployed and 1 or 0.72,
                BorderSizePixel = 0,
                ZIndex = 4,
            }, stage), { BackgroundColor3 = "PaneBottom" })
            Corner(veil, 10)
            local ring = Themed(New("UIStroke", {
                Thickness = pod.Deployed and 1.5 or 1,
                Transparency = pod.Deployed and 0.2 or 0.7,
            }, stage), { Color = function() return pod.Deployed and Glass.Accent or Glass.Rim end })

            local nameLabel = Themed(Text(tile, {
                Text = pod.Title,
                FontFace = FONT_MEDIUM,
                TextSize = 11,
                Position = UDim2.fromOffset(2, STAGE_H + 2),
                Size = UDim2.fromOffset(TILE_W - 46, 18),
                ZIndex = 3,
            }), { TextColor3 = "TextSecondary" })
            local stateLabel = Themed(Text(tile, {
                Text = "",
                FontFace = FONT_MEDIUM,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Right,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -2, 0, STAGE_H + 2),
                Size = UDim2.fromOffset(44, 18),
                ZIndex = 3,
            }), { TextColor3 = function() return pod.Deployed and Glass.Accent or Glass.TextMuted end })

            local function paint()
                stateLabel.Text = pod.Deployed and T("stow") or T("deploy")
                stateLabel.TextColor3 = pod.Deployed and Glass.Accent or Glass.TextMuted
                Tween(veil, Motion.Hover, { BackgroundTransparency = pod.Deployed and 1 or 0.72 })
                Tween(preview, Motion.Hover, { GroupTransparency = pod.Deployed and 0 or 0.55 })
                Tween(ring, Motion.Hover, {
                    Thickness = pod.Deployed and 1.5 or 1,
                    Transparency = pod.Deployed and 0.2 or 0.7,
                    Color = pod.Deployed and Glass.Accent or Glass.Rim,
                })
            end
            paint()

            tile.MouseEnter:Connect(function()
                Tween(tileScale, Motion.Pop, { Scale = 1.04 })
                Tween(nameLabel, Motion.Hover, { TextColor3 = Glass.TextPrimary })
                playSound("Hover")
            end)
            tile.MouseLeave:Connect(function()
                Tween(tileScale, Motion.Pop, { Scale = 1 })
                Tween(nameLabel, Motion.Hover, { TextColor3 = Glass.TextSecondary })
            end)

            -- Click toggles it; dragging the tile out carries the pod straight to where you drop it.
            tile.InputBegan:Connect(function(input)
                if not isPointer(input) then return end
                local start = input.Position
                local dragged = false
                local moveConnection, endConnection
                moveConnection = UserInputService.InputChanged:Connect(function(changed)
                    if not isMove(changed) then return end
                    local delta = changed.Position - start
                    if not dragged then
                        if delta.Magnitude < L.DragSlop then return end
                        dragged = true
                        W:ClosePopup()
                        local k = Scale.Scale
                        pod:Deploy(Vector2.new(changed.Position.X - POD_W * k / 2, changed.Position.Y - POD_H * k / 2))
                        pod.BeginCarry()
                    end
                    pod.MoveCarry(Vector2.new(changed.Position.X - POD_W * Scale.Scale / 2, changed.Position.Y - POD_H * Scale.Scale / 2))
                end)
                endConnection = input.Changed:Connect(function()
                    if input.UserInputState ~= Enum.UserInputState.End then return end
                    moveConnection:Disconnect()
                    endConnection:Disconnect()
                    if dragged then
                        pod.EndCarry()
                    else
                        if pod.Deployed then pod:Stow() else pod:Deploy() end
                        paint()
                    end
                end)
            end)
        end

        W:OpenPopup(panel, function()
            playSound("Close")
            Tween(panel, Motion.FadeOut, { Size = UDim2.fromOffset(width, 0) })
            task.delay(Motion.FadeOut.Time, function() panel:Destroy() end)
        end)
        playSound("Open")
        Tween(panel, Motion.Reveal, { Size = UDim2.fromOffset(width, height) })
    end

    ---------------------------------------------------------------------------------------------------
    -- Pinned controls
    --
    -- Right-clicking a toggle or slider pops it out as its own satellite, so a HUD can be built from the
    -- handful of controls actually being used. A pinned pod is a real pod: it docks, stacks and is
    -- carried like the built-in five, and it shows up on the shelf alongside them.
    --
    -- The pod's own hitbox owns dragging, and it sits above everything inside the body, so the miniature
    -- control gets its own hitbox on the frame below the title bar. That splits the pod cleanly: drag it
    -- by the header, use it everywhere else.
    ---------------------------------------------------------------------------------------------------
    local pinned = {}

    local function unpinButton(pod)
        local button = New("TextButton", {
            Name = "Unpin",
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -8, 1, -8),
            Size = UDim2.fromOffset(14, 14),
            ZIndex = 26,
        }, pod.Frame)
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
        button.MouseButton1Click:Connect(function()
            pinned[pod.PinKey] = nil
            if pod.Unbind then pod.Unbind() end
            pod:Remove()
        end)
    end

    -- The area of a pinned pod that belongs to the control rather than to dragging.
    local function controlSurface(pod)
        return New("TextButton", {
            Name = "Control",
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 30),
            Size = UDim2.new(1, -26, 1, -36),
            ZIndex = 25,
        }, pod.Frame)
    end

    local function buildPinnedToggle(pod, body, object)
        local CAP_W, CAP_H, KNOB = 46, 26, 20
        local capsule = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromOffset(12, 62),
            Size = UDim2.fromOffset(CAP_W, CAP_H),
            ZIndex = 3,
        }, body)
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
        local state = Themed(Text(body, {
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

        controlSurface(pod).MouseButton1Click:Connect(function()
            object:SetValue(not object.Value)
            playSound(object.Value and "ToggleOn" or "ToggleOff")
        end)
        object.Mirror = function() render(false) end
        pod.Unbind = function() object.Mirror = nil end
    end

    local function buildPinnedSlider(pod, body, object)
        local TUBE_H, BEAD = 6, 14
        local value = Themed(Text(body, {
            Text = "",
            TextSize = 22,
            TextTruncate = Enum.TextTruncate.None,
            Position = UDim2.fromOffset(12, 30),
            Size = UDim2.fromOffset(POD_W - 24, 26),
            ZIndex = 3,
        }), { TextColor3 = "TextPrimary" })
        local tube = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromOffset(12 + BEAD / 2, 74),
            Size = UDim2.fromOffset(POD_W - 24 - BEAD - 18, TUBE_H),
            ZIndex = 3,
        }, body)
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
            local text = object.Rounding > 0
                and string.format("%." .. object.Rounding .. "f", object.Value)
                or tostring(math.floor(object.Value + 0.5))
            value.Text = (object.Prefix or "") .. text .. (object.Suffix or "")
            if instant then level:Snap(percent()) else level:Set(percent()) end
        end
        render(true)

        local surface = controlSurface(pod)
        local function setFromX(x)
            local left, width = tube.AbsolutePosition.X, tube.AbsoluteSize.X
            if width <= 0 then return end
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
        object.Mirror = function() render(false) end
        pod.Unbind = function() object.Mirror = nil end
    end

    -- `spec` is { Kind = "Toggle" | "Slider", Key, Title, Object }.
    function W.PinControl(spec)
        local existing = pinned[spec.Key]
        if existing then
            if not existing.Deployed then existing:Deploy() end
            return existing
        end

        local title = (spec.Title or "Control"):upper()
        local pod, body = makePod("Pin_" .. spec.Key, title, "Right")
        pod.PinKey = spec.Key
        pod.Pinned = true
        if spec.Kind == "Slider" then
            buildPinnedSlider(pod, body, spec.Object)
        else
            buildPinnedToggle(pod, body, spec.Object)
        end
        unpinButton(pod)
        pinned[spec.Key] = pod
        pod:Deploy()
        Library:Notify({ Title = "Pinned", Description = spec.Title .. " is now an attachment.", Time = 3 })
        return pod
    end

    ---------------------------------------------------------------------------------------------------
    -- Window hooks
    ---------------------------------------------------------------------------------------------------
    W.OnWindowVisibility = function(visible)
        for _, pod in ipairs(pods) do
            if pod.Deployed and (pod.Docked or visible) then
                pod.alphaTarget = if pod.Docked then (if visible then 1 else 0) else 1
            end
            Animator.Wake(pod)
        end
        if visible then refresh() end
    end

    W.Pods = pods -- scripts (and the launcher) can deploy, stow or re-side a pod directly

    Holder:GetPropertyChangedSignal("Position"):Connect(wakeAll)
    Holder:GetPropertyChangedSignal("Size"):Connect(wakeAll)
    Scale:GetPropertyChangedSignal("Scale"):Connect(wakeAll)

    local previousViewport = W.OnViewportChanged
    W.OnViewportChanged = function()
        if previousViewport then previousViewport() end
        for _, pod in ipairs(pods) do
            if not pod.Docked and not pod.Carried then
                local settled = clampToScreen(Vector2.new(pod.tx, pod.ty))
                pod.tx, pod.ty = settled.X, settled.Y
            end
        end
        wakeAll()
    end
end
