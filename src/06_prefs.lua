-------------------------------------------------------------------------------------------------------
-- Preferences: language, font family, and which setup steps to skip. Saved alongside the theme choice so
-- a returning user drops straight into the interface. A factory reset clears all of it.
-------------------------------------------------------------------------------------------------------
local PREFS_FILE = THEME_FILE_FOLDER .. "/setup.json"

local Prefs = {
    Language = "en",
    FontFamily = "Gotham",
    SkipLanguage = false,
    SkipTheme = false,
    SkipFont = false,
    GlassQuality = "High",
}

local function savePrefs()
    if typeof(writefile) ~= "function" then return end
    pcall(function()
        if typeof(isfolder) == "function" and typeof(makefolder) == "function" and not isfolder(THEME_FILE_FOLDER) then
            makefolder(THEME_FILE_FOLDER)
        end
        writefile(PREFS_FILE, HttpService:JSONEncode(Prefs))
    end)
end

local function loadPrefs()
    if typeof(readfile) ~= "function" or typeof(isfile) ~= "function" then return end
    pcall(function()
        if not isfile(PREFS_FILE) then return end
        local decoded = HttpService:JSONDecode(readfile(PREFS_FILE))
        if typeof(decoded) ~= "table" then return end
        for key, value in pairs(decoded) do
            if Prefs[key] ~= nil then Prefs[key] = value end
        end
    end)
end

local function clearPrefs()
    Prefs.Language, Prefs.FontFamily = "en", "Gotham"
    Prefs.SkipLanguage, Prefs.SkipTheme, Prefs.SkipFont = false, false, false
    Prefs.GlassQuality = "High"
    if typeof(delfile) == "function" and typeof(isfile) == "function" then
        pcall(function()
            if isfile(PREFS_FILE) then delfile(PREFS_FILE) end
            if isfile(THEME_FILE) then delfile(THEME_FILE) end
        end)
    else
        savePrefs()
    end
end

-------------------------------------------------------------------------------------------------------
-- Languages: the ten most spoken on Roblox, English first.
-------------------------------------------------------------------------------------------------------
local Languages = {
    { Code = "en", Name = "English", Native = "English" },
    { Code = "es", Name = "Spanish", Native = "Español" },
    { Code = "pt", Name = "Portuguese", Native = "Português" },
    { Code = "fr", Name = "French", Native = "Français" },
    { Code = "de", Name = "German", Native = "Deutsch" },
    { Code = "ru", Name = "Russian", Native = "Русский" },
    { Code = "tr", Name = "Turkish", Native = "Türkçe" },
    { Code = "ja", Name = "Japanese", Native = "日本語" },
    { Code = "ko", Name = "Korean", Native = "한국어" },
    { Code = "zh", Name = "Chinese", Native = "中文" },
}

local Strings = {
    en = {
        title_language = "Choose your language", title_theme = "Choose your theme", title_font = "Choose your font",
        subtitle = "You can change this anytime in Settings.", continue_ = "Continue",
        dont_show_again = "Don't show this again", attachments = "Attachments",
        deploy = "Deploy", stow = "Stow", factory_reset = "Factory Reset",
    },
    es = {
        title_language = "Elige tu idioma", title_theme = "Elige tu tema", title_font = "Elige tu fuente",
        subtitle = "Puedes cambiarlo cuando quieras en Ajustes.", continue_ = "Continuar",
        dont_show_again = "No mostrar de nuevo", attachments = "Accesorios",
        deploy = "Desplegar", stow = "Guardar", factory_reset = "Restablecer",
    },
    pt = {
        title_language = "Escolha seu idioma", title_theme = "Escolha seu tema", title_font = "Escolha sua fonte",
        subtitle = "Você pode mudar isso quando quiser nas Configurações.", continue_ = "Continuar",
        dont_show_again = "Não mostrar novamente", attachments = "Anexos",
        deploy = "Abrir", stow = "Guardar", factory_reset = "Redefinir",
    },
    fr = {
        title_language = "Choisissez votre langue", title_theme = "Choisissez votre thème", title_font = "Choisissez votre police",
        subtitle = "Vous pouvez le changer à tout moment dans les Paramètres.", continue_ = "Continuer",
        dont_show_again = "Ne plus afficher", attachments = "Modules",
        deploy = "Déployer", stow = "Ranger", factory_reset = "Réinitialiser",
    },
    de = {
        title_language = "Wähle deine Sprache", title_theme = "Wähle dein Design", title_font = "Wähle deine Schriftart",
        subtitle = "Du kannst das jederzeit in den Einstellungen ändern.", continue_ = "Weiter",
        dont_show_again = "Nicht mehr anzeigen", attachments = "Module",
        deploy = "Anzeigen", stow = "Verstauen", factory_reset = "Zurücksetzen",
    },
    ru = {
        title_language = "Выберите язык", title_theme = "Выберите тему", title_font = "Выберите шрифт",
        subtitle = "Это можно изменить в настройках в любое время.", continue_ = "Продолжить",
        dont_show_again = "Больше не показывать", attachments = "Модули",
        deploy = "Открыть", stow = "Убрать", factory_reset = "Сброс",
    },
    tr = {
        title_language = "Dilini seç", title_theme = "Temanı seç", title_font = "Yazı tipini seç",
        subtitle = "Bunu istediğin zaman Ayarlar'dan değiştirebilirsin.", continue_ = "Devam",
        dont_show_again = "Bir daha gösterme", attachments = "Ekler",
        deploy = "Çıkar", stow = "Kaldır", factory_reset = "Sıfırla",
    },
    ja = {
        title_language = "言語を選択", title_theme = "テーマを選択", title_font = "フォントを選択",
        subtitle = "設定からいつでも変更できます。", continue_ = "続ける",
        dont_show_again = "次回から表示しない", attachments = "アタッチメント",
        deploy = "表示", stow = "収納", factory_reset = "初期化",
    },
    ko = {
        title_language = "언어 선택", title_theme = "테마 선택", title_font = "글꼴 선택",
        subtitle = "설정에서 언제든지 변경할 수 있습니다.", continue_ = "계속",
        dont_show_again = "다시 표시 안 함", attachments = "부착물",
        deploy = "꺼내기", stow = "넣기", factory_reset = "초기화",
    },
    zh = {
        title_language = "选择语言", title_theme = "选择主题", title_font = "选择字体",
        subtitle = "你可以随时在设置中更改。", continue_ = "继续",
        dont_show_again = "不再显示", attachments = "附件",
        deploy = "展开", stow = "收起", factory_reset = "恢复默认",
    },
}

