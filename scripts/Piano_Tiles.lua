--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                    PIANO TILES 👑 MIZUKAGE                       ║
    ║                     TEAMMIZU EDITION — v1.0                      ║
    ║         WindUI Framework • Full Feature Preserved                ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════
-- [1] ANTI DUPLICATION
-- ═══════════════════════════════════════════════════════════
if getgenv().PianoTilesMizukage then
    return game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Piano Tiles",
        Text  = "UI is already running."
    })
end
getgenv().PianoTilesMizukage = true

-- ═══════════════════════════════════════════════════════════
-- [2] SERVICES
-- ═══════════════════════════════════════════════════════════
local Players      = game:GetService("Players")
local VirtualInput = game:GetService("VirtualInputManager")
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
            return warn("[Piano Tiles] UI Failed to load.")
        end
    end
    WindUI = result
end

-- ═══════════════════════════════════════════════════════════
-- [4] BRAND & CONSTANTS
-- ═══════════════════════════════════════════════════════════
local BRAND   = "Piano Tiles 👑 Mizukage"
local AUTHOR  = "TEAMMIZU EDITION"
local VERSION = "v1.0.0"
local FOLDER  = "PianoTiles_Mizukage"

-- ═══════════════════════════════════════════════════════════
-- [5] CONFIG & STATE
-- ═══════════════════════════════════════════════════════════
local Config = {
    AutoPlayEnabled = false,
    TapLineY        = 500,
}

local State = {
    Stats = {
        TotalTaps = 0,
        StartTime = os.clock(),
    },
}

-- ═══════════════════════════════════════════════════════════
-- [6] TAP LINE VISUAL
-- ═══════════════════════════════════════════════════════════
local TapGui = Instance.new("ScreenGui")
TapGui.Name = "PianoTiles_TapLine"
TapGui.ResetOnSpawn = false
TapGui.Enabled = false
TapGui.DisplayOrder = 999
TapGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local TapFrame = Instance.new("Frame")
TapFrame.Size = UDim2.new(1, 0, 0, 4)
TapFrame.Position = UDim2.new(0, 0, 0, Config.TapLineY)
TapFrame.BackgroundColor3 = Color3.fromRGB(255, 30, 30)
TapFrame.BorderSizePixel = 0
TapFrame.Parent = TapGui

local TapLabel = Instance.new("TextLabel")
TapLabel.Size = UDim2.new(0, 200, 0, 24)
TapLabel.Position = UDim2.new(0.5, -100, 0, -28)
TapLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TapLabel.BackgroundTransparency = 0.2
TapLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TapLabel.Text = "POSISI TAP: " .. tostring(Config.TapLineY) .. " px"
TapLabel.Font = Enum.Font.GothamBold
TapLabel.TextSize = 13
TapLabel.Parent = TapFrame

local TapCorner = Instance.new("UICorner")
TapCorner.CornerRadius = UDim.new(0, 6)
TapCorner.Parent = TapLabel

local function RefreshTapLine()
    TapFrame.Position = UDim2.new(0, 0, 0, Config.TapLineY)
    TapLabel.Text = "POSISI TAP: " .. tostring(Config.TapLineY) .. " px"
end

-- ═══════════════════════════════════════════════════════════
-- [7] TAP HELPER
-- ═══════════════════════════════════════════════════════════
local function TapAt(x, y)
    VirtualInput:SendMouseButtonEvent(x, y, 0, true,  game, 1)
    task.wait(0.01)
    VirtualInput:SendMouseButtonEvent(x, y, 0, false, game, 1)
    State.Stats.TotalTaps = State.Stats.TotalTaps + 1
end

-- ═══════════════════════════════════════════════════════════
-- [8] AUTO PLAY ENGINE
-- ═══════════════════════════════════════════════════════════
local AutoPlayThread = nil

local function GetGameBoard()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    local proto = playerGui:FindFirstChild("PianoTilesPrototype")
    if not proto then return nil end
    local root = proto:FindFirstChild("Root")
    if not root then return nil end
    local container = root:FindFirstChild("PortraitContainer")
    if not container then return nil end
    return container:FindFirstChild("GameBoard")
