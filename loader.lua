--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║              MIZUKAGE OFFICIAL — PREMIUM LOADER              ║
    ║           Aesthetic UI Loader v2.0 by Mizukage Dev           ║
    ╚══════════════════════════════════════════════════════════════╝
    
    GitHub  : https://github.com/NAMA_KAMU/mizukage
    Discord : discord.gg/INVITE_KAMU
]]

-- ══════════════════════════════════
-- [1] ANTI DOUBLE-EXECUTE & GUARD
-- ══════════════════════════════════
if getgenv().MizukageLoaderActive then return end
getgenv().MizukageLoaderActive = true

if not (game.HttpGet and loadstring) then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title   = "⛔ Mizukage Error",
        Text    = "Executor kamu tidak mendukung HttpGet / loadstring!",
        Duration = 6
    })
    return
end

-- ══════════════════════════════════
-- [2] SERVICE & VARIABLE
-- ══════════════════════════════════
local CoreGui      = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local Players      = game:GetService("Players")

local ACCENT    = Color3.fromRGB(0, 255, 255)   -- Cyan
local ACCENT2   = Color3.fromRGB(100, 80, 255)  -- Purple
local BG_DARK   = Color3.fromRGB(10, 10, 18)
local BG_MID    = Color3.fromRGB(20, 20, 35)
local BG_PANEL  = Color3.fromRGB(30, 30, 50)
local TXT_MAIN  = Color3.fromRGB(220, 230, 255)
local TXT_SUB   = Color3.fromRGB(130, 140, 170)

