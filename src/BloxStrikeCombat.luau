-- BloxStrike combat/weapon controls, no external UI dependencies.
return function(c)
    local tab,weapon=c.Tabs.Combat,c.Tabs.Weapon
    local s={aim=false,hold=false,touch=false,team=true,wall=true,fov=240,smooth=0.35,
        hitPart="Head",trigger=false,triggerDelay=0.15, lastTrigger=0,hitbox=false,hitSize=5}
    local ray=RaycastParams.new()
    ray.FilterType=Enum.RaycastFilterType.Exclude
    ray.IgnoreWater=true
    local function visible(model,part,cam)
        if not s.wall then return true end
        local ignore={cam}
        local mine=c.Character(c.LocalPlayer)
        if mine then table.insert(ignore,mine) end
        ray.FilterDescendantsInstances=ignore
        local origin=cam.CFrame.Position
        local hit=c.Workspace:Raycast(origin,part.Position-origin,ray)
        return not hit or hit.Instance:IsDescendantOf(model)
    end
    local function closest(cam)
        local center=cam.ViewportSize*0.5
        local target,best=nil,s.fov*s.fov
        for _,player in ipairs(c.Players:GetPlayers()) do
            if c.Enemy(player,s.team) then
                local model=c.Living(player)
                local part=model and (model:FindFirstChild(s.hitPart) or model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart"))
                if part and part:IsA("BasePart") then
                    local position,onscreen=cam:WorldToViewportPoint(part.Position)
                    if onscreen and position.Z>0 then
                        local delta=Vector2.new(position.X,position.Y)-center
                        local d=delta:Dot(delta)
                        if d<best and visible(model,part,cam) then best=d;target=part end
                    end
                end
            end
        end
        return target
    end
    local cached,targetTime=nil,0
    local function aimFrame(dt)
        if not c.IsCurrent() or not s.aim or not (s.hold or s.touch) then return end
        local cam=c.Workspace.CurrentCamera
        if not cam then return end
        local now=os.clock()
        if now>=targetTime then
            targetTime=now+0.08
            cached=closest(cam)
        end
        if not cached or not cached.Parent then return end
        local delta=cached.Position-cam.CFrame.Position
        if delta.Magnitude<0.05 then return end
        local alpha=1-math.exp(-math.max(1,s.smooth*25)*math.min(dt,0.1))
        cam.CFrame=cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position,cached.Position),alpha)
    end
    local conn
    local function syncAim()
        if conn then conn:Disconnect();conn=nil end
        if s.aim then conn=c.RunService.RenderStepped:Connect(aimFrame) end
    end
    c.Own(c.Input.InputBegan:Connect(function(input,processed)
        if processed then return end
        if input.UserInputType==Enum.UserInputType.MouseButton2 then s.hold=true end
    end))
    c.Own(c.Input.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton2 then s.hold=false end
    end))
    tab:AddToggle("BloxAimEnabled",{Title="瞄准辅助",Default=false,Callback=function(v) s.aim=v;syncAim() end})
    tab:AddToggle("BloxTouchAim",{Title="触屏持续瞄准",Default=false,Callback=function(v) s.touch=v end})
    tab:AddSlider("BloxAimFov",{Title="瞄准检测半径",Min=25,Max=500,Default=240,Rounding=0,Callback=function(v)s.fov=v end})
    tab:AddSlider("BloxAimSmooth",{Title="平滑度",Min=5,Max=100,Default=35,Rounding=0,Callback=function(v)s.smooth=v/100 end})
    tab:AddDropdown("BloxAimPart",{Title="瞄准部位",Values={"Head","HumanoidRootPart","UpperTorso","LowerTorso"},Default="Head",Callback=function(v)s.hitPart=v end})
    tab:AddToggle("BloxWallCheck",{Title="遮挡检查",Default=true,Callback=function(v)s.wall=v end})
    tab:AddToggle("BloxTeamCheck",{Title="敌方阵营过滤",Default=true,Callback=function(v)s.team=v end})
    -- Trigger helper intentionally does not forge mouse input. It reports a target under crosshair.
    local triggerConn
    local function stopTrigger()if triggerConn then triggerConn:Disconnect();triggerConn=nil end end
    tab:AddToggle("BloxTriggerAssist",{Title="准星目标提示",Default=false,Callback=function(v)
        s.trigger=v;stopTrigger()
        if v then
            triggerConn=c.RunService.Heartbeat:Connect(function()
                local now=os.clock()
                if not c.IsCurrent() then stopTrigger();return end
                if now-s.lastTrigger<math.max(0.1,s.triggerDelay) then return end
                s.lastTrigger=now
                local cam=c.Workspace.CurrentCamera
                if not cam then return end
                local origin=cam.CFrame.Position
                local dir=cam.CFrame.LookVector*500
                local filters={cam}
                local myCharacter=c.Character(c.LocalPlayer)
                if myCharacter then table.insert(filters,myCharacter) end
                ray.FilterDescendantsInstances=filters
                local hit=c.Workspace:Raycast(origin,dir,ray)
                local model=hit and hit.Instance:FindFirstAncestorOfClass("Model")
                local player=model and c.PlayerFromModel(model)
                if player and c.Enemy(player,s.team) and c.Living(player) then
                    c.Notify("准星目标",player.DisplayName)
                end
            end)
        end
    end})
    tab:AddSlider("BloxTriggerDelay",{Title="提示间隔（毫秒）",Default=600,Min=250,Max=2000,Rounding=0,
        Callback=function(v)s.triggerDelay=v/1000 end})
    weapon:AddParagraph({Title="武器接口兼容",
        Content="参考脚本通过 _performRaycast 和 private Weapon classes 改变弹道。当前版本不直接篡改武器命中结果。游戏更新后函数签名不稳定，盲目 Hook 会导致射击失效。"})
    weapon:AddButton({Title="检测武器组件",Callback=function()
        local components=c.ReplicatedStorage:FindFirstChild("Components")
        local weapons=components and components:FindFirstChild("Weapon")
        local classes=weapons and weapons:FindFirstChild("Classes")
        local bullet=classes and classes:FindFirstChild("Bullet")
        c.Notify("组件检测",bullet and "找到 Bullet 模块（未修改）" or "未找到兼容的 Bullet 模块")
    end})
    local originals={}
    local hitThread
    local function restoreHitbox()
        s.hitbox=false
        for part,info in pairs(originals) do
            if part and part.Parent then part.Size=info.Size;part.Transparency=info.Transparency end
            originals[part]=nil
        end
    end
    tab:AddToggle("BloxHitbox",{Title="本地角色碰撞体积预览",Default=false,Callback=function(v)
        if not v then restoreHitbox();return end
        s.hitbox=true
        if hitThread then return end
        hitThread=task.spawn(function()
            while c.IsCurrent() and s.hitbox do
                for _,player in ipairs(c.Players:GetPlayers()) do
                    if c.Enemy(player,s.team) then
                        local model=c.Living(player)
                        local part=model and model:FindFirstChild("HumanoidRootPart")
                        if part and part:IsA("BasePart") then
                            if not originals[part] then originals[part]={Size=part.Size,Transparency=part.Transparency} end
                            part.Size=Vector3.new(s.hitSize,s.hitSize,s.hitSize)
                            part.Transparency=0.65
                        end
                    end
                end
                task.wait(0.5)
            end
            hitThread=nil
        end)
    end})
    tab:AddSlider("BloxHitboxSize",{Title="本地碰撞箱显示大小",Min=2,Max=20,Default=5,Rounding=0,
        Callback=function(v)s.hitSize=v end})
    c.OnCleanup(function() s.aim=false;stopTrigger();if conn then conn:Disconnect() end;restoreHitbox() end)
end
