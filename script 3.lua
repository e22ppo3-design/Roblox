-- ============================================================
-- AXIOM RIVALS v8.0 // Grief.cc 功能 + 中文 GUI + ESP
-- ============================================================

-- ========== 反封號 ==========
local hookmetamethod = hookmetamethod
local getrawmetatable = getrawmetatable
local setreadonly = setreadonly
local checkcaller = checkcaller
local getnamecallmethod = getnamecallmethod
local getconnections = getconnections

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local W = game:GetService("Workspace")
local C = W.CurrentCamera
local LP = Players.LocalPlayer

if hookmetamethod and getrawmetatable and setreadonly then
    local mt = getrawmetatable(game)
    pcall(function() setreadonly(mt, false) end)
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" and self == LP then return end
        if method == "FireServer" or method == "InvokeServer" then
            local name = self.Name:lower()
            if name:find("exploit") or name:find("cheat") or name:find("detect") or name:find("ban") or
               name:find("flag") or name:find("validate") or name:find("integrity") or name:find("security") or
               name:find("anticheat") or name:find("ac_") then
                return
            end
        end
        return oldNamecall(self, ...)
    end)
    pcall(function() setreadonly(mt, true) end)
    print("[v8] Kick hook 已安裝")
end

task.spawn(function()
    local tags = {"anticheat","ac","detection","ban","kick","security","moderation"}
    local function procAC(o)
        pcall(function()
            if o:IsA("LocalScript") or o:IsA("ModuleScript") then
                local n = o.Name:lower()
                for _, t in ipairs(tags) do
                    if n:find(t) then
                        pcall(function() o.Disabled = true end)
                        break
                    end
                end
            end
        end)
    end
    for _, o in ipairs(game:GetDescendants()) do procAC(o) end
    game.DescendantAdded:Connect(procAC)
    print("[v8] 反作弊腳本掃描完成")
end)

RS.DescendantAdded:Connect(function(obj)
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        local n = obj.Name:lower()
        if n:find("exploit") or n:find("cheat") or n:find("detect") or n:find("ban") or
           n:find("flag") or n:find("validate") or n:find("anticheat") or n:find("ac_") then
            pcall(function() obj:Destroy() end)
        end
    end
end)

if getconnections and checkcaller then
    task.spawn(function()
        pcall(function()
            for _, c in ipairs(getconnections(LP.CharacterAdded)) do
                if not checkcaller() then c:Disable() end
            end
        end)
    end)
end

-- ========== 模組 ==========
local Modules = RS:WaitForChild("Modules", 10)
local Utility, EnumLibrary
pcall(function() Utility = require(Modules:WaitForChild("Utility", 5)) end)
pcall(function() EnumLibrary = require(Modules:WaitForChild("EnumLibrary", 5)) end)

local PlayerScripts = LP:WaitForChild("PlayerScripts", 10)
local Controllers = PlayerScripts and PlayerScripts:FindFirstChild("Controllers")
local FighterController, CameraController
pcall(function() FighterController = require(Controllers:WaitForChild("FighterController", 5)) end)
pcall(function() CameraController = require(Controllers:WaitForChild("CameraController", 5)) end)

local GunModule, MeleeModule, GameplayUtility
pcall(function() GunModule = require(PlayerScripts:WaitForChild("Modules", 8):WaitForChild("ItemTypes", 5):WaitForChild("Gun", 5)) end)
pcall(function() MeleeModule = require(PlayerScripts:WaitForChild("Modules", 8):WaitForChild("ItemTypes", 5):WaitForChild("Melee", 5)) end)
pcall(function() GameplayUtility = require(Modules:WaitForChild("GameplayUtility", 5)) end)

local localFighter = FighterController and FighterController.LocalFighter

local Remotes = RS:FindFirstChild("Remotes")
local Replication = Remotes and Remotes:FindFirstChild("Replication")
local FighterRemote = Replication and Replication:FindFirstChild("Fighter")
local UseItem = FighterRemote and FighterRemote:FindFirstChild("UseItem")
local SetControls = FighterRemote and FighterRemote:FindFirstChild("SetControls")

print("[v8] Utility:", Utility ~= nil, "| EnumLibrary:", EnumLibrary ~= nil)
print("[v8] Fighter:", FighterController ~= nil, "| Camera:", CameraController ~= nil)
print("[v8] Gun:", GunModule ~= nil, "| Melee:", MeleeModule ~= nil)
print("[v8] UseItem:", UseItem ~= nil, "| SetControls:", SetControls ~= nil)

-- ========== 設定 ==========
local S = {
    SilentEnabled = false, SilentHitPart = "Head", SilentHitChance = 100, SilentFOV = 150,
    SilentAutoShoot = false, SilentFollowMuzzle = false, SilentShowFOV = false,
    SilentFOVColor = Color3.fromRGB(0, 240, 200),
    BackshootEnabled = false,
    AimEnabled = false, AimHitPart = "Head", AimSmoothness = 2, AimCurve = "Linear",
    AimFOV = 300, AimFollowMuzzle = false, AimWallCheck = false,
    AimShowFOV = false, AimFOVColor = Color3.fromRGB(255, 0, 140),
    CrosshairEnabled = false, CrosshairColor = Color3.fromRGB(0, 200, 255),
    CrosshairGrad1 = Color3.fromRGB(0, 200, 255), CrosshairGrad2 = Color3.fromRGB(0, 153, 255),
    CrosshairGrad3 = Color3.fromRGB(0, 107, 255),
    CrosshairShowLines = true, CrosshairShowAmmo = false,
    CrosshairSpinSpeed = 150, CrosshairGradRotation = 0, CrosshairMode = "static",
    InfJump = false, JumpPower = 50, WalkSpeed = 16,
    FlyEnabled = false, FlySpeed = 50, Noclip = false,
    AntiKatana = false, NoCooldown = false, NoSpread = false, NoRecoil = false,
    MaxAccuracy = false, RapidAttack = false, NoMuzzleFlash = false,
    DeviceSpoof = false, DeviceType = "PC",
    ESPEnabled = true, ShowName = true, ShowDistance = true, ShowHealth = true,
    ShowTracer = true, ShowSkeleton = true,
    ShowChams = false, ChamsColor = Color3.fromRGB(255, 0, 120), ChamsTransparency = 0.5,
    MaxDistance = 2000, HueSpeed = 0.25,
    TeamCheck = true, HideKey = Enum.KeyCode.RightShift, GuiVisible = true,
    AntiAFK = true, Notify = true,
}

-- ========== 工具 ==========
local function worldToScreen(pos, cam)
    local c = cam or C
    if not c then return Vector2.new(0, 0), false end
    local ok, v, on = pcall(function() return c:WorldToViewportPoint(pos) end)
    if not ok or not v then return Vector2.new(0, 0), false end
    return Vector2.new(v.X, v.Y), on
