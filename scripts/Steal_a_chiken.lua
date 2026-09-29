--[[
    ╔══════════════════════════════════════════════════════════════════════════╗
    ║                        MIZUKAGE OFFICIAL 👑                             ║
    ║             REMO NEST & EGG AUTOMATION SUITE — GEN2 FULL                 ║
    ║               PURE LUAU • ENTERPRISE COMPLETE EDITION                    ║
    ╚══════════════════════════════════════════════════════════════════════════╝
]]

-- ══════════════════════════════════════════════════════════════════════
-- [1] SERVICES & LOCAL PLAYER INITIALIZATION
-- ══════════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
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
-- [3] CONFIGURATION & STATE REPOSITORY
-- ══════════════════════════════════════════════════════════════════════
local Config = {
    Automation = {
        AutoSteal = false,
        AutoSellAll = false,
        AutoCollectAll = false,
        AutoPressOne = false,
        FastPrompt = true,
        
        -- Timing Delays (Dapat dikonfigurasi langsung)
        StealLoopDelay = 0.3,
        PostTeleportDelay = 0.2,
        TouchDelay = 0.15,
        PostInvokeDelay = 0.1,
        ReturnDelay = 0.2,
        PostCycleDelay = 0.5,
        SellInterval = 2.0,
        CollectInterval = 2.0,
        PressOneInterval = 1.0
    },
    Zones = {
        Forest = false,
        Lake = false,
        Jungle = false,
        Desert = false,
        Snow = false,
        Volcano = false,
        Beach = false,
        Abyss = false,
        Cosmic = false,
        Crystal = false,
        Candy = false,
        Alien = false,
        Magma = false,
        BlueLava = false
    },
    Universal = {
        WalkSpeedEnabled = false,
        WalkSpeed = 16,
        JumpPowerEnabled = false,
        JumpPower = 50,
        InfiniteJump = false,
        NoClip = false,
        AntiFling = false,
        Gravity = 196.2,
        AntiAfk = true
    }
}

-- Definisi batas koordinat X tiap zona game
local ZoneBounds = {
    Forest   = { minX = 0,    maxX = 99 },
    Lake     = { minX = 100,  maxX = 249 },
    Jungle   = { minX = 250,  maxX = 449 },
    Desert   = { minX = 450,  maxX = 729 },
    Snow     = { minX = 730,  maxX = 1049 },
    Volcano  = { minX = 1050, maxX = 1439 },
    Beach    = { minX = 1440, maxX = 1929 },
    Abyss    = { minX = 1930, maxX = 2489 },
    Cosmic   = { minX = 2490, maxX = 3109 },
    Crystal  = { minX = 3110, maxX = 3719 },
    Candy    = { minX = 3720, maxX = 4313 },
    Alien    = { minX = 4314, maxX = 4869 },
    Magma    = { minX = 4870, maxX = 5500 },
    BlueLava = { minX = 5501, maxX = 6500 }
}

local BasePosition = Vector3.new(-23.16, 34.7, -283.98)

local State = {
    Connections = {},
    Stats = {
        StealAttempts = 0,
        TotalSells = 0,
        TotalClaims = 0,
        LastTargetZone = "None",
        StartTime = os.time()
    },
    Flags = {
        IsStealing = false,
        OptimizedFPS = false
    }
}

-- ══════════════════════════════════════════════════════════════════════
-- [4] REMO REMOTE CONTAINER RESOLVER
-- ══════════════════════════════════════════════════════════════════════
local RemoContainer = nil
pcall(function()
    RemoContainer = ReplicatedStorage:WaitForChild("packages", 5)
        :WaitForChild("_Index", 5)
        :WaitForChild("littensy_remo@1.5.3", 5)
        :WaitForChild("remo", 5)
        :WaitForChild("container", 5)
end)

-- ══════════════════════════════════════════════════════════════════════
-- [5] CORE HELPER & TARGET SCANNER
-- ══════════════════════════════════════════════════════════════════════
local Core = {}

