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
    local CurrentBuildDelay = 0
    local CurrentBatchSize = 15
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
        Library:Notify("Builder", "House list successfully refreshed!", 3, "rbxassetid://91727514118912", "rbxassetid://72958619361915")
    end)
    -- Глобальная функция для связи с File Manager (Manager -> Main)
    getgenv().AutoSelectNewHouse = function(newFileName)
        if HouseDropdown and type(HouseDropdown.Refresh) == "function" then
            HouseDropdown.Refresh(GetSavedHouses()) -- Обновляем список файлов
            
            if newFileName and type(HouseDropdown.SetValue) == "function" then
                HouseDropdown.SetValue(newFileName) -- Меняем текст на кнопке
                SelectedHouse = newFileName -- Записываем в переменную для билда
            end
        end
    end
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
        CurrentOption = "Select...",
        Callback = function(Option)
            SelectedHouse = Option
        end
    })

    -- Принудительно сбрасываем кэш UI-библиотеки, чтобы не вылезали удаленные файлы
    task.spawn(function()
        if HouseDropdown and type(HouseDropdown.SetValue) == "function" then
            HouseDropdown.SetValue("Select...")
        end
        SelectedHouse = nil
    end)

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
        Size = UDim2.new(1, -8, 0, 38), -- Запас места для Scale = 1.05
        Position = UDim2.new(0.5, 0, 0, 0), -- Ставим ровно по центру
        AnchorPoint = Vector2.new(0.5, 0), -- Центр масс
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
            return Library:Notify("Error", "You can only build while inside a house!", 3, "rbxassetid://73186275216515", "rbxassetid://72958619361915")
        end
        if not SelectedHouse or SelectedHouse == "" or SelectedHouse == "Select..." then
            return Library:Notify("Error", "Select a house schematic first!", 3, "rbxassetid://73186275216515", "rbxassetid://72958619361915")
        end
        
        local filePath = FolderName .. "/" .. SelectedHouse .. ".json"
        if not isfile(filePath) then
            return Library:Notify("Error", "File not found on disk!", 3, "rbxassetid://73186275216515", "rbxassetid://72958619361915")
        end

        task.spawn(function()
            Library:Notify("Builder", "Reading file: " .. SelectedHouse, 3, "rbxassetid://91727514118912", "rbxassetid://72958619361915")
            
            local success, fileData = pcall(function() return readfile(filePath) end)
            if not success then return Library:Notify("Error", "Failed to read file!", 3, "rbxassetid://73186275216515", "rbxassetid://72958619361915") end
            
            local decodeSuccess, savedHouse = pcall(function() return HttpService:JSONDecode(fileData) end)
            if not decodeSuccess or not savedHouse.furniture then
                return Library:Notify("Error", "File corrupted or invalid format!", 3, "rbxassetid://73186275216515", "rbxassetid://72958619361915")
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
                Library:Notify("Builder", "Applying wallpapers and floors...", 3, "rbxassetid://91727514118912", "rbxassetid://72958619361915")
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
            
            Library:Notify("Builder", "Starting furniture purchase...", 3, "rbxassetid://91727514118912", "rbxassetid://72958619361915")
            
            local rawFurniture = savedHouse.furniture or savedHouse
            local pendingChanges = {}
            
            table.sort(rawFurniture, function(a, b)
                return a.cframe[2] < b.cframe[2]
            end)
            
            local downloadApi = ReplicatedStorage:WaitForChild("API"):WaitForChild("DownloadsAPI/Download")
            local buyFurnituresRemote = ReplicatedStorage:WaitForChild("API"):WaitForChild("HousingAPI/BuyFurnitures")
            local pushFurnitureEvent = ReplicatedStorage:WaitForChild("API"):WaitForChild("HousingAPI/PushFurnitureChanges")

            -- 1. ПРЕДВАРИТЕЛЬНОЕ КЭШИРОВАНИЕ
            local uniqueIDs = {}
            for _, item in ipairs(rawFurniture) do uniqueIDs[item.id] = true end
            for id, _ in pairs(uniqueIDs) do
                task.spawn(function() pcall(function() downloadApi:InvokeServer("Furniture", id) end) end)
            end
            task.wait(0.5)

-- 2. ДЕБАГ И АВТО-ПОВТОР
            warn("=== БИЛДЕР ЗАПУЩЕН | ВСЕГО ПРЕДМЕТОВ: " .. tostring(#rawFurniture) .. " ===")
            local totalBought, totalFailed = 0, 0

            local RunService = game:GetService("RunService")
            local currentBatch = {}
            local batchOriginalItems = {}

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
                table.insert(batchOriginalItems, { item = item, localCFrame = localCFrame, buyProps = buyProps })
                
                -- Тут теперь используется CurrentBatchSize, управляемый слайдером
                if #currentBatch >= CurrentBatchSize or i == #rawFurniture then
                    local successPurchase = false
                    local attempts = 0
                    local maxAttempts = 3 

                    repeat
                        attempts = attempts + 1
                        local buildSuccess, response = pcall(function() return buyFurnituresRemote:InvokeServer(currentBatch) end)
                        
                        if buildSuccess and type(response) == "table" and response.success then
                            successPurchase = true
                            if response.results then
                                for resultIndex, result in ipairs(response.results) do
                                    if result.unique then
                                        totalBought = totalBought + 1
                                        local orig = batchOriginalItems[resultIndex]
                                        local changeArgs = { unique = result.unique, cframe = orig.localCFrame }
                                        if orig.item.scale and orig.item.scale ~= 1 then changeArgs.scale = orig.item.scale end
                                        if orig.buyProps.colors then changeArgs.colors = orig.buyProps.colors end
                                        table.insert(pendingChanges, changeArgs)
                                    end
                                end
                            end
                        else
                            warn(string.format("[WARNING] Сбой покупки пачки. Попытка %d из %d", attempts, maxAttempts))
                            task.wait(1.5)
                        end
                    until successPurchase or attempts >= maxAttempts

                    if not successPurchase then totalFailed = totalFailed + #currentBatch end
                    
                    currentBatch = {}
                    batchOriginalItems = {}
                    
                    -- Логика задержки от слайдера
                    if CurrentBuildDelay > 0 then 
                        -- Работает, если слайдер от 101 до 200
                        task.wait(CurrentBuildDelay) 
                    else
                        -- Работает на Инстанте (0) и Быстрой (1-100)
                        -- Ждет 1 кадр, чтобы игра не зависла намертво от цикла
                        RunService.Heartbeat:Wait() 
                    end
                end
            end
            local chunk = {}
            for i, change in ipairs(pendingChanges) do
                table.insert(chunk, change)
                if #chunk >= 50 or i == #pendingChanges then
                    pcall(function() pushFurnitureEvent:FireServer(chunk) end)
                    chunk = {}
                    task.wait(0.5) 
                end
            end
            Library:Notify("Success", "House successfully built!", 3, "rbxassetid://18926561608", "rbxassetid://72958619361915")
        end)
    end)

    -- ==========================================
    -- 4. РЕПЛИКАТОР (НАСТРОЙКИ)
    -- ==========================================
    Tab:CreateDivider({ Text = "Configuration" })

    Tab:CreateToggle({
        Name = "Copy Textures (Wallpapers/Floors)",
        Description = "Copy wallpapers and floor materials.",
        Default = true,
        Flag = "Replicator_CopyTextures",
        Callback = function(state)
            CopyTextures = state
        end
    })

    local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local SliderContainer = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0, 70), Parent = Tab.Page }, { BackgroundColor3 = "Section" })
Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 10), Parent = SliderContainer })
local containerStroke = Library.Utils.Make("UIStroke", { Thickness = 1, Parent = SliderContainer }, { Color = "Stroke" })

