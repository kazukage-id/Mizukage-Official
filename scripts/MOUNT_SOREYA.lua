--[[
    MIZUKAGE AUTO FISH
    Rayfield Gen2 | Core PATEN (nilai dan alur tidak diubah)
    Fitur tambahan: Auto Sell, Sync Dance, Speed Lock, Teleport, Server Info
]]

-- ═══════════════════════════════════════════════════════════
-- [1] SINGLETON GUARD
-- ═══════════════════════════════════════════════════════════
local SCRIPT_ID = "MizukageAutoFishFast_Gen2"
local G = (getgenv and getgenv()) or _G

if G[SCRIPT_ID .. "_Cleanup"] then
    warn("[Mizukage] Instance lama dihentikan")
    pcall(G[SCRIPT_ID .. "_Cleanup"])
end
G[SCRIPT_ID] = true

-- ═══════════════════════════════════════════════════════════
-- [2] SERVICES
-- ═══════════════════════════════════════════════════════════
local Players     = game:GetService("Players")
local RS          = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local LP = Players.LocalPlayer

-- Deklarasi awal agar bisa dipakai oleh fungsi di bawahnya
local Rayfield

-- ═══════════════════════════════════════════════════════════
-- [3] CLEANUP MANAGER
-- ═══════════════════════════════════════════════════════════
local Cleanup = { _conns = {}, _tasks = {}, _fns = {} }

function Cleanup:AddConn(tag, conn)
    self._conns[tag] = self._conns[tag] or {}
    table.insert(self._conns[tag], conn)
end

function Cleanup:AddTask(tag, thread)
    self._tasks[tag] = self._tasks[tag] or {}
    table.insert(self._tasks[tag], thread)
end

function Cleanup:AddFn(tag, fn)
    self._fns[tag] = self._fns[tag] or {}
    table.insert(self._fns[tag], fn)
end

function Cleanup:Clean(tag)
    for _, c in ipairs(self._conns[tag] or {}) do
        pcall(function() c:Disconnect() end)
    end
    self._conns[tag] = nil

    for _, t in ipairs(self._tasks[tag] or {}) do
        pcall(task.cancel, t)
    end
    self._tasks[tag] = nil

    for _, f in ipairs(self._fns[tag] or {}) do
        pcall(f)
    end
    self._fns[tag] = nil
end

function Cleanup:CleanAll()
    local tags = {}
    for t in pairs(self._conns) do tags[t] = true end
    for t in pairs(self._tasks) do tags[t] = true end
    for t in pairs(self._fns) do tags[t] = true end
    for t in pairs(tags) do self:Clean(t) end
end

-- ═══════════════════════════════════════════════════════════
-- [4] PATEN SETTINGS (JANGAN DIUBAH)
-- ═══════════════════════════════════════════════════════════
local C = {
    -- Auto Fish PATEN
    on          = false,
    rod         = "Withering Rod",
    power       = 25,
    castWindup  = 0.01,
    tandaDur    = 0,
    catchDelay  = 0.50,
    retryDelay  = 0.05,
    nextCast    = 0.30,
    biteTimeout = 12,

    -- Tambahan
    AutoSellOnFull = false,
    AutoSyncOn     = false,
    AntiAFK        = true,
    SpeedLock      = false,
    SpeedVal       = 32,
    SellThreshold  = 5,   -- 5=Legendary 6=Mythic 7=SECRET 8=FORGOTTEN
    TpTarget       = "",
    CpNumber       = 1,
    SyncRange      = 100,
}

local S = {
    caught = 0, missed = 0, state = "IDLE",
    sales  = 0, sold   = 0, coins = 0,
    selling = false, syncTo = nil,
}
local evt = { bite = false, got = false, stop = false }

