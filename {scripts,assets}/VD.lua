-- MIZUKAGE OFFICIAL - Violence District
-- Fitur: ESP (Survivor, Killer, Generator, Gate, Pallet, Hook, Window, Tree, Gift)
-- Aimbot The Veil, Auto Generator, Auto Heal, Bypass Gate, Kill All, dll.

if getgenv().MizuViolenceLoaded then return end
getgenv().MizuViolenceLoaded = true

getgenv().MizuConfig = getgenv().MizuConfig or { IsRunning = true }
local Config = getgenv().MizuConfig
Config.Violence = Config.Violence or {
    ESPEnabled = false,
    ESP_SURVIVOR = false,
    ESP_MURDER = false,
    ESP_GENERATOR = false,
    ESP_GATE = false,
    ESP_PALLET = false,
    ESP_WINDOW = false,
    ESP_PUMPKIN = false,
    ESP_HOOK = false,
    ESP_TREE = false,
    ESP_GIFT = false,
    ShowName = true,
    ShowDistance = true,
    ShowHP = true,
    ShowHighlight = true,
    ShowPercent = true,
    BypassGate = false,
    AutoGenPerfect = false,
    AutoGenNotPerfect = false,
    AutoHealPerfect = false,
    AutoHealNotPerfect = false,
    AutoLever = false,
    KillAll = false,
    AutoCarry = false,
    AutoHook = false,
    NoFlashlight = false,
    AimbotEnabled = false,
    AimbotChargeEnabled = false,
    AimbotPitchMin = -1,
    AimbotPitchMax = 30,
    AimbotToughWall = true,
    FullBright = false,
    NoFog = false,
    AntiAFK = true,
    SpeedEnabled = false,
    SpeedValue = 5,
    Noclip = false,
    NoFall = false,
    HitboxEnabled = false,
    HitboxSize = 10,
    HitboxTransparency = 0.95,
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- ESP System
local espObjects = {}
local ESPColors = {
    SURVIVOR = Color3.fromRGB(0, 0, 255),
    MURDERER = Color3.fromRGB(255, 0, 0),
    GENERATOR = Color3.fromRGB(255, 255, 255),
    GENERATOR_DONE = Color3.fromRGB(0, 255, 0),
    GATE = Color3.fromRGB(255, 255, 255),
    PALLET = Color3.fromRGB(255, 255, 0),
    TREE = Color3.fromRGB(0, 255, 0),
    GIFT = Color3.fromRGB(255, 0, 0),
    WINDOW = Color3.fromRGB(175, 215, 230),
    HOOK = Color3.fromRGB(255, 0, 0),
    OUTLINE = Color3.fromRGB(0, 0, 0),
}

local function removeESP(obj)
    if espObjects[obj] then
        local data = espObjects[obj]
        if data.highlight then data.highlight:Destroy() end
        if data.nameLabel and data.nameLabel.Parent then
            data.nameLabel.Parent.Parent:Destroy()
        end
        espObjects[obj] = nil
    end
end

local function createESP(obj, baseColor)
    if not obj or obj.Name == "Lobby" then return end
    if espObjects[obj] then
        local data = espObjects[obj]
        if data.highlight then
            data.highlight.FillColor = baseColor
            data.highlight.OutlineColor = baseColor
            data.highlight.Enabled = Config.Violence.ShowHighlight
        end
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Adornee = obj
    highlight.FillColor = baseColor
    highlight.FillTransparency = 0.8
    highlight.OutlineColor = baseColor
    highlight.OutlineTransparency = 0.1
    highlight.Enabled = Config.Violence.ShowHighlight
    highlight.Parent = obj

    local bill = Instance.new("BillboardGui")
    bill.Size = UDim2.new(0, 200, 0, 50)
    bill.Adornee = obj
    bill.AlwaysOnTop = true
    bill.Parent = obj

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Parent = bill

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.33, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = baseColor
    nameLabel.TextStrokeColor3 = ESPColors.OUTLINE
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Text = obj.Name
    nameLabel.Visible = Config.Violence.ShowName
    nameLabel.Parent = frame

    local hpLabel = Instance.new("TextLabel")
    hpLabel.Size = UDim2.new(1, 0, 0.33, 0)
    hpLabel.Position = UDim2.new(0, 0, 0.33, 0)
    hpLabel.BackgroundTransparency = 1
    hpLabel.Font = Enum.Font.SourceSansBold
    hpLabel.TextSize = 14
    hpLabel.TextColor3 = baseColor
    hpLabel.TextStrokeColor3 = ESPColors.OUTLINE
    hpLabel.TextStrokeTransparency = 0
    hpLabel.Text = ""
    hpLabel.Parent = frame

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0.33, 0)
    distLabel.Position = UDim2.new(0, 0, 0.66, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Font = Enum.Font.SourceSansBold
    distLabel.TextSize = 14
    distLabel.TextColor3 = baseColor
    distLabel.TextStrokeColor3 = ESPColors.OUTLINE
    distLabel.TextStrokeTransparency = 0
    distLabel.Text = ""
    distLabel.Parent = frame

    espObjects[obj] = {
        highlight = highlight,
        nameLabel = nameLabel,
        hpLabel = hpLabel,
        distLabel = distLabel,
        color = baseColor
    }
end

-- Map Folders
local function getMapFolders()
    local folders = {}
    local mainMap = workspace:FindFirstChild("Map")
    if not mainMap then return folders end
    table.insert(folders, mainMap)
    local rooftop = mainMap:FindFirstChild("Rooftop")
    if rooftop then
        table.insert(folders, rooftop)
        local rooftopModel = rooftop:FindFirstChild("Model")
        if rooftopModel then table.insert(folders, rooftopModel) end
    end
    local maze2 = mainMap:FindFirstChild("Maze2")
    if maze2 then table.insert(folders, maze2) end
    local model = mainMap:FindFirstChild("Model")
    if model then table.insert(folders, model) end
    local hooks = mainMap:FindFirstChild("Hooks")
    if hooks then table.insert(folders, hooks) end
    local pallets = mainMap:FindFirstChild("Pallets")
    if pallets then table.insert(folders, pallets) end
    local gens = mainMap:FindFirstChild("Gens")
    if gens then table.insert(folders, gens) end
    return folders
end

local function getFolderGenerator()
    local folders = {}
    for _, folder in pairs(getMapFolders()) do
        for _, child in pairs(folder:GetChildren()) do
            if child.Name == "Generator" and child:IsA("Model") then
                table.insert(folders, child)
            end
        end
    end
    return folders
end

local function getGeneratorProgress(gen)
    local progress = 0
    if gen:GetAttribute("Progress") then
        progress = gen:GetAttribute("Progress")
    elseif gen:GetAttribute("RepairProgress") then
        progress = gen:GetAttribute("RepairProgress")
    else
        for _, child in pairs(gen:GetDescendants()) do
            if child:IsA("NumberValue") or child:IsA("IntValue") then
                local n = child.Name:lower()
                if n:find("progress") or n:find("repair") or n:find("percent") then
                    progress = child.Value
                    break
                end
            end
        end
    end
    progress = (progress > 1) and progress / 100 or progress
    return math.clamp(progress, 0, 1)
end

local function generatorFinished(gen)
    return getGeneratorProgress(gen) >= 0.99 or gen:FindFirstChild("Finished") or gen:FindFirstChild("Repaired")
end

local function getProgressColor(percent)
    if percent < 0.5 then
        local t = percent / 0.5
        return Color3.fromRGB(255 - (255 - 153) * t, 255, 255 - (255 - 153) * t)
    else
        local t = (percent - 0.5) / 0.5
        return Color3.fromRGB(153 * (1 - t), 255, 153 * (1 - t))
    end
end

-- ESP Update
task.spawn(function()
    while Config.IsRunning do
        task.wait(0.5)
        if not Config.Violence.ESPEnabled then
            for obj, _ in pairs(espObjects) do removeESP(obj) end
            continue
        end

        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end

        -- Players
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character and player.Character ~= LocalPlayer.Character and player.Character.Name ~= "Lobby" then
                local isMurderer = player.Character:FindFirstChild("Weapon") ~= nil
                if isMurderer and Config.Violence.ESP_MURDER then
                    createESP(player.Character, ESPColors.MURDERER)
                elseif not isMurderer and Config.Violence.ESP_SURVIVOR then
                    createESP(player.Character, ESPColors.SURVIVOR)
                else
                    removeESP(player.Character)
                end
            end
        end

        -- Generators
        if Config.Violence.ESP_GENERATOR then
            for _, gen in pairs(getFolderGenerator()) do
                local progress = getGeneratorProgress(gen)
                local isFinished = generatorFinished(gen)
                local baseColor = isFinished and ESPColors.GENERATOR_DONE or getProgressColor(progress)
                createESP(gen, baseColor)
                local data = espObjects[gen]
                if data and Config.Violence.ShowName then
                    data.nameLabel.Text = gen.Name .. (Config.Violence.ShowPercent and " | " .. math.floor(progress * 100) .. "%" or "")
                    data.nameLabel.TextColor3 = baseColor
                end
            end
        end

        -- Gates, Pallets, Windows, Hooks
        for _, folder in pairs(getMapFolders()) do
            for _, obj in pairs(folder:GetChildren()) do
                if obj.Name == "Gate" and Config.Violence.ESP_GATE then
                    createESP(obj, ESPColors.GATE)
                elseif obj.Name == "Palletwrong" and Config.Violence.ESP_PALLET then
                    createESP(obj, ESPColors.PALLET)
                elseif obj.Name == "Window" and Config.Violence.ESP_WINDOW then
                    createESP(obj, ESPColors.WINDOW)
                elseif obj.Name == "Hook" and Config.Violence.ESP_HOOK then
                    local mdl = obj:FindFirstChild("Model")
                    if mdl then createESP(mdl, ESPColors.HOOK) end
                end
            end
        end

        -- Update labels
        for obj, data in pairs(espObjects) do
            if obj and obj.Parent and obj.Name ~= "Lobby" then
                local targetPart = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if targetPart then
                    local humanoid = obj:FindFirstChildOfClass("Humanoid")
                    local isPlayer = humanoid ~= nil
                    data.nameLabel.Visible = Config.Violence.ShowName
                    if isPlayer then
                        if Config.Violence.ShowHP and humanoid then
                            data.hpLabel.Text = "[ " .. math.floor(humanoid.Health) .. " HP ]"
                            data.hpLabel.Visible = true
                        else
                            data.hpLabel.Visible = false
                        end
                        if Config.Violence.ShowDistance then
                            local dist = math.floor((hrp.Position - targetPart.Position).Magnitude)
                            data.distLabel.Text = "[ " .. dist .. " MM ]"
                            data.distLabel.Visible = true
                        else
                            data.distLabel.Visible = false
                        end
                    else
                        data.hpLabel.Visible = false
                        if Config.Violence.ShowDistance then
                            local dist = math.floor((hrp.Position - targetPart.Position).Magnitude)
                            data.distLabel.Text = "[ " .. dist .. " MM ]"
                            data.distLabel.Visible = true
                        else
                            data.distLabel.Visible = false
                        end
                    end
                    if data.highlight then
                        data.highlight.Enabled = Config.Violence.ShowHighlight
                    end
                end
            else
                removeESP(obj)
            end
        end
    end
end)

-- Bypass Gate
task.spawn(function()
    while Config.IsRunning do
        if Config.Violence.BypassGate then
            for _, folder in pairs(getMapFolders()) do
                for _, gate in pairs(folder:GetChildren()) do
                    if gate.Name == "Gate" then
                        local leftGate = gate:FindFirstChild("LeftGate")
                        local rightGate = gate:FindFirstChild("RightGate")
                        if leftGate then leftGate.Transparency = 1; leftGate.CanCollide = false end
                        if rightGate then rightGate.Transparency = 1; rightGate.CanCollide = false end
                        local box = gate:FindFirstChild("Box")
                        if box then box.CanCollide = false end
                    end
                end
            end
        end
        task.wait(1)
    end
end)

-- Auto Generator
task.spawn(function()
    while Config.IsRunning do
        if Config.Violence.AutoGenPerfect or Config.Violence.AutoGenNotPerfect then
            local playerGui = LocalPlayer:WaitForChild("PlayerGui")
            local skillRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Generator"):WaitForChild("SkillCheckResultEvent")
            local repairRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Generator"):WaitForChild("RepairEvent")
            
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local generators = getFolderGenerator()
                local closestGen, closestPoint = nil, nil
                for _, gen in pairs(generators) do
                    for i = 1, 4 do
                        local point = gen:FindFirstChild("GeneratorPoint" .. i)
                        if point and (root.Position - point.Position).Magnitude < 10 then
                            closestGen = gen; closestPoint = point; break
                        end
                    end
                    if closestGen then break end
                end
                if closestGen and closestPoint then
                    local gui = playerGui:FindFirstChild("SkillCheckPromptGui")
                    if gui then
                        local check = gui:FindFirstChild("Check")
                        if check and check.Visible then
                            if Config.Violence.AutoGenPerfect then
                                skillRemote:FireServer("success", 1, closestGen, closestPoint)
                            else
                                skillRemote:FireServer("neutral", 0, closestGen, closestPoint)
                            end
                            check.Visible = false
                        end
                    end
                end
            end
        end
        task.wait(0.15)
    end
end)

-- Auto Heal
task.spawn(function()
    while Config.IsRunning do
        if Config.Violence.AutoHealPerfect or Config.Violence.AutoHealNotPerfect then
            local playerGui = LocalPlayer:WaitForChild("PlayerGui")
            local healRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Healing"):WaitForChild("SkillCheckResultEvent")
            
            local gui = playerGui:FindFirstChild("SkillCheckPromptGui")
            if gui then
                local check = gui:FindFirstChild("Check")
                if check and check.Visible then
                    for _, plr in pairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and plr.Character then
                            local hum = plr.Character:FindFirstChild("Humanoid")
                            if hum and hum.Health <= 60 then
                                if Config.Violence.AutoHealPerfect then
                                    healRemote:FireServer("success", 1, plr.Character)
                                else
                                    healRemote:FireServer("neutral", 0, plr.Character)
                                end
                                check.Visible = false
                                break
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.15)
    end
end)

