--!strict
-- The lobby screen (only between shifts), laid out like the lobbies of the co-op horror hits (DOORS, Pressure): the
-- pay top left, a rail of object icons on the left (SHOP, DAILY, INVITE, SETTINGS; codes live in Settings), PLAY and
-- SOLO at the bottom centre, clear of the thumbstick and the jump button. Windows sit on the clipboard art.
-- The server decides everything (server Services/MenuService, LobbyService); this draws the profile and sends intents.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Difficulty = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Logic"):WaitForChild("Difficulty"))
local Upgrades = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Logic"):WaitForChild("Upgrades"))
local Net = require(Shared:WaitForChild("Net"))
local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local TapePlayer = require(script.Parent:WaitForChild("TapePlayer"))

local C = Config.C
local ART = Kit.ART
local COLOR = Kit.COLOR
local FONT = Kit.FONT
local player = Players.LocalPlayer

local Menu = {}

local windows: { [string]: Frame } = {}
local refreshers: { () -> () } = {}

local function open(name: string?)
	for key, w in windows do
		Kit.show(w, key == name and not w.Visible)
	end
end

-- ---------------------------------------------------------------- the rail and the pay

local function railButton(parent: Instance, icon: string, label: string, order: number, onClick: () -> ())
	local b = Kit.new("ImageButton", {
		Name = label,
		Image = "",
		AutoButtonColor = false,
		Size = UDim2.fromOffset(66, 74),
		LayoutOrder = order,
		Parent = parent,
	}) :: ImageButton
	local img = Kit.image(b, icon, {
		Name = "Icon",
		Size = UDim2.fromOffset(54, 54),
		Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
	})
	local plate = Kit.new("ImageLabel", {
		Image = ART.DarkButton.Image,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = ART.DarkButton.Slice,
		SliceScale = 0.12,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.fromOffset(66, 20),
		Parent = b,
	})
	Kit.text(plate, label, {
		FontFace = FONT.title,
		Size = UDim2.new(0.86, 0, 0.78, 0),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Max = 16,
	})
	local scale = Kit.new("UIScale", { Parent = img }) :: UIScale
	b.MouseEnter:Connect(function()
		scale.Scale = 1.06
	end)
	b.MouseLeave:Connect(function()
		scale.Scale = 1
	end)
	b.Activated:Connect(onClick)
	return b
end

-- ---------------------------------------------------------------- NEW SHIFT (the shift setup)

-- Adrien, 7 Nov: before a night, choose the chapter, the map, the night, how many guards and how many lives; the
-- screen shows how hard it is and what it pays (Logic/Difficulty, the same numbers the server uses at 6 AM).
local setup = { night = 1, guards = 1, lives = 1, chapter = 1, mode = Config.C.mode_default }

