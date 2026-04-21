local Poses = {}

local CHARACTER_HIDE_TRANSPARENCY = 1

local ROLE_COLORS = {
	Top = Color3.fromRGB(250, 195, 60),
	Bottom = Color3.fromRGB(100, 220, 255),
	Neutral = Color3.fromRGB(220, 220, 220)
}

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

local function ensureMat()
	local existing = workspace:FindFirstChild("BJJMat")
	if existing then return existing end
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

local function ensureDojoEnvironment(sceneRefs)
	local existing = workspace:FindFirstChild("DojoEnvironment")
	if existing then return existing end
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
	if existing then existing:Destroy() end
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
	if old then old:Destroy() end
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
	local torso = createBodyPart(model, "Torso", Vector3.new(1.2, 3.2, 0.9), color)
	local hips = createBodyPart(model, "Hips", Vector3.new(1.1, 0.75, 0.9), color:Lerp(Color3.fromRGB(30, 30, 30), 0.1))
	local shoulders = createBodyPart(model, "Shoulders", Vector3.new(1.5, 0.5, 0.9), color:Lerp(Color3.fromRGB(235, 235, 235), 0.18))
	local chestPlate = createBodyPart(model, "ChestPlate", Vector3.new(0.98, 0.9, 0.13), Color3.fromRGB(230, 230, 235))
	local head = createBodyPart(model, "Head", Vector3.new(1.3, 1.3, 1.3), Color3.fromRGB(255, 226, 197))
	local faceColor = Color3.fromRGB(18, 18, 18)
	local leftEye = createBodyPart(model, "LeftEye", Vector3.new(0.14, 0.14, 0.05), faceColor)
	local rightEye = createBodyPart(model, "RightEye", Vector3.new(0.14, 0.14, 0.05), faceColor)
	local mouth = createBodyPart(model, "Mouth", Vector3.new(0.34, 0.07, 0.05), faceColor)
	local leftArm = createBodyPart(model, "LeftArm", Vector3.new(0.38, 2.9, 0.38), color)
	local rightArm = createBodyPart(model, "RightArm", Vector3.new(0.38, 2.9, 0.38), color)
	local leftForearm = createBodyPart(model, "LeftForearm", Vector3.new(0.32, 1.85, 0.32), color:Lerp(Color3.fromRGB(15, 15, 15), 0.12))
	local rightForearm = createBodyPart(model, "RightForearm", Vector3.new(0.32, 1.85, 0.32), color:Lerp(Color3.fromRGB(15, 15, 15), 0.12))
	local leftLeg = createBodyPart(model, "LeftLeg", Vector3.new(0.42, 3.2, 0.42), color)
	local rightLeg = createBodyPart(model, "RightLeg", Vector3.new(0.42, 3.2, 0.42), color)
	local leftShin = createBodyPart(model, "LeftShin", Vector3.new(0.32, 1.95, 0.32), color:Lerp(Color3.fromRGB(12, 12, 12), 0.08))
	local rightShin = createBodyPart(model, "RightShin", Vector3.new(0.32, 1.95, 0.32), color:Lerp(Color3.fromRGB(12, 12, 12), 0.08))
	local belt = createBodyPart(model, "Belt", Vector3.new(1.26, 0.3, 0.97), Color3.fromRGB(24, 24, 24))
	local topMarker = createBodyPart(model, "TopMarker", Vector3.new(1.29, 0.14, 1.02), Color3.fromRGB(250, 195, 60))
	local bottomMarker = createBodyPart(model, "BottomMarker", Vector3.new(1.36, 0.1, 1.08), Color3.fromRGB(100, 220, 255))
	createRoleBadge(head)
	return { model = model, torso = torso, hips = hips, shoulders = shoulders, head = head, leftEye = leftEye, rightEye = rightEye, mouth = mouth, leftArm = leftArm, rightArm = rightArm, leftForearm = leftForearm, rightForearm = rightForearm, leftLeg = leftLeg, rightLeg = rightLeg, leftShin = leftShin, rightShin = rightShin, belt = belt, chestPlate = chestPlate, topMarker = topMarker, bottomMarker = bottomMarker, baseColor = color }
end

