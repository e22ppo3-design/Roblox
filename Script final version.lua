-- ============================================================
-- AXIOM RIVALS v9.8 // Silent 360 + Ragebot 整合版
-- 基於 v9.7，移植 grief.cc 的狂暴機器人 / 虛空連發 / 自動索敵 / 虛空躲藏
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
    print("[v9.8] Kick hook 已安裝")
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

print("[v9.8] Utility:", Utility ~= nil, "| EnumLibrary:", EnumLibrary ~= nil)
print("[v9.8] Gun:", GunModule ~= nil, "| Melee:", MeleeModule ~= nil)
print("[v9.8] UseItem:", UseItem ~= nil, "| SetControls:", SetControls ~= nil)

-- ========== 設定 ==========
local S = {
    SilentEnabled = false, SilentHitPart = "Head", SilentHitChance = 100, SilentFOV = 150,
    SilentAutoShoot = false, SilentFollowMuzzle = false, SilentWallCheck = true,
    Silent360 = false,
    BackshootEnabled = false,
    AntiAimEnabled = false, AntiAimYaw = "jitter", AntiAimPitch = "jitter",
    AntiAimAngle = "none", AntiAimCustomAngle = 0,
    AntiAimMinSpeed = 10, AntiAimMaxSpeed = 20,
    AntiAimMinAngle = 30, AntiAimMaxAngle = 60,
    AntiAimRandomAngle = false,
    AimEnabled = false, AimHitPart = "Head", AimFOV = 300, AimWallCheck = false,
    MouseAim = true, MouseSens = 1.0, MouseDeadzone = 2,
    MouseMaxStep = 200, MouseSmooth = 0.5, AimStuckTime = 3,
    CrosshairEnabled = false, CrosshairColor = Color3.fromRGB(0, 200, 255),
    CrosshairShowLines = true, CrosshairSpinSpeed = 150, CrosshairMode = "static",
    InfJump = false, JumpPower = 50, WalkSpeed = 16,
    FlyEnabled = false, FlySpeed = 50, Noclip = false,
    AntiKatana = false, NoCooldown = false, NoSpread = false, NoRecoil = false,
    MaxAccuracy = false, RapidAttack = false, NoMuzzleFlash = false,
    DeviceSpoof = false, DeviceType = "PC",
    ESPEnabled = true, ShowName = true, ShowDistance = true, ShowHealth = true,
    ShowTracer = true, ShowSkeleton = true,
    MaxDistance = 2000, HueSpeed = 0.25,
    TeamCheck = true, HideKey = Enum.KeyCode.RightShift, GuiVisible = true,
    AntiAFK = true,

    -- Ragebot 新增
    RageEnabled       = false,
    RageAutoTarget    = false,
    RageAutoShoot     = true,
    RageHitPart       = "Head",
    RageShootAttempts = 1,
    RagePredict       = false,
    RagePredictMul    = 1.2,
    RageOrbitHeight   = 2,
    RageOrbitRadius   = 0,
    RageFireCD        = 0.05,
    VoidSpamEnabled   = false,
    VoidShootMin      = 1,
    VoidShootMax      = 1,
    VoidHideMin       = 1,
    VoidHideMax       = 1,
    VoidHideReload    = true,
}

local hasMouseMoveRel = type(mousemoverel) == "function"
print("[v9.8] mousemoverel 支援:", hasMouseMoveRel)

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

local function getHitPartName(char, partName)
    if not char then return nil end
    local map = {
        ["Head"] = "Head", ["HumanoidRootPart"] = "HumanoidRootPart",
        ["Torso"] = "Torso", ["UpperTorso"] = "UpperTorso", ["LowerTorso"] = "LowerTorso",
    }
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

local function getEnemiesForESP()
    local out = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then table.insert(out, p) end
        end
    end
    return out
end

-- ========== Silent Aim ==========
local silentLastFire = 0
local silentFireCD = 0.01

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
    if S.Silent360 then
        local best, bestD = nil, math.huge
        local myChar = LP.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end
        for _, p in ipairs(getEnemies()) do
            local part = getHitPartName(p.Character, S.SilentHitPart)
            if part then
                local d = (part.Position - myRoot.Position).Magnitude
                if d < bestD then best = p; bestD = d end
            end
        end
        return best
    end
    local center = silentFOVCenter()
    local best, bestD = nil, math.huge
    for _, p in ipairs(getEnemies()) do
        local part = getHitPartName(p.Character, S.SilentHitPart)
        if part then
            local sp, on = worldToScreen(part.Position)
            if on then
                local d = (sp - center).Magnitude
                if d <= S.SilentFOV and d < bestD then best = p; bestD = d end
            end
        end
    end
    return best
end

local function fireSilentAt(target)
    if not UseItem or not Utility or not EnumLibrary then return false end
    if not localFighter or not localFighter.EquippedItem then return false end
    local part = getHitPartName(target.Character, S.SilentHitPart)
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

local raySilent = RaycastParams.new()
raySilent.FilterType = Enum.RaycastFilterType.Blacklist

local function canHitSilentTarget(target)
    if not S.SilentWallCheck then return target ~= nil and target.Character ~= nil end
    if not target or not target.Character then return false end
    local part = getHitPartName(target.Character, S.SilentHitPart)
    if not part then return false end
    local myChar = LP.Character
    if not myChar then return false end
    local root = myChar:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    raySilent.FilterDescendantsInstances = {myChar, C, target.Character}
    local res = W:Raycast(root.Position, part.Position - root.Position, raySilent)
    if res and res.Instance then return res.Instance:IsDescendantOf(target.Character) end
    return true
end

