-- ============================================================
-- LuaHook v12.0 — 模組 1 完整修正版
-- 反封鎖 + Linoria 框架 + 靜默自瞄（完整 + 自動射擊 + 無限距離 + 優先最近）
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

-- 反封鎖第 1 層：setmetatable
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

-- 反封鎖第 2 層：__namecall
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

-- 反封鎖第 3 層：清連接
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

-- 反封鎖第 4 層：遠端過濾
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

-- 反封鎖第 5 層：__index
if hookmetamethod then
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", function(self, key)
        if checkcaller() and key == "Kick" and self == LP then
            return function() end
        end
        return oldIndex(self, key)
    end)
end

-- 反封鎖第 6 層：AC 腳本癱瘓
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

-- 反封鎖第 7 層：LocalScript3 常量掃描
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

-- 反封鎖第 8 層：假 ClientAlert
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

local _weaponResolving = false
local hookGunModule
local function resolveWeaponModules()
    if _weaponResolving then return end
    if Rivals.Gun ~= nil then return end
    _weaponResolving = true
    task.spawn(function()
        resolveAll({
            function() if Rivals.Gun == nil then Rivals.Gun = loadGameModule(LP.PlayerScripts, {"Modules","ItemTypes","Gun"}) end end,
        })
        _weaponResolving = false
        if Rivals.Gun ~= nil and hookGunModule ~= nil then pcall(hookGunModule) end
    end)
end
resolveWeaponModules()
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    resolveWeaponModules()
    if Rivals.Ready and hookGunModule then hookGunModule() end
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

local _visParams = RaycastParams.new()
_visParams.FilterType = Enum.RaycastFilterType.Exclude
local _visFilterChar = nil
local function isVisible(worldPos)
    local origin = C.CFrame.Position
    local _vc = LP.Character
    if _vc ~= _visFilterChar then
        _visParams.FilterDescendantsInstances = { _vc }
        _visFilterChar = _vc
    end
    local result = W:Raycast(origin, worldPos - origin, _visParams)
    if not result then return true end
    local hitModel = result.Instance and result.Instance:FindFirstAncestorOfClass("Model")
    if hitModel and Players:GetPlayerFromCharacter(hitModel) then return true end
    return (result.Position - worldPos).Magnitude < 3
end

local HEAD_PARTS    = { "HitboxHead", "HitboxHeadSmall", "Head" }
local TORSO_PARTS   = { "HitboxBody", "UpperTorso", "HumanoidRootPart", "LowerTorso" }
local CLOSEST_PARTS = {
    "HitboxHead","Head","UpperTorso","LowerTorso","HumanoidRootPart",
    "LeftHand","RightHand","LeftFoot","RightFoot",
    "LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg",
}
local function pickPart(char, mode)
    if not char then return nil end
    if mode == "Closest" then
        local best, bestDist = nil, math.huge
        local vp     = C.ViewportSize
        local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
        for _, name in ipairs(CLOSEST_PARTS) do
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

-- 共享編碼工具
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
        camData[utf8.char(0)] = Rivals.Util:EncodeCFrame(eyeCF)
        camData[utf8.char(1)] = Rivals.Util:EncodeCFrame(muzzleCF)
        camData[utf8.char(2)] = hitPart
        camData[utf8.char(3)] = Rivals.Util:EncodeCFrame(objSpaceCF)
    end

    function SharedEncode.encodeShot(camData, hitPart, targetChar, fromCamPos, claimOffset)
        if not hitPart or not camData or not Rivals.Util then return false end
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

-- ============ 靜默自瞄（完整版）============
local Config = {
    SilentAim = false,
    SilentAimVisCheck = false,
    SilentAimJitter = true,
    SilentAimTargetPart = "Head",
    SilentAimFOV = 250,
    SilentAimStickiness = 0.05,
    SilentAimMultipoint = false,
    SilentAimMultipointCount = 5,
    SilentAimTorsoFallback = false,
    SilentAimHitChance = 85,
    SilentAimBodyMix = 25,
    SilentAimJitterDeg = 1.5,
    SilentAimAutoShoot = false,
    SilentAimWallCheck = true,
    SilentAim360 = false,
    SilentAimFollowMuzzle = false,
    MaxDistance = math.huge,
    TeamCheck = true,
}

local State = {
    SilentLastTarget = nil,
    Shots = 0,
    Hits = 0,
    CamPos = Vector3.zero,
}

