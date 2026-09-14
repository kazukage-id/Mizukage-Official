-- Mizukage Official
-- TeamMizu
-- SCHOOL WAR V2

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Config = {
    AutoAttack = false,
    AutoAttackRange = 15,
    AutoAttackDelay = 0,
    ReachEnabled = false,
    ReachDistance = 30,
    KillAura = false,
    KillAuraRange = 20,
    AnimationBypass = false,
    TrailSpam = false,
    AutoCombo = false,
    LockRunSpeed = false,
    RunSpeedValue = 32,
    WalkSpeedValue = 16,
    JumpPowerValue = 50,
    InfiniteJump = false,
    Noclip = false,
    AutoFarmNPC = false,
    NPCTarget = "TownNPC4",
    SelectedTarget = nil,
    LockPosition = false,
}

local Remotes = {}
local function getRemote(name)
    if not Remotes[name] then
        Remotes[name] = ReplicatedStorage:WaitForChild(name, 10)
    end
    return Remotes[name]
end

local PunchStateEvent = getRemote("PunchStateEvent")
local DealDamageEvent = getRemote("DealDamageEvent")
local TrailEvent = getRemote("TrailEvent")
local ComboEvent = getRemote("ComboEvent")
local WeaponTrailEvent = getRemote("WeaponTrailEvent")
local BreakGlassEvent = getRemote("BreakGlassEvent")
local ChooseTeam = getRemote("ChooseTeam")

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHead()
    local char = getCharacter()
    return char and char:FindFirstChild("Head")
end

local function getDistance(target)
    local myRoot = getRoot()
    if not myRoot then return math.huge end
    local targetRoot
    if typeof(target) == "Instance" then
        if target:IsA("Model") then
            targetRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head")
        elseif target:IsA("BasePart") then
            targetRoot = target
        end
    end
    if not targetRoot then return math.huge end
    return (myRoot.Position - targetRoot.Position).Magnitude
end

