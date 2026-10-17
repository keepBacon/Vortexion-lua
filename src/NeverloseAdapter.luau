-- Vortexion Neverlose bridge. All existing game feature IDs and module APIs are preserved.
-- The shared UI is vendored offline; no HttpGet dependency at runtime.
return function(Neverlose, config)
    config = config or {}
    assert(type(Neverlose) == "table" and type(Neverlose.Window) == "function", "Neverlose UI unavailable")
    local env = config.Env or ((type(getgenv) == "function" and getgenv()) or _G)
    local UIS = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local GuiService = game:GetService("GuiService")
    local Workspace = game:GetService("Workspace")
    local HttpService = game:GetService("HttpService")
    local mobile = UIS.TouchEnabled
    local callbacks, connections, health, recent = {}, {}, {}, {}
    local window, root, scale, viewportCamera, cameraConn = nil, nil, nil, nil, nil
    local createdPages, selectedPage = {}, ""
    local resizing, lastViewport, lastInsets = false, "", ""
    local uiScale = 1
    local stats = {callbacks=0, inputs=0, errors=0, repairs=0, resizes=0}
    local bridge = {Active=true, Library=Neverlose, Options={}, Tabs={}, GameTabs={}, GUI=Neverlose.Holder and Neverlose.Holder.Instance,
        VisualHz=mobile and 30 or 60, NativeNoticesEnabled=not mobile, NoticeHistory={}, AutoFit=true, SafeArea=true,
        Trace=false, Debug=config.Debug == true, TouchMode=mobile and "手指" or "鼠标"}
    env.VortexionWindBridge = bridge -- backwards-compatible key, used for old bundle teardown
    env.VortexionNeverloseBridge = bridge

    local function copy(t)
        if type(t) ~= "table" then return t end
        local r = {}; for k,v in pairs(t) do r[k]=copy(v) end; return r
    end
    local function same(a,b)
        if type(a) ~= type(b) then return false end
        if type(a) ~= "table" then return a == b end
        for k,v in pairs(a) do if not same(v,b[k]) then return false end end
        for k in pairs(b) do if a[k]==nil then return false end end
        return true
    end
    local function finite(n, default)
        n = tonumber(n)
        if not n or n~=n or math.abs(n)==math.huge then return default end
        return n
    end
    local function clamp(n, lo, hi) return math.max(lo,math.min(hi,n)) end
    local function fire(fn,...)
        if type(fn) ~= "function" then return true end
        stats.callbacks=stats.callbacks+1
        local ok,err=pcall(fn,...)
        if not ok then
            stats.errors=stats.errors+1; bridge.LastError=tostring(err)
            warn("[Vortexion/Neverlose] "..tostring(err))
        end
        return ok
    end
    function bridge:Notify(info, message, duration)
        local title,desc,seconds
        if type(info)=="table" then
            title=tostring(info.Title or "Vortexion")
            desc=tostring(info.Content or info.Description or "")
            seconds=finite(info.Duration,4)
        else title=tostring(info or "Vortexion"); desc=tostring(message or ""); seconds=finite(duration,4) end
        local record=(title..": "..desc):sub(1,1500)
        self.NoticeHistory[#self.NoticeHistory+1]=record
        if #self.NoticeHistory>20 then table.remove(self.NoticeHistory,1) end
        if not self.NativeNoticesEnabled then print("[Vortexion/Notice] "..record); return end
        local ok,err=pcall(function() Neverlose:Notify({Title=title,Text=desc,Time=seconds,AutoClose=true}) end)
        if not ok then self.LastError=tostring(err) end
    end
    local function trace(id,from,v,ok)
        recent[#recent+1]=(from.." "..tostring(id).."="..tostring(v).." "..tostring(ok)):sub(1,220)
        if #recent>24 then table.remove(recent,1) end
        if bridge.Trace then print("[Vortexion/Neverlose/Trace] "..recent[#recent]) end
    end
    function bridge:FeatureTrace() return #recent>0 and table.concat(recent,"\n") or "暂无控件事件" end
    function bridge:OnDestroy(fn)
        if self.Active then callbacks[#callbacks+1]=fn else fire(fn) end
    end
    function bridge:Destroy()
        if not self.Active then return end
        self.Active=false
        if self.ServerSwitch then pcall(function() self.ServerSwitch:Stop() end) end
        for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
        for _,fn in ipairs(callbacks) do fire(fn) end
        table.clear(callbacks); table.clear(connections); table.clear(health)
        if env.VortexionWindBridge==self then env.VortexionWindBridge=nil end
        if env.VortexionNeverloseBridge==self then env.VortexionNeverloseBridge=nil end
        pcall(function() if Neverlose.Root then Neverlose.Root:Destroy() end end)
        window=nil; root=nil
    end
    bridge.Window=function() return window end
    function bridge:RegisterFeatureHealth(name,fn)
        if not self.Active or type(fn)~="function" then return false end
        health[tostring(name)]=fn; return true
    end
    function bridge:FeatureHealth()
        local out={}
        for name,fn in pairs(health) do
            local ok,v=pcall(fn)
            out[#out+1]=name..": "..(ok and tostring(v) or ("ERROR: "..tostring(v)))
        end
        table.sort(out)
        return #out>0 and table.concat(out,"\n") or "暂无游戏模块状态报告"
    end
    function bridge:GetVisualInterval(base)
        return math.max(finite(base,0),1/clamp(finite(self.VisualHz,30),5,60))
    end
    -- Read native state, including user tap updates. Never overwrite the user's
    -- last action with an older programmatic Set() or repeated default callback.
    function bridge:ReconcileGameplayOptions()
        local repaired=0
        if not self.Active then return 0 end
        for _,item in pairs(self.Options) do
            if item.Kind=="Toggle" and item.Native and (type(item.Native.Get)=="function" or item.Native.Value~=nil) then
                local ok,value=pcall(function() return item.Native:Get() end)
                if ok and type(value)=="boolean" and value~=item.Value then
                    if item:SyncFromNative() then repaired=repaired+1 end
                end
            end
        end
        stats.repairs=stats.repairs+repaired
        return repaired
    end
    local clock=0
    connections[#connections+1]=RunService.Heartbeat:Connect(function(dt)
        if not bridge.Active then return end
        clock=clock+clamp(finite(dt,0),0,0.5)
        if clock>=1 then
            clock=0
            bridge:ReconcileGameplayOptions()
            if bridge.RefreshDiagnostics then bridge:RefreshDiagnostics() end
        end
    end)

    local function readInsets()
        if not bridge.SafeArea then return 0,0,0,0 end
        local ok,t,b=pcall(function()return GuiService:GetGuiInset() end)
        if not ok or not t or not b then return 0,0,0,0 end
        return math.max(0,t.X), math.max(0,t.Y), math.max(0,b.X), math.max(0,b.Y)
    end
    -- Original library geometry: 203 px left navigation + 643 px main canvas,
    -- both at 682 px high. Never collapse columns or alter the Section tree.
    function bridge:FitViewport()
        if not self.Active or not root or not scale or not self.AutoFit then return end
        local cam=Workspace.CurrentCamera
        if not cam then return end
        local view=cam.ViewportSize
        if finite(view.X,0)<100 or finite(view.Y,0)<100 then return end
        local l,t,r,b=readInsets()
        local width=math.max(1,view.X-l-r)
        local height=math.max(1,view.Y-t-b)
        local fit=math.min((width-8)/846,(height-8)/682,1.18)
        local applied=clamp(math.min(fit*1.08*uiScale,(width-8)/846,(height-8)/682),0.2,1.4)
        local key=('%d:%d:%d:%d:%.3f'):format(width,height,l,t,applied)
        if key==lastViewport then return end
        lastViewport=key
        scale.Scale=applied
        root.AnchorPoint=Vector2.new(0,0)
        root.Size=UDim2.fromOffset(643,682)
        root.Position=UDim2.fromOffset(l+(width-846*applied)/2+203*applied,t+(height-682*applied)/2)
        self.LastViewport=('%dx%d · %.0f%% · 原生双列'):format(width,height,applied*100)
        stats.resizes=stats.resizes+1
    end
    local function bindCamera()
        if cameraConn then cameraConn:Disconnect();cameraConn=nil end
        local cam=Workspace.CurrentCamera
        if cam then
            cameraConn=cam:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                lastViewport='';bridge:FitViewport()
            end)
            connections[#connections+1]=cameraConn
        end
        lastViewport='';bridge:FitViewport()
    end

    local tabGroup
    -- Uses asset IDs shipped by this Neverlose UI library (not HTTP icon packs).
    local navIcons = {
        Aim='6031097226', Combat='6031097226', Visual='6035181869',
        Setting='6031280882', Script='6026663699', Other='6034230648',
        Reload='6031097226', Info='6035181869', Move='6035067832'
    }
    local function pageIcon(name)
        local n=tostring(name):lower()
        local key='Other'
        if n:find('瞄') or n:find('rage') or n:find('战斗') or n:find('射') then key='Aim'
        elseif n:find('esp') or n:find('视觉') or n:find('显示') or n:find('感知') then key='Visual'
        elseif n:find('移动') or n:find('速度') or n:find('飞行') then key='Move'
        elseif n:find('脚本') or n:find('代码') then key='Script'
        elseif n:find('设置') or n:find('配置') or n:find('调试') or n:find('界面') then key='Setting'
        elseif n:find('信息') then key='Info' end
        return 'rbxassetid://'..navIcons[key]
    end
    local function createTab(pageName,icon,category)
        -- Preserves native left navigation: TSection -> Tab -> alternating Section.
        if category or not tabGroup then
            tabGroup=window.Native:TSection(category or '游戏功能')
        end
        local sourcePage=tabGroup:Tab(pageName,pageIcon(pageName))
        local tab={Native=sourcePage,Title=pageName,OptionCount=0,Sections={}}
        local headings
        if pageName:find('视觉') or pageName:find('ESP') or pageName:find('感知') then
            headings={'Main','Players ESP','World ESP','Other'}
        elseif pageName:find('战斗') or pageName:find('自瞄') then
            headings={'Main','Targeting','Advanced','Other'}
        elseif pageName:find('世界') then
            headings={'Main','World','Visual','Other'}
        else
            headings={'Main','Settings','Advanced','Other'}
        end
        local sectionLimit=8
        local function newSection()
            local n=#tab.Sections+1
            local name=headings[math.min(n,#headings)]
            if n>#headings then name='Other · '..tostring(n-#headings+1) end
            local native=sourcePage:Section(name)
            tab.Sections[#tab.Sections+1]=native
            return native
        end
        local function sectionFor()
            if #tab.Sections==0 or tab.OptionCount>1 and (tab.OptionCount-1)%sectionLimit==0 then
                return newSection()
            end
            return tab.Sections[#tab.Sections]
        end
        local function addOption(kind,id,c)
            c=c or {};id=tostring(id)
            assert(bridge.Options[id]==nil,'重复选项 ID: '..id)
            local values=copy(c.Values or {})
            local low,high=finite(c.Min,0),finite(c.Max,100)
            local decimals=clamp(math.floor(finite(c.Rounding,0)),0,3)
            if kind=='Slider' then assert(low<high,'Invalid slider range: '..id) end
            local step=10^(-decimals)
            local function normalize(v)
                if kind=='Toggle' then return v==true end
                if kind=='Input' then return tostring(v==nil and '' or v) end
                if kind=='Slider' then
                    local n=clamp(finite(v,low),low,high)
                    return clamp(math.floor(n/step+0.5)*step,low,high)
                end
                if kind=='Colorpicker' then return typeof(v)=='Color3' and v or Color3.fromRGB(0,195,255) end
                if c.Multi then return type(v)=='table' and copy(v) or (v==nil and {} or {v}) end
                if type(v)=='number' then v=values[v] end
                if v==nil then return values[1] end
                return v
            end
            local initial=normalize(c.Default)
            local option={ID=id,Kind=kind,Value=copy(initial),Values=values,listeners={}}
            bridge.Options[id]=option
            local ready=false
            local initialized=false
            local function propagate(v,origin)
                if not bridge.Active and not bridge.Cleaning then return false end
                v=normalize(v)
                if initialized and same(v,option.Value) then return false end
                initialized=true
                option.Value=copy(v)
                trace(id,origin,v,'received')
                local success=fire(c.Callback,copy(v))
                trace(id,origin,v,success and 'OK' or 'ERROR')
                for _,fn in ipairs(option.listeners) do fire(fn,copy(v)) end
                return true
            end
            local function changed(v)
                if not ready or not bridge.Active then return end
                stats.inputs=stats.inputs+1
                propagate(v,'native')
            end
            tab.OptionCount=tab.OptionCount+1
            local section=sectionFor()
            local label=tostring(c.Title or id)
            -- Native Neverlose (Mana42138) controls take positional arguments.
            if kind=='Toggle' then
                option.Native=section:Toggle(label,changed)
            elseif kind=='Slider' then
                option.Native=section:Slider(label,low,high,finite(initial,low),changed)
            elseif kind=='Dropdown' then
                if c.Multi then
                    -- Original library has no multi-dropdown; use a single dropdown
                    -- with a text summary while retaining the existing table API.
                    option.Native=section:Dropdown(label,values,function(v)
                        local nextSelection=copy(option.Value)
                        if type(nextSelection)~='table' then nextSelection={} end
                        local found=false
                        for i,x in ipairs(nextSelection) do
                            if x==v then table.remove(nextSelection,i);found=true;break end
                        end
                        if not found then nextSelection[#nextSelection+1]=v end
                        changed(nextSelection)
                    end)
                else
                    option.Native=section:Dropdown(label,values,changed)
                end
            elseif kind=='Input' then
                option.Native=section:TextBox(label,changed)
            elseif kind=='Colorpicker' then
                option.Native=section:Colorpicker(label,initial,changed)
            end
            function option:GetValue() return copy(self.Value) end
            function option:GetNativeValue()
                if not self.Native then return copy(self.Value) end
                if self.Kind=='Dropdown' and c.Multi then return copy(self.Value) end
                local ok,v=pcall(function()
                    if type(self.Native.Get)=='function' then return self.Native:Get() end
                    return self.Native.Value
                end)
                return ok and v~=nil and normalize(v) or copy(self.Value)
            end
            function option:SyncFromNative()
                return propagate(self:GetNativeValue(),'audit')
            end
            function option:SetValue(v)
                if not bridge.Active and not bridge.Cleaning then return false end
                v=normalize(v)
                if same(v,self.Value) then return true end
                if bridge.Cleaning then return propagate(v,'cleanup') end
                local ok,err=pcall(function()
                    if self.Native and type(self.Native.Set)=='function' then
                        if self.Kind=='Dropdown' and c.Multi then
                            self.Native:Set(table.concat(v,', '))
                        elseif v~=nil then self.Native:Set(v) end
                    end
                end)
                if not ok then bridge.LastError=tostring(err) end
                -- Keep original feature callbacks and ID even when native Set fails.
                propagate(v,'setvalue')
                return ok
            end
            function option:SetValues(new)
                if not bridge.Active or kind~='Dropdown' or type(new)~='table' then return false end
                values=copy(new);self.Values=copy(new)
                local ok,err=pcall(function()
                    if self.Native and type(self.Native.Refresh)=='function' then self.Native:Refresh(values) end
                end)
                if not ok then bridge.LastError=tostring(err); return false end
                if not c.Multi then
                    local valid=false
                    for _,entry in ipairs(values) do if entry==self.Value then valid=true;break end end
                    if not valid then
                        if values[1] then self:SetValue(values[1])
                        else propagate(nil,'refresh-empty') end
                    end
                end
                return true
            end
            function option:OnChanged(fn)
                if type(fn)=='function' then
                    self.listeners[#self.listeners+1]=fn
                    if bridge.Active then fire(fn,copy(self.Value)) end
                end
                return self
            end
            ready=true
            -- Original library expects :Set to update visuals, but callbacks
            -- are protected until after widget construction.
            if option.Native and type(option.Native.Set)=='function' and initial~=nil and not (kind=='Dropdown' and c.Multi) then
                local ok,err=pcall(function()option.Native:Set(initial)end)
                if not ok then bridge.LastError=tostring(err) end
            end
            propagate(initial,'initial')
            return option
        end
        for _,kind in ipairs({'Toggle','Slider','Dropdown','Input','Colorpicker'}) do
            tab['Add'..kind]=function(_,id,c)return addOption(kind,id,c)end
        end
        function tab:AddButton(info)
            info=info or {};self.OptionCount=self.OptionCount+1
            return sectionFor():Button(tostring(info.Title or '运行'),function()
                if bridge.Active and not info.Locked then fire(info.Callback) end
            end)
        end
        function tab:AddParagraph(info)
            info=info or {};self.OptionCount=self.OptionCount+1
            return sectionFor():Paragraph(info.Title or '说明',info.Content or info.Desc or '')
        end
        bridge.Tabs[#bridge.Tabs+1]=tab
        return tab
    end

    local function installSettings()
        local appearance=createTab('界面与布局',nil,'VORTEXION · UI')
        local diagnostics=createTab('UI 调试')
        local configuration=createTab('配置')
        bridge.SettingsTabs={['主题']=appearance,['界面']=appearance,['调试']=diagnostics,['配置']=configuration}
        appearance:AddParagraph({Title='Neverlose · 原生排列', Content='保持侧栏和两列 Section 结构。适配只改变整体缩放和触控区域，不改控件位置。'})
        appearance:AddParagraph({Title='图标资源',Content=tostring(bridge.BrandMode or '读取中')})
        appearance:AddToggle('nl_auto_fit',{Title='自适应屏幕',Default=true,Callback=function(v)bridge.AutoFit=v;lastViewport='';bridge:FitViewport()end})
        appearance:AddToggle('nl_safe_area',{Title='屏幕安全区域',Default=true,Callback=function(v)bridge.SafeArea=v;lastViewport='';bridge:FitViewport()end})
        appearance:AddSlider('nl_scale',{Title='界面缩放',Min=60,Max=160,Default=100,Callback=function(v)uiScale=v/100;lastViewport='';bridge:FitViewport()end})
        appearance:AddButton({Title='恢复窗口位置',Callback=function()lastViewport='';bridge:FitViewport()end})
        appearance:AddToggle('nl_notifications',{Title='屏幕通知',Default=not mobile,Callback=function(v)bridge.NativeNoticesEnabled=v end})
        appearance:AddDropdown('nl_visual_hz',{Title='画面更新频率',Values={'原速','均衡','省电'},Default='均衡',Callback=function(v)bridge.VisualHz=({['原速']=60,['均衡']=30,['省电']=10})[v] or 30 end})
        local debug=diagnostics:AddParagraph({Title='触控与回调状态',Content='等待初始化'})
        function bridge:RefreshDiagnostics()
            debug:SetDesc(self:GetDiagnostics())
        end
        diagnostics:AddButton({Title='输出全部模块运行状态',Callback=function()print(bridge:FeatureHealth())end})
        diagnostics:AddButton({Title='最近控件事件',Callback=function()print(bridge:FeatureTrace())end})
        diagnostics:AddToggle('nl_trace',{Title='跟踪控件回调',Default=false,Callback=function(v)bridge.Trace=v end})
        diagnostics:AddButton({Title='重新同步开关',Callback=function()
            local n=bridge:ReconcileGameplayOptions()
            bridge:Notify('状态校验','同步 '..n..' 项')
        end})
        diagnostics:AddButton({Title='测试触控反馈',Callback=function()
            bridge.LastTouchProbe='点击成功 '..tostring(os.clock())
            bridge:Notify('触控测试','Neverlose 点击已收到')
            bridge:RefreshDiagnostics()
        end})
        bridge.GetDiagnostics=function()
            local n=0;for _ in pairs(bridge.Options)do n=n+1 end
            return ('%s | %s | %d 个控件 | %d 回调 | %d 错误 | %s')
                :format(bridge.TouchMode,bridge.LastViewport or '等待视口',n,stats.callbacks,stats.errors,bridge.LastError or '无')
        end
        local configName=configuration:AddInput('nl_config_name',{Title='配置名称',Default='default'})
        local function configPath()
            local name=tostring(configName.Value or 'default')
            name=name:match('^[%w_%-]+$') and name or 'default'
            return 'VortexionR227_'..name..'.json'
        end
        configuration:AddButton({Title='保存配置',Callback=function()
            if type(writefile)~='function' then bridge:Notify('配置','执行器不支持 writefile');return end
            local serialized={}
            for id,opt in pairs(bridge.Options) do
                if id~='nl_config_name' and opt.Kind~='Colorpicker' then serialized[id]=opt.Value end
            end
            local ok,err=pcall(function()writefile(configPath(),HttpService:JSONEncode(serialized))end)
            bridge:Notify('配置',ok and '保存成功' or tostring(err))
        end})
        configuration:AddButton({Title='加载配置',Callback=function()
            if type(readfile)~='function' then bridge:Notify('配置','执行器不支持 readfile');return end
            local ok,count=pcall(function()
                local data=HttpService:JSONDecode(readfile(configPath()))
                local changed=0
                for id,value in pairs(data) do
                    local opt=bridge.Options[id]
                    if opt and opt:SetValue(value) then changed=changed+1 end
                end
                return changed
            end)
            bridge:Notify('配置',ok and ('读取 '..count..' 项') or tostring(count))
        end})
    end

    function bridge:CreateWindow(info)
        if window then return window end
        if not self.Active then return nil end
        info=info or {}
        local deadline=os.clock()+6
        while not Workspace.CurrentCamera and self.Active and os.clock()<deadline do task.wait(0.05) end
        assert(Workspace.CurrentCamera,'Neverlose requires CurrentCamera')
        local brandAsset,brandReason
        if type(VortexionLogoAssetFactory)=='function' then
            brandAsset,brandReason=VortexionLogoAssetFactory()
        end
        self.BrandMode=brandReason or '默认 Roblox 图标'
        local native=Neverlose:Window({Title='VORTEXION',CFG='Vortexion',Key=Enum.KeyCode.RightControl,
            External={KeySystem=false,Key={}}})
        root=Neverlose.MainFrame
        assert(root,'Neverlose native MainFrame unavailable')
        scale=Instance.new('UIScale');scale.Name='VortexionMobileScale';scale.Scale=1;scale.Parent=root
        self.GUI=Neverlose.Root
        if brandAsset and Neverlose.Root then
            local image=Neverlose.Root:FindFirstChild('PlayerImage',true)
            if image and image:IsA('ImageLabel') then image.Image=brandAsset end
        end
        window={Native=native,Root=root,GameTabs=bridge.GameTabs}
        function window:AddTab(data)
            data=data or {}
            local page=createTab(tostring(data.Title or '功能'))
            bridge.GameTabs[#bridge.GameTabs+1]=page
            return page
        end
        function window:SelectTab(i)
            local tab=bridge.GameTabs[i]
            if not bridge.Active or not tab then return end
            selectedPage=tab.Title
            tab.Native:Select()
        end
        function window:Minimize()Neverlose:VisMain(false)end
        function window:Destroy()bridge:Destroy()end
        function window:InstallSettings()end
        -- Header-only drag: touching sliders, tabs and the content itself never
        -- moves the window. Works even if the user chooses a zoomed native layout.
        local title=root:FindFirstChild('TitleMain',true)
        if title then
            title.Active=true
            local dragStart,basePosition,dragInput
            local function start(input)
                if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
                    dragInput=input;dragStart=input.Position;basePosition=root.Position
                end
            end
            connections[#connections+1]=title.InputBegan:Connect(start)
            connections[#connections+1]=UIS.InputChanged:Connect(function(input)
                if not dragInput then return end
                if input~=dragInput and not (dragInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then return end
                local delta=input.Position-dragStart
                root.Position=UDim2.fromOffset(basePosition.X.Offset+delta.X,basePosition.Y.Offset+delta.Y)
            end)
            connections[#connections+1]=UIS.InputEnded:Connect(function(input)
                if input==dragInput or dragInput and dragInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseButton1 then dragInput=nil end
            end)
        end
        -- Fixed-position reopening affordance when native menu is hidden.
        local reopen=Instance.new('TextButton')
        reopen.Name='VortexionReopen';reopen.Text='V';reopen.TextSize=22
        reopen.Font=Enum.Font.GothamBold
        reopen.BackgroundColor3=Color3.fromRGB(14,39,61)
        reopen.TextColor3=Color3.fromRGB(145,207,234)
        reopen.Size=UDim2.fromOffset(46,46)
        reopen.Position=UDim2.fromOffset(24,80)
        reopen.Parent=Neverlose.Root
        connections[#connections+1]=reopen.MouseButton1Click:Connect(function()
            root.Visible=not root.Visible
        end)
        -- All common modules use identical AddTab and Add* controls.
        local common=createTab('低延迟切服',nil,'VORTEXION · COMMON')
        local serverFactory=config.ServerSwitchFactory or ServerSwitchFactory
        if type(serverFactory)=='function' then
            local ok,v=pcall(serverFactory,common,function(msg)bridge:Notify('低延迟切服',msg)end)
            if ok then bridge.ServerSwitch=v else bridge.LastError=tostring(v) end
        end
        local perf=createTab('性能诊断')
        if type(RuntimeMonitorFactory)=='function' then
            local ok,v=pcall(RuntimeMonitorFactory,perf,bridge)
            if ok then bridge.RuntimeMonitor=v else bridge.LastError=tostring(v) end
        end
        installSettings()
        bridge:RefreshDiagnostics()
        connections[#connections+1]=Workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(bindCamera)
        bindCamera()
        local ok,inset=pcall(function()return GuiService:GetPropertyChangedSignal('TopbarInset')end)
        if ok and inset then connections[#connections+1]=inset:Connect(function()lastViewport='';bridge:FitViewport()end) end
        return window
    end
    return bridge
end
