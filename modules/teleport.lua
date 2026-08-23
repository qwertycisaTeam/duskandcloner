local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Module = {}

function Module:Init(Library, Window, Tab)

    -- ==========================================
    -- 1. ЗАГРУЗКА АВАТАРА (С ЗАГЛУШКОЙ ПРИ ОШИБКАХ РОБЛОКСА)
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
                -- Если Роблокс лагает, ставим дефолтную серую иконку
                imageLabel.Image = "rbxassetid://10827393433" 
            end
        end)
    end

    -- ==========================================
    -- 2. НОВАЯ ЛОГИКА 3D (БЕЗ ИСКАЖЕНИЙ И БАГОВ)
    -- ==========================================
    local function buildCleanPreview(houseType, viewportFrame)
        local Resources = ReplicatedStorage:FindFirstChild("Resources")
        if not Resources then return end
        
        local domeTemplate = Resources:FindFirstChild("HousePreviewDome")
        local houseExteriors = Resources:FindFirstChild("HouseExteriors")
        local houseModel = houseExteriors and houseExteriors:FindFirstChild(houseType)
        
        if domeTemplate and houseModel then
            local displayHouse = houseModel:Clone()
            
            -- Удаляем мусор (двери, невидимые коллизии)
            if displayHouse:FindFirstChild("Doors") then displayHouse.Doors:Destroy() end
            for _, part in pairs(displayHouse:GetDescendants()) do
                if part:IsA("BasePart") then
                    if part.Transparency >= 1 then
                        part:Destroy()
                    else
                        part.Anchored = true
                        part.CanCollide = false
                    end
                elseif part:IsA("Script") or part:IsA("LocalScript") then
                    part:Destroy()
                end
            end
            
            displayHouse.Parent = viewportFrame
            
            -- 1. Ставим дом ровно в центр мира (0,0,0)
            displayHouse:PivotTo(CFrame.new(0, 0, 0))
            local houseCFrame, houseSize = displayHouse:GetBoundingBox()
            
            -- 2. Добавляем зеленый купол
            local dome = domeTemplate:Clone()
            dome.Parent = viewportFrame
            local domeCFrame, domeSize = dome:GetBoundingBox()
            
            -- 3. Увеличиваем купол, если дом слишком большой (купол не сломается)
            local maxHouseWidth = math.max(houseSize.X, houseSize.Z)
            local requiredScale = (maxHouseWidth * 1.3) / domeSize.X
            if requiredScale > 1 then
                pcall(function() dome:ScaleTo(requiredScale) end)
                domeCFrame, domeSize = dome:GetBoundingBox()
            end
            
            -- 4. Ставим купол ровно под дом (утапливаем дом на 1.5 стада в траву)
            local domeY = -(houseSize.Y / 2) - (domeSize.Y / 2) + 1.5
            dome:PivotTo(CFrame.new(0, domeY, 0))
            
            -- Возвращаем габариты дома для настройки камеры
            return displayHouse, houseSize
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
    -- 3. СОЗДАНИЕ 2D ИНТЕРФЕЙСА (СТРОГИЙ МАКЕТ)
    -- ==========================================
    local Container = Library.Utils.Make("Frame", { 
        Size = UDim2.new(1, 0, 0, 0), 
        AutomaticSize = Enum.AutomaticSize.Y, 
        BackgroundTransparency = 1, 
        Parent = Tab.Page 
    })
    
    Library.Utils.Make("UIGridLayout", { 
        CellSize = UDim2.new(0.48, 0, 0, 160), 
        CellPadding = UDim2.new(0.04, 0, 0, 15), 
        SortOrder = Enum.SortOrder.LayoutOrder, 
        Parent = Container 
    })

    local function createHouseCard(houseData)
        -- Основа карточки
        local Tile = Library.Utils.Make("TextButton", { Text = "", AutoButtonColor = false, ClipsDescendants = true, Parent = Container }, { BackgroundColor3 = "Section" })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Tile})
        Library.Utils.Make("UIStroke", {Thickness = 1, Transparency = 0.5, Parent = Tile}, {Color = "Stroke"})
        
        -- Цветная полоска сверху
        local AccentLine = Library.Utils.Make("Frame", { 
            Size = UDim2.new(1, 0, 0, 4), 
            Position = UDim2.new(0, 0, 0, 0), 
            BorderSizePixel = 0, 
            ZIndex = 5, 
            Parent = Tile 
        }, { BackgroundColor3 = "Accent" })

        local RippleContainer = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 10, Parent = Tile })

        -- 3D Вьюпорт (занимает верхние 120 пикселей)
        local Viewport = Library.Utils.Make("ViewportFrame", {
            Size = UDim2.new(1, 0, 1, -40), 
            Position = UDim2.new(0, 0, 0, 4), 
            BackgroundColor3 = Color3.fromRGB(20, 20, 25), 
            BorderSizePixel = 0,
            ZIndex = 1, 
            Parent = Tile
        })

        -- Плавный переход от 3D к нижней панели
        local GradFrame = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0.4, 0), Position = UDim2.new(0, 0, 1, 0), AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = Viewport })
        local Grad = Instance.new("UIGradient")
        Grad.Rotation = 90
        Grad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
        Grad.Color = ColorSequence.new(Color3.new(0,0,0))
        Grad.Parent = GradFrame

        -- Камера
        local VpCamera = Instance.new("Camera")
        Viewport.CurrentCamera = VpCamera
        VpCamera.Parent = Viewport
        
        local houseObj, houseSize = buildCleanPreview(houseData.HouseType, Viewport)
        if houseObj and houseSize then
            -- Вычисляем дистанцию на основе реальных габаритов дома
            local maxDim = math.max(houseSize.X, houseSize.Y, houseSize.Z)
            local radius = maxDim * 1.1 -- Коэффициент отдаления
            if radius < 35 then radius = 35 end
            
            local angle = 0
            RunService.RenderStepped:Connect(function(dt)
                if not Viewport.Parent then return end
                angle = angle + math.rad(15 * dt)
                -- Камера летает вокруг 0,0,0 и смотрит прямо в 0,0,0
                local camPos = Vector3.new(math.cos(angle) * radius, houseSize.Y * 0.4, math.sin(angle) * radius)
                VpCamera.CFrame = CFrame.new(camPos, Vector3.new(0, 0, 0))
            end)
        end

        -- Аватарка (в нижних 36 пикселях)
        local Avatar = Library.Utils.Make("ImageLabel", {
            Size = UDim2.new(0, 26, 0, 26), 
            Position = UDim2.new(0, 8, 1, -6), 
            AnchorPoint = Vector2.new(0, 1), 
            BackgroundColor3 = Color3.fromRGB(30, 30, 35), 
            BackgroundTransparency = 0, 
            ZIndex = 3, 
            Parent = Tile
        })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Avatar})
        applyAvatar(Avatar, houseData.Owner)

        -- Никнейм
        local NameLbl = Library.Utils.Make("TextLabel", { 
            Text = houseData.Owner, 
            Size = UDim2.new(1, -44, 0, 26), 
            Position = UDim2.new(0, 42, 1, -6), 
            AnchorPoint = Vector2.new(0, 1), 
            BackgroundTransparency = 1, 
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.GothamMedium, 
            TextSize = 13, 
            TextTruncate = Enum.TextTruncate.AtEnd, 
            ZIndex = 3, 
            Parent = Tile 
        }, { TextColor3 = "Text" })

        -- Эффекты
        local Scale = Instance.new("UIScale", Tile)

        Library:Connect(Tile.MouseEnter, function()
            Library.Utils.TBT(AccentLine, 0.3, {Size = UDim2.new(1, 0, 0, 6)})
        end)

        Library:Connect(Tile.MouseLeave, function()
            Library.Utils.TBT(AccentLine, 0.3, {Size = UDim2.new(1, 0, 0, 4)})
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
        
        if not success then
            warn("[Dusk&Shine Teleport] Ошибка рендера вкладки: ", err)
        end
    end)
end

return Module
