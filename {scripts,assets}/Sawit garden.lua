-- MIZUKAGE OFFICIAL - Sawit Garden
-- Fitur: Auto Sawit (TP/Jalan), ESP, Save Tools, Auto Sell, dll.

if getgenv().MizuSawitGardenLoaded then return end
getgenv().MizuSawitGardenLoaded = true

getgenv().MizuConfig = getgenv().MizuConfig or { IsRunning = true }
local Config = getgenv().MizuConfig
Config.SawitGarden = Config.SawitGarden or {
    IsFarming = false,
    MoveMode = "TP",
    ESPEnabled = false,
    SavedTools = {},
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Character = nil
local HumanoidRootPart = nil
local Humanoid = nil

local function UpdateCharacterReferences(char)
    Character = char
    if Character then
        HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
        Humanoid = Character:WaitForChild("Humanoid")
    end
end

local function GetCharacter()
    local char = LocalPlayer.Character
    if char then UpdateCharacterReferences(char) end
    return Character
end
GetCharacter()
LocalPlayer.CharacterAdded:Connect(UpdateCharacterReferences)

-- Helper Functions
local function GetNearestPrompt(actionText)
    if not HumanoidRootPart then return nil end
    
    local nearestPrompt = nil
    local nearestDist = math.huge
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.ActionText == actionText and obj.Enabled then
            local parent = obj.Parent
            if parent and parent:IsA("BasePart") then
                local dist = (HumanoidRootPart.Position - parent.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearestPrompt = obj
                end
            end
        end
    end
    
    return nearestPrompt
end

local function GetAllPrompts(actionText)
    local prompts = {}
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.ActionText == actionText and obj.Enabled then
            local parent = obj.Parent
            if parent and parent:IsA("BasePart") then
                table.insert(prompts, {
                    prompt = obj,
                    dist = (HumanoidRootPart.Position - parent.Position).Magnitude
                })
            end
        end
    end
    
    table.sort(prompts, function(a, b) return a.dist < b.dist end)
    return prompts
end

-- Movement Functions
local function MoveToPosition(targetPart)
    if not targetPart or not HumanoidRootPart then return end
    
    if Config.SawitGarden.MoveMode == "TP" then
        HumanoidRootPart.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
        task.wait(0.15)
    else
        local targetPos = targetPart.Position
        Humanoid:MoveTo(targetPos)
        
        local timeout = tick() + 20
        local lastPos = HumanoidRootPart.Position
        local stuckCount = 0
        
        repeat
            task.wait(0.2)
            
            local currentPos = HumanoidRootPart.Position
            if (currentPos - lastPos).Magnitude < 0.5 then
                stuckCount = stuckCount + 1
            else
                stuckCount = 0
            end
            
            if stuckCount >= 5 then
                Humanoid.Jump = true
                task.wait(0.15)
                Humanoid:MoveTo(targetPos)
            end
            
            lastPos = currentPos
            
        until (HumanoidRootPart.Position - targetPos).Magnitude <= 5 or tick() > timeout
        
        Humanoid:MoveTo(targetPos)
        task.wait(0.5)
    end
end

-- Tools Management
local function GetAvailableTools()
    local tools = {}
    local seen = {}
    
    local function scanContainer(container)
        for _, item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") or item:IsA("HopperBin") then
                local name = item.Name
                local lowerName = string.lower(name)
                
                if not string.match(lowerName, "%d+%s*kg") and not seen[name] then
                    seen[name] = true
                    table.insert(tools, name)
                end
            end
        end
    end
    
    scanContainer(LocalPlayer.Backpack)
    if Character then scanContainer(Character) end
    
    table.sort(tools)
    return tools
end

local function EquipSavedTools()
    if #Config.SawitGarden.SavedTools == 0 then return end
    
    for _, toolName in ipairs(Config.SawitGarden.SavedTools) do
        local tool = LocalPlayer.Backpack:FindFirstChild(toolName)
        if tool and (tool:IsA("Tool") or tool:IsA("HopperBin")) then
            Humanoid:EquipTool(tool)
            task.wait(0.15)
        end
    end
end

-- Tools Selection UI
local function ShowToolsSelectionUI()
    local availableTools = GetAvailableTools()
    
    if #availableTools == 0 then
        return
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MizuSaveTools"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = game:GetService("CoreGui")
    
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.45
    background.BorderSizePixel = 0
    background.Parent = screenGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 320, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Pilih Tools untuk Disimpan"
    titleLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
    titleLabel.TextSize = 15
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = mainFrame
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 0, 280)
    scrollFrame.Position = UDim2.new(0, 10, 0, 45)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 220, 80)
    scrollFrame.Parent = mainFrame
    Instance.new("UICorner", scrollFrame).CornerRadius = UDim.new(0, 6)
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 4)
    listLayout.Parent = scrollFrame
    
    local selectedTools = {}
    for _, tool in ipairs(Config.SawitGarden.SavedTools) do
        selectedTools[tool] = true
    end
    
    local function UpdateButtonStyle(button, toolName)
        if selectedTools[toolName] then
            button.BackgroundColor3 = Color3.fromRGB(40, 90, 40)
            button.TextColor3 = Color3.fromRGB(120, 255, 120)
        else
            button.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            button.TextColor3 = Color3.fromRGB(200, 200, 220)
        end
    end
    
    local toolButtons = {}
    for index, toolName in ipairs(availableTools) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 34)
        button.LayoutOrder = index
        button.BorderSizePixel = 0
        button.TextSize = 13
        button.Font = Enum.Font.Gotham
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.Parent = scrollFrame
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 5)
        
        local btnPadding = Instance.new("UIPadding", button)
        btnPadding.PaddingLeft = UDim.new(0, 10)
        
        button.Text = (selectedTools[toolName] and "✅  " or "⬜  ") .. toolName
        UpdateButtonStyle(button, toolName)
        
        button.MouseButton1Click:Connect(function()
            selectedTools[toolName] = not selectedTools[toolName]
            button.Text = (selectedTools[toolName] and "✅  " or "⬜  ") .. toolName
            UpdateButtonStyle(button, toolName)
        end)
        
        table.insert(toolButtons, {btn = button, name = toolName})
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #availableTools * 38 + 12)
    
    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.48, 0, 0, 36)
    saveBtn.Position = UDim2.new(0.01, 0, 0, 340)
    saveBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 30)
    saveBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
    saveBtn.Text = "Simpan"
    saveBtn.TextSize = 14
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.BorderSizePixel = 0
    saveBtn.Parent = mainFrame
    Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 8)
    
    saveBtn.MouseButton1Click:Connect(function()
        local newTools = {}
        for _, item in ipairs(toolButtons) do
            if selectedTools[item.name] then
                table.insert(newTools, item.name)
            end
        end
        
        Config.SawitGarden.SavedTools = newTools
        screenGui:Destroy()
    end)
    
    local cancelBtn = Instance.new("TextButton")
    cancelBtn.Size = UDim2.new(0.48, 0, 0, 36)
    cancelBtn.Position = UDim2.new(0.51, 0, 0, 340)
    cancelBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
    cancelBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    cancelBtn.Text = "Batal"
    cancelBtn.TextSize = 14
    cancelBtn.Font = Enum.Font.GothamBold
    cancelBtn.BorderSizePixel = 0
    cancelBtn.Parent = mainFrame
    Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 8)
    
    cancelBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    background.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            screenGui:Destroy()
        end
    end)
