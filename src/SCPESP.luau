-- R226: native, pooled SCP collision-envelope ESP.
-- 3D: BoxHandleAdornment (engine tracks part transforms without Lua projection).
-- 2D: ScreenGui+UIStroke frames, projected only on a bounded refresh beat.
-- No Drawing API, global hooks, per-frame Workspace scans or per-tick allocations.
return function(common)
    local Workspace = common.Services.Workspace
    local Players = common.Services.Players
    local Config = {
        Enabled = false, Style = "3D", Box = true, Labels = true, ShowNames = true,
        NameFormat = "用户名", ShowJob = false, OnlyHostile = false,
        TargetNPCs = true, TeamCheck = false, MaxDistance = 850,
        MaxEntries = 36, TickRate = 20,
        Transparency3D = 0.30, Transparency2D = 0.15,
        BoxThickness = 1.6, NameSize = 14, JobSize = 13,
        LabelOffset = 2.4, ShowDistance = false, ShowHealth = false,
        JobTeamColor = true, JobTranslate = true,
        ColorEnemy = Color3.fromRGB(245, 80, 80),
        ColorAlly = Color3.fromRGB(75, 175, 225),
        ColorSCP = Color3.fromRGB(0, 0, 0),
        ColorLowHealth = Color3.fromRGB(255, 160, 0),
        Health = false, Skeleton = false, Tracer = false,
        Chams = false, OffScreen = false, NativeLabels = true,
    }
    local ESP = { Config = Config, Stats = { Seen = 0, Visible = 0, Ms = 0, Hz = 20, Failures = 0 } }
    local entries = {}
    local screen, layer, accumulator, lastCamera = nil, nil, 0, nil
    local stopped, serial, avg = false, 0, 0
    local wasEnabled = false
    local function dispose(entry)
        for _, component in ipairs(entry.parts or {}) do
            if component.adorn then pcall(function() component.adorn:Destroy() end) end
            if component.frame then pcall(function() component.frame:Destroy() end) end
        end
        if entry.label then pcall(function() entry.label:Destroy() end) end
    end
    local function hide(entry)
        for _, component in ipairs(entry.parts or {}) do
            if component.adorn then component.adorn.Visible = false end
            if component.frame then component.frame.Visible = false end
        end
        if entry.label then entry.label.Enabled = false end
    end
    local function clear()
        for key,entry in pairs(entries) do dispose(entry); entries[key]=nil end
    end
    local function mountScreen()
        if screen and screen.Parent then return screen end
        local gui = Instance.new("ScreenGui")
        gui.Name = "VortexionSCPESP2D"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 940
        local parent = common.GetGuiParent and common.GetGuiParent()
        if not parent then
            parent = common.LocalPlayer:FindFirstChildOfClass("PlayerGui")
        end
        if not parent then gui:Destroy() return nil end
        local ok = pcall(function() gui.Parent=parent end)
        if not ok then gui:Destroy() return nil end
        screen = gui
        return screen
    end
    -- SCP: Roleplay community team/rank vocabulary. Unmapped values remain original.
    local ROLE_ZH = {
        ["Class-D"]="D级人员", ["Class - D"]="D级人员", ["Class D"]="D级人员",
        ["Chaos Insurgency"]="混沌分裂者", ["Scientific Department"]="科研部",
        ["Security Department"]="安保部", ["Medical Department"]="医疗部",
        ["Administrative Department"]="行政部", ["Intelligence Agency"]="情报局",
        ["Internal Security Department"]="内部安全部",
        ["Rapid Response Team"]="快速反应部队", ["Mobile Task Forces"]="机动特遣队",
        ["Mobile Task Force"]="机动特遣队", ["O5 Council"]="O5议会",
        ["Foundation"]="基金会", ["Neutral"]="中立", ["Hostile"]="敌对",
        ["Recruit"]="新兵", ["Cadet"]="学员", ["Private"]="列兵",
        ["Corporal"]="下士", ["Sergeant"]="中士", ["Staff Sergeant"]="上士",
        ["Lieutenant"]="中尉", ["Captain"]="上尉", ["Commander"]="指挥官",
        ["Director"]="主管", ["Deputy Director"]="副主管",
        ["Supervisor"]="监督员", ["Special Agent"]="特工",
        ["Entry Agent"]="初级特工", ["Internal Agent"]="内部特工",
        ["Senior Supervisor"]="高级监督员", ["Lead Supervisor"]="首席监督员",
        ["Researcher"]="研究员", ["Junior Researcher"]="初级研究员",
        ["Senior Researcher"]="高级研究员", ["Intern"]="实习生",
        ["Doctor"]="医生", ["Nurse"]="护士", ["Veteran Class - D"]="资深D级人员",
        ["Conscript"]="征召兵", ["Trained Conscript"]="训练征召兵",
        ["Senior Conscript"]="高级征召兵", ["Alpha"]="阿尔法",
        ["Nu-7"]="Nu-7机动特遣队", ["Epsilon-11"]="Epsilon-11机动特遣队",
        ["Beta-7"]="Beta-7机动特遣队", ["Alpha-1"]="Alpha-1机动特遣队",
        ["Dedicated Class - D"]="资深D级人员", ["Adept Class - D"]="熟练D级人员",
        ["Advanced Class - D"]="高级D级人员", ["Board Director"]="董事会主管",
        ["Head Researcher"]="首席研究员", ["Trainee Researcher"]="见习研究员",
        ["General"]="将军", ["Major"]="少校", ["Colonel"]="上校",
        ["Task Force Leader"]="特遣队队长", ["Head Commander"]="总指挥官",
        ["Insurgency Command"]="叛乱指挥官", ["The Engineer"]="工程师",
        ["Intelligence Director"]="情报局局长", ["Internal Security Manager"]="内部安全经理",
        ["Medical Director"]="医疗部主管", ["Site Manager"]="站点经理",
        ["Junior Manager"]="初级经理", ["Senior Manager"]="高级经理",
        ["Site Assistant Manager"]="站点助理经理", ["Site Senior Manager"]="站点高级经理",
        ["Site Director"]="站点主管", ["Site Council"]="站点议会",
        ["Administrative Council"]="行政议会", ["Administrative Regulator"]="行政监察员",
    }
    local function translatedRank(raw)
        if not Config.JobTranslate then return raw end
        if ROLE_ZH[raw] then return ROLE_ZH[raw] end
        local normalized=tostring(raw):gsub("^%s+",""):gsub("%s+$","")
        return ROLE_ZH[normalized] or normalized
    end
    local function roleColor(player)
        if not player then return Config.ColorSCP end
        if not Config.JobTeamColor then return Config.ColorAlly end
        -- Prefer explicit live role color when a game version provides it.
        for _,key in ipairs({"JobColor", "RoleColor", "RankColor", "TeamColor"}) do
            local ok,value=pcall(function()return player:GetAttribute(key)end)
            if ok and typeof(value)=="Color3" then return value end
        end
        local team=player.Team
        if team then
            local ok,color=pcall(function()return team.TeamColor.Color end)
            if ok and typeof(color)=="Color3" then return color end
        end
        return Config.ColorAlly
    end
    local function role(player, cand)
        if not player then return "SCP收容体" end
        if common.Candidates and common.Candidates.GetJob then
            return translatedRank(common.Candidates:GetJob(cand))
        end
        return translatedRank(player.Team and player.Team.Name or "未知职位")
    end
    local function displayName(player,cand)
        if not Config.ShowNames then return "" end
        if not player then return "SCP收容体" end
        local name=(Config.NameFormat=="实体名" and cand.Character and cand.Character.Name) or player.Name
        return tostring(name or "")
    end
    local function labelExtra(cand)
        local info={}
        if Config.ShowDistance then
            info[#info+1] = tostring(math.floor(cand.WorldDistance or 0)) .. " studs"
        end
        if Config.ShowHealth and cand.Humanoid then
            local hp=math.max(0,math.floor(cand.Humanoid.Health or 0))
            local max=math.max(1,math.floor(cand.Humanoid.MaxHealth or 100))
            info[#info+1] = ("%d/%d HP"):format(hp,max)
        end
        return table.concat(info, " · ")
    end
    local function attachLabel(entry, head)
        if entry.label then return end
        local gui=Instance.new("BillboardGui")
        gui.Name="SCPLabel"
        gui.Size=UDim2.fromOffset(260,72)
        gui.StudsOffsetWorldSpace=Vector3.new(0,Config.LabelOffset,0)
        gui.AlwaysOnTop=true
        gui.ResetOnSpawn=false
        gui.Adornee=head
        local function addLine(name)
            local text=Instance.new("TextLabel")
            text.Name=name
            text.Size=UDim2.new(1,0,0,21)
            text.BackgroundTransparency=1
            text.Font=Enum.Font.GothamBold
            text.TextScaled=false
            text.TextSize=14
            text.TextStrokeTransparency=Config.LabelStroke == false and 1 or 0.2
            text.TextStrokeColor3=Color3.fromRGB(10,15,18)
            text.TextTruncate=Enum.TextTruncate.AtEnd
            if Config.LabelFont and Enum.Font[Config.LabelFont] then text.Font=Enum.Font[Config.LabelFont] end
            text.Parent=gui
            return text
        end
        local nameText=addLine("ESPName")
        local jobText=addLine("ESPJob")
        local metaText=addLine("ESPMeta")
        metaText.TextSize=12
        local parent=mountScreen()
        if not parent then gui:Destroy() return end
        gui.Parent=parent
        entry.label,entry.text,entry.roleText,entry.metaText=gui,nameText,jobText,metaText
    end
    local function discoverParts(cand)
        local model=cand.Character
        local parts={}
        local head=model:FindFirstChild("Head")
        if head and head:IsA("BasePart") then parts[#parts+1]=head end
        local torso=model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
            or model:FindFirstChild("HumanoidRootPart")
        if torso and torso:IsA("BasePart") and torso~=head then parts[#parts+1]=torso end
        -- SCP variants may lack a traditional rig.
        if #parts==0 and cand.HRP and cand.HRP:IsA("BasePart") then parts[1]=cand.HRP end
        return parts
    end
    local function construct(cand)
        local key=cand.Character
        local entry=entries[key]
        if entry then return entry end
        entry={parts={},character=key}
        entries[key]=entry
        for _, part in ipairs(discoverParts(cand)) do
            entry.parts[#entry.parts+1]={part=part}
        end
        return entry
    end
    local function ensureAdornment(component)
        if component.adorn and component.adorn.Parent then return component.adorn end
        local part=component.part
        if not part or not part.Parent then return nil end
        local adorn=Instance.new("BoxHandleAdornment")
        adorn.Name="SCP3DCollisionBox"
        adorn.Adornee=part
        adorn.Size=part.Size
        adorn.AlwaysOnTop=true
        adorn.ZIndex=4
        adorn.Transparency=Config.Transparency3D
        adorn.Visible=false
        adorn.Parent=screen or mountScreen() or part
        component.adorn=adorn
        return adorn
    end
    local function ensureFrame(component)
        if component.frame and component.frame.Parent then return component.frame end
        local gui=mountScreen()
        if not gui then return nil end
        local frame=Instance.new("Frame")
        frame.Name="SCP2DCollisionBox"
        frame.BackgroundTransparency=1
        frame.BorderSizePixel=0
        frame.Visible=false
        local stroke=Instance.new("UIStroke")
        stroke.Thickness=Config.BoxThickness
        stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
        stroke.Parent=frame
        frame.Parent=gui
        component.frame,component.stroke=frame,stroke
        return frame
    end
    -- Exact projected rectangle of an oriented BasePart, not a guessed player height.
    local function projectBounds(cam,part)
        local cf,sz=part.CFrame,part.Size*0.5
        local left,top,right,bottom=math.huge,math.huge,-math.huge,-math.huge
        local hasFront=false
        for sx=-1,1,2 do for sy=-1,1,2 do for szSign=-1,1,2 do
            local world=cf:PointToWorldSpace(Vector3.new(sz.X*sx,sz.Y*sy,sz.Z*szSign))
            local p=cam:WorldToViewportPoint(world)
            if p.Z>0.05 then
                hasFront=true
                left=math.min(left,p.X);right=math.max(right,p.X)
                top=math.min(top,p.Y);bottom=math.max(bottom,p.Y)
            end
        end end end
        if not hasFront or right-left<2 or bottom-top<2 then return nil end
        local v=cam.ViewportSize
        if right<0 or bottom<0 or left>v.X or top>v.Y then return nil end
        return left,top,right,bottom
    end
    function ESP:Update(dt)
        if stopped then return end
        if not Config.Enabled or (not Config.Box and not Config.ShowNames and not Config.ShowJob and not Config.ShowDistance and not Config.ShowHealth) then
            if wasEnabled then
                for _,entry in pairs(entries) do hide(entry) end
                wasEnabled=false
            end
            return
        end
        wasEnabled=true
        local cam=Workspace.CurrentCamera
        if not cam then return end
        accumulator += dt or 1/60
        local minHz=math.clamp(tonumber(Config.TickRate) or 20,8,30)
        local interval=1/minHz
        if avg>3 then interval=math.max(interval,1/12) end
        if common.VisualInterval then interval=common.VisualInterval(interval) end
        if accumulator<interval and cam==lastCamera then return end
        lastCamera=cam
        accumulator=0
        serial+=1
        local start=os.clock()
        local visible=0
        local roster=common.Candidates:Get()
        local seen=0
        for _,cand in ipairs(roster) do
            seen+=1
            if visible>=Config.MaxEntries then break end
            local character=cand.Character
            if not (character and character.Parent and cand.Humanoid and cand.Humanoid.Health>0) then continue end
            if not cand.Player and not Config.TargetNPCs then continue end
            if Config.OnlyHostile and common.Candidates.IsHostile and not common.Candidates:IsHostile(cand) then continue end
            if cand.WorldDistance>Config.MaxDistance then continue end
            local anchor=cand.Anchor
            if not anchor or not anchor.Parent then continue end
            local projected=cam:WorldToViewportPoint(anchor.Position)
            if projected.Z<=0 then continue end
            local entry=construct(cand)
            entry.seen=serial
            visible+=1
            local color = not cand.Player and Config.ColorSCP
                or ((common.Candidates.IsHostile and common.Candidates:IsHostile(cand)) and Config.ColorEnemy or Config.ColorAlly)
            local mode=Config.Style
            for _,component in ipairs(entry.parts) do
                local part=component.part
                if part and part.Parent then
                    if mode=="3D" then
                        if component.frame then component.frame.Visible=false end
                        local adorn=ensureAdornment(component)
                        if adorn then
                            adorn.Adornee=part
                            if adorn.Size~=part.Size then adorn.Size=part.Size end
                            adorn.Color3=color
                            adorn.Transparency=Config.Transparency3D
                            adorn.Visible=Config.Box
                        end
                    else
                        if component.adorn then component.adorn.Visible=false end
                        local frame=ensureFrame(component)
                        if frame then
                            local x,y,rx,by=projectBounds(cam,part)
                            if x then
                                frame.Position=UDim2.fromOffset(x,y)
                                frame.Size=UDim2.fromOffset(rx-x,by-y)
                                component.stroke.Color=color
                                component.stroke.Transparency=Config.Transparency2D
                                component.stroke.Thickness=Config.BoxThickness
                                frame.Visible=Config.Box
                            else frame.Visible=false end
                        end
                    end
                end
            end
            local nameText=displayName(cand.Player,cand)
            local jobText=(Config.ShowJob and cand.Player) and role(cand.Player,cand) or ""
            local metaText=labelExtra(cand)
            if (nameText~="" or jobText~="" or metaText~="") and cand.Head then
                attachLabel(entry,cand.Head)
                if entry.label then
                    entry.label.Adornee=cand.Head
                    entry.label.Enabled=true
                    entry.label.StudsOffsetWorldSpace=Vector3.new(0,Config.LabelOffset,0)
                    local y=0
                    for _,line in ipairs({
                        {entry.text,nameText,Config.NameSize,color},
                        {entry.roleText,jobText,Config.JobSize,roleColor(cand.Player)},
                        {entry.metaText,metaText,math.max(10,Config.JobSize-2),color},
                    }) do
                        local label,text,size,tint=line[1],line[2],line[3],line[4]
                        label.Visible=text~=""
                        if label.Visible then
                            label.Position=UDim2.fromOffset(0,y)
                            label.Size=UDim2.new(1,0,0,size+4)
                            label.TextSize=size
                            label.TextStrokeTransparency=Config.LabelStroke == false and 1 or 0.2
                            if Config.LabelFont and Enum.Font[Config.LabelFont] then label.Font=Enum.Font[Config.LabelFont] end
                            label.Text=text
                            label.TextColor3=tint
                            y+=size+4
                        end
                    end
                    entry.label.Size=UDim2.fromOffset(260,math.max(y,18))
                end
            elseif entry.label then entry.label.Enabled=false end
        end
        for key,entry in pairs(entries) do
            if entry.seen~=serial or not key.Parent then
                -- Keep no stale ESP references after death, cull or team changes.
                dispose(entry);entries[key]=nil
            end
        end
        local elapsed=(os.clock()-start)*1000
        avg=avg==0 and elapsed or (avg*.8+elapsed*.2)
        ESP.Stats={Seen=seen,Visible=visible,Ms=elapsed,AverageMs=avg,Hz=1/interval,
            Mode=Config.Style,Failures=ESP.Stats.Failures or 0}
    end
    function ESP:Cleanup()
        if stopped then return end
        stopped=true
        clear()
        if screen then pcall(function()screen:Destroy()end) end
        screen=nil
    end
    common.OnCleanup(function()ESP:Cleanup()end)
    return ESP
end
