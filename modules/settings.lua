local Module = {}

function Module:Init(Library, Window, Tab)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local TweenService = game:GetService("TweenService")
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

        local targetProps = { Position = UDim2.new(p.Position.X.Scale, 0, 1.1, 0), Rotation = p.Rotation + (rotSpeed * fallTime) }

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
            if not getgenv().DuskShine_Core or getgenv().DS_StopExecution then break end
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
        Callback = function(state) getgenv().MenuParticlesEnabled = state end
    })

    local ParticlePickerContainer = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0, 70), Parent = Tab.Page }, { BackgroundColor3 = "Section" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 10), Parent = ParticlePickerContainer })
    Library.Utils.Make("UIStroke", { Thickness = 1, Parent = ParticlePickerContainer }, { Color = "Stroke" })

    local GridHolder = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = ParticlePickerContainer })
    Library.Utils.Make("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = GridHolder })
    Library.Utils.Make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = GridHolder })

    local particleTypes = {"Old Vanilla", "Stars", "Snow", "Sakura Petals", "Bubbles"}
    local particleTiles = {}

    for i, pType in ipairs(particleTypes) do
        local isSelected = (getgenv().ParticleType == pType)
        
        -- Pet Pen Style Градиентная обводка
        local OuterGlow = Library.Utils.Make("Frame", { Size = UDim2.new(0.2, -7, 1, 0), LayoutOrder = i, BackgroundTransparency = isSelected and 0 or 1, Parent = GridHolder })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 10), Parent = OuterGlow})
        
        local GlowGrad = Instance.new("UIGradient", OuterGlow)
        GlowGrad.Offset = Vector2.new(-1, 0)
        local gradTween = TweenService:Create(GlowGrad, TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Offset = Vector2.new(1, 0)})
        if isSelected then gradTween:Play() end

        local function UpdateGradientColor()
            local sCol = Library.CurrentTheme and Library.CurrentTheme.Stroke or Color3.fromRGB(50, 50, 55)
            local aCol = Library.CurrentTheme and Library.CurrentTheme.Accent or Color3.fromRGB(255, 255, 255)
            GlowGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, sCol), ColorSequenceKeypoint.new(0.5, aCol), ColorSequenceKeypoint.new(1, sCol) })
        end
        UpdateGradientColor()
        
        local ThemeWatcher = Library.Utils.Make("Frame", {Visible = false, Parent = OuterGlow}, {BackgroundColor3 = "Accent"})
        ThemeWatcher:GetPropertyChangedSignal("BackgroundColor3"):Connect(UpdateGradientColor)

        local Tile = Library.Utils.Make("TextButton", { Size = UDim2.new(1, -4, 1, -4), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), Text = "", AutoButtonColor = false, ClipsDescendants = true, Parent = OuterGlow }, { BackgroundColor3 = "Sidebar" })
        Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Tile })
        local scale = Instance.new("UIScale", Tile)
        
        particleTiles[pType] = { Glow = OuterGlow, Tween = gradTween, Grad = GlowGrad }

        Library:Connect(Tile.MouseEnter, function()
            if getgenv().ParticleType ~= pType then TweenService:Create(OuterGlow, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play(); gradTween:Play() end
            TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.06}):Play()
        end)

        Library:Connect(Tile.MouseLeave, function()
            if getgenv().ParticleType ~= pType then TweenService:Create(OuterGlow, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play(); gradTween:Pause(); GlowGrad.Offset = Vector2.new(-1, 0) end
            TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
        end)

        task.spawn(function()
            while Tile and Tile.Parent do
                if getgenv().MenuParticlesEnabled and Window.MainFrame.Visible then
                    local p = Instance.new("Frame")
                    p.BorderSizePixel = 0
                    p.Parent = Tile

                    if pType == "Old Vanilla" then p.Size = UDim2.new(0, 3, 0, 3); p.BackgroundColor3 = Color3.new(1, 1, 1); p.Position = UDim2.new(math.random(), 0, 0, 0)
                    elseif pType == "Stars" then p.Size = UDim2.new(0, 10, 0, 10); p.BackgroundTransparency = 1; local img = Instance.new("ImageLabel", p); img.Size = UDim2.new(1, 0, 1, 0); img.BackgroundTransparency = 1; img.Image = "rbxassetid://6031225815"; img.ImageColor3 = Library.CurrentTheme.Accent; p.Position = UDim2.new(math.random(), 0, 0, 0)
                    elseif pType == "Snow" then p.Size = UDim2.new(0, 5, 0, 5); p.BackgroundColor3 = Color3.new(1, 1, 1); Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = p}); p.Position = UDim2.new(math.random(), 0, 0, 0)
                    elseif pType == "Sakura Petals" then p.Size = UDim2.new(0, 7, 0, 4); p.BackgroundColor3 = Color3.fromRGB(255, 183, 197); Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0.5, 0), Parent = p}); p.Position = UDim2.new(math.random(), 0, 0, 0)
                    elseif pType == "Bubbles" then p.Size = UDim2.new(0, 8, 0, 8); p.BackgroundTransparency = 1; Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = p}); local stroke = Instance.new("UIStroke", p); stroke.Color = Color3.new(1, 1, 1); stroke.Thickness = 1; p.Position = UDim2.new(math.random(), 0, 0, 0) end
                    TweenService:Create(p, TweenInfo.new(1.2, Enum.EasingStyle.Linear), { Position = UDim2.new(p.Position.X.Scale, math.random(-6, 6), 1, 4), BackgroundTransparency = 1 }):Play()
                    task.delay(1.2, function() if p then p:Destroy() end end)
                end
                task.wait(0.35)
            end
        end)

        Library:Connect(Tile.MouseButton1Click, function()
            getgenv().ParticleType = pType
            for name, data in pairs(particleTiles) do
                local active = (name == pType)
                TweenService:Create(data.Glow, TweenInfo.new(0.25), {BackgroundTransparency = active and 0 or 1}):Play()
                if active then data.Tween:Play() else data.Tween:Pause(); data.Grad.Offset = Vector2.new(-1, 0) end
            end
            scale.Scale = 0.92
            TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.06}):Play()
        end)
    end

    local CloserStyleContainer = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0, 75), Parent = Tab.Page }, { BackgroundColor3 = "Section" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 10), Parent = CloserStyleContainer })
    Library.Utils.Make("UIStroke", { Thickness = 1, Transparency = 0.7, Parent = CloserStyleContainer }, { Color = "Stroke" })
    
    local CloserTitle = Library.Utils.Make("TextLabel", {
        Text = "MINIMIZE BUTTON STYLE", Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = CloserStyleContainer
    }, { TextColor3 = "Accent" })
    Library.Utils.ApplyGradient(CloserTitle, Library.CurrentTheme and Library.CurrentTheme.Accent or Color3.new(1,1,1))

    local CloserGrid = Library.Utils.Make("Frame", { Size = UDim2.new(1, -24, 0, 36), Position = UDim2.new(0, 12, 0, 30), BackgroundTransparency = 1, Parent = CloserStyleContainer })
    Library.Utils.Make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = CloserGrid })

    local closerOptions = {"Top Bar", "Floating Logo"}
    local closerBtns = {}

    for i, opt in ipairs(closerOptions) do
        local isSelected = (getgenv().CloserType == opt or (not getgenv().CloserType and opt == "Top Bar"))
        
        local Btn = Library.Utils.Make("TextButton", { 
            Size = UDim2.new(0.5, -5, 1, 0), 
            LayoutOrder = i, 
            Text = opt, 
            Font = Enum.Font.GothamSemibold, 
            TextSize = 13, 
            AutoButtonColor = false, 
            Parent = CloserGrid 
        }, { 
            BackgroundColor3 = "Sidebar", 
            TextColor3 = isSelected and "Accent" or "SubText" 
        })
        
        Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Btn })
        local scale = Instance.new("UIScale", Btn)
        
        closerBtns[opt] = Btn

        Library:Connect(Btn.MouseEnter, function()
            TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.04}):Play()
            -- Мягкая подсветка текста при наведении, если кнопка не выбрана
            if getgenv().CloserType ~= opt then
                TweenService:Create(Btn, TweenInfo.new(0.2), {TextColor3 = Library.CurrentTheme.Text}):Play()
            end
        end)

        Library:Connect(Btn.MouseLeave, function()
            TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
            -- Возвращаем серый цвет, если увели курсор с неактивной кнопки
            if getgenv().CloserType ~= opt then
                TweenService:Create(Btn, TweenInfo.new(0.2), {TextColor3 = Library.CurrentTheme.SubText}):Play()
            end
        end)

        Library:Connect(Btn.MouseButton1Click, function()
            getgenv().CloserType = opt
            
            -- Плавно перекрашиваем тексты всех кнопок
            for name, button in pairs(closerBtns) do
                local active = (name == opt)
                TweenService:Create(button, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextColor3 = active and Library.CurrentTheme.Accent or Library.CurrentTheme.SubText
                }):Play()
            end
            
            scale.Scale = 0.94
            TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.04}):Play()
        end)
    end

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    
    -- Базовый размер менюхи 680x450 (с запасом)
    local maxScaleX = (viewport.X - 40) / 680
    local maxScaleY = (viewport.Y - 40) / 450
    local dynamicMax = math.floor(math.min(maxScaleX, maxScaleY) * 100)
    
    -- Жесткий лимит до 175%, но если монитор мелкий - потолком будет dynamicMax
    local safeMaxScale = math.clamp(dynamicMax, 50, 175)

    Tab:CreateUIXPanel({
        Min = 25, 
        Max = safeMaxScale,
        DefaultScale = math.clamp(getgenv().UIScaleSize or 50, 25, safeMaxScale),
        ScaleFlag = "UIScaleSize",
        ScaleCallback = function(val)
            getgenv().UIScaleSize = val
            local UIScaleObj = Screen and Screen:FindFirstChildOfClass("UIScale")
            if UIScaleObj then 
                UIScaleObj.Scale = val / 100 
                
                -- Центрируем UI при изменении масштаба (чтобы не улетало за экран)
                if Window and Window.MainFrame then
                    TweenService:Create(Window.MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0.5, 0, 0.5, 0)
                    }):Play()
                end
            end
            if getgenv().SaveConfig then pcall(getgenv().SaveConfig) end
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
    DuskBlur.Name = "DuskMenuBlur"; DuskBlur.Size = 0; DuskBlur.Enabled = false

    Library:Connect(Window.MainFrame:GetPropertyChangedSignal("Visible"), function()
        if getgenv().MenuBlurEnabled then
            if Window.MainFrame.Visible then DuskBlur.Enabled = true; TweenService:Create(DuskBlur, TweenInfo.new(0.3), {Size = 24}):Play()
            else local t = TweenService:Create(DuskBlur, TweenInfo.new(0.3), {Size = 0}); t:Play(); t.Completed:Connect(function() DuskBlur.Enabled = false end) end
        end
    end)

    Tab:CreateToggle({
        Name = "Menu Blur", Description = "Blur background when menu is open.", Flag = "MenuBlurEnabled", Default = getgenv().MenuBlurEnabled or false,
        Callback = function(state)
            getgenv().MenuBlurEnabled = state
            if state and Window.MainFrame.Visible then DuskBlur.Enabled = true; TweenService:Create(DuskBlur, TweenInfo.new(0.3), {Size = 24}):Play()
            elseif not state then local t = TweenService:Create(DuskBlur, TweenInfo.new(0.3), {Size = 0}); t:Play(); t.Completed:Connect(function() DuskBlur.Enabled = false end) end
        end
    })

    -- ==========================================
    -- GLOBAL SETTINGS
    -- ==========================================
    Tab:CreateDivider({ Text = "Global Settings" })

    Tab:CreateToggle({ Name = "Auto-Update Kicker", Description = "Kicks you from the server if a new script version is found.", Flag = "AutoUpdateKicker", Default = getgenv().AutoUpdateKicker or false, Callback = function(state) getgenv().AutoUpdateKicker = state end })
    Tab:CreateToggle({
        Name = "Anonymous Mode", Description = "Hides your identity to prevent streaming snipes.", Flag = "AnonymousMode", Default = getgenv().AnonymousMode or false,
        Callback = function(state)
            getgenv().AnonymousMode = state
            for _, avatarData in ipairs(Library.AnonItems.Avatars) do
                if state then avatarData.ImageObj.ImageTransparency = 1; avatarData.ImageObj.BackgroundTransparency = 0; avatarData.ImageObj.BackgroundColor3 = Color3.new(0,0,0); avatarData.Letter.Visible = true
                else avatarData.ImageObj.ImageTransparency = 0; avatarData.ImageObj.BackgroundTransparency = 1; avatarData.Letter.Visible = false end
            end
            for _, nameData in ipairs(Library.AnonItems.Names) do nameData.Obj.Text = string.format(nameData.Format, state and "Hidden User" or LocalPlayer.DisplayName) end
        end
    })

    -- Кастомный Toggle Menu Key (Замена дефолтному CreateKeybind для симметрии)
    local KeybindCard = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0, 70), Parent = Tab.Page }, { BackgroundColor3 = "Section" })
    Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 10), Parent = KeybindCard})
    Library.Utils.Make("UIStroke", {Thickness = 1, Parent = KeybindCard}, {Color = "Stroke"})
    
    Library.Utils.Make("TextLabel", { Text = "Toggle Menu Key", Size = UDim2.new(1, -120, 0, 20), Position = UDim2.new(0, 20, 0, 15), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Parent = KeybindCard }, { TextColor3 = "Text" })
    Library.Utils.Make("TextLabel", { Text = "Key to hide or show the menu.", Size = UDim2.new(1, -120, 0, 15), Position = UDim2.new(0, 20, 0, 38), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = KeybindCard }, { TextColor3 = "SubText" })

    local BindBtn = Library.Utils.Make("TextButton", { Size = UDim2.new(0, 80, 0, 34), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -20, 0.5, 0), Font = Enum.Font.Gotham, TextSize = 13, AutoButtonColor = false, Text = (getgenv().ToggleUIKey or Enum.KeyCode.RightControl).Name, Parent = KeybindCard }, { BackgroundColor3 = "Sidebar", TextColor3 = "SubText" })
    Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 8), Parent = BindBtn})
    Library.Utils.Make("UIStroke", {Thickness = 1, Parent = BindBtn}, {Color = "Stroke"})

    local listening = false
    Library:Connect(BindBtn.MouseButton1Click, function()
        if listening then return end
        listening = true
        BindBtn.Text = "..."
        Library.Utils.TBT(BindBtn, 0.2, {TextColor3 = Library.CurrentTheme.Accent})

        local tempConnection
        tempConnection = game:GetService("UserInputService").InputBegan:Connect(function(input)
            local isKey = input.UserInputType == Enum.UserInputType.Keyboard
            local isMouse = input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3

            if isKey or isMouse then
                local newKey = isKey and input.KeyCode or input.UserInputType
                if newKey == Enum.KeyCode.Escape then newKey = Enum.KeyCode.Unknown end

                getgenv().ToggleUIKey = newKey
                BindBtn.Text = newKey.Name
                listening = false
                Library.Utils.TBT(BindBtn, 0.2, {TextColor3 = Library.CurrentTheme.SubText})

                if getgenv().SaveConfig then pcall(getgenv().SaveConfig) end
                if tempConnection then tempConnection:Disconnect() end
            end
        end)
    end)

    Library:Connect(game:GetService("UserInputService").InputBegan, function(input, processed)
        if not processed and input.KeyCode == getgenv().ToggleUIKey then
            task.spawn(function() if Window.ToggleMenu then Window:ToggleMenu() end end)
        end
    end)

    -- ==========================================
    -- PERFORMANCE
    -- ==========================================
    Tab:CreateDivider({ Text = "Performance" })
    
    local UserInputService = game:GetService("UserInputService")
    
    local SliderContainer = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0, 70), Parent = Tab.Page }, { BackgroundColor3 = "Section" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 10), Parent = SliderContainer })
    local containerStroke = Library.Utils.Make("UIStroke", { Thickness = 1, Parent = SliderContainer }, { Color = "Stroke" })

    Library.Utils.Make("TextLabel", { Text = "Frame Rate Limit", Size = UDim2.new(1, -100, 0, 20), Position = UDim2.new(0, 20, 0, 10), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Parent = SliderContainer }, { TextColor3 = "Text" })
    Library.Utils.Make("TextLabel", { Text = "Drag to the far right to completely uncap FPS.", Size = UDim2.new(1, -100, 0, 15), Position = UDim2.new(0, 20, 0, 30), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = SliderContainer }, { TextColor3 = "SubText" })

    local PillFrame = Library.Utils.Make("Frame", { Size = UDim2.new(0, 76, 0, 24), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 9), Parent = SliderContainer }, { BackgroundColor3 = "Sidebar" }) 
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = PillFrame })
    local pillStroke = Library.Utils.Make("UIStroke", { Thickness = 1, Parent = PillFrame }, { Color = "Stroke" })
    
    local ValueText = Library.Utils.Make("TextBox", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, ClearTextOnFocus = false, ZIndex = 2, Parent = PillFrame }, { TextColor3 = "Text" })
    local PillScale = Instance.new("UIScale", PillFrame)

    local Track = Library.Utils.Make("TextButton", { Size = UDim2.new(1, -40, 0, 4), Position = UDim2.new(0, 20, 1, -12), AnchorPoint = Vector2.new(0, 1), Text = "", AutoButtonColor = false, Parent = SliderContainer }, { BackgroundColor3 = "Sidebar" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Track })

    local Fill = Library.Utils.Make("Frame", { Size = UDim2.new(0, 0, 1, 0), Parent = Track }, { BackgroundColor3 = "Accent" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Fill })

    local Knob = Library.Utils.Make("Frame", { Size = UDim2.new(0, 12, 0, 12), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Parent = Fill }, { BackgroundColor3 = "Text" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Knob })
    
    local KnobScale = Instance.new("UIScale", Knob)

    local minFPS, maxFPS = 15, 360
    local rawSavedFPS = getgenv().FPSLimit or 0
    local currentVisualFPS = (rawSavedFPS == 0) and maxFPS or rawSavedFPS 
    local isDragging = false
    local isUncapped = false

    local function updateVisuals(val)
        local pct = math.clamp((val - minFPS) / (maxFPS - minFPS), 0, 1)
        TweenService:Create(Fill, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
        
        if val == maxFPS then
            ValueText.Text = "Uncapped"
            if not isUncapped then
                isUncapped = true
                if Library.ThemeObjects[ValueText] then Library.ThemeObjects[ValueText] = { TextColor3 = "Accent" } end
                if Library.ThemeObjects[pillStroke] then Library.ThemeObjects[pillStroke] = { Color = "Accent" } end
                TweenService:Create(ValueText, TweenInfo.new(0.2), {TextColor3 = Library.CurrentTheme.Accent}):Play()
                TweenService:Create(pillStroke, TweenInfo.new(0.2), {Color = Library.CurrentTheme.Accent}):Play()
                PillScale.Scale = 0.85; TweenService:Create(PillScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
            end
        else
            ValueText.Text = tostring(val)
            if isUncapped then
                isUncapped = false
                if Library.ThemeObjects[ValueText] then Library.ThemeObjects[ValueText] = { TextColor3 = "Text" } end
                if Library.ThemeObjects[pillStroke] then Library.ThemeObjects[pillStroke] = { Color = "Stroke" } end
                TweenService:Create(ValueText, TweenInfo.new(0.2), {TextColor3 = Library.CurrentTheme.Text}):Play()
                TweenService:Create(pillStroke, TweenInfo.new(0.2), {Color = Library.CurrentTheme.Stroke}):Play()
            end
        end
    end

    local function updateDrag(input)
        local absolutePos = Track.AbsolutePosition.X
        local absoluteSize = Track.AbsoluteSize.X
        local pct = math.clamp((input.Position.X - absolutePos) / absoluteSize, 0, 1)
        local snappedValue = math.floor(minFPS + (maxFPS - minFPS) * pct)
        
        if currentVisualFPS ~= snappedValue then
            currentVisualFPS = snappedValue
            updateVisuals(currentVisualFPS)
            local actualFPS = (currentVisualFPS == maxFPS) and 0 or currentVisualFPS
            getgenv().FPSLimit = actualFPS
            if not getgenv().EcoModeEnabled and setfpscap then pcall(function() setfpscap(actualFPS) end) end
        end
    end

    ValueText.FocusLost:Connect(function()
        local num = tonumber(ValueText.Text:match("%d+"))
        if num then
            num = math.clamp(num, minFPS, maxFPS)
            currentVisualFPS = num
            updateVisuals(currentVisualFPS)
            local actualFPS = (currentVisualFPS == maxFPS) and 0 or currentVisualFPS
            getgenv().FPSLimit = actualFPS
            if not getgenv().EcoModeEnabled and setfpscap then pcall(function() setfpscap(actualFPS) end) end
        else
            ValueText.Text = (currentVisualFPS == maxFPS) and "Uncapped" or tostring(currentVisualFPS)
        end
    end)

    updateVisuals(currentVisualFPS)

    Library:Connect(Track.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true; TweenService:Create(KnobScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.35}):Play(); updateDrag(input)
        end
    end)

    Library:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = false; TweenService:Create(KnobScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
        end
    end)

    Library:Connect(UserInputService.InputChanged, function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateDrag(input) end
    end)

    Library:Connect(SliderContainer.MouseEnter, function() TweenService:Create(containerStroke, TweenInfo.new(0.3), {Transparency = 0.5}):Play() end)
    Library:Connect(SliderContainer.MouseLeave, function() TweenService:Create(containerStroke, TweenInfo.new(0.3), {Transparency = 0}):Play() end)
    
    Tab:CreateToggle({
        Name = "Extreme Performance (NoRender)", Description = "Kills 3D rendering, shadows, and textures for MAX FPS.", Flag = "PerformanceModeEnabled", Default = getgenv().PerformanceModeEnabled or false,
        Callback = function(state)
            getgenv().PerformanceModeEnabled = state
            local Terrain = workspace:FindFirstChildOfClass("Terrain")
            if state then
                Lighting.GlobalShadows = false; Lighting.FogEnd = 9e9; Lighting.ShadowSoftness = 0; Lighting.Brightness = 0
                if Terrain then Terrain.WaterWaveSize = 0; Terrain.WaterWaveSpeed = 0; Terrain.WaterReflectance = 0; Terrain.WaterTransparency = 0 end
                pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
            else
                Lighting.GlobalShadows = true; Lighting.Brightness = 1
                pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
            end
        end
    })
end

return Module