end

local function screenCenter(cam)
    local c = cam or C
    if c then return Vector2.new(c.ViewportSize.X / 2, c.ViewportSize.Y / 2) end
    return Vector2.new(960, 540)
end

local function getHitPart(char, partName)
    if not char then return nil end
    local map = {
        ["Head"] = "Head", ["HumanoidRootPart"] = "HumanoidRootPart",
        ["Torso"] = "Torso", ["UpperTorso"] = "UpperTorso", ["LowerTorso"] = "LowerTorso",
        ["Left Arm"] = "LeftUpperArm", ["Right Arm"] = "RightUpperArm",
        ["Left Leg"] = "LeftUpperLeg", ["Right Leg"] = "RightUpperLeg",
        ["LeftFoot"] = "LeftFoot", ["RightFoot"] = "RightFoot",
    }
    if partName == "Closest" then
        local camPos = C.CFrame.Position
        local camLook = C.CFrame.LookVector
        local best, bestD = nil, math.huge
        for _, p in pairs(char:GetChildren()) do
            if p:IsA("BasePart") then
                local d = 1 - camLook:Dot((p.Position - camPos).Unit)
                if d < bestD then bestD = d; best = p end
            end
        end
        return best or char:FindFirstChild("HumanoidRootPart")
    end
    if partName == "Random" then
        local list = {}
        for _, p in pairs(char:GetChildren()) do
            if p:IsA("BasePart") then table.insert(list, p) end
        end
        if #list > 0 then return list[math.random(1, #list)] end
    end
    local n = map[partName] or "Head"
    local p = char:FindFirstChild(n)
    if p and p:IsA("BasePart") then return p end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getTeamSig(char)
    if not char then return nil end
    local sh = char:FindFirstChild("Shirt")
    if sh and sh:IsA("Shirt") and sh.ShirtTemplate ~= "" then return sh.ShirtTemplate end
    local pa = char.Parent
    if pa then
        local n = pa.Name:lower()
        if n:find("terror") or n:find("counter") or n:find("team") then return pa.Name end
    end
    return nil
end

local function isEnemy(plr)
    if not plr or plr == LP then return false end
    if not S.TeamCheck then return true end
    local mc = getTeamSig(LP.Character)
    local pc = getTeamSig(plr.Character)
    if not mc or not pc then return true end
    return mc ~= pc
end

local function getEnemies()
    local out = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and isEnemy(p) then table.insert(out, p) end
        end
    end
    return out
end

-- ========== Silent Aim ==========
local silentLastFire = 0
local silentFireCD = 0.05

local function muzzlePos()
    local vm = W:FindFirstChild("ViewModels")
    if not vm then return nil end
    local fp = vm:FindFirstChild("FirstPerson")
    if not fp then return nil end
    for _, model in pairs(fp:GetChildren()) do
        if model:IsA("Model") and model.Name:find("^" .. LP.Name) then
            local iv = model:FindFirstChild("ItemVisual")
            if iv then
                local b = iv:FindFirstChild("Body")
                if b then
                    local bp = b:FindFirstChild("BodyPrimary")
                    if bp then
                        local mz = bp:FindFirstChild("_muzzle")
                        if mz and mz:IsA("Attachment") then return mz.WorldPosition end
                    end
                end
            end
        end
    end
    return nil
end

local function silentFOVCenter()
    if S.SilentFollowMuzzle then
        local mp = muzzlePos()
        if mp then
            local sp, on = worldToScreen(mp)
            if on then return sp end
        end
    end
    return screenCenter()
end

local function findSilentTarget()
    local center = silentFOVCenter()
    local best, bestD = nil, math.huge
    for _, p in ipairs(getEnemies()) do
        local part = getHitPart(p.Character, S.SilentHitPart)
        if part then
            local sp, on = worldToScreen(part.Position)
            if on then
                local d = (sp - center).Magnitude
                if d <= S.SilentFOV and d < bestD then best, bestD = p, d end
            end
        end
    end
    return best
end

local function fireSilentAt(target)
    if not UseItem or not Utility or not EnumLibrary then return false end
    if not localFighter or not localFighter.EquippedItem then return false end
    local part = getHitPart(target.Character, S.SilentHitPart)
    if not part then return false end
    local myChar = LP.Character
    local root = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local objId = localFighter.EquippedItem:Get("ObjectID")
    if not objId then return false end
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
    return true
end

local function fireSilent()
    if not S.SilentEnabled then return end
    local now = tick()
    if now - silentLastFire < silentFireCD then return end
    if S.SilentHitChance < 100 then
        if math.random(1, 100) > S.SilentHitChance then return end
    end
    local target = findSilentTarget()
    if not target then return end
    if fireSilentAt(target) then silentLastFire = now end
end

-- ========== Backshoot ==========
local backshoot = { connection = nil, target = nil, origCFrame = nil }
local backshootCheckConn = nil

local function closestPlayerBS()
    local best, bestD = nil, math.huge
    local sc = screenCenter()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local pos, on = worldToScreen(root.Position)
                if on then
                    local d = (sc - Vector2.new(pos.X, pos.Y)).Magnitude
                    if d < bestD then best = p.Character; bestD = d end
                end
            end
        end
    end
    return best
end

local function backshootLoop()
    if backshoot.connection then backshoot.connection:Disconnect() end
    backshoot.connection = RunService.Heartbeat:Connect(function()
        local myChar = LP.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
        if not backshoot.target then return end
        local tr = backshoot.target:FindFirstChild("HumanoidRootPart")
        if not tr then return end
        local behind = tr.Position + (-tr.CFrame.LookVector * 5)
        myChar.HumanoidRootPart.CFrame = CFrame.new(behind, tr.Position)
    end)
end

local function stopBS()
    if backshoot.connection then backshoot.connection:Disconnect(); backshoot.connection = nil end
end

local function startBackshootMonitor()
    if backshootCheckConn then return end
    backshootCheckConn = RunService.Heartbeat:Connect(function()
        if not backshoot.target then
            if backshootCheckConn then backshootCheckConn:Disconnect(); backshootCheckConn = nil end
            return
        end
        local hum = backshoot.target:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then
            local myChar = LP.Character
            if myChar and myChar:FindFirstChild("HumanoidRootPart") and backshoot.origCFrame then
                myChar.HumanoidRootPart.CFrame = backshoot.origCFrame
            end
            backshoot.target = nil
            stopBS()
            if backshootCheckConn then backshootCheckConn:Disconnect(); backshootCheckConn = nil end
        end
    end)
end

