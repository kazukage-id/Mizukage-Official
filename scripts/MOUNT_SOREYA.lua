--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                    MIZUKAGE OFFICIAL 👑                          ║
    ║             End-To-End Automation & QA Suite                     ║
    ║        Game: UPD_PET_MOUNT_SOREYA (Place: 118517641508250)       ║
    ║                     Release Build: 5.0.1                         ║
    ║        IN-DEPTH FORENSIC RE-ENGINEERED MASTER SUITE (FIXED)      ║
    ║  Patch Log:                                                      ║
    ║   • Removed fatal `return Webhook` (chunk killer)                ║
    ║   • Added Webhook.Debug config field                             ║
    ║   • HTTP-enabled guard for thumbnail fetcher                     ║
    ║   • Anti-stuck process queue + guard counter                     ║
    ║   • Optimized exclamation sensor (CPU throttle)                  ║
    ║   • Fixed BestCatch rarity comparison logic                      ║
    ║   • Tracked burst threads in CleanupManager                      ║
    ║   • Race-guard watchdog (IsCastingLock)                          ║
    ║   • Nil-guard EquipBestRod                                       ║
    ║   • Anti-negative stats rate                                     ║
    ║   • Rayfield double-destroy guard                                ║
    ║   • ChanceText NaN/Inf guard                                     ║
    ║   • Rarity case normalization helper                             ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════════
-- 01. BOOTSTRAP & SINGLETON LIFECYCLE GUARD
-- ═══════════════════════════════════════════════════════════════════
if getgenv and getgenv().MIZUKAGE_SOREYA_V5 then
    warn("[Mizukage Official 👑] Previous instance active. Initiating purge...")
    if getgenv().MIZUKAGE_SOREYA_UNLOAD then
        pcall(getgenv().MIZUKAGE_SOREYA_UNLOAD)
    end
end

if getgenv then
    getgenv().MIZUKAGE_SOREYA_V5 = true
end

-- ═══════════════════════════════════════════════════════════════════
-- 02. CONSTANTS & METADATA
-- ═══════════════════════════════════════════════════════════════════
local Constants = {
    NAME = "Mizukage Official",
    BRAND = "Mizukage Official 👑",
    VERSION = "5.0.1",
    BUILD = "TeamMizu🔰 Release",
    TARGET_PLACE_ID = 118517641508250,

    DEFAULT_WEBHOOK = "https://discord.com/api/webhooks/1549632270057472000/45I-jW8-qD85IHvbx02p6oqfF42dMPaHxyOLg-mS1eHEkDTR_8E9ZQlTzckVrDQO2sb7",

    DEFAULT_TIMINGS = {
        PRE_CAST_DELAY = 0.35,
        CHARGE_HOLD_DURATION = 0.50,
        CAST_POWER = 100,
        POST_CAST_SETTLE = 0.80,
        WIN_BURST_COUNT = 1,
        WIN_BURST_INTERVAL = 0.04,
        RECAST_COOLDOWN = 0.55,
        WATCHDOG_TIMEOUT = 10.0,
        COLLECT_INTERVAL = 2.5,
    },

    RARITY_RANK = {
        Common = 1, UnCommon = 2, Uncommon = 2, Rare = 3, Epic = 4,
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
    FishDB = nil, ItemDB = nil, MutasiDB = nil, TierDB = nil,
    CoreCfg = nil, EventCfg = nil,
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
-- 05. GLOBAL REMOTES RESOLUTION
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
        if idx then GlobalRemotes.IndexBerubah = idx:FindFirstChild("IndexBerubah") end
        local shop = rem:FindFirstChild("Toko")
        if shop then GlobalRemotes.DaftarSkin = shop:FindFirstChild("DaftarSkin") end
        local admin = rem:FindFirstChild("Admin")
        if admin then GlobalRemotes.PesanChat = admin:FindFirstChild("PesanChat") end
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
            AutoEquipRod = true,
            PreCastDelay = Constants.DEFAULT_TIMINGS.PRE_CAST_DELAY,
            ChargeHoldDuration = Constants.DEFAULT_TIMINGS.CHARGE_HOLD_DURATION,
            CastPower = Constants.DEFAULT_TIMINGS.CAST_POWER,
            PostCastSettle = Constants.DEFAULT_TIMINGS.POST_CAST_SETTLE,
            WinBurstCount = Constants.DEFAULT_TIMINGS.WIN_BURST_COUNT,
            WinBurstInterval = Constants.DEFAULT_TIMINGS.WIN_BURST_INTERVAL,
            RecastCooldown = Constants.DEFAULT_TIMINGS.RECAST_COOLDOWN,
            WatchdogTimeout = Constants.DEFAULT_TIMINGS.WATCHDOG_TIMEOUT,
            ExclamationSensor = true,
            FastCancelMiniGame = true,
        },
        AutoCollect = {
            Enabled = true,
            InstantClaim = true,
            CollectInterval = Constants.DEFAULT_TIMINGS.COLLECT_INTERVAL,
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
            Enabled = true,
            Url = Constants.DEFAULT_WEBHOOK,
            MinRarity = "Secret",
            WithThumb = true,
            WithImage = true,
            WithMutColor = true,
            Debug = false, -- [FIX #2]
        },
        Protection = {
            AntiAFK = true,
        }
    }
}

-- ═══════════════════════════════════════════════════════════════════
-- 07. DETERMINISTIC STATE MACHINE & TELEMETRY
-- ═══════════════════════════════════════════════════════════════════
local FishingState = {
    IDLE = "IDLE", CHARGING = "CHARGING", CASTED = "CASTED",
    BITTEN = "BITTEN", RESOLVING = "RESOLVING", POST_CATCH = "POST_CATCH",
}

local State = {
    Current = FishingState.IDLE,
    ActiveCycleToken = 0,
    LastStateChange = os.clock(),
    LastCatchTick = 0,
    LastCastTick = 0,
    IsCastingLock = false,

    Stats = {
        Catches = 0, Casts = 0, Failed = 0, Perfect = 0,
        StartTime = os.clock(), PeakRate = 0,
        BestCatch = { name = "-", rarity = "-", weight = 0, mutation = "-" },
        Rarity = {
            Common = 0, UnCommon = 0, Rare = 0, Epic = 0,
            Legendary = 0, Mythical = 0, Secret = 0, FORGOTTEN = 0
        },
        Global = { Secret = 0, Mythical = 0, Forgotten = 0 }
    }
}

