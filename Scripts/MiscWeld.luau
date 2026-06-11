--[[
	  ____         _____ _                   _     
	 |  _ \       / ____| |                 (_)    
	 | |_) |_____| |    | |__   __ _ ___ ___ _ ___ 
	 |  _ <______| |    | '_ \ / _` / __/ __| / __|
	 | |_) |     | |____| | | | (_| \__ \__ \ \__ \
	 |____/       \_____|_| |_|\__,_|___/___/_|___/
	 
	Version 1
--]]

--[[
    Usage Guide:
    Main anchor point is the DriveSeat <car.DriveSeat>
    
    1. MakeWeld: Connects two parts with a weld. Use for simple connections.
        - Syntax: MakeWeld(part1, part2, [weldType], [motorSpeed])
        - Example: MakeWeld(car.DriveSeat, misc.PassengerSeat) -- Default weld
                   MakeWeld(car.DriveSeat, misc.SteeringWheel, "Motor", 0.2) -- Motor with speed
    
    2. ModelWeld: Welds an instance and its descendants to a target part
        - Syntax: ModelWeld(model, targetPart)
        - Example: ModelWeld(misc.FrontBumper, car.DriveSeat)
       
]]

local MiscWeld = {}

-- Create weld between two parts and optional motor setup
local function MakeWeld(part1: BasePart, part2: BasePart, weldType: string, motorSpeed: number): Instance
	if weldType == nil then 
		weldType = "Weld" 
	end
	
	local weld = Instance.new(weldType)
	weld.Parent = part1
    weld.Part0 = part1
    weld.Part1 = part2
    weld.C0 = part1.CFrame:Inverse() * part1.CFrame 
	weld.C1 = part2.CFrame:Inverse() * part1.CFrame 
	
    if weldType == "Motor" and motorSpeed ~= nil then 
        weld.MaxVelocity = motorSpeed 
	end
	
    return weld
end

-- Welds all parts within an instance to a target part
local function ModelWeld(model: Instance, target: BasePart)
    if model:IsA("BasePart") then 
        MakeWeld(target, model, "Weld") 
	end
	
    for i, part in model:GetDescendants() do
        if part:IsA("BasePart") then
            MakeWeld(part, target, "Weld")
        end
    end
end

local car = script.Parent.Parent.Parent
local misc = car:WaitForChild("Misc")

--[[Weld stuff below here]]








return MiscWeld
