local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local function notify(text)
    if string.find(string.lower(text), "ошибка") then
        warn("[ULTIMATE СЕЙВЕР]: " .. text)
    else
        print("[ULTIMATE СЕЙВЕР]: " .. text)
    end
    pcall(function() StarterGui:SetCore("SendNotification", {Title = "Ultimate Saver", Text = text, Duration = 5}) end)
end

-- 1. Подключаемся к базе данных игры
local Fsys = game:GetService("ReplicatedStorage"):WaitForChild("Fsys")
local load = require(Fsys).load
local ClientData = load("ClientData")

local data = ClientData.get_data()
local myPlayerName = Players.LocalPlayer.Name

-- 2. Находим профиль владельца дома (с фолбеком на первый доступный профиль)
local targetData = data[myPlayerName] or data[next(data)]

if not targetData or not targetData.house_interior or not targetData.house_interior.furniture then
    return notify("Ошибка: Данные интерьера не найдены в базе ClientData.")
end

local rawFurniture = targetData.house_interior.furniture
local parsedFurniture = {}
local count = 0

-- 3. Выкачиваем чистые серверные данные
for uniqueId, itemData in pairs(rawFurniture) do
    count = count + 1
    
    -- Конвертируем CFrame в массив чисел для JSON
    local formattedCFrame = {}
    if typeof(itemData.cframe) == "CFrame" then
        formattedCFrame = {itemData.cframe:GetComponents()}
    elseif type(itemData.cframe) == "table" then
        formattedCFrame = itemData.cframe
    end

    -- Конвертируем цвета из Color3
    local formattedColors = {}
    if type(itemData.colors) == "table" then
        for _, color in ipairs(itemData.colors) do
            if typeof(color) == "Color3" then
                table.insert(formattedColors, {color.R, color.G, color.B})
            end
        end
    end

    -- Записываем предмет, используя оригинальный масштаб сервера
    table.insert(parsedFurniture, {
        id = itemData.id,
        cframe = formattedCFrame,
        scale = itemData.scale or 1,
        colors = formattedColors
    })
end

local saveData = {
    furniture = parsedFurniture,
    ambiance = {
        Lighting = { ClockTime = game:GetService("Lighting").ClockTime }
    }
}

-- 4. Сохраняем идеальный чертеж
pcall(function() writefile("AdoptMeHouse_Save_Ultimate.json", HttpService:JSONEncode(saveData)) end)
notify("Успех! Сохранен оригинальный серверный кэш. Предметов: " .. count)