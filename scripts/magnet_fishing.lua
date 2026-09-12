--[[
    ╔════════════════════════════════════════════════════════════╗
    ║   MAGNET FISHING NOW — v5.0 TOTAL REBUILD                   ║
    ║   ────────────────────────────────────────────────────────  ║
    ║   ✓ Force True Result (method yang BERHASIL)                ║
    ║   ✓ No Instant Win override                                 ║
    ║   ✓ ALL toggles reactive (Heartbeat per-frame)              ║
    ║   ✓ Auto TP to Bridge                                       ║
    ║   ✓ Auto Cast, Auto Drop, Auto Tap, Auto Pick               ║
    ║   ✓ Semua fitur dari v3.0 restored                          ║
    ╚════════════════════════════════════════════════════════════╝
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ═══════════════════════ SERVICES ═══════════════════════
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local HttpService       = game:GetService("HttpService")
local Lighting          = game:GetService("Lighting")
local VirtualUser       = game:GetService("VirtualUser")
local GuiService        = game:GetService("GuiService")
local TeleportService   = game:GetService("TeleportService")

local LP   = Players.LocalPlayer
local Knit = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"))

-- ═══════════════════════ KNIT SERVICES ═══════════════════════
local FishingService         = Knit.GetService("FishingService")
local EconomyService         = Knit.GetService("EconomyService")
local IndexService           = Knit.GetService("IndexService")
local ContainerService       = Knit.GetService("ContainerService")
local GearService            = Knit.GetService("GearService")
local LuckService            = Knit.GetService("LuckService")
local MarketService          = Knit.GetService("MarketService")
local PotionService          = Knit.GetService("PotionService")
local CraftingService        = Knit.GetService("CraftingService")
local PeriodicQuestService   = Knit.GetService("PeriodicQuestService")
local OfflineCatchService    = Knit.GetService("OfflineCatchService")
local InventoryToolService   = Knit.GetService("InventoryToolService")
local StarterPackService     = Knit.GetService("StarterPackService")
local GiftService            = Knit.GetService("GiftService")

-- ═══════════════════════ KNIT CONTROLLERS ═══════════════════════
local FC                    = Knit.GetController("FishingController")
local DataController        = Knit.GetController("DataController")
local IndexUIController     = Knit.GetController("IndexUIController")
local ContainerController   = Knit.GetController("ContainerController")
local SellController        = Knit.GetController("SellController")
local GearShopController    = Knit.GetController("GearShopController")
local CraftingController    = Knit.GetController("CraftingController")
local PeriodicQuestController = Knit.GetController("PeriodicQuestController")
local RobuxShopController   = Knit.GetController("RobuxShopController")

-- ═══════════════════════ SHARED ═══════════════════════
local FishingConfig = require(ReplicatedStorage.Shared.FishingConfig)
local ItemCatalog   = require(ReplicatedStorage.Shared.ItemCatalog)
local FishingRods   = require(ReplicatedStorage.Shared.FishingRods)
local Magnets       = require(ReplicatedStorage.Shared.Magnets)
local AuraCrafting  = require(ReplicatedStorage.Shared.AuraCrafting)
local FormatNumber  = require(ReplicatedStorage.Shared.FormatNumber)

-- ═══════════════════════ CONFIG ═══════════════════════
local CFG = {
    -- ═══ MASTER ═══
    AutoFish         = false,

    -- ═══ AUTO CAST ═══
    AutoCast         = true,
    AutoTPBridge     = true,
    ChargeHoldTime   = 0.4,

    -- ═══ AUTO DROP ═══
    AutoDrop         = true,
    DropDelay        = 0,

    -- ═══ AUTO PICK ═══
    AutoPick         = true,
    AutoLockPicks    = true,

    -- ═══ AUTO REEL ═══
    AutoReel         = true,
    ForceTrueResult  = true,  -- ← METHOD YANG BERHASIL

    -- ═══ AUTO TAP ═══
    AutoTap          = true,
    AutoTapCircle    = true,
    AutoTapRadar     = true,
    AutoTapCeremony  = true,
    AutoTapDrop      = true,

    -- ═══ ZERO DELAY ═══
    ZeroDelay        = true,

    -- ═══ ECONOMY ═══
    AutoSell         = false,
    SellAt           = 28,
    AutoIndex        = false,
    AutoContainer    = false,
    AutoQuest        = false,
    AutoOfflineClaim = true,

    -- ═══ GEAR ═══
    AutoUpgrade      = false,
    UpgradeOrder     = { "Storage", "Value", "Depth", "Luck" },
    AutoEquipBestRod = false,
    AutoEquipBestMag = false,

    -- ═══ CRAFTING ═══
    AutoCraftAura    = false,
    AutoTrackAura    = false,
    PreferredAura    = "Genesis",

    -- ═══ EVENTS ═══
    AutoPotion       = false,
    PotionKey        = "Luck5x",
    AutoMeteor       = false,
    AutoVariant      = false,

    -- ═══ MISC ═══
    AutoFavourite    = false,
    AutoSkipTutorial = false,
    AntiAFK          = true,
    FPSBoost         = false,
    FullBright       = false,
    NoFog            = false,
}

-- ═══════════════════════ RUNTIME ═══════════════════════
local Runtime = {
    BrightnessBackup = {},
    AntiAFKConn      = nil,
    CraftCooldown    = 0,
    RemoteHooked     = false,
    ReelRF           = nil,
    HookAttempts     = 0,
}

-- ═══════════════════════ UTIL ═══════════════════════
local function getFishData()
    local p = DataController:GetPlayer()
    return p and p.Public.Persistent.Fishing or nil
end

local function getPrivate()
    local p = DataController:GetPlayer()
    return p and p.Private.Persistent or nil
end

local function invCount()
    local d = getFishData()
    if not d then return 0, 0 end
    local n = 0
    for _, c in pairs(d.Inventory or {}) do n += c end
    local cap = FishingConfig.BaseCapacity
        + FishingConfig.Upgrades.Storage.PerLevel * ((d.Upgrades and d.Upgrades.Storage) or 0)
    return n + #(d.Containers or {}), cap
end

local function notify(content, title)
    Rayfield:Notify({
        Title = title or "Auto Fisher",
        Content = tostring(content),
        Duration = 3,
        Image = 4483362458,
    })
end

local function safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[AutoFisher]", err) end
    return ok, err
end

-- ═══════════════════════ BRIDGE HELPER ═══════════════════════
local function findNearestBridge()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local origin = hrp and hrp.Position or Vector3.zero

    local best, bestDist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "Bridge" and obj:IsA("BasePart") then
            local d = (obj.Position - origin).Magnitude
            if d < bestDist then best, bestDist = obj, d end
        end
    end
    return best
end

local function isOnBridge()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { char }

    for _, off in ipairs({
        Vector3.new(0, 0, 0), Vector3.new(1.4, 0, 0),
        Vector3.new(-1.4, 0, 0), Vector3.new(0, 0, 1.4), Vector3.new(0, 0, -1.4),
    }) do
        local hit = workspace:Raycast(hrp.Position + off, Vector3.new(0, -12, 0), params)
        if hit then
            local inst = hit.Instance
            while inst and inst ~= workspace do
                if inst.Name == "Bridge" then return true end
                inst = inst.Parent
            end
        end
    end
    return false
end

local function tpToBridge()
    local bridge = findNearestBridge()
    if not bridge then return false end
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local targetPos = bridge.Position + Vector3.new(0, 5, 0)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.CFrame = CFrame.new(targetPos)
    return true
end

-- ═══════════════════════ REMOTE HOOK — FORCE TRUE RESULT ═══════════════════════
-- Method ini YANG BERHASIL. Blok semua ReelResult(false), paksa jadi true.
local function tryHookReelResult()
    if Runtime.RemoteHooked then return true end
    Runtime.HookAttempts = Runtime.HookAttempts + 1

    -- Cari RemoteFunction
    local ok, reelRF = pcall(function()
        return ReplicatedStorage.Packages.Knit.Services.FishingService.RF.ReelResult
    end)
    if not ok or not reelRF then
        -- Coba path alternatif
        local alt = ReplicatedStorage:FindFirstChild("Packages")
        if alt then
            alt = alt:FindFirstChild("Knit")
            if alt then
                alt = alt:FindFirstChild("Services")
                if alt then
                    alt = alt:FindFirstChild("FishingService")
                    if alt then
                        alt = alt:FindFirstChild("RF")
                        if alt then
                            reelRF = alt:FindFirstChild("ReelResult")
                        end
                    end
                end
            end
        end
    end
    if not reelRF then return false end
    Runtime.ReelRF = reelRF

    -- Cek executor support
    if not (getrawmetatable and newcclosure and setreadonly and getnamecallmethod) then
        warn("[AutoFisher] Executor tidak support hookmetamethod")
        return false
    end

    local success = pcall(function()
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "InvokeServer" and self == Runtime.ReelRF then
                local args = { ... }
                -- Blok FALSE, paksa TRUE (hanya kalau AutoReel & ForceTrueResult ON)
                if args[1] == false and CFG.AutoFish and CFG.AutoReel and CFG.ForceTrueResult then
                    args[1] = true
                end
                return oldNamecall(self, table.unpack(args))
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
        Runtime.RemoteHooked = true
        return true
    end)

    return success and Runtime.RemoteHooked
end

-- ═══════════════════════ AUTOTAP MODULE ═══════════════════════
local AutoTap = {}

function AutoTap.RadarBubbles()
    local overlay = FC._radarOverlay
    if not overlay then return 0 end
    local n = 0
    for _, child in ipairs(overlay:GetChildren()) do
        if child:GetAttribute("RadarPoolIndex")
           and child.Visible
           and not child:GetAttribute("Attached")
           and not child:GetAttribute("Picked") then
            local idx = child:GetAttribute("Index")
            if idx then
                safe(function() FishingService:PickContact(idx) end)
                n += 1
            end
        end
    end
    if n > 0 and CFG.AutoLockPicks then
        safe(function() FishingService:LockPicks() end)
    end
    return n
end

function AutoTap.TapCircle()
    safe(function() FishingService:UnsnagTap() end)
    if FC._crankReelAnim then
        safe(function() FC:_crankReelAnim() end)
    end
end

function AutoTap.DropButton()
    if FC._state == "Descending" and not FC._dropTravelling then
        safe(function() FC:_dropOnce() end)
        return true
    end
    return false
end

function AutoTap.CeremonyAdvance()
    if FC._ceremonyAdvance then
        safe(FC._ceremonyAdvance)
        return true
    end
    return false
end

-- ═══════════════════════ WINDOW ═══════════════════════
local Window = Rayfield:CreateWindow({
    Name = "🎣 Magnet Fishing v5.0",
    LoadingTitle = "Loading v5.0...",
    LoadingSubtitle = "Force True Result + All Features",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ══════════════════════════════════════════════════════════
-- TAB 1: FISHING
-- ══════════════════════════════════════════════════════════
local FishTab = Window:CreateTab("🎣 Fishing", 4483362458)

FishTab:CreateSection("MASTER")

FishTab:CreateToggle({
    Name = "🟢 AUTO FISH (Master Switch)",
    CurrentValue = false,
    Flag = "Master",
    Callback = function(v)
        CFG.AutoFish = v
        notify("Master: " .. (v and "ON ✓" or "OFF ✗"))
    end,
})

FishTab:CreateSection("AUTO CAST")

FishTab:CreateToggle({
    Name = "Auto Cast",
    CurrentValue = true,
    Flag = "AutoCast",
    Callback = function(v) CFG.AutoCast = v end,
})

FishTab:CreateToggle({
    Name = "Auto TP to Bridge",
    CurrentValue = true,
    Flag = "AutoTPBridge",
    Callback = function(v) CFG.AutoTPBridge = v end,
})

FishTab:CreateSlider({
    Name = "Charge Hold Time",
    Range = { 0.25, 1 },
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = 0.4,
    Flag = "ChargeHold",
    Callback = function(v) CFG.ChargeHoldTime = v end,
})

FishTab:CreateButton({
    Name = "🌉 TP to Nearest Bridge",
    Callback = function()
        local ok = tpToBridge()
        notify(ok and "TP ke bridge!" or "Bridge tidak ditemukan.")
    end,
})

FishTab:CreateButton({
    Name = "📍 Check Bridge Status",
    Callback = function()
        notify(isOnBridge() and "✓ Di bridge" or "✗ Di darat")
    end,
})

FishTab:CreateSection("AUTO DROP")

FishTab:CreateToggle({
    Name = "Auto Drop",
    CurrentValue = true,
    Flag = "AutoDrop",
    Callback = function(v) CFG.AutoDrop = v end,
})

FishTab:CreateSlider({
    Name = "Drop Delay",
    Range = { 0, 1 },
    Increment = 0.02,
    Suffix = "s",
    CurrentValue = 0,
    Flag = "DropDelay",
    Callback = function(v) CFG.DropDelay = v end,
})

FishTab:CreateSection("AUTO PICK")

FishTab:CreateToggle({
    Name = "Auto Pick Semua Signal",
    CurrentValue = true,
    Flag = "AutoPick",
    Callback = function(v) CFG.AutoPick = v end,
})

FishTab:CreateToggle({
    Name = "Auto Lock Picks",
    CurrentValue = true,
    Flag = "AutoLock",
    Callback = function(v) CFG.AutoLockPicks = v end,
})

FishTab:CreateSection("⚡ AUTO REEL — FORCE TRUE RESULT")

FishTab:CreateToggle({
    Name = "Auto Reel",
    CurrentValue = true,
    Flag = "AutoReel",
    Callback = function(v) CFG.AutoReel = v end,
})

FishTab:CreateToggle({
    Name = "🔒 Force True Result (Remote Hook)",
    CurrentValue = true,
    Flag = "ForceTrue",
    Callback = function(v)
        CFG.ForceTrueResult = v
        notify("Force True: " .. (v and "ON ✓" or "OFF ✗"))
        if v and not Runtime.RemoteHooked then
            tryHookReelResult()
        end
    end,
})

FishTab:CreateButton({
    Name = "🎯 Hook ReelResult Now",
    Callback = function()
        local ok = tryHookReelResult()
        notify(ok and "✓ Hook OK!" or "✗ Hook gagal — executor tidak support")
    end,
})

FishTab:CreateSection("🖱️ AUTO TAP")

FishTab:CreateToggle({
    Name = "Auto Tap Master",
    CurrentValue = true,
    Flag = "AutoTap",
    Callback = function(v)
        CFG.AutoTap = v
        notify("Auto Tap: " .. (v and "ON ✓" or "OFF ✗"))
    end,
})

FishTab:CreateToggle({
    Name = "Auto Tap — TapCircle",
    CurrentValue = true,
    Flag = "AutoTapCircle",
    Callback = function(v) CFG.AutoTapCircle = v end,
})

FishTab:CreateToggle({
    Name = "Auto Tap — Radar Bubble",
    CurrentValue = true,
    Flag = "AutoTapRadar",
    Callback = function(v) CFG.AutoTapRadar = v end,
})

FishTab:CreateToggle({
    Name = "Auto Tap — Ceremony Advance",
    CurrentValue = true,
    Flag = "AutoTapCeremony",
    Callback = function(v) CFG.AutoTapCeremony = v end,
})

FishTab:CreateToggle({
    Name = "Auto Tap — Drop Button",
    CurrentValue = true,
    Flag = "AutoTapDrop",
    Callback = function(v) CFG.AutoTapDrop = v end,
})

FishTab:CreateSection("⚡ ZERO DELAY")

FishTab:CreateToggle({
    Name = "Zero Delay (0ms)",
    CurrentValue = true,
    Flag = "ZeroDelay",
    Callback = function(v)
        CFG.ZeroDelay = v
        if v then
            CFG.DropDelay = 0
            CFG.ChargeHoldTime = 0.3
        end
    end,
})

FishTab:CreateSection("Manual Actions")

FishTab:CreateButton({
    Name = "🚀 Force Cast Sekarang",
    Callback = function()
        safe(function() FC:_beginCharge() end)
        task.wait(0.4)
        safe(function() FC:_releaseCharge() end)
    end,
})

FishTab:CreateButton({
    Name = "🔻 Force Drop",
    Callback = function()
        safe(function() FC:_dropOnce() end)
    end,
})

FishTab:CreateButton({
    Name = "⏹️ Cancel Pull",
    Callback = function()
        safe(function() FishingService:CancelPull() end)
    end,
})

FishTab:CreateButton({
    Name = "🎯 Force Pick All Radar",
    Callback = function()
        local n = AutoTap.RadarBubbles()
        notify(("Picked %d bubble."):format(n))
    end,
})

FishTab:CreateSection("Live Debug")

local DebugLog = FishTab:CreateParagraph({
    Title = "Live Debug",
    Content = "Loading...",
})

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            DebugLog:Set({
                Title = "Live Debug",
                Content = string.format(
                    "State    : %s\nOnBridge : %s\nCharging : %s\nReeling  : %s\nReelFill : %.2f\nReported : %s\nHook     : %s",
                    tostring(FC._state),
                    tostring(isOnBridge()),
                    tostring(FC._charging ~= nil),
                    tostring(FC._state == "Reeling"),
                    FC._reelSim and (FC._reelSim.Fill or 0) or 0,
                    tostring(FC._reelSim and FC._reelSim.Reported),
                    tostring(Runtime.RemoteHooked)
                ),
            })
        end)
    end
end)

-- ══════════════════════════════════════════════════════════
-- TAB 2: ECONOMY
-- ══════════════════════════════════════════════════════════
local EcoTab = Window:CreateTab("💰 Economy", 4483362458)

EcoTab:CreateSection("Sell")

EcoTab:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = false,
    Flag = "AutoSell",
    Callback = function(v) CFG.AutoSell = v end,
})

