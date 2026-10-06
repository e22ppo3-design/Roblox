-- Axiom RIVALS v6.5 // 自瞄改用 yes.dev 邏輯 + Triggerbot + Device Spoofer
local openKeyPanel
local notify
local P=game:GetService("Players")
local R=game:GetService("RunService")
local U=game:GetService("UserInputService")
local T=game:GetService("TweenService")
local W=game:GetService("Workspace")
local C=W.CurrentCamera
local L=P.LocalPlayer
local HS=game:GetService("HttpService")
local VIM=game:GetService("VirtualInputManager")
local RS=game:GetService("ReplicatedStorage")
local rnd=function(n)local s=""for i=1,n do s=s..string.char(math.random(97,122))end return s end
local gn=rnd(12)
local pt=game:GetService("CoreGui")
if typeof(gethui)=="function" then
    local ok,h=pcall(gethui)
    if ok and h then pt=h end
end
pcall(function()if pt==game:GetService("CoreGui") and L:FindFirstChild("PlayerGui") then pt=L.PlayerGui end end)
if pt:FindFirstChild(gn)then pt[gn]:Destroy()end

local S={ESPEnabled=true,ShowName=true,ShowDistance=true,ShowHealth=true,ShowTracer=true,MaxDistance=2000,HueSpeed=0.25,
    WalkSpeed=16,JumpPower=50,Noclip=false,
    Aim=false,AimFOV=200,AimWall=false,TeamCheck=false,
    Triggerbot=true,TriggerMaxDistance=1000,
    FOVSmooth=true,
    AntiAFK=true,
    ChatNotify=true,
    JoinLeaveNotify=true,
    ChatKeywords={"noob","ez","lag","hack","cheat","report","kick","ban","aim","esp"},
    BHop=false,InfJump=false,Theme=1,
    HitboxVis=false,HitboxSize=2,
    Notify=true,
    HideKey=Enum.KeyCode.RightShift,GuiVisible=true,
    AimPart="Head",
    DeviceSpoofer_Active=nil,
    PanelTransparency=0.05,
    ShowFOV=true,
    ScanMode="auto"}
local THEMES={
    {name="霓虹青",S=Color3.fromRGB(0,240,200),P=Color3.fromRGB(255,0,140)},
    {name="紫電",S=Color3.fromRGB(120,80,255),P=Color3.fromRGB(255,120,60)},
    {name="烈焰",S=Color3.fromRGB(255,180,0),P=Color3.fromRGB(255,60,60)},
    {name="血月",S=Color3.fromRGB(255,0,80),P=Color3.fromRGB(120,0,200)},
}
local E={NameColor=Color3.fromRGB(255,255,255),DistanceColor=Color3.fromRGB(255,220,0),HealthColor=Color3.fromRGB(0,255,100),HueSpread=0.35}
local hc=0
local function hsv(h,s,v)return Color3.fromHSV(h%1,s,v)end
local function nw(c,p,pa)local o=Instance.new(c)for k,v in pairs(p)do o[k]=v end if pa then o.Parent=pa end return o end
local function cr(p,r)return nw("UICorner",{CornerRadius=r or UDim.new(0,8)},p)end
local function theme()return THEMES[S.Theme]end

local function entryFromModel(model, player)
    if not model or not model.Parent then return nil end
    local hum=model:FindFirstChildOfClass("Humanoid")
    local hrp=model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    local head=model:FindFirstChild("Head") or hrp
    if not hrp then return nil end
    if hum and hum.Health<=0 then return nil end
    return {model=model,hrp=hrp,head=head,player=player,humanoid=hum}
