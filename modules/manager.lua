local Module = {}
local UI_Icons = {
    Delete = "rbxassetid://103348299780330",      -- korzina
    Rename = "rbxassetid://104417156882773",    -- karandash
    Copy = "rbxassetid://115843248520941",         -- buferobmena
    Price = "rbxassetid://125651659356206",        -- moneta
    Furniture = "rbxassetid://72936320954395",    -- sofayarlik
    Options = "rbxassetid://96935793442177",   -- yarlik
    Explorer = "rbxassetid://111285083640153", -- Provodnik
    JsonFile = "rbxassetid://99263938121768"        -- json
}

local FileManager = {}
local folderName = "DuskAndShine_Houses"

-- 1. Инициализация папки (создает папку в workspace, если ее нет)
function FileManager:Init()
    if not isfolder(folderName) then
        makefolder(folderName)
    end
end

-- 2. Получение списка всех сохраненных домов
function FileManager:GetHouses()
    self:Init()
    local houses = {}
    local files = listfiles(folderName)
    
    for _, path in ipairs(files) do
        -- Вытаскиваем только имя файла без полного пути и без расширения .json
        local fileName = path:match("([^/\\]+)%.json$")
        if fileName then
            table.insert(houses, fileName)
        end
    end
    
    return houses -- Возвращает таблицу с именами (например: {"Mansion", "Starter"})
end

-- 3. Сохранение структуры дома
function FileManager:SaveHouse(name, tableData)
    self:Init()
    -- Превращаем Lua-таблицу с данными дома в строку JSON
    local encodedData = HttpService:JSONEncode(tableData)
    writefile(folderName .. "/" .. name .. ".json", encodedData)
end

-- 4. Загрузка данных дома (Чтение)
function FileManager:LoadHouse(name)
    local path = folderName .. "/" .. name .. ".json"
    if isfile(path) then
        local rawData = readfile(path)
        -- Превращаем JSON обратно в Lua-таблицу для работы клонера
        return HttpService:JSONDecode(rawData)
    end
    return nil
end

-- 5. Удаление файла
function FileManager:DeleteHouse(name)
    local path = folderName .. "/" .. name .. ".json"
    if isfile(path) then
        delfile(path)
    end
end

-- 6. Переименование файла
function FileManager:RenameHouse(oldName, newName)
    local oldPath = folderName .. "/" .. oldName .. ".json"
    local newPath = folderName .. "/" .. newName .. ".json"
    
    if isfile(oldPath) then
        -- Читаем старые данные, пишем в новый файл, удаляем старый
        local data = readfile(oldPath)
        writefile(newPath, data)
        delfile(oldPath)
        return true
    end
    return false
end

return FileManager




return Module
