-- BloxStrike camera appearance, capability-based local previews.
return function(c)
    local tab,knifeTab=c.Tabs.Appearance,c.Tabs.Knife
    local state={enabled=false,selected={},wear="Factory New",knife=false,knifeName="Butterfly Knife",touchButtons=false,gloveMode="自动",sleeves=true}
    local original={}
    local applied={}
    local dirty = false
    local reconcileKnife
    local knifeSource, knifeCamera
    local cameraConnection
    local stopNative, tryNative, updateNative
    local nativeTrack, nativeMode, nativeStarted
    local actionSerial, swingIndex = 0, 0
    local stopKnifeSounds, destroyAttachments, refreshButtons, destroyButtons, knifeApi
    -- Procedural local preview state: pose animation, one-shot sounds, arm attachments.
    local anim={mode="idle",started=0,duration=0}
    local activeSounds={}
    local attached={}
    local buttonGui, inspectButton, swingButton, stopButton
    local ANIM={equip=0.35,inspect=1.1,swing=0.28}
    local supportedKnives={"Butterfly Knife","Karambit","M9 Bayonet","Flip Knife","Gut Knife"}
    local knifeOffsets={
        ["Butterfly Knife"]=CFrame.new(0,-1.5,1.5),Karambit=CFrame.new(0,-1.5,1.5),
        ["M9 Bayonet"]=CFrame.new(0,-1.5,1),["Flip Knife"]=CFrame.new(0,-1.5,1.25),
        ["Gut Knife"]=CFrame.new(0,-1.5,0.5)
    }
    local knifeModel
    local hidden={}
    local knifeFollow
    local function roots()
        local assets=c.ReplicatedStorage:FindFirstChild("Assets")
        return assets,assets and assets:FindFirstChild("Skins")
    end
    -- Find a native view-model animation for a preview mode without loading it:
    -- hop-by-hop pcall lookups only, returns (animator,animation) or nil. Never
    -- creates a controller/animator, never waits, never loads the animation.
    local function findNativeAnimation(model,mode)
        if mode~="Equip" and mode~="Idle" and mode~="Inspect" and mode~="Heavy Swing" and mode~="Swing1" and mode~="Swing2" then return nil end
        if not c.IsCurrent() then return nil end
        if not model or not model.Parent then return nil end
        if model~=knifeModel then return nil end
        local animation
        local ok=pcall(function()
            local assets=c.ReplicatedStorage:FindFirstChild("Assets")
            local weaponAnimations=assets and assets:FindFirstChild("WeaponAnimations")
            local perKnife=weaponAnimations and weaponAnimations:FindFirstChild(state.knifeName)
            local cameraAnimations=perKnife and perKnife:FindFirstChild("CameraAnimations")
            animation=cameraAnimations and cameraAnimations:FindFirstChild(mode)
            if not (animation and animation:IsA("Animation")) then animation=nil end
        end)
        if not ok or not animation then return nil end
        local animator
        ok=pcall(function()
            animator=model:FindFirstChildWhichIsA("Animator",true)
            if not (animator and animator:IsA("Animator") and animator.Parent) then animator=nil end
        end)
        if not ok or not animator then return nil end
        if not c.IsCurrent() or model~=knifeModel or not model or not model.Parent then return nil end
        return animator,animation
    end
    local function restoreParts()
        for part,data in pairs(original) do
            if applied[part] then applied[part]:Destroy(); applied[part]=nil end
            if data and data.Parent==nil then
                if part and part.Parent then data.Parent=part else data:Destroy() end
            end
            original[part]=nil
        end
    end
    local function restoreKnife()
        knifeSource, knifeCamera = nil, nil
        actionSerial += 1
        if stopNative then stopNative() end
        if knifeModel then knifeModel:Destroy();knifeModel=nil end
        if stopKnifeSounds then stopKnifeSounds() end
        if destroyAttachments then destroyAttachments() end
        anim.mode="idle"
        if refreshButtons then refreshButtons() end
        for part,transparency in pairs(hidden) do
            if part and part.Parent then part.Transparency=transparency end
            hidden[part]=nil
        end
    end
    -- One-shot knife sounds: clone ReplicatedStorage/Sounds/<knife>/<folder>/<index>,
    -- parent under the view model, reclaim on Ended, on a bounded lifetime, or on any
    -- teardown path (disable/respawn/camera/cleanup).
    local SOUND_MAX_LIFETIME=5
    local previewSpeed,previewVolume=1,1
    local soundConnections={}
    local function disposeSound(sound)
        local connection=soundConnections[sound]
        local owned=activeSounds[sound]~=nil or connection~=nil
        activeSounds[sound],soundConnections[sound]=nil,nil
        if connection then pcall(function() connection:Disconnect() end) end
        if owned then pcall(function() sound:Destroy() end) end
    end
    local function playKnifeSound(folder,index)
        if not knifeModel then return nil end
        local sounds,perKnife,group,template
        local ok=pcall(function()
            sounds=c.ReplicatedStorage:FindFirstChild("Sounds")
            perKnife=sounds and sounds:FindFirstChild(state.knifeName)
            group=perKnife and perKnife:FindFirstChild(folder)
            template=group and group:FindFirstChild(index or "1")
        end)
        if not ok or not template then return nil end
        local clone
        local ok=pcall(function()
            clone=template:Clone()
            clone.Name=c.RandomName()
            clone.Parent=knifeModel
            if previewVolume~=1 and type(previewVolume)=="number" and previewVolume==previewVolume then
                local vol=tonumber(clone.Volume)
                if vol then clone.Volume=math.clamp(vol*previewVolume,0,10) end
            end
            clone:Play()
        end)
        if not ok or not clone then
            if clone then pcall(function() clone:Destroy() end) end
            return nil
        end
        activeSounds[clone]=tick()
        local connected,connection=pcall(function()
            local ended=clone.Ended
            if ended and type(ended.Connect)=="function" then
                return ended:Connect(function() disposeSound(clone) end)
            end
        end)
        if connected and connection then
            if activeSounds[clone]~=nil then soundConnections[clone]=connection
            else pcall(function() connection:Disconnect() end) end
        end
        return clone
    end
    -- A missing Ended capability still has a bounded lifetime.
    local function reclaimSounds(maxAge)
        for sound,born in pairs(activeSounds) do
            local ok,parent=pcall(function() return sound.Parent end)
            if not ok or not parent or tick()-born>=(maxAge or SOUND_MAX_LIFETIME) then
                disposeSound(sound)
            end
        end
    end
    function stopKnifeSounds()
        for sound in pairs(activeSounds) do disposeSound(sound) end
        for sound in pairs(soundConnections) do disposeSound(sound) end
    end
    -- Motor6D needs real BaseParts on both sides; a Model exposes PrimaryPart, a
    -- BasePart does not, so never read PrimaryPart unconditionally.
    local function firstBasePart(inst)
        if not inst then return nil end
        if inst:IsA("BasePart") then return inst end
        if inst:IsA("Model") then
            local primary=inst.PrimaryPart
            if primary and primary:IsA("BasePart") then return primary end
            return inst:FindFirstChildWhichIsA("BasePart",true)
        end
        return nil
    end
    -- Glove / sleeve attachment: clone the arm asset onto the view model arms with a
    -- Motor6D. Missing assets are skipped silently instead of fabricating ids, and a
    -- half-finished clone/motor pair is rolled back before anything is committed.
    local function attachArmAsset(folder,armName,assetName,offset)
        if not knifeModel or not folder then return nil end
        local arm=firstBasePart(knifeModel:FindFirstChild(armName,true))
        if not arm then return nil end
        local template=folder:FindFirstChild(assetName)
        if not template then return nil end
        local clone,motor
        local ok=pcall(function()
            clone=template:Clone()
            clone.Name=c.RandomName()
            clone.Parent=arm
            motor=Instance.new("Motor6D")
            motor.Name=c.RandomName()
            motor.Part0=arm
            motor.Part1=firstBasePart(clone)
            motor.C0=offset
            motor.Parent=arm
        end)
        if not ok or not clone or not motor then
            if motor then motor:Destroy() end
            if clone then clone:Destroy() end
            return nil
        end
        attached[clone]=true
        attached[motor]=true
        return clone
    end
    local function attachGloves()
        if not knifeModel then return end
        local living=c.Living(c.LocalPlayer)
        if not living then return end
        local assets=c.ReplicatedStorage:FindFirstChild("Assets")
        local weapons=assets and assets:FindFirstChild("Weapons")
        local sleeves=assets and assets:FindFirstChild("Sleeves")
        -- Glove source: 自动 follows the live team, T/CT force that branch, 不附着
        -- attaches nothing; any unrecognized value falls back to 自动, never invented.
        local mode=state.gloveMode
        if mode~="T Glove" and mode~="CT Glove" and mode~="不附着" then
            mode=living.Parent and living.Parent.Name=="Terrorists" and "T Glove" or "CT Glove"
        end
        if mode=="不附着" then return end
        local gloveOffset=CFrame.new(0,0,-1.5)
        local sleeveOffset=CFrame.new(0,0,0.5)
        if mode=="T Glove" then
            local gloves=weapons and weapons:FindFirstChild("T Glove")
            attachArmAsset(gloves,"Left Arm","Left Arm",gloveOffset)
            attachArmAsset(gloves,"Right Arm","Right Arm",gloveOffset)
        else
            local ctGloves=weapons and weapons:FindFirstChild("CT Glove")
            local sleeve=state.sleeves and sleeves and sleeves:FindFirstChild("IDF")
            attachArmAsset(sleeve,"Left Arm","Left Arm",sleeveOffset)
            attachArmAsset(ctGloves,"Left Arm","Left Arm",gloveOffset)
            attachArmAsset(sleeve,"Right Arm","Right Arm",sleeveOffset)
            attachArmAsset(ctGloves,"Right Arm","Right Arm",gloveOffset)
        end
    end
    function destroyAttachments()
        for obj in pairs(attached) do
            if obj then obj:Destroy() end
            attached[obj]=nil
        end
    end
    -- Own only tracks and rig changes on the disposable camera clone.
    local nativeSerial, nativeRig = 0, {}
    local function disposeNative(track)
        if track then
            pcall(function() track:Stop(0) end)
            pcall(function() track:Destroy() end)
        end
    end
    stopNative = function()
        nativeSerial += 1
        local track, rig = nativeTrack, nativeRig
        nativeTrack, nativeMode, nativeStarted, nativeRig = nil, nil, nil, {}
        disposeNative(track)
        for object, saved in pairs(rig) do
            pcall(function()
                if object.Parent then
                    if saved.transform then object.Transform = saved.transform
                    else object.Anchored = saved.anchored end
                end
            end)
        end
    end
    tryNative = function(name)
        local model = knifeModel
        stopNative()
        local serial = nativeSerial
        local animator, animation = findNativeAnimation(model, name)
        if not animator then return false end
        local function current()
            local ok, value = pcall(function()
                return c.IsCurrent() and state.knife and serial == nativeSerial and model == knifeModel
                    and model.Parent == knifeCamera and knifeCamera == c.Workspace.CurrentCamera
                    and animator:IsDescendantOf(model)
            end)
            return ok and value == true
        end
        local track
        local loaded = pcall(function() track = animator:LoadAnimation(animation) end)
        if not loaded or not track or not current() then disposeNative(track); return false end
        local prepared = pcall(function()
            for _, joint in ipairs(model:GetDescendants()) do
                if joint:IsA("Motor6D") then
                    nativeRig[joint] = {transform = joint.Transform}
                    local part = joint.Part1
                    if part and part ~= model.PrimaryPart and part:IsDescendantOf(model) then
                        if not nativeRig[part] then nativeRig[part] = {anchored = part.Anchored} end
                        part.Anchored = false
                    end
                end
            end
        end)
        if not prepared or not current() then
            if serial == nativeSerial then stopNative() end
            disposeNative(track)
            return false
        end
        nativeTrack, nativeMode, nativeStarted = track, name, tick()
        local played = pcall(function()
            track.Looped = name == "Idle"
            track:Play(0.05, 1, previewSpeed)
        end)
        if not played or not current() or nativeTrack ~= track then
            if nativeTrack == track then stopNative() else disposeNative(track) end
            return false
        end
        return true
    end
    updateNative = function()
        if not nativeTrack then return false end
        local playing, age = false, tick() - nativeStarted
        local ok = pcall(function() playing = nativeTrack.IsPlaying end)
        if not ok or (not playing and age >= 0.1) or (nativeMode ~= "Idle" and age >= 30) then
            local wasIdle = nativeMode == "Idle"
            stopNative()
            anim.mode = "idle"
            if not wasIdle then tryNative("Idle") end
        end
        return nativeTrack ~= nil
    end

    -- Procedural preview poses: local-only motion derived from tick(), never presented
    -- as the original animation set. Idle keeps the previous static offset exactly.
    local function startAnim(mode,duration,nativeName)
        actionSerial += 1
        local request, model = actionSerial, knifeModel
        anim.mode=mode
        anim.started=tick()
        local speed=previewSpeed
        if type(speed)~="number" or speed~=speed or not (speed>0 and speed<math.huge) then speed=1 end
        anim.duration=(duration or ANIM[mode] or 0)/math.clamp(speed,0.25,2)
        if not nativeName then
            if mode=="swing" then swingIndex=swingIndex%2+1; nativeName="Swing"..swingIndex
            else nativeName=mode=="equip" and "Equip" or "Inspect" end
        end
        tryNative(nativeName)
        return request==actionSerial and model==knifeModel and c.IsCurrent()
    end
    local function knifePose()
        local base=knifeOffsets[state.knifeName] or CFrame.new(0,-1.5,1.5)
        if nativeTrack or anim.mode=="idle" or anim.duration<=0 then return base end
        local t=tick()-anim.started
        if t>=anim.duration then return base end
        local k=t/anim.duration
        local p=base.Position
        if anim.mode=="equip" then
            local ease=1-(1-k)*(1-k)*(1-k)
            local from=CFrame.new(0,-1.9,0.9).Position
            return CFrame.new(from.X+(p.X-from.X)*ease,from.Y+(p.Y-from.Y)*ease,from.Z+(p.Z-from.Z)*ease)
        elseif anim.mode=="inspect" then
            local wave=math.sin(k*math.pi*2)
            local tilt=math.sin(k*math.pi*4)
            return CFrame.new(p.X+0.12*wave,p.Y+0.06*tilt,p.Z+0.05*math.sin(k*math.pi*2+1.5708))
        end
        local arc=math.sin(k*math.pi)
        return CFrame.new(p.X,p.Y-0.55*arc,p.Z+0.35*arc)
    end
    -- Touch actions: real production callbacks, built only when a touch device and a
    -- permissioned GUI parent exist; otherwise the buttons are simply not created.
    local function makeButton(parent,text,onClick)
        local btn=Instance.new("TextButton")
        btn.Name=c.RandomName()
        btn.Text=text
        btn.Size=UDim2.new(0,110,0,44)
        btn.Parent=parent
        local conn=btn.MouseButton1Click or btn.Activated
        if conn then pcall(function()conn:Connect(onClick) end) end
        return btn
    end
    local function buildButtons()
        if buttonGui or not state.touchButtons or not knifeModel then return end
        if not (c.Touch and c.Touch.Enabled) then return end
        local parent=c.GetGuiParent and c.GetGuiParent()
        if not parent then return end
        local gui,inspect,swing,stop
        local ok=pcall(function()
            gui=Instance.new("ScreenGui")
            gui.Name=c.RandomName()
            gui.Parent=parent
            inspect=makeButton(gui,"Inspect",function()knifeApi.Inspect() end)
            swing=makeButton(gui,"Swing",function()knifeApi.Swing() end)
            stop=makeButton(gui,"Stop",function()knifeApi.Stop() end)
            inspect.Position=UDim2.new(0,12,1,-56)
            swing.Position=UDim2.new(0,130,1,-56)
            stop.Position=UDim2.new(0,248,1,-56)
        end)
        if not ok or not gui or not inspect or not swing or not stop then
            if gui then gui:Destroy() end
            return
        end
        buttonGui=gui
        inspectButton,swingButton,stopButton=inspect,swing,stop
    end
    function refreshButtons()
        if state.touchButtons and knifeModel then
            buildButtons()
        elseif buttonGui then
            destroyButtons()
        end
    end
    function destroyButtons()
        if buttonGui then buttonGui:Destroy();buttonGui=nil end
        inspectButton,swingButton,stopButton=nil,nil,nil
    end
    knifeApi={
        Inspect=function()
            if not knifeModel or not c.IsCurrent() then return false end
            if not startAnim("inspect",ANIM.inspect) then return false end
            playKnifeSound("Inspect","1")
            return true
        end,
        Swing=function()
            if not knifeModel or not c.IsCurrent() then return false end
            if not startAnim("swing",ANIM.swing) then return false end
            local roll=math.random(2,3)
            playKnifeSound(roll==2 and "HitTwo" or "HitThree","1")
            return true
        end,
        HeavySwing=function()
            if not knifeModel or not c.IsCurrent() then return false end
            if not startAnim("swing",ANIM.swing,"Heavy Swing") then return false end
            playKnifeSound("HitThree","1")
            return true
        end,
        Stop=function()
            actionSerial += 1
            stopNative()
            stopKnifeSounds()
            anim.mode="idle"
            return true
        end,
        State=function()return anim.mode,knifeModel~=nil,next(activeSounds)~=nil end,
    }
    local function applySurface(part,source)
        if not part:IsA("BasePart") then return end
        local texture=source
        if source and not source:IsA("SurfaceAppearance") then
            texture=source:FindFirstChildOfClass("SurfaceAppearance")
        end
        if not texture then return end
        if original[part]==nil then
            local old=part:FindFirstChildOfClass("SurfaceAppearance")
            original[part]=old or false
            if old then old.Parent=nil end
        end
        if applied[part] then applied[part]:Destroy();applied[part]=nil end
        local clone=texture:Clone()
        clone.Name=c.RandomName()
        clone.Parent=part
        if c.Cloak then clone=c.Cloak.Protect(clone) end
        applied[part]=clone
    end
    local function applyModel(model, categoryName)
        if not state.enabled or not model or not model:IsA("Model") then return end
        local _,skins=roots()
        if not skins then return end
        local gloveCategory = skins:FindFirstChild("Sports Gloves")
        local gloveSkin = gloveCategory and gloveCategory:FindFirstChild(state.selected["Sports Gloves"] or "")
        local gloveCamera = gloveSkin and gloveSkin:FindFirstChild("Camera")
        local gloveWear = gloveCamera and (gloveCamera:FindFirstChild(state.wear) or gloveCamera:FindFirstChild("Factory New"))
        if gloveWear then
            for _, side in ipairs({"Left Arm", "Right Arm"}) do
                local arm = model:FindFirstChild(side, true)
                local glove = arm and arm:FindFirstChild("Glove", true)
                local source = gloveWear:FindFirstChild(side)
                if glove and source then applySurface(glove, source) end
            end
        end
        categoryName = categoryName or model.Name
        local selectedName=state.selected[categoryName]
        if not selectedName then return end
        local category=skins:FindFirstChild(categoryName)
        local skin=category and category:FindFirstChild(selectedName)
        local camera=skin and skin:FindFirstChild("Camera")
        local source=camera and (camera:FindFirstChild(state.wear) or camera:FindFirstChild("Factory New"))
        if not source then return end
        local weapon=model:FindFirstChild("Weapon")
        if not weapon then weapon=model end
        for _,part in ipairs(weapon:GetDescendants()) do
            if part:IsA("BasePart") then
                local match=source:FindFirstChild(part.Name)
                if match then applySurface(part,match) end
            end
        end
    end
    local function updateCamera()
        restoreParts()
        if not state.enabled then return end
        local camera=c.Workspace.CurrentCamera
        if camera then
            for _,model in ipairs(camera:GetChildren()) do
                applyModel(model, model == knifeModel and state.knifeName or nil)
            end
        end
    end
    local function watchCamera()
        if cameraConnection then cameraConnection:Disconnect();cameraConnection=nil end
        local camera=c.Workspace.CurrentCamera
        if camera then
            cameraConnection=camera.ChildAdded:Connect(function(model)
                if c.IsCurrent() and model ~= knifeModel then dirty = true end
            end)
        end
    end
    local skinEnabledOption = tab:AddToggle("BloxSkinEnabled",{Title="启用本地皮肤替换",Default=false,Callback=function(v)
        state.enabled=v
        updateCamera()
        dirty = true
        watchCamera()
    end})
    tab:AddDropdown("BloxSkinWear",{Title="磨损版本",Values={"Factory New","Minimal Wear","Field-Tested","Well-Worn","Battle-Scarred"},
        Default="Factory New",Callback=function(v)state.wear=v;updateCamera() end})
    local created, usedIds = {}, {}
    local skinFolderConn, resourcesConn
    local refreshing, queuedRefresh = false, false
    local function skinValues(category)
        local values = {}
        for _, skin in ipairs(category:GetChildren()) do
            if skin:IsA("Folder") or skin:IsA("Model") then table.insert(values, skin.Name) end
        end
        table.sort(values)
        return values
    end
    local function addCategory(category)
        if not c.IsCurrent() or not category or not category:IsA("Folder") then return false end
        local values = skinValues(category)
        if #values == 0 then return false end
        local categoryName = category.Name
        local existing = created[categoryName]
        if existing then
            -- Newly replicated skins extend the current dropdown in place.
            if existing.option and type(existing.option.SetValues) == "function" then
                local changed = #existing.values ~= #values
                if not changed then
                    for i, v in ipairs(values) do
                        if existing.values[i] ~= v then changed = true; break end
                    end
                end
                if changed then
                    local ok = pcall(function() existing.option:SetValues(values) end)
                    if ok then existing.values = values end
                end
            end
            return false
        end
        local optionId = "BloxSkin_" .. categoryName:gsub("[^%w]", "_")
        if usedIds[optionId] and usedIds[optionId] ~= categoryName then
            local suffix = ""
            for i = 1, #categoryName do suffix ..= ("%02x"):format(categoryName:byte(i)) end
            optionId ..= "_" .. suffix
        end
        local default = state.selected[categoryName]
        if not default or not table.find(values, default) then default = values[1] end
        local targetTab = tab
        if categoryName:find("Knife") or categoryName:find("Glove") or categoryName == "Karambit" then
            targetTab = knifeTab
        end
        -- Reserve id before creating the native option; restore on exception so refresh can retry.
        created[categoryName] = {values = values}
        local ok, option = pcall(function()
            return targetTab:AddDropdown(optionId, {Title = categoryName .. " · 皮肤", Values = values,
                Default = default, Callback = function(v)
                    state.selected[categoryName] = v
                    if state.enabled then updateCamera() end
                end})
        end)
        if not ok or not option then
            created[categoryName] = nil
            warn("[Vortexion/BloxStrike] skin dropdown " .. categoryName .. ": " .. tostring(option))
            return false
        end
        created[categoryName].option = option
        usedIds[optionId] = categoryName
        state.selected[categoryName] = default
        return true
    end
    local createSkinControls
    local function queueSkinRefresh()
        if queuedRefresh or not c.IsCurrent() then return end
        queuedRefresh = true
        task.defer(function()
            queuedRefresh = false
            if c.IsCurrent() and createSkinControls then createSkinControls(false) end
        end)
    end
    createSkinControls = function(manual)
        if not c.IsCurrent() or refreshing then return end
        local _, skins = roots()
        if not skins then
            if manual then c.Notify("皮肤资源", "Assets/Skins 尚未加载，正在等待资源出现") end
            return
        end
        refreshing = true
        local list = skins:GetChildren()
        table.sort(list, function(a, b) return a.Name < b.Name end)
        local createdCount = 0
        for _, category in ipairs(list) do
            if not c.IsCurrent() then break end
            if addCategory(category) then createdCount += 1 end
            if createdCount > 0 and createdCount % 8 == 0 then task.wait() end
        end
        refreshing = false
        if skinFolderConn then skinFolderConn:Disconnect(); skinFolderConn = nil end
        if skins.DescendantAdded then
            skinFolderConn = skins.DescendantAdded:Connect(queueSkinRefresh)
        else
            skinFolderConn = skins.ChildAdded:Connect(queueSkinRefresh)
        end
        if manual and c.IsCurrent() then
            c.Notify("皮肤菜单", ("当前 %d 个分类，新增 %d 个控件"):format(#list, createdCount))
        end
    end
    -- No busy polling: react only when Assets/Skins is replicated or its children change.
    if c.ReplicatedStorage.DescendantAdded then
        resourcesConn = c.ReplicatedStorage.DescendantAdded:Connect(function(obj)
            if obj.Name == "Skins" or (obj.Parent and obj.Parent.Name == "Skins") then
                queueSkinRefresh()
            end
        end)
    else
        resourcesConn = c.ReplicatedStorage.ChildAdded:Connect(queueSkinRefresh)
    end
    tab:AddButton({Title="刷新皮肤分类与下拉框",Callback=function()
        task.spawn(function() createSkinControls(true) end)
    end})
    tab:AddButton({Title="查看皮肤资源状态",Callback=function()
        local assets, skins = roots()
        local total = skins and #skins:GetChildren() or 0
        local selectors = 0
        for _ in pairs(created) do selectors += 1 end
        c.Notify("皮肤资源状态", ("Assets=%s · Skins=%s · 分类=%d · 控件=%d"):format(
            assets and "就绪" or "缺失", skins and "就绪" or "缺失", total, selectors))
    end})
    tab:AddButton({Title="恢复默认皮肤",Callback=function()
        -- Synchronize the visible toggle and the internal state (avoids stale UI).
        if skinEnabledOption and type(skinEnabledOption.SetValue) == "function" then
            skinEnabledOption:SetValue(false)
        else
            state.enabled = false
        end
        restoreParts()
        c.Notify("已恢复","本地已修改的材质已撤销")
    end})
    reconcileKnife = function()
        local cam = c.Workspace.CurrentCamera
        local old = cam and (cam:FindFirstChild("T Knife") or cam:FindFirstChild("CT Knife"))
        local living = c.Living(c.LocalPlayer)
        if not state.knife or not cam or not old or not living then
            if knifeModel then restoreParts(); restoreKnife() end
            return
        end
        if knifeModel and knifeSource == old and knifeCamera == cam then return end
        restoreParts()
        restoreKnife()
        local assets = c.ReplicatedStorage:FindFirstChild("Assets")
        local weapons = assets and assets:FindFirstChild("Weapons")
        local template = weapons and weapons:FindFirstChild(state.knifeName)
        local cameraModel = template and template:FindFirstChild("Camera")
        if not cameraModel then return end
        local clone = cameraModel:Clone()
        clone.Name = c.RandomName()
        if not clone.PrimaryPart then clone.PrimaryPart = clone:FindFirstChildWhichIsA("BasePart", true) end
        if not clone.PrimaryPart then clone:Destroy(); return end
        for _, part in ipairs(clone:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide=false; part.CanTouch=false; part.CanQuery=false; part.Anchored=true
            end
        end
        knifeModel, knifeSource, knifeCamera = clone, old, cam
        clone.Parent = cam
        if c.Cloak then c.Cloak.Protect(clone) end
        for _, part in ipairs(old:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Texture") then
                hidden[part]=part.Transparency; part.Transparency=1
            end
        end
        attachGloves()
        if not startAnim("equip",ANIM.equip) then return end
        playKnifeSound("Equip","1")
        refreshButtons()
        dirty = true
    end
    -- Local preview only: no weapon hooks, raycasts or remote calls.
    local TRAIL_LIFETIME, TRAIL_LIMIT = 0.5, 32
    local trailEnabled, trailStopped = false, false
    local trailColor = Color3.new(1, 1, 1)
    local trailEntries = {}
    local function removeTrail(index)
        local entry = trailEntries[index]
        if not entry then return end
        table.remove(trailEntries, index)
        local part = entry.part
        entry.part = nil
        if part then pcall(function() part:Destroy() end) end
    end
    local function clearTrailPreview()
        while #trailEntries > 0 do removeTrail(#trailEntries) end
    end
    local function finiteTrailNumber(n)
        return type(n) == "number" and n == n and math.abs(n) < math.huge
    end
    local function validTrailVector(v)
        return typeof(v) == "Vector3" and finiteTrailNumber(v.X) and finiteTrailNumber(v.Y) and finiteTrailNumber(v.Z)
    end
    local function previewTrail()
        if trailStopped or not trailEnabled or not c.IsCurrent() then return false end
        local camera = c.Workspace.CurrentCamera
        if not camera then return false end
        local ok, origin, direction = pcall(function() return camera.CFrame.Position, camera.CFrame.LookVector end)
        if not ok or not validTrailVector(origin) or not validTrailVector(direction) then return false end
        local magnitude = direction.Magnitude
        if not finiteTrailNumber(magnitude) or magnitude < 0.000001 then return false end
        direction = direction / magnitude
        origin = origin + direction * 2
        if #trailEntries >= TRAIL_LIMIT then removeTrail(1) end
        if #trailEntries >= TRAIL_LIMIT or trailStopped or not trailEnabled or not c.IsCurrent() then return false end
        local entry = {camera = camera, born = tick()}
        local success, committed = pcall(function()
            local part = Instance.new("Part")
            entry.part = part
            table.insert(trailEntries, entry)
            if trailStopped or not trailEnabled or not c.IsCurrent() or camera ~= c.Workspace.CurrentCamera then return false end
            part.Name = "VortexionTrailPreview"
            part.Anchored = true
            part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow = false, false, false, false
            part.Material, part.Color, part.Transparency = Enum.Material.Neon, trailColor, 0
            part.Size = Vector3.new(0.1, 0.1, 50)
            local midpoint = origin + direction * 25
            part.CFrame = CFrame.lookAt(midpoint, midpoint + direction)
            if not entry.part or trailStopped or not trailEnabled or not c.IsCurrent() or camera ~= c.Workspace.CurrentCamera then return false end
            part.Parent = camera
            return entry.part == part and not trailStopped and trailEnabled and c.IsCurrent() and camera == c.Workspace.CurrentCamera and part.Parent == camera
        end)
        if not success or not committed then
            for i = #trailEntries, 1, -1 do if trailEntries[i] == entry then removeTrail(i); break end end
            return false
        end
        return true
    end
    local function updateTrailPreview()
        if #trailEntries == 0 then return end
        if trailStopped or not trailEnabled or not c.IsCurrent() then clearTrailPreview(); return end
        local now, camera = tick(), c.Workspace.CurrentCamera
        for i = #trailEntries, 1, -1 do
            local entry = trailEntries[i]
            if entry then
                local age = now - entry.born
                if age >= TRAIL_LIFETIME or age < 0 or camera ~= entry.camera then
                    removeTrail(i)
                else
                    local updated, kept = pcall(function()
                        local part = entry.part
                        if not part or part.Parent ~= entry.camera then return false end
                        local fade = (1 - age / TRAIL_LIFETIME) ^ 2
                        part.Transparency = 1 - fade
                        part.Size = Vector3.new(0.1 * fade, 0.1 * fade, 50)
                        return true
                    end)
                    if not updated or not kept then removeTrail(i) end
                end
            end
        end
    end
    tab:AddToggle("BloxTrailPreview", {Title = "本地拖尾预览", Default = false, Callback = function(v)
        if trailStopped or not c.IsCurrent() then return end
        trailEnabled = v == true
        if not trailEnabled then clearTrailPreview() end
    end})
    tab:AddColorpicker("BloxTrailPreviewColor", {Title = "预览拖尾颜色", Default = trailColor, Callback = function(v)
        if trailStopped or not c.IsCurrent() or typeof(v) ~= "Color3" then return end
        local r, g, b = v.R, v.G, v.B
        if not finiteTrailNumber(r) or not finiteTrailNumber(g) or not finiteTrailNumber(b) or r < 0 or r > 1 or g < 0 or g > 1 or b < 0 or b > 1 then return end
        trailColor = v
    end})
    tab:AddButton({Title = "预览本地拖尾", Callback = previewTrail})
    tab:AddParagraph({Title = "拖尾预览范围", Content = "先开启预览，再点击按钮显示50 studs本地拖尾，0.5秒消退。仅手动预览，不连接真实开火、命中重写或网络事件。"})
    knifeTab:AddToggle("BloxCustomKnife",{Title="启用本地刀具模型",Default=false,Callback=function(v)
        state.knife=v
        if not v then restoreParts(); restoreKnife() end
        reconcileKnife()
        updateCamera()
    end})
    knifeTab:AddDropdown("BloxKnifeType",{Title="自定义刀具",Values=supportedKnives,
        Default="Butterfly Knife",Callback=function(v)
            state.knifeName=v
            if state.knife then
                restoreParts(); restoreKnife()
                reconcileKnife(); updateCamera()
            end
        end})
    knifeTab:AddToggle("BloxKnifeTouch",{Title="触屏刀具动作按钮",Default=false,Callback=function(v)
        state.touchButtons=v
        refreshButtons()
        c.Notify("刀具按钮",v and "触屏检视/挥动按钮已开启" or "触屏刀具按钮已关闭")
    end})
    knifeTab:AddSlider("BloxKnifePreviewSpeed",{Title="预览速度 %",Min=25,Max=200,Default=100,Callback=function(v)
        if not c.IsCurrent() then return end
        local n=tonumber(v)
        previewSpeed=(type(n)=="number" and n==n and n~=math.huge and n~=-math.huge and n>0) and math.clamp(n,25,200)/100 or 1
    end})
    knifeTab:AddSlider("BloxKnifeSoundVolume",{Title="音效音量 %",Min=0,Max=100,Default=100,Callback=function(v)
        if not c.IsCurrent() then return end
        local n=tonumber(v)
        previewVolume=(type(n)=="number" and n==n and n~=math.huge and n~=-math.huge and n>=0) and math.clamp(n,0,100)/100 or 1
    end})
    knifeTab:AddDropdown("BloxKnifeGloveMode",{Title="本地手套来源",Values={"自动","T Glove","CT Glove","不附着"},
        Default="自动",Callback=function(v)
            if not c.IsCurrent() then return end
            local mode=(v=="T Glove" or v=="CT Glove" or v=="不附着") and v or "自动"
            if state.gloveMode==mode then return end
            state.gloveMode=mode
            if knifeModel then destroyAttachments();if c.IsCurrent() and knifeModel then attachGloves() end end
        end})
    knifeTab:AddToggle("BloxKnifeSleeves",{Title="袖套开关（仅 CT 有效）",Default=true,Callback=function(v)
        if not c.IsCurrent() then return end
        local enabled=v==true
        if state.sleeves==enabled then return end
        state.sleeves=enabled
        if knifeModel then destroyAttachments();if c.IsCurrent() and knifeModel then attachGloves() end end
    end})
    knifeTab:AddButton({Title="刀具检视动画",Callback=function()knifeApi.Inspect() end})
    knifeTab:AddButton({Title="刀具挥动动画",Callback=function()knifeApi.Swing() end})
    knifeTab:AddButton({Title="刀具重挥动画",Callback=function()knifeApi.HeavySwing() end})
    knifeTab:AddButton({Title="停止动画与声音",Callback=function()knifeApi.Stop() end})
    knifeTab:AddParagraph({Title="刀具预览说明",
        Content="优先读取 Assets/WeaponAnimations/<刀具>/CameraAnimations 的 Equip、Idle、Inspect、Heavy Swing、Swing1、Swing2，只在本地模型自带 Animator 时播放；缺资源或加载失败则降级为程序式姿态。速度用于下一次本地预览，停止同时回收动画与声音。声音及手套/袖套按实际存在的资源使用；这些选项不修改服务器伤害、库存或游戏全局动画设置。"})
    knifeTab:AddParagraph({Title="外观规则",
        Content="皮肤由游戏 Assets/Skins 目录生成选择项。武器材质和刀具只作客户端视觉更改，不更改库存或服务器伤害。"})
    watchCamera()
    local cameraChanged = c.Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        clearTrailPreview(); restoreParts(); restoreKnife(); watchCamera(); dirty = true
    end)
    local elapsed = 0
    knifeFollow = c.RunService.RenderStepped:Connect(function(dt)
        if not c.IsCurrent() then clearTrailPreview(); return end
        updateTrailPreview()
        if not state.enabled and not state.knife and not knifeModel and next(activeSounds)==nil and anim.mode=="idle" then
            elapsed=0
            return
        end
        elapsed += dt
        if elapsed >= 0.1 then
            elapsed = 0
            reconcileKnife()
            if dirty then dirty = false; updateCamera() end
        end
        reclaimSounds()
        local nativePlaying = updateNative()
        if not nativePlaying and anim.mode~="idle" and tick()-anim.started>=anim.duration then
            anim.mode="idle"
            tryNative("Idle")
        end
        local cam = c.Workspace.CurrentCamera
        if knifeModel and knifeModel.PrimaryPart and cam then
            knifeModel:PivotTo(cam.CFrame * knifePose())
        end
    end)
    c.OnCleanup(function()
        trailStopped = true
        trailEnabled = false
        clearTrailPreview()
        knifeFollow:Disconnect(); cameraChanged:Disconnect()
        state.enabled=false;state.knife=false
        if cameraConnection then cameraConnection:Disconnect() end
        if skinFolderConn then skinFolderConn:Disconnect() end
        if resourcesConn then resourcesConn:Disconnect() end
        destroyButtons()
        restoreParts();restoreKnife()
    end)
    task.defer(function() createSkinControls(false) end)
end