EcoTab:CreateSlider({
    Name = "Sell Threshold",
    Range = { 5, 80 },
    Increment = 1,
    Suffix = " slot",
    CurrentValue = 28,
    Flag = "SellAt",
    Callback = function(v) CFG.SellAt = v end,
})

EcoTab:CreateButton({
    Name = "🚀 Sell All Sekarang",
    Callback = function()
        safe(function() EconomyService:SellAll() end)
        notify("SellAll dikirim.")
    end,
})

EcoTab:CreateButton({
    Name = "🧠 Open Sell Panel",
    Callback = function()
        safe(function() SellController:SetOpen(true) end)
    end,
})

EcoTab:CreateSection("Index")

EcoTab:CreateToggle({
    Name = "Auto Claim Index",
    CurrentValue = false,
    Flag = "AutoIndex",
    Callback = function(v) CFG.AutoIndex = v end,
})

EcoTab:CreateButton({
    Name = "📖 Claim All Index",
    Callback = function()
        safe(function()
            IndexService:ClaimAllIndex():andThen(function(r)
                if r and r.ok and (r.Paid or 0) > 0 then
                    notify(("Index: +$%s"):format(FormatNumber.Short(r.Paid)))
                end
            end)
        end)
    end,
})

EcoTab:CreateButton({
    Name = "🎯 Open Index with Odds",
    Callback = function()
        safe(function() IndexUIController:OpenWithOdds() end)
    end,
})

