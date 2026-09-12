--[[
    🔱 TEAMMIZU × MIZUKAGE OFFICIAL — TURBO EDITION
    1_Dig_Into_Secrets — Max-Speed Feature Suite (Rayfield)
    ──────────────────────────────────────────────────────
    ⚡ TURBO MODE
        • RenderStepped-driven loops (fires every frame, ~60–240 Hz)
        • Batch-fire: N messages per frame
        • Per-message cooldown BYPASS in turbo
        • Global cap raised (configurable up to 200/s)
        • 0ms Train Mode — saturates MessageBusMaxPerSecond
    ──────────────────────────────────────────────────────
    Remote: game.ReplicatedStorage.Remotes.MessageBus
    Format: MessageBus:FireServer( msgName:string, payload:table? )
    ──────────────────────────────────────────────────────
]]

-- ══════════════════════════════════════════════════════════
-- §0  BOOTSTRAP
-- ══════════════════════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local LP = Players.LocalPlayer

local Remotes    = ReplicatedStorage:WaitForChild("Remotes", 15)
local MessageBus = Remotes and Remotes:WaitForChild("MessageBus", 10) or nil

if not MessageBus then
    Rayfield:Notify({ Title="Mizukage", Content="MessageBus not found.", Duration=8 })
    return
end

local MessageNames = {}
do
    local ok, mod = pcall(function()
        return require(ReplicatedStorage.Shared.Net.MessageNames)
    end)
    if ok and type(mod) == "table" then MessageNames = mod end
end

local function safeRequire(path)
    local node = ReplicatedStorage
    for _, seg in ipairs(path) do
        node = node:FindFirstChild(seg); if not node then return nil end
    end
    if node:IsA("ModuleScript") then
        local ok, res = pcall(require, node); if ok then return res end
    end
    return nil
end

local RebirthConfig  = safeRequire({"Shared","Config","RebirthConfig"})
local UpgradeConfig  = safeRequire({"Shared","Config","UpgradeConfig"})
local TrainConfig    = safeRequire({"Shared","Config","TrainConfig"})

-- ══════════════════════════════════════════════════════════
-- §1  CORE — Turbo MessageBus Engine
-- ══════════════════════════════════════════════════════════
local Core = {}
Core.__index = Core

-- Default budgets (tuned just under SecurityConfig.MessageBusMaxPerSecond = 80)
local CAP_SAFE   = 75
local CAP_TURBO  = 150
local CAP_INSANE = 200

function Core.new()
    local self = setmetatable({}, Core)

    self._lastFire = {}         -- per-msg last timestamp (classic mode)
    self._windowStart = os.clock()
    self._windowCount = 0
    self._globalMax = CAP_TURBO

    self._log = {}
    self._logSize = 120

    self._listeners = {}
    self._data = {}
    self._flags = {}

    self._loops = {}            -- task.wait-based loops
    self._turboConns = {}       -- RenderStepped/Heartbeat connections

    self._totalFired = 0
    self._fpsWindow = {}        -- [timestamp] = count

    return self
end

-- ── logging ──
function Core:log(dir, name, payload)
    table.insert(self._log, 1, { t=os.clock(), dir=dir, name=name, payload=payload })
    while #self._log > self._logSize do table.remove(self._log) end
end

-- ── budget ──
function Core:resetWindowIfNeeded()
    local now = os.clock()
    if now - self._windowStart >= 1 then
        self._windowStart = now
        self._windowCount = 0
        self._fpsWindow = {}
    end
end

function Core:hasBudget()
    self:resetWindowIfNeeded()
    return self._windowCount < self._globalMax
end

-- ── raw fire (bypasses per-msg throttle) ──
function Core:_fireRaw(msgName, payload)
    self._windowCount += 1
    self._totalFired += 1
    self._fpsWindow[self._windowCount] = true
    self:log("OUT", msgName, payload)
    local ok = pcall(function()
        if payload ~= nil then
            MessageBus:FireServer(msgName, payload)
        else
            MessageBus:FireServer(msgName)
        end
    end)
    if not ok then warn("[Mizukage] FireServer failed:", msgName) end
    return ok