function Core.FormatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%02d:%02d", m, s)
end

function Core.HasActiveZone()
    for _, active in pairs(Config.Zones) do
        if active then return true end
    end
    return false
end

function Core.FindNearestTarget()
    if not Config.Automation.AutoSteal then
        return nil, nil, nil
    end

    local gameFolder = Workspace:FindFirstChild("Game")
    if not gameFolder then
        return nil, nil, nil
    end

    local bestPos = nil
    local bestInstance = nil
    local bestZone = nil
    local shortestDist = math.huge

    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local playerPos = rootPart and rootPart.Position or Vector3.new(0, 0, 0)

    for _, obj in ipairs(gameFolder:GetDescendants()) do
        local nameLower = obj.Name:lower()

        if (nameLower:match("chicken") or nameLower:match("chick") or nameLower:match("bird")
            or nameLower:match("rooster") or nameLower:match("hen"))
            and (obj:IsA("Model") or obj:IsA("BasePart")) then

            local objPos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position

            if math.abs(objPos.X) > 60 then
                for zoneName, isEnabled in pairs(Config.Zones) do
                    if isEnabled then
                        local bounds = ZoneBounds[zoneName]
                        if bounds and objPos.X >= bounds.minX and objPos.X <= bounds.maxX
                            and objPos.Y > 10 and objPos.Y < 120 then

                            local distance = (objPos - playerPos).Magnitude
                            if distance < shortestDist then
                                shortestDist = distance
                                bestZone = zoneName
                                bestPos = objPos
                                bestInstance = obj
                            end
                        end
                    end
                end
            end
        end
    end

    return bestPos, bestInstance, bestZone
end

-- ══════════════════════════════════════════════════════════════════════
-- [6] INSTANT PROXIMITY PROMPT ENGINE
-- ══════════════════════════════════════════════════════════════════════
local function OptimizePrompt(prompt)
    if prompt:IsA("ProximityPrompt") and Config.Automation.FastPrompt then
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 150
    end
end

for _, descendant in ipairs(Workspace:GetDescendants()) do
    OptimizePrompt(descendant)
end

State.Connections.PromptAdded = Workspace.DescendantAdded:Connect(function(descendant)
    OptimizePrompt(descendant)
end)

-- ══════════════════════════════════════════════════════════════════════
-- [7] AUTOMATION RUNNERS
-- ══════════════════════════════════════════════════════════════════════

