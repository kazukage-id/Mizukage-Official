-- MIZUKAGE OFFICIAL - Murder Mystery 2
-- Fitur: Kill Aura, Auto Shoot, Auto Farm Coins, ESP, dll.

if getgenv().MizuMM2Loaded then return end
getgenv().MizuMM2Loaded = true

getgenv().MizuConfig = getgenv().MizuConfig or { IsRunning = true }
local Config = getgenv().MizuConfig
Config.MM2 = Config.MM2 or {
    KillAura = false,
    KillAuraRadius = 15,
    AutoKill = false,
    AutoShoot = false,
    Prediction = false,
    AutoFarm = false,
    AutoGrab = false,
    AutoFarmAvoid = false,
    FarmMethod = "Closest",
    Walk = false,
    Speed = 28,
    Noclip = false,
    AntiAFK = false,
    Fling = false,
    AntiFling = false,
    ESPHighlight = false,
    ESPTypes = {},
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")
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
        if Config.MM2.Walk and hum then
            for _, conn in ipairs(getconnections(hum:GetPropertyChangedSignal("WalkSpeed"))) do
                conn:Disable()
            end
            hum.WalkSpeed = Config.MM2.Speed
        end
        task.wait(0.2)
    end
end)

-- Anti AFK
task.spawn(function()
    while Config.IsRunning do
        if Config.MM2.AntiAFK and root then
            root.CFrame = root.CFrame + Vector3.new(0, 3, 0)
        end
        task.wait(60)
    end
end)

