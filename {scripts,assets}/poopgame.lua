-- MIZUKAGE OFFICIAL - Poop Game
-- Fitur: Auto Farm, Auto Sell, Instant Poop, Remove Poops, ESP, etc.

if getgenv().MizuPoopLoaded then return end
getgenv().MizuPoopLoaded = true

getgenv().MizuConfig = getgenv().MizuConfig or { IsRunning = true }
local Config = getgenv().MizuConfig
Config.Poop = Config.Poop or {
    Farm = false,
    Sell = false,
    SellSpeed = 1,
    Walk = false,
    Speed = 28,
    Noclip = false,
    Insta = false,
    InstaSpeed = 0.30,
    Remove = false,
    AntiAFK = false,
    Fling = false,
    AntiFling = false,
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local lp = Players.LocalPlayer

-- Remotes
local PoopEvent = ReplicatedStorage:WaitForChild("PoopEvent")
local PoopCharge = ReplicatedStorage:WaitForChild("PoopChargeStart")
local PoopEventSold = ReplicatedStorage:WaitForChild("PoopSold")

local character = lp.Character or lp.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local gui = lp:WaitForChild("PlayerGui")
local container = gui:WaitForChild("PoopBalancingUI"):WaitForChild("BalancingContainer")
local bar = container:WaitForChild("MovingBar")
local zone = container:WaitForChild("TargetZone")

local clicked = false

-- Noclip
local noclipConn = nil
local function toggleNoclip(state)
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            if lp.Character then
                for _, v in pairs(lp.Character:GetChildren()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end)
    end
end

-- Auto Sell Loop
task.spawn(function()
    while Config.IsRunning do
        if Config.Poop.Sell then
            pcall(function() PoopEventSold:FireServer() end)
            task.wait(Config.Poop.SellSpeed)
        else
            task.wait(1)
        end
    end
end)

-- WalkSpeed
task.spawn(function()
    while Config.IsRunning do
        if Config.Poop.Walk and humanoid then
            humanoid.WalkSpeed = Config.Poop.Speed
        end
        task.wait()
    end
end)

-- Instant Poop
task.spawn(function()
    while Config.IsRunning do
        if Config.Poop.Insta then
            PoopCharge:FireServer(1)
            PoopEvent:FireServer(1)
        end
        task.wait(Config.Poop.InstaSpeed)
    end
end)

-- Remove Poops
task.spawn(function()
    while Config.IsRunning do
        if Config.Poop.Remove then
            for _, obj in pairs(Workspace:GetChildren()) do
                local name = string.lower(obj.Name)
                if name:find("poop") and not name:find("poopsellernpc") then
                    pcall(function() obj:Destroy() end)
                end
            end
        end
        task.wait(0.05)
    end
end)

-- Anti AFK
task.spawn(function()
    while Config.IsRunning do
        if Config.Poop.AntiAFK and root then
            root.CFrame = root.CFrame + Vector3.new(0, 3, 0)
        end
        task.wait(60)
    end
end)

-- Fling
task.spawn(function()
    local movel = 0.1
    while Config.IsRunning do
        if Config.Poop.Fling and root then
            local vel = root.Velocity
            root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
            RunService.RenderStepped:Wait()
            root.Velocity = vel
            RunService.Stepped:Wait()
            root.Velocity = vel + Vector3.new(0, movel, 0)
            movel = -movel
        end
        task.wait(0.02)
    end
end)

-- Anti Fling
task.spawn(function()
    while Config.IsRunning do
        if Config.Poop.AntiFling then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp and plr.Character then
                    for _, part in pairs(plr.Character:GetChildren()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end
            end
        end
        task.wait(0.02)
    end
end)

-- Auto Farm Skillcheck
RunService.RenderStepped:Connect(function()
    if not Config.Poop.Farm or not bar or not zone then return end
    local barX = bar.AbsolutePosition.X + bar.AbsoluteSize.X / 2
    local zoneStart = zone.AbsolutePosition.X
    local zoneEnd = zoneStart + zone.AbsoluteSize.X
    if barX >= zoneStart and barX <= zoneEnd then
        if not clicked then
            local clickX = zoneStart + zone.AbsoluteSize.X / 2
            local clickY = zone.AbsolutePosition.Y + zone.AbsoluteSize.Y / 2
            VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 0)
            VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 0)
            clicked = true
        end
    else
        clicked = false
    end
end)

