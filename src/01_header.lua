--[[
    FishyUI — liquid glass UI library by Fishy Studios
    Drop-in API replacement for deividcomsono/Obsidian

    Target : Roblox client, Luau, any executor. Also previews in Studio edit mode.
    Load   : loadstring(game:HttpGet("https://raw.githubusercontent.com/centvindisc-byte/FishyUI/main/Library.lua"))()
]]

local cloneref = (typeof(cloneref) == "function" and cloneref) or function(obj) return obj end
local function service(name) return cloneref(game:GetService(name)) end

local CoreGui = service("CoreGui")
local GuiService = service("GuiService")
local HttpService = service("HttpService")
local Lighting = service("Lighting")
local LocalizationService = service("LocalizationService")
local Players = service("Players")
local RunService = service("RunService")
local StarterGui = service("StarterGui")
local Stats = service("Stats")
local TextService = service("TextService")
local TweenService = service("TweenService")
local UserInputService = service("UserInputService")
local Workspace = service("Workspace")

-- Studio edit mode has no executor and no LocalPlayer; the window mounts under StarterGui so it renders in the viewport.
local IS_STUDIO_PREVIEW = RunService:IsStudio() and not RunService:IsRunning()
local ENV = (typeof(getgenv) == "function" and getgenv()) or _G

local FONT_BOLD = Font.fromEnum(Enum.Font.GothamBold)
local FONT_MEDIUM = Font.new(FONT_BOLD.Family, Enum.FontWeight.Medium)
local FONT_MONO = Font.fromEnum(Enum.Font.RobotoMono)

-- The live font roles. Every label built through Text() binds to its role, so picking a font in setup
-- re-applies across the whole interface, including UI that already exists.
local Fonts = { Bold = FONT_BOLD, Medium = FONT_MEDIUM, Mono = FONT_MONO }
