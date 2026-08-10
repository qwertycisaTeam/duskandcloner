local Module = {}

function Module:Init(Library, Window, Tab)
    Tab:CreateSection({ Name = "UI Settings" })

    -- Слайдер масштаба интерфейса
    Tab:CreateSlider({
        Name = "Menu Scale (%)",
        Min = 50,
        Max = 150,
        Default = 100,
        Flag = "UI_Scale",
        Callback = function(value)
            -- Меняем масштаб через переменную, которую мы экспортировали в Шаге 3
            if Window.MainUIScale then
                Window.MainUIScale.Scale = value / 100
            end
        end
    })
end

return Module
