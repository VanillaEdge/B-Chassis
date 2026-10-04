-- Friction.lua

const RunService = game:GetService("RunService")

const car = script.Parent.Car.Value :: Model
const seat = car.DriveSeat :: VehicleSeat
const wheels = car.Wheels :: Model
const tune = require(car["A-Chassis Tune"])

const BASE_FRICTION = 1.25
const PEAK_FRICTION = 1.65
const FRICTION_WEIGHT = 100
const LOAD_SENSITIVITY = -0.05

const RELAXATION_LENGTH = Vector2.new(0.4, 1) -- studs
const MIN_SPEED_THRESHOLD = 2 -- studs/s

local PACEJKA_PRESET = {
	Lat = {
		B = 18,			-- side grip buildup
		C = 1.55,		-- slide curve
		D = 1.08,		-- max side grip
		E = 0.70		-- grip falloff
	},
	
	Lon = {
		B = 12,			-- wheelspin/lockup buildup
		C = 1.75,		-- slip curve
		D = 1.08,		-- max drive/brake grip
		E = 0.70		-- grip falloff
	}
}

local cache = {}
local totalStiffness = 0

for i, wheel in wheels:GetChildren() do
	if not wheel:IsA("Part") then
		continue
	end
	
	const spring = wheel:FindFirstChild("Spring", true)
	if not spring or not spring:IsA("SpringConstraint") or spring.Stiffness <= 0 then
		continue
	end
	
	const attachment0 = spring.Attachment0
	const attachment1 = spring.Attachment1
	if not attachment0 or not attachment1 then
		continue
	end
	
	const part0 = attachment0:FindFirstAncestorWhichIsA("BasePart")
	const part1 = attachment1:FindFirstAncestorWhichIsA("BasePart")
	if not part0 or not part1 then
		continue
	end
	
	cache[wheel] = {
		Default = wheel.CurrentPhysicalProperties,
		Spring = spring,
		Attachment0 = attachment0,
		Attachment1 = attachment1,
		Part0 = part0,
		Part1 = part1,
		Radius = wheel.Size.Y * 0.5,
		Slip = Vector2.zero,
		ReferenceLoad = 0
	}
	
	totalStiffness += spring.Stiffness
end

const gravity = tune.GravComp == 0 and workspace.Gravity or tune.GravComp -- studs/s²
const chassisWeight = seat.AssemblyMass * gravity -- rowtons
if totalStiffness > 0 then
	for wheel, data in cache do
		data.ReferenceLoad = chassisWeight * (data.Spring.Stiffness / totalStiffness)
	end
end

const function calculateSpringForce(spring: SpringConstraint, attachment0: Attachment, attachment1: Attachment, part0: BasePart, part1: BasePart): number
	const delta = attachment1.WorldPosition - attachment0.WorldPosition
	const distance = delta.Magnitude
	if distance <= 1e-8 then
		return 0
	end
	
	local length = spring.CurrentLength
	local freeLength = spring.FreeLength
	if spring.LimitsEnabled then
		length = math.clamp(length, spring.MinLength, spring.MaxLength)
		freeLength = math.clamp(freeLength, spring.MinLength, spring.MaxLength)
	end
	
	const velocity0 = part0:GetVelocityAtPosition(attachment0.WorldPosition) -- studs/s
	const velocity1 = part1:GetVelocityAtPosition(attachment1.WorldPosition) -- studs/s
	
	const axis = delta / distance
	const axialVelocity = axis:Dot(velocity1 - velocity0)
	const force = spring.Stiffness * (length - freeLength) + spring.Damping * axialVelocity -- rowtons
	
	-- this returns load on axis spring is on, so not perfect but its good enough for us
	return math.clamp(force, -spring.MaxForce, spring.MaxForce)
end

const function calculateTransientSlip(currentSlip: Vector2, deltaTime: number, wheelRadius: number, wheelAngularVelocity: number, wheelLinearVelocity: Vector2): Vector2
	const vx = wheelLinearVelocity.X
	const vy = wheelLinearVelocity.Y
	
	const slipVelX = wheelAngularVelocity * wheelRadius - vx
	const speed = math.max(math.abs(vx), MIN_SPEED_THRESHOLD)
	
	const targetSlipX = slipVelX / speed
	const targetSlipY = vy / speed
	
	const decayX = math.exp(-(speed / RELAXATION_LENGTH.X) * deltaTime)
	const decayY = math.exp(-(speed / RELAXATION_LENGTH.Y) * deltaTime)
	
	return Vector2.new(
		targetSlipX + (currentSlip.X - targetSlipX) * decayX,
		targetSlipY + (currentSlip.Y - targetSlipY) * decayY
	)
end

const function magicFormula(slip: number, B: number, C: number, D: number, E: number): number
	const t = B * slip
	return D * math.sin(C * math.atan(t - E * (t - math.atan(t))))
end

const function isPastPeak(slip: number, B: number, C: number, E: number): boolean
	const t = B * math.abs(slip)
	return C * math.atan(t - E * (t - math.atan(t))) > math.pi * 0.5
end

const function computeRobloxFriction(lonSlip: number, latSlip: number, load: number, referenceLoad: number): number
	const lon = PACEJKA_PRESET.Lon
	const lat = PACEJKA_PRESET.Lat
	
	const lonGrip = math.abs(magicFormula(lonSlip, lon.B, lon.C, lon.D, lon.E)) / lon.D
	const latGrip = math.abs(magicFormula(latSlip, lat.B, lat.C, lat.D, lat.E)) / lat.D
	
	local grip = math.min(math.sqrt(lonGrip ^ 2 + latGrip ^ 2), 1)
	if isPastPeak(lonSlip, lon.B, lon.C, lon.E) or isPastPeak(latSlip, lat.B, lat.C, lat.E) then
		grip = math.min(grip, math.max(lonGrip, latGrip))
	end
	
	const loadScale = (math.max(load, referenceLoad) / referenceLoad) ^ LOAD_SENSITIVITY
	
	return math.clamp((BASE_FRICTION + (PEAK_FRICTION - BASE_FRICTION) * grip) * loadScale, 0, 2)
end

const function onSimulationUpdate(deltaTime: number)
	const carDown = -car:GetPivot().UpVector
	
	for wheel, data in cache do
		const axle = wheel.CFrame.RightVector
		
		const projectedDown = carDown - axle * carDown:Dot(axle)
		if projectedDown.Magnitude <= 1e-8 then
			continue
		end
		
		const forward = axle:Cross(projectedDown.Unit)
		const velocity = wheel:GetVelocityAtPosition(wheel.Position) -- studs/s
		
		const wheelLinearVelocity = Vector2.new(velocity:Dot(forward), velocity:Dot(axle))
		const wheelAngularVelocity = -wheel.AssemblyAngularVelocity:Dot(axle) -- rad/s
		
		const slip = calculateTransientSlip(data.Slip, deltaTime, data.Radius, wheelAngularVelocity, wheelLinearVelocity)
		const load = math.max(-calculateSpringForce(data.Spring, data.Attachment0, data.Attachment1, data.Part0, data.Part1), 0) -- rowtons
		const friction = computeRobloxFriction(slip.X, slip.Y, load, data.ReferenceLoad)
		
		const properties = data.Default
		wheel.CustomPhysicalProperties = PhysicalProperties.new(
			properties.Density,
			friction,
			properties.Elasticity,
			FRICTION_WEIGHT,
			properties.ElasticityWeight
		)
		
		data.Slip = slip
	end
end

RunService:BindToSimulation(onSimulationUpdate, Enum.StepFrequency.Hz60)
