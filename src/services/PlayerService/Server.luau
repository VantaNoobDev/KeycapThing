--!strict
--!native

-- SERVICES --
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- DEPENDENCIES --
const Data = require(ReplicatedStorage.Shared.Services.Data.Data).server

const PlayerService = {}

function PlayerService.init()
	warn(`{script.Name} has been loaded with success!`)
end

function PlayerService.OnPlayerJoin(Player: Player): ()
	task.spawn(function()
		const leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = Player

		const Stage = Instance.new("NumberValue")
		Stage.Name = "Stage"
		Stage.Value = 0
		Stage.Parent = leaderstats

		const Wins = Instance.new("NumberValue")
		Wins.Name = "Wins"
		Wins.Value = 0
		Wins.Parent = leaderstats

		task.delay(3, function()
			Data[Player].PlayerInfo.Stage.Changed(function(NewValue: number)
				Stage.Value = NewValue
			end)

			Data[Player].PlayerInfo.Wins.Changed(function(NewValue: number)
				Wins.Value = NewValue
			end)
		end)
	end)
end

Players.PlayerAdded:Connect(PlayerService.OnPlayerJoin)

return PlayerService
