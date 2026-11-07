--!strict
-- The night's task list on the guard's clipboard (plan section 2: "la ronde est sur une planchette"), top right: what
-- to do, what is done, what you carry. Each open task has a small marker in the world (where to take the item, where
-- to use it, which checkpoint to scan). Tap the clipboard's header to fold it. The server decides everything
-- (TaskService); this draws State.tasks.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))

local ART = Kit.ART
local COLOR = Kit.COLOR
local FONT = Kit.FONT
local player = Players.LocalPlayer

local Tasks = {}

local STUD_METRES = 0.28 -- plan section 7: 1 stud is about 0.28 m
local LINES = 10

export type Parts = { root: Frame, count: TextLabel, holding: TextLabel, lines: { TextLabel }, sheet: Frame }

-- Builds the clipboard into gui (Studio previews it in Edit).
function Tasks.build(gui: ScreenGui): Parts
	local root = Kit.new("Frame", {
		Name = "Clipboard",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.fromOffset(250, 40 + LINES * 18 + 30),
		Parent = gui,
	}) :: Frame
	local header = Kit.new("ImageButton", {
		Name = "Header",
		Image = ART.DarkButton.Image,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = ART.DarkButton.Slice,
		SliceScale = 0.18,
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 44),
		Parent = root,
	}) :: ImageButton
	Kit.image(header, ART.RoundsIcon, {
		Size = UDim2.fromOffset(50, 50),
		Position = UDim2.new(0, -8, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
	})
	Kit.text(header, "TONIGHT'S ROUND", {
		FontFace = FONT.title,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 46, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(0.62, 0, 0.5, 0),
		Max = 20,
	})
	local count = Kit.text(header, "0/0", {
		Name = "Count",
		FontFace = FONT.mono,
		TextColor3 = COLOR.brass,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0.22, 0, 0.5, 0),
		Max = 20,
	})
	-- the paper sheet
	local sheet = Kit.new("Frame", {
		Name = "Sheet",
		BackgroundColor3 = COLOR.paper,
		BackgroundTransparency = 0.04,
		Position = UDim2.new(0, 8, 0, 40),
		Size = UDim2.new(1, -16, 1, -40),
		Parent = root,
	}) :: Frame
	Kit.new("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 6),
		PaddingTop = UDim.new(0, 6),
		Parent = sheet,
	})
	local holding = Kit.text(sheet, "", {
		Name = "Holding",
		FontFace = FONT.title,
		TextColor3 = COLOR.red,
		TextStrokeTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 22),
		Max = 16,
	})
	local lines = {}
	for k = 1, LINES do
		local l = Kit.text(sheet, "", {
			Name = "Line" .. k,
			FontFace = FONT.paper,
			TextColor3 = COLOR.paperInk,
			TextStrokeTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 0, 0, 24 + (k - 1) * 18),
			Size = UDim2.new(1, 0, 0, 17),
			Max = 15,
			Min = 8,
		})
		-- one size for every line (a scaled text would grow on the short ones), cut with ... when too long
		l.TextScaled = false
		l.TextSize = 13
		l.TextTruncate = Enum.TextTruncate.AtEnd
		lines[k] = l
	end
	header.Activated:Connect(function()
		sheet.Visible = not sheet.Visible
	end)
	return { root = root, count = count, holding = holding, lines = lines, sheet = sheet }
end

-- what the clipboard shows for a task list (payload of the Tasks event)
function Tasks.fill(parts: Parts, data: any, myId: number)
	local list = data and data.tasks or {}
	local done = 0
	for k = 1, LINES do
		local t = list[k]
		local l = parts.lines[k]
		if t then
			if t.done then
				done += 1
			end
			local mine = t.carriedBy == myId
			local mark = if t.done then "[x]" elseif mine then "[>]" else "[ ]"
			-- where the next step is: the pickup until the item is in someone's hands
			local at = if t.pickup and not mine and t.carriedBy == nil then t.pickup else t.target
			local where = if at and not t.done then "  · " .. (Config.floorAt(at[1])) else ""
			local filmed = if t.progress
					and t.progress > 0
					and not t.done
				then string.format("  %d%%", math.floor(t.progress * 100))
				else ""
			l.Text = `{mark} {t.label}{filmed}{where}`
			l.TextColor3 = if t.done then Color3.fromRGB(140, 132, 118) elseif mine then COLOR.red else COLOR.paperInk
			l.Visible = true
		else
			l.Visible = false
		end
	end
	-- a taken guard's badge is one more line (plan section 3: bring it back to the booth)
	local free = #list + 1
	for _, b in State.badges or {} do
		if free <= LINES then
			local l = parts.lines[free]
			local mine = b.carriedBy == myId
			l.Text = (if mine then "[>] " else "[ ] ") .. "Bring " .. b.name .. "'s badge to the booth"
			l.TextColor3 = if mine then COLOR.red else COLOR.paperInk
			l.Visible = true
			free += 1
		end
	end
	parts.count.Text = `{done}/{#list}`
	local held = data and data.held and data.held[tostring(myId)]
	parts.holding.Text = if held then "HOLDING: " .. string.upper(held) else "HANDS FREE"
	parts.holding.TextColor3 = if held then COLOR.red else Color3.fromRGB(120, 112, 98)
end

-- ---------------------------------------------------------------- world markers

local markers: { [string]: BillboardGui } = {}