end

-- Sell Sawit
local function SellSawit()
    local sellPrompt = GetNearestPrompt("Jual Sawit")
    
    if not sellPrompt or not sellPrompt.Parent or not sellPrompt.Parent:IsA("BasePart") then
        return
    end
    
    MoveToPosition(sellPrompt.Parent)
    task.wait(0.2)
    
    local finalPrompt = GetNearestPrompt("Jual Sawit")
    if finalPrompt then
        fireproximityprompt(finalPrompt)
    end
end

-- ESP Functions
local ESPColors = {
    Nyawit = {
        fill = Color3.fromRGB(50, 200, 80),
        outline = Color3.fromRGB(0, 255, 60)
    },
    ["Jual Sawit"] = {
        fill = Color3.fromRGB(220, 170, 20),
        outline = Color3.fromRGB(255, 215, 0)
    }
}

local espObjects = {}

local function ClearESP()
    for _, obj in ipairs(espObjects) do
        if obj then pcall(function() obj:Destroy() end) end
    end
    espObjects = {}
end

local function UpdateESP()
    ClearESP()
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and ESPColors[obj.ActionText] then
            local parent = obj.Parent
            if parent and parent:IsA("BasePart") then
                local model = parent:FindFirstAncestorOfClass("Model")
                if model and not model:FindFirstChildOfClass("SelectionBox") then
                    local colors = ESPColors[obj.ActionText]
                    local box = Instance.new("SelectionBox")
                    box.Adornee = model
                    box.Color3 = colors.outline
                    box.LineThickness = 0.06
                    box.SurfaceTransparency = 0.6
                    box.SurfaceColor3 = colors.fill
                    box.Parent = Workspace
                    table.insert(espObjects, box)
                end
            end
        end
    end
end

