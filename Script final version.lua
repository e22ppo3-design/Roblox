-- ============================================================
-- AXIOM RIVALS v9.2 // Grief.cc 功能 + Obsidian GUI + 槍皮解鎖
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
    print("[v9.2] Kick hook 已安裝")
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

-- ============================================================
-- 槍皮解鎖（皮膚 / 飾品 / 包裝）
-- ============================================================
task.wait(4)

local _plrs = game:GetService("Players")
local _rs = game:GetService("ReplicatedStorage")
local _http = game:GetService("HttpService")
local _lp = _plrs.LocalPlayer
local _ctrl = _lp.PlayerScripts.Controllers
local _mods = _rs:WaitForChild("Modules", 10)

local _enumLib = require(_mods:WaitForChild("EnumLibrary", 10))
if _enumLib then pcall(function() _enumLib:WaitForEnumBuilder() end) end

local _cosLib = require(_mods:WaitForChild("CosmeticLibrary", 10))
local _itmLib = require(_mods:WaitForChild("ItemLibrary", 10))
local _datCtrl = require(_ctrl:WaitForChild("PlayerDataController", 10))

local _eq, _favs = {}, {}
local _buildingWep = nil

local _cosTypes = {"Skin","Wrap","Charm","Finisher","Emote"}

local function _isCosType(cosObj)
    if not cosObj then return false end
    for _, t in ipairs(_cosTypes) do
        if cosObj.Type == t then return true end
    end
    return false
end

local function _mkCosmetic(nm, ctype, opts)
    local _base = _cosLib.Cosmetics[nm]
    if not _base then return nil end
    local _d = {}
    for k, v in pairs(_base) do _d[k] = v end
    _d.Name = nm
    _d.Type = _d.Type or ctype
    _d.Seed = _d.Seed or math.random(1, 1000000)
    if opts then
        if opts.inverted ~= nil then _d.Inverted = opts.inverted end
        if opts.favoritesOnly ~= nil then _d.OnlyUseFavorites = opts.favoritesOnly end
    end
    return _d
end

local _cfgFile = "rivals_unlocker_config.json"
local _saveLock = false

local function _stripForSave()
    local _out = {}
    for wn, cos in pairs(_eq) do
        _out[wn] = {}
        for ct, cd in pairs(cos) do
            if cd and cd.Name then
                _out[wn][ct] = {Name = cd.Name, Inverted = cd.Inverted, OnlyUseFavorites = cd.OnlyUseFavorites}
            end
        end
    end
    return {equipped = _out, favorites = _favs}
end

local function _loadCfg()
    if not isfile or not readfile then return end
    local _ok1, _ex = pcall(isfile, _cfgFile)
    if not _ok1 or not _ex then return end
    local _ok2, _raw = pcall(readfile, _cfgFile)
    if not _ok2 or not _raw or _raw == "" then return end
    local _ok3, _dec = pcall(_http.JSONDecode, _http, _raw)
    if not _ok3 or not _dec then return end
    if _dec.favorites then _favs = _dec.favorites end
    if _dec.equipped then
        _eq = {}
        for wn, cos in pairs(_dec.equipped) do
            _eq[wn] = {}
            for ct, sd in pairs(cos) do
                if sd and sd.Name and _cosLib.Cosmetics[sd.Name] then
                    local _cloned = _mkCosmetic(sd.Name, ct, {
                        inverted = sd.Inverted,
                        favoritesOnly = sd.OnlyUseFavorites
                    })
                    if _cloned then _eq[wn][ct] = _cloned end
                end
            end
            if not next(_eq[wn]) then _eq[wn] = nil end
        end
    end
end

local function _saveCfg()
    if not writefile or _saveLock then return end
    _saveLock = true
    task.spawn(function()
        task.wait(1)
        local _payload = _stripForSave()
        local _ok, _enc = pcall(_http.JSONEncode, _http, _payload)
        if _ok then pcall(writefile, _cfgFile, _enc) end
        _saveLock = false
    end)
end

_loadCfg()

_cosLib.OwnsCosmeticNormally = function(self, inv, nm, wep)
    local c = _cosLib.Cosmetics[nm]
    if c and _isCosType(c) then return true end
    return false
end
_cosLib.OwnsCosmeticUniversally = function(self, inv, nm, wep)
    local c = _cosLib.Cosmetics[nm]
    if c and _isCosType(c) then return true end
    return false
