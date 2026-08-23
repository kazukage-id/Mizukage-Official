local WEBHOOK_URL = "https://discord.com/api/webhooks/1516421004291997718/t5nSkmWsiwWFpSNHjJQv3fdQKWGm2SqOQag3LS3kSEwHL1QkuyfbgzFpLI7kDXO357Bj"
local SCRIPT_RAW_URL = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/scripts/ironsoul.lua" 
local SETTINGS_FILE = "TeamMizu_Settings.json"

-- [ANTI DUPLICATION]
if getgenv().MizuBlankBase then
    return game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Mizukage Engine",
        Text = "System is already running in memory."
    })
end
getgenv().MizuBlankBase = true

if syn and syn.queue_on_teleport then
    pcall(function() syn.queue_on_teleport('loadstring(game:HttpGet("' .. SCRIPT_RAW_URL .. '"))()') end)
elseif queue_on_teleport then
    pcall(function() queue_on_teleport('loadstring(game:HttpGet("' .. SCRIPT_RAW_URL .. '"))()') end)
end

--================================================
-- [SECTION 1] SERVICES & FRAMEWORK
--================================================
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- MIZUKAGE & IRON SOUL FRAMEWORK
local Framework = ReplicatedStorage:WaitForChild("Framework")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlayerActionRE = Remotes:FindFirstChild("PlayerActionRE")
local StatsRE = Remotes:FindFirstChild("StatsRE")
local GamePlayerRE = Remotes:FindFirstChild("GamePlayerRE")
local GameRoundRE = Remotes:FindFirstChild("GameRoundRE")

-- MANGO FRAMEWORK MODULES
local FrameworkMod = require(Framework)
local TranslationUtil = FrameworkMod.Modules.TranslationUtil
local ForgeUtil = FrameworkMod.Modules.ForgeUtil
local RarityTiers = FrameworkMod.Modules.RarityTiers
local DataUtil = FrameworkMod.Modules.DataUtil
local MaterialUtil = FrameworkMod.Modules.MaterialUtil
local EquipmentUtil = FrameworkMod.Modules.EquipmentUtil

local LocalControlMgr = character:WaitForChild("LocalControlMgr", 10)
local ActionFolder = LocalControlMgr and LocalControlMgr:FindFirstChild("Action")
local ActionModules = {}
if ActionFolder then
    for _, module in ipairs(ActionFolder:GetChildren()) do
        if module:IsA("ModuleScript") then ActionModules[module.Name] = require(module) end
    end
end
local Controller = LocalControlMgr and require(LocalControlMgr:WaitForChild("Controller"))
local controllerInstance = Controller and Controller.new(character, ActionModules)
local OldWalkSpeed = Controller and Controller.SetWalkSpeed

--================================================
-- [SECTION 2] CONFIGURATIONS & STATE
--================================================
local Config = {
    IsRunning = true,
    AutoFarm = false,
    -- Iron Soul Orbit
    UseIronSoulOrbit = true,
    OrbitRadius = 6,
    OrbitSpeed = 4.0,
    AboveHeight = 8,
    UndergroundHeight = 8,
    UndergroundMode = true,
    -- Mango Static Offset
    Distance_X = 0,
    Distance_Y = 0,
    Distance_Z = 10,
    Pitch = 45,
    -- Mango Features
    AllowCameraChange = false,
    CameraDistance = 70,
    BringMobs = false,
    AutoCollectChests = false,
    AutoPlayAgain = false,
    ModifyWalkSpeed = false,
    WalkSpeed_Speed = 16,
    -- Combat & Safety
    AutoSkillTool = false,
    AutoAttackTool = false,
    AutoAvoid = false,
    SafeMode = false,
    EmergencyEscape = true,
    RoomClearDelay = 1.25,
    KillAuraRadius = 45,
    -- NEW: Anti Hit & Auto Portal/Door
    AntiHit = false,
    AntiHitRadius = 35,
    AutoPortal = false,
    AutoDoor = false,
    PortalSearchRadius = 600,
    DoorInteractDistance = 18,
    DoorOpenWait = 0.90,
    -- Auto Sell Toggles
    AutoSell = false,
    SellCrystals = {}, 
    SellOres = {},
    SellEquipment = false, 
}

local State = {
    Character = nil, Humanoid = nil, Root = nil,
    TargetModel = nil, TargetRoot = nil, TargetHumanoid = nil,
    DangerPart = nil, CollectingChests = false, CollectingEggs = false,
    Portal = nil, PortalTimer = 0,
    DoorBusy = false, DoorCooldown = false,
    StageBusy = false, StageCooldown = false,
    RoomClearTimer = 0,
    AntiHitTimer = 0,
    Connections = {}, CharacterConnections = {}
}

local function saveSettings() pcall(function() writefile(SETTINGS_FILE, HttpService:JSONEncode(Config)) end) end
local function loadSettings()
    if isfile(SETTINGS_FILE) then
        pcall(function()
            local data = HttpService:JSONDecode(readfile(SETTINGS_FILE))
            for k, v in pairs(data) do if Config[k] ~= nil then Config[k] = v end end
        end)
    end
end
loadSettings()

--================================================
-- [SECTION 3] MANGO: ESP HIGHLIGHT
--================================================
local TargetHighlight = Instance.new("Highlight")
TargetHighlight.Name = "AutofarmTarget"
TargetHighlight.Enabled = false
TargetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
TargetHighlight.FillTransparency = 0.5
TargetHighlight.FillColor = Color3.fromRGB(92, 82, 145)
TargetHighlight.OutlineTransparency = 0
TargetHighlight.OutlineColor = Color3.fromRGB(255, 215, 0)
pcall(function() TargetHighlight.Parent = player.PlayerGui:WaitForChild("woof", 3) or player.PlayerGui end)

