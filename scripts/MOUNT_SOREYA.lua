--[[
    ╔══════════════════════════════════════════════════════════╗
    ║                 MIZUKAGE OFFICIAL 👑                     ║
    ║        MOUNT SOREYA (UPD PET) — VIP ELITE SUITE          ║
    ║             Rayfield Gen2 Native Execution               ║
    ╚══════════════════════════════════════════════════════════╝
    Place ID        : 118517641508250
    Framework       : Rayfield Gen2 Native Architecture
    Specialty       : Zero-Delay Mobile Tap-Tap & VIP Suite
--]]

-- ═══ 1. SERVICES & INITIALIZATION ═══
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local StatsService = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- ═══ 2. LOAD RAYFIELD GEN2 ═══
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()
if not Rayfield then return end

-- ═══ 3. CONFIGURATION & STATE ═══
local Config = {
    General = {
        AntiAFK = true,
        FPSBoost = false,
    },
    Features = {
        AutoFish = {
            Enabled = false,
            CastPower = 95,
            CastDelay = 1.0,
            AutoTapTap = true,
            NoDelayTap = true,
            BurstMultiplier = 6,
            InstantReel = false,
        },
        AutoSell = {
            Enabled = false,
            Interval = 15,
        },
        CheckpointStepper = {
            Enabled = false,
            StepDelay = 1.0,
        },
        Movement = {
            WalkSpeed = 16,
            JumpPower = 50,
            InfJump = false,
            Noclip = false,
        },
        SelectedRod = "Withering Rod",
    }
}

local State = {
    Connections = {},
    Threads = {},
    LastCast = 0,
    IsMinigameActive = false,
    Checkpoints = {},
    TotalFishCaught = 0,
    TotalCoinsEarned = 0,
    SessionStartTime = os.time(),
}

-- ═══ 4. REMOTES RESOLUTION ═══
local Remotes = {
    KoinShop_Beli = nil,
    KoinShop_AmbilData = nil,
    Mancing_JualSemua = nil,
    Mancing_InfoJual = nil,
    Spin_BeliKoin = nil,
    Spin_Keadaan = nil,
    CekKomunitas = nil,
    CheckpointReached = nil,
}

local function ResolveRemotes()
    local remFolder = ReplicatedStorage:FindFirstChild("Remote")
    if remFolder then
        local koinShop = remFolder:FindFirstChild("KoinShop")
        if koinShop then
            Remotes.KoinShop_Beli = koinShop:FindFirstChild("Beli")
            Remotes.KoinShop_AmbilData = koinShop:FindFirstChild("AmbilData")
        end
        local mancing = remFolder:FindFirstChild("Mancing")
        if mancing then
            Remotes.Mancing_JualSemua = mancing:FindFirstChild("JualSemua")
            Remotes.Mancing_InfoJual = mancing:FindFirstChild("InfoJual")
        end
        local spin = remFolder:FindFirstChild("Spin")
        if spin then
            Remotes.Spin_BeliKoin = spin:FindFirstChild("BeliKoin")
            Remotes.Spin_Keadaan = spin:FindFirstChild("Keadaan")
        end
        local sistem = remFolder:FindFirstChild("Sistem")
        if sistem then
            Remotes.CekKomunitas = sistem:FindFirstChild("CekKomunitas")
        end
        local cp = remFolder:FindFirstChild("Checkpoint")
        if cp then
            Remotes.CheckpointReached = cp:FindFirstChild("CheckpointReached")
        end
    end
end

ResolveRemotes()

-- ═══ 5. CORE UTILITIES ═══
local function GetCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function GetRoot()
    local char = GetCharacter()
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:WaitForChild("HumanoidRootPart", 5)
end

local function GetHumanoid()
    local char = GetCharacter()
    return char:FindFirstChildOfClass("Humanoid")
end

local function SafeNotify(title, content, duration)
    pcall(function()
        Rayfield:Notify({
            title = title,
            content = content,
            duration = duration or 3.5,
        })
    end)
end

local function GetCurrentRod()
    local char = LocalPlayer.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and item:FindFirstChild("Mechanics") then
                return item
            end
        end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") and item:FindFirstChild("Mechanics") then
                return item
            end
        end
    end
    return nil
end

local function CountBackpackFish()
    local count = 0
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") and item:GetAttribute("Weight") then
                count = count + 1
            end
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and item:GetAttribute("Weight") then
                count = count + 1
            end
        end
    end
    return count
