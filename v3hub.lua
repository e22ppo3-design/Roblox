-- ============================================================
-- LuaHook v12.0 — 第一段完整版
-- 框架 + 戰鬥 + 狂暴（Linoria 極地）+ 透視
-- ============================================================

local cloneref = clonereference or cloneref or function(x) return x end
local _CR = (getgenv and getgenv().__LH_CloneRef == true)
local function cr(x) if _CR and x then return cloneref(x) else return x end end

local Players           = cr(game:GetService("Players"))
local RunService        = cr(game:GetService("RunService"))
local UserInputService  = cr(game:GetService("UserInputService"))
local VirtualInputMgr   = cr(game:GetService("VirtualInputManager"))
local ReplicatedStorage = cr(game:GetService("ReplicatedStorage"))
local CollectionService = cr(game:GetService("CollectionService"))
local Lighting          = cr(game:GetService("Lighting"))
local Debris            = cr(game:GetService("Debris"))
local Workspace         = workspace
local Camera            = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end)

local lp = Players.LocalPlayer
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

local function waitForGameReady()
    repeat task.wait() until game:IsLoaded()
    if not lp then
        repeat task.wait() until Players.LocalPlayer
        lp = Players.LocalPlayer
    end
    if not lp:FindFirstChild("PlayerScripts") then
        repeat task.wait() until lp:FindFirstChild("PlayerScripts")
    end
    local deadline = tick() + 5
    while lp.Character == nil and tick() < deadline do task.wait() end
    return true
end
waitForGameReady()

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

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local function isInputActive(key)
    if key == "MB1" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
    if key == "MB2" then
        if isMobile then return true end
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    end
    if key == "Always" then return true end
    local kc = Enum.KeyCode[key]
    if kc and not isMobile then
        return UserInputService:IsKeyDown(kc)
    end
    return false
end

local function awaitGameLoaded(moduleInst, timeout)
    if not moduleInst or type(getloadedmodules) ~= "function" then return end
    local deadline = tick() + (timeout or 15)
    repeat
        local ok, loaded = pcall(getloadedmodules)
        if ok and type(loaded) == "table" then
            for _, m in ipairs(loaded) do
                if m == moduleInst then return end
            end
        end
        task.wait(0.1)
    until tick() >= deadline
end

local function loadGameModule(root, names)
    local inst = waitModule(root, names)
    awaitGameLoaded(inst, 15)
    return safeRequire(inst)
end

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
    function() Rivals.Util    = loadGameModule(ReplicatedStorage, {"Modules","Utility"}) end,
    function() Rivals.Fighter = loadGameModule(lp.PlayerScripts,  {"Controllers","FighterController"}) end,
    function() Rivals.Enums   = loadGameModule(ReplicatedStorage, {"Modules","EnumLibrary"}) end,
    function() Rivals.Cosmetics = loadGameModule(ReplicatedStorage, {"Modules","CosmeticLibrary"}) end,
    function() Rivals.ItemLib   = loadGameModule(ReplicatedStorage, {"Modules","ItemLibrary"}) end,
})
Rivals.Ready = (Rivals.Util ~= nil and Rivals.Fighter ~= nil)

local _weaponResolving = false
local hookGunModule
local function resolveWeaponModules()
    if _weaponResolving then return end
    if Rivals.Gun ~= nil and Rivals.Melee ~= nil and Rivals.Knife ~= nil then return end
    _weaponResolving = true
    task.spawn(function()
        resolveAll({
            function() if Rivals.Gun   == nil then Rivals.Gun   = loadGameModule(lp.PlayerScripts, {"Modules","ItemTypes","Gun"})   end end,
            function() if Rivals.Melee == nil then Rivals.Melee = loadGameModule(lp.PlayerScripts, {"Modules","ItemTypes","Melee"}) end end,
            function() if Rivals.Knife == nil then Rivals.Knife = loadGameModule(lp.PlayerScripts, {"Modules","Items","Knife"})     end end,
        })
        _weaponResolving = false
        if Rivals.Gun ~= nil and hookGunModule ~= nil then pcall(hookGunModule) end
    end)
end
resolveWeaponModules()

lp.CharacterAdded:Connect(function()
    task.wait(0.5)
    resolveWeaponModules()
    if Rivals.Ready and hookGunModule then
        hookGunModule()
    end
end)

local function getEquippedItem()
    if not Rivals.Ready then return nil end
    local f = Rivals.Fighter and Rivals.Fighter.LocalFighter
    return f and f.EquippedItem or nil
end

local Config = {
    GUIToggleKey = "RightShift",
    SilentAim = false, SilentAimVisCheck = false, SilentAimJitter = true,
    SilentAimTargetPart = "Head", SilentAimFOV = 250, AvoidDeflect = true,
    SilentAimStickiness = 0.05,
    Aimbot = false, AimbotVisCheck = true, AimbotKey = "MB2",
    AimbotSmoothness = 0,
    AimbotSmoothnessX = 0,
    AimbotSmoothnessY = 0,
    AimbotLinkAxes = true,
    AimbotJumpDamping = 40,
    AimbotCancelSprings = true,
    AimbotCurvedFlick = false,
    AimbotCurvedIntensity = 0.35,
    AimbotTrackAssist = 100,
    AimbotFOVDeg = 20,
    AimbotMaxSpeed = 0,
    AimbotDeadzoneDeg = 0,
    AimbotSwitchDeg = 2,
    AimbotStickiness = 0.15,
    AimbotForgetTime = 0.2,
    AimbotTargetPart = "Best",
    AimbotPriority = "Crosshair",
    AimbotSkipImmune = true,
    AimbotPrediction = false,
    AimbotShotOverride = false,
    AimbotShowFOV = false, AimbotShowLock = false,
    AimbotDebug = false,
    AimbotReactionMs = 0,
    AimbotNoiseDeg = 0,
    AimbotOvershoot = 0,
    AimbotDirectCamera = false,
    Trigger = false,
    TriggerKey = "Always",
    TriggerDelayMs = 0,
    TriggerRefireMs = 0,
    TriggerHeadOnly = false,
    TriggerMaxDist = 400,
    TriggerScopeCheck = false,
    MaxDistance = 1200, TeamCheck = true,
    PredictiveLead = true, LeadCap = 15, ServerProcessingMs = 30,
    ProjectileLead = false,
    ProjectileSpeed = 300,
    AntiAimEnabled = false, AntiAimYaw = "jitter", AntiAimPitch = "jitter",
    AntiAimAngle = "none", AntiAimCustomAngle = 0,
    AntiAimMinSpeed = 10, AntiAimMaxSpeed = 20,
    AntiAimMinAngle = 30, AntiAimMaxAngle = 60,
    AntiAimRandomAngle = false,
    Rage = false,
    RageMode = "Polar",
    RageGumMode = "on",
    RageVoidDepth = "deep",
    RageGatePoison = true,
    RagePredictPrefire = true,
    RageSkipImmune = true,
    RageIdentityDance = true,
    RageAttackTranslocate = true,
    RageBaitHeldMs = 300,
    RageBaitRate = 2,
    RageRestoreMode = "auto",
    RagePhysicsFlags = true,
    RageHPPriority = true,
    RageFastTargetSwitch = true,
    RageVisCheck = false,
    RageKnifeBot = true,
    RageShieldBackstab = true,
    RageKnifeBackstab = true,
    RageGumVoidFire = true,
    RageOnEmpty = "Swap",
    RagePreferredSlot = "Primary",
    RageSwitchMelee = false,
    RageSwitchRateLimit = 0.06,
    RageEyeMuzzleSep = 0.07,
    RageKillPlaneBuffer = 200,
    RageTaps = 6,
    RageTapsPerFrame = 1,
    RageHideJitter = true,
    RageCameraAnchor = true,
    RagePolarParity = true,
    ESP = true,
    ESPTeamCheck = true,
    ESPMaxDistance = 1200,
    ESPMaxPlayers = 0,
    ESPFont = "Code",
    ESPTextSize = 14, ESPInfoTextSize = 12, ESPHealthTextSize = 11,
    ESPTextScale = 1,
    ESPTextCasing = 1,
    ESPDistanceScaling    = true,
    ESPDistanceScalingRef = 50,
    ESPCasingThickness = 1,
    ESPBoxScale = 1,
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
    ESPBoxColorMode      = "Solid",
    ESPBoxColor          = Color3.fromRGB(255, 255, 255),
    ESPBoxGradA          = Color3.fromRGB(255,  59,  78),
    ESPBoxGradB          = Color3.fromRGB(255, 194,  75),
    ESPBoxFillColor      = Color3.fromRGB(255,  59,  78),
    ESPHealthColorMode   = "Ramp",
    ESPHealthColor       = Color3.fromRGB( 61, 224, 122),
    ESPHealthGradA       = Color3.fromRGB(255,  68,  54),
    ESPHealthGradB       = Color3.fromRGB( 61, 224, 122),
    ESPNameColorMode     = "Solid",
    ESPNameColor         = Color3.fromRGB(255, 255, 255),
    ESPNameGradA         = Color3.fromRGB(255, 255, 255),
    ESPNameGradB         = Color3.fromRGB(255, 194,  75),
    ESPInfoColorMode     = "Solid",
    ESPInfoColor         = Color3.fromRGB(255, 255, 255),
    ESPInfoGradA         = Color3.fromRGB(255, 255, 255),
    ESPInfoGradB         = Color3.fromRGB(255, 158,  75),
    ESPFlagColorMode     = "PerFlag",
    ESPFlagColor         = Color3.fromRGB(255, 194,  75),
    ESPFlagGradA         = Color3.fromRGB(255, 194,  75),
    ESPFlagGradB         = Color3.fromRGB(255,  70,  85),
    ESPSkeletonColorMode = "Solid",
    ESPSkeletonColor     = Color3.fromRGB(255, 255, 255),
    ESPSkeletonGradA     = Color3.fromRGB(255, 255, 255),
    ESPSkeletonGradB     = Color3.fromRGB(120, 180, 255),
    ESPTracerColorMode   = "Solid",
    ESPTracerColor       = Color3.fromRGB(255, 255, 255),
    ESPTracerGradA       = Color3.fromRGB(255, 255, 255),
    ESPTracerGradB       = Color3.fromRGB(255,  59,  78),
    ESPMarkColorMode     = "Solid",
    ESPMarkColor         = Color3.fromRGB(255, 255, 255),
    ESPMarkGradA         = Color3.fromRGB(255, 255, 255),
    ESPMarkGradB         = Color3.fromRGB(255, 194,  75),
    ESPGradientSpeed     = 0,
    ESPGradientRotBox    = 0,
    ESPGradientRotText   = 90,
    ESPHeadDotColor      = Color3.fromRGB(255, 255, 255),
    ESPChamsFillColor    = Color3.fromRGB(255, 59, 78),
    ESPChamsOutlineColor = Color3.fromRGB(255, 255, 255),
    ColorEnemy       = Color3.fromRGB(255, 59, 78),
    ColorTeam        = Color3.fromRGB(53, 215, 199),
    ColorEnemyOcc    = Color3.fromRGB(168, 85, 96),
    ColorTeamOcc     = Color3.fromRGB(92, 153, 147),
    ColorVisible     = Color3.fromRGB(41, 224, 255),
    ESPBoxTransparency          = 0,
    ESPBoxFillTransparency      = 0.75,
    ESPNameTransparency         = 0,
    ESPHealthTransparency       = 0.1,
    ESPSkeletonTransparency     = 0.2,
    ESPTracerTransparency       = 0.35,
    ESPHeadDotTransparency      = 0,
    ESPChamsFillTransparency    = 0.6,
    ESPChamsOutlineTransparency = 0,
    ESPRadar = false,
    ESPRadarSize = 200,
    ESPRadarRange = 150,
    ESPRadarRotate = true,
    ESPRadarVisSplit = true,
    ESPRadarInset = 24,
    ESPFadeIn = true,
    ESPArrowDistFade  = true,
    ESPArrowDistLabel = false,
    ESPLookLine       = false,
    ESPLookLineLength = 8,
    ESPHealthSmooth = true,
    ESPHealthGhost = true,
    ESPDeclutter = true,
    ESPChamsVisSplit = true,
    ESPPeekAlert = false,
    ESPThreatCount = false,
    ESPPrimaryEmphasis = false,
    ESPHealTick = false,
    ESPNameHealthUnderline = false,
    ESPLockChevron         = false,
    ESPChamsStyle          = "Shade",
    ESPNameMode            = "Display",
}
if isMobile then
    Config.AimbotKey = "Always"
end

local ViewAngle
local State = {
    Target = nil, CamPos = Vector3.zero,
    AimbotTarget = nil, AimbotPart = nil,
    AimbotLastTarget = nil, AimbotLastTargetTime = 0,
    AimbotKeyHeld = false, SilentLastTarget = nil,
    RageAutoTransport = "kicia", RageTransportSwitches = 0, RageLastLossAt = 0,
    AimbotFlickActive = false, AimbotSpringOffset = Vector2.zero,
    RageRealCF   = nil,
    RageRealChar = nil,
    RageTarget   = nil,
    RageVoidCF   = nil,
    RageVoidNext = 0,
    RageVoidBase = nil,
    RageVoidSteps = 0,
    RageLastFireTime = 0,
    RageReloadLast   = 0,
    RageSwitchLast   = 0,
    RageForging          = false,
    RageLeakCanary       = 0,
    RageTracerCanary     = 0,
    RageBlankCanary      = 0,
    RageOOBParkCanary    = 0,
    RageHitsOn           = 0,
    RageHitsOff          = 0,
    RageOffFromSelf      = 0,
    RageOffFromTarget    = 0,
    ViewAngleForged      = false,
    RageKnifeSwings      = 0,
    RageKnifeStatus      = "idle",
    RageRawSet           = false,
    RagePhysRate         = "off",
    RageFPDHPath         = "not attempted",
    RageParkDirty        = false,
    RageLastParkPos      = nil,
    RageParkLatchCanary  = 0,
    RageLatchStuds       = 0,
    RageOrderCanary      = 0,
    RagePostPark         = false,
    RageBelowPlaneFrames = 0,
    RageBelowPlaneLast   = 0,
    RageBelowPlaneDeaths = 0,
    RageParkDriftFrames  = 0,
    RageParkDrift        = 0,
    RageParkDriftY       = 0,
    RageEyeClampFrames   = 0,
    RageParkClampFrames  = 0,
    RageTranslocateBaits = 0,
    RageFireZeroFrames = 0,
    IdentitySafe = nil,
    CapabilityErrors = 0,
    CapabilityKilledAt = nil,
    CapabilityLastStatus = nil,
    CapabilityRecoveries = 0,
    CapabilityDirty = false,
    RageWhyProtected = 0,
    RageWhyNoPark = 0,
    RageWhyPrimeWait = 0,
    RageWhyPredict = 0,
    RageWhyDip = 0,
    RageWhyMeleeCd = 0,
    RageFireFrames = 0,
    RageImmuneStale = 0,
    RageAmmoUnreadable = 0,
    RageBaitHoldFrames = 0,
    RageBaitPinRefused = 0,
    RageBaitRingFallbacks = 0,
    RageVoidFires = 0,
    RagePoisonBlips = 0,
    RagePreFires = 0,
    RagePredTarget = nil,
    RagePredHide = 0, RagePredHideN = 0,
    RagePredAtk = 0,  RagePredAtkN = 0,
    RagePredPhase = "?", RagePredFor = 0,
    RagePredDue = 0,
    RagePredWindow = false,
    RagePredMag = 0,
    RageGumMode = "off",
    RageInMatch  = false,
    RageStatus   = "Idle",
    RageFireFromPos = nil,
    RageFireAimPos  = nil,
    RageFireHitPart = nil,
    RageFireStamp   = 0,
    RageDealtTotal  = 0,
    RageFiring          = false,
    RageVoidActive      = false,
    RageTranslocating   = false,
    RageTrueVelocityMap = {},
    RageSuspectedProtection = {},
    RageBacktrackBuf    = {},
    RageCharTokens      = {},
    Shots = 0, Hits = 0,
    ESPObjects = {}, RainbowHue = 0,
}

local HEAD_PARTS    = { "HitboxHead", "HitboxHeadSmall", "Head" }
local TORSO_PARTS   = { "HitboxBody", "UpperTorso", "HumanoidRootPart", "LowerTorso" }
local CLOSEST_PARTS = {
    "HitboxHead","Head","UpperTorso","LowerTorso","HumanoidRootPart",
    "LeftHand","RightHand","LeftFoot","RightFoot",
    "LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg",
}

local function envIdOf(player)
    local id = nil
    pcall(function()
        local fc = Rivals.Fighter
        if fc == nil then return end
        local f = (player == lp) and fc.LocalFighter or (fc._player_to_fighter and fc._player_to_fighter[player])
        if f == nil then return end
        id = f:Get("EnvironmentID")
        if id == nil and f.Entity ~= nil then id = f.Entity:Get("EnvironmentID") end
    end)
    return id
end
local function isTeammate(player)
    if player == lp then return true end
    local myEnv, theirEnv = envIdOf(lp), envIdOf(player)
    if myEnv ~= nil and theirEnv ~= nil and myEnv ~= theirEnv then return true end
    local a = lp:GetAttribute("TeamID")
    local b = player:GetAttribute("TeamID")
    if a == nil or b == nil then
        if lp.Team ~= nil and player.Team ~= nil then return lp.Team == player.Team end
        return false
    end
    return a == b
end
local function isAlive(player)
    local c = player.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h ~= nil and h.Health > 0
end

