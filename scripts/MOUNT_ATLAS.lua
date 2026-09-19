--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                 MIZUKAGE OFFICIAL 👑                         ║
    ║      MOUNT ATLAS: CRIMSON ECLIPSE — VVIP AUTOMATION          ║
    ║             Rayfield Gen2 Clean Architecture                 ║
    ║         v12.0 — PURE RNG ENGINE & ZERO-BLANK UI              ║
    ╚══════════════════════════════════════════════════════════════╝
    Target Place ID : 104412011340255
    Architecture    : Server-Aligned RNG Engine (No Spoofing Dependencies)
    UI Framework    : Rayfield Gen2 (Clean Rendering, Zero Blank Icons)
--]]

-- ═══════════════════════════════════════════════════════════
-- 1. BOOTSTRAP & SINGLETON GUARD
-- ═══════════════════════════════════════════════════════════
if getgenv and getgenv().MIZUKAGE_ATLAS_V12 then
    warn("[Mizukage Official 👑] Instance aktif terdeteksi. Membersihkan sesi lama...")
    if getgenv().MIZUKAGE_ATLAS_UNLOAD then
        pcall(getgenv().MIZUKAGE_ATLAS_UNLOAD)
    end
end

if getgenv then
    getgenv().MIZUKAGE_ATLAS_V12 = true
end

-- ═══════════════════════════════════════════════════════════
-- 2. SERVICES & DEPENDENCIES
-- ═══════════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local VirtualUser       = game:GetService("VirtualUser")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")
local StarterGui        = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait(0.05) until Players.LocalPlayer
    LocalPlayer = Players.LocalPlayer
end

-- ═══════════════════════════════════════════════════════════
-- 3. CONSTANTS & SYSTEM METADATA
-- ═══════════════════════════════════════════════════════════
local Constants = {
    NAME = "Mizukage Official",
    BRAND = "Mizukage Official 👑",
    VERSION = "12.0.0",
    BUILD = "RNG Engine Master Release",
    TARGET_PLACE_ID = 104412011340255,

    RARITY_ORDER = {
        "Common", "Uncommon", "Rare", "Epic", "Legendary", "Unknown", "Eternal"
    },

    RARITY_RANK = {
        ["Common"]    = 1,
        ["Uncommon"]  = 2,
        ["Rare"]      = 3,
        ["Epic"]      = 4,
        ["Legendary"] = 5,
        ["Unknown"]   = 6,
        ["Eternal"]   = 7,
    }
}

-- ═══════════════════════════════════════════════════════════
-- 4. RAYFIELD GEN 2 NATIVE LOADER
-- ═══════════════════════════════════════════════════════════
local Rayfield
do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/gen2"))()
    end)
    if ok and type(result) == "table" then
        Rayfield = result
    else
        error("[Mizukage Official 👑] Gagal memuat Rayfield Gen2. Periksa koneksi internet.")
    end
end

-- ═══════════════════════════════════════════════════════════
-- 5. CONFIGURATION STORE
-- ═══════════════════════════════════════════════════════════
local Config = {
    General = {
        AntiAFK               = true,
        AutoLookEvent         = true,
        DisableNotifications  = true,
        DebugLog              = false,
    },
    Fishing = {
        AutoFishRNG           = false,
        CatchInterval         = 0.18,
        SelectedRod           = "Vanquisher",
        LuckMultiplier        = 0,
    },
    Economy = {
        AutoSellTrash         = false,
        AutoSellFish          = false,
        SellInterval          = 4.0,
        SellThresholdRarity   = "Rare", -- Jual ikan di bawah atau sama dengan tier ini
    },
    Automation = {
        AutoUpgradeRod        = false,
        AutoUpgradeInterval   = 1.5,
    },
    Movement = {
        WalkSpeed             = 16,
        JumpPower             = 50,
        Noclip                = false,
        InfiniteSprint        = false,
        SpamDash              = false,
    },
}

local State = {
    Threads     = {},
    Connections = {},
    Stats = {
        TotalCatches = 0,
        LastCatchName = "-",
        LastCatchRarity = "-",
        StartTime = os.clock(),
        RarityCount = {
            Common = 0, Uncommon = 0, Rare = 0, Epic = 0, Legendary = 0, Unknown = 0, Eternal = 0
        }
    },
    Lists = {
        Rods   = {},
        Auras  = {},
        Speeds = {},
        Slimes = {},
        Ranks  = {},
    },
}