local function isValidTarget(player, checkVis)
    if not player or player == LP then return false end
    if Config.TeamCheck and isTeammate(player) then return false end
    if not isAlive(player) then return false end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    if checkVis and not isVisible(hrp.Position) then return false end
    return true
end

local function selectTarget(opts)
    opts = opts or {}
    local fov         = opts.fov or 90
    local checkVis    = opts.checkVis or false
    local mode        = opts.partMode or "Head"
    local sticky      = opts.stickyTarget
    local stickyBonus = opts.stickyBonus or 0
    local vp     = C.ViewportSize
    local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    local best, bestPart, bestScore = nil, nil, math.huge
    for _, player in ipairs(getSafePlayers()) do
        if player ~= LP and isValidTarget(player, false) then
            local char = player.Character
            local part = pickPart(char, mode)
            if part and (not checkVis or isVisible(part.Position)) then
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
    return best, bestPart
end

local function selectTarget360(mode, checkVis)
    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local best, bestPart, bestDist = nil, nil, math.huge
    for _, player in ipairs(getSafePlayers()) do
        if player ~= LP and isValidTarget(player, false) then
            local char = player.Character
            local part = pickPart(char, mode)
            if part then
                local isVis = (not checkVis) or isVisible(part.Position)
                if isVis then
                    local d = (part.Position - myRoot.Position).Magnitude
                    if d < bestDist then bestDist, best, bestPart = d, player, part end
                end
            end
        end
    end
    return best, bestPart
end

-- 新增：選最近目標（自動射擊專用）
local function selectNearestTarget(mode, checkVis)
    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local best, bestPart, bestDist = nil, nil, math.huge
    for _, player in ipairs(getSafePlayers()) do
        if player ~= LP and isValidTarget(player, false) then
            local char = player.Character
            local part = pickPart(char, mode)
            if part then
                local isVis = (not checkVis) or isVisible(part.Position)
                if isVis then
                    local d = (part.Position - myRoot.Position).Magnitude
                    if d < bestDist then
                        bestDist, best, bestPart = d, player, part
                    end
                end
            end
        end
    end
    return best, bestPart
end

local function silentPartVisible(part)
    if not part or not part:IsA("BasePart") then return false end
    if not Config.SilentAimMultipoint then return isVisible(part.Position) end
    if isVisible(part.Position) then return true end
    local n = math.max(1, math.floor(Config.SilentAimMultipointCount or 5))
    local r = math.min(part.Size.X, part.Size.Y, part.Size.Z) * 0.4
    for i = 1, n do
        local a   = (i / n) * math.pi * 2
        local off = Vector3.new(math.cos(a) * r, ((i % 2 == 0) and 0.5 or -0.5) * r, math.sin(a) * r)
        if isVisible(part.Position + off) then return true end
    end
    return false
end

local function pickSilentPart(char, primary)
    if not char then return primary end
    if silentPartVisible(primary) then return primary end
    for _, name in ipairs(HEAD_PARTS) do
        local p = char:FindFirstChild(name)
        if p and p ~= primary and silentPartVisible(p) then return p end
    end
    if Config.SilentAimTorsoFallback then
        for _, name in ipairs(TORSO_PARTS) do
            local p = char:FindFirstChild(name)
            if p and silentPartVisible(p) then return p end
        end
    end
    return primary
end

-- 靜默開火
local silentLastFire = 0
local silentFireCD = 0.01

local function silentFireAt(target, part)
    if not target or not target.Character or not target.Character.Parent then return false end
    local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
    if not lf or not lf.EquippedItem then return false end
    pcall(function() lf:Input("StartShooting") end)
    State.SilentLastTarget = target
    return true
end

-- 自動射擊循環（優先最近）
local function silentAutoFireLoop()
    if not Config.SilentAim then return end
    if not Config.SilentAimAutoShoot then return end
    local now = tick()
    if now - silentLastFire < silentFireCD then return end
    if Config.SilentAimHitChance < 100 then
        if math.random(1, 100) > Config.SilentAimHitChance then return end
    end
    -- 自動射擊一律優先選最近的敵人
    local tgt, part = selectNearestTarget(Config.SilentAimTargetPart, Config.SilentAimWallCheck)
    if not tgt or not part then return end
    if silentFireAt(tgt, part) then silentLastFire = now end
end

RunService.Heartbeat:Connect(function()
    pcall(silentAutoFireLoop)
end)

