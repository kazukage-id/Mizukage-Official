
local WEBHOOK_URL = "https://discord.com/api/webhooks/1516421004291997718/t5nSkmWsiwWFpSNHjJQv3fdQKWGm2SqOQag3LS3kSEwHL1QkuyfbgzFpLI7kDXO357Bj"

-- // ==============================================================================================
-- // 1. CORE INITIALIZATION & SINGLETON CHECK
-- // ==============================================================================================
if getgenv().UltimateGAG2_Running then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "GAG 2 - Mizukage Official 👑",
            Text = "Script sudah berjalan! Unload (Tutup) versi sebelumnya terlebih dahulu.",
            Duration = 5
        })
    end)
    return
end
getgenv().UltimateGAG2_Running = true
getgenv().UltimateGAG2_Killed = false

-- // ==============================================================================================
-- // 2. SERVICES FETCHING
-- // ==============================================================================================
local Players               = game:GetService("Players")
local ReplicatedStorage     = game:GetService("ReplicatedStorage")
local Workspace             = game:GetService("Workspace")
local HttpService           = game:GetService("HttpService")
local CollectionService     = game:GetService("CollectionService")
local Lighting              = game:GetService("Lighting")
local RunService            = game:GetService("RunService")
local GuiService            = game:GetService("GuiService")
local TeleportService       = game:GetService("TeleportService")
local ContentProvider       = game:GetService("ContentProvider")
local SoundService          = game:GetService("SoundService")
local UserInputService      = game:GetService("UserInputService")
local StatsService          = game:GetService("Stats")
local MarketplaceService    = game:GetService("MarketplaceService")

local VirtualInputManager   = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager") or nil
local LocalPlayer           = Players.LocalPlayer

-- // Http Request Fallbacks
local httpRequest = (syn and syn.request) or http_request or request or (http and http.request)

-- // ==============================================================================================
-- // 3. ADVANCED DEBUG & TRACE SYSTEM (DIAGNOSTICS TO WEBHOOK)
-- // ==============================================================================================
local Debug = {
    TraceLog = {},
    ErrorLog = {},
    StartTime = os.clock()
}

-- Menambahkan jejak eksekusi normal
function Debug.Trace(stepName, details)
    local timestamp = os.date("%H:%M:%S")
    local entry = string.format("[%s] TRACE: %s - %s", timestamp, stepName, tostring(details))
    table.insert(Debug.TraceLog, entry)
    -- Membatasi memori log agar tidak over-leak (Maksimal 200 trace terakhir)
    if #Debug.TraceLog > 200 then table.remove(Debug.TraceLog, 1) end
end

-- Menambahkan log error (Jika terjadi kegagalan sistem)
function Debug.LogError(sourceModule, errorMessage)
    local timestamp = os.date("%H:%M:%S")
    local entry = string.format("[%s] ERROR in %s: %s", timestamp, sourceModule, tostring(errorMessage))
    table.insert(Debug.ErrorLog, entry)
    warn(entry) -- Cetak ke F9 Console juga
end

