local HttpService = game:GetService("HttpService")
local Module = {}

-- ==========================================
-- ЛОГИКА ФАЙЛОВОЙ СИСТЕМЫ
-- ==========================================
Module.FolderName = "DuskAndShine_Houses"

function Module:InitFolder()
    if not isfolder(self.FolderName) then
        makefolder(self.FolderName)
    end
end

function Module:GetHouses()
    self:InitFolder()
    local houses = {}
    local files = listfiles(self.FolderName)
    
    for _, path in ipairs(files) do
        local fileName = path:match("([^/\\]+)%.json$")
        if fileName then table.insert(houses, fileName) end
    end
    return houses
end

-- ==========================================
-- ИНТЕРФЕЙС (UI) - ИДЕАЛЬНАЯ КОПИЯ МАКЕТА
-- ==========================================
function Module:Init(Library, Window, Tab)
    self.Library = Library
    self.Tab = Tab

    -- 1. ШАПКА
    local HeaderPanel = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = Tab.Page
    })

    Library.Utils.Make("TextLabel", {
        Text = "FILE MANAGER: House Schematics",
        Size = UDim2.new(0.6, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = HeaderPanel
    }, { TextColor3 = "SubText" })

    -- Строгая кнопка REFRESH без эмодзи
    local RefreshBtn = Library.Utils.Make("TextButton", {
        Text = "REFRESH",
        Size = UDim2.new(0, 95, 0, 26),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        AutoButtonColor = false,
        Parent = HeaderPanel
    }, { BackgroundColor3 = "Sidebar", TextColor3 = "Text" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = RefreshBtn })
    Library.Utils.Make("UIPadding", { PaddingRight = UDim.new(0, 12), Parent = RefreshBtn })
    local RefStroke = Library.Utils.Make("UIStroke", { Thickness = 1, Transparency = 0.5, Parent = RefreshBtn }, { Color = "Stroke" })
    
    -- Чистая иконка обновления вместо смайлика
    local RefIcon = Library.Utils.Make("ImageLabel", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0, 10, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://10873923769", 
        Parent = RefreshBtn
    }, { ImageColor3 = "Text" })

    -- Анимация кнопки
    local refScale = Instance.new("UIScale", RefreshBtn)
    Library:Connect(RefreshBtn.MouseEnter, function() 
        Library.Utils.TBT(RefStroke, 0.2, {Transparency = 0}) 
        Library.Utils.TBT(RefreshBtn, 0.2, {BackgroundColor3 = Library.CurrentTheme.Section})
    end)
    Library:Connect(RefreshBtn.MouseLeave, function() 
        Library.Utils.TBT(RefStroke, 0.2, {Transparency = 0.5}) 
        Library.Utils.TBT(RefreshBtn, 0.2, {BackgroundColor3 = Library.CurrentTheme.Sidebar})
    end)
    Library:Connect(RefreshBtn.MouseButton1Click, function()
        local t = Library.Utils.TBT(refScale, 0.1, {Scale = 0.9})
        t.Completed:Connect(function() Library.Utils.TBT(refScale, 0.2, {Scale = 1}, Enum.EasingStyle.Bounce) end)
        
        -- Крутим иконку при нажатии
        Library.Utils.TBT(RefIcon, 0.5, {Rotation = 360})
        task.delay(0.5, function() RefIcon.Rotation = 0 end)
        
        self:RefreshList()
    end)

    -- 2. Контейнер для списка
    self.ListContainer = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = Tab.Page
    })
    
    Library.Utils.Make("UIListLayout", {
        Padding = UDim.new(0, 4), -- Минимальный отступ, как на макете
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.ListContainer
    })

    self:RefreshList()
end