local function buildShift(gui: ScreenGui)
	local root, body, close = Kit.window(gui, "Setup", "NEW SHIFT")
	windows.Setup = root
	local limit = root:FindFirstChildOfClass("UISizeConstraint") :: UISizeConstraint
	limit.MaxSize = Vector2.new(820, 480)
	root.Size = UDim2.fromScale(0.86, 0.94)
	close.Activated:Connect(function()
		open(nil)
	end)

	-- left: the chapter and the map, as two picture cards
	local cards = Kit.new("Frame", { Name = "Cards", Size = UDim2.new(0.46, 0, 1, 0), Parent = body })
	local function card(order: number, name: string): (Frame, ImageLabel, TextLabel, TextLabel)
		local c = Kit.plate(cards, {
			Name = name,
			Position = UDim2.new(0, 0, (order - 1) * 0.5, if order == 1 then 0 else 4),
			Size = UDim2.new(1, 0, 0.5, -4),
			ClipsDescendants = true,
		})
		local art = Kit.image(c, "", {
			Name = "Art",
			ScaleType = Enum.ScaleType.Crop,
			Size = UDim2.fromScale(1, 1),
		})
		-- a dark band under the titles so they read on the picture
		Kit.new("Frame", {
			Name = "Band",
			BackgroundColor3 = COLOR.shadow,
			BackgroundTransparency = 0.25,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 40),
			Parent = c,
		})
		local title = Kit.text(c, "", {
			Name = "Title",
			FontFace = FONT.title,
			TextColor3 = COLOR.brass,
			TextXAlignment = Enum.TextXAlignment.Left,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 10, 1, -18),
			Size = UDim2.new(1, -20, 0, 20),
			Max = 20,
		})
		local sub = Kit.text(c, "", {
			Name = "Sub",
			FontFace = FONT.paper,
			TextColor3 = COLOR.ink,
			TextXAlignment = Enum.TextXAlignment.Left,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 10, 1, -3),
			Size = UDim2.new(1, -20, 0, 15),
			Max = 14,
		})
		return c, art, title, sub
	end
	local chapterCard, chapterArt, chapterTitle, chapterSub = card(1, "Chapter")
	local _, mapArt, mapTitle, mapSub = card(2, "Map")
	-- the chapter's arrows (the next chapters show locked)
	local function arrow(text: string, x: number, step: number)
		local b = Kit.button(chapterCard, ART.DarkButton, text, {
			Name = if step > 0 then "Next" else "Previous",
			AnchorPoint = Vector2.new(x, 0),
			Position = UDim2.new(x, if x == 0 then 6 else -6, 0, 6),
			Size = UDim2.fromOffset(44, 44),
			TextSize = 22,
		})
		b.Activated:Connect(function()
			setup.chapter = math.clamp(setup.chapter + step, 1, #Config.Chapters)
			for _, fn in refreshers do
				fn()
			end
		end)
	end
	arrow("<", 0, -1)
	arrow(">", 1, 1)
	local lock = Kit.text(chapterCard, "LOCKED", {
		Name = "Lock",
		FontFace = FONT.title,
		TextColor3 = COLOR.red,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.new(0.6, 0, 0, 34),
		Max = 32,
	})

	-- right: the night, the guards, the lives, the difficulty and START
	local side = Kit.new("Frame", {
		Name = "Setup",
		Position = UDim2.new(0.49, 0, 0, 0),
		Size = UDim2.new(0.51, 0, 1, 0),
		Parent = body,
	})
	Kit.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = side })
	local function row(order: number, title: string): Frame
		local r = Kit.plate(side, { Name = title, Size = UDim2.new(1, 0, 0, 46), LayoutOrder = order })
		Kit.text(r, title, {
			FontFace = FONT.title,
			TextColor3 = COLOR.dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 10, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.new(0.28, 0, 0, 20),
			Max = 18,
		})
		local options = Kit.new("Frame", {
			Name = "Options",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -4, 0.5, 0),
			Size = UDim2.new(0.7, 0, 0, 40),
			Parent = r,
		}) :: Frame
		return options
	end

	-- MODE: EASY · NORMAL · HARD (content/modes.csv): fewer cameras, darker, a faster bar, more pay
	do
		local options = row(0, "MODE")
		Kit.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder, -- EASY, NORMAL, HARD, NIGHTMARE (content/modes.csv order)
			Padding = UDim.new(0, 6),
			Parent = options,
		})
		local labels = {}
		for k, mode in Config.Modes do
			local b, l = Kit.button(options, ART.DarkButton, mode.name, {
				Name = "Mode" .. mode.name,
				Size = UDim2.new(1 / #Config.Modes, -6, 1, 0),
				LayoutOrder = k,
				TextSize = 15,
			})
			b.Activated:Connect(function()
				setup.mode = mode.id
				for _, fn in refreshers do
					fn()
				end
			end)
			labels[mode.id] = l
		end
		local colors = { easy = COLOR.green, normal = COLOR.brass, hard = COLOR.red, nightmare = COLOR.red }
		table.insert(refreshers, function()
			for id, l in labels do
				l.TextColor3 = if setup.mode == id then (colors :: any)[id] or COLOR.green else COLOR.dim
			end
		end)
	end

	-- NIGHT: < 3 · BLACKOUT >
	local nightRow = row(1, "NIGHT")
	local nightLabel = Kit.text(nightRow, "", {
		Name = "Night",
		FontFace = FONT.title,
		Position = UDim2.new(0, 50, 0, 0),
		Size = UDim2.new(1, -100, 1, 0),
		Max = 20,
	})
	local function nightButton(text: string, step: number, x: number)
		local b = Kit.button(nightRow, ART.DarkButton, text, {
			Name = if step > 0 then "NightUp" else "NightDown",
			AnchorPoint = Vector2.new(x, 0),
			Position = UDim2.fromScale(x, 0),
			Size = UDim2.fromOffset(44, 44),
			TextSize = 22,
		})
		b.Activated:Connect(function()
			local profile = State.profile :: any
			local unlocked = math.clamp((if profile then profile.bestNight or 0 else 0) + 1, 1, #Config.Nights)
			setup.night = math.clamp(setup.night + step, 1, unlocked)
			for _, fn in refreshers do
				fn()
			end
		end)
	end
	nightButton("<", -1, 0)
	nightButton(">", 1, 1)

	-- GUARDS and LIVES: one button per value, the chosen one lit
	local function pick(order: number, title: string, key: string, values: { number })
		local options = row(order, title)
		Kit.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 6),
			Parent = options,
		})
		local labels = {}
		for k, v in values do
			local b, l = Kit.button(options, ART.DarkButton, tostring(v), {
				Name = title .. v,
				Size = UDim2.new(1 / #values, -6, 1, 0),
				LayoutOrder = k,
				TextSize = 22,
			})
			b.Activated:Connect(function()
				local chosen: any = setup
				chosen[key] = v
				for _, fn in refreshers do
					fn()
				end
			end)
			labels[k] = l
		end
		table.insert(refreshers, function()
			for k, l in labels do
				local chosen: any = setup
				l.TextColor3 = if chosen[key] == values[k] then COLOR.green else COLOR.dim
			end
		end)
	end
	local guardValues = {}
	for k = 1, C.lift_capacity do
		guardValues[k] = k
	end
	pick(2, "GUARDS", "guards", guardValues)
	-- one life for everyone (Adrien, 8 Nov): no LIVES row

	-- the difficulty and what it pays
	local diff = Kit.plate(side, { Name = "Difficulty", Size = UDim2.new(1, 0, 0, 36), LayoutOrder = 4 })
	local diffText = Kit.text(diff, "", {
		Name = "Text",
		FontFace = FONT.title,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(0.6, 0, 0, 24),
		Max = 22,
	})
	local payText = Kit.text(diff, "", {
		Name = "Pay",
		FontFace = FONT.mono,
		TextColor3 = COLOR.green,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0.4, 0, 0, 22),
		Max = 20,
	})

	local start, startLabel = Kit.button(side, ART.PlayButton, "START", {
		Name = "Start",
		Size = UDim2.new(1, 0, 0, 48),
		LayoutOrder = 5,
		TextSize = 30,
	})
	start.Activated:Connect(function()
		local chapter = Config.Chapters[setup.chapter]
		if chapter and chapter.locked then
			return
		end
		open(nil)
		Net.send("Play", { night = setup.night, guards = setup.guards, lives = setup.lives, mode = setup.mode })
	end)

	table.insert(refreshers, function()
		local profile = State.profile :: any
		local unlocked = math.clamp((if profile then profile.bestNight or 0 else 0) + 1, 1, #Config.Nights)
		setup.night = math.clamp(setup.night, 1, unlocked)
		local chapter = Config.Chapters[setup.chapter]
		local art = ART :: any
		chapterArt.Image = art[chapter.art] or ""
		mapArt.Image = art[chapter.mapArt] or ""
		chapterArt.ImageTransparency = if chapter.locked then 0.7 else 0
		mapArt.ImageTransparency = if chapter.locked then 0.7 else 0
		chapterTitle.Text = `CHAPTER {setup.chapter}  ·  {chapter.name}`
		chapterSub.Text = if chapter.locked then "Coming soon" else `{#Config.Nights} nights`
		mapTitle.Text = `MAP  ·  {chapter.map}`
		mapSub.Text = chapter.mapNote
		lock.Visible = chapter.locked
		local def = Config.nightByNumber[setup.night]
		nightLabel.Text = `{setup.night}  ·  {def.name}`
		local mult = Difficulty.payMultiplier(setup, Config.nightByNumber, C, Config.modeById)
		-- the mode's line (one life for everyone: the mode is the difficulty)
		local mode = Config.modeById[setup.mode] or Config.modeById[C.mode_default]
		diffText.Text = mode.blurb
		diffText.TextColor3 = if mode.id == "easy"
			then COLOR.green
			elseif mode.id == "normal" then COLOR.brass
			else COLOR.red
		payText.Text = string.format("PAY ×%.2f", mult)
		Kit.setEnabled(start, ART.PlayButton, not chapter.locked)
		startLabel.Text = if chapter.locked then "LOCKED" else "START"
	end)
end

-- ---------------------------------------------------------------- K&V SUPPLY (the upgrades)

-- Adrien, 8 Nov: the shop east of the hall. Its prompts open this screen (event OpenUpgrades); one row per upgrade
-- (content/upgrades.csv): its level, what it gives now and at the next level, and the price (Logic/Upgrades).
local upgradeRows: { [string]: Frame } = {}

local function formatValue(v: number, unit: string): string
	if string.sub(unit, 1, 1) == "x" then
		return string.format("×%.2f", v) .. string.sub(unit, 2)
	elseif string.sub(unit, 1, 1) == "s" then
		return string.format("%gs", v) .. string.sub(unit, 2)
	end
	return string.format("%g ", v) .. unit
end

local function describe(def: any, level: number): string
	local v, v2 = Upgrades.value(def, level)
	local text = formatValue(v, def.unit)
	if v2 and def.unit2 ~= "" then
		text ..= "  ·  " .. formatValue(v2, def.unit2)
	end
	return text
end

local function buildUpgrades(gui: ScreenGui)
	local root, body, close = Kit.window(gui, "Upgrades", "K&V SUPPLY")
	windows.Upgrades = root
	close.Activated:Connect(function()
		open(nil)
	end)
	local list = Kit.new("ScrollingFrame", {
		Name = "Rows",
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = COLOR.brass,
		Parent = body,
	})
	Kit.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	Kit.new("UIPadding", { PaddingRight = UDim.new(0, 8), Parent = list })
	for k, def in Config.Upgrades do
		local row = Kit.plate(list, { Name = def.id, Size = UDim2.new(1, 0, 0, 70), LayoutOrder = k })
		upgradeRows[def.id] = row
		Kit.image(row, (ART :: any)[def.art] or "", {
			Name = "Icon",
			Size = UDim2.fromOffset(60, 60),
			Position = UDim2.new(0, 6, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
		})
		Kit.text(row, def.name, {
			Name = "Name",
			FontFace = FONT.title,
			TextColor3 = COLOR.brass,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 74, 0, 6),
			Size = UDim2.new(0.3, 0, 0, 22),
			Max = 22,
		})
		local level = Kit.text(row, "", {
			Name = "Level",
			FontFace = FONT.mono,
			TextColor3 = COLOR.green,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0.33, 74, 0, 8),
			Size = UDim2.new(0.3, 0, 0, 18),
			Max = 16,
		})
		local effect = Kit.text(row, "", {
			Name = "Effect",
			FontFace = FONT.paper,
			TextColor3 = COLOR.ink,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 74, 0, 32),
			Size = UDim2.new(1, -230, 0, 16),
			Max = 15,
		})
		local blurb = Kit.text(row, def.blurb, {
			Name = "Blurb",
			FontFace = FONT.paper,
			TextColor3 = COLOR.dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 74, 0, 50),
			Size = UDim2.new(1, -230, 0, 14),
			Max = 13,
		})
		blurb.TextStrokeTransparency = 1
		local buy, buyLabel = Kit.button(row, ART.DarkButton, "", {
			Name = "Buy",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset(140, 48),
			TextSize = 20,
		})
		buy.Activated:Connect(function()
			Net.send("Upgrade", def.id)
		end)
		local stroke = row:FindFirstChildOfClass("UIStroke") :: UIStroke
		table.insert(refreshers, function()
			local profile = State.profile :: any
			local lv = Upgrades.level(profile, def.id)
			level.Text = `LEVEL {lv}/{def.max}  ` .. string.rep("■", lv) .. string.rep("□", def.max - lv)
			local cost = Upgrades.cost(def, lv)
			if cost then
				effect.Text = describe(def, lv) .. "   →   " .. describe(def, lv + 1)
				buyLabel.Text = Kit.money(cost)
				buyLabel.TextColor3 = if profile and profile.pay >= cost then COLOR.brass else COLOR.dim
				Kit.setEnabled(buy, ART.DarkButton, true)
			else
				effect.Text = describe(def, lv)
				buyLabel.Text = "MAX"
				buyLabel.TextColor3 = COLOR.green
				Kit.setEnabled(buy, ART.DarkButton, false)
			end
			stroke.Color = if root:GetAttribute("Focus") == def.id then COLOR.brass else COLOR.plateEdge
			stroke.Thickness = if root:GetAttribute("Focus") == def.id then 2 else 1
		end)
	end
