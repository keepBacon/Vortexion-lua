-- Lifecycle and UI shared by AOTR lobby and battle.
return function(scene, Starlight, Bridge)
    local Players=game:GetService("Players")
    local RunService=game:GetService("RunService")
    local Workspace=game:GetService("Workspace")
    local client=(getgenv and getgenv()) or _G
    if type(client.VortexionAOTRCleanup)=="function" then pcall(client.VortexionAOTRCleanup) end
    local app={scene=scene, connections={}, disposers={}, active=true, flags={}, player=Players.LocalPlayer}
    local function cleanup()
        if not app.active then return end
        app.active=false
        for _,con in ipairs(app.connections) do pcall(function() con:Disconnect() end) end
        for _,fn in ipairs(app.disposers) do pcall(fn) end
        if app.ui then pcall(function() app.ui:Destroy() end) end
    end
    client.VortexionAOTRCleanup=cleanup
    function app:Track(con) table.insert(self.connections,con);return con end
    function app:OnStop(fn) table.insert(self.disposers,fn) end
    function app:Alive() return self.active and client.VortexionAOTRCleanup==cleanup end
    function app:Notify(message)
        if self.ui and self:Alive() then self.ui:Notify({Title="AOTR",Content=message,Duration=3}) end
    end
    function app:Open()
        local ok,ui=pcall(function()
            return Bridge(Starlight,{Name="AOTR",Folder="VortexionAOTR",Section="A T T A C K  O N  T I T A N"})
        end)
        if not ok or not ui then warn("[AOTR] Starlight initialization failed: "..tostring(ui));cleanup();return end
        self.ui=ui
        local window=ui:CreateWindow({Title="AOTR"})
        pcall(function()
            local header=Starlight.Instance.MainWindow.Sidebar.Header
            header.Text="AOTR"
        end)
        return window
    end
    function app:Loop(id, interval, work)
        self.flags[id]=(self.flags[id] or 0)+1
        local generation=self.flags[id]
        task.spawn(function()
            while self:Alive() and self.flags[id]==generation do
                local started=os.clock()
                local ok,err=pcall(work)
                if not ok then warn("[AOTR/"..id.."] "..tostring(err)) end
                task.wait(math.max(0.1,interval-(os.clock()-started)))
            end
        end)
    end
    function app:StopLoop(id) self.flags[id]=(self.flags[id] or 0)+1 end
    function app:Character()
        local c=self.player and self.player.Character
        local hum=c and c:FindFirstChildOfClass("Humanoid")
        local root=c and c:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health>0 then return c,hum,root end
    end
    function app:Status(tab)
        tab:AddParagraph({Title="当前场景",Content=scene=="lobby" and "大厅 / 主菜单" or "战斗任务"})
        tab:AddParagraph({Title="脚本状态",Content="独立模块已启动。禁用功能不会保留后台循环；重新执行会清理旧监听。"})
    end
    return app
end
