local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")
local RunSvc    = game:GetService("RunService")
local LP        = Players.LocalPlayer
local Camera    = workspace.CurrentCamera
local RemoteEvent = RS:WaitForChild("RemoteEvent")
local IsGameActive = RS:WaitForChild("IsGameActive")

local C = {
    Survivor = Color3.fromRGB(0, 255, 170),
    Beast    = Color3.fromRGB(255, 30, 60),
    Computer = Color3.fromRGB(0, 170, 255), 
    Exit     = Color3.fromRGB(180, 80, 255),
    Trap     = Color3.fromRGB(255, 140, 0)
}

local State = {
    ESP_Players = true, ESP_Computers = true, ESP_Exit = true,
    ESP_Tracers = true, ESP_Boxes = true,
    AutoMinigame = false, EvasiveHack = false, AutoRescue = false, AutoRun = false, RunSpeed = 28,
    BeastAutoHammer = false, BeastAutoTrap = false, BeastCaptureRange = 15,
    GhostInvisible = false, GhostNoClip = false,
    ComputerCache = {}, ExitCache = nil, PodCache = {}, RescueCache = {}, 
    ESPStore = {}, HackedComps = {}, OriginalGhostData = {}
}

IsGameActive.Changed:Connect(function(v) 
    if v then State.HackedComps = {} end 
end)

local function getHRP(p) local ch = p and p.Character; return ch and ch:FindFirstChild("HumanoidRootPart") end
local function getLocalHRP() return getHRP(LP) end

local function isBeast(p) 
    local ch = p and p.Character
    if not ch then return false end
    if ch:FindFirstChild("BeastPowers") then return true end
    local stats = p:FindFirstChild("TempPlayerStatsModule")
    if stats then
        local s, m = pcall(require, stats)
        if s and m and m.GetValue("IsBeast") then return true end
    end
    return false
end

local function getHP(p)
    local ch = p and p.Character
    local h = ch and ch:FindFirstChildOfClass("Humanoid")
    return h and h.Health or 0, h and h.MaxHealth or 100
end

local function dist3(pos) local hrp = getLocalHRP(); if not hrp then return 9999 end; return (hrp.Position - pos).Magnitude end
local function fmtDist(d) return d >= 1000 and string.format("%.1fk", d/1000) or string.format("%dm", math.floor(d)) end

local function isBusy()
    local stats = LP:FindFirstChild("TempPlayerStatsModule")
    if stats then
        local s, m = pcall(require, stats)
        if s and m then
            return (m.GetValue("ActionProgress") > 0) or m.GetValue("ActionInput") == true
        end
    end
    return false
end

local function clearESP(inst)
    local d = State.ESPStore[inst]; if not d then return end
    if d.hl then d.hl:Destroy() end
    if d.gui then d.gui:Destroy() end
    if d.tracer and d.tracer.Remove then d.tracer:Remove() end
    if d.box and d.box.Remove then d.box:Remove() end
    State.ESPStore[inst] = nil
end

