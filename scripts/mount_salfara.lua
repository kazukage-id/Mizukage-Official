--[[
    ╔══════════════════════════════════════════════════════════╗
    ║                                                          ║
    ║          S A L F A R A   P R E M I U M                   ║
    ║          --------------------------                      ║
    ║          VIP EDITION  |  v1.0                            ║
    ║                                                          ║
    ║          Working Coordinates from Cobalt Dump            ║
    ║          Place ID: 93938699582360                        ║
    ║                                                          ║
    ╚══════════════════════════════════════════════════════════╝
--]]

-- ================================================================
-- LOADER
-- ================================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ================================================================
-- SERVICES
-- ================================================================
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")
local VirtualUser       = game:GetService("VirtualUser")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")
local StarterGui        = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid    = Character:WaitForChild("Humanoid")
local RootPart    = Character:WaitForChild("HumanoidRootPart")

-- ================================================================
-- REMOTES
-- ================================================================
local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")

local CastReplication       = FishingSystem:WaitForChild("CastReplication")
local CleanupCast           = FishingSystem:WaitForChild("CleanupCast")
local GetFishModel          = FishingSystem:WaitForChild("GetFishModel")
local FishGiver             = FishingSystem:WaitForChild("FishGiver")
local GetFishTexture        = FishingSystem:FindFirstChild("GetFishTexture")
local FishingCatchSuccess   = ReplicatedStorage:WaitForChild("FishingCatchSuccess")
local SendChatMessage       = FishingSystem:FindFirstChild("SendChatMessage")
local ShowNotification      = FishingSystem:FindFirstChild("ShowNotification")

local InventoryEvents       = FishingSystem:FindFirstChild("InventoryEvents")
local Inventory_GetData     = InventoryEvents and InventoryEvents:FindFirstChild("Inventory_GetData")
local Inventory_GetPetData  = InventoryEvents and InventoryEvents:FindFirstChild("Inventory_GetPetData")
local Inventory_GetJackpot  = InventoryEvents and InventoryEvents:FindFirstChild("Inventory_GetJackpotData")
local Inventory_SellAll     = InventoryEvents and InventoryEvents:FindFirstChild("Inventory_SellAll")

-- ================================================================
-- EXACT COORDINATES (WORKING — DARI COBALT DUMP)
-- ================================================================
local COORD = {
    HOOK_POS  = Vector3.new(-18.09935188293457, 2225.06298828125, -23729.712890625),
    CAST_DIR  = Vector3.new(-25.000003814697266, 5, 2.9802322387695312e-06),
    GIVER_POS = Vector3.new(-29.307188034057617, 2212.000244140625, -23729.712890625),
}

-- ================================================================
-- STATE
-- ================================================================
local State = {
    -- Configuration
    RodName      = "Withering",
    CastPower    = 94,
    FishName     = "MAXTON Super Harta Karun Mount Salfara 100 JUTA KOIN",
    FishRarity   = "Secret",
    FishWeight   = 1600000,

    -- Toggles
    AutoGive     = false,
    AutoGiveDelay = 1,
    AutoSell     = false,
    AutoSellDelay = 3,
    AutoFish     = false,
    AutoFishDelay = 2,

    -- Player
    SpeedEnabled = false,
    SpeedValue   = 35,
    JumpEnabled  = false,
    JumpValue    = 100,
    Noclip       = false,
    InfiniteJump = false,
    AntiAFK      = false,
    Fullbright   = false,
    ESPFish      = false,
    ESPPlayer    = false,

    -- Misc
    DebugMode    = true,
    Watermark    = true,
}

local threads = {}
local ESPObjects = {}
local stats = {
    giveCount = 0,
    sellCount = 0,
    sessionStart = tick(),
}

-- ================================================================
-- UTILITY
-- ================================================================
local function notify(title, content, dur)
    pcall(function()
        Rayfield:Notify({
            Title = title,
            Content = content,
            Duration = dur or 5,
            Image = 4483362458,
        })
    end)
end

local function log(...)
    if State.DebugMode then
        print("[Salfara Premium]", ...)
    end
end

