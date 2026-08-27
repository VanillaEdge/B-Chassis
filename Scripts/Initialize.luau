--[[
	  ____         _____ _                   _     
	 |  _ \       / ____| |                 (_)    
	 | |_) |_____| |    | |__   __ _ ___ ___ _ ___ 
	 |  _ <______| |    | '_ \ / _` / __/ __| / __|
	 | |_) |     | |____| | | | (_| \__ \__ \ \__ \
	 |____/       \_____|_| |_|\__,_|___/___/_|___/
	 
	Version 1
--]]

local Players = game:GetService("Players")

local car = script.Parent.Parent
local seat = car.DriveSeat
seat.Disabled = true

local plugins = script.Parent.Plugins
local interface = script.Parent["A-Chassis Interface"]
interface.Car.Value = car

local shutdownEvent = Instance.new("UnreliableRemoteEvent", script.Parent)
shutdownEvent.Name = "Shutdown"

local Tune = require(script.Parent)
local Units = require(car["A-Chassis Tune"].README.Units)

local Wheels = {}
for i, v in car.Wheels:GetChildren() do
	local name = v.Name
	if not v:IsA("BasePart") or not (name == "FL" or name == "FR" or name == "RL" or name == "RR") then 
		continue 
	end
	
	table.insert(Wheels, v)
end

local function MakeWeldConstraint(part0: BasePart, part1: BasePart): WeldConstraint
	local weld = Instance.new("WeldConstraint")
	weld.Name = "Weld"
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Parent = part0
	return weld
end

local function ModelWeld(model: Instance, target: BasePart)
	if model:IsA("BasePart") then 
		MakeWeldConstraint(target, model) 
	end
	
	for i, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			MakeWeldConstraint(part, target)
		end
	end
end

local function GetCarCenter(dist: number ?): CFrame
	dist = dist or 0.5
	
	local centerF = Vector3.new()
	local centerR = Vector3.new()
	local countF = 0
	local countR = 0
	
	for i, v in Wheels do
		if v.Name == "FL" or v.Name == "FR" or v.Name == "F" then
			centerF += v.Position
			countF += 1
		else
			centerR += v.Position
			countR += 1
		end
	end
	
	centerF /= countF
	centerR /= countR
	
	local pos = centerR:Lerp(centerF, dist)
	return CFrame.lookAt(pos, pos + centerF - centerR)
end

-- Remove Existing Mass
for i, descendant in car:GetDescendants() do
	if descendant:IsA("BasePart") then
		descendant.Massless = true
	end
end

