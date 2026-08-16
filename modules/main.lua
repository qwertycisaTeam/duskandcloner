local Module = {}

function Module:Init(Library, Window, Tab)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local TweenService = game:GetService("TweenService")
    local Screen = PlayerGui:WaitForChild("DuskShine_Mega", 10)

    -- ==========================================
    -- УМНОЕ АВТО-СОХРАНЕНИЕ (Без лагов и спама)
    -- ==========================================
    local saveTick = 0
    local function AutoSave()
        saveTick = tick()
        local currentTick = saveTick
        
        -- Ждем полсекунды. Если за это время функцию вызвали еще раз
        -- (например, при перетаскивании ползунка), старый вызов отменится.
        task.delay(0.5, function()
            if saveTick == currentTick then
                if Library and type(Library.SaveConfig) == "function" then
                    Library:SaveConfig("DuskShine_Settings")
                end
            end
        end)
    end

    -- ==========================================
    -- АВТО-КАЛИБРОВКА (ПЕРВЫЙ ЗАПУСК)
    -- ==========================================
    if not getgenv().UIScaleSize then
        local camera = workspace.CurrentCamera
        local screenWidth = camera and camera.ViewportSize.X or 1920
        getgenv().UIScaleSize = math.clamp(math.floor((screenWidth / 1920) * 100), 45, 100)
        AutoSave()
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
            if Window.MainFrame.Visible then SpawnParticle() end
        end
    end)

    -- ==========================================
    -- UI SETTINGS
    -- ==========================================
    Tab:CreateSection({ Name = "UI Settings & Particles" })

    Tab:CreateToggle({
        Name = "Menu Particles",
        Description = "Falling effects in the background\nof the menu.",
        Flag = "MenuParticlesEnabled",
        Default = getgenv().MenuParticlesEnabled or false,
        Callback = function(state)
            getgenv().MenuParticlesEnabled = state
            AutoSave()
        end
    })

    Tab:CreateDropdown({
        Name = "Particle Style",
        Options = {"Old Vanilla", "Stars", "Snow", "Sakura Petals", "Bubbles"},
        Default = getgenv().ParticleType or "Old Vanilla",
        Flag = "ParticleType",
        Callback = function(val)
            getgenv().ParticleType = val
            AutoSave()
        end
    })

    Tab:CreateDropdown({
        Name = "Minimize Button Style",
        Options = {"Top Bar", "Floating Logo"},
        Default = Library.Settings.CloserType or "Top Bar",
        Flag = "CloserType",
        Callback = function(val)
            Library.Settings.CloserType = val
            getgenv().CloserType = val
            AutoSave()
        end
    })

    Tab:CreateSlider({
        Name = "UI Scale (%)",
        Min = 25, Max = 100,
        Default = getgenv().UIScaleSize or 50,
        Flag = "UIScaleSize",
        Callback = function(val)
            getgenv().UIScaleSize = val
            local UIScaleObj = Screen and Screen:FindFirstChildOfClass("UIScale")
            if UIScaleObj then UIScaleObj.Scale = val / 100 end
            AutoSave()
        end
    })

    Tab:CreateColorPicker({
        Name = "UI Accent Color",
        Default = Library.CurrentTheme.Accent or Color3.fromRGB(255, 255, 255),
        Flag = "ThemeAccent",
        Callback = function(col)
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
            AutoSave()
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
            AutoSave()
        end
    })

    -- ==========================================
    -- GLOBAL SETTINGS
    -- ==========================================
    Tab:CreateSection({ Name = "Global Settings" })

    Tab:CreateToggle({
        Name = "Auto-Update Kicker",
        Description = "Kicks you from the server if a\nnew script version is found.",
        Flag = "AutoUpdateKicker",
        Default = getgenv().AutoUpdateKicker or false,
        Callback = function(state)
            getgenv().AutoUpdateKicker = state
            AutoSave()
        end
    })

    Tab:CreateToggle({
        Name = "Anonymous Mode",
        Description = "Hides your identity to prevent\nstreaming snipes.",
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
            
            AutoSave()
        end
    })

    Tab:CreateKeybind({
        Name = "Toggle Menu Key",
        Default = getgenv().ToggleUIKey or Enum.KeyCode.RightControl,
        Flag = "ToggleUIKey",
        Callback = function(key)
            getgenv().ToggleUIKey = key
            AutoSave()
        end
    })

    -- ==========================================
    -- ФИКС КРАША (ЧИСТЫЙ БИНД ЧЕРЕЗ ФУНКЦИЮ ЛИБЫ)
    -- ==========================================
    table.insert(Library.Connections, game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == getgenv().ToggleUIKey then
            task.spawn(function()
                if Window.ToggleMenu then
                    Window:ToggleMenu()
                end
            end)
        end
    end))

    -- ==========================================
    -- PERFORMANCE
    -- ==========================================
    Tab:CreateSection({ Name = "Performance" })

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
            AutoSave()
        end
    })

    Tab:CreateToggle({
        Name = "Extreme Performance (NoRender)",
        Description = "Kills 3D rendering, shadows,\nand textures for MAX FPS.",
        Flag = "PerformanceModeEnabled",
        Default = getgenv().PerformanceModeEnabled or false,
        Callback = function(state)
            getgenv().PerformanceModeEnabled = state
            
            local Lighting = game:GetService("Lighting")
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
            AutoSave()
        end
    })

    -- ==========================================
    -- АВТО-УЛУЧШЕНИЕ ИНТЕРФЕЙСА (Дропдауны и Тогглы)
    -- ==========================================
    task.spawn(function()
        task.wait(0.2) 
        for _, frame in ipairs(Tab.Page:GetChildren()) do
            
            -- ПРОКАЧКА ДРОПДАУНОВ 
            if frame:IsA("Frame") and frame.Size == UDim2.new(1, 0, 0, 40) then 
                local btn = frame:FindFirstChildWhichIsA("TextButton")
                if btn then
                    -- Удален хардкод цвета фона, чтобы он адаптировался под тему!
                    btn.BackgroundColor3 = Library.CurrentTheme.Sidebar
                    Library.ThemeObjects[btn] = { BackgroundColor3 = "Sidebar" }
                    
                    -- Динамическая обводка, привязанная к теме
                    local stroke = btn:FindFirstChildWhichIsA("UIStroke") or Instance.new("UIStroke", btn)
                    stroke.Thickness = 1
                    stroke.Transparency = 0.4
                    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    Library.ThemeObjects[stroke] = { Color = "Stroke" }
                    stroke.Color = Library.CurrentTheme.Stroke
                    
                    -- Универсальная тень снизу (полупрозрачная, смотрится на любой теме)
                    if not btn:FindFirstChild("DepthGlow") then
                        local depth = Instance.new("Frame", btn)
                        depth.Name = "DepthGlow"
                        depth.Size = UDim2.new(1, 0, 0, 3)
                        depth.Position = UDim2.new(0, 0, 1, -3)
                        depth.BackgroundColor3 = Color3.new(0, 0, 0)
                        depth.BackgroundTransparency = 0.6 -- Универсальная прозрачность
                        depth.BorderSizePixel = 0
                        local dc = Instance.new("UICorner", depth)
                        dc.CornerRadius = UDim.new(0, 6)
                    end
                    
                    -- Динамическая стрелочка, привязанная к тексту темы
                    if not btn:FindFirstChild("DropArrow") then
                        local arrow = Instance.new("ImageLabel", btn)
                        arrow.Name = "DropArrow"
                        arrow.Size = UDim2.new(0, 14, 0, 14)
                        arrow.Position = UDim2.new(1, -10, 0.5, 0)
                        arrow.AnchorPoint = Vector2.new(1, 0.5)
                        arrow.BackgroundTransparency = 1
                        arrow.Image = "rbxassetid://6031091004"
                        Library.ThemeObjects[arrow] = { ImageColor3 = "SubText" }
                        arrow.ImageColor3 = Library.CurrentTheme.SubText
                    end
                end
            end
            
            -- ФИКС ТЕКСТА В ТОГГЛАХ
            if frame:IsA("Frame") and frame.Size == UDim2.new(1, 0, 0, 70) then
                for _, child in ipairs(frame:GetChildren()) do
                    if child:IsA("TextLabel") and child.TextSize == 13 then
                        child.TextWrapped = true
                        child.Size = UDim2.new(1, -75, 0, 28) 
                        child.TextYAlignment = Enum.TextYAlignment.Top
                    end
                end
            end
            
        end
    end)
end

return Module
