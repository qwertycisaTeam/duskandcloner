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
-- ИНТЕРФЕЙС (UI) - В СТИЛЕ МАКЕТА
-- ==========================================
function Module:Init(Library, Window, Tab)
    self.Library = Library
    self.Tab = Tab

    -- 1. КАСТОМНАЯ ШАПКА (Текст слева, компактная кнопка Refresh справа)
    local HeaderPanel = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = Tab.Page
    })

    -- Заголовок секции
    Library.Utils.Make("TextLabel", {
        Text = "FILE MANAGER: House Schematics",
        Size = UDim2.new(0.6, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = HeaderPanel
    }, { TextColor3 = "SubText" })

    -- Красивая компактная кнопка Refresh
    local RefreshBtn = Library.Utils.Make("TextButton", {
        Text = "  🔄 REFRESH",
        Size = UDim2.new(0, 100, 0, 28),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        AutoButtonColor = false,
        Parent = HeaderPanel
    }, { BackgroundColor3 = "Section", TextColor3 = "Text" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = RefreshBtn })
    local RefStroke = Library.Utils.Make("UIStroke", { Thickness = 1, Parent = RefreshBtn }, { Color = "Stroke" })
    
    -- Анимация кнопки Refresh
    local refScale = Instance.new("UIScale", RefreshBtn)
    Library:Connect(RefreshBtn.MouseEnter, function() 
        Library.Utils.TBT(RefStroke, 0.2, {Transparency = 0}) 
        Library.Utils.TBT(RefreshBtn, 0.2, {BackgroundTransparency = 0.2})
    end)
    Library:Connect(RefreshBtn.MouseLeave, function() 
        Library.Utils.TBT(RefStroke, 0.2, {Transparency = 0.5}) 
        Library.Utils.TBT(RefreshBtn, 0.2, {BackgroundTransparency = 0})
    end)
    Library:Connect(RefreshBtn.MouseButton1Click, function()
        local t = Library.Utils.TBT(refScale, 0.1, {Scale = 0.9})
        t.Completed:Connect(function() Library.Utils.TBT(refScale, 0.2, {Scale = 1}, Enum.EasingStyle.Bounce) end)
        self:RefreshList()
        Library:Notify("File Manager", "List refreshed!", 2)
    end)

    -- 2. Контейнер для списка файлов
    self.ListContainer = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = Tab.Page
    })
    
    Library.Utils.Make("UIListLayout", {
        Padding = UDim.new(0, 10), -- Чуть больше отступ между карточками, как на макете
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.ListContainer
    })

    -- Первичная загрузка
    self:RefreshList()
end

