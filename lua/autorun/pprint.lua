include("clib/pprint.lua")
include("clib/syntax_parser.lua")

if CLIENT then
	function PrettyPrintOnServer(line, ...)
		local out = prettyprint.toStringWithColor(...)
		local data = util.Compress(out)
		local len = #data
		net.Start("PrettyPrintOnServer")
		net.WriteString(line)
		net.WriteInt(len, 32)
		net.WriteData(data, len)
		net.SendToServer()
	end

	local commands = { "sv", "sh", "clients", "self", "both", "cl", "file" }
	for _, cmd in ipairs(commands) do
		concommand.Add("pprint_" .. cmd, function(_, cmdName, _, argStr)
			LocalPlayer():ConCommand("cmd " .. cmdName .. " " .. argStr)
		end)
	end

	return
end

local pp = "PrettyPrint" -- hehe pp

local function tagline(ply, target)
	MsgC(Color(255, 181, 80), "[")

	for i = 1, pp:len() do
		local hue = ((i - 1) / pp:len()) * 360
		MsgC(HSVToColor(hue, 0.375, 1), pp:sub(i, i))
	end

	MsgC(Color(255, 181, 80), (": %s -> %s] "):format(ply, target))
end

local function tagline1(target)
	MsgC(Color(255, 181, 80), "[")

	for i = 1, pp:len() do
		local hue = ((i - 1) / pp:len()) * 360
		MsgC(HSVToColor(hue, 0.375, 1), pp:sub(i, i))
	end

	MsgC(Color(255, 181, 80), (": %s] "):format(target))
end

local function showLine(line)
	if syntaxParser then
		local parsed = syntaxParser.parseText(line)
		parsed.Print()
		MsgN("")
	else
		print(line)
	end
end

util.AddNetworkString("PrettyPrintOnServer")