local function transitionState(newState)
    State.Current = newState
    State.LastStateChange = os.clock()
end

-- ═══════════════════════════════════════════════════════════════════
-- 08. LOGGER
-- ═══════════════════════════════════════════════════════════════════
local Logger = {}
function Logger.Info(msg) print(string.format("[%s] [INFO] %s", Constants.NAME, tostring(msg))) end
function Logger.Debug(msg)
    if Config.General.Debug then
        print(string.format("[%s] [DEBUG] [%s] %s", Constants.NAME, State.Current, tostring(msg)))
    end
end
function Logger.Warn(msg) warn(string.format("[%s] [WARN] %s", Constants.NAME, tostring(msg))) end
function Logger.Error(msg) warn(string.format("[%s] [ERROR] %s", Constants.NAME, tostring(msg))) end

-- ═══════════════════════════════════════════════════════════════════
-- 09. NOTIFICATION & AUDIO
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
        pcall(function()
            Services.StarterGui:SetCore("SendNotification", {
                Title = title, Text = message, Duration = duration,
            })
        end)
    end
end

function Notifications.Info(msg) Notifications.Notify("Info", msg, 3) end
function Notifications.Success(msg) Notifications.Notify("Sukses", msg, 3) end
function Notifications.Warning(msg) Notifications.Notify("Perhatian", msg, 4) end
function Notifications.Error(msg) Notifications.Notify("Error", msg, 5) end

