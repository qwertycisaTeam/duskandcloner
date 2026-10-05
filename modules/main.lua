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

    -- Подключаем нативные модули Adopt Me один раз при инициализации
    local Fsys = require(ReplicatedStorage:WaitForChild("Fsys")).load
    local ClientData = Fsys("ClientData")
    local SharedConstants = Fsys("SharedConstants")

    -- Чистая функция получения статуса лимита мебели: (сколько стоит, максимум, сколько свободно)
    local function GetHouseFurnitureStatus()
        local houseInterior = ClientData.get("house_interior")
        local placedCount = 0

        if houseInterior and type(houseInterior.furniture) == "table" then
            for _ in pairs(houseInterior.furniture) do
                placedCount = placedCount + 1
            end
        end

        local maxLimit = (SharedConstants.housing_editor and SharedConstants.housing_editor.max_furniture) 
            or SharedConstants.max_furniture_per_house 
            or 4000

        local canPlace = math.max(0, maxLimit - placedCount)
        return placedCount, maxLimit, canPlace
    end
    
    -- === НОВОЕ: БАЗА МЕБЕЛИ И БАЛАНС ИГРОКА ===
    local CachedFurnitureDB = nil
    task.spawn(function()
        pcall(function()
            CachedFurnitureDB = Fsys("FurnitureDB")
        end)
    end)

    local function GetPlayerBucks()
        local bucks = 0
        pcall(function()
            local Fsys = require(game:GetService("ReplicatedStorage"):WaitForChild("Fsys")).load
            local ClientData = Fsys("ClientData")
            
            -- Способ 1: Прямой запрос (самый частый вариант)
            bucks = ClientData.get("bucks") or 0
            
            -- Способ 2: Запасной, если первый вернул 0
            if bucks == 0 then
                local pName = game:GetService("Players").LocalPlayer.Name
                local allData = ClientData.get_data()
                
                if allData and allData[pName] then
                    if type(allData[pName].bucks) == "number" then
                        bucks = allData[pName].bucks
                    elseif allData[pName].inventory and type(allData[pName].inventory.bucks) == "number" then
                        bucks = allData[pName].inventory.bucks
                    end
                end
            end
        end)
        return bucks
    end
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
    -- 2. ДРОПДАУН И ПАНЕЛЬ (ИСПРАВЛЕННАЯ ЛОГИКА)
    -- ==========================================
    
    -- 1. ЗАРАНЕЕ объявляем функцию, чтобы дропдаун её видел
    local UpdateSchematicStats 

    -- 2. Создаем Дропдаун (он будет сверху)
    HouseDropdown = Tab:CreateDropdown({
        Name = "Select House Schematic",
        Options = GetSavedHouses(),
        CurrentOption = "Select...",
        Callback = function(Option)
            SelectedHouse = Option
            if UpdateSchematicStats then
                UpdateSchematicStats(Option)
            end
        end
    })

    -- Принудительно сбрасываем при запуске
    task.spawn(function()
        if HouseDropdown and type(HouseDropdown.SetValue) == "function" then
            HouseDropdown.SetValue("Select...")
        end
        SelectedHouse = nil
    end)

    -- 3. Создаем Панель (она будет снизу под дропдауном)
    local StatsContainer = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 0,
        Parent = Tab.Page
    }, { BackgroundColor3 = "Section" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = StatsContainer })
    Library.Utils.Make("UIStroke", { Thickness = 1, Transparency = 0.5, Parent = StatsContainer }, { Color = "Stroke" })

    -- Левая часть (Мебель)
    local FurnIcon = Library.Utils.Make("ImageLabel", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 12, 0.5, -9),
        BackgroundTransparency = 1,
        Image = "rbxassetid://10828062100", 
        Parent = StatsContainer
    }, { ImageColor3 = "Accent" })

    local FurnLabel = Library.Utils.Make("TextLabel", {
        Text = "0 / 4000 Items",
        Size = UDim2.new(0.5, -35, 1, 0),
        Position = UDim2.new(0, 36, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = StatsContainer
    }, { TextColor3 = "Text" })

    -- Разделитель
    Library.Utils.Make("Frame", {
        Size = UDim2.new(0, 1, 1, -14),
        Position = UDim2.new(0.5, 0, 0, 7),
        BorderSizePixel = 0,
        Parent = StatsContainer
    }, { BackgroundColor3 = "Stroke" })

    -- Правая часть (Цена)
    local PriceIcon = Library.Utils.Make("ImageLabel", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0.5, 12, 0.5, -9),
        BackgroundTransparency = 1,
        Image = "rbxassetid://126904798120349", 
        Parent = StatsContainer
    }, { ImageColor3 = "Accent" })

    local PriceLabel = Library.Utils.Make("TextLabel", {
        Text = "Cost: $0",
        Size = UDim2.new(0.5, -35, 1, 0),
        Position = UDim2.new(0.5, 36, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = StatsContainer
    }, { TextColor3 = "Text" })

    -- 4. ПИШЕМ ФУНКЦИЮ (Теперь она обновляет цифры из JSON)
    UpdateSchematicStats = function(fileName)
        if fileName and fileName ~= "Select..." and fileName ~= "" then
            local filePath = FolderName .. "/" .. fileName .. ".json"
            if not isfile(filePath) then return end

            task.spawn(function()
                local success, fileData = pcall(function() return readfile(filePath) end)
                if not success then return end
                
                local decodeSuccess, savedHouse = pcall(function() return HttpService:JSONDecode(fileData) end)
                if not decodeSuccess then return end

                local rawFurniture = savedHouse.furniture or savedHouse
                if type(rawFurniture) ~= "table" then return end

                local neededSlots = #rawFurniture
                local totalCost = 0
                
                if type(CachedFurnitureDB) == "table" then
                    for _, item in ipairs(rawFurniture) do
                        local dbInfo = CachedFurnitureDB[item.id or item.name or item.kind]
                        if dbInfo and dbInfo.cost and not dbInfo.is_limited and not dbInfo.is_event then
                            totalCost = totalCost + dbInfo.cost
                        end
                    end
                end

                FurnLabel.Text = string.format("%d / 4000 Items", neededSlots)
                PriceLabel.Text = string.format("Cost: $%d", totalCost)

                if neededSlots > 4000 then
                    if Library.ThemeObjects[FurnLabel] then Library.ThemeObjects[FurnLabel] = { TextColor3 = "Red" } end
                    FurnLabel.TextColor3 = Library.CurrentTheme.Red
                else
                    if Library.ThemeObjects[FurnLabel] then Library.ThemeObjects[FurnLabel] = { TextColor3 = "Text" } end
                    FurnLabel.TextColor3 = Library.CurrentTheme.Text
                end
            end)
        end
    end

    -- 5. ЖИВОЙ ЦИКЛ (Следит за домом, если файл НЕ выбран)
    task.spawn(function()
        local Fsys = require(ReplicatedStorage:WaitForChild("Fsys")).load
        local ClientData = Fsys("ClientData")

        while task.wait(1.5) do
            if not getgenv().DuskShine_Core then break end

            -- Обновляем панель ТОЛЬКО если юзер сбросил выбор до "Select..."
            if not SelectedHouse or SelectedHouse == "Select..." or SelectedHouse == "" then
                local camY = workspace.CurrentCamera.CFrame.Position.Y
                local isHouseLoaded = workspace:FindFirstChild("HouseInteriors") 
                    and workspace.HouseInteriors:FindFirstChild("blueprint") 
                    and #workspace.HouseInteriors.blueprint:GetChildren() > 0

                -- Жесткая проверка: на улице мы или в доме?
                local isOutside = (camY < 500 or camY > 8500 or not isHouseLoaded)

                if isOutside then
                    FurnLabel.Text = "0 / 4000 Items"
                    PriceLabel.Text = "Cost: $0"
                    if Library.ThemeObjects[FurnLabel] then Library.ThemeObjects[FurnLabel] = { TextColor3 = "Text" } end
                    FurnLabel.TextColor3 = Library.CurrentTheme.Text
                else
                    pcall(function()
                        local houseInterior = ClientData.get("house_interior")
                        local placedCount = 0
                        local totalValue = 0
                        
                        if houseInterior and type(houseInterior.furniture) == "table" then
                            for _, item in pairs(houseInterior.furniture) do
                                placedCount = placedCount + 1
                                if CachedFurnitureDB then
                                    local dbInfo = CachedFurnitureDB[item.id or item.name]
                                    if dbInfo and dbInfo.cost and not dbInfo.is_limited and not dbInfo.is_event then
                                        totalValue = totalValue + dbInfo.cost
                                    end
                                end
                            end
                        end
                        
                        FurnLabel.Text = string.format("%d / 4000 Items", placedCount)
                        PriceLabel.Text = string.format("Cost: $%d", totalValue)
                    end)
                end
            end
        end
    end)

    -- ==========================================
    -- ВСПКМОГАТЕЛЬНЫЕ ФУНКЦИИ ДЛЯ ПРОВЕРОК
    -- ==========================================
    local function GetPlayerBucks()
        local bucks = 0
        
        -- СПОСОБ 1: Читаем прямо с экрана (из интерфейса Adopt Me) - 100% защита от обфускации
        pcall(function()
            local PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
            if PlayerGui then
                local bucksApp = PlayerGui:FindFirstChild("BucksIndicatorApp")
                if bucksApp then
                    for _, elem in ipairs(bucksApp:GetDescendants()) do
                        if elem:IsA("TextLabel") and elem.Text ~= "" then
                            -- Очищаем текст от пробелов, знаков $ и запятых (например "$277,559" -> "277559")
                            local cleanText = elem.Text:gsub("%D", "")
                            local num = tonumber(cleanText)
                            
                            -- Если нашли нормальное число, сохраняем и выходим
                            if num and num > 0 then
                                bucks = num
                                return 
                            end
                        end
                    end
                end
            end
        end)

        -- СПОСОБ 2: Классический метод через память (на случай, если интерфейс еще не прогрузился)
        if bucks == 0 then
            pcall(function()
                local clientDataModule = (getgenv().DuskCore and getgenv().DuskCore.M and getgenv().DuskCore.M.ClientData) 
                    or require(game:GetService("ReplicatedStorage"):WaitForChild("Fsys")).load("ClientData")
                local pName = game:GetService("Players").LocalPlayer.Name
                local allData = clientDataModule.get_data()
                
                if allData and allData[pName] then
                    bucks = allData[pName].bucks or (allData[pName].inventory and allData[pName].inventory.bucks) or 0
                end
                
                if bucks == 0 then
                    bucks = clientDataModule.get("bucks") or 0
                end
            end)
        end
        
        return tonumber(bucks) or 0
    end

    local function GetHouseFurnitureStatus()
        local placedCount, maxLimit = 0, 4000
        pcall(function()
            local clientDataModule = (getgenv().DuskCore and getgenv().DuskCore.M and getgenv().DuskCore.M.ClientData) or require(game:GetService("ReplicatedStorage"):WaitForChild("Fsys")).load("ClientData")
            local houseInterior = clientDataModule.get("house_interior")
            if houseInterior and type(houseInterior.furniture) == "table" then
                for _ in pairs(houseInterior.furniture) do placedCount = placedCount + 1 end
            end
            local Fsys = require(game:GetService("ReplicatedStorage"):WaitForChild("Fsys")).load
            local SharedConstants = Fsys("SharedConstants")
            maxLimit = (SharedConstants.housing_editor and SharedConstants.housing_editor.max_furniture) or SharedConstants.max_furniture_per_house or 4000
        end)
        return placedCount, maxLimit, math.max(0, maxLimit - placedCount)
    end

    -- ==========================================
    -- УНИВЕРСАЛЬНАЯ ФУНКЦИЯ СТРОЙКИ
    -- ==========================================
    local function ExecuteBuild(savedHouse, forceClearOld)
        local rawFurniture = savedHouse.furniture or savedHouse
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local RunService = game:GetService("RunService")
        
        if forceClearOld then
            local clientDataModule = (getgenv().DuskCore and getgenv().DuskCore.M and getgenv().DuskCore.M.ClientData) or require(ReplicatedStorage:WaitForChild("Fsys")).load("ClientData")
            local uniques = {}
            pcall(function()
                local houseInterior = clientDataModule.get("house_interior")
                if houseInterior and type(houseInterior.furniture) == "table" then
                    for uniqueId, _ in pairs(houseInterior.furniture) do table.insert(uniques, uniqueId) end
                end
            end)

            if #uniques > 0 then
                Library:Notify("Storing", "Auto-storing old furniture...", 3, "rbxassetid://91727514118912", "rbxassetid://72958619361915")
                local API_Folder = ReplicatedStorage:WaitForChild("API", 5)
                local sellRemote = (getgenv().DuskCore and getgenv().DuskCore.API and getgenv().DuskCore.API.SellFurniture) or (API_Folder and API_Folder:FindFirstChild("HousingAPI/SellFurniture"))
                
                if sellRemote then
                    local chunk = {}
                    for i, uId in ipairs(uniques) do
                        table.insert(chunk, uId)
                        if #chunk >= 50 or i == #uniques then
                            pcall(function() sellRemote:FireServer(true, chunk, "store") end)
                            chunk = {}
                            task.wait(0.05)
                        end
                    end
                    task.wait(1)
                end
            end
        end

        local MICRO_SHIFT_Y = 0 
        
        local function loadAmbiance(ambianceData, particleData)
            local function toColor3(rgbArray)
                if type(rgbArray) ~= "table" or #rgbArray < 3 then return Color3.new(1, 1, 1) end
                return Color3.new(rgbArray[1], rgbArray[2], rgbArray[3])
            end
            local cProps = (type(ambianceData) == "table" and ambianceData.custom_props) or {}
            local lData, ccData, srData, atmData = cProps.Lighting or {}, cProps.ColorCorrectionEffect or {}, cProps.SunRaysEffect or {}, cProps.Atmosphere or {}
            local bKind = (type(ambianceData) == "table" and ambianceData.base_kind) or "day"
            local kKind = (type(ambianceData) == "table" and ambianceData.kind) or "day"
            local customParticles = { Rain = false, CherryBlossoms = false, Leaves = false, Snow = false }
            if type(particleData) == "table" then for k, v in pairs(particleData) do customParticles[k] = v end end

            local args = {{
                base_kind = bKind, kind = kKind, priority = 3,
                custom_props = {
                    Lighting = { ClockTime = lData.ClockTime or 14, ExposureCompensation = lData.ExposureCompensation or 0, Ambient = toColor3(lData.Ambient), OutdoorAmbient = toColor3(lData.OutdoorAmbient), ColorShift_Top = toColor3(lData.ColorShift_Top) },
                    ColorCorrectionEffect = { TintColor = toColor3(ccData.TintColor), Saturation = ccData.Saturation or 0, Contrast = ccData.Contrast or 0 },
                    SunRaysEffect = { Intensity = srData.Intensity or 0 },
                    Atmosphere = { Density = atmData.Density or 0.3, Glare = atmData.Glare or 0, Haze = atmData.Haze or 0, Color = toColor3(atmData.Color) },
                    Custom = customParticles
                }
            }}
            local API_Folder = ReplicatedStorage:WaitForChild("API", 5)
            if API_Folder then
                local ambianceRemote = API_Folder:FindFirstChild("AmbianceAPI/UpdateAmbiance")
                if ambianceRemote then pcall(function() ambianceRemote:FireServer(table.unpack(args)) end) end
            end
        end
        loadAmbiance(savedHouse.ambiance, savedHouse.particles)

        if CopyTextures and savedHouse.textures then
            local API_Folder = ReplicatedStorage:WaitForChild("API", 5)
            if API_Folder then
                local BuyTextureRemote = API_Folder:FindFirstChild("HousingAPI/BuyTexture")
                if BuyTextureRemote then
                    for roomName, texData in pairs(savedHouse.textures) do
                        if texData.walls and texData.walls ~= "" then pcall(function() BuyTextureRemote:FireServer(roomName, "walls", texData.walls) end); task.wait(getgenv().CurrentBuildDelay or 0) end
                        if texData.floors and texData.floors ~= "" then pcall(function() BuyTextureRemote:FireServer(roomName, "floors", texData.floors) end); task.wait(getgenv().CurrentBuildDelay or 0) end
                    end
                end
            end
        end

        local API_Folder = ReplicatedStorage:WaitForChild("API", 5)
        if not API_Folder then return false end

        local downloadApi = API_Folder:FindFirstChild("DownloadsAPI/Download")
        local buyFurnituresRemote = getgenv().DuskCore and getgenv().DuskCore.API and getgenv().DuskCore.API.BuyFurnitures or API_Folder:FindFirstChild("HousingAPI/BuyFurnitures")
        local pushFurnitureEvent = API_Folder:FindFirstChild("HousingAPI/PushFurnitureChanges")

        if not buyFurnituresRemote then return false end

        if downloadApi then
            local uniqueIDs = {}
            for _, item in ipairs(rawFurniture) do 
                local itemId = item.id or item.name or item.kind
                if itemId then uniqueIDs[itemId] = true end 
            end
            for id, _ in pairs(uniqueIDs) do task.spawn(function() pcall(function() downloadApi:InvokeServer("Furniture", id) end) end) end
            task.wait(0.5)
        end

        table.sort(rawFurniture, function(a, b)
            local yA = (type(a.cframe) == "table" and a.cframe[2]) or 0
            local yB = (type(b.cframe) == "table" and b.cframe[2]) or 0
            return yA < yB
        end)

        local pendingChanges, currentBatch, batchOriginalItems = {}, {}, {}

        for i, item in ipairs(rawFurniture) do
            local itemId = item.id or item.name or item.kind
            if not itemId then continue end

            local cData = item.cframe
            if type(cData) ~= "table" or #cData ~= 12 then continue end

            local baseCFrame = CFrame.new(table.unpack(cData))
            local localCFrame = baseCFrame + Vector3.new(0, MICRO_SHIFT_Y, 0)
            
            local buyProps = {cframe = localCFrame}
            if item.colors and #item.colors > 0 then
                local c3table = {}
                for _, c in ipairs(item.colors) do table.insert(c3table, Color3.new(c[1], c[2], c[3])) end
                buyProps.colors = c3table
            end
            
            table.insert(currentBatch, { kind = itemId, properties = buyProps })
            table.insert(batchOriginalItems, { item = item, localCFrame = localCFrame, buyProps = buyProps })
            
            local batchLimit = getgenv().CurrentBatchSize or 15
            local buildDelay = getgenv().CurrentBuildDelay or 0

            if #currentBatch >= batchLimit or i == #rawFurniture then
                local successPurchase, attempts = false, 0
                repeat
                    attempts = attempts + 1
                    local buildSuccess, response = pcall(function() return buyFurnituresRemote:InvokeServer(currentBatch) end)
                    if buildSuccess and type(response) == "table" and response.success then
                        successPurchase = true
                        if response.results then
                            for resultIndex, result in ipairs(response.results) do
                                if result.unique then
                                    local orig = batchOriginalItems[resultIndex]
                                    local changeArgs = { unique = result.unique, cframe = orig.localCFrame }
                                    if orig.item.scale and orig.item.scale ~= 1 then changeArgs.scale = orig.item.scale end
                                    if orig.buyProps.colors then changeArgs.colors = orig.buyProps.colors end
                                    table.insert(pendingChanges, changeArgs)
                                end
                            end
                        end
                    else
                        task.wait(0.5)
                    end
                until successPurchase or attempts >= 2

                if not successPurchase and #currentBatch > 0 then
                    for bIndex, singleItemReq in ipairs(currentBatch) do
                        local sBuildSuccess, sResponse = pcall(function() return buyFurnituresRemote:InvokeServer({singleItemReq}) end)
                        if sBuildSuccess and type(sResponse) == "table" and sResponse.success and sResponse.results then
                            local orig = batchOriginalItems[bIndex]
                            for _, result in ipairs(sResponse.results) do
                                if result.unique then
                                    local changeArgs = { unique = result.unique, cframe = orig.localCFrame }
                                    if orig.item.scale and orig.item.scale ~= 1 then changeArgs.scale = orig.item.scale end
                                    if orig.buyProps.colors then changeArgs.colors = orig.buyProps.colors end
                                    table.insert(pendingChanges, changeArgs)
                                end
                            end
                        end
                        task.wait(0.02)
                    end
                end
                
                currentBatch, batchOriginalItems = {}, {}
                if buildDelay > 0 then task.wait(buildDelay) else RunService.Heartbeat:Wait() end
            end
        end
        
        if pushFurnitureEvent and #pendingChanges > 0 then
            local chunk = {}
            for i, change in ipairs(pendingChanges) do
                table.insert(chunk, change)
                if #chunk >= 50 or i == #pendingChanges then
                    pcall(function() pushFurnitureEvent:FireServer(chunk) end)
                    chunk = {}
                    task.wait(math.max(0.1, getgenv().CurrentBuildDelay or 0.1)) 
                end
            end
        end
        return true
    end

    -- ==========================================
    -- 4. ГЛАВНАЯ КНОПКА (УМНАЯ) + СЛАЙДЕР
    -- ==========================================
    local FarmAmount = 1
    local forceBuildMode = false 
    
    local BuildContainer = Library.Utils.Make("Frame", { Size = UDim2.new(1, -8, 0, 38), Position = UDim2.new(0.5, 0, 0, 0), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1, Parent = Tab.Page })
    local Glow = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 1, Parent = BuildContainer })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Glow })
    local GlowStroke = Library.Utils.Make("UIStroke", { Thickness = 4, Transparency = 0.85, Parent = Glow }, { Color = "Accent" })

    local BuildBtn = Library.Utils.Make("TextButton", { Text = "", Size = UDim2.new(1, 0, 1, 0), AutoButtonColor = false, ZIndex = 5, Parent = BuildContainer }, { BackgroundColor3 = "Section" }) 
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = BuildBtn })
    local BuildText = Library.Utils.Make("TextLabel", { Text = "BUILD SELECTED HOUSE", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, ZIndex = 6, Parent = BuildBtn }, { TextColor3 = "Accent" }) 
    local EdgeStroke = Library.Utils.Make("UIStroke", { Thickness = 1.5, Transparency = 0.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = BuildBtn }, { Color = "Accent" })
    local BuildScale = Instance.new("UIScale", BuildContainer)
    
    Library:Connect(BuildBtn.MouseEnter, function() Library.Utils.TBT(BuildBtn, 0.3, {BackgroundTransparency = 0.3}); Library.Utils.TBT(EdgeStroke, 0.3, {Transparency = 0}); Library.Utils.TBT(GlowStroke, 0.4, {Thickness = 12, Transparency = 0.6}, Enum.EasingStyle.Quint); Library.Utils.TBT(BuildScale, 0.3, {Scale = 1.05}, Enum.EasingStyle.Back, Enum.EasingDirection.Out) end)
    Library:Connect(BuildBtn.MouseLeave, function() Library.Utils.TBT(BuildBtn, 0.3, {BackgroundTransparency = 0}); Library.Utils.TBT(EdgeStroke, 0.3, {Transparency = 0.2}); Library.Utils.TBT(GlowStroke, 0.4, {Thickness = 4, Transparency = 0.85}, Enum.EasingStyle.Quint); Library.Utils.TBT(BuildScale, 0.3, {Scale = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.Out) end)

    Tab:CreateSlider({
        Name = "Farm Target (Houses)",
        Min = 1, Max = 10, Default = 1, Flag = "Farm_Amount",
        Callback = function(val) 
            FarmAmount = val 
            forceBuildMode = false
            if val > 1 then
                BuildText.Text = "START MULTI-FARM (" .. val .. ")"
                BuildText.TextColor3 = Color3.fromRGB(255, 150, 50)
            else
                BuildText.Text = "BUILD SELECTED HOUSE"
                if Library.ThemeObjects[BuildText] then Library.ThemeObjects[BuildText] = { TextColor3 = "Accent" } end
                BuildText.TextColor3 = Library.CurrentTheme.Accent
            end
        end
    })

    -- ЕДИНАЯ ЛОГИКА КЛИКА
    Library:Connect(BuildBtn.MouseButton1Click, function()
        local t = Library.Utils.TBT(BuildScale, 0.1, {Scale = 0.95})
        t.Completed:Connect(function() Library.Utils.TBT(BuildScale, 0.2, {Scale = 1}, Enum.EasingStyle.Bounce) end)
            
        if not SelectedHouse or SelectedHouse == "" or SelectedHouse == "Select..." then return Library:Notify("Error", "Select a house schematic first!", 3, "rbxassetid://73186275216515", "rbxassetid://72958619361915") end
        local filePath = FolderName .. "/" .. SelectedHouse .. ".json"
        if not isfile(filePath) then return Library:Notify("Error", "File not found on disk!", 3, "rbxassetid://73186275216515", "rbxassetid://72958619361915") end

        task.spawn(function()
            local success, fileData = pcall(function() return readfile(filePath) end)
            if not success then return end
            local HttpService = game:GetService("HttpService")
            local decodeSuccess, savedHouse = pcall(function() return HttpService:JSONDecode(fileData) end)
            if not decodeSuccess or not savedHouse.furniture then return Library:Notify("Error", "File corrupted!", 3, "rbxassetid://73186275216515", "rbxassetid://72958619361915") end

            local houseType = savedHouse.house_type

            -- Общий подсчет стоимости для защиты (используем и для фермы, и для соло)
            local totalCost = 0
            local rawFurniture = savedHouse.furniture or savedHouse
            local neededSlots = #rawFurniture
            if type(CachedFurnitureDB) == "table" then
                for _, item in ipairs(rawFurniture) do
                    local dbInfo = CachedFurnitureDB[item.id or item.name or item.kind]
                    if dbInfo and dbInfo.cost and not dbInfo.is_limited and not dbInfo.is_event then totalCost = totalCost + dbInfo.cost end
                end
            end

            local currentBucks = GetPlayerBucks()
            local placed, maxLimit, freeSlots = GetHouseFurnitureStatus()

            -- ============================================
            -- РЕЖИМ МУЛЬТИ-ФЕРМЫ
            -- ============================================
            if FarmAmount > 1 then
                if not houseType then return Library:Notify("Farm Error", "No house_type in JSON! Re-export the house first.", 5) end
                
                if currentBucks < (totalCost * FarmAmount) then
                    return Library:Notify("Low Bucks!", string.format("Need at least $%d for %d houses.", totalCost * FarmAmount, FarmAmount), 5)
                end

                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local API = ReplicatedStorage:WaitForChild("API", 5)
                local buyRemote = API:FindFirstChild("HousingAPI/BuyHouseWithAddons")
                local renameRemote = API:FindFirstChild("HousingAPI/SetHouseName")
                
                if not buyRemote then return Library:Notify("Error", "API Remotes missing!", 3) end
                Library:Notify("Farm Started", "Check F9 Console for logs...", 4)
                
                local clientDataModule = (getgenv().DuskCore and getgenv().DuskCore.M and getgenv().DuskCore.M.ClientData) or require(ReplicatedStorage:WaitForChild("Fsys")).load("ClientData")
                local LocalPlayer = game:GetService("Players").LocalPlayer
                
                for i = 1, FarmAmount do
                    print("=======================================")
                    print(string.format("🏗 [ФЕРМА] Итерация %d из %d | Тип: %s", i, FarmAmount, houseType))
                    
                    local skipBuy = false
                    local skipTeleport = false
                    local activeHouseId = nil
                    
                    -- УМНАЯ ПРОВЕРКА 1 ИТЕРАЦИИ: Нужна ли покупка?
                    if i == 1 then
                        local allData = clientDataModule.get_data()
                        local currentExterior = allData and allData[LocalPlayer.Name] and allData[LocalPlayer.Name].house_exterior_model
                        
                        if currentExterior == houseType then
                            print("🏠 Итерация 1: Нужный тип дома УЖЕ экипирован. Пропуск покупки.")
                            skipBuy = true
                            
                            local currentInterior = clientDataModule.get("house_interior")
                            if currentInterior and currentInterior.unique then
                                activeHouseId = currentInterior.unique
                                local camY = workspace.CurrentCamera.CFrame.Position.Y
                                local blueprint = workspace:FindFirstChild("HouseInteriors") and workspace.HouseInteriors:FindFirstChild("blueprint")
                                
                                if camY > 500 and camY < 8500 and blueprint and #blueprint:GetChildren() > 0 then
                                    print("✅ Мы уже внутри нужного дома! Пропуск телепортации.")
                                    skipTeleport = true
                                end
                            end
                        end
                    end
                    
                    if not skipBuy then
                        -- 1. СКАНИРУЕМ ИНВЕНТАРЬ ДО ПОКУПКИ
                        local oldHouses = {}
                        pcall(function()
                            local inv = clientDataModule.get_data()[LocalPlayer.Name].inventory.housing
                            if type(inv) == "table" then
                                for k, _ in pairs(inv) do oldHouses[k] = true end
                            end
                        end)

                        print("🛒 Покупаем новую коробку...")
                        local buySuccess, buyResponse = pcall(function() return buyRemote:InvokeServer(houseType, {}, Color3.new(0.768, 0.156, 0.109)) end)
                        
                        if not buySuccess or (type(buyResponse) == "table" and buyResponse.success == false) then
                            warn("❌ Ошибка покупки. Сервер отклонил пакет.")
                            Library:Notify("Farm Stopped", "Buy failed.", 5)
                            break
                        end
                        
                        print("✅ Запрос ушел. Ждем появления нового дома в инвентаре...")
                        
                        -- 2. ЖДЕМ ПОЯВЛЕНИЯ НОВОГО ID В ИНВЕНТАРЕ
                        local newHouseId = nil
                        local waitEquip = 0
                        repeat
                            task.wait(0.5)
                            waitEquip = waitEquip + 0.5
                            pcall(function()
                                local inv = clientDataModule.get_data()[LocalPlayer.Name].inventory.housing
                                if type(inv) == "table" then
                                    for k, _ in pairs(inv) do
                                        if not oldHouses[k] then
                                            newHouseId = k
                                        end
                                    end
                                end
                            end)
                        until newHouseId or waitEquip > 15
                        
                        if not newHouseId then
                            warn("❌ Сервер принял покупку, но дом не появился в инвентаре! Прерываем.")
                            break
                        end
                        
                        activeHouseId = newHouseId
                        print("🏠 Новый дом успешно добавлен в инвентарь! ID: " .. tostring(activeHouseId))

                        -- 3. ФОРСИРУЕМ ЭКИПИРОВКУ НОВОГО ДОМА
                        pcall(function()
                            local equipRemotes = {"EquipHouse", "SetEquippedHouse", "SpawnHouse", "SetHouse"}
                            for _, name in ipairs(equipRemotes) do
                                local r = API:FindFirstChild("HousingAPI/" .. name)
                                if r then r:InvokeServer(activeHouseId) end
                            end
                        end)
                        task.wait(1)
                    end
                    
                    -- ПЕРЕИМЕНОВАНИЕ
                    if renameRemote and activeHouseId then 
                        pcall(function() 
                            -- Передаем и просто имя, и ID+имя, чтобы игра 100% схавала
                            renameRemote:InvokeServer(SelectedHouse) 
                            renameRemote:InvokeServer(activeHouseId, SelectedHouse) 
                        end) 
                    end
                    
                    -- ЭТАП ТЕЛЕПОРТА (Если не пропущен)
                    if not skipTeleport then
                        print("🚪 Телепортируемся внутрь...")
                        
                        local currentLoc = clientDataModule.get("location_id")
                        if currentLoc == "housing" and not skipBuy then
                            -- Если мы уже были в каком-то доме, сначала выходим на улицу, чтобы избежать бага
                            pcall(function() API:FindFirstChild("LocationAPI/SetLocation"):FireServer("Neighborhood") end)
                            task.wait(1.5)
                        end
                        
                        local set_identity = (syn and syn.set_thread_identity) or setthreadidentity or setidentity
                        local get_identity = (syn and syn.get_thread_identity) or getthreadidentity or getidentity
                        local current_id = get_identity and get_identity() or 7

                        pcall(function()
                            if set_identity then pcall(set_identity, 2) end
                            local InteriorsM = require(ReplicatedStorage.ClientModules.Core.InteriorsM.InteriorsM)
                            InteriorsM.enter_smooth("housing", "MainDoor", { ["house_owner"] = LocalPlayer }) 
                        end)
                        if set_identity then pcall(set_identity, current_id) end
                        
                        print("⏳ Ждем загрузки интерьера...")
                        local isLoaded = false
                        local waitTime = 0
                        repeat
                            task.wait(0.5)
                            waitTime = waitTime + 0.5
                            local currentInterior = clientDataModule.get("house_interior")
                            
                            -- Защита от Ghost-Building: проверяем, что мы загрузились именно в новый дом
                            local isCorrectInterior = false
                            if currentInterior and activeHouseId then
                                isCorrectInterior = (currentInterior.unique == activeHouseId)
                            else
                                isCorrectInterior = true 
                            end
                            
                            local camY = workspace.CurrentCamera.CFrame.Position.Y
                            local blueprint = workspace:FindFirstChild("HouseInteriors") and workspace.HouseInteriors:FindFirstChild("blueprint")
                            
                            if isCorrectInterior and camY > 500 and camY < 8500 and blueprint and #blueprint:GetChildren() > 0 then isLoaded = true end
                            if waitTime > 25 then break end 
                        until isLoaded
                        
                        if not isLoaded then 
                            warn("❌ Интерьер не прогрузился или мы зашли в старый дом! Пропускаем итерацию.")
                            continue 
                        end
                    end
                    
                    print("🔨 Строим...")
                    local needsClear = false
                    if skipBuy then
                        local cInterior = clientDataModule.get("house_interior")
                        if cInterior and type(cInterior.furniture) == "table" then
                            local c = 0
                            for _ in pairs(cInterior.furniture) do c = c + 1 end
                            if c > 0 then needsClear = true end
                        end
                    end
                    
                    ExecuteBuild(savedHouse, needsClear)
                    task.wait(2)
                end
                
                print("🏁 Ферма завершила работу!")
                Library:Notify("Farm Finished", "All tasks completed.", 5)
            
            -- ============================================
            -- РЕЖИМ ОДИНОЧНОЙ ПОСТРОЙКИ
            -- ============================================
            else
                local isHouseLoaded = workspace:FindFirstChild("HouseInteriors") and workspace.HouseInteriors:FindFirstChild("blueprint") and #workspace.HouseInteriors.blueprint:GetChildren() > 0
                local camY = workspace.CurrentCamera.CFrame.Position.Y
                if camY < 500 or camY > 8500 or not isHouseLoaded then return Library:Notify("Error", "House is not fully loaded or you are outside!", 4, "rbxassetid://73186275216515", "rbxassetid://72958619361915") end
                
                if neededSlots > maxLimit then return Library:Notify("Error", string.format("Needs %d slots, max is %d.", neededSlots, maxLimit), 5, "rbxassetid://73186275216515", "rbxassetid://72958619361915") end

                local hasOverlap = (placed > 0)
                local isPoor = (currentBucks < totalCost)

                if (hasOverlap or isPoor) and not forceBuildMode then
                    forceBuildMode = true
                    local warnTitle = "Warning"
                    local warnText = ""
                    if hasOverlap then BuildText.Text = "STORE OLD & BUILD"; warnText = string.format("House has %d items! ", placed) else BuildText.Text = "BUILD ANYWAY" end
                    if isPoor then warnTitle = "Low Bucks!"; warnText = warnText .. string.format("Cost: $%d (You have $%d)! ", totalCost, currentBucks) end
                    warnText = warnText .. "CLICK AGAIN to force build."
                    
                    Library:Notify(warnTitle, warnText, 6, "rbxassetid://73186275216515", "rbxassetid://72958619361915")
                    task.delay(6, function() if forceBuildMode then forceBuildMode = false; BuildText.Text = "BUILD SELECTED HOUSE" end end)
                    return 
                end

                if forceBuildMode then
                    forceBuildMode = false
                    BuildText.Text = "BUILD SELECTED HOUSE"
                end
                
                Library:Notify("Builder", "Building " .. SelectedHouse .. "...", 3, "rbxassetid://91727514118912", "rbxassetid://72958619361915")
                local buildDone = ExecuteBuild(savedHouse, hasOverlap)
                if buildDone then Library:Notify("Success", "House successfully built!", 3, "rbxassetid://18926561608", "rbxassetid://72958619361915") end
            end
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
    local speedFlag = "Main_BuildSpeed"
    
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
            getgenv().CurrentBuildDelay = 0.02 
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
            Library.Flags[speedFlag] = currentVisualSpeed
        end
    end
    
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

    Library.ConfigUpdaters[speedFlag] = function(val)
        currentVisualSpeed = math.clamp(tonumber(val) or 0, minSpeed, maxSpeed)
        updateVisuals(currentVisualSpeed)
        updateBuildSettings(currentVisualSpeed)
        
        local pct = math.clamp((currentVisualSpeed - minSpeed) / (maxSpeed - minSpeed), 0, 1)
        Fill.Size = UDim2.new(pct, 0, 1, 0)
    end
    
    -- ==========================================
    -- 5. AUTO-DOOR BYPASS (OPTIMIZED & FIXED)
    -- ==========================================
    Tab:CreateDivider({ Text = "Exploits" })

    local successDoors, DoorsM = pcall(function()
        return require(ReplicatedStorage.ClientModules.Core.DoorsM.DoorsM)
    end)

    local AutoDoorToggle = false
    local lastTouchedDoor = nil
    local CachedDoors = {}

    local function checkAndCache(obj)
        if obj.Name == "TouchToEnter" and obj.Parent and obj.Parent.Name == "WorkingParts" then
            CachedDoors[obj] = obj.Parent.Parent 
        end
    end

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
                        if not getgenv().DuskShine_Core or getgenv().DS_StopExecution then 
                            AutoDoorToggle = false
                            break 
                        end
                        
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        
                        if hrp then
                            local closestDoor = nil
                            local touchPart = nil
                            local shortestDist = 5
                            
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
