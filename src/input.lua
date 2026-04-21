local UserInputService = game:GetService("UserInputService")

local Input = {}

local ACTION_THRESHOLD = 1.0
local ACTION_COOLDOWN = 0.25
local MOUNT_PRESSURE_TRIGGER = 1.0
local MOUNT_PRESSURE_REFIRE_COOLDOWN = 0.22
local MOUSE_LOCATION_THRESHOLD = 2

local function isSideMouse(bucket)
	return bucket == "Left" or bucket == "Right"
end

local function isUpOrSideMouse(bucket)
	return bucket == "Up" or bucket == "Left" or bucket == "Right"
end

local function isMediumOrHeavy(aggressionTier)
	return aggressionTier == "Medium" or aggressionTier == "Heavy"
end

function Input.mapInterpretationToLegacyAction(outcomeBias)
	if outcomeBias == "Posture breaking / control improvement bias." then return "Triangle Attempt" end
	if outcomeBias == "Triangle development bias." then return "Triangle Attempt" end
	if outcomeBias == "Hip bump / angle sweep bias." then return "Hip Bump Sweep" end
	if outcomeBias == "Mount bridge escape bias." then return "Upa Escape" end
	if outcomeBias == "Mount shrimp escape bias." then return "Elbow Escape" end
	if outcomeBias == "Mount survival framing bias." then return "Elbow Escape" end
	if outcomeBias == "Heavy top mount control bias." then return "Maintain Mount" end
	if outcomeBias == "Top mount attack bias." then return "Submission Attempt" end
	return "Wait"
end

local function updateAggressionTier(gameState)
	local isLeftDown = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
	local isRightDown = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	local buttonsDown = (isLeftDown and 1 or 0) + (isRightDown and 1 or 0)
	if buttonsDown == 0 then gameState.aggressionTier = "None"
	elseif buttonsDown == 1 then gameState.aggressionTier = "Medium"
	else gameState.aggressionTier = "Heavy" end
end

local function interpretOutcomeBias(gameState, getChannelStateName)
	local positionName = gameState.position
	local playerRole = gameState.playerRole
	local qState = getChannelStateName("Q", positionName, playerRole)
	local aState = getChannelStateName("A", positionName, playerRole)
	local mouseBucket = gameState.mouseDirectionBucket
	local aggression = gameState.aggressionTier

	if positionName == "Closed Guard" and playerRole == "Bottom" then
		if qState == "Head/Collar Control" and aState == "Closed Guard Clamp" and mouseBucket == "Down" and (aggression == "Medium" or aggression == "Heavy") then return "Posture breaking / control improvement bias." end
		if qState == "Wrist/Arm Control" and aState == "Foot on Hip / Angle Prep" and isSideMouse(mouseBucket) and isMediumOrHeavy(aggression) then return "Triangle development bias." end
		if qState == "Frame/Post" and (aState == "Foot on Hip / Angle Prep" or aState == "Hip Post / Open Angle") and isUpOrSideMouse(mouseBucket) and isMediumOrHeavy(aggression) then return "Hip bump / angle sweep bias." end
		if mouseBucket == "Down" and aggression ~= "None" then return "Posture breaking / control improvement bias." end
		if isSideMouse(mouseBucket) and aggression ~= "None" then return "Triangle development bias." end
		if mouseBucket == "Up" and aggression ~= "None" then return "Hip bump / angle sweep bias." end
		if aggression == "None" then return "No live pressure. Aiming / repositioning only." elseif aggression == "Medium" then return "Committed action with moderate risk." end
		return "Explosive action with higher risk."
	end

	if positionName == "Mount" and playerRole == "Bottom" then
		if mouseBucket == "Up" and isMediumOrHeavy(aggression) then return "Mount bridge escape bias." end
		if isSideMouse(mouseBucket) and isMediumOrHeavy(aggression) then return "Mount shrimp escape bias." end
		if aggression == "None" then return "No live pressure. Aiming / repositioning only." end
		if mouseBucket == "Down" then return "Mount survival framing bias." end
		return "Mount shrimp escape bias."
	end

	if positionName == "Mount" and playerRole == "Top" then
		if aggression == "None" then return "No live pressure. Aiming / repositioning only." end
		if mouseBucket == "Down" then return "Heavy top mount control bias." end
		if mouseBucket == "Up" and isMediumOrHeavy(aggression) then return "Top mount attack bias." end
		if isSideMouse(mouseBucket) then return "Heavy top mount control bias." end
		return "Top mount attack bias."
	end

	if aggression == "None" then return "No live pressure. Aiming / repositioning only." elseif aggression == "Medium" then return "Placeholder: committed pressure/control/base adjustment." end
	return "Placeholder: explosive pressure/control/base adjustment (higher risk)."
