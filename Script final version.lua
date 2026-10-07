-- ============================================================
-- v3 Hub // ULTIMATE
-- 移植 grief.cc 全部優勢功能
-- ============================================================

-- ========== 反封號（強化版）==========
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
local debug = debug

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local W = game:GetService("Workspace")
local C = W.CurrentCamera
local LP = Players.LocalPlayer

-- 基礎 namecall hook
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

-- 連線清除（CharacterAdded + PlayerGui.ChildAdded）
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

-- Remote 清除
RS.DescendantAdded:Connect(function(obj)
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        local n = obj.Name:lower()
        if n:find("exploit") or n:find("cheat") or n:find("detect") or n:find("ban") or
           n:find("flag") or n:find("validate") or n:find("integrity") or n:find("security") or
           n:find("anticheat") or n:find("ac_") then
            pcall(function() obj:Destroy() end)
        end
    end
end)

-- 重生後再清
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    nukeConnections()
end)

-- __index hook 保護 Kick
if hookmetamethod then
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", function(self, key)
        if checkcaller() and key == "Kick" and self == LP then
            return function() end
        end
        return oldIndex(self, key)
    end)
end

-- MiscellaneousController 元表保護
task.spawn(function()
    if not hookfunction or not getrenv then return end
    pcall(function()
        local _stbl
        _stbl = hookfunction(getrenv().setmetatable, newcclosure(function(tbl, mt)
            if mt and typeof(mt) == "table" and rawget(mt, "__mode") == "kv" then
                local tr = debug.traceback()
                if tr:find("MiscellaneousController") then
                    return _stbl({1,2,3}, {})
                end
            end
            return _stbl(tbl, mt)
        end))
    end)

    -- AC 腳本癱瘓
    local function procAC(o)
        pcall(function()
            if o:IsA("LocalScript") or o:IsA("ModuleScript") then
                local n = o.Name:lower()
                local tags = {"anticheat","ac","detection","ban","kick","security","moderation"}
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

    -- NetworkClient 清除
    pcall(function()
        local nc = game:GetService("NetworkClient")
        if not nc then return end
        nc.ChildAdded:Connect(function(ch)
            pcall(function()
                local n = ch.Name:lower()
                if n:find("anticheat") or n:find("detection") then
                    pcall(function() ch:Destroy() end)
                end
            end)
        end)
    end)

    -- LocalScript3 常數掃描 hook
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
            local ok4, consts = pcall(debug.getconstants, fn)
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

-- 假 ClientAlert 事件
pcall(function()
    local fakeEv = Instance.new("RemoteEvent")
    fakeEv.Name = "ClientAlert"
    fakeEv.Parent = LP
end)

print("[v3 Hub] 反封號強化載入完成")

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

local Remotes = RS:FindFirstChild("Remotes")
local Replication = Remotes and Remotes:FindFirstChild("Replication")
local FighterRemote = Replication and Replication:FindFirstChild("Fighter")
local UseItem = FighterRemote and FighterRemote:FindFirstChild("UseItem")
local SetControls = FighterRemote and FighterRemote:FindFirstChild("SetControls")

print("[v3 Hub] Utility:", Utility ~= nil, "| EnumLibrary:", EnumLibrary ~= nil)

-- 動態取得 LocalFighter（死亡重生修復）
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

local localFighter = FighterController and FighterController.LocalFighter

-- ========== 設定 ==========
local S = {
    SilentEnabled = false, SilentHitPart = "Head", SilentHitChance = 100, SilentFOV = 150,
    SilentAutoShoot = false, SilentFollowMuzzle = false, SilentWallCheck = true,
    Silent360 = false,

    BackshootEnabled = false,
    OrbitSpeed = 3, OrbitRadius = 5, OrbitHeight = 1, OrbitDelay = 0, OrbitDeathRespawn = true,

    -- Ragebot
    RageEnabled = false, RageAutoTarget = false, RageAutoShoot = true,
    RageHitPart = "Head", RageShootAttempts = 1, RagePredict = false, RagePredictMul = 1.2,

    -- VoidSpam
    VoidSpamEnabled = false, VoidShootMin = 1, VoidShootMax = 1,
    VoidHideMin = 1, VoidHideMax = 1, VoidHideReload = true,

    AntiAimEnabled = false, AntiAimYaw = "jitter", AntiAimPitch = "jitter",
    AntiAimAngle = "none", AntiAimCustomAngle = 0,
    AntiAimMinSpeed = 10, AntiAimMaxSpeed = 20,
    AntiAimMinAngle = 30, AntiAimMaxAngle = 60,
    AntiAimRandomAngle = false, AntiAimUnderground = false,

    AimEnabled = false, AimHitPart = "Head", AimFOV = 300, AimWallCheck = false,
    MouseAim = true, MouseSens = 1.0, MouseDeadzone = 2,
    MouseMaxStep = 200, MouseSmooth = 0.5, AimStuckTime = 3,

    CrosshairEnabled = false, CrosshairColor = Color3.fromRGB(0, 200, 255),
    CrosshairShowLines = true, CrosshairSpinSpeed = 150, CrosshairMode = "static",

    InfJump = false, JumpPower = 50, WalkSpeed = 16,
    FlyEnabled = false, FlySpeed = 50, Noclip = false,
    VelocityWalkEnabled = false, VelocityWalkKey = false, VelocityWalkSpeed = 30,
    VelocityFlyEnabled = false, VelocityFlyKey = false, VelocityFlySpeed = 50,

    AntiKatana = false, NoCooldown = false, NoSpread = false, NoRecoil = false,
    MaxAccuracy = false, RapidAttack = false, NoMuzzleFlash = false,

    DeviceSpoof = false, DeviceType = "PC",

    -- ESP
    ESPEnabled = true, ShowName = true, ShowDistance = true, ShowHealth = true,
    ShowTracer = true, ShowSkeleton = true, ShowBox = true, ShowBoxFill = false,
    ShowBoxGlow = false, ShowChams = false,
    MaxDistance = 2000, HueSpeed = 0.25,
    BoxColor1 = Color3.fromRGB(255, 255, 255), BoxColor2 = Color3.fromRGB(255, 255, 255),
    FillColor1 = Color3.fromRGB(255, 255, 255), FillColor2 = Color3.fromRGB(0, 0, 0),
    FillTransparency = 0.7, FillAnimated = false, FillRotation = 0, FillSpeed = 1,
    GlowColor1 = Color3.fromRGB(255, 255, 255), GlowColor2 = Color3.fromRGB(255, 255, 255),
    GlowTransparency = 0.5,
    HealthColor1 = Color3.fromRGB(0, 255, 0), HealthColor2 = Color3.fromRGB(255, 255, 0), HealthColor3 = Color3.fromRGB(255, 0, 0),
    SkeletonColor1 = Color3.fromRGB(255, 255, 255), SkeletonColor2 = Color3.fromRGB(255, 255, 255), SkeletonThickness = 1,
    TracerColor1 = Color3.fromRGB(255, 255, 255), TracerColor2 = Color3.fromRGB(255, 255, 255), TracerThickness = 1,
    ChamsColor1 = Color3.fromRGB(255, 255, 255), ChamsColor2 = Color3.fromRGB(255, 255, 255), ChamsTransparency = 0,
    NameColor = Color3.fromRGB(255, 255, 255), NameColor2 = Color3.fromRGB(255, 255, 255),
    DistanceColor = Color3.fromRGB(255, 255, 255), DistanceColor2 = Color3.fromRGB(255, 255, 255),
    ToolColor = Color3.fromRGB(255, 255, 255), ToolColor2 = Color3.fromRGB(255, 255, 255),
    ShowTools = false,

    -- Hit Effects
    HitEffectsEnabled = false, HitEffectColor = Color3.fromRGB(159, 133, 195),
    HitEffectStyles = {Particles = true}, HitEffectFloatSpeed = 7,
    HitEffectAliveTime = 2.8, HitEffectAliveScale = 1,

    -- Hit Sounds
    HitSoundEnabled = false, HitSoundStyle = "Rust HS", HitSoundVolume = 0.5, HitSoundPitch = 1.0,
    DisableGunSounds = false,

    -- Hit Notifications
    HitNotifEnabled = false, HitNotifColor = Color3.fromRGB(235, 235, 235),
    HitNotifTextSize = 14, HitNotifMaxVisible = 8, HitNotifDuration = 3, HitNotifStackGap = 6,
    HitNotifPosition = "Top Left", HitNotifOffsetX = 12, HitNotifOffsetY = 12,
    HitNotifInAnim = "fade bounce", HitNotifOutAnim = "fade",
    HitNotifInDur = 0.52, HitNotifOutDur = 0.38,

    -- Bullet Tracers
    BulletTracerEnabled = true, BulletTracerColor = Color3.fromRGB(255, 255, 255),
    BulletTracerStyle = "Line", BulletTracerDuration = 3, BulletTracerSize = 1, BulletTracerFadeTime = 0.5,

    -- ViewModel
    GunChamsEnabled = false, ArmChamsEnabled = false, DisableArmsEnabled = false,
    GunOutlineEnabled = false, ArmOutlineEnabled = false,
    GunMaterial = "Neon", ArmMaterial = "ForceField",
    GunColor1 = Color3.fromRGB(255, 255, 255), GunColor2 = Color3.fromRGB(255, 255, 255), GunColor3 = Color3.fromRGB(255, 255, 255),
    ArmColor1 = Color3.fromRGB(255, 255, 255), ArmColor2 = Color3.fromRGB(255, 255, 255), ArmColor3 = Color3.fromRGB(255, 255, 255),
    GunChamSpeed = 1, ArmChamSpeed = 1, GunChamTransparency = 0, ArmChamTransparency = 0,
    GunOutlineColor1 = Color3.fromRGB(255, 255, 255), GunOutlineColor2 = Color3.fromRGB(255, 255, 255), GunOutlineColor3 = Color3.fromRGB(255, 255, 255),
    ArmOutlineColor1 = Color3.fromRGB(255, 255, 255), ArmOutlineColor2 = Color3.fromRGB(255, 255, 255), ArmOutlineColor3 = Color3.fromRGB(255, 255, 255),

    -- World / Lighting
    LightingEnabled = false, LightAmbient = { Enabled = false, Color = Color3.fromRGB(255, 255, 255) },
    LightOutdoorAmbient = { Enabled = false, Color = Color3.fromRGB(255, 255, 255) },
    LightGlobalShadows = { Enabled = true }, LightShadowSoftness = { Enabled = false, Value = 0.2 },
    LightSunColor = { Enabled = false, Color = Color3.fromRGB(255, 255, 255) },
    LightColorShiftTop = { Enabled = false, Color = Color3.fromRGB(255, 255, 255) },
    LightColorShiftBottom = { Enabled = false, Color = Color3.fromRGB(255, 255, 255) },
    LightClockTime = { Enabled = false, Value = 12 },
    LightFog = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Start = 0, End = 100 },
    LightColorCorrection = { Enabled = false, Contrast = 0, Saturation = 0, Brightness = 0 },
    LightBloom = { Enabled = false, Multiplier = 0.3, Size = 4, Threshold = 0.7 },

    AtmosphereEnabled = false, AtmosphereDensity = 0.3, AtmosphereOffset = 0.25,
    AtmosphereHaze = 0.78, AtmosphereGlare = 0.15,
    AtmosphereColor = Color3.fromRGB(140, 160, 190), AtmosphereDecay = Color3.fromRGB(90, 110, 140),

    SkyboxEnabled = false, SkyboxSelection = "Default",
    SkyboxDisabledElements = {},

    AspectRatioEnabled = false, AspectRatioX = 13, AspectRatioY = 10,

    WeatherEnabled = false, WeatherEffects = {},
    WeatherColor = Color3.fromRGB(255, 255, 255), WeatherRate = 100,
    WeatherSpeedMin = 40, WeatherSpeedMax = 60, WeatherSizeMin = 0.33, WeatherSizeMax = 0.40,
    WeatherOpacityMin = 50, WeatherOpacityMax = 100, WeatherSpread = 0,
    WeatherBrightness = 100, WeatherEmission = 50, WeatherGlow = 0, WeatherSizeScale = 1,

    -- Profile Spoof
    LevelEnabled = false, LevelValue = 9999,
    WinStreakEnabled = false, WinStreakValue = 9999,
    NameSpoofEnabled = false, NameSpoofValue = "hi", NameSpoofVerified = false, NameSpoofPremium = false,
    SkinChangerEnabled = false, SkinChangerUserId = "1",
    FPSSpoofEnabled = false, FPSSpoofValue = "1", FPSSpoofFraud = false,
    MSSpoofEnabled = false, MSSpoofValue = "1", MSSpoofFraud = false,
    RegionSpoofEnabled = false, RegionSpoofValue = "v3hub.cc",

    -- Anim Player
    AnimEnabled = false, AnimServerVisible = true, AnimJitter = false, JitterSpeed = 0.1,
    AnimLoop = true, AnimAutoRespawn = true,
    AnimForceID = "96579993895076", AnimJitterID = "12081949817271",
    AnimSpeed = 2,

    -- Self Material
    SlfMtrlEnabled = false,
    SlfMtrlColor1 = Color3.fromRGB(255, 255, 255), SlfMtrlColor2 = Color3.fromRGB(255, 255, 255), SlfMtrlColor3 = Color3.fromRGB(255, 255, 255),
    SlfMtrlMaterial = "Neon", SlfMtrlTransparency = 0.1, SlfMtrlPulseSpeed = 3,

    -- Textures
    SmoothTextures = false, DarkTextures = false, TransparentTextures = false, TransparentStrength = 0.6,

    -- Misc
    HandicapsEnabled = false, AntiTripEnabled = false, AntiFlashbangEnabled = false,
    TeamCheck = true, AntiAFK = true, ModDetector = true,
}

local hasMouseMoveRel = type(mousemoverel) == "function"

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

-- ========== Silent Aim ==========
local silentLastFire = 0
local silentFireCD = 0.01

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
                if d < bestD then best, bestD = p, d end
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
                if d <= S.SilentFOV and d < bestD then best, bestD = p, d end
            end
        end
    end
    return best
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
    local data = {
        [utf8.char(1)] = {
            [utf8.char(0)] = Utility:EncodeCFrame(CFrame.new(root.Position, part.Position)),
            [utf8.char(1)] = Utility:EncodeCFrame(CFrame.new(root.Position, part.Position)),
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
    if not S.SilentWallCheck then return target ~= nil end
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

-- ========== 瞬移繞圈 ==========
local backshoot = { connection = nil, target = nil, origCFrame = nil, armedAt = 0 }
local backshootMonitorConn = nil
local orbit = { angle = 0 }

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

local function targetAlive(ch)
    if not ch or not ch.Parent then return false end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if not ch:FindFirstChild("HumanoidRootPart") then return false end
    return true
end

local function backshootLoop()
    if backshoot.connection then backshoot.connection:Disconnect() end
    backshoot.connection = RunService.Heartbeat:Connect(function(dt)
        if not S.BackshootEnabled then return end
        if tick() - backshoot.armedAt < S.OrbitDelay then return end
        local myChar = LP.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
        if not backshoot.target then return end
        local tr = backshoot.target:FindFirstChild("HumanoidRootPart")
        if not tr then return end
        orbit.angle = orbit.angle + S.OrbitSpeed * dt * math.pi * 2
        if orbit.angle > math.pi * 2 then orbit.angle = orbit.angle - math.pi * 2 end
        local offset = Vector3.new(
            math.cos(orbit.angle) * S.OrbitRadius,
            S.OrbitHeight,
            math.sin(orbit.angle) * S.OrbitRadius
        )
        pcall(function()
            myChar.HumanoidRootPart.CFrame = CFrame.new(tr.Position + offset, tr.Position)
        end)
    end)
end

local function stopBS()
    if backshoot.connection then backshoot.connection:Disconnect(); backshoot.connection = nil end
end

local function clearBackshootTarget(restorePos)
    if restorePos then
        local mc = LP.Character
        if mc and mc:FindFirstChild("HumanoidRootPart") and backshoot.origCFrame then
            pcall(function() mc.HumanoidRootPart.CFrame = backshoot.origCFrame end)
        end
    end
    backshoot.target = nil
    backshoot.origCFrame = nil
    stopBS()
end

local function startContinuousBackshoot()
    if backshootMonitorConn then backshootMonitorConn:Disconnect(); backshootMonitorConn = nil end
    backshootMonitorConn = RunService.Heartbeat:Connect(function()
        if not S.BackshootEnabled then return end
        local mc = LP.Character
        if not mc or not mc:FindFirstChild("HumanoidRootPart") then return end
        if backshoot.target and not targetAlive(backshoot.target) then
            clearBackshootTarget(false)
        end
        if not backshoot.target then
            local target = closestPlayerBS()
            if target then
                backshoot.target = target
                backshoot.origCFrame = mc.HumanoidRootPart.CFrame
                orbit.angle = 0
                backshoot.armedAt = tick()
                backshootLoop()
            end
        end
    end)
end

local function releaseBackshoot()
    if backshootMonitorConn then backshootMonitorConn:Disconnect(); backshootMonitorConn = nil end
    clearBackshootTarget(true)
end

LP.CharacterAdded:Connect(function(char)
    backshoot.target = nil
    backshoot.origCFrame = nil
    stopBS()
    if not S.BackshootEnabled or not S.OrbitDeathRespawn then return end
    pcall(function()
        char:WaitForChild("HumanoidRootPart", 5)
        char:WaitForChild("Humanoid", 5)
    end)
    task.wait(1.0 + S.OrbitDelay)
    if S.BackshootEnabled then
        pcall(startContinuousBackshoot)
    end
end)

LP.CharacterRemoving:Connect(function()
    backshoot.target = nil
    backshoot.origCFrame = nil
    stopBS()
end)

-- ========== Ragebot ==========
local Rage = {
    target = nil, targetPlayer = nil, immune = false, syncing = false, syncConn = nil,
    savedCFrame = nil, orbitAngle = 0, serverPos = nil,
    velocity = Vector3.new(0,0,0), lastPos = nil, lastTime = 0,
    lastFire = 0, voidPhase = nil, voidLastSwitch = 0, voidDuration = 0,
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
    if not S.RagePredict or not part then return part and part.Position or Vector3.new() end
    local base = part.Position
    local dist = (base - origin).Magnitude
    local ping = 0
    pcall(function()
        ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
    end)
    local total = (dist / 3000 + ping) * S.RagePredictMul
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
    local lf = getLocalFighter()
    if not lf or not lf.EquippedItem then return end
    if not Rage.target or not rageValidChar(Rage.target) then return end
    if Rage.immune then return end
    local now = tick()
    if now - Rage.lastFire < 0.05 then return end
    local part = getHitPartName(Rage.target, S.RageHitPart)
    if not part then return end
    local myChar = LP.Character
    local root = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local shootPos = Rage.serverPos or root.Position
    local targetPos = ragePredictPos(part, shootPos)
    local objId = lf.EquippedItem:Get("ObjectID")
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
        if not Rage.savedCFrame then Rage.savedCFrame = hrp.CFrame end
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
            Rage.orbitAngle = Rage.orbitAngle + 9000 * dt
            Rage.serverPos = root.Position + Vector3.new(0, 2, 0)
            pcall(function()
                hrp.CFrame = CFrame.new(Rage.serverPos)
            end)
        end
        rageUpdateVelocity()
        if S.RageAutoShoot then rageFire() end
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

-- ========== 反瞄準 ==========
local antiAimState = { frameCounter = 0, smoothYaw = 0, smoothPitch = 0, undergroundOldPos = nil }

local function getRandomInRange(mn, mx)
    return mn + math.random() * (mx - mn)
end

local function calcAntiAimYaw()
    local yaw = 0
    local currentTime = tick()
    if S.AntiAimYaw == "jitter" then
        local minA = math.rad(S.AntiAimMinAngle)
        local maxA = math.rad(S.AntiAimMaxAngle)
        if S.AntiAimRandomAngle then yaw = getRandomInRange(-maxA, maxA)
        else yaw = math.random() > 0.5 and minA or -minA end
    elseif S.AntiAimYaw == "spinbot" then
        local speed = getRandomInRange(S.AntiAimMinSpeed / 10, S.AntiAimMaxSpeed / 10)
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
        pitch = math.sin(tick() * (S.AntiAimMaxSpeed / 10)) * math.rad(S.AntiAimMaxAngle)
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
    elseif S.AntiAimAngle == "custom" then roll = math.rad(S.AntiAimCustomAngle)
    end
    return roll
end

local function getFloorBelowPosition(pos)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local ch = LP.Character
    if ch then rayParams.FilterDescendantsInstances = {ch} end
    local res = W:Raycast(pos, Vector3.new(0, -500, 0), rayParams)
    if res then
        return CFrame.new(Vector3.new(pos.X, res.Position.Y - 2, pos.Z))
    end
    return nil
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
    if S.AntiAimUnderground then
        antiAimState.undergroundOldPos = root.CFrame
        local floor = getFloorBelowPosition(root.Position)
        if floor then pcall(function() root.CFrame = floor end) end
    end
end)

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
    local cx, cy = C.ViewportSize.X/2, C.ViewportSize.Y/2
    for _, p in ipairs(getEnemies()) do
        local e = {model = p.Character, player = p}
        local part = getAimPart(e)
        if part then
            local sp, on = worldToScreen(part.Position)
            if on then
                local d = math.sqrt((sp.X - cx)^2 + (sp.Y - cy)^2)
                if d <= S.AimFOV and d < bestDist and hasLOS(part, e.model) then
                    best, bestDist = e, d
                end
            end
        end
    end
    return best
end

local AIMBOT_BIND = "v3HubMouseAim"
RunService:BindToRenderStep(AIMBOT_BIND, 201, function(dt)
    if not S.AimEnabled or not S.MouseAim or not hasMouseMoveRel then return end
    if not aimTarget or not isAliveEntry(aimTarget) then return end
    local part = getAimPart(aimTarget)
    if not part then return end
    local sp, on = worldToScreen(part.Position)
    if not on then return end
    local cx, cy = C.ViewportSize.X/2, C.ViewportSize.Y/2
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

-- ========== ESP（完整版）==========
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
    nameLbl.TextColor3 = S.NameColor
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
    distLbl.TextColor3 = S.DistanceColor
    distLbl.TextSize = 12
    distLbl.Font = Enum.Font.Code
    distLbl.TextStrokeTransparency = 0
    distLbl.Text = ""
    distLbl.Size = UDim2.fromOffset(220, 16)
    distLbl.Position = UDim2.new(0.5, -110, 1, 2)
    distLbl.TextXAlignment = Enum.TextXAlignment.Center
    distLbl.Parent = holder

    local toolLbl = Instance.new("TextLabel")
    toolLbl.BackgroundTransparency = 1
    toolLbl.TextColor3 = S.ToolColor
    toolLbl.TextSize = 12
    toolLbl.Font = Enum.Font.Code
    toolLbl.TextStrokeTransparency = 0
    toolLbl.Text = ""
    toolLbl.Size = UDim2.fromOffset(120, 16)
    toolLbl.Position = UDim2.new(1, 4, 0, 0)
    toolLbl.TextXAlignment = Enum.TextXAlignment.Left
    toolLbl.Parent = holder

    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = espGui
    local stroke = Instance.new("UIStroke")
    stroke.Color = S.BoxColor1
    stroke.Thickness = 1.5
    stroke.Parent = box

    local corners = {}
    for i = 1, 4 do
        local c = Instance.new("Frame")
        c.Size = UDim2.fromOffset(10, 2)
        c.BackgroundColor3 = S.BoxColor1
        c.BorderSizePixel = 0
        c.ZIndex = 3
        c.Parent = box
        corners[i] = c
    end
    corners[1].Position = UDim2.new(0, 0, 0, 0)
    corners[2].Position = UDim2.new(1, -10, 0, 0)
    corners[3].Position = UDim2.new(0, 0, 1, -2)
    corners[4].Position = UDim2.new(1, -10, 1, -2)

    local filled = Instance.new("Frame")
    filled.BackgroundColor3 = Color3.new(1, 1, 1)
    filled.BackgroundTransparency = S.FillTransparency
    filled.BorderSizePixel = 0
    filled.Visible = false
    filled.ZIndex = 1
    filled.Parent = espGui
    local fillGrad = Instance.new("UIGradient")
    fillGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, S.FillColor1),
        ColorSequenceKeypoint.new(1, S.FillColor2),
    })
    fillGrad.Parent = filled

    local hbBg = Instance.new("Frame")
    hbBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    hbBg.BorderSizePixel = 0
    hbBg.Size = UDim2.fromOffset(3, 100)
    hbBg.Visible = false
    hbBg.Parent = holder
    local hbBar = Instance.new("Frame")
    hbBar.BackgroundColor3 = S.HealthColor1
    hbBar.BorderSizePixel = 0
    hbBar.Size = UDim2.new(1, 0, 1, 0)
    hbBar.Parent = hbBg

    local tracer = Instance.new("Frame")
    tracer.BackgroundColor3 = S.TracerColor1
    tracer.BorderSizePixel = 0
    tracer.Visible = false
    tracer.ZIndex = 0
    tracer.Parent = espGui

    local skelLines = {}
    for i = 1, #SKEL_BONES do
        local line = Instance.new("Frame")
        line.BackgroundColor3 = S.SkeletonColor1
        line.BorderSizePixel = 0
        line.Visible = false
        line.ZIndex = 1
        line.Parent = espGui
        skelLines[i] = line
    end

    local cham = nil

    local d = {
        holder = holder, name = nameLbl, dist = distLbl, tool = toolLbl,
        box = box, stroke = stroke, corners = corners,
        filled = filled, fillGrad = fillGrad,
        hbBg = hbBg, hbBar = hbBar, tracer = tracer, skel = skelLines, cham = nil,
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
    d.filled.Visible = false
    d.tracer.Visible = false
    d.hbBg.Visible = false
    for _, l in ipairs(d.skel) do l.Visible = false end
    if d.cham then d.cham.Enabled = false end
end

local function lerpColor(a, b, t)
    return Color3.new(a.R + (b.R-a.R)*t, a.G + (b.G-a.G)*t, a.B + (b.B-a.B)*t)
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
    line.Size = UDim2.fromOffset(math.floor(len), S.SkeletonThickness)
    line.Position = UDim2.fromOffset(math.floor(mid.X - len / 2), math.floor(mid.Y))
    line.Rotation = math.deg(math.atan2(bv.Y - av.Y, bv.X - av.X))
end

local function getPlayerWeapon(player)
    if not player then return "None" end
    local vm = W:FindFirstChild("ViewModels")
    if not vm then return "None" end
    local pn = player.Name
    local function fromName(n)
        local parts = {}
        for part in n:gmatch("[^-]+") do table.insert(parts, part:match("^%s*(.-)%s*$")) end
        if #parts >= 2 and parts[1] == pn then return parts[2] end
        return nil
    end
    for _, child in ipairs(vm:GetChildren()) do
        local w = fromName(child.Name)
        if w then return w end
    end
    local fp = vm:FindFirstChild("FirstPerson")
    if fp then
        for _, child in ipairs(fp:GetChildren()) do
            local w = fromName(child.Name)
            if w then return w end
        end
    end
    return "None"
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
                    local co2 = lerpColor(S.BoxColor1, S.BoxColor2, (math.sin(tGlobal * 3) + 1) / 2)

                    d.holder.Position = UDim2.fromOffset(math.floor(cx - wPx / 2), math.floor(cy - hPx / 2))
                    d.holder.Size = UDim2.fromOffset(math.floor(wPx), math.floor(hPx))
                    d.holder.Visible = true

                    d.name.Visible = S.ShowName
                    if S.ShowName then d.name.Text = p.Name end
                    d.dist.Visible = S.ShowDistance
                    if S.ShowDistance then d.dist.Text = string.format("[%d]", math.floor(dist)) end
                    d.tool.Visible = S.ShowTools
                    if S.ShowTools then d.tool.Text = getPlayerWeapon(p) end

                    if S.ShowBox then
                        d.box.Visible = true
                        d.box.Position = UDim2.fromOffset(math.floor(cx - wPx / 2), math.floor(cy - hPx / 2))
                        d.box.Size = UDim2.fromOffset(math.floor(wPx), math.floor(hPx))
                        d.stroke.Color = co2
                        for _, c in ipairs(d.corners) do c.BackgroundColor3 = co2 end
                    else
                        d.box.Visible = false
                    end

                    if S.ShowBoxFill then
                        d.filled.Visible = true
                        d.filled.BackgroundTransparency = S.FillTransparency
                        d.filled.Position = UDim2.fromOffset(math.floor(cx - wPx / 2), math.floor(cy - hPx / 2))
                        d.filled.Size = UDim2.fromOffset(math.floor(wPx), math.floor(hPx))
                        d.fillGrad.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, S.FillColor1),
                            ColorSequenceKeypoint.new(1, S.FillColor2),
                        })
                        if S.FillAnimated then
                            d.fillGrad.Rotation = (math.sin(tGlobal * S.FillSpeed) * 90) + S.FillRotation
                        else
                            d.fillGrad.Rotation = S.FillRotation
                        end
                    else
                        d.filled.Visible = false
                    end

                    if S.ShowHealth and hum.MaxHealth > 0 then
                        local rt = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        d.hbBg.Visible = true
                        d.hbBg.Size = UDim2.fromOffset(3, math.floor(hPx))
                        d.hbBg.Position = UDim2.new(0, -6, 0, 0)
                        d.hbBar.Size = UDim2.new(1, 0, rt, 0)
                        d.hbBar.Position = UDim2.new(0, 0, 1 - rt, 0)
                        local hpc
                        if rt > 0.5 then
                            hpc = lerpColor(S.HealthColor2, S.HealthColor1, (rt - 0.5) * 2)
                        else
                            hpc = lerpColor(S.HealthColor3, S.HealthColor2, rt * 2)
                        end
                        d.hbBar.BackgroundColor3 = hpc
                    else
                        d.hbBg.Visible = false
                    end

                    if S.ShowTracer then
                        local from = Vector2.new(C.ViewportSize.X / 2, C.ViewportSize.Y)
                        local to = Vector2.new(cx, cy + hPx / 2)
                        local mid = (from + to) / 2
                        local len = (to - from).Magnitude
                        local ang = math.deg(math.atan2(to.Y - from.Y, to.X - from.X))
                        d.tracer.Visible = true
                        d.tracer.BackgroundColor3 = lerpColor(S.TracerColor1, S.TracerColor2, 0.5)
                        d.tracer.Size = UDim2.fromOffset(math.floor(len), S.TracerThickness)
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
                                local mid = worldToScreen(a.Position)
                                local skelCo = lerpColor(S.SkeletonColor1, S.SkeletonColor2, 0.5)
                                drawSkelLine(ln, a.Position, b.Position, skelCo)
                            else
                                ln.Visible = false
                            end
                        end
                    else
                        for _, l in ipairs(d.skel) do l.Visible = false end
                    end

                    if S.ShowChams then
                        if not d.cham or not d.cham.Parent then
                            d.cham = Instance.new("Highlight")
                            d.cham.Name = "ESPHighlight"
                            d.cham.Adornee = char
                            d.cham.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            d.cham.Parent = char
                        end
                        d.cham.Enabled = true
                        d.cham.FillColor = S.ChamsColor1
                        d.cham.OutlineColor = S.ChamsColor2
                        d.cham.FillTransparency = S.ChamsTransparency
                        d.cham.OutlineTransparency = math.clamp(S.ChamsTransparency, 0, 1)
                    elseif d.cham then
                        d.cham.Enabled = false
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