end

-- ── classic fire (respects minInterval + global budget) ──
function Core:fire(msgName, payload, minInterval)
    if type(msgName) ~= "string" then return false end
    local now = os.clock()
    if minInterval and minInterval > 0 then
        local last = self._lastFire[msgName] or 0
        if now - last < minInterval then return false end
    end
    if not self:hasBudget() then return false end
    self._lastFire[msgName] = now
    return self:_fireRaw(msgName, payload)
end

-- ── turbo fire — NO throttle, only global budget ──
function Core:fireTurbo(msgName, payload)
    if not self:hasBudget() then return false end
    return self:_fireRaw(msgName, payload)
end

-- ── burst: fire up to N of msgName in one tick ──
function Core:burst(msgName, count, payload)
    local fired = 0
    for _ = 1, count do
        if not self:hasBudget() then break end
        self:_fireRaw(msgName, payload)
        fired += 1
    end
    return fired
end

-- ── rotate: fire a list of messages round-robin until budget dry ──
function Core:rotate(list, maxRounds, payloadForFn)
    local rounds, fired = 0, 0
    while rounds < maxRounds do
        local moved = false
        for i, entry in ipairs(list) do
            if not self:hasBudget() then return fired end
            local msg = type(entry) == "string" and entry or entry.msg
            local pl  = type(entry) == "table" and entry.payload or nil
            if payloadForFn then pl = payloadForFn(i, entry) end
            self:_fireRaw(msg, pl)
            fired += 1
            moved = true
        end
        rounds += 1
        if not moved then break end
    end
    return fired
end

-- ── listeners / dispatch ──
function Core:on(msgName, cb)
    self._listeners[msgName] = self._listeners[msgName] or {}
    table.insert(self._listeners[msgName], cb)
    return function()
        local list = self._listeners[msgName]
        if not list then return end
        for i = #list, 1, -1 do
            if list[i] == cb then table.remove(list, i) end
        end
    end
end

function Core:_dispatch(msgName, payload)
    if msgName == "PlayerData_ChangeValue" and type(payload) == "table" then
        local k = payload.key
        if k then
            self._data[k] = payload.value
            self._data["_"..k.."_change"] = payload.change
            self._data["_"..k.."_source"] = payload.source
        end
    elseif msgName == "Mine_State" then
        self._data.MineState = payload
    elseif msgName == "Train_State" then
        self._data.TrainState = payload
    end
    local cbs = self._listeners[msgName]
    if cbs then
        for _, cb in ipairs(cbs) do
            task.spawn(function()
                local ok, err = pcall(cb, payload)
                if not ok then warn("[Mizukage] listener:", msgName, err) end
            end)
        end
    end
end

function Core:start()
    MessageBus.OnClientEvent:Connect(function(msgName, payload)
        self:log("IN", msgName, payload)
        self:_dispatch(msgName, payload)
    end)
end

function Core:get(key) return self._data[key] end

-- ── classic loop (task.wait-based) ──
function Core:startLoop(name, fn)
    self:stopLoop(name)
    self._loops[name] = task.spawn(function()
        local ok, err = pcall(fn)
        if not ok then warn("[Mizukage] loop crashed:", name, err) end
    end)
end

function Core:stopLoop(name)
    if self._loops[name] then
        pcall(task.cancel, self._loops[name])
        self._loops[name] = nil
    end
end

function Core:stopAllLoops()
    for name in pairs(self._loops) do self:stopLoop(name) end
    self:stopAllTurbo()
end

-- ── turbo loop (RenderStepped / Heartbeat-driven) ──
function Core:startTurboLoop(name, fn, useHeartbeat)
    self:stopTurboLoop(name)
    local signal = useHeartbeat and RunService.Heartbeat or RunService.RenderStepped
    self._turboConns[name] = signal:Connect(function(dt)
        local ok, err = pcall(fn, dt)
        if not ok then
            warn("[Mizukage] turbo loop error:", name, err)
            self:stopTurboLoop(name)
        end
    end)
