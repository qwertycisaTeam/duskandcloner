local Module = {}

function Module:Init(Library, Window, Tab)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local TweenService = game:GetService("TweenService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Screen = PlayerGui:WaitForChild("DuskShine_Mega", 10)

    -- ==========================================
    -- АВТО-КАЛИБРОВКА (ПЕРВЫЙ ЗАПУСК)
    -- ==========================================
    if not getgenv().UIScaleSize then
        local camera = workspace.CurrentCamera
        local screenWidth = camera and camera.ViewportSize.X or 1920
        getgenv().UIScaleSize = math.clamp(math.floor((screenWidth / 1920) * 100), 45, 100)
        if getgenv().SaveConfig then pcall(getgenv().SaveConfig) end
    end

    -- ==========================================
    -- ДВИЖОК ЧАСТИЦ
    -- ==========================================
    local ParticleFrame = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 1, 
        ClipsDescendants = true, Parent = Window.MainFrame
    })

    local function SpawnParticle()
        if not getgenv().MenuParticlesEnabled then return end

        local pType = getgenv().ParticleType or "Old Vanilla"
        local p
        local fallTime = math.random(4, 8)
        local rotSpeed = math.random(-40, 40)

        if pType == "Old Vanilla" then
            p = Instance.new("Frame")
            p.BackgroundColor3 = Color3.new(1, 1, 1)
            p.BorderSizePixel = 0
            p.Size = UDim2.new(0, math.random(3, 6), 0, math.random(3, 6))

        elseif pType == "Snow" then
            p = Instance.new("Frame")
            p.BackgroundColor3 = Color3.new(1, 1, 1)
            p.BorderSizePixel = 0
            local s = math.random(4, 9)
            p.Size = UDim2.new(0, s, 0, s)
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = p})

        elseif pType == "Bubbles" then
            p = Instance.new("Frame")
            p.BackgroundTransparency = 1
            p.BorderSizePixel = 0
            local s = math.random(8, 16)
            p.Size = UDim2.new(0, s, 0, s)
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = p})
            local stroke = Instance.new("UIStroke", p)
            stroke.Color = Color3.new(1, 1, 1)
            stroke.Thickness = 1.2

        elseif pType == "Sakura Petals" then
            p = Instance.new("Frame")
            p.BackgroundColor3 = Color3.fromRGB(255, 183, 197)
            p.BorderSizePixel = 0
            p.Size = UDim2.new(0, math.random(5, 10), 0, math.random(4, 7))
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0.5, 0), Parent = p})

        elseif pType == "Stars" then
            p = Instance.new("ImageLabel")
            p.BackgroundTransparency = 1
            p.Image = "rbxassetid://6031225815"
            p.Size = UDim2.new(0, math.random(12, 20), 0, math.random(12, 20))
            if Library.CurrentTheme then p.ImageColor3 = Library.CurrentTheme.Accent end
        end

        p.ZIndex = 1
        p.Position = UDim2.new(math.random(), 0, -0.1, 0)
        p.Rotation = math.random(0, 360)
        p.Parent = ParticleFrame

        local targetProps = {
            Position = UDim2.new(p.Position.X.Scale, 0, 1.1, 0),
            Rotation = p.Rotation + (rotSpeed * fallTime)
        }

        if pType == "Bubbles" then
            local stroke = p:FindFirstChildOfClass("UIStroke")
            if stroke then 
                stroke.Transparency = math.random(2, 6) / 10
                TweenService:Create(stroke, TweenInfo.new(fallTime, Enum.EasingStyle.Linear), {Transparency = 1}):Play() 
            end
        elseif pType == "Stars" then
            p.ImageTransparency = math.random(2, 6) / 10
            targetProps.ImageTransparency = 1 
        else
            p.BackgroundTransparency = math.random(2, 6) / 10
            targetProps.BackgroundTransparency = 1
        end

        local t = TweenService:Create(p, TweenInfo.new(fallTime, Enum.EasingStyle.Linear), targetProps)
        t:Play()
        t.Completed:Connect(function() p:Destroy() end)
    end

    task.spawn(function()
        while task.wait(0.15) do
            if not getgenv().DuskShine_Core or getgenv().DS_StopExecution then 
                break 
            end
            if Window.MainFrame.Visible then SpawnParticle() end
        end
    end)

    -- ==========================================
    -- UI SETTINGS
    -- ==========================================
    Tab:CreateDivider({ Text = "UI Settings & Particles" })

    Tab:CreateToggle({
        Name = "Menu Particles",
        Description = "Falling effects in the background of the menu.",
        Flag = "MenuParticlesEnabled",
        Default = getgenv().MenuParticlesEnabled or false,
        Callback = function(state)
            getgenv().MenuParticlesEnabled = state
        end
    })