-- ========== Bullet Tracers ==========
local tracers = {}
local tracerConn = nil
local tracerLastCreations = {}
local tracerDedupeInterval = 0.1

local tracerTextureAssets = {
    Line = "", Beam = "rbxassetid://12781852245", Lightning = "rbxassetid://446111271",
    Heartrate = "rbxassetid://5830549480", Chain = "rbxassetid://9632168658",
    Glitch = "rbxassetid://8089467613", Swirl = "rbxassetid://5638168605",
    Neon = "rbxassetid://6361963422", Plasma = "rbxassetid://8993645509",
    Laser = "rbxassetid://14549123968",
}

local function destroyTracer(t)
    if t.IsLine then
        if t.Outline then t.Outline:Remove() end
        if t.Line then t.Line:Remove() end
    else
        if t.Beam then t.Beam:Destroy() end
        if t.Attachment0 then t.Attachment0:Destroy() end
        if t.Attachment1 then t.Attachment1:Destroy() end
    end
end

local function makeLineTracer(pos3, endPos)
    local outline = Drawing.new("Line")
    outline.Thickness = 4 * S.BulletTracerSize
    outline.Color = Color3.new(0, 0, 0)
    outline.Transparency = 1
    outline.Visible = false
    local line = Drawing.new("Line")
    line.Thickness = 2 * S.BulletTracerSize
    line.Color = S.BulletTracerColor
    line.Transparency = 1
    line.Visible = false
    table.insert(tracers, {
        IsLine = true, Outline = outline, Line = line,
        StartPos = pos3, EndPos = endPos,
        Lifetime = S.BulletTracerDuration, FadeTime = S.BulletTracerFadeTime,
        CreatedTime = tick(),
    })
end

