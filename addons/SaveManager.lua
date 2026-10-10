-------------------------------------------------------------------------------------------------------
-- FishyUI SaveManager
--
-- Drop-in replacement for Obsidian's addon of the same name, so a script that already does
--
--     SaveManager:SetLibrary(Library)
--     SaveManager:SetFolder("MyHub")
--     SaveManager:IgnoreThemeSettings()
--     SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
--     SaveManager:BuildConfigSection(Tab)
--     SaveManager:LoadAutoloadConfig()
--
-- keeps working with only the loadstring URL changed.
--
-- Configs are JSON: one entry per registered element, tagged with its type so it can be handed back to
-- the right SetValue on load. Color3 and EnumItem have no JSON form, so they travel as strings.
-------------------------------------------------------------------------------------------------------
local HttpService = game:GetService("HttpService")

local SaveManager = {
    Library = nil,
    Folder = "FishyUI",
    SubFolder = "",
    Ignore = {},
    Options = {},
}

local fileSupport = typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"

local function safeIsFolder(path)
    return typeof(isfolder) == "function" and isfolder(path)
end

local function safeMakeFolder(path)
    if typeof(makefolder) == "function" and not safeIsFolder(path) then
        pcall(makefolder, path)
    end
end

local function safeListFiles(path)
    if typeof(listfiles) ~= "function" then return {} end
    local ok, list = pcall(listfiles, path)
    return ok and list or {}
end

-------------------------------------------------------------------------------------------------------
-- Per-type serialisation. Each entry records its type so loading never has to guess.
-------------------------------------------------------------------------------------------------------
SaveManager.Parser = {
    Toggle = {
        Save = function(idx, object) return { type = "Toggle", idx = idx, value = object.Value == true } end,
        Load = function(idx, data, library)
            local object = library.Toggles[idx]
            if object then object:SetValue(data.value) end
        end,
    },
    Slider = {
        Save = function(idx, object) return { type = "Slider", idx = idx, value = tostring(object.Value) } end,
        Load = function(idx, data, library)
            local object = library.Options[idx]
            if object then object:SetValue(tonumber(data.value)) end
        end,
    },
    Input = {
        Save = function(idx, object) return { type = "Input", idx = idx, text = tostring(object.Value or "") } end,
        Load = function(idx, data, library)
            local object = library.Options[idx]
            if object then object:SetValue(data.text) end
        end,
    },
    Dropdown = {
        Save = function(idx, object)
            -- Multi keeps a set; single keeps one key. Both are stored as-is.
            return { type = "Dropdown", idx = idx, value = object.Value, multi = object.Multi == true }
        end,
        Load = function(idx, data, library)
            local object = library.Options[idx]
            if object then object:SetValue(data.value) end
        end,
    },
    ColorPicker = {
        Save = function(idx, object)
            return {
                type = "ColorPicker",
                idx = idx,
                value = object.Value:ToHex(),
                transparency = object.Transparency,
            }
        end,
        Load = function(idx, data, library)
            local object = library.Options[idx]
            if not object then return end
            local ok, color = pcall(Color3.fromHex, data.value)
            if ok then object:SetValueRGB(color, data.transparency) end
        end,
    },
    KeyPicker = {
        Save = function(idx, object)
            return { type = "KeyPicker", idx = idx, key = tostring(object.Value), mode = tostring(object.Mode) }
        end,
        Load = function(idx, data, library)
            local object = library.Options[idx]
            if object then object:SetValue({ data.key, data.mode }) end
        end,
    },
}

-------------------------------------------------------------------------------------------------------
-- Setup
-------------------------------------------------------------------------------------------------------
function SaveManager:SetLibrary(library)
    self.Library = library
    return self
end

function SaveManager:SetIgnoreIndexes(list)
    for _, key in ipairs(list or {}) do
        self.Ignore[key] = true
    end
    return self
end

function SaveManager:SetFolder(folder)
    self.Folder = folder
    self:BuildFolderTree()
    return self
end

function SaveManager:SetSubFolder(folder)
    self.SubFolder = folder or ""
    self:BuildFolderTree()
    return self
