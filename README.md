# 水 Mizukage Official — Script Hub

<div align="center">

![Version](https://img.shields.io/badge/version-2.0.0-00e5ff?style=for-the-badge&labelColor=0d1220)
![Status](https://img.shields.io/badge/status-online-00e676?style=for-the-badge&labelColor=0d1220)
![Lua](https://img.shields.io/badge/language-Lua-a855f7?style=for-the-badge&labelColor=0d1220)

**Premium Roblox Script Hub dengan Aesthetic Water UI Loader**

[📖 Dokumentasi](https://mizukageofficial.mintlify.app/) • [💬 Discord](https://discord.gg/Mizukage-Official) • [🐛 Report Bug](../../issues)

</div>

---

## ⚡ Quick Start

Paste kode ini di executor kamu:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/NAMA_KAMU/mizukage/main/loader.lua"))()
```

---

## 📁 Struktur File

```
mizukage/
├── loader.lua          ← Loader utama (yang dieksekusi user)
├── README.md
├── scripts/
│   └── main.lua        ← Script hub utama kamu
└── docs/
    └── index.html      ← Dokumentasi (GitHub Pages)
```

---

## ✨ Fitur Loader

- 🎨 **Water Aesthetic UI** — Dark theme dengan cyan & purple gradient
- 🔤 **Kanji Logo 水** — Animasi glow pulse
- 📊 **Progress Bar Animasi** — Gradient fill dengan langkah-langkah status
- 🛡️ **Anti Double-Execute** — Flag `getgenv()` mencegah loader dobel
- ✅ **Executor Check** — Validasi HttpGet & loadstring sebelum jalan
- 🧹 **Auto Cleanup** — GUI & flag global dihapus otomatis
- 🔒 **pcall Protection** — Error script utama ditangkap sebagai notifikasi

---

## ⚙️ Konfigurasi

Edit variabel berikut di `loader.lua`:

| Variabel | Default | Keterangan |
|---|---|---|
| `ACCENT` | `Color3.fromRGB(0,255,255)` | Warna cyan utama |
| `ACCENT2` | `Color3.fromRGB(100,80,255)` | Warna purple gradient |
| `MAIN_SCRIPT_URL` | *(kosong)* | **Wajib diisi** — URL raw script utama |

---

## 🛡️ Executor yang Didukung

| Executor | Platform | Status |
|---|---|---|
| Synapse Z | PC | ✅ Full |
| Fluxus | PC / Android | ✅ Full |
| Delta | Android | ✅ Supported |
| Hydrogen | iOS / Android | ✅ Supported |
| Arceus X | Android | ⚠️ Partial |

---

## 🚀 Deploy Dokumentasi

1. Pergi ke **Settings → Pages**
2. Source: **Deploy from branch** → branch `main` → folder `/docs`
3. Save → tunggu ~1 menit
4. Live di: `https://mizukageofficial.mintlify.app/`

---

<div align="center">
Made with 💙 by Mizukage Dev Team
</div>
