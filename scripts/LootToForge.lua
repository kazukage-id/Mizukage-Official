local env = (getgenv and getgenv()) or _G

if not game:IsLoaded() then game.Loaded:Wait() end
if env.LootForgeAllInOne then
    return game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "LootForge", Text = "UI sudah berjalan (RightShift).",
    })
end
env.LootForgeAllInOne = true

-- ═══════════════════════════════════════════════════════════
-- [1] SERVICES
-- ═══════════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do task.wait(0.05); LocalPlayer = Players.LocalPlayer end

local RemoteRoot = ReplicatedStorage:WaitForChild("Remote", 15)

-- ═══════════════════════════════════════════════════════════
-- [2] LOAD WINDUI
-- ═══════════════════════════════════════════════════════════
local WindUI
do
    local sources = {
        "https://github.com/Footagesus/WindUI/releases/download/1.6.65/main.lua",
        "https://tree-hub.vercel.app/api/UI/WindUI",
    }
    for _, url in ipairs(sources) do
        local ok, result = pcall(function() return loadstring(game:HttpGet(url))() end)
        if ok and type(result) == "table" then WindUI = result; break end
    end
    if not WindUI then
        env.LootForgeAllInOne = nil
        return warn("[LootForge] WindUI gagal dimuat.")
    end
end

-- ═══════════════════════════════════════════════════════════
-- [3] ENGINE (Core) — inline
-- ═══════════════════════════════════════════════════════════
local Hub = (function()

local function tryRequire(path)
    local ok, mod = pcall(function()
        local node = ReplicatedStorage
        for _, name in ipairs(path) do node = node:WaitForChild(name, 5) end
        return require(node)
    end)
    return ok and mod or nil
end

local BackpackData     = tryRequire({ "LocalData", "BackpackData" })
local ProfileData      = tryRequire({ "ProfileData" })
local OreHelper        = tryRequire({ "Config", "Ore", "Helper" })
local WeaponHelper     = tryRequire({ "Config", "Weapon", "Helper" })
local ArmorHelper      = tryRequire({ "Config", "Armor", "Helper" })
local EnchStoneHelper  = tryRequire({ "Config", "EnchStone", "Helper" })
local EnhantHelper     = tryRequire({ "Config", "Enhant", "Helper" })
local RarityHelper     = tryRequire({ "Config", "Rarity", "Helper" })
local TrainCTRL        = tryRequire({ "CTRL", "TrainCTRL" })
local EnemyCTRL        = tryRequire({ "CTRL", "EnemyCTRL" })
local HPCTRL           = tryRequire({ "CTRL", "HPCTRL" })
local CommunicationUtils = tryRequire({ "Utils", "CommunicationUtils" })

local function getBindable(category, name)
    if not (CommunicationUtils and CommunicationUtils.TryGetBindableEvent) then return nil end
    local ok, be = pcall(CommunicationUtils.TryGetBindableEvent, category, name)
    return ok and be or nil
end
local EnemyHitBE = getBindable("Attack", "EnemyHitBE")

-- Config (semua toggle default OFF)
local Cfg = {
    Master = false, MasterDungeonTicket = true, MasterStageBlitz = true,
    MasterTrainWhenIdle = true, MasterAutoClickSword = true,
    MasterAutoUpgrade = true, MasterAutoForge = true,

    DropMagnet = false, MagnetTarget = "Safe Zone", MagnetInterval = 0.15,
    UltraPrompt = false,
    AutoSafeEvacuate = false, EvacuateThreshold = 90,
    LowHPEvacuate = false, LowHPThreshold = 25,

    AutoDungeon = false, DungeonRound = 1, AutoClaimTicket = true, DungeonInstaKill = true,
    AutoStage = false, Stage = "Auto", StageInstaKill = true,
    AutoClimbStages = false, StageClimbTimeout = 25,
    StageBlitz = false, StageBlitzInterval = 0.09, ConcurrentForge = true,
    KillAura = false, KillAuraDelay = 0.15,
    SafeFlight = false, FlightHeight = 14,
    GodMode = false,
    SuperLootHunter = false, SuperLootTier = "All",

    AutoTrain = false, TrainDelay = 0.15,
    AutoTrainZone = false, TrainZone = "Auto",
    NativeAutoTrain = false, RemoteOnlyTrain = false,
    AutoClickSword = false, SwordClickDelay = 0.16,
    AutoUpgrade = false, UpgradeType = "All in One", UpgradeDelay = 1.5,
    AutoRebirth = false, RebirthDelay = 10, NativeAutoRebirth = false,

    AutoForge = false, ForgeDelay = 1.0, ForgeType = "All",
    MinOreToForge = 4, OreQualityMode = "Any",
    AutoEquipBest = false, UseDPSSolver = true,
    AutoEnhance = false, EnhanceDelay = 1.5,
    AutoEnchant = false, EnchantDelay = 1.5, EnchantMaxGrade = "Mythic",
    EnchantKeepHighGrade = true, EnchantSlots = "All",

    AutoSell = false, SellDelay = 8,
    AutoSellTrashGear = false, MinGearRarityToKeep = "Legendary",
    AutoSellOres = false, OreRaritiesToKeep = { "Infinite", "Ancient", "Secret", "Eternal", "Mythic", "Legendary" }, KeepMinOreAmount = 0,
    AutoSellEnchantStones = false, EnchantFilterMode = "Sell Selected", EnchantRaritiesToTarget = { "Common", "Uncommon", "Rare" }, KeepMinStoneAmount = 0,

    AutoRollClass = false, TargetClass = "Class_9", RollClassDelay = 1.5,
    AutoRollSkills = false, RollSkillDelay = 2.0,
    AutoHatchEggs = false, HatchEggDelay = 2.0,
    AutoUsePotions = false, PotionDelay = 8.0,
    AutoEquipBestPet = false, PetEquipDelay = 3.0,
    AutoClaimRewards = false, ClaimDelay = 60,

    WalkSpeed = 16, JumpPower = 50,
    InfJump = false, Noclip = false, AntiAFK = true, AntiTrip = false, AutoReconnect = false, CpuSaver = false,

    Webhook = false, WebhookUrl = "", NotifyRareDrops = true, NotifySuperLoot = true, NotifyHourlyReport = true,
    Debug = false,
}

local Stats = {
    StartTime = os.time(), OresCollected = 0, SellCycles = 0, Kills = 0,
    RebirthCount = 0, SuperLootKills = 0, CurrentActivity = "Ready",
    LastStageClear = os.time(), LastHourlyPost = os.time(),
}

local Hub = { Cfg = Cfg, Stats = Stats, OnNotify = nil }
local function notify(title, text)
    if Hub.OnNotify then pcall(Hub.OnNotify, tostring(title), tostring(text)) end
    if Cfg.Debug then print("[Core]", title, text) end
end

-- Helper dasar
local function getRemote(folder, name)
    if not RemoteRoot then return nil end
    local f = RemoteRoot:FindFirstChild(folder .. "_Server") or RemoteRoot:FindFirstChild(folder)
    return f and f:FindFirstChild(name) or nil
end

local function call(folder, name, ...)
    local r = getRemote(folder, name)
    if not r then return nil end
    local args = { ... }
    local ok, res = pcall(function()
        if r:IsA("RemoteFunction") then return r:InvokeServer(unpack(args)) end
        r:FireServer(unpack(args))
    end)
    return ok and res or nil
end

local function char() return LocalPlayer.Character end
local function hrp() local c = char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = char(); return c and c:FindFirstChildOfClass("Humanoid") end

local function getSafeZoneCF()
    local spawn = workspace:FindFirstChild("SpawnLocation")
    if spawn then
        if spawn:IsA("Model") then return spawn:GetPivot() end
        if spawn:IsA("BasePart") then return spawn.CFrame end
    end
    local obj = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    return obj and obj.CFrame or CFrame.new(0, 5, 0)
end

local function tpTo(cf)
    local r = hrp()
    if r then
        r.AssemblyLinearVelocity = Vector3.zero
        r.AssemblyAngularVelocity = Vector3.zero
        r.CFrame = cf + Vector3.new(0, 3, 0)
    end
end

local function getPackInfo()
    local cur, maxNum = 0, 10
    pcall(function() cur = require(ReplicatedStorage.GuiUtils.LeftInfoGUI).GetOrePack() or 0 end)
    pcall(function() maxNum = require(ReplicatedStorage.LocalData.UpgradeData).GetMaxNum("OrePack") or 10 end)
    return cur, maxNum
end

local function getBackpackItems()
    if not BackpackData or type(BackpackData.GetData) ~= "function" then return nil end
    local ok, data = pcall(BackpackData.GetData)
    return ok and type(data) == "table" and type(data.have) == "table" and data.have or nil
end

local function countOres()
    local total, items = 0, getBackpackItems()
    if not items then return nil end
    for _, it in pairs(items) do
        if type(it) == "table" and it.Type == "Ore" then total += tonumber(it.Number) or 1 end
    end
    return total
end

local function isEquipped(uuid)
    local ok, r = pcall(function() return BackpackData and BackpackData.IsEquipedUUID and BackpackData.IsEquipedUUID(uuid) end)
    return ok and r or false
end

-- Scheduler
local ActiveThreads = {}
local function startLoop(flag, delay, fn)
    if ActiveThreads[flag] then return end
    ActiveThreads[flag] = true
    task.spawn(function()
        while Cfg[flag] do
            local ok, err = pcall(fn)
            if not ok and Cfg.Debug then warn("[Core Loop]", flag, err) end
            local w = type(delay) == "string" and Cfg[delay] or delay
            task.wait(math.max(tonumber(w) or 0.1, 0.05))
        end
        ActiveThreads[flag] = nil
    end)
end

-- Webhook
local function sendWebhook(title, description, fields, color)
    if not Cfg.Webhook or Cfg.WebhookUrl == "" then return end
    local req = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not req then return end
    task.spawn(function()
        pcall(function()
            req({
                Url = Cfg.WebhookUrl, Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({ embeds = { {
                    title = title, description = description, color = color or 0xFF2442,
                    fields = fields or {}, timestamp = DateTime.now():ToIsoDate(),
                } } }),
            })
        end)
    end)
end

-- Rarity
local RARITY_RANK = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5,
                      Mythic = 6, Eternal = 7, Secret = 8, Ancient = 9, Infinite = 10 }
local RANK_NAME = {}
for n, r in pairs(RARITY_RANK) do RANK_NAME[r] = n end
local RARITY_ORDER = { "Infinite", "Ancient", "Secret", "Eternal", "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common" }

local function cleanRarityText(txt)
    if type(txt) ~= "string" then return "Common" end
    local l = txt:lower()
    for _, n in ipairs(RARITY_ORDER) do
        if l:find(n:lower(), 1, true) then return n end
    end
    return "Common"
end

local function isStone(item)
    return item.Type == "EnchStone" or (item.ID and tostring(item.ID):find("Stone") ~= nil)
end

local function getItemRarityLevel(item)
    if type(item) ~= "table" then return 1 end
    local rarity
    pcall(function()
        if item.Type == "Weapon" and WeaponHelper then rarity = WeaponHelper.GetRarity(item.ID)
        elseif (item.Type == "Armor" or item.Type == "Hat") and ArmorHelper then rarity = ArmorHelper.GetRarity(item.ID)
        elseif item.Type == "Ore" and OreHelper then rarity = OreHelper.GetRarity(item.ID)
        elseif isStone(item) and EnchStoneHelper then rarity = EnchStoneHelper.GetRarity(item.ID) end
    end)
    rarity = rarity or item.Rarity
    if not rarity and item.ID then rarity = cleanRarityText(tostring(item.ID)) end
    local lvl = 1
    if rarity and RarityHelper and RarityHelper.GetRarityLevel then
        pcall(function() lvl = RarityHelper.GetRarityLevel(rarity) or lvl end)
    elseif rarity and RARITY_RANK[cleanRarityText(tostring(rarity))] then
        lvl = RARITY_RANK[cleanRarityText(tostring(rarity))]
    end
    return lvl
end

