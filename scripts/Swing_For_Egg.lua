--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                  SWING FOR EGG 👑 MIZUKAGE                       ║
    ║                     TEAMMIZU EDITION — v1.0                      ║
    ║         WindUI Framework • Full Feature Preserved                ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════
-- [1] ANTI DUPLICATION
-- ═══════════════════════════════════════════════════════════
if getgenv().SwingForEggMizukage then
    return game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Swing For Egg",
        Text  = "UI is already running."
    })
end
getgenv().SwingForEggMizukage = true

-- ═══════════════════════════════════════════════════════════
-- [2] SERVICES
-- ═══════════════════════════════════════════════════════════
local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace    = game:GetService("Workspace")
local Camera       = Workspace.CurrentCamera

local LocalPlayer  = Players.LocalPlayer
if not LocalPlayer then
    repeat task.wait(0.05) until Players.LocalPlayer
    LocalPlayer = Players.LocalPlayer
end

-- ═══════════════════════════════════════════════════════════
-- [3] UI LIBRARY LOADER
-- ═══════════════════════════════════════════════════════════
local WindUI
do
    local success, result = pcall(function()
        return loadstring(game:HttpGet(
            "https://github.com/Footagesus/WindUI/releases/download/1.6.65/main.lua"
        ))()
    end)
    if not success or type(result) ~= "table" then
        success, result = pcall(function()
            return loadstring(game:HttpGet("https://tree-hub.vercel.app/api/UI/WindUI"))()
        end)
        if not success then
            return warn("[Swing For Egg] UI Failed to load.")
        end
    end
    WindUI = result
end

-- ═══════════════════════════════════════════════════════════
-- [4] BRAND & CONSTANTS
-- ═══════════════════════════════════════════════════════════
local BRAND   = "Swing For Egg 👑 Mizukage"
local AUTHOR  = "TEAMMIZU EDITION"
local VERSION = "v1.0.0"
local FOLDER  = "SwingForEgg_Mizukage"

local RARITY_RANK = {
    Common    = 1,
    Uncommon  = 2,
    Rare      = 3,
    Legendary = 4,
    Cosmic    = 5,
    Secret    = 6,
    Eternal   = 7,
    Divine    = 8,
}

local ZONE_DISPLAY = {
    "Zone1 - Green Plains",
    "Zone2 - Lush Forest",
    "Zone3 - Desert Dunes",
    "Zone4 - Crystal Beach",
    "Zone5 - Candy Land",
    "Zone6 - Wild Savanna",
    "Zone7 - Volcano",
    "Zone8 - Dino Valley",
    "Zone9 - Deep Ocean",
    "Zone10 - Alien",
    "Zone11 - Hell",
    "Zone12 - Heaven",
}

local ZONE_SHORT = {
    Zone1  = "Z1",
    Zone2  = "Z2",
    Zone3  = "Z3",
    Zone4  = "Z4",
    Zone5  = "Z5",
    Zone6  = "Z6",
    Zone7  = "Z7",
    Zone8  = "Z8",
    Zone9  = "Z9",
    Zone10 = "Z10",
    Zone11 = "Z11",
    Zone12 = "Z12",
}

local RARITY_LIST = {
    "Common", "Uncommon", "Rare", "Legendary",
    "Cosmic", "Secret", "Eternal", "Divine",
}

-- ═══════════════════════════════════════════════════════════
-- [5] CONFIG & STATE
-- ═══════════════════════════════════════════════════════════
local Config = {
    SelectedEgg       = nil,
    TargetZone        = "Zone1",
    SelectedRarities  = {},
    AutoStealActive   = false,
    AutoRarityActive  = false,
}

local State = {
    EggList  = {},
    ScanBusy = false,
    Stats    = {
        TotalSteals = 0,
        LastEgg     = "Belum Ada",
        StartTime   = os.clock(),
    },
}

-- ═══════════════════════════════════════════════════════════
-- [6] HELPERS
-- ═══════════════════════════════════════════════════════════
local function ParseNumber(str)
    return tonumber(str:match("%d+")) or 0
end

