--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                    EGG COLLECTOR 👑 MIZUKAGE                     ║
    ║                     TEAMMIZU EDITION — v1.0                      ║
    ║         WindUI Framework • Full Feature Preserved                ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════
-- [1] ANTI DUPLICATION
-- ═══════════════════════════════════════════════════════════
if getgenv().EggCollectorMizukage then
    return game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Egg Collector",
        Text  = "UI is already running."
    })
end
getgenv().EggCollectorMizukage = true

-- ═══════════════════════════════════════════════════════════
-- [2] SERVICES
-- ═══════════════════════════════════════════════════════════
local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Camera    = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
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
            return warn("[Egg Collector] UI Failed to load.")
        end
    end
    WindUI = result
end

-- ═══════════════════════════════════════════════════════════
-- [4] BRAND & CONSTANTS
-- ═══════════════════════════════════════════════════════════
local BRAND   = "Egg Collector 👑 Mizukage"
local AUTHOR  = "TEAMMIZU EDITION"
local VERSION = "v1.0.0"
local FOLDER  = "EggCollector_Mizukage"

local SPAWN_CFRAME = CFrame.new(
    678.355652, 64.5001678, -647.315857,
    -0.206779853, 9.45582954e-8, 0.978387475,
    6.59558141e-9, 1, -9.52531209e-8,
    -0.978387475, -1.32433922e-8, -0.206779853
)

local RARITY_RANK = {
    Common    = 1,
    Uncommon  = 2,
    Rare      = 3,
    Epic      = 4,
    Legendary = 5,
    Mythical  = 6,
    Godly     = 7,
}

-- ═══════════════════════════════════════════════════════════
-- [5] STATE
-- ═══════════════════════════════════════════════════════════
local State = {
    SelectedEgg   = nil,
    BestEgg       = nil,
    BiggestEgg    = nil,
    EggGroups     = {},
    RarityMap     = {},
    RefreshBusy   = false,
    Stats = {
        TotalPickups = 0,
        StartTime    = os.clock(),
    },
}

-- ═══════════════════════════════════════════════════════════
-- [6] ZONE EGG FOLDER
-- ═══════════════════════════════════════════════════════════
local ZoneEggs
do
    ZoneEggs = Workspace:FindFirstChild("ZoneEggs")
    if not ZoneEggs then
        ZoneEggs = Workspace:WaitForChild("ZoneEggs", 10)
    end
    if not ZoneEggs then
        return warn("[Egg Collector] ZoneEggs folder tidak ditemukan.")
    end
end

-- ═══════════════════════════════════════════════════════════
-- [7] HELPERS
-- ═══════════════════════════════════════════════════════════
local function GetSpecies(egg)
    if not egg then return "" end
    local species = egg:GetAttribute("Species")
    if species and tostring(species) ~= "" then
        return tostring(species)
    end
    return egg.Name
end

local function NormalizeKey(str)
    if not str then return "" end
    return string.lower(string.gsub(tostring(str), "[%s%_%-]", ""))
end

