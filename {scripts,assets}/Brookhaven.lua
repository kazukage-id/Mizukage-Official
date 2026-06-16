-- MIZUKAGE OFFICIAL - Brookhaven
-- Fitur: Loop Fling, Bring Target, Teleport, Noclip, dll.

if getgenv().MizuBrookhavenLoaded then return end
getgenv().MizuBrookhavenLoaded = true

getgenv().MizuConfig = getgenv().MizuConfig or { IsRunning = true }
local Config = getgenv().MizuConfig
Config.Brookhaven = Config.Brookhaven or {
    SelectedPlayer = "",
    SelectedTPlayer = "",
    LoopFling = false,
    LoopTP = false,
    Walk = false,
    Speed = 16,
    Noclip = false,
    AntiAFK = false,
    Fling = false,
    AntiFling = false,
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local lp = Players.LocalPlayer

local playerNames = {}
local function updatePlayerList()
    playerNames = {}
    for _, player in pairs(Players:GetPlayers()) do
        table.insert(playerNames, player.Name)
    end
end
updatePlayerList()

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
        if Config.Brookhaven.Walk and hum then
            for _, conn in ipairs(getconnections(hum:GetPropertyChangedSignal("WalkSpeed"))) do
                conn:Disable()
            end
            hum.WalkSpeed = Config.Brookhaven.Speed
        end
        task.wait(0.2)
    end
end)

-- Anti AFK
task.spawn(function()
    while Config.IsRunning do
        if Config.Brookhaven.AntiAFK and root then
            root.CFrame = root.CFrame + Vector3.new(0, 3, 0)
        end
        task.wait(60)
    end
end)

-- Fling
task.spawn(function()
    local movel = 0.1
    while Config.IsRunning do
        if Config.Brookhaven.Fling and root then
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
        if Config.Brookhaven.AntiFling then
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

-- Loop Fling
task.spawn(function()
    while Config.IsRunning do
        if Config.Brookhaven.LoopFling then
            local savedCF = root and root.CFrame or CFrame.new()
            local hasCouch = false
            local couchTool = nil
            
            for _, item in pairs(lp.Backpack:GetChildren()) do
                if item.Name == "Couch" then
                    hasCouch = true
                    couchTool = item
                    break
                end
            end
            
            if not hasCouch and lp.Character then
                for _, item in pairs(lp.Character:GetChildren()) do
                    if item:IsA("Tool") and item.Name == "Couch" then
                        hasCouch = true
                        couchTool = item
                        break
                    end
                end
            end
            
            if not hasCouch then
                local args = { "PickingTools", "Couch" }
                game:GetService("ReplicatedStorage"):WaitForChild("RE"):WaitForChild("1Too1l"):InvokeServer(unpack(args))
            end
            
            if couchTool and couchTool.Parent == lp.Backpack then
                couchTool.Parent = lp.Character
            end
            
            local targetPlayer = Players:FindFirstChild(Config.Brookhaven.SelectedPlayer)
            if targetPlayer and targetPlayer.Character and root then
                if (root.Position - targetPlayer.Character.HumanoidRootPart.Position).Magnitude < 5000 then
                    savedCF = root.CFrame
                end
                
                local seat1 = couchTool and couchTool:FindFirstChild("Seat1")
                local seat2 = couchTool and couchTool:FindFirstChild("Seat2")
                
                if seat1 and seat1.Occupant or seat2 and seat2.Occupant then
                    root.CFrame = CFrame.new(9999999, 9999999, 9999999)
                    task.wait(0.5)
                    if couchTool and couchTool.Parent == lp.Character then
                        couchTool.Parent = lp.Backpack
                    end
                    task.wait(0.5)
                    root.CFrame = savedCF
                    
                    repeat task.wait() until targetPlayer and targetPlayer.Character and (targetPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude < 1000
                else
                    if targetPlayer.Character.HumanoidRootPart then
                        root.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2) + Vector3.new(0, -5, 0)
                    end
                end
            end
        end
        task.wait(0.01)
    end
end)

-- Bring
local function bring()
    local oldPos = root.CFrame
    local hasCouch = false
    local couchTool = nil
    
    for _, item in pairs(lp.Backpack:GetChildren()) do
        if item.Name == "Couch" then
            hasCouch = true
            couchTool = item
            break
        end
    end
    
    if not hasCouch and lp.Character then
        for _, item in pairs(lp.Character:GetChildren()) do
            if item:IsA("Tool") and item.Name == "Couch" then
                hasCouch = true
                couchTool = item
                break
            end
        end
    end
    
    if not hasCouch then
        local args = { "PickingTools", "Couch" }
        game:GetService("ReplicatedStorage"):WaitForChild("RE"):WaitForChild("1Too1l"):InvokeServer(unpack(args))
    end
    
    if couchTool and couchTool.Parent == lp.Backpack then
        couchTool.Parent = lp.Character
    end
    
    local targetPlayer = Players:FindFirstChild(Config.Brookhaven.SelectedPlayer)
    while targetPlayer and targetPlayer.Character and root do
        local seat1 = couchTool and couchTool:FindFirstChild("Seat1")
        local seat2 = couchTool and couchTool:FindFirstChild("Seat2")
        
        if (seat1 and seat1.Occupant) or (seat2 and seat2.Occupant) then
            root.CFrame = oldPos
            task.wait(1)
            if couchTool and couchTool.Parent == lp.Character then
                couchTool.Parent = lp.Backpack
            end
            break
        end
        
        if targetPlayer.Character.HumanoidRootPart then 
            root.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2) + Vector3.new(0, -5, 0) 
        end
        
        task.wait()
    end