local function GetCFrame(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj.CFrame
    elseif obj:IsA("Model") then
        return (obj.PrimaryPart and obj.PrimaryPart.CFrame) or obj:GetPivot()
    end
    return nil
end

local function GetEggRarity(egg)
    if not egg then return "Common" end

    local nameTag = egg:FindFirstChild("EggNameTag")
    if nameTag then
        local rarityObj = nameTag:FindFirstChild("Rarity")
        if rarityObj then
            if rarityObj:IsA("TextLabel") or rarityObj:IsA("TextBox") then
                if rarityObj.Text ~= "" then return rarityObj.Text end
            elseif rarityObj:IsA("StringValue") then
                if rarityObj.Value ~= "" then return rarityObj.Value end
            else
                local attr = rarityObj:GetAttribute("Text") or rarityObj:GetAttribute("Rarity")
                if attr then return tostring(attr) end
            end
        end
    end

    local eggAttr = egg:GetAttribute("Rarity")
    if eggAttr then return tostring(eggAttr) end

    return "Common"
end

local function FormatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d", m, s)
end

-- ═══════════════════════════════════════════════════════════
-- [7] MOVEMENT & TELEPORT
-- ═══════════════════════════════════════════════════════════
local function TeleportTo(targetCFrame)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.Anchored = true
    hrp.CFrame = targetCFrame
    task.wait(0.05)
    hrp.Anchored = false
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

local function StealEgg(eggObject, eggSpawn)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local baseCF = GetCFrame(eggObject) or GetCFrame(eggSpawn)
    if not baseCF then return end

    TeleportTo(baseCF * CFrame.new(0, 2, 0))
    task.wait(0.1)

    local attempts = 0
    while eggObject and eggObject.Parent and attempts < 30 do
        local prompt = eggObject:FindFirstChildWhichIsA("ProximityPrompt", true)
            or (eggSpawn and eggSpawn:FindFirstChildWhichIsA("ProximityPrompt", true))
        if prompt then
            pcall(fireproximityprompt, prompt)
        end
        task.wait(0.15)
        attempts += 1
    end

    TeleportTo(hrp.CFrame)

    State.Stats.TotalSteals = State.Stats.TotalSteals + 1
    State.Stats.LastEgg = eggObject.Name
end

-- ═══════════════════════════════════════════════════════════
-- [8] EGG SCANNER
-- ═══════════════════════════════════════════════════════════
local function ScanEggs()
    local displayList = {}
    State.EggList = {}

    local eggsFolder = Workspace:FindFirstChild("Eggs")
    if not eggsFolder then
        return { "Gak Ada Egg Spawn" }
    end

    local zoneFolders = eggsFolder:GetChildren()
    table.sort(zoneFolders, function(a, b)
        return ParseNumber(a.Name) < ParseNumber(b.Name)
    end)

    for _, zoneFolder in ipairs(zoneFolders) do
        local zoneLabel = ZONE_SHORT[zoneFolder.Name] or zoneFolder.Name
        for _, eggSpawn in ipairs(zoneFolder:GetChildren()) do
            local spawnedEgg = eggSpawn:FindFirstChild("SpawnedEgg")
            if spawnedEgg then
                local eggName = spawnedEgg:GetAttribute("EggName") or spawnedEgg.Name
                local rarity  = GetEggRarity(spawnedEgg)
                local display = "[" .. zoneLabel .. "] " .. eggName .. " [" .. rarity .. "]"

                table.insert(State.EggList, {
                    DisplayName = display,
                    EggName     = eggName,
                    Rarity      = rarity,
                    SpawnedEgg  = spawnedEgg,
                    EggSpawn    = eggSpawn,
                    ZoneName    = zoneFolder.Name,
                })
                table.insert(displayList, display)
            end
        end
    end

    return #displayList > 0 and displayList or { "Gak Ada Egg Spawn" }
end

local function GetBestEgg()
    if #State.EggList == 0 then return nil end

    local best, bestRank, bestZoneNum = nil, -1, -1

    for _, egg in ipairs(State.EggList) do
        local rank    = RARITY_RANK[egg.Rarity] or 0
        local zoneNum = ParseNumber(egg.ZoneName)

        if rank > bestRank then
            bestZoneNum = zoneNum
            bestRank    = rank
            best        = egg
        elseif rank == bestRank and zoneNum > bestZoneNum then
            bestZoneNum = zoneNum
            best        = egg
        end
    end

    return best
end

-- ═══════════════════════════════════════════════════════════
-- [9] RESET BUTTON (Floating Draggable Rainbow)
-- ═══════════════════════════════════════════════════════════
local ResetGui = Instance.new("ScreenGui")
ResetGui.Name = "SwingForEgg_ResetButton"
ResetGui.ResetOnSpawn = false
ResetGui.Enabled = false
ResetGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local ResetButton = Instance.new("TextButton")
ResetButton.Size = UDim2.new(0, 120, 0, 35)
ResetButton.Position = UDim2.new(0.5, -60, 0.5, -18)
ResetButton.Text = "Reset"
ResetButton.BackgroundColor3 = Color3.fromRGB(255, 69, 58)
ResetButton.TextColor3 = Color3.new(1, 1, 1)
ResetButton.Font = Enum.Font.GothamBold
ResetButton.TextSize = 20
ResetButton.BorderSizePixel = 0
ResetButton.Parent = ResetGui

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 12)
ButtonCorner.Parent = ResetButton