local function makeBeamTracer(pos3, endPos)
    local a0 = Instance.new("Attachment")
    a0.Parent = W.Terrain
    local a1 = Instance.new("Attachment")
    a1.Parent = W.Terrain
    local beam = Instance.new("Beam")
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.Color = ColorSequence.new(S.BulletTracerColor)
    local baseW = S.BulletTracerStyle == "Laser" and 0.02 or 0.15
    beam.Width0 = baseW * S.BulletTracerSize
    beam.Width1 = baseW * S.BulletTracerSize
    beam.Transparency = NumberSequence.new(0)
    beam.FaceCamera = true
    beam.LightEmission = 0.8
    beam.LightInfluence = 0.2
    local tex = tracerTextureAssets[S.BulletTracerStyle]
    if tex and tex ~= "" then
        beam.Texture = tex
        beam.TextureLength = 4
        beam.TextureSpeed = 1
    end
    beam.Parent = W.Terrain
    a0.WorldPosition = pos3
    a1.WorldPosition = endPos
    table.insert(tracers, {
        IsLine = false, Beam = beam, Attachment0 = a0, Attachment1 = a1,
        StartPos = pos3, EndPos = endPos,
        Lifetime = S.BulletTracerDuration, FadeTime = S.BulletTracerFadeTime,
        CreatedTime = tick(),
    })
end

local function makeTracer(pos3, endPos)
    if not S.BulletTracerEnabled or not pos3 or not endPos then return end
    local kx = math.floor(pos3.X * 5 + 0.5)
    local ky = math.floor(pos3.Y * 5 + 0.5)
    local kz = math.floor(pos3.Z * 5 + 0.5)
    local ex = math.floor(endPos.X * 5 + 0.5)
    local ey = math.floor(endPos.Y * 5 + 0.5)
    local ez = math.floor(endPos.Z * 5 + 0.5)
    local key = kx * 1e9 + ky * 1e6 + kz * 1e3 + ex + ey * 1e-3 + ez * 1e-6
    local now = tick()
    if tracerLastCreations[key] and (now - tracerLastCreations[key]) < tracerDedupeInterval then return end
    tracerLastCreations[key] = now
    if S.BulletTracerStyle == "Line" then makeLineTracer(pos3, endPos)
    else makeBeamTracer(pos3, endPos) end
end

local function updateTracers()
    if #tracers == 0 then return end
    local now = tick()
    local i = #tracers
    while i >= 1 do
        local tr = tracers[i]
        local age = now - tr.CreatedTime
        if age >= tr.Lifetime then
            destroyTracer(tr)
            tracers[i] = tracers[#tracers]
            tracers[#tracers] = nil
        else
            local fadeAlpha = 1
            local fadeStart = tr.Lifetime - tr.FadeTime
            if age >= fadeStart then
                fadeAlpha = 1 - math.clamp((age - fadeStart) / tr.FadeTime, 0, 1)
            end
            if tr.IsLine then
                local s2, onS = worldToScreen(tr.StartPos)
                local e2, onE = worldToScreen(tr.EndPos)
                if onS and onE then
                    local fv2s = Vector2.new(s2.X, s2.Y)
                    local fv2e = Vector2.new(e2.X, e2.Y)
                    tr.Outline.From = fv2s
                    tr.Outline.To = fv2e
                    tr.Outline.Transparency = fadeAlpha
                    tr.Outline.Visible = true
                    tr.Line.From = fv2s
                    tr.Line.To = fv2e
                    tr.Line.Transparency = fadeAlpha
                    tr.Line.Visible = true
                else
                    tr.Outline.Visible = false
                    tr.Line.Visible = false
                end
            else
                tr.Attachment0.WorldPosition = tr.StartPos
                tr.Attachment1.WorldPosition = tr.EndPos
                tr.Beam.Transparency = NumberSequence.new(1 - fadeAlpha)
            end
        end
        i = i - 1
    end
end

tracerConn = RunService.RenderStepped:Connect(updateTracers)

-- 監聽本地開槍
local function hookTracerEffect()
    pcall(function()
        local TracerEffect = require(LP.PlayerScripts.Modules.TracerEffect)
        local origPlay = TracerEffect.Play
        TracerEffect.Play = function(self, tracerData, config, extraData)
            if S.BulletTracerEnabled and tracerData and tracerData.IsLocal and tracerData.RaycastResults then
                local mp = muzzlePos()
                if mp then
                    for _, hit in ipairs(tracerData.RaycastResults) do
                        if hit.Position then
                            makeTracer(mp, hit.Position)
                        end
                    end
                end
            end
            return origPlay(self, tracerData, config, extraData)
        end
    end)
end
task.defer(hookTracerEffect)

-- ========== Hit Sounds ==========
local hitSoundFolder = "v3HubHitsounds"
local hitSoundDir = hitSoundFolder .. "/sounds"
local hitSoundFiles = {
    ["Among Us"] = "amongus.mp3", ["Bonk"] = "bonk.mp3", ["Bruh"] = "bruh.mp3",
    ["Fart"] = "fart.mp3", ["Minecraft"] = "minecraft.mp3", ["Neverlose"] = "neverlose.mp3",
    ["Osu"] = "osu.mp3", ["Stars"] = "Stars.mp3", ["Rust HS"] = "rust hs.mp3", ["Vine"] = "vine.mp3",
}
local hitSoundLinks = {
    ["amongus.mp3"] = "https://www.myinstants.com/media/sounds/roblox-death-sound_ytkBL7X.mp3",
    ["minecraft.mp3"] = "https://www.myinstants.com/media/sounds/steve-old-hurt-sound_XKZxUk4.mp3",
    ["bruh.mp3"] = "https://www.myinstants.com/media/sounds/discord-notification.mp3",
    ["fart.mp3"] = "https://www.myinstants.com/media/sounds/fart-moan3.mp3",
    ["neverlose.mp3"] = "https://www.myinstants.com/media/sounds/neverlose-s.mp3",
    ["rust hs.mp3"] = "https://www.myinstants.com/media/sounds/eaolwpzhgsba.mp3",
    ["osu.mp3"] = "https://www.myinstants.com/media/sounds/osu-hit-sound.mp3",
    ["Stars.mp3"] = "https://www.myinstants.com/media/sounds/starshitsound.mp3",
    ["bonk.mp3"] = "https://www.myinstants.com/media/sounds/bonk.mp3",
    ["vine.mp3"] = "https://www.myinstants.com/media/sounds/vine-boom.mp3",
}

task.spawn(function()
    if not isfolder(hitSoundFolder) then makefolder(hitSoundFolder) end
    if not isfolder(hitSoundDir) then makefolder(hitSoundDir) end
    for filename, url in pairs(hitSoundLinks) do
        local fullPath = hitSoundDir .. "/" .. filename
        if not isfile(fullPath) then
            pcall(function() writefile(fullPath, game:HttpGet(url, true)) end)
            task.wait(0.5)
        end
    end
end)

local function playHitSound()
    if not S.HitSoundEnabled then return end
    local filename = hitSoundFiles[S.HitSoundStyle] or "rust hs.mp3"
    local fullPath = hitSoundDir .. "/" .. filename
    if not isfile(fullPath) then return end
    local assetFn = getsynasset or getcustomasset
    if not assetFn then return end
    local ok, soundId = pcall(assetFn, fullPath)
    if not ok or not soundId then return end
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = S.HitSoundVolume
    sound.PlaybackSpeed = S.HitSoundPitch
    sound.Parent = W
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 5)
end

-- 監聽傷害 Billboard
local damageBillboardCache = setmetatable({}, { __mode = "k" })

local function getDamageBillboardInfo(obj)
    if damageBillboardCache[obj] ~= nil then return damageBillboardCache[obj] end
    if not obj:IsA("BillboardGui") then return nil end
    if obj.Name == "FortniteDamageNumber" then return nil end
    local lbl = obj:FindFirstChildWhichIsA("TextLabel", true)
    if not lbl then return nil end
    local dmg = tonumber(lbl.Text)
    if not (dmg and dmg > 0) then return nil end
    local adornee = obj.Adornee or (obj.Parent and obj.Parent:IsA("BasePart") and obj.Parent)
    if not adornee then return nil end
    local info = { lbl = lbl, dmg = dmg, adornee = adornee }
    damageBillboardCache[obj] = info
    return info
end

W.DescendantAdded:Connect(function(obj)
    if not obj:IsA("BillboardGui") then return end
    local info = getDamageBillboardInfo(obj)
    if not info then return end
    task.defer(function()
        if not obj or not obj.Parent then return end
        if S.HitSoundEnabled then playHitSound() end
    end)
end)

-- ========== Hit Effects ==========
local hitEffectHandlers = {}
local activeHitEffectPoses = {}
local X_MIN, X_MAX = -10, 10
local Y_MIN, Y_MAX = 1, 8
local Z_MIN, Z_MAX = -4, 4

local function randFloat(mn, mx) return mn + math.random() * (mx - mn) end

local function pickHitEffectPos(key)
    local occupied = activeHitEffectPoses[key] or {}
    local best, bestDist = nil, -1
    for attempt = 1, 60 do
        local candidate = Vector3.new(randFloat(X_MIN, X_MAX), randFloat(Y_MIN, Y_MAX), randFloat(Z_MIN, Z_MAX))
        local minDist = math.huge
        for _, pos in ipairs(occupied) do
            local d = (candidate - pos).Magnitude
            if d < minDist then minDist = d end
        end
        if minDist >= 5.5 then return candidate end
        if minDist > bestDist then bestDist = minDist best = candidate end
    end
    return best
end

local function getHitEffectPart(adornee)
    if adornee:IsA("BasePart") then return adornee
    elseif adornee:IsA("Attachment") then return adornee.Parent
    elseif adornee:IsA("Model") and adornee.PrimaryPart then return adornee.PrimaryPart
    end
end

local function spawnHitFlash(targetPart, color, brightness, range, duration)
    duration = duration * (S.HitEffectAliveTime / 2.8)
    local light = Instance.new("PointLight")
    light.Name = "HitFlash"
    light.Color = color
    light.Brightness = brightness or 6
    light.Range = range or 14
    light.Parent = targetPart
    game:GetService("TweenService"):Create(light, TweenInfo.new(duration), { Brightness = 0, Range = 0 }):Play()
    game:GetService("Debris"):AddItem(light, duration + 0.1)
end

local function spawnHitRing(targetPart, color, config)
    config = config or {}
    local ring = Instance.new("Part")
    ring.Shape = Enum.PartType.Cylinder
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanQuery = false
    ring.CanTouch = false
    ring.Material = config.Material or Enum.Material.Neon
    ring.Color = color
    ring.Transparency = config.StartTransparency or 0.35
    local startSize = config.StartSize or 0.35
    ring.Size = Vector3.new(0.05, startSize, startSize)
    ring.CFrame = targetPart.CFrame * CFrame.Angles(0, 0, math.rad(90))
    ring.Parent = W.CurrentCamera
    local endSize = config.EndSize or 5
    local duration = (config.Duration or 0.55) * (S.HitEffectAliveTime / 2.8)
    game:GetService("TweenService"):Create(ring, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.05, endSize, endSize),
        Transparency = 1
    }):Play()
    game:GetService("Debris"):AddItem(ring, duration + 0.1)
end

local function spawnHitEmitter(targetPart, config)
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = config.Name or "HitEffect"
    emitter.Texture = config.Texture or "rbxassetid://6603835352"
    if typeof(config.Color) == "ColorSequence" then emitter.Color = config.Color
    else emitter.Color = ColorSequence.new(config.Color or S.HitEffectColor) end
    emitter.LightEmission = config.LightEmission or 1
    emitter.Brightness = config.Brightness or 8
    emitter.LightInfluence = config.LightInfluence or 0
    emitter.Orientation = config.Orientation or Enum.ParticleOrientation.FacingCamera
    emitter.LockedToPart = config.LockedToPart or false
    emitter.Size = config.Size or NumberSequence.new(0.12)
    emitter.Transparency = config.Transparency or NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    emitter.Speed = config.Speed or NumberRange.new(12, 18)
    emitter.SpreadAngle = config.SpreadAngle or Vector2.new(120, 120)
    emitter.EmissionDirection = config.EmissionDirection or Enum.NormalId.Top
    local lifetime = config.Lifetime or NumberRange.new(0.6, 1.2)
    local scale = S.HitEffectAliveTime / 2.8
    emitter.Lifetime = NumberRange.new(lifetime.Min * scale, lifetime.Max * scale)
    emitter.Drag = config.Drag or 2
    emitter.Acceleration = config.Acceleration or Vector3.new(0, 4, 0)
    emitter.RotSpeed = config.RotSpeed or NumberRange.new(0, 0)
    emitter.Rate = 0
    emitter.Enabled = true
    emitter.Parent = targetPart
    emitter:Emit(config.EmitCount or 48)
    game:GetService("Debris"):AddItem(emitter, (config.Cleanup or 4) * scale)
end

hitEffectHandlers["Particles"] = function(adornee, color)
    local targetPart = getHitEffectPart(adornee)
    if not targetPart or not targetPart:IsA("BasePart") then return end
    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = "rbxassetid://6603835352"
    emitter.Color = ColorSequence.new(color)
    emitter.LightEmission = 1
    emitter.Brightness = 13
    emitter.LightInfluence = 0
    emitter.Orientation = Enum.ParticleOrientation.FacingCamera
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.09),
        NumberSequenceKeypoint.new(0.5, 0.135),
        NumberSequenceKeypoint.new(1, 0.068)
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.25, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    emitter.Speed = NumberRange.new(22, 29)
    emitter.SpreadAngle = Vector2.new(130, 130)
    emitter.EmissionDirection = Enum.NormalId.Top
    local life = S.HitEffectAliveTime
    emitter.Lifetime = NumberRange.new(life, life + 0.1)
    emitter.Drag = 3.2
    emitter.Acceleration = Vector3.new(0, 5, 0)
    emitter.Rate = 0
    emitter.Enabled = true
    emitter.Parent = targetPart
    emitter:Emit(64)
    game:GetService("Debris"):AddItem(emitter, life + 0.2)
end

hitEffectHandlers["Fortnite"] = function(adornee, color, damageText)
    local targetPart = getHitEffectPart(adornee)
    if not targetPart then return end
    local key = targetPart
    if not activeHitEffectPoses[key] then activeHitEffectPoses[key] = {} end
    local offset = pickHitEffectPos(key)
    local floatHeight = S.HitEffectFloatSpeed
    local aliveDuration = S.HitEffectAliveTime
    local endOffset = offset + Vector3.new(0, floatHeight, 0)
    table.insert(activeHitEffectPoses[key], offset)

    local bb = Instance.new("BillboardGui")
    bb.Name = "FortniteDamageNumber"
    bb.Size = UDim2.new(0, 70, 0, 40)
    bb.StudsOffset = offset
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.Adornee = targetPart
    bb.Parent = W.CurrentCamera

    local lbl = Instance.new("TextLabel", bb)
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = damageText
    lbl.TextColor3 = color
    lbl.TextTransparency = 1
    lbl.TextStrokeTransparency = 1
    lbl.TextScaled = true
    lbl.FontFace = Font.fromEnum(Enum.Font.GothamBold)

    game:GetService("TweenService"):Create(lbl, TweenInfo.new(0.12), {TextTransparency = 0, TextStrokeTransparency = 0.55}):Play()
    game:GetService("TweenService"):Create(bb, TweenInfo.new(aliveDuration), {StudsOffset = endOffset}):Play()

    task.delay(aliveDuration, function()
        if bb and bb.Parent then bb:Destroy() end
        if activeHitEffectPoses[key] then
            for i, p in ipairs(activeHitEffectPoses[key]) do
                if p == offset then table.remove(activeHitEffectPoses[key], i) break end
            end
            if #activeHitEffectPoses[key] == 0 then activeHitEffectPoses[key] = nil end
        end
    end)
end

hitEffectHandlers["Shockwave"] = function(adornee, color)
    local tp = getHitEffectPart(adornee)
    if not tp then return end
    spawnHitFlash(tp, color, 8, 18, 0.4)
    spawnHitRing(tp, color, {StartSize = 0.5, EndSize = 7, Duration = 0.5})
    spawnHitRing(tp, color, {StartSize = 0.25, EndSize = 5, Duration = 0.35, StartTransparency = 0.55})
end

hitEffectHandlers["Lightning"] = function(adornee, color)
    local tp = getHitEffectPart(adornee)
    if not tp then return end
    local bolt = Color3.new(0.85, 0.92, 1)
    spawnHitFlash(tp, bolt, 14, 22, 0.2)
    spawnHitEmitter(tp, {
        Texture = "rbxassetid://446111271", Color = bolt, Brightness = 16,
        EmitCount = 22, Speed = NumberRange.new(32, 48), SpreadAngle = Vector2.new(18, 18),
        Lifetime = NumberRange.new(0.08, 0.22), Drag = 0.2, Acceleration = Vector3.new(0, -20, 0),
    })
end

hitEffectHandlers["Blood"] = function(adornee, color)
    local tp = getHitEffectPart(adornee)
    if not tp then return end
    local blood = Color3.new(math.clamp(color.R * 0.9 + 0.35, 0, 1), math.clamp(color.G * 0.15, 0, 0.35), math.clamp(color.B * 0.15, 0, 0.35))
    spawnHitEmitter(tp, {
        Texture = "rbxassetid://243660364", Color = blood, EmitCount = 70,
        Speed = NumberRange.new(12, 28), SpreadAngle = Vector2.new(175, 175),
        Lifetime = NumberRange.new(0.7, 1.3), Drag = 5, Acceleration = Vector3.new(0, -22, 0),
    })
