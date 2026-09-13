--[[
    ╔══════════════════════════════════════════════════════════╗
    ║   EVENT_Hole_Fishing | MIZUKAGE HUB v7.0                ║
    ║   UI: Rayfield Interface Suite                          ║
    ║   Full Feature Script                                   ║
    ╚══════════════════════════════════════════════════════════╝
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ═══════════════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Remote Events
local RequestRoll     = Remotes:WaitForChild("RequestRoll")
local CastRoll        = Remotes:WaitForChild("CastRoll")
local CaughtFish      = Remotes:WaitForChild("CaughtFish")
local CatchFailed     = Remotes:WaitForChild("CatchFailed")
local SellInventory   = Remotes:WaitForChild("SellInventory")
local BuyUpgrade      = Remotes:WaitForChild("BuyUpgrade")
local BuyRod          = Remotes:WaitForChild("BuyRod")
local DoRebirth       = Remotes:WaitForChild("DoRebirth")
local SetAutoSell     = Remotes:WaitForChild("SetAutoSell")
local FunnelSignal    = Remotes:WaitForChild("FunnelSignal")

-- ═══════════════════════════════════════════════════════════
-- MODULES
-- ═══════════════════════════════════════════════════════════
local FishConfig, RodsConfig, MutationConfig, RebirthConfig, UpgradesConfig
pcall(function()
    FishConfig     = require(ReplicatedStorage:WaitForChild("FishConfig"))
    RodsConfig     = require(ReplicatedStorage:WaitForChild("RodsConfig"))
    MutationConfig = require(ReplicatedStorage:WaitForChild("MutationConfig"))
    RebirthConfig  = require(ReplicatedStorage:WaitForChild("RebirthConfig"))
    UpgradesConfig = require(ReplicatedStorage:WaitForChild("UpgradesConfig"))
end)

-- ═══════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════
local State = {
    -- Fishing
    AutoFish = false,
    PerfectCast = false,
    InstantCatch = false,
    AlwaysPerfect = false,
    AutoCast = false,
    AutoBite = false,
    
    -- Economy
    AutoSell = false,
    AutoSellRarities = {},
    AutoSellOnFull = false,
    AutoRebirth = false,
    AutoRebirthAmount = 0,
    AutoUpgrade = false,
    AutoUpgradeType = "Sell",
    AutoBuyRod = false,
    AutoBuyRodTarget = "",
    
    -- Attributes
    LuckBoost = 1,
    CashMultiplier = 1,
    ReelSpeed = 1,
    SkipCutscenes = "Off",
    InfiniteBag = false,
    SuperLucky = false,
    VIP = false,
    
    -- Filter
    FishFilterEnabled = false,
    FishFilterRarities = {},
    FishFilterMinKg = 0,
    
    -- Stats
    Stats = {
        TotalCaught = 0,
        TotalValue = 0,
        TotalKg = 0,
        RarityCount = {},
        RecentCatches = {},
        SessionStart = os.time(),
    },
    
    -- Internal
    Connections = {},
    CurrentBite = nil,
}

-- ═══════════════════════════════════════════════════════════
-- UTIL: Format angka
-- ═══════════════════════════════════════════════════════════
local function formatNumber(n)
    n = tonumber(n) or 0
    local s = tostring(math.floor(n))
    local result = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return result
end

local function formatCash(n)
    n = tonumber(n) or 0
    if n >= 1e15 then return ("%.2fQa"):format(n/1e15)
    elseif n >= 1e12 then return ("%.2fT"):format(n/1e12)
    elseif n >= 1e9 then return ("%.2fB"):format(n/1e9)
    elseif n >= 1e6 then return ("%.2fM"):format(n/1e6)
    elseif n >= 1e3 then return ("%.2fK"):format(n/1e3)
    else return tostring(math.floor(n)) end
end

-- ═══════════════════════════════════════════════════════════
-- UTIL: Dapatkan semua ikan di tas
-- ═══════════════════════════════════════════════════════════
local function getFishTools()
    local list = {}
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and item:GetAttribute("ToolType") == "Fish" then
                table.insert(list, item)
            end
        end
    end
    if LocalPlayer.Character then
        for _, item in ipairs(LocalPlayer.Character:GetChildren()) do
            if item:IsA("Tool") and item:GetAttribute("ToolType") == "Fish" then
                table.insert(list, item)
            end
        end
    end
    return list
end

local function getBagCount()
    return #getFishTools()
end

local function getBagCap()
    if LocalPlayer:GetAttribute("InfiniteBag") then return math.huge end
    return LocalPlayer:GetAttribute("BagCap") or 10
end

-- ═══════════════════════════════════════════════════════════
-- UTIL: Hitung nilai ikan
-- ═══════════════════════════════════════════════════════════
local function getFishValue(tool)
    if not tool then return 0 end
    local fixed = tonumber(tool:GetAttribute("FixedSell"))
    if fixed then return fixed end
    local name = tool.Name
    local kg = tonumber(tool:GetAttribute("Weight")) or 0
    local fish = FishConfig and FishConfig[name]
    if not fish then return 0 end
    local pricePerKg = fish.pricePerKg or 100
    return math.floor(kg * pricePerKg)
end

local function getFishRarity(name)
    local fish = FishConfig and FishConfig[name]
    return (fish and fish.rarity) or "Common"
end

-- ═══════════════════════════════════════════════════════════
-- UTIL: Notifikasi
-- ═══════════════════════════════════════════════════════════
local function notify(title, content, duration)
    Rayfield:Notify({
        Title = title,
        Content = content,
        Duration = duration or 3,
        Image = 4483362458
    })
end

-- ═══════════════════════════════════════════════════════════
-- WINDOW
-- ═══════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name = "EVENT_Hole_Fishing | Mizukage Hub",
    LoadingTitle = "Mizukage Monitor v7.0",
    LoadingSubtitle = "kazukage6 | 2026",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "MizukageHub",
        FileName = "FishingConfig"
    },
    Discord = { Enabled = false, Invite = "mizukage", RememberJoins = true },
    KeySystem = false,
    ToggleUIKeybind = "K"
})

