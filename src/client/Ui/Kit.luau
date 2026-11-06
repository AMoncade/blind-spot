--!strict
-- The game's UI kit: the night security office look (worn steel, brass trim, paper, red REC), its fonts and its
-- generated art (Config/UiArt). Every element sets its own fill, border and font: no engine default anywhere.
-- Fonts: Oswald (titles, buttons: a condensed security-sign face), Special Elite (typewritten paper), Roboto Mono
-- (numbers, clocks, the camcorder).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ART = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("UiArt"))

local Kit = {}

Kit.ART = ART

Kit.FONT = {
	title = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold),
	label = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Medium),
	paper = Font.new("rbxasset://fonts/families/SpecialElite.json"),
	mono = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Bold),
}

Kit.COLOR = {
	ink = Color3.fromRGB(232, 226, 214), -- off-white text
	dim = Color3.fromRGB(150, 143, 130),
	brass = Color3.fromRGB(201, 164, 106),
	red = Color3.fromRGB(214, 52, 38),
	green = Color3.fromRGB(125, 255, 138),
	plate = Color3.fromRGB(22, 21, 23), -- dark steel cards
	plateEdge = Color3.fromRGB(78, 66, 48),
	paper = Color3.fromRGB(231, 223, 203),
	paperInk = Color3.fromRGB(38, 34, 30),
	shadow = Color3.fromRGB(8, 7, 7),
}

type Props = { [string]: any }

function Kit.new(class: string, props: Props?): Instance
	local inst = Instance.new(class)
	if inst:IsA("GuiObject") then
		inst.BorderSizePixel = 0
		inst.BackgroundTransparency = 1
	end
	for k, v in props or {} do
		if k ~= "Parent" then
			(inst :: any)[k] = v
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

-- live text: scaled with a size cap, a dark stroke so it reads on art
function Kit.text(parent: Instance, text: string, props: Props?): TextLabel
	local p: Props = {
		Text = text,
		FontFace = Kit.FONT.label,
		TextColor3 = Kit.COLOR.ink,
		TextScaled = true,
		TextStrokeColor3 = Kit.COLOR.shadow,
		TextStrokeTransparency = 0.55,
		Parent = parent,
	}
	for k, v in props or {} do
		if k ~= "Max" and k ~= "Min" then
			p[k] = v
		end
	end
	local l = Kit.new("TextLabel", p) :: TextLabel
	Kit.new("UITextSizeConstraint", {
		MaxTextSize = props and props.Max or 28,
		MinTextSize = props and props.Min or 10,
		Parent = l,
	})
	return l
end

function Kit.image(parent: Instance, image: string, props: Props?): ImageLabel
	local p: Props = { Image = image, ScaleType = Enum.ScaleType.Fit, Parent = parent }
	for k, v in props or {} do
		p[k] = v
	end
	return Kit.new("ImageLabel", p) :: ImageLabel
end

-- a dark steel card with a thin brass edge (shop cards, rows)
function Kit.plate(parent: Instance, props: Props?): Frame
	local p: Props = { BackgroundColor3 = Kit.COLOR.plate, BackgroundTransparency = 0.08, Parent = parent }
	for k, v in props or {} do
		p[k] = v
	end
	local f = Kit.new("Frame", p) :: Frame
	Kit.new("UICorner", { CornerRadius = UDim.new(0, 4), Parent = f })
	Kit.new("UIStroke", { Color = Kit.COLOR.plateEdge, Thickness = 1, Parent = f })
	return f
end

-- An art button (9-slice) with a live label. art: Kit.ART.PlayButton or Kit.ART.DarkButton. Returns the button and
-- its label. Pressed and disabled states swap the art; a small press dip, no bounce (horror: restrained motion).
function Kit.button(parent: Instance, art: any, label: string, props: Props?): (ImageButton, TextLabel)
	local p: Props = {
		Image = art.Image,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = art.Slice,
		SliceScale = 0.32,
		AutoButtonColor = false,
		Parent = parent,
	}
	for k, v in props or {} do
		if k ~= "TextSize" then
			p[k] = v
		end
	end
	local b = Kit.new("ImageButton", p) :: ImageButton
	local l = Kit.text(b, label, {
		FontFace = Kit.FONT.title,
		Size = UDim2.new(0.84, 0, 0.62, 0),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Max = props and props.TextSize or 30,
	})
	l.Name = "Label"
	local scale = Kit.new("UIScale", { Parent = b }) :: UIScale
	b.MouseButton1Down:Connect(function()
		b.Image = art.Pressed
		scale.Scale = 0.97
	end)
	local function up()
		b.Image = if b.Active then art.Image else art.Disabled
		scale.Scale = 1
	end
	b.MouseButton1Up:Connect(up)
	b.MouseLeave:Connect(up)
	return b, l
end

function Kit.setEnabled(b: ImageButton, art: any, enabled: boolean)
	b.Active = enabled
	b.Image = if enabled then art.Image else art.Disabled
	local l = b:FindFirstChild("Label")
	if l and l:IsA("TextLabel") then
		l.TextTransparency = if enabled then 0 else 0.45
	end
end

-- A window on the clipboard art: title, close button, a content frame. Opens with a short fade and lift.
function Kit.window(parent: Instance, name: string, title: string): (Frame, Frame, ImageButton)
	local root = Kit.new("Frame", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.7, 0.92),
		Visible = false,
		Parent = parent,
	}) :: Frame
	Kit.new("UISizeConstraint", { MaxSize = Vector2.new(720, 470), MinSize = Vector2.new(420, 320), Parent = root })
	Kit.new("ImageLabel", {
		Name = "Board",
		Image = ART.Window.Image,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = ART.Window.Slice,
		SliceScale = 0.55,
		Size = UDim2.fromScale(1, 1),
		Parent = root,
	})
	Kit.text(root, title, {
		Name = "Title",
		FontFace = Kit.FONT.title,
		TextColor3 = Kit.COLOR.brass,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 30, 0, 38),
		Size = UDim2.new(0.6, 0, 0, 32),
		Max = 32,
	})
	local close = Kit.button(root, ART.DarkButton, "X", {
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -22, 0, 34),
		Size = UDim2.fromOffset(48, 44),
		TextSize = 24,
	})
	local body = Kit.new("Frame", {
		Name = "Body",
		Position = UDim2.new(0, 28, 0, 82),
		Size = UDim2.new(1, -56, 1, -100),
		ClipsDescendants = true,
		Parent = root,
	}) :: Frame
	return root, body, close
end

function Kit.show(root: GuiObject, visible: boolean)
	if visible == root.Visible then
		return
	end
	root.Visible = visible
	if visible then
		local target = root.Position
		root.Position = target + UDim2.fromOffset(0, 14)
		TweenService:Create(root, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = target,
		}):Play()
	end
end

-- $1,250
function Kit.money(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return "$" .. out
end

return Kit