end

function SaveManager:ConfigFolder()
    if self.SubFolder ~= "" then
        return string.format("%s/settings/%s", self.Folder, self.SubFolder)
    end
    return self.Folder .. "/settings"
end

function SaveManager:BuildFolderTree()
    safeMakeFolder(self.Folder)
    safeMakeFolder(self.Folder .. "/settings")
    if self.SubFolder ~= "" then
        safeMakeFolder(self:ConfigFolder())
    end
end

function SaveManager:CheckFolderTree()
    self:BuildFolderTree()
end

-- The theme addon owns these, so a config never fights it for control of the palette.
function SaveManager:IgnoreThemeSettings()
    self:SetIgnoreIndexes({
        "ThemeManager_Theme",
        "ThemeManager_Gradient",
        "ThemeManager_CustomName",
        "ThemeManager_CustomList",
        "ThemePick",
        "AccentGradient",
        "FontPick",
        "LanguagePick",
        "CursorStyle",
        "LowGraphics",
        "DPI",
        "NotifySide",
    })
    return self
end

-------------------------------------------------------------------------------------------------------
-- Save / load / delete
-------------------------------------------------------------------------------------------------------
function SaveManager:Save(name)
    if not fileSupport then return false, "no file access" end
    if not name or name == "" then return false, "no config name" end
    local library = self.Library
    if not library then return false, "no library" end

    local data = { objects = {} }
    for idx, object in pairs(library.Toggles) do
        if not self.Ignore[idx] then
            table.insert(data.objects, self.Parser.Toggle.Save(idx, object))
        end
    end
    for idx, object in pairs(library.Options) do
        local parser = self.Parser[object.Type]
        if parser and not self.Ignore[idx] then
            table.insert(data.objects, parser.Save(idx, object))
        end
    end

    self:BuildFolderTree()
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if not ok then return false, "encode failed" end
    local written = pcall(function()
        writefile(string.format("%s/%s.json", self:ConfigFolder(), name), encoded)
    end)
    return written, written and nil or "write failed"
end

function SaveManager:Load(name)
    if not fileSupport then return false, "no file access" end
    if not name or name == "" then return false, "no config name" end
    local library = self.Library
    if not library then return false, "no library" end

    local path = string.format("%s/%s.json", self:ConfigFolder(), name)
    if not isfile(path) then return false, "config does not exist" end

    local ok, decoded = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if not ok or typeof(decoded) ~= "table" or typeof(decoded.objects) ~= "table" then
        return false, "decode failed"
    end

    for _, entry in ipairs(decoded.objects) do
        local parser = self.Parser[entry.type]
        if parser and not self.Ignore[entry.idx] then
            -- One bad entry must not abandon the rest of the config.
            pcall(parser.Load, entry.idx, entry, library)
        end
    end
    return true
end

function SaveManager:Delete(name)
    if not fileSupport or typeof(delfile) ~= "function" then return false, "no file access" end
    local path = string.format("%s/%s.json", self:ConfigFolder(), name)
    if not isfile(path) then return false, "config does not exist" end
    local ok, err = pcall(delfile, path)
    return ok, err
end

function SaveManager:RefreshConfigList()
    local list = {}
    for _, path in ipairs(safeListFiles(self:ConfigFolder())) do
        if typeof(path) == "string" and path:sub(-5) == ".json" then
            local name = path:match("([^/\\]+)%.json$")
            if name and name ~= "autoload" then table.insert(list, name) end
        end
    end
    table.sort(list)
    return list
end

-------------------------------------------------------------------------------------------------------
-- Autoload
-------------------------------------------------------------------------------------------------------
function SaveManager:SetAutoloadConfig(name)
    if not fileSupport then return false end
    self:BuildFolderTree()
    return pcall(function()
        writefile(self:ConfigFolder() .. "/autoload.txt", tostring(name))
    end)
end

function SaveManager:GetAutoloadConfig()
    if not fileSupport then return nil end
    local path = self:ConfigFolder() .. "/autoload.txt"
    if not isfile(path) then return nil end
    local ok, name = pcall(readfile, path)
    if ok and typeof(name) == "string" and name ~= "" then return name end
    return nil
