
print("[v12.0] 完整版載入完成")-- ============================================================
-- LuaHook v12.0 — 完整版（準心呼吸伸縮 + 彩虹 + Sky 系統 + Hold 快捷鍵）
-- 第一段：反封鎖 + 框架 + Gun Mods + 靜默 + 自瞄 + 觸發 + ESP + Rage + AutoQueue
-- ============================================================

local hookmetamethod    = hookmetamethod
local getrawmetatable   = getrawmetatable
local setreadonly       = setreadonly
local checkcaller       = checkcaller
local getnamecallmethod = getnamecallmethod
local getconnections    = getconnections
local hookfunction      = hookfunction
local newcclosure       = newcclosure
local getrenv           = getrenv
local getgc             = getgc
local getfenv           = getfenv
local getgenvFn         = getgenv
local clonefunction     = clonefunction
local firetouchinterest = firetouchinterest
local getthreadidentity = getthreadidentity or get_thread_identity or getidentity or getthreadcontext
local setthreadidentity = setthreadidentity or set_thread_identity or setidentity or setthreadcontext
local sethiddenproperty = sethiddenproperty or set_hidden_property
local gethiddenproperty = gethiddenproperty or get_hidden_property
local setfflag          = setfflag or setfastflag or set_fflag
local getfflag          = getfflag or getfastflag
local debugLib          = debug

local Players           = game:GetService("Players")
local RS                = game:GetService("ReplicatedStorage")
local UIS               = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local W                 = game:GetService("Workspace")
local C                 = W.CurrentCamera
local LP                = Players.LocalPlayer
local CollectionService = game:GetService("CollectionService")
local Lighting          = game:GetService("Lighting")
local VirtualInputMgr   = game:GetService("VirtualInputManager")
local SoundService      = game:GetService("SoundService")
local TweenService      = game:GetService("TweenService")

W:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    C = W.CurrentCamera
end)

getgenvFn().__LH_Hooks = {}

if hookmetamethod and getrawmetatable and setreadonly then
    local mt = getrawmetatable(game)
    pcall(function() setreadonly(mt, false) end)
    local oldNamecall = mt.__namecall
    local newNamecall = function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" and self == LP then return end
        return oldNamecall(self, ...)
    end
    mt.__namecall = newNamecall
    pcall(function() setreadonly(mt, true) end)
    table.insert(getgenvFn().__LH_Hooks, { target = mt, old = oldNamecall })
end

local function LH_restoreAllHooks()
    pcall(function()
        local hooks = getgenvFn and getgenvFn().__LH_Hooks
        if not hooks then return end
        for i = #hooks, 1, -1 do
            local h = hooks[i]
            pcall(function()
                if type(restorefunction) == "function" and h.target then
                    restorefunction(h.target)
                end
            end)
        end
        getgenvFn().__LH_Hooks = {}
    end)
end
getgenvFn().__LH_restoreAllHooks = LH_restoreAllHooks

local function safeRequire(path, timeout)
    if not path then return nil end
    timeout = timeout or 5
    local start = tick()
    while tick() - start < timeout do
        local ok, result = pcall(require, path)
        if ok then return result end
        task.wait(0.2)
    end
    return nil
end

local function waitModule(root, names, timeout)
    timeout = timeout or 10
    local obj = root
    for _, n in ipairs(names) do
        if not obj then return nil end
        local ok, child = pcall(function() return obj:WaitForChild(n, timeout) end)
        obj = ok and child or nil
    end
    return obj
end

local function loadGameModule(root, names)
    local inst = waitModule(root, names)
    return safeRequire(inst, 15)
end

local _safePlayersCache = nil
local function getSafePlayers()
    if _safePlayersCache then return _safePlayersCache end
    local list = {}
    for _, p in ipairs(Players:GetChildren()) do
        if p:IsA("Player") then list[#list+1] = p end
    end
    _safePlayersCache = list
    return list
end
Players.PlayerAdded:Connect(function() _safePlayersCache = nil end)
Players.PlayerRemoving:Connect(function() _safePlayersCache = nil end)

repeat task.wait() until game:IsLoaded()

local Rivals = { Ready = false }
local function resolveAll(jobs, timeout)
    local pending = #jobs
    for _, job in ipairs(jobs) do
        task.spawn(function()
            pcall(job)
            pending = pending - 1
        end)
    end
    local deadline = tick() + (timeout or 25)
    while pending > 0 and tick() < deadline do task.wait() end
    return pending == 0
end

resolveAll({
    function() Rivals.Util    = loadGameModule(RS, {"Modules","Utility"}) end,
    function() Rivals.Fighter = loadGameModule(LP.PlayerScripts, {"Controllers","FighterController"}) end,
    function() Rivals.Enums   = loadGameModule(RS, {"Modules","EnumLibrary"}) end,
})
Rivals.Ready = (Rivals.Util ~= nil and Rivals.Fighter ~= nil)

local UseItem = nil
local Utility = Rivals.Util
local EnumLibrary = Rivals.Enums
local function refreshUseItem()
    local Remotes = RS:FindFirstChild("Remotes")
    local Replication = Remotes and Remotes:FindFirstChild("Replication")
    local FighterRemote = Replication and Replication:FindFirstChild("Fighter")
    if FighterRemote then
        UseItem = FighterRemote:FindFirstChild("UseItem")
    end
end
refreshUseItem()
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    refreshUseItem()
    if not Utility then Utility = Rivals.Util end
    if not EnumLibrary then EnumLibrary = Rivals.Enums end
end)

local GunModule, MeleeModule, GameplayUtility
local function resolveWeaponModules()
    task.spawn(function()
        resolveAll({
            function() if GunModule == nil then GunModule = loadGameModule(LP.PlayerScripts, {"Modules","ItemTypes","Gun"}) end end,
            function() if MeleeModule == nil then MeleeModule = loadGameModule(LP.PlayerScripts, {"Modules","ItemTypes","Melee"}) end end,
            function() if GameplayUtility == nil then GameplayUtility = loadGameModule(RS, {"Modules","GameplayUtility"}) end end,
        })
    end)
end
resolveWeaponModules()
LP.CharacterAdded:Connect(function()
    task.wait(1)
    resolveWeaponModules()
end)

local function envIdOf(player)
    local id = nil
    pcall(function()
        local fc = Rivals.Fighter
        if fc == nil then return end
        local f = (player == LP) and fc.LocalFighter or (fc._player_to_fighter and fc._player_to_fighter[player])
        if f == nil then return end
        id = f:Get("EnvironmentID")
        if id == nil and f.Entity ~= nil then id = f.Entity:Get("EnvironmentID") end
    end)
    return id
end

local function isTeammate(player)
    if player == LP then return true end
    local myEnv, theirEnv = envIdOf(LP), envIdOf(player)
    if myEnv ~= nil and theirEnv ~= nil and myEnv ~= theirEnv then return true end
    local a = LP:GetAttribute("TeamID")
    local b = player:GetAttribute("TeamID")
    if a == nil or b == nil then
        if LP.Team ~= nil and player.Team ~= nil then return LP.Team == player.Team end
        return false
    end
    return a == b
end

local function isAlive(player)
    local c = player.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h ~= nil and h.Health > 0
end

local function getHealth(player)
    if not player.Character then return 0, 100 end
    local h = player.Character:FindFirstChildOfClass("Humanoid")
    if not h then return 0, 100 end
    return h.Health, h.MaxHealth
end

local function isSpawnProtected(player)
    if not player then return false end
    if player.Character and player.Character:FindFirstChildOfClass("ForceField") then return true end
    return false
end

local function isDeflecting(player)
    if not player or not player.Character then return false end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then return false end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        if track.Name:lower():find("deflect") then return true end
    end
    return false
end

local function isSanePos(p)
    if not p then return false end
    local LIM = 100000
    return p == p and math.abs(p.X) < LIM and math.abs(p.Y) < LIM and math.abs(p.Z) < LIM
end

local function posIsOOB(pos) return false end

local function killFloor()
    local ok, val = pcall(function() return W.FallenPartsDestroyHeight end)
    if ok and type(val) == "number" and val == val then return val + 200 end
    return -400
end

local function inMatch()
    local envOk = false
    pcall(function()
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        if lf ~= nil and lf:Get("EnvironmentID") ~= nil and lf:IsAlive() then envOk = true end
    end)
    if envOk then return true end
    if LP:GetAttribute("TeamID") ~= nil then return true end
    if LP.Team ~= nil then return true end
    return false
end

local function getLocalFighter()
    if not Rivals.Ready then return nil end
    return Rivals.Fighter and Rivals.Fighter.LocalFighter
end

local function getEquippedItem()
    local lf = getLocalFighter()
    return lf and lf.EquippedItem or nil
end

local _sharedVelMap = {}
do
    local _svPos, _svTime = {}, {}
    local _svAccum = 0
    local SV_INTERVAL = 1 / 30
    shared._LH_velConn = RunService.Heartbeat:Connect(function(dt)
        _svAccum = _svAccum + (dt or 0)
        if _svAccum < SV_INTERVAL then return end
        _svAccum = 0
        local now = tick()
        for _, p in ipairs(getSafePlayers()) do
            if p ~= LP and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local pos = hrp.Position
                    local lt  = _svTime[p]
                    if _svPos[p] and lt then
                        local d = now - lt
                        if d > 0 then
                            local v = (pos - _svPos[p]) / d
                            if v.Magnitude < 500 then _sharedVelMap[p] = v end
                        end
                    end
                    _svPos[p]  = pos
                    _svTime[p] = now
                end
            end
        end
    end)
end

local visParams = RaycastParams.new()
visParams.FilterType = Enum.RaycastFilterType.Exclude
local _visFilterChar = nil
local function isVisible(worldPos)
    local origin = C.CFrame.Position
    local _vc = LP.Character
    if _vc ~= _visFilterChar then
        visParams.FilterDescendantsInstances = { _vc }
        _visFilterChar = _vc
    end
    local result = W:Raycast(origin, worldPos - origin, visParams)
    if not result then return true end
    local hitModel = result.Instance and result.Instance:FindFirstAncestorOfClass("Model")
    if hitModel and Players:GetPlayerFromCharacter(hitModel) then return true end
    return (result.Position - worldPos).Magnitude < 3
end

local HEAD_PARTS    = { "HitboxHead", "HitboxHeadSmall", "Head" }
local TORSO_PARTS   = { "HitboxBody", "UpperTorso", "HumanoidRootPart", "LowerTorso" }

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

local function pickPart(char, mode)
    if not char then return nil end
    if mode == "Closest" then
        local best, bestDist = nil, math.huge
        local vp     = C.ViewportSize
        local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
        for _, name in ipairs({"HitboxHead","Head","UpperTorso","LowerTorso","HumanoidRootPart","LeftHand","RightHand","LeftFoot","RightFoot","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg"}) do
            local p = char:FindFirstChild(name)
            if p and p:IsA("BasePart") then
                local sp, on = C:WorldToViewportPoint(p.Position)
                if on and sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < bestDist then best, bestDist = p, d end
                end
            end
        end
        if best then return best end
    end
    local list = mode == "Torso" and TORSO_PARTS or HEAD_PARTS
    for _, name in ipairs(list) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then return p end
    end
    return char:FindFirstChild("HumanoidRootPart")
end