-- Runner: Auto Steal Engine
task.spawn(function()
    while true do
        task.wait(Config.Automation.StealLoopDelay)

        if Config.Automation.AutoSteal and Core.HasActiveZone() and not State.Flags.IsStealing then
            local character = LocalPlayer.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")

            if rootPart then
                local targetPos, targetInstance, targetZone = Core.FindNearestTarget()

                if targetPos and targetZone and targetInstance and targetInstance.Parent then
                    State.Flags.IsStealing = true
                    State.Stats.LastTargetZone = targetZone
                    State.Stats.StealAttempts = State.Stats.StealAttempts + 1

                    -- Fase 1: Teleport ke target
                    rootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 4, 0))
                    task.wait(Config.Automation.PostTeleportDelay)

                    -- Fase 2: Aktivasi ProximityPrompt terdekat (< 25 studs)
                    for _, prompt in ipairs(Workspace:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") then
                            local promptOwner = prompt.Parent
                            local promptPos = promptOwner and (
                                promptOwner:IsA("Model") and promptOwner:GetPivot().Position
                                or promptOwner:IsA("BasePart") and promptOwner.Position
                            )

                            if promptPos and (promptPos - rootPart.Position).Magnitude < 25 then
                                pcall(function()
                                    prompt.HoldDuration = 0
                                    if fireproximityprompt then
                                        fireproximityprompt(prompt)
                                    end
                                end)
                            end
                        end
                    end

                    -- Fase 3: Simulasi tombol E
                    pcall(function()
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    end)

                    -- Fase 4: Touch Interest
                    pcall(function()
                        if targetInstance:IsA("Model") then
                            for _, part in ipairs(targetInstance:GetDescendants()) do
                                if part:IsA("BasePart") and firetouchinterest then
                                    firetouchinterest(rootPart, part, 0)
                                    task.wait(0.01)
                                    firetouchinterest(rootPart, part, 1)
                                end
                            end
                        elseif targetInstance:IsA("BasePart") and firetouchinterest then
                            firetouchinterest(rootPart, targetInstance, 0)
                            task.wait(0.01)
                            firetouchinterest(rootPart, targetInstance, 1)
                        end
                    end)

                    task.wait(Config.Automation.TouchDelay)

                    -- Fase 5: Invoke Remo stealEgg
                    if RemoContainer and RemoContainer:FindFirstChild("game.nests.stealEgg") then
                        pcall(function()
                            RemoContainer["game.nests.stealEgg"]:InvokeServer(targetZone, targetPos, targetInstance)
                        end)
                    end

                    task.wait(Config.Automation.PostInvokeDelay)

                    -- Fase 6: Simulasi tombol 1
                    pcall(function()
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
                    end)

                    task.wait(Config.Automation.ReturnDelay)

                    -- Fase 7: Teleport pulang ke Base
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(BasePosition)
                    end

                    task.wait(Config.Automation.PostCycleDelay)
                    State.Flags.IsStealing = false
                else
                    task.wait(0.5)
                end
            end
        end
    end
end)

-- Runner: Auto Sell All Items
task.spawn(function()
    while true do
        task.wait(Config.Automation.SellInterval)
        if Config.Automation.AutoSellAll and RemoContainer and RemoContainer:FindFirstChild("data.backpack.sellAllItems") then
            pcall(function()
                RemoContainer["data.backpack.sellAllItems"]:FireServer()
                State.Stats.TotalSells = State.Stats.TotalSells + 1
            end)
        end
    end
end)

-- Runner: Auto Collect All Base Eggs
task.spawn(function()
    while true do
        task.wait(Config.Automation.CollectInterval)
        if Config.Automation.AutoCollectAll and RemoContainer and RemoContainer:FindFirstChild("data.base.claimAllEggs") then
            pcall(function()
                RemoContainer["data.base.claimAllEggs"]:FireServer()
                State.Stats.TotalClaims = State.Stats.TotalClaims + 1
            end)
        end
    end
end)

-- Runner: Auto Press 1
task.spawn(function()
    while true do
        task.wait(Config.Automation.PressOneInterval)
        if Config.Automation.AutoPressOne then
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
            end)
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- [8] LOW FPS / PERFORMANCE OPTIMIZER ENGINE
-- ══════════════════════════════════════════════════════════════════════
local function ApplyPerformanceBoost()
    Lighting.GlobalShadows = false
    Lighting.Brightness = 0
    Lighting.FogEnd = 9000000000
    Lighting.Technology = Enum.Technology.Compatibility

    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            effect.Enabled = false
        end
    end

    pcall(function()
        Workspace.Terrain.WaterWaveSize = 0
        Workspace.Terrain.WaterTransparency = 1
        Workspace.Terrain.WaterReflectance = 0
        Workspace.Terrain.Decoration = false
    end)

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            obj.CastShadow = false
            obj.Color = Color3.fromRGB(150, 150, 150)
        elseif obj:IsA("Texture") or obj:IsA("Decal") or obj:IsA("SpecialMesh") then
            obj:Destroy()
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Fire")
            or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Beam") then
            obj:Destroy()
        elseif obj:IsA("MeshPart") then
            obj.RenderFidelity = Enum.RenderFidelity.Performance
            obj.CastShadow = false
            obj.Material = Enum.Material.SmoothPlastic
        elseif obj:IsA("Explosion") then
            obj.Visible = false
        end
    end

    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    
    State.Flags.OptimizedFPS = true