local function getRoot()
    if Character and Character.Parent then
        local h = Character:FindFirstChild("HumanoidRootPart")
        if h then return h end
    end
    Character = LocalPlayer.Character
    return Character and Character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    if Character and Character.Parent then
        return Character:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

local function formatNumber(n)
    local formatted = tostring(math.floor(n))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

-- ================================================================
-- CORE — WORKING SEQUENCE (JANGAN DIUBAH)
-- ================================================================
local function doCast()
    log("-> Cast")
    pcall(function()
        CastReplication:FireServer(COORD.HOOK_POS, COORD.CAST_DIR, State.RodName, State.CastPower)
    end)
end

local function doCleanup()
    log("-> Cleanup")
    pcall(function()
        CleanupCast:FireServer()
    end)
end

local function doCatchSuccess()
    log("-> CatchSuccess")
    pcall(function()
        FishingCatchSuccess:FireServer()
    end)
end

local function getModel(fishName)
    log("-> GetModel:", fishName)
    local ok, result = pcall(function()
        return GetFishModel:InvokeServer(fishName or State.FishName)
    end)
    return ok and result or nil
end

local function doGiveFish(fishName, rarity, weight)
    fishName = fishName or State.FishName
    rarity   = rarity   or State.FishRarity
    weight   = weight   or State.FishWeight

    log("-> FishGiver:", fishName)
    pcall(function()
        FishGiver:FireServer({
            hookPosition = COORD.GIVER_POS,
            name         = fishName,
            rarity       = rarity,
            weight       = weight,
        })
    end)
    stats.giveCount = stats.giveCount + 1
end

local function fullSequence(fishName, rarity, weight)
    fishName = fishName or State.FishName
    rarity   = rarity   or State.FishRarity
    weight   = weight   or State.FishWeight

    doCast()
    task.wait(0.1)
    doCleanup()
    task.wait(0.1)
    doCatchSuccess()
    task.wait(0.1)
    getModel(fishName)
    task.wait(0.1)
    doGiveFish(fishName, rarity, weight)
    task.wait(0.1)
end

local function doSellAll()
    if not Inventory_SellAll then return end
    pcall(function() Inventory_SellAll:InvokeServer() end)
    stats.sellCount = stats.sellCount + 1
end

-- ================================================================
-- THREADS
-- ================================================================
local function startAutoGive()
    if threads.give then task.cancel(threads.give) end
    threads.give = task.spawn(function()
        while State.AutoGive do
            fullSequence()
            task.wait(State.AutoGiveDelay)
        end
    end)
end

local function startAutoSell()
    if threads.sell then task.cancel(threads.sell) end
    threads.sell = task.spawn(function()
        while State.AutoSell do
            doSellAll()
            task.wait(State.AutoSellDelay)
        end
    end)
end

local function startAutoFish()
    if threads.fish then task.cancel(threads.fish) end
    threads.fish = task.spawn(function()
        while State.AutoFish do
            doCast()
            task.wait(1.5)
            doCatchSuccess()
            task.wait(0.2)
            doCleanup()
            task.wait(State.AutoFishDelay)
        end
    end)
end