local HP_RAMP_STOPS = {
    { 0.00, Color3.fromRGB(255,  68,  54) },
    { 0.20, Color3.fromRGB(255, 122,  61) },
    { 0.40, Color3.fromRGB(255, 194,  75) },
    { 0.60, Color3.fromRGB(196, 226,  78) },
    { 1.00, Color3.fromRGB( 61, 224, 122) },
}
local function hpRamp(frac)
    frac = math.clamp(frac or 0, 0, 1)
    for i = 1, #HP_RAMP_STOPS - 1 do
        local a, b = HP_RAMP_STOPS[i], HP_RAMP_STOPS[i + 1]
        if frac <= b[1] then
            local span = b[1] - a[1]
            local t = span > 0 and (frac - a[1]) / span or 0
            return a[2]:Lerp(b[2], math.clamp(t, 0, 1))
        end
    end
    return HP_RAMP_STOPS[#HP_RAMP_STOPS][2]
end

local SharedEncode = {}
do
    local function lookCF(fromPos, toPos)
        local dir = toPos - fromPos
        if dir.Magnitude < 1e-4 then dir = Vector3.new(0, -1, 0) end
        local up = Vector3.new(0, 1, 0)
        if math.abs(dir.Unit.Y) > 0.999 then up = Vector3.new(0, 0, 1) end
        return CFrame.lookAt(fromPos, fromPos + dir, up)
    end
    SharedEncode.lookCF = lookCF

    local function calculateLead(targetChar, fromPos, wantLead)
        if not targetChar then return Vector3.new() end
        local hum = targetChar:FindFirstChildOfClass("Humanoid")
        local hrp = targetChar:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return Vector3.new() end
        local lat = (LP:GetNetworkPing() or 0.05) + 0.03
        local lead = Vector3.new()
        if wantLead then
            local ply     = Players:GetPlayerFromCharacter(targetChar)
            local trueVel = hrp.AssemblyLinearVelocity
            local calcVel = ply and _sharedVelMap[ply]
            if calcVel then
                if (trueVel - calcVel).Magnitude > 25 then trueVel = calcVel end
            else
                if trueVel.Magnitude > 100 then trueVel = Vector3.new() end
            end
            if trueVel.Magnitude > 120 then trueVel = Vector3.new() end
            local md = hum.MoveDirection
            if md.Magnitude > 0.1 then
                lead = lead + Vector3.new(trueVel.X, 0, trueVel.Z) * lat
            end
            lead = lead + Vector3.new(0, trueVel.Y * lat, 0)
        end
        local cap = 15
        if lead.Magnitude > cap then lead = lead.Unit * cap end
        return lead
    end

    function SharedEncode.buildShotFields(camData, eyeCF, muzzleCF, hitPart, aimWorldPos, jitter, clampFrac, jitterFrac)
        local objSpace = hitPart.CFrame:PointToObjectSpace(aimWorldPos)
        local hs = hitPart.Size * (clampFrac or 0.45)
        objSpace = Vector3.new(
            math.clamp(objSpace.X, -hs.X, hs.X),
            math.clamp(objSpace.Y, -hs.Y, hs.Y),
            math.clamp(objSpace.Z, -hs.Z, hs.Z)
        )
        if jitter then
            local jf = jitterFrac or 1.0
            objSpace = Vector3.new(
                math.clamp(objSpace.X + (math.random() - 0.5) * hs.X * jf, -hs.X, hs.X),
                math.clamp(objSpace.Y + (math.random() - 0.5) * hs.Y * jf, -hs.Y, hs.Y),
                math.clamp(objSpace.Z + (math.random() - 0.5) * hs.Z * jf, -hs.Z, hs.Z)
            )
        end
        local hitWorld   = hitPart.CFrame:PointToWorldSpace(objSpace)
        local objSpaceCF = hitPart.CFrame:ToObjectSpace(CFrame.new(hitWorld))
        camData[utf8.char(0)] = Utility:EncodeCFrame(eyeCF)
        camData[utf8.char(1)] = Utility:EncodeCFrame(muzzleCF)
        camData[utf8.char(2)] = hitPart
        camData[utf8.char(3)] = Utility:EncodeCFrame(objSpaceCF)
    end

    function SharedEncode.encodeShot(camData, hitPart, targetChar, fromCamPos, claimOffset)
        if not hitPart or not camData or not Utility then return false end
        local lead      = calculateLead(targetChar, fromCamPos)
        local off       = (typeof(claimOffset) == "Vector3") and claimOffset or Vector3.zero
        local leadedPos = hitPart.Position + lead + off
        local eyeCF     = lookCF(fromCamPos, leadedPos)
        local muzzlePos = fromCamPos + (eyeCF.RightVector * 0.2) + Vector3.new(0, -0.07, 0)
        local muzzleCF  = lookCF(muzzlePos, leadedPos)
        SharedEncode.buildShotFields(camData, eyeCF, muzzleCF, hitPart, leadedPos, true, 0.45, 1.0)
        return true
    end
end

Config = {
    SilentEnabled = false, SilentHitPart = "Head", SilentHitChance = 100, SilentFOV = 150,
    SilentAutoShoot = false, SilentWallCheck = true, Silent360 = false,
    SilentStickiness = 0.05, SilentBodyMix = 25, SilentJitterDeg = 1.5,

    Aimbot = false, AimbotVisCheck = true, AimbotKey = "MB2",
    AimbotSmoothness = 0, AimbotFOVDeg = 20,
    AimbotTargetPart = "Best", AimbotStickiness = 0.15, AimbotSwitchDeg = 2,
    AimbotForgetTime = 0.2, AimbotTrackAssist = 100,

    Trigger = false, TriggerKey = "Always", TriggerHeadOnly = false,

    TeamCheck = true, MaxDistance = math.huge,

    NoCooldown = false, NoSpread = false, NoRecoil = false,
    MaxAccuracy = false, RapidAttack = false, NoMuzzleFlash = false,
    AntiKatana = false,

    ESP = true, ESPTeamCheck = true, ESPMaxDistance = math.huge,
    ESPFont = "Code", ESPTextSize = 14, ESPInfoTextSize = 12,
    ESPBoxScale = 1, ESPBox = true, ESPBoxThickness = 1,
    ESPBoxGlow = true, ESPRainbowBox = false,
    ESPName = true, ESPDistance = true, ESPHealth = true,
    ESPNameMode = "Display",
    ESPBoxColor = Color3.fromRGB(0, 229, 255),
    ESPNameColor = Color3.fromRGB(243, 246, 250),
    ESPInfoColor = Color3.fromRGB(174, 185, 197),
    ESPHealthColor = Color3.fromRGB(61, 224, 122),

    Rage = false, RageMode = "Polar",
    RageGumMode = "on", RageVoidDepth = "deep",
    RageSkipImmune = true, RageIdentityDance = true, RageHPPriority = true,
    RageKnifeBot = true, RageOnEmpty = "Swap", RagePreferredSlot = "Primary",
    RageEyeMuzzleSep = 0.07, RageKillPlaneBuffer = 200,
    RageTaps = 6, RageTapsPerFrame = 1, RageHideJitter = true,
    RageRestoreMode = "auto",
    RageCombatOrbitRadius = 60, RageOrbitDwell = 0.30,
    RageCombatOrbitHeight = 8, RageCombatOrbitJitter = true,
    RagePBEyeUp = 3,

    AutoQueueEnabled = false, AutoQueueMode = "1v1", AutoQueueDelay = 2, AutoQueueRanked = false,

    -- 準心
    FXCrosshair          = false,
    FXCrosshairStyle     = "Cross",
    FXCrosshairColor     = Color3.fromRGB(243, 246, 250),
    FXCrosshairDot       = true,
    FXCrosshairGap       = 4,
    FXCrosshairLen       = 7,
    FXCrosshairThickness = 2,
    FXCrosshairOutline   = true,
    FXCrosshairHitPop    = true,
    FXCrosshairAngle     = 0,
    FXCrosshairSpin      = true,
    FXCrosshairSpinSpeed = 0.6,
    FXCrosshairBounce    = true,
    FXCrosshairBounceAmt = 6,
    FXCrosshairBreathSpeed = 0.8,
    FXCrosshairRainbow      = true,
    FXCrosshairRainbowSpeed = 0.15,
    FXCrosshairSniper    = false,

    -- Sky
    SkyboxPreset        = "Off",
    SkyboxHideCelestial = false,

    HUDWatermark = true,
}

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
if isMobile then Config.AimbotKey = "Always" end

State = {
    SilentLastTarget = nil,
    Shots = 0, Hits = 0,
    AimbotTarget = nil, AimbotPart = nil,
    AimbotLastTarget = nil, AimbotLastTargetTime = 0,
    AimbotKeyHeld = false,
    ESPObjects = {},
    RageTarget = nil,
    RageVoidCF = nil,
    RageInMatch = false,
    RageStatus = "Idle",
    RageFiring = false,
    RageVoidActive = false,
    RageTrueVelocityMap = {},
    RageCharTokens = {},
    OrbitAngle = 0,
    OrbitVantage = nil,
    OrbitVantageUntil = 0,
    AutoQueueStatus = "-",
}

-- Hold Keybind
local KeybindHold = {}
do
    local _bound = {}
    local _connBegan, _connEnded = nil, nil

    local function matchInput(b, input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and b.keys["MB1"] then return true end
        if input.UserInputType == Enum.UserInputType.MouseButton2 and b.keys["MB2"] then return true end
        if input.UserInputType == Enum.UserInputType.Keyboard and b.keys[input.KeyCode.Name] then return true end
        return false
    end

    local function startLoop()
        if _connBegan then return end
        _connBegan = UIS.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            for _, b in pairs(_bound) do
                if not b.active and matchInput(b, input) then
                    b.active = true
                    pcall(b.onDown)
                end
            end
        end)
        _connEnded = UIS.InputEnded:Connect(function(input, gpe)
            if gpe then return end
            for _, b in pairs(_bound) do
                if b.active and matchInput(b, input) then
                    b.active = false
                    pcall(b.onUp)
                end
            end
        end)
    end

    function KeybindHold.bind(name, keys, onDown, onUp)
        if type(keys) == "string" then keys = { keys } end
        local set = {}
        for _, k in ipairs(keys) do set[k] = true end
        _bound[name] = { keys = set, onDown = onDown, onUp = onUp, active = false }
        startLoop()
    end

    function KeybindHold.unbind(name) _bound[name] = nil end
    function KeybindHold.unbindAll()
        _bound = {}
        if _connBegan then _connBegan:Disconnect(); _connBegan = nil end
        if _connEnded then _connEnded:Disconnect(); _connEnded = nil end
    end
end
getgenvFn().__LH_KeybindHold = KeybindHold

-- Gun Mods
do
    task.spawn(function()
        for _ = 1, 30 do
            if GunModule and GunModule.StartShooting then break end
            task.wait(1)
        end
        if not GunModule or not GunModule.StartShooting then return end
        if shared._LH_GunOrig then pcall(function() GunModule.StartShooting = shared._LH_GunOrig end) end
        local origGunShoot = GunModule.StartShooting
        shared._LH_GunOrig = origGunShoot
        GunModule.StartShooting = function(self, p26, p27)
            local oldCD, oldSpread, oldAcc, oldRecoil, oldConsistent
            if Config.NoCooldown then
                oldCD = self.Info.ShootCooldown
                self.Info.ShootCooldown = 0
            end
            if Config.NoSpread or Config.MaxAccuracy then
                oldSpread = self.Info.ShootSpread
                oldAcc = self.Info.ShootAccuracy
                oldConsistent = self.Info.ShootSpreadConsistent
                self.Info.ShootSpread = 0
                self.Info.ShootAccuracy = 1
                self.Info.ShootSpreadConsistent = true
            end
            if Config.NoRecoil then
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
    end)
end

do
    task.spawn(function()
        for _ = 1, 30 do
            if GameplayUtility and GameplayUtility.GetSpread then break end
            task.wait(1)
        end
        if not GameplayUtility or not GameplayUtility.GetSpread then return end
        if shared._LH_SpreadOrig then pcall(function() GameplayUtility.GetSpread = shared._LH_SpreadOrig end) end
        local origSpread = GameplayUtility.GetSpread
        shared._LH_SpreadOrig = origSpread
        GameplayUtility.GetSpread = function(self, aimMultiplier, isAiming, isCrouching, pelletIndex, totalPellets, consistent)
            if Config.NoSpread or Config.MaxAccuracy then return CFrame.new() end
            return origSpread(self, aimMultiplier, isAiming, isCrouching, pelletIndex, totalPellets, consistent)
        end
    end)
end

do
    task.spawn(function()
        for _ = 1, 30 do
            if MeleeModule and MeleeModule.StartShooting then break end
            task.wait(1)
        end
        if not MeleeModule or not MeleeModule.StartShooting then return end
        if shared._LH_MeleeOrig then pcall(function() MeleeModule.StartShooting = shared._LH_MeleeOrig end) end
        local origMeleeShoot = MeleeModule.StartShooting
        shared._LH_MeleeOrig = origMeleeShoot
        MeleeModule.StartShooting = function(self, p26, p27)
            local oldCD
            if Config.RapidAttack then
                oldCD = self.Info.AttackCooldown
                self.Info.AttackCooldown = 0
            end
            local result = { origMeleeShoot(self, p26, p27) }
            if Config.RapidAttack and oldCD then self.Info.AttackCooldown = oldCD end
            return unpack(result)
        end
    end)
end

local muzzleFlashConn = nil
local function noMuzzleFlash()
    local vm = W:FindFirstChild("ViewModels")
    local fp = vm and vm:FindFirstChild("FirstPerson")
    if not fp then return end
    for _, model in pairs(fp:GetChildren()) do
        if model:IsA("Model") then
            local iv = model:FindFirstChild("ItemVisual")
            local b = iv and iv:FindFirstChild("Body")
            local bp = b and b:FindFirstChild("BodyPrimary")
            local mz = bp and bp:FindFirstChild("_muzzle")
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
local function updateMuzzleFlash()
    if Config.NoMuzzleFlash then
        noMuzzleFlash()
        if not muzzleFlashConn then
            muzzleFlashConn = RunService.RenderStepped:Connect(noMuzzleFlash)
        end
    else
        if muzzleFlashConn then muzzleFlashConn:Disconnect(); muzzleFlashConn = nil end
    end
end

-- 靜默
local function isValidTargetSilent(player)
    if not player or player == LP then return false end
    if Config.TeamCheck and isTeammate(player) then return false end
    if not isAlive(player) then return false end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    return true
end

local function selectTargetSilent(opts)
    opts = opts or {}
    local fov = opts.fov or 90
    local checkVis = opts.checkVis or false
    local mode = opts.partMode or "Head"
    local sticky = opts.stickyTarget
    local stickyBonus = opts.stickyBonus or 0
    local vp = C.ViewportSize
    local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    local best, bestPart, bestScore = nil, nil, math.huge
    for _, player in ipairs(getSafePlayers()) do
        if isValidTargetSilent(player) then
            local char = player.Character
            local part = pickPart(char, mode)
            if part then
                if (not checkVis) or isVisible(part.Position) then
                    local sp, on = C:WorldToViewportPoint(part.Position)
                    if on and sp.Z > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d <= fov then
                            local score = d
                            if player == sticky then score = score * (1 - stickyBonus) end
                            if score < bestScore then bestScore, best, bestPart = score, player, part end
                        end
                    end
                end
            end
        end
    end
    return best, bestPart
end

local function findSilentTarget()
    if Config.Silent360 then
        local best, bestD = nil, math.huge
        local myChar = LP.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end
        for _, p in ipairs(getSafePlayers()) do
            if isValidTargetSilent(p) then
                local part = getHitPartName(p.Character, Config.SilentHitPart)
                if part then
                    local visibleOK = (not Config.SilentWallCheck) or isVisible(part.Position)
                    if visibleOK then                        local d = (part.Position - myRoot.Position).Magnitude
                        if d < bestD then best, bestD = p, d end
                    end
                end
            end
        end
        return best
    end
    local tgt, part = selectTargetSilent({
        fov = Config.SilentFOV,
        checkVis = Config.SilentWallCheck,
        partMode = Config.SilentHitPart,
        stickyTarget = State.SilentLastTarget,
        stickyBonus = Config.SilentStickiness,
    })
    return tgt
end

local function fireSilentAt(target)
    if not UseItem or not Utility or not EnumLibrary then return false end
    if not target or not target.Character or not target.Character.Parent then return false end
    local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
    if not lf or not lf.EquippedItem then return false end
    local part = getHitPartName(target.Character, Config.SilentHitPart)
    if not part then return false end
    if Config.SilentWallCheck then
        if not isVisible(part.Position) then return false end
    end
    local myChar = LP.Character
    local root = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local objId = lf.EquippedItem:Get("ObjectID")
    if not objId then return false end
    local camData = {}
    if not SharedEncode.encodeShot(camData, part, target.Character, root.Position) then return false end
    local env = { [utf8.char(1)] = camData }
    pcall(function()
        UseItem:FireServer(objId, EnumLibrary:ToEnum("StartShooting"), env, nil)
    end)
    State.SilentLastTarget = target
    State.Shots = State.Shots + 1
    State.Hits = State.Hits + 1
    return true
end

local silentLastFire = 0
local silentFireCD = 0.01
local function silentAutoFireLoop()
    if not Config.SilentEnabled or not Config.SilentAutoShoot then return end
    local now = tick()
    if now - silentLastFire < silentFireCD then return end
    if Config.SilentHitChance < 100 then
        if math.random(1, 100) > Config.SilentHitChance then return end
    end
    local target = findSilentTarget()
    if not target then return end
    if fireSilentAt(target) then silentLastFire = now end
end

RunService.Heartbeat:Connect(function()
    if Config.SilentEnabled and Config.SilentAutoShoot then
        pcall(silentAutoFireLoop)
    end
end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not Config.SilentEnabled or Config.SilentAutoShoot then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local target = findSilentTarget()
        if target then pcall(fireSilentAt, target) end
    end
end)

-- 自瞄
local Aimbot = {}
;(function()
    local TAU = math.pi * 2
    local D2R = math.pi / 180
    local RETAIN_MUL = 1.6
    local STICKY_MEM = 2.0
    local FF_TAU = 0.05
    local FF_MAX = 12
    local UNIT_MAX = 2000
    local PITCH_LIMIT = 1.5690509975429023
    local CAL_MIN = 1.5
    local CAL_FAST_N = 8
    local BAND_LO = 0.05
    local BAND_HI = 6.0
    local SEED_MX = -0.008726646259971648
    local SEED_MY = -0.006719517620178168
    local SEED_DX = 1.0
    local SEED_DY = 1.0
    local _bound = false
    local _mouseMove = mousemoverel
    local _tgt, _part = nil, nil
    local _prevTgt = nil
    local _lastSeenAt = 0
    local _gx, _gy = SEED_MX, SEED_MY
    local _sdx, _sdy = SEED_MX, SEED_MY
    local _nx, _ny = 0, 0
    local _sx, _sy = 0, 0
    local _fx, _fy = 0, 0
    local _lyaw, _lpit = 0, 0
    local _haveCam = false
    local _ffy, _ffp = 0, 0
    local _haveTgt = false
    local _lastPartRef = nil
    local _auth = 1.0
    local _flips = 0
    local _errEma = 0
    local _lastSign = nil
    local _drive = 0
    local _trips = 0
    local _calOff = false
    local _path = "none"

    local function wrapPi(a) return (a + math.pi) % TAU - math.pi end
    local function yawOf(v) return math.atan2(-v.X, -v.Z) end
    local function pitchOf(v) return math.asin(math.clamp(v.Y, -1, 1)) end
    local function angTo(cf, pos)
        local d = pos - cf.Position
        local m = d.Magnitude
        if m < 1e-4 then return 0 end
        return math.acos(math.clamp(cf.LookVector:Dot(d) / m, -1, 1))
    end
    local function isValidAimTarget(player)
        if not player or player == LP then return false end
        if Config.TeamCheck and isTeammate(player) then return false end
        if not isAlive(player) then return false end
        return true
    end
    local function acquire(cf, fovR, retainR, cur)
        local mode = Config.AimbotTargetPart or "Best"
        local pick = (mode == "Best") and "Head" or mode
        local vis = Config.AimbotVisCheck
        local bP, bPart, bAng, bScore = nil, nil, math.huge, math.huge
        local cPart, cAng, cOK = nil, math.huge, false
        for _, pl in ipairs(getSafePlayers()) do
            if isValidAimTarget(pl) then
                local char = pl.Character
                local part = pickPart(char, pick)
                if part then
                    local ang = angTo(cf, part.Position)
                    local isCur = (pl == cur)
                    if ang <= (isCur and retainR or fovR) then
                        local hasVis = (not vis) or isVisible(part.Position)
                        if hasVis then
                            local score = ang
                            if isCur then
                                cPart, cAng, cOK = part, ang, true
                                score = score * (1 - (Config.AimbotStickiness or 0))
                            end
                            if score < bScore then bScore, bP, bPart, bAng = score, pl, part, ang end
                        end
                    end
                end
            end
        end
        if cOK and bP and bP ~= cur then
            if bAng > cAng - (Config.AimbotSwitchDeg or 0) * D2R then
                return cur, cPart, cAng
            end
        end
        return bP, bPart, bAng
    end
    local function resolvePath()
        local touchOnly = UIS.TouchEnabled and not UIS.MouseEnabled
        if _mouseMove and not touchOnly then return "mouse" end
        return "none"
    end
    local function quant(v, frac)
        local w = v + frac
        local n = (w >= 0) and math.floor(w + 0.5) or math.ceil(w - 0.5)
        return n, w - n
    end
    local function emit(ux, uy)
        if _path == "mouse" then pcall(_mouseMove, ux, uy) end
    end
    local function calibrate(obs, sent, gain, n, seed)
        if math.abs(sent) < CAL_MIN then return gain, n end
        local s = obs / sent
        if (s * seed) <= 0 then return gain, n end
        local a = math.abs(s)
        local lo = math.abs(seed) * BAND_LO
        local hi = math.abs(seed) * BAND_HI
        if a < lo or a > hi then return gain, n end
        if n < CAL_FAST_N then return s, n + 1 end
        local r = math.abs(s / gain)
        if r < 0.34 or r > 3.0 then return gain, n end
        return gain + (s - gain) * 0.05, n + 1
    end
    local function clearTarget()
        _tgt, _part = nil, nil
        _prevTgt = nil
        _haveTgt = false
        _lastPartRef = nil
        _ffy, _ffp = 0, 0
        _flips, _errEma, _lastSign, _drive = 0, 0, nil, 0
        State.AimbotTarget = nil
        State.AimbotPart = nil
    end
    local function step(dt)
        dt = math.clamp(dt or (1 / 60), 1 / 1000, 0.1)
        local cf = C.CFrame
        local look = cf.LookVector
        local curYaw, curPit = yawOf(look), pitchOf(look)
        if _haveCam and not _calOff then
            _gx, _nx = calibrate(wrapPi(curYaw - _lyaw), _sx, _gx, _nx, _sdx)
            _gy, _ny = calibrate(curPit - _lpit, _sy, _gy, _ny, _sdy)
        end
        _lyaw, _lpit, _haveCam = curYaw, curPit, true
        _sx, _sy = 0, 0
        if not Config.Aimbot then
            State.AimbotKeyHeld = false
            clearTarget()
            return
        end
        local keyDown = false
        local kc = Config.AimbotKey
        if kc == "Always" then keyDown = true
        elseif kc == "MB1" then keyDown = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        elseif kc == "MB2" then keyDown = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        elseif kc and Enum.KeyCode[kc] then keyDown = UIS:IsKeyDown(Enum.KeyCode[kc]) end
        State.AimbotKeyHeld = keyDown
        if not keyDown then clearTarget(); return end
        _path = resolvePath()
        if _path == "none" then clearTarget(); return end
        local fovR = math.clamp(Config.AimbotFOVDeg or 20, 0.1, 180) * D2R
        local retainR = math.min(fovR * RETAIN_MUL, math.pi)
        local sticky = _tgt
        if not sticky then
            local last = State.AimbotLastTarget
            if last and (tick() - (State.AimbotLastTargetTime or 0)) <= STICKY_MEM then sticky = last end
        end
        local tgt, part = acquire(cf, fovR, retainR, sticky)
        local now = tick()
        if tgt and part then
            _lastSeenAt = now
        else
            local forget = Config.AimbotForgetTime or 0.2
            if _tgt and (now - _lastSeenAt) <= forget then
                tgt, part = _tgt, _part
            else
                clearTarget()
                return
            end
        end
        if tgt ~= _prevTgt then
            _haveTgt = false
            _ffy, _ffp = 0, 0
            _prevTgt = tgt
        end
        _tgt, _part = tgt, part
        State.AimbotTarget = tgt
        State.AimbotPart = part
        State.AimbotLastTarget = tgt
        State.AimbotLastTargetTime = now
        local targetPos = part.Position
        local targetChar = tgt.Character
        local targetRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        local targetVel = targetRP and targetRP.AssemblyLinearVelocity or Vector3.zero
        local myChar = LP.Character
        local myRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myVel = myRP and myRP.AssemblyLinearVelocity or Vector3.zero
        local vRel = targetVel - myVel
        local d = targetPos - cf.Position
        local dDist = d.Magnitude
        if dDist < 1e-3 then return end
        local u = d / dDist
        local tYaw = yawOf(u)
        local tPit = math.clamp(pitchOf(u), -PITCH_LIMIT, PITCH_LIMIT)
        local errYaw = wrapPi(tYaw - curYaw)
        local errPit = tPit - curPit
        local dH2 = d.X * d.X + d.Z * d.Z
        if _haveTgt and part == _lastPartRef and dH2 > 1e-4 then
            local vDotU = vRel:Dot(u)
            local dH = math.sqrt(dH2)
            local rawFFY = (d.Z * vRel.X - d.X * vRel.Z) / dH2
            local rawFFP = (vRel.Y - vDotU * u.Y) / dH
            local k = math.clamp(dt / FF_TAU, 0, 1)
            _ffy = _ffy + (math.clamp(rawFFY, -FF_MAX, FF_MAX) - _ffy) * k
            _ffp = _ffp + (math.clamp(rawFFP, -FF_MAX, FF_MAX) - _ffp) * k
        else
            _ffy, _ffp = 0, 0
        end
        _haveTgt, _lastPartRef = true, part
        local smoothX = Config.AimbotSmoothness or 0
        local isHardLock = (smoothX == 0)
        local aErr = math.sqrt(errYaw * errYaw + errPit * errPit)
        _errEma = _errEma + (aErr - _errEma) * math.clamp(dt / 0.15, 0, 1)
        _drive = _drive + dt
        local sPos = (errYaw >= 0)
        if _lastSign ~= nil and sPos ~= _lastSign then _flips = _flips + 1 end
        _lastSign = sPos
        _flips = _flips * math.exp(-dt / 0.25)
        if _flips >= 4 and _errEma > 0.02 and not isHardLock then
            _auth = math.max(0.15, _auth * 0.5)
            _flips = 0
        else
            _auth = math.min(1, _auth + dt * 0.3)
        end
        local alphaX = 1
        if smoothX > 0 then alphaX = (1 - math.exp(-dt / ((smoothX / 100) * 0.30))) * _auth end
        local cy = errYaw * alphaX
        local cp = errPit * alphaX
        local ff = (Config.AimbotTrackAssist or 100) / 100
        if ff > 0 and not isHardLock then
            cy = cy + _ffy * dt * ff
            cp = cp + _ffp * dt * ff
        end
        cp = math.clamp(curPit + cp, -PITCH_LIMIT, PITCH_LIMIT) - curPit
        if _gx == 0 or _gy == 0 then return end
        local ux, uy = cy / _gx, cp / _gy
        local um = math.max(math.abs(ux), math.abs(uy))
        if um > UNIT_MAX then local k = UNIT_MAX / um; ux, uy = ux * k, uy * k end
        if _path == "mouse" then
            ux, _fx = quant(ux, _fx)
            uy, _fy = quant(uy, _fy)
        end
        if ux == 0 and uy == 0 then return end
        emit(ux, uy)
        _sx, _sy = ux, uy
    end
    function Aimbot.enable()
        Config.Aimbot = true
        if _bound then return end
        RunService:BindToRenderStep("LuaHook_Aimbot", Enum.RenderPriority.Camera.Value + 1, function(dt)
            pcall(step, dt)
        end)
        _bound = true
    end
    function Aimbot.disable()
        Config.Aimbot = false
        State.AimbotKeyHeld = false
        clearTarget()
        _sx, _sy, _fx, _fy = 0, 0, 0, 0
        _haveCam = false
        _auth = 1.0
        if _bound then
            pcall(function() RunService:UnbindFromRenderStep("LuaHook_Aimbot") end)
            _bound = false
        end
    end
    function Aimbot.unload() Aimbot.disable() end
end)()

-- 觸發
local Trigger = {}
do
    local _bound = false
    local _lastChar = nil
    local trigParams = RaycastParams.new()
    trigParams.FilterType = Enum.RaycastFilterType.Exclude
    local _filterChar = nil
    local function isHeadHit(part)
        if not part then return false end
        local n = part.Name
        for _, h in ipairs(HEAD_PARTS) do if n == h then return true end end
        return false
    end
    local function isInputActive(key)
        if key == "MB1" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
        if key == "MB2" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
        if key == "Always" then return true end
        local kc = Enum.KeyCode[key]
        if kc then return UIS:IsKeyDown(kc) end
        return false
    end
    local function askToShoot()
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        if not lf then return end
        pcall(function() lf:Input("StartShooting") end)
    end
    local function underCrosshair()
        local c = LP.Character
        if c ~= _filterChar then
            trigParams.FilterDescendantsInstances = { c }
            _filterChar = c
        end
        local cf = C.CFrame
        local res = W:Raycast(cf.Position, cf.LookVector * 400, trigParams)
        if not res or not res.Instance then return nil end
        local model = res.Instance:FindFirstAncestorOfClass("Model")
        if not model then return nil end
        local pl = Players:GetPlayerFromCharacter(model)
        if not pl or pl == LP then return nil end
        return pl, res.Instance
    end
    local function step()
        if not Config.Trigger then return end
        if not isInputActive(Config.TriggerKey) then _lastChar = nil return end
        local pl, hit = underCrosshair()
        if not pl then _lastChar = nil return end
        if Config.TeamCheck and isTeammate(pl) then _lastChar = nil return end
        if not isAlive(pl) then _lastChar = nil return end
        if Config.TriggerHeadOnly and not isHeadHit(hit) then _lastChar = nil return end
        _lastChar = pl.Character
        askToShoot()
    end
    function Trigger.enable()
        Config.Trigger = true
        if _bound then return end
        RunService:BindToRenderStep("LuaHook_Trigger", Enum.RenderPriority.Camera.Value + 2, function()
            pcall(step)
        end)
        _bound = true
    end
    function Trigger.disable()
        Config.Trigger = false
        _lastChar = nil
        if not _bound then return end
        pcall(function() RunService:UnbindFromRenderStep("LuaHook_Trigger") end)
        _bound = false
    end
    function Trigger.unload() Trigger.disable() end
end

-- ESP
local ESP = {}
;(function()
    local _renderConn = nil
    local _espFrame = 0
    local _lastRenderT = 0
    local _bboxCache = {}
    local _bboxFrameN = {}
    local _ctx = {}
    local BLACK = Color3.new(0, 0, 0)
    local WHITE = Color3.new(1, 1, 1)
    local NEON  = Color3.fromRGB(0, 229, 255)
    local HPBG = Color3.fromRGB(11, 15, 22)
    local HP_W = 3
    local HP_GAP = 5
    local PAD = 5
    local MIN_W = 8
    local MIN_H = 13
    local BOX_W_STUDS = 4 * 1000 / 1080
    local BOX_H_STUDS = 6.5 * 1000 / 1080
    local TEXT_FLOOR = 8
    local FACES = {}
    for _, n in ipairs({ "Code", "RobotoMono", "Gotham", "GothamBold", "Arial", "SourceSans" }) do
        local ok, f = pcall(function() return Enum.Font[n] end)
        if ok and f then FACES[n] = f end
    end
    if FACES.Code == nil then FACES.Code = Enum.Font.SourceSans end
    local function faceFor(name) return FACES[name] or FACES.Code end
    local function sizeFor(base, mul)
        local v = math.floor(base * (mul or 1) + 0.5)
        if v < TEXT_FLOOR then v = TEXT_FLOOR end
        return v
    end
    local function styleLabel(t, face, size)
        if typeof(face) == "EnumItem" then
            if t.Font ~= face then t.Font = face end
        else
            if t.FontFace ~= face then t.FontFace = face end
        end
        if t.TextSize ~= size then t.TextSize = size end
    end
    local _gui = nil
    local function espGui()
        if _gui and _gui.Parent then return _gui end
        local ok, g = pcall(function()
            local s = Instance.new("ScreenGui")
            s.Name = "\0" .. tostring(math.random(1e5, 1e6))
            s.IgnoreGuiInset = true
            s.ResetOnSpawn = false
            s.DisplayOrder = 99990
            s.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            local parent
            pcall(function() parent = gethui and gethui() end)
            if parent == nil then pcall(function() parent = game:GetService("CoreGui") end) end
            if parent == nil then parent = LP:FindFirstChildOfClass("PlayerGui") end
            s.Parent = parent
            return s
        end)
        if not ok or not g then return nil end
        _gui = g
        return _gui
    end
    local function mkFrame(parent, z)
        local f = Instance.new("Frame")
        f.BackgroundTransparency = 1
        f.BorderSizePixel = 0
        f.ZIndex = z or 1
        f.Parent = parent
        return f
    end
    local function mkLabel(parent, z, align)
        local t = Instance.new("TextLabel")
        t.BackgroundTransparency = 1
        t.BorderSizePixel = 0
        t.TextXAlignment = align or Enum.TextXAlignment.Center
        t.AutomaticSize = Enum.AutomaticSize.XY
        t.Size = UDim2.fromOffset(0, 0)
        t.ZIndex = z or 3
        t.TextColor3 = WHITE
        local st = Instance.new("UIStroke")
        st.Color = BLACK; st.Thickness = 1; st.Transparency = 0
        st.Parent = t
        t.Parent = parent
        return t
    end
    local function mkRing(parent, z, colour, thick)
        local f = mkFrame(parent, z)
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Position = UDim2.fromScale(0.5, 0.5)
        f.Size = UDim2.fromScale(1, 1)
        local s = Instance.new("UIStroke")
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Color = colour; s.Thickness = thick; s.Transparency = 0
        s.Parent = f
        return f, s
    end
    local function mkCorner(parent, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius or 0)
        c.Parent = parent
        return c
    end
    local function buildTree(o)
        local g = espGui(); if not g then return nil end
        local u = {}
        local root = mkFrame(g, 2)
        root.Visible = false
        root.Size = UDim2.fromOffset(MIN_W, MIN_H)
        u.root = root
        u.box = mkFrame(root, 3)
        u.box.Size = UDim2.fromScale(1, 1)
        local rMid, sMid = mkRing(u.box, 5, Config.ESPBoxColor or NEON, 1)
        u.boxStroke = sMid
        mkCorner(u.box, 2)
        u.box.Visible = false
        local glow = mkFrame(root, 2)
        glow.Size = UDim2.fromScale(1, 1)
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.Position = UDim2.fromScale(0.5, 0.5)
        local gs = Instance.new("UIStroke")
        gs.Color = Config.ESPBoxColor or NEON
        gs.Thickness = 3
        gs.Transparency = 0.85
        gs.Parent = glow
        mkCorner(glow, 3)
        u.glow = glow
        u.glowStroke = gs
        glow.Visible = false
        local hp = mkFrame(root, 4)
        hp.AnchorPoint = Vector2.new(1, 0)
        hp.Position = UDim2.new(0, -HP_GAP, 0, 0)
        hp.Size = UDim2.new(0, HP_W, 1, 0)
        hp.BackgroundTransparency = 0
        hp.BackgroundColor3 = HPBG
        hp.Visible = false
        mkCorner(hp, 2)
        u.hp = hp
        u.hpFill = mkFrame(hp, 6)
        u.hpFill.BackgroundTransparency = 0
        u.hpFill.BackgroundColor3 = WHITE
        u.hpFill.AnchorPoint = Vector2.new(0, 1)
        u.hpFill.Position = UDim2.fromScale(0, 1)
        u.hpFill.Size = UDim2.fromScale(1, 1)
        mkCorner(u.hpFill, 2)
        u.name = mkLabel(root, 7)
        u.name.AnchorPoint = Vector2.new(0.5, 1)
        u.name.Position = UDim2.new(0.5, 0, 0, -PAD)
        u.name.Visible = false
        u.info = mkLabel(root, 7)
        u.info.AnchorPoint = Vector2.new(0.5, 0)
        u.info.Position = UDim2.new(0.5, 0, 1, PAD)
        u.info.Visible = false
        return u
    end
    local function cleanESP(p)
        local o = State.ESPObjects[p]; if not o then return end
        if o.ui and o.ui.root then pcall(function() o.ui.root:Destroy() end) end
        _bboxCache[p] = nil
        _bboxFrameN[p] = nil
        State.ESPObjects[p] = nil
    end
    local function buildESP(player)
        if player == LP then return end
        cleanESP(player)
        local char = player.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local o = { root = root }
        o.ui = buildTree(o)
        State.ESPObjects[player] = o
    end
    local function bbox(char, player)
        local frame = _bboxFrameN[player] or -999
        if (_espFrame - frame) < 1 then
            local c = _bboxCache[player]
            if c then return c[1], c[2], c[3], c[4] end
            return nil
        end
        _bboxFrameN[player] = _espFrame
        _bboxCache[player] = nil
        local ok, pivot = pcall(function() return char:GetPivot().Position end)
        if not ok or pivot == nil then return nil end
        local sp = C:WorldToViewportPoint(pivot)
        local depth = sp.Z
        if depth <= 0.5 then return nil end
        local vpY = _ctx.vp and _ctx.vp.Y or 1080
        local tanHalf = math.tan(math.rad(C.FieldOfView) * 0.5)
        if tanHalf <= 0 then return nil end
        local scale = vpY / (2 * depth * tanHalf)
        local bs = Config.ESPBoxScale or 1
        local rawW = BOX_W_STUDS * scale * bs
        local rawH = BOX_H_STUDS * scale * bs
        if rawH > 4000 or rawW > 3000 then return nil end
        local x = math.floor(sp.X - rawW * 0.5)
        local y = math.floor(sp.Y - rawH * 0.5)
        local bw = math.floor(math.max(MIN_W, rawW))
        local bh = math.floor(math.max(MIN_H, rawH))
        _bboxCache[player] = { x, y, x + bw, y + bh }
        return x, y, x + bw, y + bh
    end
    local function renderPlayer(player, o)
        local ctx = _ctx
        local char = player.Character
        if not char or not o.root or not o.root.Parent then cleanESP(player); return end
        local rootPos = o.root.Position
        if not rootPos then cleanESP(player); return end
        if not o.ui then o.ui = buildTree(o); if not o.ui then return end end
        local u = o.ui
        local myRoot = ctx.myRoot
        local dist = (myRoot and myRoot.Position and rootPos)
            and (myRoot.Position - rootPos).Magnitude or 0
        if (Config.ESPTeamCheck and isTeammate(player)) or (not isAlive(player)) then
            u.root.Visible = false
            return
        end
        local minX, minY, maxX, maxY = bbox(char, player)
        if not minX then
            u.root.Visible = false
        else
            local w, h = maxX - minX, maxY - minY
            u.root.Position = UDim2.fromOffset(minX, minY)
            u.root.Size = UDim2.fromOffset(w, h)
            u.root.Visible = true
            local hp, mh, frac
            pcall(function() hp, mh = getHealth(player) end)
            if hp ~= nil then frac = math.clamp((mh or 0) > 0 and hp / mh or 0, 0, 1) end
            local pulse = 0.85 + 0.15 * math.sin(tick() * 3 + (player.UserId % 100))
            local hueShift = (tick() * 0.08 + (player.UserId % 360) / 360) % 1
            local dynamicColor = Color3.fromHSV(hueShift, 0.85, 1)
            local boxColor = Config.ESPBoxColor or NEON
            if Config.ESPRainbowBox then boxColor = dynamicColor end
            if Config.ESPBox then
                u.box.Visible = true
                u.boxStroke.Color = boxColor
                u.boxStroke.Thickness = Config.ESPBoxThickness
                u.glow.Visible = Config.ESPBoxGlow == true
                if u.glowStroke then
                    u.glowStroke.Color = boxColor
                    u.glowStroke.Transparency = 0.75 + 0.15 * pulse
                    u.glowStroke.Thickness = 3
                end
            else
                u.box.Visible = false
                u.glow.Visible = false
            end
            if Config.ESPHealth then
                u.hp.Visible = true
                u.hpFill.Size = UDim2.new(1, 0, math.clamp(frac or 1, 0, 1), 0)
                u.hpFill.BackgroundColor3 = hpRamp(frac or 1)
            else
                u.hp.Visible = false
            end
            if Config.ESPName then
                u.name.Visible = true
                styleLabel(u.name, ctx.face, sizeFor(Config.ESPTextSize or 14, 1))
                u.name.Text = (Config.ESPNameMode == "Username") and player.Name or player.DisplayName
                u.name.TextColor3 = Config.ESPNameColor
            else
                u.name.Visible = false
            end
            if Config.ESPDistance then
                u.info.Visible = true
                styleLabel(u.info, ctx.face, sizeFor(Config.ESPInfoTextSize or 12, 1))
                u.info.Text = ("%dm"):format(dist)
                u.info.TextColor3 = Config.ESPInfoColor
            else
                u.info.Visible = false
            end
        end
    end
    local function render()
        local _now = tick()
        if _now - _lastRenderT < 0.0083 then return end
        _lastRenderT = _now
        _espFrame = _espFrame + 1
        if not Config.ESP then
            for _, o in pairs(State.ESPObjects) do
                if o.ui and o.ui.root then o.ui.root.Visible = false end
            end
            return
        end
        local ctx = _ctx
        ctx.vp = C.ViewportSize
        ctx.myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        ctx.face = faceFor(Config.ESPFont or "Code")
        for player, o in pairs(State.ESPObjects) do
            pcall(renderPlayer, player, o)
        end
    end
    function ESP.rebuildAll()
        for p in pairs(State.ESPObjects) do cleanESP(p) end
        if not Config.ESP then return end
        for _, p in ipairs(getSafePlayers()) do
            if p ~= LP and p.Character then buildESP(p) end
        end
    end
    function ESP.enable()
        Config.ESP = true
        ESP.rebuildAll()
        if not _renderConn then _renderConn = RunService.RenderStepped:Connect(render) end
    end
    function ESP.disable()
        Config.ESP = false
        ESP.rebuildAll()
        if _renderConn then _renderConn:Disconnect(); _renderConn = nil end
    end
    function ESP.unload()
        if _renderConn then _renderConn:Disconnect(); _renderConn = nil end
        for p in pairs(State.ESPObjects) do cleanESP(p) end
        if _gui then pcall(function() _gui:Destroy() end); _gui = nil end
    end
    function ESP.init()
        for _, p in ipairs(getSafePlayers()) do
            if p ~= LP then
                p.CharacterAdded:Connect(function()
                    task.wait(0.5); if Config.ESP then buildESP(p) end
                end)
            end
        end
        Players.PlayerAdded:Connect(function(p)
            p.CharacterAdded:Connect(function()
                task.wait(0.5); if Config.ESP then buildESP(p) end
            end)
        end)
        Players.PlayerRemoving:Connect(function(p) cleanESP(p) end)
        if Config.ESP and not _renderConn then
            _renderConn = RunService.RenderStepped:Connect(render)
            ESP.rebuildAll()
        end
    end
end)()

pcall(ESP.init)
if Config.ESP then pcall(ESP.enable) end

-- Rage
local Rage = {}
;(function()
    local function hasLOS(fromPos, toPos, ignore)
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = ignore
        local res = W:Raycast(fromPos, toPos - fromPos, rp)
        if not res then return true end
        return (res.Position - toPos).Magnitude < 3
    end
    local function lookCF(fromPos, toPos)
        local dir = toPos - fromPos
        if dir.Magnitude < 1e-4 then dir = Vector3.new(0, -1, 0) end
        local up = Vector3.new(0, 1, 0)
        if math.abs(dir.Unit.Y) > 0.999 then up = Vector3.new(0, 0, 1) end
        return CFrame.lookAt(fromPos, fromPos + dir, up)
    end
    Rage._lookCF = lookCF
    local RAGE_CLAMP_FRAC = 0.30

    local function findTarget()
        local myChar = LP.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local cands = {}
        for _, p in ipairs(getSafePlayers()) do
            if p ~= LP and isAlive(p) and not (Config.TeamCheck and isTeammate(p)) then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local d = 9999
                local sane = myRoot ~= nil and hrp ~= nil
                if sane then d = (hrp.Position - myRoot.Position).Magnitude end
                if (not sane) or d <= (Config.MaxDistance or 1200) then
                    table.insert(cands, { p = p, hp = hum.Health, d = d })
                end
            end
        end
        if #cands == 0 then return nil end
        if Config.RageHPPriority then
            table.sort(cands, function(a, b)
                if math.abs(a.hp - b.hp) > 10 then return a.hp < b.hp end
                return a.d < b.d
            end)
        else
            table.sort(cands, function(a, b) return a.d < b.d end)
        end
        return cands[1].p
    end
    Rage._findTarget = findTarget

    local function itemIsMelee(item)
        if not item then return false end
        local viaInfo = false
        pcall(function()
            local info = item.Info
            if info == nil then return end
            if info.Type == "Melee" or info.Class == "Melee" then viaInfo = true return end
            if type(info.AttackReach) == "number" and info.MaxAmmo == nil then viaInfo = true end
        end)
        if viaInfo then return true end
        return false
    end
    Rage._itemIsMelee = itemIsMelee

    local function weaponReady(it)
        if not it then return false end
        local okE, equipping = pcall(function() return it:IsEquipping() end)
        if okE and equipping then return false end
        if (it._reload_cooldown or 0) > tick() then return false end
        if itemIsMelee(it) then return true end
        local okA, ammo = pcall(function() return it:Get("Ammo") end)
        if not okA then return true end
        return type(ammo) == "number" and ammo > 0
    end
    Rage._weaponReady = weaponReady

    local _shootEnum = nil
    local function polarFire(eyePos, aimPos, hh)
        local it = getEquippedItem()
        if not it then return 0 end
        pcall(function()
            it._shoot_cooldown = 0
            it._shoot_cooldown_no_ammo = 0
            it._last_shot = tick() - 1
        end)
        if _shootEnum == nil then
            pcall(function() _shootEnum = EnumLibrary:ToEnum("StartShooting") end)
        end
        if _shootEnum == nil then return 0 end
        if not UseItem then return 0 end
        local okId, objId = pcall(function() return it:Get("ObjectID") end)
        if not okId or not objId then return 0 end
        local eyeCF = lookCF(eyePos, aimPos)
        local muzzleCF = eyeCF - Vector3.new(0, Config.RageEyeMuzzleSep or 0.07, 0)
        local sent = 0
        local okLoop = pcall(function()
            for _ = 1, math.max(1, math.min(Config.RageTapsPerFrame or 1, Config.RageTaps or 6)) do
                local inner = {}
                SharedEncode.buildShotFields(inner, eyeCF, muzzleCF, hh, aimPos, true, RAGE_CLAMP_FRAC, 1.0)
                local env = { [utf8.char(1)] = inner }
                UseItem:FireServer(objId, _shootEnum, env, nil)
                sent = sent + 1
            end
        end)
        if okLoop then State.Shots = State.Shots + sent end
        return sent
    end

    local function meleeStrike(hpos, hh, tgt)
        local it = getEquippedItem()
        if it == nil then return false end
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        if lf == nil then return false end
        local sent = pcall(function() lf:Input("StartShooting") end)
        if sent then
            State.Shots = State.Shots + 1
            State.RageKnifeSwings = (State.RageKnifeSwings or 0) + 1
        end
        return sent
    end

    local RENDER_NAME = "LuaHook_Polar_Restore"
    local _voidCF = nil
    local _target = nil
    local _firing = false
    local _conn = nil
    local VOID_MIN_STEP = 25000
    local VOID_R_MIN = 110000
    local VOID_R_MAX = 140000
    local _preParkCF = nil
    local _hiding = false
    local _primeUntil = 0
    local PRIME_S = 0.07
    local HIDE_JITTER_MAX = 0.25
    local _deflectSince = 0
    local DEFLECT_MAX_HOLD = 1.5

    local function voidAxis()
        local v = math.random(VOID_R_MIN, VOID_R_MAX)
        if math.random(0, 1) == 0 then return -v end
        return v
    end
    local VOID_DEEP_AXIS = 1073741824
    local VOID_DEEP_JITTER = 0.4
    local _voidOrder = { 1, 2, 3 }
    local function voidDeep() return Config.RageVoidDepth ~= "shallow" end
    local function deepMag(allowNeg)
        local m = VOID_DEEP_AXIS * (1 + math.random() * VOID_DEEP_JITTER)
        if allowNeg and math.random(0, 1) == 1 then return -m end
        return m
    end
    local function rollVoidDeep()
        local ang = math.random() * math.pi * 2
        local r = math.random(1000, 1500)
        local x = math.cos(ang) * r
        local y = math.random(1000, 1500)
        local z = math.sin(ang) * r
        local o = _voidOrder
        o[1], o[2], o[3] = 1, 2, 3
        for i = 3, 2, -1 do
            local j = math.random(1, i)
            o[i], o[j] = o[j], o[i]
        end
        for i = 1, math.random(1, 3) do
            local axis = o[i]
            if axis == 1 then x = deepMag(true)
            elseif axis == 2 then y = deepMag(false)
            else z = deepMag(true) end
        end
        return CFrame.new(x, y, z)
    end
    local function rollVoid()
        if voidDeep() then return rollVoidDeep() end
        return CFrame.new(voidAxis(), math.random(VOID_R_MIN, VOID_R_MAX), voidAxis())
    end
    local function voidCFrame()
        local prev = _voidCF
        local cf = rollVoid()
        if prev then
            local tries = 0
            while tries < 8 and (cf.Position - prev.Position).Magnitude < VOID_MIN_STEP do
                cf = rollVoid()
                tries = tries + 1
            end
        end
        _voidCF = cf
        return cf
    end

    local function hide(hrp, status)
        _firing = false
        State.RageFiring = false
        State.RageStatus = status
        State.RageVoidActive = true
        _hiding = true
        _primeUntil = 0
        if _preParkCF == nil then _preParkCF = hrp.CFrame end
        pcall(function() hrp.CFrame = voidCFrame() end)
    end

    local function polarTick(ch, hrp)
        local tgt = _target
        if tgt and (not tgt.Parent or not tgt.Character or not isAlive(tgt) or isTeammate(tgt)) then tgt = nil end
        if not tgt then tgt = findTarget() end
        _target = tgt
        State.RageTarget = tgt
        if not tgt or not tgt.Character then return hide(hrp, "No target") end
        if isDeflecting(tgt) then
            local now = tick()
            if _deflectSince == 0 then _deflectSince = now end
            if now - _deflectSince < DEFLECT_MAX_HOLD then return hide(hrp, "Deflecting") end
        else
            _deflectSince = 0
        end
        local it = getEquippedItem()
        if not weaponReady(it) then
            if tick() - (State.RageReloadLast or 0) > 0.5 then
                State.RageReloadLast = tick()
                local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
                if lf then pcall(function() lf:Input("StartReloading") end) end
            end
            return hide(hrp, "Reloading")
        end
        local hh = tgt.Character:FindFirstChild("HitboxHead") or tgt.Character:FindFirstChild("Head")
        if not hh then return hide(hrp, "Hiding") end
        if _hiding then
            _hiding = false
            local extra = 0
            if Config.RageHideJitter ~= false then extra = math.random() * HIDE_JITTER_MAX end
            _primeUntil = tick() + PRIME_S + extra
        end
        local hpos = hh.Position
        if not isSanePos(hpos) then return hide(hrp, "Head voided") end
        State.RageFiring = true
        State.RageVoidActive = false
        _firing = true
        State.RageStatus = "Attacking"
        local melee = itemIsMelee(it)
        if melee and Config.RageKnifeBot ~= false then
            if meleeStrike(hpos, hh, tgt) then
                State.RageStatus = "Melee"
            else
                State.RageStatus = "Melee (cooldown)"
            end
        else
            polarFire(C.CFrame.Position, hpos, hh)
        end
    end

    local ORBIT_PRIME_S = 0.07
    local ORBIT_JITTER_MAX = 0.25
    local ORBIT_JUMP = 5
    local _orbHiding = true
    local _orbPrimeUntil = 0
    local _orbLastDisp = nil

    local function orbitVantage(aimPos, ignore, kf)
        State.OrbitAngle = ((State.OrbitAngle or 0) + 2.39996) % (math.pi * 2)
        local base = Config.RageCombatOrbitRadius or 60
        local radii = { base, base * 0.6, math.min(base * 1.5, 380) }
        for _, r in ipairs(radii) do
            for i = 0, 5 do
                local ang = State.OrbitAngle + i * (math.pi / 3)
                local jitter = 0
                if Config.RageCombatOrbitJitter then jitter = (math.random() - 0.5) * 14 end
                local h = (Config.RageCombatOrbitHeight or 8) + jitter
                local pos = Vector3.new(aimPos.X + math.cos(ang) * r,
                    math.max(aimPos.Y + h, kf + 6),
                    aimPos.Z + math.sin(ang) * r)
                if isSanePos(pos) and not posIsOOB(pos) and hasLOS(pos, aimPos, ignore) then
                    return pos
                end
            end
        end
        return nil
    end

    local function orbitVoid(hrp, status)
        State.RageStatus = status
        State.OrbitVantage = nil
        State.OrbitVantageUntil = 0
        State.RageFiring = false
        State.RageVoidActive = true
        _orbHiding = true
        _orbPrimeUntil = 0
        _orbLastDisp = nil
        if _preParkCF == nil then _preParkCF = hrp.CFrame end
        pcall(function() hrp.CFrame = voidCFrame() end)
    end

    local function flankPoint(tgt, hh)
        if not tgt or not tgt.Character or not hh then return nil end
        local thrp = tgt.Character:FindFirstChild("HumanoidRootPart")
        if not thrp then return nil end
        local look = thrp.CFrame.LookVector
        look = Vector3.new(look.X, 0, look.Z)
        if look.Magnitude < 1e-3 then return nil end
        local inv = -look.Unit
        local anchor = hh.Position
        local kf = killFloor()
        local dist = 3.0
        local ignore = { tgt.Character, LP.Character }
        local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = ignore
        local flank = anchor + inv * dist
        local wr = W:Raycast(anchor, inv * dist, rp)
        if wr then flank = wr.Position - inv * 0.5 end
        flank = Vector3.new(flank.X, math.max(flank.Y, kf + 3), flank.Z)
        if not hasLOS(flank, hh.Position, ignore) then return nil end
        return flank
    end

    local function orbitTick(ch, hrp, tgt)
        local kf = killFloor()
        if not tgt or not tgt.Character then return orbitVoid(hrp, "No target") end
        local tc = tgt.Character
        local hh = tc:FindFirstChild("HitboxHead") or tc:FindFirstChild("Head")
        if not hh or not isSanePos(hh.Position) then return orbitVoid(hrp, "Hiding") end
        if not weaponReady(getEquippedItem()) then
            if tick() - (State.RageReloadLast or 0) > 0.5 then
                State.RageReloadLast = tick()
                local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
                if lf then pcall(function() lf:Input("StartReloading") end) end
            end
            return orbitVoid(hrp, "Reloading")
        end
        local aimPos = hh.Position
        if posIsOOB(aimPos) or aimPos.Y < kf + 1 then return orbitVoid(hrp, "Hiding") end
        local ignore = { tc, LP.Character }
        local vantage, status = nil, nil
        local flank = flankPoint(tgt, hh)
        if flank then
            vantage = flank
            State.OrbitVantage = nil
            status = "Flank"
        else
            local held = State.OrbitVantage
            if (not held) or tick() >= (State.OrbitVantageUntil or 0) or not hasLOS(held, aimPos, ignore) then
                local v = orbitVantage(aimPos, ignore, kf)
                if v then
                    State.OrbitVantage = v
                    State.OrbitVantageUntil = tick() + (Config.RageOrbitDwell or 0.09)
                    held = v
                else held = nil end
            end
            if held then vantage = held; status = "Orbit" end
        end
        if not vantage or not isSanePos(vantage) or posIsOOB(vantage) then
            return orbitVoid(hrp, "Orbit (hiding)")
        end
        State.RageStatus = status or "Orbit"
        State.RageVoidActive = false
        local jumped = _orbLastDisp == nil or (vantage - _orbLastDisp).Magnitude > ORBIT_JUMP
        _orbLastDisp = vantage
        if _orbHiding or jumped then
            _orbHiding = false
            _orbPrimeUntil = tick() + ORBIT_PRIME_S + math.random() * ORBIT_JITTER_MAX
        end
        if _preParkCF == nil then _preParkCF = hrp.CFrame end
        pcall(function() hrp.CFrame = CFrame.new(vantage) end)
        if tick() < _orbPrimeUntil then
            State.RageFiring = false
            State.RageStatus = "Priming"
        else
            State.RageFiring = true
            local eye = vantage + Vector3.new(0, Config.RagePBEyeUp or 3, 0)
            polarFire(eye, aimPos, hh)
        end
    end

    local function restoreHome()
        local ch = LP.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        local back = _preParkCF
        _preParkCF = nil
        pcall(function()
            if back then hrp.CFrame = back end
        end)
    end

    function Rage.init() end

    function Rage.enable()
        Config.Rage = true
        if _conn then return end
        _firing = false
        pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
        RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.First.Value - 1000, function()
            restoreHome()
        end)
        _conn = RunService.Heartbeat:Connect(function(dt)
            if not Config.Rage then Rage.disable(); return end
            local ch = LP.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if not hrp or not hrp.Parent then return end
            if not inMatch() then
                _target = nil; _firing = false
                State.RageFiring = false
                State.RageTarget = nil
                State.RageStatus = "Lobby"
                return
            end
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then
                _firing = false
                State.RageFiring = false
                State.RageVoidActive = false
                State.RageStatus = "Dead"
                return
            end
            local tgt = _target
            if tgt and (not tgt.Parent or not tgt.Character or not isAlive(tgt)
                or (Config.TeamCheck and isTeammate(tgt))) then tgt = nil end
            if not tgt then tgt = findTarget() end
            State.RageTarget = tgt
            if (Config.RageMode or "Polar") == "Orbit" then
                orbitTick(ch, hrp, tgt)
            else
                _target = tgt
                polarTick(ch, hrp)
            end
        end)
    end

    function Rage.disable()
        Config.Rage = false
        if _conn then _conn:Disconnect(); _conn = nil end
        pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
        _firing = false
        restoreHome()
        _target = nil; _voidCF = nil
        State.RageFiring = false
        State.RageVoidActive = false
        State.RageTarget = nil
        State.RageInMatch = false
        State.RageStatus = "Idle"
    end

    function Rage.unload()
        Rage.disable()
    end
    Rage._encodeShot = SharedEncode.encodeShot
    Rage._buildShotFields = SharedEncode.buildShotFields
end)()

