-- Vortexion - Forsaken · 战斗组模块 (Combat Group)
-- 借鉴来源: Forsaken-Script-main (Auto-Backstab V1-V3 / Auto-Slash / Chance-Aimbot V1-V2)
-- 共性修法落地: getconnections type 门 / 状态恢复 ~= nil / 零向量 Unit 门 / 协程体 pcall
return function(ctx)
	local Players = ctx.Players
	local LocalPlayer = ctx.LocalPlayer
	local RunService = ctx.RunService
	local Workspace = ctx.Workspace
	local track = ctx.track
	local Fluent = ctx.Fluent
	local Tabs = ctx.Tabs

	local function notify(title, content)
		if Fluent then
			pcall(function()
				Fluent:Notify({ Title = title, Content = content, Duration = 5 })
			end)
		end
	end

	-- 安全取角色部件: 每轮从 LocalPlayer.Character 重取, 不用启动期捕获的引用
	-- (附件 Backstab-V1:414-421 的 cooldown 永锁正是 stale 引用导致 behind 恒真)
	local function getAliveHRP()
		local char = LocalPlayer and LocalPlayer.Character
		if not char or not char.Parent then return nil end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then return nil end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") and hrp.Parent then return hrp end
		return nil
	end

	-- 零向量安全单位向量: 附件 Chance-V1:126-128 / V2:561 重合时 .Unit 抛 NaN
	local function safeUnit(delta, fallback)
		if delta.Magnitude < 0.01 then return fallback end
		return delta.Unit
	end

	-- 点积朝向判定: 附件 Backstab-V3:465/:493 behind 判定
	local function isBehindTarget(myHRP, targetHRP)
		if not (myHRP and targetHRP) then return false end
		local delta = targetHRP.Position - myHRP.Position
		local mag = delta.Magnitude
		if mag < 0.01 then return false end
		local dir = delta / mag
		local facing = targetHRP.CFrame.LookVector
		return dir:Dot(facing) > 0.25
	end

	-- getconnections 一律先 type 门 (附件 4 文件 5 处 P0 共性)
	local function safeFireButton(btn)
		if not btn or type(getconnections) ~= "function" then return false end
		for _, signal in ipairs({btn.Activated, btn.MouseButton1Click}) do
			local ok, conns = pcall(getconnections, signal)
			local fired = false
			if ok and type(conns) == "table" then
				for _, c in ipairs(conns) do
					if pcall(function() c:Fire() end) then fired = true end
				end
			end
			if fired then return true end
		end
		return false
	end

	-- 能力就绪双形态读取: 附件 Auto-Slash:243-256 (NumberValue / BoolValue)
	local function readAbilityReady(folder, abilityName)
		if not folder then return false end
		local v = folder:FindFirstChild(abilityName, true)
		if not v then return false end
		if v:IsA("BoolValue") then return v.Value end
		if v:IsA("NumberValue") then return v.Value > 0 end
		if v:IsA("StringValue") then
			local ok, n = pcall(tonumber, v.Value)
			return ok and n and n > 0 or false
		end
		if v:IsA("TextLabel") then
			local ok, n = pcall(tonumber, v.Text)
			return ok and n and n > 0 or false
		end
		return false
	end

	local clock = ctx.clock or os.clock
	local destroyed = false
	local backstabRange = 12
	local backstabConn = nil
	local backstabEnabled = false
	local abilityButton, cooldownReady

	local function stopBackstab()
		backstabEnabled = false
		if backstabConn then
			pcall(function() backstabConn:Disconnect() end)
			backstabConn = nil
		end
	end

	-- 单协程 + os.clock 超时 + 每轮刷新引用 (修 Backstab-V1:414-421 永久空转)
	local function startBackstab(range)
		stopBackstab()
		if destroyed then return end
		backstabRange = math.clamp(tonumber(range) or backstabRange, 2, 25)
		backstabEnabled = true
		local nextAt = -math.huge
		backstabConn = RunService.Heartbeat:Connect(function()
			if not backstabEnabled or clock() < nextAt then return end
			nextAt = clock() + 0.15
			local hrp = getAliveHRP()
			local folder = Workspace:FindFirstChild("Players")
			local killers = folder and folder:FindFirstChild("Killers")
			if not (hrp and killers) then return end
			for _, model in ipairs(killers:GetChildren()) do
				local root = model:FindFirstChild("HumanoidRootPart")
				local hum = model:FindFirstChildOfClass("Humanoid")
				if root and root:IsA("BasePart") and hum and hum.Health > 0
					and (root.Position - hrp.Position).Magnitude <= backstabRange and isBehindTarget(hrp, root) then
					local dagger = abilityButton("Dagger")
					if not _G.VortexionAbilityReady or cooldownReady(dagger and dagger:FindFirstChild("CooldownTime")) then
						safeFireButton(dagger or LocalPlayer.PlayerGui:FindFirstChild("BackstabButton", true))
					end
					break
				end
			end
		end)
		track(backstabConn)
	end

	-- Bind snapshots to each Humanoid and preserve original zero/false values.
	local aimSaved = {}
	local function aimStateSave(hum)
		if hum and not aimSaved[hum] then
			aimSaved[hum] = { WalkSpeed = hum.WalkSpeed, JumpPower = hum.JumpPower, AutoRotate = hum.AutoRotate }
		end
	end
	local function aimStateRestore(hum)
		local saved = hum and aimSaved[hum]
		if not saved then return end
		for key, value in pairs(saved) do pcall(function() hum[key] = value end) end
		aimSaved[hum] = nil
	end

	abilityButton = function(name)
		local gui = LocalPlayer:FindFirstChild("PlayerGui")
		local main = gui and gui:FindFirstChild("MainUI")
		local container = main and main:FindFirstChild("AbilityContainer")
		return container and container:FindFirstChild(name)
	end
	cooldownReady = function(value)
		if not value then return false end
		if value:IsA("BoolValue") then return value.Value == true end
		if value:IsA("NumberValue") or value:IsA("IntValue") then return value.Value <= 0 end
		if value:IsA("TextLabel") then
			local text = value.Text:match("^%s*(.-)%s*$")
			return text == "" or (tonumber(text) ~= nil and tonumber(text) <= 0)
		end
		return false
	end
	local function pressQ()
		local ok = pcall(function()
			local vim = game:GetService("VirtualInputManager")
			vim:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
			vim:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
		end)
		return ok
	end

	-- Bounded selection; folders are looked up again after round/character replacement.
	local settings = {Range = 80, Health = 60, Smoothness = 8, WallCheck = true, HoldMode = false}
	local held, heldInput = false, nil
	local modes = {Aim = false, Elliot = false, Slash = false}
	local assistConn, assistTarget = nil, nil
	local nextScan, nextAction = -math.huge, -math.huge
	local inputs = {}
	local function visible(root)
		if not settings.WallCheck then return true end
		local camera = Workspace.CurrentCamera
		if not camera then return false end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {LocalPlayer.Character}
		local hit = Workspace:Raycast(camera.CFrame.Position, root.Position - camera.CFrame.Position, params)
		return not hit or hit.Instance:IsDescendantOf(root.Parent)
	end
	local function selectTarget(injured)
		local me = getAliveHRP()
		local folder = Workspace:FindFirstChild("Players")
		local group = folder and folder:FindFirstChild(injured and "Survivors" or "Killers")
		if not (me and group) then return nil end
		local best, distance = nil, settings.Range
		for _, model in ipairs(group:GetChildren()) do
			local hum, root = model:FindFirstChildOfClass("Humanoid"), model:FindFirstChild("HumanoidRootPart")
			if model ~= LocalPlayer.Character and hum and hum.Health > 0 and root and root:IsA("BasePart")
				and (not injured or hum.Health < settings.Health) then
				local d = (root.Position - me.Position).Magnitude
				if d < distance and visible(root) then best, distance = root, d end
			end
		end
		return best
	end
	local function stopAssist()
		if assistConn then assistConn:Disconnect(); assistConn = nil end
		assistTarget = nil
	end
	local function setAssist(mode, state)
		if destroyed or modes[mode] == nil then return end
		modes[mode] = state == true
		stopAssist()
		nextScan = -math.huge
		if not (modes.Aim or modes.Elliot or modes.Slash) then return end
		assistConn = RunService.Heartbeat:Connect(function(dt)
			if ctx.UserInputService and ctx.UserInputService:GetFocusedTextBox() then assistTarget = nil; return end
			if settings.HoldMode and not held then assistTarget = nil; return end
			local char, camera = LocalPlayer.Character, Workspace.CurrentCamera
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if not hum or hum.Health <= 0 or not camera then assistTarget = nil; return end
			if clock() >= nextScan then
				nextScan = clock() + 0.2
				assistTarget = selectTarget(modes.Elliot)
			end
			local target = assistTarget
			local targetHum = target and target.Parent and target.Parent:FindFirstChildOfClass("Humanoid")
			local me = getAliveHRP()
			if not (targetHum and targetHum.Health > 0 and me) then return end
			if (target.Position - me.Position).Magnitude > settings.Range then return end
			if modes.Aim or modes.Elliot then
				local pos = camera.CFrame.Position
				if (target.Position - pos).Magnitude > 0.01 then
					camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(pos, target.Position), 1 - math.exp(-settings.Smoothness * math.clamp(dt or 0.016, 0, 0.1)))
				end
			end
			if modes.Slash and not modes.Elliot and clock() >= nextAction
				and (target.Position - me.Position).Magnitude <= 12 and cooldownReady(char:FindFirstChild("QCooldown", true)) then
				nextAction = clock() + 0.4
				pressQ()
			end
		end)
		track(assistConn)
	end
	local function setHeld(state) held = state == true; if not held then assistTarget = nil end end
	local UIS = ctx.UserInputService
	if UIS then
		inputs[1] = UIS.InputBegan:Connect(function(input, processed)
			if processed or UIS:GetFocusedTextBox() then return end
			if input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.LeftAlt then
				heldInput = input; setHeld(true)
			end
		end)
		inputs[2] = UIS.InputEnded:Connect(function(input)
			if input == heldInput then heldInput = nil; setHeld(false) end
		end)
		inputs[3] = UIS.WindowFocusReleased:Connect(function() heldInput = nil; setHeld(false) end)
		for _, conn in ipairs(inputs) do track(conn) end
	end
	local function destroy()
		if destroyed then return end
		destroyed = true
		stopBackstab(); stopAssist(); setHeld(false)
		for hum in pairs(aimSaved) do aimStateRestore(hum) end
		for _, conn in ipairs(inputs) do conn:Disconnect() end
	end

	---------------------------------------------------------------------------
	-- UI: 战斗增强 (挂 Player tab)
	---------------------------------------------------------------------------
	if Tabs and Tabs.Combat then
		Tabs.Combat:AddToggle("CombatAutoBackstab", {
			Title = "自动背刺（朝向判定 + 超时保护）",
			Default = false,
			Callback = function(state)
				if state then
					startBackstab(backstabRange)
					notify("自动背刺", "已开启，需在杀手背后 12 studs 内")
				else
					stopBackstab()
				end
			end
		})

		Tabs.Combat:AddToggle("CombatAbilityReady", {
			Title = "能力就绪双形态检测",
			Default = false,
			Callback = function(state)
				_G.VortexionAbilityReady = state or nil
			end
		})

		Tabs.Combat:AddButton({
			Title = "安全触发近战按钮",
			Callback = function()
				safeFireButton(LocalPlayer.PlayerGui:FindFirstChild("AttackButton", true))
				notify("近战", "已尝试触发（找不到按钮时静默跳过）")
			end
		})
	end

	---------------------------------------------------------------------------
	-- UI: 战斗增强 (挂 GuestSettings tab)
	---------------------------------------------------------------------------
	if Tabs and Tabs.Combat then
		Tabs.Combat:AddToggle("CombatAimStateGuard", {
			Title = "瞄准状态安全恢复（WalkSpeed=0 兼容）",
			Default = true,
			Callback = function(state)
				_G.VortexionAimStateGuard = state or nil
			end
		})
	end

	if Tabs and Tabs.Combat then
		local tab = Tabs.Combat
		tab:AddSlider("CombatBackstabRange", {Title = "背刺范围", Default = 12, Min = 2, Max = 25, Rounding = 1, Callback = function(v) backstabRange = v end})
		tab:AddToggle("CombatProximityAim", {Title = "最近杀手辅助瞄准", Default = false, Callback = function(v) setAssist("Aim", v) end})
		tab:AddToggle("CombatElliotAssist", {Title = "Elliot 受伤队友瞄准（手动投掷）", Default = false, Callback = function(v) setAssist("Elliot", v) end})
		tab:AddToggle("CombatAutoSlash", {Title = "自动 Slash（Q 冷却就绪 / 12 studs）", Default = false, Callback = function(v) setAssist("Slash", v) end})
		tab:AddToggle("CombatHoldMode", {Title = "持有模式（右键 / Alt；触屏用下方开关）", Default = false, Callback = function(v) settings.HoldMode = v; setHeld(false) end})
		tab:AddToggle("CombatTouchHeld", {Title = "触屏：按下 / 松开瞄准", Default = false, Callback = setHeld})
		tab:AddToggle("CombatWallCheck", {Title = "目标视线检测", Default = true, Callback = function(v) settings.WallCheck = v end})
		tab:AddSlider("CombatAssistRange", {Title = "辅助范围", Default = 80, Min = 10, Max = 300, Rounding = 0, Callback = function(v) settings.Range = v; nextScan = -math.huge end})
		tab:AddSlider("CombatElliotHealth", {Title = "队友生命阈值", Default = 60, Min = 1, Max = 100, Rounding = 0, Callback = function(v) settings.Health = v; nextScan = -math.huge end})
		tab:AddSlider("CombatAimSmoothness", {Title = "瞄准响应速度（每秒）", Default = 8, Min = 1, Max = 30, Rounding = 1, Callback = function(v) settings.Smoothness = v end})
	end

	return {
		Destroy = destroy,
		startBackstab = startBackstab,
		setAssist = setAssist,
		setHeld = setHeld,
		selectTarget = selectTarget,
		cooldownReady = cooldownReady,
		isBehindTarget = isBehindTarget,
		safeUnit = safeUnit,
		readAbilityReady = readAbilityReady,
		safeFireButton = safeFireButton,
		aimStateSave = aimStateSave,
		aimStateRestore = aimStateRestore,
		stopBackstab = stopBackstab,
	}
end
