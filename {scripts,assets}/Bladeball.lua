-- MIZUKAGE OFFICIAL - Blade Ball
-- Fitur: Auto Parry, Auto Spam, Speed Hack, ESP, Full Bright, Boost FPS, dll.

if getgenv().MizuBladeBallLoaded then return end
getgenv().MizuBladeBallLoaded = true

getgenv().MizuConfig = getgenv().MizuConfig or { IsRunning = true }
local Config = getgenv().MizuConfig
Config.BladeBall = Config.BladeBall or {
    AutoParry = false,
    AutoSpam = false,
    SpeedHack = false,
    SpeedValue = 16,
    ESPEnabled = false,
    FullBright = false,
    BoostFPS = false,
    ParryMethod = "F",
    SpamFloatingUI = nil,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled and not (UserInputService.KeyboardEnabled or UserInputService.MouseEnabled)

-- Runtime Folder
local runtimeFolder = Workspace:FindFirstChild("Runtime") or Workspace.ChildAdded:Wait()

-- State
local State = {
    isSpamming = false,
    spamButtonRef = nil,
    autoParryConnections = {},
    spamConnections = {},
    lastParryTime = tick(),
    parryCount = 0,
    lastCurveTime = tick(),
    lastSuccessTime = tick(),
    curveAngle = 0,
}

-- Parry Execution
local function ExecuteParry()
    if isMobile then
        local success, blockGui = pcall(function() return LocalPlayer.PlayerGui.Hotbar.Block end)
        if success and blockGui then
            pcall(function() firesignal(blockGui.Activated) end)
            task.wait(0.1)
        end
        return
    end
    
    if Config.BladeBall.ParryMethod == "F" then
        VirtualInputManager:SendKeyEvent(true, "F", false, game)
        task.defer(function() VirtualInputManager:SendKeyEvent(false, "F", false, game) end)
    elseif Config.BladeBall.ParryMethod == "LeftClick" then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.defer(function() VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0) end)
    end
end

-- Ball Utilities
local BallUtils = {}

function BallUtils.GetAllBalls()
    local balls = {}
    local ballsFolder = Workspace:FindFirstChild("Balls")
    if not ballsFolder then return balls end
    
    for _, ball in ipairs(ballsFolder:GetChildren()) do
        if ball:GetAttribute("realBall") then
            ball.CanCollide = false
            table.insert(balls, ball)
        end
    end
    return balls
end

function BallUtils.GetNearestBall()
    local ballsFolder = Workspace:FindFirstChild("Balls")
    if not ballsFolder then return nil end
    
    for _, ball in ipairs(ballsFolder:GetChildren()) do
        if ball:GetAttribute("realBall") then
            ball.CanCollide = false
            return ball
        end
    end
    return nil
end

function BallUtils.ShouldParry(ball)
    if not ball then return false end
    
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local zoomies = ball:FindFirstChild("zoomies")
    if not zoomies then return false end
    
    if ball:GetAttribute("target") ~= tostring(LocalPlayer) then return false end
    if ball:FindFirstChild("ComboCounter") then return false end
    
    local slashVFX = ball:FindFirstChild("AeroDynamicSlashVFX")
    if slashVFX then
        Debris:AddItem(slashVFX, 0)
        State.lastParryTime = tick()
    end
    
    local tornado = runtimeFolder and runtimeFolder:FindFirstChild("Tornado")
    if tornado then
        local tornadoTime = tornado:GetAttribute("TornadoTime") or 1
        if tick() - State.lastParryTime < tornadoTime + 0.314159 then return false end
    end
    
    local ballSpeed = zoomies.VectorVelocity.Magnitude
    local distance = (hrp.Position - ball.Position).Magnitude
    local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    local reactionTime = math.max(ballSpeed / 2.2 + ping / 10 * 1.3 - math.min(ballSpeed / 25, 17 * 0.7), 18)
    
    if distance <= reactionTime then return true end
    
    local directionToPlayer = (ball.Position - hrp.Position).Unit
    if directionToPlayer:Dot(zoomies.VectorVelocity.Unit) > 0.92 and distance <= reactionTime * 1.35 then
        return true
    end
    
    return false
end

-- Auto Parry
local function StopAutoParry()
    for _, conn in ipairs(State.autoParryConnections) do
        if conn and conn.Connected then conn:Disconnect() end
    end
    State.autoParryConnections = {}
end

local function StartAutoParry()
    StopAutoParry()
    
    local function CheckParry()
        if not Config.BladeBall.AutoParry then return end
        
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        
        local balls = BallUtils.GetAllBalls()
        for _, ball in ipairs(balls) do
            if BallUtils.ShouldParry(ball) then
                ExecuteParry()
                State.parryCount = State.parryCount + 1
                break
            end
        end
    end
    
    table.insert(State.autoParryConnections, RunService.PreSimulation:Connect(CheckParry))
    table.insert(State.autoParryConnections, RunService.Heartbeat:Connect(CheckParry))
    table.insert(State.autoParryConnections, RunService.RenderStepped:Connect(CheckParry))
end

-- Auto Spam
local function StopAutoSpam()
    for _, conn in ipairs(State.spamConnections) do
        if conn and conn.Connected then conn:Disconnect() end
    end
    State.spamConnections = {}
    State.isSpamming = false
end

local function ToggleAutoSpam()
    State.isSpamming = not State.isSpamming
    
    if State.isSpamming then
        table.insert(State.spamConnections, RunService.Heartbeat:Connect(function()
            if State.isSpamming then ExecuteParry() end
        end))
    else
        StopAutoSpam()
    end
end

