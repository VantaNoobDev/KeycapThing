--!strict
--!native
-- SERVICES --
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")

-- DEPENDENCIES --
const Data = require(ReplicatedStorage.Shared.Services.Data.Data).server
const Random = Random.new()

-- CONFIGURATION --
const DamagePartAmount: number = 2.5
const PositionKeyCapUpOffset: number = 0
const PositionKeyCapDownOffset: number = -0.6
const SoundId: number = 97846711231105
const DamageDebounce: number = 0.5
const AlphaFrames: number = 10
const Seed: number = 969345834810

-- TABLES --
const KeyCapsConnections: { [Model]: thread } = setmetatable({}, { __mode = "k" }) :: any
const KeyCapsRestCFrame: { [Model]: CFrame } = setmetatable({}, { __mode = "k" }) :: any
const KeyCapsPressed: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any

-- TYPES --
type TouchType = { read [string]: boolean }
type PartFunctions = {
	read [string]: (HitHumanoid: Humanoid, BasePart) -> (),

	read Damage: (Humanoid, BasePart?) -> (),
	read Kill: (Humanoid, BasePart?) -> (),
	read Checkpoint: (Humanoid, BasePart) -> (),
}

const PartFunctions: PartFunctions = {
	Damage = function(HitHumanoid: Humanoid): ()
		HitHumanoid:TakeDamage(DamagePartAmount)
	end,

	Kill = function(HitHumanoid: Humanoid): ()
		HitHumanoid.Health = 0
	end,

	Checkpoint = function(HitHumanoid: Humanoid, CheckpointPart: BasePart): ()
		local Character: Model = HitHumanoid.Parent :: Model
		local Player = Players:GetPlayerFromCharacter(Character) :: Player

		if not Player then
			warn("Player has not been found!")
			return
		end

		const PlayerData = Data.Service:asyncGetProfile(Player.UserId).Data
		const PlayerCheckpointLevel: number = PlayerData.PlayerInfo.Stage

		const PartLevelNumber = tonumber(CheckpointPart.Name) :: number
		if PlayerCheckpointLevel < PartLevelNumber then
			PlayerData.info.Stage(PartLevelNumber)
		end
	end,
}

const PartsServiceServer = {}

function PartsServiceServer.init(): ()
	task.spawn(function()
		const DamageParts = workspace:FindFirstChild("DamageParts")

		if not DamageParts then
			warn("[PartsServiceServer] Missing 'DamageParts' folder in workspace")
			return
		end
		for _, Part in DamageParts:GetChildren() do
			if Part:IsA("BasePart") then
				if Part:HasTag("Damage") then
					PartsServiceServer.Touch(Part, { Damage = true } :: TouchType)
				end

				if Part:HasTag("Kill") then
					PartsServiceServer.Touch(Part, { Kill = true } :: TouchType)
				end
			end
		end
	end)

	task.spawn(function()
		const SpecialParts = workspace:FindFirstChild("SpecialParts")

		if not SpecialParts then
			warn("[PartsServiceServer] Missing 'SpecialParts' folder in workspace")
			return
		end

		for _, Part in SpecialParts:GetChildren() do
			if Part:IsA("Model") then
				PartsServiceServer.KeyCapTouch(Part)
			end
		end
	end)

	task.spawn(function()
		const CheckpointParts = workspace:FindFirstChild("CheckpointParts")

		if not CheckpointParts then
			warn("[PartsServiceServer] Missing 'CheckpointParts' folder in workspace")
			return
		end
		for _, Part in CheckpointParts:GetChildren() do
			if Part:IsA("BasePart") then
				PartsServiceServer.Touch(Part, { Checkpoint = true } :: TouchType)
			end
		end
	end)
end

