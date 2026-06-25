--========================================================================
-- MIZUKAGE OFFICIAL DATABASE - GAMES LIST (LENGKAP)
--========================================================================

-- GAME DENGAN PLACE ID VALID (AUTO DETECT)
local ValidGames = {
    [2753915549] = {
        Name = "Blox Fruits - World 1",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/%7Bscripts%2Cassets%7D/BF.lua"
    },
    [4442272183] = {
        Name = "Blox Fruits - World 2",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/%7Bscripts%2Cassets%7D/BF.lua"
    },
    [7449423635] = {
        Name = "Blox Fruits - World 3",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/%7Bscripts%2Cassets%7D/BF.lua"
    },

    [12377995562] = {
        Name = "T R O L L G E",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/scripts,assets/TROLLGE.lua"
    },

    [130342654546662] = {
        Name = "Sambung Kata",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/%7Bscripts%2Cassets%7D/Sambung%20kata.lua"
    },

    [86096929771195] = {
        Name = "Indo Beach",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/%7Bscripts%2Cassets%7D/Indobeach.lua"
    },

    [13253735473] = {
        Name = "Trident  Survival",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/scripts/Trident_Survival.lua"
    },

    [105423512432229] = {
        Name = "8  Bola  X",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/scripts/8-Bola_X.lua"
    },[97598239454123] = {
        Name = "G A G2",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/scripts/GAG2.lua"
    },

    [107646426076756] = {
        Name = "Build a ring farm",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/scripts/Build_a_ring_farm.lua"
    },
    [88599461076137] =
    [88599461076137] = {
        Name = "F I S H I N G  C H E F",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/scripts/FISHING_CHEF.lua"
    },
}

-- GAME DENGAN PLACE ID BELUM DIKETAHUI (HANYA UNTUK TELEPORT MANUAL)
local PendingGames = {
    {
        Name = "Aura Trade",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/%7Bscripts%2Cassets%7D/AuraTrade.lua",
        PlaceId = nil
    },
    {
        Name = "Blade Ball",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/%7Bscripts%2Cassets%7D/Bladeball.lua",
        PlaceId = nil
    },
    {
        Name = "Brookhaven",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/%7Bscripts%2Cassets%7D/Brookhaven.lua",
        PlaceId = nil
    },
    {
        Name = "Demonology",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/%7Bscripts%2Cassets%7D/Demonlogy.lua",
        PlaceId = nil
    },
    {
        Name = "Evade",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/%7Bscripts%2Cassets%7D/evade.lua",
        PlaceId = nil
    },
    {
        Name = "Flick",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/%7Bscripts%2Cassets%7D/flick.lua",
        PlaceId = nil
    },{
        Name = "Murder Mystery 2",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/%7Bscripts%2Cassets%7D/MM2.lua",
        PlaceId = nil
    },
    {
        Name = "Poop Game",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/%7Bscripts%2Cassets%7D/poopgame.lua",
        PlaceId = nil
    },{
        Name = "Sawah Indo",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/%7Bscripts%2Cassets%7D/Sawah%20indo.lua",
        PlaceId = nil
    },
    {
        Name = "Sawit Garden",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/%7Bscripts%2Cassets%7D/Sawit%20garden.lua",
        PlaceId = nil
    },
    {
        Name = "Tebak Yuk",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/%7Bscripts%2Cassets%7D/Tebakyuk.lua",
        PlaceId = nil
    },
    {
        Name = "Violence District",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/%7Bscripts%2Cassets%7D/VD.lua",
        PlaceId = nil
    },
    {
        Name = "Sell Lemon",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/%7Bscripts%2Cassets%7D/sell%20lemon.lua",
        PlaceId = nil
    },
    {
        Name = "Kamar Jenazah",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/%7Bscripts%2Cassets%7D/kamar%20jenazah.lua",
        PlaceId = 122093998639862
    },
    {
        Name = "Penjaga Makam",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/%7Bscripts%2Cassets%7D/penjaga-makam.lua",
        PlaceId = 133181691852151
    },

    {
        Name = "nametag",
        Script = "https://raw.githubusercontent.com/kazukage-id/Mizukage-Official/refs/heads/main/scripts/nametag.lua",
        PlaceId = nil
    },
}

return {
    Valid = ValidGames,
    Pending = PendingGames
}
