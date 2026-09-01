local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Module = {}

local FolderName = "DuskAndShine_Houses"

local function GetSavedHouses()
    if not isfolder(FolderName) then makefolder(FolderName) end
    local houses = {}
    
    local success, files = pcall(function() return listfiles(FolderName) end)
    if not success or type(files) ~= "table" then return houses end
    
    for _, path in ipairs(files) do
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
    -- 1. АДАПТИВНАЯ ШАПКА И РЕФРЕШ
    -- ==========================================
    local SectionContainer = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = Tab.Page
    })

    Library.Utils.Make("TextLabel", {
        Text = '<b>UTILITY:</b> <font color="#9696a0">House Builder</font>',
        RichText = true, 
        Size = UDim2.new(1, -40, 1, 0), 
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1, 
        Font = Enum.Font.GothamBold,
        TextSize = 14, 
        TextXAlignment = Enum.TextXAlignment.Left, 
        Parent = SectionContainer
    }, { TextColor3 = "Text" })

    local RefreshBtn = Library.Utils.Make("TextButton", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -26, 0, 2),
        Text = "",
        AutoButtonColor = false,
        Parent = SectionContainer
    }, { BackgroundColor3 = "Sidebar" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = RefreshBtn })

    local RefStroke = Library.Utils.Make("UIStroke", { Thickness = 1, Transparency = 0.5, Parent = RefreshBtn }, { Color = "Stroke" })
    
    local RefIcon = Library.Utils.Make("ImageLabel", {
        Size = UDim2.new(0, 16, 0, 16),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6723921202",
        Parent = RefreshBtn
    }, { ImageColor3 = "SubText" })
    
    local refScale = Instance.new("UIScale", RefreshBtn)
    
    Library:Connect(RefreshBtn.MouseEnter, function() 
        Library.Utils.TBT(RefStroke, 0.2, {Transparency = 0})
        Library.Utils.TBT(RefreshBtn, 0.2, {BackgroundColor3 = Library.CurrentTheme.Section})
        Library.Utils.TBT(RefIcon, 0.2, {ImageColor3 = Library.CurrentTheme.Accent})
    end)
    Library:Connect(RefreshBtn.MouseLeave, function() 
        Library.Utils.TBT(RefStroke, 0.2, {Transparency = 0.5})
        Library.Utils.TBT(RefreshBtn, 0.2, {BackgroundColor3 = Library.CurrentTheme.Sidebar})
        Library.Utils.TBT(RefIcon, 0.2, {ImageColor3 = Library.CurrentTheme.SubText})
    end)
    
    Library:Connect(RefreshBtn.MouseButton1Click, function()
        local t = Library.Utils.TBT(refScale, 0.1, {Scale = 0.9})
        t.Completed:Connect(function() Library.Utils.TBT(refScale, 0.2, {Scale = 1}, Enum.EasingStyle.Bounce) end)
        Library.Utils.TBT(RefIcon, 0.5, {Rotation = 360}); task.delay(0.5, function() RefIcon.Rotation = 0 end)
        
        if HouseDropdown and type(HouseDropdown.Refresh) == "function" then
            HouseDropdown.Refresh(GetSavedHouses())
            if type(HouseDropdown.SetValue) == "function" then
                HouseDropdown.SetValue("Select...")
            end
            SelectedHouse = nil 
        end
        Library:Notify("Builder", "Список домов успешно обновлен!", 2)
    end)

    local TopDivider = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BorderSizePixel = 0,
        Parent = Tab.Page
    }, { BackgroundColor3 = "Text" })
    
    local DivGrad = Instance.new("UIGradient", TopDivider)
    DivGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.8),
        NumberSequenceKeypoint.new(1, 1)
    })

    -- ==========================================
    -- 2. ДРОПДАУН ВЫБОРА ДОМА
    -- ==========================================
    HouseDropdown = Tab:CreateDropdown({
        Name = "Select House Schematic",
        Options = GetSavedHouses(),
        CurrentOption = "",
        Callback = function(Option)
            SelectedHouse = Option
        end
    })

    -- Улучшенный хак: фиксим шрифты и добавляем объем (убираем плоскость)
    task.spawn(function()
        task.wait(0.1)
        for _, frame in ipairs(Tab.Page:GetChildren()) do
            if frame:IsA("Frame") and frame.Size == UDim2.new(1, 0, 0, 40) then 
                local title = frame:FindFirstChildWhichIsA("TextLabel")
                if title then
                    title.Font = Enum.Font.GothamMedium
                    title.TextSize = 13
                end

                local btn = frame:FindFirstChildWhichIsA("TextButton")
                if btn then
                    btn.TextTruncate = Enum.TextTruncate.AtEnd
                    btn.Font = Enum.Font.GothamMedium
                    btn.TextSize = 13
                    
                    if not btn:FindFirstChildWhichIsA("UIStroke") then
                        Library.Utils.Make("UIStroke", {
                            Thickness = 1,
                            Transparency = 0.5,
                            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                            Parent = btn
                        }, { Color = "Stroke" })
                    end
                end
            end
        end
    end)

    -- ==========================================
    -- 3. ПРЕМИУМ КНОПКА BUILD (НЕОНОВАЯ)
    -- ==========================================
    local BuildContainer = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
        Parent = Tab.Page
    })

    local Glow = Library.Utils.Make("Frame", { 
        Size = UDim2.new(1, 0, 1, 0), 
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1, 
        ZIndex = 1, 
        Parent = BuildContainer 
    })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Glow })
    local GlowStroke = Library.Utils.Make("UIStroke", { 
        Thickness = 4, 
        Transparency = 0.85,
        Parent = Glow 
    }, { Color = "Accent" })

    local BuildBtn = Library.Utils.Make("TextButton", {
        Text = "", 
        Size = UDim2.new(1, 0, 1, 0),
        AutoButtonColor = false,
        ZIndex = 5,
        Parent = BuildContainer 
    }, { BackgroundColor3 = "Section" }) 
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = BuildBtn })

    local BuildText = Library.Utils.Make("TextLabel", {
        Text = "BUILD SELECTED HOUSE",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        ZIndex = 6,
        Parent = BuildBtn
    }, { TextColor3 = "Accent" }) 

    local EdgeStroke = Library.Utils.Make("UIStroke", { 
        Thickness = 1.5, 
        Transparency = 0.2, 
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = BuildBtn 
    }, { Color = "Accent" })

    local BuildScale = Instance.new("UIScale", BuildContainer)

    Library:Connect(BuildBtn.MouseEnter, function() 
        Library.Utils.TBT(BuildBtn, 0.3, {BackgroundTransparency = 0.3}) 
        Library.Utils.TBT(EdgeStroke, 0.3, {Transparency = 0}) 
        Library.Utils.TBT(GlowStroke, 0.4, {Thickness = 12, Transparency = 0.6}, Enum.EasingStyle.Quint) 
        Library.Utils.TBT(BuildScale, 0.3, {Scale = 1.05}, Enum.EasingStyle.Back, Enum.EasingDirection.Out) 
    end)
    Library:Connect(BuildBtn.MouseLeave, function() 
        Library.Utils.TBT(BuildBtn, 0.3, {BackgroundTransparency = 0}) 
        Library.Utils.TBT(EdgeStroke, 0.3, {Transparency = 0.2})
        Library.Utils.TBT(GlowStroke, 0.4, {Thickness = 4, Transparency = 0.85}, Enum.EasingStyle.Quint)
        Library.Utils.TBT(BuildScale, 0.3, {Scale = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)
    
    Library:Connect(BuildBtn.MouseButton1Click, function()
        local t = Library.Utils.TBT(BuildScale, 0.1, {Scale = 0.95})
        t.Completed:Connect(function() Library.Utils.TBT(BuildScale, 0.2, {Scale = 1}, Enum.EasingStyle.Bounce) end)
            
        local camY = workspace.CurrentCamera.CFrame.Position.Y
        local blueprint = workspace:FindFirstChild("HouseInteriors") and workspace.HouseInteriors:FindFirstChild("blueprint")
        
        if camY < 500 or camY > 8500 or not blueprint or #blueprint:GetChildren() == 0 then
            return Library:Notify("Ошибка", "Строить можно только находясь внутри дома!", 4)
        end
        if not SelectedHouse or SelectedHouse == "" or SelectedHouse == "Select..." then
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
                        Custom = savedHouse.particles or {}
                    }
                }}
                local ambianceRemote = ReplicatedStorage:WaitForChild("API"):FindFirstChild("AmbianceAPI/UpdateAmbiance")
                if ambianceRemote then pcall(function() ambianceRemote:FireServer(unpack(args)) end) end
            end
            
            if savedHouse.ambiance then loadAmbiance(savedHouse.ambiance) end

            local hasParticles = false
            if type(savedHouse.particles) == "table" then
                for _, _ in pairs(savedHouse.particles) do
                    hasParticles = true
                    break
                end
            end
                    
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
            
            -- 1. Предварительное кэширование
            local uniqueIDs = {}
            for _, item in ipairs(rawFurniture) do uniqueIDs[item.id] = true end
            for id, _ in pairs(uniqueIDs) do
                task.spawn(function() pcall(function() downloadApi:InvokeServer("Furniture", id) end) end)
            end
            task.wait(0.5)
            
            -- 2. ДЕБАГ-БАТЧИНГ (ПО 5 ПРЕДМЕТОВ)
            local BATCH_SIZE = 5 
            local currentBatch = {}
            local batchReferences = {}
            local totalBought = 0
            local totalFailed = 0
            
            print("=== НАЧАЛО ПОСТРОЙКИ (DEBUG MODE) ===")
            print("Всего предметов в файле:", #rawFurniture)
            
            for i, item in ipairs(rawFurniture) do
                local baseCFrame = CFrame.new(unpack(item.cframe))
                local localCFrame = baseCFrame + Vector3.new(0, MICRO_SHIFT_Y, 0)
                
                local buyProps = {cframe = localCFrame}
                if item.colors and #item.colors > 0 then
                    local c3table = {}
                    for _, c in ipairs(item.colors) do table.insert(c3table, Color3.new(c[1], c[2], c[3])) end
                    buyProps.colors = c3table
                end
                
                table.insert(currentBatch, { kind = item.id, properties = buyProps })
                table.insert(batchReferences, { item = item, localCFrame = localCFrame, buyProps = buyProps })
            
                if #currentBatch >= BATCH_SIZE or i == #rawFurniture then
                    print(string.format("[DEBUG] Отправка пакета: %d предметов. Прогресс: %d/%d", #currentBatch, i, #rawFurniture))
                    
                    local buildSuccess, response = pcall(function() 
                        return buyFurnituresRemote:InvokeServer(currentBatch) 
                    end)
                    
                    if not buildSuccess then
                        -- Ошибка самого Roblox (InvokeServer упал)
                        warn("[ERROR] Сбой pcall (InvokeServer)! Ошибка:", tostring(response))
                        totalFailed = totalFailed + #currentBatch
                    else
                        if type(response) == "table" then
                            if response.success then
                                -- Сервер принял пачку
                                print("[SUCCESS] Пакет успешно куплен!")
                                for resultIndex, createdItem in ipairs(response.results) do
                                    if createdItem.unique then
                                        totalBought = totalBought + 1
                                        local ref = batchReferences[resultIndex]
                                        local changeArgs = { unique = createdItem.unique, cframe = ref.localCFrame }
                                        if ref.item.scale and ref.item.scale ~= 1 then changeArgs.scale = ref.item.scale end
                                        if ref.buyProps.colors then changeArgs.colors = ref.buyProps.colors end
                                        table.insert(pendingChanges, changeArgs)
                                    else
                                        warn("[WARNING] Предмет куплен, но unique ID отсутствует!")
                                    end
                                end
                            else
                                -- Сервер отклонил покупку (Анти-спам, нет денег и т.д.)
                                warn("[FAILED] Сервер отклонил пакет!")
                                warn("Ответ сервера:", HttpService:JSONEncode(response))
                                totalFailed = totalFailed + #currentBatch
                            end
                        else
                            warn("[ERROR] Неизвестный формат ответа от сервера:", typeof(response), tostring(response))
                        end
                    end
                    
                    currentBatch = {}
                    batchReferences = {}
                    
                    if CurrentBuildDelay > 0 then
                        task.wait(CurrentBuildDelay)
                    end
                end
            end
            
            print("=== ИТОГИ ПОСТРОЙКИ ===")
            print(string.format("Успешно: %d | Провалено: %d", totalBought, totalFailed))
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
    -- 4. РЕПЛИКАТОР (НАСТРОЙКИ)
    -- ==========================================
    Tab:CreateDivider({ Text = "Configuration" })

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
        Min = 0,
        Max = 200,
        Default = 10,
        Flag = "Replicator_BuildDelay",
        Callback = function(value)
            CurrentBuildDelay = value / 1000 
        end
    })

-- ==========================================
    -- 5. AUTO-DOOR BYPASS (OPTIMIZED & FIXED)
    -- ==========================================
    local successDoors, DoorsM = pcall(function()
        return require(ReplicatedStorage.ClientModules.Core.DoorsM.DoorsM)
    end)

    local AutoDoorToggle = false
    local lastTouchedDoor = nil
    
    -- === НАДЕЖНАЯ СИСТЕМА КЭШИРОВАНИЯ ===
    local CachedDoors = {}

    local function checkAndCache(obj)
        -- Быстрая проверка, чтобы не грузить игру
        if obj.Name == "TouchToEnter" and obj.Parent and obj.Parent.Name == "WorkingParts" then
            CachedDoors[obj] = obj.Parent.Parent 
        end
    end

    -- 1. Единоразово собираем двери, которые УЖЕ есть на карте
    task.spawn(function()
        local foldersToSearch = {"Interiors", "HouseExteriors", "Properties"}
        for _, folderName in ipairs(foldersToSearch) do
            local folder = workspace:FindFirstChild(folderName)
            if folder then
                for _, obj in pairs(folder:GetDescendants()) do
                    checkAndCache(obj)
                end
            end
        end
    end)

    -- 2. Глобальный слушатель: автоматически ловит новые дома, когда они спавнятся
    workspace.DescendantAdded:Connect(function(obj)
        checkAndCache(obj)
    end)
    -- =====================================

    Tab:CreateToggle({
        Name = "Auto Bypass Doors (Optimized)",
        Description = "Мгновенное срабатывание. Снимает замки и не садит FPS.",
        Default = false,
        Flag = "Exploit_AutoDoors",
        Callback = function(state)
            AutoDoorToggle = state
            
            if AutoDoorToggle then
                task.spawn(function()
                    while AutoDoorToggle do
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        
                        if hrp then
                            local closestDoor = nil
                            local touchPart = nil
                            local shortestDist = 2
                            
                            -- Перебираем только кэш (очень быстро)
                            for tp, doorModel in pairs(CachedDoors) do
                                -- ИСПРАВЛЕНО: Теперь тут стоит двоеточие ":" 
                                if tp and tp.Parent and tp:IsDescendantOf(workspace) then 
                                    local dist = (hrp.Position - tp.Position).Magnitude
                                    if dist < shortestDist then
                                        closestDoor = doorModel
                                        touchPart = tp
                                        shortestDist = dist
                                    end
                                else
                                    -- Если дверь удалилась с карты, чистим память
                                    CachedDoors[tp] = nil
                                end
                            end

                            -- Взлом и вход
                            if closestDoor and touchPart then
                                if closestDoor ~= lastTouchedDoor then
                                    if successDoors and DoorsM then
                                        local doorObj = DoorsM.get_door(closestDoor)
                                        if doorObj then
                                            -- Взламываем все статусы (включая замки)
                                            doorObj.is_open = true
                                            doorObj.can_enter = true
                                            doorObj.locked = false
                                            doorObj.is_locked = false 
                                            
                                            -- Обновляем UI двери, если функция существует
                                            if type(doorObj.update) == "function" then
                                                pcall(function() doorObj:update() end)
                                            end
                                        end
                                    end
                                    
                                    -- Эмуляция касания
                                    if firetouchinterest then
                                        firetouchinterest(hrp, touchPart, 0)
                                        task.wait(0.1)
                                        firetouchinterest(hrp, touchPart, 1)
                                    end
                                    
                                    lastTouchedDoor = closestDoor
                                    task.wait(4) -- Ожидание телепорта
                                end
                            else
                                lastTouchedDoor = nil
                            end
                        end
                        
                        task.wait(0.2)
                    end
                end)
            end
        end
    })
end
return Module
