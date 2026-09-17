--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                 MIZUKAGE OFFICIAL 👑                         ║
    ║      MOUNT ATLAS: CRIMSON ECLIPSE — VVIP EXPLOIT SUITE       ║
    ║             Rayfield Gen2 Native Architecture                ║
    ║                    v9.0 — GOD MODE RELEASE                   ║
    ╚══════════════════════════════════════════════════════════════╝
    Target Place ID : 104412011340255
    Framework       : Rayfield Gen2 Native (100% Fixed & Stable)
    Specialty       : 0-Delay Instant Index, Fake Chat, All Ranks
    Warning         : FULL FEATURES - NO SIMPLIFICATION
--]]

-- ═══════════════════════════════════════════════════════════
-- 1. SERVICES & INITIALIZATION
-- ═══════════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local VirtualUser       = game:GetService("VirtualUser")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- ═══════════════════════════════════════════════════════════
-- 2. RAYFIELD GEN2 NATIVE LOADER
-- ═══════════════════════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()
if not Rayfield then return end

-- ═══════════════════════════════════════════════════════════
-- 3. STATE, CACHE & CONFIGURATION
-- ═══════════════════════════════════════════════════════════
local Config = {
    General = {
        AntiAFK       = true,
        AutoLookEvent = true,
    },
    Features = {
        Spoofer = {
            AutoCatch      = false,
            CatchInterval  = 1.5,
            TargetRarity   = "Eternal",
            TargetFishName = "Eternal Lunar Dragon",
        },
        Economy = {
            AutoSellTrash = false,
            AutoSellFish  = false,
            SellInterval  = 4.0,
        },
        Player = {
            AutoDeposit    = false,
            DepositAmount  = 1000,
        },
        Movement = {
            WalkSpeed      = 16,
            JumpPower      = 50,
            InfJump        = false,
            Noclip         = false,
            InfiniteSprint = false,
        }
    }
}

local State = {
    Threads     = {},
    Connections = {},
    GameData    = {
        AllFish  = {},
        Rarities = {},
    },
    Stats = {
        SpoofedFish   = 0,
        IndexUnlocked = 0,
    }
}

-- ═══════════════════════════════════════════════════════════
-- 4. FISHING CONFIG EXTRACTOR v3 (REAL SCHEMA PARSER)
-- ═══════════════════════════════════════════════════════════
local function ExtractFishDatabase()
    table.clear(State.GameData.AllFish)
    table.clear(State.GameData.Rarities)
    local seen = {}

    local function addFish(name, rarity, weight)
        if type(name) ~= "string" or #name < 2 or seen[name] then return end
        seen[name] = true
        table.insert(State.GameData.AllFish, {
            Name   = name,
            Rarity = rarity or "Unknown",
            Weight = tonumber(weight) or (math.random(150, 2999) + math.random()),
        })
    end

    local configCandidates = {}
    local fs = ReplicatedStorage:FindFirstChild("FishingSystem")
    if fs then
        for _, n in ipairs({"FishingConfig","FishingConfigs","Config","FishConfig","FishTable"}) do
            local m = fs:FindFirstChild(n)
            if m then table.insert(configCandidates, m) end
        end
    end
    local cfgRoot = ReplicatedStorage:FindFirstChild("Config")
    if cfgRoot then
        for _, n in ipairs({"FishingConfig","Fish","FishConfig","FishTable"}) do
            local m = cfgRoot:FindFirstChild(n)
            if m then table.insert(configCandidates, m) end
        end
    end

    for _, mod in ipairs(configCandidates) do
        local ok, data = pcall(require, mod)
        if ok and type(data) == "table" then
            local ftable = data.FishTable
            if type(ftable) == "table" then
                local isArray = ftable[1] ~= nil
                if isArray then
                    for _, entry in ipairs(ftable) do
                        if type(entry) == "table" and entry.name then
                            addFish(entry.name, entry.rarity, entry.maxKg or entry.maxWeight)
                        end
                    end
                else
                    for _, entry in pairs(ftable) do
                        if type(entry) == "table" and entry.name then
                            addFish(entry.name, entry.rarity, entry.maxKg)
                        end
                    end
                end
            end
        end
    end

    -- Fallback Database (Diekstrak Manual dari Dump Terbaru)
    if #State.GameData.AllFish == 0 then
        local fallback = {
            {"Boar Fish","Common",50},{"Blackcap Basslet","Common",45},
            {"Pumpkin Carved Shark","Common",60},{"Freshwater Piranha","Common",60},
            {"Goliath Tiger","Common",70},{"Fangtooth","Common",55},
            {"Dead Spooky Koi Fish","Uncommon",80},{"Dead Scary Clownfish","Uncommon",75},
            {"Jellyfish","Uncommon",65},{"Lion Fish","Rare",120},
            {"Luminous Fish","Rare",130},{"Zombie Shark","Rare",150},
            {"Deep Sea Crab","Rare",120},{"Wraithfin Abyssal","Rare",140},
            {"Loving Shark","Legendary",650},{"Monster Shark","Epic",280},
            {"Queen Crab","Epic",220},{"Pink Dolphin","Epic",300},
            {"Plasma Shark","Legendary",400},{"Bone Whale","Legendary",400},
            {"Crocodile","Legendary",400},{"Ghost Shark","Legendary",500},
            {"King Crab","Legendary",500},{"Sacred Guardian Squid","Legendary",400},
            {"Panther Eel","Legendary",400},{"MegaZombie","Legendary",400},
            {"Mammoth Appafish","Legendary",400},{"Frostborn Shark","Legendary",600},
            {"Christmas Whale","Legendary",600},{"Salamander","Legendary",500},
            {"Great Whale","Legendary",400},{"Ancient Relic Crocodile","Unknown",600},
            {"KingJellyFish","Unknown",700},{"Strawberry MegaHunt","Unknown",700},
            {"Kraken","Unknown",900},{"Nessie Monster","Unknown",900},
            {"Zenith","Unknown",900},{"Bluemoon Whale","Unknown",700},
            {"Code Shark","Unknown",700},{"Comet Shark","Unknown",700},
            {"Leviathan","Unknown",950},{"El Maja","Unknown",950},
            {"Abyssal Octopus","Unknown",999},{"Cursed Kraken","Unknown",950},
            {"Ancient Kraken","Unknown",900},{"Aileron","Unknown",900},
            {"Magma Shark","Unknown",900},{"MegaHunt","Unknown",900},
            {"Eternal Lunar Dragon","Eternal",2999},{"Eternal Vulkan","Eternal",2999},
            {"Eternal Voltarion","Eternal",2999},{"Eternal Aquarion","Eternal",2999},
            {"Eternal Valerion","Eternal",2999},{"Asep Knalpot","Eternal",2999},
        }
        for _, f in ipairs(fallback) do addFish(f[1], f[2], f[3]) end
    end

    local order = {"Common","Uncommon","Rare","Epic","Legendary","Unknown","Eternal"}
    for _, r in ipairs(order) do
        for _, f in ipairs(State.GameData.AllFish) do
            if f.Rarity == r then table.insert(State.GameData.Rarities, r); break end
        end
    end

    return #State.GameData.AllFish