-- ================================================================
-- NOCLIP
-- ================================================================
local noclipConn
local function toggleNoclip(on)
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    if on then
        noclipConn = RunService.Stepped:Connect(function()
            if Character then
                for _, p in ipairs(Character:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end
end

-- ================================================================
-- INFINITE JUMP
-- ================================================================
local infConn
local function toggleInfJump(on)
    if infConn then infConn:Disconnect() infConn = nil end
    if on then
        infConn = UserInputService.JumpRequest:Connect(function()
            local h = getHumanoid()
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end

-- ================================================================
-- ANTI AFK
-- ================================================================
local afkConn
local function toggleAntiAFK(on)
    if afkConn then afkConn:Disconnect() afkConn = nil end
    if on then
        afkConn = LocalPlayer.Idled:Connect(function()
            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)
    end
end

-- ================================================================
-- FULLBRIGHT
-- ================================================================
local origL = {}
local function toggleFullbright(on)
    if on then
        origL = {
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
        }
        Lighting.Brightness = 3
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
    else
        for k, v in pairs(origL) do Lighting[k] = v end
    end
end

-- ================================================================
-- ESP
-- ================================================================
local function clearESP()
    for _, o in ipairs(ESPObjects) do
        pcall(function() o.box:Destroy() end)
        pcall(function() o.label:Destroy() end)
    end
    ESPObjects = {}
end

local function addESP(part, color, text)
    if not part or not part:IsA("BasePart") then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Size = part.Size + Vector3.new(0.5, 0.5, 0.5)
    box.Adornee = part
    box.AlwaysOnTop = true
    box.Transparency = 0.5
    box.Color3 = color
    box.Parent = part

    local bg = Instance.new("BillboardGui")
    bg.Size = UDim2.new(0, 200, 0, 40)
    bg.AlwaysOnTop = true
    bg.StudsOffset = Vector3.new(0, 3, 0)
    bg.Parent = part

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text or part.Name
    lbl.TextColor3 = color
    lbl.TextStrokeTransparency = 0
    lbl.TextScaled = true
    lbl.Parent = bg

    table.insert(ESPObjects, {box = box, label = bg})
end

-- ================================================================
-- WATERMARK
-- ================================================================
local watermarkGui
local function createWatermark()
    if watermarkGui then watermarkGui:Destroy() end
    local screen = Instance.new("ScreenGui")
    screen.Name = "SalfaraWatermark"
    screen.ResetOnSpawn = false
    screen.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 260, 0, 42)
    frame.Position = UDim2.new(0, 15, 1, -60)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Parent = screen

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(120, 90, 255)
    stroke.Thickness = 1.5
    stroke.Parent = frame

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 90, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 200)),
    })
    gradient.Parent = stroke

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 20)
    title.Position = UDim2.new(0, 10, 0, 4)
    title.BackgroundTransparency = 1
    title.Text = "SALFARA PREMIUM"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -20, 0, 16)
    sub.Position = UDim2.new(0, 10, 0, 22)
    sub.BackgroundTransparency = 1
    sub.Text = "VIP Edition  |  " .. LocalPlayer.Name
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 11
    sub.TextColor3 = Color3.fromRGB(180, 180, 200)
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = frame

    watermarkGui = screen
end

local function destroyWatermark()
    if watermarkGui then watermarkGui:Destroy() watermarkGui = nil end
end

-- ================================================================
-- UI — PREMIUM WINDOW
-- ================================================================
local Window = Rayfield:CreateWindow({
    Name = "SALFARA PREMIUM",
    Icon = 0,
    LoadingTitle = "SALFARA PREMIUM",
    LoadingSubtitle = "VIP Edition  |  Loading...",
    ShowText = "SALFARA",
    Theme = "DarkBlue",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SalfaraPremium",
        FileName = "VIPConfig",
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = false,
    },
    KeySystem = false,
})

-- ================================================================
-- TAB 1: DASHBOARD
-- ================================================================
local DashboardTab = Window:CreateTab("Dashboard", 4483362458)

DashboardTab:CreateSection("-- Quick Actions --")

DashboardTab:CreateButton({
    Name = "  [ GIVE NOW ]  MAXTON Super Harta Karun",
    Callback = function()
        fullSequence()
        notify("Give Fish", "MAXTON Super Harta Karun dikirim ke inventory.", 5)
    end,
})

DashboardTab:CreateButton({
    Name = "  [ GIVE x5 ]  MAXTON Super Harta Karun",
    Callback = function()
        task.spawn(function()
            for i = 1, 5 do
                fullSequence()
                task.wait(0.3)
            end
            notify("Give Fish", "5x MAXTON Super Harta Karun dikirim.", 5)
        end)
    end,
})

DashboardTab:CreateButton({
    Name = "  [ GIVE x10 ]  MAXTON Super Harta Karun",
    Callback = function()
        task.spawn(function()
            for i = 1, 10 do
                fullSequence()
                task.wait(0.3)
            end
            notify("Give Fish", "10x MAXTON Super Harta Karun dikirim.", 5)
        end)
    end,
})

