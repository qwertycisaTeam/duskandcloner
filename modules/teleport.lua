local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Module = {}

function Module:Init(Library, Window, Tab)

    -- ==========================================
    -- ОЧЕРЕДЬ ЗАГРУЗКИ АВАТАРОВ
    -- ==========================================
    local function applyAvatar(imageLabel, username, index)
        task.spawn(function()
            task.wait(index * 0.15) 
            
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
    -- 3D РЕНДЕР: ТОЛЬКО ДОМ, ИДЕАЛЬНАЯ КАМЕРА
    -- ==========================================
    local function buildCleanPreview(houseType, viewportFrame)
        local Resources = ReplicatedStorage:FindFirstChild("Resources")
        if not Resources then return end
        
        local houseExteriors = Resources:FindFirstChild("HouseExteriors")
        local houseModel = houseExteriors and houseExteriors:FindFirstChild(houseType)
        
        if houseModel then
            local displayHouse = houseModel:Clone()
            
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
            
            displayHouse.Parent = viewportFrame
            
            local cf, size = displayHouse:GetBoundingBox()
            return displayHouse, size, cf.Position
        end
        return nil, nil, nil
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
                            DoorPart = touchPart
                        })
                    end
                end
            end
        end
        return houses
    end

    -- ==========================================
    -- 2D ИНТЕРФЕЙС И ЛОГИКА ТЕЛЕПОРТА
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

    local function (houseData, index)
        local Tile = Library.Utils.Make("TextButton", { Text = "", AutoButtonColor = false, ClipsDescendants = false, Parent = Container }, { BackgroundColor3 = "Section" })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Tile})
        Library.Utils.Make("UIStroke", {Thickness = 1, Transparency = 0.5, Parent = Tile}, {Color = "Stroke"})
        
        Library.Utils.Make("UIPadding", { 
            PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), 
            PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), 
            Parent = Tile 
        })

        local RippleContainer = Library.Utils.Make("Frame", { Size = UDim2.new(1, 16, 1, 16), Position = UDim2.new(0, -8, 0, -8), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 10, Parent = Tile })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 12), Parent = RippleContainer})

        local Viewport = Library.Utils.Make("ViewportFrame", {
            Size = UDim2.new(1, -16, 1, -40), 
            Position = UDim2.new(0, 8, 0, 8), 
            BackgroundTransparency = 1, -- УБРАН ЧЕРНЫЙ ФОН
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 1, 
            Parent = Tile
        })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 8), Parent = Viewport})
        Library.Utils.Make("UIStroke", {Thickness = 1, Transparency = 0.7, Parent = Viewport}, {Color = "Stroke"})

        local AccentLine = Library.Utils.Make("Frame", { 
            Size = UDim2.new(0.35, 0, 0, 3), 
            Position = UDim2.new(1, -6, 1, -6), 
            AnchorPoint = Vector2.new(1, 1), 
            BorderSizePixel = 0, 
            ZIndex = 5, 
            Parent = Viewport 
        }, { BackgroundColor3 = "Accent" })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = AccentLine})

        local displayHouse, houseSize, centerPos = buildCleanPreview(houseData.HouseType, Viewport)
        
        if displayHouse and houseSize and centerPos then
            local VpCamera = Instance.new("Camera")
            VpCamera.FieldOfView = 50 
            Viewport.CurrentCamera = VpCamera
            VpCamera.Parent = Viewport
            
            local radius = houseSize.Magnitude / 2
            local distance = (radius / math.tan(math.rad(VpCamera.FieldOfView / 2))) * 1.1
            
            local angle = 0
            RunService.RenderStepped:Connect(function(dt)
                if not Viewport.Parent then return end
                angle = angle + math.rad(25 * dt)
                local camPos = centerPos + Vector3.new(math.cos(angle) * distance * 0.8, distance * 0.4, math.sin(angle) * distance * 0.8)
                VpCamera.CFrame = CFrame.lookAt(camPos, centerPos)
            end)
        end

        local Avatar = Library.Utils.Make("ImageLabel", {
            Size = UDim2.new(0, 28, 0, 28), 
            Position = UDim2.new(0, 14, 1, -8), 
            AnchorPoint = Vector2.new(0, 1), 
            BackgroundTransparency = 1, -- УБРАН ФОН У АВАТАРКИ
            ZIndex = 4, 
            Parent = Tile
        })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Avatar})
        Library.Utils.Make("UIStroke", {Thickness = 2, Parent = Avatar}, {Color = "Section"}) 
        applyAvatar(Avatar, houseData.Owner, index) 

        -- [ ... код текста остается без изменений ... ]

        local Scale = Instance.new("UIScale", Tile)

        Library:Connect(Tile.MouseEnter, function()
            Library.Utils.TBT(AccentLine, 0.3, {Size = UDim2.new(0.6, 0, 0, 4)})
        end)

        Library:Connect(Tile.MouseLeave, function()
            Library.Utils.TBT(AccentLine, 0.3, {Size = UDim2.new(0.35, 0, 0, 3)})
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
                local posY = hrp.Position.Y
                if posY < 8500 then
                    if Library.Notify then
                        Library:Notify("Error", "Teleport works ONLY in the neighborhood!", 4)
                    end
                    return 
                end

                local touchPart = houseData.DoorPart
                if not touchPart or not touchPart.Parent then 
                    if Library.Notify then Library:Notify("Error", "House not found!", 3) end
                    return 
                end

                -- 1. Телепортируемся в триггер, но разворачиваем персонажа ЛИЦОМ в дом
                -- (Смотрим на точку, которая находится на 5 стадов позади двери)
                local lookTarget = (touchPart.CFrame * CFrame.new(0, 0, -5)).Position
                hrp.CFrame = CFrame.lookAt(touchPart.Position, lookTarget)
                
                if Library.Notify then
                    Library:Notify("Teleport", "Entering " .. houseData.Owner .. "'s house...", 3, "10723426722")
                end

                -- ==========================================
                -- ЛОГИКА МГНОВЕННОГО ВХОДА
                -- ==========================================
                task.spawn(function()
                    task.wait(0.25) 
                    
                    local doorModel = touchPart.Parent.Parent
                    
                    -- 2. Снимаем замки
                    pcall(function()
                        local successDoors, DoorsM = pcall(function()
                            return require(ReplicatedStorage.ClientModules.Core.DoorsM.DoorsM)
                        end)
                        
                        if successDoors and DoorsM then
                            local doorObj = DoorsM.get_door(doorModel)
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
                    end)
                    
                    -- 3. МИКРО-ДВИЖЕНИЕ ВПЕРЕД (Толкаем персонажа лицом вглубь дома)
                    -- Вектор -Z (0, 0, -0.5) означает движение вперед туда, куда смотрит лицо
                    hrp.CFrame = hrp.CFrame * CFrame.new(0, 0, -0.5)
                    
                    -- 4. Добивка эмуляцией
                    if firetouchinterest then
                        firetouchinterest(hrp, touchPart, 0)
                        task.wait(0.1)
                        firetouchinterest(hrp, touchPart, 1)
                    end
                end)
            end
        end)
    end

    -- ==========================================
    -- АВТО-ОБНОВЛЕНИЕ КАРТОЧЕК С КЭШЕМ
    -- ==========================================
    local refreshThread = nil
    local CachedHouses = {}

    local function updateHouseCards()
        for _, child in ipairs(Container:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        local success, err = pcall(function()
            local houses = getServerHouses()
            
            -- Логика кэша: обновляем кэш только если дома реально найдены
            if #houses > 0 then
                CachedHouses = houses
            else
                houses = CachedHouses 
            end
            
            if #houses > 0 then
                for index, houseData in ipairs(houses) do
                    createHouseCard(houseData, index)
                end
            else
                createHouseCard({
                    Owner = LocalPlayer.Name,
                    HouseType = "Micro",
                    DoorPart = nil
                }, 1)
            end
        end)
        
        if not success then warn("[Dusk&Shine Teleport] Ошибка рендера: ", err) end
    end

    local function queueRefresh()
        if refreshThread then task.cancel(refreshThread) end
        refreshThread = task.spawn(function()
            task.wait(1.5) 
            updateHouseCards()
        end)
    end

    queueRefresh()

    local workspaceExteriors = workspace:WaitForChild("HouseExteriors", 5)
    if workspaceExteriors then
        workspaceExteriors.DescendantAdded:Connect(function(descendant)
            if descendant.Parent and descendant.Parent.Parent == workspaceExteriors then
                queueRefresh()
            end
        end)
        
        workspaceExteriors.DescendantRemoving:Connect(function(descendant)
            if descendant.Parent and descendant.Parent.Parent == workspaceExteriors then
                queueRefresh()
            end
        end)
    end
    
    Players.PlayerRemoving:Connect(queueRefresh)
end

return Module
