-- AXIOM RIVALS v6.5 // 酷炫 GUI + 血量漸層 + 瞄準平滑 + 反AFK + 傳送點 + 通知
-- 老闆專用

local P=game:GetService("Players")
local R=game:GetService("RunService")
local U=game:GetService("UserInputService")
local T=game:GetService("TweenService")
local W=game:GetService("Workspace")
local C=W.CurrentCamera
local L=P.LocalPlayer
local HS=game:GetService("HttpService")

-- ========== 隨機名字 ==========
local function rnd(n)
    local s=""
    for i=1,n do s=s..string.char(math.random(97,122)) end
    return s
end
local gn=rnd(12)

-- ========== 找 GUI 父層 ==========
local pt=game:GetService("CoreGui")
if typeof(gethui)=="function" then
    local ok,h=pcall(gethui)
    if ok and h then pt=h end
end
pcall(function()
    if pt==game:GetService("CoreGui") and L:FindFirstChild("PlayerGui") then
        pt=L.PlayerGui
    end
end)
if pt:FindFirstChild(gn) then pt[gn]:Destroy() end

-- ========== 設定 ==========
local S={
    ESPEnabled=true, ShowName=true, ShowDistance=true, ShowHealth=true, ShowTracer=true,
    MaxDistance=2000, HueSpeed=0.25, RainbowTracer=true,
    WalkSpeed=16, JumpPower=50, Noclip=false,
    Aim=false, AimSmooth=0.25, AimFOV=200, AimWall=false, TeamCheck=false,
    FOVSmooth=true, MouseAim=true, MouseSens=1.0, MouseSmooth=0.5,
    AntiAFK=true, ChatNotify=true, JoinLeaveNotify=true,
    BHop=false, InfJump=false, Theme=1,
    HitboxVis=false, HitboxSize=2,
    ShowFOV=true, GuiVisible=true, Notify=true,
    HideKey=Enum.KeyCode.RightShift,
    AimPart="HitboxHead", AimPartMode="fixed",
    ScanMode="auto",
    TeleportPos=nil,
}

-- ========== 主題 ==========
local THEMES={
    {name="霓虹青", S=Color3.fromRGB(0,240,200), P=Color3.fromRGB(255,0,140)},
    {name="紫電",   S=Color3.fromRGB(140,90,255), P=Color3.fromRGB(255,120,60)},
    {name="烈焰",   S=Color3.fromRGB(255,180,0),  P=Color3.fromRGB(255,60,60)},
    {name="血月",   S=Color3.fromRGB(255,0,80),   P=Color3.fromRGB(120,0,200)},
    {name="冰霜",   S=Color3.fromRGB(120,220,255),P=Color3.fromRGB(200,240,255)},
}
local function theme() return THEMES[S.Theme] end

local E={NameColor=Color3.fromRGB(255,255,255),DistanceColor=Color3.fromRGB(255,220,0),HealthColor=Color3.fromRGB(0,255,100)}
local hc=0
local function hsv(h,s,v) return Color3.fromHSV(h%1,s,v) end
local function nw(c,p,pa)
    local o=Instance.new(c)
    for k,v in pairs(p) do o[k]=v end
    if pa then o.Parent=pa end
    return o
end
local function cr(p,r) return nw("UICorner",{CornerRadius=r or UDim.new(0,8)},p) end
local function stroke(p,c,t) return nw("UIStroke",{Color=c,Thickness=t or 1,Transparency=0.3},p) end

