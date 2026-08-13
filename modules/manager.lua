local HttpService = game:GetService("HttpService")
local Module = {}

-- ==========================================
-- ПОЛНАЯ ЛОГИКА ФАЙЛОВОЙ СИСТЕМЫ
-- ==========================================
Module.FolderName = "DuskAndShine_Houses"

function Module:InitFolder()
    if not isfolder(self.FolderName) then makefolder(self.FolderName) end
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

function Module:LoadHouse(name)
    local path = self.FolderName .. "/" .. name .. ".json"
    if isfile(path) then
        return HttpService:JSONDecode(readfile(path))
    end
    return nil
end

function Module:SaveHouse(name, data)
    self:InitFolder()
    writefile(self.FolderName .. "/" .. name .. ".json", HttpService:JSONEncode(data))
end

function Module:DeleteHouse(name)
    local path = self.FolderName .. "/" .. name .. ".json"
    if isfile(path) then delfile(path) end
end

function Module:RenameHouse(old, new)
    local oldPath = self.FolderName .. "/" .. old .. ".json"
    local newPath = self.FolderName .. "/" .. new .. ".json"
    if isfile(oldPath) then
        writefile(newPath, readfile(oldPath))
        delfile(oldPath)
        return true
    end
    return false
end

-- ==========================================
-- ИНТЕРФЕЙС И РАБОТА С КНОПКАМИ
-- ==========================================
function Module:Init(Library, Window, Tab)
    self.Library = Library
    self.Tab = Tab
    self.ActiveDropdown = nil -- Храним открытое меню, чтобы закрывать старое

    local HeaderPanel = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0, 45), BackgroundTransparency = 1, Parent = Tab.Page })
    Library.Utils.Make("TextLabel", {
        Text = '<b><font color="#ffffff">FILE MANAGER:</font></b> <font color="#9696a0">House Schematics</font>',
        RichText = true, Size = UDim2.new(1, -120, 1, 0), Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = HeaderPanel
    })

    local RefreshBtn = Library.Utils.Make("TextButton", { Text = "", Size = UDim2.new(0, 95, 0, 26), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -20, 0.5, 0), AutoButtonColor = false, Parent = HeaderPanel }, { BackgroundColor3 = "Section" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = RefreshBtn })
    Library.Utils.Make("UIStroke", { Thickness = 1, Transparency = 0.5, Parent = RefreshBtn }, { Color = "Stroke" })

    local RefContent = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = RefreshBtn })
    Library.Utils.Make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), Parent = RefContent })
    local RefIcon = Library.Utils.Make("ImageLabel", { Size = UDim2.new(0, 14, 0, 14), BackgroundTransparency = 1, Image = "rbxassetid://10873923769", Parent = RefContent }, { ImageColor3 = "Text" })
    Library.Utils.Make("TextLabel", { Text = "REFRESH", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11, Parent = RefContent }, { TextColor3 = "Text" })

    Library:Connect(RefreshBtn.MouseButton1Click, function()
        self:RefreshList()
        Library.Utils.TBT(RefIcon, 0.5, {Rotation = 360}); task.delay(0.5, function() RefIcon.Rotation = 0 end)
    end)

    self.ListContainer = Library.Utils.Make("Frame", { Size = UDim2.new(1, -20, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = Tab.Page })
    Library.Utils.Make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.ListContainer })

    self:RefreshList()
end