-- ══════════════════════════════════
-- [3] UI BUILDER HELPER
-- ══════════════════════════════════
local function New(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function Corner(r, parent)
    return New("UICorner", {CornerRadius = UDim.new(0, r)}, parent)
end

local function Gradient(c1, c2, rot, parent)
    return New("UIGradient", {
        Color    = ColorSequence.new(c1, c2),
        Rotation = rot or 90
    }, parent)
end

local function Tween(obj, props, time, style, dir)
    local t = TweenService:Create(obj,
        TweenInfo.new(time or 0.4,
            style or Enum.EasingStyle.Quart,
            dir   or Enum.EasingDirection.Out),
        props)
    t:Play()
    return t
end

-- ══════════════════════════════════
-- [4] BUILD SCREEN GUI
-- ══════════════════════════════════
local Screen = New("ScreenGui", {
    Name             = "MizukageLoader",
    ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn     = false,
    IgnoreGuiInset   = true,
    Parent           = RunService:IsStudio()
        and Players.LocalPlayer:WaitForChild("PlayerGui")
        or CoreGui
})

-- Full-screen dark overlay
local Overlay = New("Frame", {
    Size                 = UDim2.fromScale(1, 1),
    BackgroundColor3     = Color3.new(0, 0, 0),
    BackgroundTransparency = 1,
    ZIndex               = 1
}, Screen)

-- Scanline texture effect (subtle)
local Scanlines = New("Frame", {
    Size                 = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ZIndex               = 2
}, Overlay)
New("UIPattern", {}, Scanlines) -- decorative, not all executors support

-- Center card
local Card = New("Frame", {
    AnchorPoint          = Vector2.new(0.5, 0.5),
    Position             = UDim2.fromScale(0.5, 0.5),
    Size                 = UDim2.fromOffset(0, 0),
    BackgroundColor3     = BG_DARK,
    ClipsDescendants     = true,
    ZIndex               = 10
}, Screen)
Corner(14, Card)

-- Card top gradient stripe
local TopStripe = New("Frame", {
    Size             = UDim2.new(1, 0, 0, 3),
    BackgroundColor3 = ACCENT,
    ZIndex           = 11
}, Card)
Corner(2, TopStripe)
Gradient(ACCENT, ACCENT2, 0, TopStripe)

-- Card background gradient
local CardBG = New("Frame", {
    Size             = UDim2.fromScale(1, 1),
    BackgroundColor3 = BG_DARK,
    ZIndex           = 10
}, Card)
Gradient(BG_DARK, BG_MID, 135, CardBG)

-- Glow circle behind logo
local GlowCircle = New("Frame", {
    AnchorPoint          = Vector2.new(0.5, 0.5),
    Position             = UDim2.new(0.5, 0, 0.28, 0),
    Size                 = UDim2.fromOffset(70, 70),
    BackgroundColor3     = ACCENT,
    BackgroundTransparency = 0.82,
    ZIndex               = 11
}, Card)
Corner(35, GlowCircle)

-- Logo icon (water kanji)
local Logo = New("TextLabel", {
    AnchorPoint          = Vector2.new(0.5, 0.5),
    Position             = UDim2.new(0.5, 0, 0.28, 0),
    Size                 = UDim2.fromOffset(50, 50),
    BackgroundTransparency = 1,
    Text                 = "水",    -- Kanji for "Water" / Mizu
    Font                 = Enum.Font.GothamBold,
    TextSize             = 32,
    TextColor3           = ACCENT,
    TextTransparency     = 1,
    ZIndex               = 12
}, Card)

-- Title
local Title = New("TextLabel", {
    AnchorPoint          = Vector2.new(0.5, 0),
    Position             = UDim2.new(0.5, 0, 0.44, 0),
    Size                 = UDim2.new(1, -40, 0, 28),
    BackgroundTransparency = 1,
    Text                 = "MIZUKAGE OFFICIAL",
    Font                 = Enum.Font.GothamBold,
    TextSize             = 19,
    TextColor3           = TXT_MAIN,
    TextTransparency     = 1,
    ZIndex               = 12
}, Card)

-- Subtitle
local Subtitle = New("TextLabel", {
    AnchorPoint          = Vector2.new(0.5, 0),
    Position             = UDim2.new(0.5, 0, 0.57, 0),
    Size                 = UDim2.new(1, -40, 0, 16),
    BackgroundTransparency = 1,
    Text                 = "Premium Script Hub",
    Font                 = Enum.Font.Gotham,
    TextSize             = 11,
    TextColor3           = ACCENT,
    TextTransparency     = 1,
    ZIndex               = 12
}, Card)

-- Divider
local Divider = New("Frame", {
    AnchorPoint          = Vector2.new(0.5, 0),
    Position             = UDim2.new(0.5, 0, 0.67, 0),
    Size                 = UDim2.new(0.7, 0, 0, 1),
    BackgroundColor3     = ACCENT,
    BackgroundTransparency = 0.7,
    ZIndex               = 12
}, Card)

-- Status text
local StatusText = New("TextLabel", {
    AnchorPoint          = Vector2.new(0.5, 0),
    Position             = UDim2.new(0.5, 0, 0.72, 0),
    Size                 = UDim2.new(1, -40, 0, 16),
    BackgroundTransparency = 1,
    Text                 = "Memulai Mizukage...",
    Font                 = Enum.Font.GothamSemibold,
    TextSize             = 11,
    TextColor3           = TXT_SUB,
    TextTransparency     = 1,
    ZIndex               = 12
}, Card)

-- Progress track
local ProgressTrack = New("Frame", {
    AnchorPoint          = Vector2.new(0.5, 0),
    Position             = UDim2.new(0.5, 0, 0.84, 0),
    Size                 = UDim2.new(0.8, 0, 0, 5),
    BackgroundColor3     = BG_PANEL,
    BackgroundTransparency = 1,
    ZIndex               = 12
}, Card)
Corner(4, ProgressTrack)

-- Progress fill
local ProgressFill = New("Frame", {
    Size                 = UDim2.new(0, 0, 1, 0),
    BackgroundColor3     = ACCENT,
    ZIndex               = 13
}, ProgressTrack)
Corner(4, ProgressFill)
Gradient(ACCENT, ACCENT2, 0, ProgressFill)

-- Progress glow
local ProgressGlow = New("Frame", {
    AnchorPoint          = Vector2.new(1, 0.5),
    Position             = UDim2.fromScale(1, 0.5),
    Size                 = UDim2.fromOffset(12, 12),
    BackgroundColor3     = ACCENT,
    BackgroundTransparency = 0.5,
    ZIndex               = 13
}, ProgressFill)
Corner(6, ProgressGlow)

-- Version label
local VersionLabel = New("TextLabel", {
    AnchorPoint          = Vector2.new(0.5, 1),
    Position             = UDim2.new(0.5, 0, 0.97, 0),
    Size                 = UDim2.new(1, -40, 0, 14),
    BackgroundTransparency = 1,
    Text                 = "v2.0 • mizukage.vercel.app",
    Font                 = Enum.Font.Gotham,
    TextSize             = 9,
    TextColor3           = TXT_SUB,
    TextTransparency     = 1,
    ZIndex               = 12
}, Card)

-- ══════════════════════════════════
-- [5] ANIMASI INTRO
-- ══════════════════════════════════

-- Fade in overlay
Tween(Overlay, {BackgroundTransparency = 0.45}, 0.5)
task.wait(0.1)

-- Pop-in card
Tween(Card, {Size = UDim2.fromOffset(340, 200)}, 0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
task.wait(0.45)

-- Reveal text elements
Tween(Logo,        {TextTransparency = 0}, 0.35)
task.wait(0.08)
Tween(Title,       {TextTransparency = 0}, 0.35)
task.wait(0.08)
Tween(Subtitle,    {TextTransparency = 0}, 0.35)
task.wait(0.08)
Tween(StatusText,  {TextTransparency = 0}, 0.3)
Tween(ProgressTrack, {BackgroundTransparency = 0}, 0.3)
Tween(VersionLabel, {TextTransparency = 0.5}, 0.3)
task.wait(0.3)

-- Glow pulse loop (runs while loading)
local pulsing = true
task.spawn(function()
    while pulsing do
        Tween(GlowCircle, {BackgroundTransparency = 0.72}, 0.8)
        task.wait(0.85)
        Tween(GlowCircle, {BackgroundTransparency = 0.88}, 0.8)
        task.wait(0.85)
    end
end)

-- ══════════════════════════════════
-- [6] LOADING STEPS
-- ══════════════════════════════════
local function Step(text, progress, waitTime)
    Tween(StatusText, {TextTransparency = 1}, 0.15)
    task.wait(0.18)
    StatusText.Text = text
    Tween(StatusText, {TextTransparency = 0}, 0.15)
    Tween(ProgressFill, {Size = UDim2.new(progress, 0, 1, 0)}, 0.45)
    task.wait(waitTime)
end

Step("Memeriksa Koneksi...",        0.20, 0.7)
Step("Memvalidasi Executor...",     0.40, 0.7)
Step("Menghubungi Server...",       0.60, 0.8)
Step("Mengunduh Script Utama...",   0.85, 0.9)
Step("Memuat Mizukage Hub...",      1.00, 0.5)

-- ══════════════════════════════════
-- [7] ANIMASI OUTRO
-- ══════════════════════════════════
pulsing = false

-- Flash accent
Tween(Card, {BackgroundColor3 = Color3.fromRGB(0, 30, 40)}, 0.15)
task.wait(0.15)
Tween(Card, {BackgroundColor3 = BG_DARK}, 0.15)
task.wait(0.15)

-- Fade everything out
Tween(Logo,          {TextTransparency = 1}, 0.25)
Tween(Title,         {TextTransparency = 1}, 0.25)
Tween(Subtitle,      {TextTransparency = 1}, 0.25)
Tween(StatusText,    {TextTransparency = 1}, 0.25)
Tween(VersionLabel,  {TextTransparency = 1}, 0.25)
Tween(ProgressTrack, {BackgroundTransparency = 1}, 0.25)
Tween(ProgressFill,  {BackgroundTransparency = 1}, 0.25)
task.wait(0.3)

Tween(Card,    {Size = UDim2.fromOffset(0, 0)},   0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
Tween(Overlay, {BackgroundTransparency = 1},       0.4)
task.wait(0.45)

Screen:Destroy()
getgenv().MizukageLoaderActive = nil

-- ══════════════════════════════════
-- [8] EKSEKUSI SCRIPT UTAMA
-- ══════════════════════════════════
--  ▶  Ganti URL di bawah dengan link raw GitHub script utama kamu
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/script/main.lua"

local ok, err = pcall(function()
    loadstring(game:HttpGet(MAIN_SCRIPT_URL, true))()
end)

if not ok then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title    = "⛔ Mizukage Error",
        Text     = "Gagal memuat script utama. Cek koneksi kamu!",
        Duration = 7
    })
    warn("[Mizukage Loader] Error: " .. tostring(err))
end