-- ═══════════════════════════════════════════════════════════
-- 6. REMOTES RESOLUTION ENGINE
-- ═══════════════════════════════════════════════════════════
local Remotes = {
    RollFishFunction    = nil,
    FishGiver           = nil,
    FishCandidates      = {},
    SellFunc            = nil,
    Reward_GetData      = nil,
    LookEvent           = nil,
    Movement            = nil,
    BuySlime            = nil,
    SlimeStatus         = nil,
    RequestUpgrade      = nil,
    GetUpgradeData      = nil,
    RequestBuyAura      = nil,
    GetAuraStatus       = nil,
    SpeedRequestEquip   = nil,
    GetSpeedStatus      = nil,
    CrimsonGetStatus    = nil,
    CrimsonRequestCraft = nil,
    CrimsonClaimReward  = nil,
    CrimsonOpenUI       = nil,
    SendChat            = nil,
    RankPurchase        = nil,
}

local function ResolveRemotes()
    table.clear(Remotes.FishCandidates)

    local fs = ReplicatedStorage:FindFirstChild("FishingSystem")
    if fs then
        Remotes.SendChat         = fs:FindFirstChild("SendChatMessage")
        Remotes.RollFishFunction = fs:FindFirstChild("RollFishFunction")
        Remotes.FishGiver        = fs:FindFirstChild("FishGiver")

        local rEv = fs:FindFirstChild("RewardEvents")
        if rEv then Remotes.Reward_GetData = rEv:FindFirstChild("Reward_GetData") end

        local uEv = fs:FindFirstChild("UpgradeRodEvents")
        if uEv then
            Remotes.RequestUpgrade = uEv:FindFirstChild("RequestUpgrade")
            Remotes.GetUpgradeData = uEv:FindFirstChild("GetUpgradeData")
        end

        for _, n in ipairs({"FishGiver", "FishCaught", "CatchFish", "SendFish", "AddFish", "RequestCatch"}) do
            local r = fs:FindFirstChild(n)
            if r and r:IsA("RemoteEvent") then
                table.insert(Remotes.FishCandidates, r)
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

    local slR = ReplicatedStorage:FindFirstChild("SlimeShopRemotes")
    if slR then
        Remotes.BuySlime    = slR:FindFirstChild("RequestBuyOrEquipSlime")
        Remotes.SlimeStatus = slR:FindFirstChild("GetStatus")
    end

    local events = ReplicatedStorage:FindFirstChild("Events")
    if events then
        Remotes.SellFunc  = events:FindFirstChild("SellFunc")
        Remotes.LookEvent = events:FindFirstChild("LookEvent")
    end

    Remotes.Movement = ReplicatedStorage:FindFirstChild("Movement")
    Remotes.RankPurchase = ReplicatedStorage:FindFirstChild("RankPurchase")
end
ResolveRemotes()

-- ═══════════════════════════════════════════════════════════
-- 7. CLEANUP & RESOURCE MANAGER
-- ═══════════════════════════════════════════════════════════
local CleanupManager = {
    _connections = {},
    _tasks = {},
}

function CleanupManager:AddConnection(tag, conn)
    if not self._connections[tag] then self._connections[tag] = {} end
    table.insert(self._connections[tag], conn)
end

function CleanupManager:AddTask(tag, thread)
    if not self._tasks[tag] then self._tasks[tag] = {} end
    table.insert(self._tasks[tag], thread)
end

function CleanupManager:Clean(tag)
    if self._connections[tag] then
        for _, conn in ipairs(self._connections[tag]) do
            pcall(function() conn:Disconnect() end)
        end
        self._connections[tag] = nil
    end

    if self._tasks[tag] then
        for _, thread in ipairs(self._tasks[tag]) do
            pcall(function() task.cancel(thread) end)
        end
        self._tasks[tag] = nil
    end
end

function CleanupManager:CleanAll()
    for tag in pairs(self._connections) do self:Clean(tag) end
    for tag in pairs(self._tasks) do self:Clean(tag) end
end

-- ═══════════════════════════════════════════════════════════
-- 8. CORE UTILITIES
-- ═══════════════════════════════════════════════════════════
local function SafeNotify(title, content, duration)
    pcall(function()
        Rayfield:Notify({
            Title    = title,
            Content  = content,
            Duration = duration or 3,
        })
    end)
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
    if remote and remote:IsA("RemoteEvent") then
        local ok, err = pcall(remote.FireServer, remote, ...)
        if not ok and Config.General.DebugLog then
            warn("[Mizukage Official 👑] Remote Fire Error: " .. tostring(err))
        end
        return ok
    end
    return false
end

local function SafeInvoke(remote, ...)
    if remote and remote:IsA("RemoteFunction") then
        local ok, res = pcall(remote.InvokeServer, remote, ...)
        if ok then return res end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════
