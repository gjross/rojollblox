$path = "src/main.client.lua"
$text = Get-Content $path -Raw

$text = $text.Replace(
@'
local headX = sideOffset * 0.62
	local headY = 1.10 + hipLift * 0.30 + crunchBias * 0.06 - extendBias * 0.04
	local headZ = -2.15 + shoulderCrunch * 0.20 - crunchBias * 0.14 + extendBias * 0.12

	local headPitch = math.rad(-18 + crunchBias * 8 - extendBias * 5)
	local headYaw = math.rad(-10 - expressionProfile.yawOffset * 0.35)
	local headRoll = math.rad(-22 + sideOffset * -10)
'@,
@'
local headX = sideOffset * 0.48
	local headY = 1.24 + hipLift * 0.28 + crunchBias * 0.05 - extendBias * 0.03
	local headZ = -1.82 + shoulderCrunch * 0.12 - crunchBias * 0.08 + extendBias * 0.08

	local headPitch = math.rad(-10 + crunchBias * 5 - extendBias * 3)
	local headYaw = math.rad(-6 - expressionProfile.yawOffset * 0.22)
	local headRoll = math.rad(-10 + sideOffset * -6)
'@
)

Set-Content $path $text
Write-Host "patched $path"