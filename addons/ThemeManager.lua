-------------------------------------------------------------------------------------------------------
-- FishyUI ThemeManager
--
-- Drop-in replacement for Obsidian's addon of the same name, so a script that already does
--
--     ThemeManager:SetLibrary(Library)
--     ThemeManager:SetFolder("MyHub")
--     ThemeManager:ApplyToTab(Tab)
--
-- keeps working with only the loadstring URL changed.
--
-- FishyUI themes are richer than a five-colour scheme: alongside the colours each one carries material
-- values (how clear the pane is, how much light the edge catches, whether there is a sheen at all). The
-- ten built-ins are selected by name; a custom theme is a flat table of tokens written to disk, and both
-- routes end at Library:ApplyScheme.
-------------------------------------------------------------------------------------------------------
local ThemeManager = {
    Library = nil,
    Folder = "FishyUI",
    Options = {},
}

-- Executor file helpers. Without an executor these all no-op, so the addon is safe in Studio.
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
-- Colour serialisation. Color3 has no JSON form, so every colour travels as a hex string.
-------------------------------------------------------------------------------------------------------
local function encodeValue(value)
    if typeof(value) == "Color3" then return "#" .. value:ToHex() end
    return value
end

local function decodeValue(value)
    if typeof(value) == "string" and value:sub(1, 1) == "#" then
        local ok, color = pcall(Color3.fromHex, value:sub(2))
        if ok then return color end
    end
    return value
end

-------------------------------------------------------------------------------------------------------
-- Setup
-------------------------------------------------------------------------------------------------------
function ThemeManager:SetLibrary(library)
    self.Library = library
    return self
end

function ThemeManager:BuildFolderTree()
    safeMakeFolder(self.Folder)
    safeMakeFolder(self.Folder .. "/themes")
    safeMakeFolder(self.Folder .. "/settings")
end

function ThemeManager:CheckFolderTree()
    self:BuildFolderTree()
end

function ThemeManager:SetFolder(folder)
    self.Folder = folder
    self:BuildFolderTree()
    return self
end

-------------------------------------------------------------------------------------------------------
-- Applying
-------------------------------------------------------------------------------------------------------
-- `theme` is either the name of a built-in or a flat table of tokens.
function ThemeManager:ApplyTheme(theme)
    local library = self.Library
    if not library then return false end

    if typeof(theme) == "string" then
        local custom = self:GetCustomTheme(theme)
        if custom then
            library:ApplyScheme(custom)
            return true
        end
        return library:SetTheme(theme)
    end

    if typeof(theme) == "table" then
        library:ApplyScheme(theme)
        return true
    end
    return false
end

function ThemeManager:ThemeUpdate()
    -- Kept for API compatibility: FishyUI repaints from its own registry the moment the palette changes,
    -- so there is nothing to push here.
    return true
end

function ThemeManager:GetCustomTheme(name)
    if not fileSupport or not name or name == "" then return nil end
    local path = string.format("%s/themes/%s.json", self.Folder, name)
    if not isfile(path) then return nil end
    local ok, decoded = pcall(function()
        return game:GetService("HttpService"):JSONDecode(readfile(path))
    end)
    if not ok or typeof(decoded) ~= "table" then return nil end
    local theme = {}
    for key, value in pairs(decoded) do theme[key] = decodeValue(value) end
    return theme
end

function ThemeManager:SaveCustomTheme(name)
    if not fileSupport or not name or name == "" then return false, "no file access" end
    local library = self.Library
    if not library then return false, "no library" end
    local scheme = library:GetScheme()
    local encoded = {}
    for key, value in pairs(scheme) do encoded[key] = encodeValue(value) end
    self:BuildFolderTree()
    local ok, err = pcall(function()
        writefile(string.format("%s/themes/%s.json", self.Folder, name),
            game:GetService("HttpService"):JSONEncode(encoded))
    end)
    return ok, err
end

function ThemeManager:Delete(name)
    if not fileSupport or typeof(delfile) ~= "function" then return false, "no file access" end
    local path = string.format("%s/themes/%s.json", self.Folder, name)
    if not isfile(path) then return false, "theme does not exist" end
    local ok, err = pcall(delfile, path)
    return ok, err
end

