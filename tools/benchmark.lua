--[[
    FishyUI on-device benchmark.

    Runs the same scripted workload against several builds of the library on this machine, one after the
    other, and shows how they compare. Run it from an executor with:

        loadstring(game:HttpGet("https://raw.githubusercontent.com/centvindisc-byte/FishyUI/claude/modest-planck-5ucl4q/tools/benchmark.lua"))()

    It takes about a minute and a half. Leave the mouse alone and keep the game focused while it runs;
    the results appear on screen and in the console. Set getgenv().FishyBenchBuilds to a list of
    { Name, Url, LowGraphics } to compare other builds.

    Frame rate is capped at 60 by default in Roblox, so on a fast machine the fps columns can read the same
    for every build; the "library ms" rows are timed directly and aren't capped. The gap shows best on a
    slow device or with an fps unlocker.
]]

local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local env = (typeof(getgenv) == "function" and getgenv()) or _G

local REPO = "https://raw.githubusercontent.com/centvindisc-byte/FishyUI/"
local BUILDS = env.FishyBenchBuilds or {
    { Name = "main", Url = REPO .. "main/Library.lua" },
    { Name = "optimised", Url = REPO .. "claude/modest-planck-5ucl4q/Library.lua" },
    { Name = "optimised + low gfx", Url = REPO .. "claude/modest-planck-5ucl4q/Library.lua", LowGraphics = true },
}

-------------------------------------------------------------------------------------------------------
-- Results panel
-------------------------------------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "FishyBench"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5000
gui.IgnoreGuiInset = true
local mounted = false
if typeof(gethui) == "function" then mounted = pcall(function() gui.Parent = gethui() end) end
if not mounted then mounted = pcall(function() gui.Parent = CoreGui end) end
if not mounted then gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end

local panel = Instance.new("TextLabel")
panel.AnchorPoint = Vector2.new(0, 1)
panel.Position = UDim2.new(0, 16, 1, -16)
panel.Size = UDim2.fromOffset(640, 60)
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.BackgroundColor3 = Color3.fromRGB(14, 10, 24)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.TextColor3 = Color3.fromRGB(240, 236, 250)
panel.Font = Enum.Font.Code
panel.TextSize = 14
panel.TextXAlignment = Enum.TextXAlignment.Left
panel.TextYAlignment = Enum.TextYAlignment.Top
panel.TextWrapped = false
panel.Text = "FishyUI benchmark: starting..."
panel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel
local padding = Instance.new("UIPadding")
for _, side in ipairs({ "PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight" }) do padding[side] = UDim.new(0, 12) end
padding.Parent = panel

local function status(text)
    panel.Text = text
    print("[FishyBench] " .. text)
end

-------------------------------------------------------------------------------------------------------
-- Measuring
-------------------------------------------------------------------------------------------------------
-- Optional engine counters; not every client exposes them, so each read is guarded.
local function engineCounter(name)
    local ok, value = pcall(function() return Stats[name] end)
    if ok and typeof(value) == "number" then return value end
    return nil
end