DashboardTab:CreateButton({
    Name = "  [ GIVE x50 ]  MAXTON Super Harta Karun",
    Callback = function()
        task.spawn(function()
            for i = 1, 50 do
                fullSequence()
                task.wait(0.25)
            end
            notify("Give Fish", "50x MAXTON Super Harta Karun dikirim.", 5)
        end)
    end,
})

DashboardTab:CreateSection("-- Loop Control --")

DashboardTab:CreateToggle({
    Name = "AUTO GIVE  |  Endless Loop",
    CurrentValue = false,
    Flag = "AutoGive",
    Callback = function(v)
        State.AutoGive = v
        if v then
            startAutoGive()
            notify("Auto Give", "Loop aktif. Mengirim ikan tanpa henti.", 3)
        else
            if threads.give then task.cancel(threads.give) threads.give = nil end
            notify("Auto Give", "Loop dimatikan.", 3)
        end
    end,
})

DashboardTab:CreateSlider({
    Name = "Loop Interval",
    Range = {0.3, 10},
    Increment = 0.1,
    Suffix = "detik",
    CurrentValue = 1,
    Flag = "AutoGiveDelay",
    Callback = function(v) State.AutoGiveDelay = v end,
})

DashboardTab:CreateSection("-- Sell Control --")

DashboardTab:CreateToggle({
    Name = "AUTO SELL  |  Endless Loop",
    CurrentValue = false,
    Flag = "AutoSell",
    Callback = function(v)
        State.AutoSell = v
        if v then
            startAutoSell()
            notify("Auto Sell", "Loop aktif.", 3)
        else
            if threads.sell then task.cancel(threads.sell) threads.sell = nil end
            notify("Auto Sell", "Loop dimatikan.", 3)
        end
    end,
})

DashboardTab:CreateSlider({
    Name = "Sell Interval",
    Range = {1, 30},
    Increment = 1,
    Suffix = "detik",
    CurrentValue = 3,
    Flag = "AutoSellDelay",
    Callback = function(v) State.AutoSellDelay = v end,
})

DashboardTab:CreateButton({
    Name = "  [ SELL NOW ]  Jual Semua Ikan",
    Callback = function()
        doSellAll()
        notify("Sell All", "Semua ikan dijual.", 3)
    end,
})

-- ================================================================
-- TAB 2: FISH INJECTOR
-- ================================================================
local InjectorTab = Window:CreateTab("Fish Injector", 4483362458)

InjectorTab:CreateSection("-- Custom Configuration --")

InjectorTab:CreateInput({
    Name = "Fish Name",
    CurrentValue = "MAXTON Super Harta Karun Mount Salfara 100 JUTA KOIN",
    PlaceholderText = "Masukkan nama ikan...",
    RemoveTextAfterFocusLost = false,
    Flag = "FishNameInput",
    Callback = function(t) State.FishName = t end,
})

InjectorTab:CreateDropdown({
    Name = "Rarity Tier",
    Options = {"Common", "Uncommon", "Epic", "Legendary", "Secret"},
    CurrentOption = "Secret",
    Flag = "RarityDropdown",
    Callback = function(o) State.FishRarity = o end,
})

InjectorTab:CreateSlider({
    Name = "Weight (kg)",
    Range = {1, 5000000},
    Increment = 1000,
    Suffix = "kg",
    CurrentValue = 1600000,
    Flag = "WeightSlider",
    Callback = function(v) State.FishWeight = v end,
})

InjectorTab:CreateButton({
    Name = "  [ INJECT ]  Kirim Ikan Custom",
    Callback = function()
        fullSequence()
        notify("Injector", State.FishName .. " dikirim.", 5)
    end,
})

InjectorTab:CreateButton({
    Name = "  [ INJECT x10 ]  Kirim Ikan Custom",
    Callback = function()
        task.spawn(function()
            for i = 1, 10 do
                fullSequence()
                task.wait(0.3)
            end
            notify("Injector", "10x " .. State.FishName .. " dikirim.", 5)
        end)
    end,
})

InjectorTab:CreateSection("-- Rod Configuration --")

