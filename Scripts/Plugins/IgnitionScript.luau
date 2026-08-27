-- IgnitionScript.lua

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local textButton = script.Parent

local isOnValue = script.Parent.Parent.IsOn :: BoolValue
local startingValue = isOnValue.Starting :: BoolValue

local vehicleContext = script.Parent.Parent.VehicleContext :: InputContext
local controllerBinding = vehicleContext.IgnitionAction.GamepadBinding :: InputBinding
local keyboardBinding = vehicleContext.IgnitionAction.KeyboardBinding :: InputBinding
local scriptableBinding = vehicleContext.IgnitionAction.ScriptableBinding :: InputBinding

-- Input type
local function onPreferredInputChanged()
	local text = keyboardBinding.KeyCode.Name
	
	local preferredInput = UserInputService.PreferredInput
	if preferredInput == Enum.PreferredInput.Gamepad then
		text = controllerBinding.KeyCode.Name
	end
	
	textButton.Text = "Hold <i><stroke color='#000000' thickness='2'><font weight='900'>" .. text .. "</font></stroke></i> to turn on."
end

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(onPreferredInputChanged)
onPreferredInputChanged()

-- Visibility
local function onIgnitionChanged()
	textButton.Visible = not isOnValue.Value or startingValue.Value
end

isOnValue:GetPropertyChangedSignal("Value"):Connect(onIgnitionChanged)
startingValue:GetPropertyChangedSignal("Value"):Connect(onIgnitionChanged)
onIgnitionChanged()

-- Button
textButton.MouseButton1Down:Connect(function()
	scriptableBinding:Fire(true)
end)

textButton.MouseButton1Up:Connect(function()
	scriptableBinding:Fire(false)
end)