end

-- ══════════════════════════════════════════════════════════════════════
-- [9] UNIVERSAL FEATURES ENGINE
-- ══════════════════════════════════════════════════════════════════════

-- Loop: WalkSpeed & JumpPower Override
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

-- Listener: Infinite Jump
State.Connections.InfJump = UserInputService.JumpRequest:Connect(function()
    if Config.Universal.InfiniteJump then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Listener: NoClip
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

-- Listener: Anti-Fling
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

-- Anti-AFK
State.Connections.IdledConn = LocalPlayer.Idled:Connect(function()
    if Config.Universal.AntiAfk then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end
end)

local function ServerHop()
    if Rayfield then
        Rayfield:Notify({ title = "Server Hop", content = "Mencari server publik lain...", duration = 3 })
    end
    local servers = {}
    local req = request or http_request or (syn and syn.request)
    if req then
        pcall(function()
            local res = req({ Url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId) })
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
-- [10] USER INTERFACE CONSTRUCTION (RAYFIELD GEN2)
-- ══════════════════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    name = "Mizukage Official 👑",
    subtitle = "Remo Automation Suite • Gen2 Edition",
    sidebarLayout = true
})

-- TAB 1: DASHBOARD
local TabDashboard = Window:CreateTab({ name = "Dashboard" })

TabDashboard:CreateText({
    name = "Status Sistem",
    content = RemoContainer and "Remote Container terdeteksi: Sistem siap beroperasi." or "Peringatan: Remo Container tidak ditemukan!"
})

TabDashboard:CreateDivider()

local StealStatLabel = TabDashboard:CreateText({
    name = "Percobaan Steal",
    content = "0 Kali"
})

local ZoneStatLabel = TabDashboard:CreateText({
    name = "Zona Terakhir",
    content = "None"
})

local SellsStatLabel = TabDashboard:CreateText({
    name = "Total Sell All",
    content = "0 Kali"
})

local ClaimsStatLabel = TabDashboard:CreateText({
    name = "Total Claim All",
    content = "0 Kali"
})

local UptimeStatLabel = TabDashboard:CreateText({
    name = "Waktu Aktif",
    content = "00:00"
})

TabDashboard:CreateButton({
    name = "Perbarui Statistik",
    callback = function()
        pcall(function()
            StealStatLabel:Set({ name = "Percobaan Steal", content = string.format("%d Kali", State.Stats.StealAttempts) })
            ZoneStatLabel:Set({ name = "Zona Terakhir", content = State.Stats.LastTargetZone })
            SellsStatLabel:Set({ name = "Total Sell All", content = string.format("%d Kali", State.Stats.TotalSells) })
            ClaimsStatLabel:Set({ name = "Total Claim All", content = string.format("%d Kali", State.Stats.TotalClaims) })
            UptimeStatLabel:Set({ name = "Waktu Aktif", content = Core.FormatTime(os.time() - State.Stats.StartTime) })
        end)
    end
})

-- TAB 2: AUTOMATION
local TabAuto = Window:CreateTab({ name = "Otomasi Utama" })

TabAuto:CreateToggle({
    name = "Auto Steal Egg",
    currentValue = Config.Automation.AutoSteal,
    flag = "Mzk_AutoSteal",
    callback = function(val)
        Config.Automation.AutoSteal = val
        if val and not Core.HasActiveZone() and Rayfield then
            Rayfield:Notify({
                title = "Pemberitahuan Zona",
                content = "Harap aktifkan minimal 1 zona di Tab Zona agar Auto Steal dapat menemukan target.",
                duration = 5
            })
        end
    end
})

TabAuto:CreateToggle({
    name = "Auto Sell All Items (Backpack)",
    currentValue = Config.Automation.AutoSellAll,
    flag = "Mzk_AutoSell",
    callback = function(val)
        Config.Automation.AutoSellAll = val
    end
})