-- 9. DYNAMIC ENUM EXTRACTIONS
-- ═══════════════════════════════════════════════════════════
local function ExtractAllCatalogs()
    -- Rod List
    table.clear(State.Lists.Rods)
    local fallbackRods = {
        "Vanquisher", "AETHERION", "Crimson Eclipse", "Celestial Aegis", "Ethereal Rainbow",
        "Reaver Scythe", "Soul Scythe", "Holy Trident", "Aether Shard", "God Rod",
        "Megalofriend", "GhostRod", "Fluorescent Rod", "LightingPunk Rod", "Forsaken",
        "Abyssal Chroma", "Oceanic Harpoon", "Heartfelt Blade", "Red Hammer", "Spirit Staff"
    }
    for _, rod in ipairs(fallbackRods) do
        table.insert(State.Lists.Rods, rod)
    end
    table.sort(State.Lists.Rods)

    -- Aura List
    table.clear(State.Lists.Auras)
    if Remotes.GetAuraStatus then
        local res = SafeInvoke(Remotes.GetAuraStatus)
        if type(res) == "table" then
            for key in pairs(res) do
                if type(key) == "string" then table.insert(State.Lists.Auras, key) end
            end
        end
    end
    if #State.Lists.Auras == 0 then
        for _, v in ipairs({"DrStrange", "Shatterspace", "Serenity", "Power", "Rhythmistic"}) do
            table.insert(State.Lists.Auras, v)
        end
    end
    table.sort(State.Lists.Auras)

    -- Speeds
    table.clear(State.Lists.Speeds)
    for lvl = 0, 7 do table.insert(State.Lists.Speeds, tostring(lvl)) end

    -- Slimes
    table.clear(State.Lists.Slimes)
    if Remotes.SlimeStatus then
        local res = SafeInvoke(Remotes.SlimeStatus)
        if type(res) == "table" then
            for _, v in ipairs(res) do
                if type(v) == "string" then table.insert(State.Lists.Slimes, v) end
            end
        end
    end
    if #State.Lists.Slimes == 0 then
        for _, v in ipairs({"Blizzard", "Leafy", "Coco", "Spooky", "Chaby", "Goldie", "Apex", "Lucki", "Angel"}) do
            table.insert(State.Lists.Slimes, v)
        end
    end
    table.sort(State.Lists.Slimes)
end
ExtractAllCatalogs()

-- ═══════════════════════════════════════════════════════════
-- 10. RNG FISHING & SMART COMMERCE ENGINES
-- ═══════════════════════════════════════════════════════════

-- [RNG FISHING ENGINE]
local function ExecuteFishingRNG()
    if not Remotes.RollFishFunction or not Remotes.FishGiver then
        ResolveRemotes()
    end

    local root = GetRoot()
    local rootPos = root and root.Position or Vector3.new(0, 0, 0)
    local rodToUse = Config.Fishing.SelectedRod or "Vanquisher"

    -- 1. Jalankan Roll RNG Resmi di Server
    if Remotes.RollFishFunction then
        pcall(function()
            Remotes.RollFishFunction:InvokeServer(rodToUse, Config.Fishing.LuckMultiplier)
        end)
    end

    -- 2. Trigger FishGiver dengan posisi asli kail (Tanpa memalsukan data ikan)
    local payload = {
        hookPosition = rootPos
    }

    local fired = false
    if Remotes.FishGiver then
        fired = SafeFire(Remotes.FishGiver, payload)
    end

    if not fired then
        for _, remote in ipairs(Remotes.FishCandidates) do
            if remote ~= Remotes.FishGiver and SafeFire(remote, payload) then
                fired = true
                break
            end
        end
    end

    if fired then
        State.Stats.TotalCatches = State.Stats.TotalCatches + 1
    end
    return fired
end

-- [SMART AUTO-SELL ENGINE]
local function BuildSellInventory(itemType, maxRarityRank)
    local payload = { Type = itemType }
    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local count = 0

    for _, container in ipairs({char, bp}) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") and item:GetAttribute("TYPE") == itemType then
                    local cleanName = item:GetAttribute("FishName") or item:GetAttribute("Name") or item:GetAttribute("ItemName")
                    if not cleanName then
                        local raw = item.Name
                        local underscore = string.find(raw, "_", 1, true)
                        cleanName = underscore and string.sub(raw, underscore + 1) or raw
                    end

                    local rarity = item:GetAttribute("Rarity") or "Common"
                    local rank = Constants.RARITY_RANK[rarity] or 1

                    -- Filter: Hanya jual jika di bawah atau sama dengan threshold
                    if rank <= maxRarityRank then
                        local amount = item:GetAttribute("amount") or 1
                        payload[cleanName] = (payload[cleanName] or 0) + amount
                        count = count + amount
                    end
                end
            end
        end
    end
    return payload, count
