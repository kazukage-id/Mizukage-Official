--[[
    ========================================================================
      Mizukage Official — Ride A Pet
      Satu file lengkap: UI WindUI + engine auto-farm Ride A Pet.
      Tanpa backend / file eksternal (hanya library WindUI yang diunduh).

      PlaceId : 124216119978534
      Toggle  : RightShift
    ========================================================================
]]

local env = (getgenv and getgenv()) or _G

-- ═══════════════════════════════════════════════════════════
-- [1] PLACE ID + ANTI DUPLIKASI
-- ═══════════════════════════════════════════════════════════
local TARGET_PLACE_ID = 124216119978534

if not game:IsLoaded() then game.Loaded:Wait() end

if game.PlaceId ~= TARGET_PLACE_ID and not env.MIZUKAGE_SKIP_PLACE_CHECK then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Mizukage Official",
            Text  = "Script ini hanya untuk Ride A Pet.",
        })
    end)
    return warn("[Mizukage Official] PlaceId " .. tostring(game.PlaceId) .. " bukan Ride A Pet.")
end

if env.MizukageOfficial then
    return game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Mizukage Official",
        Text  = "UI sudah berjalan.",
    })
end
env.MizukageOfficial = true

-- ═══════════════════════════════════════════════════════════
-- [2] SERVICES
-- ═══════════════════════════════════════════════════════════
local Players     = game:GetService("Players")
local Lighting    = game:GetService("Lighting")
local Workspace   = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.05)
    LocalPlayer = Players.LocalPlayer
end

-- ═══════════════════════════════════════════════════════════
-- [3] MUAT WINDUI (dengan cadangan)
-- ═══════════════════════════════════════════════════════════
local WindUI
do
    local sources = {
        "https://github.com/Footagesus/WindUI/releases/download/1.6.65/main.lua",
        "https://tree-hub.vercel.app/api/UI/WindUI",
    }
    for _, url in ipairs(sources) do
        local ok, result = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)
        if ok and type(result) == "table" then
            WindUI = result
            break
        end
    end
    if not WindUI then
        env.MizukageOfficial = nil
        return warn("[Mizukage Official] WindUI gagal dimuat.")
    end
end

-- ═══════════════════════════════════════════════════════════
-- [4] KONSTANTA
-- ═══════════════════════════════════════════════════════════
local BRAND   = "Mizukage Official"
local AUTHOR  = "Ride A Pet"
local VERSION = "v1.0.0"
local FOLDER  = "MizukageOfficial_RideAPet"

local State = { Alive = true, StartTime = os.clock(), SkyOriginals = {} }

-- ═══════════════════════════════════════════════════════════
-- [5] UTILITAS
-- ═══════════════════════════════════════════════════════════
local function SafeNotify(title, content, duration, icon)
    pcall(function()
        WindUI:Notify({
            Title    = title,
            Content  = content,
            Duration = duration or 3,
            Icon     = icon or "lucide:info",
        })
    end)
end

local function Safe(fn, ...)
    if type(fn) ~= "function" then return end
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(fn, table.unpack(args, 1, args.n))
        if not ok then warn("[Mizukage Official] callback error: " .. tostring(err)) end
    end)
end

local function TryCreate(fn)
    local ok, result = pcall(fn)
    if ok then return result end
    warn("[Mizukage Official] gagal membuat elemen UI: " .. tostring(result))
    return nil
end

local function FormatTime(seconds)
    return string.format("%02d:%02d:%02d",
        math.floor(seconds / 3600),
        math.floor(seconds / 60) % 60,
        math.floor(seconds % 60))
end

local function ShortNumber(n)
    n = tonumber(n) or 0
    if n >= 1e12 then return string.format("%.2fT", n / 1e12) end
    if n >= 1e9 then return string.format("%.2fB", n / 1e9) end
    if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
    if n >= 1e3 then return string.format("%.0fK", n / 1e3) end
    return tostring(math.floor(n))
end

local function StoreSky()
    State.SkyOriginals = {
        Brightness           = Lighting.Brightness,
        ExposureCompensation = Lighting.ExposureCompensation,
        ClockTime            = Lighting.ClockTime,
        Ambient              = Lighting.Ambient,
        OutdoorAmbient       = Lighting.OutdoorAmbient,
    }
end

local function RestoreSky()
    for prop, value in pairs(State.SkyOriginals) do
        pcall(function() Lighting[prop] = value end)
    end
end

local SKY_PRESETS = {
    Default   = nil,
    Sunset    = { ClockTime = 17.6, Ambient = Color3.fromRGB(120, 80, 70),  OutdoorAmbient = Color3.fromRGB(200, 120, 90) },
    Night     = { ClockTime = 0,    Ambient = Color3.fromRGB(20, 20, 40),   OutdoorAmbient = Color3.fromRGB(30, 30, 60) },
    Neon      = { ClockTime = 22,   Ambient = Color3.fromRGB(90, 0, 160),   OutdoorAmbient = Color3.fromRGB(0, 160, 200) },
    Cyberpunk = { ClockTime = 21,   Ambient = Color3.fromRGB(160, 0, 110),  OutdoorAmbient = Color3.fromRGB(0, 120, 190) },
    Space     = { ClockTime = 2,    Ambient = Color3.fromRGB(10, 10, 30),   OutdoorAmbient = Color3.fromRGB(15, 15, 45) },
}

-- ═══════════════════════════════════════════════════════════
-- [6] NAMA TELUR: alias, nilai, daftar pilihan
-- ═══════════════════════════════════════════════════════════
local EggTypeSelection = {}
local EggTypeDisplayToName = {}

local function EggCanon(value)
    local text = string.lower(tostring(value or ""))
    text = text:gsub("[%s_%-]+", "")
    if text == "blackholeegg" or text == "blackhole" then return "blackholeegg" end
    if text == "volcanoegg" or text == "volcanicegg" or text == "volcanic" then return "volcanicegg" end
    return text
end

local EggValues = {
    whiteegg = 1, brownegg = 5, crackedegg = 30, easteregg = 50,
    stoneegg = 100, leafegg = 200, mushroomegg = 500, floweregg = 750,
    slimeegg = 1000, iceegg = 3000, glassegg = 10000,
    goldenegg = 30000, diamondegg = 90000, crystalegg = 150000,
    skullegg = 250000, asteroidegg = 500000, dominusegg = 700000,
    flamingegg = 1000000, sinisteregg = 3000000, soulegg = 7000000,
    auroraegg = 300000000, galaxyegg = 1500000000,
    blackholeegg = 100000000000, solarisegg = 300000000000,
    cherubegg = 1000000000000,
}

local function EggValue(name, info)
    local known = EggValues[EggCanon(name)]
    if known then return known end
    if type(info) == "table" then
        for _, field in ipairs({ "Luck", "Value", "SampleSize", "Price", "Cost", "RarityValue" }) do
            local value = tonumber(info[field])
            if value and value > 0 then return value end
        end
    end
    return nil
end

local function FormatEggValue(value)
    for _, suffix in ipairs({
        { 1e33, "Dc" }, { 1e30, "No" }, { 1e27, "Oc" },
        { 1e24, "Sp" }, { 1e21, "Sx" }, { 1e18, "Qi" },
        { 1e15, "Qa" }, { 1e12, "T" }, { 1e9, "B" },
        { 1e6, "M" }, { 1e3, "K" },
    }) do
        if value >= suffix[1] then
            return string.format("%.1f%s", value / suffix[1], suffix[2])
        end
    end
    return tostring(math.floor(value + 0.5))
end

local function EggTypeAllowed(name)
    if next(EggTypeSelection) == nil then return true end
    return EggTypeSelection[EggCanon(name)] == true
end

local function GetEggTypeOptions()
    local entries, seen = {}, {}
    local storage = game:GetService("ReplicatedStorage")
    local gameData = storage:FindFirstChild("GameData") or storage:WaitForChild("GameData", 5)
    local eggsModule = gameData and (gameData:FindFirstChild("Eggs") or gameData:WaitForChild("Eggs", 5))

    if eggsModule then
        local ok, eggs = pcall(require, eggsModule)
        if ok and type(eggs) == "table" then
            for name, info in pairs(eggs) do
                if type(name) == "string" and not seen[name] then
                    seen[name] = true
                    table.insert(entries, { Name = name, Value = EggValue(name, info) })
                end
            end
        end
    end

    if #entries == 0 then
        for _, name in ipairs({
            "White Egg", "Brown Egg", "Cracked Egg", "Easter Egg",
            "Stone Egg", "Leaf Egg", "Mushroom Egg", "Flower Egg",
            "Slime Egg", "Ice Egg", "Glass Egg", "Golden Egg",
            "Diamond Egg", "Crystal Egg", "Skull Egg", "Asteroid Egg",
            "Dominus Egg", "Flaming Egg", "Sinister Egg", "Soul Egg",
            "Aurora Egg", "Galaxy Egg", "Blackhole Egg", "Solaris Egg",
            "Cherub Egg", "Volcanic Egg",
        }) do
            table.insert(entries, { Name = name, Value = EggValue(name) })
        end
    end

    table.sort(entries, function(a, b)
        local av, bv = a.Value or -1, b.Value or -1
        if av ~= bv then return av > bv end
        return string.lower(a.Name) < string.lower(b.Name)
    end)

    local values = {}
    EggTypeDisplayToName = {}
    for _, entry in ipairs(entries) do
        local label
        if entry.Value then
            label = entry.Name .. " [" .. FormatEggValue(entry.Value) .. "]"
        else
            label = entry.Name .. " [NEW]"
        end
        EggTypeDisplayToName[label] = entry.Name
        table.insert(values, label)
    end
    return values
end

-- ═══════════════════════════════════════════════════════════
-- [7] ADAPTER: API engine -> WindUI
-- ═══════════════════════════════════════════════════════════
local HiddenControls = {
    ["Loop extra delay (0 = instant)"] = true,
    ["Auto Deliver (Cash)"] = true,
    ["Auto Plant (Inventory)"] = true,
    ["Pickup Attempts"] = true,
    ["Volcanic Lair path"] = true,
    ["Plant/Hatch every"] = true,
    ["Also fire real prompt (hold time)"] = true,
    ["Auto Hatch"] = true,
    ["Noclip while farming"] = true,
    ["Hatch-Delay"] = true,
}

local TabIcons = {
    ["Auto Farm"] = "lucide:egg",
    ["Pets"]      = "lucide:paw-print",
    ["Progress"]  = "lucide:trending-up",
    ["Shops"]     = "lucide:shopping-cart",
    ["ESP"]       = "lucide:eye",
    ["Teleport"]  = "lucide:map-pin",
    ["Settings"]  = "lucide:settings",
}

local function dummyControl(defaultValue)
    local value = defaultValue
    return {
        Set = function(_, v) value = v end,
        Get = function() return value end,
        SetValue = function(_, v) value = v end,
    }
end

local function ToMap(list)
    local map = {}
    if type(list) ~= "table" then return map end
    for k, v in pairs(list) do
        if type(k) == "number" then
            local name = (type(v) == "table" and (v.Title or v.Name)) or v
            if name ~= nil then map[tostring(name)] = true end
        elseif v == true then
            map[tostring(k)] = true
        end
    end
    return map
end

local function MapSignature(map)
    local keys = {}
    for k in pairs(map) do table.insert(keys, k) end
    table.sort(keys)
    return table.concat(keys, "\1")
end

local function MapToList(map, ordered)
    local list, seen = {}, {}
    for _, v in ipairs(ordered or {}) do
        if map[v] then table.insert(list, v); seen[v] = true end
    end
    for k in pairs(map) do
        if not seen[k] then table.insert(list, k) end
    end
    return list
end

-- Flag registry (untuk Save / Load config)
local Flags = {}
local function RegisterFlag(flag, getter, setter)
    if flag then Flags[flag] = { Get = getter, Set = setter } end
end

