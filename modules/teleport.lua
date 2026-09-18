
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = getgenv().DuskCore.plr

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
    -- 3D РЕНДЕР: УЛУЧШЕННЫЙ ПОИСК МОДЕЛЕЙ
    -- ==========================================
    local function buildCleanPreview(houseType, viewportFrame)
        local houseModel = nil

        -- 1. Сначала ищем модель в хранилище (работает с главной карты)
        local Resources = ReplicatedStorage:FindFirstChild("Resources")
        local rsExteriors = Resources and Resources:FindFirstChild("HouseExteriors")
        if rsExteriors then
            houseModel = rsExteriors:FindFirstChild(houseType)
        end

        -- 2. Если в хранилище нет (разрабы перенесли), берем физическую модель со спального района
        if not houseModel then
            local wsExteriors = workspace:FindFirstChild("HouseExteriors")
            if wsExteriors then
                for _, plot in pairs(wsExteriors:GetChildren()) do
                    local h = plot:GetChildren()[1]
                    if h and h.Name == houseType then
                        houseModel = h
                        break
                    end
                end
            end
        end

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

    -- ==========================================
    -- ГЛОБАЛЬНЫЙ РАДАР (Через карту участков)
    -- ==========================================
    local HouseTypeCache = {} -- Хранилище вида: HouseTypeCache["НикИгрока"] = "Estate"

    local function getServerHouses()
        local houses = {}
        local addedOwners = {}

        -- 1. Сканируем физический мир, если мы в районе
        local workspaceExteriors = workspace:FindFirstChild("HouseExteriors")
        if workspaceExteriors then
            for _, plot in pairs(workspaceExteriors:GetChildren()) do
                local houseModel = plot:GetChildren()[1]
                if houseModel and houseModel:FindFirstChild("Doors") and houseModel.Doors:FindFirstChild("MainDoor") then
                    local mainDoor = houseModel.Doors.MainDoor
                    local config = mainDoor:FindFirstChild("WorkingParts") and mainDoor.WorkingParts:FindFirstChild("Configuration")

                    if config and config:FindFirstChild("house_owner") then
                        local ownerName = config.house_owner.Value
                        local touchPart = mainDoor.WorkingParts:FindFirstChild("TouchToEnter")

                       if ownerName and ownerName ~= "" and touchPart then
                            addedOwners[ownerName] = true
                            HouseTypeCache[ownerName] = houseModel.Name -- Запоминаем в память
                            
                            table.insert(houses, {
                                Owner = ownerName,
                                HouseType = houseModel.Name,
                                DoorPart = touchPart
                            })
                        end
                    end
                end
            end
        end

        -- 2. Проходим по ВСЕМ игрокам сервера, чтобы никто не потерялся
        local success, clientDataModule = pcall(function() return getgenv().DuskCore.M.ClientData end)
        local allData = success and clientDataModule and type(clientDataModule.get_data) == "function" and clientDataModule.get_data()

        for _, p in ipairs(Players:GetPlayers()) do
            if not addedOwners[p.Name] then
                addedOwners[p.Name] = true
                
                -- Ищем тип дома: сначала в физическом кэше, потом в профиле, иначе nil (Not Found)
                local hType = HouseTypeCache[p.Name]
                
                if not hType and allData and allData[p.Name] and allData[p.Name].house_exterior_model then
                    hType = allData[p.Name].house_exterior_model
                    HouseTypeCache[p.Name] = hType
                end

                table.insert(houses, {
                    Owner = p.Name,
                    HouseType = hType, -- Если nil, то сработает плашка Not Found
                    DoorPart = nil
                })
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

    local function createHouseCard(houseData, index)
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
            BackgroundTransparency = 1,
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

        local displayHouse, houseSize, centerPos = nil, nil, nil
        
        if houseData.HouseType then
            displayHouse, houseSize, centerPos = buildCleanPreview(houseData.HouseType, Viewport)
        end

        -- Если модель дома не найдена ни в мире, ни в кэше — рисуем четкую надпись Not Found
        if not displayHouse then
            local NotFoundLbl = Library.Utils.Make("TextLabel", {
                Text = "Not Found",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextSize, 14,
                TextColor3 = "SubText",
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 5,
                Parent = Viewport
            })
            -- Защита от старых багов цвета текста
            NotFoundLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
        else
            local VpCamera = Instance.new("Camera")
            VpCamera.FieldOfView = 50 
            Viewport.CurrentCamera = VpCamera
            VpCamera.Parent = Viewport

            local radius = houseSize.Magnitude / 2
            local distance = (radius / math.tan(math.rad(VpCamera.FieldOfView / 2))) * 1.1

            local angle = 0
            local renderConn 
            renderConn = RunService.RenderStepped:Connect(function(dt)
                if not Viewport.Parent then 
                    if renderConn then renderConn:Disconnect() end 
                    return 
                end
                angle = angle + math.rad(25 * dt)
                local camPos = centerPos + Vector3.new(math.cos(angle) * distance * 0.8, distance * 0.4, math.sin(angle) * distance * 0.8)
                VpCamera.CFrame = CFrame.lookAt(camPos, centerPos)
            end)
        end

        local Avatar = Library.Utils.Make("ImageLabel", {
            Size = UDim2.new(0, 28, 0, 28), 
            Position = UDim2.new(0, 14, 1, -8), 
            AnchorPoint = Vector2.new(0, 1), 
            BackgroundTransparency = 1, 
            ZIndex = 4, 
            Parent = Tile
        })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Avatar})
        Library.Utils.Make("UIStroke", {Thickness = 2, Parent = Avatar}, {Color = "Section"}) 
        applyAvatar(Avatar, houseData.Owner, index) 

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
        end)

        Library:Connect(Tile.MouseLeave, function()
            Library.Utils.TBT(AccentLine, 0.3, {Size = UDim2.new(0.35, 0, 0, 3)})
        end)

        Library:Connect(Tile.MouseButton1Down, function() 
            Library.Utils.TBT(Scale, 0.1, {Scale = 0.96}) 
        end)

        -- 2. ТЕЛЕПОРТ ИЗ ЛЮБОЙ ТОЧКИ КАРТЫ
        Library:Connect(Tile.MouseButton1Click, function()
            Library.Utils.TBT(Scale, 0.15, {Scale = 1}, Enum.EasingStyle.Bounce)
            Library.Utils.CreateRipple(RippleContainer)

            local targetPlayer = Players:FindFirstChild(houseData.Owner)
            
            if not targetPlayer then
                if Library.Notify then Library:Notify("Error", "Player is no longer in the server!", 3, "rbxassetid://73186275216515", "rbxassetid://72958619361915") end
                return
            end

            if Library.Notify then 
                Library:Notify("Teleport", "Entering " .. houseData.Owner .. "'s house...", 3, "rbxassetid://91727514118912", "rbxassetid://72958619361915") 
            end

            task.spawn(function()
                local DuskCore = getgenv().DuskCore
                local API = DuskCore.API
                local clientDataModule = DuskCore.M.ClientData
                
                -- Выходим из текущего дома, если находимся внутри
                local currentLoc = clientDataModule.get("location_id")
                if currentLoc == "housing" then
                    pcall(function() API.UnsubscribeFromHouse:InvokeServer(LocalPlayer) end)
                end
                
                -- Задаем маршрут
                pcall(function() API.SetLocation:FireServer("Neighborhood") end)
                task.wait(0.5)
                
                local set_identity = (syn and syn.set_thread_identity) or setthreadidentity or setidentity
                local get_identity = (syn and syn.get_thread_identity) or getthreadidentity or getidentity

                local current_id = get_identity and get_identity() or 7
                
                -- Форсируем родной телепорт игры
                pcall(function() 
                    if set_identity then pcall(set_identity, 2) end
                    
                    local InteriorsM = require(ReplicatedStorage.ClientModules.Core.InteriorsM.InteriorsM)
                    InteriorsM.enter_smooth("housing", "MainDoor", {
                        ["house_owner"] = targetPlayer
                    }) 
                end)
                
                if set_identity then pcall(set_identity, current_id) end
            end)
        end)
    end

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

        if not success then warn("[Dusk&Shine Teleport] Render error: ", err) end
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
        table.insert(Library.Connections, workspaceExteriors.DescendantAdded:Connect(function(descendant)
            if descendant.Parent and descendant.Parent.Parent == workspaceExteriors then
                queueRefresh()
            end
        end))

        table.insert(Library.Connections, workspaceExteriors.DescendantRemoving:Connect(function(descendant)
            if descendant.Parent and descendant.Parent.Parent == workspaceExteriors then
                queueRefresh()
            end
        end))
    end

   table.insert(Library.Connections, Players.PlayerRemoving:Connect(queueRefresh))
end

return Module