end
_cosLib.OwnsCosmeticForWeapon = function(self, inv, nm, wep)
    local c = _cosLib.Cosmetics[nm]
    if c and _isCosType(c) then return true end
    return false
end

local _origOwns = _cosLib.OwnsCosmetic
_cosLib.OwnsCosmetic = function(self, inv, nm, wep)
    if nm:find("MISSING_") or nm == "Bubble Gun" then
        return _origOwns(self, inv, nm, wep)
    end
    local c = _cosLib.Cosmetics[nm]
    if c and _isCosType(c) then return true end
    return _origOwns(self, inv, nm, wep)
end

local _origGet = _datCtrl.Get
_datCtrl.Get = function(self, key)
    local _val = _origGet(self, key)
    if key == "CosmeticInventory" then
        local _prx = {}
        if _val then
            for k, v in pairs(_val) do
                local c = _cosLib.Cosmetics[k]
                if c and _isCosType(c) then _prx[k] = v end
            end
        end
        return setmetatable(_prx, {
            __index = function(t, k)
                local c = _cosLib.Cosmetics[k]
                if c and _isCosType(c) then
                    return {Name = k, Owned = true, Seed = 0}
                end
                return nil
            end
        })
    end
    if key == "FavoritedCosmetics" then
        local _res = _val and table.clone(_val) or {}
        for wep, fv in pairs(_favs) do
            _res[wep] = _res[wep] or {}
            for nm, isFav in pairs(fv) do
                local c = _cosLib.Cosmetics[nm]
                if c and _isCosType(c) then _res[wep][nm] = isFav end
            end
        end
        return _res
    end
    return _val
end

local _origGetWep = _datCtrl.GetWeaponData
_datCtrl.GetWeaponData = function(self, wn)
    local _d = _origGetWep(self, wn)
    if not _d then return nil end
    local _m = {}
    for k, v in pairs(_d) do _m[k] = v end
    _m.Name = wn
    if _eq[wn] then
        for ct, cd in pairs(_eq[wn]) do _m[ct] = cd end
    end
    return _m
end

local _fightCtrl
pcall(function()
    _fightCtrl = require(_ctrl:WaitForChild("FighterController", 10))
end)

if hookmetamethod then
    local _remotes = _rs:FindFirstChild("Remotes")
    local _dataRem = _remotes and _remotes:FindFirstChild("Data")
    local _equipRem = _dataRem and _dataRem:FindFirstChild("EquipCosmetic")
    local _favRem = _dataRem and _dataRem:FindFirstChild("FavoriteCosmetic")
    local _repRem = _remotes and _remotes:FindFirstChild("Replication")
    local _fightRem = _repRem and _repRem:FindFirstChild("Fighter")
    local _useItmRem = _fightRem and _fightRem:FindFirstChild("UseItem")

    if _equipRem then
        local _onc
        _onc = hookmetamethod(game, "__namecall", function(self, ...)
            if getnamecallmethod() ~= "FireServer" then
                return _onc(self, ...)
            end
            local _a = {...}

            if _useItmRem and self == _useItmRem then
                local _oid = _a[1]
                if _fightCtrl then
                    pcall(function()
                        local _f = _fightCtrl:GetFighter(_lp)
                        if _f and _f.Items then
                            for _, itm in pairs(_f.Items) do
                                if itm:Get("ObjectID") == _oid then
                                    _lastWep = itm.Name
                                    break
                                end
                            end
                        end
                    end)
                end
            end

            if self == _equipRem then
                local _wn = _a[1]
                local _ct = _a[2]
                local _cn = _a[3]
                local _opts = _a[4] or {}
                if _cn and _cn ~= "None" and _cn ~= "" then
                    local _inv = _datCtrl:Get("CosmeticInventory")
                    if _inv and rawget(_inv, _cn) then
                        return _onc(self, ...)
                    end
                end
                _eq[_wn] = _eq[_wn] or {}
                if not _cn or _cn == "None" or _cn == "" then
                    _eq[_wn][_ct] = nil
                    if not next(_eq[_wn]) then _eq[_wn] = nil end
                else
                    local _cloned = _mkCosmetic(_cn, _ct, {
                        inverted = _opts.IsInverted,
                        favoritesOnly = _opts.OnlyUseFavorites
                    })
                    if _cloned then _eq[_wn][_ct] = _cloned end
                end
                task.defer(function()
                    pcall(function() _datCtrl.CurrentData:Replicate("WeaponInventory") end)
                end)
                _saveCfg()
                return
            end

            if self == _favRem then
                local _cos = _cosLib.Cosmetics[_a[2]]
                if _cos then
                    _favs[_a[1]] = _favs[_a[1]] or {}
                    _favs[_a[1]][_a[2]] = _a[3] or nil
                    task.spawn(function()
                        pcall(function() _datCtrl.CurrentData:Replicate("FavoritedCosmetics") end)
                    end)
                    _saveCfg()
                end
                return
            end

            return _onc(self, ...)
        end)
    end
