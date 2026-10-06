-- Axiom RIVALS v7.0 // Silent Aim + Aimbot (Grief.cc 邏輯) + Obsidian GUI
-- ============================================================
-- 前置：載入 Obsidian Library
-- ============================================================
local ObsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local ok = pcall(function()
    loadstring(game:HttpGet(ObsidianRepo .. "Library.lua"))()
end)
if not ok then
    warn("[v7] Obsidian Library 載入失敗")
    return
end
local Library = getgenv().Library or getgenv().ObsidianLibrary
if not Library then
    warn("[v7] Library 為 nil，中止")
    return
end

-- ThemeManager / SaveManager（可選）
pcall(function()
    loadstring(game:HttpGet(ObsidianRepo .. "addons/ThemeManager.lua"))()
    loadstring(game:HttpGet(ObsidianRepo .. "addons/SaveManager.lua"))()
end)

local QuartzTheme = {
    FontColor="ffffff",MainColor="232330",AccentColor="426e87",
    BackgroundColor="1d1b26",OutlineColor="27232f",FontFace="Code",BackgroundImage=""
}
pcall(function()
    if getgenv().ThemeManager then
        ThemeManager:SetLibrary(Library)
        ThemeManager:SetDefaultTheme(QuartzTheme)
    end
end)

local Window = Library:CreateWindow({
    Title="AXIOM // RIVALS v7.0",
    Footer="Silent Aim + Aimbot | Obsidian",
    Center=true,AutoShow=true,NotifySide="Right",ShowCustomCursor=false
})

-- ============================================================
-- 服務與模組
-- ============================================================
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local W = game:GetService("Workspace")
local C = W.CurrentCamera
local LP = Players.LocalPlayer

local Modules = RS:WaitForChild("Modules",10)
local Utility, EnumLibrary
pcall(function() Utility = require(Modules:WaitForChild("Utility",5)) end)
pcall(function() EnumLibrary = require(Modules:WaitForChild("EnumLibrary",5)) end)

local PlayerScripts = LP:WaitForChild("PlayerScripts",10)
local Controllers = PlayerScripts and PlayerScripts:FindFirstChild("Controllers")
local FighterController, CameraController
pcall(function() FighterController = require(Controllers:WaitForChild("FighterController",5)) end)
pcall(function() CameraController = require(Controllers:WaitForChild("CameraController",5)) end)

local localFighter = FighterController and FighterController.LocalFighter
local Remotes = RS:FindFirstChild("Remotes")
local Replication = Remotes and Remotes:FindFirstChild("Replication")
local FighterRemote = Replication and Replication:FindFirstChild("Fighter")
local UseItem = FighterRemote and FighterRemote:FindFirstChild("UseItem")

print("[v7] Utility:",Utility~=nil,"| EnumLibrary:",EnumLibrary~=nil)
print("[v7] FighterController:",FighterController~=nil,"| CameraController:",CameraController~=nil)
print("[v7] UseItem:",UseItem~=nil)

-- ============================================================
-- 共用工具
-- ============================================================
local function worldToScreen(pos, cam)
    local c = cam or C
    if not c then return Vector2.new(0,0), false end
    local ok, v, on = pcall(function() return c:WorldToViewportPoint(pos) end)
    if not ok or not v then return Vector2.new(0,0), false end
    return Vector2.new(v.X, v.Y), on
end
local function screenCenter(cam)
    local c = cam or C
    if c then return Vector2.new(c.ViewportSize.X/2, c.ViewportSize.Y/2) end
    return Vector2.new(960, 540)