local function toggleBackshoot()
    local mc = LP.Character
    if not mc or not mc:FindFirstChild("HumanoidRootPart") then return end
    if backshoot.target then
        if backshoot.origCFrame then mc.HumanoidRootPart.CFrame = backshoot.origCFrame end
        backshoot.target = nil
        stopBS()
        if backshootCheckConn then backshootCheckConn:Disconnect(); backshootCheckConn = nil end
    else
        backshoot.target = closestPlayerBS()
        if backshoot.target then
            backshoot.origCFrame = mc.HumanoidRootPart.CFrame
            if S.BackshootEnabled then backshootLoop() end
            startBackshootMonitor()
        end
    end
end

LP.CharacterRemoving:Connect(function()
    stopBS()
    backshoot.target = nil
    backshoot.origCFrame = nil
    if backshootCheckConn then backshootCheckConn:Disconnect(); backshootCheckConn = nil end
end)

-- ========== Aimbot ==========
local aimbot = { lockedTarget = nil, smoothCF = nil }

local function getAimbotScreenPoint()
    if S.AimFollowMuzzle then
        local mp = muzzlePos()
        if mp then
            local sp, on = worldToScreen(mp)
            if on then return sp end
        end
    end
    local loc = UIS:GetMouseLocation()
    return Vector2.new(loc.X, loc.Y)
end

local function closestToCursor()
    local best, bestD = nil, S.AimFOV
    local mp = getAimbotScreenPoint()
    if not mp then return nil end
    local cam = C
    for _, p in ipairs(getEnemies()) do
        local part = getHitPart(p.Character, S.AimHitPart)
        if part and part:IsDescendantOf(W) then
            local sp, on = worldToScreen(part.Position, cam)
            if on then
                local d = (sp - mp).Magnitude
                if d < bestD then bestD = d; best = part end
            end
        end
    end
    return best
end

local function getAimbotLerpAlpha(dt)
    local sm = math.clamp(tonumber(S.AimSmoothness) or 2, 0.1, 10)
    local speed = 6 / sm
    local curve = S.AimCurve or "Linear"
    if curve == "Instant" then return 1 end
    if curve == "Expo" then return 1 - math.exp(-(4 / sm) * dt) end
    if curve == "EaseIn" then local t = math.clamp(speed * dt, 0, 1); return t * t end
    if curve == "EaseOut" then local t = math.clamp(speed * dt, 0, 1); return 1 - (1 - t) * (1 - t) end
    if curve == "EaseInOut" then
        local t = math.clamp(speed * dt, 0, 1)
        if t < 0.5 then return 2 * t * t end
        return 1 - ((-2 * t + 2) ^ 2) / 2
    end
    if curve == "Cubic" then local t = math.clamp(speed * dt, 0, 1); return t * t * t end
    return math.clamp(speed * dt, 0, 1)
end

local AIMBOT_BIND = "AxiomAimbotUpdate"
local aimbotBound = false

local function clearAimbotLock()
    aimbot.lockedTarget = nil
    aimbot.smoothCF = nil
end

local function stepAimbot(dt)
    dt = dt or (1 / 240)
    if not S.AimEnabled then clearAimbotLock(); return end
    local cam = W.CurrentCamera
    if not cam then return end
    C = cam
    if not aimbot.lockedTarget then
        aimbot.lockedTarget = closestToCursor()
        aimbot.smoothCF = cam.CFrame
        if not aimbot.lockedTarget then return end
    end
    if not aimbot.lockedTarget.Parent or not aimbot.lockedTarget:IsDescendantOf(W) then
        clearAimbotLock(); return
    end
    if not CameraController then return end
    if not aimbot.smoothCF then aimbot.smoothCF = cam.CFrame end
    local lookCF = CFrame.lookAt(cam.CFrame.Position, aimbot.lockedTarget.Position)
    local alpha = getAimbotLerpAlpha(dt)
    aimbot.smoothCF = aimbot.smoothCF:Lerp(lookCF, alpha)
    if CameraController.MimicRotation then
        pcall(function() CameraController:MimicRotation(aimbot.smoothCF) end)
    end
end

local function updateAimbot()
    if aimbotBound then
        pcall(function() RunService:UnbindFromRenderStep(AIMBOT_BIND) end)
        aimbotBound = false
    end
    if not S.AimEnabled then clearAimbotLock(); return end
    local ok = pcall(function()
        RunService:UnbindFromRenderStep(AIMBOT_BIND)
        RunService:BindToRenderStep(AIMBOT_BIND, Enum.RenderPriority.Camera.Value + 1, stepAimbot)
    end)
    aimbotBound = ok
end

-- ========== Crosshair ==========
local crosshairLines = {}
for i = 1, 8 do crosshairLines[i] = Drawing.new("Line") end
local crosshairAngles = {0, 90, 180, 270}

local function crosshairSolve(a, r)
    local rad = math.rad(a)
    return Vector2.new(math.sin(rad) * r, math.cos(rad) * r)
end

local function updateCrosshair(t)
    if not S.CrosshairEnabled then
        for i = 1, 8 do crosshairLines[i].Visible = false end
        return
    end
    local pos
    if S.CrosshairMode == "follow muzzle" then
        local mp = muzzlePos()
        if mp then
            local sp, on = worldToScreen(mp)
            if on then pos = sp end
        end
    end
    if not pos then pos = screenCenter() end
    local spinangle = 0
    if S.CrosshairSpinSpeed > 0 then
        spinangle = -(t * S.CrosshairSpinSpeed) % 340
    end
    for i = 1, 4 do
        local basea = crosshairAngles[i] + spinangle
        local p1 = pos + crosshairSolve(basea, 11)
        local p2 = pos + crosshairSolve(basea, 21)
        local inl = crosshairLines[i + 4]
        inl.Visible = true
        inl.Color = S.CrosshairColor
        inl.From = p1
        inl.To = p2
        inl.Thickness = 1.5
        local out = crosshairLines[i]
        out.Visible = true
        out.Color = Color3.new(0, 0, 0)
        out.From = pos + crosshairSolve(basea, 10)
        out.To = pos + crosshairSolve(basea, 22)
        out.Thickness = 3
    end
end

-- ========== Movement ==========
local flyBP, flyBG = nil, nil
local flyActive = false

local function cleanupFly()
    if flyBP then flyBP:Destroy(); flyBP = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
end

