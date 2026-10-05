-- AXIOM RIVALS v6.5 | 老闆專用
-- 放在執行器裡跑，別問我為什麼，問就是為了部落

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ═══════════════════════════════════════════
-- 設定檔
-- ═══════════════════════════════════════════
local CONFIG = {
    ESP = {
        Enabled = false, Name = true, Distance = true, Health = true,
        Tracer = true, Hitbox = true, RainbowSpeed = 1,
        MaxDistance = 2000, ColorByDistance = true,
    },
    Combat = {
        Aimbot = false, WallCheck = true, FOVShow = true,
        MouseSim = true, FOYSmooth = true, FOVRadius = 120,
        Smoothness = 0.15, Sensitivity = 1, MouseSmooth = 1,
    },
    Movement = {
        Noclip = false, BunnyHop = false, InfJump = false,
        Speed = 16, JumpPower = 50, SavedPos = nil,
    },
    Misc = {
        TeamCheck = true, AntiAFK = false, ChatNotify = false,
        JoinLeaveNotify = true, ScanMode = "Auto", Theme = 1,
    },
    System = { Hidden = false, HideKey = Enum.KeyCode.RightShift },
}

-- ═══════════════════════════════════════════
-- 主題
-- ═══════════════════════════════════════════
local THEMES = {
    { Name = "霓虹青", Main = Color3.fromRGB(0, 255, 255), Accent = Color3.fromRGB(0, 150, 200) },
    { Name = "紫電", Main = Color3.fromRGB(170, 0, 255), Accent = Color3.fromRGB(100, 0, 180) },
    { Name = "烈焰", Main = Color3.fromRGB(255, 80, 0), Accent = Color3.fromRGB(200, 40, 0) },
    { Name = "血月", Main = Color3.fromRGB(255, 0, 60), Accent = Color3.fromRGB(150, 0, 30) },
    { Name = "冰霜", Main = Color3.fromRGB(180, 230, 255), Accent = Color3.fromRGB(100, 150, 200) },
}

-- ═══════════════════════════════════════════
-- 工具函式
-- ═══════════════════════════════════════════
local function safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[AXIOM] 靠北，出事了: " .. tostring(err)) end
    return ok, err
end

local function create(className, props)
    local inst = Instance.new(className)
    for k, v in pairs(props or {}) do inst[k] = v end
    return inst
end

local function getTheme() return THEMES[CONFIG.Misc.Theme] or THEMES[1] end

-- ═══════════════════════════════════════════
-- GUI 建構
-- ═══════════════════════════════════════════
local ScreenGui = create("ScreenGui", {
    Name = "AxiomRivals",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = CoreGui,
})

local Main = create("Frame", {
    Name = "Main",
    Size = UDim2.new(0, 520, 0, 420),
    Position = UDim2.new(0.5, -260, 0.5, -210),
    BackgroundColor3 = Color3.fromRGB(15, 15, 20),
    BorderSizePixel = 0,
    Parent = ScreenGui,
})
create("UICorner", { CornerRadius = UDim.new(0, 16), Parent = Main })
local MainStroke = create("UIStroke", {
    Color = getTheme().Main, Thickness = 2, Parent = Main,
})

-- 頂部光暈
local Glow = create("Frame", {
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundColor3 = getTheme().Main,
    BackgroundTransparency = 0.85,
    BorderSizePixel = 0,
    Parent = Main,
})
create("UICorner", { CornerRadius = UDim.new(0, 16), Parent = Glow })

-- 標題
local Title = create("TextLabel", {
    Size = UDim2.new(1, -20, 0, 36),
    Position = UDim2.new(0, 10, 0, 8),
    BackgroundTransparency = 1,
    Text = "AXIOM RIVALS v6.5",
    TextColor3 = getTheme().Main,
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Main,
})
create("Frame", {
    Size = UDim2.new(1, -20, 0, 2),
    Position = UDim2.new(0, 10, 0, 44),
    BackgroundColor3 = getTheme().Accent,
    BorderSizePixel = 0,
    Parent = Main,
})

-- 收合按鈕
local CollapseBtn = create("TextButton", {
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -40, 0, 8),
    BackgroundColor3 = getTheme().Accent,
    Text = "—",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    Parent = Main,
})
create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = CollapseBtn })