end

-- ---------------------------------------------------------------- SHOP

local function buildShop(gui: ScreenGui)
	local root, body, close = Kit.window(gui, "Shop", "SUPPLY ROOM")
	windows.Shop = root
	close.Activated:Connect(function()
		open(nil)
	end)
	Kit.text(body, "VIEWFINDERS  ·  UNIFORMS  ·  LAMPS  ·  UPGRADES: K&V SUPPLY, EAST OF THE HALL", {
		FontFace = FONT.paper,
		TextColor3 = COLOR.dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 20),
		Max = 16,
	})
	local list = Kit.new("ScrollingFrame", {
		Name = "Cards",
		Position = UDim2.new(0, 0, 0, 28),
		Size = UDim2.new(1, 0, 1, -28),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = COLOR.brass,
		Parent = body,
	})
	Kit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = list,
	})
	Kit.new("UIPadding", { PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 2), Parent = list })

	for k, item in Config.Shop do
		local card = Kit.plate(list, { Name = item.id, Size = UDim2.new(0, 156, 1, -10), LayoutOrder = k })
		-- the item's illustration in a dark well; a viewfinder shows its two colours under it
		local well = Kit.new("Frame", {
			Name = "Well",
			BackgroundColor3 = Color3.fromRGB(12, 11, 12),
			BackgroundTransparency = 0,
			Size = UDim2.new(1, -16, 0, 60),
			Position = UDim2.new(0, 8, 0, 8),
			Parent = card,
		})
		Kit.image(well, (ART :: any)[item.art] or ART.ShopIcon, {
			Name = "Art",
			Size = UDim2.new(1, 0, 1, 10),
			Position = UDim2.new(0.5, 0, 0.5, -2),
			AnchorPoint = Vector2.new(0.5, 0.5),
		})
		local cosmetic = item.kind == "viewfinder" or item.kind == "uniform" or item.kind == "lamp"
		if cosmetic then
			for n, hex in (if item.kind == "lamp" then { item.frame } else { item.frame, item.rec }) do
				Kit.new("Frame", {
					BackgroundColor3 = Color3.fromRGB(Config.rgb(hex)),
					BackgroundTransparency = 0,
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.new(1, -4 - (n - 1) * 12, 1, -4),
					Size = UDim2.fromOffset(9, 9),
					Parent = well,
				})
			end
		end
		Kit.text(card, string.upper(item.name), {
			FontFace = FONT.title,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 10, 0, 72),
			Size = UDim2.new(1, -20, 0, 22),
			Max = 22,
		})
		local blurb = Kit.text(card, item.blurb, {
			FontFace = FONT.paper,
			TextColor3 = COLOR.dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			Position = UDim2.new(0, 10, 0, 96),
			Size = UDim2.new(1, -20, 1, -150),
			Max = 14,
		})
		blurb.TextStrokeTransparency = 1
		local buy, label = Kit.button(card, ART.DarkButton, "", {
			Name = "Buy",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.new(1, -16, 0, 44),
			TextSize = 20,
		})
		buy.Activated:Connect(function()
			local profile = State.profile
			if cosmetic and profile and profile.owned[item.id] then
				Net.send("Equip", item.id)
			else
				Net.send("Buy", item.id)
			end
		end)
		table.insert(refreshers, function()
			local profile = State.profile
			if item.kind == "robux" then
				label.Text = if item.product ~= 0 then "R$" else "SOON"
				Kit.setEnabled(buy, ART.DarkButton, item.product ~= 0)
			elseif profile and cosmetic and (profile :: any)[item.kind] == item.id then
				label.Text = "EQUIPPED"
				label.TextColor3 = COLOR.green
				Kit.setEnabled(buy, ART.DarkButton, false)
			elseif profile and profile.owned[item.id] then
				label.Text = "EQUIP"
				label.TextColor3 = COLOR.ink
				Kit.setEnabled(buy, ART.DarkButton, true)
			elseif item.unlock == "group" then
				label.Text = "GROUP"
				label.TextColor3 = COLOR.brass
				Kit.setEnabled(buy, ART.DarkButton, true)
			else
				label.Text = Kit.money(item.price)
				label.TextColor3 = if profile and profile.pay >= item.price then COLOR.brass else COLOR.dim
				Kit.setEnabled(buy, ART.DarkButton, true)
			end
		end)
	end