local function updateFly()
    if not S.FlyEnabled then
        cleanupFly()
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
        return
    end
    if flyActive then return end
    flyActive = true
    task.spawn(function()
        while S.FlyEnabled do
            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(0.1) continue end
            if not flyBP then
                flyBP = Instance.new("BodyPosition")
                flyBP.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                flyBP.D = 1000
                flyBP.P = 10000
                flyBP.Position = hrp.Position
                flyBP.Parent = hrp
            end
            if not flyBG then
                flyBG = Instance.new("BodyGyro")
                flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
                flyBG.D = 400
                flyBG.P = 10000
                flyBG.CFrame = hrp.CFrame
                flyBG.Parent = hrp
            end
            local cam = W.CurrentCamera
            local look = cam.CFrame.LookVector
            local right = cam.CFrame.RightVector
            local move = Vector3.new()
            if UIS:IsKeyDown(Enum.KeyCode.W) then move += look end
            if UIS:IsKeyDown(Enum.KeyCode.S) then move -= look end
            if UIS:IsKeyDown(Enum.KeyCode.A) then move -= right end
            if UIS:IsKeyDown(Enum.KeyCode.D) then move += right end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0, 1, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0, 1, 0) end
            if move.Magnitude > 0 then move = move.Unit end
            flyBP.Position = hrp.Position + (move * S.FlySpeed * 0.016 * 10)
            flyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + look * Vector3.new(1, 0, 1))
            task.wait()
        end
        flyActive = false
        cleanupFly()
    end)
end

UIS.JumpRequest:Connect(function()
    if S.InfJump then
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

-- ========== Gun Mods ==========
if GunModule and GunModule.StartShooting then
    local origGunShoot = GunModule.StartShooting
    GunModule.StartShooting = function(self, p26, p27)
        local oldCD
        if S.NoCooldown then
            oldCD = self.Info.ShootCooldown
            self.Info.ShootCooldown = 0
        end
        local result = { origGunShoot(self, p26, p27) }
        if S.NoCooldown and oldCD then self.Info.ShootCooldown = oldCD end
        return unpack(result)
    end
    print("[v8] Gun NoCooldown hook 已安裝")
end

if GunModule and GunModule._Recoil then
    local origRecoil = GunModule._Recoil
    GunModule._Recoil = function(self, multiplier)
        if S.NoRecoil then return end
        return origRecoil(self, multiplier)
    end
    print("[v8] Gun NoRecoil hook 已安裝")
end

if GameplayUtility and GameplayUtility.GetSpread then
    local origSpread = GameplayUtility.GetSpread
    GameplayUtility.GetSpread = function(spread, aimMultiplier, isAiming, isCrouching, pelletIndex, totalPellets, consistent)
        if S.NoSpread or S.MaxAccuracy then return CFrame.new() end
        return origSpread(spread, aimMultiplier, isAiming, isCrouching, pelletIndex, totalPellets, consistent)
    end
    print("[v8] Gun NoSpread hook 已安裝")
end

if MeleeModule and MeleeModule.StartShooting then
    local origMeleeShoot = MeleeModule.StartShooting
    MeleeModule.StartShooting = function(self, p26, p27)
        local oldCD
        if S.RapidAttack then
            oldCD = self.Info.AttackCooldown
            self.Info.AttackCooldown = 0
        end
        local result = { origMeleeShoot(self, p26, p27) }
        if S.RapidAttack and oldCD then self.Info.AttackCooldown = oldCD end
        return unpack(result)
    end
    print("[v8] Melee RapidAttack hook 已安裝")
end

local muzzleFlashConn = nil
local function noMuzzleFlash()
    local vm = W:FindFirstChild("ViewModels")
    if not vm then return end
    local fp = vm:FindFirstChild("FirstPerson")
    if not fp then return end
    for _, model in pairs(fp:GetChildren()) do
        if model:IsA("Model") then
            local iv = model:FindFirstChild("ItemVisual")
            if iv then
                local b = iv:FindFirstChild("Body")
                if b then
                    local bp = b:FindFirstChild("BodyPrimary")
                    if bp then
                        local mz = bp:FindFirstChild("_muzzle")
                        if mz then
                            local sl = mz:FindFirstChild("SpotLight")
                            if sl then sl:Destroy() end
                            for _, child in pairs(mz:GetChildren()) do
                                if child:IsA("ParticleEmitter") and child.Name == "ParticleEmiter" then
                                    child:Destroy()
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function updateMuzzleFlash()
    if S.NoMuzzleFlash then
        noMuzzleFlash()
        if not muzzleFlashConn then
            muzzleFlashConn = RunService.RenderStepped:Connect(noMuzzleFlash)
        end
    else
        if muzzleFlashConn then muzzleFlashConn:Disconnect(); muzzleFlashConn = nil end
    end
end

-- ========== Device Spoof ==========
local DEVICE_CODES = {
    ["Mobile"] = "Touch", ["Console"] = "Gamepad",
    ["VR"] = "VR", ["PC"] = "MouseKeyboard",
}

local function applyDeviceSpoof()
    if not SetControls or not S.DeviceSpoof then return end
    local code = DEVICE_CODES[S.DeviceType] or "MouseKeyboard"
    pcall(function() SetControls:FireServer(code) end)
end

LP.CharacterAdded:Connect(function()
    task.wait(1)
    if S.DeviceSpoof then applyDeviceSpoof() end
end)

-- ========== ESP ==========
local espGui = Instance.new("ScreenGui")
espGui.Name = "AxiomESP_" .. tostring(math.random(1, 999999))
espGui.ResetOnSpawn = false
espGui.IgnoreGuiInset = true
espGui.DisplayOrder = 2147483646
espGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
espGui.Parent = game:GetService("CoreGui")

local espCache = {}
local espGuiSet = {}
local SKEL_BONES = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}