local function SetCurrentEnemy(enemy)
    if enemy then
        TargetHighlight.Adornee = enemy
        TargetHighlight.Enabled = true
    else
        TargetHighlight.Enabled = false
    end
end

--================================================
-- [SECTION 3.5] NEW: ANTI HIT SYSTEM
--================================================
local function isRedAttackObject(object)
    if not object:IsA("BasePart") then return false end
    local hue, sat, val = Color3.toHSV(object.Color)
    return (hue < 0.055 or hue > 0.945) and sat > 0.55 and val > 0.35 and object.Color.R > object.Color.G * 1.35
end

local dangerOverlapParams = OverlapParams.new()
dangerOverlapParams.FilterType = Enum.RaycastFilterType.Exclude

local function findNearbyRedAttack()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return nil end
    dangerOverlapParams.FilterDescendantsInstances = {player.Character}
    local origin = player.Character.HumanoidRootPart.Position
    local nearest, nearestDistSq = nil, Config.AntiHitRadius * Config.AntiHitRadius
    local ok, parts = pcall(function() return Workspace:GetPartBoundsInRadius(origin, Config.AntiHitRadius, dangerOverlapParams) end)
    if not ok then return nil end
    for _, obj in ipairs(parts) do
        if isRedAttackObject(obj) then
            local distSq = (origin - obj.Position).Magnitude ^ 2
            if distSq < nearestDistSq then
                nearestDistSq = distSq
                nearest = obj
            end
        end
    end
    return nearest
end

local function AntiHitLogic()
    if not Config.AntiHit then return end
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    local danger = findNearbyRedAttack()
    if danger and danger.Parent then
        State.DangerPart = danger
        local away = (myRoot.Position - danger.Position)
        away = Vector3.new(away.X, 0, away.Z).Unit
        local escapePos = myRoot.Position + away * (Config.SafeMode and 20 or 15)
        
        -- Teleport away from danger
        pcall(function()
            myRoot.CFrame = CFrame.new(escapePos)
            myRoot.AssemblyLinearVelocity = Vector3.zero
        end)
    else
        State.DangerPart = nil
    end
end

-- Anti Hit Loop
task.spawn(function()
    while task.wait(0.1) do
        if Config.IsRunning and Config.AntiHit and Config.AutoFarm then
            AntiHitLogic()
        end
    end
end)

--================================================
-- [SECTION 3.6] NEW: AUTO PORTAL & DOOR SYSTEM
--================================================
local portalCandidates = {}

local function getExitType(part)
    if not part:IsA("BasePart") then return nil end
    local names, ancestor, depth = {string.lower(part.Name)}, part.Parent, 0
    while ancestor and depth < 4 do
        if ancestor:IsA("Model") or ancestor:IsA("Folder") then
            table.insert(names, string.lower(ancestor.Name))
        end
        ancestor = ancestor.Parent
        depth += 1
    end
    local hasPortal, hasDoor = false, false
    for _, name in ipairs(names) do
        if name:find("portal") or name:find("teleport") or name:find("warp") or name:find("next") or name:find("finish") then
            hasPortal = true
        end
        if name:find("door") or name:find("gate") or name:find("exit") or name:find("entrance") then
            hasDoor = true
        end
    end
    if hasPortal then return "portal" end
    if hasDoor then return "door" end
    return nil
end

local function scorePortal(part, origin)
    local exitType = getExitType(part)
    if not exitType then return -math.huge, nil end
    local score = (exitType == "portal") and 8 or 2
    if part:FindFirstChildOfClass("TouchTransmitter") then score += 3 end
    if part:FindFirstChildOfClass("ProximityPrompt") then score += 4 end
    if part.Material == Enum.Material.Neon then score += 3 end
    if part.Size.Y > 5 and part.Size.X > 5 then score += 2 end
    score += math.max(0, 1 - ((origin - part.Position).Magnitude ^ 2) / (50 * 50))
    return score, exitType
end

local function isPortalCandidate(part) return getExitType(part) ~= nil end

local function rebuildPortalCandidates()
    table.clear(portalCandidates)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isPortalCandidate(obj) then
            table.insert(portalCandidates, obj)
        end
    end
end