-- ═══════════════════════════════════════════════════════════
-- TAB 1: MEMANCING
-- ═══════════════════════════════════════════════════════════
local FishTab = Window:CreateTab("🎣 Memancing", 4483362458)

FishTab:CreateSection("Auto Fishing")

FishTab:CreateToggle({
    Name = "Auto Memancing",
    CurrentValue = false,
    Flag = "AutoFishToggle",
    Callback = function(v)
        State.AutoFish = v
        LocalPlayer:SetAttribute("AutoFish", v)
        notify("Auto Fish", v and "Aktif" or "Nonaktif")
    end
})

FishTab:CreateToggle({
    Name = "Auto Cast (Lempar Otomatis)",
    CurrentValue = false,
    Flag = "AutoCastToggle",
    Callback = function(v) State.AutoCast = v end
})

FishTab:CreateToggle({
    Name = "Auto Bite (Picu Gigitan)",
    CurrentValue = false,
    Flag = "AutoBiteToggle",
    Callback = function(v) State.AutoBite = v end
})

FishTab:CreateToggle({
    Name = "Cast Sempurna (Perfect)",
    CurrentValue = false,
    Flag = "PerfectCastToggle",
    Callback = function(v) State.PerfectCast = v end
})

FishTab:CreateToggle({
    Name = "Selalu Perfect (x2.00)",
    CurrentValue = false,
    Flag = "AlwaysPerfectToggle",
    Callback = function(v)
        State.AlwaysPerfect = v
        if v then
            notify("Perfect", "Aktif — auto release di jendela perfect", 3)
        end
    end
})

FishTab:CreateToggle({
    Name = "Instant Catch (Auto Reel)",
    CurrentValue = false,
    Flag = "InstantCatchToggle",
    Callback = function(v) State.InstantCatch = v end
})

FishTab:CreateSection("Aksi Manual")

FishTab:CreateButton({
    Name = "Lempar Kail Sekarang",
    Callback = function()
        FunnelSignal:FireServer("cast")
        task.wait(0.2)
        RequestRoll:FireServer()
    end
})

FishTab:CreateButton({
    Name = "Paksa Ikan Menggigit",
    Callback = function()
        FunnelSignal:FireServer("bite")
    end
})

