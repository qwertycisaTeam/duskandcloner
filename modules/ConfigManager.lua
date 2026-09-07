local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local BackgroundLoader = {
    ConfigFolder = "DuskAndShineConfigs",
    AutoLoadFile = "autoload"
}

-- Функция применения самих настроек к игре
function BackgroundLoader:ApplySettings(data)
    -- 1. FPS Limit
    if data.FPSLimit then
        getgenv().FPSLimit = data.FPSLimit
        if not getgenv().EcoModeEnabled and setfpscap then
            pcall(function() setfpscap(data.FPSLimit) end)
        end
    end

    -- 2. Performance Mode (Убийца графики)
    if data.PerformanceModeEnabled ~= nil then
        getgenv().PerformanceModeEnabled = data.PerformanceModeEnabled
        local Terrain = workspace:FindFirstChildOfClass("Terrain")

        if data.PerformanceModeEnabled then
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.ShadowSoftness = 0
            Lighting.Brightness = 0
            if Terrain then
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterReflectance = 0
                Terrain.WaterTransparency = 0
            end
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        else
            Lighting.GlobalShadows = true
            Lighting.Brightness = 1
            pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
        end
    end

    -- 3. Глобальные переменные (для будущей логики скрипта или интерфейса)
    if data.AnonymousMode ~= nil then 
        getgenv().AnonymousMode = data.AnonymousMode 
    end
    
    if data.AutoUpdateKicker ~= nil then 
        getgenv().AutoUpdateKicker = data.AutoUpdateKicker 
    end

    if data.ToggleUIKey ~= nil then 
        -- Восстанавливаем Enum из таблицы, если он был так сохранен
        if type(data.ToggleUIKey) == "table" and data.ToggleUIKey.isKeybind then
            getgenv().ToggleUIKey = Enum.KeyCode[data.ToggleUIKey.Key]
        else
            getgenv().ToggleUIKey = data.ToggleUIKey
        end
    end

    -- 4. Переменные для UI (если UI будет загружен позже, он возьмет эти значения)
    if data.UIScaleSize then getgenv().UIScaleSize = data.UIScaleSize end
    if data.MenuParticlesEnabled ~= nil then getgenv().MenuParticlesEnabled = data.MenuParticlesEnabled end
    if data.ParticleType then getgenv().ParticleType = data.ParticleType end
    if data.MenuBlurEnabled ~= nil then getgenv().MenuBlurEnabled = data.MenuBlurEnabled end
    if data.CloserType then getgenv().CloserType = data.CloserType end
end

-- Основная функция инициализации, которую мы вызываем при запуске
function BackgroundLoader:Init()
    -- Авто-калибровка для первого запуска, если нет конфига
    if not getgenv().UIScaleSize then
        local camera = workspace.CurrentCamera
        local screenWidth = camera and camera.ViewportSize.X or 1920
        getgenv().UIScaleSize = math.clamp(math.floor((screenWidth / 1920) * 100), 45, 100)
    end

    if not isfolder or not readfile then return end

    local path = self.ConfigFolder .. "/" .. self.AutoLoadFile .. ".json"
    
    -- Если файл есть, читаем и применяем
    if isfile(path) then
        local success, json = pcall(function() return readfile(path) end)
        if success then
            local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(json) end)
            if decodeSuccess and type(data) == "table" then
                self:ApplySettings(data)
            end
        end
    end
end

return BackgroundLoader
