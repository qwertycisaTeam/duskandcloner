-- [lib by rio] Latest Update: 09.08.26 / library version 2 [рефакторинг от 10.08]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
local Camera = workspace.CurrentCamera

local MainFont = Font.new("rbxassetid://16658237174") -- Libre Baskerville
local LoaderFont = Font.new("rbxassetid://12187365104") -- Blaka

if getgenv().DuskShine_Core then
    getgenv().DuskShine_Core:Destroy()
end

-- main object
local Library = {
    Flags = {},
    ConfigUpdaters = {},
    Settings = {
        AnonymousMode = false,
        MenuParticles = true,
        CloserType = "Top Bar"
    },
    Connections = {},
    ThemeObjects = {},
    AnonItems = { Avatars = {}, Names = {}, UIDs = {} },
    Utils = {}
}
getgenv().DuskShine_Core = Library

function Library:Destroy()
    for _, conn in ipairs(self.Connections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    table.clear(self.Connections)
    
    local oldMega = PlayerGui:FindFirstChild("DuskShine_Mega")
    if oldMega then oldMega:Destroy() end
    
    local oldEco = PlayerGui:FindFirstChild("DuskShine_Eco")
    if oldEco then oldEco:Destroy() end
end

function Library:Connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self.Connections, connection)
    return connection
end

local rgb = Color3.fromRGB

-- utils
function Library.Utils.TBT(obj, time, props, style, dir)
    style = style or Enum.EasingStyle.Sine
    dir = dir or Enum.EasingDirection.Out
    local tween = TweenService:Create(obj, TweenInfo.new(time, style, dir), props)
    tween:Play()
    tween.Completed:Connect(function() tween:Destroy() end)
    return tween
end

function Library.Utils.CreateRipple(Parent)
    Parent.ClipsDescendants = true
    local Ripple = Instance.new("Frame")
    Ripple.Name = "Ripple"; Ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Ripple.BackgroundTransparency = 0.8; Ripple.ZIndex = 10
    
    local Mouse = Players.LocalPlayer:GetMouse()
    local AbsolutePosition = Parent.AbsolutePosition
    Ripple.Position = UDim2.new(0, Mouse.X - AbsolutePosition.X, 0, Mouse.Y - AbsolutePosition.Y)
    Ripple.Size = UDim2.new(0, 0, 0, 0)
    Ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    
    Library.Utils.Make("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Transparency = 0.8, Thickness = 1, Parent = Ripple})
    Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Ripple})
    Ripple.Parent = Parent
    
    local TargetSize = math.max(Parent.AbsoluteSize.X, Parent.AbsoluteSize.Y) * 2.5
    local Tween = TweenService:Create(Ripple, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, TargetSize, 0, TargetSize), BackgroundTransparency = 1})
    Tween:Play()
    Tween.Completed:Connect(function() Ripple:Destroy() end)
end

local BaseTheme = {
    Red    = rgb(255, 95, 87),
    Yellow = rgb(255, 189, 46),
    Green  = rgb(39, 201, 63)
}

local function makeTheme(colors)
    return setmetatable(colors, { __index = BaseTheme })
end

Library.Themes = {
    Dark = makeTheme({
        Background = rgb(15, 15, 20), Sidebar = rgb(20, 20, 25), Section = rgb(28, 28, 33),
        Text = rgb(255, 255, 255), SubText = rgb(120, 120, 130), Accent = rgb(255, 255, 255),
        Stroke = rgb(45, 45, 50), ToggleOff = rgb(55, 55, 60), ToggleOn = rgb(255, 255, 255), Knob = rgb(20, 20, 25)
    }),
    Light = makeTheme({
        Background = rgb(245, 245, 250), Sidebar = rgb(255, 255, 255), Section = rgb(235, 235, 240),
        Text = rgb(20, 20, 25), SubText = rgb(100, 100, 110), Accent = rgb(0, 122, 255),
        Stroke = rgb(220, 220, 230), ToggleOff = rgb(200, 200, 210), ToggleOn = rgb(0, 122, 255), Knob = rgb(255, 255, 255)
    }),
    Galaxy = makeTheme({
        Background = rgb(12, 10, 20), Sidebar = rgb(18, 15, 30), Section = rgb(25, 20, 42),
        Text = rgb(240, 240, 255), SubText = rgb(150, 140, 190), Accent = rgb(110, 60, 255),
        Stroke = rgb(50, 40, 80), ToggleOff = rgb(40, 30, 70), ToggleOn = rgb(110, 60, 255), Knob = rgb(20, 15, 35)
    }),
    Emerald = makeTheme({
        Background = rgb(15, 22, 18), Sidebar = rgb(20, 28, 22), Section = rgb(26, 36, 28),
        Text = rgb(240, 255, 240), SubText = rgb(130, 160, 140), Accent = rgb(46, 204, 113),
        Stroke = rgb(45, 60, 50), ToggleOff = rgb(40, 55, 45), ToggleOn = rgb(46, 204, 113), Knob = rgb(20, 28, 22)
    }),
    BlueDeepWave = makeTheme({
        Background = rgb(10, 15, 25), Sidebar = rgb(15, 22, 35), Section = rgb(22, 30, 48),
        Text = rgb(235, 245, 255), SubText = rgb(120, 140, 180), Accent = rgb(0, 170, 255),
        Stroke = rgb(40, 50, 75), ToggleOff = rgb(35, 45, 65), ToggleOn = rgb(0, 170, 255), Knob = rgb(15, 22, 35)
    })
}

Library.CurrentThemeName = "Dark"
Library.CurrentTheme = Library.Themes[Library.CurrentThemeName]

local DefaultAccents = {
    Dark = rgb(255, 255, 255), Light = rgb(0, 122, 255),
    Galaxy = rgb(110, 60, 255), Emerald = rgb(46, 204, 113), BlueDeepWave = rgb(0, 170, 255)
}

function Library.Utils.ApplyGradient(uiElement, accentColor)
    local grad = uiElement:FindFirstChild("DuskShine_Gradient")
    local isNew = false
    
    if not grad then
        grad = Instance.new("UIGradient")
        grad.Name = "DuskShine_Gradient"
        grad.Rotation = 45
        grad.Offset = Vector2.new(-0.8, 0)
        isNew = true -- Флаг, чтобы запустить анимацию и парент позже
    end
    
    -- Безопасный парсинг базового цвета (на случай, если прилетел nil)
    local safeAccent = typeof(accentColor) == "Color3" and accentColor or Color3.fromRGB(255, 255, 255)
    local h, s, v = safeAccent:ToHSV()
    
    -- Безопасный расчет свечения через pcall
    local s_success, s_result = pcall(function()
        return Color3.fromHSV(h, math.clamp(s - 0.3, 0, 1), math.clamp(v + 0.4, 0, 1))
    end)
    
    local glowColor = (s_success and typeof(s_result) == "Color3") and s_result or safeAccent
    
    -- ПРИНУДИТЕЛЬНО создаем чистые Color3 через .new() из компонентов
    -- Это сбивает любую кривую метатаблицу экзекутора
    local c1 = Color3.new(safeAccent.R, safeAccent.G, safeAccent.B)
    local c2 = Color3.new(glowColor.R, glowColor.G, glowColor.B)
    
    -- Сначала задаем цвет (используя наши чистые c1 и c2)!
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c1),
        ColorSequenceKeypoint.new(0.5, c2),
        ColorSequenceKeypoint.new(1, c1)
    })
    
    -- Только потом парентим и запускаем твин
    if isNew then
        grad.Parent = uiElement
        TweenService:Create(grad, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(0.8, 0)}):Play()
    end
end

-- Функция создания элементов с авто-подключением темы
function Library.Utils.Make(className, properties, themeProps)
    local inst = Instance.new(className)
    for prop, value in pairs(properties) do inst[prop] = value end
    
    if themeProps then
        if not Library.ThemeObjects[inst] then Library.ThemeObjects[inst] = {} end
        
        for prop, themeKey in pairs(themeProps) do
            Library.ThemeObjects[inst][prop] = themeKey
            inst[prop] = Library.CurrentTheme[themeKey]
            
            if themeKey == "Accent" and not inst:IsA("ImageLabel") then
                Library.Utils.ApplyGradient(inst, Library.CurrentTheme.Accent)
            end

            inst.Destroying:Connect(function()
                Library.ThemeObjects[inst] = nil
            end)
        end
    end
    return inst
end

function Library:SetTheme(themeName)
    if not self.Themes[themeName] then return end
    self.CurrentThemeName = themeName
    self.CurrentTheme = self.Themes[themeName]
    
    if DefaultAccents[themeName] then
        self.CurrentTheme.Accent = DefaultAccents[themeName]
    end

    for UIElement, Props in pairs(self.ThemeObjects) do
        -- Убрали лишнюю проверку, так как таблица слабая (удаленные элементы исчезают сами)
        for Property, ThemeKey in pairs(Props) do
            Library.Utils.TBT(UIElement, 0.3, {[Property] = self.CurrentTheme[ThemeKey]})
            
            if ThemeKey == "Accent" and not UIElement:IsA("ImageLabel") then
                Library.Utils.ApplyGradient(UIElement, self.CurrentTheme.Accent)
            end
        end
    end
end

Library.ThemeCycle = {"Dark", "Light", "Galaxy", "Emerald", "BlueDeepWave"}

function Library:ToggleTheme()
    local currentIndex = table.find(self.ThemeCycle, self.CurrentThemeName) or 1
    local nextIndex = currentIndex + 1
    if nextIndex > #self.ThemeCycle then nextIndex = 1 end
    
    local nextTheme = self.ThemeCycle[nextIndex]
    self:SetTheme(nextTheme)
    
    return nextTheme 
end

-- ==========================================
-- 4. СОЗДАНИЕ ОКНА (WINDOW)
-- ==========================================

function Library:RunLoader(ScreenGui, OnComplete)
    local Blur = Library.Utils.Make("BlurEffect", {Size = 0, Parent = game:GetService("Lighting")})
    TweenService:Create(Blur, TweenInfo.new(0.3), {Size = 15}):Play()

    local LoaderCard = Library.Utils.Make("Frame", { Size = UDim2.new(0, 380, 0, 220), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BorderSizePixel = 0, BackgroundTransparency = 1, Parent = ScreenGui }, { BackgroundColor3 = "Background" })
    Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 16), Parent = LoaderCard})
    local Stroke = Library.Utils.Make("UIStroke", { Thickness = 2, Transparency = 1, Parent = LoaderCard }, { Color = "Accent" })

    local Logo = Library.Utils.Make("ImageLabel", { Size = UDim2.new(0, 110, 0, 110), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.35, 0), BackgroundTransparency = 1, Image = "rbxassetid://72958619361915", ImageTransparency = 1, Parent = LoaderCard })
    local Title = Library.Utils.Make("TextLabel", { Text = "dusk & shine", Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0.52, 0), FontFace = LoaderFont, TextSize = 42, TextTransparency = 1, BackgroundTransparency = 1, Parent = LoaderCard }, { TextColor3 = "Accent" })
    local Status = Library.Utils.Make("TextLabel", { Text = "Injecting Modules...", Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0.68, 0), Font = Enum.Font.GothamMedium, TextSize = 13, TextTransparency = 1, BackgroundTransparency = 1, Parent = LoaderCard }, { TextColor3 = "SubText" })

    local BarBG = Library.Utils.Make("Frame", { Size = UDim2.new(0, 240, 0, 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.82, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = LoaderCard }, { BackgroundColor3 = "Section" })
    Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = BarBG})
    local BarFill = Library.Utils.Make("Frame", { Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0, Parent = BarBG }, { BackgroundColor3 = "Accent" })
    Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = BarFill})

    Library.Utils.TBT(LoaderCard, 0.2, {BackgroundTransparency = 0.05}) 
    Library.Utils.TBT(Stroke, 0.2, {Transparency = 0}) 
    Library.Utils.TBT(Logo, 0.25, {ImageTransparency = 0, Position = UDim2.new(0.5, 0, 0.3, 0)}) 
    Library.Utils.TBT(Title, 0.25, {TextTransparency = 0}) 
    Library.Utils.TBT(Status, 0.25, {TextTransparency = 0}) 
    Library.Utils.TBT(BarBG, 0.25, {BackgroundTransparency = 0})
    
    -- Запускаем быструю заливку бара
    Library.Utils.TBT(BarFill, 0.4, {Size = UDim2.new(1, 0, 1, 0)}).Completed:Wait()

    -- Моментальное исчезновение
    Library.Utils.TBT(LoaderCard, 0.2, {BackgroundTransparency = 1, Size = UDim2.new(0, 400, 0, 240)}) 
    Library.Utils.TBT(Stroke, 0.2, {Transparency = 1}) 
    Library.Utils.TBT(Logo, 0.2, {ImageTransparency = 1}) 
    Library.Utils.TBT(Title, 0.2, {TextTransparency = 1})
    Library.Utils.TBT(Status, 0.2, {TextTransparency = 1}) 
    Library.Utils.TBT(BarBG, 0.2, {BackgroundTransparency = 1}) 
    Library.Utils.TBT(BarFill, 0.2, {BackgroundTransparency = 1}) 
    Library.Utils.TBT(Blur, 0.3, {Size = 0})
    
    task.wait(0.25)
    LoaderCard:Destroy()
    Blur:Destroy()
    if OnComplete then OnComplete() end
