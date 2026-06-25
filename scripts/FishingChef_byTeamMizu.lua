--[[ ═══════════════════════════════════════
     TeamMizu影 — Deobfuscated
     By Mizukage Official
     https://discord.gg/Mizukage-Official
═══════════════════════════════════════ ]]--

local Env = getfenv();
local P = {};
local v1 = {...};
local r1 = true;
local r2 = string.gmatch;
local function r3(...)
    error("Tamper Detected!");
    return; 
end;
local r4 = false;
local v2 = pcall(function(...)
    r4 = true;
    return; 
end) and r4;
local r5 = math.random;
local v3 = table.concat;
local function v4(...)
    while true do
        l1 = l2;
        l2 = l1;
        r3(); 
    end;
    return; 
end;
local r6 = table and table.unpack or unpack;
local r7 = r5(3, 65);
local v5 = {
    pcall(function(...)
        return "Ve" / (13154569 - "y7" ^ 11464471); 
    end)
};
local v6 = v5[2];
local r8 = tonumber(r2(tostring(v6), ":(%d*):")());
for b = 1, r7 do
    r9 = b;
    r10 = math.random(1, 100);
    r11 = r5(0, 255);
    r12 = r5(1, r10);
    r13 = r5(1, 2) == 1;
    r14 = v6.gsub(v6, ":(%d*):", ":" .. tostring(r5(0, 10000)) .. ":");
    X = {
        pcall(function(...)
            if r5(1, 2) == 1 or r9 == r7 then
                r1 = r1 and r8 == tonumber(r2(tostring(({
                    pcall(function(...)
                        return "fZB3HLhu3vlRocP" / (2420002 - "u8CiWq1" ^ 15575860); 
                    end)
                })[2]), ":(%d*):")());
            end;
            if r13 then
                error(r14, 0);
            end;
            v1 = {};
            for d = 1, r10 do
                v1[d] = r5(0, 255); 
            end;
            v1[r12] = r11;
            return r6(v1); 
        end)
    };
    if r13 then
        r1 = r1 and (pcall(function(...)
            if r5(1, 2) == 1 or r9 == r7 then
                r1 = r1 and r8 == tonumber(r2(tostring(({
                    pcall(function(...)
                        return "fZB3HLhu3vlRocP" / (2420002 - "u8CiWq1" ^ 15575860); 
                    end)
                })[2]), ":(%d*):")());
            end;
            if r13 then
                error(r14, 0);
            end;
            v1 = {};
            for d = 1, r10 do
                v1[d] = r5(0, 255); 
            end;
            v1[r12] = r11;
            return r6(v1); 
        end) == false and X[2] == r14);
    end; 
