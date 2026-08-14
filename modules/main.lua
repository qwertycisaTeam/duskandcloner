local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Module = {}

local FolderName = "DuskAndShine_Houses"

-- ИСПРАВЛЕНИЕ ДРОПДАУНА: Безопасное чтение файлов
local function GetSavedHouses()
    if not isfolder(FolderName) then makefolder(FolderName) end
    local houses = {}
    
    -- Оборачиваем в pcall, так как listfiles может крашнуть скрипт в пустой папке
    local success, files = pcall(function() return listfiles(FolderName) end)
    if not success or type(files) ~= "table" then return houses end
    
    for _, path in ipairs(files) do
        -- Улучшенный паттерн для захвата файлов (игнорирует регистр расширения)
        local fileName = path:match("([^/\\]+)%.[jJ][sS][oO][nN]$")
        if fileName then table.insert(houses, fileName) end
    end
    return houses
end

function Module:Init(Library, Window, Tab)
    local LocalPlayer = Players.LocalPlayer
    local SelectedHouse = nil
    local CurrentBuildDelay = 0.05 
    local CopyTextures = true
    
    local HouseDropdown 

    -- ==========================================
    -- ШАПКА И РЕФРЕШ (Текст Auto-Builder удален)
    -- ==========================================
    local SectionContainer = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
        Parent = Tab.Page
    })
    
    Library:Connect(RefreshBtn.MouseButton1Click, function()
        local t = Library.Utils.TBT(refScale, 0.1, {Scale = 0.9})
        t.Completed:Connect(function() Library.Utils.TBT(refScale, 0.2, {Scale = 1}, Enum.EasingStyle.Bounce) end)
        Library.Utils.TBT(RefIcon, 0.5, {Rotation = 360}); task.delay(0.5, function() RefIcon.Rotation = 0 end)
        
        if HouseDropdown then
            local newList = GetSavedHouses()
            
            -- [ФИКС]: Принудительно перезаписываем внутреннюю таблицу библиотеки
            HouseDropdown.Options = newList 
            
            -- Пробуем разные методы обновления, чтобы точно пробило твою UI-либу
            if type(HouseDropdown.Refresh) == "function" then
                -- Второй аргумент (true) в некоторых либах запрещает сброс текущего выбора
                pcall(function() HouseDropdown:Refresh(newList, true) end)
            elseif type(HouseDropdown.SetValues) == "function" then
                pcall(function() HouseDropdown:SetValues(newList) end)
            elseif type(HouseDropdown.SetOptions) == "function" then
                pcall(function() HouseDropdown:SetOptions(newList) end)
            end
            
            -- Зануляем выбранный дом, чтобы не было фантомных построек
            SelectedHouse = nil 
        end
        
        Library:Notify("Builder", "Список домов успешно обновлен!", 2)
    end)
    local RefStroke = Library.Utils.Make("UIStroke", { Thickness = 1, Transparency = 0.5, Parent = RefreshBtn }, { Color = "Stroke" })
    
    local RefIcon = Library.Utils.Make("ImageLabel", {
        Size = UDim2.new(0, 14, 0, 14),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://10873923769",
        Parent = RefreshBtn
    }, { ImageColor3 = "Text" })
    
    local refScale = Instance.new("UIScale", RefreshBtn)
    
    Library:Connect(RefreshBtn.MouseEnter, function() 
        Library.Utils.TBT(RefStroke, 0.2, {Transparency = 0})
        Library.Utils.TBT(RefreshBtn, 0.2, {BackgroundColor3 = Library.CurrentTheme.Section})
    end)
    Library:Connect(RefreshBtn.MouseLeave, function() 
        Library.Utils.TBT(RefStroke, 0.2, {Transparency = 0.5})
        Library.Utils.TBT(RefreshBtn, 0.2, {BackgroundColor3 = Library.CurrentTheme.Sidebar})
    end)
    
    Library:Connect(RefreshBtn.MouseButton1Click, function()
        local t = Library.Utils.TBT(refScale, 0.1, {Scale = 0.9})
        t.Completed:Connect(function() Library.Utils.TBT(refScale, 0.2, {Scale = 1}, Enum.EasingStyle.Bounce) end)
        Library.Utils.TBT(RefIcon, 0.5, {Rotation = 360}); task.delay(0.5, function() RefIcon.Rotation = 0 end)
        
        if HouseDropdown and HouseDropdown.Refresh then
            HouseDropdown:Refresh(GetSavedHouses())
        end
        Library:Notify("Builder", "List of saved houses updated!", 2)
    end)

    HouseDropdown = Tab:CreateDropdown({
        Name = "Select House Schematic",
        Options = GetSavedHouses(),
        CurrentOption = "",
        Callback = function(Option)
            SelectedHouse = Option
        end
    })

    -- ==========================================
    -- КНОПКА BUILD (С глянцем, одной аурой и правильными гранями)
    -- ==========================================
    local BuildContainer = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, 0, 0, 36), -- Сделали тоньше
        BackgroundTransparency = 1,
        Parent = Tab.Page
    })

    -- Основная кнопка
    local BuildBtn = Library.Utils.Make("TextButton", {
        Text = "BUILD SELECTED HOUSE", 
        Size = UDim2.new(1, 0, 1, 0),
        Font = Enum.Font.GothamBold, 
        TextSize = 13, 
        AutoButtonColor = false,
        ZIndex = 5,
        Parent = BuildContainer 
    }, { BackgroundColor3 = "Accent" }) 
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = BuildBtn })
    
    BuildBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    if Library.ThemeObjects[BuildBtn] then Library.ThemeObjects[BuildBtn].TextColor3 = nil end

    -- Градиент для эффекта "глянца/блеска"
    local Gradient = Instance.new("UIGradient", BuildBtn)
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
    })
    Gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(0.5, 0.15),
        NumberSequenceKeypoint.new(1, 0.4)
    })
    Gradient.Rotation = 90

    -- 1. ГРАНЬ (Жесткая фаска)
    local EdgeStroke = Library.Utils.Make("UIStroke", { 
        Thickness = 1.5, 
        Transparency = 0.25, 
        Color = Color3.fromRGB(255, 255, 255),
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = BuildBtn 
    })

    -- 2. ПЛАВНОЕ РАССЕЯНИЕ (Один слой "выпирающего" неона)
    local Glow = Library.Utils.Make("Frame", { 
        Size = UDim2.new(1, 4, 1, 4), 
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1, 
        ZIndex = 2, 
        Parent = BuildBtn 
    })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Glow })
    local GlowStroke = Library.Utils.Make("UIStroke", { 
        Thickness = 3.5, 
        Transparency = 0.6, 
        Parent = Glow 
    }, { Color = "Accent" })

    local BuildScale = Instance.new("UIScale", BuildBtn)

    -- Анимация наведения
    Library:Connect(BuildBtn.MouseEnter, function() 
        Library.Utils.TBT(BuildBtn, 0.2, {BackgroundTransparency = 0.1}) 
        Library.Utils.TBT(EdgeStroke, 0.2, {Transparency = 0}) 
        Library.Utils.TBT(GlowStroke, 0.3, {Thickness = 5, Transparency = 0.4}) 
    end)
    Library:Connect(BuildBtn.MouseLeave, function() 
        Library.Utils.TBT(BuildBtn, 0.2, {BackgroundTransparency = 0}) 
        Library.Utils.TBT(EdgeStroke, 0.2, {Transparency = 0.25})
        Library.Utils.TBT(GlowStroke, 0.3, {Thickness = 3.5, Transparency = 0.6})
    end)
    
    -- Логика нажатия
    Library:Connect(BuildBtn.MouseButton1Click, function()
        local t = Library.Utils.TBT(BuildScale, 0.1, {Scale = 0.95})
        t.Completed:Connect(function() Library.Utils.TBT(BuildScale, 0.2, {Scale = 1}, Enum.EasingStyle.Bounce) end)
        
        if not SelectedHouse or SelectedHouse == "" then
            return Library:Notify("Ошибка", "Сначала выбери дом в меню!", 3)
        end
        
        local filePath = FolderName .. "/" .. SelectedHouse .. ".json"
        if not isfile(filePath) then
            return Library:Notify("Ошибка", "Файл не найден на диске!", 3)
        end

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
            
            -- [ОБНОВЛЕНИЕ 1]: Загрузка Освещения
            if savedHouse.ambiance then loadAmbiance(savedHouse.ambiance) end

            -- [ОБНОВЛЕНИЕ 2]: Загрузка Частиц (Погода, Листья и т.д.)
            if savedHouse.particles then
                local ParticleRemote = ReplicatedStorage:WaitForChild("API"):FindFirstChild("AmbianceAPI/UpdateAmbianceProperties")
                if ParticleRemote then
                    pcall(function() ParticleRemote:FireServer({ Custom = savedHouse.particles }) end)
                end
            end

            -- [ОБНОВЛЕНИЕ 3]: Загрузка Текстур (Обои и Полы)
            if CopyTextures and savedHouse.textures then
                Library:Notify("Постройка", "Применяю обои и полы...", 2)
                local BuyTextureRemote = ReplicatedStorage:WaitForChild("API"):FindFirstChild("HousingAPI/BuyTexture")
                if BuyTextureRemote then
                    for roomName, texData in pairs(savedHouse.textures) do
                        if texData.walls and texData.walls ~= "" then
                            pcall(function() BuyTextureRemote:FireServer(roomName, "walls", texData.walls) end)
                            task.wait(CurrentBuildDelay)
                        end
                        if texData.floors and texData.floors ~= "" then
                            pcall(function() BuyTextureRemote:FireServer(roomName, "floors", texData.floors) end)
                            task.wait(CurrentBuildDelay)
                        end
                    end
                end
            end

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
    end)

    -- ==========================================
    -- РЕПЛИКАТОР (НАСТРОЙКИ)
    -- ==========================================
    Tab:CreateSection({ Name = "⚙️ Replicator Settings" })

    Tab:CreateToggle({
        Name = "Copy Textures (Wallpapers/Floors)",
        Description = "Копировать обои и покрытие полов",
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
            CurrentBuildDelay = value / 1000 
        end
    })
end

return Module
