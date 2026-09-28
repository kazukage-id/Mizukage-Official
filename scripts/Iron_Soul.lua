--[[
    ███╗   ███╗██╗███████╗██╗   ██╗██╗  ██╗ █████╗  ██████╗ ███████╗
    ████╗ ████║██║╚══███╔╝██║   ██║██║ ██╔╝██╔══██╗██╔════╝ ██╔════╝
    ██╔████╔██║██║  ███╔╝ ██║   ██║█████╔╝ ███████║██║  ███╗█████╗  
    ██║╚██╔╝██║██║ ███╔╝  ██║   ██║██╔═██╗ ██╔══██║██║   ██║██╔══╝  
    ██║ ╚═╝ ██║██║███████╗╚██████╔╝██║  ██╗██║  ██║╚██████╔╝███████╗
    ╚═╝     ╚═╝╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
    
    MIZUKAGE OFFICIAL - Iron Soul Dungeon Edition
    Created by: Kazukage
    Version: 3.0.0
]]

local WEBHOOK_URL = "https://discord.com/api/webhooks/1516421004291997718/t5nSkmWsiwWFpSNHjJQv3fdQKWGm2SqOQag3LS3kSEwHL1QkuyfbgzFpLI7kDXO357Bj"
local SCRIPT_RAW_URL = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/scripts/ironsoul.lua" 
local SETTINGS_FILE = "Mizukage_TeamMizu_Settings.json"

-- [ANTI DUPLICATION]
if getgenv().MizukageEngine then
    return game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Mizukage Engine",
        Text = "System is already running in memory."
    })
end
getgenv().MizukageEngine = true

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
    -- Combat
    AutoAttack = true,
    AutoSkill = true,
    KillAuraRadius = 45,
    -- Positioning
    OrbitRadius = 6,
    OrbitSpeed = 4,
    AboveHeight = 8,
    UndergroundHeight = 8,
    UndergroundMode = true,
    -- Safety
    AutoAvoid = false,
    SafeMode = true,
    EmergencyEscape = true,
    -- Stage Progress
    AutoProgressStage = true,
    DoorInteractDistance = 18,
    DoorOpenWait = 0.90,
    ExitSearchRadius = 600,
    RoomClearDelay = 1.25,
    -- Target
    TargetSearchRadius = 600,
    TargetRefresh = 0.20,
    -- NEW FEATURES (User Requested)
    AutoCollectChests = false,
    AutoPlayAgain = false,
    -- Distance offset for chest collection
    ChestOffset_X = 0,
    ChestOffset_Y = 0,
    ChestOffset_Z = 10,
    ChestPitch = 45,
    -- Utilities
    ModifyWalkSpeed = false,
    WalkSpeed_Speed = 16,
    PerformanceMode = false,
    Debug = false,
    SaveSettings = true,
    AccentColor = {92, 82, 145},
}

local State = {
    Character = nil,
    Humanoid = nil,
    Root = nil,
    TargetModel = nil,
    TargetRoot = nil,
    TargetHumanoid = nil,
    Portal = nil,
    PortalScore = 0,
    OrbitAngle = 0,
    TargetTimer = 0,
    PortalTimer = 0,
    SkillTimer = 0,
    AttackTimer = 0,
    StatusTimer = 0,
    SkillCooldowns = { Q = 0, E = 0, R = 0 },
    StageBusy = false,
    StageCooldown = false,
    EmergencyBusy = false,
    CurrentAction = "Idle",
    LastTargetName = "-",
    LastTargetDistance = math.huge,
    TargetHealthPercent = 0,
    DangerDistance = math.huge,
    DangerPart = nil,
    DangerTimer = 0,
    UndergroundPhysics = false,
    RoomClearTimer = 0,
    DoorBusy = false,
    DoorCooldown = false,
    StageBusyTimer = 0,
    WatchdogTimer = 0,
    FallbackTargetTimer = 0,
    CollectingChests = false,
    CollectingEggs = false,
    Stats = {
        Heartbeats = 0,
        TargetScans = 0,
        PortalScans = 0,
        DangerScans = 0,
    },
    Unloaded = false,
}

local Connections = {}
local CharacterConnections = {}

local function syncConfigGlobals()
    _G.MizukageAutoFarm = Config.AutoFarm
    _G.MizukageAutoSkill = Config.AutoSkill
    _G.MizukageAutoAttack = Config.AutoAttack
    _G.MizukageAutoAvoid = Config.AutoAvoid
    _G.MizukageOrbitRadius = Config.OrbitRadius
    _G.MizukageOrbitSpeed = Config.OrbitSpeed
    _G.MizukageUndergroundMode = Config.UndergroundMode
    _G.MizukageKillAuraRadius = Config.KillAuraRadius
end

local function getSaveData()
    return {
        AutoFarm = Config.AutoFarm,
        AutoAttack = Config.AutoAttack,
        AutoSkill = Config.AutoSkill,
        KillAuraRadius = Config.KillAuraRadius,
        OrbitRadius = Config.OrbitRadius,
        OrbitSpeed = Config.OrbitSpeed,
        AboveHeight = Config.AboveHeight,
        UndergroundHeight = Config.UndergroundHeight,
        UndergroundMode = Config.UndergroundMode,
        AutoAvoid = Config.AutoAvoid,
        SafeMode = Config.SafeMode,
        EmergencyEscape = Config.EmergencyEscape,
        AutoProgressStage = Config.AutoProgressStage,
        TargetSearchRadius = Config.TargetSearchRadius,
        ExitSearchRadius = Config.ExitSearchRadius,
        AutoCollectChests = Config.AutoCollectChests,
        AutoPlayAgain = Config.AutoPlayAgain,
        ChestOffset_X = Config.ChestOffset_X,
        ChestOffset_Y = Config.ChestOffset_Y,
        ChestOffset_Z = Config.ChestOffset_Z,
        ChestPitch = Config.ChestPitch,
        ModifyWalkSpeed = Config.ModifyWalkSpeed,
        WalkSpeed_Speed = Config.WalkSpeed_Speed,
        PerformanceMode = Config.PerformanceMode,
        Debug = Config.Debug,
        AccentColor = Config.AccentColor,
    }
