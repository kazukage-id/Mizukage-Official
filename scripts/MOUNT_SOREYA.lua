--[[
================================================================================
    SOREYA TURBO FISHER v4.1  (FIXED LOAD)
    --------------------------------------------------------------------------
    Fix dari v4.0:
    - [FIX] Hapus bit32 (tidak tersedia di Luau global) -> pakai math manual
    - [FIX] mutationToHex pakai math.floor(x*255+0.5) bukan bit32
    - [FIX] Semua require pakai pcall agar tidak crash saat module absen
    - [FIX] CoreConfig / EventOtomatis aman kalau nil
    - [FIX] Rayfield:CreateLabel ada di beberapa versi, sudah aman
    - [FIX] Label:Set() di-wrap pcall
================================================================================
--]]

-- ═══════════════════════════════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")
local SoundService      = game:GetService("SoundService")
local StarterGui        = game:GetService("StarterGui")
local VirtualUser       = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer

local RS_MODULES = ReplicatedStorage:FindFirstChild("Modules")
local RS_FISHING = RS_MODULES and RS_MODULES:FindFirstChild("Fishing")
local RS_CONFIG  = ReplicatedStorage:FindFirstChild("Modul")
if RS_CONFIG then
    RS_CONFIG = RS_CONFIG:FindFirstChild("Konfigurasi")
end

-- ═══════════════════════════════════════════════════════════════════════════
--  LOAD RAYFIELD
-- ═══════════════════════════════════════════════════════════════════════════
local Rayfield
do
    local sources = {
        "https://sirius.menu/rayfield",
        "https://raw.githubusercontent.com/shlexware/Rayfield/main/source",
    }
    for _, url in ipairs(sources) do
        local ok, res = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)
        if ok and res then
            Rayfield = res
            break
        end
    end
    if not Rayfield then
        error("[Soreya] Gagal memuat Rayfield. Cek koneksi internet.")
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
--  CONFIG
-- ═══════════════════════════════════════════════════════════════════════════
local Config = {
    AutoFish             = false,
    TurboMode            = true,
    AggressiveMode       = true,
    AutoWin              = true,

    TurboInterval        = 0.01,
    NormalInterval       = 0.00,
    InstantDelay         = 0.00,
    WinBurst             = 1,
    AntiDuplicateBite    = true,

    PerfectPower         = true,
    MinPower             = 92,
    MaxPower             = 100,
    AutoEquipBest        = true,

    AutoSell             = false,
    SellBelow            = "Rare",
    KeepShiny            = true,
    KeepBig              = true,

    BiteAlert            = true,
    BiteSoundId          = "rbxassetid://123845773202915",
    RareAlert            = true,
    RareSoundId          = "rbxassetid://133304152585589",
    SuperRareSoundId     = "rbxassetid://84099093339952",
    RareThreshold        = "Legendary",

    GlobalCutsceneAlert  = false,
    GlobalCutsceneSecret = false,
    GlobalCutsceneMyth   = true,
    GlobalCutsceneForgot = true,

    CoreEventTracker     = true,
    CoreEventWarn60s     = true,
    CoreEventAlertOpen   = true,

    HourlyEventTracker   = true,

    WebhookEnabled       = false,
    WebhookUrl           = "",
    WebhookMinRarity     = "Secret",
    WebhookWithImage     = true,
    WebhookWithThumb     = true,
    WebhookWithMutColor  = true,

    AntiAFK              = true,
    PlayerRadar          = false,
    ChatFilterOn         = false,
    ChatFilterKeyword    = "SECRET",
}

-- ═══════════════════════════════════════════════════════════════════════════
--  DATABASES (semua pcall agar tidak crash)
-- ═══════════════════════════════════════════════════════════════════════════
local FishDB, ItemDB, MutasiDB, TierDB, CoreCfg, EventCfg
if RS_FISHING then
    pcall(function() FishDB   = require(RS_FISHING:WaitForChild("FishingImageDatabase", 5)) end)
    pcall(function() ItemDB   = require(RS_FISHING:WaitForChild("ItemDatabase", 5)) end)
    pcall(function() MutasiDB = require(RS_FISHING:WaitForChild("MutasiConfig", 5)) end)
    pcall(function() TierDB   = require(RS_FISHING:WaitForChild("TierIkan", 5)) end)
end
if RS_CONFIG then
    pcall(function() CoreCfg  = require(RS_CONFIG:WaitForChild("CoreConfig", 5)) end)
    pcall(function() EventCfg  = require(RS_CONFIG:WaitForChild("EventOtomatis", 5)) end)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  CONSTANTS
-- ═══════════════════════════════════════════════════════════════════════════
local RARITY_RANK = {
    Common=1, UnCommon=2, Rare=3, Epic=4,
    Legend=5, Legendary=5,
    Mythical=6, Mythic=6, Mitos=6, Mythos=6,
    Secret=7, SECRET=7,
    FORGOTTEN=8, Forgotten=8,
}

local RARITY_COLOR = {
    Common=0xB1B1B1, UnCommon=0x80FF52, Rare=0x55A2FF, Epic=0xB272F7,
    Legend=0xFFB82A, Legendary=0xFFB82A,
    Mythical=0xFF64C8, Mythic=0xFF64C8, Mitos=0xFF64C8,
    Secret=0x17FF97, SECRET=0x17FF97,
    FORGOTTEN=0x7F7F7F, Forgotten=0x7F7F7F,
}