end

-- Loop Teleport
task.spawn(function()
    while Config.IsRunning do
        if Config.Brookhaven.LoopTP then
            local target = Players:FindFirstChild(Config.Brookhaven.SelectedTPlayer)
            if target and target.Character and target.Character:FindFirstChild("Head") and root then
                root.CFrame = target.Character.Head.CFrame
            end
        end
        task.wait(0.01)
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
        Author = "Brookhaven",
        Folder = "MizukageBrookhaven",
        Size = UDim2.fromOffset(650, 520),
        Theme = "Dark",
        Accent = Color3.fromRGB(0, 200, 255),
        SideBarWidth = 210,
        HasOutline = true,
    })

    local MainTab = Window:Tab({ Title = "Main", Icon = "rocket" })
    local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
    local MiscTab = Window:Tab({ Title = "Misc", Icon = "more-horizontal" })

    -- Main Tab - Trolling
    MainTab:Section({ Title = "🎯 Trolling" })
    
    local trollingDropdown = MainTab:Dropdown({ 
        Title = "Choose Target", 
        Values = playerNames, 
        Value = {},
        Callback = function(v) Config.Brookhaven.SelectedPlayer = v[1] end 
    })
    
    MainTab:Toggle({ 
        Title = "Loop Fling Target", 
        Default = Config.Brookhaven.LoopFling, 
        Callback = function(s) Config.Brookhaven.LoopFling = s end 
    })
    
    MainTab:Button({ 
        Title = "Bring Target", 
        Variant = "Secondary", 
        Callback = bring 
    })

    MainTab:Section({ Title = "📡 Teleports" })
    
    local teleportDropdown = MainTab:Dropdown({ 
        Title = "Choose Target", 
        Values = playerNames, 
        Value = {},
        Callback = function(v) Config.Brookhaven.SelectedTPlayer = v[1] end 
    })
    
    MainTab:Button({ 
        Title = "Teleport To Target", 
        Variant = "Secondary", 
        Callback = function()
            local target = Players:FindFirstChild(Config.Brookhaven.SelectedTPlayer)
            if target and target.Character and target.Character:FindFirstChild("Head") and root then
                root.CFrame = target.Character.Head.CFrame
            end
        end 
    })
    
    MainTab:Toggle({ 
        Title = "Loop Teleport To Target", 
        Default = Config.Brookhaven.LoopTP, 
        Callback = function(s) Config.Brookhaven.LoopTP = s end 
    })

    -- Player Tab
    PlayerTab:Section({ Title = "Player Mods" })
    PlayerTab:Toggle({ Title = "Noclip", Default = Config.Brookhaven.Noclip, Callback = function(s) Config.Brookhaven.Noclip = s; toggleNoclip(s) end })
    PlayerTab:Toggle({ Title = "WalkSpeed Changer", Default = Config.Brookhaven.Walk, Callback = function(s) Config.Brookhaven.Walk = s end })
    PlayerTab:Slider({ Title = "WalkSpeed", Min = 16, Max = 100, Step = 1, Default = Config.Brookhaven.Speed, Callback = function(v) Config.Brookhaven.Speed = v end })

    -- Misc Tab
    MiscTab:Section({ Title = "Misc" })
    MiscTab:Toggle({ Title = "Anti AFK", Default = Config.Brookhaven.AntiAFK, Callback = function(s) Config.Brookhaven.AntiAFK = s end })
    MiscTab:Toggle({ Title = "Anti Fling", Default = Config.Brookhaven.AntiFling, Callback = function(s) Config.Brookhaven.AntiFling = s end })
    MiscTab:Toggle({ Title = "Touch Fling", Default = Config.Brookhaven.Fling, Callback = function(s) Config.Brookhaven.Fling = s end })

    -- Update player list
    Players.PlayerAdded:Connect(function(player)
        table.insert(playerNames, player.Name)
        trollingDropdown:SetValues(playerNames)
        teleportDropdown:SetValues(playerNames)
    end)
    Players.PlayerRemoving:Connect(function(player)
        for i, name in pairs(playerNames) do
            if name == player.Name then
                table.remove(playerNames, i)
                trollingDropdown:SetValues(playerNames)
                teleportDropdown:SetValues(playerNames)
                break
            end
        end
    end)

    WindUI:Notify({ Title = "Mizukage System", Content = "Brookhaven loaded!", Duration = 3 })
end

task.spawn(InitUI)