end

-- ═══ 6. ZERO-DELAY MOBILE AUTO TAP-TAP ENGINE ═══
local MiniGameModule = nil
pcall(function()
    MiniGameModule = require(ReplicatedStorage.Modules.Fishing.MiniGameHandler)
end)

local function TriggerSingleTap()
    if MiniGameModule and type(MiniGameModule.MobileTap) == "function" then
        pcall(MiniGameModule.MobileTap)
        return
    end
    pcall(function()
        VirtualUser:Button1Down(Vector2.new(0, 0))
        VirtualUser:Button1Up(Vector2.new(0, 0))
    end)
end

local function FireZeroDelayTapBurst()
    local burst = Config.Features.AutoFish.BurstMultiplier or 6
    for _ = 1, burst do
        TriggerSingleTap()
    end
end

local function HookRodMinigame(tool)
    if not tool then return end
    local mechanics = tool:FindFirstChild("Mechanics")
    if not mechanics then return end
    local remotes = mechanics:FindFirstChild("Remotes")
    if not remotes then return end

    local miniGameRemote = remotes:FindFirstChild("MiniGame")
    if miniGameRemote and not State.Connections["MiniGameHook_" .. tool.Name] then
        State.Connections["MiniGameHook_" .. tool.Name] = miniGameRemote.OnClientEvent:Connect(function(action, data)
            if action == "Start" then
                State.IsMinigameActive = true
                if Config.Features.AutoFish.InstantReel then
                    task.wait(0.05)
                    miniGameRemote:FireServer(true)
                    return
                end
                if Config.Features.AutoFish.AutoTapTap then
                    if State.Threads["AutoTapThread"] then
                        task.cancel(State.Threads["AutoTapThread"])
                    end
                    State.Threads["AutoTapThread"] = task.spawn(function()
                        while State.IsMinigameActive and Config.Features.AutoFish.AutoTapTap do
                            if Config.Features.AutoFish.NoDelayTap then
                                FireZeroDelayTapBurst()
                                task.wait()
                            else
                                TriggerSingleTap()
                                task.wait(0.04)
                            end
                        end
                    end)
                end
            elseif action == "Stop" then
                State.IsMinigameActive = false
                if State.Threads["AutoTapThread"] then
                    task.cancel(State.Threads["AutoTapThread"])
                    State.Threads["AutoTapThread"] = nil
                end
            end
        end)
    end

    local notifyClient = remotes:FindFirstChild("NotifyClient")
    if notifyClient and not State.Connections["NotifyHook_" .. tool.Name] then
        State.Connections["NotifyHook_" .. tool.Name] = notifyClient.OnClientEvent:Connect(function(action, payload)
            if action == "GotFish" and payload then
                State.TotalFishCaught = State.TotalFishCaught + 1
                SafeNotify("Ikan Tertangkap! 🐟", tostring(payload.originalName or payload.baseName or "Ikan") .. " (" .. tostring(payload.rarity or "Common") .. ")", 3)
            end
        end)
    end
end

-- ═══ 7. CAST & FISHING AUTOMATION ═══
local function ExecuteCast()
    local rod = GetCurrentRod()
    if not rod then return end
    local char = LocalPlayer.Character
    if rod.Parent ~= char then
        local hum = GetHumanoid()
        if hum then hum:EquipTool(rod) end
        task.wait(0.3)
    end
    local mechanics = rod:FindFirstChild("Mechanics")
    if not mechanics then return end
    local remotes = mechanics:FindFirstChild("Remotes")
    if not remotes then return end
    local castEvent = remotes:FindFirstChild("CastEvent")
    if not castEvent then return end
    HookRodMinigame(rod)
    castEvent:FireServer(true)
    task.wait(0.15)
    castEvent:FireServer(false, Config.Features.AutoFish.CastPower, nil)
    State.LastCast = tick()
end

-- ═══ 8. CHECKPOINT SCANNER ═══
local function ScanCheckpoints()
    table.clear(State.Checkpoints)
    local list = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local num = string.match(obj.Name, "^CP(%d+)$") or string.match(obj.Name, "^Checkpoint(%d+)$") or string.match(obj.Name, "^Stage(%d+)$")
            if num then
                table.insert(list, { Index = tonumber(num), Part = obj })
            end
        end
    end
    table.sort(list, function(a, b) return a.Index < b.Index end)
    State.Checkpoints = list
    return #list
