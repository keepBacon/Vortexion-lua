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
        local ok,err=pcall(function() Neverlose:Notification({Title=title,Description=desc,Duration=seconds}) end)
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
        pcall(function() Neverlose:Unload() end)
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
            if item.Kind=="Toggle" and item.Native and type(item.Native.Get)=="function" then
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
        local ok,top,bottom=pcall(function() return GuiService:GetGuiInset() end)
        if not ok or not top or not bottom then return 0,0,0,0 end
        -- Inset returns top-left and bottom-right Vector2, both are pixel offsets.
        return clamp(finite(top.X,0),0,1000),clamp(finite(top.Y,0),0,1000),
               clamp(finite(bottom.X,0),0,1000),clamp(finite(bottom.Y,0),0,1000)
    end
    function bridge:FitViewport()
        if not self.Active or not root or not scale or not self.AutoFit then return end
        local cam=Workspace.CurrentCamera
        if not cam then return end
        local viewport=cam.ViewportSize
        local vx,vy=finite(viewport.X,0),finite(viewport.Y,0)
        -- Avoid Roblox errors when camera viewport temporarily becomes (0,0),
        -- NaN or infinity during rotation, app backgrounding or device resize.
        if vx<=0 or vy<=0 then self.LastViewport="等待有效视口";return end
        local l,t,r,b=readInsets()
        l,r=clamp(l,0,vx/3),clamp(r,0,vx/3)
        t,b=clamp(t,0,vy/3),clamp(b,0,vy/3)
        local width,height=math.max(1,vx-l-r),math.max(1,vy-t-b)
        if width<=32 or height<=80 then self.LastViewport="视口暂不可用";return end
        -- On portrait devices the Neverlose sidebar becomes compact and pages
        -- reflow to a single column. The reference window is intentionally fixed
        -- in logical pixels, with a single UIScale instance owned by this bridge.
        local aspect=width/height
        local menuWidth=mobile and (aspect < 0.86 and 460 or 655) or 677
        local menuHeight=mobile and (aspect < 0.86 and 630 or 560) or 644
        local sidebar=mobile and (aspect<0.86 and 112 or 158) or 225
        local baseW=menuWidth
        local baseH=menuHeight
        local fit=math.min((width-16)/baseW,(height-20)/baseH,1.15)
        local result=clamp(fit*uiScale,0.15,1.2)
        -- Never place part of the menu outside the usable area, even in split-screen.
        result=math.min(result,(width-8)/baseW,(height-8)/baseH)
        if result<=0 or finite(result,0)<=0 then return end
        local key=("%d:%d:%d:%d:%d:%d:%.3f:%d"):format(vx,vy,l,t,r,b,result,sidebar)
        if key==lastViewport then return end
        lastViewport=key
        local anchor=Vector2.new(0.5,0.5)
        root.AnchorPoint=anchor
        root.Size=UDim2.fromOffset(baseW,baseH)
        scale.Scale=result
        root.Position=UDim2.fromOffset(l+width/2,t+height/2)
        local elements=window.Native and window.Native.Items
        if elements then
            local sidebarFrame=elements.LeftTabs and elements.LeftTabs.Instance
            if sidebarFrame then
                sidebarFrame.AnchorPoint=Vector2.new(0,0)
                sidebarFrame.Position=UDim2.fromOffset(0,55)
                sidebarFrame.Size=UDim2.new(0,sidebar,1,-55)
                sidebarFrame.ScrollBarThickness=mobile and 4 or 3
            end
            local content=elements.Content and elements.Content.Instance
            if content then
                content.Position=UDim2.fromOffset(sidebar,55)
                content.Size=UDim2.new(1,-sidebar,1,-55)
            end
            for _,page in ipairs(window.Native.Pages) do
                local items=page.Items
                local btn=items and items.Inactive and items.Inactive.Instance
                if btn then btn.Size=UDim2.new(1,-4,0,mobile and 44 or 40) end
                local title=items and items.Text and items.Text.Instance
                if title then
                    title.Size=UDim2.new(1,-50,1,0)
                    title.TextTruncate=Enum.TextTruncate.AtEnd
                    title.TextSize=mobile and 13 or 14
                end
            end
        end
        -- Keep the mobile re-open handle below the OS safe area, not under its status bar.
        if mobile and elements and elements.FloatingButton and elements.FloatingButton.Instance then
            local floating=elements.FloatingButton.Instance
            if floating.Position.Y.Scale==0 and floating.Position.Y.Offset<=40 then
                floating.Position=UDim2.new(floating.Position.X.Scale,floating.Position.X.Offset,0,t+12)
            end
        end
        stats.resizes=stats.resizes+1
        self.EffectiveScale=result
        self.LastViewport=("%d×%d / UI %.2fx / 侧栏 %d"):format(vx,vy,result,sidebar)
    end
    local function bindCamera()
        if cameraConn then cameraConn:Disconnect(); cameraConn=nil end
        viewportCamera=Workspace.CurrentCamera
        if viewportCamera then
            cameraConn=viewportCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                bridge:FitViewport()
            end)
            connections[#connections+1]=cameraConn
        end
        bridge:FitViewport()
    end

    local function createTab(pageName,icon,category)
        if category and window.Native.Category then window.Native:Category(category) end
        local sourcePage=window.Native:Page({Name=pageName, Icon=icon or "122669828593160", Columns=mobile and 1 or 2})
        local tab={Native=sourcePage,Title=pageName,OptionCount=0,Sections={}}
        local function newSection()
            local index=#tab.Sections+1
            local side=mobile and 1 or (index%2==0 and 2 or 1)
            local section=sourcePage:Section({Name=index==1 and "功能" or ("功能 · "..index),Side=side})
            table.insert(tab.Sections,section)
            return section
        end
        local function sectionFor()
            if tab.OptionCount%14==0 then return newSection() end
            return tab.Sections[#tab.Sections] or newSection()
        end
        local function addOption(kind,id,c)
            c=c or {}; id=tostring(id)
            assert(bridge.Options[id]==nil,"重复选项 ID: "..id)
            local values=copy(c.Values or {})
            local low,high=finite(c.Min,0),finite(c.Max,100)
            local decimals=clamp(math.floor(finite(c.Rounding,0)),0,2)
            if kind=="Slider" then assert(low<high,"Slider Min must be < Max: "..id) end
            local step=10^(-decimals)
            local function normalize(v)
                if kind=="Toggle" then return v==true end
                if kind=="Input" then return tostring(v==nil and "" or v) end
                if kind=="Slider" then
                    local n=clamp(finite(v,low),low,high)
                    return clamp(math.floor(n/step+0.5)*step,low,high)
                end
                if kind=="Colorpicker" then return typeof(v)=="Color3" and v or Color3.fromRGB(0,195,255) end
                if c.Multi then return type(v)=="table" and copy(v) or (v==nil and {} or {v}) end
                if type(v)=="number" then v=values[v] end
                if v==nil then return values[1] end
                return v
            end
            local initial=normalize(c.Default)
            local option={ID=id,Kind=kind,Value=copy(initial),Values=values,listeners={}}
            bridge.Options[id]=option
            local ready=false
            local initialized=false
            local function propagate(value, origin)
                if not bridge.Active and not bridge.Cleaning then return false end
                value=normalize(value)
                if same(value,option.Value) and initialized then return false end
                initialized=true
                option.Value=copy(value)
                trace(id,origin,value,"received")
                local success=fire(c.Callback,copy(value))
                trace(id,origin,value,success and "OK" or "ERROR")
                for _,fn in ipairs(option.listeners) do fire(fn,copy(value)) end
                return true
            end
            local data={Name=tostring(c.Title or id),Flag=id,Default=copy(initial),Callback=function(v)
                if not ready then return end
                stats.inputs=stats.inputs+1
                propagate(v,"native")
            end}
            if kind=="Slider" then
                data.Min,data.Max,data.Decimals=low,high,step
                data.Suffix=c.Suffix or ""
            elseif kind=="Dropdown" then
                data.Items=values; data.Multi=c.Multi==true
                data.Size=mobile and 144 or 126
            elseif kind=="Input" then
                data.Placeholder=c.Placeholder or "请输入"
                data.Finished=true
            end
            tab.OptionCount=tab.OptionCount+1
            local section=sectionFor()
            if kind=="Input" then option.Native=section:Textbox(data)
            elseif kind=="Colorpicker" then
                option.Native=section:Label(data.Name):Colorpicker(data)
            else option.Native=section[kind](section,data) end
            -- Existing gameplay modules call GetValue() on Wind-compatible handles.
            function option:GetValue() return copy(self.Value) end
            function option:GetNativeValue()
                if not self.Native or type(self.Native.Get)~="function" then return self.Value end
                local ok,result=pcall(function() return self.Native:Get() end)
                return ok and normalize(result) or self.Value
            end
            function option:SyncFromNative()
                return propagate(self:GetNativeValue(),"audit")
            end
            function option:SetValue(v)
                if not bridge.Active and not bridge.Cleaning then return false end
                v=normalize(v)
                if same(v,self.Value) then return true end
                if bridge.Cleaning then return propagate(v,"cleanup") end
                local ok,err=pcall(function() self.Native:Set(copy(v)) end)
                if not ok then bridge.LastError=tostring(err); return false end
                -- Native:Set calls Callback synchronously. Guard duplicates and
                -- still emit when an executor's implementation omits callback.
                if same(self.Value,v) then return true end
                propagate(v,"setvalue")
                return true
            end
            function option:SetValues(new)
                if not bridge.Active or kind~="Dropdown" or type(new)~="table" then return false end
                local snapshot=copy(new)
                local ok,err=pcall(function()
                    -- Native :Refresh mutates Options asynchronously in some forks;
                    -- default to a valid value after refreshing.
                    self.Native:Refresh(snapshot)
                end)
                if not ok then bridge.LastError=tostring(err); return false end
                values=snapshot
                self.Values=copy(snapshot)
                if not c.Multi then
                    local exists=false
                    for _,item in ipairs(snapshot) do if item==self.Value then exists=true; break end end
                    if not exists then
                        if snapshot[1] then self:SetValue(snapshot[1])
                        else propagate(nil,"refresh-empty") end
                    end
                else
                    local allowed={}
                    for _,v in ipairs(snapshot) do allowed[v]=true end
                    local selected={}
                    if type(self.Value)=="table" then
                        for _,v in ipairs(self.Value) do if allowed[v] then selected[#selected+1]=v end end
                    end
                    if not same(selected,self.Value) then self:SetValue(selected) end
                end
                return true
            end
            function option:OnChanged(fn)
                if type(fn)=="function" then
                    table.insert(self.listeners,fn)
                    if bridge.Active then fire(fn,copy(self.Value)) end
                end
                return self
            end
            ready=true
            propagate(initial,"initial")
            return option
        end
        for _,kind in ipairs({"Toggle","Slider","Dropdown","Input","Colorpicker"}) do
            tab["Add"..kind]=function(_,id,c) return addOption(kind,id,c) end
        end
        function tab:AddButton(info)
            info=info or {}; self.OptionCount=self.OptionCount+1
            local section=sectionFor()
            return section:Button({Name=tostring(info.Title or "运行"),Callback=function()
                if bridge.Active and not info.Locked then fire(info.Callback) end
            end})
        end
        function tab:AddParagraph(info)
            info=info or {}; self.OptionCount=self.OptionCount+1
            local section=sectionFor()
            local label=section:Label(tostring(info.Title or "说明").."\n"..tostring(info.Content or info.Desc or ""))
            function label:SetDesc(text)
                self:SetText(tostring(info.Title or "说明").."\n"..tostring(text))
            end
            return label
        end
        table.insert(bridge.Tabs,tab)
        return tab
    end

    local function installSettings()
        window.Native:Category("VORTEXION · UI")
        local appearance=createTab("外观与布局","122669828593160")
        local diagnostics=createTab("UI 调试","122669828593160")
        local configuration=createTab("配置","122669828593160")
        bridge.SettingsTabs={['主题']=appearance,['界面']=appearance,['调试']=diagnostics,['配置']=configuration}
        appearance:AddParagraph({Title="Neverlose · Mobile",Content="移动端采用单列布局、自动屏幕适配、触控优先、关闭全窗口拖动。"})
        appearance:AddToggle("nl_auto_fit",{Title="根据屏幕尺寸自动适配",Default=true,Callback=function(v)
            bridge.AutoFit=v; lastViewport=""; bridge:FitViewport()
        end})
        appearance:AddToggle("nl_safe_area",{Title="遵守系统安全区域",Default=true,Callback=function(v)
            bridge.SafeArea=v; lastViewport=""; bridge:FitViewport()
        end})
        appearance:AddSlider("nl_scale",{Title="UI 尺寸百分比",Min=65,Max=120,Default=100,Rounding=0,Suffix="%",Callback=function(v)
            uiScale=v/100; lastViewport=""; bridge:FitViewport()
        end})
        appearance:AddDropdown("nl_accent",{Title="强调色",Values={"Neverlose 蓝","翡翠绿","灰白","琥珀"},Default="Neverlose 蓝",Callback=function(v)
            local colors={['Neverlose 蓝']={Color3.fromRGB(0,116,224),Color3.fromRGB(0,195,255)},['翡翠绿']={Color3.fromRGB(18,164,120),Color3.fromRGB(70,201,164)},['灰白']={Color3.fromRGB(170,178,192),Color3.fromRGB(212,217,225)},['琥珀']={Color3.fromRGB(214,142,32),Color3.fromRGB(244,192,83)}}
            local picked=colors[v]
            if picked then
                Neverlose:ChangeTheme("Accent",picked[1]); Neverlose:ChangeTheme("AccentGradient",picked[2])
            end
        end})
        appearance:AddToggle("nl_notifications",{Title="屏幕通知（触屏默认关闭）",Default=not mobile,Callback=function(v) bridge.NativeNoticesEnabled=v end})
        appearance:AddDropdown("nl_visual_perf",{Title="视觉更新档位",Values={"原速","均衡","省电"},Default=mobile and "均衡" or "原速",Callback=function(v)
            bridge.VisualHz=({["原速"]=60,["均衡"]=30,["省电"]=10})[v] or 30
        end})
        appearance:AddButton({Title="恢复默认窗口尺寸",Callback=function()
            bridge.Options.nl_scale:SetValue(100); bridge.Options.nl_auto_fit:SetValue(true)
            bridge.Options.nl_safe_area:SetValue(true); lastViewport=""; bridge:FitViewport()
        end})
        diagnostics:AddParagraph({Title="输入诊断",Content="点击下方开关检查真实触摸回调。该测试只证明 UI 回调收到事件，不代表服务器功能生效。"})
        local diagnosticLabel=diagnostics:AddParagraph({Title="实时状态",Content="正在检测触控与视口..."})
        local lastDiagnostics=""
        function bridge:RefreshDiagnostics()
            if not self.Active then return end
            local report=("输入设备: %s | 可见: %s\n视口: %s\n收到输入: %d | 回调执行: %d | 异常: %d | 状态修复: %d\n触控试验: %s\n最近控件: %s\n错误: %s")
                :format(self.TouchMode,tostring(window and window.Native and window.Native.IsOpen),self.LastViewport or "未知",stats.inputs,stats.callbacks,stats.errors,stats.repairs,self.LastTouchProbe or "未进行",recent[#recent] or "无",self.LastError or "无")
            if report~=lastDiagnostics then lastDiagnostics=report;diagnosticLabel:SetDesc(report) end
        end
        diagnostics:AddToggle("nl_touch_probe",{Title="触控事件计数测试",Default=false,Callback=function(v)
            bridge.LastTouchProbe="测试回调 "..tostring(v).." · "..tostring(stats.inputs)
            bridge:RefreshDiagnostics()
        end})
        diagnostics:AddToggle("nl_trace",{Title="跟踪控件回调",Default=false,Callback=function(v)bridge.Trace=v end})
        diagnostics:AddButton({Title="复核所有游戏开关状态",Callback=function()
            local n=bridge:ReconcileGameplayOptions()
            bridge:Notify({Title="状态复核",Content=("修复 %d 个本地状态\n%s"):format(n,bridge:FeatureHealth()),Duration=8})
        end})
        diagnostics:AddButton({Title="运行视口 / 触控自检",Callback=function()
            lastViewport=""; bridge:FitViewport()
            local str=("设备: %s\n窗口: %s\n事件: %d | 回调: %d | 修复: %d\n最近触控: %s\n错误: %s")
                :format(bridge.TouchMode,bridge.LastViewport or "未计算",stats.inputs,stats.callbacks,stats.repairs,bridge.LastTouchProbe or "无",bridge.LastError or "无")
            bridge.LastProbe=str
            bridge:RefreshDiagnostics()
            print("[Vortexion/Neverlose/UIProbe] "..str)
            bridge:Notify({Title="Neverlose 移动端检查",Content=str,Duration=10})
        end})
        diagnostics:AddButton({Title="打印最近 24 条控件记录",Callback=function()print(bridge:FeatureTrace()) end})
        diagnostics:AddButton({Title="打印所有游戏模块状态",Callback=function()print(bridge:FeatureHealth()) end})
        diagnostics:AddButton({Title="清除最近异常",Callback=function()bridge.LastError=nil end})
        bridge.GetDiagnostics=function()
            return ("Neverlose | %s | 当前页面 %s | %s | %d 控件 | %d 回调 | %d 次异常 | %d 次重排 | %s")
                :format(bridge.TouchMode,selectedPage,bridge.LastViewport or "未适配",(function()local n=0;for _ in pairs(bridge.Options)do n=n+1 end;return n end)(),stats.callbacks,stats.errors,stats.resizes,bridge.LastError or "无")
        end
        configuration:AddParagraph({Title="会话配置",Content="按 PlaceId 隔离；可选文件接口；仅手动保存或加载，不执行外部脚本。"})
        local folder="Vortexion/neverlose-"..tostring(game.PlaceId)
        local configName=configuration:AddInput("nl_config_name",{Title="配置名称",Default="default",Placeholder="字母、数字、下划线或横线"})
        local function filepath()
            local name=configName.Value:gsub("[^%w_%-]","")
            name=name:sub(1,40)
            if name=="" then name="default" end
            return folder.."/"..name..".json"
        end
        local function ensureDir()
            if type(isfolder)~="function" or type(makefolder)~="function" then return false end
            if not isfolder("Vortexion") then makefolder("Vortexion") end
            if not isfolder(folder) then makefolder(folder) end
            return true
        end
        configuration:AddButton({Title="保存选项配置",Callback=function()
            if type(writefile)~="function" or not ensureDir() then bridge:Notify("配置","执行器缺少文件接口");return end
            local data={schema=1,placeId=game.PlaceId,options={}}
            for id,opt in pairs(bridge.Options) do
                if id~="nl_config_name" and opt.Kind~="Colorpicker" then data.options[id]=copy(opt.Value) end
            end
            local ok,err=pcall(function()writefile(filepath(),HttpService:JSONEncode(data)) end)
            bridge:Notify("保存配置",ok and "保存成功" or tostring(err))
        end})
        configuration:AddButton({Title="读取选项配置",Callback=function()
            if type(readfile)~="function" or type(isfile)~="function" then bridge:Notify("配置","执行器缺少读取接口");return end
            local path=filepath()
            local ok,result=pcall(function()
                if not isfile(path) then error("配置文件不存在") end
                local raw=HttpService:JSONDecode(readfile(path))
                assert(type(raw)=="table" and raw.schema==1 and raw.placeId==game.PlaceId and type(raw.options)=="table","配置格式或游戏不匹配")
                local count=0
                for id,v in pairs(raw.options) do
                    local opt=bridge.Options[id]
                    if opt and opt.Kind~="Colorpicker" and opt:SetValue(v) then count=count+1 end
                end
                return count
            end)
            bridge:Notify("加载配置",ok and ("加载 "..result.." 项") or tostring(result))
        end})
    end

    function bridge:CreateWindow(info)
        if window then return window end
        if not self.Active then return nil end
        info=info or {}
        local deadline=os.clock()+6
        while not Workspace.CurrentCamera and self.Active and os.clock()<deadline do task.wait(0.05) end
        assert(Workspace.CurrentCamera,"Neverlose requires an active camera")
        local native=Neverlose:Window({Name=tostring(info.Title or config.Name or "Vortexion"),SubName="VORTEXION · NEVERLOSE",Logo="120959262762131"})
        root=native.Items.MainFrame.Instance
        -- One UIScale. Neverlose's original mobile fixed 0.7 scale was removed.
        scale=Instance.new("UIScale");scale.Name="VortexionViewportScale";scale.Scale=1;scale.Parent=root
        window={Native=native,Root=root,GameTabs=bridge.GameTabs}
        local gameCategoryInserted=false
        function window:AddTab(data)
            if not gameCategoryInserted then native:Category("VORTEXION · GAMES"); gameCategoryInserted=true end
            data=data or {}
            local tab=createTab(tostring(data.Title or "功能"),nil)
            bridge.GameTabs[#bridge.GameTabs+1]=tab
            lastViewport=""; bridge:FitViewport()
            return tab
        end
        local selectRevision=0
        function window:SelectTab(i)
            local tab=bridge.GameTabs[i]
            if not bridge.Active or not tab then return end
            selectedPage=tab.Title
            selectRevision=selectRevision+1
            local revision=selectRevision
            local function apply()
                if not bridge.Active or selectRevision~=revision then return end
                for _,page in ipairs(native.Pages) do
                    local shouldOpen=page==tab.Native
                    if page.Active~=shouldOpen then page:Turn(shouldOpen) end
                end
            end
            apply()
            -- Neverlose's first page is still fading when a game initializes.
            -- Reconcile once after the vendor debounce to avoid stacked pages.
            task.delay(0.8,apply)
        end
        function window:Minimize() native:SetOpen(false) end
        function window:Destroy() bridge:Destroy() end
        function window:InstallSettings() end
        native:Category("VORTEXION · GENERAL")
        local common=createTab("低延迟切服")
        local serverFactory=config.ServerSwitchFactory or ServerSwitchFactory
        if type(serverFactory)=="function" then
            local ok,result=pcall(serverFactory,common,function(msg)bridge:Notify("低延迟切服",msg)end)
            if ok then bridge.ServerSwitch=result else bridge.LastError="ServerSwitch: "..tostring(result) end
        else common:AddParagraph({Title="切服模块不可用",Content="请检查构建文件"}) end
        local perf=createTab("性能诊断")
        if type(RuntimeMonitorFactory)=="function" then
            local ok,result=pcall(RuntimeMonitorFactory,perf,bridge)
            if ok then bridge.RuntimeMonitor=result else bridge.LastError="RuntimeMonitor: "..tostring(result) end
        end
        installSettings()
        bridge:RefreshDiagnostics()
        connections[#connections+1]=Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
        bindCamera()
        task.defer(function() if bridge.Active and native then pcall(function() native:Init() end) end end)
        -- Official topbar inset changes without viewport changes (mobile safe area).
        local ok,insetSignal=pcall(function()return GuiService:GetPropertyChangedSignal("TopbarInset") end)
        if ok and insetSignal then
            connections[#connections+1]=insetSignal:Connect(function()lastViewport="";bridge:FitViewport() end)
        end
        return window
    end
    return bridge
end