end

hitEffectHandlers["Fire"] = function(adornee, color)
    local tp = getHitEffectPart(adornee)
    if not tp then return end
    local fire = Color3.new(math.clamp(color.R + 0.25, 0, 1), math.clamp(color.G * 0.6 + 0.2, 0, 1), math.clamp(color.B * 0.2, 0, 0.4))
    spawnHitFlash(tp, fire, 10, 16, 0.45)
    spawnHitEmitter(tp, {
        Texture = "rbxassetid://241650108",
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 120)),
            ColorSequenceKeypoint.new(0.45, fire),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 20, 10))
        }),
        EmitCount = 55, Speed = NumberRange.new(8, 18), SpreadAngle = Vector2.new(70, 70),
        Lifetime = NumberRange.new(0.45, 0.95), Acceleration = Vector3.new(0, 14, 0),
    })
end

hitEffectHandlers["Stars"] = function(adornee, color)
    local tp = getHitEffectPart(adornee)
    if not tp then return end
    spawnHitFlash(tp, color, 7, 14, 0.3)
    spawnHitEmitter(tp, {
        Texture = "rbxassetid://1084982556", Color = color, EmitCount = 40,
        Speed = NumberRange.new(16, 28), SpreadAngle = Vector2.new(180, 180),
        Lifetime = NumberRange.new(0.6, 1.05), RotSpeed = NumberRange.new(-240, 240), Brightness = 12,
    })
end

hitEffectHandlers["Neon"] = function(adornee, color)
    local tp = getHitEffectPart(adornee)
    if not tp then return end
    spawnHitFlash(tp, color, 16, 20, 0.5)
    spawnHitRing(tp, color, {StartSize = 0.15, EndSize = 4, Duration = 0.35, StartTransparency = 0.15})
end

hitEffectHandlers["Plasma"] = function(adornee, color)
    local tp = getHitEffectPart(adornee)
    if not tp then return end
    local plasmaB = Color3.new(math.clamp(1 - color.R, 0, 1), math.clamp(color.G, 0, 1), math.clamp(color.B + 0.3, 0, 1))
    spawnHitFlash(tp, color, 12, 18, 0.35)
    spawnHitRing(tp, plasmaB, {StartSize = 0.4, EndSize = 5.5, Duration = 0.4, StartTransparency = 0.25})
end

hitEffectHandlers["Sparks"] = function(adornee, color)
    local tp = getHitEffectPart(adornee)
    if not tp then return end
    spawnHitFlash(tp, color, 9, 12, 0.25)
    spawnHitEmitter(tp, {
        Texture = "rbxassetid://12781852245", Color = color, EmitCount = 65,
        Speed = NumberRange.new(22, 42), SpreadAngle = Vector2.new(180, 180),
        Lifetime = NumberRange.new(0.18, 0.5), Drag = 4, Brightness = 14,
        Acceleration = Vector3.new(0, -16, 0),
    })
end

hitEffectHandlers["Confetti"] = function(adornee, color)
    local tp = getHitEffectPart(adornee)
    if not tp then return end
    local c2 = Color3.new(math.clamp(color.R + 0.3, 0, 1), math.clamp(color.G + 0.3, 0, 1), math.clamp(color.B + 0.3, 0, 1))
    local c3 = Color3.new(color.G, color.B, color.R)
    spawnHitEmitter(tp, {
        Texture = "rbxassetid://243660364",
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, color),
            ColorSequenceKeypoint.new(0.33, c2),
            ColorSequenceKeypoint.new(0.66, c3),
            ColorSequenceKeypoint.new(1, c2),
        }),
        EmitCount = 80, Speed = NumberRange.new(14, 30), SpreadAngle = Vector2.new(180, 180),
        Lifetime = NumberRange.new(1.4, 2.4), Drag = 2.5, Acceleration = Vector3.new(0, -10, 0),
        RotSpeed = NumberRange.new(-420, 420),
    })
end

W.DescendantAdded:Connect(function(obj)
    if not S.HitEffectsEnabled then return end
    if not obj:IsA("BillboardGui") then return end
    local info = getDamageBillboardInfo(obj)
    if not info then return end
    task.defer(function()
        if not obj or not obj.Parent then return end
        obj.Enabled = false
        local styles = S.HitEffectStyles
        if type(styles) ~= "table" then styles = {styles} end
        for key, val in pairs(styles) do
            local styleName
            if type(key) == "number" and type(val) == "string" then styleName = val
            elseif val == true then styleName = key end
            if styleName then
                local handler = hitEffectHandlers[styleName]
                if handler then
                    if styleName == "Fortnite" then handler(info.adornee, S.HitEffectColor, info.lbl.Text)
                    else handler(info.adornee, S.HitEffectColor) end
                end
            end
        end
    end)
end)

-- ========== ViewModel Chams ==========
local vmOrigProps = {}
local vmChamLoop = nil
local chamOutlineStore = Instance.new("Folder")
chamOutlineStore.Name = "\0v3ChamOutlines"
chamOutlineStore.Parent = game.CoreGui
local chamOutlineHighlights = {}
local chamOutlineGlowClones = {}
local chamOutlineBloomClones = {}
local vmPartHighlights = {}

local function saveVMOrig(part)
    if vmOrigProps[part] then return end
    vmOrigProps[part] = {
        Material = part.Material, Color = part.Color,
        Transparency = part.Transparency, Reflectance = part.Reflectance,
        TextureID = part:IsA("MeshPart") and part.TextureID or nil,
        textures = {}, surfaceAppearances = {},
    }
    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("Texture") or child:IsA("Decal") then
            vmOrigProps[part].textures[child] = child.Transparency
        elseif child:IsA("SurfaceAppearance") then
            table.insert(vmOrigProps[part].surfaceAppearances, child:Clone())
        end
    end
end

local function restoreVMOrig(part)
    local data = vmOrigProps[part]
    if not data then return end
    pcall(function()
        part.Material = data.Material
        part.Color = data.Color
        part.Transparency = data.Transparency
        part.Reflectance = data.Reflectance or 0
        if part:IsA("MeshPart") and data.TextureID ~= nil then part.TextureID = data.TextureID end
        for child, trans in pairs(data.textures) do
            if child and child.Parent then child.Transparency = trans end
        end
        for _, sa in ipairs(data.surfaceAppearances or {}) do
            if sa and not part:FindFirstChild(sa.Name) then sa:Clone().Parent = part end
        end
    end)
end

local function applyChamPart(part, color, material, trans, aggressive)
    saveVMOrig(part)
    pcall(function()
        part.Material = material
        part.Color = color
        part.Transparency = math.clamp(trans or 0, 0, 1)
        part.Reflectance = 0
        part.LocalTransparencyModifier = 0
        if part:IsA("MeshPart") then part.TextureID = "" end
        for _, child in ipairs(part:GetDescendants()) do
            if aggressive then
                if child:IsA("SurfaceAppearance") or child:IsA("WrapLayer") then child:Destroy()
                elseif child:IsA("Texture") or child:IsA("Decal") then child:Destroy()
                elseif child:IsA("SpecialMesh") or child:IsA("Mesh") then
                    child.TextureId = ""
                    if child:IsA("SpecialMesh") then child.VertexColor = color end
                end
            else
                if child:IsA("Texture") or child:IsA("Decal") then child.Transparency = 1
                elseif child:IsA("SpecialMesh") or child:IsA("Mesh") then child.TextureId = ""
                end
            end
        end
    end)
end

local function lerpC3(a, b, t) return Color3.new(a.R + (b.R-a.R)*t, a.G + (b.G-a.G)*t, a.B + (b.B-a.B)*t) end

local function gradC3(c1, c2, c3, pos, t)
    local cp = (pos + t) % 1
    if cp < 0.33 then return lerpC3(c1, c2, cp / 0.33)
    elseif cp < 0.66 then return lerpC3(c2, c3, (cp - 0.33) / 0.33)
    else return lerpC3(c3, c1, (cp - 0.66) / 0.34) end
end

local function isArmModel(model)
    local segs = {}
    for seg in model.Name:gmatch("[^-]+") do table.insert(segs, seg:match("^%s*(.-)%s*$"):lower()) end
    if #segs >= 2 then
        local tag = segs[2]
        if tag == "arms" or tag == "arm" or tag:find("glove", 1, true) then return true end
        if tag:find("arm", 1, true) and not tag:find("charm", 1, true) and not tag:find("armor", 1, true) then return true end
        return false
    end
    local n = model.Name:lower()
    return n:find("arms", 1, true) ~= nil or n:find("glove", 1, true) ~= nil
end

local function syncOutline(part, color)
    if not part or not part.Parent then return end
    local hl = chamOutlineHighlights[part]
    if not hl or not hl.Parent then
        hl = Instance.new("Highlight")
        hl.Name = "ChamOutline"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = chamOutlineStore
        chamOutlineHighlights[part] = hl
    end
    hl.OutlineColor = color
    hl.OutlineTransparency = 0
    hl.FillColor = color
    hl.FillTransparency = 1
    hl.Adornee = part
end

local function clearOutline(part)
    if chamOutlineHighlights[part] then
        pcall(function() chamOutlineHighlights[part]:Destroy() end)
        chamOutlineHighlights[part] = nil
    end
end

local function clearAllOutlines()
    for part in pairs(chamOutlineHighlights) do clearOutline(part) end
    for part, glow in pairs(chamOutlineGlowClones) do pcall(function() glow:Destroy() end) chamOutlineGlowClones[part] = nil end
    for part, bloom in pairs(chamOutlineBloomClones) do pcall(function() bloom:Destroy() end) chamOutlineBloomClones[part] = nil end
    for part, hl in pairs(vmPartHighlights) do pcall(function() hl:Destroy() end) vmPartHighlights[part] = nil end
end

local chamPhase = { gun = 0, arm = 0, accum = 0 }

local function applyChams(dt)
    if not (S.GunChamsEnabled or S.ArmChamsEnabled or S.GunOutlineEnabled or S.ArmOutlineEnabled or S.DisableArmsEnabled) then
        if next(vmOrigProps) then
            clearAllOutlines()
            for part, _ in pairs(vmOrigProps) do
                if part and part.Parent then restoreVMOrig(part) end
            end
            vmOrigProps = {}
        end
        return
    end
    local vm = W:FindFirstChild("ViewModels")
    if not vm then return end
    local fp = vm:FindFirstChild("FirstPerson")
    if not fp then return end
    chamPhase.accum = chamPhase.accum + (dt or 0)
    if chamPhase.accum >= (1/60) then
        chamPhase.accum = chamPhase.accum - (1/60)
        if S.GunChamsEnabled or S.GunOutlineEnabled then chamPhase.gun = (chamPhase.gun + (1/60) * S.GunChamSpeed) % 1 end
        if S.ArmChamsEnabled or S.ArmOutlineEnabled then chamPhase.arm = (chamPhase.arm + (1/60) * S.ArmChamSpeed) % 1 end
    end
    for _, model in ipairs(fp:GetChildren()) do
        if model:IsA("Model") then
            local isArm = isArmModel(model)
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") and part.Transparency < 0.99 then
                    if S.DisableArmsEnabled and isArm then
                        part.Transparency = 1
                        for _, child in ipairs(part:GetChildren()) do
                            if child:IsA("Texture") or child:IsA("Decal") or child:IsA("SurfaceAppearance") then
                                child.Transparency = 1
                            end
                        end
                        clearOutline(part)
                    else
                        local useChams = (isArm and S.ArmChamsEnabled) or (not isArm and S.GunChamsEnabled)
                        local useOutline = (isArm and S.ArmOutlineEnabled) or (not isArm and S.GunOutlineEnabled)
                        local fillColor, outlineColor
                        if isArm then
                            fillColor = gradC3(S.ArmColor1, S.ArmColor2, S.ArmColor3, 0, chamPhase.arm)
                            outlineColor = gradC3(S.ArmOutlineColor1, S.ArmOutlineColor2, S.ArmOutlineColor3, 0, chamPhase.arm)
                        else
                            fillColor = gradC3(S.GunColor1, S.GunColor2, S.GunColor3, 0, chamPhase.gun)
                            outlineColor = gradC3(S.GunOutlineColor1, S.GunOutlineColor2, S.GunOutlineColor3, 0, chamPhase.gun)
                        end
                        if useChams then
                            local mat = isArm and Enum.Material[S.ArmMaterial] or Enum.Material[S.GunMaterial]
                            local trans = isArm and S.ArmChamTransparency or S.GunChamTransparency
                            applyChamPart(part, fillColor, mat, trans, isArm)
                        elseif not useOutline then
                            restoreVMOrig(part)
                        end
                        if useOutline then
                            syncOutline(part, outlineColor)
                        else
                            clearOutline(part)
                        end
                    end
                end
            end
        end
    end
end

local CHAM_BIND = "v3HubChams"
local function updChams()
    if S.GunChamsEnabled or S.ArmChamsEnabled or S.GunOutlineEnabled or S.ArmOutlineEnabled or S.DisableArmsEnabled then
        if not vmChamLoop then
            local ok = pcall(function()
                RunService:UnbindFromRenderStep(CHAM_BIND)
                RunService:BindToRenderStep(CHAM_BIND, Enum.RenderPriority.Last.Value, applyChams)
            end)
            if not ok then vmChamLoop = RunService.RenderStepped:Connect(applyChams) end
        end
    else
        pcall(function() RunService:UnbindFromRenderStep(CHAM_BIND) end)
        if vmChamLoop then vmChamLoop:Disconnect() vmChamLoop = nil end
        clearAllOutlines()
        for part, _ in pairs(vmOrigProps) do
            if part and part.Parent then restoreVMOrig(part) end
        end
        vmOrigProps = {}
    end
end

-- ========== 移動 ==========
local flyBP, flyBG = nil, nil
local flyActive = false

local function cleanupFly()
    if flyBP then flyBP:Destroy() flyBP = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
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

-- Velocity Walk / Fly
RunService.Heartbeat:Connect(function(dt)
    if S.VelocityWalkEnabled and S.VelocityWalkKey then
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hrp and hum then
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then
                local targetVel = moveDir * S.VelocityWalkSpeed
                hrp.AssemblyLinearVelocity = Vector3.new(targetVel.X, hrp.AssemblyLinearVelocity.Y, targetVel.Z)
            end
        end
    end
end)

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

