-- R229: last-resort Neverlose-compatible dual-column shell.
-- Only used if the uploaded UI library cannot construct its Window on an executor.
-- It does not replace the normal Neverlose interface when that interface works.
return function(library, cause)
    local Players = game:GetService('Players')
    local UIS = game:GetService('UserInputService')
    local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
    local background, sectionColor, textColor, accent = rgb(15,19,21),rgb(23,29,32),rgb(234,240,244),rgb(103,181,191)
    local function ui(kind,parent,name,size,position)
        local object=Instance.new(kind)
        object.Name=name or kind
        if size then object.Size=size end
        if position then object.Position=position end
        if parent then object.Parent=parent end
        return object
    end
    local function corner(object,r)
        local c=ui('UICorner',object,'Corners'); c.CornerRadius=UDim.new(0,r or 5)
    end
    local function text(parent,content,size,position,fontSize,color)
        local l=ui('TextLabel',parent,'Label',size,position)
        l.BackgroundTransparency=1; l.Text=tostring(content or '');l.TextColor3=color or textColor
        l.Font=Enum.Font.Gotham; l.TextSize=fontSize or 14
        l.TextXAlignment=Enum.TextXAlignment.Left;l.TextTruncate=Enum.TextTruncate.AtEnd
        return l
    end
    local screen=ui('ScreenGui',nil,'VortexionEmergencyNeverlose')
    screen.IgnoreGuiInset=true;screen.ResetOnSpawn=false;screen.DisplayOrder=200
    local targets={}
    if type(gethui)=='function' then local ok,hidden=pcall(gethui);if ok and hidden then targets[#targets+1]=hidden end end
    local ok,core=pcall(function()return game:GetService('CoreGui')end)
    if ok and core then targets[#targets+1]=core end
    local player=Players.LocalPlayer
    if player then
        local playerGui=player:FindFirstChildOfClass('PlayerGui') or player:WaitForChild('PlayerGui',5)
        if playerGui then targets[#targets+1]=playerGui end
    end
    local mounted=false
    for _,target in ipairs(targets) do
        local placed=pcall(function()screen.Parent=target end)
        if placed and screen.Parent==target then mounted=true;break end
    end
    assert(mounted,'Emergency Neverlose: unable to mount ScreenGui')
    local root=ui('Frame',screen,'MainFrame',UDim2.fromOffset(643,682))
    root.BackgroundColor3=background;root.BorderSizePixel=0;corner(root,6)
    local sidebar=ui('ScrollingFrame',root,'Sidebar',UDim2.fromOffset(203,682),UDim2.fromOffset(-203,0))
    sidebar.BackgroundColor3=sectionColor;sidebar.BorderSizePixel=0
    sidebar.ScrollBarThickness=3;sidebar.CanvasSize=UDim2.fromOffset(0,0);sidebar.AutomaticCanvasSize=Enum.AutomaticSize.Y
    local leftPadding=ui('UIPadding',sidebar,'Padding');leftPadding.PaddingTop=UDim.new(0,16)
    leftPadding.PaddingLeft=UDim.new(0,12);leftPadding.PaddingRight=UDim.new(0,12)
    local navLayout=ui('UIListLayout',sidebar,'NavLayout');navLayout.Padding=UDim.new(0,6)
    navLayout.SortOrder=Enum.SortOrder.LayoutOrder
    text(root,'VORTEXION · 兼容模式',UDim2.new(1,-32,0,38),UDim2.fromOffset(18,8),19,accent)
    local warning=text(root,'原生 UI 创建失败，已使用离线兼容界面',UDim2.new(1,-30,0,24),UDim2.fromOffset(18,43),12,rgb(208,183,130))
    local pages=ui('Frame',root,'Content',UDim2.new(1,-24,1,-87),UDim2.fromOffset(12,78))
    pages.BackgroundTransparency=1
    local activeTab=nil
    local function newButton(parent,label,width,height)
        local button=ui('TextButton',parent,label,width or UDim2.new(1,0,0,36))
        button.BackgroundColor3=rgb(39,49,54);button.TextColor3=textColor;button.BorderSizePixel=0
        button.Font=Enum.Font.GothamMedium;button.TextSize=13;button.Text=tostring(label)
        button.AutoButtonColor=true;corner(button,5);return button
    end
    local function select(page)
        if activeTab then activeTab.Frame.Visible=false;activeTab.Button.BackgroundColor3=rgb(39,49,54) end
        activeTab=page;page.Frame.Visible=true;page.Button.BackgroundColor3=rgb(43,86,99)
    end
    local groups={}
    function groups:TSection(label)
        local title=text(sidebar,label,UDim2.new(1,0,0,29),nil,12,accent)
        local group={}
        function group:Tab(label,icon)
            local button=newButton(sidebar,label)
            if type(icon)=='string' and icon~='' then
                local badge=ui('ImageLabel',button,'Icon',UDim2.fromOffset(16,16),UDim2.fromOffset(7,10))
                badge.BackgroundTransparency=1;badge.Image=icon;badge.ImageColor3=accent
                button.Text='    '..label
            end
            local pane=ui('Frame',pages,'Tab_'..tostring(label),UDim2.fromScale(1,1));pane.BackgroundTransparency=1;pane.Visible=false
            local holder={Frame=pane,Button=button,Sections={},Left=nil,Right=nil}
            button.MouseButton1Click:Connect(function()select(holder)end)
            if activeTab==nil then select(holder)end
            local function column(index)
                local x=(index==1) and 0 or 0.51
                local frame=ui('ScrollingFrame',pane,'Column'..index,UDim2.new(0.49,0,1,0),UDim2.new(x,0,0,0))
                frame.BackgroundTransparency=1;frame.ScrollBarThickness=3
                frame.CanvasSize=UDim2.fromOffset(0,0);frame.AutomaticCanvasSize=Enum.AutomaticSize.Y
                local layout=ui('UIListLayout',frame,'Layout');layout.Padding=UDim.new(0,9)
                layout.SortOrder=Enum.SortOrder.LayoutOrder
                return frame
            end
            function holder:Select()select(holder)end
            function holder:Section(title)
                local index=#self.Sections+1
                local target=((index%2)==1) and (self.Left or column(1)) or (self.Right or column(2))
                if index%2==1 then self.Left=target else self.Right=target end
                local panel=ui('Frame',target,'Section_'..title,UDim2.new(1,-8,0,45))
                panel.AutomaticSize=Enum.AutomaticSize.Y
                panel.BackgroundColor3=sectionColor;panel.BorderSizePixel=0;corner(panel,5)
                local pad=ui('UIPadding',panel,'Padding');pad.PaddingTop=UDim.new(0,10)
                pad.PaddingBottom=UDim.new(0,9);pad.PaddingLeft=UDim.new(0,11);pad.PaddingRight=UDim.new(0,11)
                local list=ui('UIListLayout',panel,'Layout');list.Padding=UDim.new(0,7)
                list.SortOrder=Enum.SortOrder.LayoutOrder
                text(panel,title,UDim2.new(1,0,0,21),nil,14,accent)
                local section={Panel=panel}
                local function row(label)
                    local f=ui('Frame',panel,'Row',UDim2.new(1,0,0,37));f.BackgroundTransparency=1
                    text(f,label,UDim2.new(.6,0,1,0),nil,13)
                    return f
                end
                function section:Toggle(label,callback)
                    local frame=row(label)
                    local button=newButton(frame,'关闭',UDim2.fromOffset(55,29))
                    button.AnchorPoint=Vector2.new(1,.5);button.Position=UDim2.new(1,0,.5,0)
                    local value=false;local control={}
                    function control:Set(v)
                        value=v==true;button.Text=value and '开启' or '关闭'
                        button.BackgroundColor3=value and accent or rgb(39,49,54)
                        if callback then callback(value) end
                    end
                    function control:Get()return value end
                    button.MouseButton1Click:Connect(function()control:Set(not value)end)
                    return control
                end
                function section:Slider(label,lo,hi,default,callback)
                    local frame=row(label)
                    local number=newButton(frame,tostring(default),UDim2.fromOffset(75,29))
                    number.AnchorPoint=Vector2.new(1,.5);number.Position=UDim2.new(1,0,.5,0)
                    local current=default;local control={}
                    function control:Set(v)
                        current=math.max(lo,math.min(hi,tonumber(v) or lo))
                        number.Text=tostring(math.floor(current*100+.5)/100)
                        if callback then callback(current) end
                    end
                    function control:Get()return current end
                    local function update(input)
                        local x=input.Position.X-number.AbsolutePosition.X
                        control:Set(lo+(hi-lo)*math.max(0,math.min(1,x/math.max(1,number.AbsoluteSize.X))))
                    end
                    number.InputBegan:Connect(function(input)
                        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then update(input)end
                    end)
                    number.InputChanged:Connect(function(input)
                        if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseMovement then update(input)end
                    end)
                    return control
                end
                function section:Dropdown(label,values,callback)
                    local frame=row(label)
                    local button=newButton(frame,'选择',UDim2.fromOffset(108,29))
                    button.AnchorPoint=Vector2.new(1,.5);button.Position=UDim2.new(1,0,.5,0)
                    local choices=values or {};local chosen=nil;local control={}
                    function control:Set(v)
                        chosen=v;button.Text=tostring(v or '无选项')
                        if callback then callback(v) end
                    end
                    function control:Get()return chosen end
                    function control:Refresh(nextList)choices=nextList or {};control:Set(choices[1])end
                    button.MouseButton1Click:Connect(function()
                        if #choices==0 then return end
                        local nextIdx=1
                        for i,v in ipairs(choices)do if v==chosen then nextIdx=i%#choices+1;break end end
                        control:Set(choices[nextIdx])
                    end)
                    return control
                end
                function section:TextBox(label,callback)
                    local frame=row(label)
                    local input=ui('TextBox',frame,'Input',UDim2.fromOffset(100,29))
                    input.AnchorPoint=Vector2.new(1,.5);input.Position=UDim2.new(1,0,.5,0)
                    input.BackgroundColor3=rgb(39,49,54);input.TextColor3=textColor
                    input.PlaceholderText='输入';input.Text='';input.TextSize=13;input.BorderSizePixel=0;corner(input,5)
                    local control={}
                    function control:Set(value)
                        input.Text=tostring(value or '');if callback then callback(input.Text)end
                    end
                    function control:Get()return input.Text end
                    input.FocusLost:Connect(function()if callback then callback(input.Text)end end)
                    return control
                end
                function section:Colorpicker(label,default,callback)
                    local frame=row(label)
                    local button=newButton(frame,'颜色',UDim2.fromOffset(66,29))
                    button.AnchorPoint=Vector2.new(1,.5);button.Position=UDim2.new(1,0,.5,0)
                    local colors={default or accent,rgb(103,181,191),rgb(255,83,83),rgb(42,42,42),rgb(255,255,255)}
                    local current=colors[1];local control={}
                    function control:Set(c)
                        current=c;button.BackgroundColor3=c
                        if callback then callback(c) end
                    end
                    function control:Get()return current end
                    button.MouseButton1Click:Connect(function()
                        local nextIndex=1
                        for i,c in ipairs(colors) do if c==current then nextIndex=i%#colors+1;break end end
                        control:Set(colors[nextIndex])
                    end)
                    return control
                end
                function section:Button(label,callback)
                    local b=newButton(panel,label)
                    b.MouseButton1Click:Connect(function()if callback then callback()end end)
                    return b
                end
                function section:Paragraph(label,description)
                    local f=ui('Frame',panel,'Paragraph',UDim2.new(1,0,0,66))
                    f.BackgroundTransparency=1
                    text(f,label,UDim2.new(1,0,0,20),nil,13,accent)
                    local desc=text(f,description,UDim2.new(1,0,0,45),UDim2.fromOffset(0,21),12)
                    desc.TextWrapped=true;desc.TextTruncate=Enum.TextTruncate.None
                    return {SetDesc=function(_,value)desc.Text=tostring(value) end}
                end
                self.Sections[index]=section
                return section
            end
            return holder
        end
        return group
    end
    library.Root=screen;library.MainFrame=root
    library.VisMain=function(_,visible)root.Visible=visible end
    library.Window=function()return groups end
    library.EmergencyReason=tostring(cause or 'Neverlose Window returned no handle'):sub(1,800)
    warning.Text='原生 UI 不可用，双列兼容模式已启动；查看启动诊断'
    return groups
end