local function travelToPosition(position, lookAt)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
    local myRoot = player.Character.HumanoidRootPart
    local cframe = lookAt and CFrame.new(position, lookAt) or CFrame.new(position)
    return pcall(function()
        myRoot.CFrame = cframe
        myRoot.AssemblyLinearVelocity = Vector3.zero
        myRoot.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function interactWithDoor(door)
    if State.DoorBusy or State.DoorCooldown then return false end
    State.DoorBusy = true
    local succeeded = false
    pcall(function()
        local prompt = door:FindFirstChildOfClass("ProximityPrompt") or door:FindFirstChildWhichIsA("ProximityPrompt", true)
        local approach = door.Position - door.CFrame.LookVector * Config.DoorInteractDistance
        travelToPosition(approach, door.Position)
        task.wait(0.25)
        if prompt and fireproximityprompt then
            fireproximityprompt(prompt)
            succeeded = true
        else
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
            succeeded = true
        end
        task.wait(Config.DoorOpenWait)
    end)
    State.DoorBusy = false
    State.DoorCooldown = true
    task.delay(1.25, function() State.DoorCooldown = false end)
    return succeeded
end

local function moveToNextStage()
    if not Config.AutoFarm or State.StageBusy or State.StageCooldown or State.DoorBusy then return end
    if not Config.AutoPortal and not Config.AutoDoor then return end
    
    -- Check if room is cleared
    local targetModel, targetRoot = getAliveTarget()
    if targetModel and targetRoot then
        State.RoomClearTimer = 0
        return
    end
    
    if State.RoomClearTimer < Config.RoomClearDelay then return end

    rebuildPortalCandidates()
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    local origin = myRoot.Position
    local bestPortal, bestPortalScore, bestDoor, bestDoorScore = nil, -math.huge, nil, -math.huge
    
    for _, part in ipairs(portalCandidates) do
        if part.Parent and (origin - part.Position).Magnitude ^ 2 <= (Config.PortalSearchRadius ^ 2) then
            local score, exitType = scorePortal(part, origin)
            if exitType == "portal" and Config.AutoPortal and score > bestPortalScore then
                bestPortal = part
                bestPortalScore = score
            elseif exitType == "door" and Config.AutoDoor and score > bestDoorScore then
                bestDoor = part
                bestDoorScore = score
            end
        end
    end

    local exitObject, exitType = bestPortal or bestDoor, bestPortal and "portal" or "door"
    if not exitObject then return end

    State.StageBusy = true
    pcall(function()
        if exitType == "door" then
            if interactWithDoor(exitObject) then
                task.wait(Config.DoorOpenWait)
                rebuildPortalCandidates()
            end
        else
            local approach = exitObject.Position - exitObject.CFrame.LookVector * 8
            travelToPosition(approach, exitObject.Position)
            task.wait(0.15)
            travelToPosition(exitObject.Position, exitObject.Position + exitObject.CFrame.LookVector)
        end
    end)
    State.StageBusy = false
    State.StageCooldown = true
    State.RoomClearTimer = 0
    task.delay(0.75, function() State.StageCooldown = false end)
end

-- Auto Portal & Door Loop
task.spawn(function()
    while task.wait(0.5) do
        if Config.IsRunning and Config.AutoFarm and not State.CollectingChests and not State.CollectingEggs then
            State.RoomClearTimer += 0.5
            moveToNextStage()
        end
    end
end)

--================================================
-- [SECTION 4] MANGO: AUTO SELL LOGIC
--================================================
local function GetOresWithNames()
    local result = {}
    local ores_ForData = DataUtil:GetPlayerData(player).Ores
    for oreId, amount in pairs(ores_ForData) do
        local def = ForgeUtil:GetDef(oreId)
        if def then
            local name = TranslationUtil:TranslateByKey("K_" .. string.upper(def.ID))
            local Rarity = RarityTiers.Tiers[def.Rarity]
            table.insert(result, { ID = oreId, Name = name, Amount = amount, Rarity = Rarity.Name })
        end
    end
    return result
end

local function GetCrystals()
    local result = {}
    local crystals_data = DataUtil:GetPlayerData(player).Crystals
    for crystalId, amount in pairs(crystals_data) do
        local def, materialType = MaterialUtil:GetDef(crystalId)
        if def then
            local name = TranslationUtil:TranslateByKey("K_" .. string.upper(def.ID))
            local Rarity = RarityTiers.Tiers[def.Rarity]
            table.insert(result, { ID = crystalId, Name = name, Rarity = Rarity.Name, Amount = amount, MaterialType = materialType })
        end
    end
    return result
end

-- Auto Sell Loop (Mango)
task.spawn(function()
    while task.wait(1) do
        if Config.IsRunning and Config.AutoSell then
            local success, err = pcall(function()
                -- Crystals
                local FinalLoop = {}
                local hasCrystals = false
                for _, v in pairs(GetCrystals()) do
                    if Config.SellCrystals[v.Rarity] then
                        FinalLoop[v.ID] = 1
                        hasCrystals = true
                    end
                end
                if hasCrystals then
                    Framework.Gameplay.EquipmentSystem.MaterialUtil.RemoteEvent:FireServer("Sell", FinalLoop, {})
                end
                
                -- Ores
                local OresLoop = {}
                local hasOres = false
                for _, v in pairs(GetOresWithNames()) do
                    if Config.SellOres[v.Rarity] then
                        OresLoop[v.ID] = 1
                        hasOres = true
                    end
                end
                if hasOres then
                    Framework.Gameplay.EquipmentSystem.ForgeRF:InvokeServer("Sell", OresLoop)
                end

                -- Equipment
                if Config.SellEquipment then
                    for _, v in pairs(DataUtil:GetPlayerData(player).Equipment.Owned) do
                        Framework.Gameplay.EquipmentSystem.EquipmentRE:FireServer("Sell", {v.UUID})
                    end
                end
            end)
            if not success then warn("Auto Sell Error:", err) end
        end
    end
end)

--================================================
-- [SECTION 5] MANGO: AUTO CHEST, PLAY AGAIN & BRING
--================================================
-- Chest & Egg Loop
task.spawn(function()
    while task.wait() do
        if Config.IsRunning and Config.AutoCollectChests then
            pcall(function()
                State.CollectingChests = false
                for _, v in pairs(Workspace:GetChildren()) do
                    if v:IsA("Model") and string.find(v.Name, "Chest") and v:FindFirstChild("Root") and v:GetAttribute("HitCount") > 0 then
                        State.CollectingChests = true
                        local FinalDistance = CFrame.new(Config.Distance_X, Config.Distance_Y, Config.Distance_Z) * CFrame.Angles(math.rad(Config.Pitch), math.rad(180), 0)
                        player.Character.HumanoidRootPart.CFrame = v.Root.CFrame * FinalDistance
                    end
                    if v:FindFirstChild("DragonEgg") and v.DragonEgg:FindFirstChild("EggModel") and v.DragonEgg.EggModel:FindFirstChild("Root") and v:FindFirstChild("Root") and not v:GetAttribute("Active") then
                        State.CollectingEggs = true
                        player.Character.HumanoidRootPart.CFrame = v.DragonEgg.EggModel:FindFirstChild("Root").CFrame
                        task.wait(0.1)
                        if fireproximityprompt then fireproximityprompt(v.Root.Interact_ProximityPrompt) end
                        State.CollectingEggs = false
                    end
                end
            end)
        end
    end
end)

-- Play Again & Walkspeed
task.spawn(function()
    while task.wait() do
        if not Config.IsRunning then break end
        if Config.AutoPlayAgain then
            pcall(function()
                if player.PlayerGui.BattleHUD.PlayerRevive.ReviveFrame.Visible then
                    Remotes.GamePlayerRE:FireServer("ExitSettlement")
                end
                if player.PlayerGui.ResultGui.ScreenSettlement.Visible then
                    Remotes.GameRoundRE:FireServer("VotePlayAgain")
                end
            end)
        end
        if Config.ModifyWalkSpeed and Controller then
            pcall(function()
                Controller.SetWalkSpeed = function(p65, p66) p65.Humanoid.WalkSpeed = Config.WalkSpeed_Speed end
                player.Character.Humanoid.WalkSpeed = Config.WalkSpeed_Speed
            end)
        end
    end
end)

--================================================
-- [SECTION 6] IRON SOUL + MANGO COMBAT LOGIC
--================================================
local function AttackLogic(useSkill)
    if not controllerInstance then return end
    controllerInstance:PerformAction("BaseAttack")
    task.wait()
    controllerInstance:StopAction("BaseAttack")
    if useSkill then
        task.spawn(function()
            pcall(function()
                for _, v in pairs(player.PlayerGui.ScreenInput.PCInput.Skills:GetChildren()) do
                    if v:IsA("ImageButton") and v:GetAttribute("OnCD") == false then
                        if v:GetAttribute("FullCharge") == true then
                            controllerInstance:PerformAction("SkillU")
                            task.wait(0.1)
                            return
                        end
                        controllerInstance:PerformAction("Skill1"); task.wait(0.1)
                        controllerInstance:PerformAction("Skill2"); task.wait(0.1)
                        controllerInstance:PerformAction("SkillAW")
                    end
                end
            end)
        end)
    end
end

local enemyCandidates = {}
local function addEnemyCandidate(obj)
    local model = obj:IsA("Model") and obj or obj:FindFirstAncestorOfClass("Model")
    if model and model ~= player.Character and model:FindFirstChildOfClass("Humanoid") then enemyCandidates[model] = true end
end
for _, obj in ipairs(Workspace:GetDescendants()) do addEnemyCandidate(obj) end
Workspace.DescendantAdded:Connect(addEnemyCandidate)

local function getAliveTarget()
    local origin = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not origin then return nil, nil end
    local nearestModel, nearestRoot, bestDistSq = nil, nil, math.huge
    for model in pairs(enemyCandidates) do
        if model.Parent then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
            if hum and hum.Health > 0 and root then
                local distSq = (origin.Position - root.Position).Magnitude ^ 2
                if distSq < bestDistSq then bestDistSq = distSq; nearestRoot = root; nearestModel = model end
            end
        else enemyCandidates[model] = nil end
    end
    return nearestModel, nearestRoot
end

local OrbitAngle = 0
RunService.Heartbeat:Connect(function(dt)
    if not Config.IsRunning or not Config.AutoFarm then return end
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or State.CollectingChests or State.CollectingEggs then return end
    if State.StageBusy then return end

    -- Handle UI WhiteEffect Bug
    pcall(function()
        local whiteEffect = player.PlayerGui:FindFirstChild("ScreenDesign") and player.PlayerGui.ScreenDesign:FindFirstChild("WhiteEffect")
        if whiteEffect then whiteEffect:Destroy() end
    end)

    local targetModel, targetRoot = getAliveTarget()
    SetCurrentEnemy(targetModel)

    if targetRoot then
        State.TargetRoot = targetRoot
        
        -- [BRING MOBS - MANGO]
        if Config.BringMobs then
            task.spawn(function()
                for v in pairs(enemyCandidates) do
                    if v.Parent and v ~= targetModel then
                        local vRoot = v:FindFirstChild("HumanoidRootPart")
                        if vRoot and (targetRoot.Position - vRoot.Position).Magnitude <= 100 then
                            vRoot.CFrame = targetRoot.CFrame
                        end
                    end
                end
            end)
        end

        -- [POSITIONING]
        if Config.UseIronSoulOrbit then
            -- IRON SOUL ORBIT LOGIC
            local targetPos = targetRoot.Position
            local vOffset = Config.UndergroundMode and math.max(0, Config.UndergroundHeight) or math.max(0, Config.AboveHeight)
            OrbitAngle += (dt * Config.OrbitSpeed)
            local x = math.sin(OrbitAngle) * Config.OrbitRadius
            local z = math.cos(OrbitAngle) * Config.OrbitRadius
            local y = Config.UndergroundMode and (targetPos.Y - vOffset) or (targetPos.Y + vOffset)
            local tilt = Config.UndergroundMode and 90 or -90
            myRoot.CFrame = CFrame.new(targetPos.X + x, y, targetPos.Z + z) * CFrame.Angles(math.rad(tilt), 0, 0)
            myRoot.AssemblyLinearVelocity = Vector3.zero
        else
            -- MANGO STATIC OFFSET LOGIC
            local FinalDistance = CFrame.new(Config.Distance_X, Config.Distance_Y, Config.Distance_Z) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(Config.Pitch))
            if targetModel:GetAttribute("LevelType") == "Boss" then
                FinalDistance = CFrame.new(Config.Distance_X * 1.5, Config.Distance_Y * 1.5, Config.Distance_Z * 1.5) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(Config.Pitch))
            end
            myRoot.CFrame = targetRoot.CFrame * FinalDistance
            myRoot.AssemblyLinearVelocity = Vector3.zero
        end

        -- [CAMERA CHANGE - MANGO]
        if Config.AllowCameraChange then
            task.spawn(function()
                Camera.CameraType = Enum.CameraType.Scriptable
                local camPos = myRoot.Position + Vector3.new(0, Config.CameraDistance, 50)
                TweenService:Create(Camera, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {CFrame = CFrame.lookAt(camPos, myRoot.Position)}):Play()
            end)
        end

        -- [ATTACK EXECUTION]
        if Config.AutoAttackTool then task.spawn(function() AttackLogic(Config.AutoSkillTool) end) end
    else
        -- Fallback if no enemy
        if not Config.AllowCameraChange then
            Camera.CameraType = Enum.CameraType.Custom
            Camera.CameraSubject = player.Character:FindFirstChildOfClass("Humanoid")
        end
    end
