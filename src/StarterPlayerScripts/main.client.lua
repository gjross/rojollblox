local Players = game:GetService("Players")

local State = require(script.Parent.state)
local Poses = require(script.Parent.poses)
local UI = require(script.Parent.ui)
local Input = require(script.Parent.input)

math.randomseed(tick())
print("ROJO WORKS")

local localPlayer = Players.LocalPlayer
local gameState = State.newGameState()
local scene = Poses.bootstrapScene()
local guiRefs
local inputController

local function getChannelStateName(channel, positionName, playerRole)
	return State.getChannelStateName(gameState, channel, positionName, playerRole)
end

local function render()
	if inputController then
		inputController.postRender()
	end
	UI.render(guiRefs, gameState, getChannelStateName)
	Poses.renderScene(gameState, scene)
end

local function runPlayerAction(actionName)
	State.runPlayerAction(gameState, actionName)
	render()
end

local function bootstrapLocal()
	if localPlayer.Character then
		Poses.hideCharacter(localPlayer.Character)
	end
	localPlayer.CharacterAdded:Connect(Poses.hideCharacter)

	guiRefs = UI.createGuiForPlayer(localPlayer)
	inputController = Input.new({
		gameState = gameState,
		getChannelStateName = getChannelStateName,
		cycleChannel = function(channel)
			State.cycleChannel(gameState, channel)
		end,
		runAction = runPlayerAction,
		render = render,
		toggleCameraMode = function()
			Poses.toggleCameraMode(scene)
		end
	})

	inputController.initialize()
	render()
	inputController.bind()
end

bootstrapLocal()