end

-- ---------------------------------------------------------------- DAILY

local function buildDaily(gui: ScreenGui)
	local root, body, close = Kit.window(gui, "Daily", "DAILY PAY")
	windows.Daily = root
	close.Activated:Connect(function()
		open(nil)
	end)
	Kit.text(body, "COME BACK EVERY NIGHT. MISS ONE AND THE WEEK STARTS OVER.", {
		FontFace = FONT.paper,
		TextColor3 = COLOR.dim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 20),
		Max = 16,
	})
	local row = Kit.new("Frame", { Position = UDim2.new(0, 0, 0, 28), Size = UDim2.new(1, 0, 1, -92), Parent = body })
	Kit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0.012, 0),
		Parent = row,
	})
	local tiles = {}
	for _, d in Config.Daily do
		-- a torn calendar page per day
		local tile = Kit.new("Frame", {
			Name = "Day" .. d.day,
			BackgroundColor3 = COLOR.paper,
			BackgroundTransparency = 0,
			Size = UDim2.new(0.13, 0, 1, 0),
			LayoutOrder = d.day,
			Parent = row,
		}) :: Frame
		Kit.new("UICorner", { CornerRadius = UDim.new(0, 2), Parent = tile })
		local edge = Kit.new("UIStroke", { Color = COLOR.red, Thickness = 0, Parent = tile }) :: UIStroke
		Kit.new("Frame", {
			BackgroundColor3 = Color3.fromRGB(150, 44, 34),
			BackgroundTransparency = 0,
			Size = UDim2.new(1, 0, 0.16, 0),
			Parent = tile,
		})
		local dayLabel = Kit.text(tile, "DAY " .. d.day, {
			FontFace = FONT.paper,
			TextColor3 = COLOR.paperInk,
			TextStrokeTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.3, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0.9, 0, 0.18, 0),
			Max = 18,
		})
		Kit.text(tile, Kit.money(d.pay), {
			FontFace = FONT.mono,
			TextColor3 = COLOR.paperInk,
			TextStrokeTransparency = 1,
			Position = UDim2.new(0.5, 0, 0.62, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0.9, 0, 0.2, 0),
			Max = 22,
		})
		local stamp = Kit.text(tile, "PAID", {
			FontFace = FONT.title,
			TextColor3 = COLOR.red,
			TextStrokeTransparency = 1,
			Rotation = -14,
			Position = UDim2.new(0.5, 0, 0.84, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0.9, 0, 0.2, 0),
			Max = 22,
			Visible = false,
		})
		tiles[d.day] = { tile = tile, edge = edge, stamp = stamp, label = dayLabel }
	end
	local claim, claimLabel = Kit.button(body, ART.PlayButton, "CLAIM", {
		Name = "Claim",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -4),
		Size = UDim2.fromOffset(280, 52),
		TextSize = 26,
	})
	claim.Activated:Connect(function()
		Net.send("ClaimDaily")
	end)
	table.insert(refreshers, function()
		local profile = State.profile
		if not profile then
			return
		end
		local daily = profile.daily
		-- days already paid this week: before today's slot (or up to it once claimed)
		local paidUpTo = if daily.canClaim then daily.slot - 1 else daily.slot
		for day, t in tiles do
			t.stamp.Visible = day <= paidUpTo
			t.edge.Thickness = if day == daily.slot then 3 else 0
			t.tile.BackgroundTransparency = if day <= paidUpTo then 0.25 else 0
		end
		Kit.setEnabled(claim, ART.PlayButton, daily.canClaim)
		if daily.canClaim then
			claimLabel.Text = "CLAIM  " .. Kit.money(Config.Daily[daily.slot].pay)
		else
			local s = math.max(0, math.floor(daily.secondsLeft - (os.time() - (State.profileAt or os.time()))))
			claimLabel.Text = string.format("NEXT IN %02d:%02d:%02d", s // 3600, (s // 60) % 60, s % 60)
		end
	end)
end

-- ---------------------------------------------------------------- SETTINGS (and codes)

local function buildSettings(gui: ScreenGui)
	local root, body, close = Kit.window(gui, "Settings", "SETTINGS")
	windows.Settings = root
	close.Activated:Connect(function()
		open(nil)
	end)
	local list = Kit.new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = COLOR.brass,
		Parent = body,
	})
	Kit.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	Kit.new("UIPadding", { PaddingRight = UDim.new(0, 8), Parent = list })

	local function row(order: number, title: string): Frame
		local r = Kit.plate(list, { Size = UDim2.new(1, 0, 0, 50), LayoutOrder = order })
		Kit.text(r, title, {
			FontFace = FONT.title,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 12, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.new(0.42, 0, 0, 24),
			Max = 22,
		})
		local options = Kit.new("Frame", {
			Name = "Options",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6, 0.5, 0),
			Size = UDim2.new(0.56, 0, 0, 44),
			Parent = r,
		}) :: Frame
		Kit.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 6),
			Parent = options,
		})
		return options
	end

	local function choices(order: number, title: string, name: string, values: { any }, labels: { string })
		local options = row(order, title)
		local buttons = {}
		for k, v in values do
			local b, l = Kit.button(options, ART.DarkButton, labels[k], {
				Size = UDim2.new(1 / #values, -6, 1, 0),
				LayoutOrder = k,
				TextSize = 20,
			})
			b.Activated:Connect(function()
				Net.send("SetSetting", name, v)
				player:SetAttribute(name, v)
			end)
			buttons[k] = l
		end
		table.insert(refreshers, function()
			if not player then
				return -- the Edit preview has no player
			end
			local current = player:GetAttribute(name)
			for k, l in buttons do
				l.TextColor3 = if values[k] == current then COLOR.green else COLOR.dim
			end
		end)
	end

	local bobLabels, fovLabels = {}, {}
	for _, v in C.settings_bob_steps do
		table.insert(bobLabels, math.floor(v * 100) .. "%")
	end
	for _, v in C.settings_fov_steps do
		table.insert(fovLabels, tostring(v))
	end
	choices(1, "HEAD BOB", "HeadBob", C.settings_bob_steps, bobLabels)
	choices(2, "FIELD OF VIEW", "FieldOfView", C.settings_fov_steps, fovLabels)
	choices(3, "REDUCE FLASHES", "ReduceFlashes", { false, true }, { "OFF", "ON" })
	choices(4, "CAMERA STATUS", "RecDot", { false, true }, { "OFF", "ON" })
	choices(5, "SAFE ZONES ON FLOOR", "SafeZones", { false, true }, { "OFF", "ON" })

	local codeRow = row(6, "CODE")
	local box = Kit.new("TextBox", {
		Name = "Code",
		BackgroundColor3 = COLOR.paper,
		BackgroundTransparency = 0,
		FontFace = FONT.paper,
		PlaceholderText = "TYPE A CODE",
		PlaceholderColor3 = Color3.fromRGB(120, 112, 98),
		Text = "",
		TextColor3 = COLOR.paperInk,
		TextScaled = true,
		ClearTextOnFocus = false,
		Size = UDim2.new(0.6, -6, 1, 0),
		LayoutOrder = 1,
		Parent = codeRow,
	}) :: TextBox
	Kit.new("UITextSizeConstraint", { MaxTextSize = 20, MinTextSize = 10, Parent = box })
	Kit.new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = box })
	local redeem = Kit.button(codeRow, ART.PlayButton, "REDEEM", {
		Size = UDim2.new(0.4, 0, 1, 0),
		LayoutOrder = 2,
		TextSize = 20,
	})
	redeem.Activated:Connect(function()
		if #box.Text > 0 then
			Net.send("Redeem", box.Text)
			box.Text = ""
		end
	end)