end
local function getHitPart(char, partName)
    if not char then return nil end
    local map = {
        ["Head"]="Head",["HumanoidRootPart"]="HumanoidRootPart",
        ["Torso"]="Torso",["UpperTorso"]="UpperTorso",["LowerTorso"]="LowerTorso",
        ["Left Arm"]="LeftUpperArm",["Right Arm"]="RightUpperArm",
        ["Left Leg"]="LeftUpperLeg",["Right Leg"]="RightUpperLeg",
        ["LeftFoot"]="LeftFoot",["RightFoot"]="RightFoot",
        ["Neck"]="Neck",
    }
    if partName=="Closest" then
        local camPos = C.CFrame.Position
        local camLook = C.CFrame.LookVector
        local best, bestD = nil, math.huge
        for _,p in pairs(char:GetChildren()) do
            if p:IsA("BasePart") then
                local d = 1 - camLook:Dot((p.Position-camPos).Unit)
                if d < bestD then bestD=d; best=p end
            end
        end
        return best or char:FindFirstChild("HumanoidRootPart")
    end
    if partName=="Random" then
        local list = {}
        for _,p in pairs(char:GetChildren()) do
            if p:IsA("BasePart") then table.insert(list, p) end
        end
        if #list > 0 then return list[math.random(1,#list)] end
    end
    local n = map[partName] or "Head"
    local p = char:FindFirstChild(n)
    if p and p:IsA("BasePart") then return p end
    return char:FindFirstChild("HumanoidRootPart")
end

-- ============================================================
-- 狀態
-- ============================================================
local State = {
    Silent = {
        Enabled=false, HitPart="Head", HitChance=100, FOV=150,
        AutoShoot=false, FollowMuzzle=false, KeyMode="Toggle",
        ShowFOV=false, FOVColor=Color3.fromRGB(0,240,200),
    },
    Aimbot = {
        Enabled=false, HitPart="Head", Smoothness=2, Curve="Linear",
        FOV=300, FollowMuzzle=false, WallCheck=false, KeyMode="Toggle",
        ShowFOV=false, FOVColor=Color3.fromRGB(255,0,140),
        lockedTarget=nil, smoothCF=nil,
    },
    ESP = {
        Enabled=true, Name=true, Distance=true, Health=true,
        Tracer=true, MaxDistance=2000,
    },
    Movement = {
        WalkSpeed=16, JumpPower=50, Noclip=false, BHop=false, InfJump=false,
    },
    Misc = {
        TeamCheck=true, AntiAFK=true, ChatNotify=true, JoinNotify=true,
        DeviceSpoofer=nil,
    },
}

-- ============================================================
-- 目標收集
-- ============================================================
local function getTeamSignature(char)
    if not char then return nil end
    local sh = char:FindFirstChild("Shirt")
    if sh and sh:IsA("Shirt") and sh.ShirtTemplate ~= "" then
        return sh.ShirtTemplate
    end
    local pa = char.Parent
    if pa then
        local n = pa.Name:lower()
        if n:find("terror") or n:find("counter") or n:find("team") then
            return pa.Name
        end
    end
    return nil
end
local function isEnemy(plr)
    if not plr or plr == LP then return false end
    if not State.Misc.TeamCheck then return true end
    local mc = getTeamSignature(LP.Character)
    local pc = getTeamSignature(plr.Character)
    if not mc or not pc then return true end
    return mc ~= pc
end
local function getEnemies()
    local out = {}
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and isEnemy(p) then
                table.insert(out, p)
            end
        end
    end
    return out
end

-- ============================================================
-- Silent Aim (Grief.cc 邏輯)
-- ============================================================
local silentLastFire = 0
local silentFireCD = 0.05
local function silentFOVCenter()
    if State.Silent.FollowMuzzle then
        local vm = W:FindFirstChild("ViewModels")
        if vm then
            local fp = vm:FindFirstChild("FirstPerson")
            if fp then
                for _,m in ipairs(fp:GetChildren()) do
                    local iv = m:FindFirstChild("ItemVisual")
                    if iv then
                        local b = iv:FindFirstChild("Body")
                        if b then
                            local bp = b:FindFirstChild("BodyPrimary")
                            if bp then
                                local mz = bp:FindFirstChild("_muzzle")
                                if mz and mz:IsA("Attachment") then
                                    local sp,on = worldToScreen(mz.WorldPosition)
                                    if on then return sp end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return screenCenter()
