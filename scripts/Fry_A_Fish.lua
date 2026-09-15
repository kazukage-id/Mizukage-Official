--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                    MIZUKAGE OFFICIAL 👑                          ║
    ║             Zero-Delay Automation & QA Suite                     ║
    ║             Game: Fry A Fish (Place: 98452648064999)             ║
    ║                     Release Build: 1.3.0                         ║
    ║      Architect: Senior Luau Engineer & QA Systems                ║
    ║      Mode: GACOR / NO DELAY / UNLIMITED THROUGHPUT               ║
    ║      Patch: Auto Fishing Cast Fix + Watchdog Recovery            ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════════
-- 01. BOOTSTRAP & SINGLETON GUARD
-- ═══════════════════════════════════════════════════════════════════
if getgenv and getgenv().MIZUKAGE_LOADED then
    warn("[Mizukage Official 👑] Instance already active. Halting duplicate.")
    return
end
if getgenv then getgenv().MIZUKAGE_LOADED = true end

-- ═══════════════════════════════════════════════════════════════════
-- 02. CONSTANTS — GACOR TUNABLES
-- ═══════════════════════════════════════════════════════════════════
local Constants = {
    NAME = "Mizukage Official",
    BRAND = "Mizukage Official 👑",
    VERSION = "1.3.0",
    BUILD = "GACOR Fixed Release",
    TARGET_PLACE_ID = 98452648064999,

    STAFF_IDS = {
        [4249598239] = "Lead Admin / Developer",
        [1080341316] = "Abuse Admin / Developer",
    },

    ZONES = {
        Shallows = Vector3.new(162, 10, -50),
        Reef     = Vector3.new(200, 10, -50),
        Deep     = Vector3.new(235, 10, -50),
    },

    -- 🔥 GACOR: delay minimum aman
    SERVER_LIMITS = {
        GACOR_REEL_TICK   = 0.05,
        GACOR_FRY_SAMPLE  = 0.08,
        GACOR_ACTION_GAP  = 0.03,
        CAST_CHARGE_WAIT  = 0.08,
        CAST_COOLDOWN     = 0.10,
        WATCHDOG_IDLE     = 2.5,
        CAST_TIMEOUT      = 2.0,
    },

    RARITY_LADDER = { "Common","Uncommon","Rare","Epic","Legendary","Mythic","Secret" },
    UPGRADE_DEFS  = { "Luck","FryLuck","CustomerFlow" },
}

-- ═══════════════════════════════════════════════════════════════════
-- 03. SERVICE LOCATOR
-- ═══════════════════════════════════════════════════════════════════
local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
}

local LocalPlayer = Services.Players.LocalPlayer
if not LocalPlayer then
    Services.Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Services.Players.LocalPlayer
end

-- ═══════════════════════════════════════════════════════════════════
-- 04. NETWORK RESOLUTION (with fallback scan)
-- ═══════════════════════════════════════════════════════════════════
local Remotes = {}