-- Fling
task.spawn(function()
    local movel = 0.1
    while Config.IsRunning do
        if Config.MM2.Fling and root then
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
        if Config.MM2.AntiFling then
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

-- Auto Grab Gun
task.spawn(function()
    while Config.IsRunning do
        if Config.MM2.AutoGrab and root then
            local gun = Workspace:FindFirstChild("GunDrop", true)
            if gun and gun:IsA("BasePart") then
                local oldPos = root.CFrame
                root.CFrame = gun.CFrame
                task.wait(0.3)
                root.CFrame = oldPos
                task.wait(1)
            end
        end
        task.wait(0.5)
    end
end)

-- Auto Shoot
task.spawn(function()
    while Config.IsRunning do
        if Config.MM2.AutoShoot then
            local gun = lp.Character and lp.Character:FindFirstChild("Gun")
            if gun and gun:FindFirstChild("Shoot") then
                local targetHRP = nil
                local murderer = nil
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= lp and p.Character then
                        local char = p.Character
                        local isMrd = char:FindFirstChild("Footsteps") or char:FindFirstChild("Sleight") or
                                       char:FindFirstChild("Decoy") or char:FindFirstChild("Ghost") or
                                       char:FindFirstChild("Fake Gun") or char:FindFirstChild("Xray") or
                                       char:FindFirstChild("Haste") or char:FindFirstChild("Trap") or
                                       char:FindFirstChild("Sprint") or char:FindFirstChild("Ninja")
                        if isMrd then
                            targetHRP = char:FindFirstChild("HumanoidRootPart")
                            murderer = char
                            break
                        end
                    end
                end
                if targetHRP and root then
                    local finalTargetCFrame = targetHRP.CFrame
                    if Config.MM2.Prediction then
                        finalTargetCFrame = targetHRP.CFrame + targetHRP.Velocity * 0.15
                    end
                    gun.Shoot:FireServer(root.CFrame, finalTargetCFrame)
                    task.wait(0.5)
                end
            end
        end
        task.wait()
    end
end)

-- Kill Aura
task.spawn(function()
    while Config.IsRunning do
        if Config.MM2.KillAura and root then
            local isMurderer = character and (character:FindFirstChild("Footsteps") or character:FindFirstChild("Sleight") or
                                character:FindFirstChild("Decoy") or character:FindFirstChild("Ghost") or
                                character:FindFirstChild("Fake Gun") or character:FindFirstChild("Xray") or
                                character:FindFirstChild("Haste") or character:FindFirstChild("Trap") or
                                character:FindFirstChild("Sprint") or character:FindFirstChild("Ninja"))
            if isMurderer then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= lp and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local targetRoot = plr.Character.HumanoidRootPart
                        if (root.Position - targetRoot.Position).Magnitude <= Config.MM2.KillAuraRadius then
                            local targetPos = root.CFrame:ToWorldSpace(CFrame.new(0, 0, -1.5))
                            targetRoot.CFrame = CFrame.new(targetPos.Position) * targetRoot.CFrame.Rotation
                        end
                    end
                end
            end
        end
        task.wait(0.05)
    end
end)

-- Kill Everyone
task.spawn(function()
    while Config.IsRunning do
        if Config.MM2.AutoKill and root then
            local isMurderer = character and (character:FindFirstChild("Footsteps") or character:FindFirstChild("Sleight") or
                                character:FindFirstChild("Decoy") or character:FindFirstChild("Ghost") or
                                character:FindFirstChild("Fake Gun") or character:FindFirstChild("Xray") or
                                character:FindFirstChild("Haste") or character:FindFirstChild("Trap") or
                                character:FindFirstChild("Sprint") or character:FindFirstChild("Ninja"))
            if isMurderer then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= lp and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local targetRoot = plr.Character.HumanoidRootPart
                        local targetPos = root.CFrame:ToWorldSpace(CFrame.new(0, 0, -1.5))
                        targetRoot.CFrame = CFrame.new(targetPos.Position) * targetRoot.CFrame.Rotation
                    end
                end
            end
        end
        task.wait(0.05)
    end
end)

-- Auto Farm Coins
task.spawn(function()
    while Config.IsRunning do
        if Config.MM2.AutoFarm then
            local isMurderer = character and (character:FindFirstChild("Footsteps") or character:FindFirstChild("Sleight") or
                                character:FindFirstChild("Decoy") or character:FindFirstChild("Ghost") or
                                character:FindFirstChild("Fake Gun") or character:FindFirstChild("Xray") or
                                character:FindFirstChild("Haste") or character:FindFirstChild("Trap") or
                                character:FindFirstChild("Sprint") or character:FindFirstChild("Ninja"))
            local CoinContainer = Workspace:FindFirstChild("CoinContainer", true)
            if CoinContainer then
                local currentMurderer = nil
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= lp and p.Character then
                        local char = p.Character
                        if char:FindFirstChild("Footsteps") or char:FindFirstChild("Decoy") or char:FindFirstChild("Sleight") or
                           char:FindFirstChild("Ghost") or char:FindFirstChild("Ninja") or char:FindFirstChild("Fake Gun") or
                           char:FindFirstChild("Xray") or char:FindFirstChild("Haste") or char:FindFirstChild("Trap") or
                           char:FindFirstChild("Sprint") then
                            currentMurderer = char:FindFirstChild("HumanoidRootPart")
                            break
                        end
                    end
                end
                local allCoins = {}
                for _, c in pairs(CoinContainer:GetChildren()) do
                    if c:IsA("BasePart") and string.find(c.Name, "Coin_Server") then
                        local isDangerous = false
                        if Config.MM2.AutoFarmAvoid and currentMurderer then
                            if (c.Position - currentMurderer.Position).Magnitude < 15 then
                                isDangerous = true
                            end
                        end
                        if not isDangerous then table.insert(allCoins, c) end
                    end
                end
                local targetCoin = nil
                if #allCoins > 0 and root then
                    if Config.MM2.FarmMethod == "Closest" then
                        local closestDist = math.huge
                        for _, coin in ipairs(allCoins) do
                            local dist = (root.Position - coin.Position).Magnitude
                            if dist < closestDist then
                                closestDist = dist
                                targetCoin = coin
                            end
                        end
                    else
                        targetCoin = allCoins[math.random(1, #allCoins)]
                    end
                end
                if targetCoin and root then
                    local tween = TweenService:Create(root, TweenInfo.new(1, Enum.EasingStyle.Linear), { CFrame = CFrame.new(targetCoin.Position) })
                    tween:Play()
                    task.wait(1.1)
                    if targetCoin and targetCoin.Parent then
                        targetCoin:Destroy()
                    end
                else
                    task.wait(0.5)
                end
            else
                task.wait(1)
            end
        else
            task.wait(1)
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

local function isMurderObject(obj)
    local child = obj:FindFirstChild("Footsteps") or obj:FindFirstChild("Sleight") or obj:FindFirstChild("Decoy") or
                   obj:FindFirstChild("Ghost") or obj:FindFirstChild("Fake Gun") or obj:FindFirstChild("Xray") or
                   obj:FindFirstChild("Haste") or obj:FindFirstChild("Trap") or obj:FindFirstChild("Sprint") or obj:FindFirstChild("Ninja")
    return child and child:IsA("Folder")
end

local function isSheriffObject(obj)
    return obj.Name == "Gun" and obj:IsA("Tool")
end

local function isPlayerObject(obj)
    if obj:IsA("Model") and obj:FindFirstChild("Head") and obj.Name ~= lp.Name then
        if not isMurderObject(obj) and not isSheriffObject(obj) then return true end
    end
    return false
end

local function isGunObject(obj)
    return obj.Name == "GunDrop" and obj:IsA("BasePart")
end

local function passesFilter(obj)
    if not Config.MM2.ESPTypes or #Config.MM2.ESPTypes == 0 then return false end
    if contains(Config.MM2.ESPTypes, "Murderer") and isMurderObject(obj) then return true end
    if contains(Config.MM2.ESPTypes, "Sheriff") and isSheriffObject(obj) then return true end
    if contains(Config.MM2.ESPTypes, "Players") and isPlayerObject(obj) then return true end
    if contains(Config.MM2.ESPTypes, "Gun") and isGunObject(obj) then return true end
    return false
end

local function getObjColor(obj)
    if isPlayerObject(obj) then return Color3.fromRGB(0, 255, 0) end
    if isSheriffObject(obj) then return Color3.fromRGB(0, 0, 255) end
    if isMurderObject(obj) then return Color3.fromRGB(255, 0, 0) end
    if isGunObject(obj) then return Color3.fromRGB(0, 0, 255) end
    return Color3.fromRGB(0, 255, 0)
end

local function ensureHighlight(obj)
    if not Config.MM2.ESPHighlight then
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
        local dropgun = Workspace:FindFirstChild("GunDrop", true)
        if dropgun and passesFilter(dropgun) then ensureHighlight(dropgun) end
    end
end)

-- Glitch Proof Remover
task.spawn(function()
    while Config.IsRunning do
        task.wait(1)
        local target = Workspace:FindFirstChild("GlitchProof", true)
        if target then target:Destroy() end
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
        Author = "Murder Mystery 2",
        Folder = "MizukageMM2",
        Size = UDim2.fromOffset(700, 550),
        Theme = "Dark",
        Accent = Color3.fromRGB(255, 50, 50),
        SideBarWidth = 220,
        HasOutline = true,
    })

    local MainTab = Window:Tab({ Title = "Main", Icon = "rocket" })
    local EspTab = Window:Tab({ Title = "ESP", Icon = "eye" })
    local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
    local MiscTab = Window:Tab({ Title = "Misc", Icon = "more-horizontal" })

    -- Main Tab - Murderer
    MainTab:Section({ Title = "🔪 Murderer" })
    MainTab:Toggle({ Title = "Kill Aura", Default = Config.MM2.KillAura, Callback = function(s) Config.MM2.KillAura = s end })
    MainTab:Slider({ Title = "Kill Aura Radius", Min = 1, Max = 50, Step = 1, Default = Config.MM2.KillAuraRadius, Callback = function(v) Config.MM2.KillAuraRadius = v end })
    MainTab:Toggle({ Title = "Kill Everyone", Default = Config.MM2.AutoKill, Callback = function(s) Config.MM2.AutoKill = s end })

    -- Main Tab - Sheriff
    MainTab:Section({ Title = "🔫 Sheriff" })
    MainTab:Toggle({ Title = "Auto Shoot Murder", Default = Config.MM2.AutoShoot, Callback = function(s) Config.MM2.AutoShoot = s end })
    MainTab:Toggle({ Title = "Auto Shoot Prediction", Default = Config.MM2.Prediction, Callback = function(s) Config.MM2.Prediction = s end })

    -- Main Tab - Innocent
    MainTab:Section({ Title = "🛡️ Innocent" })
    MainTab:Toggle({ Title = "Auto Grab", Default = Config.MM2.AutoGrab, Callback = function(s) Config.MM2.AutoGrab = s end })

    -- Main Tab - Farming
    MainTab:Section({ Title = "💰 Farming" })
    MainTab:Toggle({ Title = "Auto Farm Coins", Default = Config.MM2.AutoFarm, Callback = function(s)
        Config.MM2.AutoFarm = s
        if s then
            Config.MM2.Noclip = true
            toggleNoclip(true)
        else
            Config.MM2.Noclip = false
            toggleNoclip(false)
        end
    end })
    MainTab:Toggle({ Title = "Avoid Murderer", Default = Config.MM2.AutoFarmAvoid, Callback = function(s) Config.MM2.AutoFarmAvoid = s end })
    MainTab:Dropdown({ Title = "Farm Method", Values = {"Closest", "Randomized"}, Value = Config.MM2.FarmMethod, Callback = function(v) Config.MM2.FarmMethod = v[1] end })

    -- ESP Tab
    EspTab:Section({ Title = "Visual" })
    EspTab:Button({ Title = "Full Bright", Variant = "Secondary", Callback = function()
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ShadowSoftness = 0
        Lighting.GlobalShadows = false
    end })
    EspTab:Dropdown({ Title = "ESP Types", Values = {"Murderer", "Sheriff", "Players", "Gun"}, Multi = true, Value = Config.MM2.ESPTypes, Callback = function(v) Config.MM2.ESPTypes = v end })
    EspTab:Toggle({ Title = "Highlight Objects", Default = Config.MM2.ESPHighlight, Callback = function(s) Config.MM2.ESPHighlight = s end })

    -- Player Tab
    PlayerTab:Section({ Title = "Player Mods" })
    PlayerTab:Toggle({ Title = "Noclip", Default = Config.MM2.Noclip, Callback = function(s) Config.MM2.Noclip = s; toggleNoclip(s) end })
    PlayerTab:Toggle({ Title = "WalkSpeed Changer", Default = Config.MM2.Walk, Callback = function(s) Config.MM2.Walk = s end })
    PlayerTab:Slider({ Title = "WalkSpeed", Min = 16, Max = 100, Step = 1, Default = Config.MM2.Speed, Callback = function(v) Config.MM2.Speed = v end })

    -- Misc Tab
    MiscTab:Section({ Title = "Misc" })
    MiscTab:Toggle({ Title = "Anti AFK", Default = Config.MM2.AntiAFK, Callback = function(s) Config.MM2.AntiAFK = s end })
    MiscTab:Toggle({ Title = "Anti Fling", Default = Config.MM2.AntiFling, Callback = function(s) Config.MM2.AntiFling = s end })
    MiscTab:Toggle({ Title = "Touch Fling", Default = Config.MM2.Fling, Callback = function(s) Config.MM2.Fling = s end })

    WindUI:Notify({ Title = "Mizukage System", Content = "Murder Mystery 2 loaded!", Duration = 3 })
end

task.spawn(InitUI)
