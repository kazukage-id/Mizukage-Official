--[[
    ========================================================================
      Mizukage Official — Illegal Soccer
      Satu file lengkap: UI WindUI (sama seperti skrip lain) + semua logic.
      Tanpa backend / key-system / file eksternal (hanya WindUI yang diunduh).

      Toggle UI : RightShift
      Keybind   : G = Rainbow | F = Fly | V = Speed | R = Resync
      Isi TARGET_PLACE_ID bila ingin membatasi ke satu Place ID (0 = tidak dicek).
    ========================================================================
]]

local GAME_NAME       = "Illegal Soccer"
local TARGET_PLACE_ID = 0

local env = (getgenv and getgenv()) or _G

-- ═══════════════════════════════════════════════════════════
-- [1] PLACE ID + ANTI DUPLIKASI
-- ═══════════════════════════════════════════════════════════
if not game:IsLoaded() then game.Loaded:Wait() end

if TARGET_PLACE_ID ~= 0 and game.PlaceId ~= TARGET_PLACE_ID then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Mizukage Official",
            Text  = "Script ini hanya untuk " .. GAME_NAME .. ".",
        })
    end)
    return warn("[Mizukage Official] PlaceId " .. tostring(game.PlaceId) .. " bukan " .. GAME_NAME .. ".")
end

if env.MizukageOfficial then
    return game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Mizukage Official",
        Text  = "UI sudah berjalan.",
    })
end
env.MizukageOfficial = true

-- ═══════════════════════════════════════════════════════════
-- [2] SERVICES
-- ═══════════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.05)
    LocalPlayer = Players.LocalPlayer
end
local Camera = Workspace.CurrentCamera

local BRAND   = "Mizukage Official"
local VERSION = "v1.0.0"
local FOLDER  = "MizukageOfficial_IllegalSoccer"

-- ═══════════════════════════════════════════════════════════
-- [3] WINDUI
-- ═══════════════════════════════════════════════════════════
local WindUI
do
    local sources = {
        "https://github.com/Footagesus/WindUI/releases/download/1.6.65/main.lua",
        "https://tree-hub.vercel.app/api/UI/WindUI",
    }
    for _, url in ipairs(sources) do
        local ok, result = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)
        if ok and type(result) == "table" then
            WindUI = result
            break
        end
    end
    if not WindUI then
        env.MizukageOfficial = nil
        return warn("[Mizukage Official] WindUI gagal dimuat.")
    end
end

local function SafeNotify(title, content, duration, icon)
    pcall(function()
        WindUI:Notify({
            Title    = title,
            Content  = content,
            Duration = duration or 3,
            Icon     = icon or "lucide:info",
        })
    end)
end

-- ═══════════════════════════════════════════════════════════
-- [4] CONFIG (semua toggle & parameter)
-- ═══════════════════════════════════════════════════════════
local CONFIG = {
    SilentAim = {
        Enabled      = true,
        TargetCorner = "Top Right Corner", -- Top Right/Left Corner | Bottom Right/Left Corner | Center Net | Random Corner
        CornerSpread = 15.5,
        TopHeight    = 4.2,
        BottomHeight = -3,
        HeightOffset = 1.5,
    },

    Rainbow = {
        Enabled        = true,
        AutoPossession = false,
        TargetMode     = "Camera Reticle", -- "Opponent Goal" | "Camera Reticle"
        DetachDelay    = 0.4,
        JumpDelay      = 0.52,
        ChargeDuration = 0.38,
        PlayAnimations = true,
        Keybind        = Enum.KeyCode.G,
    },

    Goalkeeper = {
        Enabled             = true,
        RequireRole         = true,
        SilentAim           = true,
        AutoDive            = true,
        AutoPunch           = true,
        AutoJump            = true,
        AutoPosition        = true,
        RemotePrediction    = true,
        PreAimPrediction    = true,
        PhysicsPrediction   = true,
        MaxDiveReach        = 16.5,
        DiveDistance        = 45,
        PunchDistance       = 8.5,
        CenterTolerance     = 1.8,
        JumpHeightThreshold = 2,
        ReactionDelayMs     = 0,
    },

    Fly = {
        Enabled    = false,
        AirDribble = true,
        Speed      = 55,
        Keybind    = Enum.KeyCode.F,
    },

    Movement = {
        InfiniteStamina = true,
        SpeedEnabled    = false,
        SpeedMultiplier = 1.2,
        AntiRubberband  = true,
        InfiniteJump    = false,
        ResyncKeybind   = Enum.KeyCode.R,
        SpeedKeybind    = Enum.KeyCode.V,
    },

    Visuals = {
        BallESP            = true,
        BallESPColor       = Color3.fromRGB(255, 215, 0),
        BallHighlight      = true,
        BallHighlightColor = Color3.fromRGB(0, 255, 170),
        PlayerESP          = false,
        PlayerESPTeamColor = true,
        EnemyColor         = Color3.fromRGB(255, 60, 60),
        AllyColor          = Color3.fromRGB(60, 180, 255),
        Fullbright         = false,
    },
}

-- Simpan / muat (hanya boolean, number, string)
local SETTINGS_FILE = FOLDER .. "_Settings.json"

local function flatten(src, dst)
    for k, v in pairs(src) do
        local tv = type(v)
        if tv == "table" then
            dst[k] = {}
            flatten(v, dst[k])
        elseif tv == "boolean" or tv == "number" or tv == "string" then
            dst[k] = v
        end
    end
end

local function applySaved(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) == "table" then applySaved(dst[k], v) end
        elseif type(dst[k]) == type(v) then
            dst[k] = v
        end
    end
end

local function saveSettings()
    if type(writefile) ~= "function" then return end
    pcall(function()
        local data = {}
        flatten(CONFIG, data)
        writefile(SETTINGS_FILE, HttpService:JSONEncode(data))
    end)
end

pcall(function()
    if type(isfile) == "function" and type(readfile) == "function" and isfile(SETTINGS_FILE) then
        applySaved(CONFIG, HttpService:JSONDecode(readfile(SETTINGS_FILE)))
    end
end)
CONFIG.Fly.Enabled = false
CONFIG.Movement.SpeedEnabled = false

-- Resource tracker untuk unload
local Cleanup = {}
local function track(v)
    table.insert(Cleanup, v)
    return v
end

-- ═══════════════════════════════════════════════════════════
-- [5] MODULES (cache module internal game)
-- ═══════════════════════════════════════════════════════════
local Mods = {}
local R = ReplicatedStorage

local function resolvePath(path)
    local cur = R
    for segment in string.gmatch(path, "[^%.]+") do
        cur = cur and cur:FindFirstChild(segment)
    end
    return cur
end

local function safeRequire(name, path)
    local inst = resolvePath(path)
    if not inst then return nil end
    local ok, res = pcall(require, inst)
    if ok then Mods[name] = res end
    return ok and res or nil
end

for _, entry in ipairs({
    { "Sprint",               "Modules.Actions.Sprint" },
    { "ActionMovement",       "Modules.Actions.ActionMovement" },
    { "SlideTackle",          "Modules.Actions.SlideTackle" },
    { "BallRenderer",         "Client.Gameplay.Ball.Renderer" },
    { "VolleyLockOn",         "Modules.Ball.VolleyLockOn" },
    { "BallPhysics",          "Modules.Ball.Physics" },
    { "Reticle",              "Client.Interface.Reticle" },
    { "PracticeSession",      "Client.Gameplay.PracticeSession" },
    { "TutorialSession",      "Client.Gameplay.TutorialSession" },
    { "MatchSettings",        "Modules.Gameplay.MatchSettings" },
    { "ActorTeams",           "Client.Gameplay.ActorTeams" },
    { "ActionRemoteProtocol", "Modules.Actions.ActionRemoteProtocol" },
    { "ActionCommands",       "Modules.Actions.ActionCommands" },
    { "ActionLocks",          "Modules.Actions.ActionLocks" },
    { "AimFacing",            "Modules.Actions.AimFacing" },
    { "GoalkeeperDive",       "Modules.Actions.GoalkeeperDive" },
    { "GKPresentation",       "Client.Gameplay.Actions.GoalkeeperDivePresentation" },
    { "GKRole",               "Client.Gameplay.Player.GoalkeeperRole" },
    { "AnimPreloader",        "Client.Gameplay.Player.AnimationPreloader" },
    { "Movement",             "Client.Gameplay.Player.Movement" },
    { "Sounds",               "Client.Gameplay.Sounds" },
    { "MotionSmoothing",      "Client.Player.CharacterMotionSmoothing" },
    { "RainbowFlick",         "Modules.Actions.RainbowFlick" },
    { "BicycleKick",          "Modules.Actions.BicycleKick" },
    { "TackleEffects",        "Client.Gameplay.Actions.TackleEffects" },
    { "KickAnimations",       "Client.Gameplay.Actions.KickAnimations" },
    { "BallCarry",            "Modules.Ball.Carry" },
    { "Shoot",                "Client.Gameplay.Actions.Shoot" },
    { "Pass",                 "Client.Gameplay.Actions.Pass" },
    { "ItemUseState",         "Client.Gameplay.ItemUseState" },
    { "Controls",             "Modules.Gameplay.Controls" },
}) do
    safeRequire(entry[1], entry[2])
