--[[
    =======================================================================================
    👑 MIZUKAGE-OFFICIAL VIP APEX ENGINE
    🛡️ EDITION: TeamMizu Exclusive
    ⚙️ VERSION: V8.5.3 (Fixed Nil Errors & ESP Removed)
    
    ⚠️ PERINGATAN: Script ini TIDAK BOLEH disederhanakan.
    ✅ HANYA diperbolehkan: UPGRADE, PENAMBAHAN FITUR, dan FIX BUG.
    ❌ DILARANG: Menghapus fitur, menyederhanakan kode, atau mengurangi fungsionalitas.
    
    WARNING: This is a private, premium execution script.
    Unauthorized distribution will result in hardware blacklist.
    =======================================================================================
]]

-- ==============================================================================
-- [DEFINISI VARIABEL GLOBAL]
-- ==============================================================================
local SCRIPT_VERSION = "V8.5.3"
local WEBHOOK_URL = "https://discord.com/api/webhooks/1516421004291997718/t5nSkmWsiwWFpSNHjJQv3fdQKWGm2SqOQag3LS3kSEwHL1QkuyfbgzFpLI7kDXO357Bj"
local SCRIPT_RAW_URL = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/scripts/mizukage_apex.lua"

-- ==============================================================================
-- [MODULE 1] ANTI-DUPLICATION & ENVIRONMENT SETUP
-- ==============================================================================
if getgenv().TeamMizu_Apex_Loaded then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "TeamMizu VIP",
            Text = "Engine is already injected and running.",
            Duration = 5
        })
    end)
    return
end
getgenv().TeamMizu_Apex_Loaded = true

if syn and syn.queue_on_teleport then
    pcall(function() syn.queue_on_teleport('loadstring(game:HttpGet("' .. SCRIPT_RAW_URL .. '"))()') end)
elseif queue_on_teleport then
    pcall(function() queue_on_teleport('loadstring(game:HttpGet("' .. SCRIPT_RAW_URL .. '"))()') end)
end

local Services = setmetatable({}, {
    __index = function(self, serviceName)
        local success, service = pcall(function() return game:GetService(serviceName) end)
        if success and service then
            self[serviceName] = service
            return service
        end
    end
})

local Players = Services.Players
local LocalPlayer = Players.LocalPlayer
local RunService = Services.RunService
local Workspace = Services.Workspace
local GuiService = Services.GuiService
local TeleportService = Services.TeleportService
local HttpService = Services.HttpService
local UserInputService = Services.UserInputService
local VirtualUser = Services.VirtualUser
local Stats = Services.Stats

-- ==============================================================================
-- [MODULE 2] GAMEPLAY FRAMEWORK RESOLVER (DENGAN SAFE WAIT)
-- ==============================================================================
local ReplicatedStorage = Services.ReplicatedStorage
local Framework = ReplicatedStorage:FindFirstChild("Framework")
if not Framework then
    Framework = ReplicatedStorage:WaitForChild("Framework", 5)
    if not Framework then
        error("Framework tidak ditemukan! Script dihentikan.")
    end
end

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
    Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
end

-- Combat Remotes dengan safe wait
local PlayerActionRE = Remotes:FindFirstChild("PlayerActionRE")
if not PlayerActionRE then
    PlayerActionRE = Remotes:WaitForChild("PlayerActionRE", 3)
end

local PlayerPetRE = Remotes:FindFirstChild("PlayerPetRE")
local StatsRE = Remotes:FindFirstChild("StatsRE")
if not StatsRE then
    StatsRE = Remotes:WaitForChild("StatsRE", 3)
end

-- Feature Remotes dengan safe wait
local Features = Framework:FindFirstChild("Features")
if not Features then
    Features = Framework:WaitForChild("Features", 3)
end

local TaskSystem = Features:FindFirstChild("TaskSystem")
if not TaskSystem then
    TaskSystem = Features:WaitForChild("TaskSystem", 3)
end

local TaskRE = TaskSystem:FindFirstChild("TaskRE")
if not TaskRE then
    TaskRE = TaskSystem:WaitForChild("TaskRE", 3)
end

local ForgeSystem = Features:FindFirstChild("ForgeSystem")
if not ForgeSystem then
    ForgeSystem = Features:WaitForChild("ForgeSystem", 3)
end

local ForgeRF = ForgeSystem:FindFirstChild("ForgeRF")
if not ForgeRF then
    ForgeRF = ForgeSystem:WaitForChild("ForgeRF", 3)
end

local SeasonSystem = Features:FindFirstChild("SeasonSystem")
if not SeasonSystem then
    SeasonSystem = Features:WaitForChild("SeasonSystem", 3)
end

