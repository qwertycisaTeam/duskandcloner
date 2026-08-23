local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Module = {}

function Module:Init(Library, Window, Tab)

    -- ==========================================
    -- БЕЗОПАСНАЯ ЗАГРУЗКА АВАТАРОВ
    -- ==========================================
    local function applyAvatar(imageLabel, username)
        task.spawn(function()
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
    -- ИДЕАЛЬНЫЙ МАТЕМАТИЧЕСКИЙ 3D РЕНДЕР
    -- ==========================================
    local function buildCleanPreview(houseType, viewportFrame)
        local Resources = ReplicatedStorage:FindFirstChild("Resources")
        if not Resources then return end
        
        local domeTemplate = Resources:FindFirstChild("HousePreviewDome")
        local houseExteriors = Resources:FindFirstChild("HouseExteriors")
        local houseModel = houseExteriors and houseExteriors:FindFirstChild(houseType)
        
        if domeTemplate and houseModel then
            -- Создаем общую группу, чтобы потом измерить всё вместе
            local previewGroup = Instance.new("Model")
            previewGroup.Name = "PreviewGroup"
            previewGroup.Parent = viewportFrame

            local displayHouse = houseModel:Clone()
            
            -- Вычищаем всё невидимое и техническое
            if displayHouse:FindFirstChild("Doors") then displayHouse.Doors:Destroy() end
            for _, part in pairs(displayHouse:GetDescendants()) do
                if part:IsA("BasePart") then
                    local n = string.lower(part.Name)
                    if part.Transparency >= 1 or n == "plot" or n == "base" or n == "hitbox" or n == "driveway" or n == "floor" then
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
            local houseCFrame, houseSize = displayHouse:GetBoundingBox()
            
            -- Готовим чистую траву
            local dome = domeTemplate:Clone()
            for _, child in pairs(dome:GetChildren()) do
                if child:IsA("Model") then child:Destroy() end
            end
            dome.Parent = previewGroup
            
            local domeCFrame, domeSize = dome:GetBoundingBox()
            
            -- Масштабируем траву под дом
            local maxHouseWidth = math.max(houseSize.X, houseSize.Z)
            local requiredScale = (maxHouseWidth * 1.3) / domeSize.X
            if requiredScale < 1 then requiredScale = 1 end
            pcall(function() dome:ScaleTo(requiredScale) end)
            
            domeCFrame, domeSize = dome:GetBoundingBox()
            local domeY = -(houseSize.Y / 2) - (domeSize.Y / 2) + 0.5
            dome:PivotTo(CFrame.new(0, domeY, 0))
            
            -- Возвращаем готовую сцену
            return previewGroup
        end
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
    -- СОЗДАНИЕ 2D ИНТЕРФЕЙСА (СТРОГО ПО СКЕТЧУ)
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

    local function createHouseCard(houseData)
        local Tile = Library.Utils.Make("TextButton", { Text = "", AutoButtonColor = false, ClipsDescendants = false, Parent = Container }, { BackgroundColor3 = "Section" })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Tile})
        Library.Utils.Make("UIStroke", {Thickness = 1, Transparency = 0.5, Parent = Tile}, {Color = "Stroke"})
        
        -- Устанавливаем единые отступы для всей карточки
        Library.Utils.Make("UIPadding", { 
            PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), 
            PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), 
            Parent = Tile 
        })

        local RippleContainer = Library.Utils.Make("Frame", { Size = UDim2.new(1, 16, 1, 16), Position = UDim2.new(0, -8, 0, -8), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 10, Parent = Tile })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 12), Parent = RippleContainer})

        -- Вьюпорт (Оставляем 24px снизу)
        local Viewport = Library.Utils.Make("ViewportFrame", {
            Size = UDim2.new(1, 0, 1, -24), 
            Position = UDim2.new(0, 0, 0, 0), 
            BackgroundColor3 = Color3.fromRGB(20, 20, 25), 
            BorderSizePixel = 0,
            ZIndex = 1, 
            Parent = Tile
        })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 8), Parent = Viewport})
        Library.Utils.Make("UIStroke", {Thickness = 1, Transparency = 0.7, Parent = Viewport}, {Color = "Stroke"})

        -- Линия внутри
        local AccentLine = Library.Utils.Make("Frame", { 
            Size = UDim2.new(0.35, 0, 0, 3), 
            Position = UDim2.new(1, -8, 1, -8), 
            AnchorPoint = Vector2.new(1, 1), 
            BorderSizePixel = 0, 
            ZIndex = 5, 
            Parent = Viewport 
        }, { BackgroundColor3 = "Accent" })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = AccentLine})

        -- Камера (Изометрия с вычислением тангенса)
        local VpCamera = Instance.new("Camera")
        VpCamera.FieldOfView = 40 -- Уменьшенный FOV дает крутой изометрический вид без сильных искажений
        Viewport.CurrentCamera = VpCamera
        VpCamera.Parent = Viewport
        
        local previewGroup = buildCleanPreview(houseData.HouseType, Viewport)
        if previewGroup then
            local cf, size = previewGroup:GetBoundingBox()
            
            -- Формула вычисления дистанции, чтобы объект 100% влез в камеру
            local radius = size.Magnitude / 2
            local distance = (radius / math.tan(math.rad(VpCamera.FieldOfView / 2))) * 1.15 -- 15% запас по краям
            
            -- Изометрический вектор: смотрит спереди, справа и сверху
            local offset = Vector3.new(1, 0.8, 1).Unit * distance
            VpCamera.CFrame = CFrame.lookAt(cf.Position + offset, cf.Position)
        end

        -- Аватарка (Крутая фишка: она "наслаивается" на 3D превью снизу-слева!)
        local Avatar = Library.Utils.Make("ImageLabel", {
            Size = UDim2.new(0, 28, 0, 28), 
            Position = UDim2.new(0, 4, 1, -2), 
            AnchorPoint = Vector2.new(0, 1), 
            BackgroundColor3 = Color3.fromRGB(30, 30, 35), 
            BackgroundTransparency = 0, 
            ZIndex = 4, 
            Parent = Tile
        })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Avatar})
        Library.Utils.Make("UIStroke", {Thickness = 2, Parent = Avatar}, {Color = "Section"}) 
        applyAvatar(Avatar, houseData.Owner)

        -- Никнейм
        local NameLbl = Library.Utils.Make("TextLabel", { 
            Text = houseData.Owner, 
            Size = UDim2.new(1, -40, 0, 20), 
            Position = UDim2.new(0, 38, 1, -6), 
            AnchorPoint = Vector2.new(0, 1), 
            BackgroundTransparency = 1, 
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.GothamMedium, 
            TextSize = 13, 
            TextTruncate = Enum.TextTruncate.AtEnd, 
            ZIndex = 3, 
            Parent = Tile 
        }, { TextColor3 = "Text" })

        -- Анимации
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
                for _, houseData in ipairs(houses) do
                    createHouseCard(houseData)
                end
            else
                createHouseCard({
                    Owner = LocalPlayer.Name,
                    HouseType = "Micro",
                    TeleportCFrame = LocalPlayer.Character and LocalPlayer.Character:GetPivot() or CFrame.new()
                })
            end
        end)
        if not success then warn("[Dusk&Shine Teleport] Ошибка рендера: ", err) end
    end)
end

return Module
