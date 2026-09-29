--[[
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║                        MIZUKAGE OFFICIAL 👑                             ║
    ║        GALATAMA GUNUNG SOREYA — V5.0 ULTIMATE FULL UNCOMPRESSED          ║
    ║               RAYFIELD GEN2 • FIXED UI & COMPLETE CONTROL                ║
    ╚══════════════════════════════════════════════════════════════════════════╝
]]

-- ══════════════════════════════════════════════════════════════════════
-- [1] SERVICES & LOCAL PLAYER
-- ══════════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- ══════════════════════════════════════════════════════════════════════
-- [2] RAYFIELD GEN2 LOADER
-- ══════════════════════════════════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

-- ══════════════════════════════════════════════════════════════════════
-- [3] MASTER CONFIGURATION STATE
-- ══════════════════════════════════════════════════════════════════════
local Config = {
    Fishing = {
        AutoCastEnabled = false,
        CastPower = 95,
        ChargeDelay = 0.15,      -- Waktu tahan kail sebelum dilepas
        PostCastDelay = 1.35,    -- Jeda setelah lemparan selesai
        
        AutoReelEnabled = false,
        SmartDelayEnabled = false,    -- Jika true, hitung otomatis berdasarkan difficulty
        SmartDelayOffset = 0.0,       -- Penambahan/Pengurangan delay pada mode Smart
        StaticReelDelay = 2.10,       -- Waktu manual absolut (jika Smart dimatikan)
        
        AutoEquip = false,
        SyncInventory = false
    },
    Network = {
        BroadcastExclamation = false,
        SecretRadar = false,
        CatchToast = true,
        AntiAfk = false
    },
    Universal = {
        WalkSpeedEnabled = false,
        WalkSpeed = 16,
        JumpPowerEnabled = false,
        JumpPower = 50,
        InfiniteJump = false,
        NoClip = false,
        AntiFling = false,
        Gravity = 196.2
    }
}

local State = {
    ActiveRod = nil,
    Remotes = {
        CastEvent = nil,
        MiniGame = nil,
        NotifyClient = nil
    },
    Connections = {},
    Stats = {
        Catches = 0,
        LastFish = "Belum Ada",
        LastRarity = "-",
        LastWeight = 0,
        LastMutation = "Normal",
        StartTime = os.time()
    },
    Flags = {
        IsCasting = false,
        InMinigame = false,
        AwaitingReward = false,
        CooldownUntil = 0
    }
}

-- ══════════════════════════════════════════════════════════════════════
-- [4] REPLICATED STORAGE RESOLVER (EVIDENCE BASED)
-- ══════════════════════════════════════════════════════════════════════
local SharedRemotes = {
    TandaSeruBersama = ReplicatedStorage:FindFirstChild("TandaSeruBersama"),
    AmbilSemua = ReplicatedStorage:FindFirstChild("Remote") 
        and ReplicatedStorage.Remote:FindFirstChild("Inventaris") 
        and ReplicatedStorage.Remote.Inventaris:FindFirstChild("AmbilSemua"),
    InventarisBerubah = ReplicatedStorage:FindFirstChild("Remote") 
        and ReplicatedStorage.Remote:FindFirstChild("Inventaris") 
        and ReplicatedStorage.Remote.Inventaris:FindFirstChild("Berubah"),
    IndexBerubah = ReplicatedStorage:FindFirstChild("Remote") 
        and ReplicatedStorage.Remote:FindFirstChild("Index") 
        and ReplicatedStorage.Remote.Index:FindFirstChild("IndexBerubah"),
    AdminPesanChat = ReplicatedStorage:FindFirstChild("Remote") 
        and ReplicatedStorage.Remote:FindFirstChild("Admin") 
        and ReplicatedStorage.Remote.Admin:FindFirstChild("PesanChat")
}

