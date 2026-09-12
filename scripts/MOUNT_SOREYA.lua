
-- ═══════════════════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")
local SoundService      = game:GetService("SoundService")
local StarterGui        = game:GetService("StarterGui")
local VirtualUser       = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer

local RS_MODULES = ReplicatedStorage:WaitForChild("Modules", 20)
local RS_FISHING = RS_MODULES and RS_MODULES:WaitForChild("Fishing", 20)

-- ═══════════════════════════════════════════════════════════════
--  LOAD RAYFIELD
-- ═══════════════════════════════════════════════════════════════
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
        if ok and res then Rayfield = res break end
    end
    if not Rayfield then
        error("[Soreya] Gagal memuat Rayfield. Cek koneksi internet.")
    end
end

-- ═══════════════════════════════════════════════════════════════
--  CONFIG
-- ═══════════════════════════════════════════════════════════════
local Config = {
    -- Master
    AutoFish          = false,
    TurboMode         = true,
    AggressiveMode    = true,

    -- Speed
    TurboInterval     = 0.08,
    NormalInterval    = 1.40,
    InstantDelay      = 0.03,
    WinBurst          = 3,

    -- Cast
    PerfectPower      = true,
    MinPower          = 92,
    MaxPower          = 100,
    AutoEquipBest     = true,

    -- Sell
    AutoSell          = false,
    SellBelow         = "Rare",
    KeepShiny         = true,
    KeepBig           = true,

    -- Alerts
    BiteAlert         = true,
    BiteSoundId       = "rbxassetid://123845773202915",
    RareAlert         = true,
    RareSoundId       = "rbxassetid://133304152585589",
    RareThreshold     = "Legendary",

    -- Webhook
    WebhookEnabled    = false,
    WebhookUrl        = "",  -- disimpan internal, tidak ditampilkan di UI
    WebhookMinRarity  = "Secret",
    WebhookWithImage  = true,
    WebhookWithThumb  = true,

    -- Misc
    AntiAFK           = true,
    PlayerRadar       = false,
    ChatFilterOn      = false,
    ChatFilterKeyword = "SECRET",
}

-- ═══════════════════════════════════════════════════════════════
--  DATABASES
-- ═══════════════════════════════════════════════════════════════
local FishDB, ItemDB
pcall(function() FishDB = require(RS_FISHING:WaitForChild("FishingImageDatabase")) end)
pcall(function() ItemDB = require(RS_FISHING:WaitForChild("ItemDatabase")) end)

-- ═══════════════════════════════════════════════════════════════
--  CONSTANTS
-- ═══════════════════════════════════════════════════════════════
local RARITY_RANK = {
    Common=1, UnCommon=2, Rare=3, Epic=4, Legendary=5,
    Mythical=6, Mythic=6, Secret=7, SECRET=7, FORGOTTEN=8, Forgotten=8,
}

local RARITY_COLOR = {
    Common    = 0xB1B1B1,
    UnCommon  = 0x80FF52,
    Rare      = 0x55A2FF,
    Epic      = 0xB272F7,
    Legendary = 0xFFB82A,
    Mythical  = 0xFF64C8,
    Mythic    = 0xFF64C8,
    Secret    = 0x17FF97,
    SECRET    = 0x17FF97,
    FORGOTTEN = 0x7F7F7F,
    Forgotten = 0x7F7F7F,
}

local RARITY_ICON = {
    Common    = "⚪",
    UnCommon  = "🟢",
    Rare      = "🔵",
    Epic      = "🟣",
    Legendary = "🟡",
    Mythical  = "🌸",
    Mythic    = "🌸",
    Secret    = "💚",
    SECRET    = "💚",
    FORGOTTEN = "⚫",
    Forgotten = "⚫",
}

local function rank(n) return RARITY_RANK[n] or 0 end
local function meets(n, min) return rank(n) >= rank(min) end

-- ═══════════════════════════════════════════════════════════════
--  STATS
-- ═══════════════════════════════════════════════════════════════
local Stats = {
    Catches   = 0,
    Casts     = 0,
    Failed    = 0,
    Perfect   = 0,
    Good      = 0,
    PeakRate  = 0,
    StartTime = os.clock(),
    Best      = { name = "-", rarity = "-", weight = 0, mutation = "-" },
    Rarity    = { Common=0, UnCommon=0, Rare=0, Epic=0, Legendary=0, Mythical=0, Secret=0, FORGOTTEN=0 },
}

-- ═══════════════════════════════════════════════════════════════
--  UTILITIES
-- ═══════════════════════════════════════════════════════════════
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
        s.SoundId, s.Volume, s.Parent = id, vol or 0.6, SoundService
        s:Play()
        task.delay(4, function() s:Destroy() end)
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

