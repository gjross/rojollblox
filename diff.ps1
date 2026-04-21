$path = "src/main.client.lua"
$text = Get-Content $path -Raw

function Replace-FunctionBlock {
	param(
		[string]$Source,
		[string]$StartMarker,
		[string]$NextMarker,
		[string]$Replacement
	)

	$start = $Source.IndexOf($StartMarker)
	if ($start -lt 0) {
		throw "Start marker not found: $StartMarker"
	}

	$next = $Source.IndexOf($NextMarker, $start)
	if ($next -lt 0) {
		throw "Next marker not found after $StartMarker : $NextMarker"
	}

	return $Source.Substring(0, $start) + $Replacement.TrimEnd() + "`r`n`r`n" + $Source.Substring($next)
}

$newPoseSideControlBottom = @'
local function poseSideControlBottom(fighter, rootPos)
	-- Side-control bottom root is rolled to keep the fighter on their side.
	local root = CFrame.new(rootPos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local torsoCf = root
		* CFrame.new(0, 1.4, 0)
		* CFrame.Angles(math.rad(8), 0, math.rad(6))

	local headCf = torsoCf
		* CFrame.new(0, 0.95, -1.15)
		* CFrame.Angles(math.rad(-10), math.rad(-8), 0)

	local leftArmCf = torsoCf
		* CFrame.new(-1.45, 0.05, -0.25)
		* CFrame.Angles(math.rad(-28), math.rad(10), math.rad(72))

	local rightArmCf = torsoCf
		* CFrame.new(1.35, -0.2, -0.45)
		* CFrame.Angles(math.rad(10), math.rad(-8), math.rad(82))

	local leftLegCf = torsoCf
		* CFrame.new(-0.8, -0.95, 1.55)
		* CFrame.Angles(math.rad(18), math.rad(-10), math.rad(6))

	local rightLegCf = torsoCf
		* CFrame.new(0.75, -1.0, 1.5)
		* CFrame.Angles(math.rad(6), math.rad(8), math.rad(-8))

	setPartCFrame(fighter.torso, torsoCf)
	setPartCFrame(fighter.head, headCf)
	setPartCFrame(fighter.leftArm, leftArmCf)
	setPartCFrame(fighter.rightArm, rightArmCf)
	setPartCFrame(fighter.leftLeg, leftLegCf)
	setPartCFrame(fighter.rightLeg, rightLegCf)
	placeBelt(fighter)
end
'@

$newPoseSideControlTop = @'
local function poseSideControlTop(fighter, rootPos)
	local root = CFrame.new(rootPos + Vector3.new(0, 0.35, 0.15)) * CFrame.Angles(0, math.rad(90), 0)
	local torsoCf = root
		* CFrame.new(0, 2.9, -0.2)
		* CFrame.Angles(math.rad(12), 0, math.rad(-4))

	local headCf = torsoCf
		* CFrame.new(0, 1.45, -0.55)
		* CFrame.Angles(math.rad(4), math.rad(-6), 0)

	local leftArmCf = torsoCf
		* CFrame.new(-1.6, -0.3, 0.9)
		* CFrame.Angles(math.rad(58), math.rad(6), math.rad(12))

	local rightArmCf = torsoCf
		* CFrame.new(1.55, -0.55, 0.35)
		* CFrame.Angles(math.rad(28), math.rad(-8), math.rad(-10))

	local leftLegCf = torsoCf
		* CFrame.new(-0.8, -1.45, 1.95)
		* CFrame.Angles(math.rad(88), 0, math.rad(4))

	local rightLegCf = torsoCf
		* CFrame.new(0.8, -1.45, 1.65)
		* CFrame.Angles(math.rad(88), 0, math.rad(-4))

	setPartCFrame(fighter.torso, torsoCf)
	setPartCFrame(fighter.head, headCf)
	setPartCFrame(fighter.leftArm, leftArmCf)
	setPartCFrame(fighter.rightArm, rightArmCf)
	setPartCFrame(fighter.leftLeg, leftLegCf)
	setPartCFrame(fighter.rightLeg, rightLegCf)
	placeBelt(fighter)
end
'@

$newPoseMountBottom = @'
local function poseMountBottom(fighter, rootPos, mountPressure, escapeProgress)
	mountPressure = mountPressure or 0
	escapeProgress = escapeProgress or 0
	local flatten = mountPressure * 0.18
	local turn = escapeProgress * 0.14
	local hipShift = escapeProgress * 0.24

	-- Mount bottom root is rolled to keep the torso pinned to the mat plane.
	local root = CFrame.new(rootPos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	local torsoCf = root
		* CFrame.new(hipShift, 1.45 - flatten, 0)
		* CFrame.Angles(math.rad(turn * 24), 0, math.rad(turn * 8))

	local headCf = torsoCf
		* CFrame.new(-hipShift * 0.08, 0.78 + flatten * 0.1, -1.42 + turn * 0.16)
		* CFrame.Angles(math.rad(-10 + flatten * 8), math.rad(-20 + turn * 28), math.rad(-8 + turn * 14))

	local leftArmCf = torsoCf
		* CFrame.new(-1.55 + hipShift * 0.3, -0.1 - flatten * 0.2, -0.05)
		* CFrame.Angles(math.rad(-6 + turn * 18), math.rad(20), math.rad(88))

	local rightArmCf = torsoCf
		* CFrame.new(1.55 + hipShift * 0.3, -0.1 - flatten * 0.2, -0.05)
		* CFrame.Angles(math.rad(6 - turn * 18), math.rad(-20), math.rad(92))

	local leftLegCf = torsoCf
		* CFrame.new(-0.95 + hipShift * 0.8, -1.15, 1.95)
		* CFrame.Angles(math.rad(14 + turn * 10), math.rad(-4), math.rad(6))

	local rightLegCf = torsoCf
		* CFrame.new(0.95 + hipShift * 0.8, -1.15, 1.95)
		* CFrame.Angles(math.rad(-10 + turn * 10), math.rad(4), math.rad(-6))

	setPartCFrame(fighter.torso, torsoCf)
	setPartCFrame(fighter.head, headCf)
	setPartCFrame(fighter.leftArm, leftArmCf)
	setPartCFrame(fighter.rightArm, rightArmCf)
	setPartCFrame(fighter.leftLeg, leftLegCf)
	setPartCFrame(fighter.rightLeg, rightLegCf)
	placeBelt(fighter)
end
'@

$newPoseMountTop = @'
local function poseMountTop(fighter, rootPos, mountPressure, escapeProgress)
	mountPressure = mountPressure or 0
	escapeProgress = escapeProgress or 0
	local upright = mountPressure * 0.2
	local destabilized = escapeProgress * 0.12

	local root = CFrame.new(rootPos)
	local torsoCf = root
		* CFrame.new(destabilized * 0.7, 4.1 + upright - (destabilized * 0.5), 0.15)
		* CFrame.Angles(math.rad(3 - upright * 10 + (destabilized * 16)), 0, math.rad(destabilized * 6))

	local headCf = torsoCf
		* CFrame.new(0, 1.45 + upright * 0.35, -0.1 + upright * 0.15)
		* CFrame.Angles(math.rad(2 - upright * 4), math.rad(destabilized * 8), 0)

	local leftArmCf = torsoCf
		* CFrame.new(-1.6 + destabilized * 0.35, -0.55 + upright * 0.25, -0.2)
		* CFrame.Angles(math.rad(35 - upright * 8 + destabilized * 18), 0, math.rad(12))

	local rightArmCf = torsoCf
		* CFrame.new(1.6 + destabilized * 0.35, -0.55 + upright * 0.25, -0.2)
		* CFrame.Angles(math.rad(35 - upright * 8 + destabilized * 18), 0, math.rad(-12))

	local leftLegCf = torsoCf
		* CFrame.new(-1.65 + destabilized * 0.45, -2.6, 0.3)
		* CFrame.Angles(math.rad(90), 0, math.rad(24 - (escapeProgress * 5)))

	local rightLegCf = torsoCf
		* CFrame.new(1.65 + destabilized * 0.45, -2.6, 0.3)
		* CFrame.Angles(math.rad(90), 0, math.rad(-24 + (escapeProgress * 5)))

	setPartCFrame(fighter.torso, torsoCf)
	setPartCFrame(fighter.head, headCf)
	setPartCFrame(fighter.leftArm, leftArmCf)
	setPartCFrame(fighter.rightArm, rightArmCf)
	setPartCFrame(fighter.leftLeg, leftLegCf)
	setPartCFrame(fighter.rightLeg, rightLegCf)
	placeBelt(fighter)
end
'@

try {
	$text = Replace-FunctionBlock `
		-Source $text `
		-StartMarker "local function poseSideControlBottom(fighter, rootPos)" `
		-NextMarker "local function poseSideControlTop(fighter, rootPos)" `
		-Replacement $newPoseSideControlBottom

	$text = Replace-FunctionBlock `
		-Source $text `
		-StartMarker "local function poseSideControlTop(fighter, rootPos)" `
		-NextMarker "local function poseMountBottom(fighter, rootPos, mountPressure, escapeProgress)" `
		-Replacement $newPoseSideControlTop

	$text = Replace-FunctionBlock `
		-Source $text `
		-StartMarker "local function poseMountBottom(fighter, rootPos, mountPressure, escapeProgress)" `
		-NextMarker "local function poseMountTop(fighter, rootPos, mountPressure, escapeProgress)" `
		-Replacement $newPoseMountBottom

	$text = Replace-FunctionBlock `
		-Source $text `
		-StartMarker "local function poseMountTop(fighter, rootPos, mountPressure, escapeProgress)" `
		-NextMarker "local function applyTopBottomPose(positionName, topFighter, bottomFighter)" `
		-Replacement $newPoseMountTop
}
catch {
	Write-Host $_.Exception.Message
	exit 1
}

Set-Content -Path $path -Value $text -Encoding UTF8
Write-Host "Updated $path"