TabAuto:CreateToggle({
    name = "Auto Collect All Eggs (Base)",
    currentValue = Config.Automation.AutoCollectAll,
    flag = "Mzk_AutoCollect",
    callback = function(val)
        Config.Automation.AutoCollectAll = val
    end
})

TabAuto:CreateToggle({
    name = "Auto Press 1 (Slot 1)",
    currentValue = Config.Automation.AutoPressOne,
    flag = "Mzk_AutoPressOne",
    callback = function(val)
        Config.Automation.AutoPressOne = val
    end
})

TabAuto:CreateToggle({
    name = "Fast Proximity Prompt (Instant E)",
    currentValue = Config.Automation.FastPrompt,
    flag = "Mzk_FastPrompt",
    callback = function(val)
        Config.Automation.FastPrompt = val
    end
})

TabAuto:CreateDivider()

TabAuto:CreateButton({
    name = "Manual Sell All Items Sekarang",
    callback = function()
        if RemoContainer and RemoContainer:FindFirstChild("data.backpack.sellAllItems") then
            pcall(function() RemoContainer["data.backpack.sellAllItems"]:FireServer() end)
            if Rayfield then Rayfield:Notify({ title = "Sell All", content = "Permintaan jual semua berhasil dikirim.", duration = 3 }) end
        end
    end
})

TabAuto:CreateButton({
    name = "Manual Collect All Eggs Sekarang",
    callback = function()
        if RemoContainer and RemoContainer:FindFirstChild("data.base.claimAllEggs") then
            pcall(function() RemoContainer["data.base.claimAllEggs"]:FireServer() end)
            if Rayfield then Rayfield:Notify({ title = "Claim All", content = "Permintaan claim semua berhasil dikirim.", duration = 3 }) end
        end
    end
})

-- TAB 3: TIMING & DELAYS
local TabTiming = Window:CreateTab({ name = "Pengaturan Delay" })

TabTiming:CreateSlider({
    name = "Interval Loop Steal (Detik)",
    range = {0.1, 1.5},
    increment = 0.05,
    currentValue = Config.Automation.StealLoopDelay,
    flag = "Mzk_StealDelay",
    callback = function(val) Config.Automation.StealLoopDelay = val end
})

TabTiming:CreateSlider({
    name = "Jeda Pasca Teleport ke Target (Detik)",
    range = {0.05, 0.6},
    increment = 0.05,
    currentValue = Config.Automation.PostTeleportDelay,
    flag = "Mzk_TeleportDelay",
    callback = function(val) Config.Automation.PostTeleportDelay = val end
})

TabTiming:CreateSlider({
    name = "Jeda Touch Interest (Detik)",
    range = {0.05, 0.5},
    increment = 0.05,
    currentValue = Config.Automation.TouchDelay,
    flag = "Mzk_TouchDelay",
    callback = function(val) Config.Automation.TouchDelay = val end
})

TabTiming:CreateSlider({
    name = "Jeda Pasca Invoke stealEgg (Detik)",
    range = {0.05, 0.4},
    increment = 0.05,
    currentValue = Config.Automation.PostInvokeDelay,
    flag = "Mzk_InvokeDelay",
    callback = function(val) Config.Automation.PostInvokeDelay = val end
})

TabTiming:CreateSlider({
    name = "Jeda Teleport Kembali ke Base (Detik)",
    range = {0.1, 0.8},
    increment = 0.05,
    currentValue = Config.Automation.ReturnDelay,
    flag = "Mzk_ReturnDelay",
    callback = function(val) Config.Automation.ReturnDelay = val end
})

TabTiming:CreateSlider({
    name = "Jeda Selesai Siklus Steal (Detik)",
    range = {0.2, 2.0},
    increment = 0.1,
    currentValue = Config.Automation.PostCycleDelay,
    flag = "Mzk_CycleDelay",
    callback = function(val) Config.Automation.PostCycleDelay = val end
})

