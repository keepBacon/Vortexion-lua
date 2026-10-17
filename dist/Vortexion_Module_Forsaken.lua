-- Vortexion WindUI - generated offline; publishing must be performed separately.
-- WindUI attribution and license are retained in vendor/WindUI/.
-- Forsaken retains runtime model rbxassetid://132866968194043.
-- Modify src/*.luau and run python3 build.py; do not edit this output.
return function(kernel)
assert(type(kernel) == 'table' and type(kernel.WindBridgeFactory) == 'function', 'Invalid Vortexion core')
local WindUI, WindBridgeFactory, GameRouter = kernel.WindUI, kernel.WindBridgeFactory, kernel.GameRouter
local entry = function()
local ForsakenCombatFactory = (function()
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

end)()
local ForsakenVisualFactory = (function()
-- Forsaken visual utilities. Existing ESP renderers remain in ForsakenCore.
return function(ctx)
	local LocalPlayer, RunService, Workspace = ctx.LocalPlayer, ctx.RunService, ctx.Workspace
	local Tabs, Fluent, track = ctx.Tabs, ctx.Fluent, ctx.track
	local Lighting = game:GetService("Lighting")
	local clock = ctx.clock or os.clock
	local destroyed, connection = false, nil
	local state = {Fullbright = false, Fog = false, Effects = false, Marker = false, Performance = false, Life12 = false, Extras = false, Highlight = false, Skin = false, Scale = false, Resources = false}
	local baseline, effects, objects = nil, {}, {}
	local nextLighting, nextMarker, nextReport, nextAppearance = -math.huge, -math.huge, -math.huge, -math.huge
	local frameCount, frameTime, fps, markerRange = 0, 0, 0, 40
	local performanceRow
	local lightingProps = {"Brightness", "Ambient", "OutdoorAmbient", "GlobalShadows", "ClockTime", "GeographicLatitude", "FogEnd", "FogStart", "ExposureCompensation"}
	-- 本地外观：默认关闭，能力缺失按 key 降级，关闭/销毁/角色切换即时恢复
	local APPEARANCE_INTERVAL = 0.1
	local APPEARANCE_LABELS = {Life12 = "Life1 / Life2 隐藏", Extras = "ExtraModels 隐藏", Highlight = "Highlight 透明度调节", Skin = "本地皮肤应用", Scale = "本地角色缩放", Resources = "角色资源方案"}
	local highlightFill, skinName, scaleValue, scaleBase = 0.5, "", 1.06, 1
	local restoreOriginalScale = true
	local appearanceChar, skinClone, respawnConnection = nil, nil, nil
	-- 外观快照按对象弱引用：角色销毁后条目自动回收，恢复只写原值。
	local appearanceSaved = setmetatable({}, {__mode = "k"})
	-- 每个角色的初始缩放（真实 Model:GetScale），切换时先恢复旧角色。
	local appearanceScaleSaved = setmetatable({}, {__mode = "k"})
	local degraded = {}
	local appearanceTicks = 0
	local ensureLoop
	local function isLocalCharacter(inst)
		local char = LocalPlayer and LocalPlayer.Character
		return inst ~= nil and char ~= nil and (inst == char or inst:IsDescendantOf(char))
	end
	local function findOrCreateByModel(parent, model, className, namePrefix)
		if not (parent and model) or destroyed then return nil end
		-- FindFirstChild 与 IsA 一并纳入 pcall：异常直接返回 nil，不进入分配
		local ok, existing, matches = pcall(function()
			local found = model:FindFirstChild(namePrefix)
			if not found then return nil, false end
			return found, found:IsA(className)
		end)
		if not ok then return nil end
		if matches and existing then return existing end
		local inst
		local ok = pcall(function()
			inst = Instance.new(className)
			inst.Name, inst.Parent = namePrefix, model
		end)
		if not ok or destroyed then
			if inst then pcall(function() inst:Destroy() end) end
			return nil
		end
		objects[inst] = math.huge
		ensureLoop()
		return inst
	end
	local function clearMarkers()
		for inst in pairs(objects) do
			objects[inst] = nil
			pcall(function() inst:Destroy() end)
		end
	end
	local function restoreBaseline()
		if baseline then
			for key, value in pairs(baseline) do pcall(function() Lighting[key] = value end) end
		end
	end
	local function restoreEffects()
		for effect, enabled in pairs(effects) do pcall(function() effect.Enabled = enabled end) end
		table.clear(effects)
	end
	local function syncLighting()
		if state.Fullbright or state.Fog then
			if not baseline then
				baseline = {}
				for _, key in ipairs(lightingProps) do baseline[key] = Lighting[key] end
			end
			restoreBaseline()
			if state.Fullbright then
				Lighting.Brightness = 3
				Lighting.Ambient, Lighting.OutdoorAmbient = Color3.new(1, 1, 1), Color3.new(1, 1, 1)
				Lighting.GlobalShadows = false
			end
			Lighting.FogStart, Lighting.FogEnd = 0, 1e6
		else
			restoreBaseline(); baseline = nil
		end
		if not state.Effects then restoreEffects(); return end
		local camera = Workspace.CurrentCamera
		for effect, enabled in pairs(effects) do
			if effect.Parent ~= Lighting and effect.Parent ~= camera then
				pcall(function() effect.Enabled = enabled end); effects[effect] = nil
			end
		end
		local parents = {Lighting}
		if camera then table.insert(parents, camera) end
		for _, parent in ipairs(parents) do
			for _, effect in ipairs(parent:GetChildren()) do
				if effect:IsA("PostEffect") then
					if effects[effect] == nil then effects[effect] = effect.Enabled end
					effect.Enabled = false
				end
			end
		end
	end
	-- 非关键视觉节拍接入共享桥接；桥接缺失或结果不可用时保留原有间隔。
	-- 与其余三路同一契约：拒绝 inf/nan/非正数，取 max(base, bridged)。
	local function visualInterval(baseSeconds)
		local ok, bridged = pcall(function()
			if Fluent and type(Fluent.GetVisualInterval) == "function" then
				return Fluent:GetVisualInterval(baseSeconds)
			end
			return nil
		end)
		if ok and type(bridged) == "number" and bridged == bridged
			and bridged ~= math.huge and bridged ~= -math.huge and bridged > 0
			and bridged >= baseSeconds then
			return bridged
		end
		return baseSeconds
	end
	local function character()
		return LocalPlayer and LocalPlayer.Character or nil
	end
	local function descendants(root)
		local out = {}
		local function walk(inst)
			for _, child in ipairs(inst:GetChildren()) do
				table.insert(out, child)
				walk(child)
			end
		end
		walk(root)
		return out
	end
	local function notifyDegraded(key)
		pcall(function()
			if Fluent and type(Fluent.Notify) == "function" then
				Fluent:Notify({Title = "Forsaken 本地外观", Content = (APPEARANCE_LABELS[key] or key) .. "：本地资源缺失，本次会话降级跳过", Duration = 4})
			end
		end)
	end
	-- Life1 / Life2：隐藏全部 BasePart，保存并恢复原 Transparency
	local function hideLifeModels(char)
		if not char then return false end
		local worked = false
		for _, modelName in ipairs({"Life1", "Life2"}) do
			local model = char:FindFirstChild(modelName)
			if model then
				for _, part in ipairs(descendants(model)) do
					if part:IsA("BasePart") then
						if appearanceSaved[part] == nil then appearanceSaved[part] = part.Transparency end
						part.Transparency = 1
						worked = true
					end
				end
			end
		end
		return worked
	end
	local function restoreLifeModels()
		for part, transparency in pairs(appearanceSaved) do
			if part:IsA("BasePart") then
				pcall(function() part.Transparency = transparency end)
			end
		end
		for key in pairs(appearanceSaved) do
			if key:IsA("BasePart") then appearanceSaved[key] = nil end
		end
	end
	-- ExtraModels：整模型脱离角色，恢复原父级
	local function hideExtras(char)
		if not char then return false end
		local model = char:FindFirstChild("ExtraModels")
		if not model then return false end
		if model.Parent == nil then return true end
		appearanceSaved[model] = model.Parent
		model.Parent = nil
		return true
	end
	local function restoreExtras()
		for object, parent in pairs(appearanceSaved) do
			local ok, matches = pcall(function() return object:IsA("Model") end)
			if ok and matches then
				appearanceSaved[object] = nil
				pcall(function() object.Parent = parent end)
			end
		end
	end
	local function applyHighlight(char)
		if not char then return false end
		local highlight = char:FindFirstChild("Highlight")
		if not highlight or not highlight:IsA("Highlight") then return false end
		if appearanceSaved[highlight] == nil then appearanceSaved[highlight] = highlight.FillTransparency end
		highlight.FillTransparency = highlightFill
		return true
	end
	local function restoreHighlight()
		for object, fill in pairs(appearanceSaved) do
			local ok, matches = pcall(function() return object:IsA("Highlight") end)
			if ok and matches then
				appearanceSaved[object] = nil
				pcall(function() object.FillTransparency = fill end)
			end
		end
	end
	-- 本地皮肤：只读取 ReplicatedStorage.Assets.Skins.Survivors.<角色>.<皮肤名>，
	-- 不下载远程资产；克隆后按附件名/部件名/Head/HumanoidRootPart 匹配并焊接。
	local function skinSource(char)
		if not char or skinName == "" then return nil end
		local storage = game:GetService("ReplicatedStorage")
		local assets = storage and storage:FindFirstChild("Assets")
		local skins = assets and assets:FindFirstChild("Skins")
		local survivors = skins and skins:FindFirstChild("Survivors")
		local folder = survivors and survivors:FindFirstChild(char.Name)
		return folder and folder:FindFirstChild(skinName) or nil
	end
	local function matchTarget(char, part)
		local attachment = part:FindFirstChildOfClass("Attachment")
		if attachment then
			for _, other in ipairs(descendants(char)) do
				if other:IsA("Attachment") and other.Name == attachment.Name and other.Parent and other.Parent:IsA("BasePart") then
					return other.Parent
				end
			end
		end
		local named = char:FindFirstChild(part.Name)
		if named and named:IsA("BasePart") then return named end
		local head = char:FindFirstChild("Head")
		if head and head:IsA("BasePart") then return head end
		local root = char:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then return root end
		for _, child in ipairs(char:GetChildren()) do
			if child:IsA("BasePart") then return child end
		end
		return nil
	end
	local function applySkin(char)
		if not char then return false end
		if skinClone and skinClone.Parent == char then return true end
		if skinClone then
			pcall(function() skinClone:Destroy() end)
			skinClone = nil
		end
		local source = skinSource(char)
		if not source then return false end
		local ok, clone = pcall(function() return source:Clone() end)
		if not ok or not clone then return false end
		clone.Name = "VortexionLocalSkin"
		for _, part in ipairs(descendants(clone)) do
			if part:IsA("BasePart") then
				part.CanCollide = false
				local target = matchTarget(char, part)
				if target then
					pcall(function() part.CFrame = target.CFrame end)
					local weld = Instance.new("Weld")
					weld.Part0 = target
					weld.Part1 = part
					weld.C0 = CFrame.new()
					weld.Parent = part
				end
			end
		end
		clone.Parent = char
		skinClone = clone
		return true
	end
	local function restoreSkin()
		if skinClone then
			pcall(function() skinClone:Destroy() end)
		skinClone = nil
		end
	end
	-- Catalog IDs are reference evidence; returned asset types are validated at runtime.
	local resourceProfiles = {
		["Yi Sang"] = {"12727615776", "12727617721", "17174244399", "93001472528329", "98573986433879"},
		["Ishmael"] = {"92622201093404", "18588497876", "18268134050", "18268128313"},
		["Terio / Manchegan衣饰"] = {ShirtTemplate = "rbxassetid://77697773617559", PantsTemplate = "rbxassetid://134919602560582", FaceTexture = "rbxassetid://405705854", PreserveAccessories = true, PreserveCharacterMeshes = true},
		["Terio / 异装衣饰"] = {ShirtTemplate = "rbxassetid://80628548279541", PantsTemplate = "rbxassetid://123452391937439", PreserveAccessories = true, PreserveCharacterMeshes = true},
		["Azure"] = {"7168334659", "12281536963", "13904713247", "138389347588090", ShirtTemplate = "rbxassetid://94974220498237", PantsTemplate = "rbxassetid://3267139027", TorsoColor = {105, 102, 92}, HideLife = true, PreserveCharacterMeshes = true},
		["TwoTime / 1x4外观"] = {
			LifeSource = {"Assets", "Skins", "Survivors", "TwoTime", "Milestone100TwoTime", "Config", "Life1"},
			HideBody = true, HideLife = true, HideModels = {"Life1", "Life2", "ExtraModels"}, DisableOriginalParticles = true, HideHighlight = true, HideSwordParticles = true,
			PreserveAccessories = true, PreserveClothing = true, PreserveCharacterMeshes = true,
		},
		["Sil / 表情"] = {FaceTexture = "rbxassetid://79565455816327", PreserveAccessories = true, PreserveClothing = true, PreserveCharacterMeshes = true},
		["Sil / 衣饰"] = {
			"13551519963", "132852136465111", "84426465822673", "84426465822673",
			ShirtTemplate = "rbxassetid://13927405506",
			PantsTemplate = "rbxassetid://13927410546",
			ShirtColor = {70, 0, 0},
			PantsColor = {10, 0, 0},
			FaceTexture = "rbxassetid://79565455816327",
			PreserveCharacterMeshes = true,
			ParticleColors = {{150, 0, 0}, {0, 0, 0}},
			Mounts = {
				{Part = "Head", C0 = CFrame.new(0, -1.60000002, 1.30000007, 1, 0, 0, 0, 1, 0, 0, 0, -1)},
				{Part = "Head", C0 = CFrame.new(0, -0.569999993, 0.100000001)},
				{Part = "Left Arm", C0 = CFrame.new(0, -0.349999994, 0), Color = {103, 0, 0}, Texture = ""},
				{Part = "Right Arm", C0 = CFrame.new(0, -0.349999994, 0), Color = {103, 0, 0}, Texture = ""},
			},
		},
	}
	-- 鞭影衣饰：浅拷贝 Sil / 衣饰 元数据 + 追加第 5 资源（Whip，权限失败时不影响原静态衣饰）
	local silShadowOutfit = {}
	for key, value in pairs(resourceProfiles["Sil / 衣饰"]) do silShadowOutfit[key] = value end
	silShadowOutfit.Mounts = {}
	for i, mount in ipairs(resourceProfiles["Sil / 衣饰"].Mounts) do silShadowOutfit.Mounts[i] = mount end
	silShadowOutfit[5] = "121467375821164"
	silShadowOutfit.PulseAnimation = {Id = "116814116277716", Delay = 0.45, Hold = 0.75}
	silShadowOutfit.Mounts[5] = {Part = "Left Arm", C0 = CFrame.new(0, -6, 0), Color = {255, 0, 0}, Texture = "", MeshScale = {1.2622312307357788, 10, 1}, Transparency = 1, Pulse = true}
	resourceProfiles["Sil / 鞭影衣饰"] = silShadowOutfit
	local resourceSoundDefs = {
		["挥鞭"] = {File = "TerioThings/sil_whip.mp3", Speed = 1, Volume = 1.5, Lifetime = 2},
		["斩击"] = {File = "TerioThings/lance_swing.mp3", Speed = 2, Volume = 1.5, Lifetime = 2},
		["凝血"] = {File = "TerioThings/coagulate.mp3", Speed = 1.5, Volume = 1.5, Lifetime = 2},
	}
	for _, name in ipairs({"Sil / 衣饰", "Sil / 鞭影衣饰"}) do
		resourceProfiles[name].ActionSounds = {["116814116277716"] = {Name = "挥鞭", Delay = 0.45}}
	end
	for _, name in ipairs({"Terio / Manchegan衣饰", "Terio / 异装衣饰"}) do
		resourceProfiles[name].ActionSounds = {["84413781229733"] = {Name = "斩击", Delay = 0}}
	end
	local resourceAudioEnabled, resourceAudioChoice = false, "挥鞭"
	local resourceProfile, resourceStatus = "无", "已关闭"
	local resourceSerial, resourceRecord, resourceAttempt, resourceRemovingChar, resourcePending = 0, nil, nil, nil, nil
	local resourceRemovingConnection, resourceToggle, localSkinToggle
	local resourceRestoreDepth = 0
	local function disposeResourceObject(object)
		if object then pcall(function() object:Destroy() end) end
	end
	local function disposeResourceSound(record, sound)
		local entry = record.audioSounds and record.audioSounds[sound]
		if record.audioSounds then record.audioSounds[sound] = nil end
		if entry and entry.connection then pcall(function() entry.connection:Disconnect() end) end
		pcall(function() sound:Stop() end)
		disposeResourceObject(sound)
	end
	local function stopResourceAudio(record)
		record.audioCue = nil
		local sounds = {}
		for sound in pairs(record.audioSounds or {}) do table.insert(sounds, sound) end
		for _, sound in ipairs(sounds) do disposeResourceSound(record, sound) end
	end
	local function unbindResourceAction(record)
		local connection = record.actionConnection
		record.actionEpoch = (record.actionEpoch or 0) + 1
		record.actionConnection, record.actionHum, record.actionAnimator, record.actionAttempt = nil, nil, nil, nil
		record.pulseActionTrack = nil
		stopResourceAudio(record)
		local epoch = record.actionEpoch
		if connection then pcall(function() connection:Disconnect() end) end
		return epoch
	end
	local function restoreResourceWorld(record)
		record.worldEpoch = (record.worldEpoch or 0) + 1
		local subscription, saved = record.worldConnection, record.worldSaved
		record.worldRoot, record.worldConnection, record.worldPending, record.worldSaved = nil, nil, nil, nil
		if subscription then pcall(function() subscription:Disconnect() end) end
		resourceRestoreDepth += 1
		for object, original in pairs(saved or {}) do
			pcall(function() if object.Enabled == false then object.Enabled = original end end)
		end
		resourceRestoreDepth -= 1
	end
	local function releaseResourceRecord(record)
		if not record or record.disposed then return end
		record.disposed = true
		resourceRestoreDepth += 1
		unbindResourceAction(record)
		restoreResourceWorld(record)
		record.pulseRequest = (record.pulseRequest or 0) + 1
		record.pulseStarted, record.pulseHandle, record.pulseAlpha, record.pulseHold = nil, nil, nil, nil
		local particleConnection = record.particleConnection
		record.particleConnection, record.particlePending, record.particleColor = nil, nil, nil
		if particleConnection then pcall(function() particleConnection:Disconnect() end) end
		for _, object in ipairs(record.items) do disposeResourceObject(object) end
		for i = #record.journal, 1, -1 do
			local entry = record.journal[i]
			pcall(function()
				local current = entry.object[entry.key]
				local unchanged
				if entry.equal then unchanged = entry.equal(current, entry.written) else unchanged = current == entry.written end
				if unchanged then entry.object[entry.key] = entry.original end
			end)
		end
		for _, entry in ipairs(record.parked) do
			pcall(function() if entry.object.Parent == record.stash then entry.object.Parent = entry.parent end end)
		end
		-- Never destroy original objects when a restore is denied or their parent is locked.
		if record.stash then
			pcall(function()
				for _, object in ipairs(record.stash:GetChildren()) do pcall(function() object.Parent = nil end) end
			end)
			disposeResourceObject(record.stash)
		end
		resourceRestoreDepth -= 1
	end
	local function restoreResources()
		resourceSerial += 1
		resourceAttempt = nil
		local previous, pending = resourceRecord, resourcePending
		resourceRecord, resourcePending = nil, nil
		releaseResourceRecord(previous)
		releaseResourceRecord(pending)
		resourceStatus = state.Resources and "等待角色或方案" or "已关闭"
	end
	local function resourceCurrent(serial, char)
		return not destroyed and state.Resources and serial == resourceSerial
			and char == character() and char ~= resourceRemovingChar and char.Parent ~= nil
			and (not ctx.sessionEnv or ctx.thisSessionId == nil or ctx.sessionEnv.VortexionSessionId == ctx.thisSessionId)
	end
	local function prepareResourceAudio(record)
		record.audioAssets, record.audioSounds = {}, {}
		if not resourceAudioEnabled then record.audioStatus = "本地音效已关闭"; return end
		local exists, asset = ctx.isfile or isfile, ctx.getcustomasset or getcustomasset
		if type(exists) ~= "function" or type(asset) ~= "function" then record.audioStatus = "缺少 isfile / getcustomasset"; return end
		local ready, missing = 0, {}
		-- This runs inside the existing asset-loading task, never a visual tick.
		for name, definition in pairs(resourceSoundDefs) do
			if record.disposed or not resourceCurrent(record.serial, record.char) then return end
			local ok, uri = pcall(function() if exists(definition.File) then return asset(definition.File) end end)
			if record.disposed or not resourceCurrent(record.serial, record.char) or not resourceAudioEnabled then return end
			if ok and type(uri) == "string" and uri ~= "" then record.audioAssets[name] = uri; ready += 1
			else table.insert(missing, definition.File) end
		end
		table.sort(missing)
		record.audioStatus = "本地音效就绪 " .. ready .. "/3" .. (#missing > 0 and ("；缺少：" .. table.concat(missing, ", ")) or "")
	end
	local function resourceWrite(record, object, key, value, equal)
		assert(not record.disposed and resourceCurrent(record.serial, record.char), "resource property cancelled")
		if not object then return end
		local values = record.saved[object]
		if not values then values = {}; record.saved[object] = values end
		local entry = values[key]
		if not entry then
			entry = {object = object, key = key, original = object[key]}
			values[key] = entry
			table.insert(record.journal, entry)
		end
		if equal then entry.equal = equal end
		entry.written = value
		object[key] = value
		assert(not record.disposed and resourceCurrent(record.serial, record.char), "resource property superseded")
	end
	local function prepareResourceTemplates(record, definition)
		for _, pair in ipairs({{"Shirt", "ShirtTemplate"}, {"Pants", "PantsTemplate"}}) do
			local template = definition[pair[2]]
			if template then
				assert(not record.disposed and resourceCurrent(record.serial, record.char), "template request cancelled")
				local clothing
				for _, item in ipairs(record.items) do if item:IsA(pair[1]) then clothing = item; break end end
				if not clothing then
					clothing = Instance.new(pair[1])
					table.insert(record.items, clothing)
					clothing.Name = "VortexionAppearance" .. pair[1]
				end
				clothing[pair[2]] = template
				local color = definition[pair[1] .. "Color"]
				if color then clothing.Color3 = Color3.fromRGB(table.unpack(color)) end
			end
		end
	end
	local azureResourceMounts = {
		["7168334659"] = CFrame.new(0, 1.25, 0),
		["12281536963"] = CFrame.new(0.200000003, -0.0700000003, 0.25),
		["13904713247"] = CFrame.new(0, 0.359999985, 0),
		["138389347588090"] = CFrame.new(0, -0.700000346, 0),
	}
	local function prepareResourceAccessory(item, char, headMount, mountPart, mountStyle)
		local all = item:GetDescendants()
		assert(#all <= 512, "asset descendant budget exceeded")
		for _, object in ipairs(all) do
			if object:IsA("LuaSourceContainer") or object:IsA("JointInstance") or object:IsA("Constraint") or object:IsA("WeldConstraint") then
				object:Destroy()
			elseif object:IsA("BasePart") then
				object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery, object.Massless = false, false, false, false, true
			end
		end
		if not item:IsA("Accessory") then return end
		local handle = item:FindFirstChild("Handle")
		assert(handle and handle:IsA("BasePart"), "accessory Handle missing")
		if mountStyle then
			local mesh = handle:FindFirstChildOfClass("SpecialMesh")
			if mountStyle.MeshScale then
				assert(mesh, "profile SpecialMesh missing")
				mesh.Scale = Vector3.new(table.unpack(mountStyle.MeshScale))
			end
			if mountStyle.Transparency ~= nil then handle.Transparency = mountStyle.Transparency end
			if mountStyle.Color then handle.Color = Color3.fromRGB(table.unpack(mountStyle.Color)) end
			if mountStyle.Texture ~= nil then
				if mesh then mesh.TextureId = mountStyle.Texture
				elseif handle:IsA("MeshPart") then handle.TextureID = mountStyle.Texture
				else error("profile mesh missing") end
			end
		end
		local attachment = handle:FindFirstChildOfClass("Attachment")
		local target, c0, c1 = nil, CFrame.new(), attachment and attachment.CFrame or item.AttachmentPoint
		if headMount then
			target, c0, c1 = char:FindFirstChild(mountPart or "Head"), headMount, mountStyle and mountStyle.C1 or CFrame.new()
			assert(target and target:IsA("BasePart"), "profile body mount missing")
		elseif attachment then
			for _, part in ipairs(char:GetChildren()) do
				if part:IsA("BasePart") then
					local match = part:FindFirstChild(attachment.Name)
					if match and match:IsA("Attachment") then target, c0 = part, match.CFrame; break end
				end
			end
		end
		if not target then
			for _, name in ipairs({"Head", "UpperTorso", "Torso"}) do
				local part = char:FindFirstChild(name)
				if part and part:IsA("BasePart") then target = part; break end
			end
		end
		assert(target, "accessory mount missing")
		local offsets = {}
		for _, part in ipairs(item:GetDescendants()) do
			if part:IsA("BasePart") and part ~= handle then offsets[part] = handle.CFrame:ToObjectSpace(part.CFrame) end
		end
		handle.CFrame = target.CFrame * c0 * c1:Inverse()
		for part, offset in pairs(offsets) do
			part.CFrame = handle.CFrame * offset
			local internal = Instance.new("Weld")
			internal.Parent = part
			internal.Part0, internal.Part1, internal.C0 = handle, part, offset
		end
		local weld = Instance.new("Weld")
		weld.Parent = handle
		weld.Name, weld.Part0, weld.Part1, weld.C0, weld.C1 = "VortexionResourceWeld", target, handle, c0, c1
		return handle
	end
	local function prepareResourceLifeModel(record, definition)
		if not definition.LifeSource then return end
		local source = game:GetService("ReplicatedStorage")
		for _, name in ipairs(definition.LifeSource) do source = source and source:FindFirstChild(name) end
		assert(source and (source:IsA("Model") or source:IsA("Folder")), "local Life1 resource missing")
		assert(#source:GetDescendants() <= 512, "local Life1 descendant budget exceeded")
		local life = source:Clone()
		if record.disposed or not resourceCurrent(record.serial, record.char) then disposeResourceObject(life); error("late local Life1 clone") end
		assert(life, "local Life1 clone unavailable")
		table.insert(record.items, life)
		life.Name = "VortexionAppearanceLife1"
		prepareResourceAccessory(life, record.char)
		for _, name in ipairs({"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}) do
			local body, skin = record.char:FindFirstChild(name), life:FindFirstChild(name)
			assert(body and body:IsA("BasePart") and skin and skin:IsA("BasePart"), "local Life1 R6 body mismatch")
		end
		local plan = {}
		for _, part in ipairs(life:GetDescendants()) do
			assert(not part:IsA("Humanoid") and not part:IsA("Animator") and not part:IsA("AnimationController"), "local Life1 controller unsupported")
			if part:IsA("BasePart") then
				local root = part
				while root.Parent ~= life do root = root.Parent; assert(root, "local Life1 orphan part") end
				local target = record.char:FindFirstChild(root.Name)
				assert(root:IsA("BasePart") and target and target:IsA("BasePart"), "local Life1 unmapped part")
				table.insert(plan, {part = part, target = target, offset = part == root and CFrame.new() or root.CFrame:ToObjectSpace(part.CFrame)})
			end
		end
		assert(#plan > 0, "local Life1 has no parts")
		for _, entry in ipairs(plan) do
			entry.part.CFrame = entry.target.CFrame * entry.offset
			local weld = Instance.new("Weld", entry.part)
			weld.Name, weld.Part0, weld.Part1, weld.C0 = "VortexionLifeWeld", entry.target, entry.part, entry.offset
		end
		local blade = Instance.new("Accessory")
		table.insert(record.items, blade)
		blade.Name = "VortexionShadowBlade"
		local handle = Instance.new("Part", blade)
		handle.Name, handle.Size, handle.Color = "Handle", Vector3.new(1, 1, 1), Color3.new(0.1, 0.1, 0.1)
		local mesh = Instance.new("SpecialMesh", handle)
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.MeshId, mesh.TextureId, mesh.Scale = "rbxassetid://62275962", "rbxassetid://62276016", Vector3.new(0.5, 0.5, 0.5)
		-- The reference weld uses handle -> arm; the adapter uses arm -> handle.
		prepareResourceAccessory(blade, record.char, CFrame.new(0, 1, 0), "Left Arm", {
			C1 = CFrame.new(1.75, -0.879999995, 0, -1.31445322e-05, 1, 0, 0, 0, 1, 1, 1.31445331e-05, -7.10549173e-15),
		})
		assert(not record.disposed and resourceCurrent(record.serial, record.char), "local Life1 preparation superseded")
	end
	local function updateResourceLife(record)
		if record.disposed then return end
		local definition = resourceProfiles[record.profile]
		if definition and definition.HideLife then
			record.hiddenLife = record.hiddenLife or {}
			for _, name in ipairs(definition.HideModels or {"Life1", "Life2"}) do
				local model = record.char:FindFirstChild(name)
				if model ~= record.hiddenLife[name] then
					record.hiddenLife[name] = model
					if model then
						for _, object in ipairs(model:GetDescendants()) do
							if object:IsA("BasePart") or object:IsA("Decal") then resourceWrite(record, object, "Transparency", 1)
							elseif definition.DisableOriginalParticles and object:IsA("ParticleEmitter") then resourceWrite(record, object, "Enabled", false) end
						end
					end
				end
			end
			return
		end
		if record.profile ~= "Yi Sang" then return end
		local life2 = record.char:FindFirstChild("Life2")
		if life2 ~= record.life2 then
			record.life2 = life2
			if life2 then
				for _, object in ipairs(life2:GetDescendants()) do
					if object:IsA("BasePart") or object:IsA("Decal") then resourceWrite(record, object, "Transparency", 1)
					elseif object:IsA("ParticleEmitter") then resourceWrite(record, object, "Enabled", false) end
				end
			end
			for _, name in ipairs({"Accessory (WingsAccessory)", "Accessory (Spicebush_Head)"}) do
				local item = record.char:FindFirstChild(name)
				local handle = item and item:FindFirstChild("Handle")
				if handle and handle:IsA("BasePart") then resourceWrite(record, handle, "Transparency", life2 and 0 or 1) end
			end
		end
	end
	local function commitResourceAppearance(record)
		local char, definition = record.char, resourceProfiles[record.profile]
		local legacy = record.profile == "Yi Sang" or record.profile == "Ishmael"
		local replacing = {}
		for _, item in ipairs(record.items) do
			if item:IsA("Shirt") then replacing.Shirt = true elseif item:IsA("Pants") then replacing.Pants = true end
		end
		for _, object in ipairs(char:GetChildren()) do
			local park = object:IsA("Accessory") and not definition.PreserveAccessories
				or object:IsA("CharacterMesh") and not definition.PreserveCharacterMeshes
				or object:IsA("Shirt") and not definition.PreserveClothing and (legacy or replacing.Shirt)
				or object:IsA("Pants") and not definition.PreserveClothing and (legacy or replacing.Pants)
			if park then
				table.insert(record.parked, {object = object, parent = char})
				object.Parent = record.stash
			elseif object:IsA("BasePart") then
				if definition.HideBody then
					resourceWrite(record, object, "Transparency", 1)
					for _, child in ipairs(object:GetDescendants()) do
						if child:IsA("Decal") then resourceWrite(record, child, "Transparency", 1)
						elseif definition.DisableOriginalParticles and child:IsA("ParticleEmitter") then resourceWrite(record, child, "Enabled", false) end
					end
				elseif legacy then resourceWrite(record, object, "Color", BrickColor.new("White").Color)
				elseif record.profile == "Azure" and object.Name ~= "HumanoidRootPart" and object.Name ~= "VisibilityDetector"
					and not object.Name:find("Hitbox") and not object.Name:find("Holder") then
					resourceWrite(record, object, "Transparency", 0)
					resourceWrite(record, object, "Color", Color3.new(1, 1, 1))
				end
			end
			assert(resourceCurrent(record.serial, char) and not record.disposed, "resource commit cancelled")
		end
		for _, item in ipairs(record.items) do
			item.Parent = char
			assert(resourceCurrent(record.serial, char) and not record.disposed, "resource attach cancelled")
		end
		if definition.FaceTexture then
			local head = char:FindFirstChild("Head")
			assert(head and head:IsA("BasePart"), "appearance Head missing")
			local face = head:FindFirstChild("face") or head:FindFirstChild("Face")
			if not face or not face:IsA("Decal") then
				face = nil
				for _, item in ipairs(head:GetChildren()) do
					if item:IsA("Decal") and item.Face == Enum.NormalId.Front then face = item; break end
				end
			end
			if face then resourceWrite(record, face, "Texture", definition.FaceTexture)
			else
				face = Instance.new("Decal")
				table.insert(record.items, face)
				face.Name, face.Texture, face.Face = "VortexionAppearanceFace", definition.FaceTexture, Enum.NormalId.Front
				face.Parent = head
				assert(resourceCurrent(record.serial, char) and not record.disposed, "appearance face cancelled")
			end
		end
		if definition.TorsoColor then
			local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
			assert(torso and torso:IsA("BasePart"), "appearance torso missing")
			resourceWrite(record, torso, "Color", Color3.fromRGB(table.unpack(definition.TorsoColor)))
		end
		if definition.HideLife then updateResourceLife(record) end
		if definition.HideHighlight then
			local highlight = char:FindFirstChild("Highlight") or char:FindFirstChildOfClass("Highlight")
			if highlight and highlight:IsA("Highlight") then resourceWrite(record, highlight, "FillTransparency", 1) end
		end
		if record.profile == "Yi Sang" then
			for _, object in ipairs(char:GetChildren()) do
				if object:IsA("BasePart") and object.Name ~= "HumanoidRootPart" and object.Name ~= "VisibilityDetector" then resourceWrite(record, object, "Transparency", 0) end
			end
			local life1 = char:FindFirstChild("Life1")
			if life1 then
				for _, object in ipairs(life1:GetDescendants()) do
					if object:IsA("BasePart") or object:IsA("Decal") then resourceWrite(record, object, "Transparency", 1) end
				end
				local head = life1:FindFirstChild("Head")
				local hair = head and head:FindFirstChild("hair")
				if hair and hair:IsA("BasePart") then
					resourceWrite(record, hair, "Transparency", 0)
					resourceWrite(record, hair, "Color", Color3.new(0, 0, 0))
					resourceWrite(record, hair, "Material", Enum.Material.SmoothPlastic)
				end
			end
			local ghost = char:FindFirstChild("GhostFire")
			local blade = ghost and ghost:FindFirstChild("GhostfireBlade")
			if blade then
				local highlight = Instance.new("Highlight")
				table.insert(record.items, highlight)
				highlight.Name, highlight.Adornee = "VortexionResourceHighlight", blade
				highlight.DepthMode, highlight.FillColor, highlight.FillTransparency = Enum.HighlightDepthMode.Occluded, Color3.new(0, 0, 0), 0
				highlight.Parent = blade
				assert(resourceCurrent(record.serial, char) and not record.disposed, "resource effect cancelled")
			end
			local holder = char:FindFirstChild("ExpressionHolder")
			local face = holder and holder:FindFirstChild("Expression")
			if face and face:IsA("Decal") then resourceWrite(record, face, "Texture", "rbxassetid://93421870784694") end
			for _, pair in ipairs({{"Accessory (WingsAccessory)", CFrame.new(0, 1, 1.25)}, {"Accessory (YiSangAccessory)", CFrame.new(0, -0.899999976, -0.600000024)}}) do
				local item = char:FindFirstChild(pair[1])
				local handle = item and item:FindFirstChild("Handle")
				local weld = handle and handle:FindFirstChild("VortexionResourceWeld")
				if weld then weld.C0 = pair[2] end
			end
			record.life2 = false
			updateResourceLife(record)
		elseif record.profile == "Ishmael" then
			local head = char:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				resourceWrite(record, head, "Transparency", 0)
				local plasma = head:FindFirstChild("Plasma")
				if plasma then
					for _, object in ipairs(plasma:GetChildren()) do
						table.insert(record.parked, {object = object, parent = plasma})
						object.Parent = record.stash
						assert(resourceCurrent(record.serial, char) and not record.disposed, "resource particle cancelled")
					end
				end
			end
			local staff = char:FindFirstChild("Staff")
			local mesh, joint = staff and staff:FindFirstChild("Mesh"), staff and staff:FindFirstChild("Joint")
			if mesh and mesh:IsA("SpecialMesh") then
				resourceWrite(record, mesh, "MeshId", "rbxassetid://18290010577")
				resourceWrite(record, mesh, "TextureId", "rbxassetid://18274213192")
				resourceWrite(record, mesh, "Scale", Vector3.new(1.15, 1.15, 1.15))
			end
			if joint and joint:IsA("JointInstance") then resourceWrite(record, joint, "C0", CFrame.new(0, -1, 0, -0.0199960023, -0.999800205, 0, 0, 0, -1, 0.999800086, -0.0199924167, 0)) end
			local torso = Instance.new("CharacterMesh")
			table.insert(record.items, torso)
			torso.BodyPart, torso.MeshId, torso.Parent = Enum.BodyPart.Torso, "48112070", char
		end
	end
	local function findResourceWorldRoot()
		local map = Workspace:FindFirstChild("Map")
		return map and map:FindFirstChild("Ingame")
	end
	local function resourceWorldCurrent(record, root, epoch)
		return not record.disposed and resourceRecord == record and resourceCurrent(record.serial, record.char)
			and record.worldEpoch == epoch and record.worldRoot == root and findResourceWorldRoot() == root
	end
	local function isResourceSwordParticle(object, root)
		if not object:IsA("ParticleEmitter") then return false end
		local top = object
		while top and top.Parent ~= root do top = top.Parent end
		return top ~= nil and top ~= object and top.Name == "Swords"
	end
	local function updateResourceWorld(record)
		if record.disposed or not resourceCurrent(record.serial, record.char) or not resourceProfiles[record.profile].HideSwordParticles then return end
		local root = findResourceWorldRoot()
		if root ~= record.worldRoot then
			restoreResourceWorld(record)
			if record.disposed or not resourceCurrent(record.serial, record.char) then return end
			if root then
				record.worldRoot = root
				record.worldSaved = setmetatable({}, {__mode = "k"})
				record.worldPending = setmetatable({}, {__mode = "k"})
				local epoch = record.worldEpoch
				local function queue(object)
					if resourceWorldCurrent(record, root, epoch) and record.worldPending and isResourceSwordParticle(object, root) and record.worldSaved[object] == nil then record.worldPending[object] = true end
				end
				local ok, candidate = pcall(function() return root.DescendantAdded:Connect(function(object) pcall(queue, object) end) end)
				if not resourceWorldCurrent(record, root, epoch) then
					if ok and candidate then pcall(function() candidate:Disconnect() end) end
					return
				end
				if not ok or not candidate then record.worldStatus = "粒子监听失败，重新应用可重试"; return end
				record.worldConnection = candidate
				record.worldStatus = "Swords 粒子本机隐藏（可恢复）"
				-- Subscribe before the one-time scan so late descendants are not lost.
				for _, object in ipairs(root:GetDescendants()) do queue(object) end
			end
		end
		if not root then record.worldStatus = "等待 Map.Ingame"; return end
		local pending = record.worldPending
		if not pending or next(pending) == nil then return end
		local epoch, batch = record.worldEpoch, {}
		for object in pairs(pending) do
			pending[object] = nil
			table.insert(batch, object)
			if #batch >= 32 then break end
		end
		for _, object in ipairs(batch) do
			if not resourceWorldCurrent(record, root, epoch) then break end
			local ok = pcall(function()
				if object.Parent and isResourceSwordParticle(object, root) and record.worldSaved[object] == nil then
					record.worldSaved[object] = object.Enabled
					object.Enabled = false
				end
			end)
			if not ok and not record.disposed then record.worldStatus = "部分 Swords 粒子隐藏失败，重新应用可重试" end
		end
	end
	local function resourceColorSequenceEqual(a, b)
		local ka, kb = a.Keypoints, b.Keypoints
		if #ka ~= #kb then return false end
		for i = 1, #ka do
			local pa, pb = ka[i], kb[i]
			if pa.Time ~= pb.Time or pa.Value.R ~= pb.Value.R or pa.Value.G ~= pb.Value.G or pa.Value.B ~= pb.Value.B then return false end
		end
		return true
	end
	local function queueResourceParticle(record, object)
		if record.disposed or not record.particlePending or not resourceCurrent(record.serial, record.char) then return end
		if object:IsA("ParticleEmitter") and object.Name == "ParticleEmitter" and object:IsDescendantOf(record.char) then
			local saved = record.saved[object]
			if not (saved and saved.Color) then record.particlePending[object] = true end
		end
	end
	local function updateResourceParticles(record)
		if not record or record.disposed or not record.particlePending or not resourceCurrent(record.serial, record.char) then return end
		if next(record.particlePending) == nil then return end
		local pending, batch = record.particlePending, {}
		-- Snapshot before writes: game callbacks may add emitters while colors change.
		for object in pairs(pending) do
			pending[object] = nil
			table.insert(batch, object)
			if #batch >= 32 then break end
		end
		for _, object in ipairs(batch) do
			if record.disposed or not resourceCurrent(record.serial, record.char) then break end
			local ok = pcall(function()
				if object.Parent and object:IsA("ParticleEmitter") and object.Name == "ParticleEmitter" and object:IsDescendantOf(record.char) then
					resourceWrite(record, object, "Color", record.particleColor, resourceColorSequenceEqual)
				end
			end)
			if not ok and not record.disposed then record.particleFailed = true end
		end
	end
	local function installResourceParticles(record)
		local colors = resourceProfiles[record.profile].ParticleColors
		if not colors then return end
		assert(not record.disposed and resourceCurrent(record.serial, record.char), "particle subscription cancelled")
		record.particleColor = ColorSequence.new(Color3.fromRGB(table.unpack(colors[1])), Color3.fromRGB(table.unpack(colors[2])))
		record.particlePending = setmetatable({}, {__mode = "k"})
		local candidate = record.char.DescendantAdded:Connect(function(object) pcall(queueResourceParticle, record, object) end)
		if record.disposed or not resourceCurrent(record.serial, record.char) then
			if candidate then pcall(function() candidate:Disconnect() end) end
			error("late particle subscription")
		end
		assert(candidate, "particle subscription missing")
		record.particleConnection = candidate
		for _, object in ipairs(record.char:GetDescendants()) do queueResourceParticle(record, object) end
	end
	local function hideResourcePulse(record)
		record.pulseRequest = (record.pulseRequest or 0) + 1
		record.pulseStarted, record.pulseHold, record.pulseActionTrack, record.pulseAlpha = nil, nil, nil, 1
		local handle = record.pulseHandle
		if handle then pcall(function() handle.Transparency = 1 end) end
	end
	local function beginResourcePulse(record, actionTrack, delay, hold)
		if not record or record.disposed or resourceRecord ~= record or not resourceCurrent(record.serial, record.char) or not record.pulseHandle then return false end
		local request = (record.pulseRequest or 0) + 1
		record.pulseRequest = request
		local ok = pcall(function()
			local handle, starts = record.pulseHandle, clock() + (delay or 0)
			assert(handle.Parent and handle:IsDescendantOf(record.char), "pulse handle removed")
			handle.Transparency = 1
			-- Property callbacks may replace this pulse before the setter returns.
			assert(not record.disposed and resourceRecord == record and resourceCurrent(record.serial, record.char) and record.pulseRequest == request, "pulse superseded")
			record.pulseStarted, record.pulseHold, record.pulseActionTrack, record.pulseAlpha = starts, hold, actionTrack, 1
		end)
		if ok then nextAppearance = -math.huge end
		return ok
	end
	local function resourceAudioCurrent(record)
		local hum = record.char:FindFirstChildOfClass("Humanoid")
		return resourceAudioEnabled and not record.disposed and resourceRecord == record and resourceCurrent(record.serial, record.char) and hum and hum.Health > 0
	end
	local function queueResourceAudio(record, name, delay, actionTrack)
		if not resourceAudioCurrent(record) or not record.audioAssets or not record.audioAssets[name] then return false end
		record.audioCue = {name = name, due = clock() + (delay or 0), track = actionTrack, epoch = record.actionEpoch}
		nextAppearance = -math.huge
		return true
	end
	local function updateResourceAudio(record)
		if not resourceAudioCurrent(record) then stopResourceAudio(record); return end
		local expired = {}
		for sound, entry in pairs(record.audioSounds or {}) do if clock() >= entry.expires or not sound.Parent then table.insert(expired, sound) end end
		for _, sound in ipairs(expired) do disposeResourceSound(record, sound) end
		local cue = record.audioCue
		if not cue then return end
		if cue.epoch ~= record.actionEpoch or (cue.track and not cue.track.IsPlaying) then record.audioCue = nil; return end
		if clock() < cue.due then return end
		record.audioCue = nil
		local count = 0
		for _ in pairs(record.audioSounds or {}) do count += 1 end
		if count >= 4 then return end
		local parent = LocalPlayer:FindFirstChild("PlayerGui")
		if not parent then record.audioStatus = "等待 PlayerGui；下次动作重试"; return end
		local sound
		local function current() return resourceAudioCurrent(record) and cue.epoch == record.actionEpoch end
		local ok = pcall(function()
			local definition, uri = resourceSoundDefs[cue.name], record.audioAssets[cue.name]
			assert(definition and uri and current(), "local sound cancelled")
			sound = Instance.new("Sound")
			if not current() then disposeResourceObject(sound); return end
			record.audioSounds[sound] = {expires = clock() + definition.Lifetime}
			sound.Name, sound.SoundId, sound.PlaybackSpeed, sound.Volume = "VortexionLocalActionSound", uri, definition.Speed, definition.Volume
			sound.Parent = parent
			assert(current(), "local sound superseded")
			local connection = sound.Ended:Connect(function() disposeResourceSound(record, sound) end)
			if not current() or not record.audioSounds[sound] then connection:Disconnect(); disposeResourceSound(record, sound); return end
			record.audioSounds[sound].connection = connection
			sound:Play()
			assert(current(), "local sound playback superseded")
		end)
		if not ok then
			if sound then disposeResourceSound(record, sound) end
			if resourceAudioCurrent(record) then record.audioStatus = "本地音效播放失败；下次动作重试" end
		end
	end
	local function updateResourceAction(record)
		if not record or record.disposed or not resourceCurrent(record.serial, record.char) then return end
		local profile = resourceProfiles[record.profile]
		local definition, sounds = profile.PulseAnimation, profile.ActionSounds
		if not (definition and record.pulseHandle) and not (resourceAudioEnabled and sounds) then return end
		local hum = record.char:FindFirstChildOfClass("Humanoid")
		local animator = hum and hum.Health > 0 and hum:FindFirstChildOfClass("Animator") or nil
		if record.actionHum ~= hum or record.actionAnimator ~= animator then
			local epoch = unbindResourceAction(record)
			if record.disposed or record.actionEpoch ~= epoch or not resourceCurrent(record.serial, record.char) then return end
			hideResourcePulse(record)
			if record.disposed or record.actionEpoch ~= epoch or not resourceCurrent(record.serial, record.char) then return end
			record.actionHum, record.actionAnimator = hum, animator
			record.actionStatus = "等待 Animator"
		end
		if not animator or record.actionConnection or record.actionAttempt == animator then return end
		record.actionAttempt = animator
		local epoch, bound = record.actionEpoch, false
		local function currentBinding()
			return not record.disposed and resourceRecord == record and resourceCurrent(record.serial, record.char)
				and record.actionEpoch == epoch and record.actionHum == hum and record.actionAnimator == animator
				and hum.Parent == record.char and hum.Health > 0 and animator.Parent == hum
		end
		local ok, candidate = pcall(function() return animator.AnimationPlayed:Connect(function(actionTrack)
			if not bound then return end
			pcall(function()
				if not currentBinding() then return end
				local animation = actionTrack.Animation
				local raw = animation and animation.AnimationId
				if type(raw) ~= "string" then return end
				local id = raw:match("^rbxassetid://(%d+)$") or raw:match("^(%d+)$")
				if not actionTrack.IsPlaying then return end
				if definition and record.pulseHandle and id == definition.Id then
					if not beginResourcePulse(record, actionTrack, definition.Delay, definition.Hold) and currentBinding() then record.actionStatus = "鞭影触发失效，可重新应用" end
				end
				local audio = sounds and sounds[id]
				if audio and currentBinding() then queueResourceAudio(record, audio.Name, audio.Delay, actionTrack) end
			end)
		end) end)
		local checked, current = pcall(currentBinding)
		if not ok or not candidate or not checked or not current then
			if ok and candidate then pcall(function() candidate:Disconnect() end) end
			if checked and current then record.actionStatus = "监听失败，可重新应用" end
			return
		end
		record.actionConnection, record.actionStatus, bound = candidate, "已绑定", true
	end
	local function resourcePulseAlpha(elapsed, hold)
		local holdEnd = 0.15 + (hold or 0.2)
		if elapsed >= holdEnd + 0.5 then return 1, true end
		if elapsed <= 0 then return 1, false end
		if elapsed < 0.15 then return 1 - elapsed / 0.15, false end
		if elapsed < holdEnd then return 0, false end
		return math.clamp((elapsed - holdEnd) / 0.5, 0, 1), false
	end
	local function updateResourcePulse(record)
		if not record or record.disposed or record.pulseStarted == nil or not resourceCurrent(record.serial, record.char) then return end
		local request, started, hold = record.pulseRequest, record.pulseStarted, record.pulseHold
		local handle, actionTrack = record.pulseHandle, record.pulseActionTrack
		if not handle or handle.Parent == nil or not handle:IsDescendantOf(record.char) then hideResourcePulse(record); return end
		if actionTrack then
			local ok, playing = pcall(function() return actionTrack.IsPlaying end)
			if not ok or not playing then hideResourcePulse(record); return end
		end
		local alpha, done = resourcePulseAlpha(clock() - started, hold)
		if record.disposed or record.pulseRequest ~= request or not resourceCurrent(record.serial, record.char) then return end
		if alpha ~= record.pulseAlpha then
			handle.Transparency = alpha
			if record.disposed or record.pulseRequest ~= request or not resourceCurrent(record.serial, record.char) then return end
			record.pulseAlpha = alpha
		end
		if done then record.pulseStarted, record.pulseHold, record.pulseActionTrack = nil, nil, nil end
	end
	local function applyResources(char)
		if ctx.sessionEnv and ctx.thisSessionId ~= nil and ctx.sessionEnv.VortexionSessionId ~= ctx.thisSessionId then
			state.Resources = false
			restoreResources()
			resourceStatus = "旧会话已停止"
			return false
		end
		if resourceRestoreDepth > 0 then return true end
		if not char or char == resourceRemovingChar then resourceStatus = "等待角色"; return false end
		if resourceRecord and resourceRecord.char == char then
			pcall(updateResourceLife, resourceRecord)
			pcall(updateResourceParticles, resourceRecord)
			pcall(updateResourceWorld, resourceRecord)
			pcall(updateResourceAction, resourceRecord)
			pcall(updateResourceAudio, resourceRecord)
			pcall(updateResourcePulse, resourceRecord)
			return true
		end
		if resourceAttempt == char then return resourceStatus == "载入中" end
		local profile = resourceProfile
		local definition = resourceProfiles[profile]
		if not definition then resourceStatus = "先选择角色方案"; return false end
		resourceSerial += 1
		local serial = resourceSerial
		if not resourceCurrent(serial, char) then return false end
		resourceAttempt, resourceStatus = char, "载入中"
		local record = {char = char, profile = profile, serial = serial, items = {}, parked = {}, saved = {}, journal = {}}
		resourcePending = record
		local spawned = pcall(function()
			task.spawn(function()
				local ok = pcall(function()
					for index, id in ipairs(definition) do
						assert(resourceCurrent(serial, char), "resource request cancelled")
						local list = game:GetObjects("rbxassetid://" .. id)
						assert(type(list) == "table", "asset result missing")
						if record.disposed or not resourceCurrent(serial, char) then
							for _, object in ipairs(list) do disposeResourceObject(object) end
							error("late resource result")
						end
						local item = list[1]
						for i, object in ipairs(list) do if i > 1 then disposeResourceObject(object) end end
						assert(item, "asset empty")
						table.insert(record.items, item)
						assert(resourceCurrent(serial, char), "late resource result")
						assert(item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants"), "unsupported asset type")
						local mount = definition.Mounts and definition.Mounts[index]
						if profile == "Azure" or mount then assert(item:IsA("Accessory"), "profile accessory type mismatch") end
						local handle = prepareResourceAccessory(item, char, mount and mount.C0 or (profile == "Azure" and azureResourceMounts[id] or nil), mount and mount.Part, mount)
						if mount and mount.Pulse then record.pulseHandle = handle end
					end
					prepareResourceLifeModel(record, definition)
					prepareResourceTemplates(record, definition)
					prepareResourceAudio(record)
					assert(not record.disposed and resourceCurrent(serial, char), "audio preparation cancelled")
					assert(resourceCurrent(serial, char) and not record.disposed, "resource commit stale")
					record.stash = Instance.new("Folder")
					record.stash.Name = "VortexionAppearanceBackup"
					resourceRecord, resourcePending = record, nil
					commitResourceAppearance(record)
					installResourceParticles(record)
					updateResourceWorld(record)
					updateResourceAction(record)
					assert(resourceCurrent(serial, char) and not record.disposed, "resource commit superseded")
				end)
				if resourcePending == record then resourcePending = nil end
				if not ok then
					if resourceRecord == record then resourceRecord = nil end
					releaseResourceRecord(record)
				end
				if resourceCurrent(serial, char) then
					resourceStatus = ok and ("已应用：" .. profile .. (#definition > 0 and ("（" .. #definition .. "项目录资源）") or (definition.LifeSource and "（本地模型 / 暗刃）" or "（衣饰 / 表情模板）"))) or "资源载入或挂载失败；原外观已保留/恢复，点重新应用重试"
					degraded.Resources = not ok
				end
			end)
		end)
		if not spawned and resourceCurrent(serial, char) then
			if resourcePending == record then resourcePending = nil end
			releaseResourceRecord(record)
			resourceStatus = "异步载入不可用"
		end
		return spawned
	end
	local function restoreScale(except)
		for model, original in pairs(appearanceScaleSaved) do
			if model ~= except then
				appearanceScaleSaved[model] = nil
				pcall(function() model:ScaleTo(restoreOriginalScale and original or scaleBase) end)
			end
		end
	end
	local function applyScale(char)
		if not char then return false end
		-- Restore previous characters even when a setting callback beats the next frame.
		restoreScale(char)
		if appearanceScaleSaved[char] == nil then
			local ok, original = pcall(function() return char:GetScale() end)
			if not ok or type(original) ~= "number" or original ~= original or original <= 0 or original >= math.huge then return false end
			appearanceScaleSaved[char] = original
		end
		return pcall(function() char:ScaleTo(scaleValue) end)
	end
	local appearanceAppliers = {
		Life12 = hideLifeModels,
		Extras = hideExtras,
		Highlight = applyHighlight,
		Skin = applySkin,
		Scale = applyScale,
		Resources = applyResources,
	}
	local appearanceRestorers = {
		Life12 = restoreLifeModels,
		Extras = restoreExtras,
		Highlight = restoreHighlight,
		Skin = restoreSkin,
		Scale = restoreScale,
		Resources = restoreResources,
	}
	local function bindRespawn()
		if respawnConnection or destroyed then return end
		local signal = LocalPlayer and LocalPlayer.CharacterAdded
		if not signal then return end
		respawnConnection = signal:Connect(function()
			if destroyed then return end
			resourceRemovingChar = nil
			local busy = false
			for key in pairs(appearanceAppliers) do
				if state[key] then busy = true break end
			end
			if not busy then return end
			-- 角色切换不受视觉节流延迟：下一帧即重新应用。
			appearanceChar = nil
			nextAppearance = -math.huge
			ensureLoop()
		end)
		track(respawnConnection)
	end
	-- Ordinary appearance is reasserted; catalog profiles update Life2 incrementally and reload only on refresh/respawn.
	-- Restore the previous character before applying any enabled appearance to a new one.
	local function enforceAppearance()
		if destroyed then return end
		local char = character()
		if char ~= appearanceChar then
			for _, restore in pairs(appearanceRestorers) do pcall(restore) end
			appearanceChar = char
			if char then
				for key, apply in pairs(appearanceAppliers) do
					if state[key] then
						local okApply = apply(char)
						if degraded[key] ~= (not okApply) then
							degraded[key] = not okApply
							if not okApply then notifyDegraded(key) end
						end
					end
				end
			end
			appearanceTicks += 1
			return
		end
		local worked = false
		for key, apply in pairs(appearanceAppliers) do
			if state[key] and apply(char) then worked = true end
		end
		if worked then appearanceTicks += 1 end
	end
	local function highlightTarget(part, duration)
		if not part or destroyed then return nil end
		local life = tonumber(duration)
		if not life or life ~= life or life == math.huge or life == -math.huge then life = 2 end
		local box
		local ok = pcall(function()
			box = Instance.new("SelectionBox")
			box.Adornee, box.Parent = part, part
			box.LineThickness, box.SurfaceTransparency = 0.05, 0.7
			box.Color3 = Color3.fromRGB(255, 60, 60)
		end)
		if not ok or destroyed then
			if box then pcall(function() box:Destroy() end) end
			return nil
		end
		objects[box] = clock() + math.clamp(life, 0.1, 30)
		ensureLoop()
		return box
	end
	local function nearestKiller()
		local char = LocalPlayer.Character
		local me = char and char:FindFirstChild("HumanoidRootPart")
		local folder = Workspace:FindFirstChild("Players")
		local killers = folder and folder:FindFirstChild("Killers")
		if not (me and killers) then return nil end
		local best, distance = nil, markerRange
		for _, model in ipairs(killers:GetChildren()) do
			local root, hum = model:FindFirstChild("HumanoidRootPart"), model:FindFirstChildOfClass("Humanoid")
			if root and root:IsA("BasePart") and hum and hum.Health > 0 then
				local d = (root.Position - me.Position).Magnitude
				if d < distance then best, distance = root, d end
			end
		end
		return best
	end
	local function active()
		for _, value in pairs(state) do if value then return true end end
		return next(objects) ~= nil
	end
	ensureLoop = function()
		if connection or destroyed or not active() then return end
		connection = RunService.RenderStepped:Connect(function(dt)
			local now = clock()
			for inst, expiry in pairs(objects) do
				local ok, parent = pcall(function() return inst.Parent end)
				if not ok or not parent or now >= expiry then
					objects[inst] = nil
					pcall(function() inst:Destroy() end)
				end
			end
			if now >= nextLighting then
				nextLighting = now + visualInterval(0.5)
				syncLighting()
			end
			if state.Marker and now >= nextMarker then
				nextMarker = now + visualInterval(2)
				local target = nearestKiller()
				if target then highlightTarget(target, 2) end
			end
			if state.Performance then
				frameCount += 1; frameTime += dt or 0
				if now >= nextReport and frameTime > 0 then
					fps = frameCount / frameTime
					nextReport = now + visualInterval(1)
					if performanceRow then performanceRow:SetDesc(("FPS %.1f / 帧耗时 %.1f ms"):format(fps, frameTime * 1000 / frameCount)) end
					frameCount, frameTime = 0, 0
				end
			end
			if now >= nextAppearance then
				nextAppearance = now + visualInterval(APPEARANCE_INTERVAL)
				enforceAppearance()
			end
			if not active() and connection then connection:Disconnect(); connection = nil end
		end)
		track(connection)
	end
	local function unbindResourceRemoving()
		if resourceRemovingConnection then pcall(function() resourceRemovingConnection:Disconnect() end); resourceRemovingConnection = nil end
		resourceRemovingChar = nil
	end
	local function bindResourceRemoving()
		if resourceRemovingConnection or destroyed then return end
		local signal = LocalPlayer and LocalPlayer.CharacterRemoving
		if not signal then return end
		local ok, candidate = pcall(function() return signal:Connect(function(old)
			if destroyed then return end
			resourceRemovingChar = old
			restoreResources()
			nextAppearance = -math.huge
		end) end)
		if ok and candidate then
			if destroyed or not state.Resources then pcall(function() candidate:Disconnect() end)
			else resourceRemovingConnection = candidate; track(candidate) end
		end
	end
	local function setVisual(key, value)
		if destroyed or state[key] == nil then return end
		state[key] = value == true
		if key == "Resources" and value == true then
			state.Skin = false; restoreSkin()
			if localSkinToggle then pcall(function() localSkinToggle:SetValue(false) end) end
			if destroyed or not state.Resources then return end
			bindResourceRemoving()
		elseif key == "Skin" and value == true and state.Resources then
			state.Resources = false; restoreResources(); unbindResourceRemoving(); degraded.Resources = nil
			if resourceToggle then pcall(function() resourceToggle:SetValue(false) end) end
			if destroyed or not state.Skin then return end
		end
		if key == "Resources" and value ~= true then unbindResourceRemoving() end
		if key == "Marker" then
			_G.VortexionTargetMarker = value or nil
			if not value then clearMarkers() end
			nextMarker = -math.huge
		end
		if key == "Performance" then frameCount, frameTime, nextReport = 0, 0, clock() + 1 end
		if appearanceAppliers[key] then
			if value == true then
				appearanceChar = character()
				local okApply = appearanceAppliers[key](appearanceChar)
				if degraded[key] ~= (not okApply) then
					degraded[key] = not okApply
					if not okApply then notifyDegraded(key) end
				end
				bindRespawn()
			else
				pcall(appearanceRestorers[key])
				degraded[key] = nil
			end
			nextAppearance = -math.huge
		end
		syncLighting(); ensureLoop()
		if not active() and connection then connection:Disconnect(); connection = nil end
	end
	local function applyFullbright() setVisual("Fullbright", true) end
	local function restoreLighting() setVisual("Fullbright", false) end
	local function refreshResourceProfile()
		if destroyed then return end
		restoreResources()
		if state.Resources then setVisual("Resources", true) end
	end
	local function setResourceAudio(value)
		if destroyed or resourceAudioEnabled == (value == true) then return end
		resourceAudioEnabled = value == true
		if resourceRecord then
			stopResourceAudio(resourceRecord)
			if not resourceAudioEnabled and not resourceProfiles[resourceRecord.profile].PulseAnimation then unbindResourceAction(resourceRecord) end
		end
		if resourceAudioEnabled and state.Resources then refreshResourceProfile() end
	end
	local function setResourceProfile(value)
		if destroyed or type(value) ~= "string" or (value ~= "无" and not resourceProfiles[value]) or value == resourceProfile then return end
		resourceProfile = value
		refreshResourceProfile()
	end
	local function setResourceEnabled(value)
		setVisual("Resources", value)
	end
	local function getResourceStatus()
		local status = resourceProfile .. "：" .. resourceStatus
		if resourceRecord and resourceProfiles[resourceRecord.profile].HideSwordParticles then status ..= "；" .. (resourceRecord.worldStatus or "等待 Map.Ingame") end
		if resourceRecord and resourceRecord.particleFailed then status ..= "（部分粒子着色失败，重新应用可重试）" end
		if resourceRecord and resourceProfiles[resourceRecord.profile].PulseAnimation then status ..= "；动作监听：" .. (resourceRecord.actionStatus or "等待 Animator") end
		if resourceAudioEnabled then status ..= "；" .. (resourceRecord and resourceRecord.audioStatus or "本地音效等待方案") end
		return status
	end
	local function previewResourceAudio()
		local record = resourceRecord
		if not record or not queueResourceAudio(record, resourceAudioChoice, 0) then return false, "先启用角色方案和本地音效，并放置对应 TerioThings 文件；角色需存活" end
		ensureLoop()
		return true, "仅预览本地音效，未执行技能"
	end
	local function pulseResourceEffect()
		local record = resourceRecord
		if not record or record.disposed or not resourceCurrent(record.serial, record.char) or not record.pulseHandle then
			return false, "先启用并载入 Sil / 鞭影衣饰"
		end
		if record.pulseStarted then return false, "鞭影显隐进行中，无需重复触发" end
		if not beginResourcePulse(record) then return false, "鞭影资源已失效或被新动作接管，重新应用后重试" end
		nextAppearance = -math.huge
		ensureLoop()
		return true, "本地鞭影淡入淡出，未触发实际技能"
	end
	local function cleanupVisual()
		for key in pairs(state) do state[key] = false end
		if connection then connection:Disconnect(); connection = nil end
		restoreBaseline(); baseline = nil
		restoreEffects(); clearMarkers()
		-- 外观与角色监听同步恢复，不等下一 tick
		for _, restore in pairs(appearanceRestorers) do pcall(restore) end
		for key in pairs(degraded) do degraded[key] = nil end
		appearanceChar = nil
		nextAppearance = -math.huge
		if respawnConnection then
			respawnConnection:Disconnect()
			respawnConnection = nil
		end
		unbindResourceRemoving()
		_G.VortexionTargetMarker = nil
	end
	local function destroy() if destroyed then return end; destroyed = true; cleanupVisual() end
	if Tabs and Tabs.Visual then
		local tab = Tabs.Visual
		tab:AddToggle("VisualFullbrightSafe", {Title = "全亮模式（原值可恢复）", Default = false, Callback = function(v) setVisual("Fullbright", v) end})
		tab:AddToggle("VisualTargetMarker", {Title = "最近杀手临时标记（2 秒自毁）", Default = false, Callback = function(v) setVisual("Marker", v) end})
		tab:AddToggle("VisualNoFog", {Title = "移除距离雾（可恢复）", Default = false, Callback = function(v) setVisual("Fog", v) end})
		tab:AddToggle("VisualNoPostEffects", {Title = "关闭后处理（含当前相机；可恢复）", Default = false, Callback = function(v) setVisual("Effects", v) end})
		tab:AddSlider("VisualMarkerRange", {Title = "临时标记范围", Default = 40, Min = 10, Max = 150, Rounding = 0, Callback = function(v) markerRange = v end})
		tab:AddParagraph({Title = "本地外观（默认关，资源缺失自动降级）", Content = "只改本机角色：Life1/Life2 部件、ExtraModels、Highlight、Assets.Skins.Survivors 本地皮肤与缩放。关闭或销毁立即恢复，重生后下一帧重新应用，不受低档位延迟。"})
		tab:AddToggle("VisualLifeHidden", {Title = "隐藏 Life1 / Life2 部件", Default = false, Callback = function(v) setVisual("Life12", v) end})
		tab:AddToggle("VisualKillerExtrasHidden", {Title = "隐藏 ExtraModels 附加模型", Default = false, Callback = function(v) setVisual("Extras", v) end})
		tab:AddToggle("VisualCharHighlight", {Title = "调节本地 Highlight 透明度", Default = false, Callback = function(v) setVisual("Highlight", v) end})
		tab:AddSlider("VisualCharHighlightFill", {Title = "Highlight 填充透明度（%）", Default = 50, Min = 0, Max = 100, Rounding = 0, Callback = function(v)
			highlightFill = math.clamp(v, 0, 100) / 100
			if state.Highlight then setVisual("Highlight", true) end
		end})
		localSkinToggle = tab:AddToggle("VisualLocalSkin", {Title = "应用本地皮肤（Assets.Skins.Survivors）", Default = false, Callback = function(v) setVisual("Skin", v) end})
		local function selectSkin(v)
			if destroyed then return end
			local name = tostring(v or "")
			if name == skinName then return end
			skinName = name
			if state.Skin then restoreSkin(); setVisual("Skin", true) end
		end
		local skinNameInput = tab:AddInput("VisualLocalSkinName", {Title = "皮肤名（留空则降级跳过）", Default = "", Callback = selectSkin})
		-- 皮肤下拉与刷新：初始仅占位；刷新读取当前角色已证实的直接子级，仅列存在资源，不自动扫描/启用
		local skinPlaceholder = "（未选择，先点刷新）"
		local skinChoiceChar = nil
		local skinChoiceNames = {}
		local skinChoiceOption = tab:AddDropdown("VisualLocalSkinChoice", {
			Title = "本地皮肤选择（刷新后可选）",
			Values = {skinPlaceholder},
			Default = skinPlaceholder,
			Callback = function(v)
				if destroyed then return end
				if type(v) ~= "string" or not skinChoiceNames[v] then return end
				-- 白名单所属角色缺失或已换角色时不应用旧选择
				local char = character()
				if not char or skinChoiceChar ~= char then return end
				selectSkin(v)
				if destroyed then return end
				if skinNameInput and type(skinNameInput.SetValue) == "function" then
					pcall(function() skinNameInput:SetValue(skinName) end)
				end
			end,
		})
		tab:AddButton({
			Title = "刷新当前角色皮肤",
			Callback = function()
				if destroyed then return end
				local char = character()
				if not char then
					skinChoiceChar, skinChoiceNames = nil, {}
					if skinChoiceOption and type(skinChoiceOption.SetValues) == "function" then
						pcall(function() skinChoiceOption:SetValues({skinPlaceholder}) end)
					end
					notifyDegraded("Skin"); return
				end
				local ok, names = pcall(function()
					local storage = game:GetService("ReplicatedStorage")
					local assets = storage and storage:FindFirstChild("Assets")
					local skins = assets and assets:FindFirstChild("Skins")
					local survivors = skins and skins:FindFirstChild("Survivors")
					local folder = survivors and survivors:FindFirstChild(char.Name)
					if not folder then return nil end
					local seen, list = {}, {}
					for _, child in ipairs(folder:GetChildren()) do
						if not seen[child.Name] then seen[child.Name] = true; table.insert(list, child.Name) end
					end
					table.sort(list)
					return list
				end)
				-- Failed reads can arrive after teardown too; fence both result paths.
				if destroyed or char ~= character() then return end
				if not ok or type(names) ~= "table" or #names == 0 then
					skinChoiceChar, skinChoiceNames = nil, {}
					if skinChoiceOption and type(skinChoiceOption.SetValues) == "function" then
						pcall(function() skinChoiceOption:SetValues({skinPlaceholder}) end)
					end
					notifyDegraded("Skin"); return
				end
				local allowed = {}
				for _, name in ipairs(names) do allowed[name] = true end
				table.insert(names, 1, skinPlaceholder)
				skinChoiceChar, skinChoiceNames = nil, {}
				if not skinChoiceOption or type(skinChoiceOption.SetValues) ~= "function" then return end
				local refreshed, accepted = pcall(function() return skinChoiceOption:SetValues(names) end)
				if destroyed or char ~= character() then return end
				-- Do not trust an exception-free queued or failed menu refresh.
				if refreshed and accepted == true then skinChoiceChar, skinChoiceNames = char, allowed end
			end,
		})
		tab:AddParagraph({Title = "角色资源方案（本地）", Content = "使用已核对的目录资源或游戏内模型，不执行资产脚本。均为本地外观组件，不含整套技能与特效；Sil 衣饰需 R6 左右臂挂点；鞭影衣饰可跟随指定动作，也可手动预览；TwoTime / 1x4外观需本地 Milestone100TwoTime 的完整 R6 Life1。与本地皮肤互斥，关闭恢复原物件，失败可重新应用。"})
		-- 方案列表从数据表派生：后续新增 Azure 等 profile 只改 resourceProfiles，下拉自动同步
		local profileValues = {"无"}
		local profileNames = {}
		for name in pairs(resourceProfiles) do table.insert(profileNames, name) end
		table.sort(profileNames)
		for _, name in ipairs(profileNames) do table.insert(profileValues, name) end
		tab:AddDropdown("AppearanceProfile", {Title = "角色资源方案", Values = profileValues, Default = "无", Callback = function(v) if not destroyed then setResourceProfile(v) end end})
		resourceToggle = tab:AddToggle("AppearanceProfileEnabled", {Title = "启用角色资源方案", Default = false, Callback = function(v) if not destroyed then setResourceEnabled(v) end end})
		tab:AddButton({Title = "重新应用角色方案", Callback = function() if not destroyed then refreshResourceProfile() end end})
		tab:AddToggle("AppearanceLocalAudio", {Title = "资源动作本地音效（需 TerioThings 文件）", Default = false, Callback = function(v) setResourceAudio(v) end})
		tab:AddDropdown("AppearanceAudioClip", {Title = "本地音效预览", Values = {"挥鞭", "斩击", "凝血"}, Default = "挥鞭", Callback = function(v) if not destroyed and resourceSoundDefs[v] then resourceAudioChoice = v end end})
		tab:AddButton({Title = "播放所选本地音效（非技能）", Callback = function()
			if destroyed then return end
			local _, message = previewResourceAudio()
			pcall(function() Fluent:Notify({Title = "本地音效", Content = message, Duration = 5}) end)
		end})
		tab:AddButton({Title = "预览 Sil 鞭影（仅本地显隐）", Callback = function()
			if destroyed then return end
			local _, message = pulseResourceEffect()
			pcall(function() Fluent:Notify({Title = "鞭影预览", Content = message, Duration = 5}) end)
		end})
		tab:AddButton({Title = "角色方案状态", Callback = function()
			if destroyed then return end
			pcall(function() Fluent:Notify({Title = "角色资源", Content = getResourceStatus(), Duration = 5}) end)
		end})
		tab:AddToggle("VisualCharScale", {Title = "本地角色缩放", Default = false, Callback = function(v) setVisual("Scale", v) end})
		tab:AddSlider("VisualCharScaleValue", {Title = "缩放值", Default = 1.06, Min = 0.5, Max = 2, Rounding = 0.01, Callback = function(v)
			scaleValue = v
			if state.Scale then setVisual("Scale", true) end
		end})
		tab:AddToggle("VisualCharScaleRestoreOriginal", {Title = "关闭缩放时恢复角色原值", Default = true, Callback = function(v) restoreOriginalScale = v == true end})
		tab:AddSlider("VisualCharScaleBase", {Title = "手动恢复缩放（关闭原值恢复时生效）", Default = 1, Min = 0.5, Max = 2, Rounding = 0.01, Callback = function(v) scaleBase = v end})
	end
	if Tabs and Tabs.Stats then
		performanceRow = Tabs.Stats:AddParagraph({Title = "客户端渲染性能", Content = "启用下方开关后每秒更新；不替代既有统计。"})
		Tabs.Stats:AddToggle("VisualPerformance", {Title = "显示 FPS / 帧耗时", Default = false, Callback = function(v) setVisual("Performance", v) end})
	end
	return {isLocalCharacter = isLocalCharacter, findOrCreateByModel = findOrCreateByModel, highlightTarget = highlightTarget, applyFullbright = applyFullbright, restoreLighting = restoreLighting, cleanupVisual = cleanupVisual, setVisual = setVisual, nearestKiller = nearestKiller, getFPS = function() return fps end, getVisualInterval = visualInterval, appearanceTicks = function() return appearanceTicks end, isDegraded = function(key) return degraded[key] == true end, setResourceProfile = setResourceProfile, setResourceEnabled = setResourceEnabled, refreshResourceProfile = refreshResourceProfile, getResourceStatus = getResourceStatus, pulseResourceEffect = pulseResourceEffect, setResourceAudio = setResourceAudio, previewResourceAudio = previewResourceAudio, Destroy = destroy}
end
end)()
local ForsakenSurvivalFactory = (function()
-- Vortexion - Forsaken · 生存组模块 (Survival Group)
-- 借鉴来源: forsakenMenu main.lua (safePos) / Auto-Block-V4 (无限体力单例) /
--           Auto-Backstab-V3 (killerTrack 清理) / forsaken_hub (InfStamina 防重入)
return function(ctx)
	local Players = ctx.Players
	local LocalPlayer = ctx.LocalPlayer
	local RunService = ctx.RunService
	local Workspace = ctx.Workspace
	local track = ctx.track
	local Fluent = ctx.Fluent
	local Tabs = ctx.Tabs
	local sessionEnv = ctx.sessionEnv
	local thisSessionId = ctx.thisSessionId

	local function notify(title, content)
		if Fluent then
			pcall(function()
				Fluent:Notify({ Title = title, Content = content, Duration = 5 })
			end)
		end
	end

	---------------------------------------------------------------------------
	-- 无限体力: 单例协程 + enabled 门 + 字段门
	-- (修附件 Auto-Block-V4:96-102 CharacterAdded 重复调用的协程累积)
	---------------------------------------------------------------------------
	local staminaConn, cachedChar, cachedSource, cachedModule = nil, nil, nil, nil
	local staminaActive, loading, destroyed = false, false, false
	local generation, staminaTarget = 0, 100
	local clock = ctx.clock or os.clock
	local savedStamina = {}
	local function restoreStamina()
		for mod, props in pairs(savedStamina) do
			for key, value in pairs(props) do
				pcall(function()
					if key == "Stamina" and type(mod.SetStamina) == "function" then mod:SetStamina(value) else mod[key] = value end
				end)
			end
		end
		table.clear(savedStamina)
	end
	local function staminaSource(char)
		local source = char and char:FindFirstChild("Stamina")
		if source then return source end
		local folder = game:GetService("ReplicatedStorage")
		for _, name in ipairs({"Systems", "Character", "Game", "Sprinting"}) do
			folder = folder and folder:FindFirstChild(name)
		end
		return folder
	end
	local function getStaminaModule()
		if destroyed then return nil end
		local char = LocalPlayer and LocalPlayer.Character
		if not char then
			if cachedChar then
				restoreStamina(); generation += 1
				loading, cachedChar, cachedSource, cachedModule = false, nil, nil, nil
			end
			return nil
		end
		local source = staminaSource(char)
		if char ~= cachedChar or source ~= cachedSource then
			restoreStamina()
			generation += 1
			loading, cachedModule = false, nil
			cachedChar, cachedSource = char, source
		end
		if cachedModule then return cachedModule end
		if not source or loading then return nil end
		loading = true
		local token = generation
		task.spawn(function()
			local ok, mod = pcall(ctx.requireModule or require, source)
			if token ~= generation then return end
			loading = false
			if ok and type(mod) == "table" then cachedModule = mod end
		end)
		return cachedModule
	end
	local function stopInfiniteStamina()
		staminaActive = false
		generation += 1
		loading = false
		if staminaConn then staminaConn:Disconnect(); staminaConn = nil end
		restoreStamina()
	end
	local function startInfiniteStamina()
		stopInfiniteStamina()
		if destroyed then return end
		staminaActive = true
		local nextAt = -math.huge
		staminaConn = RunService.Heartbeat:Connect(function()
			if not staminaActive or clock() < nextAt then return end
			nextAt = clock() + 0.2
			local mod = getStaminaModule()
			if not mod then return end
			if not savedStamina[mod] then
				local saved = {}
				for _, key in ipairs({"Stamina", "StaminaLossDisabled"}) do
					if mod[key] ~= nil then saved[key] = mod[key] end
				end
				savedStamina[mod] = saved
			end
			pcall(function()
				local maximum = type(mod.MaxStamina) == "number" and mod.MaxStamina or 100
				local value = math.clamp(staminaTarget, 0, maximum)
				if mod.StaminaLossDisabled ~= nil then mod.StaminaLossDisabled = true end
				if type(mod.Stamina) == "number" then
					if type(mod.SetStamina) == "function" then mod:SetStamina(value) else mod.Stamina = value end
				end
			end)
		end)
		track(staminaConn)
	end

	---------------------------------------------------------------------------
	-- killerTrack 自动清理: 附件 Auto-Backstab-V3:66 永续累积的内存泄漏
	---------------------------------------------------------------------------
	local killerTrack = {}
	local killerTrackAge = {}

	local function pruneKillerTrack()
		local now = os.clock()
		for hrp, data in pairs(killerTrack) do
			local stale = (not hrp.Parent) or (not data.pos)
			if killerTrackAge[hrp] and now - killerTrackAge[hrp] > 5 then stale = true end
			if stale then
				killerTrack[hrp] = nil
				killerTrackAge[hrp] = nil
			end
		end
	end

	local function trackKiller(hrp)
		if not (hrp and hrp:IsA("BasePart")) then return end
		if not killerTrack[hrp] then
			killerTrack[hrp] = { pos = hrp.Position, vel = Vector3.zero }
			killerTrackAge[hrp] = os.clock()
		else
			local d = killerTrack[hrp]
			local now = hrp.Position
			d.vel = (now - d.pos) / math.max(os.clock() - killerTrackAge[hrp], 0.016)
			d.pos = now
			killerTrackAge[hrp] = os.clock()
		end
	end

	---------------------------------------------------------------------------
	-- 安全传送点: GetTouchingParts + CanCollide + IsDescendantOf 三门
	-- 附件 forsakenMenu main.lua:341-351
	---------------------------------------------------------------------------
	local function isSafePosition(char, pos)
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") or typeof(pos) ~= "Vector3" then return false end
		if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z or pos.Magnitude == math.huge then return false end
		if pos.Y <= Workspace.FallenPartsDestroyHeight + 10 then return false end
		local ok, clear = pcall(function()
			local params = OverlapParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = {char}
			params.RespectCanCollide = true
			for _, part in ipairs(Workspace:GetPartBoundsInBox(CFrame.new(pos), root.Size, params)) do
				if part.CanCollide and not part:IsDescendantOf(char) then return false end
			end
			local ray = RaycastParams.new()
			ray.FilterType = Enum.RaycastFilterType.Exclude
			ray.FilterDescendantsInstances = {char}
			ray.RespectCanCollide = true
			return Workspace:Raycast(pos, Vector3.new(0, -(root.Size.Y / 2 + 6), 0), ray) ~= nil
		end)
		return ok and clear == true
	end
	local safeCFrame, safeCharacter = nil, nil
	local safeTp = true
	local function saveSafePoint()
		if destroyed then return false, "模块已关闭" end
		local char = LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root or not isSafePosition(char, root.Position) then return false, "当前点碰撞或无地面" end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then return false, "角色未存活" end
		safeCFrame, safeCharacter = root.CFrame, char
		return true
	end
	local function returnSafePoint()
		local char = LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if destroyed or not safeCFrame or safeCharacter ~= char or not root or not hum or hum.Health <= 0 then
			return false, "本角色尚未保存点"
		end
		if safeTp and not isSafePosition(char, safeCFrame.Position) then return false, "保存点已被阻挡" end
		root.CFrame = safeCFrame
		root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		return true
	end
	local function findTrickBehavior()
		local ok, behavior = pcall(function()
			local storage = game:GetService("ReplicatedStorage")
			local assets = storage:FindFirstChild("Assets")
			local survivors = assets and assets:FindFirstChild("Survivors")
			local veeronica = survivors and survivors:FindFirstChild("Veeronica")
			return veeronica and veeronica:FindFirstChild("Behavior")
		end)
		if ok then return behavior end
	end
	local function findTrickButton()
		local ok, button = pcall(function()
			local gui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
			local main = gui and gui:FindFirstChild("MainUI")
			return main and main:FindFirstChild("SprintingButton")
		end)
		if ok then return button end
	end
	local function trickMatchesCharacter(highlight, character)
		local ok, result = pcall(function()
			if not highlight or not character then return false end
			if not highlight.Parent or not character.Parent then return false end
			local adornee = highlight.Adornee
			if not adornee then return false end
			if adornee == character then return true end
			return adornee:IsDescendantOf(character)
		end)
		return ok and result == true
	end
	local function invokeTrickSprint(button, isCurrent)
		local getConnections = type(ctx.getConnections) == "function" and ctx.getConnections or getconnections
		if type(getConnections) ~= "function" then return false, "当前环境缺少按钮回调枚举" end
		local okList, connections = pcall(function() return getConnections(button.MouseButton1Down) end)
		if not okList or type(connections) ~= "table" then return false, "按钮回调读取失败" end
		local function member(object, key)
			local ok, value = pcall(function() return object[key] end)
			if ok then return value end
		end
		local invoked, seen = false, {}
		for _, connection in ipairs(connections) do
			local okNow, current = pcall(isCurrent)
			if not okNow or not current then break end
			if not seen[connection] then
				seen[connection] = true
				local okRun, ran = pcall(function()
					if member(connection, "Connected") == false or member(connection, "Enabled") == false then return false end
					local fire = member(connection, "Fire")
					if type(fire) == "function" then if isCurrent() then fire(connection); return true end; return false end
					local callback = member(connection, "Function")
					if type(callback) == "function" and isCurrent() then callback(); return true end
					return false
				end)
				if okRun and ran then invoked = true end
			end
		end
		if not invoked then return false, "本次没有触发可用回调" end
		return true
	end

	local function formatTrickStatus(s)
		return ("开关: %s | 模式: %s | 状态: %s | 监控: %d | 尝试/成功/失败/去重: %d/%d/%d/%d | 间隔: %d ms"):format(
			s.enabled and "开" or "关", s.touchOnly and "仅触屏" or "不限设备", s.status,
			s.monitors, s.attempts, s.successes, s.failures, s.debounced, s.debounceMs)
	end
	-- Auto-Trick owns its listeners; disabling leaves no frame or resource scans.
	local trickEnabled, trickTouchOnly, trickDebounce = false, true, 0.15
	local trickEpoch, trickFolder, trickCharacter, trickRemovedCharacter = 0, nil, nil, nil
	local trickMonitors, trickConnections, trickFolderConnections = {}, {}, {}
	local trickNextProbe, trickLastAt, trickMessage = 0, -math.huge, "已关闭"
	local trickAttempts, trickSuccesses, trickFailures, trickDebounced = 0, 0, 0, 0
	local function disconnectTrickConnections(bucket)
		for i = #bucket, 1, -1 do
			local connection = bucket[i]; bucket[i] = nil
			pcall(function() connection:Disconnect() end)
		end
	end
	local function trickSessionCurrent()
		return not destroyed and (not sessionEnv or thisSessionId == nil or sessionEnv.VortexionSessionId == thisSessionId)
	end
	local function removeTrickMonitor(highlight, record)
		if trickMonitors[highlight] ~= record then return end
		trickMonitors[highlight] = nil
		disconnectTrickConnections(record.connections)
	end
	local function clearTrickFolder()
		trickFolder = nil
		disconnectTrickConnections(trickFolderConnections)
		for highlight, record in pairs(trickMonitors) do removeTrickMonitor(highlight, record) end
	end
	local function stopAutoTrick()
		trickEnabled = false; trickEpoch += 1
		clearTrickFolder(); disconnectTrickConnections(trickConnections)
		trickCharacter, trickRemovedCharacter, trickMessage = nil, nil, "已关闭"
	end
	local function connectTrick(bucket, signal, callback, current)
		local ok, connection = pcall(function() return signal:Connect(callback) end)
		if not ok or not connection then return false end
		if not current() then pcall(function() connection:Disconnect() end); return false end
		table.insert(bucket, connection)
		return true
	end
	local function trickTouchReady()
		if not trickTouchOnly then return true end
		local ok, value = pcall(function()
			local input = ctx.UserInputService or game:GetService("UserInputService")
			return input.TouchEnabled
		end)
		return ok and value == true
	end
	local function watchTrickHighlight(highlight)
		local folder, epoch = trickFolder, trickEpoch
		local ok, valid = pcall(function() return highlight:IsA("Highlight") and highlight:IsDescendantOf(folder) end)
		if not ok or not valid or trickMonitors[highlight] then return end
		local record = {previous = false, connections = {}}
		trickMonitors[highlight] = record
		local function current()
			return trickEnabled and trickSessionCurrent() and epoch == trickEpoch and folder == trickFolder and trickMonitors[highlight] == record
		end
		local function evaluate()
			if not current() then return end
			local alive, inside = pcall(function() return highlight:IsDescendantOf(folder) end)
			if not alive or not inside then removeTrickMonitor(highlight, record); return end
			local character = trickCharacter
			local matches = character == LocalPlayer.Character and trickMatchesCharacter(highlight, character)
			local rising = matches and (not record.previous or record.pending == true)
			record.previous, record.pending = matches, false
			if not rising then return end
			if not trickTouchReady() then trickMessage = "当前不是触屏设备"; return end
			local now = clock()
			if now - trickLastAt < trickDebounce then trickDebounced += 1; return end
			local button = findTrickButton()
			if not button then record.pending = true; trickMessage = "等待冲刺按钮"; return end
			trickLastAt = now; trickAttempts += 1
			local function canInvoke()
				return current() and character == trickCharacter and character == LocalPlayer.Character
					and findTrickBehavior() == folder and findTrickButton() == button and trickTouchReady()
					and trickMatchesCharacter(highlight, character)
			end
			local success, reason = invokeTrickSprint(button, canInvoke)
			if not current() then return end
			if success then trickSuccesses += 1; trickMessage = "已触发本地冲刺回调"
			else trickFailures += 1; trickMessage = reason end
		end
		record.evaluate = evaluate
		local allocated, ready = pcall(function()
			return connectTrick(record.connections, highlight:GetPropertyChangedSignal("Adornee"), evaluate, current)
				and connectTrick(record.connections, highlight.AncestryChanged, evaluate, current)
		end)
		if not allocated or not ready or not current() then removeTrickMonitor(highlight, record); return end
		evaluate()
	end
	local function probeAutoTrick()
		if not trickEnabled or not trickSessionCurrent() then return end
		local character = LocalPlayer.Character
		if character == trickRemovedCharacter then character = nil end
		local changedCharacter = trickCharacter ~= character
		if changedCharacter then
			trickCharacter, trickLastAt = character, -math.huge
			for _, record in pairs(trickMonitors) do record.previous = false end
		end
		local folder = findTrickBehavior()
		if not folder then
			if trickFolder then clearTrickFolder() end
			trickMessage = "等待 Veeronica 行为资源"; return
		end
		if folder == trickFolder then
			for _, record in pairs(trickMonitors) do if changedCharacter or record.pending then record.evaluate() end end
			return
		end
		clearTrickFolder()
		trickFolder = folder
		local epoch = trickEpoch
		local function current() return trickEnabled and trickSessionCurrent() and epoch == trickEpoch and trickFolder == folder end
		local ok, ready = pcall(function()
			return connectTrick(trickFolderConnections, folder.DescendantAdded, watchTrickHighlight, current)
		end)
		if not ok or not ready then clearTrickFolder(); trickMessage = "资源监听暂不可用"; return end
		local listed, descendants = pcall(function() return folder:GetDescendants() end)
		if not listed or not current() then if current() then clearTrickFolder() end; return end
		trickMessage = "监听中"
		for _, descendant in ipairs(descendants) do
			if not current() then break end
			watchTrickHighlight(descendant)
		end
	end
	local function refreshAutoTrick()
		if destroyed then return end
		clearTrickFolder(); trickNextProbe = 0
		probeAutoTrick()
	end
	local function setAutoTrick(enabled)
		if destroyed or not trickSessionCurrent() then return end
		if enabled == trickEnabled then return end
		stopAutoTrick()
		if not enabled then return end
		trickEnabled = true; trickLastAt = -math.huge; trickNextProbe = 0
		trickCharacter = LocalPlayer.Character
		local epoch = trickEpoch
		local function current() return trickEnabled and trickSessionCurrent() and epoch == trickEpoch end
		local function characterChanged(character)
			if not current() then return end
			trickRemovedCharacter, trickCharacter, trickLastAt = nil, character, -math.huge
			for _, record in pairs(trickMonitors) do record.previous = false; record.evaluate() end
			trickNextProbe = 0
		end
		local ok, ready = pcall(function()
			if not connectTrick(trickConnections, LocalPlayer.CharacterAdded, characterChanged, current) then return false end
			if LocalPlayer.CharacterRemoving and not connectTrick(trickConnections, LocalPlayer.CharacterRemoving, function(character)
				if not current() then return end
				trickRemovedCharacter = character; trickCharacter = nil
				for _, record in pairs(trickMonitors) do record.previous = false end
			end, current) then return false end
			return connectTrick(trickConnections, RunService.Heartbeat, function()
				if not current() then if trickEnabled and epoch == trickEpoch then stopAutoTrick() end; return end
				local now = clock(); if now < trickNextProbe then return end
				trickNextProbe = now + 1; probeAutoTrick()
			end, current)
		end)
		if not ok or not ready then
			if epoch == trickEpoch then stopAutoTrick(); trickMessage = "生命周期监听暂不可用" end
			return
		end
		probeAutoTrick()
	end
	local function getTrickStatus()
		local count = 0; for _ in pairs(trickMonitors) do count += 1 end
		return {enabled = trickEnabled, touchOnly = trickTouchOnly, status = trickMessage, monitors = count,
			attempts = trickAttempts, successes = trickSuccesses, failures = trickFailures, debounced = trickDebounced,
			debounceMs = math.floor(trickDebounce * 1000 + 0.5)}
	end
	local function destroy()
		if destroyed then return end
		destroyed = true
		stopAutoTrick()
		stopInfiniteStamina()
		cachedModule, cachedSource, cachedChar, safeCFrame, safeCharacter = nil, nil, nil, nil, nil
		table.clear(killerTrack); table.clear(killerTrackAge)
	end

	---------------------------------------------------------------------------
	-- UI: 生存增强 (挂 Game tab)
	---------------------------------------------------------------------------
	if Tabs and Tabs.Survival then
		Tabs.Survival:AddToggle("SurvivalInfStaminaSafe", {
			Title = "无限体力（单例协程·防重生累积）",
			Default = false,
			Callback = function(state)
				if state then startInfiniteStamina() else stopInfiniteStamina() end
			end
		})

		Tabs.Survival:AddButton({
			Title = "清理失效杀手追踪缓存",
			Callback = function()
				local before = 0
				for _ in pairs(killerTrack) do before = before + 1 end
				pruneKillerTrack()
				local after = 0
				for _ in pairs(killerTrack) do after = after + 1 end
				notify("缓存清理", ("追踪条目 %d → %d"):format(before, after))
			end
		})
	end

	---------------------------------------------------------------------------
	-- UI: 生存增强 (挂 Blatant tab)
	---------------------------------------------------------------------------
	if Tabs and Tabs.Survival then
		Tabs.Survival:AddToggle("SurvivalSafeTp", {
			Title = "安全传送校验（碰撞检测）",
			Default = true,
			Callback = function(state)
				safeTp = state == true
				_G.VortexionSafeTp = state or nil
			end
		})
	end

	if Tabs and Tabs.Survival then
		Tabs.Survival:AddSlider("SurvivalStaminaTarget", {Title = "体力目标（上限由模块限制）", Default = 100, Min = 1, Max = 200, Rounding = 0, Callback = function(v) staminaTarget = v end})
		Tabs.Survival:AddButton({Title = "保存安全点（当前角色）", Callback = function()
			local ok, err = saveSafePoint(); notify("安全点", ok and "已保存" or err)
		end})
		Tabs.Survival:AddButton({Title = "返回保存点（重新校验）", Callback = function()
			local ok, err = returnSafePoint(); notify("安全点", ok and "已返回" or err)
		end})
	end

	if Tabs and Tabs.Survival then
		Tabs.Survival:AddToggle("SurvivalAutoTrick", {Title = "Auto-Trick（Veeronica）", Default = false, Callback = function(v) setAutoTrick(v == true) end})
		Tabs.Survival:AddToggle("SurvivalTrickTouchOnly", {Title = "Auto-Trick 仅触屏触发", Default = true, Callback = function(v)
			if destroyed then return end; trickTouchOnly = v == true
		end})
		Tabs.Survival:AddSlider("SurvivalTrickDebounceMs", {Title = "Auto-Trick 去重间隔 (ms)", Min = 0, Max = 1000, Default = 150, Rounding = 0, Callback = function(v)
			if destroyed then return end
			local n = tonumber(v)
			if not n or n ~= n or math.abs(n) == math.huge then return end
			trickDebounce = math.clamp(n, 0, 1000) / 1000
		end})
		Tabs.Survival:AddButton({Title = "刷新 Auto-Trick 资源", Callback = function() if not destroyed then refreshAutoTrick() end end})
		Tabs.Survival:AddButton({Title = "查看 Auto-Trick 状态", Callback = function()
			if not destroyed then notify("Auto-Trick", formatTrickStatus(getTrickStatus())) end
		end})
	end
	return {
		Destroy = destroy,
		setAutoTrick = setAutoTrick,
		refreshAutoTrick = refreshAutoTrick,
		getTrickStatus = getTrickStatus,
		saveSafePoint = saveSafePoint,
		returnSafePoint = returnSafePoint,
		getStaminaModule = getStaminaModule,
		startInfiniteStamina = startInfiniteStamina,
		stopInfiniteStamina = stopInfiniteStamina,
		trackKiller = trackKiller,
		pruneKillerTrack = pruneKillerTrack,
		isSafePosition = isSafePosition,
	}
end

end)()
local ForsakenGuestFactory = (function()
-- Vortexion - Forsaken · Guest 特权组模块 (Guest Group)
-- 借鉴来源: Auto-Trick (幂等/查重/cleanup 全库最佳实践) / Auto-Block-V4 (自定义动画) /
--           Fake-Block (char/Humanoid 双门) / forsaken_hub (防重复加载标志)
return function(ctx)
	local Players = ctx.Players
	local LocalPlayer = ctx.LocalPlayer
	local RunService = ctx.RunService
	local Workspace = ctx.Workspace
	local track = ctx.track
	local Fluent = ctx.Fluent
	local Tabs = ctx.Tabs
	local sessionEnv = ctx.sessionEnv

	local function notify(title, content)
		if Fluent then
			pcall(function()
				Fluent:Notify({ Title = title, Content = content, Duration = 5 })
			end)
		end
	end

	-- CoreGui 回退 PlayerGui: 附件 Fake-Block:7/:14
	local function getGuiHost()
		local ok, core = pcall(function() return game:GetService("CoreGui") end)
		if ok and core then
			local ok2, existing = pcall(function() return core:FindFirstChild("VortexionGuestGui") end)
			if ok2 then return core end
		end
		return LocalPlayer:FindFirstChild("PlayerGui")
	end

	-- 查重防双 GUI: 附件 Auto-Trick:165-167 + forsaken_hub:250
	local function ensureSingleGui(name)
		local host = getGuiHost()
		if not host then return nil end
		local existing = host:FindFirstChild(name)
		if existing then
			pcall(function() existing:Destroy() end)
		end
		return host
	end

	-- Keep the old lifecycle API and option ID, but let WindUI own all controls.
	local guestState = {}
	local playCustomAnim, stopAnimations
	local destroyed, fakeVariant = false, "Normal"
	-- 自定义动画播放参数：仅写局部量，影响下一次本地播放，不改现有 Track
	local animationSpeed, animationLoop = 100, false
	local function setEnabled(key, value)
		if guestState[key] == value then return end
		guestState[key] = value
	end

	local function destroyFakeBlockGui()
		guestState.FakeBlock = false
		if stopAnimations then stopAnimations() end
		ensureSingleGui("VortexionGuestGui")
		local option = Fluent and Fluent.Options and Fluent.Options.GuestFakeBlockGui
		if option and option.Value then option:SetValue(false) end
	end

	local function buildFakeBlockGui()
		ensureSingleGui("VortexionGuestGui")
		setEnabled("FakeBlock", true)
		local option = Fluent and Fluent.Options and Fluent.Options.GuestFakeBlockGui
		if option and not option.Value then option:SetValue(true) end
	end

	local function triggerFakeBlock()
		if not guestState.FakeBlock then
			notify("假格挡", "请先启用假格挡。")
			return
		end
		local char = LocalPlayer and LocalPlayer.Character
		local hum = char and char:FindFirstChild("Humanoid")
		if not (char and hum) then
			notify("假格挡", "角色或 Humanoid 未就绪")
			return
		end
		local id = fakeVariant == "M3 / M4" and "96959123077498" or "72722244508749"
		local ok, err = playCustomAnim(id)
		notify("假格挡", ok and "本地动画已播放" or tostring(err))
		return ok, err
	end

	ensureSingleGui("VortexionGuestGui")

	---------------------------------------------------------------------------
	-- 自定义动画安全播放: Animator/animId 门 + pcall LoadAnimation + 节流
	-- 附件 Auto-Block-V4:353-397 / Chance-V2:358-365
	---------------------------------------------------------------------------
	local clock = ctx.clock or os.clock
	local lastAnimAt = -math.huge
	local activeTrack, stoppedConn = nil, nil
	local disposedTracks = setmetatable({}, {__mode = "k"})
	local animationRevision = 0
	local function disposeTrack(current, connection)
		if connection then pcall(function() connection:Disconnect() end) end
		if current and not disposedTracks[current] then
			-- Stop may synchronously re-enter disposal through Stopped.
			disposedTracks[current] = true
			pcall(function() current:Stop(0.1) end)
			pcall(function() current:Destroy() end)
		end
	end
	local function clearActiveTrack()
		local current, connection = activeTrack, stoppedConn
		activeTrack, stoppedConn = nil, nil
		disposeTrack(current, connection)
	end
	stopAnimations = function()
		animationRevision += 1
		clearActiveTrack()
	end
	playCustomAnim = function(animId)
		if destroyed then return false, "模块已关闭" end
		if type(animId) ~= "string" then return false, "动画 ID 格式错误" end
		local id = animId:match("^rbxassetid://(%d+)$") or animId:match("^(%d+)$")
		if not id or tonumber(id) == 0 then return false, "请输入纯数字或 rbxassetid://数字" end
		if clock() - lastAnimAt < 0.35 then return false, "播放过于频繁" end
		local char, hum, animator
		local ready = pcall(function()
			char = LocalPlayer.Character
			hum = char and char:FindFirstChildOfClass("Humanoid")
			animator = hum and hum:FindFirstChildOfClass("Animator")
		end)
		if not ready or not hum or not animator then return false, "Animator 未就绪" end
		animationRevision += 1
		local revision = animationRevision
		local function current()
			local ok, value = pcall(function()
				return not destroyed and revision == animationRevision and LocalPlayer.Character == char
					and (not sessionEnv or ctx.thisSessionId == nil or sessionEnv.VortexionSessionId == ctx.thisSessionId)
					and char.Parent ~= nil and hum.Parent == char and hum.Health > 0 and animator.Parent == hum
			end)
			return ok and value == true
		end
		if not current() then return false, "角色已失效" end
		local animation, result
		local ok = pcall(function()
			animation = Instance.new("Animation")
			animation.AnimationId = "rbxassetid://" .. id
			result = animator:LoadAnimation(animation)
		end)
		if animation then pcall(function() animation:Destroy() end) end
		if not ok or not result then disposeTrack(result); return false, "LoadAnimation 失败" end
		if not current() then disposeTrack(result); return false, "播放请求已失效" end
		local stoppedEarly = false
		local connected, connection = pcall(function()
			return result.Stopped:Connect(function()
				stoppedEarly = true
				if activeTrack == result then stopAnimations() end
			end)
		end)
		if not connected or not connection or stoppedEarly or not current() then
			disposeTrack(result, connected and connection or nil)
			return false, "动画回收监听未就绪"
		end
		clearActiveTrack()
		if not current() or stoppedEarly then disposeTrack(result, connection); return false, "播放请求已失效" end
		activeTrack, stoppedConn = result, connection
		ok = pcall(function() result.Looped = animationLoop; result:Play(0.1, 1, animationSpeed / 100) end)
		if not ok or not current() or activeTrack ~= result or stoppedEarly then
			if activeTrack == result then stopAnimations() else disposeTrack(result, connection) end
			return false, "播放失败或请求已失效"
		end
		lastAnimAt = clock()
		return true
	end

	-- Local locomotion only: no movement parameters or server ability state are written.
	local locomotionProfiles = {
		["Terio"] = {Idle = "138598353840498", Walk = "136463880292090"},
		["TwoTime / 蹲伏"] = {Intro = "98606150731314", IntroDelay = 0.15, Idle = "74530436512522", Walk = "94721495253171"},
	}
	local locomotionEnabled, locomotionProfile, locomotionStatus = false, "Terio", "已关闭"
	local locomotionEpoch, locomotionChar, locomotionRemoving, locomotionAttempt = 0, nil, nil, nil
	local locomotionRecord, locomotionPending, locomotionStep, locomotionRemove, locomotionToggle, locomotionAttemptAnimator
	local locomotionReleaseDepth, locomotionToggleSync = 0, false
	local function releaseLocomotion(record)
		if not record or record.disposed then return end
		record.disposed = true
		locomotionReleaseDepth += 1
		local introConnection = record.introConnection
		record.introConnection = nil
		if introConnection then pcall(function() introConnection:Disconnect() end) end
		for _, current in pairs(record.tracks) do disposeTrack(current) end
		for animation in pairs(record.animations) do
			record.animations[animation] = nil
			pcall(function() animation:Destroy() end)
		end
		locomotionReleaseDepth -= 1
	end
	local function resetLocomotion()
		locomotionEpoch += 1
		local current, pending = locomotionRecord, locomotionPending
		locomotionRecord, locomotionPending, locomotionAttempt, locomotionChar, locomotionAttemptAnimator = nil, nil, nil, nil, nil
		releaseLocomotion(current); releaseLocomotion(pending)
	end
	local function locomotionCurrent(record)
		return not destroyed and locomotionEnabled and not record.disposed and record.epoch == locomotionEpoch
			and record.char == LocalPlayer.Character and record.char ~= locomotionRemoving and record.char.Parent ~= nil
			and record.hum.Parent == record.char and record.hum.Health > 0 and record.animator.Parent == record.hum
			and (not sessionEnv or ctx.thisSessionId == nil or sessionEnv.VortexionSessionId == ctx.thisSessionId)
	end
	local function finishLocomotionIntro(record, delay)
		record.introDone = true
		local intro, connection = record.tracks.Intro, record.introConnection
		record.tracks.Intro, record.introConnection = nil, nil
		disposeTrack(intro, connection)
		if not locomotionCurrent(record) then return false end
		local readyAt = delay and clock() + delay or nil
		if not locomotionCurrent(record) then return false end
		record.introReadyAt = readyAt
		return true
	end
	local function loadLocomotion(char, hum, animator)
		local profile = locomotionProfiles[locomotionProfile]
		local record = {char = char, hum = hum, animator = animator, epoch = locomotionEpoch, tracks = {}, animations = {}, introDelay = profile.IntroDelay}
		locomotionPending, locomotionAttempt, locomotionAttemptAnimator, locomotionStatus = record, char, animator, "载入中"
		local spawned = pcall(function() task.spawn(function()
			local ok = pcall(function()
				for _, name in ipairs({"Idle", "Walk", "Intro"}) do
					if profile[name] then
						assert(locomotionCurrent(record), "locomotion load cancelled")
						local animation = Instance.new("Animation")
						record.animations[animation] = true
						animation.AnimationId = "rbxassetid://" .. profile[name]
						local current = animator:LoadAnimation(animation)
						if record.animations[animation] then
							record.animations[animation] = nil
							pcall(function() animation:Destroy() end)
						end
						if not locomotionCurrent(record) then disposeTrack(current); error("late locomotion track") end
						assert(current, "locomotion track missing")
						record.tracks[name] = current
						current.Looped = name ~= "Intro"
						current.Priority = name == "Intro" and Enum.AnimationPriority.Action or (name == "Idle" and Enum.AnimationPriority.Idle or Enum.AnimationPriority.Movement)
					end
				end
				local intro = record.tracks.Intro
				if intro then
					local connected, candidate = pcall(function()
						return intro.Stopped:Connect(function()
							-- Latch only; disposal runs in the existing locomotion tick.
							if not destroyed and locomotionEnabled and not record.disposed and record.epoch == locomotionEpoch and record.introStarted and not record.introDone then record.introStopped = true end
						end)
					end)
					local readable, current = pcall(locomotionCurrent, record)
					if not connected or not candidate or not readable or not current then
						if connected and candidate then pcall(function() candidate:Disconnect() end) end
						error("locomotion intro listener cancelled")
					end
					record.introConnection = candidate
				end
				assert(locomotionCurrent(record), "locomotion commit stale")
				locomotionRecord = record
			end)
			if locomotionPending == record then locomotionPending = nil end
			if not ok then
				if locomotionRecord == record then locomotionRecord = nil end
				releaseLocomotion(record)
			end
			if not destroyed and locomotionEnabled and record.epoch == locomotionEpoch then
				locomotionStatus = ok and "已就绪" or "动画载入失败，点重新应用重试"
			end
		end) end)
		if not spawned then
			if locomotionPending == record then locomotionPending = nil end
			releaseLocomotion(record)
			if record.epoch == locomotionEpoch then locomotionStatus = "异步载入不可用" end
		end
	end
	local function driveLocomotion(record)
		if record.failed or not locomotionCurrent(record) then return end
		local hum = record.hum
		local phase = hum:GetState().Name
		local paused = activeTrack ~= nil or hum.Sit or hum.PlatformStand or phase == "Jumping" or phase == "Freefall"
			or phase == "Climbing" or phase == "Swimming" or phase == "Dead" or phase == "Seated"
		local intro = record.tracks.Intro
		if intro and not record.introDone then
			if record.introStarted then
				if paused then
					if not finishLocomotionIntro(record) then return end
				else
					local playing, expired = intro.IsPlaying, clock() >= record.introDeadline
					if record.introStopped or not playing or expired then
						record.introTimedOut = expired and playing and not record.introStopped
						if not finishLocomotionIntro(record, record.introDelay) then return end
					else locomotionStatus = "蹲伏起手"; return end
				end
			elseif not paused then
				-- A bounded local presentation, not the ability duration or cooldown.
				record.introDeadline = clock() + 8
				if not locomotionCurrent(record) then return end
				record.introStarted = true
				local ok = pcall(function() intro:Play(0.12, 1, 1) end)
				if not ok or not locomotionCurrent(record) then
					if not record.disposed then record.failed = true; locomotionStatus = "起手播放失败，点重新应用重试"; finishLocomotionIntro(record) end
					return
				end
				locomotionStatus = "蹲伏起手"; return
			else locomotionStatus = "让位于当前动作"; return end
		end
		if record.introReadyAt then
			if not paused and clock() < record.introReadyAt then locomotionStatus = "起手衔接"; return end
			record.introReadyAt = nil
		end
		local wanted = not paused and (hum.MoveDirection.Magnitude > 0.01 and "Walk" or "Idle") or nil
		if wanted == record.playing then
			if not wanted then locomotionStatus = "让位于当前动作"; return end
			local readable, playing = pcall(function() return record.tracks[wanted].IsPlaying end)
			if not locomotionCurrent(record) then return end
			if not readable then record.failed = true; locomotionStatus = "动画状态读取失败，点重新应用重试"; return end
			if playing then return end
		end
		local old, nextTrack = record.playing and record.tracks[record.playing], wanted and record.tracks[wanted]
		if nextTrack then
			local ok = pcall(function() nextTrack:Play(0.12, 1, 1) end)
			if not ok or not locomotionCurrent(record) then
				if not record.disposed then pcall(function() nextTrack:Stop(0.12) end) end
				if not record.disposed then record.failed = true; locomotionStatus = "动画播放失败，点重新应用重试" end
				return
			end
		end
		record.playing = wanted
		if old and old ~= nextTrack then pcall(function() old:Stop(0.12) end) end
		if not locomotionCurrent(record) then return end
		locomotionStatus = (wanted == "Walk" and "行走" or wanted == "Idle" and "待机" or "让位于当前动作") .. (record.introTimedOut and "（起手超时已跳过）" or "")
	end
	local function tickLocomotion()
		if destroyed or not locomotionEnabled or locomotionReleaseDepth > 0 then return end
		local char = LocalPlayer.Character
		if char ~= locomotionChar then resetLocomotion(); locomotionChar = char end
		if not char or char == locomotionRemoving or char.Parent == nil then
			if locomotionRecord or locomotionPending or locomotionAttempt then resetLocomotion(); locomotionChar = char end
			locomotionStatus = "等待角色"; return
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		local animator = hum and hum:FindFirstChildOfClass("Animator")
		local owner = locomotionRecord or locomotionPending
		if owner and (owner.hum ~= hum or owner.animator ~= animator or not locomotionCurrent(owner)) then
			resetLocomotion(); locomotionChar = char
		end
		if not hum or not animator or hum.Health <= 0 then locomotionStatus = "等待存活角色的 Animator"; return end
		if not locomotionRecord then
			if locomotionAttempt ~= char or locomotionAttemptAnimator ~= animator then loadLocomotion(char, hum, animator) end
			return
		end
		driveLocomotion(locomotionRecord)
	end
	local function setLocomotionEnabled(value)
		local enabled = value == true
		if destroyed and enabled then return end
		if not enabled then
			locomotionEnabled = false
			local step, removing = locomotionStep, locomotionRemove
			locomotionStep, locomotionRemove, locomotionRemoving = nil, nil, nil
			if step then pcall(function() step:Disconnect() end) end
			if removing then pcall(function() removing:Disconnect() end) end
			resetLocomotion(); locomotionStatus = "已关闭"
			if locomotionToggle and not locomotionToggleSync then
				locomotionToggleSync = true
				pcall(function() locomotionToggle:SetValue(false) end)
				locomotionToggleSync = false
			end
			return
		end
		if locomotionEnabled then return end
		locomotionEnabled = true
		local lastTick = -math.huge
		local ok = pcall(function()
			locomotionRemove = LocalPlayer.CharacterRemoving:Connect(function(old)
				locomotionRemoving = old; resetLocomotion(); locomotionStatus = "等待重生"
			end)
			locomotionStep = RunService.Heartbeat:Connect(function()
				if clock() - lastTick < 0.1 then return end
				lastTick = clock()
				if sessionEnv and ctx.thisSessionId ~= nil and sessionEnv.VortexionSessionId ~= ctx.thisSessionId then setLocomotionEnabled(false); return end
				local ready = pcall(tickLocomotion)
				if not ready then setLocomotionEnabled(false); locomotionStatus = "角色动作状态读取失败" end
			end)
			track(locomotionRemove); track(locomotionStep)
		end)
		if not ok or destroyed or not locomotionEnabled then setLocomotionEnabled(false) end
	end
	local function setLocomotionProfile(value)
		if destroyed or not locomotionProfiles[value] or value == locomotionProfile then return end
		locomotionProfile = value
		resetLocomotion()
	end
	-- Local Sil presentation only; source tracks are borrowed, never destroyed.
	local sil = {enabled = false, epoch = 0, serial = 0, status = "已关闭"}
	local silMap = {
		["93368339913846"] = {id = "140035118771958", delay = 0.45, speed = 1},
		["119429069577280"] = {id = "128730974312965", delay = 0, speed = 1.65},
	}
	local function silCurrent(owner)
		return sil.enabled and not destroyed and owner and owner.epoch == sil.epoch
			and LocalPlayer.Character == owner.char and owner.char ~= sil.removing and owner.char.Parent ~= nil
			and owner.hum.Parent == owner.char and owner.hum.Health > 0 and owner.animator.Parent == owner.hum
			and owner.char:FindFirstChildOfClass("Humanoid") == owner.hum and owner.hum:FindFirstChildOfClass("Animator") == owner.animator
			and (not sessionEnv or ctx.thisSessionId == nil or sessionEnv.VortexionSessionId == ctx.thisSessionId)
	end
	local function releaseSil(record)
		if not record or record.disposed then return end
		record.disposed = true
		if sil.owned == record then sil.owned = nil end
		disposeTrack(record.track, record.connection)
	end
	local function resetSil()
		sil.epoch += 1; sil.serial += 1
		sil.releaseDepth = (sil.releaseDepth or 0) + 1
		local connection, owned = sil.connection, sil.owned
		sil.connection, sil.owner, sil.pending, sil.owned = nil, nil, nil, nil
		if connection then pcall(function() connection:Disconnect() end) end
		releaseSil(owned)
		sil.releaseDepth -= 1
	end
	local function silRequestCurrent(request)
		return silCurrent(request.owner) and request.serial == sil.serial and request.original.IsPlaying == true
	end
	local function replaceSil(request)
		if not silRequestCurrent(request) then return end
		local animation, result
		local ok = pcall(function()
			animation = Instance.new("Animation")
			animation.AnimationId = "rbxassetid://" .. request.spec.id
			result = request.owner.animator:LoadAnimation(animation)
		end)
		if animation then pcall(function() animation:Destroy() end) end
		if not ok or not result then
			disposeTrack(result)
			if silCurrent(request.owner) and request.serial == sil.serial then sil.status = "动画载入失败，保留原动作" end
			return
		end
		local record = {track = result, owner = request.owner}
		if not silRequestCurrent(request) then releaseSil(record); return end
		local connected, connection = pcall(function()
			return result.Stopped:Connect(function()
				record.ended = true
				if sil.owned == record then releaseSil(record) end
			end)
		end)
		record.connection = connected and connection or nil
		if not connected or not connection or record.ended or not silRequestCurrent(request) then releaseSil(record); return end
		ok = pcall(function() result.Looped = false; result:Play(0.1, 1, request.spec.speed) end)
		if not ok or record.ended or not silRequestCurrent(request) then releaseSil(record); return end
		local old = sil.owned
		sil.owned, record.expiresAt = record, clock() + 15
		releaseSil(old)
		if sil.owned ~= record or not silRequestCurrent(request) then releaseSil(record); return end
		-- Commit the replacement before suppressing the original; failed loads leave it alone.
		local stopped = pcall(function() request.original:Stop() end)
		if not stopped then
			releaseSil(record)
			if silCurrent(record.owner) then sil.status = "原动作停止失败，撤回替换" end
			return
		end
		if sil.owned == record and silCurrent(record.owner) then sil.status = "本地动作已替换" end
	end
	local function bindSil(char, hum, animator)
		local owner = {char = char, hum = hum, animator = animator, epoch = sil.epoch}
		sil.owner = owner
		local ok, connection = pcall(function()
			return animator.AnimationPlayed:Connect(function(original)
				local readable, err = pcall(function()
					if not silCurrent(owner) or not original or original.IsPlaying ~= true then return end
					local value = original.Animation and original.Animation.AnimationId
					local id = type(value) == "string" and (value:match("^rbxassetid://(%d+)$") or value:match("^(%d+)$"))
					local spec = id and silMap[id]
					if not spec or (sil.pending and sil.pending.original == original) then return end
					sil.serial += 1
					local request = {owner = owner, original = original, spec = spec, serial = sil.serial, due = clock() + spec.delay}
					sil.pending = nil
					if spec.delay > 0 then sil.pending = request else replaceSil(request) end
				end)
				if not readable and silCurrent(owner) then sil.status = "动画观察失败：" .. tostring(err) end
			end)
		end)
		if not ok or not connection or not silCurrent(owner) then
			if ok and connection then pcall(function() connection:Disconnect() end) end
			if sil.owner == owner then sil.status = "动画监听未就绪，关闭后重试" end
			return
		end
		sil.connection, sil.status = connection, "监听本机两项Sil动作"
	end
	local setSilAnimationEnabled
	setSilAnimationEnabled = function(value)
		local enabled = value == true and not destroyed
		if not enabled then
			sil.enabled = false; sil.setup = (sil.setup or 0) + 1
			local step, removing = sil.step, sil.remove
			sil.step, sil.remove, sil.removing = nil, nil, nil
			if step then pcall(function() step:Disconnect() end) end
			if removing then pcall(function() removing:Disconnect() end) end
			resetSil(); sil.status = "已关闭"
			if sil.toggle and not sil.sync then
				sil.sync = true; pcall(function() sil.toggle:SetValue(false) end); sil.sync = false
			end
			return
		end
		if sil.enabled or (sil.releaseDepth or 0) > 0 then return end
		sil.enabled = true; sil.setup = (sil.setup or 0) + 1
		local setup = sil.setup
		local function connectSil(key, signal, fn)
			local connection = signal:Connect(fn)
			if not connection then error("Sil listener missing") end
			if not sil.enabled or destroyed or sil.setup ~= setup then
				pcall(function() connection:Disconnect() end); error("Sil listener setup cancelled")
			end
			sil[key] = connection
		end
		local lastBind = -math.huge
		local function tickSil()
			if not sil.enabled or destroyed then return end
			if sessionEnv and ctx.thisSessionId ~= nil and sessionEnv.VortexionSessionId ~= ctx.thisSessionId then setSilAnimationEnabled(false); return end
			local t = clock()
			if t - lastBind >= 0.1 then
				lastBind = t
				local char = LocalPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local animator = hum and hum:FindFirstChildOfClass("Animator")
				local owner = sil.owner
				if owner and (not silCurrent(owner) or owner.hum ~= hum or owner.animator ~= animator) then resetSil() end
				if not sil.enabled or destroyed then return end
				if not sil.owner and char and char ~= sil.removing and char.Parent and hum and hum.Health > 0 and animator and animator.Parent == hum then bindSil(char, hum, animator) end
			end
			local pending = sil.pending
			if pending and t >= pending.due then sil.pending = nil; replaceSil(pending) end
			local owned = sil.owned
			if owned and (not silCurrent(owned.owner) or t >= owned.expiresAt or not owned.track.IsPlaying) then releaseSil(owned) end
		end
		local ok, err = pcall(function()
			connectSil("remove", LocalPlayer.CharacterRemoving, function(old) sil.removing = old; resetSil() end)
			connectSil("step", RunService.Heartbeat, function()
				local success, failure = pcall(tickSil)
				if not success then resetSil(); sil.status = "动画刷新失败：" .. tostring(failure) end
			end)
			tickSil()
		end)
		if not ok and sil.setup == setup then setSilAnimationEnabled(false); sil.status = "动画监听失败：" .. tostring(err) end
	end

	local function stopAllAnimations()
		setSilAnimationEnabled(false)
		stopAnimations(); setLocomotionEnabled(false)
	end

	-- Reference chat sync: SyncScript.lua:24-78 / Terio_Survivor.lua:1243-1428; local cosmetics only.
	local chatSyncEnabled, chatSyncStatus, chatSyncEpoch = false, "已关闭", 0
	local chatSyncRecords, chatSyncBindings, chatSyncConnections = {}, {}, {}
	local setChatSyncEnabled, chatSyncToggle
	local chatSyncToggleSync, chatSyncReleaseDepth = false, 0
	local function chatSyncCurrent(epoch)
		return not destroyed and chatSyncEnabled and epoch == chatSyncEpoch
			and (not ctx.sessionEnv or ctx.thisSessionId == nil or ctx.sessionEnv.VortexionSessionId == ctx.thisSessionId)
	end
	local function chatRecordCurrent(record)
		local ok, value = pcall(function()
			return chatSyncCurrent(record.Epoch) and chatSyncRecords[record.Player] == record
				and record.Player.Parent == Players and record.Player.Character == record.Character
				and record.Character.Parent ~= nil and record.Character.Name == record.CharacterName
				and record.Humanoid.Parent == record.Character and record.Humanoid.Health > 0
				and record.Arm.Parent == record.Character and record.Character:FindFirstChild("Right Arm") == record.Arm
				and (not record.Torso or (record.Torso.Parent == record.Character and record.Character:FindFirstChild("Torso") == record.Torso))
				and (not record.Head or (record.Head.Parent == record.Character and record.Character:FindFirstChild("Head") == record.Head))
		end)
		return ok and value == true
	end
	local function restoreChatLook(entry)
		pcall(function()
			if entry.Object.Parent == entry.Owner and entry.Object[entry.Property] == entry.Applied then
				entry.Object[entry.Property] = entry.Original
			end
		end)
	end
	local function resetChatFace(record)
		chatSyncReleaseDepth += 1
		local edits, appearance = record.FaceEdits or {}, record.Appearance or {}
		record.FaceAt, record.FaceUntil, record.FaceAnimator, record.FaceEdits = nil, nil, nil, nil
		for i = #edits, 1, -1 do restoreChatLook(edits[i]) end
		if chatSyncRecords[record.Player] ~= record then
			for i = #appearance, 1, -1 do restoreChatLook(appearance[i]) end
		end
		chatSyncReleaseDepth -= 1
	end
	local function releaseChatRecord(record)
		chatSyncReleaseDepth += 1
		if chatSyncRecords[record.Player] == record then chatSyncRecords[record.Player] = nil end
		local items, labels, icons, animation, appearance = record.Items, record.Labels, record.Icons, record.LanceConnection, record.Appearance or {}
		record.Items, record.Labels, record.Icons, record.Appearance = {}, {}, {}, {}
		record.LanceAnimator, record.LanceConnection, record.LanceUntil = nil, nil, nil
		if animation then pcall(function() animation:Disconnect() end) end
		for label, original in pairs(labels) do
			pcall(function() if label.Text == record.LabelText then label.Text = original end end)
		end
		for icon, original in pairs(icons) do
			pcall(function() if icon.Image == record.IconImage then icon.Image = original end end)
		end
		resetChatFace(record)
		for i = #appearance, 1, -1 do restoreChatLook(appearance[i]) end
		for i = #items, 1, -1 do pcall(function() items[i]:Destroy() end) end
		chatSyncReleaseDepth -= 1
	end
	local function setChatLanceVisible(record, visible)
		if not chatRecordCurrent(record) then return false end
		local ok = pcall(function()
			local front, back = record.LanceFront, record.LanceBack
			if not (front and back and front.Parent and back.Parent
				and front.Parent.Parent == record.Character and back.Parent.Parent == record.Character) then error("stale lance handles") end
			front.Transparency = visible and 0 or 1
			if chatRecordCurrent(record) then back.Transparency = visible and 1 or 0 end
		end)
		if not ok then releaseChatRecord(record) end
		return ok and chatRecordCurrent(record)
	end
	local function chatLanceAnimatorCurrent(record, animator)
		local ok, valid = pcall(function()
			return chatRecordCurrent(record) and record.LanceAnimator == animator
				and animator.Parent == record.Humanoid and record.Humanoid:FindFirstChildOfClass("Animator") == animator
		end)
		return ok and valid == true
	end
	local function compensateChatFace(record, entry, appearance)
		restoreChatLook(entry)
		-- A late pulse write may outlive both pulse and appearance cleanup.
		if chatSyncRecords[record.Player] ~= record then
			for i = #appearance, 1, -1 do restoreChatLook(appearance[i]) end
		end
	end
	local function tickChatFace(record, at)
		if not record.FaceAt and not record.FaceUntil then return end
		if not chatLanceAnimatorCurrent(record, record.FaceAnimator) then
			resetChatFace(record)
			if not chatRecordCurrent(record) then releaseChatRecord(record) end
			return
		end
		if record.FaceUntil then
			if at >= record.FaceUntil then resetChatFace(record) end
			return
		end
		if at < record.FaceAt then return end
		-- Nominal reference hold: 0.15s lead + 0.20s fade-in + 0.20s hold.
		local deadline = record.FaceAt + 0.55
		if at >= deadline then resetChatFace(record); return end
		record.FaceAt, record.FaceUntil = nil, deadline
		local edits, appearance = {}, record.Appearance or {}
		record.FaceEdits = edits
		local ok = pcall(function()
			for _, face in ipairs(record.Faces or {}) do
				if not chatLanceAnimatorCurrent(record, record.FaceAnimator) or record.FaceEdits ~= edits then return end
				if face.Parent == record.Head and face.Face == Enum.NormalId.Front and face.Texture == "rbxassetid://133089396665213" then
					local entry = {Object = face, Owner = record.Head, Property = "Texture", Original = face.Texture, Applied = "rbxassetid://127552301758353"}
					table.insert(edits, entry)
					local written = pcall(function() face.Texture = entry.Applied end)
					if not written or not chatLanceAnimatorCurrent(record, record.FaceAnimator) or record.FaceEdits ~= edits or face.Parent ~= entry.Owner then
						compensateChatFace(record, entry, appearance)
						releaseChatRecord(record); return
					end
				end
			end
		end)
		if not ok then releaseChatRecord(record) end
	end
	local function refreshChatLance(record)
		if not record.LanceFront or not chatRecordCurrent(record) then return end
		local ok, animator = pcall(function() return record.Humanoid:FindFirstChildOfClass("Animator") end)
		if not ok or record.LanceAnimator == animator then return end
		local previous = record.LanceConnection
		record.LanceAnimator, record.LanceConnection, record.LanceUntil = animator, nil, nil
		if previous then pcall(function() previous:Disconnect() end) end
		resetChatFace(record)
		if not setChatLanceVisible(record, false) or not animator then return end
		local connected, connection = pcall(function()
			return animator.AnimationPlayed:Connect(function(track)
				if chatSyncReleaseDepth > 0 or not chatLanceAnimatorCurrent(record, animator) then return end
				local read, asset = pcall(function() return track.Animation.AnimationId end)
				if not read or type(asset) ~= "string" then return end
				local id = asset:match("^rbxassetid://(%d+)$") or asset:match("^(%d+)$")
					or asset:match("^https?://www%.roblox%.com/asset/%?id=(%d+)$")
				if id == "121781457295101" then
					resetChatFace(record)
					if chatLanceAnimatorCurrent(record, animator) then
						record.FaceAt, record.FaceAnimator = clock() + 2, animator
					end
					return
				end
				if id ~= "84413781229733" then return end
				-- Latest event owns the two-second window; no per-track tasks or borrowed-track writes.
				record.LanceUntil = clock() + 2
				setChatLanceVisible(record, true)
			end)
		end)
		if connected and connection then
			if chatLanceAnimatorCurrent(record, animator) then record.LanceConnection = connection
			else pcall(function() connection:Disconnect() end) end
		end
	end
	local function updateChatLabel(record)
		if not chatRecordCurrent(record) then return end
		pcall(function()
			local panel = LocalPlayer:FindFirstChild("PlayerGui")
			for _, name in ipairs({"TemporaryUI", "PlayerInfo", "CurrentSurvivors"}) do
				panel = panel and panel:FindFirstChild(name)
			end
			if not panel then return end
			for _, row in ipairs(panel:GetChildren()) do
				local username, label = row:FindFirstChild("Username"), row:FindFirstChild("SurvivorName")
				if row:IsA("Frame") and username and username.Text == record.Player.Name and chatRecordCurrent(record) then
					if label and label:IsA("TextLabel") and record.Labels[label] == nil then
						local original = label.Text
						if original ~= record.LabelText then
							record.Labels[label] = original
							label.Text = record.LabelText
							if not chatRecordCurrent(record) then releaseChatRecord(record); return end
						end
					end
					local icon = row:FindFirstChild("Icon")
					if record.IconImage and icon and (icon:IsA("ImageLabel") or icon:IsA("ImageButton")) and record.Icons[icon] == nil then
						local original = icon.Image
						if original ~= record.IconImage then
							record.Icons[icon] = original
							icon.Image = record.IconImage
							if not chatRecordCurrent(record) then releaseChatRecord(record); return end
						end
					end
				end
			end
		end)
	end
	local function receiveChatSync(player, message, epoch)
		if chatSyncReleaseDepth > 0 or not chatSyncCurrent(epoch) or (message ~= ":syncScript" and message ~= "_sync_terio_") or player == LocalPlayer then return end
		local record
		local ok = pcall(function()
			if not player or player.Parent ~= Players then return end
			local existing = chatSyncRecords[player]
			if existing then
				if chatRecordCurrent(existing) then return end
				releaseChatRecord(existing)
			end
			local count = 0
			for _ in pairs(chatSyncRecords) do count += 1 end
			if count >= 32 then return end
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local arm = char and char:FindFirstChild("Right Arm")
			local terio = message == "_sync_terio_"
			local characterName = terio and "Shedletsky" or "TwoTime"
			local torso = terio and char and char:FindFirstChild("Torso")
			if not (char and char.Name == characterName and hum and hum.Health > 0 and arm and arm:IsA("BasePart")) then return end
			if terio and not (torso and torso:IsA("BasePart")) then return end
			record = {Player = player, Character = char, CharacterName = characterName, Humanoid = hum, Arm = arm, Torso = torso, Epoch = epoch, Items = {}, Appearance = {},
				LabelText = terio and "Terio" or "Two Time (Rework)", IconImage = terio and "rbxassetid://115704573151422" or nil,
				Labels = setmetatable({}, {__mode = "k"}), Icons = setmetatable({}, {__mode = "k"})}
			chatSyncRecords[player] = record
			local function create(className, parent)
				local object = Instance.new(className)
				table.insert(record.Items, object)
				if parent then object.Parent = parent end
				return object
			end
			local function weapon(name, mount, meshId, textureId, scale, transparency, c0)
				local accessory = create("Accessory")
				accessory.Name = name
				local handle = create("Part", accessory)
				handle.Name, handle.Size = "Handle", Vector3.new(1, 1, 1)
				handle.CanCollide, handle.CanTouch, handle.CanQuery = false, false, false
				handle.Anchored, handle.Massless, handle.Transparency = false, true, transparency
				handle.Color = Color3.new(0.1, 0.1, 0.1)
				local mesh = create("SpecialMesh", handle)
				mesh.MeshId, mesh.TextureId, mesh.Scale = meshId, textureId, scale
				local weld = create("Weld", handle)
				weld.Part0, weld.Part1 = handle, mount
				weld.C0 = c0
				weld.C1 = CFrame.new(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
				return accessory
			end
			local accessories
			if terio then
				accessories = {
					weapon("VortexionSyncedLanceBack", torso, "rbxassetid://18858726703", "rbxassetid://18858727747", Vector3.new(1, 1, 1), 0,
						CFrame.new(0, -1, -0.5, 1, 0, 0, 0, -1, 0, 0, 0, 1)),
					weapon("VortexionSyncedLanceFront", arm, "rbxassetid://18858726703", "rbxassetid://18858727747", Vector3.new(1, 1, 1), 1,
						CFrame.new(-1, 0.400000006, 0, 0.00999950059, -0.999750197, 0.0199924111, 0, -0.0199934151, -0.999800086, -0.999950051, -0.00999750197, 0.000199924252)),
				}
			else
				accessories = {weapon("VortexionSyncedShadowBlade", arm, "rbxassetid://62275962", "rbxassetid://62276016", Vector3.new(0.5, 0.5, 0.5), 0,
					CFrame.new(1.75, -0.879999995, 0, -1.31445322e-05, 1, 0, 0, 0, 1, 1, 1.31445331e-05, -7.10549173e-15))}
			end
			if terio then
				record.LanceBack, record.LanceFront = accessories[1]:FindFirstChild("Handle"), accessories[2]:FindFirstChild("Handle")
			end
			local lookPublications, lookEdits = {}, {}
			if terio then
				local head = char:FindFirstChild("Head")
				if head and head:IsA("BasePart") then record.Head = head end
				local function stageLook(className, owner, property, asset)
					local targets = {}
					for _, object in ipairs(owner:GetChildren()) do
						if object:IsA(className) and (className ~= "Decal" or object.Face == Enum.NormalId.Front) then
							table.insert(targets, object)
						end
					end
					if #targets == 0 then
						local object = create(className)
						object.Name, object[property], object.Color3 = "VortexionSynced" .. className, asset, Color3.new(1, 1, 1)
						if className == "Decal" then object.Face, object.Transparency = Enum.NormalId.Front, 0 end
						table.insert(lookPublications, {Object = object, Owner = owner})
						table.insert(targets, object)
					else
						for _, object in ipairs(targets) do
							table.insert(lookEdits, {Object = object, Owner = owner, Property = property, Applied = asset})
							table.insert(lookEdits, {Object = object, Owner = owner, Property = "Color3", Applied = Color3.new(1, 1, 1)})
							if className == "Decal" then table.insert(lookEdits, {Object = object, Owner = owner, Property = "Transparency", Applied = 0}) end
						end
					end
					if className == "Decal" then record.Faces = targets end
				end
				stageLook("Shirt", char, "ShirtTemplate", "rbxassetid://13132949672")
				stageLook("Pants", char, "PantsTemplate", "rbxassetid://13132951176")
				if record.Head then stageLook("Decal", record.Head, "Texture", "rbxassetid://133089396665213") end
				-- One bounded direct-part sweep; never lock descendants or change BodyColors.
				for index, object in ipairs(char:GetChildren()) do
					if index > 256 then break end
					if object:IsA("BasePart") then
						table.insert(lookEdits, {Object = object, Owner = char, Property = "Color", Applied = Color3.new(1, 1, 1)})
					end
				end
			end
			-- Build the complete set off-character; stale or failed candidates roll back together.
			for _, accessory in ipairs(accessories) do
				if not chatRecordCurrent(record) then releaseChatRecord(record); return end
				accessory.Parent = char
				if not chatRecordCurrent(record) then releaseChatRecord(record); return end
			end
			for _, entry in ipairs(lookPublications) do
				if not chatRecordCurrent(record) then releaseChatRecord(record); return end
				entry.Object.Parent = entry.Owner
				if not chatRecordCurrent(record) then releaseChatRecord(record); return end
			end
			for _, entry in ipairs(lookEdits) do
				if not chatRecordCurrent(record) or entry.Object.Parent ~= entry.Owner then releaseChatRecord(record); return end
				entry.Original = entry.Object[entry.Property]
				if entry.Original ~= entry.Applied then
					table.insert(record.Appearance, entry)
					local written = pcall(function() entry.Object[entry.Property] = entry.Applied end)
					if not written or not chatRecordCurrent(record) or entry.Object.Parent ~= entry.Owner then
						-- A setter can close before completing its write, after the first release ran.
						restoreChatLook(entry)
						releaseChatRecord(record); return
					end
				end
			end
			refreshChatLance(record)
			updateChatLabel(record)
		end)
		if not ok and record then releaseChatRecord(record) end
	end
	local function disconnectChatConnections(list)
		for _, connection in ipairs(list) do pcall(function() connection:Disconnect() end) end
	end
	local function stopChatSync()
		chatSyncReleaseDepth += 1
		chatSyncEnabled, chatSyncEpoch, chatSyncStatus = false, chatSyncEpoch + 1, "已关闭"
		local connections, bindings, records = chatSyncConnections, chatSyncBindings, chatSyncRecords
		chatSyncConnections, chatSyncBindings, chatSyncRecords = {}, {}, {}
		disconnectChatConnections(connections)
		for _, binding in pairs(bindings) do disconnectChatConnections(binding) end
		for _, record in pairs(records) do releaseChatRecord(record) end
		if chatSyncToggle and not chatSyncToggleSync and not chatSyncEnabled then
			chatSyncToggleSync = true
			pcall(function() chatSyncToggle:SetValue(false) end)
			chatSyncToggleSync = false
		end
		chatSyncReleaseDepth -= 1
	end
	setChatSyncEnabled = function(value)
		if value ~= true then stopChatSync(); return end
		if destroyed or chatSyncEnabled or chatSyncReleaseDepth > 0 then return end
		chatSyncEpoch += 1
		chatSyncEnabled = true
		local epoch, lastTick = chatSyncEpoch, -math.huge
		local function listen(signal, callback, bucket, current)
			local connection = signal:Connect(callback)
			if not current() then pcall(function() connection:Disconnect() end); return end
			table.insert(bucket, connection)
		end
		local function current() return chatSyncCurrent(epoch) end
		local function bind(player)
			if player == LocalPlayer or chatSyncBindings[player] or not current() or player.Parent ~= Players then return end
			local bucket = {}
			chatSyncBindings[player] = bucket
			local function bindingCurrent() return current() and chatSyncBindings[player] == bucket and player.Parent == Players end
			local ok = pcall(function()
				listen(player.Chatted, function(message) if bindingCurrent() then receiveChatSync(player, message, epoch) end end, bucket, bindingCurrent)
				listen(player.CharacterRemoving, function(char)
					local record = chatSyncRecords[player]
					if bindingCurrent() and record and record.Character == char then releaseChatRecord(record) end
				end, bucket, bindingCurrent)
			end)
			if not ok or not bindingCurrent() then
				if chatSyncBindings[player] == bucket then chatSyncBindings[player] = nil end
				disconnectChatConnections(bucket)
			end
		end
		local ok = pcall(function()
			listen(Players.PlayerAdded, bind, chatSyncConnections, current)
			listen(Players.PlayerRemoving, function(player)
				if not current() then return end
				local bucket, record = chatSyncBindings[player], chatSyncRecords[player]
				chatSyncBindings[player] = nil
				if bucket then disconnectChatConnections(bucket) end
				if record then releaseChatRecord(record) end
			end, chatSyncConnections, current)
			if not current() then return end
			for _, player in ipairs(Players:GetPlayers()) do bind(player) end
			local textChat = ctx.TextChatService
			if textChat and textChat.MessageReceived then
				listen(textChat.MessageReceived, function(message)
					if not current() then return end
					pcall(function()
						local source = message.TextSource
						if source then receiveChatSync(Players:GetPlayerByUserId(source.UserId), message.Text, epoch) end
					end)
				end, chatSyncConnections, current)
			end
			if not current() then return end
			listen(RunService.Heartbeat, function()
				if not current() then
					if chatSyncEpoch == epoch then stopChatSync() end
					return
				end
				local at = clock()
				-- Check deadlines before the slower identity/UI sweep, including adjacent frames.
				for _, record in pairs(table.clone(chatSyncRecords)) do
					tickChatFace(record, at)
					if record.LanceUntil and at >= record.LanceUntil then
						record.LanceUntil = nil
						if chatRecordCurrent(record) then setChatLanceVisible(record, false) else releaseChatRecord(record) end
					end
				end
				if not current() or at - lastTick < 0.25 then return end
				lastTick = at
				for _, record in pairs(table.clone(chatSyncRecords)) do
					if chatRecordCurrent(record) then
						refreshChatLance(record)
						updateChatLabel(record)
					else releaseChatRecord(record) end
				end
			end, chatSyncConnections, current)
		end)
		if not ok or not current() then
			if chatSyncEpoch == epoch then stopChatSync(); chatSyncStatus = "聊天监听未就绪" end
			return
		end
		chatSyncStatus = "监听精确指令 :syncScript / _sync_terio_（仅其他玩家本机刀饰 / Terio枪饰与衣饰）"
	end
	-- End reference chat sync.

	local chargeSaved = {}
	local function chargeStateSave(hum)
		if hum and not chargeSaved[hum] then chargeSaved[hum] = {WalkSpeed = hum.WalkSpeed, JumpPower = hum.JumpPower} end
	end
	local function chargeStateRestore(hum)
		local saved = hum and chargeSaved[hum]
		if not saved then return end
		for key, value in pairs(saved) do pcall(function() hum[key] = value end) end
		chargeSaved[hum] = nil
	end
	local respawnConn = LocalPlayer.CharacterAdded:Connect(function()
		locomotionRemoving = nil; resetLocomotion()
		sil.removing = nil; resetSil()
		stopAnimations()
		for hum in pairs(chargeSaved) do chargeStateRestore(hum) end
	end)
	track(respawnConn)
	local function destroy()
		if destroyed then return end
		destroyed = true
		stopChatSync()
		setSilAnimationEnabled(false)
		guestState.FakeBlock = false
		setLocomotionEnabled(false)
		stopAnimations(); respawnConn:Disconnect()
		for hum in pairs(chargeSaved) do chargeStateRestore(hum) end
		ensureSingleGui("VortexionGuestGui")
	end

	---------------------------------------------------------------------------
	-- UI: Guest 增强 (挂 GuestSettings tab)
	---------------------------------------------------------------------------
	if Tabs and Tabs.Guest then
		Tabs.Guest:AddToggle("GuestFakeBlockGui", {
			Title = "启用假格挡",
			Default = false,
			Callback = function(state)
				setEnabled("FakeBlock", state)
				if not state then stopAnimations() end
			end
		})

		Tabs.Guest:AddButton({ Title = "触发假格挡", Callback = triggerFakeBlock })

		-- 纯本地演出预设：仅本机播放，不自动触发、不写服务端状态
		local actionProfiles = {
			["TwoTime / 蹲伏起手"] = "98606150731314",
			["TwoTime / 蹲伏斩击"] = "119256819262245",
			["TwoTime / 站姿斩击"] = "86545133269813",
			["Sil / 普通挥击"] = "83829782357897",
			["Terio / 蹲姿斩击"] = "84413781229733",
		}
		local actionSelected = "TwoTime / 蹲伏起手"
		Tabs.Guest:AddDropdown("GuestActionPreset", {
			Title = "本地动作演出预设",
			Values = { "TwoTime / 蹲伏起手", "TwoTime / 蹲伏斩击", "TwoTime / 站姿斩击", "Sil / 普通挥击", "Terio / 蹲姿斩击" },
			Default = "TwoTime / 蹲伏起手",
			Callback = function(v)
				if destroyed then return end
				if actionProfiles[v] then actionSelected = v end
			end,
		})
		Tabs.Guest:AddButton({
			Title = "播放所选动作（仅演出）",
			Callback = function()
				if destroyed then return end
				local ok, err = playCustomAnim(actionProfiles[actionSelected])
				notify("本地演出", ok and ("已播放 " .. actionSelected .. "（仅演出，非实际技能）") or tostring(err))
			end,
		})
		Tabs.Guest:AddInput("GuestCustomAnimId", {
			Title = "播放自定义动画 ID",
			Placeholder = "rbxassetid://...",
			Callback = function(input)
				local ok, err = playCustomAnim(input)
				notify("自定义动画", ok and "已播放" or tostring(err))
			end
		})

		Tabs.Guest:AddSlider("GuestAnimationSpeed", {
			Title = "自定义动画速度（%）",
			Min = 25,
			Max = 200,
			Default = 100,
			Rounding = 0,
			Callback = function(value)
				if destroyed then return end
				local speed = tonumber(value)
				if speed and speed == speed and speed ~= math.huge and speed ~= -math.huge then
					animationSpeed = math.clamp(speed, 25, 200)
				end
			end
		})

		Tabs.Guest:AddToggle("GuestAnimationLoop", {
			Title = "自定义动画循环播放",
			Default = false,
			Callback = function(state)
				if destroyed then return end
				animationLoop = state == true
			end
		})

		Tabs.Guest:AddToggle("GuestChargeStateGuard", {
			Title = "冲锋状态安全恢复（含 WalkSpeed=0）",
			Default = true,
			Callback = function(state)
				_G.VortexionChargeStateGuard = state or nil
			end
		})
	end

	---------------------------------------------------------------------------
	-- UI: Guest 增强 (挂 Blatant tab)
	---------------------------------------------------------------------------
	if Tabs and Tabs.Guest then
		Tabs.Guest:AddButton({
			Title = "关闭假格挡 / 清理旧浮窗",
			Callback = function()
				destroyFakeBlockGui()
				notify("Guest", "GUI 已清理")
			end
		})
	end

	if Tabs and Tabs.Guest then
		Tabs.Guest:AddParagraph({Title = "聊天武器外观同步", Content = "默认关闭。其他 TwoTime 的精确 :syncScript 显示刀饰；其他存活 Shedletsky 的 _sync_terio_ 同步Terio枪饰、衣裤、正面贴图和玩家栏，挥枪动画显形2秒；精确凝血动画延迟2秒变脸、名义0.55秒后恢复，不附带音效或红光。借用外观有条件恢复，缺项才新建；初次缺Head时跳过脸贴图，重开可补脸。仅本机可见，不发送聊天或运行远程脚本，不修改伤害/输入；关闭、离场或身份变化回收。身体白肤仅单次扫描至多256个直接子项，关闭按快照恢复；保留原配件与BodyColors，不循环锁色。Sil、Terio头发及其余动作音效仍待补。"})
		chatSyncToggle = Tabs.Guest:AddToggle("GuestTwoTimeChatSync", {Title = "接收 TwoTime / Terio 本机外观同步", Default = false, Callback = setChatSyncEnabled})
		Tabs.Guest:AddButton({Title = "聊天同步状态", Callback = function() if not destroyed then notify("聊天同步", chatSyncStatus) end end})
		Tabs.Guest:AddDropdown("GuestFakeBlockVariant", {Title = "假格挡动画类型", Values = {"Normal", "M3 / M4"}, Default = 1, Callback = function(v) fakeVariant = v end})
		Tabs.Guest:AddParagraph({Title = "角色待机 / 行走（本地）", Content = "只替换本机动作表现，不改移速或技能。TwoTime 先播一次起手，再接待机/行走；起手最长8秒兜底，中断不重播。角色离地、坐下及自定义动作播放时让位；动画权限与实际效果待游戏确认。"})
		Tabs.Guest:AddDropdown("GuestLocomotionProfile", {Title = "待机 / 行走方案", Values = {"Terio", "TwoTime / 蹲伏"}, Default = "Terio", Callback = setLocomotionProfile})
		locomotionToggle = Tabs.Guest:AddToggle("GuestLocomotionEnabled", {Title = "启用本地待机 / 行走", Default = false, Callback = setLocomotionEnabled})
		Tabs.Guest:AddButton({Title = "重新应用角色动作", Callback = function() if not destroyed then resetLocomotion() end end})
		Tabs.Guest:AddButton({Title = "角色动作状态", Callback = function() if not destroyed then notify("角色动作", locomotionProfile .. "：" .. locomotionStatus) end end})
		sil.toggle = Tabs.Guest:AddToggle("GuestSilAnimationEnabled", {Title = "Sil 本地动作替换", Default = false, Callback = setSilAnimationEnabled})
		Tabs.Guest:AddParagraph({Title = "Sil 动作范围", Content = "仅替换本机终结技与不稳之眼动画；终结技等待0.45秒，眼部动作1.65倍速。默认关闭，失败保留原动作，不附带伤害、位移或输入修改；关闭后清理自有轨道，不重播原动作。"})
		Tabs.Guest:AddButton({Title = "Sil 动作状态", Callback = function() if not destroyed then notify("Sil", sil.status) end end})
		Tabs.Guest:AddButton({Title = "停止本模块动画", Callback = stopAllAnimations})
	end

	return {
		Destroy = destroy,
		stopAnimations = stopAnimations,
		setEnabled = setEnabled,
		setChatSyncEnabled = setChatSyncEnabled,
		getChatSyncStatus = function() return chatSyncStatus end,
		playCustomAnim = playCustomAnim,
		setLocomotionEnabled = setLocomotionEnabled,
		setLocomotionProfile = setLocomotionProfile,
		getLocomotionStatus = function() return locomotionStatus end,
		stopAllAnimations = stopAllAnimations,
		setSilAnimationEnabled = setSilAnimationEnabled,
		getSilAnimationStatus = function() return sil.status end,
		buildFakeBlockGui = buildFakeBlockGui,
		triggerFakeBlock = triggerFakeBlock,
		destroyFakeBlockGui = destroyFakeBlockGui,
		chargeStateSave = chargeStateSave,
		chargeStateRestore = chargeStateRestore,
		ensureSingleGui = ensureSingleGui,
	}
end

end)()
-- Vortexion - Forsaken · WindUI 中文手机版 (based on NumanLUAU/Goonsaken-Hub, source 2026-05-13)
-- Community modification: UI localization + Android touch compatibility.
-- No guarantee of executor compatibility or live-game feature support.
-- Phase 1 has no published independent loader yet; NEVER reload the old repo on teleport.
-- Phase 2 will populate this with the verified standalone GitHub raw URL.
local hubLoader = nil
if type(hubLoader) == "string" and hubLoader ~= "" then
    if queue_on_teleport then
        queue_on_teleport(hubLoader)
    elseif syn and syn.queue_on_teleport then
        syn.queue_on_teleport(hubLoader)
    end
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RNG = Random.new()
-- v8: stop previous session's throttled background jobs on reinjection.
local sessionEnv = (getgenv and getgenv()) or _G
if type(sessionEnv.VortexionForsakenCleanup) == "function" then
    pcall(sessionEnv.VortexionForsakenCleanup)
end
sessionEnv.VortexionSessionId = (sessionEnv.VortexionSessionId or 0) + 1
local thisSessionId = sessionEnv.VortexionSessionId
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:WaitForChild("Animator")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local TextChatService = game:GetService("TextChatService")
local chatWindow = TextChatService:FindFirstChild("ChatWindowConfiguration")
local Do1x1PopupsLoop = false
local AntiSlow = false
local hubLoaded = false
local timeforonegen = 2.5
local loopgen = false
local autofixgenerator = false
local infinitestamina
local ChargeSpeedLoop = false
local GuestChargeSpeed = 2.833
local Sprinting
local stamina
-- Throttled task runner
local function runEvery(interval, fn)
    task.spawn(function()
        while sessionEnv.VortexionSessionId == thisSessionId do
            local ok, err = pcall(fn)
            if not ok then warn("[runEvery]", err) end
            task.wait(interval)
        end
    end)
end

-- Simple connection bucket so we can clean up safely if needed
local Connections = {}
local function track(conn)
    -- Retain active connections only across repeated native UI toggles.
    for i = #Connections, 1, -1 do
        if not Connections[i].Connected then table.remove(Connections, i) end
    end
    table.insert(Connections, conn)
    return conn
end
local function disconnectAll()
    for i = #Connections, 1, -1 do local c = Connections[i]
        if c and c.Disconnect then pcall(function() c:Disconnect() end) end
        Connections[i] = nil
    end
end


local executor = sessionEnv.identifyexecutor and sessionEnv.identifyexecutor() or "RobloxClientApp"

--[[
if executor == "Xeno" or executor == "Velocity" or executor == "LX63" then
	print("This script and game will NOT work on " .. tostring(executor) .. " as the entire game will break if you inject it even without loading a script. It's recommended to use Swift as it supports the require function. and the game often calls a require function everytime you spawn in as a killer or survivor since the game needs to load in the stamina module as well as sprinting and abilities so when your executor injects this. it will fail on requiring the stamina module and the game will halt without being able to load anything else.")
	return
end
]]--

local ORIGINAL_DASH_SPEED = 60

local isOverrideActive = false
local connection
local dashHumanoid, dashSaved = nil, {}
local function restoreDash(hum)
    local saved = hum and dashSaved[hum]
    if not saved then return end
    pcall(function()
        hum.WalkSpeed, hum.AutoRotate = saved.WalkSpeed, saved.AutoRotate
        hum:Move(Vector3.zero)
    end)
    dashSaved[hum] = nil
end
local function startvoidrushcontrol()
    if isOverrideActive then return end
    isOverrideActive = true
    connection = RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if dashHumanoid ~= hum then restoreDash(dashHumanoid); dashHumanoid = hum end
        if not (hum and root and hum.Health > 0) then return end
        if not dashSaved[hum] then dashSaved[hum] = {WalkSpeed = hum.WalkSpeed, AutoRotate = hum.AutoRotate} end
        hum.WalkSpeed, hum.AutoRotate = ORIGINAL_DASH_SPEED, false
        local direction = root.CFrame.LookVector
        local horizontal = Vector3.new(direction.X, 0, direction.Z)
        hum:Move(horizontal.Magnitude > 0.01 and horizontal.Unit or Vector3.new(0, 0, -1))
    end)
    track(connection)
end
local function stopvoidrushcontrol()
    isOverrideActive = false
    if connection then connection:Disconnect(); connection = nil end
    for hum in pairs(dashSaved) do restoreDash(hum) end
    dashHumanoid = nil
end

local function fireproximityprompt(Obj, Amount, Skip)
    if Obj.ClassName == "ProximityPrompt" then
        Amount = Amount or 1
        local PromptTime = Obj.HoldDuration
        if Skip then
            Obj.HoldDuration = 0
        end
        for i = 1, Amount do
            Obj:InputHoldBegin()
            if not Skip then
                task.wait(Obj.HoldDuration)
            end
            Obj:InputHoldEnd()
        end
        Obj.HoldDuration = PromptTime
    else
        error("userdata<ProximityPrompt> expected")
    end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local NameProtectActive = false
local function NameProtect()
	while NameProtectActive do
		task.wait(0.3)
        local gui = LocalPlayer.PlayerGui
        if not gui then return end

        --  TemporaryUI.PlayerInfo.CurrentSurvivors -> Username
        local currentSurvivors = gui:FindFirstChild("TemporaryUI")
            and gui.TemporaryUI:FindFirstChild("PlayerInfo")
            and gui.TemporaryUI.PlayerInfo:FindFirstChild("CurrentSurvivors")

        if currentSurvivors then
            for _, v in pairs(currentSurvivors:GetDescendants()) do
                if v:IsA("TextLabel") and v.Name == "Username" then
                    v.Text = "Protected"
                end
            end
        end

        --  TemporaryUI -> any TextLabel named "Title3"
        local tempUI = gui:FindFirstChild("TemporaryUI")
        if tempUI then
            for _, v in pairs(tempUI:GetDescendants()) do
                if v:IsA("TextLabel") and v.Name == "Title3" then
                    v.Text = "Protected"
                end
            end
        end

        --  MainUI.PlayerListHolder.Contents.Players -> Username
        local mainPlayers = gui:FindFirstChild("MainUI")
            and gui.MainUI:FindFirstChild("PlayerListHolder")
            and gui.MainUI.PlayerListHolder:FindFirstChild("Contents")
            and gui.MainUI.PlayerListHolder.Contents:FindFirstChild("Players")

        if mainPlayers then
            for _, v in pairs(mainPlayers:GetDescendants()) do
                if v:IsA("TextLabel") and v.Name == "Username" then
                    v.Text = "Protected"
                end
            end
        end

        --  TemporaryUI -> PlayerName / PlayerUsername text labels matching LocalPlayer usernames
        if tempUI then
            for _, v in pairs(tempUI:GetDescendants()) do
                if v:IsA("TextLabel") and (v.Name == "PlayerName" or v.Name == "PlayerUsername") then
                    for _, plr in pairs(Players:GetPlayers()) do
                        if v.Text == plr.Name then
                            v.Text = "Protected"
                            v.Text = "@Protected" -- optional
                        end
                    end
                end
            end
        end

        --  Workspace.Players.Spectating -> humanoids, set DisplayDistanceType to None
        local spectatingFolder = workspace:FindFirstChild("Players")
            and workspace.Players:FindFirstChild("Spectating")

        if spectatingFolder then
            for _, char in pairs(spectatingFolder:GetChildren()) do
                local humanoid = char:FindFirstChildWhichIsA("Humanoid")
                if humanoid then
                    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                end
            end
        end

        --  ImageLabels named after LocalPlayers
        for _, plr in pairs(Players:GetPlayers()) do
            local imgLabel = gui:FindFirstChild(plr.Name, true) -- recursive
            if imgLabel and imgLabel:IsA("ImageLabel") then
                local basicInfo = imgLabel:FindFirstChild("BasicInfo")
                if basicInfo then
                    local nameLabel = basicInfo:FindFirstChild("PlayerName")
                    if nameLabel and nameLabel:IsA("TextLabel") then
                        nameLabel.Text = "Protected"
                    end
                    local usernameLabel = basicInfo:FindFirstChild("PlayerUsername")
                    if usernameLabel and usernameLabel:IsA("TextLabel") then
                        usernameLabel.Text = "Protected"
                    end
                end
            end
        end

        --  MainUI.Spectate -> Username
        local spectateUI = gui:FindFirstChild("MainUI")
            and gui.MainUI:FindFirstChild("Spectate")

        if spectateUI then
            for _, v in pairs(spectateUI:GetDescendants()) do
                if v:IsA("TextLabel") and v.Name == "Username" then
                    v.Text = "Protected"
                end
            end
        end

        --  EndScreen -> ChosenValue.Title
        local chosenTitle = gui:FindFirstChild("EndScreen")
            and gui.EndScreen:FindFirstChild("Main")
            and gui.EndScreen.Main:FindFirstChild("PlayerStats")
            and gui.EndScreen.Main.PlayerStats:FindFirstChild("Header")
            and gui.EndScreen.Main.PlayerStats.Header:FindFirstChild("PlayerDropdown")
            and gui.EndScreen.Main.PlayerStats.Header.PlayerDropdown:FindFirstChild("DropdownFrame")
            and gui.EndScreen.Main.PlayerStats.Header.PlayerDropdown.DropdownFrame:FindFirstChild("ChosenValue")
            and gui.EndScreen.Main.PlayerStats.Header.PlayerDropdown.DropdownFrame.ChosenValue:FindFirstChild("Title")

        if chosenTitle and chosenTitle:IsA("TextLabel") then
            chosenTitle.Text = "Protected"
        end

        --  EndScreen.WinnerTitle.Usernames
        local winnerUsernames = gui:FindFirstChild("EndScreen")
            and gui.EndScreen:FindFirstChild("WinnerTitle")
            and gui.EndScreen.WinnerTitle:FindFirstChild("Usernames")

        if winnerUsernames and winnerUsernames:IsA("TextLabel") then
            winnerUsernames.Text = "Protected"
        end
	end
end

local multiplierNames = {
    "FallSlowness",
    "Medkit",
    "BloxyColaItem",
	"GuestBlocking",
	"BeheadAbility",
	"GuestChargeEnded"
}

-- Function to check and force multipliers
local function enforceMultipliers()
    local character = LocalPlayer.Character
    if not character then return end

    local speedMultipliers = character:FindFirstChild("SpeedMultipliers")
    if not speedMultipliers then return end

    for _, name in ipairs(multiplierNames) do
        local mult = speedMultipliers:FindFirstChild(name)
        if mult then
            mult.Value = 1
        end
    end
end

local function firetouchinterest(totouch, whattotouchwith,nilvalue)
    pcall(function()
        local clone = totouch:Clone()
        local orgpos = totouch.CFrame
        totouch.CFrame = whattotouchwith.CFrame
        task.wait(0.5)
        totouch.CFrame = orgpos
        clone:Destroy()
    end)
end

track(LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    local hum = char:WaitForChild("Humanoid", 10)
    local root = char:WaitForChild("HumanoidRootPart", 10)
    if LocalPlayer.Character ~= char or sessionEnv.VortexionSessionId ~= thisSessionId then return end
    Humanoid, HumanoidRootPart = hum, root
    Animator = hum and hum:FindFirstChildOfClass("Animator")
end))

local function checkAndSetSlowStatus()
    if AntiSlow == false then
        return
    end
	local Character = LocalPlayer.Character
	if not Character then return end
	local Humanoid = Character:WaitForChild("Humanoid")

    local speedMultipliers = Character:FindFirstChild("SpeedMultipliers")
    if not speedMultipliers then return end

    local slowedStatus = speedMultipliers:FindFirstChild("SlowedStatus")
    if not slowedStatus or not slowedStatus:IsA("NumberValue") then return end

    slowedStatus.Value = 1

    local fovMultipliers = Character:FindFirstChild("FOVMultipliers")
    if not fovMultipliers then return end

    local fovSlowedStatus = fovMultipliers:FindFirstChild("SlowedStatus")
    if not fovSlowedStatus or not fovSlowedStatus:IsA("NumberValue") then return end

    fovSlowedStatus.Value = 1

    -- Remove Slowness UI if it exists
    local LocalPlayerGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
    if LocalPlayerGui then
        local mainUI = LocalPlayerGui:FindFirstChild("MainUI")
        if mainUI then
            local statusContainer = mainUI:FindFirstChild("StatusContainer")
            if statusContainer then
                local slownessUI = statusContainer:FindFirstChild("Slowness")
                if slownessUI then
                    slownessUI.Visible = false
                end
            end
        end
    end
end

-- VirtualInputManager once (it was used but never defined)
local VIM
pcall(function() VIM = game:GetService("VirtualInputManager") end)

local function Do1x1x1x1Popups()
    -- Single cancellable worker; does not leave duplicate polling loops after toggling.
    while Do1x1PopupsLoop do
        local ok, err = pcall(function()
            local tempUI = PlayerGui:FindFirstChild("TemporaryUI")
            if not tempUI or not VIM then return end
            for _, popup in ipairs(tempUI:GetChildren()) do
                if popup.Name == "1x1x1x1Popup" and popup:IsA("GuiObject") then
                    local cx = popup.AbsolutePosition.X + popup.AbsoluteSize.X * 0.5
                    local cy = popup.AbsolutePosition.Y + popup.AbsoluteSize.Y * 0.5
                    VIM:SendMouseButtonEvent(cx, cy, Enum.UserInputType.MouseButton1.Value, true, PlayerGui, 1)
                    VIM:SendMouseButtonEvent(cx, cy, Enum.UserInputType.MouseButton1.Value, false, PlayerGui, 1)
                end
            end
        end)
        if not ok then warn("[Vortexion] 弹窗触控失败: " .. tostring(err)) end
        task.wait(0.1)
    end
end

local existence
local animTrack
local running = false
local timebetweenpuzzles = 3

local MaxRange = 120
local hitboxmodificationEnabled = false

local function ToggleInvis(enabled)
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    if enabled then
        running = true
        spawn(function()
            while running do
                local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if not humanoid then return end
                print("got humanoid")

                local animator = humanoid:FindFirstChildOfClass("Animator")
                if not animator then
                    animator = Instance.new("Animator")
                    animator.Parent = humanoid
                end

                if true then
                    if not animTrack or not animTrack.IsPlaying then
                        local animation = Instance.new("Animation")
                        animation.AnimationId = "rbxassetid://75804462760596"
                        animTrack = animator:LoadAnimation(animation)
                        animTrack.Looped = true
                        animTrack:Play()
                        animTrack:AdjustSpeed(0)
                        humanoid.Parent.HumanoidRootPart.Transparency = 0.4
                    end
                else
                    if animTrack and animTrack.IsPlaying then
                        animTrack:Stop()
                        animTrack = nil
                        humanoid.Parent.HumanoidRootPart.Transparency = 1
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        running = false
        if animTrack and animTrack.IsPlaying then
            animTrack:Stop()
            animTrack = nil
            humanoid.Parent.HumanoidRootPart.Transparency = 1
        end
    end
end

local function handleToggle(enabled)
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    if enabled then
        running = true
        spawn(function()
            while running do
                local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if not humanoid then return end

                local animator = humanoid:FindFirstChildOfClass("Animator")
                if not animator then
                    animator = Instance.new("Animator")
                    animator.Parent = humanoid
                end

                local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
                if torso and torso.Transparency ~= 0 then
                    if not animTrack or not animTrack.IsPlaying then
                        local animation = Instance.new("Animation")
                        animation.AnimationId = "rbxassetid://75804462760596"
                        animTrack = animator:LoadAnimation(animation)
                        animTrack.Looped = true
                        animTrack:Play()
                        animTrack:AdjustSpeed(0)
						humanoid.Parent.HumanoidRootPart.Transparency = 0.4
                    end
                else
                    if animTrack and animTrack.IsPlaying then
                        animTrack:Stop()
                        animTrack = nil
						humanoid.Parent.HumanoidRootPart.Transparency = 1
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        running = false
        if animTrack and animTrack.IsPlaying then
            animTrack:Stop()
            animTrack = nil
			humanoid.Parent.HumanoidRootPart.Transparency = 1
        end
    end
end

local LMSSongs = {
    ["Burnout"] = "rbxassetid://130101085745481",
    ["Compass"] = "rbxassetid://127298326178102",
    ["Vanity"] = "rbxassetid://137266220091579",
    ["Close To Me"] = "rbxassetid://90022574613230",
    ["Plead"] = "rbxassetid://80564889711353",
    ["Creation Of Hatred"] = "rbxassetid://115884097233860",
}

local GuestSettingsTriggerAnims = {
    "126830014841198", "126355327951215", "121086746534252", "18885909645",
    "98456918873918", "105458270463374", "83829782357897", "125403313786645",
    "118298475669935", "82113744478546", "70371667919898", "99135633258223",
    "97167027849946", "109230267448394", "139835501033932", "126896426760253",
    "109667959938617", "126681776859538", "129976080405072", "121293883585738",
    "81639435858902", "137314737492715", "92173139187970", "106847695270773"
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer

local blockingKillers = {}
local GuestSettingsLoop -- will hold the connection

local function getKillerActiveTriggerAnim(killer)
    local hum = killer:FindFirstChildWhichIsA("Humanoid")
    if hum and hum:FindFirstChild("Animator") then
        for _, track in ipairs(hum.Animator:GetPlayingAnimationTracks()) do
            local animId = track.Animation.AnimationId
            for _, id in ipairs(GuestSettingsTriggerAnims) do
                if string.find(animId, id) then
                    return animId
                end
            end
        end
    end
    return nil
end

local function getPunchCharges()
    local guiObj = localPlayer.PlayerGui:FindFirstChild("MainUI")
    if guiObj then
        local abilityContainer = guiObj:FindFirstChild("AbilityContainer", true)
        if abilityContainer and abilityContainer:FindFirstChild("Punch") then
            local punchObj = abilityContainer.Punch:FindFirstChild("Charges")
            if punchObj then
                return tostring(punchObj.Text)
            end
        end
    end
    return nil
end

local function startBlockTp(state)
    if state then return end -- Already running

    GuestSettingsLoop = RunService.RenderStepped:Connect(function()
        local char = localPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end

        local killersFolder = workspace.Players and workspace.Players:FindFirstChild("Killers")
        if not killersFolder then return end
        for _, killer in ipairs(killersFolder:GetChildren()) do
            if not (killer:IsA("Model") and killer:FindFirstChild("HumanoidRootPart")) then
                blockingKillers[killer] = nil
                continue
            end

            local activeAnim = getKillerActiveTriggerAnim(killer)
            if not activeAnim then
                blockingKillers[killer] = nil
                continue
            end

            if blockingKillers[killer] == activeAnim or getPunchCharges() ~= "0" then
                continue
            end

            -- Mark killer as blocking
            blockingKillers[killer] = activeAnim
            local originalCF = char.HumanoidRootPart.CFrame

            -- Fire block
            local okFireBlock = pcall(function()
                local rs = game:GetService("ReplicatedStorage")
                local modules = rs:FindFirstChild("Modules")
                local network = modules and modules:FindFirstChild("Network")
                local remote = network and network:FindFirstChild("RemoteEvent")
                if remote then
                    remote:FireServer("UseActorAbility", "Block")
                end
            end)
            if not okFireBlock then continue end

            -- Teleport in front of killer
            local killerHRP = killer.HumanoidRootPart
            local function teleportInFront()
                char.HumanoidRootPart.CFrame = CFrame.new(killerHRP.Position + killerHRP.CFrame.LookVector * 2)
            end
            teleportInFront()

            -- Keep teleporting until animation ends or punch charge = "1"
            task.spawn(function()
                while sessionEnv.VortexionSessionId == thisSessionId do
                    task.wait(0.05)
                    if not (localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")) then break end

                    teleportInFront()

                    local charges = getPunchCharges()
                    local currentAnim = getKillerActiveTriggerAnim(killer)
                    if charges == "1" or currentAnim ~= activeAnim then
                        -- Restore original position
                        if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            localPlayer.Character.HumanoidRootPart.CFrame = originalCF
                        end
                        blockingKillers[killer] = nil
                        break
                    end
                end
            end)
        end
    end)
end

local selectedSong = "Burnout" -- default

local soundPlayer = Instance.new("Sound")
soundPlayer.Name = "GoonsakenHub_Sound"
soundPlayer.Parent = Workspace
soundPlayer.Looped = false
soundPlayer.Volume = 5

-- Forward declarations keep menu callbacks bound to this session.
local Window, Tabs, Fluent
local emoteButtons = {}
local function getEquippedEmotes()
    local data = LocalPlayer:FindFirstChild("PlayerData")
    local equipped = data and data:FindFirstChild("Equipped")
    local emotes = equipped and equipped:FindFirstChild("Emotes")
    return string.split(emotes and emotes.Value or "", "|")
end

local function KillerEmoteGUI()
    if not (Window and Tabs and Tabs.Emotes) then return end
    local legacy = PlayerGui:FindFirstChild("KillerEmoteGUI")
    if legacy then legacy:Destroy() end
    local emotes = getEquippedEmotes()
    for slot = 1, 8 do
        if not emoteButtons[slot] then
            local emoteSlot = slot
            emoteButtons[slot] = Tabs.Emotes:AddButton({
                Title = "表情槽 " .. tostring(slot),
                Callback = function()
                    local name = getEquippedEmotes()[emoteSlot]
                    if not name or name == "" then
                        Fluent:Notify({ Title = "杀手表情", Content = "此槽位未装备表情。", Duration = 3 })
                        return
                    end
                    pcall(function()
                        local modules = game:GetService("ReplicatedStorage"):FindFirstChild("Modules")
                        local network = modules and modules:FindFirstChild("Network")
                        local remote = network and network:FindFirstChild("RemoteEvent")
                        if remote then remote:FireServer("PlayEmote", "Animations", name) end
                    end)
                end
            })
        end
        local button = emoteButtons[slot] and (emoteButtons[slot].Native or emoteButtons[slot])
        if button and button.SetTitle then
            local name = emotes[slot]
            button:SetTitle("表情槽 " .. tostring(slot) .. " · " .. ((name and name ~= "") and name or "未装备"))
        end
    end
    Window:SelectTab(6)
    if Window.Native and Window.Native.Open then Window.Native:Open() end
end

local timeAhead = 0.2

-- Prevent duplicate hub (if still present from other runs)
local existingGui = PlayerGui:FindFirstChild("GoonsakenHub")
if existingGui then
    existingGui:Destroy()
end

-- Preserve original logic variables
local statsGui
local ESP = {}
ESP.Enabled = false
-- Stage 2: category filters, details and a bounded, adjustable LOS refresh budget.
ESP.ShowKillers = true
ESP.ShowSurvivors = true
ESP.ShowLabels = true
ESP.ShowDetails = false
ESP.VisibleAlpha = 0.80
ESP.CheckHz = 10
ESP.LastCheck = 0
-- Feature architecture: OPAI generator-status ESP + c00lSaken threat awareness.
ESP.GeneratorDetails = false
ESP.CompletedGenerators = false
ESP.GeneratorLabelRecords = setmetatable({}, {__mode = "k"})

local PLAYER_ESP_NAME = "PlayerESP"
local ITEM_ESP_NAME = "ToolESPHighlight"
local GENERATOR_ESP_NAME = "GeneratorESP"
local TRAPSANDSPIKES_ESP_NAME = "TrapsandSpikesESP"

local aimbotConnection

local function findNearestGenerator()
    local mapFolder = Workspace:FindFirstChild("Map")
    if not mapFolder then return nil end
    local ingameMap = mapFolder:FindFirstChild("Ingame")
    if not ingameMap then return nil end
    local map = ingameMap:FindFirstChild("Map")
    if not map then return nil end

    local generators = {}
    for _, obj in pairs(map:GetChildren()) do
        if obj.Name == "Generator" and obj:IsA("Model") then
            table.insert(generators, obj)
        end
    end

    if #generators == 0 then return nil end

    local LocalPlayerRoot = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not LocalPlayerRoot then return nil end

    local nearestGen = nil
    local nearestDist = math.huge

    for _, gen in pairs(generators) do
        local genRoot = gen:FindFirstChild("HumanoidRootPart") or gen.PrimaryPart
        if genRoot then
            local dist = (genRoot.Position - LocalPlayerRoot.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearestGen = gen
            end
        end
    end

    return nearestGen
end

local function findNearestValidGenerator()
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end
    local ingame = map:FindFirstChild("Ingame")
    if not ingame then return nil end
    local container = ingame:FindFirstChild("Map")
    if not container then return nil end

    local nearest
    local shortestDist = math.huge
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    for _, gen in ipairs(container:GetDescendants()) do
        if gen.Name == "Generator" and gen:IsA("Model") and gen:FindFirstChild("Progress") and gen.Progress.Value < 100 then
            local dist = (gen.PrimaryPart.Position - root.Position).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                nearest = gen
            end
        end
    end

    return nearest
end

local function triggerNearestGenerator(shouldLoop)
	while shouldLoop do
		looping = true
		task.wait(timeforonegen + math.random() * 0.5)
		local MapFolder = workspace:FindFirstChild("Map")
			and workspace.Map:FindFirstChild("Ingame")
			and workspace.Map.Ingame:FindFirstChild("Map")
		local character = LocalPlayer.Character; local hrp = character and character:FindFirstChild("HumanoidRootPart"); if MapFolder and hrp then
			local closestGenerator, closestDistance = nil, math.huge
			local playerPosition = hrp.Position
			for _, g in ipairs(MapFolder:GetChildren()) do
				local progress = g:FindFirstChild("Progress"); local main = g:FindFirstChild("Main"); if g.Name == "Generator" and progress and main and progress.Value < 100 then
					local distance = (main.Position - playerPosition).Magnitude
					if distance < closestDistance then
						closestDistance = distance
						closestGenerator = g
					end
				end
			end
			if closestGenerator then
				local remotes = closestGenerator:FindFirstChild("Remotes"); local re = remotes and remotes:FindFirstChild("RE"); if re then re:FireServer() end
			end
		end
	end
	looping = false
end

-- Enable aimbot function
local function enableAimbot()
    local lastPositions = {}
    local deltaTime = 0.03

    aimbotConnection = RunService.Heartbeat:Connect(function()
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Parent then
            local flintlock = humanoid.Parent:FindFirstChild("Flintlock")
            if flintlock and flintlock.Transparency == 0 then
                local killersFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
                if killersFolder then
                    for _, killerModel in pairs(killersFolder:GetChildren()) do
                        if killerModel:IsA("Model") and killerModel:FindFirstChild("HumanoidRootPart") then
                            local hrp = killerModel.HumanoidRootPart
                            local currentPos = hrp.Position
                            local prevPos = lastPositions[killerModel]
                            local velocity = Vector3.new(0, 0, 0)

                            if prevPos then
                                velocity = (currentPos - prevPos) / deltaTime
                            end
                            lastPositions[killerModel] = currentPos

                            local predictedPos = currentPos + velocity * timeAhead

                            local rootPart = character:FindFirstChild("HumanoidRootPart")
                            if rootPart and (predictedPos - rootPart.Position).Magnitude > 0.01 then
								if humanoid then
									humanoid.AutoRotate = false
								end
                                rootPart.CFrame = CFrame.new(rootPart.Position, predictedPos)
                            end
                        end
                    end
                end
			else
				if humanoid then
					humanoid.AutoRotate = true
				end
			end
		end
    end)
end

-- Disable aimbot function
local function disableAimbot()
    if aimbotConnection then
		local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.AutoRotate = true
		end
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
end

local COLOR_SURVIVOR = Color3.fromRGB(0, 255, 0)
local COLOR_KILLER = Color3.fromRGB(255, 0, 0)
local COLOR_TRAPSANDSPIKES = Color3.fromRGB(255, 0, 0)
local COLOR_MEDKIT = Color3.fromRGB(0, 255, 0)
local COLOR_COLA = Color3.fromRGB(0, 150, 255)
local COLOR_GENERATOR = Color3.fromRGB(255, 255, 0)

-- Store all highlights to toggle visibility
local allHighlights = {}

local function setHighlightVisibility(highlight, visible)
    if visible then
        highlight.FillTransparency = 0.8
        highlight.OutlineTransparency = 0
    else
        highlight.FillTransparency = 1
        highlight.OutlineTransparency = 1
    end
end

-- Player ESP
local PlayersFolder = Workspace:WaitForChild("Players", 30) or Instance.new("Folder")

do
-- v3: Trap ESP is indexed once per map and incrementally maintained on instance additions.
-- Avoid the old every-0.5s GetDescendants() scan with nested descendant searches.
local trapFolder, trapAddedConnection
local function trapHighlight(target, color)
    if not target or target:FindFirstChild(TRAPSANDSPIKES_ESP_NAME) then return end
    local hl = Instance.new("Highlight")
    hl.Name = TRAPSANDSPIKES_ESP_NAME
    hl.FillColor = color or COLOR_TRAPSANDSPIKES
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.Adornee = target
    hl.Parent = target
    setHighlightVisibility(hl, ESP.Enabled)
    allHighlights[hl] = true
end
local SPECIAL_ESP_COLORS = {
    PizzaDeliveryRig = Color3.fromRGB(255, 170, 45),
    PizzaBot = Color3.fromRGB(255, 170, 45),
    Zombie = Color3.fromRGB(255, 96, 96),
    Tripwire = Color3.fromRGB(184, 110, 255),
    Tripmine = Color3.fromRGB(232, 90, 255),
    Graffiti = Color3.fromRGB(245, 245, 245),
    GroundBulb = Color3.fromRGB(22, 225, 202),
    Vine = Color3.fromRGB(146, 82, 255),
}
local function inspectTrapNode(node, ingame)
    if not (node:IsA("BasePart") or node:IsA("Model")) then return end
    local name = node.Name
    local special = SPECIAL_ESP_COLORS[name]
    if special then
        trapHighlight(node, special)
        return
    end
    if name == "Spike" or name == "SubspaceTripmine" or name == "Shadow" or name:find("RespawnLocation", 1, true) then
        if name == "Shadow" or name:find("RespawnLocation", 1, true) then
            if node:IsA("BasePart") then
                if node.Transparency ~= 0 then node.Transparency = 0 end
            elseif node:IsA("Model") then
                for _, part in ipairs(node:GetDescendants()) do
                    if part:IsA("BasePart") and part.Transparency ~= 0 then part.Transparency = 0 end
                end
            end
        end
        trapHighlight(node)
    elseif name == "Hook1" and node:IsA("BasePart") then
        -- Highlight the smallest containing trap model instead of the entire level.
        local parent = node.Parent
        while parent and parent ~= ingame and not parent:IsA("Model") do
            parent = parent.Parent
        end
        if parent and parent ~= ingame and parent:IsA("Model") then trapHighlight(parent) end
    end
end
local function bindTrapFolder(ingame)
    if not ingame or trapFolder == ingame then return end
    if trapAddedConnection then trapAddedConnection:Disconnect(); trapAddedConnection = nil end
    trapFolder = ingame
    trapAddedConnection = ingame.DescendantAdded:Connect(function(node)
        inspectTrapNode(node, ingame)
    end)
    task.spawn(function()
        local nodes = ingame:GetDescendants()
        for i, node in ipairs(nodes) do
            if trapFolder ~= ingame or not ingame.Parent then return end
            inspectTrapNode(node, ingame)
            if i % 200 == 0 then task.wait() end -- bounded startup cost
        end
    end)
end
local function bindCurrentTrapMap()
    local map = Workspace:FindFirstChild("Map")
    local ingame = map and map:FindFirstChild("Ingame")
    if ingame then bindTrapFolder(ingame) end
end
bindCurrentTrapMap()
Workspace.ChildAdded:Connect(function(child)
    if child.Name == "Map" then
        local ingame = child:FindFirstChild("Ingame")
        if ingame then bindTrapFolder(ingame) end
        child.ChildAdded:Connect(function(part)
            if part.Name == "Ingame" then bindTrapFolder(part) end
        end)
    end
end)
if not trapFolder then
    -- In case the original Map container appears after startup.
    task.spawn(function()
        for _ = 1, 30 do
            if trapFolder then return end
            bindCurrentTrapMap()
            task.wait(1)
        end
    end)
end

end -- scoped performance/UI helpers

-- 独立的玩家 ESP：杀手红色、幸存者绿色。
-- 玩家可见性 = 位于屏幕内且相机至角色之间无实体障碍物（Raycast）。
-- 修订需求：被墙体遮挡或屏幕外 0% 透明（实体高亮完全不透明）；无遮挡 80% 透明。
-- 透明度 0 = 不透明；1 = 完全不可见。目标在物理屏幕外时无法实际绘制到屏幕中。
local PLAYER_ESP_ONSCREEN_ALPHA = 0.80
local PLAYER_ESP_OFFSCREEN_ALPHA = 0
local playerESPRecords = {}

-- 手机端性能约束：共用记录内的 RaycastParams，不在每帧重建配置；
-- 每位玩家最多 2 条射线（身体 + 头部），由既有 0.1s 调度器驱动。
local function isPlayerVisibleFromCamera(record, camera, targetPosition)
    local screenPoint, isOnScreen = camera:WorldToViewportPoint(targetPosition)
    if not (isOnScreen and screenPoint.Z > 0) then return false end

    local params = record.LOSParams
    if not params then
        params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true
        params.RespectCanCollide = true
        record.LOSParams = params
    end

    -- 排除自己的角色和目标角色本体，否则会把目标身体错误判成遮挡。
    local ownCharacter = LocalPlayer.Character
    if record.LOSOwnCharacter ~= ownCharacter then
        record.LOSOwnCharacter = ownCharacter
        local excluded = { record.Character }
        if ownCharacter then table.insert(excluded, ownCharacter) end
        params.FilterDescendantsInstances = excluded
    end

    local origin = camera.CFrame.Position
    local direction = targetPosition - origin
    if direction.Magnitude <= 0.01 then return true end
    local hit = Workspace:Raycast(origin, direction, params)
    return hit == nil or hit.Distance >= direction.Magnitude - 0.25
end

local function getESPUsername(character)
    local player = Players:GetPlayerFromCharacter(character)
    if player then
        return player.Name
    end
    for _, name in ipairs({ "Username", "UserName", "PlayerName" }) do
        local value = character:GetAttribute(name)
        if type(value) == "string" and value ~= "" then
            return value
        end
    end
    local matchingPlayer = Players:FindFirstChild(character.Name)
    if matchingPlayer and matchingPlayer:IsA("Player") then
        return matchingPlayer.Name
    end
    return "未知玩家"
end

local function getESPRole(character)
    -- Forsaken 使用角色名称命名 Workspace.Players.Killers/Survivors 下的模型。
    local characterName = character:GetAttribute("CharacterName")
    if type(characterName) == "string" and characterName ~= "" then
        return characterName
    end
    local role = character:GetAttribute("Role")
    if type(role) == "string" and role ~= "" then
        return role
    end
    return character.Name
end

local function createESPText(parent, y, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 0, 20)
    label.Position = UDim2.fromOffset(4, y)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextColor3 = color
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextStrokeTransparency = 0.15
    label.TextTransparency = PLAYER_ESP_OFFSCREEN_ALPHA
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = parent
    return label
end

local function updatePlayerESP(record, camera)
    local character = record.Character
    local highlight = record.Highlight
    local billboard = record.Billboard
    if not character.Parent or not highlight.Parent or not billboard.Parent then
        return false
    end

    -- 每次刷新角色名称/阵营，以兼容换角色与中途回合变化。
    local side = character.Parent.Name
    local color = side == "Killers" and COLOR_KILLER or COLOR_SURVIVOR
    if highlight.FillColor ~= color then highlight.FillColor = color end
    if highlight.OutlineColor ~= color then highlight.OutlineColor = color end
    if record.RoleLabel.TextColor3 ~= color then record.RoleLabel.TextColor3 = color end

    local now = os.clock()
    if now >= (record.NextMetadataUpdate or 0) then
        local username = "用户名：" .. getESPUsername(character)
        local role = "角色：" .. getESPRole(character)
        if record.UsernameLabel.Text ~= username then record.UsernameLabel.Text = username end
        if record.RoleLabel.Text ~= role then record.RoleLabel.Text = role end
        record.NextMetadataUpdate = now + 1.0
    end

    local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
    if not (root and root:IsA("BasePart")) then root = nil end
    if root and billboard.Adornee ~= root then
        billboard.Adornee = root
        billboard.StudsOffsetWorldSpace = Vector3.new(0, root.Name == "Head" and -5 or -3.1, 0)
    end

    local unobstructed = false
    local selectedFaction = (side == "Killers" and ESP.ShowKillers) or (side == "Survivors" and ESP.ShowSurvivors)
    if ESP.Enabled and selectedFaction and camera and root and root:IsA("BasePart") then
        unobstructed = isPlayerVisibleFromCamera(record, camera, root.Position)
        -- 上半身露出掩体时也算可见，避免只测身体造成误判。
        if not unobstructed then
            local head = character:FindFirstChild("Head")
            if head and head:IsA("BasePart") and head ~= root then
                unobstructed = isPlayerVisibleFromCamera(record, camera, head.Position)
            end
        end
    end

    -- 墙后目标不能再使用 `Enabled = unobstructed`：那样会把 0% 透明度目标直接隐藏。
    -- 不显示本阵营或关掉 ESP 时才真正禁用；不可见或被墙遮挡则用 0% 透明度显示。
    local shouldShow = ESP.Enabled and selectedFaction and root ~= nil and root:IsA("BasePart")
    local alpha = shouldShow and (unobstructed and ESP.VisibleAlpha or PLAYER_ESP_OFFSCREEN_ALPHA) or 1
    if highlight.FillTransparency ~= alpha then highlight.FillTransparency = alpha end
    if highlight.OutlineTransparency ~= alpha then highlight.OutlineTransparency = alpha end
    if highlight.Enabled ~= shouldShow then highlight.Enabled = shouldShow end
    local showLabels = shouldShow and ESP.ShowLabels
    if billboard.Enabled ~= showLabels then billboard.Enabled = showLabels end
    if record.UsernameLabel.TextTransparency ~= alpha then record.UsernameLabel.TextTransparency = alpha end
    if record.RoleLabel.TextTransparency ~= alpha then record.RoleLabel.TextTransparency = alpha end
    if record.UsernameLabel.TextStrokeTransparency ~= alpha then record.UsernameLabel.TextStrokeTransparency = alpha end
    if record.RoleLabel.TextStrokeTransparency ~= alpha then record.RoleLabel.TextStrokeTransparency = alpha end

    -- 健康与距离是可选的；用限频采样避免手机上每个 ESP 周期重算。
    local detailLabel = record.DetailLabel
    if detailLabel then
        if detailLabel.Visible ~= ESP.ShowDetails then detailLabel.Visible = ESP.ShowDetails end
        if ESP.ShowDetails then
            if detailLabel.TextTransparency ~= alpha then detailLabel.TextTransparency = alpha end
            if detailLabel.TextStrokeTransparency ~= alpha then detailLabel.TextStrokeTransparency = alpha end
            if now >= (record.NextStatsUpdate or 0) then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local distance = myRoot and root and math.floor((myRoot.Position - root.Position).Magnitude + 0.5) or 0
                local health = humanoid and math.floor(humanoid.Health + 0.5) or 0
                local maxHealth = humanoid and math.floor(humanoid.MaxHealth + 0.5) or 0
                detailLabel.Text = string.format("生命：%d/%d · 距离：%d", health, maxHealth, distance)
                record.NextStatsUpdate = now + 0.5
            end
        end
    end
    return true
end

local function applyPlayerESP(character, color)
    if not character:IsA("Model") or character == LocalPlayer.Character then return end
    if character.Parent == nil then return end
    local earlyRoot = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
    if not (earlyRoot and earlyRoot:IsA("BasePart")) then
        return -- 刚出生时延后到下次扫描，不阻塞线程
    end

    local record = playerESPRecords[character]
    if record and record.Highlight.Parent and record.Billboard.Parent then
        -- 继续使用原来的对象；updatePlayerESP 会处理角色换边。
        return
    end
    playerESPRecords[character] = nil

    local existingHighlight = character:FindFirstChild(PLAYER_ESP_NAME)
    if existingHighlight and not existingHighlight:IsA("Highlight") then
        existingHighlight:Destroy()
        existingHighlight = nil
    end
    local highlight = existingHighlight or Instance.new("Highlight")
    highlight.Name = PLAYER_ESP_NAME
    highlight.Adornee = character
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = PLAYER_ESP_OFFSCREEN_ALPHA
    highlight.OutlineTransparency = PLAYER_ESP_OFFSCREEN_ALPHA
    highlight.Enabled = false -- 开关关闭时必须保持不可见，首次 update 再确定阵营状态
    highlight.Parent = character
    allHighlights[highlight] = true

    local previousBillboard = character:FindFirstChild("PlayerESPBillboard", true)
    if previousBillboard then previousBillboard:Destroy() end

    local root = earlyRoot
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlayerESPBillboard"
    billboard.Adornee = root
    billboard.Size = UDim2.fromOffset(220, 64)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, root.Name == "Head" and -5 or -3.1, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    billboard.MaxDistance = 5000
    billboard.Parent = root

    local usernameLabel = createESPText(billboard, 0, Color3.fromRGB(245, 245, 245))
    usernameLabel.Name = "Username"
    local roleLabel = createESPText(billboard, 20, color)
    roleLabel.Name = "Role"
    local detailLabel = createESPText(billboard, 40, Color3.fromRGB(225, 225, 225))
    detailLabel.Name = "HealthDistance"
    detailLabel.Visible = false

    record = {
        Character = character,
        Highlight = highlight,
        Billboard = billboard,
        UsernameLabel = usernameLabel,
        RoleLabel = roleLabel,
        DetailLabel = detailLabel,
    }
    playerESPRecords[character] = record
    updatePlayerESP(record, Workspace.CurrentCamera)
end

-- 非关键 ESP 投影刷新节流：CheckHz 与桥接返回都有界化，
-- 拒绝 inf/nan 造成冻结或绕过节流（与其余三路同一契约）。
local function espThrottleInterval()
    local checkHz = tonumber(ESP.CheckHz) or 10
    if checkHz ~= checkHz or checkHz == math.huge or checkHz == -math.huge then checkHz = 10 end
    local interval = 1 / math.max(2, math.min(20, checkHz))
    local bridgeOk, bridged = pcall(function()
        if Fluent and type(Fluent.GetVisualInterval) == "function" then
            return Fluent:GetVisualInterval(interval)
        end
        return nil
    end)
    if bridgeOk and type(bridged) == "number" and bridged == bridged
        and bridged ~= math.huge and bridged ~= -math.huge and bridged > 0 then
        interval = math.max(interval, bridged)
    end
    return interval
end

-- 固定最多约 10 次/秒检查屏幕投影，避免在手机端逐帧扫描地图。
runEvery(0.05, function()
    if not ESP.Enabled then return end
    local now = os.clock()
    local espInterval = espThrottleInterval()
    if now - ESP.LastCheck < espInterval then return end
    ESP.LastCheck = now
    local camera = Workspace.CurrentCamera
    for character, record in pairs(playerESPRecords) do
        if not updatePlayerESP(record, camera) then
            allHighlights[record.Highlight] = nil
            playerESPRecords[character] = nil
        end
    end
end)

-- Item ESP
local function applyItemHighlight(tool, color)
    if not tool:FindFirstChild(ITEM_ESP_NAME) then
        local highlight = Instance.new("Highlight")
        highlight.Name = ITEM_ESP_NAME
        highlight.Adornee = tool
        highlight.FillColor = color
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.Parent = tool

        -- Set initial visibility
        setHighlightVisibility(highlight, ESP.Enabled)
        allHighlights[highlight] = true
    end
end

local function highlightToolIfNeeded(tool)
    if tool:IsA("Tool") then
        if tool.Name == "Medkit" then
            applyItemHighlight(tool, COLOR_MEDKIT)
        elseif tool.Name == "BloxyCola" or tool.Name == "Cola" then
            applyItemHighlight(tool, COLOR_COLA)
        end
    end
end

do
-- Generator ESP
local function addGeneratorHighlight(model)
    if model:FindFirstChild(GENERATOR_ESP_NAME) then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = GENERATOR_ESP_NAME
    highlight.FillColor = COLOR_GENERATOR
    highlight.Adornee = model
    highlight.Parent = model

    -- Set initial visibility
    setHighlightVisibility(highlight, ESP.Enabled)
    allHighlights[highlight] = true
end

local function removeGeneratorHighlight(model)
    local existing = model:FindFirstChild(GENERATOR_ESP_NAME)
    if existing then
        allHighlights[existing] = nil
        existing:Destroy()
    end
end

-- Generator details: progress and remaining distance are sampled on demand.
-- Use existing generator index and Progress.Changed, never a second map traversal.
local function updateGeneratorLabel(generator, genModel, progress, includeDistance)
    local record = ESP.GeneratorLabelRecords[generator]
    local completed = tonumber(progress.Value) and tonumber(progress.Value) >= 100
    local visible = ESP.Enabled and ESP.GeneratorDetails and (not completed or ESP.CompletedGenerators)
    if not visible and not record then return end
    if not record and visible then
        local part = genModel.PrimaryPart or genModel:FindFirstChildWhichIsA("BasePart", true)
        if not part then return end
        local gui = Instance.new("BillboardGui")
        gui.Name = "VortexionGeneratorLabel"
        gui.Size = UDim2.fromOffset(165, 35)
        gui.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)
        gui.AlwaysOnTop = true
        gui.MaxDistance = 1200
        gui.Adornee = part
        gui.Parent = genModel
        local text = Instance.new("TextLabel")
        text.Size = UDim2.fromScale(1, 1)
        text.BackgroundTransparency = 1
        text.TextColor3 = Color3.fromRGB(255, 223, 90)
        text.TextStrokeTransparency = 0.2
        text.TextSize = 13
        text.Font = Enum.Font.GothamBold
        text.Parent = gui
        record = {Gui=gui, Label=text, Part=part, LastDistance=-1}
        ESP.GeneratorLabelRecords[generator] = record
    end
    if not record.Gui.Parent then ESP.GeneratorLabelRecords[generator] = nil; return end
    record.Gui.Enabled = visible
    if not visible then return end
    local percentage = math.clamp(tonumber(progress.Value) or 0, 0, 100)
    local distance = record.LastDistance
    if includeDistance or distance < 0 then
        local ownRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        distance = ownRoot and math.floor((ownRoot.Position - record.Part.Position).Magnitude + 0.5) or -1
        record.LastDistance = distance
    end
    local text = (completed and "已完成" or ("修理 " .. tostring(math.floor(percentage)) .. "%"))
    if distance >= 0 then text = text .. " · " .. tostring(distance) .. " studs" end
    if record.Label.Text ~= text then record.Label.Text = text end
    local color = completed and Color3.fromRGB(155, 164, 176) or Color3.fromRGB(255, 223, 90)
    if record.Label.TextColor3 ~= color then record.Label.TextColor3 = color end
end

function ESP:RefreshGeneratorLabels()
    for generator in pairs(self.GeneratorLabelRecords) do
        local progress = generator:FindFirstChild("Progress")
        local instances = generator:FindFirstChild("Instances")
        local genModel = instances and instances:FindFirstChild("Generator")
        if not (generator.Parent and progress and genModel) then
            local record = self.GeneratorLabelRecords[generator]
            if record and record.Gui.Parent then record.Gui:Destroy() end
            self.GeneratorLabelRecords[generator] = nil
        else
            updateGeneratorLabel(generator, genModel, progress, true)
        end
    end
end

-- One slow worker already shared with the existing generator registry.
runEvery(1.0, function()
    if ESP.Enabled and ESP.GeneratorDetails then ESP:RefreshGeneratorLabels() end
end)

local trackedGeneratorProgress = setmetatable({}, {__mode = "k"})
local function trackGenerator(generator)
    if trackedGeneratorProgress[generator] then return end
    local progress = generator:FindFirstChild("Progress")
    local instances = generator:FindFirstChild("Instances")

    if not progress or not instances then return end

    local genModel = instances:FindFirstChild("Generator")
    if not genModel or not genModel:IsA("Model") then return end

    if progress.Value < 100 then
        addGeneratorHighlight(genModel)
    else
        removeGeneratorHighlight(genModel)
    end

    updateGeneratorLabel(generator, genModel, progress, false)
    trackedGeneratorProgress[generator] = progress:GetPropertyChangedSignal("Value"):Connect(function()
        if not generator.Parent then
            local connection = trackedGeneratorProgress[generator]
            if connection then connection:Disconnect() end
            trackedGeneratorProgress[generator] = nil
            return
        end
        if progress.Value >= 100 then
            removeGeneratorHighlight(genModel)
        else
            addGeneratorHighlight(genModel)
        end
        updateGeneratorLabel(generator, genModel, progress, false)
    end)
end

local function trackGeneratorsInFolder(folder)
    if not folder then return end
    for _, gen in ipairs(folder:GetDescendants()) do
        if gen.Name == "Generator" and gen:IsA("Model") then
            trackGenerator(gen)
        end
    end
end

-- Listen for Map creation / reload
workspace.ChildAdded:Connect(function(child)
    if child.Name == "Map" then
        task.wait(1)
        local ingame = child:FindFirstChild("Ingame")
        local mapContainer = ingame and ingame:FindFirstChild("Map")
        if mapContainer then
            trackGeneratorsInFolder(mapContainer)
        end
    end
end)

-- Also listen for new generators being added mid-game
workspace.DescendantAdded:Connect(function(obj)
    if obj.Name == "Generator" and obj:IsA("Model") then
        trackGenerator(obj)
    end
end)

runEvery(0.5, function()
    if not ESP.Enabled then return end -- No per-player discovery cost while ESP is off.
    -- 回合切换时回收旧角色 ESP，避免多局游戏后累积失效对象。
    for character, record in pairs(playerESPRecords) do
        if not character:IsDescendantOf(PlayersFolder)
            or not record.Highlight.Parent
            or not record.Billboard.Parent then
            allHighlights[record.Highlight] = nil
            if record.Highlight.Parent then record.Highlight:Destroy() end
            if record.Billboard.Parent then record.Billboard:Destroy() end
            playerESPRecords[character] = nil
        end
    end

    local survivors = PlayersFolder:FindFirstChild("Survivors")
    if survivors then
        for _, char in ipairs(survivors:GetChildren()) do
            applyPlayerESP(char, COLOR_SURVIVOR)
        end
    end

    local killers = PlayersFolder:FindFirstChild("Killers")
    if killers then
        for _, char in ipairs(killers:GetChildren()) do
            applyPlayerESP(char, COLOR_KILLER)
        end
    end

    -- Trap ESP is event-driven; no full-map poll here.
end)

-- v3: Single asynchronous initial tool scan; future tools are handled by events.
Workspace.DescendantAdded:Connect(highlightToolIfNeeded)
task.spawn(function()
    for i, tool in ipairs(Workspace:GetDescendants()) do
        highlightToolIfNeeded(tool)
        if i % 250 == 0 then task.wait() end
    end
end)

-- Generator ESP loop
-- Find map once (with retries), then track generators, plus a 0.5s poll for *new* generators
task.spawn(function()
    local mapContainer
    repeat
        local mapRoot = Workspace:FindFirstChild("Map")
        local ingame = mapRoot and mapRoot:FindFirstChild("Ingame")
        mapContainer = ingame and ingame:FindFirstChild("Map")
        task.wait(0.5)
    until mapContainer

    -- initial pass
    for _, gen in ipairs(mapContainer:GetChildren()) do
        if gen.Name == "Generator" and gen:IsA("Model") then
            trackGenerator(gen)  -- your existing function (it adds/removes a Highlight and binds to Progress)
        end
    end

    -- Later generators are already captured by Workspace.DescendantAdded.
end)

end -- scoped performance/UI helpers

-- Function to toggle ESP on/off
function ESP:SetEnabled(state)
    ESP.Enabled = not not state
    self:RefreshGeneratorLabels()
    -- 非玩家高亮维持原来的逻辑；玩家高亮无遮挡 80%，遮挡或屏幕外 0%。
    for highlight in pairs(allHighlights) do
        if highlight.Parent == nil then
            allHighlights[highlight] = nil
        elseif highlight.Name ~= PLAYER_ESP_NAME then
            setHighlightVisibility(highlight, ESP.Enabled)
        end
    end
    local camera = Workspace.CurrentCamera
    for character, record in pairs(playerESPRecords) do
        if not updatePlayerESP(record, camera) then
            allHighlights[record.Highlight] = nil
            playerESPRecords[character] = nil
        end
    end
end

-- Player statistics are game controls; native WindUI owns the list and scrolling.
local function createStatsTracker()
    local existing = PlayerGui:FindFirstChild("TimePlayedGUI")
    if existing then existing:Destroy() end
    local controller = { Enabled = false, Alive = true, Rows = {} }
    function controller:Destroy()
        self.Alive = false
        self.Enabled = false
        for _, element in pairs(self.Rows) do
            local native = element.Native or element
            if native.Destroy then pcall(function() native:Destroy() end) end
        end
        table.clear(self.Rows)
    end
    if not (Tabs and Tabs.Stats) then return controller end

    local function formatTime(seconds)
        local days = math.floor(seconds / 86400)
        seconds = seconds % 86400
        local hours = math.floor(seconds / 3600)
        seconds = seconds % 3600
        local minutes = math.floor(seconds / 60)
        seconds = seconds % 60
        return string.format("%d天 %02d时 %02d分 %02d秒", days, hours, minutes, math.floor(seconds))
    end

    local function createPlayerRow(LocalPlayer)
        if controller.Rows[LocalPlayer] then return end
        local button = Tabs.Stats:AddButton({
            Title = LocalPlayer.Name .. " · 正在读取…",
            Callback = function()
                local timeValue = LocalPlayer:FindFirstChild("PlayerData")
                    and LocalPlayer.PlayerData:FindFirstChild("Stats")
                    and LocalPlayer.PlayerData.Stats:FindFirstChild("General")
                    and LocalPlayer.PlayerData.Stats.General:FindFirstChild("TimePlayed")

                local timeText = timeValue and formatTime(timeValue.Value) or "N/A"
                if setclipboard then
                    setclipboard(LocalPlayer.Name .. " - " .. timeText)
                end
            end
        })
        controller.Rows[LocalPlayer] = button
        task.spawn(function()
            local previousText
            while controller.Alive and sessionEnv.VortexionSessionId == thisSessionId do
                task.wait(1.0)
                if not controller.Alive or sessionEnv.VortexionSessionId ~= thisSessionId then return end
                if not LocalPlayer:IsDescendantOf(Players) then
                    local native = button.Native or button
                    if native.Destroy then native:Destroy() end
                    controller.Rows[LocalPlayer] = nil
                    return
                end
                if not controller.Enabled then continue end
                local stats = LocalPlayer:FindFirstChild("PlayerData") and LocalPlayer.PlayerData:FindFirstChild("Stats")
                local general = stats and stats:FindFirstChild("General")
                local killer = stats and stats:FindFirstChild("KillerStats")
                local survivor = stats and stats:FindFirstChild("SurvivorStats")
                local equipped = LocalPlayer:FindFirstChild("PlayerData") and LocalPlayer.PlayerData:FindFirstChild("Equipped")

                local timePlayed = general and general:FindFirstChild("TimePlayed")
                local killerWins = killer and killer:FindFirstChild("KillerWins")
                local killerLosses = killer and killer:FindFirstChild("KillerLosses")
                local survivorWins = survivor and survivor:FindFirstChild("SurvivorWins")
                local survivorLosses = survivor and survivor:FindFirstChild("SurvivorLosses")
                local kills = killer and killer:FindFirstChild("Kills")
                local emotes = equipped and equipped:FindFirstChild("Emotes")

                local timeText = timePlayed and formatTime(timePlayed.Value) or "N/A"
                local kw = killerWins and killerWins.Value or "N/A"
                local kl = killerLosses and killerLosses.Value or "N/A"
                local sw = survivorWins and survivorWins.Value or "N/A"
                local sl = survivorLosses and survivorLosses.Value or "N/A"
                local killCount = kills and kills.Value or "N/A"
                local emoteText = emotes and emotes.Value or "None"

                local updatedText = string.format(
                    "%s\n游戏时长：%s\n幸存者胜场：%s | 败场：%s\n杀手胜场：%s | 败场：%s | 击杀：%s\n表情：%s",
                    LocalPlayer.Name,
                    timeText,
                    sw, sl,
                    kw, kl, killCount,
                    emoteText
                )
                if previousText ~= updatedText then
                    local native = button.Native or button
                    if native.SetTitle then native:SetTitle(updatedText) end
                    previousText = updatedText
                end
            end
        end)
    end

    for _, OtherPlayer in ipairs(Players:GetPlayers()) do
        if OtherPlayer ~= Players.LocalPlayer then createPlayerRow(OtherPlayer) end
    end
    track(Players.PlayerAdded:Connect(function(OtherPlayer)
        if controller.Alive and sessionEnv.VortexionSessionId == thisSessionId and OtherPlayer ~= Players.LocalPlayer then
            createPlayerRow(OtherPlayer)
        end
    end))
    return controller
end

-- Default toggles and helpers (we will hook these to Fluent UI)
local toggles = {
    StatsTracker = false,
    ESP = false,
    infiniteStamina = false,
    AutoRejoinOnKick = true
}
local activeConnections = {}
local guiRefs = {}

-- Anim Ids
local GuestSettingsTriggerAnims = {
    "126830014841198", "126355327951215", "121086746534252", "18885909645",
    "98456918873918", "105458270463374", "83829782357897", "125403313786645",
    "118298475669935", "82113744478546", "70371667919898", "99135633258223",
    "97167027849946", "109230267448394", "139835501033932", "126896426760253",
    "109667959938617", "126681776859538", "129976080405072", "121293883585738",
    "81639435858902", "137314737492715",
    "92173139187970"
}

-- State Variables
local GuestSettingsOn = false
local strictRangeOn = false
local looseFacing = true
local detectionRange = 18

local predictiveBlockOn = false
local AutoPunchEnabled = false
local detectionRange = 10
local edgeKillerDelay = 3
local killerInRangeSince = nil
local predictiveCooldown = 0

local GuestSettingsOn = false
local flingPunchOn = false
local flingPower = 10000
local hiddenfling = false
local aimPunch = false

local customBlockEnabled = false
local customBlockAnimId = ""
local customPunchEnabled = false
local customPunchAnimId = ""

local infiniteStamina = false

local lastBlockTime = 0
local lastPunchTime = 0
local lastBlockTpTime = 0

local blockAnimIds = {
"72722244508749",
"96959123077498"
}
local punchAnimIds = {
"87259391926321"
}

local customChargeEnabled = false
local customChargeAnimId = ""
local chargeAnimIds = { "106014898528300" }

-- Goon animation
local function startGoon()
    local LocalPlayer = Players.LocalPlayer
    local animationId = "rbxassetid://72042024"
    if not guiRefs.GoonAnim then guiRefs.GoonAnim = nil end

    local function playGoonAnim()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        local animation = Instance.new("Animation")
        animation.AnimationId = animationId
        local animTrack = humanoid:LoadAnimation(animation)
        animTrack.Looped = true
        animTrack:Play()
        guiRefs.GoonAnim = animTrack
    end

    playGoonAnim()
    guiRefs.GoonConnection = LocalPlayer.CharacterAdded:Connect(function()
        if toggles.Goon then
            playGoonAnim()
        end
    end)
end

local function stopGoon()
    if guiRefs.GoonAnim then
        guiRefs.GoonAnim:Stop()
        guiRefs.GoonAnim = nil
    end
    if guiRefs.GoonConnection then
        guiRefs.GoonConnection:Disconnect()
        guiRefs.GoonConnection = nil
    end
end

-- LayDown animation
local function startLayDown()
    local LocalPlayer = Players.LocalPlayer
    local animationId = "rbxassetid://181526230"
    local skipTime = 0.2

    if not guiRefs.LayDownAnim then guiRefs.LayDownAnim = nil end

    local function playLayDownAnim()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        local animation = Instance.new("Animation")
        animation.AnimationId = animationId
        local animTrack = humanoid:LoadAnimation(animation)
        animTrack.Looped = true
        animTrack:Play()
        animTrack.TimePosition = skipTime
        guiRefs.LayDownAnim = animTrack
    end

    playLayDownAnim()
    guiRefs.LayDownConnection = LocalPlayer.CharacterAdded:Connect(function()
        if toggles.LayDown then
            playLayDownAnim()
        end
    end)
end

local function generatorDoAll()
    local LocalPlayer = game.Players.LocalPlayer
    local Workspace = game.Workspace

    local function findGenerators()
        local mapFolder = Workspace:FindFirstChild("Map")
        local ingameMap = mapFolder and mapFolder:FindFirstChild("Ingame")
        local map = ingameMap and ingameMap:FindFirstChild("Map")
        local generators = {}

        if map then
            for _, gen in ipairs(map:GetChildren()) do
                if gen.Name == "Generator" and gen:IsA("Model") and gen:FindFirstChild("Progress") and gen.Progress.Value < 100 then
                    -- Check if any LocalPlayers are within 25 studs of generator's Main part
                    local LocalPlayersNearby = false
                    for _, LocalPlayer in ipairs(game.Players:GetPlayers()) do
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp and gen:FindFirstChild("Main") then
                            local dist = (hrp.Position - gen.Main.Position).Magnitude
                            if dist < 25 then
                                LocalPlayersNearby = true
                                break
                            end
                        end
                    end

                    if not LocalPlayersNearby then
                        table.insert(generators, gen)
                    end
                end
            end
        end

        return generators
    end

    -- Save current LocalPlayer position to return later
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local lastPosition = humanoidRootPart.CFrame

    -- Main loop: keep working generators until none left
    while sessionEnv.VortexionSessionId == thisSessionId do
        local generators = findGenerators()
        if #generators == 0 then
            break
        end
        -- 长任务中角色可能重生：每轮刷新引用，失效即退出，避免对已销毁部件写 CFrame
        local currentChar = LocalPlayer.Character
        local currentHRP = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
        if not currentHRP then break end

        for _, gen in ipairs(generators) do
            if gen:FindFirstChild("Main") and gen:FindFirstChild("Remotes") and gen.Remotes:FindFirstChild("RE") and gen.Remotes:FindFirstChild("RF") and gen:FindFirstChild("Positions") and gen.Positions:FindFirstChild("Center") and gen:FindFirstChild("Instances") and gen.Instances:FindFirstChild("Generator") then
                -- Compute direction to face generator cube (if it exists)
				local generatorPosition = gen.Positions.Center.Position
				local generatorDirection

				if gen.Instances.Generator:FindFirstChild("Cube") and gen.Instances.Generator.Cube:IsA("BasePart") then
					local cubePos = gen.Instances.Generator.Cube.Position
					local cubeDelta = cubePos - generatorPosition
					generatorDirection = cubeDelta.Magnitude > 0.01 and cubeDelta.Unit or Vector3.new(0, 0, 1)
				else
					generatorDirection = Vector3.new(0, 0, 1) -- fallback direction forward
				end

				-- Teleport LocalPlayer to generator, facing the cube (or forward)
				currentHRP.CFrame = CFrame.new(
					generatorPosition + Vector3.new(0, 0.5, 0),
					generatorPosition + Vector3.new(generatorDirection.X, 0, generatorDirection.Z)
				)

                task.wait(timebetweenpuzzles / 2) -- adjust wait time as needed

                -- Fire the proximity prompt
                local prompt = gen.Main:FindFirstChildOfClass("ProximityPrompt")
                if not prompt then
                    prompt = gen.Main:FindFirstChild("Prompt")
                end
                if prompt then
                    fireproximityprompt(prompt, 1.5, false)
                else
                    warn("No prompt found on generator:", gen.Name)
                end

                -- Fire the remote server call multiple times (6 times as in your example)
                for _ = 1, 6 do
                    task.wait(2.5)
                    gen.Remotes.RE:FireServer()
                end

                task.wait(timebetweenpuzzles / 5) -- small delay before leaving

                -- Invoke the "leave" remote
                gen.Remotes.RF:InvokeServer("leave")
            end
        end
    end

    -- Return LocalPlayer to original position
    if humanoidRootPart and humanoidRootPart.Parent then humanoidRootPart.CFrame = lastPosition end
end

local function stopLayDown()
    if guiRefs.LayDownAnim then
        guiRefs.LayDownAnim:Stop()
        guiRefs.LayDownAnim = nil
    end
    if guiRefs.LayDownConnection then
        guiRefs.LayDownConnection:Disconnect()
        guiRefs.LayDownConnection = nil
    end
end

-- Frontflip implementation
local function createFrontflip()
    return function()
        local sausageHolder
        pcall(function()
            sausageHolder = game.CoreGui.TopBarApp.TopBarApp.UnibarLeftFrame.UnibarMenu["2"]
        end)

        if not sausageHolder then
            -- If TopBar isn't available, skip creating the button but still provide the flip on keypress.
        end

        local FlipCooldown
        local function FortniteFlips()
            if FlipCooldown then
                return
            end

            FlipCooldown = true
            local character = game:GetService("Players").LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
            if not hrp or not humanoid then
                FlipCooldown = false
                return
            end
            local savedTracks = {}

            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    savedTracks[#savedTracks + 1] = { track = track, time = track.TimePosition }
                    track:Stop(0)
                end
            end

            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)

            local duration = 0.45
            local steps = 120
            local startCFrame = hrp.CFrame
            local forwardVector = startCFrame.LookVector
            local upVector = Vector3.new(0, 1, 0)
            task.spawn(function()
                pcall(function()
                local startTime = tick()
                for i = 1, steps do
                    local t = i / steps
                    local height = 4 * (t - t ^ 2) * 10
                    local nextPos = startCFrame.Position + forwardVector * (35 * t) + upVector * height
                    local rotation = startCFrame.Rotation * CFrame.Angles(-math.rad(i * (360 / steps)), 0, 0)

                    hrp.CFrame = CFrame.new(nextPos) * rotation
                    local elapsedTime = tick() - startTime
                    local expectedTime = (duration / steps) * i
                    local waitTime = expectedTime - elapsedTime
                    if waitTime > 0 then
                        task.wait(waitTime)
                    end
                end

                hrp.CFrame = CFrame.new(startCFrame.Position + forwardVector * 35) * startCFrame.Rotation
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
                humanoid:ChangeState(Enum.HumanoidStateType.Running)

                if animator then
                    for _, data in ipairs(savedTracks) do
                        local track = data.track
                        track:Play()
                        track.TimePosition = data.time
                    end
                end
                task.wait(0.25)
                end)
                FlipCooldown = false
            end)
        end

        -- keybind F
        track(UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
            if gameProcessedEvent then return end
            local focused = UserInputService:GetFocusedTextBox()
            if focused then return end
            if input.KeyCode == Enum.KeyCode.P then
                FortniteFlips()
            end
        end))

        return {
            Flip = FortniteFlips,
            SausageHolder = sausageHolder
        }
    end
end

local frontflipObj = createFrontflip()()

-- Active UI references
-- FORSAKEN_WIND_BUNDLE_HEADER
-- build.py replaces these placeholders with an embedded, vendored WindUI source
-- Four feature-group module factories (Combat / Visual / Survival / Guest).
-- build.py injects them as embedded IIFE factories and removes these stubs.
local FluentLoaded = false
local success
success, Fluent = pcall(function()
    return WindBridgeFactory(WindUI)
end)
if success and Fluent then
    FluentLoaded = true
else
    warn("[Forsaken] WindUI 无法启动：" .. tostring(Fluent))
end

-- Create the native WindUI window through the compatibility bridge.
local IsMobile = UserInputService.TouchEnabled
-- Mobile sizing and scroll safety live in the WindUI bridge.
if FluentLoaded then
    Window = Fluent:CreateWindow({
        Title = "Forsaken",
        SubTitle = "",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.K
	})

	Tabs = {
		Combat = Window:AddTab({ Title = "战斗", Icon = "lucide-swords" }),
		Visual = Window:AddTab({ Title = "视觉", Icon = "lucide-eye" }),
		Survival = Window:AddTab({ Title = "生存", Icon = "lucide-heart-pulse" }),
		Guest = Window:AddTab({ Title = "Guest 1337", Icon = "lucide-leaf" }),
		System = Window:AddTab({ Title = "系统", Icon = "lucide-settings" }),
		Emotes = Window:AddTab({ Title = "杀手表情", Icon = "lucide-smile" }),
		Stats = Window:AddTab({ Title = "玩家统计", Icon = "lucide-chart-column" })
	}

    -- Put FOV controls before native theme/config groups on mobile.
    local fovValue, fovActive, fovCamera, fovListener = 80, false, nil, nil
    local savedFov = {}
    local function restoreFov()
        fovActive = false
        if fovListener then fovListener:Disconnect(); fovListener = nil end
        for camera, value in pairs(savedFov) do pcall(function() camera.FieldOfView = value end) end
        table.clear(savedFov)
        fovCamera = nil
    end
    Fluent:OnDestroy(restoreFov)
    local function applyFovValue()
        local camera = Workspace.CurrentCamera
        if not fovActive then return end
        if fovCamera ~= camera then
            if fovCamera and savedFov[fovCamera] ~= nil then
                pcall(function() fovCamera.FieldOfView = savedFov[fovCamera] end)
                savedFov[fovCamera] = nil
            end
            fovCamera = camera
        end
        if not camera then return end
        if savedFov[camera] == nil then savedFov[camera] = camera.FieldOfView end
        local effective = math.min(fovValue, 120) -- Roblox engine camera limit
        if math.abs(camera.FieldOfView - effective) > 0.01 then
            camera.FieldOfView = effective
        end
    end
    Tabs.System:AddSlider("ForsakenFOVValue", {
        Title = "视场角（80–200）", Default = 80, Min = 80, Max = 200, Rounding = 0,
        Callback = function(value)
            fovValue = math.clamp(tonumber(value) or 80, 80, 200)
            applyFovValue()
        end
    })
    Tabs.System:AddToggle("ForsakenFOVEnabled", {
        Title = "应用视场角", Default = false,
        Callback = function(enabled)
            fovActive = enabled
            if not enabled then
                restoreFov()
            else
                applyFovValue()
                if not fovListener then
                    local nextCheck = 0
                    fovListener = RunService.Heartbeat:Connect(function()
                        if sessionEnv.VortexionSessionId ~= thisSessionId then
                            restoreFov()
                            return
                        end
                        local now = os.clock()
                        if now >= nextCheck then
                            nextCheck = now + 0.2
                            applyFovValue()
                        end
                    end)
                end
            end
        end
    })
    Tabs.System:AddParagraph({
        Title = "视场角限制",
        Content = "控制当前相机。引擎实际限制为 120°；没有证据证实游戏设置值可直接改写到 200°。"
    })
    Window:InstallSettings(Tabs.System)

	Fluent:Notify({
		Title = "正在加载…",
		Content = "正在加载 Vortexion - Forsaken 功能模块…",
		Duration = 5,
		Image = "ban",
	})
end

local GuestSettingsOn = false
local strictRangeOn = false
local looseFacing = true
local detectionRange = 18

local predictiveBlockOn = false
local detectionRange = 10
local edgeKillerDelay = 3
local killerInRangeSince = nil
local predictiveCooldown = 0

local GuestSettingsOn = false
local flingPunchOn = false
local flingPower = 10000
local hiddenfling = false
local aimPunch = false

local customBlockEnabled = false
local customBlockAnimId = ""
local customPunchEnabled = false
local customPunchAnimId = ""

local infiniteStamina = false

local lastBlockTime = 0
local lastPunchTime = 0
local lastBlockTpTime = 0

local blockAnimIds = {
"72722244508749",
"96959123077498"
}
local punchAnimIds = {
"87259391926321"
}

local customChargeEnabled = false
local customChargeAnimId = ""
local chargeAnimIds = { "106014898528300" }

-- Stats updates start only when the existing game toggle is enabled.
statsGui = createStatsTracker()
statsGui.Enabled = false

-- Original Goonsaken callback bindings mapped through the native WindUI bridge
if FluentLoaded then
    Tabs.Survival:AddSlider("Walkspeed", {
        Title = "移动速度倍率",
        Default = 1,
        Min = 1,
        Max = 5,
        Rounding = 1,
        Suffix = "x",
        Callback = function(value)
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Parent:FindFirstChild("SpeedMultipliers") then
                humanoid.Parent.SpeedMultipliers.Sprinting.Value = value
            end
        end
    })

    Tabs.Survival:AddSlider("JumpPower", {
        Title = "跳跃力度",
        Default = 50,
        Min = 0,
        Max = 100,
        Rounding = 0,
        Callback = function(value)
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.JumpPower = value
            end
        end
    })

    Tabs.Survival:AddToggle("Goon", {
        Title = "Goon 动作",
        Default = false,
        Callback = function(state)
            toggles.Goon = state
            if state then
                startGoon()
            else
                stopGoon()
            end
        end
    })

    Tabs.Survival:AddToggle("LayDown", {
        Title = "趴下动作",
        Default = false,
        Callback = function(state)
            toggles.LayDown = state
            if state then
                startLayDown()
            else
                stopLayDown()
            end
        end
    })

    Tabs.Survival:AddButton({
        Title = "前空翻（P 键 / 手机快捷操作） · Fartsaken",
        Callback = function()
            if frontflipObj and frontflipObj.Flip then
                frontflipObj.Flip()
            end
        end
    })

    Tabs.Survival:AddToggle("AntiSlowness", {
        Title = "防减速",
        Default = false,
        Callback = function(state)
            AntiSlow = state
        end
    })

	Tabs.Survival:AddToggle("VoidRushControl", {
        Title = "虚空冲刺控制（感谢 golden）",
        Default = false,
        Callback = function(state)
            if state then
                startvoidrushcontrol()
            else
                stopvoidrushcontrol()
            end
        end
	})

    Tabs.Combat:AddButton({
        Title = "404 自动招架",
        Callback = function()
            local okLoad, errLoad = pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/NumanTF3/auto-404-parry/refs/heads/main/main.lua"))() end)
            if not okLoad then
                warn("[Vortexion/Forsaken] external script failed: " .. tostring(errLoad))
                if Fluent then Fluent:Notify({ Title = "外部脚本", Content = "加载失败，查看控制台", Duration = 5 }) end
            end
        end
    })

    Tabs.Combat:AddButton({
        Title = "Raging Pace 自动招架",
        Callback = function()
            local okLoad, errLoad = pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/NumanTF3/auto-raging-pace/refs/heads/main/main.lua"))() end)
            if not okLoad then
                warn("[Vortexion/Forsaken] external script failed: " .. tostring(errLoad))
                if Fluent then Fluent:Notify({ Title = "外部脚本", Content = "加载失败，查看控制台", Duration = 5 }) end
            end
        end
    })

    Tabs.Combat:AddToggle("ChanceAimbot", {
        Title = "Chance 自动瞄准",
        Default = false,
        Callback = function(state)
            if state then
                enableAimbot()
            else
                disableAimbot()
            end
        end
    })

	Tabs.Combat:AddSlider("ChanceAimbotPredictionValue", {
        Title = "Chance 预判参数",
        Default = 0.2,
        Min = 0.1,
        Max = 2,
        Rounding = 1,
        Callback = function(value)
			timeAhead = value
        end
    })

    Tabs.Combat:AddButton({
        Title = "极限闪避（自动躲避杀手）",
        Callback = function()
            local okLoad, errLoad = pcall(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/NumanTF3/forsaken-ultra-instinct/refs/heads/main/main.lua'))() end)
            if not okLoad then
                warn("[Vortexion/Forsaken] external script failed: " .. tostring(errLoad))
                if Fluent then Fluent:Notify({ Title = "外部脚本", Content = "加载失败，查看控制台", Duration = 5 }) end
            end
        end
    })

    Tabs.Combat:AddButton({
        Title = "Two Time 自动背刺与瞄准",
        Callback = function()
			if setclipboard then setclipboard("https://discord.gg/ETTV2g8kxS") end
			Fluent:Notify({
                Title = "Two Time 自动背刺",
                Content = "由 skibisaken 制作，已复制 Discord 链接。",
                Duration = 8
			})
            local okLoad, errLoad = pcall(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/NumanTF3/two-time-backstab/refs/heads/main/main.lua'))() end)
            if not okLoad then
                warn("[Vortexion/Forsaken] external script failed: " .. tostring(errLoad))
                if Fluent then Fluent:Notify({ Title = "外部脚本", Content = "加载失败，查看控制台", Duration = 5 }) end
            end
        end
    })

    Tabs.Visual:AddToggle("Invisible", {
        Title = "角色隐身",
        Default = false,
        Callback = function(state)
            if state then
                Fluent:Notify({
                    Title = "使用说明",
                    Content = "画面中央方块用于指示自身位置；其他玩家不会看到该方块。",
                    Duration = 6.5,
                    Image = "lucide-leaf",
                })
            end
            ToggleInvis(state)
        end
    })

    Tabs.Visual:AddToggle("Invis007n7", {
        Title = "007n7 克隆时完全隐身",
        Default = false,
        Callback = function(state)
            if state then
                Fluent:Notify({
                    Title = "使用说明",
                    Content = "克隆后画面中央方块仅用于显示自身位置，其他玩家不会看到。",
                    Duration = 6.5,
                    Image = "lucide-leaf",
                })
            end
            handleToggle(state)
        end
    })

    Tabs.Combat:AddToggle("HitboxModifier", {
        Title = "命中范围修改（基于 IYRE）",
        Default = false,
        Callback = function(Value)
            hitboxmodificationEnabled = Value
        end
    })

    Tabs.Combat:AddInput("HitboxDetectionDistance", {
        Title = "命中判定距离",
        Default = "120",
        Placeholder = "120",
        Numeric = true,
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                MaxRange = num
            end
        end
    })

    --------------------------------------------------------------------------
    -- Game Tab
    --------------------------------------------------------------------------
    Tabs.Visual:AddToggle("ESPToggle", {
        Title = "ESP 透视（杀手红 / 幸存者绿）",
        Description = "无墙遮挡时透明度 80%；有墙遮挡或屏幕外 0%（高亮完全显示）",
        Default = false,
        Callback = function(state)
            toggles.ESP = state
            ESP:SetEnabled(state)
        end
    })

    -- Stage 2: independently maintained category-based ESP options, inspired by
    -- c00lSaken/OPAI references, using the existing raycast renderer (no duplicate ESP loops).
    Tabs.Visual:AddToggle("EspKillers", {
        Title = "显示杀手（红色）", Default = true,
        Callback = function(v) ESP.ShowKillers = v; ESP:SetEnabled(ESP.Enabled) end
    })
    Tabs.Visual:AddToggle("EspSurvivors", {
        Title = "显示幸存者（绿色）", Default = true,
        Callback = function(v) ESP.ShowSurvivors = v; ESP:SetEnabled(ESP.Enabled) end
    })
    Tabs.Visual:AddToggle("EspIdentity", {
        Title = "用户名与使用角色", Default = true,
        Callback = function(v) ESP.ShowLabels = v; ESP:SetEnabled(ESP.Enabled) end
    })
    Tabs.Visual:AddSlider("EspVisibleTransparency", {
        Title = "无遮挡透明度", Min = 0, Max = 95, Default = 80, Rounding = 0, Suffix = "%",
        Callback = function(v) ESP.VisibleAlpha = math.clamp(v / 100, 0, 0.95) end
    })
    Tabs.Visual:AddToggle("EspHealthDistance", {
        Title = "显示生命值与距离", Default = false,
        Callback = function(v) ESP.ShowDetails = v; ESP:SetEnabled(ESP.Enabled) end
    })
    Tabs.Visual:AddSlider("EspRefreshRate", {
        Title = "遮挡检测频率", Min = 2, Max = 20, Default = 10, Rounding = 0, Suffix = "Hz",
        Callback = function(v) ESP.CheckHz = math.clamp(v, 2, 20) end
    })

    -- Vortexion: generator readout uses the current generator index and a 1Hz
    -- distance sampler. It never duplicates auto-solve or generator listeners.
    Tabs.Visual:AddToggle("GeneratorProgressESP", {
        Title = "发电机进度与距离标签", Default = false,
        Callback = function(v) ESP.GeneratorDetails = v; ESP:RefreshGeneratorLabels() end
    })
    Tabs.Visual:AddToggle("GeneratorShowCompleted", {
        Title = "标签包含已完成发电机", Default = false,
        Callback = function(v) ESP.CompletedGenerators = v; ESP:RefreshGeneratorLabels() end
    })

    -- Reimplemented from the *idea* of c00lSaken's killer tracking and
    -- OPAI's proximity options, not pasted from either reference source.
    do
        local alert = { Enabled=false, Range=35, Generation=0, LastGlobal=0, Cooldown=6, LastByCharacter=setmetatable({}, {__mode="k"}) }
        function alert:SetEnabled(state)
            state = not not state
            if self.Enabled == state then return end
            self.Enabled = state
            self.Generation += 1
            if not state then return end
            local generation = self.Generation
            task.spawn(function()
                while self.Enabled and self.Generation == generation do
                    local own = LocalPlayer.Character
                    local ownRoot = own and own:FindFirstChild("HumanoidRootPart")
                    local folders = Workspace:FindFirstChild("Players")
                    local killers = folders and folders:FindFirstChild("Killers")
                    if ownRoot and killers then
                        local nearest, minDistance = nil, self.Range
                        for _, model in ipairs(killers:GetChildren()) do
                            if model ~= own then
                                local root = model:FindFirstChild("HumanoidRootPart")
                                local humanoid = model:FindFirstChildOfClass("Humanoid")
                                if root and (not humanoid or humanoid.Health > 0) then
                                    local dist = (root.Position - ownRoot.Position).Magnitude
                                    if dist <= minDistance then nearest, minDistance = model, dist end
                                end
                            end
                        end
                        local now = os.clock()
                        if nearest and now - self.LastGlobal >= self.Cooldown
                            and now - (self.LastByCharacter[nearest] or -100) >= self.Cooldown then
                            self.LastGlobal = now
                            self.LastByCharacter[nearest] = now
                            pcall(function()
                                Fluent:Notify({Title = "杀手接近警报", Content = nearest.Name .. " · " .. tostring(math.floor(minDistance)) .. " studs", Duration = 2.5})
                            end)
                        end
                    end
                    task.wait(0.4) -- 2.5 Hz, no work while switched off
                end
            end)
        end
        Tabs.Visual:AddToggle("KillerProximityAlert", {
            Title = "杀手接近提醒（手机友好）", Default = false,
            Callback = function(v) alert:SetEnabled(v) end
        })
        Tabs.Visual:AddSlider("KillerProximityRadius", {
            Title = "提醒距离", Min = 10, Max = 100, Default = 35, Rounding = 0, Suffix = " studs",
            Callback = function(v) alert.Range = math.clamp(v,10,100) end
        })
    end

    Tabs.Survival:AddToggle("StatsTrackerToggle", {
        Title = "玩家数据统计",
        Default = false,
        Callback = function(state)
            toggles.StatsTracker = state
            if statsGui then
                statsGui.Enabled = state
                if state and Window then Window:SelectTab(7) end
            end
        end
    })

    -- v4: 角色切换/杀手回合会重新初始化 Sprinting 参数，单一标志位不够稳定。
    -- 此处只有一个后台维护任务；关闭时按开启前的实际值恢复，不把 nil 强改为 false。
    do
        local controller = {
            Enabled = false,
            Generation = 0,
            ModuleInstance = nil,
            Module = nil,
            Original = setmetatable({}, { __mode = "k" }),
            LastWarnAt = -10,
        }

        function controller:FindSprintingModule()
            local systems = game:GetService("ReplicatedStorage"):FindFirstChild("Systems")
            local characters = systems and (systems:FindFirstChild("Character") or systems:FindFirstChild("character"))
            local gameFolder = characters and (characters:FindFirstChild("Game") or characters:FindFirstChild("game"))
            return gameFolder and (gameFolder:FindFirstChild("Sprinting") or gameFolder:FindFirstChild("sprinting"))
        end

        function controller:Resolve()
            local moduleInstance = self:FindSprintingModule()
            if not moduleInstance then
                self.Module = nil
                self.ModuleInstance = nil
                return nil
            end
            if moduleInstance == self.ModuleInstance and type(self.Module) == "table" then
                return self.Module
            end
            local ok, module = pcall(require, moduleInstance)
            if not ok or type(module) ~= "table" then
                self.Module = nil
                if os.clock() - self.LastWarnAt > 8 then
                    self.LastWarnAt = os.clock()
                    warn("[Vortexion] Sprinting 模块不可用（执行器可能不支持 require）：", module)
                end
                return nil
            end
            self.ModuleInstance = moduleInstance
            self.Module = module
            return module
        end

        function controller:Apply()
            if not self.Enabled then return end
            local module = self:Resolve()
            if not module or not self.Enabled then return end
            if not self.Original[module] then
                -- value 字段以表包裹，能区分原来的 nil 与 false。
                local snapshot = {}
                for _, key in ipairs({"StaminaLossDisabled", "StaminaLoss", "StaminaGain"}) do
                    snapshot[key] = { value = module[key] }
                end
                self.Original[module] = snapshot
            end
            if module.StaminaLossDisabled ~= true then module.StaminaLossDisabled = true end
            if type(module.StaminaLoss) == "number" and module.StaminaLoss ~= 0 then
                module.StaminaLoss = 0
            end
            local maximum = module.MaxStamina
            if type(maximum) ~= "number" or maximum <= 0 then maximum = 100 end
            -- 杀手原版体力上限通常高于幸存者：不强制覆盖 MaxStamina。
            local gain = math.max(maximum * 6, 200)
            if type(module.StaminaGain) == "number" and module.StaminaGain < gain then
                module.StaminaGain = gain
            end
            if type(module.Stamina) == "number" and module.Stamina < maximum then
                module.Stamina = maximum
                local changed = module.__staminaChangedEvent
                if changed then
                    pcall(function()
                        if type(changed.Fire) == "function" then changed:Fire() end
                    end)
                end
            end
        end

        function controller:Restore()
            for module, snapshot in pairs(self.Original) do
                for key, entry in pairs(snapshot) do
                    pcall(function() module[key] = entry.value end)
                end
                self.Original[module] = nil
            end
            self.Module = nil
            self.ModuleInstance = nil
        end

        function controller:SetEnabled(state)
            state = not not state
            if self.Enabled == state then return end
            self.Enabled = state
            self.Generation += 1
            local generation = self.Generation
            if not state then
                self:Restore()
                return
            end
            -- 开关即时响应；游戏回合或角色重新加载时每 0.15s 自恢复。
            pcall(function() self:Apply() end)
            task.spawn(function()
                while self.Enabled and self.Generation == generation do
                    local ok, err = pcall(function() self:Apply() end)
                    if not ok and os.clock() - self.LastWarnAt > 8 then
                        self.LastWarnAt = os.clock()
                        warn("[Vortexion] 无限体力维护失败：", err)
                    end
                    task.wait(0.15)
                end
            end)
        end

        -- 重新出生/切换杀手或幸存者时保留开关状态并刷新模块引用。
        LocalPlayer.CharacterAdded:Connect(function()
            controller.Module = nil
            controller.ModuleInstance = nil
            if controller.Enabled then
                task.defer(function()
                    if controller.Enabled then pcall(function() controller:Apply() end) end
                end)
            end
        end)

        Tabs.Survival:AddToggle("InfiniteStamina", {
            Title = "无限体力（杀手 / 幸存者）",
            Description = "持续维护体力，回合切换后自动恢复；需要执行器支持 require",
            Default = false,
            Callback = function(value)
                controller:SetEnabled(value)
            end
        })
    end

    -- Auto Rejoin on Kick (default ON)
    Tabs.Survival:AddToggle("AutoRejoinToggle", {
        Title = "被踢出后自动重进",
        Default = true,
        Callback = function(state)
            toggles.AutoRejoinOnKick = state
            if state then
                if not activeConnections.AutoRejoin then
                    activeConnections.AutoRejoin = GuiService.ErrorMessageChanged:Connect(function(msg)
                        if msg and msg ~= "" then
                            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId) end)
                        end
                    end)
                end
            else
                if activeConnections.AutoRejoin then
                    activeConnections.AutoRejoin:Disconnect()
                    activeConnections.AutoRejoin = nil
                end
            end
        end
    })

    Tabs.Survival:AddButton({
        Title = "重新加入当前服务器",
        Callback = function()
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId) end)
        end
    })

    Tabs.Survival:AddToggle("autofixgen", {
        Title = "自动解当前发电机（需进入解谜）",
		Default = false,
        Callback = function(state)
			triggerNearestGenerator(state)
        end
    })

	Tabs.Survival:AddSlider("OneGenSpeedValue", {
        Title = "当前发电机解谜间隔",
        Default = 2.5,
        Min = 2.5,
        Max = 10,
        Rounding = 1,
        Callback = function(value)
            timeforonegen = value
        end
    })

    Tabs.Survival:AddToggle("auto1x1x1x1popups", {
        Title = "自动关闭 1x1x1x1 弹窗",
        Default = false,
        Callback = function(state)
            Do1x1PopupsLoop = state
            if state then
                task.spawn(Do1x1x1x1Popups)
            end
        end
    })

    --------------------------------------------------------------------------
    -- Misc Tab
    --------------------------------------------------------------------------
    Tabs.System:AddButton({
        Title = "加载 Infinite Yield",
        Callback = function()
            local okLoad, errLoad = pcall(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() end)
            if not okLoad then
                warn("[Vortexion/Forsaken] external script failed: " .. tostring(errLoad))
                if Fluent then Fluent:Notify({ Title = "外部脚本", Content = "加载失败，查看控制台", Duration = 5 }) end
            end
        end
    })

    Tabs.System:AddToggle("NameProtect", {
        Title = "名字保护（隐藏玩家用户名）",
        Default = false,
        Callback = function(state)
            if NameProtectActive == state then return end
            NameProtectActive = state
            if state then
                task.spawn(NameProtect)
            end
        end
    })

    Tabs.System:AddButton({
        Title = "FPS 性能优化（会降低画质）",
        Callback = function()
			local okLoad, errLoad = pcall(function() loadstring(game:HttpGet('https://raw.githubusercontent.com/NumanTF3/roblox-fpsboost-script/refs/heads/main/main.lua'))() end)
			if not okLoad then
			    warn("[Vortexion/Forsaken] external script failed: " .. tostring(errLoad))
			    if Fluent then Fluent:Notify({ Title = "外部脚本", Content = "加载失败，查看控制台", Duration = 5 }) end
			end
        end
    })

    Tabs.System:AddToggle("SettingsVideo", {
		Title = "暂停菜单播放 ONE MORE GAME 视频",
		Default = false,
		Callback = function(state)
            if state and (type(isfile) ~= "function" or type(writefile) ~= "function" or type(getcustomasset) ~= "function") then
                if Fluent then
                    Fluent:Notify({Title = "当前设备不支持", Content = "该视频功能需要执行器支持本地文件和视频资源加载。", Duration = 5})
                end
                return
            end
			if state then
				-- === Config ===
				local folderPath = "GoonsakenHub/Assets"
				local fileName = "onemoregame.webm"
				local fullPath = folderPath .. "/" .. fileName
				local videoUrl = "https://raw.githubusercontent.com/NumanTF3/Goonsaken-Hub/refs/heads/main/onemoregame.webm"

				-- Ensure folder exists
				if not isfolder("GoonsakenHub") then makefolder("GoonsakenHub") end
				if not isfolder(folderPath) then makefolder(folderPath) end

				-- Download if missing
				if not isfile(fullPath) then
					Fluent:Notify({
						Title = "视频资源",
						Content = "正在下载视频资源…",
						Duration = 5
					})

					local request = http_request or syn.request or request
					if not request then error("Executor does not support HTTP requests.") end

					local response = request({
						Url = videoUrl,
						Method = "GET"
					})

					if response and response.Success and response.Body then
						writefile(fullPath, response.Body)
						Fluent:Notify({
							Title = "视频资源",
							Content = "视频资源下载成功。",
							Duration = 5
						})
					else
						Fluent:Notify({
							Title = "视频资源",
							Content = "视频资源下载失败。",
							Duration = 5
						})
						return
					end
				else
					Fluent:Notify({
						Title = "视频资源",
						Content = "正在使用已缓存的视频。",
						Duration = 5
					})
				end

				-- Asset for VideoFrame
				local videoAsset = getcustomasset(fullPath)
				local CoreGui = game:GetService("CoreGui")
				local robloxGui = CoreGui:WaitForChild("RobloxGui", 10)
					local clippingShield = robloxGui and robloxGui:WaitForChild("SettingsClippingShield", 10)
					local SettingsShield = clippingShield and clippingShield:WaitForChild("SettingsShield", 10)

				local videoGui

				local function createVideo()
					if videoGui then return end
					videoGui = Instance.new("ScreenGui")
					videoGui.IgnoreGuiInset = true
					videoGui.ResetOnSpawn = false
					videoGui.Parent = PlayerGui

					local videoFrame = Instance.new("VideoFrame", videoGui)
					videoFrame.Name = "BackVideo"
					videoFrame.Size = UDim2.new(1, 0, 1, 0)
					videoFrame.Position = UDim2.new(0, 0, 0, 0)
					videoFrame.BackgroundTransparency = 1
					videoFrame.Video = videoAsset
					videoFrame.Looped = true
					videoFrame.Volume = 3
					videoFrame:Play()
				end

				local function removeVideo()
					if videoGui then
						videoGui:Destroy()
						videoGui = nil
					end
				end

				-- Monitor
				_G.SettingsVideoLoop = task.spawn(function() if not SettingsShield then return end
					local wasVisible = SettingsShield.Visible
					while state do
						local isVisible = SettingsShield.Visible
						if isVisible and not wasVisible then
							createVideo()
						elseif not isVisible and wasVisible then
							removeVideo()
						end
						wasVisible = isVisible
						task.wait(0.1)
					end
					removeVideo()
				end)

			else
				if _G.SettingsVideoLoop then
					task.cancel(_G.SettingsVideoLoop)
					_G.SettingsVideoLoop = nil
				end
			end
		end
	})

    Tabs.System:AddInput("PlaySoundByID", {
        Title = "按资源 ID 播放声音",
        Placeholder = "输入 Roblox 音效 ID",
        Numeric = true,
        Callback = function(input)
            local id = tonumber(input)
            if id then
                soundPlayer.SoundId = "rbxassetid://" .. id
                soundPlayer:Play()
            else
                warn("Invalid Sound ID: " .. tostring(input))
            end
        end
    })

    Tabs.System:AddDropdown("ChangeLMSSong", {
        Title = "选择 LMS 音乐",
        Values = {
            "Burnout", "Compass", "Vanity", "Close To Me", "Plead",
            "Creation Of Hatred"
        },
        Multi = false,
        Default = 1,
        Callback = function(Value)
            selectedSong = Value
            print("Selected LMS song:", selectedSong)
        end
    })

    Tabs.System:AddButton({
        Title = "替换 LMS 音乐",
        Callback = function()
            print("Waiting for Workspace.Themes.LastSurvivor to exist...")
            local theme = game.Workspace:WaitForChild("Themes", 30)
            if not theme then
                if Fluent then Fluent:Notify({Title = "LMS 音乐", Content = "未找到 Workspace.Themes，该功能仅限 LMS 模式可用。", Duration = 5}) end
                return
            end
            local lastSurvivor = theme:WaitForChild("LastSurvivor", 15)
            if not lastSurvivor then
                if Fluent then Fluent:Notify({Title = "LMS 音乐", Content = "未找到 Themes.LastSurvivor，可能尚未加载完成。", Duration = 5}) end
                return
            end
            local songId = LMSSongs[selectedSong]
            if songId then
                lastSurvivor.SoundId = songId
                lastSurvivor:Play()
                print("Changed LMS song to:", selectedSong)
            else
                warn("Invalid song name:", tostring(selectedSong))
            end
        end
    })
    --------------------------------------------------------------------------
    -- Blatant Tab
    --------------------------------------------------------------------------
    Tabs.Survival:AddButton({
        Title = "自动完成所有发电机",
        Callback = function()
            task.spawn(generatorDoAll)
        end
    })

    Tabs.Survival:AddSlider("GenSpeedValue", {
        Title = "全部发电机解谜间隔",
        Default = 3,
        Min = 3,
        Max = 10,
        Rounding = 1,
        Callback = function(value)
            timebetweenpuzzles = value
        end
    })

    --------------------------------------------------------------------------
    -- Auto Block Tab
    --------------------------------------------------------------------------
	Tabs.Guest:AddParagraph({
        Title = "致谢 Skibisaken",
        Content = "此功能组来自 skibisaken 的脚本，社区：https://discord.gg/ETTV2g8kxS"
    })

    -- One shared, detachable job instead of one permanent Stepped hook per toggle.
    local chargeConnection, chargeLastTime = nil, 0
    Tabs.Guest:AddToggle("ChargeSpeedToggle", {
        Title = "自定义冲锋速度", Default = false,
        Callback = function(enabled)
            if chargeConnection then chargeConnection:Disconnect(); chargeConnection = nil end
            if not enabled then return end
            chargeConnection = RunService.Heartbeat:Connect(function()
                if sessionEnv.VortexionSessionId ~= thisSessionId then
                    chargeConnection:Disconnect(); chargeConnection = nil
                    return
                end
                if os.clock() - chargeLastTime < 0.1 then return end
                chargeLastTime = os.clock()
                local character = LocalPlayer.Character
                local multipliers = character and character:FindFirstChild("SpeedMultipliers")
                local charge = multipliers and multipliers:FindFirstChild("Guest1337Charge")
                if charge and charge:IsA("NumberValue") and charge.Value ~= GuestChargeSpeed then
                    charge.Value = GuestChargeSpeed
                end
            end)
        end
    })

	Tabs.Guest:AddSlider("GuestChargeSpeed", {
        Title = "冲锋速度",
        Default = 2.833,
        Min = 2.833,
        Max = 15,
        Rounding = 1,
        Callback = function(Value)
            GuestChargeSpeed = Value
        end
    })

    -- Attack-sound awareness: event-driven, no frame-by-frame workspace scan.
    local guestSoundWarningEnabled = false
    local guestSoundWarningRange = 20
    local guestSoundWarnings = {}
    local guestSoundLastWarning = 0
    local guestSoundIds = {
        ["102228729296384"] = true, ["140242176732868"] = true,
        ["86174610237192"] = true, ["101199185291628"] = true,
        ["95079963655241"] = true, ["112809109188560"] = true,
        ["84307400688050"] = true, ["136323728355613"] = true
    }
    local function stopGuestSoundWarnings()
        guestSoundWarningEnabled = false
        for _, conn in ipairs(guestSoundWarnings) do
            if conn.Connected then conn:Disconnect() end
        end
        table.clear(guestSoundWarnings)
    end
    local function startGuestSoundWarnings()
        stopGuestSoundWarnings()
        guestSoundWarningEnabled = true
        local playersFolder = Workspace:FindFirstChild("Players")
        local killers = playersFolder and playersFolder:FindFirstChild("Killers")
        if not killers then
            guestSoundWarningEnabled = false
            return
        end
        local seen = {}
        local function check(sound)
            if not guestSoundWarningEnabled or sessionEnv.VortexionSessionId ~= thisSessionId then
                return
            end
            local id = tostring(sound.SoundId):match("%d+")
            if not guestSoundIds[id] or not sound:IsDescendantOf(killers) then return end
            local now = os.clock()
            if now - guestSoundLastWarning < 2 then return end
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local model = sound:FindFirstAncestorOfClass("Model")
            local targetRoot = model and model:FindFirstChild("HumanoidRootPart")
            if not targetRoot then
                local ancestor = model and model.Parent
                if ancestor and ancestor:IsA("Model") then
                    targetRoot = ancestor:FindFirstChild("HumanoidRootPart")
                end
            end
            if not (root and targetRoot) then return end
            local offset = root.Position - targetRoot.Position
            if offset:Dot(offset) > guestSoundWarningRange * guestSoundWarningRange then return end
            guestSoundLastWarning = now
            Fluent:Notify({Title = "Guest 1337 · 攻击预警",
                Content = "检测到附近杀手攻击音效", Duration = 2})
        end
        local function observe(item)
            if not item:IsA("Sound") or seen[item] then return end
            seen[item] = true
            local function bindIfKnown()
                local id = tostring(item.SoundId):match("%d+")
                if not guestSoundIds[id] then return end
                table.insert(guestSoundWarnings, item.Played:Connect(function() check(item) end))
            end
            bindIfKnown()
        end
        for _, item in ipairs(killers:GetDescendants()) do observe(item) end
        table.insert(guestSoundWarnings, killers.DescendantAdded:Connect(observe))
    end
    Tabs.Combat:AddToggle("GuestSoundWarning", {
        Title = "杀手攻击音效预警", Default = false,
        Callback = function(enabled)
            if enabled then startGuestSoundWarnings() else stopGuestSoundWarnings() end
        end
    })
    Tabs.Combat:AddSlider("GuestSoundWarningRange", {
        Title = "攻击预警距离", Default = 20, Min = 8, Max = 45, Rounding = 0,
        Suffix = "studs", Callback = function(value)
            guestSoundWarningRange = math.clamp(tonumber(value) or 20, 8, 45)
        end
    })
    Tabs.Combat:AddParagraph({Title = "音效预警说明",
        Content = "参考上传源码重新实现。仅启用时监听杀手音效，2 秒通知冷却，关闭时释放连接；音效 ID 可能随游戏更新失效。"})

    Tabs.Combat:AddToggle("GuestSettingsToggle", {
        Title = "自动格挡",
        Default = false,
        Callback = function(Value)
            GuestSettingsOn = Value
        end
    })

    Tabs.Combat:AddToggle("StrictRangeToggle", {
        Title = "严格距离判定",
        Default = false,
        Callback = function(Value)
            strictRangeOn = Value
        end
    })

    Tabs.Combat:AddDropdown("FacingCheckDropdown", {
        Title = "朝向判定",
        Values = { "Loose", "Strict" },
        Multi = false,
        Default = "Loose",
        Callback = function(Option)
            looseFacing = Option == "Loose"
        end
    })

    Tabs.Combat:AddInput("DetectionRangeInput", {
        Title = "检测距离",
        Placeholder = "18",
        Numeric = true,
        Callback = function(Text)
            detectionRange = tonumber(Text) or detectionRange
        end
    })

    Tabs.Combat:AddParagraph({
        Title = "⚠️ 注意",
        Content = "不要同时启用格挡传送与假格挡，可能引发冲突。"
    })

    Tabs.Combat:AddParagraph({
        Title = "",
        Content = "提高检测距离有助于格挡传送，建议约 30 studs。"
    })

    Tabs.Combat:AddToggle("BlockTPToggle", {
        Title = "格挡传送",
        Default = false,
        Callback = function(Value)
            blockTPEnabled = Value
        end
    })

    --------------------------------------------------------------------------
    -- Predictive Auto Block Tab
    --------------------------------------------------------------------------
    Tabs.Combat:AddToggle("PredictiveBlockToggle", {
        Title = "预测式自动格挡",
        Default = false,
        Callback = function(Value)
            predictiveBlockOn = Value
        end
    })

    Tabs.Combat:AddInput("PredictiveDetectionRange", {
        Title = "检测距离",
        Placeholder = "10",
        Numeric = true,
        Callback = function(text)
            local num = tonumber(text)
            if num then
                detectionRange = num
            end
        end
    })

    Tabs.Combat:AddSlider("EdgeKillerSlider", {
        Title = "边缘目标延迟",
        Default = 3,
        Min = 0,
        Max = 7,
        Rounding = 1,
        Callback = function(val)
            edgeKillerDelay = val
        end
    })

	Tabs.Combat:AddParagraph({
        Title = "边缘目标延迟",
        Content = "目标进入范围后延迟格挡的秒数；离开范围将重置计时。"
    })

    --------------------------------------------------------------------------
    -- Fake Block Tab
    --------------------------------------------------------------------------
    Tabs.Guest:AddButton({
        Title = "触发假格挡（WindUI）",
        Callback = function()
            local legacy = PlayerGui:FindFirstChild("FakeBlockGui")
            if legacy then legacy:Destroy() end
            local guest = sessionEnv.VortexionGuest
            if guest and guest.buildFakeBlockGui and guest.triggerFakeBlock then
                guest.buildFakeBlockGui()
                guest.triggerFakeBlock()
                if Window then Window:SelectTab(4) end
            else
                Fluent:Notify({ Title = "假格挡", Content = "Guest 功能组尚未就绪。", Duration = 3 })
            end
        end
    })

    --------------------------------------------------------------------------
    -- Auto Punch Tab
    --------------------------------------------------------------------------
    Tabs.Combat:AddToggle("AutoPunchToggle", {
        Title = "自动出拳",
        Default = false,
        Callback = function(Value)
            AutoPunchEnabled = Value
        end
    })

    Tabs.Combat:AddToggle("FlingPunchToggle", {
        Title = "击退出拳",
        Default = false,
        Callback = function(Value)
            flingPunchOn = Value
        end
    })

    Tabs.Combat:AddToggle("PunchAimbotToggle", {
        Title = "出拳自动瞄准",
        Default = false,
        Callback = function(Value)
            aimPunch = Value
        end
    })

    local predictionValue = 4
    Tabs.Combat:AddSlider("AimPredictionSlider", {
        Title = "瞄准预判距离",
        Default = predictionValue,
        Min = 0,
        Max = 10,
        Rounding = 1,
        Suffix = "studs",
        Callback = function(Value)
            predictionValue = Value
        end
    })

    Tabs.Combat:AddSlider("FlingPowerSlider", {
        Title = "击退力度",
        Default = 10000,
        Min = 5000,
        Max = 50000000000000,
        Rounding = 0,
        Callback = function(Value)
            flingPower = Value
        end
    })

    --------------------------------------------------------------------------
    -- Custom Animations Tab
    --------------------------------------------------------------------------
    Tabs.Visual:AddInput("CustomBlockAnim", {
        Title = "自定义格挡动画",
        Placeholder = "动画 ID",
        Callback = function(Text)
            customBlockAnimId = Text
        end
    })

    Tabs.Visual:AddToggle("EnableCustomBlockAnim", {
        Title = "启用自定义格挡动画",
        Default = false,
        Callback = function(Value)
            customBlockEnabled = Value
        end
    })

    Tabs.Visual:AddInput("CustomPunchAnim", {
        Title = "自定义出拳动画",
        Placeholder = "动画 ID",
        Callback = function(Text)
            customPunchAnimId = Text
        end
    })

    Tabs.Visual:AddToggle("EnableCustomPunchAnim", {
        Title = "启用自定义出拳动画",
        Default = false,
        Callback = function(Value)
            customPunchEnabled = Value
        end
    })

    Tabs.Visual:AddInput("ChargeAnimID", {
        Title = "冲锋动画 ID",
        Placeholder = "输入动画 ID",
        Callback = function(input)
            customChargeAnimId = input
        end
    })

    Tabs.Visual:AddToggle("EnableCustomChargeAnim", {
        Title = "自定义冲锋动画",
        Default = false,
        Callback = function(value)
            customChargeEnabled = value
        end
    })

	Tabs.System:AddButton({
        Title = "复制 Discord 邀请链接",
        Callback = function()
			if setclipboard then setclipboard("https://discord.gg/aXNagEYb2f") end
			Fluent:Notify({
                Title = "已复制 Discord 邀请链接",
                Content = "邀请链接已复制到剪贴板。",
                Duration = 8
			})
        end
    })
else
	-- Fluent not loaded fallback: wire minimal keybinds and defaults
    warn("WindUI not loaded; GUI controls unavailable; gameplay hooks retained.")
end

-- Native WindUI manages content scrolling and mobile layout.


-- Ensure AutoRejoin default ON (original script created a connection by default)
if not activeConnections.AutoRejoin and toggles.AutoRejoinOnKick then
    activeConnections.AutoRejoin = GuiService.ErrorMessageChanged:Connect(function(msg)
        if msg and msg ~= "" then
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId) end)
        end
    end)
end

-- Initially disable ESP visuals (kept behavior)
ESP:SetEnabled(false)

local AttackAnimations = {
	"rbxassetid://131430497821198", "rbxassetid://83829782357897", "rbxassetid://126830014841198",
	"rbxassetid://126355327951215", "rbxassetid://121086746534252", "rbxassetid://105458270463374",
	"rbxassetid://127172483138092", "rbxassetid://18885919947", "rbxassetid://18885909645",
	"rbxassetid://87259391926321", "rbxassetid://106014898528300", "rbxassetid://86545133269813",
	"rbxassetid://89448354637442", "rbxassetid://90499469533503", "rbxassetid://116618003477002",
	"rbxassetid://106086955212611", "rbxassetid://107640065977686", "rbxassetid://77124578197357",
	"rbxassetid://101771617803133", "rbxassetid://134958187822107", "rbxassetid://111313169447787",
	"rbxassetid://71685573690338", "rbxassetid://129843313690921", "rbxassetid://97623143664485",
	"rbxassetid://136007065400978", "rbxassetid://86096387000557", "rbxassetid://108807732150251",
	"rbxassetid://138040001965654", "rbxassetid://73502073176819", "rbxassetid://86709774283672",
	"rbxassetid://140703210927645", "rbxassetid://96173857867228", "rbxassetid://121255898612475",
	"rbxassetid://98031287364865", "rbxassetid://119462383658044", "rbxassetid://77448521277146",
	"rbxassetid://103741352379819", "rbxassetid://131696603025265", "rbxassetid://122503338277352",
	"rbxassetid://97648548303678", "rbxassetid://94162446513587", "rbxassetid://84426150435898",
	"rbxassetid://93069721274110", "rbxassetid://114620047310688", "rbxassetid://97433060861952",
	"rbxassetid://82183356141401", "rbxassetid://100592913030351", "rbxassetid://121293883585738",
	"rbxassetid://70447634862911", "rbxassetid://92173139187970", "rbxassetid://106847695270773",
	"rbxassetid://125403313786645", "rbxassetid://81639435858902", "rbxassetid://137314737492715",
	"rbxassetid://120112897026015", "rbxassetid://82113744478546", "rbxassetid://118298475669935",
	"rbxassetid://126681776859538", "rbxassetid://129976080405072", "rbxassetid://109667959938617",
	"rbxassetid://74707328554358", "rbxassetid://133336594357903", "rbxassetid://86204001129974",
	"rbxassetid://124243639579224", "rbxassetid://70371667919898", "rbxassetid://131543461321709",
	"rbxassetid://136323728355613", "rbxassetid://109230267448394"
}

-- Helpers
local function fireRemoteBlock()
	local args = {"UseActorAbility", "Block"}
	local modules = ReplicatedStorage:WaitForChild("Modules", 10); local network = modules and modules:WaitForChild("Network", 10); local remote = network and network:WaitForChild("RemoteEvent", 10); if remote then remote:FireServer(unpack(args)) else warn("[Vortexion] Block remote unavailable") end
end

local function isFacing(localRoot, targetRoot)
    if not facingCheckEnabled then
        return true
    end
    if not localRoot or not targetRoot then
        return false
    end

    local offset = localRoot.Position - targetRoot.Position
    if offset.Magnitude == 0 then
        return false -- same position, can't determine facing
    end

    local dir = offset.Unit
    local dot = targetRoot.CFrame.LookVector:Dot(dir)

    if looseFacing then
        return dot > -0.3
    else
        return dot > 0
    end
end

local function playCustomAnim(animId, isPunch)
    if not Humanoid then
        warn("Humanoid missing")
        return
    end

    if not animId or animId == "" then
        warn("No animation ID provided")
        return
    end

    local now = tick()
    local lastTime = isPunch and lastPunchTime or lastBlockTime
    if now - lastTime < 1 then
        return
    end

    -- Stop other known anims
    for _, track in ipairs(Humanoid:GetPlayingAnimationTracks()) do
        local animNum = tostring(track.Animation.AnimationId):match("%d+")
        if table.find(isPunch and punchAnimIds or blockAnimIds, animNum) then
            track:Stop()
        end
    end

    -- Create and load the animation
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. animId

    local success, track = pcall(function()
        return Humanoid:LoadAnimation(anim)
    end)

    if success and track then
        print("Playing custom " .. (isPunch and "punch" or "block") .. " animation:", animId)
        track:Play()
        if isPunch then
            lastPunchTime = now
        else
            lastBlockTime = now
        end
    else
        warn("Failed to load or play custom animation: " .. animId)
    end
end

-- Removed a dead 10 Hz character lookup; it only created function-local shadows.

coroutine.wrap(function()
    local hrp, c, vel, movel = nil, nil, nil, 0.1
    while sessionEnv.VortexionSessionId == thisSessionId do
        task.wait(hiddenfling and 0.016 or 0.25)
        if hiddenfling then
            while hiddenfling and not (c and c.Parent and hrp and hrp.Parent) do
                RunService.Heartbeat:Wait()
                c = LocalPlayer.Character
                hrp = c and c:FindFirstChild("HumanoidRootPart")
            end
            if hiddenfling then
                vel = hrp.Velocity
                hrp.Velocity = vel * flingPower + Vector3.new(0, flingPower, 0)
                RunService.RenderStepped:Wait()
                hrp.Velocity = vel
                RunService.Stepped:Wait()
                hrp.Velocity = vel + Vector3.new(0, movel, 0)
                movel = movel * -1
            end
        end
    end
end)()

do
-- v3: Combat feature checks run on a bounded budget; disabled features do not scan players.
local lastCombatScan = 0
track(RunService.Heartbeat:Connect(function()
    if not (GuestSettingsOn or blockTPEnabled or predictiveBlockOn or AutoPunchEnabled) then return end
    local now = os.clock()
    if now - lastCombatScan < 0.06 then return end
    lastCombatScan = now
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    Humanoid = myChar:FindFirstChildOfClass("Humanoid")
        -- Auto Block: Trigger block if a valid animation is played by a killer
    if GuestSettingsOn then for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            -- A player character is already sourced from Players:GetPlayers().
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local animTracks = hum and hum:FindFirstChildOfClass("Animator") and hum:FindFirstChildOfClass("Animator"):GetPlayingAnimationTracks()

            if hrp and myRoot and (hrp.Position - myRoot.Position).Magnitude <= detectionRange then
                for _, track in ipairs(animTracks or {}) do
                    local id = tostring(track.Animation.AnimationId):match("%d+")
                    if table.find(GuestSettingsTriggerAnims, id) then
                        if GuestSettingsOn and (not strictRangeOn or (hrp.Position - myRoot.Position).Magnitude <= detectionRange) then
                            if isFacing(myRoot, hrp) then
                                fireRemoteBlock()
                                if customBlockEnabled and customBlockAnimId ~= "" then
                                    playCustomAnim(customBlockAnimId, false)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    end -- GuestSettingsOn

    -- Detect if LocalPlayer is playing a block animation, and blockTP is enabled
    if blockTPEnabled and Humanoid and tick() - lastBlockTpTime >= 5 then
        for _, track in ipairs(Humanoid:GetPlayingAnimationTracks()) do
            local animId = tostring(track.Animation.AnimationId):match("%d+")
            if animId == "72722244508749" or animId == "96959123077498" then
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    local killers = {"c00lkidd", "Jason", "JohnDoe", "1x1x1x1", "Noli"}
                    for _, name in ipairs(killers) do
                        local killer = workspace:FindFirstChild("Players")
                            and workspace.Players:FindFirstChild("Killers")
                            and workspace.Players.Killers:FindFirstChild(name)


                        if killer and killer:FindFirstChild("HumanoidRootPart") then
                            lastBlockTpTime = tick()

                            task.spawn(function()
                                local startTime = tick()
                                while tick() - startTime < 0.5 do
                                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                        local myRoot = LocalPlayer.Character.HumanoidRootPart
                                        local targetHRP = killer.Parent and killer:FindFirstChild("HumanoidRootPart")
                                        local direction = targetHRP and targetHRP.CFrame.LookVector
                                        local tpPosition = targetHRP and (targetHRP.Position + direction * 6)
                                        if tpPosition then myRoot.CFrame = CFrame.new(tpPosition) end
                                    end
                                    task.wait()
                                end
                            end)

                            break
                        end
                    end
                end
                break
            end
        end
    end

    -- Predictive Auto Block: Check killer range and time
    if predictiveBlockOn and tick() > predictiveCooldown then
        local killersFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local myHum = myChar and myChar:FindFirstChild("Humanoid")

        if killersFolder and myHRP and myHum then
            local killerInRange = false

            for _, killer in ipairs(killersFolder:GetChildren()) do
	            if not game.Players:GetPlayerFromCharacter(killer) then
                    continue
                end
                local hrp = killer:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (myHRP.Position - hrp.Position).Magnitude
                    if dist <= detectionRange then
                        killerInRange = true
                        break
                    end
                end
            end

            -- Handle killer entering range
            if killerInRange then
                if not killerInRangeSince then
                    killerInRangeSince = tick()  -- Start the timer when the killer enters the range
                elseif tick() - killerInRangeSince >= edgeKillerDelay then
                    -- Block if the killer has stayed in range long enough
                    fireRemoteBlock()
                    predictiveCooldown = tick() + 2  -- Set cooldown to avoid blocking too quickly again
                    killerInRangeSince = nil  -- Reset the timer
                end
            else
                killerInRangeSince = nil  -- Reset timer if the killer leaves range
            end
        end
    end



    -- Auto Punch
    if AutoPunchEnabled then
        local gui = PlayerGui:FindFirstChild("MainUI")
        local punchBtn = gui and gui:FindFirstChild("AbilityContainer") and gui.AbilityContainer:FindFirstChild("Punch")
        local charges = punchBtn and punchBtn:FindFirstChild("Charges")

        if charges and charges.Text == "1" then
            local killerNames = {"c00lkidd", "Jason", "JohnDoe", "1x1x1x1", "Noli"}
            for _, name in ipairs(killerNames) do
                local killer = workspace:FindFirstChild("Players")
                    and workspace.Players:FindFirstChild("Killers")
                    and workspace.Players.Killers:FindFirstChild(name)


                if killer and killer:FindFirstChild("HumanoidRootPart") then
                    local root = killer.HumanoidRootPart
                    local myChar = LocalPlayer.Character
                    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    if root and myRoot and (root.Position - myRoot.Position).Magnitude <= 10 then

                        -- Aim Punch: Constant look at killer with prediction
						if aimPunch then
							local humanoid = myChar:FindFirstChild("Humanoid")
							if humanoid then
								humanoid.AutoRotate = false
							end

							task.spawn(function()
								local start = tick()
								while tick() - start < 2 do
									local myRootNow = myChar:FindFirstChild("HumanoidRootPart")
									local targetRoot = root
										and root.Parent
										and root.Parent:FindFirstChild("HumanoidRootPart")

									if myRootNow and targetRoot then
										local predictedPos = targetRoot.Position + (targetRoot.CFrame.LookVector * predictionValue)
										local lookDir = predictedPos - myRootNow.Position
										if lookDir.Magnitude > 0.01 then
											myRootNow.CFrame = CFrame.lookAt(
												myRootNow.Position,
												predictedPos
											)
										end
									end
									task.wait()
								end

								if humanoid and humanoid.Parent then
									humanoid.AutoRotate = true
								end
							end)
						end

                        -- Trigger punch GUI button
                        for _, conn in ipairs(getconnections and getconnections(punchBtn.MouseButton1Click) or {}) do
                            pcall(function()
                                conn:Fire()
                            end)
                        end

                        -- Fling Punch: Constant TP 2 studs in front of killer for 1 second
                        if flingPunchOn then
                            hiddenfling = true
                            local targetHRP = root
                            task.spawn(function()
                                local start = tick()
                                while tick() - start < 1 do
                                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and targetHRP and targetHRP.Parent then
                                        local frontPos = targetHRP.Position + (targetHRP.CFrame.LookVector * 2)
                                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(frontPos, targetHRP.Position)
                                    end
                                    task.wait()
                                end
                                hiddenfling = false
                            end)
                        end

                        -- Play custom punch animation if enabled
                        if customPunchEnabled and customPunchAnimId ~= "" then
                            playCustomAnim(customPunchAnimId, true)
                        end

                        break -- Only punch one killer per frame
                    end
                end
            end
        end
    end

end))

end -- scoped performance/UI helpers

-- Cooldown tracking for each replacement type
local lastReplaceTime = {
    block = 0,
    punch = 0,
    charge = 0,
}

-- Continuous custom animation replacer (runs forever if toggled on)
task.spawn(function()
    while sessionEnv.VortexionSessionId == thisSessionId do
        local enabled = customBlockEnabled or customPunchEnabled or customChargeEnabled
        task.wait(enabled and 0.08 or 0.4)
        if not (customBlockEnabled or customPunchEnabled or customChargeEnabled) then continue end

        local char = LocalPlayer.Character
        if not char then continue end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
        if not animator then continue end

        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            local animId = tostring(track.Animation.AnimationId):match("%d+")

            -- Block animation replacement
            if customBlockEnabled and customBlockAnimId ~= "" and table.find(blockAnimIds, animId) then
                if tick() - lastReplaceTime.block >= 3 then
                    lastReplaceTime.block = tick()
                    track:Stop()
                    local newAnim = Instance.new("Animation")
                    newAnim.AnimationId = "rbxassetid://" .. customBlockAnimId
                    local newTrack = animator:LoadAnimation(newAnim)
                    if newTrack then newTrack:Play() end
                    break
                end
            end

            -- Punch animation replacement
            if customPunchEnabled and customPunchAnimId ~= "" and table.find(punchAnimIds, animId) then
                if tick() - lastReplaceTime.punch >= 3 then
                    lastReplaceTime.punch = tick()
                    track:Stop()
                    local newAnim = Instance.new("Animation")
                    newAnim.AnimationId = "rbxassetid://" .. customPunchAnimId
                    local newTrack = animator:LoadAnimation(newAnim)
                    if newTrack then newTrack:Play() end
                    break
                end
            end

            -- Charge animation replacement
            if customChargeEnabled and customChargeAnimId ~= "" and table.find(chargeAnimIds, animId) then
                if tick() - lastReplaceTime.charge >= 3 then
                    lastReplaceTime.charge = tick()
                    track:Stop()
                    local newAnim = Instance.new("Animation")
                    newAnim.AnimationId = "rbxassetid://" .. customChargeAnimId
                    local newTrack = animator:LoadAnimation(newAnim)
                    if newTrack then newTrack:Play() end
                    break
                end
            end
        end
    end
end)

do
--// Hitbox ride logic: check at 20Hz when enabled, instead of each frame.
local lastHitboxScan = 0
local lastCandidateScan = 0
local candidateCache, cachedPlayers, cachedNpcs = {}, nil, nil
track(RunService.Heartbeat:Connect(function()
    if not hitboxmodificationEnabled then return end
    local now = os.clock()
    if now - lastHitboxScan < 0.05 then return end
    lastHitboxScan = now
	if not HumanoidRootPart or not Humanoid then return end

	local playing = false
	for _, track in ipairs(Humanoid:GetPlayingAnimationTracks()) do
		if table.find(AttackAnimations, track.Animation.AnimationId)
			and (track.TimePosition / track.Length < 0.75) then
			playing = true
			break
		end
	end

	if not playing then return end

	local Target
	local NearestDist = MaxRange

	local function scanGroup(group)
		for _, obj in ipairs(group) do
			if obj == Character or not obj.Parent or not obj:FindFirstChild("HumanoidRootPart") then continue end
			local dist = (obj.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
			if dist < NearestDist then
				NearestDist = dist
				Target = obj
			end
		end
	end

    -- Snapshot a scene candidate list at most twice per second. This avoids
    -- walking every descendant 20 times/second while the option is enabled.
    local playersFolder = workspace:FindFirstChild("Players")
    local map = workspace:FindFirstChild("Map")
    local npcs = map and map:FindFirstChild("NPCs", true)
    if now - lastCandidateScan >= 0.5 or playersFolder ~= cachedPlayers or npcs ~= cachedNpcs then
        candidateCache = {}
        cachedPlayers, cachedNpcs = playersFolder, npcs
        lastCandidateScan = now
        if playersFolder then
            for _, object in ipairs(playersFolder:GetDescendants()) do
                if object:FindFirstChild("HumanoidRootPart") then table.insert(candidateCache, object) end
            end
        end
        if npcs then
            for _, object in ipairs(npcs:GetChildren()) do
                if object:FindFirstChild("HumanoidRootPart") then table.insert(candidateCache, object) end
            end
        end
    end
    scanGroup(candidateCache)

	if not Target then return end

	local ping = LocalPlayer:GetNetworkPing()
	local randomOffset = Vector3.new(RNG:NextNumber(-1.5, 1.5), 0, RNG:NextNumber(-1.5, 1.5))
	local predicted = Target.HumanoidRootPart.Position + randomOffset + (Target.HumanoidRootPart.Velocity * (ping * 1.25))
	local divisor = math.max(ping * 2, 0.05)
	local neededVelocity = (predicted - HumanoidRootPart.Position) / divisor

	local oldVelocity = HumanoidRootPart.Velocity
	HumanoidRootPart.Velocity = neededVelocity
	RunService.RenderStepped:Wait()
    if HumanoidRootPart and HumanoidRootPart.Parent and sessionEnv.VortexionSessionId == thisSessionId then
        HumanoidRootPart.Velocity = oldVelocity
    end
end))

end -- scoped performance/UI helpers

runEvery(0.14, function()
    if not AntiSlow then return end
    checkAndSetSlowStatus()
    enforceMultipliers()
end)

-- Select the first tab on load
if Window then Window:SelectTab(1) end

-- Notify when loaded
if FluentLoaded then
Fluent:Notify({
    Title = "Forsaken",
    Content = "Vortexion - Forsaken 已加载。",
    Duration = 5
})
end

if FluentLoaded then
Fluent:Notify({
    Title = "手机端提示",
    Content = "使用 WindUI 原生触控入口展开菜单；主题与配置在统一 UI 分组管理。",
    Duration = 7
})
end

local hubLoaded = true

-- Native WindUI OpenButton owns the mobile launcher.
for _, previousName in ipairs({"GoonsakenMobileOverlay", "VortexionForsakenOverlay"}) do
    local previous = PlayerGui:FindFirstChild(previousName)
    if previous then previous:Destroy() end
end

local function SetOptionToggle(id)
    if not Fluent or not Fluent.Options then return end
    local option = Fluent.Options[id]
    if option and option.SetValue then option:SetValue(not option.Value) end
end

if FluentLoaded and Tabs then
    Tabs.Survival:AddButton({
        Title = "前空翻",
        Callback = function() if frontflipObj and frontflipObj.Flip then frontflipObj.Flip() end end
    })
    Tabs.Visual:AddButton({ Title = "ESP 快捷开关", Callback = function() SetOptionToggle("ESPToggle") end })
    Tabs.Survival:AddButton({ Title = "自动解谜快捷开关", Callback = function() SetOptionToggle("autofixgen") end })
    Tabs.Visual:AddButton({ Title = "杀手表情", Callback = KillerEmoteGUI })
    Tabs.Emotes:AddButton({ Title = "刷新装备表情", Callback = KillerEmoteGUI })
    -- Populate without changing the initial game page.
    KillerEmoteGUI()
    Window:SelectTab(1)
end

-- Avoid writes on every Heartbeat; chat config is optional in some clients.
if chatWindow then
    pcall(function() chatWindow.Enabled = true end)
end

---------------------------------------------------------------------------
-- 四个功能组模块装配 (Combat / Visual / Survival / Guest)
-- 借鉴 Forsaken-Script-main / Forsaken-Scripts-main 审计结论的增强实现，
-- 每个组自包含（pcall 隔离），单组失败不影响其余组与主界面。
---------------------------------------------------------------------------
local featureGroupApis = {}
if FluentLoaded and Tabs then
    local groupCtx = {
        Players = Players,
        LocalPlayer = LocalPlayer,
        RunService = RunService,
        Workspace = Workspace,
        UserInputService = UserInputService,
        TextChatService = TextChatService,
        Tabs = Tabs,
        Fluent = Fluent,
        track = track,
        Connections = Connections,
        disconnectAll = disconnectAll,
        runEvery = runEvery,
        sessionEnv = sessionEnv,
        thisSessionId = thisSessionId,
        IsMobile = IsMobile,
    }
    local FEATURE_GROUPS = {
        { key = "VortexionCombat",   name = "战斗组",   factory = ForsakenCombatFactory },
        { key = "VortexionVisual",   name = "视觉组",   factory = ForsakenVisualFactory },
        { key = "VortexionSurvival", name = "生存组",   factory = ForsakenSurvivalFactory },
        { key = "VortexionGuest",    name = "Guest 组", factory = ForsakenGuestFactory },
    }
    for _, group in ipairs(FEATURE_GROUPS) do
        if type(group.factory) == "function" then
            local ok, api = pcall(group.factory, groupCtx)
            if ok and type(api) == "table" then
                sessionEnv[group.key] = api
                featureGroupApis[group.key] = api
            else
                warn("[Forsaken] 功能组加载失败 " .. group.name .. ": " .. tostring(api))
            end
        end
    end
end


local cleaned = false
local function cleanupForsaken()
        if cleaned then return end
        cleaned = true
        for key, api in pairs(featureGroupApis) do
            if type(api.Destroy) == "function" then pcall(api.Destroy) end
            if sessionEnv[key] == api then sessionEnv[key] = nil end
        end
        if sessionEnv.VortexionSessionId == thisSessionId then
            sessionEnv.VortexionSessionId = thisSessionId + 1
        end
        -- Reset enabled callbacks before removing their event connections.
        for _, option in pairs(Fluent and Fluent.Options or {}) do
            if option.Value == true and option.SetValue then
                pcall(function() option:SetValue(false) end)
            end
        end
        for _, conn in pairs(activeConnections) do
            if conn and conn.Disconnect then pcall(function() conn:Disconnect() end) end
        end
        disconnectAll()
        if statsGui then pcall(function() statsGui:Destroy() end) end
        pcall(stopvoidrushcontrol)
        pcall(disableAimbot)
        pcall(function() ESP:SetEnabled(false) end)
end
sessionEnv.VortexionForsakenCleanup = cleanupForsaken
if FluentLoaded and Fluent.OnDestroy then
    Fluent:OnDestroy(function() cleanupForsaken() end)
end


end
return GameRouter.Run(WindUI, WindBridgeFactory, entry, game.GameId, game.PlaceId, "Forsaken")
end
