local HttpService = game:GetService("HttpService")
local Module = {}
print("[DEBUG] Скрипт менеджера файлов скачан и прочитан!") -- <== ДОБАВЬ ЭТО
-- ==========================================
-- ЛОГИКА ФАЙЛОВОЙ СИСТЕМЫ (Только для этого модуля)
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
        if fileName then
            table.insert(houses, fileName)
        end
    end
    return houses
end

-- ==========================================
-- ИНТЕРФЕЙС (UI)
-- ==========================================
function Module:Init(Library, Window, Tab)
    self.Library = Library
    self.Tab = Tab

    Tab:CreateSection({ Name = "FILE MANAGER: House Schematics" })

    Tab:CreateButton({
        Name = "🔄 Refresh List",
        Callback = function()
            self:RefreshList()
            Library:Notify("File Manager", "List refreshed successfully!", 2)
        end
    })

    -- Контейнер для списка файлов
    self.ListContainer = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = Tab.Page
    })
    
    Library.Utils.Make("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.ListContainer
    })

    -- Первичная загрузка
    self:RefreshList()
end

function Module:RefreshList()
    -- Очищаем старые файлы
    for _, child in ipairs(self.ListContainer:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then 
            child:Destroy() 
        end
    end

    -- Получаем список файлов через нашу локальную функцию
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

function Module:CreateFileCard(fileName)
    local Library = self.Library

    local Card = Library.Utils.Make("Frame", { 
        Size = UDim2.new(1, 0, 0, 50), 
        Parent = self.ListContainer 
    }, { BackgroundColor3 = "Section" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Card })
    Library.Utils.Make("UIStroke", { Thickness = 1, Transparency = 0.5, Parent = Card }, { Color = "Stroke" })

    local FileIcon = Library.Utils.Make("ImageLabel", {
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 15, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://99263938121768", 
        Parent = Card
    })
    Library.ThemeObjects[FileIcon] = { ImageColor3 = "SubText" }
    FileIcon.ImageColor3 = Library.CurrentTheme.SubText

    Library.Utils.Make("TextLabel", { 
        Text = fileName, 
        Size = UDim2.new(1, -100, 0, 20), 
        Position = UDim2.new(0, 50, 0.5, -10), 
        BackgroundTransparency = 1, 
        Font = Enum.Font.GothamBold, 
        TextSize = 14, 
        TextXAlignment = Enum.TextXAlignment.Left, 
        Parent = Card 
    }, { TextColor3 = "Text" })

    Library.Utils.Make("TextLabel", { 
        Text = ".json file", 
        Size = UDim2.new(1, -100, 0, 15), 
        Position = UDim2.new(0, 50, 0.5, 8), 
        BackgroundTransparency = 1, 
        Font = Enum.Font.Gotham, 
        TextSize = 11, 
        TextXAlignment = Enum.TextXAlignment.Left, 
        Parent = Card 
    }, { TextColor3 = "SubText" })

    local OptionsBtn = Library.Utils.Make("TextButton", { 
        Text = "•••", 
        Size = UDim2.new(0, 36, 0, 26), 
        AnchorPoint = Vector2.new(1, 0.5), 
        Position = UDim2.new(1, -12, 0.5, 0), 
        Font = Enum.Font.GothamBold, 
        TextSize = 14,
        AutoButtonColor = false,
        Parent = Card 
    }, { BackgroundColor3 = "Sidebar", TextColor3 = "SubText" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = OptionsBtn })
    Library.Utils.Make("UIStroke", { Thickness = 1, Parent = OptionsBtn }, { Color = "Stroke" })

    local optScale = Instance.new("UIScale", OptionsBtn)
    Library:Connect(OptionsBtn.MouseEnter, function() 
        Library.Utils.TBT(optScale, 0.2, {Scale = 1.05}) 
        Library.Utils.TBT(OptionsBtn, 0.2, {TextColor3 = Library.CurrentTheme.Accent}) 
    end)
    Library:Connect(OptionsBtn.MouseLeave, function() 
        Library.Utils.TBT(optScale, 0.2, {Scale = 1}) 
        Library.Utils.TBT(OptionsBtn, 0.2, {TextColor3 = Library.CurrentTheme.SubText}) 
    end)

    Library:Connect(OptionsBtn.MouseButton1Click, function()
        local t = Library.Utils.TBT(optScale, 0.1, {Scale = 0.9})
        t.Completed:Connect(function() Library.Utils.TBT(optScale, 0.2, {Scale = 1}, Enum.EasingStyle.Bounce) end)
        
        print("Нажали троеточие на файле: " .. fileName)
    end)
end

return Module