-- Gun 掛鉤（攔截 camData 改寫）
hookGunModule = function()
    if not Rivals.Ready or not Rivals.Gun then return end
    if shared._LH_GunOrig then pcall(function() Rivals.Gun.StartShooting = shared._LH_GunOrig end) end
    shared._gunHooked = game
    local oldStart = Rivals.Gun.StartShooting
    shared._LH_GunOrig = oldStart
    local hookWrapper = function(self, ...)
        local results = { oldStart(self, ...) }
        pcall(function()
            if not self.ClientFighter or not self.ClientFighter.IsLocalPlayer then return end
            if not Config.SilentAim then return end
            local camData = results[3]
            if not camData or typeof(camData) ~= "table" then return end
            local camPos = C.CFrame.Position
            State.CamPos = camPos
            local tgt, part
            if Config.SilentAimAutoShoot then
                tgt, part = selectNearestTarget(Config.SilentAimTargetPart, Config.SilentAimWallCheck)
            elseif Config.SilentAim360 then
                tgt, part = selectTarget360(Config.SilentAimTargetPart, Config.SilentAimWallCheck)
            else
                tgt, part = selectTarget({
                    fov        = Config.SilentAimFOV,
                    checkVis   = Config.SilentAimWallCheck,
                    partMode   = Config.SilentAimTargetPart,
                    stickyTarget = State.SilentLastTarget,
                    stickyBonus  = Config.SilentAimStickiness or 0.05,
                })
            end
            if tgt and part then
                State.SilentLastTarget = tgt
                if math.random(1, 100) <= (Config.SilentAimHitChance or 100) then
                    local hitPart = pickSilentPart(tgt.Character, part)
                    if math.random(1, 100) <= (Config.SilentAimBodyMix or 0) then
                        local body = tgt.Character:FindFirstChild("HitboxBody")
                        if body and silentPartVisible(body.Position) then hitPart = body end
                    end
                    local jit = Vector3.zero
                    local jd = Config.SilentAimJitterDeg or 0
                    if jd > 0 then
                        local okD, unit = pcall(function()
                            return Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5)
                        end)
                        local dir = Vector3.zero
                        if okD and unit and unit.Magnitude > 1e-4 then dir = unit.Unit end
                        local dist = 0
                        pcall(function() dist = (hitPart.Position - camPos).Magnitude end)
                        local off = math.min(math.tan(math.rad(jd)) * dist, 3) * (math.random() * 0.5)
                        jit = dir * off
                    end
                    if SharedEncode.encodeShot(camData, hitPart, tgt.Character, camPos, jit) then
                        results[4] = true
                        State.Shots = State.Shots + 1
                        State.Hits  = State.Hits  + 1
                    end
                end
            end
        end)
        return unpack(results)
    end
    if setfenv then pcall(setfenv, hookWrapper, getfenv(oldStart)) end
    if setreadonly then pcall(setreadonly, Rivals.Gun, false) end
    Rivals.Gun.StartShooting = hookWrapper
end
hookGunModule()

-- ============ Linoria 框架 ============
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

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
Library.IsMobile = isMobile
Library.ShowCustomCursor = false
pcall(function()
    Library.MainColor       = Color3.fromRGB(26, 27, 31)
    Library.BackgroundColor = Color3.fromRGB(17, 18, 21)
    Library.AccentColor     = Color3.fromRGB(96, 165, 250)
    Library.OutlineColor    = Color3.fromRGB(43, 45, 52)
    Library.FontColor       = Color3.fromRGB(239, 241, 245)
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
    Combat    = Window:AddTab('戰鬥'),
    Settings  = Window:AddTab('設定'),
}
local Options = Library.Options or {}
local Toggles = Library.Toggles or {}
Library.Options = Options
Library.Toggles = Toggles