local function buildESP(key)
    if espCache[key] then return espCache[key] end
    local holder = Instance.new("Frame")
    holder.Size = UDim2.fromOffset(0, 0)
    holder.BackgroundTransparency = 1
    holder.Visible = false
    holder.BorderSizePixel = 0
    holder.Parent = espGui

    local nameLbl = Instance.new("TextLabel")
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLbl.TextSize = 14
    nameLbl.Font = Enum.Font.Code
    nameLbl.TextStrokeTransparency = 0
    nameLbl.Text = ""
    nameLbl.Size = UDim2.fromOffset(220, 18)
    nameLbl.Position = UDim2.new(0.5, -110, 0, -22)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Center
    nameLbl.Parent = holder

    local distLbl = Instance.new("TextLabel")
    distLbl.BackgroundTransparency = 1
    distLbl.TextColor3 = Color3.fromRGB(255, 220, 0)
    distLbl.TextSize = 12
    distLbl.Font = Enum.Font.Code
    distLbl.TextStrokeTransparency = 0
    distLbl.Text = ""
    distLbl.Size = UDim2.fromOffset(220, 16)
    distLbl.Position = UDim2.new(0.5, -110, 1, 2)
    distLbl.TextXAlignment = Enum.TextXAlignment.Center
    distLbl.Parent = holder

    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = espGui
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 240, 200)
    stroke.Thickness = 1.5
    stroke.Parent = box

    local corners = {}
    for i = 1, 4 do
        local c = Instance.new("Frame")
        c.Size = UDim2.fromOffset(10, 2)
        c.BackgroundColor3 = Color3.fromRGB(0, 240, 200)
        c.BorderSizePixel = 0
        c.ZIndex = 3
        c.Parent = box
        corners[i] = c
    end
    corners[1].Position = UDim2.new(0, 0, 0, 0)
    corners[2].Position = UDim2.new(1, -10, 0, 0)
    corners[3].Position = UDim2.new(0, 0, 1, -2)
    corners[4].Position = UDim2.new(1, -10, 1, -2)

    local hbBg = Instance.new("Frame")
    hbBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hbBg.BorderSizePixel = 0
    hbBg.Size = UDim2.fromOffset(3, 100)
    hbBg.Visible = false
    hbBg.Parent = holder
    local hbBar = Instance.new("Frame")
    hbBar.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    hbBar.BorderSizePixel = 0
    hbBar.Size = UDim2.new(1, 0, 1, 0)
    hbBar.Parent = hbBg

    local tracer = Instance.new("Frame")
    tracer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tracer.BorderSizePixel = 0
    tracer.Visible = false
    tracer.ZIndex = 0
    tracer.Parent = espGui

    local skelLines = {}
    for i = 1, #SKEL_BONES do
        local line = Instance.new("Frame")
        line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        line.BorderSizePixel = 0
        line.Visible = false
        line.ZIndex = 1
        line.Parent = espGui
        skelLines[i] = line
    end

    local d = {
        holder = holder, name = nameLbl, dist = distLbl, box = box, stroke = stroke,
        corners = corners, hbBg = hbBg, hbBar = hbBar, tracer = tracer, skel = skelLines,
    }
    espCache[key] = d
    return d
end

local function clESP(key)
    local d = espCache[key]
    if not d then return end
    for _, o in pairs(d) do
        if type(o) == "table" then
            for _, x in ipairs(o) do if x and x.Destroy then x:Destroy() end end
        elseif o and o.Destroy then o:Destroy() end
    end
    espCache[key] = nil
end

local function hdESP(d)
    if not d then return end
    d.holder.Visible = false
    d.box.Visible = false
    d.tracer.Visible = false
    d.hbBg.Visible = false
    for _, l in ipairs(d.skel) do l.Visible = false end
end

local function drawSkelLine(line, a, b, color)
    local ap, aon = worldToScreen(a)
    local bp, bon = worldToScreen(b)
    if not aon or not bon then line.Visible = false return end
    local av = Vector2.new(ap.X, ap.Y)
    local bv = Vector2.new(bp.X, bp.Y)
    local mid = (av + bv) / 2
    local len = (bv - av).Magnitude
    if len < 1 then line.Visible = false return end
    line.Visible = true
    line.BackgroundColor3 = color
    line.Size = UDim2.fromOffset(math.floor(len), 1)
    line.Position = UDim2.fromOffset(math.floor(mid.X - len / 2), math.floor(mid.Y))
    line.Rotation = math.deg(math.atan2(bv.Y - av.Y, bv.X - av.X))
end

local function updateESP()
    if not S.ESPEnabled then
        for k, d in pairs(espCache) do hdESP(d) end
        return
    end
    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot or not C then return end
    local targets = getEnemies()
    local alive = {}
    for _, p in ipairs(targets) do
        alive[p] = true
        local char = p.Character
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if hum and hum.Health > 0 and root and head then
            local dist = (root.Position - myRoot.Position).Magnitude
            if dist <= S.MaxDistance then
                local d = espCache[p] or buildESP(p)
                local rpV, rpOn = worldToScreen(root.Position)
                local hpV, hpOn = worldToScreen(head.Position)
                if rpOn and hpOn then
                    local hPx = math.abs(rpV.Y - hpV.Y) * 2.2
                    if hPx < 15 then hPx = 15 end
                    local wPx = hPx * 0.5
                    local cx = (rpV.X + hpV.X) / 2
                    local cy = (rpV.Y + hpV.Y) / 2
                    local co = Color3.fromHSV((tGlobal * S.HueSpeed + dist / 2000 * 0.3) % 1, 1, 1)

                    d.holder.Position = UDim2.fromOffset(math.floor(cx - wPx / 2), math.floor(cy - hPx / 2))
                    d.holder.Size = UDim2.fromOffset(math.floor(wPx), math.floor(hPx))
                    d.holder.Visible = true
                    d.holder.BackgroundTransparency = 1

                    d.name.Visible = S.ShowName
                    if S.ShowName then d.name.Text = p.Name end
                    d.dist.Visible = S.ShowDistance
                    if S.ShowDistance then d.dist.Text = string.format("[%d]", math.floor(dist)) end

                    d.box.Visible = true
                    d.box.Position = UDim2.fromOffset(math.floor(cx - wPx / 2), math.floor(cy - hPx / 2))
                    d.box.Size = UDim2.fromOffset(math.floor(wPx), math.floor(hPx))
                    d.stroke.Color = co
                    for _, c in ipairs(d.corners) do c.BackgroundColor3 = co end

                    if S.ShowHealth and hum.MaxHealth > 0 then
                        local rt = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        d.hbBg.Visible = true
                        d.hbBg.Size = UDim2.fromOffset(3, math.floor(hPx))
                        d.hbBg.Position = UDim2.new(0, -6, 0, 0)
                        d.hbBar.Size = UDim2.new(1, 0, rt, 0)
                        d.hbBar.Position = UDim2.new(0, 0, 1 - rt, 0)
                        d.hbBar.BackgroundColor3 = Color3.fromHSV(rt * 0.33, 1, 1)
                    else
                        d.hbBg.Visible = false
                    end

                    if S.ShowTracer then
                        local vp = C.ViewportSize.X
                        local vq = C.ViewportSize.Y
                        local from = Vector2.new(vp / 2, vq)
                        local to = Vector2.new(cx, cy + hPx / 2)
                        local mid = (from + to) / 2
                        local len = (to - from).Magnitude
                        local ang = math.deg(math.atan2(to.Y - from.Y, to.X - from.X))
                        d.tracer.Visible = true
                        d.tracer.BackgroundColor3 = co
                        d.tracer.Size = UDim2.fromOffset(math.floor(len), 1)
                        d.tracer.Position = UDim2.fromOffset(math.floor(mid.X - len / 2), math.floor(mid.Y))
                        d.tracer.Rotation = ang
                    else
                        d.tracer.Visible = false
                    end

                    if S.ShowSkeleton then
                        for i, pair in ipairs(SKEL_BONES) do
                            local a = char:FindFirstChild(pair[1])
                            local b = char:FindFirstChild(pair[2])
                            local ln = d.skel[i]
                            if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
                                drawSkelLine(ln, a.Position, b.Position, co)
                            else
                                ln.Visible = false
                            end
                        end
                    else
                        for _, l in ipairs(d.skel) do l.Visible = false end
                    end
                else
                    hdESP(d)
                end
            else
                if espCache[p] then hdESP(espCache[p]) end
            end
        else
            if espCache[p] then hdESP(espCache[p]) end
        end
    end
    for k, d in pairs(espCache) do
        if not alive[k] then clESP(k) end
    end