end

local function saveSettings()
    if not Config.SaveSettings or type(writefile) ~= "function" then return end
    pcall(function()
        writefile(SETTINGS_FILE, HttpService:JSONEncode(getSaveData()))
    end)
end

local function loadSettings()
    if type(readfile) ~= "function" or type(isfile) ~= "function" or not isfile(SETTINGS_FILE) then
        syncConfigGlobals()
        return
    end
    pcall(function()
        local data = HttpService:JSONDecode(readfile(SETTINGS_FILE))
        if type(data) == "table" then
            for k, v in pairs(data) do
                if Config[k] ~= nil then Config[k] = v end
            end
            if type(data.AccentColor) == "table" then
                local r = tonumber(data.AccentColor[1]) or tonumber(data.AccentColor.r)
                local g = tonumber(data.AccentColor[2]) or tonumber(data.AccentColor.g)
                local b = tonumber(data.AccentColor[3]) or tonumber(data.AccentColor.b)
                if r and g and b then
                    Config.AccentColor = {
                        math.clamp(r, 0, 255),
                        math.clamp(g, 0, 255),
                        math.clamp(b, 0, 255),
                    }
                end
            end
        end
    end)
    syncConfigGlobals()
end

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Connections, connection)
    return connection
end

local function connectCharacter(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(CharacterConnections, connection)
    return connection
end

pcall(loadSettings)
Config.AutoFarm = false
_G.MizukageAutoFarm = false

local function disconnectList(list)
    for _, connection in ipairs(list) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    table.clear(list)
end

local function debugPrint(...)
    if Config.Debug then print("[Mizukage]", ...) end
end

--================================================
-- [SECTION 3] CHARACTER LIFECYCLE
--================================================
local function refreshCharacter(newCharacter)
    disconnectList(CharacterConnections)
    State.Character = newCharacter
    State.Humanoid = newCharacter:FindFirstChildOfClass("Humanoid")
    State.Root = newCharacter:FindFirstChild("HumanoidRootPart")
    State.TargetModel = nil
    State.TargetRoot = nil
    State.TargetHumanoid = nil
    State.StageBusy = false
    State.StageCooldown = false
    State.DoorBusy = false
    State.DoorCooldown = false
    State.RoomClearTimer = 0
    State.StageBusyTimer = 0
    State.UndergroundPhysics = false
    
    if not State.Humanoid then
        State.Humanoid = newCharacter:WaitForChild("Humanoid", 5)
    end
    if not State.Root then
        State.Root = newCharacter:WaitForChild("HumanoidRootPart", 5)
    end
end

connect(player.CharacterAdded, refreshCharacter)
if player.Character then
    refreshCharacter(player.Character)
else
    refreshCharacter(player.CharacterAdded:Wait())
end

--================================================
-- [SECTION 4] INPUT HELPERS
--================================================
local function pressKey(keyName)
    local keyCode = Enum.KeyCode[keyName]
    if not keyCode then return end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.02)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
end

local function activateTool()
    if not State.Character then return end
    local tool = State.Character:FindFirstChildOfClass("Tool")
    if tool then
        pcall(function() tool:Activate() end)
    end
end

--================================================
-- [SECTION 5] TARGET DETECTION
--================================================
local function getAliveTargetParts(model)
    if not model or model == State.Character then return nil, nil end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil, nil end
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    if not root or not root:IsA("BasePart") then return nil, nil end
    return humanoid, root
end

local function scoreTarget(model, humanoid, root, distanceSquared)
    local score = 0
    local name = string.lower(model.Name)
    if distanceSquared < 15 * 15 then
        score += 8
    elseif distanceSquared < 35 * 35 then
        score += 5
    else
        score += 2
    end
    if name:find("boss", 1, true) then
        score += 15
    elseif name:find("elite", 1, true) then
        score += 8
    end
    if humanoid.MaxHealth > 0 then
        local hp = humanoid.Health / humanoid.MaxHealth
        if hp < 0.25 then score += 4 end
    end
    return score
end

local enemyCandidates = {}

local function looksLikeEnemyModel(model)
    if not model or not model:IsA("Model") or model == State.Character or Players:GetPlayerFromCharacter(model) ~= nil then
        return false
    end
    return model:FindFirstChildOfClass("Humanoid") ~= nil
        and (model:FindFirstChild("HumanoidRootPart") ~= nil or model.PrimaryPart ~= nil)
end

local function addEnemyCandidate(object)
    local model = object
    if not model:IsA("Model") then
        model = object:FindFirstAncestorOfClass("Model")
    end
    if model and model ~= State.Character and looksLikeEnemyModel(model) then
        enemyCandidates[model] = true
    end
end

local function removeEnemyCandidate(object)
    if object:IsA("Model") then
        enemyCandidates[object] = nil
    else
        local model = object:FindFirstAncestorOfClass("Model")
        if model then enemyCandidates[model] = nil end
    end
end

for _, object in ipairs(workspace:GetDescendants()) do
    addEnemyCandidate(object)
end
connect(workspace.DescendantAdded, addEnemyCandidate)
connect(workspace.DescendantRemoving, removeEnemyCandidate)