end
local function findSilentTarget()
    local center = silentFOVCenter()
    local best, bestD = nil, math.huge
    for _,p in ipairs(getEnemies()) do
        local part = getHitPart(p.Character, State.Silent.HitPart)
        if part then
            local sp, on = worldToScreen(part.Position)
            if on then
                local d = (sp - center).Magnitude
                if d <= State.Silent.FOV and d < bestD then
                    best, bestD = p, d
                end
            end
        end
    end
    return best
end
local function fireSilent()
    if not State.Silent.Enabled then return end
    if not UseItem or not Utility or not EnumLibrary then return end
    if not localFighter or not localFighter.EquippedItem then return end
    local now = tick()
    if now - silentLastFire < silentFireCD then return end
    if State.Silent.HitChance < 100 then
        if math.random(1,100) > State.Silent.HitChance then return end
    end
    local target = findSilentTarget()
    if not target then return end
    local part = getHitPart(target.Character, State.Silent.HitPart)
    if not part then return end
    local myChar = LP.Character
    local root = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local objId = localFighter.EquippedItem:Get("ObjectID")
    if not objId then return end
    silentLastFire = now
    local shootPos = root.Position
    local targetPos = part.Position
    local data = {
        [utf8.char(1)] = {
            [utf8.char(0)] = Utility:EncodeCFrame(CFrame.new(shootPos, targetPos)),
            [utf8.char(1)] = Utility:EncodeCFrame(CFrame.new(shootPos, targetPos)),
            [utf8.char(2)] = part,
            [utf8.char(3)] = Utility:EncodeCFrame(CFrame.new(0.43, 0.25, 0.42)),
        },
    }
    pcall(function()
        UseItem:FireServer(objId, EnumLibrary:ToEnum("StartShooting"), data, nil)
    end)
end

-- ============================================================
-- Aimbot (Grief.cc 邏輯，用 CameraController:MimicRotation)
-- ============================================================
local function getUnstretchedCameraCFrame(cam)
    if cam then
        return cam.CFrame
    end
    return CFrame.new()
end
local function getAimbotScreenPoint()
    if State.Aimbot.FollowMuzzle then
        return silentFOVCenter()
    end
    local loc = UIS:GetMouseLocation()
    return Vector2.new(loc.X, loc.Y)
end
local function closestToCursor()
    local best, bestD = nil, State.Aimbot.FOV
    local mp = getAimbotScreenPoint()
    if not mp then return nil end
    local cam = C
    for _,p in ipairs(getEnemies()) do
        local part = getHitPart(p.Character, State.Aimbot.HitPart)
        if part and part:IsDescendantOf(W) then
            local sp, on = worldToScreen(part.Position, cam)
            if on then
                local d = (sp - mp).Magnitude
                if d < bestD then
                    bestD = d
                    best = part
                end
            end
        end
    end
    return best
end
local function getAimbotLerpAlpha(dt)
    local sm = math.clamp(tonumber(State.Aimbot.Smoothness) or 2, 0.1, 10)
    local speed = 6 / sm
    local curve = State.Aimbot.Curve or "Linear"
    if curve == "Instant" then return 1 end
    if curve == "Expo" then return 1 - math.exp(-(4/sm) * dt) end
    if curve == "EaseIn" then local t=math.clamp(speed*dt,0,1); return t*t end
    if curve == "EaseOut" then local t=math.clamp(speed*dt,0,1); return 1-(1-t)*(1-t) end
    if curve == "EaseInOut" then
        local t=math.clamp(speed*dt,0,1)
        if t<0.5 then return 2*t*t end
        return 1-((-2*t+2)^2)/2
    end
    if curve == "Cubic" then local t=math.clamp(speed*dt,0,1); return t*t*t end
    return math.clamp(speed*dt, 0, 1)