local function FindRemoteRecursive(root, name, depth)
    depth = depth or 3
    if depth < 0 or not root then return nil end
    local direct = root:FindFirstChild(name)
    if direct and (direct:IsA("RemoteEvent") or direct:IsA("RemoteFunction")) then
        return direct
    end
    for _, child in ipairs(root:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Model") then
            local found = FindRemoteRecursive(child, name, depth - 1)
            if found then return found end
        end
    end
    return nil
end

do
    local restaurant = Services.ReplicatedStorage:WaitForChild("Restaurant", 15)
    if not restaurant then
        Logger = Logger or {}
        warn("[Mizukage] Restaurant folder tidak ditemukan di ReplicatedStorage!")
    else
        local remotes = restaurant:WaitForChild("Remotes", 10)
        if remotes then
            Remotes.RE_Fish   = remotes:WaitForChild("RE_Fish", 5)
            Remotes.RE_Fry    = remotes:WaitForChild("RE_Fry", 5)
            Remotes.RF_Action = remotes:WaitForChild("RF_Action", 5)
            Remotes.RE_State  = remotes:WaitForChild("RE_State", 5)
            Remotes.RE_Event  = remotes:WaitForChild("RE_Event", 5)
        else
            -- Fallback: cari di seluruh ReplicatedStorage
            Remotes.RE_Fish   = FindRemoteRecursive(Services.ReplicatedStorage, "RE_Fish")
            Remotes.RE_Fry    = FindRemoteRecursive(Services.ReplicatedStorage, "RE_Fry")
            Remotes.RF_Action = FindRemoteRecursive(Services.ReplicatedStorage, "RF_Action")
            Remotes.RE_State  = FindRemoteRecursive(Services.ReplicatedStorage, "RE_State")
            Remotes.RE_Event  = FindRemoteRecursive(Services.ReplicatedStorage, "RE_Event")
        end
    end

    print(string.format(
        "[Mizukage] Remotes resolved → RE_Fish:%s RE_Fry:%s RF_Action:%s RE_State:%s RE_Event:%s",
        tostring(Remotes.RE_Fish ~= nil),
        tostring(Remotes.RE_Fry ~= nil),
        tostring(Remotes.RF_Action ~= nil),
        tostring(Remotes.RE_State ~= nil),
        tostring(Remotes.RE_Event ~= nil)
    ))
end

-- ═══════════════════════════════════════════════════════════════════
-- 05. CONFIGURATION STORE
-- ═══════════════════════════════════════════════════════════════════
local Config = {
    General = {
        Debug = false,
        Notifications = true,
        GACORMode = true,
    },
    Features = {
        AutoFish = {
            Enabled = false,
            CastPower = 0.95,          -- 🔥 FIX: dari 2.0 → 0.95
            GACORTick = true,
            ReelDelay = Constants.SERVER_LIMITS.GACOR_REEL_TICK,
            AutoReplace = true,
        },
        AutoFry = {
            Enabled = false,
            AutoFlip = true,
            TargetHeat = 0.98,
            SampleRate = Constants.SERVER_LIMITS.GACOR_FRY_SAMPLE,
        },
        AutoUpgrade = {
            Enabled = false,
            UpgradeStats = true,
            UpgradeGear = true,
            Interval = 2,
        },
        AutoRewards = {
            Enabled = false,
            Interval = 3,
        },
        SmartInventory = { Enabled = false, TrashCommonsOnFull = false },
        StaffDetector  = { Enabled = true, NotifyOnJoin = true },
    }
}

-- ═══════════════════════════════════════════════════════════════════
-- 06. STATE MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════
local State = {
    Runtime = {
        IsHooked = false,
        IsCasting = false,
        CastLocked = false,
        LastCastAt = 0,
        LastEventAt = 0,
        ReelThread = nil,
        WatchdogThread = nil,
        IsCookingActive = false,
        CurrentFrySession = nil,
        InventoryCount = 0,
        MaxBagCapacity = 20,
    },
    Player = {
        HeldIndex = 1, FryerTier = 1, RodTier = 1, BaitTier = 1,
        Money = 0, Level = 1, OwnedRods = {}, OwnedFryers = {},
    }
}

-- ═══════════════════════════════════════════════════════════════════
-- 07. LOGGING
-- ═══════════════════════════════════════════════════════════════════
Logger = {}
function Logger.Info(m)  print(string.format("[%s] [INFO] %s",  Constants.NAME, tostring(m))) end
function Logger.Debug(m) if Config.General.Debug then print(string.format("[%s] [DEBUG] %s", Constants.NAME, tostring(m))) end end
function Logger.Warn(m)  warn(string.format("[%s] [WARN] %s",   Constants.NAME, tostring(m))) end
function Logger.Error(m) warn(string.format("[%s] [ERROR] %s",  Constants.NAME, tostring(m))) end

-- ═══════════════════════════════════════════════════════════════════
-- 08. NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════════════
local Notifications = { RayfieldInstance = nil }
function Notifications.Notify(title, message, duration)
    if not Config.General.Notifications then return end
    duration = duration or 3
    if Notifications.RayfieldInstance and Notifications.RayfieldInstance.Notify then
        pcall(function()
            Notifications.RayfieldInstance:Notify({
                Title = title, Content = message, Duration = duration, Image = 4483362458,
            })
        end)
    else
        Logger.Info(string.format("[%s]: %s", title, message))
    end
end
function Notifications.Info(m)    Notifications.Notify("Info", m, 3) end
function Notifications.Success(m) Notifications.Notify("Success", m, 3) end
function Notifications.Warning(m) Notifications.Notify("Warning", m, 4) end
function Notifications.Error(m)   Notifications.Notify("Error", m, 5) end

-- ═══════════════════════════════════════════════════════════════════
-- 09. LIFECYCLE / CLEANUP
-- ═══════════════════════════════════════════════════════════════════
local CleanupManager = { _connections = {}, _tasks = {}, _objects = {} }
function CleanupManager:AddConnection(tag, conn)
    self._connections[tag] = self._connections[tag] or {}
    table.insert(self._connections[tag], conn)
end
function CleanupManager:AddTask(tag, thread)
    self._tasks[tag] = self._tasks[tag] or {}
    table.insert(self._tasks[tag], thread)
end
function CleanupManager:Clean(tag)
    if self._connections[tag] then
        for _, c in ipairs(self._connections[tag]) do pcall(function() c:Disconnect() end) end
        self._connections[tag] = nil
    end
    if self._tasks[tag] then
        for _, t in ipairs(self._tasks[tag]) do pcall(function() task.cancel(t) end) end
        self._tasks[tag] = nil
    end
    if self._objects[tag] then
        for _, o in ipairs(self._objects[tag]) do pcall(function() o:Destroy() end) end
        self._objects[tag] = nil
    end
end
function CleanupManager:CleanAll()
    for tag in pairs(self._connections) do self:Clean(tag) end
    for tag in pairs(self._tasks) do self:Clean(tag) end
    for tag in pairs(self._objects) do self:Clean(tag) end
end

-- ═══════════════════════════════════════════════════════════════════
-- 10. NETWORK UTILITIES
-- ═══════════════════════════════════════════════════════════════════
local Utilities = {}

function Utilities.SafeFireServer(remote, ...)
    if not remote then return false end
    local args = { ... }
    local ok = pcall(function() remote:FireServer(unpack(args)) end)
    return ok
end

function Utilities.SafeInvokeServer(remote, ...)
    if not remote then return nil end
    local args = { ... }
    local ok, res = pcall(function() return remote:InvokeServer(unpack(args)) end)
    if not ok then Logger.Error("InvokeServer failed: " .. tostring(res)) return nil end
    return res
end

function Utilities.BatchFire(remote, packets, gap)
    if not remote then return end
    gap = gap or Constants.SERVER_LIMITS.GACOR_ACTION_GAP
    task.spawn(function()
        for _, pkt in ipairs(packets) do
            pcall(function() remote:FireServer(unpack(pkt)) end)
            if gap > 0 then task.wait(gap) end
        end
    end)
end

function Utilities.BatchInvoke(remote, calls, gap)
    if not remote then return end
    gap = gap or Constants.SERVER_LIMITS.GACOR_ACTION_GAP
    task.spawn(function()
        for _, call in ipairs(calls) do
            pcall(function() remote:InvokeServer(unpack(call)) end)
            if gap > 0 then task.wait(gap) end
        end
    end)
end

function Utilities.TeleportTo(position)
    local char = LocalPlayer.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = CFrame.new(position) return true end
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════════
-- 11. FEATURE REGISTRY
-- ═══════════════════════════════════════════════════════════════════
local FeatureRegistry = { _registry = {} }
function FeatureRegistry:Register(def)
    assert(def.id, "Feature ID required")
    self._registry[def.id] = def
    if def.Initialize then pcall(function() def:Initialize() end) end
end
function FeatureRegistry:Enable(id)
    local feat = self._registry[id]
    if feat and not feat.enabled then
        feat.enabled = true
        local ok, err = pcall(function() feat:Enable() end)
        if not ok then
            Logger.Error("Enable "..tostring(feat.name).." failed: "..tostring(err))
            feat.enabled = false
        end
    end
end
function FeatureRegistry:Disable(id)
    local feat = self._registry[id]
    if feat and feat.enabled then
        feat.enabled = false
        pcall(function() feat:Disable() end)
        CleanupManager:Clean(id)
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- 12. FEATURES
-- ═══════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────
-- [F01] AUTO FISH — FIXED CAST + WATCHDOG
-- ─────────────────────────────────────────────────────────────────
FeatureRegistry:Register({
    id = "AutoFish", name = "Auto Fishing (GACOR)", category = "Fishing", enabled = false,

    Initialize = function(self)
        if not Remotes.RE_Fish then
            Logger.Error("RE_Fish tidak ditemukan — AutoFish tidak bisa jalan.")
            return
        end

        -- Pantau semua paket dari server
        local fishListener = Remotes.RE_Fish.OnClientEvent:Connect(function(packet)
            State.Runtime.LastEventAt = tick()
            if not self.enabled then return end

            -- Normalisasi packet (kadang array, kadang string, kadang table)
            local pType, pData
            if type(packet) == "table" then
                pType = packet.type or packet.t or packet[1]
                pData = packet
            elseif type(packet) == "string" then
                pType = packet
            else
                return
            end

            Logger.Debug("RE_Fish event: " .. tostring(pType))

            if pType == "Bite" then
                State.Runtime.IsHooked = true
                Utilities.SafeFireServer(Remotes.RE_Fish, "Reel")

            elseif pType == "Hooked" then
                State.Runtime.IsHooked = true
                self:StartReelLoop()

            elseif pType == "Progress" then
                if type(pData) == "table" and (pData.p or pData.progress or 0) >= 1 then
                    State.Runtime.IsHooked = false
                end

            elseif pType == "Reeled" or pType == "Caught" or pType == "Missed"
                or (type(pData) == "table" and pData.name ~= nil) then
                State.Runtime.IsHooked = false
                State.Runtime.CastLocked = false
                if self.enabled then
                    task.delay(0.05, function()
                        if self.enabled and not State.Runtime.IsHooked then
                            self:CastCycle()
                        end
                    end)
                end
            end
        end)
        CleanupManager:AddConnection("Global_AutoFish", fishListener)

        -- Auto-resolve ConfirmReplace
        if Remotes.RE_Event then
            local evt = Remotes.RE_Event.OnClientEvent:Connect(function(packet)
                if not self.enabled or type(packet) ~= "table" then return end
                if packet.type == "ConfirmReplace" and Config.Features.AutoFish.AutoReplace then
                    Utilities.SafeInvokeServer(Remotes.RF_Action, "ConfirmReplace", true)
                end
            end)
            CleanupManager:AddConnection("Global_AutoFish", evt)
        end
    end,

    -- Loop reel saat hook
    StartReelLoop = function(self)
        if State.Runtime.ReelThread then return end
        State.Runtime.ReelThread = task.spawn(function()
            while self.enabled and State.Runtime.IsHooked do
                Utilities.SafeFireServer(Remotes.RE_Fish, "Reel")
                local delay = Config.Features.AutoFish.GACORTick
                    and Constants.SERVER_LIMITS.GACOR_REEL_TICK
                    or Config.Features.AutoFish.ReelDelay
                task.wait(delay)
            end
            State.Runtime.ReelThread = nil
        end)
        CleanupManager:AddTask("AutoFish", State.Runtime.ReelThread)
    end,

    -- Kirim cast dengan multi-format fallback
    CastCycle = function(self)
        if not self.enabled or not Remotes.RE_Fish then return end
        if State.Runtime.IsHooked or State.Runtime.CastLocked then return end

        local now = tick()
        if now - State.Runtime.LastCastAt < Constants.SERVER_LIMITS.CAST_COOLDOWN then return end
        State.Runtime.LastCastAt = now
        State.Runtime.CastLocked = true
        State.Runtime.IsCasting = true

        -- Clamp power ke range valid
        local power = math.clamp(Config.Features.AutoFish.CastPower or 0.95, 0.05, 1.0)

        -- Kirim Charge dulu
        Utilities.SafeFireServer(Remotes.RE_Fish, "Charge")
        task.wait(Constants.SERVER_LIMITS.CAST_CHARGE_WAIT)

        -- Multi-format fallback untuk Cast
        local sent = false
        local attempts = {
            { "Cast", power },
            { "Cast", { power = power } },
            { "Cast", power, true },
            { "Cast" },
            { "Throw" },
            { "CastLine", power },
        }
        for _, args in ipairs(attempts) do
            if Utilities.SafeFireServer(Remotes.RE_Fish, unpack(args)) then
                sent = true
                break
            end
        end

        Logger.Debug(string.format("Cast sent (power=%.2f, sent=%s)", power, tostring(sent)))

        State.Runtime.IsCasting = false

        -- Auto-unlock kalau server tidak respon
        task.delay(Constants.SERVER_LIMITS.CAST_TIMEOUT, function()
            if self.enabled and State.Runtime.CastLocked
               and not State.Runtime.IsHooked
               and (tick() - State.Runtime.LastEventAt) > Constants.SERVER_LIMITS.CAST_TIMEOUT then
                Logger.Warn("Cast timeout → unlock.")
                State.Runtime.CastLocked = false
            end
        end)
    end,

    -- Watchdog: auto recast kalau idle
    StartWatchdog = function(self)
        if State.Runtime.WatchdogThread then return end
        State.Runtime.WatchdogThread = task.spawn(function()
            while self.enabled do
                task.wait(1.0)
                if self.enabled
                   and not State.Runtime.IsHooked
                   and not State.Runtime.CastLocked
                   and (tick() - State.Runtime.LastEventAt) > Constants.SERVER_LIMITS.WATCHDOG_IDLE then
                    Logger.Debug("Watchdog: idle → recast.")
                    self:CastCycle()
                end
            end
            State.Runtime.WatchdogThread = nil
        end)
        CleanupManager:AddTask("AutoFish", State.Runtime.WatchdogThread)
    end,

    Enable = function(self)
        State.Runtime.IsHooked = false
        State.Runtime.CastLocked = false
        State.Runtime.LastEventAt = tick()
        self:CastCycle()
        self:StartWatchdog()
    end,

    Disable = function(self)
        State.Runtime.IsHooked = false
        State.Runtime.CastLocked = false
        if Remotes.RE_Fish then
            Utilities.SafeFireServer(Remotes.RE_Fish, "Stow")
        end
    end,
})

-- ─────────────────────────────────────────────────────────────────
-- [F02] AUTO FRY — GACOR MOTION STREAM
-- ─────────────────────────────────────────────────────────────────
FeatureRegistry:Register({
    id = "AutoFry", name = "Auto Fry (GACOR)", category = "Cooking", enabled = false,

    Initialize = function(self)
        if Remotes.RE_Event then
            local evt = Remotes.RE_Event.OnClientEvent:Connect(function(packet)
                if not self.enabled or type(packet) ~= "table" then return end

                if packet.type == "FryBegin" then
                    State.Runtime.IsCookingActive = true
                    State.Runtime.CurrentFrySession = packet.plotId or packet.sessionId or 1
                    Utilities.SafeInvokeServer(Remotes.RF_Action, "FryDrop")

                elseif packet.type == "FlipWindow" then
                    if Config.Features.AutoFry.AutoFlip and packet.sessionId then
                        Utilities.SafeInvokeServer(Remotes.RF_Action, "FryFlip",
                            packet.sessionId, packet.windowId or 1)
                    end

                elseif packet.type == "FryResult" then
                    State.Runtime.IsCookingActive = false
                    State.Runtime.CurrentFrySession = nil
                    Utilities.SafeInvokeServer(Remotes.RF_Action, "FryExit")
                end
            end)
            CleanupManager:AddConnection("Global_AutoFry", evt)
        end
    end,

    Enable = function(self)
        local loop = task.spawn(function()
            while self.enabled do
                if State.Runtime.IsCookingActive and State.Runtime.CurrentFrySession and Remotes.RE_Fry then
                    Utilities.SafeFireServer(Remotes.RE_Fry, {
                        id = State.Runtime.CurrentFrySession,
                        t  = "Motion",
                        s  = Config.Features.AutoFry.TargetHeat
                    })
                end
                task.wait(Config.Features.AutoFry.SampleRate)
            end
        end)
        CleanupManager:AddTask("AutoFry", loop)
    end,

    Disable = function(self)
        State.Runtime.IsCookingActive = false
        State.Runtime.CurrentFrySession = nil
        Utilities.SafeInvokeServer(Remotes.RF_Action, "FryExit")
    end,
})

-- ─────────────────────────────────────────────────────────────────
-- [F03] AUTO UPGRADE
-- ─────────────────────────────────────────────────────────────────
FeatureRegistry:Register({
    id = "AutoUpgrade", name = "Auto Upgrade (GACOR)", category = "Automation", enabled = false,

    Enable = function(self)
        local t = task.spawn(function()
            while self.enabled do
                if Remotes.RF_Action then
                    if Config.Features.AutoUpgrade.UpgradeStats then
                        local calls = {}
                        for _, statKey in ipairs(Constants.UPGRADE_DEFS) do
                            table.insert(calls, { "BuyUpgrade", statKey })
                        end
                        Utilities.BatchInvoke(Remotes.RF_Action, calls, Constants.SERVER_LIMITS.GACOR_ACTION_GAP)
                    end

                    if Config.Features.AutoUpgrade.UpgradeGear then
                        Utilities.BatchInvoke(Remotes.RF_Action, {
                            { "BuyGearTier", "Rod",   State.Player.RodTier   + 1 },
                            { "BuyGearTier", "Fryer", State.Player.FryerTier + 1 },
                            { "BuyGearTier", "Bait",  State.Player.BaitTier  + 1 },
                        }, Constants.SERVER_LIMITS.GACOR_ACTION_GAP)
                    end
                end
                task.wait(Config.Features.AutoUpgrade.Interval)
            end
        end)
        CleanupManager:AddTask("AutoUpgrade", t)
    end,
    Disable = function(self) end,
})

-- ─────────────────────────────────────────────────────────────────
-- [F04] AUTO REWARDS
-- ─────────────────────────────────────────────────────────────────
FeatureRegistry:Register({
    id = "AutoRewards", name = "Reward Collector (GACOR)", category = "Automation", enabled = false,

    Enable = function(self)
        local t = task.spawn(function()
            while self.enabled do
                if Remotes.RF_Action then
                    local calls = { { "ClaimDaily" } }
                    for slot = 1, 8 do
                        table.insert(calls, { "ClaimPlaytime", slot })
                    end
                    Utilities.BatchInvoke(Remotes.RF_Action, calls, Constants.SERVER_LIMITS.GACOR_ACTION_GAP)
                end
                task.wait(Config.Features.AutoRewards.Interval)
            end
        end)
        CleanupManager:AddTask("AutoRewards", t)
    end,
    Disable = function(self) end,
})

-- ─────────────────────────────────────────────────────────────────
-- [F05] SMART INVENTORY
-- ─────────────────────────────────────────────────────────────────
FeatureRegistry:Register({
    id = "SmartInventory", name = "Smart Bag Cleaner", category = "Automation", enabled = false,

    Enable = function(self)
        local t = task.spawn(function()
            while self.enabled do
                if Config.Features.SmartInventory.TrashCommonsOnFull and Remotes.RF_Action then
                    if State.Runtime.InventoryCount >= State.Runtime.MaxBagCapacity then
                        Utilities.SafeInvokeServer(Remotes.RF_Action, "SelectSlot", 1)
                    end
                end
                task.wait(1.5)
            end
        end)
        CleanupManager:AddTask("SmartInventory", t)
    end,
    Disable = function(self) end,
})

-- ─────────────────────────────────────────────────────────────────
-- [F06] STAFF DETECTOR
-- ─────────────────────────────────────────────────────────────────
FeatureRegistry:Register({
    id = "StaffDetector", name = "Staff Detector", category = "Protection", enabled = true,

    CheckPlayer = function(self, player)
        if Constants.STAFF_IDS[player.UserId] then
            local role = Constants.STAFF_IDS[player.UserId]
            local txt = string.format("Staff Active: %s (%s)", player.Name, role)
            Logger.Warn(txt)
            Notifications.Warning(txt)
        end
    end,

    Enable = function(self)
        for _, p in ipairs(Services.Players:GetPlayers()) do
            if p ~= LocalPlayer then self:CheckPlayer(p) end
        end
        local c = Services.Players.PlayerAdded:Connect(function(p)
            if self.enabled then self:CheckPlayer(p) end
        end)
        CleanupManager:AddConnection("StaffDetector", c)
    end,
    Disable = function(self) end,
})

-- ═══════════════════════════════════════════════════════════════════
-- 13. GLOBAL STATE SYNC
-- ═══════════════════════════════════════════════════════════════════
if Remotes.RE_State then
    local c = Remotes.RE_State.OnClientEvent:Connect(function(data)
        if type(data) == "table" then
            if data.HeldIndex   ~= nil then State.Player.HeldIndex   = data.HeldIndex   end
            if data.FryerTier   ~= nil then State.Player.FryerTier   = data.FryerTier   end
            if data.RodTier     ~= nil then State.Player.RodTier     = data.RodTier     end
            if data.BaitTier    ~= nil then State.Player.BaitTier    = data.BaitTier    end
            if data.OwnedRods   ~= nil then State.Player.OwnedRods   = data.OwnedRods   end
            if data.OwnedFryers ~= nil then State.Player.OwnedFryers = data.OwnedFryers end
            if data.BagInventory and type(data.BagInventory) == "table" then
                local n = 0
                for _ in pairs(data.BagInventory) do n += 1 end
                State.Runtime.InventoryCount = n
            end
        end
    end)
    CleanupManager:AddConnection("Global_StateSync", c)
end

-- ═══════════════════════════════════════════════════════════════════
-- 14. RAYFIELD UI
-- ═══════════════════════════════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
Notifications.RayfieldInstance = Rayfield

local Window = Rayfield:CreateWindow({
    Name = Constants.BRAND .. " | Fry A Fish (GACOR)",
    LoadingTitle = Constants.NAME,
    LoadingSubtitle = "by Mizukage Official 👑 | v" .. Constants.VERSION,
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false,
})

local UIManager = {}
function UIManager.CreateText(tab, o)
    if tab.CreateText then return tab:CreateText(o)
    elseif tab.CreateParagraph then
        return tab:CreateParagraph({ Title = o.name or "Info", Content = o.body or "" })
    end
end
function UIManager.CreateDivider(tab, o)
    if tab.CreateDivider then return tab:CreateDivider(o) end
end

local TabMain       = Window:CreateTab("Dashboard",  "home")
local TabFishing    = Window:CreateTab("Fishing",    "anchor")
local TabCooking    = Window:CreateTab("Cooking",    "flame")
local TabUpgrades   = Window:CreateTab("Upgrades",   "trending-up")
local TabAutomation = Window:CreateTab("Automation", "cpu")
local TabTeleports  = Window:CreateTab("Teleports",  "map-pin")
local TabSettings   = Window:CreateTab("Settings",   "settings")

-- ─── DASHBOARD ───
TabMain:CreateSection("Live Diagnostics")
UIManager.CreateText(TabMain, { name = "Engine Status",
    body = "Mizukage Official GACOR v"..Constants.VERSION.." active." })
UIManager.CreateText(TabMain, { name = "Remote Resolver",
    body = string.format("RE_Fish:%s RE_Fry:%s RF_Action:%s",
        tostring(Remotes.RE_Fish ~= nil),
        tostring(Remotes.RE_Fry ~= nil),
        tostring(Remotes.RF_Action ~= nil)) })
UIManager.CreateDivider(TabMain, { name = "Fast Execution" })

TabMain:CreateButton({
    Name = "⚡ Claim Daily & All Playtime (Instant)",
    Callback = function()
        if Remotes.RF_Action then
            local calls = { { "ClaimDaily" } }
            for i = 1, 8 do table.insert(calls, { "ClaimPlaytime", i }) end
            Utilities.BatchInvoke(Remotes.RF_Action, calls, 0.03)
            Notifications.Success("Batch claim sent.")
        end
    end,
})

TabMain:CreateToggle({
    Name = "🔥 GACOR MODE (Global)",
    CurrentValue = Config.General.GACORMode,
    Flag = "Toggle_GACOR",
    Callback = function(v)
        Config.General.GACORMode = v
        if v then
            Config.Features.AutoFish.ReelDelay = Constants.SERVER_LIMITS.GACOR_REEL_TICK
            Config.Features.AutoFry.SampleRate = Constants.SERVER_LIMITS.GACOR_FRY_SAMPLE
            Notifications.Success("GACOR mode ON.")
        else
            Config.Features.AutoFish.ReelDelay = 0.20
            Config.Features.AutoFry.SampleRate = 0.25
            Notifications.Warning("GACOR mode OFF.")
        end
    end,
})

-- ─── FISHING ───
TabFishing:CreateSection("Auto Fishing (GACOR)")
TabFishing:CreateToggle({
    Name = "Enable Auto Fishing",
    CurrentValue = Config.Features.AutoFish.Enabled,
    Flag = "Toggle_AutoFish",
    Callback = function(v)
        Config.Features.AutoFish.Enabled = v
        if v then FeatureRegistry:Enable("AutoFish") else FeatureRegistry:Disable("AutoFish") end
    end,
})

TabFishing:CreateButton({
    Name = "🎣 Force Cast Now (Manual Retry)",
    Callback = function()
        if not Config.Features.AutoFish.Enabled then
            Notifications.Warning("Aktifkan Auto Fishing dulu.")
            return
        end
        State.Runtime.CastLocked = false
        State.Runtime.IsHooked = false
        local feat = FeatureRegistry._registry.AutoFish
        if feat then feat:CastCycle() Notifications.Info("Cast ulang dikirim.") end
    end,
})

TabFishing:CreateToggle({
    Name = "GACOR Reel Tick (0.05s)",
    CurrentValue = Config.Features.AutoFish.GACORTick,
    Flag = "Toggle_GACORTick",
    Callback = function(v)
        Config.Features.AutoFish.GACORTick = v
        Notifications.Info(v and "GACOR reel aktif." or "Custom delay aktif.")
    end,
})

TabFishing:CreateSlider({
    Name = "Custom Reel Delay",
    Range = { 0.02, 0.50 }, Increment = 0.01, Suffix = "s",
    CurrentValue = Config.Features.AutoFish.ReelDelay, Flag = "Slider_ReelDelay",
    Callback = function(v) Config.Features.AutoFish.ReelDelay = v end,
})

TabFishing:CreateSlider({
    Name = "Cast Power",
    Range = { 0.05, 1.00 }, Increment = 0.01, Suffix = "Pwr",  -- 🔥 FIX range
    CurrentValue = Config.Features.AutoFish.CastPower, Flag = "Slider_CastPower",
    Callback = function(v) Config.Features.AutoFish.CastPower = v end,
})

TabFishing:CreateToggle({
    Name = "Auto-Resolve Bag Full Replacement",
    CurrentValue = Config.Features.AutoFish.AutoReplace, Flag = "Toggle_AutoReplace",
    Callback = function(v) Config.Features.AutoFish.AutoReplace = v end,
})

-- ─── COOKING ───
TabCooking:CreateSection("Auto Fry (GACOR)")
TabCooking:CreateToggle({
    Name = "Enable Auto Fry",
    CurrentValue = Config.Features.AutoFry.Enabled, Flag = "Toggle_AutoFry",
    Callback = function(v)
        Config.Features.AutoFry.Enabled = v
        if v then FeatureRegistry:Enable("AutoFry") else FeatureRegistry:Disable("AutoFry") end
    end,
})
TabCooking:CreateToggle({
    Name = "Pan Auto Perfect Flip",
    CurrentValue = Config.Features.AutoFry.AutoFlip, Flag = "Toggle_AutoFlip",
    Callback = function(v) Config.Features.AutoFry.AutoFlip = v end,
})
TabCooking:CreateSlider({
    Name = "Target Pan Heat",
    Range = { 0.50, 1.00 }, Increment = 0.01, Suffix = "Heat",
    CurrentValue = Config.Features.AutoFry.TargetHeat, Flag = "Slider_TargetHeat",
    Callback = function(v) Config.Features.AutoFry.TargetHeat = v end,
})
TabCooking:CreateSlider({
    Name = "Motion Sample Rate",
    Range = { 0.04, 0.30 }, Increment = 0.01, Suffix = "s",
    CurrentValue = Config.Features.AutoFry.SampleRate, Flag = "Slider_SampleRate",
    Callback = function(v) Config.Features.AutoFry.SampleRate = v end,
})

-- ─── UPGRADES ───
TabUpgrades:CreateSection("Autonomous Upgrades (GACOR)")
TabUpgrades:CreateToggle({
    Name = "Enable Auto Upgrades",
    CurrentValue = Config.Features.AutoUpgrade.Enabled, Flag = "Toggle_AutoUpgrade",
    Callback = function(v)
        Config.Features.AutoUpgrade.Enabled = v
        if v then FeatureRegistry:Enable("AutoUpgrade") else FeatureRegistry:Disable("AutoUpgrade") end
    end,
})
TabUpgrades:CreateToggle({
    Name = "Auto Upgrade Stats",
    CurrentValue = Config.Features.AutoUpgrade.UpgradeStats, Flag = "Toggle_UpgradeStats",
    Callback = function(v) Config.Features.AutoUpgrade.UpgradeStats = v end,
})
TabUpgrades:CreateToggle({
    Name = "Auto Buy & Equip Gear",
    CurrentValue = Config.Features.AutoUpgrade.UpgradeGear, Flag = "Toggle_UpgradeGear",
    Callback = function(v) Config.Features.AutoUpgrade.UpgradeGear = v end,
})
TabUpgrades:CreateSlider({
    Name = "Upgrade Cycle Interval",
    Range = { 1, 30 }, Increment = 1, Suffix = "s",
    CurrentValue = Config.Features.AutoUpgrade.Interval, Flag = "Slider_UpgradeInterval",
    Callback = function(v) Config.Features.AutoUpgrade.Interval = v end,
})

-- ─── AUTOMATION ───
TabAutomation:CreateSection("Rewards & Inventory")
TabAutomation:CreateToggle({
    Name = "Loop Auto-Claim Rewards (GACOR)",
    CurrentValue = Config.Features.AutoRewards.Enabled, Flag = "Toggle_AutoRewards",
    Callback = function(v)
        Config.Features.AutoRewards.Enabled = v
        if v then FeatureRegistry:Enable("AutoRewards") else FeatureRegistry:Disable("AutoRewards") end
    end,
})
TabAutomation:CreateSlider({
    Name = "Reward Cycle Interval",
    Range = { 1, 30 }, Increment = 1, Suffix = "s",
    CurrentValue = Config.Features.AutoRewards.Interval, Flag = "Slider_RewardInterval",
    Callback = function(v) Config.Features.AutoRewards.Interval = v end,
})
TabAutomation:CreateToggle({
    Name = "Auto-Trash Commons When Bag Full",
    CurrentValue = Config.Features.SmartInventory.TrashCommonsOnFull, Flag = "Toggle_TrashCommons",
    Callback = function(v)
        Config.Features.SmartInventory.TrashCommonsOnFull = v
        if v then FeatureRegistry:Enable("SmartInventory") else FeatureRegistry:Disable("SmartInventory") end
    end,
})

-- ─── TELEPORTS ───
TabTeleports:CreateSection("Fishing Zones")
TabTeleports:CreateButton({ Name = "Dock Shallows (X:162)", Callback = function()
    Utilities.TeleportTo(Constants.ZONES.Shallows); Notifications.Info("→ Shallows") end })
TabTeleports:CreateButton({ Name = "The Reef (X:200)", Callback = function()
    Utilities.TeleportTo(Constants.ZONES.Reef); Notifications.Info("→ Reef") end })
TabTeleports:CreateButton({ Name = "The Deep (X:235)", Callback = function()
    Utilities.TeleportTo(Constants.ZONES.Deep); Notifications.Info("→ Deep") end })

UIManager.CreateDivider(TabTeleports, { name = "Waypoints" })
TabTeleports:CreateButton({ Name = "Teleport: My Restaurant Base", Callback = function()
    if Remotes.RF_Action then Utilities.SafeInvokeServer(Remotes.RF_Action, "MyBase")
        Notifications.Info("→ Base") end end })
TabTeleports:CreateButton({ Name = "Teleport: Main Pier", Callback = function()
    if Remotes.RF_Action then Utilities.SafeInvokeServer(Remotes.RF_Action, "Pier")
        Notifications.Info("→ Pier") end end })

-- ─── SETTINGS ───
TabSettings:CreateSection("Protections & Controls")
TabSettings:CreateToggle({
    Name = "Staff / Admin Detection Alert",
    CurrentValue = Config.Features.StaffDetector.Enabled, Flag = "Toggle_StaffDetector",
    Callback = function(v)
        Config.Features.StaffDetector.Enabled = v
        if v then FeatureRegistry:Enable("StaffDetector") else FeatureRegistry:Disable("StaffDetector") end
    end,
})
TabSettings:CreateToggle({
    Name = "In-Game Notifications",
    CurrentValue = Config.General.Notifications, Flag = "Toggle_Notifications",
    Callback = function(v) Config.General.Notifications = v end,
})
TabSettings:CreateToggle({
    Name = "Debug Console Output",
    CurrentValue = Config.General.Debug, Flag = "Toggle_Debug",
    Callback = function(v) Config.General.Debug = v end,
})

UIManager.CreateDivider(TabSettings, { name = "Lifecycle" })
TabSettings:CreateButton({
    Name = "Unload Engine & Clear Connections",
    Callback = function()
        CleanupManager:CleanAll()
        if getgenv then getgenv().MIZUKAGE_LOADED = nil end
        Notifications.Info("Engine unloaded.")
        task.wait(0.5)
        if Rayfield and Rayfield.Destroy then pcall(function() Rayfield:Destroy() end) end
    end,
})

UIManager.CreateText(TabSettings, {
    name = "Engineering Standards",
    body = Constants.BRAND .. " | GACOR v" .. Constants.VERSION
})

-- ═══════════════════════════════════════════════════════════════════
-- 15. INITIALIZE
-- ═══════════════════════════════════════════════════════════════════
FeatureRegistry:Enable("StaffDetector")
Logger.Info("Mizukage Official 👑 GACOR v" .. Constants.VERSION .. " initialized.")
Notifications.Success("Mizukage Official 👑 GACOR Loaded!")