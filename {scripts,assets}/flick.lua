-- MIZUKAGE OFFICIAL - Flick (Murder Mystery 2)
-- Fitur: Aimbot, Silent Aim, FOV, ESP, dll.

if getgenv().MizuFlickLoaded then return end
getgenv().MizuFlickLoaded = true

getgenv().MizuConfig = getgenv().MizuConfig or { IsRunning = true }
local Config = getgenv().MizuConfig
Config.Flick = Config.Flick or {
    AutoAim = false,
    FOV = false,
    FOVRadius = 30,
    AimbotPart = "Head",
    Smoothness = 10,
    WallCheck = false,
    Walk = false,
    Speed = 28,
    Noclip = false,
    AntiAFK = false,
    Fling = false,
    AntiFling = false,
    ESPHighlight = false,
    ESPTypes = {},
    SilentAim = false,
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer

local character = nil
local hum = nil
local root = nil

local function updateChar(char)
    character = char
    root = char and char:FindFirstChild("HumanoidRootPart")
    hum = char and char:FindFirstChild("Humanoid")
end
updateChar(lp.Character or lp.CharacterAdded:Wait())
lp.CharacterAdded:Connect(updateChar)

-- FOV Circle GUI
local CoreGui = game:GetService("CoreGui")
local PlayerGui = lp:WaitForChild("PlayerGui")
local existing = CoreGui:FindFirstChild("MizuFOV") or PlayerGui:FindFirstChild("MizuFOV")
if existing then existing:Destroy() end

local FOVGui = Instance.new("ScreenGui")
FOVGui.Name = "MizuFOV"
FOVGui.DisplayOrder = 10
FOVGui.ResetOnSpawn = false
FOVGui.IgnoreGuiInset = true
pcall(function() FOVGui.Parent = CoreGui end)

local FOVFrame = Instance.new("Frame")
FOVFrame.Name = "FOVCircle"
FOVFrame.BackgroundTransparency = 1
FOVFrame.BorderSizePixel = 0
FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVFrame.Visible = false
FOVFrame.Parent = FOVGui

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 1.5
UIStroke.Color = Color3.fromRGB(0, 255, 255)
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Parent = FOVFrame

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = FOVFrame

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

-- WalkSpeed Bypass
task.spawn(function()
    while Config.IsRunning do
        if Config.Flick.Walk and hum then
            for _, conn in ipairs(getconnections(hum:GetPropertyChangedSignal("WalkSpeed"))) do
                conn:Disable()
            end
            hum.WalkSpeed = Config.Flick.Speed
        end
        task.wait(0.2)
    end
end)

-- Anti AFK
task.spawn(function()
    while Config.IsRunning do
        if Config.Flick.AntiAFK and root then
            root.CFrame = root.CFrame + Vector3.new(0, 3, 0)
        end
        task.wait(60)
    end
end)

-- Fling
task.spawn(function()
    local movel = 0.1
    while Config.IsRunning do
        if Config.Flick.Fling and root then
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
        if Config.Flick.AntiFling then
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

-- Aimbot
local function isAlive(obj)
    local hum = obj:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

task.spawn(function()
    while Config.IsRunning do
        RunService.Heartbeat:Wait()
        local screenCenter = Camera.ViewportSize / 2

        if Config.Flick.FOV then
            FOVFrame.Visible = true
            local diameter = Config.Flick.FOVRadius * 2
            FOVFrame.Size = UDim2.new(0, diameter, 0, diameter)
        else
            FOVFrame.Visible = false
        end

        if not Config.Flick.AutoAim or not lp.Character or not root then continue end

        local nearestTarget = nil
        local shortestDistance = math.huge

        for _, obj in pairs(Workspace:GetChildren()) do
            if obj == lp.Character then continue end
            if not obj:IsA("Model") then continue end
            if obj.Name == "deadbody" then continue end
            if not isAlive(obj) then continue end

            local targetPart = obj:FindFirstChild(Config.Flick.AimbotPart)
            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)

                if onScreen and Config.Flick.FOV then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if dist > Config.Flick.FOVRadius then continue end
                elseif Config.Flick.FOV and not onScreen then
                    continue
                end

                if Config.Flick.WallCheck then
                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = {lp.Character, obj}
                    local ray = Workspace:Raycast(root.Position, (targetPart.Position - root.Position), rayParams)
                    if ray then continue end
                end

                local mag = (targetPart.Position - root.Position).Magnitude
                if mag < shortestDistance then
                    shortestDistance = mag
                    nearestTarget = obj
                end
            end
        end

        if nearestTarget then
            local tPart = nearestTarget:FindFirstChild(Config.Flick.AimbotPart)
            if tPart then
                local targetLook = CFrame.new(Camera.CFrame.Position, tPart.Position)
                if Config.Flick.Smoothness > 0 then
                    Camera.CFrame = Camera.CFrame:Lerp(targetLook, 1 / Config.Flick.Smoothness)
                else
                    Camera.CFrame = targetLook
                end
            end
        end
    end
end)

-- Silent Aim
local function setupSilentAim()
    local bullet_handler = require(game:GetService("ReplicatedStorage").ModuleScripts.GunModules.BulletHandler)
    local old = bullet_handler.Fire
    bullet_handler.Fire = function(data)
        local closest = nil
        local closestDist = 999
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= lp and player.Character then
                local head = player.Character:FindFirstChild("Head")
                if head then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - Camera.ViewportSize / 2).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closest = head
                        end
                    end
                end
            end
        end
        if closest then
            data.Force = data.Force * 1000
            data.Direction = (closest.Position - data.Origin).Unit
        end
        return old(data)
    end
