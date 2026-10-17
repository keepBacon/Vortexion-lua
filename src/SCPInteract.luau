-- R226 instant prompt: event-driven HoldDuration=0, never spam remote calls.
-- Server validation, range and authorization are not bypassed.
return function(common)
    local promptService=game:GetService("ProximityPromptService")
    local Interact={Config={Enabled=false},Stats={Modified=0,Triggered=0,Visible=0}}
    local originals={}
    local shown={}
    local conns={}
    local function modify(prompt)
        if not prompt or not prompt.Parent or not prompt:IsA("ProximityPrompt") then return end
        if originals[prompt]==nil then originals[prompt]=prompt.HoldDuration end
        local ok=pcall(function()prompt.HoldDuration=0 end)
        if ok then Interact.Stats.Modified+=1 end
    end
    local function restore(prompt)
        local orig=originals[prompt]
        if orig~=nil then
            pcall(function()if prompt.Parent then prompt.HoldDuration=orig end end)
            originals[prompt]=nil
        end
    end
    function Interact:SetEnabled(value)
        self.Config.Enabled=value==true
        for prompt in pairs(shown) do
            if self.Config.Enabled then modify(prompt) else restore(prompt) end
        end
    end
    conns[#conns+1]=promptService.PromptShown:Connect(function(prompt)
        shown[prompt]=true
        if Interact.Config.Enabled then modify(prompt) end
        local count=0 for _ in pairs(shown) do count+=1 end
        Interact.Stats.Visible=count
    end)
    conns[#conns+1]=promptService.PromptHidden:Connect(function(prompt)
        shown[prompt]=nil
        restore(prompt)
        local count=0 for _ in pairs(shown) do count+=1 end
        Interact.Stats.Visible=count
    end)
    conns[#conns+1]=promptService.PromptTriggered:Connect(function()
        if Interact.Config.Enabled then Interact.Stats.Triggered+=1 end
    end)
    function Interact:Cleanup()
        for _,conn in ipairs(conns) do pcall(function()conn:Disconnect()end) end
        for prompt in pairs(originals) do restore(prompt) end
        table.clear(shown)
    end
    common.OnCleanup(function()Interact:Cleanup()end)
    return Interact
end
