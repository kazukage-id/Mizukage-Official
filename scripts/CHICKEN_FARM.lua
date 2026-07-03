--==================================================================================--
-- [ INTEGRASI PROYEK ] - CHICKEN FARM + EXO HUB
-- Versi: Skrip Premium Ultimate V8 (Anti-Lag & Bypass)
-- Pengembang: AI Assistant (Tim Mizu Adaptation)
-- Status: Optimalisasi FPS, By-Pass Touch, No-Drop Limit
--==================================================================================--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

if not game:IsLoaded() then game.Loaded:Wait() end

-- ================================================== --
-- [ KEAMANAN REFERENSI REMOTE & STRUKTUR ]
-- ================================================== --
local PaperRemotes = ReplicatedStorage:WaitForChild("Paper", 5):WaitForChild("Remotes", 5)
local RE = PaperRemotes:WaitForChild("__remoteevent", 5)
local RF = PaperRemotes:WaitForChild("__remotefunction", 5)

-- Fungsi Cerdas untuk mencari Nest (Sarang) pemain agar Telur fisik bisa dihapus (Menghilangkan Lag)
local function AmbilSarangAyam()
    local path = Workspace:FindFirstChild("Plots")
    if path and path:FindFirstChild(LocalPlayer.Name) then
        local chickenFolder = path[LocalPlayer.Name]:FindFirstChild("Chickens")
        if chickenFolder then return chickenFolder:FindFirstChild("ChickenNest") end
    end
    return nil
end

-- Variabel Status Sistem (Sama seperti Fishing Chef)
local Automasi = { TugasSaatIni = "Sistem Menunggu..." }
local Config = {
    AutoTelur = false,
    HapusVisualTelur = true, -- Rahasia Anti-Lag!
    AutoLuckyBlock = false,
    AutoDeposit = false,
    AutoCash = false,
    AutoMerge = false,
    AutoBuy = false,
    AutoBuyAmount = 25,
    AutoProcess = false,
    AutoTier = false,
    AntiAFK = true,
    SpeedFarming = 0.5
}

-- ================================================== --
-- [ ENGINE: PSEUDO-GAMEPASS & EXPLOIT LISTENER ]
-- ================================================== --
RE.OnClientEvent:Connect(function(Aksi, UUID, TipeAtauKali, Posisi, TargetPath)
    -- BAYPASS SISTEM GAMEPASS & SENTUH: AMBIL TELUR OTOMATIS
    if Config.AutoTelur and Aksi == "Egg Dropped" then
        Automasi.TugasSaatIni = "Mengekstrak Telur (" .. UUID:sub(1,5) .. ")"
        
        -- Jangan didupe karena terdeteksi/menyebabkan frame-drop, tembak bersih:
        RE:FireServer("Collect Egg", UUID)
    end

    -- SISTEM SNIPER LUCKY BLOCK INSTAN
    if Config.AutoLuckyBlock and Aksi == "LuckyBlock Dropped" then
        Automasi.TugasSaatIni = "Snipe Lucky Block"
        task.spawn(function()
            -- Metode valid berdasarkan rekaman lalu lintas (SpyTraffic) Anda
            RF:InvokeServer("Collect Lucky Block", UUID)
            task.wait(0.1)
            RF:InvokeServer("Open Lucky Block")
        end)
    end
end)

-- ENGINE PENCEGAH LAG (Menghancurkan mesh telur fisik 0.1 detik setelah dicollect)
task.spawn(function()
    while true do
        task.wait(1)
        if Config.HapusVisualTelur and Config.AutoTelur then
            local sarang = AmbilSarangAyam()
            if sarang then
                -- Menghancurkan BasePart / Telur dari map secara lokal (Klien RAM hemat)
                for _, benda in pairs(sarang:GetChildren()) do
                    if benda:IsA("BasePart") or benda:IsA("Model") then
                        benda:Destroy()
                    end
                end
            end
        end
    end
end)

-- Anti AFK Modul 
LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- ================================================== --
-- [ PUSTAKA UI (RAYFIELD FRAMEWORK V7 STYLE) ]
-- ================================================== --
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "TEAMMIZU 🔰 | CHICKEN FARM",
    LoadingTitle = "Inisialisasi Mizukage Official...",
    LoadingSubtitle = "Menyembunyikan Klien",
    Theme = "DarkBlue",
    ConfigurationSaving = { Enabled = true, FolderName = "MizuConfig", FileName = "FarmData" },
    KeySystem = false
})

-- [ PEMBAGIAN TAB ]
local TabDasbor = Window:CreateTab("Dasbor", 4483362458)
local TabPertanian = Window:CreateTab("Bypass & Farm", 4483362458)
local TabBelanja = Window:CreateTab("Otomasi Toko", 4483362458)

-- ================================================== --
-- [ TAB 1: DASBOR (TELEMETRI SISTEM) ]
-- ================================================== --
local InfoKinerja = TabDasbor:CreateParagraph({Title = "Pemantau Mesin (Real-time)", Content = "Mengkalkulasi..."})