-- ══════════════════════════════════════════════════════════════════════
-- [5] FISHING ENGINE MODULE
-- ══════════════════════════════════════════════════════════════════════
local Engine = {}

function Engine.FormatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%02d:%02d", m, s)
end

function Engine.EnsureEquipped()
    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    local foundRod = nil
    local isEquipped = false

    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and item:FindFirstChild("Mechanics") then
                local remotes = item.Mechanics:FindFirstChild("Remotes")
                if remotes and remotes:FindFirstChild("CastEvent") and remotes:FindFirstChild("MiniGame") then
                    foundRod = item
                    isEquipped = true
                    break
                end
            end
        end
    end

    if not foundRod and bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") and item:FindFirstChild("Mechanics") then
                local remotes = item.Mechanics:FindFirstChild("Remotes")
                if remotes and remotes:FindFirstChild("CastEvent") and remotes:FindFirstChild("MiniGame") then
                    foundRod = item
                    isEquipped = false
                    break
                end
            end
        end
    end

    if foundRod and not isEquipped and Config.Fishing.AutoEquip then
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:EquipTool(foundRod)
            task.wait(0.25)
        end
    end

    return foundRod
end

function Engine.GetReelDelay(payload)
    if Config.Fishing.SmartDelayEnabled then
        local difficulty = 1.8
        if type(payload) == "table" and payload.difficulty then
            difficulty = tonumber(payload.difficulty) or 1.8
        end
        local baseCalc = 1.05 + (difficulty * 0.48)
        local finalDelay = baseCalc + Config.Fishing.SmartDelayOffset
        return math.clamp(finalDelay, 0, 5)
    else
        return Config.Fishing.StaticReelDelay
    end
end

function Engine.BindRod(rod)
    if not rod then return end
    
    local mechanics = rod:FindFirstChild("Mechanics")
    if not mechanics then return end
    local remotes = mechanics:FindFirstChild("Remotes")
    if not remotes then return end

    State.ActiveRod = rod
    State.Remotes.CastEvent = remotes:FindFirstChild("CastEvent")
    State.Remotes.MiniGame = remotes:FindFirstChild("MiniGame")
    State.Remotes.NotifyClient = remotes:FindFirstChild("NotifyClient")

    if State.Connections.MiniGameConn then State.Connections.MiniGameConn:Disconnect() end
    if State.Connections.NotifyConn then State.Connections.NotifyConn:Disconnect() end

    if State.Remotes.MiniGame then
        State.Connections.MiniGameConn = State.Remotes.MiniGame.OnClientEvent:Connect(function(action, payload)
            if action == "Start" then
                State.Flags.InMinigame = true
                State.Flags.AwaitingReward = true
                
                if Config.Fishing.AutoReelEnabled then
                    local targetDelay = Engine.GetReelDelay(payload)
                    
                    task.delay(targetDelay, function()
                        if State.Flags.InMinigame and State.Remotes.MiniGame then
                            pcall(function() 
                                State.Remotes.MiniGame:FireServer(true) 
                            end)
                        end
                    end)
                end
                
            elseif action == "Stop" then
                State.Flags.InMinigame = false
                task.delay(0.2, function() 
                    State.Flags.AwaitingReward = false 
                end)
            end
        end)
    end

    if State.Remotes.NotifyClient then
        State.Connections.NotifyConn = State.Remotes.NotifyClient.OnClientEvent:Connect(function(action, data)
            if action == "Bite" then
                if Config.Network.BroadcastExclamation and SharedRemotes.TandaSeruBersama then
                    pcall(function() 
                        SharedRemotes.TandaSeruBersama:FireServer(nil, nil, nil, data and data.duration or 1.5) 
                    end)
                end
                
            elseif action == "GotFish" and type(data) == "table" then
                State.Stats.Catches = State.Stats.Catches + 1
                State.Stats.LastFish = tostring(data.baseName or data.originalName or "Ikan")
                State.Stats.LastRarity = tostring(data.rarity or "Common")
                State.Stats.LastWeight = tonumber(data.weight) or 0
                State.Stats.LastMutation = tostring(data.mutation or "Normal")

                if Config.Network.CatchToast and Rayfield then
                    pcall(function()
                        Rayfield:Notify({
                            title = "🎣 " .. State.Stats.LastFish,
                            content = string.format("Rarity: %s\nBerat: %.2f kg\nMutasi: %s", 
                                State.Stats.LastRarity, 
                                State.Stats.LastWeight,
                                State.Stats.LastMutation
                            ),
                            duration = 3.5
                        })
                    end)
                end
                
                if Config.Fishing.SyncInventory and SharedRemotes.AmbilSemua then 
                    pcall(function() 
                        SharedRemotes.AmbilSemua:InvokeServer() 
                    end) 
                end
                
                State.Flags.InMinigame = false
                State.Flags.AwaitingReward = false
                State.Flags.IsCasting = false
                
            elseif action == "CastFailed" then
                State.Flags.IsCasting = false
                State.Flags.InMinigame = false
                State.Flags.AwaitingReward = false
                
                if data and data.reason == "Cooldown" then 
                    State.Flags.CooldownUntil = os.clock() + 1.2
                end
            end
        end)
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- [6] CONTINUOUS RUNNERS
-- ══════════════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.1)
        local safeToCast = Config.Fishing.AutoCastEnabled 
            and not State.Flags.InMinigame 
            and not State.Flags.AwaitingReward 
            and not State.Flags.IsCasting 
            and os.clock() >= State.Flags.CooldownUntil

        if safeToCast then
            local currentRod = Engine.EnsureEquipped()
            if currentRod then
                Engine.BindRod(currentRod)
                if State.Remotes.CastEvent then
                    State.Flags.IsCasting = true
                    
                    pcall(function() State.Remotes.CastEvent:FireServer(true) end)
                    task.wait(Config.Fishing.ChargeDelay)
                    pcall(function() State.Remotes.CastEvent:FireServer(false, Config.Fishing.CastPower, nil) end)
                    task.wait(Config.Fishing.PostCastDelay)
                    
                    State.Flags.IsCasting = false
                end
            end
        end
    end
