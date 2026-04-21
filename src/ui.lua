local UI = {}

local function setMeterPips(pips, activeCount, activeColor, inactiveColor)
	for index, pip in ipairs(pips) do
		pip.BackgroundColor3 = index <= activeCount and activeColor or inactiveColor
	end
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

local function createMeterRow(parent, labelName, labelText, yOffset)
	local label = createStyledLabel(parent, labelName, UDim2.new(0, 210, 0, 22), UDim2.new(0, 12, 0, yOffset), labelText, false, 16)
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

function UI.createGuiForPlayer(player)
	local guiRefs = {}
	local playerGui = player:WaitForChild("PlayerGui")
	local oldGui = playerGui:FindFirstChild("BJJProtoGui")
	if oldGui then
		oldGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BJJProtoGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local hudRoot = createCard(screenGui, "HudRoot", UDim2.new(0, 360, 0, 222), UDim2.new(0, 14, 0, 14), Color3.fromRGB(11, 16, 27))
	local positionCard = createCard(hudRoot, "PositionCard", UDim2.new(1, -18, 0, 40), UDim2.new(0, 9, 0, 8), Color3.fromRGB(24, 33, 48))
	local positionLabel = createStyledLabel(positionCard, "PositionLabel", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), "Closed Guard", true, 22)
	local rolesCard = createCard(hudRoot, "RolesCard", UDim2.new(1, -18, 0, 30), UDim2.new(0, 9, 0, 53), Color3.fromRGB(20, 27, 39))
	local playerRoleLabel = createStyledLabel(rolesCard, "PlayerRoleLabel", UDim2.new(0.5, -8, 1, 0), UDim2.new(0, 8, 0, 0), "YOU: BOTTOM", true, 16)
	local cpuRoleLabel = createStyledLabel(rolesCard, "CpuRoleLabel", UDim2.new(0.5, -8, 1, 0), UDim2.new(0.5, 0, 0, 0), "CPU: TOP", true, 16)
	local channelStateLabel = createStyledLabel(hudRoot, "ChannelStateLabel", UDim2.new(1, -18, 0, 34), UDim2.new(0, 9, 0, 89), "Q:- | E:- | A:- | D:-", false, 12)
	channelStateLabel.TextXAlignment = Enum.TextXAlignment.Left
	channelStateLabel.TextWrapped = true

	local controlHintLabel = createStyledLabel(hudRoot, "ControlHintLabel", UDim2.new(1, -18, 0, 24), UDim2.new(0, 9, 0, 118), "Mouse Dir: Neutral | Aggro: Light", false, 11)
	controlHintLabel.TextXAlignment = Enum.TextXAlignment.Left
	controlHintLabel.TextWrapped = true

	local closedGuardPanel = createCard(hudRoot, "ClosedGuardPanel", UDim2.new(1, -18, 0, 58), UDim2.new(0, 9, 0, 155), Color3.fromRGB(28, 24, 36))
	local triangleThreatLabel, triangleThreatPips = createMeterRow(closedGuardPanel, "TriangleThreatLabel", "Triangle Threat", 7)
	local postureLevelLabel, postureLevelPips = createMeterRow(closedGuardPanel, "PostureLevelLabel", "Posture Level", 30)

	local mountPanel = createCard(hudRoot, "MountPanel", UDim2.new(1, -18, 0, 58), UDim2.new(0, 9, 0, 155), Color3.fromRGB(38, 26, 24))
	local mountPressureLabel, mountPressurePips = createMeterRow(mountPanel, "MountPressureLabel", "Mount Pressure", 7)
	local escapeProgressLabel, escapeProgressPips = createMeterRow(mountPanel, "EscapeProgressLabel", "Escape Progress", 30)

	local roundFeed = createCard(screenGui, "RoundFeed", UDim2.new(0, 360, 0, 60), UDim2.new(0, 14, 1, -74), Color3.fromRGB(13, 18, 26))
	local playerActionLabel = createStyledLabel(roundFeed, "PlayerActionLabel", UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 6), "You - -", false, 14)
	playerActionLabel.TextXAlignment = Enum.TextXAlignment.Left

	local cpuActionLabel = createStyledLabel(roundFeed, "CpuActionLabel", UDim2.new(1, -16, 0, 18), UDim2.new(0, 8, 0, 23), "CPU - -", false, 14)
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

	return guiRefs
end

function UI.render(guiRefs, gameState, getChannelStateName)
	if guiRefs.positionLabel then guiRefs.positionLabel.Text = gameState.position end
	if guiRefs.playerRoleLabel then guiRefs.playerRoleLabel.Text = "YOU: " .. string.upper(gameState.playerRole) end
	if guiRefs.cpuRoleLabel then guiRefs.cpuRoleLabel.Text = "CPU: " .. string.upper(gameState.cpuRole) end
	if guiRefs.playerActionLabel then guiRefs.playerActionLabel.Text = "You - " .. gameState.playerAction end
	if guiRefs.cpuActionLabel then guiRefs.cpuActionLabel.Text = "CPU - " .. gameState.cpuAction end
	if guiRefs.eventLogLabel then guiRefs.eventLogLabel.Text = string.format("E%d - %s", gameState.exchangeCount, gameState.lastOutcome) end

	local inClosedGuard = gameState.position == "Closed Guard"
	local inMount = gameState.position == "Mount"
	if guiRefs.closedGuardPanel then guiRefs.closedGuardPanel.Visible = inClosedGuard end
	if guiRefs.mountPanel then guiRefs.mountPanel.Visible = inMount end

	if guiRefs.triangleThreatLabel then guiRefs.triangleThreatLabel.Text = "Triangle" end
	if guiRefs.postureLevelLabel then guiRefs.postureLevelLabel.Text = "Posture" end
	if guiRefs.triangleThreatPips then setMeterPips(guiRefs.triangleThreatPips, gameState.triangleThreat, Color3.fromRGB(246, 112, 95), Color3.fromRGB(61, 55, 63)) end
	if guiRefs.postureLevelPips then setMeterPips(guiRefs.postureLevelPips, gameState.postureLevel, Color3.fromRGB(97, 194, 255), Color3.fromRGB(52, 60, 68)) end
	if guiRefs.mountPressureLabel then guiRefs.mountPressureLabel.Text = "Pressure" end
	if guiRefs.escapeProgressLabel then guiRefs.escapeProgressLabel.Text = "Escape" end
	if guiRefs.mountPressurePips then setMeterPips(guiRefs.mountPressurePips, gameState.mountPressure, Color3.fromRGB(245, 175, 74), Color3.fromRGB(66, 54, 37)) end
	if guiRefs.escapeProgressPips then setMeterPips(guiRefs.escapeProgressPips, gameState.escapeProgress, Color3.fromRGB(119, 232, 197), Color3.fromRGB(44, 70, 65)) end

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
				"Mouse Dir: %s | Aggro: %s | Bridge %.2f | Shrimp %.2f | %s",
				gameState.mouseDirectionBucket,
				gameState.aggressionTier,
				gameState.bridgePressure,
				gameState.shrimpPressure,
				gameState.interpretedOutcomeBias
			)
		else
			guiRefs.controlHintLabel.Text = string.format(
				"Mouse Dir: %s | Aggro: %s | %s",
				gameState.mouseDirectionBucket,
				gameState.aggressionTier,
				gameState.interpretedOutcomeBias
			)
		end
	end
end

return UI