-- ═══════════════════════════════════════════════════════════
-- [5] CORE HELPERS (PATEN)
-- ═══════════════════════════════════════════════════════════
local function remotes()
    local ch   = workspace:FindFirstChild(LP.Name)
    local rod  = ch and ch:FindFirstChild(C.rod)
    local mech = rod and rod:FindFirstChild("Mechanics")
    local rm   = mech and mech:FindFirstChild("Remotes")
    if not rm then return nil end
    return {
        cast = rm:FindFirstChild("CastEvent"),
        mini = rm:FindFirstChild("MiniGame"),
        note = rm:FindFirstChild("NotifyClient"),
    }
end

local function equip()
    local ch = workspace:FindFirstChild(LP.Name)
    if ch and ch:FindFirstChild(C.rod) then return true end
    local bp = LP:FindFirstChild("Backpack")
    local t  = bp and bp:FindFirstChild(C.rod)
    if t and ch then
        t.Parent = ch
        task.wait(0.3)
        return true
    end
    return false
end

-- ═══════════════════════════════════════════════════════════
-- [6] LISTENERS (PATEN, cleanup-aware)
-- ═══════════════════════════════════════════════════════════
local lastCast, lastMini, lastNote

local function resetListeners()
    Cleanup:Clean("Fish")
    lastCast, lastMini, lastNote = nil, nil, nil
end

local function ensureListeners(R)
    if R.cast == lastCast and R.mini == lastMini and R.note == lastNote then return end
    resetListeners()
    lastCast, lastMini, lastNote = R.cast, R.mini, R.note

    local RSTanda = RS:FindFirstChild("TandaSeruBersama")

    if R.note then
        Cleanup:AddConn("Fish", R.note.OnClientEvent:Connect(function(a)
            if a == "Bite" then
                if not C.on then return end
                evt.bite = true
                if RSTanda then
                    pcall(function() RSTanda:FireServer(nil, nil, nil, C.tandaDur) end)
                end
                task.wait(C.catchDelay)
                if R.mini then R.mini:FireServer(true) end
            elseif a == "GotFish" then
                evt.got = true
                S.caught += 1
            end
        end))
    end

    if R.mini then
        Cleanup:AddConn("Fish", R.mini.OnClientEvent:Connect(function(a)
            if a == "Stop" then
                evt.stop = true
                if evt.bite and not evt.got and R.mini then
                    task.wait(C.retryDelay)
                    R.mini:FireServer(true)
                end
            end
        end))
    end
end

-- ═══════════════════════════════════════════════════════════
-- [7] CYCLE (PATEN)
-- ═══════════════════════════════════════════════════════════
local function cycle()
    if not equip() then S.state = "NO ROD"; task.wait(0.5); return end
    local R = remotes()
    if not R or not R.cast then S.state = "NO REMOTE"; task.wait(0.5); return end
    ensureListeners(R)

    evt.bite, evt.got, evt.stop = false, false, false

    S.state = "CAST"
    R.cast:FireServer(true)
    if C.castWindup > 0 then task.wait(C.castWindup) end
    R.cast:FireServer(false, C.power, nil)

    S.state = "WAIT"
    local t0 = tick()
    while C.on and tick() - t0 < C.biteTimeout and not evt.got do
        task.wait(0.02)
    end
    if not evt.got then S.missed += 1 end

    S.state = "IDLE"
    if C.nextCast > 0 then task.wait(C.nextCast) end
end

-- ═══════════════════════════════════════════════════════════
-- [8] MAIN LOOP (PATEN)
-- ═══════════════════════════════════════════════════════════
Cleanup:AddTask("AutoFish", task.spawn(function()
    while true do
        if C.on then
            pcall(cycle)
        else
            task.wait(0.3)
        end
    end
end))

-- ═══════════════════════════════════════════════════════════
-- [9] HELPERS
-- ═══════════════════════════════════════════════════════════
local function notify(title, content, duration)
    if not Rayfield then return end
    pcall(function()
        Rayfield:Notify({ title = title, content = content, duration = duration or 3 })
    end)
end

local function getRemote(folder, name)
    local r = RS:FindFirstChild("Remote")
    local f = r and r:FindFirstChild(folder)
    return f and f:FindFirstChild(name)
end

