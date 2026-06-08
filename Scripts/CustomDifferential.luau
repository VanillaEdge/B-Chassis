--[[
	  ____         _____ _                   _     
	 |  _ \       / ____| |                 (_)    
	 | |_) |_____| |    | |__   __ _ ___ ___ _ ___ 
	 |  _ <______| |    | '_ \ / _` / __/ __| / __|
	 | |_) |     | |____| | | | (_| \__ \__ \ \__ \
	 |____/       \_____|_| |_|\__,_|___/___/_|___/
	 
	Version 1
--]]

-- This is the CustomDifferential module.

--[[
	
	This script lets you make custom differential behaviour without editing the Drive.
	Every update, the Drive sends this script wheel data and default diff output.
	
	To enable:
		Place this ModuleScript inside A-Chassis Tune > README
		Name it CustomDifferential
		Set Tune.CustomDifferentialCalculations = true
		
	Example Drive value:
		local _GThrot = env._GThrot
		
	(I added this feature so I could make tank steering 😉)
	
]]

type DifferentialOutput = {
	Power: number,
	Brake: number,
	Torque: number,
	Speed: number,
}

type WheelData = {
	Name: string,
	OppositeWheel: BasePart?,
	
	Size: Vector3,
	Base: Instance ?,
	Arm: Instance ?,
	Steer: HingeConstraint ?,
	SteerAttach0: Attachment ?,
	
	AV: HingeConstraint ?,
	BV: HingeConstraint ?,
	
	isFront: boolean,
	driven: boolean,
	
	WheelSpeedValue: NumberValue,
	TCSTrackerValue: NumberValue,
	ABSTrackerValue: NumberValue,
	ESCTrackerValue: NumberValue,
	
	RotVelocityMagnitude: number,
	WheelVelocityMagnitude: number,
	CanSteer: number,
}

type DifferentialEnv = {
	_GThrot: number,
	_GBrake: number,
	_GSteerC: number,
	_GSteerT: number,
	_CGear: number,
	_spLimit: number,
	_Velocity: Vector3,
	_Config: string,
	
	Wheel: WheelData,
	Default: DifferentialOutput,
}

local differential = {}

differential.run = function(env: DifferentialEnv, dt: number): DifferentialOutput
	-- This gets called once per driven wheel
	
	local output = env.Default
	
	local _GThrot = env._GThrot
	local _GBrake = env._GBrake
	local _CGear = env._CGear
	
	output.Power = _GThrot
	output.Brake = _GBrake
	output.Torque = 1 -- normal torque multiplier
	output.Speed = math.sign(_CGear)
	
	return output
end

return differential