local function effectiveDPS(item)
    if type(item) ~= "table" or item.ID == nil then return 0 end
    local slot, id = item.Type or "Weapon", item.ID
    local baseTrain, usePower = 1, 1
    pcall(function()
        local cfg
        if slot == "Weapon" and WeaponHelper then cfg = WeaponHelper.GetConfig(id)
        elseif (slot == "Armor" or slot == "Hat") and ArmorHelper then cfg = ArmorHelper.GetConfig(id) end
        if cfg then
            baseTrain = tonumber(cfg.Train or cfg.BaseWeight) or 1
            usePower  = tonumber(cfg.UsePower) or 1
        end
    end)
    local enhBoost = 0
    pcall(function()
        enhBoost = EnhantHelper and EnhantHelper.GetBoost(tonumber(item.EnchanceNum or item.EnhanceNum) or 0) or 0
    end)
    local critRate, critDmg, interval = 0, 1.0, 0.5
    pcall(function()
        if EnchStoneHelper and type(item.EnchanceList) == "table" then
            for _, stoneId in ipairs(item.EnchanceList) do
                local sc = EnchStoneHelper.GetStoneConfig(stoneId)
                if sc then
                    critRate += tonumber(sc.BoomPercent) or 0
                    critDmg  += tonumber(sc.BoomValue) or 0
                    if sc.DamageInterval and tonumber(sc.DamageInterval) < interval then interval = tonumber(sc.DamageInterval) end
                end
            end
        end
    end)
    local affix = 1.0
    if type(item.MainAffix) == "table" then affix += (tonumber(item.MainAffix.Number) or 0) * 0.05 end
    if type(item.Affix) == "table" then
        for _, sub in ipairs(item.Affix) do
            if type(sub) == "table" and sub.Number then affix += (tonumber(sub.Number) or 0) * 0.03 end
        end
    end
    return (baseTrain * usePower * (1 + enhBoost) * affix) * (1 + critRate * critDmg) * (1 / math.max(interval, 0.1))
end

local function gearScore(item)
    if Cfg.UseDPSSolver then return effectiveDPS(item) end
    if type(item) ~= "table" or item.ID == nil then return 0 end
    local design = 0
    local helper = item.Type == "Weapon" and WeaponHelper or ArmorHelper
    if helper and helper.GetDesignPower then pcall(function() design = tonumber(helper.GetDesignPower(item.ID)) or 0 end) end
    local affix = type(item.MainAffix) == "table" and tonumber(item.MainAffix.Number) or 0
    local enh = tonumber(item.EnchanceNum or item.EnhanceNum) or 0
    return getItemRarityLevel(item) * 1e9 + design * 1e5 + affix + enh * 10
end

-- Equip / Forge / Enchant
local function equipBestGear(targetType)
    local items, remote = getBackpackItems(), getRemote("Backpack", "TryEquipItemRE")
    if not items or not remote then return false, 0 end
    local slots = (targetType == "Weapon" or targetType == "Armor" or targetType == "Hat")
        and { targetType } or { "Weapon", "Armor", "Hat" }
    local equipped, top = 0, 0
    for _, slot in ipairs(slots) do
        local bestUuid, bestScore = nil, -1
        for uuid, item in pairs(items) do
            if type(item) == "table" and item.Type == slot then
                local s = gearScore(item)
                if s > bestScore then bestUuid, bestScore = uuid, s end
            end
        end
        if bestUuid and pcall(function() remote:FireServer(bestUuid, slot) end) then
            equipped += 1; top = math.max(top, bestScore)
        end
    end
    return equipped > 0, equipped, top
end

