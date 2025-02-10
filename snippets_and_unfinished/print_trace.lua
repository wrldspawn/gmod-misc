if not _G.Color then include("includes/util/color.lua") end
local COLOR_PREFIX = Color(255, 0, 255)

oldInclude = oldInclude or include
oldRequire = oldRequire or require
oldAddCS = oldAddCS or AddCSLuaFile

function include(filename)
	MsgC(COLOR_PREFIX, "[INCLUDE] ")
	print(filename)

	local info = debug.getinfo(2, "Sln")
	if info then
		if info.what == "C" then
			print(string.format("  %s - [Native]", info.name or "???"))
		else
			print(string.format("  %s - %s:%i", info.name or "???", info.short_src or "???", info.currentline or -1))
		end
	end

	return oldInclude(filename)
end

function require(filename)
	MsgC(COLOR_PREFIX, "[REQUIRE] ")
	print(filename)

	local info = debug.getinfo(2, "Sln")
	if info then
		if info.what == "C" then
			print(string.format("  %s - [Native]", info.name or "???"))
		else
			print(string.format("  %s - %s:%i", info.name or "???", info.short_src or "???", info.currentline or -1))
		end
	end

	return oldRequire(filename)
end

function AddCSLuaFile(filename)
	MsgC(COLOR_PREFIX, "[ADDCS] ")
	print(filename)

	local info = debug.getinfo(2, "Sln")
	if info then
		if info.what == "C" then
			print(string.format("  %s - [Native]", info.name or "???"))
		else
			print(string.format("  %s - %s:%i", info.name or "???", info.short_src or "???", info.currentline or -1))
		end
	end

	return oldAddCS(filename)
end

do return end

oldMsgN = oldMsgN or MsgN
oldMsg = oldMsg or Msg
oldPrint = oldPrint or print
function print(...)
	oldPrint(...)

	local level = 2
	while true do
		local index = level - 1
		local indent = ("  "):rep(index)

		local info = debug.getinfo(level, "Sln")
		if not info then break end

		if info.what == "C" then
			oldMsgN(Format("%s%i. %s - [Native]", indent, index, info.name or "???"))
		else
			oldMsgN(Format("%s%i. %s - %s:%i", indent, index, info.name or "???", info.short_src or "???",
				info.currentline or -1))
		end

		level = level + 1
	end
end

local inMsgN = false
function MsgN(...)
	inMsgN = true
	oldMsgN(...)

	local level = 2
	while true do
		local index = level - 1
		local indent = ("  "):rep(index)

		local info = debug.getinfo(level, "Sln")
		if not info then break end

		if info.what == "C" then
			oldMsgN(Format("%s%i. %s - [Native]", indent, index, info.name or "???"))
		else
			oldMsgN(Format("%s%i. %s - %s:%i", indent, index, info.name or "???", info.short_src or "???",
				info.currentline or -1))
		end

		level = level + 1
	end
	inMsgN = false
end

function Msg(...)
	oldMsg(...)
	local args = { ... }
	for i, v in ipairs(args) do
		args[i] = tostring(v)
	end
	local str = table.concat(args, " ")

	if string.find(str, "\n$") and not inMsgN then
		local level = 2
		while true do
			local index = level - 1
			local indent = ("  "):rep(index)

			local info = debug.getinfo(level, "Sln")
			if not info then break end

			if info.what == "C" then
				oldMsgN(Format("%s%i. %s - [Native]", indent, index, info.name or "???"))
			else
				oldMsgN(Format("%s%i. %s - %s:%i", indent, index, info.name or "???", info.short_src or "???",
					info.currentline or -1))
			end

			level = level + 1
		end
	end
end
