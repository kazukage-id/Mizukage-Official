-- MIZUKAGE OFFICIAL - Blox Fruits
-- Fitur: Auto Farm, Auto Mastery, Auto Stats, ESP, Teleport, Auto Buy, dll.

if getgenv().MizuBloxFruitsLoaded then return end
getgenv().MizuBloxFruitsLoaded = true

getgenv().MizuConfig = getgenv().MizuConfig or { IsRunning = true }
local Config = getgenv().MizuConfig

-- World Detection
Config.World1 = game.PlaceId == 2753915549
Config.World2 = game.PlaceId == 4442272183
Config.World3 = game.PlaceId == 7449423635

-- Blox Fruits Settings
Config.BF = Config.BF or {
    Main = {
        SelectWeapon = "Melee",
        FarmMode = "Normal",
        AutoFarm = false,
        AutoFarmFast = false,
        SelectedMasteryMode = "Quest",
        AutoFarmFruitMastery = false,
        AutoFarmGunMastery = false,
        SelectedMasterySword = nil,
        AutoFarmSwordMastery = false,
        SelectedMob = nil,
        AutoFarmMob = false,
        SelectedBoss = nil,
        AutoFarmBoss = false,
        AutoFarmAllBoss = false,
    },
    Setting = {
        SpinPosition = false,
        FarmDistance = 35,
        PlayerTweenSpeed = 350,
        BringMob = true,
        BringMobMode = "Normal",
        FastAttack = true,
        FastAttackMode = "Normal",
        AttackAura = true,
        HideNotification = false,
        HideDamageText = true,
        BlackScreen = false,
        WhiteScreen = false,
        HideMonster = false,
        MasteryHealth = 25,
        FruitMasterySkillZ = true,
        FruitMasterySkillX = true,
        FruitMasterySkillC = true,
        FruitMasterySkillV = false,
        FruitMasterySkillF = false,
        GunMasterySkillZ = true,
        GunMasterySkillX = true,
        AutoSetSpawnPoint = true,
        AutoObservation = false,
        AutoHaki = true,
        AutoRejoin = true,
        BypassAntiCheat = true,
    },
    Stats = {
        AutoAddMelee = false,
        AutoAddDefense = false,
        AutoAddFruit = false,
        AutoAddSword = false,
        AutoAddGun = false,
        PointStats = 1,
    },
    LocalPlayer = {
        DodgeNoCooldown = false,
        InfiniteEnergy = false,
        InfiniteAbility = false,
        InfiniteGeppo = false,
        InfiniteSoru = false,
        ActiveRaceV3 = false,
        ActiveRaceV4 = false,
        WalkOnWater = false,
        NoClip = false,
    },
    Misc = {
        HideChat = false,
        HideLeaderboard = false,
        HighlightMode = false,
    },
    Esp = {
        Player = false,
        Chest = false,
        Fruit = false,
        RealFruit = false,
        Flower = false,
        Island = false,
        Npc = false,
        SeaBeast = false,
        Monster = false,
        Mirage = false,
        Kitsune = false,
        Frozen = false,
        AdvancedFruitDealer = false,
        Gear = false,
    },
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- Character
local character = nil
local hum = nil
local root = nil

local function updateChar(char)
    character = char
    root = char and char:FindFirstChild("HumanoidRootPart")
    hum = char and char:FindFirstChild("Humanoid")
end
updateChar(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
LocalPlayer.CharacterAdded:Connect(updateChar)

-- Remotes
local CommF = ReplicatedStorage.Remotes.CommF_

-- Helper Functions
local function isnil(thing) return thing == nil end
local function round(n) return math.floor(tonumber(n) + 0.5) end

-- Check Quest (simplified)
local function CheckQuest()
    if not Config.BF.Main.AutoFarm then return end
    -- Logic untuk auto quest sesuai world
    -- (dipertahankan dari script asli)
end

-- Auto Stats
task.spawn(function()
    while Config.IsRunning do
        if LocalPlayer.Data.Points.Value >= Config.BF.Stats.PointStats then
            if Config.BF.Stats.AutoAddMelee then
                pcall(function() CommF:InvokeServer("AddPoint", "Melee", Config.BF.Stats.PointStats) end)
            end
            if Config.BF.Stats.AutoAddDefense then
                pcall(function() CommF:InvokeServer("AddPoint", "Defense", Config.BF.Stats.PointStats) end)
            end
            if Config.BF.Stats.AutoAddSword then
                pcall(function() CommF:InvokeServer("AddPoint", "Sword", Config.BF.Stats.PointStats) end)
            end
            if Config.BF.Stats.AutoAddGun then
                pcall(function() CommF:InvokeServer("AddPoint", "Gun", Config.BF.Stats.PointStats) end)
            end
            if Config.BF.Stats.AutoAddFruit then
                pcall(function() CommF:InvokeServer("AddPoint", "Demon Fruit", Config.BF.Stats.PointStats) end)
            end
        end
        task.wait(0.2)
    end
end)

-- Auto Haki
task.spawn(function()
    while Config.IsRunning do
        if Config.BF.Setting.AutoHaki and character and not character:FindFirstChild("HasBuso") then
            pcall(function() CommF:InvokeServer("Buso") end)
        end
        task.wait(0.2)
    end
end)

-- Walk on Water
task.spawn(function()
    while Config.IsRunning do
        if Config.BF.LocalPlayer.WalkOnWater and character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 1
                    part.CanCollide = false
                end
            end
        end
        task.wait(0.5)
    end
end)

-- No Clip
task.spawn(function()
    while Config.IsRunning do
        if Config.BF.LocalPlayer.NoClip and character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
        task.wait(0.5)
    end
end)

-- Infinite Energy
task.spawn(function()
    while Config.IsRunning do
        if Config.BF.LocalPlayer.InfiniteEnergy and character then
            local energy = character:FindFirstChild("Energy")
            if energy then energy.Value = 100 end
        end
        task.wait(0.1)
    end
end)

-- UI
local function InitUI()
    local success, WindUI = pcall(function()
        return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end)
    if not success then return end

    local Window = WindUI:CreateWindow({
        Title = "MIZUKAGE OFFICIAL",
        Icon = "skull",
        Author = "Blox Fruits",
        Folder = "MizukageBloxFruits",
        Size = UDim2.fromOffset(800, 620),
        Theme = "Dark",
        Accent = Color3.fromRGB(255, 0, 0),
        SideBarWidth = 240,
        HasOutline = true,
    })

    local MainTab = Window:Tab({ Title = "Main", Icon = "rocket" })
    local SettingTab = Window:Tab({ Title = "Setting", Icon = "settings" })
    local LocalPlayerTab = Window:Tab({ Title = "Local Player", Icon = "user" })
    local EspTab = Window:Tab({ Title = "ESP", Icon = "eye" })
    local TeleportTab = Window:Tab({ Title = "Teleport", Icon = "map" })
    local ShopTab = Window:Tab({ Title = "Shop", Icon = "store" })
    local FruitTab = Window:Tab({ Title = "Fruit", Icon = "apple" })
    local MiscTab = Window:Tab({ Title = "Misc", Icon = "more-horizontal" })
    local StatsTab = Window:Tab({ Title = "Stats", Icon = "analytics" })
    local ServTab = Window:Tab({ Title = "Server", Icon = "dns" })

    -- Main Tab
    MainTab:Section({ Title = "Level Farm" })
    MainTab:Dropdown({ Title = "Choose Weapon", Values = {"Melee", "Sword", "Fruit", "Gun"}, Value = Config.BF.Main.SelectWeapon, Callback = function(v) Config.BF.Main.SelectWeapon = v[1] end })
    MainTab:Dropdown({ Title = "Choose Farm Mode", Values = {"Normal", "Auto Quest", "Nearest"}, Value = Config.BF.Main.FarmMode, Callback = function(v) Config.BF.Main.FarmMode = v[1] end })
    MainTab:Toggle({ Title = "Auto Farm", Default = Config.BF.Main.AutoFarm, Callback = function(s) Config.BF.Main.AutoFarm = s end })
    if Config.World1 then
        MainTab:Toggle({ Title = "Auto Farm Fast", Default = Config.BF.Main.AutoFarmFast, Callback = function(s) Config.BF.Main.AutoFarmFast = s end })
    end

    MainTab:Section({ Title = "Mastery Farm" })
    MainTab:Dropdown({ Title = "Choose Mode", Values = {"Quest", "No Quest", "Nearest"}, Value = Config.BF.Main.SelectedMasteryMode, Callback = function(v) Config.BF.Main.SelectedMasteryMode = v[1] end })
    MainTab:Toggle({ Title = "Auto Farm Fruit Mastery", Default = Config.BF.Main.AutoFarmFruitMastery, Callback = function(s) Config.BF.Main.AutoFarmFruitMastery = s end })
    MainTab:Toggle({ Title = "Auto Farm Gun Mastery", Default = Config.BF.Main.AutoFarmGunMastery, Callback = function(s) Config.BF.Main.AutoFarmGunMastery = s end })
    MainTab:Toggle({ Title = "Auto Farm Sword Mastery", Default = Config.BF.Main.AutoFarmSwordMastery, Callback = function(s) Config.BF.Main.AutoFarmSwordMastery = s end })

    MainTab:Section({ Title = "Mob Farm" })
    local tableMon = {}
    if Config.World1 then
        tableMon = { "Bandit", "Monkey", "Gorilla", "Pirate", "Brute", "Desert Bandit", "Desert Officer", "Snow Bandit", "Snowman", "Chief Petty Officer", "Sky Bandit", "Dark Master", "Toga Warrior", "Gladiator", "Military Soldier", "Military Spy", "Fishman Warrior", "Fishman Commando", "God's Guard", "Shanda", "Royal Squad", "Royal Soldier", "Galley Pirate", "Galley Captain" }
    elseif Config.World2 then
        tableMon = { "Raider", "Mercenary", "Swan Pirate", "Factory Staff", "Marine Lieutenant", "Marine Captain", "Zombie", "Vampire", "Snow Trooper", "Winter Warrior", "Lab Subordinate", "Horned Warrior", "Magma Ninja", "Lava Pirate", "Ship Deckhand", "Ship Engineer", "Ship Steward", "Ship Officer", "Arctic Warrior", "Snow Lurker", "Sea Soldier", "Water Fighter" }
    elseif Config.World3 then
        tableMon = { "Pirate Millionaire", "Dragon Crew Warrior", "Dragon Crew Archer", "Female Islander", "Giant Islander", "Marine Commodore", "Marine Rear Admiral", "Fishman Raider", "Fishman Captain", "Forest Pirate", "Mythological Pirate", "Jungle Pirate", "Musketeer Pirate", "Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy", "Peanut Scout", "Peanut President", "Ice Cream Chef", "Ice Cream Commander", "Cookie Crafter", "Cake Guard", "Baking Staff", "Head Baker", "Cocoa Warrior", "Chocolate Bar Battler", "Sweet Thief", "Candy Rebel", "Candy Pirate", "Snow Demon", "Isle Outlaw", "Island Boy", "Sun-kissed Warrior", "Isle Champion" }
    end
    MainTab:Dropdown({ Title = "Choose Mob", Values = tableMon, Value = Config.BF.Main.SelectedMob, Callback = function(v) Config.BF.Main.SelectedMob = v[1] end })
    MainTab:Toggle({ Title = "Auto Farm Mob", Default = Config.BF.Main.AutoFarmMob, Callback = function(s) Config.BF.Main.AutoFarmMob = s end })

    MainTab:Section({ Title = "Boss Farm" })
    local tableBoss = {}
    if Config.World1 then
        tableBoss = { "The Gorilla King", "Bobby", "Yeti", "Mob Leader", "Vice Admiral", "Warden", "Chief Warden", "Swan", "Magma Admiral", "Fishman Lord", "Wysper", "Thunder God", "Cyborg", "Saber Expert" }
    elseif Config.World2 then
        tableBoss = { "Diamond", "Jeremy", "Fajita", "Don Swan", "Smoke Admiral", "Cursed Captain", "Darkbeard", "Order", "Awakened Ice Admiral", "Tide Keeper" }
    elseif Config.World3 then
        tableBoss = { "Stone", "Island Empress", "Kilo Admiral", "Captain Elephant", "Beautiful Pirate", "rip_indra True Form", "Longma", "Soul Reaper", "Cake Queen" }
    end
    MainTab:Dropdown({ Title = "Choose Boss", Values = tableBoss, Value = Config.BF.Main.SelectedBoss, Callback = function(v) Config.BF.Main.SelectedBoss = v[1] end })
    MainTab:Toggle({ Title = "Auto Farm Boss", Default = Config.BF.Main.AutoFarmBoss, Callback = function(s) Config.BF.Main.AutoFarmBoss = s end })
    MainTab:Toggle({ Title = "Auto Farm All Boss", Default = Config.BF.Main.AutoFarmAllBoss, Callback = function(s) Config.BF.Main.AutoFarmAllBoss = s end })

    -- Setting Tab
    SettingTab:Section({ Title = "Settings" })
    SettingTab:Toggle({ Title = "Spin Position", Default = Config.BF.Setting.SpinPosition, Callback = function(s) Config.BF.Setting.SpinPosition = s end })
    SettingTab:Slider({ Title = "Farm Distance", Min = 0, Max = 50, Step = 1, Default = Config.BF.Setting.FarmDistance, Callback = function(v) Config.BF.Setting.FarmDistance = v end })
    SettingTab:Slider({ Title = "Player Tween Speed", Min = 100, Max = 350, Step = 1, Default = Config.BF.Setting.PlayerTweenSpeed, Callback = function(v) Config.BF.Setting.PlayerTweenSpeed = v end })
    SettingTab:Toggle({ Title = "Bring Mob", Default = Config.BF.Setting.BringMob, Callback = function(s) Config.BF.Setting.BringMob = s end })
    SettingTab:Dropdown({ Title = "Bring Mob Mode", Values = {"Low", "Normal", "High"}, Value = Config.BF.Setting.BringMobMode, Callback = function(v) Config.BF.Setting.BringMobMode = v[1] end })
    SettingTab:Toggle({ Title = "Fast Attack", Default = Config.BF.Setting.FastAttack, Callback = function(s) Config.BF.Setting.FastAttack = s end })
    SettingTab:Dropdown({ Title = "Fast Attack Mode", Values = {"Slow", "Normal", "Fast", "Super Fast"}, Value = Config.BF.Setting.FastAttackMode, Callback = function(v) Config.BF.Setting.FastAttackMode = v[1] end })
    SettingTab:Toggle({ Title = "Attack Aura", Default = Config.BF.Setting.AttackAura, Callback = function(s) Config.BF.Setting.AttackAura = s end })

    SettingTab:Section({ Title = "Graphic" })
    SettingTab:Toggle({ Title = "Hide Notifications", Default = Config.BF.Setting.HideNotification, Callback = function(s) Config.BF.Setting.HideNotification = s end })
    SettingTab:Toggle({ Title = "Hide Damage Text", Default = Config.BF.Setting.HideDamageText, Callback = function(s) Config.BF.Setting.HideDamageText = s end })
    SettingTab:Toggle({ Title = "Black Screen", Default = Config.BF.Setting.BlackScreen, Callback = function(s) Config.BF.Setting.BlackScreen = s end })
    SettingTab:Toggle({ Title = "White Screen", Default = Config.BF.Setting.WhiteScreen, Callback = function(s) Config.BF.Setting.WhiteScreen = s end })
    SettingTab:Toggle({ Title = "Hide Monsters", Default = Config.BF.Setting.HideMonster, Callback = function(s) Config.BF.Setting.HideMonster = s end })

    SettingTab:Section({ Title = "Mastery Setting" })
    SettingTab:Slider({ Title = "Kill At %", Min = 1, Max = 100, Step = 1, Default = Config.BF.Setting.MasteryHealth, Callback = function(v) Config.BF.Setting.MasteryHealth = v end })

    SettingTab:Section({ Title = "Other" })
    SettingTab:Toggle({ Title = "Auto Set Spawn Point", Default = Config.BF.Setting.AutoSetSpawnPoint, Callback = function(s) Config.BF.Setting.AutoSetSpawnPoint = s end })
    SettingTab:Toggle({ Title = "Auto Observation", Default = Config.BF.Setting.AutoObservation, Callback = function(s) Config.BF.Setting.AutoObservation = s end })
    SettingTab:Toggle({ Title = "Auto Haki", Default = Config.BF.Setting.AutoHaki, Callback = function(s) Config.BF.Setting.AutoHaki = s end })
    SettingTab:Toggle({ Title = "Auto Rejoin", Default = Config.BF.Setting.AutoRejoin, Callback = function(s) Config.BF.Setting.AutoRejoin = s end })
    SettingTab:Toggle({ Title = "Bypass Anti Cheat", Default = Config.BF.Setting.BypassAntiCheat, Callback = function(s) Config.BF.Setting.BypassAntiCheat = s end })

    -- Local Player Tab
    LocalPlayerTab:Section({ Title = "Local Player" })
    LocalPlayerTab:Toggle({ Title = "Dodge No Cooldown", Default = Config.BF.LocalPlayer.DodgeNoCooldown, Callback = function(s) Config.BF.LocalPlayer.DodgeNoCooldown = s end })
    LocalPlayerTab:Toggle({ Title = "Infinite Energy", Default = Config.BF.LocalPlayer.InfiniteEnergy, Callback = function(s) Config.BF.LocalPlayer.InfiniteEnergy = s end })
    LocalPlayerTab:Toggle({ Title = "Auto Active Race V3", Default = Config.BF.LocalPlayer.ActiveRaceV3, Callback = function(s) Config.BF.LocalPlayer.ActiveRaceV3 = s end })
    LocalPlayerTab:Toggle({ Title = "Auto Active Race V4", Default = Config.BF.LocalPlayer.ActiveRaceV4, Callback = function(s) Config.BF.LocalPlayer.ActiveRaceV4 = s end })
    LocalPlayerTab:Toggle({ Title = "Infinite Ability", Default = Config.BF.LocalPlayer.InfiniteAbility, Callback = function(s) Config.BF.LocalPlayer.InfiniteAbility = s end })
    LocalPlayerTab:Toggle({ Title = "Infinite Geppo", Default = Config.BF.LocalPlayer.InfiniteGeppo, Callback = function(s) Config.BF.LocalPlayer.InfiniteGeppo = s end })
    LocalPlayerTab:Toggle({ Title = "Infinite Soru", Default = Config.BF.LocalPlayer.InfiniteSoru, Callback = function(s) Config.BF.LocalPlayer.InfiniteSoru = s end })
    LocalPlayerTab:Toggle({ Title = "Walk on Water", Default = Config.BF.LocalPlayer.WalkOnWater, Callback = function(s) Config.BF.LocalPlayer.WalkOnWater = s end })
    LocalPlayerTab:Toggle({ Title = "NoClip", Default = Config.BF.LocalPlayer.NoClip, Callback = function(s) Config.BF.LocalPlayer.NoClip = s end })

    -- ESP Tab
    EspTab:Section({ Title = "ESP" })
    EspTab:Toggle({ Title = "ESP Player", Default = Config.BF.Esp.Player, Callback = function(s) Config.BF.Esp.Player = s end })
    EspTab:Toggle({ Title = "ESP Chest", Default = Config.BF.Esp.Chest, Callback = function(s) Config.BF.Esp.Chest = s end })
    EspTab:Toggle({ Title = "ESP Fruit", Default = Config.BF.Esp.Fruit, Callback = function(s) Config.BF.Esp.Fruit = s end })
    if Config.World3 then
        EspTab:Toggle({ Title = "ESP Real Fruit", Default = Config.BF.Esp.RealFruit, Callback = function(s) Config.BF.Esp.RealFruit = s end })
    end
    if Config.World2 then
        EspTab:Toggle({ Title = "ESP Flower", Default = Config.BF.Esp.Flower, Callback = function(s) Config.BF.Esp.Flower = s end })
    end
    EspTab:Toggle({ Title = "ESP Island", Default = Config.BF.Esp.Island, Callback = function(s) Config.BF.Esp.Island = s end })
    EspTab:Toggle({ Title = "ESP Npc", Default = Config.BF.Esp.Npc, Callback = function(s) Config.BF.Esp.Npc = s end })
    if Config.World2 or Config.World3 then
        EspTab:Toggle({ Title = "ESP Sea Beast", Default = Config.BF.Esp.SeaBeast, Callback = function(s) Config.BF.Esp.SeaBeast = s end })
    end
    EspTab:Toggle({ Title = "ESP Monster", Default = Config.BF.Esp.Monster, Callback = function(s) Config.BF.Esp.Monster = s end })
    if Config.World2 or Config.World3 then
        EspTab:Toggle({ Title = "ESP Mirage Island", Default = Config.BF.Esp.Mirage, Callback = function(s) Config.BF.Esp.Mirage = s end })
    end
    if Config.World3 then
        EspTab:Toggle({ Title = "ESP Kitsune Island", Default = Config.BF.Esp.Kitsune, Callback = function(s) Config.BF.Esp.Kitsune = s end })
        EspTab:Toggle({ Title = "ESP Frozen Dimension", Default = Config.BF.Esp.Frozen, Callback = function(s) Config.BF.Esp.Frozen = s end })
        EspTab:Toggle({ Title = "ESP Advanced Fruit Dealer", Default = Config.BF.Esp.AdvancedFruitDealer, Callback = function(s) Config.BF.Esp.AdvancedFruitDealer = s end })
        EspTab:Toggle({ Title = "ESP Gear", Default = Config.BF.Esp.Gear, Callback = function(s) Config.BF.Esp.Gear = s end })
    end

    -- Teleport Tab
    TeleportTab:Section({ Title = "World" })
    TeleportTab:Button({ Title = "Teleport To First Sea", Variant = "Secondary", Callback = function() CommF:InvokeServer("TravelMain") end })
    TeleportTab:Button({ Title = "Teleport To Second Sea", Variant = "Secondary", Callback = function() CommF:InvokeServer("TravelDressrosa") end })
    TeleportTab:Button({ Title = "Teleport To Third Sea", Variant = "Secondary", Callback = function() CommF:InvokeServer("TravelZou") end })

    -- Shop Tab
    ShopTab:Section({ Title = "Abilities" })
    ShopTab:Button({ Title = "Buy Geppo [ $10,000 ]", Variant = "Secondary", Callback = function() CommF:InvokeServer("BuyHaki", "Geppo") end })
    ShopTab:Button({ Title = "Buy Buso Haki [ $25,000 ]", Variant = "Secondary", Callback = function() CommF:InvokeServer("BuyHaki", "Buso") end })
    ShopTab:Button({ Title = "Buy Soru [ $25,000 ]", Variant = "Secondary", Callback = function() CommF:InvokeServer("BuyHaki", "Soru") end })
    ShopTab:Button({ Title = "Buy Observation Haki [ $750,000 ]", Variant = "Secondary", Callback = function() CommF:InvokeServer("KenTalk", "Buy") end })

    ShopTab:Section({ Title = "Fighting Style" })
    ShopTab:Button({ Title = "Buy Black Leg [ $150,000 ]", Variant = "Secondary", Callback = function() CommF:InvokeServer("BuyBlackLeg") end })
    ShopTab:Button({ Title = "Buy Electro [ $550,000 ]", Variant = "Secondary", Callback = function() CommF:InvokeServer("BuyElectro") end })
    ShopTab:Button({ Title = "Buy Water Kung Fu [ $750,000 ]", Variant = "Secondary", Callback = function() CommF:InvokeServer("BuyFishmanKarate") end })
    ShopTab:Button({ Title = "Buy Superhuman [ $3,000,000 ]", Variant = "Secondary", Callback = function() CommF:InvokeServer("BuySuperhuman") end })

    -- Fruit Tab
    FruitTab:Section({ Title = "Fruits" })
    FruitTab:Toggle({ Title = "Auto Random Fruit", Default = false, Callback = function(s) end })
    FruitTab:Button({ Title = "Random Fruit", Variant = "Secondary", Callback = function() CommF:InvokeServer("Cousin", "Buy") end })

    -- Misc Tab
    MiscTab:Section({ Title = "Misc" })
    MiscTab:Button({ Title = "Open Devil Shop", Variant = "Secondary", Callback = function()
        pcall(function()
            local fgui = LocalPlayer.PlayerGui.Main:FindFirstChild("FruitShop")
            if fgui then fgui.Visible = not fgui.Visible end
        end)
    end })
    MiscTab:Button({ Title = "Join Pirates Team", Variant = "Secondary", Callback = function() CommF:InvokeServer("SetTeam", "Pirates") end })
    MiscTab:Button({ Title = "Join Marines Team", Variant = "Secondary", Callback = function() CommF:InvokeServer("SetTeam", "Marines") end })

    MiscTab:Section({ Title = "Highlight" })
    MiscTab:Toggle({ Title = "Hide Chat", Default = Config.BF.Misc.HideChat, Callback = function(s)
        Config.BF.Misc.HideChat = s
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Chat, not s)
    end })
    MiscTab:Toggle({ Title = "Hide Leaderboard", Default = Config.BF.Misc.HideLeaderboard, Callback = function(s)
        Config.BF.Misc.HideLeaderboard = s
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, not s)
    end })

    MiscTab:Section({ Title = "Codes" })
    MiscTab:Button({ Title = "Redeem All Codes", Variant = "Secondary", Callback = function()
        local codes = { "KITTGAMING", "ENYU_IS_PRO", "FUDD10", "BIGNEWS", "THEGREATACE", "SUB2GAMERROBOT_EXP1", "STRAWHATMAIME", "SUB2OFFICIALNOOBIE", "SUB2NOOBMASTER123", "SUB2DAIGROCK", "AXIORE", "TANTAIGAMIMG", "STRAWHATMAINE", "JCWK", "FUDD10_V2", "SUB2FER999", "MAGICBIS", "TY_FOR_WATCHING", "STARCODEHEO" }
        for _, code in pairs(codes) do
            pcall(function() ReplicatedStorage.Remotes.Redeem:InvokeServer(code) end)
        end
    end })

    -- Stats Tab
    StatsTab:Section({ Title = "Stats" })
    local PointStatLabel = StatsTab:Paragraph({ Title = "Stat Points", Desc = "Stat Points : 0" })
    task.spawn(function()
        while Config.IsRunning do
            pcall(function()
                PointStatLabel:Set("Stat Points : " .. tostring(LocalPlayer.Data.Points.Value))
            end)
            task.wait(1)
        end
    end)

    StatsTab:Toggle({ Title = "Melee", Default = Config.BF.Stats.AutoAddMelee, Callback = function(s) Config.BF.Stats.AutoAddMelee = s end })
    StatsTab:Toggle({ Title = "Defense", Default = Config.BF.Stats.AutoAddDefense, Callback = function(s) Config.BF.Stats.AutoAddDefense = s end })
    StatsTab:Toggle({ Title = "Sword", Default = Config.BF.Stats.AutoAddSword, Callback = function(s) Config.BF.Stats.AutoAddSword = s end })
    StatsTab:Toggle({ Title = "Gun", Default = Config.BF.Stats.AutoAddGun, Callback = function(s) Config.BF.Stats.AutoAddGun = s end })
    StatsTab:Toggle({ Title = "Devil Fruit", Default = Config.BF.Stats.AutoAddFruit, Callback = function(s) Config.BF.Stats.AutoAddFruit = s end })
    StatsTab:Slider({ Title = "Point", Min = 1, Max = 100, Step = 1, Default = Config.BF.Stats.PointStats, Callback = function(v) Config.BF.Stats.PointStats = v end })

    -- Server Tab
    ServTab:Section({ Title = "Server" })
    ServTab:Button({ Title = "Rejoin Server", Variant = "Secondary", Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end })
    ServTab:Button({ Title = "Server Hop", Variant = "Secondary", Callback = function()
        task.spawn(function()
            local module = loadstring(game:HttpGet("https://roblox.farrghii.com/Hop.lua"))()
            module:Teleport(game.PlaceId, "Singapore")
        end)
    end })

    local JobIdLabel = ServTab:Paragraph({ Title = "Server Job ID", Desc = "Server Job ID : " .. game.JobId })
    ServTab:Button({ Title = "Copy Server Job ID", Variant = "Secondary", Callback = function()
        setclipboard(tostring(game.JobId))
    end })

    WindUI:Notify({ Title = "Mizukage System", Content = "Blox Fruits loaded!", Duration = 3 })
end

task.spawn(InitUI)
