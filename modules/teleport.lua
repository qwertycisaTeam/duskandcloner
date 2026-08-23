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
                -- Дефолтная заглушка, если Роблокс не отдает картинку
                imageLabel.Image = "rbxassetid://10827393433" 
            end
        end)
    end

    -- ==========================================
    -- ИДЕАЛЬНЫЙ 3D РЕНДЕР (КАК В ОРИГИНАЛЕ ADOPT ME)
    -- ==========================================
    local function buildCleanPreview(houseType, viewportFrame)
        local Resources = ReplicatedStorage:FindFirstChild("Resources")
        if not Resources then return end
        
        local domeTemplate = Resources:FindFirstChild("HousePreviewDome")
        local houseExteriors = Resources:FindFirstChild("HouseExteriors")
        local houseModel = houseExteriors and houseExteriors:FindFirstChild(houseType)
        
        if domeTemplate and houseModel then
            -- 1. Подготавливаем чистый купол
            local dome = domeTemplate:Clone()
            for _, child in pairs(dome:GetChildren()) do
                -- Уничтожаем всё, что разработчики спрятали внутри купола (в т.ч. красный домик)
                child:Destroy() 
            end
            dome.Parent = viewportFrame
            dome:PivotTo(CFrame.new(0, 0, 0))
            local domeCFrame, domeSize = dome:GetBoundingBox()
            
            -- 2. Подготавливаем дом
            local displayHouse = houseModel:Clone()
            
            -- Жесткая чистка дома от невидимых стен и баз
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
                    part:Destroy() -- Удаляем партиклы, скрипты, свет
                end
            end
            
            displayHouse.Parent = viewportFrame
            
            -- 3. Высчитываем реальные размеры очищенного дома
            local houseCFrame, houseSize = displayHouse:GetBoundingBox()
            
            -- 4. Сжимаем ДОМ, чтобы он поместился на лужайку (занимает 50% ширины лужайки)
            local maxHouseWidth = math.max(houseSize.X, houseSize.Z)
            if maxHouseWidth > 0 then
                local scaleFactor = (domeSize.X * 0.5) / maxHouseWidth
                -- Защита от слишком высоких зданий (небоскребов)
                if (houseSize.Y * scaleFactor) > (domeSize.X * 0.6) then
                    scaleFactor = (domeSize.X * 0.6) / houseSize.Y
                end
                
                pcall(function() displayHouse:ScaleTo(scaleFactor) end)
            end
            
            -- 5. Ставим сжатый дом ровно на верхушку купола
            local newHouseCFrame, newHouseSize = displayHouse:GetBoundingBox()
            -- domeCFrame.Y + domeSize.Y/2 = верхушка лужайки
            -- newHouseSize.Y/2 = половина высоты дома
            -- -0.2 = чуть-чуть утапливаем в траву, чтобы скрыть щели
            local targetY = (domeCFrame.Y + domeSize.Y / 2) + (newHouseSize.Y / 2) - 0.2
            
            -- Перемещаем дом в центр купола по X и Z, и на targetY по высоте
            displayHouse:PivotTo(CFrame.new(domeCFrame.X, targetY, domeCFrame.Z) * (newHouseCFrame - newHouseCFrame.Position))
            
            return domeSize
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
    -- СОЗДАНИЕ 2D ИНТЕРФЕЙСА (СТРОГО ПО СКЕТЧУ 1 В 1)
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
        -- 1. Основная карточка
        local Tile = Library.Utils.Make("TextButton", { Text = "", AutoButtonColor = false, ClipsDescendants = false, Parent = Container }, { BackgroundColor3 = "Section" })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Tile})
        Library.Utils.Make("UIStroke", {Thickness = 1, Transparency = 0.5, Parent = Tile}, {Color = "Stroke"})
        
        -- Идеальные отступы внутри карточки (как на макете)
        Library.Utils.Make("UIPadding", { 
            PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), 
            PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), 
            Parent = Tile 
        })

        local RippleContainer = Library.Utils.Make("Frame", { Size = UDim2.new(1, 16, 1, 16), Position = UDim2.new(0, -8, 0, -8), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 10, Parent = Tile })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 12), Parent = RippleContainer})

        -- 2. Вьюпорт (Окошко для дома)
        local Viewport = Library.Utils.Make("ViewportFrame", {
            Size = UDim2.new(1, 0, 1, -28), -- Оставляем 28px снизу для имени и аватарки
            Position = UDim2.new(0, 0, 0, 0), 
            BackgroundColor3 = Color3.fromRGB(20, 20, 25), 
            BorderSizePixel = 0,
            ZIndex = 1, 
            Parent = Tile
        })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 8), Parent = Viewport})
        Library.Utils.Make("UIStroke", {Thickness = 1, Transparency = 0.7, Parent = Viewport}, {Color = "Stroke"})

        -- 3. Настройка СТАТИЧНОЙ камеры
        local VpCamera = Instance.new("Camera")
        VpCamera.FieldOfView = 60
        Viewport.CurrentCamera = VpCamera
        VpCamera.Parent = Viewport
        
        local domeSize = buildCleanPreview(houseData.HouseType, Viewport)
        if domeSize then
            -- Статичный, красивый изометрический вид спереди-справа-сверху
            local camDist = math.max(domeSize.X, domeSize.Z) * 0.95
            local camPos = Vector3.new(camDist * 0.8, camDist * 0.6, camDist * 0.8)
            local lookAt = Vector3.new(0, domeSize.Y / 2, 0)
            
            VpCamera.CFrame = CFrame.new(camPos, lookAt)
        end

        -- 4. Аватарка (снизу слева)
        local Avatar = Library.Utils.Make("ImageLabel", {
            Size = UDim2.new(0, 22, 0, 22), 
            Position = UDim2.new(0, 4, 1, 0), 
            AnchorPoint = Vector2.new(0, 1), 
            BackgroundColor3 = Color3.fromRGB(30, 30, 35), 
            BackgroundTransparency = 0, 
            ZIndex = 3, 
            Parent = Tile
        })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Avatar})
        applyAvatar(Avatar, houseData.Owner)

        -- 5. Никнейм (снизу справа от аватарки)
        local NameLbl = Library.Utils.Make("TextLabel", { 
            Text = houseData.Owner, 
            Size = UDim2.new(1, -34, 0, 22), 
            Position = UDim2.new(0, 34, 1, 0), 
            AnchorPoint = Vector2.new(0, 1), 
            BackgroundTransparency = 1, 
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.GothamMedium, 
            TextSize = 12, 
            TextTruncate = Enum.TextTruncate.AtEnd, 
            ZIndex = 3, 
            Parent = Tile 
        }, { TextColor3 = "Text" })

        -- 6. Анимации нажатия
        local Scale = Instance.new("UIScale", Tile)

        Library:Connect(Tile.MouseEnter, function()
            Library.Utils.TBT(Viewport, 0.2, {BackgroundColor3 = Color3.fromRGB(25, 25, 30)})
        end)

        Library:Connect(Tile.MouseLeave, function()
            Library.Utils.TBT(Viewport, 0.2, {BackgroundColor3 = Color3.fromRGB(20, 20, 25)})
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
