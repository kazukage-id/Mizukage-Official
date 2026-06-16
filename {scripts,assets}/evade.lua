-- MIZUKAGE OFFICIAL - Evade
-- Fitur: Anti Nextbot, AFK Farm, Auto Objectives, ESP, Speed Hack, dll.

if getgenv().MizuEvadeLoaded then return end
getgenv().MizuEvadeLoaded = true

getgenv().MizuConfig = getgenv().MizuConfig or { IsRunning = true }
local Config = getgenv().MizuConfig
Config.Evade = Config.Evade or {
    Walk = false,
    Speed = 28,
    EmoteSpeed = 40,
    Noclip = false,
    AntiAFK = false,
    Fling = false,
    AntiFling = false,
    AntiNextbot = false,
    AutoObj = false,
    AutoRev = false,
    ESPHighlight = false,
    ESPTypes = {},
    ESPTracers = false,
    ESPNames = false,
    ESPBoxes = false,
    ESPStuds = false,
    AutoJump = false,
    Gravity = false,
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local lp = Players.LocalPlayer

local PlayersFolder = Workspace:WaitForChild("Game"):WaitForChild("Players")

-- Timer
local timer = nil
local timerActive = false

local function nextbotsExist()
    if not PlayersFolder then return false end
    for _, model in ipairs(PlayersFolder:GetChildren()) do
        if model:IsA("Model") and model:FindFirstChild("Hitbox") then
            return true
        end
    end
    return false
end

task.spawn(function()
    while Config.IsRunning do
        if nextbotsExist() and not timerActive then
            timer = 180
            timerActive = true
        end
        if timerActive and timer > 0 then
            timer = timer - 1
        elseif timerActive and timer <= 0 then
            timer = nil
            timerActive = false
        end
        task.wait(1)
    end
end)

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

-- AFK Zone Teleport
local function teleportAndCreateBase(text)
    if not root then return end
    root.CFrame = CFrame.new(0, 9999, 0)

    local basePart = Instance.new("Part")
    basePart.Size = Vector3.new(5000, 1, 5000)
    basePart.Position = root.Position - Vector3.new(0, root.Size.Y/2 + 0.5, 0)
    basePart.Anchored = true
    basePart.CanCollide = true
    basePart.Parent = workspace

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = basePart
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 7, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 5000
    billboard.Parent = basePart

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0.6, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text or "Mizukage\nAFK Zone"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard

    local timerLabel = Instance.new("TextLabel")
    timerLabel.Size = UDim2.new(1, 0, 0.4, 0)
    timerLabel.Position = UDim2.new(0, 0, 0.6, 0)
    timerLabel.BackgroundTransparency = 1
    timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    timerLabel.TextScaled = true
    timerLabel.Font = Enum.Font.GothamBold
    timerLabel.Text = "Intermission"
    timerLabel.Parent = billboard

    task.spawn(function()
        while basePart.Parent do
            if timer == nil then
                timerLabel.Text = "Intermission"
            else
                timerLabel.Text = "Round end: " .. tostring(timer)
            end
            task.wait(1)
        end
    end)
end

task.spawn(function()
    while Config.IsRunning do
        task.wait(0.5)
        if Config.Evade.AntiNextbot and root and root.Position.Y < 9990 then
            teleportAndCreateBase("Mizukage\nAFK Zone")
        end
    end
end)

-- Speed Hack (Bypass)
local normalConn = nil
task.spawn(function()
    while Config.IsRunning do
        if normalConn then normalConn:Disconnect(); normalConn = nil end
        if Config.Evade.Walk and character then
            normalConn = RunService.Heartbeat:Connect(function()
                if not Config.Evade.Walk or not character or not hum or not root then return end
                for _, conn in ipairs(getconnections(hum:GetPropertyChangedSignal("WalkSpeed"))) do
                    conn:Disable()
                end
                local dir = hum.MoveDirection
                if dir.Magnitude > 0 then
                    local speed = root:FindFirstChild("EmoteSound") and Config.Evade.EmoteSpeed or Config.Evade.Speed
                    local move = Vector3.new(dir.X, 0, dir.Z).Unit * speed
                    root.AssemblyLinearVelocity = Vector3.new(move.X, root.AssemblyLinearVelocity.Y, move.Z)
                else
                    root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- Auto Jump UI
local function createAutoJumpUI()
    if game.CoreGui:FindFirstChild("MizuAutoJump") then
        game.CoreGui:FindFirstChild("MizuAutoJump"):Destroy()
    end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MizuAutoJump"
    ScreenGui.Parent = game.CoreGui

    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0, 140, 0, 40)
    Toggle.Position = UDim2.new(0.68, 0, 0.05, 0)
    Toggle.Text = "Auto Jump: OFF"
    Toggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Toggle.TextColor3 = Color3.new(1, 1, 1)
    Toggle.Font = Enum.Font.SourceSansBold
    Toggle.TextSize = 18
    Toggle.Parent = ScreenGui
    Toggle.Active = true
    Toggle.Draggable = true

    local autoJump = false
    local conn = nil

    Toggle.MouseButton1Click:Connect(function()
        autoJump = not autoJump
        Toggle.Text = autoJump and "Auto Jump: ON" or "Auto Jump: OFF"
        if conn then conn:Disconnect() end
        if autoJump then
            conn = RunService.Heartbeat:Connect(function()
                if hum and hum.FloorMaterial ~= Enum.Material.Air then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        end
    end)
end

-- Gravity UI
local function createGravityUI()
    if game.CoreGui:FindFirstChild("MizuGravity") then
        game.CoreGui:FindFirstChild("MizuGravity"):Destroy()
    end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MizuGravity"
    ScreenGui.Parent = game.CoreGui

    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(0, 140, 0, 40)
    Toggle.Position = UDim2.new(0.68, 0, 0.05, 0)
    Toggle.Text = "Gravity: OFF"
    Toggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Toggle.TextColor3 = Color3.new(1, 1, 1)
    Toggle.Font = Enum.Font.SourceSansBold
    Toggle.TextSize = 18
    Toggle.Parent = ScreenGui
    Toggle.Active = true
    Toggle.Draggable = true

    local defaultGravity = workspace.Gravity
    local gravity = false
    local conn = nil

    Toggle.MouseButton1Click:Connect(function()
        gravity = not gravity
        Toggle.Text = gravity and "Gravity: ON" or "Gravity: OFF"
        if conn then conn:Disconnect() end
        if gravity then
            conn = RunService.Heartbeat:Connect(function()
                if workspace.Gravity ~= 30 then workspace.Gravity = 30 end
            end)
        else
            workspace.Gravity = defaultGravity
        end
    end)
end

-- Anti AFK
task.spawn(function()
    while Config.IsRunning do
        if Config.Evade.AntiAFK and root then
            root.CFrame = root.CFrame + Vector3.new(0, 3, 0)
        end
        task.wait(60)
    end
end)

-- Fling
task.spawn(function()
    local movel = 0.1
    while Config.IsRunning do
        if Config.Evade.Fling and root then
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
        if Config.Evade.AntiFling then
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

-- ESP System
local esp = {}
local tracers = {}
local boxes = {}
local DrawingAvailable = (type(Drawing) == "table" or type(Drawing) == "userdata")

local function contains(tbl, val)
    if not tbl then return false end
    for _, v in pairs(tbl) do if v == val then return true end end
    return false
end

local function isPlayerObject(obj)
    return type(obj.Name) == "string" and not obj.Name:find(" ") and not obj:FindFirstChild("Revives") and obj.Parent.Name == "Game"
end

local function isNextbotObject(obj)
    return obj:FindFirstChild("Hitbox") and obj.Hitbox:IsA("BasePart")
end

local function isInjuredPlayer(obj)
    return type(obj.Name) == "string" and not obj.Name:find(" ") and obj:FindFirstChild("Revives")
end

local function passesFilter(obj)
    if not Config.Evade.ESPTypes or #Config.Evade.ESPTypes == 0 then return false end
    if contains(Config.Evade.ESPTypes, "Players") and isPlayerObject(obj) then return true end
    if contains(Config.Evade.ESPTypes, "Nextbots") and isNextbotObject(obj) then return true end
    if contains(Config.Evade.ESPTypes, "Injured Players") and isInjuredPlayer(obj) then return true end
    return false
end

local function getObjColor(obj)
    if isInjuredPlayer(obj) then return Color3.fromRGB(255, 255, 0) end
    if isNextbotObject(obj) then return Color3.fromRGB(255, 0, 0) end
    return Color3.fromRGB(0, 255, 0)
end

local function getRootPosition(target)
    if target:IsA("BasePart") then return target.Position end
    if target:IsA("Model") then
        if target.PrimaryPart then return target.PrimaryPart.Position end
        local r = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("VisibleParts")
        if r and r:IsA("BasePart") then return r.Position end
        return target:GetPivot().Position
    end
    return Vector3.new(0, 0, 0)
end

local function ensureHighlight(obj)
    if not Config.Evade.ESPHighlight then
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

local function ensureBillboard(obj)
    if not (Config.Evade.ESPNames or Config.Evade.ESPStuds) then
        if esp[obj] and esp[obj].billboard then
            esp[obj].billboard:Destroy()
            esp[obj].billboard = nil
        end
        return
    end
    if not esp[obj] then esp[obj] = {} end
    if not esp[obj].billboard then
        local head = obj:FindFirstChild("Head") or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
        if not head then return end
        local b = Instance.new("BillboardGui")
        b.Name = "MizuESP"
        b.Size = UDim2.new(0, 200, 0, 50)
        b.Adornee = head
        b.AlwaysOnTop = true
        b.MaxDistance = 5000
        b.Parent = obj
        local n = Instance.new("TextLabel")
        n.Name = "MainLabel"
        n.Parent = b
        n.BackgroundTransparency = 1
        n.Size = UDim2.new(1, 0, 1, 0)
        n.Text = ""
        n.Font = Enum.Font.SourceSansBold
        n.TextSize = 14
        n.TextStrokeTransparency = 0
        n.RichText = true
        esp[obj].billboard = b
        esp[obj].nameLabel = n
    end
end

local function ensureTracer(obj)
    if not Config.Evade.ESPTracers then
        if tracers[obj] then tracers[obj]:Remove(); tracers[obj] = nil end
        return
    end
    if not tracers[obj] and DrawingAvailable then
        local L = Drawing.new("Line")
        L.Thickness = 1
        L.Transparency = 1
        tracers[obj] = L
    end
end

local function ensureBox(obj)
    if not Config.Evade.ESPBoxes then
        if boxes[obj] then
            for _, l in pairs(boxes[obj]) do l:Remove() end
            boxes[obj] = nil
        end
        return
    end
    if not boxes[obj] and DrawingAvailable then
        boxes[obj] = {
            tl = Drawing.new("Line"),
            tr = Drawing.new("Line"),
            bl = Drawing.new("Line"),
            br = Drawing.new("Line")
        }
        for _, line in pairs(boxes[obj]) do line.Thickness = 1; line.Transparency = 1 end
    end
end

local function removeESP(obj)
    local d = esp[obj]
    if d then
        if d.highlight then pcall(function() d.highlight:Destroy() end) end
        if d.billboard then pcall(function() d.billboard:Destroy() end) end
        esp[obj] = nil
    end
    if tracers[obj] then pcall(function() tracers[obj]:Remove() end); tracers[obj] = nil end
    if boxes[obj] then
        for _, l in pairs(boxes[obj]) do pcall(function() l:Remove() end) end
        boxes[obj] = nil
    end
end

task.spawn(function()
    while Config.IsRunning do
        task.wait(1.5)
        for _, obj in pairs(workspace:GetChildren()) do
            if obj ~= lp.Character and passesFilter(obj) then
                ensureHighlight(obj)
                ensureBillboard(obj)
                ensureTracer(obj)
                ensureBox(obj)
            end
        end

        if not Camera then return end
        local viewportSize = Camera.ViewportSize
        local myRoot = root

        for obj, data in pairs(esp) do
            if not obj or not obj.Parent or not passesFilter(obj) then
                removeESP(obj)
                continue
            end

            local color = getObjColor(obj)
            local worldPos = getRootPosition(obj)
            local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
            local isVisible = onScreen and screenPos.Z > 0

            if tracers[obj] and isVisible and Config.Evade.ESPTracers then
                tracers[obj].Visible = true
                tracers[obj].Color = color
                tracers[obj].From = Vector2.new(viewportSize.X / 2, viewportSize.Y)
                tracers[obj].To = Vector2.new(screenPos.X, screenPos.Y)
            elseif tracers[obj] then
                tracers[obj].Visible = false
            end

            if data.billboard then
                data.billboard.Enabled = isVisible and (Config.Evade.ESPNames or Config.Evade.ESPStuds)
                if data.billboard.Enabled and myRoot then
                    local targetLabel = data.nameLabel
                    if targetLabel then
                        local dist = (Camera.CFrame.Position - worldPos).Magnitude
                        if Config.Evade.ESPNames and Config.Evade.ESPStuds then
                            targetLabel.Text = obj.Name .. " (" .. string.format("%.0fm", dist) .. ")"
                        elseif Config.Evade.ESPNames then
                            targetLabel.Text = obj.Name
                        elseif Config.Evade.ESPStuds then
                            targetLabel.Text = string.format("%.0fm", dist)
                        end
                        targetLabel.TextColor3 = color
                    end
                end
            end

            if boxes[obj] and isVisible and Config.Evade.ESPBoxes then
                local box = boxes[obj]
                local size = (1 / screenPos.Z) * 1000
                local w, h = size * 0.6, size
                local x, y = screenPos.X, screenPos.Y
                for _, line in pairs(box) do line.Visible = true; line.Color = color end
                box.tl.From = Vector2.new(x-w, y-h); box.tl.To = Vector2.new(x+w, y-h)
                box.tr.From = Vector2.new(x+w, y-h); box.tr.To = Vector2.new(x+w, y+h)
                box.br.From = Vector2.new(x+w, y+h); box.br.To = Vector2.new(x-w, y+h)
                box.bl.From = Vector2.new(x-w, y+h); box.bl.To = Vector2.new(x-w, y-h)
            elseif boxes[obj] then
                for _, line in pairs(boxes[obj]) do line.Visible = false end
            end

            if data.highlight then data.highlight.FillColor = color end
        end
    end
end)

Workspace.ChildAdded:Connect(function(child)
    task.wait(0.5)
    if passesFilter(child) then
        ensureHighlight(child)
        ensureBillboard(child)
        ensureTracer(child)
        ensureBox(child)
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
        Author = "Evade",
        Folder = "MizukageEvade",
        Size = UDim2.fromOffset(680, 540),
        Theme = "Dark",
        Accent = Color3.fromRGB(255, 100, 0),
        SideBarWidth = 210,
        HasOutline = true,
    })

    local AutoTab = Window:Tab({ Title = "Auto", Icon = "cpu" })
    local EspTab = Window:Tab({ Title = "ESP", Icon = "eye" })
    local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
    local MiscTab = Window:Tab({ Title = "Misc", Icon = "more-horizontal" })

    -- Auto Tab
    AutoTab:Section({ Title = "Auto Features" })
    AutoTab:Toggle({ Title = "Auto Objectives", Default = Config.Evade.AutoObj, Callback = function(s) Config.Evade.AutoObj = s end })
    AutoTab:Toggle({ Title = "Auto Revive", Default = Config.Evade.AutoRev, Callback = function(s) Config.Evade.AutoRev = s end })
    AutoTab:Toggle({ Title = "AFK Farm", Default = Config.Evade.AntiNextbot, Callback = function(s) Config.Evade.AntiNextbot = s end })
    AutoTab:Button({ Title = "Auto Jump UI", Variant = "Secondary", Callback = createAutoJumpUI })
    AutoTab:Button({ Title = "Gravity UI", Variant = "Secondary", Callback = createGravityUI })
    AutoTab:Button({ Title = "Full Bright", Variant = "Secondary", Callback = function()
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ShadowSoftness = 0
        Lighting.GlobalShadows = false
    end })

    -- ESP Tab
    EspTab:Section({ Title = "ESP Settings" })
    EspTab:Dropdown({ Title = "ESP Types", Values = {"Injured Players", "Players", "Nextbots"}, Multi = true, Value = Config.Evade.ESPTypes, Callback = function(v) Config.Evade.ESPTypes = v end })
    EspTab:Toggle({ Title = "Highlight Objects", Default = Config.Evade.ESPHighlight, Callback = function(s) Config.Evade.ESPHighlight = s end })
    EspTab:Toggle({ Title = "Show Tracers", Default = Config.Evade.ESPTracers, Callback = function(s) Config.Evade.ESPTracers = s end })
    EspTab:Toggle({ Title = "Show Boxes", Default = Config.Evade.ESPBoxes, Callback = function(s) Config.Evade.ESPBoxes = s end })
    EspTab:Toggle({ Title = "Show Names", Default = Config.Evade.ESPNames, Callback = function(s) Config.Evade.ESPNames = s end })
    EspTab:Toggle({ Title = "Show Studs", Default = Config.Evade.ESPStuds, Callback = function(s) Config.Evade.ESPStuds = s end })

    -- Player Tab
    PlayerTab:Section({ Title = "Player Mods" })
    PlayerTab:Toggle({ Title = "Noclip", Default = Config.Evade.Noclip, Callback = function(s) Config.Evade.Noclip = s; toggleNoclip(s) end })
    PlayerTab:Toggle({ Title = "WalkSpeed Changer", Default = Config.Evade.Walk, Callback = function(s) Config.Evade.Walk = s end })
    PlayerTab:Slider({ Title = "WalkSpeed", Min = 0, Max = 150, Step = 1, Default = Config.Evade.Speed, Callback = function(v) Config.Evade.Speed = v end })
    PlayerTab:Slider({ Title = "Emote Speed", Min = 0, Max = 300, Step = 1, Default = Config.Evade.EmoteSpeed, Callback = function(v) Config.Evade.EmoteSpeed = v end })

    -- Misc Tab
    MiscTab:Section({ Title = "Misc" })
    MiscTab:Toggle({ Title = "Anti AFK", Default = Config.Evade.AntiAFK, Callback = function(s) Config.Evade.AntiAFK = s end })
    MiscTab:Toggle({ Title = "Anti Fling", Default = Config.Evade.AntiFling, Callback = function(s) Config.Evade.AntiFling = s end })
    MiscTab:Toggle({ Title = "Touch Fling", Default = Config.Evade.Fling, Callback = function(s) Config.Evade.Fling = s end })
    MiscTab:Button({ Title = "Bypass Anti Speed", Variant = "Secondary", Callback = function()
        if root then
            for _, obj in pairs(root:GetChildren()) do
                if obj:IsA("LinearVelocity") then obj:Destroy() end
            end
        end
    end })

    WindUI:Notify({ Title = "Mizukage System", Content = "Evade loaded!", Duration = 3 })
end

task.spawn(InitUI)
