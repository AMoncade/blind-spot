-- Studio, Edit only: draws the lobby screen (client Ui/Menu) into StarterGui.MenuPreview with a made-up profile, so it
-- can be looked at in the 3D viewport without a playtest. Run it through the Studio MCP or Ropilot in Edit:
--   _G.BS_PREVIEW = "Shop"   -- or "Daily", "Settings", nil for the bare lobby screen; "clear" removes the preview
--   return loadstring(game:GetService("HttpService"):GetAsync("http://127.0.0.1:34896/scripts/studio-ui-preview.luau?t=" .. os.clock(), true))()
local StarterGui = game:GetService("StarterGui")
local old = StarterGui:FindFirstChild("MenuPreview")
if old then
	old:Destroy()
end
if _G.BS_PREVIEW == "clear" then
	return "preview cleared"
end
local Client = game:GetService("StarterPlayer").StarterPlayerScripts.Client
if _G.BS_PREVIEW == "Shift" or _G.BS_PREVIEW == "Report" then
	-- the shift's interface: the watch, the camera status, the clipboard (and the 6 AM report)
	local Hud = require(Client.Controllers.Hud)
	local Tasks = require(Client.Controllers.Tasks)
	local gui = Instance.new("ScreenGui")
	gui.Name = "MenuPreview"
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local parts = Hud.build(gui)
	parts.clock.Text = "2:14 AM"
	parts.statusText.Text = "BLIND SPOT"
	parts.statusText.TextColor3 = Color3.fromRGB(150, 143, 130)
	-- off camera for a while: the edges darken, the signal bar is a third full
	for _, edge in parts.vignetteEdges do
		edge.BackgroundTransparency = 0.3
	end
	parts.signalFill.Size = UDim2.fromScale(0.35, 1)
	parts.signalFill.BackgroundColor3 = Color3.fromRGB(224, 160, 60)
	local clip = Tasks.build(gui)
	Tasks.fill(clip, {
		tasks = {
			{ id = "scan:R1", kind = "scan", label = "Scan checkpoint: Stall 14", done = true },
			{ id = "scan:R4", kind = "scan", label = "Scan checkpoint: Stairs door", done = false },
			{ id = "generator", kind = "fetch", label = "Restart the corridor generator", item = "fuel", done = false, carriedBy = 1 },
			{ id = "fuse", kind = "fetch", label = "Replace the fuse of camera 07", item = "fuse", done = false },
			{ id = "tape", kind = "fetch", label = "Bring the lost tape to the booth VCR", item = "tape", done = false },
		},
		held = { ["1"] = "fuel" },
	}, 1)
	if _G.BS_PREVIEW == "Report" then
		Hud.fillReport(parts, { night = 3, outcome = "cleared", unlocked = 4, tasks = 5, total = 5, deaths = 1, pay = 490 })
		parts.report.Visible = true
	end
	gui.Parent = StarterGui
	return "preview: " .. _G.BS_PREVIEW
end
local State = require(Client.State)
local Menu = require(Client.Ui.Menu)
State.profile = {
	pay = 1250,
	owned = { vf_classic = true, vf_amber = true },
	viewfinder = "vf_amber",
	settings = {},
	nights = 3,
	daily = { canClaim = true, streak = 3, slot = 3, lastStreak = 2, secondsLeft = 0 },
}
State.profileAt = os.time()
local gui = Instance.new("ScreenGui")
gui.Name = "MenuPreview"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local refresh = Menu.build(gui)
refresh()
local window = _G.BS_PREVIEW and gui:FindFirstChild(_G.BS_PREVIEW)
if window then
	window.Visible = true
end
gui.Parent = StarterGui
return "preview: " .. tostring(_G.BS_PREVIEW or "lobby")