local function silentAutoFireLoop()
    if not S.SilentEnabled or not S.SilentAutoShoot then return end
    local now = tick()
    if now - silentLastFire < silentFireCD then return end
    if S.SilentHitChance < 100 then
        if math.random(1, 100) > S.SilentHitChance then return end
    end
    local target = findSilentTarget()
    if not target then return end
    if not canHitSilentTarget(target) then return end
    if fireSilentAt(target) then silentLastFire = now end
end

task.spawn(function()
    while true do
        task.wait()
        if S.SilentEnabled and S.SilentAutoShoot then pcall(silentAutoFireLoop) end
    end
end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not S.SilentEnabled then return end
    if S.SilentAutoShoot then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local target = findSilentTarget()
        if target then pcall(fireSilentAt, target) end
    end
end)

-- ========== 狂暴機器人 / 虛空連發 / 自動索敵 / 虛空躲藏 ==========
local Rage = {
    target        = nil,
    targetPlayer  = nil,
    immune        = false,
    syncing       = false,
    syncConn      = nil,
    savedCFrame   = nil,
    orbitAngle    = 0,
    orbitSpeed    = 9000,
    serverPos     = nil,
    velocity      = Vector3.new(0,0,0),
    lastPos       = nil,
    lastTime      = 0,
    lastFire      = 0,
    voidPhase     = nil,
    voidLastSwitch = 0,
    voidDuration  = 0,
    lastAttackTick = 0,
}

local function rageValidChar(ch)
    if not ch or not ch.Parent then return false end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if not ch:FindFirstChild("HumanoidRootPart") then return false end
    local p = Players:GetPlayerFromCharacter(ch)
    if not p or p == LP then return false end
    if S.TeamCheck and not isEnemy(p) then return false end
    return true
end

local function rageNearest()
    local best, bestD = nil, math.huge
    local cursor = UIS:GetMouseLocation()
    local cv = Vector2.new(cursor.X, cursor.Y)
    for _, p in ipairs(getEnemies()) do
        local ch = p.Character
        if rageValidChar(ch) then
            local root = ch:FindFirstChild("HumanoidRootPart")
            if root then
                local sp, on = worldToScreen(root.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - cv).Magnitude
                    if d < bestD then best = ch; bestD = d end
                end
            end
        end
    end
    return best
end

local function rageUpdateVelocity()
    if not Rage.target or not S.RagePredict then
        Rage.velocity = Vector3.new(0,0,0)
        Rage.lastPos = nil
        return
    end
    local root = Rage.target:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local now = tick()
    local dt = now - Rage.lastTime
    if dt > 0 and dt < 0.1 then
        local cur = root.Position
        if Rage.lastPos then
            local inst = (cur - Rage.lastPos) / dt
            Rage.velocity = Rage.velocity:Lerp(inst, 0.6)
        end
        Rage.lastPos = cur
        Rage.lastTime = now
    end
end

local function ragePredictPos(part, origin)
    if not S.RagePredict or not part then
        return part and part.Position or Vector3.new()
    end
    local base = part.Position
    local dist = (base - origin).Magnitude
    local ping = 0
    pcall(function()
        ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
    end)
    local travel = dist / 3000
    local total = (travel + ping) * S.RagePredictMul
    return base + (Rage.velocity * total)
end

local VOID_COORD = 1e9
local function voidSnap(hrp)
    if not hrp then return end
    pcall(function()
        hrp.CFrame = CFrame.new(VOID_COORD, -VOID_COORD, VOID_COORD)
        hrp.AssemblyLinearVelocity = Vector3.new(VOID_COORD, VOID_COORD, VOID_COORD)
        hrp.AssemblyAngularVelocity = Vector3.new(VOID_COORD, VOID_COORD, VOID_COORD)
    end)
end

local function voidRestore(hrp)
    if not hrp or not Rage.savedCFrame then return end
    pcall(function()
        hrp.CFrame = Rage.savedCFrame
        hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
        hrp.AssemblyAngularVelocity = Vector3.new(0,0,0)
    end)
end

local function rageTickVoidSpam()
    if not S.VoidSpamEnabled then return end
    local now = tick()
    local elapsed = now - Rage.voidLastSwitch
    if Rage.voidPhase == "shoot" then
        if elapsed >= Rage.voidDuration then
            Rage.voidPhase = "hide"
            Rage.voidDuration = S.VoidHideMin + math.random() * (S.VoidHideMax - S.VoidHideMin)
            Rage.voidLastSwitch = now
        end
    elseif Rage.voidPhase == "hide" then
        if elapsed >= Rage.voidDuration then
            Rage.voidPhase = "shoot"
            Rage.voidDuration = S.VoidShootMin + math.random() * (S.VoidShootMax - S.VoidShootMin)
            Rage.voidLastSwitch = now
        end
    else
        Rage.voidPhase = "shoot"
        Rage.voidDuration = S.VoidShootMin + math.random() * (S.VoidShootMax - S.VoidShootMin)
        Rage.voidLastSwitch = now
    end
end

