-- ============================================================
-- LuaHook v12.0 — 模組 1 完整版（牆壁檢測修復）
-- 反封鎖 + Linoria 框架 + v11.0 靜默自瞄（完整 + 自動開槍 + 牆壁檢測修復）
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

-- ============ v11.0 靜默自瞄（牆壁檢測雙重修復）============
local S = {
    SilentEnabled = false,
    SilentHitPart = "Head",
    SilentHitChance = 100,
    SilentFOV = 150,
    SilentAutoShoot = false,
    SilentFollowMuzzle = false,
    SilentWallCheck = true,
    Silent360 = false,
    SilentJitter = true,
    SilentAvoidDeflect = false,
    SilentStickiness = 0.05,
    SilentMultipoint = false,
    SilentMultipointCount = 5,
    SilentTorsoFallback = false,
    SilentBodyMix = 25,
    SilentJitterDeg = 1.5,
    TeamCheck = true,
    ESPMaxDistance = math.huge,
}

local State = {
    SilentLastTarget = nil,
    Shots = 0,
    Hits = 0,
    CamPos = Vector3.zero,
}

local function isValidTargetSilent(player, checkVis)
    if not player or player == LP then return false end
    if S.TeamCheck and isTeammate(player) then return false end
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
    if S.Silent360 then
        local best, bestD = nil, math.huge
        local myChar = LP.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end
        for _, p in ipairs(getSafePlayers()) do
            if isValidTargetSilent(p) then
                local part = getHitPartName(p.Character, S.SilentHitPart)
                if part then
                    -- ★ 360 模式也套用牆壁檢測
                    local visibleOK = (not S.SilentWallCheck) or isVisible(part.Position)
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
        fov = S.SilentFOV,
        checkVis = S.SilentWallCheck,
        partMode = S.SilentHitPart,
        stickyTarget = State.SilentLastTarget,
        stickyBonus = S.SilentStickiness,
    })
    return tgt
end

local function fireSilentAt(target)
    if not UseItem or not Utility or not EnumLibrary then return false end
    if not target or not target.Character or not target.Character.Parent then return false end
    local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
    if not lf or not lf.EquippedItem then return false end
    local part = getHitPartName(target.Character, S.SilentHitPart)
    if not part then return false end
    -- ★ 開火前雙重檢查牆壁
    if S.SilentWallCheck then
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
    if not S.SilentEnabled or not S.SilentAutoShoot then return end
    local now = tick()
    if now - silentLastFire < silentFireCD then return end
    if S.SilentHitChance < 100 then
        if math.random(1, 100) > S.SilentHitChance then return end
    end
    local target = findSilentTarget()
    if not target then return end
    if fireSilentAt(target) then silentLastFire = now end
end

RunService.Heartbeat:Connect(function()
    if S.SilentEnabled and S.SilentAutoShoot then
        pcall(silentAutoFireLoop)
    end
end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not S.SilentEnabled or S.SilentAutoShoot then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local target = findSilentTarget()
        if target then pcall(fireSilentAt, target) end
    end
end)

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

do
    local L = Tabs.Combat:AddLeftGroupbox('靜默自瞄')
    L:AddToggle('Silent_Enabled', {
        Text = '啟用靜默自瞄',
        Default = false,
        Callback = function(v) S.SilentEnabled = v end
    }):AddKeyPicker('Silent_Key', {
        Text = '靜默自瞄', Default = 'None', Mode = 'Toggle', NoUI = true,
        SyncToggleState = true, Callback = function(state) S.SilentEnabled = state end
    })
    L:AddToggle('Silent_AutoShoot', {
        Text = '自動開槍',
        Default = false,
        Callback = function(v) S.SilentAutoShoot = v end
    })
    L:AddToggle('Silent_WallCheck', {
        Text = '牆壁檢測',
        Default = true,
        Callback = function(v) S.SilentWallCheck = v end
    })
    L:AddToggle('Silent_360', {
        Text = '360 度模式',
        Default = false,
        Callback = function(v) S.Silent360 = v end
    })
    L:AddDropdown('Silent_HitPart', {
        Text = '命中部位', Default = 'Head',
        Values = {"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso"},
        Callback = function(v) S.SilentHitPart = v end
    })
    L:AddSlider('Silent_FOV', {
        Text = '視野半徑', Default = 150,
        Min = 10, Max = 800, Rounding = 0, Compact = true,
        Callback = function(v) S.SilentFOV = v end
    })
    L:AddSlider('Silent_HitChance', {
        Text = '命中率 %', Default = 100,
        Min = 0, Max = 100, Rounding = 0, Compact = true,
        Callback = function(v) S.SilentHitChance = v end
    })
    L:AddToggle('Silent_FollowMuzzle', {
        Text = '跟隨槍口',
        Default = false,
        Callback = function(v) S.SilentFollowMuzzle = v end
    })
