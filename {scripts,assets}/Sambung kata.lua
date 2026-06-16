-- MIZUKAGE OFFICIAL - Sambung Kata (Word Chain Game)
-- Fitur: Auto Answer, Answer Panel, Anti AFK, Like Human Typing, Blacklist, dll.

if getgenv().MizuSambungKataLoaded then return end
getgenv().MizuSambungKataLoaded = true

getgenv().MizuConfig = getgenv().MizuConfig or { IsRunning = true }
local Config = getgenv().MizuConfig
Config.SambungKata = Config.SambungKata or {
    AutoAnswer = false,
    ShowAnswerPanel = false,
    AntiAFK = false,
    HumanTyping = false,
    ShowNotification = true,
    FilterMode = "RANDOM",
    KeyDelay = 0.06,
    SubmitDelay = 0.1,
    AutoAnswerDelay = 0.8,
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- State
local State = {
    wordsByFirstLetter = {},
    allWords = {},
    usedWords = {},
    blacklistedWords = {},
    currentPrefix = "",
    isMyTurn = false,
    isSubmitting = false,
    mistakeCount = 0,
    turnStatus = false,
}

local humanTypingCounter = 0
local humanTypingThreshold = math.random(2, 5)
local AnswerPanel = nil
local AnswerPanelConnection = nil
local AntiAFKTask = nil
local AutoAnswerTask = nil

-- Utilities
local function TableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

local function IsValidWord(word)
    return #word >= 2 and #word <= 15
end

-- Remotes
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local SubmitWordRemote = nil
if Remotes then
    SubmitWordRemote = Remotes:FindFirstChild("SubmitWord")
end

-- UI Helper
local function FindMatchUI()
    return PlayerGui:FindFirstChild("MatchUI")
end

local function FindBottomUI()
    local matchUI = FindMatchUI()
    if not matchUI then return nil end
    return matchUI:FindFirstChild("BottomUI")
end

local function FindKeyboard()
    local bottomUI = FindBottomUI()
    if not bottomUI then return nil end
    return bottomUI:FindFirstChild("Keyboard")
end

local function FindTextBox()
    local bottomUI = FindBottomUI()
    if not bottomUI then return nil end
    return bottomUI:FindFirstChildWhichIsA("TextBox", true)
end

local function IsInputActive()
    if LocalPlayer:GetAttribute("IsTurn") == true then return true end
    if State.turnStatus then return true end
    
    local matchUI = FindMatchUI()
    if not matchUI then return false end
    
    local bottomUI = FindBottomUI()
    if not bottomUI then return false end
    
    local keyboard = FindKeyboard()
    if keyboard and keyboard.Visible then return true end
    
    local textBox = FindTextBox()
    if textBox and textBox.Visible then return true end
    
    return false
end

local function GetCurrentPrefix()
    local matchUI = FindMatchUI()
    if not matchUI then return State.currentPrefix end
    
    local bottomUI = FindBottomUI()
    if not bottomUI then return State.currentPrefix end
    
    local topUI = bottomUI:FindFirstChild("TopUI")
    if not topUI then return State.currentPrefix end
    
    local wordServerFrame = topUI:FindFirstChild("WordServerFrame")
    if not wordServerFrame then return State.currentPrefix end
    
    local wordServer = wordServerFrame:FindFirstChild("WordServer")
    if not wordServer then return State.currentPrefix end
    
    local text = wordServer.Text or ""
    if #text == 0 then return State.currentPrefix end
    
    local cleanText = string.gsub(text, "%s+", "")
    local length = #cleanText
    
    if length >= 5 then
        return string.lower(string.sub(cleanText, -5))
    elseif length >= 4 then
        return string.lower(string.sub(cleanText, -4))
    elseif length >= 3 then
        return string.lower(string.sub(cleanText, -3))
    elseif length >= 2 then
        return string.lower(string.sub(cleanText, -2))
    elseif length >= 1 then
        return string.lower(string.sub(cleanText, -1))
    end
    
    return State.currentPrefix
end

-- Keyboard Typing
local function SendKey(key)
    VirtualInputManager:SendKeyEvent(true, key, false, game)
    task.wait(Config.SambungKata.KeyDelay)
    VirtualInputManager:SendKeyEvent(false, key, false, game)
end

local function SendBackspace()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Backspace, false, game)
    task.wait(0.04)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Backspace, false, game)