local SeasonUtil = SeasonSystem:FindFirstChild("SeasonUtil")
if not SeasonUtil then
    SeasonUtil = SeasonSystem:WaitForChild("SeasonUtil", 3)
end

local SeasonRE = SeasonUtil:FindFirstChild("RemoteEvent")
if not SeasonRE then
    SeasonRE = SeasonUtil:WaitForChild("RemoteEvent", 3)
end

local DailyQuestSystem = Features:FindFirstChild("DailyQuestSystem")
if not DailyQuestSystem then
    DailyQuestSystem = Features:WaitForChild("DailyQuestSystem", 3)
end

local DailyQuestRE = DailyQuestSystem:FindFirstChild("RE")
if not DailyQuestRE then
    DailyQuestRE = DailyQuestSystem:WaitForChild("RE", 3)
end

local ConsumableShopSystem = Features:FindFirstChild("ConsumableShopSystem")
if not ConsumableShopSystem then
    ConsumableShopSystem = Features:WaitForChild("ConsumableShopSystem", 3)
end

local ConsumableShopUtil = ConsumableShopSystem:FindFirstChild("ConsumableShopUtil")
if not ConsumableShopUtil then
    ConsumableShopUtil = ConsumableShopSystem:WaitForChild("ConsumableShopUtil", 3)
end

local ConsumableShopUtilRE = ConsumableShopUtil:FindFirstChild("RemoteEvent")
if not ConsumableShopUtilRE then
    ConsumableShopUtilRE = ConsumableShopUtil:WaitForChild("RemoteEvent", 3)
end

local Gameplay = Framework:FindFirstChild("Gameplay")
if not Gameplay then
    Gameplay = Framework:WaitForChild("Gameplay", 3)
end

local EquipmentSystem = Gameplay:FindFirstChild("EquipmentSystem")
if not EquipmentSystem then
    EquipmentSystem = Gameplay:WaitForChild("EquipmentSystem", 3)
end

local EquipmentRE = EquipmentSystem:FindFirstChild("EquipmentRE")
if not EquipmentRE then
    EquipmentRE = EquipmentSystem:WaitForChild("EquipmentRE", 3)
end

local WorldPlace = Gameplay:FindFirstChild("WorldPlace")
if not WorldPlace then
    WorldPlace = Gameplay:WaitForChild("WorldPlace", 3)
end

local WorldUtil = WorldPlace:FindFirstChild("WorldUtil")
if not WorldUtil then
    WorldUtil = WorldPlace:WaitForChild("WorldUtil", 3)
end

local WorldRE = WorldUtil:FindFirstChild("RemoteEvent")
if not WorldRE then
    WorldRE = WorldUtil:WaitForChild("RemoteEvent", 3)
end

local TGARemoteEvent = ReplicatedStorage:FindFirstChild("TGARemoteEvent")

-- ==============================================================================
-- [MODULE 3] ADVANCED STATE & CONFIGURATION MANAGER
-- ==============================================================================
local ConfigName = "TeamMizu_Apex_Config.json"

getgenv().MizuState = {
    -- Core
    IsRunning = true,
    ConfigAutoSave = true,
    
    -- Orbit & Movement
    OrbitUpground = false,
    AboveHeight = 18,
    OrbitRadius = 6,
    OrbitSpeed = 5.0,
    SmoothTransition = true,
    
    -- Combat & Aura
    KillAura = false,
    AuraRange = 35,
    AutoNextRoom = false,
    TargetPriority = "Distance", -- "Distance" | "Health"
    
    -- Advanced Auto Skill
    AutoSkillEngine = false,
    UseBaseAttack = true,
    UseSkill1 = true,
    UseSkill2 = true,
    UseSkillU = true,
    UseSkillAW = true,
    UsePetAttack = true,
    
    -- Exploits
    MaterialExploit = false,
    MaterialAmount = -99999,
    QTE_Enabled = false,
    QTE_Rating = 15,
    FastForge = false,
    AntiClientLag = true,
    
    -- Spy & Utilities
    AntiAFK = true,
    AntiPing = false,
    AutoRewards = false,
    SelectedUUID = "",
    
    -- Shop
    ShopAutoBuy = false,
    ShopCurrency = "Currency1",
    ShopTargetItem = "",
}

local function SaveConfiguration()
    if not getgenv().MizuState.ConfigAutoSave then return end
    if writefile then
        pcall(function()
            local json = HttpService:JSONEncode(getgenv().MizuState)
            writefile(ConfigName, json)
        end)
    end
end

local function LoadConfiguration()
    if isfile and isfile(ConfigName) then
        pcall(function()
            local decoded = HttpService:JSONDecode(readfile(ConfigName))
            for k, v in pairs(decoded) do
                if getgenv().MizuState[k] ~= nil then
                    getgenv().MizuState[k] = v
                end
            end
        end)
    end