InjectorTab:CreateDropdown({
    Name = "Select Rod",
    Options = {"Basic Rod", "Pink Candy", "Crescendo", "Spirit", "Prize", "Withering"},
    CurrentOption = "Withering",
    Flag = "RodDropdown",
    Callback = function(o) State.RodName = o end,
})

InjectorTab:CreateSlider({
    Name = "Cast Power",
    Range = {1, 100},
    Increment = 1,
    Suffix = "power",
    CurrentValue = 94,
    Flag = "PowerSlider",
    Callback = function(v) State.CastPower = v end,
})

-- ================================================================
-- TAB 3: SECRET VAULT
-- ================================================================
local VaultTab = Window:CreateTab("Secret Vault", 4483362458)

VaultTab:CreateSection("-- Premium Secret Fish --")

local secretFishList = {
    {name = "MAXTON Super Harta Karun Mount Salfara 100 JUTA KOIN", weight = 1600000, rarity = "Secret"},
    {name = "Great Lochness Monster", weight = 5000, rarity = "Secret"},
    {name = "Ikan Centil", weight = 2500, rarity = "Secret"},
    {name = "Sotong", weight = 3000, rarity = "Secret"},
    {name = "Starbloom Jelly", weight = 2000, rarity = "Secret"},
    {name = "Prize", weight = 4000, rarity = "Secret"},
    {name = "Withering", weight = 2500, rarity = "Secret"},
    {name = "Crescendo", weight = 1800, rarity = "Secret"},
    {name = "Spirit", weight = 1500, rarity = "Secret"},
    {name = "Jack", weight = 2000, rarity = "Secret"},
}

for _, fish in ipairs(secretFishList) do
    VaultTab:CreateButton({
        Name = "  [ SECRET ]  " .. fish.name,
        Callback = function()
            fullSequence(fish.name, fish.rarity, fish.weight)
            notify("Secret", fish.name .. " dikirim.", 5)
        end,
    })
end

VaultTab:CreateSection("-- Bulk Operations --")

VaultTab:CreateButton({
    Name = "  [ DROP ALL ]  Semua Secret Fish",
    Callback = function()
        task.spawn(function()
            for _, fish in ipairs(secretFishList) do
                fullSequence(fish.name, fish.rarity, fish.weight)
                task.wait(0.4)
            end
            notify("Vault", "Semua secret fish dikirim.", 5)
        end)
    end,
})

VaultTab:CreateButton({
    Name = "  [ DROP x10 ]  Semua Secret Fish",
    Callback = function()
        task.spawn(function()
            for i = 1, 10 do
                for _, fish in ipairs(secretFishList) do
                    fullSequence(fish.name, fish.rarity, fish.weight)
                    task.wait(0.2)
                end
            end
            notify("Vault", "100x Secret fish dikirim.", 5)
        end)
    end,
})

-- ================================================================
-- TAB 4: AUTO FARM
-- ================================================================
local FarmTab = Window:CreateTab("Auto Farm", 4483362458)

FarmTab:CreateSection("-- Auto Cast --")

FarmTab:CreateToggle({
    Name = "AUTO CAST  |  Endless Fishing",
    CurrentValue = false,
    Flag = "AutoFish",
    Callback = function(v)
        State.AutoFish = v
        if v then
            startAutoFish()
            notify("Auto Fish", "Auto cast aktif.", 3)
        else
            if threads.fish then task.cancel(threads.fish) threads.fish = nil end
            notify("Auto Fish", "Auto cast dimatikan.", 3)
        end
    end,
})

FarmTab:CreateSlider({
    Name = "Cast Interval",
    Range = {0.5, 10},
    Increment = 0.5,
    Suffix = "detik",
    CurrentValue = 2,
    Flag = "AutoFishDelay",
    Callback = function(v) State.AutoFishDelay = v end,
})

FarmTab:CreateSection("-- Manual Override --")

FarmTab:CreateButton({
    Name = "  [ CAST ]  Manual Cast",
    Callback = function()
        doCast()
        notify("Cast", "Cast dikirim.", 2)
    end,
})

FarmTab:CreateButton({
    Name = "  [ CATCH ]  Manual Catch Success",
    Callback = function()
        doCatchSuccess()
        notify("Catch", "Catch dikirim.", 2)
    end,
})