RunService.RenderStepped:Connect(function()
    local ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end) and math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) or 0
    local fps = math.floor(Workspace:GetRealPhysicsFPS() or 60)
    
    InfoKinerja:Set({
        Title = "📡 Pemantau Mesin (Real-time)",
        Content = string.format("🕹️ Kinerja Grafis: %d FPS\n⚡ Latensi Klien: %d ms\n⚙️ Aksi Terkini: %s\n🧹 Status V-Clear (No Lag): %s", fps, ping, Automasi.TugasSaatIni, tostring(Config.HapusVisualTelur))
    })
end)

-- ================================================== --
-- [ TAB 2: PERTANIAN (BYPASS GAMEPASS & EGG LOOP) ]
-- ================================================== --
TabPertanian:CreateSection("EKSPLOITASI SISTEM UTAMA")

TabPertanian:CreateToggle({ Name = "[Gamepass Bypassed] Auto Collect Eggs", CurrentValue = false, Callback = function(v) Config.AutoTelur = v end })
TabPertanian:CreateToggle({ Name = "[Optimasional FPS] Hancurkan Fisik Telur", CurrentValue = true, Callback = function(v) Config.HapusVisualTelur = v end })
TabPertanian:CreateToggle({ Name = "[Instant Action] Auto Klaim Lucky Block", CurrentValue = false, Callback = function(v) Config.AutoLuckyBlock = v end })

TabPertanian:CreateSection("MANAJEMEN REKENING (CASH/DEPOSIT)")

TabPertanian:CreateToggle({ Name = "[Gamepass Bypassed] Auto Kumpulkan Cash", CurrentValue = false, Callback = function(v) Config.AutoCash = v end })
TabPertanian:CreateToggle({ Name = "[Otomatisasi Lanjut] Auto Tukar/Deposit", CurrentValue = false, Callback = function(v) Config.AutoDeposit = v end })
TabPertanian:CreateToggle({ Name = "[Mekanika Pet] Auto Gabung (Merge) Ayam", CurrentValue = false, Callback = function(v) Config.AutoMerge = v end })

TabPertanian:CreateSlider({
    Name = "Jeda Proses Panggilan Server",
    Info = "Turunkan untuk mempercepat panen uang, naikkan jika server drop.",
    Range = {0.1, 5}, Increment = 0.1, CurrentValue = 0.5, Suffix = "Detik",
    Callback = function(v) Config.SpeedFarming = v end,
})

-- ================================================== --
-- [ TAB 3: BELANJA & TINGKATAN TIER ]
-- ================================================== --
TabBelanja:CreateSection("MANAJER PEMBELIAN")

TabBelanja:CreateDropdown({
    Name = "Kuantitas Ayam per Transaksi",
    Options = {"1", "5", "25", "100"},
    CurrentOption = {"25"},
    MultipleOptions = false,
    Callback = function(Option) Config.AutoBuyAmount = tonumber(Option[1]) end,
})
TabBelanja:CreateToggle({ Name = "Jalankan Auto Buy", CurrentValue = false, Callback = function(v) Config.AutoBuy = v end })

TabBelanja:CreateSection("AUTO-SPAM UPGRADES")
TabBelanja:CreateToggle({ Name = "Otomatis Tumbuk 'Upgrade Process'", CurrentValue = false, Callback = function(v) Config.AutoProcess = v end })
TabBelanja:CreateToggle({ Name = "Otomatis Tumbuk 'Upgrade Buy Tier'", CurrentValue = false, Callback = function(v) Config.AutoTier = v end })

-- Tombol Extra (Manual Utility)
TabBelanja:CreateButton({ Name = "Hancurkan Lucky Block Tersisa (Fix Glitch)", Callback = function() pcall(function() RE:FireServer("Discard Lucky Block") end) end })

-- ================================================== --
-- [ MESIN LATAR BELAKANG ASINKRON ]
-- ================================================== --
-- Loop Eksekusi Deposit, Cash, & Upgrades
task.spawn(function()
    while true do
        task.wait(Config.SpeedFarming) -- Terikat dengan slider
        
        -- Memanggil Fungsi berdasarkan saklar tanpa menunggu error
        pcall(function()
            if Config.AutoCash then 
                Automasi.TugasSaatIni = "Pencairan Kas"
                RF:InvokeServer("Collect Cash") 
            end
            if Config.AutoDeposit then 
                Automasi.TugasSaatIni = "Deposit Bank"
                RF:InvokeServer("Deposit Eggs") 
            end
            if Config.AutoMerge then 
                Automasi.TugasSaatIni = "Evolusi Genetik Ayam"
                RF:InvokeServer("Merge Chickens") 
            end
            
            -- Belanja Loop dipisah menjadi sedikit lebih jarang untuk menghindari blok pembelian
            if Config.AutoBuy and math.random() > 0.5 then 
                Automasi.TugasSaatIni = "Akuisisi Ternak (x" .. Config.AutoBuyAmount .. ")"
                RF:InvokeServer("Buy Chickens", Config.AutoBuyAmount) 
            end
            if Config.AutoProcess and math.random() > 0.7 then RF:InvokeServer("Upgrade Process Level") end
            if Config.AutoTier and math.random() > 0.7 then RF:InvokeServer("Upgrade Buy Tier Level") end
        end)
    end
end)

Rayfield:Notify({Title = "PENGAKTIFAN SUKSES", Content = "Protokol Bypass Anti-Lag dijalankan", Duration = 3, Image = "check"})