local function findNearestTarget(range, includeNPCs)
    local nearest = nil
    local nearestDist = range or Config.AutoAttackRange
    local myRoot = getRoot()
    if not myRoot then return nil end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team then
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 then
                    local dist = (myRoot.Position - root.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearest = char
                    end
                end
            end
        end
    end
    if includeNPCs then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
                if hum and root and hum.Health > 0 and obj ~= getCharacter() then
                    local name = obj.Name:lower()
                    if name:find("npc") or name:find("enemy") or name:find("town") then
                        local dist = (myRoot.Position - root.Position).Magnitude
                        if dist < nearestDist then
                            nearestDist = dist
                            nearest = obj
                        end
                    end
                end
            end
        end
    end
    return nearest
end

local function findAllTargets(range)
    local targets = {}
    local myRoot = getRoot()
    if not myRoot then return targets end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team then
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if hum and root and hum.Health > 0 then
                    local dist = (myRoot.Position - root.Position).Magnitude
                    if dist <= range then
                        table.insert(targets, char)
                    end
                end
            end
        end
    end
    return targets
end

local function autoAttackOnce(target)
    if not PunchStateEvent or not DealDamageEvent then return end
    pcall(function()
        PunchStateEvent:FireServer(true)
        if target then
            DealDamageEvent:FireServer(target)
        end
        PunchStateEvent:FireServer(false)
    end)
end

local function reachAttack(target)
    if not PunchStateEvent or not DealDamageEvent then return end
    pcall(function()
        PunchStateEvent:FireServer(true)
        DealDamageEvent:FireServer(target)
        PunchStateEvent:FireServer(false)
    end)
end

local function killAuraTick()
    local targets = findAllTargets(Config.KillAuraRange)
    for _, target in ipairs(targets) do
        autoAttackOnce(target)
    end
end

local function bypassAnimationCheck()
    local char = getCharacter()
    if not char then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("punch") then
            tool.Name = "Punch_" .. tick()
        end
    end
end

local function spamTrail()
    if not TrailEvent then return end
    pcall(function()
        TrailEvent:FireServer({"RightHand", "LeftHand"})
        TrailEvent:FireServer({"RightFoot", "LeftFoot"})
        TrailEvent:FireServer({"Head"})
    end)
end

local function setupInfiniteJump()
    UserInputService.JumpRequest:Connect(function()
        if Config.InfiniteJump then
            local hum = getHumanoid()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end

local function setupNoclip()
    RunService.Stepped:Connect(function()
        if Config.Noclip then
            local char = getCharacter()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end

local function autoFarmNPC()
    if not Config.AutoFarmNPC then return end
    local target = nil
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == Config.NPCTarget then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                target = obj
                break
            end
        end
    end
    if target then
        autoAttackOnce(target)
    end
end

local speedConnection = nil
local function applySpeedLock()
    if speedConnection then
        speedConnection:Disconnect()
        speedConnection = nil
    end
    if Config.LockRunSpeed then
        speedConnection = RunService.Heartbeat:Connect(function()
            local hum = getHumanoid()
            if hum then
                if hum.MoveDirection.Magnitude > 0 then
                    hum.WalkSpeed = Config.RunSpeedValue
                else
                    hum.WalkSpeed = Config.WalkSpeedValue
                end
                hum.JumpPower = Config.JumpPowerValue
            end
        end)
    end
end

task.spawn(function()
    while task.wait() do
        if Config.AutoAttack then
            local target = Config.SelectedTarget or findNearestTarget(Config.AutoAttackRange, true)
            if target then
                autoAttackOnce(target)
            end
        end
        if Config.ReachEnabled then
            local target = Config.SelectedTarget or findNearestTarget(Config.ReachDistance, false)
            if target then
                reachAttack(target)
            end
        end
        if Config.AutoFarmNPC then
            autoFarmNPC()
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if Config.KillAura then
            killAuraTick()
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if Config.TrailSpam then
            spamTrail()
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if Config.AnimationBypass then
            bypassAnimationCheck()
        end
    end
end)

setupInfiniteJump()
setupNoclip()

local Window = Rayfield:CreateWindow({
    Name = "SCHOOL WAR V1",
    LoadingTitle = "Mizukage Official",
    LoadingSubtitle = "TeamMizu",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "Mizukage",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false,
})

local AttackTab = Window:CreateTab("Auto Attack", 4483362458)

AttackTab:CreateSection("Auto Attack")

AttackTab:CreateToggle({
    Name = "Enable Auto Attack",
    CurrentValue = false,
    Flag = "AutoAttackToggle",
    Callback = function(value)
        Config.AutoAttack = value
    end,
})

AttackTab:CreateSlider({
    Name = "Attack Range",
    Range = {5, 100},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 15,
    Flag = "AutoAttackRangeSlider",
    Callback = function(value)
        Config.AutoAttackRange = value
    end,
})

AttackTab:CreateSection("Kill Aura")

AttackTab:CreateToggle({
    Name = "Enable Kill Aura",
    CurrentValue = false,
    Flag = "KillAuraToggle",
    Callback = function(value)
        Config.KillAura = value
    end,
})

AttackTab:CreateSlider({
    Name = "Kill Aura Range",
    Range = {5, 100},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 20,
    Flag = "KillAuraRangeSlider",
    Callback = function(value)
        Config.KillAuraRange = value
    end,
})

AttackTab:CreateSection("Auto Farm NPC")

AttackTab:CreateToggle({
    Name = "Enable Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarmNPCToggle",
    Callback = function(value)
        Config.AutoFarmNPC = value
    end,
})

AttackTab:CreateInput({
    Name = "NPC Target",
    CurrentValue = "NPC",
    PlaceholderText = "Enter NPC name",
    RemoveTextAfterFocusLost = false,
    Flag = "NPCTargetInput",
    Callback = function(text)
        Config.NPCTarget = text
    end,
})

local ReachTab = Window:CreateTab("Reach Hack", 4483362458)

ReachTab:CreateSection("Reach")

ReachTab:CreateToggle({
    Name = "Enable Reach",
    CurrentValue = false,
    Flag = "ReachToggle",
    Callback = function(value)
        Config.ReachEnabled = value
    end,
})

ReachTab:CreateSlider({
    Name = "Reach Distance",
    Range = {10, 200},
    Increment = 5,
    Suffix = " studs",
    CurrentValue = 30,
    Flag = "ReachDistanceSlider",
    Callback = function(value)
        Config.ReachDistance = value
    end,
})

ReachTab:CreateSection("Manual")

ReachTab:CreateButton({
    Name = "Attack Nearest Target",
    Callback = function()
        local target = findNearestTarget(Config.ReachDistance, false)
        if target then
            reachAttack(target)
            Rayfield:Notify({
                Title = "Reach",
                Content = "Attacked " .. target.Name,
                Duration = 2,
            })
        else
            Rayfield:Notify({
                Title = "Reach",
                Content = "No target in range",
                Duration = 2,
            })
        end
    end,
})

local VisualTab = Window:CreateTab("Animation", 4483362458)

VisualTab:CreateSection("Animation")

VisualTab:CreateToggle({
    Name = "Enable Animation Bypass",
    CurrentValue = false,
    Flag = "AnimBypassToggle",
    Callback = function(value)
        Config.AnimationBypass = value
        if value then
            bypassAnimationCheck()
        end
    end,
})

VisualTab:CreateButton({
    Name = "Force Rename Tool",
    Callback = function()
        bypassAnimationCheck()
        Rayfield:Notify({
            Title = "Animation",
            Content = "Tool renamed",
            Duration = 2,
        })
    end,
})

VisualTab:CreateSection("Trail")

VisualTab:CreateToggle({
    Name = "Enable Trail Spam",
    CurrentValue = false,
    Flag = "TrailSpamToggle",
    Callback = function(value)
        Config.TrailSpam = value
    end,
})

VisualTab:CreateButton({
    Name = "Trigger Trail",
    Callback = function()
        spamTrail()
    end,
})

VisualTab:CreateSection("Combo")

VisualTab:CreateButton({
    Name = "Combo x5",
    Callback = function()
        if ComboEvent then ComboEvent:FireServer(5) end
    end,
})

VisualTab:CreateButton({
    Name = "Combo x15",
    Callback = function()
        if ComboEvent then ComboEvent:FireServer(15) end
    end,
})

VisualTab:CreateButton({
    Name = "Combo x25",
    Callback = function()
        if ComboEvent then ComboEvent:FireServer(25) end
    end,
})

VisualTab:CreateButton({
    Name = "Combo x35",
    Callback = function()
        if ComboEvent then ComboEvent:FireServer(35) end
    end,
})

local PlayerTab = Window:CreateTab("Player", 4483362458)

PlayerTab:CreateSection("Speed Lock")

PlayerTab:CreateToggle({
    Name = "Enable Speed Lock",
    CurrentValue = false,
    Flag = "LockRunSpeedToggle",
    Callback = function(value)
        Config.LockRunSpeed = value
        applySpeedLock()
        Rayfield:Notify({
            Title = "Speed Lock",
            Content = value and "Enabled" or "Disabled",
            Duration = 2,
        })
    end,
})

PlayerTab:CreateSlider({
    Name = "Run Speed",
    Range = {16, 50},
    Increment = 1,
    Suffix = " studs/s",
    CurrentValue = 28,
    Flag = "RunSpeedSlider",
    Callback = function(value)
        Config.RunSpeedValue = value
        if Config.LockRunSpeed then
            local hum = getHumanoid()
            if hum and hum.MoveDirection.Magnitude > 0 then
                hum.WalkSpeed = value
            end
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 50},
    Increment = 1,
    Suffix = " studs/s",
    CurrentValue = 16,
    Flag = "WalkSpeedSlider",
    Callback = function(value)
        Config.WalkSpeedValue = value
    end,
})

PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = {10, 100},
    Increment = 5,
    Suffix = " studs",
    CurrentValue = 30,
    Flag = "JumpPowerSlider",
    Callback = function(value)
        Config.JumpPowerValue = value
        local hum = getHumanoid()
        if hum then
            hum.JumpPower = value
            hum.UseJumpPower = true
        end
    end,
})