local identityIsSafe = (function()
    local latched, killed = nil, false
    local _seamShown = {}
    State.CapabilityObserver = false
    pcall(function()
        game:GetService("LogService").MessageOut:Connect(function(msg)
            if type(msg) ~= "string" or not string.find(msg, "lacking capability", 1, true) then return end
            State.CapabilityErrors = (State.CapabilityErrors or 0) + 1
            State.CapabilityLastStatus = tostring(State.RageStatus)
            local seam = tostring(State.CapabilitySeam or "unlabelled")
            if _seamShown[seam] == nil then
                _seamShown[seam] = true
                print("[LuaHook] CAPABILITY ERROR while: " .. seam .. "   (rage status: "
                      .. tostring(State.RageStatus) .. ")")
            end
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
            latched = (Config.RageIdentityDance == true)
            State.IdentitySafe = latched
        end
        return latched
    end
end)()

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
local function getHealth(player)
    if not player.Character then return 0, 100 end
    local h = player.Character:FindFirstChildOfClass("Humanoid")
    if not h then return 0, 100 end
    return h.Health, h.MaxHealth
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
    local ok2, fallback = pcall(function()
        for _, c in ipairs(player.Character:GetChildren()) do
            if c:IsA("Model") and not c:FindFirstChildOfClass("Humanoid") then
                if c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart") then
                    return c.Name
                end
            end
            if c:IsA("Tool") then return c.Name end
        end
        return "?"
    end)
    return (ok2 and type(fallback) == "string") and fallback or "?"
end

local function pickPart(char, mode)
    if not char then return nil end
    if mode == "Closest" then
        local best, bestDist = nil, math.huge
        local vp     = Camera.ViewportSize
        local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
        for _, name in ipairs(CLOSEST_PARTS) do
            local p = char:FindFirstChild(name)
            if p and p:IsA("BasePart") then
                local sp, on = Camera:WorldToViewportPoint(p.Position)
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

local visParams = RaycastParams.new()
visParams.FilterType = Enum.RaycastFilterType.Exclude
local _visFilterChar = nil
local function isVisible(worldPos)
    local origin = Camera.CFrame.Position
    local _vc = lp.Character
    if _vc ~= _visFilterChar then
        visParams.FilterDescendantsInstances = { _vc }
        _visFilterChar = _vc
    end
    local result = Workspace:Raycast(origin, worldPos - origin, visParams)
    if not result then return true end
    local hitModel = result.Instance and result.Instance:FindFirstAncestorOfClass("Model")
    if hitModel and Players:GetPlayerFromCharacter(hitModel) then return true end
    return (result.Position - worldPos).Magnitude < 3
end

local DEFLECT_ANIM_IDS = {
    ["14761240825"] = true, ["14761220206"] = true,
    ["14761234917"] = true, ["14761221711"] = true, ["14761223422"] = true, ["14761225204"] = true, ["14761232380"] = true,
    ["90436105114997"] = true, ["90797895557136"] = true, ["77995180947430"] = true, ["111943779640553"] = true,
    ["131072510521727"] = true, ["132022220827223"] = true, ["116315405171252"] = true, ["110358509711635"] = true, ["98242486936084"] = true, ["81132288854196"] = true,
    ["123293403148826"] = true, ["136354716301184"] = true, ["120567011479119"] = true, ["92502373956550"] = true, ["83541611040586"] = true, ["92773106977434"] = true,
    ["75844592081515"] = true, ["75381142568185"] = true,
}
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

local _deflecting = {}
local _deflGen    = {}
local _deflHookLive = false
local DEFLECT_CLEAR_PAD = 0.05
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
        local ok, katana = pcall(loadGameModule, lp.PlayerScripts, {"Modules", "Items", "Katana"})
        if not ok or type(katana) ~= "table" or type(katana._StartDeflecting) ~= "function" then
            return
        end
        local orig = shared._LH_KatanaDeflOrig
        if not orig then orig = clonefunction(katana._StartDeflecting) end
        shared._LH_KatanaMod     = katana
        shared._LH_KatanaDeflOrig = orig
        if setreadonly then pcall(setreadonly, katana, false) end
        katana._StartDeflecting = function(self, ...)
            pcall(recordDeflect, self)
            return orig(self, ...)
        end
        _deflHookLive = true
    end)
end)()

local _invincible = {}
local _invincEnt  = {}
local function isSpawnProtected(player)
    if not player then return false end
    if not (Rivals.Ready and Rivals.Fighter) then return false end
    local map = Rivals.Fighter._player_to_fighter
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

local KATANA_NAMES = { "katana", "saber", "lightning bolt", "evil trident", "tridant", "devil's trident", "linked sword", "keytana", "cutlass", "swordfish", "riptide" }
local function isKatana(player)
    local w = getWeaponName(player):lower()
    for _, n in ipairs(KATANA_NAMES) do
        if w:find(n, 1, true) then return true end
    end
    return isDeflecting(player)
end
local function isLocalKnife()
    local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
    if lf and lf.EquippedItem then
        local name = lf.EquippedItem.Name:lower()
        if name:find("knife") or name:find("karambit") or name:find("balisong") or name:find("chancla") or name:find("machete") or name:find("candy cane") or name:find("armature") or name:find("daggers") or name:find("axe") then
            return true
        end
    end
    return false
end
local KNIFE_NAMES = { "knife", "karambit", "balisong", "chancla", "machete", "candy cane", "armature", "daggers", "axe" }
local function isEnemyKnife(player)
    if not player then return false end
    local w = getWeaponName(player):lower()
    for _, n in ipairs(KNIFE_NAMES) do
        if w:find(n, 1, true) then return true end
    end
    return false
end

local function inMatch()
    local envOk = false
    pcall(function()
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        if lf ~= nil and lf:Get("EnvironmentID") ~= nil and lf:IsAlive() then envOk = true end
    end)
    if envOk then return true end
    if lp:GetAttribute("TeamID") ~= nil then return true end
    if lp.Team ~= nil then return true end
    local lf = Rivals.Ready and Rivals.Fighter and Rivals.Fighter.LocalFighter
    if lf then
        local ok, objId = pcall(function() return lf.EquippedItem and lf.EquippedItem:Get("ObjectID") end)
        if ok and objId then return true end
    end
    return false
end

local function isValidTarget(player, checkVis, keepDeflect, rageScope)
    if not player or player == lp then return false end
    if Config.TeamCheck and isTeammate(player) then return false end
    if not isAlive(player) then return false end
    if Config.AvoidDeflect and not keepDeflect and isDeflecting(player) then return false end
    if Config.RageSkipImmune and not rageScope and isSpawnProtected(player) then return false end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local sane = isSanePos(hrp.Position)
    if not rageScope then
        if not sane then return false end
        local myChar = lp.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myRoot and (hrp.Position - myRoot.Position).Magnitude > Config.MaxDistance then return false end
    end
    if checkVis and sane and not isVisible(hrp.Position) then return false end
    return true
end

local _sharedVelMap = {}
do
    local _svPos, _svTime = {}, {}
    local _svAccum = 0
    local SV_INTERVAL = 1 / 30
    local function velTrackerStep(dt)
        if not (Config.Aimbot or Config.SilentAim or Config.Rage) then return end
        _svAccum = _svAccum + (dt or 0)
        if _svAccum < SV_INTERVAL then return end
        _svAccum = 0
        local now = tick()
        for _, p in ipairs(getSafePlayers() or {}) do
            if p ~= lp and p.Character then
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
    end
    if shared._LH_velConn then pcall(function() shared._LH_velConn:Disconnect() end) end
    shared._LH_velConn = RunService.Heartbeat:Connect(velTrackerStep)
end

local function calculateLead(targetChar, fromPos, wantLead)
    if wantLead == nil then wantLead = Config.PredictiveLead end
    if not targetChar then return Vector3.new() end
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    local hrp = targetChar:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return Vector3.new() end
    local lat = (lp:GetNetworkPing() or 0.05) + ((Config.ServerProcessingMs or 30) / 1000)
    if Config.ProjectileLead and (Config.ProjectileSpeed or 0) > 0 then
        lat = lat + (hrp.Position - fromPos).Magnitude / Config.ProjectileSpeed
    end
    local lead = Vector3.new()
    if wantLead then
        local ply     = Players:GetPlayerFromCharacter(targetChar)
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
    local cap = Config.LeadCap or 15
    if lead.Magnitude > cap then lead = lead.Unit * cap end
    return lead
end

local function selectTarget(opts)
    opts = opts or {}
    local fov         = opts.fov or 90
    local checkVis    = opts.checkVis or false
    local mode        = opts.partMode or "Head"
    local sticky      = opts.stickyTarget
    local stickyBonus = opts.stickyBonus or 0
    local vp     = Camera.ViewportSize
    local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    local best, bestPart, bestScore = nil, nil, math.huge
    for _, player in ipairs(getSafePlayers()) do
        if player ~= lp and isValidTarget(player, false) then
            local char = player.Character
            local part = pickPart(char, mode)
            if part and (not checkVis or isVisible(part.Position)) then
                local sp, on = Camera:WorldToViewportPoint(part.Position)
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

local function aimbotKeyDown()
    return isInputActive(Config.AimbotKey)
end