local function NewGroup(tab)
    local G = {}

    function G:AddDivider()
        TryCreate(function() return tab:Divider() end)
    end

    function G:AddParagraph(cfg)
        cfg = cfg or {}
        local title = tostring(cfg.Title or "Info")
        local body  = tostring(cfg.Text or "")
        local obj = {}
        local el = TryCreate(function() return tab:Paragraph({ Title = title, Desc = body }) end)
        function obj:Set(text)
            text = tostring(text or "")
            if text == body then return end
            body = text
            if el then
                if not pcall(function() el:SetDesc(text) end) then
                    pcall(function() el:SetTitle(title .. "\n" .. text) end)
                end
            end
        end
        return obj
    end

    function G:AddButton(cfg)
        cfg = cfg or {}
        local name = tostring(cfg.Name or "Button")
        if HiddenControls[name] then return dummyControl(false) end
        local destructive = string.sub(name, 1, 6) == "Unload"
        TryCreate(function()
            return tab:Button({
                Title    = name,
                Icon     = destructive and "lucide:power" or nil,
                Variant  = destructive and "Destructive" or nil,
                Callback = function() Safe(cfg.Callback) end,
            })
        end)
        return {}
    end

    function G:AddToggle(cfg)
        cfg = cfg or {}
        local name = tostring(cfg.Name or "Toggle")
        if HiddenControls[name] then return dummyControl(cfg.Default == true) end
        local obj = { Value = cfg.Default == true }
        local el = TryCreate(function()
            return tab:Toggle({
                Title    = name,
                Value    = obj.Value,
                Default  = obj.Value,
                Callback = function(v)
                    v = v and true or false
                    if v == obj.Value then return end
                    obj.Value = v
                    Safe(cfg.Callback, v)
                end,
            })
        end)
        function obj:SetValue(v)
            v = v and true or false
            if self.Value == v then return end
            self.Value = v
            if el then pcall(function() el:Set(v) end) end
            Safe(cfg.Callback, v)
        end
        obj.Set = obj.SetValue
        function obj:Get() return self.Value end
        RegisterFlag(cfg.Flag, function() return obj.Value end, function(v) obj:SetValue(v) end)
        return obj
    end

    function G:AddSlider(cfg)
        cfg = cfg or {}
        local name = tostring(cfg.Name or "Slider")
        if HiddenControls[name] then return dummyControl(cfg.Default) end
        local minV = tonumber(cfg.Min) or 0
        local maxV = tonumber(cfg.Max) or 100
        local defV = tonumber(cfg.Default) or minV
        local step = tonumber(cfg.Step)
        if not step then
            local integral = minV == math.floor(minV) and maxV == math.floor(maxV) and defV == math.floor(defV)
            step = integral and 1 or 0.1
        end
        local title = name
        if type(cfg.Suffix) == "string" then
            local unit = cfg.Suffix:gsub("^%s+", ""):gsub("%s+$", "")
            if unit ~= "" then title = name .. " (" .. unit .. ")" end
        end
        local obj = { Value = defV }
        local el = TryCreate(function()
            return tab:Slider({
                Title    = title,
                Step     = step,
                Value    = { Min = minV, Max = maxV, Default = defV },
                Callback = function(v)
                    v = tonumber(v)
                    if v == nil or v == obj.Value then return end
                    obj.Value = v
                    Safe(cfg.Callback, v)
                end,
            })
        end)
        function obj:SetValue(v)
            v = tonumber(v)
            if v == nil then return end
            self.Value = v
            if el then pcall(function() el:Set(v) end) end
            Safe(cfg.Callback, v)
        end
        obj.Set = obj.SetValue
        function obj:Get() return self.Value end
        RegisterFlag(cfg.Flag, function() return obj.Value end, function(v) obj:SetValue(v) end)
        return obj
    end

    function G:AddDropdown(cfg)
        cfg = cfg or {}
        local name   = tostring(cfg.Name or "Dropdown")
        local values = cfg.Options or {}
        local selected = cfg.Default
        if type(selected) == "number" then selected = values[selected] end
        if selected == nil then selected = values[1] end
        local obj = { Value = selected, Values = values }
        local el = TryCreate(function()
            return tab:Dropdown({
                Title    = name,
                Values   = values,
                Value    = selected,
                Callback = function(v)
                    if type(v) == "table" then v = v.Title or v.Name or v[1] end
                    if v == nil or v == obj.Value then return end
                    obj.Value = v
                    Safe(cfg.Callback, v)
                end,
            })
        end)
        function obj:SetValue(v)
            self.Value = v
            if el and v ~= nil then pcall(function() el:Select(v) end) end
            Safe(cfg.Callback, v)
        end
        obj.Set = obj.SetValue
        function obj:Get() return self.Value end
        RegisterFlag(cfg.Flag, function() return obj.Value end, function(v) obj:SetValue(v) end)
        return obj
    end

    function G:AddMultiDropdown(cfg)
        cfg = cfg or {}
        local name   = tostring(cfg.Name or "Multi Dropdown")
        local values = cfg.Options or {}
        local map    = ToMap(cfg.Default or {})
        local obj    = { Value = map, Values = values, _sig = MapSignature(map) }
        local el = TryCreate(function()
            return tab:Dropdown({
                Title     = name,
                Values    = values,
                Value     = MapToList(map, values),
                Multi     = true,
                AllowNone = true,
                Callback  = function(list)
                    local newMap = ToMap(list)
                    local sig = MapSignature(newMap)
                    if sig == obj._sig then return end
                    obj._sig, obj.Value = sig, newMap
                    Safe(cfg.Callback, MapToList(newMap, values))
                end,
            })
        end)
        function obj:SetValue(list)
            local newMap = ToMap(list)
            self.Value, self._sig = newMap, MapSignature(newMap)
            if el then pcall(function() el:Select(MapToList(newMap, values)) end) end
            Safe(cfg.Callback, MapToList(newMap, values))
        end
        obj.Set = obj.SetValue
        function obj:Get() return MapToList(self.Value, values) end
        RegisterFlag(cfg.Flag, function() return MapToList(obj.Value, values) end, function(v) obj:SetValue(v) end)
        return obj
    end

    return G
end

-- Window / Adapter (diisi saat InitInterface)
local Window
local BuildVisualsTab, BuildInterfaceSection
local OnFinalUnload

local AdapterLibrary = {}
local ConfigMemory = {}

local function ConfigPath(name)
    name = tostring(name or "default"):gsub('[%./\\:%*%?"<>|]', "")
    if name == "" then name = "default" end
    return FOLDER .. "/" .. name .. ".json", name
end

local function HasFiles()
    return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

function AdapterLibrary:SaveConfig(name)
    local data = {}
    for flag, handler in pairs(Flags) do
        local ok, value = pcall(handler.Get)
        if ok and value ~= nil then data[flag] = value end
    end
    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if not ok then return false end
    local path, clean = ConfigPath(name)
    if HasFiles() then
        if type(makefolder) == "function" and type(isfolder) == "function" and not isfolder(FOLDER) then
            pcall(makefolder, FOLDER)
        end
        if pcall(writefile, path, encoded) then return true end
    end
    ConfigMemory[clean] = encoded
    return true
end

function AdapterLibrary:LoadConfig(name)
    local path, clean = ConfigPath(name)
    local encoded = ConfigMemory[clean]
    if HasFiles() then
        local okExists, exists = pcall(isfile, path)
        if okExists and exists then
            local okRead, contents = pcall(readfile, path)
            if okRead then encoded = contents end
        end
    end
    if not encoded then return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(encoded) end)
    if not ok or type(data) ~= "table" then return false end
    for flag, value in pairs(data) do
        local handler = Flags[flag]
        if handler then pcall(handler.Set, value) end
    end
    return true
end

function AdapterLibrary:ListConfigs()
    local names = {}
    for name in pairs(ConfigMemory) do table.insert(names, name) end
    if HasFiles() and type(listfiles) == "function" then
        pcall(function()
            for _, path in ipairs(listfiles(FOLDER)) do
                local n = string.match(path, "([^/\\]+)%.json$")
                if n then table.insert(names, n) end
            end
        end)
    end
    table.sort(names)
    return names
end

function AdapterLibrary:CreateWindow(_cfg)
    local wrapper = {}

    function wrapper:Notify(cfg)
        cfg = cfg or {}
        local kind = string.lower(tostring(cfg.Type or "info"))
        local icon = ({
            success = "lucide:check",
            error   = "lucide:alert-triangle",
            warning = "lucide:alert-triangle",
        })[kind] or "lucide:info"
        SafeNotify(tostring(cfg.Title or BRAND), tostring(cfg.Content or ""), tonumber(cfg.Duration) or 3, icon)
    end

    function wrapper:Destroy()
        if OnFinalUnload then OnFinalUnload() end
    end

    function wrapper:AddTab(tabName)
        tabName = tostring(tabName)
        if tabName == "Settings" and BuildVisualsTab then BuildVisualsTab() end

        local tab = TryCreate(function()
            return Window:Tab({ Title = tabName, Icon = TabIcons[tabName] or "lucide:circle" })
        end) or Window:Tab({ Title = tabName })

        if tabName == "Settings" and BuildInterfaceSection then BuildInterfaceSection(tab) end

        local tabObj = {}
        function tabObj:AddSubTab(subName)
            subName = tostring(subName)
            if tabName == "Auto Farm" and subName == "Eggs" then
                TryCreate(function() return tab:Section({ Title = "Egg Selection" }) end)
                local group = NewGroup(tab)
                group:AddMultiDropdown({
                    Name = "Eggs to Farm (value, empty = all)",
                    Options = GetEggTypeOptions(),
                    Default = {},
                    Flag = "egg_types",
                    Callback = function(selected)
                        EggTypeSelection = {}
                        for _, display in ipairs(selected or {}) do
                            local eggName = EggTypeDisplayToName[display] or display
                            EggTypeSelection[EggCanon(eggName)] = true
                        end
                    end,
                })
            end
            TryCreate(function() return tab:Section({ Title = subName }) end)
            return NewGroup(tab)
        end
        return tabObj
    end

    return wrapper
end

-- ═══════════════════════════════════════════════════════════
-- [8] ENGINE RIDE A PET (inline, tanpa loadstring / backend)
-- ═══════════════════════════════════════════════════════════
local function RunRideAPetEngine(Library, EggTypeAllowedFn, EggCanonFn)

do
    local prev = _G.MizukageRideAPet
    if prev and type(prev.Unload) == "function" then pcall(prev.Unload) end
end
local HUB = { conns = {}, drawings = {}, highlights = {}, dead = false, version = "1.0" }
_G.MizukageRideAPet = HUB
local function track(conn) table.insert(HUB.conns, conn); return conn end

local Window = Library:CreateWindow({ Name = "Mizukage Official | Ride A Pet" })

local HAS_CONFIG = type(Library.SaveConfig) == "function"
    and type(Library.LoadConfig) == "function"
    and type(Library.ListConfigs) == "function"
local CONFIG_NAME = "rideapet"

-- Services & locals
local Players          = game:GetService("Players")
local RS               = game:GetService("ReplicatedStorage")
local Workspace        = game:GetService("Workspace")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local function GetHRP()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function GetHumanoid()
    local char = LP.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local Remotes = RS:WaitForChild("Remotes", 30)
local GameRemotes = Remotes and Remotes:WaitForChild("Game", 30)
local function Remote(name)
    if not GameRemotes then return nil end
    return GameRemotes:FindFirstChild(name)
end

local function SafeRequire(inst)
    if not inst then return nil end
    local ok, res = pcall(require, inst)
    if ok and type(res) == "table" then return res end
    return nil
end
local GameData     = RS:FindFirstChild("GameData")
local GameServices = RS:FindFirstChild("GameServices")
local EggData      = SafeRequire(GameData and GameData:FindFirstChild("Eggs"))
local FoodData     = SafeRequire(GameData and GameData:FindFirstChild("Foods"))
local NestData     = SafeRequire(GameData and GameData:FindFirstChild("Nests"))
local RebirthData  = SafeRequire(GameData and GameData:FindFirstChild("Rebirths"))
local HatchLuck    = SafeRequire(GameData and GameData:FindFirstChild("HatchLuck"))
local GeneralData  = SafeRequire(GameData and GameData:FindFirstChild("General"))
local DayNightSvc  = SafeRequire(GameServices and GameServices:FindFirstChild("DayNight"))

local NEST_PRICES = (NestData and NestData.Prices) or { 0, 1000, 5000, 100000, 1000000 }
local RARITY_ORDER = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5, Ethereal = 6, Divine = 7, Volcanic = 8 }

local function Notify(title, content, kind, dur)
    pcall(function()
        Window:Notify({ Title = title, Content = content, Type = kind or "Info", Duration = dur or 2.5 })
    end)
end
local function safeCallback(fn)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then pcall(Notify, "Mizukage Official", "Error: " .. tostring(err), "Error", 4) end
    end
end