-- Speed Hack
task.spawn(function()
    while Config.IsRunning do
        if Config.BladeBall.SpeedHack then
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChild("Humanoid")
            if humanoid then humanoid.WalkSpeed = Config.BladeBall.SpeedValue end
        end
        task.wait(0.1)
    end
end)

-- ESP System
local espFolder = Instance.new("Folder")
espFolder.Name = "Mizu_ESP"
espFolder.Parent = Workspace

local function CreateESPForPlayer(player)
    if player == LocalPlayer then return end
    
    local function addHighlight(character)
        task.wait(0.5)
        local highlight = Instance.new("Highlight")
        highlight.Name = player.Name
        highlight.FillColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineColor = Color3.fromRGB(200, 200, 200)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Enabled = Config.BladeBall.ESPEnabled or false
        highlight.Adornee = character
        highlight.Parent = espFolder
        
        player.CharacterAdded:Connect(function(newChar)
            task.wait(0.5)
            highlight.Adornee = newChar
        end)
    end
    
    if player.Character then addHighlight(player.Character) end
    player.CharacterAdded:Connect(addHighlight)
end

for _, player in ipairs(Players:GetPlayers()) do CreateESPForPlayer(player) end
Players.PlayerAdded:Connect(CreateESPForPlayer)

-- Full Bright
local savedLighting = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd = Lighting.FogEnd,
    ClockTime = Lighting.ClockTime
}

task.spawn(function()
    while Config.IsRunning do
        if Config.BladeBall.FullBright then
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.FogEnd = 1000000000
            Lighting.ClockTime = 14
        end
        task.wait(0.5)
    end
end)

-- Boost FPS
task.spawn(function()
    while Config.IsRunning do
        if Config.BladeBall.BoostFPS then
            settings().Rendering.QualityLevel = 1
            settings().Rendering.EnableFRM = false
            settings().Physics.AllowSleep = true
            settings().Physics.PhysicsEnvironmentalThrottle = 1
            
            local terrain = Workspace:FindFirstChildWhichIsA("Terrain")
            if terrain then
                terrain.WaterWaveSize = 0
                terrain.WaterWaveSpeed = 0
            end
            
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 1000000000
            
            pcall(function()
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") then
                        obj.Enabled = false
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- Keyboard Shortcuts
if not isMobile then
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.E and Config.BladeBall.AutoSpam then ToggleAutoSpam() end
    end)
end

-- UI
local function InitUI()
    local success, WindUI = pcall(function()
        return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end)
    if not success then return end

    local Window = WindUI:CreateWindow({
        Title = "MIZUKAGE OFFICIAL",
        Icon = "skull",
        Author = "Blade Ball",
        Folder = "MizukageBladeBall",
        Size = UDim2.fromOffset(680, 540),
        Theme = "Dark",
        Accent = Color3.fromRGB(0, 255, 150),
        SideBarWidth = 210,
        HasOutline = true,
    })

    local MainPage = Window:Tab({ Title = "Main", Icon = "rocket" })
    local VisualPage = Window:Tab({ Title = "Visual", Icon = "eye" })
    local SettingPage = Window:Tab({ Title = "Setting", Icon = "settings" })

    -- Main Page
    MainPage:Section({ Title = "🛡️ Auto Parry" })
    MainPage:Toggle({ Title = "Auto Parry", Default = Config.BladeBall.AutoParry, Callback = function(s) Config.BladeBall.AutoParry = s; if s then StartAutoParry() else StopAutoParry() end end })
    MainPage:Toggle({ Title = "Auto Spam Parry", Default = Config.BladeBall.AutoSpam, Callback = function(s) Config.BladeBall.AutoSpam = s; if s then ToggleAutoSpam() end end })

    MainPage:Section({ Title = "Parry Method" })
    MainPage:Dropdown({ Title = "Parry Method", Values = {"F", "LeftClick"}, Value = Config.BladeBall.ParryMethod, Callback = function(v) Config.BladeBall.ParryMethod = v[1] end })

    MainPage:Section({ Title = "⚡ Speed Hack" })
    MainPage:Slider({ Title = "Speed Value", Min = 16, Max = 80, Step = 1, Default = Config.BladeBall.SpeedValue, Callback = function(v) Config.BladeBall.SpeedValue = v end })
    MainPage:Toggle({ Title = "Enable Speed Hack", Default = Config.BladeBall.SpeedHack, Callback = function(s) Config.BladeBall.SpeedHack = s end })

    -- Visual Page
    VisualPage:Section({ Title = "ESP Player" })
    VisualPage:Toggle({ Title = "Enable ESP", Default = Config.BladeBall.ESPEnabled, Callback = function(s) Config.BladeBall.ESPEnabled = s; for _, highlight in ipairs(espFolder:GetChildren()) do if highlight:IsA("Highlight") then highlight.Enabled = s end end end })

    VisualPage:Section({ Title = "Full Bright" })
    VisualPage:Toggle({ Title = "Enable Full Bright", Default = Config.BladeBall.FullBright, Callback = function(s) Config.BladeBall.FullBright = s end })

    -- Setting Page
    SettingPage:Section({ Title = "⚙️ Performance" })
    SettingPage:Toggle({ Title = "Boost FPS", Default = Config.BladeBall.BoostFPS, Callback = function(s) Config.BladeBall.BoostFPS = s end })

    SettingPage:Section({ Title = "Info" })
    SettingPage:Paragraph({ Title = "Mizukage Blade Ball", Desc = "Version: 2.0" })
    SettingPage:Paragraph({ Title = "Keybind", Desc = "E = Toggle Auto Spam" })

    WindUI:Notify({ Title = "Mizukage System", Content = "Blade Ball loaded!", Duration = 3 })
end

task.spawn(InitUI)