-- ========== Device Spoof ==========
local DEVICE_CODES = {
    ["Mobile"] = "Touch", ["Console"] = "Gamepad", ["VR"] = "VR", ["PC"] = "MouseKeyboard",
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

-- ========== 世界 / 光照 ==========
local Lighting = game:GetService("Lighting")
local lightOrigValues = {}
local lightUpdateConn = nil
local extraColorCorrection = nil

local function storeLightOriginals()
    lightOrigValues.Ambient = Lighting.Ambient
    lightOrigValues.OutdoorAmbient = Lighting.OutdoorAmbient
    lightOrigValues.GlobalShadows = Lighting.GlobalShadows
    lightOrigValues.ShadowSoftness = Lighting.ShadowSoftness
    lightOrigValues.ColorShift_Top = Lighting.ColorShift_Top
    lightOrigValues.ColorShift_Bottom = Lighting.ColorShift_Bottom
    lightOrigValues.ClockTime = Lighting.ClockTime
    lightOrigValues.FogColor = Lighting.FogColor
    lightOrigValues.FogStart = Lighting.FogStart
    lightOrigValues.FogEnd = Lighting.FogEnd
end
storeLightOriginals()

local function ensureExtraLightEffects()
    if S.LightColorCorrection.Enabled then
        if not extraColorCorrection or not extraColorCorrection.Parent then
            extraColorCorrection = Instance.new("ColorCorrectionEffect")
            extraColorCorrection.Name = "v3ExtraCC"
            extraColorCorrection.Parent = Lighting
        end
        extraColorCorrection.Contrast = S.LightColorCorrection.Contrast / 10
        extraColorCorrection.Saturation = S.LightColorCorrection.Saturation / 10
        extraColorCorrection.Brightness = S.LightColorCorrection.Brightness / 10
        extraColorCorrection.Enabled = true
    elseif extraColorCorrection then
        extraColorCorrection.Enabled = false
    end
    if S.LightBloom.Enabled then
        local eb = Lighting:FindFirstChild("v3ExtraBloom")
        if not eb then
            eb = Instance.new("BloomEffect")
            eb.Name = "v3ExtraBloom"
            eb.Parent = Lighting
        end
        eb.Intensity = S.LightBloom.Multiplier * 0.8
        eb.Size = S.LightBloom.Size
        eb.Threshold = S.LightBloom.Threshold
        eb.Enabled = true
    else
        local eb = Lighting:FindFirstChild("v3ExtraBloom")
        if eb then eb:Destroy() end
    end
end

local function lightUpdater()
    if lightUpdateConn then lightUpdateConn:Disconnect() end
    lightUpdateConn = RunService.RenderStepped:Connect(function()
        if not S.LightingEnabled then return end
        if S.LightAmbient.Enabled then Lighting.Ambient = S.LightAmbient.Color else Lighting.Ambient = lightOrigValues.Ambient end
        if S.LightOutdoorAmbient.Enabled then Lighting.OutdoorAmbient = S.LightOutdoorAmbient.Color else Lighting.OutdoorAmbient = lightOrigValues.OutdoorAmbient end
        if S.LightGlobalShadows.Enabled ~= nil then Lighting.GlobalShadows = S.LightGlobalShadows.Enabled else Lighting.GlobalShadows = lightOrigValues.GlobalShadows end
        if S.LightShadowSoftness.Enabled then Lighting.ShadowSoftness = S.LightShadowSoftness.Value else Lighting.ShadowSoftness = lightOrigValues.ShadowSoftness end
        if S.LightSunColor.Enabled then Lighting.ColorShift_Top = S.LightSunColor.Color
        elseif S.LightColorShiftTop.Enabled then Lighting.ColorShift_Top = S.LightColorShiftTop.Color
        else Lighting.ColorShift_Top = lightOrigValues.ColorShift_Top end
        if S.LightColorShiftBottom.Enabled then Lighting.ColorShift_Bottom = S.LightColorShiftBottom.Color else Lighting.ColorShift_Bottom = lightOrigValues.ColorShift_Bottom end
        if S.LightClockTime.Enabled then Lighting.ClockTime = S.LightClockTime.Value else Lighting.ClockTime = lightOrigValues.ClockTime end
        if S.LightFog.Enabled then
            Lighting.FogColor = S.LightFog.Color
            Lighting.FogStart = S.LightFog.Start
            Lighting.FogEnd = S.LightFog.End
        else
            Lighting.FogColor = lightOrigValues.FogColor
            Lighting.FogStart = lightOrigValues.FogStart
            Lighting.FogEnd = lightOrigValues.FogEnd
        end
    end)
end

local function stopLightUpdater()
    if lightUpdateConn then lightUpdateConn:Disconnect() lightUpdateConn = nil end
    Lighting.Ambient = lightOrigValues.Ambient
    Lighting.OutdoorAmbient = lightOrigValues.OutdoorAmbient
    Lighting.GlobalShadows = lightOrigValues.GlobalShadows
    Lighting.ShadowSoftness = lightOrigValues.ShadowSoftness
    Lighting.ColorShift_Top = lightOrigValues.ColorShift_Top
    Lighting.ColorShift_Bottom = lightOrigValues.ColorShift_Bottom
    Lighting.ClockTime = lightOrigValues.ClockTime
    Lighting.FogColor = lightOrigValues.FogColor
    Lighting.FogStart = lightOrigValues.FogStart
    Lighting.FogEnd = lightOrigValues.FogEnd
end

-- Atmosphere
local function applyAtmosphere()
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Atmosphere") and v.Name == "v3Atmosphere" then v:Destroy() end
    end
    if not S.AtmosphereEnabled then return end
    local atm = Instance.new("Atmosphere")
    atm.Name = "v3Atmosphere"
    atm.Density = S.AtmosphereDensity
    atm.Offset = S.AtmosphereOffset
    atm.Haze = S.AtmosphereHaze
    atm.Glare = S.AtmosphereGlare
    atm.Color = S.AtmosphereColor
    atm.Decay = S.AtmosphereDecay
    atm.Parent = Lighting
end

-- Skybox
local skyboxes = {
    Default = { SkyboxBk = "rbxassetid://91458024", SkyboxDn = "rbxassetid://91457980", SkyboxFt = "rbxassetid://91458024", SkyboxLf = "rbxassetid://91458024", SkyboxRt = "rbxassetid://91458024", SkyboxUp = "rbxassetid://91458002" },
    Neptune = { SkyboxBk = "rbxassetid://218955819", SkyboxDn = "rbxassetid://218953419", SkyboxFt = "rbxassetid://218954524", SkyboxLf = "rbxassetid://218958493", SkyboxRt = "rbxassetid://218957134", SkyboxUp = "rbxassetid://218950090" },
    Nebula = { SkyboxBk = "rbxassetid://159454299", SkyboxDn = "rbxassetid://159454296", SkyboxFt = "rbxassetid://159454293", SkyboxLf = "rbxassetid://159454286", SkyboxRt = "rbxassetid://159454300", SkyboxUp = "rbxassetid://159454288" },
    Vaporwave = { SkyboxBk = "rbxassetid://1417494030", SkyboxDn = "rbxassetid://1417494146", SkyboxFt = "rbxassetid://1417494253", SkyboxLf = "rbxassetid://1417494402", SkyboxRt = "rbxassetid://1417494499", SkyboxUp = "rbxassetid://1417494643" },
    Minecraft = { SkyboxBk = "rbxassetid://1876545003", SkyboxDn = "rbxassetid://1876544331", SkyboxFt = "rbxassetid://1876542941", SkyboxLf = "rbxassetid://1876543392", SkyboxRt = "rbxassetid://1876543764", SkyboxUp = "rbxassetid://1876544642" },
    Jungle = { SkyboxBk = "rbxassetid://214399891", SkyboxDn = "rbxassetid://214399887", SkyboxFt = "rbxassetid://214399894", SkyboxLf = "rbxassetid://214405668", SkyboxRt = "rbxassetid://214399899", SkyboxUp = "rbxassetid://214399889" },
    Aurora = { SkyboxBk = "rbxassetid://340908398", SkyboxDn = "rbxassetid://340908450", SkyboxFt = "rbxassetid://340908468", SkyboxLf = "rbxassetid://340908504", SkyboxRt = "rbxassetid://340908530", SkyboxUp = "rbxassetid://340908586" },
    Stormy = { SkyboxBk = "rbxassetid://255027929", SkyboxDn = "rbxassetid://255027967", SkyboxFt = "rbxassetid://255027923", SkyboxLf = "rbxassetid://255027938", SkyboxRt = "rbxassetid://255027946", SkyboxUp = "rbxassetid://255027960" },
    Gloomy = { SkyboxBk = "rbxassetid://5346760450", SkyboxDn = "rbxassetid://5346760689", SkyboxFt = "rbxassetid://5346760919", SkyboxLf = "rbxassetid://5346761102", SkyboxRt = "rbxassetid://5346761335", SkyboxUp = "rbxassetid://5346761509" },
}

local function applySkybox()
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Sky") and v.Name == "v3Sky" then v:Destroy() end
    end
    if not S.SkyboxEnabled then return end
    local tex = skyboxes[S.SkyboxSelection] or skyboxes.Default
    local sky = Instance.new("Sky")
    sky.Name = "v3Sky"
    sky.SkyboxBk = tex.SkyboxBk
    sky.SkyboxDn = tex.SkyboxDn
    sky.SkyboxFt = tex.SkyboxFt
    sky.SkyboxLf = tex.SkyboxLf
    sky.SkyboxRt = tex.SkyboxRt
    sky.SkyboxUp = tex.SkyboxUp
    sky.SunAngularSize = table.find(S.SkyboxDisabledElements, "Sun") and 0 or 20
    sky.MoonAngularSize = table.find(S.SkyboxDisabledElements, "Moon") and 0 or 11
    sky.StarCount = table.find(S.SkyboxDisabledElements, "Stars") and 0 or 3000
    sky.Parent = Lighting
end

-- Aspect Ratio
local aspectRatioConn = nil
local function updateAspectRatio()
    if not S.AspectRatioEnabled or not C then return end
    local ratio = S.AspectRatioX / S.AspectRatioY
    local cf = C.CFrame
    C.CFrame = CFrame.fromMatrix(cf.Position, cf.RightVector, cf.UpVector * ratio, -cf.LookVector)
end

local function updAspectRatio()
    if aspectRatioConn then aspectRatioConn:Disconnect() aspectRatioConn = nil end
    if S.AspectRatioEnabled then
        local ok = pcall(function()
            RunService:UnbindFromRenderStep("v3AspectRatio")
            RunService:BindToRenderStep("v3AspectRatio", Enum.RenderPriority.Camera.Value + 2, updateAspectRatio)
        end)
        if not ok then aspectRatioConn = RunService.RenderStepped:Connect(updateAspectRatio) end
    else
        pcall(function() RunService:UnbindFromRenderStep("v3AspectRatio") end)
    end
end

-- ========== Weather ==========
local weatherCfgs = {
    rain = { enabled = false, color = Color3.fromRGB(255,255,255), rate = 100, speed_min = 60, speed_max = 60,
        size_min = 10, size_max = 10, transparency_min = 0.22, transparency_max = 1, spread = 0,
        brightness = 1, light_emission = 0.05, glowScale = 0, base_rate = 600,
        texture = "rbxassetid://1822883048", locked = true,
        orientation = Enum.ParticleOrientation.FacingCameraWorldUp, light_influence = 0.9,
        lifetime_min = 0.8, lifetime_max = 0.8, sizeScale = 1 },
    snow = { enabled = false, color = Color3.fromRGB(255,255,255), rate = 100, speed_min = 30, speed_max = 30,
        size_min = 0.33, size_max = 0.40, transparency_min = 0.74, transparency_max = 1, spread = 0,
        brightness = 1, light_emission = 0.5, glowScale = 0, base_rate = 1000,
        texture = "http://www.roblox.com/asset/?id=99851851", locked = false,
        orientation = Enum.ParticleOrientation.FacingCamera, light_influence = 1,
        lifetime_min = 4, lifetime_max = 4, sizeScale = 1 },
    lightrain = { enabled = false, color = Color3.fromRGB(255,255,255), rate = 100, speed_min = 30, speed_max = 50,
        size_min = 0.2, size_max = 0.2, transparency_min = 0, transparency_max = 0, spread = 0,
        brightness = 2, light_emission = 0.5, glowScale = 0, base_rate = 500,
        texture = "rbxasset://textures/particles/sparkles_main.dds", locked = true,
        orientation = Enum.ParticleOrientation.FacingCameraWorldUp, light_influence = 0.3,
        lifetime_min = 9, lifetime_max = 9, sizeScale = 1 },
    stars = { enabled = false, color = Color3.fromRGB(255,255,255), rate = 100, speed_min = 30, speed_max = 30,
        size_min = 0.33, size_max = 0.40, transparency_min = 0.74, transparency_max = 1, spread = 0,
        brightness = 1, light_emission = 0.5, glowScale = 0, base_rate = 1000,
        texture = "http://www.roblox.com/asset/?id=6822501679", locked = false,
        orientation = Enum.ParticleOrientation.FacingCamera, light_influence = 1,
        lifetime_min = 4, lifetime_max = 4, sizeScale = 1 },
    hearts = { enabled = false, color = Color3.fromRGB(255,255,255), rate = 100, speed_min = 30, speed_max = 30,
        size_min = 0.33, size_max = 0.40, transparency_min = 0.74, transparency_max = 1, spread = 0,
        brightness = 1, light_emission = 0.5, glowScale = 0, base_rate = 1000,
        texture = "http://www.roblox.com/asset/?id=36721240", locked = false,
        orientation = Enum.ParticleOrientation.FacingCamera, light_influence = 1,
        lifetime_min = 4, lifetime_max = 4, sizeScale = 1 },
}

local weatherParts = {}
local weatherParticles = {}
local activeWeatherCount = 0
local weatherHeightOffset = Vector3.new(0, 20, 0)

local function applyWeatherParticle(p, cfg)
    p.EmissionDirection = Enum.NormalId.Bottom
    p.LockedToPart = cfg.locked
    p.Orientation = cfg.orientation
    p.Texture = cfg.texture
    p.Speed = NumberRange.new(cfg.speed_min, math.max(cfg.speed_min, cfg.speed_max))
    p.Lifetime = NumberRange.new(cfg.lifetime_min, math.max(cfg.lifetime_min, cfg.lifetime_max))
    p.SpreadAngle = Vector2.new(cfg.spread, cfg.spread)
    p.LightInfluence = cfg.light_influence
    local glow = math.clamp(tonumber(cfg.glowScale) or 0, 0, 5)
    if glow > 0 then
        local glowNorm = glow / 5
        p.Brightness = cfg.brightness * (1 + glow * 1.75)
        p.LightEmission = math.clamp((cfg.light_emission or 0) + glow * 0.2, 0, 1)
        p.LightInfluence = math.clamp((cfg.light_influence or 1) * (1 - glowNorm * 0.98), 0, 1)
    else
        p.Brightness = cfg.brightness
        p.LightEmission = cfg.light_emission
    end
    p.Rate = cfg.base_rate * (cfg.rate / 100)
    p.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, cfg.size_min * (cfg.sizeScale or 1)),
        NumberSequenceKeypoint.new(1, cfg.size_max * (cfg.sizeScale or 1))
    }
    p.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, cfg.transparency_max),
        NumberSequenceKeypoint.new(0.25, cfg.transparency_min),
        NumberSequenceKeypoint.new(0.75, cfg.transparency_min),
        NumberSequenceKeypoint.new(1, cfg.transparency_max)
    }
    p.Color = ColorSequence.new(cfg.color)
end

local function buildWeather(key)
    local cfg = weatherCfgs[key]
    if weatherParts[key] then
        weatherParts[key]:Destroy()
        weatherParts[key] = nil
        weatherParticles[key] = nil
        activeWeatherCount = activeWeatherCount - 1
    end
    local part = Instance.new("Part")
    part.Size = Vector3.new(40, 1, 85)
    part.CanCollide = false
    part.Massless = true
    part.CastShadow = false
    part.Transparency = 1
    part.Anchored = true
    part.Name = "\0v3Weather"
    part.Parent = W
    weatherParts[key] = part
    local p = Instance.new("ParticleEmitter")
    applyWeatherParticle(p, cfg)
    p.Parent = part
    weatherParticles[key] = p
    activeWeatherCount = activeWeatherCount + 1
end

local function destroyWeather(key)
    if weatherParts[key] then
        weatherParts[key]:Destroy()
        weatherParts[key] = nil
        weatherParticles[key] = nil
        activeWeatherCount = activeWeatherCount - 1
    end
end

local function refreshWeather(key)
    if weatherParticles[key] then applyWeatherParticle(weatherParticles[key], weatherCfgs[key]) end
end

RunService.PostSimulation:Connect(function()
    if activeWeatherCount == 0 then return end
    local pos = C.CFrame.Position + weatherHeightOffset
    local cf = CFrame.new(pos)
    for _, part in next, weatherParts do part.CFrame = cf end
end)

-- ========== Profile Spoof ==========
task.spawn(function()
    while true do
        local plr = game:GetService("Players").LocalPlayer
        if S.LevelEnabled then plr:SetAttribute("Level", S.LevelValue) end
        if S.WinStreakEnabled then
            pcall(function()
                local ls = plr:FindFirstChild("CustomLeaderstats")
                if ls then
                    local ws = ls:FindFirstChild("Win Streak")
                    if ws then ws.Value = S.WinStreakValue end
                end
            end)
        end
        task.wait(0.4)
    end
end)

-- Name Spoof
local lastSpoof = ""
local checkUpdatingName = false

local function clearBadges(str)
    if typeof(str) ~= "string" then return "" end
    return str:gsub(utf8.char(0xE000), ""):gsub(utf8.char(0xE001), "")
end

local function escapeStr(str)
    return str:gsub("([^%w])", "%%%1")
end

local function applyNameSpoof(char)
    if not S.NameSpoofEnabled then return end
    local baseName = clearBadges(S.NameSpoofValue or "hi")
    local badges = (S.NameSpoofPremium and utf8.char(0xE001) or "") .. (S.NameSpoofVerified and utf8.char(0xE000) or "")
    local curspoof = baseName .. badges
    if char then
        local h = char:WaitForChild("Humanoid", 5)
        if h then
            h.DisplayName = curspoof
            local old = h.DisplayDistanceType
            h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            h.DisplayDistanceType = old
        end
    end
end

local function updateNameSpoof()
    if not S.NameSpoofEnabled or checkUpdatingName then return end
    checkUpdatingName = true
    local baseName = clearBadges(S.NameSpoofValue or "hi")
    local badges = (S.NameSpoofPremium and utf8.char(0xE001) or "") .. (S.NameSpoofVerified and utf8.char(0xE000) or "")
    local curspoof = baseName .. badges
    if LP.Character then
        local h = LP.Character:FindFirstChildOfClass("Humanoid")
        if h then
            pcall(function()
                h.DisplayName = curspoof
                local old = h.DisplayDistanceType
                h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                h.DisplayDistanceType = old
            end)
        end
    end
    lastSpoof = curspoof
    checkUpdatingName = false
end

LP.CharacterAdded:Connect(applyNameSpoof)
if LP.Character then applyNameSpoof(LP.Character) end