TabTiming:CreateDivider()

TabTiming:CreateSlider({
    name = "Interval Auto Sell (Detik)",
    range = {1.0, 10.0},
    increment = 0.5,
    currentValue = Config.Automation.SellInterval,
    flag = "Mzk_SellInterval",
    callback = function(val) Config.Automation.SellInterval = val end
})

TabTiming:CreateSlider({
    name = "Interval Auto Collect (Detik)",
    range = {1.0, 10.0},
    increment = 0.5,
    currentValue = Config.Automation.CollectInterval,
    flag = "Mzk_CollectInterval",
    callback = function(val) Config.Automation.CollectInterval = val end
})

TabTiming:CreateSlider({
    name = "Interval Auto Press 1 (Detik)",
    range = {0.5, 5.0},
    increment = 0.25,
    currentValue = Config.Automation.PressOneInterval,
    flag = "Mzk_PressOneInterval",
    callback = function(val) Config.Automation.PressOneInterval = val end
})

-- TAB 4: ZONES SELECTION
local TabZones = Window:CreateTab({ name = "Pilihan Zona" })

local ZoneToggleReferences = {}

TabZones:CreateButton({
    name = "PILIH SEMUA ZONA",
    callback = function()
        for zoneName, _ in pairs(Config.Zones) do
            Config.Zones[zoneName] = true
            if ZoneToggleReferences[zoneName] then
                pcall(function() ZoneToggleReferences[zoneName]:Set(true) end)
            end
        end
    end
})

TabZones:CreateButton({
    name = "HAPUS SEMUA PILIHAN ZONA",
    callback = function()
        for zoneName, _ in pairs(Config.Zones) do
            Config.Zones[zoneName] = false
            if ZoneToggleReferences[zoneName] then
                pcall(function() ZoneToggleReferences[zoneName]:Set(false) end)
            end
        end
    end
})

TabZones:CreateDivider()

local zoneOrder = {
    "Forest", "Lake", "Jungle", "Desert", "Snow", "Volcano", "Beach", 
    "Abyss", "Cosmic", "Crystal", "Candy", "Alien", "Magma", "BlueLava"
}

for _, zoneName in ipairs(zoneOrder) do
    local bounds = ZoneBounds[zoneName]
    local label = string.format("%s (X: %d - %d)", zoneName, bounds.minX, bounds.maxX)
    
    ZoneToggleReferences[zoneName] = TabZones:CreateToggle({
        name = label,
        currentValue = Config.Zones[zoneName],
        flag = "Mzk_Zone_" .. zoneName,
        callback = function(val)
            Config.Zones[zoneName] = val
        end
    })
end

-- TAB 5: UNIVERSAL PLAYER
local TabPlayer = Window:CreateTab({ name = "Universal Karakter" })

TabPlayer:CreateToggle({
    name = "Kustom WalkSpeed",
    currentValue = Config.Universal.WalkSpeedEnabled,
    flag = "Mzk_WS_Toggle",
    callback = function(val) Config.Universal.WalkSpeedEnabled = val end
})

TabPlayer:CreateSlider({
    name = "WalkSpeed",
    range = {16, 250},
    increment = 1,
    currentValue = Config.Universal.WalkSpeed,
    flag = "Mzk_WS_Val",
    callback = function(val) Config.Universal.WalkSpeed = val end
})

TabPlayer:CreateDivider()

TabPlayer:CreateToggle({
    name = "Kustom JumpPower",
    currentValue = Config.Universal.JumpPowerEnabled,
    flag = "Mzk_JP_Toggle",
    callback = function(val) Config.Universal.JumpPowerEnabled = val end
})

TabPlayer:CreateSlider({
    name = "JumpPower",
    range = {50, 300},
    increment = 1,
    currentValue = Config.Universal.JumpPower,
    flag = "Mzk_JP_Val",
    callback = function(val) Config.Universal.JumpPower = val end
})