end

local function ClearInput()
    for _ = 1, 20 do
        SendBackspace()
        task.wait(0.02)
    end
end

local function TypeWord(word, prefix)
    local wordLength = #word
    local prefixLength = #prefix
    local isHumanTyping = Config.SambungKata.HumanTyping
    
    if isHumanTyping then
        humanTypingCounter = humanTypingCounter + 1
        local shouldMakeMistake = false
        local mistakePosition = -1
        
        if humanTypingCounter >= humanTypingThreshold then
            if wordLength - prefixLength + 1 >= 2 then
                shouldMakeMistake = true
                mistakePosition = math.random(prefixLength, wordLength)
            end
            humanTypingCounter = 0
            humanTypingThreshold = math.random(2, 5)
        end
        
        for i = prefixLength, wordLength do
            local char = string.sub(word, i, i)
            local keyCode = Enum.KeyCode[string.upper(char)]
            
            if shouldMakeMistake and i == mistakePosition then
                if keyCode then
                    SendKey(keyCode)
                    task.wait(math.random(10, 15) * 0.01)
                end
                
                local randomChar = string.char(math.random(97, 122))
                local randomKey = Enum.KeyCode[string.upper(randomChar)]
                
                if randomKey then
                    task.wait(math.random(5, 25) * 0.01)
                    SendKey(randomKey)
                    task.wait(math.random(10, 15) * 0.01)
                    SendBackspace()
                    task.wait(0.6)
                end
            else
                if keyCode then
                    SendKey(keyCode)
                    if i < wordLength then
                        task.wait(math.random(10, 15) * 0.01)
                    end
                end
            end
        end
    else
        for i = prefixLength, wordLength do
            local char = string.sub(word, i, i)
            local keyCode = Enum.KeyCode[string.upper(char)]
            if keyCode then
                SendKey(keyCode)
                if i < wordLength then
                    task.wait(Config.SambungKata.KeyDelay)
                end
            end
        end
        
        task.wait(Config.SambungKata.SubmitDelay)
        SendKey(Enum.KeyCode.Return)
    end
end

-- Submit Word
local function SubmitWord(word, prefix, source)
    if not IsInputActive() then
        return false
    end
    
    if State.isSubmitting then return false end
    
    State.isSubmitting = true
    ClearInput()
    task.wait(0.1)
    
    if not IsInputActive() then
        State.isSubmitting = false
        return false
    end
    
    word = string.lower(word)
    
    TypeWord(word, prefix)
    State.usedWords[word] = true
    
    task.wait(0.2)
    State.isSubmitting = false
    
    return true
end

-- Word Database
local function InitializeWordIndex()
    for i = 97, 122 do
        State.wordsByFirstLetter[string.char(i)] = {}
    end
end

