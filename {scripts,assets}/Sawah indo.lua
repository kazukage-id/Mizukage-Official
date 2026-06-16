-- MIZUKAGE OFFICIAL - Sawah Indo
-- Fitur: All Farm (Padi, Sawit, Coop, Barn), Auto Plant, Auto Harvest, Auto Sell, dll.

if getgenv().MizuSawahIndoLoaded then return end
getgenv().MizuSawahIndoLoaded = true

getgenv().MizuConfig = getgenv().MizuConfig or { IsRunning = true }
local Config = getgenv().MizuConfig
Config.SawahIndo = Config.SawahIndo or {
    Farm = false,
    Egg = false,
    Milk = false,
    AllFarm = false,
    AllFarmPhase = "IDLE",
    Selling = false,
    SellEgg = false,
    SellMilk = false,
    SellFruit = false,
    NoDelay = false,
    AutoBuy = false,
    PlantAmount = 15,
    BurstAmount = 5,
    SellDelay = 60,
    MaxCrop = 15,
    SelectedCrop = "Padi",
    ActivePlot = nil,
    MemoryPos = nil,
    TPMode = "Memory",
    MyPlots = {},
    PadiPos = nil,
    SawitPos = nil,
    CoopPos = nil,
    BarnPos = nil,
    AntiAFK = false,
    PlantPause = 0,
    LastAutoTp = 0,
}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- Remotes
local GameRemotes = ReplicatedStorage:WaitForChild("Remotes")
local TutorialRemotes = GameRemotes:WaitForChild("TutorialRemotes")

-- Config Modules
local CropConfig = require(ReplicatedStorage.Modules:WaitForChild("CropConfig"))
local EggConfig = require(ReplicatedStorage.Modules:WaitForChild("EggConfig"))

-- Character
local character = nil
local hum = nil
local root = nil

local function UpdateCharacter(char)
    character = char
    root = char and char:FindFirstChild("HumanoidRootPart")
    hum = char and char:FindFirstChildOfClass("Humanoid")
