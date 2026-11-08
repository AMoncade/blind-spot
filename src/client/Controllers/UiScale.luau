--!strict
-- Every screen of the game grows with the player's screen (Adrien, 8 Nov: "sur mon PC les UI sont ultra petites").
-- The UI is drawn for a phone (844 x 390, 44 px touch targets, plan section 11: "Téléphone d'abord"); on a bigger screen
-- each of the game's ScreenGuis gets a UIScale, as big as the screen allows over ui_reference_width x
-- ui_reference_height, never under 1 (the phone) nor over ui_max_scale. It follows the window when it changes size.
-- Not the camcorder's picture (Camcorder.luau lays it over the screen in the hands, in the viewport's own pixels), and
-- not Roblox's own screens (the touch controls, the chat).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local C = Config.C
local player = Players.LocalPlayer

local UiScale = {}

-- the game's screens (the names they are made with)
local SCALED = {
	Hud = true,
	Menu = true,
	TaskList = true,
	Skills = true,
	CamcorderButton = true,
	Lobby = true,
	Captions = true,
	Story = true,
	Signals = true,
	Watcher = true,
	TapePlayer = true,
	Loading = true,
	Descent = true,
	Death = true,
	Tutorial = true,
}

-- the scale for a viewport of this size
function UiScale.factor(view: Vector2): number
	local fit = math.min(view.X / C.ui_reference_width, view.Y / C.ui_reference_height)
	return math.clamp(fit, 1, C.ui_max_scale)
end

function UiScale.start()
	local playerGui = player:WaitForChild("PlayerGui")
	local scales: { UIScale } = {}
	local function current(): number
		local camera = workspace.CurrentCamera
		return if camera then UiScale.factor(camera.ViewportSize) else 1
	end
	local function attach(gui: Instance)
		if not gui:IsA("ScreenGui") or not SCALED[gui.Name] or gui:FindFirstChild("Fit") then
			return
		end
		local s = Instance.new("UIScale")
		s.Name = "Fit"
		s.Scale = current()
		s.Parent = gui
		table.insert(scales, s)
	end
	for _, gui in playerGui:GetChildren() do
		attach(gui)
	end
	playerGui.ChildAdded:Connect(attach)
	local watched: Camera? = nil
	local function refresh()
		local f = current()
		for _, s in scales do
			if s.Parent and s.Scale ~= f then
				s.Scale = f
			end
		end
	end
	local function watch()
		local camera = workspace.CurrentCamera
		if camera and camera ~= watched then
			watched = camera
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
		end
		refresh()
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watch)
	watch()
end

return UiScale
