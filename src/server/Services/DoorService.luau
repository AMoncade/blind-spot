--!strict
-- The blocks that change the map during a night (Logic/Watch.DYNAMIC): the service corridors' fire doors, which a
-- guard on shift closes or opens with a prompt, and the fresh plaster on P4, which a guard breaks on night 5 (a task
-- with the effect open:<id>, TaskService). A closed door blocks the Unseen's paths and the cameras' view
-- (WatchService.setSolid), its invisible box collides and its model swings shut. The box in workspace.P3.Geometry
-- carries the attribute Solid so the clients redraw the safe zones. Every night starts with the doors open and the
-- plaster whole.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Watch = require(Shared:WaitForChild("Logic"):WaitForChild("Watch"))

local Server = script.Parent.Parent
local World = require(Server:WaitForChild("Core"):WaitForChild("World"))
local WatchService = require(script.Parent:WaitForChild("WatchService"))

local C = Config.C

local DoorService = {}

DoorService.isPlaying = nil :: ((player: Player) -> boolean)? -- NightService: on shift and alive

type Door = {
	block: typeof(Config.Map[1]),
	box: BasePart, -- the collision and the attribute Solid
	model: Model?, -- the Blender model (nil: the box is a visible stand-in)
	closed: CFrame?, -- the model's pivot when the block is solid
	prompt: ProximityPrompt?,
	solid: boolean,
	busyUntil: number,
	moveId: number,
}

local doors: { [string]: Door } = {}

local function default(b: typeof(Config.Map[1])): boolean
	return Watch.DYNAMIC[b.kind] == true
end

-- the model's pivot when a fire door stands open: turned door_swing degrees around its hinge (the block's west or
-- south end, depending on which way the door runs)
local function openPivot(d: Door): CFrame
	local b = d.block
	local closed = d.closed :: CFrame
	local alongX = b.sx >= b.sz
	local hinge = if alongX then CFrame.new(b.x - b.sx / 2, b.y, b.z) else CFrame.new(b.x, b.y, b.z - b.sz / 2)
	return hinge * CFrame.Angles(0, math.rad(C.door_swing), 0) * hinge:Inverse() * closed
end

local function pose(d: Door, animate: boolean)
	local model = d.model
	if d.block.kind == "plaster" then
		-- the patch is whole or broken: the plaster parts go, the rubble stays (parts named Rubble*)
		if model then
			for _, p in model:GetDescendants() do
				if p:IsA("BasePart") then
					local rubble = string.sub(p.Name, 1, 6) == "Rubble"
					local visible = if rubble then not d.solid else d.solid
					p.Transparency = if visible then (p:GetAttribute("BaseTransparency") or 0) :: number else 1
					p.CanCollide = false
				end
			end
		else
			d.box.Transparency = if d.solid then 0 else 1
		end
		return
	end
	if not model or not d.closed then
		-- a stand-in: the box is the door, see-through when it stands open
		d.box.Transparency = if d.solid then 0 else 0.75
		return
	end
	local from = model:GetPivot()
	local to = if d.solid then d.closed :: CFrame else openPivot(d)
	d.moveId += 1
	local id = d.moveId
	if not animate then
		model:PivotTo(to)
		return
	end
	task.spawn(function()
		local t0 = os.clock()
		while d.moveId == id do
			local a = math.min(1, (os.clock() - t0) / math.max(C.door_seconds, 0.01))
			local s = a * a * (3 - 2 * a)
			model:PivotTo(from:Lerp(to, s))
			if a >= 1 then
				break
			end
			task.wait()
		end
	end)
end

local function refreshPrompt(d: Door)
	local prompt = d.prompt
	if prompt then
		prompt.ActionText = if d.solid then "Open" else "Close"
	end
end

local function set(id: string, solid: boolean, animate: boolean)
	local d = doors[id]
	if not d then
		return
	end
	d.solid = solid
	d.box.CanCollide = solid
	d.box:SetAttribute("Solid", solid)
	WatchService.setSolid(id, solid)
	pose(d, animate)
	refreshPrompt(d)
end

-- the plaster on P4 breaks (TaskService: a task's effect open:<id> once it is done)
function DoorService.open(id: string)
	set(id, false, true)
end

-- a new night (or the shift's end): every door open, the plaster whole
function DoorService.reset()
	for id, d in doors do
		d.busyUntil = 0
		set(id, default(d.block), false)
	end
end

function DoorService.isSolid(id: string): boolean
	local d = doors[id]
	return d ~= nil and d.solid
end

-- a guard closes or opens a fire door (its prompt; Studio tests call it directly)
function DoorService.toggle(id: string, player: Player)
	local d = doors[id]
	if not d or (DoorService.isPlaying and not DoorService.isPlaying(player)) then
		return
	end
	local now = os.clock()
	if now < d.busyUntil then
		return
	end
	d.busyUntil = now + C.door_cooldown
	set(id, not d.solid, true)
end

function DoorService.start()
	local root = World.root :: Model
	local geometry = root:WaitForChild("Geometry")
	local dressing = root:WaitForChild("Dressing")
	for _, b in Config.Map do
		if Watch.DYNAMIC[b.kind] == nil then
			continue
		end
		local box = geometry:FindFirstChild(b.id)
		if not box or not box:IsA("BasePart") then
			warn(`[DoorService] no box for {b.id}`)
			continue
		end
		local model = dressing:FindFirstChild(b.id)
		local d: Door = {
			block = b,
			box = box,
			model = if model and model:IsA("Model") then model else nil,
			closed = if model and model:IsA("Model") then model:GetPivot() else nil,
			prompt = nil,
			solid = default(b),
			busyUntil = 0,
			moveId = 0,
		}
		if d.model then
			for _, p in (d.model :: Model):GetDescendants() do
				if p:IsA("BasePart") then
					p:SetAttribute("BaseTransparency", p.Transparency)
				end
			end
		end
		if b.kind == "firedoor" then
			-- the prompt sits on the box (it doesn't swing): reachable from both sides
			local prompt = Instance.new("ProximityPrompt")
			prompt.ObjectText = "Fire door"
			prompt.HoldDuration = C.door_hold
			prompt.MaxActivationDistance = 7
			prompt.RequiresLineOfSight = false
			prompt.Parent = box
			prompt.Triggered:Connect(function(player)
				DoorService.toggle(b.id, player)
			end)
			d.prompt = prompt
		end
		doors[b.id] = d
	end
	DoorService.reset()
end

return DoorService