end

function SaveManager:LoadAutoloadConfig()
    local name = self:GetAutoloadConfig()
    if not name then return false end
    local ok, err = self:Load(name)
    if self.Library then
        self.Library:Notify({
            Title = "Config",
            Description = ok and ("Auto loaded " .. name) or ("Could not auto load: " .. tostring(err)),
            Time = 4,
        })
    end
    return ok
end

-------------------------------------------------------------------------------------------------------
-- UI
-------------------------------------------------------------------------------------------------------
function SaveManager:BuildConfigSection(tab)
    local library = self.Library
    if not library or not tab then return end
    local groupbox = tab:AddRightGroupbox("Configuration")

    groupbox:AddInput("SaveManager_ConfigName", {
        Text = "Config name",
        Placeholder = "default",
        Finished = true,
    })

    local list = self:RefreshConfigList()
    groupbox:AddDropdown("SaveManager_ConfigList", {
        Text = "Saved configs",
        Values = list,
        AllowNull = true,
        Default = list[1],
    })

    self.Options.ConfigName = library.Options.SaveManager_ConfigName
    self.Options.ConfigList = library.Options.SaveManager_ConfigList

    local function refresh()
        self.Options.ConfigList:SetValues(self:RefreshConfigList())
    end

    groupbox:AddButton({
        Text = "Create",
        Func = function()
            local name = self.Options.ConfigName.Value
            if not name or name == "" then
                library:Notify({ Title = "Config", Description = "Name the config first.", Time = 4 })
                return
            end
            local ok, err = self:Save(name)
            refresh()
            library:Notify({
                Title = "Config",
                Description = ok and ("Created " .. name) or ("Could not create: " .. tostring(err)),
                Time = 4,
            })
        end,
    }):AddButton({
        Text = "Load",
        Func = function()
            local name = self.Options.ConfigList.Value
            if not name then return end
            local ok, err = self:Load(name)
            library:Notify({
                Title = "Config",
                Description = ok and ("Loaded " .. name) or ("Could not load: " .. tostring(err)),
                Time = 4,
            })
        end,
    })

    groupbox:AddButton({
        Text = "Overwrite",
        Func = function()
            local name = self.Options.ConfigList.Value
            if not name then return end
            local ok, err = self:Save(name)
            library:Notify({
                Title = "Config",
                Description = ok and ("Overwrote " .. name) or ("Could not overwrite: " .. tostring(err)),
                Time = 4,
            })
        end,
    }):AddButton({
        Text = "Refresh",
        Func = refresh,
    })

    groupbox:AddButton({
        Text = "Delete",
        Risky = true,
        DoubleClick = true,
        Func = function()
            local name = self.Options.ConfigList.Value
            if not name then return end
            local ok, err = self:Delete(name)
            refresh()
            library:Notify({
                Title = "Config",
                Description = ok and ("Deleted " .. name) or ("Could not delete: " .. tostring(err)),
                Time = 4,
            })
        end,
    })

    groupbox:AddDivider()

    local autoloadLabel = groupbox:AddLabel("Autoload: " .. (self:GetAutoloadConfig() or "none"))
    local function paintAutoload()
        autoloadLabel:SetText("Autoload: " .. (self:GetAutoloadConfig() or "none"))
    end

    groupbox:AddButton({
        Text = "Set as autoload",
        Func = function()
            local name = self.Options.ConfigList.Value
            if not name then return end
            self:SetAutoloadConfig(name)
            paintAutoload()
            library:Notify({ Title = "Config", Description = name .. " will load on start.", Time = 4 })
        end,
    }):AddButton({
        Text = "Clear autoload",
        Func = function()
            self:SetAutoloadConfig("")
            paintAutoload()
            library:Notify({ Title = "Config", Description = "Autoload cleared.", Time = 4 })
        end,
    })

    self:SetIgnoreIndexes({ "SaveManager_ConfigName", "SaveManager_ConfigList" })
end

return SaveManager