end
ExtractFishDatabase()

-- ═══════════════════════════════════════════════════════════
-- 5. REMOTES ROUTER v3 (FULL DUMP RESOLUTION)
-- ═══════════════════════════════════════════════════════════
local Remotes = {
    FishGiver           = nil,
    FishCandidates      = {},
    SellFunc            = nil,
    Reward_GetData      = nil,
    LookEvent           = nil,
    Movement            = nil,
    BankFunc            = nil,
    HeliFunc            = nil,
    ShopFunc            = nil,
    BuyCustomTitle      = nil,
    BuySlime            = nil,
    RequestUpgrade      = nil,
    GetUpgradeData      = nil,
    UpgradeResult       = nil,
    RequestBuyAura      = nil,
    GetAuraStatus       = nil,
    SpeedRequestEquip   = nil,
    GetSpeedStatus      = nil,
    CrimsonGetStatus    = nil,
    CrimsonRequestCraft = nil,
    CrimsonClaimReward  = nil,
    CrimsonOpenUI       = nil,
    RodShopPurchase     = nil,
    SendChat            = nil,
    RankPurchase        = nil,
}

local function ResolveRemotes()
    local fs = ReplicatedStorage:FindFirstChild("FishingSystem")
    if fs then
        Remotes.SendChat = fs:FindFirstChild("SendChatMessage")
        
        local rEv = fs:FindFirstChild("RewardEvents")
        if rEv then Remotes.Reward_GetData = rEv:FindFirstChild("Reward_GetData") end

        local uEv = fs:FindFirstChild("UpgradeRodEvents")
        if uEv then
            Remotes.RequestUpgrade = uEv:FindFirstChild("RequestUpgrade")
            Remotes.GetUpgradeData = uEv:FindFirstChild("GetUpgradeData")
            Remotes.UpgradeResult  = uEv:FindFirstChild("UpgradeResult")
        end

        local rsEv = fs:FindFirstChild("RodShopEvents")
        if rsEv then Remotes.RodShopPurchase = rsEv:FindFirstChild("RequestPurchase") end

        Remotes.FishCandidates = {}
        for _, n in ipairs({"FishGiver","FishCaught","CatchFish","SendFish","AddFish","RequestCatch","CastReplication","FishReplication","FishGiven","RewardFish","GiveFish"}) do
            local r = fs:FindFirstChild(n)
            if r and r:IsA("RemoteEvent") then
                table.insert(Remotes.FishCandidates, r)
                if not Remotes.FishGiver then Remotes.FishGiver = r end
            end
        end
    end

    local auraR = ReplicatedStorage:FindFirstChild("AuraRemotes")
    if auraR then
        Remotes.RequestBuyAura = auraR:FindFirstChild("RequestBuyAura")
        Remotes.GetAuraStatus  = auraR:FindFirstChild("GetAuraStatus")
    end

    local spdR = ReplicatedStorage:FindFirstChild("SpeedRemotes")
    if spdR then
        Remotes.SpeedRequestEquip = spdR:FindFirstChild("RequestEquip")
        Remotes.GetSpeedStatus    = spdR:FindFirstChild("GetSpeedStatus")
    end

    local ceR = ReplicatedStorage:FindFirstChild("CrimsonEclipseEvents")
    if ceR then
        Remotes.CrimsonGetStatus    = ceR:FindFirstChild("GetStatus")
        Remotes.CrimsonRequestCraft = ceR:FindFirstChild("RequestCraft")
        Remotes.CrimsonClaimReward  = ceR:FindFirstChild("RequestClaimReward")
        Remotes.CrimsonOpenUI       = ceR:FindFirstChild("OpenUI")
    end

    local ctR = ReplicatedStorage:FindFirstChild("CustomTitleRemotes")
    if ctR then Remotes.BuyCustomTitle = ctR:FindFirstChild("BuyCustomTitle") end

    local slR = ReplicatedStorage:FindFirstChild("SlimeShopRemotes")
    if slR then Remotes.BuySlime = slR:FindFirstChild("RequestBuyOrEquipSlime") end

    local events = ReplicatedStorage:FindFirstChild("Events")
    if events then
        Remotes.SellFunc  = events:FindFirstChild("SellFunc")
        Remotes.LookEvent = events:FindFirstChild("LookEvent")
        Remotes.BankFunc  = events:FindFirstChild("BankFunc")
    end
    
    Remotes.Movement = ReplicatedStorage:FindFirstChild("Movement")
    Remotes.RankPurchase = ReplicatedStorage:FindFirstChild("RankPurchase")