local RARITY_ICON = {
    Common="[C]", UnCommon="[UC]", Rare="[R]", Epic="[E]",
    Legend="[L]", Legendary="[L]",
    Mythical="[M]", Mythic="[M]", Mitos="[M]",
    Secret="[S]", SECRET="[S]",
    FORGOTTEN="[F]", Forgotten="[F]",
}

local function rank(n) return RARITY_RANK[n] or 0 end
local function meets(n, min) return rank(n) >= rank(min) end

-- ═══════════════════════════════════════════════════════════════════════════
--  STATS
-- ═══════════════════════════════════════════════════════════════════════════
local Stats = {
    Catches   = 0,
    Casts     = 0,
    Failed    = 0,
    Perfect   = 0,
    Good      = 0,
    PeakRate  = 0,
    StartTime = os.clock(),
    Best      = { name = "-", rarity = "-", weight = 0, mutation = "-" },
    Rarity    = {
        Common=0, UnCommon=0, Rare=0, Epic=0, Legendary=0,
        Mythical=0, Secret=0, FORGOTTEN=0,
    },
    Global    = { Secret=0, Mythical=0, Forgotten=0 },
}

-- ═══════════════════════════════════════════════════════════════════════════
--  UTILITIES
-- ═══════════════════════════════════════════════════════════════════════════
local function toast(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = dur or 3,
        })
    end)
end

local function play(id, vol)
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = id
        s.Volume = vol or 0.6
        s.Parent = SoundService
        s:Play()
        task.delay(4, function()
            if s and s.Parent then s:Destroy() end
        end)
    end)
end

local function httpPost(url, body)
    local ok, err = pcall(function()
        HttpService:PostAsync(url, HttpService:JSONEncode(body))
    end)
    return ok, err
end

local function assetIdFromUrl(url)
    if not url or url == "" then return nil end
    return tonumber(url:match("(%d+)%s*$"))
end

local ThumbCache = {}
local function getImageUrl(assetUrl)
    if not assetUrl or assetUrl == "" then return nil end
    if ThumbCache[assetUrl] then return ThumbCache[assetUrl] end

    local id = assetIdFromUrl(assetUrl)
    if not id then return nil end

    local ok, res = pcall(function()
        local raw = HttpService:GetAsync(string.format(
            "https://thumbnails.roblox.com/v1/assets?assetIds=%d&size=420x420&format=Png&isCircular=false",
            id))
        local decoded = HttpService:JSONDecode(raw)
        local entry = decoded and decoded.data and decoded.data[1]
        return entry and entry.imageUrl or nil
    end)

    if ok and res then
        ThumbCache[assetUrl] = res
        return res
    end
    local fallback = string.format(
        "https://www.roblox.com/asset-thumbnail/image?assetId=%d&width=420&height=420&format=png", id)
    ThumbCache[assetUrl] = fallback
    return fallback
end

local function getAvatarUrl(userId)
    return string.format(
        "https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png",
        userId)
end

local function chanceText(chance)
    if not chance or chance <= 0 then return "?" end
    local one = 1 / chance
    if one >= 1e9 then return string.format("1 in %.1fB", one/1e9) end
    if one >= 1e6 then return string.format("1 in %.1fM", one/1e6) end
    if one >= 1e3 then return string.format("1 in %.1fK", one/1e3) end
    return string.format("1 in %d", math.floor(one))
end

local function fmtTime(sec)
    sec = math.max(0, math.floor(tonumber(sec) or 0))
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then return string.format("%dh %02dm", h, m) end
    if m > 0 then return string.format("%dm %02ds", m, s) end
    return string.format("%ds", s)
end

-- [FIX] Tanpa bit32 - pakai math manual untuk hex RRGGBB
local function color3ToInt(c)
    if not c or typeof(c) ~= "Color3" then return nil end
    local r = math.floor(math.clamp(c.R, 0, 1) * 255 + 0.5)
    local g = math.floor(math.clamp(c.G, 0, 1) * 255 + 0.5)
    local b = math.floor(math.clamp(c.B, 0, 1) * 255 + 0.5)
    return r * 65536 + g * 256 + b
end

local function getMutationColor(mutName)
    if not MutasiDB then return nil end
    local ok, c = pcall(function()
        return MutasiDB.Warna(mutName)
    end)
    if ok and typeof(c) == "Color3" then
        return c
    end
    return nil
end

local function mutationToHex(mutName)
    return color3ToInt(getMutationColor(mutName))
end

-- ═══════════════════════════════════════════════════════════════════════════
--  ROD UTILITIES
-- ═══════════════════════════════════════════════════════════════════════════
local function getEquippedRod()
    local c = LocalPlayer.Character
    if not c then return nil end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") and t:FindFirstChild("Mechanics") then return t end
    end
    return nil
end

local function getRemotes(rod)
    if not rod then return nil end
    local mech = rod:FindFirstChild("Mechanics")
    return mech and mech:FindFirstChild("Remotes") or nil
end

local function getStatus(rod)
    if not rod then return nil end
    local mech = rod:FindFirstChild("Mechanics")
    return mech and mech:FindFirstChild("Status") or nil
end

local function fishingActive(rod)
    local st = getStatus(rod)
    if not st then return false end
    local fa = st:FindFirstChild("FishingActive")
    return fa and fa.Value or false
end

