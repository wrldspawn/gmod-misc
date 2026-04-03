local active_gamemode = engine.ActiveGamemode()
local path = "cfg/" .. active_gamemode .. ".cfg"

if file.Exists(path, "MOD") then
	local f = file.Read(path, "MOD"):gsub("\r", "")
	for _, line in ipairs(string.Explode("\n", f)) do
		if line:match("^//") then continue end

		game.ConsoleCommand(line .. "\n")
	end
end