local function findNearestTarget()
    State.Stats.TargetScans += 1
    local root = State.Root
    if not root or not root.Parent then return nil, nil, nil end
    local origin = root.Position
    local searchRadius = Config.TargetSearchRadius
    local searchRadiusSquared = searchRadius * searchRadius
    local nearestRoot = nil
    local nearestHumanoid = nil
    local nearestModel = nil
    local bestScore = -math.huge
    
    for model in pairs(enemyCandidates) do
        if not model or not model.Parent then
            enemyCandidates[model] = nil
        else
            local humanoid, targetRoot = getAliveTargetParts(model)
            if humanoid and targetRoot then
                local offset = origin - targetRoot.Position
                local distanceSquared = offset:Dot(offset)
                if distanceSquared <= searchRadiusSquared then
                    local score = scoreTarget(model, humanoid, targetRoot, distanceSquared)
                    if score > bestScore then
                        bestScore = score
                        nearestRoot = targetRoot
                        nearestHumanoid = humanoid
                        nearestModel = model
                    end
                end
            end
        end
    end
    return nearestModel, nearestRoot, nearestHumanoid
end

local function targetIsValid()
    local model = State.TargetModel
    local humanoid = State.TargetHumanoid
    local root = State.TargetRoot
    return model and model.Parent
        and humanoid and humanoid.Parent and humanoid.Health > 0
        and root and root.Parent
end

local function refreshTarget()
    if not Config.AutoFarm or State.StageBusy then
        State.TargetModel = nil
        State.TargetRoot = nil
        State.TargetHumanoid = nil
        State.RoomClearTimer = 0
        return
    end
    local model, root, humanoid = findNearestTarget()
    State.TargetModel = model
    State.TargetRoot = root
    State.TargetHumanoid = humanoid
    State.LastTargetName = model and model.Name or "No target"
    State.LastTargetDistance = root and State.Root and (State.Root.Position - root.Position).Magnitude or math.huge
    State.TargetHealthPercent = humanoid and humanoid.MaxHealth > 0
        and math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1) * 100
        or 0
    if model and humanoid and humanoid.Health > 0 then
        State.RoomClearTimer = 0
    end
end

--================================================
-- [SECTION 6] PORTAL & DOOR DETECTION
--================================================
local portalCandidates = {}

local function getExitType(part)
    if not part or not part:IsA("BasePart") then return nil end
    local names = { string.lower(part.Name) }
    local ancestor = part.Parent
    local depth = 0
    while ancestor and depth < 4 do
        if ancestor:IsA("Model") or ancestor:IsA("Folder") then
            table.insert(names, string.lower(ancestor.Name))
        end
        ancestor = ancestor.Parent
        depth += 1
    end
    local hasPortalName = false
    local hasDoorName = false
    for _, name in ipairs(names) do
        if name:find("portal", 1, true) or name:find("teleport", 1, true)
            or name:find("warp", 1, true) then
            hasPortalName = true
        end
        if name:find("door", 1, true) or name:find("gate", 1, true)
            or name:find("exit", 1, true) or name:find("entrance", 1, true) then
            hasDoorName = true
        end
        if name:find("next", 1, true) or name:find("finish", 1, true) then
            hasPortalName = true
        end
    end
    if hasPortalName then return "portal" end
    if hasDoorName then return "door" end
    return nil
end

local function isPortalCandidate(part)
    return getExitType(part) ~= nil
end

local function rebuildPortalCandidates()
    State.Stats.PortalScans += 1
    table.clear(portalCandidates)
    for _, object in ipairs(workspace:GetDescendants()) do
        if isPortalCandidate(object) then
            table.insert(portalCandidates, object)
        end
    end
end

local function scorePortal(part, origin)
    if not part or not part.Parent then return -math.huge, nil end
    local exitType = getExitType(part)
    if not exitType then return -math.huge, nil end
    local name = string.lower(part.Name)
    local score = 0
    
    if exitType == "portal" then
        score += 8
        if name:find("portal", 1, true) then score += 5 end
        if name:find("teleport", 1, true) then score += 3 end
    else
        score += 2
        if name:find("door", 1, true) then score += 2 end
        if name:find("gate", 1, true) then score += 2 end
    end
    if name:find("next", 1, true) or name:find("finish", 1, true) or name:find("exit", 1, true) then
        score += 2
    end
    if part:FindFirstChildOfClass("TouchTransmitter") then score += 3 end
    if part:FindFirstChildOfClass("ProximityPrompt") then score += 4 end
    if part.Material == Enum.Material.Neon then score += 3 end
    if part.Size.Y > 5 and part.Size.X > 5 then score += 2 end
    local offset = origin - part.Position
    local distanceSquared = offset:Dot(offset)
    score += math.max(0, 1 - distanceSquared / (50 * 50))
    return score, exitType
end

local function registerPortalCandidate(object)
    if isPortalCandidate(object) and not table.find(portalCandidates, object) then
        table.insert(portalCandidates, object)
    end
end

local function unregisterPortalCandidate(object)
    for index = #portalCandidates, 1, -1 do
        if portalCandidates[index] == object then
            table.remove(portalCandidates, index)
            break
        end
    end
end

connect(workspace.DescendantAdded, registerPortalCandidate)
connect(workspace.DescendantRemoving, unregisterPortalCandidate)

local function findBestExit()
    if not State.Root then return nil, 0, nil end
    local origin = State.Root.Position
    local maxDistanceSquared = Config.ExitSearchRadius * Config.ExitSearchRadius
    local bestPortal, bestPortalScore = nil, -math.huge
    local bestDoor, bestDoorScore = nil, -math.huge
    
    for index = #portalCandidates, 1, -1 do
        local part = portalCandidates[index]
        if not part or not part.Parent then
            table.remove(portalCandidates, index)
        else
            local delta = origin - part.Position
            local distanceSquared = delta:Dot(delta)
            if distanceSquared <= maxDistanceSquared then
                local score, exitType = scorePortal(part, origin)
                if exitType == "portal" and score > bestPortalScore then
                    bestPortal = part
                    bestPortalScore = score
                elseif exitType == "door" and score > bestDoorScore then
                    bestDoor = part
                    bestDoorScore = score
                end
            end
        end
    end
    
    if bestPortal then return bestPortal, bestPortalScore, "portal" end
    if bestDoor then return bestDoor, bestDoorScore, "door" end
    return nil, 0, nil
end

