local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Module = {}

function Module:Init(Library, Window, Tab)

    -- ==========================================
    -- УМНАЯ ЗАГРУЗКА АВАТАРОВ (БЕЗ ТАЙМАУТОВ РОБЛОКСА)
    -- ==========================================
    local function applyAvatar(imageLabel, username, index)
        task.spawn(function()
            task.wait(index * 0.15) -- Задержка очереди, чтобы не спамить API
            
            local userId = nil
            local player = Players:FindFirstChild(username)
            
            if player then
                userId = player.UserId
            else
                local success, id = pcall(function() return Players:GetUserIdFromNameAsync(username) end)
                if success then userId = id end
            end
            
            if userId then
                imageLabel.Image = "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150&h=150"
            else
                imageLabel.Image = "rbxassetid://10827393433" 
            end
        end)
    end

    -- ==========================================
    -- 3D РЕНДЕР: ИСПОЛЬЗУЕМ ОРИГИНАЛЬНЫЕ НАСТРОЙКИ ADOPT ME!
    -- ==========================================
    local function buildCleanPreview(houseType, viewportFrame)
        local Resources = ReplicatedStorage:FindFirstChild("Resources")
        if not Resources then return end
        
        local domeTemplate = Resources:FindFirstChild("HousePreviewDome")
        local houseExteriors = Resources:FindFirstChild("HouseExteriors")
        local houseModel = houseExteriors and houseExteriors:FindFirstChild(houseType)
        
        if domeTemplate and houseModel then
            -- Группа для вращения
            local previewGroup = Instance.new("Model")
            previewGroup.Name = "PreviewGroup"
            previewGroup.Parent = viewportFrame

            -- 1. Подготовка дома
            local displayHouse = houseModel:Clone()
            if displayHouse:FindFirstChild("Doors") then displayHouse.Doors:Destroy() end
            
            for _, part in pairs(displayHouse:GetDescendants()) do
                if part:IsA("BasePart") then
                    local n = string.lower(part.Name)
                    -- Жесткая зачистка невидимого мусора
                    if part.Transparency >= 1 or n == "plot" or n == "base" or n == "hitbox" or n == "driveway" then
                        part:Destroy()
                    else
                        part.Anchored = true
                        part.CanCollide = false
                    end
                elseif not part:IsA("Model") and not part:IsA("Folder") then
                    part:Destroy() 
                end
            end
            
            displayHouse.Parent = previewGroup
            displayHouse:PivotTo(CFrame.new(0, 0, 0))
            
            -- 2. Подготовка оригинального купола (без красных домов внутри)
            local dome = domeTemplate:Clone()
            for _, child in pairs(dome:GetChildren()) do
                if child:IsA("Model") then child:Destroy() end
            end
            dome.Parent = previewGroup
            
            -- Ставим купол ровно под дом (чуть-чуть утапливаем, чтобы не было щелей)
            local houseCFrame, houseSize = displayHouse:GetBoundingBox()
            local domeCFrame, domeSize = dome:GetBoundingBox()
            local domeY = -(houseSize.Y / 2) - (domeSize.Y / 2) + 0.5
            dome:PivotTo(CFrame.new(0, domeY, 0))

            -- 3. Анимация: плавно крутим саму группу, а не камеру!
            local angle = 0
            RunService.RenderStepped:Connect(function(dt)
                if not viewportFrame.Parent then return end
                angle = angle + math.rad(15 * dt)
                previewGroup:PivotTo(CFrame.Angles(0, angle, 0))
            end)
            
            return true
        end
        return false
    end

    local function getServerHouses()
        local houses = {}
        local workspaceExteriors = workspace:FindFirstChild("HouseExteriors")
        if not workspaceExteriors then return houses end

        for _, plot in pairs(workspaceExteriors:GetChildren()) do
            local houseModel = plot:GetChildren()[1]
            if houseModel and houseModel:FindFirstChild("Doors") and houseModel.Doors:FindFirstChild("MainDoor") then
                local mainDoor = houseModel.Doors.MainDoor
                local config = mainDoor:FindFirstChild("WorkingParts") and mainDoor.WorkingParts:FindFirstChild("Configuration")
                
                if config and config:FindFirstChild("house_owner") then
                    local ownerName = config.house_owner.Value
                    local touchPart = mainDoor.WorkingParts:FindFirstChild("TouchToEnter")
                    
                    if ownerName and ownerName ~= "" and touchPart then
                        table.insert(houses, {
                            Owner = ownerName,
                            HouseType = houseModel.Name,
                            DoorPart = touchPart,
                            TeleportCFrame = touchPart.CFrame * CFrame.new(0, 0, 4)
                        })
                    end
                end
            end
        end
        return houses
    end

    -- ==========================================
    -- 2D ИНТЕРФЕЙС: СЛОИ ПО ТВОЕМУ МАКЕТУ
    -- ==========================================
    
    Library.Utils.Make("TextLabel", { 
        Text = "Teleport to house:", 
        Size = UDim2.new(1, 0, 0, 20), 
        BackgroundTransparency = 1, 
        Font = Enum.Font.GothamMedium, 
        TextSize = 13, 
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Tab.Page 
    }, { TextColor3 = "SubText" })

    local Container = Library.Utils.Make("Frame", { 
        Size = UDim2.new(1, 0, 0, 0), 
        AutomaticSize = Enum.AutomaticSize.Y, 
        BackgroundTransparency = 1, 
        Parent = Tab.Page 
    })
    
    Library.Utils.Make("UIGridLayout", { 
        CellSize = UDim2.new(0.48, 0, 0, 150), 
        CellPadding = UDim2.new(0.04, 0, 0, 15), 
        SortOrder = Enum.SortOrder.LayoutOrder, 
        Parent = Container 
    })

    local function createHouseCard(houseData, index)
        -- СЛОЙ 0: Главная база (ОБРЕЗКА ОТКЛЮЧЕНА, чтобы обводка была красивой)
        local Tile = Library.Utils.Make("TextButton", { Text = "", AutoButtonColor = false, ClipsDescendants = false, Parent = Container }, { BackgroundColor3 = "Section" })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Tile})
        Library.Utils.Make("UIStroke", {Thickness = 1, Transparency = 0.5, Parent = Tile}, {Color = "Stroke"})
        
        local RippleContainer = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 10, Parent = Tile })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 12), Parent = RippleContainer})

        -- СЛОЙ 1: Вьюпорт (С отступами, внутри базы, ОБРЕЗКА ВКЛЮЧЕНА)
        local Viewport = Library.Utils.Make("ViewportFrame", {
            Size = UDim2.new(1, -16, 1, -40), 
            Position = UDim2.new(0, 8, 0, 8), 
            BackgroundColor3 = Color3.fromRGB(20, 20, 25), 
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 1, 
            Parent = Tile
        })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 8), Parent = Viewport})
        Library.Utils.Make("UIStroke", {Thickness = 1, Transparency = 0.7, Parent = Viewport}, {Color = "Stroke"})

        -- Акцентная линия лежит ВНУТРИ Вьюпорта (идеально обрезается по его углам)
        local AccentLine = Library.Utils.Make("Frame", { 
            Size = UDim2.new(0.35, 0, 0, 3), 
            Position = UDim2.new(1, -6, 1, -6), 
            AnchorPoint = Vector2.new(1, 1), 
            BorderSizePixel = 0, 
            ZIndex = 5, 
            Parent = Viewport 
        }, { BackgroundColor3 = "Accent" })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = AccentLine})

        -- ТА САМАЯ ИДЕАЛЬНАЯ КАМЕРА ИЗ ИГРЫ (№4)
        local VpCamera = Instance.new("Camera")
        VpCamera.FieldOfView = 40 
        -- Точные координаты разработчиков Adopt Me:
        VpCamera.CFrame = CFrame.new(111.803398, 71.5109024, 111.803146, 0.707106769, -0.348155349, 0.615457475, 0, 0.870388269, 0.492365986, -0.707106829, -0.34815532, 0.615457416)
        
        Viewport.CurrentCamera = VpCamera
        VpCamera.Parent = Viewport
        buildCleanPreview(houseData.HouseType, Viewport)

        -- СЛОЙ 2: Аватарка и Ник (Лежат ПОВЕРХ Вьюпорта на Главной базе)
        local Avatar = Library.Utils.Make("ImageLabel", {
            Size = UDim2.new(0, 28, 0, 28), 
            Position = UDim2.new(0, 14, 1, -8), -- Вылезает за пределы Вьюпорта, как на макете
            AnchorPoint = Vector2.new(0, 1), 
            BackgroundColor3 = Color3.fromRGB(30, 30, 35), 
            BackgroundTransparency = 0, 
            ZIndex = 4, 
            Parent = Tile
        })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Avatar})
        Library.Utils.Make("UIStroke", {Thickness = 2, Parent = Avatar}, {Color = "Section"}) 
        applyAvatar(Avatar, houseData.Owner, index) -- Передаем индекс для очереди загрузки

        local NameLbl = Library.Utils.Make("TextLabel", { 
            Text = houseData.Owner, 
            Size = UDim2.new(1, -54, 0, 20), 
            Position = UDim2.new(0, 48, 1, -12), 
            AnchorPoint = Vector2.new(0, 1), 
            BackgroundTransparency = 1, 
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.GothamMedium, 
            TextSize = 13, 
            TextTruncate = Enum.TextTruncate.AtEnd, 
            ZIndex = 3, 
            Parent = Tile 
        }, { TextColor3 = "Text" })

        local Scale = Instance.new("UIScale", Tile)

        Library:Connect(Tile.MouseEnter, function()
            Library.Utils.TBT(AccentLine, 0.3, {Size = UDim2.new(0.6, 0, 0, 4)})
            Library.Utils.TBT(Viewport, 0.3, {BackgroundColor3 = Color3.fromRGB(25, 25, 30)})
        end)

        Library:Connect(Tile.MouseLeave, function()
            Library.Utils.TBT(AccentLine, 0.3, {Size = UDim2.new(0.35, 0, 0, 3)})
            Library.Utils.TBT(Viewport, 0.3, {BackgroundColor3 = Color3.fromRGB(20, 20, 25)})
        end)

        Library:Connect(Tile.MouseButton1Down, function() 
            Library.Utils.TBT(Scale, 0.1, {Scale = 0.96}) 
        end)

        Library:Connect(Tile.MouseButton1Click, function()
            Library.Utils.TBT(Scale, 0.15, {Scale = 1}, Enum.EasingStyle.Bounce)
            Library.Utils.CreateRipple(RippleContainer)
            
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = houseData.TeleportCFrame
                if Library.Notify then
                    Library:Notify("Teleport", "Moved to " .. houseData.Owner .. "'s house", 3, "10723426722")
                end
            end
        end)
    end

    task.spawn(function()
        local success, err = pcall(function()
            local houses = getServerHouses()
            if #houses > 0 then
                for index, houseData in ipairs(houses) do
                    createHouseCard(houseData, index)
                end
            else
                createHouseCard({
                    Owner = LocalPlayer.Name,
                    HouseType = "Micro",
                    TeleportCFrame = LocalPlayer.Character and LocalPlayer.Character:GetPivot() or CFrame.new()
                }, 1)
            end
        end)
        if not success then warn("[Dusk&Shine Teleport] Ошибка рендера: ", err) end
    end)
end

return Module
