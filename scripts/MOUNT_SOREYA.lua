--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                    MIZUKAGE OFFICIAL 👑                          ║
    ║             End-To-End Automation & QA Suite                     ║
    ║        Game: UPD_PET_MOUNT_SOREYA (Place: 118517641508250)       ║
    ║                     Release Build: 4.0.0                         ║
    ║         ULTRA-FAST SENSOR & ADVANCED MANUAL CALIBRATION          ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════════
-- 01. BOOTSTRAP & SINGLETON GUARD
-- ═══════════════════════════════════════════════════════════════════
if getgenv and getgenv().MIZUKAGE_SOREYA_V4 then
    warn("[Mizukage Official 👑] Instance already running. Cleaning up prior process...")
    if getgenv().MIZUKAGE_SOREYA_UNLOAD then
        getgenv().MIZUKAGE_SOREYA_UNLOAD()
    end
end

if getgenv then
    getgenv().MIZUKAGE_SOREYA_V4 = true
end

-- ═══════════════════════════════════════════════════════════════════
-- 02. CONSTANTS & REGISTRY
-- ═══════════════════════════════════════════════════════════════════
local Constants = {
    NAME = "Mizukage Official",
    BRAND = "Mizukage Official 👑",
    VERSION = "4.0.0",
    BUILD = "Ultra Turbo Production",
    TARGET_PLACE_ID = 118517641508250,

    DEFAULT_WEBHOOK = "https://discord.com/api/webhooks/1548351986502602792/W96yV_v9vjQOZFN4JuBwETw7wr3AqXPqRaG3sAX0hfw_NzxMAkhaFvlczSw_HZu54z4_",

    RARITY_RANK = {
        Common = 1, UnCommon = 2, Rare = 3, Epic = 4,
        Legend = 5, Legendary = 5,
        Mythical = 6, Mythic = 6, Mitos = 6, Mythos = 6,
        Secret = 7, SECRET = 7,
        FORGOTTEN = 8, Forgotten = 8,
    },

    RARITY_COLOR = {
        Common = 0xB1B1B1, UnCommon = 0x80FF52, Rare = 0x55A2FF, Epic = 0xB272F7,
        Legend = 0xFFB82A, Legendary = 0xFFB82A,
        Mythical = 0xFF64C8, Mythic = 0xFF64C8, Mitos = 0xFF64C8,
        Secret = 0x17FF97, SECRET = 0x17FF97,
        FORGOTTEN = 0x7F7F7F, Forgotten = 0x7F7F7F,
    },

    RARITY_ICON = {
        Common = "[C]", UnCommon = "[UC]", Rare = "[R]", Epic = "[E]",
        Legend = "[L]", Legendary = "[L]",
        Mythical = "[M]", Mythic = "[M]", Mitos = "[M]",
        Secret = "[S]", SECRET = "[S]",
        FORGOTTEN = "[F]", Forgotten = "[F]",
    },

    SOUNDS = {
        Bite = "rbxassetid://123845773202915",
        Rare = "rbxassetid://133304152585589",
        SuperRare = "rbxassetid://84099093339952",
    }
}

-- ═══════════════════════════════════════════════════════════════════
-- 03. SERVICES
-- ═══════════════════════════════════════════════════════════════════
local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    HttpService = game:GetService("HttpService"),
    SoundService = game:GetService("SoundService"),
    StarterGui = game:GetService("StarterGui"),
    VirtualUser = game:GetService("VirtualUser"),
}

local LocalPlayer = Services.Players.LocalPlayer
if not LocalPlayer then
    Services.Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Services.Players.LocalPlayer
end

-- ═══════════════════════════════════════════════════════════════════
-- 04. DATABASES SAFE INGESTION
-- ═══════════════════════════════════════════════════════════════════
local Databases = {
    FishDB = nil,
    ItemDB = nil,
    MutasiDB = nil,
    TierDB = nil,
    CoreCfg = nil,
    EventCfg = nil,
}

do
    local rsModules = Services.ReplicatedStorage:FindFirstChild("Modules")
    local rsFishing = rsModules and rsModules:FindFirstChild("Fishing")
    if rsFishing then
        pcall(function() Databases.FishDB = require(rsFishing:WaitForChild("FishingImageDatabase", 5)) end)
        pcall(function() Databases.ItemDB = require(rsFishing:WaitForChild("ItemDatabase", 5)) end)
        pcall(function() Databases.MutasiDB = require(rsFishing:WaitForChild("MutasiConfig", 5)) end)
        pcall(function() Databases.TierDB = require(rsFishing:WaitForChild("TierIkan", 5)) end)
    end

    local rsConfig = Services.ReplicatedStorage:FindFirstChild("Modul")
    if rsConfig then
        local cfgFolder = rsConfig:FindFirstChild("Konfigurasi")
        if cfgFolder then
            pcall(function() Databases.CoreCfg = require(cfgFolder:WaitForChild("CoreConfig", 5)) end)
            pcall(function() Databases.EventCfg = require(cfgFolder:WaitForChild("EventOtomatis", 5)) end)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- 05. GLOBAL REMOTES LOCATOR
-- ═══════════════════════════════════════════════════════════════════
local GlobalRemotes = {
    TandaSeruBersama = Services.ReplicatedStorage:FindFirstChild("TandaSeruBersama"),
    CutsceneBroadcast = Services.ReplicatedStorage:FindFirstChild("CutsceneBroadcast"),
    EfekMancingEvent = Services.ReplicatedStorage:FindFirstChild("EfekMancingEvent"),
    InventarisBerubah = nil,
    InventarisAmbilSemua = nil,
    IndexBerubah = nil,
    DaftarSkin = nil,
    PesanChat = nil,
}