local function findProximityPrompt(rootObject)
    if not rootObject then return nil end
    if rootObject:IsA("ProximityPrompt") then return rootObject end
    return rootObject:FindFirstChildOfClass("ProximityPrompt")
        or rootObject:FindFirstChildWhichIsA("ProximityPrompt", true)
end

--================================================
-- [SECTION 7] MOVEMENT & TRAVEL
--================================================
local function beginTravel()
    if not State.Humanoid then return end
    pcall(function()
        State.Humanoid.PlatformStand = false
        State.Humanoid.AutoRotate = true
        State.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end)
    State.UndergroundPhysics = false
end

local function travelToPosition(position, lookAt)
    if not State.Character or not State.Root then return false end
    beginTravel()
    local cframe
    if lookAt then
        cframe = CFrame.new(position, lookAt)
    else
        cframe = CFrame.new(position)
    end
    local ok = pcall(function()
        State.Character:PivotTo(cframe)
        State.Root.CFrame = cframe
        State.Root.AssemblyLinearVelocity = Vector3.zero
        State.Root.AssemblyAngularVelocity = Vector3.zero
    end)
    return ok
end

local function interactWithDoor(door)
    if not door or not door.Parent or State.DoorBusy or State.DoorCooldown or not State.Root or not State.Humanoid then
        return false
    end
    State.DoorBusy = true
    State.CurrentAction = "Opening Door"
    local succeeded = false
    
    pcall(function()
        local prompt = findProximityPrompt(door)
        local approachPosition = door.Position - door.CFrame.LookVector * Config.DoorInteractDistance
        travelToPosition(approachPosition, door.Position)
        task.wait(0.25)
        if prompt and type(fireproximityprompt) == "function" then
            fireproximityprompt(prompt)
            succeeded = true
        else
            pressKey("F")
            succeeded = true
        end
        task.wait(Config.DoorOpenWait)
    end)
    
    State.DoorBusy = false
    State.DoorCooldown = true
    task.delay(1.25, function()
        if not State.Unloaded then
            State.DoorCooldown = false
        end
    end)
    return succeeded
end

local function findBestPortalOnly()
    if not State.Root then return nil, 0 end
    local origin = State.Root.Position
    local maxDistanceSquared = Config.ExitSearchRadius * Config.ExitSearchRadius
    local bestPortal = nil
    local bestScore = -math.huge
    
    for index = #portalCandidates, 1, -1 do
        local part = portalCandidates[index]
        if not part or not part.Parent then
            table.remove(portalCandidates, index)
        else
            local delta = origin - part.Position
            local distanceSquared = delta:Dot(delta)
            if distanceSquared <= maxDistanceSquared then
                local score, exitType = scorePortal(part, origin)
                if exitType == "portal" and score > bestScore then
                    bestPortal = part
                    bestScore = score
                end
            end
        end
    end
    return bestPortal, bestScore
end

local function moveToNextStage()
    if not Config.AutoProgressStage or State.StageBusy or State.StageCooldown or State.DoorBusy
        or not State.Root or not State.Humanoid or not Config.AutoFarm then
        return
    end
    
    local model, root, humanoid = findNearestTarget()
    if model and root and humanoid and humanoid.Health > 0 then
        State.TargetModel = model
        State.TargetRoot = root
        State.TargetHumanoid = humanoid
        State.RoomClearTimer = 0
        State.CurrentAction = "Farming"
        return
    end
    
    if State.RoomClearTimer < Config.RoomClearDelay then
        State.CurrentAction = "Clearing"
        return
    end
    
    rebuildPortalCandidates()
    local exitObject, score, exitType = findBestExit()
    if not exitObject or not exitObject.Parent then
        State.CurrentAction = "Searching Exit"
        State.StageBusy = false
        State.StageBusyTimer = 0
        return
    end
    
    State.StageBusy = true
    State.StageBusyTimer = 0
    State.Portal = exitObject
    State.PortalScore = score
    
    local ok, err = pcall(function()
        if exitType == "door" then
            State.CurrentAction = "Moving To Door"
            local opened = interactWithDoor(exitObject)
            if opened then
                task.wait(Config.DoorOpenWait)
                rebuildPortalCandidates()
                local newPortal, newScore = findBestPortalOnly()
                if newPortal and newPortal.Parent then
                    State.Portal = newPortal
                    State.PortalScore = newScore
                    State.CurrentAction = "Moving To Portal"
                    local approach = newPortal.Position - newPortal.CFrame.LookVector * 6
                    travelToPosition(approach, newPortal.Position)
                    task.wait(0.15)
                    travelToPosition(newPortal.Position, newPortal.Position + newPortal.CFrame.LookVector)
                else
                    State.CurrentAction = "Entering Door"
                    local approach = exitObject.Position - exitObject.CFrame.LookVector * 4
                    travelToPosition(approach, exitObject.Position)
                    task.wait(0.15)
                    travelToPosition(exitObject.Position, exitObject.Position + exitObject.CFrame.LookVector)
                end
            end
        else
            State.CurrentAction = "Moving To Portal"
            local approach = exitObject.Position - exitObject.CFrame.LookVector * 8
            travelToPosition(approach, exitObject.Position)
            task.wait(0.15)
            State.CurrentAction = "Entering Portal"
            travelToPosition(exitObject.Position, exitObject.Position + exitObject.CFrame.LookVector)
        end
    end)
    
    if not ok and Config.Debug then
        warn("[Mizukage] exit transition error:", err)
    end
    
    State.StageBusy = false
    State.StageBusyTimer = 0
    State.StageCooldown = true
    State.RoomClearTimer = 0
    task.delay(0.75, function()
        if not State.Unloaded then
            State.StageCooldown = false
        end
    end)
end

rebuildPortalCandidates()

--================================================
-- [SECTION 8] COMBAT: SKILLS, ORBIT, ATTACK
--================================================
local SkillCooldownConfig = { Q = 0.70, E = 0.70, R = 1.50 }