-- AutoQueue
local autoQueueThread = nil
local function autoQueueStop()
    if autoQueueThread then autoQueueThread = nil end
end
local function autoQueueStart()
    autoQueueStop()
    autoQueueThread = task.spawn(function()
        task.wait(Config.AutoQueueDelay or 2)
        while Config.AutoQueueEnabled and task.wait(1) do
            local success, result = pcall(function()
                local storage = game:GetService("ReplicatedStorage")
                local remotes = storage:WaitForChild("Remotes")
                local matchmaking = remotes:WaitForChild("Matchmaking")
                local joinqueue = matchmaking:WaitForChild("JoinQueue")
                if Config.AutoQueueRanked then
                    return joinqueue:InvokeServer(Config.AutoQueueMode or "1v1", true)
                else
                    return joinqueue:InvokeServer(Config.AutoQueueMode or "1v1")
                end
            end)
            if not success and not string.find(tostring(result):lower(), "already in queue") then
                autoQueueThread = nil
                break
            end
        end
    end)
end
task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.AutoQueueEnabled and not autoQueueThread then
            autoQueueStart()
        elseif not Config.AutoQueueEnabled and autoQueueThread then
            autoQueueStop()
        end
    end
end)

print("[v12.0] 第一段載入完成")
-- ============================================================
-- 第二段：Sky 系統 + GUI + 自訂準心（呼吸伸縮 + 四線同色彩虹）
-- 順序：Linoria → SkySystem 宣告 → GUI → CrosshairRenderer
-- ============================================================