-- UI
local function InitUI()
    local success, WindUI = pcall(function()
        return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end)
    if not success then return end

    local Window = WindUI:CreateWindow({
        Title = "MIZUKAGE OFFICIAL",
        Icon = "skull",
        Author = "Poop Game",
        Folder = "MizukagePoop",
        Size = UDim2.fromOffset(650, 500),
        Theme = "Dark",
        Accent = Color3.fromRGB(255, 200, 0),
        SideBarWidth = 210,
        HasOutline = true,
    })

    local MainTab = Window:Tab({ Title = "Main", Icon = "rocket" })
    local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
    local ExploitTab = Window:Tab({ Title = "Exploits", Icon = "cpu" })
    local MiscTab = Window:Tab({ Title = "Misc", Icon = "more-horizontal" })

    -- Main Tab
    MainTab:Section({ Title = "Auto Farm" })
    MainTab:Toggle({ Title = "Auto Farm Poop", Default = Config.Poop.Farm, Callback = function(s) Config.Poop.Farm = s end })
    MainTab:Toggle({ Title = "Auto Sell Inventory", Default = Config.Poop.Sell, Callback = function(s) Config.Poop.Sell = s end })
    MainTab:Slider({ Title = "Auto Sell Interval", Min = 1, Max = 180, Step = 1, Default = Config.Poop.SellSpeed, Callback = function(v) Config.Poop.SellSpeed = v end })

    -- Player Tab
    PlayerTab:Section({ Title = "Player Mods" })
    PlayerTab:Toggle({ Title = "Noclip", Default = Config.Poop.Noclip, Callback = function(s) Config.Poop.Noclip = s; toggleNoclip(s) end })
    PlayerTab:Toggle({ Title = "WalkSpeed Changer", Default = Config.Poop.Walk, Callback = function(s) Config.Poop.Walk = s end })
    PlayerTab:Slider({ Title = "WalkSpeed", Min = 28, Max = 100, Step = 1, Default = Config.Poop.Speed, Callback = function(v) Config.Poop.Speed = v end })

    -- Exploit Tab
    ExploitTab:Section({ Title = "Exploits" })
    ExploitTab:Toggle({ Title = "Instant Poop", Default = Config.Poop.Insta, Callback = function(s) Config.Poop.Insta = s end })
    ExploitTab:Slider({ Title = "Instant Poop Interval", Min = 0.30, Max = 10, Step = 0.01, Default = Config.Poop.InstaSpeed, Callback = function(v) Config.Poop.InstaSpeed = v end })
    ExploitTab:Toggle({ Title = "Remove Poops", Default = Config.Poop.Remove, Callback = function(s) Config.Poop.Remove = s end })

    -- Misc Tab
    MiscTab:Section({ Title = "Misc" })
    MiscTab:Toggle({ Title = "Anti AFK", Default = Config.Poop.AntiAFK, Callback = function(s) Config.Poop.AntiAFK = s end })
    MiscTab:Toggle({ Title = "Anti Fling", Default = Config.Poop.AntiFling, Callback = function(s) Config.Poop.AntiFling = s end })
    MiscTab:Toggle({ Title = "Touch Fling", Default = Config.Poop.Fling, Callback = function(s) Config.Poop.Fling = s end })

    WindUI:Notify({ Title = "Mizukage System", Content = "Poop Game loaded!", Duration = 3 })
end

task.spawn(InitUI)