local function useSkills()
    if not Config.AutoFarm or not Config.AutoSkill or not targetIsValid() or State.StageBusy then
        return
    end
    local now = os.clock()
    for _, key in ipairs({"E", "Q", "R"}) do
        if now >= State.SkillCooldowns[key] then
            pressKey(key)
            State.SkillCooldowns[key] = now + SkillCooldownConfig[key]
            task.wait(0.15)
        end
    end
end

local function setUndergroundPhysics(enabled)
    if not State.Humanoid or not State.Humanoid.Parent then return end
    if State.UndergroundPhysics == enabled then return end
    pcall(function()
        if enabled then
            State.Humanoid.AutoRotate = false
            State.Humanoid.PlatformStand = true
            State.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        else
            State.Humanoid.PlatformStand = false
            State.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            State.Humanoid.AutoRotate = true
        end
    end)
    State.UndergroundPhysics = enabled
end

local function getDesiredCombatCFrame()
    if not Config.AutoFarm or State.StageBusy or not State.Root or not State.TargetRoot
        or not State.Humanoid or not targetIsValid() then
        return nil
    end
    local targetPosition = State.TargetRoot.Position
    local radius = Config.OrbitRadius
    local verticalOffset = Config.UndergroundMode
        and math.max(0, tonumber(Config.UndergroundHeight) or 0)
        or math.max(0, tonumber(Config.AboveHeight) or 0)
    
    State.OrbitAngle += (1 / 60) * Config.OrbitSpeed
    local x = math.sin(State.OrbitAngle) * radius
    local z = math.cos(State.OrbitAngle) * radius
    local y
    local tilt
    
    if Config.UndergroundMode then
        setUndergroundPhysics(true)
        y = targetPosition.Y - verticalOffset
        tilt = 90
    else
        setUndergroundPhysics(false)
        y = targetPosition.Y + verticalOffset
        tilt = -90
    end
    
    return CFrame.new(targetPosition.X + x, y, targetPosition.Z + z)
        * CFrame.Angles(math.rad(tilt), 0, 0)
end

local function lockCombatPosition()
    local desiredCFrame = getDesiredCombatCFrame()
    if not desiredCFrame or not State.Character or not State.Root then return end
    pcall(function()
        State.Character:PivotTo(desiredCFrame)
        State.Root.CFrame = desiredCFrame
        State.Root.AssemblyLinearVelocity = Vector3.zero
        State.Root.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function updateKillAura()
    if not Config.AutoFarm or not Config.AutoAttack or State.StageBusy
        or not State.Root or not targetIsValid() then
        return
    end
    local offset = State.Root.Position - State.TargetRoot.Position
    local radius = Config.KillAuraRadius
    if offset:Dot(offset) <= radius * radius then
        activateTool()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.zero)
        end)
    end
end

--================================================
-- [SECTION 9] AUTO AVOID (RED ATTACKS)
--================================================
local function isRedAttackObject(object)
    if not object:IsA("BasePart") then return false end
    local color = object.Color
    local hue, saturation, value = Color3.toHSV(color)
    local redHue = hue < 0.055 or hue > 0.945
    return redHue and saturation > 0.55 and value > 0.35
        and color.R > color.G * 1.35 and color.R > color.B * 1.35
end

local dangerOverlapParams = OverlapParams.new()
dangerOverlapParams.FilterType = Enum.RaycastFilterType.Exclude

local function findNearbyRedAttack()
    State.Stats.DangerScans += 1
    if not Config.AutoAvoid or not State.Root then return nil end
    dangerOverlapParams.FilterDescendantsInstances = { State.Character }
    local origin = State.Root.Position
    local dangerRadius = 35
    local nearest
    local nearestDistanceSquared = dangerRadius * dangerRadius
    local ok, parts = pcall(function()
        return workspace:GetPartBoundsInRadius(origin, dangerRadius, dangerOverlapParams)
    end)
    if not ok or not parts then return nil end
    for _, object in ipairs(parts) do
        if isRedAttackObject(object) then
            local offset = origin - object.Position
            local distanceSquared = offset:Dot(offset)
            if distanceSquared < nearestDistanceSquared then
                nearestDistanceSquared = distanceSquared
                nearest = object
            end
        end
    end
    return nearest
end

local function updateAutoAvoid(dt)
    if not Config.AutoAvoid or State.StageBusy or State.EmergencyBusy
        or not State.Root or not State.Humanoid then
        State.DangerPart = nil
        State.DangerDistance = math.huge
        return
    end
    State.DangerTimer += dt
    local scanInterval = Config.PerformanceMode and 0.30 or 0.12
    if State.DangerTimer >= scanInterval then
        State.DangerTimer = 0
        State.DangerPart = findNearbyRedAttack()
    end
    local danger = State.DangerPart
    if not danger or not danger.Parent then
        State.DangerPart = nil
        State.DangerDistance = math.huge
        if Config.AutoFarm then State.CurrentAction = "Farming" end
        return
    end
    local toDanger = danger.Position - State.Root.Position
    local horizontal = Vector3.new(toDanger.X, 0, toDanger.Z)
    State.DangerDistance = horizontal.Magnitude
    local predicted = danger.Position + danger.AssemblyLinearVelocity * 0.20
    local away = State.Root.Position - predicted
    away = Vector3.new(away.X, 0, away.Z)
    if away.Magnitude < 0.05 then
        away = Vector3.new(1, 0, 0)
    else
        away = away.Unit
    end
    local safeDistance = Config.SafeMode and 16 or 12
    State.CurrentAction = "Avoiding Attack"
    State.Humanoid:MoveTo(State.Root.Position + away * safeDistance)
end

