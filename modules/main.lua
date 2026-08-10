local Module = {}

function Module:Init(Library, Window, Tab)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    -- ==========================================
    -- 1. ОСНОВНЫЕ ДЕЙСТВИЯ (ACTIONS)
    -- ==========================================
    Tab:CreateSection({ Name = "House Replicator Actions" })
    Tab:CreatePreviewButton({
        Image = "rbxassetid://603108166", -- 100% рабочая публичная текстура
        Height = 150, 
        Callback = function() end
    })
    -- КНОПКА КОПИРОВАНИЯ
    Tab:CreatePreviewButton({
        Image = "rbxassetid://72958619361915", 
        Height = 150, 
        Callback = function()
            -- Запускаем в отдельном потоке, чтобы не тормозить UI
            task.spawn(function()
                print("Copy structure executed!")
                local HttpService = game:GetService("HttpService")
                local Fsys = game:GetService("ReplicatedStorage"):WaitForChild("Fsys")
                local load = require(Fsys).load
                local ClientData = load("ClientData")
                
                local data = ClientData.get_data()
                local myPlayerName = Players.LocalPlayer.Name
                
                local targetData = data[myPlayerName] or data[next(data)]
                
                if not targetData or not targetData.house_interior or not targetData.house_interior.furniture then
                    return Library:Notify("Ошибка", "Данные интерьера не найдены.", 3)
                end
                
                local rawFurniture = targetData.house_interior.furniture
                local parsedFurniture = {}
                local count = 0
                
                for uniqueId, itemData in pairs(rawFurniture) do
                    count = count + 1
                    local formattedCFrame = {}
                    if typeof(itemData.cframe) == "CFrame" then
                        formattedCFrame = {itemData.cframe:GetComponents()}
                    elseif type(itemData.cframe) == "table" then
                        formattedCFrame = itemData.cframe
                    end
                
                    local formattedColors = {}
                    if type(itemData.colors) == "table" then
                        for _, color in ipairs(itemData.colors) do
                            if typeof(color) == "Color3" then
                                table.insert(formattedColors, {color.R, color.G, color.B})
                            end
                        end
                    end
                
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
                
                -- Сохраняем в единый файл
                pcall(function() writefile("AdoptMeHouse_Save.json", HttpService:JSONEncode(saveData)) end)
                Library:Notify("Сохранено", "Скопировано предметов: " .. tostring(count), 3)
            end)
        end
    })

    -- КНОПКА ВСТАВКИ
    Tab:CreatePreviewButton({
        Image = "rbxassetid://129747602158533", 
        Height = 150, 
        Callback = function()
            -- Запускаем в отдельном потоке, чтобы UI не завис на время постройки
            task.spawn(function()
                print("Paste structure executed!")
                local HttpService = game:GetService("HttpService")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                
                local ACTUALLY_BUILD = true
                local MICRO_SHIFT_Y = 0 
                
                -- Читаем ТОТ ЖЕ файл, куда только что сохраняли
                local success, fileData = pcall(function() return readfile("AdoptMeHouse_Save.json") end)
                if not success then 
                    return Library:Notify("Ошибка", "Файл сохранения не найден!", 3)
                end
                
                local savedHouse = HttpService:JSONDecode(fileData)
                
                local function loadAmbiance(ambianceData)
                    if not ambianceData then return end
                    
                    local function toColor3(rgbArray)
                        if type(rgbArray) ~= "table" or #rgbArray < 3 then return Color3.new(1, 1, 1) end
                        return Color3.new(rgbArray[1], rgbArray[2], rgbArray[3])
                    end
                    
                    local lData = ambianceData.Lighting or {}
                    local ccData = ambianceData.ColorCorrectionEffect or {}
                    local srData = ambianceData.SunRaysEffect or {}
                    local atmData = ambianceData.Atmosphere or {}
                
                    local args = {{
                        base_kind = "sunset", kind = "sunset", priority = 3,
                        custom_props = {
                            Lighting = {
                                ClockTime = lData.ClockTime or 14,
                                ExposureCompensation = lData.ExposureCompensation or 0,
                                Ambient = toColor3(lData.Ambient),
                                OutdoorAmbient = toColor3(lData.OutdoorAmbient),
                                ColorShift_Top = toColor3(lData.ColorShift_Top)
                            },
                            ColorCorrectionEffect = {
                                TintColor = toColor3(ccData.TintColor),
                                Saturation = ccData.Saturation or 0,
                                Contrast = ccData.Contrast or 0
                            },
                            SunRaysEffect = { Intensity = srData.Intensity or 0 },
                            Atmosphere = {
                                Density = atmData.Density or 0.3, 
                                Glare = atmData.Glare or 0,
                                Haze = atmData.Haze or 0, 
                                Color = toColor3(atmData.Color)
                            },
                            Custom = ambianceData.Custom
                        }
                    }}
                    local ambianceRemote = ReplicatedStorage:WaitForChild("API"):FindFirstChild("AmbianceAPI/UpdateAmbiance")
                    if ambianceRemote then pcall(function() ambianceRemote:FireServer(unpack(args)) end) end
                end
                
                if savedHouse.ambiance then loadAmbiance(savedHouse.ambiance) end
                
                if not ACTUALLY_BUILD then return end
                Library:Notify("Постройка", "Начинаю закупку предметов...", 3)
                
                local rawFurniture = savedHouse.furniture or savedHouse
                local pendingChanges = {}
                
                table.sort(rawFurniture, function(a, b)
                    return a.cframe[2] < b.cframe[2]
                end)
                
                local downloadApi = ReplicatedStorage:WaitForChild("API"):WaitForChild("DownloadsAPI/Download")
                local buyFurnituresRemote = ReplicatedStorage:WaitForChild("API"):WaitForChild("HousingAPI/BuyFurnitures")
                local pushFurnitureEvent = ReplicatedStorage:WaitForChild("API"):WaitForChild("HousingAPI/PushFurnitureChanges")
                
                for i, item in ipairs(rawFurniture) do
                    local fId = item.id
                    local baseCFrame = CFrame.new(unpack(item.cframe))
                    local localCFrame = baseCFrame + Vector3.new(0, MICRO_SHIFT_Y, 0)
                    
                    local buyProps = {cframe = localCFrame}
                    if item.colors and #item.colors > 0 then
                        local c3table = {}
                        for _, c in ipairs(item.colors) do table.insert(c3table, Color3.new(c[1], c[2], c[3])) end
                        buyProps.colors = c3table
                    end
                    
                    local currentBatch = {{ kind = fId, properties = buyProps }}
                
                    pcall(function() downloadApi:InvokeServer("Furniture", fId) end)
                    local buildSuccess, response = pcall(function() return buyFurnituresRemote:InvokeServer(currentBatch) end)
                    
                    if buildSuccess and type(response) == "table" and response.success and response.results and response.results[1] and response.results[1].unique then
                        local createdItem = response.results[1]
                        
                        local changeArgs = {
                            unique = createdItem.unique,
                            cframe = localCFrame
                        }
                        if item.scale and item.scale ~= 1 then changeArgs.scale = item.scale end
                        if buyProps.colors then changeArgs.colors = buyProps.colors end
                        
                        table.insert(pendingChanges, changeArgs)
                    end
                    
                    task.wait(0.2)
                end
                
                Library:Notify("Постройка", "Применяю размеры и цвета...", 3)
                
                local chunk = {}
                for i, change in ipairs(pendingChanges) do
                    table.insert(chunk, change)
                    if #chunk >= 50 or i == #pendingChanges then
                        pcall(function() pushFurnitureEvent:FireServer(chunk) end)
                        chunk = {}
                        task.wait(0.5) 
                    end
                end
                Library:Notify("Постройка", "Дом успешно скопирован!", 5)
            end)
        end
    })

    -- ==========================================
    -- 2. НАСТРОЙКИ РЕПЛИКАТОРА (SETTINGS)
    -- ==========================================
    Tab:CreateSection({ Name = "Replicator Settings" })

    -- Тоггл для включения/выключения копирования обоев и полов
    Tab:CreateToggle({
        Name = "Copy Textures",
        Description = "Копировать обои и покрытие полов",
        Default = true,
        Flag = "Replicator_CopyTextures",
        Callback = function(state)
            -- state возвращает true или false
        end
    })

    -- Ползунок для регулировки скорости постройки (чтобы не кикало за спам ремутами)
    Tab:CreateSlider({
        Name = "Build Delay (ms)",
        Min = 10,
        Max = 500,
        Default = 50,
        Flag = "Replicator_BuildDelay",
        Callback = function(value)
            -- value возвращает выбранную задержку
        end
    })

    -- Дропдаун для выбора пресетов, если захочешь сохранять дома в файлы
    Tab:CreateDropdown({
        Name = "Saved Presets",
        Options = {"None", "Modern Mansion", "Cozy Cabin", "Tiny Home"},
        Default = "None",
        Flag = "Replicator_Preset",
        Callback = function(option)
            Library:Notify("Preset Loaded", "Выбран пресет: " .. option, 3)
        end
    })
end

return Module