end
local function collectTargets()
    local out={}
    local seen={}
    for _,p in ipairs(P:GetPlayers())do
        if p~=L then
            local e=entryFromModel(p.Character,p)
            if e then table.insert(out,e) seen[e.model]=true end
        end
    end
    if S.ScanMode=="workspace" or (S.ScanMode=="auto" and #out==0) then
        for _,d in ipairs(W:GetDescendants())do
            if d:IsA("Humanoid") and d.Parent and not seen[d.Parent] then
                local e=entryFromModel(d.Parent,P:GetPlayerFromCharacter(d.Parent))
                if e then table.insert(out,e) seen[d.Parent]=true end
            end
        end
    end
    return out
end

local function getTeamColor(char)
    if not char then return nil end
    local shirt=char:FindFirstChild("Shirt")
    if shirt and shirt:IsA("Shirt") and shirt.ShirtTemplate and shirt.ShirtTemplate~="" then
        return shirt.ShirtTemplate
    end
    local parent=char.Parent
    if parent then
        local n=parent.Name:lower()
        if n:find("terror") or n:find("counter") or n:find("team") then return parent.Name end
    end
    return nil
end
local function isTeamEntry(entry)
    if not S.TeamCheck then return false end
    local myColor=getTeamColor(L.Character)
    local eColor=getTeamColor(entry.model)
    if not myColor or not eColor then return false end
    return myColor==eColor
end

-- ========== Device Spoofer ==========
local SetControlsRemote=nil
pcall(function()
    SetControlsRemote=RS:WaitForChild("Remotes",5):WaitForChild("Replication",5):WaitForChild("Fighter",5):WaitForChild("SetControls",5)
end)
local function spoofDevice(v)
    if not SetControlsRemote then return end
    pcall(function()SetControlsRemote:FireServer(v)end)
end

local KEYS={}; local KEY_NAMES={}; local KEY_MODES={}; local KEY_HOLD_STATE={}
local function bindKey(id,key)
    KEYS[id]=key
    if key==nil then KEY_NAMES[id]=nil
    elseif type(key)=="userdata" then KEY_NAMES[id]=key.Name
    else KEY_NAMES[id]=key end
    if not KEY_MODES[id] then KEY_MODES[id]="toggle" end
end
local MOUSE_IDS={MouseLeft=Enum.UserInputType.MouseButton1,MouseRight=Enum.UserInputType.MouseButton2,MouseMiddle=Enum.UserInputType.MouseButton3}
local KEY_ACTIONS={
    ESP=function(h)if h==true then S.ESPEnabled=true elseif h=="release"then S.ESPEnabled=false else S.ESPEnabled=not S.ESPEnabled end end,
    ShowName=function(h)if h==true then S.ShowName=true elseif h=="release"then S.ShowName=false else S.ShowName=not S.ShowName end end,
    ShowDistance=function(h)if h==true then S.ShowDistance=true elseif h=="release"then S.ShowDistance=false else S.ShowDistance=not S.ShowDistance end end,
    ShowHealth=function(h)if h==true then S.ShowHealth=true elseif h=="release"then S.ShowHealth=false else S.ShowHealth=not S.ShowHealth end end,
    ShowTracer=function(h)if h==true then S.ShowTracer=true elseif h=="release"then S.ShowTracer=false else S.ShowTracer=not S.ShowTracer end end,
    HitboxVis=function(h)if h==true then S.HitboxVis=true elseif h=="release"then S.HitboxVis=false else S.HitboxVis=not S.HitboxVis end end,
    Aim=function(h)if h==true then S.Aim=true elseif h=="release"then S.Aim=false else S.Aim=not S.Aim end notify(S.Aim and"自瞄 ON"or"自瞄 OFF")end,
    AimWall=function(h)if h==true then S.AimWall=true elseif h=="release"then S.AimWall=false else S.AimWall=not S.AimWall end end,
    Triggerbot=function(h)if h==true then S.Triggerbot=true elseif h=="release"then S.Triggerbot=false else S.Triggerbot=not S.Triggerbot end end,
    Noclip=function(h)if h==true then S.Noclip=true elseif h=="release"then S.Noclip=false else S.Noclip=not S.Noclip end end,
    BHop=function(h)if h==true then S.BHop=true elseif h=="release"then S.BHop=false else S.BHop=not S.BHop end end,
    InfJump=function(h)if h==true then S.InfJump=true elseif h=="release"then S.InfJump=false else S.InfJump=not S.InfJump end end,
    TeamCheck=function(h)if h==true then S.TeamCheck=true elseif h=="release"then S.TeamCheck=false else S.TeamCheck=not S.TeamCheck end end,
    AntiAFK=function(h)if h==true then S.AntiAFK=true elseif h=="release"then S.AntiAFK=false else S.AntiAFK=not S.AntiAFK end end,
    Hide=function(h)if h=="release"then return end S.GuiVisible=not S.GuiVisible end,
}
U.InputBegan:Connect(function(i,g)
    if g then return end
    if i.KeyCode==S.HideKey then S.GuiVisible=not S.GuiVisible return end
    for id,key in pairs(KEYS)do
        if key and type(key)=="userdata" and i.KeyCode==key then
            if KEY_MODES[id]=="hold" then
                if not KEY_HOLD_STATE[id] then KEY_HOLD_STATE[id]=true if KEY_ACTIONS[id] then KEY_ACTIONS[id](true) end end
            else
                if KEY_ACTIONS[id] then KEY_ACTIONS[id](false) end
            end
        end
    end
    if S.InfJump and i.KeyCode==Enum.KeyCode.Space then
        local c=L.Character local h=c and c:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping)end
    end
end)
U.InputBegan:Connect(function(i,g)
    if g then return end
    for id,key in pairs(KEYS)do
        if type(key)=="string" and MOUSE_IDS[key] and i.UserInputType==MOUSE_IDS[key] then
            if KEY_MODES[id]=="hold" then
                if not KEY_HOLD_STATE[id] then KEY_HOLD_STATE[id]=true if KEY_ACTIONS[id] then KEY_ACTIONS[id](true) end end
            else
                if KEY_ACTIONS[id] then KEY_ACTIONS[id](false) end
            end
        end
    end
end)
U.InputEnded:Connect(function(i)
    if i.KeyCode and i.KeyCode~=Enum.KeyCode.Unknown then
        for id,key in pairs(KEYS)do
            if key and type(key)=="userdata" and i.KeyCode==key and KEY_MODES[id]=="hold" then
                if KEY_HOLD_STATE[id] then KEY_HOLD_STATE[id]=false if KEY_ACTIONS[id] then KEY_ACTIONS[id]("release") end end
            end
        end
    end
    for id,key in pairs(KEYS)do
        if type(key)=="string" and MOUSE_IDS[key] and i.UserInputType==MOUSE_IDS[key] and KEY_MODES[id]=="hold" then
            if KEY_HOLD_STATE[id] then KEY_HOLD_STATE[id]=false if KEY_ACTIONS[id] then KEY_ACTIONS[id]("release") end end
        end
    end
end)

-- ========== ESP ==========
local espGui=nw("ScreenGui",{Name=gn.."ESP",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=2147483646,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},pt)
local cache={}; local ord={}
local function buildESP(key)
    if cache[key]then return cache[key]end
    local holder=nw("Frame",{Size=UDim2.fromOffset(0,0),BackgroundTransparency=1,Visible=false,BorderSizePixel=0},espGui)
    local nameLbl=nw("TextLabel",{BackgroundTransparency=1,TextColor3=E.NameColor,TextSize=14,Font=Enum.Font.Code,TextStrokeTransparency=0,TextStrokeColor3=Color3.fromRGB(0,0,0),Text="",Size=UDim2.fromOffset(200,18),Position=UDim2.new(0.5,-100,0,-22),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=2},holder)
    local distLbl=nw("TextLabel",{BackgroundTransparency=1,TextColor3=E.DistanceColor,TextSize=12,Font=Enum.Font.Code,TextStrokeTransparency=0,TextStrokeColor3=Color3.fromRGB(0,0,0),Text="",Size=UDim2.fromOffset(200,16),Position=UDim2.new(0.5,-100,1,2),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=2},holder)
    local box=nw("Frame",{BackgroundTransparency=1,BorderSizePixel=0,Visible=false,ZIndex=2},espGui)
    nw("UIStroke",{Color=Color3.fromRGB(255,255,255),Thickness=1.5},box)
    local tracer=nw("Frame",{BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,Visible=false,ZIndex=0},espGui)
    local hbVis=nw("Frame",{BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=0.7,BorderSizePixel=0,Visible=false,ZIndex=5},espGui)
    cr(hbVis,UDim.new(1,0))
    local hbBg=nw("Frame",{BackgroundColor3=Color3.fromRGB(40,40,40),BorderSizePixel=0,Size=UDim2.fromOffset(3,100),Visible=false,ZIndex=3},holder)
    local hbBar=nw("Frame",{BackgroundColor3=E.HealthColor,BorderSizePixel=0,Size=UDim2.new(1,0,1,0),Position=UDim2.new(0,0,0,0),ZIndex=4},hbBg)
    local d={holder=holder,name=nameLbl,dist=distLbl,box=box,tracer=tracer,hbVis=hbVis,hbBg=hbBg,hbBar=hbBar}
    cache[key]=d; table.insert(ord,key); return d