local function sellAll()
    if S.selling then return false end
    local js = getRemote("Mancing", "JualSemua")
    if not js then return false end
    S.selling = true
    local ok, coins = pcall(function() return js:InvokeServer() end)
    S.selling = false
    if ok then
        S.sales += 1
        local c = tonumber(coins) or 0
        if c > 0 then S.coins += c end
        return true
    end
    return false
end

local function setSellThreshold(lvl)
    local at = getRemote("Mancing", "AturAmbangJual")
    if at then pcall(function() at:InvokeServer(lvl) end) end
end

-- Listener HasilJual (Auto Sell saat tas penuh)
Cleanup:AddTask("HasilJual", task.spawn(function()
    local hj = getRemote("Mancing", "HasilJual")
    if not hj then return end
    Cleanup:AddConn("HasilJual", hj.OnClientEvent:Connect(function(data)
        if type(data) ~= "table" then return end
        if data.sebab == "penuh" then
            S.sold  += tonumber(data.jumlah) or 0
            S.coins += tonumber(data.total) or 0
        elseif data.sebab == "penuhGagal" and C.AutoSellOnFull then
            task.spawn(sellAll)
        end
    end))
end))

local function setSync(userId)
    local st = getRemote("SyncDance", "SyncTo")
    if st then pcall(function() st:FireServer(userId) end) end
end

local function doRejoin()
    local rj = getRemote("Sistem", "Rejoin")
    if rj then pcall(function() rj:FireServer() end) end
end

local function nearestPlayer(maxDist)
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local best, bestD = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if r then
                local d = (r.Position - myRoot.Position).Magnitude
                if d < bestD and d <= maxDist then best, bestD = p, d end
            end
        end
    end
    return best
end

local function tpToPlayer(name)
    if type(name) ~= "string" or name == "" then return false end
    local q = name:lower()
    local target
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and (p.Name:lower():find(q, 1, true) or p.DisplayName:lower():find(q, 1, true)) then
            target = p
            break
        end
    end
    if not target then return false end
    local myRoot  = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local tgtRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if myRoot and tgtRoot then
        myRoot.CFrame = tgtRoot.CFrame + Vector3.new(0, 3, 0)
        return true
    end
    return false
end

local function tpToCp(num)
    local cp = getRemote("Checkpoint", "TpToCheckpoint")
    if cp then pcall(function() cp:FireServer(tonumber(num) or 1) end) end
end

local function setSpeed(v)
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end

local function equipSpeedCoil()
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("Tool") and (c.Name == "Speed60" or c.Name == "Speed45") then return true end
    end
    local bp   = LP:FindFirstChild("Backpack")
    local coil = bp and (bp:FindFirstChild("Speed60") or bp:FindFirstChild("Speed45"))
    if coil then
        pcall(function() hum:EquipTool(coil) end)
        return true
    end
    return false
end

local function getLuckInfo()
    local sl = RS:FindFirstChild("Remote") and RS.Remote:FindFirstChild("ServerLuck")
    local ev = sl and sl:FindFirstChild("Event")
    if not ev then return 1, 0 end
    local luck, mut = 1, 0
    local now = os.time()
    for _, e in ipairs(ev:GetChildren()) do
        local smp = tonumber(e:GetAttribute("Sampai")) or 0
        if now < smp then
            local l = tonumber(e:GetAttribute("Luck")) or 0
            if luck < l then luck = l end
            mut += tonumber(e:GetAttribute("Mutasi")) or 0
        end
    end
    return luck, mut
end

-- ═══════════════════════════════════════════════════════════
-- [10] BACKGROUND LOOPS
-- ═══════════════════════════════════════════════════════════
-- Auto Sync: hanya kirim saat target berubah
Cleanup:AddTask("AutoSync", task.spawn(function()
    while true do
        task.wait(1.5)
        if C.AutoSyncOn then
            local p  = nearestPlayer(C.SyncRange)
            local id = p and p.UserId or nil
            if id ~= S.syncTo then
                S.syncTo = id
                setSync(id)
            end
        end
    end
end))