end

function Library:CreateWindow(config)
    config = config or {}
    local windowTitle = config.Title or "Dusk &"
    local windowAccent = config.AccentTitle or "Shine"
    local versionText = config.Version
    
    local ScreenGui = Library.Utils.Make("ScreenGui", {
        Name = "DuskShine_Mega", Parent = PlayerGui, ResetOnSpawn = false,
        IgnoreGuiInset = true, ZIndexBehavior = "Global", DisplayOrder = 100
    })

    local NotifyHolder = Library.Utils.Make("Frame", {
        Name = "Notifications", Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0, 10, 0, 10),
        AnchorPoint = Vector2.new(0, 0), BackgroundTransparency = 1, Parent = ScreenGui, ZIndex = 100
    })
    Library.Utils.Make("UIListLayout", { HorizontalAlignment = "Right", VerticalAlignment = "Bottom", Padding = UDim.new(0, 5), Parent = NotifyHolder })

    local BaseScale = (getgenv().UIScaleSize or 100) / 100
    local MainUIScale = Library.Utils.Make("UIScale", { Parent = ScreenGui, Scale = BaseScale })

    Library:Connect(Camera:GetPropertyChangedSignal("ViewportSize"), function()
        local Viewport = Camera.ViewportSize
        MainUIScale.Scale = Viewport.X < 700 and (BaseScale * (Viewport.X / 700)) or BaseScale
    end)

    local MainFrame = Library.Utils.Make("CanvasGroup", {
        Size = UDim2.new(0, 460, 0, 410), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0), BorderSizePixel = 0, GroupTransparency = 1,
        Visible = false, BackgroundTransparency = 0.15, Parent = ScreenGui
    }, { BackgroundColor3 = "Background" })

    Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 14), Parent = MainFrame})
    Library.Utils.Make("UIStroke", {Thickness = 1, Transparency = 0.5, Parent = MainFrame}, {Color = "Stroke"})

    local Sidebar = Library.Utils.Make("Frame", { Size = UDim2.new(0, 60, 1, 0), BorderSizePixel = 0, BackgroundTransparency = 0.4, Parent = MainFrame}, { BackgroundColor3 = "Sidebar" })
    Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Sidebar})

    local TabsContainer = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 1, -80), Position = UDim2.new(0, 0, 0, 20), BackgroundTransparency = 1, Parent = Sidebar })
    Library.Utils.Make("UIListLayout", {HorizontalAlignment = "Center", Padding = UDim.new(0, 20), Parent = TabsContainer})

    -- ==========================================
    -- АВАТАРКА В БОКОВОМ МЕНЮ
    -- ==========================================
    local Avatar = Library.Utils.Make("ImageButton", {
        Size = UDim2.new(0, 36, 0, 36), Position = UDim2.new(0.5, -18, 1, -65), 
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. game:GetService("Players").LocalPlayer.UserId .. "&w=100&h=100", 
        Parent = Sidebar
    }, { BackgroundColor3 = "Section" })
    Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Avatar})
    Library.Utils.Make("UIStroke", {Thickness = 1, Parent = Avatar}, {Color = "Stroke"})

    local SideAnonA = Library.Utils.Make("TextLabel", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "A", Font = Enum.Font.GothamBold, TextSize = 20,
        Visible = Library.Settings.AnonymousMode, Parent = Avatar
    }, { TextColor3 = "Accent" })
    
    if Library.Settings.AnonymousMode then 
        Avatar.ImageTransparency = 1; Avatar.BackgroundTransparency = 0; Avatar.BackgroundColor3 = Color3.new(0,0,0) 
    end
    table.insert(Library.AnonItems.Avatars, {ImageObj = Avatar, Letter = SideAnonA})

    Library:Connect(Avatar.MouseButton1Click, function()
        Library.Utils.CreateRipple(Avatar)
        Library:Notify("Profile", "Profile Page is currently disabled.", 3)
    end)

    -- ==========================================
    -- ШАПКА: TITLE, ONLINE COUNTER, SEARCH, MAC BUTTONS
    -- ==========================================
    local Header = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, -60, 0, 60), Position = UDim2.new(0, 60, 0, 0),
        BackgroundTransparency = 1, Parent = MainFrame
    })

    -- 1. Текст заголовка (Dusk & Shine v1.0)
    local TitleContainer = Library.Utils.Make("Frame", { Size = UDim2.new(0, 250, 1, 0), Position = UDim2.new(0, 25, 0, 0), BackgroundTransparency = 1, Parent = Header })
    Library.Utils.Make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = TitleContainer })

    Library.Utils.Make("TextLabel", { LayoutOrder = 1, Text = windowTitle, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0,0,1,0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 20, Parent = TitleContainer }, { TextColor3 = "Text" })
    Library.Utils.Make("TextLabel", { LayoutOrder = 2, Text = " " .. windowAccent, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0,0,1,0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 20, Parent = TitleContainer }, { TextColor3 = "Accent" })
    Library.Utils.Make("TextLabel", { LayoutOrder = 3, Text = "  " .. versionText, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0,0,1,0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 14, Parent = TitleContainer }, { TextColor3 = "SubText" })

    -- Отступ перед онлайном
    Library.Utils.Make("Frame", { LayoutOrder = 4, Size = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, Parent = TitleContainer })

    -- 2. Счетчик онлайна (Pill)
    local OnlinePill = Library.Utils.Make("Frame", { LayoutOrder = 5, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 24), Parent = TitleContainer }, { BackgroundColor3 = "Section" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = OnlinePill })
    Library.Utils.Make("UIStroke", { Thickness = 1, Parent = OnlinePill }, { Color = "Stroke" })
    Library.Utils.Make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), Parent = OnlinePill })
    Library.Utils.Make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12), Parent = OnlinePill })

    local OnlineIndicator = Library.Utils.Make("Frame", { Size = UDim2.new(0, 8, 0, 8), BackgroundColor3 = Color3.fromRGB(15, 205, 105), Parent = OnlinePill })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = OnlineIndicator })
    local OnlineText = Library.Utils.Make("TextLabel", { Text = "Loading...", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0,0,1,0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 12, Parent = OnlinePill }, { TextColor3 = "SubText" })

    -- 3. Кнопки управления (Mac Buttons)
    local MacFrame = Library.Utils.Make("Frame", { Size = UDim2.new(0, 60, 0, 20), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -25, 0.5, 0), BackgroundTransparency = 1, Parent = Header })
    Library.Utils.Make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = MacFrame })

    local function MakeMac(colorKey, layoutOrder, callback)
        local b = Library.Utils.Make("TextButton", { LayoutOrder = layoutOrder, Text = "", Size = UDim2.new(0, 14, 0, 14), Parent = MacFrame }, { BackgroundColor3 = colorKey })
        Library.Utils.Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = b })
        Library:Connect(b.MouseButton1Click, callback)
        Library:Connect(b.MouseEnter, function() Library.Utils.TBT(b, 0.2, {BackgroundTransparency = 0.3}) end)
        Library:Connect(b.MouseLeave, function() Library.Utils.TBT(b, 0.2, {BackgroundTransparency = 0}) end)
        return b
    end

    -- 4. Строка поиска (Search)
    local SearchContainer = Library.Utils.Make("Frame", { Size = UDim2.new(0, 160, 0, 32), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -95, 0.5, 0), BackgroundTransparency = 1, Parent = Header })
    local SearchBg = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 1, 0), Parent = SearchContainer }, { BackgroundColor3 = "Section" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SearchBg })
    Library.Utils.Make("UIStroke", { Parent = SearchBg }, { Color = "Stroke" })
    
    Library.Utils.Make("ImageLabel", { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -24, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1, Image = "rbxassetid://3926305904", ImageRectOffset = Vector2.new(964, 324), ImageRectSize = Vector2.new(36, 36), Parent = SearchContainer }, { ImageColor3 = "SubText" })
    local SearchInput = Library.Utils.Make("TextBox", { Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, PlaceholderText = "Search...", Text = "", Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = SearchContainer }, { TextColor3 = "Text", PlaceholderColor3 = "SubText" })

    -- ==========================================
    -- ЛОГИКА СВОРАЧИВАНИЯ (MINIMIZE / FLOATING LOGO)
    -- ==========================================
    local FloatingWidget = Library.Utils.Make("CanvasGroup", {
        Name = "FloatingWidget", Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0.5, 0, 0.1, 0),
        AnchorPoint = Vector2.new(0.5, 0.5), GroupTransparency = 1, Visible = false, ZIndex = 15, Parent = ScreenGui
    }, { BackgroundColor3 = "Sidebar" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(1, 0), Parent = FloatingWidget })
    Library.Utils.Make("UIStroke", { Thickness = 2, Parent = FloatingWidget }, { Color = "Accent" })
    Library.Utils.Make("ImageLabel", { Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Image = "rbxassetid://72958619361915", ZIndex = 16, Parent = FloatingWidget }, { ImageColor3 = "Text" })
    local FloatingClick = Library.Utils.Make("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 17, Parent = FloatingWidget })

    local OpenBtn = Library.Utils.Make("TextButton", { Size = UDim2.new(0, 140, 0, 40), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -60), Text = "Open Menu", Font = Enum.Font.GothamBold, TextSize = 14, Visible = false, ZIndex = 15, Parent = ScreenGui }, { BackgroundColor3 = "Sidebar", TextColor3 = "Text" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = OpenBtn })
    Library.Utils.Make("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 2, Parent = OpenBtn }, { Color = "Accent" })

    -- Функция переключения состояния окна
    local function ToggleMinimize()
        if MainFrame.Visible then
            Library.Utils.TBT(MainFrame, 0.3, {GroupTransparency = 1, Size = UDim2.new(0, 700, 0, 400)}, Enum.EasingStyle.Back, Enum.EasingDirection.In).Completed:Wait()
            MainFrame.Visible = false
            
            if Library.Settings.CloserType == "Floating Logo" then
                FloatingWidget.Visible = true
                FloatingWidget.Size = UDim2.new(0, 0, 0, 0)
                Library.Utils.TBT(FloatingWidget, 0.4, {Size = UDim2.new(0, 50, 0, 50), GroupTransparency = 0}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            else
                OpenBtn.Visible = true
                OpenBtn.BackgroundTransparency = 1
                Library.Utils.TBT(OpenBtn, 0.4, {Position = UDim2.new(0.5, 0, 0, 10), BackgroundTransparency = 0}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            end
        else
            if Library.Settings.CloserType == "Floating Logo" then
                Library.Utils.TBT(FloatingWidget, 0.3, {Size = UDim2.new(0, 0, 0, 0), GroupTransparency = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.In).Completed:Wait()
                FloatingWidget.Visible = false
            else
                Library.Utils.TBT(OpenBtn, 0.3, {Position = UDim2.new(0.5, 0, 0, -50)}, Enum.EasingStyle.Back, Enum.EasingDirection.In).Completed:Wait()
                OpenBtn.Visible = false
            end

            MainFrame.Visible = true
            Library.Utils.TBT(MainFrame, 0.4, {GroupTransparency = 0, Size = UDim2.new(0, 680, 0, 450)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end
    end

    Library:Connect(FloatingClick.MouseButton1Click, ToggleMinimize)
    Library:Connect(OpenBtn.MouseButton1Click, ToggleMinimize)

    -- Биндим Mac-кнопки
    MakeMac("Green", 1, function() Library:ToggleTheme() end)
    MakeMac("Yellow", 2, ToggleMinimize)
    MakeMac("Red", 3, function() 
        Library.Utils.TBT(MainFrame, 0.3, {GroupTransparency = 1, Size = UDim2.new(0, 700, 0, 400)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.delay(0.3, function()
            Library:Destroy()
        end)
    end)

    local Pages = Instance.new("Frame")
    Pages.Size = UDim2.new(1, -60, 1, -60); Pages.Position = UDim2.new(0, 60, 0, 60); Pages.BackgroundTransparency = 1; Pages.ClipsDescendants = true; Pages.Parent = MainFrame

    -- === БЕЗОПАСНЫЙ DRAGGING (Без утечек памяти) ===
    local dragging, dragInput, dragStart, startPos
    
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    Header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    -- Используем Library:Connect! Если UI закроют, коннекты умрут сами.
    Library:Connect(UserInputService.InputChanged, function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    Library:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- ==========================================
    -- 5. ОБЪЕКТ ОКНА (WINDOW OBJECT)
    -- ==========================================
    local Window = {
        MainFrame = MainFrame,
        TabsContainer = TabsContainer,
        PagesContainer = Pages,
        Tabs = {}, 
        CurrentTab = nil,
        ToggleMenu = ToggleMinimize
    }

    function Window:SetOnlineStatus(countText)
        OnlineText.Text = "Currently playing: " .. tostring(countText)
        Library.Utils.TBT(OnlineIndicator, 0.4, {BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
        task.delay(0.4, function()
            Library.Utils.TBT(OnlineIndicator, 0.4, {BackgroundColor3 = Color3.fromRGB(15, 205, 105)})
        end)
    end

    function Window:SelectTab(TabObj)
        if self.CurrentTab == TabObj.Btn then return end
        self.CurrentTab = TabObj.Btn

        for _, tab in ipairs(self.Tabs) do
            local isSelected = (tab.Btn == TabObj.Btn)
            
            if isSelected then
                -- === ЛОГИКА АКТИВНОЙ ВКЛАДКИ ===
                tab.Page.Visible = true
                tab.Page.Position = UDim2.new(0, 0, 0, 25) 
                Library.Utils.TBT(tab.Page, 0.3, {Position = UDim2.new(0, 0, 0, 5)}, Enum.EasingStyle.Quint)

                -- Обновляем реестр тем
                Library.ThemeObjects[tab.Icon] = { ImageColor3 = "Accent" }
                Library.ThemeObjects[tab.Indicator] = { BackgroundColor3 = "Accent" }
                
                -- Вычищаем градиент (если он чудом заспавнился)
                local oldGrad = tab.Indicator:FindFirstChild("DuskShine_Gradient")
                if oldGrad then oldGrad:Destroy() end

                -- ФИКС: МОМЕНТАЛЬНО задаем цвет, чтобы убить белый кадр!
                tab.Indicator.BackgroundColor3 = Library.CurrentTheme.Accent
                tab.Icon.ImageColor3 = Library.CurrentTheme.Accent
                
                -- Твиним ТОЛЬКО физику (размер, поворот, прозрачность)
                Library.Utils.TBT(tab.Icon, 0.3, {Size = UDim2.new(1.15, 0, 1.15, 0), Rotation = -12}, Enum.EasingStyle.Back)
                Library.Utils.TBT(tab.Indicator, 0.3, {BackgroundTransparency = 0})
            else
                -- === ЛОГИКА СПЯЩИХ ВКЛАДОК ===
                tab.Page.Visible = false
                
                Library.ThemeObjects[tab.Icon] = { ImageColor3 = "SubText" }
                Library.ThemeObjects[tab.Indicator] = { BackgroundColor3 = "SubText" } 
                
                local oldGrad = tab.Indicator:FindFirstChild("DuskShine_Gradient")
                if oldGrad then oldGrad:Destroy() end
                
                -- Моментально гасим цвет в серый, чтобы не было шлейфов
                tab.Indicator.BackgroundColor3 = Library.CurrentTheme.SubText
                tab.Icon.ImageColor3 = Library.CurrentTheme.SubText
                
                -- Скрываем
                Library.Utils.TBT(tab.Icon, 0.2, {Size = UDim2.new(1, 0, 1, 0), Rotation = 0})
                Library.Utils.TBT(tab.Indicator, 0.2, {BackgroundTransparency = 1})
            end
        end
    end

    -- Метод создания вкладки (теперь вызывается как Window:CreateTab)
    function Window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or "Unknown"
        local tabIcon = tabConfig.Icon or "18957829775"

        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, -4, 1, -15); Page.Position = UDim2.new(0, 0, 0, 5)
        Page.BackgroundTransparency = 1; Page.BorderSizePixel = 0; Page.ScrollBarThickness = 2 
        Page.ScrollBarImageTransparency = 0.2; Page.Visible = false; Page.Parent = self.PagesContainer
        Page.AutomaticCanvasSize = Enum.AutomaticSize.None
        
        Library.ThemeObjects[Page] = { ScrollBarImageColor3 = "SubText" }
        Page.ScrollBarImageColor3 = Library.CurrentTheme.SubText
        
        local Layout = Instance.new("UIListLayout", Page)
        Layout.Padding = UDim.new(0, 12); Layout.SortOrder = Enum.SortOrder.LayoutOrder
        local Pad = Instance.new("UIPadding", Page)
        Pad.PaddingTop = UDim.new(0, 10); Pad.PaddingLeft = UDim.new(0, 25); Pad.PaddingRight = UDim.new(0, 25); Pad.PaddingBottom = UDim.new(0, 15)

        -- ЖЕСТКАЯ МАТЕМАТИКА СКРОЛЛА (Ни пикселем больше)
        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 25)
        end)

        local Btn = Instance.new("ImageButton", self.TabsContainer)
        Btn.Size = UDim2.new(0, 32, 0, 32); Btn.BackgroundTransparency = 1; Btn.AutoButtonColor = false

        local TabIconObj = Instance.new("ImageLabel", Btn)
        TabIconObj.Size = UDim2.new(1, 0, 1, 0); TabIconObj.AnchorPoint = Vector2.new(0.5, 0.5); TabIconObj.Position = UDim2.new(0.5, 0, 0.5, 0)
        TabIconObj.BackgroundTransparency = 1; TabIconObj.Image = "rbxassetid://" .. tabIcon
        Library.ThemeObjects[TabIconObj] = { ImageColor3 = "SubText" }
        TabIconObj.ImageColor3 = Library.CurrentTheme.SubText

        local Ind = Library.Utils.Make("Frame", {
            Size = UDim2.new(0, 4, 0.5, 0), Position = UDim2.new(0, -10, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1, Parent = Btn,
            BackgroundColor3 = Library.CurrentTheme.SubText -- Сразу стартуем с серого!
        })
        -- Привязываем к серому по дефолту
        Library.ThemeObjects[Ind] = { BackgroundColor3 = "SubText" }
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Ind})

        -- 1. СНАЧАЛА ОБЪЯВЛЯЕМ ОБЪЕКТ ВКЛАДКИ
        local Tab = {
            Name = tabName,
            Page = Page,
            Btn = Btn,
            Icon = TabIconObj,
            Indicator = Ind
        }
        table.insert(self.Tabs, Tab)

        -- 2. И ТОЛЬКО ПОТОМ ВЕШАЕМ КЛИК (теперь он видит переменную Tab)
        Btn.MouseButton1Click:Connect(function()
            Window:SelectTab(Tab)
        end)
        
        table.insert(self.Tabs, Tab)

        function Tab:CreateButton(config)
            config = config or {}
            local btnText = config.Name or "Button"
            local callback = config.Callback or function() end
            
            local B = Library.Utils.Make("TextButton", {
                Size = UDim2.new(1, 0, 0, 45), Text = btnText, FontFace = MainFont, TextSize = 14,
                AutoButtonColor = false, Parent = Page
            }, { BackgroundColor3 = "Section", TextColor3 = "Text" })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 10), Parent = B})
            
            local Str = Library.Utils.Make("UIStroke", {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1.5, Transparency = 0.4, Parent = B}, {Color = "Accent"})
            local btnScale = Instance.new("UIScale", B)
            
            -- Используем наш безопасный коннект
            Library:Connect(B.MouseEnter, function() Library.Utils.TBT(Str, 0.25, {Transparency = 0, Thickness = 2}) end)
            Library:Connect(B.MouseLeave, function() Library.Utils.TBT(Str, 0.25, {Transparency = 0.4, Thickness = 1.5}) end)
            
            Library:Connect(B.MouseButton1Click, function()
                local t1 = Library.Utils.TBT(btnScale, 0.1, {Scale = 0.96}, Enum.EasingStyle.Sine)
                t1.Completed:Connect(function() Library.Utils.TBT(btnScale, 0.2, {Scale = 1}, Enum.EasingStyle.Bounce) end)
                pcall(callback)
            end)
            
            return B
        end

        function Tab:CreateCopyLink(config)
            local name = config.Name or "Link"
            local url = config.Url or ""
            
            local notifyIcon = config.NotifyIcon or "10723426722"
            local notifyLogo = config.NotifyLogo or "72958619361915"

            -- Используем 3-й аргумент для привязки к теме
            local F = Library.Utils.Make("Frame", {
                Size = UDim2.new(1, 0, 0, 46),
                Parent = Page
            }, { BackgroundColor3 = "Section" })
            
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 8), Parent = F})
            local FStroke = Library.Utils.Make("UIStroke", {Thickness = 1, Parent = F}, {Color = "Stroke"})

            local Btn = Library.Utils.Make("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = F
            })

            -- Заголовок привязываем к "Text"
            Library.Utils.Make("TextLabel", {
                Text = name,
                Size = UDim2.new(1, -45, 0, 16),
                Position = UDim2.new(0, 14, 0, 8),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = F
            }, { TextColor3 = "Text" })

            -- Ссылку привязываем к "SubText"
            Library.Utils.Make("TextLabel", {
                Text = url,
                Size = UDim2.new(1, -45, 0, 14),
                Position = UDim2.new(0, 14, 0, 26),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = F
            }, { TextColor3 = "SubText" })

            -- Иконку привязываем к "SubText"
            local Icon = Library.Utils.Make("ImageLabel", {
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(1, -30, 0.5, -9),
                BackgroundTransparency = 1,
                Image = "rbxassetid://10827393433", 
                Parent = F
            }, { ImageColor3 = "SubText" })

            -- Анимации при наведении (Перекрашиваем в Акцентный цвет)
            Library:Connect(Btn.MouseEnter, function() 
                Library.Utils.TBT(FStroke, 0.25, {Color = Library.CurrentTheme.Accent})
                Library.Utils.TBT(Icon, 0.25, {ImageColor3 = Library.CurrentTheme.Accent})
            end)
            
            Library:Connect(Btn.MouseLeave, function() 
                Library.Utils.TBT(FStroke, 0.25, {Color = Library.CurrentTheme.Stroke})
                Library.Utils.TBT(Icon, 0.25, {ImageColor3 = Library.CurrentTheme.SubText})
            end)

            Library:Connect(Btn.MouseButton1Click, function()
                Library.Utils.CreateRipple(F)
                
                if setclipboard then
                    pcall(function() setclipboard(url) end)
                    
                    if Library and Library.Notify then
                        Library:Notify(
                            "Link Copied!", 
                            "Copied " .. name .. " to clipboard.", 
                            3, 
                            notifyIcon, 
                            notifyLogo
                        )
                    end
                else
                    if Library and Library.Notify then
                        Library:Notify("Error", "Your executor doesn't support clipboard copying.", 4)
                    end
                end
            end)

            return F
        end

        function Tab:CreateToggle(config)
            config = config or {}
            local title = config.Name or "Toggle"
            local desc = config.Description or ""
            local default = config.Default or false
            local flag = config.Flag or title:gsub("%s+", "")
            local callback = config.Callback or function() end
            
            -- КАСТОМНЫЙ АРГУМЕНТ: Функция для шестеренки
            local settingsCallback = config.Settings 

            Library.Flags[flag] = default
            Library.ConfigUpdaters[flag] = function(val) SetState(val) end

            local F = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0, 70), Parent = Page }, { BackgroundColor3 = "Section" })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 10), Parent = F})
            Library.Utils.Make("UIStroke", {Thickness = 1, Parent = F}, {Color = "Stroke"})

            Library.Utils.Make("TextLabel", { Text = title, Size = UDim2.new(1, -70, 0, 20), Position = UDim2.new(0, 20, 0, 15), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Parent = F }, { TextColor3 = "Text" })
            Library.Utils.Make("TextLabel", { Text = desc, Size = UDim2.new(1, -90, 0, 15), Position = UDim2.new(0, 20, 0, 38), BackgroundTransparency = 1, FontFace = MainFont, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = F }, { TextColor3 = "SubText" })

            local Sw = Library.Utils.Make("TextButton", { Text = "", Size = UDim2.new(0, 48, 0, 26), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -20, 0.5, 0), Parent = F }, { BackgroundColor3 = default and "Accent" or "ToggleOff" })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1,0), Parent = Sw})

            local OnP = UDim2.new(1, -23, 0.5, 0); local OffP = UDim2.new(0, 3, 0.5, 0)
            local Kn = Library.Utils.Make("Frame", { Size = UDim2.new(0, 20, 0, 20), AnchorPoint = Vector2.new(0, 0.5), Position = default and OnP or OffP, Parent = Sw }, { BackgroundColor3 = "Knob" })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1,0), Parent = Kn})

            -- === ЛОГИКА ШЕСТЕРЕНКИ ===
            if settingsCallback then
                local Gear = Library.Utils.Make("ImageButton", {
                    Size = UDim2.new(0, 20, 0, 20), AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -80, 0.5, 0), BackgroundTransparency = 1,
                    Image = "rbxassetid://7734053495", Parent = F
                })
                Library.ThemeObjects[Gear] = { ImageColor3 = "SubText" }
                Gear.ImageColor3 = Library.CurrentTheme.SubText
                
                local gearScale = Instance.new("UIScale", Gear)
                
                Library:Connect(Gear.MouseEnter, function()
                    Library.Utils.TBT(gearScale, 0.2, {Scale = 1.15})
                    Library.Utils.TBT(Gear, 0.2, {ImageColor3 = Library.CurrentTheme.Accent})
                end)
                Library:Connect(Gear.MouseLeave, function()
                    Library.Utils.TBT(gearScale, 0.2, {Scale = 1})
                    Library.Utils.TBT(Gear, 0.2, {ImageColor3 = Library.CurrentTheme.SubText})
                end)
                Library:Connect(Gear.MouseButton1Click, function()
                    Library.Utils.CreateRipple(Gear)
                    local t = Library.Utils.TBT(gearScale, 0.1, {Scale = 0.85})
                    t.Completed:Connect(function() Library.Utils.TBT(gearScale, 0.2, {Scale = 1}, Enum.EasingStyle.Bounce) end)
                    pcall(settingsCallback)
                end)
            end

            local function SetState(newState)
                if Library.Flags[flag] == newState then return end
                Library.Flags[flag] = newState
                
                Library.ThemeObjects[Sw]["BackgroundColor3"] = newState and "Accent" or "ToggleOff"
                local tCol = newState and Library.CurrentTheme.Accent or Library.CurrentTheme.ToggleOff
                
                Library.Utils.TBT(Sw, 0.25, {BackgroundColor3 = tCol})
                Library.Utils.TBT(Kn, 0.25, {Position = newState and OnP or OffP})
                
                pcall(callback, newState)
            end

            Library:Connect(Sw.MouseButton1Click, function() SetState(not Library.Flags[flag]) end)
            
            return { 
                Container = F, -- Возвращаем САМ ФРЕЙМ для полного хардкора (см. Уровень 2)
                SetState = SetState,
                GetValue = function() return Library.Flags[flag] end
            }
        end

        function Tab:CreateSubPage(config)
            config = config or {}
            local title = config.Name or "Sub Page"
            
            -- Создаем главный контейнер поверх текущей вкладки (Page)
            local SubPageUI = Library.Utils.Make("CanvasGroup", {
                Name = "CustomSubPage_" .. title:gsub("%s+", ""),
                Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 20),
                BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = 1,
                Visible = false, ZIndex = 100, Parent = Page
            })

            local TopBar = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = SubPageUI })

            -- Кнопка "Назад"
            local CloseSelBtn = Library.Utils.Make("TextButton", { Text = "➖", Size = UDim2.new(0, 34, 0, 34), Position = UDim2.new(1, -10, 0, 10), AnchorPoint = Vector2.new(1, 0), Font = Enum.Font.GothamBold, TextSize = 14, Parent = TopBar }, { BackgroundColor3 = "Section", TextColor3 = "SubText" })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 6), Parent = CloseSelBtn})
            Library.Utils.Make("UIStroke", {Parent = CloseSelBtn}, {Color = "Stroke"})
            
            local scaleClose = Instance.new("UIScale", CloseSelBtn)
            Library:Connect(CloseSelBtn.MouseEnter, function() Library.Utils.TBT(scaleClose, 0.2, {Scale = 1.05}) end)
            Library:Connect(CloseSelBtn.MouseLeave, function() Library.Utils.TBT(scaleClose, 0.2, {Scale = 1}) end)

            -- Заголовок SubPage
            Library.Utils.Make("TextLabel", { Text = title, Size = UDim2.new(1, -60, 0, 20), Position = UDim2.new(0, 15, 0, 17), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Parent = SubPageUI }, { TextColor3 = "Text" })

            -- САМОЕ ВАЖНОЕ: Тот самый пустой холст (Container), куда игровой модуль будет совать свои кнопки
            local Scroll = Library.Utils.Make("ScrollingFrame", { Size = UDim2.new(1, 0, 1, -50), Position = UDim2.new(0, 0, 0, 50), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = SubPageUI }, { ScrollBarImageColor3 = "SubText" })
            
            Library.Utils.Make("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Scroll })
            Library.Utils.Make("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 15), Parent = Scroll })

            local hiddenElements = {}
            local isClosing = false
            local savedCanvasPos = Vector2.new(0,0)

            local function Close()
                if isClosing or not SubPageUI.Visible then return end
                isClosing = true
                
                Library.Utils.TBT(SubPageUI, 0.25, {GroupTransparency = 1, Position = UDim2.new(0, 0, 0, 20)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                
                task.delay(0.25, function()
                    SubPageUI.Visible = false
                    -- Возвращаем видимость всем элементам родительской вкладки
                    for _, child in ipairs(hiddenElements) do
                        if child then child.Visible = true end
                    end
                    hiddenElements = {}
                    Page.ScrollingEnabled = true
                    Page.CanvasPosition = savedCanvasPos
                    isClosing = false
                end)
            end

            Library:Connect(CloseSelBtn.MouseButton1Click, function()
                local t = Library.Utils.TBT(scaleClose, 0.1, {Scale = 0.85}, Enum.EasingStyle.Sine)
                t.Completed:Connect(function() Library.Utils.TBT(scaleClose, 0.2, {Scale = 1}, Enum.EasingStyle.Bounce) end)
                Close()
            end)

            -- Авто-закрытие, если юзер переключил вкладку в боковом меню
            Library:Connect(Page:GetPropertyChangedSignal("Visible"), function()
                if not Page.Visible and SubPageUI.Visible then
                    isClosing = false
                    SubPageUI.Visible = false
                    SubPageUI.GroupTransparency = 1
                    SubPageUI.Position = UDim2.new(0, 0, 0, 20)
                    
                    for _, child in ipairs(hiddenElements) do
                        if child then child.Visible = true end
                    end
                    hiddenElements = {}
                    Page.ScrollingEnabled = true
                    Page.CanvasPosition = savedCanvasPos
                end
            end)

            local function Open()
                if SubPageUI.Visible then return end 
                isClosing = false
                hiddenElements = {}
                
                -- Прячем все обычные элементы вкладки, чтобы показать SubPage
                for _, child in ipairs(Page:GetChildren()) do
                    if child:IsA("GuiObject") and child.Visible and child ~= SubPageUI and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
                        table.insert(hiddenElements, child)
                        child.Visible = false
                    end
                end
                
                savedCanvasPos = Page.CanvasPosition
                Page.ScrollingEnabled = false
                Page.CanvasPosition = Vector2.new(0, 0)
                
                SubPageUI.GroupTransparency = 1
                SubPageUI.Position = UDim2.new(0, 0, 0, 20)
                SubPageUI.Visible = true
                Library.Utils.TBT(SubPageUI, 0.35, {GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Quint)
            end

            return {
                Container = Scroll, -- Экспортируем пустой холст!
                Open = Open,
                Close = Close
            }
        end

        function Tab:CreateSlider(config)
            config = config or {}
            local title = config.Name or "Slider"
            local min = config.Min or 0
            local max = config.Max or 100
            local default = config.Default or min
            local flag = config.Flag or title:gsub("%s+", "")
            local callback = config.Callback or function() end

            Library.Flags[flag] = default

            local F = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0, 60), Parent = Page }, { BackgroundColor3 = "Section" })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 10), Parent = F})

            Library.Utils.Make("TextLabel", { Text = title, Size = UDim2.new(1, -30, 0, 20), Position = UDim2.new(0, 15, 0, 10), BackgroundTransparency = 1, FontFace = MainFont, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = F }, { TextColor3 = "Text" })
            
            local ValText = Library.Utils.Make("TextLabel", { Text = tostring(default), Size = UDim2.new(0, 50, 0, 20), Position = UDim2.new(1, -65, 0, 10), BackgroundTransparency = 1, FontFace = MainFont, TextSize = 14, Parent = F }, { TextColor3 = "SubText" })

            local SliderBG = Library.Utils.Make("Frame", { Size = UDim2.new(1, -30, 0, 6), Position = UDim2.new(0, 15, 0, 40), Parent = F }, { BackgroundColor3 = "Sidebar" })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = SliderBG})

            local fillPct = math.clamp((default - min) / (max - min), 0, 1)
            local SliderFill = Library.Utils.Make("Frame", { Size = UDim2.new(fillPct, 0, 1, 0), Parent = SliderBG }, { BackgroundColor3 = "Accent" })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = SliderFill})

            local Trigger = Library.Utils.Make("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = SliderBG })

            local dragging = false

            local function Update(input)
                local pos = UDim2.new(math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1), 0, 1, 0)
                SliderFill.Size = pos
                local val = math.floor(min + ((max - min) * pos.X.Scale))
                ValText.Text = tostring(val)
                
                if Library.Flags[flag] ~= val then
                    Library.Flags[flag] = val
                    pcall(callback, val)
                end
            end

            Library:Connect(Trigger.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    Update(input)
                end
            end)

            Library:Connect(UserInputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            Library:Connect(UserInputService.InputChanged, function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    Update(input)
                end
            end)

           local function UpdateSliderValue(newVal)
                newVal = math.clamp(newVal, min, max)
                Library.Flags[flag] = newVal
                ValText.Text = tostring(newVal)
                SliderFill.Size = UDim2.new((newVal - min) / (max - min), 0, 1, 0)
                pcall(callback, newVal)
            end

            -- 2. Регистрируем её в ядре (чтобы при загрузке JSON ползунок сам передвинулся)
            Library.ConfigUpdaters[flag] = UpdateSliderValue

            -- 3. Возвращаем таблицу для использования в скрипте игры
            return {
                SetValue = UpdateSliderValue, -- Ссылаемся на нашу функцию
                GetValue = function() return Library.Flags[flag] end
            }
        end

        function Tab:CreateDropdown(config)
            config = config or {}
            local title = config.Name or "Dropdown"
            local options = config.Options or {}
            local default = config.Default or options[1] or "Select..."
            local flag = config.Flag or title:gsub("%s+", "")
            local callback = config.Callback or function() end

            Library.Flags[flag] = default

            local Frame = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = Page })
            
            Library.Utils.Make("TextLabel", { Text = title, Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Frame }, { TextColor3 = "Text" })

            local Btn = Library.Utils.Make("TextButton", { Text = tostring(default), Size = UDim2.new(0.48, 0, 0, 30), Position = UDim2.new(0.52, 0, 0.5, -15), Font = Enum.Font.Gotham, TextSize = 12, Parent = Frame }, { BackgroundColor3 = "Sidebar", TextColor3 = "Text" })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 6), Parent = Btn})
            Library.Utils.Make("UIStroke", {Parent = Btn}, {Color = "Stroke"})

            local Container = Library.Utils.Make("ScrollingFrame", { Size = UDim2.new(0.48, 0, 0, 0), Position = UDim2.new(0.52, 0, 0.5, 18), ZIndex = 15, ScrollBarThickness = 2, Visible = false, Parent = Frame }, { BackgroundColor3 = "Section" })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 6), Parent = Container})
            Library.Utils.Make("UIStroke", {Parent = Container}, {Color = "Stroke"})

            local isOpen = false

            local function Close()
                isOpen = false
                Container.Visible = false
                Container.Size = UDim2.new(0.48, 0, 0, 0)
            end

            local function Refresh(newOptions)
                options = newOptions or options
                for _, child in ipairs(Container:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end

                local ySize = 0
                for _, option in ipairs(options) do
                    local optBtn = Library.Utils.Make("TextButton", { Text = tostring(option), Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 0, 0, ySize), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 12, ZIndex = 16, Parent = Container }, { TextColor3 = "SubText" })
                    
                    Library:Connect(optBtn.MouseButton1Click, function()
                        Btn.Text = tostring(option)
                        Library.Flags[flag] = option
                        Close()
                        pcall(callback, option)
                    end)
                    ySize = ySize + 25
                end
                
                Container.CanvasSize = UDim2.new(0, 0, 0, ySize)
                if isOpen then Container.Size = UDim2.new(0.48, 0, 0, math.min(ySize, 150)) end
            end

            Library:Connect(Btn.MouseButton1Click, function()
                isOpen = not isOpen
                if isOpen then
                    Refresh()
                    Container.Visible = true
                    Container.Size = UDim2.new(0.48, 0, 0, math.min(Container.CanvasSize.Y.Offset, 150))
                else
                    Close()
                end
            end)

            Refresh()

            local function SetDropdownValue(option)
                Btn.Text = tostring(option)
                Library.Flags[flag] = option
                pcall(callback, option)
            end
            
            -- Регистрируем апдейтер для конфиг-системы
            Library.ConfigUpdaters[flag] = SetDropdownValue

            return {
                SetValue = SetDropdownValue,
                Refresh = Refresh,
                GetValue = function() return Library.Flags[flag] end
            }
        end

        -- ==========================================
        -- КЛАВИША БИНДА (KEYBIND)
        -- ==========================================
        function Tab:CreateKeybind(config)
            config = config or {}
            local title = config.Name or "Keybind"
            local default = config.Default or Enum.KeyCode.Unknown
            local flag = config.Flag or title:gsub("%s+", "")
            local callback = config.Callback or function() end

            Library.Flags[flag] = default

            local F = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0, 60), Parent = Page }, { BackgroundColor3 = "Section" })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 10), Parent = F})

            Library.Utils.Make("TextLabel", { Text = title, Size = UDim2.new(1, -100, 0, 20), Position = UDim2.new(0, 15, 0.5, -10), BackgroundTransparency = 1, FontFace = MainFont, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = F }, { TextColor3 = "Text" })

            local BindBtn = Library.Utils.Make("TextButton", { Size = UDim2.new(0, 80, 0, 34), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -15, 0.5, 0), FontFace = MainFont, TextSize = 13, AutoButtonColor = false, Text = default.Name or "None", Parent = F }, { BackgroundColor3 = "Sidebar", TextColor3 = "SubText" })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 8), Parent = BindBtn})
            Library.Utils.Make("UIStroke", {Thickness = 1, Parent = BindBtn}, {Color = "Stroke"})

            local listening = false
            local tempConnection -- Временный коннект для ожидания клавиши

            -- Основной клик по кнопке (перманентный, используем Library:Connect)
            Library:Connect(BindBtn.MouseButton1Click, function()
                if listening then return end
                listening = true
                BindBtn.Text = "..."
                Library.Utils.TBT(BindBtn, 0.2, {TextColor3 = Library.CurrentTheme.Accent})

                -- Временный коннект (мы не кидаем его в ядро, так как сами его тут же убиваем)
                tempConnection = UserInputService.InputBegan:Connect(function(input)
                    local isKey = input.UserInputType == Enum.UserInputType.Keyboard
                    local isMouse = input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3

                    if isKey or isMouse then
                        local newKey = isKey and input.KeyCode or input.UserInputType
                        
                        -- Если нажали Escape, сбрасываем бинд
                        if newKey == Enum.KeyCode.Escape then
                            newKey = Enum.KeyCode.Unknown
                        end

                        Library.Flags[flag] = newKey
                        BindBtn.Text = newKey.Name
                        listening = false
                        Library.Utils.TBT(BindBtn, 0.2, {TextColor3 = Library.CurrentTheme.SubText})
                        
                        pcall(callback, newKey)

                        -- Моментально убиваем коннект после нажатия (0 утечек!)
                        if tempConnection then tempConnection:Disconnect() end
                    end
                end)
            end)

            local function SetKeybindValue(newKey)
                Library.Flags[flag] = newKey
                BindBtn.Text = newKey and newKey.Name or "None"
                pcall(callback, newKey)
            end

            Library.ConfigUpdaters[flag] = SetKeybindValue

            return {
                SetValue = SetKeybindValue,
                GetValue = function() return Library.Flags[flag] end
            }
        end

        function Tab:CreateColorPicker(config)
            config = config or {}
            local title = config.Name or "Color Picker"
            local default = config.Default or Color3.new(1, 1, 1)
            local flag = config.Flag or title:gsub("%s+", "")
            local callback = config.Callback or function() end

            Library.Flags[flag] = default

            local F = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0, 70), Parent = Page }, { BackgroundColor3 = "Section" })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 10), Parent = F})

            Library.Utils.Make("TextLabel", { Text = title, Size = UDim2.new(1, -70, 0, 20), Position = UDim2.new(0, 15, 0, 10), BackgroundTransparency = 1, FontFace = MainFont, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = F }, { TextColor3 = "Text" })

            local ColorPreview = Library.Utils.Make("Frame", { Size = UDim2.new(0, 40, 0, 20), Position = UDim2.new(1, -55, 0, 10), BackgroundColor3 = default, Parent = F })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 6), Parent = ColorPreview})

            local Bar = Library.Utils.Make("ImageButton", { Size = UDim2.new(1, -30, 0, 15), Position = UDim2.new(0, 15, 0, 40), BackgroundColor3 = Color3.new(1,1,1), AutoButtonColor = false, Parent = F })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 4), Parent = Bar})

            local Grad = Instance.new("UIGradient")
            Grad.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
            }
            Grad.Parent = Bar

            local h, s, v = default:ToHSV()
            local Selector = Library.Utils.Make("Frame", { Size = UDim2.new(0, 4, 1, 4), Position = UDim2.new(h, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1,1,1), BorderColor3 = Color3.new(0,0,0), BorderSizePixel = 1, Parent = Bar })

            local dragging = false

            local function UpdateColor(input)
                local r = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                Selector.Position = UDim2.new(r, 0, 0.5, 0)
                local col = Color3.fromHSV(r, 1, 1)
                ColorPreview.BackgroundColor3 = col
                
                if Library.Flags[flag] ~= col then
                    Library.Flags[flag] = col
                    pcall(callback, col)
                end
            end

            Library:Connect(Bar.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    UpdateColor(input)
                end
            end)

            Library:Connect(UserInputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            Library:Connect(UserInputService.InputChanged, function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateColor(input)
                end
            end)

            local function SetColorValue(color)
                Library.Flags[flag] = color
                ColorPreview.BackgroundColor3 = color
                local hC = color:ToHSV()
                Selector.Position = UDim2.new(hC, 0, 0.5, 0)
                pcall(callback, color)
            end

            Library.ConfigUpdaters[flag] = SetColorValue

            return {
                SetValue = SetColorValue,
                GetValue = function() return Library.Flags[flag] end
            }
        end

        function Tab:CreateInput(config)
            config = config or {}
            local title = config.Name or "Input"
            local placeholder = config.Placeholder or "Type here..."
            local default = config.Default or ""
            local flag = config.Flag or title:gsub("%s+", "")
            local clearOnFocus = config.ClearTextOnFocus or false
            local callback = config.Callback or function() end

            Library.Flags[flag] = default

            local F = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0, 60), Parent = Page }, { BackgroundColor3 = "Section" })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 10), Parent = F})

            Library.Utils.Make("TextLabel", { Text = title, Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, FontFace = MainFont, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = F }, { TextColor3 = "Text" })

            local BoxBG = Library.Utils.Make("Frame", { Size = UDim2.new(0.5, 0, 0, 34), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -15, 0.5, 0), Parent = F }, { BackgroundColor3 = "Sidebar" })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 8), Parent = BoxBG})

            local Box = Library.Utils.Make("TextBox", { Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, PlaceholderText = placeholder, Text = default, FontFace = MainFont, TextSize = 13, ClearTextOnFocus = clearOnFocus, Parent = BoxBG }, { TextColor3 = "Text", PlaceholderColor3 = "SubText" })

            -- Обработка завершения ввода (Нажатие Enter или клик вне поля)
            Library:Connect(Box.FocusLost, function(enterPressed)
                Library.Flags[flag] = Box.Text
                pcall(callback, Box.Text)
            end)

            local function SetInputValue(text)
                Box.Text = tostring(text)
                Library.Flags[flag] = Box.Text
                pcall(callback, Box.Text)
            end

            Library.ConfigUpdaters[flag] = SetInputValue

            return {
                SetValue = SetInputValue,
                GetValue = function() return Library.Flags[flag] end
            }
        end

        function Tab:CreateSection(config)
            config = config or {}
            local text = config.Name or "Section"

            local S = Library.Utils.Make("TextLabel", {
                Text = text, Size = UDim2.new(1, 0, 0, 35), BackgroundTransparency = 1,
                FontFace = MainFont, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Page
            }, { TextColor3 = "SubText" })
            Library.Utils.Make("UIPadding", {PaddingTop = UDim.new(0, 15), Parent = S})
            
            return { SetText = function(newText) S.Text = newText end }
        end

        function Tab:CreateDivider(config)
            config = config or {}
            local text = config.Text or ""

            local Container = Library.Utils.Make("Frame", { 
                Size = UDim2.new(1, 0, 0, 30), 
                BackgroundTransparency = 1, 
                Parent = Page 
            })

            local Layout = Library.Utils.Make("UIListLayout", { 
                FillDirection = Enum.FillDirection.Horizontal, 
                VerticalAlignment = Enum.VerticalAlignment.Center, 
                HorizontalAlignment = Enum.HorizontalAlignment.Center, 
                Padding = UDim.new(0, 12), 
                SortOrder = Enum.SortOrder.LayoutOrder, 
                Parent = Container 
            })

            -- Левая линия (Градиент от прозрачного к цвету)
            local LeftLine = Library.Utils.Make("Frame", { 
                LayoutOrder = 1, 
                Size = UDim2.new(0.35, 0, 0, 1), 
                BorderSizePixel = 0,
                Parent = Container 
            }, { BackgroundColor3 = "Stroke" })
            
            local LGrad = Instance.new("UIGradient", LeftLine)
            LGrad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0)
            })

            -- Текст по центру
            local Txt = Library.Utils.Make("TextLabel", { 
                LayoutOrder = 2, 
                Text = text, 
                AutomaticSize = Enum.AutomaticSize.X, 
                Size = UDim2.new(0, 0, 1, 0), 
                BackgroundTransparency = 1, 
                Font = Enum.Font.GothamMedium, 
                TextSize = 12, 
                Parent = Container 
            }, { TextColor3 = "SubText" })

            -- Правая линия (Градиент от цвета к прозрачному)
            local RightLine = Library.Utils.Make("Frame", { 
                LayoutOrder = 3, 
                Size = UDim2.new(0.35, 0, 0, 1), 
                BorderSizePixel = 0,
                Parent = Container 
            }, { BackgroundColor3 = "Stroke" })

            local RGrad = Instance.new("UIGradient", RightLine)
            RGrad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1)
            })

            return {
                SetText = function(newText) Txt.Text = newText end
            }
        end

        function Tab:CreateLabel(config)
            config = config or {}
            local text = config.Text or "Label"
            local iconStr = config.Icon

            local F = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = Page })
            Library.Utils.Make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = F })
            Library.Utils.Make("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), Parent = F })

            if iconStr and iconStr ~= "" then
                local Icon = Library.Utils.Make("ImageLabel", { LayoutOrder = 1, Size = UDim2.new(0, 26, 0, 26), BackgroundTransparency = 1, Parent = F })
                
                if iconStr == "avatar" then
                    Icon.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
                    Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = Icon})
                    Library.Utils.Make("UIStroke", {Parent = Icon}, {Color = "Stroke"})
                    
                    local A_Letter = Library.Utils.Make("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "A", Font = Enum.Font.GothamBold, TextSize = 14, Visible = Library.Settings.AnonymousMode, Parent = Icon }, { TextColor3 = "Accent" })
                    
                    if Library.Settings.AnonymousMode then 
                        Icon.ImageTransparency = 1; Icon.BackgroundColor3 = Color3.new(0,0,0); Icon.BackgroundTransparency = 0 
                    end
                    table.insert(Library.AnonItems.Avatars, {ImageObj = Icon, Letter = A_Letter})
                else
                    Icon.Image = iconStr
                    Library.ThemeObjects[Icon] = { ImageColor3 = "Accent" }
                    Icon.ImageColor3 = Library.CurrentTheme.Accent
                end
            end

            local T = Library.Utils.Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, (iconStr and iconStr ~= "") and -38 or 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, FontFace = MainFont, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = true, RichText = true, Parent = F }, { TextColor3 = "Text" })

            if iconStr == "avatar" then
                local formatStr = text:gsub(LocalPlayer.DisplayName, "%%s")
                table.insert(Library.AnonItems.Names, {Obj = T, Format = formatStr})
                T.Text = string.format(formatStr, Library.Settings.AnonymousMode and "Hidden User" or LocalPlayer.DisplayName)
            else
                T.Text = text
            end

            return { SetText = function(newText) T.Text = newText end }
        end

        function Tab:CreateNotice(config)
            config = config or {}
            local text = config.Text or "Notice"

            -- Делаем солидный фон с легким красноватым tint'ом вместо дешевой прозрачности
            local F = Library.Utils.Make("Frame", { 
                Size = UDim2.new(1, 0, 0, 0), 
                AutomaticSize = Enum.AutomaticSize.Y, 
                BackgroundTransparency = 0, 
                Parent = Page 
            }, { BackgroundColor3 = "Section" })
            F.BackgroundColor3 = Color3.fromRGB(32, 24, 24) 

            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 6), Parent = F})
            Library.Utils.Make("UIStroke", {Thickness = 1, Transparency = 0.3, Parent = F}, {Color = "Red"})
            
            -- Жесткие внутренние отступы
            Library.Utils.Make("UIPadding", {
                PaddingTop = UDim.new(0, 10), 
                PaddingBottom = UDim.new(0, 10), 
                PaddingLeft = UDim.new(0, 12), 
                PaddingRight = UDim.new(0, 12), 
                Parent = F
            })

            -- Левая акцентная линия, привязанная прямо к краю
            local LeftLine = Library.Utils.Make("Frame", { 
                Size = UDim2.new(0, 3, 1, 0), 
                Position = UDim2.new(0, -12, 0, 0), -- Компенсируем UIPadding
                BorderSizePixel = 0, 
                Parent = F 
            }, { BackgroundColor3 = "Red" })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 6), Parent = LeftLine})

            -- Иконка и текст с динамическим выравниванием
            Library.Utils.Make("ImageLabel", { 
                Size = UDim2.new(0, 16, 0, 16), 
                Position = UDim2.new(0, 4, 0, 1), 
                BackgroundTransparency = 1, 
                Image = "rbxassetid://11877677509", 
                Parent = F 
            }, { ImageColor3 = "Red" })

            local T = Library.Utils.Make("TextLabel", { 
                Text = text, 
                Size = UDim2.new(1, -26, 0, 0), 
                Position = UDim2.new(0, 26, 0, 0), 
                AutomaticSize = Enum.AutomaticSize.Y, 
                BackgroundTransparency = 1, 
                FontFace = MainFont, 
                TextSize = 12, 
                TextWrapped = true, 
                TextXAlignment = Enum.TextXAlignment.Left, 
                TextYAlignment = Enum.TextYAlignment.Top, 
                RichText = true, 
                Parent = F 
            }, { TextColor3 = "Text" })

            return { SetText = function(newText) T.Text = newText end }
        end

        function Tab:CreateShopGrid(config)
            config = config or {}
            local items = config.Items or {}
            local callback = config.Callback or function() end

            local Container = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = Page })
            Library.Utils.Make("UIGridLayout", { CellSize = UDim2.new(0.48, 0, 0, 130), CellPadding = UDim2.new(0.04, 0, 0, 18), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Container })

            for _, item in ipairs(items) do
                local Tile = Library.Utils.Make("TextButton", { Text = "", AutoButtonColor = false, ClipsDescendants = false, Parent = Container }, { BackgroundColor3 = "Section" })
                Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 14), Parent = Tile})

                local RippleContainer = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 10, Parent = Tile })
                Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 14), Parent = RippleContainer})

                local AccentLine = Library.Utils.Make("Frame", { Size = UDim2.new(0.6, 0, 0, 3), Position = UDim2.new(0.5, 0, 0, -8), AnchorPoint = Vector2.new(0.5, 1), BorderSizePixel = 0, ZIndex = 5, Parent = Tile }, { BackgroundColor3 = "Accent" })
                Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = AccentLine})

                local Icon = Library.Utils.Make("ImageLabel", { Size = UDim2.new(0, 70, 0, 70), Position = UDim2.new(0.5, 0, 0, 15), AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1, ZIndex = 1, ScaleType = Enum.ScaleType.Fit, Image = item.Image or "rbxassetid://0", ImageColor3 = Color3.fromRGB(220, 220, 220), Parent = Tile })

                local GradFrame = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0.7, 0), Position = UDim2.new(0, 0, 1, 0), AnchorPoint = Vector2.new(0, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = Tile })
                local Grad = Instance.new("UIGradient")
                Grad.Rotation = 90; Grad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.1)}); Grad.Color = ColorSequence.new(Color3.new(0,0,0))
                Grad.Parent = GradFrame

                local NameLbl = Library.Utils.Make("TextLabel", { Text = item.Name:upper(), Size = UDim2.new(1, -10, 0, 20), Position = UDim2.new(0.5, 0, 1, -5), AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3, Parent = Tile })
                Library.Utils.Make("UIStroke", {Thickness = 1.5, Transparency = 0.4, Parent = NameLbl})

                local PriceLbl = Library.Utils.Make("TextLabel", { Text = item.Price, Size = UDim2.new(1, -10, 0, 15), Position = UDim2.new(0.5, 0, 1, -22), AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 12, ZIndex = 3, Parent = Tile })
                if item.Price == "FREE" then PriceLbl.TextColor3 = Color3.fromRGB(46, 204, 113) else Library.ThemeObjects[PriceLbl] = {TextColor3 = "Accent"}; PriceLbl.TextColor3 = Library.CurrentTheme.Accent end
                Library.Utils.Make("UIStroke", {Thickness = 1, Transparency = 0.5, Parent = PriceLbl})

                if item.VipOnly then
                    local VipLbl = Library.Utils.Make("TextLabel", { Text = "(Only for VIP)", Size = UDim2.new(1, -10, 0, 12), Position = UDim2.new(0.5, 0, 1, -38), AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255, 215, 0), Font = Enum.Font.GothamBold, TextSize = 10, ZIndex = 3, Parent = Tile })
                    Library.Utils.Make("UIStroke", {Thickness = 1, Transparency = 0.5, Parent = VipLbl})
                end

                local Scale = Instance.new("UIScale", Tile)

                Library:Connect(Tile.MouseEnter, function()
                    Library.Utils.TBT(Icon, 0.4, {ImageColor3 = Color3.new(1, 1, 1), Size = UDim2.new(0, 80, 0, 80)}, Enum.EasingStyle.Quint)
                    Library.Utils.TBT(AccentLine, 0.3, {Size = UDim2.new(0.8, 0, 0, 4)})
                end)

                Library:Connect(Tile.MouseLeave, function()
                    Library.Utils.TBT(Icon, 0.4, {ImageColor3 = Color3.fromRGB(220, 220, 220), Size = UDim2.new(0, 70, 0, 70)}, Enum.EasingStyle.Quint)
                    Library.Utils.TBT(AccentLine, 0.3, {Size = UDim2.new(0.6, 0, 0, 3)})
                end)

                Library:Connect(Tile.MouseButton1Down, function() Library.Utils.TBT(Scale, 0.1, {Scale = 0.95}) end)

                Library:Connect(Tile.MouseButton1Click, function()
                    Library.Utils.TBT(Scale, 0.15, {Scale = 1}, Enum.EasingStyle.Bounce)
                    Library.Utils.CreateRipple(RippleContainer)
                    pcall(callback, item.Value or item.Name)
                end)
            end
        end

        -- ==========================================
        -- ТОГГЛ С РЕЖИМАМИ (TOGGLE WITH MODES)
        -- ==========================================
        function Tab:CreateModeToggle(config)
            config = config or {}
            local title = config.Name or "Mode Toggle"
            local desc = config.Description or ""
            local defaultState = config.DefaultState or false
            local modes = config.Modes or {} -- Ожидаем массив таблиц: {{Name = "Legit", Image = "..."}, {Name = "Rage", Image = "..."}}
            local defaultMode = config.DefaultMode or (modes[1] and modes[1].Name) or ""
            local flag = config.Flag or title:gsub("%s+", "")
            
            local toggleCallback = config.ToggleCallback or function() end
            local modeCallback = config.ModeCallback or function() end
            local settingsCallback = config.Settings

            -- Инициализация флагов в ядре
            Library.Flags[flag .. "_State"] = defaultState
            Library.Flags[flag .. "_Mode"] = defaultMode

            local F = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0, 70), BackgroundTransparency = 0.2, Parent = Page }, { BackgroundColor3 = "Section" })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 12), Parent = F})
            Library.Utils.Make("UIStroke", {Thickness = 1.5, Transparency = 0.6, Parent = F}, {Color = "Stroke"})

            Library.Utils.Make("TextLabel", { Text = title, Size = UDim2.new(1, -165, 0, 20), Position = UDim2.new(0, 20, 0, 15), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Parent = F }, { TextColor3 = "Text" })
            Library.Utils.Make("TextLabel", { Text = desc, Size = UDim2.new(1, -165, 0, 15), Position = UDim2.new(0, 20, 0, 38), BackgroundTransparency = 1, FontFace = MainFont, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = F }, { TextColor3 = "SubText" })

            local Sw = Library.Utils.Make("TextButton", { Text = "", Size = UDim2.new(0, 48, 0, 26), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -20, 0.5, 0), Parent = F }, { BackgroundColor3 = defaultState and "Accent" or "ToggleOff" })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1,0), Parent = Sw})

            local OnP = UDim2.new(1, -23, 0.5, 0); local OffP = UDim2.new(0, 3, 0.5, 0)
            local Kn = Library.Utils.Make("Frame", { Size = UDim2.new(0, 20, 0, 20), AnchorPoint = Vector2.new(0, 0.5), Position = defaultState and OnP or OffP, Parent = Sw }, { BackgroundColor3 = "Knob" })
            Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1,0), Parent = Kn})

            -- Создаем SubPage для режимов (Используем наш новый метод!)
            local ModesPage = self:CreateSubPage({ Name = title .. " Modes" })
            local Scroll = ModesPage.Container
            
            -- Удаляем стандартный ListLayout из SubPage и ставим Grid
            for _, child in ipairs(Scroll:GetChildren()) do if child:IsA("UIListLayout") then child:Destroy() end end
            Library.Utils.Make("UIGridLayout", { CellSize = UDim2.new(0, 160, 0, 140), CellPadding = UDim2.new(0, 15, 0, 15), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Scroll })

            local ModeCards = {}

            -- Генерация карточек режимов
            for _, modeData in ipairs(modes) do
                local Card = Library.Utils.Make("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Text = "", Parent = Scroll })
                Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 16), Parent = Card})
                local CardStroke = Library.Utils.Make("UIStroke", {Thickness = 4, Color = Color3.fromRGB(0, 0, 0), Parent = Card})

                local AccentLine = Library.Utils.Make("Frame", { Size = UDim2.new(0.8, 0, 0, 4), Position = UDim2.new(0.1, 0, 0, 12), BackgroundColor3 = Color3.fromRGB(150, 0, 0), BorderSizePixel = 0, Parent = Card })
                Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = AccentLine})

                Library.Utils.Make("ImageLabel", { Size = UDim2.new(0.8, 0, 0.5, 0), Position = UDim2.new(0.1, 0, 0.25, 0), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = modeData.Image or "", Parent = Card })
                Library.Utils.Make("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 1, -28), BackgroundTransparency = 1, Text = string.upper(modeData.Name), Font = Enum.Font.Bangers, TextSize = 22, TextColor3 = Color3.fromRGB(0, 0, 0), Parent = Card })

                ModeCards[modeData.Name] = CardStroke

                local cScale = Instance.new("UIScale", Card)
                Library:Connect(Card.MouseButton1Click, function()
                    Library.Flags[flag .. "_Mode"] = modeData.Name
                    
                    Library.Utils.TBT(cScale, 0.1, {Scale = 0.9}, Enum.EasingStyle.Sine)
                    task.delay(0.1, function() Library.Utils.TBT(cScale, 0.15, {Scale = 1}, Enum.EasingStyle.Bounce) end)

                    for name, stroke in pairs(ModeCards) do
                        stroke.Color = (name == modeData.Name) and Color3.fromRGB(220, 20, 20) or Color3.fromRGB(0, 0, 0)
                    end
                    pcall(modeCallback, modeData.Name)
                end)
            end

            -- Выделяем дефолтный режим
            if ModeCards[defaultMode] then ModeCards[defaultMode].Color = Color3.fromRGB(220, 20, 20) end

            -- Кнопка шестеренки
            local Gear = Library.Utils.Make("ImageButton", { Size = UDim2.new(0, 20, 0, 20), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -80, 0.5, 0), BackgroundTransparency = 1, Image = "rbxassetid://7734053495", Parent = F })
            Library.ThemeObjects[Gear] = { ImageColor3 = "SubText" }; Gear.ImageColor3 = Library.CurrentTheme.SubText
            local gearScale = Instance.new("UIScale", Gear)

            Library:Connect(Gear.MouseEnter, function() Library.Utils.TBT(gearScale, 0.2, {Scale = 1.15}); Library.Utils.TBT(Gear, 0.2, {ImageColor3 = Library.CurrentTheme.Accent}) end)
            Library:Connect(Gear.MouseLeave, function() Library.Utils.TBT(gearScale, 0.2, {Scale = 1}); Library.Utils.TBT(Gear, 0.2, {ImageColor3 = Library.CurrentTheme.SubText}) end)
            Library:Connect(Gear.MouseButton1Click, function()
                Library.Utils.CreateRipple(Gear)
                ModesPage:Open()
            end)

            -- Логика самого Тоггла
            local function SetState(newState)
                if Library.Flags[flag .. "_State"] == newState then return end
                Library.Flags[flag .. "_State"] = newState
                
                Library.ThemeObjects[Sw]["BackgroundColor3"] = newState and "Accent" or "ToggleOff"
                Library.Utils.TBT(Sw, 0.25, {BackgroundColor3 = newState and Library.CurrentTheme.Accent or Library.CurrentTheme.ToggleOff})
                Library.Utils.TBT(Kn, 0.25, {Position = newState and OnP or OffP})
                pcall(toggleCallback, newState)
            end

            Library:Connect(Sw.MouseButton1Click, function() SetState(not Library.Flags[flag .. "_State"]) end)
            
            return {
                Container = F,
                SetState = SetState,
                GetState = function() return Library.Flags[flag .. "_State"] end,
                GetMode = function() return Library.Flags[flag .. "_Mode"] end
            }
        end

        -- Авто-выбор первой вкладки
        if #self.Tabs == 1 then
            Window:SelectTab(Tab)
        end

        return Tab
    end

    -- ==========================================
    -- ГЛОБАЛЬНЫЙ ПОИСК (GLOBAL SEARCH)
    -- ==========================================
    local SearchPage = Library.Utils.Make("ScrollingFrame", {
        Name = "GlobalSearchPage", Size = UDim2.new(1, -20, 1, -10), Position = UDim2.new(0, 10, 0, 5),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, Visible = false, ZIndex = 50, Parent = Pages
    }, { ScrollBarImageColor3 = "SubText" })

    local SearchLayout = Library.Utils.Make("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = SearchPage })
    Library.Utils.Make("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 20), PaddingBottom = UDim.new(0, 15), Parent = SearchPage })

    SearchLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SearchPage.CanvasSize = UDim2.new(0, 0, 0, SearchLayout.AbsoluteContentSize.Y + 20)
    end)

    local isSearchOpen = false
    local originalParents = {}
    local SearchClickBtn = Library.Utils.Make("TextButton", {Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -30, 0, 0), BackgroundTransparency = 1, Text = "", ZIndex = 10, Parent = SearchContainer})

    local function RestoreSearch()
        SearchPage.Visible = false
        for elem, data in pairs(originalParents) do
            if elem and data.Parent then
                elem.Parent = data.Parent
                elem.LayoutOrder = data.OriginalOrder 
                elem.Visible = true
            end
        end
        table.clear(originalParents)
        
        if Window and Window.CurrentTab then
            for _, tab in ipairs(Window.Tabs) do
                if tab.Btn == Window.CurrentTab then
                    tab.Page.Visible = true
                    break
                end
            end
        end
    end

    local function CloseSearch()
        isSearchOpen = false
        SearchInput.Text = ""
        Library.Utils.TBT(SearchContainer, 0.4, {Size = UDim2.new(0, 32, 0, 32)}, Enum.EasingStyle.Quint)
        Library.Utils.TBT(SearchInput, 0.2, {TextTransparency = 1})
        Library.ThemeObjects[SearchContainer:FindFirstChildOfClass("ImageLabel")] = { ImageColor3 = "SubText" }
        Library.Utils.TBT(SearchContainer:FindFirstChildOfClass("ImageLabel"), 0.3, {ImageColor3 = Library.CurrentTheme.SubText})
        task.delay(0.2, function() if not isSearchOpen then SearchInput.Visible = false end end)
    end

    Library:Connect(SearchClickBtn.MouseButton1Click, function()
        isSearchOpen = not isSearchOpen
        local searchIcon = SearchContainer:FindFirstChildOfClass("ImageLabel")
        if isSearchOpen then
            SearchInput.Visible = true
            Library.Utils.TBT(SearchContainer, 0.4, {Size = UDim2.new(0, 160, 0, 32)}, Enum.EasingStyle.Quint)
            Library.Utils.TBT(SearchInput, 0.3, {TextTransparency = 0})
            Library.ThemeObjects[searchIcon] = { ImageColor3 = "Accent" }
            Library.Utils.TBT(searchIcon, 0.3, {ImageColor3 = Library.CurrentTheme.Accent})
            SearchInput:CaptureFocus()
        else
            CloseSearch()
        end
    end)

    Library:Connect(SearchInput:GetPropertyChangedSignal("Text"), function()
        local query = string.lower(SearchInput.Text):match("^%s*(.-)%s*$") or ""
        if query == "" then RestoreSearch(); return end

        for _, tab in ipairs(Window.Tabs) do tab.Page.Visible = false end
        SearchPage.Visible = true
        
        if not next(originalParents) then
            local pageIndex = 0
            for _, tab in ipairs(Window.Tabs) do
                pageIndex = pageIndex + 1
                for _, elem in ipairs(tab.Page:GetChildren()) do
                    if elem:IsA("GuiObject") and not elem:IsA("UIListLayout") and not elem:IsA("UIPadding") and not string.find(elem.Name, "SubPage") then
                        originalParents[elem] = { Parent = tab.Page, OriginalOrder = elem.LayoutOrder, AbsoluteOrder = (pageIndex * 1000) + (elem.LayoutOrder or 0), TabRef = tab }
                    end
                end
            end
        end
        
        local matchedElements = {}
        for elem, data in pairs(originalParents) do
            local match = false
            local rawText = ""
            for _, desc in ipairs(elem:GetDescendants()) do 
                if desc:IsA("TextLabel") or desc:IsA("TextBox") or desc:IsA("TextButton") then
                    rawText = rawText .. " " .. tostring(desc.Text or "")
                end
            end
            
            local cleanText = string.lower(string.gsub(rawText, "<[^>]+>", ""))
            if string.find(cleanText, query, 1, true) then match = true end
            if string.find(cleanText, "update log") or string.len(cleanText) > 100 then match = false end
            
            if match then table.insert(matchedElements, {Element = elem, Data = data})
            elseif elem.Parent == SearchPage then elem.Parent = data.Parent; elem.LayoutOrder = data.OriginalOrder end
        end
        
        table.sort(matchedElements, function(a, b) return (a.Data.AbsoluteOrder or 0) < (b.Data.AbsoluteOrder or 0) end)
        for i, item in ipairs(matchedElements) do item.Element.Parent = SearchPage; item.Element.LayoutOrder = i; item.Element.Visible = true end
        task.defer(function() SearchPage.CanvasPosition = Vector2.new(0, 0) end)
    end)

    Library:Connect(UserInputService.InputBegan, function(input)
        if not isSearchOpen or not SearchPage.Visible then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local mPos = input.Position
            local spPos = SearchPage.AbsolutePosition
            local spSize = SearchPage.AbsoluteSize
            
            if mPos.X >= spPos.X and mPos.X <= spPos.X + spSize.X and mPos.Y >= spPos.Y and mPos.Y <= spPos.Y + spSize.Y then
                for elem, data in pairs(originalParents) do
                    if elem.Parent == SearchPage and elem.Visible then
                        local pos = elem.AbsolutePosition; local size = elem.AbsoluteSize
                        if mPos.X >= pos.X and mPos.X <= pos.X + size.X and mPos.Y >= pos.Y and mPos.Y <= pos.Y + size.Y then
                            -- Закрываем поиск и чистим текст ПРЯМО ТУТ
                            CloseSearch() 
                            Window:SelectTab(data.TabRef)
                            
                            task.spawn(function()
                                task.wait(0.15) 
                                local targetY = elem.AbsolutePosition.Y - data.Parent.AbsolutePosition.Y + data.Parent.CanvasPosition.Y
                                Library.Utils.TBT(data.Parent, 0.3, {CanvasPosition = Vector2.new(0, targetY - 15)}, Enum.EasingStyle.Cubic)
                                
                                local stroke = elem:FindFirstChildOfClass("UIStroke")
                                if stroke then
                                    local oColor = stroke.Color; local oThick = stroke.Thickness
                                    Library.Utils.TBT(stroke, 0.2, {Color = Library.CurrentTheme.Accent, Thickness = 2.5})
                                    task.wait(0.6)
                                    Library.Utils.TBT(stroke, 0.5, {Color = oColor, Thickness = oThick})
                                end
                            end)
                            break
                        end
                    end
                end
            end
        end
    end)

    function Window:Build()
        -- Запускаем лоадер, передавая ему наш ScreenGui
        Library:RunLoader(ScreenGui, function()
            -- Этот код выполнится только после того, как лоадер исчезнет
            MainFrame.Visible = true
            Library.Utils.TBT(MainFrame, 0.5, {GroupTransparency = 0})
        end)
    end

    return Window
