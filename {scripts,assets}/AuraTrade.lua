-- MIZUKAGE OFFICIAL - Aura Trade
-- Fitur: Equip Best Aura, Snipe Auras, Aura Rain, TP ke Rained Aura, dll.

if getgenv().MizuAuraTradeLoaded then return end
getgenv().MizuAuraTradeLoaded = true

getgenv().MizuConfig = getgenv().MizuConfig or { IsRunning = true }
local Config = getgenv().MizuConfig
Config.AuraTrade = Config.AuraTrade or {
    BestToggle = false,
    AntiAFK = false,
    Snipe = false,
    Noclip = false,
    Walk = false,
    Speed = 25,
    SnipeTypes = {},
    TPAuraExploit = false,
    AntiFling = false,
    Fling = false,
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local lp = Players.LocalPlayer
local username = lp.Name

local character = nil
local root = nil
local humanoid = nil

local function updateChar(char)
    character = char
    root = char and char:FindFirstChild("HumanoidRootPart")
    humanoid = char and char:FindFirstChild("Humanoid")
end
updateChar(lp.Character or lp.CharacterAdded:Wait())
lp.CharacterAdded:Connect(updateChar)

-- Anti Cheat Bypass
local anti = workspace:FindFirstChild(username):FindFirstChild("LocalScript")
if anti then
    anti:Destroy()
end

-- Rarity Priority
local RarityPriority = {
    ["Contrast"] = 1, ["Volcanic"] = 2, ["Tesla"] = 3, ["Heart"] = 4,
    ["Spirit"] = 5, ["Cursed"] = 6, ["Fairy"] = 7, ["Frost"] = 8,
    ["Galatic"] = 9, ["Shimmer"] = 10, ["Lightning"] = 11, ["Pyronova"] = 12,
    ["Inferno"] = 13, ["Divine"] = 14,
}

local sniped = {}
local selectedTypes = {}

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

-- Aura Rain UI
local function rainUI()
    local playerGui = lp:WaitForChild("PlayerGui")

    local events = {
        {Name = "Spawn_GALATIC", Interval = 0.01, Type = "RemoteEvent"},
        {Name = "Spawn_FROST", Interval = 0.01, Type = "RemoteEvent"},
        {Name = "Lightning_Strike", Interval = 0.01, Type = "RemoteEvent"},
    }

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MizuAuraRain"
    screenGui.Parent = playerGui
    screenGui.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 180, 0, 160)
    frame.Position = UDim2.new(0.5, -90, 0.5, -80)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    frame.Parent = frame
    frame.Active = true
    frame.Draggable = true

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 25)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Aura Rain UI"
    titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 20
    titleLabel.Parent = frame

    local toggles = {}

    for i, eventData in ipairs(events) do
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 160, 0, 25)
        toggleBtn.Position = UDim2.new(0, 10, 0, 25 + (i - 1) * 27)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        toggleBtn.TextColor3 = Color3.new(1, 1, 1)
        toggleBtn.Font = Enum.Font.SourceSansBold
        toggleBtn.TextSize = 18
        toggleBtn.Text = eventData.Name .. ": OFF"
        toggleBtn.Parent = frame
        toggles[eventData.Name] = {Button = toggleBtn, Toggled = false}
    end

    for _, eventData in ipairs(events) do
        local eventInstance = ReplicatedStorage:FindFirstChild(eventData.Name)
        if eventInstance then
            local toggleData = toggles[eventData.Name]
            toggleData.Button.MouseButton1Click:Connect(function()
                toggleData.Toggled = not toggleData.Toggled
                toggleData.Button.Text = eventData.Name .. (toggleData.Toggled and ": ON" or ": OFF")
                if toggleData.Toggled then
                    task.spawn(function()
                        while toggleData.Toggled do
                            if eventData.Type == "RemoteEvent" then
                                eventInstance:FireServer()
                            end
                            task.wait(eventData.Interval)
                        end
                    end)
                end
            end)
        end
    end
end

-- Get Aura Score
local function getAuraScore(toolName)
    for aura, score in pairs(RarityPriority) do
        if string.find(string.lower(toolName), string.lower(aura)) then
            return score
        end
    end
    return nil
end