local function setPartCFrame(part, cf) part.CFrame = cf end
local function placeFace(fighter, forwardOffset)
	local headCf = fighter.head.CFrame
	local faceCf = headCf * CFrame.new(0, 0, -(fighter.head.Size.Z / 2 + forwardOffset))
	setPartCFrame(fighter.leftEye, faceCf * CFrame.new(-0.24, 0.14, 0))
	setPartCFrame(fighter.rightEye, faceCf * CFrame.new(0.24, 0.14, 0))
	setPartCFrame(fighter.mouth, faceCf * CFrame.new(0, -0.18, 0))
end
local function placeBelt(fighter)
	setPartCFrame(fighter.hips, fighter.torso.CFrame * CFrame.new(0, -1.6, 0))
	setPartCFrame(fighter.shoulders, fighter.torso.CFrame * CFrame.new(0, 1.5, -0.06))
	setPartCFrame(fighter.belt, fighter.torso.CFrame * CFrame.new(0, -1.05, 0))
	setPartCFrame(fighter.chestPlate, fighter.torso.CFrame * CFrame.new(0, 0.5, -0.72))
	setPartCFrame(fighter.topMarker, fighter.torso.CFrame * CFrame.new(0, -1.0, 0))
	setPartCFrame(fighter.bottomMarker, fighter.torso.CFrame * CFrame.new(0, -1.12, 0))
	setPartCFrame(fighter.leftForearm, fighter.leftArm.CFrame * CFrame.new(0, -1.35, 0))
	setPartCFrame(fighter.rightForearm, fighter.rightArm.CFrame * CFrame.new(0, -1.35, 0))
	setPartCFrame(fighter.leftShin, fighter.leftLeg.CFrame * CFrame.new(0, -1.55, 0))
	setPartCFrame(fighter.rightShin, fighter.rightLeg.CFrame * CFrame.new(0, -1.55, 0))
	placeFace(fighter, 0.03)
end

local function poseStanding(f, p, yaw)
	local root = CFrame.new(p) * CFrame.Angles(0, math.rad(yaw), 0)
	setPartCFrame(f.torso, root * CFrame.new(0, 4.8, 0)); setPartCFrame(f.head, root * CFrame.new(0, 7.2, 0))
	setPartCFrame(f.leftArm, root * CFrame.new(-1.8, 4.8, 0.1) * CFrame.Angles(math.rad(8), 0, math.rad(8)))
	setPartCFrame(f.rightArm, root * CFrame.new(1.8, 4.8, 0.1) * CFrame.Angles(math.rad(8), 0, math.rad(-8)))
	setPartCFrame(f.leftLeg, root * CFrame.new(-0.75, 1.6, 0)); setPartCFrame(f.rightLeg, root * CFrame.new(0.75, 1.6, 0)); placeBelt(f)
end

local function getClosedGuardBottomExpressionProfile(gameState)
	local channels = gameState.channels or gameState.channelStates or {}
	local q = channels.Q or 1; local e = channels.E or 1; local a = channels.A or 1; local d = channels.D or 1
	local mouseBucket = gameState.aggressionTier == "None" and "Neutral" or gameState.mouseDirectionBucket
	local profile = { mouseBucket = mouseBucket, yawOffset = 0, sideOffset = 0, crunchBias = 0, extendBias = 0, leftArmForward = 0, rightArmForward = 0, leftArmOut = 0, rightArmOut = 0, leftHipShift = 0, rightHipShift = 0, leftKneeOpen = 0, rightKneeOpen = 0 }
	if q == 1 then profile.leftArmForward, profile.leftArmOut = 0.5, -0.2 elseif q == 2 then profile.leftArmForward, profile.leftArmOut = 0.2, 0.2 else profile.leftArmForward, profile.leftArmOut = -0.2, 0.5 end
	if e == 1 then profile.rightArmForward, profile.rightArmOut = 0.5, 0.2 elseif e == 2 then profile.rightArmForward, profile.rightArmOut = 0.2, -0.2 else profile.rightArmForward, profile.rightArmOut = -0.2, -0.5 end
	if a == 1 then profile.leftHipShift, profile.leftKneeOpen = -0.2, -0.3 elseif a == 2 then profile.leftHipShift, profile.leftKneeOpen = 0.1, 0.1 else profile.leftHipShift, profile.leftKneeOpen = 0.4, 0.4 end
	if d == 1 then profile.rightHipShift, profile.rightKneeOpen = 0.2, -0.3 elseif d == 2 then profile.rightHipShift, profile.rightKneeOpen = -0.1, 0.1 else profile.rightHipShift, profile.rightKneeOpen = -0.4, 0.4 end
	if mouseBucket == "Left" then profile.yawOffset, profile.sideOffset = -14, -0.24 elseif mouseBucket == "Right" then profile.yawOffset, profile.sideOffset = 14, 0.24 elseif mouseBucket == "Down" then profile.crunchBias = 0.3 elseif mouseBucket == "Up" then profile.extendBias = 0.3 end
	return profile