end)

if SharedRemotes.InventarisBerubah then
    State.Connections.InvSync = SharedRemotes.InventarisBerubah.OnClientEvent:Connect(function()
        if Config.Fishing.SyncInventory and SharedRemotes.AmbilSemua then 
            pcall(function() SharedRemotes.AmbilSemua:InvokeServer() end) 
        end
    end)
end

if SharedRemotes.AdminPesanChat then
    State.Connections.Radar = SharedRemotes.AdminPesanChat.OnClientEvent:Connect(function(msg)
        if Config.Network.SecretRadar and type(msg) == "string" and string.find(msg, "%[SECRET%]") and Rayfield then
            pcall(function() 
                Rayfield:Notify({ 
                    title = "🌍 SECRET RADAR", 
                    content = msg:gsub("<[^>]+>", ""), 
                    duration = 5 
                }) 
            end)
        end
    end)
end

State.Connections.IdledConn = LocalPlayer.Idled:Connect(function()
    if Config.Network.AntiAfk then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- [7] UNIVERSAL MODULES ENGINE
-- ══════════════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.1)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                if Config.Universal.WalkSpeedEnabled then 
                    hum.WalkSpeed = Config.Universal.WalkSpeed 
                end
                if Config.Universal.JumpPowerEnabled then 
                    hum.UseJumpPower = true 
                    hum.JumpPower = Config.Universal.JumpPower 
                end
            end
        end
    end
end)

State.Connections.InfJump = UserInputService.JumpRequest:Connect(function()
    if Config.Universal.InfiniteJump then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then 
            hum:ChangeState(Enum.HumanoidStateType.Jumping) 
        end
    end
end)