local repo = 'https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/'
local Library, ThemeManager, SaveManager
local ok, err = pcall(function()
    local files, pending = {}, 3
    local urls = { 'Library.lua', 'addons/ThemeManager.lua', 'addons/SaveManager.lua' }
    for i = 1, 3 do
        task.spawn(function()
            local got, body = pcall(function() return game:HttpGet(repo .. urls[i]) end)
            if got and type(body) == 'string' and #body > 0 then files[i] = body end
            pending = pending - 1
        end)
    end
    local deadline = tick() + 20
    while pending > 0 and tick() < deadline do task.wait() end
    for i = 1, 3 do
        if files[i] == nil then error('failed to fetch ' .. urls[i], 0) end
    end
    local src = files[1]
    local patched, n = src:gsub('if not FetchIcons then', 'if not Icons then')
    if n > 0 then src = patched end
    Library      = loadstring(src)()
    ThemeManager = loadstring(files[2])()
    SaveManager  = loadstring(files[3])()
end)
if not ok or not Library then warn("[LuaHook] Linoria load failed:", err); return end

Library.IsMobile = isMobile
Library.ShowCustomCursor = false
pcall(function()
    Library.MainColor        = Color3.fromRGB(16, 18, 24)
    Library.BackgroundColor  = Color3.fromRGB(10, 12, 16)
    Library.AccentColor      = Color3.fromRGB(0, 229, 255)
    Library.OutlineColor     = Color3.fromRGB(35, 40, 50)
    Library.FontColor        = Color3.fromRGB(236, 240, 246)
end)

