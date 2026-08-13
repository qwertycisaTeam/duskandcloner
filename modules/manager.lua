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
-- ИНТЕРФЕЙС (РЕАЛЬНЫЙ МАКЕТ)
-- ==========================================
function Module:Init(Library, Window, Tab)
    self.Library = Library
    self.Tab = Tab

    -- 1. ШАПКА
    local HeaderPanel = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundTransparency = 1,
        Parent = Tab.Page
    })

    -- Широкий Label, чтобы текст "House Schematics" больше не обрезался
    Library.Utils.Make("TextLabel", {
        Text = '<b><font color="#ffffff">FILE MANAGER:</font></b> <font color="#9696a0">House Schematics</font>',
        RichText = true,
        Size = UDim2.new(1, -120, 1, 0), -- Оставляем 120px справа под кнопку
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = HeaderPanel
    })

    -- Кнопка REFRESH (С фоном и рамкой, как на макете)
    local RefreshBtn = Library.Utils.Make("TextButton", {
        Text = "",
        Size = UDim2.new(0, 95, 0, 26),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -20, 0.5, 0),
        AutoButtonColor = false,
        Parent = HeaderPanel
    }, { BackgroundColor3 = "Section" }) -- ТЕПЕРЬ ФОН ВИДЕН
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = RefreshBtn })
    local RefStroke = Library.Utils.Make("UIStroke", { Thickness = 1, Transparency = 0.5, Parent = RefreshBtn }, { Color = "Stroke" })

    -- Внутренности кнопки Refresh (Иконка + Текст)
    local RefContent = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = RefreshBtn })
    Library.Utils.Make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), Parent = RefContent })
    
    local RefIcon = Library.Utils.Make("ImageLabel", { Size = UDim2.new(0, 14, 0, 14), BackgroundTransparency = 1, Image = "rbxassetid://10873923769", Parent = RefContent }, { ImageColor3 = "Text" })
    Library.Utils.Make("TextLabel", { Text = "REFRESH", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11, Parent = RefContent }, { TextColor3 = "Text" })

    -- Благородная анимация кнопки
    Library:Connect(RefreshBtn.MouseEnter, function() 
        Library.Utils.TBT(RefStroke, 0.2, {Transparency = 0}) 
        Library.Utils.TBT(RefreshBtn, 0.2, {BackgroundColor3 = Library.CurrentTheme.Sidebar})
    end)
    Library:Connect(RefreshBtn.MouseLeave, function() 
        Library.Utils.TBT(RefStroke, 0.2, {Transparency = 0.5}) 
        Library.Utils.TBT(RefreshBtn, 0.2, {BackgroundColor3 = Library.CurrentTheme.Section})
    end)
    Library:Connect(RefreshBtn.MouseButton1Click, function()
        Library.Utils.TBT(RefreshBtn, 0.1, {BackgroundColor3 = Library.CurrentTheme.Text})
        task.delay(0.1, function() Library.Utils.TBT(RefreshBtn, 0.3, {BackgroundColor3 = Library.CurrentTheme.Section}) end)
        
        Library.Utils.TBT(RefIcon, 0.5, {Rotation = 360})
        task.delay(0.5, function() RefIcon.Rotation = 0 end)
        self:RefreshList()
    end)

    -- 2. КОНТЕЙНЕР (С полосой прокрутки справа)
    self.ListContainer = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, -20, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = Tab.Page
    })
    Library.Utils.Make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.ListContainer })

    self:RefreshList()
end