-- Suspension
for _, v in Wheels do
	--Apply Wheel Density
	local cpp = v.CurrentPhysicalProperties
	local wdensity = 0
	if string.find(v.Name, "F") then
		wdensity = (Tune.FWheelWeight*Units.Mass_kg)/(math.pi*(v.Size.Y/2)^2*(v.Size.X))
	else
		wdensity = (Tune.RWheelWeight*Units.Mass_kg)/(math.pi*(v.Size.Y/2)^2*(v.Size.X))
	end
	v.CustomPhysicalProperties = PhysicalProperties.new(
		wdensity, 
		cpp.Friction, 
		cpp.Elasticity, 
		cpp.FrictionWeight, 
		cpp.ElasticityWeight
	)
	v.Massless = false

	--Save wheel part positions
	local WParts = {}
	for _, a in v.Parts:GetDescendants() do
		if not a:IsA("BasePart") then continue end
		table.insert(WParts, {a, v.CFrame:ToObjectSpace(a.CFrame)})
	end
	for _, a in v.WheelFixed:GetDescendants() do
		if not a:IsA("BasePart") then continue end
		table.insert(WParts, {a, v.CFrame:ToObjectSpace(a.CFrame)})
	end

	--Align Wheels
	if v.Name=="FL" then
		v.CFrame = v.CFrame*CFrame.Angles(math.rad(Tune.FCaster), math.rad(-Tune.FToe), math.rad(Tune.FCamber))
	elseif v.Name=="FR" then
		v.CFrame = v.CFrame*CFrame.Angles(math.rad(-Tune.FCaster), math.rad(Tune.FToe), math.rad(Tune.FCamber))
	elseif v.Name=="RL" then
		v.CFrame = v.CFrame*CFrame.Angles(math.rad(Tune.RCaster), math.rad(-Tune.RToe), math.rad(Tune.RCamber))
	elseif v.Name=="RR" then
		v.CFrame = v.CFrame*CFrame.Angles(math.rad(-Tune.RCaster), math.rad(Tune.RToe), math.rad(Tune.RCamber))
	end

	for _, a in WParts do
		a[1].CFrame = v.CFrame*a[2]
	end

	--Chassis Assembly
	--Create Steering Axle
	local arm = Instance.new("Part")
	arm.Name = "Arm"
	arm.Anchored = true
	arm.CanCollide = false
	arm.Size = Vector3.new(Tune.AxleSize, Tune.AxleSize, Tune.AxleSize)
	arm.CFrame = v.CFrame
	arm.CustomPhysicalProperties = PhysicalProperties.new(math.clamp(Tune.AxleDensity, 0.01, 100), 0, 0, 100, 100)
	arm.TopSurface = Enum.SurfaceType.Smooth
	arm.BottomSurface = Enum.SurfaceType.Smooth
	arm.Transparency = 1
	arm.Parent = v

	--Create Wheel Spindle
	local base=arm:Clone()
	base.Name="Base"
	base.CFrame=arm.CFrame*CFrame.new(0, Tune.AxleSize, 0)
	base.Parent=v

	--Create Steering Anchor
	local axle = arm:Clone()
	axle.Name = "Axle"
	axle.CFrame = v.CFrame*CFrame.new(v.Size.X/2+Tune.AxleSize/2, 0, 0)
	axle.Parent = v

	--Create Powered Axle (LuaInt)
	local axlep = arm:Clone()
	axlep.Name = 'AxleP'
	axlep.CFrame = v.CFrame
	axlep.Parent = v
	MakeWeldConstraint(axlep, axle)

	--Create Suspension
	local SuspensionGeometry = v:FindFirstChild("SuspensionGeometry")
	if Tune.SuspensionEnabled and SuspensionGeometry then	
		for i, descendant in SuspensionGeometry:GetDescendants() do
			if descendant.Name == "Weld" and (descendant:IsA("BasePart") or descendant:IsA("Model")) then
				ModelWeld(descendant, car.DriveSeat)
			end
			if descendant:IsA("BasePart") then
				descendant.CustomPhysicalProperties = PhysicalProperties.new(math.clamp(Tune.CustomSuspensionDensity, 0.01, 100), 0, 0, 0, 0)
				if Tune.CustomSuspensionDensity <= 0 then
					descendant.Massless = true
				end
				descendant.Transparency = Tune.SusBasePartsVisible and 0.5 or 1
			end
			if descendant:IsA("Constraint") then
				descendant.Visible = Tune.SusConstraintsVisible
			end
		end
		
		MakeWeldConstraint(SuspensionGeometry.Hub, base)
		
		if SuspensionGeometry:FindFirstChild("SpringTop") then
			MakeWeldConstraint(SuspensionGeometry.SpringTop, car.DriveSeat)
		end
		
		local spring = SuspensionGeometry:FindFirstChild("Spring")
		spring.LimitsEnabled = true
		
		if v.Name == "FL" or v.Name == "FR" or v.Name == "F" then
			spring.Damping = Tune.FSusDamping
			spring.Stiffness = Tune.FSusStiffness
			spring.FreeLength = Tune.FSusFreeLength
			spring.MaxLength = Tune.FSusMaxLength
			spring.MinLength = Tune.FSusMinLength
		else
			spring.Damping = Tune.RSusDamping
			spring.Stiffness = Tune.RSusStiffness
			spring.FreeLength = Tune.RSusFreeLength
			spring.MaxLength = Tune.RSusMaxLength
			spring.MinLength = Tune.RSusMinLength
		end
	else
		if SuspensionGeometry then
			SuspensionGeometry:ClearAllChildren()
		end
		MakeWeldConstraint(car.DriveSeat, base)
	end
	
	--Lock Rear Steering Axle
	if (Tune.FWSteer=='Static' or Tune.FWSteer=='Speed' or Tune.FWSteer=='Both') == false then
		if v.Name == "RL" or v.Name == "RR" then
			MakeWeldConstraint(base, axle)
		end
	end

	MakeWeldConstraint(arm, axle)

	--Weld Miscelaneous Parts
	if v:FindFirstChild("SuspensionFixed")~=nil then
		ModelWeld(v.SuspensionFixed, car.DriveSeat)
	end
	if v:FindFirstChild("WheelFixed")~=nil then
		ModelWeld(v.WheelFixed, axle)
	end
	if v:FindFirstChild("Fixed")~=nil then
		ModelWeld(v.Fixed, arm)
	end

	--Weld Wheel Parts
	if v:FindFirstChild("Parts")~=nil then
		ModelWeld(v.Parts, v)
	end

	--Add Steering Gyro
	if v:FindFirstChild("Steer") then
		v:FindFirstChild("Steer"):Destroy()
	end

	if (v.Name == "FR" or v.Name == "FL" or v.Name == "F") or (Tune.FWSteer == "Static" or Tune.FWSteer == "Speed" or Tune.FWSteer == "Both") then
		local steerAttach0 = Instance.new("Attachment")
		steerAttach0.Name = "SteerAttach0"
		steerAttach0.Parent = arm
		
		local steerAttach1 = Instance.new("Attachment")
		steerAttach1.Name = "SteerAttach1"
		steerAttach1.Parent = base
		
		local steer = Instance.new("AlignOrientation")
		steer.Name = "Steer"
		steer.Mode = Enum.OrientationAlignmentMode.TwoAttachment
		steer.ReactionTorqueEnabled = true
		steer.RigidityEnabled = true
		steer.Attachment0 = steerAttach0
		steer.Attachment1 = steerAttach1
		steer.Name = "Steer"
		steer.CFrame = v.CFrame
		steer.Parent = v.Arm
	end

	--Add rotation constraint (Detomiks)
	local rotationAttachment0 = Instance.new("Attachment")
	rotationAttachment0.Name = "RotationAttachment0"
	rotationAttachment0.Position = Vector3.new(0, -Tune.AxleSize/2, 0)
	rotationAttachment0.Orientation = Vector3.new(0, 0, 90)
	rotationAttachment0.Parent = base

	local rotationAttachment1 = Instance.new("Attachment")
	rotationAttachment1.Name = "RotationAttachment1"
	rotationAttachment1.Position = Vector3.new(0, Tune.AxleSize/2, 0)
	rotationAttachment1.Orientation = Vector3.new(0, 0, 90)
	rotationAttachment1.Parent = arm

	local rotationHinge = Instance.new("HingeConstraint")
	rotationHinge.Name = "Rotate"
	rotationHinge.LimitsEnabled = true
	rotationHinge.UpperAngle = (string.find(v.Name, "F") and Tune.MaxSteerAngle or Tune.RMaxSteerAngle) + 5 -- +5 to prevent physics shaking
	rotationHinge.LowerAngle = -rotationHinge.UpperAngle
	rotationHinge.Attachment0 = rotationAttachment0
	rotationHinge.Attachment1 = rotationAttachment1
	rotationHinge.Parent = base

	--Add Motors (LuaInt)
	local AV=Instance.new("HingeConstraint")
	AV.ActuatorType='Motor'
	AV.Parent = v
	AV.Attachment0=Instance.new("Attachment")
	AV.Attachment0.Name='AA'
	AV.Attachment0.Parent = v.AxleP
	AV.Attachment1=Instance.new("Attachment")
	AV.Attachment1.Name='AB'
	AV.Attachment1.Parent = v
	AV.Name="#AV"
	AV.AngularVelocity=0
	AV.MotorMaxTorque=0

	local BV=Instance.new("HingeConstraint")
	BV.ActuatorType='Motor'
	BV.Parent = v
	BV.Attachment0=Instance.new("Attachment")
	BV.Attachment0.Parent = v.AxleP
	BV.Attachment0.Name='BA'
	BV.Attachment1=Instance.new("Attachment")
	BV.Attachment1.Name='BB'
	BV.Attachment1.Parent = v
	BV.Name="#BV"
	BV.AngularVelocity=0
	if string.find(v.Name, "F") then
		BV.MotorMaxTorque = (Tune.PBrakeForce * 9.80665 * Units.Force_N) * Tune.PBrakeBias
	else
		BV.MotorMaxTorque = (Tune.PBrakeForce * 9.80665 * Units.Force_N) * (1-Tune.PBrakeBias)
	end

	-- Attempt to fix wheel alignment issues
	if string.find(v.Name, "L") then
		AV.Attachment0.Orientation = Vector3.new(0, 180, 0)
		BV.Attachment0.Orientation = Vector3.new(0, 180, 0)
		AV.Attachment1.Orientation = Vector3.new(0, 180, 0)
		BV.Attachment1.Orientation = Vector3.new(0, 180, 0)
	end

	--Realign Caster
	if v.Name=="FL" then
		v.CFrame = v.CFrame*CFrame.Angles(math.rad(-Tune.FCaster), 0, 0)
	elseif v.Name=="FR" then
		v.CFrame = v.CFrame*CFrame.Angles(math.rad(Tune.FCaster), 0, 0)
	elseif v.Name=="RL" then
		v.CFrame = v.CFrame*CFrame.Angles(math.rad(-Tune.RCaster), 0, 0)
	elseif v.Name=="RR" then
		v.CFrame = v.CFrame*CFrame.Angles(math.rad(Tune.RCaster), 0, 0)
	end