task.spawn(function()
    while true do
        local hue = math.random()
        local color = Color3.fromHSV(hue, 1, 1)
        TweenService:Create(ResetButton, TweenInfo.new(0.5), { BackgroundColor3 = color }):Play()
        task.wait(0.5)
    end
end)

local dragging      = false
local dragged       = false
local clickingBusy  = false
local dragStartPos  = nil
local dragStartUdim = nil

ResetButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging      = true
        dragged       = false
        dragStartPos  = input.Position
        dragStartUdim = ResetButton.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
       or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartPos
        if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
            dragged = true
        end
        local newPos = UDim2.new(
            dragStartUdim.X.Scale,
            dragStartUdim.X.Offset + delta.X,
            dragStartUdim.Y.Scale,
            dragStartUdim.Y.Offset + delta.Y
        )
        TweenService:Create(ResetButton, TweenInfo.new(0.05), { Position = newPos }):Play()
    end
end)

ResetButton.MouseButton1Click:Connect(function()
    if dragged or clickingBusy then return end
    clickingBusy = true
    if LocalPlayer.Character then
        LocalPlayer.Character:BreakJoints()
    end
    task.wait(6)
    clickingBusy = false
end)

-- ═══════════════════════════════════════════════════════════
-- [10] UI INITIALIZATION
-- ═══════════════════════════════════════════════════════════
local Window