local function rageFire()
    if not UseItem or not Utility or not EnumLibrary then return end
    if not localFighter or not localFighter.EquippedItem then return end
    if not Rage.target or not rageValidChar(Rage.target) then return end
    if Rage.immune then return end
    local now = tick()
    if now - Rage.lastFire < S.RageFireCD then return end
    local part = getHitPartName(Rage.target, S.RageHitPart)
    if not part then return end
    local myChar = LP.Character
    local root = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local shootPos = Rage.serverPos or root.Position
    local targetPos = ragePredictPos(part, shootPos)
    local objId = localFighter.EquippedItem:Get("ObjectID")
    if not objId then return end
    local data = {
        [utf8.char(1)] = {
            [utf8.char(0)] = Utility:EncodeCFrame(CFrame.new(shootPos, targetPos)),
            [utf8.char(1)] = Utility:EncodeCFrame(CFrame.new(shootPos, targetPos)),
            [utf8.char(2)] = part,
            [utf8.char(3)] = Utility:EncodeCFrame(CFrame.new(0.43, 0.25, 0.42)),
        },
    }
    local attempts = math.clamp(math.floor(S.RageShootAttempts), 1, 3)
    for _ = 1, attempts do
        pcall(function()
            UseItem:FireServer(objId, EnumLibrary:ToEnum("StartShooting"), data, nil)
        end)
    end
    Rage.lastFire = now
    Rage.lastAttackTick = now
end

local function rageSetTarget(ch)
    if not ch then return end
    Rage.target = ch
    Rage.targetPlayer = Players:GetPlayerFromCharacter(ch)
    Rage.immune = false
    Rage.savedCFrame = nil
    Rage.lastPos = nil
    Rage.lastTime = tick()
end

local function rageClearTarget()
    if Rage.syncConn then Rage.syncConn:Disconnect(); Rage.syncConn = nil end
    Rage.syncing = false
    Rage.target = nil
    Rage.targetPlayer = nil
    Rage.immune = false
    Rage.serverPos = nil
    Rage.voidPhase = nil
    local myChar = LP.Character
    local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    voidRestore(hrp)
    Rage.savedCFrame = nil
end

local function rageStartSync()
    if Rage.syncing then return end
    Rage.syncing = true
    Rage.syncConn = RunService.Heartbeat:Connect(function(dt)
        if not S.RageEnabled then return end
        if not Rage.target or not rageValidChar(Rage.target) then
            rageClearTarget()
            return
        end
        if Rage.immune then return end

        local myChar = LP.Character
        local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        if not Rage.savedCFrame then
            Rage.savedCFrame = hrp.CFrame
        end

        if S.VoidSpamEnabled then
            rageTickVoidSpam()
            if Rage.voidPhase == "hide" then
                voidSnap(hrp)
                return
            end
        end

        if S.VoidHideReload and localFighter and localFighter.EquippedItem then
            local reloading = false
            pcall(function()
                local it = localFighter.EquippedItem
                for _, k in ipairs({"Reloading","IsReloading","IsReload"}) do
                    local v = it:Get(k)
                    if v == true or v == 1 then reloading = true break end
                end
            end)
            if reloading then
                voidSnap(hrp)
                return
            end
        end

        local root = Rage.target:FindFirstChild("HumanoidRootPart")
        if root then
            local base = root.Position + Vector3.new(0, S.RageOrbitHeight, 0)
            Rage.orbitAngle = Rage.orbitAngle + Rage.orbitSpeed * dt
            local offset = Vector3.new(
                math.cos(Rage.orbitAngle) * S.RageOrbitRadius,
                0,
                math.sin(Rage.orbitAngle) * S.RageOrbitRadius
            )
            Rage.serverPos = base + offset
            pcall(function()
                hrp.CFrame = CFrame.new(Rage.serverPos)
            end)
        end

        rageUpdateVelocity()

        if S.RageAutoShoot then
            rageFire()
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(0.2)
        if S.RageEnabled and S.RageAutoTarget and not Rage.immune then
            if not Rage.target or not rageValidChar(Rage.target) then
                local newT = rageNearest()
                if newT then
                    rageSetTarget(newT)
                    rageStartSync()
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not Rage.targetPlayer then return end
    local ch = Rage.targetPlayer.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    local immune = root and root:FindFirstChild("Attachment") ~= nil
    if immune and not Rage.immune then
        Rage.immune = true
    elseif not immune and Rage.immune then
        Rage.immune = false
        rageStartSync()
    end
end)

local function rageToggleKey()
    if S.RageEnabled and Rage.target then
        rageClearTarget()
    else
        local ch = rageNearest()
        if ch then rageSetTarget(ch); rageStartSync() end
    end
end

-- ========== 瞬移到敵後（Backshoot）==========
local backshoot = { connection = nil, target = nil, origCFrame = nil }
local backshootCheckConn = nil

local function closestPlayerBS()
    local best, bestD = nil, math.huge
    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    for _, p in ipairs(getEnemies()) do
        local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local d = (root.Position - myRoot.Position).Magnitude
            if d < bestD then best = p.Character; bestD = d end
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

local function releaseBackshoot()
    local mc = LP.Character
    if backshoot.target then
        if mc and mc:FindFirstChild("HumanoidRootPart") and backshoot.origCFrame then
            mc.HumanoidRootPart.CFrame = backshoot.origCFrame
        end
        backshoot.target = nil
        stopBS()
        if backshootCheckConn then backshootCheckConn:Disconnect(); backshootCheckConn = nil end
    end
end

LP.CharacterRemoving:Connect(function()
    releaseBackshoot()
end)

-- ========== 反瞄準（Anti-Aim）==========
local antiAimState = { frameCounter = 0, smoothYaw = 0, smoothPitch = 0 }

local function getRandomInRange(mn, mx)
    return mn + math.random() * (mx - mn)
end