end

task.spawn(function()
    while Config.IsRunning do
        if Config.Flick.SilentAim then
            setupSilentAim()
            break
        end
        task.wait(1)
    end
end)

-- FOV Slider
task.spawn(function()
    local fovRadius = 70
    while Config.IsRunning do
        RunService.RenderStepped:Wait()
        if workspace.CurrentCamera.FieldOfView ~= fovRadius then
            workspace.CurrentCamera.FieldOfView = fovRadius
        end
    end
end)

-- ESP System
local esp = {}
local function contains(tbl, val)
    if not tbl then return false end
    for _, v in pairs(tbl) do if v == val then return true end end
    return false
end

local function isPlayerObject(obj)
    if obj:IsA("Model") and obj:FindFirstChild("Head") and obj.Name ~= lp.Name then return true end
    return false
end

local function passesFilter(obj)
    if not Config.Flick.ESPTypes or #Config.Flick.ESPTypes == 0 then return false end
    if contains(Config.Flick.ESPTypes, "Players") and isPlayerObject(obj) then return true end
    return false
end

local function getObjColor(obj)
    return Color3.fromRGB(0, 255, 0)
end

local function ensureHighlight(obj)
    if not Config.Flick.ESPHighlight then
        if esp[obj] and esp[obj].highlight then
            esp[obj].highlight:Destroy()
            esp[obj].highlight = nil
        end
        return
    end
    if not esp[obj] then esp[obj] = {} end
    if not esp[obj].highlight then
        local h = Instance.new("Highlight")
        h.Adornee = obj
        h.FillTransparency = 0.5
        h.OutlineTransparency = 0
        h.FillColor = getObjColor(obj)
        h.OutlineColor = Color3.new(1, 1, 1)
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = obj
        esp[obj].highlight = h
    end
end

