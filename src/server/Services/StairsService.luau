--!strict
-- The stairwell (content/stairs.csv): each floor's stairwell door has a prompt up and a prompt down to the next
-- floor's door. The floors lie side by side in the world (content/floors.csv), so taking the stairs moves the guard
-- to the other door, facing out. What they carry comes with them. On shift only.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Net"))

local Server = script.Parent.Parent
local World = require(Server:WaitForChild("Core"):WaitForChild("World"))

local C = Config.C

local StairsService = {}

StairsService.isPlaying = nil :: ((player: Player) -> boolean)? -- NightService: on shift and alive
StairsService.onTake = nil :: ((player: Player, floor: string) -> ())? -- a guard took the stairs (the radio)

local nextUse: { [Player]: number } = {}

-- where a guard comes out of a stairwell door: stairs_out studs in front of it, facing away from it
function StairsService.exitCFrame(spotId: string): CFrame
	local spot = Config.spotById[spotId]
	local yaw = math.rad(spot.yaw)
	local front = Vector3.new(math.sin(yaw), 0, math.cos(yaw))
	local at = Vector3.new(spot.x, spot.y + 3, spot.z) + front * C.stairs_out
	return CFrame.lookAt(at, at + front)
end

-- a guard takes the stairs to the door `target` (the prompts; Studio tests call it directly)
function StairsService.take(player: Player, target: string)
	if StairsService.isPlaying and not StairsService.isPlaying(player) then
		return
	end
	local now = os.clock()
	if now < (nextUse[player] or 0) then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	nextUse[player] = now + C.stairs_cooldown
	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = StairsService.exitCFrame(target)
	local floor = Config.spotById[target].floor
	Net.event():FireClient(player, "Notice", Config.floorById[floor].name, true)
	if StairsService.onTake then
		StairsService.onTake(player, floor)
	end
end

local function addPrompt(
	anchor: BasePart,
	text: string,
	key: Enum.KeyCode,
	pad: Enum.KeyCode,
	offset: number,
	target: string
)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Stairs" .. text
	prompt.ObjectText = "Stairwell"
	prompt.ActionText = text .. " to " .. Config.floorById[Config.spotById[target].floor].name
	prompt.HoldDuration = C.stairs_hold
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = key
	prompt.GamepadKeyCode = pad
	prompt.UIOffset = Vector2.new(0, offset)
	prompt.Parent = anchor
	prompt.Triggered:Connect(function(player)
		StairsService.take(player, target)
	end)
end

function StairsService.start()
	Players.PlayerRemoving:Connect(function(player)
		nextUse[player] = nil
	end)
	local spots = (World.root :: Model):WaitForChild("Spots")
	for _, row in Config.Stairs do
		local model = spots:FindFirstChild(row.spot)
		local anchor = model and model:FindFirstChild("Anchor")
		if not anchor or not anchor:IsA("BasePart") then
			warn(`[StairsService] no stairwell door {row.spot}`)
			continue
		end
		-- the spot's own prompt (World) is not used: two prompts instead, with different keys so both show
		-- (ProximityPrompt exclusivity is per key)
		local own = anchor:FindFirstChildWhichIsA("ProximityPrompt")
		if own then
			own:Destroy()
		end
		if row.up ~= "" then
			addPrompt(anchor, "Up", Enum.KeyCode.E, Enum.KeyCode.ButtonX, 0, row.up)
		end
		if row.down ~= "" then
			addPrompt(anchor, "Down", Enum.KeyCode.R, Enum.KeyCode.ButtonY, if row.up ~= "" then 72 else 0, row.down)
		end
	end
end

return StairsService