local function calcAntiAimYaw()
    local yaw = 0
    local currentTime = tick()
    if S.AntiAimYaw == "jitter" then
        local minA = math.rad(S.AntiAimMinAngle)
        local maxA = math.rad(S.AntiAimMaxAngle)
        if S.AntiAimRandomAngle then
            yaw = getRandomInRange(-maxA, maxA)
        else
            yaw = math.random() > 0.5 and minA or -minA
        end
    elseif S.AntiAimYaw == "spinbot" then
        local speed = getRandomInRange(S.AntiAimMinSpeed / 10, S.AntiAimMaxSpeed / 10)
        yaw = (currentTime * speed) % (2 * math.pi)
    elseif S.AntiAimYaw == "random" then
        if antiAimState.frameCounter % 30 == 0 then
            yaw = getRandomInRange(-math.rad(S.AntiAimMaxAngle), math.rad(S.AntiAimMaxAngle))
        else
            yaw = antiAimState.smoothYaw
        end
        antiAimState.smoothYaw = yaw
    end
    return yaw
end

local function calcAntiAimPitch()
    local pitch = 0
    if S.AntiAimPitch == "jitter" then
        local minA = math.rad(S.AntiAimMinAngle)
        local maxA = math.rad(S.AntiAimMaxAngle)
        if S.AntiAimRandomAngle then
            pitch = getRandomInRange(-maxA, maxA)
        else
            pitch = math.random() > 0.5 and minA or -minA
        end
    elseif S.AntiAimPitch == "spinbot" then
        pitch = math.sin(tick() * (S.AntiAimMaxSpeed / 10)) * math.rad(S.AntiAimMaxAngle)
    elseif S.AntiAimPitch == "random" then
        if antiAimState.frameCounter % 20 == 0 then
            pitch = getRandomInRange(math.rad(-89), math.rad(89))
        else
            pitch = antiAimState.smoothPitch
        end
        antiAimState.smoothPitch = pitch
    end
    return pitch
end

local function calcAntiAimRoll()
    local roll = 0
    if S.AntiAimAngle == "tilt 45" then roll = math.rad(45)
    elseif S.AntiAimAngle == "tilt 90" then roll = math.rad(90)
    elseif S.AntiAimAngle == "upside down" then roll = math.rad(180)
    elseif S.AntiAimAngle == "custom" then roll = math.rad(S.AntiAimCustomAngle)
    end
    return roll
end

local antiAimConn = nil

local function stepAntiAim()
    if not S.AntiAimEnabled then return end
    local character = LP.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    antiAimState.frameCounter = antiAimState.frameCounter + 1
    local yaw = calcAntiAimYaw()
    local pitch = calcAntiAimPitch()
    local roll = calcAntiAimRoll()
    root.CFrame = root.CFrame * CFrame.Angles(pitch, yaw, roll)
end

local function updateAntiAim()
    if antiAimConn then antiAimConn:Disconnect(); antiAimConn = nil end
    if S.AntiAimEnabled then
        antiAimConn = RunService.Heartbeat:Connect(stepAntiAim)
    end
end

-- ========== 模擬滑鼠自瞄 ==========
local aimTarget = nil
local lastAimPos = nil
local lastAimTime = tick()

local function isAliveEntry(e)
    if not e or not e.model or not e.model.Parent then return false end
    local hum = e.model:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return false end
    return e.model:FindFirstChild("HumanoidRootPart") ~= nil
end

local function getAimPart(entry)
    if not entry or not entry.model or not entry.model.Parent then return nil, nil end
    local part = entry.model:FindFirstChild(S.AimHitPart)
    if part and part:IsA("BasePart") then return part, entry end
    local fb = {"Head","HumanoidRootPart","UpperTorso"}
    for _, n in ipairs(fb) do
        local p = entry.model:FindFirstChild(n)
        if p and p:IsA("BasePart") then return p, entry end
    end
    return entry.model:FindFirstChild("HumanoidRootPart"), entry
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist

local function hasLOS(part, targetModel)
    if not S.AimWallCheck then return true end
    if not part or not C then return false end
    rayParams.FilterDescendantsInstances = {LP.Character, C, targetModel}
    local res = W:Raycast(C.CFrame.Position, part.Position - C.CFrame.Position, rayParams)
    if res and res.Instance then return res.Instance:IsDescendantOf(targetModel) end
    return true
end

local function findNearestInFOV()
    local best, bestDist = nil, math.huge
    local vp = C.ViewportSize.X
    local vq = C.ViewportSize.Y
    local cx, cy = vp/2, vq/2
    for _, p in ipairs(getEnemies()) do
        local e = {model = p.Character, player = p}
        local part = getAimPart(e)
        if part then
            local sp, on = worldToScreen(part.Position)
            if on then
                local dx, dy = sp.X - cx, sp.Y - cy
                local d = math.sqrt(dx*dx + dy*dy)
                if d <= S.AimFOV and d < bestDist and hasLOS(part, e.model) then
                    best, bestDist = e, d
                end
            end
        end
    end
    return best
end

local function findNearestAny()
    local best, bestDist = nil, math.huge
    local camPos = C.CFrame.Position
    for _, p in ipairs(getEnemies()) do
        local e = {model = p.Character, player = p}
        local part = getAimPart(e)
        if part then
            local d = (part.Position - camPos).Magnitude
            if d < bestDist and hasLOS(part, e.model) then
                best, bestDist = e, d
            end
        end
    end
    return best
end

local AIMBOT_BIND = "AxiomMouseAim"
RunService:BindToRenderStep(AIMBOT_BIND, 201, function(dt)
    if not S.AimEnabled then return end
    if not S.MouseAim then return end
    if not hasMouseMoveRel then return end
    if not aimTarget or not isAliveEntry(aimTarget) then return end
    local part = getAimPart(aimTarget)
    if not part then return end
    local sp, on = worldToScreen(part.Position)
    if not on then return end
    local vp = C.ViewportSize.X
    local vq = C.ViewportSize.Y
    local cx, cy = vp/2, vq/2
    local dx = sp.X - cx
    local dy = sp.Y - cy
    if math.abs(dx) < S.MouseDeadzone and math.abs(dy) < S.MouseDeadzone then return end
    dx = dx * (1 - S.MouseSmooth) * S.MouseSens
    dy = dy * (1 - S.MouseSmooth) * S.MouseSens
    local mag = math.sqrt(dx*dx + dy*dy)
    if mag > S.MouseMaxStep then
        dx = dx / mag * S.MouseMaxStep
        dy = dy / mag * S.MouseMaxStep
    end
    mousemoverel(dx, dy)
end)

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