end

-- ---------------------------------------------------------------- TAPES

local function buildTapes(gui: ScreenGui)
	local root, body, close = Kit.window(gui, "Tapes", "THE TAPES")
	windows.Tapes = root
	close.Activated:Connect(function()
		open(nil)
	end)
	local list = Kit.new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = COLOR.brass,
		Parent = body,
	})
	Kit.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	Kit.new("UIPadding", { PaddingRight = UDim.new(0, 8), Parent = list })
	for k, tape in Config.Tapes do
		local row = Kit.plate(list, { Size = UDim2.new(1, 0, 0, 52), LayoutOrder = k })
		local title = Kit.text(row, "", {
			FontFace = FONT.title,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 12, 0, 6),
			Size = UDim2.new(0.62, 0, 0, 22),
			Max = 20,
		})
		local stamp = Kit.text(row, "", {
			FontFace = FONT.mono,
			TextColor3 = COLOR.dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 12, 0, 30),
			Size = UDim2.new(0.62, 0, 0, 16),
			Max = 13,
		})
		local play, playLabel = Kit.button(row, ART.DarkButton, "PLAY", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6, 0.5, 0),
			Size = UDim2.fromOffset(120, 44),
			TextSize = 20,
		})
		play.Activated:Connect(function()
			local profile = State.profile
			if profile and profile.tapes and profile.tapes[tape.id] then
				open(nil)
				TapePlayer.play(tape)
			end
		end)
		table.insert(refreshers, function()
			local profile = State.profile
			local found = profile and profile.tapes and profile.tapes[tape.id]
			title.Text = if found then `{k}. {tape.title}` else `{k}. ???`
			stamp.Text = if found then tape.stamp else "LOST SOMEWHERE ON P3"
			playLabel.Text = if found then "PLAY" else "LOCKED"
			Kit.setEnabled(play, ART.DarkButton, found == true)
		end)
	end