net.Receive("PrettyPrintOnServer", function(len, ply)
	if not IsValid(ply) then return end
	if not ply:IsAdmin() then return end

	tagline(_G.me:Name(), ply:Name())
	local line = net.ReadString()
	showLine(line)

	local dlen = net.ReadInt(32)
	local data = net.ReadData(dlen)
	local str = util.Decompress(data)

	if not str then return end

	local out = {}
	local pattern = "\x0E(.-)\x0F"
	local parts = string.Explode(pattern, str, true)
	local index = 1

	for col in string.gmatch(str, pattern) do
		table.insert(out, parts[index])
		index = index + 1

		if col then
			local r, g, b, a = unpack(string.Explode(" ", col))
			r = tonumber(r) or 255
			g = tonumber(g) or 255
			b = tonumber(b) or 255
			a = tonumber(a) or 255
			table.insert(out, Color(r, g, b, a))
		end
	end

	table.insert(out, parts[#parts])
	table.insert(out, Color(255, 255, 255))
	MsgC(unpack(out))
end)

local function add(cmd, callback)
	concommand.Add("pprint_" .. cmd, function(ply, _, _, argStr)
		local a, b
		easylua.End()
		local ret, why = callback(ply, argStr)

		if not ret then
			if why == false then
				a, b = false, why
			elseif isstring(why) then
				ply:ChatPrint("FAILED: " .. why)
				a, b = false, why
			end
		end

		easylua.Start(ply)

		return a, b
	end)
end

local function X(ply, i)
	return luadev.GetPlayerIdentifier(ply, "cmd:" .. i)
end

local function pprint(line, id)
	line = line:gsub("\n", " ")
	id = id or "pprint_eval"

	local script = string.format([[local toEval = %q
local id = %q

local function compile(code, id)
	local fullCode = "return function() " .. code .. "\nend"
	local compiled = CompileString(fullCode, id, false)

	if isstring(compiled) then
		return nil, compiled
	end

	local f = compiled()

	if not f then
		return nil, "Unexpected error."
	end

	return f
end

local eval = compile("return " .. toEval, id)

if not eval then
	local f, err = compile(toEval, id)
	eval = f
	if err then
		ErrorNoHalt(id .. ": " .. err)
		return
	end
end

if eval then
	setfenv(eval, easylua.EnvMeta)

	local func = prettyprint.show
	if CLIENT then
		func = function(...) PrettyPrintOnServer(toEval, ...) end
	end
	prettyprint.StartLimit()
	func(eval())
	prettyprint.EndLimit()
end]], line, id)

	return script:gsub("    ", ""):gsub("\t", ""):gsub("\n", " ")
end

local function pprint_self(line, id)
	line = line:gsub("\n", " ")
	id = id or "pprint_eval"

	local script = string.format([[local toEval = %q
local id = %q

local function compile(code, id)
	local fullCode = "return function() " .. code .. "\nend"
	local compiled = CompileString(fullCode, id, false)

	if isstring(compiled) then
		return nil, compiled
	end

	local f = compiled()

	if not f then
		return nil, "Unexpected error."
	end

	return f
end

local eval = compile("return " .. toEval, id)

if not eval then
	local f, err = compile(toEval, id)
	eval = f
	if err then
		ErrorNoHalt(id .. ": " .. err)
		return
	end
end

if eval then
	setfenv(eval, easylua.EnvMeta)
	prettyprint.StartPrintTable()
	prettyprint.show(eval())
	prettyprint.EndPrintTable()
end]], line, id)

	return script:gsub("    ", ""):gsub("\t", ""):gsub("\n", " ")
end

add("sv", function(ply, line)
	if not ply:IsAdmin() then return end
	if not line then
		return false, "invalid script"
	end

	if luadev.ValidScript then
		local valid, err = luadev.ValidScript(pprint(line, "pprint"), "pprint")

		if not valid then
			return false, err
		end
	end

	tagline(ply:Name(), "Server")
	showLine(line)

	return luadev.RunOnServer(pprint(line, "pprint"), X(ply, "pprint"), {
		ply = ply
	})
end)

add("sh", function(ply, line)
	if not ply:IsAdmin() then return end
	if not line then
		return false, "invalid script"
	end

	if luadev.ValidScript then
		local valid, err = luadev.ValidScript(pprint(line, "pprints"), "pprints")

		if not valid then
			return false, err
		end
	end

	tagline(ply:Name(), "Shared")
	MsgN("")
	tagline1("Server")
	showLine(line)

	return luadev.RunOnShared(pprint(line, "pprints"), X(ply, "pprints"), {
		ply = ply
	})
end)

add("clients", function(ply, line)
	if not ply:IsAdmin() then return end
	if not line then return end

	if luadev.ValidScript then
		local valid, err = luadev.ValidScript(pprint(line, "pprintc"), "pprintc")

		if not valid then
			return false, err
		end
	end

	tagline(ply:Name(), "Clients")
	showLine(line)

	return luadev.RunOnClients(pprint(line, "pprintc"), X(ply, "pprintc"), {
		ply = ply
	})
end)

--[[add("psc", function(ply, line)
local sep = ply:GetInfo("ayako_separator")

local script = ayako:SplitWithEscapes(line, sep)
local target = table.remove(script, 1)
script = table.concat(script, sep)

if luadev.ValidScript then
	local valid, err = luadev.ValidScript(pprint(script, "pprintsc"), "pprintsc")

	if not valid then
		return false, err
	end
end

easylua.Start(ply)
local ent = easylua.FindEntity(target)

if istable(ent) then
	ent = ent.get()
end

easylua.End()

return luadev.RunOnClient(pprint(script, "pprintsc"), ent, X(ply, "pprintsc"), {
ply = ply
})
end)--]]

local sv_allowcslua = GetConVar "sv_allowcslua"

add("self", function(ply, line)
	if not line then return end

	local script = ply:IsAdmin() and pprint(line, "pprintm") or pprint_self(line, "pprintm")

	if luadev.ValidScript then
		local valid, err = luadev.ValidScript(script, "pprintm")

		if not valid then
			return false, err
		end
	end

	if not ply:IsAdmin() and not sv_allowcslua:GetBool() then
		return false, "sv_allowcslua is 0"
	end

	luadev.RunOnClient(script, ply, X(ply, "pprintm"), {
		ply = ply
	})
end)

add("cl", function(ply, line)
	if not line then return end

	if luadev.ValidScript then
		local valid, err = luadev.ValidScript(pprint_self(line, "pprintm"), "pprintm")

		if not valid then
			return false, err
		end
	end

	if not sv_allowcslua:GetBool() then
		return false, "sv_allowcslua is 0"
	end

	luadev.RunOnClient(pprint_self(line, "pprintm"), ply, X(ply, "pprintm"), {
		ply = ply
	})
end)

add("both", function(ply, line)
	if not ply:IsAdmin() then return end
	if not line then return end

	if luadev.ValidScript then
		local valid, err = luadev.ValidScript(pprint(line, "pprintb"), "pprintb")

		if not valid then
			return false, err
		end
	end

	tagline(ply:Name(), "Both")
	MsgN("")

	luadev.RunOnClient(pprint(line, "pprintb"), ply, X(ply, "pprintb"), {
		ply = ply
	})

	tagline1("Server")
	showLine(line)

	return luadev.RunOnServer(pprint(line, "pprintb"), X(ply, "pprintb"), {
		ply = ply
	})
end)

local LINES_PATTERN = ":%s*(%d+)[-]?(%d-)$"

add("file", function(ply, line)
	if not ply:IsAdmin() then return end
	if not line then return end
	local original_line = line
	line = line:gsub("^lua/", ""):gsub("^gamemodes/", ""):gsub(LINES_PATTERN, "")

	if not file.Exists(line, "LUA") or not file.Exists(line, "lsv") then
		return false, "Unknown file"
	end

	local contents = file.Read(line, "LUA") or file.Read(line, "lsv")
	local target_lines = ""
	if original_line:find(LINES_PATTERN) then
		local start_line, end_line = original_line:match(LINES_PATTERN)
		start_line = tonumber(start_line)
		if end_line then
			end_line = tonumber(end_line)
		end

		if end_line and start_line > end_line then
			return false, "End line number points to before start line number"
		end

		local lines = string.Explode("\n", contents:gsub("\r", ""))

		local out_lines = {}
		if end_line then
			target_lines = Format(", lines %d-%d", start_line, end_line)
			for i = start_line, end_line do
				out_lines[#out_lines + 1] = lines[i]
			end
		else
			target_lines = Format(", line %d", start_line)
			out_lines[#out_lines + 1] = lines[start_line] .. "\n"
		end

		contents = table.concat(out_lines, "\n")
	end

	local parsed = syntaxParser.parseText(contents)

	tagline1(Format("%s printing file: %s%s", ply:Name(), line, target_lines))
	MsgN("")
	parsed.Print()
	MsgN("")
end)