-- ========== 移動 ==========
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

-- ========== 槍枝修改 ==========
if GunModule and GunModule.StartShooting then
    local origGunShoot = GunModule.StartShooting
    GunModule.StartShooting = function(self, p26, p27)
        local oldCD, oldSpread, oldAcc, oldRecoil, oldConsistent
        if S.NoCooldown then
            oldCD = self.Info.ShootCooldown
            self.Info.ShootCooldown = 0
        end
        if S.NoSpread or S.MaxAccuracy then
            oldSpread = self.Info.ShootSpread
            oldAcc = self.Info.ShootAccuracy
            oldConsistent = self.Info.ShootSpreadConsistent
            self.Info.ShootSpread = 0
            self.Info.ShootAccuracy = 1
            self.Info.ShootSpreadConsistent = true
        end
        if S.NoRecoil then
            oldRecoil = self.Info.ShootRecoil
            self.Info.ShootRecoil = 0
        end
        local result = { origGunShoot(self, p26, p27) }
        if oldCD then self.Info.ShootCooldown = oldCD end
        if oldSpread then self.Info.ShootSpread = oldSpread end
        if oldAcc then self.Info.ShootAccuracy = oldAcc end
        if oldConsistent then self.Info.ShootSpreadConsistent = oldConsistent end
        if oldRecoil then self.Info.ShootRecoil = oldRecoil end
        return unpack(result)
    end
    print("[v9.8] Gun 無散射 / 無後座 / 無冷卻 hook 已安裝")
end

if GameplayUtility and GameplayUtility.GetSpread then
    local origSpread = GameplayUtility.GetSpread
    GameplayUtility.GetSpread = function(self, aimMultiplier, isAiming, isCrouching, pelletIndex, totalPellets, consistent)
        if S.NoSpread or S.MaxAccuracy then
            return CFrame.new()
        end
        return origSpread(self, aimMultiplier, isAiming, isCrouching, pelletIndex, totalPellets, consistent)
    end
    print("[v9.8] Gun GetSpread hook 已安裝")
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
    print("[v9.8] Melee RapidAttack hook 已安裝")
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

-- ========== 裝置偽裝 ==========
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

local tGlobal = 0

local function updateESP()
    if not S.ESPEnabled then
        for k, d in pairs(espCache) do hdESP(d) end
        return
    end
    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot or not C then return end
    local targets = getEnemiesForESP()
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

-- ========== Obsidian GUI ==========
local ObsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local ok = pcall(function()
    loadstring(game:HttpGet(ObsidianRepo .. "Library.lua"))()
end)
if not ok then
    warn("[v9.8] Obsidian 載入失敗")
    return
end
local Library = getgenv().Library or getgenv().ObsidianLibrary
if not Library then return end

pcall(function()
    loadstring(game:HttpGet(ObsidianRepo .. "addons/ThemeManager.lua"))()
    loadstring(game:HttpGet(ObsidianRepo .. "addons/SaveManager.lua"))()
end)
pcall(function()
    if getgenv().ThemeManager then
        ThemeManager:SetLibrary(Library)
        ThemeManager:SetDefaultTheme({
            FontColor = "ffffff", MainColor = "232330", AccentColor = "426e87",
            BackgroundColor = "1d1b26", OutlineColor = "27232f", FontFace = "Code", BackgroundImage = ""
        })
    end
end)

local Window = Library:CreateWindow({
    Title = "AXIOM // RIVALS v9.8",
    Footer = "Silent 360 + Ragebot | Obsidian GUI",
    Center = true, AutoShow = true, NotifySide = "Right", ShowCustomCursor = false
})

local CombatTab = Window:AddTab("Combat", "swords")
local VisualsTab = Window:AddTab("Visuals", "eye")
local MovementTab = Window:AddTab("Movement", "person-standing")
local GunTab = Window:AddTab("Gun", "crosshair")
local MiscTab = Window:AddTab("Misc", "circle-ellipsis")

-- ========== Combat: Silent Aim ==========
local silentGroup = CombatTab:AddLeftGroupbox("Silent Aim")
silentGroup:AddToggle("Silent_Enabled", {
    Text = "Enable Silent Aim", Default = false,
    Callback = function(v) S.SilentEnabled = v end
}):AddKeyPicker("Silent_Key", {
    Text = "Silent Aim", Default = "None", Mode = "Toggle", NoUI = true,
    SyncToggleState = true, Callback = function(state) S.SilentEnabled = state end
})
silentGroup:AddToggle("Silent_AutoShoot", { Text = "Auto Shoot (能打到才開)", Default = false, Callback = function(v) S.SilentAutoShoot = v end })
silentGroup:AddToggle("Silent_WallCheck", { Text = "牆壁檢測（不穿牆開槍）", Default = true, Callback = function(v) S.SilentWallCheck = v end })
silentGroup:AddToggle("Silent_360", { Text = "360 度模式（背後也打）", Default = false, Callback = function(v) S.Silent360 = v end })
silentGroup:AddDropdown("Silent_HitPart", {
    Text = "Hit Part", Default = "Head",
    Values = {"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso"},
    Callback = function(v) S.SilentHitPart = v end
})
silentGroup:AddSlider("Silent_FOV", { Text = "FOV Radius", Default = 150, Min = 10, Max = 800, Rounding = 0, Compact = true, Callback = function(v) S.SilentFOV = v end })
silentGroup:AddSlider("Silent_HitChance", { Text = "Hit Chance %", Default = 100, Min = 0, Max = 100, Rounding = 0, Compact = true, Callback = function(v) S.SilentHitChance = v end })
silentGroup:AddToggle("Silent_FollowMuzzle", { Text = "Follow Muzzle", Default = false, Callback = function(v) S.SilentFollowMuzzle = v end })

