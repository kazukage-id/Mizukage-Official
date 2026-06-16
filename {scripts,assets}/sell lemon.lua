-- MIZUKAGE OFFICIAL - Lemon Sells v2 (Base Universal)
-- Fitur: Auto Buy, Auto Upgrade, Auto Fruit

if getgenv().MizuLemonLoaded then
    return game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Mizukage Official",
        Text = "Sistem Lemon sudah berjalan!"
    })
end
getgenv().MizuLemonLoaded = true

-- ================================================
-- KONFIGURASI GLOBAL
-- ================================================
getgenv().MizuConfig = getgenv().MizuConfig or { IsRunning = true }
local Config = getgenv().MizuConfig
Config.Lemon = Config.Lemon or {
    Buy = false,
    Upgrade = false,
    Fruit = false,
    Delay = 0.25,
}

-- ================================================
-- SERVICE
-- ================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- ================================================
-- FUNGSI INTI
-- ================================================
local function GetCharacter()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char, char:WaitForChild("HumanoidRootPart")
end

local function FindTycoon()
    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Folder") and v.Name:match("Tycoon") then
            local owner = v:FindFirstChild("Owner")
            if owner and owner.Value == LocalPlayer then
                return v
            end
        end
    end
end

local Tycoon = FindTycoon()
if not Tycoon then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Mizukage Official",
        Text = "Tycoon tidak ditemukan!"
    })
    return
end

local Buttons = {}
local function RefreshButtons()
    table.clear(Buttons)
    local folder = Tycoon:FindFirstChild("Purchases")
    if not folder then return end
    for _, obj in pairs(folder:GetDescendants()) do
        if obj:IsA("Model") and obj:GetAttribute("Shown") and not obj:GetAttribute("Purchased") then
            local part = obj:FindFirstChild("Button")
            if part and part:IsA("BasePart") then
                table.insert(Buttons, part)
            end
        end
    end
end

local function Touch(part)
    pcall(function()
        local _, hrp = GetCharacter()
        firetouchinterest(hrp, part, 0)
        task.wait(0.05)
        firetouchinterest(hrp, part, 1)
    end)
end

-- Loop Buy
task.spawn(function()
    while Config.IsRunning do
        if Config.Lemon.Buy then
            RefreshButtons()
            for _, button in ipairs(Buttons) do
                if button and button.Parent then Touch(button) end
            end
        end
        task.wait(Config.Lemon.Delay)
    end
end)

-- Upgrade
local function Upgrade()
    for _, v in pairs(Tycoon:GetDescendants()) do
        if v:IsA("RemoteFunction") and v.Name == "Upgrade" then
            pcall(function()
                for i = 1, 50 do v:InvokeServer(i) end
            end)
        end
    end
end

task.spawn(function()
    while Config.IsRunning do
        if Config.Lemon.Upgrade then Upgrade() end
        task.wait(2)
    end
end)

-- Fruit
local Trees = {}
local function ScanTree()
    table.clear(Trees)
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name == "LemonTree" then
            table.insert(Trees, v)
        end
    end
end

local function Collect(tree)
    pcall(function()
        local _, hrp = GetCharacter()
        hrp.CFrame = tree:GetPivot() + Vector3.new(0, 5, 0)
        for _, x in pairs(tree:GetDescendants()) do
            if x:IsA("ClickDetector") then
                fireclickdetector(x)
            end
        end
    end)
end

task.spawn(function()
    while Config.IsRunning do
        if Config.Lemon.Fruit then
            ScanTree()
            for _, tree in ipairs(Trees) do
                if tree.Parent then
                    Collect(tree)
                    task.wait(0.3)
                end
            end
        end
        task.wait(1)
    end
end)

-- ================================================
-- UI (WindUI)
-- ================================================
local function InitUI()
    local success, WindUI = pcall(function()
        return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end)
    if not success then return end

    local Window = WindUI:CreateWindow({
        Title = "MIZUKAGE OFFICIAL",
        Icon = "skull",
        Author = "Lemon Sells",
        Folder = "MizukageLemon",
        Size = UDim2.fromOffset(600, 450),
        Theme = "Dark",
        Accent = Color3.fromRGB(255, 215, 0),
        SideBarWidth = 200,
        HasOutline = true,
        Background = "rbxassetid://137490169052447",
        BackgroundImageTransparency = 0.7,
    })

    local MainTab = Window:Tab({ Title = "Main", Icon = "swords" })

    MainTab:Section({ Title = "Auto Farm" })
    MainTab:Toggle({
        Title = "Auto Buy",
        Default = Config.Lemon.Buy,
        Callback = function(s)
            Config.Lemon.Buy = s
        end
    })
    MainTab:Toggle({
        Title = "Auto Upgrade",
        Default = Config.Lemon.Upgrade,
        Callback = function(s)
            Config.Lemon.Upgrade = s
        end
    })
    MainTab:Toggle({
        Title = "Auto Fruit",
        Default = Config.Lemon.Fruit,
        Callback = function(s)
            Config.Lemon.Fruit = s
        end
    })
    MainTab:Slider({
        Title = "Delay",
        Min = 0.1,
        Max = 2,
        Step = 0.1,
        Default = Config.Lemon.Delay,
        Callback = function(v)
            Config.Lemon.Delay = v
        end
    })

    MainTab:Section({ Title = "Control" })
    MainTab:Button({
        Title = "Emergency Stop",
        Variant = "Secondary",
        Callback = function()
            Config.Lemon.Buy = false
            Config.Lemon.Upgrade = false
            Config.Lemon.Fruit = false
        end
    })
    MainTab:Button({
        Title = "Destroy GUI",
        Variant = "Danger",
        Callback = function()
            getgenv().MizuLemonLoaded = false
            Window:Destroy()
        end
    })

    WindUI:Notify({
        Title = "Mizukage System",
        Content = "Lemon Sells v2 siap!",
        Duration = 3
    })
end

task.spawn(InitUI)