Library.Utils.Make("TextLabel", { Text = "Build Speed", Size = UDim2.new(1, -100, 0, 20), Position = UDim2.new(0, 20, 0, 10), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Parent = SliderContainer }, { TextColor3 = "Text" })
Library.Utils.Make("TextLabel", { Text = "Drag left for Instant, right for Slow build.", Size = UDim2.new(1, -100, 0, 15), Position = UDim2.new(0, 20, 0, 30), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = SliderContainer }, { TextColor3 = "SubText" })

local PillFrame = Library.Utils.Make("Frame", { Size = UDim2.new(0, 76, 0, 24), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 9), Parent = SliderContainer }, { BackgroundColor3 = "Sidebar" }) 
Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = PillFrame })
local pillStroke = Library.Utils.Make("UIStroke", { Thickness = 1, Parent = PillFrame }, { Color = "Stroke" })

-- Заменили TextBox на TextLabel, чтобы нельзя было вписывать цифры
local ValueText = Library.Utils.Make("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13, ZIndex = 2, Parent = PillFrame }, { TextColor3 = "Text" })
local PillScale = Instance.new("UIScale", PillFrame)

local Track = Library.Utils.Make("TextButton", { Size = UDim2.new(1, -40, 0, 4), Position = UDim2.new(0, 20, 1, -12), AnchorPoint = Vector2.new(0, 1), Text = "", AutoButtonColor = false, Parent = SliderContainer }, { BackgroundColor3 = "Sidebar" })
Library.Utils.Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Track })