end
local AIMBOT_BIND = "AxiomAimbotUpdate"
local aimbotBound = false
local function clearAimbotLock()
    State.Aimbot.lockedTarget = nil
    State.Aimbot.smoothCF = nil
end
local function stepAimbot(dt)
    dt = dt or (1/240)
    if not State.Aimbot.Enabled then
        clearAimbotLock()
        return
    end
    local cam = W.CurrentCamera
    if not cam then return end
    C = cam
    if not State.Aimbot.lockedTarget then
        State.Aimbot.lockedTarget = closestToCursor()
        State.Aimbot.smoothCF = getUnstretchedCameraCFrame(cam)
        if not State.Aimbot.lockedTarget then return end
    end
    if not State.Aimbot.lockedTarget.Parent or not State.Aimbot.lockedTarget:IsDescendantOf(W) then
        clearAimbotLock()
        return
    end
    if not CameraController then return end
    if not State.Aimbot.smoothCF then
        State.Aimbot.smoothCF = getUnstretchedCameraCFrame(cam)
    end
    local lookCF = CFrame.lookAt(cam.CFrame.Position, State.Aimbot.lockedTarget.Position)
    local alpha = getAimbotLerpAlpha(dt)
    State.Aimbot.smoothCF = State.Aimbot.smoothCF:Lerp(lookCF, alpha)
    if CameraController.MimicRotation then
        pcall(function()
            CameraController:MimicRotation(State.Aimbot.smoothCF)
        end)
    end
end
local function updateAimbot()
    if aimbotBound then
        pcall(function() RunService:UnbindFromRenderStep(AIMBOT_BIND) end)
        aimbotBound = false
    end
    if not State.Aimbot.Enabled then
        clearAimbotLock()
        return
    end
    local ok = pcall(function()
        RunService:UnbindFromRenderStep(AIMBOT_BIND)
        RunService:BindToRenderStep(AIMBOT_BIND, Enum.RenderPriority.Camera.Value + 1, stepAimbot)
    end)
    aimbotBound = ok
end

-- ============================================================
-- FOV 圈（Drawing）
-- ============================================================
local silentFOVDrawing = Drawing and Drawing.new("Circle") or nil
local aimbotFOVDrawing = Drawing and Drawing.new("Circle") or nil
if silentFOVDrawing then
    silentFOVDrawing.Thickness=2
    silentFOVDrawing.Filled=false
    silentFOVDrawing.Visible=false
end
if aimbotFOVDrawing then
    aimbotFOVDrawing.Thickness=2
    aimbotFOVDrawing.Filled=false
    aimbotFOVDrawing.Visible=false
end