end
local function cl(key)
    local d=cache[key]; if not d then return end
    for _,o in pairs(d)do if o and o.Destroy then o:Destroy()end end
    cache[key]=nil
    for i,v in ipairs(ord)do if v==key then table.remove(ord,i)break end end
end
local function hd(d)
    if not d then return end
    d.holder.Visible=false; d.box.Visible=false; d.tracer.Visible=false; d.hbVis.Visible=false
end
local function ho(key)for i,v in ipairs(ord)do if v==key then return(i-1)*E.HueSpread end end return 0 end
local function rd(entry)
    local m=entry.model; local hrp=entry.hrp; local head=entry.head
    local key=m; local d=cache[key]or buildESP(key)
    if isTeamEntry(entry)then hd(d)return end
    if not S.ESPEnabled and not S.ShowTracer and not S.HitboxVis then hd(d)return end
    if not hrp or not hrp.Parent then hd(d)return end
    local rp=hrp.Position; local hp=head and head.Position or rp
    local ds=(C.CFrame.Position-rp).Magnitude
    if ds>S.MaxDistance then hd(d)return end
    local hrpV,hrpOn=C:WorldToViewportPoint(rp)
    local headV,headOn=C:WorldToViewportPoint(hp)
    if not hrpOn or not headOn then hd(d)return end
    local hPx=math.abs(hrpV.Y-headV.Y)*2.2
    if hPx<10 then hPx=10 end
    local wPx=hPx*0.5
    local cx=(hrpV.X+headV.X)/2
    local cy=(hrpV.Y+headV.Y)/2
    local co=hsv((hc+ds/2000*0.3)%1,1,1)
    d.holder.Position=UDim2.fromOffset(math.floor(cx-wPx/2),math.floor(cy-hPx/2))
    d.holder.Size=UDim2.fromOffset(math.floor(wPx),math.floor(hPx))
    d.holder.Visible=true; d.holder.BackgroundTransparency=1
    d.name.Visible=S.ShowName
    if S.ShowName then d.name.Text=m.Name end
    d.dist.Visible=S.ShowDistance
    if S.ShowDistance then d.dist.Text=string.format("[%d]",math.floor(ds))end
    if S.ESPEnabled then
        d.box.Visible=true
        d.box.Position=UDim2.fromOffset(0,0)
        d.box.Size=UDim2.fromOffset(math.floor(wPx),math.floor(hPx))
        local stroke=d.box:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color=co end
    else d.box.Visible=false end
    if S.ShowHealth and entry.humanoid and entry.humanoid.MaxHealth>0 then
        local rt=math.clamp(entry.humanoid.Health/entry.humanoid.MaxHealth,0,1)
        d.hbBg.Visible=true
        d.hbBg.Size=UDim2.fromOffset(3,math.floor(hPx))
        d.hbBg.Position=UDim2.new(0,-6,0,0)
        d.hbBar.Size=UDim2.new(1,0,rt,0)
        d.hbBar.Position=UDim2.new(0,0,1-rt,0)
        d.hbBar.BackgroundColor3=hsv(rt*0.33,1,1)
    else d.hbBg.Visible=false end
    if S.HitboxVis and head then
        local hV,hOn=C:WorldToViewportPoint(head.Position)
        if hOn then
            local scale=(C.CFrame.Position-head.Position).Magnitude
            local size2=math.clamp(2000/scale*S.HitboxSize,10,400)
            d.hbVis.Visible=true; d.hbVis.BackgroundColor3=co
            d.hbVis.Size=UDim2.fromOffset(math.floor(size2),math.floor(size2))
            d.hbVis.Position=UDim2.fromOffset(math.floor(hV.X-size2/2),math.floor(hV.Y-size2/2))
        else d.hbVis.Visible=false end
    else d.hbVis.Visible=false end
    if S.ShowTracer then
        local vp=C.ViewportSize.X; local vq=C.ViewportSize.Y
        local from=Vector2.new(vp/2,vq)
        local to=Vector2.new(cx,cy+hPx/2)
        local mid=(from+to)/2; local len=(to-from).Magnitude
        local ang=math.deg(math.atan2(to.Y-from.Y,to.X-from.X))
        d.tracer.Visible=true
        d.tracer.BackgroundColor3=co
        d.tracer.Size=UDim2.fromOffset(math.floor(len),1)
        d.tracer.Position=UDim2.fromOffset(math.floor(mid.X-len/2),math.floor(mid.Y))
        d.tracer.Rotation=ang
    else d.tracer.Visible=false end
end

-- ========== 自瞄（yes.dev 邏輯）==========
local lockedTarget=nil
local AutoclickActive=false