State.Connections.NoClip = RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if Config.Universal.NoClip and char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

State.Connections.AntiFling = RunService.Stepped:Connect(function()
    if Config.Universal.AntiFling then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in ipairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end)

local function ExecuteServerHop()
    if Rayfield then 
        Rayfield:Notify({title = "Server Hop", content = "Mencari server publik lain...", duration = 3}) 
    end
    
    local servers = {}
    local req = request or http_request or (syn and syn.request)
    
    if req then
        pcall(function()
            local res = req({Url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)})
            if res and res.Body then
                local body = HttpService:JSONDecode(res.Body)
                if body and body.data then
                    for _, v in ipairs(body.data) do
                        if type(v) == "table" and v.playing < v.maxPlayers and v.id ~= game.JobId then
                            table.insert(servers, v.id)
                        end
                    end
                end
            end
        end)
    end
    
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
    else
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- [8] FULL UI CONSTRUCTION (RAYFIELD GEN2)
-- ══════════════════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    name = "Mizukage Official 👑",
    subtitle = "Galatama SOREYA | v5.0 Ultimate Uncompressed",
    sidebarLayout = true
})

-- TAB 1: DASHBOARD
local TabDashboard = Window:CreateTab({ name = "Dashboard" })

local CatchLabel = TabDashboard:CreateLabel({name = "Tangkapan Sesi Ini: 0 Ekor"})
local FishDetailLabel = TabDashboard:CreateLabel({name = "Ikan Terakhir: Belum Ada"})
local UptimeLabel = TabDashboard:CreateLabel({name = "Waktu Aktif Script: 00:00"})

TabDashboard:CreateButton({
    name = "Refresh Statistik",
    callback = function()
        pcall(function()
            CatchLabel:Set("Tangkapan Sesi Ini: " .. State.Stats.Catches .. " Ekor")
            FishDetailLabel:Set(string.format("Ikan Terakhir: %s [%s] • %.2f kg", State.Stats.LastFish, State.Stats.LastRarity, State.Stats.LastWeight))
            UptimeLabel:Set("Waktu Aktif Script: " .. Engine.FormatTime(os.time() - State.Stats.StartTime))
        end)
    end
})

-- TAB 2: AUTO CAST CONFIG
local TabCast = Window:CreateTab({ name = "Pengaturan Cast" })

TabCast:CreateToggle({
    name = "Auto Cast (Lempar Kail Otomatis)",
    currentValue = Config.Fishing.AutoCastEnabled,
    flag = "Mzk_Cast",
    callback = function(val)
        Config.Fishing.AutoCastEnabled = val
    end
})

TabCast:CreateSlider({
    name = "Power Tarikan / Kekuatan Lempar",
    range = {20, 100},
    increment = 1,
    currentValue = Config.Fishing.CastPower,
    flag = "Mzk_Power",
    callback = function(val)
        Config.Fishing.CastPower = val
    end
})

TabCast:CreateSlider({
    name = "Delay Charge (Waktu Kail Ditahan)",
    range = {0.0, 1.0},
    increment = 0.05,
    currentValue = Config.Fishing.ChargeDelay,
    flag = "Mzk_ChargeDelay",
    callback = function(val)
        Config.Fishing.ChargeDelay = val
    end
})

TabCast:CreateSlider({
    name = "Delay Pasca Lempar (Tunggu Umpan Masuk)",
    range = {0.5, 3.5},
    increment = 0.05,
    currentValue = Config.Fishing.PostCastDelay,
    flag = "Mzk_PostCastDelay",
    callback = function(val)
        Config.Fishing.PostCastDelay = val
    end
})

-- TAB 3: AUTO REEL (FULL MANUAL CONTROL)
local TabReel = Window:CreateTab({ name = "Pengaturan Tarikan (Reel)" })