local function GetWordPriority(word)
    local suffixes = {
        ["if"] = 100, ["ng"] = 95, ["um"] = 92, ["ea"] = 91,
        ["nya"] = 90, ["q"] = 85, ["x"] = 85, ["ik"] = 70,
        ["an"] = 60, ["er"] = 50, ["us"] = 40, ["ud"] = 40
    }
    
    for suffix, priority in pairs(suffixes) do
        if string.sub(word, -#suffix) == suffix then
            return priority
        end
    end
    
    return 0
end

local function SortWordsByPriority(words)
    table.sort(words, function(a, b)
        local priorityA = GetWordPriority(a)
        local priorityB = GetWordPriority(b)
        if priorityA ~= priorityB then return priorityA > priorityB end
        return #a < #b
    end)
    return words
end

local function FilterWordsByMode(words, prefix, limit)
    limit = limit or 20
    local filtered = {}
    
    if Config.SambungKata.FilterMode == "PRIORITY" then
        filtered = words
    elseif Config.SambungKata.FilterMode == "SHORTEST" then
        table.sort(words, function(a, b) return #a < #b end)
        filtered = words
    elseif Config.SambungKata.FilterMode == "LONGEST" then
        table.sort(words, function(a, b) return #a > #b end)
        filtered = words
    elseif Config.SambungKata.FilterMode == "RANDOM" then
        for i = #words, 2, -1 do
            local j = math.random(i)
            words[i], words[j] = words[j], words[i]
        end
        filtered = words
    else
        local suffixMap = {
            ["IF"] = "if", ["NG"] = "ng", ["NYA"] = "nya",
            ["UM"] = "um", ["EA"] = "ea", ["SM"] = "sm",
            ["KL"] = "kl", ["JM"] = "jm", ["GC"] = "gc",
            ["GY"] = "gy", ["CY"] = "cy", ["LS"] = "ls",
            ["KS"] = "ks", ["MS"] = "ms"
        }
        
        local targetSuffix = suffixMap[Config.SambungKata.FilterMode]
        if targetSuffix then
            for _, word in ipairs(words) do
                if string.sub(word, -#targetSuffix) == targetSuffix then
                    table.insert(filtered, word)
                end
            end
            table.sort(filtered, function(a, b) return #a < #b end)
        else
            filtered = words
        end
    end
    
    local result = {}
    for i = 1, math.min(#filtered, limit) do
        table.insert(result, filtered[i])
    end
    
    return result
end

local function GetMatchingWords(prefix)
    if not prefix or prefix == "" then return {} end
    
    local firstChar = string.sub(prefix, 1, 1)
    local wordsWithPrefix = State.wordsByFirstLetter[firstChar] or {}
    local matches = {}
    
    for _, word in ipairs(wordsWithPrefix) do
        if string.sub(word, 1, #prefix) == prefix then
            local isUsed = State.usedWords[word]
            local isBlacklisted = State.blacklistedWords[word]
            
            if not isUsed and not isBlacklisted then
                table.insert(matches, word)
            end
        end
    end
    
    return FilterWordsByMode(matches, prefix, 20)
end

local function LoadWordDatabase(urls)
    InitializeWordIndex()
    
    for _, url in ipairs(urls) do
        local success, content = pcall(function() return game:HttpGet(url) end)
        
        if success and content then
            State.allWords = {}
            State.wordsByFirstLetter = {}
            InitializeWordIndex()
            State.usedWords = {}
            State.blacklistedWords = {}
            
            for word in string.gmatch(content, "[%a]+") do
                word = string.lower(word)
                if IsValidWord(word) then
                    table.insert(State.allWords, word)
                    
                    local firstChar = string.sub(word, 1, 1)
                    if State.wordsByFirstLetter[firstChar] then
                        table.insert(State.wordsByFirstLetter[firstChar], word)
                    end
                end
            end
            
            for firstChar, words in pairs(State.wordsByFirstLetter) do
                SortWordsByPriority(words)
            end
            
            return true
        end
    end
    
    return false
end

-- Auto Answer
local function StartAutoAnswer()
    if AutoAnswerTask then task.cancel(AutoAnswerTask) end
    
    AutoAnswerTask = task.spawn(function()
        local lastPrefix = ""
        
        while Config.SambungKata.AutoAnswer do
            if IsInputActive() then
                local currentPrefix = GetCurrentPrefix()
                
                if currentPrefix ~= "" then
                    if currentPrefix ~= lastPrefix then lastPrefix = currentPrefix end
                    
                    task.wait(Config.SambungKata.AutoAnswerDelay)
                    
                    local matches = GetMatchingWords(currentPrefix)
                    local bestMatch = matches[1]
                    
                    if bestMatch then
                        SubmitWord(bestMatch, currentPrefix, "auto")
                        task.wait(Config.SambungKata.AutoAnswerDelay)
                    else
                        task.wait(0.8)
                    end
                else
                    task.wait(0.3)
                end
            else
                task.wait(0.3)
            end
        end
    end)
end

local function StopAutoAnswer()
    Config.SambungKata.AutoAnswer = false
    if AutoAnswerTask then task.cancel(AutoAnswerTask); AutoAnswerTask = nil end
end

-- Anti AFK
local function StartAntiAFK()
    if AntiAFKTask then task.cancel(AntiAFKTask) end
    
    AntiAFKTask = task.spawn(function()
        while Config.SambungKata.AntiAFK do
            pcall(function()
                game:GetService("VirtualUser"):CaptureController()
                game:GetService("VirtualUser"):ClickButton2(Vector2.new())
            end)
            task.wait(60)
            
            local character = LocalPlayer.Character
            local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
            
            if humanoidRootPart then
                humanoidRootPart.CFrame = humanoidRootPart.CFrame + Vector3.new(1, 0, 0)
                task.wait(0.1)
                humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position)
            end
        end
    end)
end

local function StopAntiAFK()
    if AntiAFKTask then task.cancel(AntiAFKTask); AntiAFKTask = nil end
end

-- Answer Panel
local function CreateAnswerPanel()
    if AnswerPanel then pcall(function() AnswerPanel:Destroy() end) end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MizuAnswerPanel"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 999998
    screenGui.Parent = PlayerGui
    AnswerPanel = screenGui
    
    local mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.fromOffset(200, 280)
    mainFrame.Position = UDim2.fromScale(0.02, 0.2)
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 20, 50)
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.Active = true
    mainFrame.ClipsDescendants = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
    
    local titleBar = Instance.new("Frame", mainFrame)
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(80, 50, 160)
    titleBar.BackgroundTransparency = 0.1
    titleBar.Active = true
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)
    
    local titleLabel = Instance.new("TextLabel", titleBar)
    titleLabel.Size = UDim2.new(1, -34, 1, 0)
    titleLabel.Position = UDim2.fromOffset(8, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "PILIH JAWABAN"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 11
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.Size = UDim2.fromOffset(20, 20)
    closeBtn.Position = UDim2.new(1, -25, 0.5, -10)
    closeBtn.Text = "×"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 80)
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.AutoButtonColor = false
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)
    
    closeBtn.MouseButton1Click:Connect(function()
        Config.SambungKata.ShowAnswerPanel = false
        if AnswerPanel then AnswerPanel:Destroy() end
    end)
    
    local infoFrame = Instance.new("Frame", mainFrame)
    infoFrame.Size = UDim2.new(1, -16, 0, 40)
    infoFrame.Position = UDim2.fromOffset(8, 34)
    infoFrame.BackgroundColor3 = Color3.fromRGB(50, 30, 70)
    infoFrame.BackgroundTransparency = 0.2
    Instance.new("UICorner", infoFrame).CornerRadius = UDim.new(0, 8)
    
    local prefixLabel = Instance.new("TextLabel", infoFrame)
    prefixLabel.Size = UDim2.new(1, 0, 0.5, 0)
    prefixLabel.Position = UDim2.fromOffset(0, 3)
    prefixLabel.BackgroundTransparency = 1
    prefixLabel.Text = "Prefix: -"
    prefixLabel.TextColor3 = Color3.fromRGB(230, 220, 255)
    prefixLabel.Font = Enum.Font.GothamBold
    prefixLabel.TextSize = 12
    prefixLabel.TextXAlignment = Enum.TextXAlignment.Center
    
    local turnLabel = Instance.new("TextLabel", infoFrame)
    turnLabel.Size = UDim2.new(1, 0, 0.5, 0)
    turnLabel.Position = UDim2.fromOffset(0, 21)
    turnLabel.BackgroundTransparency = 1
    turnLabel.Text = "Giliran: ❌"
    turnLabel.TextColor3 = Color3.fromRGB(200, 180, 255)
    turnLabel.Font = Enum.Font.GothamBold
    turnLabel.TextSize = 11
    turnLabel.TextXAlignment = Enum.TextXAlignment.Center
    
    local wordListFrame = Instance.new("Frame", mainFrame)
    wordListFrame.Size = UDim2.new(1, -16, 1, -84)
    wordListFrame.Position = UDim2.fromOffset(8, 80)
    wordListFrame.BackgroundColor3 = Color3.fromRGB(25, 15, 35)
    wordListFrame.BackgroundTransparency = 0.1
    Instance.new("UICorner", wordListFrame).CornerRadius = UDim.new(0, 8)
    
    local scrollFrame = Instance.new("ScrollingFrame", wordListFrame)
    scrollFrame.Name = "WordList"
    scrollFrame.Size = UDim2.new(1, -12, 1, -12)
    scrollFrame.Position = UDim2.fromOffset(6, 6)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(180, 120, 255)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.BorderSizePixel = 0
    
    local listLayout = Instance.new("UIListLayout", scrollFrame)
    listLayout.Padding = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local answerWords = {}
    local lastPrefix = ""
    
    local function UpdateWordList()
        for _, child in pairs(scrollFrame:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then
                if child.Name ~= "Header" then child:Destroy() end
            end
        end
        
        if #answerWords == 0 then
            local emptyLabel = Instance.new("TextLabel", scrollFrame)
            emptyLabel.Size = UDim2.new(1, 0, 0, 40)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Text = "Tidak ada kata"
            emptyLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
            emptyLabel.Font = Enum.Font.Gotham
            emptyLabel.TextSize = 12
        else
            for index, word in ipairs(answerWords) do
                local wordButton = Instance.new("TextButton", scrollFrame)
                wordButton.Name = "WordBtn_" .. word
                wordButton.Size = UDim2.new(1, 0, 0, 34)
                wordButton.BackgroundColor3 = Color3.fromRGB(45, 28, 65)
                wordButton.BackgroundTransparency = 0.1
                wordButton.Text = ""
                wordButton.AutoButtonColor = false
                Instance.new("UICorner", wordButton).CornerRadius = UDim.new(0, 6)
                
                local wordLabel = Instance.new("TextLabel", wordButton)
                wordLabel.Size = UDim2.new(0, 140, 1, 0)
                wordLabel.Position = UDim2.fromOffset(8, 0)
                wordLabel.BackgroundTransparency = 1
                wordLabel.Text = string.upper(word)
                wordLabel.TextColor3 = Color3.fromRGB(230, 220, 255)
                wordLabel.Font = Enum.Font.GothamBold
                wordLabel.TextSize = 12
                wordLabel.TextXAlignment = Enum.TextXAlignment.Left
                
                local lengthFrame = Instance.new("Frame", wordButton)
                lengthFrame.Size = UDim2.fromOffset(50, 22)
                lengthFrame.Position = UDim2.new(1, -58, 0.5, -11)
                lengthFrame.BackgroundColor3 = Color3.fromRGB(100, 70, 180)
                lengthFrame.BackgroundTransparency = 0.15
                Instance.new("UICorner", lengthFrame).CornerRadius = UDim.new(0, 5)
                
                local lengthLabel = Instance.new("TextLabel", lengthFrame)
                lengthLabel.Size = UDim2.fromScale(1, 1)
                lengthLabel.BackgroundTransparency = 1
                lengthLabel.Text = "+" .. string.sub(word, #lastPrefix + 1)
                lengthLabel.TextColor3 = Color3.new(1, 1, 1)
                lengthLabel.Font = Enum.Font.GothamBold
                lengthLabel.TextSize = 10
                
                wordButton.MouseButton1Click:Connect(function()
                    if not IsInputActive() then
                        return
                    end
                    
                    if State.isSubmitting then return end
                    
                    SubmitWord(word, lastPrefix, "panel")
                    wordButton:Destroy()
                end)
            end
            task.wait()
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
        end
    end
    
    if AnswerPanelConnection then AnswerPanelConnection:Disconnect() end
    
    local wasTurnActive = false
    
    AnswerPanelConnection = RunService.Heartbeat:Connect(function()
        if not Config.SambungKata.ShowAnswerPanel or not AnswerPanel then return end
        
        local isTurnActive = IsInputActive()
        local currentPrefixValue = GetCurrentPrefix()
        
        prefixLabel.Text = "Prefix: " .. (currentPrefixValue ~= "" and string.upper(currentPrefixValue) or "-")
        turnLabel.Text = "Giliran: " .. (isTurnActive and "AKTIF" or "TIDAK")
        
        if isTurnActive then
            if not wasTurnActive or currentPrefixValue ~= lastPrefix then
                lastPrefix = currentPrefixValue
                answerWords = GetMatchingWords(lastPrefix)
                UpdateWordList()
                wasTurnActive = true
            end
        else
            if wasTurnActive then
                wasTurnActive = false
                answerWords = {}
                UpdateWordList()
            end
        end
    end)
end

local function DestroyAnswerPanel()
    if AnswerPanelConnection then AnswerPanelConnection:Disconnect(); AnswerPanelConnection = nil end
    if AnswerPanel then pcall(function() AnswerPanel:Destroy() end); AnswerPanel = nil end
    Config.SambungKata.ShowAnswerPanel = false
end

-- Event Listeners
local function SetupEventListeners()
    local lastMistakeCount = LocalPlayer:GetAttribute("Mistake") or 0
    
    LocalPlayer:GetAttributeChangedSignal("Mistake"):Connect(function()
        local newMistakeCount = LocalPlayer:GetAttribute("Mistake") or 0
        if newMistakeCount > lastMistakeCount then
            if State.turnStatus then
                local wrongWord = GetCurrentPrefix()
                if wrongWord and #wrongWord > 1 then
                    State.blacklistedWords[wrongWord] = true
                end
            end
        end
        lastMistakeCount = newMistakeCount
    end)
    
    LocalPlayer:GetAttributeChangedSignal("IsTurn"):Connect(function()
        State.turnStatus = LocalPlayer:GetAttribute("IsTurn") == true
        if not State.turnStatus then State.currentPrefix = "" end
    end)
    
    State.turnStatus = LocalPlayer:GetAttribute("IsTurn") == true
    
    task.spawn(function()
        local leaderstats = LocalPlayer:WaitForChild("leaderstats", 10)
        if not leaderstats then return end
        
        local wins = leaderstats:WaitForChild("Wins", 10)
        local losses = leaderstats:WaitForChild("Losses", 10)
        
        if not wins or not losses then return end
        
        wins.Changed:Connect(function()
            State.usedWords = {}
        end)
        
        losses.Changed:Connect(function()
            State.usedWords = {}
        end)
    end)
end

-- Teleport Functions
local function TeleportToTableWithPlayers()
    local tables = Workspace:FindFirstChild("Tables")
    if not tables then return end
    
    local availableTables = {}
    
    for _, tableModel in pairs(tables:GetChildren()) do
        if tableModel:IsA("Model") and string.find(tableModel.Name, "Table") then
            local seats = tableModel:FindFirstChild("Seats")
            if seats then
                local playerCount = 0
                for _, seat in pairs(seats:GetChildren()) do
                    if seat:IsA("Seat") and seat.Occupant then
                        playerCount = playerCount + 1
                    end
                end
                
                if playerCount > 0 then
                    local tablePart = tableModel:FindFirstChild("TablePart")
                    if tablePart then
                        table.insert(availableTables, {
                            model = tableModel,
                            part = tablePart,
                            position = tablePart.Position,
                            playerCount = playerCount,
                            name = tableModel.Name
                        })
                    end
                end
            end
        end
    end
    
    if #availableTables == 0 then return end
    
    table.sort(availableTables, function(a, b) return a.playerCount > b.playerCount end)
    
    local targetTable = availableTables[1]
    local character = LocalPlayer.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if humanoidRootPart then
        humanoidRootPart.CFrame = CFrame.new(targetTable.position + Vector3.new(0, 3, 0))
    end
end

local function TeleportToRewardParkour()
    local claimPart = Workspace:FindFirstChild("ClaimBambuPart")
    if not claimPart then return end
    
    local character = LocalPlayer.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if humanoidRootPart then
        humanoidRootPart.CFrame = CFrame.new(claimPart.Position + Vector3.new(0, 3, 0))
    end
end

-- UI
local function InitUI()
    local success, WindUI = pcall(function()
        return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end)
    if not success then return end

    local Window = WindUI:CreateWindow({
        Title = "MIZUKAGE OFFICIAL",
        Icon = "skull",
        Author = "Sambung Kata",
        Folder = "MizukageSambungKata",
        Size = UDim2.fromOffset(700, 550),
        Theme = "Dark",
        Accent = Color3.fromRGB(255, 215, 0),
        SideBarWidth = 220,
        HasOutline = true,
    })

    local MainPage = Window:Tab({ Title = "Main", Icon = "rocket" })
    local StatsPage = Window:Tab({ Title = "Stats", Icon = "analytics" })
    local DatabasePage = Window:Tab({ Title = "Database", Icon = "database" })

    -- Main Page
    MainPage:Section({ Title = "🔍 Filter Kata" })
    local filterModes = { "RANDOM", "PRIORITY", "IF", "NG", "NYA", "XQ", "UM", "EA", "SM", "KL", "JM", "GC", "GY", "CY", "LS", "KS", "MS", "SHORTEST", "LONGEST" }
    MainPage:Dropdown({ Title = "Mode Filter", Values = filterModes, Value = Config.SambungKata.FilterMode, Callback = function(v) Config.SambungKata.FilterMode = v[1] end })

    MainPage:Section({ Title = "⚙️ Pengaturan Utama" })
    MainPage:Toggle({ Title = "Auto Jawab", Default = Config.SambungKata.AutoAnswer, Callback = function(s) Config.SambungKata.AutoAnswer = s; if s then StartAutoAnswer() else StopAutoAnswer() end end })
    MainPage:Toggle({ Title = "Pilih Jawaban", Default = Config.SambungKata.ShowAnswerPanel, Callback = function(s) Config.SambungKata.ShowAnswerPanel = s; if s then CreateAnswerPanel() else DestroyAnswerPanel() end end })
    MainPage:Toggle({ Title = "Anti AFK", Default = Config.SambungKata.AntiAFK, Callback = function(s) Config.SambungKata.AntiAFK = s; if s then StartAntiAFK() else StopAntiAFK() end end })
    MainPage:Toggle({ Title = "Like Human Typing", Default = Config.SambungKata.HumanTyping, Callback = function(s) Config.SambungKata.HumanTyping = s end })

    MainPage:Section({ Title = "⏱️ Pengaturan Delay" })
    MainPage:Slider({ Title = "Delay Antar Huruf", Min = 0.02, Max = 0.3, Step = 0.01, Default = Config.SambungKata.KeyDelay, Callback = function(v) Config.SambungKata.KeyDelay = v end })
    MainPage:Slider({ Title = "Delay Submit", Min = 0.05, Max = 0.5, Step = 0.01, Default = Config.SambungKata.SubmitDelay, Callback = function(v) Config.SambungKata.SubmitDelay = v end })
    MainPage:Slider({ Title = "Delay Auto Jawab", Min = 0.1, Max = 3, Step = 0.1, Default = Config.SambungKata.AutoAnswerDelay, Callback = function(v) Config.SambungKata.AutoAnswerDelay = v; if Config.SambungKata.AutoAnswer then StartAutoAnswer() end end })

    MainPage:Section({ Title = "📡 Teleport" })
    MainPage:Button({ Title = "Cari Meja dengan Pemain", Variant = "Secondary", Callback = TeleportToTableWithPlayers })
    MainPage:Button({ Title = "TP ke Reward Parkour", Variant = "Secondary", Callback = TeleportToRewardParkour })

    -- Stats Page
    StatsPage:Section({ Title = "📊 Player Stats" })
    StatsPage:Paragraph({ Title = "Nama", Desc = "Nama: " .. LocalPlayer.Name })
    StatsPage:Paragraph({ Title = "Display", Desc = "Display: " .. LocalPlayer.DisplayName })
    StatsPage:Paragraph({ Title = "User ID", Desc = "User ID: " .. LocalPlayer.UserId })

    StatsPage:Section({ Title = "💰 Keuangan" })
    local moneyLabel = StatsPage:Paragraph({ Title = "Money", Desc = "Money: Loading..." })
    local winsLabel = StatsPage:Paragraph({ Title = "Wins", Desc = "Wins: Loading..." })
    local lossesLabel = StatsPage:Paragraph({ Title = "Losses", Desc = "Losses: Loading..." })
    local winRateLabel = StatsPage:Paragraph({ Title = "Win Rate", Desc = "Win Rate: Loading..." })

    StatsPage:Button({ Title = "Refresh Stats", Variant = "Secondary", Callback = function()
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats then
            local money = leaderstats:FindFirstChild("Money")
            local wins = leaderstats:FindFirstChild("Wins")
            local losses = leaderstats:FindFirstChild("Losses")
            if money then moneyLabel:Set("Money: Rp" .. money.Value) end
            if wins then winsLabel:Set("Wins: " .. wins.Value) end
            if losses then lossesLabel:Set("Losses: " .. losses.Value) end
            if wins and losses then
                local total = wins.Value + losses.Value
                local winRate = total > 0 and math.floor(wins.Value / total * 100) or 0
                winRateLabel:Set("Win Rate: " .. winRate .. "%")
            end
        end
    end })

    StatsPage:Section({ Title = "📈 Performance" })
    local usedWordsLabel = StatsPage:Paragraph({ Title = "Kata Terpakai", Desc = "Kata Terpakai: 0" })
    local blacklistLabel = StatsPage:Paragraph({ Title = "Kata Diblacklist", Desc = "Kata Diblacklist: 0" })
    local totalWordsLabel = StatsPage:Paragraph({ Title = "Total Kamus", Desc = "Total Kamus: 0" })

    StatsPage:Button({ Title = "Reset Kata Terpakai", Variant = "Secondary", Callback = function() State.usedWords = {} end })

    task.spawn(function()
        while Config.IsRunning do
            pcall(function()
                usedWordsLabel:Set("Kata Terpakai: " .. TableLength(State.usedWords))
                blacklistLabel:Set("Kata Diblacklist: " .. TableLength(State.blacklistedWords))
                totalWordsLabel:Set("Total Kamus: " .. #State.allWords)
            end)
            task.wait(5)
        end
    end)

    -- Database Page
    DatabasePage:Section({ Title = "📚 Load Kamus" })
    local dbStatusLabel = DatabasePage:Paragraph({ Title = "Status", Desc = "Status: Belum dimuat" })
    
    DatabasePage:Button({ Title = "Load Kamus", Variant = "Secondary", Callback = function()
        dbStatusLabel:Set("Status: Loading...")
        task.spawn(function()
            local success = LoadWordDatabase({ "https://raw.githubusercontent.com/wasovfree/Wafree/refs/heads/main/list.txt" })
            if success then
                dbStatusLabel:Set("Status: " .. #State.allWords .. " kata")
                totalWordsLabel:Set("Total Kamus: " .. #State.allWords)
            else
                dbStatusLabel:Set("Status: Gagal load")
            end
        end)
    end })

    WindUI:Notify({ Title = "Mizukage System", Content = "Sambung Kata loaded!", Duration = 3 })
end

SetupEventListeners()
task.spawn(function()
    LoadWordDatabase({ "https://raw.githubusercontent.com/wasovfree/Wafree/refs/heads/main/list.txt" })
end)
task.spawn(InitUI)