--===================
    local ParticlePickerContainer = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, 0, 0, 75),
        Parent = Tab.Page  -- Исправили с Page на Tab.Page
    }, { BackgroundColor3 = "Section" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 10), Parent = ParticlePickerContainer })
    Library.Utils.Make("UIStroke", { Thickness = 1, Parent = ParticlePickerContainer }, { Color = "Stroke" })

    Library.Utils.Make("TextLabel", {
        Text = "PARTICLE STYLE PREVIEW",
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 15, 0, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        Parent = ParticlePickerContainer
    }, { TextColor3 = "SubText" })

    local GridFrame = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, -20, 0, 36),
        Position = UDim2.new(0, 10, 0, 30),
        BackgroundTransparency = 1,
        Parent = ParticlePickerContainer
    })
    
    Library.Utils.Make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 8),
        Parent = GridFrame
    })

    local particleTypes = {"Old Vanilla", "Stars", "Snow", "Sakura Petals", "Bubbles"}
    local cardStrokes = {}

    for _, pType in ipairs(particleTypes) do
        local Tile = Library.Utils.Make("TextButton", {
            Size = UDim2.new(0, 36, 0, 36),
            Text = "",
            AutoButtonColor = false,
            ClipsDescendants = true,
            Parent = GridFrame
        }, { BackgroundColor3 = "Sidebar" })
        
        Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Tile })
        local tStroke = Library.Utils.Make("UIStroke", { Thickness = 1.5, Parent = Tile }, { Color = "Stroke" })
        cardStrokes[pType] = tStroke

        task.spawn(function()
            while Tile and Tile.Parent do
                if getgenv().MenuParticlesEnabled and (getgenv().ParticleType == pType) then
                    local p = Instance.new("Frame")
                    p.Size = UDim2.new(0, 3, 0, 3)
                    p.Position = UDim2.new(math.random(), 0, 0, 0)
                    p.BackgroundColor3 = Color3.new(1, 1, 1)
                    p.BorderSizePixel = 0
                    p.Parent = Tile
                    
                    if pType == "Stars" then
                        p.BackgroundColor3 = Library.CurrentTheme.Accent
                    elseif pType == "Sakura Petals" then
                        p.BackgroundColor3 = Color3.fromRGB(255, 183, 197)
                    end

                    TweenService:Create(p, TweenInfo.new(1.2, Enum.EasingStyle.Linear), {
                        Position = UDim2.new(p.Position.X.Scale, math.random(-10, 10), 1, 5),
                        BackgroundTransparency = 1
                    }):Play()

                    task.delay(1.2, function() if p then p:Destroy() end end)
                end
                task.wait(0.3)
            end
        end)

        Library:Connect(Tile.MouseButton1Click, function()
            getgenv().ParticleType = pType
            for name, stroke in pairs(cardStrokes) do
                stroke.Color = (name == pType) and Library.CurrentTheme.Accent or Library.CurrentTheme.Stroke
                stroke.Thickness = (name == pType) and 2.5 or 1.5
            end
        end)
    end
    Tab:CreateDropdown({
        Name = "Minimize Button Style",
        Options = {"Top Bar", "Floating Logo"},
        Default = Library.Settings.CloserType or "Top Bar",
        Flag = "CloserType",
        Callback = function(val)
            Library.Settings.CloserType = val
            getgenv().CloserType = val
        end
    })

    Tab:CreateUIXPanel({
        Min = 25, Max = 100,
        DefaultScale = getgenv().UIScaleSize or 50,
        ScaleFlag = "UIScaleSize",
        ScaleCallback = function(val)
            getgenv().UIScaleSize = val
            local UIScaleObj = Screen and Screen:FindFirstChildOfClass("UIScale")
            if UIScaleObj then UIScaleObj.Scale = val / 100 end
        end,

        DefaultColor = Library.CurrentTheme.Accent or Color3.fromRGB(255, 255, 255),
        ColorFlag = "ThemeAccent",
        ColorCallback = function(col)
            Library.CurrentTheme.Accent = col
            Library.Themes.Dark.Accent = col
            Library.Themes.Light.Accent = col

            for element, props in pairs(Library.ThemeObjects) do
                if element and element.Parent then
                    for propName, themeKey in pairs(props) do
                        if themeKey == "Accent" then
                            TweenService:Create(element, TweenInfo.new(0.3), {[propName] = col}):Play()
                            local grad = element:FindFirstChild("DuskShine_Gradient")
                            if grad then
                                local glow = Color3.new(math.clamp(col.R + 0.35, 0, 1), math.clamp(col.G + 0.35, 0, 1), math.clamp(col.B + 0.35, 0, 1))
                                grad.Color = ColorSequence.new({
                                    ColorSequenceKeypoint.new(0, col),
                                    ColorSequenceKeypoint.new(0.5, glow),
                                    ColorSequenceKeypoint.new(1, col)
                                })
                            end
                        end
                    end
                end
            end
        end
    })

    local Lighting = game:GetService("Lighting")
    local DuskBlur = Lighting:FindFirstChild("DuskMenuBlur") or Instance.new("BlurEffect", Lighting)
    DuskBlur.Name = "DuskMenuBlur"
    DuskBlur.Size = 0
    DuskBlur.Enabled = false

    Window.MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
        if getgenv().MenuBlurEnabled then
            if Window.MainFrame.Visible then
                DuskBlur.Enabled = true
                TweenService:Create(DuskBlur, TweenInfo.new(0.3), {Size = 24}):Play()
            else
                local t = TweenService:Create(DuskBlur, TweenInfo.new(0.3), {Size = 0})
                t:Play()
                t.Completed:Connect(function() DuskBlur.Enabled = false end)
            end
        end
    end)

    Tab:CreateToggle({
        Name = "Menu Blur",
        Description = "Blur background when menu is open.",
        Flag = "MenuBlurEnabled",
        Default = getgenv().MenuBlurEnabled or false,
        Callback = function(state)
            getgenv().MenuBlurEnabled = state
            if state and Window.MainFrame.Visible then
                DuskBlur.Enabled = true
                TweenService:Create(DuskBlur, TweenInfo.new(0.3), {Size = 24}):Play()
            elseif not state then
                local t = TweenService:Create(DuskBlur, TweenInfo.new(0.3), {Size = 0})
                t:Play()
                t.Completed:Connect(function() DuskBlur.Enabled = false end)
            end
        end
    })

    -- ==========================================
    -- GLOBAL SETTINGS
    -- ==========================================
    Tab:CreateDivider({ Text = "Global Settings" })

    Tab:CreateToggle({
        Name = "Auto-Update Kicker",
        Description = "Kicks you from the server if a new script version is found.",
        Flag = "AutoUpdateKicker",
        Default = getgenv().AutoUpdateKicker or false,
        Callback = function(state)
            getgenv().AutoUpdateKicker = state
        end
    })

    Tab:CreateToggle({
        Name = "Anonymous Mode",
        Description = "Hides your identity to prevent streaming snipes.",
        Flag = "AnonymousMode",
        Default = getgenv().AnonymousMode or false,
        Callback = function(state)
            getgenv().AnonymousMode = state
            Library.Settings.AnonymousMode = state

            for _, avatarData in ipairs(Library.AnonItems.Avatars) do
                if state then
                    avatarData.ImageObj.ImageTransparency = 1
                    avatarData.ImageObj.BackgroundTransparency = 0
                    avatarData.ImageObj.BackgroundColor3 = Color3.new(0,0,0)
                    avatarData.Letter.Visible = true
                else
                    avatarData.ImageObj.ImageTransparency = 0
                    avatarData.ImageObj.BackgroundTransparency = 1
                    avatarData.Letter.Visible = false
                end
            end

            for _, nameData in ipairs(Library.AnonItems.Names) do
                nameData.Obj.Text = string.format(nameData.Format, state and "Hidden User" or LocalPlayer.DisplayName)
            end
        end
    })

    Tab:CreateKeybind({
        Name = "Toggle Menu Key",
        Default = getgenv().ToggleUIKey or Enum.KeyCode.RightControl,
        Flag = "ToggleUIKey",
        Callback = function(key)
            getgenv().ToggleUIKey = key
        end
    })

    table.insert(Library.Connections, game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == getgenv().ToggleUIKey then
            task.spawn(function()
                if Window.ToggleMenu then Window:ToggleMenu() end
            end)
        end
    end))

    -- ==========================================
    -- PERFORMANCE
    -- ==========================================
    Tab:CreateDivider({ Text = "Performance" })

    Tab:CreateSlider({
        Name = "FPS Limit (0 = Uncapped)",
        Min = 0, Max = 120,
        Default = getgenv().FPSLimit or 0,
        Flag = "FPSLimit",
        Callback = function(val)
            getgenv().FPSLimit = val
            if not getgenv().EcoModeEnabled and setfpscap then
                pcall(function() setfpscap(val) end)
            end
        end
    })

    Tab:CreateToggle({
        Name = "Extreme Performance (NoRender)",
        Description = "Kills 3D rendering, shadows, and textures for MAX FPS.",
        Flag = "PerformanceModeEnabled",
        Default = getgenv().PerformanceModeEnabled or false,
        Callback = function(state)
            getgenv().PerformanceModeEnabled = state

            local Terrain = workspace:FindFirstChildOfClass("Terrain")

            if state then
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 9e9
                Lighting.ShadowSoftness = 0
                Lighting.Brightness = 0
                if Terrain then
                    Terrain.WaterWaveSize = 0
                    Terrain.WaterWaveSpeed = 0
                    Terrain.WaterReflectance = 0
                    Terrain.WaterTransparency = 0
                end
                pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
            else
                Lighting.GlobalShadows = true
                Lighting.Brightness = 1
                pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
            end
        end
    })

end

return Module