local function T(key)
    local table_ = Strings[Library.Language] or Strings.en
    return table_[key] or Strings.en[key] or key
end

function Library:SetLanguage(code)
    if not Strings[code] then return false end
    self.Language = code
    Prefs.Language = code
    savePrefs()
    return true
end

function Library:T(key)
    return T(key)
end

-------------------------------------------------------------------------------------------------------
-- Fonts
-------------------------------------------------------------------------------------------------------
local FontFamilies = {
    { Name = "Gotham", Font = Enum.Font.Gotham, Sample = "Aa" },
    { Name = "Roboto", Font = Enum.Font.Roboto, Sample = "Aa" },
    { Name = "Nunito", Font = Enum.Font.Nunito, Sample = "Aa" },
    { Name = "Ubuntu", Font = Enum.Font.Ubuntu, Sample = "Aa" },
    { Name = "Josefin", Font = Enum.Font.JosefinSans, Sample = "Aa" },
    { Name = "Oswald", Font = Enum.Font.Oswald, Sample = "Aa" },
    { Name = "Merriweather", Font = Enum.Font.Merriweather, Sample = "Aa" },
    { Name = "Mono", Font = Enum.Font.RobotoMono, Sample = "Aa" },
}

local function familyByName(name)
    for _, entry in ipairs(FontFamilies) do
        if entry.Name == name then return entry end
    end
    return FontFamilies[1]
end

function Library:SetFontFamily(name)
    local entry = familyByName(name)
    local base = Font.fromEnum(entry.Font)
    Fonts.Bold = Font.new(base.Family, Enum.FontWeight.Bold)
    Fonts.Medium = Font.new(base.Family, Enum.FontWeight.Medium)
    Fonts.Mono = if entry.Name == "Mono" then Fonts.Bold else FONT_MONO
    self.FontFamily = entry.Name
    self.Scheme.Font = Fonts.Bold
    Prefs.FontFamily = entry.Name
    savePrefs()
    applyTheme()
    return true
end

-- Applies whatever was saved last run. Called before the window is built.
local function applyPrefs()
    loadPrefs()
    Library.Language = Strings[Prefs.Language] and Prefs.Language or "en"
    local entry = familyByName(Prefs.FontFamily)
    local base = Font.fromEnum(entry.Font)
    Fonts.Bold = Font.new(base.Family, Enum.FontWeight.Bold)
    Fonts.Medium = Font.new(base.Family, Enum.FontWeight.Medium)
    Fonts.Mono = if entry.Name == "Mono" then Fonts.Bold else FONT_MONO
    Library.FontFamily = entry.Name
    Library.Scheme.Font = Fonts.Bold
    Library.GlassQuality = if QUALITY_RANK[Prefs.GlassQuality] then Prefs.GlassQuality else "High"
end