-- Auto Lever
task.spawn(function()
    while Config.IsRunning do
        if Config.Violence.AutoLever then
            local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Exit"):WaitForChild("LeverEvent")
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                for _, folder in pairs(getMapFolders()) do
                    local gate = folder:FindFirstChild("Gate")
                    if gate and gate:FindFirstChild("ExitLever") then
                        local main = gate.ExitLever:FindFirstChild("Main")
                        if main and (root.Position - main.Position).Magnitude < 10 then
                            remote:FireServer(main, true)
                        end
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

-- Kill All
task.spawn(function()
    while Config.IsRunning do
        if Config.Violence.KillAll then
            local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Attacks"):WaitForChild("BasicAttack")
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
                        local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
                        if targetRoot and humanoid and humanoid.Health > 20 then
                            root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 2)
                            remote:FireServer()
                            task.wait(0.15)
                        end
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

-- Auto Carry
task.spawn(function()
    while Config.IsRunning do
        if Config.Violence.AutoCarry then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local hum = plr.Character:FindFirstChild("Humanoid")
                        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                        if hum and hrp and hum.Health == 20 and (root.Position - hrp.Position).Magnitude < 10 then
                            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Carry"):WaitForChild("CarrySurvivorEvent"):FireServer(plr.Character)
                            task.wait(5)
                        end
                    end
                end
            end
        end
        task.wait(2.5)
    end
end)

-- Aimbot The Veil
local aimbotTarget = nil

task.spawn(function()
    while Config.IsRunning do
        if Config.Violence.AimbotEnabled or Config.Violence.AimbotChargeEnabled then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not root then task.wait(0.1); continue end

            local closest = nil
            local closestDist = math.huge
            local mouse = UserInputService:GetMouseLocation()
            
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local head = plr.Character:FindFirstChild("Head")
                    if head then
                        local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                        if onScreen then
                            local dist = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                            if dist < closestDist then
                                closestDist = dist
                                closest = plr
                            end
                        end
                    end
                end
            end

            if closest then
                local head = closest.Character:FindFirstChild("Head")
                if head then
                    local distance = (root.Position - head.Position).Magnitude
                    local pitch = Config.Violence.AimbotPitchMin + (Config.Violence.AimbotPitchMax - Config.Violence.AimbotPitchMin) * math.clamp((distance - 1) / (250 - 1), 0, 1)
                    local dir = (head.Position - Camera.CFrame.Position).Unit
                    local yaw = math.atan2(dir.X, dir.Z)
                    local pitchRad = math.rad(pitch)
                    local look = Vector3.new(math.sin(yaw) * math.cos(pitchRad), math.sin(pitchRad), math.cos(yaw) * math.cos(pitchRad))
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + look)
                end
            end
        end
        task.wait()
    end
end)