FishTab:CreateButton({
    Name = "Tangkap Sekarang (CaughtFish)",
    Callback = function()
        if State.CurrentBite and State.CurrentBite.token then
            CaughtFish:FireServer(State.CurrentBite.token)
        else
            notify("Error", "Tidak ada bite aktif", 3)
        end
    end
})

FishTab:CreateSection("Atribut Memancing")

FishTab:CreateSlider({
    Name = "Pengali Keberuntungan (Luck)",
    Range = {1, 1000},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "LuckBoostSlider",
    Callback = function(v)
        State.LuckBoost = v
        LocalPlayer:SetAttribute("LuckBoost", v)
    end
})

FishTab:CreateSlider({
    Name = "Pengali Uang (Cash)",
    Range = {1, 1000},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "CashMultSlider",
    Callback = function(v)
        State.CashMultiplier = v
        LocalPlayer:SetAttribute("CashMult", v)
    end
})

FishTab:CreateSlider({
    Name = "Kecepatan Reel",
    Range = {1, 50},
    Increment = 0.5,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "ReelSpeedSlider",
    Callback = function(v)
        State.ReelSpeed = v
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
        if tool then tool:SetAttribute("ReelSpeed", v) end
    end
})

FishTab:CreateSlider({
    Name = "Sell Boost (%)",
    Range = {0, 500},
    Increment = 5,
    Suffix = "%",
    CurrentValue = 0,
    Flag = "SellBoostSlider",
    Callback = function(v)
        LocalPlayer:SetAttribute("SellBoost", v)
    end
})

-- ═══════════════════════════════════════════════════════════
-- TAB 2: EKONOMI
-- ═══════════════════════════════════════════════════════════
local EconTab = Window:CreateTab("💰 Ekonomi", 4483362458)

EconTab:CreateSection("Jual Ikan")

EconTab:CreateButton({
    Name = "Jual Semua Isi Tas",
    Callback = function()
        SellInventory:InvokeServer()
        notify("Penjualan", "Semua ikan dijual")
    end
})

EconTab:CreateToggle({
    Name = "Auto Jual (Loop)",
    CurrentValue = false,
    Flag = "AutoSellToggle",
    Callback = function(v) State.AutoSell = v end
})

EconTab:CreateToggle({
    Name = "Auto Jual Saat Tas Penuh",
    CurrentValue = false,
    Flag = "AutoSellOnFullToggle",
    Callback = function(v) State.AutoSellOnFull = v end
})

EconTab:CreateSection("Auto Jual Per Rarity")

local rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Abyssal", "Primordial"}

for _, rarity in ipairs(rarities) do
    EconTab:CreateToggle({
        Name = "Auto Jual " .. rarity,
        CurrentValue = false,
        Flag = "AutoSell_" .. rarity,
        Callback = function(v)
            State.AutoSellRarities[rarity] = v
            SetAutoSell:FireServer(rarity, v)
        end
    })
end

EconTab:CreateSection("Upgrade")

EconTab:CreateButton({
    Name = "Upgrade Ukuran Lubang (Hole)",
    Callback = function() BuyUpgrade:FireServer("Hole") end
})

EconTab:CreateButton({
    Name = "Upgrade Nilai Jual (Sell)",
    Callback = function() BuyUpgrade:FireServer("Sell") end
})

EconTab:CreateButton({
    Name = "Upgrade Tas (Bag)",
    Callback = function() BuyUpgrade:FireServer("Bag") end
})

EconTab:CreateToggle({
    Name = "Auto Upgrade",
    CurrentValue = false,
    Flag = "AutoUpgradeToggle",
    Callback = function(v) State.AutoUpgrade = v end
})

EconTab:CreateDropdown({
    Name = "Target Auto Upgrade",
    Options = {"Hole", "Sell", "Bag"},
    CurrentOption = {"Sell"},
    MultipleOptions = false,
    Flag = "AutoUpgradeDropdown",
    Callback = function(opt)
        State.AutoUpgradeType = type(opt) == "table" and opt[1] or opt
    end
})

EconTab:CreateSection("Rebirth")

EconTab:CreateButton({
    Name = "Lakukan Rebirth",
    Callback = function()
        DoRebirth:FireServer()
        notify("Rebirth", "Permintaan terkirim")
    end
})