task.spawn(function()
    while Config.IsRunning do
        task.wait(1.5)
        for _, obj in pairs(Workspace:GetChildren()) do
            if obj ~= lp.Character and passesFilter(obj) then
                ensureHighlight(obj)
            end
        end
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
        Author = "Flick",
        Folder = "MizukageFlick",
        Size = UDim2.fromOffset(680, 520),
        Theme = "Dark",
        Accent = Color3.fromRGB(0, 255, 255),
        SideBarWidth = 210,
        HasOutline = true,
    })

    local MainTab = Window:Tab({ Title = "Main", Icon = "rocket" })
    local EspTab = Window:Tab({ Title = "ESP", Icon = "eye" })
    local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
    local MiscTab = Window:Tab({ Title = "Misc", Icon = "more-horizontal" })

    -- Main Tab - Aimbot
    MainTab:Section({ Title = "🎯 Aimbot" })
    MainTab:Toggle({ Title = "Auto Aimbot", Default = Config.Flick.AutoAim, Callback = function(s) Config.Flick.AutoAim = s end })
    MainTab:Toggle({ Title = "Aimbot FOV", Default = Config.Flick.FOV, Callback = function(s) Config.Flick.FOV = s end })

    MainTab:Section({ Title = "Aimbot Settings" })
    MainTab:Dropdown({ Title = "Target Part", Values = {"Head", "HumanoidRootPart"}, Value = Config.Flick.AimbotPart, Callback = function(v) Config.Flick.AimbotPart = v[1] end })
    MainTab:Slider({ Title = "Camera Smoothness", Min = 0, Max = 50, Step = 1, Default = Config.Flick.Smoothness, Callback = function(v) Config.Flick.Smoothness = v end })
    MainTab:Slider({ Title = "FOV Radius", Min = 10, Max = 150, Step = 1, Default = Config.Flick.FOVRadius, Callback = function(v) Config.Flick.FOVRadius = v end })
    MainTab:Toggle({ Title = "Wall Check", Default = Config.Flick.WallCheck, Callback = function(s) Config.Flick.WallCheck = s end })

    MainTab:Section({ Title = "Exploits" })
    MainTab:Toggle({ Title = "Silent Aim / Insta Hit", Default = Config.Flick.SilentAim, Callback = function(s) Config.Flick.SilentAim = s end })

    -- ESP Tab
    EspTab:Section({ Title = "Visual" })
    EspTab:Button({ Title = "Full Bright", Variant = "Secondary", Callback = function()
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ShadowSoftness = 0
        Lighting.GlobalShadows = false
    end })
    EspTab:Dropdown({ Title = "ESP Types", Values = {"Players"}, Multi = true, Value = Config.Flick.ESPTypes, Callback = function(v) Config.Flick.ESPTypes = v end })
    EspTab:Toggle({ Title = "Highlight Objects", Default = Config.Flick.ESPHighlight, Callback = function(s) Config.Flick.ESPHighlight = s end })

    -- Player Tab
    PlayerTab:Section({ Title = "Player Mods" })
    PlayerTab:Toggle({ Title = "Noclip", Default = Config.Flick.Noclip, Callback = function(s) Config.Flick.Noclip = s; toggleNoclip(s) end })
    PlayerTab:Toggle({ Title = "WalkSpeed Changer", Default = Config.Flick.Walk, Callback = function(s) Config.Flick.Walk = s end })
    PlayerTab:Slider({ Title = "WalkSpeed", Min = 16, Max = 100, Step = 1, Default = Config.Flick.Speed, Callback = function(v) Config.Flick.Speed = v end })

    -- Misc Tab
    MiscTab:Section({ Title = "Misc" })
    MiscTab:Toggle({ Title = "Anti AFK", Default = Config.Flick.AntiAFK, Callback = function(s) Config.Flick.AntiAFK = s end })
    MiscTab:Toggle({ Title = "Anti Fling", Default = Config.Flick.AntiFling, Callback = function(s) Config.Flick.AntiFling = s end })
    MiscTab:Toggle({ Title = "Touch Fling", Default = Config.Flick.Fling, Callback = function(s) Config.Flick.Fling = s end })

    WindUI:Notify({ Title = "Mizukage System", Content = "Flick loaded!", Duration = 3 })
end

task.spawn(InitUI)