end

function Core:stopTurboLoop(name)
    if self._turboConns[name] then
        pcall(function() self._turboConns[name]:Disconnect() end)
        self._turboConns[name] = nil
    end
end

function Core:stopAllTurbo()
    for name in pairs(self._turboConns) do self:stopTurboLoop(name) end
end

-- ── live fire-rate counter ──
function Core:getFireRate()
    local now = os.clock()
    local live = 0
    -- count events in the current rolling window bucket
    for _ in pairs(self._fpsWindow) do live += 1 end
    if now - self._windowStart >= 1 then return 0 end
    return live
end

local MB = Core.new()
MB:start()

-- ══════════════════════════════════════════════════════════
-- §2  RAYFIELD UI
-- ══════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name = "🔱 MIZUKAGE — TURBO",
    LoadingTitle = "TeamMizu × Mizukage",
    LoadingSubtitle = "Dig Into Secrets — Turbo Edition",
    ConfigurationSaving = {
        Enabled = true, FolderName = "Mizukage", FileName = "dig_turbo",
    },
    Discord = { Enabled = false },
    KeySystem = false,
})

local Settings = {
    TrainRate      = 0.05,
    AutoHitRate    = 0.05,
    MineRate       = 0.05,
    ClaimTip       = 1.5,
    SellCooldown   = 0.35,
    MaxDepth       = 24,
    RebirthCheck   = 1.0,
    RewardInterval = 5,
    -- turbo
    TrainBatch     = 3,     -- fires per frame (train)
    MineBatch      = 2,     -- fires per frame (mine)
    GlobalCap      = CAP_TURBO,
}

-- ══════════════════════════════════════════════════════════
-- §3  TAB: ⚡ Automation — TURBO
-- ══════════════════════════════════════════════════════════
local TabAuto = Window:CreateTab("⚡ Turbo", 4483362458)

TabAuto:CreateSection("🚀 0ms Train (SATURATION)")

TabAuto:CreateToggle({
    Name = "🔥 0ms TRAIN (MAX — every frame)",
    CurrentValue = false,
    Flag = "train_0ms",
    Callback = function(v)
        if v then
            -- Fire Train_AutoHit + Train_Click in a rotation every frame
            MB:startTurboLoop("train_0ms", function()
                local batch = Settings.TrainBatch
                local r = MB:rotate({ "Train_AutoHit", "Train_Click" }, batch)
                if r == 0 then
                    -- budget dry this frame, silently skip
                end
            end, false)  -- RenderStepped (best latency)
        else
            MB:stopTurboLoop("train_0ms")
        end
    end,
})

TabAuto:CreateToggle({
    Name = "🔥 0ms TRAIN + Tip Claim Fusion",
    CurrentValue = false,
    Flag = "train_0ms_tip",
    Callback = function(v)
        if v then
            MB:startTurboLoop("train_0ms_tip", function()
                local batch = Settings.TrainBatch
                local r = MB:rotate({
                    "Train_AutoHit",
                    "Train_Click",
                    "Train_ClaimTip",
                }, batch)
            end, false)
        else
            MB:stopTurboLoop("train_0ms_tip")
        end
    end,
})

TabAuto:CreateSlider({
    Name = "Train Batch per Frame (1-20)",
    Range = {1, 20}, Increment = 1,
    CurrentValue = Settings.TrainBatch,
    Flag = "train_batch",
    Callback = function(v) Settings.TrainBatch = v end,
})

TabAuto:CreateButton({
    Name = "⚡ MANUAL BURST (fire 60 instantly)",
    Callback = function()
        MB:burst("Train_AutoHit", 30, nil)
        MB:burst("Train_Click",   30, nil)
        Rayfield:Notify({ Title="Burst", Content="60 fires dispatched.", Duration=3 })
    end,
})