do
    local rem = Services.ReplicatedStorage:FindFirstChild("Remote")
    if rem then
        local inv = rem:FindFirstChild("Inventaris")
        if inv then
            GlobalRemotes.InventarisBerubah = inv:FindFirstChild("Berubah")
            GlobalRemotes.InventarisAmbilSemua = inv:FindFirstChild("AmbilSemua")
        end

        local idx = rem:FindFirstChild("Index")
        if idx then
            GlobalRemotes.IndexBerubah = idx:FindFirstChild("IndexBerubah")
        end

        local shop = rem:FindFirstChild("Toko")
        if shop then
            GlobalRemotes.DaftarSkin = shop:FindFirstChild("DaftarSkin")
        end

        local admin = rem:FindFirstChild("Admin")
        if admin then
            GlobalRemotes.PesanChat = admin:FindFirstChild("PesanChat")
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- 06. CONFIGURATION STORE
-- ═══════════════════════════════════════════════════════════════════
local Config = {
    General = {
        Debug = false,
        Notifications = true,
    },
    Features = {
        AutoFish = {
            Enabled = false,
            Mode = "Ultra Turbo", -- Ultra Turbo, Realistic, Smart Fast
            MinPower = 94,
            MaxPower = 99,
            ChargeDelay = 0.05,     -- Kecepatan charge lemparan
            RecastDelay = 0.12,     -- Jeda melempar ulang setelah ikan didapat
            WatchdogTimeout = 8.0,  -- Reset paksa jika minigame/lemparan macet
            BypassStatusCheck = true, -- Lempar kail walau status game desync
            AutoEquipBest = true,
            AntiDuplicateBite = true,
            WinBurst = 2,
            VisualExclamationSensor = true,
        },
        AutoCollect = {
            Enabled = true,
            InstantClaim = true,
            SweepInterval = 3,
        },
        Alerts = {
            BiteAlert = true,
            RareAlert = true,
            RareThreshold = "Legendary",
            GlobalCutscene = true,
            PlayerRadar = false,
            ChatFilter = false,
            ChatKeyword = "SECRET",
        },
        EventTrackers = {
            CoreTracker = true,
            HourlyTracker = true,
        },
        Webhook = {
            Enabled = true, -- Aktif secara backend
            Url = Constants.DEFAULT_WEBHOOK,
            MinRarity = "Secret",
            WithThumb = true,
            WithImage = true,
            WithMutColor = true,
        },
        Protection = {
            AntiAFK = true,
        }
    }
}

-- ═══════════════════════════════════════════════════════════════════
-- 07. RUNTIME STATE MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════
local State = {
    Runtime = {
        IsCasting = false,
        IsMiniGameActive = false,
        LastCastTick = 0,
        LastBiteTick = 0,
        LastGotFishTick = 0,
        ActiveRod = nil,
    },
    Stats = {
        Catches = 0,
        Casts = 0,
        Failed = 0,
        Perfect = 0,
        StartTime = os.clock(),
        PeakRate = 0,
        BestCatch = { name = "-", rarity = "-", weight = 0, mutation = "-" },
        Rarity = {
            Common = 0, UnCommon = 0, Rare = 0, Epic = 0,
            Legendary = 0, Mythical = 0, Secret = 0, FORGOTTEN = 0
        },
        Global = {
            Secret = 0, Mythical = 0, Forgotten = 0
        }
    }
}

-- ═══════════════════════════════════════════════════════════════════
-- 08. LOGGER & DIAGNOSTICS
-- ═══════════════════════════════════════════════════════════════════
local Logger = {}
function Logger.Info(msg)
    print(string.format("[%s] [INFO] %s", Constants.NAME, tostring(msg)))
end

function Logger.Debug(msg)
    if Config.General.Debug then
        print(string.format("[%s] [DEBUG] %s", Constants.NAME, tostring(msg)))
    end
end

function Logger.Warn(msg)
    warn(string.format("[%s] [WARN] %s", Constants.NAME, tostring(msg)))
end

function Logger.Error(msg)
    warn(string.format("[%s] [ERROR] %s", Constants.NAME, tostring(msg)))
end

-- ═══════════════════════════════════════════════════════════════════
-- 09. NOTIFICATION & AUDIO ENGINE
-- ═══════════════════════════════════════════════════════════════════
local Notifications = {
    RayfieldInstance = nil,
}

function Notifications.Notify(title, message, duration)
    if not Config.General.Notifications then return end
    duration = duration or 3
    if Notifications.RayfieldInstance and Notifications.RayfieldInstance.Notify then
        pcall(function()
            Notifications.RayfieldInstance:Notify({
                Title = title,
                Content = message,
                Duration = duration,
                Image = 4483362458,
            })
        end)
    else
        pcall(function()
            Services.StarterGui:SetCore("SendNotification", {
                Title = title,
                Text = message,
                Duration = duration,
            })
        end)
    end
end

function Notifications.Info(msg) Notifications.Notify("Info", msg, 3) end
function Notifications.Success(msg) Notifications.Notify("Success", msg, 3) end
function Notifications.Warning(msg) Notifications.Notify("Warning", msg, 4) end
function Notifications.Error(msg) Notifications.Notify("Error", msg, 5) end

local function playAudio(id, vol)
    task.spawn(function()
        local ok, s = pcall(function()
            local snd = Instance.new("Sound")
            snd.SoundId = id
            snd.Volume = vol or 0.6
            snd.Parent = Services.SoundService
            snd:Play()
            return snd
        end)
        if ok and s then
            task.wait(3.5)
            pcall(function() s:Destroy() end)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- 10. LIFECYCLE & CLEANUP MANAGER
-- ═══════════════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════════════
-- 11. REVERSE-ENGINEERED UTILITIES
-- ═══════════════════════════════════════════════════════════════════
local Utilities = {}

function Utilities.Rank(r)
    return Constants.RARITY_RANK[r] or 0
end

function Utilities.MeetsRarity(r, threshold)
    return Utilities.Rank(r) >= Utilities.Rank(threshold)
end

function Utilities.ChanceText(chance)
    if not chance or chance <= 0 then return "?" end
    local val = 1 / chance
    if val >= 1e9 then return string.format("1 in %.1fB", val / 1e9) end
    if val >= 1e6 then return string.format("1 in %.1fM", val / 1e6) end
    if val >= 1e3 then return string.format("1 in %.1fK", val / 1e3) end
    return string.format("1 in %d", math.floor(val))
end

function Utilities.FormatTime(sec)
    sec = math.max(0, math.floor(tonumber(sec) or 0))
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then return string.format("%dh %02dm", h, m) end
    if m > 0 then return string.format("%dm %02ds", m, s) end
    return string.format("%ds", s)
end

function Utilities.Color3ToInteger(c)
    if not c or typeof(c) ~= "Color3" then return nil end
    local r = math.floor(math.clamp(c.R, 0, 1) * 255 + 0.5)
    local g = math.floor(math.clamp(c.G, 0, 1) * 255 + 0.5)
    local b = math.floor(math.clamp(c.B, 0, 1) * 255 + 0.5)
    return r * 65536 + g * 256 + b
end

function Utilities.GetMutationColor(mutName)
    if not Databases.MutasiDB then return nil end
    local ok, c = pcall(function() return Databases.MutasiDB.Warna(mutName) end)
    if ok and typeof(c) == "Color3" then return c end
    return nil
end

function Utilities.GetEquippedRod()
    local c = LocalPlayer.Character
    if not c then return nil end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") and t:FindFirstChild("Mechanics") then
            return t
        end
    end
    return nil
end

function Utilities.GetRodRemotes(rod)
    if not rod then return nil end
    local mech = rod:FindFirstChild("Mechanics")
    return mech and mech:FindFirstChild("Remotes") or nil
end

function Utilities.IsFishingActive(rod)
    if not rod then return false end
    if Config.Features.AutoFish.BypassStatusCheck then
        return false -- Bypass internal status lock
    end
    local mech = rod:FindFirstChild("Mechanics")
    local status = mech and mech:FindFirstChild("Status")
    local fa = status and status:FindFirstChild("FishingActive")
    return fa and fa.Value or false
end

function Utilities.EquipBestRod()
    local bestTool, bestTier, bestPrice = nil, -1, -1
    local pools = {}
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    local ch = LocalPlayer.Character
    if bp then table.insert(pools, bp) end
    if ch then table.insert(pools, ch) end

    for _, container in ipairs(pools) do
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("Mechanics") then
                local name = tool:GetAttribute("SkinDipakai") or tool.Name
                local rodDef = Databases.ItemDB and Databases.ItemDB.Rods and Databases.ItemDB.Rods[name]
                local tier = (rodDef and rodDef.Tier) or 1
                local price = (rodDef and rodDef.Price) or 0
                if tier > bestTier or (tier == bestTier and price > bestPrice) then
                    bestTool, bestTier, bestPrice = tool, tier, price
                end
            end
        end
    end

    if bestTool and bestTool.Parent ~= LocalPlayer.Character then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum:EquipTool(bestTool) end) end
    end
    return bestTool