PlayerTab:CreateSection("Movement")

PlayerTab:CreateToggle({
    Name = "Enable Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJumpToggle",
    Callback = function(value)
        Config.InfiniteJump = value
    end,
})

PlayerTab:CreateToggle({
    Name = "Enable Noclip",
    CurrentValue = false,
    Flag = "NoclipToggle",
    Callback = function(value)
        Config.Noclip = value
    end,
})

PlayerTab:CreateSection("Actions")

PlayerTab:CreateButton({
    Name = "Apply Speed",
    Callback = function()
        local hum = getHumanoid()
        if hum then
            hum.WalkSpeed = Config.RunSpeedValue
            hum.JumpPower = Config.JumpPowerValue
            Rayfield:Notify({
                Title = "Applied",
                Content = "Speed: " .. Config.RunSpeedValue .. " Jump: " .. Config.JumpPowerValue,
                Duration = 2,
            })
        end
    end,
})

PlayerTab:CreateButton({
    Name = "Reset Speed",
    Callback = function()
        local hum = getHumanoid()
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            Config.LockRunSpeed = false
            Rayfield:Notify({
                Title = "Reset",
                Content = "Speed restored",
                Duration = 2,
            })
        end
    end,
})

local UtilTab = Window:CreateTab("Utility", 4483362458)