end

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
print("[v12.0] 模組 1 載入完成")
-- ============================================================
-- LuaHook v12.0 — 模組 2
-- 自瞄 + 觸發 + 隊伍檢測
-- 接在模組 1 之後
-- ============================================================

-- ============ 自瞄 Config ============
Config.Aimbot = false
Config.AimbotVisCheck = true
Config.AimbotKey = "MB2"
Config.AimbotSmoothness = 0
Config.AimbotSmoothnessX = 0
Config.AimbotSmoothnessY = 0
Config.AimbotLinkAxes = true
Config.AimbotJumpDamping = 40
Config.AimbotCancelSprings = true
Config.AimbotCurvedFlick = false
Config.AimbotCurvedIntensity = 0.35
Config.AimbotTrackAssist = 100
Config.AimbotFOVDeg = 20
Config.AimbotMaxSpeed = 0
Config.AimbotDeadzoneDeg = 0
Config.AimbotSwitchDeg = 2
Config.AimbotStickiness = 0.15
Config.AimbotForgetTime = 0.2
Config.AimbotTargetPart = "Best"
Config.AimbotPriority = "Crosshair"
Config.AimbotSkipImmune = true
Config.AimbotPrediction = false
Config.AimbotShotOverride = false
Config.AimbotShowFOV = false
Config.AimbotShowLock = false
Config.AimbotDebug = false
Config.AimbotReactionMs = 0
Config.AimbotNoiseDeg = 0
Config.AimbotOvershoot = 0
Config.AimbotDirectCamera = false

Config.Trigger = false
Config.TriggerKey = "Always"
Config.TriggerDelayMs = 0
Config.TriggerRefireMs = 0
Config.TriggerHeadOnly = false
Config.TriggerMaxDist = 400
Config.TriggerScopeCheck = false

Config.TeamCheck = true

-- 自瞄狀態
State.AimbotTarget = nil
State.AimbotPart = nil
State.AimbotLastTarget = nil
State.AimbotLastTargetTime = 0
State.AimbotKeyHeld = false
State.AimbotFlickActive = false

