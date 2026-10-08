-- ============================================================
-- LuaHook v12.0 — 整合版
-- 反封鎖 + Linoria 框架 + 靜默自瞄 + 自瞄 + 觸發 + 隊伍檢測 + ESP
-- ============================================================

-- ============ 反封鎖 ============
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

W:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    C = W.CurrentCamera
end)

do
    if getgenvFn and hookfunction and newcclosure and getrenv then
        getgenvFn().__LH_SetmtBP = game
        local ok = pcall(function()
            local oldsetmt
            local l1 = { hits = 0 }
            getgenvFn().__LH_L1 = l1
            local rawget_, rawlen_, type_ = rawget, rawlen, type
            oldsetmt = hookfunction(getrenv().setmetatable, newcclosure(function(t, mt)
                if type_(mt) == "table" and rawget_(mt, "__mode") == "kv"
                   and type_(t) == "table" and rawlen_(t) == 4
                   and type_(rawget_(t, 1)) == "table"
                   and rawget_(t, 2) == 1
                   and rawget_(t, 3) == "String"
                   and type_(rawget_(t, 4)) == "userdata" then
                    l1.hits = l1.hits + 1
                    return oldsetmt({ 1, 2, 3 }, {})
                end
                return oldsetmt(t, mt)
            end))
        end)
        if not ok then getgenvFn().__LH_SetmtBP = nil end
    end
end

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
end

local function nukeConnections()
    if not getconnections then return end
    pcall(function()
        for _, conn in ipairs(getconnections(LP.CharacterAdded)) do
            if not checkcaller() then conn:Disable() end
        end
    end)
    pcall(function()
        for _, conn in ipairs(getconnections(LP.PlayerGui.ChildAdded)) do
            if not checkcaller() then conn:Disable() end
        end
    end)
end
nukeConnections()

RS.DescendantAdded:Connect(function(obj)
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        local n = obj.Name:lower()
        if n:find("exploit") or n:find("cheat") or n:find("detect") or n:find("ban") or
           n:find("flag") or n:find("validate") or n:find("anticheat") or n:find("ac_") then
            pcall(function() obj:Destroy() end)
        end
    end
end)

LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    nukeConnections()
end)

if hookmetamethod then
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", function(self, key)
        if checkcaller() and key == "Kick" and self == LP then
            return function() end
        end
        return oldIndex(self, key)
    end)
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

task.spawn(function()
    if not hookfunction or not getgc or not getfenv then return end
    pcall(function()
        local rf = game:GetService("ReplicatedFirst")
        local tgt = rf:WaitForChild("LocalScript3", 10)
        local gc = getgc(false)
        for i = 1, #gc do
            local fn = gc[i]
            if type(fn) ~= "function" then continue end
            local ok1, env = pcall(getfenv, fn)
            if not ok1 or type(env) ~= "table" then continue end
            local ok2, scr = pcall(function() return rawget(env, "script") end)
            if not ok2 or not scr or typeof(scr) ~= "Instance" then continue end
            if scr ~= tgt then continue end
            local ok4, consts = pcall(debugLib.getconstants, fn)
            if not ok4 or type(consts) ~= "table" then continue end
            for j = 1, #consts do
                local c = consts[j]
                if type(c) == "string" and (c:find("TakeTheL") or c:find("ban") or c:find("kick")) then
                    pcall(function() hookfunction(fn, function() end) end)
                    break
                end
            end
        end
    end)
end)

pcall(function()
    local fakeEv = Instance.new("RemoteEvent")
    fakeEv.Name = "ClientAlert"
    fakeEv.Parent = LP
end)

-- ============ 基礎框架 ============
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

-- ============ 工具 ============
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

local function worldToScreen(pos, cam)
    local c = cam or C
    if not c then return Vector2.new(0, 0), false end
    local ok, v, on = pcall(function() return c:WorldToViewportPoint(pos) end)
    if not ok or not v then return Vector2.new(0, 0), false end
    return Vector2.new(v.X, v.Y), on
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

-- ============ 設定 ============
local Config = {
    SilentEnabled = false, SilentHitPart = "Head", SilentHitChance = 100, SilentFOV = 150,
    SilentAutoShoot = false, SilentFollowMuzzle = false, SilentWallCheck = true,
    Silent360 = false, SilentJitter = true, SilentAvoidDeflect = false,
    SilentStickiness = 0.05, SilentMultipoint = false, SilentMultipointCount = 5,
    SilentTorsoFallback = false, SilentBodyMix = 25, SilentJitterDeg = 1.5,
    Aimbot = false, AimbotVisCheck = true, AimbotKey = "MB2",
    AimbotSmoothness = 0, AimbotSmoothnessX = 0, AimbotSmoothnessY = 0, AimbotLinkAxes = true,
    AimbotJumpDamping = 40, AimbotCancelSprings = true,
    AimbotCurvedFlick = false, AimbotCurvedIntensity = 0.35,
    AimbotTrackAssist = 100, AimbotFOVDeg = 20, AimbotMaxSpeed = 0,
    AimbotDeadzoneDeg = 0, AimbotSwitchDeg = 2, AimbotStickiness = 0.15,
    AimbotForgetTime = 0.2, AimbotTargetPart = "Best", AimbotPriority = "Crosshair",
    AimbotSkipImmune = true, AimbotPrediction = false, AimbotShotOverride = false,
    AimbotShowFOV = false, AimbotShowLock = false, AimbotDebug = false,
    AimbotReactionMs = 0, AimbotNoiseDeg = 0, AimbotOvershoot = 0, AimbotDirectCamera = false,
    Trigger = false, TriggerKey = "Always", TriggerDelayMs = 0, TriggerRefireMs = 0,
    TriggerHeadOnly = false, TriggerMaxDist = 400, TriggerScopeCheck = false,
    TeamCheck = true, MaxDistance = math.huge,
    ESP = true, ESPTeamCheck = true, ESPMaxDistance = math.huge, ESPMaxPlayers = 0,
    ESPFont = "Code", ESPTextSize = 14, ESPInfoTextSize = 12, ESPHealthTextSize = 11,
    ESPTextScale = 1, ESPTextCasing = 1, ESPDistanceScaling = true, ESPDistanceScalingRef = 50,
    ESPCasingThickness = 1, ESPBoxScale = 1,
    ESPBox = true, ESPBoxStyle = "Full Box", ESPBoxBrackets = false, ESPCornerLength = 0.28,
    ESPBoxFill = false, ESPBoxThickness = 1,
    ESPName = true, ESPDistance = true, ESPWeapon = false,
    ESPHealth = true, ESPHealthNumberMode = "OnDamage",
    ESPSkeleton = false, ESPSkeletonThickness = 1,
    ESPChams = false,
    ESPTracers = false, ESPTracerThickness = 1, ESPTracerOrigin = "Bottom",
    ESPArrows = false,
    ESPFlagStaring = false, ESPFlagDeflect = true, ESPFlagShield = true, ESPFlagInvincible = true, ESPFlagLowHP = true,
    ESPHeadDot = false, ESPHeadDotSize = 4,
    ESPBoxColorMode = "Solid", ESPBoxColor = Color3.fromRGB(255, 255, 255),
    ESPBoxGradA = Color3.fromRGB(255, 59, 78), ESPBoxGradB = Color3.fromRGB(255, 194, 75),
    ESPBoxFillColor = Color3.fromRGB(255, 59, 78),
    ESPHealthColorMode = "Ramp", ESPHealthColor = Color3.fromRGB(61, 224, 122),
    ESPHealthGradA = Color3.fromRGB(255, 68, 54), ESPHealthGradB = Color3.fromRGB(61, 224, 122),
    ESPNameColorMode = "Solid", ESPNameColor = Color3.fromRGB(255, 255, 255),
    ESPNameGradA = Color3.fromRGB(255, 255, 255), ESPNameGradB = Color3.fromRGB(255, 194, 75),
    ESPInfoColorMode = "Solid", ESPInfoColor = Color3.fromRGB(255, 255, 255),
    ESPInfoGradA = Color3.fromRGB(255, 255, 255), ESPInfoGradB = Color3.fromRGB(255, 158, 75),
    ESPFlagColorMode = "PerFlag", ESPFlagColor = Color3.fromRGB(255, 194, 75),
    ESPFlagGradA = Color3.fromRGB(255, 194, 75), ESPFlagGradB = Color3.fromRGB(255, 70, 85),
    ESPSkeletonColorMode = "Solid", ESPSkeletonColor = Color3.fromRGB(255, 255, 255),
    ESPSkeletonGradA = Color3.fromRGB(255, 255, 255), ESPSkeletonGradB = Color3.fromRGB(120, 180, 255),
    ESPTracerColorMode = "Solid", ESPTracerColor = Color3.fromRGB(255, 255, 255),
    ESPTracerGradA = Color3.fromRGB(255, 255, 255), ESPTracerGradB = Color3.fromRGB(255, 59, 78),
    ESPMarkColorMode = "Solid", ESPMarkColor = Color3.fromRGB(255, 255, 255),
    ESPMarkGradA = Color3.fromRGB(255, 255, 255), ESPMarkGradB = Color3.fromRGB(255, 194, 75),
    ESPGradientSpeed = 0, ESPGradientRotBox = 0, ESPGradientRotText = 90,
    ESPHeadDotColor = Color3.fromRGB(255, 255, 255),
    ESPChamsFillColor = Color3.fromRGB(255, 59, 78),
    ESPChamsOutlineColor = Color3.fromRGB(255, 255, 255),
    ESPChamsStyle = "Shade", ESPChamsVisSplit = true,
    ColorEnemy = Color3.fromRGB(255, 59, 78), ColorTeam = Color3.fromRGB(53, 215, 199),
    ColorEnemyOcc = Color3.fromRGB(168, 85, 96), ColorTeamOcc = Color3.fromRGB(92, 153, 147),
    ColorVisible = Color3.fromRGB(41, 224, 255),
    ESPBoxTransparency = 0, ESPBoxFillTransparency = 0.75,
    ESPNameTransparency = 0, ESPHealthTransparency = 0.1,
    ESPSkeletonTransparency = 0.2, ESPTracerTransparency = 0.35,
    ESPHeadDotTransparency = 0, ESPChamsFillTransparency = 0.6, ESPChamsOutlineTransparency = 0,
    ESPRadar = false, ESPRadarSize = 200, ESPRadarRange = 150, ESPRadarRotate = true,
    ESPRadarVisSplit = true, ESPRadarInset = 24, ESPRadarGrid = true, ESPRadarSweep = false,
    ESPFadeIn = true, ESPArrowDistFade = true, ESPArrowDistLabel = false,
    ESPLookLine = false, ESPLookLineLength = 8,
    ESPHealthSmooth = true, ESPHealthGhost = true, ESPDeclutter = true,
    ESPPeekAlert = false, ESPThreatCount = false, ESPPrimaryEmphasis = false,
    ESPHealTick = false, ESPNameHealthUnderline = false, ESPLockChevron = false,
    ESPNameMode = "Display",
}