UtilTab:CreateSection("Teleport")

UtilTab:CreateButton({
    Name = "Teleport to Nearest",
    Callback = function()
        local target = findNearestTarget(500, false)
        if target then
            local root = getRoot()
            local targetRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head")
            if root and targetRoot then
                root.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0)
                Rayfield:Notify({
                    Title = "Teleport",
                    Content = "Teleported to " .. target.Name,
                    Duration = 2,
                })
            end
        end
    end,
})

UtilTab:CreateButton({
    Name = "Teleport to NPC",
    Callback = function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == Config.NPCTarget then
                local root = getRoot()
                local targetRoot = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
                if root and targetRoot then
                    root.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0)
                    Rayfield:Notify({
                        Title = "Teleport",
                        Content = "Teleported to " .. obj.Name,
                        Duration = 2,
                    })
                    return
                end
            end
        end
    end,
})

UtilTab:CreateSection("Info")

UtilTab:CreateButton({
    Name = "Player Info",
    Callback = function()
        local hum = getHumanoid()
        if hum then
            Rayfield:Notify({
                Title = "Player Info",
                Content = string.format("HP: %d/%d Speed: %d Jump: %d", hum.Health, hum.MaxHealth, hum.WalkSpeed, hum.JumpPower),
                Duration = 3,
            })
        end
    end,
})

UtilTab:CreateButton({
    Name = "Team Info",
    Callback = function()
        local team = LocalPlayer.Team and LocalPlayer.Team.Name or "Neutral"
        Rayfield:Notify({
            Title = "Team Info",
            Content = "Team: " .. team,
            Duration = 3,
        })
    end,
})

local SettingsTab = Window:CreateTab("Settings", 4483362458)

SettingsTab:CreateSection("Presets")

SettingsTab:CreateButton({
    Name = "Preset Max Power",
    Callback = function()
        Config.AutoAttack = true
        Config.KillAura = true
        Config.ReachEnabled = true
        Config.TrailSpam = true
        Config.AnimationBypass = true
        Config.InfiniteJump = true
        Config.Noclip = true
        Config.LockRunSpeed = true
        applySpeedLock()
        Rayfield:Notify({
            Title = "Preset",
            Content = "Max Power enabled",
            Duration = 3,
        })
    end,
})

SettingsTab:CreateButton({
    Name = "Preset Panic Off",
    Callback = function()
        Config.AutoAttack = false
        Config.KillAura = false
        Config.ReachEnabled = false
        Config.TrailSpam = false
        Config.AnimationBypass = false
        Config.InfiniteJump = false
        Config.Noclip = false
        Config.AutoFarmNPC = false
        Config.LockRunSpeed = false
        if speedConnection then
            speedConnection:Disconnect()
            speedConnection = nil
        end
        Rayfield:Notify({
            Title = "Preset",
            Content = "All features disabled",
            Duration = 3,
        })
    end,
})

SettingsTab:CreateButton({
    Name = "Preset Stealth",
    Callback = function()
        Config.AutoAttack = false
        Config.KillAura = false
        Config.ReachEnabled = false
        Config.TrailSpam = false
        Config.AnimationBypass = false
        Config.InfiniteJump = false
        Config.Noclip = false
        Config.AutoFarmNPC = false
        Config.LockRunSpeed = true
        applySpeedLock()
        Rayfield:Notify({
            Title = "Preset",
            Content = "Stealth enabled",
            Duration = 3,
        })
    end,
})

SettingsTab:CreateSection("Notification")

SettingsTab:CreateButton({
    Name = "Test Notification",
    Callback = function()
        Rayfield:Notify({
            Title = "Mizukage Official",
            Content = "System operational",
            Duration = 3,
        })
    end,
})

Rayfield:Notify({
    Title = "Mizukage Official",
    Content = "SCHOOL WAR Vloaded",
    Duration = 5,
})

game:BindToClose(function()
    Config.AutoAttack = false
    Config.KillAura = false
    Config.ReachEnabled = false
    Config.TrailSpam = false
    Config.LockRunSpeed = false
    if speedConnection then
        speedConnection:Disconnect()
    end
end)