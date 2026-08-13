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
-- ИНТЕРФЕЙС (МАКСИМАЛЬНАЯ КОПИЯ МАКЕТА)
-- ==========================================
function Module:Init(Library, Window, Tab)
    self.Library = Library
    self.Tab = Tab

    -- 1. ШАПКА
    local HeaderPanel = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, 0, 0, 50), -- Сделали шапку просторнее
        BackgroundTransparency = 1,
        Parent = Tab.Page
    })

    -- RichText для идеального копирования шрифтов макета
    Library.Utils.Make("TextLabel", {
        Text = '<b><font color="#ffffff">FILE MANAGER:</font></b> <font color="#9696a0">House Schematics</font>',
        RichText = true,
        Size = UDim2.new(0.6, 0, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham, -- Базовый шрифт, жирность задана через теги
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = HeaderPanel
    })

    -- Кнопка REFRESH (Строгая и солидная)
    local RefreshBtn = Library.Utils.Make("TextButton", {
        Text = "",
        Size = UDim2.new(0, 95, 0, 28),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -20, 0.5, 0), -- Отодвинули от правого края под графу
        AutoButtonColor = false,
        Parent = HeaderPanel
    }, { BackgroundColor3 = "Sidebar" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = RefreshBtn })
    local RefStroke = Library.Utils.Make("UIStroke", { Thickness = 1, Transparency = 0.6, Parent = RefreshBtn }, { Color = "Stroke" })

    -- Внутренности кнопки Refresh
    local RefContent = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = RefreshBtn })
    Library.Utils.Make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), Parent = RefContent })
    
    local RefIcon = Library.Utils.Make("ImageLabel", { Size = UDim2.new(0, 13, 0, 13), BackgroundTransparency = 1, Image = "rbxassetid://10873923769", Parent = RefContent }, { ImageColor3 = "Text" })
    Library.Utils.Make("TextLabel", { Text = "REFRESH", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11, Parent = RefContent }, { TextColor3 = "Text" })

    -- ДОРОГАЯ АНИМАЦИЯ (Без Scale!)
    Library:Connect(RefreshBtn.MouseEnter, function() 
        Library.Utils.TBT(RefStroke, 0.2, {Transparency = 0}) 
        Library.Utils.TBT(RefreshBtn, 0.2, {BackgroundColor3 = Library.CurrentTheme.Section})
    end)
    Library:Connect(RefreshBtn.MouseLeave, function() 
        Library.Utils.TBT(RefStroke, 0.2, {Transparency = 0.6}) 
        Library.Utils.TBT(RefreshBtn, 0.2, {BackgroundColor3 = Library.CurrentTheme.Sidebar})
    end)
    Library:Connect(RefreshBtn.MouseButton1Click, function()
        -- Вспышка фона вместо изменения размера
        Library.Utils.TBT(RefreshBtn, 0.1, {BackgroundColor3 = Library.CurrentTheme.Text})
        task.delay(0.1, function() Library.Utils.TBT(RefreshBtn, 0.3, {BackgroundColor3 = Library.CurrentTheme.Section}) end)
        
        Library.Utils.TBT(RefIcon, 0.5, {Rotation = 360})
        task.delay(0.5, function() RefIcon.Rotation = 0 end)
        self:RefreshList()
    end)

    -- 2. КОНТЕЙНЕР (С местом под правую графу)
    self.ListContainer = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, -20, 0, 0), -- -20px создает ту самую пустую полосу справа!
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = Tab.Page
    })
    Library.Utils.Make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.ListContainer })

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
-- КАРТОЧКА ФАЙЛА (С ЯРКИМ НЕОНОМ)
-- ==========================================
function Module:CreateFileCard(fileName)
    local Library = self.Library

    -- По дефолту карточка полностью сливается с фоном
    local Card = Library.Utils.Make("TextButton", { 
        Text = "",
        Size = UDim2.new(1, 0, 0, 60), -- Карточка стала выше и массивнее
        AutoButtonColor = false,
        BackgroundTransparency = 1, 
        Parent = self.ListContainer 
    }, { BackgroundColor3 = "Section" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Card })
    
    -- Неоновая обводка (скрыта по дефолту)
    local GlowStroke = Library.Utils.Make("UIStroke", { 
        Thickness = 2.5, -- Толстый, сочный контур для ховера
        Transparency = 1, 
        Color = Color3.fromRGB(255, 255, 255), 
        Parent = Card 
    })

    -- КРУПНАЯ ИКОНКА JSON
    local FileIcon = Library.Utils.Make("ImageLabel", {
        Size = UDim2.new(0, 34, 0, 34), -- Увеличили размер
        Position = UDim2.new(0, 10, 0.5, 0),
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
        Position = UDim2.new(0, 55, 0.5, -11), 
        BackgroundTransparency = 1, 
        Font = Enum.Font.GothamBold, 
        TextSize = 15, -- Сделали заголовок крупнее
        TextXAlignment = Enum.TextXAlignment.Left, 
        Parent = Card 
    }, { TextColor3 = "Text" })

    local timeStr = os.date("%H:%M:%S PM")
    Library.Utils.Make("TextLabel", { 
        Text = "Last-saved " .. timeStr, 
        Size = UDim2.new(1, -110, 0, 15), 
        Position = UDim2.new(0, 55, 0.5, 9), 
        BackgroundTransparency = 1, 
        Font = Enum.Font.Gotham, 
        TextSize = 12, 
        TextXAlignment = Enum.TextXAlignment.Left, 
        Parent = Card 
    }, { TextColor3 = "SubText" })

    -- КНОПКА ОПЦИЙ "•••" (Без изменения масштаба!)
    local OptionsBtn = Library.Utils.Make("TextButton", { 
        Text = "•••", 
        Size = UDim2.new(0, 36, 0, 24), 
        AnchorPoint = Vector2.new(1, 0.5), 
        Position = UDim2.new(1, -10, 0.5, 0), 
        Font = Enum.Font.GothamBold, 
        TextSize = 14,
        AutoButtonColor = false,
        BackgroundTransparency = 0.8,
        Parent = Card 
    }, { BackgroundColor3 = "Sidebar", TextColor3 = "SubText" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = OptionsBtn })
    local OptStroke = Library.Utils.Make("UIStroke", { Thickness = 1, Transparency = 0.7, Parent = OptionsBtn }, { Color = "Stroke" })

    -- === ЛОГИКА НАВЕДЕНИЯ НА КАРТОЧКУ (НЕОН) ===
    Library:Connect(Card.MouseEnter, function()
        -- Резко проявляется толстая белая обводка, фон слегка темнеет для контраста
        Library.Utils.TBT(GlowStroke, 0.15, {Transparency = 0.1}, Enum.EasingStyle.Sine)
        Library.Utils.TBT(Card, 0.15, {BackgroundTransparency = 0.8}, Enum.EasingStyle.Sine)
    end)
    Library:Connect(Card.MouseLeave, function()
        Library.Utils.TBT(GlowStroke, 0.3, {Transparency = 1}, Enum.EasingStyle.Sine)
        Library.Utils.TBT(Card, 0.3, {BackgroundTransparency = 1}, Enum.EasingStyle.Sine)
    end)

    -- === ЛОГИКА КНОПКИ "•••" (Солидный отклик) ===
    Library:Connect(OptionsBtn.MouseEnter, function() 
        Library.Utils.TBT(OptionsBtn, 0.15, {BackgroundTransparency = 0.3, TextColor3 = Library.CurrentTheme.Accent}) 
        Library.Utils.TBT(OptStroke, 0.15, {Transparency = 0})
    end)
    Library:Connect(OptionsBtn.MouseLeave, function() 
        Library.Utils.TBT(OptionsBtn, 0.15, {BackgroundTransparency = 0.8, TextColor3 = Library.CurrentTheme.SubText}) 
        Library.Utils.TBT(OptStroke, 0.15, {Transparency = 0.7})
    end)

    Library:Connect(OptionsBtn.MouseButton1Click, function()
        -- Никаких сжатий. Делаем яркую вспышку фона
        Library.Utils.TBT(OptionsBtn, 0.1, {BackgroundTransparency = 0})
        task.delay(0.1, function() Library.Utils.TBT(OptionsBtn, 0.2, {BackgroundTransparency = 0.3}) end)
        
        print("Открываем Dropdown для: " .. fileName)
    end)
end

return Module