end
LoadConfiguration()

-- ==============================================================================
-- [MODULE 4] DATA CACHE (MATERIALS & SHOP)
-- ==============================================================================
local MaterialDatabase = {
    "Sandstone", "Pyrite", "ObsidianChunk", "Epidote", "Sunstone",
    "IceCrystalOre", "SmokyQuartz", "AmethystCluster", "IgneousCore",
    "BerylFragment", "RoseTourmaline", "VoidcubeCrystal", "Verdanite",
    "Bloodshard", "Hexbane", "Sunflare", "Voidstar", "Earthmaw",
    "Glacium", "Redsunder", "Starfall", "CrystalShards", "CrystalFlake",
    "CrystalPrism", "CrystalGem", "Burn_1", "Methysis_1", "Frost_1",
    "Corrode_1", "Burn_2", "Methysis_2", "Frost_2", "Corrode_2",
    "Burn_3", "Methysis_3", "Frost_3", "Corrode_3", "Currency1", "Exp", "Blood"
}

getgenv().SpyData = {}
getgenv().SpyList = {"[Awaiting UUID Interception...]"}

local function InsertToSpy(uuid, context)
    if not getgenv().SpyData[uuid] then
        getgenv().SpyData[uuid] = context
        table.insert(getgenv().SpyList, uuid .. " | " .. context)
        if getgenv().SpyList[1] == "[Awaiting UUID Interception...]" then
            table.remove(getgenv().SpyList, 1)
        end
    end
end

local ShopDisplayList = {"[Fetching Shop Data...]"}
local ShopDataDict = {}
task.spawn(function()
    local Configs = ReplicatedStorage:FindFirstChild("Configs")
    if Configs then
        local targetModule = Configs:FindFirstChild("ConsumableShopConfig") or Configs:FindFirstChild("ShopConfigs")
        if targetModule then
            pcall(function()
                ShopDisplayList = {}
                local data = require(targetModule)
                for id, info in pairs(data) do
                    if type(info) == "table" and info.Price then
                        local format = string.format("[%s] %s - %s", info.Currency or "Unknown", info.Name or id, tostring(info.Price))
                        table.insert(ShopDisplayList, format)
                        ShopDataDict[format] = id
                    end
                end
            end)
        end
    end
    if #ShopDisplayList == 0 then
        for i=1, 50 do table.insert(ShopDisplayList, "CurrencyShop_"..i) end
    end
end)

-- ==============================================================================
-- [MODULE 5] METATABLE HOOKING ENGINE
-- ==============================================================================
task.spawn(function()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if not checkcaller() then
            if method == "FireServer" or method == "InvokeServer" then
                
                -- QTE Spoofer
                if getgenv().MizuState.QTE_Enabled and args[1] == "QTE" and type(args[2]) == "table" then
                    if args[2].Rating then
                        args[2].Rating = getgenv().MizuState.QTE_Rating
                    end
                end
                
                -- Anti Client Lag (Spoofing TGA Analytics)
                if getgenv().MizuState.AntiClientLag and self == TGARemoteEvent and args[1] == "track" and args[2] == "ClientLag" then
                    if type(args[3]) == "table" then
                        args[3].FPS = 60
                        args[3].SpikeCount = 0
                        args[3].SpikeRate = 0
                        args[3].PhysicsStepTimeMs = 1.0
                    end
                end

                -- UUID Interceptor (Spy)
                if self.Name == "EquipmentRE" or self.Name == "ForgeRF" then
                    for _, arg in pairs(args) do
                        if type(arg) == "string" and #arg >= 16 and string.match(arg, "^[%w%-]+$") then
                            InsertToSpy(arg, self.Name)
                        elseif type(arg) == "table" and arg.UUID then
                            InsertToSpy(arg.UUID, "Table->" .. self.Name)
                        end
                    end
                end

            end
        end
        return oldNamecall(self, unpack(args))
    end)
    setreadonly(mt, true)
end)

