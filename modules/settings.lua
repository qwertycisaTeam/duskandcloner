local Module = {}

function Module:Init(Library, Window, Tab)
    -- ==========================================
    -- СЕКЦИЯ: UI SETTINGS
    -- ==========================================
    Tab:CreateSection({ Name = "UI Settings" })

    Tab:CreateToggle({
        Name = "Menu Particles",
        Description = "Falling stars and comets in background.",
        Default = true,
        Flag = "UI_Particles",
        Callback = function(state)
            Library.Settings.MenuParticles = state
            -- Здесь вызываешь функцию партиклов, если state == true
        end
    })

    Tab:CreateSlider({
        Name = "UI Scale (%)",
        Min = 50,
        Max = 150,
        Default = 100,
        Flag = "UI_Scale",
        Callback = function(value)
            -- Меняем масштаб (Window.MainUIScale должен быть добавлен в таблицу Window в ядре!)
            if Window.MainUIScale then
                Window.MainUIScale.Scale = value / 100
            end
        end
    })

    Tab:CreateColorPicker({
        Name = "UI Accent Color",
        Default = Color3.fromRGB(46, 204, 113),
        Flag = "UI_Accent",
        Callback = function(color)
            -- Обновляем акцентный цвет текущей темы
            Library.CurrentTheme.Accent = color
            for UIElement, Props in pairs(Library.ThemeObjects) do
                for Property, ThemeKey in pairs(Props) do
                    if ThemeKey == "Accent" then
                        Library.Utils.TBT(UIElement, 0.3, {[Property] = color})
                        if not UIElement:IsA("ImageLabel") then
                            Library.Utils.ApplyGradient(UIElement, color)
                        end
                    end
                end
            end
        end
    })

    Tab:CreateToggle({
        Name = "Menu Blur",
        Description = "Blur background when menu is open",
        Default = false,
        Flag = "UI_Blur",
        Callback = function(state)
            -- Логика включения/отключения BlurEffect в Lighting
        end
    })

    -- ==========================================
    -- СЕКЦИЯ: GLOBAL SETTINGS
    -- ==========================================
    Tab:CreateSection({ Name = "Global Settings" })

    Tab:CreateToggle({
        Name = "Auto-Update Kicker",
        Description = "Kicks you from the server if a new script version is found.",
        Default = false,
        Flag = "Global_AutoUpdate"
    })

    Tab:CreateToggle({
        Name = "Anonymous Mode",
        Description = "Hides your identity to prevent streaming snipes.",
        Default = false,
        Flag = "Global_AnonMode",
        Callback = function(state)
            Library.Settings.AnonymousMode = state
            
            -- Прячем/показываем аватарки
            for _, item in ipairs(Library.AnonItems.Avatars) do
                if state then
                    item.ImageObj.ImageTransparency = 1
                    item.ImageObj.BackgroundTransparency = 0
                    item.ImageObj.BackgroundColor3 = Color3.new(0, 0, 0)
                    if item.Letter then item.Letter.Visible = true end
                else
                    item.ImageObj.ImageTransparency = 0
                    item.ImageObj.BackgroundTransparency = 1
                    if item.Letter then item.Letter.Visible = false end
                end
            end
            
            -- Прячем/показываем ники
            for _, item in ipairs(Library.AnonItems.Names) do
                if state then
                    item.Obj.Text = string.format(item.Format, "Hidden User")
                else
                    item.Obj.Text = string.format(item.Format, game:GetService("Players").LocalPlayer.DisplayName)
                end
            end
        end
    })

    Tab:CreateToggle({
        Name = "Anti-AFK",
        Description = "Prevent Roblox kick",
        Default = true, 
        Flag = "Global_AntiAFK",
        Callback = function(state)
            -- Твой обход Anti-AFK
        end
    })

    Tab:CreateKeybind({
        Name = "Toggle Menu Key",
        Default = Enum.KeyCode.RightControl,
        Flag = "Global_MenuKey",
        Callback = function(key)
            -- Обновляем бинд на кнопку сворачивания
        end
    })

    -- Кнопка для сохранения всех настроек (чтобы конфиг записался в файл)
    Tab:CreateButton({
        Name = "Save Configuration",
        Callback = function()
            Library:SaveConfig("DuskShine_Settings")
        end
    })
end

return Module