-- ============================================================
-- ESP（簡化版）
-- ============================================================
local espGui = Instance.new("ScreenGui")
espGui.Name="AxiomESP_"..tostring(math.random(1,999999))
espGui.ResetOnSpawn=false
espGui.IgnoreGuiInset=true
espGui.DisplayOrder=2147483646
espGui.Parent = game:GetService("CoreGui")
local espCache = {}
local function buildESP(key)
    if espCache[key] then return espCache[key] end
    local holder=Instance.new("Frame")
    holder.Size=UDim2.fromOffset(0,0)
    holder.BackgroundTransparency=1
    holder.Visible=false
    holder.Parent=espGui
    local nameLbl=Instance.new("TextLabel")
    nameLbl.BackgroundTransparency=1
    nameLbl.TextColor3=Color3.fromRGB(255,255,255)
    nameLbl.TextSize=14
    nameLbl.Font=Enum.Font.Code
    nameLbl.TextStrokeTransparency=0
    nameLbl.Text=""
    nameLbl.Size=UDim2.fromOffset(220,18)
    nameLbl.Position=UDim2.new(0.5,-110,0,-22)
    nameLbl.TextXAlignment=Enum.TextXAlignment.Center
    nameLbl.Parent=holder
    local distLbl=Instance.new("TextLabel")
    distLbl.BackgroundTransparency=1
    distLbl.TextColor3=Color3.fromRGB(255,220,0)
    distLbl.TextSize=12
    distLbl.Font=Enum.Font.Code
    distLbl.TextStrokeTransparency=0
    distLbl.Text=""
    distLbl.Size=UDim2.fromOffset(220,16)
    distLbl.Position=UDim2.new(0.5,-110,1,2)
    distLbl.TextXAlignment=Enum.TextXAlignment.Center
    distLbl.Parent=holder
    local box=Instance.new("Frame")
    box.BackgroundTransparency=1
    box.BorderSizePixel=0
    box.Visible=false
    box.Parent=espGui
    local stroke=Instance.new("UIStroke")
    stroke.Color=Color3.fromRGB(0,240,200)
    stroke.Thickness=1.5
    stroke.Parent=box
    local hbBg=Instance.new("Frame")
    hbBg.BackgroundColor3=Color3.fromRGB(40,40,40)
    hbBg.BorderSizePixel=0
    hbBg.Size=UDim2.fromOffset(3,100)
    hbBg.Visible=false
    hbBg.Parent=holder
    local hbBar=Instance.new("Frame")
    hbBar.BackgroundColor3=Color3.fromRGB(0,255,100)
    hbBar.BorderSizePixel=0
    hbBar.Size=UDim2.new(1,0,1,0)
    hbBar.Parent=hbBg
    local d={holder=holder,name=nameLbl,dist=distLbl,box=box,stroke=stroke,hbBg=hbBg,hbBar=hbBar}
    espCache[key]=d
    return d
end
local function updateESP()
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local d = espCache[p.Character]
            if d and not State.ESP.Enabled then
                d.holder.Visible=false
                d.box.Visible=false
            end
        end
    end
    if not State.ESP.Enabled then return end
    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot or not C then return end
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and isEnemy(p) then
            local hum=p.Character:FindFirstChildOfClass("Humanoid")
            local root=p.Character:FindFirstChild("HumanoidRootPart")
            local head=p.Character:FindFirstChild("Head")
            if hum and hum.Health>0 and root and head then
                local dist=(root.Position-myRoot.Position).Magnitude
                if dist<=State.ESP.MaxDistance then
                    local d=espCache[p.Character] or buildESP(p.Character)
                    local rp=root.Position
                    local hp=head.Position
                    local rpV,rpOn=worldToScreen(rp)
                    local hpV,hpOn=worldToScreen(hp)
                    if rpOn and hpOn then
                        local hPx=math.abs(rpV.Y-hpV.Y)*2.2
                        if hPx<10 then hPx=10 end
                        local wPx=hPx*0.5
                        local cx=(rpV.X+hpV.X)/2
                        local cy=(rpV.Y+hpV.Y)/2
                        d.holder.Position=UDim2.fromOffset(math.floor(cx-wPx/2),math.floor(cy-hPx/2))
                        d.holder.Size=UDim2.fromOffset(math.floor(wPx),math.floor(hPx))
                        d.holder.Visible=true
                        d.name.Visible=State.ESP.Name
                        if State.ESP.Name then d.name.Text=p.Name end
                        d.dist.Visible=State.ESP.Distance
                        if State.ESP.Distance then d.dist.Text=string.format("[%d]",math.floor(dist)) end
                        d.box.Visible=true
                        d.box.Position=UDim2.fromOffset(math.floor(cx-wPx/2),math.floor(cy-hPx/2))
                        d.box.Size=UDim2.fromOffset(math.floor(wPx),math.floor(hPx))
                        if State.ESP.Health and hum.MaxHealth>0 then
                            local rt=math.clamp(hum.Health/hum.MaxHealth,0,1)
                            d.hbBg.Visible=true
                            d.hbBg.Size=UDim2.fromOffset(3,math.floor(hPx))
                            d.hbBg.Position=UDim2.new(0,-6,0,0)
                            d.hbBar.Size=UDim2.new(1,0,rt,0)
                            d.hbBar.Position=UDim2.new(0,0,1-rt,0)
                            d.hbBar.BackgroundColor3=Color3.fromHSV(rt*0.33,1,1)
                        else d.hbBg.Visible=false end
                    else
                        d.holder.Visible=false
                        d.box.Visible=false
                    end
                else
                    if espCache[p.Character] then
                        espCache[p.Character].holder.Visible=false
                        espCache[p.Character].box.Visible=false
                    end
                end
            end
        end
    end