local sharedRaycastParams=RaycastParams.new()
sharedRaycastParams.FilterType=Enum.RaycastFilterType.Blacklist
local raycastBlacklistDirty=true
local raycastBlacklistTime=0
local function getSharedRaycastParams(targetChar)
    local now=os.clock()
    if raycastBlacklistDirty or now-raycastBlacklistTime>0.5 then
        local bl={}
        if L.Character then table.insert(bl,L.Character)end
        for _,p in ipairs(P:GetPlayers())do
            if p~=L and p.Character and p.Character~=targetChar then table.insert(bl,p.Character)end
        end
        sharedRaycastParams.FilterDescendantsInstances=bl
        raycastBlacklistDirty=false
        raycastBlacklistTime=now
    end
    return sharedRaycastParams
end
local function hasLineOfSight(targetPart)
    if not targetPart or not C then return false end
    local parent=targetPart.Parent
    if not parent then return false end
    local camPos=C.CFrame.Position
    local ok,targetPos=pcall(function()return targetPart.Position end)
    if not ok then return false end
    local offset=targetPos-camPos
    local dist=offset.Magnitude
    if dist<=0 then return false end
    local params=getSharedRaycastParams(parent)
    local ok2,res=pcall(function()return W:Raycast(camPos,offset.Unit*dist,params)end)
    if not ok2 then return true end
    if not res or not res.Instance then return true end
    return res.Instance:IsDescendantOf(parent)
end
local function getCrosshair()
    if not C then return Vector2.new(0,0) end
    if U.MouseBehavior==Enum.MouseBehavior.LockCenter then
        return Vector2.new(C.ViewportSize.X/2,C.ViewportSize.Y/2)
    end
    return U:GetMouseLocation()
end
local function worldToScreen(pos)
    if not C then return nil,false end
    local ok,res=pcall(function()return C:WorldToScreenPoint(pos)end)
    if not ok or not res then return nil,false end
    return Vector2.new(res.X,res.Y),res.Z>0
end
local function isEnemy(player)
    if not player or player==L then return false end
    if not S.TeamCheck then return true end
    local myColor=getTeamColor(L.Character)
    local pColor=getTeamColor(player.Character)
    if not myColor or not pColor then return true end
    return myColor~=pColor
end
local function getAimTarget()
    local crosshair=getCrosshair()
    local localChar=L.Character
    if not localChar then return nil end
    local localRoot=localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil end
    if lockedTarget then
        if not isEnemy(lockedTarget)then
            lockedTarget=nil
        else
            local ch=lockedTarget.Character
            local head=ch and ch:FindFirstChild("Head")
            local hum=ch and ch:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health>0 then
                local dist=(localRoot.Position-head.Position).Magnitude
                if dist>S.TriggerMaxDistance then
                    lockedTarget=nil
                elseif S.AimWall and not hasLineOfSight(head)then
                    lockedTarget=nil
                else
                    return head
                end
            else
                lockedTarget=nil
            end
        end
    end
    local bestPlayer,bestDist=nil,math.huge
    for _,e in ipairs(collectTargets())do
        if e.player and isEnemy(e.player)then
            local head=e.model:FindFirstChild("Head")
            if head then
                local dist3d=(localRoot.Position-head.Position).Magnitude
                if dist3d<=S.TriggerMaxDistance then
                    local sp,on=worldToScreen(head.Position)
                    if sp and on then
                        local d2=(sp-crosshair).Magnitude
                        if d2<=S.AimFOV then
                            if S.AimWall and not hasLineOfSight(head)then
                                -- skip
                            else
                                if d2<bestDist then bestDist=d2 bestPlayer=e.player end
                            end
                        end
                    end
                end
            end
        end
    end
    if bestPlayer then
        lockedTarget=bestPlayer
        return bestPlayer.Character:FindFirstChild("Head")
    end
    return nil
end
local function forceAimAtHead(head)
    if not head or not head.Parent or not C then return false end
    local char=L.Character
    if not char then return false end
    local root=char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local ok,headPos=pcall(function()return head.Position end)
    if not ok then return false end
    local camPos=C.CFrame.Position
    C.CFrame=CFrame.lookAt(camPos,headPos,Vector3.new(0,1,0))
    local rootPos=root.Position
    root.CFrame=CFrame.lookAt(rootPos,Vector3.new(headPos.X,rootPos.Y,headPos.Z),Vector3.new(0,1,0))
    return true
end
local function updateLockedBody()
    if not S.Aim or not lockedTarget then return end
    if not isEnemy(lockedTarget)then lockedTarget=nil return end
    local ch=lockedTarget.Character
    local head=ch and ch:FindFirstChild("Head")
    local hum=ch and ch:FindFirstChildOfClass("Humanoid")
    if not ch or not head or not hum or hum.Health<=0 then
        lockedTarget=nil return
    end
    if S.AimWall and not hasLineOfSight(head)then
        lockedTarget=nil return
    end
    forceAimAtHead(head)
end

-- Triggerbot
local HITBOX_PARTS={"Head","UpperTorso","LowerTorso","HumanoidRootPart","LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm","LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg"}
local function getHitboxBounds(part)
    if not C or not part or not part.Parent then return nil end
    local ok,cf,size=pcall(function()return part.CFrame,part.Size*0.5 end)
    if not ok or not cf or not size then return nil end
    local sx,sy,sz=size.X,size.Y,size.Z
    local corners={
        cf*Vector3.new(sx,sy,sz),cf*Vector3.new(-sx,sy,sz),
        cf*Vector3.new(sx,-sy,sz),cf*Vector3.new(-sx,-sy,sz),
        cf*Vector3.new(sx,sy,-sz),cf*Vector3.new(-sx,sy,-sz),
        cf*Vector3.new(sx,-sy,-sz),cf*Vector3.new(-sx,-sy,-sz),
    }
    local minX,minY=math.huge,math.huge
    local maxX,maxY=-math.huge,-math.huge
    local anyOn=false
    for _,c in ipairs(corners)do
        local ok2,res=pcall(function()return C:WorldToScreenPoint(c)end)
        if ok2 and res and res.Z>0 then
            anyOn=true
            if res.X<minX then minX=res.X end
            if res.Y<minY then minY=res.Y end
            if res.X>maxX then maxX=res.X end
            if res.Y>maxY then maxY=res.Y end
        end
    end
    if not anyOn then return nil end
    return minX,minY,maxX,maxY