TabAuto:CreateSection("⛏️ Turbo Mine")

TabAuto:CreateToggle({
    Name = "🔥 Turbo Mine Hit (every frame)",
    CurrentValue = false,
    Flag = "mine_turbo",
    Callback = function(v)
        if v then
            MB:startTurboLoop("mine_turbo", function()
                MB:rotate({ "Train_MineHit" }, Settings.MineBatch)
            end, false)
        else
            MB:stopTurboLoop("mine_turbo")
        end
    end,
})

TabAuto:CreateSlider({
    Name = "Mine Batch per Frame (1-20)",
    Range = {1, 20}, Increment = 1,
    CurrentValue = Settings.MineBatch,
    Flag = "mine_batch",
    Callback = function(v) Settings.MineBatch = v end,
})

TabAuto:CreateToggle({
    Name = "⚡ Instant Descend (slam all depths)",
    CurrentValue = false,
    Flag = "instant_descend",
    Callback = function(v)
        if v then
            MB:startLoop("instant_descend", function()
                -- fire 1..MaxDepth in rapid succession
                for d = 1, Settings.MaxDepth do
                    MB:fireTurbo("Mine_EnterOreLayer", { tierId = d, depth = d })
                    task.wait(0.15)
                end
                -- reset at top after full run
                task.wait(3)
                MB:fire("Mine_Return", nil, 2)
            end)
        else
            MB:stopLoop("instant_descend")
        end
    end,
})

TabAuto:CreateToggle({
    Name = "⚡ Auto Sell (turbo, on full)",
    CurrentValue = false,
    Flag = "turbo_sell",
    Callback = function(v)
        if v then
            MB:startLoop("turbo_sell", function()
                local last = 0
                local unsub = MB:on("Mine_CollectResult", function(p)
                    if type(p) ~= "table" then return end
                    if p.reason == "full" or p.ok == false then
                        local now = os.clock()
                        if now - last >= Settings.SellCooldown then
                            last = now
                            MB:fire("Mine_Sell", nil, Settings.SellCooldown)
                        end
                    end
                end)
                while MB._flags.turbo_sell do task.wait(0.25) end
                unsub()
            end)
        else
            MB:stopLoop("turbo_sell")
        end
    end,
})

TabAuto:CreateSection("🎛️ Classic Train (safe mode)")

TabAuto:CreateToggle({
    Name = "Auto Train Click (safe)",
    CurrentValue = false, Flag = "auto_train_click",
    Callback = function(v)
        if v then
            MB:startLoop("train_click", function()
                while true do
                    MB:fire("Train_Click", nil, Settings.TrainRate)
                    task.wait(Settings.TrainRate)
                end
            end)
        else MB:stopLoop("train_click") end
    end,
})

TabAuto:CreateToggle({
    Name = "Auto Train AutoHit (safe)",
    CurrentValue = false, Flag = "auto_train_autohit",
    Callback = function(v)
        if v then
            MB:startLoop("train_autohit", function()
                while true do
                    MB:fire("Train_AutoHit", nil, Settings.AutoHitRate)
                    task.wait(Settings.AutoHitRate)
                end
            end)
        else MB:stopLoop("train_autohit") end
    end,
})

TabAuto:CreateToggle({
    Name = "Auto Claim Train Tips (safe)",
    CurrentValue = false, Flag = "auto_train_tip",
    Callback = function(v)
        if v then
            MB:startLoop("train_tip", function()
                while true do
                    MB:fire("Train_ClaimTip", nil, 0.5)
                    task.wait(Settings.ClaimTip)
                end
            end)
        else MB:stopLoop("train_tip") end
    end,
})

TabAuto:CreateSection("Hotbar")

TabAuto:CreateButton({ Name = "Select Pickaxe", Callback=function()
    MB:fire("Hotbar_Select", { mode = "pickaxe" }, 0.2)
end })