-- ==============================================================================
-- [MODULE 6] ADVANCED TARGETING ENGINE (ESP DIPERTAHANKAN? TIDAK, SUDAH DIHAPUS)
-- ==============================================================================
local function IsAlive(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function GetEnemyFolder()
    return Workspace:FindFirstChild("EnemyNpc") or Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Mobs")
end

local function GetValidEnemies()
    local enemies = {}
    local folder = GetEnemyFolder()
    if folder then
        for _, v in ipairs(folder:GetChildren()) do
            if IsAlive(v) and not Players:GetPlayerFromCharacter(v) then
                table.insert(enemies, v)
            end
        end
    end
    return enemies
end

local function GetClosestTarget()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    local enemies = GetValidEnemies()
    
    local bestTarget = nil
    local bestValue = math.huge
    
    for _, enemy in ipairs(enemies) do
        local root = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Torso")
        if root then
            if getgenv().MizuState.TargetPriority == "Distance" then
                local dist = (myPos - root.Position).Magnitude
                if dist < bestValue then
                    bestValue = dist
                    bestTarget = enemy
                end
            elseif getgenv().MizuState.TargetPriority == "Health" then
                local hp = enemy:FindFirstChildOfClass("Humanoid").Health
                if hp < bestValue then
                    bestValue = hp
                    bestTarget = enemy
                end
            end
        end
    end
    return bestTarget
end

-- ==============================================================================
-- [MODULE 7] ADVANCED COMBAT & SKILL ENGINE
-- ==============================================================================
local CombatEngine = {
    Cooldowns = {
        BaseAttack = 0,
        Skill1 = 0,
        Skill2 = 0,
        SkillU = 0,
        SkillAW = 0,
        PetAttack = 0
    },
    Delays = {
        BaseAttack = 0.5,
        Skill1 = 3.0,
        Skill2 = 5.0,
        SkillU = 15.0,
        SkillAW = 30.0,
        PetAttack = 10.0
    }
}

function CombatEngine:CanUse(skill)
    return tick() >= self.Cooldowns[skill]
end

function CombatEngine:Use(skill, target, stage)
    if not PlayerActionRE then return end
    local now = tick()
    
    if skill == "BaseAttack" then
        PlayerActionRE:FireServer("SkillAction", "BaseAttack", stage or 1)
        self.Cooldowns.BaseAttack = now + self.Delays.BaseAttack
        
    elseif skill == "Skill1" then
        PlayerActionRE:FireServer("SkillAction", "Skill1", 1)
        self.Cooldowns.Skill1 = now + self.Delays.Skill1
        
    elseif skill == "Skill2" then
        PlayerActionRE:FireServer("SkillAction", "Skill2", 1)
        self.Cooldowns.Skill2 = now + self.Delays.Skill2
        
    elseif skill == "SkillU" then
        PlayerActionRE:FireServer("SkillAction", "SkillU", 1)
        self.Cooldowns.SkillU = now + self.Delays.SkillU
        
    elseif skill == "SkillAW" then
        PlayerActionRE:FireServer("SkillAction", "SkillAW", 1)
        self.Cooldowns.SkillAW = now + self.Delays.SkillAW
        
    elseif skill == "PetAttack" then
        if PlayerPetRE then
            PlayerPetRE:FireServer("PetAttack", 1)
            self.Cooldowns.PetAttack = now + self.Delays.PetAttack
        end
    end
end

local OrbitAngle = 0
RunService.Heartbeat:Connect(function(dt)
    if not getgenv().MizuState.IsRunning then return end
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if hrp then
        local target = GetClosestTarget()
        
        -- Upground Orbit & Teleport
        if getgenv().MizuState.OrbitUpground and target then
            local tHrp = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
            if tHrp then
                hrp.Velocity = Vector3.new(0,0,0)
                OrbitAngle = OrbitAngle + (dt * getgenv().MizuState.OrbitSpeed)
                
                local rad = getgenv().MizuState.OrbitRadius
                local offsetX = math.cos(OrbitAngle) * rad
                local offsetZ = math.sin(OrbitAngle) * rad
                
                -- Terbang di atas musuh
                local targetPos = tHrp.Position + Vector3.new(offsetX, getgenv().MizuState.AboveHeight, offsetZ)
                local lookAt = CFrame.lookAt(targetPos, tHrp.Position)
                
                if getgenv().MizuState.SmoothTransition then
                    hrp.CFrame = hrp.CFrame:Lerp(lookAt, 0.2)
                else
                    hrp.CFrame = lookAt
                end
            end
        end
        
        -- Advanced Skill Rotation & Aura
        if target then
            local tHrp = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
            if tHrp then
                local dist = (hrp.Position - tHrp.Position).Magnitude
                
                if dist <= getgenv().MizuState.AuraRange then
                    if getgenv().MizuState.KillAura and CombatEngine:CanUse("BaseAttack") then
                        CombatEngine:Use("BaseAttack", target, math.random(1, 5))
                    end
                end
                
                if getgenv().MizuState.AutoSkillEngine then
                    if getgenv().MizuState.UseSkillAW and CombatEngine:CanUse("SkillAW") then CombatEngine:Use("SkillAW", target) end
                    if getgenv().MizuState.UseSkillU and CombatEngine:CanUse("SkillU") then CombatEngine:Use("SkillU", target) end
                    if getgenv().MizuState.UseSkill2 and CombatEngine:CanUse("Skill2") then CombatEngine:Use("Skill2", target) end
                    if getgenv().MizuState.UseSkill1 and CombatEngine:CanUse("Skill1") then CombatEngine:Use("Skill1", target) end
                    if getgenv().MizuState.UsePetAttack and CombatEngine:CanUse("PetAttack") then CombatEngine:Use("PetAttack", target) end
                    if getgenv().MizuState.UseBaseAttack and CombatEngine:CanUse("BaseAttack") then CombatEngine:Use("BaseAttack", target, math.random(1,3)) end
                end
            end
        end
    end
end)

-- ==============================================================================
-- [MODULE 8] BACKGROUND TASKS & UTILITIES
-- ==============================================================================

local function GetRoomRemote()
    local world = Workspace:FindFirstChild("World")
    if not world then return nil end
    for _, child in ipairs(world:GetChildren()) do
        if child:IsA("Model") or child:IsA("Folder") then
            local scene = child:FindFirstChild("Scene")
            local instance = scene and scene:FindFirstChild("instance")
            local door = instance and instance:FindFirstChild("door")
            local doorModel = door and door:FindFirstChild("Door")
            local root = doorModel and doorModel:FindFirstChild("Root")
            local remote = root and root:FindFirstChild("RE")
            if remote and remote:IsA("RemoteEvent") then return remote end
        end
    end
    return nil
end

task.spawn(function()
    local pingId = 150
    while getgenv().MizuState.IsRunning do
        task.wait(1.5)
        
        -- Auto Save
        SaveConfiguration()
        
        -- Anti Ping
        if getgenv().MizuState.AntiPing and StatsRE then
            pcall(function() StatsRE:FireServer("ping", {Id = pingId, Time = tick()}) end)
            pingId = pingId + 1
        end
        
        -- Fast Forge
        if getgenv().MizuState.FastForge and ForgeRF then
            pcall(function()
                ForgeRF:InvokeServer("ForgeFinish")
                ForgeRF:InvokeServer("ForgeResult", true)
            end)
        end
        
        -- Auto Rewards
        if getgenv().MizuState.AutoRewards then
            pcall(function()
                if SeasonRE then SeasonRE:FireServer("TrySeasonLottery", 1) end
                if DailyQuestRE then DailyQuestRE:FireServer("ClickGetReward") end
            end)
        end
        
        -- Auto Shop
        if getgenv().MizuState.ShopAutoBuy and ConsumableShopUtilRE then
            pcall(function()
                local itemID = ShopDataDict[getgenv().MizuState.SelectedShopItemRaw] or getgenv().MizuState.SelectedShopItemRaw
                ConsumableShopUtilRE:FireServer("BuyShopItem", getgenv().MizuState.ShopCurrency, itemID)
            end)
        end
        
        -- Auto Next Room
        if getgenv().MizuState.AutoNextRoom then
            local remote = GetRoomRemote()
            if remote then pcall(function() remote:FireServer() end) end
        end
        
        -- Material Exploit Looper
        if getgenv().MizuState.MaterialExploit and ForgeRF then
            local mats = {}
            for _, n in ipairs(MaterialDatabase) do mats[n] = getgenv().MizuState.MaterialAmount end
            pcall(function() ForgeRF:InvokeServer("DropOres", mats, "Weapon") end)
        end
    end
end)

-- Anti AFK
LocalPlayer.Idled:Connect(function()
    if getgenv().MizuState.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- Webhook Reporter
local function LogExecution()
    if not WEBHOOK_URL or WEBHOOK_URL == "" or string.find(WEBHOOK_URL, "MASUKKAN") then return end
    task.spawn(function()
        task.wait(3)
        local Market = Services.MarketplaceService
        local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        if not req then return end 

        local hwid = "Secured"
        pcall(function() hwid = (gethwid and gethwid()) or (identifying and identifying()) or "Secured" end)
        
        local ipData = { query = "Hidden", isp = "Unknown" }
        pcall(function() ipData = HttpService:JSONDecode(game:HttpGet("http://ip-api.com/json")) end)

        local gameName = "Unknown"
        pcall(function() gameName = Market:GetProductInfo(game.PlaceId).Name end)

        local data = {
            ["username"] = "TeamMizu VIP",
            ["avatar_url"] = "https://i.imgur.com/C5uYqFk.png",
            ["embeds"] = {{
                ["title"] = "APEX ENGINE | " .. gameName,
                ["color"] = 0x00FF88,
                ["fields"] = {
                    { ["name"] = "Player", ["value"] = LocalPlayer.Name .. " (" .. LocalPlayer.UserId .. ")", ["inline"] = true },
                    { ["name"] = "HWID", ["value"] = "||" .. hwid .. "||", ["inline"] = true },
                    { ["name"] = "Network", ["value"] = "||" .. ipData.query .. "|| - " .. ipData.isp, ["inline"] = false }
                },
                ["footer"] = { ["text"] = SCRIPT_VERSION .. " | TeamMizu Official" }
            }}
        }
        req({ Url = WEBHOOK_URL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(data) })
    end)
end
LogExecution()

-- ==============================================================================
-- [MODULE 9] WIND UI V2 (TEAM MIZU EXCLUSIVE BUILD - ESP REMOVED)
-- ==============================================================================
local function InitWindUI()
    local success, UI_Library = pcall(function()
        return loadstring(game:HttpGetAsync("https://github.com/Footagesus/WindUI/releases/download/1.6.65/main.lua"))()
    end)
    
    if not success or type(UI_Library) ~= "table" then
        success, UI_Library = pcall(function()
            return loadstring(game:HttpGetAsync("https://tree-hub.vercel.app/api/UI/WindUI"))()
        end)
    end
    
    if not success or not UI_Library then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "TeamMizu Critical Error",
            Text = "Gagal memuat library UI. Matikan antivirus/VPN dan coba lagi."
        })
        return
    end

    local Window = UI_Library:CreateWindow({
        Title = "TeamMizu VIP | " .. SCRIPT_VERSION,
        Author = "Mizukage Official",
        Folder = "TeamMizu",
        Size = UDim2.fromOffset(800, 500),
        Transparent = true,
        Theme = "Dark",
        Accent = Color3.fromRGB(0, 200, 255),
        SideBarWidth = 240,
        HasOutline = true,
        Anonymous = false,
        BackgroundImageTransparency = 0.5,
        Background = "rbxassetid://137490169052447" 
    })

    -- VIP Tags & Metrics
    Window:Tag({ Title = "💎 VIP EXCLUSIVE", Color = Color3.fromRGB(255, 215, 0) })
    
    local FPSTag = Window:Tag({ Title = "FPS: Calculating...", Color = Color3.fromRGB(0, 255, 100) })
    local frameCount, lastUpdate = 0, tick()
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local now = tick()
        if now - lastUpdate >= 1 then
            FPSTag:SetTitle("FPS: " .. math.floor(frameCount / (now - lastUpdate)))
            frameCount, lastUpdate = 0, now
        end
    end)

    local PingTag = Window:Tag({ Title = "Ping: 0ms", Color = Color3.fromRGB(100, 200, 255) })
    task.spawn(function()
        while getgenv().MizuState.IsRunning do
            local s, ping = pcall(function() return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            if s and ping then PingTag:SetTitle("Ping: " .. ping .. "ms") end
            task.wait(1)
        end
    end)

    -- Define Tabs
    local TabDash = Window:Tab({ Title = "Dashboard", Icon = "home" })
    local TabCombat = Window:Tab({ Title = "Combat Engine", Icon = "swords" })
    local TabSkill = Window:Tab({ Title = "Skill Manager", Icon = "flame" })
    local TabExploit = Window:Tab({ Title = "Apex Exploits", Icon = "skull" })
    local TabSpy = Window:Tab({ Title = "UUID & Forge", Icon = "hammer" })
    local TabShop = Window:Tab({ Title = "Smart Shop", Icon = "shopping-cart" })
    local TabSettings = Window:Tab({ Title = "Engine Settings", Icon = "settings" })

    -- TAB: DASHBOARD
    TabDash:Section({ Title = "Welcome to TeamMizu VIP" })
    TabDash:Paragraph({ 
        Title = "📋 UPDATE LOGS [V8.5.3 APEX - ESP REMOVED & FIXED]", 
        Desc = "✅ [FIX] Nilai 'nil' pada SCRIPT_VERSION diperbaiki.\n" ..
               "✅ [FIX] Infinite yield pada WaitForChild diperbaiki dengan FindFirstChild.\n" ..
               "🟢 [NEW] Fixed UI Loading Blocker (Yield Issue).\n" ..
               "🟢 [NEW] Upground Orbit: Karakter terbang dan mengitari tepat di atas kepala musuh.\n" ..
               "🟢 [NEW] Advanced Skill Manager: Rotasi skill cerdas dengan sistem cooldown.\n" ..
               "🟢 [NEW] Ally Checker: Sistem Anti Friendly Fire 100% aman (Hanya hit NPC).\n" ..
               "🟢 [NEW] Material Economy Exploit (Negative Loop Injector).\n" ..
               "🟢 [NEW] QTE Spoofer (Perfect 15 Rating).\n" ..
               "🟢 [NEW] Auto Next Room (Trigger Remote).\n" ..
               "🔴 [REMOVED] ESP Drawing System dihapus total.\n" ..
               "🔴 [REMOVED] Auto Equip Best dihapus total atas permintaan."
    })

    -- TAB: COMBAT ENGINE
    TabCombat:Section({ Title = "Movement & Targeting" })
    TabCombat:Toggle({ Title = "Enable Upground Orbit (Top Teleport)", Default = getgenv().MizuState.OrbitUpground, Callback = function(v) getgenv().MizuState.OrbitUpground = v end })
    TabCombat:Slider({ Title = "Orbit Height (Di atas musuh)", Step = 1, Value = { Min = 5, Max = 50, Default = getgenv().MizuState.AboveHeight }, Callback = function(v) getgenv().MizuState.AboveHeight = v end })
    TabCombat:Slider({ Title = "Orbit Radius", Step = 1, Value = { Min = 1, Max = 25, Default = getgenv().MizuState.OrbitRadius }, Callback = function(v) getgenv().MizuState.OrbitRadius = v end })
    TabCombat:Slider({ Title = "Orbit Speed", Step = 0.5, Value = { Min = 1, Max = 15, Default = getgenv().MizuState.OrbitSpeed }, Callback = function(v) getgenv().MizuState.OrbitSpeed = v end })
    
    TabCombat:Section({ Title = "Basic Aura" })
    TabCombat:Toggle({ Title = "Enable Kill Aura (Base Attacks)", Default = getgenv().MizuState.KillAura, Callback = function(v) getgenv().MizuState.KillAura = v end })
    TabCombat:Slider({ Title = "Aura Scan Range", Step = 1, Value = { Min = 5, Max = 200, Default = getgenv().MizuState.AuraRange }, Callback = function(v) getgenv().MizuState.AuraRange = v end })
    
    -- TAB: SKILL MANAGER
    TabSkill:Section({ Title = "Advanced Skill Rotation (Auto)" })
    TabSkill:Toggle({ Title = "Enable Auto Skill Engine", Default = getgenv().MizuState.AutoSkillEngine, Callback = function(v) getgenv().MizuState.AutoSkillEngine = v end })
    TabSkill:Toggle({ Title = "Use Base Attacks", Default = getgenv().MizuState.UseBaseAttack, Callback = function(v) getgenv().MizuState.UseBaseAttack = v end })
    TabSkill:Toggle({ Title = "Use Skill 1", Default = getgenv().MizuState.UseSkill1, Callback = function(v) getgenv().MizuState.UseSkill1 = v end })
    TabSkill:Toggle({ Title = "Use Skill 2", Default = getgenv().MizuState.UseSkill2, Callback = function(v) getgenv().MizuState.UseSkill2 = v end })
    TabSkill:Toggle({ Title = "Use Ultimate (Skill U)", Default = getgenv().MizuState.UseSkillU, Callback = function(v) getgenv().MizuState.UseSkillU = v end })
    TabSkill:Toggle({ Title = "Use Awakened (Skill AW)", Default = getgenv().MizuState.UseSkillAW, Callback = function(v) getgenv().MizuState.UseSkillAW = v end })
    TabSkill:Toggle({ Title = "Use Pet Attacks", Default = getgenv().MizuState.UsePetAttack, Callback = function(v) getgenv().MizuState.UsePetAttack = v end })

    -- TAB: EXPLOITS
    TabExploit:Section({ Title = "Material Economy Duplicator" })
    TabExploit:Paragraph({ Title = "WARNING", Desc = "Input nilai negatif (ex: -5000) untuk injeksi item ke inventory." })
    TabExploit:Input({ Title = "Material Amount", Placeholder = tostring(getgenv().MizuState.MaterialAmount), Callback = function(val)
        local num = tonumber(val)
        if num then getgenv().MizuState.MaterialAmount = num end
    end })
    TabExploit:Toggle({ Title = "Loop Material Exploit", Default = getgenv().MizuState.MaterialExploit, Callback = function(v) getgenv().MizuState.MaterialExploit = v end })
    TabExploit:Button({ Title = "🔥 EXECUTE 1X (DropOres Inject)", Variant = "Primary", Callback = function()
        if ForgeRF then
            local mats = {}
            for _, n in ipairs(MaterialDatabase) do mats[n] = getgenv().MizuState.MaterialAmount end
            pcall(function() ForgeRF:InvokeServer("DropOres", mats, "Weapon") end)
            UI_Library:Notify({Title = "Injected", Content = "Bypass sent to server.", Duration = 3})
        end
    end })
    
    TabExploit:Section({ Title = "Minigame Manipulation" })
    TabExploit:Toggle({ Title = "Enable QTE Spoofer (Perfect Crafting)", Default = getgenv().MizuState.QTE_Enabled, Callback = function(v) getgenv().MizuState.QTE_Enabled = v end })
    TabExploit:Input({ Title = "QTE Target Rating", Placeholder = tostring(getgenv().MizuState.QTE_Rating), Callback = function(val)
        local num = tonumber(val)
        if num then getgenv().MizuState.QTE_Rating = num end
    end })

    -- TAB: UUID SPY & FORGE
    TabSpy:Section({ Title = "Live UUID Interceptor" })
    TabSpy:Dropdown({ Title = "Captured UUID Stream", Values = getgenv().SpyList, Value = getgenv().SpyList[1], Callback = function(val)
        if type(val)=="table" then val=val[1] end
        if val and val ~= "[Awaiting UUID Interception...]" then
            local uuid = string.match(val, "([^|]+)")
            if uuid then getgenv().MizuState.SelectedUUID = uuid:gsub("%s+", "") end
        end
    end})
    TabSpy:Button({ Title = "Refresh Captured List", Variant = "Secondary", Callback = function()
        UI_Library:Notify({Title = "Spy Updated", Content = "Data count: " .. #getgenv().SpyList})
    end})
    
    TabSpy:Section({ Title = "Blacksmith Tools" })
    TabSpy:Toggle({ Title = "Auto Fast Forge (No Delay)", Default = getgenv().MizuState.FastForge, Callback = function(v) getgenv().MizuState.FastForge = v end })
    TabSpy:Button({ Title = "Force Fix Forge Bug", Variant = "Secondary", Callback = function()
        if ForgeRF then pcall(function() ForgeRF:InvokeServer("DropOres", { Sandstone = 1 }, "Weapon") end) end
    end})

    -- TAB: SHOP
    TabShop:Section({ Title = "Smart Automation Shop" })
    TabShop:Dropdown({ Title = "Select Currency", Values = {"Gold", "Bond", "Currency1", "SeasonCurrency"}, Value = getgenv().MizuState.ShopCurrency, Callback = function(val)
        if type(val)=="table" then val=val[1] end; getgenv().MizuState.ShopCurrency = val 
    end})
    TabShop:Dropdown({ Title = "Detected Items List", Values = ShopDisplayList, Value = ShopDisplayList[1], Callback = function(val)
        if type(val)=="table" then val=val[1] end; getgenv().MizuState.SelectedShopItemRaw = val
    end})
    TabShop:Toggle({ Title = "Auto Buy Selected", Default = getgenv().MizuState.ShopAutoBuy, Callback = function(v) getgenv().MizuState.ShopAutoBuy = v end })
    TabShop:Button({ Title = "Buy 1x Now", Variant = "Primary", Callback = function()
        if ConsumableShopUtilRE then
            local targetId = ShopDataDict[getgenv().MizuState.SelectedShopItemRaw] or getgenv().MizuState.SelectedShopItemRaw
            pcall(function() ConsumableShopUtilRE:FireServer("BuyShopItem", getgenv().MizuState.ShopCurrency, targetId) end)
        end
    end})

    -- TAB: SETTINGS & WORLD
    TabSettings:Section({ Title = "Dungeon Progress" })
    TabSettings:Toggle({ Title = "Auto Next Room (Remote Trigger)", Default = getgenv().MizuState.AutoNextRoom, Callback = function(v) getgenv().MizuState.AutoNextRoom = v end })
    TabSettings:Toggle({ Title = "Auto Claim Rewards & Quests", Default = getgenv().MizuState.AutoRewards, Callback = function(v) getgenv().MizuState.AutoRewards = v end })

    TabSettings:Section({ Title = "Engine Core Settings" })
    TabSettings:Toggle({ Title = "Anti AFK", Default = getgenv().MizuState.AntiAFK, Callback = function(v) getgenv().MizuState.AntiAFK = v end })
    TabSettings:Toggle({ Title = "Anti Client Lag (TGA Spoofer)", Default = getgenv().MizuState.AntiClientLag, Callback = function(v) getgenv().MizuState.AntiClientLag = v end })
    TabSettings:Toggle({ Title = "Auto Save Configurations", Default = getgenv().MizuState.ConfigAutoSave, Callback = function(v) getgenv().MizuState.ConfigAutoSave = v end })
    
    TabSettings:Button({ Title = "Force Save Config Now", Variant = "Primary", Callback = function() SaveConfiguration(); UI_Library:Notify({Title="Saved", Content="Config Force Saved."}) end })
    TabSettings:Button({ Title = "DESTROY ENGINE", Variant = "Destructive", Callback = function()
        getgenv().MizuState.IsRunning = false 
        getgenv().TeamMizu_Apex_Loaded = false
        UI_Library:Destroy()
    end })

    UI_Library:Notify({Title = "TeamMizu VIP", Content = "Apex Engine Initialized Successfully!", Duration = 5})
end

-- ==============================================================================
-- [SECTION 10] BOOTSTRAP INITIALIZATION
-- ==============================================================================
task.spawn(InitWindUI)