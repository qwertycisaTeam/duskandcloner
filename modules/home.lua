local Module = {}

function Module:Init(Library, Window, Tab)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    -- ==========================================
    -- 1. WELCOME SECTION
    -- ==========================================
    Tab:CreateSection({ Name = "Home" })
    
    Tab:CreateNotice({ 
        Text = "<b>VIP Servers Only:</b> Please use our script only on private servers and use only version from <b>discord.gg/duskshine!</b> Beware of scammers." 
    })
    
    -- В нашей либе %s автоматически заменяется на DisplayName, когда передается Icon = "avatar"
    Tab:CreateLabel({ 
        Text = "Welcome back, <b><font color='rgb(255,255,255)'>%s</font></b>!", 
        Icon = "avatar" 
    })

    -- Создаем лейбл лога и сохраняем его в переменную, чтобы потом обновить текст
    local UpdateLogLabel = Tab:CreateLabel({ Text = "Fetching update log..." })

    task.spawn(function()
        -- Динамически подтягиваем домен (локалхост из оркестратора или прод)
        local domain = getgenv().DuskDomain or "http://192.168.50.161"
        local localUrl = domain .. "/api/updatelog/" .. tostring(getgenv().ScriptID)
        
        local success, res = pcall(function()
            return game:HttpGet(localUrl)
        end)
        
        if success and res and res ~= "" and not res:match("Not Found") then
            -- Обновляем текст через безопасный метод из нашей либы
            UpdateLogLabel.SetText(res)
        else
            UpdateLogLabel.SetText("Failed to load update log. API offline.")
        end
    end)

    -- ==========================================
    -- 2. SERVER UTILITIES
    -- ==========================================
    Tab:CreateSection({ Name = "Server Utilities" })

    Tab:CreateNotice({ 
        Text = "If you want to teleport, use <b>Server Hop</b> or rejoin. Turn off <i>\"Disable Teleports\"</i> and <i>\"Anti-Scam\"</i> in Delta. Other executors don't require this." 
    })

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
                    -- Ищем первый попавшийся сервер, где есть минимум 3 свободных места
                    if s.playing <= (s.maxPlayers - 3) and s.id ~= game.JobId then
                        TPS:TeleportToPlaceInstance(game.PlaceId, s.id)
                        return
                    end
                end
            end
        end
        -- Fallback: если не нашли публичный сервер, просто кидаем в новый
        TPS:Teleport(game.PlaceId)
    end

    Tab:CreateButton({ Name = "Server Hop", Callback = ServerHop })
    Tab:CreateButton({ Name = "Rejoin Server", Callback = RejoinServer })

    -- ==========================================
    -- 3. DEVELOPER CONNECTION
    -- ==========================================
    Tab:CreateSection({ Name = "Developer Connection" })
    
    Tab:CreateLabel({ Text = "Telegram: @afont1337" })

    -- Используем компонент CreateCopyLink 
    Tab:CreateCopyLink({ 
        Name = "t.me/DuskAndShine", 
        Url = "https://t.me/DuskAndShine" 
    })
    
    Tab:CreateCopyLink({ 
        Name = "Site", 
        Url = "https://duskandshine.xyz" 
    })
    
    Tab:CreateCopyLink({ 
        Name = "Discord", 
        Url = "https://discord.gg/duskshine" 
    })
end

return Module