TabAuto:CreateButton({ Name = "Deselect Tool", Callback=function()
    MB:fire("Hotbar_Select", { mode = "none" }, 0.2)
end })

-- ══════════════════════════════════════════════════════════
-- §4  TAB: 🚂 Train Station
-- ══════════════════════════════════════════════════════════
local TabTrain = Window:CreateTab("🚂 Train", 4483362458)

local stationOpts = {"101","102","103","104","105","106","107","108","109"}
TabTrain:CreateDropdown({
    Name = "Select Station",
    Options = stationOpts,
    CurrentOption = {"101"},
    Flag = "sel_station",
    Callback = function(opt) Settings.SelectedStation = tonumber(opt[1]) or 101 end,
})

TabTrain:CreateButton({ Name = "⚡ Enter Now", Callback = function()
    MB:fire("Train_Enter", { trainId = Settings.SelectedStation or 101 }, 0.5)
end })

TabTrain:CreateButton({ Name = "⚡ Leave Now", Callback = function()
    MB:fire("Train_Leave", nil, 0.5)
end })

TabTrain:CreateToggle({
    Name = "Auto Enter Train (turbo)",
    CurrentValue = false, Flag = "turbo_enter_train",
    Callback = function(v)
        if v then
            MB:startTurboLoop("turbo_enter_train", function()
                MB:fireTurbo("Train_Enter", { trainId = Settings.SelectedStation or 101 })
            end, true)  -- Heartbeat (less priority contention)
        else MB:stopTurboLoop("turbo_enter_train") end
    end,
})

-- ══════════════════════════════════════════════════════════
-- §5  TAB: 🐾 Pets
-- ══════════════════════════════════════════════════════════
local TabPets = Window:CreateTab("🐾 Pets", 4483362458)

TabPets:CreateButton({ Name = "⚡ Equip Best (instant)", Callback = function()
    MB:fireTurbo("EquipBestPets", {})
end })

TabPets:CreateToggle({
    Name = "Auto Re-Equip Best (turbo)",
    CurrentValue = false, Flag = "auto_equip_best",
    Callback = function(v)
        if v then
            MB:startLoop("auto_equip_best", function()
                local last = 0
                local unsub = MB:on("PlayerData_ChangeValue", function(p)
                    if type(p) ~= "table" then return end
                    if p.key == "PetList" or p.key == "UnlockedPetIds" or p.key == "RebirthCount" then
                        local now = os.clock()
                        if now - last >= 1 then
                            last = now
                            MB:fireTurbo("EquipBestPets", {})
                        end
                    end
                end)
                while MB._flags.auto_equip_best do task.wait(0.25) end
                unsub()
            end)
        else MB:stopLoop("auto_equip_best") end
    end,
})

-- ══════════════════════════════════════════════════════════
-- §6  TAB: 🎁 Rewards
-- ══════════════════════════════════════════════════════════
local TabReward = Window:CreateTab("🎁 Rewards", 4483362458)

TabReward:CreateToggle({
    Name = "⚡ Auto Claim Online Reward (turbo)",
    CurrentValue = false, Flag = "turbo_online",
    Callback = function(v)
        if v then
            MB:on("OnlineReward_State", function(state)
                if type(state)=="table" and (state.canClaim or state.ready) then
                    MB:fireTurbo(MessageNames.OnlineReward_Claim or "OnlineReward_Claim")
                end
            end)
            MB:startTurboLoop("turbo_online", function()
                MB:fireTurbo(MessageNames.OnlineReward_GetState or "OnlineReward_GetState")
            end, true)
        else MB:stopTurboLoop("turbo_online") end
    end,
})

TabReward:CreateToggle({
    Name = "⚡ Auto Claim Sign Bonus (turbo)",
    CurrentValue = false, Flag = "turbo_sign",
    Callback = function(v)
        if v then
            MB:on("SignBonus_State", function(state)
                if type(state)=="table" and state.canClaimToday then
                    MB:fireTurbo(MessageNames.SignBonus_Claim or "SignBonus_Claim")
                end
            end)
            MB:startTurboLoop("turbo_sign", function()
                MB:fireTurbo(MessageNames.SignBonus_GetState or "SignBonus_GetState")
            end, true)
        else MB:stopTurboLoop("turbo_sign") end
    end,
})