EcoTab:CreateSection("Quest")

EcoTab:CreateToggle({
    Name = "Auto Claim Quest",
    CurrentValue = false,
    Flag = "AutoQuest",
    Callback = function(v) CFG.AutoQuest = v end,
})

EcoTab:CreateButton({
    Name = "📜 Open Quest Panel",
    Callback = function()
        safe(function() PeriodicQuestController:SetOpen(true) end)
    end,
})

EcoTab:CreateButton({
    Name = "🔄 Re-Deal Quests (Admin)",
    Callback = function()
        safe(function()
            PeriodicQuestService:DebugRedeal(LP):andThen(function()
                notify("Quests re-dealt.")
            end)
        end)
    end,
})

EcoTab:CreateSection("Offline")

EcoTab:CreateToggle({
    Name = "Auto Claim Offline",
    CurrentValue = true,
    Flag = "AutoOffline",
    Callback = function(v) CFG.AutoOfflineClaim = v end,
})

EcoTab:CreateButton({
    Name = "💸 Claim Offline Now",
    Callback = function()
        safe(function()
            OfflineCatchService:ClaimWelcomeBack():andThen(function(r)
                notify(("Offline: $%s"):format(FormatNumber.Short((r and r.Cash) or 0)))
            end)
        end)
    end,
})