local okWin, Window = pcall(function()
    return Library:CreateWindow({
        Title = 'LuaHook v12.0',
        Center = true,
        AutoShow = false,
        TabPadding = 8,
        MenuFadeTime = 0.25,
        NotifySide = 'Right',
        Resizable = true,
        UnlockMouseWhileOpen = true,
    })
end)
if not okWin or not Window then warn("[LuaHook] GUI window failed:", Window); return end

-- ============================================================
-- Sky 系統（三層防護：事件 + 屬性 + 快速輪詢）
-- ============================================================
local SkySystem = {}
;(function()
    local Lighting    = game:GetService("Lighting")
    local RunService  = game:GetService("RunService")
    local Players     = game:GetService("Players")
    local LP          = Players.LocalPlayer
    local W           = game:GetService("Workspace")

    local SKY = {
        Space     = { Bk="rbxassetid://159454299",  Dn="rbxassetid://159454296",  Ft="rbxassetid://159454293",  Lf="rbxassetid://159454286",  Rt="rbxassetid://159454300",  Up="rbxassetid://159454288" },
        Sunset    = { Bk="rbxassetid://264908339",  Dn="rbxassetid://264907909",  Ft="rbxassetid://264909420",  Lf="rbxassetid://264909758",  Rt="rbxassetid://264908886",  Up="rbxassetid://264907379" },
        Clouds    = { Bk="rbxassetid://570557514",  Dn="rbxassetid://570557775",  Ft="rbxassetid://570557559",  Lf="rbxassetid://570557620",  Rt="rbxassetid://570557672",  Up="rbxassetid://570557727" },
        Storm     = { Bk="rbxassetid://255027929",  Dn="rbxassetid://255027967",  Ft="rbxassetid://255027923",  Lf="rbxassetid://255027938",  Rt="rbxassetid://255027946",  Up="rbxassetid://255027960" },
        Winter    = { Bk="rbxassetid://402229526",  Dn="rbxassetid://402229596",  Ft="rbxassetid://402229293",  Lf="rbxassetid://402229368",  Rt="rbxassetid://402229417",  Up="rbxassetid://402229564" },
        Vaporwave = { Bk="rbxassetid://1417494030", Dn="rbxassetid://1417494146", Ft="rbxassetid://1417494253", Lf="rbxassetid://1417494402", Rt="rbxassetid://1417494499", Up="rbxassetid://1417494643" },
    }
    SkySystem.SkyboxOrder = { "Off", "Space", "Sunset", "Clouds", "Storm", "Winter", "Vaporwave" }

    local _sky = nil
    local _skyConn = nil          -- Lighting.ChildAdded 守衛
    local _repopConn = nil        -- 快速輪詢
    local _lastRepopT = 0
    local _lastPlace = game.PlaceId
    local _origSkies = {}

    local function hideMapSkies()
        for _, c in ipairs(Lighting:GetChildren()) do
            if c:IsA("Sky") and not c:GetAttribute("WX_Custom") then
                table.insert(_origSkies, c)
                pcall(function() c.Parent = nil end)
            end
        end
    end

    local function restoreMapSkies()
        for i = #_origSkies, 1, -1 do
            local c = _origSkies[i]
            if c and c.Parent == nil then
                pcall(function() c.Parent = Lighting end)
            end
            _origSkies[i] = nil
        end
    end

    local function buildSky(preset)
        local set = SKY[preset]
        if not set then return end
        hideMapSkies()
        local s = Instance.new("Sky")
        s.Name = "_wxSky"
        s:SetAttribute("WX_Custom", true)
        s.SkyboxBk = set.Bk
        s.SkyboxDn = set.Dn
        s.SkyboxFt = set.Ft
        s.SkyboxLf = set.Lf
        s.SkyboxRt = set.Rt
        s.SkyboxUp = set.Up
        if Config.SkyboxHideCelestial then
            s.SunAngularSize     = 0
            s.MoonAngularSize    = 0
            s.StarCount          = 0
            s.CelestialBodiesShown = false
        else
            s.CelestialBodiesShown = true
        end
        s.Parent = Lighting
        _sky = s
    end

    -- 檢查 Sky 是否還在，不見就重建
    local function repopSky()
        if not Config.SkyboxPreset or Config.SkyboxPreset == "Off" then return end
        -- 檢查是否還在
        if _sky and _sky.Parent == Lighting then
            -- 順便檢查有沒有別的 Sky 搶進來
            local hasForeign = false
            for _, c in ipairs(Lighting:GetChildren()) do
                if c:IsA("Sky") and not c:GetAttribute("WX_Custom") then
                    hasForeign = true
                    break
                end
            end
            if not hasForeign then return end
        end
        -- 重建
        _sky = nil
        local preset = Config.SkyboxPreset
        hideMapSkies()
        buildSky(preset)
    end

    local function startSkyGuard()
        if _skyConn then return end
        _skyConn = Lighting.ChildAdded:Connect(function(c)
            if c:IsA("Sky") and not c:GetAttribute("WX_Custom")
               and Config.SkyboxPreset and Config.SkyboxPreset ~= "Off" then
                table.insert(_origSkies, c)
                pcall(function() c.Parent = nil end)
                -- 立刻重建我們的
                task.defer(repopSky)
            end
        end)
        -- 監聽 Sky 被移除
        Lighting.ChildRemoved:Connect(function(c)
            if c:IsA("Sky") and c:GetAttribute("WX_Custom") then
                _sky = nil
                task.defer(repopSky)
            end
        end)
    end

    local function stopSkyGuard()
        if _skyConn then _skyConn:Disconnect(); _skyConn = nil end
    end

    -- 快速輪詢 0.1 秒
    local function startRepop()
        if _repopConn then return end
        _repopConn = RunService.Heartbeat:Connect(function()
            if not Config.SkyboxPreset or Config.SkyboxPreset == "Off" then return end
            local now = tick()
            if now - _lastRepopT < 0.1 then return end
            _lastRepopT = now
            -- 換 place 偵測
            if game.PlaceId ~= _lastPlace then
                _lastPlace = game.PlaceId
                _sky = nil
                _origSkies = {}
            end
            repopSky()
        end)
    end

    local function stopRepop()
        if _repopConn then _repopConn:Disconnect(); _repopConn = nil end
    end

    local function clearSky()
        if _sky then pcall(function() _sky:Destroy() end); _sky = nil end
        restoreMapSkies()
    end

    function SkySystem.setSkybox(preset)
        if preset and not SKY[preset] then preset = "Off" end
        Config.SkyboxPreset = preset
        clearSky()
        if preset == "Off" or preset == nil then
            stopSkyGuard()
            stopRepop()
            return
        end
        buildSky(preset)
        startSkyGuard()
        startRepop()
    end

    function SkySystem.toggleCelestial(hide)
        Config.SkyboxHideCelestial = hide
        if _sky then
            if hide then
                _sky.SunAngularSize     = 0
                _sky.MoonAngularSize    = 0
                _sky.StarCount          = 0
                _sky.CelestialBodiesShown = false
            else
                _sky.SunAngularSize     = 11
                _sky.MoonAngularSize    = 11
                _sky.StarCount          = 3000
                _sky.CelestialBodiesShown = true
            end
        end
    end

    -- 角色重生監聽（換圖時角色會被重建）
    LP.CharacterAdded:Connect(function()
        if Config.SkyboxPreset and Config.SkyboxPreset ~= "Off" then
            task.wait(0.3)
            _sky = nil
            repopSky()
            task.wait(1)
            repopSky()
        end
    end)

    -- Workspace 屬性變動（有些圖會換 Workspace 屬性觸發重建）
    W:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        if Config.SkyboxPreset and Config.SkyboxPreset ~= "Off" then
            task.defer(repopSky)
        end
    end)

    function SkySystem.init()
        if Config.SkyboxPreset and Config.SkyboxPreset ~= "Off" then
            pcall(SkySystem.setSkybox, Config.SkyboxPreset)
        end
    end

    function SkySystem.unload()
        clearSky()
        stopSkyGuard()
        stopRepop()
        Config.SkyboxPreset = "Off"
    end

    getgenvFn().__LH_SkySystem = SkySystem