-- ========== 目標收集 ==========
local function entryFromModel(model,player)
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
    for _,p in ipairs(P:GetPlayers()) do
        if p~=L then
            local e=entryFromModel(p.Character,p)
            if e then table.insert(out,e) end
        end
    end
    if S.ScanMode=="workspace" or (S.ScanMode=="auto" and #out==0) then
        for _,d in ipairs(W:GetDescendants()) do
            if d:IsA("Humanoid") and d.Parent then
                local e=entryFromModel(d.Parent,P:GetPlayerFromCharacter(d.Parent))
                if e then table.insert(out,e) end
            end
        end
    end
    return out
end
local function isTeamEntry(entry)
    if not S.TeamCheck then return false end
    local myChar=L.Character
    if not myChar or not entry.model then return false end
    local myTeam=myChar:FindFirstChild("Team")
    local eTeam=entry.model:FindFirstChild("Team")
    if myTeam and eTeam then return myTeam.Value==eTeam.Value end
    return false
end

-- ========== ESP ==========
local espGui=nw("ScreenGui",{Name=gn.."ESP",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=2147483646,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},pt)
local cache={}
local function buildESP(key)
    if cache[key] then return cache[key] end
    local holder=nw("Frame",{Size=UDim2.fromOffset(0,0),BackgroundTransparency=1,Visible=false,BorderSizePixel=0},espGui)
    local nameLbl=nw("TextLabel",{BackgroundTransparency=1,TextColor3=E.NameColor,TextSize=14,Font=Enum.Font.Code,TextStrokeTransparency=0,TextStrokeColor3=Color3.fromRGB(0,0,0),Text="",Size=UDim2.fromOffset(200,18),Position=UDim2.new(0.5,-100,0,-22),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=2},holder)
    local distLbl=nw("TextLabel",{BackgroundTransparency=1,TextColor3=E.DistanceColor,TextSize=12,Font=Enum.Font.Code,TextStrokeTransparency=0,TextStrokeColor3=Color3.fromRGB(0,0,0),Text="",Size=UDim2.fromOffset(200,16),Position=UDim2.new(0.5,-100,1,2),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=2},holder)
    local box=nw("Frame",{BackgroundTransparency=1,BorderSizePixel=0,Visible=false,ZIndex=2},espGui)
    local bs=nw("UIStroke",{Color=Color3.fromRGB(255,255,255),Thickness=1.5},box)
    local tracer=nw("Frame",{BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,Visible=false,ZIndex=0},espGui)
    local hbVis=nw("Frame",{BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=0.7,BorderSizePixel=0,Visible=false,ZIndex=5},espGui)
    cr(hbVis,UDim.new(1,0))
    local hbBg=nw("Frame",{BackgroundColor3=Color3.fromRGB(40,40,40),BorderSizePixel=0,Size=UDim2.fromOffset(4,100),Visible=false,ZIndex=3},holder)
    cr(hbBg,UDim.new(1,0))
    local hbBar=nw("Frame",{BackgroundColor3=E.HealthColor,BorderSizePixel=0,Size=UDim2.new(1,0,1,0),Position=UDim2.new(0,0,0,0),ZIndex=4},hbBg)
    cr(hbBar,UDim.new(1,0))
    local d={holder=holder,name=nameLbl,dist=distLbl,box=box,bs=bs,tracer=tracer,hbVis=hbVis,hbBg=hbBg,hbBar=hbBar}
    cache[key]=d
    return d
end
local function cl(key)
    local d=cache[key]; if not d then return end
    for _,o in pairs(d) do if o and o.Destroy then o:Destroy() end end
    cache[key]=nil
end
local function hd(d)
    if not d then return end
    d.holder.Visible=false; d.box.Visible=false; d.tracer.Visible=false; d.hbVis.Visible=false; d.hbBg.Visible=false
end
local function rd(entry)
    local m=entry.model; local hrp=entry.hrp; local head=entry.head
    local d=cache[m] or buildESP(m)
    if isTeamEntry(entry) then hd(d) return end
    if not S.ESPEnabled then hd(d) return end
    if not hrp or not hrp.Parent then hd(d) return end
    local rp=hrp.Position; local hp=head and head.Position or rp
    local ds=(C.CFrame.Position-rp).Magnitude
    if ds>S.MaxDistance then hd(d) return end
    local hrpV,hrpOn=C:WorldToViewportPoint(rp)
    local headV,headOn=C:WorldToViewportPoint(hp)
    if not hrpOn or not headOn then hd(d) return end
    local hpx=math.abs(hrpV.Y-headV.Y)*2.2
    if hpx<10 then hpx=10 end
    local wpx=hpx*0.5
    local cx=(hrpV.X+headV.X)/2
    local cy=(hrpV.Y+headV.Y)/2
    local hue=(hc+ds/S.MaxDistance*0.35)%1
    local co=hsv(hue,1,1)
    d.holder.Position=UDim2.fromOffset(math.floor(cx-wpx/2),math.floor(cy-hpx/2))
    d.holder.Size=UDim2.fromOffset(math.floor(wpx),math.floor(hpx))
    d.holder.Visible=true
    d.name.Visible=S.ShowName
    if S.ShowName then d.name.Text=m.Name end
    d.dist.Visible=S.ShowDistance
    if S.ShowDistance then d.dist.Text=string.format("[%d]",math.floor(ds)) end
    d.box.Visible=true
    d.box.Position=UDim2.fromOffset(math.floor(cx-wpx/2),math.floor(cy-hpx/2))
    d.box.Size=UDim2.fromOffset(math.floor(wpx),math.floor(hpx))
    d.bs.Color=co
    if S.ShowHealth and entry.humanoid and entry.humanoid.MaxHealth>0 then
        local rt=math.clamp(entry.humanoid.Health/entry.humanoid.MaxHealth,0,1)
        d.hbBg.Visible=true
        d.hbBg.Size=UDim2.fromOffset(4,math.floor(hpx))
        d.hbBg.Position=UDim2.new(0,-8,0,0)
        d.hbBar.Size=UDim2.new(1,0,rt,0)
        d.hbBar.Position=UDim2.new(0,0,1-rt,0)
        -- 血量漸層：滿血綠 → 中血黃 → 殘血紅
        local hueH=rt*0.33
        d.hbBar.BackgroundColor3=hsv(hueH,1,1)
    else
        d.hbBg.Visible=false
    end
    if S.HitboxVis and head then
        local hV,hOn=C:WorldToViewportPoint(head.Position)
        if hOn then
            local scale=(C.CFrame.Position-head.Position).Magnitude
            local size2=math.clamp(2000/scale*S.HitboxSize,10,400)
            d.hbVis.Visible=true
            d.hbVis.BackgroundColor3=co
            d.hbVis.Size=UDim2.fromOffset(math.floor(size2),math.floor(size2))
            d.hbVis.Position=UDim2.fromOffset(math.floor(hV.X-size2/2),math.floor(hV.Y-size2/2))
        else d.hbVis.Visible=false end
    else d.hbVis.Visible=false end
    if S.ShowTracer then
        local vp=C.ViewportSize.X; local vq=C.ViewportSize.Y
        local from=Vector2.new(vp/2,vq)
        local to=Vector2.new(cx,cy+hpx/2)
        local mid=(from+to)/2; local len=(to-from).Magnitude
        local ang=math.deg(math.atan2(to.Y-from.Y,to.X-from.X))
        d.tracer.Visible=true
        d.tracer.BackgroundColor3=S.RainbowTracer and hsv(hue,1,1) or co
        d.tracer.Size=UDim2.fromOffset(math.floor(len),1)
        d.tracer.Position=UDim2.fromOffset(math.floor(mid.X-len/2),math.floor(mid.Y))
        d.tracer.Rotation=ang
    else d.tracer.Visible=false end
end

-- ========== GUI ==========
local K={
    Bg=Color3.fromRGB(8,8,14),
    Panel=Color3.fromRGB(14,14,24),
    Row=Color3.fromRGB(20,20,36),
    RowHi=Color3.fromRGB(34,34,58),
    Text=Color3.fromRGB(235,235,250),
    Dim=Color3.fromRGB(120,120,160),
    Danger=Color3.fromRGB(255,70,100),
}
local sc=nw("ScreenGui",{Name=gn,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=true,DisplayOrder=2147483647},pt)

-- 主面板
local PW=270
local mn=nw("Frame",{
    Size=UDim2.fromOffset(PW,700),
    Position=UDim2.new(0,20,0.1,0),
    BackgroundColor3=K.Bg,
    BackgroundTransparency=0.05,
    BorderSizePixel=0,
    ClipsDescendants=true,
    Active=true,
},sc)
cr(mn,UDim.new(0,12))
local mainStroke=stroke(mn,theme().S,2)
mainStroke.Transparency=0.2

-- 頂部光暈
local glow=nw("Frame",{
    Size=UDim2.new(1,0,0,80),
    BackgroundColor3=theme().S,
    BackgroundTransparency=0.85,
    BorderSizePixel=0,
    ZIndex=0,
},mn)
cr(glow,UDim.new(0,12))

-- 標題列
local tb=nw("Frame",{
    Size=UDim2.new(1,0,0,42),
    BackgroundColor3=Color3.fromRGB(12,12,22),
    BackgroundTransparency=0.2,
    BorderSizePixel=0,
    ZIndex=5,
},mn)
cr(tb,UDim.new(0,12))

local title=nw("TextLabel",{
    Size=UDim2.new(1,-90,1,0),
    Position=UDim2.new(0,14,0,0),
    BackgroundTransparency=1,
    Text="AXIOM  //  RIVALS  v6.5",
    TextColor3=theme().S,
    TextSize=14,
    Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left,
    ZIndex=7,
},tb)

-- 標題左側裝飾條
local bar=nw("Frame",{
    Size=UDim2.fromOffset(3,20),
    Position=UDim2.new(0,6,0.5,-10),
    BackgroundColor3=theme().S,
    BorderSizePixel=0,
    ZIndex=7,
},tb)
cr(bar,UDim.new(1,0))

-- 最小化按鈕
local cp=nw("TextButton",{
    Size=UDim2.fromOffset(24,24),
    Position=UDim2.new(1,-58,0,9),
    BackgroundColor3=K.Row,
    Text="—",
    TextColor3=theme().S,
    Font=Enum.Font.GothamBold,
    TextSize=14,
    BorderSizePixel=0,
    AutoButtonColor=false,
    ZIndex=7,
},tb)
cr(cp,UDim.new(0,6))

-- 關閉按鈕
local cx=nw("TextButton",{
    Size=UDim2.fromOffset(24,24),
    Position=UDim2.new(1,-30,0,9),
    BackgroundColor3=Color3.fromRGB(50,14,24),
    Text="×",
    TextColor3=K.Danger,
    Font=Enum.Font.GothamBold,
    TextSize=16,
    BorderSizePixel=0,
    AutoButtonColor=false,
    ZIndex=7,
},tb)
cr(cx,UDim.new(0,6))

-- 內容區
local content=nw("ScrollingFrame",{
    Size=UDim2.new(1,-10,1,-52),
    Position=UDim2.new(0,5,0,46),
    BackgroundTransparency=1,
    BorderSizePixel=0,
    ScrollBarThickness=3,
    ScrollBarImageColor3=theme().S,
    CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
    ZIndex=3,
},mn)
nw("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},content)
nw("UIPadding",{PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,8)},content)

local orderCount=0
local function nextOrder() orderCount=orderCount+1 return orderCount end

-- 可折疊區塊
local function makeCollapsible(titleText)
    local header=nw("TextButton",{
        Size=UDim2.new(1,0,0,34),
        BackgroundColor3=K.Row,
        Text="",
        AutoButtonColor=false,
        BorderSizePixel=0,
        LayoutOrder=nextOrder(),
    },content)
    cr(header,UDim.new(0,8))
    local hs=stroke(header,theme().S,1)
    hs.Transparency=0.5

    local arrow=nw("TextLabel",{
        Size=UDim2.fromOffset(18,18),
        Position=UDim2.new(0,10,0.5,-9),
        BackgroundTransparency=1,
        Text="▼",
        TextColor3=theme().S,
        TextSize=11,
        Font=Enum.Font.GothamBold,
        ZIndex=2,
    },header)

    local tl=nw("TextLabel",{
        Size=UDim2.new(1,-36,1,0),
        Position=UDim2.new(0,32,0,0),
        BackgroundTransparency=1,
        Text=titleText,
        TextColor3=K.Text,
        TextSize=13,
        Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=2,
    },header)

    local body=nw("Frame",{
        Size=UDim2.new(1,0,0,0),
        BackgroundTransparency=1,
        BorderSizePixel=0,
        LayoutOrder=nextOrder(),
        AutomaticSize=Enum.AutomaticSize.Y,
        ClipsDescendants=true,
    },content)
    nw("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},body)
    nw("UIPadding",{PaddingTop=UDim.new(0,2),PaddingBottom=UDim.new(0,2)},body)

    local bodyOrder=0
    local function bodyNext() bodyOrder=bodyOrder+1 return bodyOrder end

    local open=true
    header.MouseButton1Click:Connect(function()
        open=not open
        T:Create(arrow,TweenInfo.new(0.2),{Rotation=open and 0 or -90}):Play()
        body.Visible=open
    end)
    return body,bodyNext
end

-- 開關
local function makeToggle(parent,bodyNext,t,key,cb)
    local holder=nw("Frame",{
        Size=UDim2.new(1,0,0,32),
        BackgroundTransparency=1,
        BorderSizePixel=0,
        LayoutOrder=bodyNext(),
    },parent)
    local b=nw("TextButton",{
        Size=UDim2.new(1,0,1,0),
        BackgroundColor3=K.Row,
        BackgroundTransparency=0.2,
        Text="",
        AutoButtonColor=false,
        BorderSizePixel=0,
        ZIndex=2,
    },holder)
    cr(b,UDim.new(0,8))
    local bs=stroke(b,theme().S,1)
    bs.Transparency=0.7

    local swBg=nw("Frame",{
        Size=UDim2.fromOffset(38,18),
        Position=UDim2.new(1,-48,0.5,-9),
        BackgroundColor3=Color3.fromRGB(40,40,60),
        BorderSizePixel=0,
        ZIndex=3,
    },b)
    cr(swBg,UDim.new(1,0))

    local swKnob=nw("Frame",{
        Size=UDim2.fromOffset(14,14),
        Position=UDim2.new(0,2,0.5,-7),
        BackgroundColor3=K.Dim,
        BorderSizePixel=0,
        ZIndex=4,
    },swBg)
    cr(swKnob,UDim.new(1,0))

    local l=nw("TextLabel",{
        Size=UDim2.new(1,-100,1,0),
        Position=UDim2.new(0,14,0,0),
        BackgroundTransparency=1,
        Text=t,
        TextColor3=K.Text,
        TextSize=12,
        Font=Enum.Font.GothamMedium,
        TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=3,
    },b)

    local state=false
    local function refresh()
        T:Create(swBg,TweenInfo.new(0.2),{BackgroundColor3=state and theme().S or Color3.fromRGB(40,40,60)}):Play()
        T:Create(swKnob,TweenInfo.new(0.2,Enum.EasingStyle.Back),{
            Position=state and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7),
            BackgroundColor3=state and Color3.fromRGB(255,255,255) or K.Dim,
        }):Play()
    end
    refresh()
    b.MouseButton1Click:Connect(function()
        state=not state
        refresh()
        S[key]=state
        if cb then pcall(cb,state) end
    end)
    return b
end

-- 滑桿
local function makeSlider(parent,bodyNext,t,minV,maxV,default,cb)
    local holder=nw("Frame",{
        Size=UDim2.new(1,0,0,50),
        BackgroundColor3=K.Row,
        BackgroundTransparency=0.2,
        BorderSizePixel=0,
        LayoutOrder=bodyNext(),
    },parent)
    cr(holder,UDim.new(0,8))
    local hs=stroke(holder,theme().S,1)
    hs.Transparency=0.7

    nw("TextLabel",{
        Size=UDim2.new(1,-20,0,14),
        Position=UDim2.new(0,14,0,6),
        BackgroundTransparency=1,
        Text=t,
        TextColor3=K.Text,
        TextSize=11,
        Font=Enum.Font.GothamMedium,
        TextXAlignment=Enum.TextXAlignment.Left,
    },holder)

    local v=nw("TextLabel",{
        Size=UDim2.new(0,70,0,14),
        Position=UDim2.new(1,-84,0,6),
        BackgroundTransparency=1,
        Text=string.format("%.2f",default),
        TextColor3=theme().S,
        TextSize=11,
        Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Right,
    },holder)

    local tr=nw("Frame",{
        Size=UDim2.new(1,-28,0,8),
        Position=UDim2.new(0,14,0,32),
        BackgroundColor3=Color3.fromRGB(38,38,58),
        BorderSizePixel=0,
    },holder)
    cr(tr,UDim.new(1,0))

    local fl=nw("Frame",{
        Size=UDim2.new((default-minV)/(maxV-minV),0,1,0),
        BackgroundColor3=theme().S,
        BorderSizePixel=0,
    },tr)
    cr(fl,UDim.new(1,0))

    local kn=nw("Frame",{
        Size=UDim2.fromOffset(16,16),
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new((default-minV)/(maxV-minV),0,0.5,0),
        BackgroundColor3=Color3.fromRGB(255,255,255),
        BorderSizePixel=0,
        ZIndex=3,
    },tr)
    cr(kn,UDim.new(1,0))
    stroke(kn,theme().S,2)

    local dg=false
    local function sf(x)
        local rl=math.clamp((x-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1)
        local vv=minV+(maxV-minV)*rl
        fl.Size=UDim2.new(rl,0,1,0)
        kn.Position=UDim2.new(rl,0,0.5,0)
        v.Text=string.format("%.2f",vv)
        if cb then pcall(cb,vv) end
    end
    tr.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dg=true
            sf(i.Position.X)
        end
    end)
    U.InputChanged:Connect(function(i)
        if dg and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            sf(i.Position.X)
        end
    end)
    U.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dg=false
        end
    end)
    return holder