--================================================
-- [SECTION 10] NEW FEATURE: AUTO CHEST & EGG
--================================================
task.spawn(function()
    while task.wait(0.1) do
        if not Config.IsRunning or not Config.AutoCollectChests then
            State.CollectingChests = false
            State.CollectingEggs = false
            task.wait(0.5)
            continue
        end
        
        local char = player.Character
        if not char then task.wait(0.5) continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then task.wait(0.5) continue end
        
        State.CollectingChests = false
        State.CollectingEggs = false
        
        pcall(function()
            -- AUTO CHEST COLLECTION
            for _, v in pairs(Workspace:GetChildren()) do
                if v:IsA("Model") and string.find(v.Name, "Chest") 
                    and v:FindFirstChild("Root") 
                    and v:GetAttribute("HitCount") 
                    and v:GetAttribute("HitCount") > 0 then
                    
                    State.CollectingChests = true
                    local finalCFrame = CFrame.new(
                        Config.ChestOffset_X,
                        Config.ChestOffset_Y,
                        Config.ChestOffset_Z
                    ) * CFrame.Angles(math.rad(Config.ChestPitch), math.rad(180), 0)
                    
                    pcall(function()
                        root.CFrame = v.Root.CFrame * finalCFrame
                        root.AssemblyLinearVelocity = Vector3.zero
                        root.AssemblyAngularVelocity = Vector3.zero
                    end)
                    task.wait(0.05)
                end
                
                -- AUTO EGG COLLECTION
                if v:FindFirstChild("DragonEgg") 
                    and v.DragonEgg:FindFirstChild("EggModel") 
                    and v.DragonEgg.EggModel:FindFirstChild("Root") 
                    and v:FindFirstChild("Root") 
                    and not v:GetAttribute("Active") then
                    
                    State.CollectingEggs = true
                    pcall(function()
                        root.CFrame = v.DragonEgg.EggModel:FindFirstChild("Root").CFrame
                        root.AssemblyLinearVelocity = Vector3.zero
                    end)
                    task.wait(0.1)
                    if fireproximityprompt and v.Root:FindFirstChild("Interact_ProximityPrompt") then
                        pcall(function()
                            fireproximityprompt(v.Root.Interact_ProximityPrompt)
                        end)
                    end
                    State.CollectingEggs = false
                end
            end
        end)
    end
end)

--================================================
-- [SECTION 11] NEW FEATURE: AUTO PLAY AGAIN
--================================================
task.spawn(function()
    while task.wait(1) do
        if not Config.IsRunning or not Config.AutoPlayAgain then
            task.wait(0.5)
            continue
        end
        
        pcall(function()
            local gui = player.PlayerGui
            
            -- Battle HUD Revive Frame (Exit Settlement on death)
            local battleHUD = gui:FindFirstChild("BattleHUD")
            if battleHUD then
                local playerRevive = battleHUD:FindFirstChild("PlayerRevive")
                if playerRevive then
                    local reviveFrame = playerRevive:FindFirstChild("ReviveFrame")
                    if reviveFrame and reviveFrame.Visible then
                        if GamePlayerRE then
                            GamePlayerRE:FireServer("ExitSettlement")
                        end
                    end
                end
            end
            
            -- Result GUI (Vote Play Again)
            local resultGui = gui:FindFirstChild("ResultGui")
            if resultGui then
                local screenSettlement = resultGui:FindFirstChild("ScreenSettlement")
                if screenSettlement and screenSettlement.Visible then
                    if GameRoundRE then
                        GameRoundRE:FireServer("VotePlayAgain")
                    end
                end
            end
        end)
    end
end)

--================================================
-- [SECTION 12] UTILITY: WALKSPEED MODIFIER
--================================================
task.spawn(function()
    while task.wait(0.5) do
        if not Config.IsRunning then break end
        if Config.ModifyWalkSpeed and Controller then
            pcall(function()
                Controller.SetWalkSpeed = function(self, speed)
                    if self.Humanoid then
                        self.Humanoid.WalkSpeed = Config.WalkSpeed_Speed
                    end
                end
                if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                    player.Character.Humanoid.WalkSpeed = Config.WalkSpeed_Speed
                end
            end)
        end
    end
end)

