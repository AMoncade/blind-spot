--!strict
-- The death (plan section 4): "Deux secondes. L'image se fige, la bande VHS déraille, ... noir." No blood, no flash:
-- the view freezes, tape tear bars slide across it (they move, they don't blink) and it fades to black, then the
-- player wakes up in the booth. The hand entering the frame comes with the Blender hands in phase 1.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local State = require(script.Parent.Parent:WaitForChild("State"))
local FirstPerson = require(script.Parent:WaitForChild("FirstPerson"))

local player = Players.LocalPlayer

local Death = {}

local gui: ScreenGui
local black: Frame
local bars: { Frame } = {}

local function build()
	gui = Instance.new("ScreenGui")
	gui.Name = "Death"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 20
	gui.Enabled = false
	for k = 1, 6 do
		local bar = Instance.new("Frame")
		bar.Name = "Tear" .. k
		bar.BorderSizePixel = 0
		bar.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		bar.BackgroundTransparency = 0.55
		bar.Size = UDim2.new(1.2, 0, 0.02 + k * 0.006, 0)
		bar.Parent = gui
		table.insert(bars, bar)
	end
	black = Instance.new("Frame")
	black.Name = "Black"
	black.BorderSizePixel = 0
	black.BackgroundColor3 = Color3.new(0, 0, 0)
	black.Size = UDim2.new(1, 0, 1, 0)
	black.BackgroundTransparency = 1
	black.ZIndex = 5
	black.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")
end

function Death.start()
	build()
	State.on("Death", function(seconds: number)
		local camera = workspace.CurrentCamera
		FirstPerson.frozen = true
		camera.CameraType = Enum.CameraType.Scriptable
		gui.Enabled = true
		black.BackgroundTransparency = 1
		TweenService:Create(black, TweenInfo.new(seconds * 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 0,
		}):Play()
		local t0 = os.clock()
		while os.clock() - t0 < seconds * 0.8 and State.dead do
			for k, bar in bars do
				-- the tear slides down and jitters sideways: motion, not flashes
				local y = ((os.clock() - t0) * (0.25 + k * 0.07) + k * 0.17) % 1
				bar.Position = UDim2.new(-0.1 + math.random() * 0.06, 0, y, 0)
			end
			task.wait(1 / 15)
		end
	end)
	State.on("Respawn", function()
		local camera = workspace.CurrentCamera
		camera.CameraType = Enum.CameraType.Custom
		FirstPerson.frozen = false
		TweenService:Create(black, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
		task.delay(0.8, function()
			if not State.dead then
				gui.Enabled = false
			end
		end)
	end)
end

return Death