local function playAudio(id, vol)
    task.spawn(function()
        local ok, snd = pcall(function()
            local s = Instance.new("Sound")
            s.SoundId = id
            s.Volume = vol or 0.6
            s.Parent = Services.SoundService
            s:Play()
            return s
        end)
        if ok and snd then
            task.wait(3.5)
            pcall(function() snd:Destroy() end)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════
-- 10. LIFECYCLE & CLEANUP MANAGER
-- ═══════════════════════════════════════════════════════════════════
local CleanupManager = { _connections = {}, _tasks = {} }

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
-- 11. CALCULATION & INVENTORY HELPERS
-- ═══════════════════════════════════════════════════════════════════
local Utilities = {}

-- [FIX #13] Rarity normalization
function Utilities.NormalizeRarity(r)
    if type(r) ~= "string" then return "Common" end
    r = r:gsub("^%s+", ""):gsub("%s+$", "")
    if r:upper() == "FORGOTTEN" then return "FORGOTTEN" end
    if r:upper() == "SECRET" then return "SECRET" end
    return r
end

function Utilities.Rank(r)
    return Constants.RARITY_RANK[Utilities.NormalizeRarity(r)] or 0
end

function Utilities.MeetsRarity(r, threshold)
    return Utilities.Rank(r) >= Utilities.Rank(threshold)
end

-- [FIX #12] ChanceText NaN/Inf guard
function Utilities.ChanceText(chance)
    local c = tonumber(chance)
    if not c or c <= 0 then return "?" end
    local val = 1 / c
    if val ~= val or val == math.huge then return "?" end
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
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") and t:FindFirstChild("Mechanics") then
            return t
        end
    end
    return nil
end

function Utilities.GetRodInBackpack()
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not bp then return nil end
    for _, t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") and t:FindFirstChild("Mechanics") then
            return t
        end
    end
    return nil
end

function Utilities.EnsureRodEquipped()
    local equipped = Utilities.GetEquippedRod()
    if equipped then return equipped end
    local inBackpack = Utilities.GetRodInBackpack()
    if inBackpack then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function() hum:EquipTool(inBackpack) end)
            task.wait(0.25)
            return Utilities.GetEquippedRod()
        end
    end
    return nil
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

    -- [FIX #9] Nil guard for character
    if bestTool then
        local ch2 = LocalPlayer.Character
        if ch2 and bestTool.Parent ~= ch2 then
            local hum = ch2:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function() hum:EquipTool(bestTool) end)
                task.wait(0.25)
            end
        end
    end
    return bestTool
end

function Utilities.GetRodRemotes(rod)
    if not rod then return nil end
    local mech = rod:FindFirstChild("Mechanics")
    return mech and mech:FindFirstChild("Remotes") or nil
end

-- ═══════════════════════════════════════════════════════════════════
-- 12. BACKEND DISCORD WEBHOOK ENGINE — V2 PRO (PATCHED)
-- ═══════════════════════════════════════════════════════════════════
local Webhook = {}
local ThumbCache = {}
local SendQueue = {}
local IsProcessing = false
local RecentHashes = {}
local HASH_TTL = 30

local function dbg(...)
    if Config.Features.Webhook and Config.Features.Webhook.Debug then
        print("[WEBHOOK]", ...)
    end
end

local function hash(str)
    local h = 5381
    for i = 1, #str do
        h = ((h * 33) + str:byte(i)) % 2147483647
    end
    return tostring(h)
end

local function isDuplicate(key)
    local now = os.time()
    for k, t in pairs(RecentHashes) do
        if now - t > HASH_TTL then RecentHashes[k] = nil end
    end
    if RecentHashes[key] then return true end
    RecentHashes[key] = now
    return false
end

local function pad2(n) return string.format("%02d", n) end

local function utcTime()
    return pad2(os.date("!%H")) .. ":" .. pad2(os.date("!%M")) .. ":" .. pad2(os.date("!%S")) .. " UTC"
end

-- [FIX #3] Thumbnail fetcher with HTTP guard
function Webhook.GetThumbnail(assetUrl)
    if not assetUrl or assetUrl == "" then return nil end
    if ThumbCache[assetUrl] then return ThumbCache[assetUrl] end

    if not Services.HttpService.HttpEnabled then
        dbg("HttpService disabled — skip thumbnail")
        return nil
    end

    local id = tonumber(tostring(assetUrl):match("(%d+)%s*$"))
    if not id then
        dbg("Asset ID tidak valid:", tostring(assetUrl))
        return nil
    end

    local url = string.format(
        "https://thumbnails.roblox.com/v1/assets?assetIds=%d&size=420x420&format=Png&isCircular=false",
        id
    )

    local ok, res = pcall(function()
        local raw = Services.HttpService:GetAsync(url)
        local decoded = Services.HttpService:JSONDecode(raw)
        return decoded and decoded.data and decoded.data[1] and decoded.data[1].imageUrl or nil
    end)

    if ok and res then
        ThumbCache[assetUrl] = res
        return res
    end
    dbg("Thumbnail gagal:", assetUrl)
    return nil
end

local function buildEmbed(data, player)
    local W = Config.Features.Webhook
    local rarity = Utilities.NormalizeRarity(data.rarity or "Unknown")

    local color = Constants.RARITY_COLOR[rarity] or 0x55A2FF
    if W.WithMutColor and data.mutation and data.mutation ~= "Normal" then
        local mutCol = Utilities.GetMutationColor(data.mutation)
        if mutCol then
            color = Utilities.Color3ToInteger(mutCol) or color
        end
    end

    local icon = Constants.RARITY_ICON[rarity] or "❓"
    local weight = string.format("%.2f kg", tonumber(data.weight) or 0)
    local chance = Utilities.ChanceText(data.chance)
    local playerName = (player and (player.DisplayName or player.Name)) or "Unknown"

    local fishImage = nil
    if W.WithImage and Databases.FishDB and Databases.FishDB.GetIcon then
        pcall(function()
            local rawIcon = Databases.FishDB.GetIcon(data.name)
            fishImage = Webhook.GetThumbnail(rawIcon)
        end)
    end

    local mutText = (data.mutation and data.mutation ~= "Normal")
        and ("✨ " .. tostring(data.mutation))
        or  "➖ Normal"

    local embed = {
        title = string.format("%s TANGKAPAN %s!", icon, rarity:upper()),
        description = string.format("### 🐟 **%s**\n> Ditangkap oleh **%s**", tostring(data.name or "Unknown"), playerName),
        color = color,
        fields = {
            { name = "🏆 Rarity", value = ("```%s```"):format(rarity), inline = true },
            { name = "🧬 Mutasi", value = ("```%s```"):format(mutText), inline = true },
            { name = "⚖️ Berat", value = ("```%s```"):format(weight), inline = true },
            { name = "🎲 Chance", value = ("```%s```"):format(chance), inline = true },
            { name = "👤 Pemain", value = ("```%s```"):format(playerName), inline = true },
            { name = "🕐 Waktu", value = ("```%s```"):format(utcTime()), inline = true },
        },
        footer = { text = Constants.BRAND .. " • Telemetry Engine v2 (patched)" },
        timestamp = DateTime.now():ToIsoDate(),
    }

    if fishImage then
        if W.WithThumb then embed.thumbnail = { url = fishImage } end
        if W.WithImage then embed.image = { url = fishImage } end
    end

    return embed
end

-- [FIX #4] Anti-stuck process queue
local function processQueue()
    if IsProcessing then return end
    IsProcessing = true

    task.spawn(function()
        local guardIter = 0
        while #SendQueue > 0 do
            guardIter = guardIter + 1
            if guardIter > 100 then
                warn("[WEBHOOK] Queue guard tripped — reset")
                break
            end

            local job = table.remove(SendQueue, 1)
            if job then
                local ok, err = pcall(function()
                    Services.HttpService:PostAsync(
                        job.url, job.payload, Enum.HttpContentType.ApplicationJson
                    )
                end)

                if not ok then
                    local errStr = tostring(err)
                    warn("[WEBHOOK] Gagal kirim:", errStr)
                    if errStr:find("429") and (job.retries or 0) < 3 then
                        job.retries = (job.retries or 0) + 1
                        job.retryAfter = (job.retryAfter or 3) * 2
                        dbg(("Rate limit — retry #%d dalam %ds"):format(job.retries, job.retryAfter))
                        task.delay(job.retryAfter, function()
                            table.insert(SendQueue, 1, job)
                        end)
                    end
                else
                    dbg("✅ Terkirim:", job.label)
                end
            end
            task.wait(1.2)
        end
        IsProcessing = false
    end)
end

function Webhook.Dispatch(data, player)
    local W = Config.Features.Webhook

    if not W.Enabled then return end
    if not W.Url or W.Url == "" then return end
    if not W.Url:match("^https://discord%.com/api/webhooks/") then
        warn("[WEBHOOK] ❌ URL tidak valid!")
        return
    end

    local rarity = Utilities.NormalizeRarity(data.rarity or "Common")
    if not Utilities.MeetsRarity(rarity, W.MinRarity or "Secret") then
        dbg(("Skip '%s' — rarity '%s' di bawah '%s'"):format(
            tostring(data.name), rarity, W.MinRarity or "Secret"
        ))
        return
    end

    local pName = (player and (player.Name or player.DisplayName))
        or (LocalPlayer and (LocalPlayer.Name or LocalPlayer.DisplayName))
        or "Unknown"
    local key = hash(tostring(data.name) .. "|" .. rarity .. "|" .. pName)
    if isDuplicate(key) then
        dbg("Duplicate — skip:", data.name, rarity)
        return
    end

    local resolvedPlayer = player or LocalPlayer

    local embed = buildEmbed(data, resolvedPlayer)
    local payload = {
        username = Constants.BRAND .. " Telemetry",
        avatar_url = nil,
        embeds = { embed },
    }

    local okEnc, encoded = pcall(function()
        return Services.HttpService:JSONEncode(payload)
    end)

    if not okEnc or not encoded then
        warn("[WEBHOOK] ❌ Encode gagal:", encoded)
        return
    end

    table.insert(SendQueue, {
        url = W.Url, payload = encoded,
        label = ("%s [%s]"):format(tostring(data.name), rarity),
        retries = 0, retryAfter = 2,
    })

    processQueue()
end

-- [FIX #1] JANGAN return di top-level chunk — simpan ke global saja
_G.MizukageWebhook = Webhook

-- ═══════════════════════════════════════════════════════════════════
-- 13. FEATURE REGISTRY
-- ═══════════════════════════════════════════════════════════════════
local FeatureRegistry = { _features = {} }

function FeatureRegistry:Register(def)
    assert(def.id, "Fitur wajib memiliki ID")
    self._features[def.id] = def
    if def.Initialize then pcall(function() def:Initialize() end) end
end

function FeatureRegistry:Enable(id)
    local feat = self._features[id]
    if feat and not feat.enabled then
        feat.enabled = true
        Logger.Debug("Mengaktifkan: " .. feat.name)
        pcall(function() feat:Enable() end)
    end
end

function FeatureRegistry:Disable(id)
    local feat = self._features[id]
    if feat and feat.enabled then
        feat.enabled = false
        Logger.Debug("Menonaktifkan: " .. feat.name)
        pcall(function() feat:Disable() end)
        CleanupManager:Clean(id)
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- 14. CORE ENGINE IMPLEMENTATION
-- ═══════════════════════════════════════════════════════════════════

FeatureRegistry:Register({
    id = "AutoFish",
    name = "Auto Fishing Engine",
    category = "Fishing",
    enabled = false,

    ExecuteCast = function(self)
        if not self.enabled or State.IsCastingLock then return end
        if State.Current == FishingState.BITTEN or State.Current == FishingState.RESOLVING then return end

        local rod = Utilities.EnsureRodEquipped()
        if not rod then
            Logger.Warn("Gagal cast: Rod tidak ditemukan.")
            return
        end

        local remotes = Utilities.GetRodRemotes(rod)
        local castEvent = remotes and remotes:FindFirstChild("CastEvent")
        if not castEvent then return end

        State.IsCastingLock = true
        State.ActiveCycleToken = os.clock()
        local currentCycle = State.ActiveCycleToken

        transitionState(FishingState.CHARGING)
        task.wait(Config.Features.AutoFish.PreCastDelay)
        if not self.enabled or State.ActiveCycleToken ~= currentCycle then
            State.IsCastingLock = false
            return
        end

        pcall(function() castEvent:FireServer(true) end)
        Logger.Debug("STEP 1: Charge dimulai...")

        task.wait(Config.Features.AutoFish.ChargeHoldDuration)
        if not self.enabled or State.ActiveCycleToken ~= currentCycle then
            State.IsCastingLock = false
            return
        end

        local targetPower = math.clamp(Config.Features.AutoFish.CastPower, 30, 100)
        pcall(function() castEvent:FireServer(false, targetPower, nil) end)

        State.Stats.Casts = State.Stats.Casts + 1
        State.LastCastTick = os.clock()
        if targetPower >= 95 then State.Stats.Perfect = State.Stats.Perfect + 1 end
        transitionState(FishingState.CASTED)
        Logger.Debug(string.format("STEP 1 Selesai: Kail dilempar (Power: %d%%)", targetPower))

        task.wait(Config.Features.AutoFish.PostCastSettle)
        State.IsCastingLock = false
    end,

    HandleBite = function(self, miniGameRemote, biteData)
        if not self.enabled then return end
        if State.Current == FishingState.RESOLVING or State.Current == FishingState.POST_CATCH then return end

        transitionState(FishingState.BITTEN)
        local currentCycle = State.ActiveCycleToken
        Logger.Debug("STEP 2: TANDA SERU MUNCUL!")

        local rar = Utilities.NormalizeRarity((type(biteData) == "table" and biteData.rarity) or "Common")
        local nm = (type(biteData) == "table" and biteData.name) or "Unknown"

        if GlobalRemotes.TandaSeruBersama then
            pcall(function() GlobalRemotes.TandaSeruBersama:FireServer(nil, nil, nil, 1.5) end)
        end

        if Config.Features.Alerts.RareAlert and Utilities.MeetsRarity(rar, Config.Features.Alerts.RareThreshold) then
            playAudio(Constants.SOUNDS.Rare, 0.7)
            Notifications.Notify("TANDA SERU! RARE BITE", string.format("%s [%s]", nm, rar), 2.5)
        elseif Config.Features.Alerts.BiteAlert then
            playAudio(Constants.SOUNDS.Bite, 0.4)
        end

        transitionState(FishingState.RESOLVING)
        -- [FIX #7] Track burst thread
        local burstThread = task.spawn(function()
            local bursts = math.clamp(Config.Features.AutoFish.WinBurstCount, 1, 5)
            for _ = 1, bursts do
                if not self.enabled or State.ActiveCycleToken ~= currentCycle then break end
                pcall(function() miniGameRemote:FireServer(true) end)
                task.wait(Config.Features.AutoFish.WinBurstInterval)
            end
            Logger.Debug("STEP 3: Paket kemenangan MiniGame dikirim.")
        end)
        CleanupManager:AddTask("AutoFish", burstThread)
    end,

    HandleGotFish = function(self, fishData)
        if not self.enabled then return end
        transitionState(FishingState.POST_CATCH)
        State.Stats.Catches = State.Stats.Catches + 1
        State.LastCatchTick = os.clock()
        local currentCycle = State.ActiveCycleToken

        local rar = Utilities.NormalizeRarity(fishData.rarity or "Common")
        State.Stats.Rarity[rar] = (State.Stats.Rarity[rar] or 0) + 1

        local w = fishData.weight or 0
        local nm = fishData.baseName or fishData.originalName or "Unknown"
        local mut = fishData.mutation or "Normal"

        -- [FIX #6] Proper rarity comparison
        local bestRank = Utilities.Rank(State.Stats.BestCatch.rarity or "")
        local newRank = Utilities.Rank(rar)
        if newRank > bestRank or (newRank == bestRank and w > (State.Stats.BestCatch.weight or 0)) then
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

        Logger.Debug(string.format("STEP 4: Ikan Masuk -> %s (%s, %.2fkg)", nm, rar, w))

        Webhook.Dispatch({
            name = nm, rarity = rar, mutation = mut,
            weight = w, chance = fishData.chance,
        })

        if Config.Features.AutoCollect.InstantClaim and GlobalRemotes.InventarisAmbilSemua then
            task.spawn(function()
                pcall(function() GlobalRemotes.InventarisAmbilSemua:InvokeServer() end)
            end)
        end

        task.delay(Config.Features.AutoFish.RecastCooldown, function()
            if self.enabled and State.ActiveCycleToken == currentCycle then
                transitionState(FishingState.IDLE)
                Logger.Debug("STEP 5: Cooldown server tuntas.")
                self:ExecuteCast()
            end
        end)
    end,

    HookRodTool = function(self, tool)
        if not tool or tool:GetAttribute("MizukageMasterV5") then return end
        tool:SetAttribute("MizukageMasterV5", true)

        local remotes = Utilities.GetRodRemotes(tool)
        if not remotes then return end

        local miniGame = remotes:WaitForChild("MiniGame", 5)
        local notify = remotes:WaitForChild("NotifyClient", 5)

        if miniGame then
            local mgConn = miniGame.OnClientEvent:Connect(function(action, data)
                if not self.enabled then return end

                if action == "Start" then
                    self:HandleBite(miniGame, data)
                elseif action == "Stop" then
                    if State.Current == FishingState.RESOLVING or State.Current == FishingState.BITTEN then
                        local token = State.ActiveCycleToken
                        task.delay(Config.Features.AutoFish.RecastCooldown, function()
                            if self.enabled and State.ActiveCycleToken == token
                               and State.Current ~= FishingState.CHARGING then
                                transitionState(FishingState.IDLE)
                                self:ExecuteCast()
                            end
                        end)
                    end
                end
            end)
            CleanupManager:AddConnection("AutoFish", mgConn)
        end

        if notify then
            local notifyConn = notify.OnClientEvent:Connect(function(action, data)
                if not self.enabled then return end

                if action == "Bite" then
                    if miniGame then self:HandleBite(miniGame, data) end
                elseif action == "CastFailed" then
                    State.Stats.Failed = State.Stats.Failed + 1
                    State.IsCastingLock = false
                    Logger.Warn("Cast Ditolak Server: " .. tostring(data and data.reason or "Unknown"))
                    transitionState(FishingState.IDLE)
                    task.delay(Config.Features.AutoFish.RecastCooldown, function()
                        if self.enabled and not State.IsCastingLock then
                            self:ExecuteCast()
                        end
                    end)
                elseif action == "GotFish" and type(data) == "table" then
                    self:HandleGotFish(data)
                end
            end)
            CleanupManager:AddConnection("AutoFish", notifyConn)
        end
    end,

    Enable = function(self)
        transitionState(FishingState.IDLE)
        State.IsCastingLock = false

        if Config.Features.AutoFish.AutoEquipRod then
            Utilities.EnsureRodEquipped()
        end

        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        local ch = LocalPlayer.Character
        if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then self:HookRodTool(t) end end end
        if ch then for _, t in ipairs(ch:GetChildren()) do if t:IsA("Tool") then self:HookRodTool(t) end end end

        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local childConn = char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") and child:FindFirstChild("Mechanics") then
                task.wait(0.1)
                self:HookRodTool(child)
            end
        end)
        CleanupManager:AddConnection("AutoFish", childConn)

        -- [FIX #5] Optimized visual sensor (throttled)
        if Config.Features.AutoFish.ExclamationSensor then
            local visualTask = task.spawn(function()
                local lastScan = 0
                while self.enabled do
                    local now = os.clock()
                    if State.Current == FishingState.CASTED and (now - lastScan) > 0.15 then
                        lastScan = now
                        local myChar = LocalPlayer.Character
                        if myChar then
                            local found = false
                            for _, desc in ipairs(myChar:GetDescendants()) do
                                if desc:IsA("BillboardGui") then
                                    local n = desc.Name:lower()
                                    if n:find("tanda") or n:find("bite") or n:find("seru") then
                                        found = true
                                        break
                                    end
                                end
                            end
                            if found then
                                local rod = Utilities.GetEquippedRod()
                                local rem = Utilities.GetRodRemotes(rod)
                                local mg = rem and rem:FindFirstChild("MiniGame")
                                if mg then
                                    Logger.Debug("Sensor Visual Tanda Seru Aktif!")
                                    self:HandleBite(mg, { name = "Visual Catch", rarity = "Common" })
                                end
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end)
            CleanupManager:AddTask("AutoFish", visualTask)
        end

        -- [FIX #8] Race-guard watchdog
        local watchdogLoop = task.spawn(function()
            while self.enabled do
                local now = os.clock()

                if Config.Features.AutoFish.AutoEquipRod then
                    pcall(Utilities.EnsureRodEquipped)
                end

                if not State.IsCastingLock then
                    if State.Current == FishingState.CASTED
                       and (now - State.LastStateChange) > Config.Features.AutoFish.WatchdogTimeout then
                        Logger.Warn("Watchdog: Kail idle — melempar ulang...")
                        transitionState(FishingState.IDLE)
                        self:ExecuteCast()
                    elseif State.Current == FishingState.IDLE then
                        self:ExecuteCast()
                    end
                end

                task.wait(0.25)
            end
        end)
        CleanupManager:AddTask("AutoFish", watchdogLoop)

        task.delay(0.2, function()
            if self.enabled and not State.IsCastingLock then
                self:ExecuteCast()
            end
        end)
    end,

    Disable = function(self)
        State.IsCastingLock = false
        State.ActiveCycleToken = os.clock()
        transitionState(FishingState.IDLE)
    end,
})

FeatureRegistry:Register({
    id = "AutoCollect",
    name = "Auto Inventory Collector",
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
        local sweep = task.spawn(function()
            while self.enabled do
                if Config.Features.AutoCollect.Enabled and GlobalRemotes.InventarisAmbilSemua then
                    pcall(function() GlobalRemotes.InventarisAmbilSemua:InvokeServer() end)
                end
                task.wait(Config.Features.AutoCollect.CollectInterval)
            end
        end)
        CleanupManager:AddTask("AutoCollect", sweep)
    end,

    Disable = function(self) end,
})

FeatureRegistry:Register({
    id = "EventTrackers",
    name = "Event Intelligence",
    category = "Intelligence",
    enabled = true,

    Enable = function(self)
        local evLoop = task.spawn(function()
            local warnedCore = false
            local lastHourly = nil

            while self.enabled do
                if Config.Features.EventTrackers.CoreTracker and Databases.CoreCfg
                   and type(Databases.CoreCfg.Fase) == "function" then
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

                if Config.Features.EventTrackers.HourlyTracker and Databases.EventCfg
                   and type(Databases.EventCfg.Acara) == "function" then
                    local ok, info = pcall(function()
                        return Databases.EventCfg.Acara(Databases.EventCfg.JamSekarang())
                    end)
                    if ok and type(info) == "table" and info.tier ~= lastHourly then
                        lastHourly = info.tier
                        Notifications.Info(string.format("Event Jam Ini: %s (%s)",
                            tostring(info.tier), tostring(info.ket or "")))
                    end
                end

                task.wait(8)
            end
        end)
        CleanupManager:AddTask("EventTrackers", evLoop)
    end,

    Disable = function(self) end,
})

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
    Name = Constants.BRAND .. " | SOREYA V5",
    LoadingTitle = Constants.NAME,
    LoadingSubtitle = "TeamMizu 🔰",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false,
})

-- [FIX #11] Rayfield double-destroy guard
local RayfieldDestroyed = false
local function SafeDestroyRayfield()
    if RayfieldDestroyed then return end
    RayfieldDestroyed = true
    if Rayfield and Rayfield.Destroy then
        pcall(function() Rayfield:Destroy() end)
    end
end

local UIManager = {}
function UIManager.CreateText(tab, options)
    if tab.CreateParagraph then
        return tab:CreateParagraph({ Title = options.name or "Info", Content = options.body or "" })
    end
end

function UIManager.CreateDivider(tab, options)
    if tab.CreateDivider then return tab:CreateDivider(options) end
end

local TabMain = Window:CreateTab("Dashboard", "home")
local TabAutoFish = Window:CreateTab("Auto Fish", "anchor")
local TabManual = Window:CreateTab("Settingan Manual", "sliders")
local TabCollect = Window:CreateTab("Inventory", "archive")
local TabAlerts = Window:CreateTab("Alerts", "bell")
local TabEvents = Window:CreateTab("Event Intel", "calendar")
local TabWebhook = Window:CreateTab("Webhook", "send")
local TabStats = Window:CreateTab("Stats", "activity")
local TabSettings = Window:CreateTab("Settings", "settings")

-- ─── TAB 1: DASHBOARD ───
TabMain:CreateSection("Status Operasional")

UIManager.CreateText(TabMain, {
    name = "Engine Status",
    body = "Mizukage v5.0.1 — Patch: Return-killer removed, race guards, optimized sensor."
})

UIManager.CreateText(TabMain, {
    name = "TeamMizu 🔰 Integration",
    body = "Admin Jembod cepet bgt dia FIX nya"
})

UIManager.CreateDivider(TabMain, { name = "Aksi Cepat" })

TabMain:CreateButton({
    Name = "⚡ Pasang Rod Terbaik Sekarang",
    Callback = function()
        local r = Utilities.EquipBestRod()
        if r then Notifications.Success("Rod Terpasang: " .. r.Name)
        else Notifications.Warning("Rod tidak ditemukan.") end
    end,
})

TabMain:CreateButton({
    Name = "📥 Ambil Semua Tangkapan (Manual)",
    Callback = function()
        if GlobalRemotes.InventarisAmbilSemua then
            pcall(function() GlobalRemotes.InventarisAmbilSemua:InvokeServer() end)
            Notifications.Success("Hasil tangkapan dipindahkan ke tas.")
        end
    end,
})

-- ─── TAB 2: AUTO FISH ───
TabAutoFish:CreateSection("Kontrol Utama")

TabAutoFish:CreateToggle({
    Name = "Aktifkan Auto Fishing",
    CurrentValue = Config.Features.AutoFish.Enabled,
    Flag = "Toggle_AutoFishMaster",
    Callback = function(val)
        Config.Features.AutoFish.Enabled = val
        if val then
            FeatureRegistry:Enable("AutoFish")
            Notifications.Success("Auto Fish: AKTIF")
        else
            FeatureRegistry:Disable("AutoFish")
            Notifications.Warning("Auto Fish: NONAKTIF")
        end
    end,
})

TabAutoFish:CreateToggle({
    Name = "Auto-Equip Rod",
    CurrentValue = Config.Features.AutoFish.AutoEquipRod,
    Flag = "Toggle_AutoEquipRod",
    Callback = function(val) Config.Features.AutoFish.AutoEquipRod = val end,
})

TabAutoFish:CreateToggle({
    Name = "Auto Tanda Seru",
    CurrentValue = Config.Features.AutoFish.ExclamationSensor,
    Flag = "Toggle_VisualExclamation",
    Callback = function(val) Config.Features.AutoFish.ExclamationSensor = val end,
})

-- ─── TAB 3: SETTINGAN MANUAL ───
TabManual:CreateSection("Kalibrasi Seluruh Jeda & Timing")

TabManual:CreateSlider({
    Name = "1. Durasi Tahan Lemparan (Charge Duration)",
    Range = { 0.10, 1.50 }, Increment = 0.50, Suffix = " detik",
    CurrentValue = Config.Features.AutoFish.ChargeHoldDuration,
    Flag = "Slider_ChargeHoldDuration",
    Callback = function(val) Config.Features.AutoFish.ChargeHoldDuration = val end,
})

TabManual:CreateSlider({
    Name = "2. Target Power Lemparan",
    Range = { 30, 100 }, Increment = 1, Suffix = "%",
    CurrentValue = Config.Features.AutoFish.CastPower,
    Flag = "Slider_CastPower",
    Callback = function(val) Config.Features.AutoFish.CastPower = val end,
})

TabManual:CreateSlider({
    Name = "3. Jeda Lempar Kembali (Recast Cooldown)",
    Range = { 0.50, 3.00 }, Increment = 0.05, Suffix = " detik",
    CurrentValue = Config.Features.AutoFish.RecastCooldown,
    Flag = "Slider_RecastCooldown",
    Callback = function(val) Config.Features.AutoFish.RecastCooldown = val end,
})

TabManual:CreateSlider({
    Name = "4. Jeda Persiapan Lemparan (Pre-Cast Delay)",
    Range = { 0.05, 1.00 }, Increment = 0.05, Suffix = " detik",
    CurrentValue = Config.Features.AutoFish.PreCastDelay,
    Flag = "Slider_PreCastDelay",
    Callback = function(val) Config.Features.AutoFish.PreCastDelay = val end,
})

TabManual:CreateSlider({
    Name = "5. Jeda Pendaratan Umpan (Post-Cast Settle)",
    Range = { 0.20, 2.00 }, Increment = 0.05, Suffix = " detik",
    CurrentValue = Config.Features.AutoFish.PostCastSettle,
    Flag = "Slider_PostCastSettle",
    Callback = function(val) Config.Features.AutoFish.PostCastSettle = val end,
})

TabManual:CreateSlider({
    Name = "6. Repetisi Paket Menang (Win Burst Count)",
    Range = { 1, 5 }, Increment = 1, Suffix = " burst",
    CurrentValue = Config.Features.AutoFish.WinBurstCount,
    Flag = "Slider_WinBurstCount",
    Callback = function(val) Config.Features.AutoFish.WinBurstCount = math.clamp(val, 1, 5) end,
})

TabManual:CreateSlider({
    Name = "7. Jeda Antar Tembakan Menang (Burst Interval)",
    Range = { 0.01, 0.20 }, Increment = 0.01, Suffix = " detik",
    CurrentValue = Config.Features.AutoFish.WinBurstInterval,
    Flag = "Slider_WinBurstInterval",
    Callback = function(val) Config.Features.AutoFish.WinBurstInterval = val end,
})

TabManual:CreateSlider({
    Name = "8. Watchdog Timeout (Anti-Macet)",
    Range = { 4.0, 30.0 }, Increment = 0.5, Suffix = " detik",
    CurrentValue = Config.Features.AutoFish.WatchdogTimeout,
    Flag = "Slider_WatchdogTimeout",
    Callback = function(val) Config.Features.AutoFish.WatchdogTimeout = val end,
})

TabManual:CreateButton({
    Name = "🔄 Kembalikan ke Settingan Aman",
    Callback = function()
        Config.Features.AutoFish.PreCastDelay = Constants.DEFAULT_TIMINGS.PRE_CAST_DELAY
        Config.Features.AutoFish.ChargeHoldDuration = Constants.DEFAULT_TIMINGS.CHARGE_HOLD_DURATION
        Config.Features.AutoFish.CastPower = Constants.DEFAULT_TIMINGS.CAST_POWER
        Config.Features.AutoFish.PostCastSettle = Constants.DEFAULT_TIMINGS.POST_CAST_SETTLE
        Config.Features.AutoFish.WinBurstCount = Constants.DEFAULT_TIMINGS.WIN_BURST_COUNT
        Config.Features.AutoFish.WinBurstInterval = Constants.DEFAULT_TIMINGS.WIN_BURST_INTERVAL
        Config.Features.AutoFish.RecastCooldown = Constants.DEFAULT_TIMINGS.RECAST_COOLDOWN
        Config.Features.AutoFish.WatchdogTimeout = Constants.DEFAULT_TIMINGS.WATCHDOG_TIMEOUT
        Notifications.Success("Settingan dikembalikan ke default aman.")
    end,
})

-- ─── TAB 4: INVENTORY ───
TabCollect:CreateSection("Manajemen Hasil Tangkapan")

TabCollect:CreateToggle({
    Name = "Instant Claim (Ambil Langsung Saat Dapat Ikan)",
    CurrentValue = Config.Features.AutoCollect.InstantClaim,
    Flag = "Toggle_InstantClaim",
    Callback = function(val) Config.Features.AutoCollect.InstantClaim = val end,
})

TabCollect:CreateSlider({
    Name = "Jeda Pembersihan Berkala (Sweep)",
    Range = { 1.0, 10.0 }, Increment = 0.5, Suffix = " detik",
    CurrentValue = Config.Features.AutoCollect.CollectInterval,
    Flag = "Slider_CollectInterval",
    Callback = function(val) Config.Features.AutoCollect.CollectInterval = val end,
})

-- ─── TAB 5: ALERTS ───
TabAlerts:CreateSection("Audio & Visual Notifikasi")

TabAlerts:CreateToggle({
    Name = "Suara Gigitan Kail (Bite)",
    CurrentValue = Config.Features.Alerts.BiteAlert,
    Flag = "Toggle_AlertBite",
    Callback = function(val) Config.Features.Alerts.BiteAlert = val end,
})

TabAlerts:CreateToggle({
    Name = "Suara Tangkapan Langka",
    CurrentValue = Config.Features.Alerts.RareAlert,
    Flag = "Toggle_AlertRare",
    Callback = function(val) Config.Features.Alerts.RareAlert = val end,
})

TabAlerts:CreateDropdown({
    Name = "Batas Minimal Rarity Notifikasi",
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
    Callback = function(val) Config.Features.Alerts.GlobalCutscene = val end,
})

-- ─── TAB 6: EVENT INTEL ───
TabEvents:CreateSection("Pemantau Acara Server")

TabEvents:CreateToggle({
    Name = "Pantau Withering Core (60s Warning)",
    CurrentValue = Config.Features.EventTrackers.CoreTracker,
    Flag = "Toggle_CoreTracker",
    Callback = function(val) Config.Features.EventTrackers.CoreTracker = val end,
})

TabEvents:CreateToggle({
    Name = "Pantau Jadwal Event Per Jam",
    CurrentValue = Config.Features.EventTrackers.HourlyTracker,
    Flag = "Toggle_HourlyTracker",
    Callback = function(val) Config.Features.EventTrackers.HourlyTracker = val end,
})

TabEvents:CreateButton({
    Name = "Cek Status Core Sekarang",
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
TabWebhook:CreateSection("Backend Discord")

UIManager.CreateText(TabWebhook, {
    name = "Status Aktif",
    body = "Cek discord."
})

TabWebhook:CreateToggle({
    Name = "Aktifkan Pengiriman",
    CurrentValue = Config.Features.Webhook.Enabled,
    Flag = "Toggle_WebhookBackend",
    Callback = function(val) Config.Features.Webhook.Enabled = val end,
})

TabWebhook:CreateToggle({
    Name = "Debug Webhook (Console)",
    CurrentValue = Config.Features.Webhook.Debug,
    Flag = "Toggle_WebhookDebug",
    Callback = function(val) Config.Features.Webhook.Debug = val end,
})

TabWebhook:CreateDropdown({
    Name = "Minimal Rarity Dikirim",
    Options = { "Rare", "Epic", "Legendary", "Mythical", "Secret", "FORGOTTEN" },
    CurrentOption = { "Secret" },
    MultipleOptions = false,
    Flag = "Dropdown_WhRarity",
    Callback = function(opt)
        Config.Features.Webhook.MinRarity = type(opt) == "table" and opt[1] or opt
    end,
})

TabWebhook:CreateButton({
    Name = "Kirim Test ke Discord",
    Callback = function()
        Webhook.Dispatch({
            name = "KHONTOLODON", rarity = "Secret", mutation = "Frozen",
            weight = 1250.50, chance = 0.000002,
        })
        Notifications.Success("TEST percobaan dikirim ke Discord Mizukage.")
    end,
})

-- ─── TAB 8: STATS ───
TabStats:CreateSection("Statistik Mancing")

local StatL1 = TabStats:CreateParagraph({ Title = "Kinerja Sesi", Content = "Mengumpulkan metrik..." })
local StatL2 = TabStats:CreateParagraph({ Title = "Rincian Rarity", Content = "Mengumpulkan metrik..." })
local StatL3 = TabStats:CreateParagraph({ Title = "Rekor Ikan", Content = "-" })

-- [FIX #10] Anti-negative rate
local statsTask = task.spawn(function()
    while task.wait(1) do
        local elapsed = os.clock() - (State.Stats.StartTime or os.clock())
        local elapsedMin = math.max(elapsed / 60, 0.001)
        local rate = State.Stats.Catches / elapsedMin
        if rate > (State.Stats.PeakRate or 0) then State.Stats.PeakRate = rate end

        pcall(function()
            StatL1:Set({
                Title = "Kinerja Sesi",
                Content = string.format(
                    "Status Engine: [%s]\nTangkapan: %d | Lemparan: %d | Gagal: %d\nKecepatan: %.1f/mnt | Puncak: %.1f/mnt",
                    State.Current, State.Stats.Catches, State.Stats.Casts,
                    State.Stats.Failed, rate, State.Stats.PeakRate)
            })

            local r = State.Stats.Rarity
            StatL2:Set({
                Title = "Rincian Rarity",
                Content = string.format(
                    "Common: %d | UnCommon: %d | Rare: %d | Epic: %d\nLegendary: %d | Mythical: %d\nSecret: %d | Forgotten: %d",
                    r.Common or 0, r.UnCommon or 0, r.Rare or 0, r.Epic or 0,
                    r.Legendary or 0, (r.Mythical or 0) + (r.Mythic or 0),
                    (r.Secret or 0) + (r.SECRET or 0), (r.FORGOTTEN or 0) + (r.Forgotten or 0))
            })

            local b = State.Stats.BestCatch
            StatL3:Set({
                Title = "Rekor Ikan Terbesar",
                Content = string.format("%s [%s]\nBerat: %.2f kg | Mutasi: %s",
                    tostring(b.name), tostring(b.rarity), tonumber(b.weight) or 0, tostring(b.mutation))
            })
        end)
    end
end)
CleanupManager:AddTask("UI_Stats", statsTask)

-- ─── TAB 9: SETTINGS ───
TabSettings:CreateSection("Manajemen & Proteksi")

TabSettings:CreateToggle({
    Name = "Anti-AFK Protection",
    CurrentValue = Config.Features.Protection.AntiAFK,
    Flag = "Toggle_AntiAfk",
    Callback = function(val) Config.Features.Protection.AntiAFK = val end,
})

TabSettings:CreateToggle({
    Name = "Notifikasi UI In-Game",
    CurrentValue = Config.General.Notifications,
    Flag = "Toggle_Notifications",
    Callback = function(val) Config.General.Notifications = val end,
})

TabSettings:CreateToggle({
    Name = "Debug Console Output",
    CurrentValue = Config.General.Debug,
    Flag = "Toggle_Debug",
    Callback = function(val) Config.General.Debug = val end,
})

UIManager.CreateDivider(TabSettings, { name = "Shutdown" })

TabSettings:CreateButton({
    Name = "Hentikan Script (Unload)",
    Callback = function()
        FeatureRegistry:Disable("AutoFish")
        CleanupManager:CleanAll()
        if getgenv then getgenv().MIZUKAGE_SOREYA_V5 = nil end
        Notifications.Info("Mizukage Official Engine dihentikan secara aman.")
        task.wait(0.8)
        SafeDestroyRayfield()
    end,
})

-- ═══════════════════════════════════════════════════════════════════
-- 16. HOTKEY & EXPORT BINDINGS
-- ═══════════════════════════════════════════════════════════════════
local hotkeyConn = Services.UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Config.Features.AutoFish.Enabled = not Config.Features.AutoFish.Enabled
        if Config.Features.AutoFish.Enabled then
            FeatureRegistry:Enable("AutoFish")
            Notifications.Success("Auto Fishing: AKTIF [RightShift]")
        else
            FeatureRegistry:Disable("AutoFish")
            Notifications.Warning("Auto Fishing: NONAKTIF [RightShift]")
        end
    end
end)
CleanupManager:AddConnection("Global_Hotkey", hotkeyConn)

if getgenv then
    getgenv().MIZUKAGE_SOREYA_UNLOAD = function()
        FeatureRegistry:Disable("AutoFish")
        CleanupManager:CleanAll()
        SafeDestroyRayfield()
        getgenv().MIZUKAGE_SOREYA_V5 = nil
    end
end

-- Luncurkan background daemon
FeatureRegistry:Enable("AutoCollect")
FeatureRegistry:Enable("EventTrackers")
FeatureRegistry:Enable("Telemetry")
FeatureRegistry:Enable("AntiAFK")

Logger.Info("Mizukage Official 👑 v5.0.1 loaded.")
Notifications.Success("Mizukage Official 👑 v5.0.1 Berhasil Dimuat! (RightShift = On/Off)")