-- MIZUKAGE OFFICIAL - Demonology
-- Fitur: Visible Ghost, Auto Hide, ESP, Item Grab, dll.

if getgenv().MizuDemonologyLoaded then return end
getgenv().MizuDemonologyLoaded = true

getgenv().MizuConfig = getgenv().MizuConfig or { IsRunning = true }
local Config = getgenv().MizuConfig
Config.Demonology = Config.Demonology or {
    Walk = false,
    Speed = 28,
    Noclip = false,
    AntiAFK = false,
    Fling = false,
    AntiFling = false,
    GhostVisible = false,
    AutoHide = false,
    ESPHighlight = false,
    ESPTypes = {},
    ESPTracers = false,
    ESPNames = false,
    ESPBoxes = false,
    ESPStuds = false,
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
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
        if Config.Demonology.Walk and hum then
            for _, conn in ipairs(getconnections(hum:GetPropertyChangedSignal("WalkSpeed"))) do
                conn:Disable()
            end
            hum.WalkSpeed = Config.Demonology.Speed
        end
        task.wait(0.2)
    end
end)

-- Anti AFK
task.spawn(function()
    while Config.IsRunning do
        if Config.Demonology.AntiAFK and root then
            root.CFrame = root.CFrame + Vector3.new(0, 3, 0)
        end
        task.wait(60)
    end
end)

