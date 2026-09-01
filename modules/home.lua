local Module = {}

function Module:Init(Library, Window, Tab)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    local isAnonymous = getgenv().AnonymousMode or (Library.Settings and Library.Settings.AnonymousMode) or false 
    
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
        if success and fontEnum then NameFont = fontEnum; break end
    end

    -- ==========================================
    -- 1. WELCOME SECTION & STATS (Улучшенные пропорции)
    -- ==========================================
    Tab:CreateDivider({ Text = "Home" }) -- Новая плашка вместо секции
    
    local greetings = { "Hello", "Welcome back", "Wassup dear" }
    local randomGreeting = greetings[math.random(1, #greetings)]

    -- Сделали блок выше (110px), чтобы всё дышало
    local TopContainer = Library.Utils.Make("Frame", {
        Size = UDim2.new(1, 0, 0, 110), 
        BackgroundTransparency = 1,
        Parent = Tab.Page
    })

    -- ЛЕВАЯ ЧАСТЬ (Приветствие)
    local WelcomeFrame = Library.Utils.Make("Frame", {
        Size = UDim2.new(0.5, -5, 1, 0), Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1, Parent = TopContainer
    })

    -- Увеличили аватарку (60x60)
    local AvatarImage = Library.Utils.Make("ImageLabel", {
        Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0, 10, 0.5, -30),
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150",
        BackgroundTransparency = isAnonymous and 0 or 1, BackgroundColor3 = Color3.new(0, 0, 0),
        ImageTransparency = isAnonymous and 1 or 0, Parent = WelcomeFrame
    })
    Library.Utils.Make("UICorner", {CornerRadius = UDim.new(1, 0), Parent = AvatarImage})

    local AvatarLetter = Library.Utils.Make("TextLabel", {
        Text = "?", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 28, Visible = isAnonymous, Parent = AvatarImage
    }, { TextColor3 = "Accent" })

    -- Сдвинули тексты и увеличили шрифты
    Library.Utils.Make("TextLabel", {
        Text = randomGreeting .. ",", Size = UDim2.new(1, -85, 0, 20), Position = UDim2.new(0, 85, 0.5, -24),
        BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = WelcomeFrame
    }, { TextColor3 = "SubText" })

    local UsernameLabel = Library.Utils.Make("TextLabel", {
        Text = displayName .. "!", Size = UDim2.new(1, -85, 0, 35), Position = UDim2.new(0, 85, 0.5, -4),
        BackgroundTransparency = 1, Font = NameFont, TextSize = 26,
        TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true, Parent = WelcomeFrame
    }, { TextColor3 = "Accent" })
    Library.Utils.Make("UITextSizeConstraint", {MaxTextSize = 28, MinTextSize = 14, Parent = UsernameLabel})

    if Library.AnonItems then
        table.insert(Library.AnonItems.Avatars, {ImageObj = AvatarImage, Letter = AvatarLetter})
        table.insert(Library.AnonItems.Names, {Obj = UsernameLabel, Format = "%s!"})
    end

    -- ==========================================
    -- 2. UPDATE LOG
    -- ==========================================
    Tab:CreateDivider({ Text = "Latest Update" }) -- Добавили разделитель!
    local UpdateLogLabel = Tab:CreateLabel({ Text = "Fetching update log..." })

    task.spawn(function()
        local domain = getgenv().DuskDomain or "http://192.168.50.161"
        local localUrl = domain .. "/api/updatelog/" .. tostring(getgenv().ScriptID)
        local success, res = pcall(function() return game:HttpGet(localUrl) end)
        if success and res and res ~= "" and not res:match("Not Found") then
            UpdateLogLabel.SetText(res)
        else
            UpdateLogLabel.SetText("Failed to load update log. API offline.")
        end
    end)

    -- ==========================================
    -- СОВРЕМЕННЫЙ ШАБЛОН ДЛЯ КАРТОЧЕК
    -- ==========================================
    local function CreateModernCard(name, desc, iconId, callback)
        local Card = Library.Utils.Make("Frame", { Size = UDim2.new(1, 0, 0, 60), Parent = Tab.Page }, { BackgroundColor3 = "Section" })
        Library.Utils.Make("UICorner", {CornerRadius = UDim.new(0, 8), Parent = Card})
        local Stroke = Library.Utils.Make("UIStroke", {Thickness = 1, Parent = Card}, { Color = "Stroke" })
        
        Library.Utils.Make("TextLabel", { Text = name, Size = UDim2.new(1, -70, 0, 16), Position = UDim2.new(0, 15, 0, 12), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = Card }, { TextColor3 = "Text" })
        Library.Utils.Make("TextLabel", { Text = desc, Size = UDim2.new(1, -70, 0, 14), Position = UDim2.new(0, 15, 0, 32), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = Card }, { TextColor3 = "SubText" })
        
        local Btn = Library.Utils.Make("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = Card })
        local Icon = Library.Utils.Make("ImageLabel", { Size = UDim2.new(0, 24, 0, 24), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -15, 0.5, 0), BackgroundTransparency = 1, Image = iconId, Parent = Card }, { ImageColor3 = "SubText" })

        Library:Connect(Btn.MouseEnter, function() 
            Library.Utils.TBT(Stroke, 0.25, {Color = Library.CurrentTheme.Accent})
            Library.Utils.TBT(Icon, 0.25, {ImageColor3 = Library.CurrentTheme.Accent, Size = UDim2.new(0, 28, 0, 28)}) 
        end)
        Library:Connect(Btn.MouseLeave, function() 
            Library.Utils.TBT(Stroke, 0.25, {Color = Library.CurrentTheme.Stroke})
            Library.Utils.TBT(Icon, 0.25, {ImageColor3 = Library.CurrentTheme.SubText, Size = UDim2.new(0, 24, 0, 24)})
        end)
        Library:Connect(Btn.MouseButton1Click, function()
            Library.Utils.CreateRipple(Card)
            pcall(callback)
        end)
    end

    -- ==========================================
    -- 3. SERVER UTILITIES
    -- ==========================================
    Tab:CreateDivider({ Text = "Server Utilities" }) -- Плашка!

    local function RejoinServer()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
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

    CreateModernCard("Server Hop", "Finds and joins a new public server", "rbxassetid://115929304045144", ServerHop)
    CreateModernCard("Rejoin Server", "Reconnects to the current server instance", "rbxassetid://100152237482023", RejoinServer)

    -- ==========================================
    -- 4. COMMUNITY & LINKS
    -- ==========================================
    Tab:CreateDivider({ Text = "Community & Links" }) -- Плашка!

    local function CopyToClipboard(text, notifyName)
        if setclipboard then
            setclipboard(text)
            if Library.Notify then 
                -- 4-й аргумент: Иконка скрепки (10723426722)
                -- 5-й аргумент: Фоновый водяной знак (72958619361915)
                Library:Notify(
                    "Link Copied!", 
                    "Copied " .. notifyName .. " to clipboard.", 
                    3, 
                    "rbxassetid://10723426722", 
                    "rbxassetid://72958619361915"
                ) 
            end
        end
    end

    -- Заменили старые линки на новые современные карточки
    CreateModernCard("Telegram Channel", "https://t.me/DuskAndShine", "rbxassetid://111514738904110", function()
        CopyToClipboard("https://t.me/DuskAndShine", "Telegram Link")
    end)
    
    CreateModernCard("Official Website", "https://duskandshine.xyz", "rbxassetid://7733954760", function()
        CopyToClipboard("https://duskandshine.xyz", "Website Link")
    end)
    
    CreateModernCard("Discord Server", "https://discord.gg/duskshine", "rbxassetid://112538196670712", function()
        CopyToClipboard("https://discord.gg/duskshine", "Discord Link")
    end)

end

return Module