EconTab:CreateToggle({
    Name = "Auto Rebirth",
    CurrentValue = false,
    Flag = "AutoRebirthToggle",
    Callback = function(v) State.AutoRebirth = v end
})

EconTab:CreateSlider({
    Name = "Auto Rebirth Setelah N kali",
    Range = {1, 20},
    Increment = 1,
    CurrentValue = 1,
    Flag = "AutoRebirthAmountSlider",
    Callback = function(v) State.AutoRebirthAmount = v end
})

EconTab:CreateButton({
    Name = "Auto Rebirth Sampai Max",
    Callback = function()
        task.spawn(function()
            for i = 1, 15 do
                DoRebirth:FireServer()
                task.wait(3)
            end
            notify("Auto Rebirth", "Selesai 15x", 5)
        end)
    end
})

-- ═══════════════════════════════════════════════════════════
-- TAB 3: FILTER IKAN
-- ═══════════════════════════════════════════════════════════
local FilterTab = Window:CreateTab("🎯 Filter", 4483362458)

FilterTab:CreateSection("Filter Rarity")

FilterTab:CreateToggle({
    Name = "Aktifkan Filter",
    CurrentValue = false,
    Flag = "FishFilterToggle",
    Callback = function(v)
        State.FishFilterEnabled = v
        notify("Filter", v and "Aktif" or "Nonaktif")
    end
})

for _, rarity in ipairs(rarities) do
    FilterTab:CreateToggle({
        Name = "Pertahankan " .. rarity,
        CurrentValue = true,
        Flag = "KeepRarity_" .. rarity,
        Callback = function(v)
            State.FishFilterRarities[rarity] = v
        end
    })
end

FilterTab:CreateSection("Filter Berat")

FilterTab:CreateSlider({
    Name = "Minimal Kg (Auto-jual di bawah ini)",
    Range = {0, 10000},
    Increment = 10,
    Suffix = " kg",
    CurrentValue = 0,
    Flag = "FishMinKgSlider",
    Callback = function(v) State.FishFilterMinKg = v end
})

-- ═══════════════════════════════════════════════════════════
-- TAB 4: TOKO
-- ═══════════════════════════════════════════════════════════
local ShopTab = Window:CreateTab("🛒 Toko", 4483362458)

ShopTab:CreateSection("Beli Pancing")

if RodsConfig then
    for _, rod in ipairs(RodsConfig) do
        if rod.name and not rod.robux and not rod.questRod then
            ShopTab:CreateButton({
                Name = ("Beli %s ($%s)"):format(rod.name, formatNumber(rod.price or 0)),
                Callback = function() BuyRod:FireServer(rod.name) end
            })
        end
    end
end

ShopTab:CreateSection("Auto Beli Rod")

ShopTab:CreateToggle({
    Name = "Auto Beli Rod Termurah Berikutnya",
    CurrentValue = false,
    Flag = "AutoBuyRodToggle",
    Callback = function(v) State.AutoBuyRod = v end
})

ShopTab:CreateSection("Teleport Menu")

ShopTab:CreateButton({
    Name = "Buka Toko Pancing",
    Callback = function() FunnelSignal:FireServer("rodshop") end
})

ShopTab:CreateButton({
    Name = "Buka Toko Upgrade Lubang",
    Callback = function() FunnelSignal:FireServer("holeshop") end
})

ShopTab:CreateButton({
    Name = "Buka Tempat Jual Ikan",
    Callback = function() FunnelSignal:FireServer("seller") end
})

-- ═══════════════════════════════════════════════════════════
-- TAB 5: STATISTIK
-- ═══════════════════════════════════════════════════════════
local StatsTab = Window:CreateTab("📊 Statistik", 4483362458)

StatsTab:CreateSection("Ringkasan Session")

local statsLabel = StatsTab:CreateParagraph({
    Title = "Statistik Live",
    Content = "Total: 0 | Nilai: $0 | Kg: 0"
})

local rarityLabel = StatsTab:CreateParagraph({
    Title = "Per Rarity",
    Content = "Belum ada"
})