-- ══════════════════════════════════════════════════════════
-- TAB 3: GEAR
-- ══════════════════════════════════════════════════════════
local GearTab = Window:CreateTab("⚙️ Gear", 4483362458)

GearTab:CreateSection("Auto Upgrade")

GearTab:CreateToggle({
    Name = "Auto Upgrade",
    CurrentValue = false,
    Flag = "AutoUpgrade",
    Callback = function(v) CFG.AutoUpgrade = v end,
})

GearTab:CreateDropdown({
    Name = "Upgrade Order",
    Options = { "Storage", "Value", "Depth", "Luck" },
    CurrentOption = { "Storage", "Value", "Depth", "Luck" },
    MultipleOptions = true,
    Flag = "UpgradeOrder",
    Callback = function(opts) CFG.UpgradeOrder = opts end,
})

for _, track in ipairs({ "Storage", "Value", "Depth", "Luck" }) do
    GearTab:CreateButton({
        Name = "Buy " .. track .. " x1",
        Callback = function()
            safe(function()
                GearService:BuyUpgrade(track):andThen(function(r)
                    if r and r.Success then notify(track .. " upgraded.") end
                end)
            end)
        end,
    })
end

GearTab:CreateButton({
    Name = "⏫ Upgrade Semua (1x cycle)",
    Callback = function()
        for _, track in ipairs(CFG.UpgradeOrder) do
            safe(function() GearService:BuyUpgrade(track) end)
            task.wait(0.3)
        end
        notify("Upgrade cycle done.")
    end,
})

GearTab:CreateSection("Rods")

local rodList = {}
for _, id in ipairs(FishingRods.Order) do
    local r = FishingRods.Rods[id]
    if r then table.insert(rodList, r.Display .. " [" .. id .. "]") end
end

GearTab:CreateDropdown({
    Name = "Equip Rod",
    Options = rodList,
    CurrentOption = {},
    Flag = "EquipRod",
    Callback = function(opt)
        local id = opt and opt:match("%[([^%]]+)%]")
        if id then
            safe(function()
                GearService:EquipRod(id):andThen(function(r)
                    if r and r.Success then notify("Equipped: " .. id) end
                end)
            end)
        end
    end,
})

GearTab:CreateToggle({
    Name = "Auto Equip Best Rod",
    CurrentValue = false,
    Flag = "BestRod",
    Callback = function(v) CFG.AutoEquipBestRod = v end,
})

GearTab:CreateSection("Magnets")

local magList = {}
for _, id in ipairs(Magnets.Order) do
    local m = Magnets.Magnets[id]
    if m then table.insert(magList, m.Display .. " [" .. id .. "]") end
end

GearTab:CreateDropdown({
    Name = "Equip Magnet",
    Options = magList,
    CurrentOption = {},
    Flag = "EquipMag",
    Callback = function(opt)
        local id = opt and opt:match("%[([^%]]+)%]")
        if id then
            safe(function()
                GearService:EquipMagnet(id):andThen(function(r)
                    if r and r.Success then notify("Equipped: " .. id) end
                end)
            end)
        end
    end,
})

GearTab:CreateToggle({
    Name = "Auto Equip Best Magnet",
    CurrentValue = false,
    Flag = "BestMag",
    Callback = function(v) CFG.AutoEquipBestMag = v end,
})

GearTab:CreateSection("Container")

GearTab:CreateToggle({
    Name = "Auto Open Container",
    CurrentValue = false,
    Flag = "AutoContainer",
    Callback = function(v) CFG.AutoContainer = v end,
})

GearTab:CreateButton({
    Name = "📦 Toggle Container Panel",
    Callback = function()
        safe(function() ContainerController:Toggle() end)
    end,
})

GearTab:CreateSection("Shop")

GearTab:CreateButton({
    Name = "🛒 Open Rod Shop",
    Callback = function()
        safe(function() GearShopController:SetOpen(true, "Rods") end)
    end,
})

GearTab:CreateButton({
    Name = "🧲 Open Magnet Shop",
    Callback = function()
        safe(function() GearShopController:SetOpen(true, "Magnets") end)
    end,
})

GearTab:CreateButton({
    Name = "⏫ Open Upgrade Shop",
    Callback = function()
        safe(function() GearShopController:SetOpen(true, "Upgrades") end)
    end,
})

