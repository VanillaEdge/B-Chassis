--[[
	  ____         _____ _                   _     
	 |  _ \       / ____| |                 (_)    
	 | |_) |_____| |    | |__   __ _ ___ ___ _ ___ 
	 |  _ <______| |    | '_ \ / _` / __/ __| / __|
	 | |_) |     | |____| | | | (_| \__ \__ \ \__ \
	 |____/       \_____|_| |_|\__,_|___/___/_|___/
	 
	Version 1
--]]

-- Dependencies
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local camera = workspace.CurrentCamera :: Camera
local player = Players.LocalPlayer :: Player

local car = script.Parent.Car.Value
local values = script.Parent.Values

local _Tune = require(car["A-Chassis Tune"]) :: { [string]: any }
local Units = require(car["A-Chassis Tune"].README.Units) :: { [string]: number }
local InterfaceValues = car["A-Chassis Tune"]["A-Chassis Interface"].Values

local VehicleContext = ((_Tune.CustomInputContextEnabled and _Tune.CustomInputContexPath) or script.Parent.VehicleContext) :: InputContext
local ThrottleAction = VehicleContext.ThrottleAction :: InputAction
local BrakeAction = VehicleContext.BrakeAction :: InputAction
local SteerAction = VehicleContext.SteerAction :: InputAction
local ViewportAction = VehicleContext.ViewportAction :: InputAction

local ReadMe = car["A-Chassis Tune"].README
local EngineModule = ReadMe:FindFirstChild("CustomEngine") and require(ReadMe:FindFirstChild("CustomEngine")) or nil
local DifferentialModule = ReadMe:FindFirstChild("CustomDifferential") and require(ReadMe:FindFirstChild("CustomDifferential")) or nil

-- Value instances
local Value = {
	Clutch = values.Clutch,
	Gear = values.Gear,
	TransmissionMode = values.TransmissionMode,
	CurrentRatio = values.CurrentRatio,
	RPM = values.RPM,
	Boost = values.Boost,
	BoostTurbo = values.BoostTurbo,
	BoostSuper = values.BoostSuper,
	HpNatural = values.HpNatural,
	HpElectric = values.HpElectric,
	HpTurbo = values.HpTurbo,
	HpSuper = values.HpSuper,
	HpBoosted = values.HpBoosted,
	Horsepower = values.Horsepower,
	TqNatural = values.TqNatural,
	TqElectric = values.TqElectric,
	TqTurbo = values.TqTurbo,
	TqSuper = values.TqSuper,
	TqBoosted = values.TqBoosted,
	Torque = values.Torque,
	Throttle = values.Throttle,
	InputThrottle = values.InputThrottle,
	Brake = values.Brake,
	InputBrake = values.InputBrake,
	SteerC = values.SteerC,
	SteerT = values.SteerT,
	PBrake = values.PBrake,
	Velocity = values.Velocity,
	AverageRotSpeed = values.AverageRotSpeed,
	Acceleration = values.Acceleration,
	Center = values.Center,
	TCS = values.TCS,
	TCSActive = values.TCSActive,
	TCSAmt = values.TCSAmt,
	ABS = values.ABS,
	ABSActive = values.ABSActive,
	ABSAmt = values.ABSAmt,
	ESC = values.ESC,
	ESCActive = values.ESCActive,
	ESCAmt = values.ESCAmt,
	CS = values.CS,
	CSActive = values.CSActive,
	CSAmt = values.CSAmt,
}

local TCSTrackerFolder = values.TCSTracker
local ABSTrackerFolder = values.ABSTracker
local ESCTrackerFolder = values.ESCTracker
local WheelSpeedsFolder = values.WheelSpeeds

-- Connected variables
local GlobalTemperature = workspace:GetAttribute("GlobalTemperature") or 22
workspace:GetAttributeChangedSignal("GlobalTemperature"):Connect(function()
	GlobalTemperature = workspace:GetAttribute("GlobalTemperature") or 22
end)

local _IsOn = _Tune.AutoStart and (_Tune.Engine or _Tune.Electric)
local IsOnValue = script.Parent.IsOn
IsOnValue.Value = _IsOn
IsOnValue.Changed:Connect(function(value)
	_IsOn = value
end)

local _Starting = false
local StartingValue = IsOnValue.Starting
StartingValue.Value = _Starting
StartingValue.Changed:Connect(function(value)
	_Starting = value
end)

local _AutoClutch = true
local AutoClutchValue = values.AutoClutch
AutoClutchValue.Value = _AutoClutch
AutoClutchValue.Changed:Connect(function(value)
	_AutoClutch = value
end)

local _MSteer = false
local MouseSteerValue = values.MouseSteerOn
MouseSteerValue.Value = _MSteer
MouseSteerValue.Changed:Connect(function(value)
	_MSteer = value
end)

-- Local variables
local ParkingGearEnabled = _Tune.Ratios[1] == 0
local ParkingGearOffset = ParkingGearEnabled and 1 or 0

local _GSteerT = 0
local _GSteerC = 0

local _GThrot = 0
local _InThrot = 0
local _IThrot = 0
local _GBrake = 0
local _InBrake = 0
local _IBrake = 0

local _GClutch = 0
local _ClPressing = false
local _PlayerClutch = false
local _Clutch = 0
local _ClutchKick = 0
local _ClutchModulate = 0

local _RPM = _Tune.AutoStart and _Tune.IdleRPM or 0
local _OutTorque = 0
local _CGear = ParkingGearOffset == 1 and -2 or 0
local _ShiftUp = false
local _ShiftDn = false
local _Shifting = false
local _StallTimer = 0
local _spLimit = 0

local _Boost = 0
local _TBoost = 0
local _SBoost = 0

local _HP = 0
local _TQ = 0
local _NH = 0
local _NT = 0
local _EH = 0
local _ET = 0
local _TH = 0
local _TT = 0
local _SH = 0
local _ST = 0
local _BH = 0
local _BT = 0

local _CurrentRatio = _Tune.Ratios[_CGear + 2 + ParkingGearOffset]
local _CVTRatio = 0
local _FlywheelEnergy = 0

local _TMode = _Tune.TransModes[1]
local _RevLimiting = false
local _RevCutTimer = 0

local _PBrake = car["A-Chassis Tune"]["A-Chassis Interface"].Values.PBrake.Value

local _TCSTracker = {}
local _TCS = _Tune.TCSEnabled and InterfaceValues.TCS.Value or false
local _TCSActive = false
local _TCSAmt = 0

local _ABSTracker = {}
local _ABS = _Tune.ABSEnabled and InterfaceValues.ABS.Value or false
local _ABSActive = false
local _ABSAmt = 0

local _ESCTracker = {}
local _ESC = (_Tune.ESCEnabled and _Tune.TCSEnabled) and InterfaceValues.ESC.Value or false
local _ESCActive = false
local _ESCAmt = 0

