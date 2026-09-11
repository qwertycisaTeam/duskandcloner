local HttpService = game:GetService("HttpService")
local Module = {}

function Module:Init(Library)
    local Folder = "DuskAndShineConfigs"
    local FilePath = Folder .. "/TrueSettings.json"

    if not isfolder(Folder) then 
        pcall(function() makefolder(Folder) end) 
    end

    local function Save()
        local data = { Theme = Library.CurrentThemeName, Flags = {} }
        for flag, value in pairs(Library.Flags) do
            if typeof(value) == "Color3" then 
                data.Flags[flag] = { r = value.R, g = value.G, b = value.B, _type = "Color3" }
            elseif typeof(value) == "EnumItem" then 
                data.Flags[flag] = { name = value.Name, typeStr = tostring(value.EnumType):gsub("Enum%.", ""), _type = "Enum" }
            else 
                data.Flags[flag] = value 
            end
        end
        
        pcall(function()
            writefile(FilePath, HttpService:JSONEncode(data))
        end)
    end

    local function Load()
        if not isfile(FilePath) then return end
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(FilePath)) end)
        if not success or type(decoded) ~= "table" then return end
        
        if decoded.Theme and Library.Themes[decoded.Theme] then 
            Library:SetTheme(decoded.Theme) 
        end
        
        if decoded.Flags then
            for flag, savedValue in pairs(decoded.Flags) do
                local parsedValue = savedValue
                if type(savedValue) == "table" then
                    if savedValue._type == "Color3" then parsedValue = Color3.new(savedValue.r, savedValue.g, savedValue.b)
                    elseif savedValue._type == "Enum" then pcall(function() parsedValue = Enum[savedValue.typeStr][savedValue.name] end) end
                end
                
                if Library.ConfigUpdaters[flag] then
                    task.spawn(function() pcall(Library.ConfigUpdaters[flag], parsedValue) end)
                else
                    Library.Flags[flag] = parsedValue
                end
            end
        end
    end

    -- Сразу грузим конфиг при инициализации модуля
    Load()

    -- Запускаем фоновый цикл сохранения каждые 3 секунды
    task.spawn(function()
        while task.wait(3) do
            if getgenv().DS_StopExecution then break end
            Save()
        end
    end)
end

return Module