local function createPlayerESP(player)
    if player == LP then return end
    local ch = player.Character; if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if State.ESPStore[hrp] then return end

    local color = isBeast(player) and C.Beast or C.Survivor

    local hl = Instance.new("Highlight")
    hl.Adornee = ch; hl.FillColor = color; hl.FillTransparency = 0.8; hl.OutlineColor = color; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = ch

    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0, 120, 0, 28); gui.StudsOffset = Vector3.new(0, 3.5, 0); gui.AlwaysOnTop = true; gui.Adornee = hrp; gui.Parent = hrp

    local avatarFrame = Instance.new("Frame")
    avatarFrame.Size = UDim2.new(0, 24, 0, 24); avatarFrame.BackgroundColor3 = color; avatarFrame.ClipsDescendants = true; avatarFrame.Parent = gui
    local ac = Instance.new("UICorner"); ac.CornerRadius = UDim.new(1, 0); ac.Parent = avatarFrame

    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Size = UDim2.new(1, -2, 1, -2); avatarImg.Position = UDim2.new(0, 1, 0, 1); avatarImg.BackgroundTransparency = 1
    avatarImg.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..player.UserId.."&width=150&height=150&format=png"
    avatarImg.Parent = avatarFrame
    local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(1, 0); ic.Parent = avatarImg

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, -30, 0, 12); nameLbl.Position = UDim2.new(0, 28, 0, -1); nameLbl.BackgroundTransparency = 1
    nameLbl.Text = string.upper(player.Name); nameLbl.TextColor3 = color; nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 10
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.TextStrokeTransparency = 0; nameLbl.Parent = gui

    local hpBg = Instance.new("Frame")
    hpBg.Size = UDim2.new(1, -30, 0, 2); hpBg.Position = UDim2.new(0, 28, 0, 12); hpBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20); hpBg.BorderSizePixel = 0; hpBg.Parent = gui
    local hpFill = Instance.new("Frame")
    hpFill.Size = UDim2.new(1, 0, 1, 0); hpFill.BackgroundColor3 = color; hpFill.BorderSizePixel = 0; hpFill.Parent = hpBg

    local dist = Instance.new("TextLabel")
    dist.Size = UDim2.new(1, -30, 0, 10); dist.Position = UDim2.new(0, 28, 0, 15); dist.BackgroundTransparency = 1
    dist.Text = "0m"; dist.TextColor3 = Color3.fromRGB(200, 200, 200); dist.Font = Enum.Font.Code; dist.TextSize = 9
    dist.TextXAlignment = Enum.TextXAlignment.Left; dist.TextStrokeTransparency = 0; dist.Parent = gui

    local tracer, box
    pcall(function()
        if Drawing then
            if State.ESP_Tracers then tracer = Drawing.new("Line"); tracer.Thickness = 1; tracer.Color = color; tracer.Transparency = 0.4 end
            if State.ESP_Boxes then box = Drawing.new("Square"); box.Thickness = 1; box.Color = color; box.Transparency = 0.6 end
        end
    end)

    State.ESPStore[hrp] = { gui=gui, hl=hl, hpFill=hpFill, dist=dist, avatarFrame=avatarFrame, nameLbl=nameLbl, owner=player, currentColor=color, tracer=tracer, box=box }
end

local function createObjectESP(inst, kind, color)
    if State.ESPStore[inst] or not inst:IsA("BasePart") then return end

    local hl = Instance.new("Highlight")
    hl.Adornee = inst; hl.FillColor = color; hl.FillTransparency = 0.8; hl.OutlineColor = color; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = inst

    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0, 70, 0, 20); gui.StudsOffset = Vector3.new(0, 1.5, 0); gui.AlwaysOnTop = true; gui.Adornee = inst; gui.Parent = inst

    local iconFrame = Instance.new("Frame")
    iconFrame.Size = UDim2.new(0, 18, 0, 18); iconFrame.Position = UDim2.new(0, 0, 0.5, -9); iconFrame.BackgroundColor3 = color; iconFrame.ClipsDescendants = true; iconFrame.Parent = gui
    local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(1, 0); ic.Parent = iconFrame

    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(1, -2, 1, -2); img.Position = UDim2.new(0, 1, 0, 1); img.BackgroundTransparency = 1
    img.Image = kind=="computer" and "rbxassetid://6031091004" or (kind=="exit" and "rbxassetid://6035047409" or "rbxassetid://6031094667")
    img.Parent = iconFrame
    local imgc = Instance.new("UICorner"); imgc.CornerRadius = UDim.new(1, 0); imgc.Parent = img

    local dist = Instance.new("TextLabel")
    dist.Size = UDim2.new(1, -22, 1, 0); dist.Position = UDim2.new(0, 22, 0, 0); dist.BackgroundTransparency = 1
    dist.TextColor3 = color; dist.Font = Enum.Font.GothamBold; dist.TextSize = 10; dist.TextXAlignment = Enum.TextXAlignment.Left; dist.TextStrokeTransparency = 0; dist.Parent = gui

    State.ESPStore[inst] = { gui=gui, hl=hl, dist=dist, kind=kind, isObj=true }
end