end

-- ============================================================
-- 主迴圈
-- ============================================================
RunService.RenderStepped:Connect(function(dt)
    if not C then C = W.CurrentCamera end
    if not C then return end
    if silentFOVDrawing then
        if State.Silent.ShowFOV and State.Silent.Enabled then
            silentFOVDrawing.Position = silentFOVCenter()
            silentFOVDrawing.Radius = State.Silent.FOV
            silentFOVDrawing.Color = State.Silent.FOVColor
            silentFOVDrawing.Visible = true
        else
            silentFOVDrawing.Visible = false
        end
    end
    if aimbotFOVDrawing then
        if State.Aimbot.ShowFOV and State.Aimbot.Enabled then
            aimbotFOVDrawing.Position = screenCenter()
            aimbotFOVDrawing.Radius = State.Aimbot.FOV
            aimbotFOVDrawing.Color = State.Aimbot.FOVColor
            aimbotFOVDrawing.Visible = true
        else
            aimbotFOVDrawing.Visible = false
        end
    end
    pcall(updateESP)
    if State.Silent.Enabled then
        if State.Silent.AutoShoot or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            pcall(fireSilent)
        end
    end
    if State.Movement.Noclip and LP.Character then
        for _,v in ipairs(LP.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide=false end
        end
    end
    local myChar=LP.Character
    if myChar then
        local hum=myChar:FindFirstChildOfClass("Humanoid")
        if hum then
            if hum.WalkSpeed~=State.Movement.WalkSpeed then hum.WalkSpeed=State.Movement.WalkSpeed end
            if hum.UseJumpPower~=true then hum.UseJumpPower=true end
            if hum.JumpPower~=State.Movement.JumpPower then hum.JumpPower=State.Movement.JumpPower end
        end
        if State.Movement.BHop then
            local h=myChar:FindFirstChildOfClass("Humanoid")
            if h and h.FloorMaterial~=Enum.Material.Air then h.Jump=true end
        end
    end
end)

UIS.InputBegan:Connect(function(i,g)
    if g then return end
    if State.Movement.InfJump and i.KeyCode==Enum.KeyCode.Space then
        local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- 反 AFK
task.spawn(function()
    while true do
        task.wait(30)
        if State.Misc.AntiAFK and LP.Character then
            local h=LP.Character:FindFirstChildOfClass("Humanoid")
            if h then
                h:ChangeState(Enum.HumanoidStateType.Jumping)
                task.wait(0.1)
                h:ChangeState(Enum.HumanoidStateType.Landed)
            end
        end
    end
end)

-- 聊天 / 進出通知
local chatKW={"noob","ez","hack","cheat","report","kick","ban"}
local function onChatted(plr,msg)
    if not State.Misc.ChatNotify then return end
    local lower=msg:lower()
    for _,kw in ipairs(chatKW) do
        if lower:find(kw,1,true) then
            Library:Notify({Title=plr.Name,Description=msg,Time=4})
            break
        end
    end
end
Players.PlayerAdded:Connect(function(p)
    if State.Misc.JoinNotify then
        Library:Notify({Title="加入",Description=p.Name,Time=3})
    end
    p.Chatted:Connect(function(msg) onChatted(p,msg) end)
end)
Players.PlayerRemoving:Connect(function(p)
    if State.Misc.JoinNotify then
        Library:Notify({Title="離開",Description=p.Name,Time=3})
    end
end)
for _,p in ipairs(Players:GetPlayers()) do
    p.Chatted:Connect(function(msg) onChatted(p,msg) end)
end

-- ============================================================
-- UI 建構
-- ============================================================
local CombatTab = Window:AddTab("Combat", "swords")
local VisualsTab = Window:AddTab("Visuals", "eye")
local MovementTab = Window:AddTab("Movement", "person-standing")
local MiscTab = Window:AddTab("Misc", "circle-ellipsis")
local SettingsTab = Window:AddTab("Settings", "settings")

-- ---- Combat: Silent Aim ----
local silentGroup = CombatTab:AddLeftGroupbox("Silent Aim")
silentGroup:AddToggle("Silent_Enabled",{
    Text="Enable Silent Aim",Default=false,
    Callback=function(v) State.Silent.Enabled=v end
}):AddKeyPicker("Silent_Key",{
    Text="Silent Aim",Default="None",Mode="Toggle",NoUI=true,
    SyncToggleState=true,
    Callback=function(state) State.Silent.Enabled=state end
})
silentGroup:AddToggle("Silent_AutoShoot",{
    Text="Auto Shoot (按住左鍵)",Default=false,
    Callback=function(v) State.Silent.AutoShoot=v end
})
silentGroup:AddDropdown("Silent_HitPart",{
    Text="Hit Part",Default="Head",
    Values={"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso","Closest","Random"},
    Callback=function(v) State.Silent.HitPart=v end
})
silentGroup:AddSlider("Silent_FOV",{
    Text="FOV Radius",Default=150,Min=10,Max=800,Rounding=0,Compact=true,
    Callback=function(v) State.Silent.FOV=v end
})
silentGroup:AddSlider("Silent_HitChance",{
    Text="Hit Chance %",Default=100,Min=0,Max=100,Rounding=0,Compact=true,
    Callback=function(v) State.Silent.HitChance=v end
})
silentGroup:AddToggle("Silent_FollowMuzzle",{
    Text="Follow Muzzle",Default=false,
    Callback=function(v) State.Silent.FollowMuzzle=v end
})
silentGroup:AddToggle("Silent_ShowFOV",{
    Text="Show FOV Circle",Default=false,
    Callback=function(v) State.Silent.ShowFOV=v end
}):AddColorPicker("Silent_FOVColor",{
    Default=Color3.fromRGB(0,240,200),Title="FOV Color",
    Callback=function(v) State.Silent.FOVColor=v end
})

-- ---- Combat: Aimbot ----
local aimGroup = CombatTab:AddRightGroupbox("Aimbot")
aimGroup:AddToggle("Aimbot_Enabled",{
    Text="Enable Aimbot",Default=false,
    Callback=function(v)
        State.Aimbot.Enabled=v
        updateAimbot()
    end
}):AddKeyPicker("Aimbot_Key",{
    Text="Aimbot",Default="None",Mode="Toggle",NoUI=true,
    SyncToggleState=true,
    Callback=function(state)
        State.Aimbot.Enabled=state
        updateAimbot()
    end
})
aimGroup:AddDropdown("Aimbot_HitPart",{
    Text="Hit Part",Default="Head",
    Values={"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso"},
    Callback=function(v) State.Aimbot.HitPart=v end
})
aimGroup:AddSlider("Aimbot_Smoothness",{
    Text="Smoothness",Default=2,Min=0.1,Max=10,Rounding=2,Compact=true,
    Callback=function(v) State.Aimbot.Smoothness=math.clamp(v,0.1,10) end
})
aimGroup:AddDropdown("Aimbot_Curve",{
    Text="Aim Curve",Default="Linear",
    Values={"Linear","Expo","EaseIn","EaseOut","EaseInOut","Cubic","Instant"},
    Callback=function(v) State.Aimbot.Curve=v end
})
aimGroup:AddSlider("Aimbot_FOV",{
    Text="FOV Radius",Default=300,Min=10,Max=1000,Rounding=0,Compact=true,
    Callback=function(v) State.Aimbot.FOV=v end
})
aimGroup:AddToggle("Aimbot_WallCheck",{
    Text="Wall Check",Default=false,
    Callback=function(v) State.Aimbot.WallCheck=v end
})
aimGroup:AddToggle("Aimbot_FollowMuzzle",{
    Text="Follow Muzzle",Default=false,
    Callback=function(v) State.Aimbot.FollowMuzzle=v end
})
aimGroup:AddToggle("Aimbot_ShowFOV",{
    Text="Show FOV Circle",Default=false,
    Callback=function(v) State.Aimbot.ShowFOV=v end
}):AddColorPicker("Aimbot_FOVColor",{
    Default=Color3.fromRGB(255,0,140),Title="FOV Color",
    Callback=function(v) State.Aimbot.FOVColor=v end
})

-- ---- Visuals ----
local espGroup = VisualsTab:AddLeftGroupbox("ESP")
espGroup:AddToggle("ESP_Enabled",{Text="ESP 開關",Default=true,Callback=function(v) State.ESP.Enabled=v end})
espGroup:AddToggle("ESP_Name",{Text="名字",Default=true,Callback=function(v) State.ESP.Name=v end})
espGroup:AddToggle("ESP_Distance",{Text="距離",Default=true,Callback=function(v) State.ESP.Distance=v end})
espGroup:AddToggle("ESP_Health",{Text="血量",Default=true,Callback=function(v) State.ESP.Health=v end})
espGroup:AddSlider("ESP_MaxDist",{Text="最大距離",Default=2000,Min=100,Max=5000,Rounding=0,Compact=true,Callback=function(v) State.ESP.MaxDistance=v end})

-- ---- Movement ----
local moveGroup = MovementTab:AddLeftGroupbox("移動")
moveGroup:AddToggle("Move_Noclip",{Text="穿牆",Default=false,Callback=function(v) State.Movement.Noclip=v end})
moveGroup:AddToggle("Move_BHop",{Text="Bunny Hop",Default=false,Callback=function(v) State.Movement.BHop=v end})
moveGroup:AddToggle("Move_InfJump",{Text="無限跳躍",Default=false,Callback=function(v) State.Movement.InfJump=v end})
moveGroup:AddSlider("Move_WalkSpeed",{Text="移動速度",Default=16,Min=16,Max=200,Rounding=0,Compact=true,Callback=function(v) State.Movement.WalkSpeed=v end})
moveGroup:AddSlider("Move_JumpPower",{Text="跳躍力",Default=50,Min=50,Max=300,Rounding=0,Compact=true,Callback=function(v) State.Movement.JumpPower=v end})

-- ---- Misc ----
local miscGroup = MiscTab:AddLeftGroupbox("其他")
miscGroup:AddToggle("Misc_TeamCheck",{Text="隊伍檢測",Default=true,Callback=function(v) State.Misc.TeamCheck=v end})
miscGroup:AddToggle("Misc_AntiAFK",{Text="反 AFK",Default=true,Callback=function(v) State.Misc.AntiAFK=v end})
miscGroup:AddToggle("Misc_ChatNotify",{Text="聊天通知",Default=true,Callback=function(v) State.Misc.ChatNotify=v end})
miscGroup:AddToggle("Misc_JoinNotify",{Text="進出通知",Default=true,Callback=function(v) State.Misc.JoinNotify=v end})

-- ---- Settings ----
local setGroup = SettingsTab:AddLeftGroupbox("系統")
setGroup:AddButton({Text="卸載腳本",Func=function()
    if silentFOVDrawing then pcall(function() silentFOVDrawing:Remove() end) end
    if aimbotFOVDrawing then pcall(function() aimbotFOVDrawing:Remove() end) end
    pcall(function() RunService:UnbindFromRenderStep(AIMBOT_BIND) end)
    espGui:Destroy()
    Library:Unload()
end})

Library:Notify({Title="AXIOM v7.0",Description="Silent Aim + Aimbot 已載入",Time=4})
print("[Axiom v7.0] 載入完成")