-- State
local S = {
    eggLoop = false,
    eggPriority = "Best Value",     -- Fast Cycle | Best Value | Nearest
    eggRarities = {},               -- empty = all
    eggLoopDelay = 0,
    sideInterval = 3,
    autoDeliver = true,
    autoPlant = false,
    plantMinLuck = 0,
    autoHatch = true,
    hatchDelay = 1.0,
    volcanicLairPath = true,
    lairSettle = 0.8,
    pickupRetries = 8,
    deliverDelay = 0,
    usePrompt = false,
    -- Pets
    petLoop = false,
    autoCollectPets = true,
    autoFeedPets = false,
    autoPlacePets = false,
    placeBestPets = true,
    -- Progress
    progressLoop = false,
    autoUnlockNests = false,
    autoRebirth = false,
    autoClaimIndex = false,
    autoClaimOffline = false,
    autoClaimGroup = false,
    autoClaimEvent = false,
    autoRadar = false,
    autoBuyFood = false,
    autoBuyGear = false,
    buyFoods = {},
    buyGears = {},
    feedFoods = {},
    shopKeepCash = 0,
    -- ESP
    eggEsp = false,
    petEsp = false,
    playerEsp = false,
    espRarities = {},
    espEggLabels = true,
    espEggMaxDist = 0,
    -- Noclip (farm only)
    noclip = false,
    farmNoclip = true,
    farmNoclipActive = false,
    -- Luck upgrades
    luckBuying = false,
    luckBuyDelay = 2,
    luckBuyMode = "1 Upgrade",
    upgradeReserve = 100000,
    -- internal
    busy = false,
    lastEggError = nil,
    stats = { eggs = 0, hatched = 0, delivered = 0, planted = 0, collected = 0, rebirths = 0, nests = 0, cash = 0 },
}
HUB.state = S

-- Helpers
local function EggInfo(name)
    if EggData and EggData[name] then return EggData[name] end
    return nil
end

local function RarityRank(rarity)
    return RARITY_ORDER[rarity] or 0
end

local function OwnPlot()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, p in ipairs(plots:GetChildren()) do
        if p:GetAttribute("NestsOwnerLoaded") == LP.UserId then return p end
    end
    for _, p in ipairs(plots:GetChildren()) do
        local data = p:FindFirstChild("Data")
        local owner = data and data:FindFirstChild("Owner")
        if owner and owner:IsA("ObjectValue") and owner.Value == LP then return p end
    end
    return nil
end
local function PlotEggs(plot) return plot and plot:FindFirstChild("Eggs") end
local function PlotNests(plot) return plot and plot:FindFirstChild("Nests") end
local function PlotPets(plot) return plot and plot:FindFirstChild("Pets") end
local function Basket() return LP:FindFirstChild("Basket") end
local function CarriedEggs() local b = Basket() return b and b:GetChildren() or {} end

-- Hard teleport: pivot the whole character
local function PivotCharacter(cframe)
    if typeof(cframe) ~= "CFrame" then return false end
    local char, hrp = LP.Character, GetHRP()
    if not char or not hrp then return false end
    local ok = pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        char:PivotTo(cframe)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
    if ok then
        HUB.lastPlacedPos = cframe.Position
        HUB.lastPlacedAt = os.clock()
    end
    return ok
end

local EGG_HEIGHT_OFFSET = 10

local function EggTopCFrame(model)
    if not model or not model.Parent then return nil end
    local ok, bb, size = pcall(function() return model:GetBoundingBox() end)
    if not ok or typeof(bb) ~= "CFrame" or typeof(size) ~= "Vector3" then return nil end
    return CFrame.new(Vector3.new(bb.Position.X, bb.Position.Y + size.Y * 0.5 + EGG_HEIGHT_OFFSET, bb.Position.Z))
end

local function PartTopCFrame(part)
    if not part or not part:IsA("BasePart") or not part.Parent then return nil end
    return part.CFrame * CFrame.new(0, part.Size.Y * 0.5 + EGG_HEIGHT_OFFSET, 0)
end

local function TravelToCFrame(cframe)
    if typeof(cframe) ~= "CFrame" then return false end
    return PivotCharacter(cframe)
end

local function TravelTo(pos, yOffset)
    if typeof(pos) ~= "Vector3" then return false end
    return TravelToCFrame(CFrame.new(pos + Vector3.new(0, yOffset or 3, 0)))
end

local function PlayerCash()
    local sd = LP:FindFirstChild("SavedData")
    local cash = sd and sd:FindFirstChild("Cash")
    return cash and cash.Value or 0
end
local function PlayerStat(name)
    local sd = LP:FindFirstChild("SavedData")
    local v = sd and sd:FindFirstChild(name)
    return v and v.Value or 0
end

local lastHold = { duration = nil, method = nil, action = nil }
local PROMPT_SETTLE = 0.05

-- One fireproximityprompt (never InputHoldBegin/End: that wedges the prompt state)
local function FirePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") or not prompt.Parent then return false end
    if prompt.Enabled == false then return false end
    lastHold.duration = tonumber(prompt.HoldDuration) or 0
    lastHold.action = tostring(prompt.ActionText or "")
    local ok = pcall(fireproximityprompt, prompt)
    lastHold.method = ok and "Proximity prompt" or "prompt trigger failed"
    return ok
end

-- ==============================================================================
-- EGG SYSTEM (EggPickup remote fired directly, retried until carry is full)
-- ==============================================================================
local function ServerDataFolder()
    return RS:FindFirstChild("ServerData")
end
local function ActiveEggsFolder()
    local sd = ServerDataFolder()
    return sd and sd:FindFirstChild("ActiveEggs")
end
local function EggPickupRemote() return Remote("EggPickup") end
local function EggPlacedRemote() return Remote("EggPlaced") end
local function ArrivalClaimRemote() return Remote("EggArrivalClaim") end

local lastPickup = { mode = nil, reason = nil, name = nil }
if EggPickupRemote() then
    track(EggPickupRemote().OnClientEvent:Connect(function(mode, reason, name)
        lastPickup = { mode = tostring(mode), reason = tostring(reason), name = tostring(name) }
    end))
end

local function EggRecords()
    local out = {}
    local folder = ActiveEggsFolder()
    if not folder then return out end
    local now = Workspace:GetServerTimeNow()
    for _, record in ipairs(folder:GetChildren()) do
        local name = record:GetAttribute("Egg")
        local pos = record:GetAttribute("Position")
        local private = record:GetAttribute("PrivateTo")
        local dropEnds = tonumber(record:GetAttribute("DropEndsAt"))
        local falling = dropEnds ~= nil and dropEnds == dropEnds and dropEnds > now
        if type(name) == "string" and typeof(pos) == "Vector3"
            and (private == nil or private == LP.UserId) and not falling then
            local info = EggInfo(name)
            out[#out + 1] = {
                record = record,
                id = record.Name,
                name = name,
                pos = pos,
                weight = tonumber(record:GetAttribute("Weight")) or 1,
                mutation = record:GetAttribute("Mutation"),
                rarity = (info and info.Rarity) or "?",
                luck = (info and info.Luck) or 0,
                sell = (info and info.SellPrice) or 0,
                growth = (info and info.GrowthTime) or 0,
            }
        end
    end
    return out
end

local function RenderedEggs()
    local out = {}
    local rendered = Workspace:FindFirstChild("RenderedEggs")
    if not rendered then return out end
    for _, model in ipairs(rendered:GetChildren()) do
        if model:IsA("Model") then
            local pp = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
            if pp then
                local info = EggInfo(model.Name)
                local prompt = model:FindFirstChild("Pickup", true)
                if not prompt or not prompt:IsA("ProximityPrompt") then
                    prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
                end
                out[#out + 1] = {
                    model = model,
                    pos = pp.Position,
                    rarity = (info and info.Rarity) or "?",
                    prompt = (prompt and prompt:IsA("ProximityPrompt")) and prompt or nil,
                }
            end
        end
    end
    return out
end

local function RenderedEggNear(pos)
    if typeof(pos) ~= "Vector3" then return nil end
    local best, bestD
    for _, r in ipairs(RenderedEggs()) do
        local d = (r.pos - pos).Magnitude
        if d < 12 and (not bestD or d < bestD) then best, bestD = r, d end
    end
    return best
end

local function TravelToEgg(egg)
    if not egg or typeof(egg.pos) ~= "Vector3" then return false end
    local rendered = RenderedEggNear(egg.pos)
    local target = rendered and EggTopCFrame(rendered.model)
    if not target then target = CFrame.new(egg.pos + Vector3.new(0, EGG_HEIGHT_OFFSET, 0)) end
    return TravelToCFrame(target)
end

-- ==============================================================================
-- VOLCANIC EGG - GUARDIAN LAIR PATH
-- The server only accepts the pickup while we count as inside the lair, so enter
-- through the lair door first, wait for the server's InVolcano marker, then claim.
-- ==============================================================================
local function IsVolcanicEgg(egg)
    if not egg then return false end
    if EggCanonFn(egg.name) == "volcanicegg" then return true end
    local rec = egg.record
    if not rec then return false end
    local ok, val = pcall(function() return rec:GetAttribute("Egg") end)
    return ok and EggCanonFn(val) == "volcanicegg"
end

local function LairDoor()
    local vol = Workspace:FindFirstChild("Volcano")
    if not vol then return nil end
    local p = vol:FindFirstChild("VolcanoEntrance")
    if p and p:IsA("BasePart") then return p end
    for _, c in ipairs(vol:GetChildren()) do
        if c:IsA("BasePart") and string.find(string.lower(c.Name), "entrance", 1, true) then
            return c
        end
    end
    return nil
end

local function LairBounds()
    local b = Workspace:FindFirstChild("GuardianBounds")
    if b and b:IsA("BasePart") then return b end
    return nil
end

local function InBox(part, pos)
    if not (part and typeof(pos) == "Vector3") then return false end
    local ok, res = pcall(function()
        local v = part.CFrame:PointToObjectSpace(pos)
        local h = part.Size * 0.5
        return math.abs(v.X) <= h.X and math.abs(v.Y) <= h.Y and math.abs(v.Z) <= h.Z
    end)
    return ok and res == true
end

local function ServerSeesInsideLair()
    local ok, val = pcall(function() return LP:GetAttribute("InVolcano") end)
    return ok and val == true
end

local function InsideLair()
    local hrp = GetHRP()
    local b = LairBounds()
    if hrp and b and InBox(b, hrp.Position) then return true end
    return ServerSeesInsideLair()
end

local function EnterLair()
    if ServerSeesInsideLair() then return true end
    local door = LairDoor()
    for _ = 1, 3 do
        if HUB.dead then return false end
        if door then
            local look = door.CFrame.LookVector
            for _, step in ipairs({ -7, 0, 7, 0 }) do
                TravelToCFrame(CFrame.new(door.Position + look * step + Vector3.new(0, 2, 0)))
                task.wait(0.12)
            end
        end
        local waited = 0
        while waited < (tonumber(S.lairSettle) or 0.6) do
            if ServerSeesInsideLair() then return true end
            task.wait(0.05)
            waited = waited + 0.05
        end
    end
    return ServerSeesInsideLair() or InsideLair()
end

local function AimCameraAtEgg(rendered)
    local prompt = rendered and rendered.prompt
    local part = prompt and prompt.Parent
    if not part or not part:IsA("BasePart") then return false end
    local needs = prompt.RequiresLineOfSight == true
    pcall(function()
        if not needs and part:HasTag("EggPickupRequiresLineOfSight") then needs = true end
    end)
    if not needs then return false end
    local cam = Workspace.CurrentCamera
    if not cam then return false end
    pcall(function() cam.CFrame = CFrame.lookAt(cam.CFrame.Position, part.Position) end)
    return true
end

local function RarityAllowed(rarity)
    if not S.eggRarities or next(S.eggRarities) == nil then return true end
    return S.eggRarities[rarity] == true
end

-- Target priority: Fast Cycle | Best Value | Nearest
local function PickTargetEgg()
    local hrp = GetHRP()
    if not hrp then return nil end
    local origin = hrp.Position
    local renderedList = RenderedEggs()
    local function Claimable(egg)
        for _, r in ipairs(renderedList) do
            if (r.pos - egg.pos).Magnitude < 8 and r.prompt and r.prompt.Parent then return true end
        end
        return false
    end
    local best, bestScore, bestClaimable = nil, nil, false
    for _, egg in ipairs(EggRecords()) do
        if RarityAllowed(egg.rarity) and EggTypeAllowedFn(egg.name) then
            local travel = ((egg.pos - origin) * Vector3.new(1, 0, 1)).Magnitude
            local claimable = S.usePrompt and Claimable(egg) or false
            local value = RarityRank(egg.rarity) * 1000 + egg.luck + egg.sell * 10
            local score
            if S.eggPriority == "Nearest" then
                score = -travel
            elseif S.eggPriority == "Fast Cycle" then
                score = value / math.max((travel / 200) + egg.growth + 2, 1)
            else -- Best Value
                score = value - travel * 0.1
            end
            if claimable and not bestClaimable then
                best, bestScore, bestClaimable = egg, score, true
            elseif claimable == bestClaimable and (not bestScore or score > bestScore) then
                best, bestScore = egg, score
            end
        end
    end
    return best