end)()

-- ============================================================
-- GUI
-- ============================================================
local Tabs = {
    Combat = Window:AddTab('戰鬥'),
    ESP    = Window:AddTab('透視'),
    Rage   = Window:AddTab('狂暴'),
    Gun    = Window:AddTab('槍械'),
    HUD    = Window:AddTab('準心'),
    World  = Window:AddTab('世界'),
    Auto   = Window:AddTab('自動'),
    Settings = Window:AddTab('設定'),
}
local Options = Library.Options or {}
local Toggles = Library.Toggles or {}
Library.Options = Options
Library.Toggles = Toggles

local function bindModeToggle(pickerName, configKey, onSet)
    local modeOpt = Options[pickerName .. "_Mode"]
    local keyOpt  = Options[pickerName]
    if not keyOpt then return end
    local function apply()
        local keys = keyOpt.Value
        if type(keys) == "table" then keys = keys[1] end
        local mode = modeOpt and modeOpt.Value or "Toggle"
        local H = getgenvFn().__LH_KeybindHold
        if not H then return end
        H.unbind(pickerName)
        if keys and keys ~= "None" and keys ~= "" then
            if mode == "Hold" then
                H.bind(pickerName, keys,
                    function() onSet(true) end,
                    function() onSet(false) end)
            else
                H.bind(pickerName, keys,
                    function() onSet(not (Config[configKey] == true)) end,
                    function() end)
            end
        end
    end
    if keyOpt.OnChanged then keyOpt:OnChanged(apply) end
    if modeOpt and modeOpt.OnChanged then modeOpt:OnChanged(apply) end
    task.defer(apply)
end

-- 戰鬥
do
    local L = Tabs.Combat:AddLeftGroupbox('靜默自瞄')
    L:AddToggle('Silent_Enabled', { Text = '啟用靜默自瞄', Default = false, Callback = function(v) Config.SilentEnabled = v end })
        :AddKeyPicker('Silent_Key', { Text = '靜默自瞄', Default = 'None', Mode = 'Toggle', NoUI = true, SyncToggleState = true })
    L:AddDropdown('Silent_Key_Mode', { Values = {'Toggle','Hold'}, Default = 'Toggle', Text = '快捷鍵模式', Callback = function() end })
    L:AddToggle('Silent_AutoShoot', { Text = '自動開槍', Default = false, Callback = function(v) Config.SilentAutoShoot = v end })
    L:AddToggle('Silent_WallCheck', { Text = '牆壁檢測', Default = true, Callback = function(v) Config.SilentWallCheck = v end })
    L:AddToggle('Silent_360', { Text = '360 度模式', Default = false, Callback = function(v) Config.Silent360 = v end })
    L:AddDropdown('Silent_HitPart', { Text = '命中部位', Default = 'Head', Values = {"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso"}, Callback = function(v) Config.SilentHitPart = v end })
    L:AddSlider('Silent_FOV', { Text = '視野半徑', Default = 150, Min = 10, Max = 800, Rounding = 0, Compact = true, Callback = function(v) Config.SilentFOV = v end })
    L:AddSlider('Silent_HitChance', { Text = '命中率 %', Default = 100, Min = 0, Max = 100, Rounding = 0, Compact = true, Callback = function(v) Config.SilentHitChance = v end })
    bindModeToggle('Silent_Key', 'SilentEnabled', function(v) Config.SilentEnabled = v end)

    local R = Tabs.Combat:AddRightGroupbox('自瞄')
    R:AddToggle('Aimbot', { Text = '啟用自瞄', Default = false, Callback = function(v) if v then Aimbot.enable() else Aimbot.disable() end end })
        :AddKeyPicker('AimbotKey_Picker', { Text = '自瞄', Default = 'None', Mode = 'Toggle', NoUI = true, SyncToggleState = true })
    R:AddDropdown('AimbotKey_Picker_Mode', { Values = {'Toggle','Hold'}, Default = 'Toggle', Text = '快捷鍵模式', Callback = function() end })
    R:AddDropdown('AimbotKey', { Values = {'Always','MB2','MB1','C','E','F','Q','V','X','LeftShift','LeftAlt','LeftControl'}, Default = 'MB2', Text = '啟動方式', Callback = function(v) Config.AimbotKey = v end })
    R:AddSlider('AimbotSmoothness', { Text = '平滑度 (0=硬鎖)', Default = 0, Min = 0, Max = 100, Rounding = 0, Callback = function(v) Config.AimbotSmoothness = v end })
    R:AddSlider('AimbotFOVDeg', { Text = '視野 度', Default = 20, Min = 1, Max = 180, Rounding = 1, Callback = function(v) Config.AimbotFOVDeg = v end })
    R:AddDropdown('AimbotTargetPart', { Values = {'Best','Head','Torso','Closest'}, Default = 'Best', Text = '目標骨骼', Callback = function(v) Config.AimbotTargetPart = v end })
    R:AddToggle('AimbotVisCheck', { Text = '可見性檢測', Default = true, Callback = function(v) Config.AimbotVisCheck = v end })
    bindModeToggle('AimbotKey_Picker', 'Aimbot', function(v) if v then Aimbot.enable() else Aimbot.disable() end end)

    local TB = Tabs.Combat:AddRightGroupbox('觸發機器人')
    TB:AddToggle('Trigger', { Text = '啟用觸發', Default = false, Callback = function(v) if v then Trigger.enable() else Trigger.disable() end end })
        :AddKeyPicker('Trigger_Key', { Text = '觸發', Default = 'None', Mode = 'Toggle', NoUI = true, SyncToggleState = true })
    TB:AddDropdown('Trigger_Key_Mode', { Values = {'Toggle','Hold'}, Default = 'Toggle', Text = '快捷鍵模式', Callback = function() end })
    TB:AddDropdown('TriggerKey', { Values = {'Always','MB2','MB1','C','E','F','Q','V','X','LeftShift','LeftAlt','LeftControl'}, Default = 'Always', Text = '啟動方式', Callback = function(v) Config.TriggerKey = v end })
    TB:AddToggle('TriggerHeadOnly', { Text = '只打頭', Default = false, Callback = function(v) Config.TriggerHeadOnly = v end })
    bindModeToggle('Trigger_Key', 'Trigger', function(v) if v then Trigger.enable() else Trigger.disable() end end)

    local T = Tabs.Combat:AddLeftGroupbox('目標選擇')
    T:AddToggle('TeamCheck', { Text = '隊伍檢測', Default = true, Callback = function(v) Config.TeamCheck = v end })
