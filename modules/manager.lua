local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Module = {}

-- ==========================================
-- ЛОГИКА ФАЙЛОВОЙ СИСТЕМЫ
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
    if isfile(path) then return HttpService:JSONDecode(readfile(path)) end
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
    self.ActiveDropdown = nil 

    -- ==========================================
    -- 1. АДАПТИВНАЯ ШАПКА И РЕФРЕШ
    -- ==========================================
    local HeaderPanel = Library.Utils.Make("Frame", { 
        Size = UDim2.new(1, 0, 0, 30), 
        BackgroundTransparency = 1, 
        Parent = Tab.Page 
    })
    
    Library.Utils.Make("TextLabel", {
        Text = '<b>FILE MANAGER:</b> <font color="#9696a0">House Schematics</font>',
        RichText = true, 
        Size = UDim2.new(1, -40, 1, 0), 
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1, 
        Font = Enum.Font.Gotham, 
        TextSize = 14, 
        TextXAlignment = Enum.TextXAlignment.Left, 
        Parent = HeaderPanel
    }, { TextColor3 = "Text" })

    local RefreshBtn = Library.Utils.Make("TextButton", { 
        Size = UDim2.new(0, 26, 0, 26), 
        AnchorPoint = Vector2.new(1, 0.5), 
        Position = UDim2.new(1, 0, 0.5, 0), 
        AutoButtonColor = false, 
        Text = "",
        Parent = HeaderPanel 
    }, { BackgroundColor3 = "Sidebar" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = RefreshBtn })
    
    local RefStroke = Library.Utils.Make("UIStroke", { Thickness = 1, Transparency = 0.5, Parent = RefreshBtn }, { Color = "Stroke" })

    local RefIcon = Library.Utils.Make("ImageLabel", { 
        Size = UDim2.new(0, 16, 0, 16), 
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1, 
        Image = "rbxassetid://6723921202", 
        Parent = RefreshBtn 
    }, { ImageColor3 = "SubText" })

    local refScale = Instance.new("UIScale", RefreshBtn)

    Library:Connect(RefreshBtn.MouseEnter, function() 
        Library.Utils.TBT(RefStroke, 0.2, {Transparency = 0})
        Library.Utils.TBT(RefreshBtn, 0.2, {BackgroundColor3 = Library.CurrentTheme.Section})
        Library.Utils.TBT(RefIcon, 0.2, {ImageColor3 = Library.CurrentTheme.Accent})
    end)
    Library:Connect(RefreshBtn.MouseLeave, function() 
        Library.Utils.TBT(RefStroke, 0.2, {Transparency = 0.5})
        Library.Utils.TBT(RefreshBtn, 0.2, {BackgroundColor3 = Library.CurrentTheme.Sidebar})
        Library.Utils.TBT(RefIcon, 0.2, {ImageColor3 = Library.CurrentTheme.SubText})
    end)
    
    Library:Connect(RefreshBtn.MouseButton1Click, function()
        local t = Library.Utils.TBT(refScale, 0.1, {Scale = 0.9})
        t.Completed:Connect(function() Library.Utils.TBT(refScale, 0.2, {Scale = 1}, Enum.EasingStyle.Bounce) end)
        Library.Utils.TBT(RefIcon, 0.5, {Rotation = 360}); task.delay(0.5, function() RefIcon.Rotation = 0 end)
        
        self:RefreshList()
    end)

    local TopDivider = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BorderSizePixel = 0,
        Parent = Tab.Page
    }, { BackgroundColor3 = "Text" })
    
    local DivGrad = Instance.new("UIGradient", TopDivider)
    DivGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.8),
        NumberSequenceKeypoint.new(1, 1)
    })

    -- ==========================================
    -- 2. КОНТЕЙНЕР ДЛЯ КНОПОК И ФАЙЛОВ
    -- ==========================================
    self.ListContainer = Library.Utils.Make("Frame", { Size = UDim2.new(1, -20, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = Tab.Page })
    Library.Utils.Make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.ListContainer })

    -- ==========================================
    -- 3. ПРЕМИУМ КНОПКА ПАРСЕРА ADOPT ME (GHOST СТИЛЬ)
    -- ==========================================
    local ParseContainer = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
        LayoutOrder = -1, 
        Parent = self.ListContainer
    })

    local ParseGlow = Library.Utils.Make("Frame", { 
        Size = UDim2.new(1, 0, 1, 0), 
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1, 
        ZIndex = 1, 
        Parent = ParseContainer 
    })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = ParseGlow })
    local ParseGlowStroke = Library.Utils.Make("UIStroke", { 
        Thickness = 4, 
        Transparency = 0.85,
        Parent = ParseGlow 
    }, { Color = "Accent" })

    local ParseBtn = Library.Utils.Make("TextButton", {
        Text = "", 
        Size = UDim2.new(1, 0, 1, 0),
        AutoButtonColor = false,
        ZIndex = 5,
        Parent = ParseContainer 
    }, { BackgroundColor3 = "Section" }) 
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = ParseBtn })

    local ParseText = Library.Utils.Make("TextLabel", {
        Text = "💾 EXPORT CURRENT INTERIOR",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        ZIndex = 6,
        Parent = ParseBtn
    }, { TextColor3 = "Accent" }) 

    local ParseEdgeStroke = Library.Utils.Make("UIStroke", { 
        Thickness = 1.5, 
        Transparency = 0.2, 
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = ParseBtn 
    }, { Color = "Accent" })

    local ParseScale = Instance.new("UIScale", ParseContainer)

    Library:Connect(ParseBtn.MouseEnter, function() 
        Library.Utils.TBT(ParseBtn, 0.3, {BackgroundTransparency = 0.3}) 
        Library.Utils.TBT(ParseEdgeStroke, 0.3, {Transparency = 0}) 
        Library.Utils.TBT(ParseGlowStroke, 0.4, {Thickness = 12, Transparency = 0.6}, Enum.EasingStyle.Quint) 
        Library.Utils.TBT(ParseScale, 0.3, {Scale = 1.05}, Enum.EasingStyle.Back, Enum.EasingDirection.Out) 
    end)
    Library:Connect(ParseBtn.MouseLeave, function() 
        Library.Utils.TBT(ParseBtn, 0.3, {BackgroundTransparency = 0}) 
        Library.Utils.TBT(ParseEdgeStroke, 0.3, {Transparency = 0.2})
        Library.Utils.TBT(ParseGlowStroke, 0.4, {Thickness = 4, Transparency = 0.85}, Enum.EasingStyle.Quint)
        Library.Utils.TBT(ParseScale, 0.3, {Scale = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)
    
    Library:Connect(ParseBtn.MouseButton1Click, function()
        local t = Library.Utils.TBT(ParseScale, 0.1, {Scale = 0.95})
        t.Completed:Connect(function() Library.Utils.TBT(ParseScale, 0.2, {Scale = 1}, Enum.EasingStyle.Bounce) end)
        
        task.spawn(function()
            local Fsys = game:GetService("ReplicatedStorage"):WaitForChild("Fsys")
            local loadFsys = require(Fsys).load
            local ClientData = loadFsys("ClientData")
            
            local data = ClientData.get_data()
            local TARGET_OWNER = Players.LocalPlayer.Name 
            local targetData = data[TARGET_OWNER]
            
            if not targetData or not targetData.house_interior then
                return Library:Notify("Ошибка", "Данные интерьера не найдены. Вы точно в доме?", 3)
            end
            
            local rawFurniture = targetData.house_interior.furniture or {}
            local parsedFurniture = {}
            local count = 0
            
            for uniqueId, itemData in pairs(rawFurniture) do
                count = count + 1
                local formattedCFrame = {}
                if typeof(itemData.cframe) == "CFrame" then
                    formattedCFrame = {itemData.cframe:GetComponents()}
                elseif type(itemData.cframe) == "table" then
                    formattedCFrame = itemData.cframe
                end
            
                local formattedColors = {}
                if type(itemData.colors) == "table" then
                    for _, color in ipairs(itemData.colors) do
                        if typeof(color) == "Color3" then
                            table.insert(formattedColors, {color.R, color.G, color.B})
                        end
                    end
                end
            
                table.insert(parsedFurniture, {
                    id = itemData.id,
                    cframe = formattedCFrame,
                    scale = itemData.scale or 1,
                    colors = formattedColors
                })
            end

            local parsedTextures = {}
            local rawTextures = targetData.house_interior.textures or {}
            local textureCount = 0
            
            for roomName, roomData in pairs(rawTextures) do
                parsedTextures[roomName] = {
                    floors = roomData.floors or "",
                    walls = roomData.walls or ""
                }
                textureCount = textureCount + 1
            end

            local rawAmbiance = targetData.house_interior.ambiance or {}
            local parsedParticles = {}
            
            if rawAmbiance.custom_props and rawAmbiance.custom_props.Custom then
                parsedParticles = rawAmbiance.custom_props.Custom
            end
            
            local saveData = {
                furniture = parsedFurniture,
                textures = parsedTextures,  
                ambiance = rawAmbiance,     
                particles = parsedParticles 
            }
            
            local newFileName = "AdoptMeHouse_" .. os.date("%H%M%S")
            self:SaveHouse(newFileName, saveData)
            
            self:RefreshList()
            Library:Notify("Успех!", "Скопировано: " .. count .. " предметов и " .. textureCount .. " комнат. Погода сохранена.", 4)
        end)
    end)

    self:RefreshList()
end

function Module:RefreshList()
    if self.ActiveDropdown then self.ActiveDropdown:Destroy(); self.ActiveDropdown = nil end

    for _, child in ipairs(self.ListContainer:GetChildren()) do
        if child:IsA("TextButton") and child.LayoutOrder ~= -1 then 
            child:Destroy() 
        end
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
    local GlowStroke = Library.Utils.Make("UIStroke", { Thickness = 1, Transparency = 0.7, Parent = Card }, { Color = "Stroke" })

    local FileIcon = Library.Utils.Make("ImageLabel", { Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(0, 14, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1, Image = "rbxassetid://105856032975609", Parent = Card }, { ImageColor3 = "Text" })

    local TitleLbl = Library.Utils.Make("TextLabel", { Text = fileName, Size = UDim2.new(1, -110, 0, 20), Position = UDim2.new(0, 54, 0.5, -10), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14,TextTruncate = Enum.TextTruncate.AtEnd, TextXAlignment = Enum.TextXAlignment.Left, Parent = Card }, { TextColor3 = "Text" })
    
    local RenameBox = Library.Utils.Make("TextBox", {
        Text = fileName, 
        Size = UDim2.new(1, -110, 0, 20), 
        Position = UDim2.new(0, 54, 0.5, -10),
        BackgroundTransparency = 0.5, 
        BackgroundColor3 = Color3.fromRGB(0,0,0),
        Font = Enum.Font.GothamBold, 
        TextSize = 14, 
        TextXAlignment = Enum.TextXAlignment.Left,
        ClipsDescendants = true,
        ClearTextOnFocus = false, 
        Visible = false, 
        Parent = Card
    }, { TextColor3 = "Accent" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 4), Parent = RenameBox })

    local lastValidText = fileName
    
    RenameBox:GetPropertyChangedSignal("Text"):Connect(function()
        local currentText = RenameBox.Text
        local filteredText = currentText:gsub('[<>:"/\\|?*!@#$%%^&()+=%[%]{};\'.,`~№]', "")
        
        if currentText ~= filteredText then
            RenameBox.Text = filteredText
            return 
        end

        local length = utf8.len(filteredText)
        
        if not length or length > 28 then
            RenameBox.Text = lastValidText 
        else
            lastValidText = filteredText 
        end
    end)
    
    local timeStr = os.date("%H:%M:%S")
    Library.Utils.Make("TextLabel", { Text = "Last-saved " .. timeStr, Size = UDim2.new(1, -110, 0, 15), Position = UDim2.new(0, 54, 0.5, 8), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = Card }, { TextColor3 = "SubText" })

    local OptionsBtn = Library.Utils.Make("TextButton", { Text = "•••", Size = UDim2.new(0, 34, 0, 24), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false, Parent = Card }, { BackgroundColor3 = "Sidebar", TextColor3 = "SubText" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = OptionsBtn })
    local OptStroke = Library.Utils.Make("UIStroke", { Thickness = 1, Transparency = 0.5, Parent = OptionsBtn }, { Color = "Stroke" })

    Library:Connect(Card.MouseEnter, function() GlowStroke.Color = Color3.fromRGB(255, 255, 255); Library.Utils.TBT(GlowStroke, 0.2, {Transparency = 0, Thickness = 2}, Enum.EasingStyle.Quint); Library.Utils.TBT(Card, 0.2, {BackgroundTransparency = 0.2}, Enum.EasingStyle.Quint) end)
    Library:Connect(Card.MouseLeave, function() GlowStroke.Color = Library.CurrentTheme.Stroke; Library.Utils.TBT(GlowStroke, 0.2, {Transparency = 0.7, Thickness = 1}, Enum.EasingStyle.Quint); Library.Utils.TBT(Card, 0.2, {BackgroundTransparency = 0}, Enum.EasingStyle.Quint) end)

    Library:Connect(OptionsBtn.MouseEnter, function() Library.Utils.TBT(OptionsBtn, 0.15, {BackgroundColor3 = Library.CurrentTheme.Section, TextColor3 = Library.CurrentTheme.Accent}); Library.Utils.TBT(OptStroke, 0.15, {Transparency = 0}) end)
    Library:Connect(OptionsBtn.MouseLeave, function() Library.Utils.TBT(OptionsBtn, 0.15, {BackgroundColor3 = Library.CurrentTheme.Sidebar, TextColor3 = Library.CurrentTheme.SubText}); Library.Utils.TBT(OptStroke, 0.15, {Transparency = 0.5}) end)

    local function CreateDropdown()
        if self.ActiveDropdown then self.ActiveDropdown:Destroy() end

        local Dropdown = Library.Utils.Make("Frame", { 
            Size = UDim2.new(0, 150, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            AnchorPoint = Vector2.new(1, 0), 
            Position = UDim2.new(1, -10, 1, 5), 
            ZIndex = 50, 
            ClipsDescendants = true,
            Parent = Card 
        }, { BackgroundColor3 = "Sidebar" })
        Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Dropdown })
        Library.Utils.Make("UIStroke", { Thickness = 1, Transparency = 0.3, Parent = Dropdown }, { Color = "Stroke" })
        
        Library.Utils.Make("UIPadding", {
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            Parent = Dropdown
        })
        Library.Utils.Make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = Dropdown })
        
        self.ActiveDropdown = Dropdown

        local dropScale = Instance.new("UIScale", Dropdown)
        dropScale.Scale = 0.8
        Library.Utils.TBT(dropScale, 0.25, {Scale = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        
        local function AddAction(title, iconId, colorKey, hoverColorKey, callback)
            local btn = Library.Utils.Make("TextButton", { 
                Text = "", 
                Size = UDim2.new(1, 0, 0, 32), 
                BackgroundTransparency = 1, 
                ZIndex = 51, 
                AutoButtonColor = false,
                Parent = Dropdown 
            })
            Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })

            local Icon = Library.Utils.Make("ImageLabel", {
                Size = UDim2.new(0, 16, 0, 16),
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 8, 0.5, 0),
                BackgroundTransparency = 1,
                Image = iconId,
                ZIndex = 52,
                Parent = btn
            }, { ImageColor3 = colorKey })

            local TextLbl = Library.Utils.Make("TextLabel", {
                Text = title,
                Size = UDim2.new(1, -32, 1, 0),
                Position = UDim2.new(0, 32, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 52,
                Parent = btn
            }, { TextColor3 = colorKey })

            Library:Connect(btn.MouseEnter, function() 
                Library.Utils.TBT(btn, 0.2, {BackgroundTransparency = 0.8}, Enum.EasingStyle.Quint) 
                Library.Utils.TBT(TextLbl, 0.2, {TextColor3 = Library.CurrentTheme[hoverColorKey] or Color3.fromRGB(255,255,255)}, Enum.EasingStyle.Quint)
                Library.Utils.TBT(Icon, 0.2, {ImageColor3 = Library.CurrentTheme[hoverColorKey] or Color3.fromRGB(255,255,255)}, Enum.EasingStyle.Quint)
            end)
            Library:Connect(btn.MouseLeave, function() 
                Library.Utils.TBT(btn, 0.2, {BackgroundTransparency = 1}, Enum.EasingStyle.Quint) 
                Library.Utils.TBT(TextLbl, 0.2, {TextColor3 = Library.CurrentTheme[colorKey]}, Enum.EasingStyle.Quint)
                Library.Utils.TBT(Icon, 0.2, {ImageColor3 = Library.CurrentTheme[colorKey]}, Enum.EasingStyle.Quint)
            end)

            Library:Connect(btn.MouseButton1Click, function() 
                local closeTween = Library.Utils.TBT(dropScale, 0.15, {Scale = 0.8})
                Library.Utils.TBT(Dropdown, 0.15, {BackgroundTransparency = 1})
                closeTween.Completed:Connect(function()
                    Dropdown:Destroy()
                    self.ActiveDropdown = nil
                end)
                pcall(callback) 
            end)
        end

        -- ID иконок нужно будет заменить на твои актуальные из Роблокса
        AddAction("Rename", "rbxassetid://11552554707", "SubText", "Text", function() 
            TitleLbl.Visible = false; RenameBox.Visible = true; RenameBox.Text = fileName; RenameBox:CaptureFocus() 
        end)
        AddAction("Duplicate", "rbxassetid://11552809117", "SubText", "Text", function() 
            local data = self:LoadHouse(fileName); if data then self:SaveHouse(fileName .. "_copy", data); self:RefreshList(); Library:Notify("File Manager", "Duplicated: " .. fileName, 2) end 
        end)
        AddAction("Copy Code", "rbxassetid://10631627960", "SubText", "Accent", function() 
            local data = self:LoadHouse(fileName); if data and setclipboard then setclipboard(HttpService:JSONEncode(data)); Library:Notify("Copied", "JSON code copied to clipboard!", 2) end 
        end)
        AddAction("Delete File", "rbxassetid://11552825838", "Red", "Red", function() 
            self:DeleteHouse(fileName); self:RefreshList(); Library:Notify("Deleted", fileName .. " has been removed.", 2) 
        end)
    end

    Library:Connect(OptionsBtn.MouseButton1Click, function()
        Library.Utils.TBT(OptionsBtn, 0.1, {BackgroundColor3 = Library.CurrentTheme.Text}); task.delay(0.1, function() Library.Utils.TBT(OptionsBtn, 0.2, {BackgroundColor3 = Library.CurrentTheme.Section}) end)
        if self.ActiveDropdown and self.ActiveDropdown.Parent == Card then self.ActiveDropdown:Destroy(); self.ActiveDropdown = nil else CreateDropdown() end
    end)

    Library:Connect(RenameBox.FocusLost, function()
        RenameBox.Visible = false; TitleLbl.Visible = true
        
        local newName = RenameBox.Text:match("^%s*(.-)%s*$") 
        
        if newName and newName ~= "" and newName ~= fileName then
            if self:RenameHouse(fileName, newName) then 
                self:RefreshList() 
                Library:Notify("File Manager", "Renamed to " .. newName, 2) 
            end
        else 
            RenameBox.Text = fileName 
        end
    end)
end

return Module