-- ========== Combat: Ragebot ==========
local rageGroup = CombatTab:AddLeftGroupbox("狂暴機器人 (Ragebot)")
rageGroup:AddToggle("Rage_Enabled", {
    Text = "啟用狂暴機器人", Default = false,
    Callback = function(v)
        S.RageEnabled = v
        if not v then rageClearTarget() end
    end
}):AddKeyPicker("Rage_Key", {
    Text = "Ragebot", Default = "None", Mode = "Toggle", NoUI = true,
    SyncToggleState = true, Callback = function(state)
        S.RageEnabled = state
        if not state then rageClearTarget() end
    end
})
rageGroup:AddToggle("Rage_AutoTarget", { Text = "自動索敵", Default = false, Callback = function(v) S.RageAutoTarget = v end })
rageGroup:AddToggle("Rage_AutoShoot", { Text = "自動開火", Default = true, Callback = function(v) S.RageAutoShoot = v end })
rageGroup:AddToggle("Rage_Predict", { Text = "預測", Default = false, Callback = function(v) S.RagePredict = v end })
rageGroup:AddSlider("Rage_PredictMul", { Text = "預測倍率", Default = 1.2, Min = 0.1, Max = 3.0, Rounding = 1, Compact = true, Callback = function(v) S.RagePredictMul = v end })
rageGroup:AddDropdown("Rage_HitPart", {
    Text = "命中部位", Default = "Head",
    Values = {"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso"},
    Callback = function(v) S.RageHitPart = v end
})
rageGroup:AddSlider("Rage_Attempts", { Text = "開火次數", Default = 1, Min = 1, Max = 3, Rounding = 0, Compact = true, Callback = function(v) S.RageShootAttempts = v end })
rageGroup:AddSlider("Rage_OrbitH", { Text = "環繞高度", Default = 2, Min = -10, Max = 15, Rounding = 1, Compact = true, Callback = function(v) S.RageOrbitHeight = v end })
rageGroup:AddSlider("Rage_OrbitR", { Text = "環繞半徑", Default = 0, Min = 0, Max = 15, Rounding = 1, Compact = true, Callback = function(v) S.RageOrbitRadius = v end })
rageGroup:AddSlider("Rage_FireCD", { Text = "開火冷卻", Default = 0.05, Min = 0.01, Max = 0.5, Rounding = 2, Compact = true, Callback = function(v) S.RageFireCD = v end })
rageGroup:AddButton({
    Text = "手動鎖定最近敵人",
    Func = function()
        local ch = rageNearest()
        if ch then rageSetTarget(ch); rageStartSync() end
    end
})
rageGroup:AddButton({
    Text = "解除鎖定",
    Func = function() rageClearTarget() end
})

-- ========== Combat: Void Spam ==========
local voidGroup = CombatTab:AddLeftGroupbox("虛空連發 (Void Spam)")
voidGroup:AddToggle("Void_Enabled", { Text = "啟用虛空連發", Default = false, Callback = function(v)
    S.VoidSpamEnabled = v
    if not v then Rage.voidPhase = nil end
end })
voidGroup:AddSlider("Void_ShootMin", { Text = "攻擊時間", Default = 1, Min = 0.1, Max = 2, Rounding = 1, Compact = true, Callback = function(v) S.VoidShootMin = v; S.VoidShootMax = v end })
voidGroup:AddSlider("Void_HideMin", { Text = "躲藏時間", Default = 1, Min = 0.1, Max = 2, Rounding = 1, Compact = true, Callback = function(v) S.VoidHideMin = v; S.VoidHideMax = v end })
voidGroup:AddToggle("Void_HideReload", { Text = "換彈時躲藏", Default = true, Callback = function(v) S.VoidHideReload = v end })

-- ========== Combat: Backshoot ==========
local backGroup = CombatTab:AddRightGroupbox("瞬移敵後（Backshoot）")
backGroup:AddToggle("Backshoot_Enabled", {
    Text = "啟用瞬移", Default = false,
    Callback = function(v) S.BackshootEnabled = v end
})
backGroup:AddButton({
    Text = "瞬移到最近敵人身後",
    Func = function() toggleBackshoot() end
})
backGroup:AddButton({
    Text = "解除瞬移（回原位）",
    Func = function() releaseBackshoot() end
})

