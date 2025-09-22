if not game.IsDedicated() then return end

local enabled = CreateConVar("oc_seasonal_lobby", "0", FCVAR_ARCHIVE)
if not enabled:GetBool() then return end

local lobby_map = GetConVar("oc_lobby_map")

local map = "winter_lobby_2012"
local date = os.date("!*t")

if date.month > 3 and date.month < 10 then
	map = "keyfox_lobby_summer"
end

lobby_map:SetString(map)

if game.GetMap() == "oc_lobby" then
	RunConsoleCommand("changelevel", map)
end
