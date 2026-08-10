-- Ждем, пока ядро, холст и логика клонера появятся в памяти
repeat task.wait() until getgenv().DuskShine_Core and getgenv().BuilderModuleContainer and getgenv().HouseClonerLogic

local Library = getgenv().DuskShine_Core
local TargetContainer = getgenv().BuilderModuleContainer
local Cloner = getgenv().HouseClonerLogic

-- 1. Создаем авто-выравнивание (твой код со скрина)
Library.Utils.Make("UIListLayout", {
    Parent = TargetContainer,
    Padding = UDim.new(0, 15),
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder
})

-- 2. Универсальная функция (твой код со скрина)
local function CreateImageModuleButton(imageId, layoutOrder, callback)
    local ImgBtn = Library.Utils.Make("ImageButton", {
        Size = UDim2.new(1, -20, 0, 140),
        Image = imageId,
        ScaleType = Enum.ScaleType.Crop,
        LayoutOrder = layoutOrder,
        AutoButtonColor = false,
        Parent = TargetContainer
    }, { BackgroundColor3 = "Section" })

    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 16), Parent = ImgBtn })
    
    local Stroke = Library.Utils.Make("UIStroke", { 
        Thickness = 2, Transparency = 0.5, Parent = ImgBtn 
    }, { Color = "Stroke" })

    local btnScale = Instance.new("UIScale", ImgBtn)
    
    Library:Connect(ImgBtn.MouseEnter, function() Library.Utils.TBT(Stroke, 0.2, { Transparency = 0, Thickness = 3 }) end)
    Library:Connect(ImgBtn.MouseLeave, function() Library.Utils.TBT(Stroke, 0.2, { Transparency = 0.5, Thickness = 2 }) end)

    Library:Connect(ImgBtn.MouseButton1Click, function()
        local t1 = Library.Utils.TBT(btnScale, 0.1, { Scale = 0.95 }, Enum.EasingStyle.Sine)
        t1.Completed:Connect(function() Library.Utils.TBT(btnScale, 0.2, { Scale = 1 }, Enum.EasingStyle.Bounce) end)
        pcall(callback)
    end)

    return ImgBtn
end

-- 3. СОЗДАЕМ КНОПКИ И ЦЕПЛЯЕМ ЛОГИКУ
local COPY_IMG = "rbxassetid://СЮДА_ID_COPY"
local PASTE_IMG = "rbxassetid://СЮДА_ID_PASTE"

CreateImageModuleButton(COPY_IMG, 1, function()
    -- Используем уведомления из библиотеки
    Library:Notify("Replicator", "Scanning layout data...", 2)
    
    local success = Cloner.CopyStructure()
    
    if success then
        Library:Notify("Success", "House layout saved to memory!", 3)
    end
end)

CreateImageModuleButton(PASTE_IMG, 2, function()
    Library:Notify("Replicator", "Building structure...", 2)
    
    local success = Cloner.PasteStructure()
    
    if success then
        Library:Notify("Success", "Replication complete!", 3)
    end
end)