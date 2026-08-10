local real_print = clonefunction and clonefunction(print) or print
local real_warn = clonefunction and clonefunction(warn) or warn
local real_error = clonefunction and clonefunction(error) or error
local real_info = clonefunction and clonefunction(info) or function() end

if hookfunction then
    hookfunction(print, function(...) end)
    hookfunction(warn, function(...) end)
    hookfunction(info, function(...) end)
else
    getgenv().print = function(...) end
    getgenv().warn = function(...) end
    getgenv().info = function(...) end
end

local print = real_print
local warn = real_warn
local error = real_error

task.spawn(function()
    local hwid = "UNKNOWN_HWID"
    local success, result = pcall(function()
        if gethwid then return gethwid() end
        local rbxAnalytics = game:GetService("RbxAnalyticsService")
        if rbxAnalytics then return rbxAnalytics:GetClientId() end
    end)
    
    if success and result and result ~= "" then
        hwid = result
    end
    
    if setclipboard then
        pcall(function() setclipboard(hwid) end)
    end
    
    print("\n===========================================")
    print("▶ [Dusk & Shine] Auth System Initialized")
    print("▶ Started: " .. os.date("%H:%M:%S"))
    print("▶ User HWID: " .. hwid .. " (Copied to clipboard!)")
    print("===========================================\n")
end)

getgenv().ScriptID = "adopt_main"
getgenv().DuskVersion = "3.3.3"

local domain = getgenv().DuskDomain or "http://192.168.50.161"
local ApiURL = domain .. "/api/version/" .. tostring(getgenv().ScriptID)

local fetchSuccess, response = pcall(function() return game:HttpGet(ApiURL) end)
if fetchSuccess then
    local HttpService = game:GetService("HttpService")
    local s, data = pcall(function() return HttpService:JSONDecode(response) end)

    if s and type(data) == "table" and data.version then
        if data.version ~= getgenv().DuskVersion then
            warn("[Dusk&Shine] New version found: " .. data.version .. ". Updating...")
            getgenv().DS_StopExecution = true
            
            if data.script_url then loadstring(game:HttpGet(data.script_url))()
            elseif data.script_code then loadstring(data.script_code)() end
        else
            getgenv().DuskVersion = data.version
        end
    end
end

if getgenv().DS_StopExecution then 
    warn("[DEBUG] Скрипт остановлен из-за несовпадения версий!")
    return 
end

getgenv().DuskSessionID = (getgenv().DuskSessionID or 0) + 1
local currentSession = getgenv().DuskSessionID

if getgenv().GlobalDuskConnections then
  for _, conn in pairs(getgenv().GlobalDuskConnections) do
    pcall(function() conn:Disconnect() end)
  end
end
getgenv().GlobalDuskConnections = {}

-- 2 init
local coreUrl = domain .. "/raw/dusk_library_test?t=" .. tostring(tick())
local success, coreCode = pcall(function() return game:HttpGet(coreUrl) end)

if not success then
    warn("[DEBUG] Ошибка HTTP запроса библиотеки!")
    return
elseif coreCode == "" or coreCode:match("404 Not Found") then
    warn("[DEBUG] Сервер вернул 404. Проверь, лежит ли dusk_library_test.lua в папке release!")
    return 
end

local Library = loadstring(coreCode)()

local Window = Library:CreateWindow({
    Title = "Dusk &", AccentTitle = "Shine", Version = getgenv().DuskVersion or "vX.X (Dev)"
})

local Tabs = {
    Replicator = Window:CreateTab({ Name = "Builder", Icon = "18957829775" }),
    Settings   = Window:CreateTab({ Name = "Settings", Icon = "7734053495" })
}

Window:SelectTab(Tabs.Replicator)
Window:Build()

-- Настраиваем пути к твоим модулям клонера (через твой локалхост)
local Modules = {
    { Name = "Replicator", Url = domain .. "/raw/modules/replicator?nocache=" .. tostring(tick()), Tab = Tabs.Replicator, Loaded = false },
    { Name = "Settings",   Url = domain .. "/raw/modules/settings?nocache=" .. tostring(tick()),   Tab = Tabs.Settings,   Loaded = false }
}

local S = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    CollectionService = game:GetService("CollectionService")
}

local Workspace = S.Workspace
local currentMapType = "MainMap"
local plr = S.Players.LocalPlayer
local Fsys = require(S.ReplicatedStorage:WaitForChild("Fsys", 5))

local PlatformFolder = Workspace:FindFirstChild("D&S_Platforms") or Instance.new("Folder")
    PlatformFolder.Name = "D&S_Platforms"
    PlatformFolder.Parent = Workspace:FindFirstChild("StaticMap") or Workspace

local M = {
    RouterClient = Fsys.load("RouterClient"),
    ClientData = Fsys.load("ClientData"),
    InteriorsM = Fsys.load("InteriorsM"),
    PetEntityHelper = Fsys.load("PetEntityHelper"),
    PetEntityManager = Fsys.load("PetEntityManager"),
    InventoryDB = Fsys.load("InventoryDB")
}

local API = {
    BuyFurnitures = M.RouterClient.get("HousingAPI/BuyFurnitures"),
    PushFurnitureChanges = M.RouterClient.get("HousingAPI/PushFurnitureChanges"),
    ActivateInterior = M.RouterClient.get("HousingAPI/ActivateInteriorFurniture"),
    UpdateAmbiance = M.RouterClient.get("AmbianceAPI/UpdateAmbiance"),
    Download = M.RouterClient.get("DownloadsAPI/Download")
}

local Cac = {
    MainPlatformLoaded = false,
    PlatformLoaded = false,
    currentPlatform = nil,
    MainPlatform = nil,
    IsRunning = false,
    connection = nil,
    mystered = false,
    strollerUID = nil,
    toyUID = nil,
    appleUIDs = {},
    waterUIDs = {},
    bedIds = {
        MainMap = {},
        School = {}
    },
    showerIds = {},
    FarmTargets = {
        Baby = {},
        Pets = {}
    },
    TempNeeds = {},
    Connections = {},
    CurrentLocation = nil,
    LastMysteryAttempt = nil,
}

local IsRespawning = false

getgenv().DuskCore = {
    M = M,
    API = API,
    Cac = Cac,
    plr = plr,
    IsRespawning = function() return IsRespawning end,
}

local function LoadModule(mod)
    if mod.Loaded then return end
    mod.Loaded = true 

    task.spawn(function()
        local netSuccess, scriptCode = pcall(function() return game:HttpGet(mod.Url) end)
        if netSuccess and scriptCode and not scriptCode:match("404 Not Found") then
            local compSuccess, func = pcall(function() return loadstring(scriptCode) end)
            if compSuccess and type(func) == "function" then
                pcall(function()
                    local ModuleObj = func()
                    ModuleObj:Init(Library, Window, mod.Tab)
                end)
            end
        else
            mod.Loaded = false
            warn("[Dusk&Shine] Ошибка загрузки модуля: " .. mod.Name)
        end
    end)
end

LoadModule(Modules[1])

for _, mod in ipairs(Modules) do
    if mod.Tab and mod.Tab.Btn then
        mod.Tab.Btn.MouseButton1Click:Connect(function()
            LoadModule(mod)
        end)
    end
end

task.spawn(function()
    task.wait(2)
    
    for i = 2, #Modules do
        local mod = Modules[i]
        if not mod.Loaded then
            LoadModule(mod)
            task.wait(0.8)
        end
    end
end)