-- Skin Changer
local function applySkinChanger(char)
    if not S.SkinChangerEnabled or not char then return end
    local h = char:WaitForChild("Humanoid", 5)
    local targetId = tonumber(S.SkinChangerUserId)
    if not h or not targetId then return end
    pcall(function()
        local model = game:GetService("Players"):CreateHumanoidModelFromUserId(targetId)
        if not model then return end
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("BodyColors") or obj:IsA("CharacterMesh") or obj:IsA("ShirtGraphic") then
                obj:Destroy()
            end
        end
        local head = char:FindFirstChild("Head")
        if head then
            local face = head:FindFirstChildOfClass("Decal")
            if face then face:Destroy() end
        end
        for _, obj in ipairs(model:GetChildren()) do
            if obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("BodyColors") or obj:IsA("CharacterMesh") or obj:IsA("ShirtGraphic") then
                obj:Clone().Parent = char
            elseif obj.Name == "Head" then
                local targetFace = obj:FindFirstChildOfClass("Decal")
                if targetFace and head then targetFace:Clone().Parent = head end
            end
        end
        model:Destroy()
    end)
end

LP.CharacterAdded:Connect(function(c)
    applyNameSpoof(c)
    applySkinChanger(c)
end)

-- FPS/MS/Region Spoof
local playerGui = LP:WaitForChild("PlayerGui")
local foundLabels = {}
local foundRegionLabels = {}

local function findLabels(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("TextLabel") and child.Name == "Title" then
            if child.Parent.Name == "ServerRegion" then
                table.insert(foundRegionLabels, child)
            else
                table.insert(foundLabels, child)
            end
        end
        findLabels(child)
    end
end
findLabels(playerGui)

local fpsSpoofConns = {}
local msSpoofConns = {}
local regionSpoofConns = {}

local function applyFpsSpoof()
    for _, c in ipairs(fpsSpoofConns) do c:Disconnect() end
    fpsSpoofConns = {}
    if not S.FPSSpoofEnabled then return end
    for _, label in ipairs(foundLabels) do
        table.insert(fpsSpoofConns, label:GetPropertyChangedSignal("Text"):Connect(function()
            local spoofed = label.Text:gsub("%d+fps", S.FPSSpoofValue .. "fps")
            if spoofed ~= label.Text then label.Text = spoofed end
        end))
    end
end

local function applyMsSpoof()
    for _, c in ipairs(msSpoofConns) do c:Disconnect() end
    msSpoofConns = {}
    if not S.MSSpoofEnabled then return end
    for _, label in ipairs(foundLabels) do
        table.insert(msSpoofConns, label:GetPropertyChangedSignal("Text"):Connect(function()
            local spoofed = label.Text:gsub("%d+ms", S.MSSpoofValue .. "ms")
            if spoofed ~= label.Text then label.Text = spoofed end
        end))
    end
end

local function applyRegionSpoof()
    for _, c in ipairs(regionSpoofConns) do c:Disconnect() end
    regionSpoofConns = {}
    if not S.RegionSpoofEnabled then return end
    for _, label in ipairs(foundRegionLabels) do
        label.Text = S.RegionSpoofValue
        table.insert(regionSpoofConns, label:GetPropertyChangedSignal("Text"):Connect(function()
            if label.Text ~= S.RegionSpoofValue then label.Text = S.RegionSpoofValue end
        end))
    end
end

-- ========== 自身材質 ==========
local SlfMtrl = {
    parts = {}, originals = {}, conn = nil, phase = 0, cacheTick = 0,
}

local function slfMtrlGetBodyParts()
    local char = LP.Character
    if not char then return {} end
    local parts = {}
    for _, inst in ipairs(char:GetChildren()) do
        if inst:IsA("BasePart") and inst.Name ~= "HumanoidRootPart" then
            parts[#parts + 1] = inst
        end
    end
    return parts
end

local function slfMtrlRecordOriginal(part)
    if SlfMtrl.originals[part] then return end
    SlfMtrl.originals[part] = {
        Material = part.Material, Color = part.Color, Transparency = part.Transparency,
    }
end

local function slfMtrlRestore()
    for part, data in pairs(SlfMtrl.originals) do
        if part and part.Parent then
            part.Material = data.Material
            part.Color = data.Color
            part.Transparency = data.Transparency
        end
    end
    SlfMtrl.originals = {}
end

local function slfMtrlRefreshCache()
    SlfMtrl.parts = slfMtrlGetBodyParts()
    for _, part in ipairs(SlfMtrl.parts) do slfMtrlRecordOriginal(part) end
end

local function slfMtrlApply(dt)
    if not S.SlfMtrlEnabled then return end
    if tick() - SlfMtrl.cacheTick > 0.5 then
        SlfMtrl.cacheTick = tick()
        slfMtrlRefreshCache()
    end
    SlfMtrl.phase = SlfMtrl.phase + dt * S.SlfMtrlPulseSpeed
    local t = (math.sin(SlfMtrl.phase) + 1) * 0.5
    local pulseColor
    if t < 0.5 then pulseColor = S.SlfMtrlColor1:Lerp(S.SlfMtrlColor2, t * 2)
    else pulseColor = S.SlfMtrlColor2:Lerp(S.SlfMtrlColor3, (t - 0.5) * 2) end
    local mat = Enum.Material[S.SlfMtrlMaterial] or Enum.Material.Neon
    local trans = math.clamp(S.SlfMtrlTransparency, 0, 1)
    for _, part in ipairs(SlfMtrl.parts) do
        if part and part.Parent then
            part.Material = mat
            part.Color = pulseColor
            part.Transparency = trans
        end
    end
end

local function slfMtrlSetEnabled(state)
    if state then
        slfMtrlRefreshCache()
        if not SlfMtrl.conn then
            SlfMtrl.conn = RunService.RenderStepped:Connect(slfMtrlApply)
        end
    else
        if SlfMtrl.conn then SlfMtrl.conn:Disconnect() SlfMtrl.conn = nil end
        slfMtrlRestore()
    end
end

LP.CharacterAdded:Connect(function()
    task.wait(0.25)
    if S.SlfMtrlEnabled then slfMtrlRefreshCache() end
end)

-- ========== 動畫播放器 ==========
local AnimPlayer = { animationId = "", loop = true, track = nil, stoppedConn = nil }

local function animPlayerGetAnimator()
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end
    return animator
end

local function animPlayerNormalizeId(raw)
    local txt = tostring(raw or "")
    local numeric = txt:match("%d+")
    if not numeric then return nil end
    return "rbxassetid://" .. numeric
end

local function animPlayerStop()
    if AnimPlayer.stoppedConn then AnimPlayer.stoppedConn:Disconnect() AnimPlayer.stoppedConn = nil end
    if AnimPlayer.track then
        pcall(function() AnimPlayer.track:Stop() AnimPlayer.track:Destroy() end)
        AnimPlayer.track = nil
    end
end

local function animPlayerPlay()
    local animId = animPlayerNormalizeId(AnimPlayer.animationId)
    if not animId then return end
    local animator = animPlayerGetAnimator()
    if not animator then return end
    animPlayerStop()
    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    anim:Destroy()
    if not ok or not track then return end
    AnimPlayer.track = track
    track.Looped = AnimPlayer.loop
    track:Play(0.05, 1, 1)
    AnimPlayer.stoppedConn = track.Stopped:Connect(function()
        if AnimPlayer.loop then
            task.delay(0.03, function()
                if AnimPlayer.track == track then
                    pcall(function() track:Play(0.05, 1, 1) end)
                end
            end)
        end
    end)
end

-- ========== 雜項 ==========
-- Noclip
local noclipConn = nil
local function updNoclip()
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    if S.Noclip then
        noclipConn = RunService.Stepped:Connect(function()
            local char = LP.Character
            if not char then return end
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end)
    end
end

-- Anti Trip
local tripHRP = nil
local tripConnA, tripConnB = nil, nil

local function updAntiTrip()
    if tripConnA then tripConnA:Disconnect() tripConnA = nil end
    if tripConnB then tripConnB:Disconnect() tripConnB = nil end
    if not S.AntiTripEnabled then tripHRP = nil return end
    tripConnA = RunService.Heartbeat:Connect(function()
        pcall(function()
            tripHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        end)
    end)
    tripConnB = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not tripHRP then return end
            for _, s in ipairs(W:GetChildren()) do
                if s.Name == "SubspaceTripmineHitbox" then
                    local hb = s:FindFirstChild("Hitbox")
                    if hb and tripHRP:IsA("BasePart") then
                        firetouchinterest(tripHRP, hb, 1)
                        firetouchinterest(tripHRP, hb, 0)
                    end
                end
            end
        end)
    end)
end

-- Anti Flashbang
local function patchFlashbang()
    pcall(function()
        local modules = RS:FindFirstChild("Modules")
        local il = modules and modules:FindFirstChild("ItemLibrary")
        if il then
            local itemLib = require(il)
            if itemLib and itemLib.Items and itemLib.Items.Flashbang then
                itemLib.Items.Flashbang.BlindDuration = 0
                if itemLib.Items.Flashbang.Info then
                    itemLib.Items.Flashbang.Info.BlindDuration = 0
                end
            end
        end
    end)
end

-- Anti AFK
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

-- ========== GUI ==========
local ObsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local ok = pcall(function()
    loadstring(game:HttpGet(ObsidianRepo .. "Library.lua"))()
end)
if not ok then
    warn("[v3 Hub] Obsidian 載入失敗")
    return
end
local Library = getgenv().Library or getgenv().ObsidianLibrary
if not Library then return end

ThemeManager = loadstring(game:HttpGet(ObsidianRepo .. "addons/ThemeManager.lua"))()
SaveManager  = loadstring(game:HttpGet(ObsidianRepo .. "addons/SaveManager.lua"))()

getgenv().ThemeManager = ThemeManager
getgenv().SaveManager  = SaveManager
_G.ThemeManager = ThemeManager
_G.SaveManager  = SaveManager

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
    Title = "v3 Hub // RIVALS",
    Footer = "v3 Hub | Obsidian GUI",
    Center = true, AutoShow = true, NotifySide = "Right", ShowCustomCursor = false
})

local CombatTab = Window:AddTab("Combat", "swords")
local VisualsTab = Window:AddTab("Visuals", "eye")
local WorldTab = Window:AddTab("World", "earth")
local CharacterTab = Window:AddTab("Character", "person-standing")
local MovementTab = Window:AddTab("Movement", "person-standing")
local GunTab = Window:AddTab("Gun", "crosshair")
local MiscTab = Window:AddTab("Misc", "circle-ellipsis")
local ConfigTab = Window:AddTab("Configs", "save")

-- === Combat ===
local silentGroup = CombatTab:AddLeftGroupbox("Silent Aim")
silentGroup:AddToggle("Silent_Enabled", { Text = "Enable Silent Aim", Default = false, Callback = function(v) S.SilentEnabled = v end }):AddKeyPicker("Silent_Key", { Text = "Silent Aim", Default = "None", Mode = "Toggle", NoUI = true, SyncToggleState = true, Callback = function(state) S.SilentEnabled = state end })
silentGroup:AddToggle("Silent_AutoShoot", { Text = "Auto Shoot", Default = false, Callback = function(v) S.SilentAutoShoot = v end })
silentGroup:AddToggle("Silent_WallCheck", { Text = "Wall Check", Default = true, Callback = function(v) S.SilentWallCheck = v end })
silentGroup:AddToggle("Silent_360", { Text = "360 Mode", Default = false, Callback = function(v) S.Silent360 = v end })
silentGroup:AddDropdown("Silent_HitPart", { Text = "Hit Part", Default = "Head", Values = {"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso"}, Callback = function(v) S.SilentHitPart = v end })
silentGroup:AddSlider("Silent_FOV", { Text = "FOV", Default = 150, Min = 10, Max = 800, Rounding = 0, Compact = true, Callback = function(v) S.SilentFOV = v end })
silentGroup:AddSlider("Silent_HitChance", { Text = "Hit Chance", Default = 100, Min = 0, Max = 100, Rounding = 0, Compact = true, Callback = function(v) S.SilentHitChance = v end })
silentGroup:AddToggle("Silent_FollowMuzzle", { Text = "Follow Muzzle", Default = false, Callback = function(v) S.SilentFollowMuzzle = v end })

local rageGroup = CombatTab:AddLeftGroupbox("Ragebot")
rageGroup:AddToggle("Rage_Enabled", { Text = "Enable Ragebot", Default = false, Callback = function(v) S.RageEnabled = v if not v then rageClearTarget() end end }):AddKeyPicker("Rage_Key", { Text = "Ragebot", Default = "None", Mode = "Toggle", NoUI = true, SyncToggleState = true, Callback = function(state) S.RageEnabled = state if not state then rageClearTarget() end end })
rageGroup:AddToggle("Rage_AutoTarget", { Text = "Auto Target", Default = false, Callback = function(v) S.RageAutoTarget = v end })
rageGroup:AddToggle("Rage_AutoShoot", { Text = "Auto Shoot", Default = true, Callback = function(v) S.RageAutoShoot = v end })
rageGroup:AddToggle("Rage_Predict", { Text = "Prediction", Default = false, Callback = function(v) S.RagePredict = v end })
rageGroup:AddSlider("Rage_PredictMul", { Text = "Prediction Mult", Default = 1.2, Min = 0.1, Max = 3.0, Rounding = 1, Compact = true, Callback = function(v) S.RagePredictMul = v end })
rageGroup:AddDropdown("Rage_HitPart", { Text = "Hit Part", Default = "Head", Values = {"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso"}, Callback = function(v) S.RageHitPart = v end })
rageGroup:AddSlider("Rage_Attempts", { Text = "Shoot Attempts", Default = 1, Min = 1, Max = 3, Rounding = 0, Compact = true, Callback = function(v) S.RageShootAttempts = v end })
rageGroup:AddButton({ Text = "手動鎖定最近敵人", Func = function() local ch = rageNearest() if ch then rageSetTarget(ch) rageStartSync() end end })
rageGroup:AddButton({ Text = "解除鎖定", Func = function() rageClearTarget() end })

local voidGroup = CombatTab:AddLeftGroupbox("Void Spam")
voidGroup:AddToggle("Void_Enabled", { Text = "Enable Void Spam", Default = false, Callback = function(v) S.VoidSpamEnabled = v if not v then Rage.voidPhase = nil end end })
voidGroup:AddSlider("Void_ShootMin", { Text = "Attack Time", Default = 1, Min = 0.1, Max = 2, Rounding = 1, Compact = true, Callback = function(v) S.VoidShootMin = v S.VoidShootMax = v end })
voidGroup:AddSlider("Void_HideMin", { Text = "Hide Time", Default = 1, Min = 0.1, Max = 2, Rounding = 1, Compact = true, Callback = function(v) S.VoidHideMin = v S.VoidHideMax = v end })
voidGroup:AddToggle("Void_HideReload", { Text = "Hide on Reload", Default = true, Callback = function(v) S.VoidHideReload = v end })

local aimGroup = CombatTab:AddRightGroupbox("Aimbot (Mouse)")
aimGroup:AddToggle("Aimbot_Enabled", { Text = "Enable Aimbot", Default = false, Callback = function(v) S.AimEnabled = v if v then S.TeamCheck = true end end })
aimGroup:AddDropdown("Aimbot_HitPart", { Text = "Hit Part", Default = "Head", Values = {"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso"}, Callback = function(v) S.AimHitPart = v end })
aimGroup:AddSlider("Aimbot_FOV", { Text = "FOV", Default = 300, Min = 10, Max = 1000, Rounding = 0, Compact = true, Callback = function(v) S.AimFOV = v end })
aimGroup:AddToggle("Aimbot_WallCheck", { Text = "Wall Check", Default = false, Callback = function(v) S.AimWallCheck = v end })
aimGroup:AddSlider("Aimbot_Sens", { Text = "Sensitivity", Default = 1.0, Min = 0.1, Max = 5, Rounding = 2, Compact = true, Callback = function(v) S.MouseSens = v end })
aimGroup:AddSlider("Aimbot_Smooth", { Text = "Smoothness", Default = 0.5, Min = 0, Max = 0.95, Rounding = 2, Compact = true, Callback = function(v) S.MouseSmooth = v end })
aimGroup:AddSlider("Aimbot_Deadzone", { Text = "Deadzone", Default = 2, Min = 0, Max = 20, Rounding = 0, Compact = true, Callback = function(v) S.MouseDeadzone = v end })
aimGroup:AddSlider("Aimbot_MaxStep", { Text = "Max Step", Default = 200, Min = 10, Max = 500, Rounding = 0, Compact = true, Callback = function(v) S.MouseMaxStep = v end })

