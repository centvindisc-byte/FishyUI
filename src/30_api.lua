-------------------------------------------------------------------------------------------------------
-- Library API
-------------------------------------------------------------------------------------------------------
function Library:Toggle(value)
    if self.Unloaded or not self.Window then return end
    -- In edge-rail mode the window is parked off-screen: any toggle brings it back rather than trying to
    -- show a window that is not where the user left it. ExitRail clears the flag before calling back in.
    local W = self.Window._W
    if W and W.RailActive then
        W.ExitRail()
        return
    end
    if value == nil then value = not self.Toggled end
    self.Toggled = value
    self.Window:_setVisible(value)
end

-- Morphs the whole palette to the named theme, colours and material alike, and remembers the choice.
function Library:SetTheme(name)
    local theme = Themes[name]
    if not theme or self.Unloaded then return false end
    self.Theme = name
    self.AccentGradient = nil -- a new theme starts from its own accent; the palette can recustomise after

    local from = {}
    for key in pairs(theme) do from[key] = Glass[key] end
    if self.ThemeMorph then self.ThemeMorph:Disconnect() end

    -- In-between frames only repaint what moved (the shared tokens and every font binding stay put); the
    -- last frame repaints everything, so the end state is exactly what a full apply produces.
    local function blend(alpha, final)
        for key, target in pairs(theme) do
            local start = from[key]
            if typeof(start) == "number" then
                Glass[key] = start + (target - start) * alpha
            else
                Glass[key] = start:Lerp(target, alpha)
            end
        end
        applyTheme(not final)
    end

    if self.LowGraphics then
        -- No morph: the new theme lands in one repaint instead of half a second of them.
        self.ThemeMorph = nil
        blend(1, true)
        syncScheme()
        self:UpdateKeybindFrame()
    else
        local elapsed = 0
        self.ThemeMorph = RunService.Heartbeat:Connect(function(dt)
            elapsed += dt
            local t = math.min(1, elapsed / THEME_MORPH_TIME)
            blend(TweenService:GetValue(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), t >= 1)
            if t >= 1 then
                self.ThemeMorph:Disconnect()
                self.ThemeMorph = nil
                syncScheme()
                self:UpdateKeybindFrame()
            end
        end)
    end

    saveThemeChoice(name)
    local window = self.Window
    if window and window._W then
        window._W:OnThemeChanged()
        if window.OnThemeChanged then task.spawn(window.OnThemeChanged, name) end
    end
    return true
end

-- Low graphics mode, for weak devices. It turns off what is purely decorative and costly to draw: the
-- full-screen blur behind the window, the animated backdrop, the lensed rims, halos and specular lines on
-- every glass surface, the bubble's signal pulse, and the theme morph (themes switch instantly). Every
-- control, colour and animation that carries meaning stays. Off by default; the choice is saved like the
-- sound and cursor settings, and CreateWindow's LowGraphics option overrides it.
function Library:SetLowGraphics(enabled)
    enabled = enabled == true
    self.LowGraphics = enabled
    Prefs.LowGraphics = enabled
    savePrefs()
    for _, gui in ipairs({ self.ScreenGui, notifyGui }) do
        if gui and gui.Parent then
            for _, inst in ipairs(gui:GetDescendants()) do
                if DECOR_NAMES[inst.Name] and inst:IsA("GuiObject") then inst.Visible = not enabled end
            end
        end
    end
    local W = self.Window and self.Window._W
    if W then
        if W.Blur then W.Blur.Enabled = not enabled end
        if W.RefreshAmbient then W.RefreshAmbient() end
        if W.OnLowGraphics then W.OnLowGraphics(enabled) end
    end
    return true
end

-- Wipes the saved language, font, theme and "don't show again" choices, then walks the setup flow again.
function Library:FactoryReset()
    clearPrefs()
    self.AccentGradient = nil
    self:SetLanguage("en")
    self:SetFontFamily("Gotham")
    self:SetTheme("Amethyst")
    local window = self.Window
    if window and window.ShowSetup then
        self:Toggle(false)
        task.delay(0.35, function() window:ShowSetup() end)
    end
    return true
end

-- Obsidian's five scheme keys map onto the closest FishyUI tokens; any token can also be named directly,
-- which is how a custom theme carries material values (PaneTransparency, EdgeTransparency, ...) that the
-- five-colour scheme has no room for. ThemeManager uses this for themes that aren't one of the built-ins.
local SCHEME_TO_TOKEN = {
    BackgroundColor = "PaneMid",
    MainColor = "PaneTop",
    AccentColor = "AccentDeep",
    OutlineColor = "Rim",
    FontColor = "TextPrimary",
    RedColor = "Danger",
    DarkColor = "PaneBottom",
}

function Library:ApplyScheme(scheme)
    if typeof(scheme) ~= "table" then return false end
    for key, value in pairs(scheme) do
        local token = SCHEME_TO_TOKEN[key] or key
        local current = Glass[token]
        if current ~= nil and typeof(value) == typeof(current) then
            Glass[token] = value
        end
    end
    applyTheme()
    syncScheme()
    self:UpdateKeybindFrame()
    return true
end

-- A flat copy of the live palette, suitable for writing to disk and handing back to ApplyScheme.
function Library:GetScheme()
    local copy = {}
    for key, value in pairs(Glass) do copy[key] = value end
    return copy
end

function Library:SetDPIScale(percent)
    self.DPIScale = percent / 100
    if self.Window then self.Window:_rescale() end
end

function Library:OnUnload(callback)
    table.insert(self.UnloadSignals, callback)
end

function Library:Unload()
    if self.Unloaded then return end
    self.Unloaded = true
    if self.ThemeMorph then self.ThemeMorph:Disconnect() end
    Animator.Stop()
    for _, connection in ipairs(self.Signals) do
        pcall(function() connection:Disconnect() end)
    end
    for _, callback in ipairs(self.UnloadSignals) do
        task.spawn(callback)
    end
    local W = self.Window and self.Window._W
    if W and W.Blur then pcall(function() W.Blur:Destroy() end) end
    if self.ScreenGui then pcall(function() self.ScreenGui:Destroy() end) end
    if notifyStack then pcall(function() notifyStack:Destroy() end) end
    if notifyGui then pcall(function() notifyGui:Destroy() end) end
    -- The UI voices live in SoundService, outside the ScreenGui, so nothing above takes them with it;
    -- every re-execution used to leave another set behind.
    for name, sound in pairs(voiceSounds) do
        pcall(function() sound:Destroy() end)
        voiceSounds[name] = nil
    end
    table.clear(self.Registry)
    table.clear(ThemeWritten)
end

ENV.Library = Library
return Library