-- ============ 自瞄完整版 ============
local Aimbot = {}
;(function()
    local TAU = math.pi * 2
    local D2R = math.pi / 180
    local R2D = 180 / math.pi
    local MAX_TAU     = 0.30
    local RETAIN_MUL  = 1.6
    local STICKY_MEM  = 2.0
    local FF_TAU      = 0.05
    local FF_MAX      = 12
    local UNIT_MAX    = 2000
    local RAMP_TIME   = 0.15
    local PITCH_LIMIT = 1.5690509975429023
    local CAL_MIN     = 1.5
    local CAL_FAST_N  = 8
    local BAND_LO     = 0.05
    local BAND_HI     = 6.0
    local OSC_ERR     = 0.02
    local RUNAWAY_ERR = 1.0
    local SEED_MX     = -0.008726646259971648
    local SEED_MY     = -0.006719517620178168
    local SEED_DX     = 1.0
    local SEED_DY     = 1.0
    local _bound       = false
    local _mouseMove   = mousemoverel
    local _tgt, _part  = nil, nil
    local _prevTgt     = nil
    local _acquireAt   = 0
    local _lastSeenAt  = 0
    local _ramp        = 0
    local _gx, _gy     = SEED_MX, SEED_MY
    local _sdx, _sdy   = SEED_MX, SEED_MY
    local _nx, _ny     = 0, 0
    local _sx, _sy     = 0, 0
    local _fx, _fy     = 0, 0
    local _lyaw, _lpit = 0, 0
    local _haveCam     = false
    local _ffy, _ffp   = 0, 0
    local _lty, _ltp   = 0, 0
    local _haveTgt     = false
    local _lastPartRef = nil
    local _flickActive   = false
    local _flickT        = 0
    local _flickDur      = 0.15
    local _flickCtrl1Y   = 0
    local _flickCtrl1P   = 0
    local _flickCtrl2Y   = 0
    local _flickCtrl2P   = 0
    local _auth        = 1.0
    local _flips       = 0
    local _errEma      = 0
    local _lastSign    = nil
    local _drive       = 0
    local _trips       = 0
    local _calOff      = false
    local _lastFOV     = 0
    local _errDeg      = 0
    local _path        = "none"
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
        local vis  = Config.AimbotVisCheck
        local bP, bPart, bAng, bScore = nil, nil, math.huge, math.huge
        local cPart, cAng, cOK = nil, math.huge, false
        for _, pl in ipairs(getSafePlayers()) do
            if isValidAimTarget(pl) then
                local char = pl.Character
                local part = pickPart(char, pick)
                if part then
                    local ang    = angTo(cf, part.Position)
                    local isCur  = (pl == cur)
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
                        _gx, _gy   = SEED_DX, SEED_DY
                        _sdx, _sdy = SEED_DX, SEED_DY
                        _nx, _ny   = 0, 0
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
        if _path == "mouse" then
            pcall(_mouseMove, ux, uy)
        elseif _path == "direct" and _ctl then
            pcall(function() _ctl:ApplyRotationDelta(Vector2.new(uy, ux)) end)
        end
    end

    local function calibrate(obs, sent, gain, n, seed)
        if math.abs(sent) < CAL_MIN then return gain, n end
        local s = obs / sent
        if (s * seed) <= 0 then return gain, n end
        local a  = math.abs(s)
        local lo = math.abs(seed) * BAND_LO
        local hi = math.abs(seed) * BAND_HI
        if a < lo or a > hi then return gain, n end
        if n < CAL_FAST_N then return s, n + 1 end
        local r = math.abs(s / gain)
        if r < 0.34 or r > 3.0 then return gain, n end
        return gain + (s - gain) * 0.05, n + 1
    end

    local function clearTarget()
        _tgt, _part  = nil, nil
        _prevTgt     = nil
        _haveTgt     = false
        _lastPartRef = nil
        _ffy, _ffp   = 0, 0
        _errDeg      = 0
        _flips, _errEma, _lastSign, _drive = 0, 0, nil, 0
        _flickActive = false
        State.AimbotTarget      = nil
        State.AimbotPart        = nil
        State.AimbotFlickActive = false
    end

    local function step(dt)
        dt = math.clamp(dt or (1 / 60), 1 / 1000, 0.1)
        local cf     = C.CFrame
        local look   = cf.LookVector
        local curYaw, curPit = yawOf(look), pitchOf(look)
        if _haveCam and not _calOff then
            _gx, _nx = calibrate(wrapPi(curYaw - _lyaw), _sx, _gx, _nx, _sdx)
            _gy, _ny = calibrate(curPit - _lpit,         _sy, _gy, _ny, _sdy)
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
        if State.RageFiring then clearTarget(); return end
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
            _acquireAt   = now
            _ramp        = 0
            _haveTgt     = false
            _ffy, _ffp   = 0, 0
            _prevTgt     = tgt
            _flickActive = false
        end
        _tgt, _part = tgt, part
        State.AimbotTarget         = tgt
        State.AimbotPart           = part
        State.AimbotLastTarget     = tgt
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
        _lty, _ltp, _haveTgt, _lastPartRef = tYaw, tPit, true, part
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
        _drive  = _drive + dt
        local sPos = (errYaw >= 0)
        if _lastSign ~= nil and sPos ~= _lastSign then _flips = _flips + 1 end
        _lastSign = sPos
        _flips = _flips * math.exp(-dt / 0.25)
        if _flips >= 4 and _errEma > OSC_ERR and not isHardLock then
            _auth  = math.max(0.15, _auth * 0.5)
            _flips = 0
        else
            _auth = math.min(1, _auth + dt * 0.3)
        end
        local avgSmooth = (smoothX + smoothY) * 0.5
        if _errEma > RUNAWAY_ERR and _drive > (0.15 + (avgSmooth / 100) * MAX_TAU * 3) and not isHardLock then
            _auth    = math.max(0.08, _auth * 0.5)
            _gx, _gy = _sdx, _sdy
            _nx, _ny = 0, 0
            _drive   = 0
            _trips   = _trips + 1
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

-- ============ 觸發機器人 ============
local Trigger = {}
do
    local _bound    = false
    local _lastFire = 0
    local _onTgtAt  = 0
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
        local cf   = C.CFrame
        local dist = math.clamp(Config.TriggerMaxDist or 400, 1, 400)
        local res  = W:Raycast(cf.Position, cf.LookVector * dist, trigParams)
        if not res or not res.Instance then return nil end
        local model = res.Instance:FindFirstAncestorOfClass("Model")
        if not model then return nil end
        local pl = Players:GetPlayerFromCharacter(model)
        if not pl or pl == LP then return nil end
        return pl, res.Instance
    end
    local function step()
        if not Config.Trigger then return end
        if Config.Rage then _lastChar = nil return end
        if not isInputActive(Config.TriggerKey) then _lastChar = nil return end
        local pl, hit = underCrosshair()
        if not pl then _lastChar = nil return end
        if Config.TeamCheck and isTeammate(pl) then _lastChar = nil return end
        if not isAlive(pl) then _lastChar = nil return end
        if Config.TriggerHeadOnly and not isHeadHit(hit) then _lastChar = nil return end
        local now = tick()
        if pl.Character ~= _lastChar then
            _lastChar = pl.Character
            _onTgtAt  = now
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
        _onTgtAt  = 0
        if not _bound then return end
        pcall(function() RunService:UnbindFromRenderStep("LuaHook_Trigger") end)
        _bound = false
    end
    function Trigger.unload() Trigger.disable() end
end

-- ============ 自瞄 GUI ============
do
    local R = Tabs.Combat:AddRightGroupbox('自瞄')
    R:AddToggle('Aimbot', {
        Text = '啟用自瞄',
        Default = false,
        Callback = function(v) if v then Aimbot.enable() else Aimbot.disable() end end
    }):AddKeyPicker('AimbotKey_Picker', {
        Text = '自瞄', Default = 'None', Mode = 'Toggle', NoUI = true,
        SyncToggleState = true, Callback = function(state)
            if state then Aimbot.enable() else Aimbot.disable() end
        end
    })
    R:AddDropdown('AimbotKey', {
        Values = {'Always','MB2','MB1','C','E','F','Q','V','X','LeftShift','LeftAlt','LeftControl'},
        Default = 'MB2', Text = '啟動方式',
        Callback = function(v) Config.AimbotKey = v end
    })
    R:AddSlider('AimbotSmoothness', {
        Text = '平滑度 (0 = 硬鎖)',
        Default = 0, Min = 0, Max = 100, Rounding = 0,
        Callback = function(v) Config.AimbotSmoothness = v end
    })
    R:AddToggle('AimbotLinkAxes', {
        Text = '水平垂直連動',
        Default = true,
        Callback = function(v) Config.AimbotLinkAxes = v end
    })
    local axisDep = R:AddDependencyBox()
    axisDep:AddSlider('AimbotSmoothnessX', {
        Text = '水平平滑度',
        Default = 0, Min = 0, Max = 100, Rounding = 0,
        Callback = function(v) Config.AimbotSmoothnessX = v end
    })
    axisDep:AddSlider('AimbotSmoothnessY', {
        Text = '垂直平滑度',
        Default = 0, Min = 0, Max = 100, Rounding = 0,
        Callback = function(v) Config.AimbotSmoothnessY = v end
    })
    axisDep:SetupDependencies({ { Toggles.AimbotLinkAxes, false } })
    R:AddSlider('AimbotJumpDamping', {
        Text = '跳躍阻尼 %',
        Default = 40, Min = 0, Max = 100, Rounding = 0,
        Callback = function(v) Config.AimbotJumpDamping = v end
    })
    R:AddToggle('AimbotCancelSprings', {
        Text = '預先取消武器彈簧',
        Default = true,
        Callback = function(v) Config.AimbotCancelSprings = v end
    })
    R:AddToggle('AimbotCurvedFlick', {
        Text = '人性化曲線甩槍',
        Default = false,
        Callback = function(v) Config.AimbotCurvedFlick = v end
    })
    local curveDep = R:AddDependencyBox()
    curveDep:AddSlider('AimbotCurvedIntensity', {
        Text = '曲線振幅',
        Default = 0.35, Min = 0.05, Max = 1.0, Rounding = 2,
        Callback = function(v) Config.AimbotCurvedIntensity = v end
    })
    curveDep:SetupDependencies({ { Toggles.AimbotCurvedFlick, true } })
    R:AddSlider('AimbotTrackAssist', {
        Text = '追蹤輔助 %',
        Default = 100, Min = 0, Max = 100, Rounding = 0,
        Callback = function(v) Config.AimbotTrackAssist = v end
    })
    R:AddSlider('AimbotMaxSpeed', {
        Text = '最大轉向速度 度/秒',
        Default = 0, Min = 0, Max = 3600, Rounding = 0,
        Callback = function(v) Config.AimbotMaxSpeed = v end
    })
    R:AddSlider('AimbotDeadzoneDeg', {
        Text = '死區 度',
        Default = 0, Min = 0, Max = 10, Rounding = 2,
        Callback = function(v) Config.AimbotDeadzoneDeg = v end
    })
    R:AddSlider('AimbotFOVDeg', {
        Text = '視野 度',
        Default = 20, Min = 1, Max = 180, Rounding = 1,
        Callback = function(v) Config.AimbotFOVDeg = v end
    })
    R:AddSlider('AimbotSwitchDeg', {
        Text = '切換閾值 度',
        Default = 2, Min = 0, Max = 45, Rounding = 1,
        Callback = function(v) Config.AimbotSwitchDeg = v end
    })
    R:AddSlider('AimbotStickiness', {
        Text = '黏著度',
        Default = 0.15, Min = 0, Max = 0.5, Rounding = 2,
        Callback = function(v) Config.AimbotStickiness = v end
    })
    R:AddSlider('AimbotForgetTime', {
        Text = '遺忘時間 秒',
        Default = 0.2, Min = 0, Max = 1.0, Rounding = 2,
        Callback = function(v) Config.AimbotForgetTime = v end
    })
    R:AddDropdown('AimbotTargetPart', {
        Values = {'Best','Head','Torso','Closest'},
        Default = 'Best', Text = '目標骨骼',
        Callback = function(v) Config.AimbotTargetPart = v end
    })
    R:AddDropdown('AimbotPriority', {
        Values = {'Crosshair','Health','Distance'},
        Default = 'Crosshair', Text = '優先順序',
        Callback = function(v) Config.AimbotPriority = v end
    })
    R:AddToggle('AimbotVisCheck', {
        Text = '可見性檢測',
        Default = true,
        Callback = function(v) Config.AimbotVisCheck = v end
    })
    R:AddToggle('AimbotSkipImmune', {
        Text = '跳過無敵',
        Default = true,
        Callback = function(v) Config.AimbotSkipImmune = v end
    })
    R:AddToggle('AimbotPrediction', {
        Text = '預測',
        Default = false,
        Callback = function(v) Config.AimbotPrediction = v end
    })
    R:AddSlider('AimbotReactionMs', {
        Text = '反應延遲 毫秒',
        Default = 0, Min = 0, Max = 300, Rounding = 0,
        Callback = function(v) Config.AimbotReactionMs = v end
    })
    R:AddSlider('AimbotNoiseDeg', {
        Text = '自瞄抖動 度/秒',
        Default = 0, Min = 0, Max = 20, Rounding = 1,
        Callback = function(v) Config.AimbotNoiseDeg = v end
    })
    R:AddToggle('AimbotShowFOV', {
        Text = '顯示視野圈',
        Default = false,
        Callback = function(v) Config.AimbotShowFOV = v end
    })
end

-- ============ 觸發 GUI ============
do
    local TB = Tabs.Combat:AddRightGroupbox('觸發機器人')
    TB:AddToggle('Trigger', {
        Text = '啟用觸發',
        Default = false,
        Callback = function(v) if v then Trigger.enable() else Trigger.disable() end end
    })
    TB:AddDropdown('TriggerKey', {
        Values = {'Always','MB2','MB1','C','E','F','Q','V','X','LeftShift','LeftAlt','LeftControl'},
        Default = 'Always', Text = '啟動方式',
        Callback = function(v) Config.TriggerKey = v end
    })
    TB:AddToggle('TriggerHeadOnly', {
        Text = '只打頭',
        Default = false,
        Callback = function(v) Config.TriggerHeadOnly = v end
    })
    TB:AddSlider('TriggerDelayMs', {
        Text = '反應延遲 毫秒',
        Default = 0, Min = 0, Max = 300, Rounding = 0,
        Callback = function(v) Config.TriggerDelayMs = v end
    })
    TB:AddSlider('TriggerRefireMs', {
        Text = '重射延遲 毫秒',
        Default = 0, Min = 0, Max = 500, Rounding = 0,
        Callback = function(v) Config.TriggerRefireMs = v end
    })
    TB:AddSlider('TriggerMaxDist', {
        Text = '最大距離',
        Default = 400, Min = 50, Max = 400, Rounding = 0,
        Callback = function(v) Config.TriggerMaxDist = v end
    })
end

-- ============ 隊伍檢測 GUI ============
do
    local T = Tabs.Combat:AddLeftGroupbox('目標選擇')
    T:AddToggle('TeamCheck', {
        Text = '隊伍檢測',
        Default = true,
        Callback = function(v) Config.TeamCheck = v end
    })
    T:AddDropdown('MaxDistance', {
        Values = {'100','500','1000','2000','5000','無限'},
        Default = '無限',
        Text = '最大距離',
        Callback = function(v)
            if v == '無限' then
                Config.MaxDistance = math.huge
            else
                Config.MaxDistance = tonumber(v) or math.huge
            end
        end
    })
end

print("[v12.0] 模組 2 載入完成：自瞄 + 觸發 + 隊伍檢測")