-- Speed Lock
Cleanup:AddTask("SpeedLock", task.spawn(function()
    while true do
        task.wait(0.5)
        if C.SpeedLock then setSpeed(C.SpeedVal) end
    end
end))

-- Anti AFK
Cleanup:AddConn("AntiAFK", LP.Idled:Connect(function()
    if C.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end
end))

-- Respawn: reset listener dan terapkan speed
Cleanup:AddConn("Char", LP.CharacterAdded:Connect(function(char)
    task.wait(1)
    resetListeners()
    S.state = "IDLE"
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and (C.SpeedLock or C.SpeedVal ~= 16) then
        hum.WalkSpeed = C.SpeedVal
    end
end))

-- ═══════════════════════════════════════════════════════════
-- [11] RAYFIELD UI
-- ═══════════════════════════════════════════════════════════
local ok, lib = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/gen2"))()
end)
if not ok or not lib then
    warn("[Mizukage] Gagal memuat UI Rayfield:", lib)
    G[SCRIPT_ID] = nil
    return
end
Rayfield = lib

local Window = Rayfield:CreateWindow({
    name                   = "Mizukage Auto Fish",
    subtitle               = "Ultimate Edition  v2",
    sidebarLayout          = true,
    theme                  = "Amethyst",
    disableRayfieldPrompts = true,
    disableBuildWarnings   = true,
})

-- ── DASHBOARD ──
local TabHome = Window:CreateTab({ name = "Dashboard" })
TabHome:CreateSection({ name = "Kontrol Utama" })

TabHome:CreateToggle({
    name         = "Auto Fish",
    currentValue = C.on,
    callback     = function(v)
        C.on = v
        if not v then S.state = "IDLE" end
    end,
})

TabHome:CreateDivider()
TabHome:CreateSection({ name = "Statistik Memancing" })

local stCaught = TabHome:CreateStat({ name = "Ikan Didapat", value = "0" })
local stMissed = TabHome:CreateStat({ name = "Ikan Gagal",   value = "0" })
local stState  = TabHome:CreateStat({ name = "Status",       value = "IDLE" })

TabHome:CreateDivider()
TabHome:CreateSection({ name = "Statistik Jual" })

local stSales = TabHome:CreateStat({ name = "Transaksi Jual", value = "0" })
local stSold  = TabHome:CreateStat({ name = "Ikan Terjual",   value = "0" })
local stCoins = TabHome:CreateStat({ name = "Total Koin",     value = "0" })

TabHome:CreateDivider()
TabHome:CreateSection({ name = "Info Server" })

local stLuck    = TabHome:CreateStat({ name = "Server Luck",   value = "x1" })
local stMut     = TabHome:CreateStat({ name = "Mutasi Bonus",  value = "+0" })
local stPlayers = TabHome:CreateStat({ name = "Pemain Online", value = "0" })