end

local function ExecuteSmartSell(itemType)
    if not Remotes.SellFunc then ResolveRemotes() end
    if not Remotes.SellFunc then return 0 end

    local thresholdRank = Constants.RARITY_RANK[Config.Economy.SellThresholdRarity] or 3
    if itemType == "Trash" then
        thresholdRank = 99 -- Sampah selalu dijual
    end

    local payload, count = BuildSellInventory(itemType, thresholdRank)
    if count > 0 then
        if Remotes.SellFunc:IsA("RemoteFunction") then
            pcall(function()
                Remotes.SellFunc:InvokeServer("Sell", payload)
                Remotes.SellFunc:InvokeServer("GetSavedLoot")
            end)
        else
            SafeFire(Remotes.SellFunc, "Sell", payload)
        end
        return count
    end
    return 0
end

local function ExecuteDash()
    local char = LocalPlayer.Character
    if not char then return end
    local katana = char:FindFirstChild("KatanaV2")
    if not katana then return end
    local dashRemote = katana:FindFirstChild("DashRemote")
    if not dashRemote then return end
    local root = GetRoot()
    local pos = root and root.Position or Vector3.new(0, 0, 0)
    pcall(function() dashRemote:FireServer(char, pos) end)
end

-- ═══════════════════════════════════════════════════════════
-- 11. INVENTORY SCANNER & LISTENER (TELEMETRY)
-- ═══════════════════════════════════════════════════════════
local function HookInventoryListener()
    local function checkItem(item)
        if item:IsA("Tool") and item:GetAttribute("TYPE") == "Fish" then
            local fishName = item:GetAttribute("FishName") or item.Name
            local rarity = item:GetAttribute("Rarity") or "Common"

            State.Stats.LastCatchName = fishName
            State.Stats.LastCatchRarity = rarity
            if State.Stats.RarityCount[rarity] then
                State.Stats.RarityCount[rarity] = State.Stats.RarityCount[rarity] + 1
            end

            local rank = Constants.RARITY_RANK[rarity] or 1
            if rank >= 5 then
                SafeNotify("TANGKAPAN LANGKA!", string.format("%s [%s]", fishName, rarity), 4)
            end
        end
    end

    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        bp.ChildAdded:Connect(checkItem)
    end
    if LocalPlayer.Character then
        LocalPlayer.Character.ChildAdded:Connect(checkItem)
    end
end
HookInventoryListener()

-- ═══════════════════════════════════════════════════════════
-- 12. RAYFIELD GEN 2 UI (CLEAN ARCHITECTURE — ZERO BLANK ICONS)
-- ═══════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name                   = Constants.BRAND .. " | Mount Atlas",
    LoadingTitle           = Constants.NAME,
    LoadingSubtitle        = "RNG Engine Edition v12.0",
    Theme                  = "Amethyst",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings   = true,
    ConfigurationSaving    = {
        Enabled    = false,
    },
})

-- ─── SAFE TAB ADAPTER (Tanpa Icon String yang Bermasalah) ───
local function CreateCleanTab(title)
    local ok, tab = pcall(function()
        return Window:CreateTab({
            Name = title,
            name = title,
        })
    end)
    if ok and tab then return tab end

    local ok2, tab2 = pcall(function()
        return Window:CreateTab(title)
    end)
    if ok2 and tab2 then return tab2 end

    error("Gagal menginisialisasi Tab: " .. tostring(title))
end

-- ─── TAB 1: DASHBOARD ───
local DashTab = CreateCleanTab("Dashboard")
DashTab:CreateSection("STATUS PENGGUNA")

DashTab:CreateButton({
    Name = "Pemain: " .. LocalPlayer.Name,
    Callback = function() end,
})

DashTab:CreateButton({
    Name = "Lihat Statistik Sesi Memancing",
    Callback = function()
        local r = State.Stats.RarityCount
        local text = string.format(
            "Total Roll: %d\nIkan Terakhir: %s [%s]\nCommon: %d | Rare: %d\nEpic: %d | Legendary: %d\nUnknown: %d | Eternal: %d",
            State.Stats.TotalCatches,
            State.Stats.LastCatchName,
            State.Stats.LastCatchRarity,
            r.Common or 0, r.Rare or 0,
            r.Epic or 0, r.Legendary or 0,
            r.Unknown or 0, r.Eternal or 0
        )
        SafeNotify("Statistik Sesi", text, 6)
    end,
})

DashTab:CreateDivider()
DashTab:CreateSection("AUTOMATION MASTER")