-- Full Bright
task.spawn(function()
    while Config.IsRunning do
        if Config.Violence.FullBright then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        end
        task.wait(0.5)
    end
end)

-- No Fog
task.spawn(function()
    while Config.IsRunning do
        if Config.Violence.NoFog and Lighting:FindFirstChild("Atmosphere") then
            Lighting.Atmosphere.Density = 0
        end
        task.wait(0.5)
    end
end)

-- Anti AFK
task.spawn(function()
    local vu = game:GetService("VirtualUser")
    while Config.IsRunning do
        if Config.Violence.AntiAFK then
            vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(math.random(150, 270))
            vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(math.random(150, 270))
        else
            task.wait(1)
        end
    end
end)

-- Speed
task.spawn(function()
    while Config.IsRunning do
        if Config.Violence.SpeedEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char.Humanoid.MoveDirection.Magnitude > 0 then
                char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame + char.Humanoid.MoveDirection * Config.Violence.SpeedValue * 0.004
            end
        end
        task.wait()
    end
end)

-- Noclip
local noclipConn = nil
task.spawn(function()
    while Config.IsRunning do
        if Config.Violence.Noclip then
            if not noclipConn then
                noclipConn = RunService.Stepped:Connect(function()
                    local char = LocalPlayer.Character
                    if char then
                        for _, part in pairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then part.CanCollide = false end
                        end
                    end
                end)
            end
        else
            if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- No Fall
local NoFallEnabled = false
local FallRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Mechanics"):WaitForChild("Fall")
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if Config.Violence.NoFall and self == FallRemote and method == "FireServer" then return nil end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- Hitbox
task.spawn(function()
    while Config.IsRunning do
        if Config.Violence.HitboxEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local part = player.Character.HumanoidRootPart
                    pcall(function()
                        part.Size = Vector3.new(Config.Violence.HitboxSize, Config.Violence.HitboxSize, Config.Violence.HitboxSize)
                        part.Transparency = Config.Violence.HitboxTransparency
                        part.BrickColor = BrickColor.new("Really red")
                        part.Material = Enum.Material.Neon
                        part.CanCollide = false
                    end)
                end
            end
        end
        task.wait(0.5)
    end
end)

-- No Flashlight
task.spawn(function()
    while Config.IsRunning do
        if Config.Violence.NoFlashlight then
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, descendant in pairs(playerGui:GetDescendants()) do
                    if descendant:IsA("GuiObject") and descendant.Name == "Blind" then
                        descendant:Destroy()
                    end
                end
            end
        end
        task.wait(0.5)
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
        Author = "Violence District",
        Folder = "MizukageViolence",
        Size = UDim2.fromOffset(780, 600),
        Theme = "Dark",
        Accent = Color3.fromRGB(255, 50, 50),
        SideBarWidth = 240,
        HasOutline = true,
    })

    local InfoTab = Window:Tab({ Title = "Info", Icon = "info" })
    local SurTab = Window:Tab({ Title = "Survivor", Icon = "shield" })
    local KillerTab = Window:Tab({ Title = "Killer", Icon = "swords" })
    local MasTab = Window:Tab({ Title = "Xmas", Icon = "celebration" })
    local MainTab = Window:Tab({ Title = "Main", Icon = "rocket" })
    local EspTab = Window:Tab({ Title = "ESP", Icon = "eye" })
    local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
    local HitboxTab = Window:Tab({ Title = "Hitbox", Icon = "target" })
    local TeleportTab = Window:Tab({ Title = "Teleport", Icon = "map" })

    -- ESP Tab
    EspTab:Section({ Title = "Feature ESP" })
    EspTab:Toggle({ Title = "Enable ESP", Default = Config.Violence.ESPEnabled, Callback = function(s) Config.Violence.ESPEnabled = s end })

    EspTab:Section({ Title = "ESP Role" })
    EspTab:Toggle({ Title = "ESP Survivor", Default = Config.Violence.ESP_SURVIVOR, Callback = function(s) Config.Violence.ESP_SURVIVOR = s end })
    EspTab:Toggle({ Title = "ESP Killer", Default = Config.Violence.ESP_MURDER, Callback = function(s) Config.Violence.ESP_MURDER = s end })

    EspTab:Section({ Title = "ESP Engine" })
    EspTab:Toggle({ Title = "ESP Generator", Default = Config.Violence.ESP_GENERATOR, Callback = function(s) Config.Violence.ESP_GENERATOR = s end })
    EspTab:Toggle({ Title = "ESP Gate", Default = Config.Violence.ESP_GATE, Callback = function(s) Config.Violence.ESP_GATE = s end })

    EspTab:Section({ Title = "ESP Object" })
    EspTab:Toggle({ Title = "ESP Pallet", Default = Config.Violence.ESP_PALLET, Callback = function(s) Config.Violence.ESP_PALLET = s end })
    EspTab:Toggle({ Title = "ESP Hook", Default = Config.Violence.ESP_HOOK, Callback = function(s) Config.Violence.ESP_HOOK = s end })
    EspTab:Toggle({ Title = "ESP Window", Default = Config.Violence.ESP_WINDOW, Callback = function(s) Config.Violence.ESP_WINDOW = s end })

    EspTab:Section({ Title = "ESP Event" })
    EspTab:Toggle({ Title = "ESP Tree", Default = Config.Violence.ESP_TREE, Callback = function(s) Config.Violence.ESP_TREE = s end })
    EspTab:Toggle({ Title = "ESP Gift", Default = Config.Violence.ESP_GIFT, Callback = function(s) Config.Violence.ESP_GIFT = s end })

    EspTab:Section({ Title = "ESP Settings" })
    EspTab:Toggle({ Title = "Show Name", Default = Config.Violence.ShowName, Callback = function(s) Config.Violence.ShowName = s end })
    EspTab:Toggle({ Title = "Show Distance", Default = Config.Violence.ShowDistance, Callback = function(s) Config.Violence.ShowDistance = s end })
    EspTab:Toggle({ Title = "Show Health", Default = Config.Violence.ShowHP, Callback = function(s) Config.Violence.ShowHP = s end })
    EspTab:Toggle({ Title = "Show Highlight", Default = Config.Violence.ShowHighlight, Callback = function(s) Config.Violence.ShowHighlight = s end })
    EspTab:Toggle({ Title = "Show Percent", Default = Config.Violence.ShowPercent, Callback = function(s) Config.Violence.ShowPercent = s end })

    -- Main Tab
    MainTab:Section({ Title = "Feature Bypass" })
    MainTab:Toggle({ Title = "Bypass Gate (Open Gate)", Default = Config.Violence.BypassGate, Callback = function(s) Config.Violence.BypassGate = s end })

    MainTab:Section({ Title = "Feature Visual" })
    MainTab:Toggle({ Title = "Full Bright", Default = Config.Violence.FullBright, Callback = function(s) Config.Violence.FullBright = s end })
    MainTab:Toggle({ Title = "No Fog", Default = Config.Violence.NoFog, Callback = function(s) Config.Violence.NoFog = s end })

    MainTab:Section({ Title = "Misc" })
    MainTab:Toggle({ Title = "Anti AFK", Default = Config.Violence.AntiAFK, Callback = function(s) Config.Violence.AntiAFK = s end })

    -- Survivor Tab
    SurTab:Section({ Title = "Feature Generator" })
    SurTab:Toggle({ Title = "Auto SkillCheck (Perfect)", Default = Config.Violence.AutoGenPerfect, Callback = function(s) Config.Violence.AutoGenPerfect = s end })
    SurTab:Toggle({ Title = "Auto SkillCheck (Not Perfect)", Default = Config.Violence.AutoGenNotPerfect, Callback = function(s) Config.Violence.AutoGenNotPerfect = s end })

    SurTab:Section({ Title = "Feature Heal" })
    SurTab:Toggle({ Title = "Auto SkillCheck Heal (Perfect)", Default = Config.Violence.AutoHealPerfect, Callback = function(s) Config.Violence.AutoHealPerfect = s end })
    SurTab:Toggle({ Title = "Auto SkillCheck Heal (Not Perfect)", Default = Config.Violence.AutoHealNotPerfect, Callback = function(s) Config.Violence.AutoHealNotPerfect = s end })

    SurTab:Section({ Title = "Feature Exit" })
    SurTab:Toggle({ Title = "Auto Lever (No Hold)", Default = Config.Violence.AutoLever, Callback = function(s) Config.Violence.AutoLever = s end })

    -- Killer Tab
    KillerTab:Section({ Title = "Killer: The Veil" })
    KillerTab:Toggle({ Title = "Enable Aimbot (The Veil)", Default = Config.Violence.AimbotEnabled, Callback = function(s) Config.Violence.AimbotEnabled = s end })
    KillerTab:Toggle({ Title = "Enable Aimbot Charge (The Veil)", Default = Config.Violence.AimbotChargeEnabled, Callback = function(s) Config.Violence.AimbotChargeEnabled = s end })
    KillerTab:Input({ Title = "Set Pitch Min", Placeholder = "Ex: -1", Callback = function(v) local n = tonumber(v); if n then Config.Violence.AimbotPitchMin = n end end })
    KillerTab:Input({ Title = "Set Pitch Max", Placeholder = "Ex: 30", Callback = function(v) local n = tonumber(v); if n then Config.Violence.AimbotPitchMax = n end end })
    KillerTab:Toggle({ Title = "Tough Wall", Default = Config.Violence.AimbotToughWall, Callback = function(s) Config.Violence.AimbotToughWall = s end })

    KillerTab:Section({ Title = "Feature Killer" })
    KillerTab:Toggle({ Title = "Kill All (Warning: Get Ban)", Default = Config.Violence.KillAll, Callback = function(s) Config.Violence.KillAll = s end })
    KillerTab:Toggle({ Title = "Auto Carry (Nearby Survivor)", Default = Config.Violence.AutoCarry, Callback = function(s) Config.Violence.AutoCarry = s end })
    KillerTab:Toggle({ Title = "Auto Hook (Nearby Hook)", Default = Config.Violence.AutoHook, Callback = function(s) Config.Violence.AutoHook = s end })
    KillerTab:Toggle({ Title = "No Flashlight", Default = Config.Violence.NoFlashlight, Callback = function(s) Config.Violence.NoFlashlight = s end })

    -- Player Tab
    PlayerTab:Section({ Title = "Feature Player" })
    PlayerTab:Slider({ Title = "Set Speed Value", Min = 1, Max = 999, Step = 1, Default = Config.Violence.SpeedValue, Callback = function(v) Config.Violence.SpeedValue = v end })
    PlayerTab:Toggle({ Title = "Enable Speed", Default = Config.Violence.SpeedEnabled, Callback = function(s) Config.Violence.SpeedEnabled = s end })

    PlayerTab:Section({ Title = "Feature Power" })
    PlayerTab:Toggle({ Title = "No Clip", Default = Config.Violence.Noclip, Callback = function(s) Config.Violence.Noclip = s end })
    PlayerTab:Toggle({ Title = "No Fall (Beta)", Default = Config.Violence.NoFall, Callback = function(s) Config.Violence.NoFall = s end })

    -- Hitbox Tab
    HitboxTab:Section({ Title = "Hitbox System" })
    HitboxTab:Input({ Title = "Set Transparency", Placeholder = "Ex: 0.95", Callback = function(v) local n = tonumber(v); if n then Config.Violence.HitboxTransparency = math.clamp(n, 0, 1) end end })
    HitboxTab:Input({ Title = "Set Hitbox Size", Placeholder = "Ex: 10", Callback = function(v) local n = tonumber(v); if n then Config.Violence.HitboxSize = n end end })
    HitboxTab:Toggle({ Title = "Enable Hitbox", Default = Config.Violence.HitboxEnabled, Callback = function(s) Config.Violence.HitboxEnabled = s end })

    WindUI:Notify({ Title = "Mizukage System", Content = "Violence District loaded!", Duration = 3 })
end

task.spawn(InitUI)