TabHome:CreateButton({
    name     = "Refresh Info Server",
    callback = function()
        local luck, mut = getLuckInfo()
        stLuck:Set("x" .. tostring(luck))
        stMut:Set("+" .. tostring(mut))
        stPlayers:Set(tostring(#Players:GetPlayers()))
    end,
})

-- ── AUTO FISH ──
local TabFish = Window:CreateTab({ name = "Auto Fish" })
TabFish:CreateSection({ name = "Paten Settings (Jangan Diubah)" })

TabFish:CreateInput({
    name         = "Nama Rod",
    placeholder  = "Withering Rod",
    currentValue = C.rod,
    callback     = function(t)
        if t and t ~= "" and t ~= C.rod then
            C.rod = t
            resetListeners()
            notify("Rod", "Rod diganti ke: " .. t)
        end
    end,
})

TabFish:CreateSlider({
    name = "Power", range = {5, 100}, increment = 1, suffix = "",
    currentValue = C.power,
    callback = function(v) C.power = v end,
})

TabFish:CreateSlider({
    name = "Cast Windup (x0.01 dtk)", range = {0, 50}, increment = 1, suffix = "",
    currentValue = math.floor(C.castWindup * 100 + 0.5),
    callback = function(v) C.castWindup = v / 100 end,
})

TabFish:CreateSlider({
    name = "Tanda Seru Durasi", range = {0, 10}, increment = 1, suffix = " dtk",
    currentValue = C.tandaDur,
    callback = function(v) C.tandaDur = v end,
})

TabFish:CreateSlider({
    name = "Catch Delay (x0.01 dtk)", range = {10, 150}, increment = 5, suffix = "",
    currentValue = math.floor(C.catchDelay * 100 + 0.5),
    callback = function(v) C.catchDelay = v / 100 end,
})

TabFish:CreateSlider({
    name = "Retry Delay (x0.01 dtk)", range = {1, 50}, increment = 1, suffix = "",
    currentValue = math.floor(C.retryDelay * 100 + 0.5),
    callback = function(v) C.retryDelay = v / 100 end,
})

TabFish:CreateSlider({
    name = "Next Cast Delay (x0.01 dtk)", range = {5, 200}, increment = 5, suffix = "",
    currentValue = math.floor(C.nextCast * 100 + 0.5),
    callback = function(v) C.nextCast = v / 100 end,
})

TabFish:CreateSlider({
    name = "Bite Timeout", range = {5, 30}, increment = 1, suffix = " dtk",
    currentValue = C.biteTimeout,
    callback = function(v) C.biteTimeout = v end,
})

-- ── AUTO SELL ──
local TabSell = Window:CreateTab({ name = "Auto Sell" })
TabSell:CreateSection({ name = "Jual Ikan" })

TabSell:CreateButton({
    name     = "Jual Semua Sekarang",
    callback = function()
        local done = sellAll()
        notify("Auto Sell", done and "Semua ikan berhasil dijual" or "Gagal atau tidak ada ikan", 3)
    end,
})

TabSell:CreateToggle({
    name         = "Auto Jual Saat Tas Penuh",
    currentValue = C.AutoSellOnFull,
    callback     = function(v) C.AutoSellOnFull = v end,
})

local thresholdMap = {
    ["Legendary (5)"] = 5,
    ["Mythic (6)"]    = 6,
    ["SECRET (7)"]    = 7,
    ["FORGOTTEN (8)"] = 8,
}

TabSell:CreateDropdown({
    name            = "Threshold Jual Otomatis",
    options         = {"Legendary (5)", "Mythic (6)", "SECRET (7)", "FORGOTTEN (8)"},
    currentOption   = "Legendary (5)",
    multipleOptions = false,
    callback        = function(v)
        local val = type(v) == "table" and v[1] or v
        C.SellThreshold = thresholdMap[val] or 5
        setSellThreshold(C.SellThreshold)
    end,
})

-- ── PLAYER ──
local TabPlayer = Window:CreateTab({ name = "Player" })
TabPlayer:CreateSection({ name = "Karakter" })

TabPlayer:CreateSlider({
    name = "WalkSpeed", range = {16, 200}, increment = 1, suffix = " spd",
    currentValue = C.SpeedVal,
    callback = function(v)
        C.SpeedVal = v
        setSpeed(v)
    end,
})

TabPlayer:CreateToggle({
    name         = "Speed Lock",
    currentValue = C.SpeedLock,
    callback     = function(v)
        C.SpeedLock = v
        if v then setSpeed(C.SpeedVal) end
    end,
})

TabPlayer:CreateButton({
    name     = "Equip Speed Coil (Speed60 / Speed45)",
    callback = function()
        local ok2 = equipSpeedCoil()
        notify("Speed Coil", ok2 and "Coil berhasil di-equip" or "Tidak punya coil", 3)
    end,
})

TabPlayer:CreateToggle({
    name         = "Anti AFK",
    currentValue = C.AntiAFK,
    callback     = function(v) C.AntiAFK = v end,
})

TabPlayer:CreateButton({
    name     = "Reset Karakter",
    callback = function()
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h.Health = 0 end
    end,
})

TabPlayer:CreateSection({ name = "Teleport Pemain" })

TabPlayer:CreateInput({
    name         = "Nama Pemain Target",
    placeholder  = "ketik username...",
    currentValue = "",
    callback     = function(t) C.TpTarget = t or "" end,
})

TabPlayer:CreateButton({
    name     = "Teleport ke Pemain",
    callback = function()
        if C.TpTarget == "" then
            notify("Teleport", "Isi nama pemain terlebih dahulu", 3)
            return
        end
        local ok2 = tpToPlayer(C.TpTarget)
        notify("Teleport", ok2 and ("Berhasil ke " .. C.TpTarget) or "Pemain tidak ditemukan", 3)
    end,
})

TabPlayer:CreateSection({ name = "Teleport Checkpoint" })

TabPlayer:CreateSlider({
    name = "Nomor Checkpoint (0 = BC)", range = {0, 30}, increment = 1, suffix = "",
    currentValue = C.CpNumber,
    callback = function(v) C.CpNumber = v end,
})

TabPlayer:CreateButton({
    name     = "Teleport ke Checkpoint",
    callback = function() tpToCp(C.CpNumber) end,
})

TabPlayer:CreateSection({ name = "Sync Dance" })

TabPlayer:CreateToggle({
    name         = "Auto Sync ke Pemain Terdekat",
    currentValue = C.AutoSyncOn,
    callback     = function(v)
        C.AutoSyncOn = v
        if not v then
            S.syncTo = nil
            setSync(nil)
        end
    end,
})

TabPlayer:CreateSlider({
    name = "Jarak Sync", range = {10, 300}, increment = 10, suffix = " studs",
    currentValue = C.SyncRange,
    callback = function(v) C.SyncRange = v end,
})

-- ── SYSTEM ──
local TabSystem = Window:CreateTab({ name = "System" })
TabSystem:CreateSection({ name = "Server" })

TabSystem:CreateButton({
    name     = "Rejoin Server",
    callback = function() doRejoin() end,
})

TabSystem:CreateDivider()
TabSystem:CreateSection({ name = "Zona Berbahaya" })

local function unload()
    C.on = false
    C.AutoSyncOn = false
    C.SpeedLock = false
    S.syncTo = nil
    pcall(setSync, nil)
    Cleanup:CleanAll()
    resetListeners()
    G[SCRIPT_ID] = nil
    G[SCRIPT_ID .. "_Cleanup"] = nil
    pcall(function() Rayfield:Destroy() end)
end

TabSystem:CreateButton({
    name     = "Unload Script",
    callback = unload,
})

-- ═══════════════════════════════════════════════════════════
-- [12] STATS UPDATE LOOP (kirim hanya saat nilai berubah)
-- ═══════════════════════════════════════════════════════════
local statCache = {}
local function push(key, stat, val)
    if statCache[key] ~= val then
        statCache[key] = val
        pcall(function() stat:Set(val) end)
    end
end

Cleanup:AddTask("StatsLoop", task.spawn(function()
    local elapsed = 0
    while true do
        task.wait(0.3)
        push("caught", stCaught, tostring(S.caught))
        push("missed", stMissed, tostring(S.missed))
        push("state",  stState,  S.state)
        push("sales",  stSales,  tostring(S.sales))
        push("sold",   stSold,   tostring(S.sold))
        push("coins",  stCoins,  tostring(S.coins))

        elapsed += 0.3
        if elapsed >= 5 then
            elapsed = 0
            local luck, mut = getLuckInfo()
            push("luck",    stLuck,    "x" .. tostring(luck))
            push("mut",     stMut,     "+" .. tostring(mut))
            push("players", stPlayers, tostring(#Players:GetPlayers()))
        end
    end
end))

-- ═══════════════════════════════════════════════════════════
-- [13] CLEANUP HOOK & STARTUP
-- ═══════════════════════════════════════════════════════════
G[SCRIPT_ID .. "_Cleanup"] = unload

task.spawn(function()
    task.wait(1)
    setSellThreshold(C.SellThreshold)
end)

notify("Mizukage Auto Fish", "Pengaturan PATEN dimuat. Siap memancing.", 5)