-- ============ 靜默自瞄 GUI ============
do
    local L = Tabs.Combat:AddLeftGroupbox('靜默自瞄')
    L:AddToggle('SilentAim', {
        Text = '啟用靜默自瞄',
        Default = Config.SilentAim,
        Callback = function(v) Config.SilentAim = v end
    }):AddKeyPicker('SilentAimKey', {
        Default = 'None', Mode = 'Toggle',
        SyncToggleState = true, Text = '靜默自瞄'
    })
    L:AddToggle('SilentAimAutoShoot', {
        Text = '自動射擊',
        Default = Config.SilentAimAutoShoot,
        Callback = function(v) Config.SilentAimAutoShoot = v end
    })
    L:AddToggle('SilentAimWallCheck', {
        Text = '牆壁檢測',
        Default = Config.SilentAimWallCheck,
        Callback = function(v) Config.SilentAimWallCheck = v end
    })
    L:AddToggle('SilentAim360', {
        Text = '360 度（背後也能打）',
        Default = Config.SilentAim360,
        Callback = function(v) Config.SilentAim360 = v end
    })
    L:AddToggle('SilentAimFollowMuzzle', {
        Text = '跟隨槍口',
        Default = Config.SilentAimFollowMuzzle,
        Callback = function(v) Config.SilentAimFollowMuzzle = v end
    })
    L:AddDivider('目標')
    L:AddDropdown('SilentAimTargetPart', {
        Values = {'Head','Torso','Closest'},
        Default = Config.SilentAimTargetPart,
        Text = '目標骨骼',
        Callback = function(v) Config.SilentAimTargetPart = v end
    })
    L:AddSlider('SilentAimFOV', {
        Text = '視野半徑',
        Default = Config.SilentAimFOV,
        Min = 20, Max = 2000, Rounding = 0,
        Callback = function(v) Config.SilentAimFOV = v end
    })
    L:AddSlider('SilentAimStickiness', {
        Text = '黏著度',
        Default = Config.SilentAimStickiness,
        Min = 0, Max = 0.5, Rounding = 2,
        Callback = function(v) Config.SilentAimStickiness = v end
    })
    L:AddDivider('隱蔽')
    L:AddToggle('SilentAimMultipoint', {
        Text = '多點採樣',
        Default = Config.SilentAimMultipoint,
        Callback = function(v) Config.SilentAimMultipoint = v end
    })
    local smpDep = L:AddDependencyBox()
    smpDep:AddSlider('SilentAimMultipointCount', {
        Text = '多點樣本數',
        Default = Config.SilentAimMultipointCount,
        Min = 1, Max = 12, Rounding = 0,
        Callback = function(v) Config.SilentAimMultipointCount = math.floor(v) end
    })
    smpDep:SetupDependencies({ { Toggles.SilentAimMultipoint, true } })
    L:AddToggle('SilentAimTorsoFallback', {
        Text = '軀幹回退',
        Default = Config.SilentAimTorsoFallback,
        Callback = function(v) Config.SilentAimTorsoFallback = v end
    })
    L:AddSlider('SilentAimHitChance', {
        Text = '命中機率 %',
        Default = Config.SilentAimHitChance,
        Min = 25, Max = 100, Rounding = 0,
        Callback = function(v) Config.SilentAimHitChance = math.floor(v) end
    })
    L:AddSlider('SilentAimBodyMix', {
        Text = '身體混合 %',
        Default = Config.SilentAimBodyMix,
        Min = 0, Max = 100, Rounding = 0,
        Callback = function(v) Config.SilentAimBodyMix = math.floor(v) end
    })
    L:AddSlider('SilentAimJitterDeg', {
        Text = '抖動錐角 (度)',
        Default = Config.SilentAimJitterDeg,
        Min = 0, Max = 10, Rounding = 1,
        Callback = function(v) Config.SilentAimJitterDeg = v end
    })
end

-- ============ 設定分頁 ============
do
    local L = Tabs.Settings:AddLeftGroupbox('選單')
    L:AddDropdown('GUIToggleKey', {
        Values = {'RightShift','LeftShift','RightControl','LeftControl','RightAlt','LeftAlt',
                  'F1','F2','F3','F4','F5','F6','F7','F8','F9','F10','F11','F12',
                  'Insert','Delete','Home','End','PageUp','PageDown','CapsLock','Tab'},
        Default = 'RightShift',
        Text = '介面開關鍵',
        Callback = function() end
    })
    L:AddButton({ Text = '卸載腳本 (需雙擊)', DoubleClick = true, Func = function()
        if shared._LH_GunOrig and Rivals.Gun then
            if setreadonly then pcall(setreadonly, Rivals.Gun, false) end
            Rivals.Gun.StartShooting = shared._LH_GunOrig
        end
        shared._gunHooked = nil
        shared._LH_GunOrig = nil
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

Library:Notify('模組 1 載入完成', 4)
_G["\76\72"] = Library
print("[v12.0] 模組 1 完整修正版載入完成")