local function equipBestRod()
    local best, bTier, bPrice = nil, -1, -1
    local pools = {}
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    local ch = LocalPlayer.Character
    if bp then table.insert(pools, bp) end
    if ch then table.insert(pools, ch) end

    for _, p in ipairs(pools) do
        for _, t in ipairs(p:GetChildren()) do
            if t:IsA("Tool") and t:FindFirstChild("Mechanics") then
                local name = t:GetAttribute("SkinDipakai") or t.Name
                local rd = ItemDB and ItemDB.Rods and ItemDB.Rods[name]
                local tier = (rd and rd.Tier) or 1
                local price = (rd and rd.Price) or 0
                if tier > bTier or (tier == bTier and price > bPrice) then
                    best, bTier, bPrice = t, tier, price
                end
            end
        end
    end

    if best and best.Parent ~= LocalPlayer.Character then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum:EquipTool(best) end) end
    end
    return best
end

-- ═══════════════════════════════════════════════════════════════════════════
--  TURBO CAST
-- ═══════════════════════════════════════════════════════════════════════════
local function turboCast(rod)
    if not rod then return false end
    if fishingActive(rod) then return false end

    local remotes = getRemotes(rod)
    if not remotes then return false end
    local castEvent = remotes:FindFirstChild("CastEvent")
    if not castEvent then return false end

    local power = Config.PerfectPower
        and math.random(Config.MinPower, Config.MaxPower)
        or math.random(30, 60)

    pcall(function() castEvent:FireServer(true) end)
    task.wait(Config.TurboMode and Config.InstantDelay or 0.25)
    pcall(function() castEvent:FireServer(false, power) end)

    Stats.Casts = Stats.Casts + 1
    if power >= 85 then
        Stats.Perfect = Stats.Perfect + 1
    elseif power >= 70 then
        Stats.Good = Stats.Good + 1
    end
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
--  WEBHOOK BUILDER
-- ═══════════════════════════════════════════════════════════════════════════
local function buildWebhookPayload(data)
    local rarity = data.rarity or "Common"
    local mutation = data.mutation or "Normal"
    local isNormal = (mutation == "Normal" or mutation == "")

    local fishName = data.baseName or data.originalName or "Unknown"
    local weight = data.weight or 0
    local chance = data.chance or 0
    local big = data.big and "**BIG** " or ""
    local shiny = (mutation == "Shiny") and "* " or ""

    local color = RARITY_COLOR[rarity] or 0x5865F2
    if Config.WebhookWithMutColor and not isNormal then
        local mutCol = mutationToHex(mutation)
        if mutCol then color = mutCol end
    end
    local rIcon = RARITY_ICON[rarity] or "[?]"

    local fishImageUrl
    if Config.WebhookWithImage and FishDB and FishDB.GetIcon then
        pcall(function()
            local icon = FishDB.GetIcon(fishName)
            fishImageUrl = getImageUrl(icon)
        end)
    end

    local mutDisplay = isNormal and "`Normal`" or ("`" .. mutation .. "`")
    local fields = {
        { name = "Mutation", value = mutDisplay, inline = true },
        { name = "Weight",   value = string.format("`%.2f kg`", weight), inline = true },
        { name = "Rarity",   value = string.format("`%s %s`", rIcon, rarity), inline = true },
        { name = "Chance",   value = "`" .. chanceText(chance) .. "`", inline = true },
        { name = "Fisher",   value = "`" .. LocalPlayer.DisplayName .. "`", inline = true },
        { name = "Time",     value = "`" .. os.date("%H:%M:%S") .. "`", inline = true },
    }

    local embed = {
        title       = string.format("%s%s CATCH!", shiny, rarity:upper()),
        description = string.format("%s**%s**", big, fishName),
        color       = color,
        fields      = fields,
        footer      = {
            text     = "Sorenya Fisher v4.1 | " .. LocalPlayer.Name,
            icon_url = getAvatarUrl(LocalPlayer.UserId),
        },
        timestamp   = DateTime.now():ToIsoDate(),
    }

    if fishImageUrl then
        if Config.WebhookWithThumb then embed.thumbnail = { url = fishImageUrl } end
        embed.image = { url = fishImageUrl }
    end

    return {
        username   = "Soreya Turbo Fisher",
        avatar_url = getAvatarUrl(LocalPlayer.UserId),
        embeds     = { embed },
    }
end

