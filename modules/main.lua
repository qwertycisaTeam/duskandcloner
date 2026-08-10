local Module = {}

function Module:Init(Library, Window, Tab)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    -- ==========================================
    -- 1. ОСНОВНЫЕ ДЕЙСТВИЯ (ACTIONS)
    -- ==========================================
    Tab:CreateSection({ Name = "House Replicator Actions" })
    
    Tab:CreateNotice({ 
        Text = "Встань внутрь дома, который хочешь скопировать, перед использованием функций." 
    })

    -- Вызов нашей новой функции с большими кнопками-картинками
    Tab:CreateImageButton({
        Name = "COPY - Сохранить структуру",
        Image = "rbxassetid://0", -- Вставь сюда ID картинки COPY, загруженной в Roblox
        Callback = function()
            Library:Notify("Replicator", "Сканирование мебели и стен началось...", 3)
            -- Здесь будет твоя логика лупа по CollectionService или Workspace для сбора данных дома
        end
    })

    Tab:CreateImageButton({
        Name = "PASTE - Воспроизвести",
        Image = "rbxassetid://0", -- Вставь сюда ID картинки PASTE, загруженной в Roblox
        Callback = function()
            Library:Notify("Replicator", "Начинаю постройку дома...", 3)
            -- Здесь будет вызов RemoteEvents через SimpleSpy для спавна мебели
        end
    })

    -- ==========================================
    -- 2. НАСТРОЙКИ РЕПЛИКАТОРА (SETTINGS)
    -- ==========================================
    Tab:CreateSection({ Name = "Replicator Settings" })

    -- Тоггл для включения/выключения копирования обоев и полов
    Tab:CreateToggle({
        Name = "Copy Textures",
        Description = "Копировать обои и покрытие полов",
        Default = true,
        Flag = "Replicator_CopyTextures",
        Callback = function(state)
            -- state возвращает true или false
        end
    })

    -- Ползунок для регулировки скорости постройки (чтобы не кикало за спам ремутами)
    Tab:CreateSlider({
        Name = "Build Delay (ms)",
        Min = 10,
        Max = 500,
        Default = 50,
        Flag = "Replicator_BuildDelay",
        Callback = function(value)
            -- value возвращает выбранную задержку
        end
    })

    -- Дропдаун для выбора пресетов, если захочешь сохранять дома в файлы
    Tab:CreateDropdown({
        Name = "Saved Presets",
        Options = {"None", "Modern Mansion", "Cozy Cabin", "Tiny Home"},
        Default = "None",
        Flag = "Replicator_Preset",
        Callback = function(option)
            Library:Notify("Preset Loaded", "Выбран пресет: " .. option, 3)
        end
    })
end

return Module