end

-- 透視
do
    local L = Tabs.ESP:AddLeftGroupbox('透視 & 方框')
    L:AddToggle('ESP', { Text = '啟用透視', Default = true, Callback = function(v) if v then ESP.enable() else ESP.disable() end end })
    L:AddToggle('ESPTeamCheck', { Text = '隊伍檢測', Default = true, Callback = function(v) Config.ESPTeamCheck = v end })
    L:AddToggle('ESPBox', { Text = '方框', Default = true, Callback = function(v) Config.ESPBox = v end })
    L:AddToggle('ESPBoxGlow', { Text = '霓虹光暈', Default = true, Callback = function(v) Config.ESPBoxGlow = v end })
    L:AddToggle('ESPRainbowBox', { Text = '彩虹方框', Default = false, Callback = function(v) Config.ESPRainbowBox = v end })
    L:AddSlider('ESPBoxThickness', { Text = '方框粗細', Default = 1, Min = 1, Max = 4, Rounding = 0, Callback = function(v) Config.ESPBoxThickness = math.floor(v) end })
    L:AddSlider('ESPBoxScale', { Text = '方框大小', Default = 1, Min = 0.6, Max = 1.6, Rounding = 2, Callback = function(v) Config.ESPBoxScale = v end })
    L:AddToggle('ESPHealth', { Text = '血條', Default = true, Callback = function(v) Config.ESPHealth = v end })
    local R = Tabs.ESP:AddRightGroupbox('文字')
    R:AddToggle('ESPName', { Text = '玩家名字', Default = true, Callback = function(v) Config.ESPName = v end })
    R:AddDropdown('ESPNameMode', { Values = {'Display','Username'}, Default = 'Display', Text = '名字來源', Callback = function(v) Config.ESPNameMode = v end })
    R:AddToggle('ESPDistance', { Text = '距離', Default = true, Callback = function(v) Config.ESPDistance = v end })
    R:AddSlider('ESPTextSize', { Text = '名字大小', Default = 14, Min = 9, Max = 24, Rounding = 0, Callback = function(v) Config.ESPTextSize = math.floor(v) end })
    R:AddLabel('名字顏色'):AddColorPicker('ESPNameColor', { Default = Config.ESPNameColor, Callback = function(v) Config.ESPNameColor = v end })
    R:AddLabel('方框顏色'):AddColorPicker('ESPBoxColor', { Default = Config.ESPBoxColor, Callback = function(v) Config.ESPBoxColor = v end })
end

-- 狂暴
do
    local RageTab = Tabs.Rage
    local CORE = RageTab:AddLeftGroupbox('核心')
    CORE:AddToggle('Rage_Enabled', { Text = '啟用狂暴', Default = false, Callback = function(v) if v then Rage.enable() else Rage.disable() end end })
        :AddKeyPicker('Rage_Key', { Text = '狂暴', Default = 'None', Mode = 'Toggle', NoUI = true, SyncToggleState = true })
    CORE:AddDropdown('Rage_Key_Mode', { Values = {'Toggle','Hold'}, Default = 'Toggle', Text = '快捷鍵模式', Callback = function() end })
    CORE:AddDropdown('RageMode', { Values = {'Polar','Orbit'}, Default = 'Polar', Text = '狂暴模式', Callback = function(v) Config.RageMode = v; if Config.Rage then Rage.enable() end end })
    CORE:AddToggle('Rage_HPPriority', { Text = '優先低血量目標', Default = true, Callback = function(v) Config.RageHPPriority = v end })
    CORE:AddDivider('引擎')
    CORE:AddDropdown('Rage_VoidDepth', { Values = {'shallow','deep'}, Default = 'deep', Text = '躲藏深度', Callback = function(v) Config.RageVoidDepth = v end })
    CORE:AddDropdown('Rage_RestoreMode', { Values = {'auto','none','render','kerp'}, Default = 'auto', Text = '傳送模式', Callback = function(v) Config.RageRestoreMode = v end })
    bindModeToggle('Rage_Key', 'Rage', function(v) if v then Rage.enable() else Rage.disable() end end)

    local ORBIT = RageTab:AddLeftGroupbox('繞圈專屬')
    ORBIT:AddSlider('RageCombatOrbitRadius', { Text = '繞圈半徑', Default = 60, Min = 20, Max = 380, Rounding = 0, Callback = function(v) Config.RageCombatOrbitRadius = v end })
    ORBIT:AddSlider('RageOrbitDwell', { Text = '停留時間', Default = 0.30, Min = 0.10, Max = 0.60, Rounding = 2, Callback = function(v) Config.RageOrbitDwell = v end })
    ORBIT:AddSlider('RageCombatOrbitHeight', { Text = '繞圈高度', Default = 8, Min = 0, Max = 40, Rounding = 0, Callback = function(v) Config.RageCombatOrbitHeight = v end })
    ORBIT:AddToggle('RageCombatOrbitJitter', { Text = '垂直抖動', Default = true, Callback = function(v) Config.RageCombatOrbitJitter = v end })
    ORBIT:AddSlider('RagePBEyeUp', { Text = '眼睛高度', Default = 3, Min = 1, Max = 12, Rounding = 0, Callback = function(v) Config.RagePBEyeUp = v end })

    local WEP = RageTab:AddRightGroupbox('武器')
    WEP:AddDropdown('Rage_OnEmpty', { Values = {'Swap','Reload'}, Default = 'Swap', Text = '彈藥耗盡時', Callback = function(v) Config.RageOnEmpty = v end })
    WEP:AddDropdown('Rage_PreferredSlot', { Values = {'Primary','Secondary','Melee'}, Default = 'Primary', Text = '偏好欄位', Callback = function(v) Config.RagePreferredSlot = v end })
    WEP:AddSlider('Rage_Taps', { Text = '每次開火發數', Default = 6, Min = 1, Max = 8, Rounding = 0, Compact = true, Callback = function(v) Config.RageTaps = v end })
    WEP:AddSlider('Rage_TapsPerFrame', { Text = '每幀發數', Default = 1, Min = 1, Max = 6, Rounding = 0, Compact = true, Callback = function(v) Config.RageTapsPerFrame = v end })
    WEP:AddSlider('Rage_EyeMuzzleSep', { Text = '眼-口分離', Default = 0.07, Min = 0, Max = 1, Rounding = 2, Compact = true, Callback = function(v) Config.RageEyeMuzzleSep = v end })

    local MELEE = RageTab:AddRightGroupbox('近戰')
    MELEE:AddToggle('Rage_KnifeBot', { Text = '小刀機器人', Default = true, Callback = function(v) Config.RageKnifeBot = v end })
end

-- 槍械
do
    local G = Tabs.Gun:AddLeftGroupbox('槍械修改')
    G:AddToggle('Gun_NoCooldown', { Text = '無冷卻', Default = false, Callback = function(v) Config.NoCooldown = v end })
    G:AddToggle('Gun_NoSpread', { Text = '無散射', Default = false, Callback = function(v) Config.NoSpread = v end })
    G:AddToggle('Gun_NoRecoil', { Text = '無後座', Default = false, Callback = function(v) Config.NoRecoil = v end })
    G:AddToggle('Gun_MaxAccuracy', { Text = '最大精準', Default = false, Callback = function(v) Config.MaxAccuracy = v end })
    G:AddToggle('Gun_RapidAttack', { Text = '快速攻擊（近戰）', Default = false, Callback = function(v) Config.RapidAttack = v end })
    G:AddToggle('Gun_NoMuzzleFlash', { Text = '無槍口火光', Default = false, Callback = function(v) Config.NoMuzzleFlash = v; updateMuzzleFlash() end })
end

-- 準心
do
    local L = Tabs.HUD:AddLeftGroupbox('自訂準心')
    L:AddToggle('FXCrosshair', { Text = '啟用自訂準心', Default = Config.FXCrosshair,
        Callback = function(v) Config.FXCrosshair = v end })
    local D = L:AddDependencyBox()
    D:AddDropdown('FXCrosshairStyle', {
        Values = {'Cross','X','T','Dot','Chevron'},
        Default = Config.FXCrosshairStyle,
        Text = '樣式',
        Callback = function(v) Config.FXCrosshairStyle = v end })
    D:AddLabel('顏色'):AddColorPicker('FXCrosshairColor', {
        Default = Config.FXCrosshairColor,
        Callback = function(v) Config.FXCrosshairColor = v end })
    D:AddToggle('FXCrosshairDot', {
        Text = '中心點', Default = Config.FXCrosshairDot,
        Callback = function(v) Config.FXCrosshairDot = v end })
    D:AddToggle('FXCrosshairOutline', {
        Text = '黑色外框', Default = Config.FXCrosshairOutline,
        Callback = function(v) Config.FXCrosshairOutline = v end })
    D:AddSlider('FXCrosshairGap', {
        Text = '內距', Default = Config.FXCrosshairGap,
        Min = 0, Max = 20, Rounding = 0,
        Callback = function(v) Config.FXCrosshairGap = math.floor(v) end })
    D:AddSlider('FXCrosshairLen', {
        Text = '每段長度', Default = Config.FXCrosshairLen,
        Min = 2, Max = 24, Rounding = 0,
        Callback = function(v) Config.FXCrosshairLen = math.floor(v) end })
    D:AddSlider('FXCrosshairThickness', {
        Text = '粗細', Default = Config.FXCrosshairThickness,
        Min = 1, Max = 4, Rounding = 0,
        Callback = function(v) Config.FXCrosshairThickness = math.floor(v) end })

    D:AddDivider('旋轉')
    D:AddToggle('FXCrosshairSpin', {
        Text = '持續旋轉', Default = Config.FXCrosshairSpin,
        Callback = function(v) Config.FXCrosshairSpin = v end })
    D:AddSlider('FXCrosshairSpinSpeed', {
        Text = '旋轉速度', Default = Config.FXCrosshairSpinSpeed,
        Min = 0.1, Max = 4, Rounding = 1,
        Callback = function(v) Config.FXCrosshairSpinSpeed = v end })

    D:AddDivider('自動呼吸伸縮（無需開火）')
    D:AddToggle('FXCrosshairBounce', {
        Text = '啟用呼吸伸縮', Default = Config.FXCrosshairBounce,
        Callback = function(v) Config.FXCrosshairBounce = v end })
    D:AddSlider('FXCrosshairBounceAmt', {
        Text = '伸縮幅度', Default = Config.FXCrosshairBounceAmt,
        Min = 1, Max = 20, Rounding = 0,
        Callback = function(v) Config.FXCrosshairBounceAmt = math.floor(v) end })
    D:AddSlider('FXCrosshairBreathSpeed', {
        Text = '呼吸速度（次/秒）', Default = Config.FXCrosshairBreathSpeed,
        Min = 0.1, Max = 4, Rounding = 1,
        Callback = function(v) Config.FXCrosshairBreathSpeed = v end })

    D:AddDivider('彩色（四條線一起變色）')
    D:AddToggle('FXCrosshairRainbow', {
        Text = '彩色（彩虹）', Default = Config.FXCrosshairRainbow,
        Callback = function(v) Config.FXCrosshairRainbow = v end })
    D:AddSlider('FXCrosshairRainbowSpeed', {
        Text = '彩色流動速度', Default = Config.FXCrosshairRainbowSpeed,
        Min = 0.02, Max = 1, Rounding = 2,
        Callback = function(v) Config.FXCrosshairRainbowSpeed = v end })

    D:AddDivider('命中加長')
    D:AddToggle('FXCrosshairHitPop', {
        Text = '命中加長', Default = Config.FXCrosshairHitPop,
        Callback = function(v) Config.FXCrosshairHitPop = v end })

    D:AddDivider('狙擊鏡')
    D:AddToggle('FXCrosshairSniper', {
        Text = '開鏡時才顯示', Default = Config.FXCrosshairSniper,
        Callback = function(v) Config.FXCrosshairSniper = v end })

    D:SetupDependencies({ { Toggles.FXCrosshair, true } })
end

-- 世界（Sky）
do
    local L = Tabs.World:AddLeftGroupbox('天空盒')
    L:AddDropdown('WX_Sky', {
        Values = SkySystem.SkyboxOrder,
        Default = Config.SkyboxPreset or 'Off',
        Text = '天空盒預設',
        Callback = function(v) SkySystem.setSkybox(v) end })
    L:AddToggle('WX_HideCelestial', {
        Text = '隱藏天體（日/月/星）', Default = Config.SkyboxHideCelestial,
        Callback = function(v) SkySystem.toggleCelestial(v) end })
    L:AddButton({
        Text = '還原遊戲天空盒',
        Func = function()
            SkySystem.setSkybox('Off')
            if Options.WX_Sky then pcall(function() Options.WX_Sky:SetValue('Off') end) end
        end })