end
local function shouldFire()
    if not C then return false end
    if S.Aim and lockedTarget and isEnemy(lockedTarget)then
        local ch=lockedTarget.Character
        local head=ch and ch:FindFirstChild("Head")
        local hum=ch and ch:FindFirstChildOfClass("Humanoid")
        if head and hum and hum.Health>0 then
            if hasLineOfSight(head)then
                if forceAimAtHead(head)then return true end
            else
                lockedTarget=nil
            end
        else
            lockedTarget=nil
        end
    end
    if not S.Triggerbot then return false end
    local crosshair=getCrosshair()
    local cx,cy=crosshair.X,crosshair.Y
    local camPos=C.CFrame.Position
    for _,e in ipairs(collectTargets())do
        if e.player and isEnemy(e.player)then
            local ch=e.model
            local hum=ch:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health>0 then
                local root=ch:FindFirstChild("HumanoidRootPart")
                if root and (root.Position-camPos).Magnitude<=S.TriggerMaxDistance then
                    for _,pn in ipairs(HITBOX_PARTS)do
                        local part=ch:FindFirstChild(pn)
                        if part then
                            if hasLineOfSight(part)then
                                local minX,minY,maxX,maxY=getHitboxBounds(part)
                                if minX and cx>=minX and cx<=maxX and cy>=minY and cy<=maxY then
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

-- FOV 圈（Drawing）
local fovCircleDraw=nil
pcall(function()
    if Drawing then
        fovCircleDraw=Drawing.new("Circle")
        fovCircleDraw.Thickness=2
        fovCircleDraw.Color=Color3.fromRGB(255,0,0)
        fovCircleDraw.Filled=false
        fovCircleDraw.Visible=false
    end
end)
local function updateCircle()
    if not fovCircleDraw then return end
    if S.Aim and S.ShowFOV then
        fovCircleDraw.Position=getCrosshair()
        fovCircleDraw.Radius=S.AimFOV
        fovCircleDraw.Visible=true
    else
        fovCircleDraw.Visible=false
    end
end

-- 自動開火迴圈
task.spawn(function()
    while true do
        if AutoclickActive then
            if not C then C=W.CurrentCamera end
            if C then
                local vp=C.ViewportSize
                if vp then
                    VIM:SendMouseButtonEvent(vp.X/2,vp.Y/2,0,true,game,0)
                    VIM:SendMouseButtonEvent(vp.X/2,vp.Y/2,0,false,game,0)
                end
            end
        end
        task.wait()
    end
end)

-- 主迴圈
R.RenderStepped:Connect(function()
    if not C then C=W.CurrentCamera end
    if not C then return end
    if not L.Character then return end
    updateCircle()
    hc=(hc+0.016*S.HueSpeed)%1
    local targets=collectTargets()
    for _,e in ipairs(targets)do pcall(rd,e)end
    local alive={}
    for _,e in ipairs(targets)do alive[e.model]=true end
    for k,_ in pairs(cache)do if not alive[k] then cl(k)end end
    if S.Aim then
        if lockedTarget then
            updateLockedBody()
        else
            local th=getAimTarget()
            if th then forceAimAtHead(th)end
        end
    else
        lockedTarget=nil
    end
    if S.Triggerbot then
        AutoclickActive=shouldFire()
    else
        AutoclickActive=false
    end
    -- 持續速度
    local myChar=L.Character
    if myChar then
        local hum=myChar:FindFirstChildOfClass("Humanoid")
        if hum then
            if hum.WalkSpeed~=S.WalkSpeed then hum.WalkSpeed=S.WalkSpeed end
            if hum.UseJumpPower~=true then hum.UseJumpPower=true end
            if hum.JumpPower~=S.JumpPower then hum.JumpPower=S.JumpPower end
        end
    end
    if S.BHop then
        local h=myChar:FindFirstChildOfClass("Humanoid")
        if h and h.FloorMaterial~=Enum.Material.Air then h.Jump=true end
    end
end)

R.Stepped:Connect(function()
    if S.Noclip and L.Character then
        for _,v in ipairs(L.Character:GetDescendants())do
            if v:IsA("BasePart")and v.CanCollide then v.CanCollide=false end
        end
    end
end)
L.CharacterAdded:Connect(function(c)
    task.wait(0.5)
    local h=c:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed=S.WalkSpeed h.UseJumpPower=true h.JumpPower=S.JumpPower end
end)

