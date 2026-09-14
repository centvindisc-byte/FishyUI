-------------------------------------------------------------------------------------------------------
-- Notifications: glass toasts that glide in from the notify side, carry a fuse of accent light that
-- burns down over their lifetime, then fold away. Toasts are short-lived, so they take the current
-- palette at creation instead of joining the theme registry.
-------------------------------------------------------------------------------------------------------
local NOTIFY_WIDTH = 292
local notifyStack, notifyGui

local function getNotifyStack()
    if notifyStack and notifyStack.Parent then return notifyStack end
    local gui = Library.ScreenGui
    if not gui then
        -- Kept in a file-local so Unload can destroy it. Notifying before CreateWindow (or after an
        -- unload) used to mint a fresh ScreenGui that nothing held a reference to, leaking one per call.
        if notifyGui and notifyGui.Parent then
            gui = notifyGui
        else
            gui = New("ScreenGui", { Name = "FishyUINotifications", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1001 }, nil)
            mountGui(gui)
            notifyGui = gui
        end
    end
    local right = Library.NotifySide ~= "Left"
    notifyStack = New("Frame", {
        Name = "Notifications",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(right and 1 or 0, 0),
        Position = UDim2.new(right and 1 or 0, right and -16 or 16, 0, GuiService:GetGuiInset().Y + 16),
        Size = UDim2.new(0, NOTIFY_WIDTH, 1, -32),
        ZIndex = 300,
    }, gui)
    New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = right and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left,
    }, notifyStack)
    return notifyStack
end

local notifyOrder = 0
function Library:Notify(info, duration)
    if typeof(info) ~= "table" then
        info = { Title = "", Description = tostring(info), Time = duration }
    end
    local lifetime = tonumber(info.Time or duration) or 4
    self:Log(info.Title ~= nil and info.Title ~= "" and info.Title or info.Description)
    local stack = getNotifyStack()
    local fromRight = self.NotifySide ~= "Left"
    notifyOrder += 1

    local slot = New("Frame", {
        Name = "Toast",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        LayoutOrder = notifyOrder,
    }, stack)
    local toast = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.fromOffset(fromRight and NOTIFY_WIDTH + 40 or -(NOTIFY_WIDTH + 40), 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = math.min(Glass.PaneTransparency, 0.08),
        BorderSizePixel = 0,
        ZIndex = 2,
    }, slot)
    Corner(toast, 12)
    New("UIGradient", { Rotation = 115, Color = paneGradientColor() }, toast)
    New("UIStroke", { Color = Glass.Rim, Transparency = Glass.BorderTransparency, Thickness = 1 }, toast)
    -- The accent bar is placed freely on the toast; the text stacks inside its own padded body.
    local bar = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0),
        Size = UDim2.new(0, 3, 1, -22),
        BackgroundColor3 = Glass.Accent,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, toast)
    Corner(bar, 2)

    local body = New("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 3,
    }, toast)
    New("UIPadding", {
        PaddingTop = UDim.new(0, 11),
        PaddingBottom = UDim.new(0, 13),
        PaddingLeft = UDim.new(0, 20),
        PaddingRight = UDim.new(0, 14),
    }, body)
    New("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, body)

    if info.Title and info.Title ~= "" then
        Text(body, {
            Text = info.Title,
            TextSize = 13,
            TextColor3 = Glass.TextPrimary,
            Size = UDim2.new(1, 0, 0, 18),
            LayoutOrder = 1,
            ZIndex = 3,
        })
    end
    if info.Description and info.Description ~= "" then
        Text(body, {
            Text = info.Description,
            FontFace = FONT_MEDIUM,
            TextSize = 12,
            RichText = true,
            TextColor3 = Glass.TextSecondary,
            TextWrapped = true,
            TextTruncate = Enum.TextTruncate.None,
            TextYAlignment = Enum.TextYAlignment.Top,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2,
            ZIndex = 3,
        })
    end
    local fuse = New("Frame", {
        Name = "Fuse",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = Glass.Accent,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        ZIndex = 4,
    }, slot)
    Corner(fuse, 1)

    local closed = false
    local notification = {}
    function notification:Destroy()
        if closed then return end
        closed = true
        Tween(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.fromOffset(fromRight and NOTIFY_WIDTH + 40 or -(NOTIFY_WIDTH + 40), 0),
        })
        Tween(fuse, Motion.FadeOut, { BackgroundTransparency = 1 })
        task.delay(0.22, function()
            Tween(slot, Motion.Reveal, { Size = UDim2.new(1, 0, 0, 0) })
            task.delay(Motion.Reveal.Time, function() slot:Destroy() end)
        end)
    end

    task.defer(function()
        if closed then return end
        local height = toast.AbsoluteSize.Y
        Tween(slot, Motion.Reveal, { Size = UDim2.new(1, 0, 0, height) })
        Tween(toast, Motion.Drop, { Position = UDim2.fromOffset(0, 0) })
        Tween(fuse, TweenInfo.new(lifetime, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) })
        task.delay(lifetime, function() notification:Destroy() end)
    end)
    return notification
end

function Library:SetNotifySide(side)
    self.NotifySide = side
    if notifyStack then
        notifyStack:Destroy()
        notifyStack = nil
    end
end