DashTab:CreateToggle({
    Name = "Master Automation (Auto-RNG + Auto-Sell)",
    CurrentValue = false,
    Flag = "MasterAutoToggle",
    Callback = function(val)
        Config.Fishing.AutoFishRNG    = val
        Config.Economy.AutoSellFish   = val
        Config.Economy.AutoSellTrash  = val

        if val then
            CleanupManager:AddTask("MasterFishing", task.spawn(function()
                while Config.Fishing.AutoFishRNG do
                    ExecuteFishingRNG()
                    task.wait(Config.Fishing.CatchInterval)
                end
            end))
            CleanupManager:AddTask("MasterSelling", task.spawn(function()
                while Config.Economy.AutoSellFish or Config.Economy.AutoSellTrash do
                    if Config.Economy.AutoSellFish  then ExecuteSmartSell("Fish") end
                    if Config.Economy.AutoSellTrash then ExecuteSmartSell("Trash") end
                    task.wait(Config.Economy.SellInterval)
                end
            end))
            SafeNotify("Master Auto", "Semua sistem aktif.", 3)
        else
            CleanupManager:Clean("MasterFishing")
            CleanupManager:Clean("MasterSelling")
            SafeNotify("Master Auto", "Semua sistem nonaktif.", 3)
        end
    end,
})

DashTab:CreateToggle({
    Name = "Blokir Notifikasi Spam Layar",
    CurrentValue = true,
    Flag = "Toggle_MutePopups",
    Callback = function(val)
        Config.General.DisableNotifications = val
    end,
})

DashTab:CreateToggle({
    Name = "Proteksi Anti-AFK",
    CurrentValue = true,
    Flag = "Toggle_AntiAfk",
    Callback = function(val)
        Config.General.AntiAFK = val
    end,
})

-- ─── TAB 2: AUTONOMOUS RNG FISHING ───
local FishTab = CreateCleanTab("RNG Fishing")
FishTab:CreateSection("KONTROL AUTOMASI MEMANCING (PURE RNG)")

FishTab:CreateToggle({
    Name = "Aktifkan Auto Fish (RNG Loop)",
    CurrentValue = false,
    Flag = "Toggle_AutoRNG",
    Callback = function(val)
        Config.Fishing.AutoFishRNG = val
        if val then
            CleanupManager:AddTask("RNG_Loop", task.spawn(function()
                while Config.Fishing.AutoFishRNG do
                    ExecuteFishingRNG()
                    task.wait(Config.Fishing.CatchInterval)
                end
            end))
            SafeNotify("Auto Fish", "Loop penarikan RNG aktif.", 3)
        else
            CleanupManager:Clean("RNG_Loop")
            SafeNotify("Auto Fish", "Loop penarikan RNG berhenti.", 3)
        end
    end,
})

FishTab:CreateSlider({
    Name = "Kecepatan Tarikan (Interval Detik)",
    Range = { 0.05, 2.0 },
    Increment = 0.01,
    CurrentValue = Config.Fishing.CatchInterval,
    Flag = "Slider_CatchInterval",
    Callback = function(val)
        Config.Fishing.CatchInterval = val
    end,
})

local defaultRod = State.Lists.Rods[1] or "Vanquisher"
FishTab:CreateDropdown({
    Name = "Pilih Rod untuk Roll",
    Options = #State.Lists.Rods > 0 and State.Lists.Rods or { "Vanquisher" },
    CurrentOption = { defaultRod },
    MultipleOptions = false,
    Flag = "Dropdown_RodSelection",
    Callback = function(opt)
        Config.Fishing.SelectedRod = type(opt) == "table" and opt[1] or opt
    end,
})

FishTab:CreateSlider({
    Name = "Pengali Keberuntungan (Bonus Luck)",
    Range = { 0, 100 },
    Increment = 1,
    CurrentValue = 0,
    Flag = "Slider_BonusLuck",
    Callback = function(val)
        Config.Fishing.LuckMultiplier = val
    end,
})

FishTab:CreateDivider()
FishTab:CreateSection("MANUAL INSTANT ROLL")

FishTab:CreateButton({
    Name = "Roll 1x Tangkapan Sekarang",
    Callback = function()
        local ok = ExecuteFishingRNG()
        SafeNotify("Manual Roll", ok and "Roll berhasil dikirim ke server." or "Gagal memicu remote.", 2)
    end,
})

FishTab:CreateButton({
    Name = "Roll 10x Rapid Bursts",
    Callback = function()
        task.spawn(function()
            for _ = 1, 10 do
                ExecuteFishingRNG()
                task.wait(0.05)
            end
            SafeNotify("Rapid Bursts", "10x roll selesai diproses.", 3)
        end)
    end,
})