end

-- Weight
do
	local mass = 0
	for i, descendant in car:GetDescendants() do
		if descendant:IsA("BasePart") and not descendant.Massless then
			mass += descendant.Mass
		end
	end	
	
	local size = Vector3.new(Tune.WeightBSize[1], Tune.WeightBSize[2], Tune.WeightBSize[3]) / Units.Length_mm
	local density = (Tune.Weight * Units.Mass_kg - mass) / (size.X * size.Y * size.Z) -- fixed by denkodin
	
	local weightB = Instance.new("Part")
	weightB.Name = "#Weight"
	weightB.Anchored = true
	weightB.CanCollide = false
	weightB.BrickColor = BrickColor.new("Really black")
	weightB.TopSurface = Enum.SurfaceType.Smooth
	weightB.BottomSurface = Enum.SurfaceType.Smooth
	weightB.Transparency = Tune.WBVisible and 0.75 or 1

	weightB.Size = size
	weightB.CustomPhysicalProperties = PhysicalProperties.new(math.clamp(density, 0.01, 100), 0, 0, 0, 0)
	weightB.CFrame = GetCarCenter(Tune.WeightDist / 100) * CFrame.new(0, Tune.CGHeight, 0)
	weightB.Parent = car.Body
end

-- Gravcomp
for i, descendent in car:GetDescendants() do
	local valid = descendent:IsA("BasePart") and not descendent.Massless
	if not valid then 
		continue
	end
	
	local attachment = descendent:FindFirstChild("#GRAVCOMP_ATTACH") or Instance.new("Attachment")
	attachment.Name = "#GRAVCOMP_ATTACH"
	attachment.Parent = descendent
	
	local force = descendent:FindFirstChild("#GRAVCOMP") or Instance.new("VectorForce")
	force.Name = "#GRAVCOMP"
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.ApplyAtCenterOfMass  = true
	force.Attachment0 = attachment
	force.Force = Vector3.new(0, Tune.GravComp > 0 and descendent.Mass * (workspace.Gravity - Tune.GravComp) or 0, 0)
	force.Enabled = Tune.GravComp > 0
	force.Parent = descendent
