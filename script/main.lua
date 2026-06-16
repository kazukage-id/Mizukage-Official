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

-- ══════════════════════════════════
-- LETAKKAN KODE HUB KAMU DI BAWAH INI
-- ══════════════════════════════════

-- contoh:
-- local gui = require(...)
-- gui:Init()

print("[Mizukage] Main script loaded successfully.")