end

-- Collect an egg: TP onto it, fire the EggPickup remote right away, retry.
local function CollectEgg(egg, tries)
    if not egg or HUB.dead then return false, "no target" end
    if #CarriedEggs() > 0 then return false, "carry full" end
    local before = #CarriedEggs()
    local volcanic = IsVolcanicEgg(egg)
    if volcanic and S.volcanicLairPath ~= false and not ServerSeesInsideLair() then
        EnterLair()
    end
    lastPickup = { mode = nil, reason = nil, name = egg.name, hold = nil, method = nil }
    local function WaitBasket(seconds)
        local waited = 0
        while waited < seconds and #CarriedEggs() == before do
            task.wait(0.02)
            waited = waited + 0.02
        end
        return #CarriedEggs() > before
    end
    local remote = EggPickupRemote()
    local function Claim()
        if remote then
            pcall(function() remote:FireServer(egg.id) end)
            lastPickup.method = "Remote (instant)"
        end
        if S.usePrompt then
            local r = RenderedEggNear(egg.pos)
            local p = r and r.prompt
            if p and p.Parent then
                AimCameraAtEgg(r)
                FirePrompt(p)
                lastPickup.hold = lastHold.duration
                if not lastPickup.method then lastPickup.method = lastHold.method end
            end
        end
    end
    for _ = 1, tonumber(tries) or S.pickupRetries or 8 do
        if HUB.dead then return false, "unload" end
        if #CarriedEggs() > before then return true end
        if not egg.record.Parent then return false, "egg gone" end
        local rendered = RenderedEggNear(egg.pos)
        local prompt = rendered and rendered.prompt
        TravelToCFrame((rendered and EggTopCFrame(rendered.model))
            or CFrame.new(egg.pos + Vector3.new(0, EGG_HEIGHT_OFFSET, 0)))
        if prompt and prompt.Parent then
            local near = prompt.Parent
            local hrp = GetHRP()
            local maxDist = tonumber(prompt.MaxActivationDistance) or 10
            if hrp and (hrp.Position - near.Position).Magnitude > maxDist then
                TravelToCFrame(CFrame.new(near.Position + Vector3.new(0, math.max(3, maxDist - 2), 0)))
            end
        end
        if volcanic then
            local waited, sinceTp = 0, 0
            local settle = tonumber(S.lairSettle) or 1.0
            local target = (rendered and EggTopCFrame(rendered.model))
                or CFrame.new(egg.pos + Vector3.new(0, EGG_HEIGHT_OFFSET, 0))
            while waited < settle and not ServerSeesInsideLair() and not HUB.dead do
                task.wait(0.05)
                waited = waited + 0.05
                sinceTp = sinceTp + 0.05
                if sinceTp >= 0.2 then
                    sinceTp = 0
                    TravelToCFrame(target)
                end
            end
        end
        Claim()
        if WaitBasket(0.06) then return true end
        Claim()
        if WaitBasket(0.18) then return true end
        if lastPickup.mode == "BasketFull" or (lastPickup.reason or ""):find("basket") then
            return false, "carry full"
        end
        if volcanic and (lastPickup.reason or ""):find("lair") then
            EnterLair()
        end
    end
    if #CarriedEggs() > before then return true end
    return false, tostring(lastPickup.reason or lastPickup.mode or "no response")
end