local function marker(key: string, text: string): BillboardGui
	local b = markers[key]
	if b then
		return b
	end
	b = Kit.new("BillboardGui", {
		Name = "Marker_" .. key,
		AlwaysOnTop = true,
		LightInfluence = 0,
		MaxDistance = 260,
		Size = UDim2.fromOffset(140, 46),
		StudsOffset = Vector3.new(0, 2.6, 0),
	}) :: BillboardGui
	local diamond = Kit.new("Frame", {
		Name = "Diamond",
		BackgroundColor3 = COLOR.brass,
		BackgroundTransparency = 0,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 2),
		Size = UDim2.fromOffset(12, 12),
		Rotation = 45,
		Parent = b,
	})
	Kit.new("UIStroke", { Color = COLOR.shadow, Thickness = 1.5, Parent = diamond })
	Kit.text(b, text, {
		Name = "Label",
		FontFace = FONT.title,
		TextColor3 = COLOR.ink,
		Position = UDim2.new(0, 0, 0, 18),
		Size = UDim2.new(1, 0, 0, 16),
		Max = 15,
	})
	Kit.text(b, "", {
		Name = "Distance",
		FontFace = FONT.mono,
		TextColor3 = COLOR.dim,
		Position = UDim2.new(0, 0, 0, 33),
		Size = UDim2.new(1, 0, 0, 12),
		Max = 12,
	})
	b.Parent = player:WaitForChild("PlayerGui")
	markers[key] = b
	return b
end

local function spotAnchor(position: { number }): BasePart?
	-- the spot whose anchor sits over this config position
	local root = workspace:FindFirstChild("P3")
	local spots = root and root:FindFirstChild("Spots")
	if not spots then
		return nil
	end
	for _, m in spots:GetChildren() do
		local a = m:FindFirstChild("Anchor")
		if a and a:IsA("BasePart") then
			local p = a.Position
			if math.abs(p.X - position[1]) < 3 and math.abs(p.Z - position[3]) < 3 then
				return a
			end
		end
	end
	return nil
end

local function badgeAnchor(userId: number): BasePart?
	local root = workspace:FindFirstChild("P3")
	local folder = root and root:FindFirstChild("Badges")
	local part = folder and folder:FindFirstChild("Badge_" .. userId)
	return if part and part:IsA("BasePart") then part else nil
end

local function refreshMarkers(data: any, myId: number)
	local wanted: { [string]: boolean } = {}
	if State.shift and not State.down then
		for _, b in State.badges or {} do
			local key, text, pos
			if b.carriedBy == myId then
				key, text = "badge:" .. b.id .. ":use", "SIGN IN " .. b.name
				local book = Config.spotById.SignIn
				pos = { book.x, book.y, book.z }
			elseif b.carriedBy == nil then
				key, text, pos = "badge:" .. b.id, b.name .. "'S BADGE", b.pos
			end
			if key and pos then
				local anchor = if b.carriedBy == myId then spotAnchor(pos) else badgeAnchor(b.id)
				if anchor then
					local m = marker(key, text)
					m.Adornee = anchor
					wanted[key] = true
				end
			end
		end
	end
	if State.shift and data and data.tasks then
		for _, t in data.tasks do
			if t.done then
				continue
			end
			local pos, text
			if t.kind == "scan" then
				pos, text = t.target, "SCAN"
			elseif t.kind == "film" then
				pos, text = t.target, "FILM"
			elseif t.carriedBy == myId then
				pos, text = t.target, "USE " .. string.upper(t.item)
			elseif t.carriedBy == nil and t.pickup then
				pos, text = t.pickup, "TAKE " .. string.upper(t.item)
			end
			if pos then
				local key = t.id .. ":" .. text
				local anchor = spotAnchor(pos)
				if anchor then
					local b = marker(key, text)
					b.Adornee = anchor
					b:SetAttribute("Floor", (Config.floorAt(pos[1])))
					wanted[key] = true
				end
			end
		end
	end
	for key, b in markers do
		if not wanted[key] then
			b:Destroy()
			markers[key] = nil
		end
	end
end

function Tasks.start()
	local gui = Kit.new("ScreenGui", {
		Name = "TaskList",
		ResetOnSpawn = false,
		DisplayOrder = 2,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui
	local parts = Tasks.build(gui)
	gui.Enabled = State.shift
	gui.Parent = player:WaitForChild("PlayerGui")

	local function refresh()
		Tasks.fill(parts, State.tasks, player.UserId)
		refreshMarkers(State.tasks, player.UserId)
		gui.Enabled = State.shift
	end
	State.on("Tasks", refresh)
	State.on("Badges", refresh)
	State.on("Down", refresh)
	State.on("Respawn", refresh)
	State.on("Shift", refresh)

	RunService.RenderStepped:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		-- a marker shows on its own floor only (the floors lie side by side in the world)
		local here = if root and root:IsA("BasePart") then (Config.floorAt(root.Position.X)) else nil
		for _, b in markers do
			b.Enabled = State.shift and not State.dead and not State.down and b:GetAttribute("Floor") == here
			local adornee = b.Adornee
			local distance = b:FindFirstChild("Distance")
			if root and root:IsA("BasePart") and adornee and adornee:IsA("BasePart") and distance then
				local d = (adornee.Position - root.Position).Magnitude * STUD_METRES
				local label = distance :: TextLabel
				label.Text = string.format("%d m", math.floor(d + 0.5))
			end
		end
	end)
	refresh()
end

return Tasks
