local ServerScriptService = game:GetService("ServerScriptService")

local PartsServiceServer = require(ServerScriptService.Services.PartsService.PartsServiceServer)
local PlayerServiceServer = require(ServerScriptService.Services.PlayerService.PlayerServiceServer)

PartsServiceServer.init()
PlayerServiceServer.init()