function Module:RefreshList()
    for _, child in ipairs(self.ListContainer:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
    end

    local houses = self:GetHouses()

    if #houses == 0 then
        Library.Utils.Make("TextLabel", {
            Text = "No saved houses found.",
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            Parent = self.ListContainer
        }, { TextColor3 = "SubText" })
        return
    end

    for _, houseName in ipairs(houses) do
        self:CreateFileCard(houseName)
    end
end

-- ==========================================
-- КАРТОЧКА ФАЙЛА (МАКЕТНАЯ ВЕРСИЯ)
-- ==========================================
function Module:CreateFileCard(fileName)
    local Library = self.Library

    -- Карточка прозрачная по дефолту! (Сливается с фоном)
    local Card = Library.Utils.Make("TextButton", { 
        Text = "",
        Size = UDim2.new(1, 0, 0, 52), 
        AutoButtonColor = false,
        BackgroundTransparency = 1, 
        Parent = self.ListContainer 
    }, { BackgroundColor3 = "Section" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Card })
    
    -- Неоновая обводка (Скрыта по дефолту)
    local GlowStroke = Library.Utils.Make("UIStroke", { 
        Thickness = 1.5, 
        Transparency = 1, 
        Color = Color3.fromRGB(255, 255, 255), 
        Parent = Card 
    })

    local FileIcon = Library.Utils.Make("ImageLabel", {
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 14, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://105856032975609", 
        Parent = Card
    })
    Library.ThemeObjects[FileIcon] = { ImageColor3 = "Text" }
    FileIcon.ImageColor3 = Library.CurrentTheme.Text

    Library.Utils.Make("TextLabel", { 
        Text = fileName, 
        Size = UDim2.new(1, -110, 0, 20), 
        Position = UDim2.new(0, 50, 0.5, -10), 
        BackgroundTransparency = 1, 
        Font = Enum.Font.GothamBold, 
        TextSize = 14, 
        TextXAlignment = Enum.TextXAlignment.Left, 
        Parent = Card 
    }, { TextColor3 = "Text" })

    -- Подпись как на макете
    local timeStr = os.date("%H:%M:%S")
    Library.Utils.Make("TextLabel", { 
        Text = "Last-saved " .. timeStr, 
        Size = UDim2.new(1, -110, 0, 15), 
        Position = UDim2.new(0, 50, 0.5, 8), 
        BackgroundTransparency = 1, 
        Font = Enum.Font.Gotham, 
        TextSize = 11, 
        TextXAlignment = Enum.TextXAlignment.Left, 
        Parent = Card 
    }, { TextColor3 = "SubText" })

    local OptionsBtn = Library.Utils.Make("TextButton", { 
        Text = "•••", 
        Size = UDim2.new(0, 34, 0, 26), 
        AnchorPoint = Vector2.new(1, 0.5), 
        Position = UDim2.new(1, -14, 0.5, 0), 
        Font = Enum.Font.GothamBold, 
        TextSize = 14,
        AutoButtonColor = false,
        Parent = Card 
    }, { BackgroundColor3 = "Sidebar", TextColor3 = "SubText" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = OptionsBtn })
    local OptStroke = Library.Utils.Make("UIStroke", { Thickness = 1, Transparency = 0.5, Parent = OptionsBtn }, { Color = "Stroke" })

    -- === ЛОГИКА НАВЕДЕНИЯ КАК В МАКЕТЕ ===
    Library:Connect(Card.MouseEnter, function()
        -- Появляется белая рамка и слегка подсвечивается фон
        Library.Utils.TBT(GlowStroke, 0.2, {Transparency = 0.3}, Enum.EasingStyle.Sine)
        Library.Utils.TBT(Card, 0.2, {BackgroundTransparency = 0.6}, Enum.EasingStyle.Sine)
    end)
    Library:Connect(Card.MouseLeave, function()
        -- Карточка снова исчезает в фоне
        Library.Utils.TBT(GlowStroke, 0.2, {Transparency = 1}, Enum.EasingStyle.Sine)
        Library.Utils.TBT(Card, 0.2, {BackgroundTransparency = 1}, Enum.EasingStyle.Sine)
    end)

    local optScale = Instance.new("UIScale", OptionsBtn)
    Library:Connect(OptionsBtn.MouseEnter, function() 
        Library.Utils.TBT(optScale, 0.2, {Scale = 1.05}) 
        Library.Utils.TBT(OptionsBtn, 0.2, {TextColor3 = Library.CurrentTheme.Accent}) 
        Library.Utils.TBT(OptStroke, 0.2, {Transparency = 0})
    end)
    Library:Connect(OptionsBtn.MouseLeave, function() 
        Library.Utils.TBT(optScale, 0.2, {Scale = 1}) 
        Library.Utils.TBT(OptionsBtn, 0.2, {TextColor3 = Library.CurrentTheme.SubText}) 
        Library.Utils.TBT(OptStroke, 0.2, {Transparency = 0.5})
    end)

    Library:Connect(OptionsBtn.MouseButton1Click, function()
        local t = Library.Utils.TBT(optScale, 0.1, {Scale = 0.9})
        t.Completed:Connect(function() Library.Utils.TBT(optScale, 0.2, {Scale = 1}, Enum.EasingStyle.Bounce) end)
        
        print("Нажали троеточие на файле: " .. fileName)
    end)
end

return Module