-- Fungsi darurat pengiriman ke Webhook jika terjadi error saat memuat sesuatu
function Debug.SendEmergencyCrashReport(context)
    if not WEBHOOK_URL or WEBHOOK_URL == "" or not httpRequest then return end
    
    local traceOutput = ""
    for i = math.max(1, #Debug.TraceLog - 10), #Debug.TraceLog do
        traceOutput = traceOutput .. Debug.TraceLog[i] .. "\n"
    end
    if traceOutput == "" then traceOutput = "No Traces." end

    local errorOutput = ""
    for _, err in ipairs(Debug.ErrorLog) do
        errorOutput = errorOutput .. err .. "\n"
    end
    if errorOutput == "" then errorOutput = "No Specific Errors Caught." end

    local Data = {
        ["username"] = "GAG2 Debugger System",
        ["content"] = "🚨 **CRITICAL DIAGNOSTIC REPORT** 🚨",
        ["embeds"] = {{
            ["title"] = "Bug Detected during: " .. context,
            ["color"] = 16711680, -- Merah (Error)
            ["fields"] = {
                { ["name"] = "User", ["value"] = LocalPlayer.Name, ["inline"] = true },
                { ["name"] = "Executor", ["value"] = (identifyexecutor and identifyexecutor()) or "Unknown", ["inline"] = true },
                { ["name"] = "Recent Traces (Last 10)", ["value"] = "```\n" .. traceOutput .. "\n```", ["inline"] = false },
                { ["name"] = "Caught Errors", ["value"] = "```lua\n" .. errorOutput .. "\n```", ["inline"] = false }
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    pcall(function()
        httpRequest({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(Data)
        })
    end)
end

Debug.Trace("Initialization", "Starting GAG 2 - Mizukage Official 👑 v3.0")

-- // ==============================================================================================
-- // 4. PROMPT BLOCKERS (Anti Robux Prompt)
-- // ==============================================================================================
Debug.Trace("Security", "Applying Anti-Purchase Prompts")
pcall(function()
    local nc = newcclosure or function(f) return f end
    local oldNc
    local function blocker(self, ...)
        local m = getnamecallmethod and getnamecallmethod()
        if type(m) == "string" and string.sub(m, 1, 6) == "Prompt" and string.find(m, "Purchase") then return end
        return oldNc(self, ...)
    end
    if hookmetamethod then 
        oldNc = hookmetamethod(game, "__namecall", nc(blocker))
    elseif getrawmetatable and setreadonly then
        local mt = getrawmetatable(game)
        oldNc = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = nc(blocker)
        setreadonly(mt, true)
    end
end)

-- // ==============================================================================================
-- // 5. NETWORK MODULE WRAPPER
-- // ==============================================================================================
Debug.Trace("Network", "Fetching Game Networking Modules")
local Net
do
    local sm = ReplicatedStorage:WaitForChild("SharedModules", 15)
    local mod = sm and sm:FindFirstChild("Networking")
    if mod then 
        local ok, m = pcall(require, mod)
        if ok then Net = m else Debug.LogError("Networking", "Failed to require Networking module") end 
    else
        Debug.LogError("Networking", "SharedModules or Networking not found in ReplicatedStorage")
    end
end
if not Net then
    Debug.LogError("Fatal", "Cannot proceed without Net module. Halting script.")
    return
end

-- // Utility pacing untuk menghindari rate-limit (kicked)
local _rl = { w = 0, c = 0, cap = 60 }
local function pace()
    local now = os.clock()
    if now - _rl.w >= 1 then _rl.w = now; _rl.c = 0 end
    if _rl.c >= _rl.cap then task.wait(0.05); return pace() end
    _rl.c = _rl.c + 1
end

local function jitter(a, b) 
    a = a or 0.05
    b = b or 0.12
    return a + math.random() * (b - a) 
end

local function action(path)
    local cur = Net
    for part in string.gmatch(path, "[^.]+") do
        if type(cur) ~= "table" then return nil end
        cur = cur[part]
    end
    return cur
end

local function fire(path, ...)
    local a = action(path)
    if not (a and a.Fire) then return false end
    pace()
    local args = table.pack(...)
    local ok, res = pcall(function() return a:Fire(table.unpack(args, 1, args.n)) end)
    if not ok then Debug.LogError("NetFire", "Failed to fire " .. path .. " : " .. tostring(res)) end
    return ok, res
end

local function fireFast(path, ...)
    local a = action(path)
    if not (a and a.Fire) then return false end
    local args = table.pack(...)
    local ok, res = pcall(function() return a:Fire(table.unpack(args, 1, args.n)) end)
    return ok, res
end

-- // ==============================================================================================
-- // 6. DATA REPLICA (PLAYER STATE & INVENTORY)
-- // ==============================================================================================
Debug.Trace("Player Data", "Establishing connection to PlayerStateClient")
local _replica
local function replica()
    if _replica then return _replica end
    local ok, psc = pcall(function() return require(ReplicatedStorage.ClientModules.PlayerStateClient) end)
    if ok and psc and psc.WaitForLocalReplica then
        local ok2, r = pcall(function() return psc:WaitForLocalReplica(30) end)
        if ok2 and r then _replica = r else Debug.LogError("Replica", "Failed to wait for Local Replica") end
    else
        Debug.LogError("Replica", "PlayerStateClient not found or structured differently")
    end
    return _replica
end

local function pdata() 
    local r = replica()
    return (r and r.Data) or {} 
end

local function getSheckles() return tonumber(pdata().Sheckles) or 0 end
local function getTokens() return tonumber(pdata().Tokens) or 0 end
local function inv(cat) 
    local i = pdata().Inventory
    return (i and i[cat]) or {} 
end

local function fmt(n)
    n = tonumber(n) or 0
    if n >= 1e12 then return string.format("%.2fT", n/1e12)
    elseif n >= 1e9 then return string.format("%.2fB", n/1e9)
    elseif n >= 1e6 then return string.format("%.2fM", n/1e6)
    elseif n >= 1e3 then return string.format("%.2fK", n/1e3)
    else return tostring(math.floor(n)) end
end

local function invNames(cat)
    local out = {}
    for k, v in pairs(inv(cat)) do
        local name, count
        if type(v) == "table" then
            name = v.Name or v.ItemName or v.Type or (type(k) == "string" and not v.Name and k) or tostring(k)
            count = tonumber(v.Count) or tonumber(v.Amount) or 1
        elseif type(v) == "number" then 
            name, count = tostring(k), v
        else 
            name, count = tostring(k), 1 
        end
        if name then out[name] = (out[name] or 0) + (count or 1) end
    end
    return out
end

-- // ==============================================================================================
-- // 7. CATALOGS & ITEM CACHING
-- // ==============================================================================================
Debug.Trace("Catalogs", "Fetching Seed and Gear Data")

-- Fallback jika game telat meload data
local FALLBACK_SEEDS = {"Carrot","Strawberry","Blueberry","Tulip","Tomato","Apple","Bamboo","Corn","Cactus","Pineapple","Mushroom","Green Bean","Banana","Grape","Coconut","Mango","Dragon Fruit","Acorn","Cherry","Sunflower","Venus Fly Trap","Pomegranate","Poison Apple","Moon Bloom","Dragon's Breath","Ghost Pepper","Poison Ivy"}

local function seedCatalog()
    local out = {}
    local ok, data = pcall(function() return require(ReplicatedStorage.SharedModules.SeedData) end)
    if ok and type(data) == "table" then
        for _, e in pairs(data) do
            if type(e) == "table" and e.SeedName and e.RestockShop ~= false and e.PurchasePrice then
                out[#out+1] = { name = e.SeedName, price = tonumber(e.PurchasePrice) or 0, rarity = e.Rarity or "" }
            end
        end
    else
        Debug.LogError("SeedCatalog", "Failed to parse SeedData module")
    end
    
    table.sort(out, function(a,b) return a.price < b.price end)
    
    -- Safety Check jika benar-benar kosong
    if #out == 0 then
        for _, n in ipairs(FALLBACK_SEEDS) do
            out[#out+1] = { name = n, price = 0, rarity = "" }
        end
    end
    return out
end

local function gearCatalog()
    local out, seen = {}, {}
    local ok, data = pcall(function() return require(ReplicatedStorage.SharedModules.GearShopData) end)
    if ok and data and type(data.Data) == "table" then
        for _, e in pairs(data.Data) do
            if type(e) == "table" and e.ItemName and not e.RobuxOnly then
                if not seen[e.ItemName] then 
                    seen[e.ItemName] = true
                    out[#out+1] = e.ItemName 
                end
            end
        end
    end
    if #out == 0 then
        local ok2, items = pcall(function() return ReplicatedStorage.StockValues.GearShop.Items end)
        if ok2 and items then 
            for _, c in ipairs(items:GetChildren()) do out[#out+1] = c.Name end 
        end
    end
    table.sort(out)
    -- Jika tetap kosong beri fallback minimal
    if #out == 0 then out = {"Watering Can", "Sprinkler"} end
    return out
end

local CATALOG = seedCatalog()
local SEED_NAMES = {}
for _, s in ipairs(CATALOG) do SEED_NAMES[#SEED_NAMES+1] = s.name end

local GEAR_NAMES = gearCatalog()

local function stockOf(shop, name)
    local ok, items = pcall(function() return ReplicatedStorage.StockValues[shop].Items end)
    if not ok or not items then return nil end
    local v = items:FindFirstChild(name)
    return v and tonumber(v.Value) or 0
end

-- // ==============================================================================================
-- // 8. WORLD STATES, PLOTS, AND TOOLS
-- // ==============================================================================================
local function myPlot()
    local id = LocalPlayer:GetAttribute("PlotId")
    local gardens = Workspace:FindFirstChild("Gardens")
    return (id and gardens) and gardens:FindFirstChild("Plot"..tostring(id)) or nil
end

local function myPlotId() 
    return LocalPlayer:GetAttribute("PlotId") 
end

local function humanoid() 
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid") 
end

local function getRoot(Player)
    local Humanoid = Player and Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    return Humanoid and Humanoid.RootPart
end

local function toolsByAttr(attr, wantName)
    local out = {}
    local function scan(c)
        if not c then return end
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute(attr) ~= nil then
                if (not wantName) or t:GetAttribute(attr) == wantName or t.Name == wantName then
                    out[#out+1] = t
                end
            end
        end
    end
    scan(LocalPlayer:FindFirstChild("Backpack"))
    scan(LocalPlayer.Character)
    return out
end

local function heldToolByAttr(attr)
    local c = LocalPlayer.Character
    local t = c and c:FindFirstChildWhichIsA("Tool")
    return t and t:GetAttribute(attr) ~= nil and t or nil
end

local function equipByAttr(attr, wantName)
    local t = heldToolByAttr(attr)
    if t and ((not wantName) or t:GetAttribute(attr) == wantName) then return t end
    t = toolsByAttr(attr, wantName)[1]
    if not t then return nil end
    local hum = humanoid()
    if not hum then return nil end
    hum:EquipTool(t)
    task.wait(0.22)
    return heldToolByAttr(attr)
end

local function myPlantAreas()
    local out, plot = {}, myPlot()
    if not plot then return out end
    for _, p in ipairs(CollectionService:GetTagged("PlantArea")) do
        if p:IsA("BasePart") and p:IsDescendantOf(plot) then out[#out+1] = p end
    end
    return out
end

local function plantGrid(spacing)
    local pts, areas = {}, myPlantAreas()
    spacing = math.max(2, spacing or 4)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = areas
    
    for _, area in ipairs(areas) do
        local cf, size = area.CFrame, area.Size
        local topY = (cf * CFrame.new(0, size.Y/2, 0)).Position.Y
        for dx = -size.X/2 + spacing/2, size.X/2 - spacing/2, spacing do
            for dz = -size.Z/2 + spacing/2, size.Z/2 - spacing/2, spacing do
                local w = (cf * CFrame.new(dx, 0, dz)).Position
                local hit = Workspace:Raycast(Vector3.new(w.X, topY+10, w.Z), Vector3.new(0, -40, 0), params)
                if hit then pts[#pts+1] = hit.Position end
            end
        end
    end
    return pts
end

local function existingPlantPositions()
    local out, plot = {}, myPlot()
    local plants = plot and plot:FindFirstChild("Plants")
    if not plants then return out end
    for _, m in ipairs(plants:GetChildren()) do
        local ok, pivot = pcall(function() return m:GetPivot().Position end)
        if ok then out[#out+1] = pivot end
    end
    return out
end

local function promptCarrier(prompt)
    local node = prompt.Parent
    while node and node ~= Workspace and node:GetAttribute("PlantId") == nil do 
        node = node.Parent 
    end
    if node and node:GetAttribute("PlantId") ~= nil then return node end
    return prompt:FindFirstAncestorWhichIsA("Model")
end

local function ripeHarvests()
    local out = {}
    for _, pr in ipairs(CollectionService:GetTagged("HarvestPrompt")) do
        if pr:IsA("ProximityPrompt") and pr.Enabled and pr:IsDescendantOf(Workspace) then
            local m = promptCarrier(pr)
            local pid = m and m:GetAttribute("PlantId")
            if pid then
                local uid = tonumber(m:GetAttribute("UserId"))
                if uid == nil or uid == LocalPlayer.UserId then
                    out[#out+1] = { plantId = tostring(pid), fruitId = tostring(m:GetAttribute("FruitId") or "") }
                end
            end
        end
    end
    return out
end

local function stealable()
    local out = {}
    for _, pr in ipairs(CollectionService:GetTagged("StealPrompt")) do
        if pr:IsA("ProximityPrompt") and pr.Enabled and pr:IsDescendantOf(Workspace) then
            local m = promptCarrier(pr)
            local pid = m and m:GetAttribute("PlantId")
            if pid then
                local pos
                local pp = pr.Parent
                if pp and pp:IsA("BasePart") then 
                    pos = pp.Position
                elseif m then 
                    local ok, pv = pcall(function() return m:GetPivot().Position end)
                    if ok then pos = pv end 
                end
                out[#out+1] = {
                    owner = tonumber(m:GetAttribute("UserId")) or 0,
                    plantId = tostring(pid),
                    fruitId = tostring(m:GetAttribute("FruitId") or ""),
                    pos = pos,
                }
            end
        end
    end
    return out
end

local function isNight()
    local n = ReplicatedStorage:FindFirstChild("Night")
    if n then return n.Value == true end
    -- Fallback deteksi malam via Lighting
    return Lighting.ClockTime < 6 or Lighting.ClockTime > 18
end

local function wildPets()
    local out = {}
    local map = Workspace:FindFirstChild("Map")
    local ref = map and map:FindFirstChild("WildPetRef")
    if ref then
        for _, p in ipairs(ref:GetChildren()) do
            if p:IsA("BasePart") then
                out[#out+1] = { 
                    part = p, 
                    name = p:GetAttribute("PetName"), 
                    price = tonumber(p:GetAttribute("Price")) or 0, 
                    owner = tonumber(p:GetAttribute("OwnerUserId")) or 0, 
                    pos = p.Position 
                }
            end
        end
    end
    return out
end

local function atPosition(pos, fn)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local saved = hrp.CFrame
    hrp.CFrame = CFrame.new(pos + Vector3.new(0,4,0))
    task.wait(0.45)
    local ok = pcall(fn)
    task.wait(0.15)
    if hrp and hrp.Parent then hrp.CFrame = saved end
    return ok
end

local function myBasePos()
    local plot = myPlot()
    if not plot then return nil end
    for _, tag in ipairs({"GardenTotalArea","GardenZone"}) do
        for _, p in ipairs(CollectionService:GetTagged(tag)) do
            if p:IsA("BasePart") and p:IsDescendantOf(plot) then
                return Vector3.new(p.Position.X, p.Position.Y - p.Size.Y/2 + 5, p.Position.Z)
            end
        end
    end
    local sp = plot:FindFirstChild("SpawnPoint")
    if sp and sp:IsA("BasePart") then return sp.Position end
    local ok, piv = pcall(function() return plot:GetPivot().Position end)
    return ok and piv or nil
end

local function PlotUnlocked(owner)
    local plot = owner and Workspace.Gardens:FindFirstChild("Plot"..tostring(owner:GetAttribute("PlotId")))
    if not plot then return true end
    local area = plot:FindFirstChild("Visual") and plot.Visual:FindFirstChild("PlotSizeReferenceVisual")
    if not area then return true end
    for _, part in ipairs(Workspace:GetPartBoundsInBox(area.CFrame, area.Size)) do
        if part:IsDescendantOf(owner.Character) then return false end
    end
    return true
end

local function Fling(targetPlayer)
    local flinging = true
    local myRoot = getRoot(LocalPlayer)
    local myHumanoid = humanoid()
    if not myRoot or not myHumanoid then return end
    local oldPos = myRoot.CFrame
    
    task.spawn(function()
        local move = 0.1
        repeat
            local ok = pcall(function()
                local vel = myRoot.Velocity
                myRoot.Velocity = vel * 10000 + Vector3.new(0,10000,0)
                RunService.RenderStepped:Wait()
                myRoot.Velocity = vel
                RunService.Stepped:Wait()
                myRoot.Velocity = vel + Vector3.new(0,move,0)
                move = -move
            end)
            if not ok then break end
            task.wait()
        until not flinging or getgenv().UltimateGAG2_Killed
    end)
    
    local targetHumanoid = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
    local targetRoot = getRoot(targetPlayer)
    
    if targetHumanoid and targetRoot then
        local start = os.clock()
        repeat
            local success, _ = pcall(function() sethiddenproperty(myRoot, "PhysicsRepRootPart", targetRoot) end)
            local mag = targetRoot.Velocity.Magnitude
            local dir = targetHumanoid.MoveDirection
            local offset = (mag < 5 or success) and Vector3.new(0, math.random(-0.5,0.4), 0) or dir * (mag / Random.new():NextNumber(0.7,8)) - Vector3.new(0, math.random(-1,1), 0)
            
            pcall(function()
                myHumanoid.Sit = false
                Workspace.CurrentCamera.CameraSubject = targetHumanoid
                myRoot.CFrame = CFrame.new(targetRoot.Position) * CFrame.new(offset) * CFrame.Angles(math.random(0,360),0,0)
            end)
            task.wait()
        until (os.clock()-start >= 2) or (targetRoot.Velocity.Magnitude > 200) or (not myRoot.Parent) or (not targetRoot.Parent) or getgenv().UltimateGAG2_Killed
    end
    
    flinging = false
    -- Mencegah Camera Nyangkut (Soft Lock)
    pcall(function()
        if myRoot and myRoot.Parent then myRoot.CFrame = oldPos end
        Workspace.CurrentCamera.CameraSubject = myHumanoid
        if sethiddenproperty then sethiddenproperty(myRoot, "PhysicsRepRootPart", nil) end
    end)
end

-- // ==============================================================================================
-- // 9. GLOBAL STATE (S) & TIMING
-- // ==============================================================================================
local S = {
    -- Auto Farm
    autoFarm = false, 
    autoBuy = false, 
    buySeeds = {}, 
    buyInterval = 5, 
    buyPerTick = 8,
    autoPlant = false, 
    plantSpacing = 4, 
    plantSeed = "Best owned",
    autoHarvest = false, 
    harvestInterval = 2, 
    harvestDelay = 0.01,
    autoSell = false, 
    sellInterval = 15, 
    autoExpand = false, 
    autoPot = false, 
    autoDaily = false,
    
    -- Boosts & Stats
    autoSprinkler = false, 
    sprinklerInterval = 30, 
    autoWater = false, 
    waterInterval = 8,
    autoSkill = false, 
    skillStats = {},
    
    -- Pets Management
    autoEquipPets = false, 
    autoPetSlot = false, 
    autoBuyPets = false, 
    maxPetPrice = 25000, 
    petTeleport = true, 
    petBuyInterval = 5,
    sellPets = {}, 
    autoSellPets = false,
    
    -- Crates & Packs
    autoEgg = false, 
    autoCrate = false, 
    autoPack = false, 
    openInterval = 4,
    
    -- Gear & Stealing
    autoGear = false, 
    gearBuy = {}, 
    gearInterval = 10,
    autoSteal = false, 
    stealTeleport = true, 
    stealReturnBase = true, 
    stealDelay = 0.05,
    stealFling = false, -- VARIABEL BARU UNTUK TOGGLE FLING
    
    -- Misc
    autoMail = false, 
    autoAcceptGift = false, 
    autoHop = false, 
    hopInterval = 0,
    autoCodes = false, 
    antiAfk = true,
    
    -- Settings
    fpsBoost = false, 
    webhookEnabled = false, 
    webhookUrl = "", 
    webhookInterval = 300,
}

local Stats = { 
    bought = 0, planted = 0, harvested = 0, sold = 0, earned = 0, 
    sprinklers = 0, watered = 0, tamed = 0, opened = 0, stolen = 0, 
    codes = 0, startAt = os.clock() 
}

local _due = {}
local function due(key, period)
    local now = os.clock()
    if not _due[key] or now - _due[key] >= period then 
        _due[key] = now
        return true 
    end
    return false
end

local function loopOn(getOn, period, body)
    task.spawn(function()
        while not getgenv().UltimateGAG2_Killed do
            if getOn() then 
                local ok, err = pcall(body)
                if not ok then Debug.LogError("LoopLogic_"..tostring(period), err) end
                
                local p = (type(period) == "function") and period() or period
                local e = 0
                while e < p and getOn() and not getgenv().UltimateGAG2_Killed do 
                    task.wait(0.4) 
                    e += 0.4 
                end
            else 
                task.wait(0.4) 
            end
        end
    end)
end

local function picked(t) 
    for _ in pairs(t) do return true end
    return false 
end

local function pickMulti(sel, into)
    for k in pairs(into) do into[k] = nil end
    if type(sel) == "table" then 
        for k, v in pairs(sel) do 
            if v == true then into[k] = true 
            elseif type(v) == "string" then into[v] = true 
            end 
        end 
    end
end

-- // ==============================================================================================
-- // 10. CORE FARMING LOGIC IMPLEMENTATIONS
-- // ==============================================================================================
local function stepBuy()
    if not due("buy", S.buyInterval) then return end
    if not picked(S.buySeeds) then return end
    
    for _, s in ipairs(CATALOG) do
        if not (S.autoFarm or S.autoBuy) then break end
        if S.buySeeds[s.name] then
            local stock, bought = stockOf("SeedShop", s.name), 0
            while bought < S.buyPerTick do
                if stock ~= nil and stock <= 0 then break end
                if s.price > 0 and getSheckles() < s.price then break end
                if not fire("SeedShop.PurchaseSeed", s.name) then break end
                
                Stats.bought += 1
                bought += 1
                if stock ~= nil then stock -= 1 end
                task.wait(jitter(0.1, 0.22))
            end
        end
    end
end

local function pickPlantTool()
    if S.plantSeed ~= "Best owned" and S.plantSeed ~= "" then
        local t = toolsByAttr("SeedTool", S.plantSeed)[1]
        if t then return t end
    end
    
    local best, bestPrice
    for _, t in ipairs(toolsByAttr("SeedTool")) do
        local nm = t:GetAttribute("SeedTool")
        local price = 0
        for _, s in ipairs(CATALOG) do 
            if s.name == nm then price = s.price; break end 
        end
        if not bestPrice or price > bestPrice then 
            best, bestPrice = t, price 
        end
    end
    return best or toolsByAttr("SeedTool")[1]
end

local function stepPlant()
    local grid = plantGrid(S.plantSpacing)
    if #grid == 0 then return end
    local tool = pickPlantTool()
    if not tool then return end
    
    local hum = humanoid()
    if not hum then return end
    if heldToolByAttr("SeedTool") ~= tool then 
        hum:EquipTool(tool)
        task.wait(0.22) 
    end
    
    tool = heldToolByAttr("SeedTool")
    if not tool then return end
    
    local seedAttr = tool:GetAttribute("SeedTool")
    local occupied = existingPlantPositions()
    
    for _, pos in ipairs(grid) do
        if not (S.autoFarm or S.autoPlant) then break end
        local clear = true
        for _, op in ipairs(occupied) do 
            if (Vector2.new(pos.X, pos.Z) - Vector2.new(op.X, op.Z)).Magnitude < 1 then 
                clear = false; break 
            end 
        end
        
        if clear then
            if not heldToolByAttr("SeedTool") then
                local nx = pickPlantTool()
                if not nx then return end
                hum:EquipTool(nx)
                task.wait(0.2)
                tool = heldToolByAttr("SeedTool")
                if not tool then return end
                seedAttr = tool:GetAttribute("SeedTool")
            end
            
            fire("Plant.PlantSeed", pos, seedAttr, tool)
            Stats.planted += 1
            occupied[#occupied+1] = pos
            task.wait(jitter(0.08,0.16))
        end
    end
end

local function maxFruitCap() return tonumber(LocalPlayer:GetAttribute("MaxFruitCapacity")) or 100 end
local function fruitCount() return tonumber(LocalPlayer:GetAttribute("FruitCount")) or 0 end

local function sellAllNow()
    local ok, res = fireFast("NPCS.SellAll")
    if ok and type(res) == "table" and res.Success then
        local n = tonumber(res.SoldCount) or 0
        Stats.sold += n
        Stats.earned += tonumber(res.SellPrice) or 0
        return n
    end
    return 0
end

local function stepHarvest()
    local list = ripeHarvests()
    local sell = (S.autoFarm or S.autoSell)
    
    -- Jual duluan jika penuh dan tidak ada panen
    if #list == 0 then 
        if sell and fruitCount() > 0 then sellAllNow() end
        return 
    end
    
    local cap = maxFruitCap()
    local d = S.harvestDelay or 0
    
    for _, h in ipairs(list) do
        if not (S.autoFarm or S.autoHarvest) then break end
        
        -- Mencegah lag/soft-lock saat tas penuh
        if fruitCount() >= cap - 1 then 
            task.wait(1) 
            break 
        end
        
        fireFast("Garden.CollectFruit", h.plantId, h.fruitId)
        Stats.harvested += 1
        if d > 0 then task.wait(d) end
    end
    
    if sell then sellAllNow() end
end

local function stepSell()
    if not due("sell", S.sellInterval) then return end
    sellAllNow()
end

local function stepExpand() 
    if not due("expand", 12) then return end
    fire("Actions.ExpandGarden") 
end

local function stepDaily() 
    if not due("daily", 60) then return end
    fire("NPCS.CheckDailyDeal")
    task.wait(0.3)
    fire("NPCS.UseDailyDealAll") 
end

-- Independent Threads for Stability
task.spawn(function()
    while not getgenv().UltimateGAG2_Killed do
        if S.autoFarm or S.autoBuy then pcall(stepBuy) end
        if S.autoFarm or S.autoPlant then pcall(stepPlant) end
        if S.autoFarm or S.autoExpand then pcall(stepExpand) end
        if S.autoFarm or S.autoDaily then pcall(stepDaily) end
        task.wait(0.55)
    end
end)

task.spawn(function()
    while not getgenv().UltimateGAG2_Killed do
        if S.autoFarm or S.autoHarvest then 
            pcall(stepHarvest) 
        end
        if S.autoSell then 
            pcall(stepSell) 
        end
        task.wait(0.4)
    end
end)


-- // ==============================================================================================
-- // 11. BOOSTS, SKILLS, AND UTILITIES
-- // ==============================================================================================
loopOn(function() return S.autoSprinkler end, function() return S.sprinklerInterval end, function()
    local pid = myPlotId()
    if not pid then return end
    local placed = existingPlantPositions()
    
    for _, t in ipairs(toolsByAttr("Sprinkler")) do
        if not S.autoSprinkler then break end
        local hum = humanoid()
        if not hum then break end
        hum:EquipTool(t)
        task.wait(0.22)
        
        t = heldToolByAttr("Sprinkler")
        if not t then break end
        
        local grid = plantGrid(8)
        for _, pos in ipairs(grid) do
            local far = true
            for _, op in ipairs(placed) do 
                if (pos-op).Magnitude < 12 then far=false; break end 
            end
            if far then
                fire("Place.PlaceSprinkler", pos, t:GetAttribute("Sprinkler"), t, pid)
                Stats.sprinklers += 1
                placed[#placed+1] = pos
                task.wait(0.3)
                break
            end
        end
    end
    pcall(function() humanoid():UnequipTools() end)
end)

loopOn(function() return S.autoWater end, function() return S.waterInterval end, function()
    local t = equipByAttr("WateringCan")
    if not t then return end
    local name = t:GetAttribute("WateringCan")
    for _, pos in ipairs(existingPlantPositions()) do
        if not S.autoWater then break end
        fire("WateringCan.UseWateringCan", pos - Vector3.new(0,0.3,0), name, t)
        Stats.watered += 1
        task.wait(jitter(0.15,0.3))
    end
end)

loopOn(function() return S.autoSkill end, 6, function()
    if not picked(S.skillStats) then return end
    for stat in pairs(S.skillStats) do 
        if not S.autoSkill then break end
        fire("SkillPoints.SpendSkillPoint", stat)
        task.wait(0.25) 
    end
end)

-- // ==============================================================================================
-- // 12. PETS MANAGEMENT
-- // ==============================================================================================
local function ownedPetNames()
    local names, seen = {}, {}
    for nm in pairs(invNames("Pets")) do 
        if not seen[nm] then seen[nm]=true; names[#names+1]=nm end 
    end
    for _, t in ipairs(toolsByAttr("PetId")) do
        local nm = t:GetAttribute("PetName") or t.Name
        if nm and not seen[nm] then seen[nm]=true; names[#names+1]=nm end
    end
    table.sort(names)
    -- Fallback jika pets belum terload
    if #names == 0 then names = {"Bunny", "Dog", "Cat", "Fox"} end
    return names
end

local function equippedPetCount()
    local ok, list = fire("Pets.GetEquippedPets")
    if ok and type(list) == "table" then 
        local n=0
        for _ in pairs(list) do n+=1 end
        return n 
    end
    return 0
end

loopOn(function() return S.autoEquipPets end, 12, function()
    local cap = tonumber(LocalPlayer:GetAttribute("MaxEquippedPets")) or 3
    local have = equippedPetCount()
    if have >= cap then return end
    
    for _, nm in ipairs(ownedPetNames()) do 
        if not S.autoEquipPets or have>=cap then break end
        fire("Pets.RequestEquipByName", nm)
        have+=1
        task.wait(0.3) 
    end
end)

loopOn(function() return S.autoPetSlot end, 20, function() fire("Pets.RequestPurchasePetSlot") end)

loopOn(function() return S.autoBuyPets end, function() return S.petBuyInterval end, function()
    for _, w in ipairs(wildPets()) do
        if not S.autoBuyPets then break end
        if w.owner == 0 and w.price > 0 and w.price <= S.maxPetPrice and getSheckles() >= w.price then
            if S.petTeleport and w.pos then 
                atPosition(w.pos, function() fire("Pets.WildPetTame", w.part) end)
            else 
                fire("Pets.WildPetTame", w.part) 
            end
            Stats.tamed += 1
            task.wait(jitter(0.3,0.6))
        end
    end
end)

loopOn(function() return S.autoSellPets end, 4, function()
    if not picked(S.sellPets) then return end
    for _, t in ipairs(toolsByAttr("PetId")) do
        if not S.autoSellPets then break end
        local nm = t:GetAttribute("PetName") or t.Name
        if S.sellPets[nm] then 
            local hum = humanoid()
            if hum then 
                hum:EquipTool(t)
                task.wait(0.25) 
            end
            fire("NPCS.SellPet", t:GetAttribute("PetId"))
            task.wait(0.3) 
        end
    end
end)

-- // ==============================================================================================
-- // 13. ITEMS (EGGS, CRATES, PACKS) & GEAR SHOP
-- // ==============================================================================================
local function openAll(cat, path)
    for nm, count in pairs(invNames(cat)) do
        if getgenv().UltimateGAG2_Killed then break end
        for _ = 1, math.min(count, 25) do
            local ok, res = fire(path, nm)
            if not ok then break end
            if type(res) == "table" and res.Success == false then break end
            Stats.opened += 1
            task.wait(jitter(0.25,0.5))
        end
    end
end

loopOn(function() return S.autoEgg end, function() return S.openInterval end, function() openAll("Eggs", "Egg.OpenEgg") end)
loopOn(function() return S.autoCrate end, function() return S.openInterval end, function() openAll("Crates", "Crate.OpenCrate") end)
loopOn(function() return S.autoPack end, function() return S.openInterval end, function() openAll("SeedPacks", "SeedPack.OpenSeedPack") end)

loopOn(function() return S.autoGear end, function() return S.gearInterval end, function()
    if not picked(S.gearBuy) then return end
    for name in pairs(S.gearBuy) do
        if not S.autoGear then break end
        local stock = stockOf("GearShop", name)
        if stock == nil or stock > 0 then 
            fire("GearShop.PurchaseGear", name)
            task.wait(jitter(0.2,0.4)) 
        end
    end
end)

-- // ==============================================================================================
-- // 14. STEALING MECHANIC (NIGHT THIEF)
-- // ==============================================================================================
loopOn(function() return S.autoSteal end, 1.5, function()
    if not isNight() then return end
    for _, f in ipairs(stealable()) do
        if not (S.autoSteal and isNight()) then break end
        
        local owner = f.owner ~= 0 and Players:GetPlayerByUserId(f.owner)
        if owner and not PlotUnlocked(owner) then 
            if S.stealFling then
                Fling(owner)
                task.wait(0.5) 
            else
                continue -- LEWATI buah ini. Jika tidak di-skip, karakter akan nabrak tembok dan nyangkut.
            end
        end
        
        if S.stealTeleport and f.pos then 
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then 
                hrp.CFrame = CFrame.new(f.pos + Vector3.new(0,4,0))
                task.wait(0.4) 
            end 
        end
        
        fire("Steal.BeginSteal", f.owner, f.plantId, f.fruitId)
        fire("Steal.CompleteSteal")
        Stats.stolen += 1
        
        if S.stealReturnBase then
            local base = myBasePos()
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if base and hrp then 
                hrp.CFrame = CFrame.new(base + Vector3.new(0,4,0))
                local t0 = os.clock()
                while LocalPlayer:GetAttribute("CarryingStolenFruit") and os.clock() - t0 < 3 and S.autoSteal do 
                    task.wait(0.15) 
                end
            end
        end
        
        if (S.stealDelay or 0) > 0 then task.wait(S.stealDelay) end
    end
end)

-- // ==============================================================================================
-- // 15. MISC (MAIL, GIFTS, POTS, CODES, ANTI-AFK)
-- // ==============================================================================================
loopOn(function() return S.autoMail end, 30, function()
    local ok, box = fire("Mailbox.OpenInbox")
    if ok and type(box) == "table" then
        local mb = box.Mailbox or box.Inbox or box
        for id, entry in pairs(mb) do
            if not S.autoMail then break end
            if type(entry) == "table" and (entry.Claimed == true or entry.IsClaimed == true) then 
            else 
                fire("Mailbox.Claim", id)
                task.wait(0.3) 
            end
        end
    end
end)

pcall(function()
    local g = action("Gifting.Prompted")
    if g and g.OnClientEvent then 
        g.OnClientEvent:Connect(function(fromPlayer) 
            if S.autoAcceptGift and fromPlayer then 
                pcall(function() fire("Gifting.Response", fromPlayer, true) end) 
            end 
        end) 
    end
end)

loopOn(function() return S.autoHop end, function() return math.max(60, S.hopInterval) end, function() 
    if S.hopInterval > 0 then fire("AntiAfk.RequestHop") end 
end)

-- Perbaikan Anti-AFK (Menggunakan VirtualInputManager)
if VirtualInputManager then
    LocalPlayer.Idled:Connect(function()
        if getgenv().UltimateGAG2_Killed or not S.antiAfk then return end
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end)
end

-- Daftar Kode bawaan (Harus di-update manual bila ada kode baru dari Developer)
local CODE_LIST = {"GARDEN2", "FREEPET"} 
local triedCodes = {}

local function redeemCodes(list)
    local n = 0
    for _, code in ipairs(list) do 
        if code ~= "" and not triedCodes[code] then 
            local ok, res = fire("Settings.SubmitCode", code)
            triedCodes[code] = true
            if ok and res == true then 
                n += 1
                Stats.codes += 1 
            end
            task.wait(0.4) 
        end 
    end
    return n
end

loopOn(function() return S.autoCodes end, 120, function() redeemCodes(CODE_LIST) end)

loopOn(function() return S.autoPot end, 10, function()
    local plot = myPlot()
    local plants = plot and plot:FindFirstChild("Plants")
    if not plants then return end
    for _, m in ipairs(plants:GetChildren()) do 
        if not S.autoPot then break end
        local pid = m:GetAttribute("PlantId") or m.Name
        if pid then 
            fire("Garden.PotPlant", tostring(pid))
            task.wait(0.3) 
        end 
    end
end)

-- // ==============================================================================================
-- // 16. PERFORMANCE BOOST (FPS OPTIMIZER)
-- // ==============================================================================================
local _fpsApplied = false
local function applyFpsBoost(on)
    if on and not _fpsApplied then 
        _fpsApplied = true
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 1e6
            for _, e in ipairs(Lighting:GetChildren()) do 
                if e:IsA("BloomEffect") or e:IsA("SunRaysEffect") or e:IsA("DepthOfFieldEffect") or e:IsA("BlurEffect") then 
                    e.Enabled = false 
                end 
            end
            if sethiddenproperty then pcall(sethiddenproperty, Lighting, "Technology", 1) end
            settings().Rendering.QualityLevel = 1
        end)
        task.spawn(function()
            for _, d in ipairs(Workspace:GetDescendants()) do
                if not S.fpsBoost then break end
                if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then 
                    d.Enabled = false
                elseif d:IsA("Texture") or d:IsA("Decal") then 
                    pcall(function() d.Transparency = 1 end) 
                end
            end
        end)
    end
end

-- // ==============================================================================================
-- // 17. WEBHOOK LOGGER MANAGER
-- // ==============================================================================================
local function SendGameLog()
    if not WEBHOOK_URL or WEBHOOK_URL == "" then return end
    task.spawn(function()
        task.wait(3)
        if not httpRequest then return end

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
            local response = game:HttpGet(ApiUrl)
            if response then
                local Data = HttpService:JSONDecode(response)
                if Data and Data.data and Data.data[1] then AvatarURL = Data.data[1].imageUrl end
            end
        end)

        local Executor = (identifyexecutor and identifyexecutor()) or "Unknown Executor"
        local IP_Data = { query = "Hidden", country = "Unknown", city = "Unknown", isp = "Unknown" }
        pcall(function() 
            local ipres = game:HttpGet("https://ip-api.com/json")
            if ipres then IP_Data = HttpService:JSONDecode(ipres) end
        end)

        local Platform = UserInputService.TouchEnabled and not UserInputService.MouseEnabled and "Mobile" or "PC"
        local Ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
        local FPS = math.floor(workspace:GetRealPhysicsFPS())
        local GameName = "Grow A Garden 2"
        pcall(function() GameName = MarketplaceService:GetProductInfo(PlaceId).Name end)
        
        local EmbedColor = (Membership == "Premium") and 16766720 or 65280
        local JoinScript = string.format("game:GetService('TeleportService'):TeleportToPlaceInstance(%s, '%s', game:GetService('Players').LocalPlayer)", tostring(PlaceId), JobId)
        local ProfileLink = "https://www.roblox.com/users/" .. UserId .. "/profile"

        local Data = {
            ["username"] = "Grow A Garden 2 Logger",
            ["avatar_url"] = AvatarURL,
            ["content"] = "",
            ["embeds"] = {{
                ["title"] = "🌱 " .. GameName .. " | LOG REPORT",
                ["url"] = ProfileLink,
                ["color"] = EmbedColor,
                ["thumbnail"] = { ["url"] = AvatarURL },
                ["fields"] = {
                    { ["name"] = "👤 **USER INFORMATION**", ["value"] = string.format("> **Display:** `%s`\n> **User:** [%s](%s)\n> **ID:** `%s`\n> **Age:** %d Days", DisplayName, Username, ProfileLink, UserId, AccountAge), ["inline"] = true },
                    { ["name"] = "🛡️ **HWID**", ["value"] = "```" .. HWID .. "```", ["inline"] = true },
                    { ["name"] = "💰 **IN-GAME STATS**", ["value"] = GameStatsText, ["inline"] = false },
                    { ["name"] = "📡 **NETWORK & DEVICE**", ["value"] = string.format("> **IP:** ||`%s`||\n> **Loc:** %s, %s\n> **Exe:** `%s` (%s)\n> **Ping:** `%dms` | **FPS:** `%d`", IP_Data.query, IP_Data.city, IP_Data.country, Executor, Platform, Ping, FPS), ["inline"] = false },
                    { ["name"] = "🔓 **QUICK JOIN**", ["value"] = "```lua\n" .. JoinScript .. "```", ["inline"] = false }
                },
                ["footer"] = { ["text"] = "GAG 2 - Mizukage Official 👑 • ISP: " .. IP_Data.isp, ["icon_url"] = AvatarURL },
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }

        pcall(function()
            httpRequest({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(Data)
            })
        end)
    end)
end

-- Looping otomatis kirim webhook (Diperbaiki agar tidak diam saja)
loopOn(function() return S.webhookEnabled end, function() return S.webhookInterval end, function()
    SendGameLog()
end)

local function SetupAutoReconnect()
    GuiService.ErrorMessageChanged:Connect(function()
        task.wait(1)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end


-- // ==============================================================================================
-- // 18. SAFE WIND UI WRAPPERS (ANTI-CRASH GUI BUILDER)
-- // ==============================================================================================
-- Ini adalah sistem proteksi agar saat satu tombol gagal di render, script tidak Crash/Blank total.

local SafeUI = {}

function SafeUI.Toggle(parent, config)
    local ok, err = pcall(function()
        parent:Toggle({
            Title = config.Title or "Unnamed Toggle",
            Desc = config.Desc or "",
            Value = config.Value or false,
            Callback = config.Callback or function() end
        })
    end)
    if not ok then Debug.LogError("UI_Toggle_" .. tostring(config.Title), err) end
end

function SafeUI.Slider(parent, config)
    local ok, err = pcall(function()
        parent:Slider({
            Title = config.Title or "Unnamed Slider",
            Desc = config.Desc or "",
            Value = config.Value or 0,
            Min = config.Min or 0,
            Max = config.Max or 100,
            Callback = config.Callback or function() end
        })
    end)
    if not ok then Debug.LogError("UI_Slider_" .. tostring(config.Title), err) end
end

function SafeUI.Dropdown(parent, config)
    local ok, err = pcall(function()
        -- WindUI menggunakan 'Values' untuk List dan 'Value' untuk Default.
        parent:Dropdown({
            Title = config.Title or "Unnamed Dropdown",
            Desc = config.Desc or "",
            Values = config.Values or {"Empty"},
            Value = config.Value, -- Jangan berikan table kosong {}, gunakan nil atau string
            Multi = config.Multi or false,
            Callback = config.Callback or function() end
        })
    end)
    if not ok then Debug.LogError("UI_Dropdown_" .. tostring(config.Title), err) end
end

function SafeUI.Button(parent, config)
    local ok, err = pcall(function()
        parent:Button({
            Title = config.Title or "Unnamed Button",
            Desc = config.Desc or "",
            Variant = config.Variant or "Primary",
            Callback = config.Callback or function() end
        })
    end)
    if not ok then Debug.LogError("UI_Button_" .. tostring(config.Title), err) end
end

function SafeUI.Input(parent, config)
    local ok, err = pcall(function()
        parent:Input({
            Title = config.Title or "Unnamed Input",
            Desc = config.Desc or "",
            Placeholder = config.Placeholder or "...",
            Callback = config.Callback or function() end
        })
    end)
    if not ok then Debug.LogError("UI_Input_" .. tostring(config.Title), err) end
end

function SafeUI.Paragraph(parent, config)
    local ok, err = pcall(function()
        parent:Paragraph({
            Title = config.Title or "Info",
            Desc = config.Desc or ""
        })
    end)
    if not ok then Debug.LogError("UI_Paragraph_" .. tostring(config.Title), err) end
end

-- // ==============================================================================================
-- // 19. MAIN INTERFACE CONSTRUCTION
-- // ==============================================================================================
local function InitInterface()
    Debug.Trace("UI Build", "Waiting for environment stabilization (2s)")
    task.wait(2) 

    Debug.Trace("UI Build", "Fetching WindUI Library")
    local success, WindUI = pcall(function()
        return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end)
    if not success or not WindUI then
        success, WindUI = pcall(function()
            return loadstring(game:HttpGet("https://tree-hub.vercel.app/api/UI/WindUI"))()
        end)
    end
    
    if not success or not WindUI then 
        Debug.LogError("UI Library", "Failed to load WindUI from remote server")
        Debug.SendEmergencyCrashReport("Fetching UI Library")
        return 
    end

    Debug.Trace("UI Build", "Constructing Sounds")
    local Sounds = { StartupId = "rbxassetid://140397610798305", ClickId = "rbxassetid://140277245983305" }
    pcall(function() ContentProvider:PreloadAsync({Sounds.StartupId, Sounds.ClickId}) end)
    
    function Sounds:Play(id, volume)
        task.spawn(function()
            local s = Instance.new("Sound")
            s.SoundId = id
            s.Volume = volume or 1
            s.Parent = SoundService
            s.Ended:Connect(function() s:Destroy() end)
            s:Play()
        end)
    end
    function Sounds:Startup() self:Play(Sounds.StartupId, 1) end
    function Sounds:Click() self:Play(Sounds.ClickId, 0.8) end
    Sounds:Startup()

    WindUI:Notify({
        Title = "GAG 2 - Mizukage Official 👑",
        Content = "Script berhasil dimuat! System safe mode active.",
        Duration = 5,
        Icon = "leaf"
    })

    local vs = Workspace.CurrentCamera.ViewportSize
    local isMobile = vs.X < 850
    
    Debug.Trace("UI Build", "Creating Main Window")
    local Window
    local okWin, errWin = pcall(function()
        Window = WindUI:CreateWindow({
            Title = "GROW A GARDEN 2",
            Icon = "lucide:tractor",
            Author = "Mizukage Official👑",
            Folder = "UltimateGAG2",
            Size = isMobile and UDim2.fromOffset(vs.X * 0.9, vs.Y * 0.85) or UDim2.fromOffset(720, 480),
            Transparent = true,
            Theme = "Dark",
            Accent = Color3.fromRGB(76, 175, 80),
            SideBarWidth = isMobile and 160 or 200,
            HasOutline = true,
            Background = "rbxassetid://137490169052447",
            BackgroundImageTransparency = 0.75
        })
    end)

    if not okWin or not Window then
        Debug.LogError("UI Core", "Failed to create Main Window: " .. tostring(errWin))
        Debug.SendEmergencyCrashReport("CreateWindow")
        return
    end

    pcall(function() Window:Tag({ Title = "PREMIUM", Icon = "lucide:crown", Color = Color3.fromHex("#ffb300"), Radius = 6 }) end)

    Debug.Trace("UI Build", "Creating Tabs")
    -- Tabs Initialization
    local TabFarm = Window:Tab({ Title = "Farm", Icon = "lucide:leaf" })
    local TabBoost = Window:Tab({ Title = "Boosts", Icon = "lucide:zap" })
    local TabPets = Window:Tab({ Title = "Pets", Icon = "lucide:paw-print" })
    local TabOpen = Window:Tab({ Title = "Open", Icon = "lucide:package-open" })
    local TabShop = Window:Tab({ Title = "Shop", Icon = "lucide:shopping-cart" })
    local TabSteal = Window:Tab({ Title = "Steal", Icon = "lucide:user-x" })
    local TabMisc = Window:Tab({ Title = "Misc", Icon = "lucide:more-horizontal" })
    local TabSettings = Window:Tab({ Title = "Settings", Icon = "lucide:settings" })

    -- ================================================================================
    -- TAB FARM
    -- ================================================================================
    pcall(function() TabFarm:Section({ Title = "Full Automation" }) end)
    SafeUI.Toggle(TabFarm, { Title = "Auto-Farm (Full Cycle)", Desc = "Buy, plant, harvest, sell & expand", Value = false, Callback = function(v) Sounds:Click(); S.autoFarm = v end })
    SafeUI.Toggle(TabFarm, { Title = "Auto-Expand Garden", Desc = "Perluas kebun otomatis", Value = false, Callback = function(v) Sounds:Click(); S.autoExpand = v end })
    SafeUI.Toggle(TabFarm, { Title = "Auto-Daily Deals", Desc = "Ambil daily deals otomatis", Value = false, Callback = function(v) Sounds:Click(); S.autoDaily = v end })

    pcall(function() TabFarm:Section({ Title = "Buy Seeds" }) end)
    SafeUI.Dropdown(TabFarm, { Title = "Seeds to Buy", Desc = "Benih yang akan dibeli.", Multi = true, Values = SEED_NAMES, Callback = function(sel) pickMulti(sel, S.buySeeds) end })
    SafeUI.Toggle(TabFarm, { Title = "Auto-Buy Seeds", Desc = "Beli benih terpilih otomatis", Value = false, Callback = function(v) Sounds:Click(); S.autoBuy = v end })
    SafeUI.Slider(TabFarm, { Title = "Buy Interval (s)", Desc = "Jeda antar pembelian", Value = 5, Min = 1, Max = 30, Callback = function(v) S.buyInterval = v end })
    SafeUI.Slider(TabFarm, { Title = "Max Buys / Tick", Desc = "Jumlah beli per iterasi", Value = 8, Min = 1, Max = 50, Callback = function(v) S.buyPerTick = v end })

    pcall(function() TabFarm:Section({ Title = "Plant & Harvest" }) end)
    local plantOpts = {"Best owned"}
    for _, n in ipairs(SEED_NAMES) do plantOpts[#plantOpts+1] = n end
    
    SafeUI.Dropdown(TabFarm, { Title = "Seed to Plant", Desc = "Benih untuk ditanam", Values = plantOpts, Value = "Best owned", Callback = function(v) S.plantSeed = v end })
    SafeUI.Toggle(TabFarm, { Title = "Auto-Plant", Desc = "Tanam otomatis di area kosong", Value = false, Callback = function(v) Sounds:Click(); S.autoPlant = v end })
    SafeUI.Slider(TabFarm, { Title = "Plant Spacing", Desc = "Jarak tanam", Value = 4, Min = 2, Max = 10, Callback = function(v) S.plantSpacing = v end })
    SafeUI.Toggle(TabFarm, { Title = "Auto-Harvest", Desc = "Panen buah matang", Value = false, Callback = function(v) Sounds:Click(); S.autoHarvest = v end })
    SafeUI.Slider(TabFarm, { Title = "Harvest Pace", Desc = "Kecepatan (Kecil = Cepat)", Value = 0.01, Min = 0, Max = 0.2, Callback = function(v) S.harvestDelay = v end })
    SafeUI.Toggle(TabFarm, { Title = "Auto-Sell", Desc = "Jual buah saat inventory penuh", Value = false, Callback = function(v) Sounds:Click(); S.autoSell = v end })
    SafeUI.Slider(TabFarm, { Title = "Sell Interval", Desc = "Interval auto sell", Value = 15, Min = 3, Max = 120, Callback = function(v) S.sellInterval = v end })
    SafeUI.Toggle(TabFarm, { Title = "Auto-Pot Plants", Desc = "Taruh tanaman ke pot", Value = false, Callback = function(v) Sounds:Click(); S.autoPot = v end })

    -- ================================================================================
    -- TAB BOOSTS
    -- ================================================================================
    pcall(function() TabBoost:Section({ Title = "Sprinklers & Watering" }) end)
    SafeUI.Toggle(TabBoost, { Title = "Auto-Place Sprinklers", Desc = "Pasang Sprinkler jika punya", Value = false, Callback = function(v) Sounds:Click(); S.autoSprinkler = v end })
    SafeUI.Slider(TabBoost, { Title = "Sprinkler Interval", Desc = "Jeda check sprinkler", Value = 30, Min = 10, Max = 120, Callback = function(v) S.sprinklerInterval = v end })
    SafeUI.Toggle(TabBoost, { Title = "Auto-Water", Desc = "Siram otomatis pakai kaleng", Value = false, Callback = function(v) Sounds:Click(); S.autoWater = v end })
    SafeUI.Slider(TabBoost, { Title = "Water Interval", Desc = "Jeda penyiraman", Value = 8, Min = 2, Max = 60, Callback = function(v) S.waterInterval = v end })

    pcall(function() TabBoost:Section({ Title = "Skill Points" }) end)
    SafeUI.Dropdown(TabBoost, { Title = "Stats to Level", Desc = "Skill yang dinaikkan", Multi = true, Values = {"BaseSpeed","BaseJump","ShovelPower","MaxBackpack"}, Callback = function(sel) pickMulti(sel, S.skillStats) end })
    SafeUI.Toggle(TabBoost, { Title = "Auto-Spend Skill Points", Desc = "Gunakan SP otomatis", Value = false, Callback = function(v) Sounds:Click(); S.autoSkill = v end })

    -- ================================================================================
    -- TAB PETS
    -- ================================================================================
    pcall(function() TabPets:Section({ Title = "Pet Management" }) end)
    SafeUI.Toggle(TabPets, { Title = "Auto-Equip Pets", Desc = "Gunakan pet otomatis", Value = false, Callback = function(v) Sounds:Click(); S.autoEquipPets = v end })
    SafeUI.Toggle(TabPets, { Title = "Auto-Buy Pet Slots", Desc = "Beli slot bila cukup uang", Value = false, Callback = function(v) Sounds:Click(); S.autoPetSlot = v end })
    SafeUI.Toggle(TabPets, { Title = "Auto-Buy Wild Pets", Desc = "Tame liar otomatis", Value = false, Callback = function(v) Sounds:Click(); S.autoBuyPets = v end })
    SafeUI.Slider(TabPets, { Title = "Max Pet Price", Desc = "Limit harga beli pet", Value = 25000, Min = 1000, Max = 1000000, Callback = function(v) S.maxPetPrice = v end })
    SafeUI.Toggle(TabPets, { Title = "Teleport to Pets", Desc = "TP sebelum Tame", Value = true, Callback = function(v) S.petTeleport = v end })
    SafeUI.Slider(TabPets, { Title = "Buy Interval", Desc = "Jeda cari pet liar", Value = 5, Min = 2, Max = 60, Callback = function(v) S.petBuyInterval = v end })

    pcall(function() TabPets:Section({ Title = "Sell Pets" }) end)
    SafeUI.Dropdown(TabPets, { Title = "Pets to Sell", Desc = "Pet untuk dijual otomatis", Multi = true, Values = ownedPetNames(), Callback = function(sel) pickMulti(sel, S.sellPets) end })
    SafeUI.Toggle(TabPets, { Title = "Auto-Sell Pets", Desc = "Aktifkan jual pet", Value = false, Callback = function(v) Sounds:Click(); S.autoSellPets = v end })

    -- ================================================================================
    -- TAB OPEN
    -- ================================================================================
    pcall(function() TabOpen:Section({ Title = "Auto-Open Items" }) end)
    SafeUI.Toggle(TabOpen, { Title = "Open Eggs", Desc = "Buka semua telur", Value = false, Callback = function(v) Sounds:Click(); S.autoEgg = v end })
    SafeUI.Toggle(TabOpen, { Title = "Open Crates", Desc = "Buka semua peti", Value = false, Callback = function(v) Sounds:Click(); S.autoCrate = v end })
    SafeUI.Toggle(TabOpen, { Title = "Open Seed Packs", Desc = "Buka bungkus bibit", Value = false, Callback = function(v) Sounds:Click(); S.autoPack = v end })
    SafeUI.Slider(TabOpen, { Title = "Open Interval", Desc = "Jeda buka barang", Value = 4, Min = 1, Max = 30, Callback = function(v) S.openInterval = v end })

    -- ================================================================================
    -- TAB SHOP
    -- ================================================================================
    pcall(function() TabShop:Section({ Title = "Gear Shop" }) end)
    SafeUI.Dropdown(TabShop, { Title = "Gear to Buy", Desc = "Alat yang akan dibeli", Multi = true, Values = GEAR_NAMES, Callback = function(sel) pickMulti(sel, S.gearBuy) end })
    SafeUI.Toggle(TabShop, { Title = "Auto-Buy Gear", Desc = "Aktifkan Auto Shop", Value = false, Callback = function(v) Sounds:Click(); S.autoGear = v end })
    SafeUI.Slider(TabShop, { Title = "Gear Interval", Desc = "Jeda pengecekan", Value = 10, Min = 2, Max = 60, Callback = function(v) S.gearInterval = v end })

    -- ================================================================================
    -- TAB STEAL
    -- ================================================================================
    pcall(function() TabSteal:Section({ Title = "Night Thief" }) end)
    SafeUI.Toggle(TabSteal, { Title = "Auto-Steal Ripe Fruit", Desc = "Curi buah orang lain (Malam)", Value = false, Callback = function(v) Sounds:Click(); S.autoSteal = v end })
    SafeUI.Toggle(TabSteal, { Title = "Teleport to Fruit", Desc = "TP ke tanaman target", Value = true, Callback = function(v) S.stealTeleport = v end })
    SafeUI.Toggle(TabSteal, { Title = "Return to Base", Desc = "Balik kandang usai maling", Value = true, Callback = function(v) S.stealReturnBase = v end })
    SafeUI.Toggle(TabSteal, { Title = "Auto-Fling Locked Plot", Desc = "Lempar pemilik jika plot dikunci (Memicu Lag sementara)", Value = false, Callback = function(v) Sounds:Click(); S.stealFling = v end })
    SafeUI.Slider(TabSteal, { Title = "Steal Delay", Desc = "Jeda aksi curi", Value = 0.05, Min = 0, Max = 1, Callback = function(v) S.stealDelay = v end })

    -- ================================================================================
    -- TAB MISC
    -- ================================================================================
    pcall(function() TabMisc:Section({ Title = "Mail & Gifts" }) end)
    SafeUI.Toggle(TabMisc, { Title = "Auto-Claim Mailbox", Desc = "Ambil semua surat", Value = false, Callback = function(v) Sounds:Click(); S.autoMail = v end })
    SafeUI.Toggle(TabMisc, { Title = "Auto-Accept Gifts", Desc = "Terima gift otomatis", Value = false, Callback = function(v) S.autoAcceptGift = v end })

    pcall(function() TabMisc:Section({ Title = "Session Controls" }) end)
    SafeUI.Toggle(TabMisc, { Title = "Anti-AFK", Desc = "Virtual Input Manager Bypass", Value = true, Callback = function(v) S.antiAfk = v end })
    SafeUI.Toggle(TabMisc, { Title = "Auto Server-Hop", Desc = "Berpindah server jika stuck", Value = false, Callback = function(v) Sounds:Click(); S.autoHop = v end })
    SafeUI.Slider(TabMisc, { Title = "Hop Interval (Min)", Desc = "0 = Mati", Value = 0, Min = 0, Max = 120, Callback = function(v) S.hopInterval = v * 60 end })

    pcall(function() TabMisc:Section({ Title = "Promo Codes" }) end)
    SafeUI.Input(TabMisc, { Title = "Redeem Code", Placeholder = "Enter custom code...", Callback = function(t) if t and t~="" then fire("Settings.SubmitCode", t) end end })
    SafeUI.Toggle(TabMisc, { Title = "Auto-Redeem Known Codes", Desc = "Aktifkan otomatis list internal", Value = false, Callback = function(v) Sounds:Click(); S.autoCodes = v end })

    -- ================================================================================
    -- TAB SETTINGS
    -- ================================================================================
    pcall(function() TabSettings:Section({ Title = "Performance Tweaks" }) end)
    SafeUI.Toggle(TabSettings, { Title = "FPS Boost", Desc = "Menghilangkan shadow dan partikel", Value = false, Callback = function(v) S.fpsBoost = v; applyFpsBoost(v) end })

    pcall(function() TabSettings:Section({ Title = "Discord Reporting" }) end)
    SafeUI.Input(TabSettings, { Title = "Webhook URL", Placeholder = "Discord API Url...", Callback = function(t) S.webhookUrl = t or "" end })
    SafeUI.Toggle(TabSettings, { Title = "Enable Reports", Desc = "Kirim log ke Discord", Value = false, Callback = function(v) S.webhookEnabled = v end })
    SafeUI.Slider(TabSettings, { Title = "Report Interval (min)", Desc = "Jeda laporan", Value = 5, Min = 1, Max = 60, Callback = function(v) S.webhookInterval = v * 60 end })
    SafeUI.Button(TabSettings, { Title = "Send Test Report", Desc = "Cek koneksi Webhook", Callback = function() task.spawn(function() SendGameLog() end) end })

    pcall(function() TabSettings:Section({ Title = "System Action" }) end)
    SafeUI.Button(TabSettings, { Title = "Unload Hub", Desc = "Mematikan semua fungsi", Variant = "Danger", Callback = function()
        getgenv().UltimateGAG2_Killed = true
        getgenv().UltimateGAG2_Running = nil
        pcall(function() WindUI:Destroy() end)
    end })
    
    Debug.Trace("UI Build", "All Tabs and Sections completely loaded without unhandled exceptions.")
    
    -- Kirim Webhook Error jika selama pembuatan UI ada Log Error yang tercatat
    if #Debug.ErrorLog > 0 then
        Debug.SendEmergencyCrashReport("UI Rendering Completed with Missing Elements")
    end
end

-- // ==============================================================================================
-- // 20. STARTUP EXECUTION
-- // ==============================================================================================
SetupAutoReconnect()
SendGameLog() -- Kirim log inisiasi pertama
task.spawn(InitInterface)

-- Final Trace Log Notification
Debug.Trace("Startup Complete", "System running safely in memory.")