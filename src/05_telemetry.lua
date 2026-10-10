-------------------------------------------------------------------------------------------------------
-- Telemetry: live session and network numbers shared by the bubble and the satellite pods. Samples once
-- a second; listeners registered with OnTick run right after each sample.
-------------------------------------------------------------------------------------------------------
local Telemetry = {
    SessionStart = os.clock(),
    Fps = 0,
    Ping = nil,
    PingSamples = {},
    FpsSamples = {},
    Region = "--",
    Executor = "Unknown",
    Listeners = {},
    Running = false,
}
local TELEMETRY_SAMPLES = 32

function Telemetry.Strength(ping)
    if not ping or ping <= 0 then return 0 end
    if ping <= L.PingGood then return 3 end
    if ping <= L.PingFair then return 2 end
    return 1
end

function Telemetry.StrengthColor(strength)
    if strength >= 3 then return Glass.Accent end
    if strength == 2 then return Glass.Warning end
    return Glass.Danger
end

-- 00:12:45
function Telemetry.Clock(seconds)
    seconds = math.max(0, math.floor(seconds))
    return string.format("%02d:%02d:%02d", math.floor(seconds / 3600), math.floor(seconds % 3600 / 60), seconds % 60)
end

-- 2h 14m, or 14m 05s under an hour
function Telemetry.Duration(seconds)
    seconds = math.max(0, math.floor(seconds))
    local hours, minutes = math.floor(seconds / 3600), math.floor(seconds % 3600 / 60)
    if hours > 0 then return string.format("%dh %02dm", hours, minutes) end
    return string.format("%dm %02ds", minutes, seconds % 60)
end

function Telemetry.OnTick(callback)
    table.insert(Telemetry.Listeners, callback)
end

function Telemetry.Start()
    if Telemetry.Running then return end
    Telemetry.Running = true

    if typeof(identifyexecutor) == "function" then
        local ok, name = pcall(identifyexecutor)
        if ok and name then Telemetry.Executor = tostring(name) end
    elseif RunService:IsStudio() then
        Telemetry.Executor = "Studio"
    end

    -- The player's country/region as Roblox reports it. The server's region isn't visible to clients.
    task.spawn(function()
        local player = Players.LocalPlayer
        if not player then return end
        local ok, code = pcall(function() return LocalizationService:GetCountryRegionForPlayerAsync(player) end)
        if ok and typeof(code) == "string" and code ~= "" then Telemetry.Region = code end
    end)

    local function sample()
        Telemetry.Ping = readPingMs()
        table.insert(Telemetry.PingSamples, Telemetry.Ping or 0)
        if #Telemetry.PingSamples > TELEMETRY_SAMPLES then table.remove(Telemetry.PingSamples, 1) end
        for _, listener in ipairs(Telemetry.Listeners) do
            Library:SafeCallback(listener)
        end
    end

    local frames, elapsed = 0, 0
    Library:GiveSignal(RunService.Heartbeat:Connect(function(dt)
        frames += 1
        elapsed += dt
        if elapsed < 1 then return end
        Telemetry.Fps = math.floor(frames / elapsed + 0.5)
        table.insert(Telemetry.FpsSamples, Telemetry.Fps)
        if #Telemetry.FpsSamples > TELEMETRY_SAMPLES then table.remove(Telemetry.FpsSamples, 1) end
        frames, elapsed = 0, 0
        sample()
    end))
    task.defer(sample)
end