-- ══════════════════════════════════════════════════════════
-- TAB 4: CRAFTING
-- ══════════════════════════════════════════════════════════
local CraftTab = Window:CreateTab("🔮 Crafting", 4483362458)

CraftTab:CreateSection("Aura Auto")

CraftTab:CreateToggle({
    Name = "Auto Craft Aura",
    CurrentValue = false,
    Flag = "AutoCraft",
    Callback = function(v) CFG.AutoCraftAura = v end,
})

CraftTab:CreateToggle({
    Name = "Auto Track Aura",
    CurrentValue = false,
    Flag = "AutoTrack",
    Callback = function(v) CFG.AutoTrackAura = v end,
})

local auraList = {}
for _, a in ipairs(AuraCrafting.Order) do
    table.insert(auraList, a.Name .. " [" .. a.Id .. "]")
end

CraftTab:CreateDropdown({
    Name = "Preferred Aura",
    Options = auraList,
    CurrentOption = { "Genesis [Genesis]" },
    Flag = "PrefAura",
    Callback = function(opt)
        local id = opt and opt:match("%[([^%]]+)%]")
        if id then CFG.PreferredAura = id end
    end,
})

CraftTab:CreateSection("Manual Craft")

for _, aura in ipairs(AuraCrafting.Order) do
    CraftTab:CreateButton({
        Name = ("Craft %s"):format(aura.Name),
        Callback = function()
            safe(function()
                CraftingService:Craft(aura.Id):andThen(function(r)
                    notify(r and r.Success and ("Crafted " .. aura.Name) or ("Gagal " .. aura.Name))
                end)
            end)
        end,
    })
end

CraftTab:CreateButton({
    Name = "🎨 Open Crafting UI",
    Callback = function()
        safe(function() CraftingController:SetOpen(true) end)
    end,
})

-- ══════════════════════════════════════════════════════════
-- TAB 5: EVENTS
-- ══════════════════════════════════════════════════════════
local EventTab = Window:CreateTab("🎆 Events", 4483362458)

EventTab:CreateSection("Potion")

EventTab:CreateToggle({
    Name = "Auto Use Potion",
    CurrentValue = false,
    Flag = "AutoPotion",
    Callback = function(v) CFG.AutoPotion = v end,
})

EventTab:CreateDropdown({
    Name = "Potion Type",
    Options = FishingConfig.Potions and FishingConfig.Potions.Order or { "Luck5x" },
    CurrentOption = { "Luck5x" },
    Flag = "PotionKey",
    Callback = function(opt) CFG.PotionKey = opt[1] end,
})

EventTab:CreateButton({
    Name = "🧪 Use Potion Now",
    Callback = function()
        safe(function()
            PotionService:UsePotion(CFG.PotionKey):andThen(function(r)
                if r and r.Success then notify("Potion used: " .. CFG.PotionKey) end
            end)
        end)
    end,
})

EventTab:CreateSection("Meteor Shower")

EventTab:CreateToggle({
    Name = "Auto Trigger Meteor (Admin)",
    CurrentValue = false,
    Flag = "AutoMeteor",
    Callback = function(v) CFG.AutoMeteor = v end,
})

EventTab:CreateSection("Variant Events")

EventTab:CreateToggle({
    Name = "Auto Trigger Variant (Admin)",
    CurrentValue = false,
    Flag = "AutoVariant",
    Callback = function(v) CFG.AutoVariant = v end,
})

EventTab:CreateSection("Shop")

EventTab:CreateButton({
    Name = "💎 Open Robux Shop",
    Callback = function()
        safe(function() RobuxShopController:SetOpen(true) end)
    end,
})

EventTab:CreateButton({
    Name = "🎁 Starter Pack State",
    Callback = function()
        safe(function()
            StarterPackService:GetState():andThen(function()
                notify("Starter Pack loaded.")
            end)
        end)
    end,
})

-- ══════════════════════════════════════════════════════════
-- TAB 6: TELEPORT
-- ══════════════════════════════════════════════════════════
local TpTab = Window:CreateTab("🌀 Teleport", 4483362458)

TpTab:CreateSection("Fishing Stands")

local function tpToStand(standName)
    local stands = workspace:FindFirstChild("FishingStands")
    if not stands then return false end
    local stand = stands:FindFirstChild(standName)
    if not stand then return false end

    local keeper = stand:FindFirstChild("ShopKeeper")
    local target = (keeper and (keeper:FindFirstChild("Torso")
        or keeper:FindFirstChildWhichIsA("BasePart", true)))
        or stand:FindFirstChildWhichIsA("BasePart", true)
    if not target then return false end

    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local goal = target.Position + target.CFrame.LookVector * 8
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { char, stand }
    local hit = workspace:Raycast(goal + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0), params)
    local y = hit and hit.Position.Y or target.Position.Y

    hrp.CFrame = CFrame.new(Vector3.new(goal.X, y + 3, goal.Z),
        Vector3.new(target.Position.X, y + 3, target.Position.Z))
    return true
end

for _, standName in ipairs({ "RodStand", "SellStand", "MagnetStand" }) do
    TpTab:CreateButton({
        Name = "TP → " .. standName,
        Callback = function()
            local ok = tpToStand(standName)
            notify(ok and ("TP ke " .. standName) or "Gagal TP")
        end,
    })
end

TpTab:CreateSection("Bridge")

TpTab:CreateButton({
    Name = "🌉 TP to Nearest Bridge",
    Callback = function()
        local ok = tpToBridge()
        notify(ok and "TP ke bridge!" or "Bridge tidak ditemukan.")
    end,
})

TpTab:CreateSection("Player")

local playerOptions = {}
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then table.insert(playerOptions, p.Name) end
end

TpTab:CreateDropdown({
    Name = "Teleport Ke Player",
    Options = playerOptions,
    CurrentOption = {},
    Flag = "TpPlayer",
    Callback = function(opt)
        local target = Players:FindFirstChild(opt)
        if target and target.Character and LP.Character then
            local thrp = target.Character:FindFirstChild("HumanoidRootPart")
            local mhrp = LP.Character:FindFirstChild("HumanoidRootPart")
            if thrp and mhrp then
                mhrp.CFrame = thrp.CFrame * CFrame.new(0, 0, -4)
                notify("TP ke " .. target.Name)
            end
        end
    end,
})

TpTab:CreateSection("World")