-- 分頁列
local TabBar = create("Frame", {
    Size = UDim2.new(1, -20, 0, 34),
    Position = UDim2.new(0, 10, 0, 54),
    BackgroundTransparency = 1,
    Parent = Main,
})
create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6),
    Parent = TabBar,
})

local Content = create("ScrollingFrame", {
    Size = UDim2.new(1, -20, 1, -150),
    Position = UDim2.new(0, 10, 0, 96),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    Parent = Main,
})
create("UIListLayout", { Padding = UDim.new(0, 6), Parent = Content })

-- ═══════════════════════════════════════════
-- 控件工廠
-- ═══════════════════════════════════════════
local Tabs = {}
local ActiveTab = nil

local function clearContent()
    for _, c in ipairs(Content:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
end

local function makeToggle(text, key, callback)
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(25, 25, 32),
        BorderSizePixel = 0,
        Parent = Content,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = row })
    create("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(220, 220, 230),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    local btn = create("TextButton", {
        Size = UDim2.new(0, 50, 0, 22),
        Position = UDim2.new(1, -60, 0.5, -11),
        BackgroundColor3 = CONFIG[key] and getTheme().Main or Color3.fromRGB(50, 50, 60),
        Text = CONFIG[key] and "ON" or "OFF",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Parent = row,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
    btn.MouseButton1Click:Connect(function()
        CONFIG[key] = not CONFIG[key]
        btn.Text = CONFIG[key] and "ON" or "OFF"
        btn.BackgroundColor3 = CONFIG[key] and getTheme().Main or Color3.fromRGB(50, 50, 60)
        if callback then safe(callback, CONFIG[key]) end
    end)
    return row
end

local function makeSlider(text, key, min, max, callback)
    local row = create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Color3.fromRGB(25, 25, 32),
        BorderSizePixel = 0,
        Parent = Content,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = row })
    local lbl = create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 10, 0, 2),
        BackgroundTransparency = 1,
        Text = text .. ": " .. tostring(CONFIG[key]),
        TextColor3 = Color3.fromRGB(220, 220, 230),
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    local bar = create("Frame", {
        Size = UDim2.new(1, -20, 0, 8),
        Position = UDim2.new(0, 10, 0, 26),
        BackgroundColor3 = Color3.fromRGB(50, 50, 60),
        BorderSizePixel = 0,
        Parent = row,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = bar })
    local fill = create("Frame", {
        Size = UDim2.new((CONFIG[key] - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = getTheme().Main,
        BorderSizePixel = 0,
        Parent = bar,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = fill })
    local dragging = false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * rel)
            CONFIG[key] = val
            lbl.Text = text .. ": " .. tostring(val)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            if callback then safe(callback, val) end
        end
    end)
    return row
end

local function makeButton(text, callback)
    local btn = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = getTheme().Accent,
        Text = text,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Parent = Content,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
    btn.MouseButton1Click:Connect(function() safe(callback) end)
    return btn
end

-- ═══════════════════════════════════════════
-- 分頁定義
-- ═══════════════════════════════════════════
local function buildVisual()
    clearContent()
    makeToggle("ESP 開關", "ESP_Enabled")
    makeToggle("名字顯示", "ESP_Name")
    makeToggle("距離顯示", "ESP_Distance")
    makeToggle("血量顯示", "ESP_Health")
    makeToggle("追蹤線", "ESP_Tracer")
    makeToggle("Hitbox 顯示", "ESP_Hitbox")
    makeSlider("彩虹速度", "ESP_RainbowSpeed", 1, 10)
    makeSlider("ESP 距離", "ESP_MaxDistance", 100, 5000)
    makeToggle("外框顏色隨距離變色", "ESP_ColorByDistance")
end

local function buildCombat()
    clearContent()
    makeToggle("自瞄開關", "Combat_Aimbot")
    makeToggle("自瞄牆檢", "Combat_WallCheck")
    makeToggle("FOV 顯示", "Combat_FOVShow")
    makeToggle("模擬滑鼠自瞄", "Combat_MouseSim")
    makeToggle("FOV 距離平滑", "Combat_FOYSmooth")
    makeSlider("FOV 半徑", "Combat_FOVRadius", 20, 500)
    makeSlider("自瞄平滑", "Combat_Smoothness", 1, 100)
    makeSlider("滑鼠靈敏度", "Combat_Sensitivity", 1, 10)
    makeSlider("滑鼠平滑", "Combat_MouseSmooth", 1, 10)
