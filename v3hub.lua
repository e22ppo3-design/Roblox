local V3HUB_SELF_URL = "https://raw.githubusercontent.com/e22ppo3-design/Roblox/main/v3hub.lua"
task.spawn(function()
    local ok = pcall(function()
        local queueFn = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
        if not queueFn then return end
        if V3HUB_SELF_URL == "" or V3HUB_SELF_URL:find("你的帳號") then return end
        queueFn("loadstring(game:HttpGet('" .. V3HUB_SELF_URL .. "'))()")
    end)
end)

local hookmetamethod = hookmetamethod
local getrawmetatable = getrawmetatable
local setreadonly = setreadonly
local checkcaller = checkcaller
local getnamecallmethod = getnamecallmethod
local getconnections = getconnections
local hookfunction = hookfunction
local newcclosure = newcclosure
local getrenv = getrenv
local getgc = getgc
local getfenv = getfenv
local getgenvFn = getgenv
local clonefunction = clonefunction
local firetouchinterest = firetouchinterest
local getthreadidentity = getthreadidentity or get_thread_identity or getidentity or getthreadcontext
local setthreadidentity = setthreadidentity or set_thread_identity or setidentity or setthreadcontext
local sethiddenproperty = sethiddenproperty or set_hidden_property
local gethiddenproperty = gethiddenproperty or get_hidden_property
local setfflag = setfflag or setfastflag or set_fflag
local getfflag = getfflag or getfastflag
local debugLib = debug

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local W = game:GetService("Workspace")
local C = W.CurrentCamera
local LP = Players.LocalPlayer
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local VirtualInputMgr = game:GetService("VirtualInputManager")
local SoundService = game:GetService("SoundService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local StatsService = game:GetService("Stats")

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

local Modules = RS:WaitForChild("Modules", 10)
local Utility, EnumLibrary, CosmeticLibrary, ItemLibrary
pcall(function() Utility = require(Modules:WaitForChild("Utility", 5)) end)
pcall(function() EnumLibrary = require(Modules:WaitForChild("EnumLibrary", 5)) end)
pcall(function() CosmeticLibrary = require(Modules:WaitForChild("CosmeticLibrary", 5)) end)
pcall(function() ItemLibrary = require(Modules:WaitForChild("ItemLibrary", 5)) end)

local PlayerScripts = LP:WaitForChild("PlayerScripts", 10)
local Controllers = PlayerScripts and PlayerScripts:FindFirstChild("Controllers")
local FighterController, CameraController
pcall(function() FighterController = require(Controllers:WaitForChild("FighterController", 5)) end)
pcall(function() CameraController = require(Controllers:WaitForChild("CameraController", 5)) end)

local GunModule, MeleeModule, KnifeModule, GameplayUtility
pcall(function() GunModule = require(PlayerScripts:WaitForChild("Modules", 8):WaitForChild("ItemTypes", 5):WaitForChild("Gun", 5)) end)
pcall(function() MeleeModule = require(PlayerScripts:WaitForChild("Modules", 8):WaitForChild("ItemTypes", 5):WaitForChild("Melee", 5)) end)
pcall(function() KnifeModule = require(PlayerScripts:WaitForChild("Modules", 8):WaitForChild("Items", 5):WaitForChild("Knife", 5)) end)
pcall(function() GameplayUtility = require(Modules:WaitForChild("GameplayUtility", 5)) end)

local localFighter = FighterController and FighterController.LocalFighter

local Remotes = RS:FindFirstChild("Remotes")
local Replication = Remotes and Remotes:FindFirstChild("Replication")
local FighterRemote = Replication and Replication:FindFirstChild("Fighter")
local UseItem = FighterRemote and FighterRemote:FindFirstChild("UseItem")
local SetControls = FighterRemote and FighterRemote:FindFirstChild("SetControls")
local UpdateCameraRotation = FighterRemote and FighterRemote:FindFirstChild("UpdateCameraRotation")

local _fighterCache = nil
local _fighterCacheTime = 0
local function getLocalFighter()
    local now = tick()
    if _fighterCache and (now - _fighterCacheTime) < 0.25 and _fighterCache.EquippedItem ~= nil then
        return _fighterCache
    end
    local ok, fc = pcall(function()
        return require(LP.PlayerScripts.Controllers.FighterController)
    end)
    if ok and fc and fc.LocalFighter then
        _fighterCache = fc.LocalFighter
        _fighterCacheTime = now
        return _fighterCache
    end
    _fighterCache = nil
    return nil
end
LP.CharacterAdded:Connect(function()
    _fighterCache = nil
    _fighterCacheTime = 0
    task.wait(0.5)
    getLocalFighter()
end)

local S = {
    SilentEnabled = false, SilentHitPart = "Head", SilentHitChance = 100, SilentFOV = 150,
    SilentAutoShoot = false, SilentFollowMuzzle = false, SilentWallCheck = true,
    Silent360 = false, SilentJitter = true, SilentAvoidDeflect = true,
    SilentStickiness = 0.05, SilentMultipoint = false, SilentMultipointCount = 5,
    SilentTorsoFallback = false, SilentBodyMix = 25, SilentJitterDeg = 1.5,

    AimEnabled = false, AimKey = "MB2", AimVisCheck = true,
    AimSmoothness = 0, AimSmoothnessX = 0, AimSmoothnessY = 0, AimLinkAxes = true,
    AimJumpDamping = 40, AimCancelSprings = true,
    AimCurvedFlick = false, AimCurvedIntensity = 0.35,
    AimTrackAssist = 100, AimFOVDeg = 20, AimMaxSpeed = 0,
    AimDeadzoneDeg = 0, AimSwitchDeg = 2, AimStickiness = 0.15,
    AimForgetTime = 0.2, AimTargetPart = "Best", AimPriority = "Crosshair",
    AimSkipImmune = true, AimPrediction = false,
    AimShotOverride = false, AimShowFOV = false, AimShowLock = false,
    AimDebug = false, AimReactionMs = 0, AimNoiseDeg = 0, AimOvershoot = 0,
    AimDirectCamera = false,

    RageEnabled = false, RageMode = "Polar",
    RageDirectFire = true, RageRateLimit = false, RageTaps = 6, RageTapsPerFrame = 1,
    RageVoidMove = true, RageVoidDepth = "deep", RageVoidMinStep = 25000,
    RageVoidJitterLocal = false, RageVoidJitterStuds = 2000,
    RageEyeMuzzleSep = 0.07, RageGatePoison = true,
    RagePredictPrefire = true, RageSkipImmune = true,
    RageIdentityDance = true, RagePredictResurface = true, RageAttackContinuity = true,
    RageKnifeBot = true, RageMeleeAsk = true, RageKnifeCamForge = true,
    RageParkLift = false, RagePolarParity = true, RagePhysicsFlags = true,
    RageRestoreMode = "auto", RageCameraAnchor = true,
    RagePartGlue = false, RageGumMode = "on", RageGumVoidFire = true,
    RageAttackTranslocate = true, RageBaitHeldMs = 300, RageBaitRate = 2,
    RagePrioritizeHackers = true, RageHideJitter = true,
    RageHPPriority = true, RageFastTargetSwitch = true, RageVisCheck = false,
    RageShieldBackstab = true, RageKnifeBackstab = true,
    RageKillPlaneBuffer = 200, RageLab = false, RageVoidPhase = true,
    RageOnEmpty = "Swap", RagePreferredSlot = "Primary",
    RageSwitchMelee = false, RageSwitchRateLimit = 0.06,
    RageFireRateOverride = 0, RageEyeMuzzleClamp = true,

    AntiAimEnabled = false, AntiAimYaw = "jitter", AntiAimPitch = "jitter",
    AntiAimAngle = "none", AntiAimCustomAngle = 0,
    AntiAimMinSpeed = 10, AntiAimMaxSpeed = 20,
    AntiAimMinAngle = 30, AntiAimMaxAngle = 60,
    AntiAimRandomAngle = false,

    ESPEnabled = true, ESPShowName = true, ESPShowDistance = true,
    ESPShowHealth = true, ESPShowTracer = true, ESPShowSkeleton = true,
    ESPMaxDistance = 1200, ESPTeamCheck = true,
    ESPFont = "Code", ESPTextSize = 14, ESPInfoTextSize = 12, ESPHealthTextSize = 11,
    ESPTextScale = 1, ESPBoxScale = 1, ESPBoxStyle = "Full Box",
    ESPBoxThickness = 1, ESPCasingThickness = 1,
    ESPBoxColor = Color3.fromRGB(235, 235, 245),
    ESPHealthColorMode = "Ramp",
    ESPNameColor = Color3.fromRGB(243, 246, 250),
    ESPDistanceColor = Color3.fromRGB(174, 185, 197),
    ColorEnemy = Color3.fromRGB(255, 59, 78),
    ColorTeam = Color3.fromRGB(53, 215, 199),
    ColorEnemyOcc = Color3.fromRGB(168, 85, 96),
    ColorTeamOcc = Color3.fromRGB(92, 153, 147),
    ESPHealthColor = Color3.fromRGB(61, 224, 122),
    ESPHealthGradA = Color3.fromRGB(255, 68, 54),
    ESPHealthGradB = Color3.fromRGB(61, 224, 122),
    ESPHealthSmooth = true, ESPHealthGhost = true,
    ESPHealthNumberMode = "OnDamage",
    ESPSkeletonColor = Color3.fromRGB(255, 255, 255),
    ESPSkeletonThickness = 1,
    ESPTracerColor = Color3.fromRGB(255, 59, 78),
    ESPTracerOrigin = "Bottom", ESPTracerThickness = 1,
    ESPChams = false, ESPChamsFillColor = Color3.fromRGB(255, 59, 78),
    ESPChamsOutlineColor = Color3.fromRGB(255, 255, 255),
    ESPChamsStyle = "Shade", ESPChamsVisSplit = true,
    ColorVisible = Color3.fromRGB(41, 224, 255),
    ESPArrows = false, ESPRadar = false,
    ESPFlagDeflect = true, ESPFlagShield = true,
    ESPFlagInvincible = true, ESPFlagLowHP = true, ESPFlagStaring = false,
    ESPMaxPlayers = 0, ESPFadeIn = true, ESPDeclutter = true,

    CrosshairEnabled = false, CrosshairColor = Color3.fromRGB(0, 200, 255),
    CrosshairShowLines = true, CrosshairSpinSpeed = 150, CrosshairMode = "static",

    InfJump = false, JumpPower = 50, WalkSpeed = 16,
    FlyEnabled = false, FlySpeed = 50, Noclip = false,

    NoCooldown = false, NoSpread = false, NoRecoil = false,
    MaxAccuracy = false, RapidAttack = false, NoMuzzleFlash = false,
    AntiKatana = false,

    DeviceSpoof = false, DeviceType = "PC",
    TeamCheck = true, AntiAFK = true,

    AutoQueueEnabled = false, AutoQueueMode = "1v1",
    AutoQueueRanked = false, AutoQueueDelay = 2,

    FXHitMarker = true,
    FXHitMarkerColor = Color3.fromRGB(255, 255, 255),
    FXHitMarkerCritColor = Color3.fromRGB(255, 194, 75),
    FXHitMarkerLethalColor = Color3.fromRGB(255, 64, 78),
    FXHitMarkerGap = 5, FXHitMarkerLen = 8, FXHitMarkerThickness = 2,
    FXHitMarkerStyle = "X",
    FXDamageNumbers = true,
    FXDamageAccumWindow = 0.9,
    FXKillBanner = true,
    FXKillBannerColor = Color3.fromRGB(255, 194, 75),
    FXKillFeed = true,
    FXHeadshotSpark = true,
    FXHitFlash = true,
    FXDamageDirection = true,
    FXLowHPVignette = true,
    FXLowHPThreshold = 0.35,
    FXCritDamage = 30,
    FXBeamTracer = false,
    FXBeamStyle = "Glow",
    FXBeamHitColor = Color3.fromRGB(255, 194, 75),
    FXFovRing = false,
    FXFovColorA = Color3.fromRGB(53, 215, 199),
    FXFovColorB = Color3.fromRGB(255, 194, 75),
    FXFovThickness = 1.5,
    FXFovCasing = true,
    FXCrosshair = false,
    FXCrosshairStyle = "Cross",
    FXCrosshairColor = Color3.fromRGB(243, 246, 250),
    FXCrosshairDot = true,
    FXCrosshairGap = 4,
    FXCrosshairLen = 7,
    FXCrosshairThickness = 2,
    FXCrosshairOutline = true,
    FXCrosshairHitPop = true,
    FXCrosshairAngle = 0,
    FXCrosshairSpin = false,
    FXCrosshairSpinSpeed = 1.0,
    FXCrosshairSniper = false,
    FXCrosshairBounce = false,
    FXCrosshairBounceAmt = 4,
    HUDWatermark = true,
    HUDWatermarkStats = true,
}

local hasMouseMoveRel = type(mousemoverel) == "function"
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

local State = {
    Target = nil, CamPos = Vector3.zero,
    AimbotTarget = nil, AimbotPart = nil,
    AimbotLastTarget = nil, AimbotLastTargetTime = 0,
    AimbotKeyHeld = false, SilentLastTarget = nil,
    Shots = 0, Hits = 0,
    ESPObjects = {},
    RainbowHue = 0,
    RageTarget = nil, RageRealCF = nil, RageRealChar = nil,
    RageVoidCF = nil, RageVoidNext = 0, RageVoidBase = nil, RageVoidSteps = 0,
    RageLastFireTime = 0, RageReloadLast = 0, RageSwitchLast = 0,
    RageInMatch = false, RageStatus = "Idle",
    RageFiring = false, RageVoidActive = false, RageTranslocating = false,
    RageFireFromPos = nil, RageFireAimPos = nil, RageFireHitPart = nil, RageFireStamp = 0,
    RageDealtTotal = 0, RageTrueVelocityMap = {},
    RageSuspectedProtection = {}, RageBacktrackBuf = {}, RageCharTokens = {},
    RageGlueBound = false, RageGumMode = "off", RageGlueVerified = "n/a",
    IdentitySafe = nil, CapabilityObserver = false,
    CapabilityErrors = 0, CapabilityKilledAt = nil,
    CapabilityLastStatus = nil, CapabilityRecoveries = 0, CapabilityDirty = false,
    CapabilitySeam = nil,
    ViewAngleForged = false,
    RageWhyProtected = 0, RageWhyNoPark = 0, RageWhyPrimeWait = 0,
    RageWhyPredict = 0, RageWhyDip = 0, RageWhyMeleeCd = 0,
    RageFireFrames = 0, RageImmuneStale = 0, RageAmmoUnreadable = 0,
    RageBaitHoldFrames = 0, RageBaitPinRefused = 0, RageBaitRingFallbacks = 0,
    RageVoidFires = 0, RagePoisonBlips = 0, RagePreFires = 0,
    RagePredTarget = nil, RagePredHide = 0, RagePredHideN = 0,
    RagePredAtk = 0, RagePredAtkN = 0, RagePredPhase = "?",
    RagePredFor = 0, RagePredDue = 0, RagePredWindow = false, RagePredMag = 0,
    RageParkDirty = false, RageLastParkPos = nil,
    RageParkLatchCanary = 0, RageLatchStuds = 0, RageOrderCanary = 0,
    RagePostPark = false, RageBelowPlaneFrames = 0, RageBelowPlaneLast = 0,
    RageBelowPlaneDeaths = 0, RageParkDriftFrames = 0, RageParkDrift = 0,
    RageParkDriftY = 0, RageEyeClampFrames = 0, RageParkClampFrames = 0,
    RageTranslocateBaits = 0, RageFireZeroFrames = 0,
    RageBlankCanary = 0, RageTracerCanary = 0, RageOOBParkCanary = 0,
    RageHitsOn = 0, RageHitsOff = 0, RageOffFromSelf = 0, RageOffFromTarget = 0,
    RageKnifeSwings = 0, RageKnifeStatus = "idle", RageRawSet = false,
    RagePhysRate = "off", RageFPDHPath = "not attempted",
    RageImmuneOverride = 0, RageFireWhy = nil,
}

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

local function envIdOf(player)
    local id = nil
    pcall(function()
        local fc = FighterController
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

local function isEnemy(plr)
    if not plr or plr == LP then return false end
    if not S.TeamCheck then return true end
    return not isTeammate(plr)
end

local function isAlive(player)
    local c = player.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h ~= nil and h.Health > 0
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

local function getHealth(player)
    if not player.Character then return 0, 100 end
    local h = player.Character:FindFirstChildOfClass("Humanoid")
    if not h then return 0, 100 end
    return h.Health, h.MaxHealth
end

local function getEquippedItem()
    local lf = getLocalFighter()
    return lf and lf.EquippedItem or nil
end

local function getWeaponName(player)
    if not player or not player.Character then return "?" end
    local ok, res = pcall(function()
        local fc = FighterController
        if fc and fc._player_to_fighter then
            local f = fc._player_to_fighter[player]
            if f and f.EquippedItem and f.EquippedItem.Info then
                return f.EquippedItem.Info.Name
            end
        end
        return nil
    end)
    if ok and type(res) == "string" and res ~= "" then return res end
    return "?"
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
    if ok and type(val) == "number" and val == val then return val + S.RageKillPlaneBuffer end
    return -400
end

local function clampHop(targetPos, fromPos, maxHop)
    local d = targetPos - fromPos
    local m = d.Magnitude
    if m <= maxHop or m == 0 then return targetPos end
    return fromPos + d * (maxHop / m)
end

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
        _identitySafeLatched = (S.RageIdentityDance == true)
        State.IdentitySafe = _identitySafeLatched
    end
    return _identitySafeLatched
end

local function atId2(fn, ...)
    if _identSet == nil or not identityIsSafe() then return pcall(fn, ...) end
    local done, ok, res = false, false, nil
    task.spawn(function()
        local okPrev, prev = pcall(_identGet)
        if not okPrev then return end
        if not pcall(_identSet, 2) then return end
        done = true
        ok, res = pcall(fn, ...)
        pcall(_identSet, prev)
    end)
    if done then return ok, res end
    return pcall(fn, ...)
end

local function atId8(fn, ...)
    if _identSet == nil or not identityIsSafe() then return pcall(fn, ...) end
    local done, ok, res = false, false, nil
    task.spawn(function()
        local okPrev, prev = pcall(_identGet)
        if not okPrev then return end
        if not pcall(_identSet, 8) then return end
        done = true
        ok, res = pcall(fn, ...)
        pcall(_identSet, prev)
    end)
    if done then return ok, res end
    return pcall(fn, ...)
end

local _identityIsSafeFn = (function()
    local latched, killed = nil, false
    State.CapabilityObserver = false
    pcall(function()
        game:GetService("LogService").MessageOut:Connect(function(msg)
            if type(msg) ~= "string" or not string.find(msg, "lacking capability", 1, true) then return end
            State.CapabilityErrors = (State.CapabilityErrors or 0) + 1
            State.CapabilityLastStatus = tostring(State.RageStatus)
            if not killed then
                killed = true
                State.CapabilityKilledAt = tostring(State.RageStatus)
                State.CapabilityDirty = true
            end
        end)
        State.CapabilityObserver = true
    end)
    return function()
        if latched == nil then
            latched = (S.RageIdentityDance == true)
            State.IdentitySafe = latched
        end
        return latched
    end
end)()

local ConstPatch = {}
;(function()
    local _getconstants = getconstants or (debugLib and debugLib.getconstants)
    local _setconstant = setconstant or (debugLib and debugLib.setconstant)
    local _getprotos = getprotos or (debugLib and debugLib.getprotos)
    local _getproto = getproto or (debugLib and debugLib.getproto)
    local HAVE_CONST = type(_getconstants) == "function" and type(_setconstant) == "function"
    local HAVE_PROTOS = type(_getprotos) == "function" and type(_getproto) == "function"
    local _sets = {}
    local function ledger(create)
        if not getgenvFn then return nil end
        local g = getgenvFn()
        local t = rawget(g, "__LH_ConstLedger")
        if not t and create then
            t = {}
            g.__LH_ConstLedger = t
        end
        return t
    end
    local HASH_SEED = 5381
    local STR_CAP = 256
    local function hashByte(h, b) return bit32.band(bit32.lshift(h, 5) + h + b, 0xFFFFFFFF) end
    local function hashString(h, s)
        local n = #s
        h = hashByte(h, bit32.band(n, 0xFF))
        h = hashByte(h, bit32.band(bit32.rshift(n, 8), 0xFF))
        local upto = math.min(n, STR_CAP)
        for i = 1, upto do h = hashByte(h, string.byte(s, i)) end
        return h
    end
    local function hashValue(h, v)
        local t = typeof(v)
        h = hashString(h, t)
        if t == "string" then return hashString(h, v) end
        if t == "number" then return hashString(h, string.format("%.17g", v)) end
        if t == "boolean" then return hashByte(h, v and 1 or 0) end
        return h
    end
    function ConstPatch.fingerprint(fn)
        if not HAVE_CONST or type(fn) ~= "function" then return nil end
        local ok, result = pcall(function()
            local consts = _getconstants(fn)
            if type(consts) ~= "table" then return nil end
            local h = HASH_SEED
            for i, v in consts do
                h = hashValue(h, i)
                h = hashValue(h, v)
            end
            if HAVE_PROTOS then
                local protos = _getprotos(fn)
                if type(protos) == "table" then h = hashValue(h, #protos) end
            end
            return h
        end)
        return ok and result or nil
    end
    local function resolveFn(src)
        if type(src.fn) == "function" then return src.fn end
        if type(src.holder) ~= "table" then return nil end
        local v = rawget(src.holder, src.name)
        return type(v) == "function" and v or nil
    end
    local function candidates(fn, src)
        if src.scan ~= "protos" then return { fn } end
        if not HAVE_PROTOS then return nil, "no getprotos" end
        local ok, protos = pcall(_getprotos, fn)
        if not ok or type(protos) ~= "table" then return nil, "getprotos failed" end
        local out = {}
        for i in protos do
            local okG, live = pcall(_getproto, fn, i, true)
            if okG and type(live) == "table" and type(live[1]) == "function" then
                out[#out + 1] = live[1]
            end
        end
        return out
    end
    local function collectMatches(fn, src)
        local ok, consts = pcall(_getconstants, fn)
        if not ok or type(consts) ~= "table" then return nil, "getconstants failed" end
        if src.index ~= nil then
            if src.expect == nil then return nil, "index mode needs expect" end
            local cur = consts[src.index]
            if cur == nil then return nil, "no const at " .. tostring(src.index) end
            if cur ~= src.expect then return nil, "index holds " .. tostring(cur) end
            return { { index = src.index, old = cur } }
        end
        local hits = {}
        for i, v in consts do
            if v == src.target then hits[#hits + 1] = { index = i, old = v } end
        end
        return hits
    end
    local function validateSource(src)
        if type(src) ~= "table" then return "not a table" end
        if type(src.name) ~= "string" then return "needs name" end
        if type(src.fn) ~= "function" and type(src.holder) ~= "table" then return "needs fn or holder" end
        if (src.target == nil) == (src.index == nil) then return "needs exactly one of target/index" end
        if src.new == nil then return "needs new" end
        if src.scan ~= nil and src.scan ~= "self" and src.scan ~= "protos" then return "bad scan" end
        if src.index ~= nil and src.scan == "protos" then return "index cannot combine protos" end
        return nil
    end
    local Set = {}
    Set.__index = Set
    function ConstPatch.new(name, sources)
        local set = setmetatable({ name = name, sources = sources, restores = nil }, Set)
        _sets[#_sets + 1] = set
        return set
    end
    function Set:Apply()
        if not HAVE_CONST then return false, "no debug.getconstants" end
        if self.restores then return false, self.name .. ": already applied" end
        local plan = {}
        for _, src in self.sources do
            local label = self.name .. "/" .. tostring(src.name or "?")
            local shapeErr = validateSource(src)
            if shapeErr then return false, label .. ": " .. shapeErr end
            local fn = resolveFn(src)
            if not fn then return false, label .. ": cannot resolve" end
            if src.fingerprint ~= nil then
                local got = ConstPatch.fingerprint(fn)
                if got ~= src.fingerprint then
                    return false, string.format("%s: VERSION GATE %s != %s", label, tostring(got), tostring(src.fingerprint))
                end
            end
            local cands, cerr = candidates(fn, src)
            if not cands then return false, label .. ": " .. cerr end
            local found = 0
            for _, cand in cands do
                local hits, herr = collectMatches(cand, src)
                if not hits then return false, label .. ": " .. herr end
                if #hits > 1 then return false, label .. ": AMBIGUOUS" end
                if #hits == 1 then
                    local hit = hits[1]
                    if typeof(src.new) ~= typeof(hit.old) then
                        return false, label .. ": type change refused"
                    end
                    found = found + 1
                    plan[#plan + 1] = { fn = cand, index = hit.index, old = hit.old, new = src.new }
                end
            end
            local exact = src.count
            if exact == nil and src.scan ~= "protos" then exact = 1 end
            if exact ~= nil and found ~= exact then
                return false, string.format("%s: found %d expected %d", label, found, exact)
            end
        end
        local restores = {}
        self.restores = restores
        local led = ledger(true)
        for _, p in plan do
            local ok = pcall(_setconstant, p.fn, p.index, p.new)
            if not ok then self:Revert() return false, self.name .. ": setconstant failed" end
            local rec = { fn = p.fn, index = p.index, old = p.old }
            restores[#restores + 1] = rec
            if led then led[#led + 1] = rec end
        end
        return true
    end
    function Set:Revert()
        local restores = self.restores
        if not restores then return end
        self.restores = nil
        local led = ledger()
        for i = #restores, 1, -1 do
            local rec = restores[i]
            pcall(_setconstant, rec.fn, rec.index, rec.old)
            if led then
                for j = #led, 1, -1 do
                    if led[j] == rec then table.remove(led, j) break end
                end
            end
        end
    end
    function Set:IsApplied() return self.restores ~= nil end
    function ConstPatch.revertAll()
        for _, set in _sets do pcall(function() set:Revert() end) end
        local led = ledger()
        if not led or not _setconstant then return end
        for i = #led, 1, -1 do
            local rec = led[i]
            if type(rec) == "table" and type(rec.fn) == "function" then
                pcall(_setconstant, rec.fn, rec.index, rec.old)
            end
            led[i] = nil
        end
    end
    function ConstPatch.available() return HAVE_CONST, HAVE_PROTOS end
end)()

local ViewAngle = {}
;(function()
    local _remote = nil
    local _forged = nil
    local _loopFn, _utilIdx, _utilOrig = nil, nil, nil
    local _suppressed = false
    local _joints, _jointsOrig = nil, nil

    local function remote()
        if _remote == nil then
            pcall(function() _remote = UpdateCameraRotation end)
        end
        return _remote
    end

    local function resolveLoop()
        if _loopFn ~= nil then return true end
        if shared._LH_ViewLoopFn ~= nil and shared._LH_ViewUtilOrig ~= nil then
            _loopFn = shared._LH_ViewLoopFn
            _utilIdx = shared._LH_ViewUtilIdx
            _utilOrig = shared._LH_ViewUtilOrig
            return true
        end
        if type(debugLib) ~= "table" or type(debugLib.getupvalues) ~= "function" or type(debugLib.setupvalue) ~= "function" then
            return false
        end
        pcall(function()
            local F = FighterController
            if F == nil then return end
            local fn = rawget(F, "_CameraReplicationLoop")
            if type(fn) ~= "function" then
                local mt = getmetatable(F)
                local proto = mt and rawget(mt, "__index")
                if type(proto) == "table" then fn = rawget(proto, "_CameraReplicationLoop") end
            end
            if type(fn) ~= "function" then return end
            for i, v in debugLib.getupvalues(fn) do
                if type(v) == "table" then
                    local vmt = getmetatable(v)
                    local vidx = vmt and rawget(vmt, "__index")
                    if type(vidx) == "table" and rawget(vidx, "EncodeCameraRotation") ~= nil then
                        _loopFn, _utilIdx, _utilOrig = fn, i, v
                        shared._LH_ViewLoopFn = fn
                        shared._LH_ViewUtilIdx = i
                        shared._LH_ViewUtilOrig = v
                        return
                    end
                end
            end
        end)
        return _loopFn ~= nil
    end

    local function makeShim()
        local shim = {}
        shim.EncodeCameraRotation = function(_, rot)
            local last = nil
            pcall(function()
                local F = FighterController
                if F ~= nil then
                    F._replication_stopped = false
                    last = F._last_encoded_camera_rotation
                end
            end)
            if last ~= nil then return last end
            return _utilOrig:EncodeCameraRotation(rot)
        end
        return setmetatable(shim, { __index = _utilOrig })
    end

    local function suppress(on)
        if on == _suppressed then return end
        if on then
            if not resolveLoop() then return end
            if pcall(debugLib.setupvalue, _loopFn, _utilIdx, makeShim()) then
                _suppressed = true
                State.ViewAngleForged = true
            end
            return
        end
        if _loopFn ~= nil and _utilOrig ~= nil then
            pcall(debugLib.setupvalue, _loopFn, _utilIdx, _utilOrig)
        end
        _suppressed = false
        State.ViewAngleForged = false
    end

    local function patchJoints(on)
        if on then
            if _jointsOrig ~= nil then return end
            pcall(function()
                local ok, m = pcall(function()
                    return require(LP.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientFighterCharacter.Joints)
                end)
                if not ok or type(m) ~= "table" then return end
                _joints = m
                local orig = shared._LH_JointsUpdateOrig or rawget(m, "Update")
                if type(orig) ~= "function" then _joints = nil return end
                shared._LH_JointsUpdateOrig = orig
                _jointsOrig = orig
                if setreadonly then pcall(setreadonly, m, false) end
                m.Update = function(selfJoints, dt, data)
                    if _forged ~= nil and type(data) == "table" then
                        pcall(function()
                            local cfc = selfJoints.ClientFighterCharacter
                            local cf = cfc and cfc.ClientFighter
                            if cf and cf.IsLocalPlayer == true then
                                data.CameraRotationRaw = _forged
                            end
                        end)
                    end
                    return orig(selfJoints, dt, data)
                end
            end)
            return
        end
        if _joints ~= nil and _jointsOrig ~= nil then
            pcall(function()
                if setreadonly then pcall(setreadonly, _joints, false) end
                _joints.Update = _jointsOrig
            end)
        end
        _jointsOrig = nil
    end

    function ViewAngle.forge(pitch, yaw)
        local r = remote()
        if r == nil or not Utility then return false end
        local ok = pcall(function()
            local enc = Utility:EncodeCameraRotation(Vector2.new(pitch, yaw))
            _forged = Utility:DecodeCameraRotation(enc)
            r:FireServer(enc, nil)
        end)
        if not ok then return false end
        suppress(true)
        patchJoints(true)
        return true
    end

    function ViewAngle.restore()
        _forged = nil
        suppress(false)
        patchJoints(false)
    end

    ViewAngle.isForging = function() return _forged ~= nil end
end)()

print("[v11.0] 第一段載入完成")local _sharedVelMap = {}
do
    local _svPos, _svTime = {}, {}
    local _svAccum = 0
    local SV_INTERVAL = 1/30
    if shared._LH_velConn then pcall(function() shared._LH_velConn:Disconnect() end) end
    shared._LH_velConn = RunService.Heartbeat:Connect(function(dt)
        if not (S.AimEnabled or S.SilentEnabled or S.RageEnabled) then return end
        _svAccum = _svAccum + (dt or 0)
        if _svAccum < SV_INTERVAL then return end
        _svAccum = 0
        local now = tick()
        for _, p in ipairs(getSafePlayers()) do
            if p ~= LP and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local pos = hrp.Position
                    local lt = _svTime[p]
                    if _svPos[p] and lt then
                        local d = now - lt
                        if d > 0 then
                            local v = (pos - _svPos[p]) / d
                            if v.Magnitude < 500 then _sharedVelMap[p] = v end
                        end
                    end
                    _svPos[p] = pos
                    _svTime[p] = now
                end
            end
        end
    end)
end

local function calculateLead(targetChar, fromPos, wantLead)
    if wantLead == nil then wantLead = S.SilentEnabled or S.AimEnabled end
    if not targetChar then return Vector3.new() end
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return Vector3.new() end
    local lat = (LP:GetNetworkPing() or 0.05) + 0.03
    local lead = Vector3.new()
    if wantLead then
        local ply = Players:GetPlayerFromCharacter(targetChar)
        local trueVel = hrp.AssemblyLinearVelocity
        local calcVel = ply and (_sharedVelMap[ply] or State.RageTrueVelocityMap[ply])
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

local _invincible, _invincEnt = {}, {}
local function isSpawnProtected(player)
    if not player then return false end
    if player.Character and player.Character:FindFirstChildOfClass("ForceField") then return true end
    if not (FighterController) then return false end
    local map = FighterController._player_to_fighter
    if not map then return false end
    local f = map[player]
    if not f then return false end
    local e = f.Entity
    if not e then return false end
    local uid = player.UserId
    if _invincEnt[uid] ~= e then
        _invincible[uid] = nil
        local ok = pcall(function()
            local live = e:Get("IsInvincible") == true
            e:GetDataChangedSignal("IsInvincible"):Connect(function()
                _invincible[uid] = e:Get("IsInvincible") == true
            end)
            _invincible[uid] = live
        end)
        if ok then _invincEnt[uid] = e end
    end
    local okLive, live = pcall(function() return e:Get("IsInvincible") == true end)
    if okLive then
        if live ~= (_invincible[uid] == true) then
            State.RageImmuneStale = (State.RageImmuneStale or 0) + 1
        end
        _invincible[uid] = live
        return live
    end
    return _invincible[uid] == true
end

local MELEE_NMS = {
    ["Battle Axe"]=true,["Chainsaw"]=true,["Daggers"]=true,["Fists"]=true,
    ["Gunblade"]=true,["Katana"]=true,["Knife"]=true,["Scythe"]=true,["Trowel"]=true,
}
local KATANA_NAMES = {"katana","saber","lightning bolt","evil trident","tridant","devil's trident","linked sword","keytana","cutlass","swordfish","riptide"}
local KNIFE_NAMES = {"knife","karambit","balisong","chancla","machete","candy cane","armature","daggers","axe"}

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
        if not (FighterController and FighterController._player_to_fighter) then return false end
        local f = FighterController._player_to_fighter[player]
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
        local lf = FighterController and FighterController.LocalFighter
        if lf ~= nil and lf:Get("EnvironmentID") ~= nil and lf:IsAlive() then envOk = true end
    end)
    if envOk then return true end
    if LP:GetAttribute("TeamID") ~= nil then return true end
    if LP.Team ~= nil then return true end
    local lf = getLocalFighter()
    if lf then
        local ok, objId = pcall(function() return lf.EquippedItem and lf.EquippedItem:Get("ObjectID") end)
        if ok and objId then return true end
    end
    return false
end

local function isValidTarget(player, checkVis, keepDeflect, rageScope)
    if not player or player == LP then return false end
    if S.TeamCheck and isTeammate(player) then return false end
    if not isAlive(player) then return false end
    if S.SilentAvoidDeflect and not keepDeflect and isDeflecting(player) then return false end
    if S.RageSkipImmune and not rageScope and isSpawnProtected(player) then return false end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local sane = isSanePos(hrp.Position)
    if not rageScope then
        if not sane then return false end
        local myChar = LP.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myRoot and (hrp.Position - myRoot.Position).Magnitude > S.ESPMaxDistance then return false end
    end
    if checkVis and sane and not isVisible(hrp.Position) then return false end
    return true
end

local function pickPart(char, mode)
    if not char then return nil end
    if mode == "Closest" then
        local best, bestDist = nil, math.huge
        local vp = C.ViewportSize
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
    local list = mode == "Torso" and {"HitboxBody","UpperTorso","HumanoidRootPart","LowerTorso"} or {"HitboxHead","HitboxHeadSmall","Head"}
    for _, name in ipairs(list) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then return p end
    end
    return char:FindFirstChild("HumanoidRootPart")
end

local function selectTarget(opts)
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

local Rage = {}
;(function()
    local _tgtConn = nil
    local function bump(p) State.RageCharTokens[p] = (State.RageCharTokens[p] or 0) + 1 end
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
    local function buildShotFields(camData, eyeCF, muzzleCF, hitPart, aimWorldPos, jitter, clampFrac, jitterFrac)
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
        local hitWorld = hitPart.CFrame:PointToWorldSpace(objSpace)
        local objSpaceCF = hitPart.CFrame:ToObjectSpace(CFrame.new(hitWorld))
        camData[utf8.char(0)] = Utility:EncodeCFrame(eyeCF)
        camData[utf8.char(1)] = Utility:EncodeCFrame(muzzleCF)
        camData[utf8.char(2)] = hitPart
        camData[utf8.char(3)] = Utility:EncodeCFrame(objSpaceCF)
    end
    Rage._buildShotFields = buildShotFields
    local RAGE_CLAMP_FRAC = 0.30
    local function encodeShot(camData, hitPart, targetChar, fromCamPos, claimOffset)
        if not hitPart or not camData or not Utility then return false end
        local lead = calculateLead(targetChar, fromCamPos)
        local off = (typeof(claimOffset) == "Vector3") and claimOffset or Vector3.zero
        local leadedPos = hitPart.Position + lead + off
        local eyeCF = lookCF(fromCamPos, leadedPos)
        local muzzlePos = fromCamPos + (eyeCF.RightVector * 0.2) + Vector3.new(0, -S.RageEyeMuzzleSep, 0)
        local muzzleCF = lookCF(muzzlePos, leadedPos)
        buildShotFields(camData, eyeCF, muzzleCF, hitPart, leadedPos, S.SilentJitter, 0.45, 1.0)
        return true
    end
    Rage._encodeShot = encodeShot
    local PICK_SLOT = { Primary = 1, Secondary = 2, Melee = 3 }
    local function fighterItems()
        local lf = getLocalFighter()
        return lf and lf.Items or nil
    end
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
    local function itemAmmo(item)
        if not item then return nil end
        local ok, a = pcall(function() return item:Get("Ammo") or item:Get("CurrentAmmo") end)
        if ok and type(a) == "number" then return a end
        return nil
    end
    local function slotItemByIndex(idx)
        local items = fighterItems(); if not items then return nil end
        if items[idx] then return items[idx] end
        if items[tostring(idx)] then return items[tostring(idx)] end
        for key, it in pairs(items) do
            if it and typeof(it) == "table" then
                local okS, s = pcall(function() return tonumber(it:Get("Slot") or it:Get("Index") or it:Get("ItemSlot") or key) end)
                if okS and s == idx then return it end
            end
        end
        return nil
    end
    local function whichSlotNow()
        local cur = getEquippedItem(); if not cur then return nil end
        local okId, oid = pcall(function() return cur:Get("ObjectID") end)
        if okId and oid then
            for idx = 1, 3 do
                local it = slotItemByIndex(idx)
                if it then
                    local okI, iid = pcall(function() return it:Get("ObjectID") end)
                    if okI and iid == oid then return idx end
                end
            end
        end
        if itemIsMelee(cur) then return 3 end
        return nil
    end
    local function slotUsable(idx)
        local it = slotItemByIndex(idx); if not it then return false end
        if itemIsMelee(it) then return S.RageSwitchMelee == true end
        local a = itemAmmo(it)
        return a == nil or a > 0
    end
    local function nextUsableSlot(excludeIdx)
        local pref = PICK_SLOT[S.RagePreferredSlot] or 1
        local order = { pref }
        for _, s in ipairs({ 1, 2, 3 }) do if s ~= pref and (S.RageSwitchMelee or s ~= 3) then order[#order+1] = s end end
        for _, s in ipairs(order) do
            if s ~= excludeIdx and slotUsable(s) then return s end
        end
        return nil
    end
    local function equipSlot(idx)
        if not idx then return false end
        if whichSlotNow() == idx then return true end
        local now = tick()
        if now - (State.RageSwitchLast or 0) < (S.RageSwitchRateLimit or 0.06) then return false end
        State.RageSwitchLast = now
        local lf = getLocalFighter()
        local equipped = false
        if lf and lf.EquipItem then
            equipped = pcall(function() lf:EquipItem(idx) end)
        end
        if not equipped then
            pcall(function()
                local kc = ({ Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three })[idx]
                if kc then
                    VirtualInputMgr:SendKeyEvent(true, kc, false, game)
                    VirtualInputMgr:SendKeyEvent(false, kc, false, game)
                end
            end)
        end
        return true
    end
    Rage._equipSlot = equipSlot
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
        local mode = S.RageOnEmpty or "Reload"
        local okA, ammo = pcall(function() return it:Get("Ammo") end)
        local empty = not (okA and type(ammo) == "number" and ammo > 0)
        if mode ~= "Swap" or not empty then
            if tick() - (State.RageReloadLast or 0) < 0.5 then return "throttled" end
            State.RageReloadLast = tick()
            local lf = getLocalFighter()
            if lf then
                pcall(function() lf:Input("StartReloading") end)
            end
            pcall(function() it:StartReloading() end)
            return "requested"
        end
        local lf = getLocalFighter()
        local items = lf and lf.Items
        if type(items) ~= "table" then return "no items" end
        if tick() - (State.RageSwitchLast or 0) < 0.5 then return "swap-wait" end
        local pref = PICK_SLOT[S.RagePreferredSlot or "Primary"] or 1
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
    local function findTarget()
        local myChar = LP.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local cands = {}
        for _, p in ipairs(getSafePlayers()) do
            if isValidTarget(p, S.RageVisCheck, true, true) then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local d = 9999
                local sane = myRoot ~= nil and hrp ~= nil and isSanePos(hrp.Position)
                if sane then d = (hrp.Position - myRoot.Position).Magnitude end
                if (not sane) or d <= (S.ESPMaxDistance or 1200) then
                    table.insert(cands, { p = p, hp = hum.Health, d = d })
                end
            end
        end
        if #cands == 0 then return nil end
        if S.RageHPPriority then
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
    local function startTargetLoop()
        if _tgtConn then _tgtConn:Disconnect() end
        local lastPosMap, lastTimeMap = {}, {}
        _tgtConn = RunService.Heartbeat:Connect(function()
            if not S.RageEnabled then return end
            local nowTime = tick()
            for _, p in ipairs(getSafePlayers()) do
                if p ~= LP and p.Character then
                    local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
                    if pRoot then
                        local cp = pRoot.Position
                        if lastPosMap[p] and lastTimeMap[p] then
                            local dt = nowTime - lastTimeMap[p]
                            if dt > 0 then State.RageTrueVelocityMap[p] = (cp - lastPosMap[p]) / dt end
                        end
                        lastPosMap[p] = cp
                        lastTimeMap[p] = nowTime
                    end
                end
            end
            if S.RageFastTargetSwitch and State.RageTarget and not isValidTarget(State.RageTarget, false, true, true) then
                State.RageTarget = nil
            end
        end)
    end
    Rage._startTargetLoop = startTargetLoop
    function Rage.init()
        for _, p in ipairs(getSafePlayers()) do bump(p) end
        Players.PlayerAdded:Connect(function(p)
            bump(p)
            p.CharacterAdded:Connect(function() bump(p) end)
        end)
        for _, p in ipairs(getSafePlayers()) do
            p.CharacterAdded:Connect(function() bump(p) end)
        end
        Players.PlayerRemoving:Connect(function(p) State.RageCharTokens[p] = nil end)
        LP.CharacterAdded:Connect(function()
            bump(LP)
            State.RageRealCF = nil
            State.RageRealChar = nil
            State.RageParkDirty = false
            State.RageTarget = nil
        end)
        bump(LP)
    end
end)()

local PolarCore = {}
;(function()
    local _realCF, _realChar = nil, nil
    local _voidCF = nil
    local _target = nil
    local _firing = false
    local _inMatch = false
    local _deflectSince = 0
    local _shots = 0
    local _voidSteps = 0
    local _shootEnum = nil
    local _useItem = nil
    local _notified = nil
    local _conn, _stepConn, _charConn = nil, nil, nil
    local RENDER_NAME = "v3Hub_Polar_Restore"
    local VOID_R_MIN, VOID_R_MAX = 110000, 140000
    local VOID_MIN_STEP = 25000
    local VOID_MOVE = true
    local DEFLECT_MAX_HOLD = 1.5
    local IMMUNE_MAX_HOLD = 6.0
    local _immuneSince = 0
    local _immuneTgt = nil
    local EYE_MUZZLE_SEP = 0.07
    local EYE_UP_SANE = 2.5
    local KILL_PLANE_BUF = 200
    local RAGE_CLAMP_FRAC = 0.30
    local _preParkCF = nil
    local FFLAGS_ON = { DFIntS2PhysicsSenderRate = "120", DFIntAssemblyHistoryBufferSize = "2147483648", DFIntAssemblyHistorySkipSize = "0" }
    local FFLAGS_OFF = { DFIntS2PhysicsSenderRate = "15", DFIntAssemblyHistoryBufferSize = "15", DFIntAssemblyHistorySkipSize = "8" }
    local _fpdhOriginal = nil
    local _flagsOn = false
    local _physSet, _physLive = false, false
    local _fpdhDead = false
    local _fpdhIdTried = false
    local function fflagApi()
        local set, get, name = nil, nil, "none"
        pcall(function()
            if type(setfflag) == "function" then
                set, name = setfflag, "setfflag"
            end
            if type(getfflag) == "function" then get = getfflag end
        end)
        return set, get, name
    end
    local function writeFPDH(value)
        if _fpdhDead then return false, "refused earlier" end
        if not identityIsSafe() then return false, "identity off" end
        if not _fpdhIdTried then
            _fpdhIdTried = true
            identEnsure()
        end
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
        if on and S.RagePhysicsFlags == false then return end
        _flagsOn = on
        if _fpdhOriginal == nil then
            local prev = W.FallenPartsDestroyHeight
            if prev ~= prev then prev = -500 end
            _fpdhOriginal = prev
        end
        local fpdhOk, fpdhHow
        if on then
            fpdhOk, fpdhHow = writeFPDH(0/0)
        else
            local okBack, howBack = writeFPDH(_fpdhOriginal)
            fpdhHow = "restored=" .. tostring(okBack) .. " " .. tostring(howBack)
        end
        State.RageFPDHPath = fpdhHow
        local set, get, setName = fflagApi()
        if set == nil then
            _physSet, _physLive = false, false
            State.RagePhysRate = "no fflag setter"
            return
        end
        local want = on and FFLAGS_ON or FFLAGS_OFF
        local threw = false
        local keyOk = false
        for name, value in want do
            local wrote = pcall(set, name, value)
            if not wrote then threw = true end
            if name == "DFIntAssemblyHistorySkipSize" and wrote then keyOk = true end
        end
        _physSet = on and not threw
        _physLive = _physSet and keyOk and fpdhOk
        State.RagePhysRate = setName .. " " .. (on and "verified" or "off")
    end
    Rage._setPhysicsFlags = setPhysicsFlags
    local function restoreMode()
        local m = S.RageRestoreMode
        if m == "kerp" then m = "kicia" end
        if m == "auto" then m = "kicia" end
        if m == "kicia" or m == "render" or m == "none" then return m end
        return "none"
    end
    local _rvCF = nil
    local function voidAxis()
        local v = math.random(VOID_R_MIN, VOID_R_MAX)
        if math.random(0,1) == 0 then return -v end
        return v
    end
    local VOID_DEEP_AXIS = 1073741824
    local VOID_DEEP_JITTER = 0.4
    local _voidOrder = { 1, 2, 3 }
    local function deepMag(allowNeg)
        local m = VOID_DEEP_AXIS * (1 + math.random() * VOID_DEEP_JITTER)
        if allowNeg and math.random(0,1) == 1 then return -m end
        return m
    end
    local function rollVoidDeep()
        local x, y, z = math.random(1000,1500), math.random(1000,1500), math.random(1000,1500)
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
        if S.RageVoidDepth ~= "shallow" then return rollVoidDeep() end
        return CFrame.new(voidAxis(), math.random(VOID_R_MIN, VOID_R_MAX), voidAxis())
    end
    local function voidCFrame()
        local prev = _voidCF
        local cf = rollVoid()
        if VOID_MOVE and prev then
            local tries = 0
            while tries < 8 and (cf.Position - prev.Position).Magnitude < VOID_MIN_STEP do
                cf = rollVoid()
                tries = tries + 1
            end
        end
        _voidCF = cf
        _voidSteps = _voidSteps + 1
        return cf
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
    local PRIME_S = 0.07
    local HIDE_JITTER_MAX = 0.25
    local _hiding = false
    local _primeUntil = 0
    local function hide(hrp, status)
        _firing = false
        State.RageFiring = false
        State.RageStatus = status
        State.RageVoidActive = true
        _hiding = true
        _primeUntil = 0
        displace(hrp, voidCFrame())
    end
    local function eyeRise(fromPos, tgtChar)
        local rise = EYE_UP_SANE
        pcall(function()
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            rp.FilterDescendantsInstances = { LP.Character, tgtChar }
            local res = W:Raycast(fromPos, Vector3.new(0, EYE_UP_SANE, 0), rp)
            if res ~= nil then
                local room = (res.Position.Y - fromPos.Y) - 0.25
                if room < rise then rise = math.max(room, 0.15) end
            end
        end)
        return rise
    end
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
            _useItem, _shootEnum = nil, nil
            State.CapabilityRecoveries = (State.CapabilityRecoveries or 0) + 1
        end
        if _shootEnum == nil then
            pcall(function() _shootEnum = EnumLibrary:ToEnum("StartShooting") end)
        end
        if _shootEnum == nil then State.RageFireWhy = "no enum"; return 0 end
        if _useItem == nil then
            pcall(function() _useItem = Replication and Replication.Fighter and Replication.Fighter.UseItem end)
        end
        if _useItem == nil then State.RageFireWhy = "no remote"; return 0 end
        local okId, objId = pcall(function() return it:Get("ObjectID") end)
        if not okId or not objId then State.RageFireWhy = "no objId"; return 0 end
        local base = eyePos - Vector3.new(0, EYE_UP_SANE, 0)
        local rise = eyeRise(base, State.RageTarget and State.RageTarget.Character or nil)
        local fireEyePos = base + Vector3.new(0, rise, 0)
        local eyeCF = Rage._lookCF(fireEyePos, aimPos)
        local muzzleCF = eyeCF - Vector3.new(0, EYE_MUZZLE_SEP, 0)
        local sent = 0
        local rayCast = false
        pcall(function() rayCast = it.Info.IsRaycast == true end)
        local okLoop, loopErr = pcall(function()
            for _ = 1, math.max(1, math.min(S.RageTapsPerFrame or 1, S.RageTaps or 6)) do
                local inner = {}
                Rage._buildShotFields(inner, eyeCF, muzzleCF, hh, aimPos, true, RAGE_CLAMP_FRAC, 1.0)
                local env = { [utf8.char(1)] = inner }
                if rayCast and not S.RagePolarParity then env[utf8.char(2)] = true end
                _useItem:FireServer(objId, _shootEnum, env, nil)
                sent = sent + 1
            end
        end)
        if not okLoop then State.RageFireWhy = "send threw: " .. tostring(loopErr) end
        _shots = _shots + sent
        State.Shots = State.Shots + sent
        return sent
    end
    local function polarTick(ch, hrp)
        local tgt = _target
        if tgt and (not tgt.Parent or not tgt.Character or not isAlive(tgt) or isTeammate(tgt)) then
            tgt = nil
        end
        if not tgt then tgt = Rage._findTarget() end
        _target = tgt
        State.RageTarget = tgt
        if not tgt or not tgt.Character then return hide(hrp, "No target") end
        local holdFire = isSpawnProtected(tgt) and S.RageSkipImmune
        if not holdFire then
            _immuneSince, _immuneTgt = 0, nil
        else
            local now = tick()
            if _immuneTgt ~= tgt then _immuneSince, _immuneTgt = now, tgt end
            if now - _immuneSince > IMMUNE_MAX_HOLD then
                holdFire = false
                State.RageImmuneOverride = (State.RageImmuneOverride or 0) + 1
            end
        end
        if S.SilentAvoidDeflect and isDeflecting(tgt) then
            local now = tick()
            if _deflectSince == 0 then _deflectSince = now end
            if now - _deflectSince < DEFLECT_MAX_HOLD then return hide(hrp, "Deflecting") end
        else
            _deflectSince = 0
        end
        local it = getEquippedItem()
        if not Rage._weaponReady(it) then
            local act = Rage._weaponRecovery(it)
            if act == "swap" or act == "swap-wait" then return hide(hrp, "Swapping") end
            return hide(hrp, "Reloading")
        end
        local hh = tgt.Character:FindFirstChild("HitboxHead") or tgt.Character:FindFirstChild("Head")
        if not hh then return hide(hrp, "Hiding") end
        if _hiding then
            _hiding = false
            local extra = 0
            if S.RageHideJitter ~= false then extra = math.random() * HIDE_JITTER_MAX end
            _primeUntil = tick() + PRIME_S + extra
        end
        local hpos = hh.Position
        if not isSanePos(hpos) then return hide(hrp, "Head voided") end
        if holdFire then
            _firing = false
            State.RageFiring = false
            State.RageVoidActive = true
            State.RageWhyProtected = (State.RageWhyProtected or 0) + 1
            State.RageStatus = "Protected"
            displace(hrp, voidCFrame())
            return
        end
        if S.RagePolarParity ~= false and tick() < _primeUntil then
            _firing = false
            State.RageFiring = false
            State.RageVoidActive = true
            State.RageWhyPrimeWait = (State.RageWhyPrimeWait or 0) + 1
            State.RageStatus = "Priming"
            displace(hrp, voidCFrame())
            return
        end
        State.RageFiring = true
        State.RageVoidActive = false
        _firing = true
        State.RageStatus = "Attacking"
        local eyePos = C.CFrame.Position
        local sent = polarFire(eyePos, hpos, hh)
        if sent == 0 then
            State.RageFireZeroFrames = (State.RageFireZeroFrames or 0) + 1
            State.RageStatus = "PARKED, SENT NOTHING: " .. tostring(State.RageFireWhy)
        else
            State.RageFireFrames = (State.RageFireFrames or 0) + 1
        end
        if _notified ~= tgt then
            _notified = tgt
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
        end)
    end
    Players.PlayerRemoving:Connect(function(p)
        State.RageTrueVelocityMap[p] = nil
    end)
    function PolarCore.start()
        if _conn then return end
        _firing = false
        setPhysicsFlags(true)
        _notified = nil
        pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
        RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.First.Value - 1000, function()
            if _firing and restoreMode() == "none" then return end
            restoreHome(false)
        end)
        _stepConn = RunService.Stepped:Connect(function()
            if _firing then
                local pol = restoreMode()
                if pol == "render" then return restoreHome(false) end
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
            if not S.RageEnabled or (S.RageMode or "Polar") ~= "Polar" then
                PolarCore.stop()
                return
            end
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
                _target = nil
                _firing = false
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
    function PolarCore.stop()
        setPhysicsFlags(false)
        if _conn then _conn:Disconnect(); _conn = nil end
        if _stepConn then _stepConn:Disconnect(); _stepConn = nil end
        if _charConn then _charConn:Disconnect(); _charConn = nil end
        pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
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
    function Rage.enable()
        S.RageEnabled = true
        Rage._startTargetLoop()
        PolarCore.start()
    end
    function Rage.disable()
        S.RageEnabled = false
        PolarCore.stop()
        State.RageFiring = false
        State.RageVoidActive = false
        State.RageStatus = "Idle"
    end
    function Rage.unload()
        Rage.disable()
        if shared._LH_velConn then
            pcall(function() shared._LH_velConn:Disconnect() end)
            shared._LH_velConn = nil
        end
    end
end)()

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
    local _fovC, _lockC, _dbgT = nil, nil, nil
    local _tgt, _part = nil, nil
    local _prevTgt = nil
    local _notified = nil
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
    local _lty, _ltp = 0, 0
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
    local function fovPixels(deg)
        local vp = C.ViewportSize
        local lim = math.max(vp.X, vp.Y)
        if deg >= 89 then return lim end
        local half = math.tan(math.rad(C.FieldOfView) * 0.5)
        if half <= 0 then return lim end
        return math.clamp(math.tan(deg * D2R) / half * (vp.Y * 0.5), 4, lim)
    end
    local function minJerk(s)
        s = math.clamp(s, 0, 1)
        return s * s * s * (10 + s * (-15 + 6 * s))
    end
    local function bezier(p0, p1, p2, p3, t)
        local it = 1 - t
        return it*it*it*p0 + 3*it*it*t*p1 + 3*it*t*t*p2 + t*t*t*p3
    end
    local function validFor(pl)
        if not isValidTarget(pl, false) then return false end
        if S.AimSkipImmune and isSpawnProtected(pl) then return false end
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
        return firstVisible(char, {"HitboxHead","HitboxHeadSmall","Head"}, primary)
            or firstVisible(char, {"HitboxBody","UpperTorso","HumanoidRootPart","LowerTorso"}, primary)
            or primary
    end
    local function acquire(cf, fovR, retainR, cur)
        local mode = S.AimTargetPart or "Best"
        local pick = (mode == "Best") and "Head" or mode
        local prio = S.AimPriority or "Crosshair"
        local vis = S.AimVisCheck
        local myRoot = nil
        if prio == "Distance" then
            local mc = LP.Character
            myRoot = mc and mc:FindFirstChild("HumanoidRootPart")
        end
        local bP, bPart, bAng, bScore = nil, nil, math.huge, math.huge
        local cPart, cAng, cOK = nil, math.huge, false
        for _, pl in ipairs(getSafePlayers()) do
            if pl ~= LP and validFor(pl) then
                local char = pl.Character
                local part = pickPart(char, pick)
                if part then
                    local ang = angTo(cf, part.Position)
                    local isCur = (pl == cur)
                    if ang <= (isCur and retainR or fovR) then
                        local hasVis = (not vis) or isVisible(part.Position)
                        if hasVis then
                            local score = ang
                            if prio == "Health" then
                                local hp = getHealth(pl)
                                score = hp * 100 + ang
                            elseif prio == "Distance" and myRoot then
                                score = (part.Position - myRoot.Position).Magnitude * 100 + ang
                            end
                            if isCur then
                                cPart, cAng, cOK = part, ang, true
                                score = score * (1 - (S.AimStickiness or 0))
                            end
                            if score < bScore then bScore, bP, bPart, bAng = score, pl, part, ang end
                        end
                    end
                end
            end
        end
        if prio == "Crosshair" and cOK and bP and bP ~= cur then
            if bAng > cAng - (S.AimSwitchDeg or 0) * D2R then
                return cur, cPart, cAng
            end
        end
        return bP, bPart, bAng
    end
    local function ensureDraw()
        pcall(function()
            if not _fovC then
                _fovC = Drawing.new("Circle")
                if _fovC then
                    _fovC.Thickness = 1; _fovC.NumSides = 64
                    _fovC.Color = Color3.fromRGB(180, 180, 180)
                    _fovC.Transparency = 0.6; _fovC.Filled = false; _fovC.Visible = false
                end
            end
            if not _lockC then
                _lockC = Drawing.new("Circle")
                if _lockC then
                    _lockC.Thickness = 2; _lockC.NumSides = 32
                    _lockC.Color = Color3.fromRGB(255, 80, 100)
                    _lockC.Transparency = 0.9; _lockC.Filled = false; _lockC.Radius = 6; _lockC.Visible = false
                end
            end
        end)
    end
    local function updateDraw()
        local wantFov = S.AimEnabled and S.AimShowFOV
        local wantLock = S.AimEnabled and S.AimShowLock and _part
        if not (wantFov or wantLock) then
            if _fovC and _fovC.Visible then _fovC.Visible = false end
            if _lockC and _lockC.Visible then _lockC.Visible = false end
            return
        end
        ensureDraw()
        if _fovC then
            if wantFov then
                local vp = C.ViewportSize
                _fovC.Position = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
                _fovC.Radius = fovPixels(S.AimFOVDeg or 20)
                _fovC.Visible = true
            else _fovC.Visible = false end
        end
        if _lockC then
            local on = false
            if wantLock then
                local sp, vis = C:WorldToViewportPoint(_part.Position)
                if vis and sp.Z > 0 then
                    _lockC.Position = Vector2.new(sp.X, sp.Y); on = true
                end
            end
            _lockC.Visible = on
        end
    end
    local function resolvePath()
        local touchOnly = UIS.TouchEnabled and not UIS.MouseEnabled
        if _mouseMove and not touchOnly then return "mouse" end
        if S.AimDirectCamera or touchOnly then
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
    local function getSpringOffset()
        if not S.AimCancelSprings then return 0, 0 end
        if _ctl then
            local s = rawget(_ctl, "_aim_spring") or rawget(_ctl, "_camera_rotation_spring")
            if s and typeof(s.Position) == "Vector2" then return s.Position.Y, s.Position.X
            elseif s and typeof(s.Position) == "Vector3" then return s.Position.X, s.Position.Y end
        end
        return 0, 0
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
        _notified = nil
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
        dt = math.clamp(dt or (1/60), 1/1000, 0.1)
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
        updateDraw()
        if not S.AimEnabled then
            State.AimbotKeyHeld = false
            clearTarget()
            return
        end
        if State.RageFiring then clearTarget(); return end
        if not inMatch() then
            State.AimbotKeyHeld = false
            clearTarget()
            return
        end
        local keyDown = false
        local kc = S.AimKey
        if kc == "Always" then keyDown = true
        elseif kc == "MB1" then keyDown = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        elseif kc == "MB2" then keyDown = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        elseif kc and Enum.KeyCode[kc] then keyDown = UIS:IsKeyDown(Enum.KeyCode[kc]) end
        State.AimbotKeyHeld = keyDown
        if not keyDown then clearTarget(); return end
        _path = resolvePath()
        if _path == "none" then clearTarget(); return end
        local fovR = math.clamp(S.AimFOVDeg or 20, 0.1, 180) * D2R
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
            local forget = S.AimForgetTime or 0.2
            if _tgt and (now - _lastSeenAt) <= forget then
                tgt, part = _tgt, _part
            else
                clearTarget()
                return
            end
        end
        if (S.AimTargetPart or "Best") == "Best" then
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
        if S.AimPrediction then
            local lead = calculateLead(targetChar, cf.Position, true)
            targetPos = targetPos + lead
        end
        local d = targetPos - cf.Position
        local dDist = d.Magnitude
        if dDist < 1e-3 then return end
        local u = d / dDist
        local tYaw = yawOf(u)
        local tPit = math.clamp(pitchOf(u), -PITCH_LIMIT, PITCH_LIMIT)
        local errYaw = wrapPi(tYaw - curYaw)
        local errPit = tPit - curPit
        _errDeg = math.sqrt(errYaw*errYaw + errPit*errPit) * R2D
        local dH2 = d.X*d.X + d.Z*d.Z
        if _haveTgt and part == _lastPartRef and dH2 > 1e-4 then
            local vDotU = vRel:Dot(u)
            local dH = math.sqrt(dH2)
            local rawFFY = (d.Z*vRel.X - d.X*vRel.Z) / dH2
            local rawFFP = (vRel.Y - vDotU * u.Y) / dH
            local k = math.clamp(dt / FF_TAU, 0, 1)
            _ffy = _ffy + (math.clamp(rawFFY, -FF_MAX, FF_MAX) - _ffy) * k
            _ffp = _ffp + (math.clamp(rawFFP, -FF_MAX, FF_MAX) - _ffp) * k
        else
            _ffy, _ffp = 0, 0
        end
        _lty, _ltp, _haveTgt, _lastPartRef = tYaw, tPit, true, part
        if (S.AimReactionMs or 0) > 0 and (now - _acquireAt)*1000 < S.AimReactionMs then return end
        if (S.AimDeadzoneDeg or 0) > 0 then
            local m = math.sqrt(errYaw*errYaw + errPit*errPit)
            if m < S.AimDeadzoneDeg * D2R then return end
        end
        local smoothX = S.AimLinkAxes and (S.AimSmoothness or 0) or (S.AimSmoothnessX or S.AimSmoothness or 0)
        local smoothY = S.AimLinkAxes and (S.AimSmoothness or 0) or (S.AimSmoothnessY or S.AimSmoothness or 0)
        smoothX = math.clamp(smoothX, 0, 100)
        smoothY = math.clamp(smoothY, 0, 100)
        local isHardLock = (smoothX == 0 and smoothY == 0)
        local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
        local isAirborne = (targetHum and targetHum.FloorMaterial == Enum.Material.Air) or math.abs(targetVel.Y) > 5
        if isAirborne and (S.AimJumpDamping or 0) > 0 and smoothY > 0 then
            local jDamp = (S.AimJumpDamping / 100)
            local vyFrac = math.clamp(math.abs(targetVel.Y) / 60, 0, 1)
            smoothY = math.clamp(smoothY + (100 - smoothY) * vyFrac * jDamp, 0, 100)
        end
        local aErr = math.sqrt(errYaw*errYaw + errPit*errPit)
        _errEma = _errEma + (aErr - _errEma) * math.clamp(dt/0.15, 0, 1)
        _drive = _drive + dt
        local sPos = (errYaw >= 0)
        if _lastSign ~= nil and sPos ~= _lastSign then _flips = _flips + 1 end
        _lastSign = sPos
        _flips = _flips * math.exp(-dt/0.25)
        if _flips >= 4 and _errEma > OSC_ERR and not isHardLock then
            _auth = math.max(0.15, _auth * 0.5)
            _flips = 0
        else
            _auth = math.min(1, _auth + dt*0.3)
        end
        local avgSmooth = (smoothX + smoothY) * 0.5
        if _errEma > RUNAWAY_ERR and _drive > (0.15 + (avgSmooth/100)*MAX_TAU*3) and not isHardLock then
            _auth = math.max(0.08, _auth * 0.5)
            _gx, _gy = _sdx, _sdy
            _nx, _ny = 0, 0
            _drive = 0
            _trips = _trips + 1
            if _trips >= 2 then _calOff = true end
        end
        local alphaX = 1
        if smoothX > 0 then alphaX = (1 - math.exp(-dt / ((smoothX/100)*MAX_TAU))) * _auth end
        local alphaY = 1
        if smoothY > 0 then alphaY = (1 - math.exp(-dt / ((smoothY/100)*MAX_TAU))) * _auth end
        local cy = errYaw * alphaX
        local cp = errPit * alphaY
        if S.AimCurvedFlick and _errDeg > 3.0 and not isHardLock then
            if not _flickActive then
                _flickActive = true
                _flickT = 0
                _flickDur = math.clamp((_errDeg/90)*0.22 + 0.08, 0.08, 0.35)
                local intensity = (S.AimCurvedIntensity or 0.35) * (_errDeg * D2R)
                local normY, normP = -errPit/(aErr+1e-4), errYaw/(aErr+1e-4)
                local curveSign = ((math.floor(now*10) % 2 == 0) and 1 or -1)
                _flickCtrl1Y = normY * intensity * curveSign
                _flickCtrl1P = normP * intensity * curveSign
                _flickCtrl2Y = normY * (intensity*0.7) * curveSign
                _flickCtrl2P = normP * (intensity*0.7) * curveSign
            end
            _flickT = math.min(_flickDur, _flickT + dt)
            local prog = _flickT / _flickDur
            local sJerk = minJerk(prog)
            local p1Y = errYaw*0.33 + _flickCtrl1Y
            local p1P = errPit*0.33 + _flickCtrl1P
            local p2Y = errYaw*0.66 + _flickCtrl2Y
            local p2P = errPit*0.66 + _flickCtrl2P
            cy = bezier(0, p1Y, p2Y, errYaw, sJerk) * alphaX
            cp = bezier(0, p1P, p2P, errPit, sJerk) * alphaY
            if prog >= 1.0 or _errDeg < 1.0 then _flickActive = false end
        else
            _flickActive = false
        end
        State.AimbotFlickActive = _flickActive
        if not isHardLock then
            local spPit, spYaw = getSpringOffset()
            cy = cy - (spYaw * alphaX)
            cp = cp - (spPit * alphaY)
        end
        local os = S.AimOvershoot or 0
        if os > 0 and not isHardLock then
            _ramp = math.min(1, _ramp + dt/RAMP_TIME)
            local k = 1 + math.sin(_ramp*math.pi)*os
            cy, cp = cy*k, cp*k
        end
        local ff = (S.AimTrackAssist or 100)/100
        if ff > 0 and not isHardLock then
            cy = cy + _ffy*dt*ff
            cp = cp + _ffp*dt*ff
        end
        local nz = S.AimNoiseDeg or 0
        if nz > 0 then
            local n = nz * D2R * dt
            cy = cy + (math.random()-0.5)*2*n
            cp = cp + (math.random()-0.5)*2*n
        end
        local cap = S.AimMaxSpeed or 0
        if cap > 0 then
            local m = math.sqrt(cy*cy + cp*cp)
            local lim = cap * D2R * dt
            if m > lim then local k = lim/m; cy, cp = cy*k, cp*k end
        end
        cp = math.clamp(curPit + cp, -PITCH_LIMIT, PITCH_LIMIT) - curPit
        if _gx == 0 or _gy == 0 then return end
        local ux, uy = cy/_gx, cp/_gy
        local um = math.max(math.abs(ux), math.abs(uy))
        if um > UNIT_MAX then local k = UNIT_MAX/um; ux, uy = ux*k, uy*k end
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
        S.AimEnabled = true
        if _bound then return end
        RunService:BindToRenderStep("v3Hub_Aimbot", Enum.RenderPriority.Camera.Value + 1, function(dt)
            pcall(step, dt)
        end)
        _bound = true
    end
    function Aimbot.disable()
        S.AimEnabled = false
        State.AimbotKeyHeld = false
        clearTarget()
        _sx, _sy, _fx, _fy = 0, 0, 0, 0
        _haveCam, _ramp, _notified = false, 0, nil
        _auth = 1.0
        if _bound then
            pcall(function() RunService:UnbindFromRenderStep("v3Hub_Aimbot") end)
            _bound = false
        end
        if _fovC then _fovC.Visible = false end
        if _lockC then _lockC.Visible = false end
    end
    function Aimbot.unload()
        Aimbot.disable()
        if _fovC then pcall(function() _fovC:Remove() end); _fovC = nil end
        if _lockC then pcall(function() _lockC:Remove() end); _lockC = nil end
    end
    function Aimbot.hasMouseMove() return _mouseMove ~= nil end
end)()

print("[v11.0] 第二段載入完成")local silentLastFire = 0
local silentFireCD = 0.01
local raySilent = RaycastParams.new()
raySilent.FilterType = Enum.RaycastFilterType.Blacklist

local function silentFOVCenter()
    if S.SilentFollowMuzzle then
        local vm = W:FindFirstChild("ViewModels")
        local fp = vm and vm:FindFirstChild("FirstPerson")
        if fp then
            for _, model in pairs(fp:GetChildren()) do
                if model:IsA("Model") and model.Name:find("^" .. LP.Name) then
                    local iv = model:FindFirstChild("ItemVisual")
                    local b = iv and iv:FindFirstChild("Body")
                    local bp = b and b:FindFirstChild("BodyPrimary")
                    local mz = bp and bp:FindFirstChild("_muzzle")
                    if mz and mz:IsA("Attachment") then
                        local sp, on = worldToScreen(mz.WorldPosition)
                        if on then return sp end
                    end
                end
            end
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
        for _, p in ipairs(getSafePlayers()) do
            if isValidTarget(p, false) then
                local part = getHitPartName(p.Character, S.SilentHitPart)
                if part then
                    local d = (part.Position - myRoot.Position).Magnitude
                    if d < bestD then best, bestD = p, d end
                end
            end
        end
        return best
    end
    local tgt, part = selectTarget({
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
    local lf = getLocalFighter()
    if not lf or not lf.EquippedItem then return false end
    local part = getHitPartName(target.Character, S.SilentHitPart)
    if not part then return false end
    local myChar = LP.Character
    local root = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local objId = lf.EquippedItem:Get("ObjectID")
    if not objId then return false end
    local camData = {}
    if not Rage._encodeShot(camData, part, target.Character, root.Position) then return false end
    local env = { [utf8.char(1)] = camData }
    pcall(function()
        UseItem:FireServer(objId, EnumLibrary:ToEnum("StartShooting"), env, nil)
    end)
    State.SilentLastTarget = target
    State.Shots = State.Shots + 1
    State.Hits = State.Hits + 1
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

local antiAimState = { frameCounter = 0, smoothYaw = 0, smoothPitch = 0 }
local function getRandomInRange(mn, mx) return mn + math.random() * (mx - mn) end
local function calcAntiAimYaw()
    local yaw = 0
    local currentTime = tick()
    if S.AntiAimYaw == "jitter" then
        local minA = math.rad(S.AntiAimMinAngle)
        local maxA = math.rad(S.AntiAimMaxAngle)
        if S.AntiAimRandomAngle then yaw = getRandomInRange(-maxA, maxA)
        else yaw = math.random() > 0.5 and minA or -minA end
    elseif S.AntiAimYaw == "spinbot" then
        local speed = getRandomInRange(S.AntiAimMinSpeed/10, S.AntiAimMaxSpeed/10)
        yaw = (currentTime * speed) % (2 * math.pi)
    elseif S.AntiAimYaw == "random" then
        if antiAimState.frameCounter % 30 == 0 then
            yaw = getRandomInRange(-math.rad(S.AntiAimMaxAngle), math.rad(S.AntiAimMaxAngle))
        else yaw = antiAimState.smoothYaw end
        antiAimState.smoothYaw = yaw
    end
    return yaw
end
local function calcAntiAimPitch()
    local pitch = 0
    if S.AntiAimPitch == "jitter" then
        local minA = math.rad(S.AntiAimMinAngle)
        local maxA = math.rad(S.AntiAimMaxAngle)
        if S.AntiAimRandomAngle then pitch = getRandomInRange(-maxA, maxA)
        else pitch = math.random() > 0.5 and minA or -minA end
    elseif S.AntiAimPitch == "spinbot" then
        pitch = math.sin(tick() * (S.AntiAimMaxSpeed/10)) * math.rad(S.AntiAimMaxAngle)
    elseif S.AntiAimPitch == "random" then
        if antiAimState.frameCounter % 20 == 0 then
            pitch = getRandomInRange(math.rad(-89), math.rad(89))
        else pitch = antiAimState.smoothPitch end
        antiAimState.smoothPitch = pitch
    end
    return pitch
end
local function calcAntiAimRoll()
    local roll = 0
    if S.AntiAimAngle == "tilt 45" then roll = math.rad(45)
    elseif S.AntiAimAngle == "tilt 90" then roll = math.rad(90)
    elseif S.AntiAimAngle == "upside down" then roll = math.rad(180)
    elseif S.AntiAimAngle == "custom" then roll = math.rad(S.AntiAimCustomAngle) end
    return roll
end

local antiAimConn = RunService.Heartbeat:Connect(function()
    if not S.AntiAimEnabled then return end
    local character = LP.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    antiAimState.frameCounter = antiAimState.frameCounter + 1
    local yaw = calcAntiAimYaw()
    local pitch = calcAntiAimPitch()
    local roll = calcAntiAimRoll()
    pcall(function()
        root.CFrame = root.CFrame * CFrame.Angles(pitch, yaw, roll)
    end)
end)

local espGui = Instance.new("ScreenGui")
espGui.Name = "v3HubESP_" .. tostring(math.random(1, 999999))
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
    nameLbl.TextColor3 = S.ESPNameColor
    nameLbl.TextSize = S.ESPTextSize
    nameLbl.Font = Enum.Font.Code
    nameLbl.TextStrokeTransparency = 0
    nameLbl.Text = ""
    nameLbl.Size = UDim2.fromOffset(220, 18)
    nameLbl.Position = UDim2.new(0.5, -110, 0, -22)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Center
    nameLbl.Parent = holder

    local distLbl = Instance.new("TextLabel")
    distLbl.BackgroundTransparency = 1
    distLbl.TextColor3 = S.ESPDistanceColor
    distLbl.TextSize = S.ESPInfoTextSize
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
    stroke.Color = S.ESPBoxColor
    stroke.Thickness = S.ESPBoxThickness
    stroke.Parent = box

    local corners = {}
    for i = 1, 4 do
        local c = Instance.new("Frame")
        c.Size = UDim2.fromOffset(10, 2)
        c.BackgroundColor3 = S.ESPBoxColor
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
    hbBar.BackgroundColor3 = S.ESPHealthColor
    hbBar.BorderSizePixel = 0
    hbBar.Size = UDim2.new(1, 0, 1, 0)
    hbBar.Parent = hbBg

    local tracer = Instance.new("Frame")
    tracer.BackgroundColor3 = S.ESPTracerColor
    tracer.BorderSizePixel = 0
    tracer.Visible = false
    tracer.ZIndex = 0
    tracer.Parent = espGui

    local skelLines = {}
    for i = 1, #SKEL_BONES do
        local line = Instance.new("Frame")
        line.BackgroundColor3 = S.ESPSkeletonColor
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
    line.Size = UDim2.fromOffset(math.floor(len), S.ESPSkeletonThickness)
    line.Position = UDim2.fromOffset(math.floor(mid.X - len/2), math.floor(mid.Y))
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
    local alive = {}
    local count = 0
    for _, p in ipairs(getSafePlayers()) do
        if p ~= LP and p.Character then
            local char = p.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            if hum and hum.Health > 0 and root and head then
                local isTeam = S.TeamCheck and isTeammate(p)
                if not isTeam then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    if dist <= S.ESPMaxDistance then
                        if S.ESPMaxPlayers > 0 and count >= S.ESPMaxPlayers then
                            hdESP(espCache[p])
                        else
                            count = count + 1
                            alive[p] = true
                            local d = espCache[p] or buildESP(p)
                            local rpV, rpOn = worldToScreen(root.Position)
                            local hpV, hpOn = worldToScreen(head.Position)
                            if rpOn and hpOn then
                                local hPx = math.abs(rpV.Y - hpV.Y) * 2.2
                                if hPx < 15 then hPx = 15 end
                                local wPx = hPx * 0.5 * S.ESPBoxScale
                                local cx = (rpV.X + hpV.X) / 2
                                local cy = (rpV.Y + hpV.Y) / 2

                                d.holder.Position = UDim2.fromOffset(math.floor(cx - wPx/2), math.floor(cy - hPx/2))
                                d.holder.Size = UDim2.fromOffset(math.floor(wPx), math.floor(hPx))
                                d.holder.Visible = true

                                d.name.Visible = S.ESPShowName
                                if S.ESPShowName then d.name.Text = p.Name end
                                d.dist.Visible = S.ESPShowDistance
                                if S.ESPShowDistance then d.dist.Text = string.format("[%d]", math.floor(dist)) end

                                d.box.Visible = true
                                d.box.Position = UDim2.fromOffset(math.floor(cx - wPx/2), math.floor(cy - hPx/2))
                                d.box.Size = UDim2.fromOffset(math.floor(wPx), math.floor(hPx))
                                d.stroke.Color = S.ESPBoxColor
                                for _, c in ipairs(d.corners) do c.BackgroundColor3 = S.ESPBoxColor end

                                if S.ESPShowHealth and hum.MaxHealth > 0 then
                                    local rt = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                                    d.hbBg.Visible = true
                                    d.hbBg.Size = UDim2.fromOffset(3, math.floor(hPx))
                                    d.hbBg.Position = UDim2.new(0, -6, 0, 0)
                                    d.hbBar.Size = UDim2.new(1, 0, rt, 0)
                                    d.hbBar.Position = UDim2.new(0, 0, 1 - rt, 0)
                                    d.hbBar.BackgroundColor3 = hpRamp(rt)
                                else
                                    d.hbBg.Visible = false
                                end

                                if S.ESPShowTracer then
                                    local vp = C.ViewportSize
                                    local from = Vector2.new(vp.X/2, vp.Y)
                                    local to = Vector2.new(cx, cy + hPx/2)
                                    local mid = (from + to) / 2
                                    local len = (to - from).Magnitude
                                    local ang = math.deg(math.atan2(to.Y - from.Y, to.X - from.X))
                                    d.tracer.Visible = true
                                    d.tracer.BackgroundColor3 = S.ESPTracerColor
                                    d.tracer.Size = UDim2.fromOffset(math.floor(len), S.ESPTracerThickness)
                                    d.tracer.Position = UDim2.fromOffset(math.floor(mid.X - len/2), math.floor(mid.Y))
                                    d.tracer.Rotation = ang
                                else
                                    d.tracer.Visible = false
                                end

                                if S.ESPShowSkeleton then
                                    for i, pair in ipairs(SKEL_BONES) do
                                        local a = char:FindFirstChild(pair[1])
                                        local b = char:FindFirstChild(pair[2])
                                        local ln = d.skel[i]
                                        if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
                                            drawSkelLine(ln, a.Position, b.Position, S.ESPSkeletonColor)
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
                        end
                    else
                        if espCache[p] then hdESP(espCache[p]) end
                    end
                else
                    if espCache[p] then hdESP(espCache[p]) end
                end
            else
                if espCache[p] then hdESP(espCache[p]) end
            end
        end
    end
    for k, d in pairs(espCache) do
        if not alive[k] then clESP(k) end
    end
end

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
        local vm = W:FindFirstChild("ViewModels")
        local fp = vm and vm:FindFirstChild("FirstPerson")
        if fp then
            for _, model in pairs(fp:GetChildren()) do
                if model:IsA("Model") and model.Name:find("^" .. LP.Name) then
                    local iv = model:FindFirstChild("ItemVisual")
                    local b = iv and iv:FindFirstChild("Body")
                    local bp = b and b:FindFirstChild("BodyPrimary")
                    local mz = bp and bp:FindFirstChild("_muzzle")
                    if mz and mz:IsA("Attachment") then
                        local sp, on = worldToScreen(mz.WorldPosition)
                        if on then pos = sp end
                    end
                end
            end
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
                flyBP.D = 1000; flyBP.P = 10000
                flyBP.Position = hrp.Position
                flyBP.Parent = hrp
            end
            if not flyBG then
                flyBG = Instance.new("BodyGyro")
                flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
                flyBG.D = 400; flyBG.P = 10000
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
end
if GameplayUtility and GameplayUtility.GetSpread then
    local origSpread = GameplayUtility.GetSpread
    GameplayUtility.GetSpread = function(self, aimMultiplier, isAiming, isCrouching, pelletIndex, totalPellets, consistent)
        if S.NoSpread or S.MaxAccuracy then return CFrame.new() end
        return origSpread(self, aimMultiplier, isAiming, isCrouching, pelletIndex, totalPellets, consistent)
    end
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
    if S.NoMuzzleFlash then
        noMuzzleFlash()
        if not muzzleFlashConn then
            muzzleFlashConn = RunService.RenderStepped:Connect(noMuzzleFlash)
        end
    else
        if muzzleFlashConn then muzzleFlashConn:Disconnect(); muzzleFlashConn = nil end
    end
end

local DEVICE_CODES = {
    ["Mobile"]="Touch",["Console"]="Gamepad",["VR"]="VR",["PC"]="MouseKeyboard",
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

RunService.RenderStepped:Connect(function(dt)
    tGlobal = tGlobal + dt
    if not C then C = W.CurrentCamera end
    if not C then return end
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

local autoQueueThread = nil
local function autoQueueStop()
    if autoQueueThread then autoQueueThread = nil end
end
local function autoQueueStart()
    autoQueueStop()
    autoQueueThread = task.spawn(function()
        task.wait(S.AutoQueueDelay)
        while S.AutoQueueEnabled and task.wait(1) do
            local success, result = pcall(function()
                local storage = game:GetService("ReplicatedStorage")
                local remotes = storage:WaitForChild("Remotes")
                local matchmaking = remotes:WaitForChild("Matchmaking")
                local joinqueue = matchmaking:WaitForChild("JoinQueue")
                if S.AutoQueueRanked then
                    return joinqueue:InvokeServer(S.AutoQueueMode, true)
                else
                    return joinqueue:InvokeServer(S.AutoQueueMode)
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
        if S.AutoQueueEnabled and not autoQueueThread then
            autoQueueStart()
        elseif not S.AutoQueueEnabled and autoQueueThread then
            autoQueueStop()
        end
    end
end)

local ObsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local ok = pcall(function()
    loadstring(game:HttpGet(ObsidianRepo .. "Library.lua"))()
end)
if not ok then
    warn("[v11.0] Obsidian 載入失敗")
    return
end
local Library = getgenv().Library or getgenv().ObsidianLibrary
if not Library then return end

ThemeManager = loadstring(game:HttpGet(ObsidianRepo .. "addons/ThemeManager.lua"))()
SaveManager = loadstring(game:HttpGet(ObsidianRepo .. "addons/SaveManager.lua"))()

getgenv().ThemeManager = ThemeManager
getgenv().SaveManager = SaveManager
_G.ThemeManager = ThemeManager
_G.SaveManager = SaveManager

pcall(function()
    if ThemeManager then
        ThemeManager:SetLibrary(Library)
        ThemeManager:SetDefaultTheme({
            FontColor = "ffffff", MainColor = "232330", AccentColor = "426e87",
            BackgroundColor = "1d1b26", OutlineColor = "27232f", FontFace = "Code", BackgroundImage = ""
        })
    end
end)

if SaveManager then
    pcall(function() SaveManager:SetLibrary(Library) end)
    pcall(function()
        if SaveManager.SetIgnoreIndexes then SaveManager:SetIgnoreIndexes({ "MenuKeybind" }) end
    end)
    pcall(function() SaveManager:SetFolder("v3hub/rivals") end)
end

local Window = Library:CreateWindow({
    Title = "v3 Hub // RIVALS v11.0",
    Footer = "Polar Rage + Aimbot Complete",
    Center = true, AutoShow = true, NotifySide = "Right", ShowCustomCursor = false
})

local CombatTab = Window:AddTab("Combat", "swords")
local VisualsTab = Window:AddTab("Visuals", "eye")
local MovementTab = Window:AddTab("Movement", "person-standing")
local GunTab = Window:AddTab("Gun", "crosshair")
local MiscTab = Window:AddTab("Misc", "circle-ellipsis")
local AutoTab = Window:AddTab("Auto", "zap")
local ConfigTab = Window:AddTab("Configs", "save")

local silentGroup = CombatTab:AddLeftGroupbox("Silent Aim")
silentGroup:AddToggle("Silent_Enabled", {
    Text = "Enable Silent Aim", Default = false,
    Callback = function(v) S.SilentEnabled = v end
}):AddKeyPicker("Silent_Key", {
    Text = "Silent Aim", Default = "None", Mode = "Toggle", NoUI = true,
    SyncToggleState = true, Callback = function(state) S.SilentEnabled = state end
})
silentGroup:AddToggle("Silent_AutoShoot", { Text = "Auto Shoot", Default = false, Callback = function(v) S.SilentAutoShoot = v end })
silentGroup:AddToggle("Silent_WallCheck", { Text = "Wall Check", Default = true, Callback = function(v) S.SilentWallCheck = v end })
silentGroup:AddToggle("Silent_360", { Text = "360 Mode", Default = false, Callback = function(v) S.Silent360 = v end })
silentGroup:AddDropdown("Silent_HitPart", {
    Text = "Hit Part", Default = "Head",
    Values = {"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso"},
    Callback = function(v) S.SilentHitPart = v end
})
silentGroup:AddSlider("Silent_FOV", { Text = "FOV Radius", Default = 150, Min = 10, Max = 800, Rounding = 0, Compact = true, Callback = function(v) S.SilentFOV = v end })
silentGroup:AddSlider("Silent_HitChance", { Text = "Hit Chance %", Default = 100, Min = 0, Max = 100, Rounding = 0, Compact = true, Callback = function(v) S.SilentHitChance = v end })
silentGroup:AddToggle("Silent_FollowMuzzle", { Text = "Follow Muzzle", Default = false, Callback = function(v) S.SilentFollowMuzzle = v end })

local aimGroup = CombatTab:AddLeftGroupbox("Aimbot (Complete)")
aimGroup:AddToggle("Aim_Enabled", { Text = "Enable Aimbot", Default = false, Callback = function(v)
    if v then Aimbot.enable() else Aimbot.disable() end
end }):AddKeyPicker("Aim_Key", { Text = "Aimbot", Default = "MB2", Mode = "Toggle", NoUI = true, SyncToggleState = true, Callback = function(state) S.AimKey = state and "MB2" or "None" end })
aimGroup:AddDropdown("Aim_KeyDropdown", { Text = "Activation", Default = "MB2", Values = {"Always","MB1","MB2","Q","E","F","C","V","X"}, Callback = function(v) S.AimKey = v end })
aimGroup:AddSlider("Aim_Smoothness", { Text = "Smoothness (0 = hard lock)", Default = 0, Min = 0, Max = 100, Rounding = 0, Compact = true, Callback = function(v) S.AimSmoothness = v end })
aimGroup:AddToggle("Aim_LinkAxes", { Text = "Link X/Y smoothing", Default = true, Callback = function(v) S.AimLinkAxes = v end })
aimGroup:AddSlider("Aim_SmoothnessX", { Text = "Yaw smoothness", Default = 0, Min = 0, Max = 100, Rounding = 0, Compact = true, Callback = function(v) S.AimSmoothnessX = v end })
aimGroup:AddSlider("Aim_SmoothnessY", { Text = "Pitch smoothness", Default = 0, Min = 0, Max = 100, Rounding = 0, Compact = true, Callback = function(v) S.AimSmoothnessY = v end })
aimGroup:AddSlider("Aim_JumpDamping", { Text = "Jump damping %", Default = 40, Min = 0, Max = 100, Rounding = 0, Compact = true, Callback = function(v) S.AimJumpDamping = v end })
aimGroup:AddToggle("Aim_CancelSprings", { Text = "Pre-cancel weapon springs", Default = true, Callback = function(v) S.AimCancelSprings = v end })
aimGroup:AddToggle("Aim_CurvedFlick", { Text = "Humanized curved flicks", Default = false, Callback = function(v) S.AimCurvedFlick = v end })
aimGroup:AddSlider("Aim_CurvedIntensity", { Text = "Curve amplitude", Default = 0.35, Min = 0.05, Max = 1.0, Rounding = 2, Compact = true, Callback = function(v) S.AimCurvedIntensity = v end })
aimGroup:AddSlider("Aim_TrackAssist", { Text = "Track assist %", Default = 100, Min = 0, Max = 100, Rounding = 0, Compact = true, Callback = function(v) S.AimTrackAssist = v end })
aimGroup:AddSlider("Aim_MaxSpeed", { Text = "Max turn speed deg/s", Default = 0, Min = 0, Max = 3600, Rounding = 0, Compact = true, Callback = function(v) S.AimMaxSpeed = v end })
aimGroup:AddSlider("Aim_Deadzone", { Text = "Deadzone deg", Default = 0, Min = 0, Max = 10, Rounding = 2, Compact = true, Callback = function(v) S.AimDeadzoneDeg = v end })
aimGroup:AddSlider("Aim_FOVDeg", { Text = "FOV deg", Default = 20, Min = 1, Max = 180, Rounding = 1, Compact = true, Callback = function(v) S.AimFOVDeg = v end })
aimGroup:AddSlider("Aim_SwitchDeg", { Text = "Switch threshold deg", Default = 2, Min = 0, Max = 45, Rounding = 1, Compact = true, Callback = function(v) S.AimSwitchDeg = v end })
aimGroup:AddSlider("Aim_Stickiness", { Text = "Stickiness", Default = 0.15, Min = 0, Max = 0.5, Rounding = 2, Compact = true, Callback = function(v) S.AimStickiness = v end })
aimGroup:AddSlider("Aim_ForgetTime", { Text = "Forget time s", Default = 0.2, Min = 0, Max = 1.0, Rounding = 2, Compact = true, Callback = function(v) S.AimForgetTime = v end })
aimGroup:AddDropdown("Aim_TargetPart", { Text = "Target bone", Default = "Best", Values = {"Best","Head","Torso","Closest"}, Callback = function(v) S.AimTargetPart = v end })
aimGroup:AddDropdown("Aim_Priority", { Text = "Priority", Default = "Crosshair", Values = {"Crosshair","Health","Distance"}, Callback = function(v) S.AimPriority = v end })
aimGroup:AddToggle("Aim_VisCheck", { Text = "Visibility check", Default = true, Callback = function(v) S.AimVisCheck = v end })
aimGroup:AddToggle("Aim_SkipImmune", { Text = "Skip immune", Default = true, Callback = function(v) S.AimSkipImmune = v end })
aimGroup:AddToggle("Aim_Prediction", { Text = "Prediction", Default = false, Callback = function(v) S.AimPrediction = v end })
aimGroup:AddToggle("Aim_ShotOverride", { Text = "Shot override", Default = false, Callback = function(v) S.AimShotOverride = v end })
aimGroup:AddSlider("Aim_ReactionMs", { Text = "Reaction delay ms", Default = 0, Min = 0, Max = 300, Rounding = 0, Compact = true, Callback = function(v) S.AimReactionMs = v end })
aimGroup:AddSlider("Aim_NoiseDeg", { Text = "Aim noise deg/s", Default = 0, Min = 0, Max = 20, Rounding = 1, Compact = true, Callback = function(v) S.AimNoiseDeg = v end })
aimGroup:AddSlider("Aim_Overshoot", { Text = "Overshoot", Default = 0, Min = 0, Max = 1, Rounding = 2, Compact = true, Callback = function(v) S.AimOvershoot = v end })
aimGroup:AddToggle("Aim_ShowFOV", { Text = "Show FOV", Default = false, Callback = function(v) S.AimShowFOV = v end })
aimGroup:AddToggle("Aim_ShowLock", { Text = "Show lock indicator", Default = false, Callback = function(v) S.AimShowLock = v end })
aimGroup:AddToggle("Aim_DirectCamera", { Text = "Direct camera fallback", Default = false, Callback = function(v) S.AimDirectCamera = v end })

local rageGroup = CombatTab:AddRightGroupbox("Rage (Polar)")
rageGroup:AddToggle("Rage_Enabled", {
    Text = "Enable Rage", Default = false,
    Callback = function(v)
        if v then Rage.enable() else Rage.disable() end
    end
}):AddKeyPicker("Rage_Key", {
    Text = "Rage", Default = "None", Mode = "Toggle", NoUI = true,
    SyncToggleState = true, Callback = function(state)
        if state then Rage.enable() else Rage.disable() end
    end
})
rageGroup:AddSlider("Rage_Taps", { Text = "Taps per fire", Default = 6, Min = 1, Max = 8, Rounding = 0, Compact = true, Callback = function(v) S.RageTaps = v end })
rageGroup:AddSlider("Rage_TapsPerFrame", { Text = "Taps per frame", Default = 1, Min = 1, Max = 6, Rounding = 0, Compact = true, Callback = function(v) S.RageTapsPerFrame = v end })
rageGroup:AddDropdown("Rage_OnEmpty", { Text = "On empty", Default = "Swap", Values = {"Swap","Reload"}, Callback = function(v) S.RageOnEmpty = v end })
rageGroup:AddDropdown("Rage_PreferredSlot", { Text = "Preferred slot", Default = "Primary", Values = {"Primary","Secondary","Melee"}, Callback = function(v) S.RagePreferredSlot = v end })
rageGroup:AddToggle("Rage_SkipImmune", { Text = "Hold fire on immune", Default = true, Callback = function(v) S.RageSkipImmune = v end })
rageGroup:AddToggle("Rage_HPPriority", { Text = "Target low HP first", Default = true, Callback = function(v) S.RageHPPriority = v end })
rageGroup:AddToggle("Rage_PrioritizeHackers", { Text = "Target cheaters first", Default = true, Callback = function(v) S.RagePrioritizeHackers = v end })
rageGroup:AddToggle("Rage_HideJitter", { Text = "Hide jitter", Default = true, Callback = function(v) S.RageHideJitter = v end })
rageGroup:AddToggle("Rage_PredictResurface", { Text = "Predict resurface", Default = true, Callback = function(v) S.RagePredictResurface = v end })
rageGroup:AddToggle("Rage_PredictPrefire", { Text = "Prefire resurface", Default = true, Callback = function(v) S.RagePredictPrefire = v end })
rageGroup:AddToggle("Rage_AttackContinuity", { Text = "Attack continuity", Default = true, Callback = function(v) S.RageAttackContinuity = v end })
rageGroup:AddToggle("Rage_PhysicsFlags", { Text = "Physics flags", Default = true, Callback = function(v) S.RagePhysicsFlags = v end })
rageGroup:AddToggle("Rage_GatePoison", { Text = "Gate poison", Default = true, Callback = function(v) S.RageGatePoison = v end })
rageGroup:AddToggle("Rage_IdentityDance", { Text = "Identity dance", Default = true, Callback = function(v) S.RageIdentityDance = v end })
rageGroup:AddDropdown("Rage_VoidDepth", { Text = "Void depth", Default = "deep", Values = {"shallow","deep"}, Callback = function(v) S.RageVoidDepth = v end })
rageGroup:AddToggle("Rage_VoidMove", { Text = "Void move", Default = true, Callback = function(v) S.RageVoidMove = v end })
rageGroup:AddSlider("Rage_KillPlaneBuffer", { Text = "Kill plane buffer", Default = 200, Min = 0, Max = 500, Rounding = 0, Compact = true, Callback = function(v) S.RageKillPlaneBuffer = v end })
rageGroup:AddDropdown("Rage_RestoreMode", { Text = "Restore mode", Default = "auto", Values = {"auto","none","render","kicia"}, Callback = function(v) S.RageRestoreMode = v end })
rageGroup:AddToggle("Rage_KnifeBot", { Text = "Knife bot", Default = true, Callback = function(v) S.RageKnifeBot = v end })
rageGroup:AddToggle("Rage_KnifeBackstab", { Text = "Knife backstab", Default = true, Callback = function(v) S.RageKnifeBackstab = v end })
rageGroup:AddToggle("Rage_ShieldBackstab", { Text = "Shield backstab", Default = true, Callback = function(v) S.RageShieldBackstab = v end })
rageGroup:AddToggle("Rage_GumMode", { Text = "Gum mode", Default = true, Callback = function(v) S.RageGumMode = v and "on" or "off" end })
rageGroup:AddToggle("Rage_GumVoidFire", { Text = "Gum void fire", Default = true, Callback = function(v) S.RageGumVoidFire = v end })
rageGroup:AddToggle("Rage_AttackTranslocate", { Text = "Attack translocate", Default = true, Callback = function(v) S.RageAttackTranslocate = v end })
rageGroup:AddSlider("Rage_BaitHeldMs", { Text = "Bait held ms", Default = 300, Min = 0, Max = 1000, Rounding = 0, Compact = true, Callback = function(v) S.RageBaitHeldMs = v end })
rageGroup:AddSlider("Rage_BaitRate", { Text = "Bait rate", Default = 2, Min = 1, Max = 6, Rounding = 0, Compact = true, Callback = function(v) S.RageBaitRate = v end })
rageGroup:AddToggle("Rage_CameraAnchor", { Text = "Camera anchor", Default = true, Callback = function(v) S.RageCameraAnchor = v end })
rageGroup:AddToggle("Rage_PolarParity", { Text = "Polar parity", Default = true, Callback = function(v) S.RagePolarParity = v end })
rageGroup:AddToggle("Rage_VoidPhase", { Text = "Void phase", Default = true, Callback = function(v) S.RageVoidPhase = v end })
rageGroup:AddSlider("Rage_EyeMuzzleSep", { Text = "Eye muzzle sep", Default = 0.07, Min = 0, Max = 1, Rounding = 2, Compact = true, Callback = function(v) S.RageEyeMuzzleSep = v end })

local antiGroup = CombatTab:AddRightGroupbox("Anti-Aim")
antiGroup:AddToggle("AntiAim_Enabled", { Text = "Enable", Default = false, Callback = function(v) S.AntiAimEnabled = v end })
antiGroup:AddDropdown("AntiAim_Yaw", { Text = "Yaw", Default = "jitter", Values = {"none","jitter","spinbot","random"}, Callback = function(v) S.AntiAimYaw = v end })
antiGroup:AddDropdown("AntiAim_Pitch", { Text = "Pitch", Default = "jitter", Values = {"none","jitter","spinbot","random"}, Callback = function(v) S.AntiAimPitch = v end })
antiGroup:AddDropdown("AntiAim_Angle", { Text = "Angle", Default = "none", Values = {"none","tilt 45","tilt 90","upside down","custom"}, Callback = function(v) S.AntiAimAngle = v end })
antiGroup:AddSlider("AntiAim_CustomAngle", { Text = "Custom Angle", Default = 0, Min = 0, Max = 360, Rounding = 1, Compact = true, Callback = function(v) S.AntiAimCustomAngle = v end })
antiGroup:AddSlider("AntiAim_MinSpeed", { Text = "Min Speed", Default = 10, Min = 1, Max = 50, Rounding = 1, Compact = true, Callback = function(v) S.AntiAimMinSpeed = v end })
antiGroup:AddSlider("AntiAim_MaxSpeed", { Text = "Max Speed", Default = 20, Min = 1, Max = 100, Rounding = 1, Compact = true, Callback = function(v) S.AntiAimMaxSpeed = v end })
antiGroup:AddSlider("AntiAim_MinAngle", { Text = "Min Angle", Default = 30, Min = 1, Max = 180, Rounding = 1, Compact = true, Callback = function(v) S.AntiAimMinAngle = v end })
antiGroup:AddSlider("AntiAim_MaxAngle", { Text = "Max Angle", Default = 60, Min = 1, Max = 180, Rounding = 1, Compact = true, Callback = function(v) S.AntiAimMaxAngle = v end })
antiGroup:AddToggle("AntiAim_RandomAngle", { Text = "Random Angle", Default = false, Callback = function(v) S.AntiAimRandomAngle = v end })

local espGroup = VisualsTab:AddLeftGroupbox("ESP")
espGroup:AddToggle("ESP_Enabled", { Text = "Enable", Default = true, Callback = function(v) S.ESPEnabled = v end })
espGroup:AddToggle("ESP_ShowName", { Text = "Name", Default = true, Callback = function(v) S.ESPShowName = v end })
espGroup:AddToggle("ESP_ShowDistance", { Text = "Distance", Default = true, Callback = function(v) S.ESPShowDistance = v end })
espGroup:AddToggle("ESP_ShowHealth", { Text = "Health", Default = true, Callback = function(v) S.ESPShowHealth = v end })
espGroup:AddToggle("ESP_ShowTracer", { Text = "Tracer", Default = true, Callback = function(v) S.ESPShowTracer = v end })
espGroup:AddToggle("ESP_ShowSkeleton", { Text = "Skeleton", Default = true, Callback = function(v) S.ESPShowSkeleton = v end })
espGroup:AddSlider("ESP_MaxDist", { Text = "Max Distance", Default = 1200, Min = 100, Max = 5000, Rounding = 0, Compact = true, Callback = function(v) S.ESPMaxDistance = v end })
espGroup:AddSlider("ESP_MaxPlayers", { Text = "Max Players", Default = 0, Min = 0, Max = 24, Rounding = 0, Compact = true, Callback = function(v) S.ESPMaxPlayers = v end })
espGroup:AddToggle("ESP_TeamCheck", { Text = "Team Check", Default = true, Callback = function(v) S.ESPTeamCheck = v; S.TeamCheck = v end })
espGroup:AddSlider("ESP_BoxScale", { Text = "Box Size", Default = 1, Min = 0.6, Max = 1.6, Rounding = 2, Compact = true, Callback = function(v) S.ESPBoxScale = v end })

local crossGroup = VisualsTab:AddRightGroupbox("Crosshair")
crossGroup:AddToggle("Crosshair_Enabled", { Text = "Enable", Default = false, Callback = function(v) S.CrosshairEnabled = v end }):AddColorPicker("Crosshair_Color", { Default = Color3.fromRGB(0, 200, 255), Title = "Color", Callback = function(v) S.CrosshairColor = v end })
crossGroup:AddToggle("Crosshair_ShowLines", { Text = "Show Lines", Default = true, Callback = function(v) S.CrosshairShowLines = v end })
crossGroup:AddSlider("Crosshair_Spin", { Text = "Spin Speed", Default = 150, Min = 0, Max = 340, Rounding = 0, Compact = true, Callback = function(v) S.CrosshairSpinSpeed = v end })
crossGroup:AddDropdown("Crosshair_Mode", { Text = "Mode", Default = "static", Values = {"static","follow muzzle"}, Callback = function(v) S.CrosshairMode = v end })

local moveGroup = MovementTab:AddLeftGroupbox("Movement")
moveGroup:AddToggle("Move_InfJump", { Text = "Infinite Jump", Default = false, Callback = function(v) S.InfJump = v end })
moveGroup:AddToggle("Move_Noclip", { Text = "Noclip", Default = false, Callback = function(v) S.Noclip = v end })
moveGroup:AddToggle("Move_Fly", { Text = "Fly", Default = false, Callback = function(v) S.FlyEnabled = v; updateFly() end })
moveGroup:AddSlider("Move_WalkSpeed", { Text = "WalkSpeed", Default = 16, Min = 16, Max = 200, Rounding = 0, Compact = true, Callback = function(v) S.WalkSpeed = v end })
moveGroup:AddSlider("Move_JumpPower", { Text = "JumpPower", Default = 50, Min = 50, Max = 300, Rounding = 0, Compact = true, Callback = function(v) S.JumpPower = v end })
moveGroup:AddSlider("Move_FlySpeed", { Text = "Fly Speed", Default = 50, Min = 16, Max = 750, Rounding = 0, Compact = true, Callback = function(v) S.FlySpeed = v end })

local gunGroup = GunTab:AddLeftGroupbox("Gun Mods")
gunGroup:AddToggle("Gun_AntiKatana", { Text = "Anti Katana", Default = false, Callback = function(v) S.AntiKatana = v end })
gunGroup:AddToggle("Gun_NoCooldown", { Text = "No Cooldown", Default = false, Callback = function(v) S.NoCooldown = v end })
gunGroup:AddToggle("Gun_NoSpread", { Text = "No Spread", Default = false, Callback = function(v) S.NoSpread = v end })
gunGroup:AddToggle("Gun_NoRecoil", { Text = "No Recoil", Default = false, Callback = function(v) S.NoRecoil = v end })
gunGroup:AddToggle("Gun_MaxAccuracy", { Text = "Max Accuracy", Default = false, Callback = function(v) S.MaxAccuracy = v end })
gunGroup:AddToggle("Gun_RapidAttack", { Text = "Rapid Attack", Default = false, Callback = function(v) S.RapidAttack = v end })
gunGroup:AddToggle("Gun_NoMuzzleFlash", { Text = "No Muzzle Flash", Default = false, Callback = function(v) S.NoMuzzleFlash = v; updateMuzzleFlash() end })

local deviceGroup = MiscTab:AddLeftGroupbox("Device Spoof")
deviceGroup:AddToggle("Device_Spoof", { Text = "Enable", Default = false, Callback = function(v) S.DeviceSpoof = v; applyDeviceSpoof() end })
deviceGroup:AddDropdown("Device_Type", { Text = "Type", Default = "PC", Values = {"PC","Console","Mobile","VR"}, Callback = function(v) S.DeviceType = v; if S.DeviceSpoof then applyDeviceSpoof() end end })

local miscGroup = MiscTab:AddRightGroupbox("Misc")
miscGroup:AddToggle("Misc_TeamCheck", { Text = "Team Check", Default = true, Callback = function(v) S.TeamCheck = v end })
miscGroup:AddToggle("Misc_AntiAFK", { Text = "Anti AFK", Default = true, Callback = function(v) S.AntiAFK = v end })
miscGroup:AddButton({ Text = "卸載腳本", Func = function()
    pcall(function() RunService:UnbindFromRenderStep("v3Hub_Aimbot") end)
    if antiAimConn then antiAimConn:Disconnect() end
    if espGui then espGui:Destroy() end
    for _, line in ipairs(crosshairLines) do pcall(function() line:Remove() end) end
    for k, _ in pairs(espCache) do clESP(k) end
    cleanupFly()
    if muzzleFlashConn then muzzleFlashConn:Disconnect() end
    pcall(Rage.unload)
    pcall(Aimbot.unload)
    pcall(ViewAngle.restore)
    pcall(ConstPatch.revertAll)
    Library:Unload()
end })

local autoQueueGroup = AutoTab:AddLeftGroupbox("Auto Queue")
autoQueueGroup:AddToggle("AutoQueue_Enabled", { Text = "Enable", Default = false, Callback = function(v) S.AutoQueueEnabled = v end })
autoQueueGroup:AddDropdown("AutoQueue_Mode", { Text = "Mode", Default = "1v1", Values = {"1v1","2v2","3v3","4v4","5v5"}, Callback = function(v) S.AutoQueueMode = v end })
autoQueueGroup:AddToggle("AutoQueue_Ranked", { Text = "Ranked", Default = false, Callback = function(v) S.AutoQueueRanked = v end })
autoQueueGroup:AddSlider("AutoQueue_Delay", { Text = "Delay s", Default = 2, Min = 0, Max = 30, Rounding = 1, Compact = true, Callback = function(v) S.AutoQueueDelay = v end })

if SaveManager then
    pcall(function() SaveManager:BuildConfigSection(ConfigTab) end)
    pcall(function() SaveManager:LoadAutoloadConfig() end)
end

pcall(Rage.init)

Library:Notify({ Title = "v3 Hub", Description = "v11.0 載入完成", Time = 4 })
print("[v11.0] 完整載入完成")