-- ========== GUI ==========
local K={Bg=Color3.fromRGB(10,10,16),Row=Color3.fromRGB(20,20,32),Text=Color3.fromRGB(230,230,245),Dim=Color3.fromRGB(120,120,150),Danger=Color3.fromRGB(255,70,100)}
local sc2=nw("ScreenGui",{Name=gn,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=true,DisplayOrder=2147483647},pt)
local PW=250
local mn=nw("Frame",{Size=UDim2.fromOffset(PW,660),Position=UDim2.new(0,20,0.1,0),BackgroundColor3=K.Bg,BackgroundTransparency=0.05,BorderSizePixel=0,ClipsDescendants=true,Active=true},sc2)
cr(mn,UDim.new(0,10))
nw("UIStroke",{Color=theme().S,Thickness=1.5,Transparency=0.3},mn)
local tb=nw("Frame",{Size=UDim2.new(1,0,0,38),BackgroundColor3=Color3.fromRGB(16,16,26),BorderSizePixel=0,ZIndex=5},mn)
cr(tb,UDim.new(0,10))
nw("TextLabel",{Size=UDim2.new(1,-70,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Text="AXIOM // RIVALS v6.5",TextColor3=K.Text,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7},tb)
local cp=nw("TextButton",{Size=UDim2.fromOffset(22,22),Position=UDim2.new(1,-54,0,8),BackgroundColor3=K.Row,Text="—",TextColor3=theme().S,Font=Enum.Font.GothamBold,TextSize=13,BorderSizePixel=0,AutoButtonColor=false,ZIndex=7},tb)
cr(cp,UDim.new(0,5))
local cx=nw("TextButton",{Size=UDim2.fromOffset(22,22),Position=UDim2.new(1,-28,0,8),BackgroundColor3=Color3.fromRGB(50,14,24),Text="×",TextColor3=K.Danger,Font=Enum.Font.GothamBold,TextSize=15,BorderSizePixel=0,AutoButtonColor=false,ZIndex=7},tb)
cr(cx,UDim.new(0,5))
local content=nw("ScrollingFrame",{Size=UDim2.new(1,-8,1,-46),Position=UDim2.new(0,4,0,42),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=theme().S,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=3},mn)
nw("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},content)
nw("UIPadding",{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,6)},content)
local orderCount=0
local function nextOrder()orderCount=orderCount+1 return orderCount end
local function makeTitle(text)
    local holder=nw("Frame",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=nextOrder()},content)
    local bar=nw("Frame",{Size=UDim2.fromOffset(3,14),Position=UDim2.new(0,4,0.5,-7),BackgroundColor3=theme().S,BorderSizePixel=0,ZIndex=2},holder)
    cr(bar,UDim.new(1,0))
    nw("TextLabel",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,14,0,0),BackgroundTransparency=1,Text=text,TextColor3=K.Text,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=2},holder)
end
local function makeToggle(t,bindId,cb)
    local holder=nw("Frame",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=nextOrder()},content)
    local b=nw("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundColor3=K.Row,BackgroundTransparency=0.2,Text="",AutoButtonColor=false,BorderSizePixel=0,ZIndex=2},holder)
    cr(b,UDim.new(0,7))
    nw("UIStroke",{Color=theme().S,Thickness=1,Transparency=0.7},b)
    local swBg=nw("Frame",{Size=UDim2.fromOffset(34,16),Position=UDim2.new(1,-44,0.5,-8),BackgroundColor3=Color3.fromRGB(40,40,55),BorderSizePixel=0,ZIndex=3},b)
    cr(swBg,UDim.new(1,0))
    local swKnob=nw("Frame",{Size=UDim2.fromOffset(12,12),Position=UDim2.new(0,2,0.5,-6),BackgroundColor3=K.Dim,BorderSizePixel=0,ZIndex=4},swBg)
    cr(swKnob,UDim.new(1,0))
    local l=nw("TextLabel",{Size=UDim2.new(1,-90,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Text=t,TextColor3=K.Text,TextSize=12,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3},b)
    local keyLbl=nw("TextLabel",{Size=UDim2.fromOffset(50,1),Position=UDim2.new(1,-76,0,0),BackgroundTransparency=1,Text="",TextColor3=theme().S,TextSize=10,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=3},b)
    local state=false
    local function refresh()
        swBg.BackgroundColor3=state and theme().S or Color3.fromRGB(40,40,55)
        swKnob.Position=state and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
        swKnob.BackgroundColor3=state and Color3.fromRGB(255,255,255) or K.Dim
    end
    refresh()
    b.MouseButton1Click:Connect(function()
        state=not state
        refresh()
        if cb then pcall(cb,state)end
    end)
    if bindId then
        b.MouseButton2Click:Connect(function()if openKeyPanel then openKeyPanel(bindId,b)end end)
        task.spawn(function()
            while b.Parent do
                local kn=KEY_NAMES[bindId]
                if kn then keyLbl.Text=KEY_MODES[bindId]=="hold" and("["..kn.."·H]")or("["..kn.."]") else keyLbl.Text="" end
                task.wait(0.3)
            end
        end)
    end
end
local function makeSlider(t,mn2,mx,df,cb)
    local holder=nw("Frame",{Size=UDim2.new(1,0,0,46),BackgroundColor3=K.Row,BackgroundTransparency=0.2,BorderSizePixel=0,LayoutOrder=nextOrder()},content)
    cr(holder,UDim.new(0,7))
    nw("UIStroke",{Color=theme().S,Thickness=1,Transparency=0.7},holder)
    nw("TextLabel",{Size=UDim2.new(1,-16,0,14),Position=UDim2.new(0,12,0,5),BackgroundTransparency=1,Text=t,TextColor3=K.Text,TextSize=11,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left},holder)
    local v=nw("TextLabel",{Size=UDim2.new(0,60,0,14),Position=UDim2.new(1,-72,0,5),BackgroundTransparency=1,Text=string.format("%.0f",df),TextColor3=theme().S,TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Right},holder)
    local tr=nw("Frame",{Size=UDim2.new(1,-24,0,8),Position=UDim2.new(0,12,0,28),BackgroundColor3=Color3.fromRGB(38,38,54),BorderSizePixel=0},holder)
    cr(tr,UDim.new(1,0))
    local fl=nw("Frame",{Size=UDim2.new((df-mn2)/(mx-mn2),0,1,0),BackgroundColor3=theme().S,BorderSizePixel=0},tr)
    cr(fl,UDim.new(1,0))
    local kn=nw("Frame",{Size=UDim2.fromOffset(14,14),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new((df-mn2)/(mx-mn2),0,0.5,0),BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,ZIndex=3},tr)
    cr(kn,UDim.new(1,0))
    nw("UIStroke",{Color=theme().S,Thickness=1.5},kn)
    local dg=false
    local function sf(x)
        local rl=math.clamp((x-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1)
        local vv=mn2+(mx-mn2)*rl
        fl.Size=UDim2.new(rl,0,1,0)
        kn.Position=UDim2.new(rl,0,0.5,0)
        v.Text=string.format("%.0f",vv)
        if cb then pcall(cb,vv)end
    end
    tr.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dg=true sf(i.Position.X) end end)
    U.InputChanged:Connect(function(i)if dg and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch)then sf(i.Position.X)end end)
    U.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dg=false end end)