end

-- ---------------------------------------------------------------- INVITE

local function invite()
	local ok, can = pcall(function()
		return SocialService:CanSendGameInviteAsync(player)
	end)
	if ok and can then
		pcall(function()
			SocialService:PromptGameInvite(player)
		end)
	else
		State.notice("INVITES AREN'T AVAILABLE HERE", false)
	end
end

-- ---------------------------------------------------------------- the screen

-- Builds the whole screen into gui and returns its refresh and the PLAY bar. Studio previews it in Edit with a
-- made-up profile (scripts/studio-ui-preview.luau); Menu.start wires it to the player.
function Menu.build(gui: ScreenGui): (() -> (), GuiObject)
	-- the pay
	local pay = Kit.new("ImageLabel", {
		Name = "Pay",
		Image = ART.DarkButton.Image,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = ART.DarkButton.Slice,
		SliceScale = 0.18,
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.fromOffset(176, 50),
		Parent = gui,
	})
	Kit.image(pay, ART.PayIcon, {
		Size = UDim2.fromOffset(58, 58),
		Position = UDim2.new(0, -10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
	})
	local payText = Kit.text(pay, "$0", {
		Name = "Amount",
		FontFace = FONT.mono,
		TextColor3 = COLOR.green,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 54, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(1, -64, 0.56, 0),
		Max = 24,
	})

	-- the rail
	local rail = Kit.new("Frame", {
		Name = "Rail",
		Position = UDim2.fromOffset(10, 66),
		Size = UDim2.fromOffset(3 * 72, 2 * 80),
		Parent = gui,
	})
	-- two rows of three under the pay (Adrien, 7 Nov: one long strip looked odd), clear of the touch thumbstick
	-- (bottom left) and the jump button (bottom right)
	Kit.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(66, 74),
		CellPadding = UDim2.fromOffset(6, 6),
		FillDirectionMaxCells = 3,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = rail,
	})
	railButton(rail, ART.ShopIcon, "SHOP", 1, function()
		open("Shop")
	end)
	local dailyButton = railButton(rail, ART.DailyIcon, "DAILY", 2, function()
		open("Daily")
	end)
	railButton(rail, ART.InviteIcon, "INVITE", 3, invite)
	railButton(rail, ART.SettingsIcon, "SETTINGS", 4, function()
		open("Settings")
	end)
	railButton(rail, ART.TapesIcon, "TAPES", 5, function()
		open("Tapes")
	end)
	-- a red dot on DAILY when a claim is waiting
	local dot = Kit.new("Frame", {
		Name = "Ready",
		BackgroundColor3 = COLOR.red,
		BackgroundTransparency = 0,
		Position = UDim2.fromOffset(48, 0),
		Size = UDim2.fromOffset(14, 14),
		Visible = false,
		Parent = dailyButton,
	})
	Kit.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })

	-- PLAY and SOLO
	local bar = Kit.new("Frame", {
		Name = "PlayBar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.fromOffset(380, 62),
		Parent = gui,
	})
	local playButton = Kit.button(bar, ART.PlayButton, "PLAY", {
		Name = "Play",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(0.7, 0, 1, 0),
		TextSize = 36,
	})
	-- PLAY opens the shift setup (chapter, map, night, guards, lives); START there takes the lift
	playButton.Activated:Connect(function()
		open("Setup")
	end)

	-- the notice
	local notice = Kit.new("ImageLabel", {
		Name = "Notice",
		Image = ART.DarkButton.Image,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = ART.DarkButton.Slice,
		SliceScale = 0.18,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(320, 44),
		Visible = false,
		ZIndex = 5,
		Parent = gui,
	})
	local noticeText = Kit.text(notice, "", {
		FontFace = FONT.title,
		Size = UDim2.new(0.9, 0, 0.6, 0),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Max = 22,
		ZIndex = 6,
	})
	local noticeToken = 0
	function State.notice(text: string, good: boolean)
		noticeToken += 1
		local token = noticeToken
		noticeText.Text = text
		noticeText.TextColor3 = if good then COLOR.green else COLOR.ink
		notice.Visible = true
		task.delay(2.6, function()
			if noticeToken == token then
				notice.Visible = false
			end
		end)
	end

	buildShift(gui)
	buildUpgrades(gui)
	buildShop(gui)
	buildDaily(gui)
	buildSettings(gui)
	buildTapes(gui)

	local function refresh()
		local profile = State.profile :: any
		if profile then
			payText.Text = Kit.money(profile.pay)
			dot.Visible = profile.daily.canClaim
		end
		for _, fn in refreshers do
			fn()
		end
	end
	return refresh, bar
