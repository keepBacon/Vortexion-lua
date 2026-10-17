-- Vortexion SCP common runtime: capability probe, debug channel, guards.
-- Every SCP module receives this singleton as `common` and never globals state.
return function(common)
	common = common or {}
	common.Version = "3.0.0"
	common.Name = "SCP"

	--=========================================================================
	-- Executor capability probe. Each feature degrades instead of hard-failing.
	--=========================================================================
	local Caps = {}
	local function detect(name, test)
		local ok, result = pcall(test)
		Caps[name] = ok and result and true or false
	end
	detect("Drawing", function() return type(Drawing) == "table" and type(Drawing.new) == "function" end)
	detect("DrawingUserdata", function() return type(Drawing) == "userdata" end)
	detect("hookfunction", function() return type(hookfunction) == "function" end)
	detect("replaceclosure", function() return type(replaceclosure) == "function" end)
	detect("hookmetamethod", function() return type(hookmetamethod) == "function" end)
	detect("getrawmetatable", function() return type(getrawmetatable) == "function" end)
	detect("newcclosure", function() return type(newcclosure) == "function" end)
	detect("checkcaller", function() return type(checkcaller) == "function" end)
	detect("mousemoverel", function() return type(mousemoverel) == "function" end)
	detect("gethui", function() return type(gethui) == "function" end)
	detect("getgenv", function() return type(getgenv) == "function" end)
	detect("setclipboard", function() return type(setclipboard) == "function" end)
	common.Caps = Caps
	-- ESP gate: Drawing API present in either userdata or table form.
	common.HasDrawing = (Caps.Drawing or Caps.DrawingUserdata) and true or false

	--=========================================================================
	-- Debug channel: one prefix per module, gated by the Settings/Debug toggle.
	--=========================================================================
	common.Debug = false
	function common.Log(module, ...)
		if not common.Debug then return end
		print(("[Vortexion/SCP/%s]"):format(module), ...)
	end

	--=========================================================================
	-- Guarded execution with 5s warn throttle: one broken subsystem must never
	-- spam the console or stall the shared render loop.
	--=========================================================================
	local lastWarn = {}
	function common.Guard(module, fn, ...)
		local ok, err = pcall(fn, ...)
		if not ok then
			local now = tick()
			if not lastWarn[module] or now - lastWarn[module] > 5 then
				lastWarn[module] = now
				warn(("[Vortexion/SCP/%s] %s"):format(module, tostring(err)))
			end
		end
		return ok
	end

	--=========================================================================
	-- Visual cadence: consume the shared bridge interval clamp when present.
	-- The bridge returns max(baseSeconds, 1/VisualHz); a missing method, a
	-- non-function field or a failing call keeps the original beat untouched.
	--=========================================================================
	function common.VisualInterval(baseSeconds)
		local base = tonumber(baseSeconds) or 0
		if base <= 0 or base ~= base then return baseSeconds end
		local bridge = common.UI
		if type(bridge) == "table" and type(bridge.GetVisualInterval) == "function" then
			local ok, value = pcall(bridge.GetVisualInterval, bridge, base)
			-- the shared clamp may only slow visuals down, never speed them up:
			-- reject NaN / +-inf / non-positive and never return below base.
			if ok and type(value) == "number" and value == value
				and value < math.huge and value > -math.huge and value > 0 then
				return math.max(base, value)
			end
		end
		return base
	end

	--=========================================================================
	-- RandomName: short identifiers for module-owned GUI instances.
	--=========================================================================
	local NAME_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	function common.RandomName(len)
		len = len or 14
		local out = table.create(len)
		for i = 1, len do
			local ci = math.random(1, #NAME_CHARS)
			out[i] = NAME_CHARS:sub(ci, ci)
		end
		return table.concat(out)
	end

	--=========================================================================
	-- getGuiParent: capability-based GUI parent with PlayerGui fallback.
	--=========================================================================
	function common.GetGuiParent()
		if Caps.gethui then
			local ok, hui = pcall(gethui)
			if ok and hui then return hui end
		end
		local coreGui = game:FindService("CoreGui")
		if coreGui then return coreGui end
		local lp = game:GetService("Players").LocalPlayer
		return lp and lp:FindFirstChild("PlayerGui")
	end

	--=========================================================================
	-- Cleanup registry: modules push disposers; Core:Stop() runs them all so a
	-- reload/respawn never leaks connections, drawings or patched closures.
	--=========================================================================
	common.Disposers = common.Disposers or {}
	if not common.OnCleanup then
		function common.OnCleanup(fn)
			table.insert(common.Disposers, fn)
		end
	end

	--=========================================================================
	-- Touch layer: mobile trigger + fly drag. Single finger held = trigger;
	-- single finger drag = horizontal fly; two fingers = vertical fly.
	--=========================================================================
	common.Touch = { Enabled = false, Held = false, Presses = 0, Region = "Right" }
	do
		local UIS = common.Services and (common.Services.UserInputService or common.Services.Input)
		if not UIS then
			local ok, svc = pcall(function() return game:GetService("UserInputService") end)
			if ok then UIS = svc end
		end
		if UIS and UIS.TouchEnabled then
			common.Touch.Enabled = true
			local touchPoints = {}
			local touchConns = {}
			local sequence = 0
			table.insert(touchConns, UIS.TouchStarted:Connect(function(input, processed)
				if processed then return end
				local cam = (common.Services.Workspace or workspace).CurrentCamera
				if common.Touch.Region == "Right" and cam and input.Position.X < cam.ViewportSize.X * 0.5 then return end
				sequence += 1
				touchPoints[input] = { Origin = input.Position, Position = input.Position, Order = sequence }
				if not common.Touch.Held then common.Touch.Presses += 1 end
				common.Touch.Held = true
			end))
			table.insert(touchConns, UIS.TouchMoved:Connect(function(input)
				if touchPoints[input] then touchPoints[input].Position = input.Position end
			end))
			table.insert(touchConns, UIS.TouchEnded:Connect(function(input)
				touchPoints[input] = nil
				common.Touch.Held = next(touchPoints) ~= nil
			end))
			local function resetTouch()
				table.clear(touchPoints)
				common.Touch.Held = false
				common.Touch.FocusEpoch = (common.Touch.FocusEpoch or 0) + 1
			end
			if UIS.WindowFocusReleased then
				table.insert(touchConns, UIS.WindowFocusReleased:Connect(resetTouch))
			end
			function common.Touch:Drag()
				local first, second
				for _, point in pairs(touchPoints) do
					if not first or point.Order < first.Order then
						second, first = first, point
					elseif not second or point.Order < second.Order then second = point end
				end
				if not first then return Vector2.zero, 0 end
				local d = first.Position - first.Origin
				local vertical = second and second.Position.Y - second.Origin.Y or 0
				return Vector2.new(d.X, d.Y), vertical
			end
			common.OnCleanup(function()
				for _, cn in ipairs(touchConns) do pcall(function() cn:Disconnect() end) end
				touchPoints = {}
				common.Touch.Held = false
			end)
		end
	end

	--=========================================================================
	-- Safe service cache (executor-agnostic direct GetService).
	--=========================================================================
	common.Services = common.Services or {
		Players = game:GetService("Players"),
		RunService = game:GetService("RunService"),
		UserInputService = game:GetService("UserInputService"),
		HttpService = game:GetService("HttpService"),
		Lighting = game:GetService("Lighting"),
		TeleportService = game:GetService("TeleportService"),
		VirtualUser = game:GetService("VirtualUser"),
		TweenService = game:GetService("TweenService"),
		Workspace = workspace,
	}
	common.Services.UserInputService = common.Services.UserInputService or common.Services.Input
	common.Services.Input = common.Services.Input or common.Services.UserInputService
	common.LocalPlayer = common.LocalPlayer or common.Services.Players.LocalPlayer

	return common
end
