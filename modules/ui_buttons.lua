-- modules/ui_buttons.lua
repeat task.wait() until getgenv().DuskShine_Core and getgenv().BuilderModuleContainer and getgenv().ReplicatorLogic and getgenv().MainReplicatorTab

local Library = getgenv().DuskShine_Core
local TargetContainer = getgenv().BuilderModuleContainer
local Logic = getgenv().ReplicatorLogic
local MainTab = getgenv().MainReplicatorTab

-- Кастомные уведомления
local function notify(title, text, isError)
    Library:Notify(title, text, 4, isError and "rbxassetid://11877677509" or "rbxassetid://283952329")
end

-- ==========================================
-- КНОПКИ-КАРТИНКИ В SUBPAGE (COPY/PASTE)
-- ==========================================
Library.Utils.Make("UIListLayout", { Parent = TargetContainer, Padding = UDim.new(0, 15), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder })

local function CreateImageModuleButton(imageId, layoutOrder, callback)
    local ImgBtn = Library.Utils.Make("ImageButton", { Size = UDim2.new(1, -20, 0, 140), Image = imageId, ScaleType = Enum.ScaleType.Crop, LayoutOrder = layoutOrder, AutoButtonColor = false, Parent = TargetContainer }, { BackgroundColor3 = "Section" })
    Library.Utils.Make("UICorner", { CornerRadius = UDim.new(0, 16), Parent = ImgBtn })
    local Stroke = Library.Utils.Make("UIStroke", { Thickness = 2, Transparency = 0.5, Parent = ImgBtn }, { Color = "Stroke" })
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

local COPY_IMG = "rbxassetid://ТВОЙ_ID_COPY"
local PASTE_IMG = "rbxassetid://ТВОЙ_ID_PASTE"

CreateImageModuleButton(COPY_IMG, 1, function()
    notify("Replicator", "Scanning interior...")
    local success, result = Logic.CopyHouse()
    if success then notify("Success", "Saved " .. result .. " items to memory!") else notify("Error", result, true) end
end)

CreateImageModuleButton(PASTE_IMG, 2, function()
    notify("Replicator", "Building structure...")
    local success, placed, fails = Logic.PasteHouse()
    if success then notify("Success", string.format("Placed: %d | Fails: %d", placed, fails)) else notify("Error", placed, true) end
end)

-- ==========================================
-- ТОГЛ НА ГЛАВНОЙ ВКЛАДКЕ (AUTO-ENTER)
-- ==========================================
MainTab:CreateSection({ Name = "Utilities" })

MainTab:CreateToggle({
    Name = "Auto-Enter Closed Doors",
    Default = false,
    Callback = function(state)
        Logic.ToggleAutoEnter(state)
        if state then notify("Auto-Enter", "Enabled. Scanning for doors...") else notify("Auto-Enter", "Disabled.") end
    end
})