TpTab:CreateButton({
    Name = "🏠 TP Ke Spawn",
    Callback = function()
        local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
        if spawn and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            LP.Character.HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
            notify("TP ke spawn.")
        end
    end,
})

-- ══════════════════════════════════════════════════════════
-- TAB 7: PLAYER / MISC
-- ══════════════════════════════════════════════════════════
local PlayerTab = Window:CreateTab("👤 Player", 4483362458)

PlayerTab:CreateSection("Auto Utility")

PlayerTab:CreateToggle({
    Name = "Auto Favourite Item",
    CurrentValue = false,
    Flag = "AutoFav",
    Callback = function(v) CFG.AutoFavourite = v end,
})

PlayerTab:CreateToggle({
    Name = "Auto Skip Tutorial",
    CurrentValue = false,
    Flag = "AutoSkipTut",
    Callback = function(v) CFG.AutoSkipTutorial = v end,
})

PlayerTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = true,
    Flag = "AntiAFK",
    Callback = function(v) CFG.AntiAFK = v end,
})

PlayerTab:CreateSection("Visual")

PlayerTab:CreateToggle({
    Name = "FPS Boost",
    CurrentValue = false,
    Flag = "FPSBoost",
    Callback = function(v)
        CFG.FPSBoost = v
        if v then
            Runtime.BrightnessBackup.GlobalShadows = Lighting.GlobalShadows
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 100000
            pcall(function() settings().Rendering.QualityLevel = 1 end)
        else
            Lighting.GlobalShadows = Runtime.BrightnessBackup.GlobalShadows
            pcall(function() settings().Rendering.QualityLevel = 10 end)
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "Full Bright",
    CurrentValue = false,
    Flag = "FullBright",
    Callback = function(v)
        CFG.FullBright = v
        if v then
            Runtime.BrightnessBackup.Ambient    = Lighting.Ambient
            Runtime.BrightnessBackup.OutdoorAmb = Lighting.OutdoorAmbient
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        else
            Lighting.Ambient    = Runtime.BrightnessBackup.Ambient or Lighting.Ambient
            Lighting.OutdoorAmb = Runtime.BrightnessBackup.OutdoorAmb or Lighting.OutdoorAmbient
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "No Fog",
    CurrentValue = false,
    Flag = "NoFog",
    Callback = function(v)
        CFG.NoFog = v
        if v then
            Runtime.BrightnessBackup.FogEnd   = Lighting.FogEnd
            Runtime.BrightnessBackup.FogStart = Lighting.FogStart
            Lighting.FogEnd = 1e6
            Lighting.FogStart = 1e6
        else
            Lighting.FogEnd   = Runtime.BrightnessBackup.FogEnd or Lighting.FogEnd
            Lighting.FogStart = Runtime.BrightnessBackup.FogStart or Lighting.FogStart
        end
    end,
})

PlayerTab:CreateSection("Server Info")

local ServerInfo = PlayerTab:CreateParagraph({
    Title = "Server Info",
    Content = "Loading...",
})

task.spawn(function()
    while task.wait(2) do
        pcall(function()
            ServerInfo:Set({
                Title = "Server Info",
                Content = string.format(
                    "Place ID : %d\nJob ID   : %s\nPlayers  : %d\nPing     : %.0f ms",
                    game.PlaceId,
                    game.JobId:sub(1, 12) .. "...",
                    #Players:GetPlayers(),
                    LP:GetNetworkPing() * 1000
                ),
            })
        end)
    end
end)

-- ══════════════════════════════════════════════════════════
-- TAB 8: STATS
-- ══════════════════════════════════════════════════════════
local StatsTab = Window:CreateTab("📊 Stats", 4483362458)

local LiveStats = StatsTab:CreateParagraph({
    Title = "Live Player Status",
    Content = "Menunggu data...",
})

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local d = getFishData()
            local luck = FC._baseLuck or 1
            local slots, cap = invCount()
            local cash = math.floor(LP:GetAttribute("CashRaw") or 0)

            LiveStats:Set({
                Title = "Live Player Status",
                Content = string.format(
                    "State    : %s\nSlots    : %d / %d\nLuck     : x%.2f\nCash     : $%s\nContainers: %d",
                    tostring(FC._state),
                    slots, cap,
                    luck,
                    FormatNumber.Short(cash),
                    #(d and d.Containers or {})
                ),
            })
        end)
    end
end)

-- ══════════════════════════════════════════════════════════
-- TAB 9: SETTINGS
-- ══════════════════════════════════════════════════════════
local SetTab = Window:CreateTab("🔧 Settings", 4483362458)

SetTab:CreateSection("Quick Actions")

SetTab:CreateButton({
    Name = "✅ Enable Semua Auto",
    Callback = function()
        CFG.AutoFish = true
        CFG.AutoCast, CFG.AutoTPBridge = true, true
        CFG.AutoDrop = true
        CFG.AutoPick, CFG.AutoLockPicks = true, true
        CFG.AutoReel, CFG.ForceTrueResult = true, true
        CFG.AutoTap = true
        CFG.AutoTapCircle, CFG.AutoTapRadar = true, true
        CFG.AutoTapCeremony, CFG.AutoTapDrop = true, true
        CFG.AutoSell = true
        CFG.AutoIndex, CFG.AutoContainer, CFG.AutoQuest = true, true, true
        CFG.AutoUpgrade = true
        CFG.AutoCraftAura, CFG.AutoTrackAura = true, true
        CFG.AutoPotion = true
        CFG.AutoOfflineClaim = true
        CFG.AutoFavourite = true
        if not Runtime.RemoteHooked then tryHookReelResult() end
        notify("✅ Semua auto ENABLED!")
    end,
})

SetTab:CreateButton({
    Name = "❌ Disable Semua Auto",
    Callback = function()
        CFG.AutoFish = false
        CFG.AutoSell, CFG.AutoIndex, CFG.AutoContainer, CFG.AutoQuest = false, false, false, false
        CFG.AutoUpgrade = false
        CFG.AutoCraftAura, CFG.AutoTrackAura = false, false
        CFG.AutoPotion = false
        CFG.AutoMeteor, CFG.AutoVariant = false, false
        notify("❌ Semua auto DISABLED!")
    end,
})