end

ScanCheckpoints()

-- ═══ 9. ANTI-AFK KEEP ALIVE ═══
State.Connections["Idled"] = LocalPlayer.Idled:Connect(function()
    if Config.General.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end
end)

-- ═══════════════════════════════════════════════════════════
-- ═══ 10. 🎨 ICON PACK — ASSET ID DASHBOARD MODERN ═══
-- ═══════════════════════════════════════════════════════════
local Icons = {
    -- TAB ICONS (Modern & Rapi)
    Dashboard  = "rbxassetid://10734883584",  -- 🏠 Home/Dashboard
    Fishing    = "rbxassetid://10709770563",  -- 🎣 Fishing Rod/Fish
    Shop       = "rbxassetid://10734950309",  -- 🛒 Shopping Cart
    Obby       = "rbxassetid://10734940376",  -- 🚩 Flag/Progression
    Movement   = "rbxassetid://10734924532",  -- 👟 Footprints
    
    -- SECTION / NOTIF ICONS (Bonus)
    Crown      = "rbxassetid://10723344577",  -- 👑 Crown VIP
    Sparkle    = "rbxassetid://10734949238",  -- ✨ Magic
    Fire       = "rbxassetid://10734945126",  -- 🔥 Fire
    Money      = "rbxassetid://10734957161",  -- 💰 Coins
    Star       = "rbxassetid://10734957364",  -- ⭐ Star
    Bolt       = "rbxassetid://10734880196",  -- ⚡ Lightning
    Shield     = "rbxassetid://10734882702",  -- 🛡️ Shield
    Gear       = "rbxassetid://10734881552",  -- ⚙️ Settings Gear
    Fish       = "rbxassetid://10709770563",  -- 🐟 Fish
    Bag        = "rbxassetid://10734902147",  -- 🎒 Backpack
    Rocket     = "rbxassetid://10734945656",  -- 🚀 Speed Boost
    Map        = "rbxassetid://10734940760",  -- 🗺️ Map/Checkpoint
}

-- ═══ 11. RAYFIELD GEN2 UI BUILDER ═══
local Window = Rayfield:CreateWindow({
    name = "MIZUKAGE OFFICIAL 👑",
    subtitle = "Mount Soreya",
    sidebarLayout = true,
})

-- ─── TAB 1: VIP COMMAND DASHBOARD ───
local DashTab = Window:CreateTab({
    name = "Dashboard",
    icon = Icons.Dashboard
})

DashTab:CreateSection({ name = "👑 MIZUKAGE VIP CENTER" })

DashTab:CreateButton({
    name = "User: " .. LocalPlayer.Name .. " (" .. LocalPlayer.DisplayName .. ")",
    callback = function() end
})

DashTab:CreateButton({
    name = "Target Game: MOUNT SOREYA",
    callback = function() end
})

DashTab:CreateButton({
    name = "Engine: Rayfield Gen2 — Zero-Delay Mobile Native",
    callback = function() end
})

DashTab:CreateDivider()
DashTab:CreateSection({ name = "QUICK MASTER CONTROLS" })

DashTab:CreateToggle({
    name = "Master Auto Farm (Auto Cast + Tap + Sell)",
    value = false,
    callback = function(val)
        Config.Features.AutoFish.Enabled = val
        Config.Features.AutoFish.AutoTapTap = val
        Config.Features.AutoSell.Enabled = val

        if val then
            if not State.Threads["CastLoop"] then
                State.Threads["CastLoop"] = task.spawn(function()
                    while Config.Features.AutoFish.Enabled do
                        local rod = GetCurrentRod()
                        if rod then
                            ExecuteCast()
                            task.wait(Config.Features.AutoFish.CastDelay)
                        else
                            task.wait(1.2)
                        end
                    end
                end)
            end
            if not State.Threads["SellLoop"] then
                State.Threads["SellLoop"] = task.spawn(function()
                    while Config.Features.AutoSell.Enabled do
                        if not Remotes.Mancing_JualSemua then ResolveRemotes() end
                        if Remotes.Mancing_JualSemua then
                            Remotes.Mancing_JualSemua:InvokeServer()
                        end
                        task.wait(Config.Features.AutoSell.Interval)
                    end
                end)
            end
            SafeNotify("Master Auto Farm", "Semua sistem farming aktif!", 4)
        else
            if State.Threads["CastLoop"] then
                task.cancel(State.Threads["CastLoop"])
                State.Threads["CastLoop"] = nil
            end
            if State.Threads["SellLoop"] then
                task.cancel(State.Threads["SellLoop"])
                State.Threads["SellLoop"] = nil
            end
            SafeNotify("Master Auto Farm", "Seluruh automasi dinonaktifkan.", 3)
        end
    end
})