end

local function buildMovement()
    clearContent()
    makeToggle("穿牆", "Movement_Noclip")
    makeToggle("Bunny Hop", "Movement_BunnyHop")
    makeToggle("無限跳躍", "Movement_InfJump")
    makeSlider("移動速度", "Movement_Speed", 16, 200)
    makeSlider("跳躍力", "Movement_JumpPower", 50, 300)
    makeButton("記錄當前位置", function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then CONFIG.Movement.SavedPos = hrp.CFrame end
    end)
    makeButton("傳回記錄點", function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and CONFIG.Movement.SavedPos then hrp.CFrame = CONFIG.Movement.SavedPos end
    end)
end

local function buildMisc()
    clearContent()
    makeToggle("隊伍檢測", "Misc_TeamCheck")
    makeToggle("反 AFK", "Misc_AntiAFK")
    makeToggle("聊天通知", "Misc_ChatNotify")
    makeToggle("進出通知", "Misc_JoinLeaveNotify")
    makeButton("切換主題", function()
        CONFIG.Misc.Theme = (CONFIG.Misc.Theme % #THEMES) + 1
        local t = getTheme()
        MainStroke.Color = t.Main
        Title.TextColor3 = t.Main
        Glow.BackgroundColor3 = t.Main
    end)
    makeButton("隱藏 GUI", function() ScreenGui.Enabled = false end)
    makeButton("儲存設定", function()
        safe(function() writefile("axiom_rivals.json", HttpService:JSONEncode(CONFIG)) end)
    end)
    makeButton("載入設定", function()
        safe(function()
            local data = readfile("axiom_rivals.json")
            local decoded = HttpService:JSONDecode(data)
            for k, v in pairs(decoded) do CONFIG[k] = v end
        end)
    end)
end

local function buildSystem()
    clearContent()
    makeButton("隱藏鍵: RightShift", function() end)
    makeButton("存檔 (writefile)", function()
        safe(function() writefile("axiom_rivals.json", HttpService:JSONEncode(CONFIG)) end)
    end)
    makeButton("讀檔 (readfile)", function()
        safe(function()
            local data = readfile("axiom_rivals.json")
            local decoded = HttpService:JSONDecode(data)
            for k, v in pairs(decoded) do CONFIG[k] = v end
        end)
    end)
    makeButton("錯誤防護: pcall 已啟用", function() end)
end

-- 建立分頁按鈕
local tabDefs = {
    { Name = "視覺", Build = buildVisual },
    { Name = "戰鬥", Build = buildCombat },
    { Name = "移動", Build = buildMovement },
    { Name = "其他", Build = buildMisc },
    { Name = "系統", Build = buildSystem },
}

for i, def in ipairs(tabDefs) do
    local btn = create("TextButton", {
        Size = UDim2.new(0, 88, 1, 0),
        BackgroundColor3 = i == 1 and getTheme().Main or Color3.fromRGB(30, 30, 40),
        Text = def.Name,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        Parent = TabBar,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })
    btn.MouseButton1Click:Connect(function()
        for _, b in ipairs(TabBar:GetChildren()) do
            if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(30, 30, 40) end
        end
        btn.BackgroundColor3 = getTheme().Main
        def.Build()
    end)
end

-- 預設顯示第一個分頁
buildVisual()

-- ═══════════════════════════════════════════
-- ESP 繪製
-- ═══════════════════════════════════════════
local ESPFolder = create("Folder", { Name = "AxiomESP", Parent = ScreenGui })

local function createESP(player)
    local box = create("Frame", {
        Name = player.Name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
        Parent = ESPFolder,
    })
    local stroke = create("UIStroke", { Color = Color3.fromRGB(0, 255, 255), Thickness = 1.5, Parent = box })
    local nameLbl = create("TextLabel", {
        Size = UDim2.new(0, 150, 0, 16),
        BackgroundTransparency = 1,
        Text = player.Name,
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        Parent = box,
    })
    local distLbl = create("TextLabel", {
        Size = UDim2.new(0, 150, 0, 14),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Color3.fromRGB(200, 200, 200),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        Parent = box,
    })
    local healthBar = create("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        Position = UDim2.new(-1, -6, 0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 255, 0),
        BorderSizePixel = 0,
        Parent = box,
    })
    local tracer = create("Frame", {
        BackgroundColor3 = Color3.fromRGB(0, 255, 255),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 1, 0, 1),
        Visible = false,
        Parent = ESPFolder,
    })
    return { Box = box, Stroke = stroke, Name = nameLbl, Dist = distLbl, Health = healthBar, Tracer = tracer }