end
local function makeButton(t,cb)
    local holder=nw("Frame",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=nextOrder()},content)
    local b=nw("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundColor3=K.Row,BackgroundTransparency=0.2,Text=t,TextColor3=K.Text,TextSize=12,Font=Enum.Font.GothamMedium,AutoButtonColor=false,BorderSizePixel=0,ZIndex=2},holder)
    cr(b,UDim.new(0,7))
    nw("UIStroke",{Color=theme().S,Thickness=1,Transparency=0.7},b)
    b.MouseButton1Click:Connect(function()if cb then pcall(cb,b)end end)
end

makeTitle("視覺")
makeToggle("ESP 開關","ESP",function(s)S.ESPEnabled=s end)
makeToggle("名字","ShowName",function(s)S.ShowName=s end)
makeToggle("距離","ShowDistance",function(s)S.ShowDistance=s end)
makeToggle("血量","ShowHealth",function(s)S.ShowHealth=s end)
makeToggle("追蹤線","ShowTracer",function(s)S.ShowTracer=s end)
makeToggle("Hitbox 顯示","HitboxVis",function(s)S.HitboxVis=s end)
makeSlider("彩虹速度",0,2,S.HueSpeed,function(v)S.HueSpeed=v end)
makeSlider("ESP 距離",100,5000,S.MaxDistance,function(v)S.MaxDistance=v end)

makeTitle("戰鬥")
makeToggle("自瞄開關","Aim",function(s)S.Aim=s notify(s and"自瞄 ON"or"自瞄 OFF")end)
makeToggle("自瞄牆檢","AimWall",function(s)S.AimWall=s end)
makeToggle("Triggerbot","Triggerbot",function(s)S.Triggerbot=s notify(s and"自動開火 ON"or"自動開火 OFF")end)
makeToggle("FOV 顯示","FOVSmooth",function(s)S.ShowFOV=s end)
makeSlider("FOV 半徑",30,800,S.AimFOV,function(v)S.AimFOV=v end)
makeSlider("觸發距離",100,2000,S.TriggerMaxDistance,function(v)S.TriggerMaxDistance=v end)

makeTitle("移動")
makeToggle("穿牆","Noclip",function(s)S.Noclip=s end)
makeToggle("Bunny Hop","BHop",function(s)S.BHop=s end)
makeToggle("無限跳躍","InfJump",function(s)S.InfJump=s end)
makeSlider("移動速度",16,200,S.WalkSpeed,function(v)S.WalkSpeed=v end)
makeSlider("跳躍力",50,300,S.JumpPower,function(v)S.JumpPower=v end)

makeTitle("其他")
makeToggle("隊伍檢測","TeamCheck",function(s)S.TeamCheck=s end)
makeToggle("反 AFK","AntiAFK",function(s)S.AntiAFK=s end)
makeToggle("聊天通知","ChatNotify",function(s)S.ChatNotify=s end)
makeToggle("進出通知","JoinLeaveNotify",function(s)S.JoinLeaveNotify=s end)

-- 裝置偽裝
makeTitle("裝置偽裝")
local DEVICES={{"PC","MouseKeyboard"},{"主機","Gamepad"},{"手機","Touch"},{"VR","VR"}}
for _,d in ipairs(DEVICES)do
    makeButton("偽裝為 "..d[1],function(b)
        if S.DeviceSpoofer_Active==d[2]then
            S.DeviceSpoofer_Active=nil
            spoofDevice("MouseKeyboard")
            b.Text="偽裝為 "..d[1]
        else
            S.DeviceSpoofer_Active=d[2]
            spoofDevice(d[2])
            b.Text="偽裝為 "..d[1].." [ON]"
        end
    end)
end

makeTitle("系統")
makeButton("掃描模式：自動",function(b)
    if S.ScanMode=="auto" then S.ScanMode="player"
    elseif S.ScanMode=="player" then S.ScanMode="workspace"
    else S.ScanMode="auto" end
    b.Text="掃描模式："..(S.ScanMode=="auto" and"自動"or S.ScanMode=="player" and"僅玩家"or"僅 Workspace")
end)
makeButton("隱藏 GUI",function()S.GuiVisible=not S.GuiVisible mn.Visible=S.GuiVisible end)

-- 快捷鍵
local keyPanel=nw("Frame",{Size=UDim2.fromOffset(200,166),BackgroundColor3=Color3.fromRGB(14,14,22),BackgroundTransparency=0.05,BorderSizePixel=0,Visible=false,ZIndex=300},sc2)
cr(keyPanel,UDim.new(0,8))
nw("UIStroke",{Color=theme().S,Thickness=1.5},keyPanel)
nw("TextLabel",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text="快捷鍵綁定",TextColor3=theme().S,TextSize=12,Font=Enum.Font.GothamBold},keyPanel)
nw("TextLabel",{Size=UDim2.new(1,-8,0,14),Position=UDim2.new(0,4,0,22),BackgroundTransparency=1,Text="按鍵盤或滑鼠鍵",TextColor3=K.Dim,TextSize=10,Font=Enum.Font.Code},keyPanel)
local kpCurrent=nw("TextButton",{Size=UDim2.new(1,-8,0,22),Position=UDim2.new(0,4,0,40),BackgroundColor3=K.Row,Text="目前：無",TextColor3=K.Text,TextSize=11,Font=Enum.Font.Code,BorderSizePixel=0,AutoButtonColor=false},keyPanel)
cr(kpCurrent,UDim.new(0,4))
local kpMode=nw("TextButton",{Size=UDim2.new(1,-8,0,22),Position=UDim2.new(0,4,0,66),BackgroundColor3=Color3.fromRGB(30,22,45),Text="模式：切換",TextColor3=theme().S,TextSize=11,Font=Enum.Font.Code,BorderSizePixel=0,AutoButtonColor=false},keyPanel)
cr(kpMode,UDim.new(0,4))
local kpClear=nw("TextButton",{Size=UDim2.new(1,-8,0,22),Position=UDim2.new(0,4,0,92),BackgroundColor3=Color3.fromRGB(50,12,24),Text="清除綁定",TextColor3=K.Danger,TextSize=11,Font=Enum.Font.Code,BorderSizePixel=0,AutoButtonColor=false},keyPanel)
cr(kpClear,UDim.new(0,4))
local kpClose=nw("TextButton",{Size=UDim2.new(1,-8,0,20),Position=UDim2.new(0,4,1,-24),BackgroundColor3=K.Row,Text="關閉",TextColor3=K.Text,TextSize=11,Font=Enum.Font.Code,BorderSizePixel=0,AutoButtonColor=false},keyPanel)
cr(kpClose,UDim.new(0,4))
local currentBindId=nil
local listeningKey=false
openKeyPanel=function(id,anchorBtn)
    currentBindId=id
    kpCurrent.Text="目前："..(KEY_NAMES[id]or"無")
    kpMode.Text="模式："..((KEY_MODES[id]=="hold")and"按住"or"切換")
    local ap=anchorBtn.AbsolutePosition
    local px=ap.X+anchorBtn.AbsoluteSize.X+5
    local py=ap.Y
    if px+200>sc2.AbsoluteSize.X then px=ap.X-205 end
    if py+166>sc2.AbsoluteSize.Y then py=sc2.AbsoluteSize.Y-172 end
    keyPanel.Position=UDim2.fromOffset(math.floor(px),math.floor(py))
    keyPanel.Visible=true
    listeningKey=false