end

-- 按鈕
local function makeButton(parent,bodyNext,t,cb)
    local holder=nw("Frame",{
        Size=UDim2.new(1,0,0,34),
        BackgroundTransparency=1,
        BorderSizePixel=0,
        LayoutOrder=bodyNext(),
    },parent)
    local b=nw("TextButton",{
        Size=UDim2.new(1,0,1,0),
        BackgroundColor3=K.Row,
        BackgroundTransparency=0.2,
        Text=t,
        TextColor3=K.Text,
        TextSize=12,
        Font=Enum.Font.GothamMedium,
        AutoButtonColor=false,
        BorderSizePixel=0,
        ZIndex=2,
    },holder)
    cr(b,UDim.new(0,8))
    local bs=stroke(b,theme().S,1)
    bs.Transparency=0.7
    b.MouseButton1Click:Connect(function()
        if cb then pcall(cb,b) end
    end)
    return b
end

-- ========== 建構 UI ==========
local body,bodyNext

body,bodyNext=makeCollapsible("視覺")
makeToggle(body,bodyNext,"ESP 開關","ESPEnabled")
makeToggle(body,bodyNext,"名字","ShowName")
makeToggle(body,bodyNext,"距離","ShowDistance")
makeToggle(body,bodyNext,"血量","ShowHealth")
makeToggle(body,bodyNext,"追蹤線","ShowTracer")
makeToggle(body,bodyNext,"Hitbox 顯示","HitboxVis")
makeSlider(body,bodyNext,"彩虹速度",0,2,S.HueSpeed,function(v) S.HueSpeed=v end)
makeSlider(body,bodyNext,"ESP 距離",100,5000,S.MaxDistance,function(v) S.MaxDistance=v end)

