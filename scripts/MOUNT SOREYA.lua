--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                     MIZUKAGE OFFICIAL 👑                         ║
    ║          GALATAMA GUNUNG SOREYA — v6.0 WINDUİ EDITION            ║
    ║   WindUI Framework • Full Fishing Automation Suite (FIXED)       ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════
-- [1] SINGLETON GUARD
-- ═══════════════════════════════════════════════════════════
if getgenv and getgenv().MizukageSoreyaV6 then
    warn("[Mizukage] Instance sudah berjalan. Unload dulu sebelum re-execute.")
    return
end
if getgenv then getgenv().MizukageSoreyaV6 = true end

-- ═══════════════════════════════════════════════════════════
-- [2] SERVICES
-- ═══════════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local VirtualUser       = game:GetService("VirtualUser")
local UserInputService  = game:GetService("UserInputService")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")
local Camera            = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait(0.05) until Players.LocalPlayer
    LocalPlayer = Players.LocalPlayer
end

-- ═══════════════════════════════════════════════════════════
-- [3] WINDUİ NATIVE LOADER
-- ═══════════════════════════════════════════════════════════
local WindUI
do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/1.6.65/main.lua"))()
    end)
    if not ok or type(result) ~= "table" then
        ok, result = pcall(function()
            return loadstring(game:HttpGet("https://tree-hub.vercel.app/api/UI/WindUI"))()
        end)
    end
    if not ok or type(result) ~= "table" then
        error("[Mizukage] WindUI gagal dimuat. Periksa koneksi.")
    end
    WindUI = result
end

-- ═══════════════════════════════════════════════════════════
-- [4] CONFIG & STATE
-- ═══════════════════════════════════════════════════════════
local Config = {
    Fishing = {
        AutoCastEnabled = false,
        CastPower       = 95,
        ChargeDelay     = 0.15,
        PostCastDelay   = 1.35,

        AutoReelEnabled = false,
        SmartDelay      = false,
        SmartOffset     = 0.0,
        StaticDelay     = 2.10,

        AutoEquip       = false,
        SyncInventory   = false,
    },
    Network = {
        CatchToast  = true,
        SecretRadar = false,
        Exclamation = false,
        AntiAfk     = false,
    },
    Character = {
        WalkSpeedEnabled = false,
        WalkSpeed        = 16,
        JumpPowerEnabled = false,
        JumpPower        = 50,
        InfiniteJump     = false,
        NoClip           = false,
        AntiFling        = false,
    },
    World = {
        Gravity = 196.2,
    },
    IsRunning = true,
}

local State = {
    ActiveRod = nil,
    Remotes = {
        CastEvent    = nil,
        MiniGame     = nil,
        NotifyClient = nil,
    },
    Flags = {
        Busy           = false,
        KailInWater    = false,
        InMinigame     = false,
        AwaitingReward = false,
        CooldownUntil  = 0,
        CastStartedAt  = nil,
    },
    Stats = {
        Catches      = 0,
        LastFish     = "Belum Ada",
        LastRarity   = "-",
        LastWeight   = 0,
        LastMutation = "Normal",
        StartTime    = os.clock(),
    },
}

-- ═══════════════════════════════════════════════════════════
-- [5] CLEANUP MANAGER (tag-based)
-- ═══════════════════════════════════════════════════════════
local Cleanup = { _conns = {}, _tasks = {} }

function Cleanup:AddConn(tag, conn)
    if not self._conns[tag] then self._conns[tag] = {} end
    table.insert(self._conns[tag], conn)
end

function Cleanup:AddTask(tag, thread)
    if not self._tasks[tag] then self._tasks[tag] = {} end
    table.insert(self._tasks[tag], thread)
end

function Cleanup:Clean(tag)
    if self._conns[tag] then
        for _, c in ipairs(self._conns[tag]) do
            pcall(function() c:Disconnect() end)
        end
        self._conns[tag] = nil
    end
    if self._tasks[tag] then
        for _, t in ipairs(self._tasks[tag]) do
            pcall(function() task.cancel(t) end)
        end
        self._tasks[tag] = nil
    end
end

function Cleanup:CleanAll()
    for tag in pairs(self._conns) do self:Clean(tag) end
    for tag in pairs(self._tasks) do self:Clean(tag) end
