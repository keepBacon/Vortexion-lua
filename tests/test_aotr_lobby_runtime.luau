local function signal()
    local s={listeners={}}
    function s:Connect(fn)
        local c={Connected=true}
        function c:Disconnect() self.Connected=false end
        table.insert(self.listeners,{fn=fn,connection=c})
        return c
    end
    function s:Fire(...)
        for _,h in ipairs(self.listeners) do if h.connection.Connected then h.fn(...) end end
    end
    return s
end

local cameraSignal=signal()
local cameraOne={FieldOfView=70}
local cameraTwo={FieldOfView=90}
workspace={CurrentCamera=cameraOne,GetPropertyChangedSignal=function(_,name) assert(name=="CurrentCamera") return cameraSignal end}
game={PlaceId=14916516914}

local app={active=true,player={},connections={},disposers={},options={},notifications={},buttons={}}
function app:Alive() return self.active end
function app.player:GetAttribute() return nil end
function app:Open()
    local window={} 
    function window:AddTab()
        local tab={}
        function tab:AddButton(cfg) app.buttons[cfg.Title]=cfg end
        function tab:AddParagraph() end
        function tab:AddSlider(id,config) app.options[id]=config end
        function tab:AddToggle(id,config) app.options[id]=config end
        return tab
    end
    function window:InstallSettings() end
    function window:SelectTab() end
    self.owner=app
    app.ui=window
    return window
end
function app:Status() end
function app:Notify(message) table.insert(self.notifications,message) end
function app.ProbeHUD() end
app.HUD={blades="3/5",spears="1/2"}
function app.ReadCount(label)
    if type(label)~="string" then return nil end
    local have,max=label:match("(%d+)/(%d+)")
    if have then return tonumber(have),tonumber(max) end
    return nil
end
function app:Character() return nil end
function app:Track(connection) table.insert(self.connections,connection) return connection end
function app:OnStop(fn) table.insert(self.disposers,fn) return fn end
function app:Cleanup()
    self.active=false
    for _,connection in ipairs(self.connections) do connection:Disconnect() end
    for _,fn in ipairs(self.disposers) do fn() end
end
AOTRCommon=function() return app end
WindUI={} 
WindBridgeFactory=function() end
local entry=__FACTORY__

assert(app.options.AOTRLobbyFovEnabled,"lobby FOV toggle registered")
assert(app.options.AOTRLobbyFov,"lobby FOV slider registered")
app.options.AOTRLobbyFovEnabled.Callback(true)
app.options.AOTRLobbyFov.Callback(105)
assert(cameraOne.FieldOfView==105,"initial camera receives FOV")
workspace.CurrentCamera=cameraTwo
cameraSignal:Fire()
assert(cameraTwo.FieldOfView==105,"replacement camera receives FOV")
app.options.AOTRLobbyFovEnabled.Callback(false)
assert(cameraTwo.FieldOfView==90,"disabling restores replacement camera baseline")
app.buttons["查看刀片/雷枪余量"].Callback()
local joined=table.concat(app.notifications," ")
assert(string.find(joined,"刀片",1,true) and string.find(joined,"雷枪",1,true),"HUD button notifies blades and spears")
assert(string.find(joined,"3/5",1,true) and string.find(joined,"1/2",1,true),"HUD button reports parsed counts")
print("PASS AOTR lobby HUD readout")
app:Cleanup()
assert(cameraOne.FieldOfView==70,"cleanup restores original camera")
assert(cameraTwo.FieldOfView==90,"cleanup restores replacement camera")
for _,connection in ipairs(app.connections) do assert(not connection.Connected,"cleanup disconnects camera listener") end
print("PASS AOTR lobby camera lifecycle")
