--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              MIZUKAGE OFFICIAL — MAIN SCRIPT                 ║
    ║                Hub v3.0 Ultimate Edition                     ║
    ╚══════════════════════════════════════════════════════════════╝
    
    Mode Manual Override (Jika tidak ingin auto-execute):
    getgenv().MizuManualMode = true
]]

local StarterGui = game:GetService("StarterGui")

-- Mencegah execute ganda
if getgenv().MizuLauncherLoaded then 
    StarterGui:SetCore("SendNotification", {Title = "Mizukage", Text = "Script sudah berjalan!", Duration = 3})
    return 
end
getgenv().MizuLauncherLoaded = true

--========================================================================
-- [KONFIGURASI]
--========================================================================
local CONFIG = {
    WEBHOOK_URL = "https://discord.com/api/webhooks/1516421004291997718/t5nSkmWsiwWFpSNHjJQv3fdQKWGm2SqOQag3LS3kSEwHL1QkuyfbgzFpLI7kDXO357Bj",
    GITHUB_DB = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/script/DBscript.lua",
    VERSION = "3.0 Ultimate",
    DELAY_BEFORE_EXECUTION = 1.5
}

local isManualMode = getgenv().MizuManualMode or false

--========================================================================
-- [SERVICES]
--========================================================================
local Services = {
    Players = game:GetService("Players"),
    TeleportService = game:GetService("TeleportService"),
    MarketplaceService = game:GetService("MarketplaceService"),
    HttpService = game:GetService("HttpService"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    VirtualUser = game:GetService("VirtualUser"),
    Lighting = game:GetService("Lighting")
}
local LocalPlayer = Services.Players.LocalPlayer
local PlaceID = game.PlaceId

--========================================================================
-- [UTILITY FUNCTIONS (CACHE BUSTER & SAFE EXECUTE)]
--========================================================================
local Utilities = {}

-- Bypass cache executor dengan menambahkan ?t=waktu
function Utilities:GetCleanURL(url)
    if string.find(url, "raw.githubusercontent") then
        local separator = string.find(url, "?") and "&" or "?"
        return url .. separator .. "t=" .. tostring(math.floor(tick() * 1000))
    end
    return url
end

function Utilities:SafeExecute(url)
    if type(url) ~= "string" or url == "" then return false, "URL Kosong/Invalid" end
    
    local cleanUrl = self:GetCleanURL(url)
    
    local successGet, scriptContent = pcall(function()
        return game:HttpGet(cleanUrl)
    end)
    
    if not successGet then return false, "Gagal Fetch HTTP (Link mati / Koneksi lambat)" end
    
    local loadFunc, loadErr = loadstring(scriptContent)
    if not loadFunc then return false, "Error Syntax pada Script Target: " .. tostring(loadErr) end
    
    local successExec, execErr = pcall(loadFunc)
    if not successExec then return false, "Error saat menjalankan Script Target: " .. tostring(execErr) end
    
    return true, "Sukses"
end

function Utilities:SendNotification(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 5 })
    end)
end

--========================================================================
-- [CLOUD DATABASE MANAGER]
--========================================================================
local CloudDB = { ValidGames = {}, PendingGames = {} }

function CloudDB:Fetch()
    local cleanUrl = Utilities:GetCleanURL(CONFIG.GITHUB_DB)
    local success, data = pcall(function()
        return loadstring(game:HttpGet(cleanUrl))()
    end)
    
    if success and type(data) == "table" then
        self.ValidGames = data.Valid or {}
        self.PendingGames = data.Pending or {}
        return true
    end
    return false
end

--========================================================================
-- [UI MANAGER (LUNA LIB)]
--========================================================================
local UIManager = {}

