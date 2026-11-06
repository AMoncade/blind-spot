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