end

function Menu.start()
	local gui = Kit.new("ScreenGui", {
		Name = "Menu",
		ResetOnSpawn = false,
		DisplayOrder = 4,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}) :: ScreenGui
	local refresh, bar = Menu.build(gui)
	State.on("Profile", refresh)
	-- Adrien, 7 Nov: the game opens on the shift setup
	local opened = false
	State.on("Profile", function()
		if not opened and not State.shift then
			opened = true
			open("Setup")
		end
	end)
	State.on("Notice", function(text: string, good: boolean)
		State.notice(text, good)
	end)
	-- a K&V SUPPLY prompt: the upgrade screen, the stand's upgrade lit
	State.on("OpenUpgrades", function(id: string?)
		windows.Upgrades:SetAttribute("Focus", id or "")
		refresh()
		if not windows.Upgrades.Visible then
			open("Upgrades")
		end
	end)
	State.on("Shift", function(onShift: boolean)
		gui.Enabled = not onShift
		if onShift then
			open(nil)
		end
	end)
	-- walked into an empty lift: the shift setup, as PLAY opens it
	State.on("OpenSetup", function()
		-- open, never toggle (it may already be up: it opens on the first visit too)
		if not State.shift and not windows.Setup.Visible then
			open("Setup")
		end
	end)
	State.on("Lift", function(info: any)
		bar.Visible = info == nil
		if info then
			open(nil)
		end
	end)
	player:GetAttributeChangedSignal("HeadBob"):Connect(refresh)
	player:GetAttributeChangedSignal("FieldOfView"):Connect(refresh)
	player:GetAttributeChangedSignal("ReduceFlashes"):Connect(refresh)
	player:GetAttributeChangedSignal("RecDot"):Connect(refresh)
	player:GetAttributeChangedSignal("SafeZones"):Connect(refresh)
	-- the daily countdown ticks
	task.spawn(function()
		while true do
			task.wait(1)
			if windows.Daily.Visible then
				refresh()
			end
		end
	end)
	gui.Enabled = not State.shift
	gui.Parent = player:WaitForChild("PlayerGui")
	refresh()
	Net.send("Profile")
end

return Menu