end

local _cliItem
pcall(function()
    _cliItem = require(_lp.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem)
end)

if _cliItem and _cliItem._CreateViewModel then
    local _origCVM = _cliItem._CreateViewModel
    _cliItem._CreateViewModel = function(self, vmRef)
        local _wn = self.Name
        local _wp = self.ClientFighter and self.ClientFighter.Player
        _buildingWep = (_wp == _lp) and _wn or nil
        if _wp == _lp and _eq[_wn] then
            local _cos = _eq[_wn]
            if _cos.Skin then
                pcall(function()
                    vmRef.Skin = _cos.Skin
                    vmRef.Name = _cos.Skin.Name
                end)
            end
            if _cos.Charm then pcall(function() vmRef.Charm = _cos.Charm end) end
            if _cos.Wrap then pcall(function() vmRef.Wrap = _cos.Wrap end) end
        end
        local _r = _origCVM(self, vmRef)
        _buildingWep = nil
        return _r
    end
end

local _vmMod = _lp.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
if _vmMod then
    local _CVM = require(_vmMod)
    local _origNew = _CVM.new
    _CVM.new = function(repData, cliItm)
        local _wp = cliItm.ClientFighter and cliItm.ClientFighter.Player
        local _wn = _buildingWep or cliItm.Name
        if _wp == _lp and _eq[_wn] then
            local _cos = _eq[_wn]
            if _cos.Skin then
                pcall(function()
                    repData.Skin = _cos.Skin
                    repData.Name = _cos.Skin.Name
                end)
            end
            if _cos.Charm then pcall(function() repData.Charm = _cos.Charm end) end
            if _cos.Wrap then pcall(function() repData.Wrap = _cos.Wrap end) end
        end
        return _origNew(repData, cliItm)
    end
end

local function unlockAllSkin()
    local count = 0
    for nm, cos in pairs(_cosLib.Cosmetics) do
        if cos and _isCosType(cos) then count = count + 1 end
    end
    print("[v9.2] Unlock All Skin 已執行 | 總共 " .. count .. " 個化妝品")
    return count
end

getgenv().UnlockAllSkin = unlockAllSkin
getgenv().GetCosmeticCount = function()
    local count = 0
    for nm, cos in pairs(_cosLib.Cosmetics) do
        if cos and _isCosType(cos) then count = count + 1 end
    end
    return count
end

print("[v9.2] 槍皮解鎖已載入 | 化妝品總數:", getgenv().GetCosmeticCount())

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

print("[v9.2] Utility:", Utility ~= nil, "| EnumLibrary:", EnumLibrary ~= nil)
print("[v9.2] Fighter:", FighterController ~= nil, "| Camera:", CameraController ~= nil)
print("[v9.2] Gun:", GunModule ~= nil, "| Melee:", MeleeModule ~= nil)
print("[v9.2] UseItem:", UseItem ~= nil, "| SetControls:", SetControls ~= nil)

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
    CrosshairShowLines = true, CrosshairShowAmmo = false,
    CrosshairSpinSpeed = 150, CrosshairGradRotation = 0, CrosshairMode = "static",
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
    print("[v9.2] Gun NoCooldown hook 已安裝")
end

if GunModule and GunModule._Recoil then
    local origRecoil = GunModule._Recoil
    GunModule._Recoil = function(self, multiplier)
        if S.NoRecoil then return end
        return origRecoil(self, multiplier)
    end
    print("[v9.2] Gun NoRecoil hook 已安裝")
end