DashTab:CreateToggle({
    name = "No-Delay Mobile Burst (No Delay Tap)",
    value = Config.Features.AutoFish.NoDelayTap,
    callback = function(val)
        Config.Features.AutoFish.NoDelayTap = val
    end
})

DashTab:CreateToggle({
    name = "Anti-AFK Protection",
    value = Config.General.AntiAFK,
    callback = function(val)
        Config.General.AntiAFK = val
    end
})

DashTab:CreateDivider()
DashTab:CreateSection({ name = "LIVE & 1-TAP ACTIONS" })

DashTab:CreateButton({
    name = "Cek Jumlah Ikan di Tas",
    callback = function()
        local count = CountBackpackFish()
        SafeNotify("Inventaris Ikan", "Total ikan di tas saat ini: " .. tostring(count), 3.5)
    end
})

DashTab:CreateButton({
    name = "Jual Seluruh Ikan Sekarang (1-Tap Sell)",
    callback = function()
        if not Remotes.Mancing_JualSemua then ResolveRemotes() end
        if Remotes.Mancing_JualSemua then
            local res = Remotes.Mancing_JualSemua:InvokeServer()
            if typeof(res) == "table" and res.total then
                SafeNotify("Penjualan Sukses!", "Mendapatkan +" .. tostring(res.total) .. " Koin (" .. tostring(res.jumlah) .. " Ikan)", 4)
            else
                SafeNotify("Penjualan", "Perintah jual berhasil diproses server.", 3)
            end
        else
            SafeNotify("Error", "Remote penjualan tidak ditemukan.", 3)
        end
    end
})

DashTab:CreateButton({
    name = "Klaim Hadiah Komunitas (Free Candy Cane)",
    callback = function()
        if not Remotes.CekKomunitas then ResolveRemotes() end
        if Remotes.CekKomunitas then
            Remotes.CekKomunitas:InvokeServer("cek")
            SafeNotify("Komunitas", "Permintaan klaim skin terkirim ke server!", 3)
        end
    end
})

DashTab:CreateDivider()
DashTab:CreateSection({ name = "FPS BOOSTER & DIAGNOSTIK" })

DashTab:CreateToggle({
    name = "Mobile FPS Booster (Matikan Efek Berat)",
    value = false,
    callback = function(val)
        Config.General.FPSBoost = val
        pcall(function()
            local efkWadah = Workspace:FindFirstChild("EfekMancingWadah")
            if efkWadah then efkWadah:ClearAllChildren() end
            local vfx = Workspace:FindFirstChild("VFX")
            if vfx and val then
                for _, part in ipairs(vfx:GetChildren()) do
                    if part:IsA("ParticleEmitter") or part:IsA("Beam") or part:IsA("Trail") then
                        part.Enabled = false
                    end
                end
            end
        end)
    end
})

-- ─── TAB 2: FISHING & ULTRA TAP ───
local FishTab = Window:CreateTab({
    name = "Fishing Lite",
    icon = Icons.Fishing
})

FishTab:CreateSection({ name = "Sistem Lempar & Auto Tap" })

FishTab:CreateToggle({
    name = "Auto Cast Fishing Rod",
    value = false,
    callback = function(val)
        Config.Features.AutoFish.Enabled = val
        if val then
            State.Threads["CastLoop"] = task.spawn(function()
                while Config.Features.AutoFish.Enabled do
                    local rod = GetCurrentRod()
                    if rod then
                        ExecuteCast()
                        task.wait(Config.Features.AutoFish.CastDelay)
                    else
                        task.wait(1.5)
                    end
                end
            end)
        else
            if State.Threads["CastLoop"] then
                task.cancel(State.Threads["CastLoop"])
                State.Threads["CastLoop"] = nil
            end
        end
    end
})

FishTab:CreateToggle({
    name = "Mobile Auto Tap",
    value = true,
    callback = function(val)
        Config.Features.AutoFish.AutoTapTap = val
    end
})

