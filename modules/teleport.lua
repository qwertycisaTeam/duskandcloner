local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Module = {}

function Module:Init(Library, Window, Tab)

    -- ==========================================
    -- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
    -- ==========================================
    
    -- Бронебойная загрузка аватарок (сначала ищем на сервере, потом в API)
    local function applyAvatar(imageLabel, username)
        task.spawn(function()
            local userId = nil
            local player = Players:FindFirstChild(username)
            
            if player then
                userId = player.UserId
            else
                local s, id = pcall(function() return Players:GetUserIdFromNameAsync(username) end)
                if s then userId = id end
            end
            
            if userId then
                imageLabel.Image = "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150&h=150"
            end
        end)
    end

    local function buildCleanPreview(houseType, viewportFrame)
        local Resources = ReplicatedStorage:FindFirstChild("Resources")
        if not Resources then return end
        
        local domeTemplate = Resources:FindFirstChild("HousePreviewDome")
        local houseExteriors = Resources:FindFirstChild("HouseExteriors")
        local houseModel = houseExteriors and houseExteriors:FindFirstChild(houseType)
        
        if domeTemplate then
            local dome = domeTemplate:Clone()
            dome.Parent = viewportFrame
            
            if houseModel then
                local displayHouse = houseModel:Clone()
                
                -- Чистим коллизии и скрипты
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
                
                displayHouse.Parent = dome
                
                -- ИСПРАВЛЕНИЕ: Убрали проверку PrimaryPart у дома, теперь ставится 100%
                if dome.PrimaryPart then
                    displayHouse:PivotTo(dome.PrimaryPart.CFrame * CFrame.new(0, 0.5, 0))
                end
            end
            return dome
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
    -- СОЗДАНИЕ ИНТЕРФЕЙСА ЧЕРЕЗ LIBRARY.UTILS
    -- ==========================================
    
    local Container = Library.Utils.Make("Frame", { 
        Size = UDim2.new(1, 0, 0, 0), 
        AutomaticSize = Enum.AutomaticSize.Y, 
        BackgroundTransparency = 1, 
        Parent = Tab.Page 
    })
    
    Library.Utils.Make("UIGridLayout", { 
        CellSize = UDim2.new(0.48, 0, 0, 160), 
        CellPadding = UDim2.new(0.04, 0, 0, 18), 
        SortOrder = Enum.SortOrder.LayoutOrder, 
        Parent = Container 
    })

    local AccentColor = Library.CurrentTheme and Library.CurrentTheme.Accent or Color3.fromRGB(85, 170, 255)

    local function createHouseCard(houseData)
        -- Главная карточка
        local Tile = Library.Utils.Make("TextButton", { Text = "", AutoButtonColor = false, ClipsDescendants = true, Parent = Container }, { BackgroundColor3 = "Section" })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 10), Parent = Tile})
        Library.Utils.Make("UIStroke", {Thickness = 1, Transparency = 0.5, Parent = Tile}, {Color = "Stroke"})

        -- Контейнер для Ripple
        local RippleContainer = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 10, Parent = Tile })
        
        -- ИСПРАВЛЕНИЕ: Акцентная линия теперь встроена ровно в верхний край
        local AccentLine = Library.Utils.Make("Frame", { 
            Size = UDim2.new(1, 0, 0, 3), 
            Position = UDim2.new(0, 0, 0, 0), 
            BorderSizePixel = 0, 
            ZIndex = 5, 
            Parent = Tile 
        }, { BackgroundColor3 = "Accent" })

        -- 3D Вьюпорт (Сдвинут вплотную к верху)
        local Viewport = Library.Utils.Make("ViewportFrame", {
            Size = UDim2.new(1, 0, 0, 110), 
            Position = UDim2.new(0, 0, 0, 3), 
            BackgroundTransparency = 1, 
            ZIndex = 1, 
            Parent = Tile
        })

        local VpCamera = Instance.new("Camera")
        Viewport.CurrentCamera = VpCamera
        VpCamera.Parent = Viewport
        
        local dome = buildCleanPreview(houseData.HouseType, Viewport)
        if dome and dome.PrimaryPart then
            local cframe = dome.PrimaryPart.CFrame
            local radius = 35 
            local angle = 0
            
            RunService.RenderStepped:Connect(function(dt)
                if not Viewport.Parent then return end
                angle = angle + math.rad(15 * dt)
                VpCamera.CFrame = CFrame.new(cframe.Position + Vector3.new(math.cos(angle) * radius, 15, math.sin(angle) * radius), cframe.Position)
            end)
        end

        -- Градиент-затемнение
        local GradFrame = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0.4, 0), Position = UDim2.new(0, 0, 1, 0), AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = Tile })
        local Grad = Instance.new("UIGradient")
        Grad.Rotation = 90
        Grad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.1)})
        Grad.Color = ColorSequence.new(Color3.new(0,0,0))
        Grad.Parent = GradFrame

        -- ИСПРАВЛЕНИЕ: Аватарке задан дефолтный фон, чтобы не было пустоты во время загрузки
        local Avatar = Library.Utils.Make("ImageLabel", {
            Size = UDim2.new(0, 24, 0, 24), 
            Position = UDim2.new(0, 10, 1, -12), 
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
            Size = UDim2.new(1, -45, 0, 24), 
            Position = UDim2.new(0, 40, 1, -12), 
            AnchorPoint = Vector2.new(0, 1), 
            BackgroundTransparency = 1, 
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.GothamMedium, 
            TextSize = 12, 
            TextTruncate = Enum.TextTruncate.AtEnd, 
            ZIndex = 3, 
            Parent = Tile 
        }, { TextColor3 = "Text" })

        -- Анимации ховера
        local Scale = Instance.new("UIScale", Tile)

        Library:Connect(Tile.MouseEnter, function()
            Library.Utils.TBT(AccentLine, 0.3, {Size = UDim2.new(1, 0, 0, 5)})
        end)

        Library:Connect(Tile.MouseLeave, function()
            Library.Utils.TBT(AccentLine, 0.3, {Size = UDim2.new(1, 0, 0, 3)})
        end)

        Library:Connect(Tile.MouseButton1Down, function() 
            Library.Utils.TBT(Scale, 0.1, {Scale = 0.96}) 
        end)

        -- Телепортация
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
end

return Module