RunSvc.RenderStepped:Connect(function()
    if State.ESP_Players then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp and not State.ESPStore[hrp] then createPlayerESP(p) end
            end
        end
    end

    for inst, d in pairs(State.ESPStore) do
        if not inst.Parent then clearESP(inst); continue end
        if d.dist then d.dist.Text = fmtDist(dist3(inst.Position)) end
        
        if d.owner then
            local isBeastNow = isBeast(d.owner)
            local newColor = isBeastNow and C.Beast or C.Survivor
            if d.currentColor ~= newColor then
                d.currentColor = newColor
                d.hl.FillColor = newColor; d.hl.OutlineColor = newColor
                d.nameLbl.TextColor3 = newColor; d.hpFill.BackgroundColor3 = newColor; d.avatarFrame.BackgroundColor3 = newColor
                if d.tracer then d.tracer.Color = newColor end
                if d.box then d.box.Color = newColor end
            end
            local hp, mx = getHP(d.owner)
            d.hpFill.Size = UDim2.new(math.clamp(hp/mx,0,1),0,1,0)

            local root = d.owner.Character and d.owner.Character:FindFirstChild("HumanoidRootPart")
            if root and (d.tracer or d.box) then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    if d.tracer then
                        d.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                        d.tracer.To = Vector2.new(pos.X, pos.Y)
                        d.tracer.Visible = State.ESP_Tracers
                    end
                    if d.box then
                        local height = math.clamp(1000 / pos.Z, 20, 500)
                        local width = height * 0.6
                        d.box.Size = Vector2.new(width, height)
                        d.box.Position = Vector2.new(pos.X - width/2, pos.Y - height/2)
                        d.box.Visible = State.ESP_Boxes
                    end
                else
                    if d.tracer then d.tracer.Visible = false end
                    if d.box then d.box.Visible = false end
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        local comps, exitP, pods, rescues = {}, nil, {}, {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if not obj:IsA("BasePart") then continue end
            local sign = obj:FindFirstChild("ActionSign")
            
            if sign and sign:IsA("IntValue") then
                if sign.Value == 20 then
                    if not State.HackedComps[obj] then table.insert(comps, obj) end
                elseif sign.Value == 0 and obj.Name == "ExitDoorTrigger" then
                    exitP = obj
                elseif sign.Value == 30 then
                    table.insert(pods, obj)
                elseif sign.Value == 31 then
                    table.insert(rescues, obj)
                end
            end
        end
        State.ComputerCache, State.ExitCache, State.PodCache, State.RescueCache = comps, exitP, pods, rescues
        task.wait(1)
    end
end)

RunSvc.Heartbeat:Connect(function()
    if State.ESP_Computers then
        for _, c in ipairs(State.ComputerCache) do
            if not State.ESPStore[c] then createObjectESP(c, "computer", C.Computer) end
        end
    end
    if State.ESP_Exit and State.ExitCache and not State.ESPStore[State.ExitCache] then 
        createObjectESP(State.ExitCache, "exit", C.Exit) 
    end
end)

local function pressAction(obj, holdTime)
    local ev = obj:FindFirstChild("Event")
    pcall(function() RemoteEvent:FireServer("Input", "Trigger", true, ev) end)
    task.wait(0.1)
    
    local start = tick()
    while tick() - start < holdTime do
        pcall(function()
            RemoteEvent:FireServer("Input", "Action", true)
            RemoteEvent:FireServer("SetPlayerMinigameResult", true)
        end)
        task.wait(0.05)
    end
    
    pcall(function()
        RemoteEvent:FireServer("Input", "Action", false)
        RemoteEvent:FireServer("Input", "Trigger", false, ev)
    end)
end

local function nearestBeast(range)
    local hrp = getLocalHRP(); if not hrp then return nil end
    local best, bestD = nil, range
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and isBeast(p) then
            local t = getHRP(p)
            if t then 
                local d = (t.Position - hrp.Position).Magnitude
                if d < bestD then best, bestD = p, d end 
            end
        end
    end
    return best, bestD
end

local DodgeSide = 1
local LastDodgeTime = 0

task.spawn(function()
    while true do
        if LP.Character and not isBusy() then
            local hrp = getLocalHRP()
            
            if State.AutoMinigame then
                for _, comp in ipairs(State.ComputerCache) do
                    if (comp.Position - hrp.Position).Magnitude < 10 then
                        State.HackedComps[comp] = true
                        pressAction(comp, 1.5)
                        task.wait(0.5)
                        break
                    end
                end
            end
            
            if State.AutoRescue then
                for _, rescueObj in ipairs(State.RescueCache) do
                    if (rescueObj.Position - hrp.Position).Magnitude < 10 then
                        pressAction(rescueObj, 1.0)
                        task.wait(0.5)
                        break
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if State.EvasiveHack and LP.Character then
            local hrp = getLocalHRP()
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            local beast, dist = nearestBeast(20)
            
            if beast and dist < 20 and hrp and hum then
                local beastHrp = getHRP(beast)
                if beastHrp then
                    local dirToBeast = (beastHrp.Position - hrp.Position).Unit
                    local perpendicular = Vector3.new(-dirToBeast.Z, 0, dirToBeast.X)
                    
                    if tick() - LastDodgeTime > 0.15 then
                        DodgeSide = DodgeSide * -1
                        LastDodgeTime = tick()
                    end
                    
                    local moveVec = (perpendicular * DodgeSide).Unit * 45 + Vector3.new(0, 15, 0)
                    hrp.AssemblyLinearVelocity = moveVec
                    
                    pcall(function()
                        RemoteEvent:FireServer("Input", "Crawl", true)
                        RemoteEvent:FireServer("Input", "Action", true)
                        RemoteEvent:FireServer("SetPlayerMinigameResult", true)
                    end)
                    
                    if hum:GetState() ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
                        hum.Jump = true
                    end
                    
                    task.wait(0.1)
                    pcall(function()
                        RemoteEvent:FireServer("Input", "Crawl", false)
                    end)
                end
            end
        end
        task.wait(0.1)
    end
end)

local function applyGhost(state)
    local char = LP.Character
    if not char then return end
    
    if state then
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") or v:IsA("Decal") then
                if not State.OriginalGhostData[v] then
                    State.OriginalGhostData[v] = v.Transparency
                end
                v.Transparency = 1
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
        task.spawn(function()
            while State.GhostInvisible do
                local c = LP.Character
                if c then
                    for _, v in ipairs(c:GetDescendants()) do
                        if v:IsA("BasePart") or v:IsA("Decal") then
                            v.Transparency = 1
                        end
                    end
                end
                task.wait(0.1)
            end
        end)
    else
        for v, originalTrans in pairs(State.OriginalGhostData) do
            if v and v.Parent then
                v.Transparency = originalTrans
                if v:IsA("BasePart") then v.CanCollide = true end
            end
        end
        table.clear(State.OriginalGhostData)
    end
end

RunSvc.Stepped:Connect(function()
    if State.GhostNoClip and LP.Character then
        for _, v in ipairs(LP.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then
                v.CanCollide = false
            end
        end
    end
end)

task.spawn(function()
    while true do
        if State.AutoRun and IsGameActive.Value and LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed ~= State.RunSpeed then
                hum.WalkSpeed = State.RunSpeed
            end
        end
        task.wait(0.1)
    end
end)

local function getBeastEv() local ch = LP.Character; local h = ch and ch:FindFirstChild("Hammer"); return h and h:FindFirstChild("HammerEvent") end
local function nearestSurvivor(range)
    local hrp = getLocalHRP(); if not hrp then return nil end
    local best, bestD = nil, range
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP or isBeast(p) then continue end
        local t = getHRP(p)
        if t then local d = (t.Position - hrp.Position).Magnitude; if d < bestD then best, bestD = p, d end end
    end
    return best
end

task.spawn(function()
    local hitParts = {"Head", "HumanoidRootPart", "Torso", "Left Arm", "Right Arm"}
    local hitIndex = 1
    while true do
        if isBeast(LP) and LP.Character then
            local hrp = getLocalHRP()
            
            if State.BeastAutoHammer then
                local ev = getBeastEv()
                local target = nearestSurvivor(State.BeastCaptureRange)
                if ev and target then
                    local part = target.Character and target.Character:FindFirstChild(hitParts[hitIndex])
                    if part then
                        pcall(function()
                            ev:FireServer("HammerClick", true)
                            ev:FireServer("HammerHit", part)
                        end)
                        hitIndex = (hitIndex % #hitParts) + 1
                    end
                end
            end
            
            if State.BeastAutoTrap then
                local isCarrying = false
                local stats = LP:FindFirstChild("TempPlayerStatsModule")
                if stats then
                    local s, m = pcall(require, stats)
                    if s and m and m.GetValue("CarriedPlayer") then isCarrying = true end
                end
                
                if isCarrying then
                    local closestPod, dist = nil, 100
                    for _, pod in ipairs(State.PodCache) do
                        local d = (pod.Position - hrp.Position).Magnitude
                        if d < dist then closestPod, dist = pod, d end
                    end
                    if closestPod and dist < 10 then
                        pressAction(closestPod, 1.0)
                        task.wait(1)
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

local Window = Rayfield:CreateWindow({
    Name = "👑 Mizukage Official | TeamMizu🔰",
    LoadingTitle = "👑 Mizukage Official",
    LoadingSubtitle = "v11.0 Evasive Edition",
    Theme = "Midnight", 
    ToggleUIKeybind = "K",
})

local SurTab = Window:CreateTab("Survivor", 4483362458)
SurTab:CreateSection("Auto Assist")
SurTab:CreateToggle({ Name = "Force Auto Hack (Instan)", CurrentValue = false, Flag = "AutoMinigame", Callback = function(v) State.AutoMinigame = v end })
SurTab:CreateToggle({ Name = "Evasive Hack (Agresif Menghindar)", CurrentValue = false, Flag = "EvasiveHack", Callback = function(v) State.EvasiveHack = v end })
SurTab:CreateToggle({ Name = "Auto Rescue Teman", CurrentValue = false, Flag = "AutoRescue", Callback = function(v) State.AutoRescue = v end })

local BeastTab = Window:CreateTab("Beast", 4483362458)
BeastTab:CreateSection("Predator System")
BeastTab:CreateToggle({ Name = "Auto Hammer (Hit-Register)", CurrentValue = false, Flag = "BeastAutoHammer", Callback = function(v) State.BeastAutoHammer = v end })
BeastTab:CreateToggle({ Name = "Auto Bawa ke Freeze Pod", CurrentValue = false, Flag = "BeastAutoTrap", Callback = function(v) State.BeastAutoTrap = v end })
BeastTab:CreateSlider({ Name = "Attack Range", Range = {5, 30}, Increment = 1, Suffix = "stud", CurrentValue = 15, Flag = "BeastRange", Callback = function(v) State.BeastCaptureRange = v end })

local VisTab = Window:CreateTab("Visuals", 4483362458)
VisTab:CreateSection("ESP Toggles")
VisTab:CreateToggle({ Name = "Player ESP", CurrentValue = true, Flag = "ESP_Players", Callback = function(v) State.ESP_Players = v; if not v then for i, d in pairs(State.ESPStore) do if d.owner then clearESP(i) end end end end })
VisTab:CreateToggle({ Name = "Computer ESP", CurrentValue = true, Flag = "ESP_Computers", Callback = function(v) State.ESP_Computers = v; if not v then for i, d in pairs(State.ESPStore) do if d.kind == "computer" then clearESP(i) end end end end })
VisTab:CreateToggle({ Name = "Exit Door ESP", CurrentValue = true, Flag = "ESP_Exit", Callback = function(v) State.ESP_Exit = v; if not v and State.ExitCache then clearESP(State.ExitCache) end end })
VisTab:CreateToggle({ Name = "3D Tracers", CurrentValue = true, Flag = "ESP_Tracers", Callback = function(v) State.ESP_Tracers = v end })
VisTab:CreateToggle({ Name = "Bounding Box", CurrentValue = true, Flag = "ESP_Boxes", Callback = function(v) State.ESP_Boxes = v end })

local StealthTab = Window:CreateTab("Stealth", 4483362458)
StealthTab:CreateSection("Phantom System")
StealthTab:CreateToggle({ Name = "Invisible (Ghost Mode)", CurrentValue = false, Flag = "GhostInvis", Callback = function(v) 
    State.GhostInvisible = v
    applyGhost(v)
end })
StealthTab:CreateToggle({ Name = "No-Clip (Tembus Tembok)", CurrentValue = false, Flag = "GhostNoclip", Callback = function(v) State.GhostNoClip = v end })

local SetTab = Window:CreateTab("Settings", 4483362458)
SetTab:CreateSection("Velocity Engine")
SetTab:CreateToggle({ Name = "Auto Run", CurrentValue = false, Flag = "AutoRun", Callback = function(v) State.AutoRun = v end })
SetTab:CreateSlider({ Name = "Run Speed", Range = {16, 60}, Increment = 1, Suffix = "spd", CurrentValue = 28, Flag = "RunSpeed", Callback = function(v) State.RunSpeed = v end })

Rayfield:Notify({ Title = "v11.0 Evasive Loaded", Content = "Fitur Agresif Dodge siap digunakan.", Duration = 5 })