end
UpdateCharacter(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
LocalPlayer.CharacterAdded:Connect(UpdateCharacter)

-- Helper Functions
local function FormatNumber(num)
    local str = tostring(math.floor(tonumber(num) or 0))
    local k
    while true do
        str, k = str:gsub("^(-?%d+)(%d%d%d)", "%1.%2")
        if k == 0 then break end
    end
    return str
end

local function TeleportTo(position)
    if root then
        root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
        task.wait(0.4)
    end
end

local function SaveMemoryPosition()
    if root then
        Config.SawahIndo.MemoryPos = { pos = root.Position, savedAt = os.clock() }
        return true
    end
    return false
end

local function GetTeleportPosition()
    if Config.SawahIndo.TPMode == "Plot" and Config.SawahIndo.ActivePlot then
        return Config.SawahIndo.ActivePlot.pos
    end
    if Config.SawahIndo.TPMode == "Memory" and Config.SawahIndo.MemoryPos then
        return Config.SawahIndo.MemoryPos.pos
    end
    return nil
end

-- Crop Database
local CropList = {}
local CropDropdownList = {}
local CropKeyMap = {}

for seedName, data in pairs(CropConfig.Seeds) do
    local cropName = seedName
    if seedName == "Bibit Padi" then cropName = "Padi"
    elseif seedName == "Bibit Jagung" then cropName = "Jagung"
    elseif seedName == "Bibit Tomat" then cropName = "Tomat"
    elseif seedName == "Bibit Terong" then cropName = "Terong"
    elseif seedName == "Bibit Strawberry" then cropName = "Strawberry"
    elseif seedName == "Bibit Sawit" then cropName = "Sawit"
    elseif seedName == "Bibit Durian" then cropName = "Durian"
    end

    if data.HarvestItem then
        CropList[cropName] = {
            SeedName = seedName,
            HarvestItem = data.HarvestItem,
            Price = CropConfig.SellableItems and CropConfig.SellableItems[data.HarvestItem] and 
                    CropConfig.SellableItems[data.HarvestItem].SellPrice or 10,
            MinLevel = data.MinLevel or 1,
            Icon = data.Icon or "🌾"
        }
    end
end

local sortedCrops = {}
for key, data in pairs(CropList) do
    table.insert(sortedCrops, { key = key, level = data.MinLevel })
end
table.sort(sortedCrops, function(a, b) return a.level < b.level end)

for _, v in ipairs(sortedCrops) do
    local display = string.format("%s [lv.%d] %s", v.key, CropList[v.key].MinLevel, CropList[v.key].Icon)
    table.insert(CropDropdownList, display)
    CropKeyMap[display] = v.key
end

-- Scan Coop & Barn
local function ScanCoopBarn()
    local coop, barn = nil, nil
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local owner = obj:GetAttribute("OwnerId") or obj:GetAttribute("Owner") or obj:GetAttribute("OwnerUserId")
        if owner and tostring(owner) == tostring(LocalPlayer.UserId) then
            local nameLower = string.lower(obj.Name or "")
            
            if string.find(nameLower, "coop") then
                if obj:IsA("Model") then
                    local primaryPart = obj.PrimaryPart
                    coop = primaryPart and primaryPart.Position or obj:GetBoundingBox().Position
                else
                    coop = obj.Position
                end
            elseif string.find(nameLower, "barn") then
                if obj:IsA("Model") then
                    local primaryPart = obj.PrimaryPart
                    barn = primaryPart and primaryPart.Position or obj:GetBoundingBox().Position
                else
                    barn = obj.Position
                end
            end
        end
    end
    
    return coop, barn
end

-- Crop Counting
local function CountActiveCrops()
    local active = Workspace:FindFirstChild("ActiveCrops")
    if not active then return 0 end
    
    local count = 0
    local userId = tostring(LocalPlayer.UserId)
    
    for _, crop in ipairs(active:GetChildren()) do
        if string.match(crop.Name, "Crop_(%d+)_") == userId then
            count = count + 1
        end
    end
    return count
end

-- Seed Management
local function CountSeeds(cropData)
    if not cropData then return 0 end
    
    local count = 0
    
    local function checkContainer(container)
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") and string.find(item.Name, cropData.SeedName) then
                local qty = string.match(item.Name, "(%d+)$")
                count = count + (tonumber(qty) or 1)
            end
        end
    end
    
    if character then checkContainer(character) end
    checkContainer(LocalPlayer.Backpack)
    
    return count
end

local function BuySeeds(cropData, amount)
    if amount <= 0 or not cropData then return end
    
    pcall(function()
        TutorialRemotes.RequestShop:InvokeServer("BUY", cropData.SeedName, amount)
    end)
    task.wait(0.5)
end

local function EquipSeed(cropData)
    if not cropData or not hum then return false end
    
    if character then
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") and string.find(tool.Name, cropData.SeedName) then
                return true
            end
        end
    end
    
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and string.find(tool.Name, cropData.SeedName) then
            hum:EquipTool(tool)
            task.wait(0.2)
            return true
        end
    end
    
    return false
end

-- Plant Functions
local function RandomOffset(center, radius)
    local angle = math.rad(math.random(0, 360))
    local dist = math.random() * (radius or 18) + 2
    return center + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
end

local function PlantCrop(cropName, centerPos)
    local cropData = CropList[cropName]
    if not cropData then return end
    
    if os.clock() < Config.SawahIndo.PlantPause then return end
    
    if CountActiveCrops() >= Config.SawahIndo.MaxCrop then return end
    
    if not centerPos then
        if not SaveMemoryPosition() then return end
        centerPos = GetTeleportPosition()
        if not centerPos then return end
    end
    
    local seedCount = CountSeeds(cropData)
    if seedCount < Config.SawahIndo.BurstAmount then
        if Config.SawahIndo.AutoBuy then
            BuySeeds(cropData, Config.SawahIndo.PlantAmount - seedCount)
        end
        if CountSeeds(cropData) == 0 then return end
    end
    
    if not EquipSeed(cropData) then return end
    
    local toPlant = math.min(Config.SawahIndo.BurstAmount, math.max(Config.SawahIndo.MaxCrop - CountActiveCrops(), 0))
    if toPlant == 0 then return end
    
    for i = 1, toPlant do
        if CountSeeds(cropData) == 0 then
            if Config.SawahIndo.AutoBuy then
                BuySeeds(cropData, Config.SawahIndo.PlantAmount)
                if not EquipSeed(cropData) then break end
            else
                break
            end
        end
        
        pcall(function()
            TutorialRemotes.PlantCrop:FireServer(RandomOffset(centerPos))
        end)
        task.wait(Config.SawahIndo.NoDelay and 0.1 or 0.3)
    end
end

-- Harvest Functions
local function HarvestInRadius(center, radius)
    if not root then return end
    
    local active = Workspace:FindFirstChild("ActiveCrops")
    if not active then return end
    
    local userId = tostring(LocalPlayer.UserId)
    
    for _, crop in ipairs(active:GetChildren()) do
        if string.match(crop.Name, "Crop_(%d+)_") == userId then
            for _, prompt in ipairs(crop:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                    local promptParent = prompt.Parent
                    if promptParent and promptParent:IsA("BasePart") then
                        local distance = (promptParent.Position - center).Magnitude
                        if distance < radius then
                            fireproximityprompt(prompt)
                            task.wait(0.15)
                        end
                    end
                end
            end
        end
    end
end

-- Selling Functions
local function SellCrop(cropName)
    if not CropList[cropName] then return 0 end
    
    local success, result = pcall(function()
        return TutorialRemotes.RequestSell:InvokeServer("GET_LIST")
    end)
    
    if not success or type(result) ~= "table" or type(result.Items) ~= "table" then
        return 0
    end
    
    for _, item in pairs(result.Items) do
        if type(item) == "table" and tonumber(item.Owned) then
            local name = item.Name or item.DisplayName or ""
            if string.find(name, CropList[cropName].HarvestItem) then
                local qty = tonumber(item.Owned)
                local price = tonumber(item.SellPrice) or CropList[cropName].Price or 0
                
                if qty and qty > 0 then
                    pcall(function()
                        TutorialRemotes.RequestSell:InvokeServer("SELL", name, qty)
                    end)
                    task.wait(0.2)
                end
                return qty or 0
            end
        end
    end
    
    return 0
end

local function SellAll()
    for cropName in pairs(CropList) do
        pcall(SellCrop, cropName)
    end
    
    if Config.SawahIndo.SellEgg then 
        pcall(function() 
            TutorialRemotes.RequestSell:InvokeServer("GET_EGG_LIST") 
        end) 
    end
    
    if Config.SawahIndo.SellMilk then 
        pcall(function() 
            TutorialRemotes.RequestSell:InvokeServer("GET_MILK_LIST") 
        end) 
    end
    
    if Config.SawahIndo.SellFruit then 
        pcall(function() 
            TutorialRemotes.RequestSell:InvokeServer("GET_FRUIT_LIST") 
        end) 
    end
end

-- Animal Functions
local FastInteractCache = {}
local EggVisualCache = {}
local MilkVisualCache = {}

local function FeedAnimals(center, radius)
    if not root then return end
    
    for prompt in pairs(FastInteractCache) do
        if prompt and prompt.Parent and prompt.Enabled then
            local action = string.lower(prompt.ActionText or "")
            if string.find(action, "feed") then
                local parent = prompt.Parent
                if parent and parent:IsA("BasePart") then
                    local distance = (parent.Position - center).Magnitude
                    if distance < radius then
                        TeleportTo(parent.Position)
                        task.wait(0.1)
                        fireproximityprompt(prompt)
                        task.wait(0.5)
                    end
                end
            end
        end
    end
    TeleportTo(center)
end

local function CollectAnimals(center, radius)
    if not root then return end
    
    for prompt in pairs(FastInteractCache) do
        if prompt and prompt.Parent and prompt.Enabled then
            local action = string.lower(prompt.ActionText or "")
            if string.find(action, "collect") then
                local parent = prompt.Parent
                if parent and parent:IsA("BasePart") then
                    local distance = (parent.Position - center).Magnitude
                    if distance < radius then
                        TeleportTo(parent.Position)
                        task.wait(0.1)
                        fireproximityprompt(prompt)
                        task.wait(0.5)
                    end
                end
            end
        end
    end
    TeleportTo(center)
end

-- Auto Collect Loops
local function AutoEggLoop()
    if not root then return end
    
    for egg in pairs(EggVisualCache) do
        if egg and egg.Parent then
            local prompt = egg:FindFirstChildOfClass("ProximityPrompt")
            if prompt and prompt.Enabled then
                if root and (root.Position - egg.Position).Magnitude < 35 then
                    fireproximityprompt(prompt)
                    task.wait(0.15)
                end
            end
        else
            EggVisualCache[egg] = nil
        end
    end
end

local function AutoMilkLoop()
    if not root then return end
    
    for milk in pairs(MilkVisualCache) do
        if milk and milk.Parent then
            local prompt = milk:FindFirstChildOfClass("ProximityPrompt")
            if prompt and prompt.Enabled then
                if root and (root.Position - milk.Position).Magnitude < 35 then
                    fireproximityprompt(prompt)
                    task.wait(0.15)
                end
            end
        else
            MilkVisualCache[milk] = nil
        end
    end
end

-- Main Loops
local function StartPlantLoop(flagName, cropName, centerPos)
    task.spawn(function()
        while Config.SawahIndo[flagName] do
            PlantCrop(cropName, centerPos)
            task.wait(0.3)
        end
    end)
end

local function StartHarvestLoop(flagName)
    task.spawn(function()
        while Config.SawahIndo[flagName] do
            pcall(function()
                local pos = GetTeleportPosition()
                if pos then HarvestInRadius(pos, 80) end
            end)
            task.wait(0.4)
        end
    end)
end

local function StartSellLoop(flagName)
    task.spawn(function()
        while Config.SawahIndo[flagName] do
            if Config.SawahIndo.Selling then
                SellCrop(Config.SawahIndo.SelectedCrop)
            end
            
            if Config.SawahIndo.SellEgg then 
                pcall(function() TutorialRemotes.RequestSell:InvokeServer("GET_EGG_LIST") end) 
            end
            
            if Config.SawahIndo.SellMilk then 
                pcall(function() TutorialRemotes.RequestSell:InvokeServer("GET_MILK_LIST") end) 
            end
            
            if Config.SawahIndo.SellFruit then 
                pcall(function() TutorialRemotes.RequestSell:InvokeServer("GET_FRUIT_LIST") end) 
            end
            
            for i = 1, Config.SawahIndo.SellDelay or 60 do
                if not Config.SawahIndo[flagName] then return end
                task.wait(1)
            end
        end
    end)
end

local function StartEggLoop(flagName)
    task.spawn(function()
        while Config.SawahIndo[flagName] do
            pcall(AutoEggLoop)
            task.wait(0.8)
        end
    end)
end

local function StartMilkLoop(flagName)
    task.spawn(function()
        while Config.SawahIndo[flagName] do
            pcall(AutoMilkLoop)
            task.wait(0.8)
        end
    end)
end

local function StartAutoTP(flagName)
    task.spawn(function()
        while Config.SawahIndo[flagName] do
            if not Config.SawahIndo.AllFarm then
                local pos = GetTeleportPosition()
                if pos and os.clock() - Config.SawahIndo.LastAutoTp > 60 then
                    TeleportTo(pos)
                    Config.SawahIndo.LastAutoTp = os.clock()
                end
            end
            task.wait(5)
        end
    end)
end

-- All Farm Loop
local function AllFarmLoop()
    task.spawn(function()
        while Config.SawahIndo.AllFarm do
            pcall(SellAll)
            for i = 1, 60 do
                if not Config.SawahIndo.AllFarm then return end
                task.wait(1)
            end
        end
    end)
    
    while Config.SawahIndo.AllFarm do
        -- Phase 1: Padi
        local padiPos = Config.SawahIndo.PadiPos
        if padiPos then
            Config.SawahIndo.AllFarmPhase = "PADI"
            TeleportTo(padiPos)
            
            local start = os.clock()
            while os.clock() - start < 2 and Config.SawahIndo.AllFarm do
                pcall(PlantCrop, Config.SawahIndo.SelectedCrop, padiPos)
                pcall(HarvestInRadius, padiPos, 80)
                task.wait(0.15)
            end
        else
            task.wait(2)
        end
        
        if not Config.SawahIndo.AllFarm then break end
        
        -- Phase 2: Sawit + Durian
        local sawitPos = Config.SawahIndo.SawitPos
        if sawitPos then
            Config.SawahIndo.AllFarmPhase = "SAWIT"
            TeleportTo(sawitPos)
            task.wait(0.3)
            
            pcall(function()
                local cropData = CropList["Sawit"]
                if cropData and CountSeeds(cropData) > 0 and EquipSeed(cropData) then
                    TutorialRemotes.PlantCrop:FireServer(root.Position)
                end
            end)
            task.wait(0.3)
            
            if root then
                root.CFrame = root.CFrame + Vector3.new(4, 0, 0)
                task.wait(0.2)
                
                pcall(function()
                    local cropData = CropList["Durian"]
                    if cropData and CountSeeds(cropData) > 0 and EquipSeed(cropData) then
                        TutorialRemotes.PlantCrop:FireServer(root.Position)
                    end
                end)
                task.wait(0.3)
            end
            
            pcall(HarvestInRadius, sawitPos, 80)
            task.wait(0.3)
            TeleportTo(sawitPos)
        end
        
        if not Config.SawahIndo.AllFarm then break end
        
        -- Phase 3: Coop
        local coopPos = Config.SawahIndo.CoopPos
        if coopPos then
            Config.SawahIndo.AllFarmPhase = "COOP"
            TeleportTo(coopPos)
            task.wait(0.3)
            pcall(FeedAnimals, coopPos, 70)
            task.wait(0.3)
            pcall(CollectAnimals, coopPos, 70)
        end
        
        if not Config.SawahIndo.AllFarm then break end
        
        -- Phase 4: Barn
        local barnPos = Config.SawahIndo.BarnPos
        if barnPos then
            Config.SawahIndo.AllFarmPhase = "BARN"
            TeleportTo(barnPos)
            task.wait(0.3)
            pcall(FeedAnimals, barnPos, 70)
            task.wait(0.3)
            pcall(CollectAnimals, barnPos, 70)
        end
    end
    
    Config.SawahIndo.AllFarmPhase = "IDLE"
end

-- Prompt Cache Setup
local function SetupPromptCache()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            FastInteractCache[obj] = true
            if Config.SawahIndo.NoDelay and obj.HoldDuration > 0 then
                obj.HoldDuration = 0
            end
        elseif obj:IsA("BasePart") then
            local name = obj.Name or ""
            if string.find(name, "EggVisual") then
                EggVisualCache[obj] = true
            elseif string.find(name, "MilkVisual") then
                MilkVisualCache[obj] = true
            end
        end
    end
end

-- Event Connections
local function SetupEventConnections()
    TutorialRemotes.Notification.OnClientEvent:Connect(function(msg)
        if type(msg) ~= "string" then return end
        
        if string.find(msg, "Maximum 15 crops") then
            Config.SawahIndo.PlantPause = os.clock() + 30
        end
    end)
    
    Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("ProximityPrompt") then
            FastInteractCache[obj] = true
            if Config.SawahIndo.NoDelay and obj.HoldDuration > 0 then
                obj.HoldDuration = 0
            end
        elseif obj:IsA("BasePart") then
            local name = obj.Name or ""
            if string.find(name, "EggVisual") then
                EggVisualCache[obj] = true
            elseif string.find(name, "MilkVisual") then
                MilkVisualCache[obj] = true
            end
        end
    end)
    
    Workspace.DescendantRemoving:Connect(function(obj)
        FastInteractCache[obj] = nil
        EggVisualCache[obj] = nil
        MilkVisualCache[obj] = nil
    end)
    
    task.spawn(function()
        while Config.IsRunning do
            task.wait(10)
            if Config.SawahIndo.NoDelay then
                for prompt in pairs(FastInteractCache) do
                    if prompt and prompt.HoldDuration > 0 then
                        prompt.HoldDuration = 0
                    end
                end
            end
        end
    end)
end

-- Auto Click Confirm
local ConfirmTouchOffset = Vector2.new(0, 36)

local function SendTouch(pos)
    pcall(function()
        VirtualUser:CaptureController()
        if VirtualUser.TouchTap then
            VirtualUser:TouchTap(pos, Enum.UserInputType.Touch)
        end
        VirtualUser:ClickButton1(pos)
    end)
end

local function SetupConfirmClicker()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    local function WatchConfirm(gui)
        task.spawn(function()
            task.wait(0.05)
            pcall(function()
                local overlay = gui:FindFirstChild("ConfirmOverlay")
                if not overlay or not overlay.Visible then return end
                
                local card = overlay:FindFirstChild("ConfirmCard")
                if not card or not card.Visible then return end
                
                local yesBtn = card:FindFirstChild("YesButton")
                if not yesBtn or not yesBtn.Visible then return end
                
                local pos = yesBtn.AbsolutePosition + yesBtn.AbsoluteSize / 2
                
                pcall(function() yesBtn.MouseButton1Click:Fire() end)
                pcall(function() yesBtn.Activated:Fire() end)
                
                SendTouch(pos + ConfirmTouchOffset)
                SendTouch(pos)
            end)
        end)
    end
    
    local confirmGui = playerGui:FindFirstChild("ConfirmGui")
    if confirmGui then WatchConfirm(confirmGui) end
    
    playerGui.ChildAdded:Connect(function(child)
        if child.Name == "ConfirmGui" then WatchConfirm(child) end
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
        Author = "Sawah Indo",
        Folder = "MizukageSawahIndo",
        Size = UDim2.fromOffset(750, 580),
        Theme = "Dark",
        Accent = Color3.fromRGB(0, 200, 100),
        SideBarWidth = 230,
        HasOutline = true,
    })

    local AllFarmTab = Window:Tab({ Title = "All Farm", Icon = "rocket" })
    local PlantTab = Window:Tab({ Title = "Tanaman", Icon = "grass" })
    local FarmTab = Window:Tab({ Title = "Ternak", Icon = "pets" })
    local TPManagerTab = Window:Tab({ Title = "TP Manager", Icon = "map" })
    local PlotManagerTab = Window:Tab({ Title = "Plot Manager", Icon = "list" })
    local UtilTab = Window:Tab({ Title = "Utilities", Icon = "settings" })

    -- All Farm Tab
    AllFarmTab:Section({ Title = "📍 Setup Koordinat" })
    AllFarmTab:Paragraph({ Title = "Pergi ke setiap lokasi lalu klik tombol Simpan", Desc = "" })

    AllFarmTab:Dropdown({ Title = "Pilih Tanaman (Phase 1)", Values = CropDropdownList, Value = {CropDropdownList[1] or "Padi [lv.1] 🌾"}, Callback = function(v) Config.SawahIndo.SelectedCrop = CropKeyMap[v[1]] or "Padi" end })

    AllFarmTab:Button({ Title = "Simpan Koordinat Tanam", Variant = "Secondary", Callback = function()
        if not root then return end
        Config.SawahIndo.PadiPos = root.Position
    end })

    AllFarmTab:Button({ Title = "Simpan Koordinat Sawit", Variant = "Secondary", Callback = function()
        if not root then return end
        Config.SawahIndo.SawitPos = root.Position
    end })

    AllFarmTab:Section({ Title = "🏚️ Kandang" })
    local CoopLabel = AllFarmTab:Paragraph({ Title = "Coop", Desc = "Coop: Belum di-scan" })
    local BarnLabel = AllFarmTab:Paragraph({ Title = "Barn", Desc = "Barn: Tidak ditemukan" })

    AllFarmTab:Button({ Title = "Refresh Kandang", Variant = "Secondary", Callback = function()
        task.spawn(function()
            local coop, barn = ScanCoopBarn()
            if coop then
                Config.SawahIndo.CoopPos = coop
                CoopLabel:Set(string.format("Coop: %.0f, %.0f, %.0f ✅", coop.X, coop.Y, coop.Z))
            else
                CoopLabel:Set("Coop: Tidak ditemukan ❌")
            end
            if barn then
                Config.SawahIndo.BarnPos = barn
                BarnLabel:Set(string.format("Barn: %.0f, %.0f, %.0f ✅", barn.X, barn.Y, barn.Z))
            else
                BarnLabel:Set("Barn: Tidak ditemukan ❌")
            end
        end)
    end })

    AllFarmTab:Section({ Title = "🚜 Kontrol All Farm" })
    local PhaseLabel = AllFarmTab:Paragraph({ Title = "Phase", Desc = "Phase: IDLE" })

    AllFarmTab:Toggle({ Title = "AUTO FARM ALL", Default = Config.SawahIndo.AllFarm, Callback = function(s)
        Config.SawahIndo.AllFarm = s
        Config.SawahIndo.Farm = false
        Config.SawahIndo.Egg = false
        Config.SawahIndo.Milk = false
        
        if s then
            if not Config.SawahIndo.PadiPos then
                Config.SawahIndo.AllFarm = false
                return
            end
            task.spawn(AllFarmLoop)
        else
            Config.SawahIndo.AllFarmPhase = "IDLE"
        end
    end })

    task.spawn(function()
        local phaseMap = { IDLE = "IDLE", PADI = "Tanam Padi", SAWIT = "Sawit", COOP = "Kandang Ayam", BARN = "Kandang Sapi" }
        while Config.IsRunning do
            task.wait(1)
            local phase = Config.SawahIndo.AllFarmPhase or "IDLE"
            pcall(function() PhaseLabel:Set("Phase: " .. (phaseMap[phase] or phase)) end)
        end
    end)

    AllFarmTab:Button({ Title = "Jual Semua Sekarang", Variant = "Secondary", Callback = function()
        task.spawn(function()
            for cropName in pairs(CropList) do
                pcall(SellCrop, cropName)
            end
        end)
    end })

    -- Plant Tab
    PlantTab:Section({ Title = "🌱 Konfigurasi" })
    PlantTab:Dropdown({ Title = "Target Tanaman", Values = CropDropdownList, Value = {CropDropdownList[1] or "Padi [lv.1] 🌾"}, Callback = function(v) Config.SawahIndo.SelectedCrop = CropKeyMap[v[1]] or "Padi" end })
    PlantTab:Slider({ Title = "Maks Bibit di Tas", Min = 1, Max = 99, Step = 1, Default = Config.SawahIndo.PlantAmount, Callback = function(v) Config.SawahIndo.PlantAmount = v end })
    PlantTab:Slider({ Title = "Max Crop Aktif", Min = 1, Max = 50, Step = 1, Default = Config.SawahIndo.MaxCrop, Callback = function(v) Config.SawahIndo.MaxCrop = v end })
    PlantTab:Slider({ Title = "Seed per Burst", Min = 1, Max = 30, Step = 1, Default = Config.SawahIndo.BurstAmount, Callback = function(v) Config.SawahIndo.BurstAmount = v end })

    PlantTab:Section({ Title = "🎮 Control" })
    PlantTab:Toggle({ Title = "Auto Farm Tanaman", Default = Config.SawahIndo.Farm, Callback = function(s)
        Config.SawahIndo.Farm = s
        if s then
            if Config.SawahIndo.AllFarm then
                Config.SawahIndo.Farm = false
                return
            end
            if SaveMemoryPosition() then end
            StartPlantLoop("Farm", Config.SawahIndo.SelectedCrop, GetTeleportPosition())
            StartHarvestLoop("Farm")
            StartSellLoop("Farm")
            StartAutoTP("Farm")
        end
    end })

    PlantTab:Toggle({ Title = "Auto Beli Bibit", Default = Config.SawahIndo.AutoBuy, Callback = function(s) Config.SawahIndo.AutoBuy = s end })
    PlantTab:Toggle({ Title = "Auto Jual Tanaman", Default = Config.SawahIndo.Selling, Callback = function(s) Config.SawahIndo.Selling = s end })

    PlantTab:Section({ Title = "🛠️ Manual" })
    PlantTab:Button({ Title = "Jual Tanaman Sekarang", Variant = "Secondary", Callback = function()
        task.spawn(function() SellCrop(Config.SawahIndo.SelectedCrop) end)
    end })

    -- Farm Tab (Ternak)
    FarmTab:Section({ Title = "🥚 Auto Egg" })
    FarmTab:Toggle({ Title = "Auto Collect Telur", Default = Config.SawahIndo.Egg, Callback = function(s)
        Config.SawahIndo.Egg = s
        if s then
            if Config.SawahIndo.AllFarm then
                Config.SawahIndo.Egg = false
                return
            end
            StartEggLoop("Egg")
        end
    end })
    FarmTab:Toggle({ Title = "Auto Jual Telur", Default = Config.SawahIndo.SellEgg, Callback = function(s) Config.SawahIndo.SellEgg = s end })
    FarmTab:Button({ Title = "Jual Telur Sekarang", Variant = "Secondary", Callback = function() pcall(function() TutorialRemotes.RequestSell:InvokeServer("GET_EGG_LIST") end) end })

    FarmTab:Section({ Title = "🥛 Auto Milk" })
    FarmTab:Toggle({ Title = "Auto Collect Susu", Default = Config.SawahIndo.Milk, Callback = function(s)
        Config.SawahIndo.Milk = s
        if s then
            if Config.SawahIndo.AllFarm then
                Config.SawahIndo.Milk = false
                return
            end
            StartMilkLoop("Milk")
        end
    end })
    FarmTab:Toggle({ Title = "Auto Jual Susu", Default = Config.SawahIndo.SellMilk, Callback = function(s) Config.SawahIndo.SellMilk = s end })
    FarmTab:Button({ Title = "Jual Susu Sekarang", Variant = "Secondary", Callback = function() pcall(function() TutorialRemotes.RequestSell:InvokeServer("GET_MILK_LIST") end) end })

    FarmTab:Section({ Title = "🍎 Auto Fruit" })
    FarmTab:Toggle({ Title = "Auto Jual Buah", Default = Config.SawahIndo.SellFruit, Callback = function(s) Config.SawahIndo.SellFruit = s end })

    -- TP Manager Tab
    TPManagerTab:Section({ Title = "📍 Mode Auto TP" })
    TPManagerTab:Toggle({ Title = "Smart Memory TP", Default = true, Callback = function(s)
        Config.SawahIndo.TPMode = s and "Memory" or "Plot"
        if s and not Config.SawahIndo.MemoryPos then SaveMemoryPosition() end
    end })

    TPManagerTab:Section({ Title = "💾 Memory Position" })
    TPManagerTab:Button({ Title = "Update Memory Position", Variant = "Secondary", Callback = function()
        if SaveMemoryPosition() then end
    end })
    TPManagerTab:Button({ Title = "TP ke Memory Position", Variant = "Secondary", Callback = function()
        if Config.SawahIndo.MemoryPos then
            TeleportTo(Config.SawahIndo.MemoryPos.pos)
        end
    end })

    -- Utilities Tab
    UtilTab:Section({ Title = "⚙️ Utilitas" })
    UtilTab:Toggle({ Title = "Fast Interact", Default = Config.SawahIndo.NoDelay, Callback = function(s) Config.SawahIndo.NoDelay = s end })
    UtilTab:Toggle({ Title = "Anti AFK", Default = Config.SawahIndo.AntiAFK, Callback = function(s) Config.SawahIndo.AntiAFK = s end })

    UtilTab:Section({ Title = "📊 Session Tracker" })
    local UptimeLabel = UtilTab:Paragraph({ Title = "Uptime", Desc = "Uptime: 00:00:00" })
    local StatusLabel = UtilTab:Paragraph({ Title = "Status", Desc = "Status: Idle" })
    local CropLabel = UtilTab:Paragraph({ Title = "Crop Aktif", Desc = "Crop Aktif: 0 / " .. Config.SawahIndo.MaxCrop })
    local TPModeLabel = UtilTab:Paragraph({ Title = "TP Mode", Desc = "TP Mode: Memory" })

    task.spawn(function()
        local startTime = os.clock()
        while Config.IsRunning do
            task.wait(1)
            local uptime = os.clock() - startTime
            local h = math.floor(uptime / 3600)
            local m = math.floor(uptime % 3600 / 60)
            local s = math.floor(uptime % 60)
            
            local status = "Idle"
            if Config.SawahIndo.AllFarm then status = "All Farm: " .. (Config.SawahIndo.AllFarmPhase or "...")
            elseif Config.SawahIndo.Farm then status = "Farming"
            elseif Config.SawahIndo.Egg then status = "Collecting Egg"
            elseif Config.SawahIndo.Milk then status = "Collecting Milk" end
            
            local cropCount = CountActiveCrops()
            
            pcall(function()
                UptimeLabel:Set(string.format("Uptime: %02d:%02d:%02d", h, m, s))
                StatusLabel:Set("Status: " .. status)
                CropLabel:Set("Crop Aktif: " .. cropCount .. " / " .. Config.SawahIndo.MaxCrop)
                TPModeLabel:Set("TP Mode: " .. Config.SawahIndo.TPMode)
            end)
        end
    end)

    WindUI:Notify({ Title = "Mizukage System", Content = "Sawah Indo loaded!", Duration = 3 })
end

SetupPromptCache()
SetupEventConnections()
SetupConfirmClicker()
task.spawn(InitUI)