end

local function poseClosedGuardBottom(fighter, rootPos)
	local root = CFrame.new(rootPos) * CFrame.Angles(math.rad(90), 0, 0)
	local torsoCf = root * CFrame.new(0, 1.1, -0.45) * CFrame.Angles(math.rad(-32), 0, 0)
	local headCf = torsoCf * CFrame.new(0, 1.2, -0.68) * CFrame.Angles(math.rad(8), 0, 0)
	local leftArmCf = torsoCf * CFrame.new(-1.2, 0.45, -0.18) * CFrame.Angles(math.rad(-10), math.rad(10), math.rad(60))
	local rightArmCf = torsoCf * CFrame.new(1.2, 0.45, -0.18) * CFrame.Angles(math.rad(-10), math.rad(-10), math.rad(-60))
	local leftLegCf = root * CFrame.new(-1.08, 1.05, 1.25) * CFrame.Angles(math.rad(40), math.rad(-8), math.rad(46))
	local rightLegCf = root * CFrame.new(1.08, 1.05, 1.25) * CFrame.Angles(math.rad(40), math.rad(8), math.rad(-46))
	setPartCFrame(fighter.torso, torsoCf); setPartCFrame(fighter.head, headCf); setPartCFrame(fighter.leftArm, leftArmCf); setPartCFrame(fighter.rightArm, rightArmCf); setPartCFrame(fighter.leftLeg, leftLegCf); setPartCFrame(fighter.rightLeg, rightLegCf); placeBelt(fighter)
end
local function poseClosedGuardTop(fighter, rootPos)
	local root = CFrame.new(rootPos)
	local torsoCf = root * CFrame.new(0, 1.9, -0.22) * CFrame.Angles(math.rad(24), 0, 0)
	local headCf = torsoCf * CFrame.new(0, 1.28, -0.28) * CFrame.Angles(math.rad(6), 0, 0)
	local leftArmCf = torsoCf * CFrame.new(-1.08, -1.12, -0.86) * CFrame.Angles(math.rad(56), math.rad(6), math.rad(16))
	local rightArmCf = torsoCf * CFrame.new(1.08, -1.12, -0.86) * CFrame.Angles(math.rad(56), math.rad(-6), math.rad(-16))
	local leftLegCf = root * CFrame.new(-1.45, -0.12, 0.42) * CFrame.Angles(math.rad(6), math.rad(4), math.rad(16))
	local rightLegCf = root * CFrame.new(1.45, -0.12, 0.42) * CFrame.Angles(math.rad(6), math.rad(-4), math.rad(-16))
	setPartCFrame(fighter.torso, torsoCf); setPartCFrame(fighter.head, headCf); setPartCFrame(fighter.leftArm, leftArmCf); setPartCFrame(fighter.rightArm, rightArmCf); setPartCFrame(fighter.leftLeg, leftLegCf); setPartCFrame(fighter.rightLeg, rightLegCf); placeBelt(fighter)