function ThemeManager:GetCustomThemeList()
    local list = {}
    for _, path in ipairs(safeListFiles(self.Folder .. "/themes")) do
        if typeof(path) == "string" and path:sub(-5) == ".json" then
            local name = path:match("([^/\\]+)%.json$")
            if name then table.insert(list, name) end
        end
    end
    table.sort(list)
    return list
end

-------------------------------------------------------------------------------------------------------
-- The default theme, reapplied on the next run
-------------------------------------------------------------------------------------------------------
function ThemeManager:SaveDefault(name)
    if not fileSupport then return false end
    self:BuildFolderTree()
    local ok = pcall(function()
        writefile(self.Folder .. "/settings/theme.txt", tostring(name))
    end)
    return ok
end

function ThemeManager:LoadDefault()
    if not fileSupport then return false end
    local path = self.Folder .. "/settings/theme.txt"
    if not isfile(path) then return false end
    local ok, name = pcall(readfile, path)
    if not ok or typeof(name) ~= "string" or name == "" then return false end
    return self:ApplyTheme(name)
end

-------------------------------------------------------------------------------------------------------
-- UI
-------------------------------------------------------------------------------------------------------
function ThemeManager:CreateThemeManager(groupbox)
    local library = self.Library
    if not library or not groupbox then return end

    local builtIn = {}
    for _, name in ipairs(library.ThemeOrder) do table.insert(builtIn, name) end

    groupbox:AddDropdown("ThemeManager_Theme", {
        Text = "Theme",
        Values = builtIn,
        Default = library.Theme,
        Callback = function(value)
            library:SetTheme(value)
            self:SaveDefault(value)
        end,
    })

    groupbox:AddPalette("ThemeManager_Gradient", { Text = "Accent gradient" })

    groupbox:AddDivider()

    groupbox:AddInput("ThemeManager_CustomName", {
        Text = "Custom theme name",
        Placeholder = "my theme",
        Finished = true,
    })

    local customList = self:GetCustomThemeList()
    groupbox:AddDropdown("ThemeManager_CustomList", {
        Text = "Saved themes",
        Values = customList,
        AllowNull = true,
        Default = customList[1],
    })

    local function refreshList()
        local list = self:GetCustomThemeList()
        self.Options.CustomList:SetValues(list)
    end

    groupbox:AddButton({
        Text = "Save custom",
        Func = function()
            local name = self.Options.CustomName.Value
            if not name or name == "" then
                library:Notify({ Title = "Theme", Description = "Name the theme first.", Time = 4 })
                return
            end
            local ok, err = self:SaveCustomTheme(name)
            refreshList()
            library:Notify({
                Title = "Theme",
                Description = ok and ("Saved " .. name) or ("Could not save: " .. tostring(err)),
                Time = 4,
            })
        end,
    }):AddButton({
        Text = "Load",
        Func = function()
            local name = self.Options.CustomList.Value
            if not name then return end
            self:ApplyTheme(name)
            self:SaveDefault(name)
            library:Notify({ Title = "Theme", Description = "Loaded " .. name, Time = 4 })
        end,
    })

    groupbox:AddButton({
        Text = "Delete custom",
        Risky = true,
        DoubleClick = true,
        Func = function()
            local name = self.Options.CustomList.Value
            if not name then return end
            local ok, err = self:Delete(name)
            refreshList()
            library:Notify({
                Title = "Theme",
                Description = ok and ("Deleted " .. name) or ("Could not delete: " .. tostring(err)),
                Time = 4,
            })
        end,
    }):AddButton({
        Text = "Refresh list",
        Func = refreshList,
    })

    groupbox:AddButton({
        Text = "Reset to Amethyst",
        Func = function()
            library:SetAccentGradient(nil)
            library:SetTheme("Amethyst")
            self:SaveDefault("Amethyst")
        end,
    })

    -- Mirror the elements the addon created so its own methods can read them back.
    self.Options.Theme = library.Options.ThemeManager_Theme
    self.Options.CustomName = library.Options.ThemeManager_CustomName
    self.Options.CustomList = library.Options.ThemeManager_CustomList
end

function ThemeManager:ApplyToGroupbox(groupbox)
    self:CreateThemeManager(groupbox)
end

function ThemeManager:ApplyToTab(tab)
    self:CreateThemeManager(tab:AddLeftGroupbox("Themes"))
end

return ThemeManager