TabPlayer:CreateDivider()

TabPlayer:CreateToggle({
    name = "Infinite Jump (Lompat Tanpa Batas)",
    currentValue = Config.Universal.InfiniteJump,
    flag = "Mzk_InfJump",
    callback = function(val) Config.Universal.InfiniteJump = val end
})

-- TAB 6: UNIVERSAL WORLD & PERFORMANCE
local TabWorld = Window:CreateTab({ name = "Dunia & Performa" })

TabWorld:CreateToggle({
    name = "No-Clip (Tembus Tembok)",
    currentValue = Config.Universal.NoClip,
    flag = "Mzk_NoClip",
    callback = function(val) Config.Universal.NoClip = val end
})

TabWorld:CreateToggle({
    name = "Anti-Fling (Tembus Pemain Lain)",
    currentValue = Config.Universal.AntiFling,
    flag = "Mzk_AntiFling",
    callback = function(val) Config.Universal.AntiFling = val end
})

TabWorld:CreateSlider({
    name = "Gravitasi Dunia",
    range = {0, 196},
    increment = 1,
    currentValue = Config.Universal.Gravity,
    flag = "Mzk_Gravity",
    callback = function(val)
        Config.Universal.Gravity = val
        Workspace.Gravity = val
    end
})

TabWorld:CreateDivider()

TabWorld:CreateButton({
    name = "OPTIMASI LOW FPS (BOOST PERFORMA)",
    callback = function()
        ApplyPerformanceBoost()
        if Rayfield then
            Rayfield:Notify({
                title = "Performa",
                content = "Optimasi grafis & material telah diterapkan secara menyeluruh.",
                duration = 4
            })
        end
    end
})

TabWorld:CreateButton({
    name = "Pindah Server (Server Hop)",
    callback = ServerHop
})

TabWorld:CreateButton({
    name = "Rejoin Server Ini",
    callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

-- TAB 7: SISTEM & CLEANUP
local TabSystem = Window:CreateTab({ name = "Sistem & Kontrol" })

TabSystem:CreateToggle({
    name = "Anti-AFK (20 Menit Idle Protection)",
    currentValue = Config.Universal.AntiAfk,
    flag = "Mzk_AntiAfk",
    callback = function(val) Config.Universal.AntiAfk = val end
})

TabSystem:CreateDivider()

TabSystem:CreateButton({
    name = "Matikan Total Script (Unload & Cleanup)",
    callback = function()
        -- 1. Matikan semua flag otomasi
        Config.Automation.AutoSteal = false
        Config.Automation.AutoSellAll = false
        Config.Automation.AutoCollectAll = false
        Config.Automation.AutoPressOne = false
        Config.Automation.FastPrompt = false
        
        -- 2. Matikan override universal
        Config.Universal.WalkSpeedEnabled = false
        Config.Universal.JumpPowerEnabled = false
        Config.Universal.InfiniteJump = false
        Config.Universal.NoClip = false
        Config.Universal.AntiFling = false
        Workspace.Gravity = 196.2
        
        -- 3. Reset Humanoid
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end

        -- 4. Disconnect seluruh RBXScriptConnection
        for name, conn in pairs(State.Connections) do
            if conn then
                conn:Disconnect()
                State.Connections[name] = nil
            end
        end

        if Rayfield then
            Rayfield:Notify({
                title = "Mizukage Official 👑",
                content = "Script berhasil dimatikan total. Seluruh koneksi memori telah dibersihkan.",
                duration = 4
            })
        end
    end
})

-- ══════════════════════════════════════════════════════════════════════
-- [11] INITIAL NOTIFICATION
-- ══════════════════════════════════════════════════════════════════════
pcall(function()
    Rayfield:Notify({
        title = "Mizukage Official 👑",
        content = "Suite Otomasi Remo Gen2 berhasil dimuat!",
        duration = 5
    })
end)