end

-- ========== GUI ==========
local K = {
    Bg = Color3.fromRGB(10, 10, 16), Row = Color3.fromRGB(20, 20, 32),
    Text = Color3.fromRGB(230, 230, 245), Dim = Color3.fromRGB(120, 120, 150),
    Danger = Color3.fromRGB(255, 70, 100),
}
local theme = { S = Color3.fromRGB(0, 240, 200), P = Color3.fromRGB(255, 0, 140) }

local function nw(c, p, pa)
    local o = Instance.new(c)
    for k, v in pairs(p) do o[k] = v end
    if pa then o.Parent = pa end
    return o
end
local function cr(p, r) return nw("UICorner", { CornerRadius = r or UDim.new(0, 8) }, p) end

local sc2 = nw("ScreenGui", { Name = "AxiomGUI_" .. tostring(math.random(1, 999999)), ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 2147483647 }, game:GetService("CoreGui"))
local PW = 260
local mn = nw("Frame", { Size = UDim2.fromOffset(PW, 640), Position = UDim2.new(0, 20, 0.05, 0), BackgroundColor3 = K.Bg, BackgroundTransparency = 0.05, BorderSizePixel = 0, ClipsDescendants = true, Active = true }, sc2)
cr(mn, UDim.new(0, 10))
nw("UIStroke", { Color = theme.S, Thickness = 1.5, Transparency = 0.3 }, mn)

local tb = nw("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = Color3.fromRGB(16, 16, 26), BorderSizePixel = 0, ZIndex = 5 }, mn)
cr(tb, UDim.new(0, 10))
nw("TextLabel", { Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = "AXIOM // RIVALS v8.0", TextColor3 = K.Text, TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7 }, tb)
local cp = nw("TextButton", { Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, -54, 0, 8), BackgroundColor3 = K.Row, Text = "—", TextColor3 = theme.S, Font = Enum.Font.GothamBold, TextSize = 13, BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 7 }, tb)
cr(cp, UDim.new(0, 5))
local cx = nw("TextButton", { Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, -28, 0, 8), BackgroundColor3 = Color3.fromRGB(50, 14, 24), Text = "×", TextColor3 = K.Danger, Font = Enum.Font.GothamBold, TextSize = 15, BorderSizePixel = 0, AutoButtonColor = false, ZIndex = 7 }, tb)
cr(cx, UDim.new(0, 5))