local function sendWebhook(data)
    if not Config.WebhookEnabled then return end
    if Config.WebhookUrl == "" then return end
    if not meets(data.rarity or "Common", Config.WebhookMinRarity) then return end

    task.spawn(function()
        local payload = buildWebhookPayload(data)
        local ok, err = httpPost(Config.WebhookUrl, payload)
        if not ok then
            warn("[Soreya Webhook] " .. tostring(err))
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
--  ROD HOOKING
-- ═══════════════════════════════════════════════════════════════════════════
local lastBiteAt = 0

local function hookRod(rod)
    if not rod or rod:GetAttribute("SoreyaHooked") then return end
    rod:SetAttribute("SoreyaHooked", true)

    local remotes = getRemotes(rod)
    if not remotes then
        task.delay(0.5, function() hookRod(rod) end)
        return
    end

    local tandaSeru = ReplicatedStorage:FindFirstChild("TandaSeruBersama")

    -- MiniGame
    local mg = remotes:WaitForChild("MiniGame", 10)
    if mg then
        mg.OnClientEvent:Connect(function(action, data)
            if action ~= "Start" then return end
            if type(data) ~= "table" then return end

            local rar = data.rarity or "Common"
            local nm  = data.name or "?"
            local ch  = data.chance or 0
            local w   = data.weight or 0
            local line = string.format("%s | %s | %.2fkg", nm, chanceText(ch), w)

            local now = os.clock()
            if Config.AntiDuplicateBite and (now - lastBiteAt) < 0.05 then
                -- skip duplicate
            else
                lastBiteAt = now
                if tandaSeru then
                    pcall(function()
                        tandaSeru:FireServer(nil, nil, nil, 1.5)
                    end)
                end

                if Config.RareAlert and meets(rar, Config.RareThreshold) then
                    play(Config.RareSoundId, 0.7)
                    toast(RARITY_ICON[rar] .. " RARE BITE", line, 3)
                elseif Config.BiteAlert then
                    play(Config.BiteSoundId, 0.5)
                    toast("[BITE]", line, 1.5)
                end
            end

            if Config.AutoWin then
                local burst = math.clamp(Config.WinBurst, 1, 3)
                if Config.TurboMode then
                    task.spawn(function()
                        for i = 1, burst do
                            pcall(function() mg:FireServer(true) end)
                            if i < burst then task.wait(0.01) end
                        end
                    end)
                else
                    task.delay(0.15, function()
                        pcall(function() mg:FireServer(true) end)
                    end)
                end
            end
        end)
    end

    -- NotifyClient
    local nc = remotes:WaitForChild("NotifyClient", 10)
    if nc then
        nc.OnClientEvent:Connect(function(action, data)
            if action == "Bite" then
                if Config.BiteAlert and not Config.TurboMode then
                    play(Config.BiteSoundId, 0.4)
                end
                return
            end

            if action == "CastFailed" then
                Stats.Failed = Stats.Failed + 1
                return
            end

            if action ~= "GotFish" or type(data) ~= "table" then return end

            Stats.Catches = Stats.Catches + 1
            local rar = data.rarity or "Common"
            Stats.Rarity[rar] = (Stats.Rarity[rar] or 0) + 1

            local w  = data.weight or 0
            local nm = data.baseName or data.originalName or "?"
            local mut = data.mutation or "Normal"
            local big = data.big and "Big " or ""

            if w > (Stats.Best.weight or 0) and meets(rar, Stats.Best.rarity) then
                Stats.Best = { name = nm, rarity = rar, weight = w, mutation = mut }
            end

            if Config.RareAlert and meets(rar, Config.RareThreshold) then
                if rank(rar) >= rank("Secret") then
                    play(Config.SuperRareSoundId, 0.8)
                else
                    play(Config.RareSoundId, 0.7)
                end
                toast(RARITY_ICON[rar] .. " " .. rar,
                    string.format("%s%s %s (%.2fkg)", big, mut, nm, w), 3)
            end

            sendWebhook({
                baseName     = data.baseName,
                originalName = data.originalName,
                rarity       = rar,
                mutation     = mut,
                weight       = w,
                chance       = data.chance,
                big          = data.big,
                shiny        = (mut == "Shiny"),
            })
        end)
    end
end

local function hookAllRods()
    for _, container in ipairs(LocalPlayer:GetChildren()) do
        if container:IsA("Backpack") then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and tool:FindFirstChild("Mechanics") then
                    task.spawn(function() hookRod(tool) end)
                end
            end
            container.ChildAdded:Connect(function(tool)
                if tool:IsA("Tool") and tool:FindFirstChild("Mechanics") then
                    task.wait(0.25)
                    hookRod(tool)
                end
            end)
        end
    end
end
hookAllRods()

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    hookAllRods()
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  CUTSCENE BROADCAST HOOK
-- ═══════════════════════════════════════════════════════════════════════════
pcall(function()
    local cb = ReplicatedStorage:WaitForChild("CutsceneBroadcast", 10)
    if not cb then return end

    cb.OnClientEvent:Connect(function(kind, pos, player)
        if not Config.GlobalCutsceneAlert then return end
        local who = (player and (player.DisplayName or player.Name)) or "Someone"

        if kind == "SecretCatch" and Config.GlobalCutsceneSecret then
            Stats.Global.Secret = Stats.Global.Secret + 1
            play(Config.RareSoundId, 0.5)
            toast("GLOBAL | SECRET", who .. " menangkap Secret!", 3)
        elseif kind == "Mythical" and Config.GlobalCutsceneMyth then
            Stats.Global.Mythical = Stats.Global.Mythical + 1
            play(Config.RareSoundId, 0.4)
            toast("GLOBAL | MYTHICAL", who .. " menangkap Mythical!", 3)
        elseif kind == "ForgottenCatch" and Config.GlobalCutsceneForgot then
            Stats.Global.Forgotten = Stats.Global.Forgotten + 1
            play(Config.SuperRareSoundId, 0.6)
            toast("GLOBAL | FORGOTTEN", who .. " menangkap FORGOTTEN!", 4)
        end
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  CORE EVENT TRACKER
-- ═══════════════════════════════════════════════════════════════════════════
task.spawn(function()
    if not CoreCfg or type(CoreCfg.Fase) ~= "function" then return end

    local lastState = nil
    local warned60  = false

    while task.wait(5) do
        if not Config.CoreEventTracker then continue end
        local ok, phase, remain = pcall(CoreCfg.Fase, os.time())
        if not ok then continue end

        if phase ~= lastState then
            lastState = phase
            warned60 = false
            if phase == "aktif" and Config.CoreEventAlertOpen then
                toast("WITHERING CORE", "Core Event AKTIF selama " .. fmtTime(remain), 5)
                play(Config.RareSoundId, 0.6)
            end
        end

        if phase == "tunggu" and Config.CoreEventWarn60s then
            if remain and remain <= 60 and not warned60 then
                warned60 = true
                toast("WITHERING CORE", "Core Event mulai dalam " .. fmtTime(remain), 4)
                play(Config.BiteSoundId, 0.4)
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  HOURLY EVENT TRACKER
-- ═══════════════════════════════════════════════════════════════════════════
task.spawn(function()
    if not EventCfg then return end
    if type(EventCfg.Acara) ~= "function" then return end
    if type(EventCfg.JamSekarang) ~= "function" then return end

    local lastTier = nil
    while task.wait(10) do
        if not Config.HourlyEventTracker then continue end
        local ok, info = pcall(function()
            return EventCfg.Acara(EventCfg.JamSekarang())
        end)
        if not ok or type(info) ~= "table" then continue end
        if info.tier ~= lastTier then
            lastTier = info.tier
            toast("EVENT JAM INI", tostring(info.tier) .. " | " .. tostring(info.ket or ""), 5)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  MAIN LOOP
-- ═══════════════════════════════════════════════════════════════════════════
local loopThread

local function startLoop()
    if loopThread then return end
    loopThread = task.spawn(function()
        while Config.AutoFish do
            if LocalPlayer.Character then
                local rod = getEquippedRod()
                if not rod and Config.AutoEquipBest then
                    equipBestRod()
                    task.wait(0.1)
                    rod = getEquippedRod()
                end

                if rod then
                    if Config.AggressiveMode then
                        if not fishingActive(rod) then
                            turboCast(rod)
                        end
                        task.wait(Config.TurboMode and Config.TurboInterval or 0.3)
                    else
                        turboCast(rod)
                        task.wait(Config.TurboMode and Config.TurboInterval or Config.NormalInterval)
                    end
                else
                    task.wait(0.3)
                end
            else
                task.wait(0.5)
            end
        end
        loopThread = nil
    end)
end

local function stopLoop()
    Config.AutoFish = false
end

-- ═══════════════════════════════════════════════════════════════════════════
--  ANTI-AFK
-- ═══════════════════════════════════════════════════════════════════════════
LocalPlayer.Idled:Connect(function()
    if not Config.AntiAFK then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  CHAT FILTER
-- ═══════════════════════════════════════════════════════════════════════════
pcall(function()
    local r = ReplicatedStorage:FindFirstChild("Remote")
    r = r and r:FindFirstChild("Admin")
    r = r and r:FindFirstChild("PesanChat")
    if not r then return end
    r.OnClientEvent:Connect(function(msg)
        if not Config.ChatFilterOn then return end
        if type(msg) ~= "string" then return end
        if not msg:find(Config.ChatFilterKeyword) then return end
        local clean = msg:gsub("<[^>]+>", "")
        play(Config.RareSoundId, 0.4)
        toast("GLOBAL RARE", clean:sub(1, 90), 3)
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  PLAYER RADAR
-- ═══════════════════════════════════════════════════════════════════════════
pcall(function()
    local e = ReplicatedStorage:WaitForChild("EfekMancingEvent", 5)
    if not e then return end
    e.OnClientEvent:Connect(function(action, a, _, c)
        if not Config.PlayerRadar then return end
        if action == "lempar" and typeof(a) == "Instance" then
            toast("RADAR | Cast", a.Name .. " casting", 1.5)
        elseif action == "dive" and typeof(a) == "Instance" then
            toast("RADAR | Dive", (c and c.Name or "?"), 1.5)
        end
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  UI
-- ═══════════════════════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name = "Soreya Fisher v4.1",
    LoadingTitle = "Memuat sistem...",
    LoadingSubtitle = "New update v4.1",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SoreyaAutoFish",
        FileName = "Config_v41",
    },
    Discord = { Enabled = false },
    KeySystem = false,
})

-- ─────────────────────────────────────────
--  TAB: MAIN
-- ─────────────────────────────────────────
local MainTab = Window:CreateTab("Main", nil)

MainTab:CreateSection("Master Control")

MainTab:CreateToggle({
    Name = "Auto Fishing",
    CurrentValue = false,
    Flag = "Master",
    Callback = function(v)
        Config.AutoFish = v
        if v then
            startLoop()
            Rayfield:Notify({ Title = "FASTER Fishing", Content = "AKTIF", Duration = 3 })
        else
            stopLoop()
            Rayfield:Notify({ Title = "FASTER Fishing", Content = "MATI", Duration = 3 })
        end
    end,
})

MainTab:CreateSection("FAST Engine")

MainTab:CreateToggle({
    Name = "FAST Mode (instant cast)",
    CurrentValue = true,
    Flag = "FAST",
    Callback = function(v) Config.TurboMode = v end,
})

MainTab:CreateToggle({
    Name = "Aggressive Mode (no idle)",
    CurrentValue = true,
    Flag = "Aggro",
    Callback = function(v) Config.AggressiveMode = v end,
})

MainTab:CreateSlider({
    Name = "Turbo Interval",
    Range = { 0.02, 0.5 },
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = 0.08,
    Flag = "TurboInt",
    Callback = function(v) Config.TurboInterval = v end,
})

MainTab:CreateSlider({
    Name = "Instant Release Delay",
    Range = { 0.01, 0.2 },
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = 0.03,
    Flag = "InstantD",
    Callback = function(v) Config.InstantDelay = v end,
})

MainTab:CreateSlider({
    Name = "Win Burst (max 3 anti-spam)",
    Range = { 1, 3 },
    Increment = 1,
    CurrentValue = 1,
    Flag = "WinBurst",
    Callback = function(v) Config.WinBurst = math.clamp(v, 1, 3) end,
})

MainTab:CreateToggle({
    Name = "Anti Duplicate Bite",
    CurrentValue = true,
    Flag = "AntiDupBite",
    Callback = function(v) Config.AntiDuplicateBite = v end,
})

MainTab:CreateSection("Cast")

MainTab:CreateToggle({
    Name = "Perfect Power",
    CurrentValue = true,
    Flag = "Perfect",
    Callback = function(v) Config.PerfectPower = v end,
})

MainTab:CreateSlider({
    Name = "Power Min",
    Range = { 60, 100 }, Increment = 1, Suffix = "%",
    CurrentValue = 92, Flag = "MinP",
    Callback = function(v) Config.MinPower = v end,
})

MainTab:CreateSlider({
    Name = "Power Max",
    Range = { 60, 100 }, Increment = 1, Suffix = "%",
    CurrentValue = 100, Flag = "MaxP",
    Callback = function(v) Config.MaxPower = v end,
})

MainTab:CreateToggle({
    Name = "Auto Win Minigame",
    CurrentValue = true,
    Flag = "AutoWin",
    Callback = function(v) Config.AutoWin = v end,
})

MainTab:CreateToggle({
    Name = "Auto Equip Best Rod",
    CurrentValue = true,
    Flag = "AutoEq",
    Callback = function(v) Config.AutoEquipBest = v end,
})

-- ─────────────────────────────────────────
--  TAB: ALERTS
-- ─────────────────────────────────────────
local AlertTab = Window:CreateTab("Alerts", nil)
AlertTab:CreateSection("Notifications")

AlertTab:CreateToggle({
    Name = "Bite Alert",
    CurrentValue = true, Flag = "BA",
    Callback = function(v) Config.BiteAlert = v end,
})

AlertTab:CreateToggle({
    Name = "Rare Catch Alert",
    CurrentValue = true, Flag = "RA",
    Callback = function(v) Config.RareAlert = v end,
})

AlertTab:CreateDropdown({
    Name = "Minimum Rarity",
    Options = { "UnCommon", "Rare", "Epic", "Legendary", "Mythical", "Secret" },
    CurrentOption = { "Legendary" },
    MultipleOptions = false,
    Flag = "RThr",
    Callback = function(o)
        Config.RareThreshold = type(o) == "table" and o[1] or o
    end,
})

AlertTab:CreateSection("Global Cutscene Alert")

AlertTab:CreateToggle({
    Name = "Enable Global Alert",
    CurrentValue = true, Flag = "GCA",
    Callback = function(v) Config.GlobalCutsceneAlert = v end,
})

AlertTab:CreateToggle({
    Name = "Show Secret (orang lain)",
    CurrentValue = true, Flag = "GCSec",
    Callback = function(v) Config.GlobalCutsceneSecret = v end,
})

AlertTab:CreateToggle({
    Name = "Show Mythical (orang lain)",
    CurrentValue = true, Flag = "GCMyth",
    Callback = function(v) Config.GlobalCutsceneMyth = v end,
})

AlertTab:CreateToggle({
    Name = "Show Forgotten (orang lain)",
    CurrentValue = true, Flag = "GCForg",
    Callback = function(v) Config.GlobalCutsceneForgot = v end,
})

AlertTab:CreateSection("Event Tracker")

AlertTab:CreateToggle({
    Name = "Withering Core Tracker",
    CurrentValue = true, Flag = "CET",
    Callback = function(v) Config.CoreEventTracker = v end,
})

AlertTab:CreateToggle({
    Name = "Warn 60s sebelum Core",
    CurrentValue = true, Flag = "CEW",
    Callback = function(v) Config.CoreEventWarn60s = v end,
})

AlertTab:CreateToggle({
    Name = "Alert saat Core Event buka",
    CurrentValue = true, Flag = "CEA",
    Callback = function(v) Config.CoreEventAlertOpen = v end,
})

AlertTab:CreateToggle({
    Name = "Hourly Event Tracker",
    CurrentValue = true, Flag = "HET",
    Callback = function(v) Config.HourlyEventTracker = v end,
})

-- ─────────────────────────────────────────
--  TAB: WEBHOOK
-- ─────────────────────────────────────────
local WebhookTab = Window:CreateTab("Webhook", nil)
WebhookTab:CreateSection("Discord Integration")

WebhookTab:CreateToggle({
    Name = "Enable Webhook",
    CurrentValue = false,
    Flag = "WHEn",
    Callback = function(v) Config.WebhookEnabled = v end,
})

local WebhookStatus = WebhookTab:CreateLabel("Webhook: belum diatur")

WebhookTab:CreateInput({
    Name = "Paste Webhook URL",
    CurrentValue = "",
    PlaceholderText = "Tempel URL lalu otomatis tersimpan & tersembunyi",
    RemoveTextAfterFocusLost = true,
    Flag = "WHUrl",
    Callback = function(text)
        if type(text) ~= "string" then return end
        text = text:gsub("%s+", "")
        if text == "" then return end

        if not text:find("discord") and not text:find("http") then
            pcall(function() WebhookStatus:Set("URL tidak valid") end)
            return
        end

        Config.WebhookUrl = text
        pcall(function() WebhookStatus:Set("Webhook tersimpan & tersembunyi") end)

        task.spawn(function()
            local ok = httpPost(Config.WebhookUrl, {
                username   = "Soreya Turbo Fisher",
                avatar_url = getAvatarUrl(LocalPlayer.UserId),
                embeds = {{
                    title       = "Webhook Terhubung",
                    description = "Koneksi berhasil. Siap menerima notifikasi tangkapan langka.",
                    color       = 0x57BB8A,
                    footer      = { text = "Soreya Turbo Fisher v4.1" },
                    timestamp   = DateTime.now():ToIsoDate(),
                }},
            })
            pcall(function()
                WebhookStatus:Set(ok and "Webhook aktif & teruji" or "Tersimpan, gagal tes")
            end)
        end)
    end,
})

WebhookTab:CreateButton({
    Name = "Hapus Webhook Tersimpan",
    Callback = function()
        Config.WebhookUrl = ""
        pcall(function() WebhookStatus:Set("Webhook: belum diatur") end)
        Rayfield:Notify({ Title = "Webhook", Content = "URL dihapus", Duration = 3 })
    end,
})

WebhookTab:CreateSection("Filters")

WebhookTab:CreateDropdown({
    Name = "Minimum Rarity",
    Options = { "Epic", "Legendary", "Mythical", "Secret", "FORGOTTEN" },
    CurrentOption = { "Secret" },
    MultipleOptions = false,
    Flag = "WHMin",
    Callback = function(o)
        Config.WebhookMinRarity = type(o) == "table" and o[1] or o
    end,
})

WebhookTab:CreateToggle({
    Name = "Sertakan Thumbnail Ikan",
    CurrentValue = true, Flag = "WHThumb",
    Callback = function(v) Config.WebhookWithThumb = v end,
})

WebhookTab:CreateToggle({
    Name = "Sertakan Gambar Besar Ikan",
    CurrentValue = true, Flag = "WHImg",
    Callback = function(v) Config.WebhookWithImage = v end,
})

WebhookTab:CreateToggle({
    Name = "Warna Embed Ikut Mutasi",
    CurrentValue = true, Flag = "WHMutCol",
    Callback = function(v) Config.WebhookWithMutColor = v end,
})

WebhookTab:CreateSection("Test")

WebhookTab:CreateButton({
    Name = "Test dengan Ikan Contoh (Secret)",
    Callback = function()
        if Config.WebhookUrl == "" then
            Rayfield:Notify({ Title = "Webhook", Content = "URL belum diatur", Duration = 3 })
            return
        end
        sendWebhook({
            baseName = "Crystal Goliath",
            rarity   = "Secret",
            mutation = "Radioactive",
            weight   = 1234.56,
            chance   = 0.000004,
            big      = true,
        })
        Rayfield:Notify({ Title = "Webhook", Content = "Test dikirim!", Duration = 3 })
    end,
})

-- ─────────────────────────────────────────
--  TAB: INVENTORY
-- ─────────────────────────────────────────
local InvTab = Window:CreateTab("Inventory", nil)
InvTab:CreateSection("Auto Sell")

InvTab:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = false, Flag = "Sell",
    Callback = function(v) Config.AutoSell = v end,
})

InvTab:CreateDropdown({
    Name = "Sell Below Rarity",
    Options = { "Common", "UnCommon", "Rare", "Epic", "Legendary" },
    CurrentOption = { "Rare" },
    MultipleOptions = false,
    Flag = "SellR",
    Callback = function(o)
        Config.SellBelow = type(o) == "table" and o[1] or o
    end,
})

InvTab:CreateToggle({
    Name = "Keep Shiny",
    CurrentValue = true, Flag = "KeepS",
    Callback = function(v) Config.KeepShiny = v end,
})

InvTab:CreateToggle({
    Name = "Keep Big",
    CurrentValue = true, Flag = "KeepB",
    Callback = function(v) Config.KeepBig = v end,
})

InvTab:CreateSection("Utility")

InvTab:CreateButton({
    Name = "Force Equip Best Rod",
    Callback = function()
        local r = equipBestRod()
        Rayfield:Notify({
            Title = "Equip",
            Content = r and ("Equipped: " .. r.Name) or "Tidak ada rod",
            Duration = 3,
        })
    end,
})

InvTab:CreateButton({
    Name = "Unhook All Rods",
    Callback = function()
        for _, c in ipairs(LocalPlayer:GetChildren()) do
            if c:IsA("Backpack") then
                for _, t in ipairs(c:GetChildren()) do
                    if t:IsA("Tool") then
                        t:SetAttribute("SoreyaHooked", nil)
                    end
                end
            end
        end
        Rayfield:Notify({ Title = "Reset", Content = "Rods di-unhook", Duration = 3 })
    end,
})

-- ─────────────────────────────────────────
--  TAB: STATS
-- ─────────────────────────────────────────
local StatTab = Window:CreateTab("Stats", nil)
StatTab:CreateSection("Live Session")

local L1 = StatTab:CreateLabel("Catches: 0 | Casts: 0 | Failed: 0")
local L2 = StatTab:CreateLabel("Rate: 0.0 /min | Peak: 0.0 /min")
local L3 = StatTab:CreateLabel("Best: -")
local L4 = StatTab:CreateLabel("SECRET: 0 | FORGOTTEN: 0 | Mythical: 0 | Legendary: 0")
local L5 = StatTab:CreateLabel("Global: Secret 0 | Myth 0 | Forgotten 0")

task.spawn(function()
    while task.wait(0.5) do
        local up  = os.clock() - Stats.StartTime
        local min = up / 60
        local rate = min > 0 and (Stats.Catches / min) or 0
        if rate > Stats.PeakRate then Stats.PeakRate = rate end

        pcall(function()
            L1:Set(string.format("Catches: %d | Casts: %d | Failed: %d",
                Stats.Catches, Stats.Casts, Stats.Failed))
            L2:Set(string.format("Rate: %.1f /min | Peak: %.1f /min | Uptime: %dm",
                rate, Stats.PeakRate, math.floor(min)))
            L3:Set(string.format("Best: %s [%s] %.2fkg (%s)",
                Stats.Best.name, Stats.Best.rarity, Stats.Best.weight, Stats.Best.mutation))
            local r = Stats.Rarity
            L4:Set(string.format("SECRET: %d | FORGOTTEN: %d | Mythical: %d | Legendary: %d",
                (r.Secret or 0) + (r.SECRET or 0),
                (r.FORGOTTEN or 0) + (r.Forgotten or 0),
                (r.Mythical or 0) + (r.Mythic or 0),
                r.Legendary or 0))
            L5:Set(string.format("Global: Secret %d | Myth %d | Forgotten %d",
                Stats.Global.Secret, Stats.Global.Mythical, Stats.Global.Forgotten))
        end)
    end
end)

StatTab:CreateButton({
    Name = "Reset Stats",
    Callback = function()
        Stats.Catches, Stats.Casts, Stats.Failed = 0, 0, 0
        Stats.Perfect, Stats.Good = 0, 0
        Stats.PeakRate = 0
        Stats.StartTime = os.clock()
        Stats.Best = { name = "-", rarity = "-", weight = 0, mutation = "-" }
        Stats.Rarity = {
            Common=0, UnCommon=0, Rare=0, Epic=0, Legendary=0,
            Mythical=0, Secret=0, FORGOTTEN=0,
        }
        Stats.Global = { Secret=0, Mythical=0, Forgotten=0 }
        Rayfield:Notify({ Title = "Stats", Content = "Reset", Duration = 2 })
    end,
})

-- ─────────────────────────────────────────
--  TAB: EXTRA
-- ─────────────────────────────────────────
local ExtraTab = Window:CreateTab("Extra", nil)
ExtraTab:CreateSection("Misc")

ExtraTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = true, Flag = "AFK",
    Callback = function(v) Config.AntiAFK = v end,
})

ExtraTab:CreateToggle({
    Name = "Player Radar",
    CurrentValue = false, Flag = "Radar",
    Callback = function(v) Config.PlayerRadar = v end,
})

ExtraTab:CreateSection("Chat Filter")

ExtraTab:CreateToggle({
    Name = "Custom Chat Filter",
    CurrentValue = false, Flag = "CF",
    Callback = function(v) Config.ChatFilterOn = v end,
})

ExtraTab:CreateInput({
    Name = "Chat Keyword",
    CurrentValue = "SECRET",
    RemoveTextAfterFocusLost = false,
    Flag = "CFKey",
    Callback = function(t)
        if t and t ~= "" then Config.ChatFilterKeyword = t end
    end,
})

ExtraTab:CreateSection("Quick Actions")

ExtraTab:CreateButton({
    Name = "Force One Turbo Cast",
    Callback = function()
        task.spawn(function()
            local r = getEquippedRod() or equipBestRod()
            if r then turboCast(r) end
        end)
    end,
})

ExtraTab:CreateButton({
    Name = "Burst Cast x5",
    Callback = function()
        task.spawn(function()
            local r = getEquippedRod() or equipBestRod()
            if not r then return end
            for i = 1, 5 do
                turboCast(r)
                task.wait(0.15)
            end
            Rayfield:Notify({ Title = "Burst", Content = "5 cast terkirim", Duration = 3 })
        end)
    end,
})

ExtraTab:CreateSection("Info")

ExtraTab:CreateButton({
    Name = "Cek Core Event Sekarang",
    Callback = function()
        if not CoreCfg or type(CoreCfg.Fase) ~= "function" then
            Rayfield:Notify({ Title = "Core", Content = "CoreConfig tidak tersedia", Duration = 3 })
            return
        end
        local ok, phase, remain = pcall(CoreCfg.Fase, os.time())
        if ok then
            Rayfield:Notify({
                Title = "Withering Core",
                Content = string.format("%s | %s", tostring(phase), fmtTime(remain)),
                Duration = 5,
            })
        end
    end,
})

ExtraTab:CreateButton({
    Name = "Cek Event Jam Ini",
    Callback = function()
        if not EventCfg or type(EventCfg.Acara) ~= "function" then
            Rayfield:Notify({ Title = "Event", Content = "EventOtomatis tidak tersedia", Duration = 3 })
            return
        end
        local ok, info = pcall(function()
            return EventCfg.Acara(EventCfg.JamSekarang())
        end)
        if ok and type(info) == "table" then
            Rayfield:Notify({
                Title = "Event Jam Ini",
                Content = tostring(info.tier) .. " | " .. tostring(info.ket or ""),
                Duration = 6,
            })
        end
    end,
})

-- ═══════════════════════════════════════════════════════════════════════════
--  HOTKEY
-- ═══════════════════════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Config.AutoFish = not Config.AutoFish
        if Config.AutoFish then startLoop() else stopLoop() end
        toast("Soreya", Config.AutoFish and "Turbo ON" or "Turbo OFF", 2)
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
--  READY
-- ═══════════════════════════════════════════════════════════════════════════
Rayfield:Notify({
    Title = "Soreya Fisher v4.1",
    Content = "Ready. RightShift = toggle cepat.",
    Duration = 6,
})
toast("Soreya", "Fisher v4.1 siap!", 3)
print("[Soreya] Turbo Fisher v4.1 loaded.")