local backGroup = CombatTab:AddRightGroupbox("Orbit Teleport")
backGroup:AddToggle("Backshoot_Enabled", { Text = "Enable Orbit", Default = false, Callback = function(v) S.BackshootEnabled = v if v then startContinuousBackshoot() else releaseBackshoot() end end })
backGroup:AddSlider("Orbit_Delay", { Text = "Delay", Default = 0, Min = 0, Max = 5, Rounding = 2, Compact = true, Callback = function(v) S.OrbitDelay = v end })
backGroup:AddSlider("Orbit_Speed", { Text = "Speed (rev/s)", Default = 3, Min = 0.5, Max = 20, Rounding = 1, Compact = true, Callback = function(v) S.OrbitSpeed = v end })
backGroup:AddSlider("Orbit_Radius", { Text = "Radius", Default = 5, Min = 1, Max = 20, Rounding = 1, Compact = true, Callback = function(v) S.OrbitRadius = v end })
backGroup:AddSlider("Orbit_Height", { Text = "Height", Default = 1, Min = -5, Max = 10, Rounding = 1, Compact = true, Callback = function(v) S.OrbitHeight = v end })
backGroup:AddToggle("Orbit_DeathRespawn", { Text = "Auto Restart on Respawn", Default = true, Callback = function(v) S.OrbitDeathRespawn = v end })

local antiGroup = CombatTab:AddRightGroupbox("Anti-Aim")
antiGroup:AddToggle("AntiAim_Enabled", { Text = "Enable Anti-Aim", Default = false, Callback = function(v) S.AntiAimEnabled = v end })
antiGroup:AddDropdown("AntiAim_Yaw", { Text = "Yaw", Default = "jitter", Values = {"none","jitter","spinbot","random"}, Callback = function(v) S.AntiAimYaw = v end })
antiGroup:AddDropdown("AntiAim_Pitch", { Text = "Pitch", Default = "jitter", Values = {"none","jitter","spinbot","random"}, Callback = function(v) S.AntiAimPitch = v end })
antiGroup:AddDropdown("AntiAim_Angle", { Text = "Angle", Default = "none", Values = {"none","tilt 45","tilt 90","upside down","custom"}, Callback = function(v) S.AntiAimAngle = v end })
antiGroup:AddSlider("AntiAim_CustomAngle", { Text = "Custom Angle", Default = 0, Min = 0, Max = 360, Rounding = 1, Compact = true, Callback = function(v) S.AntiAimCustomAngle = v end })
antiGroup:AddSlider("AntiAim_MinSpeed", { Text = "Min Speed", Default = 10, Min = 1, Max = 50, Rounding = 1, Compact = true, Callback = function(v) S.AntiAimMinSpeed = v end })
antiGroup:AddSlider("AntiAim_MaxSpeed", { Text = "Max Speed", Default = 20, Min = 1, Max = 100, Rounding = 1, Compact = true, Callback = function(v) S.AntiAimMaxSpeed = v end })
antiGroup:AddSlider("AntiAim_MinAngle", { Text = "Min Angle", Default = 30, Min = 1, Max = 180, Rounding = 1, Compact = true, Callback = function(v) S.AntiAimMinAngle = v end })
antiGroup:AddSlider("AntiAim_MaxAngle", { Text = "Max Angle", Default = 60, Min = 1, Max = 180, Rounding = 1, Compact = true, Callback = function(v) S.AntiAimMaxAngle = v end })
antiGroup:AddToggle("AntiAim_RandomAngle", { Text = "Random Angle", Default = false, Callback = function(v) S.AntiAimRandomAngle = v end })
antiGroup:AddToggle("AntiAim_Underground", { Text = "Underground", Default = false, Callback = function(v) S.AntiAimUnderground = v end })

-- === Visuals ===
local espGroup = VisualsTab:AddLeftGroupbox("ESP")
espGroup:AddToggle("ESP_Enabled", { Text = "Enable ESP", Default = true, Callback = function(v) S.ESPEnabled = v end })
espGroup:AddToggle("ESP_Box", { Text = "Box", Default = true, Callback = function(v) S.ShowBox = v end })
espGroup:AddToggle("ESP_BoxFill", { Text = "Box Fill", Default = false, Callback = function(v) S.ShowBoxFill = v end })
espGroup:AddToggle("ESP_BoxGlow", { Text = "Box Glow", Default = false, Callback = function(v) S.ShowBoxGlow = v end })
espGroup:AddToggle("ESP_Name", { Text = "Name", Default = true, Callback = function(v) S.ShowName = v end })
espGroup:AddToggle("ESP_Distance", { Text = "Distance", Default = true, Callback = function(v) S.ShowDistance = v end })
espGroup:AddToggle("ESP_Tools", { Text = "Weapon", Default = false, Callback = function(v) S.ShowTools = v end })
espGroup:AddToggle("ESP_Health", { Text = "Healthbar", Default = true, Callback = function(v) S.ShowHealth = v end })
espGroup:AddToggle("ESP_Tracer", { Text = "Tracer", Default = true, Callback = function(v) S.ShowTracer = v end })
espGroup:AddToggle("ESP_Skeleton", { Text = "Skeleton", Default = true, Callback = function(v) S.ShowSkeleton = v end })
espGroup:AddToggle("ESP_Chams", { Text = "Chams", Default = false, Callback = function(v) S.ShowChams = v end })
espGroup:AddSlider("ESP_MaxDist", { Text = "Max Distance", Default = 2000, Min = 100, Max = 5000, Rounding = 0, Compact = true, Callback = function(v) S.MaxDistance = v end })
espGroup:AddSlider("ESP_HueSpeed", { Text = "Rainbow Speed", Default = 0.25, Min = 0, Max = 2, Rounding = 2, Compact = true, Callback = function(v) S.HueSpeed = v end })

local crossGroup = VisualsTab:AddRightGroupbox("Crosshair")
crossGroup:AddToggle("Crosshair_Enabled", { Text = "Enable Crosshair", Default = false, Callback = function(v) S.CrosshairEnabled = v end }):AddColorPicker("Crosshair_Color", { Default = Color3.fromRGB(0, 200, 255), Title = "Color", Callback = function(v) S.CrosshairColor = v end })
crossGroup:AddToggle("Crosshair_ShowLines", { Text = "Show Lines", Default = true, Callback = function(v) S.CrosshairShowLines = v end })
crossGroup:AddSlider("Crosshair_Spin", { Text = "Spin Speed", Default = 150, Min = 0, Max = 340, Rounding = 0, Compact = true, Callback = function(v) S.CrosshairSpinSpeed = v end })
crossGroup:AddDropdown("Crosshair_Mode", { Text = "Mode", Default = "static", Values = {"static","follow muzzle"}, Callback = function(v) S.CrosshairMode = v end })

-- Bullet Tracers
local btGroup = VisualsTab:AddRightGroupbox("Bullet Tracers")
btGroup:AddToggle("BT_Enabled", { Text = "Enable", Default = true, Callback = function(v) S.BulletTracerEnabled = v end }):AddColorPicker("BT_Color", { Default = Color3.fromRGB(255, 255, 255), Title = "Color", Callback = function(v) S.BulletTracerColor = v end })
btGroup:AddDropdown("BT_Style", { Text = "Style", Default = "Line", Values = {"Line","Beam","Lightning","Heartrate","Chain","Glitch","Swirl","Neon","Plasma","Laser"}, Callback = function(v) S.BulletTracerStyle = v end })
btGroup:AddSlider("BT_Duration", { Text = "Duration", Default = 3, Min = 0.1, Max = 10, Rounding = 1, Compact = true, Callback = function(v) S.BulletTracerDuration = v end })
btGroup:AddSlider("BT_Size", { Text = "Size", Default = 1, Min = 0.5, Max = 5, Rounding = 1, Compact = true, Callback = function(v) S.BulletTracerSize = v end })
btGroup:AddSlider("BT_FadeTime", { Text = "Fade Time", Default = 0.5, Min = 0, Max = 2, Rounding = 1, Compact = true, Callback = function(v) S.BulletTracerFadeTime = v end })

-- === World ===
local lightGroup = WorldTab:AddLeftGroupbox("Lighting")
lightGroup:AddToggle("Light_Enabled", { Text = "Enable", Default = false, Callback = function(v) S.LightingEnabled = v if v then lightUpdater() else stopLightUpdater() end end })
lightGroup:AddToggle("Light_Ambient", { Text = "Ambient", Default = false, Callback = function(v) S.LightAmbient.Enabled = v end }):AddColorPicker("Light_AmbientColor", { Default = Color3.fromRGB(255, 255, 255), Title = "Color", Callback = function(v) S.LightAmbient.Color = v end })
lightGroup:AddToggle("Light_Outdoor", { Text = "Outdoor Ambient", Default = false, Callback = function(v) S.LightOutdoorAmbient.Enabled = v end }):AddColorPicker("Light_OutdoorColor", { Default = Color3.fromRGB(255, 255, 255), Title = "Color", Callback = function(v) S.LightOutdoorAmbient.Color = v end })
lightGroup:AddToggle("Light_Shadows", { Text = "Global Shadows", Default = true, Callback = function(v) S.LightGlobalShadows.Enabled = v end })
lightGroup:AddToggle("Light_ShadowSoftness", { Text = "Shadow Softness", Default = false, Callback = function(v) S.LightShadowSoftness.Enabled = v end })
lightGroup:AddToggle("Light_ClockTime", { Text = "Time", Default = false, Callback = function(v) S.LightClockTime.Enabled = v end })
lightGroup:AddSlider("Light_ClockValue", { Text = "Hour", Default = 12, Min = 0, Max = 24, Rounding = 1, Compact = true, Callback = function(v) S.LightClockTime.Value = v end })
lightGroup:AddToggle("Light_CC", { Text = "Color Correction", Default = false, Callback = function(v) S.LightColorCorrection.Enabled = v ensureExtraLightEffects() end })
lightGroup:AddSlider("Light_CCContrast", { Text = "Contrast", Default = 0, Min = -10, Max = 10, Rounding = 1, Compact = true, Callback = function(v) S.LightColorCorrection.Contrast = v ensureExtraLightEffects() end })
lightGroup:AddSlider("Light_CCSat", { Text = "Saturation", Default = 0, Min = -10, Max = 10, Rounding = 1, Compact = true, Callback = function(v) S.LightColorCorrection.Saturation = v ensureExtraLightEffects() end })
lightGroup:AddToggle("Light_Bloom", { Text = "Bloom", Default = false, Callback = function(v) S.LightBloom.Enabled = v ensureExtraLightEffects() end })
lightGroup:AddSlider("Light_BloomMult", { Text = "Bloom Intensity", Default = 0.3, Min = 0, Max = 1.5, Rounding = 2, Compact = true, Callback = function(v) S.LightBloom.Multiplier = v ensureExtraLightEffects() end })

local atmoGroup = WorldTab:AddRightGroupbox("Atmosphere")
atmoGroup:AddToggle("Atmo_Enabled", { Text = "Enable", Default = false, Callback = function(v) S.AtmosphereEnabled = v applyAtmosphere() end }):AddColorPicker("Atmo_Color", { Default = Color3.fromRGB(140, 160, 190), Title = "Color", Callback = function(v) S.AtmosphereColor = v applyAtmosphere() end }):AddColorPicker("Atmo_Decay", { Default = Color3.fromRGB(90, 110, 140), Title = "Decay", Callback = function(v) S.AtmosphereDecay = v applyAtmosphere() end })
atmoGroup:AddSlider("Atmo_Density", { Text = "Density", Default = 0.3, Min = 0, Max = 1, Rounding = 2, Compact = true, Callback = function(v) S.AtmosphereDensity = v applyAtmosphere() end })
atmoGroup:AddSlider("Atmo_Haze", { Text = "Haze", Default = 0.78, Min = 0, Max = 5, Rounding = 2, Compact = true, Callback = function(v) S.AtmosphereHaze = v applyAtmosphere() end })

local skyGroup = WorldTab:AddRightGroupbox("Skybox")
skyGroup:AddToggle("Sky_Enabled", { Text = "Enable", Default = false, Callback = function(v) S.SkyboxEnabled = v applySkybox() end })
skyGroup:AddDropdown("Sky_Selection", { Text = "Skybox", Default = "Default", Values = {"Default","Neptune","Nebula","Vaporwave","Minecraft","Jungle","Aurora","Stormy","Gloomy"}, Callback = function(v) S.SkyboxSelection = v applySkybox() end })
skyGroup:AddDropdown("Sky_Disabled", { Text = "Disable Elements", Default = {}, Values = {"Sun","Moon","Stars"}, Multi = true, Callback = function(v) S.SkyboxDisabledElements = v applySkybox() end })

local aspectGroup = WorldTab:AddRightGroupbox("Aspect Ratio")
aspectGroup:AddToggle("Aspect_Enabled", { Text = "Enable", Default = false, Callback = function(v) S.AspectRatioEnabled = v updAspectRatio() end })
aspectGroup:AddSlider("Aspect_X", { Text = "X", Default = 13, Min = 1, Max = 13, Rounding = 0, Compact = true, Callback = function(v) S.AspectRatioX = v end })
aspectGroup:AddSlider("Aspect_Y", { Text = "Y", Default = 10, Min = 10, Max = 32, Rounding = 0, Compact = true, Callback = function(v) S.AspectRatioY = v end })

-- Weather
local weatherGroup = WorldTab:AddLeftGroupbox("Weather")
weatherGroup:AddToggle("Weather_Enabled", { Text = "Enable", Default = false, Callback = function(v) S.WeatherEnabled = v if not v then for key in next, weatherCfgs do destroyWeather(key) end end end }):AddColorPicker("Weather_Color", { Default = Color3.fromRGB(255, 255, 255), Title = "Color", Callback = function(v) S.WeatherColor = v for key in next, weatherParticles do weatherCfgs[key].color = v refreshWeather(key) end end })
weatherGroup:AddDropdown("Weather_Effects", { Text = "Effects", Default = {}, Values = {"rain","snow","light rain","stars","hearts"}, Multi = true, Callback = function(v)
    local keyMap = {["rain"]="rain",["snow"]="snow",["light rain"]="lightrain",["stars"]="stars",["hearts"]="hearts"}
    for displayName, cfgKey in next, keyMap do
        local active = v[displayName] == true
        weatherCfgs[cfgKey].enabled = active
        if active and S.WeatherEnabled then buildWeather(cfgKey) refreshWeather(cfgKey)
        elseif not active then destroyWeather(cfgKey) end
    end
end })
weatherGroup:AddSlider("Weather_Rate", { Text = "Rate", Default = 100, Min = 0, Max = 100, Rounding = 0, Compact = true, Callback = function(v) S.WeatherRate = v for key in next, weatherParticles do weatherCfgs[key].rate = v refreshWeather(key) end end })
weatherGroup:AddSlider("Weather_SizeScale", { Text = "Size Scale", Default = 1, Min = 0.1, Max = 5, Rounding = 2, Compact = true, Callback = function(v) S.WeatherSizeScale = v for key in next, weatherParticles do weatherCfgs[key].sizeScale = v refreshWeather(key) end end })

-- Textures
local texGroup = WorldTab:AddRightGroupbox("Textures")
texGroup:AddToggle("Tex_Smooth", { Text = "Smooth Textures", Default = false, Callback = function(v) S.SmoothTextures = v end })
texGroup:AddToggle("Tex_Dark", { Text = "Dark Textures", Default = false, Callback = function(v) S.DarkTextures = v end })
texGroup:AddToggle("Tex_Transparent", { Text = "Transparent Textures", Default = false, Callback = function(v) S.TransparentTextures = v end })
texGroup:AddSlider("Tex_Transparency", { Text = "Transparency", Default = 0.6, Min = 0.5, Max = 1, Rounding = 2, Compact = true, Callback = function(v) S.TransparentStrength = v end })

-- Kill Sounds
local ksGroup = WorldTab:AddRightGroupbox("Kill Sounds")
ksGroup:AddToggle("KS_Enabled", { Text = "Enable", Default = false, Callback = function(v) S.KillSoundEnabled = v end })
ksGroup:AddDropdown("KS_Style", { Text = "Sound", Default = "sound 1", Values = {"sound 1","sound 2","sound 3"}, Callback = function(v) S.KillSoundStyle = v end })
ksGroup:AddSlider("KS_Volume", { Text = "Volume", Default = 50, Min = 0, Max = 100, Rounding = 0, Compact = true, Callback = function(v) S.KillSoundVolume = v end })

-- === Character ===
local profileGroup = CharacterTab:AddLeftGroupbox("Profile Spoof")
profileGroup:AddToggle("Level_Enabled", { Text = "Level Spoof", Default = false, Callback = function(v) S.LevelEnabled = v end })
profileGroup:AddInput("Level_Value", { Text = "Level", Default = "9999", Numeric = true, Finished = false, Callback = function(v) S.LevelValue = tonumber(v) or 9999 end })
profileGroup:AddToggle("WinStreak_Enabled", { Text = "Win Streak Spoof", Default = false, Callback = function(v) S.WinStreakEnabled = v end })
profileGroup:AddInput("WinStreak_Value", { Text = "Win Streak", Default = "9999", Numeric = true, Finished = false, Callback = function(v) S.WinStreakValue = tonumber(v) or 9999 end })

