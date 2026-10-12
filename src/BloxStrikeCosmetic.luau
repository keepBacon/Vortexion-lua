-- BloxStrike camera appearance, capability-based local previews.
return function(c)
    local tab,knifeTab=c.Tabs.Appearance,c.Tabs.Knife
    local state={enabled=false,selected={},wear="Factory New",knife=false,knifeName="Butterfly Knife"}
    local original={}
    local added={}
    local cameraConnection
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
    local function restoreParts()
        for part,data in pairs(original) do
            if part and part.Parent then
                local current=part:FindFirstChild("VortexionSkin")
                if current then current:Destroy() end
                if data and data.Parent==nil then data.Parent=part end
            end
            original[part]=nil
        end
    end
    local function restoreKnife()
        if knifeFollow then knifeFollow:Disconnect();knifeFollow=nil end
        if knifeModel then knifeModel:Destroy();knifeModel=nil end
        for part,transparency in pairs(hidden) do
            if part and part.Parent then part.Transparency=transparency end
            hidden[part]=nil
        end
    end
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
        local current=part:FindFirstChild("VortexionSkin")
        if current then current:Destroy() end
        local clone=texture:Clone()
        clone.Name="VortexionSkin"
        clone.Parent=part
    end
    local function applyModel(model)
        if not state.enabled or not model or not model:IsA("Model") then return end
        local _,skins=roots()
        if not skins then return end
        local selectedName=state.selected[model.Name]
        if not selectedName then return end
        local category=skins:FindFirstChild(model.Name)
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
            for _,model in ipairs(camera:GetChildren()) do applyModel(model) end
        end
    end
    local function watchCamera()
        if cameraConnection then cameraConnection:Disconnect();cameraConnection=nil end
        local camera=c.Workspace.CurrentCamera
        if camera then
            cameraConnection=camera.ChildAdded:Connect(function(model)
                if not c.IsCurrent() then return end
                task.delay(0.15,function()
                    if c.IsCurrent() and model.Parent then
                        applyModel(model)
                    end
                end)
            end)
        end
    end
    tab:AddToggle("BloxSkinEnabled",{Title="启用本地皮肤替换",Default=false,Callback=function(v)
        state.enabled=v
        updateCamera()
        if v then watchCamera() elseif cameraConnection then cameraConnection:Disconnect();cameraConnection=nil end
    end})
    tab:AddDropdown("BloxSkinWear",{Title="磨损版本",Values={"Factory New","Minimal Wear","Field-Tested","Well-Worn","Battle-Scarred"},
        Default="Factory New",Callback=function(v)state.wear=v;updateCamera() end})
    local created={}
    local function addCategory(category)
        if not category or not category:IsA("Folder") or created[category.Name] then return end
        local values={}
        for _,skin in ipairs(category:GetChildren()) do
            if skin:IsA("Folder") or skin:IsA("Model") then table.insert(values,skin.Name) end
        end
        table.sort(values)
        if #values==0 then return end
        created[category.Name]=true
        local categoryName=category.Name
        local optionId="BloxSkin_"..categoryName:gsub("[^%w]","_")
        local default=state.selected[categoryName] or values[1]
        state.selected[categoryName]=default
        local targetTab=tab
        if categoryName:find("Knife") or categoryName:find("Glove") or categoryName=="Karambit" then
            targetTab=knifeTab
        end
        targetTab:AddDropdown(optionId,{Title=categoryName.." · 皮肤",Values=values,Default=default,
            Callback=function(v)
                state.selected[categoryName]=v
                if state.enabled then updateCamera() end
            end})
    end
    local skinFolderConn
    local function createSkinControls()
        local _,skins=roots()
        if not skins then
            c.Notify("皮肤资源","Assets/Skins 尚未加载，可使用刷新按钮")
            return
        end
        local list=skins:GetChildren()
        table.sort(list,function(a,b)return a.Name<b.Name end)
        local createdCount=0
        for _,category in ipairs(list) do
            if not created[category.Name] then
                addCategory(category)
                createdCount+=1
                if createdCount%6==0 then task.wait() end
            end
        end
        if skinFolderConn then skinFolderConn:Disconnect() end
        skinFolderConn=skins.ChildAdded:Connect(function(category)
            if c.IsCurrent() then task.defer(addCategory,category) end
        end)
        c.Notify("皮肤菜单","已加载 "..tostring(#list).." 个武器分类")
    end
    tab:AddButton({Title="刷新皮肤分类与下拉框",Callback=function()
        task.spawn(createSkinControls)
    end})
    tab:AddButton({Title="恢复默认皮肤",Callback=function()
        state.enabled=false;restoreParts()
        c.Notify("已恢复","本地已修改的材质已撤销")
    end})
    knifeTab:AddToggle("BloxCustomKnife",{Title="启用本地刀具模型",Default=false,
        Callback=function(v)
            state.knife=v
            restoreKnife()
            if v then
                local assets=c.ReplicatedStorage:FindFirstChild("Assets")
                local weapons=assets and assets:FindFirstChild("Weapons")
                local template=weapons and weapons:FindFirstChild(state.knifeName)
                local cameraModel=template and template:FindFirstChild("Camera")
                local cam=c.Workspace.CurrentCamera
                local old=cam and (cam:FindFirstChild("T Knife") or cam:FindFirstChild("CT Knife"))
                if not (cameraModel and cam and old) then
                    c.Notify("刀具不可用","缺少刀具资源或当前没有装备刀具")
                    return
                end
                local clone=cameraModel:Clone()
                clone.Name="VortexionKnife"
                for _,p in ipairs(clone:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Anchored=true
                    end
                end
                clone.Parent=cam
                if not clone.PrimaryPart then
                    local root=clone:FindFirstChildWhichIsA("BasePart",true)
                    if root then clone.PrimaryPart=root end
                end
                if not clone.PrimaryPart then clone:Destroy();return end
                knifeModel=clone
                for _,p in ipairs(old:GetDescendants()) do
                    if p:IsA("BasePart") or p:IsA("Texture") then
                        hidden[p]=p.Transparency;p.Transparency=1
                    end
                end
                knifeFollow=c.RunService.RenderStepped:Connect(function()
                    if not c.IsCurrent() or not state.knife then restoreKnife();return end
                    local currentCam=c.Workspace.CurrentCamera
                    if knifeModel and knifeModel.PrimaryPart and currentCam then
                        knifeModel:PivotTo(currentCam.CFrame*(knifeOffsets[state.knifeName] or CFrame.new(0,-1.5,1.5)))
                    end
                end)
            end
        end})
    knifeTab:AddDropdown("BloxKnifeType",{Title="自定义刀具",Values=supportedKnives,
        Default="Butterfly Knife",Callback=function(v)
            state.knifeName=v
            if state.knife then
                c.Notify("刀具类型已更改","关闭并再次开启刀具模型以应用新类型")
            end
        end})
    knifeTab:AddParagraph({Title="外观规则",
        Content="皮肤由游戏 Assets/Skins 目录生成选择项。武器材质和刀具只作客户端视觉更改，不更改库存或服务器伤害。"})
    c.OnCleanup(function()
        state.enabled=false;state.knife=false
        if cameraConnection then cameraConnection:Disconnect() end
        if skinFolderConn then skinFolderConn:Disconnect() end
        restoreParts();restoreKnife()
    end)
    task.defer(createSkinControls)
end