-- ─── TAB 3: SMART COMMERCE ───
local EconTab = CreateCleanTab("Penjualan & Ekonomi")
EconTab:CreateSection("FILTER PENJUALAN SELEKTIF (ANTI TAS PENUH)")

EconTab:CreateDropdown({
    Name = "Batas Rarity Maksimal yang Dijual",
    Options = { "Common", "Uncommon", "Rare", "Epic" },
    CurrentOption = { "Rare" },
    MultipleOptions = false,
    Flag = "Dropdown_SellRarityThreshold",
    Callback = function(opt)
        Config.Economy.SellThresholdRarity = type(opt) == "table" and opt[1] or opt
    end,
})

EconTab:CreateToggle({
    Name = "Loop Auto Jual Ikan (Sesuai Batas Rarity)",
    CurrentValue = false,
    Flag = "Toggle_AutoSellFish",
    Callback = function(val)
        Config.Economy.AutoSellFish = val
        if val then
            CleanupManager:AddTask("Loop_SellFish", task.spawn(function()
                while Config.Economy.AutoSellFish do
                    ExecuteSmartSell("Fish")
                    task.wait(Config.Economy.SellInterval)
                end
            end))
        else
            CleanupManager:Clean("Loop_SellFish")
        end
    end,
})

EconTab:CreateToggle({
    Name = "Loop Auto Jual Sampah",
    CurrentValue = false,
    Flag = "Toggle_AutoSellTrash",
    Callback = function(val)
        Config.Economy.AutoSellTrash = val
        if val then
            CleanupManager:AddTask("Loop_SellTrash", task.spawn(function()
                while Config.Economy.AutoSellTrash do
                    ExecuteSmartSell("Trash")
                    task.wait(Config.Economy.SellInterval)
                end
            end))
        else
            CleanupManager:Clean("Loop_SellTrash")
        end
    end,
})

EconTab:CreateSlider({
    Name = "Jeda Auto Jual (Detik)",
    Range = { 2.0, 20.0 },
    Increment = 0.5,
    CurrentValue = 4.0,
    Flag = "Slider_SellInterval",
    Callback = function(val)
        Config.Economy.SellInterval = val
    end,
})

EconTab:CreateDivider()
EconTab:CreateSection("PENJUALAN INSTAN")

EconTab:CreateButton({
    Name = "Jual Semua Ikan (Di Bawah Filter) Sekarang",
    Callback = function()
        local n = ExecuteSmartSell("Fish")
        SafeNotify("Penjualan", n > 0 and ("Berhasil menjual " .. n .. " ikan.") or "Tidak ada ikan yang memenuhi kriteria penjualan.", 3)
    end,
})

EconTab:CreateButton({
    Name = "Jual Semua Sampah Sekarang",
    Callback = function()
        local n = ExecuteSmartSell("Trash")
        SafeNotify("Penjualan", n > 0 and ("Berhasil menjual " .. n .. " sampah.") or "Tidak ada sampah.", 3)
    end,
})

-- ─── TAB 4: BLACK MARKET & TOKO ───
local ShopTab = CreateCleanTab("Black Market")
ShopTab:CreateSection("SLIME & PET STORE")

local selectedSlime = State.Lists.Slimes[1] or "Blizzard"
ShopTab:CreateDropdown({
    Name = "Pilih Slime",
    Options = #State.Lists.Slimes > 0 and State.Lists.Slimes or { "Blizzard" },
    CurrentOption = { selectedSlime },
    MultipleOptions = false,
    Flag = "Dropdown_SelectSlime",
    Callback = function(opt)
        selectedSlime = type(opt) == "table" and opt[1] or opt
    end,
})

ShopTab:CreateButton({
    Name = "Beli Slime Terpilih",
    Callback = function()
        if not Remotes.BuySlime then ResolveRemotes() end
        if Remotes.BuySlime then
            SafeFire(Remotes.BuySlime, selectedSlime)
            SafeNotify("Toko Slime", "Permintaan beli: " .. selectedSlime, 3)
        end
    end,
})

ShopTab:CreateButton({
    Name = "Beli SEMUA Slime Sekaligus",
    Callback = function()
        if not Remotes.BuySlime then ResolveRemotes() end
        if Remotes.BuySlime then
            task.spawn(function()
                for _, s in ipairs(State.Lists.Slimes) do
                    SafeFire(Remotes.BuySlime, s)
                    task.wait(0.15)
                end
                SafeNotify("Toko Slime", "Semua pesanan slime dikirim.", 3)
            end)
        end
    end,
})

