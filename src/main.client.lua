--420 859
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

math.randomseed(tick())

print("ROJO WORKS")

-- =====================================================
-- gameState
-- =====================================================
local gameState = {
	position = "Closed Guard",
	playerRole = "Bottom",
	cpuRole = "Top",
	triangleThreat = 0,
	postureLevel = 0,
	mountPressure = 0,
	escapeProgress = 0,
	bridgePressure = 0,
	shrimpPressure = 0,
	triangleAdvantage = 0,
	mountAdvantage = 0,
	escapeAdvantage = 0,
	playerAction = "-",
	cpuAction = "-",
	eventLog = "[Exchange 0] Closed Guard | Player Bottom vs CPU Top\nResult: Match started in closed guard.",
	lastOutcome = "No exchanges yet.",
	exchangeCount = 0,
	playerReaction = 0,
	cpuReaction = 0,
	actionPressure = 0,
	lastActionTime = 0,
	channelStates = {
		Q = 1,
		E = 1,
		A = 1,
		D = 1
	},
	mouseDirectionBucket = "Neutral",
	aggressionTier = "None",
	interpretedOutcomeBias = "No live pressure. Aiming / repositioning only.",
	visualPulse = {
		top = 0,
		bottom = 0
	}
}

gameState.channels = gameState.channelStates

local guiRefs = {}

local CHARACTER_HIDE_TRANSPARENCY = 1
local sceneRefs = {}

local playerFighter
local cpuFighter

local render

local ROLE_COLORS = {
	Top = Color3.fromRGB(250, 195, 60),
	Bottom = Color3.fromRGB(100, 220, 255),
	Neutral = Color3.fromRGB(220, 220, 220)
}

local CHANNEL_STATE_WHEELS = {
	DefaultUpper = {"Grip Control", "Frame/Post", "Inside Tie"},
	DefaultLower = {"Clamp/Base", "Angle Prep", "Hip Post"},
	ClosedGuardBottomUpper = {"Head/Collar Control", "Wrist/Arm Control", "Frame/Post"},
	ClosedGuardBottomLower = {"Closed Guard Clamp", "Foot on Hip / Angle Prep", "Hip Post / Open Angle"}
}

local function getChannelWheel(channel, positionName, playerRole)
	local isClosedGuardBottom = positionName == "Closed Guard" and playerRole == "Bottom"
	local isUpperChannel = channel == "Q" or channel == "E"
	if isClosedGuardBottom then
		return isUpperChannel and CHANNEL_STATE_WHEELS.ClosedGuardBottomUpper or CHANNEL_STATE_WHEELS.ClosedGuardBottomLower
	end

	return isUpperChannel and CHANNEL_STATE_WHEELS.DefaultUpper or CHANNEL_STATE_WHEELS.DefaultLower
end