local _CS = _Tune.CSEnabled and InterfaceValues.CS.Value or false
local _CSActive = false
local _CSAmt = 0

local _WheelSpeedsTable = {}
local _WheelSpeeds = {}

local _AvgWheelSpeed = 0
local _DriveWheelSpeed = 0
local _MaxWheelSpin = 0

local _OldVelocity = Vector3.new()
local _Acceleration = Vector3.new()
local _Velocity = Vector3.new()
local _Center = CFrame.new()
local _Wheelbase = 1

local _FlipWait = os.clock()
local _FlipActive = false

local weightBrick = car.Body["#Weight"] :: Part
local driveSeat = car.DriveSeat :: VehicleSeat
local flipAlignOrientation = driveSeat.Flip :: AlignOrientation

-- Wheels
local FWheelCount = 0
local RWheelCount = 0

local wDia = 0
local wDRatio = 0

local Wheels = {}
local Drive = {}

for _, v in car.Wheels:GetChildren() :: { BasePart } do
	local name = v.Name
	if not v:IsA("BasePart") or not (name == "FL" or name == "FR" or name == "F" or name == "RL" or name == "RR" or name == "R") then 
		continue 
	end
	
	local av = v:WaitForChild("#AV") :: HingeConstraint
	local bv = v:WaitForChild("#BV") :: HingeConstraint
	
	local base = v:FindFirstChild("Base")
	local arm = v:FindFirstChild("Arm")

	local steer = arm and arm:FindFirstChild("Steer") or nil
	local steerAttach0 = steer and steer.Attachment0 or nil

	FWheelCount += string.find(name, "F") and 1 or 0
	RWheelCount += (not string.find(name, "F")) and 1 or 0

	local isFront = string.find(name, "F") ~= nil
	local driven = ((_Tune.Config == "FWD" or _Tune.Config == "AWD") and isFront) or ((_Tune.Config == "RWD" or _Tune.Config == "AWD") and not isFront)

	local canSteer = 0
	if arm and steer then
		canSteer = v:GetAttribute("SteerDisabled") and 1 or 2
	end

	local WheelSpeedValue = Instance.new("NumberValue", WheelSpeedsFolder)
	WheelSpeedValue.Name = name
	local TCSTrackerValue = Instance.new("NumberValue", TCSTrackerFolder)
	TCSTrackerValue.Name = name
	local ABSTrackerValue = Instance.new("NumberValue", ABSTrackerFolder)
	ABSTrackerValue.Name = name
	local ESCTrackerValue = Instance.new("NumberValue", ESCTrackerFolder)
	ESCTrackerValue.Name = name

	local data = {}
	data.Name = name
	data.OppositeWheel = (name == "FL" and car.Wheels:FindFirstChild("FR")) or (name == "FR" and car.Wheels:FindFirstChild("FL")) or (name == "RL" and car.Wheels:FindFirstChild("RR")) or (name == "RR" and car.Wheels:FindFirstChild("RL"))
	data.Size = v.Size
	data.Base = base
	data.Arm = arm
	data.Steer = steer
	data.SteerAttach0 = steerAttach0
	data.AV = av
	data.BV = bv
	data.isFront = isFront
	data.driven = driven
	data.WheelSpeedValue = WheelSpeedValue
	data.TCSTrackerValue = TCSTrackerValue
	data.ABSTrackerValue = ABSTrackerValue
	data.ESCTrackerValue = ESCTrackerValue
	data.RotVelocityMagnitude = 0
	data.WheelVelocityMagnitude = 0
	data.CanSteer = canSteer

	if driven then
		table.insert(Drive, v)
	end

	v:GetPropertyChangedSignal("Size"):Connect(function()
		Wheels[v].Size = v.Size

		local size = 0
		for name, data in Wheels do 
			size = math.max(size, data.Size.Y)
			wDia = size
		end

		wDRatio = wDia * math.pi / 60
	end)

	v:GetAttributeChangedSignal("SteerDisabled"):Connect(function()
		data.CanSteer = v:GetAttribute("SteerDisabled") and 1 or 2
	end)

	Wheels[v] = data
end

for name, data in Wheels do 
	wDia = math.max(wDia, data.Size.Y)
	wDRatio = wDia * math.pi / 60
end

-- Shutdown
driveSeat.ChildRemoved:Connect(function(child: Instance) 
	if child.Name=="SeatWeld" and child:IsA("Weld") then
		-- Remove Flip Force
		flipAlignOrientation.Enabled = false
		_FlipActive = false
		
		-- Save assist states
		InterfaceValues.PBrake.Value = _PBrake
		InterfaceValues.TCS.Value = _TCS
		InterfaceValues.ABS.Value = _ABS
		InterfaceValues.ESC.Value = _ESC
		InterfaceValues.CS.Value = _CS
		
		-- Remove wheel force
		for _, data in Wheels do
			if data.AV then
				data.AV.MotorMaxTorque = 0
				data.AV.AngularVelocity = 0
			end
			if data.BV then
				if ParkingGearEnabled then
					_CGear = -2
				else
					_PBrake = true
				end

				if data.isFront then
					local PBrakeForceF = _Tune.PBrakeForce * 9.80665 * Units.Force_N * _Tune.PBrakeBias
					data.BV.MotorMaxTorque = _Tune.ExitBrake and PBrakeForceF or 0
				else
					local PBrakeForceR = _Tune.PBrakeForce * 9.80665 * Units.Force_N * (1 - _Tune.PBrakeBias)
					data.BV.MotorMaxTorque = _Tune.ExitBrake and PBrakeForceR or 0
				end
			end
		end

		-- Tell server to remove
		car["A-Chassis Tune"].Shutdown:FireServer()
	end
end)