function PartsServiceServer.KeyCapTouch(KeyCap: Model): ()
	const Part = KeyCap:FindFirstChild("Touch") :: BasePart
	const Mesh = KeyCap:FindFirstChild("Key") :: MeshPart
	const Label = Mesh:WaitForChild("Top"):FindFirstChildOfClass("TextLabel") :: TextLabel

	if not Part or not Mesh then
		return
	end

	Mesh.BrickColor = BrickColor.Random()
	Label.Text = string.upper(string.char(Random:NextInteger(97, 122)))

	KeyCapsRestCFrame[KeyCap] = KeyCap:GetPivot()
	KeyCapsPressed[KeyCap] = false

	const TouchingHumanoids: { [Humanoid]: number } = setmetatable({}, { __mode = "k" }) :: any

	const function ReleaseIfEmpty(): ()
		if next(TouchingHumanoids) == nil and KeyCapsPressed[KeyCap] then
			KeyCapsPressed[KeyCap] = false
			PartsServiceServer.ReleaseTween(KeyCap)
		end
	end

	Part.Touched:Connect(function(Hit: BasePart)
		const Character = Hit.Parent
		const Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

		if not Humanoid then
			return
		end

		TouchingHumanoids[Humanoid] = (TouchingHumanoids[Humanoid] or 0) + 1

		if not KeyCapsPressed[KeyCap] then
			KeyCapsPressed[KeyCap] = true
			PartsServiceServer.PressTween(KeyCap, Humanoid)
		end
	end)

	Part.TouchEnded:Connect(function(Hit: BasePart)
		const Character = Hit.Parent
		const Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

		if not Humanoid then
			return
		end

		const Count = TouchingHumanoids[Humanoid]

		if not Count then
			return
		end

		if Count <= 1 then
			TouchingHumanoids[Humanoid] = nil
		else
			TouchingHumanoids[Humanoid] = Count - 1
		end

		ReleaseIfEmpty()
	end)

	task.spawn(function()
		while Part.Parent do
			task.wait(1)

			for Humanoid in TouchingHumanoids do
				const Character = Humanoid.Parent

				if not Character or Humanoid.Health <= 0 or not Character:IsDescendantOf(workspace) then
					TouchingHumanoids[Humanoid] = nil
				end
			end

			ReleaseIfEmpty()
		end

		KeyCapsRestCFrame[KeyCap] = nil
		KeyCapsPressed[KeyCap] = nil

		if KeyCapsConnections[KeyCap] then
			task.cancel(KeyCapsConnections[KeyCap])
			KeyCapsConnections[KeyCap] = nil
		end
	end)
end

local function TweenKeyCap(KeyCap: Model, FromOffset: number, ToOffset: number): ()
	if KeyCapsConnections[KeyCap] then
		task.cancel(KeyCapsConnections[KeyCap])
	end

	const RestCFrame = KeyCapsRestCFrame[KeyCap]

	if not RestCFrame then
		return
	end
	local Connection = task.spawn(function()
		for i = 1, 10 do
			local Alpha = i / AlphaFrames
			local YOffset = math.lerp(FromOffset, ToOffset, Alpha)

			KeyCap:PivotTo(RestCFrame * CFrame.new(0, YOffset, 0))
			task.wait()
		end
		KeyCapsConnections[KeyCap] = nil
	end)
	KeyCapsConnections[KeyCap] = Connection
end

function PartsServiceServer.PressTween(KeyCap: Model, Humanoid: Humanoid): ()
	task.spawn(function()
		const Sound: Sound = Instance.new("Sound")
		Sound.SoundId = "rbxassetid://" .. SoundId
		Sound.Parent = Humanoid.Parent
		Sound:Play()

		Sound.Ended:Connect(function()
			Sound:Destroy()
		end)
	end)

	TweenKeyCap(KeyCap, PositionKeyCapUpOffset, PositionKeyCapDownOffset)
end

function PartsServiceServer.ReleaseTween(KeyCap: Model): ()
	TweenKeyCap(KeyCap, PositionKeyCapDownOffset, PositionKeyCapUpOffset)
end

function PartsServiceServer.Touch(Part: BasePart, Type: TouchType): ()
	const LastHit: { [Humanoid]: number } = setmetatable({}, { __mode = "k" }) :: any
	local PartType: string = ""

	for TypeName, Boolean in Type do
		if not Boolean then
			continue
		end
		PartType = TypeName
	end

	Part.Touched:Connect(function(Hit: BasePart)
		const HitHumanoid = Hit.Parent and Hit.Parent:FindFirstChildOfClass("Humanoid")

		if not HitHumanoid then
			return
		end

		const Now = os.clock()

		if LastHit[HitHumanoid] and Now - LastHit[HitHumanoid] < DamageDebounce then
			return
		end
		LastHit[HitHumanoid] = Now

		const PartFunction = PartFunctions[PartType]
		if PartFunction then
			PartFunction(HitHumanoid :: Humanoid, Part :: BasePart)
		end
	end)
end

warn("[PartsServiceServer] has loaded successfully, with 5 functions.")

return PartsServiceServer