ShopTab:CreateDivider()
ShopTab:CreateSection("AURA & SPEED")

ShopTab:CreateButton({
    Name = "Beli & Pasang SEMUA Aura",
    Callback = function()
        if not Remotes.RequestBuyAura then ResolveRemotes() end
        if Remotes.RequestBuyAura then
            task.spawn(function()
                for _, aura in ipairs(State.Lists.Auras) do
                    SafeInvoke(Remotes.RequestBuyAura, aura)
                    task.wait(0.2)
                end
                SafeNotify("Aura", "Semua aura telah diproses.", 3)
            end)
        end
    end,
})

ShopTab:CreateButton({
    Name = "Pasang SEMUA Level Speed",
    Callback = function()
        if not Remotes.SpeedRequestEquip then ResolveRemotes() end
        if Remotes.SpeedRequestEquip then
            task.spawn(function()
                for _, spd in ipairs(State.Lists.Speeds) do
                    SafeInvoke(Remotes.SpeedRequestEquip, tonumber(spd) or 0)
                    task.wait(0.15)
                end
                SafeNotify("Speed", "Semua level speed diaktifkan.", 3)
            end)
        end
    end,
})

-- ─── TAB 5: UPGRADE ROD ───
local UpgradeTab = CreateCleanTab("Upgrade Rod")
UpgradeTab:CreateSection("AUTOMATED ROD REINFORCEMENT")

local upgradeRodChoice = State.Lists.Rods[1] or "Vanquisher"
UpgradeTab:CreateDropdown({
    Name = "Pilih Rod untuk Di-Upgrade",
    Options = #State.Lists.Rods > 0 and State.Lists.Rods or { "Vanquisher" },
    CurrentOption = { upgradeRodChoice },
    MultipleOptions = false,
    Flag = "Dropdown_UpgradeRodChoice",
    Callback = function(opt)
        upgradeRodChoice = type(opt) == "table" and opt[1] or opt
    end,
})

UpgradeTab:CreateButton({
    Name = "Kirim Permintaan Upgrade 10x (Rod Terpilih)",
    Callback = function()
        if not Remotes.RequestUpgrade then ResolveRemotes() end
        if Remotes.RequestUpgrade then
            task.spawn(function()
                for _ = 1, 10 do
                    SafeFire(Remotes.RequestUpgrade, upgradeRodChoice)
                    task.wait(0.1)
                end
                SafeNotify("Upgrade", "10x upgrade dikirim ke: " .. upgradeRodChoice, 3)
            end)
        end
    end,
})

UpgradeTab:CreateToggle({
    Name = "Loop Auto-Upgrade Rod Terpilih",
    CurrentValue = false,
    Flag = "Toggle_LoopUpgrade",
    Callback = function(val)
        Config.Automation.AutoUpgradeRod = val
        if val then
            CleanupManager:AddTask("Loop_Upgrade", task.spawn(function()
                while Config.Automation.AutoUpgradeRod do
                    if Remotes.RequestUpgrade then
                        SafeFire(Remotes.RequestUpgrade, upgradeRodChoice)
                    end
                    task.wait(Config.Automation.AutoUpgradeInterval)
                end
            end))
        else
            CleanupManager:Clean("Loop_Upgrade")
        end
    end,
})

-- ─── TAB 6: EVENT & ALTAR ───
local EventTab = CreateCleanTab("Event & Altar")
EventTab:CreateSection("CRIMSON ECLIPSE & ALTAR ACTIONS")

EventTab:CreateButton({
    Name = "Klaim Reward Crimson Eclipse (5x)",
    Callback = function()
        if not Remotes.CrimsonClaimReward then ResolveRemotes() end
        if Remotes.CrimsonClaimReward then
            task.spawn(function()
                for _ = 1, 5 do
                    SafeFire(Remotes.CrimsonClaimReward)
                    task.wait(0.2)
                end
                SafeNotify("Crimson Event", "Klaim reward selesai.", 3)
            end)
        end
    end,
})

EventTab:CreateButton({
    Name = "Buka UI Altar Crimson",
    Callback = function()
        if not Remotes.CrimsonOpenUI then ResolveRemotes() end
        if Remotes.CrimsonOpenUI then
            SafeFire(Remotes.CrimsonOpenUI)
        end
    end,
})

EventTab:CreateButton({
    Name = "Klaim Reward Index",
    Callback = function()
        if not Remotes.Reward_GetData then ResolveRemotes() end
        if Remotes.Reward_GetData then
            SafeInvoke(Remotes.Reward_GetData)
            SafeNotify("Pokedex", "Klaim data reward index dikirim.", 3)
        end
    end,
})