if GameplayUtility and GameplayUtility.GetSpread then
    local origSpread = GameplayUtility.GetSpread
    GameplayUtility.GetSpread = function(self, aimMultiplier, isAiming, isCrouching, pelletIndex, totalPellets, consistent)
        if S.NoSpread or S.MaxAccuracy then
            return CFrame.new()
        end
        return origSpread(self, aimMultiplier, isAiming, isCrouching, pelletIndex, totalPellets, consistent)
    end
    print("[v9.2] Gun NoSpread hook 已安裝（修正版）")
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
    print("[v9.2] Melee RapidAttack hook 已安裝")
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

-- ========== Obsidian GUI ==========
local ObsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local ok = pcall(function()
    loadstring(game:HttpGet(ObsidianRepo .. "Library.lua"))()
end)
if not ok then
    warn("[v9.2] Obsidian 載入失敗")
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
    Title = "AXIOM // RIVALS v9.2",
    Footer = "Grief.cc 功能 | Obsidian GUI | 槍皮解鎖",
    Center = true, AutoShow = true, NotifySide = "Right", ShowCustomCursor = false
})

local CombatTab = Window:AddTab("Combat", "swords")
local VisualsTab = Window:AddTab("Visuals", "eye")
local MovementTab = Window:AddTab("Movement", "person-standing")
local GunTab = Window:AddTab("Gun", "crosshair")
local SkinTab = Window:AddTab("Skin", "shirt")
local MiscTab = Window:AddTab("Misc", "circle-ellipsis")

-- Combat: Silent Aim
local silentGroup = CombatTab:AddLeftGroupbox("Silent Aim")
silentGroup:AddToggle("Silent_Enabled", {
    Text = "Enable Silent Aim", Default = false,
    Callback = function(v) S.SilentEnabled = v end
}):AddKeyPicker("Silent_Key", {
    Text = "Silent Aim", Default = "None", Mode = "Toggle", NoUI = true,
    SyncToggleState = true, Callback = function(state) S.SilentEnabled = state end
})
silentGroup:AddToggle("Silent_AutoShoot", {
    Text = "Auto Shoot", Default = false,
    Callback = function(v) S.SilentAutoShoot = v end
})
silentGroup:AddDropdown("Silent_HitPart", {
    Text = "Hit Part", Default = "Head",
    Values = {"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso","Closest","Random"},
    Callback = function(v) S.SilentHitPart = v end
})
silentGroup:AddSlider("Silent_FOV", {
    Text = "FOV Radius", Default = 150, Min = 10, Max = 800, Rounding = 0, Compact = true,
    Callback = function(v) S.SilentFOV = v end
})
silentGroup:AddSlider("Silent_HitChance", {
    Text = "Hit Chance %", Default = 100, Min = 0, Max = 100, Rounding = 0, Compact = true,
    Callback = function(v) S.SilentHitChance = v end
})
silentGroup:AddToggle("Silent_FollowMuzzle", {
    Text = "Follow Muzzle", Default = false,
    Callback = function(v) S.SilentFollowMuzzle = v end
})
silentGroup:AddToggle("Silent_ShowFOV", {
    Text = "Show FOV", Default = false,
    Callback = function(v) S.SilentShowFOV = v end
}):AddColorPicker("Silent_FOVColor", {
    Default = Color3.fromRGB(0, 240, 200), Title = "FOV Color",
    Callback = function(v) S.SilentFOVColor = v end
})

