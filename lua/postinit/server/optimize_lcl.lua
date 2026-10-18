if not HolyLib then return end

local client_lua_files = stringtable.FindTable("client_lua_files")
local currentPaths = client_lua_files:GetStringUserData(0)
local paths = string.Split(currentPaths:sub(0, #currentPaths - 1), ";")
local newPaths = {}

for _, path in ipairs(paths) do
	if path:sub(1, 8) == "/addons/" and path:find("/gamemodes/$") then
		if not file.Exists(path:sub(2), "MOD") then continue end
	end

	newPaths[#newPaths + 1] = path
end

client_lua_files:SetStringUserData(0, table.concat(newPaths, ";") .. "\0")
