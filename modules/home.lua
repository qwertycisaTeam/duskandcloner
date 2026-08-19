local Module = {}

function Module:Init(Library, Window, Tab)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    -- Безопасная проверка стейта
    local isAnonymous = getgenv().AnonymousMode or (Library.Settings and Library.Settings.AnonymousMode) or false 
    
    -- БРОНЕБОЙНАЯ ПРОВЕРКА ИМЕНИ (чтобы не словить nil и краш)
    local displayName = LocalPlayer.Name
    pcall(function()
        if LocalPlayer.DisplayName and LocalPlayer.DisplayName ~= "" then
            displayName = LocalPlayer.DisplayName
        end
    end)
    if isAnonymous then displayName = "Hidden User" end

    local NameFont = Enum.Font.GothamBold
    local fancyFonts = {"Shojumaru", "Macondo", "AmaticSC", "Fantasy"}

    for _, fontName in ipairs(fancyFonts) do
        local success, fontEnum = pcall(function() return Enum.Font[fontName] end)
        if success and fontEnum then
            NameFont = fontEnum
            break -- Нашли рабочий красивый шрифт, останавливаем поиск
        end
    end

    -- ==========================================
    -- 1. WELCOME SECTION
    -- ==========================================
    Tab:CreateSection({ Name = "Home" })
    
    local greetings = {
        "Hello", 
        "Welcome back", 
        "Wassup dear"
    }
    local randomGreeting = greetings[math.random(1, #greetings)]

    local WelcomeFrame = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundTransparency = 1,
        Parent = Tab.Page
    })

    local AvatarImage = Library.Utils.Make("ImageLabel", {
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0, 10, 0.5, -25),
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150",
        BackgroundTransparency = isAnonymous and 0 or 1,
        BackgroundColor3 = Color3.new(0, 0, 0),
        ImageTransparency = isAnonymous and 1 or 0,
        Parent = WelcomeFrame
    })
    Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = AvatarImage})

    local AvatarLetter = Library.Utils.Make("TextLabel", {
        Text = "?", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 24,
        Visible = isAnonymous, Parent = AvatarImage
    }, { TextColor3 = "Text" })

    Library.Utils.Make("TextLabel", {
        Text = randomGreeting .. ",",
        Size = UDim2.new(1, -75, 0, 20),
        Position = UDim2.new(0, 75, 0.5, -20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = WelcomeFrame
    }, { TextColor3 = "SubText" })

    local UsernameLabel = Library.Utils.Make("TextLabel", {
        Text = displayName .. "!",
        Size = UDim2.new(1, -75, 0, 35), -- Увеличили высоту контейнера (было 25)
        Position = UDim2.new(0, 75, 0.5, 0),
        BackgroundTransparency = 1,
        Font = NameFont,
        TextSize = 28, -- Сделали шрифт крупнее (было 22)
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = WelcomeFrame
    }, { TextColor3 = "Accent" })

    Library.Utils.Make("UIStroke", {
        Thickness = 1, -- Сильно уменьшили толщину обводки (было 2.5)
        Transparency = 0.3, -- Сделали свечение чуть плотнее, раз оно теперь тонкое
        Parent = UsernameLabel
    }, { Color = "Accent" })

    if Library.AnonItems then
        table.insert(Library.AnonItems.Avatars, {
            ImageObj = AvatarImage,
            Letter = AvatarLetter
        })
        table.insert(Library.AnonItems.Names, {
            Obj = UsernameLabel,
            Format = "%s!"
        })
    end

    local UpdateLogLabel = Tab:CreateLabel({ Text = "Fetching update log..." })

    task.spawn(function()
        local domain = getgenv().DuskDomain or "http://192.168.50.161"
        local localUrl = domain .. "/api/updatelog/" .. tostring(getgenv().ScriptID)
        
        local success, res = pcall(function()
            return game:HttpGet(localUrl)
        end)
        
        if success and res and res ~= "" and not res:match("Not Found") then
            UpdateLogLabel.SetText(res)
        else
            UpdateLogLabel.SetText("Failed to load update log. API offline.")
        end
    end)

    -- ==========================================
    -- 2. SERVER UTILITIES
    -- ==========================================
    Tab:CreateSection({ Name = "Server Utilities" })

    local function RejoinServer()
        local ts = game:GetService("TeleportService")
        ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end

    local function ServerHop()
        local Http = game:GetService("HttpService")
        local TPS = game:GetService("TeleportService")
        local Api = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
        
        local success, result = pcall(function() return game:HttpGet(Api) end)
        if success then
            local data = Http:JSONDecode(result)
            if data and data.data then
                for _, s in ipairs(data.data) do
                    if s.playing <= (s.maxPlayers - 3) and s.id ~= game.JobId then
                        TPS:TeleportToPlaceInstance(game.PlaceId, s.id)
                        return
                    end
                end
            end
        end
        TPS:Teleport(game.PlaceId)
    end

    local function CreateActionCard(name, desc, iconId, callback)
        local F = Library.Utils.Make("Frame", {
            Size = UDim2.new(1, 0, 0, 46),
            Parent = Tab.Page
        }, { BackgroundColor3 = "Section" })
        
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 8), Parent = F})
        local FStroke = Library.Utils.Make("UIStroke", {Thickness = 1, Parent = F}, {Color = "Stroke"})

        local Btn = Library.Utils.Make("TextButton", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = F
        })

        Library.Utils.Make("TextLabel", {
            Text = name, Size = UDim2.new(1, -45, 0, 16), Position = UDim2.new(0, 14, 0, 8),
            BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = F
        }, { TextColor3 = "Text" })

        Library.Utils.Make("TextLabel", {
            Text = desc, Size = UDim2.new(1, -45, 0, 14), Position = UDim2.new(0, 14, 0, 26),
            BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = F
        }, { TextColor3 = "SubText" })

        -- ВОТ ЗДЕСЬ ИКОНКА СТАЛА DECAL (ImageLabel)
        local Icon = Library.Utils.Make("ImageLabel", {
            Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -30, 0.5, -9),
            BackgroundTransparency = 1, Image = iconId, Parent = F
        }, { ImageColor3 = "SubText" })

        Library:Connect(Btn.MouseEnter, function() 
            Library.Utils.TBT(FStroke, 0.25, {Color = Library.CurrentTheme.Accent})
            -- Анимация: иконка плавно увеличивается и красится в цвет акцента
            Library.Utils.TBT(Icon, 0.25, {ImageColor3 = Library.CurrentTheme.Accent, Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -32, 0.5, -11)}) 
        end)
        
        Library:Connect(Btn.MouseLeave, function() 
            Library.Utils.TBT(FStroke, 0.25, {Color = Library.CurrentTheme.Stroke})
            Library.Utils.TBT(Icon, 0.25, {ImageColor3 = Library.CurrentTheme.SubText, Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -30, 0.5, -9)})
        end)

        Library:Connect(Btn.MouseButton1Click, function()
            Library.Utils.CreateRipple(F)
            pcall(callback)
        end)
    end

    -- Вызовы функции: 3-м аргументом передаем Asset ID нужной картинки
    CreateActionCard("Server Hop", "Finds and joins a new public server", "rbxassetid://115929304045144", ServerHop)
    CreateActionCard("Rejoin Server", "Reconnects to the current server instance", "rbxassetid://100152237482023", RejoinServer)

    -- ==========================================
    -- 3. COMMUNITY & LINKS
    -- ==========================================
    Tab:CreateSection({ Name = "Community & Links" })

    -- НОВАЯ ФУНКЦИЯ ДЛЯ КАРТИНОК (вместо InjectHoverEmoji)
    local function InjectHoverIcon(iconId)
        local elements = Tab.Page:GetChildren()
        local lastFrame = nil
        
        for i = #elements, 1, -1 do
            if elements[i]:IsA("Frame") then
                lastFrame = elements[i]
                break
            end
        end
        
        if lastFrame then
            local Btn = lastFrame:FindFirstChildOfClass("TextButton", true)
            if Btn then
                -- Картинка вместо текста
                local BigIcon = Library.Utils.Make("ImageLabel", {
                    Image = iconId, Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(1, -50, 0.5, -20),
                    BackgroundTransparency = 1, ImageTransparency = 1, Parent = lastFrame
                }, { ImageColor3 = "Accent" })
                
                Library:Connect(Btn.MouseEnter, function() 
                    Library.Utils.TBT(BigIcon, 0.25, {Size = UDim2.new(0, 48, 0, 48), Position = UDim2.new(1, -54, 0.5, -24), ImageTransparency = 0.4}) 
                end)
                
                Library:Connect(Btn.MouseLeave, function() 
                    Library.Utils.TBT(BigIcon, 0.25, {Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(1, -50, 0.5, -20), ImageTransparency = 1})
                end)
            end
        end
    end

    Tab:CreateCopyLink({ 
        Name = "Telegram Channel", 
        Url = "https://t.me/DuskAndShine",
        NotifyIcon = "rbxassetid://10723426722",
        NotifyLogo = "rbxassetid://72958619361915"
    })
    InjectHoverIcon("rbxassetid://129003197083110") -- Иконка самолетика
    
    Tab:CreateCopyLink({ 
        Name = "Official Website", 
        Url = "https://duskandshine.xyz",
        NotifyIcon = "rbxassetid://10723426722",
        NotifyLogo = "rbxassetid://72958619361915"
    })
    InjectHoverIcon("rbxassetid://7733954760") -- Иконка глобуса
    
    Tab:CreateCopyLink({ 
        Name = "Discord Server", 
        Url = "https://discord.gg/duskshine",
        NotifyIcon = "rbxassetid://10723426722",
        NotifyLogo = "rbxassetid://72958619361915"
    })
    InjectHoverIcon("rbxassetid://18505728201") -- Иконка дискорда

end

return Module