-- Deliver: over our own baseplate, claim via EggArrivalClaim
local function DeliverCarried()
    if #CarriedEggs() == 0 then return false, "carry empty" end
    local plot = OwnPlot()
    local base = plot and plot:FindFirstChild("Baseplate")
    if not base then return false, "no plot" end
    local cashBefore = PlayerCash()
    TravelToCFrame(PartTopCFrame(base) or CFrame.new(base.Position + Vector3.new(0, 6, 0)))
    local claim = ArrivalClaimRemote()
    local names = {}
    for _, c in ipairs(CarriedEggs()) do names[#names + 1] = c.Name end
    for _ = 1, 8 do
        if #CarriedEggs() == 0 then break end
        if claim then
            local hrp = GetHRP()
            if hrp then
                pcall(function() claim:FireServer(Workspace:GetServerTimeNow(), hrp.Position, names) end)
            end
        end
        for _ = 1, 8 do
            task.wait(0.02)
            if #CarriedEggs() == 0 then break end
        end
    end
    if #CarriedEggs() > 0 then return false, "delivery stuck" end
    S.stats.delivered = S.stats.delivered + 1
    local gained = PlayerCash() - cashBefore
    if gained > 0 then S.stats.cash = S.stats.cash + gained end
    task.spawn(function()
        for _ = 1, 30 do
            if HUB.dead then break end
            task.wait(0.05)
            local now = PlayerCash() - cashBefore
            if now > gained then
                S.stats.cash = S.stats.cash + (now - gained)
                gained = now
            elseif now > 0 then
                break
            end
            if gained > 0 then break end
        end
    end)
    return true, gained
end

-- Egg tools in the inventory (plantable eggs)
local function EggTools()
    local out = {}
    for _, c in ipairs({ LP:FindFirstChild("Backpack"), LP.Character }) do
        if c then
            for _, t in ipairs(c:GetChildren()) do
                if t:IsA("Tool") and t:HasTag("Egg") then
                    local info = EggInfo(t.Name)
                    out[#out + 1] = {
                        tool = t,
                        name = t.Name,
                        weight = tonumber(t:GetAttribute("Weight")) or 1,
                        mutation = t:GetAttribute("Mutation"),
                        rarity = (info and info.Rarity) or "?",
                        luck = (info and info.Luck) or 0,
                        equipped = t.Parent == LP.Character,
                    }
                end
            end
        end
    end
    return out
end

local function HeldEggTool()
    local char = LP.Character
    if not char then return nil end
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("Tool") and c:HasTag("Egg") then return c end
    end
    return nil
end

local function FreeNest()
    local plot = OwnPlot()
    local nests = PlotNests(plot)
    if not nests then return nil, plot end
    for _, n in ipairs(nests:GetChildren()) do
        if n:GetAttribute("Unlocked") == true and not n:GetAttribute("Occupied") then
            return n, plot
        end
    end
    return nil, plot
end

local function NestPosition(nest, plot)
    local anchor = nest:FindFirstChild("PlacePromptAnchor")
    if anchor and anchor:IsA("BasePart") then return anchor.Position end
    local model = nest:FindFirstChild("Model")
    if model then return model:GetPivot().Position end
    local base = plot and plot:FindFirstChild("Baseplate")
    return base and base.Position or nil
end

local function PlantBestEgg(minLuck)
    if HUB.dead then return false, "unload" end
    local remote = EggPlacedRemote()
    if not remote then return false, "EggPlaced remote missing" end
    local nest, plot = FreeNest()
    if not nest then return false, "no free nest" end
    local pick
    for _, entry in ipairs(EggTools()) do
        if entry.luck >= (tonumber(minLuck) or 0) then
            if not pick or entry.luck > pick.luck
                or (entry.luck == pick.luck and RarityRank(entry.rarity) > RarityRank(pick.rarity)) then
                pick = entry
            end
        end
    end
    if not pick then return false, "no egg in inventory" end
    local humanoid = GetHumanoid()
    if not humanoid then return false, "no humanoid" end
    if HeldEggTool() ~= pick.tool then
        pcall(function() humanoid:UnequipTools() end)
        task.wait(0.1)
        pcall(function() humanoid:EquipTool(pick.tool) end)
        task.wait(0.35)
    end
    if not HeldEggTool() then return false, "egg not equipped" end
    local eggsFolder = plot and PlotEggs(plot)
    local before = eggsFolder and #eggsFolder:GetChildren() or 0
    local pos = NestPosition(nest, plot)
    if pos then
        TravelTo(pos, 4)
        task.wait(0.25)
    end
    if nest:GetAttribute("Occupied") == true then return false, "nest already taken" end
    if LP:GetAttribute("NoNest") == true then
        local base = plot and plot:FindFirstChild("Baseplate")
        local plantPos = base and base.Position or pos
        if not plantPos then return false, "no position" end
        pcall(function() remote:FireServer({ PlantPosition = plantPos }) end)
    else
        pcall(function() remote:FireServer({ NestId = nest.Name }) end)
    end
    local placed = false
    for _ = 1, 8 do
        task.wait(0.15)
        if nest:GetAttribute("Occupied") == true
            or (eggsFolder and #eggsFolder:GetChildren() > before) then
            placed = true
            break
        end
    end
    if placed then
        S.stats.planted = S.stats.planted + 1
        return true, pick.name
    end
    return false, "place refused"
end

local function GrowthRemaining(egg)
    local data = egg:FindFirstChild("EggData")
    local placeTime = data and data:FindFirstChild("PlaceTime")
    local weight = data and data:FindFirstChild("Weight")
    local info = EggInfo(egg.Name)
    if not (placeTime and placeTime.Value > 0 and info) then return 0 end
    local growth = info.GrowthTime or 0
    if GeneralData and GeneralData.GrowthTimeFor then
        local ok, res = pcall(GeneralData.GrowthTimeFor, growth, (weight and weight.Value) or 1)
        if ok and type(res) == "number" then growth = res end
    end
    local elapsed
    if DayNightSvc and DayNightSvc.GrowthElapsed then
        local ok, res = pcall(DayNightSvc.GrowthElapsed, placeTime.Value)
        if ok and type(res) == "number" then elapsed = res end
    end
    elapsed = elapsed or (Workspace:GetServerTimeNow() - placeTime.Value)
    return math.max(growth - elapsed, 0)
end

local function HatchEgg(egg)
    local pp = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart", true)
    local prompt = egg:FindFirstChild("Hatch", true)
    if prompt and prompt:IsA("ProximityPrompt") then
        if pp then
            TravelToCFrame(PartTopCFrame(pp) or CFrame.new(pp.Position + Vector3.new(0, 10, 0)))
            task.wait(PROMPT_SETTLE)
        end
        return FirePrompt(prompt), "prompt"
    end
    local key = egg:GetAttribute("EggKey")
    if not key then return false, "no egg key" end
    local remote = Remote("Hatch")
    if not remote then return false, "hatch remote missing" end
    if pp then
        TravelTo(pp.Position, 4)
        task.wait(0.2)
    end
    return (pcall(function() remote:FireServer({ EggKey = key }) end)), "remote"
end

local function HatchReadyEggs()
    local plot = OwnPlot()
    local eggs = PlotEggs(plot)
    if not eggs then return 0 end
    local before = #eggs:GetChildren()
    local fired = 0
    for _, egg in ipairs(eggs:GetChildren()) do
        local prompt = egg:FindFirstChild("Hatch", true)
        local available = prompt and prompt:GetAttribute("HatchPromptAvailable")
        local remaining = GrowthRemaining(egg)
        if available == true or remaining <= 0 then
            if HatchEgg(egg) then fired = fired + 1 end
            task.wait(S.hatchDelay)
        end
    end
    if fired == 0 then return 0 end
    local count = 0
    for _ = 1, 40 do
        task.wait(0.25)
        local now = (eggs.Parent and #eggs:GetChildren()) or 0
        count = math.max(before - now, 0)
        if count >= fired then break end
    end
    S.stats.hatched = S.stats.hatched + count
    return count
end

-- ==============================================================================
-- PET SYSTEM
-- ==============================================================================
local function OwnPlotPets()
    local plot = OwnPlot()
    local pets = PlotPets(plot)
    if not pets then return {} end
    local out = {}
    for _, pet in ipairs(pets:GetChildren()) do
        if pet:GetAttribute("OwnerUserId") == LP.UserId then out[#out + 1] = pet end
    end
    return out
end

local function HeldPets()
    local out = {}
    local containers = { LP:FindFirstChild("Backpack"), LP.Character }
    for _, c in ipairs(containers) do
        if c then
            for _, t in ipairs(c:GetChildren()) do
                if t:IsA("Tool") and t:GetAttribute("PetKey") then out[#out + 1] = t end
            end
        end
    end
    return out
end

local function PetCollectPrompt(pet)
    for _, d in ipairs(pet:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local txt = string.lower(tostring(d.ActionText or "") .. " " .. tostring(d.ObjectText or "") .. " " .. d.Name)
            if txt:find("collect") or txt:find("einsammeln") or txt:find("abholen") or txt:find("kassieren") then
                return d
            end
        end
    end
    return nil
end

local function CollectPetEarnings()
    local remote = Remote("PetCollect")
    local n = 0
    for _, pet in ipairs(OwnPlotPets()) do
        local prompt = PetCollectPrompt(pet)
        if prompt then
            local hrp = GetHRP()
            local pp = prompt.Parent
            if hrp and pp and pp:IsA("BasePart") and (hrp.Position - pp.Position).Magnitude > 12 then
                TravelTo(pp.Position, 6)
                task.wait(PROMPT_SETTLE)
            end
            FirePrompt(prompt)
            n = n + 1
            task.wait(0.12)
        else
            local key = pet:GetAttribute("PetKey")
            if remote and key then
                pcall(function() remote:FireServer(key) end)
                n = n + 1
                task.wait(0.08)
            end
        end
    end
    S.stats.collected = S.stats.collected + n
    return n
end

local function FoodTools()
    local out = {}
    local function scan(c)
        if not c then return end
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and not t:GetAttribute("PetKey") then
                local n = tostring(t.Name)
                if FoodData and FoodData[n] then out[#out + 1] = t end
            end
        end
    end
    scan(LP:FindFirstChild("Backpack"))
    scan(LP.Character)
    return out
end

local function FeedPets()
    local foods = FoodTools()
    if #foods == 0 then return false, "no food" end
    local humanoid = GetHumanoid()
    local food, lowestCost
    for _, candidate in ipairs(foods) do
        if next(S.feedFoods) == nil or S.feedFoods[candidate.Name] then
            local entry = FoodData and FoodData[candidate.Name]
            local cost = entry and tonumber(entry.Cost) or math.huge
            if not food or cost < lowestCost then
                food, lowestCost = candidate, cost
            end
        end
    end
    if not food then return false, "selected food not in inventory" end
    if humanoid then pcall(function() humanoid:EquipTool(food) end) end
    task.wait(0.2)
    local fed = 0
    for _, pet in ipairs(OwnPlotPets()) do
        local prompt = pet:FindFirstChild("Feed", true)
        if prompt then
            FirePrompt(prompt)
            fed = fed + 1
            task.wait(0.35)
        end
    end
    return true, fed
end

-- Shops: selected items only; purchase counted after inventory confirmation
HUB.ShopData = SafeRequire(GameData and GameData:FindFirstChild("Shop"))
HUB.ShopRetry = {}
HUB.ShopStatus = "Ready"

function HUB.ShopEntries(category)
    local entries = {}
    local items = HUB.ShopData and HUB.ShopData[category]
    if type(items) == "table" then
        for name, data in pairs(items) do
            local price = type(data) == "table" and tonumber(data.Price)
            if type(name) == "string" and price and price >= 0 then
                entries[#entries + 1] = { Name = name, Price = price }
            end
        end
    end
    table.sort(entries, function(a, b)
        return a.Price < b.Price or (a.Price == b.Price and a.Name < b.Name)
    end)
    return entries
end

function HUB.ShopNames(category)
    local names = {}
    for _, entry in ipairs(HUB.ShopEntries(category)) do
        names[#names + 1] = entry.Name
    end
    return names
end

function HUB.InventoryCount(name)
    local total = 0
    for _, container in pairs({ LP:FindFirstChildOfClass("Backpack"), LP.Character }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and tool.Name:gsub("%s*%[.*$", "") == name then
                    local amount = tool:FindFirstChild("Amount", true)
                    total = total + (amount and tonumber(amount.Value) or 1)
                end
            end
        end
    end
    return total
end

function HUB.AutoBuyStep(category)
    local selected = category == "Food" and S.buyFoods or S.buyGears
    if next(selected) == nil then return end
    local buyRemote = Remote("BuyWithCash")
    if not buyRemote then HUB.ShopStatus = "BuyWithCash unavailable" return end
    local openRemote = Remote("SetOpenShop")
    local opened = false
    for _, entry in ipairs(HUB.ShopEntries(category)) do
        local name = entry.Name
        local retryKey = category .. ":" .. name
        if selected[name] and os.clock() >= (HUB.ShopRetry[retryKey] or 0)
            and (tonumber(PlayerCash()) or 0) - entry.Price >= S.shopKeepCash then
            if not opened and openRemote then
                pcall(function() openRemote:FireServer(category) end)
                task.wait(0.15)
                opened = true
            end
            local before = HUB.InventoryCount(name)
            local sent = pcall(function() buyRemote:FireServer(category, name) end)
            if sent then
                local deadline = os.clock() + 0.8
                while not HUB.dead and os.clock() < deadline and HUB.InventoryCount(name) <= before do
                    RunService.Heartbeat:Wait()
                end
            end
            if sent and HUB.InventoryCount(name) > before then
                HUB.ShopStatus = "Bought " .. name
            else
                HUB.ShopRetry[retryKey] = os.clock() + 30
                HUB.ShopStatus = "Buy not confirmed: " .. name
            end
        end
    end
end

-- Place best held pets (game's own PlaceBest button, fallback: PlacePet remote)
local function PlaceBestPets()
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    local main = pg and pg:FindFirstChild("Main")
    local tracker = main and main:FindFirstChild("PetsTracker")
    local placeBest = tracker and tracker:FindFirstChild("PlaceBest")
    if placeBest then
        local ok, conns = pcall(getconnections, placeBest.Activated)
        if ok and #conns > 0 then
            for _, c in ipairs(conns) do
                if type(c.Function) == "function" then pcall(c.Function) end
            end
            return true
        end
    end
    local remote = Remote("PlacePet")
    local plot = OwnPlot()
    if not (remote and plot) then return false end
    local nests = PlotNests(plot)
    if not nests then return false end
    local freeAnchor
    for _, n in ipairs(nests:GetChildren()) do
        if n:GetAttribute("Unlocked") == true then
            local anchor = n:FindFirstChild("PlacePromptAnchor")
            if anchor then freeAnchor = anchor break end
        end
    end
    if not freeAnchor then return false end
    local pets = HeldPets()
    table.sort(pets, function(a, b)
        return (a:GetAttribute("Weight") or 0) > (b:GetAttribute("Weight") or 0)
    end)
    local placed = 0
    for _, pet in ipairs(pets) do
        local key = pet:GetAttribute("PetKey")
        if key then
            local pos = freeAnchor.Position
            pcall(function() remote:FireServer(key, pos.X, pos.Y, pos.Z) end)
            placed = placed + 1
            task.wait(0.25)
            if placed >= 1 then break end
        end
    end
    return placed > 0
end

-- ==============================================================================
-- PROGRESS
-- ==============================================================================
local function UnlockNests()
    local plot = OwnPlot()
    local nests = PlotNests(plot)
    if not nests then return 0 end
    local cash = PlayerCash()
    local unlocked = 0
    for _, n in ipairs(nests:GetChildren()) do
        if n:GetAttribute("Unlocked") ~= true then
            local idx = tonumber(n.Name) or 1
            local price = NEST_PRICES[idx] or math.huge
            if cash >= price then
                local prompt = n:FindFirstChild("UnlockNest", true)
                if prompt then
                    FirePrompt(prompt)
                    unlocked = unlocked + 1
                    S.stats.nests = S.stats.nests + 1
                    task.wait(0.6)
                end
            end
        end
    end
    return unlocked
end

local function RebirthCost()
    local current = tonumber(PlayerStat("Rebirths")) or 0
    if RebirthData and RebirthData.GetCost then
        local ok, res = pcall(RebirthData.GetCost, current)
        if ok and type(res) == "number" then return res end
    end
    return 1000000 * (50 ^ current)
end

local function TryRebirth()
    local cap = (RebirthData and RebirthData.Cap) or 6
    if (tonumber(PlayerStat("Rebirths")) or 0) >= cap then return false, "cap reached" end
    if PlayerCash() < RebirthCost() then return false, "not enough cash" end
    local remote = Remote("Rebirth")
    if not remote then return false end
    pcall(function() remote:FireServer() end)
    S.stats.rebirths = S.stats.rebirths + 1
    return true
end

local function FireSimpleRemote(remote)
    if not remote then return false end
    pcall(function() remote:FireServer() end)
    return true
end
local function ReusableRemote(name)
    local reusable = Remotes and Remotes:FindFirstChild("Reusable")
    return reusable and reusable:FindFirstChild(name)
end
local function ClaimIndexReward() return FireSimpleRemote(Remote("ClaimIndexReward")) end
local function ClaimOfflineEarnings() return FireSimpleRemote(Remote("OfflineEarnings")) end
local function ClaimGroupReward() return FireSimpleRemote(ReusableRemote("ClaimGroupReward")) end
local function ClaimEventReward() return FireSimpleRemote(ReusableRemote("ClaimEventReward")) end
local function ActivateRadar() return FireSimpleRemote(Remote("ActivateRadar")) end

-- Hatch luck upgrades (price / multiplier come from GameData.HatchLuck)
local function HatchUpgradeLevel()
    return tonumber(PlayerStat("HatchUpgrades")) or 0
end

local function HatchLuckMultiplier()
    local level = HatchUpgradeLevel()
    if HatchLuck and type(HatchLuck.GetMultiplier) == "function" then
        local ok, res = pcall(HatchLuck.GetMultiplier, level)
        if ok and type(res) == "number" then return res end
    end
    return 1 + level
end

local function NextHatchUpgradePrice()
    local level = HatchUpgradeLevel()
    if HatchLuck and type(HatchLuck.GetPrice) == "function" then
        local ok, res = pcall(HatchLuck.GetPrice, level)
        if ok and type(res) == "number" then return res end
    end
    return 5 + level * 5
end

local function MaxAffordableHatchUpgrades()
    local level, cash = HatchUpgradeLevel(), PlayerCash()
    if HatchLuck and type(HatchLuck.GetMaxAffordable) == "function" then
        local ok, count, cost = pcall(HatchLuck.GetMaxAffordable, level, cash)
        if ok and type(count) == "number" then return count, (type(cost) == "number" and cost or 0) end
    end
    return 0, 0
end

local function UpgradeRemote()
    local plotRemotes = GameRemotes and GameRemotes:FindFirstChild("Plot")
    return plotRemotes and plotRemotes:FindFirstChild("Upgrades")
end

local function BuyHatchUpgrades(mode, force)
    local remote = UpgradeRemote()
    if not remote then return false, "upgrades remote missing" end
    local cash = PlayerCash()
    local price = NextHatchUpgradePrice()
    if not force and (cash - price) < (S.upgradeReserve or 0) then
        return false, "Reserve"
    end
    pcall(function()
        if (mode or S.luckBuyMode) == "Max" then
            remote:FireServer("Max")
        else
            remote:FireServer(1)
        end
    end)
    return true
end

-- ==============================================================================
-- ESP
-- ==============================================================================
local ESP_COLORS = {
    Common = Color3.fromRGB(200, 200, 200),
    Rare = Color3.fromRGB(80, 160, 255),
    Epic = Color3.fromRGB(170, 90, 255),
    Legendary = Color3.fromRGB(255, 190, 60),
    Mythic = Color3.fromRGB(255, 90, 90),
    Ethereal = Color3.fromRGB(90, 255, 210),
    Divine = Color3.fromRGB(255, 255, 140),
    Volcanic = Color3.fromRGB(255, 120, 40),
}

local espMaps = { egg = {}, pet = {}, player = {} }

local function EspRarityOk(rarity)
    if S.espRarities == nil or next(S.espRarities) == nil then return true end
    return S.espRarities[rarity] == true
end

local ClearEggMarkers -- forward declaration (defined below)

local function HideESP(kind)
    if kind == "egg" and ClearEggMarkers then ClearEggMarkers() end
    for inst, h in pairs(espMaps[kind]) do
        pcall(function() h:Destroy() end)
        espMaps[kind][inst] = nil
    end
    for i = #HUB.highlights, 1, -1 do
        if HUB.highlights[i].kind == kind then table.remove(HUB.highlights, i) end
    end
end

-- Egg markers: all unclaimed field eggs from ServerData.ActiveEggs
local eggMarkers = {}
local markerFolder = nil

local function MarkerFolder()
    if markerFolder and markerFolder.Parent then return markerFolder end
    markerFolder = Instance.new("Folder")
    markerFolder.Name = "MizukageEggMarkers"
    markerFolder.Parent = Workspace.CurrentCamera or Workspace
    return markerFolder
end

local function ForgetHighlight(instance)
    for i = #HUB.highlights, 1, -1 do
        if HUB.highlights[i].instance == instance then table.remove(HUB.highlights, i) end
    end
end

ClearEggMarkers = function()
    for id, m in pairs(eggMarkers) do
        if m.highlight then
            ForgetHighlight(m.highlight)
            pcall(function() m.highlight:Destroy() end)
        end
        if m.part then pcall(function() m.part:Destroy() end) end
        eggMarkers[id] = nil
    end
end

local function MakeEggMarker(id, egg)
    local color = ESP_COLORS[egg.rarity] or Color3.new(1, 1, 1)
    local part = Instance.new("Part")
    part.Name = "MizukageEggMarker"
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(3, 3, 3)
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Transparency = 0.6
    part.CFrame = CFrame.new(egg.pos + Vector3.new(0, 1.5, 0))
    part.Parent = MarkerFolder()

    local h = Instance.new("Highlight")
    h.Name = "MizukageESP"
    h.Adornee = part
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.FillColor = color
    h.FillTransparency = 0.7
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.OutlineTransparency = 0
    h.Parent = part
    table.insert(HUB.highlights, { instance = h, kind = "egg" })

    local gui = Instance.new("BillboardGui")
    gui.Name = "MizukageEggLabel"
    gui.Size = UDim2.fromOffset(180, 30)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.MaxDistance = 6000
    gui.Parent = part
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.TextStrokeTransparency = 0.35
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextColor3 = color
    label.Text = ""
    label.Parent = gui

    eggMarkers[id] = { part = part, highlight = h, gui = gui, label = label }
    return eggMarkers[id]
end

local function HighlightFor(kind, inst)
    if not inst or not inst.Parent then return nil end
    if not (inst:IsA("Model") or inst:IsA("BasePart")) then return nil end
    local map = espMaps[kind]
    local h = map[inst]
    if h and not h.Parent then h = nil map[inst] = nil end
    if not h then
        h = Instance.new("Highlight")
        h.Name = "MizukageESP"
        h.FillTransparency = 0.6
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.OutlineColor = Color3.fromRGB(255, 255, 255)
        h.Adornee = inst
        h.Parent = inst
        map[inst] = h
        table.insert(HUB.highlights, { instance = h, kind = kind, adornee = inst })
    end
    h.Enabled = true
    return h
end

local function UpdateEggESP()
    if not S.eggEsp then HideESP("egg") return end
    local seen, seenIds, known = {}, {}, {}
    local own = OwnPlot()
    local hrp = GetHRP()
    local origin = hrp and hrp.Position or nil
    local maxDist = tonumber(S.espEggMaxDist) or 0
    local labels = S.espEggLabels ~= false
    local rendered = RenderedEggs()

    -- 1a) all unclaimed field eggs (server records)
    for _, egg in ipairs(EggRecords()) do
        if EspRarityOk(egg.rarity) then
            local dist = origin and ((egg.pos - origin) * Vector3.new(1, 0, 1)).Magnitude or 0
            if maxDist <= 0 or dist <= maxDist then
                local color = ESP_COLORS[egg.rarity] or Color3.new(1, 1, 1)
                local outline = egg.mutation and Color3.fromRGB(255, 215, 80) or Color3.fromRGB(255, 255, 255)
                local model, modelDist
                for _, r in ipairs(rendered) do
                    local d = (r.pos - egg.pos).Magnitude
                    if d < 8 and (not modelDist or d < modelDist) then model, modelDist = r.model, d end
                end
                if model then
                    known[model] = true
                    local h = HighlightFor("egg", model)
                    if h then
                        h.FillColor = color
                        h.OutlineColor = outline
                        h.FillTransparency = 0.55
                        seen[model] = true
                    end
                end
                local m = eggMarkers[egg.id]
                if not m then m = MakeEggMarker(egg.id, egg) end
                if m and m.part and m.part.Parent then
                    m.part.CFrame = CFrame.new(egg.pos + Vector3.new(0, 1.5, 0))
                    m.part.Color = color
                    m.part.Transparency = model and 0.75 or 0.6
                    if m.highlight then
                        m.highlight.Enabled = true
                        m.highlight.FillColor = color
                        m.highlight.FillTransparency = model and 0.85 or 0.7
                        m.highlight.OutlineColor = outline
                    end
                    if m.gui then m.gui.Enabled = labels end
                    if m.label and labels then
                        m.label.TextColor3 = color
                        m.label.Text = string.format("%s - %s - %dm%s", egg.name, egg.rarity, math.floor(dist),
                            egg.mutation and (" - " .. tostring(egg.mutation)) or "")
                    end
                end
                seenIds[egg.id] = true
            end
        end
    end

    -- 1b) rendered eggs without a record (e.g. currently falling)
    for _, r in ipairs(rendered) do
        if not known[r.model] and EspRarityOk(r.rarity) then
            local h = HighlightFor("egg", r.model)
            if h then
                h.FillColor = ESP_COLORS[r.rarity] or Color3.new(1, 1, 1)
                h.OutlineColor = Color3.fromRGB(255, 255, 255)
                h.FillTransparency = 0.55
                seen[r.model] = true
            end
        end
    end

    -- clean up markers (claimed, gone or filtered out)
    for id, m in pairs(eggMarkers) do
        if not seenIds[id] then
            if m.highlight then
                ForgetHighlight(m.highlight)
                pcall(function() m.highlight:Destroy() end)
            end
            if m.part then pcall(function() m.part:Destroy() end) end
            eggMarkers[id] = nil
        end
    end

    -- 2) plot eggs (own = green outline, others = white)
    local plots = Workspace:FindFirstChild("Plots")
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            local eggs = plot:FindFirstChild("Eggs")
            if eggs then
                for _, e in ipairs(eggs:GetChildren()) do
                    local info = EggInfo(e.Name)
                    local rarity = (info and info.Rarity) or "?"
                    if EspRarityOk(rarity) then
                        local h = HighlightFor("egg", e)
                        if h then
                            h.FillColor = ESP_COLORS[rarity] or Color3.new(1, 1, 1)
                            h.OutlineColor = (plot == own) and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 255, 255)
                            h.FillTransparency = 0.6
                            seen[e] = true
                        end
                    end
                end
            end
        end
    end

    -- 3) eggs in our own carry
    for _, c in ipairs(CarriedEggs()) do
        local h = HighlightFor("egg", c)
        if h then
            h.FillColor = Color3.fromRGB(255, 255, 255)
            h.OutlineColor = Color3.fromRGB(255, 220, 80)
            seen[c] = true
        end
    end

    for inst, h in pairs(espMaps.egg) do
        if not seen[inst] then h.Enabled = false end
    end
end

local function UpdatePetESP()
    if not S.petEsp then HideESP("pet") return end
    local seen = {}
    local plots = Workspace:FindFirstChild("Plots")
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            local pets = plot:FindFirstChild("Pets")
            if pets then
                for _, pet in ipairs(pets:GetChildren()) do
                    local own = pet:GetAttribute("OwnerUserId") == LP.UserId
                    local h = HighlightFor("pet", pet)
                    if h then
                        h.FillColor = own and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 120, 200)
                        seen[pet] = true
                    end
                end
            end
        end
    end
    for _, t in ipairs(HeldPets()) do
        local h = HighlightFor("pet", t)
        if h then
            h.FillColor = Color3.fromRGB(80, 200, 255)
            seen[t] = true
        end
    end
    for inst, h in pairs(espMaps.pet) do
        if not seen[inst] then h.Enabled = false end
    end
end

local function UpdatePlayerESP()
    if not S.playerEsp then HideESP("player") return end
    local seen = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local h = HighlightFor("player", plr.Character)
            if h then
                h.FillColor = Color3.fromRGB(255, 80, 80)
                seen[plr.Character] = true
            end
        end
    end
    for inst, h in pairs(espMaps.player) do
        if not seen[inst] then h.Enabled = false end
    end
end

local function RefreshESP()
    pcall(UpdateEggESP)
    pcall(UpdatePetESP)
    pcall(UpdatePlayerESP)
end

-- ==============================================================================
-- NOCLIP (egg farm only)
-- ==============================================================================
local function StartNoclip()
    if HUB.noclipConn then return end
    HUB.noclipConn = RunService.Stepped:Connect(function()
        if not (S.noclip or S.farmNoclipActive) then return end
        local char = LP.Character
        if not char then return end
        for _, d in ipairs(char:GetDescendants()) do
            if d:IsA("BasePart") and d.CanCollide then d.CanCollide = false end
        end
    end)
end

local BODY_PARTS = {
    HumanoidRootPart = true, Head = true, UpperTorso = true, LowerTorso = true, Torso = true,
    LeftUpperArm = true, RightUpperArm = true, LeftLowerArm = true, RightLowerArm = true,
    LeftHand = true, RightHand = true, LeftUpperLeg = true, RightUpperLeg = true,
    LeftLowerLeg = true, RightLowerLeg = true, LeftFoot = true, RightFoot = true,
}
local function RestoreCollisions()
    local char = LP.Character
    if not char then return end
    for _, d in ipairs(char:GetChildren()) do
        if d:IsA("BasePart") and BODY_PARTS[d.Name] and not d.CanCollide then
            pcall(function() d.CanCollide = true end)
        end
    end
end

local function SetFarmNoclip(on)
    if S.farmNoclipActive == on then return end
    S.farmNoclipActive = on
    if on then
        StartNoclip()
    elseif not S.noclip then
        task.delay(0.4, RestoreCollisions)
    end
end

-- ==============================================================================
-- TELEPORTS
-- ==============================================================================
local function TeleportToOwnPlot()
    local plot = OwnPlot()
    if not plot then return Notify("Mizukage Official", "No plot loaded", "Error") end
    local base = plot:FindFirstChild("Baseplate") or plot:FindFirstChild("Baseplate", true)
    if base then TravelToCFrame(PartTopCFrame(base)) end
end
local function TeleportToStall(name)
    local stalls = Workspace:FindFirstChild("Stalls")
    local stall = stalls and stalls:FindFirstChild(name)
    if not stall then return Notify("Mizukage Official", "Stall not found", "Error") end
    local pivot = stall:IsA("Model") and stall:GetPivot().Position or stall.Position
    TravelTo(pivot, 6)
end

-- ==============================================================================
-- LOOPS
-- ==============================================================================
local function EggLoopStep()
    if S.busy then return end
    -- Hold Shift = Auto Farm pauses (play manually)
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
        return
    end
    -- If something else moved us, hold still briefly instead of fighting it
    local hrpNow = GetHRP()
    if hrpNow and HUB.lastPlacedPos and HUB.lastPlacedAt then
        local fresh = (os.clock() - HUB.lastPlacedAt) < 0.6
        if not fresh and (hrpNow.Position - HUB.lastPlacedPos).Magnitude > 40 then
            HUB.manualUntil = os.clock() + 1.5
            HUB.lastPlacedPos = hrpNow.Position
            if (os.clock() - (HUB.manualWarnAt or 0)) > 8 then
                HUB.manualWarnAt = os.clock()
                Notify("Auto Farm", "Paused - the character was moved externally", "Info", 3)
            end
        end
    end
    if HUB.manualUntil and os.clock() < HUB.manualUntil then return end
    S.busy = true
    local did = false
    local ok, err = pcall(function()
        -- 1) TP onto the egg -> claim
        if #CarriedEggs() == 0 then
            local target = PickTargetEgg()
            if target then
                local got, why = CollectEgg(target)
                if got then
                    S.stats.eggs = S.stats.eggs + 1
                    did = true
                else
                    S.lastEggError = tostring(why)
                end
            end
        end
        local delay = tonumber(S.deliverDelay) or 0
        if did and delay > 0 then
            local t0 = os.clock()
            while not HUB.dead and (os.clock() - t0) < delay do task.wait(0.02) end
        end
        -- 2) TP back over our baseplate -> deliver (pays cash)
        if #CarriedEggs() > 0 and S.autoDeliver then
            if DeliverCarried() then did = true end
        end
        -- 3) side tasks (plant / hatch) only every X seconds
        local now = os.clock()
        local every = tonumber(S.sideInterval) or 3
        if every >= 0 and (now - (HUB.lastSideAt or 0)) >= every then
            HUB.lastSideAt = now
            if S.autoPlant then PlantBestEgg(S.plantMinLuck) end
            if S.autoHatch then HatchReadyEggs() end
        end
    end)
    if not ok then pcall(Notify, "Mizukage Official", "Egg loop: " .. tostring(err), "Error", 3) end
    S.busy = false
    return did
end

local function PetLoopStep()
    if S.petLoop and S.autoCollectPets then CollectPetEarnings() end
    if S.petLoop and S.autoPlacePets and S.placeBestPets then PlaceBestPets() end
    if S.autoFeedPets then FeedPets() end
end

local function ProgressLoopStep()
    if S.autoUnlockNests then UnlockNests() end
    if S.autoRebirth then TryRebirth() end
    if S.autoClaimOffline then ClaimOfflineEarnings() end
    if S.autoClaimIndex then ClaimIndexReward() end
    if S.autoClaimGroup then ClaimGroupReward() end
    if S.autoClaimEvent then ClaimEventReward() end
    if S.autoRadar then ActivateRadar() end
end

local function StartLoops()
    if HUB.loopsRunning then return end
    HUB.loopsRunning = true
    task.spawn(function()
        while not HUB.dead do
            if S.eggLoop then
                SetFarmNoclip(S.farmNoclip)
                local ok, did = pcall(EggLoopStep)
                if did then
                    local extra = tonumber(S.eggLoopDelay) or 0
                    if extra > 0 then task.wait(extra) end
                else
                    task.wait(0.12)
                end
            else
                SetFarmNoclip(false)
                task.wait(0.25)
            end
        end
    end)
    task.spawn(function()
        while not HUB.dead do
            if S.luckBuying then
                pcall(BuyHatchUpgrades, S.luckBuyMode, false)
                task.wait(math.max(tonumber(S.luckBuyDelay) or 2, 0.2))
            else
                task.wait(0.25)
            end
        end
    end)
    task.spawn(function()
        while not HUB.dead do
            if S.petLoop or S.autoFeedPets then pcall(PetLoopStep) end
            task.wait(3)
        end
    end)
    task.spawn(function()
        while not HUB.dead do
            if S.autoBuyFood then pcall(HUB.AutoBuyStep, "Food") end
            if S.autoBuyGear then pcall(HUB.AutoBuyStep, "Gears") end
            task.wait(5)
        end
    end)
    task.spawn(function()
        while not HUB.dead do
            if S.progressLoop then pcall(ProgressLoopStep) end
            task.wait(5)
        end
    end)
    task.spawn(function()
        while not HUB.dead do
            pcall(RefreshESP)
            task.wait(0.5)
        end
    end)
end

-- ==============================================================================
-- UI
-- ==============================================================================
local mainTab = Window:AddTab("Auto Farm")
local petsTab = Window:AddTab("Pets")
local progressTab = Window:AddTab("Progress")
local shopTab = Window:AddTab("Shops")
local espTab = Window:AddTab("ESP")
local teleportTab = Window:AddTab("Teleport")
local setTab = Window:AddTab("Settings")

-- Eggs
local eggsLoopSub = mainTab:AddSubTab("Eggs")
eggsLoopSub:AddToggle({
    Name = "Auto Farm Eggs", Default = false, Flag = "eggs_loop",
    Callback = safeCallback(function(v) S.eggLoop = v StartLoops() end)
})
eggsLoopSub:AddDropdown({
    Name = "Egg Priority", Options = { "Best Value", "Fast Cycle", "Nearest" }, Default = "Best Value", Flag = "eggs_prio",
    Callback = safeCallback(function(v) S.eggPriority = v end)
})
eggsLoopSub:AddMultiDropdown({
    Name = "Rarities (empty = all)", Options = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Ethereal", "Divine", "Volcanic" },
    Default = {}, Flag = "eggs_rarities",
    Callback = safeCallback(function(list)
        S.eggRarities = {}
        for _, r in ipairs(list) do S.eggRarities[r] = true end
    end)
})
-- Hidden in the UI (kept with their source defaults)
eggsLoopSub:AddSlider({
    Name = "Loop extra delay (0 = instant)", Min = 0, Max = 3, Default = 0, Suffix = "s", Flag = "eggs_delay",
    Callback = safeCallback(function(v) S.eggLoopDelay = tonumber(v) or 0 end)
})
eggsLoopSub:AddDivider()
eggsLoopSub:AddToggle({
    Name = "Auto Deliver (Cash)", Default = true, Flag = "eggs_deliver",
    Callback = safeCallback(function(v) S.autoDeliver = v end)
})
eggsLoopSub:AddToggle({
    Name = "Auto Plant (Inventory)", Default = false, Flag = "eggs_plant",
    Callback = safeCallback(function(v)
        S.autoPlant = v
        if v then StartLoops() end
    end)
})
eggsLoopSub:AddSlider({
    Name = "Pickup Attempts", Min = 2, Max = 20, Default = 8, Flag = "eggs_pickuptries",
    Callback = safeCallback(function(v) S.pickupRetries = math.floor(tonumber(v) or 8) end)
})
eggsLoopSub:AddToggle({
    Name = "Volcanic Lair path", Default = true, Flag = "eggs_lairpath",
    Callback = safeCallback(function(v) S.volcanicLairPath = v end)
})
eggsLoopSub:AddSlider({
    Name = "Plant/Hatch every", Min = 0, Max = 30, Default = 3, Suffix = "s", Flag = "eggs_sideinterval",
    Callback = safeCallback(function(v) S.sideInterval = tonumber(v) or 3 end)
})
eggsLoopSub:AddToggle({
    Name = "Also fire real prompt (hold time)", Default = false, Flag = "eggs_useprompt",
    Callback = safeCallback(function(v) S.usePrompt = v end)
})
eggsLoopSub:AddToggle({
    Name = "Auto Hatch", Default = true, Flag = "eggs_hatch",
    Callback = safeCallback(function(v) S.autoHatch = v end)
})
eggsLoopSub:AddToggle({
    Name = "Noclip while farming", Default = true, Flag = "eggs_farmnoclip",
    Callback = safeCallback(function(v)
        S.farmNoclip = v
        if not v then SetFarmNoclip(false) end
    end)
})
eggsLoopSub:AddSlider({
    Name = "Hatch-Delay", Min = 0.2, Max = 5, Default = 1.0, Suffix = "s", Flag = "eggs_hatchdelay",
    Callback = safeCallback(function(v) S.hatchDelay = tonumber(v) or 1 end)
})

-- Pets
local petsLoopSub = petsTab:AddSubTab("Automation")
petsLoopSub:AddToggle({
    Name = "Pet Farm", Default = false, Flag = "pets_loop",
    Callback = safeCallback(function(v) S.petLoop = v StartLoops() end)
})
petsLoopSub:AddToggle({
    Name = "Collect earnings", Default = true, Flag = "pets_collect",
    Callback = safeCallback(function(v) S.autoCollectPets = v end)
})
petsLoopSub:AddToggle({
    Name = "Auto place pets", Default = false, Flag = "pets_place",
    Callback = safeCallback(function(v) S.autoPlacePets = v end)
})

-- Progress
local progAutoSub = progressTab:AddSubTab("Automation")
progAutoSub:AddToggle({
    Name = "Progress Loop", Default = false, Flag = "prog_loop",
    Callback = safeCallback(function(v) S.progressLoop = v StartLoops() end)
})
progAutoSub:AddToggle({
    Name = "Buy nests", Default = false, Flag = "prog_nests",
    Callback = safeCallback(function(v) S.autoUnlockNests = v end)
})
progAutoSub:AddToggle({
    Name = "Auto Rebirth", Default = false, Flag = "prog_rebirth",
    Callback = safeCallback(function(v) S.autoRebirth = v end)
})
progAutoSub:AddToggle({
    Name = "Auto Index-Reward", Default = false, Flag = "prog_index",
    Callback = safeCallback(function(v) S.autoClaimIndex = v end)
})
progAutoSub:AddToggle({
    Name = "Auto offline cash", Default = false, Flag = "prog_offline",
    Callback = safeCallback(function(v) S.autoClaimOffline = v end)
})
progAutoSub:AddToggle({
    Name = "Auto group reward", Default = false, Flag = "prog_group",
    Callback = safeCallback(function(v) S.autoClaimGroup = v end)
})
progAutoSub:AddToggle({
    Name = "Auto Event-Reward", Default = false, Flag = "prog_event",
    Callback = safeCallback(function(v) S.autoClaimEvent = v end)
})
progAutoSub:AddToggle({
    Name = "Auto Radar", Default = false, Flag = "prog_radar",
    Callback = safeCallback(function(v) S.autoRadar = v end)
})
progAutoSub:AddToggle({
    Name = "Auto Buy Luck", Default = false, Flag = "luck_autobuy",
    Callback = safeCallback(function(v) S.luckBuying = v StartLoops() end)
})
progAutoSub:AddSlider({
    Name = "Buy delay", Min = 0.2, Max = 30, Default = 2, Suffix = "s", Flag = "luck_delay",
    Callback = safeCallback(function(v) S.luckBuyDelay = tonumber(v) or 2 end)
})
progAutoSub:AddDropdown({
    Name = "Buy mode", Options = { "1 Upgrade", "Max" }, Default = "1 Upgrade", Flag = "luck_mode",
    Callback = safeCallback(function(v) S.luckBuyMode = tostring(v) end)
})
progAutoSub:AddSlider({
    Name = "Keep cash", Min = 0, Max = 5000000, Default = 100000, Suffix = "$", Flag = "luck_reserve",
    Callback = safeCallback(function(v) S.upgradeReserve = tonumber(v) or 100000 end)
})

local progStatusLabel = progAutoSub:AddParagraph({ Title = "Status", Text = "..." })
local function ProgressStatusText()
    local count = MaxAffordableHatchUpgrades()
    local plot = OwnPlot()
    local nests = PlotNests(plot)
    local open, total = 0, 0
    if nests then
        for _, n in ipairs(nests:GetChildren()) do
            total = total + 1
            if n:GetAttribute("Unlocked") == true then open = open + 1 end
        end
    end
    return string.format("Luck Lv%d (x%.1f) | next %s $ | affordable %d | nests %d/%d | rebirths %s (%s $)",
        HatchUpgradeLevel(), HatchLuckMultiplier(), tostring(NextHatchUpgradePrice()), count,
        open, total, tostring(PlayerStat("Rebirths")), tostring(RebirthCost()))
end
task.spawn(function()
    while not HUB.dead do
        task.wait(2)
        pcall(function() progStatusLabel:Set(ProgressStatusText()) end)
    end
end)

-- Shops
local shopSub = shopTab:AddSubTab("Food & Feeding")
shopSub:AddToggle({
    Name = "Auto Buy Food", Default = false, Flag = "shop_buy_food",
    Callback = safeCallback(function(v) S.autoBuyFood = v StartLoops() end)
})
shopSub:AddMultiDropdown({
    Name = "Food to Buy", Options = HUB.ShopNames("Food"), Default = {}, Flag = "shop_food_names",
    Callback = safeCallback(function(names)
        S.buyFoods = {}
        for _, name in ipairs(names) do S.buyFoods[name] = true end
    end)
})
shopSub:AddToggle({
    Name = "Auto Feed Pets", Default = false, Flag = "shop_feed_pets",
    Callback = safeCallback(function(v) S.autoFeedPets = v StartLoops() end)
})
shopSub:AddMultiDropdown({
    Name = "Food to Feed (empty = any)", Options = HUB.ShopNames("Food"), Default = {}, Flag = "shop_feed_names",
    Callback = safeCallback(function(names)
        S.feedFoods = {}
        for _, name in ipairs(names) do S.feedFoods[name] = true end
    end)
})
shopSub:AddToggle({
    Name = "Auto Buy Gear", Default = false, Flag = "shop_buy_gear",
    Callback = safeCallback(function(v) S.autoBuyGear = v StartLoops() end)
})
shopSub:AddMultiDropdown({
    Name = "Gear to Buy", Options = HUB.ShopNames("Gears"), Default = {}, Flag = "shop_gear_names",
    Callback = safeCallback(function(names)
        S.buyGears = {}
        for _, name in ipairs(names) do S.buyGears[name] = true end
    end)
})
shopSub:AddSlider({
    Name = "Keep Cash", Min = 0, Max = 100000000, Default = 0, Flag = "shop_keep_cash",
    Callback = safeCallback(function(v) S.shopKeepCash = tonumber(v) or 0 end)
})
local shopStatus = shopSub:AddParagraph({ Title = "Shop", Text = HUB.ShopStatus })
task.spawn(function()
    while not HUB.dead do
        task.wait(2)
        pcall(function() shopStatus:Set(HUB.ShopStatus) end)
    end
end)

-- ESP
local espSub = espTab:AddSubTab("ESP")
espSub:AddToggle({
    Name = "Egg ESP", Default = false, Flag = "esp_egg",
    Callback = safeCallback(function(v) S.eggEsp = v RefreshESP() end)
})
espSub:AddToggle({
    Name = "Pet ESP (own green)", Default = false, Flag = "esp_pet",
    Callback = safeCallback(function(v) S.petEsp = v RefreshESP() end)
})
espSub:AddToggle({
    Name = "Player ESP", Default = false, Flag = "esp_player",
    Callback = safeCallback(function(v) S.playerEsp = v RefreshESP() end)
})
espSub:AddMultiDropdown({
    Name = "Rarity filter", Options = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Ethereal", "Divine", "Volcanic" },
    Default = {}, Flag = "esp_rarities",
    Callback = safeCallback(function(list)
        S.espRarities = {}
        for _, r in ipairs(list) do S.espRarities[r] = true end
        RefreshESP()
    end)
})
espSub:AddToggle({
    Name = "Eggs: name + distance", Default = true, Flag = "esp_egglabels",
    Callback = safeCallback(function(v) S.espEggLabels = v RefreshESP() end)
})
espSub:AddSlider({
    Name = "Eggs: markers up to (0 = all)", Min = 0, Max = 8000, Default = 0, Suffix = "studs", Flag = "esp_eggmax",
    Callback = safeCallback(function(v) S.espEggMaxDist = tonumber(v) or 0 RefreshESP() end)
})

-- Teleport
local teleportEggSub = teleportTab:AddSubTab("Eggs")
teleportEggSub:AddButton({
    Name = "Travel to next egg",
    Callback = safeCallback(function()
        local t = PickTargetEgg()
        if t then TravelToEgg(t) Notify("Teleport", t.name, "Success") else Notify("Teleport", "no egg", "Info") end
    end)
})
local teleportPlotSub = teleportTab:AddSubTab("Plot")
teleportPlotSub:AddButton({
    Name = "Return to my plot",
    Callback = safeCallback(TeleportToOwnPlot)
})
local teleportStallsSub = teleportTab:AddSubTab("Stalls")
teleportStallsSub:AddButton({ Name = "Food stall", Callback = safeCallback(function() TeleportToStall("Food") end) })
teleportStallsSub:AddButton({ Name = "Gear stall", Callback = safeCallback(function() TeleportToStall("Gears") end) })
teleportStallsSub:AddButton({ Name = "Sell stall", Callback = safeCallback(function() TeleportToStall("Sell") end) })
teleportStallsSub:AddButton({ Name = "Egg tracker", Callback = safeCallback(function() TeleportToStall("EggTracker") end) })

-- Settings
local setSub = setTab:AddSubTab("Config")
setSub:AddButton({
    Name = "Save config",
    Callback = safeCallback(function()
        if not HAS_CONFIG then return Notify("Config", "Config API unavailable", "Error") end
        Library:SaveConfig(CONFIG_NAME)
        Notify("Config", "Saved", "Success")
    end)
})
setSub:AddButton({
    Name = "Load config",
    Callback = safeCallback(function()
        if not HAS_CONFIG then return Notify("Config", "Config API unavailable", "Error") end
        Library:LoadConfig(CONFIG_NAME)
        Notify("Config", "Loaded", "Success")
    end)
})
setSub:AddButton({
    Name = "Unload Mizukage Official",
    Callback = safeCallback(function()
        if HUB.Unload then HUB.Unload() end
    end)
})

-- ==============================================================================
-- UNLOAD
-- ==============================================================================
function HUB.Unload()
    if HUB.dead then return end
    HUB.dead = true
    S.eggLoop, S.petLoop, S.progressLoop = false, false, false
    for _, c in ipairs(HUB.conns) do pcall(function() c:Disconnect() end) end
    HUB.conns = {}
    if HUB.noclipConn then pcall(function() HUB.noclipConn:Disconnect() end) end
    HUB.noclipConn = nil
    HUB.loopsRunning = nil
    for _, h in ipairs(HUB.highlights) do pcall(function() h.instance:Destroy() end) end
    HUB.highlights = {}
    pcall(ClearEggMarkers)
    S.farmNoclip, S.farmNoclipActive = false, false
    pcall(RestoreCollisions)
    pcall(function() Window:Destroy() end)
    if _G.MizukageRideAPet == HUB then _G.MizukageRideAPet = nil end
    print("[Mizukage Official] Ride A Pet unloaded.")
end

HUB.actions = {
    PickTargetEgg = PickTargetEgg,
    CollectEgg = CollectEgg,
    DeliverCarried = DeliverCarried,
    PlantBestEgg = PlantBestEgg,
    HatchReadyEggs = HatchReadyEggs,
    CollectPetEarnings = CollectPetEarnings,
    PlaceBestPets = PlaceBestPets,
    FeedPets = FeedPets,
    UnlockNests = UnlockNests,
    TryRebirth = TryRebirth,
    OwnPlot = OwnPlot,
    EggRecords = EggRecords,
    RenderedEggs = RenderedEggs,
    EggTools = EggTools,
    GrowthRemaining = GrowthRemaining,
    IsVolcanicEgg = IsVolcanicEgg,
    LairDoor = LairDoor,
    LairBounds = LairBounds,
    InsideLair = InsideLair,
    ServerSeesInsideLair = ServerSeesInsideLair,
    EnterLair = EnterLair,
}
StartLoops()
Notify("Mizukage Official", "Ride A Pet loaded", "Success", 3)

return HUB

end -- RunRideAPetEngine

-- ═══════════════════════════════════════════════════════════
-- [9] UI UTAMA (WindUI) + LIFECYCLE
-- ═══════════════════════════════════════════════════════════
local Hub
local visualsBuilt = false

OnFinalUnload = function()
    if not State.Alive then return end
    State.Alive = false
    RestoreSky()
    env.MizukageOfficialUnload = nil
    task.delay(0.4, function()
        env.MizukageOfficial = nil
        if Window and Window.Destroy then pcall(function() Window:Destroy() end) end
    end)
end

local function FullUnload()
    if Hub and type(Hub.Unload) == "function" then
        pcall(Hub.Unload)
    end
    OnFinalUnload()
end

BuildVisualsTab = function()
    if visualsBuilt then return end
    visualsBuilt = true

    local TabVisual = Window:Tab({ Title = "Visuals", Icon = "lucide:sparkles" })
    TabVisual:Section({ Title = "Sky / Lighting (client-side)" })
    StoreSky()

    local function ApplySky(preset)
        local data = SKY_PRESETS[preset]
        if not data then RestoreSky() return end
        for prop, value in pairs(data) do
            pcall(function() Lighting[prop] = value end)
        end
    end

    local skyNames = {}
    for name in pairs(SKY_PRESETS) do table.insert(skyNames, name) end
    table.sort(skyNames)
    table.insert(skyNames, 1, "Default") -- nilai nil tidak ikut di pairs()
    TabVisual:Dropdown({
        Title = "Sky Preset", Values = skyNames, Value = "Default",
        Callback = function(v) if type(v) == "table" then v = v.Title or v[1] end ApplySky(v) end,
    })
    TabVisual:Slider({
        Title = "Brightness", Step = 0.1,
        Value = { Min = 0, Max = 5, Default = math.clamp(State.SkyOriginals.Brightness or 1, 0, 5) },
        Callback = function(v) pcall(function() Lighting.Brightness = v end) end,
    })
    TabVisual:Slider({
        Title = "Exposure", Step = 0.1,
        Value = { Min = -2, Max = 2, Default = math.clamp(State.SkyOriginals.ExposureCompensation or 0, -2, 2) },
        Callback = function(v) pcall(function() Lighting.ExposureCompensation = v end) end,
    })
    TabVisual:Button({
        Title = "Restore Original Sky", Icon = "lucide:rotate-ccw", Variant = "Secondary",
        Callback = function() RestoreSky() SafeNotify("Sky", "Sky dikembalikan.", 3, "lucide:check") end,
    })
end

BuildInterfaceSection = function(tab)
    tab:Section({ Title = "Interface" })
    local themes = {}
    pcall(function() for name in pairs(WindUI:GetThemes()) do table.insert(themes, name) end end)
    table.sort(themes)
    if #themes == 0 then themes = { "Dark", "Light" } end
    tab:Dropdown({
        Title = "Theme", Values = themes, Value = "Dark",
        Callback = function(v)
            if type(v) == "table" then v = v.Title or v[1] end
            pcall(function() WindUI:SetTheme(v) end)
        end,
    })
    tab:Divider()
end

local function InitInterface()
    local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local isMobile = viewport.X < 850

    pcall(function()
        WindUI:Gradient({
            ["0"]   = { Color = Color3.fromHex("#5c5291"), Transparency = 0.15 },
            ["50"]  = { Color = Color3.fromHex("#0096ff"), Transparency = 0.10 },
            ["100"] = { Color = Color3.fromHex("#18181b"), Transparency = 0 },
        }, { Rotation = 45 })
    end)

    Window = WindUI:CreateWindow({
        Title        = BRAND,
        Icon         = "lucide:egg",
        Author       = AUTHOR,
        Folder       = FOLDER,
        Size         = isMobile
            and UDim2.fromOffset(viewport.X * 0.95, viewport.Y * 0.95)
            or  UDim2.fromOffset(840, 620),
        MinSize      = Vector2.new(560, 420),
        MaxSize      = Vector2.new(950, 780),
        ToggleKey    = Enum.KeyCode.RightShift,
        Transparent  = true,
        Theme        = "Dark",
        Accent       = Color3.fromRGB(145, 104, 255),
        Resizable    = true,
        SideBarWidth = isMobile and 220 or 250,
        HasOutline   = true,
        BackgroundImageTransparency = 0.42,
        Background   = "rbxassetid://137490169052447",
        ScrollBarEnabled = true,
        User = {
            Enabled   = true,
            Anonymous = false,
            Callback  = function()
                SafeNotify("Player Info", string.format("Name: %s\nDisplay: %s\nUserID: %s",
                    LocalPlayer.Name, LocalPlayer.DisplayName, LocalPlayer.UserId), 5, "lucide:user")
            end,
        },
    })

    pcall(function()
        Window:Tag({ Title = "MIZUKAGE OFFICIAL", Icon = "lucide:crown",    Color = Color3.fromHex("#FFD700"), Radius = 13 })
        Window:Tag({ Title = VERSION,             Icon = "lucide:sparkles", Color = Color3.fromHex("#30ff6a"), Radius = 6 })
        Window:Tag({ Title = "RIDE A PET",        Icon = "lucide:egg",      Color = Color3.fromHex("#0096ff"), Radius = 0 })
        Window:Divider()
    end)

    -- Dashboard
    local TabDash = Window:Tab({ Title = "Dashboard", Icon = "lucide:layout-dashboard" })
    TabDash:Section({ Title = "Status Live" })
    local StatusPara = TabDash:Paragraph({ Title = "Memuat Ride A Pet..." })

    -- Engine (inline)
    local ok, result = pcall(RunRideAPetEngine, AdapterLibrary, EggTypeAllowed, EggCanon)
    if ok then
        Hub = result
    else
        warn("[Mizukage Official] engine error: " .. tostring(result))
        SafeNotify(BRAND, "Engine gagal dimuat: " .. tostring(result), 10, "lucide:alert-triangle")
    end
    BuildVisualsTab() -- jaga-jaga bila engine berhenti sebelum tab Settings

    env.MizukageOfficialUnload = FullUnload

    -- Live dashboard
    task.spawn(function()
        local lastText
        while State.Alive do
            local S = Hub and Hub.state
            local text
            if S then
                local st = S.stats
                text = string.format(
                    "Engine: ONLINE\nAuto Farm: %s | Pet Farm: %s | Progress: %s\nEggs: %d | Delivered: %d | Hatched: %d | Planted: %d\nCash gained: %s | Uptime: %s",
                    S.eggLoop and "ON" or "OFF",
                    S.petLoop and "ON" or "OFF",
                    S.progressLoop and "ON" or "OFF",
                    st.eggs, st.delivered, st.hatched, st.planted,
                    ShortNumber(st.cash),
                    FormatTime(os.clock() - State.StartTime)
                )
            else
                text = "Engine: OFFLINE\nCek console (F9) untuk detail error."
            end
            if text ~= lastText then
                lastText = text
                pcall(function() StatusPara:SetTitle(text) end)
            end
            task.wait(1)
        end
    end)

    if Hub then
        SafeNotify(BRAND, "Ride A Pet siap.", 4, "lucide:check")
        task.wait(0.5)
        pcall(function()
            WindUI:Popup({
                Title   = "Selamat Datang",
                Icon    = "lucide:egg",
                Content = BRAND .. " — Ride A Pet " .. VERSION
                    .. "\n\nAuto Farm · Pets · Progress · Shops · ESP · Teleport"
                    .. "\n\nTahan Shift untuk jeda Auto Farm.",
                Buttons = {
                    { Title = "Tutup", Variant = "Tertiary", Callback = function() end },
                    { Title = "Mulai Auto Farm", Icon = "lucide:zap", Variant = "Primary",
                      Callback = function()
                          local handler = Flags.eggs_loop
                          if handler then pcall(handler.Set, true) end
                      end },
                },
            })
        end)
    end
end

task.spawn(function()
    local ok, err = pcall(InitInterface)
    if not ok then
        warn("[Mizukage Official] InitInterface gagal: " .. tostring(err))
        SafeNotify(BRAND, "UI gagal dibuat: " .. tostring(err), 8, "lucide:alert-triangle")
        env.MizukageOfficial = nil
    end
end)

print("[" .. BRAND .. "] Ride A Pet " .. VERSION .. " loaded")
