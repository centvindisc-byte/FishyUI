-------------------------------------------------------------------------------------------------------
-- Sound: soft glass feedback. One built-in click is retuned per voice (pitch + level) rather than
-- pulling remote assets, so it always loads and costs nothing to stream.
-------------------------------------------------------------------------------------------------------
local SoundService = service("SoundService")
local CLICK_ASSET = "rbxasset://sounds/electronicpingshort.wav"

Prefs.SoundEnabled = true
Prefs.SoundVolume = 0.6

local VOICES = {
    ToggleOn = { Speed = 1.65, Volume = 0.30 },
    ToggleOff = { Speed = 1.12, Volume = 0.24 },
    Tick = { Speed = 2.30, Volume = 0.07, MinGap = 0.035 }, -- slider steps
    Tab = { Speed = 0.72, Volume = 0.26 }, -- the low "whoosh" on page changes
    Open = { Speed = 0.95, Volume = 0.32 },
    Close = { Speed = 0.66, Volume = 0.26 },
    Hover = { Speed = 2.60, Volume = 0.045, MinGap = 0.05 },
    Deploy = { Speed = 1.35, Volume = 0.24 },
    Press = { Speed = 1.90, Volume = 0.16 },
}

local voiceSounds, lastPlayed = {}, {}

local function voiceSound(name)
    local existing = voiceSounds[name]
    if existing and existing.Parent then return existing end
    local voice = VOICES[name]
    local sound = New("Sound", {
        Name = "FishyUI_" .. name,
        SoundId = CLICK_ASSET,
        PlaybackSpeed = voice.Speed,
        Volume = voice.Volume,
        RollOffMaxDistance = 0,
    }, SoundService)
    voiceSounds[name] = sound
    return sound
end

-- Plays a UI voice. Silently does nothing when sound is off or the asset failed to load.
-- Assigns the upvalue declared in 03_core.lua rather than shadowing it with a new local.
function playSound(name)
    if not Library.SoundEnabled then return end
    local voice = VOICES[name]
    if not voice then return end
    local now = os.clock()
    if voice.MinGap and now - (lastPlayed[name] or 0) < voice.MinGap then return end
    lastPlayed[name] = now
    pcall(function()
        local sound = voiceSound(name)
        sound.Volume = voice.Volume * Library.SoundVolume
        sound.TimePosition = 0
        sound:Play()
    end)
end

Library.SoundEnabled = true
Library.SoundVolume = 0.6

function Library:SetSoundEnabled(enabled)
    self.SoundEnabled = enabled == true
    Prefs.SoundEnabled = self.SoundEnabled
    savePrefs()
end

function Library:SetSoundVolume(volume)
    self.SoundVolume = math.clamp(tonumber(volume) or 0.6, 0, 1)
    Prefs.SoundVolume = self.SoundVolume
    savePrefs()
end

function Library:PlaySound(name)
    playSound(name)
end

local function applySoundPrefs()
    Library.SoundEnabled = Prefs.SoundEnabled ~= false
    Library.SoundVolume = tonumber(Prefs.SoundVolume) or 0.6
end
