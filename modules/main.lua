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
                        Custom = ambianceData.Custom
                    }
                }}
                local ambianceRemote = ReplicatedStorage:WaitForChild("API"):FindFirstChild("AmbianceAPI/UpdateAmbiance")
                if ambianceRemote then pcall(function() ambianceRemote:FireServer(unpack(args)) end) end
            end
            
            if savedHouse.ambiance then loadAmbiance(savedHouse.ambiance) end

            if savedHouse.particles then
                local ParticleRemote = ReplicatedStorage:WaitForChild("API"):FindFirstChild("AmbianceAPI/UpdateAmbianceProperties")
                if ParticleRemote then
                    pcall(function() ParticleRemote:FireServer({ Custom = savedHouse.particles }) end)
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
        Min = 10,
        Max = 500,
        Default = 50,
        Flag = "Replicator_BuildDelay",
        Callback = function(value)
            CurrentBuildDelay = value / 1000 
        end
    })

-- ==========================================
    -- 5. AUTO-DOOR BYPASS
    -- ==========================================
    -- Подгружаем модуль дверей один раз
    local successDoors, DoorsM = pcall(function()
        return require(ReplicatedStorage.ClientModules.Core.DoorsM.DoorsM)
    end)

    local AutoDoorToggle = false

    Tab:CreateToggle({
        Name = "Auto Bypass Doors",
        Description = "Автоматически взламывает двери в радиусе 15 стадов",
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
                            local searchFolders = {
                                workspace:FindFirstChild("Interiors"),
                                workspace:FindFirstChild("HouseExteriors"),
                                workspace:FindFirstChild("Properties")
                            }

                            local closestDoor = nil
                            local touchPart = nil
                            local shortestDist = 15

                            -- 1. Ищем ближайшую дверь
                            for _, folder in pairs(searchFolders) do
                                if folder then
                                    for _, obj in pairs(folder:GetDescendants()) do
                                        if obj.Name == "WorkingParts" then
                                            local tp = obj:FindFirstChild("TouchToEnter")
                                            if tp then
                                                local dist = (hrp.Position - tp.Position).Magnitude
                                                if dist < shortestDist then
                                                    closestDoor = obj.Parent
                                                    touchPart = tp
                                                    shortestDist = dist
                                                end
                                            end
                                        end
                                    end
                                end
                            end

                            -- 2. Взламываем и симулируем вход
                            if closestDoor and touchPart then
                                if successDoors and DoorsM then
                                    local doorObj = DoorsM.get_door(closestDoor)
                                    if doorObj then
                                        doorObj.is_open = true
                                        doorObj.can_enter = true
                                    end
                                end
                                
                                -- 3. Вызываем системное касание (обходим защиту Fsys!)
                                if firetouchinterest then
                                    firetouchinterest(hrp, touchPart, 0)
                                    task.wait(0.1)
                                    firetouchinterest(hrp, touchPart, 1)
                                end
                            end
                        end
                        
                        -- Задержка обязательна, иначе GetDescendants() повесит игру намертво
                        task.wait(0.5)
                    end
                end)
            end
        end
    })
end
return Module
