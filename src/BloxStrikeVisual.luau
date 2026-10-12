return function(c)
    local tab,movement=c.Tabs.Visual,c.Tabs.Movement
    local s={esp=false,team=true,brightness=false,walk=false,speed=24}
    local highlights={}
    local lightingBackup
    local speedBackups={}
    local function clearESP()
        for p,h in pairs(highlights) do pcall(function() h:Destroy() end);highlights[p]=nil end
    end
    local function updateESP()
        if not s.esp then return end
        for _,player in ipairs(c.Players:GetPlayers()) do
            local model=c.Living(player)
            local valid=model and c.Enemy(player,s.team)
            local h=highlights[player]
            if not valid then
                if h then h:Destroy();highlights[player]=nil end
            else
                if not h or h.Parent~=model then
                    if h then h:Destroy() end
                    h=Instance.new("Highlight")
                    h.Name="VortexionBloxESP"
                    h.Adornee=model
                    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                    h.FillTransparency=0.75
                    h.OutlineTransparency=0.08
                    h.Parent=model
                    highlights[player]=h
                end
                h.FillColor=Color3.fromRGB(240,90,90)
                h.OutlineColor=Color3.fromRGB(255,160,100)
            end
        end
    end
    local espWorker
    local function startESP()
        if espWorker then return end
        espWorker=task.spawn(function()
            while s.esp and c.IsCurrent() do
                updateESP()
                task.wait(0.3)
            end
            espWorker=nil
        end)
    end
    tab:AddToggle("BloxESP",{Title="玩家高亮 ESP",Default=false,Callback=function(v)
        s.esp=v
        if v then startESP() else clearESP() end
    end})
    tab:AddToggle("BloxESPTeam",{Title="仅显示敌方",Default=true,Callback=function(v)s.team=v;updateESP() end})
    local function setLight(on)
        if on then
            if not lightingBackup then
                lightingBackup={Brightness=c.Lighting.Brightness,ClockTime=c.Lighting.ClockTime,
                    Ambient=c.Lighting.Ambient,OutdoorAmbient=c.Lighting.OutdoorAmbient,
                    GlobalShadows=c.Lighting.GlobalShadows}
            end
            c.Lighting.Brightness=2
            c.Lighting.ClockTime=14
            c.Lighting.Ambient=Color3.fromRGB(175,175,175)
            c.Lighting.OutdoorAmbient=Color3.fromRGB(175,175,175)
            c.Lighting.GlobalShadows=false
        elseif lightingBackup then
            for key,value in pairs(lightingBackup) do c.Lighting[key]=value end
            lightingBackup=nil
        end
    end
    tab:AddToggle("BloxFullbright",{Title="全亮",Default=false,Callback=function(v)s.brightness=v;setLight(v) end})
    local function restoreSpeed()
        for h,spd in pairs(speedBackups) do
            if h and h.Parent then h.WalkSpeed=spd end
            speedBackups[h]=nil
        end
    end
    local speedWorker
    movement:AddSlider("BloxWalkSpeed",{Title="移动速度",Min=16,Max=65,Default=24,Rounding=0,
        Callback=function(v)s.speed=v end})
    movement:AddToggle("BloxSpeedEnabled",{Title="自定义移动速度",Default=false,Callback=function(v)
        s.walk=v
        if not v then restoreSpeed();return end
        if speedWorker then return end
        speedWorker=task.spawn(function()
            while s.walk and c.IsCurrent() do
                local model,hum=c.Living(c.LocalPlayer)
                if hum then
                    if speedBackups[hum]==nil then speedBackups[hum]=hum.WalkSpeed end
                    if hum.WalkSpeed~=s.speed then hum.WalkSpeed=s.speed end
                end
                task.wait(0.25)
            end
            speedWorker=nil
        end)
    end})
    movement:AddParagraph({Title="移动兼容性",
        Content="本地 WalkSpeed 设置可能被游戏内移动控制器覆盖；服务器是否接受由游戏版本决定。"})
    c.OnCleanup(function()
        s.esp=false;s.walk=false
        clearESP();restoreSpeed();setLight(false)
    end)
end
