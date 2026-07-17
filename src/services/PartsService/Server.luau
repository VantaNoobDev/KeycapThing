--!strict
--!native
local DamagePartAmount: number = 2.5
local PositionKeyCapUpOffset: number = 0
local PositionKeyCapDownOffset: number = -0.45
local SoundId: number = 97846711231105

local KeyCapsConnections: { [Model]: thread } = setmetatable({}, { __mode = "k" }) :: any
local KeyCapsRestCFrame: { [Model]: CFrame } = setmetatable({}, { __mode = "k" }) :: any
local KeyCapsPressed: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local PartsServiceServer = {}

function PartsServiceServer.init()
	task.spawn(function()
		local DamageParts = workspace:FindFirstChild("DamageParts")

		if not DamageParts then
			warn("[PartsServiceServer] Missing 'DamageParts' folder in workspace")
			return
		end
		for _, Part in DamageParts:GetChildren() do
			if Part:IsA("BasePart") then
				if Part:HasTag("Damage") then
					PartsServiceServer.Touch(Part, true, false)
				end

				if Part:HasTag("Kill") then
					PartsServiceServer.Touch(Part, false, true)
				end
			end
		end
	end)

	task.spawn(function()
		local SpecialParts = workspace:FindFirstChild("SpecialParts")

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
end

function PartsServiceServer.KeyCapTouch(KeyCap: Model)
	local Part = KeyCap:FindFirstChildWhichIsA("BasePart")

	if not Part then
		return
	end

	KeyCapsRestCFrame[KeyCap] = KeyCap:GetPivot()
	KeyCapsPressed[KeyCap] = false

	task.spawn(function()
		while Part.Parent do
			local HumanoidTouching = false
			local Humanoid: Humanoid? = nil

			for _, TouchingPart in workspace:GetPartsInPart(Part) do
				local Character = TouchingPart:FindFirstAncestorOfClass("Model")
				local FoundHumanoid = Character and Character:FindFirstChildOfClass("Humanoid")
				if FoundHumanoid then
					HumanoidTouching = true
					Humanoid = FoundHumanoid
					break
				end
			end

			if HumanoidTouching ~= KeyCapsPressed[KeyCap] then
				KeyCapsPressed[KeyCap] = HumanoidTouching
				if HumanoidTouching then
					PartsServiceServer.PressTween(KeyCap, Humanoid :: Humanoid) -- Press --
				else
					PartsServiceServer.ReleaseTween(KeyCap) -- Release --
				end
			end
			task.wait(0.05)
		end

		KeyCapsRestCFrame[KeyCap] = nil
		KeyCapsPressed[KeyCap] = nil

		if KeyCapsConnections[KeyCap] then
			task.cancel(KeyCapsConnections[KeyCap])
			KeyCapsConnections[KeyCap] = nil
		end
	end)
end

local function TweenKeyCap(KeyCap: Model, FromOffset: number, ToOffset: number)
	if KeyCapsConnections[KeyCap] then
		task.cancel(KeyCapsConnections[KeyCap])
	end

	local RestCFrame = KeyCapsRestCFrame[KeyCap]

	if not RestCFrame then
		return
	end
	local Connection = task.spawn(function()
		for i = 1, 10 do
			local Alpha = i / 10
			local YOffset = math.lerp(FromOffset, ToOffset, Alpha)

			KeyCap:PivotTo(RestCFrame * CFrame.new(0, YOffset, 0))
			task.wait()
		end
		KeyCapsConnections[KeyCap] = nil
	end)
	KeyCapsConnections[KeyCap] = Connection
end

function PartsServiceServer.PressTween(KeyCap: Model, Humanoid: Humanoid)
	task.spawn(function()
		local Sound: Sound = Instance.new("Sound")
		Sound.SoundId = "rbxassetid://" .. SoundId
		Sound.Parent = Humanoid.Parent
		Sound:Play()

		Sound.Ended:Connect(function()
			Sound:Destroy()
		end)
	end)

	TweenKeyCap(KeyCap, PositionKeyCapUpOffset, PositionKeyCapDownOffset)
end

function PartsServiceServer.ReleaseTween(KeyCap: Model)
	TweenKeyCap(KeyCap, PositionKeyCapDownOffset, PositionKeyCapUpOffset)
end

function PartsServiceServer.Touch(Part: BasePart, Damage: boolean?, Health: boolean?)
	local LastHit: { [Humanoid]: number } = {}
	local DEBOUNCE: number = 0.5

	Part.Touched:Connect(function(Hit: BasePart)
		local HitHumanoid = Hit.Parent and Hit.Parent:FindFirstChildOfClass("Humanoid")

		if not HitHumanoid then
			return
		end

		local Now = os.clock()

		if LastHit[HitHumanoid] and Now - LastHit[HitHumanoid] < DEBOUNCE then
			return
		end
		LastHit[HitHumanoid] = Now

		if Damage then
			HitHumanoid:TakeDamage(DamagePartAmount)
		end

		if Health then
			HitHumanoid.Health = 0
		end
	end)
end

warn("[PartsServiceServer] has loaded successfully, with 5 functions.")

return PartsServiceServer