end

-- Flip
do
	local weightB = car.Body:WaitForChild("#Weight") :: BasePart
	
	local attachment = Instance.new("Attachment")
	attachment.Name = "FlipAttachment"
	attachment.Axis = car.DriveSeat.CFrame:VectorToObjectSpace(weightB.CFrame.UpVector)
	attachment.Parent = car.DriveSeat
	
	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Name = "Flip"
	alignOrientation.Enabled = false
	alignOrientation.RigidityEnabled = true
	alignOrientation.AlignType = Enum.AlignType.PrimaryAxisParallel
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = attachment
	alignOrientation.PrimaryAxis = Vector3.yAxis
	alignOrientation.Parent = car.DriveSeat
end

-- Weld and Unanchor
do
	-- Run MiscWeld Module(s)
	for i, v in script:GetChildren() do
		if v:IsA("ModuleScript") then
			require(v)
		end
	end
	
	-- Weld Body
	ModelWeld(car.Body, car.DriveSeat)
	
	--Unanchor
	for i, v in car:GetDescendants() do
		if v:IsA("BasePart") then
			v.Anchored = false
		end
	end	
end

-- Plugins
do
	for i, v in plugins:GetChildren() do
		-- Move remotes to car
		for i, event in v:GetChildren() do
			if not event:IsA("BaseRemoteEvent") and not event:IsA("RemoteFunction") then
				continue
			end
			
			event.Parent = car
			
			-- Enable scripts if any
			for i, child in event:GetChildren() do
				if child:IsA("Script") then 
					child.Enabled = true 
				end
			end
		end
		
		-- Move plugins to screen gui
		v.Parent = interface
	end
	
	-- Cleanup folder
	plugins:Destroy()
