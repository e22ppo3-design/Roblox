-- Axiom RIVALS v6.4 // 血量漸層 + FOV平滑 + 反AFK + 聊天/進出通知
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
    Aim=false,AimSmooth=0.25,AimFOV=200,AimWall=false,TeamCheck=false,
    FOVSmooth=true,
    AntiAFK=true,
    ChatNotify=true,
    JoinLeaveNotify=true,
    ChatKeywords={"noob","ez","lag","hack","cheat","report","kick","ban","aim","esp"},
    BHop=false,InfJump=false,Theme=1,
    HitboxVis=false,HitboxSize=2,
    AimAssist=false,AssistStrength=0.15,
    Notify=true,
    HideKey=Enum.KeyCode.RightShift,GuiVisible=true,
    AimPart="HitboxHead",AimPartMode="fixed",RainbowTracer=true,
    SyncFacing=false,
    MouseAim=true,
    MouseSens=1.0,
    MouseDeadzone=2,
    MouseMaxStep=200,
    MouseSmooth=0.5,
    AimStuckTime=3,
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

local hasMouseMoveRel = type(mousemoverel)=="function"
print("[Axiom] mousemoverel 支援:", hasMouseMoveRel)

local function entryFromModel(model, player)
    if not model or not model.Parent then return nil end
    local hum=model:FindFirstChildOfClass("Humanoid")
    local hrp=model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    local head=model:FindFirstChild("Head") or hrp
    if not hrp then return nil end
    if hum and hum.Health<=0 then return nil end
    return {model=model,hrp=hrp,head=head,player=player,humanoid=hum}
end
local function refreshEntry(entry)
    if not entry or not entry.model or not entry.model.Parent then return nil end
    return entryFromModel(entry.model, entry.player)
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
                local model=d.Parent
                local e=entryFromModel(model,P:GetPlayerFromCharacter(model))
                if e then table.insert(out,e) seen[model]=true end
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
    local pants=char:FindFirstChild("Pants")
    if pants and pants:IsA("Pants") and pants.PantsTemplate and pants.PantsTemplate~="" then
        return pants.PantsTemplate
    end
    local parent=char.Parent
    if parent then
        local n=parent.Name:lower()
        if n:find("terror") or n:find("counter") or n:find("team") then
            return parent.Name
        end
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
    AimAssist=function(h)if h==true then S.AimAssist=true elseif h=="release"then S.AimAssist=false else S.AimAssist=not S.AimAssist end end,
    MouseAim=function(h)if h==true then S.MouseAim=true elseif h=="release"then S.MouseAim=false else S.MouseAim=not S.MouseAim end end,
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
    local heightPx=math.abs(hrpV.Y-headV.Y)*2.2
    if heightPx<10 then heightPx=10 end
    local widthPx=heightPx*0.5
    local cx=(hrpV.X+headV.X)/2
    local cy=(hrpV.Y+headV.Y)/2
    local sh=(ds/S.MaxDistance)*0.15
    local hue=(hc+ho(key)+sh)%1
    local co=hsv(hue,1,1)
    d.holder.Position=UDim2.fromOffset(math.floor(cx-widthPx/2),math.floor(cy-heightPx/2))
    d.holder.Size=UDim2.fromOffset(math.floor(widthPx),math.floor(heightPx))
    d.holder.Visible=true; d.holder.BackgroundTransparency=1
    d.name.Visible=S.ShowName
    if S.ShowName then d.name.Text=m.Name d.name.Position=UDim2.new(0.5,-100,0,-20) end
    d.dist.Visible=S.ShowDistance
    if S.ShowDistance then d.dist.Text=string.format("[%d]",math.floor(ds))end
    if S.ESPEnabled then
        d.box.Visible=true
        d.box.Position=UDim2.fromOffset(math.floor(cx-widthPx/2),math.floor(cy-heightPx/2))
        d.box.Size=UDim2.fromOffset(math.floor(widthPx),math.floor(heightPx))
        local stroke=d.box:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color=co end
    else d.box.Visible=false end
    -- 血量條：漸層（滿血綠 → 中血黃 → 殘血紅）
    if S.ShowHealth and entry.humanoid and entry.humanoid.MaxHealth>0 then
        local rt=math.clamp(entry.humanoid.Health/entry.humanoid.MaxHealth,0,1)
        d.hbBg.Visible=true
        d.hbBg.Size=UDim2.fromOffset(3,math.floor(heightPx))
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
        local to=Vector2.new(cx,cy+heightPx/2)
        local mid=(from+to)/2; local len=(to-from).Magnitude
        local ang=math.deg(math.atan2(to.Y-from.Y,to.X-from.X))
        d.tracer.Visible=true
        d.tracer.BackgroundColor3=S.RainbowTracer and hsv((hc+ho(key))%1,1,1) or co
        d.tracer.Size=UDim2.fromOffset(math.floor(len),1)
        d.tracer.Position=UDim2.fromOffset(math.floor(mid.X-len/2),math.floor(mid.Y))
        d.tracer.Rotation=ang
    else d.tracer.Visible=false end