local function findBestAuras()
    local found = {}

    for _, plrModel in ipairs(workspace:GetChildren()) do
        if plrModel.Name ~= lp.Name then
            local char = plrModel
            local backpack = plrModel:FindFirstChild("Backpack")

            local tool = char:FindFirstChildWhichIsA("Tool")
            if tool then
                local score = getAuraScore(tool.Name)
                if score then
                    table.insert(found, {player = plrModel.Name, tool = tool.Name, score = score})
                end
            end

            if backpack then
                for _, tool in ipairs(backpack:GetChildren()) do
                    if tool:IsA("Tool") then
                        local score = getAuraScore(tool.Name)
                        if score then
                            table.insert(found, {player = plrModel.Name, tool = tool.Name, score = score})
                        end
                    end
                end
            end
        end
    end

    table.sort(found, function(a, b) return a.score > b.score end)

    for i = 1, math.min(2, #found) do
        WindUI:Notify({Title = "Best Aura", Content = found[i].tool .. "\nOwner: " .. found[i].player, Duration = 4})
    end
end

-- Anti Fling
task.spawn(function()
    while Config.IsRunning do
        if Config.AuraTrade.AntiFling then
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

-- Anti AFK
task.spawn(function()
    while Config.IsRunning do
        if Config.AuraTrade.AntiAFK and root then
            root.CFrame = root.CFrame + Vector3.new(0, 3, 0)
        end
        task.wait(60)
    end
end)

-- WalkSpeed
task.spawn(function()
    while Config.IsRunning do
        if Config.AuraTrade.Walk and humanoid then
            humanoid.WalkSpeed = Config.AuraTrade.Speed
        end
        task.wait()
    end
end)

-- Fling
task.spawn(function()
    local movel = 0.1
    while Config.IsRunning do
        if Config.AuraTrade.Fling and root then
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

-- Snipe Aura
task.spawn(function()
    while Config.IsRunning do
        task.wait()
        if not Config.AuraTrade.Snipe or #selectedTypes == 0 then continue end

        local character = lp.Character
        if not character then continue end

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then continue end

        local found = false

        for _, v in pairs(Workspace:GetChildren()) do
            if v:IsA("Tool") and not sniped[v] then
                local toolName = v.Name
                local lowerName = v.Name:lower()
                for _, type in ipairs(selectedTypes) do
                    if type ~= "" and lowerName:find(type:lower(), 1, true) then
                        local handle = v:FindFirstChild("Handle") or v:FindFirstChildWhichIsA("BasePart")
                        if handle then
                            rootPart.CFrame = handle.CFrame + Vector3.new(0, 1, 0)
                            sniped[v] = true
                            found = true
                            WindUI:Notify({Title = "Sniped", Content = toolName, Duration = 2})
                            break
                        end
                    end
                end
                if found then break end
            end
        end
    end
end)

-- TP to Rained Aura
task.spawn(function()
    while Config.IsRunning do
        task.wait()
        if not Config.AuraTrade.TPAuraExploit or not root then continue end

        for _, tool in ipairs(workspace:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == "5" and not sniped[tool] then
                local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
                if handle then
                    root.CFrame = handle.CFrame + Vector3.new(0, 1, 0)
                    sniped[tool] = true
                    task.wait(0.1)
                end
            end
        end
    end
end)

-- Equip Best Aura
local function isBetter(rarity1, stage1, rarity2, stage2)
    local StageOverrides = {
        ["Shimmer"] = { [5] = "Lightning" },
        ["Lightning"] = { [5] = "Pyronova" },
        ["Pyronova"] = { [4] = "Inferno" },
        ["Frost"] = { [5] = "Galatic" },
        ["Fairy"] = { [5] = "Frost" },
        ["Galatic"] = { [5] = "Shimmer" }
    }
    
    local overrides = StageOverrides[rarity1]
    if overrides and overrides[stage1] and rarity2 == overrides[stage1] then
        return true
    end
    local rank1 = RarityPriority[rarity1] or 0
    local rank2 = RarityPriority[rarity2] or 0
    if rank1 ~= rank2 then return rank1 > rank2 end
    return stage1 > stage2
end

local function getToolInfo(tool)
    local name = tool.Name
    local rarity, stage = name:match("^(%w+)%s%[STAGE%s(%d+)%]")
    if not rarity or not stage then return nil, 0 end
    return rarity, tonumber(stage)
end

local function equipBestTool(player)
    local backpack = player:FindFirstChild("Backpack")
    local char = player.Character
    if not backpack or not char then return end

    local bestTool, bestRarity, bestStage

    for _, container in ipairs({ backpack, char }) do
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                local rarity, stage = getToolInfo(tool)
                if rarity and (not bestTool or isBetter(rarity, stage, bestRarity, bestStage)) then
                    bestTool = tool
                    bestRarity = rarity
                    bestStage = stage
                end
            end
        end
    end

    if bestTool then
        local equippedTool = char:FindFirstChildOfClass("Tool")
        if equippedTool and equippedTool.Name ~= bestTool.Name then
            equippedTool.Parent = backpack
        end
        if not equippedTool or equippedTool.Name ~= bestTool.Name then
            bestTool.Parent = char
        end
    end
end

task.spawn(function()
    while Config.IsRunning do
        task.wait(1)
        if Config.AuraTrade.BestToggle then
            for _, player in ipairs(Players:GetPlayers()) do
                pcall(function()
                    if player.Character then equipBestTool(player) end
                end)
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
        Author = "Aura Trade",
        Folder = "MizukageAuraTrade",
        Size = UDim2.fromOffset(680, 540),
        Theme = "Dark",
        Accent = Color3.fromRGB(255, 0, 200),
        SideBarWidth = 210,
        HasOutline = true,
    })

    local MainTab = Window:Tab({ Title = "Main", Icon = "rocket" })
    local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
    local ExploitTab = Window:Tab({ Title = "Exploits", Icon = "cpu" })
    local MiscTab = Window:Tab({ Title = "Misc", Icon = "more-horizontal" })

    -- Main Tab
    MainTab:Section({ Title = "✨ Aura Farm" })
    MainTab:Toggle({ Title = "Equip Best Aura", Default = Config.AuraTrade.BestToggle, Callback = function(s) Config.AuraTrade.BestToggle = s end })
    MainTab:Toggle({ Title = "Snipe Auras", Default = Config.AuraTrade.Snipe, Callback = function(s) Config.AuraTrade.Snipe = s end })

    local snipeTypeOptions = { "Contrast", "Volcanic", "Tesla", "Heart", "Spirit", "Cursed", "Fairy", "Frost", "Galatic", "Shimmer", "Lightning", "Pyronova", "Inferno", "Werewolf", "Bionic", "Divine" }
    MainTab:Dropdown({ Title = "Snipe Type", Values = snipeTypeOptions, Multi = true, Value = Config.AuraTrade.SnipeTypes, Callback = function(v) Config.AuraTrade.SnipeTypes = v; selectedTypes = v end })

    MainTab:Button({ Title = "Find Best Aura", Variant = "Secondary", Callback = findBestAuras })

    -- Player Tab
    PlayerTab:Section({ Title = "Player Mods" })
    PlayerTab:Toggle({ Title = "Noclip", Default = Config.AuraTrade.Noclip, Callback = function(s) Config.AuraTrade.Noclip = s; toggleNoclip(s) end })
    PlayerTab:Toggle({ Title = "WalkSpeed Changer", Default = Config.AuraTrade.Walk, Callback = function(s) Config.AuraTrade.Walk = s end })
    PlayerTab:Slider({ Title = "WalkSpeed", Min = 16, Max = 100, Step = 1, Default = Config.AuraTrade.Speed, Callback = function(v) Config.AuraTrade.Speed = v end })

    -- Exploit Tab
    ExploitTab:Section({ Title = "⚡ Exploits" })
    ExploitTab:Button({ Title = "Aura Rain (EXPLOIT)", Variant = "Secondary", Callback = rainUI })
    ExploitTab:Toggle({ Title = "Teleport To Rained Aura", Default = Config.AuraTrade.TPAuraExploit, Callback = function(s) Config.AuraTrade.TPAuraExploit = s end })

    -- Misc Tab
    MiscTab:Section({ Title = "Misc" })
    MiscTab:Toggle({ Title = "Anti AFK", Default = Config.AuraTrade.AntiAFK, Callback = function(s) Config.AuraTrade.AntiAFK = s end })
    MiscTab:Toggle({ Title = "Anti Fling", Default = Config.AuraTrade.AntiFling, Callback = function(s) Config.AuraTrade.AntiFling = s end })
    MiscTab:Toggle({ Title = "Touch Fling", Default = Config.AuraTrade.Fling, Callback = function(s) Config.AuraTrade.Fling = s end })

    WindUI:Notify({ Title = "Mizukage System", Content = "Aura Trade loaded!", Duration = 3 })
end

task.spawn(InitUI)