end
kpCurrent.MouseButton1Click:Connect(function()listeningKey=true kpCurrent.Text="按鍵中..." end)
kpMode.MouseButton1Click:Connect(function()
    if currentBindId then
        KEY_MODES[currentBindId]=(KEY_MODES[currentBindId]=="hold")and"toggle"or"hold"
        kpMode.Text="模式："..((KEY_MODES[currentBindId]=="hold")and"按住"or"切換")
    end
end)
kpClear.MouseButton1Click:Connect(function()
    if currentBindId then bindKey(currentBindId,nil) kpCurrent.Text="目前：無" notify("已清除綁定") end
end)
kpClose.MouseButton1Click:Connect(function()keyPanel.Visible=false currentBindId=nil listeningKey=false end)
U.InputBegan:Connect(function(i,g)
    if not listeningKey then return end
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        if currentBindId then bindKey(currentBindId,"MouseLeft") kpCurrent.Text="目前：MouseLeft" end
        listeningKey=false return
    elseif i.UserInputType==Enum.UserInputType.MouseButton2 then
        if currentBindId then bindKey(currentBindId,"MouseRight") kpCurrent.Text="目前：MouseRight" end
        listeningKey=false return
    elseif i.UserInputType==Enum.UserInputType.MouseButton3 then
        if currentBindId then bindKey(currentBindId,"MouseMiddle") kpCurrent.Text="目前：MouseMiddle" end
        listeningKey=false return
    elseif i.KeyCode and i.KeyCode~=Enum.KeyCode.Unknown then
        if currentBindId then bindKey(currentBindId,i.KeyCode) kpCurrent.Text="目前："..i.KeyCode.Name end
        listeningKey=false return
    end
end)

-- 反 AFK
task.spawn(function()
    while true do
        task.wait(30)
        if S.AntiAFK and L.Character then
            local h=L.Character:FindFirstChildOfClass("Humanoid")
            if h then
                h:ChangeState(Enum.HumanoidStateType.Jumping)
                task.wait(0.1)
                h:ChangeState(Enum.HumanoidStateType.Landed)
            end
        end
    end
end)

-- 通知
local function onChatted(player,msg)
    if not S.ChatNotify then return end
    local lower=msg:lower()
    for _,kw in ipairs(S.ChatKeywords)do
        if lower:find(kw,1,true)then notify("["..player.Name.."] "..msg) break end
    end
end
P.PlayerAdded:Connect(function(p)
    if S.JoinLeaveNotify then notify("加入: "..p.Name) end
    p.Chatted:Connect(function(msg)onChatted(p,msg)end)
end)
P.PlayerRemoving:Connect(function(p)
    if S.JoinLeaveNotify then notify("離開: "..p.Name) end
end)
for _,p in ipairs(P:GetPlayers())do
    p.Chatted:Connect(function(msg)onChatted(p,msg)end)
end

-- 拖動 + 收合
local dg,dS,dP=false,nil,nil
tb.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dg=true dS,dP=i.Position,mn.Position
        i.Changed:Connect(function()if i.UserInputState==Enum.UserInputState.End then dg=false end end)
    end
end)
U.InputChanged:Connect(function(i)
    if dg and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch)then
        local d=i.Position-dS
        mn.Position=UDim2.new(dP.X.Scale,dP.X.Offset+d.X,dP.Y.Scale,dP.Y.Offset+d.Y)
    end
end)
local cpd=false
cp.MouseButton1Click:Connect(function()
    cpd=not cpd
    local tg=cpd and UDim2.fromOffset(PW,38)or UDim2.fromOffset(PW,660)
    T:Create(mn,TweenInfo.new(0.25,Enum.EasingStyle.Quart),{Size=tg}):Play()
    content.Visible=not cpd
    cp.Text=cpd and"+"or"—"
end)
cx.MouseButton1Click:Connect(function()
    sc2:Destroy()
    espGui:Destroy()
    if fovCircleDraw then pcall(function()fovCircleDraw:Remove()end)end
    for k,_ in pairs(cache)do cl(k)end
end)

notify("AXIOM RIVALS v6.5 已載入 // 自瞄改用 yes.dev 邏輯")
print("[Axiom] v6.5 已載入 | 目標:",#collectTargets())