TabReward:CreateToggle({
    Name = "⚡ Auto Claim Offline Reward (turbo)",
    CurrentValue = false, Flag = "turbo_offline",
    Callback = function(v)
        if v then
            MB:on("OfflineReward_State", function(state)
                if type(state)=="table" and state.canClaim then
                    MB:fireTurbo(MessageNames.OfflineReward_Claim or "OfflineReward_Claim")
                end
            end)
            MB:startTurboLoop("turbo_offline", function()
                MB:fireTurbo(MessageNames.OfflineReward_GetState or "OfflineReward_GetState")
            end, true)
        else MB:stopTurboLoop("turbo_offline") end
    end,
})

TabReward:CreateButton({
    Name = "⚡ SLAM ALL REWARDS NOW",
    Callback = function()
        MB:burst(MessageNames.OnlineReward_GetState or "OnlineReward_GetState", 3, nil)
        MB:burst(MessageNames.SignBonus_GetState    or "SignBonus_GetState",    3, nil)
        MB:burst(MessageNames.OfflineReward_GetState or "OfflineReward_GetState",3, nil)
        MB:burst(MessageNames.OnlineReward_Claim or "OnlineReward_Claim", 1, nil)
        MB:burst(MessageNames.SignBonus_Claim    or "SignBonus_Claim",    1, nil)
        MB:burst(MessageNames.OfflineReward_Claim or "OfflineReward_Claim",1, nil)
    end,
})

-- ══════════════════════════════════════════════════════════
-- §7  TAB: 🔮 Mutation / Rebirth
-- ══════════════════════════════════════════════════════════
local TabMut = Window:CreateTab("🔮 Mutation", 4483362458)

TabMut:CreateToggle({
    Name = "⚡ Auto Claim Mutation (turbo)",
    CurrentValue = false, Flag = "turbo_mutation",
    Callback = function(v)
        if v then
            MB:on("Mutation_State", function(state)
                if type(state)~="table" then return end
                if state.finishAt and os.time() >= state.finishAt and state.started then
                    MB:fireTurbo(MessageNames.Mutation_Claim or "Mutation_Claim")
                end
            end)
            MB:startTurboLoop("turbo_mutation", function()
                MB:fireTurbo(MessageNames.Mutation_State or "Mutation_State")
            end, true)
        else MB:stopTurboLoop("turbo_mutation") end
    end,
})

TabMut:CreateSection("Rebirth")

TabMut:CreateToggle({
    Name = "⚡ Auto Rebirth (turbo, level-gated)",
    CurrentValue = false, Flag = "turbo_rebirth",
    Callback = function(v)
        if v then
            MB:startLoop("turbo_rebirth", function()
                while true do
                    local lvl = tonumber(MB:get("Level")) or 0
                    local rbs = tonumber(MB:get("RebirthCount")) or 0
                    local req = RebirthConfig and RebirthConfig.getRequiredLevel
                        and RebirthConfig.getRequiredLevel(rbs) or 12
                    if lvl >= req then
                        MB:fireTurbo("Rebirth_Request")
                    end
                    task.wait(Settings.RebirthCheck)
                end
            end)
        else MB:stopLoop("turbo_rebirth") end
    end,
})

-- ══════════════════════════════════════════════════════════
-- §8  TAB: 🧭 Upgrade
-- ══════════════════════════════════════════════════════════
local TabUpg = Window:CreateTab("🧭 Upgrade", 4483362458)

local upgradeTypes = {"walkSpeed", "sellPrice", "storage", "petEquip"}

TabUpg:CreateSection("Manual")
for _, ut in ipairs(upgradeTypes) do
    TabUpg:CreateButton({
        Name = "Buy 1x " .. ut,
        Callback = function()
            MB:fireTurbo("MoneyUpgrade_Request", { upgradeType = ut })
        end,
    })