end;
r1 = r1 and 0 == 0;
if r1 then
    r17 = math.floor;
    v5 = {};
    r18 = 0;
    r19 = 2;
    r20 = {};
    Q = 0;
    for f = 1, 256 do
        v5[f] = f; 
    end;
    v6 = #v5 == 0;
    f = table.remove(v5, math.random(1, #v5));
    r20[f] = string.char(f - 1);
    if #v5 == 0 then
        r21 = {};
        r23 = {};
        r16 = setmetatable({}, {
            ["__index"] = r23,
            ["__metatable"] = nil
        });
        d = game;
        r24 = d.GetService(d, "Players");
        m = game;
        r25 = m.GetService(m, "RunService");
        v2 = game;
        r26 = v2.GetService(v2, "UserInputService");
        s = game;
        r27 = s.GetService(s, "TweenService");
        r28 = r24.LocalPlayer;
        v6 = false;
        r33 = 5;
        local function r34(arg1_2, ...)
            v1 = arg1_2;
            if not v1.IsA(v1, "Model") then
                return false;
            end;
            if v1 == r28.Character then
                return false;
            end;
            K = v1.FindFirstChildOfClass(v1, "Humanoid");
            if K then
                if K then
                    return true;
                end;
                return false;
            else
                k = v3;
            end; 
        end;
        local function r35(...)
            v1 = r28.Character;
            if not v1 then
                return false;
            end;
            if not v1.FindFirstChild(v1, "HumanoidRootPart") then
                return false;
            end;
            m = workspace;
            d = m[2];
            m = m[1];
            for a, s in pairs(m.GetDescendants(m)) do
                v2 = a;
                v4 = r34(s);
                if v4 then
                    v4 = s.FindFirstChildWhichIsA(s, "BasePart");
                    if v4 then
                        if (v1.FindFirstChild(v1, "HumanoidRootPart").Position - v4.Position).Magnitude <= r33 then
                            return true;
                        end;
                    end;
                end; 
            end;
            return false; 
        end;
        local function r36(arg1_3, ...)
            if r32 then
                v3 = r32;
                v3.Disconnect(v3);
            end;
            if not arg1_3 then
                K = r28.Character;
                if K then
                    s = K.GetDescendants;
                    d = s[1];
                    a = s[2];
                    for m, s in pairs(s(K)) do
                        v2 = m;
                        if s.IsA(s, "BasePart") then
                            s.CanTouch = true;
                        end; 
                    end;
                end;
                return;
            end;
            k = r25.Heartbeat;
            r32 = k.Connect(k, function(...)
                v1 = r28.Character;
                if not v1 then
                    return;
                end;
                r35();
                v2 = v1.GetDescendants;
                m = {
                    v2(v1)
                };
                a = v2[3];
                d = v2[2];
                for a, s in pairs(G("pairs")) do
                    v2 = a;
                    if s.IsA(s, "BasePart") then
                        s.CanTouch = not r35();
                    end; 
                end;
                return; 
            end);
            return; 
        end;
        r38 = {};
        local function r39(arg1_4, ...)
            a = r38;
            K = 45[2];
            a = 45[1];
            for d, v2 in pairs(a) do
                if v2 then
                    v2.Destroy(v2);
                end; 
            end;
            r38 = {};
            if r37 then
                K = r37;
                K.Disconnect(K);
            end;
            if not arg1_4 then
                return;
            end;
            local function r40(arg1_5, ...)
                v1 = arg1_5;
                K = string.lower(v1.Name);
                if string.find(K, "soul") or string.find(K, "orb") then
                    d = Instance.new("Highlight");
                    d.FillColor = Color3.fromRGB(255, 255, 0);
                    d.FillTransparency = .3;
                    k = arg1_5;
                    d.Parent = k;
                    table.insert(r38, d);
                end;
                return; 
            end;
            v4 = workspace;
            v2 = v4[2];
            m = v4[1];
            for s, v4 in ipairs(v4.GetDescendants(v4)) do
                r40(v4);
                a = s; 
            end;
            a = workspace.DescendantAdded;
            r37 = a.Connect(a, function(arg1_6, ...)
                r40(arg1_6);
                return; 
            end);
            return; 
        end;
        r41 = {};
        r43 = 83;
        local function r44(arg1_7, ...)
            a = r24;
            K = a[2];
            d = a[3];
            a = "pairs";
            for d, v2 in pairs(a.GetPlayers(a)) do
                m = d;
                if v2.Character == arg1_7 then
                    return true;
                else
                    
                end; 
            end;
            return false; 
        end;
        local function r45(arg1_8, ...)
            v1 = arg1_8;
            K = r28.Character;
            if not K then
                return false;
            end;
            d = K.FindFirstChild(K, "HumanoidRootPart");
            a = v1.FindFirstChildWhichIsA(v1, "BasePart");
            if d then
                k = v3;
            end;
            if d then
                return (d.Position - a.Position).Magnitude < r43;
            end;
            return false; 
        end;
        local function r46(arg1_9, ...)
            v1 = arg1_9;
            if not v1.IsA(v1, "Model") then
                return;
            end;
            if r41[v1] then
                return;
            end;
            if r44(v1) then
                return;
            end;
            K = v1.FindFirstChildOfClass(v1, "Humanoid");
            v3 = v1.FindFirstChildWhichIsA(v1, "BasePart");
            a = v3;
            if K then
                v3 = v3;
                if K and v3 then
                    m = Instance.new("Highlight");
                    m.FillColor = Color3.fromRGB(255, 0, 0);
                    m.OutlineColor = Color3.fromRGB(255, 255, 255);
                    m.FillTransparency = 0.25;
                    k = arg1_9;
                    m.Parent = k;
                    r41[v1] = m;
                end;
                return;
            else
                m = v1.FindFirstChildOfClass(v1, "AnimationController");
            end; 
        end;
        local function r47(arg1_10, ...)
            a = r41;
            d = 45[3];
            a = 45[1];
            for d, v2 in a, pairs(a) do
                if v2 then
                    v2.Destroy(v2);
                end; 
            end;
            r41 = {};
            if r42 then
                K = r42;
                K.Disconnect(K);
            end;
            if not arg1_10 then
                return;
            end;
            s = workspace;
            m = s[2];
            a = s[1];
            for v2, s in ipairs(s.GetDescendants(s)) do
                d = v2;
                r46(s); 
            end;
            d = workspace.DescendantAdded;
            r42 = d.Connect(d, function(arg1_11, ...)
                v1 = arg1_11;
                v3 = task.wait;
                v3(.2);
                a = v1.IsA(v1, "Model");
                if a then
                    K = arg1_11;
                end;
                v3 = v3;
                K = a or v1.FindFirstAncestorOfClass(v1, "Model");
                if K then
                    r46(K);
                end;
                return; 
            end);
            return; 
        end;
        r48 = {};
        setESPPlayer = function(arg1_12, ...)
            a = r48;
            K = 45[2];
            a = 45[1];
            for d, v2 in pairs(a) do
                v3 = v2.highlight;
                if v3 then
                    v3 = v2.highlight;
                    v3.Destroy(v3);
                end;
                v3 = v2.gui;
                if v3 then
                    v3 = v2.gui;
                    v3.Destroy(v3);
                end; 
            end;
            r48 = {};
            if r49 then
                K = r49;
                K.Disconnect(K);
            end;
            if not arg1_12 then
                return;
            end;
            local function r50(arg1_13, ...)
                v1 = arg1_13;
                if v1 == r28 then
                    return;
                end;
                if not v1.Character then
                    return;
                end;
                K = v1.Character;
                d = K.FindFirstChild(K, "Head");
                a = K.FindFirstChild(K, "HumanoidRootPart");
                if not d or not a then
                    return;
                end;
                m = Instance.new("Highlight");
                m.FillColor = Color3.fromRGB(0, 255, 255);
                m.OutlineColor = Color3.fromRGB(255, 255, 255);
                m.FillTransparency = .35;
                m.Parent = K;
                v2 = Instance.new("BillboardGui");
                v2.Size = UDim2.new(0, 200, 0, 40);
                v2.StudsOffset = Vector3.new(0, 2.5, 0);
                v2.AlwaysOnTop = true;
                v2.Parent = d;
                s = Instance.new("TextLabel");
                s.Size = UDim2.new(1, 0, 1, 0);
                s.BackgroundTransparency = 1;
                s.TextColor3 = Color3.fromRGB(0, 255, 255);
                s.TextStrokeTransparency = 0;
                s.Font = Enum.Font.GothamBold;
                s.TextSize = 14;
                s.Text = v1.Name;
                s.Parent = v2;
                r48[v1] = {
                    ["highlight"] = m,
                    ["gui"] = v2,
                    ["label"] = s,
                    ["root"] = a
                };
                return; 
            end;
            v4 = P[d];
            v2 = v4[2];
            s = v4[3];
            for s, v4 in pairs(v4.GetPlayers(v4)) do
                r50(v4);
                a = s; 
            end;
            a = P[d].PlayerAdded;
            a.Connect(a, function(arg1_14, ...)
                r51 = arg1_14;
                v3 = r51.CharacterAdded;
                v3.Connect(v3, function(...)
                    task.wait(1);
                    r50(r51);
                    return; 
                end);
                return; 
            end);
            a = r25.RenderStepped;
            r49 = a.Connect(a, function(...)
                v1 = r28.Character;
                if not v1 then
                    return;
                end;
                if not v1.FindFirstChild(v1, "HumanoidRootPart") then
                    return;
                end;
                m = r48;
                a = 21367823001310[3];
                m = 21367823001310[1];
                for a, s in m, pairs(m) do
                    if a.Character and (s.root and s.label) then
                        v4 = math.floor((v1.FindFirstChild(v1, r16[d("H_l!\xa7\xa8\x12OW\xa5:\xf1aR\xfd\xca", v2)]).Position - s.root.Position).Magnitude);
                        s.label.Text = a.Name .. " [" .. v4 .. "m]";
                    end; 
                end;
                return; 
            end);
            return; 
        end;
        r52 = false;
        r53 = {};
        local function r54(arg1_15, ...)
            r55 = arg1_15;
            if not r52 then
                return;
            end;
            d = r55;
            if not d or not d.IsA(d, "ProximityPrompt") then
                return;
            end;
            task.spawn(function(...)
                v1 = r52;
                k = r55.Parent;
                while not v1 do
                    if k then
                        pcall(function(...)
                            r55.Enabled = true;
                            r55.RequiresLineOfSight = false;
                            r55.MaxActivationDistance = math.huge;
                            r55.HoldDuration = 0;
                            fireproximityprompt(r55);
                            return; 
                        end);
                        task.wait(.1);
                    end;
                    return; 
                end;
                k = r55.Parent; 
            end);
            return; 
        end;
        local function r56(arg1_16, ...)
            v1 = arg1_16;
            if r53[v1] then
                return;
            end;
            r53[v1] = true;
            r54(v1);
            return; 
        end;
        local function r57(arg1_17, ...)
            m = " tyL\x8b\x0f\xa9\xb6\xe3V_\xb3\xba\xe4p";
            v1 = arg1_17;
            if v1.IsA(v1, r16[r15(m, 16897111301820)]) then
                v3 = string.lower;
                m = v1.Parent;
                if m then
                    d = string.lower(arg1_17.Parent.Name);
                end;
                v3 = v3;
                d = m or "";
                m = string.find(v3(v1.Name), "soul");
                if m then
                    if m then
                        r56(arg1_17);
                    end;
                    return;
                end;
            end; 
        end;
        setAutoSoul = function(arg1_18, ...)
            v1 = arg1_18;
            r52 = v1;
            if not v1 then
                r53 = {};
                return;
            end;
            v2 = workspace;
            d = v2[1];
            a = v2[2];
            for m, v2 in ipairs(v2.GetDescendants(v2)) do
                K = m;
                r57(v2); 
            end;
            K = workspace.DescendantAdded;
            K.Connect(K, function(arg1_19, ...)
                v1 = arg1_19;
                if v1.IsA(v1, "ProximityPrompt") then
                    r57(v1);
                end;
                return; 
            end);
            return; 
        end;
        v3 = P[K];
        r58 = r26.TouchEnabled and not r26.KeyboardEnabled;
        r59 = "QuickInteract_v2_Config.json";
        local function r60(arg1_20, ...)
            a = 46[2];
            m = 46[3];
            v2 = "pairs";
            for m, v4 in pairs(arg1_20) do
                if not true then
                    K = "{" .. ",";
                end;
                K = "{" .. "\"" .. m .. "\":";
                if type(v4) == "boolean" then
                    if v4 then
                        v5 = "true";
                    end;
                    v3 = v3;
                    v3 = v3;
                    K = g .. (v4 or "false");
                else
                    if type(v4) == "number" then
                        K = g .. tostring(v4);
                    else
                        K = g .. "\"" .. tostring(v4) .. "\"";
                    end;
                    d = false;
                end; 
            end;
            return "{" .. "}"; 
        end;
        local function r61(arg1_21, ...)
            v1 = arg1_21;
            if not v1 or v1 == "" then
                return nil;
            end;
            k = string;
            K = {};
            v3 = k.gmatch;
            v2 = r16;
            m = "\"([^\"]+)\":([^,}]+)";
            a = v2[3];
            d = v2[2];
            for a, s in v3(v1, k) do
                if s == "true" then
                    ({})[a] = true;
                else
                    if s == "false" then
                        ({})[a] = false;
                    else
                        if tonumber(s) then
                            ({})[a] = tonumber(s);
                        else
                            ({})[a] = s.match(s, "\"?([^\"]*)\"?");
                        end;
                    end;
                end; 
            end;
            v2 = next(K) ~= nil;
            if v2 then
                a = {};
            end;
            v3 = v3;
            return v2 or nil; 
        end;
        local function r62(arg1_22, ...)
            r63 = arg1_22;
            pcall(function(...)
                if writefile then
                    writefile(P[17], P[C[1]](r63));
                end;
                return; 
            end);
            return; 
        end;
        local function r64(...)
            r65 = {
                ["NoDelay"] = false,
                ["SpeedHack"] = false,
                ["Noclip"] = false,
                ["WalkSpeed"] = 16
            };
            pcall(function(...)
                if readfile then
                    a = {
                        pcall(readfile, r59)
                    };
                    v1 = a[2];
                    K = pcall(readfile, r59);
                    if K then
                        k = a[2];
                    end;
                    if K then
                        d = r61(v1);
                        if d then
                            m = v2[3];
                            v2 = v2[1];
                            for m, v4 in v2, pairs(d) do
                                P[v1][m] = v4; 
                            end;
                        end;
                    end;
                end;
                return; 
            end);
            return r65; 
        end;
        r66 = r64();
        local function r67(arg1_23, arg2_23, ...)
            d = Instance.new("UICorner");
            d.CornerRadius = UDim.new(0, arg1_23);
            d.Parent = arg2_23;
            return; 
        end;
        local function r68(arg1_24, arg2_24, arg3_24, ...)
            a = Instance.new("UIStroke");
            k = arg1_24;
            a.Thickness = k;
            k = arg2_24;
            a.Color = k;
            a.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
            a.Parent = arg3_24;
            return; 
        end;
        local function r69(arg1_25, arg2_25, arg3_25, arg4_25, arg5_25, arg6_25, ...)
            a = arg4_25;
            m = arg5_25;
            v2 = arg6_25;
            s = Instance.new("TextLabel");
            k = arg1_25;
            s.Parent = k;
            s.BackgroundTransparency = 1;
            k = arg2_25;
            s.Text = k;
            k = arg3_25;
            s.TextSize = k;
            v4 = "TextColor3";
            k = a;
            if a then
                v3 = r15;
                s[v3] = a;
                k = m;
                v4 = "Font";
                if m then
                    v3 = r15;
                    s[v3] = m;
                    v4 = "TextXAlignment";
                    k = v2;
                    if v2 then
                        v3 = r15;
                        s[v3] = v2;
                        s.TextWrapped = true;
                        return s;
                    else
                        k = Enum.TextXAlignment.Left;
                    end;
                else
                    k = Enum.Font.GothamBold;
                end;
            else
                k = Color3.fromRGB(228, 224, 245);
            end; 
        end;
        local function r70(arg1_26, arg2_26, arg3_26, arg4_26, arg5_26, arg6_26, arg7_26, ...)
            a = arg4_26;
            g = P[K];
            r71 = arg6_26;
            r72 = arg7_26;
            v4 = r58 and 64 or 56;
            r73 = Instance.new("Frame", arg1_26);
            r73.Size = UDim2.new(1, 0, 0, v4);
            r73.BackgroundColor3 = Color3.fromRGB(20, 20, 32);
            r73.BorderSizePixel = 0;
            Q = arg5_26;
            r73.LayoutOrder = Q;
            r67(11, r73);
            r68(1, Color3.fromRGB(50, 50, 82), r73);
            r74 = Instance.new("Frame", r73);
            r74.Size = UDim2.new(0, 3, 0, v4 - 20);
            r74.Position = UDim2.new(0, 0, 0.5, -(v4 - 20) / 2);
            r74.BackgroundColor3 = Color3.fromRGB(138, 134, 172);
            r74.BorderSizePixel = 0;
            r68(1, Color3.fromRGB(50, 50, 82), r74);
            g = Instance.new("Frame", r73);
            g.Size = UDim2.new(0, 34, 0, 34);
            g.Position = UDim2.new(0, 10, 0.5, -17);
            g.BackgroundColor3 = Color3.fromRGB(30, 30, 48);
            g.BorderSizePixel = 0;
            r67(9, g);
            w = r69(g, arg2_26, 17, r71, Enum.Font.GothamBold, Enum.TextXAlignment.Center);
            w.Size = UDim2.new(1, 0, 1, 0);
            w.ZIndex = 3;
            v5 = r69(r73, arg3_26, 13, Color3.fromRGB(228, 224, 245));
            v5.Size = UDim2.new(1, -112, 0, 20);
            v5.Position = UDim2.new(0, 52, 0, 8);
            if a then
                v6 = r69(r73, a, 10, Color3.fromRGB(138, 134, 172), Enum.Font.Gotham);
                v6.Size = UDim2.new(1, -112, 0, 14);
                v6.Position = UDim2.new(0, 52, 0, 30);
            end;
            r75 = Instance.new("Frame", r73);
            r75.Size = UDim2.new(0, 50, 0, 28);
            r75.Position = UDim2.new(1, -60, 0.5, -14);
            r75.BackgroundColor3 = Color3.fromRGB(30, 30, 48);
            r75.BorderSizePixel = 0;
            r67(14, r75);
            r76 = Instance.new("Frame", r75);
            r76.Size = UDim2.new(0, 22, 0, 22);
            r76.Position = UDim2.new(0, 3, 0.5, -11);
            r76.BackgroundColor3 = Color3.fromRGB(138, 134, 172);
            r76.BorderSizePixel = 0;
            r67(11, r76);
            r77 = false;
            local function r78(arg1_27, ...)
                v1 = arg1_27;
                r77 = v1;
                K = TweenInfo.new(.2, Enum.EasingStyle.Quart);
                if v1 then
                    k = r27;
                    d = k.Create(k, r75, K, {
                        ["BackgroundColor3"] = r71
                    });
                    d.Play(d);
                    k = r27;
                    d = k.Create(k, r76, K, {
                        ["Position"] = UDim2.new(0, 25, 0.5, -11),
                        ["BackgroundColor3"] = Color3.fromRGB(12, 12, 20)
                    });
                    d.Play(d);
                    r74.BackgroundColor3 = r71;
                    r73.BackgroundColor3 = Color3.new(r71.R * .08, r71.G * .08, r71.B * .14);
                else
                    k = r27;
                    d = k.Create(k, r75, K, {
                        ["BackgroundColor3"] = Color3.fromRGB(30, 30, 48)
                    });
                    d.Play(d);
                    k = r27;
                    d = k.Create(k, r76, K, {
                        ["Position"] = UDim2.new(0, 3, 0.5, -11),
                        ["BackgroundColor3"] = Color3.fromRGB(138, 134, 172)
                    });
                    d.Play(d);
                    r74.BackgroundColor3 = Color3.fromRGB(138, 134, 172);
                    r73.BackgroundColor3 = Color3.fromRGB(20, 20, 32);
                end;
                if r72 then
                    r72(v1);
                end;
                return; 
            end;
            v = Instance.new("TextButton", r73);
            v.Size = UDim2.new(1, 0, 1, 0);
            v.BackgroundTransparency = 1;
            v.Text = "";
            k = v.MouseButton1Click;
            k.Connect(k, function(...)
                r78(not r77);
                return; 
            end);
            return r73, function(...)
                return r77; 
            end, r78; 
        end;
        local function r79(arg1_28, arg2_28, arg3_28, arg4_28, arg5_28, arg6_28, arg7_28, arg8_28, arg9_28, ...)
            s = arg7_28;
            r80 = arg5_28;
            v4 = arg8_28;
            Q = P[K];
            r81 = arg6_28;
            r82 = arg9_28;
            Q = Instance.new("Frame", arg1_28);
            Q.Size = UDim2.new(1, 0, 0, r58 and 84 or 76);
            Q.BackgroundColor3 = Color3.fromRGB(20, 20, 32);
            Q.BorderSizePixel = 0;
            w = arg4_28;
            Q.LayoutOrder = w;
            r67(11, Q);
            r68(1, Color3.fromRGB(50, 50, 82), Q);
            w = r69(Q, arg2_28, 11, Color3.fromRGB(228, 224, 245));
            w.Size = UDim2.new(1, -100, 0, 18);
            w.Position = UDim2.new(0, 14, 0, 8);
            r83 = r69(Q, tostring(s), 20, v4, Enum.Font.GothamBold, Enum.TextXAlignment.Right);
            r83.Size = UDim2.new(0, 72, 0, 24);
            r83.Position = UDim2.new(1, -84, 0, 4);
            r69(Q, arg3_28, 9, Color3.fromRGB(138, 134, 172), Enum.Font.Gotham, Enum.TextXAlignment.Right);
            f = v3;
            r84 = Instance.new("Frame", Q);
            r84.Size = UDim2.new(1, -28, 0, r58 and 8 or 6);
            r84.Position = UDim2.new(0, 14, 0, r58 and 56 or 50);
            r84.BackgroundColor3 = Color3.fromRGB(30, 30, 48);
            r84.BorderSizePixel = 0;
            r67(4, r84);
            r85 = Instance.new("Frame", r84);
            r85.Size = UDim2.new(0, 0, 1, 0);
            r85.BackgroundColor3 = v4;
            r85.BorderSizePixel = 0;
            r67(4, r85);
            y = v3;
            L = r58 and 20 or 16;
            r86 = Instance.new("Frame", r84);
            r86.Size = UDim2.new(0, L, 0, L);
            r86.AnchorPoint = Vector2.new(0.5, 0.5);
            r86.BackgroundColor3 = Color3.fromRGB(228, 224, 245);
            r86.BorderSizePixel = 0;
            r86.Position = UDim2.new(0, 0, 0.5, 0);
            r67(L / 2, r86);
            r68(2, v4, r86);
            X = v3;
            r87 = false;
            local function r88(arg1_29, ...)
                v1 = math.clamp(math.floor(arg1_29 + 0.5), r80, r81);
                K = (v1 - r80) / (r81 - r80);
                r85.Size = UDim2.new(K, 0, 1, 0);
                r86.Position = UDim2.new(K, 0, 0.5, 0);
                r83.Text = tostring(v1);
                if r82 then
                    r82(v1);
                end;
                return; 
            end;
            r88(s);
            p = v3;
            local function r89(arg1_30, ...)
                d = math.clamp((arg1_30 - r84.AbsolutePosition.X) / r84.AbsoluteSize.X, 0, 1);
                r88(r80 + (r81 - r80) * d);
                return; 
            end;
            p = r58 and 48 or 32;
            Z = Instance.new("TextButton", r84);
            Z.Size = UDim2.new(1, 16, 0, p);
            Z.Position = UDim2.new(0, -8, 0.5, -p / 2);
            Z.BackgroundTransparency = 1;
            Z.Text = "";
            Z.ZIndex = 5;
            k = Z.InputBegan;
            k.Connect(k, function(arg1_31, ...)
                v1 = arg1_31;
                if v1.UserInputType == Enum.UserInputType.MouseButton1 or v1.UserInputType == Enum.UserInputType.Touch then
                    r87 = true;
                    r89(v1.Position.X);
                end;
                return; 
            end);
            k = r26.InputChanged;
            k.Connect(k, function(arg1_32, ...)
                v1 = arg1_32;
                if not r87 then
                    return;
                end;
                if v1.UserInputType == Enum.UserInputType.MouseMovement or v1.UserInputType == Enum.UserInputType.Touch then
                    r89(v1.Position.X);
                end;
                return; 
            end);
            k = r26.InputEnded;
            k.Connect(k, function(arg1_33, ...)
                v1 = arg1_33;
                if v1.UserInputType == Enum.UserInputType.MouseButton1 or v1.UserInputType == Enum.UserInputType.Touch then
                    r87 = false;
                end;
                return; 
            end);
            return Q, r88; 
        end;
        local function r90(arg1_34, arg2_34, arg3_34, ...)
            a = Instance.new("Frame", arg1_34);
            a.Size = UDim2.new(1, 0, 0, 2);
            a.BackgroundTransparency = 1;
            k = arg3_34;
            a.LayoutOrder = k;
            m = Instance.new("Frame", a);
            m.Size = UDim2.new(1, 0, 0, 1);
            m.Position = UDim2.new(0, 0, 0.5, 0);
            m.BackgroundColor3 = Color3.fromRGB(50, 50, 82);
            m.BorderSizePixel = 0;
            v2 = Instance.new("Frame", a);
            v2.Size = UDim2.new(0, 0, 0, 20);
            v2.AutomaticSize = Enum.AutomaticSize.X;
            v2.Position = UDim2.new(0, 0, 0.5, -10);
            v2.BackgroundColor3 = Color3.fromRGB(12, 12, 20);
            r67(5, v2);
            r68(1, Color3.fromRGB(50, 50, 82), v2);
            s = r69(v2, arg2_34, 10, Color3.fromRGB(75, 205, 255), Enum.Font.GothamBold, Enum.TextXAlignment.Center);
            s.Size = UDim2.new(0, 0, 1, 0);
            s.AutomaticSize = Enum.AutomaticSize.X;
            return a; 
        end;
        local function r91(arg1_35, arg2_35, arg3_35, arg4_35, arg5_35, ...)
            a = arg4_35;
            m = arg5_35;
            if m then
                m = m;
                v2 = Instance.new("Frame", arg1_35);
                v3 = "Size";
                v2[v3] = UDim2.new(1, 0, 0, a or 38);
                v2.BackgroundColor3 = Color3.fromRGB(30, 30, 48);
                v2.BorderSizePixel = 0;
                v4 = arg3_35;
                v2.LayoutOrder = v4;
                r67(9, v2);
                r68(1, Color3.fromRGB(50, 50, 82), v2);
                v4 = Instance.new("Frame", v2);
                v4.Size = UDim2.new(0, 3, 0, (a or 38) - 14);
                v4.Position = UDim2.new(0, 0, 0.5, -((a or 38) - 14) / 2);
                g = m;
                v4.BackgroundColor3 = g;
                v4.BorderSizePixel = 0;
                r67(2, v4);
                g = r69(v2, arg2_35, 10, Color3.fromRGB(228, 224, 245), Enum.Font.Gotham);
                g.Size = UDim2.new(1, -18, 1, 0);
                g.Position = UDim2.new(0, 12, 0, 0);
                g.ZIndex = 2;
                return v2;
            else
                k = Color3.fromRGB(50, 50, 82);
            end; 
        end;
        local function r92(arg1_36, arg2_36, arg3_36, ...)
            r93 = arg3_36;
            a = Instance.new("Frame", arg1_36);
            v3 = "Size";
            x = v3;
            w = v3;
            a[v3] = UDim2.new(1, 0, 0, r58 and 50 or 44);
            a.BackgroundColor3 = Color3.fromRGB(20, 20, 32);
            a.BorderSizePixel = 0;
            m = arg2_36;
            a.LayoutOrder = m;
            r67(11, a);
            r68(1, Color3.fromRGB(50, 50, 82), a);
            m = r69(a, "Preset:", 10, Color3.fromRGB(228, 224, 245), Enum.Font.Gotham);
            m.Size = UDim2.new(0, 48, 0, 16);
            m.Position = UDim2.new(0, 10, 0.5, -8);
            v5 = "col";
            s = v3;
            g = v3;
            v4 = v3;
            s = r58 and 64 or 60;
            x = v3;
            v4 = r58 and 32 or 26;
            k = ipairs;
            x = v5[1];
            Q = v5[2];
            for w, v6 in k({
                {
                    ["name"] = "Normal",
                    ["val"] = 9,
                    ["col"] = Color3.fromRGB(55, 215, 118)
                },
                {
                    ["name"] = "Cepat",
                    ["val"] = 12,
                    ["col"] = Color3.fromRGB(75, 205, 255)
                },
                {
                    ["name"] = "Turbo",
                    ["val"] = 20,
                    [v5] = Color3.fromRGB(255, 188, 45)
                }
            }) do
                r94 = v6;
                r95 = Instance.new("TextButton", a);
                r95.Size = UDim2.new(0, s, 0, v4);
                r95.Position = UDim2.new(0, 62 + (w - 1) * (s + 4), 0.5, -v4 / 2);
                r95.BackgroundColor3 = Color3.fromRGB(30, 30, 48);
                r95.TextColor3 = r94.col;
                r95.Text = r94.name;
                r95.TextSize = 11;
                r95.Font = Enum.Font.GothamBold;
                r95.BorderSizePixel = 0;
                r95.AutoButtonColor = false;
                r67(7, r95);
                r68(1, r94.col, r95);
                k = r95.MouseButton1Click;
                k.Connect(k, function(...)
                    v3 = r27;
                    k = v3.Create(v3, r95, TweenInfo.new(.08), {
                        ["BackgroundColor3"] = r94.col
                    });
                    k.Play(k);
                    task.delay(.15, function(...)
                        v3 = r27;
                        k = v3.Create(v3, r95, TweenInfo.new(.2), {
                            ["BackgroundColor3"] = Color3.fromRGB(30, 30, 48)
                        });
                        k.Play(k);
                        return; 
                    end);
                    if r93 then
                        r93(r94.val);
                    end;
                    return; 
                end); 
            end;
            return a; 
        end;
        local function r96(arg1_37, arg2_37, ...)
            d = Instance.new("Frame", arg1_37);
            v3 = "Size";
            Q = "Size";
            g = v3;
            d[v3] = UDim2.new(1, 0, 0, r58 and 48 or 40);
            d.BackgroundColor3 = Color3.fromRGB(20, 20, 32);
            d.BorderSizePixel = 0;
            a = arg2_37;
            d.LayoutOrder = a;
            r67(11, d);
            r68(1, Color3.fromRGB(50, 50, 82), d);
            m = v3;
            s = v3;
            v4 = v3;
            m = r58 and 70 or 65;
            v2 = v3;
            v2 = r58 and 32 or 26;
            k = ipairs;
            g = 32[3];
            for g, Q in 32[1], k({
                {
                    ["text"] = "\xf0\x9f\x92\xbe Save",
                    ["col"] = Color3.fromRGB(75, 205, 118),
                    ["fn"] = function(...)
                        r62(r66);
                        return; 
                    end
                },
                {
                    ["text"] = "\xe2\x9a\x99 Load",
                    ["col"] = Color3.fromRGB(55, 215, 118),
                    ["fn"] = function(...)
                        r66 = r64();
                        setNoDelay(r66.NoDelay);
                        setSpeed(r66.SpeedHack);
                        setNoclip(r66.Noclip);
                        return; 
                    end
                },
                {
                    ["text"] = "\xf0\x9f\x94\x84 Reset",
                    ["col"] = Color3.fromRGB(240, 65, 80),
                    ["fn"] = function(...)
                        r66 = {
                            ["NoDelay"] = false,
                            ["SpeedHack"] = false,
                            ["Noclip"] = false,
                            ["WalkSpeed"] = 16
                        };
                        setNoDelay(false);
                        setSpeed(false);
                        setNoclip(false);
                        return; 
                    end
                }
            }) do
                r97 = Q;
                r98 = Instance.new("TextButton", d);
                r98.Size = UDim2.new(0, m, 0, v2);
                r98.Position = UDim2.new(0, 10 + (g - 1) * (m + 8), 0.5, -v2 / 2);
                r98.BackgroundColor3 = Color3.fromRGB(30, 30, 48);
                r98.TextColor3 = r97.col;
                r98.Text = r97.text;
                r98.TextSize = 11;
                r98.Font = Enum.Font.GothamBold;
                r98.BorderSizePixel = 0;
                r67(7, r98);
                r68(1, r97.col, r98);
                k = r98.MouseButton1Click;
                k.Connect(k, function(...)
                    v3 = r27;
                    k = v3.Create(v3, r98, TweenInfo.new(.08), {
                        ["BackgroundColor3"] = r97.col
                    });
                    k.Play(k);
                    task.delay(.1, function(...)
                        v3 = r27;
                        k = v3.Create(v3, r98, TweenInfo.new(.2), {
                            ["BackgroundColor3"] = Color3.fromRGB(30, 30, 48)
                        });
                        k.Play(k);
                        return; 
                    end);
                    r97.fn();
                    return; 
                end); 
            end;
            return d; 
        end;
        local function r99(arg1_38, arg2_38, arg3_38, arg4_38, ...)
            r100 = arg2_38;
            r101 = arg4_38;
            v2 = Instance.new("Frame", arg1_38);
            v2.Size = UDim2.new(1, 0, 0, 40);
            v2.BackgroundColor3 = Color3.fromRGB(30, 30, 48);
            v2.BorderSizePixel = 0;
            k = arg3_38;
            v2.LayoutOrder = k;
            r67(8, v2);
            s = r69(v2, r100.Name, 11, Color3.fromRGB(228, 224, 245));
            s.Size = UDim2.new(1, -50, 1, 0);
            s.Position = UDim2.new(0, 8, 0, 0);
            r102 = Instance.new("TextButton", v2);
            r102.Size = UDim2.new(0, 42, 0, 24);
            r102.Position = UDim2.new(1, -48, 0.5, -12);
            r102.BackgroundColor3 = Color3.fromRGB(55, 205, 118);
            r102.TextColor3 = Color3.fromRGB(20, 20, 20);
            r102.Text = "TP";
            r102.TextSize = 10;
            r102.Font = Enum.Font.GothamBold;
            r102.BorderSizePixel = 0;
            r67(6, r102);
            v3 = r102.MouseButton1Click;
            v3.Connect(v3, function(...)
                r101(r100);
                v3 = r27;
                k = v3.Create(v3, r102, TweenInfo.new(.08), {
                    ["BackgroundColor3"] = Color3.fromRGB(75, 205, 255)
                });
                k.Play(k);
                task.delay(.3, function(...)
                    v3 = r27;
                    k = v3.Create(v3, r102, TweenInfo.new(.15), {
                        ["BackgroundColor3"] = Color3.fromRGB(55, 205, 118)
                    });
                    k.Play(k);
                    return; 
                end);
                return; 
            end);
            return v2; 
        end;
        local function r103(arg1_39, ...)
            v1 = arg1_39;
            if not v1 or not v1.Character then
                return;
            end;
            K = v1.Character;
            d = K.FindFirstChild(K, "HumanoidRootPart");
            a = r28.Character;
            if not a or not d then
                return;
            end;
            m = a.FindFirstChild(a, "HumanoidRootPart");
            if m then
                m.CFrame = d.CFrame + Vector3.new(0, 3, 0);
            end;
            return; 
        end;
        local function r104(arg1_40, ...)
            v1 = arg1_40;
            k = "Noclip";
            r66[k] = v1;
            if r29 then
                v3 = r29;
                v3.Disconnect(v3);
            end;
            if v1 then
                k = r25.Stepped;
                r29 = k.Connect(k, function(...)
                    v1 = r28.Character;
                    if not v1 then
                        return;
                    end;
                    m = v1.GetDescendants;
                    a = {
                        m(v1)
                    };
                    a = m[1];
                    d = m[3];
                    for d, v2 in a, ipairs(G(a)) do
                        m = d;
                        if v2.IsA(v2, "BasePart") then
                            v2.CanCollide = false;
                        end; 
                    end;
                    return; 
                end);
            else
                d = r28.Character;
                if d then
                    a = d.FindFirstChild(d, "HumanoidRootPart");
                    if a then
                        a.CFrame = a.CFrame + Vector3.new(0, 2, 0);
                        task.wait(.1);
                        g = d.GetDescendants;
                        s = g[3];
                        for s, g in g[1], ipairs(g(d)) do
                            v4 = s;
                            if g.IsA(g, "BasePart") then
                                g.CanCollide = true;
                            end; 
                        end;
                        a.AssemblyLinearVelocity = Vector3.new(0, 0, 0);
                        a.AssemblyAngularVelocity = Vector3.new(0, 0, 0);
                    end;
                end;
                r62(r66);
                return;
            end; 
        end;
        local function r105(arg1_41, ...)
            K = r28.Character;
            if not K then
                return;
            end;
            k = "Humanoid";
            d = K.FindFirstChildOfClass(K, k);
            if d then
                k = arg1_41;
                d.WalkSpeed = k;
            end;
            return; 
        end;
        local function r106(arg1_42, ...)
            v1 = arg1_42;
            k = "SpeedHack";
            r66[k] = v1;
            if r30 then
                v3 = r30;
                v3.Disconnect(v3);
            end;
            if v1 then
                k = r25.Heartbeat;
                r30 = k.Connect(k, function(...)
                    r105(r66.WalkSpeed);
                    return; 
                end);
            else
                r105(16);
            end;
            r62(r66);
            return; 
        end;
        local function r107(arg1_43, ...)
            v2 = 4114101225339;
            v1 = arg1_43;
            k = r16[r15("]:\xcae\x1a\x80^", v2)];
            r66[k] = v1;
            if r31 then
                v3 = r31;
                v3.Disconnect(v3);
            end;
            if v1 then
                k = ipairs;
                m = workspace;
                v2 = {
                    m.GetDescendants(m)
                };
                d = m[2];
                K = m[1];
                for a, v2 in k(G(v2)) do
                    m = a;
                    r108 = v2;
                    k = r108;
                    if k.IsA(k, "ProximityPrompt") then
                        pcall(function(...)
                            r108.HoldDuration = 0;
                            return; 
                        end);
                    end; 
                end;
                k = workspace.DescendantAdded;
                r31 = k.Connect(k, function(arg1_44, ...)
                    r109 = arg1_44;
                    v3 = r109;
                    if v3.IsA(v3, "ProximityPrompt") then
                        pcall(function(...)
                            r109.HoldDuration = 0;
                            return; 
                        end);
                    end;
                    return; 
                end);
            else
                k = r31;
                if k then
                    k = P[z];
                    k.Disconnect(k);
                end;
                k = ipairs;
                v2 = workspace;
                s = {
                    v2.GetDescendants(v2)
                };
                a = v2[2];
                m = v2[3];
                for m, s in k(G(s)) do
                    v2 = m;
                    r110 = s;
                    k = r110;
                    if k.IsA(k, "ProximityPrompt") then
                        pcall(function(...)
                            r110.HoldDuration = 1;
                            return; 
                        end);
                    end; 
                end;
                r62(r66);
                return;
            end; 
        end;
        r111 = (function(...)
            v1 = gethui;
            K = Instance.new("ScreenGui");
            K.Name = "BubbleIconGui";
            K.ResetOnSpawn = false;
            k = v1() or v1.GetService(v1, "CoreGui");
            K.Parent = k;
            r112 = Instance.new("Frame", K);
            r112.Size = UDim2.new(0, 60, 0, 60);
            r112.Position = UDim2.new(0, 20, 0, 20);
            r112.BackgroundColor3 = Color3.fromRGB(55, 205, 255);
            r112.BorderSizePixel = 0;
            r112.ZIndex = 1000;
            r67(60 / 2, r112);
            r68(2, Color3.fromRGB(255, 255, 255), r112);
            m = r69(r112, "\xf0\x9f\xa4\x96", 28, Color3.fromRGB(20, 20, 20), Enum.Font.GothamBold, Enum.TextXAlignment.Center);
            m.Size = UDim2.new(1, 0, 1, 0);
            m.ZIndex = 1001;
            r113 = false;
            r116 = false;
            v3 = r112.InputBegan;
            v3.Connect(v3, function(arg1_45, ...)
                v1 = arg1_45;
                if v1.UserInputType == Enum.UserInputType.MouseButton1 or v1.UserInputType == Enum.UserInputType.Touch then
                    r116 = false;
                    r113 = true;
                    r114 = v1.Position;
                    r115 = r112.Position;
                end;
                return; 
            end);
            v3 = r112.InputEnded;
            v3.Connect(v3, function(arg1_46, ...)
                v1 = arg1_46;
                if v1.UserInputType == Enum.UserInputType.MouseButton1 or v1.UserInputType == Enum.UserInputType.Touch then
                    r113 = false;
                end;
                return; 
            end);
            v3 = r26.InputChanged;
            v3.Connect(v3, function(arg1_47, ...)
                if r113 and arg1_47.UserInputType == Enum.UserInputType.MouseMovement then
                    if r114 then
                        K = arg1_47.Position - r114;
                        if K.Magnitude > 10 then
                            P[g] = true;
                        end;
                        if r116 then
                            r112.Position = r115 + UDim2.new(0, K.X, 0, K.Y);
                        end;
                    end;
                end;
                return; 
            end);
            return r112; 
        end)();
        YV = {
            (function(arg1_48, ...)
                r117 = arg1_48;
                r118 = Instance.new("ScreenGui");
                r118.Name = "QuickInteractGui";
                r118.ResetOnSpawn = false;
                r118.IgnoreGuiInset = true;
                r118.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
                d = gethui;
                a = d() or d.GetService(d, "CoreGui");
                r118.Parent = a;
                v3 = r58;
                if v3 then
                    a = 250;
                    m = 250;
                end;
                r119 = Instance.new("Frame", r118);
                r119.Size = UDim2.new(0, 0, 0, 0);
                r119.Position = UDim2.new(0.5, -250 / 2, 0.5, -300 / 2);
                r119.BackgroundColor3 = Color3.fromRGB(12, 12, 20);
                r119.BorderSizePixel = 0;
                r67(13, r119);
                r68(1.5, Color3.fromRGB(50, 50, 82), r119);
                s = r27;
                v4 = s.Create(s, r119, TweenInfo.new(.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    ["Size"] = UDim2.new(0, 250, 0, 300),
                    ["Position"] = UDim2.new(0.5, -250 / 2, 0.5, -300 / 2 + 150)
                });
                v4.Play(v4);
                v4 = Instance.new("Frame", r119);
                v4.Size = UDim2.new(1, 0, 0, 54);
                v4.BackgroundColor3 = Color3.fromRGB(20, 20, 32);
                v4.BorderSizePixel = 0;
                g = Instance.new("Frame", v4);
                g.Size = UDim2.new(0, 34, 0, 34);
                g.Position = UDim2.new(0, 10, 0.5, -17);
                g.BackgroundColor3 = Color3.fromRGB(55, 205, 255);
                g.BorderSizePixel = 0;
                r67(10, g);
                r69(g, "\xf0\x9f\xa4\x96 ", 18, Color3.fromRGB(20, 20, 20), Enum.Font.GothamBold, Enum.TextXAlignment.Center).Size = UDim2.new(1, 0, 1, 0);
                Q = r69(v4, "THE MORGUE SHIFT", 14, Color3.fromRGB(228, 224, 245));
                Q.Size = UDim2.new(0, 220, 0, 22);
                Q.Position = UDim2.new(0, 52, 0, 8);
                w = r69(v4, "PS SCRIPT  ", 10, Color3.fromRGB(75, 205, 255));
                w.Size = UDim2.new(0, 260, 0, 15);
                w.Position = UDim2.new(0, 52, 0, 30);
                v5 = Instance.new("TextButton", v4);
                v5.Size = UDim2.new(0, 28, 0, 28);
                v5.Position = UDim2.new(1, -34, 0.5, -14);
                v5.BackgroundColor3 = Color3.fromRGB(200, 55, 70);
                v5.Text = "\xe2\x9c\x95";
                v5.TextSize = 12;
                v5.Font = Enum.Font.GothamBold;
                v5.BorderSizePixel = 0;
                r67(7, v5);
                s = v5.MouseButton1Click;
                s.Connect(s, function(...)
                    v3 = r27;
                    k = v3.Create(v3, r119, TweenInfo.new(.2, Enum.EasingStyle.Quart), {
                        ["Size"] = UDim2.new(0, 0, 0, 0)
                    });
                    k.Play(k);
                    task.wait(0.25);
                    v3 = r118;
                    v3.Destroy(v3);
                    return; 
                end);
                r120 = Instance.new("TextButton", v4);
                r120.Size = UDim2.new(0, 28, 0, 28);
                r120.Position = UDim2.new(1, -68, 0.5, -14);
                r120.BackgroundColor3 = Color3.fromRGB(30, 30, 48);
                r120.Text = "\xe2\x94\x80";
                r120.TextSize = 13;
                r120.Font = Enum.Font.GothamBold;
                r67(7, r120);
                r68(1, Color3.fromRGB(50, 50, 82), r120);
                r121 = false;
                v6 = r120.MouseButton1Click;
                v6.Connect(v6, function(...)
                    r121 = not r121;
                    if r121 then
                        P[v2].Visible = false;
                        if r117 then
                            r117.Visible = true;
                        end;
                    else
                        P[v2].Visible = true;
                        if r117 then
                            r117.Visible = false;
                        end;
                        v2 = r121;
                        if v2 then
                            a = "\xe2\x96\xa1";
                        end;
                        v3 = v3;
                        v3 = v3;
                        r120.Text = v2 or "\xe2\x94\x80";
                        return;
                    end; 
                end);
                r122 = false;
                L = v4.InputBegan;
                L.Connect(L, function(arg1_49, ...)
                    v1 = arg1_49;
                    if v1.UserInputType == Enum.UserInputType.MouseButton1 or v1.UserInputType == Enum.UserInputType.Touch then
                        r122 = true;
                        r123 = v1.Position;
                        r124 = r119.Position;
                    end;
                    return; 
                end);
                L = v4.InputEnded;
                L.Connect(L, function(arg1_50, ...)
                    v1 = arg1_50;
                    if v1.UserInputType == Enum.UserInputType.MouseButton1 or v1.UserInputType == Enum.UserInputType.Touch then
                        r122 = false;
                    end;
                    return; 
                end);
                L = r26.InputChanged;
                L.Connect(L, function(arg1_51, ...)
                    K = r122;
                    v1 = arg1_51;
                    if K then
                        k = v1.UserInputType == Enum.UserInputType.MouseMovement or v1.UserInputType == Enum.UserInputType.Touch;
                        v3 = r15;
                    end;
                    if K then
                        K = v1.Position - r123;
                        r119.Position = r124 + UDim2.new(0, K.X, 0, K.Y);
                    end;
                    return; 
                end);
                r125 = {};
                r126 = {};
                r127 = Instance.new("Frame", r119);
                r127.Size = UDim2.new(.4, 0, 0, 32);
                r127.Position = UDim2.new(0, 0, 0, 54);
                r127.BackgroundColor3 = Color3.fromRGB(20, 20, 32);
                r127.BorderSizePixel = 0;
                Y = Instance.new("UIListLayout", r127);
                Y.FillDirection = Enum.FillDirection.Horizontal;
                Y.SortOrder = Enum.SortOrder.LayoutOrder;
                Y.Padding = UDim.new(0, 0);
                local function y(arg1_52, arg2_52, ...)
                    v1 = arg1_52;
                    r128 = Instance.new("TextButton", r127);
                    r128.Size = UDim2.new(0.5, 0, 1, 0);
                    r128.BackgroundColor3 = Color3.fromRGB(30, 30, 48);
                    r128.TextColor3 = Color3.fromRGB(138, 134, 172);
                    r128.Text = arg2_52 .. " " .. v1;
                    r128.TextSize = 10;
                    r128.Font = Enum.Font.GothamBold;
                    r128.BorderSizePixel = 0;
                    r128.LayoutOrder = #r125 + 1;
                    r129 = Instance.new("ScrollingFrame", r119);
                    r129.Size = UDim2.new(1, -20, 1, -116);
                    r129.Position = UDim2.new(0, 10, 0, 92);
                    r129.BackgroundTransparency = 1;
                    r129.Visible = false;
                    r129.CanvasSize = UDim2.new(0, 0, 0, 0);
                    r129.ScrollBarThickness = 4;
                    r129.ScrollBarImageColor3 = Color3.fromRGB(75, 205, 255);
                    r129.AutomaticCanvasSize = Enum.AutomaticSize.Y;
                    r129.ScrollingDirection = Enum.ScrollingDirection.Y;
                    r130 = Instance.new("UIListLayout", r129);
                    r130.SortOrder = Enum.SortOrder.LayoutOrder;
                    r130.Padding = UDim.new(0, 8);
                    v3 = r130;
                    k = v3.GetPropertyChangedSignal(v3, "AbsoluteContentSize");
                    k.Connect(k, function(...)
                        r129.CanvasSize = UDim2.new(0, 0, 0, r130.AbsoluteContentSize.Y + 10);
                        return; 
                    end);
                    v2 = Instance.new("UIPadding", r129);
                    v2.PaddingTop = UDim.new(0, 4);
                    v2.PaddingBottom = UDim.new(0, 12);
                    v2.PaddingRight = UDim.new(0, 4);
                    v3 = r128.MouseButton1Click;
                    v3.Connect(v3, function(...)
                        d = r125;
                        v1 = 85[2];
                        d = 85[1];
                        for K, m in ipairs(d) do
                            m.BackgroundColor3 = Color3.fromRGB(30, 30, 48);
                            m.TextColor3 = Color3.fromRGB(138, 134, 172); 
                        end;
                        d = Color3.fromRGB(75, 205, 255);
                        r128.BackgroundColor3 = d.Lerp(d, Color3.fromRGB(30, 30, 48), 0.5);
                        r128.TextColor3 = Color3.fromRGB(75, 205, 255);
                        d = 205[3];
                        for d, m in 205[1], ipairs(r126) do
                            a = d;
                            m.Visible = false; 
                        end;
                        r129.Visible = true;
                        return; 
                    end);
                    table.insert(r125, r128);
                    table.insert(r126, r129);
                    if v1 == "Main" then
                        v4 = Color3.fromRGB(75, 205, 255);
                        r128.BackgroundColor3 = v4.Lerp(v4, Color3.fromRGB(30, 30, 48), 0.5);
                        r128.TextColor3 = Color3.fromRGB(75, 205, 255);
                        r129.Visible = true;
                    end;
                    return r129; 
                end;
                n = y("Main", "\xe2\x9a\xa1");
                p = y("TP", "\xf0\x9f\x8c\x8d");
                Z = y("MAP TP", "\xf0\x9f\x97\xba\xef\xb8\x8f");
                X = y("SOUL", "\xe2\x99\xa6\xef\xb8\x8f");
                DV = y("ESP", "\xf0\x9f\x91\x81\xef\xb8\x8f");
                r90(n, "\xe2\x9a\xa1  SETTINGS ", 10);
                r70(n, "\xe2\x9a\xa1", "No Delay Button", "Hapus hold duration semua ProximityPrompt", 11, Color3.fromRGB(75, 100, 255), function(arg1_53, ...)
                    P[vV](arg1_53);
                    return; 
                end);
                r79(n, "Walk Speed", "studs/s", 13, 1, 500, r66.WalkSpeed, Color3.fromRGB(55, 215, 118), function(arg1_54, ...)
                    v1 = arg1_54;
                    K = arg1_54;
                    r66.WalkSpeed = K;
                    if r66.SpeedHack then
                        r105(v1);
                    end;
                    r62(r66);
                    return; 
                end);
                r70(n, "\xf0\x9f\x8f\x83", "Speed Hack", "Ubah kecepatan jalan karakter", 12, Color3.fromRGB(55, 215, 118), function(arg1_55, ...)
                    P[fV](arg1_55);
                    return; 
                end);
                r70(n, "\xf0\x9f\x91\xbb", "Noclip", "Tembus dinding dan benda", 14, Color3.fromRGB(240, 65, 80), function(arg1_56, ...)
                    P[UV](arg1_56);
                    return; 
                end);
                r92(n, 15, function(arg1_57, ...)
                    v1 = arg1_57;
                    K = arg1_57;
                    r66.WalkSpeed = K;
                    if r66.SpeedHack then
                        r105(v1);
                    end;
                    r62(r66);
                    return; 
                end);
                EV = v3;
                VV = v3;
                r91(n, "\xf0\x9f\x92\xa1  Speed Hack harus aktif agar kecepatan diterapkan\n    Preset: Normal=9  Cepat=12  Turbo=20 ", 16, r58 and 48 or 42, Color3.fromRGB(55, 215, 118));
                r90(n, "\xf0\x9f\x92\xbe  CONFIGURASI", 20);
                r96(n, 21);
                EV = v3;
                VV = v3;
                r91(n, "\xf0\x9f\x92\xbe  Save = Simpan config\n\xe2\x9a\x99 Load = Muat config tersimpan\n\xf0\x9f\x94\x84 Reset = Kembalikan ke default", 22, r58 and 54 or 48, Color3.fromRGB(75, 205, 255));
                r70(n, "\xf0\x9f\x9b\xa1\xef\xb8\x8f", "Anti Ghost", "Hantu tidak bisa membunuh kamu", 15, Color3.fromRGB(255, 80, 80), function(arg1_58, ...)
                    P[60](arg1_58);
                    return; 
                end);
                r90(p, "\xf0\x9f\x8c\x8d  PLAYER LIST ", 1);
                r131 = Instance.new("Frame", p);
                r131.Size = UDim2.new(1, 0, 0, 0);
                r131.BackgroundTransparency = 1;
                r131.BorderSizePixel = 0;
                r131.AutomaticSize = Enum.AutomaticSize.Y;
                TV = Instance.new("UIListLayout", r131);
                TV.SortOrder = Enum.SortOrder.LayoutOrder;
                TV.Padding = UDim.new(0, 6);
                local function r132(...)
                    d = r131;
                    K = d[3];
                    d = d[1];
                    for K, m in d, ipairs(d.GetChildren(d)) do
                        a = K;
                        if m.IsA(m, "Frame") then
                            m.Destroy(m);
                        end; 
                    end;
                    v1 = 0;
                    m = r24;
                    v2 = {
                        m.GetPlayers(m)
                    };
                    K = m[1];
                    d = m[2];
                    for a, v2 in ipairs(G(v2)) do
                        m = a;
                        if v2 ~= r28 then
                            r99(r131, v2, 0, function(arg1_59, ...)
                                P[C[25]](arg1_59);
                                return; 
                            end);
                            v1 = 0 + 1;
                        end; 
                    end;
                    return; 
                end;
                GV = r24.PlayerAdded;
                GV.Connect(GV, function(...)
                    r132();
                    return; 
                end);
                GV = r24.PlayerRemoving;
                GV.Connect(GV, function(...)
                    r132();
                    return; 
                end);
                r132();
                rV = v3;
                PV = v3;
                r91(p, "\xf0\x9f\x8c\x8d  Klik tombol [TP] untuk teleport ke player\n    Daftar update otomatis saat ada player join/leave", 3, r58 and 50 or 44, Color3.fromRGB(255, 188, 45));
                r90(X, "\xe2\x99\xa6\xef\xb8\x8f AUTO COLLECT", 1);
                r70(X, "\xf0\x9f\x91\xbb", "Auto Soul", "Ambil soul / orb otomatis", 2, Color3.fromRGB(255, 188, 45), function(arg1_60, ...)
                    setAutoSoul(arg1_60);
                    return; 
                end);
                PV = v3;
                rV = v3;
                r91(X, "\xe2\x99\xa6\xef\xb8\x8f Auto Soul akan otomatis collect semua soul/orb di map", 3, r58 and 50 or 44, Color3.fromRGB(255, 188, 45));
                r90(Z, "\xf0\x9f\x97\xba\xef\xb8\x8f  TELEPORT KE LOKASI", 1);
                rV = "name";
                kV = "name";
                PV = "Ruang Jenazah";
                OV = "pos";
                Vector3.new(20.51, 4.78, -33.77);
                kV = {
                    ["name"] = "Ruang Penyimpanan",
                    ["pos"] = Vector3.new(86.34, 22.37, -23.9)
                };
                PV = {
                    ["name"] = "Ruang Pengawetan",
                    ["pos"] = Vector3.new(42.35, 20.91, -27.01)
                };
                CV = rV[2];
                VV = rV[1];
                for EV, rV in ipairs({
                    {
                        ["name"] = "Lobby",
                        ["pos"] = Vector3.new(55.76, 4.78, -60.77)
                    },
                    {
                        ["name"] = "Ruang Otopsi",
                        ["pos"] = Vector3.new(82.1, 4.78, -56.5)
                    },
                    {
                        ["name"] = "Ruang Sterilisasi",
                        ["pos"] = Vector3.new(88.84, 4.78, -28.1)
                    },
                    {
                        [rV] = "Ruang Kremasi",
                        ["pos"] = Vector3.new(33.8, 4.78, -57.62)
                    },
                    rV,
                    kV,
                    PV,
                    {
                        ["name"] = "Ruang Elektrikal",
                        ["pos"] = Vector3.new(25.77, 17.65, -55.56)
                    },
                    {
                        ["name"] = "Ruang Duka",
                        ["pos"] = Vector3.new(56.35, 17.75, -44.3)
                    }
                }), PV do
                    r133 = rV;
                    PV = Instance.new("TextButton", Z);
                    PV.Size = UDim2.new(1, -20, 0, 35);
                    PV.Position = UDim2.new(0, 10, 0, 25 + (EV - 1) * 40);
                    PV.BackgroundColor3 = Color3.fromRGB(30, 30, 48);
                    PV.TextColor3 = Color3.fromRGB(228, 224, 245);
                    PV.Text = r133.name;
                    PV.Font = Enum.Font.GothamBold;
                    PV.TextSize = 12;
                    PV.BorderSizePixel = 0;
                    r67(8, PV);
                    r68(1, Color3.fromRGB(50, 50, 82), PV);
                    kV = PV.MouseButton1Click;
                    kV.Connect(kV, function(...)
                        v1 = r28;
                        if v1 then
                            a = v1.Character;
                            k = a and a.FindFirstChild(a, "HumanoidRootPart");
                            v3 = r28;
                        end;
                        if v1 then
                            v1.Character.HumanoidRootPart.CFrame = CFrame.new(r133.pos + Vector3.new(0, 2, 0));
                        end;
                        return; 
                    end); 
                end;
                r90(DV, "\xf0\x9f\x91\x81\xef\xb8\x8f ESP SETTINGS", 1);
                r70(DV, "\xf0\x9f\x91\xa4", "ESP Player", "Melihat player melalui dinding", 2, Color3.fromRGB(0, 255, 255), function(arg1_61, ...)
                    setESPPlayer(arg1_61);
                    return; 
                end);
                r70(DV, "\xe2\x99\xa6\xef\xb8\x8f", "ESP Soul", "Menampilkan soul/orb", 3, Color3.fromRGB(255, 255, 0), function(arg1_62, ...)
                    P[61](arg1_62);
                    return; 
                end);
                r70(DV, "\xf0\x9f\x91\xbb", "ESP Hantu", "Deteksi hantu di map", 4, Color3.fromRGB(255, 0, 0), function(arg1_63, ...)
                    P[66](arg1_63);
                    return; 
                end);
                kV = v3;
                OV = v3;
                r91(DV, "\xf0\x9f\x91\x81\xef\xb8\x8f ESP akan menampilkan label di atas target\n    Player: Cyan | Soul: Yellow | Ghost: Red", 5, r58 and 50 or 44, Color3.fromRGB(75, 205, 255));
                return r119, r118; 
            end)(r111)
        };
        nV = YV[2];
        r134 = (function(arg1_64, ...)
            r117 = arg1_64;
            r118 = Instance.new("ScreenGui");
            r118.Name = "QuickInteractGui";
            r118.ResetOnSpawn = false;
            r118.IgnoreGuiInset = true;
            r118.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
            d = gethui;
            a = d() or d.GetService(d, "CoreGui");
            r118.Parent = a;
            v3 = r58;
            if v3 then
                a = 250;
                m = 250;
            end;
            r119 = Instance.new("Frame", r118);
            r119.Size = UDim2.new(0, 0, 0, 0);
            r119.Position = UDim2.new(0.5, -250 / 2, 0.5, -300 / 2);
            r119.BackgroundColor3 = Color3.fromRGB(12, 12, 20);
            r119.BorderSizePixel = 0;
            r67(13, r119);
            r68(1.5, Color3.fromRGB(50, 50, 82), r119);
            s = r27;
            v4 = s.Create(s, r119, TweenInfo.new(.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                ["Size"] = UDim2.new(0, 250, 0, 300),
                ["Position"] = UDim2.new(0.5, -250 / 2, 0.5, -300 / 2 + 150)
            });
            v4.Play(v4);
            v4 = Instance.new("Frame", r119);
            v4.Size = UDim2.new(1, 0, 0, 54);
            v4.BackgroundColor3 = Color3.fromRGB(20, 20, 32);
            v4.BorderSizePixel = 0;
            g = Instance.new("Frame", v4);
            g.Size = UDim2.new(0, 34, 0, 34);
            g.Position = UDim2.new(0, 10, 0.5, -17);
            g.BackgroundColor3 = Color3.fromRGB(55, 205, 255);
            g.BorderSizePixel = 0;
            r67(10, g);
            r69(g, "\xf0\x9f\xa4\x96 ", 18, Color3.fromRGB(20, 20, 20), Enum.Font.GothamBold, Enum.TextXAlignment.Center).Size = UDim2.new(1, 0, 1, 0);
            Q = r69(v4, "THE MORGUE SHIFT", 14, Color3.fromRGB(228, 224, 245));
            Q.Size = UDim2.new(0, 220, 0, 22);
            Q.Position = UDim2.new(0, 52, 0, 8);
            w = r69(v4, "PS SCRIPT  ", 10, Color3.fromRGB(75, 205, 255));
            w.Size = UDim2.new(0, 260, 0, 15);
            w.Position = UDim2.new(0, 52, 0, 30);
            v5 = Instance.new("TextButton", v4);
            v5.Size = UDim2.new(0, 28, 0, 28);
            v5.Position = UDim2.new(1, -34, 0.5, -14);
            v5.BackgroundColor3 = Color3.fromRGB(200, 55, 70);
            v5.Text = "\xe2\x9c\x95";
            v5.TextSize = 12;
            v5.Font = Enum.Font.GothamBold;
            v5.BorderSizePixel = 0;
            r67(7, v5);
            s = v5.MouseButton1Click;
            s.Connect(s, function(...)
                v3 = r27;
                k = v3.Create(v3, r119, TweenInfo.new(.2, Enum.EasingStyle.Quart), {
                    ["Size"] = UDim2.new(0, 0, 0, 0)
                });
                k.Play(k);
                task.wait(0.25);
                v3 = r118;
                v3.Destroy(v3);
                return; 
            end);
            r120 = Instance.new("TextButton", v4);
            r120.Size = UDim2.new(0, 28, 0, 28);
            r120.Position = UDim2.new(1, -68, 0.5, -14);
            r120.BackgroundColor3 = Color3.fromRGB(30, 30, 48);
            r120.Text = "\xe2\x94\x80";
            r120.TextSize = 13;
            r120.Font = Enum.Font.GothamBold;
            r67(7, r120);
            r68(1, Color3.fromRGB(50, 50, 82), r120);
            r121 = false;
            v6 = r120.MouseButton1Click;
            v6.Connect(v6, function(...)
                r121 = not r121;
                if r121 then
                    P[v2].Visible = false;
                    if r117 then
                        r117.Visible = true;
                    end;
                else
                    P[v2].Visible = true;
                    if r117 then
                        r117.Visible = false;
                    end;
                    v2 = r121;
                    if v2 then
                        a = "\xe2\x96\xa1";
                    end;
                    v3 = v3;
                    v3 = v3;
                    r120.Text = v2 or "\xe2\x94\x80";
                    return;
                end; 
            end);
            r122 = false;
            L = v4.InputBegan;
            L.Connect(L, function(arg1_65, ...)
                v1 = arg1_65;
                if v1.UserInputType == Enum.UserInputType.MouseButton1 or v1.UserInputType == Enum.UserInputType.Touch then
                    r122 = true;
                    r123 = v1.Position;
                    r124 = r119.Position;
                end;
                return; 
            end);
            L = v4.InputEnded;
            L.Connect(L, function(arg1_66, ...)
                v1 = arg1_66;
                if v1.UserInputType == Enum.UserInputType.MouseButton1 or v1.UserInputType == Enum.UserInputType.Touch then
                    r122 = false;
                end;
                return; 
            end);
            L = r26.InputChanged;
            L.Connect(L, function(arg1_67, ...)
                K = r122;
                v1 = arg1_67;
                if K then
                    k = v1.UserInputType == Enum.UserInputType.MouseMovement or v1.UserInputType == Enum.UserInputType.Touch;
                    v3 = r15;
                end;
                if K then
                    K = v1.Position - r123;
                    r119.Position = r124 + UDim2.new(0, K.X, 0, K.Y);
                end;
                return; 
            end);
            r125 = {};
            r126 = {};
            r127 = Instance.new("Frame", r119);
            r127.Size = UDim2.new(.4, 0, 0, 32);
            r127.Position = UDim2.new(0, 0, 0, 54);
            r127.BackgroundColor3 = Color3.fromRGB(20, 20, 32);
            r127.BorderSizePixel = 0;
            Y = Instance.new("UIListLayout", r127);
            Y.FillDirection = Enum.FillDirection.Horizontal;
            Y.SortOrder = Enum.SortOrder.LayoutOrder;
            Y.Padding = UDim.new(0, 0);
            local function y(arg1_68, arg2_68, ...)
                v1 = arg1_68;
                r128 = Instance.new("TextButton", r127);
                r128.Size = UDim2.new(0.5, 0, 1, 0);
                r128.BackgroundColor3 = Color3.fromRGB(30, 30, 48);
                r128.TextColor3 = Color3.fromRGB(138, 134, 172);
                r128.Text = arg2_68 .. " " .. v1;
                r128.TextSize = 10;
                r128.Font = Enum.Font.GothamBold;
                r128.BorderSizePixel = 0;
                r128.LayoutOrder = #r125 + 1;
                r129 = Instance.new("ScrollingFrame", r119);
                r129.Size = UDim2.new(1, -20, 1, -116);
                r129.Position = UDim2.new(0, 10, 0, 92);
                r129.BackgroundTransparency = 1;
                r129.Visible = false;
                r129.CanvasSize = UDim2.new(0, 0, 0, 0);
                r129.ScrollBarThickness = 4;
                r129.ScrollBarImageColor3 = Color3.fromRGB(75, 205, 255);
                r129.AutomaticCanvasSize = Enum.AutomaticSize.Y;
                r129.ScrollingDirection = Enum.ScrollingDirection.Y;
                r130 = Instance.new("UIListLayout", r129);
                r130.SortOrder = Enum.SortOrder.LayoutOrder;
                r130.Padding = UDim.new(0, 8);
                v3 = r130;
                k = v3.GetPropertyChangedSignal(v3, "AbsoluteContentSize");
                k.Connect(k, function(...)
                    r129.CanvasSize = UDim2.new(0, 0, 0, r130.AbsoluteContentSize.Y + 10);
                    return; 
                end);
                v2 = Instance.new("UIPadding", r129);
                v2.PaddingTop = UDim.new(0, 4);
                v2.PaddingBottom = UDim.new(0, 12);
                v2.PaddingRight = UDim.new(0, 4);
                v3 = r128.MouseButton1Click;
                v3.Connect(v3, function(...)
                    d = r125;
                    v1 = 85[2];
                    d = 85[1];
                    for K, m in ipairs(d) do
                        m.BackgroundColor3 = Color3.fromRGB(30, 30, 48);
                        m.TextColor3 = Color3.fromRGB(138, 134, 172); 
                    end;
                    d = Color3.fromRGB(75, 205, 255);
                    r128.BackgroundColor3 = d.Lerp(d, Color3.fromRGB(30, 30, 48), 0.5);
                    r128.TextColor3 = Color3.fromRGB(75, 205, 255);
                    d = 205[3];
                    for d, m in 205[1], ipairs(r126) do
                        a = d;
                        m.Visible = false; 
                    end;
                    r129.Visible = true;
                    return; 
                end);
                table.insert(r125, r128);
                table.insert(r126, r129);
                if v1 == "Main" then
                    v4 = Color3.fromRGB(75, 205, 255);
                    r128.BackgroundColor3 = v4.Lerp(v4, Color3.fromRGB(30, 30, 48), 0.5);
                    r128.TextColor3 = Color3.fromRGB(75, 205, 255);
                    r129.Visible = true;
                end;
                return r129; 
            end;
            n = y("Main", "\xe2\x9a\xa1");
            p = y("TP", "\xf0\x9f\x8c\x8d");
            Z = y("MAP TP", "\xf0\x9f\x97\xba\xef\xb8\x8f");
            X = y("SOUL", "\xe2\x99\xa6\xef\xb8\x8f");
            DV = y("ESP", "\xf0\x9f\x91\x81\xef\xb8\x8f");
            r90(n, "\xe2\x9a\xa1  SETTINGS ", 10);
            r70(n, "\xe2\x9a\xa1", "No Delay Button", "Hapus hold duration semua ProximityPrompt", 11, Color3.fromRGB(75, 100, 255), function(arg1_69, ...)
                P[vV](arg1_69);
                return; 
            end);
            r79(n, "Walk Speed", "studs/s", 13, 1, 500, r66.WalkSpeed, Color3.fromRGB(55, 215, 118), function(arg1_70, ...)
                v1 = arg1_70;
                K = arg1_70;
                r66.WalkSpeed = K;
                if r66.SpeedHack then
                    r105(v1);
                end;
                r62(r66);
                return; 
            end);
            r70(n, "\xf0\x9f\x8f\x83", "Speed Hack", "Ubah kecepatan jalan karakter", 12, Color3.fromRGB(55, 215, 118), function(arg1_71, ...)
                P[fV](arg1_71);
                return; 
            end);
            r70(n, "\xf0\x9f\x91\xbb", "Noclip", "Tembus dinding dan benda", 14, Color3.fromRGB(240, 65, 80), function(arg1_72, ...)
                P[UV](arg1_72);
                return; 
            end);
            r92(n, 15, function(arg1_73, ...)
                v1 = arg1_73;
                K = arg1_73;
                r66.WalkSpeed = K;
                if r66.SpeedHack then
                    r105(v1);
                end;
                r62(r66);
                return; 
            end);
            EV = v3;
            VV = v3;
            r91(n, "\xf0\x9f\x92\xa1  Speed Hack harus aktif agar kecepatan diterapkan\n    Preset: Normal=9  Cepat=12  Turbo=20 ", 16, r58 and 48 or 42, Color3.fromRGB(55, 215, 118));
            r90(n, "\xf0\x9f\x92\xbe  CONFIGURASI", 20);
            r96(n, 21);
            EV = v3;
            VV = v3;
            r91(n, "\xf0\x9f\x92\xbe  Save = Simpan config\n\xe2\x9a\x99 Load = Muat config tersimpan\n\xf0\x9f\x94\x84 Reset = Kembalikan ke default", 22, r58 and 54 or 48, Color3.fromRGB(75, 205, 255));
            r70(n, "\xf0\x9f\x9b\xa1\xef\xb8\x8f", "Anti Ghost", "Hantu tidak bisa membunuh kamu", 15, Color3.fromRGB(255, 80, 80), function(arg1_74, ...)
                P[60](arg1_74);
                return; 
            end);
            r90(p, "\xf0\x9f\x8c\x8d  PLAYER LIST ", 1);
            r131 = Instance.new("Frame", p);
            r131.Size = UDim2.new(1, 0, 0, 0);
            r131.BackgroundTransparency = 1;
            r131.BorderSizePixel = 0;
            r131.AutomaticSize = Enum.AutomaticSize.Y;
            TV = Instance.new("UIListLayout", r131);
            TV.SortOrder = Enum.SortOrder.LayoutOrder;
            TV.Padding = UDim.new(0, 6);
            local function r132(...)
                d = r131;
                K = d[3];
                d = d[1];
                for K, m in d, ipairs(d.GetChildren(d)) do
                    a = K;
                    if m.IsA(m, "Frame") then
                        m.Destroy(m);
                    end; 
                end;
                v1 = 0;
                m = r24;
                v2 = {
                    m.GetPlayers(m)
                };
                K = m[1];
                d = m[2];
                for a, v2 in ipairs(G(v2)) do
                    m = a;
                    if v2 ~= r28 then
                        r99(r131, v2, 0, function(arg1_75, ...)
                            P[C[25]](arg1_75);
                            return; 
                        end);
                        v1 = 0 + 1;
                    end; 
                end;
                return; 
            end;
            GV = r24.PlayerAdded;
            GV.Connect(GV, function(...)
                r132();
                return; 
            end);
            GV = r24.PlayerRemoving;
            GV.Connect(GV, function(...)
                r132();
                return; 
            end);
            r132();
            rV = v3;
            PV = v3;
            r91(p, "\xf0\x9f\x8c\x8d  Klik tombol [TP] untuk teleport ke player\n    Daftar update otomatis saat ada player join/leave", 3, r58 and 50 or 44, Color3.fromRGB(255, 188, 45));
            r90(X, "\xe2\x99\xa6\xef\xb8\x8f AUTO COLLECT", 1);
            r70(X, "\xf0\x9f\x91\xbb", "Auto Soul", "Ambil soul / orb otomatis", 2, Color3.fromRGB(255, 188, 45), function(arg1_76, ...)
                setAutoSoul(arg1_76);
                return; 
            end);
            PV = v3;
            rV = v3;
            r91(X, "\xe2\x99\xa6\xef\xb8\x8f Auto Soul akan otomatis collect semua soul/orb di map", 3, r58 and 50 or 44, Color3.fromRGB(255, 188, 45));
            r90(Z, "\xf0\x9f\x97\xba\xef\xb8\x8f  TELEPORT KE LOKASI", 1);
            rV = "name";
            kV = "name";
            PV = "Ruang Jenazah";
            OV = "pos";
            Vector3.new(20.51, 4.78, -33.77);
            kV = {
                ["name"] = "Ruang Penyimpanan",
                ["pos"] = Vector3.new(86.34, 22.37, -23.9)
            };
            PV = {
                ["name"] = "Ruang Pengawetan",
                ["pos"] = Vector3.new(42.35, 20.91, -27.01)
            };
            CV = rV[2];
            VV = rV[1];
            for EV, rV in ipairs({
                {
                    ["name"] = "Lobby",
                    ["pos"] = Vector3.new(55.76, 4.78, -60.77)
                },
                {
                    ["name"] = "Ruang Otopsi",
                    ["pos"] = Vector3.new(82.1, 4.78, -56.5)
                },
                {
                    ["name"] = "Ruang Sterilisasi",
                    ["pos"] = Vector3.new(88.84, 4.78, -28.1)
                },
                {
                    [rV] = "Ruang Kremasi",
                    ["pos"] = Vector3.new(33.8, 4.78, -57.62)
                },
                rV,
                kV,
                PV,
                {
                    ["name"] = "Ruang Elektrikal",
                    ["pos"] = Vector3.new(25.77, 17.65, -55.56)
                },
                {
                    ["name"] = "Ruang Duka",
                    ["pos"] = Vector3.new(56.35, 17.75, -44.3)
                }
            }), PV do
                r133 = rV;
                PV = Instance.new("TextButton", Z);
                PV.Size = UDim2.new(1, -20, 0, 35);
                PV.Position = UDim2.new(0, 10, 0, 25 + (EV - 1) * 40);
                PV.BackgroundColor3 = Color3.fromRGB(30, 30, 48);
                PV.TextColor3 = Color3.fromRGB(228, 224, 245);
                PV.Text = r133.name;
                PV.Font = Enum.Font.GothamBold;
                PV.TextSize = 12;
                PV.BorderSizePixel = 0;
                r67(8, PV);
                r68(1, Color3.fromRGB(50, 50, 82), PV);
                kV = PV.MouseButton1Click;
                kV.Connect(kV, function(...)
                    v1 = r28;
                    if v1 then
                        a = v1.Character;
                        k = a and a.FindFirstChild(a, "HumanoidRootPart");
                        v3 = r28;
                    end;
                    if v1 then
                        v1.Character.HumanoidRootPart.CFrame = CFrame.new(r133.pos + Vector3.new(0, 2, 0));
                    end;
                    return; 
                end); 
            end;
            r90(DV, "\xf0\x9f\x91\x81\xef\xb8\x8f ESP SETTINGS", 1);
            r70(DV, "\xf0\x9f\x91\xa4", "ESP Player", "Melihat player melalui dinding", 2, Color3.fromRGB(0, 255, 255), function(arg1_77, ...)
                setESPPlayer(arg1_77);
                return; 
            end);
            r70(DV, "\xe2\x99\xa6\xef\xb8\x8f", "ESP Soul", "Menampilkan soul/orb", 3, Color3.fromRGB(255, 255, 0), function(arg1_78, ...)
                P[61](arg1_78);
                return; 
            end);
            r70(DV, "\xf0\x9f\x91\xbb", "ESP Hantu", "Deteksi hantu di map", 4, Color3.fromRGB(255, 0, 0), function(arg1_79, ...)
                P[66](arg1_79);
                return; 
            end);
            kV = v3;
            OV = v3;
            r91(DV, "\xf0\x9f\x91\x81\xef\xb8\x8f ESP akan menampilkan label di atas target\n    Player: Cyan | Soul: Yellow | Ghost: Red", 5, r58 and 50 or 44, Color3.fromRGB(75, 205, 255));
            return r119, r118; 
        end)(r111);
        r135 = false;
        r138 = false;
        pV = r111.InputBegan;
        pV.Connect(pV, function(arg1_80, ...)
            v1 = arg1_80;
            if v1.UserInputType == Enum.UserInputType.MouseButton1 or v1.UserInputType == Enum.UserInputType.Touch then
                r138 = false;
                r135 = true;
                r136 = v1.Position;
                r137 = r111.Position;
            end;
            return; 
        end);
        pV = r26.InputChanged;
        pV.Connect(pV, function(arg1_81, ...)
            if r135 and arg1_81.UserInputType == Enum.UserInputType.MouseMovement then
                if r136 then
                    if (arg1_81.Position - r136).Magnitude > 10 then
                        r138 = true;
                    end;
                end;
            end;
            return; 
        end);
        pV = r111.InputEnded;
        pV.Connect(pV, function(arg1_82, ...)
            v1 = arg1_82;
            if v1.UserInputType == Enum.UserInputType.MouseButton1 or v1.UserInputType == Enum.UserInputType.Touch then
                r135 = false;
                if not r138 then
                    r134.Visible = not r134.Visible;
                    r111.Visible = not r111.Visible;
                end;
            end;
            return; 
        end);
        r134.Visible = false;
        r111.Visible = true;
        (function(...)
            if r66.NoDelay then
                r107(true);
            end;
            if r66.SpeedHack then
                r106(true);
            end;
            if r66.Noclip then
                r104(true);
            end;
            if r66.WalkSpeed and r66.WalkSpeed ~= 16 then
                r105(r66.WalkSpeed);
            end;
            return; 
        end)();
        AV = r26.InputBegan;
        AV.Connect(AV, function(arg1_83, arg2_83, ...)
            if arg2_83 then
                return;
            end;
            if arg1_83.KeyCode == Enum.KeyCode.RightShift then
                r134.Visible = not r134.Visible;
                r111.Visible = not r111.Visible;
            end;
            return; 
        end);
        print("[Script] \xe2\x9c\x85 MORGUE SHIFT loaded with all features!");
        print("[Script] \xf0\x9f\xa4\x96 Click the bubble icon to toggle UI");
        print("[Script] \xf0\x9f\x91\x81\xef\xb8\x8f ESP features now available in ESP tab");
        return;
    end;
end;
return (function(...)
    while true do
        l1 = l2;
        l2 = l1;
        r3(); 
    end;
    return; 
end)();