end

    -- ==========================================
    -- 6. СИСТЕМА УВЕДОМЛЕНИЙ (NOTIFICATIONS)
    -- ==========================================
    function Library:Notify(title, text, duration, icon, logo)
        duration = duration or 3
        
        -- 1. Умная конвертация ID для иконки и логотипа
        local iconId = icon or "rbxassetid://283952329" 
        if tonumber(iconId) then iconId = "rbxassetid://" .. iconId end
        if logo and tonumber(logo) then logo = "rbxassetid://" .. logo end
        
        local ScreenGui = PlayerGui:FindFirstChild("DuskShine_Mega")
        if not ScreenGui then return end
            
        local Holder = ScreenGui:FindFirstChild("Notifications")
        if not Holder then return end

        local Container = Library.Utils.Make("Frame", { 
            Size = UDim2.new(0, 310, 0, 0), 
            AutomaticSize = Enum.AutomaticSize.Y, 
            BackgroundTransparency = 1, 
            Parent = Holder 
        })

        local AlertBox = Library.Utils.Make("Frame", {
            Size = UDim2.new(1, 0, 1, -5), 
            Position = UDim2.new(1, 40, 0, 0), 
            BackgroundColor3 = Color3.fromRGB(25, 25, 30), 
            BackgroundTransparency = 1, 
            BorderSizePixel = 0, 
            ClipsDescendants = true,
            Parent = Container
        })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 8), Parent = AlertBox})
        local Stroke = Library.Utils.Make("UIStroke", {Thickness = 1, Transparency = 1, Parent = AlertBox}, {Color = "Stroke"})
        
        -- Правый водяной знак (Создаем ДО контента, чтобы положить на ZIndex 1)
        local RightLogo = nil
        if logo then
            RightLogo = Library.Utils.Make("ImageLabel", {
                Size = UDim2.new(0, 160, 0, 160), 
                Position = UDim2.new(1, 35, 0.5, 0), 
                AnchorPoint = Vector2.new(1, 0.5), 
                BackgroundTransparency = 1, 
                Image = logo, 
                ImageTransparency = 1, 
                ScaleType = Enum.ScaleType.Fit, 
                ZIndex = 1, 
                Parent = AlertBox 
            })
        end

        local Content = Library.Utils.Make("Frame", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 2, Parent = AlertBox
        })
        Library.Utils.Make("UIPadding", {
            PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 18), 
            PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = Content
        })

        local Icon = Library.Utils.Make("ImageLabel", { 
            Size = UDim2.new(0, 32, 0, 32), Position = UDim2.new(0, 0, 0, 0), 
            BackgroundTransparency = 1, Image = iconId, ImageTransparency = 1, ZIndex = 3, Parent = Content 
        })

        -- 2. ОДИН правильный расчет отступа перед созданием текста
        local textOffset = logo and -55 or -42

        local TitleLbl = Library.Utils.Make("TextLabel", { 
            Text = title, Size = UDim2.new(1, textOffset, 0, 16), Position = UDim2.new(0, 42, 0, 0), 
            BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14, 
            TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, ZIndex = 3, Parent = Content 
        }, { TextColor3 = "Text" })

        local DescLbl = Library.Utils.Make("TextLabel", { 
            Text = text, Size = UDim2.new(1, textOffset, 0, 0), Position = UDim2.new(0, 42, 0, 18), 
            AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, 
            TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, 
            TextTransparency = 1, ZIndex = 3, Parent = Content 
        }, { TextColor3 = "Text" })

        local TimeBarBg = Library.Utils.Make("Frame", { 
            Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 1, -3), 
            BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 5, Parent = AlertBox 
        })
        local TimeBar = Library.Utils.Make("Frame", { 
            Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0, BackgroundTransparency = 1, Parent = TimeBarBg 
        }, { BackgroundColor3 = "Accent" })

        Library.Utils.TBT(AlertBox, 0.35, {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        Library.Utils.TBT(Stroke, 0.35, {Transparency = 0.2})
        Library.Utils.TBT(Icon, 0.35, {ImageTransparency = 0})
        Library.Utils.TBT(TitleLbl, 0.35, {TextTransparency = 0})
        Library.Utils.TBT(DescLbl, 0.35, {TextTransparency = 0})
        Library.Utils.TBT(TimeBar, 0.35, {BackgroundTransparency = 0})
        
        if RightLogo then Library.Utils.TBT(RightLogo, 0.35, {ImageTransparency = 0.85}) end

        Library.Utils.TBT(TimeBar, duration, {Size = UDim2.new(1, 0, 1, 0)}, Enum.EasingStyle.Linear)

        local isClosed = false
        task.delay(duration, function()
            if isClosed then return end
            isClosed = true
            local out = Library.Utils.TBT(AlertBox, 0.3, {Position = UDim2.new(1, 50, 0, 0), BackgroundTransparency = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
            Library.Utils.TBT(Stroke, 0.3, {Transparency = 1})
            Library.Utils.TBT(Icon, 0.3, {ImageTransparency = 1})
            Library.Utils.TBT(TitleLbl, 0.3, {TextTransparency = 1})
            Library.Utils.TBT(DescLbl, 0.3, {TextTransparency = 1})
            Library.Utils.TBT(TimeBar, 0.3, {BackgroundTransparency = 1})
            if RightLogo then Library.Utils.TBT(RightLogo, 0.3, {ImageTransparency = 1}) end
            out.Completed:Connect(function() Container:Destroy() end)
        end)
    end

    -- ==========================================
    -- 7. МЕНЕДЖЕР КОНФИГОВ (CONFIG SYSTEM)
    -- ==========================================
    local HttpService = game:GetService("HttpService")
    Library.ConfigFolder = "DuskAndShineConfigs"

    function Library:SaveConfig(fileName)
        if not writefile then 
            warn("[Dusk] Executor does not support file saving.")
            return 
        end

        if not isfolder(self.ConfigFolder) then 
            makefolder(self.ConfigFolder) 
        end
        
        local saveTable = {}
        -- Умный обход: кодируем специфические типы данных
        for flag, value in pairs(self.Flags) do
            if typeof(value) == "Color3" then
                saveTable[flag] = { R = value.R, G = value.G, B = value.B, isColor = true }
            elseif typeof(value) == "EnumItem" then
                saveTable[flag] = { Key = value.Name, isKeybind = true }
            else
                saveTable[flag] = value
            end
        end

        local success, json = pcall(function() return HttpService:JSONEncode(saveTable) end)
        if success then
            writefile(self.ConfigFolder .. "/" .. fileName .. ".json", json)
            self:Notify("Config System", "Successfully saved: " .. fileName, 3)
        else
            self:Notify("Error", "Failed to encode config!", 3)
        end
    end

    function Library:LoadConfig(fileName)
        if not readfile or not isfile(self.ConfigFolder .. "/" .. fileName .. ".json") then 
            self:Notify("Error", "Config file not found!", 3)
            return 
        end
        
        local json = readfile(self.ConfigFolder .. "/" .. fileName .. ".json")
        local success, data = pcall(function() return HttpService:JSONDecode(json) end)
        
        if success and type(data) == "table" then
            for flag, value in pairs(data) do
                -- Декодируем специфические типы обратно
                if type(value) == "table" then
                    if value.isColor then
                        value = Color3.new(value.R, value.G, value.B)
                    elseif value.isKeybind then
                        value = Enum.KeyCode[value.Key]
                    end
                end
                
                -- Обновляем данные в ядре
                self.Flags[flag] = value
                
                -- Если компонент зарегистрировал функцию апдейта (SetState, SetValue) - вызываем её!
                if self.ConfigUpdaters[flag] then
                    pcall(self.ConfigUpdaters[flag], value)
                end
            end
            self:Notify("Config System", "Successfully loaded: " .. fileName, 3)
        else
            self:Notify("Error", "Failed to read config!", 3)
        end
    end

return Library