end

TabUpg:CreateSection("Turbo Loops")
for _, ut in ipairs(upgradeTypes) do
    TabUpg:CreateToggle({
        Name = "⚡ Auto " .. ut,
        CurrentValue = false,
        Flag = "turbo_upg_" .. ut,
        Callback = function(v)
            local key = "turbo_upg_" .. ut
            if v then
                MB:startTurboLoop(key, function()
                    MB:fireTurbo("MoneyUpgrade_Request", { upgradeType = ut })
                end, true)
            else
                MB:stopTurboLoop(key)
            end
        end,
    })
end

TabUpg:CreateButton({
    Name = "⚡ MAX EVERYTHING (spam all 4)",
    Callback = function()
        MB:startLoop("max_all_upgrades", function()
            local deadline = os.clock() + 5  -- 5 second spam
            while os.clock() < deadline do
                for _, ut in ipairs(upgradeTypes) do
                    MB:fireTurbo("MoneyUpgrade_Request", { upgradeType = ut })
                end
                task.wait(0.05)
            end
        end)
    end,
})

-- ══════════════════════════════════════════════════════════
-- §9  TAB: ⚙️ Settings
-- ══════════════════════════════════════════════════════════
local TabSet = Window:CreateTab("⚙️ Settings", 4483362458)

TabSet:CreateSection("Global Fire Cap")

TabSet:CreateSlider({
    Name = "Global Cap / second",
    Range = {30, 200}, Increment = 5,
    CurrentValue = Settings.GlobalCap,
    Flag = "set_cap",
    Callback = function(v)
        Settings.GlobalCap = v
        MB._globalMax = v
    end,
})

TabSet:CreateButton({
    Name = "🟢 SAFE (75/s)",
    Callback = function()
        Settings.GlobalCap = CAP_SAFE
        MB._globalMax = CAP_SAFE
        Rayfield:Notify({ Title="Mode", Content="SAFE — 75 fires/sec.", Duration=3 })
    end,
})

TabSet:CreateButton({
    Name = "🟡 TURBO (150/s)",
    Callback = function()
        Settings.GlobalCap = CAP_TURBO
        MB._globalMax = CAP_TURBO
        Rayfield:Notify({ Title="Mode", Content="TURBO — 150 fires/sec.", Duration=3 })
    end,
})

TabSet:CreateButton({
    Name = "🔴 INSANE (200/s)",
    Callback = function()
        Settings.GlobalCap = CAP_INSANE
        MB._globalMax = CAP_INSANE
        Rayfield:Notify({ Title="Mode", Content="INSANE — 200 fires/sec. RISK.", Duration=3 })
    end,
})

TabSet:CreateSection("Classic Timing (non-turbo)")

TabSet:CreateSlider({ Name="Train Click Rate", Range={0.01,1.0}, Increment=0.01, Suffix="s",
    CurrentValue=Settings.TrainRate, Flag="set_trainRate",
    Callback=function(v) Settings.TrainRate=v end })

TabSet:CreateSlider({ Name="AutoHit Rate", Range={0.01,1.0}, Increment=0.01, Suffix="s",
    CurrentValue=Settings.AutoHitRate, Flag="set_autohitRate",
    Callback=function(v) Settings.AutoHitRate=v end })

TabSet:CreateSlider({ Name="Mine Hit Rate", Range={0.01,1.0}, Increment=0.01, Suffix="s",
    CurrentValue=Settings.MineRate, Flag="set_mineRate",
    Callback=function(v) Settings.MineRate=v end })

TabSet:CreateSlider({ Name="Max Descend Depth", Range={1,24}, Increment=1,
    CurrentValue=Settings.MaxDepth, Flag="set_maxDepth",
    Callback=function(v) Settings.MaxDepth=v end })

TabSet:CreateSection("Emergency")