local recentLabel = StatsTab:CreateParagraph({
    Title = "Tangkapan Terakhir",
    Content = "Belum ada"
})

local function refreshStats()
    local s = State.Stats
    local uptime = os.time() - s.SessionStart
    local hrs = math.floor(uptime / 3600)
    local min = math.floor((uptime % 3600) / 60)
    
    statsLabel:Set({
        Title = "Statistik Live",
        Content = string.format(
            "Total: %d | Nilai: $%s | Kg: %s | Uptime: %02dh%02dm",
            s.TotalCaught, formatCash(s.TotalValue), formatNumber(s.TotalKg), hrs, min
        )
    })
    
    local parts = {}
    for r, c in pairs(s.RarityCount) do
        table.insert(parts, r .. ": " .. c)
    end
    table.sort(parts)
    rarityLabel:Set({
        Title = "Per Rarity",
        Content = #parts > 0 and table.concat(parts, " | ") or "Belum ada"
    })
    
    local recent = {}
    for i = math.max(1, #s.RecentCatches - 4), #s.RecentCatches do
        local c = s.RecentCatches[i]
        if c then table.insert(recent, string.format("%s (%.1fkg)", c.name, c.kg)) end
    end
    recentLabel:Set({
        Title = "Tangkapan Terakhir",
        Content = #recent > 0 and table.concat(recent, ", ") or "Belum ada"
    })
end

StatsTab:CreateButton({
    Name = "Reset Statistik",
    Callback = function()
        State.Stats = {
            TotalCaught = 0, TotalValue = 0, TotalKg = 0,
            RarityCount = {}, RecentCatches = {}, SessionStart = os.time()
        }
        refreshStats()
    end
})

StatsTab:CreateButton({
    Name = "Copy Laporan ke Clipboard",
    Callback = function()
        local s = State.Stats
        local lines = {
            "=== MIZUKAGE HUB | Laporan ===",
            "Total Catch: " .. s.TotalCaught,
            "Total Value: $" .. formatNumber(s.TotalValue),
            "Total Kg: " .. formatNumber(s.TotalKg),
            "--- Per Rarity ---"
        }
        for r, c in pairs(s.RarityCount) do
            table.insert(lines, r .. ": " .. c)
        end
        if setclipboard then
            setclipboard(table.concat(lines, "\n"))
            notify("Copy", "Laporan dicopy ke clipboard")
        end
    end
})

task.spawn(function()
    while true do
        task.wait(3)
        refreshStats()
    end
end)

-- ═══════════════════════════════════════════════════════════
-- TAB 6: PENGATURAN
-- ═══════════════════════════════════════════════════════════
local SettingsTab = Window:CreateTab("⚙️ Pengaturan", 4483362458)

SettingsTab:CreateSection("Cutscene")

SettingsTab:CreateDropdown({
    Name = "Skip Cutscene",
    Options = {"Off", "Mid", "All"},
    CurrentOption = {"Off"},
    MultipleOptions = false,
    Flag = "SkipCutsceneDropdown",
    Callback = function(opt)
        local v = type(opt) == "table" and opt[1] or opt
        State.SkipCutscenes = v
        LocalPlayer:SetAttribute("SkipCutscenes", v)
    end
})

SettingsTab:CreateSection("Atribut Cepat")

SettingsTab:CreateToggle({
    Name = "Tas Infinity (InfiniteBag)",
    CurrentValue = false,
    Flag = "InfiniteBagToggle",
    Callback = function(v)
        State.InfiniteBag = v
        LocalPlayer:SetAttribute("InfiniteBag", v)
    end
})

SettingsTab:CreateToggle({
    Name = "Super Lucky (2x Luck)",
    CurrentValue = false,
    Flag = "SuperLuckyToggle",
    Callback = function(v)
        State.SuperLucky = v
        LocalPlayer:SetAttribute("SuperLucky", v)
    end
})

SettingsTab:CreateToggle({
    Name = "Status VIP",
    CurrentValue = false,
    Flag = "VIPToggle",
    Callback = function(v)
        State.VIP = v
        LocalPlayer:SetAttribute("VIP", v)
    end
})

SettingsTab:CreateToggle({
    Name = "Status Double Cash",
    CurrentValue = false,
    Flag = "DoubleCashToggle",
    Callback = function(v)
        LocalPlayer:SetAttribute("CashMult", v and 2 or 1)
    end
})

SettingsTab:CreateToggle({
    Name = "Speedy Fisher",
    CurrentValue = false,
    Flag = "SpeedyFisherToggle",
    Callback = function(v)
        LocalPlayer:SetAttribute("ReelMult", v and 2 or 1)
    end
})

SettingsTab:CreateSection("Debug")

SettingsTab:CreateToggle({
    Name = "Tampilkan Info Debug (HOLSTER)",
    CurrentValue = false,
    Flag = "DebugToggle",
    Callback = function(v) _G.HOLSTER_DEBUG = v end
})

SettingsTab:CreateSection("Info")

SettingsTab:CreateParagraph({
    Title = "Tentang",
    Content = "Mizukage Hub v7.0 | Script EVENT_Hole_Fishing"
})

SettingsTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end
})

SettingsTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local TS = game:GetService("TeleportService")
        local HTTP = game:GetService("HttpService")
        local ok, res = pcall(function()
            return HTTP:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        end)
        if ok and res and res.data then
            for _, srv in ipairs(res.data) do
                if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                    TS:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                    return
                end
            end
        end
        notify("Server Hop", "Tidak ada server ditemukan", 3)
    end
})

-- ═══════════════════════════════════════════════════════════
-- CORE LOGIC: Auto Fish Loop
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.1)
        
        if State.AutoFish then
            local state = LocalPlayer:GetAttribute("FishState")
            
            if state == "idle" or state == nil then
                if State.AutoCast or State.AutoFish then
                    FunnelSignal:FireServer("cast")
                    task.wait(0.4)
                    RequestRoll:FireServer()
                end
            elseif state == "bite" then
                if State.AutoBite or State.AutoFish then
                    FunnelSignal:FireServer("bite")
                end
                if State.InstantCatch and State.CurrentBite and State.CurrentBite.token then
                    task.wait(0.2)
                    CaughtFish:FireServer(State.CurrentBite.token)
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- LISTENER: CastRoll (dapat info ikan)
-- ═══════════════════════════════════════════════════════════
CastRoll.OnClientEvent:Connect(function(token, fishName, kg, sc, mut, bite, smult)
    State.CurrentBite = {
        token = token,
        fish = fishName,
        kg = kg,
        sc = sc,
        mut = mut or "",
        bite = bite,
        smult = smult
    }
end)

-- ═══════════════════════════════════════════════════════════
-- LISTENER: CaughtFish → update stats
-- ═══════════════════════════════════════════════════════════
local lastCaught = nil
CastRoll.OnClientEvent:Connect(function(token, fishName, kg, sc, mut, bite, smult)
    -- simpan untuk nanti saat CaughtFish dipanggil
    lastCaught = {name = fishName, kg = kg, mut = mut or "", smult = smult}
end)

-- Pantau penambahan tool Fish ke backpack untuk update stats
local function onFishAdded(tool)
    if tool:IsA("Tool") and tool:GetAttribute("ToolType") == "Fish" then
        local name = tool.Name
        local kg = tool:GetAttribute("Weight") or 0
        local value = getFishValue(tool)
        local rarity = getFishRarity(name)
        
        State.Stats.TotalCaught = State.Stats.TotalCaught + 1
        State.Stats.TotalValue = State.Stats.TotalValue + value
        State.Stats.TotalKg = State.Stats.TotalKg + kg
        State.Stats.RarityCount[rarity] = (State.Stats.RarityCount[rarity] or 0) + 1
        table.insert(State.Stats.RecentCatches, {name = name, kg = kg, rarity = rarity})
        if #State.Stats.RecentCatches > 20 then
            table.remove(State.Stats.RecentCatches, 1)
        end
    end
end

local function watchBackpack()
    local backpack = LocalPlayer:WaitForChild("Backpack", 10)
    if not backpack then return end
    for _, c in ipairs(backpack:GetChildren()) do onFishAdded(c) end
    backpack.ChildAdded:Connect(onFishAdded)
end

if LocalPlayer:FindFirstChildOfClass("Backpack") then
    task.spawn(watchBackpack)