end

-- ═══════════════════════════════════════════════════════════
-- [6] UTILITIES
-- ═══════════════════════════════════════════════════════════
local function SafeNotify(title, content, duration, icon)
    pcall(function()
        WindUI:Notify({
            Title    = title,
            Content  = content,
            Duration = duration or 3,
            Icon     = icon or "lucide:info",
        })
    end)
end

local function SafeWait(parent, name, timeout)
    if not parent then return nil end
    local existing = parent:FindFirstChild(name)
    if existing then return existing end
    return parent:WaitForChild(name, timeout or 5)
end

-- ═══════════════════════════════════════════════════════════
-- [7] REMOTES RESOLUTION (fishing specific)
-- ═══════════════════════════════════════════════════════════
local SharedRemotes = {}
do
    SharedRemotes.TandaSeruBersama = SafeWait(ReplicatedStorage, "TandaSeruBersama", 3)

    local remote = SafeWait(ReplicatedStorage, "Remote", 3)
    if remote then
        local inv = SafeWait(remote, "Inventaris", 2)
        if inv then
            SharedRemotes.AmbilSemua        = SafeWait(inv, "AmbilSemua", 2)
            SharedRemotes.InventarisBerubah = SafeWait(inv, "Berubah", 2)
        end
        local adm = SafeWait(remote, "Admin", 2)
        if adm then
            SharedRemotes.AdminPesanChat = SafeWait(adm, "PesanChat", 2)
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- [8] FISHING ENGINE
-- ═══════════════════════════════════════════════════════════
local Engine = {}

function Engine.FormatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d", m, s)
end

function Engine.FindRodIn(container)
    if not container then return nil end
    for _, item in ipairs(container:GetChildren()) do
        if item:IsA("Tool") and item:FindFirstChild("Mechanics") then
            local remotes = item.Mechanics:FindFirstChild("Remotes")
            if remotes
               and remotes:FindFirstChild("CastEvent")
               and remotes:FindFirstChild("MiniGame") then
                return item
            end
        end
    end
    return nil
end

function Engine.EnsureEquipped()
    local char = LocalPlayer.Character
    if not char then return nil end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")

    local equipped = Engine.FindRodIn(char)
    if equipped then return equipped end

    local candidate = Engine.FindRodIn(bp)
    if candidate then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function() hum:EquipTool(candidate) end)
            task.wait(0.25)
            return candidate
        end
    end
    return nil
end

function Engine.GetReelDelay(payload)
    if Config.Fishing.SmartDelay then
        local difficulty = 1.8
        if type(payload) == "table" and payload.difficulty then
            difficulty = tonumber(payload.difficulty) or 1.8
        end
        return math.clamp(1.05 + (difficulty * 0.48) + Config.Fishing.SmartOffset, 0, 5)
    else
        return Config.Fishing.StaticDelay
    end
end

function Engine.ResetFlags()
    State.Flags.Busy           = false
    State.Flags.KailInWater    = false
    State.Flags.InMinigame     = false
    State.Flags.AwaitingReward = false
    State.Flags.CastStartedAt  = nil
end