TabSet:CreateButton({
    Name = "⚠️ STOP ALL (kills every loop)",
    Callback = function()
        MB:stopAllLoops()
        -- reset toggles visually
        for _, flag in ipairs({
            "train_0ms","train_0ms_tip","mine_turbo","instant_descend","turbo_sell",
            "auto_train_click","auto_train_autohit","auto_train_tip",
            "turbo_enter_train","auto_equip_best","turbo_online","turbo_sign",
            "turbo_offline","turbo_mutation","turbo_rebirth",
            "turbo_upg_walkSpeed","turbo_upg_sellPrice","turbo_upg_storage","turbo_upg_petEquip",
        }) do
            pcall(function() Rayfield:SetToggle(flag, false) end)
        end
        Rayfield:Notify({ Title="Mizukage", Content="All loops stopped.", Duration=4 })
    end,
})

-- ══════════════════════════════════════════════════════════
-- §10  TAB: 🐞 Debug
-- ══════════════════════════════════════════════════════════
local TabDebug = Window:CreateTab("🐞 Debug", 4483362458)

TabDebug:CreateSection("Live Stats")

local statLabel = TabDebug:CreateLabel("booting...")
task.spawn(function()
    while true do
        local rate = MB:getFireRate()
        local cap  = MB._globalMax
        local total= MB._totalFired
        local lvl  = tostring(MB:get("Level") or "?")
        local rbs  = tostring(MB:get("RebirthCount") or "?")
        local exp  = tostring(MB:get("TotalExp") or "?")
        local cash = tostring(MB:get("Money") or "?")
        local text = string.format(
            "⚡ %d/s  (cap %d/s)   total: %d\nLevel %s | RB %s\nExp %s | $%s",
            rate, cap, total, lvl, rbs, exp, cash
        )
        pcall(function() statLabel:Set(text) end)
        task.wait(0.5)
    end
end)

TabDebug:CreateSection("MessageBus Log")

local logLabel = TabDebug:CreateLabel("—")
task.spawn(function()
    while true do
        local lines = {}
        for i = 1, math.min(14, #MB._log) do
            local e = MB._log[i]
            local age = string.format("%.1f", os.clock() - e.t)
            table.insert(lines, string.format("[%s] %s  (%ss)", e.dir, e.name, age))
        end
        pcall(function() logLabel:Set(table.concat(lines, "\n")) end)
        task.wait(0.75)
    end
end)

TabDebug:CreateButton({
    Name = "Print PlayerData Snapshot",
    Callback = function()
        print("─── Mizukage PlayerData ───")
        for k, v in pairs(MB._data) do
            if not tostring(k):match("^_") then print(k, v) end
        end
        print("───────────────────────────")
    end,
})

TabDebug:CreateButton({
    Name = "Print Last 30 Events",
    Callback = function()
        print("─── Mizukage Log ───")
        for i = 1, math.min(30, #MB._log) do
            local e = MB._log[i]
            print(string.format("[%s] %s", e.dir, e.name), e.payload)
        end
        print("────────────────────")
    end,
})

-- ══════════════════════════════════════════════════════════
-- §11  INIT HANDSHAKE
-- ══════════════════════════════════════════════════════════
task.delay(1.5, function()
    MB:fire(MessageNames.OnlineReward_GetState or "OnlineReward_GetState", nil, 1)
    MB:fire(MessageNames.SignBonus_GetState    or "SignBonus_GetState",    1)
    MB:fire(MessageNames.OfflineReward_GetState or "OfflineReward_GetState",1)
end)

Rayfield:Notify({
    Title = "🔱 TURBO LOADED",
    Content = "0ms Train ready. Open Turbo tab → enable '0ms TRAIN (MAX)'.",
    Duration = 7,
})

-- ══════════════════════════════════════════════════════════
-- §12  CLEANUP
-- ══════════════════════════════════════════════════════════
LP.AncestryChanged:Connect(function()
    if not LP:IsDescendantOf(game) then MB:stopAllLoops() end
end)