end

local K={Bg=Color3.fromRGB(10,10,16),Row=Color3.fromRGB(20,20,32),RowHi=Color3.fromRGB(34,34,54),Text=Color3.fromRGB(230,230,245),Dim=Color3.fromRGB(120,120,150),Danger=Color3.fromRGB(255,70,100)}
local sc2=nw("ScreenGui",{Name=gn,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=true,DisplayOrder=2147483647},pt)
local PW=250
local mn=nw("Frame",{Size=UDim2.fromOffset(PW,660),Position=UDim2.new(0,20,0.1,0),BackgroundColor3=K.Bg,BackgroundTransparency=0.05,BorderSizePixel=0,ClipsDescendants=true,Active=true},sc2)
cr(mn,UDim.new(0,10))
nw("UIStroke",{Color=theme().S,Thickness=1.5,Transparency=0.3},mn)
local tb=nw("Frame",{Size=UDim2.new(1,0,0,38),BackgroundColor3=Color3.fromRGB(16,16,26),BorderSizePixel=0,ZIndex=5},mn)
cr(tb,UDim.new(0,10))
nw("TextLabel",{Size=UDim2.new(1,-70,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Text="AXIOM // RIVALS v6.4",TextColor3=K.Text,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=7},tb)
local cp=nw("TextButton",{Size=UDim2.fromOffset(22,22),Position=UDim2.new(1,-54,0,8),BackgroundColor3=K.Row,Text="—",TextColor3=theme().S,Font=Enum.Font.GothamBold,TextSize=13,BorderSizePixel=0,AutoButtonColor=false,ZIndex=7},tb)
cr(cp,UDim.new(0,5))
local cx=nw("TextButton",{Size=UDim2.fromOffset(22,22),Position=UDim2.new(1,-28,0,8),BackgroundColor3=Color3.fromRGB(50,14,24),Text="×",TextColor3=K.Danger,Font=Enum.Font.GothamBold,TextSize=15,BorderSizePixel=0,AutoButtonColor=false,ZIndex=7},tb)
cr(cx,UDim.new(0,5))
local content=nw("ScrollingFrame",{Size=UDim2.new(1,-8,1,-46),Position=UDim2.new(0,4,0,42),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=theme().S,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=3},mn)
nw("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},content)
nw("UIPadding",{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,6)},content)
local orderCount=0
local function nextOrder()orderCount=orderCount+1 return orderCount end
local function makeCollapsible(title)
    local header=nw("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundColor3=K.Row,Text="",AutoButtonColor=false,BorderSizePixel=0,LayoutOrder=nextOrder()},content)
    cr(header,UDim.new(0,7))
    nw("UIStroke",{Color=theme().S,Thickness=1,Transparency=0.6},header)
    local arrow=nw("TextLabel",{Size=UDim2.fromOffset(16,16),Position=UDim2.new(0,8,0.5,-8),BackgroundTransparency=1,Text="▼",TextColor3=theme().S,TextSize=10,Font=Enum.Font.GothamBold,ZIndex=2},header)
    nw("TextLabel",{Size=UDim2.new(1,-32,1,0),Position=UDim2.new(0,26,0,0),BackgroundTransparency=1,Text=title,TextColor3=K.Text,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=2},header)
    local body=nw("Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=nextOrder(),AutomaticSize=Enum.AutomaticSize.Y,ClipsDescendants=true},content)
    nw("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},body)
    nw("UIPadding",{PaddingTop=UDim.new(0,2),PaddingBottom=UDim.new(0,2)},body)
    local bodyOrder=0
    local function bodyNext()bodyOrder=bodyOrder+1 return bodyOrder end
    local open=true
    header.MouseButton1Click:Connect(function()
        open=not open
        T:Create(arrow,TweenInfo.new(0.2),{Rotation=open and 0 or -90}):Play()
        body.Visible=open
    end)
    return body,bodyNext
end
local function makeToggle(parent,bodyNext,t,bindId,cb)
    local holder=nw("Frame",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=bodyNext()},parent)
    local b=nw("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundColor3=K.Row,BackgroundTransparency=0.2,Text="",AutoButtonColor=false,BorderSizePixel=0,ZIndex=2},holder)
    cr(b,UDim.new(0,7))
    local bs=nw("UIStroke",{Color=theme().S,Thickness=1,Transparency=0.7},b)
    local swBg=nw("Frame",{Size=UDim2.fromOffset(34,16),Position=UDim2.new(1,-44,0.5,-8),BackgroundColor3=Color3.fromRGB(40,40,55),BorderSizePixel=0,ZIndex=3},b)
    cr(swBg,UDim.new(1,0))
    local swKnob=nw("Frame",{Size=UDim2.fromOffset(12,12),Position=UDim2.new(0,2,0.5,-6),BackgroundColor3=K.Dim,BorderSizePixel=0,ZIndex=4},swBg)
    cr(swKnob,UDim.new(1,0))
    local l=nw("TextLabel",{Size=UDim2.new(1,-90,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Text=t,TextColor3=K.Text,TextSize=12,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3},b)
    local state=false
    local function refresh()
        T:Create(swBg,TweenInfo.new(0.2),{BackgroundColor3=state and theme().S or Color3.fromRGB(40,40,55)}):Play()
        T:Create(swKnob,TweenInfo.new(0.2,Enum.EasingStyle.Back),{Position=state and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6),BackgroundColor3=state and Color3.fromRGB(255,255,255) or K.Dim}):Play()
    end
    refresh()
    b.MouseButton1Click:Connect(function()
        state=not state
        refresh()
        if cb then pcall(cb,state)end
    end)
    b.MouseButton2Click:Connect(function()if bindId and openKeyPanel then openKeyPanel(bindId,b)end end)
    return b,l
end
local function makeSlider(parent,bodyNext,t,mn2,mx,df,cb)
    local holder=nw("Frame",{Size=UDim2.new(1,0,0,46),BackgroundColor3=K.Row,BackgroundTransparency=0.2,BorderSizePixel=0,LayoutOrder=bodyNext()},parent)
    cr(holder,UDim.new(0,7))
    nw("UIStroke",{Color=theme().S,Thickness=1,Transparency=0.7},holder)
    nw("TextLabel",{Size=UDim2.new(1,-16,0,14),Position=UDim2.new(0,12,0,5),BackgroundTransparency=1,Text=t,TextColor3=K.Text,TextSize=11,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left},holder)
    local v=nw("TextLabel",{Size=UDim2.new(0,60,0,14),Position=UDim2.new(1,-72,0,5),BackgroundTransparency=1,Text=string.format("%.2f",df),TextColor3=theme().S,TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Right},holder)
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
        v.Text=string.format("%.2f",vv)
        if cb then pcall(cb,vv)end
    end
    tr.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dg=true sf(i.Position.X)
        end
    end)
    U.InputChanged:Connect(function(i)if dg and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch)then sf(i.Position.X)end end)
    U.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dg=false end
    end)
    return holder
end
local function makeButton(parent,bodyNext,t,cb,bindId)
    local holder=nw("Frame",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=bodyNext()},parent)
    local b=nw("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundColor3=K.Row,BackgroundTransparency=0.2,Text=t,TextColor3=K.Text,TextSize=12,Font=Enum.Font.GothamMedium,AutoButtonColor=false,BorderSizePixel=0,ZIndex=2},holder)
    cr(b,UDim.new(0,7))
    nw("UIStroke",{Color=theme().S,Thickness=1,Transparency=0.7},b)
    b.MouseButton1Click:Connect(function()if cb then pcall(cb,b)end end)
    if bindId then b.MouseButton2Click:Connect(function()if openKeyPanel then openKeyPanel(bindId,b)end end) end
    return b
end

local body,bodyNext
body,bodyNext=makeCollapsible("視覺")
makeToggle(body,bodyNext,"ESP 開關","ESP",function(s)S.ESPEnabled=s end)
makeToggle(body,bodyNext,"名字","ShowName",function(s)S.ShowName=s end)
makeToggle(body,bodyNext,"距離","ShowDistance",function(s)S.ShowDistance=s end)
makeToggle(body,bodyNext,"血量","ShowHealth",function(s)S.ShowHealth=s end)
makeToggle(body,bodyNext,"追蹤線","ShowTracer",function(s)S.ShowTracer=s end)
makeToggle(body,bodyNext,"Hitbox 顯示","HitboxVis",function(s)S.HitboxVis=s end)
makeSlider(body,bodyNext,"彩虹速度",0,2,S.HueSpeed,function(v)S.HueSpeed=v end)
makeSlider(body,bodyNext,"ESP 距離",100,5000,S.MaxDistance,function(v)S.MaxDistance=v end)

body,bodyNext=makeCollapsible("戰鬥")
makeToggle(body,bodyNext,"自瞄開關","Aim",function(s)S.Aim=s notify(s and"自瞄 ON"or"自瞄 OFF")end)
makeToggle(body,bodyNext,"自瞄牆檢","AimWall",function(s)S.AimWall=s end)
makeToggle(body,bodyNext,"FOV 顯示","ShowFOV",function(s)S.ShowFOV=s end)
makeToggle(body,bodyNext,"Aim Assist","AimAssist",function(s)S.AimAssist=s end)
makeToggle(body,bodyNext,"模擬滑鼠自瞄","MouseAim",function(s)S.MouseAim=s notify(s and"模擬滑鼠 ON"or"模擬滑鼠 OFF")end)
makeToggle(body,bodyNext,"FOV 距離平滑","FOVSmooth",function(s)S.FOVSmooth=s end)
makeButton(body,bodyNext,"自瞄部位：HitboxHead",function(b)
    local parts={"HitboxHead","HitboxBody","Head","HumanoidRootPart","隨機"}
    local cur=1
    for i,p in ipairs(parts)do
        if p=="隨機" and S.AimPartMode=="random" then cur=i break end
        if p==S.AimPart and S.AimPartMode~="random" then cur=i break end
    end
    cur=cur%#parts+1
    local sel=parts[cur]
    if sel=="隨機" then S.AimPartMode="random" b.Text="自瞄部位：隨機"
    else S.AimPartMode="fixed" S.AimPart=sel b.Text="自瞄部位："..sel end
    notify("自瞄部位："..sel)
end)
makeSlider(body,bodyNext,"FOV 半徑",30,800,S.AimFOV,function(v)S.AimFOV=v end)
makeSlider(body,bodyNext,"自瞄平滑",0,0.95,S.AimSmooth,function(v)S.AimSmooth=v end)
makeSlider(body,bodyNext,"Assist 強度",0,1,S.AssistStrength,function(v)S.AssistStrength=v end)
makeSlider(body,bodyNext,"滑鼠靈敏度",0.1,5,S.MouseSens,function(v)S.MouseSens=v end)
makeSlider(body,bodyNext,"滑鼠平滑",0,0.95,S.MouseSmooth,function(v)S.MouseSmooth=v end)
makeSlider(body,bodyNext,"滑鼠死區",0,20,S.MouseDeadzone,function(v)S.MouseDeadzone=v end)
makeSlider(body,bodyNext,"單幀上限",10,500,S.MouseMaxStep,function(v)S.MouseMaxStep=v end)
makeSlider(body,bodyNext,"卡住解鎖秒",0.5,10,S.AimStuckTime,function(v)S.AimStuckTime=v end)

body,bodyNext=makeCollapsible("移動")
makeToggle(body,bodyNext,"穿牆","Noclip",function(s)S.Noclip=s end)
makeToggle(body,bodyNext,"Bunny Hop","BHop",function(s)S.BHop=s end)
makeToggle(body,bodyNext,"無限跳躍","InfJump",function(s)S.InfJump=s end)
makeSlider(body,bodyNext,"移動速度",16,200,S.WalkSpeed,function(v)S.WalkSpeed=v end)
makeSlider(body,bodyNext,"跳躍力",50,300,S.JumpPower,function(v)S.JumpPower=v end)

body,bodyNext=makeCollapsible("其他")
makeToggle(body,bodyNext,"隊伍檢測","TeamCheck",function(s)S.TeamCheck=s notify(s and"隊伍檢測 ON"or"隊伍檢測 OFF")end)
makeToggle(body,bodyNext,"反 AFK","AntiAFK",function(s)S.AntiAFK=s notify(s and"反 AFK ON"or"反 AFK OFF")end)
makeToggle(body,bodyNext,"聊天通知","ChatNotify",function(s)S.ChatNotify=s end)
makeToggle(body,bodyNext,"進出通知","JoinLeaveNotify",function(s)S.JoinLeaveNotify=s end)
makeButton(body,bodyNext,"掃描模式：自動",function(b)
    if S.ScanMode=="auto" then S.ScanMode="player"
    elseif S.ScanMode=="player" then S.ScanMode="workspace"
    else S.ScanMode="auto" end
    b.Text="掃描模式："..(S.ScanMode=="auto" and"自動"or S.ScanMode=="player" and"僅玩家"or"僅 Workspace")
end)
makeButton(body,bodyNext,"切換主題",function(b)
    S.Theme=S.Theme%#THEMES+1
    b.Text="主題："..THEMES[S.Theme].name
    local stroke=mn:FindFirstChildOfClass("UIStroke")
    if stroke then stroke.Color=theme().S end
end)
makeButton(body,bodyNext,"隱藏 GUI",function()S.GuiVisible=not S.GuiVisible mn.Visible=S.GuiVisible end)
makeButton(body,bodyNext,"儲存設定",function()
    if not writefile then notify("執行器不支援 writefile") return end
    local data={}
    for k,v in pairs(S)do
        if type(v)=="boolean" or type(v)=="number" or type(v)=="string" then data[k]=v end
    end
    local keyData={}
    for id,key in pairs(KEYS)do
        if key then
            if type(key)=="userdata" then
                keyData[id]={k="keycode",v=key.Name,m=KEY_MODES[id]}
            else
                keyData[id]={k="string",v=key,m=KEY_MODES[id]}
            end
        end
    end
    data._keys=keyData
    data._theme=S.Theme
    local ok,err=pcall(function()
        writefile("axiom_rivals_v6.json",HS:JSONEncode(data))
    end)
    if ok then notify("設定已儲存") else notify("儲存失敗："..tostring(err)) end
end)
makeButton(body,bodyNext,"載入設定",function()
    if not readfile or not isfile then notify("執行器不支援 readfile") return end
    if not isfile("axiom_rivals_v6.json") then notify("找不到存檔") return end
    local ok,data=pcall(function()
        return HS:JSONDecode(readfile("axiom_rivals_v6.json"))
    end)
    if not ok or type(data)~="table" then notify("存檔格式錯誤") return end
    for k,v in pairs(data)do
        if k~="_keys" and k~="_theme" and S[k]~=nil then
            if type(v)=="boolean" or type(v)=="number" or type(v)=="string" then S[k]=v end
        end
    end
    if data._theme then S.Theme=data._theme end
    if data._keys then
        for id,kd in pairs(data._keys)do
            if kd.k=="keycode" then
                for _,kc in ipairs(Enum.KeyCode:GetEnumItems())do
                    if kc.Name==kd.v then bindKey(id,kc) break end
                end
            else
                bindKey(id,kd.v)
            end
            if kd.m then KEY_MODES[id]=kd.m end
        end
    end
    notify("設定已載入")
end)

local keyListHolder=nw("Frame",{Size=UDim2.new(1,0,0,120),BackgroundColor3=K.Row,BackgroundTransparency=0.2,BorderSizePixel=0,LayoutOrder=nextOrder()},content)
cr(keyListHolder,UDim.new(0,7))
nw("UIStroke",{Color=theme().S,Thickness=1,Transparency=0.7},keyListHolder)
nw("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text="已綁定快捷鍵",TextColor3=theme().S,TextSize=11,Font=Enum.Font.GothamBold},keyListHolder)
local keyListLbl=nw("TextLabel",{Size=UDim2.new(1,-12,1,-24),Position=UDim2.new(0,6,0,20),BackgroundTransparency=1,Text="",TextColor3=K.Text,TextSize=10,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},keyListHolder)
task.spawn(function()
    while keyListLbl.Parent do
        local lines={}
        for id,key in pairs(KEYS)do
            if key then
                local mode=KEY_MODES[id]=="hold" and"·H"or""
                table.insert(lines,string.format("%s: %s%s",id,KEY_NAMES[id]or"?",mode))
            end
        end
        keyListLbl.Text=#lines>0 and table.concat(lines,"\n")or"（無）右鍵功能按鈕綁定"
        task.wait(0.4)
    end
end)

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
    kpMode.TextColor3=(KEY_MODES[id]=="hold")and Color3.fromRGB(255,150,80)or theme().S
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
        kpMode.TextColor3=(KEY_MODES[currentBindId]=="hold")and Color3.fromRGB(255,150,80)or theme().S
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

local RANDOM_PARTS={"HitboxHead","HitboxBody","Head","HumanoidRootPart"}
local function getAimPartName()
    if S.AimPartMode=="random" then return RANDOM_PARTS[math.random(1,#RANDOM_PARTS)] end
    return S.AimPart
end
local function getAimPart(entry)
    local e=refreshEntry(entry)
    if not e then return nil, nil end
    local name=getAimPartName()
    local part=e.model:FindFirstChild(name)
    if part and part:IsA("BasePart") then return part, e end
    local fb={"HitboxHead","HitboxBody","Head","HumanoidRootPart"}
    for _,n in ipairs(fb)do
        local p=e.model:FindFirstChild(n)
        if p and p:IsA("BasePart") then return p, e end
    end
    return e.head or e.hrp, e
end
local function isVisibleEntry(entry)
    if not S.AimWall then return true end
    local part=select(1,getAimPart(entry))
    if not part then return false end
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={L.Character,C,entry.model}
    local result=W:Raycast(C.CFrame.Position,part.Position-C.CFrame.Position,params)
    if result and result.Instance then return result.Instance:IsDescendantOf(entry.model) end
    return true
end
local function findNearestInFOV()
    local best,bestDist=nil,math.huge
    local vp=C.ViewportSize.X; local vq=C.ViewportSize.Y
    local cx,cy=vp/2,vq/2
    for _,entry in ipairs(collectTargets())do
        if not isTeamEntry(entry)then
            local part=select(1,getAimPart(entry))
            if part then
                local sp,on=C:WorldToViewportPoint(part.Position)
                if on then
                    local dx,dy=sp.X-cx,sp.Y-cy
                    local screenDist=math.sqrt(dx*dx+dy*dy)
                    if screenDist<=S.AimFOV and screenDist<bestDist and isVisibleEntry(entry)then
                        best,bestDist=entry,screenDist
                    end
                end
            end
        end
    end
    return best
end
local function findNearestAny()
    local best,bestDist=nil,math.huge
    local camPos=C.CFrame.Position
    for _,entry in ipairs(collectTargets())do
        if not isTeamEntry(entry)then
            local part=select(1,getAimPart(entry))
            if part then
                local d=(part.Position-camPos).Magnitude
                if d<bestDist and isVisibleEntry(entry)then best,bestDist=entry,d end
            end
        end
    end
    return best
end
local function isAlive(entry)
    if not entry or not entry.model or not entry.model.Parent then return false end
    local hum=entry.model:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health<=0 then return false end
    local hrp=entry.model:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    return true
end
local lockedTarget=nil
local aimTarget=nil
local lastAimPos=nil
local lastAimTime=tick()

-- 自瞄（FOV 距離平滑）
R:BindToRenderStep("AxiomMouseAim",201,function(dt)
    if not S.Aim then return end
    if not S.MouseAim then return end
    if not hasMouseMoveRel then return end
    if not aimTarget or not isAlive(aimTarget)then return end
    local part,refreshed=getAimPart(aimTarget)
    if not part or not refreshed then return end
    aimTarget=refreshed
    local sp,on=C:WorldToViewportPoint(part.Position)
    if not on then return end
    local vp=C.ViewportSize.X
    local vq=C.ViewportSize.Y
    local cx,cy=vp/2,vq/2
    local dx=sp.X-cx
    local dy=sp.Y-cy
    if math.abs(dx)<S.MouseDeadzone and math.abs(dy)<S.MouseDeadzone then return end
    -- FOV 距離平滑：越靠近邊緣越慢，越靠近中心越快
    local screenDist=math.sqrt(dx*dx+dy*dy)
    local distFactor=1
    if S.FOVSmooth then
        distFactor=1-(screenDist/S.AimFOV)*0.9
        distFactor=math.clamp(distFactor,0.1,1)
    end
    dx=dx*(1-S.MouseSmooth)*S.MouseSens*distFactor
    dy=dy*(1-S.MouseSmooth)*S.MouseSens*distFactor
    local mag=math.sqrt(dx*dx+dy*dy)
    if mag>S.MouseMaxStep then
        dx=dx/mag*S.MouseMaxStep
        dy=dy/mag*S.MouseMaxStep
    end
    mousemoverel(dx,dy)
end)

R:BindToRenderStep("AxiomCamAim",200,function(dt)
    if not S.Aim then return end
    if S.MouseAim then return end
    if not aimTarget or not isAlive(aimTarget)then return end
    local part=select(1,getAimPart(aimTarget))
    if not part then return end
    local look=CFrame.new(C.CFrame.Position,part.Position)
    C.CFrame=C.CFrame:Lerp(look,1-math.clamp(S.AimSmooth,0,0.99))
end)

local fovCircle=nw("Frame",{Size=UDim2.fromOffset(S.AimFOV*2,S.AimFOV*2),AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0.5,0),BackgroundTransparency=1,BorderSizePixel=0,Visible=false,ZIndex=1},sc2)
local fovStroke=nw("UIStroke",{Color=theme().S,Thickness=2,Transparency=0.3},fovCircle)
cr(fovCircle,UDim.new(1,0))

local notifFrame=nw("Frame",{Size=UDim2.fromOffset(220,30),Position=UDim2.new(1,-240,1,-50),BackgroundColor3=Color3.fromRGB(16,16,26),BackgroundTransparency=0.1,BorderSizePixel=0,Visible=false,ZIndex=200},sc2)
cr(notifFrame,UDim.new(0,7))
nw("UIStroke",{Color=theme().S,Thickness=1.5},notifFrame)
local notifLbl=nw("TextLabel",{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,6,0,0),BackgroundTransparency=1,Text="",TextColor3=K.Text,TextSize=12,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},notifFrame)
local notifQueue={}
notify=function(msg)if not S.Notify then return end table.insert(notifQueue,msg)end
task.spawn(function()
    while true do
        if #notifQueue>0 then
            local msg=table.remove(notifQueue,1)
            notifLbl.Text="▸ "..msg
            notifFrame.Visible=true
            task.wait(2)
            notifFrame.Visible=false
        else task.wait(0.1)end
    end
end)

-- ========== 反 AFK ==========
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

-- ========== 聊天通知 ==========
local function onChatted(player,msg)
    if not S.ChatNotify then return end
    local lower=msg:lower()
    for _,kw in ipairs(S.ChatKeywords)do
        if lower:find(kw,1,true)then
            notify("["..player.Name.."] "..msg)
            break
        end
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

local frames=0; local lastT=tick()
R.RenderStepped:Connect(function(dt)
    hc=(hc+dt*S.HueSpeed)%1
    local targets=collectTargets()
    for _,entry in ipairs(targets)do pcall(rd,entry)end
    local alive={}
    for _,entry in ipairs(targets)do alive[entry.model]=true end
    for key,_ in pairs(cache)do if not alive[key] then cl(key) end end
    fovCircle.Visible=S.ShowFOV and S.Aim and S.GuiVisible
    if fovCircle.Visible then
        local px=S.AimFOV*2
        fovCircle.Size=UDim2.fromOffset(px,px)
        fovStroke.Color=hsv(hc,1,1)
    end
    if S.Aim and S.GuiVisible then
        if U:IsKeyDown(Enum.KeyCode.Q)then
            if not lockedTarget or not isAlive(lockedTarget)then
                lockedTarget=findNearestAny()
            end
            aimTarget=lockedTarget
        else
            lockedTarget=nil
            aimTarget=findNearestInFOV()
        end
    else
        lockedTarget=nil
        aimTarget=nil
    end
    if aimTarget then
        local part=select(1,getAimPart(aimTarget))
        if part then
            if lastAimPos and (part.Position-lastAimPos).Magnitude<0.1 then
                if tick()-lastAimTime>S.AimStuckTime then
                    aimTarget=nil
                    lockedTarget=nil
                    lastAimTime=tick()
                    lastAimPos=nil
                end
            else
                lastAimPos=part.Position
                lastAimTime=tick()
            end
        end
    else
        lastAimPos=nil
        lastAimTime=tick()
    end
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
        local c=L.Character local h=c and c:FindFirstChildOfClass("Humanoid")
        if h and h.FloorMaterial~=Enum.Material.Air then h.Jump=true end
    end
    frames=frames+1
    if tick()-lastT>=1 then frames=0 lastT=tick()end
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
    R:UnbindFromRenderStep("AxiomMouseAim")
    R:UnbindFromRenderStep("AxiomCamAim")
    sc2:Destroy()
    espGui:Destroy()
    for k,_ in pairs(cache)do cl(k)end
end)

notify("AXIOM RIVALS v6.4 已載入 // 血量漸層 + FOV平滑 + 反AFK + 通知")
print("[Axiom] v6.4 已載入，mousemoverel 支援:",hasMouseMoveRel,"目標數:",#collectTargets())
