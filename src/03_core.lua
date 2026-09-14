-------------------------------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------------------------------
local Assets = {
    GlassEdge = "rbxassetid://108437916503362",
    GlassGlow = "rbxassetid://99623734860368",
    Spark = "rbxassetid://86707188750389",
}

local Motion = {
    Reflow = TweenInfo.new(0.46, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    DragReflow = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Settle = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Hover = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Press = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Pop = TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    Drop = TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    Collapse = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut),
    Expand = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Reveal = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    FadeIn = TweenInfo.new(0.34, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    FadeOut = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Blur = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Scroll = TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    -- Entrances and exits: things arrive on a long, soft curve and leave quickly.
    Intro = TweenInfo.new(0.52, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    IntroSoft = TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Outro = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
    Slide = TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
}

local L = {
    ViewportFill = 0.94,
    MinWindow = Vector2.new(600, 400),
    FooterHeight = 28,
    ResizeGrip = 18,
    HeaderButton = 28,
    HeaderButtons = 5, -- minimise, themes, palette, attachments, cursor
    SliceBaseRadius = 18, -- GlassEdge / GlassGlow textures are authored for an 18px corner
    GlowRingInset = 28, -- GlassGlow's hollow centre starts this far in (at SliceScale 1)

    SidebarWidth = 208,
    SidebarInset = 12,
    BrandHeight = 56,
    TabHeight = 38,
    TabGap = 4,
    TabRadius = 10,
    IconX = 12,
    IconSize = 16,
    SubHeight = 28,
    DrawerPadTop = 2,
    DrawerPadBottom = 6,
    BeadWidth = 4,
    BeadHeight = 14,

    DragSlop = 8, -- a press that moves this far picks a tab up; less than this is a click
    LiftScale = 1.05,
    MagnetRange = 44, -- within this distance of its gap, in any direction, a carried tab is pulled in

    PageHeaderHeight = 60,
    PagePadding = 14,
    ColumnGap = 12,
    CardPadding = 12,
    CardRadius = 12,
    ElementGap = 10,

    BubbleHeight = 44,
    BubbleMargin = 12,
    BubbleEdgeMagnet = 72, -- screen px: the bubble and floating pods dock onto an edge released this close
    WindowEdgeMagnet = 72, -- the same for the window
    WindowMargin = 12,
    TapSlop = 6,
    SignalBarWidth = 3,
    SignalBarGap = 2,
    SignalBarHeights = { 5, 9, 13 },
    PingGood = 100,
    PingFair = 200,
}
L.RailX = L.IconX + L.IconSize / 2 -- the sub-tab rail runs straight down from the tab icon's centre
L.SubLabelX = L.RailX + 14
-- Width a page header must leave clear on the right so its title never runs under the header buttons.
L.HeaderReserve = 14 + L.HeaderButtons * L.HeaderButton + (L.HeaderButtons - 1) * 6 + 14
L.EdgeRailWidth = 52 -- the slim icon rail the window collapses into at a screen edge
L.RailPushDepth = 0.42 -- fraction of the window dragged off-screen that triggers rail mode

local Springs = {
    TabLens = { Height = L.TabHeight, Stiffness = 170, Damping = 0.8, MaxStretch = 22, StretchPerSpeed = 0.045, Squash = 5, PressX = 4, PressY = 2, FlareRest = 0.62, FlarePeak = 0.24 },
    Bead = { Height = L.BeadHeight, Stiffness = 210, Damping = 0.75, MaxStretch = 9, StretchPerSpeed = 0.035, Squash = 1, PressX = 0, PressY = 0 },
    Slot = { Height = L.TabHeight, Stiffness = 260, Damping = 0.78, MaxStretch = 12, StretchPerSpeed = 0.04, Squash = 3, PressX = 0, PressY = 0 },
    ListLens = { Height = 28, Stiffness = 320, Damping = 0.82, MaxStretch = 10, StretchPerSpeed = 0.03, Squash = 3, PressX = 0, PressY = 0 },
}

-------------------------------------------------------------------------------------------------------
-- Library
-------------------------------------------------------------------------------------------------------
local Library = {
    LocalPlayer = Players.LocalPlayer,
    IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,
    ScreenGui = nil,
    Window = nil,
    KeybindFrame = nil,

    Toggled = false,
    Unloaded = false,

    Options = {},
    Toggles = {},
    Labels = {},
    Buttons = {},
    DependencyBoxes = {},
    Signals = {},
    UnloadSignals = {},

    -- Lucide icon name -> image. Names that aren't mapped fall back to a small ring.
    Icons = {},

    Themes = Themes,
    ThemeOrder = ThemeOrder,
    Theme = "Amethyst",
    Language = "en",
    FontFamily = "Gotham",
    AccentGradient = nil, -- a custom ColorSequence for accent fills; nil follows the theme
    Registry = {}, -- instance -> { property = token name | function }

    ActivityLog = {}, -- newest-first { time, title }
    ActivityListeners = {},

    CornerRadius = 14,
    DPIScale = 1,
    NotifySide = "Right",
    ShowCustomCursor = true,
    ForceCheckbox = false,
    ShowToggleFrameInKeybinds = true,
    ToggleKeybind = Enum.KeyCode.RightControl,

    -- Obsidian scheme keys, kept in sync with the active theme so ThemeManager keeps working.
    Scheme = {
        BackgroundColor = Glass.PaneMid,
        MainColor = Glass.PaneTop,
        AccentColor = Glass.AccentDeep,
        OutlineColor = Glass.PaneTop,
        FontColor = Glass.TextPrimary,
        RedColor = Glass.Danger,
        DarkColor = Glass.PaneBottom,
        WhiteColor = Color3.new(1, 1, 1),
        Font = FONT_BOLD,
    },
}

-------------------------------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------------------------------
local function New(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local function Tween(inst, info, goal)
    local t = TweenService:Create(inst, info, goal)
    t:Play()
    return t
end

local function Corner(parent, radius)
    return New("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

-- Declared here, defined in 07_sound.lua. The files are concatenated in name order, so materials and
-- elements built before that point would otherwise compile their calls as a nil global.
local playSound

local function resolveToken(source)
    if typeof(source) == "function" then return source() end
    return Glass[source]
end

-- Binds instance properties to the live palette. Each property maps to a token name, or to a function
-- for values that also depend on state (the active tab's label, a toggle that is on, ...).
-- The registry keeps strong references: Roblox can collect the Lua proxy of an instance that is still on
-- screen, which would silently drop it from a weak table. Destroyed instances are pruned on apply instead.
local function Themed(inst, props)
    local bound = Library.Registry[inst]
    if not bound then
        bound = {}
        Library.Registry[inst] = bound
    end
    for property, source in pairs(props) do
        bound[property] = source
        inst[property] = resolveToken(source)
    end
    return inst
end

local function applyTheme()
    for inst, bound in pairs(Library.Registry) do
        if inst.Parent == nil then
            Library.Registry[inst] = nil -- closed popups and destroyed rows
        else
            for property, source in pairs(bound) do
                inst[property] = resolveToken(source)
            end
        end
    end
end

-- The gradient used by accent fills (toggles, sliders, bars). A custom gradient from the palette editor
-- overrides the theme's two-stop accent.
local function accentSequence()
    return Library.AccentGradient or ColorSequence.new(Glass.AccentDeep, Glass.Accent)
end

-- A theme token nudged toward another one. Satellites float over the game rather than over the window's
-- own glass, so their muted text needs lifting toward the primary colour to stay readable on the flatter,
-- lower-contrast themes (Midnight, Onyx, Smoke).
local function mixToken(from, to, alpha)
    return function() return Glass[from]:Lerp(Glass[to], alpha) end
end

function Library:SetAccentGradient(sequence)
    self.AccentGradient = sequence
    applyTheme()
end

-- A short line for the Activity satellite. Notifications feed it too.
function Library:Log(title)
    table.insert(self.ActivityLog, 1, { time = os.date("%H:%M:%S"), title = tostring(title) })
    while #self.ActivityLog > 20 do table.remove(self.ActivityLog) end
    for _, listener in ipairs(self.ActivityListeners) do
        self:SafeCallback(listener)
    end
end

local function syncScheme()
    local scheme = Library.Scheme
    scheme.BackgroundColor = Glass.PaneMid
    scheme.MainColor = Glass.PaneTop
    scheme.AccentColor = Glass.AccentDeep
    scheme.OutlineColor = Glass.PaneTop:Lerp(Glass.AccentDeep, 0.35)
    scheme.FontColor = Glass.TextPrimary
    scheme.DarkColor = Glass.PaneBottom
end

local function Text(parent, props)
    local label = New("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        FontFace = FONT_BOLD,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, nil)
    for k, v in pairs(props) do label[k] = v end
    label.Parent = parent
    -- Bind to the font role it was built with, so a later font change reaches it.
    local role = "Bold"
    if label.FontFace == FONT_MONO then
        role = "Mono"
    elseif label.FontFace == FONT_MEDIUM then
        role = "Medium"
    end
    Themed(label, { FontFace = function() return Fonts[role] end })
    return label
end

local function textWidth(text, size, font)
    return TextService:GetTextSize(text, size, font, Vector2.new(4000, 200)).X
end

local function merge(defaults, overrides)
    local out = {}
    for k, v in pairs(defaults) do out[k] = v end
    for k, v in pairs(overrides or {}) do out[k] = v end
    return out
end

local function without(list, excluded)
    local out = {}
    for _, item in ipairs(list) do
        if item ~= excluded then table.insert(out, item) end
    end
    return out
end

local function viewportSize()
    local cam = Workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local function toPixels(udim2)
    local vp = viewportSize()
    return Vector2.new(udim2.X.Scale * vp.X + udim2.X.Offset, udim2.Y.Scale * vp.Y + udim2.Y.Offset)
end

local function resolveIcon(icon)
    if typeof(icon) == "number" then return "rbxassetid://" .. icon end
    if typeof(icon) == "string" then
        if icon:match("^rbxasset") or icon:match("^https?://") then return icon end
        if tonumber(icon) then return "rbxassetid://" .. icon end
        return Library.Icons[icon]
    end
    return nil
end

local function resolveKeyCode(bind)
    if typeof(bind) == "EnumItem" then return bind end
    local name = bind
    if typeof(bind) == "table" then name = bind.Value end
    if typeof(name) == "string" then
        local ok, key = pcall(function() return Enum.KeyCode[name] end)
        if ok then return key end
    end
    return nil
end

local KEY_SHORT_NAMES = {
    LeftShift = "LShift", RightShift = "RShift", LeftControl = "LCtrl", RightControl = "RCtrl",
    LeftAlt = "LAlt", RightAlt = "RAlt", LeftSuper = "LCmd", RightSuper = "RCmd", Return = "Enter",
    Backspace = "Back", CapsLock = "Caps", Escape = "Esc", PageUp = "PgUp", PageDown = "PgDn",
    MB1 = "MB1", MB2 = "MB2", MB3 = "MB3",
    Zero = "0", One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9",
}
local function keyDisplayName(name)
    if not name or name == "" or name == "None" then return "None" end
    return KEY_SHORT_NAMES[name] or name
end

local function isPointer(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local function readPingMs()
    local ok, value = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if ok and typeof(value) == "number" and value > 0 then return value end
    local player = Players.LocalPlayer
    if player then
        local okPing, seconds = pcall(player.GetNetworkPing, player)
        if okPing and typeof(seconds) == "number" and seconds > 0 then return seconds * 1000 end
    end
    return nil
end

local function mountGui(gui)
    local candidates = {}
    if IS_STUDIO_PREVIEW then
        table.insert(candidates, StarterGui)
    else
        if typeof(gethui) == "function" then
            local ok, hui = pcall(gethui)
            if ok and typeof(hui) == "Instance" then table.insert(candidates, hui) end
        end
        table.insert(candidates, CoreGui)
        if Players.LocalPlayer then
            table.insert(candidates, Players.LocalPlayer:WaitForChild("PlayerGui"))
        end
    end
    for _, parent in ipairs(candidates) do
        if pcall(function() gui.Parent = parent end) and gui.Parent == parent then return end
    end
end

function Library:GiveSignal(connection)
    table.insert(self.Signals, connection)
    return connection
end

function Library:SafeCallback(callback, ...)
    if typeof(callback) ~= "function" then return end
    local ok, err = pcall(callback, ...)
    if not ok then warn("[FishyUI] callback error: " .. tostring(err)) end
end

-------------------------------------------------------------------------------------------------------
-- Animator
--
-- One Heartbeat drives every spring in the library. Objects join with Animator.Wake and leave on their
-- own once :Step(dt) reports they have come to rest, so idle UI costs nothing.
-------------------------------------------------------------------------------------------------------
local Animator = { active = {}, pending = {}, stepping = false, connection = nil }
local ANIMATOR_MAX_STEP = 1 / 240

function Animator.Wake(object)
    if Library.Unloaded then return end
    if Animator.stepping then
        Animator.pending[object] = true -- tables must not grow while they are being iterated
    else
        Animator.active[object] = true
    end
    if Animator.connection then return end
    Animator.connection = RunService.Heartbeat:Connect(function(dt)
        dt = math.min(dt, 1 / 20)
        local steps = math.max(1, math.ceil(dt / ANIMATOR_MAX_STEP))
        Animator.stepping = true
        for object in pairs(Animator.active) do
            local moving = false
            for _ = 1, steps do
                moving = object:Step(dt / steps)
                if not moving then break end
            end
            if not moving then Animator.active[object] = nil end
        end
        Animator.stepping = false
        for object in pairs(Animator.pending) do
            Animator.active[object] = true
            Animator.pending[object] = nil
        end
        if next(Animator.active) == nil then
            Animator.connection:Disconnect()
            Animator.connection = nil
        end
    end)
end

function Animator.Stop()
    if Animator.connection then Animator.connection:Disconnect() end
    Animator.connection = nil
    table.clear(Animator.active)
    table.clear(Animator.pending)
end

-- A 1D spring rendered through `onStep(value, velocity)`. `epsilon` is the rest tolerance in value units.
local function Spring(stiffness, dampingRatio, value, onStep, epsilon)
    epsilon = epsilon or 0.01
    local damping = 2 * math.sqrt(stiffness) * dampingRatio
    local spring = { value = value, velocity = 0, target = value }

    function spring:Step(dt)
        self.velocity += (stiffness * (self.target - self.value) - damping * self.velocity) * dt
        self.value += self.velocity * dt
        if math.abs(self.target - self.value) < epsilon and math.abs(self.velocity) < epsilon * 10 then
            self.value, self.velocity = self.target, 0
            onStep(self.value, 0)
            return false
        end
        onStep(self.value, self.velocity)
        return true
    end

    function spring:Set(target)
        self.target = target
        Animator.Wake(self)
    end

    function spring:Snap(target)
        self.value, self.target, self.velocity = target, target, 0
        onStep(target, 0)
    end

    onStep(value, 0)
    return spring
end