-- ========== Combat: Anti-Aim ==========
local antiGroup = CombatTab:AddRightGroupbox("反瞄準（Anti-Aim）")
antiGroup:AddToggle("AntiAim_Enabled", {
    Text = "啟用反瞄準", Default = false,
    Callback = function(v) S.AntiAimEnabled = v; updateAntiAim() end
})
antiGroup:AddDropdown("AntiAim_Yaw", { Text = "Yaw", Default = "jitter", Values = {"none","jitter","spinbot","random"}, Callback = function(v) S.AntiAimYaw = v end })
antiGroup:AddDropdown("AntiAim_Pitch", { Text = "Pitch", Default = "jitter", Values = {"none","jitter","spinbot","random"}, Callback = function(v) S.AntiAimPitch = v end })
antiGroup:AddDropdown("AntiAim_Angle", { Text = "Angle", Default = "none", Values = {"none","tilt 45","tilt 90","upside down","custom"}, Callback = function(v) S.AntiAimAngle = v end })
antiGroup:AddSlider("AntiAim_CustomAngle", { Text = "Custom Angle", Default = 0, Min = 0, Max = 360, Rounding = 1, Compact = true, Callback = function(v) S.AntiAimCustomAngle = v end })
antiGroup:AddSlider("AntiAim_MinSpeed", { Text = "Min Speed", Default = 10, Min = 1, Max = 50, Rounding = 1, Compact = true, Callback = function(v) S.AntiAimMinSpeed = v end })
antiGroup:AddSlider("AntiAim_MaxSpeed", { Text = "Max Speed", Default = 20, Min = 1, Max = 100, Rounding = 1, Compact = true, Callback = function(v) S.AntiAimMaxSpeed = v end })
antiGroup:AddSlider("AntiAim_MinAngle", { Text = "Min Angle", Default = 30, Min = 1, Max = 180, Rounding = 1, Compact = true, Callback = function(v) S.AntiAimMinAngle = v end })
antiGroup:AddSlider("AntiAim_MaxAngle", { Text = "Max Angle", Default = 60, Min = 1, Max = 180, Rounding = 1, Compact = true, Callback = function(v) S.AntiAimMaxAngle = v end })
antiGroup:AddToggle("AntiAim_RandomAngle", { Text = "Random Angle", Default = false, Callback = function(v) S.AntiAimRandomAngle = v end })

-- ========== Combat: 模擬滑鼠自瞄 ==========
local aimGroup = CombatTab:AddRightGroupbox("自瞄（模擬滑鼠）")
aimGroup:AddToggle("Aimbot_Enabled", {
    Text = "Enable Aimbot", Default = false,
    Callback = function(v)
        S.AimEnabled = v
        if v then S.TeamCheck = true end
    end
})
aimGroup:AddDropdown("Aimbot_HitPart", { Text = "Hit Part", Default = "Head", Values = {"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso"}, Callback = function(v) S.AimHitPart = v end })
aimGroup:AddSlider("Aimbot_FOV", { Text = "FOV Radius", Default = 300, Min = 10, Max = 1000, Rounding = 0, Compact = true, Callback = function(v) S.AimFOV = v end })
aimGroup:AddToggle("Aimbot_WallCheck", { Text = "Wall Check（牆檢）", Default = false, Callback = function(v) S.AimWallCheck = v end })
aimGroup:AddSlider("Aimbot_Sens", { Text = "滑鼠靈敏度", Default = 1.0, Min = 0.1, Max = 5, Rounding = 2, Compact = true, Callback = function(v) S.MouseSens = v end })
aimGroup:AddSlider("Aimbot_Smooth", { Text = "滑鼠平滑", Default = 0.5, Min = 0, Max = 0.95, Rounding = 2, Compact = true, Callback = function(v) S.MouseSmooth = v end })
aimGroup:AddSlider("Aimbot_Deadzone", { Text = "滑鼠死區", Default = 2, Min = 0, Max = 20, Rounding = 0, Compact = true, Callback = function(v) S.MouseDeadzone = v end })
aimGroup:AddSlider("Aimbot_MaxStep", { Text = "單幀上限", Default = 200, Min = 10, Max = 500, Rounding = 0, Compact = true, Callback = function(v) S.MouseMaxStep = v end })
aimGroup:AddSlider("Aimbot_Stuck", { Text = "卡住解鎖秒", Default = 3, Min = 0.5, Max = 10, Rounding = 1, Compact = true, Callback = function(v) S.AimStuckTime = v end })

-- ========== Visuals ==========
local espGroup = VisualsTab:AddLeftGroupbox("ESP")
espGroup:AddToggle("ESP_Enabled", { Text = "ESP 開關", Default = true, Callback = function(v) S.ESPEnabled = v end })
espGroup:AddToggle("ESP_Name", { Text = "名字", Default = true, Callback = function(v) S.ShowName = v end })
espGroup:AddToggle("ESP_Distance", { Text = "距離", Default = true, Callback = function(v) S.ShowDistance = v end })
espGroup:AddToggle("ESP_Health", { Text = "血量", Default = true, Callback = function(v) S.ShowHealth = v end })
espGroup:AddToggle("ESP_Tracer", { Text = "追蹤線", Default = true, Callback = function(v) S.ShowTracer = v end })
espGroup:AddToggle("ESP_Skeleton", { Text = "骨架", Default = true, Callback = function(v) S.ShowSkeleton = v end })
espGroup:AddSlider("ESP_MaxDist", { Text = "最大距離", Default = 2000, Min = 100, Max = 5000, Rounding = 0, Compact = true, Callback = function(v) S.MaxDistance = v end })
espGroup:AddSlider("ESP_HueSpeed", { Text = "彩虹速度", Default = 0.25, Min = 0, Max = 2, Rounding = 2, Compact = true, Callback = function(v) S.HueSpeed = v end })

local crossGroup = VisualsTab:AddRightGroupbox("Crosshair")
crossGroup:AddToggle("Crosshair_Enabled", { Text = "Enable Crosshair", Default = false, Callback = function(v) S.CrosshairEnabled = v end }):AddColorPicker("Crosshair_Color", { Default = Color3.fromRGB(0, 200, 255), Title = "Color", Callback = function(v) S.CrosshairColor = v end })
crossGroup:AddToggle("Crosshair_ShowLines", { Text = "Show Lines", Default = true, Callback = function(v) S.CrosshairShowLines = v end })
crossGroup:AddSlider("Crosshair_Spin", { Text = "Spin Speed", Default = 150, Min = 0, Max = 340, Rounding = 0, Compact = true, Callback = function(v) S.CrosshairSpinSpeed = v end })
crossGroup:AddDropdown("Crosshair_Mode", { Text = "Mode", Default = "static", Values = {"static","follow muzzle"}, Callback = function(v) S.CrosshairMode = v end })

