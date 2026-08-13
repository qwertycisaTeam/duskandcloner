local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Module = {}

local FolderName = "DuskAndShine_Houses"

-- Функция получения списка домов для Dropdown
local function GetSavedHouses()
    if not isfolder(FolderName) then makefolder(FolderName) end
    local houses = {}
    local files = listfiles(FolderName)
    
    for _, path in ipairs(files) do
        local fileName = path:match("([^/\\]+)%.json$")
        if fileName then table.insert(houses, fileName) end
    end
    return houses
end

function Module:Init(Library, Window, Tab)
    local LocalPlayer = Players.LocalPlayer
    local SelectedHouse = nil
    local CurrentBuildDelay = 0.05 -- По умолчанию 50мс (0.05 сек)
    local CopyTextures = true
    
    -- ==========================================
    -- 1. СИСТЕМА АВТО-БИЛДЕРА
    -- ==========================================
    Tab:CreateSection({ Name = "🏠 Auto-Builder System" })

    -- Выбор дома из папки
    local HouseDropdown = Tab:CreateDropdown({
        Name = "Select House Schematic",
        Options = GetSavedHouses(),
        CurrentOption = "",
        Callback = function(Option)
            SelectedHouse = Option
        end
    })

    -- Кнопка обновления списка (если добавил файл через Файловый Менеджер)
    Tab:CreateButton({
        Name = "🔄 Refresh File List",
        Callback = function()
            local houses = GetSavedHouses()
            if HouseDropdown.Refresh then
                HouseDropdown:Refresh(houses)
            end
            Library:Notify("Builder", "List of saved houses updated!", 2)
        end
    })

    -- ГЛАВНАЯ КНОПКА ПОСТРОЙКИ
    Tab:CreateButton({
        Name = "🔨 BUILD SELECTED HOUSE",
        Callback = function()
            if not SelectedHouse or SelectedHouse == "" then
                return Library:Notify("Ошибка", "Сначала выбери дом в меню!", 3)
            end
            
            local filePath = FolderName .. "/" .. SelectedHouse .. ".json"
            if not isfile(filePath) then
                return Library:Notify("Ошибка", "Файл не найден на диске!", 3)
            end

            -- Запускаем процесс в отдельном потоке
            task.spawn(function()
                Library:Notify("Запуск", "Читаем файл: " .. SelectedHouse, 2)
                
                local success, fileData = pcall(function() return readfile(filePath) end)
                if not success then return Library:Notify("Ошибка", "Не удалось прочитать файл!", 3) end
                
                local decodeSuccess, savedHouse = pcall(function() return HttpService:JSONDecode(fileData) end)
                if not decodeSuccess or not savedHouse.furniture then
                    return Library:Notify("Ошибка", "Файл поврежден или имеет неверный формат!", 3)
                end

                local ACTUALLY_BUILD = true
                local MICRO_SHIFT_Y = 0 
                
                -- ================== ЛОГИКА AMBIANCE (ОСВЕЩЕНИЕ) ==================
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
                
                -- ================== ЛОГИКА ЗАСТРОЙКИ (МЕБЕЛЬ) ==================
                Library:Notify("Постройка", "Начинаю закупку предметов...", 3)
                
                local rawFurniture = savedHouse.furniture or savedHouse
                local pendingChanges = {}
                
                -- Сортировка по высоте (чтобы строить снизу вверх)
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
                    
                    -- ИСПОЛЬЗУЕМ ЗАДЕРЖКУ ИЗ СЛАЙДЕРА!
                    task.wait(CurrentBuildDelay)
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
                Library:Notify("Успех", "Дом " .. SelectedHouse .. " успешно построен!", 5)
            end)
        end
    })

    -- ==========================================
    -- 2. НАСТРОЙКИ РЕПЛИКАТОРА
    -- ==========================================
    Tab:CreateSection({ Name = "⚙️ Replicator Settings" })

    Tab:CreateToggle({
        Name = "Copy Textures (Wallpapers/Floors)",
        Description = "Копировать обои и покрытие полов (в разработке)",
        Default = true,
        Flag = "Replicator_CopyTextures",
        Callback = function(state)
            CopyTextures = state
        end
    })

    Tab:CreateSlider({
        Name = "Build Delay (ms)",
        Min = 10,
        Max = 500,
        Default = 50,
        Flag = "Replicator_BuildDelay",
        Callback = function(value)
            -- Переводим миллисекунды в секунды для task.wait()
            CurrentBuildDelay = value / 1000 
        end
    })
end

return Module
