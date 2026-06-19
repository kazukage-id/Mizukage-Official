-- ==========================================================
-- MIZUKAGE ENGINE - ADVANCED VULNERABILITY TESTER
-- ==========================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "🍣 Mizukage Adv. Tester",
   LoadingTitle = "Memuat Modul Lanjutan...",
   LoadingSubtitle = "by Security Analyst",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false,
})

-- ==========================================
-- SERVICES & VARIABLES
-- ==========================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local KnitServices = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services")
local FishService = KnitServices:WaitForChild("Fish")
local CustomerService = KnitServices:WaitForChild("PlayerCustomerService")
local PurchaseController = KnitServices:WaitForChild("PurchaseController")

-- Global Settings
local getgenv = getfenv or function() return _G end
getgenv().Fishing = { Active = false, Power = 0.9, MinigameDelay = 5, LoopDelay = 2 }
getgenv().Cooking = { Active = false, FishID = 1, CutDelay = 1.5 }
getgenv().Serving = { Active = false, AutoTeleport = false, ServeDelay = 1 }

-- ==========================================
-- TAB 1: 🎣 AUTO FISHING (MANUAL TIMING)
-- ==========================================
local TabFishing = Window:CreateTab("🎣 Memancing", nil)

TabFishing:CreateSection("Pengaturan Jeda (Bypass Anti-Cheat)")

TabFishing:CreateSlider({
   Name = "Kekuatan Lemparan (Cast Power)",
   Range = {0.1, 1.0},
   Increment = 0.05,
   CurrentValue = 0.9,
   Flag = "FishPower",
   Callback = function(Value)
      getgenv().Fishing.Power = Value
   end,
})

TabFishing:CreateSlider({
   Name = "Jeda Tunggu Minigame (Detik)",
   Info = "Server menolak jika instan. Set ke 5-8 detik.",
   Range = {1, 15},
   Increment = 0.5,
   CurrentValue = 5,
   Flag = "MiniDelay",
   Callback = function(Value)
      getgenv().Fishing.MinigameDelay = Value
   end,
})

TabFishing:CreateSlider({
   Name = "Jeda Antar Lemparan (Detik)",
   Range = {1, 10},
   Increment = 0.5,
   CurrentValue = 2,
   Flag = "LoopDelay",
   Callback = function(Value)
      getgenv().Fishing.LoopDelay = Value
   end,
})

TabFishing:CreateToggle({
   Name = "Mulai Auto Fish (Custom Delay)",
   CurrentValue = false,
   Flag = "TglFish",
   Callback = function(Value)
      getgenv().Fishing.Active = Value
      if Value then
         task.spawn(function()
            while getgenv().Fishing.Active do
                -- 1. Lempar Pancing
                pcall(function()
                    FishService.RF.CastRequest:InvokeServer(getgenv().Fishing.Power)
                end)
                
                -- 2. Tunggu simulasi ikan memakan umpan (Sesuai Slider)
                task.wait(getgenv().Fishing.MinigameDelay)
                
                -- 3. Selesaikan Minigame
                if not getgenv().Fishing.Active then break end
                pcall(function()
                    FishService.RF.MinigameResolved:InvokeServer(true)
                end)
                
                -- 4. Jeda sebelum melempar lagi
                task.wait(getgenv().Fishing.LoopDelay)
            end
         end)
      end
   end,
})

-- ==========================================
-- TAB 2: 🔪 AUTO CUTTING (MANUAL TIMING)
-- ==========================================
local TabCooking = Window:CreateTab("🔪 Potong Ikan", nil)

TabCooking:CreateSection("Konfigurasi Potong")

TabCooking:CreateInput({
   Name = "ID Ikan (Lihat di Inventory)",
   Info = "Masukkan ID angka ikan yang ingin dipotong berulang.",
   PlaceholderText = "Contoh: 1, 2, atau 10",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      getgenv().Cooking.FishID = tonumber(Text) or 1
   end,
})

TabCooking:CreateSlider({
   Name = "Jeda Potong / Cut Delay (Detik)",
   Info = "Jangan terlalu cepat agar tidak kick/error.",
   Range = {0.5, 3},
   Increment = 0.1,
   CurrentValue = 1.5,
   Flag = "CutDelay",
   Callback = function(Value)
      getgenv().Cooking.CutDelay = Value
   end,
})

