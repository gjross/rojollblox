local State = {}

local CHANNEL_STATE_WHEELS = {
	DefaultUpper = {"Grip Control", "Frame/Post", "Inside Tie"},
	DefaultLower = {"Clamp/Base", "Angle Prep", "Hip Post"},
	ClosedGuardBottomUpper = {"Head/Collar Control", "Wrist/Arm Control", "Frame/Post"},
	ClosedGuardBottomLower = {"Closed Guard Clamp", "Foot on Hip / Angle Prep", "Hip Post / Open Angle"}
}

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

function State.newGameState()
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
	return gameState
end

function State.getChannelWheel(channel, positionName, playerRole)
	local isClosedGuardBottom = positionName == "Closed Guard" and playerRole == "Bottom"
	local isUpperChannel = channel == "Q" or channel == "E"
	if isClosedGuardBottom then
		return isUpperChannel and CHANNEL_STATE_WHEELS.ClosedGuardBottomUpper or CHANNEL_STATE_WHEELS.ClosedGuardBottomLower
	end
	return isUpperChannel and CHANNEL_STATE_WHEELS.DefaultUpper or CHANNEL_STATE_WHEELS.DefaultLower
end

function State.getChannelStateName(gameState, channel, positionName, playerRole)
	local wheel = State.getChannelWheel(channel, positionName, playerRole)
	local index = gameState.channelStates[channel] or 1
	index = math.clamp(index, 1, #wheel)
	return wheel[index]
end

function State.cycleChannel(gameState, channel)
	local wheel = State.getChannelWheel(channel, gameState.position, gameState.playerRole)
	local current = gameState.channelStates[channel] or 1
	local nextIndex = (current % #wheel) + 1
	gameState.channelStates[channel] = nextIndex
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

local function setState(gameState, position, playerRole, cpuRole)
	local normalizedPlayerRole, normalizedCpuRole = normalizedRolesForPosition(position, playerRole, cpuRole)
	gameState.position = position
	gameState.playerRole = normalizedPlayerRole
	gameState.cpuRole = normalizedCpuRole
end

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

local function randomSuccess(chance)
	return math.random() <= chance
end

local function clampAdvantage(value)
	return math.clamp(value, 0, 3)
end

local function clampThreat(value)
	return math.clamp(value, 0, 2)
end

local function resolveExchange(gameState, positionName, playerRole, cpuRole, playerAction, cpuAction)
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

local function applyAdvantageProgression(gameState, positionName, playerAction, cpuAction)
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

local function applyThreatProgression(gameState, positionName, playerAction, cpuAction)
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

local function buildExchangeLog(gameState, oldPosition, oldPlayerRole, oldCpuRole, playerAction, cpuAction, outcome, newPosition, newPlayerRole, newCpuRole, threatChanges)
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

function State.runPlayerAction(gameState, actionName)
	if not actionName then
		return
	end

	local oldPosition = gameState.position
	local oldPlayerRole = gameState.playerRole
	local oldCpuRole = gameState.cpuRole
	local cpuAction = pickCpuAction(oldPosition, oldCpuRole)
	local outcome = resolveExchange(gameState, oldPosition, oldPlayerRole, oldCpuRole, actionName, cpuAction)
	local threatChanges = applyThreatProgression(gameState, oldPosition, actionName, cpuAction)
	local advantageChanges = applyAdvantageProgression(gameState, oldPosition, actionName, cpuAction)

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

	gameState.playerAction = actionName
	gameState.cpuAction = cpuAction
	setState(gameState, outcome.newPosition, outcome.newPlayerRole, outcome.newCpuRole)
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
		gameState,
		oldPosition,
		oldPlayerRole,
		oldCpuRole,
		actionName,
		cpuAction,
		outcome,
		gameState.position,
		gameState.playerRole,
		gameState.cpuRole,
		threatChanges
	)
end

return State