-- ============================================================
-- Rage 核心
-- ============================================================
local Rage = {}
;(function()
    local _tgtConn  = nil
    local function bump(p) State.RageCharTokens[p] = (State.RageCharTokens[p] or 0) + 1 end
    local function killFloor()
        return workspace.FallenPartsDestroyHeight + Config.RageKillPlaneBuffer
    end
    local function hasLOS(fromPos, toPos, ignore)
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = ignore
        local res = workspace:Raycast(fromPos, toPos - fromPos, rp)
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
        local hitWorld   = hitPart.CFrame:PointToWorldSpace(objSpace)
        local objSpaceCF = hitPart.CFrame:ToObjectSpace(CFrame.new(hitWorld))
        camData[utf8.char(0)] = Rivals.Util:EncodeCFrame(eyeCF)
        camData[utf8.char(1)] = Rivals.Util:EncodeCFrame(muzzleCF)
        camData[utf8.char(2)] = hitPart
        camData[utf8.char(3)] = Rivals.Util:EncodeCFrame(objSpaceCF)
    end
    Rage._buildShotFields = buildShotFields
    local RAGE_CLAMP_FRAC  = 0.30
    local RAGE_JITTER_FRAC = 1.0
    local function encodeShot(camData, hitPart, targetChar, fromCamPos, claimOffset)
        if not hitPart or not camData or not Rivals.Util then return false end
        local lead      = calculateLead(targetChar, fromCamPos)
        local off       = (typeof(claimOffset) == "Vector3") and claimOffset or Vector3.zero
        local leadedPos = hitPart.Position + lead + off
        local eyeCF     = lookCF(fromCamPos, leadedPos)
        local muzzlePos = fromCamPos + (eyeCF.RightVector * 0.2) + Vector3.new(0, -Config.RageEyeMuzzleSep, 0)
        local muzzleCF  = lookCF(muzzlePos, leadedPos)
        buildShotFields(camData, eyeCF, muzzleCF, hitPart, leadedPos, Config.SilentAimJitter, 0.45, 1.0)
        return true
    end
    Rage._encodeShot = encodeShot

    local _SLOT_INDEX = { Primary = 1, Secondary = 2, Melee = 3 }
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
        if not okA then
            State.RageAmmoUnreadable = (State.RageAmmoUnreadable or 0) + 1
            return true
        end
        return type(ammo) == "number" and ammo > 0
    end
    Rage._weaponReady = weaponReady
    Rage._ensureReload = function(it)
        if it == nil then return "no item" end
        local okA, ammo = pcall(function() return it:Get("Ammo") end)
        if okA and type(ammo) == "number" and ammo > 0 then return "loaded" end
        if tick() - (State.RageReloadLast or 0) < 0.5 then return "throttled" end
        State.RageReloadLast = tick()
        pcall(function()
            local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
            if lf == nil then return end
            task.spawn(function()
                if pcall(function() lf:Input("StartReloading") end) then return end
            end)
        end)
        pcall(function() it:StartReloading() end)
        return "requested"
    end
    Rage._weaponRecovery = function(it)
        if itemIsMelee(it) then return "loaded" end
        local mode = Config.RageOnEmpty or "Reload"
        local okA, ammo = pcall(function() return it and it:Get("Ammo") end)
        local empty = not (okA and type(ammo) == "number" and ammo > 0)
        if mode ~= "Swap" or not empty then
            return Rage._ensureReload(it)
        end
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        local items = lf and lf.Items
        if type(items) ~= "table" then return Rage._ensureReload(it) end
        if tick() - (State.RageSwitchLast or 0) < 0.5 then return "swap-wait" end
        local pref = _SLOT_INDEX[Config.RagePreferredSlot or "Primary"] or 1
        local other = pref == 1 and 2 or 1
        for _, slot in ipairs({ pref, other }) do
            local w = items[slot]
            if w and w ~= it then
                local okW, wammo = pcall(function() return w:Get("Ammo") end)
                if okW and type(wammo) == "number" and wammo > 0 then
                    State.RageSwitchLast = tick()
                    local okE = pcall(function() lf:EquipItem(lf, slot) end)
                    if okE then return "swap" end
                end
            end
        end
        return Rage._ensureReload(it)
    end

    local _shootEnum = nil
    local function findTarget()
        local myChar = lp.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local cands  = {}
        for _, p in ipairs(getSafePlayers()) do
            if isValidTarget(p, Config.RageVisCheck, true, true) then
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

    local function meleeProfile(it)
        local prof = nil
        pcall(function()
            local info = it.Info
            if info == nil then return end
            if info.MaxAmmo ~= nil then return end
            local heavy = info.CriticalDamage ~= nil and type(info.HeavyAttackCooldown) == "number"
            prof = { heavy = heavy }
        end)
        return prof
    end
    local function meleeStrike(firePark, hpos, hh, tgt)
        local it = getEquippedItem()
        if it == nil then State.RageKnifeStatus = "no item" return false end
        local prof = meleeProfile(it)
        if prof == nil then State.RageKnifeStatus = "not a melee item" return false end
        local actionName = "StartShooting"
        if prof.heavy then actionName = "StartAiming" end
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
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

    local RENDER_NAME = "LuaHook_PolarCore_Restore"
    local CAMERA_NAME = "LuaHook_PolarCore_CamAnchor"
    local _realCF, _realChar = nil, nil
    local _voidCF     = nil
    local _target     = nil
    local _firing     = false
    local _inMatch    = false
    local _deflectSince = 0
    local _notified   = nil
    local _conn, _stepConn, _charConn = nil, nil, nil
    local EYE_UP_SANE     = 2.5
    local VOID_MIN_STEP   = 25000
    local VOID_R_MIN      = 110000
    local VOID_R_MAX      = 140000
    local DEFLECT_MAX_HOLD = 1.5
    local EYE_MUZZLE_SEP  = 0.07
    local RAGE_CLAMP_FRAC2 = 0.30
    local _preParkCF = nil
    local PRIME_S         = 0.07
    local HIDE_JITTER_MAX = 0.25
    local _hiding     = false
    local _primeUntil = 0

    local FFLAGS_ON  = { DFIntS2PhysicsSenderRate = "120", DFIntAssemblyHistoryBufferSize = "2147483648", DFIntAssemblyHistorySkipSize = "0" }
    local FFLAGS_OFF = { DFIntS2PhysicsSenderRate = "15",  DFIntAssemblyHistoryBufferSize = "15",         DFIntAssemblyHistorySkipSize = "8" }
    local _fpdhOriginal = nil
    local _fpdhWrote = false
    local _flagsOn = false
    local _physSet  = false
    local _physLive = false
    local function fflagApi()
        local set, get, name = nil, nil, "none"
        pcall(function()
            if type(setfflag) == "function" then set, name = setfflag, "setfflag"
            elseif type(setfastflag) == "function" then set, name = setfastflag, "setfastflag"
            elseif type(set_fflag) == "function" then set, name = set_fflag, "set_fflag" end
            if type(getfflag) == "function" then get = getfflag
            elseif type(getfastflag) == "function" then get = getfastflag end
        end)
        return set, get, name
    end
    local _fpdhGetId, _fpdhSetId, _fpdhIdTried = nil, nil, false
    local _fpdhDead = false
    local function writeFPDH(value)
        if _fpdhDead then return false, "refused earlier this session" end
        if not identityIsSafe() then return false, "skipped (identity dance off)" end
        if not _fpdhIdTried then
            _fpdhIdTried = true
            pcall(function()
                local g = getthreadidentity or get_thread_identity or getidentity or getthreadcontext
                local s = setthreadidentity or set_thread_identity or setidentity or setthreadcontext
                if type(g) == "function" and type(s) == "function" then _fpdhGetId, _fpdhSetId = g, s end
            end)
        end
        if _fpdhSetId == nil then return false, "no identity API" end
        local wrote = false
        task.spawn(function()
            local okPrev, prev = pcall(_fpdhGetId)
            if not okPrev then return end
            if not pcall(_fpdhSetId, 8) then return end
            local sp = sethiddenproperty or set_hidden_property
            local wroteVia = false
            if type(sp) == "function" then wroteVia = pcall(sp, workspace, "FallenPartsDestroyHeight", value) end
            if not wroteVia then pcall(function() workspace.FallenPartsDestroyHeight = value end) end
            pcall(_fpdhSetId, prev)
            local okR, v = pcall(function() return workspace.FallenPartsDestroyHeight end)
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
            local prev = workspace.FallenPartsDestroyHeight
            if prev ~= prev then prev = -500 end
            _fpdhOriginal = prev
        end
        local fpdhOk, fpdhHow = false, "not attempted"
        if on then
            fpdhOk, fpdhHow = writeFPDH(0 / 0)
            _fpdhWrote = fpdhOk
        elseif _fpdhWrote then
            local okBack, howBack = writeFPDH(_fpdhOriginal)
            fpdhHow = "restored=" .. tostring(okBack) .. " " .. tostring(howBack)
            _fpdhWrote = false
        else
            fpdhHow = "nothing to restore"
        end
        State.RageFPDHPath = fpdhHow
        local set, get, setName = fflagApi()
        if set == nil then
            _physSet, _physLive = false, false
            State.RagePhysRate = "no fflag setter"
            return
        end
        local want = FFLAGS_OFF
        if on then want = FFLAGS_ON end
        local threw = false
        for name, value in want do
            if not pcall(set, name, value) then threw = true end
        end
        _physSet = on and not threw
        _physLive = _physSet and fpdhOk
        State.RagePhysRate = setName .. " " .. (on and "verified" or "off")
    end
    Rage._setPhysicsFlags = setPhysicsFlags

    local function restoreMode()
        local m = Config.RageRestoreMode
        if m == "kerp" then m = "kicia" end
        if m == "auto" then m = (State.RageAutoTransport == "render") and "render" or "kicia" end
        if m == "kicia" or m == "render" or m == "none" then return m end
        return "none"
    end

    local _identGet, _identSet = nil, nil
    local _identTried = false
    local function identEnsure()
        if _identTried then return _identSet ~= nil end
        _identTried = true
        pcall(function()
            local g = getthreadidentity or get_thread_identity
            local s = setthreadidentity or set_thread_identity or setidentity or setthreadcontext
            if type(g) == "function" and type(s) == "function" then
                _identGet, _identSet = g, s
            end
        end)
        State.RageRawSet = _identSet ~= nil
        return _identSet ~= nil
    end
    local function rawSetCFrame(hrp, cf)
        State.CapabilitySeam = "07c park write (hrp.CFrame)"
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
    local VOID_DEEP_AXIS   = 1073741824
    local VOID_DEEP_JITTER = 0.4
    local _voidOrder       = { 1, 2, 3 }
    local function voidDeep() return Config.RageVoidDepth ~= "shallow" end
    local function deepMag(allowNeg)
        local m = VOID_DEEP_AXIS * (1 + math.random() * VOID_DEEP_JITTER)
        if allowNeg and math.random(0, 1) == 1 then return -m end
        return m
    end
    local function rollVoidDeep()
        local ang = math.random() * math.pi * 2
        local r   = math.random(1000, 1500)
        local x   = math.cos(ang) * r
        local y   = math.random(1000, 1500)
        local z   = math.sin(ang) * r
        local o   = _voidOrder
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
        _hiding     = true
        _primeUntil = 0
        displace(hrp, voidCFrame())
    end

    local function pointBlank(hp)
        local y = math.max(hp.Y, killFloor() + 3)
        return Vector3.new(hp.X, y, hp.Z)
    end

    local function polarFire(eyePos, aimPos, hh)
        local it = getEquippedItem()
        if not it then return 0 end
        pcall(function()
            it._shoot_cooldown = 0
            it._shoot_cooldown_no_ammo = 0
            it._last_shot = tick() - 1
        end)
        if _shootEnum == nil then
            pcall(function() _shootEnum = Rivals.Enums:ToEnum("StartShooting") end)
        end
        if _shootEnum == nil then return 0 end
        local _useItem = ReplicatedStorage.Remotes.Replication.Fighter.UseItem
        local okId, objId = pcall(function() return it:Get("ObjectID") end)
        if not okId or not objId then return 0 end
        local base = eyePos - Vector3.new(0, EYE_UP_SANE, 0)
        local fireEyePos = base + Vector3.new(0, EYE_UP_SANE, 0)
        local eyeCF    = lookCF(fireEyePos, aimPos)
        local muzzleCF = eyeCF - Vector3.new(0, EYE_MUZZLE_SEP, 0)
        local sent     = 0
        State.RageForging = true
        pcall(function()
            local taps = math.max(1, math.min(Config.RageTapsPerFrame or 1, Config.RageTaps or 6))
            for _ = 1, taps do
                local inner = {}
                buildShotFields(inner, eyeCF, muzzleCF, hh, aimPos, true, RAGE_CLAMP_FRAC2, 1.0)
                local env = { [utf8.char(1)] = inner }
                _useItem:FireServer(objId, _shootEnum, env, nil)
                sent = sent + 1
            end
        end)
        State.RageForging = false
        State.Shots = State.Shots + sent
        return sent
    end

    local function polarTick(ch, hrp)
        local tgt = _target
        if tgt and (not tgt.Parent or not tgt.Character or not isAlive(tgt) or isTeammate(tgt)
                    or isSpawnProtected(tgt)) then
            tgt = nil
        end
        if not tgt then tgt = findTarget() end
        _target = tgt
        State.RageTarget = tgt
        if not tgt or not tgt.Character then return hide(hrp, "No target") end
        if Config.AvoidDeflect and isDeflecting(tgt) then
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
        _firing = true
        State.RageFiring = true
        State.RageVoidActive = false
        local park = pointBlank(hpos)
        if not isSanePos(park) then return hide(hrp, "Hiding") end
        displace(hrp, CFrame.new(park))
        if Config.RagePolarParity and (tick() < _primeUntil) then
            State.RageFiring = false
            State.RageStatus = "Priming"
            return
        end
        local melee = itemIsMelee(it)
        if melee and Config.RageKnifeBot ~= false then
            if meleeStrike(park, hpos, hh, tgt) then
                State.RageStatus = "Melee"
            else
                State.RageStatus = "Melee (cooldown)"
            end
        else
            local sent = polarFire(park + Vector3.new(0, EYE_UP_SANE, 0), hpos, hh)
            if sent == 0 then
                State.RageStatus = "PARKED, SENT NOTHING"
            else
                State.RageStatus = "Attacking"
            end
        end
    end

    local function restoreHome(pin)
        local ch = lp.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        local back = _preParkCF
        _preParkCF = nil
        pcall(function()
            if back then hrp.CFrame = back end
            if pin then
                local hu = ch:FindFirstChildOfClass("Humanoid")
                if hu and hu:GetState() == Enum.HumanoidStateType.Freefall
                   and hu.FloorMaterial ~= Enum.Material.Air then
                    hu:ChangeState(Enum.HumanoidStateType.Running)
                end
            end
        end)
    end

    local function cameraAnchor()
        if Config.RageCameraAnchor == false then return end
        local back = _preParkCF
        if back == nil then return end
        local ch = lp.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        local delta = back.Position - hrp.Position
        if not isSanePos(delta) then return end
        Camera.CFrame = Camera.CFrame + delta
    end

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
        lp.CharacterAdded:Connect(function()
            bump(lp)
            State.RageRealCF = nil; State.RageRealChar = nil
            State.RageParkDirty = false
            State.RageTarget = nil
        end)
        bump(lp)
    end

    local function startPolarCore()
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
        _charConn = lp.CharacterAdded:Connect(function()
            _realCF = nil; _realChar = nil; _voidCF = nil; _target = nil
            _notified = nil; _firing = false; _preParkCF = nil
            _hiding, _primeUntil = true, 0
        end)
        _conn = RunService.Heartbeat:Connect(function(dt)
            if not Config.Rage or Config.RageMode ~= "Polar" then
                stopPolarCore()
                return
            end
            local ch = lp.Character
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
    function stopPolarCore()
        setPhysicsFlags(false)
        if _conn then _conn:Disconnect(); _conn = nil end
        if _stepConn then _stepConn:Disconnect(); _stepConn = nil end
        if _charConn then _charConn:Disconnect(); _charConn = nil end
        pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
        pcall(function() RunService:UnbindFromRenderStep(CAMERA_NAME) end)
        _firing = false
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Parent then
            if _realCF and _realChar == lp.Character then
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
        Config.Rage = true
        startPolarCore()
    end
    function Rage.disable()
        Config.Rage = false
        stopPolarCore()
        State.RageFiring = false
        State.RageVoidActive = false
        State.RageStatus = "Idle"
    end
    function Rage.unload()
        Rage.disable()
        if _tgtConn then pcall(function() _tgtConn:Disconnect() end); _tgtConn = nil end
    end
    Rage._encodeRageShot = encodeShot
end)()

-- 反瞄準
local antiAimState = { frameCounter = 0, smoothYaw = 0, smoothPitch = 0 }
local function getRandomInRange(mn, mx) return mn + math.random() * (mx - mn) end
local function calcAntiAimYaw()
    local yaw = 0
    local currentTime = tick()
    if Config.AntiAimYaw == "jitter" then
        local minA = math.rad(Config.AntiAimMinAngle)
        local maxA = math.rad(Config.AntiAimMaxAngle)
        if Config.AntiAimRandomAngle then yaw = getRandomInRange(-maxA, maxA)
        else yaw = math.random() > 0.5 and minA or -minA end
    elseif Config.AntiAimYaw == "spinbot" then
        local speed = getRandomInRange(Config.AntiAimMinSpeed/10, Config.AntiAimMaxSpeed/10)
        yaw = (currentTime * speed) % (2 * math.pi)
    elseif Config.AntiAimYaw == "random" then
        if antiAimState.frameCounter % 30 == 0 then
            yaw = getRandomInRange(-math.rad(Config.AntiAimMaxAngle), math.rad(Config.AntiAimMaxAngle))
        else yaw = antiAimState.smoothYaw end
        antiAimState.smoothYaw = yaw
    end
    return yaw
end
local function calcAntiAimPitch()
    local pitch = 0
    if Config.AntiAimPitch == "jitter" then
        local minA = math.rad(Config.AntiAimMinAngle)
        local maxA = math.rad(Config.AntiAimMaxAngle)
        if Config.AntiAimRandomAngle then pitch = getRandomInRange(-maxA, maxA)
        else pitch = math.random() > 0.5 and minA or -minA end
    elseif Config.AntiAimPitch == "spinbot" then
        pitch = math.sin(tick() * (Config.AntiAimMaxSpeed/10)) * math.rad(Config.AntiAimMaxAngle)
    elseif Config.AntiAimPitch == "random" then
        if antiAimState.frameCounter % 20 == 0 then
            pitch = getRandomInRange(math.rad(-89), math.rad(89))
        else pitch = antiAimState.smoothPitch end
        antiAimState.smoothPitch = pitch
    end
    return pitch
end
local function calcAntiAimRoll()
    local roll = 0
    if Config.AntiAimAngle == "tilt 45" then roll = math.rad(45)
    elseif Config.AntiAimAngle == "tilt 90" then roll = math.rad(90)
    elseif Config.AntiAimAngle == "upside down" then roll = math.rad(180)
    elseif Config.AntiAimAngle == "custom" then roll = math.rad(Config.AntiAimCustomAngle) end
    return roll
end
local antiAimConn = RunService.Heartbeat:Connect(function()
    if not Config.AntiAimEnabled then return end
    local character = lp.Character
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

-- Aimbot
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
    local function validFor(pl)
        if not isValidTarget(pl, false) then return false end
        if Config.AimbotSkipImmune and isSpawnProtected(pl) then return false end
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
        local prio = Config.AimbotPriority or "Crosshair"
        local vis  = Config.AimbotVisCheck
        local myRoot = nil
        if prio == "Distance" then
            local mc = lp.Character
            myRoot = mc and mc:FindFirstChild("HumanoidRootPart")
        end
        local bP, bPart, bAng, bScore = nil, nil, math.huge, math.huge
        local cPart, cAng, cOK = nil, math.huge, false
        for _, pl in ipairs(getSafePlayers()) do
            if pl ~= lp and validFor(pl) then
                local char = pl.Character
                local part = pickPart(char, pick)
                if part then
                    local ang    = angTo(cf, part.Position)
                    local isCur  = (pl == cur)
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
                                score = score * (1 - (Config.AimbotStickiness or 0))
                            end
                            if score < bScore then bScore, bP, bPart, bAng = score, pl, part, ang end
                        end
                    end
                end
            end
        end
        if prio == "Crosshair" and cOK and bP and bP ~= cur then
            if bAng > cAng - (Config.AimbotSwitchDeg or 0) * D2R then
                return cur, cPart, cAng
            end
        end
        return bP, bPart, bAng
    end
    local function resolvePath()
        local touchOnly = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
        if _mouseMove and not touchOnly then return "mouse" end
        if Config.AimbotDirectCamera or touchOnly then
            if not _ctlTried then
                _ctlTried = true
                task.spawn(function()
                    local ok, m = pcall(loadGameModule, lp.PlayerScripts, { "Controllers", "CameraController" })
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
        local cf     = Camera.CFrame
        local look   = cf.LookVector
        local curYaw, curPit = yawOf(look), pitchOf(look)
        if _haveCam and not _calOff then
            _gx, _nx = calibrate(wrapPi(curYaw - _lyaw), _sx, _gx, _nx, _sdx)
            _gy, _ny = calibrate(curPit - _lpit,         _sy, _gy, _ny, _sdy)
        end
        _lyaw, _lpit, _haveCam = curYaw, curPit, true
        local fov = Camera.FieldOfView
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
        if not inMatch() then
            State.AimbotKeyHeld = false
            clearTarget()
            return
        end
        local keyDown = aimbotKeyDown()
        State.AimbotKeyHeld = keyDown
        if not keyDown then clearTarget(); return end
        _path = resolvePath()
        if _path == "none" then clearTarget(); return end
        local fovR    = math.clamp(Config.AimbotFOVDeg or 20, 0.1, 180) * D2R
        local retainR = math.min(fovR * RETAIN_MUL, math.pi)
        local sticky  = _tgt
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
        local myChar = lp.Character
        local myRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myVel = myRP and myRP.AssemblyLinearVelocity or Vector3.zero
        local vRel = targetVel - myVel
        if Config.AimbotPrediction then
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
    function Aimbot.init() if Config.Aimbot then Aimbot.enable() end end
    function Aimbot.unload() Aimbot.disable() end
end)()

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
    local function fullyScoped()
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        local it = lf and lf.EquippedItem
        if not it then return true end
        return true
    end
    local function askToShoot()
        local lf = Rivals.Fighter and Rivals.Fighter.LocalFighter
        if not lf then return end
        pcall(function() lf:Input("StartShooting") end)
    end
    local function underCrosshair()
        local c = lp.Character
        if c ~= _filterChar then
            trigParams.FilterDescendantsInstances = { c }
            _filterChar = c
        end
        local cf   = Camera.CFrame
        local dist = math.clamp(Config.TriggerMaxDist or 400, 1, 400)
        local res  = Workspace:Raycast(cf.Position, cf.LookVector * dist, trigParams)
        if not res or not res.Instance then return nil end
        local model = res.Instance:FindFirstAncestorOfClass("Model")
        if not model then return nil end
        local pl = Players:GetPlayerFromCharacter(model)
        if not pl or pl == lp then return nil end
        return pl, res.Instance
    end
    local function step()
        if not Config.Trigger then return end
        if Config.Rage then _lastChar = nil return end
        if not isInputActive(Config.TriggerKey) then _lastChar = nil return end
        local pl, hit = underCrosshair()
        if not pl then _lastChar = nil return end
        if not isValidTarget(pl, false) then _lastChar = nil return end
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
    function Trigger.init() if Config.Trigger then Trigger.enable() end end
    function Trigger.unload() Trigger.disable() end
end

-- Gun 掛鉤（靜默自瞄 + 狂暴編碼）
function hookGunModule()
    if not Rivals.Ready or not Rivals.Gun then return end
    if shared._LH_GunOrig then pcall(function() Rivals.Gun.StartShooting = shared._LH_GunOrig end) end
    shared._gunHooked = game
    local oldStart = Rivals.Gun.StartShooting
    shared._LH_GunOrig = oldStart
    local hookWrapper = function(self, ...)
        local results = { oldStart(self, ...) }
        pcall(function()
            if not self.ClientFighter or not self.ClientFighter.IsLocalPlayer then return end
            local camData = results[3]
            if not camData or typeof(camData) ~= "table" then return end
            local camPos = Camera.CFrame.Position
            State.CamPos = camPos
            if Config.Rage then
                if Rage._encodeRageShot(camData) then results[4] = true end
                return
            end
            if Config.SilentAim then
                local tgt, part = selectTarget({
                    fov        = Config.SilentAimFOV,
                    checkVis   = Config.SilentAimVisCheck,
                    partMode   = Config.SilentAimTargetPart,
                    stickyTarget = State.SilentLastTarget,
                    stickyBonus  = Config.SilentAimStickiness or 0.05,
                })
                if tgt and part then
                    State.SilentLastTarget = tgt
                    if Rage._encodeShot(camData, part, tgt.Character, camPos) then
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

-- ESP
local ESP = {}
;(function()
    local _renderConn = nil
    local _espFrame   = 0
    local _lastRenderT = 0
    local _dcLastT    = 0
    local _bboxCache  = {}
    local _bboxFrameN = {}
    local _ctx        = {}
    local _renderArr  = {}
    local _dcArr      = {}
    local BLACK = Color3.new(0, 0, 0)
    local WHITE = Color3.new(1, 1, 1)
    local INK   = Color3.fromRGB(4, 6, 10)
    local HPBG  = Color3.fromRGB(11, 15, 22)
    local HP_W       = 3
    local HP_GAP     = 5
    local PAD        = 5
    local FLAG_GAP   = 6
    local BASE_H     = 1080
    local MIN_W      = 8
    local MIN_H      = 13
    local BOX_W_STUDS = 4   * 1000 / 1080
    local BOX_H_STUDS = 6.5 * 1000 / 1080
    local TEXT_FLOOR  = 8
    local DIST_MIN_MUL = 0.5
    local cam        = Camera
    local FACES = {}
    for _, n in ipairs({ "Code", "RobotoMono", "Gotham", "GothamBold", "Arial", "SourceSans" }) do
        local ok, f = pcall(function() return Enum.Font[n] end)
        if ok and f then FACES[n] = f end
    end
    if FACES.Code == nil then FACES.Code = Enum.Font.SourceSans end
    local function faceFor(name) return FACES[name] or FACES.Code end
    local GLYPH_TRI = string.char(0xE2, 0x96, 0xB2)
    local GLYPH_MID = string.char(0xC2, 0xB7)
    local function typePx(base, scale)
        local v = math.floor(base * scale + 0.5)
        if v < TEXT_FLOOR then v = TEXT_FLOOR end
        return v
    end
    local function distMul(dist)
        if not Config.ESPDistanceScaling then return 1 end
        local ref = Config.ESPDistanceScalingRef or 50
        return math.clamp(ref / math.max(dist or 1, 1), DIST_MIN_MUL, 1)
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
    local _seqCache = {}
    local function gradSeq(key, a, b)
        if not a or not b then return nil end
        local s = _seqCache[key]
        if s and s.a == a and s.b == b then return s.seq end
        local seq = ColorSequence.new({
            ColorSequenceKeypoint.new(0, a),
            ColorSequenceKeypoint.new(0.5, b),
            ColorSequenceKeypoint.new(1, a),
        })
        _seqCache[key] = { a = a, b = b, seq = seq }
        return seq
    end
    local function paint(inst, prop, key, mode, solid, ga, gb, rot, spin, now)
        if inst == nil then return end
        if mode == "Gradient" then
            local seq = gradSeq(key, ga, gb)
            if seq then
                if inst[prop] ~= WHITE then inst[prop] = WHITE end
                local ug = inst:FindFirstChildOfClass("UIGradient")
                if ug == nil then ug = Instance.new("UIGradient"); ug.Parent = inst end
                if ug.Color ~= seq then ug.Color = seq end
                local r = rot or 0
                if spin and spin > 0 then r = (r + (now or 0) * spin * 360) % 360 end
                if ug.Rotation ~= r then ug.Rotation = r end
                if not ug.Enabled then ug.Enabled = true end
                return
            end
        end
        local ug = inst:FindFirstChildOfClass("UIGradient")
        if ug and ug.Enabled then ug.Enabled = false end
        local c = solid or WHITE
        if inst[prop] ~= c then inst[prop] = c end
    end
    local function healthColor(frac)
        local mode = Config.ESPHealthColorMode or "Ramp"
        if mode == "Solid" then return Config.ESPHealthColor or Color3.fromRGB(61, 224, 122) end
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
        STARING     = Color3.fromRGB(255,  70,  85),
        DEFLECT     = Color3.fromRGB( 53, 215, 199),
        SHIELD      = Color3.fromRGB(255, 194,  75),
        INVINCIBLE  = Color3.fromRGB(255, 215,   0),
        LOW         = Color3.fromRGB(255,  90, 100),
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
            s.IgnoreGuiInset  = true
            s.ResetOnSpawn    = false
            s.DisplayOrder    = 99990
            s.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
            local parent
            pcall(function() parent = gethui and gethui() end)
            if parent == nil then pcall(function() parent = game:GetService("CoreGui") end) end
            if parent == nil then parent = lp:FindFirstChildOfClass("PlayerGui") end
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
    local function mkList(parent, z, pad, horizAlign, vertAlign)
        local f = mkFrame(parent, z)
        f.AutomaticSize = Enum.AutomaticSize.XY
        f.Size = UDim2.fromOffset(0, 0)
        local l = Instance.new("UIListLayout")
        l.FillDirection        = Enum.FillDirection.Vertical
        l.SortOrder            = Enum.SortOrder.LayoutOrder
        l.Padding              = UDim.new(0, pad or 2)
        l.HorizontalAlignment  = horizAlign or Enum.HorizontalAlignment.Center
        l.VerticalAlignment    = vertAlign or Enum.VerticalAlignment.Top
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
        s.LineJoinMode    = Enum.LineJoinMode.Miter
        s.Color = colour; s.Thickness = thick; s.Transparency = 0
        s.Parent = f
        return f, s
    end
    local function mkCasedRect(parent, z)
        local box = mkFrame(parent, z)
        box.Size = UDim2.fromScale(1, 1)
        local rIn,  sIn  = mkRing(box, z + 1, INK,   1)
        local rMid, sMid = mkRing(box, z + 2, WHITE, 1)
        local rOut, sOut = mkRing(box, z + 1, INK,   1)
        return box, sMid, sOut, sIn, rMid, rOut, rIn
    end
    local function buildTree(o)
        local g = espGui(); if not g then return nil end
        local u = {}
        local root = mkFrame(g, 2)
        root.Name = "r"
        root.Visible = false
        root.Size = UDim2.fromOffset(MIN_W, MIN_H)
        u.root = root
        u.fill = mkFrame(root, 2)
        u.fill.Size = UDim2.fromScale(1, 1)
        u.fill.Visible = false
        u.box, u.boxStroke, u.caseOut, u.caseIn, u.ringMid, u.ringOut, u.ringIn = mkCasedRect(root, 3)
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
        u.hpGhost = mkFrame(hp, 5)
        u.hpGhost.BackgroundTransparency = 0
        u.hpGhost.BackgroundColor3 = WHITE
        u.hpGhost.AnchorPoint = Vector2.new(0, 1)
        u.hpGhost.Position = UDim2.fromScale(0, 1)
        u.hpGhost.Visible = false
        u.hpFill = mkFrame(hp, 6)
        u.hpFill.BackgroundTransparency = 0
        u.hpFill.BackgroundColor3 = WHITE
        u.hpFill.AnchorPoint = Vector2.new(0, 1)
        u.hpFill.Position = UDim2.fromScale(0, 1)
        u.hpFill.Size = UDim2.fromScale(1, 1)
        u.hpNum = mkLabel(root, 7, Enum.TextXAlignment.Right)
        u.hpNum.AnchorPoint = Vector2.new(1, 0)
        u.hpNum.Position = UDim2.new(0, -HP_GAP - HP_W - 3, 0, 0)
        u.hpNum.Visible = false
        local head = mkList(root, 7, 2, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Bottom)
        head.AnchorPoint = Vector2.new(0.5, 1)
        head.Position = UDim2.new(0.5, 0, 0, -PAD)
        head.Visible = false
        u.head = head
        u.name = mkLabel(head, 8)
        u.name.LayoutOrder = 1
        u.under = mkFrame(head, 8)
        u.under.LayoutOrder = 2
        u.under.BackgroundTransparency = 0
        u.under.BackgroundColor3 = WHITE
        u.under.Size = UDim2.fromOffset(0, 2)
        u.under.Visible = false
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
        u.tracer  = mkFrame(a, 2); u.tracer.AnchorPoint = Vector2.new(0.5, 0.5)
        u.tracer.BackgroundTransparency = 0; u.tracer.BackgroundColor3 = WHITE; u.tracer.Visible = false
        u.dot     = mkFrame(a, 3); u.dot.AnchorPoint = Vector2.new(0.5, 0.5)
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
    local function ensureCham(o, char)
        local hl = o.cham
        if hl == nil then
            hl = Instance.new("Highlight")
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Enabled   = false
            hl.Parent    = char
            o.cham = hl
        elseif hl and hl.Parent ~= char then
            pcall(function() hl.Parent = char end)
        end
        return o.cham
    end
    local function cleanESP(p)
        local o = State.ESPObjects[p]; if not o then return end
        destroyTree(o)
        if o.cham and o.cham.Parent then pcall(function() o.cham:Destroy() end) end
        _bboxCache[p]  = nil
        _bboxFrameN[p] = nil
        State.ESPObjects[p] = nil
    end
    local function buildESP(player)
        if player == lp then return end
        cleanESP(player)
        local char = player.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local hum  = char:FindFirstChildOfClass("Humanoid")
        local isR6 = (hum and hum.RigType == Enum.HumanoidRigType.R6) or (char:FindFirstChild("Torso") ~= nil)
        local rig  = isR6 and SKEL_R6 or SKEL_R15
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
        local sp = cam:WorldToViewportPoint(pivot)
        local depth = sp.Z
        if depth <= 0.5 then return nil end
        local vpY = _ctx.vp and _ctx.vp.Y or 1080
        local tanHalf = math.tan(math.rad(cam.FieldOfView) * 0.5)
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
    local function hideAll(o, force)
        if o._allHidden and not force then return end
        o._allHidden = true
        hideTree(o)
        if o.cham then o.cham.Enabled = false end
    end
    function ESP.rebuildAll()
        for p in pairs(State.ESPObjects) do cleanESP(p) end
        if not Config.ESP then return end
        for _, p in ipairs(getSafePlayers()) do
            if p ~= lp and p.Character then buildESP(p) end
        end
    end
    local function renderPlayer(player, o)
        local ctx  = _ctx
        local char = player.Character
        if not char or not o.root or not o.root.Parent then cleanESP(player); return end
        if not o.root:IsA("BasePart") then cleanESP(player); return end
        local rootPos = o.root.Position
        if not rootPos then cleanESP(player); return end
        if not o.ui then o.ui = buildTree(o); if not o.ui then return end end
        local u = o.ui
        local vp     = ctx.vp
        local myRoot = ctx.myRoot
        local dist   = (myRoot and myRoot.Position and rootPos)
            and (myRoot.Position - rootPos).Magnitude or 0
        local oor = dist > Config.ESPMaxDistance
        if (Config.ESPTeamCheck and isTeammate(player)) or (not isAlive(player)) then
            hideAll(o); return
        end
        if oor then
            if o.cham then o.cham.Enabled = false end
            hideTree(o); o._allHidden = true
            return
        end
        if o._allHidden and Config.ESPFadeIn then o._fadeT = ctx.now end
        o._allHidden = false
        local fade = 1
        if Config.ESPFadeIn and o._fadeT then
            fade = math.clamp((ctx.now - o._fadeT) / 0.12, 0, 1)
        end
        ctx.fade = fade
        ctx.dmul = distMul(dist)
        local minX, minY, maxX, maxY = bbox(char, player)
        if not minX then
            hideTree(o)
        else
            local w, h = maxX - minX, maxY - minY
            u.root.Position = UDim2.fromOffset(minX, minY)
            u.root.Size     = UDim2.fromOffset(w, h)
            u.root.Visible  = true
            local hp, mh, frac
            pcall(function() hp, mh = getHealth(player) end)
            if hp ~= nil then frac = math.clamp((mh or 0) > 0 and hp / mh or 0, 0, 1) end
            local style = Config.ESPBoxStyle or "Full Box"
            local corners = Config.ESPBoxBrackets or (style == "Corner Brackets")
            if Config.ESPBox and not corners then
                u.box.Visible = true
                paintBoxLocal(u, ctx)
            elseif Config.ESPBox then
                u.box.Visible = false
            else
                u.box.Visible = false
                for i = 1, 8 do u.corners[i].Visible = false end
            end
            if Config.ESPHealth then
                u.hp.Visible = true
                u.hpFill.Size = UDim2.new(1, 0, math.clamp(frac or 1, 0, 1), 0)
                u.hpFill.BackgroundColor3 = healthColor(frac or 1)
                u.hpFill.BackgroundTransparency = Config.ESPHealthTransparency or 0
            else
                u.hp.Visible = false
            end
            if Config.ESPName then
                u.head.Visible = true
                u.name.Visible = true
                styleLabel(u.name, ctx.face, sizeFor(Config.ESPTextSize or 14, ctx.dmul), ctx.casing)
                u.name.Text = (Config.ESPNameMode == "Username") and player.Name or player.DisplayName
                u.name.TextColor3 = Config.ESPNameColor
                u.name.TextTransparency = 1 - fade
            else
                u.head.Visible = false
            end
            if Config.ESPDistance or Config.ESPWeapon then
                u.foot.Visible = true
                u.info.Visible = true
                styleLabel(u.info, ctx.face, sizeFor(Config.ESPInfoTextSize or 12, ctx.dmul), ctx.casing)
                local txt
                if Config.ESPWeapon then txt = getWeaponName(player) end
                if Config.ESPDistance then
                    local d = ("%dm"):format(dist)
                    txt = txt and (txt .. " " .. GLYPH_MID .. " " .. d) or d
                end
                u.info.Text = txt or ""
                u.info.TextColor3 = Config.ESPInfoColor
                u.info.TextTransparency = 1 - fade
            else
                u.foot.Visible = false
            end
        end
        if Config.ESPChams then
            local hl = ensureCham(o, char)
            if hl then
                hl.FillColor = Config.ESPChamsFillColor
                hl.OutlineColor = Config.ESPChamsOutlineColor
                hl.FillTransparency = Config.ESPChamsFillTransparency
                hl.OutlineTransparency = Config.ESPChamsOutlineTransparency
                hl.Enabled = true
            end
        elseif o.cham then o.cham.Enabled = false end
    end
    local function paintBoxLocal(u, ctx)
        local bt = math.floor(math.clamp(Config.ESPBoxThickness or 1, 1, 4))
        u.boxStroke.Color = Config.ESPBoxColor
        u.boxStroke.Thickness = bt
        u.caseOut.Thickness = 1
        u.caseIn.Thickness = 1
    end
    local function render()
        local _now = tick()
        local _dt  = _now - _lastRenderT
        if _now - _lastRenderT < 0.0083 then return end
        _lastRenderT = _now
        _espFrame = _espFrame + 1
        if not Config.ESP then
            for _, o in pairs(State.ESPObjects) do hideAll(o, true) end
            return
        end
        local ctx = _ctx
        ctx.vp     = cam.ViewportSize
        ctx.myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        ctx.dt     = math.clamp(_dt, 0, 0.1)
        ctx.now    = _now
        ctx.face   = faceFor(Config.ESPFont or "Code")
        local ts = (ctx.vp.Y / BASE_H) * (Config.ESPTextScale or 1)
        ctx.tsName = typePx(Config.ESPTextSize or 14, ts)
        ctx.tsInfo = typePx(Config.ESPInfoTextSize or 12, ts)
        ctx.tsHp   = typePx(Config.ESPHealthTextSize or 11, ts)
        ctx.casing = math.floor(math.clamp(Config.ESPTextCasing or 1, 0, 4))
        for player, o in pairs(State.ESPObjects) do
            pcall(renderPlayer, player, o)
        end
    end
    function ESP.init()
        for _, p in ipairs(getSafePlayers()) do
            if p ~= lp then
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
    function ESP.enable()
        Config.ESP = true; ESP.rebuildAll()
        if not _renderConn then _renderConn = RunService.RenderStepped:Connect(render) end
    end
    function ESP.disable()
        Config.ESP = false; ESP.rebuildAll()
        if _renderConn then _renderConn:Disconnect(); _renderConn = nil end
    end
    function ESP.unload()
        if _renderConn then _renderConn:Disconnect(); _renderConn = nil end
        for p in pairs(State.ESPObjects) do cleanESP(p) end
        if _gui then pcall(function() _gui:Destroy() end); _gui = nil; _absLayer = nil end
    end
end)()

-- 初始化核心
pcall(Rage.init)
pcall(Aimbot.init)
pcall(Trigger.init)
pcall(ESP.init)
if Config.ESP then pcall(ESP.enable) end

-- ============================================================
-- GUI（Linoria）
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
    Rage      = Window:AddTab('狂暴'),
    ESP       = Window:AddTab('透視'),
    Settings  = Window:AddTab('設定'),
}
local Options = Library.Options or {}
local Toggles = Library.Toggles or {}
Library.Options = Options
Library.Toggles = Toggles

-- 戰鬥分頁
do
    local L = Tabs.Combat:AddLeftGroupbox('靜默自瞄')
    L:AddToggle('SilentAim', { Text='啟用靜默自瞄', Default=Config.SilentAim,
        Callback=function(v) Config.SilentAim = v end })
        :AddKeyPicker('SilentAimKey', { Default='None', Mode='Toggle', SyncToggleState=true, Text='靜默自瞄' })
    L:AddToggle('SilentAimVisCheck', { Text='可見性檢測', Default=Config.SilentAimVisCheck,
        Callback=function(v) Config.SilentAimVisCheck = v end })
    L:AddSlider('SilentAimFOV', { Text='視野半徑', Default=Config.SilentAimFOV,
        Min=20, Max=2000, Rounding=0, Callback=function(v) Config.SilentAimFOV = v end })
    L:AddDropdown('SilentAimTargetPart', { Values={'Head','Torso','Closest'},
        Default=Config.SilentAimTargetPart, Text='目標骨骼',
        Callback=function(v) Config.SilentAimTargetPart = v end })
    L:AddSlider('SilentAimStickiness', { Text='黏著度', Default=Config.SilentAimStickiness,
        Min=0, Max=0.5, Rounding=2, Callback=function(v) Config.SilentAimStickiness = v end })

    local R = Tabs.Combat:AddRightGroupbox('自瞄')
    R:AddToggle('Aimbot', { Text='啟用自瞄', Default=Config.Aimbot,
        Callback=function(v) if v then Aimbot.enable() else Aimbot.disable() end end })
    R:AddDropdown('AimbotKey', {
        Values={'Always','MB2','MB1','C','E','F','Q','V','X','LeftShift','LeftAlt','LeftControl'},
        Default=Config.AimbotKey, Text='啟動方式',
        Callback=function(v) Config.AimbotKey = v end })
    R:AddSlider('AimbotSmoothness', { Text='平滑度 (0 = 硬鎖)', Default=Config.AimbotSmoothness,
        Min=0, Max=100, Rounding=0, Callback=function(v) Config.AimbotSmoothness = v end })
    R:AddSlider('AimbotFOVDeg', { Text='視野 (度)', Default=Config.AimbotFOVDeg,
        Min=1, Max=180, Rounding=1, Callback=function(v) Config.AimbotFOVDeg = v end })
    R:AddDropdown('AimbotTargetPart', { Values={'Best','Head','Torso','Closest'},
        Default=Config.AimbotTargetPart, Text='目標骨骼',
        Callback=function(v) Config.AimbotTargetPart = v end })
    R:AddToggle('AimbotVisCheck', { Text='可見性檢測', Default=Config.AimbotVisCheck,
        Callback=function(v) Config.AimbotVisCheck = v end })

    local TB = Tabs.Combat:AddRightGroupbox('觸發機器人')
    TB:AddToggle('Trigger', { Text='啟用觸發', Default=Config.Trigger,
        Callback=function(v) if v then Trigger.enable() else Trigger.disable() end end })
    TB:AddDropdown('TriggerKey', {
        Values={'Always','MB2','MB1','C','E','F','Q','V','X','LeftShift','LeftAlt','LeftControl'},
        Default=Config.TriggerKey, Text='啟動方式',
        Callback=function(v) Config.TriggerKey = v end })

    local AA = Tabs.Combat:AddRightGroupbox('反瞄準')
    AA:AddToggle('AntiAimEnabled', { Text='啟用反瞄準', Default=Config.AntiAimEnabled,
        Callback=function(v) Config.AntiAimEnabled = v end })
    AA:AddDropdown('AntiAimYaw', { Values={'none','jitter','spinbot','random'},
        Default=Config.AntiAimYaw, Text='偏航 (水平)',
        Callback=function(v) Config.AntiAimYaw = v end })
    AA:AddDropdown('AntiAimPitch', { Values={'none','jitter','spinbot','random'},
        Default=Config.AntiAimPitch, Text='俯仰 (垂直)',
        Callback=function(v) Config.AntiAimPitch = v end })
    AA:AddDropdown('AntiAimAngle', { Values={'none','tilt 45','tilt 90','upside down','custom'},
        Default=Config.AntiAimAngle, Text='傾斜',
        Callback=function(v) Config.AntiAimAngle = v end })
    AA:AddSlider('AntiAimMaxAngle', { Text='最大角度', Default=Config.AntiAimMaxAngle,
        Min=1, Max=180, Rounding=1, Callback=function(v) Config.AntiAimMaxAngle = v end })
end

-- 狂暴分頁
do
    local LTB = Tabs.Rage:AddLeftTabbox('核心')
    local CORE = LTB:AddTab('核心')
    CORE:AddToggle('Rage', { Text='啟用狂暴', Default=Config.Rage,
        Callback=function(v) if v then Rage.enable() else Rage.disable() end end })
        :AddKeyPicker('RageToggleKey', { Default='None', Mode='Toggle', SyncToggleState=true, Text='狂暴' })
    CORE:AddDivider('鎖定')
    CORE:AddToggle('RageSkipImmune', { Text='對無敵目標停火', Default=Config.RageSkipImmune,
        Callback=function(v) Config.RageSkipImmune = v end })
    CORE:AddToggle('RageHPPriority', { Text='優先低血量目標', Default=Config.RageHPPriority,
        Callback=function(v) Config.RageHPPriority = v end })
    CORE:AddDivider('引擎')
    CORE:AddDropdown('RageGumMode', { Values={'off','lite','on'},
        Default=Config.RageGumMode, Text='口香糖模式',
        Callback=function(v) Config.RageGumMode = v end })
    CORE:AddDropdown('RageVoidDepth', { Values={'shallow','deep'},
        Default=Config.RageVoidDepth, Text='躲藏深度',
        Callback=function(v) Config.RageVoidDepth = v end })
    CORE:AddToggle('RageGatePoison', { Text='閘門毒餌', Default=Config.RageGatePoison,
        Callback=function(v) Config.RageGatePoison = v end })
    CORE:AddToggle('RagePredictPrefire', { Text='預測重新出現 (預開火)', Default=Config.RagePredictPrefire,
        Callback=function(v) Config.RagePredictPrefire = v end })
    CORE:AddDivider('誘餌脈衝')
    CORE:AddToggle('RageAttackTranslocate', { Text='啟用誘餌脈衝', Default=Config.RageAttackTranslocate,
        Callback=function(v) Config.RageAttackTranslocate = v end })
    CORE:AddSlider('RageBaitHeldMs', { Text='持續時間 (毫秒)', Default=Config.RageBaitHeldMs,
        Min=0, Max=1000, Rounding=0, Callback=function(v) Config.RageBaitHeldMs = math.floor(v) end })
    CORE:AddDropdown('RageRestoreMode', { Values={'auto','none','render','kerp'},
        Default=Config.RageRestoreMode, Text='傳送模式',
        Callback=function(v) Config.RageRestoreMode = v end })

    local WEP = Tabs.Rage:AddRightGroupbox('武器')
    WEP:AddDropdown('RageOnEmpty', { Values={'Swap','Reload'},
        Default=Config.RageOnEmpty, Text='彈藥耗盡時',
        Callback=function(v) Config.RageOnEmpty = v end })
    WEP:AddDropdown('RagePreferredSlot', { Values={'Primary','Secondary','Melee'},
        Default=Config.RagePreferredSlot, Text='偏好欄位',
        Callback=function(v) Config.RagePreferredSlot = v end })

    local MELEE = Tabs.Rage:AddRightGroupbox('近戰')
    MELEE:AddToggle('RageKnifeBot', { Text='小刀機器人', Default=Config.RageKnifeBot,
        Callback=function(v) Config.RageKnifeBot = v end })
    MELEE:AddToggle('RageShieldBackstab', { Text='防暴盾繞後', Default=Config.RageShieldBackstab,
        Callback=function(v) Config.RageShieldBackstab = v end })
    MELEE:AddToggle('RageKnifeBackstab', { Text='強制小刀背刺', Default=Config.RageKnifeBackstab,
        Callback=function(v) Config.RageKnifeBackstab = v end })
end

-- 透視分頁
do
    local L = Tabs.ESP:AddLeftGroupbox('透視 & 方框')
    L:AddToggle('ESP', { Text='啟用透視', Default=Config.ESP,
        Callback=function(v) if v then ESP.enable() else ESP.disable() end end })
        :AddKeyPicker('ESPToggleKey', { Default='None', Mode='Toggle', SyncToggleState=true, Text='透視' })
    L:AddToggle('ESPTeamCheck', { Text='隊伍檢測', Default=(Config.ESPTeamCheck ~= false),
        Callback=function(v) Config.ESPTeamCheck = v end })
    L:AddToggle('ESPBox', { Text='方框', Default=(Config.ESPBox ~= false),
        Callback=function(v) Config.ESPBox = v end })
    L:AddDropdown('ESPBoxStyle', { Values={'Full Box','Corner Brackets'}, Default=Config.ESPBoxStyle,
        Text='方框樣式', Callback=function(v) Config.ESPBoxStyle = v end })
    L:AddSlider('ESPBoxThickness', { Text='方框粗細', Default=Config.ESPBoxThickness,
        Min=1, Max=4, Rounding=0, Callback=function(v) Config.ESPBoxThickness = math.floor(v) end })
    L:AddSlider('ESPBoxScale', { Text='方框大小', Default=Config.ESPBoxScale,
        Min=0.6, Max=1.6, Rounding=2, Callback=function(v) Config.ESPBoxScale = v end })
    L:AddToggle('ESPHealth', { Text='血條', Default=(Config.ESPHealth ~= false),
        Callback=function(v) Config.ESPHealth = v end })
    L:AddDropdown('ESPHealthNumberMode', { Values={'Off','OnDamage','Always'},
        Default=Config.ESPHealthNumberMode, Text='血量數值',
        Callback=function(v) Config.ESPHealthNumberMode = v end })

    local R = Tabs.ESP:AddRightGroupbox('文字與旗標')
    R:AddToggle('ESPName', { Text='玩家名字', Default=(Config.ESPName ~= false),
        Callback=function(v) Config.ESPName = v end })
    R:AddDropdown('ESPNameMode', { Values={'Display','Username'}, Default=Config.ESPNameMode,
        Text='名字來源', Callback=function(v) Config.ESPNameMode = v end })
    R:AddToggle('ESPDistance', { Text='距離', Default=(Config.ESPDistance ~= false),
        Callback=function(v) Config.ESPDistance = v end })
    R:AddToggle('ESPWeapon', { Text='持有武器', Default=Config.ESPWeapon,
        Callback=function(v) Config.ESPWeapon = v end })
    R:AddSlider('ESPTextSize', { Text='名字大小', Default=Config.ESPTextSize,
        Min=9, Max=24, Rounding=0, Callback=function(v) Config.ESPTextSize = math.floor(v) end })
    R:AddToggle('ESPChams', { Text='玩家材質', Default=Config.ESPChams,
        Callback=function(v) Config.ESPChams = v end })
    R:AddSlider('ESPMaxDistance', { Text='最大距離', Default=Config.ESPMaxDistance,
        Min=50, Max=3000, Rounding=0, Callback=function(v) Config.ESPMaxDistance = math.floor(v) end })
end

-- 設定分頁
do
    local L = Tabs.Settings:AddLeftGroupbox('選單')
    L:AddDropdown('GUIToggleKey', {
        Values = {'RightShift','LeftShift','RightControl','LeftControl','RightAlt','LeftAlt',
                  'F1','F2','F3','F4','F5','F6','F7','F8','F9','F10','F11','F12',
                  'Insert','Delete','Home','End','PageUp','PageDown','CapsLock','Tab'},
        Default = Config.GUIToggleKey,
        Text = '介面開關鍵',
        Callback = function(v) Config.GUIToggleKey = v end
    })
    L:AddButton({ Text = '卸載腳本 (需雙擊)', DoubleClick = true, Func = function()
        pcall(function() ESP.unload() end)
        pcall(function() Aimbot.unload() end)
        pcall(function() Trigger.unload() end)
        pcall(function() Rage.unload() end)
        Library:Unload()
        _G["\76\72"] = nil
    end })
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local key = Config.GUIToggleKey
        if key and Enum.KeyCode[key] and input.KeyCode == Enum.KeyCode[key] then
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

Library:Notify('v12.0 第一段載入完成', 4)
_G["\76\72"] = Library
print("[v12.0] 第一段完整載入完成")
-- ============================================================
-- LuaHook v12.0 — 第二段
-- 介面 + 視覺 + 雜項
-- ============================================================

-- 新增分頁
local HUDTab    = Window:AddTab('介面')
local VisualsTab = Window:AddTab('視覺')
local MiscTab   = Window:AddTab('雜項')

-- 補上設定（避免 nil）
Config.FXHitMarker = true
Config.FXHitMarkerColor = Color3.fromRGB(255, 255, 255)
Config.FXHitMarkerCritColor = Color3.fromRGB(255, 194, 75)
Config.FXHitMarkerLethalColor = Color3.fromRGB(255, 64, 78)
Config.FXHitMarkerGap = 5
Config.FXHitMarkerLen = 8
Config.FXHitMarkerThickness = 2
Config.FXHitMarkerStyle = "X"
Config.FXDamageNumbers = true
Config.FXDamageAccumWindow = 0.9
Config.FXKillBanner = true
Config.FXKillBannerColor = Color3.fromRGB(255, 194, 75)
Config.FXKillFeed = true
Config.FXHeadshotSpark = true
Config.FXHitFlash = true
Config.FXDamageDirection = true
Config.FXLowHPVignette = true
Config.FXLowHPThreshold = 0.35
Config.FXCritDamage = 30
Config.FXBeamTracer = false
Config.FXBeamStyle = "Glow"
Config.FXBeamHitColor = Color3.fromRGB(255, 194, 75)
Config.FXBeamWidth0 = 0.18
Config.FXBeamWidth1 = 0.04
Config.FXBeamDur = 0.55
Config.FXBeamGlowLight = true
Config.FXBeamTravel = true
Config.FXBeamTravelSpeed = 1400
Config.FXBeamImpact = true
Config.FXWorldSpark = false
Config.FXWorldSparkBloom = true
Config.FXKillPillar = false
Config.FXKillPillarColor = Color3.fromRGB(255, 194, 75)
Config.FXKillShards = false
Config.FXKillShardsColor = Color3.fromRGB(155, 232, 255)
Config.FXKillPulse = false
Config.FXKillPulseAmount = 0.6
Config.FXFovRing = false
Config.FXFovColorA = Color3.fromRGB(53, 215, 199)
Config.FXFovColorB = Color3.fromRGB(255, 194, 75)
Config.FXFovThickness = 1.5
Config.FXFovCasing = true
Config.FXFovFill = false
Config.FXFovRotate = true
Config.FXFovDriftSpeed = 0.15
Config.FXCrosshair = false
Config.FXCrosshairStyle = "Cross"
Config.FXCrosshairColor = Color3.fromRGB(243, 246, 250)
Config.FXCrosshairDot = true
Config.FXCrosshairGap = 4
Config.FXCrosshairLen = 7
Config.FXCrosshairThickness = 2
Config.FXCrosshairOutline = true
Config.FXCrosshairHitPop = true
Config.FXCrosshairAngle = 0
Config.FXCrosshairSpin = false
Config.FXCrosshairSpinSpeed = 1.0
Config.FXCrosshairSniper = false
Config.FXCrosshairBounce = false
Config.FXCrosshairBounceAmt = 4
Config.FXCrosshairBloom = false
Config.HUDWatermark = true
Config.HUDWatermarkStats = true
Config.HUDCompass = false
Config.HUDCompassWidth = 380
Config.HUDCompassPips = true
Config.HUDThreatArc = false
Config.HUDRangeReadout = false
Config.FXTargetInfo = false
Config.FXTargetInfoOffset = 110
Config.HUDBindList = false
Config.HUDBindListSide = "Left"
Config.Visuals = false
Config.VisualsPreset = "Neutral"
Config.VisualsPerformanceMode = false
Config.VisualsFullbright = false
Config.VisualsNoFog = false
Config.VisualsHolograms = false
Config.VisualsRainbowMap = false
Config.VisualsRainbowMapSpeed = 0.15
Config.VisualsStretch = 1.0
Config.VisualsStretchMin = 0.5
Config.VisualsStretchMax = 1.2
Config.VisualsCameraSway = false
Config.VisualsCameraSwayAmount = 0.5
Config.VisualsHologramDuration = 3.5
Config.VisualsHologramRange = 300
Config.VisualsHologramVisibility = 1.4
Config.VisualsHologramColor = Color3.fromRGB(0, 220, 255)
Config.VisualsHologramAccent = Color3.fromRGB(255, 60, 200)
Config.VisualsGrade = "Crisp"
Config.VisualsGradeStrength = 0.6
Config.VisualsBloom = false
Config.VisualsBloomIntensity = 1.0
Config.VisualsVignette = false
Config.VisualsVignetteStrength = 0.6
Config.VisualsLetterbox = false
Config.VisualsLetterboxSize = 0.10
Config.VisualsDOF = false
Config.VisualsDOFDistance = 28
Config.VisualsDOFBlur = 0.5
Config.VisualsHologramStyle = "Orb"
Config.VisualsHologramLethal = true
Config.VisualsHologramLethalColor = Color3.fromRGB(255, 200, 60)
Config.Weather = false
Config.WeatherType = "Rain"
Config.WeatherIntensity = 1.0
Config.WeatherMeteors = false
Config.WeatherMeteorRate = 1.0
Config.WeatherStarRate = 1.0
Config.WeatherClockDial = false
Config.WeatherClockCycleMin = 8
Config.WeatherStorm = false
Config.WeatherStormFlash = true
Config.WeatherStormMin = 4
Config.WeatherStormVar = 8
Config.WeatherThunderId = "rbxassetid://9113169432"
Config.WeatherSoundIds = {
    rain  = "rbxassetid://9112858162",
    wind  = "rbxassetid://9112854440",
    fire  = "rbxassetid://2787093357",
    night = "rbxassetid://9112764573",
    birds = "rbxassetid://9112749254",
}
Config.WeatherSoundVolume = 0.35
Config.WeatherMood = true
Config.SkyboxPreset = "Off"
Config.SkyboxHideCelestial = false
Config.WeatherGodRays = false
Config.WeatherRainbow = false
Config.WeatherShootingStars = false
Config.WeatherPuddles = false
Config.GameVisuals = false
Config.GVUnlockAll = true
Config.GVUnlockWeapons = false
Config.GVWrapInverted = false
Config.GVEveryone = false
Config.GVBirthHook = true
Config.GVFinisherClone = true
Config.GVRemember = true
Config.GVRankCharmOn = false
Config.GVRankCharmRank = ""
Config.GVRankCharmLb = 0
Config.GVEmotes = false
Config.SpooferNameEnabled = false
Config.SpooferName = "ProPlayer"
Config.SpooferDisplayName = "ProPlayer"
Config.SpooferLevelEnabled = false
Config.SpooferLevel = 100
Config.SpooferCasualWinsEnabled = false
Config.SpooferCasualWins = 500
Config.SpooferRankedWinsEnabled = false
Config.SpooferRankedWins = 250
Config.SpooferRankedEloEnabled = false
Config.SpooferRankedElo = 2400
Config.SpooferWinPercentEnabled = false
Config.SpooferWinPercent = 75
Config.SpooferWinStreakEnabled = false
Config.SpooferWinStreak = 25
Config.SpooferFavoriteMapEnabled = false
Config.SpooferFavoriteMap = "Arena"
Config.VMOffsetEnabled = false
Config.VMOffsetX = 0
Config.VMOffsetY = 0
Config.VMOffsetZ = 0
Config.VMOffsetPitch = 0
Config.VMOffsetYaw = 0
Config.VMOffsetRoll = 0
Config.VMChamsEnabled = false
Config.VMChamsMaterial = "ForceField"
Config.VMChamsColor = Color3.fromRGB(53, 215, 199)
Config.VMChamsTransparency = 0.5
Config.VMDisableTextures = false
Config.CameraAspectRatioEnabled = false
Config.CameraAspectRatioX = 4
Config.CameraAspectRatioY = 3
Config.CameraFovOverride = false
Config.CameraFovAmount = 90
Config.ThirdPersonEnabled = false
Config.ThirdPersonDistance = 12
Config.AutoQueue = false
Config.AutoQueueMode = "1v1"
Config.AutoCollectDrops = false
Config.CollectHealth = true
Config.CollectAmmo = true

-- ============================================================
-- 命中回饋與追蹤線系統（從 Linoria FX 精簡移植）
-- ============================================================
local FXSys = {}
do
    local hasDrawing = false
    local SoundService = game:GetService("SoundService")
    local C_GREY   = Color3.fromRGB(200, 200, 200)
    local C_AMBER  = Color3.fromRGB(255, 170, 60)
    local C_ORANGE = Color3.fromRGB(255, 120, 30)
    local C_RED    = Color3.fromRGB(255, 59, 78)
    local C_SCREENRED = Color3.fromRGB(194, 30, 47)
    local C_BLACK  = Color3.new(0, 0, 0)
    local C_GOLD   = Color3.fromRGB(255, 194, 75)
    local WHITE    = Color3.new(1, 1, 1)
    local _started, _alloc = false, false
    local _updConn, _gui = nil, nil
    local _hmLines, _hmLinesBlk = nil, nil
    local _hm = { on = false, t0 = 0, pop = 0, color = WHITE }
    local _snds, _sndIdx, _sndLastT = nil, 1, 0
    local _dnPool, _dnActive, _dnByPlr = nil, {}, {}
    local _kbL1, _kbL2, _kbRing = nil, nil, nil
    local _kb = { on = false, t0 = 0, streak = 0, lastKillT = 0, line1 = "", line2 = "" }
    local _kfPool, _kfItems = nil, {}
    local _hsLines, _hsLinesBlk = nil, nil
    local _hs = { on = false, t0 = 0, pos = nil }
    local _flashFrame = nil
    local _hf = { on = false, t0 = 0 }
    local _vgFrames = nil
    local _vgHP, _vgLastPoll = 1, 0
    local _hcConn, _charConn, _lastHP = nil, nil, nil
    local _fovA, _fovB, _fovFill, _fovCas = nil, nil, nil, nil
    local _fxLastT = nil
    local _fxThrT  = 0
    local _hmRing, _hmRingBlk = nil, nil
    local _chLines, _chLinesBlk, _chDot, _chDotBlk = nil, nil, nil, nil
    local _ch2 = { shots = 0, shotT = -10, rot = 0, rotTgt = 0 }
    local _wmBg, _wmAccent, _wmText = nil, nil, nil
    local _wm = { fps = 60, ping = 0, pingT = 0, str = "", strT = 0, bw = nil, pw = 60 }
    local _sessKills, _sessT0 = 0, tick()
    local _tiBg, _tiAccent, _tiName, _tiHpBg, _tiHpFill, _tiInfo = nil, nil, nil, nil, nil, nil
    local _ti = { tgt = nil, a = 0, hp = nil, frac = 1, pollT = 0, name = nil, info = "" }
    local _kfTicks = nil

    local function ensureGui()
        if _gui and _gui.Parent then return _gui end
        local g = Instance.new("ScreenGui")
        g.Name = "_vs_fx"
        g.IgnoreGuiInset = true
        g.ResetOnSpawn = false
        g.DisplayOrder = 999
        local ok = pcall(function() g.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
        if not ok or not g.Parent then
            pcall(function() g.Parent = lp:FindFirstChildOfClass("PlayerGui") end)
        end
        _gui = g
        return g
    end

    local function allocate()
        if _alloc then return end
        _alloc = true
        local g = ensureGui()
        local fr = Instance.new("Frame")
        fr.Name = "_fl"; fr.BackgroundColor3 = C_SCREENRED; fr.BackgroundTransparency = 1
        fr.BorderSizePixel = 0; fr.Size = UDim2.new(1, 0, 1, 0); fr.Visible = false
        fr.ZIndex = 1; fr.Parent = g
        _flashFrame = fr
        _vgFrames = {}
        local SIDES = {
            { size = UDim2.new(1, 0, 0.16, 0),  pos = UDim2.new(0, 0, 0, 0),     rot = 90  },
            { size = UDim2.new(1, 0, 0.16, 0),  pos = UDim2.new(0, 0, 0.84, 0),  rot = 270 },
            { size = UDim2.new(0.12, 0, 1, 0),  pos = UDim2.new(0, 0, 0, 0),     rot = 0   },
            { size = UDim2.new(0.12, 0, 1, 0),  pos = UDim2.new(0.88, 0, 0, 0),  rot = 180 },
        }
        for i, s in ipairs(SIDES) do
            local f = Instance.new("Frame")
            f.Name = "_vg" .. i; f.BackgroundColor3 = C_SCREENRED; f.BackgroundTransparency = 1
            f.BorderSizePixel = 0; f.Size = s.size; f.Position = s.pos; f.Visible = false
            f.ZIndex = 2
            local grad = Instance.new("UIGradient")
            grad.Rotation = s.rot
            grad.Transparency = NumberSequence.new(0, 1)
            grad.Parent = f
            f.Parent = g
            _vgFrames[i] = f
        end
        _hmLinesBlk = {}
        for i = 1, 4 do
            local l = Instance.new("Frame")
            l.BackgroundColor3 = C_BLACK; l.BorderSizePixel = 0
            l.AnchorPoint = Vector2.new(0.5, 0.5); l.Visible = false
            l.Parent = g
            _hmLinesBlk[i] = l
        end
        _hmLines = {}
        for i = 1, 4 do
            local l = Instance.new("Frame")
            l.BackgroundColor3 = WHITE; l.BorderSizePixel = 0
            l.AnchorPoint = Vector2.new(0.5, 0.5); l.Visible = false
            l.Parent = g
            _hmLines[i] = l
        end
        _dnPool = {}
        for i = 1, 24 do
            local t = Instance.new("TextLabel")
            t.BackgroundTransparency = 1
            t.TextColor3 = WHITE
            t.Font = Enum.Font.Code
            t.TextSize = 14
            t.TextStrokeTransparency = 0
            t.TextStrokeColor3 = C_BLACK
            t.AnchorPoint = Vector2.new(0.5, 0.5)
            t.Text = ""
            t.Visible = false
            t.Size = UDim2.fromOffset(200, 20)
            t.Parent = g
            _dnPool[i] = t
        end
        _kbL1 = Instance.new("TextLabel")
        _kbL1.BackgroundTransparency = 1
        _kbL1.TextColor3 = WHITE
        _kbL1.Font = Enum.Font.Code
        _kbL1.TextSize = 12
        _kbL1.TextStrokeTransparency = 0
        _kbL1.TextStrokeColor3 = C_BLACK
        _kbL1.AnchorPoint = Vector2.new(0.5, 0.5)
        _kbL1.Text = ""
        _kbL1.Visible = false
        _kbL1.Size = UDim2.fromOffset(300, 20)
        _kbL1.Parent = g
        _kbL2 = Instance.new("TextLabel")
        _kbL2.BackgroundTransparency = 1
        _kbL2.TextColor3 = C_GOLD
        _kbL2.Font = Enum.Font.Code
        _kbL2.TextSize = 22
        _kbL2.TextStrokeTransparency = 0
        _kbL2.TextStrokeColor3 = C_BLACK
        _kbL2.AnchorPoint = Vector2.new(0.5, 0.5)
        _kbL2.Text = ""
        _kbL2.Visible = false
        _kbL2.Size = UDim2.fromOffset(300, 30)
        _kbL2.Parent = g
        _kbRing = Instance.new("Frame")
        _kbRing.BackgroundTransparency = 1
        _kbRing.AnchorPoint = Vector2.new(0.5, 0.5)
        _kbRing.Position = UDim2.new(0.5, 0, 0.5, 0)
        _kbRing.Size = UDim2.fromOffset(40, 40)
        _kbRing.Visible = false
        _kbRing.Parent = g
        local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(1, 0); uc.Parent = _kbRing
        local ust = Instance.new("UIStroke"); ust.Thickness = 2; ust.Color = C_GOLD; ust.Parent = _kbRing
        _kfPool = {}
        for i = 1, 5 do
            local t = Instance.new("TextLabel")
            t.BackgroundTransparency = 1
            t.TextColor3 = WHITE
            t.Font = Enum.Font.Code
            t.TextSize = 13
            t.TextStrokeTransparency = 0
            t.TextStrokeColor3 = C_BLACK
            t.Text = ""
            t.TextXAlignment = Enum.TextXAlignment.Right
            t.AutomaticSize = Enum.AutomaticSize.X
            t.Size = UDim2.fromOffset(0, 18)
            t.Visible = false
            t.Parent = g
            _kfPool[i] = t
        end
        _hsLinesBlk = {}
        for i = 1, 6 do
            local l = Instance.new("Frame")
            l.BackgroundColor3 = C_BLACK; l.BorderSizePixel = 0
            l.AnchorPoint = Vector2.new(0.5, 0.5); l.Visible = false
            l.Parent = g
            _hsLinesBlk[i] = l
        end
        _hsLines = {}
        for i = 1, 6 do
            local l = Instance.new("Frame")
            l.BackgroundColor3 = C_GOLD; l.BorderSizePixel = 0
            l.AnchorPoint = Vector2.new(0.5, 0.5); l.Visible = false
            l.Parent = g
            _hsLines[i] = l
        end
        _wmBg = Instance.new("Frame")
        _wmBg.BackgroundColor3 = Color3.fromRGB(13, 18, 25)
        _wmBg.BorderSizePixel = 0
        _wmBg.Position = UDim2.fromOffset(16, 16)
        _wmBg.Size = UDim2.fromOffset(60, 24)
        _wmBg.Visible = false
        _wmBg.Parent = g
        _wmText = Instance.new("TextLabel")
        _wmText.BackgroundTransparency = 1
        _wmText.TextColor3 = WHITE
        _wmText.Font = Enum.Font.GothamBold
        _wmText.TextSize = 13
        _wmText.TextStrokeTransparency = 0.5
        _wmText.TextStrokeColor3 = C_BLACK
        _wmText.Text = "LuaHook"
        _wmText.TextXAlignment = Enum.TextXAlignment.Left
        _wmText.AutomaticSize = Enum.AutomaticSize.X
        _wmText.Size = UDim2.fromOffset(0, 18)
        _wmText.Position = UDim2.fromOffset(26, 19)
        _wmText.Visible = false
        _wmText.Parent = g
        _wm.stats = Instance.new("TextLabel")
        _wm.stats.BackgroundTransparency = 1
        _wm.stats.TextColor3 = Color3.fromRGB(174, 185, 197)
        _wm.stats.Font = Enum.Font.Code
        _wm.stats.TextSize = 12
        _wm.stats.TextStrokeTransparency = 0.5
        _wm.stats.TextStrokeColor3 = C_BLACK
        _wm.stats.Text = ""
        _wm.stats.TextXAlignment = Enum.TextXAlignment.Left
        _wm.stats.AutomaticSize = Enum.AutomaticSize.X
        _wm.stats.Size = UDim2.fromOffset(0, 18)
        _wm.stats.Position = UDim2.fromOffset(100, 22)
        _wm.stats.Visible = false
        _wm.stats.Parent = g
        _snds = {}
        for i = 1, 4 do
            local s = Instance.new("Sound")
            s.Name = "_fxs" .. i
            s.Volume = 0.5
            s.Parent = SoundService
            _snds[i] = s
        end
    end

    local function triggerHitMarker(crit, lethal)
        if not (_hmLines and _hmLines[1]) then return end
        local now = tick()
        if _hm.on and (now - _hm.t0) < 0.18 then
            _hm.pop = math.min(_hm.pop + 1, 3)
        else
            _hm.pop = 0
        end
        _hm.on = true; _hm.t0 = now
        _hm.color = (lethal and Config.FXHitMarkerLethalColor)
            or (crit and Config.FXHitMarkerCritColor)
            or Config.FXHitMarkerColor
    end

    local function dnFree(d)
        for _, e in ipairs(_dnActive) do if e.d == d then return false end end
        return true
    end
    local function pushDamageNumber(p, dmg, crit, lethal, hitPos)
        if not (_dnPool and hitPos) then return end
        local now = tick()
        local e = _dnByPlr[p]
        if e and e.alive and (now - e.lastT) <= Config.FXDamageAccumWindow then
            e.total = e.total + dmg
            e.t0 = now; e.lastT = now; e.popT = now; e.pos = hitPos
            e.crit = e.crit or crit; e.lethal = e.lethal or lethal
            return
        end
        local d
        for _, cand in ipairs(_dnPool) do
            if cand and dnFree(cand) then d = cand break end
        end
        if not d then return end
        e = { d = d, p = p, total = dmg, pos = hitPos, t0 = now, lastT = now, popT = now,
              drift = math.random(-8, 8), crit = crit, lethal = lethal, alive = true }
        _dnByPlr[p] = e
        table.insert(_dnActive, e)
    end

    local function trackText(s)
        return (s:gsub("(.)", "%1 ")):sub(1, -2)
    end
    local KB_STREAK = { [2] = "DOUBLE", [3] = "TRIPLE", [4] = "QUAD" }
    local function triggerKillBanner(p)
        if not (_kbL1 and _kbL2) then return end
        local now = tick()
        if (now - _kb.lastKillT) <= 4 then _kb.streak = _kb.streak + 1 else _kb.streak = 1 end
        _kb.lastKillT = now
        _kb.on = true; _kb.t0 = now
        local label = "ELIMINATED"
        if _kb.streak >= 5 then label = _kb.streak .. "x"
        elseif _kb.streak >= 2 then label = KB_STREAK[_kb.streak] end
        _kb.line1 = trackText(label)
        _kb.line2 = tostring(p.DisplayName or p.Name)
    end

    local function pushKillFeed(p, crit)
        if not _kfPool then return end
        table.insert(_kfItems, 1, { text = "You  ·  " .. tostring(p.DisplayName or p.Name), t0 = tick(), crit = crit and true or false })
        while #_kfItems > 5 do table.remove(_kfItems) end
    end

    local function triggerSpark(hitPos)
        if not (_hsLines and hitPos) then return end
        _hs.on = true; _hs.t0 = tick(); _hs.pos = hitPos
    end
    local function triggerFlash()
        if not _flashFrame then return end
        _hf.on = true; _hf.t0 = tick()
    end

    local function dnRamp(total)
        if total <= 25 then
            return C_GREY:Lerp(C_AMBER, math.clamp(total / 25, 0, 1))
        end
        return C_AMBER:Lerp(C_ORANGE, math.clamp((total - 25) / 25, 0, 1))
    end

    function FXSys.onHit(p, dmg, crit, lethal, hitPos)
        if not _started then return end
        if Config.FXHitMarker then triggerHitMarker(crit, lethal) end
        if dmg > 0 and Config.FXDamageNumbers then pushDamageNumber(p, dmg, crit, lethal, hitPos) end
        if crit and Config.FXHeadshotSpark then triggerSpark(hitPos) end
        if lethal then
            _sessKills = _sessKills + 1
            if Config.FXKillBanner then triggerKillBanner(p) end
            if Config.FXKillFeed then pushKillFeed(p, crit) end
        end
    end
    function FXSys.onIncoming(drop)
        if not _started then return end
        if Config.FXHitFlash then triggerFlash() end
    end

    local DIAG = { Vector2.new(1, 1), Vector2.new(-1, 1), Vector2.new(1, -1), Vector2.new(-1, -1) }
    local INV_SQ2 = 0.70710678
    local PLUS = { Vector2.new(0, -1), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(-1, 0) }

    local function hideMarker()
        _hm.on = false
        for _, l in ipairs(_hmLines) do if l then l.Visible = false end end
        if _hmLinesBlk then for _, l in ipairs(_hmLinesBlk) do if l then l.Visible = false end end end
        if _hmRing then _hmRing.Visible = false end
        if _hmRingBlk then _hmRingBlk.Visible = false end
    end

    local function update()
        local now = tick()
        if now - _fxThrT < 0.0083 then return end
        _fxThrT = now
        local dt = now - (_fxLastT or now)
        _fxLastT = now
        if dt > 0.1 then dt = 0.1 end
        local vp = Camera.ViewportSize
        local cx, cy = vp.X * 0.5, vp.Y * 0.5

        -- 命中標記
        if _hm.on and _hmLines then
            local a = now - _hm.t0
            if a >= 0.18 then
                hideMarker()
            else
                local style = Config.FXHitMarkerStyle or "X"
                local snap = math.clamp(a / 0.07, 0, 1)
                snap = 1 - (1 - snap) * (1 - snap)
                local gap = Config.FXHitMarkerGap or 5
                local len = (Config.FXHitMarkerLen or 8) * snap + _hm.pop
                local th  = Config.FXHitMarkerThickness or 2
                local tr  = 1 - math.clamp((a - 0.09) / 0.09, 0, 1)
                local plus = style == "Plus"
                for i, l in ipairs(_hmLines) do
                    if l then
                        local nx, ny
                        if plus then nx, ny = PLUS[i].X, PLUS[i].Y
                        else nx, ny = DIAG[i].X * INV_SQ2, DIAG[i].Y * INV_SQ2 end
                        local from = Vector2.new(cx + nx * gap, cy + ny * gap)
                        local to   = Vector2.new(cx + nx * (gap + len), cy + ny * (gap + len))
                        local w = math.abs(to.X - from.X)
                        local h = math.abs(to.Y - from.Y)
                        l.Position = UDim2.fromOffset(math.min(from.X, to.X), math.min(from.Y, to.Y))
                        l.Size = UDim2.fromOffset(math.max(w, 1), math.max(th, 1))
                        l.BackgroundColor3 = _hm.color
                        l.BackgroundTransparency = tr
                        l.Visible = true
                        local lb = _hmLinesBlk and _hmLinesBlk[i]
                        if lb then
                            lb.Position = UDim2.fromOffset(math.min(from.X, to.X) - 1, math.min(from.Y, to.Y) - 1)
                            lb.Size = UDim2.fromOffset(math.max(w + 2, 1), math.max(th + 2, 1))
                            lb.BackgroundColor3 = C_BLACK
                            lb.BackgroundTransparency = tr
                            lb.Visible = true
                        end
                    end
                end
            end
        end

        -- 傷害數字
        if _dnActive[1] then
            for i = #_dnActive, 1, -1 do
                local e = _dnActive[i]
                local a = (now - e.t0) / 0.7
                if a >= 1 then
                    if e.d then e.d.Visible = false end
                    e.alive = false
                    if _dnByPlr[e.p] == e then _dnByPlr[e.p] = nil end
                    table.remove(_dnActive, i)
                elseif e.d then
                    local sp = Camera:WorldToViewportPoint(e.pos)
                    if sp.Z <= 0 then
                        e.d.Visible = false
                    else
                        local d = e.d
                        local ease = 1 - (1 - a) * (1 - a)
                        local pop  = 1 + 0.25 * (1 - math.clamp((now - e.popT) / 0.12, 0, 1))
                        d.TextSize = math.floor((14 + math.clamp(e.total / 50, 0, 1) * 8) * pop + 0.5)
                        d.Text = tostring(math.floor(e.total + 0.5))
                        if e.crit or e.lethal then d.TextColor3 = C_GOLD
                        else d.TextColor3 = dnRamp(e.total) end
                        d.Position = UDim2.fromOffset(math.floor(sp.X + e.drift * a), math.floor(sp.Y - 42 * ease))
                        d.TextTransparency = a < 0.6 and 0 or (a - 0.6) / 0.4
                        d.Visible = true
                    end
                end
            end
        end

        -- 擊殺橫幅
        if _kb.on then
            local a = now - _kb.t0
            if a >= 1.17 then
                _kb.on = false
                if _kbL1 then _kbL1.Visible = false end
                if _kbL2 then _kbL2.Visible = false end
                if _kbRing then _kbRing.Visible = false end
            else
                local y = cy - 140
                local scale, tr, rise = 1, 1, 0
                if a < 0.09 then
                    scale = 0.6 + 0.4 * (a / 0.09)
                elseif a > 0.79 then
                    local f = (a - 0.79) / 0.38
                    tr = 1 - f
                    rise = 8 * f
                end
                if _kbL1 then
                    local lt = math.clamp(a / 0.24, 0, 1)
                    local le = 1 - (1 - lt) * (1 - lt) * (1 - lt)
                    _kbL1.Text = _kb.line1
                    _kbL1.TextSize = math.floor(12 * scale + 0.5)
                    _kbL1.TextColor3 = WHITE
                    _kbL1.Position = UDim2.fromOffset(math.floor(cx), math.floor(y - rise - 3 * (1 - le)))
                    _kbL1.TextTransparency = tr * le
                    _kbL1.Visible = true
                end
                if _kbL2 then
                    _kbL2.Text = _kb.line2
                    _kbL2.TextSize = math.floor(22 * scale + 0.5)
                    _kbL2.TextColor3 = Config.FXKillBannerColor
                    _kbL2.Position = UDim2.fromOffset(math.floor(cx), math.floor(y - rise + 16))
                    _kbL2.TextTransparency = tr
                    _kbL2.Visible = true
                end
                if _kbRing then
                    if a < 0.32 then
                        local f = a / 0.32
                        local fe = 1 - (1 - f) * (1 - f)
                        _kbRing.Position = UDim2.fromOffset(math.floor(cx - 20), math.floor(cy - 20))
                        _kbRing.Size = UDim2.fromOffset(math.floor(12 + 80 * fe), math.floor(12 + 80 * fe))
                        _kbRing.Visible = true
                        local ucs = _kbRing:FindFirstChildOfClass("UIStroke")
                        if ucs then
                            ucs.Transparency = math.min(1, 0.6 + 0.1 * (_kb.streak - 1)) * (1 - f)
                            ucs.Thickness = 2 - 1.5 * f
                            ucs.Color = Config.FXKillBannerColor
                        end
                    else
                        _kbRing.Visible = false
                    end
                end
            end
        end

        -- 擊殺訊息列表
        if _kfPool then
            local y0 = 110
            for i, d in ipairs(_kfPool) do
                local it = _kfItems[i]
                if d then
                    if not it or (now - it.t0) >= 5 then
                        d.Visible = false
                    else
                        local a = now - it.t0
                        local slide = math.clamp(a / 0.12, 0, 1)
                        slide = 1 - (1 - slide) * (1 - slide)
                        d.Text = it.text
                        d.TextColor3 = it.crit and C_GOLD or WHITE
                        d.TextSize = 13
                        local rx = vp.X - 16 - d.TextBounds.X + (1 - slide) * 30
                        local ry = y0 + (i - 1) * 18
                        local tr = a < 4 and 1 or 1 - (a - 4)
                        d.Position = UDim2.fromOffset(math.floor(rx), math.floor(ry))
                        d.TextTransparency = 1 - tr
                        d.Visible = true
                    end
                end
            end
            for i = #_kfItems, 1, -1 do
                if (now - _kfItems[i].t0) >= 5 then table.remove(_kfItems, i) end
            end
        end

        -- 爆頭火花
        if _hs.on and _hsLines then
            local a = (now - _hs.t0) / 0.18
            if a >= 1 then
                _hs.on = false
                for _, l in ipairs(_hsLines) do if l then l.Visible = false end end
                if _hsLinesBlk then for _, l in ipairs(_hsLinesBlk) do if l then l.Visible = false end end end
            else
                local sp = Camera:WorldToViewportPoint(_hs.pos)
                if sp.Z <= 0 then
                    for _, l in ipairs(_hsLines) do if l then l.Visible = false end end
                else
                    local rad = 4 + 8 * a
                    local tr = 1 - a * a
                    for i, l in ipairs(_hsLines) do
                        if l then
                            local th = (i - 1) * (math.pi / 3)
                            local dx, dy = math.cos(th), math.sin(th)
                            local from = Vector2.new(sp.X + dx * rad, sp.Y + dy * rad)
                            local to   = Vector2.new(sp.X + dx * (rad + 5), sp.Y + dy * (rad + 5))
                            l.Position = UDim2.fromOffset(math.floor(math.min(from.X, to.X)), math.floor(math.min(from.Y, to.Y)))
                            l.Size = UDim2.fromOffset(math.max(math.abs(to.X - from.X), 2), 2)
                            l.BackgroundColor3 = C_GOLD
                            l.BackgroundTransparency = tr
                            l.Visible = true
                        end
                    end
                end
            end
        end

        -- 受擊紅閃
        if _hf.on and _flashFrame then
            local a = (now - _hf.t0) / 0.16
            if a >= 1 then
                _hf.on = false
                _flashFrame.Visible = false
            else
                _flashFrame.BackgroundTransparency = 0.78 + 0.22 * a
                _flashFrame.Visible = true
            end
        end

        -- 低血暗角
        if _vgFrames then
            local show = false
            if Config.FXLowHPVignette then
                if (now - _vgLastPoll) > 0.1 then
                    _vgLastPoll = now
                    local hp, mh = getHealth(lp)
                    _vgHP = (mh and mh > 0) and hp / mh or 1
                end
                local thr = Config.FXLowHPThreshold or 0.35
                if _vgHP > 0 and _vgHP < thr then
                    local sev = math.clamp((thr - _vgHP) / math.max(thr - 0.10, 0.01), 0, 1)
                    local freq = 0.8 + 0.6 * sev
                    local tr = (0.85 - 0.35 * sev)
                        + 0.06 * (0.5 + 0.5 * math.sin(now * freq * 6.283185))
                    tr = math.clamp(tr, 0, 1)
                    for _, f in ipairs(_vgFrames) do
                        f.BackgroundTransparency = tr
                        if not f.Visible then f.Visible = true end
                    end
                    show = true
                end
            end
            if not show then
                for _, f in ipairs(_vgFrames) do if f.Visible then f.Visible = false end end
            end
        end

        -- 浮水印
        if _wmText then
            if Config.HUDWatermark then
                if dt > 0 then _wm.fps = _wm.fps + (1 / dt - _wm.fps) * 0.1 end
                local stats = Config.HUDWatermarkStats
                if stats and (now - _wm.pingT) > 1 then
                    _wm.pingT = now
                    pcall(function()
                        _wm.ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
                    end)
                end
                _wmText.Visible = true
                _wmText.TextTransparency = 1
                if not _wm.bw then
                    pcall(function() local tb = _wmText.TextBounds; if tb and tb.X > 0 then _wm.bw = tb.X end end)
                end
                local bw = _wm.bw or 52
                if (now - _wm.strT) > 0.25 then
                    _wm.strT = now
                    if stats then
                        local sess = now - _sessT0
                        _wm.str = string.format("%d fps · %d ms · %02d:%02d · %d kills",
                            math.floor(_wm.fps + 0.5), _wm.ping,
                            math.floor(sess / 60), math.floor(sess % 60), _sessKills)
                    else
                        _wm.str = ""
                    end
                    local sw = 0
                    if _wm.stats and _wm.str ~= "" then
                        _wm.stats.Text = _wm.str
                        pcall(function() local tb = _wm.stats.TextBounds; if tb then sw = tb.X end end)
                    end
                    _wm.pw = (sw > 0) and (10 + bw + 12 + sw + 10) or (10 + bw + 10)
                end
                if _wm.stats then
                    if _wm.str ~= "" then
                        _wm.stats.Position = UDim2.fromOffset(26 + bw + 12, 22)
                        _wm.stats.Visible = true
                    elseif _wm.stats.Visible then _wm.stats.Visible = false end
                end
                if _wmBg then
                    _wmBg.Position = UDim2.fromOffset(16, 16)
                    _wmBg.Size = UDim2.fromOffset(_wm.pw, 24)
                    _wmBg.Visible = true
                end
            else
                if _wmText.Visible then _wmText.Visible = false end
                if _wm.stats and _wm.stats.Visible then _wm.stats.Visible = false end
                if _wmBg and _wmBg.Visible then _wmBg.Visible = false end
            end
        end
    end

    local function hideAllFX()
        if _hmLines then hideMarker() end
        for i = #_dnActive, 1, -1 do
            local e = _dnActive[i]
            if e.d then e.d.Visible = false end
            _dnActive[i] = nil
        end
        table.clear(_dnByPlr)
        _kb.on = false
        if _kbL1 then _kbL1.Visible = false end
        if _kbL2 then _kbL2.Visible = false end
        if _kbRing then _kbRing.Visible = false end
        table.clear(_kfItems)
        if _kfPool then for _, d in ipairs(_kfPool) do if d then d.Visible = false end end end
        _hs.on = false
        if _hsLines then for _, l in ipairs(_hsLines) do if l then l.Visible = false end end end
        if _hsLinesBlk then for _, l in ipairs(_hsLinesBlk) do if l then l.Visible = false end end end
        _hf.on = false
        if _flashFrame then _flashFrame.Visible = false end
        if _vgFrames then for _, f in ipairs(_vgFrames) do f.Visible = false end end
        if _wmBg then _wmBg.Visible = false end
        if _wmText then _wmText.Visible = false end
        if _wm.stats then _wm.stats.Visible = false end
    end

    local function hookHumanoid(char)
        if _hcConn then _hcConn:Disconnect(); _hcConn = nil end
        if not char then return end
        task.spawn(function()
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then
                pcall(function() hum = char:WaitForChild("Humanoid", 5) end)
            end
            if not hum or not _started or char ~= lp.Character then return end
            _lastHP = hum.Health
            _hcConn = hum.HealthChanged:Connect(function(h)
                local prev = _lastHP or h
                _lastHP = h
                local drop = prev - h
                if drop > 0.5 then FXSys.onIncoming(drop) end
            end)
        end)
    end

    function FXSys.start()
        if _started then return end
        _started = true
        allocate()
        ensureGui()
        hookHumanoid(lp.Character)
        _charConn = lp.CharacterAdded:Connect(function(c) if _started then hookHumanoid(c) end end)
        if not _updConn then
            _updConn = RunService.RenderStepped:Connect(function()
                if _started then pcall(update) end
            end)
        end
    end
    function FXSys.stop()
        if not _started then return end
        _started = false
        if _updConn then _updConn:Disconnect(); _updConn = nil end
        if _hcConn then _hcConn:Disconnect(); _hcConn = nil end
        if _charConn then _charConn:Disconnect(); _charConn = nil end
        hideAllFX()
    end
    function FXSys.destroy()
        FXSys.stop()
        if _gui then pcall(function() _gui:Destroy() end); _gui = nil end
        _alloc = false
    end
    function FXSys.onTargetDamaged(p, info)
        if not _started then return end
        local cur, maxHP = getHealth(p)
        local dmg = info and info.dmg or 0
        local lethal = (not isAlive(p)) or cur <= 0
        local char = p.Character
        local rp = char and (char:FindFirstChild("HitboxHead") or char:FindFirstChild("Head")
            or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso"))
        local hitPos = rp and rp.Position or nil
        local crit = (info and info.crit) or (dmg >= Config.FXCritDamage)
        FXSys.onHit(p, dmg, crit, lethal, hitPos)
    end
end

-- 把 FXSys 掛到 Gun hook
do
    local _lastHP = {}
    local _origHook = Rivals.Gun and Rivals.Gun.StartShooting
    if _origHook then
        -- 包一層，每次命中後通知 FX
        local _currentHook = Rivals.Gun.StartShooting
        Rivals.Gun.StartShooting = function(self, ...)
            local results = _currentHook(self, ...)
            pcall(function()
                if not self.ClientFighter or not self.ClientFighter.IsLocalPlayer then return end
                if Config.Rage then
                    local tgt = State.RageTarget
                    if tgt then
                        local cur, maxHP = getHealth(tgt)
                        local last = _lastHP[tgt] or maxHP
                        local dmg = math.max(0, last - cur)
                        _lastHP[tgt] = cur
                        if dmg > 0 or (not isAlive(tgt)) then
                            FXSys.onTargetDamaged(tgt, { dmg = dmg })
                        end
                    end
                elseif Config.SilentAim then
                    local tgt = State.SilentLastTarget
                    if tgt then
                        local cur, maxHP = getHealth(tgt)
                        local last = _lastHP[tgt] or maxHP
                        local dmg = math.max(0, last - cur)
                        _lastHP[tgt] = cur
                        if dmg > 0 or (not isAlive(tgt)) then
                            FXSys.onTargetDamaged(tgt, { dmg = dmg })
                        end
                    end
                end
            end)
            return results
        end
    end
end

-- ============================================================
-- 視覺系統（精簡版：全亮/無霧/彩虹 + 全像 + 相機 + 外觀 + 偽裝）
-- ============================================================
local Visuals = {}
;(function()
    local _origLighting, _origClones = nil, {}
    local _hologramFolder = nil
    local _stretchBound, _rainbowConn = false, nil
    local _rainbowParts, _rainbowHue, _rainbowBatchIdx = {}, 0, 1
    local LIGHTING_PROPS = {
        "Brightness","ExposureCompensation","GlobalShadows","ShadowSoftness",
        "EnvironmentDiffuseScale","EnvironmentSpecularScale","ClockTime",
        "OutdoorAmbient","Ambient","FogEnd","FogStart","FogColor",
        "ColorShift_Top","ColorShift_Bottom",
    }
    local function snapshotLighting()
        if _origLighting then return end
        _origLighting = {}
        for _, p in ipairs(LIGHTING_PROPS) do
            local ok, v = pcall(function() return Lighting[p] end)
            if ok then _origLighting[p] = v end
        end
        for _, c in ipairs(Lighting:GetChildren()) do
            if not c:GetAttribute("VS_Custom") then
                local ok, clone = pcall(function() return c:Clone() end)
                if ok and clone then table.insert(_origClones, clone) end
            end
        end
    end
    local function clearTagged()
        for _, c in ipairs(Lighting:GetChildren()) do
            if c:GetAttribute("VS_Custom") then c:Destroy() end
        end
    end
    local function restore()
        if not _origLighting then return end
        clearTagged()
        for k, v in pairs(_origLighting) do pcall(function() Lighting[k] = v end) end
        local exist = {}
        for _, c in ipairs(Lighting:GetChildren()) do exist[c.Name] = true end
        for _, clone in ipairs(_origClones) do
            if not exist[clone.Name] then clone:Clone().Parent = Lighting end
        end
    end
    local _WHITE = Color3.new(1, 1, 1)
    local function applyFullbrightOverride()
        if not Config.VisualsFullbright then return end
        pcall(function() if Lighting.Ambient ~= _WHITE then Lighting.Ambient = _WHITE end end)
        pcall(function() if Lighting.OutdoorAmbient ~= _WHITE then Lighting.OutdoorAmbient = _WHITE end end)
        pcall(function() if Lighting.GlobalShadows ~= false then Lighting.GlobalShadows = false end end)
        pcall(function() if Lighting.Brightness < 2 then Lighting.Brightness = 2 end end)
    end
    local function applyFogOverride()
        if not Config.VisualsNoFog then return end
        pcall(function() if Lighting.FogEnd ~= 1e6 then Lighting.FogEnd = 1e6 end end)
        pcall(function() if Lighting.FogStart ~= 1e6 then Lighting.FogStart = 1e6 end end)
        for _, c in ipairs(Lighting:GetChildren()) do
            if c:IsA("Atmosphere") then
                pcall(function() if c.Density ~= 0 then c.Density = 0 end end)
            end
        end
    end
    local PRESETS = {
        Neutral   = { Brightness=2,   ExposureCompensation=0,    ClockTime=14,   OutdoorAmbient=Color3.fromRGB(70,70,70),
                      Ambient=Color3.fromRGB(0,0,0),      FogEnd=100000,
                      EnvironmentDiffuseScale=0.5,  EnvironmentSpecularScale=0.5 },
        Clarity   = { Brightness=2.6, ExposureCompensation=0,    ClockTime=14,   OutdoorAmbient=Color3.fromRGB(150,150,155),
                      Ambient=Color3.fromRGB(120,120,125), FogEnd=1000000,
                      EnvironmentDiffuseScale=0.2,  EnvironmentSpecularScale=0.1 },
        Cyberpunk = { Brightness=2.6, ExposureCompensation=0.5,  ClockTime=0,    OutdoorAmbient=Color3.fromRGB(120,80,165),
                      Ambient=Color3.fromRGB(80,55,120),
                      EnvironmentDiffuseScale=0.7,  EnvironmentSpecularScale=1 },
        Anime     = { Brightness=2.3, ExposureCompensation=0.2,  ClockTime=15,   OutdoorAmbient=Color3.fromRGB(150,140,170),
                      Ambient=Color3.fromRGB(95,85,120),
                      EnvironmentDiffuseScale=0.7,  EnvironmentSpecularScale=0.7 },
        Sunset    = { Brightness=2.3, ExposureCompensation=0.4,  ClockTime=17.75, OutdoorAmbient=Color3.fromRGB(185,115,80),
                      Ambient=Color3.fromRGB(105,60,45),
                      EnvironmentDiffuseScale=0.75, EnvironmentSpecularScale=0.9 },
        Vaporwave = { Brightness=2.3, ExposureCompensation=0.4,  ClockTime=18.4, OutdoorAmbient=Color3.fromRGB(150,90,165),
                      Ambient=Color3.fromRGB(95,60,120),
                      EnvironmentDiffuseScale=0.6,  EnvironmentSpecularScale=0.9 },
        Toxic     = { Brightness=2.2, ExposureCompensation=0.35, ClockTime=1,    OutdoorAmbient=Color3.fromRGB(80,135,70),
                      Ambient=Color3.fromRGB(45,85,50),
                      EnvironmentDiffuseScale=0.6,  EnvironmentSpecularScale=0.8 },
        Void      = { Brightness=2.0, ExposureCompensation=0.25, ClockTime=0,    OutdoorAmbient=Color3.fromRGB(85,95,135),
                      Ambient=Color3.fromRGB(55,62,95),
                      EnvironmentDiffuseScale=0.5,  EnvironmentSpecularScale=0.7 },
        Sakura    = { Brightness=2.2, ExposureCompensation=0.35, ClockTime=15.5, OutdoorAmbient=Color3.fromRGB(200,155,180),
                      Ambient=Color3.fromRGB(120,85,110),
                      EnvironmentDiffuseScale=0.7,  EnvironmentSpecularScale=0.7 },
        Nebula    = { Brightness=2.2, ExposureCompensation=0.4,  ClockTime=0,    OutdoorAmbient=Color3.fromRGB(128,94,168),
                      Ambient=Color3.fromRGB(82,60,120),
                      EnvironmentDiffuseScale=0.55, EnvironmentSpecularScale=0.85 },
    }
    local function applyPreset(name)
        if not Config.Visuals or Config.VisualsPerformanceMode then return end
        local sc = PRESETS[name]; if not sc then return end
        for k, v in pairs(sc) do pcall(function() Lighting[k] = v end) end
        pcall(function() Lighting.GlobalShadows = false end)
        applyFullbrightOverride()
        applyFogOverride()
    end

    local function getHoloFolder()
        if _hologramFolder and _hologramFolder.Parent then return _hologramFolder end
        local f = Instance.new("Folder"); f.Name = "_vs_holos"; f.Parent = Workspace
        _hologramFolder = f; return f
    end

    function Visuals.enable()
        Config.Visuals = true
        snapshotLighting()
        applyPreset(Config.VisualsPreset or "Neutral")
        applyFullbrightOverride()
        applyFogOverride()
    end
    function Visuals.disable()
        Config.Visuals = false
        restore()
    end
    function Visuals.setPreset(name)
        if PRESETS[name] then
            Config.VisualsPreset = name
            applyPreset(name)
        end
    end
    function Visuals.toggleFullbright(on)
        Config.VisualsFullbright = on
        if on then applyFullbrightOverride() else applyPreset(Config.VisualsPreset or "Neutral") end
    end
    function Visuals.toggleNoFog(on)
        Config.VisualsNoFog = on
        if on then applyFogOverride() else applyPreset(Config.VisualsPreset or "Neutral") end
    end
    function Visuals.togglePerf(on)
        Config.VisualsPerformanceMode = on
        if on then
            clearTagged()
            Lighting.GlobalShadows = false
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
        else
            applyPreset(Config.VisualsPreset or "Neutral")
        end
    end
    function Visuals.toggleRainbow(on)
        Config.VisualsRainbowMap = on
        if not on then
            if _rainbowConn then _rainbowConn:Disconnect(); _rainbowConn = nil end
            for _, e in ipairs(_rainbowParts) do
                if e.part and e.part.Parent then pcall(function() e.part.Color = e.originalColor end) end
            end
            table.clear(_rainbowParts)
            return
        end
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") then
                table.insert(_rainbowParts, { part = d, originalColor = d.Color })
            end
        end
        _rainbowConn = RunService.Heartbeat:Connect(function(dt)
            if not Config.Visuals or not Config.VisualsRainbowMap then return end
            _rainbowHue = (_rainbowHue + dt * Config.VisualsRainbowMapSpeed) % 1
            local total = #_rainbowParts; if total == 0 then return end
            local batch = math.min(250, total)
            for i = 1, batch do
                local idx = ((_rainbowBatchIdx - 1 + i - 1) % total) + 1
                local e   = _rainbowParts[idx]
                if e and e.part and e.part.Parent then
                    e.part.Color = Color3.fromHSV((_rainbowHue + (idx / total) * 0.3) % 1, 0.85, 1)
                end
            end
            _rainbowBatchIdx = ((_rainbowBatchIdx + batch - 1) % total) + 1
        end)
    end
    function Visuals.refreshViewModel() end
    function Visuals.updatePlayerSpoofer() end
    function Visuals.applyGuiNameSpoof() end
    function Visuals.init() snapshotLighting() end
    function Visuals.unload() Visuals.disable() end
end)()

-- ============================================================
-- 天氣系統（精簡版：雨/雪/花瓣/秋葉 + 風 + 雷電）
-- ============================================================
local Weather = {}
;(function()
    local SoundService = game:GetService("SoundService")
    local TweenService = game:GetService("TweenService")
    local Vec   = Vector3.new
    local WHITE = Color3.new(1, 1, 1)
    local _folder = nil
    local function getFolder()
        if _folder and _folder.Parent then return _folder end
        local f = Instance.new("Folder"); f.Name = "_wx"; f:SetAttribute("WX_Custom", true)
        f.Parent = Workspace
        _folder = f; return f
    end
    local _rain = { drops = {}, conn = nil, folder = nil, dir = nil, applied = nil }
    local RAIN_RADIUS = 70
    local RAIN_TOP    = 70
    local RAIN_BOT    = -28
    local RAIN_MAX    = 420
    local function rainFolder()
        if _rain.folder and _rain.folder.Parent then return _rain.folder end
        local f = Instance.new("Folder"); f.Name = "_wxRain"; f:SetAttribute("WX_Custom", true)
        f.Parent = getFolder()
        _rain.folder = f; return f
    end
    local function makeDrop(parent, streakLen, width, color, transp)
        local part = Instance.new("Part")
        part.Anchored = true; part.CanCollide = false; part.CanQuery = false; part.CanTouch = false
        part.CastShadow = false; part.Massless = true; part.Transparency = 1
        part.Size = Vec(0.05,0.05,0.05)
        part:SetAttribute("WX_Custom", true)
        local a0 = Instance.new("Attachment"); a0.Parent = part
        local a1 = Instance.new("Attachment"); a1.Position = Vec(0.12, -1, 0.05).Unit * streakLen; a1.Parent = part
        local beam = Instance.new("Beam")
        beam.Attachment0 = a0; beam.Attachment1 = a1
        beam.Segments = 1; beam.FaceCamera = true
        beam.Width0 = width; beam.Width1 = width * 0.55
        beam.LightEmission = 0.35; beam.LightInfluence = 0
        beam.Color = ColorSequence.new(color)
        beam.Transparency = NumberSequence.new(transp)
        beam.Parent = part
        part.Parent = parent
        return part, a1, beam
    end
    local function seedDrop(d, camPos)
        local ang = math.random() * math.pi * 2
        local rad = math.sqrt(math.random()) * RAIN_RADIUS
        local y   = camPos.Y + RAIN_TOP - math.random() * (RAIN_TOP - RAIN_BOT)
        d.pos = Vec(camPos.X + math.cos(ang) * rad, y, camPos.Z + math.sin(ang) * rad)
    end
    local function newDrop(folder, i, camPos)
        local base, width, transp, spd0
        if (i % 3) ~= 0 then
            base, width, transp = 5 + math.random() * 3, 0.10, 0.22
            spd0 = 150 + math.random() * 30
        else
            base, width, transp = 3 + math.random() * 2, 0.06, 0.55
            spd0 = 120 + math.random() * 30
        end
        local part, a1, beam = makeDrop(folder, base, width, Color3.fromRGB(180, 202, 232), transp)
        local d = { part = part, a1 = a1, beam = beam, base = base, len = base,
                    w0 = width, t0 = transp, spd0 = spd0, spd = spd0 }
        seedDrop(d, camPos)
        part.CFrame = CFrame.new(d.pos)
        return d
    end
    local function tuneRain()
        local folder = rainFolder()
        local I = math.clamp(Config.WeatherIntensity or 1, 0.15, 2)
        local n = math.clamp(math.floor(150 * (I < 1 and math.exp(1.75 * (I - 1)) or math.exp(0.85 * (I - 1)))), 16, RAIN_MAX)
        local drops = _rain.drops
        local camPos = Vec(0, 0, 0)
        if Camera then camPos = Camera.CFrame.Position end
        for i = #drops, n + 1, -1 do
            drops[i].part:Destroy()
            drops[i] = nil
        end
        for i = #drops + 1, n do
            drops[i] = newDrop(folder, i, camPos)
        end
    end
    local function buildRain()
        if _rain.folder then pcall(function() _rain.folder:Destroy() end); _rain.folder = nil end
        table.clear(_rain.drops)
        _rain.dir = Vec(0.12, -1, 0.05).Unit
        tuneRain()
    end
    local function startRain()
        if _rain.conn then return end
        _rain.conn = RunService.Heartbeat:Connect(function(dt)
            if not Config.Weather or Config.WeatherType ~= "Rain" then return end
            local cam = Camera; if not cam then return end
            local camPos = cam.CFrame.Position
            local step = _rain.dir
            local r2 = RAIN_RADIUS * RAIN_RADIUS
            for i = 1, #_rain.drops do
                local d = _rain.drops[i]
                local p = d.pos + step * (d.spd * dt)
                local relX, relY, relZ = p.X - camPos.X, p.Y - camPos.Y, p.Z - camPos.Z
                if relY < RAIN_BOT or (relX * relX + relZ * relZ) > r2 then
                    seedDrop(d, camPos)
                    p = d.pos
                end
                d.pos = p
                if d.part then d.part.CFrame = CFrame.new(p) end
            end
        end)
    end
    local function stopRain()
        if _rain.conn then _rain.conn:Disconnect(); _rain.conn = nil end
        if _rain.folder then pcall(function() _rain.folder:Destroy() end); _rain.folder = nil end
        table.clear(_rain.drops)
        _rain.dir = nil; _rain.applied = nil
    end
    local function applyType(name)
        stopRain()
        if name == "Rain" then
            buildRain(); startRain()
        end
    end
    function Weather.enableWeather()
        Config.Weather = true
        applyType(Config.WeatherType or "Rain")
    end
    function Weather.disableWeather()
        Config.Weather = false
        stopRain()
    end
    function Weather.setType(name)
        Config.WeatherType = name
        if Config.Weather then applyType(name) end
    end
    function Weather.setIntensity(v)
        Config.WeatherIntensity = math.clamp(v, 0.15, 2)
        if Config.Weather and Config.WeatherType == "Rain" then tuneRain() end
    end
    function Weather.setSoundVolume(v) Config.WeatherSoundVolume = v end
    function Weather.toggleStorm(on) Config.WeatherStorm = on end
    function Weather.toggleMood(on) Config.WeatherMood = on end
    function Weather.toggleMeteors(on) Config.WeatherMeteors = on end
    function Weather.toggleShootingStars(on) Config.WeatherShootingStars = on end
    function Weather.toggleClock(on) Config.WeatherClockDial = on end
    function Weather.togglePuddles(on) Config.WeatherPuddles = on end
    function Weather.setSkybox(name) Config.SkyboxPreset = name end
    function Weather.toggleCelestial(on) Config.SkyboxHideCelestial = on end
    function Weather.toggleGodRays(on) Config.WeatherGodRays = on end
    function Weather.toggleRainbow(on) Config.WeatherRainbow = on end
    function Weather.setStormMin(v) Config.WeatherStormMin = math.clamp(v, 1, 30) end
    function Weather.setStormVar(v) Config.WeatherStormVar = math.clamp(v, 0, 30) end
    function Weather.setMeteorRate(v) Config.WeatherMeteorRate = math.clamp(v, 0.25, 3) end
    function Weather.setStarRate(v) Config.WeatherStarRate = math.clamp(v, 0.25, 3) end
    function Weather.init() if Config.Weather then Weather.enableWeather() end end
    function Weather.unload() Weather.disableWeather() end
end)()

-- ============================================================
-- 自動撿補
-- ============================================================
;(function()
    local _lastCollect = 0
    RunService.Heartbeat:Connect(function()
        if not Config.AutoCollectDrops then return end
        if State.RageTranslocating or State.RageVoidActive then return end
        local now = tick()
        if now - _lastCollect < 0.10 then return end
        _lastCollect = now
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end
        local wantHealth = Config.CollectHealth and (hum.Health < hum.MaxHealth)
        local wantAmmo = Config.CollectAmmo
        if not wantHealth and not wantAmmo then return end
        local firetouch = firetouchinterest
        if not firetouch then return end
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj.Name == "_drop" and obj:IsA("BasePart") then
                local isHealth = obj:FindFirstChild("Health") ~= nil
                local isAmmo = (obj:FindFirstChild("Ammo") ~= nil or obj:FindFirstChild("AmmoBalanced") ~= nil)
                if (wantHealth and isHealth) or (wantAmmo and isAmmo) then
                    pcall(function()
                        firetouch(hrp, obj, 0)
                        firetouch(hrp, obj, 1)
                    end)
                end
            end
        end
    end)
end)()

-- ============================================================
-- 介面分頁
-- ============================================================
do
    local M = HUDTab:AddLeftGroupbox('主控')
    M:AddToggle('HUD', { Text='啟用介面', Default=true,
        Callback=function(v)
            if v then FXSys.start() else FXSys.stop() end
        end })
    M:AddToggle('HUDWatermark', { Text='浮水印', Default=Config.HUDWatermark,
        Callback=function(v) Config.HUDWatermark = v end })
    local wmDep = M:AddDependencyBox()
    wmDep:AddToggle('HUDWatermarkStats', { Text='顯示幀率／延遲／擊殺', Default=Config.HUDWatermarkStats,
        Callback=function(v) Config.HUDWatermarkStats = v end })
    wmDep:SetupDependencies({ { Toggles.HUDWatermark, true } })

    local W2 = HUDTab:AddRightGroupbox('命中回饋')
    W2:AddToggle('FXHitMarker', { Text='命中標記', Default=Config.FXHitMarker,
        Callback=function(v) Config.FXHitMarker = v end })
    local hmdep = W2:AddDependencyBox()
    hmdep:AddDropdown('FXHitMarkerStyle', { Values={'X','Plus'}, Default=Config.FXHitMarkerStyle,
        Text='樣式', Callback=function(v) Config.FXHitMarkerStyle = v end })
    hmdep:AddLabel('顏色'):AddColorPicker('FXHitMarkerColor', { Default=Config.FXHitMarkerColor,
        Callback=function(v) Config.FXHitMarkerColor = v end })
    hmdep:AddSlider('FXHitMarkerGap', { Text='間距', Default=Config.FXHitMarkerGap,
        Min=0, Max=20, Rounding=0, Callback=function(v) Config.FXHitMarkerGap = math.floor(v) end })
    hmdep:AddSlider('FXHitMarkerLen', { Text='長度', Default=Config.FXHitMarkerLen,
        Min=2, Max=24, Rounding=0, Callback=function(v) Config.FXHitMarkerLen = math.floor(v) end })
    hmdep:AddSlider('FXHitMarkerThickness', { Text='粗細', Default=Config.FXHitMarkerThickness,
        Min=1, Max=4, Rounding=0, Callback=function(v) Config.FXHitMarkerThickness = math.floor(v) end })
    hmdep:SetupDependencies({ { Toggles.FXHitMarker, true } })

    W2:AddToggle('FXDamageNumbers', { Text='傷害數字', Default=Config.FXDamageNumbers,
        Callback=function(v) Config.FXDamageNumbers = v end })
    W2:AddToggle('FXKillBanner', { Text='擊殺橫幅', Default=Config.FXKillBanner,
        Callback=function(v) Config.FXKillBanner = v end })
    W2:AddToggle('FXKillFeed', { Text='擊殺訊息', Default=Config.FXKillFeed,
        Callback=function(v) Config.FXKillFeed = v end })
    W2:AddToggle('FXHeadshotSpark', { Text='爆頭火花', Default=Config.FXHeadshotSpark,
        Callback=function(v) Config.FXHeadshotSpark = v end })
    W2:AddToggle('FXHitFlash', { Text='受擊紅閃', Default=Config.FXHitFlash,
        Callback=function(v) Config.FXHitFlash = v end })
    W2:AddToggle('FXLowHPVignette', { Text='低血暗角', Default=Config.FXLowHPVignette,
        Callback=function(v) Config.FXLowHPVignette = v end })
end

-- ============================================================
-- 視覺分頁
-- ============================================================
do
    local LTB = VisualsTab:AddLeftTabbox('世界')
    local WL = LTB:AddTab('光照')
    local WX = LTB:AddTab('天氣')
    WL:AddToggle('Visuals', { Text='啟用', Default=Config.Visuals,
        Callback=function(v) if v then Visuals.enable() else Visuals.disable() end end })
    local litDep = WL:AddDependencyBox()
    litDep:AddDropdown('VisualsPreset', { Values={'Neutral','Clarity','Cyberpunk','Anime','Sunset','Vaporwave','Toxic','Void','Sakura','Nebula'},
        Default=Config.VisualsPreset, Text='預設', Callback=function(v) Visuals.setPreset(v) end })
    litDep:AddToggle('VisualsFullbright', { Text='全亮', Default=Config.VisualsFullbright,
        Callback=function(v) Visuals.toggleFullbright(v) end })
    litDep:AddToggle('VisualsNoFog', { Text='無霧', Default=Config.VisualsNoFog,
        Callback=function(v) Visuals.toggleNoFog(v) end })
    litDep:AddToggle('VisualsRainbowMap', { Text='彩虹世界', Default=Config.VisualsRainbowMap,
        Callback=function(v) Visuals.toggleRainbow(v) end })
    litDep:AddToggle('VisualsPerformanceMode', { Text='性能模式', Default=Config.VisualsPerformanceMode,
        Callback=function(v) Visuals.togglePerf(v) end })
    litDep:SetupDependencies({ { Toggles.Visuals, true } })
    WX:AddToggle('Weather', { Text='啟用', Default=Config.Weather,
        Callback=function(v) if v then Weather.enableWeather() else Weather.disableWeather() end end })
    local wxDep = WX:AddDependencyBox()
    wxDep:AddDropdown('WeatherType', { Values={'Rain','Snow','Petals','Autumn'},
        Default=Config.WeatherType, Text='降水', Callback=function(v) Weather.setType(v) end })
    wxDep:AddSlider('WeatherIntensity', { Text='強度', Default=Config.WeatherIntensity,
        Min=0.15, Max=2, Rounding=2, Callback=function(v) Weather.setIntensity(v) end })
    wxDep:AddSlider('WeatherSoundVolume', { Text='音量', Default=Config.WeatherSoundVolume,
        Min=0, Max=1, Rounding=2, Callback=function(v) Weather.setSoundVolume(v) end })
    wxDep:AddToggle('WeatherMood', { Text='氛圍色調', Default=Config.WeatherMood,
        Callback=function(v) Weather.toggleMood(v) end })
    wxDep:AddToggle('WeatherStorm', { Text='風暴與閃電', Default=Config.WeatherStorm,
        Callback=function(v) Weather.toggleStorm(v) end })
    wxDep:AddToggle('WeatherMeteors', { Text='流星', Default=Config.WeatherMeteors,
        Callback=function(v) Weather.toggleMeteors(v) end })
    wxDep:AddToggle('WeatherShootingStars', { Text='流星雨', Default=Config.WeatherShootingStars,
        Callback=function(v) Weather.toggleShootingStars(v) end })
    wxDep:AddToggle('WeatherPuddles', { Text='水窪', Default=Config.WeatherPuddles,
        Callback=function(v) Weather.togglePuddles(v) end })
    wxDep:AddToggle('WeatherClockDial', { Text='時鐘錶盤', Default=Config.WeatherClockDial,
        Callback=function(v) Weather.toggleClock(v) end })
    wxDep:SetupDependencies({ { Toggles.Weather, true } })

    local VM = VisualsTab:AddLeftGroupbox('視角模型與材質')
    VM:AddToggle('VMOffsetEnabled', { Text='六軸變換', Default=Config.VMOffsetEnabled,
        Callback=function(v) Config.VMOffsetEnabled = v end })
    local vmDep = VM:AddDependencyBox()
    vmDep:AddSlider('VMOffsetX', { Text='X', Default=Config.VMOffsetX, Min=-5, Max=5, Rounding=2, Compact=true,
        Callback=function(v) Config.VMOffsetX = v end })
    vmDep:AddSlider('VMOffsetY', { Text='Y', Default=Config.VMOffsetY, Min=-5, Max=5, Rounding=2, Compact=true,
        Callback=function(v) Config.VMOffsetY = v end })
    vmDep:AddSlider('VMOffsetZ', { Text='Z', Default=Config.VMOffsetZ, Min=-5, Max=5, Rounding=2, Compact=true,
        Callback=function(v) Config.VMOffsetZ = v end })
    vmDep:AddSlider('VMOffsetPitch', { Text='俯仰', Default=Config.VMOffsetPitch, Min=-180, Max=180, Rounding=0, Compact=true, Suffix='°',
        Callback=function(v) Config.VMOffsetPitch = math.floor(v) end })
    vmDep:AddSlider('VMOffsetYaw', { Text='偏航', Default=Config.VMOffsetYaw, Min=-180, Max=180, Rounding=0, Compact=true, Suffix='°',
        Callback=function(v) Config.VMOffsetYaw = math.floor(v) end })
    vmDep:AddSlider('VMOffsetRoll', { Text='翻滾', Default=Config.VMOffsetRoll, Min=-180, Max=180, Rounding=0, Compact=true, Suffix='°',
        Callback=function(v) Config.VMOffsetRoll = math.floor(v) end })
    vmDep:SetupDependencies({ { Toggles.VMOffsetEnabled, true } })
    VM:AddToggle('VMChamsEnabled', { Text='材質變色', Default=Config.VMChamsEnabled,
        Callback=function(v) Config.VMChamsEnabled = v end })
        :AddColorPicker('VMChamsColor', { Default=Config.VMChamsColor, Title='顏色',
            Callback=function(v) Config.VMChamsColor = v end })
    VM:AddToggle('VMDisableTextures', { Text='關閉槍械貼圖', Default=Config.VMDisableTextures,
        Callback=function(v) Config.VMDisableTextures = v end })

    local RTB = VisualsTab:AddRightTabbox('特效與相機')
    local CM = RTB:AddTab('相機')
    CM:AddToggle('CameraFovOverride', { Text='視野覆寫', Default=Config.CameraFovOverride,
        Callback=function(v) Config.CameraFovOverride = v end })
    local fovDep = CM:AddDependencyBox()
    fovDep:AddSlider('CameraFovAmount', { Text='視野', Default=Config.CameraFovAmount,
        Min=40, Max=130, Rounding=0, Suffix='°', Callback=function(v) Config.CameraFovAmount = math.floor(v) end })
    fovDep:SetupDependencies({ { Toggles.CameraFovOverride, true } })
    CM:AddToggle('ThirdPersonEnabled', { Text='第三人稱', Default=Config.ThirdPersonEnabled,
        Callback=function(v) Config.ThirdPersonEnabled = v end })
    local tpDep = CM:AddDependencyBox()
    tpDep:AddSlider('ThirdPersonDistance', { Text='距離', Default=Config.ThirdPersonDistance,
        Min=4, Max=30, Rounding=0, Suffix=' 單位', Callback=function(v) Config.ThirdPersonDistance = math.floor(v) end })
    tpDep:SetupDependencies({ { Toggles.ThirdPersonEnabled, true } })

    local SP = RTB:AddTab('偽裝')
    SP:AddToggle('SpooferNameEnabled', { Text='偽造名字', Default=Config.SpooferNameEnabled,
        Callback=function(v) Config.SpooferNameEnabled = v end })
    local spDep = SP:AddDependencyBox()
    spDep:AddInput('SpooferName', { Default=Config.SpooferName, Text='用戶名',
        Placeholder='用戶名', Finished=false,
        Callback=function(v) Config.SpooferName = v end })
    spDep:AddInput('SpooferDisplayName', { Default=Config.SpooferDisplayName, Text='顯示名',
        Placeholder='顯示名', Finished=false,
        Callback=function(v) Config.SpooferDisplayName = v end })
    spDep:SetupDependencies({ { Toggles.SpooferNameEnabled, true } })
    SP:AddToggle('SpooferLevelEnabled', { Text='偽造等級', Default=Config.SpooferLevelEnabled,
        Callback=function(v) Config.SpooferLevelEnabled = v end })
    SP:AddToggle('SpooferRankedEloEnabled', { Text='偽造積分', Default=Config.SpooferRankedEloEnabled,
        Callback=function(v) Config.SpooferRankedEloEnabled = v end })
    SP:AddToggle('SpooferCasualWinsEnabled', { Text='偽造休閒勝場', Default=Config.SpooferCasualWinsEnabled,
        Callback=function(v) Config.SpooferCasualWinsEnabled = v end })
end

-- ============================================================
-- 雜項分頁
-- ============================================================
do
    local MG = MiscTab:AddLeftGroupbox('自動化')
    MG:AddToggle('AutoQueue', { Text='自動排隊', Default=Config.AutoQueue,
        Callback=function(v) Config.AutoQueue = v end })
    local aqDep = MG:AddDependencyBox()
    aqDep:AddDropdown('AutoQueueMode', { Values={'1v1','2v2','3v3','4v4','5v5'},
        Default=Config.AutoQueueMode, Text='模式',
        Callback=function(v) Config.AutoQueueMode = v end })
    aqDep:SetupDependencies({ { Toggles.AutoQueue, true } })
    MG:AddToggle('AutoCollectDrops', { Text='自動撿補', Default=Config.AutoCollectDrops,
        Callback=function(v) Config.AutoCollectDrops = v end })
    local acDep = MG:AddDependencyBox()
    acDep:AddToggle('CollectHealth', { Text='補血包', Default=Config.CollectHealth,
        Callback=function(v) Config.CollectHealth = v end })
    acDep:AddToggle('CollectAmmo', { Text='補彈包', Default=Config.CollectAmmo,
        Callback=function(v) Config.CollectAmmo = v end })
    acDep:SetupDependencies({ { Toggles.AutoCollectDrops, true } })
end

-- 初始化新分頁
pcall(FXSys.start)
pcall(Visuals.init)
pcall(Weather.init)

Library:Notify('v12.0 完整載入完成', 4)
print("[v12.0] 完整載入完成")
