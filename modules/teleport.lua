local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Module = {}

function Module:Init(Library, Window, Tab)

    -- ==========================================
    -- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
    -- ==========================================
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
                
                local domeCFrame, domeSize = dome:GetBoundingBox()
                local houseCFrame, houseSize = displayHouse:GetBoundingBox()
                
                -- ИСПРАВЛЕНА ОПЕЧАТКА ЗДЕСЬ
                local maxHouseWidth = math.max(houseSize.X, houseSize.Z)
                local scaleFactor = (domeSize.X * 0.65) / maxHouseWidth
                
                if (houseSize.Y * scaleFactor) > (domeSize.X * 0.8) then
                    scaleFactor = (domeSize.X * 0.8) / houseSize.Y
                end
                
                displayHouse:ScaleTo(scaleFactor)
                local newHouseCFrame, newHouseSize = displayHouse:GetBoundingBox()
                local yOffset = (domeSize.Y / 2) + (newHouseSize.Y / 2) - 0.5
                displayHouse:PivotTo(domeCFrame * CFrame.new(0, yOffset, 0))
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
        CellSize = UDim2.new(0.48, 0, 0, 155), 
        CellPadding = UDim2.new(0.04, 0, 0, 15), 
        SortOrder = Enum.SortOrder.LayoutOrder, 
        Parent = Container 
    })

    local function createHouseCard(houseData)
        local Tile = Library.Utils.Make("TextButton", { Text = "", AutoButtonColor = false, ClipsDescendants = false, Parent = Container }, { BackgroundColor3 = "Section" })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 14), Parent = Tile})
        Library.Utils.Make("UIStroke", {Thickness = 1, Transparency = 0.6, Parent = Tile}, {Color = "Stroke"})
        
        Library.Utils.Make("UIPadding", { 
            PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), 
            PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), 
            Parent = Tile 
        })

        local RippleContainer = Library.Utils.Make("Frame", { Size = UDim2.new(1, 16, 1, 16), Position = UDim2.new(0, -8, 0, -8), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 10, Parent = Tile })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 14), Parent = RippleContainer})

        local Viewport = Library.Utils.Make("ViewportFrame", {
            Size = UDim2.new(1, 0, 1, -38), 
            Position = UDim2.new(0, 0, 0, 0), 
            BackgroundColor3 = Color3.fromRGB(20, 20, 25), 
            BorderSizePixel = 0,
            ZIndex = 1, 
            Parent = Tile
        })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 10), Parent = Viewport})
        Library.Utils.Make("UIStroke", {Thickness = 1, Transparency = 0.8, Parent = Viewport}, {Color = "Stroke"})

        local GradFrame = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0.4, 0), Position = UDim2.new(0, 0, 1, 0), AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = Viewport })
        local Grad = Instance.new("UIGradient")
        Grad.Rotation = 90
        Grad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.1)})
        Grad.Color = ColorSequence.new(Color3.new(0,0,0))
        Grad.Parent = GradFrame

        local AccentLine = Library.Utils.Make("Frame", { 
            Size = UDim2.new(0.3, 0, 0, 3), 
            Position = UDim2.new(1, -6, 1, -6), 
            AnchorPoint = Vector2.new(1, 1), 
            BorderSizePixel = 0, 
            ZIndex = 5, 
            Parent = Viewport 
        }, { BackgroundColor3 = "Accent" })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = AccentLine})

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

        local Avatar = Library.Utils.Make("ImageLabel", {
            Size = UDim2.new(0, 30, 0, 30), 
            Position = UDim2.new(0, 0, 1, 0), 
            AnchorPoint = Vector2.new(0, 1), 
            BackgroundColor3 = Color3.fromRGB(30, 30, 35), 
            BackgroundTransparency = 0, 
            ZIndex = 3, 
            Parent = Tile
        })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Avatar})
        Library.Utils.Make("UIStroke", {Thickness = 1, Transparency = 0.6, Parent = Avatar}, {Color = "Stroke"})
        applyAvatar(Avatar, houseData.Owner)

        local NameLbl = Library.Utils.Make("TextLabel", { 
            Text = houseData.Owner, 
            Size = UDim2.new(1, -38, 0, 30), 
            Position = UDim2.new(0, 38, 1, 0), 
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
            Library.Utils.TBT(AccentLine, 0.3, {Size = UDim2.new(0.8, 0, 0, 3)})
            Library.Utils.TBT(Viewport, 0.3, {BackgroundColor3 = Color3.fromRGB(25, 25, 30)})
        end)

        Library:Connect(Tile.MouseLeave, function()
            Library.Utils.TBT(AccentLine, 0.3, {Size = UDim2.new(0.3, 0, 0, 3)})
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
        
        -- Если опять случится что-то не так, мы это хотя бы увидим
        if not success then
            warn("[Dusk&Shine Teleport] Ошибка рендера вкладки: ", err)
        end
    end)
end

return Module
