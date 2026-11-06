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
local Net = require(Shared:WaitForChild("Net"))
local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Kit = require(script.Parent:WaitForChild("Kit"))

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

-- ---------------------------------------------------------------- SHOP

local function viewfinderPreview(parent: Instance, item: any)
	-- the camcorder's viewfinder in this item's colours: corner brackets, REC and the tape clock
	local screen = Kit.new("Frame", {
		Name = "Preview",
		BackgroundColor3 = Color3.fromRGB(10, 14, 11),
		BackgroundTransparency = 0,
		Size = UDim2.new(1, -16, 0, 60),
		Position = UDim2.new(0, 8, 0, 8),
		Parent = parent,
	})
	local frame = Color3.fromRGB(Config.rgb(item.frame))
	for _, a in { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } } do
		for _, horizontal in { true, false } do
			Kit.new("Frame", {
				BackgroundColor3 = frame,
				BackgroundTransparency = 0,
				AnchorPoint = Vector2.new(a[1], a[2]),
				Position = UDim2.new(0.06 + a[1] * 0.88, 0, 0.1 + a[2] * 0.8, 0),
				Size = if horizontal then UDim2.new(0.16, 0, 0, 2) else UDim2.new(0, 2, 0.24, 0),
				Parent = screen,
			})
		end
	end
	Kit.text(screen, "● REC", {
		FontFace = FONT.mono,
		TextColor3 = Color3.fromRGB(Config.rgb(item.rec)),
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0.12, 0, 0.18, 0),
		Size = UDim2.new(0.5, 0, 0.26, 0),
		Max = 14,
	})
	Kit.text(screen, "03:14", {
		FontFace = FONT.mono,
		TextColor3 = Color3.fromRGB(Config.rgb(item.text)),
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0.12, 0, 0.58, 0),
		Size = UDim2.new(0.4, 0, 0.24, 0),
		Max = 14,
	})
end

local function buildShop(gui: ScreenGui)
	local root, body, close = Kit.window(gui, "Shop", "SUPPLY ROOM")
	windows.Shop = root
	close.Activated:Connect(function()
		open(nil)
	end)
	Kit.text(body, "CAMCORDER VIEWFINDERS  ·  PAID FROM YOUR NIGHT SHIFTS", {
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
		if item.kind == "viewfinder" then
			viewfinderPreview(card, item)
		else
			local badge = Kit.new("Frame", {
				BackgroundColor3 = Color3.fromRGB(40, 30, 18),
				BackgroundTransparency = 0,
				Size = UDim2.new(1, -16, 0, 60),
				Position = UDim2.new(0, 8, 0, 8),
				Parent = card,
			})
			Kit.text(badge, if item.id == "vip" then "VIP" else "+25%", {
				FontFace = FONT.title,
				TextColor3 = COLOR.brass,
				Size = UDim2.fromScale(0.8, 0.6),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Max = 34,
			})
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
			if item.kind == "viewfinder" and profile and profile.owned[item.id] then
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
			elseif profile and profile.viewfinder == item.id then
				label.Text = "EQUIPPED"
				label.TextColor3 = COLOR.green
				Kit.setEnabled(buy, ART.DarkButton, false)
			elseif profile and profile.owned[item.id] then
				label.Text = "EQUIP"
				label.TextColor3 = COLOR.ink
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
	choices(4, "REC DOT WHEN FILMED", "RecDot", { false, true }, { "OFF", "ON" })

	local codeRow = row(5, "CODE")
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
		Size = UDim2.fromOffset(4 * 72, 74),
		Parent = gui,
	})
	-- a row under the pay: clear of the touch thumbstick (bottom left) and the jump button (bottom right)
	Kit.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
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
		Size = UDim2.new(0.64, 0, 1, 0),
		TextSize = 36,
	})
	local soloButton = Kit.button(bar, ART.DarkButton, "SOLO", {
		Name = "Solo",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0.33, 0, 0.84, 0),
		TextSize = 26,
	})
	playButton.Activated:Connect(function()
		open(nil)
		Net.send("Play", "group")
	end)
	soloButton.Activated:Connect(function()
		open(nil)
		Net.send("Play", "solo")
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

	buildShop(gui)
	buildDaily(gui)
	buildSettings(gui)

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
	State.on("Notice", function(text: string, good: boolean)
		State.notice(text, good)
	end)
	State.on("Shift", function(onShift: boolean)
		gui.Enabled = not onShift
		if onShift then
			open(nil)
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