end

-- 自動
do
    local L = Tabs.Auto:AddLeftGroupbox('自動排隊')
    L:AddToggle('AutoQueue_Enabled', { Text = '自動 1v1', Default = false, Callback = function(v) Config.AutoQueueEnabled = v end })
    L:AddDropdown('AutoQueue_Mode', { Text = '模式', Default = '1v1', Values = {'1v1','2v2','3v3','4v4','5v5'}, Callback = function(v) Config.AutoQueueMode = v end })
    L:AddToggle('AutoQueue_Ranked', { Text = '排名模式', Default = false, Callback = function(v) Config.AutoQueueRanked = v end })
    L:AddSlider('AutoQueue_Delay', { Text = '延遲 秒', Default = 2, Min = 0, Max = 30, Rounding = 1, Compact = true, Callback = function(v) Config.AutoQueueDelay = v end })
end

-- 設定
do
    local L = Tabs.Settings:AddLeftGroupbox('選單')
    L:AddDropdown('GUIToggleKey', {
        Values = {'RightShift','LeftShift','RightControl','LeftControl','RightAlt','LeftAlt','F1','F2','F3','F4','F5','F6','F7','F8','F9','F10','F11','F12','Insert','Delete','Home','End','PageUp','PageDown','CapsLock','Tab'},
        Default = 'RightShift', Text = '介面開關鍵', Callback = function() end
    })
    L:AddButton({ Text = '卸載腳本 (需雙擊)', DoubleClick = true, Func = function()
        pcall(function()
            if getgenvFn().__LH_restoreAllHooks then
                getgenvFn().__LH_restoreAllHooks()
            end
        end)
        pcall(function()
            if getgenvFn().__LH_KeybindHold then
                getgenvFn().__LH_KeybindHold.unbindAll()
            end
        end)
        pcall(function()
            if getgenvFn().__LH_CrosshairRenderer then
                getgenvFn().__LH_CrosshairRenderer.destroy()
            end
        end)
        pcall(function()
            if getgenvFn().__LH_SkySystem then
                getgenvFn().__LH_SkySystem.unload()
            end
        end)
        pcall(function() ESP.unload() end)
        pcall(function() Aimbot.unload() end)
        pcall(function() Trigger.unload() end)
        pcall(function() Rage.unload() end)
        if muzzleFlashConn then muzzleFlashConn:Disconnect() end
        if shared._LH_GunOrig and GunModule then
            if setreadonly then pcall(setreadonly, GunModule, false) end
            GunModule.StartShooting = shared._LH_GunOrig
        end
        if shared._LH_SpreadOrig and GameplayUtility then
            if setreadonly then pcall(setreadonly, GameplayUtility, false) end
            GameplayUtility.GetSpread = shared._LH_SpreadOrig
        end
        if shared._LH_MeleeOrig and MeleeModule then
            if setreadonly then pcall(setreadonly, MeleeModule, false) end
            MeleeModule.StartShooting = shared._LH_MeleeOrig
        end
        Library:Unload()
        _G["\76\72"] = nil
    end })
    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local kp = Options.GUIToggleKey
        if kp and kp.Value and kp.Value ~= 'None'
           and Enum.KeyCode[kp.Value] and input.KeyCode == Enum.KeyCode[kp.Value] then
            pcall(function() Library:Toggle() end)
        end
    end)
end

task.spawn(function()
    pcall(function()
        ThemeManager:SetLibrary(Library)
        SaveManager:SetLibrary(Library)
        SaveManager:IgnoreThemeSettings()
        SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
        ThemeManager:SetFolder('v3hub')
        SaveManager:SetFolder('v3hub/rivals')
        SaveManager:BuildConfigSection(Tabs.Settings)
        ThemeManager:ApplyToTab(Tabs.Settings)
        SaveManager:LoadAutoloadConfig()
    end)
end)

-- ============================================================
-- 自訂準心繪製層（呼吸伸縮 + 四條線同色彩虹）
-- ============================================================
local CrosshairRenderer = {}
;(function()
    local CoreGui      = game:GetService("CoreGui")
    local RunService   = game:GetService("RunService")
    local Players      = game:GetService("Players")
    local LP           = Players.LocalPlayer
    local Camera       = workspace.CurrentCamera

    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        Camera = workspace.CurrentCamera
    end)

    local BLACK = Color3.new(0, 0, 0)
    local WHITE = Color3.new(1, 1, 1)

    local _gui = nil
    local _lines, _linesBlk  = {}, {}
    local _chDot, _chDotBlk  = nil, nil
    local _conn = nil
    local _started = false

    local _fx = {
        breathT = 0,
        rotBase = 0,
        hue     = 0,
        lastHits = 0,
        popT = -10,
    }

    local DIAG    = { Vector2.new(1, 1), Vector2.new(-1, 1), Vector2.new(1, -1), Vector2.new(-1, -1) }
    local PLUS    = { Vector2.new(0, -1), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(-1, 0) }
    local INV_SQ2 = 0.70710678

    local function ensureGui()
        if _gui and _gui.Parent then return _gui end
        local g = Instance.new("ScreenGui")
        g.Name = "_lh_xhair_" .. tostring(math.random(1e5, 1e6))
        g.IgnoreGuiInset = true
        g.ResetOnSpawn   = false
        g.DisplayOrder   = 99997
        g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        local ok = pcall(function() g.Parent = (gethui and gethui()) or CoreGui end)
        if not ok or not g.Parent then
            pcall(function() g.Parent = LP:FindFirstChildOfClass("PlayerGui") end)
        end
        _gui = g
        return g
    end

    local function mkLine(parent, color, z)
        local f = Instance.new("Frame")
        f.BackgroundColor3 = color
        f.BorderSizePixel  = 0
        f.AnchorPoint      = Vector2.new(0.5, 0.5)
        f.Visible          = false
        f.ZIndex           = z or 5
        f.Parent           = parent
        return f
    end

    local function mkDot(parent, color, z)
        local f = Instance.new("Frame")
        f.BackgroundColor3 = color
        f.BorderSizePixel  = 0
        f.AnchorPoint      = Vector2.new(0.5, 0.5)
        f.Visible          = false
        f.ZIndex           = z or 5
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = f
        f.Parent = parent
        return f
    end

    local function allocate()
        if _lines[1] then return end
        local g = ensureGui()
        for i = 1, 4 do _linesBlk[i] = mkLine(g, BLACK, 4) end
        for i = 1, 4 do _lines[i]    = mkLine(g, WHITE, 5) end
        _chDotBlk = mkDot(g, BLACK, 5)
        _chDot    = mkDot(g, WHITE, 6)
    end

    local function hideAll()
        if _lines then
            for i = 1, #_lines do
                if _lines[i] then _lines[i].Visible = false end
                if _linesBlk[i] then _linesBlk[i].Visible = false end
            end
        end
        if _chDot then _chDot.Visible = false end
        if _chDotBlk then _chDotBlk.Visible = false end
    end

    local function isScoped()
        local lf = nil
        pcall(function()
            if Rivals and Rivals.Fighter then lf = Rivals.Fighter.LocalFighter end
        end)
        if not lf or not lf.EquippedItem then return false end
        local it = lf.EquippedItem
        local cur, pct = nil, nil
        pcall(function() cur = it.ViewModel and it.ViewModel.CurrentAimValue end)
        pcall(function() pct = it.Info and it.Info.AimScopePercent end)
        if type(cur) == "number" then
            if type(pct) == "number" then return cur >= pct end
            return cur >= 1
        end
        local aiming = nil
        pcall(function() aiming = it:Get("IsAiming") end)
        if aiming == nil then return true end
        return aiming == true
    end

    local function applyLine(f, fromX, fromY, toX, toY, color, thickness)
        if not f then return end
        local dx, dy = toX - fromX, toY - fromY
        local len = math.sqrt(dx * dx + dy * dy)
        if len < 0.5 then f.Visible = false; return end
        f.Position               = UDim2.fromOffset(
            math.floor((fromX + toX) * 0.5),
            math.floor((fromY + toY) * 0.5))
        f.Size                   = UDim2.fromOffset(math.floor(len + 0.5), thickness)
        f.Rotation               = math.deg(math.atan2(dy, dx))
        f.BackgroundColor3       = color
        f.BackgroundTransparency = 0
        f.Visible                = true
    end

    local function update(dt)
        if not Config.FXCrosshair and not Config.FXCrosshairSniper then
            hideAll()
            return
        end

        local crossOn  = Config.FXCrosshair == true
        local sniperOn = Config.FXCrosshairSniper == true
        if not crossOn and not (sniperOn and isScoped()) then
            hideAll()
            return
        end

        allocate()

        local vp = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
        local cx, cy = vp.X * 0.5, vp.Y * 0.5

        local style = Config.FXCrosshairStyle or "Cross"
        local gap   = Config.FXCrosshairGap or 4
        local len   = Config.FXCrosshairLen or 7
        local th    = Config.FXCrosshairThickness or 2
        local col   = Config.FXCrosshairColor or WHITE
        local outl  = Config.FXCrosshairOutline ~= false

        -- 持續旋轉
        if Config.FXCrosshairSpin then
            _fx.rotBase = (_fx.rotBase + (Config.FXCrosshairSpinSpeed or 1.0) * 360 * dt) % 360
        else
            if _fx.rotBase ~= 0 then
                _fx.rotBase = _fx.rotBase + (0 - _fx.rotBase) * math.min(dt * 8, 1)
                if math.abs(_fx.rotBase) < 0.5 then _fx.rotBase = 0 end
            end
        end

        -- 自動呼吸伸縮
        local breathAmt = 0
        if Config.FXCrosshairBounce then
            local speed = Config.FXCrosshairBreathSpeed or 0.8
            local range = Config.FXCrosshairBounceAmt or 6
            _fx.breathT = _fx.breathT + dt * speed
            local s = (math.sin(_fx.breathT * math.pi * 2) + 1) * 0.5
            breathAmt = s * range
        end
        local gapEff = gap + breathAmt

        -- 彩虹：整組同一個色相
        local useRainbow = Config.FXCrosshairRainbow
        if useRainbow then
            _fx.hue = (_fx.hue + dt * (Config.FXCrosshairRainbowSpeed or 0.15)) % 1
        end
        local sharedCol = col
        if useRainbow then
            sharedCol = Color3.fromHSV(_fx.hue, 1, 1)
        end

        -- 命中加長
        if Config.FXCrosshairHitPop ~= false then
            local h = State and State.Hits or 0
            if h ~= _fx.lastHits then
                _fx.lastHits = h
                _fx.popT = tick()
            end
            len = len + 2 * (1 - math.clamp((tick() - _fx.popT) / 0.06, 0, 1))
        end

        local rotDeg = ((Config.FXCrosshairAngle or 0) + _fx.rotBase) % 360
        local rotRad = math.rad(rotDeg)
        local cosR, sinR = math.cos(rotRad), math.sin(rotRad)

        local isX       = style == "X"
        local isT       = style == "T"
        local isDotOnly = style == "Dot"
        local isChevron = style == "Chevron"

        for i = 1, 4 do
            local l  = _lines[i]
            local lb = _linesBlk[i]

            local hide = isDotOnly
                or (isT and i == 1)
                or (isChevron and i > 2)

            if hide then
                if l  then l.Visible  = false end
                if lb then lb.Visible = false end
            else
                local nx, ny
                if isChevron then
                    local sx = (i == 1) and -1 or 1
                    nx, ny = sx * 0.707, 0.707
                elseif isX then
                    nx, ny = DIAG[i].X * INV_SQ2, DIAG[i].Y * INV_SQ2
                else
                    nx, ny = PLUS[i].X, PLUS[i].Y
                end
                local rnx = nx * cosR - ny * sinR
                local rny = nx * sinR + ny * cosR
                local fromX = cx + rnx * gapEff
                local fromY = cy + rny * gapEff
                local toX   = cx + rnx * (gapEff + len)
                local toY   = cy + rny * (gapEff + len)

                if outl and lb then
                    applyLine(lb, fromX - 1, fromY - 1, toX - 1, toY - 1, BLACK, th + 2)
                else
                    if lb then lb.Visible = false end
                end
                applyLine(l, fromX, fromY, toX, toY, sharedCol, th)
            end
        end

        local showDot = isDotOnly or (Config.FXCrosshairDot ~= false)
        if showDot then
            local r = isDotOnly and (th + 1) or math.max(th * 0.5 + 0.5, 1)
            if _chDotBlk then
                if outl then
                    local rr = math.ceil(r + 1)
                    _chDotBlk.Position = UDim2.fromOffset(math.floor(cx - rr), math.floor(cy - rr))
                    _chDotBlk.Size     = UDim2.fromOffset(rr * 2, rr * 2)
                    _chDotBlk.BackgroundColor3 = BLACK
                    _chDotBlk.Visible  = true
                else
                    _chDotBlk.Visible = false
                end
            end
            if _chDot then
                local rr = math.ceil(r)
                _chDot.Position = UDim2.fromOffset(math.floor(cx - rr), math.floor(cy - rr))
                _chDot.Size     = UDim2.fromOffset(rr * 2, rr * 2)
                _chDot.BackgroundColor3 = sharedCol
                _chDot.Visible  = true
            end
        else
            if _chDot then _chDot.Visible = false end
            if _chDotBlk then _chDotBlk.Visible = false end
        end
    end

    function CrosshairRenderer.start()
        if _started then return end
        _started = true
        allocate()
        if not _conn then
            _conn = RunService.RenderStepped:Connect(function(dt)
                if not _started then return end
                pcall(update, dt)
            end)
        end
    end

    function CrosshairRenderer.stop()
        if not _started then return end
        _started = false
        if _conn then _conn:Disconnect(); _conn = nil end
        hideAll()
    end

    function CrosshairRenderer.destroy()
        CrosshairRenderer.stop()
        if _gui then pcall(function() _gui:Destroy() end); _gui = nil end
        _lines, _linesBlk = {}, {}
        _chDot, _chDotBlk = nil, nil
    end

    function CrosshairRenderer.init()
        pcall(CrosshairRenderer.start)
    end

    getgenvFn().__LH_CrosshairRenderer = CrosshairRenderer
end)()

pcall(CrosshairRenderer.init)
pcall(SkySystem.init)
pcall(Rage.init)

Library:Notify('v12.0 完整版載入完成（準心 + Sky）', 4)
_G["\76\72"] = Library