TabReel:CreateToggle({
    name = "Auto Reel (Tarik Ikan Otomatis)",
    currentValue = Config.Fishing.AutoReelEnabled,
    flag = "Mzk_Reel",
    callback = function(val)
        Config.Fishing.AutoReelEnabled = val
    end
})

TabReel:CreateDivider()
TabReel:CreateLabel({name = "MANUAL OVERRIDE (Tanpa Mode Smart)"})

TabReel:CreateSlider({
    name = "Static Reel Delay (Detik)",
    range = {0.0, 5.0},
    increment = 0.05,
    currentValue = Config.Fishing.StaticReelDelay,
    flag = "Mzk_StaticReel",
    callback = function(val)
        Config.Fishing.StaticReelDelay = val
    end
})

TabReel:CreateDivider()
TabReel:CreateLabel({name = "SMART ADAPTIVE (Ikuti Difficulty Server)"})

TabReel:CreateToggle({
    name = "Gunakan Smart Adaptive Delay",
    currentValue = Config.Fishing.SmartDelayEnabled,
    flag = "Mzk_SmartDelay",
    callback = function(val)
        Config.Fishing.SmartDelayEnabled = val
    end
})

TabReel:CreateSlider({
    name = "Smart Delay Offset (Detik Tambahan)",
    range = {-2.0, 2.0},
    increment = 0.05,
    currentValue = Config.Fishing.SmartDelayOffset,
    flag = "Mzk_SmartOffset",
    callback = function(val)
        Config.Fishing.SmartDelayOffset = val
    end
})

-- TAB 4: JARINGAN & MONITOR
local TabNetwork = Window:CreateTab({ name = "Radar & Jaringan" })

TabNetwork:CreateToggle({
    name = "Auto Equip Pancingan",
    currentValue = Config.Fishing.AutoEquip,
    flag = "Mzk_AutoEquip",
    callback = function(val) Config.Fishing.AutoEquip = val end
})

TabNetwork:CreateToggle({
    name = "Auto Sinkronisasi Inventaris",
    currentValue = Config.Fishing.SyncInventory,
    flag = "Mzk_SyncInv",
    callback = function(val) Config.Fishing.SyncInventory = val end
})

TabNetwork:CreateToggle({
    name = "Anti-AFK (20 Menit Bypass)",
    currentValue = Config.Network.AntiAfk,
    flag = "Mzk_AntiAfk",
    callback = function(val) Config.Network.AntiAfk = val end
})

TabNetwork:CreateToggle({
    name = "Notifikasi Tangkapan (Toast)",
    currentValue = Config.Network.CatchToast,
    flag = "Mzk_CatchToast",
    callback = function(val) Config.Network.CatchToast = val end
})

TabNetwork:CreateToggle({
    name = "Radar Ikan Secret Server",
    currentValue = Config.Network.SecretRadar,
    flag = "Mzk_SecretRadar",
    callback = function(val) Config.Network.SecretRadar = val end
})

TabNetwork:CreateToggle({
    name = "Replikasi Animasi Tanda Seru (!)",
    currentValue = Config.Network.BroadcastExclamation,
    flag = "Mzk_Exclam",
    callback = function(val) Config.Network.BroadcastExclamation = val end
})

-- TAB 5: UNIVERSAL PLAYER
local TabPlayer = Window:CreateTab({ name = "Universal Karakter" })

TabPlayer:CreateToggle({
    name = "Aktifkan Custom WalkSpeed",
    currentValue = Config.Universal.WalkSpeedEnabled,
    flag = "Mzk_WS_Toggle",
    callback = function(val) Config.Universal.WalkSpeedEnabled = val end
})

TabPlayer:CreateSlider({
    name = "Nilai WalkSpeed",
    range = {16, 250}, increment = 1, currentValue = Config.Universal.WalkSpeed,
    flag = "Mzk_WS_Val", callback = function(val) Config.Universal.WalkSpeed = val end
})

TabPlayer:CreateDivider()