local forgeCycleIndex = 1
local function forgeNow(forgeType, minOres)
    local items, remote = getBackpackItems(), getRemote("Forge", "ForgeRF")
    if not items or not remote or not remote:IsA("RemoteFunction") then return false, "Forge data/remote unavailable" end

    forgeType = forgeType or Cfg.ForgeType
    minOres = math.max(4, math.floor(tonumber(minOres or Cfg.MinOreToForge) or 4))

    local total, entries = 0, {}
    for uuid, item in pairs(items) do
        if type(item) == "table" and item.Type == "Ore" then
            local count = math.max(1, math.floor(tonumber(item.Number) or 1))
            local power = 0
            if OreHelper and OreHelper.GetPower then pcall(function() power = tonumber(OreHelper.GetPower(item.ID)) or 0 end) end
            total += count
            entries[#entries + 1] = { UUID = uuid, Count = count, Power = power }
        end
    end
    if total < 4 then return false, "Need at least 4 ores" end

    local rotating = forgeType == "All"
    local slot = forgeType
    if rotating then
        local rot = { "Weapon", "Armor", "Hat" }
        slot = rot[((forgeCycleIndex - 1) % #rot) + 1]
    end
    if slot ~= "Weapon" and slot ~= "Armor" and slot ~= "Hat" then slot = "Weapon" end

    local target
    if slot == "Weapon" then target = math.clamp(minOres, 4, 13)
    elseif slot == "Hat" then target = minOres >= 16 and 16 or 4
    elseif minOres >= 20 and total >= 23 then target = 23
    elseif minOres >= 11 and total >= 11 then target = 11
    elseif minOres >= 8 and total >= 8 then target = 8
    elseif rotating then slot, target = "Hat", 4
    else return false, "Armor forging needs 8, 11, or 23 ores" end
    if total < target then return false, ("Need %d ores for %s"):format(target, slot) end

    if Cfg.OreQualityMode == "High" then table.sort(entries, function(a, b) return a.Power > b.Power end)
    elseif Cfg.OreQualityMode == "Low" then table.sort(entries, function(a, b) return a.Power < b.Power end) end

    local uuidList, selected = {}, 0
    for _, ore in ipairs(entries) do
        local take = math.min(ore.Count, target - selected)
        if take > 0 then uuidList[ore.UUID] = take; selected += take end
        if selected >= target then break end
    end
    if selected < target then return false, "Could not select enough ores" end

    local ok, result = pcall(function()
        return remote:InvokeServer({ ConfigType = slot == "Weapon" and "Weapon" or "Armor", UUIDList = uuidList })
    end)
    if not ok or result == false then return false, "Forge request failed" end
    if rotating then forgeCycleIndex = slot == "Hat" and 1 or (forgeCycleIndex % 3) + 1 end
    task.delay(0.25, function() equipBestGear(slot) end)
    return true, slot, selected
end

local function autoEnchantEquipped()
    local bp = getBackpackItems()
    if not bp then return false, 0 end
    local maxRank = Cfg.EnchantMaxGrade == "All" and 99 or (RARITY_RANK[Cfg.EnchantMaxGrade] or 6)
    local stones = {}
    for uuid, item in pairs(bp) do
        if type(item) == "table" and isStone(item) then
            local rank = getItemRarityLevel(item)
            if not (Cfg.EnchantKeepHighGrade and rank >= 7) and rank <= maxRank then
                for _ = 1, tonumber(item.Number or item.Count) or 1 do
                    stones[#stones + 1] = { UUID = uuid, Rank = rank }
                end
            end
        end
    end
    if #stones == 0 then return false, 0 end
    table.sort(stones, function(a, b) return a.Rank < b.Rank end)

    local slots = (Cfg.EnchantSlots == "Weapon" or Cfg.EnchantSlots == "Armor" or Cfg.EnchantSlots == "Hat")
        and { Cfg.EnchantSlots } or { "Weapon", "Armor", "Hat" }
    local enchantRE = getRemote("Backpack", "EnchantRE")
    local idx, done = 1, 0

    for uuid, item in pairs(bp) do
        if type(item) == "table" and isEquipped(uuid) and table.find(slots, item.Type) then
            local maxSlots = tonumber(item.EnchanceNum or item.EnhanceNum) or 0
            local used = 0
            for _, s in ipairs(item.EnchanceList or {}) do
                if type(s) == "table" and (s.ID or s.id or s.Name) then used += 1 end
            end
            local empty = maxSlots - used
            while empty > 0 and idx <= #stones do
                local stone = stones[idx]; idx += 1
                local fired = false
                pcall(function()
                    if BackpackData and BackpackData.EnchantEquipment then
                        BackpackData.EnchantEquipment(uuid, stone.UUID); fired = true
                    elseif enchantRE then
                        enchantRE:FireServer(uuid, stone.UUID); fired = true
                    end
                end)
                if fired then done += 1; empty -= 1; task.wait(0.2) end
            end
        end
        if idx > #stones then break end
    end
    return done > 0, done
end

local function gearSolver()
    local ok, count, score = equipBestGear("All")
    pcall(autoEnchantEquipped)
    return ok, count, score
end

-- Sell
local function hasEquippedArmor()
    local bp = getBackpackItems()
    if not bp then return false end
    for uuid, item in pairs(bp) do
        if type(item) == "table" and item.Type == "Armor" and isEquipped(uuid) then return true end
    end
    return false
end

local function sellTrashGear()
    local bp = getBackpackItems()
    if not bp then return 0 end
    if Cfg.AutoEquipBest then pcall(equipBestGear, "All"); task.wait(0.08) end

    local keep = RARITY_RANK[Cfg.MinGearRarityToKeep] or 5
    local armorOn = hasEquippedArmor()
    local pool = {}
    for uuid, item in pairs(bp) do
        if type(item) == "table" and (item.Type == "Weapon" or item.Type == "Armor" or item.Type == "Hat") and not isEquipped(uuid) then
            if item.Type == "Armor" and not armorOn then
                pcall(equipBestGear, "Armor"); armorOn = true
            else
                pool[#pool + 1] = { uuid = uuid, score = gearScore(item), rarity = getItemRarityLevel(item) }
            end
        end
    end
    table.sort(pool, function(a, b) return a.score > b.score end)
    local protected = {}
    for i = 1, math.min(7, #pool) do protected[pool[i].uuid] = true end

    local sold = 0
    for _, g in ipairs(pool) do
        if not protected[g.uuid] and g.rarity < keep then
            call("Backpack", "TrySellItemRE", g.uuid, 1)
            sold += 1; task.wait(0.02)
        end
    end
    return sold
end

local function sellOres()
    local bp = getBackpackItems()
    if not bp then return 0 end
    local kept = {}
    for _, s in ipairs(Cfg.OreRaritiesToKeep) do kept[cleanRarityText(s)] = true end
    local minKeep, sold = tonumber(Cfg.KeepMinOreAmount) or 0, 0
    for uuid, item in pairs(bp) do
        if type(item) == "table" and item.Type == "Ore" then
            local name = RANK_NAME[getItemRarityLevel(item)] or "Common"
            if not kept[name] then
                local cur = tonumber(item.Number or item.Count) or 1
                local qty = minKeep > 0 and (cur - minKeep) or cur
                if qty > 0 then call("Backpack", "TrySellItemRE", uuid, qty); sold += qty; task.wait(0.02) end
            end
        end
    end
    return sold
end

local function sellEnchantStones()
    local bp = getBackpackItems()
    if not bp then return 0 end
    local targets = {}
    for _, s in ipairs(Cfg.EnchantRaritiesToTarget) do targets[cleanRarityText(s)] = true end
    local sellSelected = not Cfg.EnchantFilterMode or Cfg.EnchantFilterMode:find("Sell") ~= nil
    local minKeep, sold = tonumber(Cfg.KeepMinStoneAmount) or 0, 0
    for uuid, item in pairs(bp) do
        if type(item) == "table" and isStone(item) then
            local name = RANK_NAME[getItemRarityLevel(item)] or "Common"
            local should = sellSelected == (targets[name] == true)
            if should then
                local cur = tonumber(item.Number or item.Count) or 1
                local qty = minKeep > 0 and (cur - minKeep) or cur
                if qty > 0 then call("Backpack", "TrySellItemRE", uuid, qty); sold += qty; task.wait(0.02) end
            end
        end
    end
    return sold
end

local function equipBestPet()
    local bp = getBackpackItems()
    if not bp then return end
    local bestUuid, bestPower = nil, -1
    local PetHelper = tryRequire({ "Config", "Pet", "Helper" })
    for uuid, item in pairs(bp) do
        if type(item) == "table" and item.ID then
            local id = tostring(item.ID):lower()
            if item.Type == "Pet" or id:find("pet") or id:find("animal") then
                local power = 0
                pcall(function()
                    power = tonumber(PetHelper and PetHelper.GetPower and PetHelper.GetPower(item.ID))
                        or tonumber(PetHelper and PetHelper.GetDamage and PetHelper.GetDamage(item.ID)) or 0
                end)
                if power == 0 then
                    power = getItemRarityLevel(item) * 1e5 + (tonumber(item.Level) or 0) * 100
                        + (tonumber(item.EnchanceNum or item.EnhanceNum) or 0)
                end
                if power > bestPower then bestUuid, bestPower = uuid, power end
            end
        end
    end
    if bestUuid then
        call("Pet", "TryEquipPetRE", bestUuid)
        call("Backpack", "TryEquipPetRE", bestUuid)
        call("Pet", "EquipPetRE", bestUuid)
        call("Egg", "EquipPetRE", bestUuid)
    end
end

-- Loot
local function runDropMagnet()
    local oreCache = workspace:FindFirstChild("OreCache")
    if not oreCache then return end
    local targetCF
    if Cfg.MagnetTarget == "Safe Zone" then targetCF = getSafeZoneCF() + Vector3.new(0, 2, 0)
    else local r = hrp(); if not r then return end; targetCF = r.CFrame end
    for _, drop in ipairs(oreCache:GetChildren()) do
        if drop:IsA("Model") then
            pcall(function()
                if drop.PrimaryPart then
                    drop.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
                    drop.PrimaryPart.AssemblyAngularVelocity = Vector3.zero
                    drop.PrimaryPart.CanCollide = false
                end
                drop:PivotTo(targetCF)
            end)
        end
    end
end

local notifiedDrops = {}
local RARE_KEYS = { "Mythic", "Eternal", "Secret", "Ancient", "Infinite" }
local function runUltraPrompts()
    if not fireproximityprompt then return end
    local oreCache = workspace:FindFirstChild("OreCache")
    if not oreCache then return end
    local prompts = {}
    for _, p in ipairs(oreCache:GetDescendants()) do
        if p:IsA("ProximityPrompt") and p.Enabled then prompts[#prompts + 1] = p end
    end
    if Cfg.NotifyRareDrops and Cfg.Webhook then
        for _, drop in ipairs(oreCache:GetChildren()) do
            if drop:IsA("Model") and not notifiedDrops[drop] and drop:FindFirstChildOfClass("Highlight") then
                for _, k in ipairs(RARE_KEYS) do
                    if drop.Name:find(k) then
                        notifiedDrops[drop] = true
                        sendWebhook("Rare Item Acquired", "A rare drop was generated.", {
                            { name = "Drop", value = drop.Name, inline = true },
                            { name = "Activity", value = tostring(Stats.CurrentActivity), inline = true },
                        }, 0xF59E0B)
                        break
                    end
                end
            end
        end
    end
    for _, p in ipairs(prompts) do
        pcall(function()
            p.MaxActivationDistance = 1e6
            p.RequiresLineOfSight = false
            p.HoldDuration = 0
            fireproximityprompt(p, 0)
            Stats.OresCollected += 1
        end)
    end
end

local lastEvacuation = 0
local function checkSafeEvacuate()
    local cur, maxNum = getPackInfo()
    local packPct = cur / math.max(maxNum, 1) * 100
    local h = hum()
    local hpPct = h and (h.Health / math.max(h.MaxHealth, 1) * 100) or 100

    local reason
    if Cfg.AutoSafeEvacuate and packPct >= Cfg.EvacuateThreshold then reason = ("Pack Full (%d/%d)"):format(cur, maxNum)
    elseif Cfg.LowHPEvacuate and hpPct <= Cfg.LowHPThreshold then reason = ("Critical HP (%.1f%%)"):format(hpPct) end
    if not reason then return false end
    if os.clock() - lastEvacuation < 20 then return true end
    lastEvacuation = os.clock()
    Stats.CurrentActivity = "Evacuate: " .. reason
    call("Stage", "ClaimedAllOreRE")
    tpTo(getSafeZoneCF())
    task.wait(0.3)
    call("Backpack", "TrySellAllRE"); Stats.SellCycles += 1
    task.wait(0.2)
    call("Upgrade", "UpgradeOnceRE", "OrePack")
    task.wait(0.5)
    notify("Safe Zone Evacuate", reason)
    return true
end

-- Combat
local function getDungeonManagerEnv()
    local env, state
    pcall(function()
        local mgr = LocalPlayer.PlayerScripts:FindFirstChild("Manager")
        local dm = mgr and mgr:FindFirstChild("DungeonManager")
        if dm and getsenv then
            env = getsenv(dm)
            if env and debug and debug.getupvalues and env.CheckFinishedOnce then
                local up = debug.getupvalues(env.CheckFinishedOnce)
                if up and type(up[1]) == "table" then state = up[1] end
            end
        end
    end)
    return env, state
end

local function instantKillEnemy(enemy)
    if not enemy or not enemy:IsA("Model") then return end
    local uuid = enemy:GetAttribute("UUID") or enemy.Name
    pcall(function()
        local _, st = getDungeonManagerEnv()
        if st then st.DeadCF = enemy:GetPivot() end
    end)
    pcall(function()
        if EnemyHitBE then EnemyHitBE:Fire(uuid, 1e30) end
        if EnemyCTRL then
            if EnemyCTRL.HurtEnemy then EnemyCTRL.HurtEnemy(uuid, 1e30) end
            if EnemyCTRL.DeadEnemyData then EnemyCTRL.DeadEnemyData(uuid) end
        end
        if HPCTRL and HPCTRL.SetCurrentHP then HPCTRL.SetCurrentHP(enemy, 0) end
        enemy:SetAttribute("Dead", true)
        local h = enemy:FindFirstChildOfClass("Humanoid")
        if h then h.Health = 0 end
        Stats.Kills += 1
    end)
end

local function instantKillAll()
    local folder = workspace:FindFirstChild("EnemyFolder")
    if not folder then return 0 end
    local n = 0
    for _, e in ipairs(folder:GetChildren()) do
        if e:IsA("Model") and not e:GetAttribute("Dead") then instantKillEnemy(e); n += 1 end
    end
    return n
end

local function runKillAura()
    local be = EnemyHitBE or getBindable("Attack", "EnemyHitBE")
    local folder = workspace:FindFirstChild("EnemyFolder")
    if not be or not folder then return end
    for _, e in ipairs(folder:GetChildren()) do
        if e:IsA("Model") and not e:GetAttribute("Dead") then
            pcall(function() be:Fire(e.Name, 99999999, { SkillID = "K_Skill_1_ATK" }); Stats.Kills += 1 end)
        end
    end
    local sl = workspace:FindFirstChild("SuperLootFolder")
    if sl then
        for _, s in ipairs(sl:GetChildren()) do
            pcall(function() be:Fire(s.Name, 99999999, { SkillID = "K_Skill_1_ATK" }) end)
        end
    end
end

local function runSafeFlight()
    if not Cfg.SafeFlight then return end
    local r, folder = hrp(), workspace:FindFirstChild("EnemyFolder")
    if not r or not folder then return end
    local first = folder:GetChildren()[1]
    if first and first:IsA("Model") and first.PrimaryPart then
        local p = first.PrimaryPart.Position
        r.AssemblyLinearVelocity = Vector3.zero
        r.CFrame = CFrame.new(p.X, p.Y + Cfg.FlightHeight, p.Z)
    end
end

local function maintainGodMode()
    if not Cfg.GodMode then return end
    pcall(function()
        LocalPlayer:SetAttribute("Invincible", true)
        if HPCTRL then HPCTRL.SetCurrentHP(LocalPlayer, HPCTRL.GetMaxHP(LocalPlayer)) end
    end)
end

-- Super Loot hunter
local hunted = {}
local function checkSuperLootHunter()
    local sl = workspace:FindFirstChild("SuperLootFolder")
    if not sl or #sl:GetChildren() == 0 then return end
    for _, v in ipairs(sl:GetChildren()) do
        local tier = v.Name
        if Cfg.SuperLootTier == "All" or Cfg.SuperLootTier == tier then
            local target
            local folder = workspace:FindFirstChild("EnemyFolder")
            if folder then
                for _, e in ipairs(folder:GetChildren()) do
                    local id = e:GetAttribute("EnemyID")
                    if id and tostring(id):find("Super") then target = e; break end
                end
            end
            if target and target.PrimaryPart and not hunted[target] then
                Stats.CurrentActivity = "Super Loot: " .. tier
                notify("Super Loot Hunter", tier)
                if Cfg.NotifySuperLoot then
                    sendWebhook("Super Loot Target Engaged", "Boss intercepted.", {
                        { name = "Tier", value = tier, inline = true },
                        { name = "Position", value = tostring(target.PrimaryPart.Position), inline = true },
                    }, 0xEF4444)
                end
                tpTo(target.PrimaryPart.CFrame + Vector3.new(0, 8, 0))
                task.wait(0.2)
                runKillAura()
                call("SuperLoot", "KillSuperLootRE", target.Name)
                Stats.SuperLootKills += 1
                hunted[target] = true
                task.wait(0.5)
                runDropMagnet(); runUltraPrompts()
                break
            end
        end
    end
end

-- Stages list
local Stages = {}
pcall(function()
    local sh = require(ReplicatedStorage.Config.Stage.Helper)
    for k in pairs(sh.GetStageEnemyConfig()) do Stages[#Stages + 1] = k end
    table.sort(Stages, function(a, b) return (tonumber(a:match("%d+")) or 0) < (tonumber(b:match("%d+")) or 0) end)
end)
if #Stages == 0 then for i = 1, 30 do Stages[i] = "Stage_" .. i end end

local Potions = {}
pcall(function()
    for k in pairs(require(ReplicatedStorage.Config.Potion.Helper).GetConfig()) do Potions[#Potions + 1] = k end
end)
if #Potions == 0 then Potions = { "DamagePotion", "TrainPotion", "CoinPotion", "LuckPotion", "HPPotion" } end

local function getTargetStage()
    if Cfg.Stage == "Auto" or Cfg.Stage:find("Auto") then
        local maxPass = 0
        pcall(function()
            local pd = ProfileData.GetTotalData()
            maxPass = tonumber(pd.Stats.StagePass) or 0
        end)
        local n = math.clamp(maxPass + 1, 1, math.max(#Stages, 30))
        return "Stage_" .. n, n
    end
    local clean = Cfg.Stage:match("Stage_%d+") or Cfg.Stage
    return clean, tonumber(clean:match("%d+")) or 1
end

-- Train zones
local TrainZones = {
    { Id = 1, Rebirth = 0,  Mult = 1.5, PadPos = Vector3.new(-53.0, 3.0, -41.0),    DummyPos = Vector3.new(-57.88, 6.94, -41.04) },
    { Id = 2, Rebirth = 2,  Mult = 2,   PadPos = Vector3.new(-53.0, 3.0, -20.9),    DummyPos = Vector3.new(-57.88, 6.94, -20.91) },
    { Id = 3, Rebirth = 5,  Mult = 4,   PadPos = Vector3.new(-53.0, 3.0, 21.4),     DummyPos = Vector3.new(-57.88, 6.94, 21.37) },
    { Id = 4, Rebirth = 9,  Mult = 6,   PadPos = Vector3.new(-53.0, 3.0, 43.25),    DummyPos = Vector3.new(-57.88, 6.94, 43.25) },
    { Id = 5, Rebirth = 12, Mult = 8,   PadPos = Vector3.new(-80.0, 8.6, 21.29),    DummyPos = Vector3.new(-84.50, 8.61, 21.29) },
    { Id = 6, Rebirth = 15, Mult = 10,  PadPos = Vector3.new(-80.0, 9.1, -20.90),   DummyPos = Vector3.new(-83.92, 9.11, -20.90) },
    { Id = 7, Rebirth = 18, Mult = 15,  PadPos = Vector3.new(-108.0, 12.7, 32.24),  DummyPos = Vector3.new(-114.22, 12.73, 32.24) },
    { Id = 8, Rebirth = 21, Mult = 25,  PadPos = Vector3.new(-106.0, 10.6, -31.00), DummyPos = Vector3.new(-110.27, 10.63, -30.99) },
}

local function getRebirth()
    local reb = 0
    pcall(function()
        local eco = LocalPlayer:FindFirstChild("Eco")
        local rb = eco and (eco:FindFirstChild("rebirth") or eco:FindFirstChild("Rebirth"))
        if rb then reb = tonumber(rb.Value) or 0 end
    end)
    if reb == 0 then
        pcall(function()
            local pd = ProfileData.GetTotalData()
            reb = tonumber(pd.Eco.rebirth) or tonumber(pd.Eco.Rebirth) or 0
        end)
    end
    if reb == 0 then
        pcall(function() reb = tonumber(LocalPlayer:GetAttribute("Rebirth")) or tonumber(LocalPlayer:GetAttribute("rebirth")) or 0 end)
    end
    return reb
end

local function getBestTrainZone()
    local reb, best = getRebirth(), TrainZones[1]
    for _, z in ipairs(TrainZones) do
        if reb >= z.Rebirth and z.Mult >= best.Mult then best = z end
    end
    return best
end

local function getSelectedTrainZone()
    if Cfg.TrainZone == "Auto" then return getBestTrainZone() end
    for _, z in ipairs(TrainZones) do
        if tostring(z.Id) == tostring(Cfg.TrainZone) then return z end
    end
    return getBestTrainZone()
end

local function getTrainZonePart(id)
    local part
    pcall(function()
        local t = workspace:FindFirstChild("TOUCHED")
        local ata = t and t:FindFirstChild("AutoTrainArea")
        if ata then part = ata:FindFirstChild(tostring(id)) end
        if not part then
            local caf = workspace:FindFirstChild("CanAttackFolder")
            local ta = caf and caf:FindFirstChild("TrainArea")
            if ta then part = ta:FindFirstChild("Train_" .. id) or ta:FindFirstChild(tostring(id)) end
        end
    end)
    return part
end

local function getTrainCTRL()
    return TrainCTRL or tryRequire({ "CTRL", "TrainCTRL" })
end

local function trainOnce()
    local tc = getTrainCTRL()
    if tc and type(tc.TrainOnce) == "function" then pcall(tc.TrainOnce) else call("Train", "TrainOnceRE") end
end

local function enterTrainZone(zone)
    zone = zone or getSelectedTrainZone()
    if not zone then return end
    local r, h = hrp(), hum()
    if r and h and h.Health > 0 then
        local cur = r.Position
        if (Vector3.new(cur.X, zone.PadPos.Y, cur.Z) - zone.PadPos).Magnitude > 6 then
            r.CFrame = CFrame.lookAt(zone.PadPos + Vector3.new(0, 1.5, 0), zone.DummyPos)
            r.AssemblyLinearVelocity = Vector3.zero
            r.AssemblyAngularVelocity = Vector3.zero
            task.wait(0.1)
            local part = getTrainZonePart(zone.Id)
            if part and typeof(firetouchinterest) == "function" then
                pcall(function() firetouchinterest(r, part, 0); task.wait(0.02); firetouchinterest(r, part, 1) end)
            end
        end
    end
    if LocalPlayer:GetAttribute("AutoTrainAreaID") ~= zone.Id then
        call("Train", "IntoAutoTrainRE", zone.Id)
    end
    Stats.CurrentActivity = "Train zone " .. zone.Id
end

local function exitTrain()
    pcall(function()
        local tc = getTrainCTRL()
        if tc then
            if tc.GetIsAutoing and tc.GetIsAutoing() then tc.ExitAutoTrain() end
            if tc.GetIsTraining and tc.GetIsTraining() then tc.EndTrain() end
        end
        LocalPlayer:SetAttribute("AutoTrainAreaID", nil)
        call("Train", "ExitAutoTrainRE")
    end)
end

local lastSword = 0
local function runSwordClick()
    local now = os.clock()
    if now - lastSword < (tonumber(Cfg.SwordClickDelay) or 0.16) then return end
    lastSword = now
    trainOnce()
end

-- Dungeon / Stage
local function claimStageOres(stageId, stageFinishedRF, getOreRF, claimedAllRE)
    local ok, ores = pcall(function() return stageFinishedRF:InvokeServer(stageId) end)
    if ok and type(ores) == "table" then
        if getOreRF and getOreRF:IsA("RemoteFunction") then
            for oreUuid in pairs(ores) do
                Stats.OresCollected += 1
                pcall(function() getOreRF:InvokeServer(oreUuid) end)
            end
        end
        if claimedAllRE then pcall(function() claimedAllRE:FireServer() end) end
        Stats.LastStageClear = os.time()
        return true
    end
    return false
end

local function runDungeonLoop()
    if not Cfg.AutoDungeon then return end
    if checkSafeEvacuate() then return end

    if not LocalPlayer:GetAttribute("Dungeoning") then
        Stats.CurrentActivity = "Dungeon: enter round " .. Cfg.DungeonRound
        if Cfg.AutoClaimTicket then call("Dungeon", "TryClaimDailyDunTicRE") end
        local ok = call("Dungeon", "TryIntoDungeonRF", Cfg.DungeonRound)
        task.wait(0.8)
        if ok or LocalPlayer:GetAttribute("Dungeoning") then call("Dungeon", "StartRoundRE", Cfg.DungeonRound) end
        return
    end

    Stats.CurrentActivity = "Dungeon: wave"
    local env, st = getDungeonManagerEnv()
    if st and st.Round and st.Round >= 30 and st.Finished then
        if env and env.ExitDungeon then pcall(env.ExitDungeon) else call("Dungeon", "ExitDungeonRE") end
        task.wait(1.0)
        return
    end
    if Cfg.DungeonInstaKill and instantKillAll() > 0 then
        pcall(function() if env and env.CheckFinishedOnce then env.CheckFinishedOnce() end end)
    end
    runKillAura()
    if Cfg.DropMagnet then runDropMagnet() end
    if Cfg.UltraPrompt then runUltraPrompts() end
    runSafeFlight()
end

local function runStageLoop()
    if not Cfg.AutoStage then return end
    if LocalPlayer:GetAttribute("Dungeoning") then return end
    if checkSafeEvacuate() then return end

    local stageId = getTargetStage()
    Stats.CurrentActivity = "Stage: " .. stageId
    LocalPlayer:SetAttribute("StageID", stageId)

    local finished = getRemote("Stage", "StageFinishedRF")
    if finished and finished:IsA("RemoteFunction") then
        claimStageOres(stageId, finished, getRemote("Stage", "GetOreRF"), getRemote("Stage", "ClaimedAllOreRE"))
    end

    if LocalPlayer:GetAttribute("IntoFight") then
        if Cfg.StageInstaKill then instantKillAll() end
        runKillAura(); runSafeFlight()
    end
    if Cfg.DropMagnet then runDropMagnet() end
    if Cfg.UltraPrompt then runUltraPrompts() end

    if Cfg.AutoClimbStages and not Cfg.Stage:find("Auto") then
        local folder = workspace:FindFirstChild("EnemyFolder")
        local remaining = folder and #folder:GetChildren() or 0
        local idx = table.find(Stages, Cfg.Stage) or 1
        if remaining == 0 then
            if idx < #Stages then
                Cfg.Stage = Stages[idx + 1]; Stats.LastStageClear = os.time()
                notify("Stage Advance", Cfg.Stage); task.wait(0.5)
            end
        elseif os.time() - Stats.LastStageClear > Cfg.StageClimbTimeout and idx > 1 then
            Cfg.Stage = Stages[idx - 1]; Stats.LastStageClear = os.time()
            notify("Stage Retreat", Cfg.Stage)
            call("Stage", "ClaimedAllOreRE"); tpTo(getSafeZoneCF()); task.wait(0.8)
        end
    end
end

local blitzing = false
local function runStageBlitz()
    if blitzing or LocalPlayer:GetAttribute("Dungeoning") then return end
    if checkSafeEvacuate() then return end
    local finished = getRemote("Stage", "StageFinishedRF")
    if not (finished and finished:IsA("RemoteFunction")) then return end
    local getOre, claimAll = getRemote("Stage", "GetOreRF"), getRemote("Stage", "ClaimedAllOreRE")

    pcall(exitTrain)
    blitzing = true
    Stats.CurrentActivity = "Stage Blitz 1-30"
    task.spawn(function()
        local okAll, errAll = pcall(function()
            for i = 1, 30 do
                if not (Cfg.StageBlitz or (Cfg.Master and Cfg.MasterStageBlitz)) then break end
                if LocalPlayer:GetAttribute("Dungeoning") or checkSafeEvacuate() then break end
                claimStageOres("Stage_" .. i, finished, getOre, claimAll)

                if (Cfg.ConcurrentForge or (Cfg.Master and Cfg.MasterAutoForge)) and (i == 15 or i == 30) then
                    pcall(function()
                        local total = countOres() or 0
                        if total >= 8 then forgeNow("Armor", 8) elseif total >= 4 then forgeNow("Weapon", 4) end
                    end)
                end
                task.wait(Cfg.StageBlitzInterval or 0.09)
            end
        end)
        if not okAll and Cfg.Debug then warn("[Blitz]", errAll) end
        if Cfg.DropMagnet then pcall(runDropMagnet) end
        if Cfg.UltraPrompt then pcall(runUltraPrompts) end
        blitzing = false
    end)
end

-- Gacha / potions / claim
local function runClassAndSkillRoll()
    if Cfg.AutoRollClass then
        local current = "Class_1"
        pcall(function() current = require(ReplicatedStorage.LocalData.ClassData).GetEquipedClass() or "Class_1" end)
        if current ~= Cfg.TargetClass then
            Stats.CurrentActivity = "Roll class: " .. current
            call("Class", "LuckOnceRE", "1")
        else
            call("Class", "SetIndexLockRE", "1")
            call("Class", "ChangeEquipedIndexRE", "1")
            Cfg.AutoRollClass = false
            notify("Class Gacha", "Locked " .. current)
        end
    end
    if Cfg.AutoRollSkills then call("Backpack", "LuckSkillCell_2RE") end
end

local function runPotionAndHatch()
    if Cfg.AutoUsePotions then
        pcall(function()
            local BuffData = require(ReplicatedStorage.LocalData.BuffData)
            for _, pot in ipairs(Potions) do
                if not BuffData.IsHaveBuff(pot) then call("Potion", "TryUsePotionRE", pot); task.wait(0.1) end
            end
        end)
    end
    if Cfg.AutoHatchEggs then call("Egg", "PutEggRE") end
end

local function claimAllRewards()
    call("Offline", "TryClaimOfflineRewardRE")
    for i = 1, 12 do call("Online", "TryClaimRE", i); task.wait(0.05) end
    call("UpdateLog", "TryClaimUPDRewardRE")
    call("Dungeon", "TryClaimDailyDunTicRE")
    call("EnhantEvent", "TryClaimQuestRE")
    call("Index", "TryClaimIndexExpRF")
    call("Index", "TryClaimLevelRewardRF")
end

local KnownCodes = { "RELEASE", "LOOT", "FORGE", "ENHANCE", "UPDATE1", "FREEGEMS", "LIKE1000" }
local function redeemCodes(list)
    for _, c in ipairs(list or KnownCodes) do call("Code", "TryUseCodeRF", c); task.wait(0.25) end
end

local function upgradeTick()
    if Cfg.UpgradeType == "All in One" then
        call("Upgrade", "UpgradeOnceRE", "Train")
        call("Upgrade", "UpgradeOnceRE", "OrePack")
        call("Upgrade", "UpgradeOnceRE", "Luck")
    else
        call("Upgrade", "UpgradeOnceRE", Cfg.UpgradeType)
    end
end

-- Master
local tick = { claim = 0, upgrade = 0, forge = 0, enchant = 0 }

local function runMaster()
    if not Cfg.Master then return end
    if checkSafeEvacuate() then task.wait(0.8); return end
    if Cfg.SuperLootHunter then pcall(checkSuperLootHunter) end

    local now = os.clock()
    if now - tick.claim >= 60 then
        tick.claim = now
        pcall(function()
            call("Offline", "TryClaimOfflineRewardRE")
            call("Dungeon", "TryClaimDailyDunTicRE")
            for i = 1, 12 do call("Online", "TryClaimRE", i) end
        end)
    end

    local hasTickets = false
    pcall(function()
        local t = BackpackData.GetItemDataByIDType("Dungeon_Ticket", "Material")
        hasTickets = t and (tonumber(t.Number) or 0) > 0
    end)

    if hasTickets and Cfg.MasterDungeonTicket then
        Cfg.AutoDungeon, Cfg.AutoStage, Cfg.AutoTrain = true, false, false
        pcall(runDungeonLoop)
    else
        Cfg.AutoDungeon, Cfg.AutoStage, Cfg.AutoTrain = false, true, false
        if Cfg.MasterStageBlitz or Cfg.StageBlitz then pcall(runStageBlitz) else pcall(runStageLoop) end
    end

    if Cfg.MasterAutoClickSword then pcall(runSwordClick) end

    if Cfg.MasterTrainWhenIdle and not LocalPlayer:GetAttribute("IntoFight") and not LocalPlayer:GetAttribute("Dungeoning") then
        if Cfg.AutoTrainZone then pcall(enterTrainZone) end
        if not blitzing then Stats.CurrentActivity = "Train" end
        trainOnce()
    end

    if Cfg.DropMagnet then pcall(runDropMagnet) end
    if Cfg.UltraPrompt then pcall(runUltraPrompts) end

    if Cfg.MasterAutoUpgrade and now - tick.upgrade >= 3 then
        tick.upgrade = now; pcall(upgradeTick)
    end

    if Cfg.MasterAutoForge and Cfg.AutoForge and now - tick.forge >= 2 then
        tick.forge = now
        pcall(function()
            if (countOres() or 0) >= Cfg.MinOreToForge then
                local ok = forgeNow(Cfg.ForgeType, Cfg.MinOreToForge)
                if ok then task.delay(0.3, function() pcall(equipBestGear, "All") end) end
            end
        end)
    end

    if Cfg.AutoEquipBest then pcall(equipBestGear, "All") end
    if Cfg.AutoEnchant and now - tick.enchant >= (Cfg.EnchantDelay or 2) then
        tick.enchant = now
        pcall(Cfg.UseDPSSolver and gearSolver or autoEnchantEquipped)
    end
    if Cfg.AutoRebirth then pcall(function() call("Rebirth", "TryRebirthRE"); Stats.RebirthCount += 1 end) end

    pcall(runPotionAndHatch)
    pcall(runClassAndSkillRoll)
end

-- Player utilities
local function applyAntiTrip(h)
    if not h then return end
    pcall(function()
        h.MaxSlopeAngle = 89
        h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    end)
end

local function applyCharacterStats(h)
    if not h then return end
    h.WalkSpeed = Cfg.WalkSpeed
    h.UseJumpPower = true
    h.JumpPower = Cfg.JumpPower
end

local function setCpuSaver(on)
    pcall(function()
        RunService:Set3dRenderingEnabled(not on)
        if setfpscap then setfpscap(on and 15 or 60) end
    end)
end

local conns = {}
local function connect(sig, fn) conns[#conns + 1] = sig:Connect(fn) end

connect(LocalPlayer.CharacterAdded, function(c)
    local h = c:WaitForChild("Humanoid", 8)
    applyCharacterStats(h)
    if Cfg.AntiTrip then applyAntiTrip(h) end
    if Cfg.GodMode then task.wait(0.5); maintainGodMode() end
end)

connect(UserInputService.JumpRequest, function()
    if Cfg.InfJump then local h = hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

connect(RunService.Stepped, function()
    if Cfg.Noclip and char() then
        for _, p in ipairs(char():GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
    if Cfg.GodMode then maintainGodMode() end
end)

connect(LocalPlayer.Idled, function()
    if Cfg.AntiAFK then VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end
end)

pcall(function()
    connect(game:GetService("GuiService").ErrorMessageChanged, function()
        if Cfg.AutoReconnect and (Cfg.Master or Cfg.AutoDungeon or Cfg.AutoStage) then
            task.wait(3)
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
            task.wait(3.5)
            pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
        end
    end)
end)

-- Public API loops
local LOOPS = {
    DropMagnet            = { "MagnetInterval", runDropMagnet },
    UltraPrompt           = { 0.15, runUltraPrompts },
    AutoDungeon           = { 0.5, runDungeonLoop },
    AutoStage             = { 0.5, runStageLoop },
    KillAura              = { "KillAuraDelay", runKillAura },
    AutoSell              = { "SellDelay", function() call("Backpack", "TrySellAllRE"); Stats.SellCycles += 1 end },
    AutoSellTrashGear     = { "SellDelay", function() sellTrashGear(); Stats.SellCycles += 1 end },
    AutoSellOres          = { "SellDelay", sellOres },
    AutoSellEnchantStones = { "SellDelay", sellEnchantStones },
    AutoEquipBestPet      = { "PetEquipDelay", equipBestPet },
    AutoTrain             = { "TrainDelay", function()
                                if Cfg.AutoTrainZone then pcall(enterTrainZone) end
                                trainOnce()
                            end },
    AutoUpgrade           = { "UpgradeDelay", upgradeTick },
    AutoRebirth           = { "RebirthDelay", function() call("Rebirth", "TryRebirthRE"); Stats.RebirthCount += 1 end },
    AutoForge             = { "ForgeDelay", function() forgeNow(Cfg.ForgeType, Cfg.MinOreToForge) end },
    AutoEquipBest         = { 3.0, function() equipBestGear("All") end },
    AutoEnhance           = { "EnhanceDelay", function() call("Backpack", "EnhantEquipmentRF") end },
    AutoEnchant           = { "EnchantDelay", autoEnchantEquipped },
    AutoRollClass         = { "RollClassDelay", runClassAndSkillRoll },
    AutoRollSkills        = { "RollSkillDelay", runClassAndSkillRoll },
    AutoUsePotions        = { "PotionDelay", runPotionAndHatch },
    AutoHatchEggs         = { "HatchEggDelay", runPotionAndHatch },
    AutoClaimRewards      = { "ClaimDelay", claimAllRewards },
    AutoClickSword        = { "SwordClickDelay", runSwordClick },
    RemoteOnlyTrain       = { "TrainDelay", function()
                                if not LocalPlayer:GetAttribute("IntoFight") and not LocalPlayer:GetAttribute("Dungeoning") then trainOnce() end
                            end },
}

function Hub.Set(flag, value)
    Cfg[flag] = value
    if flag == "Master" and value then startLoop("Master", 0.15, runMaster)
    elseif flag == "StageBlitz" and value then startLoop("StageBlitz", 0.5, runStageBlitz)
    elseif LOOPS[flag] and value then startLoop(flag, LOOPS[flag][1], LOOPS[flag][2])
    elseif flag == "NativeAutoTrain" then
        if value then call("Train", "IntoAutoTrainRE", (getSelectedTrainZone() or TrainZones[1]).Id) else call("Train", "ExitAutoTrainRE") end
    elseif flag == "NativeAutoRebirth" then call("Rebirth", "UpdateAutoRebirthRE", value)
    elseif flag == "AutoTrainZone" and value then task.spawn(function() pcall(enterTrainZone) end)
    elseif flag == "AutoTrainZone" and not value and not Cfg.AutoTrain then call("Train", "ExitAutoTrainRE")
    elseif flag == "AntiTrip" and value then applyAntiTrip(hum())
    elseif flag == "CpuSaver" then setCpuSaver(value)
    elseif flag == "WalkSpeed" or flag == "JumpPower" then applyCharacterStats(hum())
    end
end

function Hub.Stop()
    for flag, v in pairs(Cfg) do if type(v) == "boolean" and flag ~= "AntiAFK" then Cfg[flag] = false end end
    setCpuSaver(false)
end

Hub.ForgeOnce        = function() return forgeNow(Cfg.ForgeType, Cfg.MinOreToForge) end
Hub.EquipBest        = function() return equipBestGear("All") end
Hub.EnchantOnce      = autoEnchantEquipped
Hub.SellAll          = function() call("Backpack", "TrySellAllRE"); Stats.SellCycles += 1 end
Hub.SellTrashGear    = sellTrashGear
Hub.SellOres         = sellOres
Hub.SellStones       = sellEnchantStones
Hub.EquipBestPet     = equipBestPet
Hub.ClaimAll         = claimAllRewards
Hub.RedeemCodes      = redeemCodes
Hub.HuntSuperLoot    = checkSuperLootHunter
Hub.TeleportSafeZone = function() tpTo(getSafeZoneCF()) end
Hub.EnterTrainZone   = enterTrainZone
Hub.ExitTrain        = exitTrain
Hub.Stages, Hub.TrainZones, Hub.Potions = Stages, TrainZones, Potions

-- Live stats
local Live = { Kills = 0, Super = 0, OresGained = 0, LastOres = nil, StartRebirth = nil, Watched = {} }
Hub.Live = Live

local function watchFolder(name, onRemoved)
    local f = workspace:FindFirstChild(name)
    if f and Live.Watched[name] ~= f then
        Live.Watched[name] = f
        conns[#conns + 1] = f.ChildRemoved:Connect(onRemoved)
    end
end

task.spawn(function()
    while true do
        pcall(function()
            watchFolder("EnemyFolder", function(c) if c:IsA("Model") then Live.Kills += 1 end end)
            watchFolder("SuperLootFolder", function() Live.Super += 1 end)

            local ore = countOres()
            if ore then
                if Live.LastOres and ore > Live.LastOres then Live.OresGained += ore - Live.LastOres end
                Live.LastOres = ore
            end

            local reb = nil
            pcall(function() reb = tonumber(ProfileData.GetTotalData().Eco.rebirth) end)
            if reb and not Live.StartRebirth then Live.StartRebirth = reb end

            Stats.OresCollected, Stats.Kills, Stats.SuperLootKills = Live.OresGained, Live.Kills, Live.Super
            if reb and Live.StartRebirth then Stats.RebirthCount = math.max(reb - Live.StartRebirth, 0) end

            if Cfg.Webhook and Cfg.NotifyHourlyReport and os.time() - Stats.LastHourlyPost >= 3600 then
                Stats.LastHourlyPost = os.time()
                local e = os.time() - Stats.StartTime
                sendWebhook("Hourly Report", "Farming session status.", {
                    { name = "Elapsed", value = ("%02d:%02d:%02d"):format(e // 3600, (e % 3600) // 60, e % 60), inline = true },
                    { name = "Ores", value = tostring(Stats.OresCollected), inline = true },
                    { name = "Kills", value = tostring(Stats.Kills), inline = true },
                    { name = "Sales", value = tostring(Stats.SellCycles), inline = true },
                    { name = "Super Loot", value = tostring(Stats.SuperLootKills), inline = true },
                    { name = "Rebirths", value = tostring(Stats.RebirthCount), inline = true },
                    { name = "Activity", value = tostring(Stats.CurrentActivity), inline = false },
                })
            end
        end)
        task.wait(1)
    end
end)

return Hub
end)()  -- ═══ END ENGINE ═══

env.LootForgeCore = Hub

local Cfg, Stats = Hub.Cfg, Hub.Stats

-- ═══════════════════════════════════════════════════════════
-- [4] UI CONSTANTS
-- ═══════════════════════════════════════════════════════════
local BRAND   = "LootForge"
local VERSION = "v1.0.0"
local FOLDER  = "LootForgeUI"
local State   = { Alive = true, StartTime = os.clock() }

local function SafeNotify(title, content, duration, icon)
    pcall(function()
        WindUI:Notify({ Title = title, Content = content, Duration = duration or 3, Icon = icon or "lucide:info" })
    end)
end

local function Safe(fn, ...)
    if type(fn) ~= "function" then return end
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(fn, table.unpack(args, 1, args.n))
        if not ok then warn("[LootForge] callback error: " .. tostring(err)) end
    end)
end

local function TryCreate(fn)
    local ok, result = pcall(fn)
    if ok then return result end
    warn("[LootForge] UI element gagal: " .. tostring(result))
    return nil
end

local function FormatTime(seconds)
    return string.format("%02d:%02d:%02d", math.floor(seconds / 3600), math.floor(seconds / 60) % 60, math.floor(seconds % 60))
end

local function ShortNumber(n)
    n = tonumber(n) or 0
    if n >= 1e12 then return string.format("%.2fT", n / 1e12) end
    if n >= 1e9  then return string.format("%.2fB", n / 1e9)  end
    if n >= 1e6  then return string.format("%.1fM", n / 1e6)  end
    if n >= 1e3  then return string.format("%.0fK", n / 1e3)  end
    return tostring(math.floor(n))
end

-- Hook engine notify → WindUI
Hub.OnNotify = function(title, text) SafeNotify(title, text, 3, "lucide:gem") end

-- ═══════════════════════════════════════════════════════════
-- [5] ADAPTER
-- ═══════════════════════════════════════════════════════════
local TabIcons = {
    ["Loot"]     = "lucide:gem",
    ["Combat"]   = "lucide:sword",
    ["Train"]    = "lucide:dumbbell",
    ["Forge"]    = "lucide:hammer",
    ["Sell"]     = "lucide:coins",
    ["Player"]   = "lucide:user",
    ["Master"]   = "lucide:crown",
    ["Settings"] = "lucide:settings",
}

local function ToMap(list)
    local map = {}
    if type(list) ~= "table" then return map end
    for k, v in pairs(list) do
        if type(k) == "number" then
            local name = (type(v) == "table" and (v.Title or v.Name)) or v
            if name ~= nil then map[tostring(name)] = true end
        elseif v == true then map[tostring(k)] = true end
    end
    return map
end
local function MapSignature(map)
    local keys = {}
    for k in pairs(map) do table.insert(keys, k) end
    table.sort(keys)
    return table.concat(keys, "\1")
end
local function MapToList(map, ordered)
    local list, seen = {}, {}
    for _, v in ipairs(ordered or {}) do
        if map[v] then table.insert(list, v); seen[v] = true end
    end
    for k in pairs(map) do if not seen[k] then table.insert(list, k) end end
    return list
end

local Flags = {}
local function RegisterFlag(flag, getter, setter)
    if flag then Flags[flag] = { Get = getter, Set = setter } end
end

local function NewGroup(tab)
    local G = {}

    function G:AddDivider()
        TryCreate(function() return tab:Divider() end)
    end

    function G:AddParagraph(cfg)
        cfg = cfg or {}
        local title = tostring(cfg.Title or "Info")
        local body  = tostring(cfg.Text or "")
        local obj = {}
        local el = TryCreate(function() return tab:Paragraph({ Title = title, Desc = body }) end)
        function obj:Set(text)
            text = tostring(text or "")
            if text == body then return end
            body = text
            if el then
                if not pcall(function() el:SetDesc(text) end) then
                    pcall(function() el:SetTitle(title .. "\n" .. text) end)
                end
            end
        end
        return obj
    end

    function G:AddButton(cfg)
        cfg = cfg or {}
        local name = tostring(cfg.Name or "Button")
        local destructive = string.sub(name, 1, 6) == "Unload"
        TryCreate(function()
            return tab:Button({
                Title    = name,
                Icon     = destructive and "lucide:power" or nil,
                Variant  = destructive and "Destructive" or nil,
                Callback = function() Safe(cfg.Callback) end,
            })
        end)
        return {}
    end

    function G:AddToggle(cfg)
        cfg = cfg or {}
        local name = tostring(cfg.Name or "Toggle")
        local obj = { Value = cfg.Default == true }
        local el = TryCreate(function()
            return tab:Toggle({
                Title = name, Value = obj.Value, Default = obj.Value,
                Callback = function(v)
                    v = v and true or false
                    if v == obj.Value then return end
                    obj.Value = v
                    Safe(cfg.Callback, v)
                end,
            })
        end)
        function obj:SetValue(v)
            v = v and true or false
            if self.Value == v then return end
            self.Value = v
            if el then pcall(function() el:Set(v) end) end
            Safe(cfg.Callback, v)
        end
        obj.Set = obj.SetValue
        function obj:Get() return self.Value end
        RegisterFlag(cfg.Flag, function() return obj.Value end, function(v) obj:SetValue(v) end)
        return obj
    end

    function G:AddSlider(cfg)
        cfg = cfg or {}
        local name = tostring(cfg.Name or "Slider")
        local minV = tonumber(cfg.Min) or 0
        local maxV = tonumber(cfg.Max) or 100
        local defV = tonumber(cfg.Default) or minV
        local step = tonumber(cfg.Step)
        if not step then
            local integral = minV == math.floor(minV) and maxV == math.floor(maxV) and defV == math.floor(defV)
            step = integral and 1 or 0.1
        end
        local title = name
        if type(cfg.Suffix) == "string" then
            local unit = cfg.Suffix:gsub("^%s+", ""):gsub("%s+$", "")
            if unit ~= "" then title = name .. " (" .. unit .. ")" end
        end
        local obj = { Value = defV }
        local el = TryCreate(function()
            return tab:Slider({
                Title = title, Step = step,
                Value = { Min = minV, Max = maxV, Default = defV },
                Callback = function(v)
                    v = tonumber(v)
                    if v == nil or v == obj.Value then return end
                    obj.Value = v
                    Safe(cfg.Callback, v)
                end,
            })
        end)
        function obj:SetValue(v)
            v = tonumber(v)
            if v == nil then return end
            self.Value = v
            if el then pcall(function() el:Set(v) end) end
            Safe(cfg.Callback, v)
        end
        obj.Set = obj.SetValue
        function obj:Get() return self.Value end
        RegisterFlag(cfg.Flag, function() return obj.Value end, function(v) obj:SetValue(v) end)
        return obj
    end

    function G:AddDropdown(cfg)
        cfg = cfg or {}
        local name = tostring(cfg.Name or "Dropdown")
        local values = cfg.Options or {}
        local selected = cfg.Default
        if type(selected) == "number" then selected = values[selected] end
        if selected == nil then selected = values[1] end
        local obj = { Value = selected, Values = values }
        local el = TryCreate(function()
            return tab:Dropdown({
                Title = name, Values = values, Value = selected,
                Callback = function(v)
                    if type(v) == "table" then v = v.Title or v.Name or v[1] end
                    if v == nil or v == obj.Value then return end
                    obj.Value = v
                    Safe(cfg.Callback, v)
                end,
            })
        end)
        function obj:SetValue(v)
            self.Value = v
            if el and v ~= nil then pcall(function() el:Select(v) end) end
            Safe(cfg.Callback, v)
        end
        obj.Set = obj.SetValue
        function obj:Get() return self.Value end
        RegisterFlag(cfg.Flag, function() return obj.Value end, function(v) obj:SetValue(v) end)
        return obj
    end

    function G:AddMultiDropdown(cfg)
        cfg = cfg or {}
        local name = tostring(cfg.Name or "Multi Dropdown")
        local values = cfg.Options or {}
        local map = ToMap(cfg.Default or {})
        local obj = { Value = map, Values = values, _sig = MapSignature(map) }
        local el = TryCreate(function()
            return tab:Dropdown({
                Title = name, Values = values,
                Value = MapToList(map, values),
                Multi = true, AllowNone = true,
                Callback = function(list)
                    local newMap = ToMap(list)
                    local sig = MapSignature(newMap)
                    if sig == obj._sig then return end
                    obj._sig, obj.Value = sig, newMap
                    Safe(cfg.Callback, MapToList(newMap, values))
                end,
            })
        end)
        function obj:SetValue(list)
            local newMap = ToMap(list)
            self.Value, self._sig = newMap, MapSignature(newMap)
            if el then pcall(function() el:Select(MapToList(newMap, values)) end) end
            Safe(cfg.Callback, MapToList(newMap, values))
        end
        obj.Set = obj.SetValue
        function obj:Get() return MapToList(self.Value, values) end
        RegisterFlag(cfg.Flag, function() return MapToList(obj.Value, values) end, function(v) obj:SetValue(v) end)
        return obj
    end

    function G:AddInput(cfg)
        cfg = cfg or {}
        local name = tostring(cfg.Name or "Input")
        local obj = { Value = cfg.Default or "" }
        local el = TryCreate(function()
            return tab:Input({
                Title = name, Value = obj.Value,
                Placeholder = cfg.Placeholder or "",
                Callback = function(v)
                    if v == obj.Value then return end
                    obj.Value = tostring(v or "")
                    Safe(cfg.Callback, obj.Value)
                end,
            })
        end)
        function obj:SetValue(v)
            v = tostring(v or "")
            self.Value = v
            if el then pcall(function() el:Set(v) end) end
            Safe(cfg.Callback, v)
        end
        obj.Set = obj.SetValue
        function obj:Get() return self.Value end
        RegisterFlag(cfg.Flag, function() return obj.Value end, function(v) obj:SetValue(v) end)
        return obj
    end

    return G
end

-- Config save/load
local ConfigMemory = {}
local function ConfigPath(name)
    name = tostring(name or "default"):gsub('[%./\\:%*%?"<>|]', "")
    if name == "" then name = "default" end
    return FOLDER .. "/" .. name .. ".json", name
end
local function HasFiles()
    return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end
local ConfigLib = {}
function ConfigLib:Save(name)
    local data = {}
    for flag, handler in pairs(Flags) do
        local ok, value = pcall(handler.Get)
        if ok and value ~= nil then data[flag] = value end
    end
    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if not ok then return false end
    local path, clean = ConfigPath(name)
    if HasFiles() then
        if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder(FOLDER) then
            pcall(makefolder, FOLDER)
        end
        if pcall(writefile, path, encoded) then return true end
    end
    ConfigMemory[clean] = encoded
    return true
end
function ConfigLib:Load(name)
    local path, clean = ConfigPath(name)
    local encoded = ConfigMemory[clean]
    if HasFiles() then
        local ok, exists = pcall(isfile, path)
        if ok and exists then
            local ok2, contents = pcall(readfile, path)
            if ok2 then encoded = contents end
        end
    end
    if not encoded then return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(encoded) end)
    if not ok or type(data) ~= "table" then return false end
    for flag, value in pairs(data) do
        local h = Flags[flag]
        if h then pcall(h.Set, value) end
    end
    return true
end

-- ═══════════════════════════════════════════════════════════
-- [6] BUILD UI
-- ═══════════════════════════════════════════════════════════
local Window
local function InitUI()
    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local isMobile = viewport.X < 850

    pcall(function()
        WindUI:Gradient({
            ["0"]   = { Color = Color3.fromHex("#5c5291"), Transparency = 0.15 },
            ["50"]  = { Color = Color3.fromHex("#0096ff"), Transparency = 0.10 },
            ["100"] = { Color = Color3.fromHex("#18181b"), Transparency = 0 },
        }, { Rotation = 45 })
    end)

    Window = WindUI:CreateWindow({
        Title = BRAND, Icon = "lucide:gem", Author = "LootForge",
        Folder = FOLDER,
        Size = isMobile and UDim2.fromOffset(viewport.X * 0.95, viewport.Y * 0.95)
                      or  UDim2.fromOffset(860, 620),
        MinSize = Vector2.new(560, 420),
        MaxSize = Vector2.new(980, 800),
        ToggleKey = Enum.KeyCode.RightShift,
        Transparent = true, Theme = "Dark",
        Accent = Color3.fromRGB(145, 104, 255),
        Resizable = true,
        SideBarWidth = isMobile and 220 or 250,
        HasOutline = true,
        Background = "rbxassetid://137490169052447",
        BackgroundImageTransparency = 0.42,
        ScrollBarEnabled = true,
    })

    pcall(function()
        Window:Tag({ Title = "LOOTFORGE", Icon = "lucide:gem",    Color = Color3.fromHex("#FFD700"), Radius = 13 })
        Window:Tag({ Title = VERSION,    Icon = "lucide:sparkles", Color = Color3.fromHex("#30ff6a"), Radius = 6 })
        Window:Divider()
    end)

    -- ── Dashboard ──
    local TabDash = Window:Tab({ Title = "Dashboard", Icon = "lucide:layout-dashboard" })
    TabDash:Section({ Title = "Status Live" })
    local StatusPara = TabDash:Paragraph({ Title = "Memuat..." })
    TabDash:Section({ Title = "Quick Actions" })
    local quickGroup = NewGroup(TabDash)
    quickGroup:AddButton({
        Name = "Nyalakan Master AI",
        Callback = function()
            local h = Flags.Master
            if h then pcall(h.Set, true) end
            SafeNotify("Master", "Master AI ON", 2, "lucide:zap")
        end,
    })
    quickGroup:AddButton({
        Name = "Claim All Rewards",
        Callback = function() Hub.ClaimAll(); SafeNotify("Claim", "All claimed", 2, "lucide:gift") end,
    })
    quickGroup:AddButton({
        Name = "Teleport Safe Zone",
        Callback = function() Hub.TeleportSafeZone(); SafeNotify("TP", "Safe zone", 2, "lucide:map-pin") end,
    })
    quickGroup:AddButton({
        Name = "Forge Once",
        Callback = function()
            local ok, slot, n = Hub.ForgeOnce()
            SafeNotify("Forge", ok and ("Forged " .. tostring(slot) .. " (" .. tostring(n) .. ")") or "Gagal", 3, "lucide:hammer")
        end,
    })

    -- ── Master ──
    local TabMaster = Window:Tab({ Title = "Master", Icon = TabIcons["Master"] })
    TabMaster:Section({ Title = "Master AI" })
    local masterGroup = NewGroup(TabMaster)
    masterGroup:AddToggle({
        Name = "Master AI (urutan lengkap)", Default = Cfg.Master, Flag = "Master",
        Callback = function(v) Hub.Set("Master", v) end,
    })
    masterGroup:AddToggle({
        Name = "Dungeon Ticket dulu", Default = Cfg.MasterDungeonTicket, Flag = "MasterDungeonTicket",
        Callback = function(v) Cfg.MasterDungeonTicket = v end,
    })
    masterGroup:AddToggle({
        Name = "Stage Blitz di master", Default = Cfg.MasterStageBlitz, Flag = "MasterStageBlitz",
        Callback = function(v) Cfg.MasterStageBlitz = v end,
    })
    masterGroup:AddToggle({
        Name = "Train saat idle", Default = Cfg.MasterTrainWhenIdle, Flag = "MasterTrainWhenIdle",
        Callback = function(v) Cfg.MasterTrainWhenIdle = v end,
    })
    masterGroup:AddToggle({
        Name = "Auto click sword", Default = Cfg.MasterAutoClickSword, Flag = "MasterAutoClickSword",
        Callback = function(v) Cfg.MasterAutoClickSword = v end,
    })
    masterGroup:AddToggle({
        Name = "Auto upgrade", Default = Cfg.MasterAutoUpgrade, Flag = "MasterAutoUpgrade",
        Callback = function(v) Cfg.MasterAutoUpgrade = v end,
    })
    masterGroup:AddToggle({
        Name = "Auto forge", Default = Cfg.MasterAutoForge, Flag = "MasterAutoForge",
        Callback = function(v) Cfg.MasterAutoForge = v end,
    })

    -- ── Loot ──
    local TabLoot = Window:Tab({ Title = "Loot", Icon = TabIcons["Loot"] })
    local lootGroup = NewGroup(TabLoot)
    TabLoot:Section({ Title = "Magnet & Prompt" })
    lootGroup:AddToggle({
        Name = "Drop Magnet", Default = Cfg.DropMagnet, Flag = "DropMagnet",
        Callback = function(v) Hub.Set("DropMagnet", v) end,
    })
    lootGroup:AddDropdown({
        Name = "Magnet Target", Options = { "Safe Zone", "To Player" }, Default = Cfg.MagnetTarget, Flag = "MagnetTarget",
        Callback = function(v) Cfg.MagnetTarget = v end,
    })
    lootGroup:AddSlider({
        Name = "Magnet Interval", Min = 0.05, Max = 1, Default = Cfg.MagnetInterval, Suffix = "s", Flag = "MagnetInterval",
        Callback = function(v) Cfg.MagnetInterval = v end,
    })
    lootGroup:AddToggle({
        Name = "Ultra Prompt", Default = Cfg.UltraPrompt, Flag = "UltraPrompt",
        Callback = function(v) Hub.Set("UltraPrompt", v) end,
    })
    TabLoot:Section({ Title = "Evakuasi" })
    lootGroup:AddToggle({
        Name = "Auto Safe Evacuate", Default = Cfg.AutoSafeEvacuate, Flag = "AutoSafeEvacuate",
        Callback = function(v) Cfg.AutoSafeEvacuate = v end,
    })
    lootGroup:AddSlider({
        Name = "Evacuate Threshold", Min = 50, Max = 100, Default = Cfg.EvacuateThreshold, Suffix = "%", Flag = "EvacuateThreshold",
        Callback = function(v) Cfg.EvacuateThreshold = v end,
    })
    lootGroup:AddToggle({
        Name = "Low HP Evacuate", Default = Cfg.LowHPEvacuate, Flag = "LowHPEvacuate",
        Callback = function(v) Cfg.LowHPEvacuate = v end,
    })
    lootGroup:AddSlider({
        Name = "Low HP Threshold", Min = 5, Max = 80, Default = Cfg.LowHPThreshold, Suffix = "%", Flag = "LowHPThreshold",
        Callback = function(v) Cfg.LowHPThreshold = v end,
    })

    -- ── Combat ──
    local TabCombat = Window:Tab({ Title = "Combat", Icon = TabIcons["Combat"] })
    TabCombat:Section({ Title = "Dungeon" })
    local combatGroup = NewGroup(TabCombat)
    combatGroup:AddToggle({
        Name = "Auto Dungeon", Default = Cfg.AutoDungeon, Flag = "AutoDungeon",
        Callback = function(v) Hub.Set("AutoDungeon", v) end,
    })
    combatGroup:AddSlider({
        Name = "Dungeon Round", Min = 1, Max = 30, Default = Cfg.DungeonRound, Flag = "DungeonRound",
        Callback = function(v) Cfg.DungeonRound = math.floor(v) end,
    })
    combatGroup:AddToggle({
        Name = "Dungeon InstaKill", Default = Cfg.DungeonInstaKill, Flag = "DungeonInstaKill",
        Callback = function(v) Cfg.DungeonInstaKill = v end,
    })
    TabCombat:Section({ Title = "Stage" })
    combatGroup:AddToggle({
        Name = "Auto Stage", Default = Cfg.AutoStage, Flag = "AutoStage",
        Callback = function(v) Hub.Set("AutoStage", v) end,
    })
    local stageOptions = { "Auto" }
    for _, s in ipairs(Hub.Stages) do stageOptions[#stageOptions + 1] = s end
    combatGroup:AddDropdown({
        Name = "Stage Target", Options = stageOptions, Default = Cfg.Stage, Flag = "Stage",
        Callback = function(v) Cfg.Stage = v end,
    })
    combatGroup:AddToggle({
        Name = "Stage InstaKill", Default = Cfg.StageInstaKill, Flag = "StageInstaKill",
        Callback = function(v) Cfg.StageInstaKill = v end,
    })
    combatGroup:AddToggle({
        Name = "Auto Climb Stages", Default = Cfg.AutoClimbStages, Flag = "AutoClimbStages",
        Callback = function(v) Cfg.AutoClimbStages = v end,
    })
    combatGroup:AddSlider({
        Name = "Climb Timeout", Min = 5, Max = 120, Default = Cfg.StageClimbTimeout, Suffix = "s", Flag = "StageClimbTimeout",
        Callback = function(v) Cfg.StageClimbTimeout = v end,
    })
    TabCombat:Section({ Title = "Aura & Flight" })
    combatGroup:AddToggle({
        Name = "Kill Aura", Default = Cfg.KillAura, Flag = "KillAura",
        Callback = function(v) Hub.Set("KillAura", v) end,
    })
    combatGroup:AddSlider({
        Name = "Kill Aura Delay", Min = 0.05, Max = 2, Default = Cfg.KillAuraDelay, Suffix = "s", Flag = "KillAuraDelay",
        Callback = function(v) Cfg.KillAuraDelay = v end,
    })
    combatGroup:AddToggle({
        Name = "Safe Flight", Default = Cfg.SafeFlight, Flag = "SafeFlight",
        Callback = function(v) Cfg.SafeFlight = v end,
    })
    combatGroup:AddSlider({
        Name = "Flight Height", Min = 5, Max = 50, Default = Cfg.FlightHeight, Suffix = "studs", Flag = "FlightHeight",
        Callback = function(v) Cfg.FlightHeight = v end,
    })
    combatGroup:AddToggle({
        Name = "God Mode", Default = Cfg.GodMode, Flag = "GodMode",
        Callback = function(v) Cfg.GodMode = v end,
    })
    combatGroup:AddToggle({
        Name = "Stage Blitz", Default = Cfg.StageBlitz, Flag = "StageBlitz",
        Callback = function(v) Hub.Set("StageBlitz", v) end,
    })
    combatGroup:AddSlider({
        Name = "Blitz Interval", Min = 0.05, Max = 1, Default = Cfg.StageBlitzInterval, Suffix = "s", Flag = "StageBlitzInterval",
        Callback = function(v) Cfg.StageBlitzInterval = v end,
    })
    TabCombat:Section({ Title = "Super Loot" })
    combatGroup:AddToggle({
        Name = "Super Loot Hunter", Default = Cfg.SuperLootHunter, Flag = "SuperLootHunter",
        Callback = function(v) Cfg.SuperLootHunter = v end,
    })
    combatGroup:AddDropdown({
        Name = "Super Loot Tier", Options = { "All", "Tier1", "Tier2", "Tier3" }, Default = Cfg.SuperLootTier, Flag = "SuperLootTier",
        Callback = function(v) Cfg.SuperLootTier = v end,
    })

    -- ── Train ──
    local TabTrain = Window:Tab({ Title = "Train", Icon = TabIcons["Train"] })
    local trainGroup = NewGroup(TabTrain)
    TabTrain:Section({ Title = "Train Dasar" })
    trainGroup:AddToggle({
        Name = "Auto Train", Default = Cfg.AutoTrain, Flag = "AutoTrain",
        Callback = function(v) Hub.Set("AutoTrain", v) end,
    })
    trainGroup:AddSlider({
        Name = "Train Delay", Min = 0.05, Max = 2, Default = Cfg.TrainDelay, Suffix = "s", Flag = "TrainDelay",
        Callback = function(v) Cfg.TrainDelay = v end,
    })
    trainGroup:AddToggle({
        Name = "Auto Train Zone", Default = Cfg.AutoTrainZone, Flag = "AutoTrainZone",
        Callback = function(v) Hub.Set("AutoTrainZone", v) end,
    })
    local zoneOptions = { "Auto" }
    for _, z in ipairs(Hub.TrainZones) do zoneOptions[#zoneOptions + 1] = tostring(z.Id) end
    trainGroup:AddDropdown({
        Name = "Train Zone", Options = zoneOptions, Default = tostring(Cfg.TrainZone), Flag = "TrainZone",
        Callback = function(v) Cfg.TrainZone = v end,
    })
    trainGroup:AddToggle({
        Name = "Native Auto Train", Default = Cfg.NativeAutoTrain, Flag = "NativeAutoTrain",
        Callback = function(v) Hub.Set("NativeAutoTrain", v) end,
    })
    trainGroup:AddToggle({
        Name = "Remote Only Train", Default = Cfg.RemoteOnlyTrain, Flag = "RemoteOnlyTrain",
        Callback = function(v) Hub.Set("RemoteOnlyTrain", v) end,
    })
    TabTrain:Section({ Title = "Sword & Upgrade" })
    trainGroup:AddToggle({
        Name = "Auto Click Sword", Default = Cfg.AutoClickSword, Flag = "AutoClickSword",
        Callback = function(v) Hub.Set("AutoClickSword", v) end,
    })
    trainGroup:AddSlider({
        Name = "Sword Click Delay", Min = 0.05, Max = 1, Default = Cfg.SwordClickDelay, Suffix = "s", Flag = "SwordClickDelay",
        Callback = function(v) Cfg.SwordClickDelay = v end,
    })
    trainGroup:AddToggle({
        Name = "Auto Upgrade", Default = Cfg.AutoUpgrade, Flag = "AutoUpgrade",
        Callback = function(v) Hub.Set("AutoUpgrade", v) end,
    })
    trainGroup:AddDropdown({
        Name = "Upgrade Type", Options = { "All in One", "Train", "OrePack", "Luck" }, Default = Cfg.UpgradeType, Flag = "UpgradeType",
        Callback = function(v) Cfg.UpgradeType = v end,
    })
    trainGroup:AddSlider({
        Name = "Upgrade Delay", Min = 0.5, Max = 10, Default = Cfg.UpgradeDelay, Suffix = "s", Flag = "UpgradeDelay",
        Callback = function(v) Cfg.UpgradeDelay = v end,
    })
    trainGroup:AddToggle({
        Name = "Auto Rebirth", Default = Cfg.AutoRebirth, Flag = "AutoRebirth",
        Callback = function(v) Hub.Set("AutoRebirth", v) end,
    })
    trainGroup:AddSlider({
        Name = "Rebirth Delay", Min = 1, Max = 60, Default = Cfg.RebirthDelay, Suffix = "s", Flag = "RebirthDelay",
        Callback = function(v) Cfg.RebirthDelay = v end,
    })

    -- ── Forge ──
    local TabForge = Window:Tab({ Title = "Forge", Icon = TabIcons["Forge"] })
    local forgeGroup = NewGroup(TabForge)
    TabForge:Section({ Title = "Forge" })
    forgeGroup:AddToggle({
        Name = "Auto Forge", Default = Cfg.AutoForge, Flag = "AutoForge",
        Callback = function(v) Hub.Set("AutoForge", v) end,
    })
    forgeGroup:AddDropdown({
        Name = "Forge Type", Options = { "All", "Weapon", "Armor", "Hat" }, Default = Cfg.ForgeType, Flag = "ForgeType",
        Callback = function(v) Cfg.ForgeType = v end,
    })
    forgeGroup:AddSlider({
        Name = "Forge Delay", Min = 0.2, Max = 10, Default = Cfg.ForgeDelay, Suffix = "s", Flag = "ForgeDelay",
        Callback = function(v) Cfg.ForgeDelay = v end,
    })
    forgeGroup:AddSlider({
        Name = "Min Ore to Forge", Min = 4, Max = 30, Default = Cfg.MinOreToForge, Flag = "MinOreToForge",
        Callback = function(v) Cfg.MinOreToForge = math.floor(v) end,
    })
    forgeGroup:AddDropdown({
        Name = "Ore Quality Mode", Options = { "Any", "High", "Low" }, Default = Cfg.OreQualityMode, Flag = "OreQualityMode",
        Callback = function(v) Cfg.OreQualityMode = v end,
    })
    forgeGroup:AddButton({
        Name = "Forge Once",
        Callback = function()
            local ok, slot, n = Hub.ForgeOnce()
            SafeNotify("Forge", ok and ("Forged " .. tostring(slot) .. " (" .. tostring(n) .. " ores)") or "Gagal", 3, "lucide:hammer")
        end,
    })
    TabForge:Section({ Title = "Equipment" })
    forgeGroup:AddToggle({
        Name = "Auto Equip Best", Default = Cfg.AutoEquipBest, Flag = "AutoEquipBest",
        Callback = function(v) Hub.Set("AutoEquipBest", v) end,
    })
    forgeGroup:AddToggle({
        Name = "Gunakan DPS Solver", Default = Cfg.UseDPSSolver, Flag = "UseDPSSolver",
        Callback = function(v) Cfg.UseDPSSolver = v end,
    })
    forgeGroup:AddToggle({
        Name = "Auto Enchant", Default = Cfg.AutoEnchant, Flag = "AutoEnchant",
        Callback = function(v) Hub.Set("AutoEnchant", v) end,
    })
    forgeGroup:AddDropdown({
        Name = "Enchant Max Grade", Options = { "All", "Common", "Rare", "Epic", "Legendary", "Mythic", "Eternal" },
        Default = Cfg.EnchantMaxGrade, Flag = "EnchantMaxGrade",
        Callback = function(v) Cfg.EnchantMaxGrade = v end,
    })
    forgeGroup:AddDropdown({
        Name = "Enchant Slots", Options = { "All", "Weapon", "Armor", "Hat" }, Default = Cfg.EnchantSlots, Flag = "EnchantSlots",
        Callback = function(v) Cfg.EnchantSlots = v end,
    })
    forgeGroup:AddToggle({
        Name = "Enchant Keep High Grade", Default = Cfg.EnchantKeepHighGrade, Flag = "EnchantKeepHighGrade",
        Callback = function(v) Cfg.EnchantKeepHighGrade = v end,
    })
    forgeGroup:AddButton({
        Name = "Equip Best Sekarang",
        Callback = function()
            local ok, n = Hub.EquipBest()
            SafeNotify("Equip", ok and ("Equipped " .. n) or "Tidak ada item", 3, "lucide:shirt")
        end,
    })

    -- ── Sell ──
    local TabSell = Window:Tab({ Title = "Sell", Icon = TabIcons["Sell"] })
    local sellGroup = NewGroup(TabSell)
    TabSell:Section({ Title = "Auto Sell" })
    sellGroup:AddToggle({
        Name = "Auto Sell All", Default = Cfg.AutoSell, Flag = "AutoSell",
        Callback = function(v) Hub.Set("AutoSell", v) end,
    })
    sellGroup:AddSlider({
        Name = "Sell Delay", Min = 2, Max = 60, Default = Cfg.SellDelay, Suffix = "s", Flag = "SellDelay",
        Callback = function(v) Cfg.SellDelay = v end,
    })
    TabSell:Section({ Title = "Gear" })
    sellGroup:AddToggle({
        Name = "Auto Sell Trash Gear", Default = Cfg.AutoSellTrashGear, Flag = "AutoSellTrashGear",
        Callback = function(v) Hub.Set("AutoSellTrashGear", v) end,
    })
    sellGroup:AddDropdown({
        Name = "Min Rarity to Keep",
        Options = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Eternal", "Secret", "Ancient", "Infinite" },
        Default = Cfg.MinGearRarityToKeep, Flag = "MinGearRarityToKeep",
        Callback = function(v) Cfg.MinGearRarityToKeep = v end,
    })
    TabSell:Section({ Title = "Ore & Stone" })
    sellGroup:AddToggle({
        Name = "Auto Sell Ores", Default = Cfg.AutoSellOres, Flag = "AutoSellOres",
        Callback = function(v) Hub.Set("AutoSellOres", v) end,
    })
    sellGroup:AddMultiDropdown({
        Name = "Ore Rarity to Keep",
        Options = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Eternal", "Secret", "Ancient", "Infinite" },
        Default = Cfg.OreRaritiesToKeep, Flag = "OreRaritiesToKeep",
        Callback = function(list) Cfg.OreRaritiesToKeep = list end,
    })
    sellGroup:AddSlider({
        Name = "Keep Min Ore Amount", Min = 0, Max = 100, Default = Cfg.KeepMinOreAmount, Flag = "KeepMinOreAmount",
        Callback = function(v) Cfg.KeepMinOreAmount = math.floor(v) end,
    })
    sellGroup:AddToggle({
        Name = "Auto Sell Enchant Stones", Default = Cfg.AutoSellEnchantStones, Flag = "AutoSellEnchantStones",
        Callback = function(v) Hub.Set("AutoSellEnchantStones", v) end,
    })
    sellGroup:AddDropdown({
        Name = "Enchant Filter Mode", Options = { "Sell Selected", "Keep Selected" }, Default = Cfg.EnchantFilterMode, Flag = "EnchantFilterMode",
        Callback = function(v) Cfg.EnchantFilterMode = v end,
    })
    sellGroup:AddMultiDropdown({
        Name = "Enchant Rarities to Target",
        Options = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Eternal" },
        Default = Cfg.EnchantRaritiesToTarget, Flag = "EnchantRaritiesToTarget",
        Callback = function(list) Cfg.EnchantRaritiesToTarget = list end,
    })

    -- ── Player ──
    local TabPlayer = Window:Tab({ Title = "Player", Icon = TabIcons["Player"] })
    local playerGroup = NewGroup(TabPlayer)
    TabPlayer:Section({ Title = "Movement" })
    playerGroup:AddSlider({
        Name = "WalkSpeed", Min = 16, Max = 200, Default = Cfg.WalkSpeed, Flag = "WalkSpeed",
        Callback = function(v) Hub.Set("WalkSpeed", v) end,
    })
    playerGroup:AddSlider({
        Name = "JumpPower", Min = 50, Max = 300, Default = Cfg.JumpPower, Flag = "JumpPower",
        Callback = function(v) Hub.Set("JumpPower", v) end,
    })
    playerGroup:AddToggle({
        Name = "Infinite Jump", Default = Cfg.InfJump, Flag = "InfJump",
        Callback = function(v) Cfg.InfJump = v end,
    })
    playerGroup:AddToggle({
        Name = "Noclip", Default = Cfg.Noclip, Flag = "Noclip",
        Callback = function(v) Cfg.Noclip = v end,
    })
    TabPlayer:Section({ Title = "Utility" })
    playerGroup:AddToggle({
        Name = "Anti AFK", Default = Cfg.AntiAFK, Flag = "AntiAFK",
        Callback = function(v) Cfg.AntiAFK = v end,
    })
    playerGroup:AddToggle({
        Name = "Anti Trip", Default = Cfg.AntiTrip, Flag = "AntiTrip",
        Callback = function(v) Hub.Set("AntiTrip", v) end,
    })
    playerGroup:AddToggle({
        Name = "Auto Reconnect", Default = Cfg.AutoReconnect, Flag = "AutoReconnect",
        Callback = function(v) Cfg.AutoReconnect = v end,
    })
    playerGroup:AddToggle({
        Name = "CPU Saver", Default = Cfg.CpuSaver, Flag = "CpuSaver",
        Callback = function(v) Hub.Set("CpuSaver", v) end,
    })
    playerGroup:AddButton({
        Name = "Teleport Safe Zone",
        Callback = function() Hub.TeleportSafeZone(); SafeNotify("TP", "Safe zone", 2, "lucide:map-pin") end,
    })
    playerGroup:AddButton({
        Name = "Claim All Rewards",
        Callback = function() Hub.ClaimAll(); SafeNotify("Claim", "All claimed", 2, "lucide:gift") end,
    })

    -- ── Settings ──
    local TabSet = Window:Tab({ Title = "Settings", Icon = TabIcons["Settings"] })
    local setGroup = NewGroup(TabSet)
    TabSet:Section({ Title = "Debug" })
    setGroup:AddToggle({
        Name = "Debug Log", Default = Cfg.Debug, Flag = "Debug",
        Callback = function(v) Cfg.Debug = v end,
    })
    TabSet:Section({ Title = "Webhook" })
    setGroup:AddToggle({
        Name = "Aktifkan Webhook", Default = Cfg.Webhook, Flag = "Webhook",
        Callback = function(v) Cfg.Webhook = v end,
    })
    setGroup:AddInput({
        Name = "Webhook URL", Default = Cfg.WebhookUrl, Placeholder = "https://discord.com/api/webhooks/...", Flag = "WebhookUrl",
        Callback = function(v) Cfg.WebhookUrl = v end,
    })
    setGroup:AddToggle({
        Name = "Notify Rare Drops", Default = Cfg.NotifyRareDrops, Flag = "NotifyRareDrops",
        Callback = function(v) Cfg.NotifyRareDrops = v end,
    })
    setGroup:AddToggle({
        Name = "Notify Super Loot", Default = Cfg.NotifySuperLoot, Flag = "NotifySuperLoot",
        Callback = function(v) Cfg.NotifySuperLoot = v end,
    })
    setGroup:AddToggle({
        Name = "Notify Hourly Report", Default = Cfg.NotifyHourlyReport, Flag = "NotifyHourlyReport",
        Callback = function(v) Cfg.NotifyHourlyReport = v end,
    })
    TabSet:Section({ Title = "Config" })
    setGroup:AddButton({
        Name = "Save Config",
        Callback = function()
            if ConfigLib:Save("lootforge") then SafeNotify("Config", "Saved", 2, "lucide:check") end
        end,
    })
    setGroup:AddButton({
        Name = "Load Config",
        Callback = function()
            if ConfigLib:Load("lootforge") then SafeNotify("Config", "Loaded", 2, "lucide:check") end
        end,
    })
    setGroup:AddDivider()
    setGroup:AddButton({
        Name = "Unload LootForge",
        Callback = function()
            Hub.Stop()
            if Window and Window.Destroy then pcall(function() Window:Destroy() end) end
            env.LootForgeAllInOne = nil
            State.Alive = false
        end,
    })

    -- Live dashboard
    task.spawn(function()
        local lastText
        while State.Alive do
            local st = Stats
            local text = string.format(
                "Master: %s | Activity: %s\nOres: %s | Kills: %s | Sell Cycles: %s\nRebirths: %s | Super Loot: %s\nUptime: %s",
                Cfg.Master and "ON" or "OFF", tostring(st.CurrentActivity or "-"),
                ShortNumber(st.OresCollected or 0), ShortNumber(st.Kills or 0), ShortNumber(st.SellCycles or 0),
                ShortNumber(st.RebirthCount or 0), ShortNumber(st.SuperLootKills or 0),
                FormatTime(os.clock() - State.StartTime)
            )
            if text ~= lastText then
                lastText = text
                pcall(function() StatusPara:SetTitle(text) end)
            end
            task.wait(1)
        end
    end)

    SafeNotify(BRAND, "LootForge siap. Toggle: RightShift.", 3, "lucide:check")
    pcall(function()
        WindUI:Popup({
            Title = "Selamat Datang", Icon = "lucide:gem",
            Content = BRAND .. " " .. VERSION .. "\n\nTab: Master · Loot · Combat · Train · Forge · Sell · Player\n\nPeringatan: script ini adalah cheat. Risiko ban.",
            Buttons = {
                { Title = "Tutup", Variant = "Tertiary", Callback = function() end },
                { Title = "Nyalakan Master AI", Icon = "lucide:zap", Variant = "Primary",
                  Callback = function()
                      local h = Flags.Master
                      if h then pcall(h.Set, true) end
                  end },
            },
        })
    end)
end

task.spawn(function()
    local ok, err = pcall(InitUI)
    if not ok then
        warn("[LootForge] InitUI gagal: " .. tostring(err))
        SafeNotify("LootForge", "UI gagal dibuat: " .. tostring(err), 8, "lucide:alert-triangle")
        env.LootForgeAllInOne = nil
    end
end)

print("[LootForge] All-in-One " .. VERSION .. " loaded (RightShift)")