-- ─── TAB 7: PERGERAKAN ───
local MoveTab = CreateCleanTab("Pergerakan")
MoveTab:CreateSection("KONTROL FISIK KARAKTER")

MoveTab:CreateSlider({
    Name = "Kecepatan Jalan (WalkSpeed)",
    Range = { 16, 150 },
    Increment = 1,
    CurrentValue = 16,
    Flag = "Slider_WalkSpeed",
    Callback = function(val)
        Config.Movement.WalkSpeed = val
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = val end
    end,
})

MoveTab:CreateSlider({
    Name = "Kekuatan Lompat (JumpPower)",
    Range = { 50, 250 },
    Increment = 5,
    CurrentValue = 50,
    Flag = "Slider_JumpPower",
    Callback = function(val)
        Config.Movement.JumpPower = val
        local hum = GetHumanoid()
        if hum then hum.JumpPower = val end
    end,
})

MoveTab:CreateToggle({
    Name = "Noclip (Tembus Dinding)",
    CurrentValue = false,
    Flag = "Toggle_Noclip",
    Callback = function(val)
        Config.Movement.Noclip = val
        if val then
            local conn = RunService.Stepped:Connect(function()
                if Config.Movement.Noclip and LocalPlayer.Character then
                    for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                        if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
                    end
                end
            end)
            CleanupManager:AddConnection("Noclip", conn)
        else
            CleanupManager:Clean("Noclip")
        end
    end,
})

MoveTab:CreateToggle({
    Name = "Infinite Dash (KatanaV2)",
    CurrentValue = false,
    Flag = "Toggle_DashSpam",
    Callback = function(val)
        Config.Movement.SpamDash = val
        if val then
            CleanupManager:AddTask("SpamDash", task.spawn(function()
                while Config.Movement.SpamDash do
                    ExecuteDash()
                    task.wait(0.08)
                end
            end))
        else
            CleanupManager:Clean("SpamDash")
        end
    end,
})

-- ─── TAB 8: PENGATURAN & SHUTDOWN ───
local SetTab = CreateCleanTab("Pengaturan")
SetTab:CreateSection("MANAJEMEN SCRIPT")

SetTab:CreateToggle({
    Name = "Console Debug Output",
    CurrentValue = false,
    Flag = "Toggle_DebugLog",
    Callback = function(val)
        Config.General.DebugLog = val
    end,
})

SetTab:CreateButton({
    Name = "Bongkar Script & Hentikan Sesi (Unload)",
    Callback = function()
        Config.Fishing.AutoFishRNG = false
        Config.Economy.AutoSellFish = false
        Config.Economy.AutoSellTrash = false
        CleanupManager:CleanAll()

        if getgenv then getgenv().MIZUKAGE_ATLAS_V12 = nil end
        SafeNotify("Shutdown", "Script berhasil dinonaktifkan.", 3)
        task.wait(0.5)
        if Rayfield and Rayfield.Destroy then
            pcall(function() Rayfield:Destroy() end)
        end
    end,
})

-- ═══════════════════════════════════════════════════════════
-- 13. GLOBAL BACKGROUND DAEMONS & HOOKS
-- ═══════════════════════════════════════════════════════════
-- Anti-AFK
local afkConn = LocalPlayer.Idled:Connect(function()
    if Config.General.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end
end)
CleanupManager:AddConnection("Global_AntiAFK", afkConn)

-- Auto Look Event
local lookTask = task.spawn(function()
    while true do
        if Config.General.AutoLookEvent and Remotes.LookEvent then
            SafeFire(Remotes.LookEvent, nil)
        end
        task.wait(1.5)
    end
end)
CleanupManager:AddTask("Global_LookEvent", lookTask)

-- Character Respawn Persist
local charConn = LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        task.wait(0.3)
        hum.WalkSpeed = Config.Movement.WalkSpeed
        hum.JumpPower = Config.Movement.JumpPower
    end
    HookInventoryListener()
end)
CleanupManager:AddConnection("Global_CharAdded", charConn)

-- Export Shutdown
if getgenv then
    getgenv().MIZUKAGE_ATLAS_UNLOAD = function()
        Config.Fishing.AutoFishRNG = false
        Config.Economy.AutoSellFish = false
        Config.Economy.AutoSellTrash = false
        CleanupManager:CleanAll()
        if Rayfield and Rayfield.Destroy then pcall(function() Rayfield:Destroy() end) end
        getgenv().MIZUKAGE_ATLAS_V12 = nil
    end
end

SafeNotify(Constants.BRAND, "v12.0 Siap Digunakan!\nUI bersih tanpa icon blank. RNG Fishing aktif.", 5)