local function SampleCurve(curve: { { number } }, x: number): number
	for i = 2, #curve do
		local a = curve[i - 1]
		local b = curve[i]
		
		if x <= b[1] then
			local t = (x - a[1]) / (b[1] - a[1])
			return a[2] + (b[2] - a[2]) * math.clamp(t, 0, 1)
		end
	end
	
	return curve[#curve][2]
end

local function MoveToward(current: number, target: number, step: number): number
	if current < target then
		return math.min(current + step, target)
	elseif current > target then
		return math.max(current - step, target)
	end
	
	return target
end

local function StepForTime(dt: number, time: number, range: number ?): number
	local span = range or 1
	
	if time <= 0 then
		return span
	end
	
	return span * dt / time
end

-- Steering
local function Steering(dt: number)
	local speed = _Velocity.Magnitude * (Units.Length_mm / 1000) * 3.6
	
	-- Steering Input
	local input = math.clamp(_GSteerT, -1, 1)
	if math.abs(input) > _Tune.SteerDeadzone then
		input = math.sign(input) * SampleCurve(_Tune.SteerInputCurve, math.abs(input))
	else
		input = 0
	end
	
	-- Counter Steering
	_CSAmt = 0
	
	if _CS and speed > _Tune.CSSpeedThresh then
		local sideRatio = _Center:VectorToObjectSpace(_Velocity).X / math.max(_Velocity.Magnitude, 0.001)
		local csSideDeadzone = 0.02
		if math.abs(sideRatio) < csSideDeadzone then
			sideRatio = 0
		end
		
		local desiredCS = math.clamp(sideRatio, -1, 1) * (_Tune.CSAmt / 100)
		local steerLimit = math.max(_Tune.CSSteerThresh / 100, 0.001)
		local inputFade = 1 - math.clamp(math.abs(input) / steerLimit, 0, 1)
		
		_CSAmt = desiredCS * inputFade
		
		if math.abs(_CSAmt) <= ((_Tune.CSAmt / 100) * 0.01) then
			_CSAmt = 0
		end
	end
	
	_CSActive = _CSAmt ~= 0
	
	local target = math.clamp(input + _CSAmt, -1, 1)
	if math.abs(target) < 0.001 then
		target = 0
	end
	
	local returning = math.abs(target) < math.abs(_GSteerC) or target * _GSteerC < 0
	local steerTime = returning and _Tune.ReturnTime or _Tune.SteerTime
	_GSteerC = MoveToward(_GSteerC, target, StepForTime(dt, steerTime))
	
	-- Four Wheel Steering
	local rearScale = 0
	if _Tune.FWSteer ~= "None" then
		local rearSpeed = speed / math.max(_Tune.RSteerSpeed, 0.001)
		if _Tune.FWSteer == "Static" then
			rearScale = -math.max(0, 1 - rearSpeed)
		elseif _Tune.FWSteer == "Speed" then
			rearScale = math.min(1, rearSpeed)
		elseif _Tune.FWSteer == "Both" then
			rearScale = math.clamp(rearSpeed - 1, -1, 1)
		end
	end
	
	-- Apply
	local angleScale = SampleCurve(_Tune.MaxAngleCurve, speed)
	for _, data in Wheels do
		if data.CanSteer == 0 then
			continue
		end
		
		if data.CanSteer ~= 2 then
			data.SteerAttach0.Orientation = Vector3.zero
			continue
		end
		
		local maxAngle = data.isFront and _Tune.MaxSteerAngle or _Tune.RMaxSteerAngle
		local steerScale = data.isFront and 1 or rearScale
		local steerAngle = _GSteerC * maxAngle * angleScale * steerScale
		
		data.SteerAttach0.Orientation = Vector3.new(0, steerAngle, 0)
	end
end

-- Engine
-- Electric Only Setup
if not _Tune.Engine and _Tune.Electric then 
	_Tune.Redline = _Tune.E_Redline 
	_Tune.ShiftRPM = _Tune.E_Redline
	_Tune.Turbochargers = 0
	_Tune.Superchargers = 0
	_Tune.Clutch = false 
	_Tune.IdleRPM = 0 
	_Tune.ClutchType = "Clutch" 
end

-- Automatic Transmission
local function Auto()	
	if not _IsOn then 
		return 
	end
	
	local fFDr = _Tune.FinalDrive * 30 / math.pi
	
	if _Tune.AutoShiftVers == "Old" and (_CGear == 0 or (ParkingGearEnabled and _CGear == -2)) then 
		_ClPressing = false 
		_CGear = 1
	end
	
	if _CGear >= 1 then
		if (_CGear==1 and _InBrake > 0 and _InThrot <= 0 and _Velocity.Magnitude < 5) and _Tune.AutoShiftVers == "Old" then
			_CGear = -1 _ClPressing = false
		elseif _Velocity.Magnitude > 5 and _Tune.ClutchType ~= "CVT" then
			if _Tune.AutoShiftMode == "RPM" then
				if _RPM>(_Tune.ShiftRPM+_Tune.AutoUpThresh) then
					if not _ShiftUp and not _Shifting then _ShiftUp = true end
				elseif math.max(math.min(_MaxWheelSpin*_Tune.Ratios[_CGear+1+ParkingGearOffset]*fFDr,_Tune.Redline+100),0)<(_Tune.ShiftRPM-_Tune.AutoDownThresh) and _CGear>1 then
					if not _ShiftDn and not _Shifting then _ShiftDn = true end 
				end
			else
				if _Velocity.Magnitude > math.ceil(wDRatio*(_Tune.ShiftRPM+_Tune.AutoUpThresh)/_CurrentRatio/_Tune.FinalDrive) then
					if not _ShiftUp and not _Shifting then _ShiftUp = true end
				elseif _Velocity.Magnitude < math.ceil(wDRatio*(_Tune.ShiftRPM-_Tune.AutoDownThresh)/_Tune.Ratios[_CGear+1+ParkingGearOffset]/_Tune.FinalDrive) and _CGear>1 then
					if not _ShiftDn and not _Shifting then _ShiftDn = true end
				end
			end
		end
	else
		if (_InThrot > 0 and _Velocity.Magnitude < 5) and _Tune.AutoShiftVers == "Old" then
			_ClPressing = false
			_CGear = 1
		end
	end
end

local function Gear()
	if _ShiftUp and not _Shifting then
		if (_TMode == "Manual" and not _ClPressing) or (_TMode == "Manual" and _Tune.ClutchRel and (_InThrot > 0)) or _CGear == #_Tune.Ratios - 2 - ParkingGearOffset or (_TMode ~= "Manual" and not _IsOn) then 
			_ShiftUp = false 
			return 
		end
		local NextGear = math.min(_CGear + 3 + ParkingGearOffset, #_Tune.Ratios)
		if _TMode ~= "Manual" and _Tune.ClutchType ~= "CVT" then
			_Shifting = true
			if _CGear > 0 then 
				task.wait(_Tune.ShiftUpTime)
			end
		end
		_ShiftUp = false
		_Shifting = false
		if _TMode ~= "Manual" and not _IsOn then 
			return 
		end
		if NextGear > 3 + ParkingGearOffset and _Tune.ClutchType == "CVT" then return end
		_CGear = math.min(_CGear + 1, #_Tune.Ratios - 2 - ParkingGearOffset)
		if _TMode ~= "Manual" or (_CGear == 1 and _IsOn) then 
			_ClPressing = (_TMode == "Manual" and _PlayerClutch) or false
		end
	end

	if _ShiftDn and not _Shifting then
		if (_TMode == "Manual" and not _ClPressing) or _CGear == -1 - ParkingGearOffset or (_TMode ~= "Manual" and not _IsOn) then 
			_ShiftDn = false 
			return 
		end
		local PrevGear = math.min(_CGear + 1 + ParkingGearOffset, #_Tune.Ratios)
		if _TMode ~= "Manual" then
			_Shifting = true
			if _CGear > 1 then 
				task.wait(_Tune.ShiftDnTime)
			end
		end
		_ShiftDn = false
		_Shifting = false
		if _TMode ~= "Manual" and not _IsOn then 
			return 
		end
		_CGear = math.max(_CGear - 1, _Velocity.Magnitude > 5 and -1 or -2)
		if _TMode ~= "Manual" or (_CGear == -1 and _IsOn) then 
			_ClPressing = (_TMode == "Manual" and _PlayerClutch) or false
		end
	end
end

local goalRPM = 0

-- Power calculation prerequesites
local function f(m: number, n: number, p: number, q: number, M: number, b: number, x: number): number
	return math.clamp(M - ( (q-n)/(b^p-b^m) * (b^x-b^m) + n), 0, M)
end

-- Apply Power
local function Engine(dt: number)
	local deltaTime = dt * 60
	
	local fFDr = _Tune.FinalDrive * 30 / math.pi
	local cGrav = (_Tune.GravComp > 0 and _Tune.GravComp or workspace.Gravity) * _Tune.InclineComp / 35
	
	local _WheelRPM = _DriveWheelSpeed * _CurrentRatio * fFDr
	
	local speedKmh = _Velocity.Magnitude / (Units.Velocity_mdivs / 3.6)
	
	-- Pedal smoothing
	_InThrot = MoveToward(_InThrot, _IThrot, StepForTime(dt, _Tune.ThrotTime))
	_InBrake = MoveToward(_InBrake, _IBrake, StepForTime(dt, _Tune.BrakeTime))
	
	-- CVT
	if _Tune.ClutchType == "CVT" then
		local denom = _DriveWheelSpeed * fFDr
		local targetRPM = _Tune.IdleRPM + (_Tune.CVTRPM - _Tune.IdleRPM) * _GThrot
		if math.abs(denom) > 1e-6 then
			_CVTRatio = math.clamp(targetRPM / denom, _Tune.CVTMinRatio, _Tune.CVTMaxRatio)
		else
			_CVTRatio = _Tune.CVTMaxRatio
		end
	end
	
	-- Update ratio
	_CurrentRatio = _Tune.ClutchType == "CVT" and _CVTRatio or _Tune.Ratios[_CGear+2+ParkingGearOffset]
	_spLimit = _Tune.Redline/(fFDr*_CurrentRatio)
	if _CurrentRatio*fFDr == 0 then
		_spLimit = 0
	end -- Prevents [nan] from dividing by 0
	
	-- Flywheel/clutch-dumping
	_FlywheelEnergy = math.max((_RPM-_WheelRPM)*_Tune.DumpMult,0) * (1-_Clutch) * 1.356*Units.Torque_nm
	
	-- Throttle
	if _Shifting and _ShiftUp then
		_GThrot = 0
	elseif _Shifting and _ShiftDn then
		_GThrot = _Tune.ShiftDnThrottle / 100
	elseif _Tune.AutoShiftVers == "Old" and _CGear == -1 and _TMode == "Auto" then
		_GThrot = _InBrake
	else
		_GThrot = _InThrot
	end
	
	-- Brake
	if (_Tune.AutoShiftVers == "Old" and _CGear==-1 and _TMode=="Auto") then
		_GBrake = _InThrot
	else
		_GBrake = _InBrake
	end
	
	if not _IsOn then
		_StallTimer = 0
		if _AutoClutch then
			_Clutch = 1
		end
		_GThrot = 0
	end
	
	-- Rev limiter
	_RevCutTimer = math.max(_RevCutTimer - dt, 0)
	
	if not _IsOn then
		_RevCutTimer = 0
	elseif _RPM >= _Tune.Redline and _RevCutTimer <= 0 then
		_RevCutTimer = _Tune.RedlineThrottleCutTime or 0.08
	end
	
	_RevLimiting = _RevCutTimer > 0
	
	if _RevLimiting then
		_GThrot = 0
	end
	
	-- Speed limiter
	local limit = (_CGear < 0 and _Tune.ReverseSpeed or _Tune.SpeedLimit)
	if limit > 0 then
		local cut = 1 - math.clamp((speedKmh - (limit - _Tune.SLimitGradient)) / _Tune.SLimitGradient, 0, 1)
		_GThrot = math.min(_GThrot, cut)
		
		if _Tune.SLimitBrake then
			_GBrake = math.max(_GBrake, math.clamp((speedKmh - limit) / _Tune.SLimitGradient, 0, 1))
		end
	end
	
	-- Idler circuit	
	local rpmThrottle = _GThrot
	if _IsOn and _Tune.Engine then
		local idleTarget = _Tune.IdleRPM + (math.random() * 2 - 1) * (_Tune.IdleInstability or 0)
		local idleThrottle = math.clamp((idleTarget - _RPM) / math.max(_Tune.IdleRPM * 0.5, 1), 0, 0.45)
		rpmThrottle = math.max(rpmThrottle, idleThrottle)
	end
	
	if (_Tune.Engine or _Tune.Electric) and not _Starting then 
		goalRPM = math.clamp(_RPM - (_Tune.RevDecay * deltaTime) + (_Tune.RevAccel * rpmThrottle * deltaTime) - (math.clamp(math.max(_RPM - _Tune.IdleRPM, 0) / math.max(_Tune.Redline - _Tune.IdleRPM, 1), 0, 1) * _Tune.RevDecayRPM * deltaTime), 0, _Tune.Redline)
	end
	
	-- Set RPM
	local aRPM = math.max((goalRPM * (1 - deltaTime) + _WheelRPM * deltaTime) * (1 - _Clutch) + goalRPM * _Clutch, 0)
	local clutchP = math.min(math.abs(aRPM - _RPM) / (_Tune.Flywheel * deltaTime), 0.9)
	if _ClPressing then 
		clutchP = 0 
	end
	_RPM = aRPM * (1 - clutchP) + _RPM * clutchP
	
	if _RPM > _Tune.Redline then
		_RPM = _Tune.Redline
	end
	
	-- Clutch
	if _Shifting or (_CGear == 0 or (ParkingGearEnabled and _CGear == -2)) then
		_ClPressing = true
		_Clutch = 1
	end
	
	if _Tune.Clutch then
		if _AutoClutch then
			if _Tune.ClutchType == "Clutch" or _Tune.ClutchType == "CVT" then
				_ClutchKick = _ClPressing and 1 or MoveToward(_ClutchKick, 0, StepForTime(dt, _Tune.ClutchTime))				
				
				local speedInfluence = speedKmh / math.max(_Tune.SpeedEngage, 0.001) -- / math.max(math.abs(_CGear), 1)
				_ClutchModulate = math.clamp(speedInfluence - _ClutchKick, 0, 1)
				
			elseif _Tune.ClutchType == "TorqueConverter" and _Tune.TQLock then
				local offThrottleUnlock = _GThrot <= 0.01 and speedKmh < _Tune.SpeedEngage
				local onThrottleUnlock = _GThrot > 0.01 and _RPM < _Tune.RPMEngage and _WheelRPM < _Tune.RPMEngage
				
				local targetModulate = (offThrottleUnlock or onThrottleUnlock) and 0 or 1
				_ClutchModulate = MoveToward(_ClutchModulate, targetModulate, StepForTime(dt, _Tune.ClutchTime))
				
			elseif _Tune.ClutchType == "TorqueConverter" and not _Tune.TQLock then
				_ClutchModulate = math.min((_RPM / _Tune.Redline) * 0.7, 1)
			end
			
			_Clutch = _ClPressing and 1 or 1 - _ClutchModulate
		else
			_Clutch = _ClPressing and 1 or 0
		end
	else
		_Clutch = (not _ClPressing and not _Shifting) and 0 or 1
	end
	
	if _AutoClutch and (_Starting or _RevLimiting) then
		_Clutch = 1
	end
	
	local canStall = _Tune.Stall and _Tune.Clutch and _Tune.Engine and _IsOn and not _Starting and _Clutch <= 0.01 and _RPM <= _Tune.IdleRPM * 0.25
	if canStall then
		_StallTimer += dt
		if _StallTimer >= 0.2 then
			IsOnValue.Value = false
			_StallTimer = 0
		end
	else
		_StallTimer = 0
	end
	
	-- Torque calculations (Detomiks)
	-- What you see here is mostly just ported over from Desmos.
	if not EngineModule or _Tune.CustomEngineCalculations == false then
		local x = _RPM/1000
		local NTorque = 0
		local ETorque = 0
		local TTorque = 0
		local STorque = 0
		if _Tune.Engine then
			local NIdleTorque = f(_Tune.IdleRPM/1000, _Tune.IdleTorque, _Tune.PeakTorqueRPM/1000, _Tune.PeakTorque, _Tune.PeakTorque, _Tune.IdleTorqueCurve, x)
			local NRedlineTorque = f(_Tune.PeakTorqueRPM/1000, _Tune.PeakTorque, _Tune.Redline/1000, _Tune.RedlineTorque, _Tune.PeakTorque, 1/_Tune.RedlineTorqueCurve, x)
			local VVL = _Tune.VVLTorque > 0 and _Tune.VVLTorque - f(_Tune.VVLRPM/1000, 0, (_Tune.VVLRPM + _Tune.VVLTime)/1000, _Tune.VVLTorque, _Tune.VVLTorque, _Tune.VVLCurve, x) or 0
			local AirPressurePercent = math.exp((-9.80665 * 0.0289644 * (_Center.Y * Units.Length_mm / 1000)) / (8.3142 * (GlobalTemperature + 273.15))) -- look up the barometric formula 
			NTorque = (_Tune.PeakTorque - NIdleTorque - NRedlineTorque + VVL) * AirPressurePercent * (math.clamp(x / (_Tune.IdleRPM / 1000), 0, 1)) -- fix to torque produced when engine off
			_NH, _NT = (NTorque*x)/5.252, NTorque
			
			if _Tune.Turbochargers > 0 then
				local turboMaxBoost = _Tune.Turbochargers * _Tune.T_Boost
				local turboBoostGoal = _Tune.Turbochargers * ((_GThrot ^ 3) * (100 / _Tune.T_Size) * ((NTorque * x) / 5.252) - f(_Tune.IdleRPM / 1000, _Tune.T_IdleBoost, _Tune.T_PeakRPM / 1000, _Tune.T_Boost, (_GThrot ^ 3) * (100 / _Tune.T_Size) * ((NTorque * x) / 5.252), 1 / _Tune.T_Curve, x))
				turboBoostGoal = math.clamp(turboBoostGoal, 0, turboMaxBoost)
				
				local spoolTime = turboBoostGoal > _TBoost and _Tune.T_SpoolUpTime or _Tune.T_SpoolDownTime
				_TBoost = MoveToward(_TBoost, turboBoostGoal, StepForTime(dt, spoolTime, turboMaxBoost))
				
				TTorque = _TBoost * _Tune.T_Efficiency
				_TH, _TT = (TTorque * x) / 5.252, TTorque
			end
			
			if _Tune.Superchargers > 0 then
				local SIdleBoost = f(_Tune.IdleRPM / 1000, _Tune.S_IdleBoost, _Tune.S_PeakRPM / 1000, _Tune.S_Boost, _Tune.S_Boost, _Tune.S_IdleCurve, x)
				local SRedlineBoost = f(_Tune.S_PeakRPM / 1000, _Tune.S_Boost, _Tune.Redline / 1000, _Tune.S_RedlineBoost, _Tune.S_Boost, 1 / _Tune.S_RedlineCurve, x)
				
				local superMaxBoost = _Tune.Superchargers * _Tune.S_Boost
				local superBoostGoal = _Tune.Superchargers * _GThrot * (_Tune.S_Boost - SIdleBoost - SRedlineBoost)
				superBoostGoal = math.clamp(superBoostGoal, 0, superMaxBoost)
				
				_SBoost = MoveToward(_SBoost, superBoostGoal, StepForTime(dt, _Tune.S_ResponseTime, superMaxBoost))
				
				STorque = _SBoost * _Tune.S_Efficiency
				_SH, _ST = (STorque * x) / 5.252, STorque
			end
			
			if _Tune.Turbochargers > 0 or _Tune.Superchargers > 0 then
				_BH, _BT = ((TTorque + STorque) * x) / 5.252, TTorque + STorque
			end
		end
		
		if _Tune.Electric then
			ETorque = 1 * (_Tune.E_Torque - f(_Tune.E_TransitionRPM/1000, _Tune.E_Torque, _Tune.E_Redline/1000, _Tune.E_RedlineTorque, _Tune.E_Torque, _Tune.E_Curve, x))
			_EH, _ET = (ETorque*x)/5.252, ETorque
		end
		
		local minTorque = (_IsOn and _RPM >= _Tune.IdleRPM * 0.75) and _Tune.IdleTorque or 0
		local maxTorque = (_Tune.HPLimit > 0 and _Tune.HPLimit or math.huge) * (5.252 / math.max(x, 0.001))
		
		local TotalTorque = math.clamp(NTorque + ETorque + TTorque + STorque, minTorque, maxTorque)
		_HP, _TQ = (TotalTorque*x)/5.252, TotalTorque
	else
		EngineModule.run({
			-- Manually add environment variables here
			_RPM = _RPM,
			_GThrot = _GThrot,
			_IsOn = _IsOn,
			_CGear = _CGear,

		}, dt)
		
		_Boost = EngineModule._Boost
		_TBoost = EngineModule._TBoost
		_SBoost = EngineModule._SBoost
		
		_HP = EngineModule._HP
		_TQ = EngineModule._TQ
		_NH = EngineModule._NH
		_NT = EngineModule._NT
		_EH = EngineModule._EH
		_ET = EngineModule._ET
		_TH = EngineModule._TH
		_TT = EngineModule._TT
		_SH = EngineModule._SH
		_ST = EngineModule._ST
		_BH = EngineModule._BH
		_BT = EngineModule._BT
	end
	
	-- Starter
	if _Starting then
		IsOnValue.Value = true
		_TQ += _Tune.StarterTorque or 120
	end
	
	-- Exit engine
	_OutTorque = _TQ * _CurrentRatio * _Tune.FinalDrive
	local iComp = (_Center.LookVector.Y)*cGrav*math.sign(_CGear)
	_OutTorque = _OutTorque*math.max(1,(1+iComp))
	
	-- Brakes
	local FBrakeForce =_Tune.BrakeForce * 9.80665 * Units.Force_N * _Tune.BrakeBias -- luaint edit, conversion to SI unit Detomiks
	local RBrakeForce =_Tune.BrakeForce * 9.80665 * Units.Force_N * (1 - _Tune.BrakeBias) -- luaint edit
	local PBrakeForceF = _Tune.PBrakeForce * 9.80665 * Units.Force_N * _Tune.PBrakeBias
	local PBrakeForceR = _Tune.PBrakeForce * 9.80665 * Units.Force_N * (1 - _Tune.PBrakeBias)
	
	-- ESC
	local escTargetWheel = nil
	local escBrake = 0
	
	if _ESC and speedKmh > _Tune.ESCSpeed then
		local speedMps = _Velocity.Magnitude * (Units.Length_mm / 1000)
		local steerAngle = math.rad(_GSteerC * _Tune.MaxSteerAngle * SampleCurve(_Tune.MaxAngleCurve, speedKmh))
		local desiredYaw = (speedMps / math.max(_Wheelbase, 0.001)) * math.tan(steerAngle)
		local actualYaw = weightBrick.CFrame:VectorToObjectSpace(weightBrick.AssemblyAngularVelocity).Y
		
		local maxYaw = 9.80665 / math.max(speedMps, 0.001) -- 1 g limit
		desiredYaw = math.clamp(desiredYaw, -maxYaw, maxYaw)
		
		local yawError = desiredYaw - actualYaw
		local threshold = math.max(_Tune.ESCThreshold, 0.001)
		
		if math.abs(yawError) > threshold then
			local desiredSign = math.sign(desiredYaw)
			local turnSign = desiredSign ~= 0 and desiredSign or math.sign(actualYaw)
			
			if turnSign ~= 0 then
				if desiredSign ~= 0 and math.sign(yawError) == desiredSign then
					escTargetWheel = turnSign > 0 and "RL" or "RR" -- brake the inside rear wheel
				else
					escTargetWheel = turnSign > 0 and "FR" or "FL" -- brake the outside front wheel
				end
				
				local response = math.clamp((math.abs(yawError) - threshold) / threshold, 0, 1)
				escBrake = response * math.clamp(_Tune.ESCBrake / 100, 0, 1)
			end
		end
	end
	
	-- Update Wheels
	for wheel, data in Wheels do
		-- Apply Power
		local PBrakeV = (_PBrake == true or _CGear == -2) and 1 or 0
		local on = _IsOn and 1 or 0
		
		local throt = _GThrot
		local brake = _GBrake
		
		local clutch = 1
		if _ClPressing or (_AutoClutch and _Starting) then
			clutch = 0
		end
		
		-- Apply Differential
		local output = {
			Power = data.driven and throt or 0,
			Brake = brake,
			Torque = 1,
			Speed = data.driven and math.sign(_CGear) or 0,
		}
		
		if data.driven then
			if data.OppositeWheel then
				local power = data.isFront and _Tune.FDiffPower or _Tune.RDiffPower
				local coast = data.isFront and _Tune.FDiffCoast or _Tune.RDiffCoast
				local preload = data.isFront and _Tune.FDiffPreload or _Tune.RDiffPreload
				
				local oppositeSpeed = math.max(data.OppositeWheel.RotVelocity.Magnitude, 0.001)
				local avg = ((data.RotVelocityMagnitude / oppositeSpeed) - 1) * (preload / 10)
				
				output.Torque = math.ceil(math.max(0, math.min(2, 1 - (((power / 100) * avg * output.Power) + ((coast / 100) * avg * (1 - output.Power))))) * 100) / 100
			end
			
			if DifferentialModule and _Tune.CustomDifferentialCalculations ~= false then
				output = DifferentialModule.run({
					_GThrot = output.Power,
					_GBrake = output.Brake,
					_GSteerC = _GSteerC,
					_GSteerT = _GSteerT,
					_CGear = _CGear,
					_spLimit = _spLimit,
					_Velocity = _Velocity,
					_Config = _Tune.Config,
					
					Wheel = data,
					Default = output,
				}, dt)
			end
		end
		
		-- Apply ESC
		local tqESC = 0
		if data.Name == escTargetWheel then
			tqESC = math.min(escBrake, math.max(1 - output.Brake, 0))
			output.Brake += tqESC
		end
		
		_ESCActive = tqESC > 0 or _ESCActive
		_ESCTracker[data.Name] = tqESC
		
		-- Apply ABS
		local tqABS = 1
		if _ABS and output.Brake > 0 then
			tqABS = 1 - (math.min(math.max(0, math.abs(data.RotVelocityMagnitude * (data.Size.Y / 2) / (Units.Velocity_mdivs / 3.6) - data.WheelVelocityMagnitude / (Units.Velocity_mdivs / 3.6)) - _Tune.ABSThreshold) / _Tune.ABSGradient, 1) * (1 - (_Tune.ABSLimit / 100)))
			output.Brake *= tqABS
		end
		
		_ABSActive = tqABS < 1 or _ABSActive
		_ABSTracker[data.Name] = 1 - tqABS
		
		-- Apply TCS
		local tqTCS = 1
		if data.driven and _TCS and output.Power > 0.01 then
			tqTCS = 1 - (math.min(math.max(0, math.abs(data.RotVelocityMagnitude * (data.Size.Y / 2) / (Units.Velocity_mdivs / 3.6) - data.WheelVelocityMagnitude / (Units.Velocity_mdivs / 3.6)) - _Tune.TCSThreshold) / _Tune.TCSGradient, 1) * (1 - (_Tune.TCSLimit / 100)))
			-- This is used when calculating tqOUT
		end
		
		if data.driven then
			_TCSActive = tqTCS < 1 or _TCSActive
			_TCSTracker[data.Name] = 1 - tqTCS
		end
		
		-- Apply Drive
		if data.driven then
			local bias = (_Tune.Config == "AWD" and (_Tune.TorqueVector + 1) / 2) or (_Tune.Config == "FWD" and 0) or 1
			local tq = data.isFront and (_OutTorque * (1 - bias)) / FWheelCount or (_OutTorque * bias) / RWheelCount
			local tqOUT = ((tq * 1.356 * Units.Torque_nm * tqTCS * clutch) + (_FlywheelEnergy / #Drive)) * output.Power * on
			
			data.AV.MotorMaxTorque = tqOUT * output.Torque
			data.AV.AngularVelocity = math.abs(_spLimit) * output.Speed
		else
			data.AV.MotorMaxTorque = 0
			data.AV.AngularVelocity = 0
		end
		
		-- Apply Brakes
		local brakeForce = data.isFront and FBrakeForce or RBrakeForce
		local pBrakeForce = data.isFront and PBrakeForceF or PBrakeForceR
		local eBrakeForce = data.driven and (_Tune.EBrakeForce * clutch * ((1 - output.Power) * (_RPM / _Tune.Redline))) or 0
		
		data.BV.MotorMaxTorque = (brakeForce * output.Brake) + eBrakeForce + (pBrakeForce * PBrakeV)
	end
end

-- Wheel output values
local function GetCenter()
	local centerF = Vector3.new()
	local centerR = Vector3.new()
	local countF = 0
	local countR = 0
	
	for wheel, data in Wheels do
		if data.isFront then
			centerF = centerF + wheel.Position
			countF = countF + 1
		else
			centerR = centerR + wheel.Position
			countR = countR + 1
		end
	end
	
	centerF = centerF / countF
	centerR = centerR / countR
	
	_Wheelbase = math.max((centerF - centerR).Magnitude * (Units.Length_mm / 1000), 0.001)
	
	return CFrame.lookAt(centerR:Lerp(centerF, 0.5), centerF)
end

local function WheelOutput(dt: number)
	local tcsCount = 0
	local absCount = 0
	local escCount = 0
	local rot = 0
	local count = 0
	local driveCount = 0
	
	_TCSAmt = 0
	_ABSAmt = 0
	_ESCAmt = 0
	
	_MaxWheelSpin = 0
	_DriveWheelSpeed = 0
	
	for wheel, data in Wheels do
		count += 1
		
		-- Wheel speeds
		if not _WheelSpeedsTable[data.Name] then
			_WheelSpeedsTable[data.Name] = {}
		end
		
		data.RotVelocityMagnitude = wheel.RotVelocity.Magnitude
		data.WheelVelocityMagnitude = wheel.Velocity.Magnitude
		
		table.insert(_WheelSpeedsTable[data.Name], data.RotVelocityMagnitude)
		if #_WheelSpeedsTable[data.Name] > 8 then
			table.remove(_WheelSpeedsTable[data.Name], 1)
		end
		
		local avg = 0
		local avgCount = 0
		
		for _, a in _WheelSpeedsTable[data.Name] do
			avg += a
			avgCount += 1
		end
		
		avg = avg / avgCount
		_WheelSpeeds[data.Name] = avg
		
		if data.driven then
			_DriveWheelSpeed = _DriveWheelSpeed + avg
			driveCount = driveCount + 1
			if avg > _MaxWheelSpin then
				_MaxWheelSpin = avg
			end
		end
		
		-- Output wheel speeds
		data.WheelSpeedValue.Value = _WheelSpeeds[data.Name] -- I'm not using the avg variable here for future-proofing if we change the calculation later and stuff
		rot += _WheelSpeeds[data.Name] * (data.Size.Y / 2)
		
		-- TCS
		if _TCSTracker[data.Name] then
			data.TCSTrackerValue.Value = _TCSTracker[data.Name]
			_TCSAmt += _TCSTracker[data.Name]
			tcsCount += 1
		end
		
		-- ABS
		if _ABSTracker[data.Name] then
			data.ABSTrackerValue.Value = _ABSTracker[data.Name]
			_ABSAmt += _ABSTracker[data.Name]
			absCount += 1
		end
		
		-- ESC
		if _ESCTracker[data.Name] then
			data.ESCTrackerValue.Value = _ESCTracker[data.Name]
			_ESCAmt += math.abs(_ESCTracker[data.Name])
			escCount += 1
		end
	end
	
	_DriveWheelSpeed = _DriveWheelSpeed / driveCount
	
	-- Wheel speeds
	_AvgWheelSpeed = rot / count
	-- TCS
	_TCSAmt = _TCSAmt / tcsCount
	_TCSActive = false
	-- ABS
	_ABSAmt = _ABSAmt / absCount
	_ABSActive = false
	-- ESC
	_ESCAmt = _ESCAmt / escCount
	_ESCActive = false
end

-- Flip
local function Flip()
	if _FlipActive then
		return
	end
	
	_FlipActive = true
	flipAlignOrientation.Enabled = true
	
	task.delay(0.5, function()
		if flipAlignOrientation.Parent then
			flipAlignOrientation.Enabled = false
		end
		_FlipActive = false
	end)
end

local function AutoFlip()
	if weightBrick.CFrame.UpVector.Y > 0.1 then
		_FlipWait = os.clock()
		return
	end
	
	if _FlipActive or os.clock() - _FlipWait < 3 then
		return
	end
	
	_FlipWait = os.clock()
	Flip()
end

-- Inputs
-- If migrating to server authority, ensure to use attributes for inputs to allow prediction
local VehicleActions = {
	ThrottleAction = {
		Step = function(action: InputAction)
			local throttle = action:GetState() :: number
			_IThrot = math.clamp(throttle, 0, 1)
		end,
	},
	
	BrakeAction = {
		Step = function(action: InputAction)
			local brake = action:GetState() :: number
			_IBrake = math.clamp(brake, 0, 1)
		end,
	},
	
	SteerAction = {
		Step = function(action: InputAction)
			if _MSteer then
				return
			end
			
			local steer = action:GetState() :: number
			_GSteerT = math.clamp(steer, -1, 1)
		end,
	},
	
	ViewportAction = { -- Used to get mouse position on viewport for mouse steering
		Step = function(action: InputAction)
			if not _MSteer then
				return
			end
			
			local position = action:GetState() :: Vector2
			local viewportSize = camera.ViewportSize
			
			local halfWidth = viewportSize.X / 2
			local limitPercent = math.clamp(_Tune.MouseSteerLimit, 1, 100)
			local limit = halfWidth * limitPercent / 100
			local deadzone = halfWidth * math.clamp(_Tune.MouseSteerDeadzone, 0, limitPercent - 1) / 100
			local offset = position.X - halfWidth
			
			local steer = 0
			if math.abs(offset) > deadzone then
				steer = math.sign(offset) * (math.abs(offset) - deadzone) / (limit - deadzone)
			end
			
			_GSteerT = math.clamp(steer, -1, 1)
		end,
	},
	
	MouseSteerAction = {
		Pressed = function()
			MouseSteerValue.Value = not _MSteer
			_GSteerT = 0
		end,
	},
	
	ShiftDownAction = {
		Pressed = function()
			if ((_IsOn and ((_TMode == "Auto" and _CGear <= 1) and _Tune.AutoShiftVers == "New") or _TMode == "Semi") or _TMode == "Manual") then
				_ShiftDn = true
			end
		end,
	},
	
	ShiftUpAction = {
		Pressed = function()
			if ((_IsOn and ((_TMode == "Auto" and _CGear < 1) and _Tune.AutoShiftVers == "New") or _TMode == "Semi") or _TMode == "Manual") then
				_ShiftUp = true
			end
		end,
	},
	
	ClutchAction = {
		Pressed = function()
			if _TMode == "Manual" then
				_ClPressing = true
				_PlayerClutch = true
			end
		end,
		
		Released = function()
			_ClPressing = false
			_PlayerClutch = false
		end,
	},
	
	HandbrakeAction = {
		Pressed = function()
			_PBrake = not _PBrake
		end,
		
		Released = function()
			if _Velocity.Magnitude > 5 then
				_PBrake = false
			end
		end,
	},
	
	TransmissionAction = {
		Pressed = function()
			local index = table.find(_Tune.TransModes, _TMode) or 1
			_TMode = _Tune.TransModes[index % #_Tune.TransModes + 1]
		end,
	},
	
	FlipAction = {
		Pressed = Flip,
	},
	
	ABSAction = {
		Pressed = function()
			if _Tune.ABSEnabled and _IsOn then
				_ABS = not _ABS
			end
		end,
	},
	
	ESCAction = {
		Pressed = function()
			if not (_Tune.TCSEnabled and _IsOn) then
				return
			end
			
			if not _Tune.ESCEnabled then
				_TCS = not _TCS
				return
			end
			
			if _TCS and _ESC then
				_ESC = false
			elseif _TCS then
				_TCS = false
			else
				_TCS = true
				_ESC = true
			end
		end,
	},
	
	CSAction = {
		Pressed = function()
			if _Tune.CSEnabled and _IsOn then
				_CS = not _CS
			end
		end,
	},
} :: { [string]: { [string]: (...any) -> (), }, }

for actionName, handlers in VehicleActions do
	local action = VehicleContext:FindFirstChild(actionName) :: InputAction
	if not action then
		continue
	end
	
	if handlers.Pressed then
		action.Pressed:Connect(handlers.Pressed)
	end
	
	if handlers.Released then
		action.Released:Connect(handlers.Released)
	end
end

-- Run
-- Print Version
print("A-Chassis, Version " .. require(ReadMe))

-- In case of car death
driveSeat.AncestryChanged:Connect(function() 
	if driveSeat.Parent then return end 
	task.wait(10) 
	script.Parent:Destroy() 
end)

-- Runtime Loops
local function RuntimeLoop(deltaTime: number)
	-- Update Internal Values
	-- Velocity
	_Velocity = weightBrick.AssemblyLinearVelocity
	_Acceleration = (_Velocity - _OldVelocity) / deltaTime
	_OldVelocity = _Velocity
	_Center = GetCenter()
	
	-- Inputs
	VehicleActions.ThrottleAction.Step(ThrottleAction)
	VehicleActions.BrakeAction.Step(BrakeAction)
	VehicleActions.SteerAction.Step(SteerAction)
	VehicleActions.ViewportAction.Step(ViewportAction)
	
	-- Update External Values
	-- Transmission
	Value.Clutch.Value = _Clutch
	Value.Gear.Value = _CGear
	Value.TransmissionMode.Value = _TMode
	Value.CurrentRatio.Value = _CurrentRatio
	Value.RPM.Value = _RPM
	
	-- Boost
	Value.Boost.Value = _TBoost + _SBoost
	Value.BoostTurbo.Value = _TBoost
	Value.BoostSuper.Value = _SBoost
	
	-- Horsepower
	Value.HpNatural.Value = _NH
	Value.HpElectric.Value = _EH
	Value.HpTurbo.Value = _TH
	Value.HpSuper.Value = _SH
	Value.HpBoosted.Value = _BH
	Value.Horsepower.Value = _HP
	
	-- Torque
	Value.TqNatural.Value = _NT
	Value.TqElectric.Value = _ET
	Value.TqTurbo.Value = _TT
	Value.TqSuper.Value = _ST
	Value.TqBoosted.Value = _BT
	Value.Torque.Value = _TQ
	
	-- Inputs
	Value.Throttle.Value = _GThrot
	Value.InputThrottle.Value = _IThrot
	Value.Brake.Value = _GBrake
	Value.InputBrake.Value = _IBrake
	Value.SteerC.Value = _GSteerC
	Value.SteerT.Value = _GSteerT
	Value.PBrake.Value = _PBrake
	
	-- Velocity
	Value.Velocity.Value = _Velocity
	Value.AverageRotSpeed.Value = _AvgWheelSpeed
	Value.Acceleration.Value = _Acceleration
	
	-- Misc
	Value.Center.Value = _Center
	Value.TCS.Value = _TCS
	Value.TCSActive.Value = _TCSActive
	Value.TCSAmt.Value = _TCSAmt
	
	Value.ABS.Value = _ABS
	Value.ABSActive.Value = _ABSActive
	Value.ABSAmt.Value = _ABSAmt
	
	Value.ESC.Value = _ESC
	Value.ESCActive.Value = _ESCActive
	Value.ESCAmt.Value = _ESCAmt
	
	Value.CS.Value = _CS
	Value.CSActive.Value = _CSActive
	Value.CSAmt.Value = _CSAmt
	
	-- Wheel Output
	WheelOutput(deltaTime)
	
	-- Steering
	Steering(deltaTime)
	
	-- Gear
	Gear()
	
	-- Power
	Engine(deltaTime)
end

RunService:BindToSimulation(RuntimeLoop, Enum.StepFrequency.Hz60)

local function SlowRuntimeLoop()
	while true do
		local deltaTime = task.wait(1/8)
		
		-- Automatic Transmission
		if _TMode == "Auto" then 
			Auto() 
		end
		
		-- Flip
		if _Tune.AutoFlip then 
			AutoFlip() 
		end
	end
end

task.spawn(SlowRuntimeLoop)

script:SetAttribute("Loaded", true)
