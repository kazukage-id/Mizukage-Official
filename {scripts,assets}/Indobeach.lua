-- MIZUKAGE OFFICIAL - Indo Beach
-- Fitur: Auto Fishing, Instant Ore, No Clip, WalkSpeed, Player Teleport, Avatar Copy, dll.

if getgenv().MizuIndoBeachLoaded then return end
getgenv().MizuIndoBeachLoaded = true

getgenv().MizuConfig = getgenv().MizuConfig or { IsRunning = true }
local Config = getgenv().MizuConfig
Config.IndoBeach = Config.IndoBeach or {
    AutoFishing = false,
    InstantOre = false,
    NoClip = false,
    WalkSpeed = 16,
    SelectedRod = "NormalRod",
    SelectedPlayer = nil,
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- Remotes
local RemoteThrow = ReplicatedStorage:WaitForChild("RemoteThrow")
local RemoteRetract = ReplicatedStorage:WaitForChild("RemoteRetract")
local GiveCrystal = ReplicatedStorage:WaitForChild("GiveCrystal")
local BloxbizRemotes = ReplicatedStorage:WaitForChild("BloxbizRemotes")
local CatalogApplyOutfit = BloxbizRemotes:WaitForChild("CatalogOnApplyOutfit")

-- State
local fishingState = "ready"
local isCasting = false
local isRetracting = false
local isWaitingForFish = falselocal currentFishingDelay = 1.2

-- Character
local character = nil
local hum = nil
local root = nil

local function updateChar(char)
    character = char
    root = char and char:FindFirstChild("HumanoidRootPart")
    hum = char and char:FindFirstChild("Humanoid")
end
updateChar(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
LocalPlayer.CharacterAdded:Connect(updateChar)

-- Helper Functions
local function getBackpack() return LocalPlayer:FindFirstChild("Backpack") end
local function getPlayerGui() return LocalPlayer:FindFirstChild("PlayerGui") end

local function getFishingRod()
    local rod = character and character:FindFirstChild(Config.IndoBeach.SelectedRod)
    if not rod then
        local backpack = getBackpack()
        if backpack then rod = backpack:FindFirstChild(Config.IndoBeach.SelectedRod) end
    end
    return rod
end

local function getFishingGui()
    local gui = getPlayerGui()
    return gui and gui:FindFirstChild("Fishing")
end

-- WalkSpeed
task.spawn(function()
    while Config.IsRunning do
        if hum then hum.WalkSpeed = Config.IndoBeach.WalkSpeed end
        task.wait(0.5)
    end
end)

-- No Clip
local noclipConn = nil
task.spawn(function()
    while Config.IsRunning do
        if Config.IndoBeach.NoClip then
            if not noclipConn then
                noclipConn = RunService.RenderStepped:Connect(function()
                    if character then
                        for _, part in pairs(character:GetDescendants()) do
                            if part:IsA("BasePart") then part.CanCollide = false end
                        end
                    end
                end)
            end
        else
            if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        end
        task.wait(0.5)
    end
end)

-- Instant Ore
task.spawn(function()
    while Config.IsRunning do
        if Config.IndoBeach.InstantOre then
            pcall(function() GiveCrystal:InvokeServer(5.3574877270148) end)
        end
        task.wait(0.2)
    end
end)

-- Sell Functions
local function sellAllFish()
    local gui = getPlayerGui()
    local sellButton = gui and gui:FindFirstChild("SellFishes")
    if sellButton then firesignal(sellButton.MouseButton1Click) end
end

local function sellAllOre()
    local gui = getPlayerGui()
    local sellButton = gui and gui:FindFirstChild("SellOres")
    if sellButton then firesignal(sellButton.MouseButton1Click) end
end

-- Fishing Core
local function castFishingRod()
    local rod = getFishingRod()
    if not rod or not root or not hum then return false end

    if rod.Parent == getBackpack() then
        hum:EquipTool(rod)
        task.wait(0.2)
    end

    local maxLength = rod:FindFirstChild("MaxLength") and rod.MaxLength.Value or 50
    local speed = rod:FindFirstChild("Speed") and rod.Speed.Value or 30

    RemoteThrow:FireServer(
        root.Position + root.CFrame.LookVector * maxLength,
        root.CFrame,
        maxLength,
        speed,
        LocalPlayer
    )

    root.Anchored = true
    isCasting = true
    isRetracting = true
    isWaitingForFish = false
    fishingState = "waiting"

    task.delay(2, function()
        if isRetracting and not isWaitingForFish then
            local fishingGui = getFishingGui()
            if fishingGui then
                local fishingButton = fishingGui:FindFirstChild("FishingButton")
                if fishingButton then
                    fishingButton.Position = UDim2.new(math.random() * 0.3 + 0.32, 0, math.random() * 0.17 + 0.4, 0)
                    fishingButton.Visible = true
                end
            end
            isWaitingForFish = true
        end
    end)
    return true
end

local function retractFishingRod()
    if root then
        RemoteRetract:FireServer(nil, root.CFrame, LocalPlayer)
        root.Anchored = false
    end
    isCasting = false
    isRetracting = false
    isWaitingForFish = false
    fishingState = "cooldown"
    task.delay(currentFishingDelay, function() fishingState = "ready" end)
end

local function handleAutoFishing()
    if not Config.IndoBeach.AutoFishing or not character or not hum or not root then return end

    if fishingState == "ready" then
        local rod = getFishingRod()
        if rod then castFishingRod() end
    elseif fishingState == "waiting" then
        local fishingGui = getFishingGui()
        if fishingGui then
            local fishingButton = fishingGui:FindFirstChild("FishingButton")
            if fishingButton and fishingButton.Visible then
                firesignal(fishingButton.MouseButton1Click)
                isWaitingForFish = false
                fishingState = "reeling"
            end
        end
    elseif fishingState == "reeling" then
        if isWaitingForFish then retractFishingRod() end
    end
end

task.spawn(function()
    while Config.IsRunning do
        handleAutoFishing()
        task.wait(0.1)
    end
end)

-- Player Functions
local function getPlayerList()
    local names = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then table.insert(names, player.Name) end
    end
    return names
end

local function teleportToPlayer(targetPlayer)
    local targetChar = targetPlayer and targetPlayer.Character
    if not targetChar or not root then return false end
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if targetRoot then
        root.CFrame = targetRoot.CFrame + Vector3.new(3, 0, 3)
        return true
    end
    return false
end

local function applyAvatarFromPlayer(targetPlayer)
    local targetChar = targetPlayer and targetPlayer.Character
    if not targetChar then return false end
    local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
    if not targetHumanoid then return false end
    local description = targetHumanoid:GetAppliedDescription()
    if not description then return false end

    local accessories = {}
    for _, child in pairs(description:GetChildren()) do
        if child:IsA("AccessoryDescription") then
            table.insert(accessories, {
                Rotation = Vector3.zero,
                Position = Vector3.zero,
                Scale = Vector3.one,
                AssetId = child.AssetId,
                IsLayered = false,
                AccessoryType = Enum.AccessoryType.Hat
            })
        end
    end
    if description.Shirt ~= "" then
        table.insert(accessories, { AssetId = tonumber(description.Shirt), AccessoryType = Enum.AccessoryType.Shirt })
    end
    if description.Pants ~= "" then
        table.insert(accessories, { AssetId = tonumber(description.Pants), AccessoryType = Enum.AccessoryType.Pants })
    end

    CatalogApplyOutfit:FireServer({
        Accessories = accessories,
        Head = tonumber(description.Head) or 0,
        LeftArm = tonumber(description.LeftArm) or 0,
        RightArm = tonumber(description.RightArm) or 0,
        LeftLeg = tonumber(description.LeftLeg) or 0,
        RightLeg = tonumber(description.RightLeg) or 0,
        Torso = tonumber(description.Torso) or 0,
        Shirt = tonumber(description.Shirt) or 0,
        Pants = tonumber(description.Pants) or 0,
        GraphicTShirt = tonumber(description.GraphicTShirt) or 0,
        Face = tonumber(description.Face) or 0,
        BodyTypeScale = description.BodyTypeScale,
        DepthScale = description.DepthScale,
        HeightScale = description.HeightScale,
        WidthScale = description.WidthScale,
        ProportionScale = description.ProportionScale,
        HeadScale = description.HeadScale,
        LeftArmColor = description.LeftArmColor,
        RightArmColor = description.RightArmColor,
        LeftLegColor = description.LeftLegColor,
        RightLegColor = description.RightLegColor,
        TorsoColor = description.TorsoColor,
        HeadColor = description.HeadColor,
        IdleAnimation = tonumber(description.IdleAnimation) or 0,
        RunAnimation = tonumber(description.RunAnimation) or 0,
        WalkAnimation = tonumber(description.WalkAnimation) or 0,
        JumpAnimation = tonumber(description.JumpAnimation) or 0,
        ClimbAnimation = tonumber(description.ClimbAnimation) or 0,
        FallAnimation = tonumber(description.FallAnimation) or 0,
        SwimAnimation = tonumber(description.SwimAnimation) or 0
    })
    return true
end

local function resetToDefaultAvatar()
    local defaultDescription = Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId)
    if not defaultDescription then return false end
    CatalogApplyOutfit:FireServer({
        Accessories = {},
        Head = tonumber(defaultDescription.Head) or 0,
        LeftArm = tonumber(defaultDescription.LeftArm) or 0,
        RightArm = tonumber(defaultDescription.RightArm) or 0,
        LeftLeg = tonumber(defaultDescription.LeftLeg) or 0,
        RightLeg = tonumber(defaultDescription.RightLeg) or 0,
        Torso = tonumber(defaultDescription.Torso) or 0,
        Shirt = tonumber(defaultDescription.Shirt) or 0,
        Pants = tonumber(defaultDescription.Pants) or 0,
        GraphicTShirt = tonumber(defaultDescription.GraphicTShirt) or 0,
        Face = tonumber(defaultDescription.Face) or 0,
        BodyTypeScale = defaultDescription.BodyTypeScale,
        DepthScale = defaultDescription.DepthScale,
        HeightScale = defaultDescription.HeightScale,
        WidthScale = defaultDescription.WidthScale,
        ProportionScale = defaultDescription.ProportionScale,
        HeadScale = defaultDescription.HeadScale,
        LeftArmColor = defaultDescription.LeftArmColor,
        RightArmColor = defaultDescription.RightArmColor,
        LeftLegColor = defaultDescription.LeftLegColor,
        RightLegColor = defaultDescription.RightLegColor,
        TorsoColor = defaultDescription.TorsoColor,
        HeadColor = defaultDescription.HeadColor,
        IdleAnimation = tonumber(defaultDescription.IdleAnimation) or 0,
        RunAnimation = tonumber(defaultDescription.RunAnimation) or 0,
        WalkAnimation = tonumber(defaultDescription.WalkAnimation) or 0,
        JumpAnimation = tonumber(defaultDescription.JumpAnimation) or 0,
        ClimbAnimation = tonumber(defaultDescription.ClimbAnimation) or 0,
        FallAnimation = tonumber(defaultDescription.FallAnimation) or 0,
        SwimAnimation = tonumber(defaultDescription.SwimAnimation) or 0
    })
    return true
end

local function loadFlyScript()
    pcall(function() loadstring(game:HttpGetAsync("https://pastefy.app/heWTDAEO/raw"))() end)
end

-- Anti AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new())
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new())
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
        Author = "Indo Beach",
        Folder = "MizukageIndoBeach",
        Size = UDim2.fromOffset(680, 540),
        Theme = "Dark",
        Accent = Color3.fromRGB(0, 150, 255),
        SideBarWidth = 210,
        HasOutline = true,
    })

    local MainTab = Window:Tab({ Title = "Main", Icon = "rocket" })
    local MiscTab = Window:Tab({ Title = "Misc", Icon = "settings" })
    local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })

    -- Main Tab
    MainTab:Section({ Title = "🎣 Fish Farm" })
    MainTab:Dropdown({ Title = "Pilih Pancingan", Values = {"NormalRod", "Goth Rod", "Nereus Rod", "Shark Rod", "Tech Rod", "Trident Rod"}, Value = Config.IndoBeach.SelectedRod, Callback = function(v) Config.IndoBeach.SelectedRod = v[1] end })
    MainTab:Toggle({ Title = "Auto Fishing", Default = Config.IndoBeach.AutoFishing, Callback = function(s) Config.IndoBeach.AutoFishing = s; if not s then retractFishingRod() end end })
    MainTab:Button({ Title = "Jual Semua Ikan", Variant = "Secondary", Callback = sellAllFish })

    MainTab:Section({ Title = "⛏️ Ore Farm" })
    MainTab:Toggle({ Title = "Instant Ore", Default = Config.IndoBeach.InstantOre, Callback = function(s) Config.IndoBeach.InstantOre = s end })
    MainTab:Button({ Title = "Jual Semua Ore", Variant = "Secondary", Callback = sellAllOre })

    -- Misc Tab
    MiscTab:Section({ Title = "⚙️ Pengaturan Karakter" })
    MiscTab:Slider({ Title = "WalkSpeed", Min = 16, Max = 100, Step = 1, Default = Config.IndoBeach.WalkSpeed, Callback = function(v) Config.IndoBeach.WalkSpeed = v end })
    MiscTab:Toggle({ Title = "NoClip", Default = Config.IndoBeach.NoClip, Callback = function(s) Config.IndoBeach.NoClip = s end })

    MiscTab:Section({ Title = "🛠️ Utilitas Lain" })
    MiscTab:Button({ Title = "Load Fly Script", Variant = "Secondary", Callback = loadFlyScript })

    -- Player Tab
    PlayerTab:Section({ Title = "👤 Pilih Player" })
    local playerDropdown = PlayerTab:Dropdown({ Title = "Pilih Player", Values = getPlayerList(), Value = {}, Callback = function(v) Config.IndoBeach.SelectedPlayer = v[1] end })
    PlayerTab:Button({ Title = "Refresh Daftar Player", Variant = "Secondary", Callback = function() playerDropdown:SetValues(getPlayerList()) end })

    PlayerTab:Section({ Title = "🎯 Aksi" })
    PlayerTab:Button({ Title = "Teleport ke Player", Variant = "Secondary", Callback = function()
        local target = Players:FindFirstChild(Config.IndoBeach.SelectedPlayer)
        if target then teleportToPlayer(target) end
    end })
    PlayerTab:Button({ Title = "Salin & Terapkan Avatar", Variant = "Secondary", Callback = function()
        local target = Players:FindFirstChild(Config.IndoBeach.SelectedPlayer)
        if target then applyAvatarFromPlayer(target) end
    end })
    PlayerTab:Button({ Title = "Reset ke Avatar Default", Variant = "Secondary", Callback = resetToDefaultAvatar })

    WindUI:Notify({ Title = "Mizukage System", Content = "Indo Beach loaded!", Duration = 3 })
end

task.spawn(InitUI)