FarmTab:CreateButton({
    Name = "  [ CLEANUP ]  Manual Cleanup",
    Callback = function()
        doCleanup()
        notify("Cleanup", "Cleanup dikirim.", 2)
    end,
})

-- ================================================================
-- TAB 5: CHARACTER
-- ================================================================
local CharTab = Window:CreateTab("Character", 4483362458)

CharTab:CreateSection("-- Movement --")

CharTab:CreateToggle({
    Name = "SPEED  |  Walk Speed Override",
    CurrentValue = false,
    Flag = "SpeedToggle",
    Callback = function(v)
        State.SpeedEnabled = v
        local h = getHumanoid()
        if h then h.WalkSpeed = v and State.SpeedValue or 16 end
    end,
})

CharTab:CreateSlider({
    Name = "Speed Value",
    Range = {16, 500},
    Increment = 1,
    Suffix = "studs/s",
    CurrentValue = 35,
    Flag = "SpeedValue",
    Callback = function(v)
        State.SpeedValue = v
        if State.SpeedEnabled then
            local h = getHumanoid()
            if h then h.WalkSpeed = v end
        end
    end,
})

CharTab:CreateToggle({
    Name = "JUMP  |  Jump Power Override",
    CurrentValue = false,
    Flag = "JumpToggle",
    Callback = function(v)
        State.JumpEnabled = v
        local h = getHumanoid()
        if h then
            h.UseJumpPower = v
            h.JumpPower = v and State.JumpValue or 50
        end
    end,
})

CharTab:CreateSlider({
    Name = "Jump Value",
    Range = {50, 500},
    Increment = 1,
    Suffix = "power",
    CurrentValue = 100,
    Flag = "JumpValue",
    Callback = function(v)
        State.JumpValue = v
        if State.JumpEnabled then
            local h = getHumanoid()
            if h then h.JumpPower = v end
        end
    end,
})

CharTab:CreateToggle({
    Name = "NOCLIP  |  Walk Through Walls",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(v) toggleNoclip(v) end,
})

CharTab:CreateToggle({
    Name = "INFINITE JUMP  |  Multi Jump",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(v) toggleInfJump(v) end,
})

CharTab:CreateToggle({
    Name = "ANTI AFK  |  Prevent Kick",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(v) toggleAntiAFK(v) end,
})

-- ================================================================
-- TAB 6: VISUAL
-- ================================================================
local VisualTab = Window:CreateTab("Visual", 4483362458)

VisualTab:CreateSection("-- Lighting --")

VisualTab:CreateToggle({
    Name = "FULLBRIGHT  |  Max Brightness",
    CurrentValue = false,
    Flag = "Fullbright",
    Callback = function(v) toggleFullbright(v) end,
})

VisualTab:CreateSection("-- ESP --")

VisualTab:CreateToggle({
    Name = "ESP FISH  |  Highlight Fish",
    CurrentValue = false,
    Flag = "ESPFish",
    Callback = function(v)
        State.ESPFish = v
        if v then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and (obj.Name:lower():find("fish") or obj.Name:lower():find("ikan")) then
                    for _, p in ipairs(obj:GetChildren()) do
                        if p:IsA("BasePart") then addESP(p, Color3.fromRGB(0, 255, 120), obj.Name) end
                    end
                end
            end
        else
            clearESP()
        end
    end,
})

VisualTab:CreateToggle({
    Name = "ESP PLAYER  |  Highlight Players",
    CurrentValue = false,
    Flag = "ESPPlayer",
    Callback = function(v)
        State.ESPPlayer = v
        if v then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then addESP(hrp, Color3.fromRGB(255, 80, 80), plr.Name) end
                end
            end
        else
            clearESP()
        end
    end,
})

-- ================================================================
-- TAB 7: UTILITY
-- ================================================================
local UtilTab = Window:CreateTab("Utility", 4483362458)

UtilTab:CreateSection("-- Chat & Social --")

