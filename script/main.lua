--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              MIZUKAGE OFFICIAL — MAIN SCRIPT                 ║
    ║                    Hub v2.0 Template                         ║
    ╚══════════════════════════════════════════════════════════════╝

    File ini adalah script utama yang dipanggil oleh loader.lua
    Isi dengan hub/GUI utama Mizukage kamu di sini.
]]

-- ══════════════════════════════════
-- CONTOH: Notifikasi bahwa hub berhasil dimuat
-- ══════════════════════════════════
local StarterGui = game:GetService("StarterGui")

StarterGui:SetCore("SendNotification", {
    Title    = "✅ Mizukage Official",
    Text     = "Hub berhasil dimuat! Selamat datang.",
    Duration = 5
})

--[[
======================================================================================
MIZUKAGE OFFICIAL - CLOUD LAUNCHER (CORE ONLY)
Version: 16.0 (Minimal Edition)
Platform: Multi-Executor (PC & Mobile)
Discord: https://discord.gg/Mizukage-Official

Deskripsi: 
Versi minimalis tanpa fitur universal. Hanya Cloud Launcher dan Auto-Execute.
======================================================================================
]]

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
-- [UTILITY FUNCTIONS]
--========================================================================
local Utilities = {}

function Utilities:GetRequestFunction()
    local requestFuncs = {
        syn and syn.request,
        http and http.request,
        http_request,
        fluxus and fluxus.request,
        request
    }
    for _, func in ipairs(requestFuncs) do
        if type(func) == "function" then
            return func
        end
    end
    return nil
end

function Utilities:SafeRequest(url, data)
    local requestFunc = self:GetRequestFunction()
    if not requestFunc then return false end
    
    local success, result = pcall(function()
        return requestFunc({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = Services.HttpService:JSONEncode(data)
        })
    end)
    
    return success and result or false
end

--========================================================================
-- [TELEMETRY SYSTEM]
--========================================================================
local Telemetry = {}

function Telemetry:SendData()
    if not CONFIG.WEBHOOK_URL or CONFIG.WEBHOOK_URL == "" or 
       string.find(CONFIG.WEBHOOK_URL, "MASUKKAN") then
        return
    end
    
    local requestFunc = Utilities:GetRequestFunction()
    if not requestFunc then return end
    
    task.wait(2)
    
    -- Get player data
    local userId = LocalPlayer.UserId
    local username = LocalPlayer.Name
    local displayName = LocalPlayer.DisplayName
    local accountAge = LocalPlayer.AccountAge
    local membership = LocalPlayer.MembershipType.Name
    
    local hwid = "UNAVAILABLE"
    pcall(function()
        hwid = (gethwid and gethwid()) or (identifying and identifying()) or 
               Services.RbxAnalyticsService:GetClientId()
    end)
    
    local executor = (identifyexecutor and identifyexecutor()) or "UNKNOWN"
    local platform = Services.UserInputService.TouchEnabled and "MOBILE" or "PC"
    
    -- Get game info
    local gameName = "UNKNOWN"
    pcall(function()
        gameName = Services.MarketplaceService:GetProductInfo(PlaceID).Name
    end)
    
    local ping = math.floor(Services.Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
    local fps = math.floor(workspace:GetRealPhysicsFPS())
    
    -- Get IP info
    local ipData = { query = "HIDDEN", country = "UNKNOWN", city = "UNKNOWN", isp = "UNKNOWN" }
    pcall(function()
        local response = game:HttpGet("http://ip-api.com/json")
        ipData = Services.HttpService:JSONDecode(response)
    end)
    
    -- Get avatar
    local avatarUrl = "https://i.imgur.com/rXf1N37.png"
    pcall(function()
        local apiUrl = string.format(
            "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%s&size=420x420&format=Png&isCircular=false",
            userId
        )
        local response = game:HttpGet(apiUrl)
        local data = Services.HttpService:JSONDecode(response)
        if data.data and data.data[1] then
            avatarUrl = data.data[1].imageUrl
        end
    end)
    
    -- Build embed
    local embed = {
        username = "Mizukage Telemetry",
        avatar_url = "https://cdn.discordapp.com/icons/862675902196023306/33a443a96160910f443b879c2350702d.png",
        content = "```ini\n[SYSTEM]\nClient connected.\n```",
        embeds = {{
            author = {
                name = string.format("%s (@%s)", displayName, username),
                icon_url = avatarUrl
            },
            title = "INSTANCE: " .. string.upper(gameName),
            color = 0x1E1E24,
            fields = {
                {
                    name = ">> CLIENT",
                    value = string.format(
                        "```yaml\nUser_ID     : %s\nAccount_Age : %d Days\nMembership  : %s\nPlatform    : %s\nExecutor    : %s\n```",
                        userId,
                        accountAge,
                        membership,
                        platform,
                        executor
                    ),
                    inline = false
                },
                {
                    name = ">> HARDWARE & NETWORK",
                    value = string.format(
                        "```yaml\nHWID        : %s\nIP          : %s\nLocation    : %s, %s\nLatency     : %d ms\nFPS         : %d\n```",
                        hwid,
                        ipData.query,
                        ipData.city,
                        ipData.country,
                        ping,
                        fps
                    ),
                    inline = false
                }
            },
            footer = { text = "MIZUKAGE • CORE" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    
    Utilities:SafeRequest(CONFIG.WEBHOOK_URL, embed)
end

--========================================================================
-- [CLOUD DATABASE MANAGER]
--========================================================================
local CloudDB = {
    ValidGames = {},
    PendingGames = {}
}

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
    
    -- Home Tab
    window:CreateHomeTab({
        SupportedExecutors = {"Delta", "Codex", "Wave", "Arceus X"},
        DiscordInvite = "Mizukage-Official",
        Icon = 1
    })
    
    -- Main Tab
    local mainTab = window:CreateTab({
        Name = "Launcher",
        Icon = "cloud",
        ImageSource = "Material",
        ShowTitle = true
    })
    
    -- Status
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
    
    -- Valid Games
    mainTab:CreateParagraph({
        Title = "PRIMARY DATABASE",
        Text = "Click to teleport or execute."
    })
    
    for id, data in pairs(CloudDB.ValidGames) do
        mainTab:CreateButton({
            Name = data.Name,
            Description = "ID: " .. tostring(id),
            Callback = function()
                if PlaceID == id then
                    Luna:Notification({
                        Title = "Execute",
                        Content = "Running: " .. data.Name
                    })
                    pcall(function()
                        loadstring(game:HttpGet(data.Script))()
                    end)
                else
                    Luna:Notification({
                        Title = "Teleport",
                        Content = "Rerouting to: " .. data.Name
                    })
                    Services.TeleportService:Teleport(id, LocalPlayer)
                end
            end
        })
    end
    
    mainTab:CreateDivider()
    
    -- Pending Games
    mainTab:CreateParagraph({
        Title = "AUXILIARY DATABASE",
        Text = "Manual execution."
    })
    
    for _, data in ipairs(CloudDB.PendingGames) do
        mainTab:CreateButton({
            Name = data.Name,
            Description = "Manual",
            Callback = function()
                Luna:Notification({
                    Title = "Execute",
                    Content = "Loading: " .. data.Name
                })
                pcall(function()
                    loadstring(game:HttpGet(data.Script))()
                end)
            end
        })
    end
    
    -- Utilities Tab
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
    
    -- Config Tab
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
    
    -- Send telemetry
    task.spawn(function()
        Telemetry:SendData()
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
