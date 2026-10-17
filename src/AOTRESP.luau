-- Vortexion AOTR ESP: per-titan billboard tags and nape highlights.
--
-- Tags live in one cloaked ScreenGui (gethui/CoreGui) with Adornee pointing at
-- each titan nape: parenting them into the titan model would expose them to
-- workspace enumeration, and a name like "TitanESP" is a one-line scan hit.
-- Refresh runs at 10Hz with entry reuse; dead/despawned titans drop their tag.
return function(app)
    local Players=app.Services.Players
    local Workspace=app.Services.Workspace
    local LocalPlayer=Players.LocalPlayer
    local ESP={}

    local Config={
        Enabled=false,
        Tags=true,
        Health=true,
        Distance=true,
        NapeHighlight=false,
        MaxDistance=1200,
        BossColor=Color3.fromRGB(255,80,80),
        NormalColor=Color3.fromRGB(255,200,90),
    }
    ESP.Config=Config

    local state={screenGui=nil,entries={},accum=0,disposed=false}

    local function ensureGui()
        if state.screenGui and state.screenGui.Parent then return state.screenGui end
        if state.screenGui then
            pcall(function() state.screenGui:Destroy() end)
            state.screenGui=nil
        end
        local parent=app.GetGuiParent()
        if not parent then return nil end
        local raw=Instance.new("ScreenGui")
        local ok,result=pcall(function()
            raw.Name=app.RandomName()
            raw.ResetOnSpawn=false
            raw.DisplayOrder=990
            raw.Parent=parent
            return app.Cloak and app.Cloak.Protect(raw) or raw
        end)
        if not ok then
            pcall(function() raw:Destroy() end)
            error(result,0)
        end
        state.screenGui=result
        return result
    end

    local function buildEntry(entry)
        local gui=ensureGui()
        if not gui then return nil end
        local created={}
        local function allocate(class)
            local object=Instance.new(class)
            table.insert(created,object)
            return object
        end
        -- Own every allocation before setting properties; failed setup rolls back.
        local ok,result=pcall(function()
            local billboard=allocate("BillboardGui")
            billboard.Name=app.RandomName()
            billboard.Adornee=entry.nape
            billboard.Size=UDim2.fromOffset(160,44)
            billboard.StudsOffset=Vector3.new(0,4,0)
            billboard.AlwaysOnTop=true
            billboard.MaxDistance=Config.MaxDistance
            local nameLabel=allocate("TextLabel")
            nameLabel.Name="Name"
            nameLabel.BackgroundTransparency=1
            nameLabel.Size=UDim2.new(1,0,0,16)
            nameLabel.Font=Enum.Font.GothamBold
            nameLabel.TextSize=13
            nameLabel.TextStrokeTransparency=0.4
            nameLabel.Text=entry.model.Name
            nameLabel.Parent=billboard
            local sub=allocate("TextLabel")
            sub.Name="Sub"
            sub.BackgroundTransparency=1
            sub.Position=UDim2.new(0,0,0,16)
            sub.Size=UDim2.new(1,0,0,14)
            sub.Font=Enum.Font.Gotham
            sub.TextSize=12
            sub.TextStrokeTransparency=0.5
            sub.Parent=billboard
            local barBack=allocate("Frame")
            barBack.Name="BarBack"
            barBack.Position=UDim2.new(0,0,0,30)
            barBack.Size=UDim2.new(1,0,0,4)
            barBack.BackgroundColor3=Color3.fromRGB(20,20,20)
            barBack.BorderSizePixel=0
            barBack.Parent=billboard
            local barFill=allocate("Frame")
            barFill.Name="BarFill"
            barFill.Size=UDim2.fromScale(1,1)
            barFill.BackgroundColor3=Color3.fromRGB(90,220,110)
            barFill.BorderSizePixel=0
            barFill.Parent=barBack
            billboard.Parent=gui
            if app.Cloak then billboard=app.Cloak.Protect(billboard) end

            local record={billboard=billboard,nameLabel=nameLabel,subLabel=sub,barBack=barBack,barFill=barFill,highlight=nil,cache={}}
            return record
        end)
        if not ok then
            for i=#created,1,-1 do pcall(function() created[i]:Destroy() end) end
            error(result,0)
        end
        return result
    end

    local function destroyEntry(record)
        local owned={}
        for _,key in ipairs({"nameLabel","subLabel","barFill","barBack","highlight","billboard"}) do
            if record[key] then table.insert(owned,record[key]) end
            record[key]=nil
        end
        record.cache={}
        for _,object in ipairs(owned) do pcall(function() object:Destroy() end) end
    end

    local function validEntry(record)
        if not record then return false end
        local ok,valid=pcall(function()
            return record.billboard and record.billboard.Parent==state.screenGui
                and record.nameLabel and record.nameLabel.Parent==record.billboard
                and record.subLabel and record.subLabel.Parent==record.billboard
                and record.barBack and record.barBack.Parent==record.billboard
                and record.barFill and record.barFill.Parent==record.barBack
        end)
        return ok and valid==true
    end

    local function clearAll()
        for _,record in pairs(state.entries) do destroyEntry(record) end
        state.entries={}
    end

    local function syncHighlight(record,entry,color)
        if not Config.NapeHighlight then
            if record.highlight then record.highlight:Destroy();record.highlight=nil end
            return
        end
        if not record.highlight or not record.highlight.Parent then
            if record.highlight then record.highlight:Destroy();record.highlight=nil end
            local raw=Instance.new("Highlight")
            local ok,result=pcall(function()
                raw.Name=app.RandomName()
                raw.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                raw.FillTransparency=0.7
                raw.OutlineTransparency=0
                raw.Parent=state.screenGui
                return app.Cloak and app.Cloak.Protect(raw) or raw
            end)
            if not ok then
                pcall(function() raw:Destroy() end)
                error(result,0)
            end
            record.highlight=result
        end
        record.highlight.Adornee=entry.model
        record.highlight.FillColor=color
        record.highlight.OutlineColor=color
    end

    local function updateESP()
        local Titans=app.Titans
        if not Titans then clearAll();return end
        local entries=Titans:All()
        if #entries==0 then clearAll();return end
        if not ensureGui() then clearAll();return end
        local hrp
        local char,_,root=app:Character()
        if root then hrp=root end
        local seen={}
        for _,entry in ipairs(entries) do
            if entry.nape and entry.nape.Parent then
                seen[entry.model]=true
                local record=state.entries[entry.model]
                if not validEntry(record) then
                    if record then destroyEntry(record) end
                    record=buildEntry(entry)
                    state.entries[entry.model]=record
                end
                if record then
                    local cache=record.cache
                    local color=entry.boss and Config.BossColor or Config.NormalColor
                    if cache.nape~=entry.nape then
                        cache.nape=entry.nape
                        record.billboard.Adornee=entry.nape
                    end
                    if cache.maxDist~=Config.MaxDistance then
                        cache.maxDist=Config.MaxDistance
                        record.billboard.MaxDistance=Config.MaxDistance
                    end
                    if cache.nameText~=entry.model.Name then
                        cache.nameText=entry.model.Name
                        record.nameLabel.Text=entry.model.Name
                    end
                    if cache.tagsVis~=Config.Tags then
                        cache.tagsVis=Config.Tags
                        record.nameLabel.Visible=Config.Tags
                    end
                    if cache.boss~=entry.boss then
                        cache.boss=entry.boss
                        record.nameLabel.TextColor3=color
                    end
                    if Config.Distance and hrp then
                        local d=math.floor((entry.nape.Position-hrp.Position).Magnitude)
                        local text=("%d studs"):format(d)
                        if cache.distText~=text then
                            cache.distText=text
                            record.subLabel.Text=text
                        end
                        if not record.subLabel.Visible then record.subLabel.Visible=true end
                    else
                        if record.subLabel.Visible then record.subLabel.Visible=false end
                    end
                    if Config.Health and entry.humanoid then
                        local maxH=math.max(entry.humanoid.MaxHealth,1)
                        local frac=math.clamp(entry.humanoid.Health/maxH,0,1)
                        if cache.frac~=frac then
                            cache.frac=frac
                            record.barFill.Size=UDim2.fromScale(frac,1)
                            record.barFill.BackgroundColor3=Color3.fromRGB(220,60,60):Lerp(Color3.fromRGB(90,220,110),frac)
                        end
                        if not record.barFill.Parent.Visible then record.barFill.Parent.Visible=true end
                    else
                        if record.barFill.Parent.Visible then record.barFill.Parent.Visible=false end
                    end
                    local enabled=Config.Tags or record.subLabel.Visible or record.barFill.Parent.Visible
                    if cache.enabled~=enabled then
                        cache.enabled=enabled
                        record.billboard.Enabled=enabled
                    end
                    syncHighlight(record,entry,color)
                end
            end
        end
        for model,record in pairs(state.entries) do
            if not seen[model] then
                destroyEntry(record)
                state.entries[model]=nil
            end
        end
    end

    local function visualInterval(base)
        base=tonumber(base) or 0.1
        if base~=base or base==math.huge or base==-math.huge or base<=0 then base=0.1 end
        local function accept(v)
            return type(v)=="number" and v==v and v~=math.huge and v~=-math.huge and v>0
        end
        if type(app.GetVisualInterval)=="function" then
            local ok,value=pcall(app.GetVisualInterval,app,base)
            if ok and accept(value) then return math.max(base,value) end
            return base
        end
        local ui=app.ui
        if ui and type(ui.GetVisualInterval)=="function" then
            local ok,value=pcall(function() return ui:GetVisualInterval(base) end)
            if ok and accept(value) then return math.max(base,value) end
        end
        return base
    end

    function ESP:Update(dt)
        if state.disposed then return end
        if not Config.Enabled then
            state.accum=0
            clearAll()
            return
        end
        -- Losing the local character must drop stale distance text immediately,
        -- independent of the (possibly throttled) visual cadence.
        if next(state.entries)~=nil then
            local _,_,root=app:Character()
            if not root then
                for _,record in pairs(state.entries) do
                    if record.subLabel.Visible then record.subLabel.Visible=false end
                end
            end
        end
        state.accum+=dt
        if state.accum<visualInterval(0.1) then return end
        state.accum=0
        app.Guard("ESP",updateESP)
    end

    function ESP:Stop()
        state.accum=0
        clearAll()
        if state.screenGui then
            pcall(function() state.screenGui:Destroy() end)
            state.screenGui=nil
        end
        Config.Enabled=false
    end

    app:OnStop(function()
        state.disposed=true
        ESP:Stop()
    end)

    return ESP
end