end
ResolveRemotes()

-- ═══════════════════════════════════════════════════════════
-- 6. CORE UTILITIES
-- ═══════════════════════════════════════════════════════════
local function SafeNotify(title, content, duration)
    pcall(function() Rayfield:Notify({Title = title, Content = content, Duration = duration or 3.5}) end)
end

local function GetRoot()
    local c = LocalPlayer.Character
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso"))
end

local function GetHumanoid()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function SafeFire(remote, ...)
    if remote and remote:IsA("RemoteEvent") then pcall(remote.FireServer, remote, ...) end
end

local function SafeInvoke(remote, ...)
    if remote and remote:IsA("RemoteFunction") then
        local ok, res = pcall(remote.InvokeServer, remote, ...)
        if ok then return res end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════
-- 7. THE VULNERABILITIES ENGINES (EXPLOITS)
-- ═══════════════════════════════════════════════════════════

-- [EXPLOIT 1: FISH SPOOFER]
local function SpoofFishCatch(fName, fRarity, fWeight)
    if #Remotes.FishCandidates == 0 and not Remotes.FishGiver then ResolveRemotes() end

    local root = GetRoot()
    local rootPos = root and root.Position or Vector3.new(0, 0, 0)
    local w = fWeight or math.random(150, 2900) + math.random()

    local payload = {
        hookPosition = rootPos,
        rarity       = fRarity or Config.Features.Spoofer.TargetRarity,
        name         = fName or Config.Features.Spoofer.TargetFishName,
        weight       = w,
    }

    local fired = false
    for _, r in ipairs(Remotes.FishCandidates) do
        if r and r:IsA("RemoteEvent") then
            pcall(function() r:FireServer(payload) end)
            fired = true
        end
    end
    if not fired and Remotes.FishGiver then
        pcall(function() Remotes.FishGiver:FireServer(payload) end)
        fired = true
    end

    if fired then State.Stats.SpoofedFish = State.Stats.SpoofedFish + 1 end
end

-- [EXPLOIT 2: INSTANT INDEX UNLOCKER — NO DELAY]
local function ExecuteInstantIndexUnlock()
    if not Remotes.FishGiver and #Remotes.FishCandidates == 0 then ResolveRemotes() end
    if #State.GameData.AllFish == 0 then ExtractFishDatabase() end
    
    local total = #State.GameData.AllFish
    SafeNotify("Index Unlocker ⚡", "Injecting " .. total .. " ikan — ONE SHOT — NO DELAY!", 4)

    task.spawn(function()
        local root    = GetRoot()
        local rootPos = root and root.Position or Vector3.new(0, 0, 0)

        local payloads = table.create(total)
        for i = 1, total do
            local f = State.GameData.AllFish[i]
            payloads[i] = { hookPosition = rootPos, rarity = f.Rarity, name = f.Name, weight = f.Weight }
        end

        local fired = 0
        for i = 1, total do
            local p = payloads[i]
            local any = false
            for _, r in ipairs(Remotes.FishCandidates) do
                if r and r:IsA("RemoteEvent") then
                    pcall(function() r:FireServer(p) end)
                    any = true
                end
            end
            if not any and Remotes.FishGiver then
                pcall(function() Remotes.FishGiver:FireServer(p) end)
                any = true
            end
            if any then fired = fired + 1 end
            if i % 20 == 0 then task.wait() end -- Anti crash
        end

        State.Stats.IndexUnlocked = fired
        if Remotes.Reward_GetData then SafeInvoke(Remotes.Reward_GetData) end

        SafeNotify("INDEX 100% 🏆", "Berhasil inject " .. fired .. "/" .. total .. " ikan!\nSemua reward Index terbuka.", 7)
    end)