--================================================
-- [SECTION 13] WIND UI INTERFACE (MIZUKAGE TEAMMIZU)
--================================================
local WindUI
local function InitInterface()
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/1.6.65/main.lua"))()
    end)
    if not success or type(result) ~= "table" then
        success, result = pcall(function()
            return loadstring(game:HttpGet("https://tree-hub.vercel.app/api/UI/WindUI"))()
        end)
        if not success then
            return warn("[MIZUKAGE] UI Failed to load.")
        end
    end
    WindUI = result

    -- LOCALIZATION
    WindUI:Localization({
        Enabled = true,
        Prefix = "loc:",
        DefaultLanguage = "en",
        Translations = {
            ["id"] = {
                ["WELCOME"] = "Selamat Datang di Mizukage TeamMizu!",
                ["MAIN"] = "Autofarm Utama",
                ["POSITION"] = "Engine Posisi",
                ["UTILITY"] = "Utilitas",
                ["SAFETY"] = "Keamanan",
                ["LOADED"] = "Iron Soul Dungeon Edition berhasil dimuat!",
                ["START_FARM"] = "Mulai Farming",
                ["CLOSE"] = "Tutup",
            },
            ["en"] = {
                ["WELCOME"] = "Welcome to Mizukage TeamMizu!",
                ["MAIN"] = "Main Autofarm",
                ["POSITION"] = "Position Engine",
                ["UTILITY"] = "Utility",
                ["SAFETY"] = "Safety",
                ["LOADED"] = "Iron Soul Dungeon Edition loaded successfully!",
                ["START_FARM"] = "Start Farming",
                ["CLOSE"] = "Close",
            },
        }
    })

    -- GRADIENT THEME
    WindUI:Gradient({
        ["0"] = { Color = Color3.fromHex("#5c5291"), Transparency = 0.15 },
        ["50"] = { Color = Color3.fromHex("#0096ff"), Transparency = 0.10 },
        ["100"] = { Color = Color3.fromHex("#18181b"), Transparency = 0 },
    }, {
        Rotation = 45,
    })

    -- CREATE WINDOW
    local viewport = Camera.ViewportSize
    local isMobile = viewport.X < 850
    local dynamicSize = isMobile 
        and UDim2.fromOffset(viewport.X * 0.95, viewport.Y * 0.95) 
        or UDim2.fromOffset(840, 600)

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
        
        User = {
            Enabled = true,
            Anonymous = false,
            Callback = function()
                WindUI:Notify({
                    Title = "👤 Player Info",
                    Content = string.format("Name: %s\nDisplay: %s\nUserID: %s", 
                        player.Name, player.DisplayName, player.UserId),
                    Duration = 5,
                    Icon = "lucide:user",
                })
            end,
        },
    })

    -- TAGS
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

    -- TABS
    local TabMain = Window:Tab({ Title = "loc:MAIN", Icon = "lucide:sword" })
    local TabPos = Window:Tab({ Title = "loc:POSITION", Icon = "lucide:move" })
    local TabSafety = Window:Tab({ Title = "loc:SAFETY", Icon = "lucide:shield" })
    local TabUtility = Window:Tab({ Title = "loc:UTILITY", Icon = "lucide:package" })

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
        Title = "Auto Attack (Kill Aura)",
        Flag = "AutoAttack",
        Default = Config.AutoAttack,
        Callback = function(s) Config.AutoAttack = s; saveSettings() end
    })
    TabMain:Toggle({
        Title = "Auto Use Skill (Q/E/R)",
        Flag = "AutoSkill",
        Default = Config.AutoSkill,
        Callback = function(s) Config.AutoSkill = s; saveSettings() end
    })
    TabMain:Slider({
        Title = "Kill Aura Radius",
        Flag = "KillAuraRadius",
        Step = 5,
        Value = { Min = 15, Max = 100, Default = Config.KillAuraRadius },
        Callback = function(v) Config.KillAuraRadius = v; saveSettings() end
    })

    TabMain:Divider()

    TabMain:Section({ Title = "Auto Chest & Egg" })
    TabMain:Toggle({
        Title = "Auto Collect Chests & Eggs",
        Flag = "AutoCollectChests",
        Default = Config.AutoCollectChests,
        Callback = function(s)
            Config.AutoCollectChests = s
            saveSettings()
            if s then
                WindUI:Notify({
                    Title = "📦 Auto Chest",
                    Content = "✅ Auto Chest & Egg enabled!",
                    Duration = 3,
                    Icon = "lucide:package",
                })
            end
        end
    })

    TabMain:Divider()

    TabMain:Section({ Title = "Play Again" })
    TabMain:Toggle({
        Title = "Auto Play Again (Settlement)",
        Flag = "AutoPlayAgain",
        Default = Config.AutoPlayAgain,
        Callback = function(s)
            Config.AutoPlayAgain = s
            saveSettings()
            if s then
                WindUI:Notify({
                    Title = "🔄 Play Again",
                    Content = "✅ Auto Play Again enabled!",
                    Duration = 3,
                    Icon = "lucide:refresh-cw",
                })
            end
        end
    })

    --================================================
    -- POSITION TAB
    --================================================
    TabPos:Section({ Title = "Orbit Positioning" })
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

    TabPos:Divider()

    TabPos:Section({ Title = "Chest Positioning Offset" })
    TabPos:Slider({
        Title = "Chest Offset X",
        Flag = "ChestOffset_X",
        Step = 1,
        Value = { Min = -20, Max = 20, Default = Config.ChestOffset_X },
        Callback = function(v) Config.ChestOffset_X = v; saveSettings() end
    })
    TabPos:Slider({
        Title = "Chest Offset Y",
        Flag = "ChestOffset_Y",
        Step = 1,
        Value = { Min = -20, Max = 20, Default = Config.ChestOffset_Y },
        Callback = function(v) Config.ChestOffset_Y = v; saveSettings() end
    })
    TabPos:Slider({
        Title = "Chest Offset Z",
        Flag = "ChestOffset_Z",
        Step = 1,
        Value = { Min = -20, Max = 20, Default = Config.ChestOffset_Z },
        Callback = function(v) Config.ChestOffset_Z = v; saveSettings() end
    })
    TabPos:Slider({
        Title = "Chest Pitch",
        Flag = "ChestPitch",
        Step = 1,
        Value = { Min = -180, Max = 180, Default = Config.ChestPitch },
        Callback = function(v) Config.ChestPitch = v; saveSettings() end
    })

    --================================================
    -- SAFETY TAB
    --================================================
    TabSafety:Section({ Title = "Combat Safety" })
    TabSafety:Toggle({
        Title = "Auto Avoid (Red Attacks)",
        Flag = "AutoAvoid",
        Default = Config.AutoAvoid,
        Callback = function(s)
            Config.AutoAvoid = s
            saveSettings()
            if s then
                WindUI:Notify({
                    Title = "🛡️ Auto Avoid",
                    Content = "✅ Auto Avoid enabled!",
                    Duration = 3,
                    Icon = "lucide:shield",
                })
            end
        end
    })
    TabSafety:Toggle({
        Title = "Safe Mode (Extra Distance)",
        Flag = "SafeMode",
        Default = Config.SafeMode,
        Callback = function(s) Config.SafeMode = s; saveSettings() end
    })
    TabSafety:Toggle({
        Title = "Emergency Escape",
        Flag = "EmergencyEscape",
        Default = Config.EmergencyEscape,
        Callback = function(s) Config.EmergencyEscape = s; saveSettings() end
    })

    TabSafety:Divider()

    TabSafety:Section({ Title = "Stage Progress" })
    TabSafety:Toggle({
        Title = "Auto Progress Stage (Portal & Door)",
        Flag = "AutoProgressStage",
        Default = Config.AutoProgressStage,
        Callback = function(s) Config.AutoProgressStage = s; saveSettings() end
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
            if not s and OldWalkSpeed then
                Controller.SetWalkSpeed = OldWalkSpeed
            end
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

    TabUtility:Section({ Title = "Performance" })
    TabUtility:Toggle({
        Title = "Performance Mode",
        Flag = "PerformanceMode",
        Default = Config.PerformanceMode,
        Callback = function(s) Config.PerformanceMode = s; saveSettings() end
    })
    TabUtility:Toggle({
        Title = "Debug Monitor",
        Flag = "Debug",
        Default = Config.Debug,
        Callback = function(s) Config.Debug = s; saveSettings() end
    })

    TabUtility:Divider()

    TabUtility:Section({ Title = "Config Management" })
    TabUtility:Button({
        Title = "Save Settings",
        Variant = "Primary",
        Icon = "lucide:save",
        Callback = function()
            saveSettings()
            WindUI:Notify({
                Title = "💾 Config",
                Content = "Settings saved successfully!",
                Duration = 3,
                Icon = "lucide:check",
            })
        end
    })
    TabUtility:Button({
        Title = "Load Settings",
        Variant = "Secondary",
        Icon = "lucide:folder-open",
        Callback = function()
            loadSettings()
            WindUI:Notify({
                Title = "📂 Config",
                Content = "Settings loaded successfully!",
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
                            getgenv().MizukageEngine = false
                            Window:Destroy()
                        end,
                        Variant = "Destructive",
                    },
                },
            })
        end
    })

    --================================================
    -- WELCOME POPUP
    --================================================
    task.wait(0.5)
    WindUI:Popup({
        Title = "loc:WELCOME",
        Icon = "lucide:crown",
        Content = "loc:LOADED\n\n👑 Created by: Kazukage\n⚔️ Game: Iron Soul Dungeon\n📦 Version: 3.0.0\n👥 Team: TeamMizu\n\nNew Features:\n📦 Auto Chest & Egg\n🔄 Auto Play Again\n\nThank you for using our script!",
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
end

task.spawn(InitInterface)

--================================================
-- [SECTION 14] MAIN HEARTBEAT LOOP
--================================================
connect(RunService.Heartbeat, function(dt)
    if State.Unloaded then return end
    State.Stats.Heartbeats += 1
    State.StatusTimer += dt
    
    if not Config.AutoFarm then
        State.WatchdogTimer = 0
        State.StageBusyTimer = 0
        State.CurrentAction = "Idle"
        return
    end
    
    if not State.Character or not State.Root or not State.Humanoid or State.Humanoid.Health <= 0 then
        return
    end
    
    -- Skip combat if collecting chests/eggs
    if State.CollectingChests or State.CollectingEggs then
        State.CurrentAction = State.CollectingEggs and "Collecting Egg" or "Collecting Chest"
        return
    end
    
    -- Watchdog
    State.WatchdogTimer += dt
    if State.StageBusy then
        State.StageBusyTimer += dt
        if State.StageBusyTimer >= 6 then
            State.StageBusy = false
            State.DoorBusy = false
            State.StageBusyTimer = 0
            State.RoomClearTimer = 0
            State.CurrentAction = "Recovering"
        end
    else
        State.StageBusyTimer = 0
    end
    
    if State.WatchdogTimer >= 2 then
        State.WatchdogTimer = 0
        if Config.AutoProgressStage and not State.StageBusy then
            rebuildPortalCandidates()
        end
    end
    
    if not State.TargetRoot or not targetIsValid() then
        State.RoomClearTimer += dt
    end
    
    if State.FallbackTargetTimer > 0 then
        State.FallbackTargetTimer = math.max(0, State.FallbackTargetTimer - dt)
    end
    
    -- Target refresh
    State.TargetTimer += dt
    local targetInterval = Config.PerformanceMode
        and math.max(Config.TargetRefresh, 0.25)
        or math.min(Config.TargetRefresh, 0.50)
    if State.TargetTimer >= targetInterval then
        State.TargetTimer = 0
        refreshTarget()
    end
    
    -- Portal progress
    State.PortalTimer += dt
    local portalInterval = Config.PerformanceMode and 1.5 or 1.0
    if State.PortalTimer >= portalInterval then
        State.PortalTimer = 0
        if Config.AutoProgressStage and not State.StageBusy then
            task.spawn(function()
                local ok, err = pcall(moveToNextStage)
                if not ok then
                    State.StageBusy = false
                    State.DoorBusy = false
                    State.RoomClearTimer = 0
                    State.CurrentAction = "Recovering"
                    if Config.Debug then
                        warn("[Mizukage] stage error:", err)
                    end
                end
            end)
        end
    end
    
    -- Combat execution
    if State.EmergencyBusy then
        State.CurrentAction = "Emergency Escape"
    elseif Config.AutoAvoid and State.DangerPart then
        updateAutoAvoid(dt)
    elseif Config.AutoProgressStage and State.StageBusy then
        if State.CurrentAction == "Farming" then
            State.CurrentAction = "Portal"
        end
    else
        lockCombatPosition()
        State.AttackTimer += dt
        if State.AttackTimer >= 0.10 then
            State.AttackTimer = 0
            updateKillAura()
        end
        State.CurrentAction = "Farming"
    end
    
    -- Auto Skill
    State.SkillTimer += dt
    if State.SkillTimer >= 2.50 then
        State.SkillTimer = 0
        if Config.AutoSkill and targetIsValid() then
            task.spawn(useSkills)
        end
    end
end)

--================================================
-- [SECTION 15] UNLOAD
--================================================
local function unload()
    if State.Unloaded then return end
    State.Unloaded = true
    Config.AutoFarm = false
    Config.IsRunning = false
    _G.MizukageAutoFarm = false
    disconnectList(CharacterConnections)
    disconnectList(Connections)
    getgenv().MizukageEngine = false
    debugPrint("Unloaded")
end

_G.MizukageUnload = unload

print("[Mizukage] Mizukage Official - Iron Soul Dungeon Edition v3.0.0 loaded")