-- ========== Movement ==========
local moveGroup = MovementTab:AddLeftGroupbox("Movement")
moveGroup:AddToggle("Move_InfJump", { Text = "Infinite Jump", Default = false, Callback = function(v) S.InfJump = v end })
moveGroup:AddToggle("Move_Noclip", { Text = "Noclip", Default = false, Callback = function(v) S.Noclip = v end })
moveGroup:AddToggle("Move_Fly", { Text = "Fly", Default = false, Callback = function(v) S.FlyEnabled = v; updateFly() end })
moveGroup:AddSlider("Move_WalkSpeed", { Text = "WalkSpeed", Default = 16, Min = 16, Max = 200, Rounding = 0, Compact = true, Callback = function(v) S.WalkSpeed = v end })
moveGroup:AddSlider("Move_JumpPower", { Text = "JumpPower", Default = 50, Min = 50, Max = 300, Rounding = 0, Compact = true, Callback = function(v) S.JumpPower = v end })
moveGroup:AddSlider("Move_FlySpeed", { Text = "Fly Speed", Default = 50, Min = 16, Max = 750, Rounding = 0, Compact = true, Callback = function(v) S.FlySpeed = v end })

-- ========== Gun ==========
local gunGroup = GunTab:AddLeftGroupbox("Gun Mods")
gunGroup:AddToggle("Gun_AntiKatana", { Text = "Anti Katana", Default = false, Callback = function(v) S.AntiKatana = v end })
gunGroup:AddToggle("Gun_NoCooldown", { Text = "No Cooldown", Default = false, Callback = function(v) S.NoCooldown = v end })
gunGroup:AddToggle("Gun_NoSpread", { Text = "No Spread (無散射)", Default = false, Callback = function(v) S.NoSpread = v end })
gunGroup:AddToggle("Gun_NoRecoil", { Text = "No Recoil", Default = false, Callback = function(v) S.NoRecoil = v end })
gunGroup:AddToggle("Gun_MaxAccuracy", { Text = "Max Accuracy", Default = false, Callback = function(v) S.MaxAccuracy = v end })
gunGroup:AddToggle("Gun_RapidAttack", { Text = "Rapid Attack", Default = false, Callback = function(v) S.RapidAttack = v end })
gunGroup:AddToggle("Gun_NoMuzzleFlash", { Text = "No Muzzle Flash", Default = false, Callback = function(v) S.NoMuzzleFlash = v; updateMuzzleFlash() end })

-- ========== Misc ==========
local deviceGroup = MiscTab:AddLeftGroupbox("Device Spoof")
deviceGroup:AddToggle("Device_Spoof", { Text = "Enable", Default = false, Callback = function(v) S.DeviceSpoof = v; applyDeviceSpoof() end })
deviceGroup:AddDropdown("Device_Type", { Text = "Type", Default = "PC", Values = {"PC","Console","Mobile","VR"}, Callback = function(v) S.DeviceType = v; if S.DeviceSpoof then applyDeviceSpoof() end end })

local miscGroup = MiscTab:AddRightGroupbox("Misc")
miscGroup:AddToggle("Misc_TeamCheck", { Text = "隊伍檢測（開啟自瞄時自動啟用）", Default = true, Callback = function(v) S.TeamCheck = v end })
miscGroup:AddToggle("Misc_AntiAFK", { Text = "反 AFK", Default = true, Callback = function(v) S.AntiAFK = v end })
miscGroup:AddButton({ Text = "卸載腳本", Func = function()
    pcall(function() RunService:UnbindFromRenderStep(AIMBOT_BIND) end)
    if antiAimConn then antiAimConn:Disconnect() end
    if Rage.syncConn then Rage.syncConn:Disconnect() end
    if espGui then espGui:Destroy() end
    for _, line in ipairs(crosshairLines) do pcall(function() line:Remove() end) end
    for k, _ in pairs(espCache) do clESP(k) end
    cleanupFly()
    if muzzleFlashConn then muzzleFlashConn:Disconnect() end
    Library:Unload()
end })

-- ========== 主迴圈 ==========
RunService.RenderStepped:Connect(function(dt)
    tGlobal = tGlobal + dt
    if not C then C = W.CurrentCamera end
    if not C then return end

    if S.AimEnabled then
        if UIS:IsKeyDown(Enum.KeyCode.Q) then
            if not aimTarget or not isAliveEntry(aimTarget) then
                aimTarget = findNearestAny()
            end
        else
            aimTarget = findNearestInFOV()
        end
    else
        aimTarget = nil
    end

    if aimTarget then
        local part = getAimPart(aimTarget)
        if part then
            if lastAimPos and (part.Position - lastAimPos).Magnitude < 0.1 then
                if tick() - lastAimTime > S.AimStuckTime then
                    aimTarget = nil
                    lastAimTime = tick()
                    lastAimPos = nil
                end
            else
                lastAimPos = part.Position
                lastAimTime = tick()
            end
        end
    else
        lastAimPos = nil
        lastAimTime = tick()
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

Library:Notify({ Title = "AXIOM v9.8", Description = "Silent 360 + Ragebot 整合完成", Time = 4 })
print("[v9.8] 完整載入完成")