local nameGroup = CharacterTab:AddLeftGroupbox("Name Spoof")
nameGroup:AddToggle("Name_Enabled", { Text = "Enable", Default = false, Callback = function(v) S.NameSpoofEnabled = v if v and LP.Character then applyNameSpoof(LP.Character) end end })
nameGroup:AddInput("Name_Value", { Text = "Custom Name", Default = "hi", Finished = false, Callback = function(v) S.NameSpoofValue = clearBadges(v or "hi") updateNameSpoof() end })
nameGroup:AddToggle("Name_Verified", { Text = "Verified Badge", Default = false, Callback = function(v) S.NameSpoofVerified = v updateNameSpoof() end })
nameGroup:AddToggle("Name_Premium", { Text = "Premium Badge", Default = false, Callback = function(v) S.NameSpoofPremium = v updateNameSpoof() end })

local skinGroup = CharacterTab:AddLeftGroupbox("Skin Changer")
skinGroup:AddToggle("Skin_Enabled", { Text = "Enable", Default = false, Callback = function(v) S.SkinChangerEnabled = v if v and LP.Character then applySkinChanger(LP.Character) end end })
skinGroup:AddInput("Skin_UserId", { Text = "User ID", Default = "1", Numeric = true, Finished = true, Callback = function(v) S.SkinChangerUserId = v or "1" if S.SkinChangerEnabled and LP.Character then applySkinChanger(LP.Character) end end })

local spoofGroup = CharacterTab:AddRightGroupbox("FPS / MS / Region Spoof")
spoofGroup:AddToggle("FPS_Enabled", { Text = "FPS Spoof", Default = false, Callback = function(v) S.FPSSpoofEnabled = v applyFpsSpoof() end })
spoofGroup:AddInput("FPS_Value", { Text = "FPS", Default = "1", Numeric = true, Finished = false, Callback = function(v) S.FPSSpoofValue = v or "1" applyFpsSpoof() end })
spoofGroup:AddToggle("MS_Enabled", { Text = "MS Spoof", Default = false, Callback = function(v) S.MSSpoofEnabled = v applyMsSpoof() end })
spoofGroup:AddInput("MS_Value", { Text = "MS", Default = "1", Numeric = true, Finished = false, Callback = function(v) S.MSSpoofValue = v or "1" applyMsSpoof() end })
spoofGroup:AddToggle("Region_Enabled", { Text = "Region Spoof", Default = false, Callback = function(v) S.RegionSpoofEnabled = v applyRegionSpoof() end })
spoofGroup:AddInput("Region_Value", { Text = "Region", Default = "v3hub.cc", Finished = false, Callback = function(v) S.RegionSpoofValue = v or "v3hub.cc" applyRegionSpoof() end })

-- Self Material
local slfGroup = CharacterTab:AddRightGroupbox("Self Material")
slfGroup:AddToggle("Slf_Enabled", { Text = "Enable", Default = false, Callback = function(v) S.SlfMtrlEnabled = v slfMtrlSetEnabled(v) end }):AddColorPicker("Slf_Color1", { Default = Color3.fromRGB(255, 255, 255), Title = "Color 1", Callback = function(v) S.SlfMtrlColor1 = v end }):AddColorPicker("Slf_Color2", { Default = Color3.fromRGB(255, 255, 255), Title = "Color 2", Callback = function(v) S.SlfMtrlColor2 = v end }):AddColorPicker("Slf_Color3", { Default = Color3.fromRGB(255, 255, 255), Title = "Color 3", Callback = function(v) S.SlfMtrlColor3 = v end })
slfGroup:AddDropdown("Slf_Material", { Text = "Material", Default = "Neon", Values = {"Neon","ForceField","Glass","Ice","Plastic","Wood","Marble","Granite","Brick","Concrete","Foil"}, Callback = function(v) S.SlfMtrlMaterial = v end })
slfGroup:AddSlider("Slf_Transparency", { Text = "Transparency", Default = 0.1, Min = 0, Max = 1, Rounding = 2, Compact = true, Callback = function(v) S.SlfMtrlTransparency = v end })
slfGroup:AddSlider("Slf_Speed", { Text = "Pulse Speed", Default = 3, Min = 0.1, Max = 12, Rounding = 1, Compact = true, Callback = function(v) S.SlfMtrlPulseSpeed = v end })

-- Anim Player
local animGroup = CharacterTab:AddRightGroupbox("Animation Player")
animGroup:AddInput("Anim_ID", { Text = "Animation ID", Default = "", Finished = true, Callback = function(v) AnimPlayer.animationId = v end })
animGroup:AddToggle("Anim_Loop", { Text = "Loop", Default = true, Callback = function(v) AnimPlayer.loop = v end })
animGroup:AddButton({ Text = "Play", Func = function() animPlayerPlay() end })
animGroup:AddButton({ Text = "Stop", Func = function() animPlayerStop() end })

-- === Movement ===
local moveGroup = MovementTab:AddLeftGroupbox("Movement")
moveGroup:AddToggle("Move_InfJump", { Text = "Infinite Jump", Default = false, Callback = function(v) S.InfJump = v end })
moveGroup:AddToggle("Move_Noclip", { Text = "Noclip", Default = false, Callback = function(v) S.Noclip = v updNoclip() end })
moveGroup:AddToggle("Move_Fly", { Text = "Fly", Default = false, Callback = function(v) S.FlyEnabled = v updateFly() end })
moveGroup:AddSlider("Move_WalkSpeed", { Text = "WalkSpeed", Default = 16, Min = 16, Max = 200, Rounding = 0, Compact = true, Callback = function(v) S.WalkSpeed = v end })
moveGroup:AddSlider("Move_JumpPower", { Text = "JumpPower", Default = 50, Min = 50, Max = 300, Rounding = 0, Compact = true, Callback = function(v) S.JumpPower = v end })
moveGroup:AddSlider("Move_FlySpeed", { Text = "Fly Speed", Default = 50, Min = 16, Max = 750, Rounding = 0, Compact = true, Callback = function(v) S.FlySpeed = v end })

local velGroup = MovementTab:AddRightGroupbox("Velocity Movement")
velGroup:AddToggle("Vel_Walk", { Text = "Velocity Walk", Default = false, Callback = function(v) S.VelocityWalkEnabled = v end }):AddKeyPicker("Vel_Walk_Key", { Default = "None", NoUI = true, Mode = "Toggle", SyncToggleState = false, Callback = function(state) S.VelocityWalkKey = state end })
velGroup:AddSlider("Vel_WalkSpeed", { Text = "Walk Speed", Default = 30, Min = 16, Max = 750, Rounding = 0, Compact = true, Callback = function(v) S.VelocityWalkSpeed = v end })
velGroup:AddToggle("Vel_Fly", { Text = "Velocity Fly", Default = false, Callback = function(v) S.VelocityFlyEnabled = v end }):AddKeyPicker("Vel_Fly_Key", { Default = "None", NoUI = true, Mode = "Toggle", SyncToggleState = false, Callback = function(state) S.VelocityFlyKey = state end })
velGroup:AddSlider("Vel_FlySpeed", { Text = "Fly Speed", Default = 50, Min = 16, Max = 750, Rounding = 0, Compact = true, Callback = function(v) S.VelocityFlySpeed = v end })

-- === Gun ===
local gunGroup = GunTab:AddLeftGroupbox("Gun Mods")
gunGroup:AddToggle("Gun_AntiKatana", { Text = "Anti Katana", Default = false, Callback = function(v) S.AntiKatana = v end })
gunGroup:AddToggle("Gun_NoCooldown", { Text = "No Cooldown", Default = false, Callback = function(v) S.NoCooldown = v end })
gunGroup:AddToggle("Gun_NoSpread", { Text = "No Spread", Default = false, Callback = function(v) S.NoSpread = v end })
gunGroup:AddToggle("Gun_NoRecoil", { Text = "No Recoil", Default = false, Callback = function(v) S.NoRecoil = v end })
gunGroup:AddToggle("Gun_MaxAccuracy", { Text = "Max Accuracy", Default = false, Callback = function(v) S.MaxAccuracy = v end })
gunGroup:AddToggle("Gun_RapidAttack", { Text = "Rapid Attack", Default = false, Callback = function(v) S.RapidAttack = v end })
gunGroup:AddToggle("Gun_NoMuzzleFlash", { Text = "No Muzzle Flash", Default = false, Callback = function(v) S.NoMuzzleFlash = v end })

-- === Misc ===
local deviceGroup = MiscTab:AddLeftGroupbox("Device Spoof")
deviceGroup:AddToggle("Device_Spoof", { Text = "Enable", Default = false, Callback = function(v) S.DeviceSpoof = v applyDeviceSpoof() end })
deviceGroup:AddDropdown("Device_Type", { Text = "Type", Default = "PC", Values = {"PC","Console","Mobile","VR"}, Callback = function(v) S.DeviceType = v if S.DeviceSpoof then applyDeviceSpoof() end end })

local hitFXGroup = MiscTab:AddLeftGroupbox("Hit Effects")
hitFXGroup:AddToggle("HitFX_Enabled", { Text = "Enable", Default = false, Callback = function(v) S.HitEffectsEnabled = v end }):AddColorPicker("HitFX_Color", { Default = Color3.fromRGB(159, 133, 195), Title = "Color", Callback = function(v) S.HitEffectColor = v end })
hitFXGroup:AddDropdown("HitFX_Styles", { Text = "Style", Default = {"Particles"}, Values = {"Particles","Fortnite","Shockwave","Lightning","Blood","Fire","Stars","Neon","Plasma","Sparks","Confetti"}, Multi = true, Callback = function(v) S.HitEffectStyles = v end })
hitFXGroup:AddSlider("HitFX_Float", { Text = "Float Speed", Default = 7, Min = 1, Max = 25, Rounding = 1, Compact = true, Callback = function(v) S.HitEffectFloatSpeed = v end })
hitFXGroup:AddSlider("HitFX_Alive", { Text = "Alive Time", Default = 2.8, Min = 0.5, Max = 8, Rounding = 1, Compact = true, Callback = function(v) S.HitEffectAliveTime = v S.HitEffectAliveScale = v / 2.8 end })

local hitSoundGroup = MiscTab:AddLeftGroupbox("Hit Sounds")
hitSoundGroup:AddToggle("HS_Enabled", { Text = "Enable", Default = false, Callback = function(v) S.HitSoundEnabled = v end })
hitSoundGroup:AddDropdown("HS_Style", { Text = "Sound", Default = "Rust HS", Values = {"Rust HS","Among Us","Bonk","Bruh","Fart","Minecraft","Neverlose","Osu","Stars","Vine"}, Callback = function(v) S.HitSoundStyle = v end })
hitSoundGroup:AddSlider("HS_Volume", { Text = "Volume", Default = 50, Min = 1, Max = 100, Rounding = 0, Compact = true, Callback = function(v) S.HitSoundVolume = v / 100 end })
hitSoundGroup:AddSlider("HS_Pitch", { Text = "Pitch", Default = 100, Min = 50, Max = 200, Rounding = 0, Compact = true, Callback = function(v) S.HitSoundPitch = v / 100 end })

local vmGroup = MiscTab:AddRightGroupbox("ViewModel Chams")
vmGroup:AddToggle("VM_GunChams", { Text = "Gun Chams", Default = false, Callback = function(v) S.GunChamsEnabled = v updChams() end }):AddColorPicker("VM_GunColor1", { Default = Color3.fromRGB(255, 255, 255), Title = "Color 1", Callback = function(v) S.GunColor1 = v end }):AddColorPicker("VM_GunColor2", { Default = Color3.fromRGB(255, 255, 255), Title = "Color 2", Callback = function(v) S.GunColor2 = v end }):AddColorPicker("VM_GunColor3", { Default = Color3.fromRGB(255, 255, 255), Title = "Color 3", Callback = function(v) S.GunColor3 = v end })
vmGroup:AddToggle("VM_ArmChams", { Text = "Arm Chams", Default = false, Callback = function(v) S.ArmChamsEnabled = v updChams() end }):AddColorPicker("VM_ArmColor1", { Default = Color3.fromRGB(255, 255, 255), Title = "Color 1", Callback = function(v) S.ArmColor1 = v end }):AddColorPicker("VM_ArmColor2", { Default = Color3.fromRGB(255, 255, 255), Title = "Color 2", Callback = function(v) S.ArmColor2 = v end }):AddColorPicker("VM_ArmColor3", { Default = Color3.fromRGB(255, 255, 255), Title = "Color 3", Callback = function(v) S.ArmColor3 = v end })
vmGroup:AddToggle("VM_GunOutline", { Text = "Gun Outline", Default = false, Callback = function(v) S.GunOutlineEnabled = v updChams() end }):AddColorPicker("VM_GunOutlineColor1", { Default = Color3.fromRGB(255, 255, 255), Title = "Color 1", Callback = function(v) S.GunOutlineColor1 = v end }):AddColorPicker("VM_GunOutlineColor2", { Default = Color3.fromRGB(255, 255, 255), Title = "Color 2", Callback = function(v) S.GunOutlineColor2 = v end }):AddColorPicker("VM_GunOutlineColor3", { Default = Color3.fromRGB(255, 255, 255), Title = "Color 3", Callback = function(v) S.GunOutlineColor3 = v end })
vmGroup:AddToggle("VM_ArmOutline", { Text = "Arm Outline", Default = false, Callback = function(v) S.ArmOutlineEnabled = v updChams() end }):AddColorPicker("VM_ArmOutlineColor1", { Default = Color3.fromRGB(255, 255, 255), Title = "Color 1", Callback = function(v) S.ArmOutlineColor1 = v end }):AddColorPicker("VM_ArmOutlineColor2", { Default = Color3.fromRGB(255, 255, 255), Title = "Color 2", Callback = function(v) S.ArmOutlineColor2 = v end }):AddColorPicker("VM_ArmOutlineColor3", { Default = Color3.fromRGB(255, 255, 255), Title = "Color 3", Callback = function(v) S.ArmOutlineColor3 = v end })
vmGroup:AddToggle("VM_DisableArms", { Text = "Disable Arms", Default = false, Callback = function(v) S.DisableArmsEnabled = v updChams() end })

local miscGroup = MiscTab:AddRightGroupbox("Misc")
miscGroup:AddToggle("Misc_TeamCheck", { Text = "Team Check", Default = true, Callback = function(v) S.TeamCheck = v end })
miscGroup:AddToggle("Misc_AntiAFK", { Text = "Anti AFK", Default = true, Callback = function(v) S.AntiAFK = v end })
miscGroup:AddToggle("Misc_AntiTrip", { Text = "Anti Subspace Tripmine", Default = false, Callback = function(v) S.AntiTripEnabled = v updAntiTrip() end })
miscGroup:AddToggle("Misc_AntiFlashbang", { Text = "Anti Flashbang", Default = false, Callback = function(v) S.AntiFlashbangEnabled = v if v then patchFlashbang() end end })
miscGroup:AddButton({ Text = "Unload Script", Func = function()
    pcall(function() RunService:UnbindFromRenderStep(AIMBOT_BIND) end)
    pcall(function() RunService:UnbindFromRenderStep(CHAM_BIND) end)
    if antiAimConn then antiAimConn:Disconnect() end
    if backshootMonitorConn then backshootMonitorConn:Disconnect() end
    if Rage.syncConn then Rage.syncConn:Disconnect() end
    if espGui then espGui:Destroy() end
    for _, line in ipairs(crosshairLines) do pcall(function() line:Remove() end) end
    for k, _ in pairs(espCache) do clESP(k) end
    cleanupFly()
    Library:Unload()
end })

-- SaveManager
if SaveManager then
    pcall(function() SaveManager:BuildConfigSection(ConfigTab) end)
    pcall(function() SaveManager:LoadAutoloadConfig() end)
end

-- ========== 主迴圈 ==========
RunService.RenderStepped:Connect(function(dt)
    tGlobal = tGlobal + dt
    if not C then C = W.CurrentCamera end
    if not C then return end

    if S.AimEnabled then
        if UIS:IsKeyDown(Enum.KeyCode.Q) then
            if not aimTarget or not isAliveEntry(aimTarget) then
                local best, bestDist = nil, math.huge
                local camPos = C.CFrame.Position
                for _, p in ipairs(getEnemies()) do
                    local e = {model = p.Character, player = p}
                    local part = getAimPart(e)
                    if part then
                        local d = (part.Position - camPos).Magnitude
                        if d < bestDist and hasLOS(part, e.model) then best, bestDist = e, d end
                    end
                end
                aimTarget = best
            end
        else
            aimTarget = findNearestInFOV()
        end
    else
        aimTarget = nil
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

Library:Notify({ Title = "v3 Hub", Description = "grief.cc 優勢功能移植完成", Time = 4 })
print("[v3 Hub] 完整載入完成")
