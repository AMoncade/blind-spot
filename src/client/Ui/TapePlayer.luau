--!strict
-- Plays a found tape (content/tapes.csv) as a VHS screen: black with rolling tracking bars, PLAY and the tape's date
-- stamp, its lines typed out one after the other. No sound yet: the lines are the tape (plan section 6: 20 to 40 s).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Kit = require(script.Parent:WaitForChild("Kit"))

local COLOR = Kit.COLOR
local FONT = Kit.FONT
local player = Players.LocalPlayer

local TapePlayer = {}

local current: ScreenGui? = nil

function TapePlayer.stop()
	if current then
		current:Destroy()
		current = nil
	end
end

function TapePlayer.play(tape: any)
	TapePlayer.stop()
	local gui = Kit.new("ScreenGui", {
		Name = "TapePlayer",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 40,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui
	current = gui
	Kit.new("Frame", {
		BackgroundColor3 = Color3.fromRGB(8, 9, 10),
		BackgroundTransparency = 0.04,
		Size = UDim2.fromScale(1, 1),
		Parent = gui,
	})
	local bars = {}
	for k = 1, 3 do
		bars[k] = Kit.new("Frame", {
			BackgroundColor3 = Color3.fromRGB(70, 74, 78),
			BackgroundTransparency = 0.7,
			Size = UDim2.new(1, 0, 0, 6 + k * 4),
			Parent = gui,
		}) :: Frame
	end
	local safe = Kit.new("Frame", { Size = UDim2.fromScale(1, 1), Parent = gui })
	Kit.new("UIPadding", {
		PaddingTop = UDim.new(0, 48),
		PaddingLeft = UDim.new(0, 28),
		PaddingRight = UDim.new(0, 28),
		PaddingBottom = UDim.new(0, 24),
		Parent = safe,
	})
	Kit.text(safe, "▶ PLAY", {
		FontFace = FONT.mono,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(0.3, 0, 0, 28),
		Max = 26,
	})
	Kit.text(safe, tape.stamp, {
		FontFace = FONT.mono,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -64, 0, 0),
		Size = UDim2.new(0.45, 0, 0, 28),
		Max = 22,
	})
	Kit.text(safe, tape.title, {
		FontFace = FONT.title,
		TextColor3 = COLOR.brass,
		Position = UDim2.new(0.5, 0, 0.18, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0.7, 0, 0, 40),
		Max = 40,
	})
	local line = Kit.text(safe, "", {
		FontFace = FONT.mono,
		TextWrapped = true,
		Position = UDim2.new(0.5, 0, 0.6, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(0.8, 0, 0.3, 0),
		Max = 26,
	})
	local close = Kit.button(safe, Kit.ART.DarkButton, "X", {
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, -6),
		Size = UDim2.fromOffset(52, 44),
		TextSize = 24,
	})
	close.Activated:Connect(TapePlayer.stop)
	gui.Parent = player:WaitForChild("PlayerGui")

	local t0 = os.clock()
	local connection = RunService.RenderStepped:Connect(function()
		for k, bar in bars do
			bar.Position = UDim2.new(0, 0, ((os.clock() - t0) * (0.07 + k * 0.04) + k * 0.3) % 1, 0)
		end
	end)
	gui.Destroying:Connect(function()
		connection:Disconnect()
	end)
	task.spawn(function()
		for _, text in tape.lines do
			for n = 1, #text do
				if current ~= gui then
					return
				end
				line.Text = string.sub(text, 1, n)
				task.wait(1 / 32)
			end
			task.wait(2.4)
		end
		task.wait(1.5)
		if current == gui then
			line.Text = "■ STOP"
		end
	end)
end

return TapePlayer