local function InitInterface()
    -- ─── Gradient ───
    WindUI:Gradient({
        ["0"]   = { Color = Color3.fromHex("#5c5291"), Transparency = 0.15 },
        ["50"]  = { Color = Color3.fromHex("#0096ff"), Transparency = 0.10 },
        ["100"] = { Color = Color3.fromHex("#18181b"), Transparency = 0 },
    }, { Rotation = 45 })

    -- ─── Window ───
    local viewport = Camera.ViewportSize
    local isMobile = viewport.X < 850

    Window = WindUI:CreateWindow({
        Title        = BRAND,
        Icon         = "lucide:egg",
        Author       = AUTHOR,
        Folder       = FOLDER,
        Size         = isMobile
            and UDim2.fromOffset(viewport.X * 0.95, viewport.Y * 0.95)
            or  UDim2.fromOffset(840, 600),
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
        ScrollBarEnabled = true,

        User = {
            Enabled   = true,
            Anonymous = false,
            Callback  = function()
                WindUI:Notify({
                    Title    = "👤 Player Info",
                    Content  = string.format(
                        "Name: %s\nDisplay: %s\nUserID: %s",
                        LocalPlayer.Name, LocalPlayer.DisplayName, LocalPlayer.UserId
                    ),
                    Duration = 5,
                    Icon     = "lucide:user",
                })
            end,
        },
    })

    -- ─── Tags ───
    Window:Tag({ Title = "👑 MIZUKAGE", Icon = "lucide:crown",    Color = Color3.fromHex("#FFD700"), Radius = 13 })
    Window:Tag({ Title = VERSION,       Icon = "lucide:sparkles", Color = Color3.fromHex("#30ff6a"), Radius = 6 })
    Window:Tag({ Title = "TEAMMIZU",    Icon = "lucide:users",    Color = Color3.fromHex("#0096ff"), Radius = 0 })
    Window:Divider()

    -- ─── Tabs ───
    local TabDash    = Window:Tab({ Title = "Dashboard",    Icon = "lucide:layout-dashboard" })
    local TabManual  = Window:Tab({ Title = "Manual TP",    Icon = "lucide:search" })
    local TabAuto    = Window:Tab({ Title = "Auto Steal",   Icon = "lucide:zap" })
    local TabRarity  = Window:Tab({ Title = "Auto Rarity",  Icon = "lucide:sparkles" })
    local TabUtils   = Window:Tab({ Title = "Utilities",    Icon = "lucide:wrench" })
    local TabSys     = Window:Tab({ Title = "Settings",     Icon = "lucide:settings" })

    -- ═══════════════════════════════════════════════════════════
    -- TAB: DASHBOARD
    -- ═══════════════════════════════════════════════════════════
    TabDash:Section({ Title = "Statistik Sesi" })

    TabDash:Button({
        Title   = "Refresh Statistik",
        Icon    = "lucide:refresh-cw",
        Variant = "Primary",
        Callback = function()
            WindUI:Notify({
                Title    = "📊 Statistik Sesi",
                Content  = string.format(
                    "Total Steals: %d\nEgg Terakhir: %s\nUptime: %s",
                    State.Stats.TotalSteals,
                    State.Stats.LastEgg,
                    FormatTime(os.clock() - State.Stats.StartTime)
                ),
                Duration = 6,
                Icon     = "lucide:bar-chart",
            })
        end,
    })

    TabDash:Divider()
    TabDash:Section({ Title = "Master Control" })

    TabDash:Toggle({
        Title    = "Master Auto Steal (Semua Zone)",
        Flag     = "MasterAutoSteal",
        Default  = false,
        Callback = function(val)
            Config.AutoStealActive  = val
            Config.AutoRarityActive = val

            if val then
                task.spawn(function()
                    while Config.AutoStealActive do
                        local best = GetBestEgg()
                        if best and best.SpawnedEgg then
                            StealEgg(best.SpawnedEgg, best.EggSpawn)
                        end
                        task.wait(0.5)
                    end
                end)
                WindUI:Notify({
                    Title    = "Master Auto",
                    Content  = "Auto steal semua zone aktif.",
                    Duration = 3,
                    Icon     = "lucide:zap",
                })
            else
                WindUI:Notify({
                    Title    = "Master Auto",
                    Content  = "Auto steal nonaktif.",
                    Duration = 3,
                    Icon     = "lucide:power",
                })
            end
        end,
    })

    -- ═══════════════════════════════════════════════════════════
    -- TAB: MANUAL TP
    -- ═══════════════════════════════════════════════════════════
    TabManual:Section({ Title = "Target Egg Selection" })

    local EggDropdown = TabManual:Dropdown({
        Title  = "Select Target Egg",
        Values = ScanEggs(),
        Value  = nil,
        Callback = function(selected)
            for _, egg in ipairs(State.EggList) do
                if egg.DisplayName == selected then
                    Config.SelectedEgg = egg
                    break
                end
            end
        end,
    })

    local function RefreshDropdown()
        if State.ScanBusy then return end
        State.ScanBusy = true

        task.delay(0.2, function()
            local newList = ScanEggs()
            if EggDropdown then
                if EggDropdown.Refresh then
                    EggDropdown:Refresh(newList)
                elseif EggDropdown.SetValues then
                    EggDropdown:SetValues(newList)
                end
            end
            State.ScanBusy = false
        end)
    end

    local EggsFolder = Workspace:FindFirstChild("Eggs")
    if EggsFolder then
        EggsFolder.DescendantAdded:Connect(function(desc)
            if desc.Name == "SpawnedEgg" or desc.Name == "Rarity" then
                RefreshDropdown()
            end
        end)
        EggsFolder.DescendantRemoving:Connect(function(desc)
            if desc.Name == "SpawnedEgg" then
                RefreshDropdown()
            end
        end)
    end

    TabManual:Section({ Title = "Steal Egg" })

    TabManual:Button({
        Title = "Steal Egg",
        Icon  = "lucide:package",
        Callback = function()
            if not Config.SelectedEgg then
                WindUI:Notify({
                    Title    = "Manual TP",
                    Content  = "Pilih egg dulu di dropdown.",
                    Duration = 3,
                    Icon     = "lucide:alert-triangle",
                })
                return
            end
            local spawnedEgg = Config.SelectedEgg.EggSpawn:FindFirstChild("SpawnedEgg")
            if spawnedEgg then
                StealEgg(spawnedEgg, Config.SelectedEgg.EggSpawn)
            end
        end,
    })

    TabManual:Button({
        Title   = "Get & Steal Best Egg",
        Icon    = "lucide:crown",
        Variant = "Primary",
        Callback = function()
            local best = GetBestEgg()
            if best and best.SpawnedEgg then
                StealEgg(best.SpawnedEgg, best.EggSpawn)
            else
                WindUI:Notify({
                    Title    = "Best Egg Finder",
                    Content  = "Tidak ada telur yang terdeteksi!",
                    Duration = 3,
                    Icon     = "lucide:x",
                })
            end
        end,
    })

    -- ═══════════════════════════════════════════════════════════
    -- TAB: AUTO STEAL
    -- ═══════════════════════════════════════════════════════════
    TabAuto:Section({ Title = "Auto Steal" })

    TabAuto:Dropdown({
        Title  = "Select Target Zone",
        Values = ZONE_DISPLAY,
        Value  = "Zone1 - Green Plains",
        Callback = function(selected)
            Config.TargetZone = selected:split(" ")[1]
        end,
    })

    TabAuto:Toggle({
        Title = "Auto Steal Egg",
        Flag  = "AutoStealEgg",
        Value = false,
        Callback = function(enabled)
            Config.AutoStealActive = enabled

            if enabled then
                task.spawn(function()
                    while Config.AutoStealActive do
                        local eggsFolder = Workspace:FindFirstChild("Eggs")
                        local zoneFolder = eggsFolder and eggsFolder:FindFirstChild(Config.TargetZone)

                        if zoneFolder then
                            for _, eggSpawn in ipairs(zoneFolder:GetChildren()) do
                                if not Config.AutoStealActive then break end

                                local spawnedEgg = eggSpawn:FindFirstChild("SpawnedEgg")
                                if spawnedEgg then
                                    StealEgg(spawnedEgg, eggSpawn)
                                end
                            end
                        end

                        task.wait(0.5)
                    end
                end)

                WindUI:Notify({
                    Title    = "Auto Steal",
                    Content  = "Auto steal aktif di " .. Config.TargetZone .. ".",
                    Duration = 3,
                    Icon     = "lucide:zap",
                })
            end
        end,
    })

    -- ═══════════════════════════════════════════════════════════
    -- TAB: AUTO RARITY
    -- ═══════════════════════════════════════════════════════════
    TabRarity:Section({ Title = "Select Target Rarities" })

    TabRarity:Dropdown({
        Title   = "Select Rarities",
        Values  = RARITY_LIST,
        Multi   = true,
        Default = {},
        Callback = function(selected)
            Config.SelectedRarities = selected
        end,
    })

    TabRarity:Section({ Title = "Auto Rarity Control" })

    TabRarity:Toggle({
        Title = "Start Auto Collect by Rarity",
        Flag  = "AutoRarity",
        Value = false,
        Callback = function(enabled)
            Config.AutoRarityActive = enabled

            if enabled then
                task.spawn(function()
                    while Config.AutoRarityActive do
                        local eggsFolder = Workspace:FindFirstChild("Eggs")

                        if eggsFolder then
                            for _, zoneFolder in ipairs(eggsFolder:GetChildren()) do
                                if not Config.AutoRarityActive then break end

                                for _, eggSpawn in ipairs(zoneFolder:GetChildren()) do
                                    if not Config.AutoRarityActive then break end

                                    local spawnedEgg = eggSpawn:FindFirstChild("SpawnedEgg")
                                    if spawnedEgg then
                                        local rarity = GetEggRarity(spawnedEgg)
                                        if table.find(Config.SelectedRarities, rarity) then
                                            StealEgg(spawnedEgg, eggSpawn)
                                        end
                                    end
                                end
                            end
                        end

                        task.wait(0.5)
                    end
                end)

                WindUI:Notify({
                    Title    = "Auto Rarity",
                    Content  = "Auto collect by rarity aktif.",
                    Duration = 3,
                    Icon     = "lucide:sparkles",
                })
            end
        end,
    })

    -- ═══════════════════════════════════════════════════════════
    -- TAB: UTILITIES
    -- ═══════════════════════════════════════════════════════════
    TabUtils:Section({ Title = "Reset Character" })

    TabUtils:Toggle({
        Title = "Enable Reset Character Button",
        Flag  = "EnableResetBtn",
        Value = false,
        Callback = function(enabled)
            ResetGui.Enabled = enabled
        end,
    })

    TabUtils:Section({ Title = "Zone Teleport" })

    TabUtils:Button({
        Title   = "Load Zone 10, 11, 12",
        Icon    = "lucide:globe",
        Variant = "Primary",
        Callback = function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            TeleportTo(CFrame.new(
                13.3948393, 2.99999928, 3729.59253,
                -0.99835062, 1.62008407e-9, -0.057411328,
                2.56459048e-10, 1, 2.3759215e-8,
                0.057411328, 2.37053026e-8, -0.99835062
            ))

            task.wait(3)
            TeleportTo(hrp.CFrame)
        end,
    })

    -- ═══════════════════════════════════════════════════════════
    -- TAB: SETTINGS
    -- ═══════════════════════════════════════════════════════════
    TabSys:Section({ Title = "Manajemen Script" })

    TabSys:Button({
        Title   = "Refresh Egg List Sekarang",
        Icon    = "lucide:refresh-cw",
        Variant = "Secondary",
        Callback = function()
            local count = #ScanEggs()
            WindUI:Notify({
                Title    = "Egg Scanner",
                Content  = "Ditemukan " .. tostring(count) .. " egg spawn.",
                Duration = 3,
                Icon     = "lucide:check",
            })
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
                            Config.AutoStealActive  = false
                            Config.AutoRarityActive = false
                            ResetGui.Enabled = false

                            if getgenv() then getgenv().SwingForEggMizukage = nil end

                            WindUI:Notify({
                                Title    = BRAND,
                                Content  = "Script dinonaktifkan.",
                                Duration = 3,
                                Icon     = "lucide:heart",
                            })
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

    -- ═══════════════════════════════════════════════════════════
    -- WELCOME POPUP
    -- ═══════════════════════════════════════════════════════════
    task.wait(0.5)
    WindUI:Popup({
        Title   = "Selamat Datang 👑",
        Icon    = "lucide:egg",
        Content = "🥚 Swing For Egg 👑 Mizukage siap!\n\n👑 TEAMMIZU EDITION\n⚙️ Version: " .. VERSION .. "\n🥚 Manual TP & Best Egg Finder\n⚡ Auto Steal per Zone\n✨ Auto Collect by Rarity\n🛠️ Reset Button & Zone Teleport\n\nSelamat bermain!",
        Buttons = {
            {
                Title    = "Tutup",
                Variant  = "Tertiary",
                Callback = function() end,
            },
            {
                Title   = "Mulai Auto Steal",
                Icon    = "lucide:zap",
                Variant = "Primary",
                Callback = function()
                    Config.AutoStealActive = true
                    task.spawn(function()
                        while Config.AutoStealActive do
                            local best = GetBestEgg()
                            if best and best.SpawnedEgg then
                                StealEgg(best.SpawnedEgg, best.EggSpawn)
                            end
                            task.wait(0.5)
                        end
                    end)
                    WindUI:Notify({
                        Title    = "Master Auto",
                        Content  = "Auto steal aktif.",
                        Duration = 3,
                        Icon     = "lucide:zap",
                    })
                end,
            },
        },
    })
end

task.spawn(InitInterface)

-- ═══════════════════════════════════════════════════════════
-- [11] BOOTSTRAP
-- ═══════════════════════════════════════════════════════════
print("[Swing For Egg 👑 Mizukage] " .. VERSION .. " loaded")

-- ═══════════════════════════════════════════════════════════
-- [12] UNLOAD EXPORT
-- ═══════════════════════════════════════════════════════════
getgenv().SwingForEggMizukageUnload = function()
    Config.AutoStealActive  = false
    Config.AutoRarityActive = false
    ResetGui.Enabled = false
    getgenv().SwingForEggMizukage = nil
end