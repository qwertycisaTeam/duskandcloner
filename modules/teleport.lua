local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Module = {}

function Module:Init(Library, Window, Tab)
    -- Оборачиваем весь процесс в отдельный поток, чтобы не вешать надпись "Loading..." в меню
    task.spawn(function()
        -- pcall перехватит любые ошибки (если нужная папка не прогрузилась) и не даст меню сломаться
        local success, err = pcall(function()
            
            -- ==========================================
            -- ФУНКЦИИ ВНУТРИ ПОТОКА
            -- ==========================================
            local function applyAvatar(imageLabel, username)
                task.spawn(function()
                    local s, userId = pcall(function() return Players:GetUserIdFromNameAsync(username) end)
                    if s and userId then
                        local content = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
                        imageLabel.Image = content
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
                        if displayHouse.PrimaryPart and dome.PrimaryPart then
                            displayHouse:PivotTo(dome.PrimaryPart.CFrame * CFrame.new(0, 1, 0))
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
            -- СОЗДАНИЕ ИНТЕРФЕЙСА
            -- ==========================================
            local ScrollContainer = Instance.new("ScrollingFrame")
            ScrollContainer.Name = "TeleportScroll"
            ScrollContainer.Size = UDim2.new(1, 0, 1, -10)
            ScrollContainer.Position = UDim2.new(0, 0, 0, 5)
            ScrollContainer.BackgroundTransparency = 1
            ScrollContainer.ScrollBarThickness = 3
            ScrollContainer.Parent = Tab.Page

            local GridLayout = Instance.new("UIGridLayout")
            GridLayout.CellSize = UDim2.new(0, 155, 0, 175)
            GridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
            GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
            GridLayout.Parent = ScrollContainer
            
            local Padding = Instance.new("UIPadding")
            Padding.PaddingTop = UDim.new(0, 5)
            Padding.PaddingLeft = UDim.new(0, 5)
            Padding.Parent = ScrollContainer

            -- Определяем акцентный цвет из библиотеки (или ставим синий по дефолту)
            local AccentColor = Library.CurrentTheme and Library.CurrentTheme.Accent or Color3.fromRGB(85, 170, 255)

            local function createHouseCard(houseData)
                local Card = Instance.new("Frame")
                Card.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                Card.Parent = ScrollContainer
                Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 10)

                local Accent = Instance.new("Frame")
                Accent.Size = UDim2.new(1, 0, 0, 4)
                Accent.BackgroundColor3 = AccentColor
                Accent.BorderSizePixel = 0
                Accent.Parent = Card
                Instance.new("UICorner", Accent).CornerRadius = UDim.new(0, 10)

                local Viewport = Instance.new("ViewportFrame")
                Viewport.Size = UDim2.new(1, -10, 0, 110)
                Viewport.Position = UDim2.new(0, 5, 0, 10)
                Viewport.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
                Viewport.Parent = Card
                Instance.new("UICorner", Viewport).CornerRadius = UDim.new(0, 8)

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

                local Avatar = Instance.new("ImageLabel")
                Avatar.Size = UDim2.new(0, 32, 0, 32)
                Avatar.Position = UDim2.new(0, 8, 1, -40)
                Avatar.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
                Avatar.Parent = Card
                Instance.new("UICorner", Avatar).CornerRadius = UDim.new(1, 0)
                applyAvatar(Avatar, houseData.Owner)

                local NameText = Instance.new("TextLabel")
                NameText.Size = UDim2.new(1, -55, 0, 32)
                NameText.Position = UDim2.new(0, 48, 1, -40)
                NameText.BackgroundTransparency = 1
                NameText.Text = houseData.Owner
                NameText.TextColor3 = Color3.fromRGB(255, 255, 255)
                NameText.TextXAlignment = Enum.TextXAlignment.Left
                NameText.Font = Enum.Font.GothamMedium
                NameText.TextSize = 13
                NameText.TextTruncate = Enum.TextTruncate.AtEnd
                NameText.Parent = Card

                local TeleportBtn = Instance.new("TextButton")
                TeleportBtn.Size = UDim2.new(1, 0, 1, 0)
                TeleportBtn.BackgroundTransparency = 1
                TeleportBtn.Text = ""
                TeleportBtn.Parent = Card

                TeleportBtn.MouseButton1Click:Connect(function()
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = houseData.TeleportCFrame
                        if Library.Notify then
                            Library:Notify("Телепорт", "Перемещаемся к дому " .. houseData.Owner, 2)
                        end
                    end
                end)
            end

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

            GridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, GridLayout.AbsoluteContentSize.Y + 20)
            end)

        end)
        
        -- Если внутри вкладки всё же произошла какая-то ошибка, скрипт не умрет тихо,
        -- а покажет тебе красивое уведомление из твоей библиотеки!
        if not success then
            warn("[Клонер] Ошибка при рендере вкладки Teleport:", err)
            if Library and Library.Notify then
                Library:Notify("Ошибка Вкладки", "Загляни в консоль (F9)", 5)
            end
        end
    end)
end

return Module