local State = {
    SilentLastTarget = nil,
    Shots = 0, Hits = 0,
    AimbotTarget = nil, AimbotPart = nil,
    AimbotLastTarget = nil, AimbotLastTargetTime = 0,
    AimbotKeyHeld = false, AimbotFlickActive = false,
    ESPObjects = {},
    RageFiring = false,
}

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
                    if visibleOK then
                        local d = (part.Position - myRoot.Position).Magnitude
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

-- ============ 自瞄 ============
local Aimbot = {}
;(function()
    local TAU = math.pi * 2
    local D2R = math.pi / 180
    local R2D = 180 / math.pi
    local MAX_TAU = 0.30
    local RETAIN_MUL = 1.6
    local STICKY_MEM = 2.0
    local FF_TAU = 0.05
    local FF_MAX = 12
    local UNIT_MAX = 2000
    local RAMP_TIME = 0.15
    local PITCH_LIMIT = 1.5690509975429023
    local CAL_MIN = 1.5
    local CAL_FAST_N = 8
    local BAND_LO = 0.05
    local BAND_HI = 6.0
    local OSC_ERR = 0.02
    local RUNAWAY_ERR = 1.0
    local SEED_MX = -0.008726646259971648
    local SEED_MY = -0.006719517620178168
    local SEED_DX = 1.0
    local SEED_DY = 1.0
    local _bound = false
    local _mouseMove = mousemoverel
    local _tgt, _part = nil, nil
    local _prevTgt = nil
    local _acquireAt = 0
    local _lastSeenAt = 0
    local _ramp = 0
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
    local _flickActive = false
    local _flickT = 0
    local _flickDur = 0.15
    local _flickCtrl1Y, _flickCtrl1P = 0, 0
    local _flickCtrl2Y, _flickCtrl2P = 0, 0
    local _auth = 1.0
    local _flips = 0
    local _errEma = 0
    local _lastSign = nil
    local _drive = 0
    local _trips = 0
    local _calOff = false
    local _lastFOV = 0
    local _errDeg = 0
    local _path = "none"
    local _ctl, _ctlTried = nil, false

    local function wrapPi(a) return (a + math.pi) % TAU - math.pi end
    local function yawOf(v) return math.atan2(-v.X, -v.Z) end
    local function pitchOf(v) return math.asin(math.clamp(v.Y, -1, 1)) end
    local function angTo(cf, pos)
        local d = pos - cf.Position
        local m = d.Magnitude
        if m < 1e-4 then return 0 end
        return math.acos(math.clamp(cf.LookVector:Dot(d) / m, -1, 1))
    end
    local function minJerk(s)
        s = math.clamp(s, 0, 1)
        return s * s * s * (10 + s * (-15 + 6 * s))
    end
    local function bezier(p0, p1, p2, p3, t)
        local it = 1 - t
        return it * it * it * p0 + 3 * it * it * t * p1 + 3 * it * t * t * p2 + t * t * t * p3
    end
    local function isValidAimTarget(player)
        if not player or player == LP then return false end
        if Config.TeamCheck and isTeammate(player) then return false end
        if not isAlive(player) then return false end
        return true
    end
    local function firstVisible(char, list, skip)
        for _, n in ipairs(list) do
            local p = char:FindFirstChild(n)
            if p and p ~= skip and p:IsA("BasePart") and isVisible(p.Position) then return p end
        end
        return nil
    end
    local function resolveBest(char, primary)
        if not char then return primary end
        if primary and isVisible(primary.Position) then return primary end
        return firstVisible(char, HEAD_PARTS, primary)
            or firstVisible(char, TORSO_PARTS, primary)
            or primary
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
        if Config.AimbotDirectCamera or touchOnly then
            if not _ctlTried then
                _ctlTried = true
                task.spawn(function()
                    local ok, m = pcall(function()
                        return require(LP.PlayerScripts.Controllers.CameraController)
                    end)
                    if ok and type(m) == "table" and typeof(m.Rotation) == "Vector2"
                       and type(m.ApplyRotationDelta) == "function" then
                        _ctl = m
                        _gx, _gy = SEED_DX, SEED_DY
                        _sdx, _sdy = SEED_DX, SEED_DY
                        _nx, _ny = 0, 0
                    end
                end)
            end
            if _ctl then return "direct" end
        end
        return "none"
    end
    local function quant(v, frac)
        local w = v + frac
        local n = (w >= 0) and math.floor(w + 0.5) or math.ceil(w - 0.5)
        return n, w - n
    end
    local function emit(ux, uy)
        if _path == "mouse" then pcall(_mouseMove, ux, uy)
        elseif _path == "direct" and _ctl then
            pcall(function() _ctl:ApplyRotationDelta(Vector2.new(uy, ux)) end)
        end
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
        _errDeg = 0
        _flips, _errEma, _lastSign, _drive = 0, 0, nil, 0
        _flickActive = false
        State.AimbotTarget = nil
        State.AimbotPart = nil
        State.AimbotFlickActive = false
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
        local fov = C.FieldOfView
        if math.abs(fov - _lastFOV) > 0.5 then
            _lastFOV = fov
            _nx, _ny = 0, 0
        end
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
        if (Config.AimbotTargetPart or "Best") == "Best" then
            part = resolveBest(tgt.Character, part) or part
        end
        if tgt ~= _prevTgt then
            _acquireAt = now
            _ramp = 0
            _haveTgt = false
            _ffy, _ffp = 0, 0
            _prevTgt = tgt
            _flickActive = false
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
        _errDeg = math.sqrt(errYaw * errYaw + errPit * errPit) * R2D
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
        if (Config.AimbotReactionMs or 0) > 0
           and (now - _acquireAt) * 1000 < Config.AimbotReactionMs then return end
        if (Config.AimbotDeadzoneDeg or 0) > 0 then
            local m = math.sqrt(errYaw * errYaw + errPit * errPit)
            if m < Config.AimbotDeadzoneDeg * D2R then return end
        end
        local smoothX = Config.AimbotLinkAxes and (Config.AimbotSmoothness or 0) or (Config.AimbotSmoothnessX or Config.AimbotSmoothness or 0)
        local smoothY = Config.AimbotLinkAxes and (Config.AimbotSmoothness or 0) or (Config.AimbotSmoothnessY or Config.AimbotSmoothness or 0)
        smoothX = math.clamp(smoothX, 0, 100)
        smoothY = math.clamp(smoothY, 0, 100)
        local isHardLock = (smoothX == 0 and smoothY == 0)
        local aErr = math.sqrt(errYaw * errYaw + errPit * errPit)
        _errEma = _errEma + (aErr - _errEma) * math.clamp(dt / 0.15, 0, 1)
        _drive = _drive + dt
        local sPos = (errYaw >= 0)
        if _lastSign ~= nil and sPos ~= _lastSign then _flips = _flips + 1 end
        _lastSign = sPos
        _flips = _flips * math.exp(-dt / 0.25)
        if _flips >= 4 and _errEma > OSC_ERR and not isHardLock then
            _auth = math.max(0.15, _auth * 0.5)
            _flips = 0
        else
            _auth = math.min(1, _auth + dt * 0.3)
        end
        local avgSmooth = (smoothX + smoothY) * 0.5
        if _errEma > RUNAWAY_ERR and _drive > (0.15 + (avgSmooth / 100) * MAX_TAU * 3) and not isHardLock then
            _auth = math.max(0.08, _auth * 0.5)
            _gx, _gy = _sdx, _sdy
            _nx, _ny = 0, 0
            _drive = 0
            _trips = _trips + 1
            if _trips >= 2 then _calOff = true end
        end
        local alphaX = 1
        if smoothX > 0 then alphaX = (1 - math.exp(-dt / ((smoothX / 100) * MAX_TAU))) * _auth end
        local alphaY = 1
        if smoothY > 0 then alphaY = (1 - math.exp(-dt / ((smoothY / 100) * MAX_TAU))) * _auth end
        local cy = errYaw * alphaX
        local cp = errPit * alphaY
        if Config.AimbotCurvedFlick and _errDeg > 3.0 and not isHardLock then
            if not _flickActive then
                _flickActive = true
                _flickT = 0
                _flickDur = math.clamp((_errDeg / 90) * 0.22 + 0.08, 0.08, 0.35)
                local intensity = (Config.AimbotCurvedIntensity or 0.35) * (_errDeg * D2R)
                local normY, normP = -errPit / (aErr + 1e-4), errYaw / (aErr + 1e-4)
                local curveSign = ((math.floor(now * 10) % 2 == 0) and 1 or -1)
                _flickCtrl1Y = normY * intensity * curveSign
                _flickCtrl1P = normP * intensity * curveSign
                _flickCtrl2Y = normY * (intensity * 0.7) * curveSign
                _flickCtrl2P = normP * (intensity * 0.7) * curveSign
            end
            _flickT = math.min(_flickDur, _flickT + dt)
            local prog = _flickT / _flickDur
            local sJerk = minJerk(prog)
            local p1Y = errYaw * 0.33 + _flickCtrl1Y
            local p1P = errPit * 0.33 + _flickCtrl1P
            local p2Y = errYaw * 0.66 + _flickCtrl2Y
            local p2P = errPit * 0.66 + _flickCtrl2P
            cy = bezier(0, p1Y, p2Y, errYaw, sJerk) * alphaX
            cp = bezier(0, p1P, p2P, errPit, sJerk) * alphaY
            if prog >= 1.0 or _errDeg < 1.0 then _flickActive = false end
        else
            _flickActive = false
        end
        State.AimbotFlickActive = _flickActive
        local ff = (Config.AimbotTrackAssist or 100) / 100
        if ff > 0 and not isHardLock then
            cy = cy + _ffy * dt * ff
            cp = cp + _ffp * dt * ff
        end
        local nz = Config.AimbotNoiseDeg or 0
        if nz > 0 then
            local n = nz * D2R * dt
            cy = cy + (math.random() - 0.5) * 2 * n
            cp = cp + (math.random() - 0.5) * 2 * n
        end
        local cap = Config.AimbotMaxSpeed or 0
        if cap > 0 then
            local m = math.sqrt(cy * cy + cp * cp)
            local lim = cap * D2R * dt
            if m > lim then local k = lim / m; cy, cp = cy * k, cp * k end
        end
        cp = math.clamp(curPit + cp, -PITCH_LIMIT, PITCH_LIMIT) - curPit
        if _gx == 0 or _gy == 0 then return end
        local ux, uy = cy / _gx, cp / _gy
        local um = math.max(math.abs(ux), math.abs(uy))
        if um > UNIT_MAX then local k = UNIT_MAX / um; ux, uy = ux * k, uy * k end
        if _path == "mouse" then
            ux, _fx = quant(ux, _fx)
            uy, _fy = quant(uy, _fy)
        else
            _fx, _fy = 0, 0
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
        _haveCam, _ramp = false, 0
        _auth = 1.0
        if _bound then
            pcall(function() RunService:UnbindFromRenderStep("LuaHook_Aimbot") end)
            _bound = false
        end
    end
    function Aimbot.unload() Aimbot.disable() end
end)()