local Fill = Library.Utils.Make("Frame", { Size = UDim2.new(0, 0, 1, 0), Parent = Track }, { BackgroundColor3 = "Accent" })
Library.Utils.Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Fill })

local Knob = Library.Utils.Make("Frame", { Size = UDim2.new(0, 12, 0, 12), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Parent = Fill }, { BackgroundColor3 = "Text" })
Library.Utils.Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Knob })
local KnobScale = Instance.new("UIScale", Knob)

local minSpeed, maxSpeed = 0, 200
local currentVisualSpeed = 0 
local isDragging = false
local currentMode = ""

-- Привязка к переменным билдера
getgenv().CurrentBatchSize = 15
getgenv().CurrentBuildDelay = 0

local function updateBuildSettings(val)
    if val == 0 then
        getgenv().CurrentBatchSize = 15
        getgenv().CurrentBuildDelay = 0
    elseif val <= 80 then
        local progress = val / 80
        getgenv().CurrentBatchSize = math.clamp(math.floor(15 - (progress * 14)), 1, 14)
        getgenv().CurrentBuildDelay = 0
    elseif val <= 120 then
        getgenv().CurrentBatchSize = 1
        getgenv().CurrentBuildDelay = 0.02 -- Минимальная плавная задержка
    else
        getgenv().CurrentBatchSize = 1
        local slowProgress = (val - 120) / 80
        getgenv().CurrentBuildDelay = 0.05 + (slowProgress * 0.45)
    end
end