-- fetch image url from roblox thumbnail api (cached)
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
    -- fallback: direct url
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

local function humanNumber(n)
    n = tonumber(n) or 0
    if n >= 1e9 then return string.format("%.1fB", n/1e9) end
    if n >= 1e6 then return string.format("%.1fM", n/1e6) end
    if n >= 1e3 then return string.format("%.1fK", n/1e3) end
    if n >= 1 then return tostring(math.floor(n)) end
    if n >= 0.001 then return tostring(math.floor(1/n)) end
    return tostring(n)
end

local function chanceText(chance)
    if not chance or chance <= 0 then return "?" end
    local one = 1 / chance
    if one >= 1e9 then return string.format("1 in %.1fB", one/1e9) end
    if one >= 1e6 then return string.format("1 in %.1fM", one/1e6) end
    if one >= 1e3 then return string.format("1 in %.1fK", one/1e3) end
    return string.format("1 in %d", math.floor(one))
end

-- ═══════════════════════════════════════════════════════════════
--  ROD UTILITIES
-- ═══════════════════════════════════════════════════════════════
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
                local tier = rd and rd.Tier or 1
                local price = rd and rd.Price or 0
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

-- ═══════════════════════════════════════════════════════════════
--  TURBO CAST
-- ═══════════════════════════════════════════════════════════════
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
    if power >= 85 then Stats.Perfect = Stats.Perfect + 1
    elseif power >= 70 then Stats.Good = Stats.Good + 1 end
    return true
end

-- ═══════════════════════════════════════════════════════════════
--  RICH WEBHOOK BUILDER
-- ═══════════════════════════════════════════════════════════════
local function buildWebhookPayload(data)
    local rarity = data.rarity or "Common"
    local mutation = data.mutation or "Normal"
    local isNormal = (mutation == "Normal" or mutation == "")

    local fishName = data.baseName or data.originalName or "Unknown"
    local weight = data.weight or 0
    local chance = data.chance or 0
    local big = data.big and "**BIG** " or ""
    local shiny = data.shiny and "✨ " or ""

    local color = RARITY_COLOR[rarity] or 0x5865F2
    local rIcon = RARITY_ICON[rarity] or "⚪"

    -- fish image
    local fishImageUrl
    if Config.WebhookWithImage and FishDB then
        pcall(function()
            local icon = FishDB.GetIcon(fishName)
            fishImageUrl = getImageUrl(icon)
        end)
    end

    -- build fields
    local fields = {
        { name = "🧬 Mutation", value = isNormal and "`Normal`" or ("`" .. mutation .. "`"), inline = true },
        { name = "⚖️ Weight",   value = string.format("`%.2f kg`", weight), inline = true },
        { name = "💠 Rarity",   value = string.format("`%s %s`", rIcon, rarity), inline = true },
        { name = "🎲 Chance",   value = "`" .. chanceText(chance) .. "`", inline = true },
        { name = "🎣 Fisher",   value = "`" .. LocalPlayer.DisplayName .. "`", inline = true },
        { name = "⏰ Time",     value = "`" .. os.date("%H:%M:%S") .. "`", inline = true },
    }

    local embed = {
        title       = string.format("%s %s CATCH!", shiny, rarity:upper()),
        description = string.format("%s**%s**", big, fishName),
        color       = color,
        fields      = fields,
        footer      = {
            text     = "Soreya Turbo Fisher • " .. LocalPlayer.Name,
            icon_url = getAvatarUrl(LocalPlayer.UserId),
        },
        timestamp   = DateTime.now():ToIsoDate(),
    }

    if fishImageUrl then
        if Config.WebhookWithThumb then embed.thumbnail = { url = fishImageUrl } end
        embed.image = { url = fishImageUrl }
    end

    return {
        username    = "Soreya Turbo Fisher",
        avatar_url  = getAvatarUrl(LocalPlayer.UserId),
        embeds      = { embed },
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

-- ═══════════════════════════════════════════════════════════════
--  ROD HOOKING
-- ═══════════════════════════════════════════════════════════════
local function hookRod(rod)
    if not rod or rod:GetAttribute("SoreyaHooked") then return end
    rod:SetAttribute("SoreyaHooked", true)

    local remotes = getRemotes(rod)
    if not remotes then
        task.delay(0.5, function() hookRod(rod) end)
        return
    end

    -- ── MiniGame ──
    local mg = remotes:WaitForChild("MiniGame", 10)
    if mg then
        mg.OnClientEvent:Connect(function(action, data)
            if action ~= "Start" then return end

            if type(data) == "table" then
                local rar = data.rarity or "Common"
                local nm  = data.name or "?"
                local ch  = data.chance or 0
                local w   = data.weight or 0
                local line = string.format("%s • %s • %.2fkg",
                    nm, chanceText(ch), w)

                if Config.RareAlert and meets(rar, Config.RareThreshold) then
                    play(Config.RareSoundId, 0.7)
                    toast(RARITY_ICON[rar] .. " RARE BITE", line, 3)
                elseif Config.BiteAlert then
                    play(Config.BiteSoundId, 0.5)
                    toast("🎣 Bite", line, 1.5)
                end
            end

            if Config.AutoWin then
                if Config.TurboMode then
                    task.spawn(function()
                        for i = 1, math.max(1, Config.WinBurst) do
                            pcall(function() mg:FireServer(true) end)
                            if i < Config.WinBurst then task.wait(0.01) end
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

    -- ── NotifyClient ──
    local nc = remotes:WaitForChild("NotifyClient", 10)
    if nc then
        nc.OnClientEvent:Connect(function(action, data)
            if action == "Bite" then
                if Config.BiteAlert and not Config.TurboMode then
                    play(Config.BiteSoundId, 0.4)
                end
                return
            end

            if action ~= "GotFish" or type(data) ~= "table" then return end

            -- ── stats ──
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

            -- ── alert ──
            if Config.RareAlert and meets(rar, Config.RareThreshold) then
                play(Config.RareSoundId, 0.7)
                toast("🎉 " .. rar,
                    string.format("%s%s %s (%.2fkg)", big, mut, nm, w), 3)
            end

            -- ── webhook ──
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

-- ═══════════════════════════════════════════════════════════════
--  MAIN LOOP
-- ═══════════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════════
--  ANTI-AFK
-- ═══════════════════════════════════════════════════════════════
LocalPlayer.Idled:Connect(function()
    if not Config.AntiAFK then return end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- ═══════════════════════════════════════════════════════════════
--  CHAT FILTER
-- ═══════════════════════════════════════════════════════════════
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
        toast("📢 GLOBAL RARE", clean:sub(1, 90), 3)
    end)
end)

-- ═══════════════════════════════════════════════════════════════
--  PLAYER RADAR
-- ═══════════════════════════════════════════════════════════════
pcall(function()
    local e = ReplicatedStorage:WaitForChild("EfekMancingEvent", 5)
    if not e then return end
    e.OnClientEvent:Connect(function(action, a, _, c)
        if not Config.PlayerRadar then return end
        if action == "lempar" and typeof(a) == "Instance" then
            toast("📡 Cast", a.Name .. " casting", 1.5)
        elseif action == "dive" and typeof(a) == "Instance" then
            toast("📡 Dive", (c and c.Name or "?"), 1.5)
        end
    end)
end)

-- ═══════════════════════════════════════════════════════════════
--  UI
-- ═══════════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name = "Soreya Turbo Fisher",
    LoadingTitle = "Memuat sistem...",
    LoadingSubtitle = "Turbo Edition v3.0",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SoreyaAutoFish",
        FileName = "Config_v3",
    },
    Discord = { Enabled = false },
    KeySystem = false,
})