body,bodyNext=makeCollapsible("戰鬥")
makeToggle(body,bodyNext,"自瞄開關","Aim",function(s) notify(s and "自瞄 ON" or "自瞄 OFF") end)
makeToggle(body,bodyNext,"自瞄牆檢","AimWall")
makeToggle(body,bodyNext,"FOV 顯示","ShowFOV")
makeToggle(body,bodyNext,"模擬滑鼠自瞄","MouseAim")
makeToggle(body,bodyNext,"FOV 距離平滑","FOVSmooth")
makeSlider(body,bodyNext,"FOV 半徑",30,800,S.AimFOV,function(v) S.AimFOV=v end)
makeSlider(body,bodyNext,"自瞄平滑",0,0.95,S.AimSmooth,function(v) S.AimSmooth=v end)
makeSlider(body,bodyNext,"滑鼠靈敏度",0.1,5,S.MouseSens,function(v) S.MouseSens=v end)
makeSlider(body,bodyNext,"滑鼠平滑",0,0.95,S.MouseSmooth,function(v) S.MouseSmooth=v end)

body,bodyNext=makeCollapsible("移動")
makeToggle(body,bodyNext,"穿牆","Noclip")
makeToggle(body,bodyNext,"Bunny Hop","BHop")
makeToggle(body,bodyNext,"無限跳躍","InfJump")
makeSlider(body,bodyNext,"移動速度",16,200,S.WalkSpeed,function(v) S.WalkSpeed=v end)
makeSlider(body,bodyNext,"跳躍力",50,300,S.JumpPower,function(v) S.JumpPower=v end)
makeButton(body,bodyNext,"記錄當前位置",function(b)
    if L.Character then
        local hrp=L.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            S.TeleportPos=hrp.CFrame
            notify("已記錄位置")
        end
    end
end)
makeButton(body,bodyNext,"傳回記錄點",function(b)
    if S.TeleportPos and L.Character then
        local hrp=L.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame=S.TeleportPos
            notify("已傳送")
        end
    else
        notify("尚未記錄位置")
    end
end)