end

local BallRemotes = {}
do
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local ball    = remotes and remotes:FindFirstChild("Ball")
    if ball then
        BallRemotes.State                    = ball:FindFirstChild("State")
        BallRemotes.MovementUpdate           = ball:FindFirstChild("MovementUpdate")
        BallRemotes.ActionPresentationUpdate = ball:FindFirstChild("ActionPresentationUpdate")
        BallRemotes.GoalAnnouncement         = ball:FindFirstChild("GoalAnnouncement")
        BallRemotes.Kick                     = ball:FindFirstChild("Kick")
    end
end

local moduleCount = 0
for _ in pairs(Mods) do moduleCount += 1 end
local gameDetected = Mods.BallRenderer ~= nil and Mods.Reticle ~= nil

-- ═══════════════════════════════════════════════════════════
-- [6] STATE
-- ═══════════════════════════════════════════════════════════
local State = {
    IsGoalkeeper           = false,
    DefendingGoal          = nil,
    GoalFacingNormal       = Vector3.new(-1, 0, 0),
    ActiveThreat           = nil,
    LastThreatInterceptPos = nil,
    BallPosition           = Vector3.zero,
    BallVelocity           = Vector3.zero,
    DistanceToBall         = 999,
    LastDiveTime           = 0,
    LastPunchTime          = 0,
    IsDiving               = false,
    IsPunching             = false,
    StatusText             = "INIT",
    GoalTimer              = 0,
    Unloaded               = false,
}

local RainbowState = { IsExecuting = false, LastExecutionTime = 0 }

-- ═══════════════════════════════════════════════════════════
-- [7] HELPERS
-- ═══════════════════════════════════════════════════════════
local function getRoot()
    local ch = LocalPlayer.Character
    return ch and ch:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local ch = LocalPlayer.Character
    return ch and ch:FindFirstChildOfClass("Humanoid")
end

local function hasPossession()
    local M = Mods.BallRenderer
    if M and M.GetMovementState then
        local st = M.GetMovementState()
        if st and st.CarrierUserId == LocalPlayer.UserId then return true end
    end
    if M and M.GetMainMatchOwnerUserId then
        if M.GetMainMatchOwnerUserId() == LocalPlayer.UserId then return true end
    end
    if M and M.IsBoundBallOwnedBy and M.IsBoundBallOwnedBy(LocalPlayer.UserId) then
        return true
    end
    local ch = LocalPlayer.Character
    if ch and ch:GetAttribute("GoalkeeperCarryBallHigh") == true then return true end
    return false
end

-- Prioritas: match ball -> practice ball -> visual child -> fallback
local function findBall()
    local M = Mods.BallRenderer
    if M and M.GetMatchBallId and M.GetBall then
        local id = M.GetMatchBallId()
        if id then
            local b = M.GetBall(id)
            if b and b.Parent then return b end
        end
    end
    local PS = Mods.PracticeSession
    if PS and PS.GetLocalPracticeBallId then
        local id = PS.GetLocalPracticeBallId()
        if id then
            local misc = Workspace:FindFirstChild("Misc")
            local vis  = misc and misc:FindFirstChild("Visuals")
            local b = vis and vis:FindFirstChild("ClientBall_" .. tostring(id))
            if b then return b end
        end
    end
    local misc = Workspace:FindFirstChild("Misc")
    local vis  = misc and misc:FindFirstChild("Visuals")
    if vis then
        local b = vis:FindFirstChild("ClientBall_MainMatch")
        if b then return b end
        for _, v in pairs(vis:GetChildren()) do
            if v:IsA("BasePart") and v.Name:find("ClientBall_") then return v end
        end
    end
    return nil
end

-- Urutan: PracticeSession -> Lobby.Practice.Goals.Defence -> Map.Data[team].Goal -> terdekat
local function getDefendedGoal()
    local root = getRoot()
    if not root then return nil, Vector3.new(-1, 0, 0) end
    local pos = root.Position
    local PS  = Mods.PracticeSession

    if PS and PS.GetDefendedGoalPart then
        local g = PS.GetDefendedGoalPart()
        if g then return g, Vector3.new(-1, 0, 0) end
    end

    local lobby    = Workspace:FindFirstChild("Lobby")
    local practice = lobby and lobby:FindFirstChild("Practice")
    local goals    = practice and practice:FindFirstChild("Goals")
    if goals then
        local d = goals:FindFirstChild("Defence")
        local g = d and d:FindFirstChild("Goal")
        if g then return g, Vector3.new(-1, 0, 0) end
    end

    local map  = Workspace:FindFirstChild("Map")
    local data = map and map:FindFirstChild("Data")
    if data then
        local teamName
        local AT = Mods.ActorTeams
        if AT and AT.GetActorTeamName then
            pcall(function() teamName = AT.GetActorTeamName(LocalPlayer) end)
        end
        if teamName then
            local t = data:FindFirstChild(teamName)
            local g = t and t:FindFirstChild("Goal")
            if g then
                local diff = Vector3.new(0, g.Position.Y, 0) - g.Position
                return g, Vector3.new(diff.X, 0, diff.Z).Unit
            end
        end
    end

    local best, bestDist = nil, math.huge
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name == "Goal" and v.Size.X > 10 then
            local d = (v.Position - pos).Magnitude
            if d < bestDist then best = v; bestDist = d end
        end
    end
    if best then
        local diff = pos - best.Position
        local u = diff.Magnitude > 0.1 and Vector3.new(diff.X, 0, diff.Z).Unit or Vector3.new(-1, 0, 0)
        return best, u
    end
    return nil, Vector3.new(-1, 0, 0)
end

local function isGoalkeeper()
    if not CONFIG.Goalkeeper.RequireRole then return true end
    local ch = LocalPlayer.Character
    if not ch then return false end
    local GK = Mods.GKRole
    if GK and GK.IsGoalkeeper and GK.IsGoalkeeper() then return true end
    if ch:GetAttribute("ActiveGoalkeeper") == true then return true end
    local MS = Mods.MatchSettings
    if MS and MS.Constants and ch:GetAttribute(MS.Constants.GoalkeeperRoleAttributeName) == true then
        return true
    end
    if MS and MS.IsGoalkeeperCharacter and MS.IsGoalkeeperCharacter(ch) then return true end
    local g = State.DefendingGoal or getDefendedGoal()
    local root = ch:FindFirstChild("HumanoidRootPart")
    if g and root and (g.Position - root.Position).Magnitude < 55 then return true end
    return false
end

-- ═══════════════════════════════════════════════════════════
-- [8] ANTI-RUBBERBAND
-- Hook handler Ball.State agar server tidak mengembalikan posisi.
-- ═══════════════════════════════════════════════════════════
local antiHooks = {}
do
    local Mod = Mods.Movement
    local hooked = {}

    local function hookAnti()
        if not BallRemotes.State then return end
        if type(getconnections) ~= "function" or type(hookfunction) ~= "function" then return end

        for _, conn in ipairs(getconnections(BallRemotes.State.OnClientEvent)) do
            local fn = conn.Function
            if type(fn) == "function" and not hooked[fn] then
                hooked[fn] = true
                local old
                local ok, result = pcall(function()
                    return hookfunction(fn, function(p33, p34, p35, p36, p37, p38, p39)
                        if not State.Unloaded and CONFIG.Movement.AntiRubberband and p39 == true then
                            pcall(function()
                                if Mod and Mod.Get then
                                    local c = Mod.Get("CharacterTeleportClient")
                                    if c then
                                        if c.TeleportEpoch ~= p33 then
                                            c.TeleportEpoch = p33
                                            c.ReceivedPlacementRevision = p34
                                            c.AppliedPlacementRevision  = p34
                                            c.PendingPlacement          = nil
                                            c.ScheduledPlacementRevision= nil
                                        else
                                            c.ReceivedPlacementRevision = math.max(c.ReceivedPlacementRevision or 0, p34)
                                            c.AppliedPlacementRevision  = math.max(c.AppliedPlacementRevision or 0, p34)
                                            c.PendingPlacement          = nil
                                        end
                                    end
                                end
                            end)
                            return -- koreksi server dibatalkan
                        end
                        return old(p33, p34, p35, p36, p37, p38, p39)
                    end)
                end)
                if ok and type(result) == "function" then
                    old = result
                    table.insert(antiHooks, fn)
                end
            end
        end
    end

    pcall(hookAnti)
