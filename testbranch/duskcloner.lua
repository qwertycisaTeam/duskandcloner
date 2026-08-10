-- duskcloner.lua
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Глобальная таблица с логикой
getgenv().ReplicatorLogic = {}
local Logic = getgenv().ReplicatorLogic

-- Вспомогательная функция (вызовы UI-уведомлений будем делать из UI-файла, здесь оставляем только принты)
local function logAction(text)
    print("[ReplicatorLogic]: " .. text)
end

-- ==========================================
-- ФУНКЦИЯ КОПИРОВАНИЯ (PARSER)
-- ==========================================
function Logic.CopyHouse()
    local Fsys = ReplicatedStorage:WaitForChild("Fsys")
    local load = require(Fsys).load
    local ClientData = load("ClientData")

    local data = ClientData.get_data()
    local myPlayerName = LocalPlayer.Name
    local targetData = data[myPlayerName] or data[next(data)]

    if not targetData or not targetData.house_interior or not targetData.house_interior.furniture then
        return false, "Данные интерьера не найдены в базе ClientData."
    end

    local rawFurniture = targetData.house_interior.furniture
    local parsedFurniture = {}
    local count = 0

    for uniqueId, itemData in pairs(rawFurniture) do
        count = count + 1
        local formattedCFrame = typeof(itemData.cframe) == "CFrame" and {itemData.cframe:GetComponents()} or itemData.cframe
        
        local formattedColors = {}
        if type(itemData.colors) == "table" then
            for _, color in ipairs(itemData.colors) do
                if typeof(color) == "Color3" then table.insert(formattedColors, {color.R, color.G, color.B}) end
            end
        end

        table.insert(parsedFurniture, {
            id = itemData.id, cframe = formattedCFrame, scale = itemData.scale or 1, colors = formattedColors
        })
    end

    local saveData = {
        furniture = parsedFurniture,
        ambiance = { Lighting = { ClockTime = game:GetService("Lighting").ClockTime } }
    }

    local success, err = pcall(function() 
        writefile("AdoptMeHouse_Save_Ultimate.json", HttpService:JSONEncode(saveData)) 
    end)
    
    if success then return true, count else return false, tostring(err) end
end

-- ==========================================
-- ФУНКЦИЯ ПОСТРОЙКИ (BUILDER)
-- ==========================================
function Logic.PasteHouse()
    local success, fileData = pcall(function() return readfile("AdoptMeHouse_Save_Ultimate.json") end)
    if not success then return false, "Файл сохранения не найден." end

    local savedHouse = HttpService:JSONDecode(fileData)
    local rawFurniture = savedHouse.furniture or savedHouse
    local successCount, failCount = 0, 0
    local pendingChanges = {}

    table.sort(rawFurniture, function(a, b) return a.cframe[2] < b.cframe[2] end)

    local downloadApi = ReplicatedStorage:WaitForChild("API"):WaitForChild("DownloadsAPI/Download")
    local buyFurnituresRemote = ReplicatedStorage:WaitForChild("API"):WaitForChild("HousingAPI/BuyFurnitures")
    local pushFurnitureEvent = ReplicatedStorage:WaitForChild("API"):WaitForChild("HousingAPI/PushFurnitureChanges")

    for _, item in ipairs(rawFurniture) do
        local fId = item.id
        local baseCFrame = CFrame.new(unpack(item.cframe))
        local buyProps = {cframe = baseCFrame}
        
        if item.colors and #item.colors > 0 then
            local c3table = {}
            for _, c in ipairs(item.colors) do table.insert(c3table, Color3.new(c[1], c[2], c[3])) end
            buyProps.colors = c3table
        end

        pcall(function() downloadApi:InvokeServer("Furniture", fId) end)
        local buildSuccess, response = pcall(function() return buyFurnituresRemote:InvokeServer({{ kind = fId, properties = buyProps }}) end)
        
        if buildSuccess and type(response) == "table" and response.success and response.results and response.results[1] and response.results[1].unique then
            successCount = successCount + 1
            local changeArgs = { unique = response.results[1].unique, cframe = baseCFrame }
            if item.scale and item.scale ~= 1 then changeArgs.scale = item.scale end
            if buyProps.colors then changeArgs.colors = buyProps.colors end
            table.insert(pendingChanges, changeArgs)
        else
            failCount = failCount + 1
        end
        task.wait(0.2)
    end

    local chunk = {}
    for i, change in ipairs(pendingChanges) do
        table.insert(chunk, change)
        if #chunk >= 50 or i == #pendingChanges then
            pcall(function() pushFurnitureEvent:FireServer(chunk) end)
            chunk = {}; task.wait(0.5) 
        end
    end

    return true, successCount, failCount
end

-- ==========================================
-- ЦИКЛ АВТОВХОДА В ДВЕРИ (AUTO-ENTER)
-- ==========================================
Logic.IsAutoEntering = false
local successDoorModule, DoorsM = pcall(function() return require(ReplicatedStorage.ClientModules.Core.DoorsM.DoorsM) end)

function Logic.ToggleAutoEnter(state)
    Logic.IsAutoEntering = state
    if not state then return end

    task.spawn(function()
        while Logic.IsAutoEntering do
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                local searchFolders = { workspace:FindFirstChild("Interiors"), workspace:FindFirstChild("HouseExteriors"), workspace:FindFirstChild("Properties") }
                local closestDoor, touchPart, shortestDist = nil, nil, 15

                for _, folder in pairs(searchFolders) do
                    if folder then
                        for _, obj in pairs(folder:GetDescendants()) do
                            if obj.Name == "WorkingParts" then
                                local tp = obj:FindFirstChild("TouchToEnter")
                                if tp then
                                    local dist = (hrp.Position - tp.Position).Magnitude
                                    if dist < shortestDist then closestDoor = obj.Parent; touchPart = tp; shortestDist = dist end
                                end
                            end
                        end
                    end
                end

                if closestDoor and touchPart then
                    if successDoorModule and DoorsM then
                        local doorObj = DoorsM.get_door(closestDoor)
                        if doorObj then doorObj.is_open = true; doorObj.can_enter = true end
                    end
                    if firetouchinterest then
                        firetouchinterest(hrp, touchPart, 0); task.wait(0.1); firetouchinterest(hrp, touchPart, 1)
                        task.wait(2)
                    end
                end
            end
            task.wait(1)
        end
    end)
end