SetTab:CreateKeybind({
    Name = "Toggle Master (Auto Fish)",
    CurrentKeybind = "RightShift",
    HoldToInteract = false,
    Flag = "KeyMaster",
    Callback = function()
        CFG.AutoFish = not CFG.AutoFish
        notify("Master: " .. (CFG.AutoFish and "ON ✓" or "OFF ✗"))
    end,
})

SetTab:CreateKeybind({
    Name = "Toggle Auto Tap",
    CurrentKeybind = "RightControl",
    HoldToInteract = false,
    Flag = "KeyTap",
    Callback = function()
        CFG.AutoTap = not CFG.AutoTap
        notify("Auto Tap: " .. (CFG.AutoTap and "ON ✓" or "OFF ✗"))
    end,
})

SetTab:CreateKeybind({
    Name = "Toggle Force True Result",
    CurrentKeybind = "RightAlt",
    HoldToInteract = false,
    Flag = "KeyForce",
    Callback = function()
        CFG.ForceTrueResult = not CFG.ForceTrueResult
        notify("Force True: " .. (CFG.ForceTrueResult and "ON ✓" or "OFF ✗"))
        if CFG.ForceTrueResult and not Runtime.RemoteHooked then
            tryHookReelResult()
        end
    end,
})

SetTab:CreateSection("Utility")

SetTab:CreateButton({
    Name = "♻️ Rejoin Server",
    Callback = function()
        safe(function()
            TeleportService:Teleport(game.PlaceId, LP)
        end)
    end,
})

SetTab:CreateButton({
    Name = "🌐 Server Hop",
    Callback = function()
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
        local ok, res = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if ok and res and res.data then
            for _, srv in ipairs(res.data) do
                if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LP)
                    end)
                    return
                end
            end
        end
        notify("Server hop gagal.")
    end,
})

SetTab:CreateButton({
    Name = "🗑️ Destroy UI",
    Callback = function() Rayfield:Destroy() end,
})

-- ══════════════════════════════════════════════════════════
-- ══════════════════════════════════════════════════════════
-- ═══════════════════════ LOGIC LOOPS ═══════════════════════
-- ══════════════════════════════════════════════════════════
-- ══════════════════════════════════════════════════════════

-- Try hook on load
task.spawn(function()
    task.wait(2)
    tryHookReelResult()
end)

-- ═══ PullState Handler ═══
FishingService.PullState:Connect(function(state, data)
    data = data or {}
    if not CFG.AutoFish then return end

    if state == "Snagged" then
        if CFG.AutoPick and CFG.AutoTapRadar then
            task.spawn(AutoTap.RadarBubbles)
        end

    elseif state == "Reveal" and CFG.AutoTapCeremony then
        task.defer(function()
            if FC._ceremonyAdvance then
                safe(FC._ceremonyAdvance)
            end
        end)
    end
end)

-- ═══ LOOP: AUTO CAST + BRIDGE ═══
task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()

        if not (CFG.AutoFish and CFG.AutoCast) then continue end
        if FC._state ~= "Idle" then continue end
        if FC._charging then continue end
        if FC._revealActive then continue end
        if FC._castInFlight then continue end
        if os.clock() < (FC._recastReadyAt or 0) then continue end

        -- Inventory check
        local n, cap = invCount()
        if n >= cap - 1 then
            if CFG.AutoSell then
                safe(function() EconomyService:SellAll() end)
                task.wait(1)
            end
            continue
        end

        -- Bridge check
        if not isOnBridge() then
            if CFG.AutoTPBridge then
                if tpToBridge() then
                    task.wait(0.6)
                end
            end
            continue
        end

        -- Cast!
        safe(function() FC:_beginCharge() end)
        task.wait(CFG.ChargeHoldTime)
        safe(function() FC:_releaseCharge() end)
        task.wait(0.4)
    end
end)

-- ═══ LOOP: AUTO DROP ═══
task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        if not (CFG.AutoFish and CFG.AutoDrop and CFG.AutoTapDrop) then continue end
        if FC._state ~= "Descending" then continue end
        if FC._dropTravelling then continue end
        if LP:GetAttribute("AutoFishOn") then continue end

        AutoTap.DropButton()
        task.wait(CFG.DropDelay)
    end
end)

-- ═══ LOOP: AUTO TAP TAPCIRCLE ═══
task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        if not (CFG.AutoFish and CFG.AutoTap and CFG.AutoTapCircle) then continue end
        if FC._state ~= "Descending" then continue end

        local screen = FC._screen
        if screen then
            local tc = screen:FindFirstChild("TapCircle")
            if tc and tc.Visible then
                for _ = 1, 3 do
                    AutoTap.TapCircle()
                    RunService.Heartbeat:Wait()
                    if FC._state ~= "Descending" then break end
                end
            end
        end
    end
end)

-- ═══ LOOP: AUTO TAP RADAR ═══
task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        if not (CFG.AutoFish and CFG.AutoTap and CFG.AutoTapRadar) then continue end
        if FC._state ~= "Snagged" then continue end

        local overlay = FC._radarOverlay
        if overlay and overlay.Visible then
            AutoTap.RadarBubbles()
        end
    end
end)

-- ═══ LOOP: AUTO TAP CEREMONY ═══
task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        if not (CFG.AutoFish and CFG.AutoTap and CFG.AutoTapCeremony) then continue end
        if FC._revealActive and FC._ceremonyAdvance then
            safe(FC._ceremonyAdvance)
        end
    end
end)

-- ═══ LOOP: AUTO SELL ═══
task.spawn(function()
    while task.wait(1.5) do
        if CFG.AutoFish and CFG.AutoSell then
            local n, cap = invCount()
            if n >= CFG.SellAt then
                safe(function() EconomyService:SellAll() end)
                task.wait(0.5)
            end
        end
    end
end)

-- ═══ LOOP: AUTO INDEX ═══
task.spawn(function()
    while task.wait(15) do
        if CFG.AutoFish and CFG.AutoIndex then
            safe(function()
                IndexService:ClaimAllIndex():andThen(function(r)
                    if r and r.ok and (r.Paid or 0) > 0 then
                        notify(("Index: +$%s"):format(FormatNumber.Short(r.Paid)))
                    end
                end)
            end)
        end
    end
end)