end
LocalPlayer.ChildAdded:Connect(function(c)
    if c.Name == "Backpack" then task.spawn(watchBackpack) end
end)

-- ═══════════════════════════════════════════════════════════
-- CORE LOGIC: Auto Sell
-- ═══════════════════════════════════════════════════════════
local function shouldSellFish(tool)
    local name = tool.Name
    local rarity = getFishRarity(name)
    local kg = tonumber(tool:GetAttribute("Weight")) or 0
    
    if State.FishFilterEnabled then
        if not State.FishFilterRarities[rarity] then return true end
        if kg < State.FishFilterMinKg then return true end
        return false
    end
    
    if State.AutoSellRarities[rarity] then return true end
    return false
end

local function runAutoSell()
    if not (State.AutoSell or State.AutoSellOnFull or State.FishFilterEnabled) then return end
    
    local fish = getFishTools()
    local shouldSell = false
    
    for _, tool in ipairs(fish) do
        if shouldSellFish(tool) then
            shouldSell = true
            break
        end
    end
    
    if State.AutoSellOnFull then
        if getBagCount() >= getBagCap() - 1 then
            shouldSell = true
        end
    end
    
    if shouldSell then
        SellInventory:InvokeServer()
    end
end

task.spawn(function()
    while true do
        task.wait(2)
        pcall(runAutoSell)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- CORE LOGIC: Always Perfect Cast
-- ═══════════════════════════════════════════════════════════
LocalPlayer:GetAttributeChangedSignal("FishState"):Connect(function()
    local state = LocalPlayer:GetAttribute("FishState")
    
    if state == "charging" and State.AlwaysPerfect then
        -- charge cycle: 0.5 detik + 0.72π loop. Perfect = 0.87+
        -- start perfect ~0.75s dari mulai charge
        task.wait(0.78)
        if LocalPlayer:GetAttribute("FishState") == "charging" then
            FunnelSignal:FireServer("cast")
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- CORE LOGIC: Auto Upgrade
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(3)
        if State.AutoUpgrade then
            pcall(function()
                BuyUpgrade:FireServer(State.AutoUpgradeType or "Sell")
            end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- CORE LOGIC: Auto Rebirth
-- ═══════════════════════════════════════════════════════════
local rebirthCount = 0
task.spawn(function()
    while true do
        task.wait(5)
        if State.AutoRebirth then
            if rebirthCount < State.AutoRebirthAmount then
                DoRebirth:FireServer()
                rebirthCount = rebirthCount + 1
                notify("Auto Rebirth", rebirthCount .. "/" .. State.AutoRebirthAmount, 2)
            end
        else
            rebirthCount = 0
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- CORE LOGIC: Auto Buy Rod
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(5)
        if State.AutoBuyRod and RodsConfig then
            local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
            local cash = leaderstats and leaderstats:FindFirstChild("Cash")
            cash = cash and cash.Value or 0
            
            local owned = {}
            local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
            if backpack then
                for _, t in ipairs(backpack:GetChildren()) do
                    if t:IsA("Tool") then owned[t.Name] = true end
                end
            end
            
            for _, rod in ipairs(RodsConfig) do
                if rod.name and not rod.robux and not rod.questRod then
                    if not owned[rod.name] and rod.price <= cash then
                        BuyRod:FireServer(rod.name)
                        break
                    end
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- REFRESH UI CASH DISPLAY (untuk Cash Hud)
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
            local cash = leaderstats and leaderstats:FindFirstChild("Cash")
            if cash then
                -- sudah di-update server-side
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════
-- LOAD CONFIG & STARTUP NOTIFY
-- ═══════════════════════════════════════════════════════════
Rayfield:LoadConfiguration()

notify(
    "🎣 Mizukage Hub Dimuat",
    "EVENT_Hole_Fishing | Semua fitur siap digunakan",
    6
)

print("[Mizukage] EVENT_Hole_Fishing script loaded.")
print("[Mizukage] Total Fish: " .. (FishConfig and (function()
    local n = 0
    for _ in pairs(FishConfig) do n = n + 1 end
    return n
end)() or 0))
print("[Mizukage] Total Rods: " .. (RodsConfig and #RodsConfig or 0))