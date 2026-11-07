--!strict
-- The uniform (content/shop.csv, kind uniform): every guard wears the company jacket over their own avatar, in the
-- colours of the uniform they equipped (Fabric: the cloth, Stripe: the reflective band). The jacket is the Blender model
-- ServerStorage.LevelModels.GuardVest, built around an R15 UpperTorso and scaled to each guard's torso (R6 too). It is
-- an Accessory, so first person hides it (Controllers/FirstPerson); teammates see it.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local Server = script.Parent.Parent
local Data = require(Server:WaitForChild("Core"):WaitForChild("Data"))
local MenuService = require(script.Parent:WaitForChild("MenuService"))

local C = Config.C
local REF = Vector3.new(2, 1.6, 1) -- the torso the jacket was built around (tools/blender/floor_props.py, guard_vest)

local UniformService = {}

local function torsoOf(character: Model): BasePart?
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	return if torso and torso:IsA("BasePart") then torso else nil
end

local function rgb(hex: string): Color3
	return Color3.fromRGB(Config.rgb(hex))
end

-- dress this guard's character in their uniform (again: after an equip, a respawn)
function UniformService.apply(player: Player)
	local character = player.Character
	local torso = character and torsoOf(character)
	local source = ServerStorage:FindFirstChild("LevelModels")
	local template = source and source:FindFirstChild("GuardVest")
	if not character or not torso or not template or not template:IsA("Model") then
		return
	end
	local old = character:FindFirstChild("Uniform")
	if old then
		old:Destroy()
	end
	local profile = Data.get(player)
	local item = Config.shopById[profile and profile.uniform or "un_navy"] or Config.shopById.un_navy
	local cf, size = template:GetBoundingBox()
	local ref = cf * CFrame.new(0, -size.Y / 2 + C.vest_center, 0)
	local extra = Vector3.new(C.vest_scale[1], C.vest_scale[2], C.vest_scale[3])
	local scale = torso.Size / REF * extra
	local accessory = Instance.new("Accessory")
	accessory.Name = "Uniform"
	for _, p in template:GetChildren() do
		if not p:IsA("BasePart") then
			continue
		end
		local part = p:Clone()
		for _, d in part:GetChildren() do
			if d:IsA("JointInstance") or d:IsA("WeldConstraint") then
				d:Destroy()
			end
		end
		local rel = ref:ToObjectSpace(p.CFrame)
		part.Size = p.Size * scale
		-- the model's front is its +z, a character's is its -z: half a turn
		part.CFrame = torso.CFrame * CFrame.Angles(0, math.pi, 0) * CFrame.new(rel.Position * scale) * rel.Rotation
		part.Anchored = false
		part.Massless = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		if part.Name == "Fabric" then
			part.Color = rgb(item.frame)
			part.Material = Enum.Material.Fabric
		elseif part.Name == "Stripe" then
			part.Color = rgb(item.rec)
			part.Material = Enum.Material.SmoothPlastic
			part.Reflectance = 0.15
		end
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = torso
		weld.Part1 = part
		weld.Parent = part
		part.Parent = accessory
	end
	accessory.Parent = character
end

function UniformService.init()
	MenuService.onEquip = UniformService.apply
end

function UniformService.start()
	local function watch(player: Player)
		player.CharacterAppearanceLoaded:Connect(function()
			UniformService.apply(player)
		end)
		if player.Character then
			UniformService.apply(player)
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
end

return UniformService