-- Runs `perFrame` once a frame for `seconds` and returns frame statistics. Library work the callback
-- triggers is timed separately with os.clock, which is not capped by the frame-rate limit.
local function measure(seconds, perFrame)
    local times, elapsed, frame, luaTime = {}, 0, 0, 0
    local gpu, gpuFrames = 0, 0
    while elapsed < seconds do
        frame += 1
        if perFrame then
            local start = os.clock()
            perFrame(frame)
            luaTime += os.clock() - start
        end
        local dt = RunService.Heartbeat:Wait()
        elapsed += dt
        times[#times + 1] = dt
        local g = engineCounter("RenderGPUFrameTime")
        if g then gpu += g gpuFrames += 1 end
    end
    local sum = 0
    for _, dt in ipairs(times) do sum += dt end
    table.sort(times)
    return {
        fps = #times / sum,
        worst = times[#times] * 1000,
        p95 = times[math.max(1, math.floor(#times * 0.95))] * 1000,
        lua = luaTime * 1000 / #times,
        gpu = if gpuFrames > 0 then gpu / gpuFrames else nil,
    }
end

-------------------------------------------------------------------------------------------------------
-- Workload: a hub-sized window, then each phase
-------------------------------------------------------------------------------------------------------
local LONG_LIST = {}
for i = 1, 200 do LONG_LIST[i] = string.format("Item %03d", i) end

local function buildWindow(Library, lowGraphics)
    local Window = Library:CreateWindow({
        Title = "Benchmark",
        Footer = "FishyUI benchmark",
        ThemeSelect = false,
        AutoShow = true,
        Theme = "Amethyst",
        LowGraphics = lowGraphics == true,
        ToggleKeybind = Enum.KeyCode.F13,
    })
    for t = 1, 4 do
        local tab = Window:AddTab("Tab " .. t)
        for g = 1, 4 do
            local box = if g % 2 == 1 then tab:AddLeftGroupbox("Group " .. g) else tab:AddRightGroupbox("Group " .. g)
            for e = 1, 3 do
                box:AddToggle(string.format("T%d_%d_%d", t, g, e), { Text = "Toggle " .. e, Default = e == 1 })
            end
            box:AddSlider(string.format("S%d_%d", t, g), { Text = "Slider", Min = 0, Max = 100, Default = 50 })
            box:AddDropdown(string.format("D%d_%d", t, g), { Text = "Dropdown", Values = LONG_LIST, Default = 1 })
            local dependent = box:AddDependencyBox()
            dependent:AddToggle(string.format("Dep%d_%d", t, g), { Text = "Only when toggle 1 is on" })
            dependent:SetupDependencies({ { Library.Toggles[string.format("T%d_%d_1", t, g)], true } })
            box:AddLabel("Keybind"):AddKeyPicker(string.format("K%d_%d", t, g), { Default = "None", Text = "Bind" })
        end
    end
    return Window
end

local PHASES = {
    { Key = "idle", Label = "Idle, window open" },
    { Key = "gradient", Label = "Gradient edits (1/frame)" },
    { Key = "theme", Label = "Theme switches" },
    { Key = "drag", Label = "Window drag, 3 pods out" },
    { Key = "slider", Label = "Slider drag (1 step/frame)" },
    { Key = "bubble", Label = "Minimised to bubble" },
}

local function runBuild(build, index)
    local prior = env.Library
    if type(prior) == "table" and type(prior.Unload) == "function" then pcall(prior.Unload, prior) end

    status(string.format("[%d/%d] %s: downloading", index, #BUILDS, build.Name))
    local source = game:HttpGet(build.Url)
    local compiled, err = loadstring(source)
    assert(compiled, "could not compile " .. build.Name .. ": " .. tostring(err))
    local Library = compiled()
    local Window = buildWindow(Library, build.LowGraphics)
    local W = Window._W
    local results = {}

    status(string.format("[%d/%d] %s: warming up", index, #BUILDS, build.Name))
    measure(2)

    status(string.format("[%d/%d] %s: %s", index, #BUILDS, build.Name, PHASES[1].Label))
    results.idle = measure(4)

    status(string.format("[%d/%d] %s: %s", index, #BUILDS, build.Name, PHASES[2].Label))
    local ramps = {}
    for i = 1, 30 do
        ramps[i] = ColorSequence.new(Color3.fromHSV(i / 30, 0.6, 1), Color3.fromHSV((i / 30 + 0.3) % 1, 0.7, 1))
    end
    results.gradient = measure(3, function(frame) Library:SetAccentGradient(ramps[frame % 30 + 1]) end)
    Library:SetAccentGradient(nil)

    status(string.format("[%d/%d] %s: %s", index, #BUILDS, build.Name, PHASES[3].Label))
    local themes = { "Glacier", "Sakura", "Ember", "Amethyst" }
    results.theme = measure(4, function(frame)
        if frame % 30 == 1 then Library:SetTheme(themes[math.floor(frame / 30) % #themes + 1]) end
    end)
    measure(1)

    status(string.format("[%d/%d] %s: %s", index, #BUILDS, build.Name, PHASES[4].Label))
    local pods = W and W.Pods or {}
    for i = 1, math.min(3, #pods) do pods[i]:Deploy() end
    measure(1.5)
    local base = W.Holder.Position
    results.drag = measure(3, function(frame)
        local offset = math.sin(frame / 18) * 140
        W.Holder.Position = UDim2.new(base.X.Scale, base.X.Offset + offset, base.Y.Scale, base.Y.Offset + offset * 0.4)
    end)
    W.Holder.Position = base
    for i = 1, math.min(3, #pods) do pods[i]:Stow() end
    measure(1)

    status(string.format("[%d/%d] %s: %s", index, #BUILDS, build.Name, PHASES[5].Label))
    local slider = Library.Options["S1_1"]
    results.slider = measure(2, function(frame) slider:SetValue(frame % 100) end)

    status(string.format("[%d/%d] %s: %s", index, #BUILDS, build.Name, PHASES[6].Label))
    Library:Toggle(false)
    measure(1.5)
    results.bubble = measure(4)

    Library:Unload()
    measure(1)
    return results
end

-------------------------------------------------------------------------------------------------------
-- Run and report
-------------------------------------------------------------------------------------------------------
task.spawn(function()
    local all = {}
    for i, build in ipairs(BUILDS) do
        local ok, results = pcall(runBuild, build, i)
        if not ok then
            status("Benchmark stopped while running " .. build.Name .. ":\n" .. tostring(results))
            return
        end
        all[i] = results
    end

    local function cell(text, width) return text .. string.rep(" ", math.max(1, width - #text)) end
    local lines = { "FishyUI benchmark (this device)", "" }
    local header = cell("", 30)
    for _, build in ipairs(BUILDS) do header ..= cell(build.Name, 22) end
    table.insert(lines, header)
    for _, phase in ipairs(PHASES) do
        table.insert(lines, phase.Label)
        local rows = {
            { "  fps (avg)", function(r) return string.format("%.1f", r.fps) end },
            { "  worst frame", function(r) return string.format("%.1f ms", r.worst) end },
            { "  95th pct frame", function(r) return string.format("%.1f ms", r.p95) end },
        }
        if phase.Key == "gradient" or phase.Key == "theme" or phase.Key == "drag" or phase.Key == "slider" then
            table.insert(rows, { "  library ms/frame", function(r) return string.format("%.3f ms", r.lua) end })
        end
        if all[1] and all[1][phase.Key].gpu then
            table.insert(rows, { "  GPU frame", function(r) return if r.gpu then string.format("%.2f ms", r.gpu) else "-" end })
        end
        for _, row in ipairs(rows) do
            local line = cell(row[1], 30)
            for i in ipairs(BUILDS) do line ..= cell(row[2](all[i][phase.Key]), 22) end
            table.insert(lines, line)
        end
    end
    table.insert(lines, "")
    table.insert(lines, "Lower ms is better. Screenshot this and send it back.")
    status(table.concat(lines, "\n"))
end)