-- Collect Loop
local lastActionTime = tick()
local function CollectSawit()
    if not HumanoidRootPart then return end
    
    local nyawitPrompt = GetNearestPrompt("Nyawit")
    
    if not nyawitPrompt or not nyawitPrompt.Parent then
        if tick() - lastActionTime >= 30 then
            lastActionTime = tick()
        end
        task.wait(1)
        return
    end
    
    MoveToPosition(nyawitPrompt.Parent)
    task.wait(0.1)
    
    EquipSavedTools()
    
    if nyawitPrompt.Enabled then
        lastActionTime = tick()
        fireproximityprompt(nyawitPrompt)
        
        local startTime = tick()
        while tick() - startTime < 22 do
            task.wait(1)
            if Config.SawitGarden.IsFarming then
                lastActionTime = tick()
            end
        end
        
        local collectPrompts = GetAllPrompts("Ambil")
        for _, item in ipairs(collectPrompts) do
            if item.prompt and item.prompt.Enabled then
                fireproximityprompt(item.prompt)
                task.wait(0.05)
            end
        end
    end
end

-- Anti AFK
task.spawn(function()
    while Config.IsRunning do
        task.wait(240)
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end
end)

-- Main Farm Loop
task.spawn(function()
    while Config.IsRunning do
        task.wait(0.3)
        if Config.SawitGarden.IsFarming then
            pcall(CollectSawit)
        else
            task.wait(1)
        end
    end
end)

-- ESP Update Loop
task.spawn(function()
    while Config.IsRunning do
        task.wait(3)
        if Config.SawitGarden.ESPEnabled then
            pcall(UpdateESP)
        end
    end
end)

-- Keyboard Shortcuts
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    local key = input.KeyCode
    
    if key == Enum.KeyCode.F5 then
        Config.SawitGarden.IsFarming = not Config.SawitGarden.IsFarming
    elseif key == Enum.KeyCode.F6 then
        task.spawn(SellSawit)
    elseif key == Enum.KeyCode.F7 then
        Config.SawitGarden.ESPEnabled = not Config.SawitGarden.ESPEnabled
        if not Config.SawitGarden.ESPEnabled then ClearESP() end
    elseif key == Enum.KeyCode.F8 then
        Config.SawitGarden.MoveMode = (Config.SawitGarden.MoveMode == "TP" and "Jalan" or "TP")
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
        Author = "Sawit Garden",
        Folder = "MizukageSawitGarden",
        Size = UDim2.fromOffset(650, 500),
        Theme = "Dark",
        Accent = Color3.fromRGB(0, 200, 80),
        SideBarWidth = 210,
        HasOutline = true,
    })

    local MainTab = Window:Tab({ Title = "Auto Sawit", Icon = "grass" })
    local InfoTab = Window:Tab({ Title = "Info", Icon = "info" })

    MainTab:Section({ Title = "🎮 Kontrol" })
    MainTab:Toggle({ Title = "Auto Sawit", Default = Config.SawitGarden.IsFarming, Callback = function(s) Config.SawitGarden.IsFarming = s; if s then lastActionTime = tick() end end })
    MainTab:Dropdown({ Title = "Mode", Values = {"TP", "Jalan"}, Value = Config.SawitGarden.MoveMode, Callback = function(v) Config.SawitGarden.MoveMode = v[1] end })
    MainTab:Toggle({ Title = "ESP Pohon & Kios", Default = Config.SawitGarden.ESPEnabled, Callback = function(s) Config.SawitGarden.ESPEnabled = s; if s then pcall(UpdateESP) else ClearESP() end end })

    MainTab:Section({ Title = "🛠️ Aksi Manual" })
    MainTab:Button({ Title = "Jual Sawit Sekarang", Variant = "Secondary", Callback = function() task.spawn(SellSawit) end })

    MainTab:Section({ Title = "🔧 Tools" })
    MainTab:Button({ Title = "Save My Tools", Variant = "Secondary", Callback = ShowToolsSelectionUI })
    MainTab:Button({ Title = "Lihat Saved Tools", Variant = "Secondary", Callback = function()
        if #Config.SawitGarden.SavedTools == 0 then
            return
        else
            WindUI:Notify({ Title = "Saved Tools", Content = table.concat(Config.SawitGarden.SavedTools, ", "), Duration = 3 })
        end
    end })

    MainTab:Section({ Title = "⌨️ Shortcut Keyboard" })
    MainTab:Paragraph({ Title = "F5", Desc = "Toggle Auto Sawit" })
    MainTab:Paragraph({ Title = "F6", Desc = "Jual Sawit Sekarang" })
    MainTab:Paragraph({ Title = "F7", Desc = "Toggle ESP" })
    MainTab:Paragraph({ Title = "F8", Desc = "Select Mode Sawit" })

    InfoTab:Section({ Title = "📌 Save Tools" })
    InfoTab:Paragraph({ Title = "📌", Desc = "Klik 'Save My Tools'" })
    InfoTab:Paragraph({ Title = "📌", Desc = "Centang tool yang mau auto-dipegang" })
    InfoTab:Paragraph({ Title = "📌", Desc = "Auto-equip tiap siklus farm dimulai" })

    WindUI:Notify({ Title = "Mizukage System", Content = "Sawit Garden loaded!", Duration = 3 })
end

task.spawn(InitUI)