FishTab:CreateToggle({
    name = "Instant Auto Reel",
    value = false,
    callback = function(val)
        Config.Features.AutoFish.InstantReel = val
    end
})

FishTab:CreateSlider({
    name = "Burst Tap",
    range = {1, 15},
    increment = 1,
    value = 6,
    callback = function(val)
        Config.Features.AutoFish.BurstMultiplier = val
    end
})

FishTab:CreateSlider({
    name = "Cast Power Percentage (%)",
    range = {20, 100},
    increment = 1,
    value = 95,
    callback = function(val)
        Config.Features.AutoFish.CastPower = val
    end
})

FishTab:CreateSlider({
    name = "Cast Delay Loop (Detik)",
    range = {0.6, 5},
    increment = 0.2,
    value = 1.0,
    callback = function(val)
        Config.Features.AutoFish.CastDelay = val
    end
})

FishTab:CreateDivider()
FishTab:CreateSection({ name = "Otomasi Penjualan Ikan" })

FishTab:CreateToggle({
    name = "Auto Sell Fish Loop",
    value = false,
    callback = function(val)
        Config.Features.AutoSell.Enabled = val
        if val then
            State.Threads["SellLoop"] = task.spawn(function()
                while Config.Features.AutoSell.Enabled do
                    if not Remotes.Mancing_JualSemua then ResolveRemotes() end
                    if Remotes.Mancing_JualSemua then
                        Remotes.Mancing_JualSemua:InvokeServer()
                    end
                    task.wait(Config.Features.AutoSell.Interval)
                end
            end)
        else
            if State.Threads["SellLoop"] then
                task.cancel(State.Threads["SellLoop"])
                State.Threads["SellLoop"] = nil
            end
        end
    end
})

FishTab:CreateSlider({
    name = "Auto Sell Interval (Detik)",
    range = {5, 60},
    increment = 5,
    value = 15,
    callback = function(val)
        Config.Features.AutoSell.Interval = val
    end
})

-- ─── TAB 3: SHOP & REWARDS ───
local ShopTab = Window:CreateTab({
    name = "Shop & Rewards",
    icon = Icons.Shop
})

ShopTab:CreateSection({ name = "Beli Joran (KoinShop Remote)" })

local RodList = {
    "Ares Rod",
    "Ghostfinn Rod",
    "Bamboo Rod",
    "Element Rod",
    "Diamond Rod",
    "Withering Rod"
}

ShopTab:CreateDropdown({
    name = "Pilih Joran Target",
    options = RodList,
    value = "Withering Rod",
    callback = function(option)
        local chosen = typeof(option) == "table" and option[1] or option
        Config.Features.SelectedRod = chosen
    end
})

ShopTab:CreateButton({
    name = "Beli Joran Terpilih (KoinShop)",
    callback = function()
        if not Remotes.KoinShop_Beli then ResolveRemotes() end
        if Remotes.KoinShop_Beli and Config.Features.SelectedRod then
            Remotes.KoinShop_Beli:InvokeServer("rod", Config.Features.SelectedRod)
            SafeNotify("Koin Shop", "Membeli " .. tostring(Config.Features.SelectedRod), 3)
        end
    end
})

ShopTab:CreateDivider()
ShopTab:CreateSection({ name = "Roda Spin & Komunitas" })

ShopTab:CreateButton({
    name = "Beli 10x Spin Koin (5,000,000 Koin)",
    callback = function()
        if not Remotes.Spin_BeliKoin then ResolveRemotes() end
        if Remotes.Spin_BeliKoin then
            Remotes.Spin_BeliKoin:InvokeServer(10, "koin")
            SafeNotify("Spin Wheel", "10x Spin Koin telah dibeli!", 3)
        end
    end
})

ShopTab:CreateButton({
    name = "Beli 10x Spin Title (5,000,000 Koin)",
    callback = function()
        if not Remotes.Spin_BeliKoin then ResolveRemotes() end
        if Remotes.Spin_BeliKoin then
            Remotes.Spin_BeliKoin:InvokeServer(10, "title")
            SafeNotify("Spin Wheel", "10x Spin Title telah dibeli!", 3)
        end
    end
})

ShopTab:CreateButton({
    name = "Klaim Skin Gratis Komunitas (Candy Cane)",
    callback = function()
        if not Remotes.CekKomunitas then ResolveRemotes() end
        if Remotes.CekKomunitas then
            Remotes.CekKomunitas:InvokeServer("cek")
            SafeNotify("Komunitas", "Permintaan reward terkirim!", 3)
        end
    end
})