end

-- [EXPLOIT 3: SMART REMOTE LIQUIDATOR]
local function BuildSellPayload(itemType)
    local payload = { Type = itemType }
    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local count = 0

    for _, container in ipairs({char, bp}) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") and item:GetAttribute("TYPE") == itemType then
                    local rawName = item.Name
                    local parts = string.split(rawName, "_")
                    local cleanName = parts[2] or rawName
                    local amount = item:GetAttribute("amount") or 1
                    payload[cleanName] = (payload[cleanName] or 0) + amount
                    count = count + amount
                end
            end
        end
    end
    return payload, count
end

local function ExecuteSmartSell(itemType)
    if not Remotes.SellFunc then ResolveRemotes() end
    local payload, count = BuildSellPayload(itemType)

    if count > 0 and Remotes.SellFunc then
        pcall(function()
            if Remotes.SellFunc:IsA("RemoteFunction") then
                Remotes.SellFunc:InvokeServer("Sell", payload)
                Remotes.SellFunc:InvokeServer("GetSavedLoot")
            else
                Remotes.SellFunc:FireServer("Sell", payload)
            end
        end)
        return count
    end
    return 0
end

-- ═══════════════════════════════════════════════════════════
-- 8. RAYFIELD GEN2 VVIP UI BUILDER (FLAWLESS)
-- ═══════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name = "MIZUKAGE OFFICIAL 👑",
    LoadingTitle = "Crimson Eclipse — God Mode",
    LoadingSubtitle = "VVIP Level Max Edition",
    Theme = "Amethyst",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ConfigurationSaving = { Enabled = true, FolderName = "Mizukage", FileName = "CrimsonMax" },
    SidebarLayout = true, -- Strict Anti-Cutoff Mobile
})

-- ─── TAB 1: DASHBOARD ───
local DashTab = Window:CreateTab({ Name = "Dashboard", Icon = "rbxassetid://10734883584" })

DashTab:CreateSection({ Name = "👑 COMMAND CENTER" })

DashTab:CreateButton({
    Name = "Player: " .. LocalPlayer.Name,
    Callback = function() end
})

DashTab:CreateButton({
    Name = "📈 Statistik Sesi VVIP",
    Callback = function()
        SafeNotify("Stats", "🐟 Ikan Spoof: " .. State.Stats.SpoofedFish .. "\n🏆 Index Unlock: " .. State.Stats.IndexUnlocked, 5)
    end
})

DashTab:CreateDivider()

DashTab:CreateSection({ Name = "⚡ MASTER AUTOMATION HUB" })

DashTab:CreateToggle({
    Name = "🚀 MASTER AUTO FARM (Spoof + Sell)",
    CurrentValue = false,
    Flag = "MasterAuto",
    Callback = function(val)
        Config.Features.Spoofer.AutoCatch     = val
        Config.Features.Economy.AutoSellFish  = val
        Config.Features.Economy.AutoSellTrash = val

        if val then
            State.Threads["MasterSpoof"] = task.spawn(function()
                while Config.Features.Spoofer.AutoCatch do
                    SpoofFishCatch()
                    task.wait(Config.Features.Spoofer.CatchInterval)
                end
            end)
            State.Threads["MasterSell"] = task.spawn(function()
                while Config.Features.Economy.AutoSellFish or Config.Features.Economy.AutoSellTrash do
                    if Config.Features.Economy.AutoSellFish then ExecuteSmartSell("Fish") end
                    if Config.Features.Economy.AutoSellTrash then ExecuteSmartSell("Trash") end
                    task.wait(Config.Features.Economy.SellInterval)
                end
            end)
            SafeNotify("🚀 Control", "Mesin Pencetak Uang & Ikan Aktif Penuh!", 4)
        else
            if State.Threads["MasterSpoof"] then task.cancel(State.Threads["MasterSpoof"]); State.Threads["MasterSpoof"] = nil end
            if State.Threads["MasterSell"]  then task.cancel(State.Threads["MasterSell"]);  State.Threads["MasterSell"]  = nil end
            SafeNotify("🚀 Control", "Semua operasi dihentikan.", 3)
        end
    end
})