TabCooking:CreateToggle({
   Name = "Mulai Auto Cut Fish",
   CurrentValue = false,
   Flag = "TglCut",
   Callback = function(Value)
      getgenv().Cooking.Active = Value
      if Value then
         task.spawn(function()
            while getgenv().Cooking.Active do
                pcall(function()
                    -- Simulasi seperti traffic dump asli
                    FishService.RF.StartCutSession:InvokeServer()
                    task.wait(getgenv().Cooking.CutDelay)
                    
                    FishService.RE.CutAction:FireServer(1, 1.34)
                    task.wait(getgenv().Cooking.CutDelay)
                    
                    FishService.RE.CutAction:FireServer(2, 2.77)
                    
                    -- Memberi tahu server animasi selesai
                    if Workspace:FindFirstChild("Code") then
                        local stall = Workspace.Code.Plots:FindFirstChild(LocalPlayer.Name)
                        if stall then
                            FishService.RE.ServerAnims:FireServer("CuttingBoard", stall.STALL.CookingStation.CuttingBoard, false)
                        end
                    end
                    
                    task.wait(0.2)
                    -- Mengklaim hasil potongan berdasarkan ID yang diinput manual
                    FishService.RF.CutFish:InvokeServer(getgenv().Cooking.FishID, 1.6)
                end)
                task.wait(1.5)
            end
         end)
      end
   end,
})

-- ==========================================
-- TAB 3: 🧑‍🍳 AUTO SERVE (BYPASS DISTANCE)
-- ==========================================
local TabResto = Window:CreateTab("🧑‍🍳 Restoran", nil)

TabResto:CreateSection("Pelayanan Pelanggan")

TabResto:CreateToggle({
   Name = "Gunakan Teleport ke NPC (Bypass Jarak)",
   Info = "Centang ini jika server mengecek jarak (Magnitude).",
   CurrentValue = false,
   Flag = "TglTPNPC",
   Callback = function(Value)
      getgenv().Serving.AutoTeleport = Value
   end,
})

TabResto:CreateSlider({
   Name = "Jeda Pelayanan (Detik)",
   Range = {0.5, 5},
   Increment = 0.5,
   CurrentValue = 1,
   Flag = "ServeDelay",
   Callback = function(Value)
      getgenv().Serving.ServeDelay = Value
   end,
})

TabResto:CreateToggle({
   Name = "Mulai Auto Serve",
   CurrentValue = false,
   Flag = "TglServe",
   Callback = function(Value)
      getgenv().Serving.Active = Value
      if Value then
         task.spawn(function()
            while getgenv().Serving.Active do
                pcall(function()
                    local activeNPCs = Workspace:FindFirstChild("Code") and Workspace.Code:FindFirstChild("ActiveNPCs")
                    if activeNPCs then
                        for _, npc in ipairs(activeNPCs:GetChildren()) do
                            if npc.Name == "Customer" then
                                -- Teleport jika diaktifkan (menyelinap agar server mengira kita dekat)
                                if getgenv().Serving.AutoTeleport and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                    local root = LocalPlayer.Character.HumanoidRootPart
                                    local oldPos = root.CFrame
                                    root.CFrame = npc:GetPivot()
                                    task.wait(0.2)
                                    CustomerService.RE.StoreFood:FireServer(npc)
                                    task.wait(0.1)
                                    root.CFrame = oldPos -- Kembali ke posisi semula
                                else
                                    -- Serve dari jauh
                                    CustomerService.RE.StoreFood:FireServer(npc)
                                end
                                task.wait(getgenv().Serving.ServeDelay)
                            end
                        end
                    end
                end)
                task.wait(1)
            end
         end)
      end
   end,
})

-- ==========================================
-- TAB 4: 🚀 EXPLOIT LAINNYA
-- ==========================================
local TabMisc = Window:CreateTab("🚀 Lainnya", nil)

TabMisc:CreateButton({
   Name = "Jual Semua Ikan",
   Callback = function()
      pcall(function()
          PurchaseController.RE.SellFish:FireServer()
          FishService.RE.SellFish:FireServer()
      end)
      Rayfield:Notify({Title = "Terkirim", Content = "Remote jual ikan dikirim.", Duration = 2})
   end,
})

TabMisc:CreateButton({
   Name = "Perbarui Data Restoran (Fix Bug)",
   Info = "Kadang game nge-bug jika tidak update data restoran.",
   Callback = function()
      pcall(function()
          FishService.RF.RequestRestaurauntData:InvokeServer()
          FishService.RF.RequestFishData:InvokeServer()
      end)
      Rayfield:Notify({Title = "Refresh Data", Content = "Sinkronisasi dengan server...", Duration = 2})
   end,
})

TabMisc:CreateButton({
   Name = "Teleport ke Kedai Sendiri",
   Callback = function()
      pcall(function()
          local plot = Workspace.Code.Plots:FindFirstChild(LocalPlayer.Name)
          if plot and LocalPlayer.Character then
              LocalPlayer.Character.HumanoidRootPart.CFrame = plot.STALL.WorldPivot
          else
              Rayfield:Notify({Title = "Gagal", Content = "Kedai belum di-claim / tidak ditemukan.", Duration = 3})
          end
      end)
   end,
})