function Engine.BindRod(rod)
    if not rod or rod == State.ActiveRod then return end

    local mechanics = rod:FindFirstChild("Mechanics")
    if not mechanics then return end
    local remotes = mechanics:FindFirstChild("Remotes")
    if not remotes then return end

    State.ActiveRod            = rod
    State.Remotes.CastEvent    = remotes:FindFirstChild("CastEvent")
    State.Remotes.MiniGame     = remotes:FindFirstChild("MiniGame")
    State.Remotes.NotifyClient = remotes:FindFirstChild("NotifyClient")

    Cleanup:Clean("Rod_MiniGame")
    Cleanup:Clean("Rod_Notify")

    if State.Remotes.MiniGame then
        local c = State.Remotes.MiniGame.OnClientEvent:Connect(function(action, payload)
            if action == "Start" then
                State.Flags.InMinigame     = true
                State.Flags.AwaitingReward = true

                if Config.Fishing.AutoReelEnabled then
                    local delay = Engine.GetReelDelay(payload)
                    task.delay(delay, function()
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
        Cleanup:AddConn("Rod_MiniGame", c)
    end

    if State.Remotes.NotifyClient then
        local c = State.Remotes.NotifyClient.OnClientEvent:Connect(function(action, data)
            if action == "Bite" then
                State.Flags.KailInWater = true
                if Config.Network.Exclamation and SharedRemotes.TandaSeruBersama then
                    pcall(function()
                        SharedRemotes.TandaSeruBersama:FireServer(
                            nil, nil, nil,
                            (data and data.duration) or 1.5
                        )
                    end)
                end

            elseif action == "GotFish" and type(data) == "table" then
                State.Stats.Catches      = State.Stats.Catches + 1
                State.Stats.LastFish     = tostring(data.baseName or data.originalName or "Ikan")
                State.Stats.LastRarity   = tostring(data.rarity or "Common")
                State.Stats.LastWeight   = tonumber(data.weight) or 0
                State.Stats.LastMutation = tostring(data.mutation or "Normal")

                if Config.Network.CatchToast then
                    SafeNotify(
                        "🎣 " .. State.Stats.LastFish,
                        string.format(
                            "Rarity: %s\nBerat: %.2f kg\nMutasi: %s",
                            State.Stats.LastRarity,
                            State.Stats.LastWeight,
                            State.Stats.LastMutation
                        ),
                        3.5,
                        "lucide:fish"
                    )
                end

                if Config.Fishing.SyncInventory and SharedRemotes.AmbilSemua then
                    pcall(function() SharedRemotes.AmbilSemua:InvokeServer() end)
                end

                Engine.ResetFlags()

            elseif action == "CastFailed" then
                Engine.ResetFlags()
                if data and data.reason == "Cooldown" then
                    State.Flags.CooldownUntil = os.clock() + 1.2
                end
            end
        end)
        Cleanup:AddConn("Rod_Notify", c)
    end
end

-- ═══════════════════════════════════════════════════════════
-- [9] AUTO CAST RUNNER
-- ═══════════════════════════════════════════════════════════
local function StartAutoCast()
    Cleanup:Clean("Loop_AutoCast")
    Cleanup:AddTask("Loop_AutoCast", task.spawn(function()
        while Config.Fishing.AutoCastEnabled and Config.IsRunning do
            task.wait(0.1)

            -- Watchdog anti-stuck
            if State.Flags.Busy and State.Flags.CastStartedAt then
                if os.clock() - State.Flags.CastStartedAt > 45 then
                    Engine.ResetFlags()
                end
            end

            local ready = (not State.Flags.Busy)
                and (os.clock() >= State.Flags.CooldownUntil)

            if ready then
                local rod = Engine.EnsureEquipped()
                if rod then
                    Engine.BindRod(rod)
                    if State.Remotes.CastEvent then
                        State.Flags.Busy          = true
                        State.Flags.CastStartedAt = os.clock()

                        pcall(function()
                            State.Remotes.CastEvent:FireServer(true)
                        end)
                        task.wait(Config.Fishing.ChargeDelay)
                        pcall(function()
                            State.Remotes.CastEvent:FireServer(false, Config.Fishing.CastPower, nil)
                        end)
                        task.wait(Config.Fishing.PostCastDelay)
                        State.Flags.KailInWater = true
                    else
                        State.Flags.Busy = false
                    end
                end
            end
        end
    end))
end

-- ═══════════════════════════════════════════════════════════
-- [10] UNIVERSAL CHARACTER LOOPS
-- ═══════════════════════════════════════════════════════════
Cleanup:AddTask("Loop_Character", task.spawn(function()
    while Config.IsRunning do
        task.wait(0.1)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                if Config.Character.WalkSpeedEnabled then
                    hum.WalkSpeed = Config.Character.WalkSpeed
                end
                if Config.Character.JumpPowerEnabled then
                    hum.UseJumpPower = true
                    hum.JumpPower    = Config.Character.JumpPower
                end
            end
        end
    end
end))

Cleanup:AddConn("InfJump", UserInputService.JumpRequest:Connect(function()
    if Config.Character.InfiniteJump then
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

Cleanup:AddConn("NoClip", RunService.Stepped:Connect(function()
    if Config.Character.NoClip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end))

Cleanup:AddConn("AntiFling", RunService.Stepped:Connect(function()
    if Config.Character.AntiFling then
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
end))

-- ═══════════════════════════════════════════════════════════
-- [11] GLOBAL HOOKS
-- ═══════════════════════════════════════════════════════════
if SharedRemotes.InventarisBerubah then
    Cleanup:AddConn("InvSync", SharedRemotes.InventarisBerubah.OnClientEvent:Connect(function()
        if Config.Fishing.SyncInventory and SharedRemotes.AmbilSemua then
            pcall(function() SharedRemotes.AmbilSemua:InvokeServer() end)
        end
    end))
end

if SharedRemotes.AdminPesanChat then
    Cleanup:AddConn("Radar", SharedRemotes.AdminPesanChat.OnClientEvent:Connect(function(msg)
        if Config.Network.SecretRadar
           and type(msg) == "string"
           and string.find(msg, "%[SECRET%]") then
            SafeNotify("🌍 SECRET RADAR", msg:gsub("<[^>]+>", ""), 5, "lucide:radar")
        end
    end))
end

Cleanup:AddConn("AntiAFK", LocalPlayer.Idled:Connect(function()
    if Config.Network.AntiAfk then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end
end))

-- ═══════════════════════════════════════════════════════════
-- [12] SERVER HOP
-- ═══════════════════════════════════════════════════════════
local function ExecuteServerHop()
    SafeNotify("Server Hop", "Mencari server publik lain...", 3, "lucide:globe")

    local servers = {}
    local req = request or http_request or (syn and syn.request)

    if req then
        pcall(function()
            local res = req({
                Url = string.format(
                    "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
                    game.PlaceId
                )
            })
            if res and res.Body then
                local body = HttpService:JSONDecode(res.Body)
                if body and body.data then
                    for _, v in ipairs(body.data) do
                        if type(v) == "table"
                           and v.playing < v.maxPlayers
                           and v.id ~= game.JobId then
                            table.insert(servers, v.id)
                        end
                    end
                end
            end
        end)
    end

    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(
            game.PlaceId,
            servers[math.random(1, #servers)],
            LocalPlayer
        )
    else
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end

-- ═══════════════════════════════════════════════════════════
-- [13] WINDUİ INTERFACE
-- ═══════════════════════════════════════════════════════════
local Window

do
    -- LOCALIZATION
    WindUI:Localization({
        Enabled = true,
        Prefix = "loc:",
        DefaultLanguage = "id",
        Translations = {
            ["id"] = {
                ["WELCOME"]    = "Selamat Datang di Mizukage Official!",
                ["DASHBOARD"]  = "Dashboard",
                ["CAST"]       = "Auto Cast",
                ["REEL"]       = "Auto Reel",
                ["RADAR"]      = "Radar & Jaringan",
                ["CHARACTER"]  = "Karakter",
                ["WORLD"]      = "Dunia",
                ["SYSTEM"]     = "Sistem Utama",
                ["CLOSE"]      = "Tutup",
                ["START"]      = "Mulai Auto Cast",
            },
            ["en"] = {
                ["WELCOME"]    = "Welcome to Mizukage Official!",
                ["DASHBOARD"]  = "Dashboard",
                ["CAST"]       = "Auto Cast",
                ["REEL"]       = "Auto Reel",
                ["RADAR"]      = "Radar & Network",
                ["CHARACTER"]  = "Character",
                ["WORLD"]      = "World",
                ["SYSTEM"]     = "System",
                ["CLOSE"]      = "Close",
                ["START"]      = "Start Auto Cast",
            },
        }
    })

    -- GRADIENT
    WindUI:Gradient({
        ["0"]   = { Color = Color3.fromHex("#5c5291"), Transparency = 0.15 },
        ["50"]  = { Color = Color3.fromHex("#0096ff"), Transparency = 0.10 },
        ["100"] = { Color = Color3.fromHex("#18181b"), Transparency = 0 },
    }, { Rotation = 45 })

    local viewport  = Camera.ViewportSize
    local isMobile  = viewport.X < 850
    local dynamicSize = isMobile
        and UDim2.fromOffset(viewport.X * 0.95, viewport.Y * 0.95)
        or UDim2.fromOffset(840, 600)

    Window = WindUI:CreateWindow({
        Title        = "MIZUKAGE OFFICIAL 👑",
        Icon         = "lucide:crown",
        Author       = "GUNUNG SOREYA EDITION",
        Folder       = "MizukageSoreya",
        Size         = dynamicSize,
        MinSize      = Vector2.new(560, 400),
        MaxSize      = Vector2.new(950, 750),
        ToggleKey    = Enum.KeyCode.RightShift,
        Transparent  = true,
        Theme        = "Dark",
        Accent       = Color3.fromRGB(92, 82, 145),
        Resizable    = true,
        SideBarWidth = isMobile and 240 or 260,
        HasOutline   = true,
        BackgroundImageTransparency = 0.42,
        Background   = "rbxassetid://137490169052447",
        HideSearchBar = false,
        ScrollBarEnabled = true,
        User = {
            Enabled   = true,
            Anonymous = false,
            Callback  = function()
                WindUI:Notify({
                    Title    = "👤 Info Pemain",
                    Content  = string.format(
                        "Name: %s\nDisplay: %s\nUserID: %s",
                        LocalPlayer.Name,
                        LocalPlayer.DisplayName,
                        LocalPlayer.UserId
                    ),
                    Duration = 5,
                    Icon     = "lucide:user",
                })
            end,
        },
    })

    Window:Tag({
        Title  = "👑 VIP",
        Icon   = "lucide:crown",
        Color  = Color3.fromHex("#FFD700"),
        Radius = 13,
    })

    Window:Tag({
        Title  = "v6.0",
        Icon   = "lucide:sparkles",
        Color  = Color3.fromHex("#30ff6a"),
        Radius = 6,
    })

    Window:Tag({
        Title  = "SOREYA",
        Icon   = "lucide:fish",
        Color  = Color3.fromHex("#0096ff"),
        Radius = 0,
    })

    Window:Divider()

    -- ─── TABS ───
    local TabDash  = Window:Tab({ Title = "loc:DASHBOARD", Icon = "lucide:layout-dashboard" })
    local TabCast  = Window:Tab({ Title = "loc:CAST",      Icon = "lucide:cast" })
    local TabReel  = Window:Tab({ Title = "loc:REEL",      Icon = "lucide:target" })
    local TabRadar = Window:Tab({ Title = "loc:RADAR",     Icon = "lucide:radar" })
    local TabChar  = Window:Tab({ Title = "loc:CHARACTER", Icon = "lucide:user" })
    local TabWorld = Window:Tab({ Title = "loc:WORLD",     Icon = "lucide:globe" })
    local TabSys   = Window:Tab({ Title = "loc:SYSTEM",    Icon = "lucide:settings" })

    -- ═══════════════════════════════════════════
    -- TAB: DASHBOARD
    -- ═══════════════════════════════════════════
    TabDash:Section({ Title = "Statistik Sesi" })

    TabDash:Paragraph({
        Title = "Pantau Aktivitas Memancing",
        Desc  = "Tekan tombol Refresh untuk melihat data terbaru.",
        Image = "lucide:bar-chart",
        ImageSize = 24,
    })

    TabDash:Button({
        Title = "Refresh Statistik",
        Variant = "Primary",
        Icon = "lucide:refresh-cw",
        Callback = function()
            local uptime = Engine.FormatTime(os.clock() - State.Stats.StartTime)
            SafeNotify(
                "📊 Statistik Sesi",
                string.format(
                    "Tangkapan: %d ekor\nTerakhir: %s [%s]\nBerat: %.2f kg\nMutasi: %s\nUptime: %s",
                    State.Stats.Catches,
                    State.Stats.LastFish,
                    State.Stats.LastRarity,
                    State.Stats.LastWeight,
                    State.Stats.LastMutation,
                    uptime
                ),
                6,
                "lucide:bar-chart"
            )
        end,
    })

    TabDash:Divider()
    TabDash:Section({ Title = "Master Control" })

    TabDash:Toggle({
        Title    = "Master Auto Fishing (Cast + Reel)",
        Flag     = "MasterAutoFish",
        Default  = false,
        Callback = function(val)
            Config.Fishing.AutoCastEnabled = val
            Config.Fishing.AutoReelEnabled = val
            if val then
                StartAutoCast()
                SafeNotify("Master Auto", "Auto Cast + Auto Reel aktif.", 3, "lucide:zap")
            else
                Cleanup:Clean("Loop_AutoCast")
                Engine.ResetFlags()
                SafeNotify("Master Auto", "Auto Cast + Auto Reel nonaktif.", 3, "lucide:power")
            end
        end,
    })

    -- ═══════════════════════════════════════════
    -- TAB: AUTO CAST
    -- ═══════════════════════════════════════════
    TabCast:Section({ Title = "Auto Lempar Kail" })

    TabCast:Toggle({
        Title    = "Auto Cast",
        Flag     = "AutoCastEnabled",
        Default  = false,
        Callback = function(val)
            Config.Fishing.AutoCastEnabled = val
            if val then
                StartAutoCast()
                SafeNotify("Auto Cast", "Auto lempar kail aktif.", 3, "lucide:cast")
            else
                Cleanup:Clean("Loop_AutoCast")
                Engine.ResetFlags()
                SafeNotify("Auto Cast", "Auto lempar kail berhenti.", 3, "lucide:power")
            end
        end,
    })

    TabCast:Slider({
        Title    = "Power Tarikan",
        Flag     = "CastPower",
        Step     = 1,
        Value    = { Min = 20, Max = 100, Default = Config.Fishing.CastPower },
        Callback = function(v) Config.Fishing.CastPower = v end,
    })

    TabCast:Slider({
        Title    = "Delay Charge (Tahan Kail)",
        Flag     = "ChargeDelay",
        Step     = 0.05,
        Value    = { Min = 0, Max = 1.0, Default = Config.Fishing.ChargeDelay },
        Callback = function(v) Config.Fishing.ChargeDelay = v end,
    })

    TabCast:Slider({
        Title    = "Delay Pasca Lempar",
        Flag     = "PostCastDelay",
        Step     = 0.05,
        Value    = { Min = 0.5, Max = 3.5, Default = Config.Fishing.PostCastDelay },
        Callback = function(v) Config.Fishing.PostCastDelay = v end,
    })

    -- ═══════════════════════════════════════════
    -- TAB: AUTO REEL
    -- ═══════════════════════════════════════════
    TabReel:Section({ Title = "Auto Tarik Ikan" })

    TabReel:Toggle({
        Title    = "Auto Reel",
        Flag     = "AutoReelEnabled",
        Default  = false,
        Callback = function(val)
            Config.Fishing.AutoReelEnabled = val
            SafeNotify(
                "Auto Reel",
                val and "Auto tarik aktif." or "Auto tarik nonaktif.",
                3,
                "lucide:target"
            )
        end,
    })

    TabReel:Divider()
    TabReel:Section({ Title = "Manual Override (Tanpa Smart)" })

    TabReel:Slider({
        Title    = "Static Reel Delay (Detik)",
        Flag     = "StaticDelay",
        Step     = 0.05,
        Value    = { Min = 0, Max = 5.0, Default = Config.Fishing.StaticDelay },
        Callback = function(v) Config.Fishing.StaticDelay = v end,
    })

    TabReel:Divider()
    TabReel:Section({ Title = "Smart Adaptive (Ikuti Difficulty)" })

    TabReel:Toggle({
        Title    = "Gunakan Smart Adaptive Delay",
        Flag     = "SmartDelay",
        Default  = false,
        Callback = function(val) Config.Fishing.SmartDelay = val end,
    })

    TabReel:Slider({
        Title    = "Smart Delay Offset (Detik Tambahan)",
        Flag     = "SmartOffset",
        Step     = 0.05,
        Value    = { Min = -2.0, Max = 2.0, Default = Config.Fishing.SmartOffset },
        Callback = function(v) Config.Fishing.SmartOffset = v end,
    })

    -- ═══════════════════════════════════════════
    -- TAB: RADAR & JARINGAN
    -- ═══════════════════════════════════════════
    TabRadar:Section({ Title = "Kontrol Inventaris & Jaringan" })

    TabRadar:Toggle({
        Title    = "Auto Equip Pancingan",
        Flag     = "AutoEquip",
        Default  = false,
        Callback = function(val)
            Config.Fishing.AutoEquip = val
            if val then
                local rod = Engine.EnsureEquipped()
                SafeNotify(
                    "Auto Equip",
                    rod and ("Rod aktif: " .. rod.Name) or "Rod tidak ditemukan.",
                    3,
                    "lucide:package"
                )
            end
        end,
    })

    TabRadar:Toggle({
        Title    = "Auto Sinkronisasi Inventaris",
        Flag     = "SyncInventory",
        Default  = false,
        Callback = function(val) Config.Fishing.SyncInventory = val end,
    })

    TabRadar:Divider()

    TabRadar:Toggle({
        Title    = "Anti-AFK (Bypass Idle)",
        Flag     = "AntiAfk",
        Default  = false,
        Callback = function(val) Config.Network.AntiAfk = val end,
    })

    TabRadar:Toggle({
        Title    = "Notifikasi Tangkapan (Toast)",
        Flag     = "CatchToast",
        Default  = true,
        Callback = function(val) Config.Network.CatchToast = val end,
    })

    TabRadar:Divider()

    TabRadar:Toggle({
        Title    = "Radar Ikan Secret Server",
        Flag     = "SecretRadar",
        Default  = false,
        Callback = function(val) Config.Network.SecretRadar = val end,
    })

    TabRadar:Toggle({
        Title    = "Replikasi Animasi Tanda Seru (!)",
        Flag     = "Exclamation",
        Default  = false,
        Callback = function(val) Config.Network.Exclamation = val end,
    })

    -- ═══════════════════════════════════════════
    -- TAB: KARAKTER
    -- ═══════════════════════════════════════════
    TabChar:Section({ Title = "Atribut Pemain" })

    TabChar:Toggle({
        Title    = "Aktifkan Custom WalkSpeed",
        Flag     = "WalkSpeedEnabled",
        Default  = false,
        Callback = function(val) Config.Character.WalkSpeedEnabled = val end,
    })

    TabChar:Slider({
        Title    = "Nilai WalkSpeed",
        Flag     = "WalkSpeedValue",
        Step     = 1,
        Value    = { Min = 16, Max = 250, Default = Config.Character.WalkSpeed },
        Callback = function(v) Config.Character.WalkSpeed = v end,
    })

    TabChar:Divider()

    TabChar:Toggle({
        Title    = "Aktifkan Custom JumpPower",
        Flag     = "JumpPowerEnabled",
        Default  = false,
        Callback = function(val) Config.Character.JumpPowerEnabled = val end,
    })

    TabChar:Slider({
        Title    = "Nilai JumpPower",
        Flag     = "JumpPowerValue",
        Step     = 1,
        Value    = { Min = 50, Max = 300, Default = Config.Character.JumpPower },
        Callback = function(v) Config.Character.JumpPower = v end,
    })

    TabChar:Divider()

    TabChar:Toggle({
        Title    = "Infinite Jump",
        Flag     = "InfiniteJump",
        Default  = false,
        Callback = function(val) Config.Character.InfiniteJump = val end,
    })

    -- ═══════════════════════════════════════════
    -- TAB: DUNIA
    -- ═══════════════════════════════════════════
    TabWorld:Section({ Title = "Modifikasi Lingkungan" })

    TabWorld:Toggle({
        Title    = "No-Clip (Tembus Dinding)",
        Flag     = "NoClip",
        Default  = false,
        Callback = function(val) Config.Character.NoClip = val end,
    })

    TabWorld:Toggle({
        Title    = "Anti-Fling (Tembus Pemain Lain)",
        Flag     = "AntiFling",
        Default  = false,
        Callback = function(val) Config.Character.AntiFling = val end,
    })

    TabWorld:Slider({
        Title    = "Modifikasi Gravitasi Game",
        Flag     = "Gravity",
        Step     = 1,
        Value    = { Min = 0, Max = 300, Default = Config.World.Gravity },
        Callback = function(v)
            Config.World.Gravity = v
            Workspace.Gravity = v
        end,
    })

    TabWorld:Divider()
    TabWorld:Section({ Title = "Lokasi Server" })

    TabWorld:Button({
        Title    = "Pindah Server (Server Hop)",
        Variant  = "Primary",
        Icon     = "lucide:globe",
        Callback = ExecuteServerHop,
    })

    TabWorld:Button({
        Title    = "Rejoin Server Saat Ini",
        Variant  = "Secondary",
        Icon     = "lucide:refresh-cw",
        Callback = function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end,
    })

    -- ═══════════════════════════════════════════
    -- TAB: SISTEM
    -- ═══════════════════════════════════════════
    TabSys:Section({ Title = "Manajemen Script" })

    TabSys:Button({
        Title   = "Paksa Sinkronkan Inventaris Sekarang",
        Variant = "Secondary",
        Icon    = "lucide:package-search",
        Callback = function()
            if SharedRemotes.AmbilSemua then
                pcall(function() SharedRemotes.AmbilSemua:InvokeServer() end)
                SafeNotify("Inventaris", "Permintaan sinkronisasi dikirim.", 3, "lucide:check")
            else
                SafeNotify("Inventaris", "Remote tidak ditemukan.", 3, "lucide:x")
            end
        end,
    })

    TabSys:Divider()

    TabSys:Button({
        Title   = "Unload Script (Terminate)",
        Variant = "Destructive",
        Icon    = "lucide:power",
        Callback = function()
            Window:Dialog({
                Icon    = "lucide:alert-triangle",
                Title   = "Konfirmasi Unload",
                Content = "Yakin ingin menghentikan script?",
                Buttons = {
                    {
                        Title    = "Batal",
                        Variant  = "Tertiary",
                        Callback = function() end,
                    },
                    {
                        Title   = "Ya, Unload",
                        Icon    = "lucide:power",
                        Variant = "Destructive",
                        Callback = function()
                            Config.IsRunning = false
                            Config.Fishing.AutoCastEnabled = false
                            Config.Fishing.AutoReelEnabled = false
                            Config.Character.WalkSpeedEnabled = false
                            Config.Character.JumpPowerEnabled = false
                            Config.Character.InfiniteJump = false
                            Config.Character.NoClip = false
                            Config.Character.AntiFling = false
                            Workspace.Gravity = 196.2

                            Engine.ResetFlags()
                            Cleanup:CleanAll()

                            if getgenv then getgenv().MizukageSoreyaV6 = nil end

                            SafeNotify("Mizukage", "Script dinonaktifkan.", 3, "lucide:heart")
                            task.wait(0.8)

                            if Window and Window.Destroy then
                                pcall(function() Window:Destroy() end)
                            end
                        end,
                    },
                },
            })
        end,
    })

    -- ─── WELCOME POPUP ───
    task.wait(0.5)
    WindUI:Popup({
        Title   = "loc:WELCOME",
        Icon    = "lucide:crown",
        Content = "🎣 Galatama Gunung Soreya siap!\n\n👑 Mizukage Official\n⚙️ Version: v6.0 WindUI Edition\n🎣 Auto Cast & Reel\n📦 Auto Equip & Sync\n🛡️ Universal Karakter & Dunia\n\nPilih tab untuk mulai mengatur.\n\nSelamat memancing!",
        Buttons = {
            {
                Title    = "loc:CLOSE",
                Variant  = "Tertiary",
                Callback = function() end,
            },
            {
                Title   = "loc:START",
                Icon    = "lucide:cast",
                Variant = "Primary",
                Callback = function()
                    Config.Fishing.AutoCastEnabled = true
                    Config.Fishing.AutoReelEnabled = true
                    StartAutoCast()
                    SafeNotify("Master Auto", "Auto Cast + Auto Reel aktif.", 3, "lucide:zap")
                end,
            },
        },
    })
end

-- ═══════════════════════════════════════════════════════════
-- [14] BOOTSTRAP
-- ═══════════════════════════════════════════════════════════
task.defer(function()
    local rod = Engine.EnsureEquipped()
    if rod then Engine.BindRod(rod) end
end)

SafeNotify(
    "Mizukage Official 👑",
    "v6.0 WindUI Edition dimuat.\nSelamat memancing!",
    5,
    "lucide:crown"
)