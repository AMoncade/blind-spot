--!strict
-- The story on the client (plan section 6): the dispatcher's radio as subtitles (bottom centre, the walkie-talkie,
-- typed out, one line at a time), and the booth's log book (its prompt opens the previous guard's notes for tonight).
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))

local ART = Kit.ART
local COLOR = Kit.COLOR
local FONT = Kit.FONT
local player = Players.LocalPlayer

local Story = {}

function Story.start()
	local gui = Kit.new("ScreenGui", {
		Name = "Story",
		ResetOnSpawn = false,
		DisplayOrder = 9,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui

	-- the radio
	local radio = Kit.new("ImageLabel", {
		Name = "Radio",
		Image = ART.DarkButton.Image,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = ART.DarkButton.Slice,
		SliceScale = 0.2,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -18),
		Size = UDim2.new(0.62, 0, 0, 58),
		Visible = false,
		Parent = gui,
	}) :: ImageLabel
	Kit.new("UISizeConstraint", { MaxSize = Vector2.new(620, 58), Parent = radio })
	Kit.image(radio, ART.InviteIcon, {
		Size = UDim2.fromOffset(60, 60),
		Position = UDim2.new(0, -12, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
	})
	local who = Kit.text(radio, "DISPATCH", {
		FontFace = FONT.title,
		TextColor3 = COLOR.brass,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 54, 0, 6),
		Size = UDim2.new(1, -66, 0, 16),
		Max = 14,
	})
	local said = Kit.text(radio, "", {
		FontFace = FONT.label,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Position = UDim2.new(0, 54, 0, 22),
		Size = UDim2.new(1, -66, 0, 30),
		Max = 17,
		Min = 9,
	})
	local queue: { string } = {}
	local busy = false
	local function nextLine()
		if busy then
			return
		end
		local text = table.remove(queue, 1)
		if not text then
			radio.Visible = false
			return
		end
		busy = true
		radio.Visible = true
		-- the dispatcher grows strange: the radio of the hard night is only static
		who.Text = if string.find(text, "static", 1, true) then "RADIO" else "DISPATCH"
		-- typed fast, held long enough to read; a waiting queue shortens the hold so the radio never lags behind
		for n = 1, #text, 2 do
			said.Text = string.sub(text, 1, n + 1)
			task.wait(1 / 30)
		end
		said.Text = text
		task.wait(if #queue > 0 then 1.2 else 1.6 + #text / 30)
		busy = false
		nextLine()
	end
	State.on("Radio", function(text: string)
		table.insert(queue, text)
		task.spawn(nextLine)
	end)
	State.on("Shift", function(onShift: boolean)
		if not onShift then
			table.clear(queue)
		end
	end)

	-- the log book
	local book, body, close = Kit.window(gui, "LogBook", "SHIFT LOG  ·  P3 BOOTH")
	close.Activated:Connect(function()
		book.Visible = false
	end)
	local sheet = Kit.new("Frame", {
		BackgroundColor3 = COLOR.paper,
		BackgroundTransparency = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = body,
	})
	Kit.new("UIPadding", {
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		PaddingTop = UDim.new(0, 10),
		Parent = sheet,
	})
	Kit.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sheet })
	local function fill()
		for _, c in sheet:GetChildren() do
			if c:IsA("TextLabel") then
				c:Destroy()
			end
		end
		local night = State.night and State.night.night or 1
		local k = 0
		for _, entry in Config.Logbook do
			if entry.night == night then
				k += 1
				local l = Kit.text(sheet, "- " .. entry.line, {
					FontFace = FONT.paper,
					TextColor3 = COLOR.paperInk,
					TextStrokeTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
					Size = UDim2.new(1, 0, 0, 40),
					LayoutOrder = k,
					Max = 20,
				})
				l.TextScaled = false
				l.TextSize = 18
			end
		end
	end
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local model = prompt:FindFirstAncestorWhichIsA("Model")
		if model and model.Name == "LogBook" then
			fill()
			Kit.show(book, true)
		end
	end)
	gui.Parent = player:WaitForChild("PlayerGui")
end

return Story
