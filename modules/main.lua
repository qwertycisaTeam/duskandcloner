local Module = {}

function Module:Init(Library, Window, Tab)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    -- ==========================================
    -- 1. ОСНОВНЫЕ ДЕЙСТВИЯ (ACTIONS)
    -- ==========================================
    Tab:CreateSection({ Name = "House Replicator Actions" })
    -- Пример создания кнопки "COPY"
    Tab:CreateImageButton({
        Image = "rbxassetid://87011988082140", -- Вставь ID твоей картинки из студии
        Height = 150, -- Можно регулировать высоту
        Callback = function()
            print("Copy structure executed!")
            -- Здесь код для парсинга и копирования v7 файлов
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