function UIManager:Create(GameData)
    -- Ambil Luna UI (dengan Cache Buster agar selalu fresh)
    local successUI, Luna = pcall(function()
        return loadstring(game:HttpGet(Utilities:GetCleanURL("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/master/source.lua")))()
    end)

    if not successUI or type(Luna) ~= "table" then
        Utilities:SendNotification("❌ UI Error", "Gagal memuat sistem UI. Periksa jaringanmu.")
        return
    end

    local window = Luna:CreateWindow({
        Name = "Mizukage Hub",
        Subtitle = "v" .. CONFIG.VERSION,
        LogoID = "82795327169782",
        LoadingEnabled = true,
        LoadingTitle = "Mizukage Hub",
        LoadingSubtitle = "Memuat Fitur Premium...",
        ConfigSettings = { ConfigFolder = "MizuLauncher" },
        KeySystem = false
    })
    
    window:CreateHomeTab({
        SupportedExecutors = {"Delta", "Codex", "Wave", "Arceus X", "Krampus"},
        DiscordInvite = "Mizukage-Official",
        Icon = "home" 
    })
    
    -- ================= TAB 1: LAUNCHER & DATABASE =================
    local mainTab = window:CreateTab({ Name = "Game Launcher", Icon = "cloud", ShowTitle = true })
    
    if GameData then
        mainTab:CreateParagraph({
            Title = "✅ GAME TERDETEKSI: " .. GameData.Name,
            Text = "Mode Manual Aktif atau Auto-Execute Gagal. Silakan tekan tombol di bawah untuk menjalankan script."
        })
        mainTab:CreateButton({
            Name = "▶️ JALANKAN SCRIPT " .. GameData.Name,
            Description = "Eksekusi dari database: " .. GameData.Script,
            Callback = function()
                Luna:Notification({ Title = "Mengeksekusi", Content = "Mohon tunggu..." })
                
                local isSuccess, errMessage = Utilities:SafeExecute(GameData.Script)
                
                if isSuccess then
                    Luna:Notification({ Title = "Sukses", Content = "Script berhasil dijalankan!" })
                    task.wait(1)
                    Luna:Destroy()
                else
                    Luna:Notification({ Title = "Error Eksekusi", Content = errMessage })
                    warn("[Mizukage] Eksekusi Gagal: " .. errMessage)
                end
            end
        })
    else
        mainTab:CreateParagraph({
            Title = "⚠️ STATUS: GAME TIDAK DIDUKUNG",
            Text = "Game ini (PlaceID: "..PlaceID..") tidak ada di Database Utama. Gunakan fitur Universal."
        })
    end
    
    mainTab:CreateDivider()
    mainTab:CreateParagraph({ Title = "🌍 DATABASE UTAMA", Text = "Daftar game yang terdaftar di sistem." })
    
    for id, data in pairs(CloudDB.ValidGames) do
        mainTab:CreateButton({
            Name = data.Name,
            Description = "PlaceID: " .. tostring(id),
            Callback = function()
                if PlaceID == id then
                    local isSuccess, errMessage = Utilities:SafeExecute(data.Script)
                    if isSuccess then Luna:Destroy() else Luna:Notification({Title = "Error", Content = errMessage}) end
                else
                    Luna:Notification({ Title = "Teleportasi", Content = "Menuju ke " .. data.Name })
                    Services.TeleportService:Teleport(id, LocalPlayer)
                end
            end
        })
    end
    
    -- ================= TAB 2: UNIVERSAL PLAYER =================
    local playerTab = window:CreateTab({ Name = "Universal Player", Icon = "user", ShowTitle = true })
    
    playerTab:CreateSlider({
        Name = "WalkSpeed",
        Min = 16, Max = 500, Default = 16,
        Callback = function(Value)
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = Value
            end
        end
    })
    
    playerTab:CreateSlider({
        Name = "JumpPower",
        Min = 50, Max = 500, Default = 50,
        Callback = function(Value)
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.UseJumpPower = true
                LocalPlayer.Character.Humanoid.JumpPower = Value
            end
        end
    })

    local infJumpConnection
    playerTab:CreateToggle({
        Name = "Infinite Jump",
        Description = "Lompat di udara tanpa batas",
        CurrentValue = false,
        Callback = function(Value)
            if Value then
                infJumpConnection = Services.UserInputService.JumpRequest:Connect(function()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        LocalPlayer.Character.Humanoid:ChangeState("Jumping")
                    end
                end)
            else
                if infJumpConnection then infJumpConnection:Disconnect() end
            end
        end
    })

    playerTab:CreateButton({
        Name = "Full Heal / Reset Character",
        Callback = function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.Health = 0
            end
        end
    })

    -- ================= TAB 3: VISUALS & UTILITIES =================
    local utilTab = window:CreateTab({ Name = "Visual & Misc", Icon = "eye", ShowTitle = true })
    
    utilTab:CreateToggle({
        Name = "Anti-AFK",
        Description = "Mencegah kick 20 menit dari Roblox",
        CurrentValue = true, -- Default nyala
        Callback = function(Value)
            getgenv().AntiAfkEnabled = Value
        end
    })

    -- Sistem Anti-AFK Background
    LocalPlayer.Idled:Connect(function()
        if getgenv().AntiAfkEnabled then
            Services.VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            Services.VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
    end)

    utilTab:CreateButton({
        Name = "Fullbright (Terang Benderang)",
        Callback = function()
            Services.Lighting.Ambient = Color3.new(1, 1, 1)
            Services.Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
            Services.Lighting.ColorShift_Top = Color3.new(1, 1, 1)
            Services.Lighting.Brightness = 2
            Services.Lighting.GlobalShadows = false
            Services.Lighting.FogEnd = 9e9
            Luna:Notification({Title = "Visuals", Content = "Fullbright diaktifkan!"})
        end
    })

    utilTab:CreateButton({
        Name = "Extreme FPS Boost (Potato PC/HP)",
        Description = "Menghapus semua tekstur agar sangat lancar",
        Callback = function()
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.Material = Enum.Material.SmoothPlastic
                    v.CastShadow = false
                elseif v:IsA("Decal") or v:IsA("Texture") then
                    v:Destroy()
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                    v.Enabled = false
                end
            end
            Luna:Notification({Title = "Performance", Content = "Grafik diturunkan ke minimum!"})
        end
    })

    -- ================= TAB 4: SERVER TOOLS =================
    local serverTab = window:CreateTab({ Name = "Server Tools", Icon = "server", ShowTitle = true })

    serverTab:CreateButton({
        Name = "Server Hop (Pindah Server)",
        Callback = function()
            Luna:Notification({ Title = "Mencari", Content = "Mencari server public acak..." })
            local Http = Services.HttpService
            local Api = "https://games.roblox.com/v1/games/" .. PlaceID .. "/servers/Public?sortOrder=Asc&limit=100"
            
            local success, result = pcall(function() return Http:JSONDecode(game:HttpGet(Api)) end)
            if success and result and result.data then
                local servers = {}
                for _, v in ipairs(result.data) do
                    if v.playing < v.maxPlayers and v.id ~= game.JobId then
                        table.insert(servers, v.id)
                    end
                end
                if #servers > 0 then
                    local randomServer = servers[math.random(1, #servers)]
                    Services.TeleportService:TeleportToPlaceInstance(PlaceID, randomServer, LocalPlayer)
                else
                    Luna:Notification({ Title = "Gagal", Content = "Tidak ada server kosong ditemukan." })
                end
            end
        end
    })

    serverTab:CreateButton({
        Name = "Rejoin Server Ini",
        Callback = function()
            Services.TeleportService:TeleportToPlaceInstance(PlaceID, game.JobId, LocalPlayer)
        end
    })

    serverTab:CreateButton({
        Name = "Copy JobID Server",
        Callback = function()
            setclipboard(game.JobId)
            Luna:Notification({ Title = "Copied", Content = "JobId disalin ke clipboard." })
        end
    })
    
    window:CreateTab({ Name = "Settings", Icon = "settings", ShowTitle = true }):BuildConfigSection()
end

--========================================================================
-- [MAIN APPLICATION LOGIC]
--========================================================================
local App = {}

function App:Initialize()
    Utilities:SendNotification("Mizukage Hub", "Memulai inisialisasi...")
    
    local dbLoaded = CloudDB:Fetch()
    if not dbLoaded then
        Utilities:SendNotification("Warning", "Gagal load Database. Membuka mode Offline.")
        UIManager:Create(nil)
        return
    end
    
    local GameData = CloudDB.ValidGames[PlaceID]

    -- LOGIKA AUTO-EXECUTE vs MANUAL
    if GameData and not isManualMode then
        Utilities:SendNotification("Auto-Execute", "Menemukan game: " .. GameData.Name)
        task.wait(CONFIG.DELAY_BEFORE_EXECUTION)
        
        -- Menggunakan fungsi SafeExecute dengan Anti-Cache
        local successExec, errMessage = Utilities:SafeExecute(GameData.Script)
        
        if not successExec then
            warn("[Mizukage] Auto-Execution failed: " .. errMessage)
            Utilities:SendNotification("Error 404", "Link game bermasalah. Membuka UI Universal.")
            UIManager:Create(GameData)
        end
    else
        UIManager:Create(GameData)
    end
end

--========================================================================
-- [STARTUP]
--========================================================================
pcall(function() App:Initialize() end)
