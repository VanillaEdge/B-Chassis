--[[	
		             _____ _                   _     
	     /\         / ____| |                 (_)    
	    /  \ ______| |    | |__   __ _ ___ ___ _ ___ 
	   / /\ \______| |    | '_ \ / _` / __/ __| / __|
	  / ____ \     | |____| | | | (_| \__ \__ \ \__ \
	 /_/    \_\     \_____|_| |_|\__,_|___/___/_|___/
	 Version 1.7
--]]

local Tune = {}

--[[Misc]]
	Tune.LoadDelay		= 3			    -- Delay before initializing chassis (in seconds)
	Tune.AutoStart		= true		    -- Set to false if using manual ignition plugin
	Tune.AutoFlip		= true		    -- Set to false if using manual flip plugin
	Tune.Mobile			= true			-- Set to false if using a 3rd party mobile support method.
	
--[[Wheel Alignment]]
	--[Values are in degrees]
	Tune.FCamber		= -0.5
	Tune.RCamber		= -0.5
	Tune.FCaster		= 0
	Tune.RCaster		= 0
	Tune.FToe			= 0
	Tune.RToe			= 0

--[[Weight and CG]]
	Tune.Weight			= 1440		-- Total weight (in kilograms, under Earth's gravity, including wheel and suspension weight)
	Tune.WeightBSize	= {			-- Size of weight brick in milimeters. You can find how to convert studs to milimeters inside the Units module.
		--[[Width]]			1900	,
		--[[Height]]		1303	,
		--[[Length]]		4545	}
	Tune.WeightDist		= 44		-- Weight distribution (0 - on rear wheels, 100 - on front wheels, can be <0 or >100)
	Tune.CGHeight		= 0.12		-- Center of gravity height (studs relative to average of all wheels)
	Tune.WBVisible		= false		-- Makes the weight brick visible
	
	Tune.GravComp		= 35		-- Desired gravitational force in Roblox units. (35 is the default. Set to 0 to use workspace.Gravity instead)

	--Unsprung Weight
	Tune.FWheelWeight	= 22		-- Front Wheel Weight in kg
	Tune.RWheelWeight	= 23		-- Rear Wheel Weight in kg
 
	Tune.AxleSize		= 1.5		-- Size of structural members (larger = MORE STABLE / carry more weight)
	Tune.AxleDensity	= 0.1		-- Density of structural members
	Tune.CustomSuspensionDensity	= 1	-- Density of suspension joints, only applies to custom suspension. (0 makes them massless)

--[[Suspension]]
	Tune.SuspensionEnabled	= true		-- Enables suspension, true or false
	
	-- Front Spring
	Tune.FSusStiffness	= 1800			-- Sets the strength of the spring (RMU/s²)
	Tune.FSusDamping	= 175			-- Sets how fast the spring's oscillation dies down (RMU/s)
	
	Tune.FSusFreeLength = 1.8			-- Sets the natural resting length of the spring in studs
	Tune.FSusMaxLength = 2.25			-- Sets the maximum length of the front spring in studs
	Tune.FSusMinLength = 0.35			-- Sets the minimum length of the front spring in studs
	
	-- Rear Spring
	Tune.RSusStiffness	= 1800			-- Sets the strength of the spring (RMU/s²)
	Tune.RSusDamping	= 175			-- Sets how fast the spring's oscillation dies down (RMU/s)
	
	Tune.RSusFreeLength = 1.8			-- Sets the natural resting length of the spring in studs
	Tune.RSusMaxLength = 2.25			-- Sets the maximum length of the rear spring in studs
	Tune.RSusMinLength = 0.35			-- Sets the minimum length of the rear spring in studs
	
	-- Aesthetics
	Tune.SusConstraintsVisible = true	-- Sets the visibility of Constraints in SuspensionGeometry (springs, rods, etc)
	Tune.SusBasePartsVisible = true		-- Sets the visibility of BaseParts in SuspensionGeometry (meshes, parts)
	
--[[Steering]]
	-- Front Steering
	Tune.MaxSteerAngle = 32		-- Maximum front wheel steering angle in degrees at standstill, before speed scaling
	
	-- Steering Response
	Tune.SteerTime = 0.5		-- Time in seconds to reach the maximum steering angle from center
	Tune.ReturnTime = 0.35		-- Time in seconds to reset from maximum steering angle to center
	Tune.SteerDeadzone = 0.05	-- Minimum raw input threshold to filter out stick drift
	
	-- Steering Input
	Tune.SteerInputCurve = {	-- [Raw Input : Steering Multiplier]
		{0.0, 0.0},
		{0.2, 0.05},
		{0.5, 0.3},
		{1.0, 1.0},
	}
	
	-- Speed Scaling
	Tune.MaxAngleCurve = {    -- [Speed KMH : Steering Angle Multiplier]
		{0, 1.0},
		{100, 0.8},
		{200, 0.5},
		{300, 0.3},
	}
	
	-- Counter-steer
	Tune.CSEnabled			= true		-- Enables or disables countersteering
	Tune.CSAmt				= 100		-- Amount of countersteering at a full perpendicular slide (in percent)
	Tune.CSSteerThresh		= 10		-- Steering input where countersteer assist fades out (in percent)
	Tune.CSSpeedThresh		= 10		-- Minimum vehicle speed before countersteering can activate, (in km/h)
	
	-- Four Wheel Steering
	Tune.FWSteer			= "None"	-- Static, Speed, Both, or None
	Tune.RMaxSteerAngle 	= 10		-- Rear wheel steering angle limit before speed scaling and 4WS mode scaling.
	Tune.RSteerSpeed		= 80		-- Speed where 4WS fully activates (Speed), deactivates (Static), or transition begins (Both) (km/h)
	
--[[Engine (Detomiks)]]

	-- *USE THE GRAPH BELOW TO PROPERLY TUNE THE ENGINE.*
	-- https://www.desmos.com/calculator/cqhgbm0vlt
	
	-- To import engines prior to 1.7, consult the README.
	
	Tune.CustomEngineCalculations	= false		-- Enables the use of the CustomEngine module. Even if enabled, please do not remove the default engine values.
	
	-- Naturally Aspirated Engine
	Tune.Engine 		= true		
		
		Tune.PeakTorque				= 390		-- The maximum amount of torque the engine makes in lb-ft.
		Tune.PeakTorqueRPM			= 2500		-- When the engine reaches PeakTorque in RPM.

		Tune.IdleRPM				= 1000		-- The engine's desired idle RPM. IdleDamping may change this.
		Tune.IdleTorque				= 315		-- How much torque the engine makes at idle.
		Tune.IdleTorqueCurve		= 0.275		-- The shape of the torque curve between idle and ShiftRPM.
		Tune.IdleInstability 		= 20 		-- RPM wander above/below IdleRPM. Set 0 for perfectly stable idle.

		Tune.Redline				= 7500		-- The maximum RPM.
		Tune.RedlineTorque			= 160		-- How much torque the engine makes at redline.
		Tune.RedlineTorqueCurve		= 0.31		-- The shape of the torque curve between ShiftRPM and redline.
		Tune.RedlineThrottleCutTime	= 0.06		-- Seconds to cut throttle after hitting redline
		
		Tune.ShiftRPM				= 7000		-- This is when the engine shifts.
		
		Tune.VVLTorque				= 0			-- Variable Valve Lift (VVL, aka VTEC)'s amount of torque. Set this to 0 to turn off.
		Tune.VVLRPM					= 3000		-- When VVL activates in RPM.
		Tune.VVLTime				= 1000		-- How long it takes for VVL to activate in RPM.
		Tune.VVLCurve				= 0.1		-- The shape of the curve during VVL activation.

		Tune.HPLimit				= 0			-- The horsepower limit of the engine (set to 0 to turn off).

	-- Electric Engine
	Tune.Electric		= false

		Tune.E_Torque				= 1050		-- The amount of electric torque in lb-ft.
		Tune.E_TransitionRPM		= 4600		-- When the torque begins decaying.

		Tune.E_Redline				= 20000		-- The maximum RPM of the electric motor.
		Tune.E_RedlineTorque		= 205		-- How much torque is made at the maximum RPM.

		Tune.E_Curve				= 0.84		-- The shape of the curve between TransitionRPM and the redline.

	-- Turbocharger
	Tune.Turbochargers	= 2				-- Number of turbochargers in the engine, set to 0 for no turbochargers

		Tune.T_Boost			= 10		-- The maximum amount of boost of one turbocharger in PSI.
		Tune.T_PeakRPM			= 2500		-- When the turbo reaches maximum boost.

		Tune.T_IdleBoost		= 0			-- How much boost is made at idle.
		Tune.T_Curve			= 0.91		-- The shape of the boost curve between idle and ShiftRPM.
		
		Tune.T_Efficiency		= 10		-- How much torque is made with 1 PSI.
		
		Tune.T_Size				= 11		-- Turbo size, larger = less boost from horsepower
		Tune.T_SpoolIncrease	= 0.3		-- Throttle response of the turbo. (Higher = more responsive, ranges from 0 to 1)
		Tune.T_SpoolDecrease	= 0.06		-- Throttle response of the turbo. (Higher = more responsive, ranges from 0 to 1)

	-- Supercharger
	Tune.Superchargers	= 0			-- Number of superchargers in the engine, Set to 0 for no superchargers

		Tune.S_Boost			= 8			-- The maximum amount of boost of one supercharger in PSI.
		Tune.S_PeakRPM			= 5500		-- When the supercharger reaches its maximum boost.
		
		Tune.S_IdleBoost		= 6.1		-- The amount of boost at idle.
		Tune.S_IdleCurve		= 0.31		-- The shape of the boost curve between idle and ShiftRPM.

		Tune.S_RedlineBoost		= 5.6		-- The amount of boost at redline.
		Tune.S_RedlineCurve		= 0.187		-- The shape of the boost curve between ShiftRPM and redline.

		Tune.S_Efficiency		= 4.34		-- How much torque is made with 1 PSI.

		Tune.S_Response			= 0.1		-- Throttle response of the supercharger. (Higher = more responsive, ranges from 0 to 1)
		
	-- Starter
	Tune.StarterTorque 			= 120		-- Amount of torque produced by starter during ignition
	
	-- Throttle and brake input
	Tune.ThrotAccel		= .05		-- Throttle acceleration, applied per tick (recommended values between 0.1 to 0.3)
	Tune.ThrotDecel		= .2		-- Throttle deceleration, applied per tick (recommended values between 0.05 to 0.1)
	Tune.BrakeAccel		= .1		-- Brake acceleration, applied per tick
	Tune.BrakeDecel		= .2		-- Brake deceleration, applied per tick
	
	Tune.RevAccel		= 180		-- RPM acceleration when clutch is on (this should be higher than RevDecay and RevDecayRPM)
	Tune.RevDecay		= 30		-- RPM decay when clutch is on
	Tune.RevDecayRPM	= 60		-- RPM decay from engine speed

	Tune.Flywheel		= 800		-- Flywheel weight (higher = faster response, lower = more stable RPM)
	Tune.DumpMult		= 1.0		-- Flywheel energy multiplier when dumping the clutch (keep at 1.0 for the best result).
	
	Tune.InclineComp	= 1.0	    -- Torque compensation multiplier for inclines (applies gradient from 0-90 degrees)
	
--[[Drivetrain]]	
	Tune.Config			= "AWD"		-- "FWD" , "RWD" , "AWD"
	Tune.TorqueVector	= 0.2			-- AWD ONLY, "-1" has a 100% front bias, "0" has a 50:50 bias, and "1" has a 100% rear bias. Can be any number between that range.

	-- Options for a limited slip differential (LuaInt)
	-- *You can set all of these values to 0 to achieve an open differential.
	Tune.FDiffPower		= 20		-- 0 - 100				Higher values yield more wheel lock-up under throttle, more stability (Front wheels, only if driven)
	Tune.FDiffCoast		= 60		-- 0 - 100				Higher values yield more wheel lock-up when off throttle, more stability (Front wheels, only if driven)
	Tune.FDiffPreload	= 40		-- 0 - 100				Higher values will make the wheels generally lock up faster in any environment (Front wheels, only if driven)
	Tune.RDiffPower		= 20		-- 0 - 100				(Rear wheels, only if driven)
	Tune.RDiffCoast		= 60		-- 0 - 100				(Rear wheels, only if driven)
	Tune.RDiffPreload	= 40		-- 0 - 100				(Rear wheels, only if driven)

	-- Traction Control Settings
	Tune.TCSEnabled		= true		-- Implements TCS
	Tune.TCSThreshold	= 10		-- Slip speed allowed before TCS starts working (in km/h)
	Tune.TCSGradient	= 10		-- Slip speed gradient between 0 to max reduction (in km/h)
	Tune.TCSLimit		= 4			-- Minimum amount of torque at max reduction (in percent)
	
	-- Electronic Stability Control Settings
	Tune.ESCEnabled		= true		-- Implements ESC. TCS MUST ALSO BE ENABLED. This uses the same keybind as TCS.
	Tune.ESCVector		= -0.2		-- Force from the front to the rear for ESC. "-1" has a 100% front bias, "0" has a 50:50 bias, and "1" has a 100% rear bias. Can be any number between that range.
	Tune.ESCThreshold	= 0.85		-- Force difference in Gs before ESC starts working.
	Tune.ESCSpeed		= 30		-- Minimum speed before ESC can work in km/h.
	Tune.ESCThrottle	= 60		-- Maximum amount of throttle allowed to ESC in percent. (0 to allow no throttle)
	Tune.ESCBrake		= 60		-- Maximum amount of brakes allowed to ESC in percent. (0 to allow no brakes)

--[[Transmission]]
	Tune.Clutch			= true		-- Implements a realistic clutch, change to "false" for the chassis to act like AC6.81T.

	Tune.TransModes		= {"Auto", "Semi", "Manual"}												--[[
	[Modes]
		"Auto"		: Automatic shifting
		"Semi"		: Clutchless manual shifting, dual clutch transmission
		"Manual"	: Manual shifting with clutch
		
		>Include within brackets
			eg: {"Semi"} or {"Auto", "Manual"}								
	>First mode is default mode													]]

	Tune.ClutchMode		= "New"												--[[
	[Modes]
		"New"		: Speed controls clutch engagement			(AC6C V1.2)
		"Old"		: Speed and RPM control clutch engagement	(AC6C V1.1)		]]

	Tune.ClutchType 	= "Clutch"										--[[
	[Types]
		"Clutch"			: Standard clutch, recommended
		"TorqueConverter"	: Torque converter, keeps RPM up
		"CVT"				: Continously Variable Transmission
																		]] 
--[[Transmission]]
	--Transmission Settings
	Tune.Stall			= false		-- Stalling, enables the car to stall. An ignition plugin would be necessary. Disables if Tune.Clutch is false.
	Tune.ClutchRel		= false		-- If true, the driver must let off the gas before shifting to a higher gear. Recommended false for beginners.
	Tune.ClutchEngage	= 10		-- How fast engagement is (0 = instant, 99 = super slow)	
	Tune.SpeedEngage 	= 40		-- Speed the clutch fully engages at (Based on km/h)

	--Clutch: "Old" mode
	Tune.ClutchRPMMult	= 1			-- Clutch RPM multiplier, recommended to leave at 1.0

	--Torque Converter:
	Tune.TQLock 		= false		-- Torque converter starts locking at a certain RPM
	Tune.RPMEngage 		= 3500		-- Keeps RPMs to this level until passed

	--CVT:
	Tune.CVTRPM			= 7000		-- RPM that the CVT wants to keep at full throttle.
	Tune.CVTMaxRatio	= 6			-- The gear ratio that the CVT cannot go over.
	Tune.CVTMinRatio	= 1			-- The gear ratio that the CVT cannot go under.

	--Automatic Settings
	Tune.AutoShiftMode	= "Speed"												--[[
	[Modes]
		"Speed"		: Shifts based on wheel speed
		"RPM"		: Shifts based on RPM										]]	
	Tune.AutoShiftType	= "DCT"												--[[
	[Types]
		"Rev"		: Clutch engages fully once RPM reached			(AC6C V1)
		"DCT"		: Clutch engages after a set time has passed	(AC6.81T)	]]
	Tune.AutoShiftVers	= "Old"												--[[
	[Versions]
		"New"		: Shift from Reverse, Neutral, and Drive		(AC6.81T)
		"Old"		: Auto shifts into R or D when stopped.			(AC6.52S2)	]]
	
	Tune.AutoUpThresh	= -200		-- Automatic upshift point 	(relative to ShiftRPM, positive = Over-rev)
	Tune.AutoDownThresh = 1400		-- Automatic downshift point (relative to ShiftRPM, positive = Under-rev)

	--Automatic: Revmatching
	Tune.ShiftThrot		= 100		-- Throttle level when shifting down to revmatch, 0 - 100%

	--Automatic: DCT
	Tune.ShiftUpTime	= 0.2		-- Time required to shift into next gear, from a lower gear to a higher one.
	Tune.ShiftDnTime	= 0.1		-- Time required to shift into next gear, from a higher gear to a lower one.

	--Gear Ratios
	--You can tune the gears in the engine graphs by switching G_TunerType inside Desmos
	Tune.FinalDrive		= 3.621
	Tune.Ratios			= {
		--[[Park]]		--0			, --"0" enables the parking gear, "--0" disables.
		--[[Reverse]]	3.18		,
		--[[Neutral]]	0			,
		--[[ 1 ]]		3.927		,
		--[[ 2 ]]		2.454		,
		--[[ 3 ]]		1.785		,
		--[[ 4 ]]		1.413		,
		--[[ 5 ]]		1.101		,
		--[[ 6 ]]		0.893		,
	}

	Tune.FDMult			= 1			-- Ratio multiplier (keep this at 1 if car is not struggling with torque)

	-- Speed Limiter
	Tune.SpeedLimit 	= 0	 		-- Maximum speed limit in km/h (0 or less for no limiter)
	Tune.ReverseSpeed	= 40		-- Maximum reverse speed limit
	Tune.SLimitGradient	= 2			-- Throttle and brake interpolation
	Tune.SLimitBrake	= true		-- If true, this will apply the brake if the car is moving too quickly.

	--[[Brakes]]
	Tune.ExitBrake		= true		-- Set to false if you don't want the car to apply the parking brake when exiting

	-- ABS
	Tune.ABSEnabled		= true		-- Implements the Antilock Braking System
	Tune.ABSThreshold	= 3			-- Slip speed allowed before ABS starts working (in km/h) 
	Tune.ABSGradient	= 8			-- Slip speed gradient between 0 to max reduction (in km/h)
	Tune.ABSLimit		= 0			-- Minimum amount of torque at max reduction (in percent)
	
	-- Forces
	Tune.BrakeForce		= 2000		-- Total brake force in kgf
	Tune.BrakeBias		= 0.65		-- Brake bias towards the front, percentage (1 = Front, 0 = Rear, .5 = 50/50)
	Tune.PBrakeForce	= 1000		-- Handbrake force in kgf
	Tune.PBrakeBias		= 0			-- Handbrake bias towards the front, percentage (1 = Front, 0 = Rear, .5 = 50/50)
	Tune.EBrakeForce	= 500		-- Engine braking force at redline in kgf

--[[[Default Controls]]
	--Peripheral Deadzones
	Tune.Peripherals = {
		MSteerWidth				= 67		,	-- Mouse steering control width	(0 - 100% of screen width)
		MSteerDZone				= 0			,	-- Mouse steering deadzone (0 - 100%)

		ControlLDZone			= 5			,	-- Controller steering L-deadzone (0 - 100%)
		ControlRDZone			= 5			,	-- Controller steering R-deadzone (0 - 100%)
	}

	--Control Mapping
	Tune.Controls = {

		--Keyboard Controls
		--Mode Toggles
		ToggleTCS				= Enum.KeyCode.T					,
		ToggleABS				= Enum.KeyCode.Y					,
		ToggleCS				= Enum.KeyCode.U					,
		ToggleTransMode			= Enum.KeyCode.M					,
		ToggleMouseDrive		= Enum.KeyCode.R					,

		--Primary Controls
		Throttle				= Enum.KeyCode.Up					,
		Brake					= Enum.KeyCode.Down					,
		SteerLeft				= Enum.KeyCode.Left					,
		SteerRight				= Enum.KeyCode.Right				,

		--Secondary Controls
		Throttle2				= Enum.KeyCode.W					,
		Brake2					= Enum.KeyCode.S					,
		SteerLeft2				= Enum.KeyCode.A					,
		SteerRight2				= Enum.KeyCode.D					,

		--Manual Transmission
		ShiftUp					= Enum.KeyCode.E					,
		ShiftDown				= Enum.KeyCode.Q					,
		Clutch					= Enum.KeyCode.LeftShift			,

		--Handbrake
		PBrake					= Enum.KeyCode.P					,

		--Mouse Controls
		MouseThrottle			= Enum.UserInputType.MouseButton1	,
		MouseBrake				= Enum.UserInputType.MouseButton2	,
		MouseClutch				= Enum.KeyCode.W					,
		MouseShiftUp			= Enum.KeyCode.E					,
		MouseShiftDown			= Enum.KeyCode.Q					,
		MousePBrake				= Enum.KeyCode.LeftShift			,

		--Controller Mapping
		ContlrThrottle			= Enum.KeyCode.ButtonR2				,
		ContlrBrake				= Enum.KeyCode.ButtonL2				,
		ContlrSteer				= Enum.KeyCode.Thumbstick1			,
		ContlrShiftUp			= Enum.KeyCode.ButtonY				,
		ContlrShiftDown			= Enum.KeyCode.ButtonX				,
		ContlrClutch			= Enum.KeyCode.ButtonR1				,
		ContlrPBrake			= Enum.KeyCode.ButtonL1				,
		ContlrToggleTMode		= Enum.KeyCode.DPadUp				,
		ContlrToggleTCS			= Enum.KeyCode.DPadDown				,
		ContlrToggleABS			= Enum.KeyCode.DPadRight			,
		ContlrToggleCS			= Enum.KeyCode.DPadLeft				,
	}

return Tune