local function GetBasePart(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then return obj end
    if obj.PrimaryPart then return obj.PrimaryPart end
    return obj:FindFirstChildWhichIsA("BasePart", true)
end

local function FormatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d", m, s)
end

-- ═══════════════════════════════════════════════════════════
-- [8] EGG LIST
-- ═══════════════════════════════════════════════════════════
local function GetEggList()
    local list = {}
    for _, obj in ipairs(ZoneEggs:GetChildren()) do
        if obj.Parent and not obj:IsA("Folder")
           and (obj:IsA("Model") or obj:IsA("BasePart")) then
            table.insert(list, obj)
        end
    end
    return list
end

-- ═══════════════════════════════════════════════════════════
-- [9] RARITY MAP
-- ═══════════════════════════════════════════════════════════
local function RebuildRarityMap()
    table.clear(State.RarityMap)

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local mainUI    = playerGui and playerGui:FindFirstChild("MainUI")
    local frames    = mainUI and mainUI:FindFirstChild("Frames")
    local index     = frames and frames:FindFirstChild("Index")
    local content   = index and index:FindFirstChild("Content")
    local scrolling = content and content:FindFirstChild("ScrollingFrame")

    if not scrolling then return end

    for i = 1, 8 do
        local zone = scrolling:FindFirstChild("Zone" .. i)
        if zone and zone:FindFirstChild("Content") then
            for _, item in ipairs(zone.Content:GetChildren()) do
                local applied = item:GetAttribute("AppliedRarity")
                if applied then
                    State.RarityMap[NormalizeKey(item.Name)] = applied
                end
            end
        end
    end
end

local function GetRarity(eggName)
    if not next(State.RarityMap) then
        RebuildRarityMap()
    end
    return State.RarityMap[NormalizeKey(eggName)] or "Common"
end

-- ═══════════════════════════════════════════════════════════
-- [10] EGG DETAILS
-- ═══════════════════════════════════════════════════════════
local function GetEggDetails(egg)
    if not egg or not egg.Parent then
        return "Tidak Ada Egg", "Tidak ada telur di map saat ini."
    end

    local species  = GetSpecies(egg)
    local mutation = egg:GetAttribute("Mutation") or "Normal"
    local scale    = egg:GetAttribute("ItemScale")
    local rarity   = GetRarity(species)

    return species, string.format(
        "Rarity: %s\nMutation: %s\nWeight / Scale: %.2f",
        rarity, mutation, scale or 1
    )
end

-- ═══════════════════════════════════════════════════════════
-- [11] BEST & BIGGEST SCANNER
-- ═══════════════════════════════════════════════════════════
local function ScanBestAndBiggest()
    local bestRank, biggestScale = -1, -1
    local best, biggest = nil, nil

    for _, egg in ipairs(GetEggList()) do
        local rank  = RARITY_RANK[GetRarity(GetSpecies(egg))] or 1
        local scale = egg:GetAttribute("ItemScale") or 0

        if rank > bestRank then
            bestRank = rank
            best     = egg
        end

        if scale > biggestScale then
            biggestScale = scale
            biggest      = egg
        end
    end

    State.BestEgg    = best
    State.BiggestEgg = biggest
end

-- ═══════════════════════════════════════════════════════════
-- [12] PICKUP ENGINE
-- ═══════════════════════════════════════════════════════════
local function PickupEgg(egg)
    if not egg or not egg.Parent then return end

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
        or char:WaitForChild("HumanoidRootPart", 2)
    if not hrp then return end

    local base = GetBasePart(egg)
    if not base then return end

    local targetCF = base.CFrame * CFrame.new(0, 2, 0)
    hrp.AssemblyLinearVelocity = Vector3.zero

    if char.PivotTo then
        char:PivotTo(targetCF)
    else
        hrp.CFrame = targetCF
    end

    task.wait(0.05)

    local attempts = 0
    while egg and egg.Parent and attempts < 20 do
        local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            pcall(fireproximityprompt, prompt)
        end

        local clickDet = egg:FindFirstChildWhichIsA("ClickDetector", true)
        if clickDet then
            pcall(fireclickdetector, clickDet)
        end

        task.wait(0.1)
        attempts = attempts + 1
    end

    if hrp and hrp.Parent then
        hrp.AssemblyLinearVelocity = Vector3.zero
        if char.PivotTo then
            char:PivotTo(SPAWN_CFRAME)
        else
            hrp.CFrame = SPAWN_CFRAME
        end
    end

    State.Stats.TotalPickups = State.Stats.TotalPickups + 1
end

-- ═══════════════════════════════════════════════════════════
-- [13] UI INITIALIZATION
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
            or  UDim2.fromOffset(800, 580),
        MinSize      = Vector2.new(560, 420),
        MaxSize      = Vector2.new(950, 750),
        ToggleKey    = Enum.KeyCode.RightShift,
        Transparent  = true,
        Theme        = "Dark",
        Accent       = Color3.fromRGB(92, 82, 145),
        Resizable    = true,
        SideBarWidth = isMobile and 220 or 240,
        HasOutline   = true,
        BackgroundImageTransparency = 0.42,
        Background   = "rbxassetid://137490169052447",
        ScrollBarEnabled = true,

        User = {
            Enabled   = true,
            Anonymous = false,
            Callback  = function()
                WindUI:Notify({
                    Title    = "Player Info",
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
    Window:Tag({ Title = "MIZUKAGE", Icon = "lucide:crown",    Color = Color3.fromHex("#FFD700"), Radius = 13 })
    Window:Tag({ Title = VERSION,   Icon = "lucide:sparkles", Color = Color3.fromHex("#30ff6a"), Radius = 6 })
    Window:Tag({ Title = "TEAMMIZU", Icon = "lucide:users",   Color = Color3.fromHex("#0096ff"), Radius = 0 })
    Window:Divider()

    -- ─── Tabs ───
    local TabDash = Window:Tab({ Title = "Dashboard",  Icon = "lucide:layout-dashboard" })
    local TabEgg  = Window:Tab({ Title = "Egg Options", Icon = "lucide:egg" })
    local TabSys  = Window:Tab({ Title = "Settings",   Icon = "lucide:settings" })

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
                Title    = "Statistik Sesi",
                Content  = string.format(
                    "Total Pickups: %d\nUptime: %s",
                    State.Stats.TotalPickups,
                    FormatTime(os.clock() - State.Stats.StartTime)
                ),
                Duration = 6,
                Icon     = "lucide:bar-chart",
            })
        end,
    })

    -- ═══════════════════════════════════════════════════════════
    -- TAB: EGG OPTIONS
    -- ═══════════════════════════════════════════════════════════
    TabEgg:Section({ Title = "Egg Selector" })

    local EggDropdown
    local SelectedDetail

    EggDropdown = TabEgg:Dropdown({
        Title  = "Select Egg",
        Values = { "Loading Eggs..." },
        Value  = nil,
        Callback = function(selected)
            local group = State.EggGroups[selected]
            if group and #group > 0 then
                State.SelectedEgg = group[1]
            else
                State.SelectedEgg = nil
            end

            if SelectedDetail then
                local species, desc = GetEggDetails(State.SelectedEgg)
                SelectedDetail:SetTitle("Detail Selected: " .. species)
                SelectedDetail:SetDesc(desc)
            end
        end,
    })

    SelectedDetail = TabEgg:Paragraph({
        Title = "Tidak Ada Telur Dipilih",
        Desc  = "Silakan pilih telur dari dropdown di atas.",
    })

    TabEgg:Button({
        Title   = "Pickup Selected Egg",
        Icon    = "lucide:hand",
        Variant = "Primary",
        Callback = function()
            if State.SelectedEgg and State.SelectedEgg.Parent then
                task.spawn(function()
                    PickupEgg(State.SelectedEgg)
                end)
            else
                WindUI:Notify({
                    Title    = BRAND,
                    Content  = "Pilih telur dulu dari dropdown!",
                    Duration = 3,
                    Icon     = "lucide:alert-triangle",
                })
            end
        end,
    })

    TabEgg:Divider()
    TabEgg:Section({ Title = "Best & Biggest Egg (Real-Time)" })

    local BestDetail, BiggestDetail

    TabEgg:Button({
        Title   = "Get Best Egg",
        Icon    = "lucide:crown",
        Variant = "Primary",
        Callback = function()
            if State.BestEgg and State.BestEgg.Parent then
                task.spawn(function()
                    PickupEgg(State.BestEgg)
                end)
            else
                WindUI:Notify({
                    Title    = BRAND,
                    Content  = "Tidak ada Best Egg di map saat ini!",
                    Duration = 3,
                    Icon     = "lucide:x",
                })
            end
        end,
    })

    BestDetail = TabEgg:Paragraph({
        Title = "Best Egg: Scanning...",
    })

    TabEgg:Button({
        Title   = "Get Biggest Egg",
        Icon    = "lucide:trending-up",
        Variant = "Primary",
        Callback = function()
            if State.BiggestEgg and State.BiggestEgg.Parent then
                task.spawn(function()
                    PickupEgg(State.BiggestEgg)
                end)
            else
                WindUI:Notify({
                    Title    = BRAND,
                    Content  = "Tidak ada Biggest Egg di map saat ini!",
                    Duration = 3,
                    Icon     = "lucide:x",
                })
            end
        end,
    })

    BiggestDetail = TabEgg:Paragraph({
        Title = "Biggest Egg: Scanning...",
    })

    -- ═══════════════════════════════════════════════════════════
    -- REFRESH HANDLER
    -- ═══════════════════════════════════════════════════════════
    local function RefreshEggList()
        if State.RefreshBusy then return end
        State.RefreshBusy = true

        task.delay(0.5, function()
            -- Bangun grup egg
            State.EggGroups = {}
            local groupedKeys = {}

            for _, egg in ipairs(GetEggList()) do
                local species  = GetSpecies(egg)
                local rarity   = GetRarity(species)
                local groupKey = species .. " [" .. rarity .. "]"

                if not State.EggGroups[groupKey] then
                    State.EggGroups[groupKey] = {}
                end
                table.insert(State.EggGroups[groupKey], egg)
            end

            -- Build sorted display
            local display = {}
            for key, list in pairs(State.EggGroups) do
                local label = string.format("%s (%d)", key, #list)
                groupedKeys[label] = list
                table.insert(display, label)
            end
            table.sort(display)

            if #display == 0 then
                display = { "No Eggs Available" }
            end

            -- Refresh dropdown
            if EggDropdown then
                if EggDropdown.Refresh then
                    EggDropdown:Refresh(display)
                elseif EggDropdown.SetValues then
                    EggDropdown:SetValues(display)
                end
            end

            -- Scan best & biggest
            ScanBestAndBiggest()

            if BestDetail then
                local species, desc = GetEggDetails(State.BestEgg)
                BestDetail:SetTitle("Best Egg: " .. species)
                BestDetail:SetDesc(desc)
            end

            if BiggestDetail then
                local species, desc = GetEggDetails(State.BiggestEgg)
                BiggestDetail:SetTitle("Biggest Egg: " .. species)
                BiggestDetail:SetDesc(desc)
            end

            State.RefreshBusy = false
        end)
    end

    -- ─── Init scan ───
    RebuildRarityMap()
    RefreshEggList()

    -- ─── Auto refresh saat ada perubahan ───
    ZoneEggs.ChildAdded:Connect(function()
        RefreshEggList()
    end)

    ZoneEggs.ChildRemoved:Connect(function(child)
        if State.SelectedEgg == child then
            State.SelectedEgg = nil
            if SelectedDetail then
                SelectedDetail:SetTitle("Tidak Ada Telur Dipilih")
                SelectedDetail:SetDesc("Silakan pilih telur dari dropdown di atas.")
            end
        end
        RefreshEggList()
    end)

    -- ═══════════════════════════════════════════════════════════
    -- TAB: SETTINGS
    -- ═══════════════════════════════════════════════════════════
    TabSys:Section({ Title = "Manajemen Script" })

    TabSys:Button({
        Title   = "Force Refresh Egg List",
        Icon    = "lucide:refresh-cw",
        Variant = "Secondary",
        Callback = function()
            RebuildRarityMap()
            RefreshEggList()
            WindUI:Notify({
                Title    = "Egg List",
                Content  = "Refresh dipaksa.",
                Duration = 3,
                Icon     = "lucide:check",
            })
        end,
    })

    TabSys:Button({
        Title   = "Reset Statistik",
        Icon    = "lucide:rotate-ccw",
        Variant = "Secondary",
        Callback = function()
            State.Stats.TotalPickups = 0
            State.Stats.StartTime = os.clock()
            WindUI:Notify({
                Title    = "Statistik",
                Content  = "Statistik direset.",
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
                            if getgenv() then getgenv().EggCollectorMizukage = nil end

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
        Content = "Egg Collector 👑 Mizukage siap!\n\nTEAMMIZU EDITION\nVersion: " .. VERSION .. "\n\nEgg Selector\nBest & Biggest Egg\nStatistik Sesi\n\nSelamat bermain!",
        Buttons = {
            {
                Title    = "Tutup",
                Variant  = "Tertiary",
                Callback = function() end,
            },
            {
                Title   = "Mulai",
                Icon    = "lucide:play",
                Variant = "Primary",
                Callback = function()
                    WindUI:Notify({
                        Title    = BRAND,
                        Content  = "Silakan pilih telur di tab Egg Options.",
                        Duration = 3,
                        Icon     = "lucide:check",
                    })
                end,
            },
        },
    })
end

task.spawn(InitInterface)

-- ═══════════════════════════════════════════════════════════
-- [14] BOOTSTRAP
-- ═══════════════════════════════════════════════════════════
print("[Egg Collector 👑 Mizukage] " .. VERSION .. " loaded")

-- ═══════════════════════════════════════════════════════════
-- [15] UNLOAD EXPORT
-- ═══════════════════════════════════════════════════════════
getgenv().EggCollectorMizukageUnload = function()
    getgenv().EggCollectorMizukage = nil
end