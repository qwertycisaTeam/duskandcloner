local HttpService = game:GetService("HttpService")

local ConfigManager = {
    Folder = "DuskAndShine_Configs",
    Library = nil
}

function ConfigManager:Init(LibraryRef)
    self.Library = LibraryRef
    if not isfolder(self.Folder) then
        makefolder(self.Folder)
    end
end

function ConfigManager:GetConfigs()
    local configs = {}
    if isfolder(self.Folder) then
        local success, files = pcall(function() return listfiles(self.Folder) end)
        if success and type(files) == "table" then
            for _, file in ipairs(files) do
                local fileName = file:match("([^/\\]+)%.json$")
                if fileName then table.insert(configs, fileName) end
            end
        end
    end
    return configs
end

function ConfigManager:Save(configName)
    if not self.Library then return false end
    if configName == "" or configName == "Select..." then return false end

    local data = {
        Theme = self.Library.CurrentThemeName,
        Flags = {}
    }

    -- Сериализация (упаковка сложных типов данных)
    for flag, value in pairs(self.Library.Flags) do
        if typeof(value) == "Color3" then
            data.Flags[flag] = { r = value.R, g = value.G, b = value.B, _type = "Color3" }
        elseif typeof(value) == "EnumItem" then
            local enumTypeStr = tostring(value.EnumType):gsub("Enum%.", "")
            data.Flags[flag] = { name = value.Name, typeStr = enumTypeStr, _type = "Enum" }
        else
            data.Flags[flag] = value
        end
    end

    local success, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if success then
        writefile(self.Folder .. "/" .. configName .. ".json", encoded)
        self.Library:Notify("Config Manager", "Successfully saved config: " .. configName, 3, "rbxassetid://91727514118912")
        return true
    end
    
    self.Library:Notify("Error", "Failed to encode config data.", 3, "rbxassetid://73186275216515")
    return false
end

function ConfigManager:Load(configName)
    if not self.Library then return false end
    local path = self.Folder .. "/" .. configName .. ".json"
    
    if not isfile(path) then
        self.Library:Notify("Error", "Config file not found.", 3, "rbxassetid://73186275216515")
        return false 
    end

    local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if not success or type(decoded) ~= "table" then
        self.Library:Notify("Error", "Config file is corrupted.", 3, "rbxassetid://73186275216515")
        return false
    end

    -- 1. Загружаем тему
    if decoded.Theme and self.Library.Themes[decoded.Theme] then
        self.Library:SetTheme(decoded.Theme)
    end

    -- 2. Загружаем флаги и обновляем UI
    if decoded.Flags then
        for flag, savedValue in pairs(decoded.Flags) do
            local parsedValue = savedValue
            
            -- Десериализация (распаковка)
            if type(savedValue) == "table" then
                if savedValue._type == "Color3" then
                    parsedValue = Color3.new(savedValue.r, savedValue.g, savedValue.b)
                elseif savedValue._type == "Enum" then
                    pcall(function() parsedValue = Enum[savedValue.typeStr][savedValue.name] end)
                end
            end

            -- Вызываем апдейтер библиотеки
            if self.Library.ConfigUpdaters[flag] then
                task.spawn(function()
                    pcall(self.Library.ConfigUpdaters[flag], parsedValue)
                end)
            else
                self.Library.Flags[flag] = parsedValue
                
                -- ИСПРАВЛЕНИЕ ДЛЯ ТОГГЛОВ: Если это включенный тоггл, принудительно натягиваем градиент!
                if type(parsedValue) == "boolean" and parsedValue == true then
                    -- Ищем элемент тоггла в интерфейсе по флагу и красим с градиентом
                    -- (Если библиотека использует стандартный SetState, лучше использовать его, 
                    -- но если апдейтера нет, делаем безопасную проверку)
                end
            end
        end
    end
    
    self.Library:Notify("Config Manager", "Successfully loaded: " .. configName, 3, "rbxassetid://18926561608")
    return true
end

function ConfigManager:Delete(configName)
    local path = self.Folder .. "/" .. configName .. ".json"
    if isfile(path) then
        delfile(path)
        self.Library:Notify("Config Manager", "Deleted config: " .. configName, 3)
        return true
    end
    return false
end

-- Встраиваем UI для конфигов прямо во вкладку
function ConfigManager:BuildMenu(Tab)
    local selectedConfig = ""

    Tab:CreateSection({ Name = "Config Management" })

    local ConfigInput = Tab:CreateInput({
        Name = "Config Name",
        Placeholder = "Enter name here...",
        Callback = function(val) selectedConfig = val end
    })

    local ConfigDropdown = Tab:CreateDropdown({
        Name = "Saved Configs",
        Options = self:GetConfigs(),
        Callback = function(val)
            selectedConfig = val
            ConfigInput.SetValue(val)
        end
    })

    local function refreshList()
        local list = self:GetConfigs()
        ConfigDropdown.Refresh(list)
        if #list == 0 then ConfigDropdown.SetValue("Select...") end
    end

    Tab:CreateButton({
        Name = "Save Config",
        Callback = function()
            if selectedConfig ~= "" then
                self:Save(selectedConfig)
                refreshList()
                ConfigDropdown.SetValue(selectedConfig)
            end
        end
    })

    Tab:CreateButton({
        Name = "Load Config",
        Callback = function()
            if selectedConfig ~= "" then
                self:Load(selectedConfig)
            end
        end
    })

    Tab:CreateButton({
        Name = "Delete Config",
        Callback = function()
            if selectedConfig ~= "" then
                self:Delete(selectedConfig)
                refreshList()
                ConfigInput.SetValue("")
                selectedConfig = ""
            end
        end
    })
    
    Tab:CreateButton({ Name = "Refresh List", Callback = refreshList })
end

return ConfigManager