local function getChannelStateName(channel, positionName, playerRole)
	local wheel = getChannelWheel(channel, positionName, playerRole)
	local index = gameState.channelStates[channel] or 1
	index = math.clamp(index, 1, #wheel)
	return wheel[index]
end


local function setRoles(playerRole, cpuRole)
	gameState.playerRole = playerRole
	gameState.cpuRole = cpuRole
end

local function normalizedRolesForPosition(position, playerRole, cpuRole)
	if position == "Standing" then
		return "Neutral", "Neutral"
	end

	if playerRole == "Top" and cpuRole == "Bottom" then
		return "Top", "Bottom"
	end

	if playerRole == "Bottom" and cpuRole == "Top" then
		return "Bottom", "Top"
	end

	return "Bottom", "Top"
end

local function setState(position, playerRole, cpuRole)
	local normalizedPlayerRole, normalizedCpuRole = normalizedRolesForPosition(position, playerRole, cpuRole)
	gameState.position = position
	setRoles(normalizedPlayerRole, normalizedCpuRole)
end

-- =====================================================
-- move definitions (position + role)
-- =====================================================
local moveDefinitions = {
	["Standing"] = {
		Neutral = {"Takedown Attempt", "Guard Pull"}
	},
	["Closed Guard"] = {
		Bottom = {"Triangle Attempt", "Hip Bump Sweep"},
		Top = {"Posture", "Guard Break"}
	},
	["Side Control"] = {
		Bottom = {"Frame + Recover Guard", "Bridge Escape"},
		Top = {"Stabilize", "Mount Attempt"}
	},
	["Mount"] = {
		Bottom = {"Upa Escape", "Elbow Escape"},
		Top = {"Submission Attempt", "Maintain Mount"}
	}
}

local function validActions(positionName, role)
	local positionData = moveDefinitions[positionName]
	if not positionData then
		return {"Wait", "Wait"}
	end

	local roleData = positionData[role]
	if not roleData then
		return {"Wait", "Wait"}
	end

	return roleData
end

local function pickCpuAction(positionName, role)
	local cpuActions = validActions(positionName, role)
	if #cpuActions == 0 then
		return "Wait"
	end
	return cpuActions[math.random(1, #cpuActions)]
end

-- =====================================================
-- resolution logic
-- =====================================================
local function randomSuccess(chance)
	return math.random() <= chance
end

local function clampAdvantage(value)
	return math.clamp(value, 0, 3)
end

local function resolveExchange(positionName, playerRole, cpuRole, playerAction, cpuAction)
	local result = {
		newPosition = positionName,
		newPlayerRole = playerRole,
		newCpuRole = cpuRole,
		summary = "Both fighters settle. Position stays the same.",
		status = "stays"
	}

	if positionName == "Standing" then
		if playerAction == "Guard Pull" then
			result.newPosition = "Closed Guard"
			result.newPlayerRole = "Bottom"
			result.newCpuRole = "Top"
			result.summary = "You pull guard and land in closed guard bottom."
			result.status = "changes"
		elseif playerAction == "Takedown Attempt" then
			if cpuAction == "Guard Pull" then
				result.newPosition = "Closed Guard"
				result.newPlayerRole = "Top"
				result.newCpuRole = "Bottom"
				result.summary = "CPU pulls guard into your takedown pressure. You become top in closed guard."
				result.status = "changes"
			elseif randomSuccess(0.55) then
				result.newPosition = "Side Control"
				result.newPlayerRole = "Top"
				result.newCpuRole = "Bottom"
				result.summary = "You finish the takedown and settle into top side control."
				result.status = "changes"
			else
				result.newPlayerRole = "Neutral"
				result.newCpuRole = "Neutral"
				result.summary = "CPU defends the takedown. Both stay standing."
			end
		end
	elseif positionName == "Closed Guard" then
		local triangleThreat = gameState.triangleThreat
		local postureLevel = gameState.postureLevel
		local triangleAdvantage = gameState.triangleAdvantage
		local hipBumpChance = math.clamp(0.32 + ((2 - postureLevel) * 0.14) - (triangleAdvantage * 0.03), 0.2, 0.75)
		local guardBreakChance = math.clamp(0.55 + (postureLevel * 0.2), 0.4, 0.9)
		local triangleAttemptChance = math.clamp(0.22 + (triangleThreat * 0.08) + (triangleAdvantage * 0.14) - (postureLevel * 0.08), 0.12, 0.78)
		local triangleFinishChance = math.clamp(0.35 + (triangleAdvantage * 0.12) - (postureLevel * 0.08), 0.2, 0.82)
		local triangleFinishingWindow = triangleThreat >= 2 and postureLevel <= 1

		if playerRole == "Bottom" then
			if playerAction == "Hip Bump Sweep" and randomSuccess(hipBumpChance) then
				result.newPosition = "Closed Guard"
				result.newPlayerRole = "Top"
				result.newCpuRole = "Bottom"
				result.summary = "You hit a hip bump sweep and reverse to top closed guard."
				result.status = "reverses"
			elseif playerAction == "Triangle Attempt" and triangleFinishingWindow and randomSuccess(triangleFinishChance) then
				result.summary = "Triangle is deeply locked from layered attacks. CPU survives, but you're close."
			elseif playerAction == "Triangle Attempt" and randomSuccess(triangleAttemptChance) then
				result.summary = "Triangle developing."
			elseif cpuAction == "Guard Break" and randomSuccess(guardBreakChance) then
				result.newPosition = "Side Control"
				result.newPlayerRole = "Bottom"
				result.newCpuRole = "Top"
				result.summary = "CPU breaks your guard and passes to side control."
				result.status = "changes"
			else
				result.summary = "Guard remains closed, battle continues."
			end
		elseif playerRole == "Top" then
			if playerAction == "Guard Break" and randomSuccess(guardBreakChance) then
				result.newPosition = "Side Control"
				result.newPlayerRole = "Top"
				result.newCpuRole = "Bottom"
				result.summary = "You break guard and pass to side control."
				result.status = "changes"
			elseif cpuAction == "Hip Bump Sweep" and randomSuccess(hipBumpChance) then
				result.newPosition = "Closed Guard"
				result.newPlayerRole = "Bottom"
				result.newCpuRole = "Top"
				result.summary = "CPU times your posture and sweeps."
				result.status = "reverses"
			elseif cpuAction == "Triangle Attempt" and triangleFinishingWindow and randomSuccess(triangleFinishChance) then
				result.summary = "CPU's layered triangle threat is getting tight, but you survive."
			else
				result.summary = "Guard remains closed, battle continues."
			end
		end
	elseif positionName == "Side Control" then
		if playerRole == "Bottom" then
			if playerAction == "Frame + Recover Guard" and randomSuccess(0.75) then
				result.newPosition = "Closed Guard"
				result.newPlayerRole = "Bottom"
				result.newCpuRole = "Top"
				result.summary = "You frame well and recover closed guard."
				result.status = "changes"
			elseif playerAction == "Bridge Escape" and randomSuccess(0.4) then
				result.newPosition = "Closed Guard"
				result.newPlayerRole = "Top"
				result.newCpuRole = "Bottom"
				result.summary = "Bridge escape turns into a reversal. You come up on top in closed guard."
				result.status = "reverses"
			elseif cpuAction == "Mount Attempt" and randomSuccess(0.7) then
				result.newPosition = "Mount"
				result.newPlayerRole = "Bottom"
				result.newCpuRole = "Top"
				result.summary = "CPU climbs from side control to mount."
				result.status = "changes"
			else
				result.summary = "CPU stabilizes side control."
			end
		elseif playerRole == "Top" then
			if playerAction == "Mount Attempt" and randomSuccess(0.7) then
				result.newPosition = "Mount"
				result.newPlayerRole = "Top"
				result.newCpuRole = "Bottom"
				result.summary = "You progress from side control to mount."
				result.status = "changes"
			elseif cpuAction == "Frame + Recover Guard" and randomSuccess(0.75) then
				result.newPosition = "Closed Guard"
				result.newPlayerRole = "Top"
				result.newCpuRole = "Bottom"
				result.summary = "CPU recovers guard, but you stay on top."
				result.status = "changes"
			elseif cpuAction == "Bridge Escape" and randomSuccess(0.4) then
				result.newPosition = "Closed Guard"
				result.newPlayerRole = "Bottom"
				result.newCpuRole = "Top"
				result.summary = "CPU bridges and reverses the position."
				result.status = "reverses"
			else
				result.summary = "You keep chest-to-chest side control pressure."
			end
		end
	elseif positionName == "Mount" then
		local mountPressure = gameState.mountPressure
		local escapeProgress = gameState.escapeProgress
		local mountAdvantage = gameState.mountAdvantage
		local escapeAdvantage = gameState.escapeAdvantage
		local upaSuccessChance = math.clamp(0.56 - (mountPressure * 0.15) - (mountAdvantage * 0.07) + (escapeProgress * 0.08) + (escapeAdvantage * 0.07), 0.15, 0.82)
		local elbowEscapeChance = math.clamp(0.22 + (escapeProgress * 0.22) + (escapeAdvantage * 0.12) + ((2 - mountPressure) * 0.05) - (mountAdvantage * 0.05), 0.15, 0.85)
		local submissionChance = math.clamp(0.2 + (mountPressure * 0.18) + (mountAdvantage * 0.1) - (escapeProgress * 0.08) - (escapeAdvantage * 0.08), 0.1, 0.8)

		if playerRole == "Bottom" then
			if playerAction == "Upa Escape" and randomSuccess(upaSuccessChance) then
				result.newPosition = "Closed Guard"
				result.newPlayerRole = "Top"
				result.newCpuRole = "Bottom"
				result.summary = "Upa escape successful. You bridge and reverse to top closed guard."
				result.status = "reverses"
			elseif playerAction == "Elbow Escape" and randomSuccess(elbowEscapeChance) then
				if escapeProgress >= 2 then
					result.newPosition = "Closed Guard"
					result.newPlayerRole = "Bottom"
					result.newCpuRole = "Top"
					result.summary = "Escape attempt building paid off. You recover guard from mount."
					result.status = "changes"
				else
					result.newPosition = "Side Control"
					result.newPlayerRole = "Bottom"
					result.newCpuRole = "Top"
					result.summary = "Escape attempt building. You make space and drop to side control bottom."
					result.status = "changes"
				end
			elseif cpuAction == "Submission Attempt" and randomSuccess(submissionChance) then
				result.summary = "Submission threat developing from top mount."
			elseif cpuAction == "Maintain Mount" then
				result.summary = "Mount pressure increasing as top stays heavy."
			else
				result.summary = "Top maintaining dominant position in mount."
			end
		elseif playerRole == "Top" then
			if playerAction == "Submission Attempt" and randomSuccess(submissionChance) then
				result.summary = "Submission threat developing from your mount control."
			elseif cpuAction == "Upa Escape" and randomSuccess(upaSuccessChance) then
				result.newPosition = "Closed Guard"
				result.newPlayerRole = "Bottom"
				result.newCpuRole = "Top"
				result.summary = "CPU upa escape successful and reverses you."
				result.status = "reverses"
			elseif cpuAction == "Elbow Escape" and randomSuccess(elbowEscapeChance) then
				if escapeProgress >= 2 then
					result.newPosition = "Closed Guard"
					result.newPlayerRole = "Top"
					result.newCpuRole = "Bottom"
					result.summary = "CPU builds enough movement to recover guard."
					result.status = "changes"
				else
					result.newPosition = "Side Control"
					result.newPlayerRole = "Top"
					result.newCpuRole = "Bottom"
					result.summary = "CPU elbow escape creates space to your side control."
					result.status = "changes"
				end
			elseif playerAction == "Maintain Mount" then
				result.summary = "Mount pressure increasing as you settle weight."
			else
				result.summary = "Top maintaining dominant position in mount."
			end
		end
	end

	return result
end

local function clampThreat(value)
	return math.clamp(value, 0, 2)
end

local function applyAdvantageProgression(positionName, playerAction, cpuAction)
	local oldTriangleAdvantage = gameState.triangleAdvantage
	local oldMountAdvantage = gameState.mountAdvantage
	local oldEscapeAdvantage = gameState.escapeAdvantage
	local advantageEvents = {}

	if positionName == "Closed Guard" then
		if playerAction == "Triangle Attempt" or cpuAction == "Triangle Attempt" then
			gameState.triangleAdvantage = clampAdvantage(gameState.triangleAdvantage + 1)
			table.insert(advantageEvents, "Triangle pressure increasing.")
		end

		if playerAction == "Posture" or cpuAction == "Posture" then
			gameState.triangleAdvantage = clampAdvantage(gameState.triangleAdvantage - 1)
			table.insert(advantageEvents, "Posture regaining control.")
		end
	elseif positionName == "Mount" then
		if playerAction == "Maintain Mount" or cpuAction == "Maintain Mount" then
			gameState.mountAdvantage = clampAdvantage(gameState.mountAdvantage + 1)
			table.insert(advantageEvents, "Mount pressure building.")
		end

		if playerAction == "Upa Escape" or cpuAction == "Upa Escape" or playerAction == "Elbow Escape" or cpuAction == "Elbow Escape" then
			gameState.escapeAdvantage = clampAdvantage(gameState.escapeAdvantage + 1)
			table.insert(advantageEvents, "Escape gaining momentum.")
		end

		if playerAction == "Submission Attempt" or cpuAction == "Submission Attempt" then
			gameState.escapeAdvantage = clampAdvantage(gameState.escapeAdvantage - 1)
		end
	end

	return {
		oldTriangleAdvantage = oldTriangleAdvantage,
		newTriangleAdvantage = gameState.triangleAdvantage,
		oldMountAdvantage = oldMountAdvantage,
		newMountAdvantage = gameState.mountAdvantage,
		oldEscapeAdvantage = oldEscapeAdvantage,
		newEscapeAdvantage = gameState.escapeAdvantage,
		events = advantageEvents
	}
end

local function applyThreatProgression(positionName, playerAction, cpuAction)
	local oldTriangleThreat = gameState.triangleThreat
	local oldPostureLevel = gameState.postureLevel
	local oldMountPressure = gameState.mountPressure
	local oldEscapeProgress = gameState.escapeProgress

	if positionName == "Closed Guard" then
		if playerAction == "Triangle Attempt" or cpuAction == "Triangle Attempt" then
			gameState.triangleThreat = clampThreat(gameState.triangleThreat + 1)
		end

		if playerAction == "Posture" or cpuAction == "Posture" then
			gameState.triangleThreat = clampThreat(gameState.triangleThreat - 1)
			gameState.postureLevel = clampThreat(gameState.postureLevel + 1)
		end

		if playerAction == "Hip Bump Sweep" or cpuAction == "Hip Bump Sweep" then
			gameState.postureLevel = clampThreat(gameState.postureLevel - 1)
		end
	elseif positionName == "Mount" then
		if playerAction == "Maintain Mount" or cpuAction == "Maintain Mount" then
			gameState.mountPressure = clampThreat(gameState.mountPressure + 1)
		end

		if playerAction == "Elbow Escape" or cpuAction == "Elbow Escape" then
			gameState.escapeProgress = clampThreat(gameState.escapeProgress + 1)
		end

		if playerAction == "Submission Attempt" or cpuAction == "Submission Attempt" then
			gameState.escapeProgress = clampThreat(gameState.escapeProgress - 1)
		end
	end

	return {
		oldTriangleThreat = oldTriangleThreat,
		newTriangleThreat = gameState.triangleThreat,
		oldPostureLevel = oldPostureLevel,
		newPostureLevel = gameState.postureLevel,
		oldMountPressure = oldMountPressure,
		newMountPressure = gameState.mountPressure,
		oldEscapeProgress = oldEscapeProgress,
		newEscapeProgress = gameState.escapeProgress
	}
end

local function buildExchangeLog(oldPosition, oldPlayerRole, oldCpuRole, playerAction, cpuAction, outcome, newPosition, newPlayerRole, newCpuRole, threatChanges)
	gameState.exchangeCount += 1
	local momentumLine = ""
	if oldPosition == "Mount" or newPosition == "Mount" then
		local mountPressure = oldPosition == "Mount" and threatChanges.newMountPressure or gameState.mountPressure
		local escapeProgress = oldPosition == "Mount" and threatChanges.newEscapeProgress or gameState.escapeProgress
		if mountPressure > escapeProgress then
			momentumLine = string.format("\nMount: Pressure %d/2 | Escape %d/2 | Momentum: Top control growing.", mountPressure, escapeProgress)
		elseif escapeProgress > mountPressure then
			momentumLine = string.format("\nMount: Pressure %d/2 | Escape %d/2 | Momentum: Bottom escape building.", mountPressure, escapeProgress)
		else
			momentumLine = string.format("\nMount: Pressure %d/2 | Escape %d/2 | Momentum: Even battle.", mountPressure, escapeProgress)
		end
	end

	return string.format(
		"[Exchange %d] %s -> %s\nYou (%s): %s | CPU (%s): %s\nRoles: You %s -> %s | CPU %s -> %s\nResult: %s%s",
		gameState.exchangeCount,
		oldPosition,
		newPosition,
		oldPlayerRole,
		playerAction,
		oldCpuRole,
		cpuAction,
		oldPlayerRole,
		newPlayerRole,
		oldCpuRole,
		newCpuRole,
		outcome.summary,
		momentumLine
	)
end

local function runExchange(playerAction)
	local oldPosition = gameState.position
	local oldPlayerRole = gameState.playerRole
	local oldCpuRole = gameState.cpuRole
	local cpuAction = pickCpuAction(oldPosition, oldCpuRole)
	local outcome = resolveExchange(oldPosition, oldPlayerRole, oldCpuRole, playerAction, cpuAction)
	local threatChanges = applyThreatProgression(oldPosition, playerAction, cpuAction)
	local advantageChanges = applyAdvantageProgression(oldPosition, playerAction, cpuAction)

	if threatChanges.newTriangleThreat > threatChanges.oldTriangleThreat then
		outcome.summary = outcome.summary .. " Triangle developing."
	elseif threatChanges.newTriangleThreat < threatChanges.oldTriangleThreat then
		outcome.summary = outcome.summary .. " Triangle threat reduced by posture."
	end

	if threatChanges.newPostureLevel > threatChanges.oldPostureLevel then
		outcome.summary = outcome.summary .. " Posture improving."
	elseif threatChanges.newPostureLevel < threatChanges.oldPostureLevel then
		outcome.summary = outcome.summary .. " Hip bump opportunity opening."
	end

	if threatChanges.newMountPressure > threatChanges.oldMountPressure then
		outcome.summary = outcome.summary .. " Mount pressure increasing."
	elseif threatChanges.newMountPressure < threatChanges.oldMountPressure then
		outcome.summary = outcome.summary .. " Mount pressure easing."
	end

	if threatChanges.newEscapeProgress > threatChanges.oldEscapeProgress then
		outcome.summary = outcome.summary .. " Escape attempt building."
	elseif threatChanges.newEscapeProgress < threatChanges.oldEscapeProgress then
		outcome.summary = outcome.summary .. " Submission threat slowing escape momentum."
	end

	for _, eventText in ipairs(advantageChanges.events) do
		outcome.summary = outcome.summary .. " " .. eventText
	end

	local playerSwing = 0
	if outcome.status == "reverses" then
		playerSwing = oldPlayerRole == "Bottom" and 1 or -1
	elseif outcome.status == "changes" then
		if outcome.newPlayerRole == "Top" and oldPlayerRole ~= "Top" then
			playerSwing = 1
		elseif outcome.newPlayerRole == "Bottom" and oldPlayerRole ~= "Bottom" then
			playerSwing = -1
		end
	end

	local topPulseGain = 0
	local bottomPulseGain = 0
	if threatChanges.newTriangleThreat > threatChanges.oldTriangleThreat then
		bottomPulseGain += 0.35
	end
	if threatChanges.newPostureLevel > threatChanges.oldPostureLevel then
		topPulseGain += 0.3
	end
	if threatChanges.newMountPressure > threatChanges.oldMountPressure then
		topPulseGain += 0.4
	end
	if threatChanges.newEscapeProgress > threatChanges.oldEscapeProgress then
		bottomPulseGain += 0.35
	end
	if playerSwing > 0 then
		topPulseGain += 0.25
	elseif playerSwing < 0 then
		bottomPulseGain += 0.25
	end

	gameState.visualPulse.top = math.clamp(gameState.visualPulse.top + topPulseGain, 0, 1.5)
	gameState.visualPulse.bottom = math.clamp(gameState.visualPulse.bottom + bottomPulseGain, 0, 1.5)
	gameState.playerReaction = playerSwing
	gameState.cpuReaction = -playerSwing


	gameState.playerAction = playerAction
	gameState.cpuAction = cpuAction
	setState(outcome.newPosition, outcome.newPlayerRole, outcome.newCpuRole)
	if oldPosition == "Closed Guard" and gameState.position ~= "Closed Guard" then
		gameState.triangleThreat = 0
		gameState.postureLevel = 0
		gameState.triangleAdvantage = 0
	end
	if oldPosition == "Mount" and gameState.position ~= "Mount" then
		gameState.mountPressure = 0
		gameState.escapeProgress = 0
		gameState.mountAdvantage = 0
		gameState.escapeAdvantage = 0
		gameState.bridgePressure = 0
		gameState.shrimpPressure = 0
	end
	gameState.lastOutcome = outcome.summary
	gameState.eventLog = buildExchangeLog(
		oldPosition,
		oldPlayerRole,
		oldCpuRole,
		playerAction,
		cpuAction,
		outcome,
		gameState.position,
		gameState.playerRole,
		gameState.cpuRole,
		threatChanges
	)
end

local function runPlayerAction(actionName)
	if not actionName then
		return
	end

	runExchange(actionName)
	if render then
		render()
	end
end

local ACTION_THRESHOLD = 1.0
local ACTION_COOLDOWN = 0.25

local function tryTriggerActionFromPressure(action)
	local now = tick()
	if (now - gameState.lastActionTime) < ACTION_COOLDOWN then
		return
	end

	if gameState.actionPressure < ACTION_THRESHOLD then
		return
	end

	gameState.lastActionTime = now
	gameState.actionPressure = 0
	runPlayerAction(action)
end


local function isSideMouse(bucket)
	return bucket == "Left" or bucket == "Right"
end

local function isUpOrSideMouse(bucket)
	return bucket == "Up" or bucket == "Left" or bucket == "Right"
end

local function isMediumOrHeavy(aggressionTier)
	return aggressionTier == "Medium" or aggressionTier == "Heavy"
end

local function mapInterpretationToLegacyAction(outcomeBias)
	if outcomeBias == "Posture breaking / control improvement bias." then
		return "Triangle Attempt"
	end

	if outcomeBias == "Triangle development bias." then
		return "Triangle Attempt"
	end

	if outcomeBias == "Hip bump / angle sweep bias." then
		return "Hip Bump Sweep"
	end

	if outcomeBias == "Mount bridge escape bias." then
		return "Upa Escape"
	end

	if outcomeBias == "Mount shrimp escape bias." then
		return "Elbow Escape"
	end

	if outcomeBias == "Mount survival framing bias." then
		return "Elbow Escape"
	end

	if outcomeBias == "Heavy top mount control bias." then
		return "Maintain Mount"
	end

	if outcomeBias == "Top mount attack bias." then
		return "Submission Attempt"
	end

	return "Wait"
end

local function updateAggressionTier()
	local isLeftDown = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
	local isRightDown = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	local buttonsDown = (isLeftDown and 1 or 0) + (isRightDown and 1 or 0)

	if buttonsDown == 0 then
		gameState.aggressionTier = "None"
	elseif buttonsDown == 1 then
		gameState.aggressionTier = "Medium"
	else
		gameState.aggressionTier = "Heavy"
	end
end

local function interpretOutcomeBias()
	local positionName = gameState.position
	local playerRole = gameState.playerRole
	local qState = getChannelStateName("Q", positionName, playerRole)
	local aState = getChannelStateName("A", positionName, playerRole)
	local mouseBucket = gameState.mouseDirectionBucket
	local aggression = gameState.aggressionTier

	if positionName == "Closed Guard" and playerRole == "Bottom" then
		if qState == "Head/Collar Control"
			and aState == "Closed Guard Clamp"
			and mouseBucket == "Down"
			and (aggression == "Medium" or aggression == "Heavy") then
			return "Posture breaking / control improvement bias."
		end

		if qState == "Wrist/Arm Control"
			and aState == "Foot on Hip / Angle Prep"
			and isSideMouse(mouseBucket)
			and isMediumOrHeavy(aggression) then
			return "Triangle development bias."
		end

		if qState == "Frame/Post"
			and (aState == "Foot on Hip / Angle Prep" or aState == "Hip Post / Open Angle")
			and isUpOrSideMouse(mouseBucket)
			and isMediumOrHeavy(aggression) then
			return "Hip bump / angle sweep bias."
		end

		if mouseBucket == "Down" and aggression ~= "None" then
			return "Posture breaking / control improvement bias."
		end

		if isSideMouse(mouseBucket) and aggression ~= "None" then
			return "Triangle development bias."
		end

		if mouseBucket == "Up" and aggression ~= "None" then
			return "Hip bump / angle sweep bias."
		end

		if aggression == "None" then
			return "No live pressure. Aiming / repositioning only."
		elseif aggression == "Medium" then
			return "Committed action with moderate risk."
		end

		return "Explosive action with higher risk."
	end

	if positionName == "Mount" and playerRole == "Bottom" then
		if mouseBucket == "Up" and isMediumOrHeavy(aggression) then
			return "Mount bridge escape bias."
		end

		if isSideMouse(mouseBucket) and isMediumOrHeavy(aggression) then
			return "Mount shrimp escape bias."
		end

		if aggression == "None" then
			return "No live pressure. Aiming / repositioning only."
		end

		if mouseBucket == "Down" then
			return "Mount survival framing bias."
		end

		return "Mount shrimp escape bias."
	end

	if positionName == "Mount" and playerRole == "Top" then
		if aggression == "None" then
			return "No live pressure. Aiming / repositioning only."
		end

		if mouseBucket == "Down" then
			return "Heavy top mount control bias."
		end

		if mouseBucket == "Up" and isMediumOrHeavy(aggression) then
			return "Top mount attack bias."
		end

		if isSideMouse(mouseBucket) then
			return "Heavy top mount control bias."
		end

		return "Top mount attack bias."
	end

	if aggression == "None" then
		return "No live pressure. Aiming / repositioning only."
	elseif aggression == "Medium" then
		return "Placeholder: committed pressure/control/base adjustment."
	end

	return "Placeholder: explosive pressure/control/base adjustment (higher risk)."
end

local lastDebugLine = ""

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

	if line ~= lastDebugLine then
		print(line)
		lastDebugLine = line
	end
end

local function runInterpretedExchange()
	updateAggressionTier()
	gameState.interpretedOutcomeBias = interpretOutcomeBias()
	debugControlGrammar()
	local playerAction = mapInterpretationToLegacyAction(gameState.interpretedOutcomeBias)
	tryTriggerActionFromPressure(playerAction)
end

local function cycleChannel(channel)
	local wheel = getChannelWheel(channel, gameState.position, gameState.playerRole)
	local current = gameState.channelStates[channel] or 1
	local nextIndex = (current % #wheel) + 1
	gameState.channelStates[channel] = nextIndex

	gameState.interpretedOutcomeBias = interpretOutcomeBias()
	debugControlGrammar()
	render()
end

local function ensureMat()
	local existing = workspace:FindFirstChild("BJJMat")
	if existing then
		return existing
	end

	local mat = Instance.new("Part")
	mat.Name = "BJJMat"
	mat.Size = Vector3.new(30, 1, 30)
	mat.Position = Vector3.new(0, 0.5, 0)
	mat.Anchored = true
	mat.Material = Enum.Material.SmoothPlastic
	mat.Color = Color3.fromRGB(28, 34, 45)
	mat.Parent = workspace

	return mat
end

local function createScenePart(parent, name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide = true
	part.Material = material or Enum.Material.SmoothPlastic
	part.Color = color
	part.Parent = parent
	return part
end

local function ensureDojoEnvironment()
	local existing = workspace:FindFirstChild("DojoEnvironment")
	if existing then
		return existing
	end

	local env = Instance.new("Model")
	env.Name = "DojoEnvironment"
	env.Parent = workspace

	local baseFloor = createScenePart(env, "WoodFloor", Vector3.new(90, 1, 90), Vector3.new(0, 0, 0), Color3.fromRGB(93, 66, 42), Enum.Material.WoodPlanks)
	baseFloor.Transparency = 0.04
	baseFloor.CastShadow = true

	local matBorder = createScenePart(env, "MatBorder", Vector3.new(34, 0.7, 34), Vector3.new(0, 0.87, 0), Color3.fromRGB(56, 49, 44), Enum.Material.Slate)
	matBorder.CanCollide = false

	local backWall = createScenePart(env, "BackWall", Vector3.new(60, 20, 1), Vector3.new(0, 10, -24), Color3.fromRGB(212, 198, 175), Enum.Material.SmoothPlastic)
	local sideWallA = createScenePart(env, "SideWallA", Vector3.new(1, 20, 48), Vector3.new(-29.5, 10, -0.5), Color3.fromRGB(208, 190, 168), Enum.Material.SmoothPlastic)
	local sideWallB = createScenePart(env, "SideWallB", Vector3.new(1, 20, 48), Vector3.new(29.5, 10, -0.5), Color3.fromRGB(208, 190, 168), Enum.Material.SmoothPlastic)
	local roofBeam = createScenePart(env, "RoofBeam", Vector3.new(60, 1, 5), Vector3.new(0, 19, -24), Color3.fromRGB(70, 49, 34), Enum.Material.Wood)
	backWall.CastShadow = false
	sideWallA.CastShadow = false
	sideWallB.CastShadow = false
	roofBeam.CanCollide = false

	local banner = createScenePart(env, "BackBanner", Vector3.new(20, 5, 0.4), Vector3.new(0, 11.5, -23.4), Color3.fromRGB(32, 35, 44), Enum.Material.SmoothPlastic)
	banner.CanCollide = false

	local trimA = createScenePart(env, "TrimA", Vector3.new(60, 0.8, 0.8), Vector3.new(0, 1.6, -23.6), Color3.fromRGB(90, 66, 42), Enum.Material.Wood)
	local trimB = createScenePart(env, "TrimB", Vector3.new(60, 0.8, 0.8), Vector3.new(0, 18, -23.6), Color3.fromRGB(90, 66, 42), Enum.Material.Wood)
	trimA.CanCollide = false
	trimB.CanCollide = false

	local lightLeft = createScenePart(env, "LanternLeft", Vector3.new(1.8, 4, 1.8), Vector3.new(-11, 13, -22.8), Color3.fromRGB(255, 205, 152), Enum.Material.Neon)
	local lightRight = createScenePart(env, "LanternRight", Vector3.new(1.8, 4, 1.8), Vector3.new(11, 13, -22.8), Color3.fromRGB(255, 205, 152), Enum.Material.Neon)
	lightLeft.CanCollide = false
	lightRight.CanCollide = false
	lightLeft.Transparency = 0.2
	lightRight.Transparency = 0.2

	local focusRiser = createScenePart(env, "FocusRiser", Vector3.new(18, 0.4, 18), Vector3.new(0, 1.22, 0), Color3.fromRGB(32, 34, 39), Enum.Material.SmoothPlastic)
	focusRiser.CanCollide = false

	sceneRefs.backWall = backWall
	sceneRefs.banner = banner
	sceneRefs.focusRiser = focusRiser
	return env
end


local function destroyIfExists(name)
	local existing = workspace:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
end

local function createBodyPart(model, name, size, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Parent = model
	return part
end

local function createRoleBadge(part)
	local old = part:FindFirstChild("RoleBillboard")
	if old then
		old:Destroy()
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "RoleBillboard"
	billboard.Size = UDim2.new(0, 110, 0, 34)
	billboard.StudsOffset = Vector3.new(0, 2.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Name = "RoleText"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 0.2
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = "NEUTRAL"
	label.Parent = billboard
end

local function createSimpleFighter(modelName, color)
	destroyIfExists(modelName)

	local model = Instance.new("Model")
	model.Name = modelName
	model.Parent = workspace

	local torso = createBodyPart(model, "Torso", Vector3.new(2.6, 3.2, 1.7), color)
	local hips = createBodyPart(model, "Hips", Vector3.new(2.4, 1.05, 1.7), color:Lerp(Color3.fromRGB(30, 30, 30), 0.1))
	local shoulders = createBodyPart(model, "Shoulders", Vector3.new(3.1, 0.7, 1.6), color:Lerp(Color3.fromRGB(235, 235, 235), 0.18))
	local chestPlate = createBodyPart(model, "ChestPlate", Vector3.new(2.1, 1, 0.2), Color3.fromRGB(230, 230, 235))
	local head = createBodyPart(model, "Head", Vector3.new(1.9, 1.9, 1.9), Color3.fromRGB(255, 226, 197))
	local faceColor = Color3.fromRGB(18, 18, 18)
	local leftEye = createBodyPart(model, "LeftEye", Vector3.new(0.18, 0.18, 0.05), faceColor)
	local rightEye = createBodyPart(model, "RightEye", Vector3.new(0.18, 0.18, 0.05), faceColor)
	local mouth = createBodyPart(model, "Mouth", Vector3.new(0.42, 0.08, 0.05), faceColor)
	local leftArm = createBodyPart(model, "LeftArm", Vector3.new(0.95, 2.9, 0.95), color)
	local rightArm = createBodyPart(model, "RightArm", Vector3.new(0.95, 2.9, 0.95), color)
	local leftForearm = createBodyPart(model, "LeftForearm", Vector3.new(0.8, 1.85, 0.8), color:Lerp(Color3.fromRGB(15, 15, 15), 0.12))
	local rightForearm = createBodyPart(model, "RightForearm", Vector3.new(0.8, 1.85, 0.8), color:Lerp(Color3.fromRGB(15, 15, 15), 0.12))
	local leftLeg = createBodyPart(model, "LeftLeg", Vector3.new(1.05, 3.2, 1.05), color)
	local rightLeg = createBodyPart(model, "RightLeg", Vector3.new(1.05, 3.2, 1.05), color)
	local leftShin = createBodyPart(model, "LeftShin", Vector3.new(0.9, 1.95, 0.9), color:Lerp(Color3.fromRGB(12, 12, 12), 0.08))
	local rightShin = createBodyPart(model, "RightShin", Vector3.new(0.9, 1.95, 0.9), color:Lerp(Color3.fromRGB(12, 12, 12), 0.08))
	local belt = createBodyPart(model, "Belt", Vector3.new(2.8, 0.35, 1.8), Color3.fromRGB(24, 24, 24))
	local topMarker = createBodyPart(model, "TopMarker", Vector3.new(2.85, 0.16, 1.86), Color3.fromRGB(250, 195, 60))
	local bottomMarker = createBodyPart(model, "BottomMarker", Vector3.new(2.95, 0.12, 1.96), Color3.fromRGB(100, 220, 255))

	createRoleBadge(head)

	return {
		model = model,
		torso = torso,
		hips = hips,
		shoulders = shoulders,
		head = head,
		leftEye = leftEye,
		rightEye = rightEye,
		mouth = mouth,
		leftArm = leftArm,
		rightArm = rightArm,
		leftForearm = leftForearm,
		rightForearm = rightForearm,
		leftLeg = leftLeg,
		rightLeg = rightLeg,
		leftShin = leftShin,
		rightShin = rightShin,
		belt = belt,
		chestPlate = chestPlate,
		topMarker = topMarker,
		bottomMarker = bottomMarker,
		baseColor = color
	}
end

local function setPartCFrame(part, cf)
	part.CFrame = cf
end

local function placeFace(fighter, forwardOffset)
	local headCf = fighter.head.CFrame
	local faceCf = headCf * CFrame.new(0, 0, -(fighter.head.Size.Z / 2 + forwardOffset))

	setPartCFrame(fighter.leftEye, faceCf * CFrame.new(-0.32, 0.18, 0))
	setPartCFrame(fighter.rightEye, faceCf * CFrame.new(0.32, 0.18, 0))
	setPartCFrame(fighter.mouth, faceCf * CFrame.new(0, -0.22, 0))
end

local function placeBelt(fighter)
	setPartCFrame(fighter.hips, fighter.torso.CFrame * CFrame.new(0, -1.7, 0))
	setPartCFrame(fighter.shoulders, fighter.torso.CFrame * CFrame.new(0, 1.5, -0.06))
	setPartCFrame(fighter.belt, fighter.torso.CFrame * CFrame.new(0, -1.05, 0))
	setPartCFrame(fighter.chestPlate, fighter.torso.CFrame * CFrame.new(0, 0.55, -0.95))
	setPartCFrame(fighter.topMarker, fighter.torso.CFrame * CFrame.new(0, -1.0, 0))
	setPartCFrame(fighter.bottomMarker, fighter.torso.CFrame * CFrame.new(0, -1.12, 0))
	setPartCFrame(fighter.leftForearm, fighter.leftArm.CFrame * CFrame.new(0, -1.35, 0))
	setPartCFrame(fighter.rightForearm, fighter.rightArm.CFrame * CFrame.new(0, -1.35, 0))
	setPartCFrame(fighter.leftShin, fighter.leftLeg.CFrame * CFrame.new(0, -1.55, 0))
	setPartCFrame(fighter.rightShin, fighter.rightLeg.CFrame * CFrame.new(0, -1.55, 0))
	placeFace(fighter, 0.03)
end

local function poseStanding(fighter, rootPos, facingYawDegrees)
	local yaw = math.rad(facingYawDegrees)
	local root = CFrame.new(rootPos) * CFrame.Angles(0, yaw, 0)

	setPartCFrame(fighter.torso, root * CFrame.new(0, 4.8, 0))
	setPartCFrame(fighter.head, root * CFrame.new(0, 7.2, 0))
	setPartCFrame(fighter.leftArm, root * CFrame.new(-1.8, 4.8, 0.1) * CFrame.Angles(math.rad(8), 0, math.rad(8)))
	setPartCFrame(fighter.rightArm, root * CFrame.new(1.8, 4.8, 0.1) * CFrame.Angles(math.rad(8), 0, math.rad(-8)))
	setPartCFrame(fighter.leftLeg, root * CFrame.new(-0.75, 1.6, 0))
	setPartCFrame(fighter.rightLeg, root * CFrame.new(0.75, 1.6, 0))
	placeBelt(fighter)
end

local function getAggressionExpressionScale(aggressionTier)
	if aggressionTier == "Heavy" then
		return 1
	elseif aggressionTier == "Medium" then
		return 0.7
	end

	return 0
end

local function getClosedGuardBottomExpressionProfile()
	local channels = gameState.channels or gameState.channelStates or {}
	local q = channels.Q or 1
	local e = channels.E or 1
	local a = channels.A or 1
	local d = channels.D or 1
	local aggressionScale = getAggressionExpressionScale(gameState.aggressionTier)
	local mouseBucket = gameState.mouseDirectionBucket
	if gameState.aggressionTier == "None" then
		mouseBucket = "Neutral"
	end

	local leftArmForward = 0
	local rightArmForward = 0
	local leftArmOut = 0
	local rightArmOut = 0

	local leftHipShift = 0
	local rightHipShift = 0
	local leftKneeOpen = 0
	local rightKneeOpen = 0

	-- LEFT ARM (Q)
	if q == 1 then
		leftArmForward = 0.5
		leftArmOut = -0.2
	elseif q == 2 then
		leftArmForward = 0.2
		leftArmOut = 0.2
	elseif q == 3 then
		leftArmForward = -0.2
		leftArmOut = 0.5
	end

	-- RIGHT ARM (E)
	if e == 1 then
		rightArmForward = 0.5
		rightArmOut = 0.2
	elseif e == 2 then
		rightArmForward = 0.2
		rightArmOut = -0.2
	elseif e == 3 then
		rightArmForward = -0.2
		rightArmOut = -0.5
	end

	-- LEFT LEG (A)
	if a == 1 then
		leftHipShift = -0.2
		leftKneeOpen = -0.3
	elseif a == 2 then
		leftHipShift = 0.1
		leftKneeOpen = 0.1
	elseif a == 3 then
		leftHipShift = 0.4
		leftKneeOpen = 0.4
	end

	-- RIGHT LEG (D)
	if d == 1 then
		rightHipShift = 0.2
		rightKneeOpen = -0.3
	elseif d == 2 then
		rightHipShift = -0.1
		rightKneeOpen = 0.1
	elseif d == 3 then
		rightHipShift = -0.4
		rightKneeOpen = 0.4
	end

	local profile = {
		aggressionScale = aggressionScale,
		mouseBucket = mouseBucket,
		yawOffset = 0,
		sideOffset = 0,
		crunchBias = 0,
		extendBias = 0,
		leftArmForward = leftArmForward,
		rightArmForward = rightArmForward,
		leftArmOut = leftArmOut,
		rightArmOut = rightArmOut,
		leftHipShift = leftHipShift,
		rightHipShift = rightHipShift,
		leftKneeOpen = leftKneeOpen,
		rightKneeOpen = rightKneeOpen
	}

	if mouseBucket == "Left" then
		profile.yawOffset = -14
		profile.sideOffset = -0.24
	elseif mouseBucket == "Right" then
		profile.yawOffset = 14
		profile.sideOffset = 0.24
	elseif mouseBucket == "Down" then
		profile.crunchBias = 0.3
	elseif mouseBucket == "Up" then
		profile.extendBias = 0.3
	end

	return profile
end

local function poseClosedGuardBottom(fighter, rootPos, controlPressure, postureResistance, expressionProfile)
	local root = CFrame.new(rootPos) * CFrame.Angles(math.rad(90), 0, 0)

	-- torso: slightly angled, not flat
	local torsoCf = root
		* CFrame.new(0, 1.0, -0.5)
		* CFrame.Angles(math.rad(-20), 0, 0)

	-- head: always visible, attached, forward of chest
	local headCf = torsoCf
		* CFrame.new(0, 1.1, -0.8)

	-- arms: neutral framing
	local leftArmCf = torsoCf
		* CFrame.new(-1.3, 0.3, 0)
		* CFrame.Angles(0, 0, math.rad(70))

	local rightArmCf = torsoCf
		* CFrame.new(1.3, 0.3, 0)
		* CFrame.Angles(0, 0, math.rad(-70))

	-- legs: wrapped (closed guard)
	local leftLegCf = root
		* CFrame.new(-0.8, 0.6, 1.6)
		* CFrame.Angles(math.rad(25), 0, math.rad(25))

	local rightLegCf = root
		* CFrame.new(0.8, 0.6, 1.6)
		* CFrame.Angles(math.rad(25), 0, math.rad(-25))

	setPartCFrame(fighter.torso, torsoCf)
	setPartCFrame(fighter.head, headCf)
	setPartCFrame(fighter.leftArm, leftArmCf)
	setPartCFrame(fighter.rightArm, rightArmCf)
	setPartCFrame(fighter.leftLeg, leftLegCf)
	setPartCFrame(fighter.rightLeg, rightLegCf)

	placeBelt(fighter)
end

local function poseClosedGuardTop(fighter, rootPos, controlPressure, postureResistance, expressionProfile)
	local root = CFrame.new(rootPos)

	-- hips centered over opponent
	local torsoCf = root
		* CFrame.new(0, 2.2, 0)
		* CFrame.Angles(math.rad(-10), 0, 0)

	-- head: upright, dominant, readable
	local headCf = torsoCf
		* CFrame.new(0, 1.4, 0)

	-- arms: framing on opponent torso (not blocking camera)
	local leftArmCf = torsoCf
		* CFrame.new(-1.0, -0.8, -0.6)
		* CFrame.Angles(math.rad(30), 0, math.rad(30))

	local rightArmCf = torsoCf
		* CFrame.new(1.0, -0.8, -0.6)
		* CFrame.Angles(math.rad(30), 0, math.rad(-30))

	-- knees wide base
	local leftLegCf = root
		* CFrame.new(-1.2, 0, 0.8)
		* CFrame.Angles(0, 0, math.rad(10))

	local rightLegCf = root
		* CFrame.new(1.2, 0, 0.8)
		* CFrame.Angles(0, 0, math.rad(-10))

	setPartCFrame(fighter.torso, torsoCf)
	setPartCFrame(fighter.head, headCf)
	setPartCFrame(fighter.leftArm, leftArmCf)
	setPartCFrame(fighter.rightArm, rightArmCf)
	setPartCFrame(fighter.leftLeg, leftLegCf)
	setPartCFrame(fighter.rightLeg, rightLegCf)

	placeBelt(fighter)
end

local function poseSideControlBottom(fighter, rootPos)
	local root = CFrame.new(rootPos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local torsoCf = root * CFrame.new(0, 1.4, 0)
	setPartCFrame(fighter.torso, torsoCf)
	setPartCFrame(fighter.head, torsoCf * CFrame.new(0, 0.2, -2.35))
	setPartCFrame(fighter.leftArm, CFrame.new(rootPos + Vector3.new(-2.0, 1.6, -0.25)) * CFrame.Angles(math.rad(-20), 0, math.rad(90)))
	setPartCFrame(fighter.rightArm, CFrame.new(rootPos + Vector3.new(2.0, 1.2, -0.45)) * CFrame.Angles(math.rad(8), 0, math.rad(90)))
	setPartCFrame(fighter.leftLeg, CFrame.new(rootPos + Vector3.new(-0.9, 1.2, 2.05)) * CFrame.Angles(math.rad(12), 0, 0))
	setPartCFrame(fighter.rightLeg, CFrame.new(rootPos + Vector3.new(0.9, 1.2, 2.05)) * CFrame.Angles(math.rad(-8), 0, 0))
	placeBelt(fighter)
end

local function poseSideControlTop(fighter, rootPos)
	local root = CFrame.new(rootPos + Vector3.new(0, 0.35, 0.15)) * CFrame.Angles(0, math.rad(90), 0)
	setPartCFrame(fighter.torso, root * CFrame.new(0, 2.9, -0.2) * CFrame.Angles(math.rad(12), 0, 0))
	setPartCFrame(fighter.head, root * CFrame.new(0, 5.1, -0.7))
	setPartCFrame(fighter.leftArm, root * CFrame.new(-1.6, 2.55, 0.65) * CFrame.Angles(math.rad(55), 0, math.rad(8)))
	setPartCFrame(fighter.rightArm, root * CFrame.new(1.65, 2.35, 0.2) * CFrame.Angles(math.rad(25), 0, math.rad(-8)))
	setPartCFrame(fighter.leftLeg, root * CFrame.new(-0.8, 1.5, 1.7) * CFrame.Angles(math.rad(90), 0, 0))
	setPartCFrame(fighter.rightLeg, root * CFrame.new(0.8, 1.5, 1.45) * CFrame.Angles(math.rad(90), 0, 0))
	placeBelt(fighter)
end

local function poseMountBottom(fighter, rootPos, mountPressure, escapeProgress)
	mountPressure = mountPressure or 0
	escapeProgress = escapeProgress or 0
	local flatten = mountPressure * 0.18
	local turn = escapeProgress * 0.14
	local hipShift = escapeProgress * 0.24

	local root = CFrame.new(rootPos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local torsoCf = root * CFrame.new(hipShift, 1.45 - flatten, 0) * CFrame.Angles(math.rad(turn * 24), 0, 0)
	local headLift = 0.72 + flatten * 0.18
	local headDepth = -1.48 + turn * 0.22
	local headPitch = math.rad(-12 + flatten * 10)
	local headYaw = math.rad(-22 + turn * 40)
	local headRoll = math.rad(-8 + turn * 18)

	setPartCFrame(fighter.torso, torsoCf)
	setPartCFrame(fighter.head, torsoCf * CFrame.new(-hipShift * 0.08, headLift, headDepth) * CFrame.Angles(headPitch, headYaw, headRoll))
	setPartCFrame(fighter.leftArm, CFrame.new(rootPos + Vector3.new(-1.6 + hipShift * 0.5, 1.35 - flatten * 0.25, 0.1)) * CFrame.Angles(math.rad(turn * 18), math.rad(20), math.rad(95)))
	setPartCFrame(fighter.rightArm, CFrame.new(rootPos + Vector3.new(1.6 + hipShift * 0.5, 1.35 - flatten * 0.25, 0.1)) * CFrame.Angles(math.rad(-turn * 18), math.rad(-20), math.rad(85)))
	setPartCFrame(fighter.leftLeg, CFrame.new(rootPos + Vector3.new(-0.95 + hipShift, 1.2, 2.1)) * CFrame.Angles(math.rad(12 + turn * 12), 0, 0))
	setPartCFrame(fighter.rightLeg, CFrame.new(rootPos + Vector3.new(0.95 + hipShift, 1.2, 2.1)) * CFrame.Angles(math.rad(-12 + turn * 12), 0, 0))
	placeBelt(fighter)
end

local function poseMountTop(fighter, rootPos, mountPressure, escapeProgress)
	mountPressure = mountPressure or 0
	escapeProgress = escapeProgress or 0
	local upright = mountPressure * 0.2
	local destabilized = escapeProgress * 0.12

	setPartCFrame(fighter.torso, CFrame.new(rootPos + Vector3.new(destabilized * 0.7, 4.1 + upright - (destabilized * 0.5), 0.15)) * CFrame.Angles(math.rad(3 - upright * 10 + (destabilized * 16)), 0, 0))
	setPartCFrame(fighter.head, CFrame.new(rootPos + Vector3.new(destabilized * 0.55, 6.55 + upright * 0.8 - destabilized * 0.35, 0.05 + upright * 0.3)))
	setPartCFrame(fighter.leftArm, CFrame.new(rootPos + Vector3.new(-1.6 + destabilized, 3.55 + upright * 0.35, -0.05)) * CFrame.Angles(math.rad(35 - upright * 8 + destabilized * 18), 0, math.rad(10)))
	setPartCFrame(fighter.rightArm, CFrame.new(rootPos + Vector3.new(1.6 + destabilized, 3.55 + upright * 0.35, -0.05)) * CFrame.Angles(math.rad(35 - upright * 8 + destabilized * 18), 0, math.rad(-10)))
	setPartCFrame(fighter.leftLeg, CFrame.new(rootPos + Vector3.new(-1.65 + destabilized * 0.9, 1.5, 0.45)) * CFrame.Angles(math.rad(90), 0, math.rad(24 - (escapeProgress * 5))))
	setPartCFrame(fighter.rightLeg, CFrame.new(rootPos + Vector3.new(1.65 + destabilized * 0.9, 1.5, 0.45)) * CFrame.Angles(math.rad(90), 0, math.rad(-24 + (escapeProgress * 5))))
	placeBelt(fighter)
end

local function applyTopBottomPose(positionName, topFighter, bottomFighter)
	if positionName == "Closed Guard" then
		local pressureScore = gameState.triangleThreat - gameState.postureLevel
		local controlPressure = math.clamp((pressureScore + 1) / 3, 0, 1)
		local postureResistance = gameState.postureLevel / 2
		local postureState = math.clamp(gameState.postureLevel, 0, 2)
		local expressionProfile = getClosedGuardBottomExpressionProfile()
		poseClosedGuardBottom(bottomFighter, Vector3.new(-0.05, 0.30, -0.10), controlPressure, postureResistance, expressionProfile)
		poseClosedGuardTop(topFighter, Vector3.new(0.05, 0.92, 0.42), postureState, controlPressure)
	elseif positionName == "Side Control" then
		poseSideControlBottom(bottomFighter, Vector3.new(0, 0.6, 0))
		poseSideControlTop(topFighter, Vector3.new(0, 0.6, 0))
	elseif positionName == "Mount" then
		poseMountBottom(bottomFighter, Vector3.new(0, 0.6, 0), gameState.mountPressure, gameState.escapeProgress)
		poseMountTop(topFighter, Vector3.new(0, 0.6, 0), gameState.mountPressure, gameState.escapeProgress)
	end
end

local function applyPositionPose(positionName, playerRole, cpuRole)
	if positionName == "Standing" then
		poseStanding(playerFighter, Vector3.new(-3, 0, 0), 90)
		poseStanding(cpuFighter, Vector3.new(3, 0, 0), -90)
		return
	end

	if playerRole == "Top" and cpuRole == "Bottom" then
		applyTopBottomPose(positionName, playerFighter, cpuFighter)
	elseif playerRole == "Bottom" and cpuRole == "Top" then
		applyTopBottomPose(positionName, cpuFighter, playerFighter)
	else
		poseStanding(playerFighter, Vector3.new(-3, 0, 0), 90)
		poseStanding(cpuFighter, Vector3.new(3, 0, 0), -90)
	end
end

local function applyReactionOffsets(fighter, reaction)
	if not reaction or reaction == 0 then
		return
	end

	local lift = math.abs(reaction) * 0.1
	local lean = reaction * 0.12
	setPartCFrame(fighter.torso, fighter.torso.CFrame * CFrame.new(0, lift, -lean) * CFrame.Angles(math.rad(-reaction * 5), 0, 0))
	setPartCFrame(fighter.head, fighter.head.CFrame * CFrame.new(0, lift * 0.45, -lean * 0.6))
	setPartCFrame(fighter.leftArm, fighter.leftArm.CFrame * CFrame.Angles(math.rad(reaction * 5), 0, 0))
	setPartCFrame(fighter.rightArm, fighter.rightArm.CFrame * CFrame.Angles(math.rad(reaction * 5), 0, 0))
	placeBelt(fighter)
end


local function styleFighterByRole(fighter, role, isPlayer)
	local targetColor = ROLE_COLORS[role] or ROLE_COLORS.Neutral
	local pulse = role == "Top" and gameState.visualPulse.top or gameState.visualPulse.bottom
	local roleMix = 0.2 + (pulse * 0.05)
	local armLegColor = fighter.baseColor:Lerp(targetColor, roleMix)
	fighter.torso.Color = fighter.baseColor:Lerp(targetColor, 0.3 + (pulse * 0.05))
	fighter.hips.Color = fighter.baseColor:Lerp(targetColor, 0.24 + (pulse * 0.04))
	fighter.shoulders.Color = fighter.baseColor:Lerp(targetColor, 0.28 + (pulse * 0.05))
	fighter.leftArm.Color = armLegColor
	fighter.rightArm.Color = armLegColor
	fighter.leftLeg.Color = armLegColor
	fighter.rightLeg.Color = armLegColor
	fighter.leftForearm.Color = armLegColor:Lerp(Color3.fromRGB(245, 245, 245), 0.05 + pulse * 0.08)
	fighter.rightForearm.Color = armLegColor:Lerp(Color3.fromRGB(245, 245, 245), 0.05 + pulse * 0.08)
	fighter.leftShin.Color = armLegColor
	fighter.rightShin.Color = armLegColor
	fighter.chestPlate.Color = fighter.baseColor:Lerp(targetColor, 0.34 + (pulse * 0.07))
	fighter.topMarker.Transparency = role == "Top" and 0.05 or 0.8
	fighter.bottomMarker.Transparency = role == "Bottom" and 0.08 or 0.82
	fighter.topMarker.Color = ROLE_COLORS.Top
	fighter.bottomMarker.Color = ROLE_COLORS.Bottom

	local roleBillboard = fighter.head:FindFirstChild("RoleBillboard")
	if roleBillboard and roleBillboard:FindFirstChild("RoleText") then
		local identityText = isPlayer and "YOU" or "CPU"
		local roleText = roleBillboard.RoleText
		if role == "Top" then
			roleBillboard.StudsOffset = Vector3.new(0.45, 2.85, 0)
		elseif role == "Bottom" then
			roleBillboard.StudsOffset = Vector3.new(-0.45, 1.85, 0)
		else
			roleBillboard.StudsOffset = Vector3.new(0, 2.2, 0)
		end
		roleText.Text = string.upper(identityText .. " • " .. role)
		roleText.BackgroundColor3 = isPlayer and Color3.fromRGB(40, 115, 235) or fighter.baseColor:Lerp(targetColor, 0.55)
		roleText.TextColor3 = Color3.fromRGB(235, 238, 245)
		roleText.TextStrokeTransparency = isPlayer and 0.15 or 0.55
		roleText.TextStrokeColor3 = Color3.fromRGB(10, 14, 22)
		roleText.BackgroundTransparency = isPlayer and 0.05 or 0.2
	end
end

local cameraMode = "Player"

local cameraState = {
	currentCFrame = nil
}

local function getFighterBasis(fighter)
	local torso = fighter and fighter.torso
	local head = fighter and fighter.head
	if not torso or not head then
		return nil
	end

	return {
		torsoPos = torso.Position,
		headPos = head.Position,
		forward = torso.CFrame.LookVector,
		right = torso.CFrame.RightVector,
		up = torso.CFrame.UpVector
	}
end

local function makePlayerCameraTarget(positionName, playerRole)
	local basis = getFighterBasis(playerFighter)
	local opponentBasis = getFighterBasis(cpuFighter)

	if not basis or not opponentBasis then
		return {
			focus = Vector3.new(0, 4, 0),
			offset = Vector3.new(0, 7, 12)
		}
	end

	if positionName == "Standing" then
		local focus = opponentBasis.headPos + Vector3.new(0, -0.4, 0)
		local eye = basis.headPos + (basis.right * 1.2) + Vector3.new(0, 1.8, 8.5)
		return { focus = focus, eye = eye }
	end

	if playerRole == "Top" then
		local focus = opponentBasis.headPos + Vector3.new(0, 0.2, 0)
		local eye = basis.headPos + (basis.right * 2.2) + Vector3.new(0, 2.2, 6.0)
		return { focus = focus, eye = eye }
	else
		local headMid = (basis.headPos + opponentBasis.headPos) * 0.5
		local toOpponent = opponentBasis.headPos - basis.headPos
		local flatBack = Vector3.new(-toOpponent.X, 0, -toOpponent.Z)

		if flatBack.Magnitude < 0.001 then
			flatBack = Vector3.new(0, 0, 1)
		else
			flatBack = flatBack.Unit
		end

		local side = Vector3.new(-flatBack.Z, 0, flatBack.X)

		local focus = Vector3.new(
			headMid.X,
			headMid.Y - 0.2,
			headMid.Z
		)

		local pressureLean = 0
		local pressureLift = 0

		if positionName == "Mount" then
			local bridgeBias = gameState.bridgePressure or 0
			local shrimpBias = gameState.shrimpPressure or 0
			pressureLean = (shrimpBias - bridgeBias * 0.25) * 0.45
			pressureLift = bridgeBias * 0.25
		end

		local eye = basis.headPos
			+ Vector3.new(0, 0.35 + pressureLift, 0)
			+ (flatBack * (3.0 - pressureLift * 0.35))
			+ (side * (0.35 + pressureLean))

		return { focus = focus, eye = eye }
	end
end

local function getCameraTargetForState()
	local positionName = gameState.position
	local playerRole = gameState.playerRole

	if cameraMode == "Coach" then
		if positionName == "Standing" then
			return {
				focus = Vector3.new(0, 4.2, 0),
				offset = Vector3.new(0, 12.5, 22)
			}
		elseif positionName == "Closed Guard" then
			return {
				focus = Vector3.new(0, 3.1, 0.15),
				offset = Vector3.new(0, 11.5, 19.5)
			}
		elseif positionName == "Mount" then
			return {
				focus = Vector3.new(0, 3.2, 0.1),
				offset = Vector3.new(0, 11.8, 19)
			}
		elseif positionName == "Side Control" then
			return {
				focus = Vector3.new(0, 3.0, 0.0),
				offset = Vector3.new(0, 11.3, 18.5)
			}
		end

		return {
			focus = Vector3.new(0, 3.5, 0),
			offset = Vector3.new(0, 12, 20)
		}
	end

	return makePlayerCameraTarget(positionName, playerRole)
end

local function clampCameraEye(eye, focus)
	local minY = 8
	local minZ = 12
	local minX = 3
	--1.6
	if eye.Y < minY then
		eye = Vector3.new(eye.X, minY, eye.Z)
	end

	local toEye = eye - focus
	if toEye.Magnitude < 4 then
		if toEye.Magnitude < 0.001 then
			toEye = Vector3.new(0, 1, 0)
		else
			toEye = toEye.Unit
		end
		eye = focus + (toEye * 4)
	end

	return eye
end

local function updateCamera()
	local camera = workspace.CurrentCamera
	if not camera then return end

	camera.CameraType = Enum.CameraType.Scriptable

	local target = getCameraTargetForState()
	local focus = target.focus
	local eye

	if target.eye then
		eye = clampCameraEye(target.eye, focus)
	else
		eye = clampCameraEye(focus + target.offset, focus)
	end

	local desired = CFrame.lookAt(eye, focus)

	if not cameraState.currentCFrame then
		cameraState.currentCFrame = desired
	else
		cameraState.currentCFrame = cameraState.currentCFrame:Lerp(desired, 0.10)
	end

	camera.CFrame = cameraState.currentCFrame
end

local function toggleCameraMode()
	if cameraMode == "Player" then
		cameraMode = "Coach"
	else
		cameraMode = "Player"
	end

	cameraState.currentCFrame = nil
	print("Camera mode:", cameraMode)
end

-- =====================================================
-- UI rendering
-- =====================================================
local function setMeterPips(pips, activeCount, activeColor, inactiveColor)
	for index, pip in ipairs(pips) do
		pip.BackgroundColor3 = index <= activeCount and activeColor or inactiveColor
	end
end



local mouseDirectionState = {
	lastNonNeutralTime = 0
}
local lastMouseLogTime = 0


local MOUSE_DIRECTION_THRESHOLD = 3
local MOUSE_DIRECTION_HOLD_TIME = 0.18


render = function()
	if mouseDirectionState and (tick() - mouseDirectionState.lastNonNeutralTime) > 0.35 then
		gameState.mouseDirectionBucket = "Neutral"
	end

	if guiRefs.positionLabel then
		guiRefs.positionLabel.Text = gameState.position
	end

	if guiRefs.playerRoleLabel then
		guiRefs.playerRoleLabel.Text = "YOU: " .. string.upper(gameState.playerRole)
	end

	if guiRefs.cpuRoleLabel then
		guiRefs.cpuRoleLabel.Text = "CPU: " .. string.upper(gameState.cpuRole)
	end

	if guiRefs.playerActionLabel then
		guiRefs.playerActionLabel.Text = "You • " .. gameState.playerAction
	end

	if guiRefs.cpuActionLabel then
		guiRefs.cpuActionLabel.Text = "CPU • " .. gameState.cpuAction
	end

	if guiRefs.eventLogLabel then
		guiRefs.eventLogLabel.Text = string.format("E%d • %s", gameState.exchangeCount, gameState.lastOutcome)
	end

	local inClosedGuard = gameState.position == "Closed Guard"
	local inMount = gameState.position == "Mount"
	if guiRefs.closedGuardPanel then
		guiRefs.closedGuardPanel.Visible = inClosedGuard
	end
	if guiRefs.mountPanel then
		guiRefs.mountPanel.Visible = inMount
	end

	if guiRefs.triangleThreatLabel then
		guiRefs.triangleThreatLabel.Text = "Triangle"
	end

	if guiRefs.postureLevelLabel then
		guiRefs.postureLevelLabel.Text = "Posture"
	end

	if guiRefs.triangleThreatPips then
		setMeterPips(guiRefs.triangleThreatPips, gameState.triangleThreat, Color3.fromRGB(246, 112, 95), Color3.fromRGB(61, 55, 63))
	end

	if guiRefs.postureLevelPips then
		setMeterPips(guiRefs.postureLevelPips, gameState.postureLevel, Color3.fromRGB(97, 194, 255), Color3.fromRGB(52, 60, 68))
	end

	if guiRefs.mountPressureLabel then
		guiRefs.mountPressureLabel.Text = "Pressure"
	end

	if guiRefs.escapeProgressLabel then
		guiRefs.escapeProgressLabel.Text = "Escape"
	end

	if guiRefs.mountPressurePips then
		setMeterPips(guiRefs.mountPressurePips, gameState.mountPressure, Color3.fromRGB(245, 175, 74), Color3.fromRGB(66, 54, 37))
	end

	if guiRefs.escapeProgressPips then
		setMeterPips(guiRefs.escapeProgressPips, gameState.escapeProgress, Color3.fromRGB(119, 232, 197), Color3.fromRGB(44, 70, 65))
	end

	if guiRefs.channelStateLabel then
		guiRefs.channelStateLabel.Text = string.format(
			"Q:%s | E:%s | A:%s | D:%s",
			getChannelStateName("Q", gameState.position, gameState.playerRole),
			getChannelStateName("E", gameState.position, gameState.playerRole),
			getChannelStateName("A", gameState.position, gameState.playerRole),
			getChannelStateName("D", gameState.position, gameState.playerRole)
		)
	end

	if guiRefs.controlHintLabel then
		if gameState.position == "Mount" and gameState.playerRole == "Bottom" then
			guiRefs.controlHintLabel.Text = string.format(
				"Mouse Dir: %s • Aggro: %s • Bridge %.2f • Shrimp %.2f • %s",
				gameState.mouseDirectionBucket,
				gameState.aggressionTier,
				gameState.bridgePressure,
				gameState.shrimpPressure,
				gameState.interpretedOutcomeBias
			)
		else
			guiRefs.controlHintLabel.Text = string.format(
				"Mouse Dir: %s • Aggro: %s • %s",
				gameState.mouseDirectionBucket,
				gameState.aggressionTier,
				gameState.interpretedOutcomeBias
			)
		end
	end

	styleFighterByRole(playerFighter, gameState.playerRole, true)
	styleFighterByRole(cpuFighter, gameState.cpuRole, false)

	applyPositionPose(gameState.position, gameState.playerRole, gameState.cpuRole)
	applyReactionOffsets(playerFighter, gameState.playerReaction)
	applyReactionOffsets(cpuFighter, gameState.cpuReaction)
	updateCamera()
	gameState.playerReaction *= 0.55
	gameState.cpuReaction *= 0.55
	gameState.visualPulse.top *= 0.72
	gameState.visualPulse.bottom *= 0.72
end

local function createCard(parent, name, size, position, color)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = color or Color3.fromRGB(17, 22, 31)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Color = Color3.fromRGB(140, 160, 190)
	stroke.Parent = frame
	return frame
end

local function createStyledLabel(parent, name, size, position, text, textScaled, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(240, 244, 255)
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextScaled = textScaled or false
	label.TextSize = textSize or 24
	label.Parent = parent
	return label
end

local function createActionButton(parent, name, size, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(38, 122, 196)
	button.BorderSizePixel = 0
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.Text = "-"
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	return button
end

local function createMeterRow(parent, labelName, labelText, yOffset)
	local label = createStyledLabel(
		parent,
		labelName,
		UDim2.new(0, 210, 0, 22),
		UDim2.new(0, 12, 0, yOffset),
		labelText,
		false,
		16
	)
	label.TextXAlignment = Enum.TextXAlignment.Left

	local pips = {}
	for i = 1, 2 do
		local pip = Instance.new("Frame")
		pip.Name = labelName .. "Pip" .. i
		pip.Size = UDim2.new(0, 38, 0, 14)
		pip.Position = UDim2.new(0, 220 + ((i - 1) * 44), 0, yOffset + 4)
		pip.BackgroundColor3 = Color3.fromRGB(52, 52, 52)
		pip.BorderSizePixel = 0
		pip.Parent = parent
		table.insert(pips, pip)
	end

	return label, pips
end

local function createGuiForPlayer(player)
	local playerGui = player:WaitForChild("PlayerGui")

	local oldGui = playerGui:FindFirstChild("BJJProtoGui")
	if oldGui then
		oldGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BJJProtoGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local keyboardEvent = Instance.new("BindableEvent")
	keyboardEvent.Name = "KeyboardActionEvent"
	keyboardEvent.Parent = screenGui

	local hudRoot = createCard(
		screenGui,
		"HudRoot",
		UDim2.new(0, 360, 0, 222),
		UDim2.new(0, 14, 0, 14),
		Color3.fromRGB(11, 16, 27)
	)

	local positionCard = createCard(hudRoot, "PositionCard", UDim2.new(1, -18, 0, 40), UDim2.new(0, 9, 0, 8), Color3.fromRGB(24, 33, 48))
	local positionLabel = createStyledLabel(positionCard, "PositionLabel", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), "Closed Guard", true, 22)

	local rolesCard = createCard(hudRoot, "RolesCard", UDim2.new(1, -18, 0, 30), UDim2.new(0, 9, 0, 53), Color3.fromRGB(20, 27, 39))
	local playerRoleLabel = createStyledLabel(rolesCard, "PlayerRoleLabel", UDim2.new(0.5, -8, 1, 0), UDim2.new(0, 8, 0, 0), "YOU: BOTTOM", true, 16)
	local cpuRoleLabel = createStyledLabel(rolesCard, "CpuRoleLabel", UDim2.new(0.5, -8, 1, 0), UDim2.new(0.5, 0, 0, 0), "CPU: TOP", true, 16)

	local channelStateLabel = createStyledLabel(
		hudRoot,
		"ChannelStateLabel",
		UDim2.new(1, -18, 0, 34),
		UDim2.new(0, 9, 0, 89),
		"Q:- | E:- | A:- | D:-",
		false,
		12
	)
	channelStateLabel.TextXAlignment = Enum.TextXAlignment.Left
	channelStateLabel.TextWrapped = true

	local controlHintLabel = createStyledLabel(
		hudRoot,
		"ControlHintLabel",
		UDim2.new(1, -18, 0, 24),
		UDim2.new(0, 9, 0, 118),
		"Mouse Dir: Neutral • Aggro: Light",
		false,
		11
	)
	controlHintLabel.TextXAlignment = Enum.TextXAlignment.Left
	controlHintLabel.TextWrapped = true

	local closedGuardPanel = createCard(hudRoot, "ClosedGuardPanel", UDim2.new(1, -18, 0, 58), UDim2.new(0, 9, 0, 155), Color3.fromRGB(28, 24, 36))
	local triangleThreatLabel, triangleThreatPips = createMeterRow(closedGuardPanel, "TriangleThreatLabel", "Triangle Threat", 7)
	local postureLevelLabel, postureLevelPips = createMeterRow(closedGuardPanel, "PostureLevelLabel", "Posture Level", 30)

	local mountPanel = createCard(hudRoot, "MountPanel", UDim2.new(1, -18, 0, 58), UDim2.new(0, 9, 0, 155), Color3.fromRGB(38, 26, 24))
	local mountPressureLabel, mountPressurePips = createMeterRow(mountPanel, "MountPressureLabel", "Mount Pressure", 7)
	local escapeProgressLabel, escapeProgressPips = createMeterRow(mountPanel, "EscapeProgressLabel", "Escape Progress", 30)

	local roundFeed = createCard(screenGui, "RoundFeed", UDim2.new(0, 360, 0, 60), UDim2.new(0, 14, 1, -74), Color3.fromRGB(13, 18, 26))
	local playerActionLabel = createStyledLabel(roundFeed, "PlayerActionLabel", UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 6), "You • -", false, 14)
	playerActionLabel.TextXAlignment = Enum.TextXAlignment.Left

	local cpuActionLabel = createStyledLabel(roundFeed, "CpuActionLabel", UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 23), "CPU • -", false, 14)
	cpuActionLabel.TextXAlignment = Enum.TextXAlignment.Left

	local eventLogLabel = createStyledLabel(roundFeed, "EventLogLabel", UDim2.new(1, -16, 0, 20), UDim2.new(0, 8, 0, 40), "Match started.", false, 12)
	eventLogLabel.TextXAlignment = Enum.TextXAlignment.Left
	eventLogLabel.TextYAlignment = Enum.TextYAlignment.Top
	eventLogLabel.TextWrapped = true
	eventLogLabel.TextTruncate = Enum.TextTruncate.AtEnd

	guiRefs.positionLabel = positionLabel
	guiRefs.playerRoleLabel = playerRoleLabel
	guiRefs.cpuRoleLabel = cpuRoleLabel
	guiRefs.playerActionLabel = playerActionLabel
	guiRefs.cpuActionLabel = cpuActionLabel
	guiRefs.eventLogLabel = eventLogLabel
	guiRefs.closedGuardPanel = closedGuardPanel
	guiRefs.mountPanel = mountPanel
	guiRefs.triangleThreatLabel = triangleThreatLabel
	guiRefs.postureLevelLabel = postureLevelLabel
	guiRefs.triangleThreatPips = triangleThreatPips
	guiRefs.postureLevelPips = postureLevelPips
	guiRefs.mountPressureLabel = mountPressureLabel
	guiRefs.escapeProgressLabel = escapeProgressLabel
	guiRefs.mountPressurePips = mountPressurePips
	guiRefs.escapeProgressPips = escapeProgressPips
	guiRefs.channelStateLabel = channelStateLabel
	guiRefs.controlHintLabel = controlHintLabel

	keyboardEvent.Event:Connect(function(actionName)
		if actionName == "ToggleCamera" then
			toggleCameraMode()
			render()
		end
	end)

	render()
end

local localPlayer = Players.LocalPlayer

local function hideCharacter(character)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = CHARACTER_HIDE_TRANSPARENCY
			descendant.CastShadow = false
		elseif descendant:IsA("Decal") then
			descendant.Transparency = 1
		elseif descendant:IsA("BillboardGui") then
			descendant.Enabled = false
		end
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.CameraOffset = Vector3.new(0, 0, 0)
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		rootPart.CFrame = CFrame.new(0, 6, 27) * CFrame.Angles(0, math.rad(180), 0)
	end
end

local function bootstrapLocal()
	ensureMat()
	ensureDojoEnvironment()

	playerFighter = createSimpleFighter("PlayerFighter", Color3.fromRGB(40, 90, 210))
	cpuFighter = createSimpleFighter("CpuFighter", Color3.fromRGB(210, 70, 70))

	if localPlayer.Character then
		hideCharacter(localPlayer.Character)
	end
	localPlayer.CharacterAdded:Connect(hideCharacter)

	--localPlayer.CameraMode = Enum.CameraMode.Classic
	--localPlayer.CameraMinZoomDistance = 23
	--localPlayer.CameraMaxZoomDistance = 23

	createGuiForPlayer(localPlayer)
	gameState.interpretedOutcomeBias = interpretOutcomeBias()
	debugControlGrammar()
	lastMouseLocation = UserInputService:GetMouseLocation()
	render()
end


local function updateMouseDirectionFromDelta(delta)
	if math.abs(delta.X) < 0.25 and math.abs(delta.Y) < 0.25 then
		return
	end

	if math.abs(delta.X) >= math.abs(delta.Y) then
		if delta.X >= 0 then
			gameState.mouseDirectionBucket = "Right"
		else
			gameState.mouseDirectionBucket = "Left"
		end
	else
		if delta.Y >= 0 then
			gameState.mouseDirectionBucket = "Down"
		else
			gameState.mouseDirectionBucket = "Up"
		end
	end

	mouseDirectionState.lastNonNeutralTime = tick()
end

local function getGasMultiplier()
	if gameState.aggressionTier == "Heavy" then
		return 1.0
	elseif gameState.aggressionTier == "Medium" then
		return 0.6
	end

	return 0.0
end

local function decayMountInputPressure(dt)
	local decay = dt * 0.7
	gameState.bridgePressure = math.max(0, gameState.bridgePressure - decay)
	gameState.shrimpPressure = math.max(0, gameState.shrimpPressure - decay)
end

local function buildMountInputPressureFromDelta(delta)
	if gameState.position ~= "Mount" or gameState.playerRole ~= "Bottom" then
		return
	end

	local gas = getGasMultiplier()
	if gas <= 0 then
		return
	end

	local mag = delta.Magnitude
	if mag <= 0 then
		return
	end

	local build = math.min(mag / 22, 1.4) * gas * 0.22
	local bucket = gameState.mouseDirectionBucket

	if bucket == "Up" then
		gameState.bridgePressure = math.min(1.25, gameState.bridgePressure + build)
	elseif bucket == "Left" or bucket == "Right" then
		gameState.shrimpPressure = math.min(1.25, gameState.shrimpPressure + build)
	elseif bucket == "Down" then
		gameState.bridgePressure = math.max(0, gameState.bridgePressure - 0.05)
		gameState.shrimpPressure = math.max(0, gameState.shrimpPressure - 0.03)
	end
end

local lastMousePressureTime = tick()
local MOUNT_PRESSURE_TRIGGER = 1.0
local MOUNT_PRESSURE_REFIRE_COOLDOWN = 0.22
local lastMountPressureFireTime = 0

local function tryMountPressureResolution()
	if gameState.position ~= "Mount" or gameState.playerRole ~= "Bottom" then
		return
	end

	local now = tick()
	if (now - lastMountPressureFireTime) < MOUNT_PRESSURE_REFIRE_COOLDOWN then
		return
	end

	local chosenAction = nil

	if gameState.bridgePressure >= MOUNT_PRESSURE_TRIGGER and gameState.bridgePressure >= gameState.shrimpPressure then
		chosenAction = "Upa Escape"
	elseif gameState.shrimpPressure >= MOUNT_PRESSURE_TRIGGER then
		chosenAction = "Elbow Escape"
	end

	if not chosenAction then
		return
	end

	lastMountPressureFireTime = now

	if chosenAction == "Upa Escape" then
		gameState.bridgePressure = math.max(0, gameState.bridgePressure - 0.75)
	else
		gameState.shrimpPressure = math.max(0, gameState.shrimpPressure - 0.75)
	end

	runPlayerAction(chosenAction)
end
local lastMouseLocation = nil
local MOUSE_LOCATION_THRESHOLD = 2

local function getDerivedMouseDelta()
	local pos = UserInputService:GetMouseLocation()

	if not lastMouseLocation then
		lastMouseLocation = pos
		return Vector2.zero
	end

	local delta = pos - lastMouseLocation
	lastMouseLocation = pos

	if math.abs(delta.X) < MOUSE_LOCATION_THRESHOLD and math.abs(delta.Y) < MOUSE_LOCATION_THRESHOLD then
		return Vector2.zero
	end

	return delta
end

local function bindInputs()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.Q then
			cycleChannel("Q")
		elseif input.KeyCode == Enum.KeyCode.E then
			cycleChannel("E")
		elseif input.KeyCode == Enum.KeyCode.A then
			cycleChannel("A")
		elseif input.KeyCode == Enum.KeyCode.D then
			cycleChannel("D")
		elseif input.KeyCode == Enum.KeyCode.C then
			toggleCameraMode()
			render()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.MouseButton2 then
			updateAggressionTier()
			gameState.interpretedOutcomeBias = interpretOutcomeBias()
			debugControlGrammar()
			render()
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.MouseButton2 then
			updateAggressionTier()
			gameState.interpretedOutcomeBias = interpretOutcomeBias()
			debugControlGrammar()
			render()
		end
	end)

	UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local now = tick()
			local dt = now - lastMousePressureTime
			lastMousePressureTime = now

			local derivedDelta = getDerivedMouseDelta()

			local mag = derivedDelta.Magnitude
			local now = tick()

			if mag > 6 and (now - lastMouseLogTime) > 0.15 then
				print(string.format(
					"[MouseDelta] X=%.1f Y=%.1f | Mag=%.1f",
					derivedDelta.X,
					derivedDelta.Y,
					mag
					))
				lastMouseLogTime = now
			end

			updateMouseDirectionFromDelta(derivedDelta)
			updateAggressionTier()
			local gas = getGasMultiplier()
			local mag = derivedDelta.Magnitude

			if gas > 0 and mag > 0 then
				gameState.actionPressure = math.min(1.5, gameState.actionPressure + (mag / 30) * gas)
			else
				gameState.actionPressure = math.max(0, gameState.actionPressure - 0.05)
			end

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

bootstrapLocal()
bindInputs()