-- ═══ LOOP: AUTO CONTAINER ═══
task.spawn(function()
    while task.wait(3) do
        if CFG.AutoFish and CFG.AutoContainer then
            local d = getFishData()
            if d and d.Containers then
                for i, c in ipairs(d.Containers) do
                    if os.time() >= (c.OpenAt or 0) then
                        safe(function() ContainerService:Open(i) end)
                        task.wait(0.4)
                    end
                end
            end
        end
    end
end)

-- ═══ LOOP: AUTO QUEST ═══
task.spawn(function()
    while task.wait(5) do
        if CFG.AutoFish and CFG.AutoQuest then
            safe(function()
                PeriodicQuestService:GetQuests():andThen(function(payload)
                    if not payload then return end
                    for period, data in pairs(payload) do
                        for _, q in ipairs(data.Quests or {}) do
                            if q.Completed and not q.Claimed then
                                PeriodicQuestService:Claim(period, q.Id)
                                task.wait(0.3)
                            end
                        end
                    end
                end)
            end)
        end
    end
end)

-- ═══ LOOP: AUTO UPGRADE ═══
task.spawn(function()
    while task.wait(15) do
        if CFG.AutoFish and CFG.AutoUpgrade then
            for _, track in ipairs(CFG.UpgradeOrder) do
                safe(function() GearService:BuyUpgrade(track) end)
                task.wait(0.4)
            end
        end
    end
end)

-- ═══ LOOP: AUTO BEST ROD/MAGNET ═══
task.spawn(function()
    while task.wait(3) do
        if CFG.AutoFish then
            local d = getFishData()
            if d then
                if CFG.AutoEquipBestRod then
                    local bestId, bestTier = nil, 0
                    for _, id in ipairs(FishingRods.Order) do
                        if d.Rods and d.Rods[id] then
                            local t = FishingRods.Rods[id].Tier or 0
                            if t > bestTier then bestTier, bestId = t, id end
                        end
                    end
                    if bestId and d.EquippedRod ~= bestId then
                        safe(function() GearService:EquipRod(bestId) end)
                    end
                end
                if CFG.AutoEquipBestMag then
                    local bestId, bestTier = nil, 0
                    for _, id in ipairs(Magnets.Order) do
                        if d.Magnets and d.Magnets[id] then
                            local t = Magnets.Magnets[id].Tier or 0
                            if t > bestTier then bestTier, bestId = t, id end
                        end
                    end
                    if bestId and d.EquippedMagnet ~= bestId then
                        safe(function() GearService:EquipMagnet(bestId) end)
                    end
                end
            end
        end
    end
end)

-- ═══ LOOP: AUTO CRAFT / TRACK ═══
task.spawn(function()
    while task.wait(5) do
        if CFG.AutoFish and CFG.AutoCraftAura then
            local d = getFishData()
            local priv = getPrivate()
            if d and AuraCrafting.Enabled then
                local plan = AuraCrafting.Plan(d, AuraCrafting.ById[CFG.PreferredAura], (priv and priv.Favourites) or {})
                if plan and plan.Ready and os.clock() >= Runtime.CraftCooldown then
                    Runtime.CraftCooldown = os.clock() + 5
                    safe(function() CraftingService:Craft(CFG.PreferredAura) end)
                end
            end
        end
        if CFG.AutoFish and CFG.AutoTrackAura then
            local d = getFishData()
            if d then
                local st = AuraCrafting.State(d)
                if st.Tracked ~= CFG.PreferredAura then
                    safe(function() CraftingService:Track(CFG.PreferredAura) end)
                end
                if st.Owned and st.Owned[CFG.PreferredAura] and st.Equipped ~= CFG.PreferredAura then
                    safe(function() CraftingService:Equip(CFG.PreferredAura) end)
                end
            end
        end
    end
end)

-- ═══ LOOP: AUTO POTION ═══
task.spawn(function()
    while task.wait(3) do
        if CFG.AutoFish and CFG.AutoPotion then
            local cnt = LP:GetAttribute("Potion_" .. CFG.PotionKey) or 0
            local until_ = LP:GetAttribute("PotionUntil_" .. CFG.PotionKey) or 0
            if cnt > 0 and os.time() >= until_ then
                safe(function() PotionService:UsePotion(CFG.PotionKey) end)
                task.wait(2)
            end
        end
    end
end)

-- ═══ LOOP: AUTO METEOR / VARIANT ═══
task.spawn(function()
    while task.wait(60) do
        if CFG.AutoFish and CFG.AutoMeteor then
            safe(function()
                local MS = Knit.GetService("MeteorShowerService")
                MS:Trigger(180, LP.UserId)
            end)
        end
        if CFG.AutoFish and CFG.AutoVariant then
            safe(function()
                local VE = Knit.GetService("VariantEventService")
                VE:ForceEvent("all", 4, 180)
            end)
        end
    end
end)

-- ═══ AUTO OFFLINE CLAIM ═══
task.spawn(function()
    task.wait(4)
    if CFG.AutoOfflineClaim then
        safe(function()
            OfflineCatchService:ClaimWelcomeBack():andThen(function(r)
                if r and r.Success then notify("Offline earnings claimed.") end
            end)
        end)
    end
end)

-- ═══ LOOP: AUTO FAVOURITE ═══
task.spawn(function()
    while task.wait(3) do
        if CFG.AutoFavourite then
            local char = LP.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                local key = tool:GetAttribute("FTV_Key")
                if key and not tool:GetAttribute("FTV_Fav") then
                    safe(function() InventoryToolService:ToggleFavourite(key) end)
                end
            end
        end
    end
end)

-- ═══ LOOP: AUTO SKIP TUTORIAL ═══
task.spawn(function()
    while task.wait(2) do
        if CFG.AutoSkipTutorial then
            safe(function()
                if not (getPrivate() and getPrivate().CompletedTutorial) then
                    Knit.GetService("TutorialService"):Complete()
                end
            end)
        end
    end
end)

-- ═══ ANTI AFK ═══
if Runtime.AntiAFKConn then Runtime.AntiAFKConn:Disconnect() end
Runtime.AntiAFKConn = LP.Idled:Connect(function()
    if CFG.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- ═══════════════════════ READY NOTIFY ═══════════════════════
Rayfield:Notify({
    Title = "🎣 v5.0 Loaded",
    Content = "Force True Result + ALL features restored. RightShift=Master, RightCtrl=Tap, RightAlt=Force",
    Duration = 8,
    Image = 4483362458,
})