-- Combat: Aimbot
local aimGroup = CombatTab:AddRightGroupbox("Aimbot")
aimGroup:AddToggle("Aimbot_Enabled", {
    Text = "Enable Aimbot", Default = false,
    Callback = function(v) S.AimEnabled = v updateAimbot() end
}):AddKeyPicker("Aimbot_Key", {
    Text = "Aimbot", Default = "None", Mode = "Toggle", NoUI = true,
    SyncToggleState = true, Callback = function(state) S.AimEnabled = state updateAimbot() end
})
aimGroup:AddDropdown("Aimbot_HitPart", {
    Text = "Hit Part", Default = "Head",
    Values = {"Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso"},
    Callback = function(v) S.AimHitPart = v end
})
aimGroup:AddSlider("Aimbot_Smoothness", {
    Text = "Smoothness", Default = 2, Min = 0.1, Max = 10, Rounding = 2, Compact = true,
    Callback = function(v) S.AimSmoothness = math.clamp(v, 0.1, 10) end
})
aimGroup:AddDropdown("Aimbot_Curve", {
    Text = "Aim Curve", Default = "Linear",
    Values = {"Linear","Expo","EaseIn","EaseOut","EaseInOut","Cubic","Instant"},
    Callback = function(v) S.AimCurve = v end
})
aimGroup:AddSlider("Aimbot_FOV", {
    Text = "FOV Radius", Default = 300, Min = 10, Max = 1000, Rounding = 0, Compact = true,
    Callback = function(v) S.AimFOV = v end
})
aimGroup:AddToggle("Aimbot_WallCheck", {
    Text = "Wall Check", Default = false,
    Callback = function(v) S.AimWallCheck = v end
})
aimGroup:AddToggle("Aimbot_FollowMuzzle", {
    Text = "Follow Muzzle", Default = false,
    Callback = function(v) S.AimFollowMuzzle = v end
})
aimGroup:AddToggle("Aimbot_ShowFOV", {
    Text = "Show FOV", Default = false,
    Callback = function(v) S.AimShowFOV = v end
}):AddColorPicker("Aimbot_FOVColor", {
    Default = Color3.fromRGB(255, 0, 140), Title = "FOV Color",
    Callback = function(v) S.AimFOVColor = v end
})

-- Combat: Backshoot
local backGroup = CombatTab:AddRightGroupbox("Backshoot")
backGroup:AddToggle("Backshoot_Enabled", {
    Text = "Enable Backshoot", Default = false,
    Callback = function(v) S.BackshootEnabled = v end
}):AddKeyPicker("Backshoot_Key", {
    Text = "Backshoot", Default = "None", Mode = "Toggle", NoUI = true,
    SyncToggleState = false, Callback = function(state) if state then toggleBackshoot() end end
})

-- Visuals
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
crossGroup:AddToggle("Crosshair_Enabled", {
    Text = "Enable Crosshair", Default = false,
    Callback = function(v) S.CrosshairEnabled = v end
}):AddColorPicker("Crosshair_Color", {
    Default = Color3.fromRGB(0, 200, 255), Title = "Color",
    Callback = function(v) S.CrosshairColor = v end
})
crossGroup:AddToggle("Crosshair_ShowLines", { Text = "Show Lines", Default = true, Callback = function(v) S.CrosshairShowLines = v end })
crossGroup:AddToggle("Crosshair_ShowAmmo", { Text = "Show Ammo", Default = false, Callback = function(v) S.CrosshairShowAmmo = v end })
crossGroup:AddSlider("Crosshair_Spin", { Text = "Spin Speed", Default = 150, Min = 0, Max = 340, Rounding = 0, Compact = true, Callback = function(v) S.CrosshairSpinSpeed = v end })
crossGroup:AddSlider("Crosshair_GradRot", { Text = "Gradient Rotation", Default = 0, Min = 0, Max = 360, Rounding = 0, Compact = true, Callback = function(v) S.CrosshairGradRotation = v end })
crossGroup:AddDropdown("Crosshair_Mode", { Text = "Mode", Default = "static", Values = {"static","follow muzzle"}, Callback = function(v) S.CrosshairMode = v end })

-- Movement
local moveGroup = MovementTab:AddLeftGroupbox("Movement")
moveGroup:AddToggle("Move_InfJump", { Text = "Infinite Jump", Default = false, Callback = function(v) S.InfJump = v end })
moveGroup:AddToggle("Move_Noclip", { Text = "Noclip", Default = false, Callback = function(v) S.Noclip = v end })
moveGroup:AddToggle("Move_Fly", { Text = "Fly", Default = false, Callback = function(v) S.FlyEnabled = v updateFly() end })
moveGroup:AddSlider("Move_WalkSpeed", { Text = "WalkSpeed", Default = 16, Min = 16, Max = 200, Rounding = 0, Compact = true, Callback = function(v) S.WalkSpeed = v end })
moveGroup:AddSlider("Move_JumpPower", { Text = "JumpPower", Default = 50, Min = 50, Max = 300, Rounding = 0, Compact = true, Callback = function(v) S.JumpPower = v end })
moveGroup:AddSlider("Move_FlySpeed", { Text = "Fly Speed", Default = 50, Min = 16, Max = 750, Rounding = 0, Compact = true, Callback = function(v) S.FlySpeed = v end })

