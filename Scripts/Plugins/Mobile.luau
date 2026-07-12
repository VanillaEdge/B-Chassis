-- MobileScript.lua

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
local vehicleContext = script.Parent.Parent.VehicleContext :: InputContext

local car = script.Parent.Parent.Car.Value :: Model
local seat = car.DriveSeat :: VehicleSeat
local tune = require(car["A-Chassis Tune"]) 

local throttleActionBinding = vehicleContext.ThrottleAction.ScriptableBinding :: InputBinding
local brakeActionBinding = vehicleContext.BrakeAction.ScriptableBinding :: InputBinding
local steerActionBinding = vehicleContext.SteerAction.ScriptableBinding :: InputBinding

local defaultShiftVersion = tune.AutoShiftVers

GuiService.TouchControlsEnabled = false
player.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor

-- Visibility
local function onPreferredInputChanged()
	local preferredInput = UserInputService.PreferredInput
	if preferredInput == Enum.PreferredInput.Touch then
		script.Parent.Visible = true
		tune.AutoShiftVers = "Old"
	else
		script.Parent.Visible = false
		tune.AutoShiftVers = defaultShiftVersion
	end
end

UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(onPreferredInputChanged)
onPreferredInputChanged()

-- Jump
script.Parent.Jump.Activated:Connect(function()
	humanoid.Sit = false
end)

seat:GetPropertyChangedSignal("Occupant"):Connect(function()
	GuiService.TouchControlsEnabled = true
	tune.AutoShiftVers = defaultShiftVersion
end)

-- Throttle
script.Parent.Throttle.InputBegan:Connect(function()
	throttleActionBinding:Fire(1)
end)

script.Parent.Throttle.InputEnded:Connect(function()
	throttleActionBinding:Fire(0)
end)

-- Brake
script.Parent.Brake.InputBegan:Connect(function()
	brakeActionBinding:Fire(1)
end)

script.Parent.Brake.InputEnded:Connect(function()
	brakeActionBinding:Fire(0)
end)

-- Steering
script.Parent.Left.InputBegan:Connect(function()
	steerActionBinding:Fire(-1)
end)

script.Parent.Left.InputEnded:Connect(function()
	steerActionBinding:Fire(0)
end)

script.Parent.Right.InputBegan:Connect(function()
	steerActionBinding:Fire(1)
end)

script.Parent.Right.InputEnded:Connect(function()
	steerActionBinding:Fire(0)
end)
