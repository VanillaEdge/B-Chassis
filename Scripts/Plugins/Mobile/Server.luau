-- Server.lua

local Players = game:GetService("Players")

local seat = script.Parent.Parent.DriveSeat :: VehicleSeat
local event = script.Parent

event.OnServerEvent:Connect(function(player: Player)
	local humanoid = seat.Occupant
	local driver = Players:GetPlayerFromCharacter(humanoid and humanoid.Parent)
	if player and player.UserId == driver.UserId then
		humanoid.Sit = false
	end
end)
