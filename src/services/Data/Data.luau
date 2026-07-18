--!strict
--!native

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(ReplicatedStorage.Packages.DataService)

local Template = {
	PlayerInfo = { Stage = 0, Wins = 0 },
}

return DataService({
	template = Template,
})