DashTab:CreateToggle({
    Name = "🏃 Server Infinite Sprint (No Stamina)",
    CurrentValue = false,
    Flag = "AutoSprint",
    Callback = function(val)
        Config.Features.Movement.InfiniteSprint = val
        if val then
            State.Threads["SprintLoop"] = task.spawn(function()
                while Config.Features.Movement.InfiniteSprint do
                    if Remotes.Movement then
                        if Remotes.Movement:IsA("RemoteFunction") then SafeInvoke(Remotes.Movement, "Run", true)
                        else SafeFire(Remotes.Movement, "Run", true) end
                    end
                    task.wait(0.5)
                end
            end)
        else
            if State.Threads["SprintLoop"] then task.cancel(State.Threads["SprintLoop"]); State.Threads["SprintLoop"] = nil end
            if Remotes.Movement then
                if Remotes.Movement:IsA("RemoteFunction") then SafeInvoke(Remotes.Movement, "Run", false)
                else SafeFire(Remotes.Movement, "Run", false) end
            end
        end
    end
})

DashTab:CreateToggle({
    Name = "🛡️ Anti-AFK & Server Heartbeat",
    CurrentValue = true,
    Flag = "AntiAFK",
    Callback = function(val)
        Config.General.AntiAFK = val
    end
})

-- ─── TAB 2: INDEX MASTERY ───
local IndexTab = Window:CreateTab({ Name = "Index Mastery", Icon = "rbxassetid://10709769841" })

IndexTab:CreateSection({ Name = "🏆 0-DELAY POKEDEX UNLOCKER" })

IndexTab:CreateButton({
    Name = "🔥 EKSEKUSI: UNLOCK 100% INDEX IKAN INSTAN",
    Callback = function() ExecuteInstantIndexUnlock() end
})

IndexTab:CreateButton({
    Name = "🎁 Klaim Ulang Hadiah Index",
    Callback = function()
        if not Remotes.Reward_GetData then ResolveRemotes() end
        if Remotes.Reward_GetData then
            SafeInvoke(Remotes.Reward_GetData)
            SafeNotify("Reward", "Mengklaim hadiah buku Index!", 3)
        end
    end
})

-- ─── TAB 3: FISH SPOOFER ───
local SpoofTab = Window:CreateTab({ Name = "Fish Spoofer", Icon = "rbxassetid://10709770563" })

SpoofTab:CreateSection({ Name = "🐟 MESIN PEMALSU IKAN" })

SpoofTab:CreateToggle({
    Name = "⚡ Aktifkan Auto Spoof Catch (Loop)",
    CurrentValue = false,
    Flag = "SpoofLoop",
    Callback = function(val)
        Config.Features.Spoofer.AutoCatch = val
        if val then
            State.Threads["SpoofStandAlone"] = task.spawn(function()
                while Config.Features.Spoofer.AutoCatch do
                    SpoofFishCatch()
                    task.wait(Config.Features.Spoofer.CatchInterval)
                end
            end)
        else
            if State.Threads["SpoofStandAlone"] then task.cancel(State.Threads["SpoofStandAlone"]); State.Threads["SpoofStandAlone"] = nil end
        end
    end
})

local Rarities = State.GameData.Rarities
if #Rarities == 0 then Rarities = {"Common","Uncommon","Rare","Epic","Legendary","Unknown","Eternal"} end