body,bodyNext=makeCollapsible("其他")
makeToggle(body,bodyNext,"隊伍檢測","TeamCheck")
makeToggle(body,bodyNext,"反 AFK","AntiAFK")
makeToggle(body,bodyNext,"聊天通知","ChatNotify")
makeToggle(body,bodyNext,"進出通知","JoinLeaveNotify")
makeButton(body,bodyNext,"掃描模式：自動",function(b)
    if S.ScanMode=="auto" then S.ScanMode="player"
    elseif S.ScanMode=="player" then S.ScanMode="workspace"
    else S.ScanMode="auto" end
    b.Text="掃描模式："..(S.ScanMode=="auto" and "自動" or S.ScanMode=="player" and "僅玩家" or "僅 Workspace")
end)
makeButton(body,bodyNext,"切換主題",function(b)
    S.Theme=S.Theme%#THEMES+1
    b.Text="主題："..THEMES[S.Theme].name
    mainStroke.Color=theme().S
    title.TextColor3=theme().S
    bar.BackgroundColor3=theme().S
    glow.BackgroundColor3=theme().S
end)
makeButton(body,bodyNext,"隱藏 GUI",function()
    S.GuiVisible=not S.GuiVisible
    mn.Visible=S.GuiVisible
end)
makeButton(body,bodyNext,"儲存設定",function()
    if not writefile then notify("執行器不支援 writefile") return end
    local data={}
    for k,v in pairs(S) do
        if type(v)=="boolean" or type(v)=="number" or type(v)=="string" then data[k]=v end
    end
    local ok,err=pcall(function()
        writefile("axiom_v65.json",HS:JSONEncode(data))
    end)
    if ok then notify("設定已儲存") else notify("儲存失敗") end
end)
makeButton(body,bodyNext,"載入設定",function()
    if not readfile or not isfile then notify("執行器不支援") return end
    if not isfile("axiom_v65.json") then notify("找不到存檔") return end
    local ok,data=pcall(function() return HS:JSONDecode(readfile("axiom_v65.json")) end)
    if not ok or type(data)~="table" then notify("存檔錯誤") return end
    for k,v in pairs(data) do
        if S[k]~=nil then S[k]=v end
    end
    notify("設定已載入")
end)