end

local espCache = {}

RunService.RenderStepped:Connect(function()
    if not CONFIG.ESP_Enabled then
        for _, data in pairs(espCache) do
            data.Box.Visible = false
            data.Tracer.Visible = false
        end
        return
    end
    local theme = getTheme()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if hrp and humanoid then
                if CONFIG.Misc_TeamCheck and player.Team == LocalPlayer.Team then continue end
                local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                if dist <= CONFIG.ESP_MaxDistance then
                    local data = espCache[player] or createESP(player)
                    espCache[player] = data
                    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local scale = math.clamp(1000 / dist, 0.3, 3)
                        data.Box.Size = UDim2.new(0, 40 * scale, 0, 60 * scale)
                        data.Box.Position = UDim2.new(0, screenPos.X - 20 * scale, 0, screenPos.Y - 30 * scale)
                        data.Box.Visible = true
                        data.Name.Visible = CONFIG.ESP_Name
                        data.Dist.Visible = CONFIG.ESP_Distance
                        data.Dist.Text = string.format("%d studs", math.floor(dist))
                        data.Dist.Position = UDim2.new(0, 0, 1, 2)
                        data.Health.Visible = CONFIG.ESP_Health
                        data.Health.Size = UDim2.new(0, 3, humanoid.Health / humanoid.MaxHealth, 0)
                        data.Health.BackgroundColor3 = Color3.fromRGB(
                            math.floor(255 * (1 - humanoid.Health / humanoid.MaxHealth)),
                            math.floor(255 * (humanoid.Health / humanoid.MaxHealth)), 0)
                        data.Stroke.Color = CONFIG.ESP_ColorByDistance
                            and Color3.fromRGB(math.floor(255 * (dist / CONFIG.ESP_MaxDistance)), 255 - math.floor(255 * (dist / CONFIG.ESP_MaxDistance)), 100)
                            or theme.Main
                        if CONFIG.ESP_Tracer then
                            data.Tracer.Visible = true
                            local mousePos = UserInputService:GetMouseLocation()
                            local delta = Vector2.new(mousePos.X - screenPos.X, mousePos.Y - screenPos.Y)
                            data.Tracer.Size = UDim2.new(0, delta.Magnitude, 0, 1)
                            data.Tracer.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
                            data.Tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X))
                            data.Tracer.BackgroundColor3 = theme.Main
                        else
                            data.Tracer.Visible = false
                        end
                    else
                        data.Box.Visible = false
                        data.Tracer.Visible = false
                    end
                else
                    local data = espCache[player]
                    if data then data.Box.Visible = false; data.Tracer.Visible = false end
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════
-- 自瞄
-- ═══════════════════════════════════════════
local fovCircle = create("Frame", {
    Size = UDim2.new(0, 240, 0, 240),
    Position = UDim2.new(0.5, -120, 0.5, -120),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
    Parent = ScreenGui,
})
create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fovCircle })
local fovStroke = create("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Parent = fovCircle })

RunService.RenderStepped:Connect(function()
    if CONFIG.Combat_FOVShow and CONFIG.Combat_Aimbot then
        fovCircle.Visible = true
        fovCircle.Size = UDim2.new(0, CONFIG.Combat_FOVRadius * 2, 0, CONFIG.Combat_FOVRadius * 2)
        fovCircle.Position = UDim2.new(0.5, -CONFIG.Combat_FOVRadius, 0.5, -CONFIG.Combat_FOVRadius)
        fovStroke.Color = getTheme().Main
    else
        fovCircle.Visible = false
    end
end)

local function getClosestTarget()
    local closest, minDist = nil, CONFIG.Combat_FOVRadius
    local mousePos = UserInputService:GetMouseLocation()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if CONFIG.Misc_TeamCheck and player.Team == LocalPlayer.Team then continue end
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character
