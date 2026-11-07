--!strict
-- The sound of the shift (plan section 8), on the modular audio API, all on the client:
--   the beds (hum, ventilation, the BLACKOUT drone, water drops) go through a low-pass that closes when the guard is
--     off camera ("le silence te trahit") and a fader that dies when the Unseen closes in (the hush, 1.5 s ahead);
--   the cues: a camera turning toward you, the lights dying, the radio's static, the tape tearing;
--   every cue that matters has a caption (plan section 2), shown even before its sound is uploaded.
-- A sound plays once its asset id is in content/sounds.csv (the files are assets/sounds/, made by
-- tools/audio/make_sounds.py).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Client = script.Parent.Parent
local State = require(Client:WaitForChild("State"))
local Kit = require(Client:WaitForChild("Ui"):WaitForChild("Kit"))

local C = Config.C
local player = Players.LocalPlayer

local SoundDirector = {}

local OPEN_HZ = 22000

local players: { [string]: AudioPlayer } = {}
local defs: { [string]: any } = {}
local filter: AudioFilter
local bedFader: AudioFader
local caption: TextLabel
local captionToken = 0

local function wire(a: Instance, b: Instance, parent: Instance)
	local w = Instance.new("Wire")
	w.SourceInstance = a
	w.TargetInstance = b
	w.Parent = parent
end

local function show(text: string)
	if text == "" then
		return
	end
	captionToken += 1
	local token = captionToken
	caption.Text = text
	caption.Visible = true
	task.delay(2.4, function()
		if captionToken == token then
			caption.Visible = false
		end
	end)
end

-- plays a cue (or starts a loop); its caption shows whether or not the sound exists yet
local function play(id: string, on: boolean?)
	local def = defs[id]
	local p = players[id]
	if on == false then
		if p and p.IsPlaying then
			p:Stop()
		end
		return
	end
	if def and not def.loop then
		show(def.caption)
	end
	if p then
		if def.loop then
			if not p.IsPlaying then
				p:Play()
			end
		else
			p.TimePosition = 0
			p:Play()
		end
	end
end

local function build()
	local root = Instance.new("Folder")
	root.Name = "BlindSpotAudio"
	local output = Instance.new("AudioDeviceOutput")
	output.Parent = root
	-- beds: player -> filter (off camera) -> fader (hush) -> output
	filter = Instance.new("AudioFilter")
	filter.FilterType = Enum.AudioFilterType.Lowpass12dB
	filter.Frequency = OPEN_HZ
	filter.Parent = root
	bedFader = Instance.new("AudioFader")
	bedFader.Volume = 1
	bedFader.Parent = root
	wire(filter, bedFader, root)
	wire(bedFader, output, root)
	-- cues: player -> fader -> output (never muffled: they are the signs)
	local cueFader = Instance.new("AudioFader")
	cueFader.Volume = 1
	cueFader.Parent = root
	wire(cueFader, output, root)
	for _, def in Config.Sounds do
		defs[def.id] = def
		if def.asset ~= "" then
			local p = Instance.new("AudioPlayer")
			p.Name = def.id
			p.Asset = "rbxassetid://" .. def.asset
			p.Looping = def.loop
			p.Volume = if def.id == "tension" then 0 else def.volume -- the tension music fades in (below)
			p.Parent = root
			-- the beds go through the muffle; the cues and the tension music never do
			local bed = (def.loop or def.id == "drip") and def.id ~= "tension"
			wire(p, if bed then filter else cueFader, root)
			players[def.id] = p
		end
	end
	root.Parent = SoundService
end

function SoundDirector.start()
	build()
	local gui = Kit.new("ScreenGui", {
		Name = "Captions",
		ResetOnSpawn = false,
		DisplayOrder = 9,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	}) :: ScreenGui
	caption = Kit.text(gui, "", {
		Name = "Caption",
		FontFace = Kit.FONT.paper,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -140),
		Size = UDim2.new(0.5, 0, 0, 22),
		Max = 18,
		Visible = false,
	})
	gui.Parent = player:WaitForChild("PlayerGui")

	local lastPhase = ""
	local lastFilmed = true
	local seen: { [string]: boolean } = {}
	local nextDrip = os.clock() + C.drip_min
	RunService.Heartbeat:Connect(function(dt: number)
		local _, seg = State.now()
		local phase = if State.shift and seg then seg.phase else "LOBBY"
		if phase ~= lastPhase then
			-- the beds follow the power: the hum stops in a BLACKOUT, the drone takes over
			play("hum", phase == "LIVE" or phase == "FLICKER")
			play("vent", phase ~= "LOBBY")
			play("drone", phase == "BLACKOUT")
			if phase == "BLACKOUT" then
				play("clack")
			end
			lastPhase = phase
		end
		-- off camera, the sound closes in (plan section 3: "le silence te trahit")
		local filmed = State.filmed or not State.shift
		if filmed ~= lastFilmed then
			lastFilmed = filmed
			TweenService:Create(filter, TweenInfo.new(C.muffle_seconds), {
				Frequency = if filmed then OPEN_HZ else C.muffle_hz,
			}):Play()
		end
		-- a camera starts filming you: its motor
		local now: { [string]: boolean } = {}
		for _, id in State.seenBy do
			now[id] = true
			if State.shift and not seen[id] then
				play("motor")
			end
		end
		seen = now
		-- the tension music swells as the signal bar drops (Adrien, 7 Nov), and fades back under a camera
		local tension = players.tension
		if tension then
			local alive = State.shift and not State.dead and not State.down
			local e = State.exposure
			local want = if alive
				then defs.tension.volume * math.clamp((C.tension_start - e) / C.tension_start, 0, 1)
				else 0
			tension.Volume += (want - tension.Volume) * math.min(1, dt * 2)
			if want > 0.01 and not tension.IsPlaying then
				tension:Play()
			elseif want <= 0.01 and tension.Volume < 0.01 and tension.IsPlaying then
				tension:Stop()
			end
		end
		if State.shift and os.clock() >= nextDrip then
			nextDrip = os.clock() + math.random(C.drip_min, C.drip_max)
			play("drip")
		end
	end)
	State.on("Hush", function(on: boolean)
		TweenService:Create(bedFader, TweenInfo.new(C.hush_seconds), {
			Volume = if on then C.hush_volume else 1,
		}):Play()
	end)
	State.on("Respawn", function()
		bedFader.Volume = 1
	end)
	State.on("Radio", function()
		play("static")
	end)
	State.on("Death", function()
		-- the tear comes with his lunge (Controllers/Death), after a moment of silence
		task.delay(C.catch_lunge, function()
			if State.dead then
				play("tear")
			end
		end)
	end)
end

return SoundDirector