-- Tab 列
local tabBar = nw("Frame", { Size = UDim2.new(1, -16, 0, 32), Position = UDim2.new(0, 8, 0, 42), BackgroundColor3 = Color3.fromRGB(14, 14, 22), BorderSizePixel = 0, ZIndex = 5 }, mn)
cr(tabBar, UDim.new(0, 8))
local tabLayout = nw("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, tabBar)
nw("UIPadding", { PaddingLeft = UDim.new(0, 6) }, tabBar)

local tabContents = {}
local activeTab = 1
local TABS = {}

local contentWrap = nw("Frame", { Size = UDim2.new(1, -16, 1, -120), Position = UDim2.new(0, 8, 0, 80), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 3 }, mn)

local function makeTabContent(idx)
    local scroll = nw("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = theme.S, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = (idx == 1), ZIndex = 3 }, contentWrap)
    nw("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
    nw("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, scroll)
    tabContents[idx] = scroll
    return scroll
end

for i = 1, 6 do makeTabContent(i) end

local function makeTabButton(name, idx)
    local b = nw("TextButton", { Size = UDim2.fromOffset(38, 24), BackgroundColor3 = K.Row, BackgroundTransparency = 0.3, Text = name, TextColor3 = K.Dim, TextSize = 11, Font = Enum.Font.GothamBold, AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = idx, ZIndex = 6 }, tabBar)
    cr(b, UDim.new(0, 6))
    local bs = nw("UIStroke", { Color = theme.S, Thickness = 1, Transparency = 0.7 }, b)
    b.MouseButton1Click:Connect(function()
        activeTab = idx
        for i, t in ipairs(TABS) do
            local isA = (i == idx)
            t.b.BackgroundTransparency = isA and 0 or 0.3
            t.b.TextColor3 = isA and K.Text or K.Dim
            t.bs.Transparency = isA and 0.1 or 0.7
            tabContents[i].Visible = isA
        end
    end)
    TABS[idx] = { b = b, bs = bs }
end

for i, name in ipairs({"战斗", "视觉", "移动", "枪械", "系统", "其他"}) do
    makeTabButton(name, i)
end

local orderCounters = {1,1,1,1,1,1}
local function nextOrder(tab) orderCounters[tab] = orderCounters[tab] + 1 return orderCounters[tab] end

local function makeTitle(tab, text)
    local holder = nw("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = nextOrder(tab) }, tabContents[tab])
    local bar = nw("Frame", { Size = UDim2.fromOffset(3, 14), Position = UDim2.new(0, 4, 0.5, -7), BackgroundColor3 = theme.S, BorderSizePixel = 0, ZIndex = 2 }, holder)
    cr(bar, UDim.new(1, 0))
    nw("TextLabel", { Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = K.Text, TextSize = 12, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 }, holder)
end

local function makeToggle(tab, t, get, set)
    local holder = nw("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = nextOrder(tab) }, tabContents[tab])
    local b = nw("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = K.Row, BackgroundTransparency = 0.2, Text = "", AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 2 }, holder)
    cr(b, UDim.new(0, 7))
    nw("UIStroke", { Color = theme.S, Thickness = 1, Transparency = 0.7 }, b)
    local swBg = nw("Frame", { Size = UDim2.fromOffset(34, 16), Position = UDim2.new(1, -44, 0.5, -8), BackgroundColor3 = Color3.fromRGB(40, 40, 55), BorderSizePixel = 0, ZIndex = 3 }, b)
    cr(swBg, UDim.new(1, 0))
    local swKnob = nw("Frame", { Size = UDim2.fromOffset(12, 12), Position = UDim2.new(0, 2, 0.5, -6), BackgroundColor3 = K.Dim, BorderSizePixel = 0, ZIndex = 4 }, swBg)
    cr(swKnob, UDim.new(1, 0))
    nw("TextLabel", { Size = UDim2.new(1, -90, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = t, TextColor3 = K.Text, TextSize = 12, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 }, b)
    local state = get()
    local function refresh()
        swBg.BackgroundColor3 = state and theme.S or Color3.fromRGB(40, 40, 55)
        swKnob.Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        swKnob.BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or K.Dim
    end
    refresh()
    b.MouseButton1Click:Connect(function()
        state = not state
        set(state)
        refresh()
    end)
    return b
end

local function makeSlider(tab, t, mn2, mx, df, cb)
    local holder = nw("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = K.Row, BackgroundTransparency = 0.2, BorderSizePixel = 0, LayoutOrder = nextOrder(tab) }, tabContents[tab])
    cr(holder, UDim.new(0, 7))
    nw("UIStroke", { Color = theme.S, Thickness = 1, Transparency = 0.7 }, holder)
    nw("TextLabel", { Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 12, 0, 5), BackgroundTransparency = 1, Text = t, TextColor3 = K.Text, TextSize = 11, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left }, holder)
    local v = nw("TextLabel", { Size = UDim2.new(0, 60, 0, 14), Position = UDim2.new(1, -72, 0, 5), BackgroundTransparency = 1, Text = string.format("%.1f", df), TextColor3 = theme.S, TextSize = 11, Font = Enum.Font.Code, TextXAlignment = Enum.TextXAlignment.Right }, holder)
    local tr = nw("Frame", { Size = UDim2.new(1, -24, 0, 8), Position = UDim2.new(0, 12, 0, 28), BackgroundColor3 = Color3.fromRGB(38, 38, 54), BorderSizePixel = 0 }, holder)
    cr(tr, UDim.new(1, 0))
    local fl = nw("Frame", { Size = UDim2.new((df - mn2) / (mx - mn2), 0, 1, 0), BackgroundColor3 = theme.S, BorderSizePixel = 0 }, tr)
    cr(fl, UDim.new(1, 0))
    local kn = nw("Frame", { Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new((df - mn2) / (mx - mn2), 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, ZIndex = 3 }, tr)
    cr(kn, UDim.new(1, 0))
    nw("UIStroke", { Color = theme.S, Thickness = 1.5 }, kn)
    local dg = false
    local function sf(x)
        local rl = math.clamp((x - tr.AbsolutePosition.X) / tr.AbsoluteSize.X, 0, 1)
        local vv = mn2 + (mx - mn2) * rl
        fl.Size = UDim2.new(rl, 0, 1, 0)
        kn.Position = UDim2.new(rl, 0, 0.5, 0)
        v.Text = string.format("%.1f", vv)
        if cb then pcall(cb, vv) end
    end
    tr.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dg = true sf(i.Position.X) end end)
    UIS.InputChanged:Connect(function(i) if dg and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then sf(i.Position.X) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dg = false end end)
    return holder
end

local function makeDropdown(tab, t, options, default, cb)
    local card = nw("Frame", { Size = UDim2.new(1, 0, 0, 62), BackgroundColor3 = K.Row, BackgroundTransparency = 0.2, BorderSizePixel = 0, LayoutOrder = nextOrder(tab) }, tabContents[tab])
    cr(card, UDim.new(0, 7))
    nw("UIStroke", { Color = theme.S, Thickness = 1, Transparency = 0.7 }, card)
    nw("TextLabel", { Size = UDim2.new(1, -16, 0, 14), Position = UDim2.new(0, 12, 0, 5), BackgroundTransparency = 1, Text = t, TextColor3 = K.Text, TextSize = 11, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left }, card)
    local idx = 1
    for i, o in ipairs(options) do if o == default then idx = i break end end
    local btn = nw("TextButton", { Size = UDim2.new(1, -28, 0, 26), Position = UDim2.new(0, 14, 0, 28), BackgroundColor3 = Color3.fromRGB(30, 20, 52), Text = options[idx], TextColor3 = theme.S, TextSize = 11, Font = Enum.Font.Code, BorderSizePixel = 0, AutoButtonColor = false }, card)
    cr(btn, UDim.new(0, 6))
    nw("UIStroke", { Color = theme.S, Thickness = 1, Transparency = 0.5 }, btn)
    btn.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        btn.Text = options[idx]
        if cb then pcall(cb, options[idx]) end
    end)
    return btn
end

-- ========== 战斗 Tab ==========
makeTitle(1, "Silent Aim")
makeToggle(1, "Silent Aim 开关", function() return S.SilentEnabled end, function(v) S.SilentEnabled = v end)
makeToggle(1, "自动开火", function() return S.SilentAutoShoot end, function(v) S.SilentAutoShoot = v end)
makeDropdown(1, "命中部位", {"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso","Closest","Random"}, S.SilentHitPart, function(v) S.SilentHitPart = v end)
makeSlider(1, "FOV 半径", 10, 800, S.SilentFOV, function(v) S.SilentFOV = v end)
makeSlider(1, "命中率 %", 0, 100, S.SilentHitChance, function(v) S.SilentHitChance = v end)
makeToggle(1, "跟随枪口", function() return S.SilentFollowMuzzle end, function(v) S.SilentFollowMuzzle = v end)
makeToggle(1, "显示 FOV", function() return S.SilentShowFOV end, function(v) S.SilentShowFOV = v end)

makeTitle(1, "Aimbot")
makeToggle(1, "自瞄开关", function() return S.AimEnabled end, function(v) S.AimEnabled = v updateAimbot() end)
makeDropdown(1, "自瞄部位", {"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso"}, S.AimHitPart, function(v) S.AimHitPart = v end)
makeSlider(1, "平滑度", 0.1, 10, S.AimSmoothness, function(v) S.AimSmoothness = v end)
makeDropdown(1, "曲线", {"Linear","Expo","EaseIn","EaseOut","EaseInOut","Cubic","Instant"}, S.AimCurve, function(v) S.AimCurve = v end)
makeSlider(1, "自瞄 FOV", 10, 1000, S.AimFOV, function(v) S.AimFOV = v end)
makeToggle(1, "墙检", function() return S.AimWallCheck end, function(v) S.AimWallCheck = v end)
makeToggle(1, "跟随枪口", function() return S.AimFollowMuzzle end, function(v) S.AimFollowMuzzle = v end)
makeToggle(1, "显示 FOV", function() return S.AimShowFOV end, function(v) S.AimShowFOV = v end)

makeTitle(1, "Backshoot")
makeToggle(1, "Backshoot 开关", function() return S.BackshootEnabled end, function(v) S.BackshootEnabled = v end)
makeToggle(1, "执行 Backshoot", function() return backshoot.target ~= nil end, function(v) toggleBackshoot() end)

-- ========== 视觉 Tab ==========
makeTitle(2, "ESP")
makeToggle(2, "ESP 开关", function() return S.ESPEnabled end, function(v) S.ESPEnabled = v end)
makeToggle(2, "名字", function() return S.ShowName end, function(v) S.ShowName = v end)
makeToggle(2, "距离", function() return S.ShowDistance end, function(v) S.ShowDistance = v end)
makeToggle(2, "血量", function() return S.ShowHealth end, function(v) S.ShowHealth = v end)
makeToggle(2, "追踪线", function() return S.ShowTracer end, function(v) S.ShowTracer = v end)
makeToggle(2, "骨架", function() return S.ShowSkeleton end, function(v) S.ShowSkeleton = v end)
makeSlider(2, "最大距离", 100, 5000, S.MaxDistance, function(v) S.MaxDistance = v end)
makeSlider(2, "彩虹速度", 0, 2, S.HueSpeed, function(v) S.HueSpeed = v end)

makeTitle(2, "准心")
makeToggle(2, "准心开关", function() return S.CrosshairEnabled end, function(v) S.CrosshairEnabled = v end)
makeToggle(2, "准心线", function() return S.CrosshairShowLines end, function(v) S.CrosshairShowLines = v end)
makeToggle(2, "弹药显示", function() return S.CrosshairShowAmmo end, function(v) S.CrosshairShowAmmo = v end)
makeSlider(2, "旋转速度", 0, 340, S.CrosshairSpinSpeed, function(v) S.CrosshairSpinSpeed = v end)
makeSlider(2, "渐变旋转", 0, 360, S.CrosshairGradRotation, function(v) S.CrosshairGradRotation = v end)
makeDropdown(2, "准心模式", {"static","follow muzzle"}, S.CrosshairMode, function(v) S.CrosshairMode = v end)

-- ========== 移动 Tab ==========
makeTitle(3, "移动")
makeToggle(3, "无限跳", function() return S.InfJump end, function(v) S.InfJump = v end)
makeToggle(3, "穿墙", function() return S.Noclip end, function(v) S.Noclip = v end)
makeToggle(3, "飞行", function() return S.FlyEnabled end, function(v) S.FlyEnabled = v updateFly() end)
makeSlider(3, "移动速度", 16, 200, S.WalkSpeed, function(v) S.WalkSpeed = v end)
makeSlider(3, "跳跃力", 50, 300, S.JumpPower, function(v) S.JumpPower = v end)
makeSlider(3, "飞行速度", 16, 750, S.FlySpeed, function(v) S.FlySpeed = v end)

-- ========== 枪械 Tab ==========
makeTitle(4, "枪械修改")
makeToggle(4, "反武士刀", function() return S.AntiKatana end, function(v) S.AntiKatana = v end)
makeToggle(4, "无限射速", function() return S.NoCooldown end, function(v) S.NoCooldown = v end)
makeToggle(4, "无散射", function() return S.NoSpread end, function(v) S.NoSpread = v end)
makeToggle(4, "无后座", function() return S.NoRecoil end, function(v) S.NoRecoil = v end)
makeToggle(4, "最大精准", function() return S.MaxAccuracy end, function(v) S.MaxAccuracy = v end)
makeToggle(4, "快速攻击", function() return S.RapidAttack end, function(v) S.RapidAttack = v end)
makeToggle(4, "无枪口火光", function() return S.NoMuzzleFlash end, function(v) S.NoMuzzleFlash = v updateMuzzleFlash() end)

-- ========== 系统 Tab ==========
makeTitle(5, "装置伪装")
makeToggle(5, "启用伪装", function() return S.DeviceSpoof end, function(v) S.DeviceSpoof = v applyDeviceSpoof() end)
makeDropdown(5, "装置类型", {"PC","Console","Mobile","VR"}, S.DeviceType, function(v) S.DeviceType = v if S.DeviceSpoof then applyDeviceSpoof() end end)

-- ========== 其他 Tab ==========
makeTitle(6, "其他")
makeToggle(6, "队伍检测", function() return S.TeamCheck end, function(v) S.TeamCheck = v end)
makeToggle(6, "反 AFK", function() return S.AntiAFK end, function(v) S.AntiAFK = v end)
makeToggle(6, "隐藏 GUI", function() return not S.GuiVisible end, function(v) S.GuiVisible = not v mn.Visible = S.GuiVisible end)

-- 拖動
local drag = false
local dragStart, dragPos
tb.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = true
        dragStart, dragPos = i.Position, mn.Position
        i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then drag = false end end)
    end
end)
UIS.InputChanged:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dragStart
        mn.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + d.X, dragPos.Y.Scale, dragPos.Y.Offset + d.Y)
    end
end)

-- 收合
local collapsed = false
cp.MouseButton1Click:Connect(function()
    collapsed = not collapsed
    local tg = collapsed and UDim2.fromOffset(PW, 38) or UDim2.fromOffset(PW, 640)
    TweenService:Create(mn, TweenInfo.new(0.25, Enum.EasingStyle.Quart), { Size = tg }):Play()
    contentWrap.Visible = not collapsed
    tabBar.Visible = not collapsed
    cp.Text = collapsed and "+" or "—"
end)

cx.MouseButton1Click:Connect(function()
    pcall(function() RunService:UnbindFromRenderStep(AIMBOT_BIND) end)
    if espGui then espGui:Destroy() end
    if sc2 then sc2:Destroy() end
    for _, line in ipairs(crosshairLines) do pcall(function() line:Remove() end) end
    for k, _ in pairs(espCache) do clESP(k) end
    cleanupFly()
    if muzzleFlashConn then muzzleFlashConn:Disconnect() end
end)

-- ========== 主迴圈 ==========
local tGlobal = 0
RunService.RenderStepped:Connect(function(dt)
    tGlobal = tGlobal + dt
    if not C then C = W.CurrentCamera end
    if not C then return end

    if S.SilentEnabled then
        if S.SilentAutoShoot or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            pcall(fireSilent)
        end
    end

    updateCrosshair(tGlobal)
    pcall(updateESP)

    if S.Noclip and LP.Character then
        for _, v in ipairs(LP.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
        end
    end

    local myChar = LP.Character
    if myChar then
        local hum = myChar:FindFirstChildOfClass("Humanoid")
        if hum then
            if hum.WalkSpeed ~= S.WalkSpeed then hum.WalkSpeed = S.WalkSpeed end
            if hum.UseJumpPower ~= true then hum.UseJumpPower = true end
            if hum.JumpPower ~= S.JumpPower then hum.JumpPower = S.JumpPower end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(30)
        if S.AntiAFK and LP.Character then
            local h = LP.Character:FindFirstChildOfClass("Humanoid")
            if h then
                h:ChangeState(Enum.HumanoidStateType.Jumping)
                task.wait(0.1)
                h:ChangeState(Enum.HumanoidStateType.Landed)
            end
        end
    end
end)

UIS.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == S.HideKey then
        S.GuiVisible = not S.GuiVisible
        mn.Visible = S.GuiVisible
    end
end)

print("[v8] 完整載入完成")
