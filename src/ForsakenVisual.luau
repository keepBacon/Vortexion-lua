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