local function updateVisuals(val)
    local pct = math.clamp((val - minSpeed) / (maxSpeed - minSpeed), 0, 1)
    TweenService:Create(Fill, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
    
    local newMode = ""
    if val == 0 then newMode = "Instant"
    elseif val <= 80 then newMode = "Fast"
    elseif val <= 120 then newMode = "Normal"
    else newMode = "Slow" end

    ValueText.Text = newMode

    -- Анимация при смене режима (Цвет текста и обводки)
    if newMode ~= currentMode then
        currentMode = newMode
        local targetColor = (newMode == "Instant") and Library.CurrentTheme.Accent or Library.CurrentTheme.Text
        local targetStroke = (newMode == "Instant") and Library.CurrentTheme.Accent or Library.CurrentTheme.Stroke
        
        if Library.ThemeObjects[ValueText] then Library.ThemeObjects[ValueText] = { TextColor3 = (newMode == "Instant") and "Accent" or "Text" } end
        if Library.ThemeObjects[pillStroke] then Library.ThemeObjects[pillStroke] = { Color = (newMode == "Instant") and "Accent" or "Stroke" } end
        
        TweenService:Create(ValueText, TweenInfo.new(0.2), {TextColor3 = targetColor}):Play()
        TweenService:Create(pillStroke, TweenInfo.new(0.2), {Color = targetStroke}):Play()
        
        PillScale.Scale = 0.85
        TweenService:Create(PillScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    end
end

local function updateDrag(input)
    local absolutePos = Track.AbsolutePosition.X
    local absoluteSize = Track.AbsoluteSize.X
    local pct = math.clamp((input.Position.X - absolutePos) / absoluteSize, 0, 1)
    local snappedValue = math.floor(minSpeed + (maxSpeed - minSpeed) * pct)
    
    if currentVisualSpeed ~= snappedValue then
        currentVisualSpeed = snappedValue
        updateVisuals(currentVisualSpeed)
        updateBuildSettings(currentVisualSpeed)
    end
end

-- Инициализация первого кадра
updateVisuals(currentVisualSpeed)
updateBuildSettings(currentVisualSpeed)

Library:Connect(Track.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        TweenService:Create(KnobScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.35}):Play()
        updateDrag(input)
    end
end)

Library:Connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
        TweenService:Create(KnobScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
    end
end)

Library:Connect(UserInputService.InputChanged, function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateDrag(input) end
end)

Library:Connect(SliderContainer.MouseEnter, function() TweenService:Create(containerStroke, TweenInfo.new(0.3), {Transparency = 0.5}):Play() end)
Library:Connect(SliderContainer.MouseLeave, function() TweenService:Create(containerStroke, TweenInfo.new(0.3), {Transparency = 0}):Play() end)
-- ==========================================
    -- 5. AUTO-DOOR BYPASS (OPTIMIZED & FIXED)
    -- ==========================================
    Tab:CreateDivider({ Text = "Exploits" })

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

    -- 2. Глобальный слушатель: автоматически ловит новые дома
    local foldersToSearch = {"Interiors", "HouseExteriors", "Properties"}
    for _, folderName in ipairs(foldersToSearch) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            table.insert(Library.Connections, folder.DescendantAdded:Connect(function(obj)
                checkAndCache(obj)
            end))
        end
    end
    
Tab:CreateToggle({
        Name = "Auto Bypass Doors",
        Description = "Instant activation. Unlocks doors and does not drop FPS.",
        Default = false,
        Flag = "Exploit_AutoDoors",
        Callback = function(state)
            AutoDoorToggle = state
            
            if AutoDoorToggle then
                task.spawn(function()
                    while AutoDoorToggle do
                        -- ЖЕЛЕЗОБЕТОННАЯ ПРОВЕРКА: Если ядра скрипта больше нет в памяти — убиваем цикл
                        if not getgenv().DuskShine_Core or getgenv().DS_StopExecution then 
                            AutoDoorToggle = false
                            break 
                        end
                        
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        
                        if hrp then
                            local closestDoor = nil
                            local touchPart = nil
                            local shortestDist = 2
                            
                            -- Перебираем только кэш (очень быстро)
                            for tp, doorModel in pairs(CachedDoors) do
                                if tp and tp.Parent and tp:IsDescendantOf(workspace) then 
                                    local dist = (hrp.Position - tp.Position).Magnitude
                                    if dist < shortestDist then
                                        closestDoor = doorModel
                                        touchPart = tp
                                        shortestDist = dist
                                    end
                                else
                                    CachedDoors[tp] = nil
                                end
                            end

                            -- Взлом и вход
                            if closestDoor and touchPart then
                                if closestDoor ~= lastTouchedDoor then
                                    if successDoors and DoorsM then
                                        local doorObj = DoorsM.get_door(closestDoor)
                                        if doorObj then
                                            doorObj.is_open = true
                                            doorObj.can_enter = true
                                            doorObj.locked = false
                                            doorObj.is_locked = false 
                                            
                                            if type(doorObj.update) == "function" then
                                                pcall(function() doorObj:update() end)
                                            end
                                        end
                                    end
                                    
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