SpoofTab:CreateDropdown({
    Name = "🎨 Pilih Rarity Ikan",
    Options = Rarities,
    CurrentOption = {Rarities[#Rarities] or "Eternal"},
    MultipleOptions = false,
    Flag = "DropRarity",
    Callback = function(opt)
        Config.Features.Spoofer.TargetRarity = typeof(opt) == "table" and opt[1] or opt
    end
})

local FishNames = {}
for i, f in ipairs(State.GameData.AllFish) do
    table.insert(FishNames, f.Name)
    if i >= 100 then break end
end
if #FishNames == 0 then FishNames = {"Eternal Lunar Dragon","Leviathan","Kraken"} end

SpoofTab:CreateDropdown({
    Name = "🐠 Pilih Jenis Ikan",
    Options = FishNames,
    CurrentOption = {FishNames[1]},
    MultipleOptions = false,
    Flag = "DropFish",
    Callback = function(opt)
        Config.Features.Spoofer.TargetFishName = typeof(opt) == "table" and opt[1] or opt
    end
})

SpoofTab:CreateSlider({
    Name = "⏱️ Interval Tembakan (Detik)",
    Range = {0.1, 10.0},
    Increment = 0.1,
    CurrentValue = 1.5,
    Flag = "SpoofInterval",
    Callback = function(val)
        Config.Features.Spoofer.CatchInterval = val
    end
})

SpoofTab:CreateDivider()
SpoofTab:CreateSection({ Name = "🎯 MANUAL BURST FIRE" })

SpoofTab:CreateButton({
    Name = "🔥 Tembak 10x Ikan Palsu (Burst)",
    Callback = function()
        task.spawn(function()
            for i = 1, 10 do SpoofFishCatch(); task.wait(0.05) end
            SafeNotify("🐟 Burst", "10x tembakan sinyal terkirim!", 3)
        end)
    end
})

SpoofTab:CreateButton({
    Name = "💥 Tembak 50x Ikan Palsu (Rapid)",
    Callback = function()
        task.spawn(function()
            for i = 1, 50 do SpoofFishCatch(); if i % 10 == 0 then task.wait(0.05) end end
            SafeNotify("💥 Rapid", "50x tembakan sinyal terkirim!", 3)
        end)
    end
})

-- ─── TAB 4: ECONOMY ───
local EconTab = Window:CreateTab({ Name = "Economy", Icon = "rbxassetid://10734950309" })

EconTab:CreateSection({ Name = "💵 PENCAIRAN UANG JARAK JAUH" })

EconTab:CreateButton({
    Name = "🐟 Cairkan Seluruh Ikan Sekarang!",
    Callback = function()
        local count = ExecuteSmartSell("Fish")
        SafeNotify("💰 Liquidator", count > 0 and ("Sukses menjual %d ikan!"):format(count) or "Tidak ada ikan.", 3)
    end
})

EconTab:CreateButton({
    Name = "🗑️ Cairkan Seluruh Sampah Sekarang!",
    Callback = function()
        local count = ExecuteSmartSell("Trash")
        SafeNotify("💰 Liquidator", count > 0 and ("Sukses menjual %d sampah!"):format(count) or "Tidak ada sampah.", 3)
    end
})

EconTab:CreateToggle({
    Name = "🔁 Auto Jual Ikan Berkelanjutan",
    CurrentValue = false,
    Flag = "AutoSellF",
    Callback = function(val)
        Config.Features.Economy.AutoSellFish = val
        if val then
            State.Threads["AutoSellFish2"] = task.spawn(function()
                while Config.Features.Economy.AutoSellFish do
                    ExecuteSmartSell("Fish")
                    task.wait(Config.Features.Economy.SellInterval)
                end
            end)
        else
            if State.Threads["AutoSellFish2"] then task.cancel(State.Threads["AutoSellFish2"]); State.Threads["AutoSellFish2"] = nil end
        end
    end
})

EconTab:CreateToggle({
    Name = "🔁 Auto Jual Sampah Berkelanjutan",
    CurrentValue = false,
    Flag = "AutoSellT",
    Callback = function(val)
        Config.Features.Economy.AutoSellTrash = val
        if val then
            State.Threads["AutoSellTrash2"] = task.spawn(function()
                while Config.Features.Economy.AutoSellTrash do
                    ExecuteSmartSell("Trash")
                    task.wait(Config.Features.Economy.SellInterval)
                end
            end)
        else
            if State.Threads["AutoSellTrash2"] then task.cancel(State.Threads["AutoSellTrash2"]); State.Threads["AutoSellTrash2"] = nil end
        end
    end
})

EconTab:CreateSlider({
    Name = "⏱️ Interval Auto Sell (Detik)",
    Range = {2.0, 30.0},
    Increment = 1.0,
    CurrentValue = 5.0,
    Flag = "SellInterval",
    Callback = function(val) Config.Features.Economy.SellInterval = val end
})

-- ─── TAB 5: BLACK MARKET ───
local ShopTab = Window:CreateTab({ Name = "Black Market", Icon = "rbxassetid://10734896206" })

ShopTab:CreateSection({ Name = "🐾 PEMBELIAN PET (SLIMES)" })

local Slimes = {"Blizzard","Leafy","Coco","Spooky","Chaby","Goldie","Apex","Lucki","Angel"}
local selectedSlime = "Blizzard"

ShopTab:CreateDropdown({
    Name = "🐾 Pilih Slime / Pet",
    Options = Slimes,
    CurrentOption = {"Blizzard"},
    MultipleOptions = false,
    Flag = "DropSlime",
    Callback = function(opt) selectedSlime = typeof(opt) == "table" and opt[1] or opt end
})

ShopTab:CreateButton({
    Name = "🛍️ Beli Slime Terpilih (Remote)",
    Callback = function()
        if not Remotes.BuySlime then ResolveRemotes() end
        if Remotes.BuySlime and selectedSlime then
            SafeFire(Remotes.BuySlime, selectedSlime)
            SafeNotify("🐾 Slime Shop", "Sinyal pembelian slime dikirim: " .. selectedSlime, 3)
        end
    end
})

ShopTab:CreateButton({
    Name = "🔥 SPAM Beli SEMUA Slime",
    Callback = function()
        if not Remotes.BuySlime then ResolveRemotes() end
        if not Remotes.BuySlime then return end
        task.spawn(function()
            for _, s in ipairs(Slimes) do SafeFire(Remotes.BuySlime, s); task.wait(0.15) end
            SafeNotify("🔥 Slime", "Spam beli semua slime terkirim!", 4)
        end)
    end
})

ShopTab:CreateDivider()
ShopTab:CreateSection({ Name = "👑 RANK PURCHASE EXPLOIT" })

local Ranks = {"VVIP", "Onyx", "Phoenix", "Aurora", "Emperor"}
for _, rank in ipairs(Ranks) do
    ShopTab:CreateButton({
        Name = "💰 Beli Rank: " .. rank,
        Callback = function()
            if not Remotes.RankPurchase then ResolveRemotes() end
            if Remotes.RankPurchase then
                SafeFire(Remotes.RankPurchase, rank)
                SafeNotify("Rank", "Mencoba claim rank: " .. rank, 3)
            end
        end
    })
end

-- ─── TAB 6: ROD UPGRADES ───
local RodTab = Window:CreateTab({ Name = "Rod Upgrades", Icon = "rbxassetid://10734940376" })

RodTab:CreateSection({ Name = "🔧 ROD UPGRADE EXPLOIT" })

local RodList = {
    "Megalofriend","Fluorescent Rod","GhostRod","LightingPunk Rod","Pirate Octopus",
    "Aqua Prism","Flery","Loving","ZombieRod","Forsaken","Crystalized","Earthly",
    "Manifest","Purple Saber","Katanaa","Umbrella","Developer Rod","Disco",
    "Admin Rod","Holy Trident","Aether Shard","God Rod","Cursed Soul",
    "Abyssal Chroma","Red Matter","Jelly","Amber","Abyssfire","Deep Conjurer",
    "Timeless","Paragos","Oceanic Harpoon","Heartfelt Blade","Red Hammer",
    "Spirit Staff","Prisma","Vanquisher","Reaver Scythe","Soul Scythe",
    "Undead Guitar","Grace Emerald","Electric Guitar","Crimson Eclipse",
    "Azure","Celestial Aegis","AETHERION","Ethereal Rainbow",
}

local selectedRod = "Megalofriend"

RodTab:CreateDropdown({
    Name = "🔧 Pilih Rod",
    Options = RodList,
    CurrentOption = {"Megalofriend"},
    MultipleOptions = false,
    Flag = "DropRod",
    Callback = function(o) selectedRod = typeof(o) == "table" and o[1] or o end
})

RodTab:CreateButton({
    Name = "🔥 SPAM UPGRADE ROD TERPILIH (10x)",
    Callback = function()
        if not Remotes.RequestUpgrade then ResolveRemotes() end
        if not Remotes.RequestUpgrade then return end
        task.spawn(function()
            for i = 1, 10 do SafeFire(Remotes.RequestUpgrade, selectedRod); task.wait(0.15) end
            SafeNotify("⚡ Upgrade", "10x upgrade terkirim: " .. selectedRod, 4)
        end)
    end
})

RodTab:CreateButton({
    Name = "🔥 SPAM SEMUA ROD (Max Level All)",
    Callback = function()
        if not Remotes.RequestUpgrade then ResolveRemotes() end
        if not Remotes.RequestUpgrade then return end
        task.spawn(function()
            for _, rod in ipairs(RodList) do
                for _ = 1, 8 do SafeFire(Remotes.RequestUpgrade, rod); task.wait(0.08) end
            end
            SafeNotify("⚡ ALL ROD", "Spam upgrade ke SEMUA rod selesai!", 5)
        end)
    end
})

-- ─── TAB 7: AURA & SPEED ───
local AuraTab = Window:CreateTab({ Name = "Aura & Speed", Icon = "rbxassetid://10734939856" })

AuraTab:CreateSection({ Name = "🏃 SPEED EXPLOIT" })

AuraTab:CreateButton({
    Name = "🔥 Equip SEMUA Speed Level (0-7)",
    Callback = function()
        if not Remotes.SpeedRequestEquip then ResolveRemotes() end
        if not Remotes.SpeedRequestEquip then return end
        task.spawn(function()
            for lvl = 0, 7 do SafeInvoke(Remotes.SpeedRequestEquip, lvl); task.wait(0.2) end
            SafeNotify("🏃 Speed", "Semua speed level 0-7 dipanggil!", 4)
        end)
    end
})

AuraTab:CreateDivider()
AuraTab:CreateSection({ Name = "🌀 AURA EXPLOIT" })

local AuraList = {"DrStrange","Shatterspace","Serenity","Power","Rhythmistic"}

AuraTab:CreateButton({
    Name = "🔥 BELI SEMUA AURA Sekaligus",
    Callback = function()
        if not Remotes.RequestBuyAura then ResolveRemotes() end
        if not Remotes.RequestBuyAura then return end
        task.spawn(function()
            for _, a in ipairs(AuraList) do SafeInvoke(Remotes.RequestBuyAura, a); task.wait(0.25) end
            SafeNotify("🌀 Aura", "Semua aura di-request!", 4)
        end)
    end
})

-- ─── TAB 8: EVENT & TROLL ───
local TrollTab = Window:CreateTab({ Name = "Event & Troll", Icon = "rbxassetid://10734918483" })

TrollTab:CreateSection({ Name = "📢 FAKE GLOBAL CHAT ANNOUNCER" })

local trollFish = "Eternal Lunar Dragon"
TrollTab:CreateInput({
    Name = "📝 Tulis Nama Ikan Palsu",
    PlaceholderText = "Eternal Lunar Dragon",
    RemoveTextAfterFocusLost = false,
    Callback = function(text) trollFish = text end
})

TrollTab:CreateButton({
    Name = "📢 Broadcast Tangkapan Palsu ke Chat!",
    Callback = function()
        if not Remotes.SendChat then ResolveRemotes() end
        if Remotes.SendChat then
            local weight = math.random(1999, 9999) + math.random()
            SafeFire(Remotes.SendChat, "General", LocalPlayer.Name, trollFish, weight, "Eternal")
            SafeNotify("📢 Chat Spoofed", "Pesan palsu terkirim ke seluruh server!", 3)
        end
    end
})

TrollTab:CreateDivider()
TrollTab:CreateSection({ Name = "🌑 CRIMSON ECLIPSE EVENT" })

TrollTab:CreateButton({
    Name = "🔥 SPAM Claim Reward Crimson (5x)",
    Callback = function()
        if not Remotes.CrimsonClaimReward then ResolveRemotes() end
        if Remotes.CrimsonClaimReward then
            task.spawn(function()
                for i=1,5 do SafeFire(Remotes.CrimsonClaimReward); task.wait(0.3) end
            end)
        end
    end
})

TrollTab:CreateButton({
    Name = "🔮 Buka UI Crimson Altar Jarak Jauh",
    Callback = function()
        if not Remotes.CrimsonOpenUI then ResolveRemotes() end
        if Remotes.CrimsonOpenUI then SafeFire(Remotes.CrimsonOpenUI) end
    end
})

-- ─── TAB 9: MOVEMENT ───
local MoveTab = Window:CreateTab({ Name = "Movement", Icon = "rbxassetid://10734924532" })

MoveTab:CreateSection({ Name = "🏃 MANIPULASI FISIK" })

MoveTab:CreateSlider({
    Name = "🚶 WalkSpeed",
    Range = {16, 120},
    Increment = 1,
    CurrentValue = 16,
    Flag = "WS_Flag",
    Callback = function(val)
        Config.Features.Movement.WalkSpeed = val
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = val end
    end
})

MoveTab:CreateSlider({
    Name = "🦘 JumpPower",
    Range = {50, 250},
    Increment = 5,
    CurrentValue = 50,
    Flag = "JP_Flag",
    Callback = function(val)
        Config.Features.Movement.JumpPower = val
        local hum = GetHumanoid()
        if hum then hum.JumpPower = val end
    end
})

MoveTab:CreateToggle({
    Name = "👻 Noclip (Tembus Dinding)",
    CurrentValue = false,
    Flag = "Noclip_Flag",
    Callback = function(val)
        Config.Features.Movement.Noclip = val
        if val and not State.Connections["Noclip"] then
            State.Connections["Noclip"] = RunService.Stepped:Connect(function()
                if Config.Features.Movement.Noclip then
                    local char = LocalPlayer.Character
                    if char then
                        for _, p in ipairs(char:GetDescendants()) do
                            if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
                        end
                    end
                end
            end)
        elseif not val and State.Connections["Noclip"] then
            State.Connections["Noclip"]:Disconnect(); State.Connections["Noclip"] = nil
        end
    end
})

-- ═══════════════════════════════════════════════════════════
-- 9. GLOBAL SYSTEM CONNECTIONS & KEEP-ALIVE
-- ═══════════════════════════════════════════════════════════
State.Connections["AntiAFK"] = LocalPlayer.Idled:Connect(function()
    if not Config.General.AntiAFK then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end)

State.Threads["LookEventSpoof"] = task.spawn(function()
    while true do
        if Config.General.AutoLookEvent and Remotes.LookEvent then
            SafeFire(Remotes.LookEvent, nil)
        end
        task.wait(1.5)
    end
end)

State.Connections["CharAdded"] = LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        task.wait(0.2)
        hum.WalkSpeed = Config.Features.Movement.WalkSpeed
        hum.JumpPower = Config.Features.Movement.JumpPower
    end
end)

SafeNotify("MIZUKAGE OFFICIAL 👑", "VVIP God Mode Loaded! All 9 Tabs Rendered.", 5)