function Module:RefreshList()
    for _, child in ipairs(self.ListContainer:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
    end

    local houses = self:GetHouses()

    if #houses == 0 then
        Library.Utils.Make("TextLabel", { Text = "No saved houses found.", Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = self.ListContainer }, { TextColor3 = "SubText" })
        return
    end

    for _, houseName in ipairs(houses) do
        self:CreateFileCard(houseName)
    end
end

-- ==========================================
-- КАРТОЧКА ФАЙЛА (С ПЛОТНЫМ ФОНОМ И НЕОНОМ)
-- ==========================================
function Module:CreateFileCard(fileName)
    local Library = self.Library

    -- ВОЗВРАЩАЕМ ПЛОТНЫЙ ФОН
    local Card = Library.Utils.Make("TextButton", { 
        Text = "",
        Size = UDim2.new(1, 0, 0, 56), 
        AutoButtonColor = false,
        BackgroundTransparency = 0, -- Карточка снова монолитная!
        Parent = self.ListContainer 
    }, { BackgroundColor3 = "Section" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Card })
    
    -- Базовая рамка (серая)
    local GlowStroke = Library.Utils.Make("UIStroke", { 
        Thickness = 1, 
        Transparency = 0.7, 
        Parent = Card 
    }, { Color = "Stroke" }) -- По умолчанию цвет рамки берем из темы

    -- Твоя иконка дискеты/JSON
    local FileIcon = Library.Utils.Make("ImageLabel", {
        Size = UDim2.new(0, 26, 0, 26), 
        Position = UDim2.new(0, 14, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://105856032975609", 
        Parent = Card
    })
    Library.ThemeObjects[FileIcon] = { ImageColor3 = "Text" }
    FileIcon.ImageColor3 = Library.CurrentTheme.Text

    -- Тексты
    Library.Utils.Make("TextLabel", { 
        Text = fileName, 
        Size = UDim2.new(1, -110, 0, 20), 
        Position = UDim2.new(0, 54, 0.5, -10), 
        BackgroundTransparency = 1, 
        Font = Enum.Font.GothamBold, 
        TextSize = 14, 
        TextXAlignment = Enum.TextXAlignment.Left, 
        Parent = Card 
    }, { TextColor3 = "Text" })

    local timeStr = os.date("%H:%M:%S")
    Library.Utils.Make("TextLabel", { 
        Text = "Last-saved " .. timeStr, 
        Size = UDim2.new(1, -110, 0, 15), 
        Position = UDim2.new(0, 54, 0.5, 8), 
        BackgroundTransparency = 1, 
        Font = Enum.Font.Gotham, 
        TextSize = 11, 
        TextXAlignment = Enum.TextXAlignment.Left, 
        Parent = Card 
    }, { TextColor3 = "SubText" })

    -- КНОПКА ОПЦИЙ "•••"
    local OptionsBtn = Library.Utils.Make("TextButton", { 
        Text = "•••", 
        Size = UDim2.new(0, 34, 0, 24), 
        AnchorPoint = Vector2.new(1, 0.5), 
        Position = UDim2.new(1, -12, 0.5, 0), 
        Font = Enum.Font.GothamBold, 
        TextSize = 14,
        AutoButtonColor = false,
        Parent = Card 
    }, { BackgroundColor3 = "Sidebar", TextColor3 = "SubText" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = OptionsBtn })
    local OptStroke = Library.Utils.Make("UIStroke", { Thickness = 1, Transparency = 0.5, Parent = OptionsBtn }, { Color = "Stroke" })

    -- === ЛОГИКА НАСТОЯЩЕГО НЕОНА ===
    Library:Connect(Card.MouseEnter, function()
        -- Красим контур в кристально белый и делаем толще
        GlowStroke.Color = Color3.fromRGB(255, 255, 255)
        Library.Utils.TBT(GlowStroke, 0.2, {Transparency = 0, Thickness = 2}, Enum.EasingStyle.Quint)
        Library.Utils.TBT(Card, 0.2, {BackgroundTransparency = 0.2}, Enum.EasingStyle.Quint) -- Легкая подсветка фона
    end)
    Library:Connect(Card.MouseLeave, function()
        -- Возвращаем цвет контура из темы и делаем тонким
        GlowStroke.Color = Library.CurrentTheme.Stroke
        Library.Utils.TBT(GlowStroke, 0.2, {Transparency = 0.7, Thickness = 1}, Enum.EasingStyle.Quint)
        Library.Utils.TBT(Card, 0.2, {BackgroundTransparency = 0}, Enum.EasingStyle.Quint)
    end)

    -- === ЛОГИКА КНОПКИ "•••" ===
    Library:Connect(OptionsBtn.MouseEnter, function() 
        Library.Utils.TBT(OptionsBtn, 0.15, {BackgroundColor3 = Library.CurrentTheme.Section, TextColor3 = Library.CurrentTheme.Accent}) 
        Library.Utils.TBT(OptStroke, 0.15, {Transparency = 0})
    end)
    Library:Connect(OptionsBtn.MouseLeave, function() 
        Library.Utils.TBT(OptionsBtn, 0.15, {BackgroundColor3 = Library.CurrentTheme.Sidebar, TextColor3 = Library.CurrentTheme.SubText}) 
        Library.Utils.TBT(OptStroke, 0.15, {Transparency = 0.5})
    end)

    Library:Connect(OptionsBtn.MouseButton1Click, function()
        -- Вспышка фона (как в дорогих интерфейсах)
        Library.Utils.TBT(OptionsBtn, 0.1, {BackgroundColor3 = Library.CurrentTheme.Text})
        task.delay(0.1, function() Library.Utils.TBT(OptionsBtn, 0.2, {BackgroundColor3 = Library.CurrentTheme.Section}) end)
        
        print("Открываем Dropdown для: " .. fileName)
    end)
end

return Module