end

-- Character mass
for i, seat in car:GetDescendants() do
	if not seat:IsA("Seat") and not seat:IsA("VehicleSeat") then
		continue
	end
	
	local parts = {}
	
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if not seat.Occupant then
			for part, massless in parts do
				part.Massless = massless
			end
			
			table.clear(parts)
			return
		end
		
		for i, part in seat.Occupant.Parent:GetDescendants() do
			if not part:IsA("BasePart") then
				continue
			end
			
			parts[part] = part.Massless
			part.Massless = true
		end
	end)
end

-- Void death cleanup
seat.AncestryChanged:Connect(function()
	if seat.Parent then 
		return
	end
	
	task.wait(10) -- Delay for clients to finish up
	
	if car then
		car:Destroy()
	end
end)

-- Driver Sit
seat.ChildAdded:Connect(function(child: Instance)
	if child.Name == "SeatWeld" and child:IsA("Weld") then
		local player = Players:GetPlayerFromCharacter(child.Part1.Parent)
		if not player then 
			return 
		end
		
		task.wait(0.1)
		
		car.DriveSeat:SetNetworkOwner(player)
		
		local clone = interface:Clone()
		clone.Parent = player.PlayerGui
	end
end)

-- Driver Leave
seat.ChildRemoved:Connect(function(child: Instance)
	if child.Name == "SeatWeld" and child:IsA("Weld") then
		if not seat.Parent then
			return
		end
		
		-- Remove Flip Force
		if seat:FindFirstChild("Flip") then
			seat.Flip.Enabled = false
		end
		
		-- Handle wheel changes
		for _, wheel in Wheels do
			-- Apply handbrake
			if wheel:FindFirstChild("#BV") and Tune.ExitBrake then
				if string.find(wheel.Name, "F") then
					wheel["#BV"].MotorMaxTorque = (Tune.PBrakeForce * 9.80665 * Units.Force_N) * Tune.PBrakeBias
				else
					wheel["#BV"].MotorMaxTorque = (Tune.PBrakeForce * 9.80665 * Units.Force_N) * (1-Tune.PBrakeBias)
				end
			end
			
			-- Remove wheel force
			if wheel:FindFirstChild("#AV") then
				wheel["#AV"].MotorMaxTorque = 0
				wheel["#AV"].AngularVelocity = 0
			end
			
			-- Readjust steering
			if wheel.Arm:FindFirstChild("Steer") then
				wheel.Arm.Steer.Attachment0.Orientation = Vector3.new(0, -wheel.Base.Rotate.CurrentAngle, 0)
			end
		end	
	end
end)

-- Driver mental breakdown
shutdownEvent.OnServerEvent:Connect(function(player: Player)
	if not player:FindFirstChild("PlayerGui") then 
		return 
	end
	
	for i, v in player.PlayerGui:GetChildren() do
		if v.Name == "A-Chassis Interface" then 
			v:Destroy() 
		end
	end
end)

task.delay(1, function()
	script.Parent.Parent.DriveSeat.Disabled = false
	script:SetAttribute("Loaded", true)
end)