end

-- ═══════════════════════════════════════════════════════════
-- [9] SILENT AIM
-- Override Reticle.GetCameraRay / GetCameraAimRay / ...WithoutHit.
-- Prioritas: GK silent aim > silent aim gawang > original.
-- ═══════════════════════════════════════════════════════════
local function goalTargetPosition(goalPart)
    local pos   = goalPart.Position
    local right = goalPart.CFrame.RightVector
    local up    = goalPart.CFrame.UpVector

    local root   = getRoot()
    local origin = root and root.Position or (Camera and Camera.CFrame.Position) or pos
    local dir    = (pos - origin)
    local unit   = dir.Magnitude > 0.01 and dir.Unit or Vector3.new(0, 0, -1)
    local cross  = unit:Cross(Vector3.new(0, 1, 0))
    local camRight  = Camera and Camera.CFrame.RightVector or Vector3.new(1, 0, 0)
    local rightUnit = cross.Magnitude > 0.01 and cross.Unit or camRight
    local r = (right:Dot(rightUnit) >= 0) and right or -right

    local c = CONFIG.SilentAim
    if c.TargetCorner == "Top Right Corner" then
        return pos + r * c.CornerSpread + up * c.TopHeight
    elseif c.TargetCorner == "Top Left Corner" then
        return pos - r * c.CornerSpread + up * c.TopHeight
    elseif c.TargetCorner == "Bottom Right Corner" then
        return pos + r * c.CornerSpread + up * c.BottomHeight
    elseif c.TargetCorner == "Bottom Left Corner" then
        return pos - r * c.CornerSpread + up * c.BottomHeight
    elseif c.TargetCorner == "Random Corner" then
        local corners = {
            pos + r * c.CornerSpread + up * c.TopHeight,
            pos - r * c.CornerSpread + up * c.TopHeight,
            pos + r * c.CornerSpread + up * c.BottomHeight,
            pos - r * c.CornerSpread + up * c.BottomHeight,
        }
        return corners[math.random(1, #corners)]
    else
        return pos + up * c.HeightOffset
    end
end

local function findOpponentGoal()
    local root = getRoot()
    if not root then return nil, "No Root" end
    local pos  = root.Position
    local look = Camera and Camera.CFrame.LookVector or Vector3.new(0, 0, -1)

    local PS = Mods.PracticeSession
    if PS and PS.GetGoalParts then
        local ok, parts = pcall(PS.GetGoalParts)
        if ok and parts and #parts > 0 then
            local best, bestScore = nil, math.huge
            for _, p in pairs(parts) do
                local d = p.Position - pos
                local score = d.Magnitude - (d.Unit:Dot(look)) * 35
                if score < bestScore then best = p; bestScore = score end
            end
            if best then return best, "Practice Goal" end
        end
    end

    local map  = Workspace:FindFirstChild("Map")
    local data = map and map:FindFirstChild("Data")
    if data then
        local teamName
        local AT = Mods.ActorTeams
        if AT and AT.GetActorTeamName then
            pcall(function() teamName = AT.GetActorTeamName(LocalPlayer) end)
        end
        local MS = Mods.MatchSettings
        if MS and MS.GetOpposingTeamName and teamName then
            local opp = MS.GetOpposingTeamName(teamName)
            local t = data:FindFirstChild(opp)
            local g = t and t:FindFirstChild("Goal")
            if g then return g, "Opp: " .. opp end
        end
    end
    return nil, "No Opp Goal"
end

local origCameraRay, origCameraAimRay, origCameraAimRayNoHit
do
    local Reticle = Mods.Reticle
    if Reticle then
        origCameraRay         = Reticle.GetCameraRay
        origCameraAimRay      = Reticle.GetCameraAimRay
        origCameraAimRayNoHit = Reticle.GetCameraAimRayWithoutHit

        if origCameraRay then
            function Reticle.GetCameraRay(...)
                if not State.Unloaded then
                    if CONFIG.Goalkeeper.Enabled and CONFIG.Goalkeeper.SilentAim and State.IsGoalkeeper then
                        local pos = State.LastThreatInterceptPos or State.BallPosition
                        if pos and Camera then
                            return Ray.new(Camera.CFrame.Position, (pos - Camera.CFrame.Position).Unit * 1000)
                        end
                    end
                    if CONFIG.SilentAim.Enabled then
                        local g = findOpponentGoal()
                        if g and Camera then
                            local tp = goalTargetPosition(g)
                            return Ray.new(Camera.CFrame.Position, (tp - Camera.CFrame.Position).Unit * 1000)
                        end
                    end
                end
                return origCameraRay(...)
            end
        end

        if origCameraAimRay then
            function Reticle.GetCameraAimRay(...)
                if not State.Unloaded then
                    if CONFIG.Goalkeeper.Enabled and CONFIG.Goalkeeper.SilentAim and State.IsGoalkeeper then
                        local pos = State.LastThreatInterceptPos or State.BallPosition
                        if pos then
                            local cf = Camera and Camera.CFrame or CFrame.new()
                            return {
                                Origin = cf.Position,
                                Direction = (pos - cf.Position).Unit,
                                CameraCFrame = cf,
                                ClientHit = { Position = pos, Kind = "Ball" },
                                TargetPosition = pos,
                                IsAirborne = false,
                            }
                        end
                    end
                    if CONFIG.SilentAim.Enabled then
                        local g = findOpponentGoal()
                        if g then
                            local tp = goalTargetPosition(g)
                            local cf = Camera and Camera.CFrame or CFrame.new()
                            return {
                                Origin = cf.Position,
                                Direction = (tp - cf.Position).Unit,
                                CameraCFrame = cf,
                                ClientHit = { Position = tp, Kind = "Goal" },
                                TargetPosition = tp,
                                IsAirborne = false,
                            }
                        end
                    end
                end
                return origCameraAimRay(...)
            end
        end

        if origCameraAimRayNoHit then
            function Reticle.GetCameraAimRayWithoutHit(...)
                if not State.Unloaded and CONFIG.SilentAim.Enabled then
                    local g = findOpponentGoal()
                    if g then
                        local tp = goalTargetPosition(g)
                        local cf = Camera and Camera.CFrame or CFrame.new()
                        return {
                            Origin = cf.Position,
                            Direction = (tp - cf.Position).Unit,
                            CameraCFrame = cf,
                            TargetPosition = tp,
                        }
                    end
                end
                return origCameraAimRayNoHit(...)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
-- [10] AUTO GOALKEEPER
-- ═══════════════════════════════════════════════════════════
-- Proyeksi lintasan bola ke bidang gawang (gravitasi -28 studs/s^2)
local function solveIntercept(origin, velocity, goalPos, goalNormal)
    if not origin or not velocity or not goalPos or not goalNormal then return nil end
    local a = velocity:Dot(goalNormal)
    if a <= 0.5 then return nil end
    local t = (goalPos - origin):Dot(goalNormal) / a
    if t <= 0 or t > 3.5 then return nil end
    return origin + velocity * t + 0.5 * Vector3.new(0, -28, 0) * t * t, t
end

local function executePunch(targetPos)
    if not CONFIG.Goalkeeper.AutoPunch then return false end
    if State.IsPunching or State.IsDiving or hasPossession() then return false end
    local now = os.clock()
    if now - State.LastPunchTime < 0.65 then return false end

    local ch   = LocalPlayer.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    local hum  = ch and ch:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return false end

    State.IsPunching    = true
    State.LastPunchTime = now

    local cf  = Camera and Camera.CFrame or root.CFrame
    local bp  = targetPos or State.BallPosition
    local dir = (bp - cf.Position).Unit

    local AF   = Mods.AimFacing
    local flat = AF and AF.GetFlatDirection and AF.GetFlatDirection(dir) or Vector3.new(dir.X, 0, dir.Z).Unit

    local aim = {
        Origin = cf.Position,
        Direction = dir,
        CameraCFrame = cf,
        TargetPosition = bp,
        ClientHit = { Position = bp, Kind = "Ball" },
        IsAirborne = false,
    }

    local AC = Mods.ActionCommands
    local cmd
    if AC and AC.Kick then
        cmd = AC.Kick({
            AimDirection = aim,
            KickDirection = flat,
            ChargeSeconds = 0.05,
            MaximumChargeSeconds = 0.5,
            PassType = "Shot",
            UseClientPosition = true,
            ShotTime = Workspace:GetServerTimeNow(),
        })
    end

    task.spawn(function()
        local ARP = Mods.ActionRemoteProtocol
        if ARP and cmd then
            pcall(function() ARP.Start(cmd) end)
            task.wait(0.02)
            cmd.AimDirection = aim
            pcall(function() ARP.Update(cmd) end)
            task.wait(0.02)
            pcall(function() ARP.Release(cmd) end)
        end
        pcall(function()
            if Mods.AnimPreloader and Mods.AnimPreloader.Play then
                Mods.AnimPreloader.Play(ch, "GoalkeeperPunch", 0.05)
            end
            if Mods.Sounds and Mods.Sounds.PlayBallReceive then
                Mods.Sounds.PlayBallReceive(ch)
            end
        end)
        State.IsPunching = false
    end)
    return true
end

local function executeDive(targetPos, isHigh, velocity, sourcePos)
    if not CONFIG.Goalkeeper.AutoDive then return false end
    if hasPossession() or State.IsDiving then return false end
    local GD = Mods.GoalkeeperDive
    local repeatDelay = GD and GD.Constants and GD.Constants.RepeatDelaySeconds or 1.65
    if os.clock() - State.LastDiveTime < repeatDelay then return false end

    local ch   = LocalPlayer.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    local hum  = ch and ch:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return false end

    State.IsDiving     = true
    State.LastDiveTime = os.clock()

    local cf  = Camera and Camera.CFrame or root.CFrame
    local off = targetPos - root.Position
    local flatOff  = Vector3.new(off.X, 0, off.Z)
    local rightDot = flatOff:Dot(cf.RightVector)
    local lookDot  = flatOff:Dot(cf.LookVector)
    local yDiff    = targetPos.Y - root.Position.Y

    local centerTol  = CONFIG.Goalkeeper.CenterTolerance
    local jumpThr    = CONFIG.Goalkeeper.JumpHeightThreshold
    local isHighShot = isHigh or yDiff > jumpThr

    -- Bola tengah
    if math.abs(rightDot) <= centerTol then
        if isHighShot and CONFIG.Goalkeeper.AutoJump then
            State.StatusText = "HIGH JUMP SAVE"
            hum.Jump = true
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            pcall(function()
                root:ApplyImpulse(Vector3.new(0, root.AssemblyMass * 46, 0))
            end)
            task.delay(0.14, function() executePunch(targetPos) end)
            task.delay(0.45, function() State.IsDiving = false end)
            return true
        else
            State.StatusText = "PUNCH SAVE"
            local GDMod   = Mods.GoalkeeperDive
            local dirName = GDMod and GDMod.GetDirectionChoiceByName and GDMod.GetDirectionChoiceByName("F") or "F"
            pcall(function()
                if GDMod and GDMod.Run then
                    GDMod.Run(root, hum, dirName, function() return cf end, {
                        Assist = {
                            ExtraDistance = math.clamp(math.max(lookDot, 2), 2.2, 4.5) - 20,
                            TravelScale = 1,
                            InitialVerticalVelocity = 8,
                        }
                    })
                end
            end)
            task.delay(0.12, function() executePunch(targetPos) end)
            task.delay(0.4, function() State.IsDiving = false end)
            return true
        end
    end

    -- Bola samping
    local dirName = rightDot < 0 and "L" or "R"
    if lookDot > 3 and math.abs(rightDot) > 3 then
        dirName = dirName .. "F"
    end

    local reach = math.clamp(math.abs(rightDot) + 0.5, 2.2, 18.5)
    local extra = reach - 20
    local vert  = isHighShot and 26 or 12
    State.StatusText = string.format("%s [%s] (%.1f)",
        isHighShot and "HIGH DIVE" or "DIVE", dirName, reach)

    task.spawn(function()
        pcall(function()
            if Mods.GKPresentation and Mods.GKPresentation.Play then
                Mods.GKPresentation.Play(ch, dirName, 0.1)
            end
            if Mods.Sounds and Mods.Sounds.PlayGoalkeeperDive then
                Mods.Sounds.PlayGoalkeeperDive(ch)
            end
        end)
        local GDMod = Mods.GoalkeeperDive
        if GDMod and GDMod.Run then
            pcall(function()
                GDMod.Run(root, hum, dirName, function()
                    return Camera and Camera.CFrame or root.CFrame
                end, {
                    Assist = {
                        ExtraDistance = extra,
                        TravelScale = 1,
                        InitialVerticalVelocity = vert,
                    }
                })
            end)
        end
        task.delay(0.12, function() executePunch(targetPos) end)
        task.delay(0.4, function() State.IsDiving = false end)
    end)
    return true
end

local function tryGoalkeeperSave(interceptPos, isHigh, velocity, sourcePos)
    if not CONFIG.Goalkeeper.Enabled or hasPossession() then return end
    if not isGoalkeeper() then return end
    if not interceptPos then return end

    State.LastThreatInterceptPos = interceptPos
    State.ActiveThreat = {
        targetPos = interceptPos,
        isHigh    = isHigh,
        shotTime  = os.clock(),
        velocity  = velocity,
        position  = sourcePos,
    }

    local root = getRoot()
    if not root then return end

    local cf = Camera and Camera.CFrame or root.CFrame
    local off = interceptPos - root.Position
    local rightDot = Vector3.new(off.X, 0, off.Z):Dot(cf.RightVector)
    if math.abs(rightDot) > CONFIG.Goalkeeper.MaxDiveReach then return end

    local reaction = CONFIG.Goalkeeper.ReactionDelayMs
    if reaction <= 0 then
        executeDive(interceptPos, isHigh, velocity, sourcePos)
        State.ActiveThreat = nil
    else
        task.delay(reaction / 1000, function()
            executeDive(interceptPos, isHigh, velocity, sourcePos)
            State.ActiveThreat = nil
        end)
    end
end

local function hookBallEvents()
    -- Ball.State: deteksi tendangan instan
    if BallRemotes.State then
        track(BallRemotes.State.OnClientEvent:Connect(function(data)
            if not CONFIG.Goalkeeper.Enabled or not CONFIG.Goalkeeper.RemotePrediction then return end
            if hasPossession() or not isGoalkeeper() then return end
            if type(data) ~= "table" then return end
            if data.Kind == "Movement" and data.Mode == "Airborne" then
                if data.LastKickerUserId == LocalPlayer.UserId then return end
                local goal = State.DefendingGoal or getDefendedGoal()
                local root = getRoot()
                if not goal or not root then return end
                local hit = solveIntercept(data.Position, data.Velocity, goal.Position, State.GoalFacingNormal)
                if hit and (hit - root.Position).Magnitude <= CONFIG.Goalkeeper.DiveDistance then
                    local yThr = CONFIG.Goalkeeper.JumpHeightThreshold
                    tryGoalkeeperSave(hit, hit.Y - root.Position.Y > yThr, data.Velocity, data.Position)
                end
            end
        end))
    end

    -- MovementUpdate: update lintasan realtime
    if BallRemotes.MovementUpdate then
        track(BallRemotes.MovementUpdate.OnClientEvent:Connect(function(data)
            if not CONFIG.Goalkeeper.Enabled or not CONFIG.Goalkeeper.RemotePrediction then return end
            if hasPossession() or not isGoalkeeper() then return end
            if type(data) ~= "table" then return end
            if data.Kind ~= "Movement" or data.Mode ~= "Airborne" then return end
            if data.LastKickerUserId == LocalPlayer.UserId then return end
            local goal = State.DefendingGoal or getDefendedGoal()
            local root = getRoot()
            if not goal or not root then return end
            local pos = data.GoalCrossingPosition
            if not pos then
                pos = solveIntercept(data.Position, data.Velocity, goal.Position, State.GoalFacingNormal)
            end
            if pos and (pos - root.Position).Magnitude <= CONFIG.Goalkeeper.DiveDistance then
                local yThr = CONFIG.Goalkeeper.JumpHeightThreshold
                tryGoalkeeperSave(pos, pos.Y - root.Position.Y > yThr, data.Velocity, data.Position)
            end
        end))
    end

    -- ActionPresentationUpdate: prediksi sebelum bola lepas
    if BallRemotes.ActionPresentationUpdate then
        track(BallRemotes.ActionPresentationUpdate.OnClientEvent:Connect(function(kind, userId, ...)
            if not CONFIG.Goalkeeper.Enabled or not CONFIG.Goalkeeper.PreAimPrediction then return end
            if hasPossession() or not isGoalkeeper() then return end
            if kind == "KickChargeUpdated" and userId ~= LocalPlayer.UserId then
                local args = { ... }
                local p = args[7] or args[8]
                if typeof(p) == "Vector3" then
                    local root = getRoot()
                    if root and (p - root.Position).Magnitude <= CONFIG.Goalkeeper.DiveDistance then
                        State.LastThreatInterceptPos = p
                        State.StatusText = "PRE-AIM CHARGING"
                    end
                end
            end
        end))
    end

    -- GoalAnnouncement: fallback bila ada crossing position
    if BallRemotes.GoalAnnouncement then
        track(BallRemotes.GoalAnnouncement.OnClientEvent:Connect(function(data)
            if not CONFIG.Goalkeeper.Enabled then return end
            if hasPossession() or not isGoalkeeper() then return end
            if type(data) == "table" and data.CrossingPosition then
                local root = getRoot()
                if root and (data.CrossingPosition - root.Position).Magnitude <= CONFIG.Goalkeeper.DiveDistance then
                    local yThr = CONFIG.Goalkeeper.JumpHeightThreshold
                    tryGoalkeeperSave(data.CrossingPosition, data.CrossingPosition.Y - root.Position.Y > yThr, nil, nil)
                end
            end
        end))
    end
end

hookBallEvents()

-- ═══════════════════════════════════════════════════════════
-- [11] RAINBOW BICYCLE KICK
-- Flick -> detach -> jump -> charge volley -> release (IsBicycleKick)
-- ═══════════════════════════════════════════════════════════
local function buildAimForRainbow(useOpponentGoal)
    local root = getRoot()
    if not root then return nil, nil end

    local aim = nil
    if useOpponentGoal then
        local goal = findOpponentGoal()
        if goal then
            local gp = goal.Position + Vector3.new(0, 2.5, 0)
            local rp = root.Position + Vector3.new(0, 2, 0)
            local dir = (gp - rp).Unit
            local cf  = Camera and Camera.CFrame or CFrame.lookAt(rp, gp)
            aim = {
                Origin = rp,
                Direction = dir,
                CameraCFrame = cf,
                TargetPosition = gp,
                ClientHit = { Position = gp, Kind = "Map" },
                IsAirborne = true,
            }
        end
    end

    if not aim then
        local Reticle = Mods.Reticle
        if Reticle and Reticle.GetCameraAimRay then
            local ok, res = pcall(Reticle.GetCameraAimRay)
            if ok and res then aim = res end
        end
    end

    if not aim then
        local cf = Camera and Camera.CFrame
        local dir = cf and cf.LookVector or root.CFrame.LookVector
        aim = { Origin = root.Position, Direction = dir, IsAirborne = true }
    end

    local AF   = Mods.AimFacing
    local flat = AF and AF.GetFlatDirection and AF.GetFlatDirection(aim.Direction)
                 or Vector3.new(aim.Direction.X, 0, aim.Direction.Z).Unit
    return aim, flat
end

local function executeRainbow()
    if RainbowState.IsExecuting then return false, "Executing..." end
    if not CONFIG.Rainbow.Enabled then return false, "Disabled" end

    local ch   = LocalPlayer.Character
    local hum  = ch and ch:FindFirstChildOfClass("Humanoid")
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    if not ch or not hum or not root or hum.Health <= 0 then return false, "No Character" end

    local RF = Mods.RainbowFlick
    local cooldown = RF and RF.Constants and RF.Constants.CooldownSeconds or 3
    local now = os.clock()
    if now - RainbowState.LastExecutionTime < cooldown then
        return false, string.format("CD %.1fs", cooldown - (now - RainbowState.LastExecutionTime))
    end

    RainbowState.IsExecuting       = true
    RainbowState.LastExecutionTime = now

    task.spawn(function()
        local ok, err = pcall(function()
            local TS    = Mods.MotionSmoothing
            local nowS  = TS and TS.GetSmoothedServerTime and TS.GetSmoothedServerTime()
                          or Workspace:GetServerTimeNow()

            local detachDelay = CONFIG.Rainbow.DetachDelay
            local jumpDelay   = CONFIG.Rainbow.JumpDelay
            local charge      = CONFIG.Rainbow.ChargeDuration
            local playAnims   = CONFIG.Rainbow.PlayAnimations

            -- [1] Windup + animasi
            if RF and RF.SetWindingUpUntil then
                RF.SetWindingUpUntil(LocalPlayer,
                    nowS + RF.Constants.BallDetachSeconds + (RF.Constants.DetachCommandGraceSeconds or 0.15))
            end
            if playAnims and Mods.TackleEffects and Mods.TackleEffects.PlayLocalRainbowFlick then
                pcall(function() Mods.TackleEffects.PlayLocalRainbowFlick() end)
            end

            -- [2] Command RainbowFlick
            local AC  = Mods.ActionCommands
            local ARP = Mods.ActionRemoteProtocol
            if AC and AC.RainbowFlick and ARP then
                ARP.Send(AC.RainbowFlick({ ShotTime = nowS }))
            end

            task.wait(detachDelay)

            -- [3] Detach: bola popup
            local launch  = RF and RF.GetCharacterLaunch and RF.GetCharacterLaunch(ch)
            local BR      = Mods.BallRenderer
            local ballPos = BR and BR.GetPosition and BR.GetPosition()
                            or (launch and launch.Position)
                            or (root.Position + root.CFrame.LookVector * 2)
            local ballDir = launch and launch.Direction or root.CFrame.LookVector

            if AC and AC.RainbowFlick and ARP then
                ARP.Send(AC.RainbowFlick({
                    Mode = AC.Modes and AC.Modes.RainbowFlickDetach,
                    AimDirection = ballDir,
                    ClientPosition = ballPos,
                    ShotTime = nowS + (RF and RF.Constants and RF.Constants.BallDetachSeconds or 0.35),
                }))
            end

            task.wait(jumpDelay)

            -- [4] Jump
            pcall(function()
                if Mods.ActionLocks and Mods.ActionLocks.SetJumpStateBlocked then
                    Mods.ActionLocks.SetJumpStateBlocked("BallCarrier", false)
                    Mods.ActionLocks.SetJumpStateBlocked("KickRecovery", false)
                    Mods.ActionLocks.SetJumpStateBlocked("SlideTackle", false)
                end
            end)

            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            hum.JumpPower = 50
            hum.JumpHeight = 7.2
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            hum.Jump = true
            root.AssemblyLinearVelocity = Vector3.new(
                root.AssemblyLinearVelocity.X, 46, root.AssemblyLinearVelocity.Z)

            task.wait(0.2)

            if Mods.BicycleKick and Mods.BicycleKick.StartHover then
                Mods.BicycleKick.StartHover(ch, hum, root)
            end

            local chargeAnim
            if playAnims and Mods.KickAnimations and Mods.KickAnimations.PlayCharge then
                pcall(function()
                    chargeAnim = Mods.KickAnimations.PlayCharge(ch, 0.1, nil,
                        Mods.KickAnimations.AnimationSets and Mods.KickAnimations.AnimationSets.BicycleKick)
                end)
            end

            -- [5] Charge volley -> release
            local useOppGoal = CONFIG.Rainbow.TargetMode == "Opponent Goal"
            local aim, kickDir = buildAimForRainbow(useOppGoal)

            local nowS2 = TS and TS.GetSmoothedServerTime and TS.GetSmoothedServerTime()
                          or Workspace:GetServerTimeNow()
            local cmd3
            if AC and AC.Volley then
                cmd3 = AC.Volley({
                    UseClientPosition = true,
                    ChargeSeconds = charge,
                    MaximumChargeSeconds = 0.4,
                    PassType = AC.PassTypes and AC.PassTypes.Shot or "Shot",
                    AimDirection = aim,
                    KickDirection = kickDir,
                    ShotTime = nowS2,
                    IsBicycleKick = true,
                })
            end
            if ARP and cmd3 then ARP.Start(cmd3) end

            task.wait(charge)

            local nowS3 = TS and TS.GetSmoothedServerTime and TS.GetSmoothedServerTime()
                          or Workspace:GetServerTimeNow()
            local BC        = Mods.BallCarry
            local volleyPos = BC and BC.GetVolleyPosition and BC.GetVolleyPosition(ch) or root.Position
            local aim2, kickDir2 = buildAimForRainbow(useOppGoal)

            if ARP and cmd3 then
                cmd3.ChargeSeconds   = charge
                cmd3.ShotTime        = nowS3
                cmd3.ChargeStartedAt = nowS2
                cmd3.ClientPosition  = volleyPos
                cmd3.AimDirection    = aim2
                cmd3.KickDirection   = kickDir2
                ARP.Release(cmd3)
            end

            if Mods.BicycleKick and Mods.BicycleKick.FinishHover then
                Mods.BicycleKick.FinishHover(ch, hum, root)
            end
            if chargeAnim then pcall(function() chargeAnim:Stop(0.1) end) end

            if playAnims then
                pcall(function()
                    if Mods.KickAnimations and Mods.KickAnimations.PlayKick then
                        Mods.KickAnimations.PlayKick(ch, 0.1, 0.4, nil, nil,
                            Mods.KickAnimations.AnimationSets and Mods.KickAnimations.AnimationSets.BicycleKick)
                    end
                    if Mods.Sounds and Mods.Sounds.Play then
                        Mods.Sounds.Play("CharacterBicycleKick")
                    end
                end)
            end
        end)

        if not ok then warn("[Mizukage Official Rainbow] Error:", err) end
        task.wait(0.5)
        RainbowState.IsExecuting = false
    end)

    return true, "Executing"
end

-- ═══════════════════════════════════════════════════════════
-- [12] FLY & AIR DRIBBLE
-- WASD gerak, Space naik, Shift/Ctrl turun.
-- ═══════════════════════════════════════════════════════════
local flyBodyVel, flyBodyGyro

local function stopFly()
    if flyBodyVel then flyBodyVel:Destroy(); flyBodyVel = nil end
    if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
end

local function startFly(root)
    if flyBodyVel and flyBodyVel.Parent ~= root then stopFly() end
    if not flyBodyVel then
        flyBodyVel = Instance.new("BodyVelocity")
        flyBodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBodyVel.Velocity = Vector3.zero
        flyBodyVel.Parent = root
    end
    if not flyBodyGyro then
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBodyGyro.P = 1000
        flyBodyGyro.Parent = root
    end
end

track(RunService.Heartbeat:Connect(function()
    if CONFIG.Fly.Enabled then
        local root = getRoot()
        if root then
            startFly(root)
            local cf = Camera and Camera.CFrame or root.CFrame
            flyBodyGyro.CFrame = cf

            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
                or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                move = move - Vector3.new(0, 1, 0)
            end

            if move.Magnitude > 0 then
                move = move.Unit * CONFIG.Fly.Speed
            end
            flyBodyVel.Velocity = move

            -- Air dribble: bola menempel di depan pemain
            if CONFIG.Fly.AirDribble then
                local ball = findBall()
                if ball and ball:IsA("BasePart") then
                    local targetPos = root.Position + root.CFrame.LookVector * 3 - Vector3.new(0, 2, 0)
                    ball.CFrame = CFrame.new(targetPos)
                    ball.AssemblyLinearVelocity = Vector3.zero
                end
            end
        end
    else
        if flyBodyVel or flyBodyGyro then stopFly() end
    end
end))

-- ═══════════════════════════════════════════════════════════
-- [13] MOVEMENT
-- ═══════════════════════════════════════════════════════════
local staminaWasOn = false
track(RunService.Heartbeat:Connect(function()
    local Sprint = Mods.Sprint
    if not Sprint or not Sprint.SetUnlimitedStamina then return end
    if CONFIG.Movement.InfiniteStamina then
        staminaWasOn = true
        pcall(Sprint.SetUnlimitedStamina, LocalPlayer, "MizukageStamina", true)
    elseif staminaWasOn then
        staminaWasOn = false
        pcall(Sprint.SetUnlimitedStamina, LocalPlayer, "MizukageStamina", false)
    end
end))

local speedWasOn = false
track(RunService.Heartbeat:Connect(function()
    local AM = Mods.ActionMovement
    if not AM or not AM.SetSpeedMultiplier then return end
    if CONFIG.Movement.SpeedEnabled then
        speedWasOn = true
        pcall(AM.SetSpeedMultiplier, math.clamp(CONFIG.Movement.SpeedMultiplier, 1, 1.4))
    elseif speedWasOn then
        speedWasOn = false
        pcall(AM.SetSpeedMultiplier, 1)
    end
end))

track(UserInputService.JumpRequest:Connect(function()
    if CONFIG.Movement.InfiniteJump then
        local hum = getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

local function resyncPosition()
    task.spawn(function()
        local root = getRoot()
        if not root then return end
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            if Mods.Movement and Mods.Movement.SetMultiplier then
                Mods.Movement.SetMultiplier("MizukageSpeedHook", { WalkSpeed = 1 })
            end
        end)
        task.wait(0.12)
        local ball = findBall()
        if ball and BallRemotes.State then
            pcall(function() BallRemotes.State:FireServer(ball) end)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════
-- [14] VISUALS
-- ═══════════════════════════════════════════════════════════
local ballBox, ballHighlight
local playerBoxes = {}
local lightingBackup

local function makeBox(adornee, color)
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee      = adornee
    box.AlwaysOnTop  = true
    box.ZIndex       = 5
    box.Size         = adornee.Size
    box.Color3       = color
    box.Transparency = 0.4
    box.Parent       = adornee
    return box
end

local function restoreLighting()
    if lightingBackup then
        for prop, value in pairs(lightingBackup) do
            pcall(function() Lighting[prop] = value end)
        end
        lightingBackup = nil
    end
end

track(Players.PlayerRemoving:Connect(function(plr)
    if playerBoxes[plr] then
        pcall(function() playerBoxes[plr]:Destroy() end)
        playerBoxes[plr] = nil
    end
end))

track(RunService.RenderStepped:Connect(function()
    local V = CONFIG.Visuals
    local ball = findBall()

    -- Ball ESP
    if V.BallESP and ball then
        if not ballBox or ballBox.Adornee ~= ball or not ballBox.Parent then
            if ballBox then ballBox:Destroy() end
            ballBox = makeBox(ball, V.BallESPColor)
        end
        ballBox.Color3 = V.BallESPColor
        ballBox.Visible = true
    elseif ballBox then
        ballBox.Visible = false
    end

    -- Ball highlight
    if V.BallHighlight and ball then
        if not ballHighlight or ballHighlight.Parent ~= ball then
            if ballHighlight then ballHighlight:Destroy() end
            ballHighlight = Instance.new("Highlight")
            ballHighlight.FillColor        = V.BallHighlightColor
            ballHighlight.OutlineColor     = Color3.new(1, 1, 1)
            ballHighlight.FillTransparency = 0.6
            ballHighlight.Parent           = ball
        end
    elseif ballHighlight then
        ballHighlight:Destroy()
        ballHighlight = nil
    end

    -- Player ESP
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local box = playerBoxes[plr]
                if box and box.Adornee ~= root then
                    box:Destroy()
                    box, playerBoxes[plr] = nil, nil
                end
                if V.PlayerESP then
                    local color = V.EnemyColor
                    if V.PlayerESPTeamColor and plr.Team ~= nil and plr.Team == LocalPlayer.Team then
                        color = V.AllyColor
                    end
                    if not box then
                        box = makeBox(root, color)
                        playerBoxes[plr] = box
                    end
                    box.Color3 = color
                    box.Visible = true
                elseif box then
                    box.Visible = false
                end
            end
        end
    end

    -- Fullbright
    if V.Fullbright then
        if not lightingBackup then
            lightingBackup = {
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
            }
        end
        Lighting.Ambient        = Color3.fromRGB(180, 180, 180)
        Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
        Lighting.Brightness     = 3
        Lighting.ClockTime      = 14
    elseif lightingBackup then
        restoreLighting()
    end
end))

-- State GK & bola realtime
track(RunService.Heartbeat:Connect(function(dt)
    State.IsGoalkeeper = isGoalkeeper()

    -- Perbarui gawang yang dijaga (tidak tiap frame)
    State.GoalTimer += dt
    if State.GoalTimer >= 1 then
        State.GoalTimer = 0
        local goal, normal = getDefendedGoal()
        if goal then
            State.DefendingGoal = goal
            State.GoalFacingNormal = normal
        end
    end

    local ball = findBall()
    if ball then
        State.BallPosition = ball.Position
        State.BallVelocity = ball.AssemblyLinearVelocity
        local root = getRoot()
        State.DistanceToBall = root and (root.Position - ball.Position).Magnitude or 999
    end
end))

-- Auto possession rainbow
track(RunService.Heartbeat:Connect(function()
    if not CONFIG.Rainbow.Enabled or not CONFIG.Rainbow.AutoPossession then return end
    if RainbowState.IsExecuting then return end
    if hasPossession() then
        local RF = Mods.RainbowFlick
        local cd = RF and RF.Constants and RF.Constants.CooldownSeconds or 3
        if os.clock() - RainbowState.LastExecutionTime >= cd then
            executeRainbow()
        end
    end
end))

-- ═══════════════════════════════════════════════════════════
-- [15] UI (WindUI) — ukuran ringkas
-- ═══════════════════════════════════════════════════════════
local Window
local Controls = {}
local StatusPara

local function SetControl(group, key, value)
    CONFIG[group][key] = value
    local el = Controls[group .. "." .. key]
    if el then pcall(function() el:Set(value) end) end
end

local function AddToggle(tab, title, group, key, onChange)
    local bucket = CONFIG[group]
    Controls[group .. "." .. key] = tab:Toggle({
        Title    = title,
        Value    = bucket[key] == true,
        Default  = bucket[key] == true,
        Callback = function(v)
            v = v and true or false
            if v == (bucket[key] == true) then return end
            bucket[key] = v
            if onChange then pcall(onChange, v) end
            saveSettings()
        end,
    })
end

local function AddSlider(tab, title, group, key, minV, maxV, step)
    local bucket = CONFIG[group]
    tab:Slider({
        Title = title,
        Step  = step or 1,
        Value = { Min = minV, Max = maxV, Default = math.clamp(bucket[key], minV, maxV) },
        Callback = function(v)
            v = tonumber(v)
            if v == nil or v == bucket[key] then return end
            bucket[key] = v
            saveSettings()
        end,
    })
end

local function AddDropdown(tab, title, group, key, values)
    local bucket = CONFIG[group]
    tab:Dropdown({
        Title    = title,
        Values   = values,
        Value    = bucket[key],
        Callback = function(v)
            if type(v) == "table" then v = v.Title or v[1] end
            if v == nil or v == bucket[key] then return end
            bucket[key] = v
            saveSettings()
        end,
    })
end

local function keyName(code)
    return code and code.Name or "-"
end

local function updateStatusPanel()
    if not StatusPara then return end
    local text = string.format(
        "Game: %s | Modul: %d%s\nRole GK: %s | Possession: %s\nGK Status: %s\nJarak bola: %.1f studs | Rainbow: %s",
        GAME_NAME, moduleCount, gameDetected and "" or " (game tidak terdeteksi)",
        State.IsGoalkeeper and "YA" or "TIDAK",
        hasPossession() and "YA" or "TIDAK",
        State.StatusText,
        State.DistanceToBall < 999 and State.DistanceToBall or 0,
        RainbowState.IsExecuting and "RUNNING" or "READY"
    )
    if text ~= State.LastText then
        State.LastText = text
        pcall(function() StatusPara:SetTitle(text) end)
    end
end

local function unload()
    if State.Unloaded then return end
    State.Unloaded = true

    for _, v in ipairs(Cleanup) do
        pcall(function()
            if typeof(v) == "RBXScriptConnection" then v:Disconnect()
            elseif typeof(v) == "Instance" then v:Destroy()
            elseif type(v) == "function" then v() end
        end)
    end
    table.clear(Cleanup)

    stopFly()
    restoreLighting()
    if ballBox then pcall(function() ballBox:Destroy() end) end
    if ballHighlight then pcall(function() ballHighlight:Destroy() end) end
    for _, b in pairs(playerBoxes) do pcall(function() b:Destroy() end) end

    -- Matikan efek stamina / speed
    if Mods.Sprint and Mods.Sprint.SetUnlimitedStamina then
        pcall(Mods.Sprint.SetUnlimitedStamina, LocalPlayer, "MizukageStamina", false)
    end
    if Mods.ActionMovement and Mods.ActionMovement.SetSpeedMultiplier and speedWasOn then
        pcall(Mods.ActionMovement.SetSpeedMultiplier, 1)
    end

    -- Kembalikan fungsi Reticle asli
    local Reticle = Mods.Reticle
    if Reticle then
        if origCameraRay then Reticle.GetCameraRay = origCameraRay end
        if origCameraAimRay then Reticle.GetCameraAimRay = origCameraAimRay end
        if origCameraAimRayNoHit then Reticle.GetCameraAimRayWithoutHit = origCameraAimRayNoHit end
    end

    -- Lepas hook anti-rubberband bila executor mendukung
    if type(restorefunction) == "function" then
        for _, fn in ipairs(antiHooks) do pcall(restorefunction, fn) end
    end

    if Window then pcall(function() Window:Destroy() end) end

    env.MizukageOfficial = nil
    env.MizukageOfficialUnload = nil
    print("[Mizukage Official] Cleanup complete.")
end

env.MizukageOfficialUnload = unload

local function InitInterface()
    local viewport = Camera and Camera.ViewportSize or Vector2.new(1280, 720)
    local isMobile = viewport.X < 850

    pcall(function()
        WindUI:Gradient({
            ["0"]   = { Color = Color3.fromHex("#5c5291"), Transparency = 0.15 },
            ["50"]  = { Color = Color3.fromHex("#0096ff"), Transparency = 0.10 },
            ["100"] = { Color = Color3.fromHex("#18181b"), Transparency = 0 },
        }, { Rotation = 45 })
    end)

    Window = WindUI:CreateWindow({
        Title        = BRAND,
        Icon         = "lucide:goal",
        Author       = GAME_NAME,
        Folder       = FOLDER,
        Size         = isMobile
            and UDim2.fromOffset(viewport.X * 0.88, viewport.Y * 0.88)
            or  UDim2.fromOffset(620, 460),
        MinSize      = Vector2.new(460, 340),
        MaxSize      = Vector2.new(760, 600),
        ToggleKey    = Enum.KeyCode.RightShift,
        Transparent  = true,
        Theme        = "Dark",
        Accent       = Color3.fromRGB(145, 104, 255),
        Resizable    = true,
        SideBarWidth = isMobile and 150 or 180,
        HasOutline   = true,
        BackgroundImageTransparency = 0.42,
        Background   = "rbxassetid://137490169052447",
        ScrollBarEnabled = true,
        User = {
            Enabled   = true,
            Anonymous = false,
            Callback  = function()
                SafeNotify("Player Info", string.format("Name: %s\nDisplay: %s\nUserID: %s",
                    LocalPlayer.Name, LocalPlayer.DisplayName, LocalPlayer.UserId), 5, "lucide:user")
            end,
        },
    })

    pcall(function()
        Window:Tag({ Title = "MIZUKAGE OFFICIAL", Icon = "lucide:crown",    Color = Color3.fromHex("#FFD700"), Radius = 13 })
        Window:Tag({ Title = VERSION,             Icon = "lucide:sparkles", Color = Color3.fromHex("#30ff6a"), Radius = 6 })
        Window:Tag({ Title = "ILLEGAL SOCCER",   Icon = "lucide:goal",     Color = Color3.fromHex("#0096ff"), Radius = 0 })
        Window:Divider()
    end)

    -- Dashboard
    local TabDash = Window:Tab({ Title = "Dashboard", Icon = "lucide:layout-dashboard" })
    TabDash:Section({ Title = "Status Live" })
    StatusPara = TabDash:Paragraph({ Title = "Menunggu..." })
    TabDash:Section({ Title = "Keybind" })
    TabDash:Paragraph({ Title = string.format(
        "Rainbow: %s | Fly: %s | Speed: %s | Resync: %s",
        keyName(CONFIG.Rainbow.Keybind), keyName(CONFIG.Fly.Keybind),
        keyName(CONFIG.Movement.SpeedKeybind), keyName(CONFIG.Movement.ResyncKeybind)) })

    -- Offense
    local TabOff = Window:Tab({ Title = "Offense", Icon = "lucide:crosshair" })
    TabOff:Section({ Title = "Silent Aim" })
    AddToggle(TabOff, "Silent Aim ke Gawang", "SilentAim", "Enabled")
    AddDropdown(TabOff, "Target Sudut", "SilentAim", "TargetCorner", {
        "Top Right Corner", "Top Left Corner", "Bottom Right Corner",
        "Bottom Left Corner", "Center Net", "Random Corner",
    })
    AddSlider(TabOff, "Corner Spread", "SilentAim", "CornerSpread", 0, 18, 0.5)
    AddSlider(TabOff, "Tinggi Sudut Atas", "SilentAim", "TopHeight", 0, 8, 0.1)
    AddSlider(TabOff, "Offset Sudut Bawah", "SilentAim", "BottomHeight", -8, 0, 0.1)
    AddSlider(TabOff, "Tinggi Center Net", "SilentAim", "HeightOffset", 0, 6, 0.1)

    TabOff:Section({ Title = "Rainbow Bicycle Kick" })
    AddToggle(TabOff, "Rainbow Aktif", "Rainbow", "Enabled")
    AddToggle(TabOff, "Auto saat Possession", "Rainbow", "AutoPossession")
    AddDropdown(TabOff, "Target Rainbow", "Rainbow", "TargetMode", { "Camera Reticle", "Opponent Goal" })
    AddSlider(TabOff, "Detach Delay (s)", "Rainbow", "DetachDelay", 0.1, 1, 0.01)
    AddSlider(TabOff, "Jump Delay (s)", "Rainbow", "JumpDelay", 0.1, 1, 0.01)
    AddSlider(TabOff, "Charge (s, max 0.40)", "Rainbow", "ChargeDuration", 0.1, 0.4, 0.01)
    AddToggle(TabOff, "Animasi + Sound", "Rainbow", "PlayAnimations")
    TabOff:Button({
        Title = "Jalankan Rainbow Sekarang", Icon = "lucide:zap",
        Callback = function()
            local ok, msg = executeRainbow()
            SafeNotify("Rainbow", tostring(msg), 2, ok and "lucide:check" or "lucide:info")
        end,
    })

    -- Goalkeeper
    local TabGK = Window:Tab({ Title = "Goalkeeper", Icon = "lucide:shield" })
    TabGK:Section({ Title = "Auto Goalkeeper" })
    AddToggle(TabGK, "Auto Goalkeeper", "Goalkeeper", "Enabled")
    AddToggle(TabGK, "Wajib Role GK Resmi", "Goalkeeper", "RequireRole")
    AddToggle(TabGK, "GK Silent Aim", "Goalkeeper", "SilentAim")
    AddToggle(TabGK, "Auto Dive", "Goalkeeper", "AutoDive")
    AddToggle(TabGK, "Auto Punch", "Goalkeeper", "AutoPunch")
    AddToggle(TabGK, "Auto Jump", "Goalkeeper", "AutoJump")
    AddToggle(TabGK, "Prediksi Remote (instan)", "Goalkeeper", "RemotePrediction")
    AddToggle(TabGK, "Prediksi Pre-Aim", "Goalkeeper", "PreAimPrediction")
    TabGK:Section({ Title = "Parameter" })
    AddSlider(TabGK, "Max Dive Reach", "Goalkeeper", "MaxDiveReach", 5, 20, 0.5)
    AddSlider(TabGK, "Jarak Dive (studs)", "Goalkeeper", "DiveDistance", 10, 80, 1)
    AddSlider(TabGK, "Center Tolerance", "Goalkeeper", "CenterTolerance", 0, 5, 0.1)
    AddSlider(TabGK, "Batas Bola Tinggi", "Goalkeeper", "JumpHeightThreshold", 0, 8, 0.1)
    AddSlider(TabGK, "Reaction Delay (ms)", "Goalkeeper", "ReactionDelayMs", 0, 500, 10)

    -- Movement
    local TabMove = Window:Tab({ Title = "Movement", Icon = "lucide:wind" })
    TabMove:Section({ Title = "Fly" })
    AddToggle(TabMove, "Fly", "Fly", "Enabled")
    AddToggle(TabMove, "Air Dribble", "Fly", "AirDribble")
    AddSlider(TabMove, "Kecepatan Fly", "Fly", "Speed", 10, 150, 1)
    TabMove:Section({ Title = "Stamina & Speed" })
    AddToggle(TabMove, "Infinite Stamina", "Movement", "InfiniteStamina")
    AddToggle(TabMove, "Speed Multiplier", "Movement", "SpeedEnabled")
    AddSlider(TabMove, "Multiplier (max 1.4)", "Movement", "SpeedMultiplier", 1, 1.4, 0.05)
    AddToggle(TabMove, "Anti Rubberband", "Movement", "AntiRubberband")
    AddToggle(TabMove, "Infinite Jump", "Movement", "InfiniteJump")
    TabMove:Button({
        Title = "Resync Posisi", Icon = "lucide:refresh-cw",
        Callback = resyncPosition,
    })

    -- Visuals
    local TabVis = Window:Tab({ Title = "Visuals", Icon = "lucide:eye" })
    TabVis:Section({ Title = "Bola" })
    AddToggle(TabVis, "Ball ESP", "Visuals", "BallESP")
    AddToggle(TabVis, "Ball Highlight", "Visuals", "BallHighlight")
    TabVis:Section({ Title = "Pemain & Lingkungan" })
    AddToggle(TabVis, "Player ESP", "Visuals", "PlayerESP")
    AddToggle(TabVis, "Warna Sesuai Tim", "Visuals", "PlayerESPTeamColor")
    AddToggle(TabVis, "Fullbright", "Visuals", "Fullbright")

    -- Settings
    local TabSet = Window:Tab({ Title = "Settings", Icon = "lucide:settings" })
    TabSet:Section({ Title = "Interface" })
    local themes = {}
    pcall(function() for name in pairs(WindUI:GetThemes()) do table.insert(themes, name) end end)
    table.sort(themes)
    if #themes == 0 then themes = { "Dark", "Light" } end
    TabSet:Dropdown({
        Title = "Theme", Values = themes, Value = "Dark",
        Callback = function(v)
            if type(v) == "table" then v = v.Title or v[1] end
            pcall(function() WindUI:SetTheme(v) end)
        end,
    })
    TabSet:Divider()
    TabSet:Section({ Title = "Manajemen Script" })
    TabSet:Button({
        Title = "Unload Script (Terminate)", Variant = "Destructive", Icon = "lucide:power",
        Callback = function()
            Window:Dialog({
                Icon    = "lucide:alert-triangle",
                Title   = "Konfirmasi Unload",
                Content = "Yakin ingin menghentikan script?",
                Buttons = {
                    { Title = "Batal", Variant = "Tertiary", Callback = function() end },
                    { Title = "Ya, Unload", Icon = "lucide:power", Variant = "Destructive", Callback = unload },
                },
            })
        end,
    })

    if gameDetected then
        SafeNotify(BRAND, GAME_NAME .. " siap (" .. moduleCount .. " modul).", 4, "lucide:check")
    else
        SafeNotify(BRAND, "Module game tidak ditemukan. Pastikan kamu di " .. GAME_NAME .. ".", 8, "lucide:alert-triangle")
    end
end

local uiOk, uiErr = pcall(InitInterface)
if not uiOk then
    warn("[Mizukage Official] InitInterface gagal: " .. tostring(uiErr))
    SafeNotify(BRAND, "UI gagal dibuat: " .. tostring(uiErr), 8, "lucide:alert-triangle")
    unload()
    return
end

-- ═══════════════════════════════════════════════════════════
-- [16] INPUT (keybind) + STATUS LOOP
-- ═══════════════════════════════════════════════════════════
track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    if CONFIG.Rainbow.Enabled and CONFIG.Rainbow.Keybind and input.KeyCode == CONFIG.Rainbow.Keybind then
        executeRainbow()
    end

    if input.KeyCode == CONFIG.Movement.ResyncKeybind then
        resyncPosition()
    end

    if CONFIG.Fly.Keybind and input.KeyCode == CONFIG.Fly.Keybind then
        SetControl("Fly", "Enabled", not CONFIG.Fly.Enabled)
    end

    if CONFIG.Movement.SpeedKeybind and input.KeyCode == CONFIG.Movement.SpeedKeybind then
        SetControl("Movement", "SpeedEnabled", not CONFIG.Movement.SpeedEnabled)
    end
end))

task.spawn(function()
    while not State.Unloaded do
        pcall(updateStatusPanel)
        task.wait(0.5)
    end
end)

print("[" .. BRAND .. "] " .. GAME_NAME .. " " .. VERSION .. " loaded")