function Module:RefreshList()
    -- Очищаем старые файлы
    for _, child in ipairs(self.ListContainer:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
    end

    local houses = self:GetHouses()

    if #houses == 0 then
        Library.Utils.Make("TextLabel", {
            Text = "No saved houses found. Save a house first!",
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            Parent = self.ListContainer
        }, { TextColor3 = "SubText" })
        return
    end

    -- Рисуем карточки
    for _, houseName in ipairs(houses) do
        self:CreateFileCard(houseName)
    end
end

-- ==========================================
-- КАРТОЧКА ФАЙЛА (С НЕОНОВЫМ ЭФФЕКТОМ)
-- ==========================================
function Module:CreateFileCard(fileName)
    local Library = self.Library

    -- Карточка теперь кликабельная (TextButton), чтобы ловить наведение мышки на весь блок
    local Card = Library.Utils.Make("TextButton", { 
        Text = "",
        Size = UDim2.new(1, 0, 0, 56), 
        AutoButtonColor = false,
        Parent = self.ListContainer 
    }, { BackgroundColor3 = "Section" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 12), Parent = Card })
    
    -- Тот самый "Неоновый" Stroke. По дефолту тусклый и тонкий.
    local GlowStroke = Library.Utils.Make("UIStroke", { 
        Thickness = 1.2, 
        Transparency = 0.7, 
        Color = Color3.fromRGB(255, 255, 255), -- Чисто белый цвет для эффекта свечения
        Parent = Card 
    })

    -- Иконка JSON (Слева)
    local FileIcon = Library.Utils.Make("ImageLabel", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(0, 16, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://105856032975609", 
        Parent = Card
    })
    Library.ThemeObjects[FileIcon] = { ImageColor3 = "Text" }
    FileIcon.ImageColor3 = Library.CurrentTheme.Text -- На макете она светлая

    -- Название файла
    Library.Utils.Make("TextLabel", { 
        Text = fileName, 
        Size = UDim2.new(1, -110, 0, 20), 
        Position = UDim2.new(0, 56, 0.5, -10), 
        BackgroundTransparency = 1, 
        Font = Enum.Font.GothamBold, 
        TextSize = 14, 
        TextXAlignment = Enum.TextXAlignment.Left, 
        Parent = Card 
    }, { TextColor3 = "Text" })

    -- Имитация подписи "Last-saved" (как на макете)
    Library.Utils.Make("TextLabel", { 
        Text = "Local JSON file", 
        Size = UDim2.new(1, -110, 0, 15), 
        Position = UDim2.new(0, 56, 0.5, 8), 
        BackgroundTransparency = 1, 
        Font = Enum.Font.Gotham, 
        TextSize = 11, 
        TextXAlignment = Enum.TextXAlignment.Left, 
        Parent = Card 
    }, { TextColor3 = "SubText" })

    -- Кнопка опций "•••" (Справа)
    local OptionsBtn = Library.Utils.Make("TextButton", { 
        Text = "•••", 
        Size = UDim2.new(0, 40, 0, 28), 
        AnchorPoint = Vector2.new(1, 0.5), 
        Position = UDim2.new(1, -14, 0.5, 0), 
        Font = Enum.Font.GothamBold, 
        TextSize = 16,
        AutoButtonColor = false,
        Parent = Card 
    }, { BackgroundColor3 = "Sidebar", TextColor3 = "SubText" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = OptionsBtn })
    local OptStroke = Library.Utils.Make("UIStroke", { Thickness = 1, Transparency = 0.5, Parent = OptionsBtn }, { Color = "Stroke" })

    -- === АНИМАЦИИ (НЕОН И КНОПКИ) ===
    local cardScale = Instance.new("UIScale", Card)
    local optScale = Instance.new("UIScale", OptionsBtn)

    -- Когда мышка наводится на САМУ КАРТОЧКУ (Неоновое свечение)
    Library:Connect(Card.MouseEnter, function()
        -- Делаем обводку толще и ярче, чуть увеличиваем карточку
        Library.Utils.TBT(GlowStroke, 0.3, {Transparency = 0.1, Thickness = 2.5}, Enum.EasingStyle.Quint)
        Library.Utils.TBT(cardScale, 0.3, {Scale = 1.02}, Enum.EasingStyle.Quint)
    end)
    Library:Connect(Card.MouseLeave, function()
        -- Возвращаем обратно
        Library.Utils.TBT(GlowStroke, 0.3, {Transparency = 0.7, Thickness = 1.2}, Enum.EasingStyle.Quint)
        Library.Utils.TBT(cardScale, 0.3, {Scale = 1}, Enum.EasingStyle.Quint)
    end)

    -- Анимация наведения на "•••"
    Library:Connect(OptionsBtn.MouseEnter, function() 
        Library.Utils.TBT(optScale, 0.2, {Scale = 1.1}) 
        Library.Utils.TBT(OptionsBtn, 0.2, {TextColor3 = Library.CurrentTheme.Accent}) 
        Library.Utils.TBT(OptStroke, 0.2, {Transparency = 0})
    end)
    Library:Connect(OptionsBtn.MouseLeave, function() 
        Library.Utils.TBT(optScale, 0.2, {Scale = 1}) 
        Library.Utils.TBT(OptionsBtn, 0.2, {TextColor3 = Library.CurrentTheme.SubText}) 
        Library.Utils.TBT(OptStroke, 0.2, {Transparency = 0.5})
    end)

    -- Клик по кнопке "•••" (Здесь позже появится Dropdown меню!)
    Library:Connect(OptionsBtn.MouseButton1Click, function()
        local t = Library.Utils.TBT(optScale, 0.1, {Scale = 0.9})
        t.Completed:Connect(function() Library.Utils.TBT(optScale, 0.2, {Scale = 1}, Enum.EasingStyle.Bounce) end)
        
        print("Нажали троеточие на файле: " .. fileName)
    end)
end

return Module