-- ─── TAB 4: OBBY PROGRESSION ───
local ObbyTab = Window:CreateTab({
    name = "Obby Progression",
    icon = Icons.Obby
})

ObbyTab:CreateSection({ name = "Anti-Skip Sequential Stepper" })

ObbyTab:CreateButton({
    name = "Pindai / Refresh Checkpoints Map",
    callback = function()
        local count = ScanCheckpoints()
        SafeNotify("Checkpoint Scanner", "Ditemukan " .. tostring(count) .. " pos berurutan.", 3)
    end
})

ObbyTab:CreateToggle({
    name = "Sequential Checkpoint Auto-Stepper",
    value = false,
    callback = function(val)
        Config.Features.CheckpointStepper.Enabled = val
        if val then
            State.Threads["StepperLoop"] = task.spawn(function()
                if #State.Checkpoints == 0 then ScanCheckpoints() end
                for i = 1, #State.Checkpoints do
                    if not Config.Features.CheckpointStepper.Enabled then break end
                    local cp = State.Checkpoints[i]
                    local root = GetRoot()
                    if root and cp.Part then
                        root.CFrame = cp.Part.CFrame + Vector3.new(0, 3, 0)
                        task.wait(Config.Features.CheckpointStepper.StepDelay)
                    end
                end
                Config.Features.CheckpointStepper.Enabled = false
                SafeNotify("Obby Selesai", "Semua checkpoint telah disinkronkan!", 4)
            end)
        else
            if State.Threads["StepperLoop"] then
                task.cancel(State.Threads["StepperLoop"])
                State.Threads["StepperLoop"] = nil
            end
        end
    end
})

ObbyTab:CreateSlider({
    name = "Step Interval Delay (Detik)",
    range = {0.4, 3},
    increment = 0.1,
    value = 1.0,
    callback = function(val)
        Config.Features.CheckpointStepper.StepDelay = val
    end
})

-- ─── TAB 5: MOVEMENT SUITE ───
local MoveTab = Window:CreateTab({
    name = "Movement",
    icon = Icons.Movement
})

MoveTab:CreateSection({ name = "Statistik Karakter" })

MoveTab:CreateSlider({
    name = "WalkSpeed",
    range = {16, 120},
    increment = 1,
    value = 16,
    callback = function(val)
        Config.Features.Movement.WalkSpeed = val
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = val end
    end
})

MoveTab:CreateSlider({
    name = "JumpPower",
    range = {50, 250},
    increment = 5,
    value = 50,
    callback = function(val)
        Config.Features.Movement.JumpPower = val
        local hum = GetHumanoid()
        if hum then hum.JumpPower = val end
    end
})

MoveTab:CreateToggle({
    name = "Infinite Jump",
    value = false,
    callback = function(val)
        Config.Features.Movement.InfJump = val
        if val and not State.Connections["InfJump"] then
            State.Connections["InfJump"] = UserInputService.JumpRequest:Connect(function()
                if Config.Features.Movement.InfJump then
                    local hum = GetHumanoid()
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end
            end)
        elseif not val and State.Connections["InfJump"] then
            State.Connections["InfJump"]:Disconnect()
            State.Connections["InfJump"] = nil
        end
    end
})

MoveTab:CreateToggle({
    name = "Noclip",
    value = false,
    callback = function(val)
        Config.Features.Movement.Noclip = val
        if val and not State.Connections["Noclip"] then
            State.Connections["Noclip"] = RunService.Stepped:Connect(function()
                if Config.Features.Movement.Noclip then
                    local char = LocalPlayer.Character
                    if char then
                        for _, part in ipairs(char:GetDescendants()) do
                            if part:IsA("BasePart") and part.CanCollide then
                                part.CanCollide = false
                            end
                        end
                    end
                end
            end)
        elseif not val and State.Connections["Noclip"] then
            State.Connections["Noclip"]:Disconnect()
            State.Connections["Noclip"] = nil
        end
    end
})

State.Connections["CharAdded"] = LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        task.wait(0.2)
        hum.WalkSpeed = Config.Features.Movement.WalkSpeed
        hum.JumpPower = Config.Features.Movement.JumpPower
    end
end)

SafeNotify("MIZUKAGE OFFICIAL 👑", "VIP berhasil dimuat sempurna!", 4)