end)

--================================================
-- [SECTION 7] WIND UI INTERFACE (PREMIUM TEAMMIZU)
--================================================
local function InitInterface()
    local success, WindUI = pcall(function() return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/1.6.65/main.lua"))() end)
    if not success or type(WindUI) ~= "table" then
        success, WindUI = pcall(function() return loadstring(game:HttpGet("https://tree-hub.vercel.app/api/UI/WindUI"))() end)
        if not success then return warn("[MIZUKAGE] UI Failed to load.") end
    end

    --================================================
    -- LOCALIZATION SYSTEM
    --================================================
    WindUI:Localization({
        Enabled = true,
        Prefix = "loc:",
        DefaultLanguage = "en",
        Translations = {
            ["id"] = {
                ["WELCOME"] = "Selamat Datang di Mizukage TeamMizu!",
                ["MAIN"] = "Autofarm Utama",
                ["POSITION"] = "Engine Posisi",
                ["UTILITY"] = "Utilitas Mango",
                ["SELL"] = "Auto Jual",
                ["SAFETY"] = "Keamanan",
                ["LOADED"] = "Iron Soul Dungeon Edition berhasil dimuat!",
                ["START_FARM"] = "Mulai Farming",
                ["CLOSE"] = "Tutup",
            },
            ["en"] = {
                ["WELCOME"] = "Welcome to Mizukage TeamMizu!",
                ["MAIN"] = "Main Autofarm",
                ["POSITION"] = "Position Engine",
                ["UTILITY"] = "Mango Utility",
                ["SELL"] = "Auto Sell",
                ["SAFETY"] = "Safety",
                ["LOADED"] = "Iron Soul Dungeon Edition loaded successfully!",
                ["START_FARM"] = "Start Farming",
                ["CLOSE"] = "Close",
            },
        }
    })

    --================================================
    -- GRADIENT THEME (MIZUKAGE PURPLE x BLUE)
    --================================================
    WindUI:Gradient({
        ["0"] = { Color = Color3.fromHex("#5c5291"), Transparency = 0.15 },
        ["50"] = { Color = Color3.fromHex("#0096ff"), Transparency = 0.10 },
        ["100"] = { Color = Color3.fromHex("#18181b"), Transparency = 0 },
    }, {
        Rotation = 45,
    })

    --================================================
    -- CREATE WINDOW
    --================================================
    local viewport = Camera.ViewportSize
    local isMobile = viewport.X < 850
    local dynamicSize = isMobile and UDim2.fromOffset(viewport.X * 0.95, viewport.Y * 0.95) or UDim2.fromOffset(840, 600)

    local Window = WindUI:CreateWindow({
        Title = "MIZUKAGE OFFICIAL 👑",
        Icon = "lucide:crown",
        Author = "TEAMMIZU EDITION",
        Folder = "MizukageTeamMizu",
        Size = dynamicSize,
        MinSize = Vector2.new(560, 400),
        MaxSize = Vector2.new(950, 750),
        ToggleKey = Enum.KeyCode.RightShift,
        Transparent = true,
        Theme = "Dark",
        Accent = Color3.fromRGB(92, 82, 145),
        Resizable = true,
        SideBarWidth = isMobile and 240 or 260,
        HasOutline = true,
        BackgroundImageTransparency = 0.42,
        Background = "rbxassetid://137490169052447",
        HideSearchBar = false,
        ScrollBarEnabled = true,
        
        -- USER SYSTEM
        User = {
            Enabled = true,
            Anonymous = false,
            Callback = function()
                WindUI:Notify({
                    Title = "👤 Player Info",
                    Content = string.format("Name: %s\nDisplay: %s\nUserID: %s", player.Name, player.DisplayName, player.UserId),
                    Duration = 5,
                    Icon = "lucide:user",
                })
            end,
        },
    })

    --================================================
    -- TAGS (VIP & VERSION)
    --================================================
    Window:Tag({
        Title = "👑 VIP",
        Icon = "lucide:crown",
        Color = Color3.fromHex("#FFD700"),
        Radius = 13,
    })

    Window:Tag({
        Title = "v3.0.0",
        Icon = "lucide:sparkles",
        Color = Color3.fromHex("#30ff6a"),
        Radius = 6,
    })

    Window:Tag({
        Title = "TEAMMIZU",
        Icon = "lucide:users",
        Color = Color3.fromHex("#0096ff"),
        Radius = 0,
    })

    Window:Divider()

    --================================================
    -- CONFIG MANAGER (TeamMizu)
    --================================================
    local ConfigManager = Window.ConfigManager
    local MizuConfig = ConfigManager:CreateConfig("TeamMizu")

    --================================================
    -- CREATE TABS
    --================================================
    local TabMain = Window:Tab({ Title = "loc:MAIN", Icon = "lucide:sword" })
    local TabPos = Window:Tab({ Title = "loc:POSITION", Icon = "lucide:move" })
    local TabSafety = Window:Tab({ Title = "loc:SAFETY", Icon = "lucide:shield" })
    local TabUtility = Window:Tab({ Title = "loc:UTILITY", Icon = "lucide:package" })
    local TabSell = Window:Tab({ Title = "loc:SELL", Icon = "lucide:shopping-cart" })

    --================================================
    -- MAIN TAB
    --================================================
    TabMain:Section({ Title = "Combat & Autofarm" })
    TabMain:Toggle({
        Title = "Enable Auto Farm Master",
        Flag = "AutoFarm",
        Default = Config.AutoFarm,
        Callback = function(s)
            Config.AutoFarm = s
            saveSettings()
            if s then
                WindUI:Notify({
                    Title = "⚔️ Auto Farm",
                    Content = "✅ Auto Farm enabled - Hunting enemies...",
                    Duration = 3,
                    Icon = "lucide:sword",
                })
            end
        end
    })
    TabMain:Toggle({
        Title = "Auto Attack (Mango Controller)",
        Flag = "AutoAttackTool",
        Default = Config.AutoAttackTool,
        Callback = function(s) Config.AutoAttackTool = s; saveSettings() end
    })
    TabMain:Toggle({
        Title = "Auto Use Skill",
        Flag = "AutoSkillTool",
        Default = Config.AutoSkillTool,
        Callback = function(s) Config.AutoSkillTool = s; saveSettings() end
    })

    TabMain:Divider()

    TabMain:Section({ Title = "Mango Features" })
    TabMain:Toggle({
        Title = "Bring Mobs to Target",
        Flag = "BringMobs",
        Default = Config.BringMobs,
        Callback = function(s) Config.BringMobs = s; saveSettings() end
    })
    TabMain:Toggle({
        Title = "Auto Collect Chests & Eggs",
        Flag = "AutoCollectChests",
        Default = Config.AutoCollectChests,
        Callback = function(s) Config.AutoCollectChests = s; saveSettings() end
    })
    TabMain:Toggle({
        Title = "Auto Play Again (Settlement)",
        Flag = "AutoPlayAgain",
        Default = Config.AutoPlayAgain,
        Callback = function(s) Config.AutoPlayAgain = s; saveSettings() end
    })

    TabMain:Divider()

    TabMain:Section({ Title = "Camera Settings" })
    TabMain:Toggle({
        Title = "Allow Camera Change",
        Flag = "AllowCameraChange",
        Default = Config.AllowCameraChange,
        Callback = function(s)
            Config.AllowCameraChange = s
            if not s then
                Camera.CameraType = Enum.CameraType.Custom
                Camera.CameraSubject = player.Character.Humanoid
            end
            saveSettings()
        end
    })
    TabMain:Slider({
        Title = "Camera Distance",
        Flag = "CameraDistance",
        Step = 1,
        Value = { Min = 0, Max = 100, Default = Config.CameraDistance },
        Callback = function(v) Config.CameraDistance = v; saveSettings() end
    })

    --================================================
    -- POSITION TAB
    --================================================
    TabPos:Section({ Title = "Positioning Engine Selection" })
    TabPos:Toggle({
        Title = "Use Iron Soul Smooth Orbit",
        Flag = "UseIronSoulOrbit",
        Default = Config.UseIronSoulOrbit,
        Callback = function(s) Config.UseIronSoulOrbit = s; saveSettings() end
    })

    TabPos:Divider()

    TabPos:Section({ Title = "Mango Static Offset (Works if Orbit OFF)" })
    TabPos:Slider({
        Title = "Distance X",
        Flag = "Distance_X",
        Step = 1,
        Value = { Min = -20, Max = 20, Default = Config.Distance_X },
        Callback = function(v) Config.Distance_X = v; saveSettings() end
    })
    TabPos:Slider({
        Title = "Distance Y",
        Flag = "Distance_Y",
        Step = 1,
        Value = { Min = -20, Max = 20, Default = Config.Distance_Y },
        Callback = function(v) Config.Distance_Y = v; saveSettings() end
    })
    TabPos:Slider({
        Title = "Distance Z",
        Flag = "Distance_Z",
        Step = 1,
        Value = { Min = -20, Max = 20, Default = Config.Distance_Z },
        Callback = function(v) Config.Distance_Z = v; saveSettings() end
    })
    TabPos:Slider({
        Title = "Pitch Angle",
        Flag = "Pitch",
        Step = 1,
        Value = { Min = -180, Max = 180, Default = Config.Pitch },
        Callback = function(v) Config.Pitch = v; saveSettings() end
    })

    TabPos:Divider()

    TabPos:Section({ Title = "Iron Soul Orbit Setting (Works if Orbit ON)" })
    TabPos:Toggle({
        Title = "Underground Mode",
        Flag = "UndergroundMode",
        Default = Config.UndergroundMode,
        Callback = function(s)
            Config.UndergroundMode = s
            saveSettings()
            if s then
                WindUI:Notify({
                    Title = "⚠️ Warning",
                    Content = "Underground Mode activated - Use at your own risk!",
                    Duration = 4,
                    Icon = "lucide:alert-triangle",
                })
            end
        end
    })
    TabPos:Slider({
        Title = "Under Height",
        Flag = "UndergroundHeight",
        Step = 1,
        Value = { Min = 5, Max = 50, Default = Config.UndergroundHeight },
        Callback = function(v) Config.UndergroundHeight = v; saveSettings() end
    })
    TabPos:Slider({
        Title = "Above Height",
        Flag = "AboveHeight",
        Step = 1,
        Value = { Min = 5, Max = 50, Default = Config.AboveHeight },
        Callback = function(v) Config.AboveHeight = v; saveSettings() end
    })
    TabPos:Slider({
        Title = "Orbit Radius",
        Flag = "OrbitRadius",
        Step = 1,
        Value = { Min = 2, Max = 25, Default = Config.OrbitRadius },
        Callback = function(v) Config.OrbitRadius = v; saveSettings() end
    })
    TabPos:Slider({
        Title = "Orbit Speed",
        Flag = "OrbitSpeed",
        Step = 0.5,
        Value = { Min = 1, Max = 10, Default = Config.OrbitSpeed },
        Callback = function(v) Config.OrbitSpeed = v; saveSettings() end
    })

    --================================================
    -- SAFETY TAB (NEW)
    --================================================
    TabSafety:Section({ Title = "Anti Hit System" })
    TabSafety:Toggle({
        Title = "Enable Anti Hit (Dodge Red Attacks)",
        Flag = "AntiHit",
        Default = Config.AntiHit,
        Callback = function(s)
            Config.AntiHit = s
            saveSettings()
            if s then
                WindUI:Notify({
                    Title = "🛡️ Anti Hit",
                    Content = "✅ Anti Hit enabled - Dodging red attacks!",
                    Duration = 3,
                    Icon = "lucide:shield",
                })
            end
        end
    })
    TabSafety:Slider({
        Title = "Anti Hit Detection Radius",
        Flag = "AntiHitRadius",
        Step = 5,
        Value = { Min = 15, Max = 60, Default = Config.AntiHitRadius },
        Callback = function(v) Config.AntiHitRadius = v; saveSettings() end
    })
    TabSafety:Toggle({
        Title = "Safe Mode (Extra Distance)",
        Flag = "SafeMode",
        Default = Config.SafeMode,
        Callback = function(s) Config.SafeMode = s; saveSettings() end
    })

    TabSafety:Divider()

    TabSafety:Section({ Title = "Auto Portal & Door" })
    TabSafety:Toggle({
        Title = "Auto Enter Portals",
        Flag = "AutoPortal",
        Default = Config.AutoPortal,
        Callback = function(s)
            Config.AutoPortal = s
            saveSettings()
            if s then
                WindUI:Notify({
                    Title = "🌀 Auto Portal",
                    Content = "✅ Auto Portal enabled!",
                    Duration = 3,
                    Icon = "lucide:door-open",
                })
            end
        end
    })
    TabSafety:Toggle({
        Title = "Auto Open Doors",
        Flag = "AutoDoor",
        Default = Config.AutoDoor,
        Callback = function(s)
            Config.AutoDoor = s
            saveSettings()
            if s then
                WindUI:Notify({
                    Title = "🚪 Auto Door",
                    Content = "✅ Auto Door enabled!",
                    Duration = 3,
                    Icon = "lucide:door-open",
                })
            end
        end
    })
    TabSafety:Slider({
        Title = "Portal Search Radius",
        Flag = "PortalSearchRadius",
        Step = 50,
        Value = { Min = 200, Max = 1500, Default = Config.PortalSearchRadius },
        Callback = function(v) Config.PortalSearchRadius = v; saveSettings() end
    })
    TabSafety:Slider({
        Title = "Room Clear Delay",
        Flag = "RoomClearDelay",
        Step = 0.1,
        Value = { Min = 0.5, Max = 5.0, Default = Config.RoomClearDelay },
        Callback = function(v) Config.RoomClearDelay = v; saveSettings() end
    })

    --================================================
    -- UTILITY TAB
    --================================================
    TabUtility:Section({ Title = "Character Modification" })
    TabUtility:Toggle({
        Title = "Change WalkSpeed",
        Flag = "ModifyWalkSpeed",
        Default = Config.ModifyWalkSpeed,
        Callback = function(s)
            Config.ModifyWalkSpeed = s
            if not s and OldWalkSpeed then Controller.SetWalkSpeed = OldWalkSpeed end
            saveSettings()
        end
    })
    TabUtility:Slider({
        Title = "WalkSpeed Value",
        Flag = "WalkSpeed_Speed",
        Step = 1,
        Value = { Min = 1, Max = 100, Default = Config.WalkSpeed_Speed },
        Callback = function(v) Config.WalkSpeed_Speed = v; saveSettings() end
    })

    TabUtility:Divider()

    TabUtility:Section({ Title = "Config Management" })
    TabUtility:Button({
        Title = "Save Config (TeamMizu)",
        Variant = "Primary",
        Icon = "lucide:save",
        Callback = function()
            MizuConfig:Save()
            WindUI:Notify({
                Title = "💾 Config",
                Content = "TeamMizu config saved!",
                Duration = 3,
                Icon = "lucide:check",
            })
        end
    })
    TabUtility:Button({
        Title = "Load Config (TeamMizu)",
        Variant = "Secondary",
        Icon = "lucide:folder-open",
        Callback = function()
            MizuConfig:Load()
            WindUI:Notify({
                Title = "📂 Config",
                Content = "TeamMizu config loaded!",
                Duration = 3,
                Icon = "lucide:check",
            })
        end
    })

    TabUtility:Divider()

    TabUtility:Button({
        Title = "Unload Script (Terminate)",
        Variant = "Destructive",
        Icon = "lucide:power",
        Callback = function()
            Window:Dialog({
                Icon = "lucide:alert-triangle",
                Title = "Unload Confirmation",
                Content = "Are you sure you want to terminate the script?",
                Buttons = {
                    {
                        Title = "Cancel",
                        Callback = function()
                            print("[MIZUKAGE] Unload cancelled")
                        end,
                        Variant = "Tertiary",
                    },
                    {
                        Title = "Yes, Terminate",
                        Icon = "lucide:power",
                        Callback = function()
                            WindUI:Notify({
                                Title = "👋 Goodbye!",
                                Content = "Script terminated. Thanks for using Mizukage!",
                                Duration = 3,
                                Icon = "lucide:heart",
                            })
                            task.wait(1)
                            Config.IsRunning = false
                            Config.AutoFarm = false
                            getgenv().MizuBlankBase = false
                            Window:Destroy()
                        end,
                        Variant = "Destructive",
                    },
                },
            })
        end
    })

    --================================================
    -- AUTO SELL TAB
    --================================================
    TabSell:Section({ Title = "Auto Sell Configuration" })
    TabSell:Toggle({
        Title = "ENABLE AUTO SELL",
        Flag = "AutoSell",
        Default = Config.AutoSell,
        Callback = function(s)
            Config.AutoSell = s
            saveSettings()
            if s then
                WindUI:Notify({
                    Title = "💰 Auto Sell",
                    Content = "✅ Auto Sell enabled!",
                    Duration = 3,
                    Icon = "lucide:shopping-cart",
                })
            end
        end
    })

    TabSell:Divider()

    TabSell:Section({ Title = "Sell Ores (By Rarity)" })
    for _, tier in pairs(RarityTiers.Tiers) do
        if tier.Name ~= "None" then
            TabSell:Toggle({
                Title = "Sell Ore: " .. tier.Name,
                Flag = "SellOre_" .. tier.Name,
                Default = Config.SellOres[tier.Name] or false,
                Callback = function(s) Config.SellOres[tier.Name] = s; saveSettings() end
            })
        end
    end

    TabSell:Divider()

    TabSell:Section({ Title = "Sell Crystals (By Rarity)" })
    for _, tier in pairs(RarityTiers.Tiers) do
        if tier.Name ~= "None" then
            TabSell:Toggle({
                Title = "Sell Crystal: " .. tier.Name,
                Flag = "SellCrystal_" .. tier.Name,
                Default = Config.SellCrystals[tier.Name] or false,
                Callback = function(s) Config.SellCrystals[tier.Name] = s; saveSettings() end
            })
        end
    end

    TabSell:Divider()

    TabSell:Section({ Title = "Sell Equipment" })
    TabSell:Toggle({
        Title = "Sell ALL Equipment",
        Flag = "SellEquipment",
        Default = Config.SellEquipment,
        Callback = function(s) Config.SellEquipment = s; saveSettings() end
    })

    --================================================
    -- WELCOME POPUP
    --================================================
    task.wait(0.5)
    WindUI:Popup({
        Title = "loc:WELCOME",
        Icon = "lucide:crown",
        Content = "loc:LOADED\n\n👑 Created by: Kazukage\n⚔️ Game: Iron Soul Dungeon\n📦 Version: 3.0.0\n👥 Team: TeamMizu\n\nNew Features:\n🛡️ Anti Hit System\n🌀 Auto Portal\n🚪 Auto Door\n\nThank you for using our script!",
        Buttons = {
            {
                Title = "loc:CLOSE",
                Callback = function() end,
                Variant = "Tertiary",
            },
            {
                Title = "loc:START_FARM",
                Icon = "lucide:sword",
                Callback = function()
                    Config.AutoFarm = true
                    WindUI:Notify({
                        Title = "⚔️ Auto Farm",
                        Content = "✅ Auto Farm enabled - Hunting enemies...",
                        Duration = 3,
                        Icon = "lucide:sword",
                    })
                end,
                Variant = "Primary",
            },
        }
    })

    --================================================
    -- LOAD CONFIG AUTOMATICALLY
    --================================================
    MizuConfig:Load()
end

task.spawn(InitInterface)