-- ============ 觸發 ============
local Trigger = {}
do
    local _bound = false
    local _lastFire = 0
    local _onTgtAt = 0
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
        local dist = math.clamp(Config.TriggerMaxDist or 400, 1, 400)
        local res = W:Raycast(cf.Position, cf.LookVector * dist, trigParams)
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
        local now = tick()
        if pl.Character ~= _lastChar then
            _lastChar = pl.Character
            _onTgtAt = now
        end
        if (now - _onTgtAt) * 1000 < (Config.TriggerDelayMs or 0) then return end
        if (now - _lastFire) * 1000 < (Config.TriggerRefireMs or 0) then return end
        _lastFire = now
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
        _lastFire = 0
        _onTgtAt = 0
        if not _bound then return end
        pcall(function() RunService:UnbindFromRenderStep("LuaHook_Trigger") end)
        _bound = false
    end
    function Trigger.unload() Trigger.disable() end
end

-- ============ ESP ============
local ESP = {}
;(function()
    local _renderConn = nil
    local _espFrame = 0
    local _lastRenderT = 0
    local _dcLastT = 0
    local _bboxCache = {}
    local _bboxFrameN = {}
    local _ctx = {}
    local BLACK = Color3.new(0, 0, 0)
    local WHITE = Color3.new(1, 1, 1)
    local INK = Color3.fromRGB(4, 6, 10)
    local HPBG = Color3.fromRGB(11, 15, 22)
    local HP_W = 3
    local HP_GAP = 5
    local PAD = 5
    local FLAG_GAP = 6
    local BASE_H = 1080
    local MIN_W = 8
    local MIN_H = 13
    local BOX_W_STUDS = 4 * 1000 / 1080
    local BOX_H_STUDS = 6.5 * 1000 / 1080
    local TEXT_FLOOR = 8
    local DIST_MIN_MUL = 0.5
    local cam = C
    local FACES = {}
    for _, n in ipairs({ "Code", "RobotoMono", "Gotham", "GothamBold", "Arial", "SourceSans" }) do
        local ok, f = pcall(function() return Enum.Font[n] end)
        if ok and f then FACES[n] = f end
    end
    if FACES.Code == nil then FACES.Code = Enum.Font.SourceSans end
    local function faceFor(name) return FACES[name] or FACES.Code end
    local GLYPH_MID = string.char(0xC2, 0xB7)
    local function typePx(base, scale)
        local v = math.floor(base * scale + 0.5)
        if v < TEXT_FLOOR then v = TEXT_FLOOR end
        return v
    end
    local function sizeFor(base, mul)
        local v = math.floor(base * (mul or 1) + 0.5)
        if v < TEXT_FLOOR then v = TEXT_FLOOR end
        return v
    end
    local function styleLabel(t, face, size, casing)
        if typeof(face) == "EnumItem" then
            if t.Font ~= face then t.Font = face end
        else
            if t.FontFace ~= face then t.FontFace = face end
        end
        if t.TextSize ~= size then t.TextSize = size end
        local st = t:FindFirstChildOfClass("UIStroke")
        if st then
            local c = casing or 2
            if st.Thickness ~= c then st.Thickness = c end
            if st.Enabled ~= (c > 0) then st.Enabled = c > 0 end
        end
    end
    local function healthColor(frac)
        local mode = Config.ESPHealthColorMode or "Ramp"
        if mode == "Solid" then return Config.ESPHealthColor end
        if mode == "Gradient" then return WHITE end
        return hpRamp(frac)
    end
    local SKEL_R15 = {
        {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
        {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
        {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
        {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
        {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    }
    local SKEL_R6 = {
        {"Head","Torso"},
        {"Torso","Left Arm"},{"Torso","Right Arm"},
        {"Torso","Left Leg"},{"Torso","Right Leg"},
    }
    local FLAG_COLORS = {
        STARING = Color3.fromRGB(255, 70, 85),
        DEFLECT = Color3.fromRGB(53, 215, 199),
        SHIELD = Color3.fromRGB(255, 194, 75),
        INVINCIBLE = Color3.fromRGB(255, 215, 0),
        LOW = Color3.fromRGB(255, 90, 100),
    }
    local _gui, _absLayer = nil, nil
    local function mkAbsLayer(g)
        local a = Instance.new("Frame")
        a.Name = "a"; a.BackgroundTransparency = 1; a.BorderSizePixel = 0
        a.Size = UDim2.fromScale(1, 1); a.Position = UDim2.new(); a.ZIndex = 1
        a.Parent = g
        return a
    end
    local function espGui()
        if _gui and _gui.Parent then
            if _absLayer == nil or _absLayer.Parent ~= _gui then _absLayer = mkAbsLayer(_gui) end
            return _gui
        end
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
        _absLayer = mkAbsLayer(g)
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
        t.RichText = true
        t.TextXAlignment = align or Enum.TextXAlignment.Center
        t.AutomaticSize = Enum.AutomaticSize.XY
        t.Size = UDim2.fromOffset(0, 0)
        t.ZIndex = z or 3
        t.TextColor3 = WHITE
        local st = Instance.new("UIStroke")
        st.Color = BLACK; st.Thickness = 1; st.Transparency = 0
        st.LineJoinMode = Enum.LineJoinMode.Round
        st.Parent = t
        t.Parent = parent
        return t
    end
    local function mkList(parent, z, pad, hAlign, vAlign)
        local f = mkFrame(parent, z)
        f.AutomaticSize = Enum.AutomaticSize.XY
        f.Size = UDim2.fromOffset(0, 0)
        local l = Instance.new("UIListLayout")
        l.FillDirection = Enum.FillDirection.Vertical
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Padding = UDim.new(0, pad or 2)
        l.HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Center
        l.VerticalAlignment = vAlign or Enum.VerticalAlignment.Top
        l.Parent = f
        return f
    end
    local function mkRing(parent, z, colour, thick)
        local f = mkFrame(parent, z)
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Position = UDim2.fromScale(0.5, 0.5)
        f.Size = UDim2.fromScale(1, 1)
        local s = Instance.new("UIStroke")
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.LineJoinMode = Enum.LineJoinMode.Miter
        s.Color = colour; s.Thickness = thick; s.Transparency = 0
        s.Parent = f
        return f, s
    end
    local function buildTree(o)
        local g = espGui(); if not g then return nil end
        local u = {}
        local root = mkFrame(g, 2)
        root.Name = "r"
        root.Visible = false
        root.Size = UDim2.fromOffset(MIN_W, MIN_H)
        u.root = root
        u.box = mkFrame(root, 3)
        u.box.Size = UDim2.fromScale(1, 1)
        local rIn, sIn = mkRing(u.box, 4, INK, 1)
        local rMid, sMid = mkRing(u.box, 5, WHITE, 1)
        local rOut, sOut = mkRing(u.box, 4, INK, 1)
        u.boxStroke, u.caseOut, u.caseIn = sMid, sOut, sIn
        u.ringMid, u.ringOut, u.ringIn = rMid, rOut, rIn
        u.box.Visible = false
        u.corners = {}
        for i = 1, 8 do
            local c = mkFrame(root, 6)
            c.BackgroundTransparency = 0
            c.BackgroundColor3 = WHITE
            c.Visible = false
            local cs = Instance.new("UIStroke")
            cs.Color = INK; cs.Thickness = 1; cs.Transparency = 0
            cs.LineJoinMode = Enum.LineJoinMode.Miter
            cs.Parent = c
            u.corners[i] = c
        end
        local hp = mkFrame(root, 4)
        hp.AnchorPoint = Vector2.new(1, 0)
        hp.Position = UDim2.new(0, -HP_GAP, 0, 0)
        hp.Size = UDim2.new(0, HP_W, 1, 0)
        hp.BackgroundTransparency = 0
        hp.BackgroundColor3 = HPBG
        local hs = Instance.new("UIStroke")
        hs.Color = INK; hs.Thickness = 1; hs.Transparency = 0
        hs.LineJoinMode = Enum.LineJoinMode.Miter
        hs.Parent = hp
        hp.Visible = false
        u.hp = hp
        u.hpFill = mkFrame(hp, 6)
        u.hpFill.BackgroundTransparency = 0
        u.hpFill.BackgroundColor3 = WHITE
        u.hpFill.AnchorPoint = Vector2.new(0, 1)
        u.hpFill.Position = UDim2.fromScale(0, 1)
        u.hpFill.Size = UDim2.fromScale(1, 1)
        local head = mkList(root, 7, 2, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Bottom)
        head.AnchorPoint = Vector2.new(0.5, 1)
        head.Position = UDim2.new(0.5, 0, 0, -PAD)
        head.Visible = false
        u.head = head
        u.name = mkLabel(head, 8)
        u.name.LayoutOrder = 1
        local foot = mkList(root, 7, 2, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)
        foot.AnchorPoint = Vector2.new(0.5, 0)
        foot.Position = UDim2.new(0.5, 0, 1, PAD)
        foot.Visible = false
        u.foot = foot
        u.info = mkLabel(foot, 8)
        u.info.LayoutOrder = 1
        u.info.Visible = false
        local flags = mkList(root, 7, 3, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)
        flags.AnchorPoint = Vector2.new(0, 0)
        flags.Position = UDim2.new(1, FLAG_GAP, 0, 0)
        flags.Visible = false
        u.flags = flags
        u.chips = {}
        for i = 1, 5 do
            local c = mkLabel(flags, 8, Enum.TextXAlignment.Left)
            c.LayoutOrder = i
            c.Visible = false
            u.chips[i] = c
        end
        local a = _absLayer
        u.skel = {}
        u.tracer = mkFrame(a, 2); u.tracer.AnchorPoint = Vector2.new(0.5, 0.5)
        u.tracer.BackgroundTransparency = 0; u.tracer.BackgroundColor3 = WHITE; u.tracer.Visible = false
        u.dot = mkFrame(a, 3); u.dot.AnchorPoint = Vector2.new(0.5, 0.5)
        u.dot.BackgroundTransparency = 0; u.dot.BackgroundColor3 = WHITE; u.dot.Visible = false
        local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = u.dot
        local ds = Instance.new("UIStroke"); ds.Color = INK; ds.Thickness = 1; ds.Parent = u.dot
        return u
    end
    local function destroyTree(o)
        local u = o.ui; if not u then return end
        pcall(function() if u.root then u.root:Destroy() end end)
        pcall(function() if u.tracer then u.tracer:Destroy() end end)
        pcall(function() if u.dot then u.dot:Destroy() end end)
        if u.skel then
            for i = 1, #u.skel do pcall(function() u.skel[i]:Destroy() end) end
        end
        o.ui = nil
    end
    local function cleanESP(p)
        local o = State.ESPObjects[p]; if not o then return end
        destroyTree(o)
        if o.cham and o.cham.Parent then pcall(function() o.cham:Destroy() end) end
        _bboxCache[p] = nil
        _bboxFrameN[p] = nil
        State.ESPObjects[p] = nil
    end
    local function buildESP(player)
        if player == LP then return end
        cleanESP(player)
        local char = player.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local isR6 = (hum and hum.RigType == Enum.HumanoidRigType.R6) or (char:FindFirstChild("Torso") ~= nil)
        local rig = isR6 and SKEL_R6 or SKEL_R15
        local bones = {}
        for i, pair in ipairs(rig) do
            bones[i] = { a = char:FindFirstChild(pair[1]), b = char:FindFirstChild(pair[2]) }
        end
        local o = { root = root, rig = rig, bones = bones, _fadeT = tick() }
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
    local function hideTree(o)
        local u = o.ui; if not u then return end
        if u.root then u.root.Visible = false end
        if u.tracer then u.tracer.Visible = false end
        if u.dot then u.dot.Visible = false end
        if u.skel then for i = 1, #u.skel do u.skel[i].Visible = false end end
    end
    local function renderPlayer(player, o)
        local ctx = _ctx
        local char = player.Character
        if not char or not o.root or not o.root.Parent then cleanESP(player); return end
        if not o.root:IsA("BasePart") then cleanESP(player); return end
        local rootPos = o.root.Position
        if not rootPos then cleanESP(player); return end
        if not o.ui then o.ui = buildTree(o); if not o.ui then return end end
        local u = o.ui
        local vp = ctx.vp
        local myRoot = ctx.myRoot
        local dist = (myRoot and myRoot.Position and rootPos)
            and (myRoot.Position - rootPos).Magnitude or 0
        if (Config.ESPTeamCheck and isTeammate(player)) or (not isAlive(player)) then
            hideTree(o); o._allHidden = true; return
        end
        o._allHidden = false
        local minX, minY, maxX, maxY = bbox(char, player)
        if not minX then
            hideTree(o)
        else
            local w, h = maxX - minX, maxY - minY
            u.root.Position = UDim2.fromOffset(minX, minY)
            u.root.Size = UDim2.fromOffset(w, h)
            u.root.Visible = true
            local hp, mh, frac
            pcall(function() hp, mh = getHealth(player) end)
            if hp ~= nil then frac = math.clamp((mh or 0) > 0 and hp / mh or 0, 0, 1) end
            if Config.ESPBox then
                u.box.Visible = true
                u.boxStroke.Color = Config.ESPBoxColor
                u.boxStroke.Thickness = Config.ESPBoxThickness
            else
                u.box.Visible = false
            end
            if Config.ESPHealth then
                u.hp.Visible = true
                u.hpFill.Size = UDim2.new(1, 0, math.clamp(frac or 1, 0, 1), 0)
                u.hpFill.BackgroundColor3 = healthColor(frac or 1)
            else
                u.hp.Visible = false
            end
            if Config.ESPName then
                u.head.Visible = true
                u.name.Visible = true
                styleLabel(u.name, ctx.face, sizeFor(Config.ESPTextSize or 14, 1), 1)
                u.name.Text = (Config.ESPNameMode == "Username") and player.Name or player.DisplayName
                u.name.TextColor3 = Config.ESPNameColor
            else
                u.head.Visible = false
            end
            if Config.ESPDistance or Config.ESPWeapon then
                u.foot.Visible = true
                u.info.Visible = true
                styleLabel(u.info, ctx.face, sizeFor(Config.ESPInfoTextSize or 12, 1), 1)
                local txt
                if Config.ESPDistance then
                    txt = ("%dm"):format(dist)
                end
                u.info.Text = txt or ""
                u.info.TextColor3 = Config.ESPInfoColor
            else
                u.foot.Visible = false
            end
        end
    end
    local function render()
        local _now = tick()
        local _dt = _now - _lastRenderT
        if _now - _lastRenderT < 0.0083 then return end
        _lastRenderT = _now
        _espFrame = _espFrame + 1
        if not Config.ESP then
            for _, o in pairs(State.ESPObjects) do hideTree(o) end
            return
        end
        local ctx = _ctx
        ctx.vp = C.ViewportSize
        ctx.myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        ctx.dt = math.clamp(_dt, 0, 0.1)
        ctx.now = _now
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
        if _gui then pcall(function() _gui:Destroy() end); _gui = nil; _absLayer = nil end
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

-- ============ GUI ============
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
    Library = loadstring(src)()
    ThemeManager = loadstring(files[2])()
    SaveManager = loadstring(files[3])()
end)
if not ok or not Library then warn("[LuaHook] Linoria load failed:", err); return end

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
Library.IsMobile = isMobile
Library.ShowCustomCursor = false
pcall(function()
    Library.MainColor = Color3.fromRGB(26, 27, 31)
    Library.BackgroundColor = Color3.fromRGB(17, 18, 21)
    Library.AccentColor = Color3.fromRGB(96, 165, 250)
    Library.OutlineColor = Color3.fromRGB(43, 45, 52)
    Library.FontColor = Color3.fromRGB(239, 241, 245)
end)

local okWin, Window = pcall(function()
    return Library:CreateWindow({
        Title = 'LuaHook v12.0',
        Center = true,
        AutoShow = false,
        TabPadding = 8,
        MenuFadeTime = 0.2,
        NotifySide = 'Right',
        Resizable = true,
        UnlockMouseWhileOpen = true,
    })
end)
if not okWin or not Window then warn("[LuaHook] GUI window failed:", Window); return end

local Tabs = {
    Combat = Window:AddTab('戰鬥'),
    ESP = Window:AddTab('透視'),
    Settings = Window:AddTab('設定'),
}
local Options = Library.Options or {}
local Toggles = Library.Toggles or {}
Library.Options = Options
Library.Toggles = Toggles

-- 靜默自瞄
do
    local L = Tabs.Combat:AddLeftGroupbox('靜默自瞄')
    L:AddToggle('Silent_Enabled', {
        Text = '啟用靜默自瞄', Default = false,
        Callback = function(v) Config.SilentEnabled = v end
    }):AddKeyPicker('Silent_Key', {
        Text = '靜默自瞄', Default = 'None', Mode = 'Toggle', NoUI = true,
        SyncToggleState = true, Callback = function(state) Config.SilentEnabled = state end
    })
    L:AddToggle('Silent_AutoShoot', { Text = '自動開槍', Default = false, Callback = function(v) Config.SilentAutoShoot = v end })
    L:AddToggle('Silent_WallCheck', { Text = '牆壁檢測', Default = true, Callback = function(v) Config.SilentWallCheck = v end })
    L:AddToggle('Silent_360', { Text = '360 度模式', Default = false, Callback = function(v) Config.Silent360 = v end })
    L:AddDropdown('Silent_HitPart', {
        Text = '命中部位', Default = 'Head',
        Values = {"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso"},
        Callback = function(v) Config.SilentHitPart = v end
    })
    L:AddSlider('Silent_FOV', { Text = '視野半徑', Default = 150, Min = 10, Max = 800, Rounding = 0, Compact = true, Callback = function(v) Config.SilentFOV = v end })
    L:AddSlider('Silent_HitChance', { Text = '命中率 %', Default = 100, Min = 0, Max = 100, Rounding = 0, Compact = true, Callback = function(v) Config.SilentHitChance = v end })
    L:AddToggle('Silent_FollowMuzzle', { Text = '跟隨槍口', Default = false, Callback = function(v) Config.SilentFollowMuzzle = v end })
end

-- 自瞄
do
    local R = Tabs.Combat:AddRightGroupbox('自瞄')
    R:AddToggle('Aimbot', { Text = '啟用自瞄', Default = false, Callback = function(v) if v then Aimbot.enable() else Aimbot.disable() end end })
        :AddKeyPicker('AimbotKey_Picker', { Text = '自瞄', Default = 'None', Mode = 'Toggle', NoUI = true, SyncToggleState = true, Callback = function(state) if state then Aimbot.enable() else Aimbot.disable() end end })
    R:AddDropdown('AimbotKey', {
        Values = {'Always','MB2','MB1','C','E','F','Q','V','X','LeftShift','LeftAlt','LeftControl'},
        Default = 'MB2', Text = '啟動方式', Callback = function(v) Config.AimbotKey = v end
    })
    R:AddSlider('AimbotSmoothness', { Text = '平滑度 (0=硬鎖)', Default = 0, Min = 0, Max = 100, Rounding = 0, Callback = function(v) Config.AimbotSmoothness = v end })
    R:AddSlider('AimbotFOVDeg', { Text = '視野 度', Default = 20, Min = 1, Max = 180, Rounding = 1, Callback = function(v) Config.AimbotFOVDeg = v end })
    R:AddDropdown('AimbotTargetPart', { Values = {'Best','Head','Torso','Closest'}, Default = 'Best', Text = '目標骨骼', Callback = function(v) Config.AimbotTargetPart = v end })
    R:AddToggle('AimbotVisCheck', { Text = '可見性檢測', Default = true, Callback = function(v) Config.AimbotVisCheck = v end })
    R:AddToggle('AimbotPrediction', { Text = '預測', Default = false, Callback = function(v) Config.AimbotPrediction = v end })
end

-- 觸發 + 隊伍檢測
do
    local TB = Tabs.Combat:AddRightGroupbox('觸發機器人')
    TB:AddToggle('Trigger', { Text = '啟用觸發', Default = false, Callback = function(v) if v then Trigger.enable() else Trigger.disable() end end })
    TB:AddDropdown('TriggerKey', {
        Values = {'Always','MB2','MB1','C','E','F','Q','V','X','LeftShift','LeftAlt','LeftControl'},
        Default = 'Always', Text = '啟動方式', Callback = function(v) Config.TriggerKey = v end
    })
    TB:AddToggle('TriggerHeadOnly', { Text = '只打頭', Default = false, Callback = function(v) Config.TriggerHeadOnly = v end })
    TB:AddSlider('TriggerDelayMs', { Text = '反應延遲 毫秒', Default = 0, Min = 0, Max = 300, Rounding = 0, Callback = function(v) Config.TriggerDelayMs = v end })
    TB:AddSlider('TriggerRefireMs', { Text = '重射延遲 毫秒', Default = 0, Min = 0, Max = 500, Rounding = 0, Callback = function(v) Config.TriggerRefireMs = v end })
    TB:AddSlider('TriggerMaxDist', { Text = '最大距離', Default = 400, Min = 50, Max = 400, Rounding = 0, Callback = function(v) Config.TriggerMaxDist = v end })
end

do
    local T = Tabs.Combat:AddLeftGroupbox('目標選擇')
    T:AddToggle('TeamCheck', { Text = '隊伍檢測', Default = true, Callback = function(v) Config.TeamCheck = v end })
    T:AddDropdown('MaxDistance', {
        Values = {'100','500','1000','2000','5000','無限'},
        Default = '無限', Text = '最大距離',
        Callback = function(v)
            if v == '無限' then Config.MaxDistance = math.huge
            else Config.MaxDistance = tonumber(v) or math.huge end
        end
    })
end

-- ESP
do
    local L = Tabs.ESP:AddLeftGroupbox('透視 & 方框')
    L:AddToggle('ESP', { Text = '啟用透視', Default = true, Callback = function(v) if v then ESP.enable() else ESP.disable() end end })
        :AddKeyPicker('ESPToggleKey', { Default = 'None', Mode = 'Toggle', SyncToggleState = true, Text = '透視' })
    L:AddToggle('ESPTeamCheck', { Text = '隊伍檢測', Default = true, Callback = function(v) Config.ESPTeamCheck = v end })
    L:AddToggle('ESPBox', { Text = '方框', Default = true, Callback = function(v) Config.ESPBox = v end })
    L:AddSlider('ESPBoxThickness', { Text = '方框粗細', Default = 1, Min = 1, Max = 4, Rounding = 0, Callback = function(v) Config.ESPBoxThickness = math.floor(v) end })
    L:AddSlider('ESPBoxScale', { Text = '方框大小', Default = 1, Min = 0.6, Max = 1.6, Rounding = 2, Callback = function(v) Config.ESPBoxScale = v end })
    L:AddToggle('ESPHealth', { Text = '血條', Default = true, Callback = function(v) Config.ESPHealth = v end })
    L:AddDropdown('ESPHealthNumberMode', { Values = {'Off','OnDamage','Always'}, Default = 'OnDamage', Text = '血量數值', Callback = function(v) Config.ESPHealthNumberMode = v end })
    local R = Tabs.ESP:AddRightGroupbox('文字')
    R:AddToggle('ESPName', { Text = '玩家名字', Default = true, Callback = function(v) Config.ESPName = v end })
    R:AddDropdown('ESPNameMode', { Values = {'Display','Username'}, Default = 'Display', Text = '名字來源', Callback = function(v) Config.ESPNameMode = v end })
    R:AddToggle('ESPDistance', { Text = '距離', Default = true, Callback = function(v) Config.ESPDistance = v end })
    R:AddToggle('ESPWeapon', { Text = '持有武器', Default = false, Callback = function(v) Config.ESPWeapon = v end })
    R:AddSlider('ESPTextSize', { Text = '名字大小', Default = 14, Min = 9, Max = 24, Rounding = 0, Callback = function(v) Config.ESPTextSize = math.floor(v) end })
    R:AddLabel('名字顏色'):AddColorPicker('ESPNameColor', { Default = Config.ESPNameColor, Callback = function(v) Config.ESPNameColor = v end })
    R:AddLabel('方框顏色'):AddColorPicker('ESPBoxColor', { Default = Config.ESPBoxColor, Callback = function(v) Config.ESPBoxColor = v end })
end

-- 設定
do
    local L = Tabs.Settings:AddLeftGroupbox('選單')
    L:AddDropdown('GUIToggleKey', {
        Values = {'RightShift','LeftShift','RightControl','LeftControl','RightAlt','LeftAlt','F1','F2','F3','F4','F5','F6','F7','F8','F9','F10','F11','F12','Insert','Delete','Home','End','PageUp','PageDown','CapsLock','Tab'},
        Default = 'RightShift', Text = '介面開關鍵', Callback = function() end
    })
    L:AddButton({ Text = '卸載腳本 (需雙擊)', DoubleClick = true, Func = function()
        pcall(function() ESP.unload() end)
        pcall(function() Aimbot.unload() end)
        pcall(function() Trigger.unload() end)
        if getgenvFn then getgenvFn().__LH_SetmtBP = nil end
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

Library:Notify('v12.0 整合版載入完成', 4)
_G["\76\72"] = Library
print("[v12.0] 整合版載入完成")
-- ============================================================
-- LuaHook v12.0 — 狂暴完整版（Linoria 原文，砍 Orbit）
-- 從你之前貼的 Linoria 源碼搬過來，Orbit 相關刪除
-- 接在整合版結尾
-- ============================================================

-- ============ 狂暴設定 ============
Config.Rage = false
Config.RageMode = "Polar"
Config.RageGumMode = "on"
Config.RageVoidDepth = "deep"
Config.RageVoidMove = true
Config.RageVoidMinStep = 25000
Config.RageVoidJitterLocal = false
Config.RageVoidJitterStuds = 2000
Config.RageGatePoison = true
Config.RagePredictPrefire = true
Config.RagePredictResurface = true
Config.RageSkipImmune = true
Config.RageIdentityDance = true
Config.RageAttackContinuity = true
Config.RageAttackTranslocate = true
Config.RageBaitHeldMs = 300
Config.RageBaitRate = 2
Config.RageRestoreMode = "auto"
Config.RagePhysicsFlags = true
Config.RageCameraAnchor = true
Config.RageHPPriority = true
Config.RageFastTargetSwitch = true
Config.RageVisCheck = false
Config.RageKnifeBot = true
Config.RageShieldBackstab = true
Config.RageKnifeBackstab = true
Config.RageGumVoidFire = true
Config.RageOnEmpty = "Swap"
Config.RagePreferredSlot = "Primary"
Config.RageSwitchMelee = false
Config.RageSwitchRateLimit = 0.06
Config.RageEyeMuzzleSep = 0.07
Config.RageKillPlaneBuffer = 200
Config.RageTaps = 6
Config.RageTapsPerFrame = 1
Config.RageHideJitter = true
Config.RagePolarParity = true
Config.RagePrioritizeHackers = true
Config.RageDirectFire = true

State.RageTarget = nil
State.RageRealCF = nil
State.RageRealChar = nil
State.RageVoidCF = nil
State.RageVoidNext = 0
State.RageVoidBase = nil
State.RageVoidSteps = 0
State.RageLastFireTime = 0
State.RageReloadLast = 0
State.RageSwitchLast = 0
State.RageInMatch = false
State.RageStatus = "Idle"
State.RageFiring = false
State.RageVoidActive = false
State.RageTranslocating = false
State.RageFireFromPos = nil
State.RageFireAimPos = nil
State.RageFireHitPart = nil
State.RageFireStamp = 0
State.RageDealtTotal = 0
State.RageTrueVelocityMap = {}
State.RageSuspectedProtection = {}
State.RageBacktrackBuf = {}
State.RageCharTokens = {}
State.RageGlueBound = false
State.RageGumMode = "off"
State.RageGlueVerified = "n/a"
State.IdentitySafe = nil
State.CapabilityObserver = false
State.CapabilityErrors = 0
State.CapabilityKilledAt = nil
State.CapabilityLastStatus = nil
State.CapabilityRecoveries = 0
State.CapabilityDirty = false
State.CapabilitySeam = nil
State.ViewAngleForged = false
State.RageWhyProtected = 0
State.RageWhyNoPark = 0
State.RageWhyPrimeWait = 0
State.RageWhyPredict = 0
State.RageWhyDip = 0
State.RageWhyMeleeCd = 0
State.RageFireFrames = 0
State.RageImmuneStale = 0
State.RageAmmoUnreadable = 0
State.RageBaitHoldFrames = 0
State.RageBaitPinRefused = 0
State.RageBaitRingFallbacks = 0
State.RageVoidFires = 0
State.RagePoisonBlips = 0
State.RagePreFires = 0
State.RagePredTarget = nil
State.RagePredHide = 0
State.RagePredHideN = 0
State.RagePredAtk = 0
State.RagePredAtkN = 0
State.RagePredPhase = "?"
State.RagePredFor = 0
State.RagePredDue = 0
State.RagePredWindow = false
State.RagePredMag = 0
State.RageParkDirty = false
State.RageLastParkPos = nil
State.RageParkLatchCanary = 0
State.RageLatchStuds = 0
State.RageOrderCanary = 0
State.RagePostPark = false
State.RageBelowPlaneFrames = 0
State.RageBelowPlaneLast = 0
State.RageBelowPlaneDeaths = 0
State.RageParkDriftFrames = 0
State.RageParkDrift = 0
State.RageParkDriftY = 0
State.RageEyeClampFrames = 0
State.RageParkClampFrames = 0
State.RageTranslocateBaits = 0
State.RageFireZeroFrames = 0
State.RageBlankCanary = 0
State.RageTracerCanary = 0
State.RageOOBParkCanary = 0
State.RageHitsOn = 0
State.RageHitsOff = 0
State.RageOffFromSelf = 0
State.RageOffFromTarget = 0
State.RageKnifeSwings = 0
State.RageKnifeStatus = "idle"
State.RageRawSet = false
State.RagePhysRate = "off"
State.RageFPDHPath = "not attempted"
State.RageImmuneOverride = 0
State.RageFireWhy = nil

-- ============ Identity 工具 ============
local _identGet, _identSet, _identTried = nil, nil, false
local function identEnsure()
    if _identTried then return _identSet ~= nil end
    _identTried = true
    pcall(function()
        if type(getthreadidentity) == "function" and type(setthreadidentity) == "function" then
            _identGet, _identSet = getthreadidentity, setthreadidentity
        end
    end)
    State.RageRawSet = _identSet ~= nil
    return _identSet ~= nil
end

local _identitySafeLatched = nil
local function identityIsSafe()
    if _identitySafeLatched == nil then
        _identitySafeLatched = (Config.RageIdentityDance == true)
        State.IdentitySafe = _identitySafeLatched
    end
    return _identitySafeLatched
end

local function atId2(fn, ...)
    if _identSet == nil or not identityIsSafe() then return pcall(fn, ...) end
    local args = table.pack(...)
    local done, ok, res = false, false, nil
    task.spawn(function()
        local okPrev, prev = pcall(_identGet)
        if not okPrev then return end
        if not pcall(_identSet, 2) then return end
        done = true
        ok, res = pcall(fn, table.unpack(args, 1, args.n))
        pcall(_identSet, prev)
    end)
    if done then return ok, res end
    return pcall(fn, table.unpack(args, 1, args.n))
end

local function atId8(fn, ...)
    if _identSet == nil or not identityIsSafe() then return pcall(fn, ...) end
    local args = table.pack(...)
    local done, ok, res = false, false, nil
    task.spawn(function()
        local okPrev, prev = pcall(_identGet)
        if not okPrev then return end
        if not pcall(_identSet, 8) then return end
        done = true
        ok, res = pcall(fn, table.unpack(args, 1, args.n))
        pcall(_identSet, prev)
    end)
    if done then return ok, res end
    return pcall(fn, table.unpack(args, 1, args.n))
end

pcall(function()
    game:GetService("LogService").MessageOut:Connect(function(msg)
        if type(msg) ~= "string" or not string.find(msg, "lacking capability", 1, true) then return end
        State.CapabilityErrors = (State.CapabilityErrors or 0) + 1
        State.CapabilityLastStatus = tostring(State.RageStatus)
        if not State.CapabilityKilledAt then
            State.CapabilityKilledAt = tostring(State.RageStatus)
            State.CapabilityDirty = true
        end
    end)
    State.CapabilityObserver = true
end)

-- ============ Deflect 偵測 ============
local DEFLECT_ANIM_IDS = {
    ["14761240825"]=true,["14761220206"]=true,["14761234917"]=true,["14761221711"]=true,
    ["14761223422"]=true,["14761225204"]=true,["14761232380"]=true,["90436105114997"]=true,
    ["90797895557136"]=true,["77995180947430"]=true,["111943779640553"]=true,["131072510521727"]=true,
    ["132022220827223"]=true,["116315405171252"]=true,["110358509711635"]=true,["98242486936084"]=true,
    ["81132288854196"]=true,["123293403148826"]=true,["136354716301184"]=true,["120567011479119"]=true,
    ["92502373956550"]=true,["83541611040586"]=true,["92773106977434"]=true,["75844592081515"]=true,
    ["75381142568185"]=true,
}
local _deflecting, _deflGen = {}, {}
local _deflHookLive = false
local DEFLECT_CLEAR_PAD = 0.05

local function isDeflectingAnim(player)
    if not player or not player.Character then return false end
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then return false end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        if track.Name:lower():find("deflect") then return true end
        local anim = track.Animation
        local id = anim and anim.AnimationId
        if id then
            local num = id:match("(%d+)")
            if num and DEFLECT_ANIM_IDS[num] then return true end
        end
    end
    return false
end

local function isDeflecting(player)
    if not player then return false end
    if _deflecting[player.UserId] then return true end
    if _deflHookLive then return false end
    return isDeflectingAnim(player)
end

;(function()
    local function recordDeflect(self)
        local fighter = self and self.ClientFighter
        local plr = fighter and fighter.Player
        if not plr then return end
        local uid = plr.UserId
        local dur = self.Info and self.Info.DeflectDuration
        if type(dur) ~= "number" then dur = 0.1 end
        _deflecting[uid] = true
        local gen = (_deflGen[uid] or 0) + 1
        _deflGen[uid] = gen
        task.delay(dur + DEFLECT_CLEAR_PAD, function()
            if _deflGen[uid] == gen then _deflecting[uid] = nil end
        end)
    end
    task.spawn(function()
        for _ = 1, 10 do
            local ok, katana = pcall(function()
                return require(LP.PlayerScripts.Modules.Items.Katana)
            end)
            if ok and type(katana) == "table" and type(katana._StartDeflecting) == "function" then
                local orig = shared._LH_KatanaDeflOrig
                if not orig then orig = clonefunction(katana._StartDeflecting) end
                shared._LH_KatanaMod = katana
                shared._LH_KatanaDeflOrig = orig
                if setreadonly then pcall(setreadonly, katana, false) end
                katana._StartDeflecting = function(self, ...)
                    pcall(recordDeflect, self)
                    return orig(self, ...)
                end
                _deflHookLive = true
                return
            end
            task.wait(1)
        end
    end)
end)()

-- ============ 免疫偵測 ============
local _invincible, _invincEnt = {}, {}
local function isSpawnProtected(player)
    if not player then return false end
    if player.Character and player.Character:FindFirstChildOfClass("ForceField") then return true end
    if not Rivals.Fighter then return false end
    local map = Rivals.Fighter._player_to_fighter
    if not map then return false end
    local f = map[player]
    if not f then return false end
    local e = f.Entity
    if not e then return false end
    local uid = player.UserId
    if _invincEnt[uid] ~= e then
        _invincible[uid] = nil
        pcall(function()
            local live = e:Get("IsInvincible") == true
            e:GetDataChangedSignal("IsInvincible"):Connect(function()
                _invincible[uid] = e:Get("IsInvincible") == true
            end)
            _invincible[uid] = live
        end)
        _invincEnt[uid] = e
    end
    return _invincible[uid] == true
end

-- ============ 武器工具 ============
local MELEE_NMS = {
    ["Battle Axe"]=true,["Chainsaw"]=true,["Daggers"]=true,["Fists"]=true,
    ["Gunblade"]=true,["Katana"]=true,["Knife"]=true,["Scythe"]=true,["Trowel"]=true,
}
local KATANA_NAMES = {"katana","saber","lightning bolt","evil trident","tridant","devil's trident","linked sword","keytana","cutlass","swordfish","riptide"}
local KNIFE_NAMES = {"knife","karambit","balisong","chancla","machete","candy cane","armature","daggers","axe"}

local function getLocalFighter()
    if not Rivals.Ready then return nil end
    return Rivals.Fighter and Rivals.Fighter.LocalFighter
end
local function getEquippedItem()
    local lf = getLocalFighter()
    return lf and lf.EquippedItem or nil
end
local function getWeaponName(player)
    if not player or not player.Character then return "?" end
    local ok, res = pcall(function()
        if Rivals.Ready and Rivals.Fighter and Rivals.Fighter._player_to_fighter then
            local f = Rivals.Fighter._player_to_fighter[player]
            if f and f.EquippedItem and f.EquippedItem.Info then
                return f.EquippedItem.Info.Name
            end
        end
        return nil
    end)
    if ok and type(res) == "string" and res ~= "" then return res end
    return "?"
end
local function isKatana(player)
    local w = getWeaponName(player):lower()
    for _, n in ipairs(KATANA_NAMES) do
        if w:find(n, 1, true) then return true end
    end
    return isDeflecting(player)
end
local function isLocalKnife()
    local lf = getLocalFighter()
    if lf and lf.EquippedItem then
        local name = lf.EquippedItem.Name:lower()
        for _, n in ipairs(KNIFE_NAMES) do
            if name:find(n, 1, true) then return true end
        end
    end
    return false
end
local function isEnemyKnife(player)
    if not player then return false end
    local w = getWeaponName(player):lower()
    for _, n in ipairs(KNIFE_NAMES) do
        if w:find(n, 1, true) then return true end
    end
    return false
end
local function isRiotShield(player)
    local w = getWeaponName(player):lower()
    return w:find("riot shield") or w:find("energy shield") or w:find("tombstone shield")
        or w:find("broken surfboard", 1, true) or w == "door" or w == "sled" or w == "masterpiece"
end
local function ownsRiotShield(player)
    if not player then return false end
    local ok, res = pcall(function()
        if not (Rivals.Ready and Rivals.Fighter and Rivals.Fighter._player_to_fighter) then return false end
        local f = Rivals.Fighter._player_to_fighter[player]
        local items = f and f.Items
        if type(items) ~= "table" then return false end
        for _, it in items do
            local n = nil
            if type(it) == "table" then
                n = it.Name
                if n == nil and it.Info then n = it.Info.Name end
            end
            if type(n) == "string" then
                local low = n:lower()
                if low:find("riot shield") or low:find("energy shield") or low:find("tombstone shield") then
                    return true
                end
            end
        end
        return false
    end)
    return ok and res == true
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

local SANE_POS_LIMIT = 100000
local function isSanePos(p)
    return p == p
        and math.abs(p.X) < SANE_POS_LIMIT
        and math.abs(p.Y) < SANE_POS_LIMIT
        and math.abs(p.Z) < SANE_POS_LIMIT
end
local function posInPart(pos, part)
    if not part or not part.Parent then return false end
    local lpv = part.CFrame:PointToObjectSpace(pos)
    local s = part.Size * 0.5
    return math.abs(lpv.X) <= s.X and math.abs(lpv.Y) <= s.Y and math.abs(lpv.Z) <= s.Z
end
local function posIsOOB(pos)
    local ok, result = pcall(function()
        for _, p in ipairs(CollectionService:GetTagged("OutOfBoundsSafePart")) do
            if posInPart(pos, p) then return false end
        end
        for _, p in ipairs(CollectionService:GetTagged("OutOfBoundsPart")) do
            if posInPart(pos, p) then return true end
        end
        return false
    end)
    return ok and result == true
end
local function killFloor()
    local ok, val = pcall(function() return W.FallenPartsDestroyHeight end)
    if ok and type(val) == "number" and val == val then return val + Config.RageKillPlaneBuffer end
    return -400
end
local function isValidRageTarget(player, keepDeflect, rageScope)
    if not player or player == LP then return false end
    if Config.TeamCheck and isTeammate(player) then return false end
    if not isAlive(player) then return false end
    if Config.RageSkipImmune and not rageScope and isSpawnProtected(player) then return false end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    if Config.RageVisCheck and not rageScope and not isVisible(hrp.Position) then return false end
    return true
end

print("[v12.0] 狂暴完整版 — 基礎載入完成")
-- ============================================================
-- 狂暴完整版 — 第二則（Rage 核心 + GUI）
-- ============================================================

local Rage = {}
;(function()
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
            if isValidRageTarget(p, true, true) then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local d = 9999
                local sane = myRoot ~= nil and hrp ~= nil and isSanePos(hrp.Position)
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
        local okN, nm = pcall(function() return item:Get("Name") or item.Name end)
        if okN and type(nm) == "string" and MELEE_NMS[nm] then return true end
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
        if not okA then
            State.RageAmmoUnreadable = (State.RageAmmoUnreadable or 0) + 1
            return true
        end
        return type(ammo) == "number" and ammo > 0
    end
    Rage._weaponReady = weaponReady

    Rage._weaponRecovery = function(it)
        if not it then return "no item" end
        if itemIsMelee(it) then return "loaded" end
        local mode = Config.RageOnEmpty or "Swap"
        local okA, ammo = pcall(function() return it:Get("Ammo") end)
        local empty = not (okA and type(ammo) == "number" and ammo > 0)
        if mode ~= "Swap" or not empty then
            if tick() - (State.RageReloadLast or 0) < 0.5 then return "throttled" end
            State.RageReloadLast = tick()
            local lf = getLocalFighter()
            if lf then pcall(function() lf:Input("StartReloading") end) end
            pcall(function() it:StartReloading() end)
            return "requested"
        end
        local lf = getLocalFighter()
        local items = lf and lf.Items
        if type(items) ~= "table" then return "no items" end
        if tick() - (State.RageSwitchLast or 0) < 0.5 then return "swap-wait" end
        local pref = 1
        if Config.RagePreferredSlot == "Secondary" then pref = 2
        elseif Config.RagePreferredSlot == "Melee" then pref = 3 end
        local other = pref == 1 and 2 or 1
        for _, slot in ipairs({ pref, other }) do
            local w = items[slot]
            if w and w ~= it then
                local okW, wammo = pcall(function() return w:Get("Ammo") end)
                if okW and type(wammo) == "number" and wammo > 0 then
                    State.RageSwitchLast = tick()
                    local okE = pcall(function() lf:EquipItem(slot) end)
                    if okE then return "swap" end
                end
            end
        end
        return "no swap"
    end

    local _shootEnum = nil
    local function polarFire(eyePos, aimPos, hh)
        local it = getEquippedItem()
        if not it then State.RageFireWhy = "no item"; return 0 end
        pcall(function()
            it._shoot_cooldown = 0
            it._shoot_cooldown_no_ammo = 0
            it._last_shot = tick() - 1
        end)
        if State.CapabilityDirty then
            State.CapabilityDirty = false
            _shootEnum = nil
        end
        if _shootEnum == nil then
            pcall(function() _shootEnum = EnumLibrary:ToEnum("StartShooting") end)
        end
        if _shootEnum == nil then State.RageFireWhy = "no enum"; return 0 end
        if not UseItem then State.RageFireWhy = "no remote"; return 0 end
        local okId, objId = pcall(function() return it:Get("ObjectID") end)
        if not okId or not objId then State.RageFireWhy = "no objId"; return 0 end
        local base = eyePos - Vector3.new(0, 2.5, 0)
        local eyeCF = lookCF(base + Vector3.new(0, 2.5, 0), aimPos)
        local muzzleCF = eyeCF - Vector3.new(0, Config.RageEyeMuzzleSep, 0)
        local sent = 0
        local okLoop, loopErr = pcall(function()
            for _ = 1, math.max(1, math.min(Config.RageTapsPerFrame or 1, Config.RageTaps or 6)) do
                local inner = {}
                SharedEncode.buildShotFields(inner, eyeCF, muzzleCF, hh, aimPos, true, RAGE_CLAMP_FRAC, 1.0)
                local env = { [utf8.char(1)] = inner }
                UseItem:FireServer(objId, _shootEnum, env, nil)
                sent = sent + 1
            end
        end)
        if not okLoop then State.RageFireWhy = "send threw: " .. tostring(loopErr) end
        State.Shots = State.Shots + sent
        return sent
    end

    local function meleeStrike(hpos, hh, tgt)
        local it = getEquippedItem()
        if it == nil then State.RageKnifeStatus = "no item" return false end
        local prof = nil
        pcall(function()
            local info = it.Info
            if info == nil then return end
            if info.MaxAmmo ~= nil then return end
            prof = { heavy = info.CriticalDamage ~= nil }
        end)
        if prof == nil then State.RageKnifeStatus = "not melee" return false end
        local actionName = "StartShooting"
        if prof.heavy then actionName = "StartAiming" end
        local lf = getLocalFighter()
        if lf == nil then State.RageKnifeStatus = "no LocalFighter" return false end
        local sent = pcall(function() lf:Input(actionName) end)
        if sent then
            State.Shots = State.Shots + 1
            State.RageKnifeSwings = (State.RageKnifeSwings or 0) + 1
            State.RageKnifeStatus = "swinging " .. actionName
        else
            State.RageKnifeStatus = "send failed"
        end
        return sent
    end

    local RENDER_NAME = "LuaHook_Polar_Restore"
    local CAMERA_NAME = "LuaHook_Polar_CamAnchor"
    local _realCF, _realChar = nil, nil
    local _voidCF = nil
    local _target = nil
    local _firing = false
    local _inMatch = false
    local _deflectSince = 0
    local _notified = nil
    local _conn, _stepConn, _charConn = nil, nil, nil
    local VOID_MIN_STEP = 25000
    local VOID_R_MIN = 110000
    local VOID_R_MAX = 140000
    local DEFLECT_MAX_HOLD = 1.5
    local IMMUNE_MAX_HOLD = 6.0
    local _immuneSince = 0
    local _immuneTgt = nil
    local _preParkCF = nil
    local PRIME_S = 0.07
    local HIDE_JITTER_MAX = 0.25
    local _hiding = false
    local _primeUntil = 0

    local FFLAGS_ON = { DFIntS2PhysicsSenderRate = "120", DFIntAssemblyHistoryBufferSize = "2147483648", DFIntAssemblyHistorySkipSize = "0" }
    local FFLAGS_OFF = { DFIntS2PhysicsSenderRate = "15", DFIntAssemblyHistoryBufferSize = "15", DFIntAssemblyHistorySkipSize = "8" }
    local _fpdhOriginal = nil
    local _flagsOn = false

    local function fflagApi()
        local set, get, name = nil, nil, "none"
        pcall(function()
            if type(setfflag) == "function" then set, name = setfflag, "setfflag"
            elseif type(setfastflag) == "function" then set, name = setfastflag, "setfastflag" end
            if type(getfflag) == "function" then get = getfflag end
        end)
        return set, get, name
    end

    local _fpdhIdTried = false
    local _fpdhDead = false
    local function writeFPDH(value)
        if _fpdhDead then return false, "refused earlier" end
        if not identityIsSafe() then return false, "identity off" end
        if not _fpdhIdTried then _fpdhIdTried = true identEnsure() end
        if _identSet == nil then return false, "no identity API" end
        local wrote = false
        task.spawn(function()
            local okPrev, prev = pcall(_identGet)
            if not okPrev then return end
            if not pcall(_identSet, 8) then return end
            local sp = sethiddenproperty
            local wroteVia = false
            if type(sp) == "function" then
                wroteVia = pcall(sp, W, "FallenPartsDestroyHeight", value)
            end
            if not wroteVia then
                pcall(function() W.FallenPartsDestroyHeight = value end)
            end
            pcall(_identSet, prev)
            local okR, v = pcall(function() return W.FallenPartsDestroyHeight end)
            if okR then
                if value ~= value then wrote = (v ~= v) else wrote = (v == value) end
            end
        end)
        if wrote then return true, "identity 8" end
        _fpdhDead = true
        return false, "refused"
    end

    local function setPhysicsFlags(on)
        if on == _flagsOn then return end
        if on and Config.RagePhysicsFlags == false then return end
        _flagsOn = on
        if _fpdhOriginal == nil then
            local prev = W.FallenPartsDestroyHeight
            if prev ~= prev then prev = -500 end
            _fpdhOriginal = prev
        end
        if on then
            writeFPDH(0/0)
        else
            writeFPDH(_fpdhOriginal)
        end
        local set, get, setName = fflagApi()
        if set == nil then
            State.RagePhysRate = "no fflag setter"
            return
        end
        local want = on and FFLAGS_ON or FFLAGS_OFF
        for name, value in want do pcall(set, name, value) end
        State.RagePhysRate = setName .. " " .. (on and "verified" or "off")
    end
    Rage._setPhysicsFlags = setPhysicsFlags

    local function restoreMode()
        local m = Config.RageRestoreMode
        if m == "kerp" or m == "auto" then m = "kicia" end
        if m == "kicia" or m == "render" or m == "none" then return m end
        return "none"
    end

    local function rawSetCFrame(hrp, cf)
        identEnsure()
        if _identSet ~= nil and identityIsSafe() then
            local wrote = false
            task.spawn(function()
                local okPrev, prev = pcall(_identGet)
                if not okPrev then return end
                if not pcall(_identSet, 8) then return end
                wrote = pcall(function() hrp.CFrame = cf end)
                pcall(_identSet, prev)
            end)
            if wrote then return true end
        end
        return pcall(function() hrp.CFrame = cf end)
    end
    local function displace(hrp, cf)
        if _preParkCF == nil then _preParkCF = hrp.CFrame end
        return rawSetCFrame(hrp, cf)
    end
    Rage._displace = displace

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
        displace(hrp, voidCFrame())
    end

    local function polarTick(ch, hrp)
        local tgt = _target
        if tgt and (not tgt.Parent or not tgt.Character or not isAlive(tgt) or isTeammate(tgt)) then tgt = nil end
        if not tgt then tgt = findTarget() end
        _target = tgt
        State.RageTarget = tgt
        if not tgt or not tgt.Character then return hide(hrp, "No target") end
        local holdFire = isSpawnProtected(tgt) and Config.RageSkipImmune
        if not holdFire then
            _immuneSince, _immuneTgt = 0, nil
        else
            local now = tick()
            if _immuneTgt ~= tgt then _immuneSince, _immuneTgt = now, tgt end
            if now - _immuneSince > IMMUNE_MAX_HOLD then holdFire = false end
        end
        if isDeflecting(tgt) then
            local now = tick()
            if _deflectSince == 0 then _deflectSince = now end
            if now - _deflectSince < DEFLECT_MAX_HOLD then return hide(hrp, "Deflecting") end
        else
            _deflectSince = 0
        end
        local it = getEquippedItem()
        if not weaponReady(it) then
            local act = Rage._weaponRecovery(it)
            if act == "swap" or act == "swap-wait" then return hide(hrp, "Swapping") end
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
        if holdFire then
            _firing = false
            State.RageFiring = false
            State.RageVoidActive = true
            State.RageStatus = "Protected"
            displace(hrp, voidCFrame())
            return
        end
        if Config.RagePolarParity and (tick() < _primeUntil) then
            _firing = false
            State.RageFiring = false
            State.RageVoidActive = true
            State.RageStatus = "Priming"
            displace(hrp, voidCFrame())
            return
        end
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
            local sent = polarFire(C.CFrame.Position, hpos, hh)
            if sent == 0 then State.RageStatus = "PARKED, SENT NOTHING: " .. tostring(State.RageFireWhy) end
        end
    end

    local function restoreHome(pin)
        local ch = LP.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        local back = _preParkCF
        _preParkCF = nil
        pcall(function()
            if back then hrp.CFrame = back end
            if pin then
                local hu = ch:FindFirstChildOfClass("Humanoid")
                if hu and hu:GetState() == Enum.HumanoidStateType.Freefall and hu.FloorMaterial ~= Enum.Material.Air then
                    hu:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end)
    end

    local function cameraAnchor()
        if Config.RageCameraAnchor == false then return end
        local back = _preParkCF
        if back == nil then return end
        local ch = LP.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        local delta = back.Position - hrp.Position
        if not isSanePos(delta) then return end
        C.CFrame = C.CFrame + delta
    end

    function Rage.enable()
        Config.Rage = true
        if _conn then return end
        _firing = false
        setPhysicsFlags(true)
        _notified = nil
        pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
        pcall(function() RunService:UnbindFromRenderStep(CAMERA_NAME) end)
        RunService:BindToRenderStep(CAMERA_NAME, Enum.RenderPriority.Camera.Value + 5, function()
            pcall(cameraAnchor)
        end)
        RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.First.Value - 1000, function()
            if _firing and restoreMode() == "none" then return end
            restoreHome(false)
        end)
        _stepConn = RunService.Stepped:Connect(function()
            if _firing then
                local pol = restoreMode()
                if pol ~= "kicia" then return end
            end
            restoreHome(true)
        end)
        _charConn = LP.CharacterAdded:Connect(function()
            _realCF = nil; _realChar = nil; _voidCF = nil; _target = nil
            _notified = nil; _firing = false; _preParkCF = nil
            _hiding, _primeUntil = true, 0
        end)
        _conn = RunService.Heartbeat:Connect(function(dt)
            if not Config.Rage then Rage.disable(); return end
            local ch = LP.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            if not hrp or not hrp.Parent then return end
            if _preParkCF == nil and isSanePos(hrp.Position) then
                _realCF = hrp.CFrame
                _realChar = ch
            end
            _inMatch = inMatch()
            State.RageInMatch = _inMatch
            if not _inMatch then
                _target = nil; _firing = false
                State.RageFiring = false
                State.RageTarget = nil
                State.RageStatus = "Lobby"
                if not isSanePos(hrp.Position) then restoreHome(false) end
                return
            end
            if not _realCF or _realChar ~= ch then
                _firing = false
                State.RageFiring = false
                State.RageStatus = "Waiting"
                return
            end
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then
                _firing = false
                State.RageFiring = false
                State.RageVoidActive = false
                State.RageStatus = "Dead"
                if not isSanePos(hrp.Position) then restoreHome(false) end
                return
            end
            polarTick(ch, hrp)
        end)
    end

    function Rage.disable()
        Config.Rage = false
        setPhysicsFlags(false)
        if _conn then _conn:Disconnect(); _conn = nil end
        if _stepConn then _stepConn:Disconnect(); _stepConn = nil end
        if _charConn then _charConn:Disconnect(); _charConn = nil end
        pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
        pcall(function() RunService:UnbindFromRenderStep(CAMERA_NAME) end)
        _firing = false
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Parent then
            if _realCF and _realChar == LP.Character then
                pcall(function() hrp.CFrame = CFrame.new(_realCF.Position) * hrp.CFrame.Rotation end)
            elseif not isSanePos(hrp.Position) then
                pcall(function() hrp.CFrame = CFrame.new(0, 100, 0) end)
            end
        end
        _realCF = nil; _realChar = nil; _target = nil; _voidCF = nil; _notified = nil
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

do
    local RageTab = Window:AddTab('狂暴')
    local CORE = RageTab:AddLeftGroupbox('核心')
    CORE:AddToggle('Rage_Enabled', {
        Text = '啟用狂暴', Default = false,
        Callback = function(v) if v then Rage.enable() else Rage.disable() end end
    }):AddKeyPicker('Rage_Key', {
        Text = '狂暴', Default = 'None', Mode = 'Toggle', NoUI = true,
        SyncToggleState = true, Callback = function(state) if state then Rage.enable() else Rage.disable() end end
    })
    CORE:AddToggle('Rage_SkipImmune', { Text = '對無敵目標停火', Default = true, Callback = function(v) Config.RageSkipImmune = v end })
    CORE:AddToggle('Rage_HPPriority', { Text = '優先低血量目標', Default = true, Callback = function(v) Config.RageHPPriority = v end })
    CORE:AddToggle('Rage_PrioritizeHackers', { Text = '優先作弊者', Default = true, Callback = function(v) Config.RagePrioritizeHackers = v end })
    CORE:AddToggle('Rage_VisCheck', { Text = '可見性檢測', Default = false, Callback = function(v) Config.RageVisCheck = v end })
    CORE:AddDivider('引擎')
    CORE:AddDropdown('Rage_GumMode', { Values = {'off','lite','on'}, Default = 'on', Text = '口香糖模式', Callback = function(v) Config.RageGumMode = v end })
    CORE:AddDropdown('Rage_VoidDepth', { Values = {'shallow','deep'}, Default = 'deep', Text = '躲藏深度', Callback = function(v) Config.RageVoidDepth = v end })
    CORE:AddToggle('Rage_GatePoison', { Text = '閘門毒餌', Default = true, Callback = function(v) Config.RageGatePoison = v end })
    CORE:AddToggle('Rage_PredictPrefire', { Text = '預測重新出現', Default = true, Callback = function(v) Config.RagePredictPrefire = v end })
    CORE:AddToggle('Rage_IdentityDance', { Text = '身份舞步', Default = true, Callback = function(v) Config.RageIdentityDance = v end })
    CORE:AddToggle('Rage_PhysicsFlags', { Text = '物理旗標', Default = true, Callback = function(v) Config.RagePhysicsFlags = v end })
    CORE:AddToggle('Rage_CameraAnchor', { Text = '相機錨定', Default = true, Callback = function(v) Config.RageCameraAnchor = v end })
    CORE:AddDivider('誘餌脈衝')
    CORE:AddToggle('Rage_AttackTranslocate', { Text = '啟用誘餌脈衝', Default = true, Callback = function(v) Config.RageAttackTranslocate = v end })
    CORE:AddSlider('Rage_BaitHeldMs', { Text = '持續時間 毫秒', Default = 300, Min = 0, Max = 1000, Rounding = 0, Callback = function(v) Config.RageBaitHeldMs = math.floor(v) end })
    CORE:AddSlider('Rage_BaitRate', { Text = '每次爆發次數', Default = 2, Min = 1, Max = 6, Rounding = 0, Callback = function(v) Config.RageBaitRate = math.floor(v) end })
    CORE:AddDropdown('Rage_RestoreMode', { Values = {'auto','none','render','kerp'}, Default = 'auto', Text = '傳送模式', Callback = function(v) Config.RageRestoreMode = v end })

    local WEP = RageTab:AddRightGroupbox('武器')
    WEP:AddDropdown('Rage_OnEmpty', { Values = {'Swap','Reload'}, Default = 'Swap', Text = '彈藥耗盡時', Callback = function(v) Config.RageOnEmpty = v end })
    WEP:AddDropdown('Rage_PreferredSlot', { Values = {'Primary','Secondary','Melee'}, Default = 'Primary', Text = '偏好欄位', Callback = function(v) Config.RagePreferredSlot = v end })
    WEP:AddSlider('Rage_Taps', { Text = '每次開火發數', Default = 6, Min = 1, Max = 8, Rounding = 0, Compact = true, Callback = function(v) Config.RageTaps = v end })
    WEP:AddSlider('Rage_TapsPerFrame', { Text = '每幀發數', Default = 1, Min = 1, Max = 6, Rounding = 0, Compact = true, Callback = function(v) Config.RageTapsPerFrame = v end })
    WEP:AddSlider('Rage_EyeMuzzleSep', { Text = '眼-口分離', Default = 0.07, Min = 0, Max = 1, Rounding = 2, Compact = true, Callback = function(v) Config.RageEyeMuzzleSep = v end })

    local MELEE = RageTab:AddRightGroupbox('近戰')
    MELEE:AddToggle('Rage_KnifeBot', { Text = '小刀機器人', Default = true, Callback = function(v) Config.RageKnifeBot = v end })
    MELEE:AddToggle('Rage_ShieldBackstab', { Text = '防暴盾繞後', Default = true, Callback = function(v) Config.RageShieldBackstab = v end })
    MELEE:AddToggle('Rage_KnifeBackstab', { Text = '強制小刀背刺', Default = true, Callback = function(v) Config.RageKnifeBackstab = v end })
    MELEE:AddToggle('Rage_GumVoidFire', { Text = '口香糖虛空開火', Default = true, Callback = function(v) Config.RageGumVoidFire = v end })
end

Library:Notify('狂暴載入完成', 4)
print("[v12.0] 狂暴完整版載入完成")