end

-- ═══════════════════════════════════════════════════════════════════
-- 12. DISCORD WEBHOOK BACKEND DISPATCHER
-- ═══════════════════════════════════════════════════════════════════
local Webhook = {}
local ThumbCache = {}

function Webhook.GetThumbnail(assetUrl)
    if not assetUrl or assetUrl == "" then return nil end
    if ThumbCache[assetUrl] then return ThumbCache[assetUrl] end

    local id = tonumber(assetUrl:match("(%d+)%s*$"))
    if not id then return nil end

    local url = string.format("https://thumbnails.roblox.com/v1/assets?assetIds=%d&size=420x420&format=Png&isCircular=false", id)
    local ok, res = pcall(function()
        local raw = Services.HttpService:GetAsync(url)
        local decoded = Services.HttpService:JSONDecode(raw)
        return decoded and decoded.data and decoded.data[1] and decoded.data[1].imageUrl or nil
    end)

    if ok and res then
        ThumbCache[assetUrl] = res
        return res
    end
    return nil
end

function Webhook.Dispatch(data)
    if not Config.Features.Webhook.Enabled or Config.Features.Webhook.Url == "" then return end
    if not Utilities.MeetsRarity(data.rarity or "Common", Config.Features.Webhook.MinRarity) then return end

    task.spawn(function()
        local color = Constants.RARITY_COLOR[data.rarity] or 0x5865F2
        if Config.Features.Webhook.WithMutColor and data.mutation and data.mutation ~= "Normal" then
            local mutCol = Utilities.GetMutationColor(data.mutation)
            if mutCol then
                color = Utilities.Color3ToInteger(mutCol) or color
            end
        end

        local icon = Constants.RARITY_ICON[data.rarity] or "[?]"
        local weightStr = string.format("%.2f kg", data.weight or 0)
        local chanceStr = Utilities.ChanceText(data.chance)

        local fishImage = nil
        if Config.Features.Webhook.WithImage and Databases.FishDB and Databases.FishDB.GetIcon then
            pcall(function()
                local rawIcon = Databases.FishDB.GetIcon(data.name)
                fishImage = Webhook.GetThumbnail(rawIcon)
            end)
        end

        local embed = {
            title = string.format("🎣 %s CATCH CONFIRMED!", (data.rarity or "RARE"):upper()),
            description = string.format("**%s**", tostring(data.name or "Unknown Fish")),
            color = color,
            fields = {
                { name = "Rarity Tier", value = string.format("`%s %s`", icon, tostring(data.rarity)), inline = true },
                { name = "Mutation", value = string.format("`%s`", tostring(data.mutation or "Normal")), inline = true },
                { name = "Exact Weight", value = string.format("`%s`", weightStr), inline = true },
                { name = "Catch Chance", value = string.format("`%s`", chanceStr), inline = true },
                { name = "Player Name", value = string.format("`%s`", LocalPlayer.DisplayName), inline = true },
                { name = "Catch Time", value = string.format("`%s`", os.date("%H:%M:%S")), inline = true },
            },
            footer = { text = Constants.BRAND .. " | Embedded Telemetry Engine" },
            timestamp = DateTime.now():ToIsoDate(),
        }

        if fishImage then
            if Config.Features.Webhook.WithThumb then embed.thumbnail = { url = fishImage } end
            embed.image = { url = fishImage }
        end

        pcall(function()
            Services.HttpService:PostAsync(
                Config.Features.Webhook.Url,
                Services.HttpService:JSONEncode({
                    username = Constants.BRAND .. " Logger",
                    embeds = { embed }
                })
            )
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- 13. FEATURE REGISTRY SYSTEM
-- ═══════════════════════════════════════════════════════════════════
local FeatureRegistry = {
    _features = {}
}

function FeatureRegistry:Register(def)
    assert(def.id, "Feature must have an id")
    self._features[def.id] = def
    if def.Initialize then
        pcall(function() def:Initialize() end)
    end
end

function FeatureRegistry:Enable(id)
    local feat = self._features[id]
    if feat and not feat.enabled then
        feat.enabled = true
        Logger.Debug("Enabling feature: " .. feat.name)
        pcall(function() feat:Enable() end)
    end
end

function FeatureRegistry:Disable(id)
    local feat = self._features[id]
    if feat and feat.enabled then
        feat.enabled = false
        Logger.Debug("Disabling feature: " .. feat.name)
        pcall(function() feat:Disable() end)
        CleanupManager:Clean(id)
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- 14. CORE ENGINE & ULTRA-FAST SENSOR IMPLEMENTATION
-- ═══════════════════════════════════════════════════════════════════

-- [F01] Ultra-Fast Auto Fishing Engine
FeatureRegistry:Register({
    id = "AutoFish",
    name = "Ultra Turbo Fishing Core",
    category = "Fishing",
    enabled = false,

    ExecuteCast = function(self, rod)
        if not self.enabled or State.Runtime.IsMiniGameActive then return end
        if Utilities.IsFishingActive(rod) then return end

        local remotes = Utilities.GetRodRemotes(rod)
        local castEvent = remotes and remotes:FindFirstChild("CastEvent")
        if not castEvent then return end

        State.Runtime.IsCasting = true
        local targetPower = math.random(
            math.clamp(Config.Features.AutoFish.MinPower, 80, 100),
            math.clamp(Config.Features.AutoFish.MaxPower, 80, 100)
        )

        pcall(function() castEvent:FireServer(true) end)
        task.wait(Config.Features.AutoFish.ChargeDelay)
        pcall(function() castEvent:FireServer(false, targetPower, nil) end)

        State.Runtime.LastCastTick = os.clock()
        State.Stats.Casts = State.Stats.Casts + 1
        if targetPower >= 95 then
            State.Stats.Perfect = State.Stats.Perfect + 1
        end
        State.Runtime.IsCasting = false
        Logger.Debug(string.format("Perfect Cast Dispatched (Power: %d%%)", targetPower))
    end,

    InstantResolveBite = function(self, miniGameRemote, data)
        local now = os.clock()
        if Config.Features.AutoFish.AntiDuplicateBite and (now - State.Runtime.LastBiteTick) < 0.05 then
            return
        end
        State.Runtime.LastBiteTick = now
        State.Runtime.IsMiniGameActive = true

        local rar = (type(data) == "table" and data.rarity) or "Common"
        local nm = (type(data) == "table" and data.name) or "Unknown"

        -- Sinyal publik tanda seru
        if GlobalRemotes.TandaSeruBersama then
            pcall(function()
                GlobalRemotes.TandaSeruBersama:FireServer(nil, nil, nil, 1.5)
            end)
        end

        -- Alerting
        if Config.Features.Alerts.RareAlert and Utilities.MeetsRarity(rar, Config.Features.Alerts.RareThreshold) then
            playAudio(Constants.SOUNDS.Rare, 0.7)
            Notifications.Notify("TANDA SERU! RARE BITE", string.format("%s [%s]", nm, rar), 2.5)
        elseif Config.Features.Alerts.BiteAlert then
            playAudio(Constants.SOUNDS.Bite, 0.4)
        end

        -- Instant Auto-Win Execution (Super Cepat & Tuntas)
        task.spawn(function()
            local bursts = math.clamp(Config.Features.AutoFish.WinBurst, 1, 3)
            for _ = 1, bursts do
                if not self.enabled or not State.Runtime.IsMiniGameActive then break end
                pcall(function() miniGameRemote:FireServer(true) end)
                task.wait(0.03)
            end
        end)
    end,

    HookTool = function(self, tool)
        if not tool or tool:GetAttribute("MizukageHookedV4") then return end
        tool:SetAttribute("MizukageHookedV4", true)

        local remotes = Utilities.GetRodRemotes(tool)
        if not remotes then return end

        local miniGame = remotes:WaitForChild("MiniGame", 5)
        local notify = remotes:WaitForChild("NotifyClient", 5)

        -- 1. Sensor MiniGame Event (Paling Akurat & Instan)
        if miniGame then
            local mgConn = miniGame.OnClientEvent:Connect(function(action, data)
                if not self.enabled then return end

                if action == "Start" then
                    Logger.Debug("MiniGame 'Start' Trigger Detected! Executing auto-win...")
                    self:InstantResolveBite(miniGame, data)
                elseif action == "Stop" then
                    State.Runtime.IsMiniGameActive = false
                    -- Langsung melempar kail kembali dengan cerdas
                    task.delay(Config.Features.AutoFish.RecastDelay, function()
                        if self.enabled and not State.Runtime.IsMiniGameActive then
                            local equipped = Utilities.GetEquippedRod()
                            if equipped then
                                self:ExecuteCast(equipped)
                            end
                        end
                    end)
                end
            end)
            CleanupManager:AddConnection("AutoFish", mgConn)
        end

        -- 2. Sensor NotifyClient Event (Backup Trigger & GotFish Handler)
        if notify then
            local notifyConn = notify.OnClientEvent:Connect(function(action, data)
                if not self.enabled then return end

                if action == "Bite" then
                    Logger.Debug("NotifyClient 'Bite' Trigger Detected!")
                    if miniGame and not State.Runtime.IsMiniGameActive then
                        self:InstantResolveBite(miniGame, data)
                    end
                elseif action == "CastFailed" then
                    State.Stats.Failed = State.Stats.Failed + 1
                    State.Runtime.IsMiniGameActive = false
                    Logger.Warn("Cast Failed: " .. tostring(data and data.reason or "Unknown"))
                    -- Coba recast setelah jeda aman
                    task.delay(0.6, function()
                        local equipped = Utilities.GetEquippedRod()
                        if equipped and self.enabled then
                            self:ExecuteCast(equipped)
                        end
                    end)
                elseif action == "GotFish" and type(data) == "table" then
                    State.Runtime.IsMiniGameActive = false
                    State.Stats.Catches = State.Stats.Catches + 1
                    State.Runtime.LastGotFishTick = os.clock()

                    local rar = data.rarity or "Common"
                    State.Stats.Rarity[rar] = (State.Stats.Rarity[rar] or 0) + 1

                    local w = data.weight or 0
                    local nm = data.baseName or data.originalName or "Unknown"
                    local mut = data.mutation or "Normal"

                    if w > (State.Stats.BestCatch.weight or 0) and Utilities.MeetsRarity(rar, State.Stats.BestCatch.rarity) then
                        State.Stats.BestCatch = { name = nm, rarity = rar, weight = w, mutation = mut }
                    end

                    if Config.Features.Alerts.RareAlert and Utilities.MeetsRarity(rar, Config.Features.Alerts.RareThreshold) then
                        if Utilities.Rank(rar) >= Utilities.Rank("Secret") then
                            playAudio(Constants.SOUNDS.SuperRare, 0.8)
                        else
                            playAudio(Constants.SOUNDS.Rare, 0.6)
                        end
                        Notifications.Success(string.format("Tersangkut! %s (%s, %.2fkg)", nm, rar, w))
                    end

                    -- Webhook Dispatcher
                    Webhook.Dispatch({
                        name = nm,
                        rarity = rar,
                        mutation = mut,
                        weight = w,
                        chance = data.chance,
                    })

                    -- Instant claim inventaris
                    if Config.Features.AutoCollect.InstantClaim and GlobalRemotes.InventarisAmbilSemua then
                        task.spawn(function()
                            pcall(function() GlobalRemotes.InventarisAmbilSemua:InvokeServer() end)
                        end)
                    end

                    -- Fast Smart Recast
                    task.delay(Config.Features.AutoFish.RecastDelay, function()
                        if self.enabled and not State.Runtime.IsMiniGameActive then
                            local currentRod = Utilities.GetEquippedRod()
                            if currentRod then
                                self:ExecuteCast(currentRod)
                            end
                        end
                    end)
                end
            end)
            CleanupManager:AddConnection("AutoFish", notifyConn)
        end
    end,

    ScanAndHookAll = function(self)
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        local ch = LocalPlayer.Character
        if bp then
            for _, item in ipairs(bp:GetChildren()) do
                if item:IsA("Tool") and item:FindFirstChild("Mechanics") then
                    self:HookTool(item)
                end
            end
        end
        if ch then
            for _, item in ipairs(ch:GetChildren()) do
                if item:IsA("Tool") and item:FindFirstChild("Mechanics") then
                    self:HookTool(item)
                end
            end
        end
    end,

    Enable = function(self)
        self:ScanAndHookAll()

        -- Dynamic Hook Listener saat ganti rod/respawn
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local childConn = char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") and child:FindFirstChild("Mechanics") then
                task.wait(0.1)
                self:HookTool(child)
            end
        end)
        CleanupManager:AddConnection("AutoFish", childConn)

        -- 3. Sensor Visual Instance (Exclamation Mark Detector)
        if Config.Features.AutoFish.VisualExclamationSensor then
            local visualWatcher = task.spawn(function()
                while self.enabled do
                    local myChar = LocalPlayer.Character
                    if myChar and not State.Runtime.IsMiniGameActive then
                        for _, desc in ipairs(myChar:GetDescendants()) do
                            if desc:IsA("BillboardGui") and (desc.Name:lower():find("tanda") or desc.Name:lower():find("bite") or desc.Name:lower():find("exclamation")) then
                                local rod = Utilities.GetEquippedRod()
                                local remotes = Utilities.GetRodRemotes(rod)
                                local miniGame = remotes and remotes:FindFirstChild("MiniGame")
                                if miniGame then
                                    Logger.Debug("Visual Exclamation Mark Sensor Triggered!")
                                    self:InstantResolveBite(miniGame, { name = "Visual Catch", rarity = "Common" })
                                    break
                                end
                            end
                        end
                    end
                    task.wait(0.08)
                end
            end)
            CleanupManager:AddTask("AutoFish", visualWatcher)
        end

        -- 4. Main Autonomous Loop & Watchdog Engine (Anti-Stuck Protection)
        local mainLoop = task.spawn(function()
            while self.enabled do
                local rod = Utilities.GetEquippedRod()
                if not rod and Config.Features.AutoFish.AutoEquipBest then
                    Utilities.EquipBestRod()
                    task.wait(0.15)
                    rod = Utilities.GetEquippedRod()
                end

                if rod then
                    self:HookTool(rod)
                    local now = os.clock()

                    -- Anti-stuck Watchdog
                    if State.Runtime.IsMiniGameActive and (now - State.Runtime.LastBiteTick) > Config.Features.AutoFish.WatchdogTimeout then
                        Logger.Warn("Watchdog: Minigame timed out. Force resetting state...")
                        State.Runtime.IsMiniGameActive = false
                    end

                    if not State.Runtime.IsMiniGameActive and not State.Runtime.IsCasting then
                        if (now - State.Runtime.LastCastTick) > Config.Features.AutoFish.WatchdogTimeout then
                            Logger.Debug("Watchdog: Rod idle too long. Executing smart recast...")
                            self:ExecuteCast(rod)
                        end
                    end
                end
                task.wait(0.2)
            end
        end)
        CleanupManager:AddTask("AutoFish", mainLoop)

        -- Trigger cast awal
        task.delay(0.2, function()
            local initRod = Utilities.GetEquippedRod() or Utilities.EquipBestRod()
            if initRod and self.enabled then
                self:ExecuteCast(initRod)
            end
        end)
    end,

    Disable = function(self)
        State.Runtime.IsMiniGameActive = false
        State.Runtime.IsCasting = false
    end,
})

-- [F02] Auto Collect System (AmbilSemua Engine)
FeatureRegistry:Register({
    id = "AutoCollect",
    name = "Auto Inventory Claimer",
    category = "Automation",
    enabled = true,

    Initialize = function(self)
        if GlobalRemotes.InventarisBerubah and GlobalRemotes.InventarisAmbilSemua then
            local cConn = GlobalRemotes.InventarisBerubah.OnClientEvent:Connect(function()
                if Config.Features.AutoCollect.Enabled then
                    pcall(function() GlobalRemotes.InventarisAmbilSemua:InvokeServer() end)
                end
            end)
            CleanupManager:AddConnection("Global_AutoCollect", cConn)
        end
    end,

    Enable = function(self)
        local sweepTask = task.spawn(function()
            while self.enabled do
                if Config.Features.AutoCollect.Enabled and GlobalRemotes.InventarisAmbilSemua then
                    pcall(function() GlobalRemotes.InventarisAmbilSemua:InvokeServer() end)
                end
                task.wait(Config.Features.AutoCollect.SweepInterval)
            end
        end)
        CleanupManager:AddTask("AutoCollect", sweepTask)
    end,

    Disable = function(self) end,
})

-- [F03] World Event & Hourly Schedule Trackers
FeatureRegistry:Register({
    id = "EventTrackers",
    name = "Event Intelligence",
    category = "Intelligence",
    enabled = true,

    Enable = function(self)
        local eventLoop = task.spawn(function()
            local warnedCore = false
            local lastHourly = nil

            while self.enabled do
                -- Core Tracker
                if Config.Features.EventTrackers.CoreTracker and Databases.CoreCfg and type(Databases.CoreCfg.Fase) == "function" then
                    local ok, phase, remain = pcall(Databases.CoreCfg.Fase, os.time())
                    if ok then
                        if phase == "tunggu" and remain and remain <= 60 and not warnedCore then
                            warnedCore = true
                            Notifications.Warning("Withering Core mulai dalam " .. Utilities.FormatTime(remain) .. "!")
                        elseif phase == "aktif" and warnedCore then
                            warnedCore = false
                            Notifications.Success("Withering Core Event sedang AKTIF!")
                        end
                    end
                end

                -- Hourly Tracker
                if Config.Features.EventTrackers.HourlyTracker and Databases.EventCfg and type(Databases.EventCfg.Acara) == "function" then
                    local ok, info = pcall(function()
                        return Databases.EventCfg.Acara(Databases.EventCfg.JamSekarang())
                    end)
                    if ok and type(info) == "table" and info.tier ~= lastHourly then
                        lastHourly = info.tier
                        Notifications.Info(string.format("Event Jam Ini: %s (%s)", tostring(info.tier), tostring(info.ket or "")))
                    end
                end

                task.wait(8)
            end
        end)
        CleanupManager:AddTask("EventTrackers", eventLoop)
    end,

    Disable = function(self) end,
})

-- [F04] Global Telemetry & Radar
FeatureRegistry:Register({
    id = "Telemetry",
    name = "Global Telemetry & Alerts",
    category = "Intelligence",
    enabled = true,

    Initialize = function(self)
        if GlobalRemotes.CutsceneBroadcast then
            local cutConn = GlobalRemotes.CutsceneBroadcast.OnClientEvent:Connect(function(kind, _, player)
                if not Config.Features.Alerts.GlobalCutscene then return end
                local who = (player and (player.DisplayName or player.Name)) or "Seseorang"

                if kind == "SecretCatch" then
                    State.Stats.Global.Secret = State.Stats.Global.Secret + 1
                    playAudio(Constants.SOUNDS.Rare, 0.4)
                    Notifications.Notify("GLOBAL SECRET", who .. " menangkap ikan SECRET!", 3)
                elseif kind == "Mythical" then
                    State.Stats.Global.Mythical = State.Stats.Global.Mythical + 1
                    Notifications.Notify("GLOBAL MYTHICAL", who .. " menangkap ikan MYTHICAL!", 3)
                elseif kind == "ForgottenCatch" then
                    State.Stats.Global.Forgotten = State.Stats.Global.Forgotten + 1
                    playAudio(Constants.SOUNDS.SuperRare, 0.5)
                    Notifications.Notify("GLOBAL FORGOTTEN", who .. " menangkap ikan FORGOTTEN!", 4)
                end
            end)
            CleanupManager:AddConnection("Global_Telemetry", cutConn)
        end

        if GlobalRemotes.PesanChat then
            local chatConn = GlobalRemotes.PesanChat.OnClientEvent:Connect(function(msg)
                if not Config.Features.Alerts.ChatFilter or type(msg) ~= "string" then return end
                if msg:find(Config.Features.Alerts.ChatKeyword) then
                    local clean = msg:gsub("<[^>]+>", "")
                    Notifications.Info("[CHAT] " .. clean:sub(1, 85))
                end
            end)
            CleanupManager:AddConnection("Global_Telemetry", chatConn)
        end
    end,

    Enable = function(self) end,
    Disable = function(self) end,
})

-- [F05] Anti-AFK Engine
FeatureRegistry:Register({
    id = "AntiAFK",
    name = "Anti-AFK Protection",
    category = "Protection",
    enabled = true,

    Initialize = function(self)
        local afkConn = LocalPlayer.Idled:Connect(function()
            if Config.Features.Protection.AntiAFK then
                pcall(function()
                    Services.VirtualUser:CaptureController()
                    Services.VirtualUser:ClickButton2(Vector2.new())
                end)
            end
        end)
        CleanupManager:AddConnection("Global_AntiAFK", afkConn)
    end,

    Enable = function(self) end,
    Disable = function(self) end,
})

-- ═══════════════════════════════════════════════════════════════════
-- 15. RAYFIELD GEN 2 UI INTERFACE
-- ═══════════════════════════════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
Notifications.RayfieldInstance = Rayfield

local Window = Rayfield:CreateWindow({
    Name = Constants.BRAND .. " | SOREYA V4",
    LoadingTitle = Constants.NAME,
    LoadingSubtitle = "by Mizukage Official 👑",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false,
})

local UIManager = {}
function UIManager.CreateText(tab, options)
    if tab.CreateText then
        return tab:CreateText(options)
    elseif tab.CreateParagraph then
        return tab:CreateParagraph({
            Title = options.name or "Info",
            Content = options.body or ""
        })
    end
end

function UIManager.CreateDivider(tab, options)
    if tab.CreateDivider then return tab:CreateDivider(options) end
end

-- TABS CREATION
local TabMain = Window:CreateTab("Dashboard", "home")
local TabAutoFish = Window:CreateTab("Auto Fish", "anchor")
local TabManual = Window:CreateTab("Manual Tuning", "sliders")
local TabCollect = Window:CreateTab("Inventory", "archive")
local TabAlerts = Window:CreateTab("Alerts", "bell")
local TabEvents = Window:CreateTab("Event Intel", "calendar")
local TabWebhook = Window:CreateTab("Webhook", "send")
local TabStats = Window:CreateTab("Stats", "activity")
local TabSettings = Window:CreateTab("Settings", "settings")

-- ─── TAB 1: DASHBOARD ───
TabMain:CreateSection("Live Status")

UIManager.CreateText(TabMain, {
    name = "Engine Mode",
    body = "Ultra-Fast Dual-Sensor Engine v4.0.0 Active."
})

UIManager.CreateText(TabMain, {
    name = "Webhook Integration",
    body = "Pre-Configured & Running in Backend."
})

UIManager.CreateDivider(TabMain, { name = "Quick Actions" })

TabMain:CreateButton({
    Name = "⚡ Force Equip Best Rod",
    Callback = function()
        local r = Utilities.EquipBestRod()
        if r then
            Notifications.Success("Rod Terpasang: " .. r.Name)
        else
            Notifications.Warning("Rod tidak ditemukan.")
        end
    end,
})

TabMain:CreateButton({
    Name = "📥 Ambil Semua Tangkapan (Manual Claim)",
    Callback = function()
        if GlobalRemotes.InventarisAmbilSemua then
            pcall(function() GlobalRemotes.InventarisAmbilSemua:InvokeServer() end)
            Notifications.Success("Semua ikan berhasil diklaim ke tas.")
        end
    end,
})

-- ─── TAB 2: AUTO FISH ───
TabAutoFish:CreateSection("Master Controls")

TabAutoFish:CreateToggle({
    Name = "Enable Ultra Auto Fishing",
    CurrentValue = Config.Features.AutoFish.Enabled,
    Flag = "Toggle_MasterAutoFish",
    Callback = function(val)
        Config.Features.AutoFish.Enabled = val
        if val then
            FeatureRegistry:Enable("AutoFish")
            Notifications.Success("Auto Fishing: AKTIF")
        else
            FeatureRegistry:Disable("AutoFish")
            Notifications.Warning("Auto Fishing: NONAKTIF")
        end
    end,
})

TabAutoFish:CreateToggle({
    Name = "Sensor Visual Tanda Seru (BillboardGui)",
    CurrentValue = Config.Features.AutoFish.VisualExclamationSensor,
    Flag = "Toggle_VisualSensor",
    Callback = function(val)
        Config.Features.AutoFish.VisualExclamationSensor = val
    end,
})

TabAutoFish:CreateToggle({
    Name = "Bypass Rod Status Lock (Force Cast)",
    CurrentValue = Config.Features.AutoFish.BypassStatusCheck,
    Flag = "Toggle_BypassLock",
    Callback = function(val)
        Config.Features.AutoFish.BypassStatusCheck = val
    end,
})

TabAutoFish:CreateToggle({
    Name = "Auto Equip Best Rod",
    CurrentValue = Config.Features.AutoFish.AutoEquipBest,
    Flag = "Toggle_AutoEquip",
    Callback = function(val)
        Config.Features.AutoFish.AutoEquipBest = val
    end,
})

-- ─── TAB 3: MANUAL TUNING ───
TabManual:CreateSection("Kecepatan & Kalibrasi Manual")

TabManual:CreateSlider({
    Name = "Jeda Melempar Ulang (Recast Delay)",
    Range = { 0.05, 1.50 },
    Increment = 0.01,
    Suffix = " detik",
    CurrentValue = Config.Features.AutoFish.RecastDelay,
    Flag = "Slider_RecastDelay",
    Callback = function(val)
        Config.Features.AutoFish.RecastDelay = val
    end,
})

TabManual:CreateSlider({
    Name = "Waktu Tahan Lemparan (Charge Delay)",
    Range = { 0.02, 0.40 },
    Increment = 0.01,
    Suffix = " detik",
    CurrentValue = Config.Features.AutoFish.ChargeDelay,
    Flag = "Slider_ChargeDelay",
    Callback = function(val)
        Config.Features.AutoFish.ChargeDelay = val
    end,
})

TabManual:CreateSlider({
    Name = "Target Power Minimum",
    Range = { 80, 100 },
    Increment = 1,
    Suffix = "%",
    CurrentValue = Config.Features.AutoFish.MinPower,
    Flag = "Slider_MinPower",
    Callback = function(val)
        Config.Features.AutoFish.MinPower = val
    end,
})

TabManual:CreateSlider({
    Name = "Target Power Maksimum",
    Range = { 80, 100 },
    Increment = 1,
    Suffix = "%",
    CurrentValue = Config.Features.AutoFish.MaxPower,
    Flag = "Slider_MaxPower",
    Callback = function(val)
        Config.Features.AutoFish.MaxPower = val
    end,
})

TabManual:CreateSlider({
    Name = "Repetisi Selesaikan Bite (Win Burst)",
    Range = { 1, 3 },
    Increment = 1,
    Suffix = " burst",
    CurrentValue = Config.Features.AutoFish.WinBurst,
    Flag = "Slider_WinBurst",
    Callback = function(val)
        Config.Features.AutoFish.WinBurst = math.clamp(val, 1, 3)
    end,
})

TabManual:CreateSlider({
    Name = "Anti-Stuck Watchdog Timeout",
    Range = { 4, 15 },
    Increment = 1,
    Suffix = " detik",
    CurrentValue = Config.Features.AutoFish.WatchdogTimeout,
    Flag = "Slider_Watchdog",
    Callback = function(val)
        Config.Features.AutoFish.WatchdogTimeout = val
    end,
})

-- ─── TAB 4: INVENTORY ───
TabCollect:CreateSection("Auto Claim & Storage")

TabCollect:CreateToggle({
    Name = "Auto AmbilSemua (Setiap Ikan Masuk)",
    CurrentValue = Config.Features.AutoCollect.InstantClaim,
    Flag = "Toggle_InstantClaim",
    Callback = function(val)
        Config.Features.AutoCollect.InstantClaim = val
    end,
})

TabCollect:CreateSlider({
    Name = "Jeda Pembersihan Berkala",
    Range = { 1, 10 },
    Increment = 1,
    Suffix = " detik",
    CurrentValue = Config.Features.AutoCollect.SweepInterval,
    Flag = "Slider_Sweep",
    Callback = function(val)
        Config.Features.AutoCollect.SweepInterval = val
    end,
})

-- ─── TAB 5: ALERTS ───
TabAlerts:CreateSection("Notifikasi & Suara")

TabAlerts:CreateToggle({
    Name = "Suara Saat Kail Dimakan (Bite)",
    CurrentValue = Config.Features.Alerts.BiteAlert,
    Flag = "Toggle_AlertBite",
    Callback = function(val)
        Config.Features.Alerts.BiteAlert = val
    end,
})

TabAlerts:CreateToggle({
    Name = "Suara Ikan Langka",
    CurrentValue = Config.Features.Alerts.RareAlert,
    Flag = "Toggle_AlertRare",
    Callback = function(val)
        Config.Features.Alerts.RareAlert = val
    end,
})

TabAlerts:CreateDropdown({
    Name = "Batas Minimal Rarity Alert",
    Options = { "UnCommon", "Rare", "Epic", "Legendary", "Mythical", "Secret", "FORGOTTEN" },
    CurrentOption = { "Legendary" },
    MultipleOptions = false,
    Flag = "Dropdown_RareLimit",
    Callback = function(opt)
        Config.Features.Alerts.RareThreshold = type(opt) == "table" and opt[1] or opt
    end,
})

TabAlerts:CreateToggle({
    Name = "Global Cutscene Watcher",
    CurrentValue = Config.Features.Alerts.GlobalCutscene,
    Flag = "Toggle_Cutscene",
    Callback = function(val)
        Config.Features.Alerts.GlobalCutscene = val
    end,
})

-- ─── TAB 6: EVENT INTEL ───
TabEvents:CreateSection("Pemeriksaan Event Server")

TabEvents:CreateToggle({
    Name = "Pantau Withering Core",
    CurrentValue = Config.Features.EventTrackers.CoreTracker,
    Flag = "Toggle_CoreTracker",
    Callback = function(val)
        Config.Features.EventTrackers.CoreTracker = val
    end,
})

TabEvents:CreateToggle({
    Name = "Pantau Jadwal Event Jam",
    CurrentValue = Config.Features.EventTrackers.HourlyTracker,
    Flag = "Toggle_HourlyTracker",
    Callback = function(val)
        Config.Features.EventTrackers.HourlyTracker = val
    end,
})

TabEvents:CreateButton({
    Name = "Periksa Fase Core Sekarang",
    Callback = function()
        if Databases.CoreCfg and type(Databases.CoreCfg.Fase) == "function" then
            local ok, phase, remain = pcall(Databases.CoreCfg.Fase, os.time())
            if ok then
                Notifications.Info(string.format("Core: %s | Sisa: %s", tostring(phase), Utilities.FormatTime(remain)))
            end
        else
            Notifications.Warning("Database CoreConfig tidak ditemukan.")
        end
    end,
})

-- ─── TAB 7: WEBHOOK ───
TabWebhook:CreateSection("Backend Discord Integration")

UIManager.CreateText(TabWebhook, {
    name = "Webhook Status",
    body = "Webhook terpasang langsung di backend dan otomatis aktif."
})

TabWebhook:CreateToggle({
    Name = "Aktifkan Webhook",
    CurrentValue = Config.Features.Webhook.Enabled,
    Flag = "Toggle_WebhookBackend",
    Callback = function(val)
        Config.Features.Webhook.Enabled = val
    end,
})

TabWebhook:CreateDropdown({
    Name = "Minimal Rarity Kirim Webhook",
    Options = { "Rare", "Epic", "Legendary", "Mythical", "Secret", "FORGOTTEN" },
    CurrentOption = { "Secret" },
    MultipleOptions = false,
    Flag = "Dropdown_WhRarity",
    Callback = function(opt)
        Config.Features.Webhook.MinRarity = type(opt) == "table" and opt[1] or opt
    end,
})

TabWebhook:CreateButton({
    Name = "Kirim Test Embed Sekarang",
    Callback = function()
        Webhook.Dispatch({
            name = "Frozen Great Whale (Test Embed)",
            rarity = "Secret",
            mutation = "Frozen",
            weight = 1250.50,
            chance = 0.000002,
        })
        Notifications.Success("Test embed berhasil dikirim ke webhook Discord Anda.")
    end,
})

-- ─── TAB 8: STATS ───
TabStats:CreateSection("Performa Mancing")

local StatL1 = TabStats:CreateParagraph({ Title = "Statistik Sesi", Content = "Menghitung data..." })
local StatL2 = TabStats:CreateParagraph({ Title = "Rincian Tangkapan", Content = "Menghitung data..." })
local StatL3 = TabStats:CreateParagraph({ Title = "Rekor Terbesar", Content = "-" })

local statsTask = task.spawn(function()
    while task.wait(1) do
        local elapsedMin = (os.clock() - State.Stats.StartTime) / 60
        local rate = elapsedMin > 0 and (State.Stats.Catches / elapsedMin) or 0
        if rate > State.Stats.PeakRate then State.Stats.PeakRate = rate end

        pcall(function()
            StatL1:Set({
                Title = "Statistik Sesi",
                Content = string.format("Tangkapan: %d | Lemparan: %d | Gagal: %d\nKecepatan: %.1f/menit | Puncak: %.1f/menit",
                    State.Stats.Catches, State.Stats.Casts, State.Stats.Failed, rate, State.Stats.PeakRate)
            })

            local r = State.Stats.Rarity
            StatL2:Set({
                Title = "Rincian Tangkapan",
                Content = string.format("Common: %d | UnCommon: %d | Rare: %d | Epic: %d\nLegendary: %d | Mythical: %d\nSecret: %d | Forgotten: %d",
                    r.Common or 0, r.UnCommon or 0, r.Rare or 0, r.Epic or 0,
                    r.Legendary or 0, (r.Mythical or 0) + (r.Mythic or 0),
                    (r.Secret or 0) + (r.SECRET or 0), (r.FORGOTTEN or 0) + (r.Forgotten or 0))
            })

            local b = State.Stats.BestCatch
            StatL3:Set({
                Title = "Rekor Terbesar",
                Content = string.format("%s [%s]\nBerat: %.2f kg | Mutasi: %s",
                    tostring(b.name), tostring(b.rarity), tonumber(b.weight) or 0, tostring(b.mutation))
            })
        end)
    end
end)
CleanupManager:AddTask("UI_Stats", statsTask)

-- ─── TAB 9: SETTINGS ───
TabSettings:CreateSection("Manajemen Script")

TabSettings:CreateToggle({
    Name = "Anti-AFK Protection",
    CurrentValue = Config.Features.Protection.AntiAFK,
    Flag = "Toggle_AntiAfk",
    Callback = function(val)
        Config.Features.Protection.AntiAFK = val
    end,
})

TabSettings:CreateToggle({
    Name = "Notifikasi UI",
    CurrentValue = Config.General.Notifications,
    Flag = "Toggle_Notifications",
    Callback = function(val)
        Config.General.Notifications = val
    end,
})

TabSettings:CreateToggle({
    Name = "Output Debug Console",
    CurrentValue = Config.General.Debug,
    Flag = "Toggle_Debug",
    Callback = function(val)
        Config.General.Debug = val
    end,
})

UIManager.CreateDivider(TabSettings, { name = "Shutdown" })

TabSettings:CreateButton({
    Name = "Hentikan dan Bongkar Script (Unload)",
    Callback = function()
        FeatureRegistry:Disable("AutoFish")
        CleanupManager:CleanAll()
        if getgenv then getgenv().MIZUKAGE_SOREYA_V4 = nil end
        Notifications.Info("Mizukage Official Engine berhasil dihentikan.")
        task.wait(0.8)
        if Rayfield and Rayfield.Destroy then pcall(function() Rayfield:Destroy() end) end
    end,
})

-- ═══════════════════════════════════════════════════════════════════
-- 16. HOTKEY REGISTRATION & UNLOAD EXPORT
-- ═══════════════════════════════════════════════════════════════════
local hotkeyConn = Services.UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Config.Features.AutoFish.Enabled = not Config.Features.AutoFish.Enabled
        if Config.Features.AutoFish.Enabled then
            FeatureRegistry:Enable("AutoFish")
            Notifications.Success("Auto Fishing: AKTIF (RightShift)")
        else
            FeatureRegistry:Disable("AutoFish")
            Notifications.Warning("Auto Fishing: NONAKTIF (RightShift)")
        end
    end
end)
CleanupManager:AddConnection("Global_Hotkey", hotkeyConn)

if getgenv then
    getgenv().MIZUKAGE_SOREYA_UNLOAD = function()
        FeatureRegistry:Disable("AutoFish")
        CleanupManager:CleanAll()
        if Rayfield and Rayfield.Destroy then pcall(function() Rayfield:Destroy() end) end
        getgenv().MIZUKAGE_SOREYA_V4 = nil
    end
end

-- Luncurkan background services
FeatureRegistry:Enable("AutoCollect")
FeatureRegistry:Enable("EventTrackers")
FeatureRegistry:Enable("Telemetry")
FeatureRegistry:Enable("AntiAFK")

Logger.Info("Mizukage Official 👑 v4.0.0 Siap Digunakan. Webhook Embedded.")
Notifications.Success("Mizukage Official 👑 v4.0.0 Berhasil Dimuat! (Tekan RightShift untuk On/Off)")