-- ========== 通知系統 ==========
local notifFrame=nw("Frame",{
    Size=UDim2.fromOffset(240,34),
    Position=UDim2.new(1,-260,1,-60),
    BackgroundColor3=Color3.fromRGB(14,14,24),
    BackgroundTransparency=0.05,
    BorderSizePixel=0,
    Visible=false,
    ZIndex=200,
},sc)
cr(notifFrame,UDim.new(0,8))
stroke(notifFrame,theme().S,2)

local notifLbl=nw("TextLabel",{
    Size=UDim2.new(1,-16,1,0),
    Position=UDim2.new(0,8,0,0),
    BackgroundTransparency=1,
    Text="",
    TextColor3=K.Text,
    TextSize=12,
    Font=Enum.Font.Code,
    TextXAlignment=Enum.TextXAlignment.Left,
},notifFrame)

local notifQueue={}
notify=function(msg)
    if not S.Notify then return end
    table.insert(notifQueue,msg)
end
task.spawn(function()
    while true do
        if #notifQueue>0 then
            local msg=table.remove(notifQueue,1)
            notifLbl.Text="▸ "..msg
            notifFrame.Visible=true
            task.wait(2)
            notifFrame.Visible=false
        else
            task.wait(0.1)
        end
    end
end)

-- ========== 反 AFK ==========
task.spawn(function()
    while true do
        task.wait(math.random(25,35))
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

-- ========== 聊天/進出通知 ==========
local function onChatted(player,msg)
    if not S.ChatNotify then return end
    local lower=msg:lower()
    local kws={"noob","ez","lag","hack","cheat","report","kick","ban","aim","esp"}
    for _,kw in ipairs(kws) do
        if lower:find(kw,1,true) then
            notify("["..player.Name.."] "..msg)
            break
        end
    end
end
P.PlayerAdded:Connect(function(p)
    if S.JoinLeaveNotify then notify("加入: "..p.Name) end
    p.Chatted:Connect(function(msg) onChatted(p,msg) end)
end)
P.PlayerRemoving:Connect(function(p)
    if S.JoinLeaveNotify then notify("離開: "..p.Name) end
end)
for _,p in ipairs(P:GetPlayers()) do
    p.Chatted:Connect(function(msg) onChatted(p,msg) end)
end

-- ========== 自瞄 ==========
local hasMouseMoveRel=type(mousemoverel)=="function"
local fovCircle=nw("Frame",{
    Size=UDim2.fromOffset(S.AimFOV*2,S.AimFOV*2),
    AnchorPoint=Vector2.new(0.5,0.5),
    Position=UDim2.new(0.5,0,0.5,0),
    BackgroundTransparency=1,
    BorderSizePixel=0,
    Visible=false,
    ZIndex=1,
},sc)
local fovStroke=stroke(fovCircle,theme().S,2)
cr(fovCircle,UDim.new(1,0))

R:BindToRenderStep("AxiomMouseAim",201,function(dt)
    if not S.Aim or not S.MouseAim or not hasMouseMoveRel then return end
    local target=nil
    local vp=C.ViewportSize.X; local vq=C.ViewportSize.Y
    local cx,cy=vp/2,vq/2
    local best=math.huge
    for _,entry in ipairs(collectTargets()) do
        if not isTeamEntry(entry) then
            local part=entry.model:FindFirstChild("HitboxHead") or entry.head
            if part then
                local sp,on=C:WorldToViewportPoint(part.Position)
                if on then
                    local dx,dy=sp.X-cx,sp.Y-cy
                    local sd=math.sqrt(dx*dx+dy*dy)
                    if sd<=S.AimFOV and sd<best then best=sd target=entry end
                end
            end
        end
    end
    if not target then return end
    local part=target.model:FindFirstChild("HitboxHead") or target.head
    if not part then return end
    local sp,on=C:WorldToViewportPoint(part.Position)
    if not on then return end
    local dx=sp.X-cx
    local dy=sp.Y-cy
    local sd=math.sqrt(dx*dx+dy*dy)
    if sd<2 then return end
    local distFactor=1
    if S.FOVSmooth then
        distFactor=1-(sd/S.AimFOV)*0.9
        distFactor=math.clamp(distFactor,0.1,1)
    end
    dx=dx*(1-S.MouseSmooth)*S.MouseSens*distFactor
    dy=dy*(1-S.MouseSmooth)*S.MouseSens*distFactor
    mousemoverel(dx,dy)
end)

-- ========== 主渲染循環 ==========
R.RenderStepped:Connect(function(dt)
    hc=(hc+dt*S.HueSpeed)%1
    local targets=collectTargets()
    for _,entry in ipairs(targets) do pcall(rd,entry) end
    local alive={}
    for _,entry in ipairs(targets) do alive[entry.model]=true end
    for key,_ in pairs(cache) do
        if not alive[key] then cl(key) end
    end
    fovCircle.Visible=S.ShowFOV and S.Aim and S.GuiVisible
    if fovCircle.Visible then
        local px=S.AimFOV*2
        fovCircle.Size=UDim2.fromOffset(px,px)
        fovStroke.Color=hsv(hc,1,1)
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
        local c=L.Character
        local h=c and c:FindFirstChildOfClass("Humanoid")
        if h and h.FloorMaterial~=Enum.Material.Air then h.Jump=true end
    end
end)

R.Stepped:Connect(function()
    if S.Noclip and L.Character then
        for _,v in ipairs(L.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide=false end
        end
    end
end)

L.CharacterAdded:Connect(function(c)
    task.wait(0.5)
    local h=c:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed=S.WalkSpeed h.UseJumpPower=true h.JumpPower=S.JumpPower end
end)

-- ========== 拖動 ==========
local dg,dS,dP=false,nil,nil
tb.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dg=true
        dS,dP=i.Position,mn.Position
    end
end)
U.InputChanged:Connect(function(i)
    if dg and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-dS
        mn.Position=UDim2.new(dP.X.Scale,dP.X.Offset+d.X,dP.Y.Scale,dP.Y.Offset+d.Y)
    end
end)
U.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dg=false
    end
end)

-- ========== 收合 ==========
local cpd=false
cp.MouseButton1Click:Connect(function()
    cpd=not cpd
    local tg=cpd and UDim2.fromOffset(PW,42) or UDim2.fromOffset(PW,700)
    T:Create(mn,TweenInfo.new(0.25,Enum.EasingStyle.Quart),{Size=tg}):Play()
    content.Visible=not cpd
    cp.Text=cpd and "+" or "—"
end)

-- ========== 關閉 ==========
cx.MouseButton1Click:Connect(function()
    R:UnbindFromRenderStep("AxiomMouseAim")
    sc:Destroy()
    espGui:Destroy()
    for k,_ in pairs(cache) do cl(k) end
end)

-- ========== 隱藏鍵 ==========
U.InputBegan:Connect(function(i,g)
    if g then return end
    if i.KeyCode==S.HideKey then
        S.GuiVisible=not S.GuiVisible
        mn.Visible=S.GuiVisible
    end
end)

notify("AXIOM RIVALS v6.5 已載入 // 酷炫版")
print("[Axiom] v6.5 酷炫版載入完成")