function Module:RefreshList()
    if self.ActiveDropdown then self.ActiveDropdown:Destroy(); self.ActiveDropdown = nil end

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
-- КАРТОЧКА И ДРОПДАУН МЕНЮ
-- ==========================================
function Module:CreateFileCard(fileName)
    local Library = self.Library

    local Card = Library.Utils.Make("TextButton", { Text = "", Size = UDim2.new(1, 0, 0, 56), AutoButtonColor = false, BackgroundTransparency = 0, ClipsDescendants = false, Parent = self.ListContainer }, { BackgroundColor3 = "Section" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Card })
    Library.Utils.Make("UIStroke", { Thickness = 1, Transparency = 0.7, Parent = Card }, { Color = "Stroke" })

    local FileIcon = Library.Utils.Make("ImageLabel", { Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(0, 14, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1, Image = "rbxassetid://105856032975609", Parent = Card }, { ImageColor3 = "Text" })

    local TitleLbl = Library.Utils.Make("TextLabel", { Text = fileName, Size = UDim2.new(1, -110, 0, 20), Position = UDim2.new(0, 54, 0.5, -10), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = Card }, { TextColor3 = "Text" })
    
    -- Текстовое поле для переименования (Скрыто по умолчанию)
    local RenameBox = Library.Utils.Make("TextBox", {
        Text = fileName, Size = UDim2.new(1, -110, 0, 20), Position = UDim2.new(0, 54, 0.5, -10),
        BackgroundTransparency = 0.5, BackgroundColor3 = Color3.fromRGB(0,0,0),
        Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false, Visible = false, Parent = Card
    }, { TextColor3 = "Accent" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 4), Parent = RenameBox })

    local timeStr = os.date("%H:%M:%S")
    Library.Utils.Make("TextLabel", { Text = "Last-saved " .. timeStr, Size = UDim2.new(1, -110, 0, 15), Position = UDim2.new(0, 54, 0.5, 8), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = Card }, { TextColor3 = "SubText" })

    local OptionsBtn = Library.Utils.Make("TextButton", { Text = "•••", Size = UDim2.new(0, 34, 0, 24), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false, Parent = Card }, { BackgroundColor3 = "Sidebar", TextColor3 = "SubText" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = OptionsBtn })
    Library.Utils.Make("UIStroke", { Thickness = 1, Transparency = 0.5, Parent = OptionsBtn }, { Color = "Stroke" })

    -- === ЛОГИКА ВЫПАДАЮЩЕГО МЕНЮ ===
    local function CreateDropdown()
        if self.ActiveDropdown then self.ActiveDropdown:Destroy() end

        local Dropdown = Library.Utils.Make("Frame", {
            Size = UDim2.new(0, 140, 0, 120),
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -10, 1, 5), -- Появляется чуть ниже кнопки "•••"
            ZIndex = 50,
            Parent = Card
        }, { BackgroundColor3 = "Sidebar" })
        Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Dropdown })
        Library.Utils.Make("UIStroke", { Thickness = 1, Parent = Dropdown }, { Color = "Stroke" })
        Library.Utils.Make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = Dropdown })
        
        self.ActiveDropdown = Dropdown

        local function AddAction(text, colorKey, callback)
            local btn = Library.Utils.Make("TextButton", {
                Text = "  " .. text, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 51, Parent = Dropdown
            }, { TextColor3 = colorKey })
            
            Library:Connect(btn.MouseEnter, function() Library.Utils.TBT(btn, 0.15, {BackgroundTransparency = 0.9}) end)
            Library:Connect(btn.MouseLeave, function() Library.Utils.TBT(btn, 0.15, {BackgroundTransparency = 1}) end)
            Library:Connect(btn.MouseButton1Click, function()
                Dropdown:Destroy()
                self.ActiveDropdown = nil
                pcall(callback)
            end)
        end

        AddAction("✏️ Rename", "Text", function()
            TitleLbl.Visible = false
            RenameBox.Visible = true
            RenameBox.Text = fileName
            RenameBox:CaptureFocus()
        end)

        AddAction("📄 Duplicate", "Text", function()
            local data = self:LoadHouse(fileName)
            if data then
                self:SaveHouse(fileName .. "_copy", data)
                self:RefreshList()
                Library:Notify("File Manager", "Duplicated: " .. fileName, 2)
            end
        end)

        AddAction("📋 Copy Code", "Text", function()
            local data = self:LoadHouse(fileName)
            if data and setclipboard then
                setclipboard(HttpService:JSONEncode(data))
                Library:Notify("Copied", "JSON code copied to clipboard!", 2)
            end
        end)

        AddAction("🗑️ Delete File", "Red", function()
            self:DeleteHouse(fileName)
            self:RefreshList()
            Library:Notify("Deleted", fileName .. " has been removed.", 2)
        end)
    end

    Library:Connect(OptionsBtn.MouseButton1Click, function()
        -- Если меню уже открыто для ЭТОГО файла - закрываем. Иначе открываем новое.
        if self.ActiveDropdown and self.ActiveDropdown.Parent == Card then
            self.ActiveDropdown:Destroy()
            self.ActiveDropdown = nil
        else
            CreateDropdown()
        end
    end)

    -- Логика применения нового имени
    Library:Connect(RenameBox.FocusLost, function()
        RenameBox.Visible = false
        TitleLbl.Visible = true
        
        -- Убираем спецсимволы, оставляем только буквы, цифры и пробелы
        local newName = RenameBox.Text:gsub("[^%w%s%-_]", ""):match("^%s*(.-)%s*$") 
        if newName ~= "" and newName ~= fileName then
            if self:RenameHouse(fileName, newName) then
                self:RefreshList()
                Library:Notify("File Manager", "Renamed to " .. newName, 2)
            end
        else
            RenameBox.Text = fileName -- Если ввели дичь, сбрасываем обратно
        end
    end)
end

return Module