end

function Input.new(config)
	local controller = {}
	local gameState = config.gameState
	local getChannelStateName = config.getChannelStateName
	local cycleChannel = config.cycleChannel
	local runAction = config.runAction
	local render = config.render
	local toggleCameraMode = config.toggleCameraMode

	local lastDebugLine = ""
	local mouseDirectionState = { lastNonNeutralTime = 0 }
	local lastMouseLogTime = 0
	local lastMousePressureTime = tick()
	local lastMountPressureFireTime = 0
	local lastMouseLocation = nil

	local function debugControlGrammar()
		local line = string.format(
			"[ControlGrammar] Position=%s | Role=%s | Q=%s | E=%s | A=%s | D=%s | Mouse=%s | Aggression=%s | Outcome=%s",
			gameState.position,
			gameState.playerRole,
			getChannelStateName("Q", gameState.position, gameState.playerRole),
			getChannelStateName("E", gameState.position, gameState.playerRole),
			getChannelStateName("A", gameState.position, gameState.playerRole),
			getChannelStateName("D", gameState.position, gameState.playerRole),
			gameState.mouseDirectionBucket,
			gameState.aggressionTier,
			gameState.interpretedOutcomeBias
		)
		if line ~= lastDebugLine then print(line); lastDebugLine = line end
	end

	local function tryTriggerActionFromPressure(action)
		local now = tick()
		if (now - gameState.lastActionTime) < ACTION_COOLDOWN then return end
		if gameState.actionPressure < ACTION_THRESHOLD then return end
		gameState.lastActionTime = now
		gameState.actionPressure = 0
		runAction(action)
	end

	local function updateMouseDirectionFromDelta(delta)
		if math.abs(delta.X) < 0.25 and math.abs(delta.Y) < 0.25 then return end
		if math.abs(delta.X) >= math.abs(delta.Y) then gameState.mouseDirectionBucket = delta.X >= 0 and "Right" or "Left"
		else gameState.mouseDirectionBucket = delta.Y >= 0 and "Down" or "Up" end
		mouseDirectionState.lastNonNeutralTime = tick()
	end

	local function getGasMultiplier()
		if gameState.aggressionTier == "Heavy" then return 1.0 elseif gameState.aggressionTier == "Medium" then return 0.6 end
		return 0.0
	end

	local function decayMountInputPressure(dt)
		local decay = dt * 0.7
		gameState.bridgePressure = math.max(0, gameState.bridgePressure - decay)
		gameState.shrimpPressure = math.max(0, gameState.shrimpPressure - decay)
	end

	local function buildMountInputPressureFromDelta(delta)
		if gameState.position ~= "Mount" or gameState.playerRole ~= "Bottom" then return end
		local gas = getGasMultiplier(); if gas <= 0 then return end
		local mag = delta.Magnitude; if mag <= 0 then return end
		local build = math.min(mag / 22, 1.4) * gas * 0.22
		local bucket = gameState.mouseDirectionBucket
		if bucket == "Up" then gameState.bridgePressure = math.min(1.25, gameState.bridgePressure + build)
		elseif bucket == "Left" or bucket == "Right" then gameState.shrimpPressure = math.min(1.25, gameState.shrimpPressure + build)
		elseif bucket == "Down" then gameState.bridgePressure = math.max(0, gameState.bridgePressure - 0.05); gameState.shrimpPressure = math.max(0, gameState.shrimpPressure - 0.03) end
	end

	local function tryMountPressureResolution()
		if gameState.position ~= "Mount" or gameState.playerRole ~= "Bottom" then return end
		local now = tick(); if (now - lastMountPressureFireTime) < MOUNT_PRESSURE_REFIRE_COOLDOWN then return end
		local chosenAction = nil
		if gameState.bridgePressure >= MOUNT_PRESSURE_TRIGGER and gameState.bridgePressure >= gameState.shrimpPressure then chosenAction = "Upa Escape"
		elseif gameState.shrimpPressure >= MOUNT_PRESSURE_TRIGGER then chosenAction = "Elbow Escape" end
		if not chosenAction then return end
		lastMountPressureFireTime = now
		if chosenAction == "Upa Escape" then gameState.bridgePressure = math.max(0, gameState.bridgePressure - 0.75) else gameState.shrimpPressure = math.max(0, gameState.shrimpPressure - 0.75) end
		runAction(chosenAction)
	end

	local function getDerivedMouseDelta()
		local pos = UserInputService:GetMouseLocation()
		if not lastMouseLocation then lastMouseLocation = pos; return Vector2.zero end
		local delta = pos - lastMouseLocation
		lastMouseLocation = pos
		if math.abs(delta.X) < MOUSE_LOCATION_THRESHOLD and math.abs(delta.Y) < MOUSE_LOCATION_THRESHOLD then return Vector2.zero end
		return delta
	end

	local function runInterpretedExchange()
		updateAggressionTier(gameState)
		gameState.interpretedOutcomeBias = interpretOutcomeBias(gameState, getChannelStateName)
		debugControlGrammar()
		local playerAction = Input.mapInterpretationToLegacyAction(gameState.interpretedOutcomeBias)
		tryTriggerActionFromPressure(playerAction)
	end

	function controller.postRender()
		if (tick() - mouseDirectionState.lastNonNeutralTime) > 0.35 then gameState.mouseDirectionBucket = "Neutral" end
	end

	function controller.initialize()
		lastMouseLocation = UserInputService:GetMouseLocation()
		updateAggressionTier(gameState)
		gameState.interpretedOutcomeBias = interpretOutcomeBias(gameState, getChannelStateName)
		debugControlGrammar()
	end

	function controller.bind()
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.KeyCode == Enum.KeyCode.Q then cycleChannel("Q"); gameState.interpretedOutcomeBias = interpretOutcomeBias(gameState, getChannelStateName); debugControlGrammar(); render()
			elseif input.KeyCode == Enum.KeyCode.E then cycleChannel("E"); gameState.interpretedOutcomeBias = interpretOutcomeBias(gameState, getChannelStateName); debugControlGrammar(); render()
			elseif input.KeyCode == Enum.KeyCode.A then cycleChannel("A"); gameState.interpretedOutcomeBias = interpretOutcomeBias(gameState, getChannelStateName); debugControlGrammar(); render()
			elseif input.KeyCode == Enum.KeyCode.D then cycleChannel("D"); gameState.interpretedOutcomeBias = interpretOutcomeBias(gameState, getChannelStateName); debugControlGrammar(); render()
			elseif input.KeyCode == Enum.KeyCode.C then toggleCameraMode(); render()
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
				updateAggressionTier(gameState)
				gameState.interpretedOutcomeBias = interpretOutcomeBias(gameState, getChannelStateName)
				debugControlGrammar()
				render()
			end
		end)

		UserInputService.InputEnded:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
				updateAggressionTier(gameState)
				gameState.interpretedOutcomeBias = interpretOutcomeBias(gameState, getChannelStateName)
				debugControlGrammar()
				render()
			end
		end)

		UserInputService.InputChanged:Connect(function(input, gameProcessed)
			if gameProcessed then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				local now = tick()
				local dt = now - lastMousePressureTime
				lastMousePressureTime = now
				local derivedDelta = getDerivedMouseDelta()
				local mag = derivedDelta.Magnitude
				if mag > 6 and (now - lastMouseLogTime) > 0.15 then
					print(string.format("[MouseDelta] X=%.1f Y=%.1f | Mag=%.1f", derivedDelta.X, derivedDelta.Y, mag))
					lastMouseLogTime = now
				end
				updateMouseDirectionFromDelta(derivedDelta)
				updateAggressionTier(gameState)
				local gas = getGasMultiplier()
				if gas > 0 and mag > 0 then gameState.actionPressure = math.min(1.5, gameState.actionPressure + (mag / 30) * gas)
				else gameState.actionPressure = math.max(0, gameState.actionPressure - 0.05) end
				if gameState.position == "Mount" and gameState.playerRole == "Bottom" then
					decayMountInputPressure(dt)
					buildMountInputPressureFromDelta(derivedDelta)
					tryMountPressureResolution()
				end
				runInterpretedExchange()
				render()
			end
		end)
	end

	return controller
end

return Input