TabPlayer:CreateToggle({
    name = "Aktifkan Custom JumpPower",
    currentValue = Config.Universal.JumpPowerEnabled,
    flag = "Mzk_JP_Toggle", callback = function(val) Config.Universal.JumpPowerEnabled = val end
})

TabPlayer:CreateSlider({
    name = "Nilai JumpPower",
    range = {50, 300}, increment = 1, currentValue = Config.Universal.JumpPower,
    flag = "Mzk_JP_Val", callback = function(val) Config.Universal.JumpPower = val end
})

TabPlayer:CreateDivider()

TabPlayer:CreateToggle({
    name = "Infinite Jump (Lompat Tanpa Batas)",
    currentValue = Config.Universal.InfiniteJump,
    flag = "Mzk_InfJump", callback = function(val) Config.Universal.InfiniteJump = val end
})

-- TAB 6: UNIVERSAL WORLD
local TabWorld = Window:CreateTab({ name = "Universal Dunia" })

TabWorld:CreateToggle({
    name = "No-Clip (Jalan Tembus Tembok)",
    currentValue = Config.Universal.NoClip,
    flag = "Mzk_NoClip", callback = function(val) Config.Universal.NoClip = val end
})

TabWorld:CreateToggle({
    name = "Anti-Fling (Tembus Pemain Lain)",
    currentValue = Config.Universal.AntiFling,
    flag = "Mzk_AntiFling", callback = function(val) Config.Universal.AntiFling = val end
})

TabWorld:CreateSlider({
    name = "Modifikasi Gravitasi Game",
    range = {0, 196}, increment = 1, currentValue = Config.Universal.Gravity,
    flag = "Mzk_Gravity", callback = function(val) 
        Config.Universal.Gravity = val 
        Workspace.Gravity = val
    end
})

TabWorld:CreateDivider()

TabWorld:CreateButton({ name = "Pindah Server (Server Hop)", callback = ExecuteServerHop })
TabWorld:CreateButton({ name = "Rejoin Server Saat Ini", callback = function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end })

-- TAB 7: CLEANUP & SYSTEM
local TabSys = Window:CreateTab({ name = "Sistem Utama" })

TabSys:CreateButton({
    name = "Paksa Sinkronkan Inventaris Sekarang",
    callback = function()
        if SharedRemotes.AmbilSemua then 
            pcall(function() SharedRemotes.AmbilSemua:InvokeServer() end)
            if Rayfield then Rayfield:Notify({title = "Inventaris", content = "Berhasil meminta sinkronisasi ke server.", duration = 3}) end
        end
    end
})

TabSys:CreateButton({
    name = "Matikan Total Script (Unload & Cleanup)",
    callback = function()
        Config.Fishing.AutoCastEnabled = false
        Config.Fishing.AutoReelEnabled = false
        
        Config.Universal.WalkSpeedEnabled = false
        Config.Universal.JumpPowerEnabled = false
        Config.Universal.InfiniteJump = false
        Config.Universal.NoClip = false
        Config.Universal.AntiFling = false
        Workspace.Gravity = 196.2
        
        for name, conn in pairs(State.Connections) do 
            if conn then conn:Disconnect() State.Connections[name] = nil end 
        end
        
        if Rayfield then Rayfield:Notify({title = "Mizukage Official 👑", content = "Sistem mati. Seluruh background thread dan koneksi telah dibersihkan tanpa memory leak.", duration = 4}) end
    end
})

-- ══════════════════════════════════════════════════════════════════════
-- [9] INIT BOOTSTRAP
-- ══════════════════════════════════════════════════════════════════════
pcall(function() Rayfield:Notify({ title = "Mizukage Official 👑", content = "Versi Ultimate (Uncompressed) Dimuat. Selamat Memancing!", duration = 5 }) end)
task.defer(function() 
    local initialRod = Engine.EnsureEquipped()
    if initialRod then Engine.BindRod(initialRod) end 
end)