-- Gun
local gunGroup = GunTab:AddLeftGroupbox("Gun Mods")
gunGroup:AddToggle("Gun_AntiKatana", { Text = "Anti Katana", Default = false, Callback = function(v) S.AntiKatana = v end })
gunGroup:AddToggle("Gun_NoCooldown", { Text = "No Cooldown", Default = false, Callback = function(v) S.NoCooldown = v end })
gunGroup:AddToggle("Gun_NoSpread", { Text = "No Spread", Default = false, Callback = function(v) S.NoSpread = v end })
gunGroup:AddToggle("Gun_NoRecoil", { Text = "No Recoil", Default = false, Callback = function(v) S.NoRecoil = v end })
gunGroup:AddToggle("Gun_MaxAccuracy", { Text = "Max Accuracy", Default = false, Callback = function(v) S.MaxAccuracy = v end })
gunGroup:AddToggle("Gun_RapidAttack", { Text = "Rapid Attack", Default = false, Callback = function(v) S.RapidAttack = v end })
gunGroup:AddToggle("Gun_NoMuzzleFlash", { Text = "No Muzzle Flash", Default = false, Callback = function(v) S.NoMuzzleFlash = v updateMuzzleFlash() end })

-- Skin Tab
local skinGroup = SkinTab:AddLeftGroupbox("Skin Unlocker")
skinGroup:AddLabel("皮膚 / 飾品 / 包裝 解鎖")
skinGroup:AddLabel("已載入 " .. tostring(getgenv().GetCosmeticCount and getgenv().GetCosmeticCount() or 0) .. " 個化妝品")
skinGroup:AddButton({
    Text = "Unlock All Skin",
    Func = function()
        if getgenv().UnlockAllSkin then
            local count = getgenv().UnlockAllSkin()
            Library:Notify({
                Title = "Unlock All Skin",
                Description = "已解鎖 " .. tostring(count) .. " 個化妝品",
                Time = 4
            })
        else
            Library:Notify({
                Title = "Unlock All Skin",
                Description = "解鎖模組未載入",
                Time = 4
            })
        end
    end
})

local skinGroupRight = SkinTab:AddRightGroupbox("Skin 類型")
skinGroupRight:AddLabel("Skin: 422 個")
skinGroupRight:AddLabel("Wrap: 382 個")
skinGroupRight:AddLabel("Charm: 296 個")
skinGroupRight:AddLabel("Finisher: 123 個")
skinGroupRight:AddLabel("Emote: 55 個")
skinGroupRight:AddLabel("總計: 1278 個")

-- Misc
local deviceGroup = MiscTab:AddLeftGroupbox("Device Spoof")
deviceGroup:AddToggle("Device_Spoof", { Text = "Enable", Default = false, Callback = function(v) S.DeviceSpoof = v applyDeviceSpoof() end })
deviceGroup:AddDropdown("Device_Type", { Text = "Type", Default = "PC", Values = {"PC","Console","Mobile","VR"}, Callback = function(v) S.DeviceType = v if S.DeviceSpoof then applyDeviceSpoof() end end })

local miscGroup = MiscTab:AddRightGroupbox("Misc")
miscGroup:AddToggle("Misc_TeamCheck", { Text = "隊伍檢測", Default = true, Callback = function(v) S.TeamCheck = v end })
miscGroup:AddToggle("Misc_AntiAFK", { Text = "反 AFK", Default = true, Callback = function(v) S.AntiAFK = v end })
miscGroup:AddButton({ Text = "卸載腳本", Func = function()
    pcall(function() RunService:UnbindFromRenderStep(AIMBOT_BIND) end)
    if espGui then espGui:Destroy() end
    for _, line in ipairs(crosshairLines) do pcall(function() line:Remove() end) end
    for k, _ in pairs(espCache) do clESP(k) end
    cleanupFly()
    if muzzleFlashConn then muzzleFlashConn:Disconnect() end
    Library:Unload()
end })

-- ========== 主迴圈 ==========
tGlobal = 0
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

Library:Notify({ Title = "AXIOM v9.2", Description = "載入完成 | 槍皮解鎖已整合", Time = 4 })
print("[v9.2] 完整載入完成")
