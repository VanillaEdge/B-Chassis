-- SpeedScript.lua

local velocityValue = script.Parent.Parent.Values.Velocity :: Vector3Value
local speedTextLabel = script.Parent.Speed

local STUD_TO_METERS = 0.28
local MPS_TO_KMH = 3.6

local function onVelocityChanged()
	local speedStudsPerSecond = velocityValue.Value.Magnitude
	local speedKmh = speedStudsPerSecond * STUD_TO_METERS * MPS_TO_KMH
	
	speedTextLabel.Text = tostring(math.floor(speedKmh))
end

velocityValue:GetPropertyChangedSignal("Value"):Connect(onVelocityChanged)

onVelocityChanged()