-- Fling
task.spawn(function()
    local movel = 0.1
    while Config.IsRunning do
        if Config.Demonology.Fling and root then
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
        if Config.Demonology.AntiFling then
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

-- Item Grab Remote
local toolRE = ReplicatedStorage.Events.RequestItemPickup

-- Ghost Visible & Auto Hide
local originalStates = {}
local function cacheGhost()
    local ghost = Workspace:FindFirstChild("Ghost")
    if not ghost then return end
    local visibleParts = ghost:FindFirstChild("VisibleParts")
    if not visibleParts then return end
    for _, obj in pairs(visibleParts:GetDescendants()) do
        if obj:IsA("BasePart") and not originalStates[obj] then
            originalStates[obj] = { Transparency = obj.Transparency, LocalTransparencyModifier = obj.LocalTransparencyModifier, Decals = {} }
            for _, decal in pairs(obj:GetDescendants()) do
                if decal:IsA("Decal") then originalStates[obj].Decals[decal] = decal.Transparency end
            end
        end
    end
end

local function restoreOriginal()
    for obj, state in pairs(originalStates) do
        if obj and obj:IsA("BasePart") then
            obj.Transparency = state.Transparency
            obj.LocalTransparencyModifier = state.LocalTransparencyModifier
            for decal, oldT in pairs(state.Decals) do
                if decal and decal:IsA("Decal") then decal.Transparency = oldT end
            end
        end
    end
end

local lastDoorState = nil
task.spawn(function()
    while Config.IsRunning do
        task.wait(1)
        
        if Config.Demonology.AutoHide then
            local exitDoor = Workspace:FindFirstChild("Doors")
            exitDoor = exitDoor and exitDoor:FindFirstChild("ExitDoor")
            local isLocked = exitDoor and exitDoor:GetAttribute("Locked") or exitDoor and exitDoor:FindFirstChild("Locked")
            
            if exitDoor and lastDoorState == false and isLocked == true then
                local targetLocation = Workspace:FindFirstChild("Map")
                targetLocation = targetLocation and targetLocation:FindFirstChild("Rooms")
                targetLocation = targetLocation and targetLocation:FindFirstChild("Base Camp")
                targetLocation = targetLocation and targetLocation:FindFirstChild("EnergyMonitorFeed")
                if targetLocation and targetLocation:IsA("BasePart") and root then
                    root.CFrame = targetLocation.CFrame + Vector3.new(0, 5, 0)
                end
            end
            lastDoorState = isLocked
        else
            lastDoorState = nil
        end

        if Config.Demonology.GhostVisible then
            local ghost = Workspace:FindFirstChild("Ghost")
            if ghost then
                local visibleParts = ghost:FindFirstChild("VisibleParts")
                if visibleParts then
                    for _, obj in pairs(visibleParts:GetDescendants()) do
                        if obj:IsA("BasePart") then
                            obj.Transparency = 0
                            obj.LocalTransparencyModifier = 0
                            for _, decal in pairs(obj:GetDescendants()) do
                                if decal:IsA("Decal") then decal.Transparency = 0 end
                            end
                        end
                    end
                end
            end
        end
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
    local child = obj:FindFirstChild("Health")
    return child and child:IsA("Script")
end

local function isGhostObject(obj)
    local ghost = obj:FindFirstChild("VisibleParts")
    return ghost and ghost:IsA("Model")
end

local function isItem(obj)
    return obj:IsA("BasePart") and obj.Name == "Handle" and obj.Parent and obj.Parent.Parent and obj.Parent.Parent.Name == "Items"
end

local function isHandprint(obj)
    return obj:IsA("BasePart") and obj.Parent and obj.Parent.Name == "Handprints"
end

local function isOrb(obj)
    return obj:IsA("BasePart") and obj.Parent and obj.Parent.Name == "Workspace"
end

local function passesFilter(obj)
    if not Config.Demonology.ESPTypes or #Config.Demonology.ESPTypes == 0 then return false end
    if contains(Config.Demonology.ESPTypes, "Players") and isPlayerObject(obj) then return true end
    if contains(Config.Demonology.ESPTypes, "Ghosts") and isGhostObject(obj) then return true end
    if contains(Config.Demonology.ESPTypes, "Items") and isItem(obj) then return true end
    if contains(Config.Demonology.ESPTypes, "Handprints") and isHandprint(obj) then return true end
    if contains(Config.Demonology.ESPTypes, "Ghost Orb") and isOrb(obj) then return true end
    return false
end

local function getObjColor(obj)
    if isItem(obj) then return Color3.fromRGB(255, 255, 0) end
    if isGhostObject(obj) then return Color3.fromRGB(255, 0, 0) end
    if isHandprint(obj) then return Color3.fromRGB(0, 128, 0) end
    if isOrb(obj) then return Color3.fromRGB(0, 0, 0) end
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
    if not Config.Demonology.ESPHighlight then
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
    if not (Config.Demonology.ESPNames or Config.Demonology.ESPStuds) then
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
    if not Config.Demonology.ESPTracers then
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
    if not Config.Demonology.ESPBoxes then
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
        for _, obj in pairs(Workspace:GetChildren()) do
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

            if tracers[obj] and isVisible and Config.Demonology.ESPTracers then
                tracers[obj].Visible = true
                tracers[obj].Color = color
                tracers[obj].From = Vector2.new(viewportSize.X / 2, viewportSize.Y)
                tracers[obj].To = Vector2.new(screenPos.X, screenPos.Y)
            elseif tracers[obj] then
                tracers[obj].Visible = false
            end

            if data.billboard then
                data.billboard.Enabled = isVisible and (Config.Demonology.ESPNames or Config.Demonology.ESPStuds)
                if data.billboard.Enabled and myRoot then
                    local targetLabel = data.nameLabel
                    if targetLabel then
                        local dist = (Camera.CFrame.Position - worldPos).Magnitude
                        if Config.Demonology.ESPNames and Config.Demonology.ESPStuds then
                            targetLabel.Text = obj.Name .. " (" .. string.format("%.0fm", dist) .. ")"
                        elseif Config.Demonology.ESPNames then
                            targetLabel.Text = obj.Name
                        elseif Config.Demonology.ESPStuds then
                            targetLabel.Text = string.format("%.0fm", dist)
                        end
                        targetLabel.TextColor3 = color
                    end
                end
            end

            if boxes[obj] and isVisible and Config.Demonology.ESPBoxes then
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

-- Status Labels
local orbStatusLabel = nil
local handprintStatusLabel = nil

-- UI
local function InitUI()
    local success, WindUI = pcall(function()
        return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end)
    if not success then return end

    local Window = WindUI:CreateWindow({
        Title = "MIZUKAGE OFFICIAL",
        Icon = "skull",
        Author = "Demonology",
        Folder = "MizukageDemonology",
        Size = UDim2.fromOffset(700, 550),
        Theme = "Dark",
        Accent = Color3.fromRGB(150, 0, 255),
        SideBarWidth = 220,
        HasOutline = true,
    })

    local MainTab = Window:Tab({ Title = "Helper", Icon = "hammer" })
    local EspTab = Window:Tab({ Title = "ESP", Icon = "eye" })
    local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
    local MiscTab = Window:Tab({ Title = "Misc", Icon = "more-horizontal" })

    -- Main Tab - Items
    MainTab:Section({ Title = "🛠️ Items" })
    MainTab:Button({ Title = "Grab Video Camera", Variant = "Secondary", Callback = function() toolRE:FireServer(Workspace:WaitForChild("Items"):WaitForChild("1")) end })
    MainTab:Button({ Title = "Grab Thermometer", Variant = "Secondary", Callback = function() toolRE:FireServer(Workspace:WaitForChild("Items"):WaitForChild("2")) end })
    MainTab:Button({ Title = "Grab Spirit Book", Variant = "Secondary", Callback = function() toolRE:FireServer(Workspace:WaitForChild("Items"):WaitForChild("3")) end })
    MainTab:Button({ Title = "Grab Blacklight", Variant = "Secondary", Callback = function() toolRE:FireServer(Workspace:WaitForChild("Items"):WaitForChild("4")) end })
    MainTab:Button({ Title = "Grab Spirit Box", Variant = "Secondary", Callback = function() toolRE:FireServer(Workspace:WaitForChild("Items"):WaitForChild("5")) end })
    MainTab:Button({ Title = "Grab EMF Reader", Variant = "Secondary", Callback = function() toolRE:FireServer(Workspace:WaitForChild("Items"):WaitForChild("6")) end })
    MainTab:Button({ Title = "Grab Flashlight", Variant = "Secondary", Callback = function() toolRE:FireServer(Workspace:WaitForChild("Items"):WaitForChild("7")) end })
    MainTab:Button({ Title = "Grab Laser Projector", Variant = "Secondary", Callback = function() toolRE:FireServer(Workspace:WaitForChild("Items"):WaitForChild("8")) end })
    MainTab:Button({ Title = "Grab Flower Pot", Variant = "Secondary", Callback = function() toolRE:FireServer(Workspace:WaitForChild("Items"):WaitForChild("9")) end })

    -- Main Tab - Ghost
    MainTab:Section({ Title = "👻 Ghost" })
    MainTab:Toggle({ Title = "Visible Ghost", Default = Config.Demonology.GhostVisible, Callback = function(s)
        if not s then restoreOriginal() end
        Config.Demonology.GhostVisible = s
    end })
    MainTab:Toggle({ Title = "Auto Hide (Haunt)", Default = Config.Demonology.AutoHide, Callback = function(s) Config.Demonology.AutoHide = s end })

    -- Status Labels
    MainTab:Section({ Title = "Status" })
    orbStatusLabel = MainTab:Paragraph({ Title = "GhostOrb Status", Desc = "NOT FOUND" })
    handprintStatusLabel = MainTab:Paragraph({ Title = "Handprints Status", Desc = "NOT FOUND" })

    task.spawn(function()
        while Config.IsRunning do
            task.wait(1)
            local orb = Workspace:FindFirstChild("GhostOrb")
            if orb and orb:IsA("BasePart") then
                orbStatusLabel:Set("FOUND")
            else
                orbStatusLabel:Set("NOT FOUND")
            end

            local hpFolder = Workspace:FindFirstChild("Handprints")
            local foundHandprint = false
            if hpFolder and hpFolder:IsA("Folder") then
                for _, obj in pairs(hpFolder:GetDescendants()) do
                    if obj:IsA("BasePart") then foundHandprint = true; break end
                end
            end
            if foundHandprint then
                handprintStatusLabel:Set("FOUND")
            else
                handprintStatusLabel:Set("NOT FOUND")
            end
        end
    end)

    -- ESP Tab
    EspTab:Section({ Title = "ESP Settings" })
    EspTab:Button({ Title = "Full Bright", Variant = "Secondary", Callback = function()
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ShadowSoftness = 0
        Lighting.GlobalShadows = false
    end })
    EspTab:Dropdown({ Title = "ESP Types", Values = {"Ghosts", "Players", "Items", "Handprints", "Ghost Orb"}, Multi = true, Value = Config.Demonology.ESPTypes, Callback = function(v) Config.Demonology.ESPTypes = v end })
    EspTab:Toggle({ Title = "Highlight Objects", Default = Config.Demonology.ESPHighlight, Callback = function(s) Config.Demonology.ESPHighlight = s end })
    EspTab:Toggle({ Title = "Show Tracers", Default = Config.Demonology.ESPTracers, Callback = function(s) Config.Demonology.ESPTracers = s end })
    EspTab:Toggle({ Title = "Show Boxes", Default = Config.Demonology.ESPBoxes, Callback = function(s) Config.Demonology.ESPBoxes = s end })
    EspTab:Toggle({ Title = "Show Names", Default = Config.Demonology.ESPNames, Callback = function(s) Config.Demonology.ESPNames = s end })
    EspTab:Toggle({ Title = "Show Studs", Default = Config.Demonology.ESPStuds, Callback = function(s) Config.Demonology.ESPStuds = s end })

    -- Player Tab
    PlayerTab:Section({ Title = "Player Mods" })
    PlayerTab:Toggle({ Title = "Noclip", Default = Config.Demonology.Noclip, Callback = function(s) Config.Demonology.Noclip = s; toggleNoclip(s) end })
    PlayerTab:Toggle({ Title = "WalkSpeed Changer", Default = Config.Demonology.Walk, Callback = function(s) Config.Demonology.Walk = s end })
    PlayerTab:Slider({ Title = "WalkSpeed", Min = 16, Max = 100, Step = 1, Default = Config.Demonology.Speed, Callback = function(v) Config.Demonology.Speed = v end })

    -- Misc Tab
    MiscTab:Section({ Title = "Misc" })
    MiscTab:Toggle({ Title = "Anti AFK", Default = Config.Demonology.AntiAFK, Callback = function(s) Config.Demonology.AntiAFK = s end })
    MiscTab:Toggle({ Title = "Anti Fling", Default = Config.Demonology.AntiFling, Callback = function(s) Config.Demonology.AntiFling = s end })
    MiscTab:Toggle({ Title = "Touch Fling", Default = Config.Demonology.Fling, Callback = function(s) Config.Demonology.Fling = s end })

    WindUI:Notify({ Title = "Mizukage System", Content = "Demonology loaded!", Duration = 3 })
end

cacheGhost()
task.spawn(InitUI)