end

local function StartAutoPlay()
    if AutoPlayThread then
        pcall(function() task.cancel(AutoPlayThread) end)
        AutoPlayThread = nil
    end

    AutoPlayThread = task.spawn(function()
        while Config.AutoPlayEnabled do
            local gameBoard = GetGameBoard()
            if gameBoard then
                for laneIndex = 1, 4 do
                    if not Config.AutoPlayEnabled then break end

                    local lane = gameBoard:FindFirstChild("Lane" .. laneIndex)
                    if lane then
                        for _, tile in ipairs(lane:GetChildren()) do
                            if tile.Name == "PianoTile" and tile:IsA("GuiObject") and tile.Visible then
                                local absPos  = tile.AbsolutePosition
                                local absSize = tile.AbsoluteSize
                                local centerX = absPos.X + absSize.X / 2
                                local centerY = absPos.Y + absSize.Y / 2

                                local inRange = math.abs(centerY - Config.TapLineY) <= absSize.Y / 2
                                    or (centerY >= Config.TapLineY and absPos.Y <= Config.TapLineY)

                                if inRange then
                                    TapAt(centerX, centerY)
                                    task.wait(0.005)
                                    break
                                end
                            end
                        end
                    end
                end
            end
            task.wait(0.005)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
-- [9] UI INITIALIZATION
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
        Icon         = "lucide:music",
        Author       = AUTHOR,
        Folder       = FOLDER,
        Size         = isMobile
            and UDim2.fromOffset(viewport.X * 0.95, viewport.Y * 0.95)
            or  UDim2.fromOffset(760, 560),
        MinSize      = Vector2.new(500, 400),
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
    local TabDash   = Window:Tab({ Title = "Dashboard",      Icon = "lucide:layout-dashboard" })
    local TabMain   = Window:Tab({ Title = "Main",           Icon = "lucide:zap" })
    local TabArea   = Window:Tab({ Title = "Edit Area Tap",  Icon = "lucide:sliders" })
    local TabSys    = Window:Tab({ Title = "Settings",       Icon = "lucide:settings" })

    -- ═══════════════════════════════════════════════════════════
    -- TAB: DASHBOARD
    -- ═══════════════════════════════════════════════════════════
    TabDash:Section({ Title = "Statistik Sesi" })

    TabDash:Button({
        Title   = "Refresh Statistik",
        Icon    = "lucide:refresh-cw",
        Variant = "Primary",
        Callback = function()
            local m = math.floor((os.clock() - State.Stats.StartTime) / 60)
            local s = math.floor((os.clock() - State.Stats.StartTime) % 60)
            WindUI:Notify({
                Title    = "Statistik Sesi",
                Content  = string.format(
                    "Total Taps: %d\nUptime: %02d:%02d",
                    State.Stats.TotalTaps, m, s
                ),
                Duration = 6,
                Icon     = "lucide:bar-chart",
            })
        end,
    })

    -- ═══════════════════════════════════════════════════════════
    -- TAB: MAIN
    -- ═══════════════════════════════════════════════════════════
    TabMain:Section({ Title = "Automation" })

    TabMain:Toggle({
        Title    = "Auto Play Tiles",
        Flag     = "AutoPlayTiles",
        Default  = false,
        Callback = function(value)
            Config.AutoPlayEnabled = value
            if value then
                StartAutoPlay()
                WindUI:Notify({
                    Title    = "Auto Play",
                    Content  = "Auto play aktif.",
                    Duration = 3,
                    Icon     = "lucide:zap",
                })
            else
                if AutoPlayThread then
                    pcall(function() task.cancel(AutoPlayThread) end)
                    AutoPlayThread = nil
                end
                WindUI:Notify({
                    Title    = "Auto Play",
                    Content  = "Auto play nonaktif.",
                    Duration = 3,
                    Icon     = "lucide:power",
                })
            end
        end,
    })

    -- ═══════════════════════════════════════════════════════════
    -- TAB: EDIT AREA TAP
    -- ═══════════════════════════════════════════════════════════
    TabArea:Section({ Title = "Atur Garis Area Tap" })

    TabArea:Toggle({
        Title    = "Tampilkan Garis Merah",
        Flag     = "ShowTapLine",
        Default  = false,
        Callback = function(value)
            TapGui.Enabled = value
        end,
    })

    TabArea:Divider()

    TabArea:Button({
        Title   = "Geser Ke Atas (-20 px)",
        Icon    = "lucide:chevron-up",
        Variant = "Secondary",
        Callback = function()
            Config.TapLineY = math.max(50, Config.TapLineY - 20)
            RefreshTapLine()
        end,
    })

    TabArea:Button({
        Title   = "Geser Ke Bawah (+20 px)",
        Icon    = "lucide:chevron-down",
        Variant = "Secondary",
        Callback = function()
            Config.TapLineY = Config.TapLineY + 20
            RefreshTapLine()
        end,
    })

    TabArea:Divider()

    TabArea:Button({
        Title   = "Geser Atas Banyak (-50 px)",
        Icon    = "lucide:chevrons-up",
        Variant = "Secondary",
        Callback = function()
            Config.TapLineY = math.max(50, Config.TapLineY - 50)
            RefreshTapLine()
        end,
    })

    TabArea:Button({
        Title   = "Geser Bawah Banyak (+50 px)",
        Icon    = "lucide:chevrons-down",
        Variant = "Secondary",
        Callback = function()
            Config.TapLineY = Config.TapLineY + 50
            RefreshTapLine()
        end,
    })

    TabArea:Divider()

    TabArea:Button({
        Title   = "Reset Posisi ke 500 px",
        Icon    = "lucide:rotate-ccw",
        Variant = "Primary",
        Callback = function()
            Config.TapLineY = 500
            RefreshTapLine()
        end,
    })

    -- ═══════════════════════════════════════════════════════════
    -- TAB: SETTINGS
    -- ═══════════════════════════════════════════════════════════
    TabSys:Section({ Title = "Manajemen Script" })

    TabSys:Button({
        Title   = "Reset Statistik Sesi",
        Icon    = "lucide:refresh-cw",
        Variant = "Secondary",
        Callback = function()
            State.Stats.TotalTaps = 0
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
                            Config.AutoPlayEnabled = false
                            TapGui.Enabled = false

                            if AutoPlayThread then
                                pcall(function() task.cancel(AutoPlayThread) end)
                                AutoPlayThread = nil
                            end

                            if getgenv() then getgenv().PianoTilesMizukage = nil end

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
        Icon    = "lucide:music",
        Content = "Piano Tiles 👑 Mizukage siap!\n\nTEAMMIZU EDITION\nVersion: " .. VERSION .. "\n\nAuto Play Tiles\nEdit Area Tap\nStatistik Sesi\n\nSelamat bermain!",
        Buttons = {
            {
                Title    = "Tutup",
                Variant  = "Tertiary",
                Callback = function() end,
            },
            {
                Title   = "Mulai Auto Play",
                Icon    = "lucide:zap",
                Variant = "Primary",
                Callback = function()
                    Config.AutoPlayEnabled = true
                    StartAutoPlay()
                    WindUI:Notify({
                        Title    = "Auto Play",
                        Content  = "Auto play aktif.",
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
-- [10] BOOTSTRAP
-- ═══════════════════════════════════════════════════════════
print("[Piano Tiles 👑 Mizukage] " .. VERSION .. " loaded")

-- ═══════════════════════════════════════════════════════════
-- [11] UNLOAD EXPORT
-- ═══════════════════════════════════════════════════════════
getgenv().PianoTilesMizukageUnload = function()
    Config.AutoPlayEnabled = false
    TapGui.Enabled = false
    if AutoPlayThread then
        pcall(function() task.cancel(AutoPlayThread) end)
        AutoPlayThread = nil
    end
    getgenv().PianoTilesMizukage = nil
end