-- ─────────────────────────────────────────
--  TAB: MAIN
-- ─────────────────────────────────────────
local MainTab = Window:CreateTab("🎣 Main", nil)

MainTab:CreateSection("Master Control")

MainTab:CreateToggle({
    Name = "⚡ Auto Fishing",
    CurrentValue = false,
    Flag = "Master",
    Callback = function(v)
        Config.AutoFish = v
        if v then
            startLoop()
            Rayfield:Notify({ Title = "Turbo Fishing", Content = "AKTIF", Duration = 3 })
        else
            stopLoop()
            Rayfield:Notify({ Title = "Turbo Fishing", Content = "MATI", Duration = 3 })
        end
    end,
})

MainTab:CreateSection("Turbo Engine")

MainTab:CreateToggle({
    Name = "⚡ Turbo Mode (instant cast)",
    CurrentValue = true,
    Flag = "Turbo",
    Callback = function(v) Config.TurboMode = v end,
})

MainTab:CreateToggle({
    Name = "🔥 Aggressive Mode (no idle)",
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
    Name = "🀄 Win Burst (fire true × N)",
    Range = { 1, 10 },
    Increment = 1,
    CurrentValue = 3,
    Flag = "WinBurst",
    Callback = function(v) Config.WinBurst = v end,
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
local AlertTab = Window:CreateTab("🔔 Alerts", nil)
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

-- ─────────────────────────────────────────
--  TAB: WEBHOOK
-- ─────────────────────────────────────────
local WebhookTab = Window:CreateTab("🌐 Webhook", nil)
WebhookTab:CreateSection("Discord Integration")

WebhookTab:CreateToggle({
    Name = "Enable Webhook",
    CurrentValue = false,
    Flag = "WHEn",
    Callback = function(v) Config.WebhookEnabled = v end,
})

-- status label (menggantikan display URL)
local WebhookStatus = WebhookTab:CreateLabel("🔒 Webhook: belum diatur")

-- input URL — hidden setelah focus lost
WebhookTab:CreateInput({
    Name = "Paste Webhook URL",
    CurrentValue = "",
    PlaceholderText = "Tempel URL → otomatis tersimpan & tersembunyi",
    RemoveTextAfterFocusLost = true,   -- ✨ URL tidak ditampilkan lagi
    Flag = "WHUrl",
    Callback = function(text)
        if type(text) ~= "string" then return end
        text = text:gsub("%s+", "")
        if text == "" then return end

        -- validasi sederhana
        if not text:find("discord") and not text:find("http") then
            WebhookStatus:Set("❌ URL tidak valid")
            return
        end

        Config.WebhookUrl = text
        WebhookStatus:Set("✅ Webhook tersimpan & tersembunyi")

        -- test cepat
        task.spawn(function()
            local ok = httpPost(Config.WebhookUrl, {
                username   = "Soreya Turbo Fisher",
                avatar_url = getAvatarUrl(LocalPlayer.UserId),
                embeds = {{
                    title       = "✅ Webhook Terhubung",
                    description = "Koneksi berhasil. Siap menerima notifikasi tangkapan langka!",
                    color       = 0x57BB8A,
                    footer      = { text = "Soreya Turbo Fisher v3.0" },
                    timestamp   = DateTime.now():ToIsoDate(),
                }},
            })
            WebhookStatus:Set(ok and "🟢 Webhook aktif & teruji" or "⚠️ Tersimpan, gagal tes")
        end)
    end,
})

WebhookTab:CreateButton({
    Name = "🗑️ Hapus Webhook Tersimpan",
    Callback = function()
        Config.WebhookUrl = ""
        WebhookStatus:Set("🔒 Webhook: belum diatur")
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

WebhookTab:CreateSection("Test")

WebhookTab:CreateButton({
    Name = "🧪 Test dengan Ikan Contoh (Secret)",
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
local InvTab = Window:CreateTab("🎒 Inventory", nil)
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
local StatTab = Window:CreateTab("📊 Stats", nil)
StatTab:CreateSection("Live Session")

local L1 = StatTab:CreateLabel("Catches: 0 | Casts: 0 | Failed: 0")
local L2 = StatTab:CreateLabel("Rate: 0.0 /min | Peak: 0.0 /min")
local L3 = StatTab:CreateLabel("Best: -")
local L4 = StatTab:CreateLabel("SECRET: 0 | FORGOTTEN: 0 | Myth: 0 | Leg: 0")

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
                (r.Secret + r.SECRET), (r.FORGOTTEN + r.Forgotten),
                (r.Mythical + r.Mythic), r.Legendary))
        end)
    end
end)

StatTab:CreateButton({
    Name = "Reset Stats",
    Callback = function()
        Stats.Catches, Stats.Casts, Stats.Failed, Stats.Perfect, Stats.Good = 0,0,0,0,0
        Stats.PeakRate = 0
        Stats.StartTime = os.clock()
        Stats.Best = { name = "-", rarity = "-", weight = 0, mutation = "-" }
        Stats.Rarity = { Common=0, UnCommon=0, Rare=0, Epic=0, Legendary=0, Mythical=0, Secret=0, FORGOTTEN=0 }
        Rayfield:Notify({ Title = "Stats", Content = "Reset", Duration = 2 })
    end,
})

-- ─────────────────────────────────────────
--  TAB: EXTRA
-- ─────────────────────────────────────────
local ExtraTab = Window:CreateTab("⚙ Extra", nil)
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
    Name = "🔥 Force One Turbo Cast",
    Callback = function()
        task.spawn(function()
            local r = getEquippedRod() or equipBestRod()
            if r then turboCast(r) end
        end)
    end,
})

ExtraTab:CreateButton({
    Name = "🎯 Burst Cast ×5",
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

-- ═══════════════════════════════════════════════════════════════
--  HOTKEY
-- ═══════════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Config.AutoFish = not Config.AutoFish
        if Config.AutoFish then startLoop() else stopLoop() end
        toast("Soreya", Config.AutoFish and "⚡ Turbo ON" or "⏹ Turbo OFF", 2)
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  READY
-- ═══════════════════════════════════════════════════════════════
Rayfield:Notify({
    Title = "Soreya Fisher v3.0",
    Content = "Ready. RightShift = toggle cepat.",
    Duration = 6,
})
toast("Soreya", " Fisher siap!", 3)
print("[Soreya] Turbo Fisher v3.0 loaded.")