UtilTab:CreateButton({
    Name = "  [ HELP ]  Kirim HELP ke Chat",
    Callback = function()
        if SendChatMessage then
            pcall(function() SendChatMessage:FireServer("General", "HELP") end)
            notify("Dragon Chat", "HELP dikirim ke chat.", 3)
        end
    end,
})

UtilTab:CreateSection("-- Navigation --")

UtilTab:CreateButton({
    Name = "  [ SPAWN ]  Teleport ke Spawn",
    Callback = function()
        local sp = workspace:FindFirstChildOfClass("SpawnLocation")
        local hrp = getRoot()
        if sp and hrp then
            hrp.CFrame = sp.CFrame + Vector3.new(0, 5, 0)
            notify("Teleport", "Teleport ke spawn.", 3)
        end
    end,
})

UtilTab:CreateButton({
    Name = "  [ REJOIN ]  Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

UtilTab:CreateSection("-- Inventory --")

UtilTab:CreateButton({
    Name = "  [ CHECK ]  Lihat Inventory",
    Callback = function()
        if not Inventory_GetData then
            notify("Error", "Remote tidak tersedia.", 3)
            return
        end
        local ok, data = pcall(function() return Inventory_GetData:InvokeServer() end)
        if ok and type(data) == "table" then
            notify("Inventory", "Total ikan: " .. #data, 5)
        else
            notify("Inventory", "Gagal mengambil data.", 3)
        end
    end,
})

UtilTab:CreateButton({
    Name = "  [ PETS ]  Lihat Data Pet",
    Callback = function()
        if not Inventory_GetPetData then return end
        local ok, data = pcall(function() return Inventory_GetPetData:InvokeServer() end)
        notify("Pets", ok and "Data pet berhasil dimuat." or "Gagal.", 3)
    end,
})

UtilTab:CreateButton({
    Name = "  [ JACKPOT ]  Lihat Data Jackpot",
    Callback = function()
        if not Inventory_GetJackpot then return end
        local ok, data = pcall(function() return Inventory_GetJackpot:InvokeServer() end)
        notify("Jackpot", ok and "Data jackpot berhasil dimuat." or "Gagal.", 3)
    end,
})

-- ================================================================
-- TAB 8: SETTINGS
-- ================================================================
local SettingsTab = Window:CreateTab("Settings", 4483362458)

SettingsTab:CreateSection("-- Interface --")

SettingsTab:CreateToggle({
    Name = "WATERMARK  |  Tampilkan Watermark",
    CurrentValue = true,
    Flag = "WatermarkToggle",
    Callback = function(v)
        State.Watermark = v
        if v then createWatermark() else destroyWatermark() end
    end,
})

SettingsTab:CreateToggle({
    Name = "DEBUG MODE  |  Print Console Log",
    CurrentValue = true,
    Flag = "DebugToggle",
    Callback = function(v) State.DebugMode = v end,
})

SettingsTab:CreateSection("-- Session --")

SettingsTab:CreateButton({
    Name = "  [ UNLOAD ]  Unload Hub",
    Callback = function()
        for _, t in pairs(threads) do pcall(function() task.cancel(t) end) end
        clearESP()
        toggleNoclip(false)
        toggleInfJump(false)
        toggleAntiAFK(false)
        destroyWatermark()
        Rayfield:Destroy()
    end,
})

-- ================================================================
-- INITIALIZE
-- ================================================================
Rayfield:LoadConfiguration()

createWatermark()

notify("SALFARA PREMIUM", "VIP Edition berhasil dimuat. Tekan K untuk toggle UI.", 8)

-- ================================================================
-- RESPAWN HANDLER
-- ================================================================
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    RootPart = newChar:WaitForChild("HumanoidRootPart")
    task.wait(1)

    local h = getHumanoid()
    if h then
        if State.SpeedEnabled then h.WalkSpeed = State.SpeedValue end
        if State.JumpEnabled then
            h.UseJumpPower = true
            h.JumpPower = State.JumpValue
        end
    end
    if State.Noclip then toggleNoclip(true) end
end)

-- ================================================================
-- DISPLAY SERVER HOP INFO
-- ================================================================
log("Premium Hub loaded successfully.")
log("Server:", game.JobId)
log("Place ID:", game.PlaceId)