end
local function poseSideControlBottom(fighter, rootPos)
	local root = CFrame.new(rootPos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local torsoCf = root * CFrame.new(0, 1.4, 0) * CFrame.Angles(math.rad(8), 0, math.rad(6))
	local headCf = torsoCf * CFrame.new(0, 0.95, -1.15) * CFrame.Angles(math.rad(-10), math.rad(-8), 0)
	local leftArmCf = torsoCf * CFrame.new(-1.45, 0.05, -0.25) * CFrame.Angles(math.rad(-28), math.rad(10), math.rad(72))
	local rightArmCf = torsoCf * CFrame.new(1.35, -0.2, -0.45) * CFrame.Angles(math.rad(10), math.rad(-8), math.rad(82))
	local leftLegCf = torsoCf * CFrame.new(-0.8, -0.95, 1.55) * CFrame.Angles(math.rad(18), math.rad(-10), math.rad(6))
	local rightLegCf = torsoCf * CFrame.new(0.75, -1.0, 1.5) * CFrame.Angles(math.rad(6), math.rad(8), math.rad(-8))
	setPartCFrame(fighter.torso, torsoCf); setPartCFrame(fighter.head, headCf); setPartCFrame(fighter.leftArm, leftArmCf); setPartCFrame(fighter.rightArm, rightArmCf); setPartCFrame(fighter.leftLeg, leftLegCf); setPartCFrame(fighter.rightLeg, rightLegCf); placeBelt(fighter)
end
local function poseSideControlTop(fighter, rootPos)
	local root = CFrame.new(rootPos + Vector3.new(0, 0.35, 0.15)) * CFrame.Angles(0, math.rad(90), 0)
	local torsoCf = root * CFrame.new(0, 2.9, -0.2) * CFrame.Angles(math.rad(12), 0, math.rad(-4))
	local headCf = torsoCf * CFrame.new(0, 1.45, -0.55) * CFrame.Angles(math.rad(4), math.rad(-6), 0)
	local leftArmCf = torsoCf * CFrame.new(-1.6, -0.3, 0.9) * CFrame.Angles(math.rad(58), math.rad(6), math.rad(12))
	local rightArmCf = torsoCf * CFrame.new(1.55, -0.55, 0.35) * CFrame.Angles(math.rad(28), math.rad(-8), math.rad(-10))
	local leftLegCf = torsoCf * CFrame.new(-0.8, -1.45, 1.95) * CFrame.Angles(math.rad(88), 0, math.rad(4))
	local rightLegCf = torsoCf * CFrame.new(0.8, -1.45, 1.65) * CFrame.Angles(math.rad(88), 0, math.rad(-4))
	setPartCFrame(fighter.torso, torsoCf); setPartCFrame(fighter.head, headCf); setPartCFrame(fighter.leftArm, leftArmCf); setPartCFrame(fighter.rightArm, rightArmCf); setPartCFrame(fighter.leftLeg, leftLegCf); setPartCFrame(fighter.rightLeg, rightLegCf); placeBelt(fighter)
end
local function poseMountBottom(fighter, rootPos, mountPressure, escapeProgress)
	mountPressure = mountPressure or 0; escapeProgress = escapeProgress or 0
	local flatten = mountPressure * 0.18; local turn = escapeProgress * 0.14; local hipShift = escapeProgress * 0.24
	local root = CFrame.new(rootPos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local torsoCf = root * CFrame.new(hipShift, 1.45 - flatten, 0) * CFrame.Angles(math.rad(turn * 24), 0, math.rad(turn * 8))
	local headCf = torsoCf * CFrame.new(-hipShift * 0.08, 0.78 + flatten * 0.1, -1.42 + turn * 0.16) * CFrame.Angles(math.rad(-10 + flatten * 8), math.rad(-20 + turn * 28), math.rad(-8 + turn * 14))
	local leftArmCf = torsoCf * CFrame.new(-1.55 + hipShift * 0.3, -0.1 - flatten * 0.2, -0.05) * CFrame.Angles(math.rad(-6 + turn * 18), math.rad(20), math.rad(88))
	local rightArmCf = torsoCf * CFrame.new(1.55 + hipShift * 0.3, -0.1 - flatten * 0.2, -0.05) * CFrame.Angles(math.rad(6 - turn * 18), math.rad(-20), math.rad(92))
	local leftLegCf = torsoCf * CFrame.new(-0.95 + hipShift * 0.8, -1.15, 1.95) * CFrame.Angles(math.rad(14 + turn * 10), math.rad(-4), math.rad(6))
	local rightLegCf = torsoCf * CFrame.new(0.95 + hipShift * 0.8, -1.15, 1.95) * CFrame.Angles(math.rad(-10 + turn * 10), math.rad(4), math.rad(-6))
	setPartCFrame(fighter.torso, torsoCf); setPartCFrame(fighter.head, headCf); setPartCFrame(fighter.leftArm, leftArmCf); setPartCFrame(fighter.rightArm, rightArmCf); setPartCFrame(fighter.leftLeg, leftLegCf); setPartCFrame(fighter.rightLeg, rightLegCf); placeBelt(fighter)
end
local function poseMountTop(fighter, rootPos, mountPressure, escapeProgress)
	mountPressure = mountPressure or 0; escapeProgress = escapeProgress or 0
	local upright = mountPressure * 0.2; local destabilized = escapeProgress * 0.12
	local root = CFrame.new(rootPos)
	local torsoCf = root * CFrame.new(destabilized * 0.7, 4.1 + upright - (destabilized * 0.5), 0.15) * CFrame.Angles(math.rad(3 - upright * 10 + (destabilized * 16)), 0, math.rad(destabilized * 6))
	local headCf = torsoCf * CFrame.new(0, 1.45 + upright * 0.35, -0.1 + upright * 0.15) * CFrame.Angles(math.rad(2 - upright * 4), math.rad(destabilized * 8), 0)
	local leftArmCf = torsoCf * CFrame.new(-1.6 + destabilized * 0.35, -0.55 + upright * 0.25, -0.2) * CFrame.Angles(math.rad(35 - upright * 8 + destabilized * 18), 0, math.rad(12))
	local rightArmCf = torsoCf * CFrame.new(1.6 + destabilized * 0.35, -0.55 + upright * 0.25, -0.2) * CFrame.Angles(math.rad(35 - upright * 8 + destabilized * 18), 0, math.rad(-12))
	local leftLegCf = torsoCf * CFrame.new(-1.65 + destabilized * 0.45, -2.6, 0.3) * CFrame.Angles(math.rad(90), 0, math.rad(24 - (escapeProgress * 5)))
	local rightLegCf = torsoCf * CFrame.new(1.65 + destabilized * 0.45, -2.6, 0.3) * CFrame.Angles(math.rad(90), 0, math.rad(-24 + (escapeProgress * 5)))
	setPartCFrame(fighter.torso, torsoCf); setPartCFrame(fighter.head, headCf); setPartCFrame(fighter.leftArm, leftArmCf); setPartCFrame(fighter.rightArm, rightArmCf); setPartCFrame(fighter.leftLeg, leftLegCf); setPartCFrame(fighter.rightLeg, rightLegCf); placeBelt(fighter)
end

local function applyTopBottomPose(gameState, topFighter, bottomFighter)
	if gameState.position == "Closed Guard" then
		local _profile = getClosedGuardBottomExpressionProfile(gameState)
		poseClosedGuardBottom(bottomFighter, Vector3.new(-0.1, 0.2, -0.2))
		poseClosedGuardTop(topFighter, Vector3.new(0.1, 1.35, 1.2))
	elseif gameState.position == "Side Control" then
		poseSideControlBottom(bottomFighter, Vector3.new(0, 0.6, 0)); poseSideControlTop(topFighter, Vector3.new(0, 0.6, 0))
	elseif gameState.position == "Mount" then
		poseMountBottom(bottomFighter, Vector3.new(0, 0.6, 0), gameState.mountPressure, gameState.escapeProgress)
		poseMountTop(topFighter, Vector3.new(0, 0.6, 0), gameState.mountPressure, gameState.escapeProgress)
	end
end

local function applyPositionPose(gameState, scene)
	if gameState.position == "Standing" then
		poseStanding(scene.playerFighter, Vector3.new(-3, 0, 0), 90); poseStanding(scene.cpuFighter, Vector3.new(3, 0, 0), -90); return
	end
	if gameState.playerRole == "Top" and gameState.cpuRole == "Bottom" then
		applyTopBottomPose(gameState, scene.playerFighter, scene.cpuFighter)
	elseif gameState.playerRole == "Bottom" and gameState.cpuRole == "Top" then
		applyTopBottomPose(gameState, scene.cpuFighter, scene.playerFighter)
	else
		poseStanding(scene.playerFighter, Vector3.new(-3, 0, 0), 90); poseStanding(scene.cpuFighter, Vector3.new(3, 0, 0), -90)
	end
end

local function applyReactionOffsets(fighter, reaction)
	if not reaction or reaction == 0 then return end
	local lift = math.abs(reaction) * 0.1; local lean = reaction * 0.12
	setPartCFrame(fighter.torso, fighter.torso.CFrame * CFrame.new(0, lift, -lean) * CFrame.Angles(math.rad(-reaction * 5), 0, 0))
	setPartCFrame(fighter.head, fighter.head.CFrame * CFrame.new(0, lift * 0.45, -lean * 0.6))
	setPartCFrame(fighter.leftArm, fighter.leftArm.CFrame * CFrame.Angles(math.rad(reaction * 5), 0, 0))
	setPartCFrame(fighter.rightArm, fighter.rightArm.CFrame * CFrame.Angles(math.rad(reaction * 5), 0, 0))
	placeBelt(fighter)
end

local function styleFighterByRole(gameState, fighter, role, isPlayer)
	local targetColor = ROLE_COLORS[role] or ROLE_COLORS.Neutral
	local pulse = role == "Top" and gameState.visualPulse.top or gameState.visualPulse.bottom
	local roleMix = 0.2 + (pulse * 0.05)
	local armLegColor = fighter.baseColor:Lerp(targetColor, roleMix)
	fighter.torso.Color = fighter.baseColor:Lerp(targetColor, 0.3 + (pulse * 0.05)); fighter.hips.Color = fighter.baseColor:Lerp(targetColor, 0.24 + (pulse * 0.04)); fighter.shoulders.Color = fighter.baseColor:Lerp(targetColor, 0.28 + (pulse * 0.05))
	fighter.leftArm.Color = armLegColor; fighter.rightArm.Color = armLegColor; fighter.leftLeg.Color = armLegColor; fighter.rightLeg.Color = armLegColor
	fighter.leftForearm.Color = armLegColor:Lerp(Color3.fromRGB(245, 245, 245), 0.05 + pulse * 0.08); fighter.rightForearm.Color = fighter.leftForearm.Color; fighter.leftShin.Color = armLegColor; fighter.rightShin.Color = armLegColor
	fighter.chestPlate.Color = fighter.baseColor:Lerp(targetColor, 0.34 + (pulse * 0.07))
	fighter.topMarker.Transparency = role == "Top" and 0.05 or 0.8; fighter.bottomMarker.Transparency = role == "Bottom" and 0.08 or 0.82
	fighter.topMarker.Color = ROLE_COLORS.Top; fighter.bottomMarker.Color = ROLE_COLORS.Bottom
	local roleBillboard = fighter.head:FindFirstChild("RoleBillboard")
	if roleBillboard and roleBillboard:FindFirstChild("RoleText") then
		local identityText = isPlayer and "YOU" or "CPU"; local roleText = roleBillboard.RoleText
		if role == "Top" then roleBillboard.StudsOffset = Vector3.new(0.45, 2.85, 0) elseif role == "Bottom" then roleBillboard.StudsOffset = Vector3.new(-0.45, 1.85, 0) else roleBillboard.StudsOffset = Vector3.new(0, 2.2, 0) end
		roleText.Text = string.upper(identityText .. " * " .. role)
		roleText.BackgroundColor3 = isPlayer and Color3.fromRGB(40, 115, 235) or fighter.baseColor:Lerp(targetColor, 0.55)
		roleText.TextColor3 = Color3.fromRGB(235, 238, 245)
		roleText.TextStrokeTransparency = isPlayer and 0.15 or 0.55
		roleText.TextStrokeColor3 = Color3.fromRGB(10, 14, 22)
		roleText.BackgroundTransparency = isPlayer and 0.05 or 0.2
	end
end

local function getFighterBasis(fighter)
	if not fighter or not fighter.torso or not fighter.head then return nil end
	return { torsoPos = fighter.torso.Position, headPos = fighter.head.Position, forward = fighter.torso.CFrame.LookVector, right = fighter.torso.CFrame.RightVector, up = fighter.torso.CFrame.UpVector }
end

local function makePlayerCameraTarget(gameState, scene)
	local basis = getFighterBasis(scene.playerFighter); local opponentBasis = getFighterBasis(scene.cpuFighter)
	if not basis or not opponentBasis then return { focus = Vector3.new(0, 4, 0), offset = Vector3.new(0, 7, 12) } end
	if gameState.position == "Standing" then return { focus = opponentBasis.headPos + Vector3.new(0, -0.4, 0), eye = basis.headPos + (basis.right * 1.2) + Vector3.new(0, 1.8, 8.5) } end
	if gameState.playerRole == "Top" then return { focus = opponentBasis.headPos + Vector3.new(0, 0.2, 0), eye = basis.headPos + (basis.right * 2.2) + Vector3.new(0, 2.2, 6.0) } end
	local headMid = (basis.headPos + opponentBasis.headPos) * 0.5
	local toOpponent = opponentBasis.headPos - basis.headPos
	local flatBack = Vector3.new(-toOpponent.X, 0, -toOpponent.Z); if flatBack.Magnitude < 0.001 then flatBack = Vector3.new(0, 0, 1) else flatBack = flatBack.Unit end
	local side = Vector3.new(-flatBack.Z, 0, flatBack.X)
	local pressureLean, pressureLift = 0, 0
	if gameState.position == "Mount" then local bridgeBias = gameState.bridgePressure or 0; local shrimpBias = gameState.shrimpPressure or 0; pressureLean = (shrimpBias - bridgeBias * 0.25) * 0.45; pressureLift = bridgeBias * 0.25 end
	local eye = basis.headPos + Vector3.new(0, 0.35 + pressureLift, 0) + (flatBack * (3.0 - pressureLift * 0.35)) + (side * (0.35 + pressureLean))
	return { focus = Vector3.new(headMid.X, headMid.Y - 0.2, headMid.Z), eye = eye }
end

local function getCameraTargetForState(gameState, scene)
	if scene.cameraMode == "Coach" then
		if gameState.position == "Standing" then return { focus = Vector3.new(0, 4.2, 0), offset = Vector3.new(0, 12.5, 22) }
		elseif gameState.position == "Closed Guard" then return { focus = Vector3.new(0, 3.1, 0.15), offset = Vector3.new(0, 11.5, 19.5) }
		elseif gameState.position == "Mount" then return { focus = Vector3.new(0, 3.2, 0.1), offset = Vector3.new(0, 11.8, 19) }
		elseif gameState.position == "Side Control" then return { focus = Vector3.new(0, 3.0, 0.0), offset = Vector3.new(0, 11.3, 18.5) }
		else return { focus = Vector3.new(0, 3.5, 0), offset = Vector3.new(0, 12, 20) } end
	end
	return makePlayerCameraTarget(gameState, scene)
end

local function clampCameraEye(eye, focus)
	if eye.Y < 8 then eye = Vector3.new(eye.X, 8, eye.Z) end
	local toEye = eye - focus
	if toEye.Magnitude < 4 then
		if toEye.Magnitude < 0.001 then toEye = Vector3.new(0, 1, 0) else toEye = toEye.Unit end
		eye = focus + (toEye * 4)
	end
	return eye
end

local function updateCamera(gameState, scene)
	local camera = workspace.CurrentCamera
	if not camera then return end
	camera.CameraType = Enum.CameraType.Scriptable
	local target = getCameraTargetForState(gameState, scene)
	local focus = target.focus
	local eye = target.eye and clampCameraEye(target.eye, focus) or clampCameraEye(focus + target.offset, focus)
	local desired = CFrame.lookAt(eye, focus)
	if not scene.cameraState.currentCFrame then scene.cameraState.currentCFrame = desired else scene.cameraState.currentCFrame = scene.cameraState.currentCFrame:Lerp(desired, 0.10) end
	camera.CFrame = scene.cameraState.currentCFrame
end

function Poses.toggleCameraMode(scene)
	scene.cameraMode = scene.cameraMode == "Player" and "Coach" or "Player"
	scene.cameraState.currentCFrame = nil
	print("Camera mode:", scene.cameraMode)
end

function Poses.hideCharacter(character)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then descendant.Transparency = CHARACTER_HIDE_TRANSPARENCY; descendant.CastShadow = false
		elseif descendant:IsA("Decal") then descendant.Transparency = 1
		elseif descendant:IsA("BillboardGui") then descendant.Enabled = false end
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None; humanoid.CameraOffset = Vector3.new(0, 0, 0) end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then rootPart.CFrame = CFrame.new(0, 6, 27) * CFrame.Angles(0, math.rad(180), 0) end
end

function Poses.bootstrapScene()
	local scene = { sceneRefs = {}, cameraMode = "Player", cameraState = { currentCFrame = nil } }
	ensureMat(); ensureDojoEnvironment(scene.sceneRefs)
	scene.playerFighter = createSimpleFighter("PlayerFighter", Color3.fromRGB(40, 90, 210))
	scene.cpuFighter = createSimpleFighter("CpuFighter", Color3.fromRGB(210, 70, 70))
	return scene
end

function Poses.renderScene(gameState, scene)
	styleFighterByRole(gameState, scene.playerFighter, gameState.playerRole, true)
	styleFighterByRole(gameState, scene.cpuFighter, gameState.cpuRole, false)
	applyPositionPose(gameState, scene)
	applyReactionOffsets(scene.playerFighter, gameState.playerReaction)
	applyReactionOffsets(scene.cpuFighter, gameState.cpuReaction)
	updateCamera(gameState, scene)
	gameState.playerReaction *= 0.55
	gameState.cpuReaction *= 0.55
	gameState.visualPulse.top *= 0.72
	gameState.visualPulse.bottom *= 0.72
end

return Poses
