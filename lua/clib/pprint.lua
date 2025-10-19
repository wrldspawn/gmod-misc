-- Based on MDave's thing
-- https://gist.github.com/mentlerd/d56ad9e6361f4b86af84
if AddCSLuaFile then AddCSLuaFile() end
module("prettyprint", package.seeall)

local TypeID = TypeID
-- menu state
if not TypeID then
	TypeID = function(t)
		if isstring(t) then
			return TYPE_STRING
		elseif isfunction(t) then
			return TYPE_FUNCTION
		elseif istable(t) then
			return TYPE_TABLE
		elseif isnumber(t) then
			return TYPE_NUMBER
		elseif isbool(t) then
			return TYPE_BOOL
		else
			return TYPE_NIL
		end
	end
end

local COLORS_TYPE    = {
	[TYPE_BOOL]     = Color(230, 185, 157),
	[TYPE_NUMBER]   = Color(226, 158, 202),
	[TYPE_STRING]   = Color(144, 185, 159),
	[TYPE_FUNCTION] = Color(133, 181, 186),
}

local COLOR_GLOBAL   = Color(172, 161, 207)

local COLOR_NEUTRAL  = Color(201, 199, 205)
local COLOR_NAME     = Color(212, 192, 192)

local COLOR_COMMENT  = Color(129, 117, 117)

local COLOR_WHITE    = Color(255, 255, 255)

-- 'nil' value
local NIL            = {}

-- Localise for faster access
local pcall          = pcall
local next           = next
local pairs          = pairs
local ipairs         = ipairs

local isstring       = isstring
local isnumber       = isnumber
local isvector       = isvector
local isangle        = isangle
local isentity       = isentity
local isfunction     = isfunction
local ispanel        = ispanel

local IsColor        = IsColor
local IsValid        = IsValid

local tonumber       = tonumber
local tostring       = tostring

local string_len     = string.len
local string_sub     = string.sub
local string_find    = string.find
local string_byte    = string.byte
local string_match   = string.match
local string_gsub    = string.gsub
local string_char    = string.char
local string_format  = string.format
local string_rep     = string.rep
local string_split   = string.Split
local string_lower   = string.lower

local table_concat   = table.concat
local table_insert   = table.insert
local table_sort     = table.sort

local math_min       = math.min
local math_max       = math.max

local debug_getinfo  = debug.getinfo
local debug_getlocal = debug.getlocal

-- Stream interface
local gMsgF -- Print fragment
local gMsgN -- Print newline
local gMsgC -- Set print color

local _MsgC          = _G.MsgC
local _MsgN          = _G.MsgN

do
	local COLOR_GREP = Color(235, 70, 70)

	-- Grep parameters (static between gBegin/gEnd)
	local grep
	local grep_raw

	local grep_proximity

	-- Current line parameters
	local buffer
	local colors
	local markers

	local baseColor
	local currColor

	local length

	-- History
	local history
	local remain


	-- Actual printing
	local function gCheckMatch(buffer)
		local raw = table_concat(buffer)

		return raw, string_find(raw, grep, 0, grep_raw)
	end

	local function gFlushEx(raw, markers, colors, baseColor)
		-- Print entire buffer
		local len    = string_len(raw)

		-- Keep track of the current line properties
		local index  = 1
		local marker = 1

		currColor    = baseColor

		-- Method to print to a preset area
		local function printToIndex(limit, color)
			local mark = markers and markers[marker]

			-- Print all marker areas until we would overshoot
			while mark and mark < limit do
				-- Catch up to the marker
				MsgC(color or currColor or COLOR_NEUTRAL, string_sub(raw, index, mark))
				index     = mark + 1

				-- Set new color
				currColor = colors[marker]

				-- Select next marker
				marker    = marker + 1
				mark      = markers[marker]
			end

			-- Print the remaining between the last marker and the limit
			MsgC(color or currColor or COLOR_NEUTRAL, string_sub(raw, index, limit))
			index = limit + 1
		end

		-- Grep!
		local last = 1
		local from, to = string_find(raw, grep, 0, grep_raw)

		while from do
			printToIndex(from - 1)
			printToIndex(to, COLOR_GREP)

			last     = to + 1
			from, to = string_find(raw, grep, last, grep_raw)
		end

		printToIndex(len)
		MsgN("")
	end


	local function gCommit()
		if grep_proximity then
			-- Check if the line has at least one match
			local raw, match = gCheckMatch(buffer)

			if match then
				-- Divide matches
				if history[grep_proximity] then
					MsgN("...")
				end

				-- Flush history
				if grep_proximity ~= 0 then
					local len = #history

					for index = len - 1, 1, -1 do
						local entry = history[index]
						history[index] = nil

						gFlushEx(entry[1], entry[2], entry[3], entry[4])
					end

					history[len] = nil
				end

				-- Flush line, allow next X lines to get printed
				gFlushEx(raw, markers, colors, baseColor)
				remain = grep_proximity - 1

				history[grep_proximity + 1] = nil
			elseif remain > 0 then
				-- Flush immediately
				gFlushEx(raw, markers, colors, baseColor)
				remain = remain - 1
			else
				-- Store in history
				table_insert(history, 1, { raw, markers, colors, baseColor })
				history[grep_proximity + 1] = nil
			end
		else
			-- Flush anyway
			gFlushEx(table_concat(buffer), markers, colors, baseColor)
		end

		-- Reset state
		length    = 0
		buffer    = {}

		markers   = nil
		colors    = nil

		baseColor = nil
		currColor = nil
	end

	-- State machine
	function gBegin(new, prox)
		grep = isstring(new) and new

		if grep then
			grep_raw       = not pcall(string_find, ' ', grep)
			grep_proximity = isnumber(prox) and prox

			-- Reset everything
			buffer         = {}
			history        = {}
		end

		length = 0
		remain = 0

		baseColor = nil
		currColor = nil
	end

	function gFinish()
		if grep_proximity and history and history[1] then
			MsgN("...")
		end

		-- Free memory
		buffer  = nil
		markers = nil
		colors  = nil

		history = nil
	end

	function gMsgC(color)
		if grep then
			-- Try to save some memory by not immediately allocating colors
			if length == 0 then
				baseColor = color
				return
			end

			-- Record color change
			if color ~= currColor then
				if not markers then
					markers = {}
					colors  = {}
				end

				-- Record color change
				markers[#markers + 1] = length
				colors[#colors + 1] = color
			end
		end

		currColor = color
	end

	function gMsgF(str)
		if grep then
			-- Split multiline fragments to separate ones
			local fragColor = currColor or baseColor

			local last = 1
			local from, to = string_find(str, '\n')

			while from do
				local frag          = string_sub(str, last, from - 1)
				local len           = from - last

				-- Merge fragment to the line
				length              = length + len
				buffer[#buffer + 1] = frag

				-- Print finished line
				gCommit()

				-- Assign base color as previous fragColor
				baseColor = fragColor

				-- Look for more
				last      = to + 1
				from, to  = string_find(str, '\n', last)
			end

			-- Push last fragment
			local frag          = string_sub(str, last)
			local len           = string_len(str) - last + 1

			length              = length + len
			buffer[#buffer + 1] = frag
		else
			-- Push immediately
			MsgC(currColor or baseColor or COLOR_NEUTRAL, str)
		end
	end

	function gMsgN()
		-- Print everything in the buffer
		if grep then
			gCommit()
		else
			MsgN("")
		end

		baseColor = nil
		currColor = nil
	end
end

-- taken from gcompute
local escapeTable = {}
for i = 0, 255 do
	local c = string_char(i)

	if i < string_byte(" ") then
		escapeTable[c] = string_format("\\x%02x", i)
	elseif i >= 127 then
		escapeTable[c] = string_format("\\x%02x", i)
	end
end
escapeTable["\\"] = "\\\\"
escapeTable["\t"] = "\\t"
escapeTable["\r"] = "\\r"
escapeTable["\n"] = "\\n"
escapeTable["\""] = "\\\""

local characterPrintingBlacklist =
{
	["\0"] = true,
	["\r"] = true,
	["\n"] = true
}

local limitedprint = false
function StartLimit()
	limitedprint = true
end

function EndLimit()
	limitedprint = false
end

function UseEPOE(state)
	if SERVER then return end
	if not epoe then return end

	if state == true then
		MsgC = epoe.MsgC
		MsgN = epoe.MsgN
	else
		MsgC = _MsgC
		MsgN = _MsgN
	end
end

local printtable = false
function StartPrintTable()
	printtable = true
end

function EndPrintTable()
	printtable = false
end

local keywords = {
	["and"]      = true,
	["break"]    = true,
	["continue"] = true,
	["do"]       = true,
	["else"]     = true,
	["elseif"]   = true,
	["end"]      = true,
	["false"]    = true,
	["for"]      = true,
	["function"] = true,
	["if"]       = true,
	["nil"]      = true,
	["not"]      = true,
	["or"]       = true,
	["repeat"]   = true,
	["return"]   = true,
	["then"]     = true,
	["true"]     = true,
	["until"]    = true,
	["while"]    = true,
}
local function IsValidVariableName(str)
	if not isstring(str) then return false end
	if string_match(str, "^[_a-zA-Z][_a-zA-Z0-9]*$") then
		if keywords[str] then
			return false
		end

		return true
	end

	return false
end

local function ContainsSequences(str, offset)
	return string_find(str, "[\192-\255]", offset) and true or false
end

local function UTF8_Length(str)
	local _, len = string_gsub(str, "[^\128-\191]", "")
	return len
end

local function UTF8_Iterator(str, offset)
	offset = offset or 1
	if offset <= 0 then offset = 1 end

	return function()
		if offset > #str then return nil, #str + 1 end

		local length
		local byte = string_byte(str, offset)
		if not byte then
			length = 0
		elseif byte >= 240 then
			length = 4
		elseif byte >= 224 then
			length = 3
		elseif byte >= 192 then
			length = 2
		else
			length = 1
		end

		local character = string_sub(str, offset, offset + length - 1)
		local lastOffset = offset
		offset = offset + length
		return character, lastOffset
	end
end

local function UTF8_Byte(char, offset)
	if char == "" then return -1 end
	offset = offset or 1

	local byte = string_byte(char, offset)
	local length = 1
	if byte >= 128 then
		-- multi-byte sequence
		if byte >= 240 then
			-- 4 byte sequence
			length = 4
			if #char < 4 then return -1, length end
			byte = (byte % 8) * 262144
			byte = byte + (string_byte(char, offset + 1) % 64) * 4096
			byte = byte + (string_byte(char, offset + 2) % 64) * 64
			byte = byte + (string_byte(char, offset + 3) % 64)
		elseif byte >= 224 then
			-- 3 byte sequence
			length = 3
			if #char < 3 then return -1, length end
			byte = (byte % 16) * 4096
			byte = byte + (string_byte(char, offset + 1) % 64) * 64
			byte = byte + (string_byte(char, offset + 2) % 64)
		elseif byte >= 192 then
			-- 2 byte sequence
			length = 2
			if #char < 2 then return -1, length end
			byte = (byte % 32) * 64
			byte = byte + (string_byte(char, offset + 1) % 64)
		else
			-- this is a continuation byte
			-- invalid sequence
			byte = -1
		end
	else
		-- single byte sequence
	end
	return byte, length
end

local function InternalPrintValue(value, shouldComment, shouldComma)
	if shouldComment == nil then
		shouldComment = true
	end

	if shouldComma == nil then
		shouldComma = true
	end

	local strOut = {}

	-- 'nil' values can also be printed
	if value == NIL then
		gMsgC(COLORS_TYPE[TYPE_NUMBER])
		gMsgF("nil")
		strOut[#strOut + 1] = "nil"

		return table_concat(strOut, "")
	end

	local color = COLORS_TYPE[TypeID(value)]

	-- For strings, place quotes
	if isstring(value) then
		local escapedString = string_gsub(value, ".", escapeTable)
		if limitedprint and #escapedString > 127 then
			escapedString = escapedString:sub(1, 127) .. "\xe2\x80\xa6"
		end
		value = string_format('"%s"', escapedString)

		if syntaxParser then
			for _, part in ipairs(syntaxParser.process(value)) do
				if IsColor(part) then
					gMsgC(part)
				else
					gMsgF(part)
					strOut[#strOut + 1] = part
				end
			end
		else
			gMsgC(color)
			gMsgF(value)
			strOut[#strOut + 1] = value
		end

		if shouldComma then
			gMsgC(COLOR_NEUTRAL)
			gMsgF(",")
			strOut[#strOut + 1] = ","
		end

		return table_concat(strOut, "")
	end

	-- Format tables
	if istable(value) and not IsColor(value) then
		local classname = "table"
		local mt = getmetatable(value)

		if mt then
			if mt.MetaName then
				classname = mt.MetaName
			elseif mt.__tostring then
				classname = tostring(value)
			end
		end

		if next(value) then
			gMsgC(COLOR_NEUTRAL)
			gMsgF("{ ")
			strOut[#strOut + 1] = "{ "

			gMsgC(COLOR_COMMENT)
			gMsgF(string_format("--[[ %s: %p ]]", classname, value))
			strOut[#strOut + 1] = string_format("--[[ %s: %p ]]", classname, value)

			gMsgC(COLOR_NEUTRAL)
			gMsgF(" }")
			strOut[#strOut + 1] = " }"

			if shouldComma then
				gMsgC(COLOR_NEUTRAL)
				gMsgF(",")
				strOut[#strOut + 1] = ","
			end
		else
			gMsgC(COLOR_NEUTRAL)
			gMsgF("{}")
			strOut[#strOut + 1] = "{}"

			if shouldComma then
				gMsgC(COLOR_NEUTRAL)
				gMsgF(",")
				strOut[#strOut + 1] = ","
			end

			if shouldComment then
				gMsgC(COLOR_COMMENT)
				gMsgF(string_format(" -- %s: %p", classname, value))
				strOut[#strOut + 1] = string_format(" -- %s: %p", classname, value)
			end
		end

		return table_concat(strOut, "")
	end

	-- Vectors/Angles/Colors
	if isvector(value) then
		local tbl = value:ToTable()

		gMsgC(COLOR_GLOBAL)
		gMsgF("Vector")
		strOut[#strOut + 1] = "Vector"

		gMsgC(COLOR_NEUTRAL)
		gMsgF("(")
		strOut[#strOut + 1] = "("

		for k, v in pairs(tbl) do
			gMsgC(COLORS_TYPE[TYPE_NUMBER])
			gMsgF(v)
			strOut[#strOut + 1] = v

			if k ~= #tbl then
				gMsgC(COLOR_NEUTRAL)
				gMsgF(", ")
				strOut[#strOut + 1] = ", "
			end
		end

		gMsgC(COLOR_NEUTRAL)
		gMsgF(")")
		strOut[#strOut + 1] = ")"

		if shouldComma then
			gMsgC(COLOR_NEUTRAL)
			gMsgF(",")
			strOut[#strOut + 1] = ","
		end

		return table_concat(strOut, "")
	end

	if isangle(value) then
		local tbl = value:ToTable()

		gMsgC(COLOR_GLOBAL)
		gMsgF("Angle")
		strOut[#strOut + 1] = "Angle"

		gMsgC(COLOR_NEUTRAL)
		gMsgF("(")
		strOut[#strOut + 1] = "("

		for k, v in ipairs(tbl) do
			gMsgC(COLORS_TYPE[TYPE_NUMBER])
			gMsgF(v)
			strOut[#strOut + 1] = v

			if k ~= #tbl then
				gMsgC(COLOR_NEUTRAL)
				gMsgF(", ")
				strOut[#strOut + 1] = ", "
			end
		end

		gMsgC(COLOR_NEUTRAL)
		gMsgF(")")
		strOut[#strOut + 1] = ")"

		if shouldComma then
			gMsgC(COLOR_NEUTRAL)
			gMsgF(",")
			strOut[#strOut + 1] = ","
		end

		return table_concat(strOut, "")
	end

	if IsColor(value) then
		local tbl = value:ToTable()

		gMsgC(COLOR_GLOBAL)
		gMsgF("Color")
		strOut[#strOut + 1] = "Color"

		gMsgC(COLOR_NEUTRAL)
		gMsgF("(")
		strOut[#strOut + 1] = "("

		for k, v in ipairs(tbl) do
			gMsgC(COLORS_TYPE[TYPE_NUMBER])
			gMsgF(v)
			strOut[#strOut + 1] = v

			if k ~= #tbl then
				gMsgC(COLOR_NEUTRAL)
				gMsgF(", ")
				strOut[#strOut + 1] = ", "
			end
		end

		gMsgC(COLOR_NEUTRAL)
		gMsgF(")")
		strOut[#strOut + 1] = ")"

		if shouldComma then
			gMsgC(COLOR_NEUTRAL)
			gMsgF(",")
			strOut[#strOut + 1] = ","
		end

		if shouldComment then
			gMsgC(COLOR_COMMENT)
			gMsgF(" -- ")

			gMsgC(value)
			gMsgF("█")
			strOut[#strOut + 1] = " -- █"
		end

		return table_concat(strOut, "")
	end

	-- Entities
	if isentity(value) then
		if not IsValid(value) and value ~= game.GetWorld() then
			gMsgC(COLOR_GLOBAL)
			gMsgF("NULL")
			strOut[#strOut + 1] = "NULL"
			return table_concat(strOut, "")
		elseif value == game.GetWorld() then
			gMsgC(COLOR_GLOBAL)
			gMsgF("game.GetWorld")
			strOut[#strOut + 1] = "game.GetWorld"

			gMsgC(COLOR_NEUTRAL)
			gMsgF("()")
			strOut[#strOut + 1] = "()"

			if shouldComma then
				gMsgC(COLOR_NEUTRAL)
				gMsgF(",")
				strOut[#strOut + 1] = ","
			end

			if shouldComment then
				local comment = string_format(" -- %s, %s", value:GetClass(), value:GetModel())
				gMsgC(COLOR_COMMENT)
				gMsgF(comment)
				strOut[#strOut + 1] = comment
			end

			return table_concat(strOut, "")
		elseif value:EntIndex() < 0 and value:GetModel() and value:GetModel() ~= "" then
			gMsgC(COLOR_GLOBAL)
			gMsgF("ClientsideModel")
			strOut[#strOut + 1] = "ClientsideModel"

			gMsgC(COLOR_NEUTRAL)
			gMsgF("(")
			strOut[#strOut + 1] = "("

			gMsgC(COLORS_TYPE[TYPE_STRING])
			local model = string_format("%q", value:GetModel())
			gMsgF(model)
			strOut[#strOut + 1] = model

			gMsgC(COLOR_NEUTRAL)
			gMsgF(")")
			strOut[#strOut + 1] = ")"

			if shouldComma then
				gMsgC(COLOR_NEUTRAL)
				gMsgF(",")
				strOut[#strOut + 1] = ","
			end

			return table_concat(strOut, "")
		elseif value:IsPlayer() then
			gMsgC(COLOR_GLOBAL)
			gMsgF("Player")
			strOut[#strOut + 1] = "Player"

			gMsgC(COLOR_NEUTRAL)
			gMsgF("(")
			strOut[#strOut + 1] = "("

			local idx = value:UserID()
			gMsgC(COLORS_TYPE[TYPE_NUMBER])
			gMsgF(idx)
			strOut[#strOut + 1] = idx

			gMsgC(COLOR_NEUTRAL)
			gMsgF(")")
			strOut[#strOut + 1] = ")"

			if shouldComma then
				gMsgC(COLOR_NEUTRAL)
				gMsgF(",")
				strOut[#strOut + 1] = ","
			end

			if shouldComment then
				local comment = string_format(" -- %s, %q", value:SteamID(), value:Name())
				gMsgC(COLOR_COMMENT)
				gMsgF(comment)
				strOut[#strOut + 1] = comment
			end

			return table_concat(strOut, "")
		else
			gMsgC(COLOR_GLOBAL)
			gMsgF("Entity")
			strOut[#strOut + 1] = "Entity"

			gMsgC(COLOR_NEUTRAL)
			gMsgF("(")
			strOut[#strOut + 1] = "("

			local idx = value:EntIndex()
			gMsgC(COLORS_TYPE[TYPE_NUMBER])
			gMsgF(idx)
			strOut[#strOut + 1] = idx

			gMsgC(COLOR_NEUTRAL)
			gMsgF(")")
			strOut[#strOut + 1] = ")"

			if shouldComma then
				gMsgC(COLOR_NEUTRAL)
				gMsgF(",")
				strOut[#strOut + 1] = ","
			end

			if shouldComment then
				local class = string_format(" -- %s", value:GetClass())
				gMsgC(COLOR_COMMENT)
				gMsgF(class)
				strOut[#strOut + 1] = class

				local model = value:GetModel()
				if model and model ~= "" then
					local modelstr = string_format(", %s", model)
					gMsgF(modelstr)
					strOut[#strOut + 1] = modelstr
				end

				local name = value.GetName and value:GetName()
				if name and name ~= "" then
					local namestr = string_format(", %q", name)
					gMsgF(namestr)
					strOut[#strOut + 1] = namestr
				end

				local children = #value:GetChildren()
				if children > 0 then
					local childstr = string_format(", %d child" .. (children ~= 1 and "ren" or ""), children)
					gMsgF(childstr)
					strOut[#strOut + 1] = childstr
				end
			end

			return table_concat(strOut, "")
		end
	end

	-- Functions
	if isfunction(value) then
		local info = debug_getinfo(value, "Su")
		local aux

		gMsgC(color)
		gMsgF("function")
		strOut[#strOut + 1] = "function"

		gMsgC(COLOR_NEUTRAL)
		gMsgF("(")
		strOut[#strOut + 1] = "("

		if info.what == 'C' then
			gMsgF("...")
			strOut[#strOut + 1] = "..."
			aux = " -- Native"
		else
			if info.isvararg then
				gMsgF("...")
				strOut[#strOut + 1] = "..."
			else
				local args = {}

				local arg = 2
				local last_arg = debug_getlocal(value, 1)
				while last_arg ~= nil do
					args[#args + 1] = last_arg
					last_arg = debug_getlocal(value, arg)
					arg = arg + 1
				end

				local argStr = table_concat(args, ", ")
				gMsgF(argStr)
				strOut[#strOut + 1] = argStr
			end

			if info.linedefined ~= info.lastlinedefined then
				aux = string_format(" -- %s: %i-%i", info.short_src, info.linedefined, info.lastlinedefined)
			else
				aux = string_format(" -- %s: %i", info.short_src, info.linedefined)
			end
		end
		gMsgF(")")
		strOut[#strOut + 1] = ")"

		if shouldComma then
			gMsgC(COLOR_NEUTRAL)
			gMsgF(",")
			strOut[#strOut + 1] = ","
		end

		if shouldComment then
			gMsgC(COLOR_COMMENT)
			gMsgF(aux)
			strOut[#strOut + 1] = aux
		end

		return table_concat(strOut, "")
	end

	-- Panels
	if ispanel(value) then
		gMsgC(COLOR_NEUTRAL)
		gMsgF("{ ")
		strOut[#strOut + 1] = "{"

		gMsgC(COLOR_GLOBAL)
		gMsgF("Panel")
		strOut[#strOut + 1] = "Panel"

		gMsgC(COLOR_NEUTRAL)
		gMsgF(": ")
		strOut[#strOut + 1] = ": "

		local class = "NULL Panel"
		if IsValid(value) then
			class = value:GetClassName()
		end
		gMsgC(COLOR_GLOBAL)
		gMsgF(class)
		strOut[#strOut + 1] = class

		gMsgC(COLOR_NEUTRAL)
		gMsgF(" }")
		strOut[#strOut + 1] = " }"

		if shouldComma then
			gMsgC(COLOR_NEUTRAL)
			gMsgF(",")
			strOut[#strOut + 1] = ","
		end

		if shouldComment and IsValid(value) then
			local children = #value:GetChildren()
			local comment = string_format(" -- %s%s", value:IsVisible() and "Visible" or "Invisible",
				children > 0 and
				string_format(", %d child" .. (children ~= 1 and "ren" or ""), children) or "")
			gMsgC(COLOR_COMMENT)
			gMsgF(comment)
			strOut[#strOut + 1] = comment
		end
		return table_concat(strOut, "")
	end

	-- threads
	if type(value) == "thread" then
		gMsgC(COLOR_GLOBAL)
		gMsgF("thread")
		strOut[#strOut + 1] = "thread"

		gMsgC(COLOR_NEUTRAL)
		local pointer = Format(": %p", value)
		gMsgF(pointer)
		strOut[#strOut + 1] = pointer

		gMsgC(COLOR_COMMENT)
		local status = " -- " .. coroutine.status(value)
		gMsgF(status)
		strOut[#strOut + 1] = status

		return table_concat(strOut, "")
	end

	-- Workaround for userdata not using MetaName
	if string_sub(tostring(value), 0, 8) == "userdata" then
		local meta = getmetatable(value)

		if meta and meta.MetaName then
			value = string_format("%s: %p", meta.MetaName, value)
		end
	end

	-- General print
	gMsgC(color)
	gMsgF(tostring(value))
	strOut[#strOut + 1] = tostring(value)

	if shouldComma then
		gMsgC(COLOR_NEUTRAL)
		gMsgF(",")
		strOut[#strOut + 1] = ","
	end

	return table_concat(strOut, "")
end


-- Associated to object keys
local function isprimitive(value)
	local id = TypeID(value)

	return id <= TYPE_FUNCTION and id ~= TYPE_TABLE
end

local function InternalPrintTable(table, path, prefix, names, todo, recursive)
	-- Collect keys and some info about them
	local keyList        = {}
	local keyStr         = {}
	local shouldPrintKey = {}

	local keyCount       = 0

	for key, value in pairs(table) do
		-- Add to key list for later sorting
		keyList[#keyList + 1] = key

		-- Describe key as string
		if isstring(key) or isnumber(key) then
			keyStr[key] = tostring(key)
		elseif isprimitive(key) then
			keyStr[key] = tostring(key)
		else
			-- stupid hack
			local _gMsgC = gMsgC
			local _gMsgF = gMsgF
			gMsgC = function() end
			gMsgF = function() end

			keyStr[key] = InternalPrintValue(key, false, false)
			shouldPrintKey[key] = true

			gMsgC = _gMsgC
			gMsgF = _gMsgF
		end

		keyCount = keyCount + 1
	end

	-- Exit early for empty tables
	if keyCount == 0 then
		gMsgC(COLOR_NEUTRAL)
		gMsgF("{}")
		if not recursive then
			gMsgN()
		end

		--gMsgC(color_comment)
		--gMsgF(string_format("-- 0 total entries.", keyCount))
		--gMsgN()
		return
	end


	-- Determine max key length
	local keyLen = -1

	for key, str in pairs(keyStr) do
		str = IsValidVariableName(str) and str or
				"[" .. (shouldPrintKey[key] and str or (isnumber(tonumber(str)) and str or string_format('"%s"', str))) .. "]"

		keyLen = math_max(keyLen, string_len(str))
	end

	-- Sort table keys
	if keyCount > 1 then
		table_sort(keyList, function(A, B)
			-- Sort numbers numerically correct
			if isnumber(A) and isnumber(B) then
				return A < B
			end

			-- Order by string representation
			return string_lower(keyStr[A]) < string_lower(keyStr[B])
		end)
	end

	-- Mark object as done
	todo[table] = nil

	if not recursive and IsColor(table) then
		gMsgC(COLOR_COMMENT)
		gMsgF("-- Color: ")
		gMsgC(table)
		gMsgF("█")
		gMsgN()
	end

	gMsgC(COLOR_NEUTRAL)
	gMsgF("{")
	gMsgN()
	gMsgC(COLOR_WHITE)

	local maxKeyIndex = -1
	if limitedprint then
		maxKeyIndex = math_min(160, keyCount)
	end

	-- Start describing table
	for index, key in ipairs(keyList) do
		if maxKeyIndex > -1 and index > maxKeyIndex then break end
		local value = table[key]

		-- Assign names to already described keys/values
		local kName = names[key]
		local vName = names[value]

		-- Decide to either fully describe, or print the value
		--local describe = not isprimitive(value) and ( not vName or todo[value] )

		-- Fancy table guides
		--local moreLines = (index ~= keyCount) or describe

		gMsgF(prefix .. "  ")

		-- Print key
		local sKey = kName or keyStr[key]

		if not shouldPrintKey[key] then
			if IsValidVariableName(sKey) then
				gMsgC(COLOR_NAME)
				gMsgF(sKey)
			else
				gMsgC(COLOR_NEUTRAL)
				gMsgF("[")

				gMsgC(isnumber(tonumber(sKey)) and COLORS_TYPE[TYPE_NUMBER] or COLORS_TYPE[TYPE_STRING])
				gMsgF(isnumber(tonumber(sKey)) and sKey or string_format("%q", sKey))

				gMsgC(COLOR_NEUTRAL)
				gMsgF("]")

				sKey = "[" .. (isnumber(tonumber(sKey)) and sKey or string_format("%q", sKey)) .. "]"
			end
		else
			gMsgC(COLOR_NEUTRAL)
			gMsgF("[")

			local str = InternalPrintValue(key, false, false)

			gMsgC(COLOR_NEUTRAL)
			gMsgF("]")

			sKey = "[" .. str .. "]"
		end

		-- Describe non primitives
		--describe = istable(value) and ( not names[value] or todo[value] ) and value ~= NIL

		-- Print key postfix
		local padding = keyLen - string_len(sKey)
		local postfix = string_format("%s = ", string_rep(' ', padding))

		gMsgC(COLOR_NEUTRAL)
		gMsgF(postfix)

		-- Print the value (or the reference name)
		if vName and not todo[value] then
			gMsgC(COLOR_GLOBAL)
			gMsgF(vName)
		else
			if istable(value) then
				if printtable then
					if IsColor(value) then
						InternalPrintValue(value)
					else
						local base = {
							[_G]    = "_G",
							[table] = "self",
							[value] = "subroot"
						}
						InternalPrintTable(value, nil, prefix .. "  ", base, {}, true)
					end
				else
					InternalPrintValue(value)
				end
			else
				InternalPrintValue(value)
			end
		end

		gMsgN()
		gMsgC(COLOR_WHITE)
	end

	if not recursive then
		if maxKeyIndex > -1 and keyCount > maxKeyIndex then
			gMsgC(COLOR_COMMENT)
			gMsgF(string_format(prefix .. "  -- %s more...", keyCount - maxKeyIndex))
			gMsgN()
		end
	end

	gMsgF(prefix)
	gMsgC(COLOR_NEUTRAL)
	gMsgF("}")
	if not recursive then
		gMsgN()
	end

	if not recursive then
		gMsgC(COLOR_COMMENT)
		gMsgF(string_format("-- %d total entr%s.", keyCount, keyCount == 1 and "y" or "ies"))
		gMsgN()
	end
end

function PrintTableGrep(table, grep, proximity)
	local base = {
		[_G]    = "_G",
		[table] = "self"
	}

	gBegin(grep, proximity)
	InternalPrintTable(table, nil, "", base, {})
	gFinish()
end

function PrintLocals(level)
	level      = level or 2
	local hash = {}

	for index = 1, 255 do
		local name, value = debug_getlocal(2, index)

		if not name then
			break
		end

		if value == nil then
			value = NIL
		end

		hash[name] = value
	end

	PrintTableGrep(hash)
end

function show(...)
	local n = select('#', ...)
	local tbl = { ... }


	for i = 1, n do
		local value = tbl[i]
		if not value then
			InternalPrintValue(NIL, true, false)
			gMsgN()

			continue
		end

		local addr = string_format("%p", value)
		if addr ~= "NULL" and not isstring(value) then
			gMsgC(COLOR_COMMENT)
			gMsgF("-- " .. addr)
			gMsgN()
		end

		if istable(value) then
			if IsColor(value) then
				InternalPrintValue(value, true, false)
				gMsgN()
			else
				local mt = getmetatable(value)
				if mt then
					local name

					if mt.MetaName then
						name = mt.MetaName
					elseif mt.__tostring then
						name = tostring(value)
					else
						name = "has metatable"
					end

					if name then
						gMsgC(COLOR_COMMENT)
						gMsgF("-- " .. name)
						gMsgN()
					end
				end

				PrintTableGrep(value)
			end
		elseif isentity(value) then
			if not IsValid(value) and value ~= game.GetWorld() then
				InternalPrintValue(value, true, false)
				gMsgN()
			else
				local isPlayer = value:IsPlayer()
				if isPlayer then
					gMsgC(COLOR_COMMENT)
					gMsgF("-- " .. value:Name())
					gMsgN()

					gMsgC(COLOR_COMMENT)
					gMsgF("-- " .. value:SteamID())
					gMsgN()
				end

				gMsgC(COLOR_COMMENT)
				gMsgF("-- " .. value:GetClass())
				gMsgN()

				local model = value:GetModel()
				if model and model ~= "" then
					gMsgC(COLOR_COMMENT)
					gMsgF("-- " .. model)
					gMsgN()
				end

				local name = value.GetName and value:GetName()
				if name and name ~= "" and not isPlayer then
					gMsgC(COLOR_COMMENT)
					gMsgF(string_format("-- %q", name))
					gMsgN()
				end

				if value == game.GetWorld() then
					gMsgC(COLORS_TYPE[TYPE_FUNCTION])
					gMsgF("game.GetWorld")

					gMsgC(COLOR_NEUTRAL)
					gMsgF("()")
				elseif isPlayer then
					gMsgC(COLOR_GLOBAL)
					gMsgF("Player")

					gMsgC(COLOR_NEUTRAL)
					gMsgF("(")

					gMsgC(COLORS_TYPE[TYPE_NUMBER])
					gMsgF(value:UserID())

					gMsgC(COLOR_NEUTRAL)
					gMsgF(")")

					gMsgC(COLOR_COMMENT)
					gMsgF(string_format(" -- Entity(%d)", value:EntIndex()))
				else
					gMsgC(COLOR_GLOBAL)
					gMsgF("Entity")

					gMsgC(COLOR_NEUTRAL)
					gMsgF("(")

					gMsgC(COLORS_TYPE[TYPE_NUMBER])
					gMsgF(value:EntIndex())

					gMsgC(COLOR_NEUTRAL)
					gMsgF(")")
				end

				gMsgN()

				PrintTableGrep(value:GetTable())

				local children = value:GetChildren()
				if #children > 0 and not isPlayer then
					gMsgC(COLOR_COMMENT)
					gMsgF("-- Children:")
					gMsgN()
					PrintTableGrep(children)
				end
			end
		elseif ispanel(value) then
			if not IsValid(value) then
				InternalPrintValue(value, true, false)
				gMsgN()
			else
				PrintTableGrep(value:GetTable())

				local children = value:GetChildren()
				if #children > 0 then
					gMsgC(COLOR_COMMENT)
					gMsgF("-- Children:")
					gMsgN()
					PrintTableGrep(children)
				end
			end
		elseif isfunction(value) then
			if GLib and GLib.Lua and syntaxParser then
				local f = GLib.Lua.Function(value)
				if f:IsNative() then
					InternalPrintValue(value, true, false)
					gMsgN()
				else
					local code

					local src = f:GetFilePath():gsub("^lua/", "")
					local data = file.Read(src, "GAME")
					data = data or file.Read(src, "LUA")
					data = data or file.Read(src, SERVER and "LSV" or "LCL")

					if data then
						local startLine = f:GetStartLine()
						local endLine   = f:GetEndLine()

						local lines     = string_split(data, "\n")
						if endLine <= #lines then
							local codeLines = {}
							for l = startLine, endLine do
								codeLines[#codeLines + 1] = lines[l]
							end
							code = table_concat(codeLines, "\n")
						end
					end

					if not code then
						local ok, out = pcall(function() return GLib.Lua.BytecodeReader(value):ToString() end)
						if not ok then
							gMsgC(COLOR_COMMENT)
							gMsgF(string_format("-- Failed to decompile: %s", out))
							gMsgN()
							code = ""
						else
							code = out
						end
					end

					local info = f.InfoTable
					if info.linedefined ~= info.lastlinedefined then
						gMsgC(COLOR_COMMENT)
						gMsgF(string_format("-- %s: %i-%i", info.short_src, info.linedefined, info.lastlinedefined))
					else
						gMsgC(COLOR_COMMENT)
						gMsgF(string_format("-- %s: %i", info.short_src, info.linedefined))
					end
					gMsgN()

					local formatted = syntaxParser.process(code)
					for _, v in pairs(formatted) do
						if IsColor(v) then
							gMsgC(v)
						else
							gMsgF(v)
						end
					end

					gMsgN()
				end
			else
				InternalPrintValue(value, true, false)
				gMsgN()
			end
		elseif isstring(value) then
			if GLib and ContainsSequences(value) then
				local codePointCount = UTF8_Length(value)
				gMsgC(COLOR_COMMENT)
				gMsgF("-- " .. tostring(codePointCount) .. " code point" .. (codePointCount == 1 and "" or "s"))
				gMsgN()

				local j = 0
				for c in UTF8_Iterator(value) do
					if j >= 5 then
						gMsgC(COLOR_COMMENT)
						gMsgF("-- ...")
						gMsgN()
						break
					end
					j = j + 1

					gMsgC(COLOR_COMMENT)
					gMsgF("-- " ..
						string_format("U+%06X ", UTF8_Byte(c)) ..
						(not characterPrintingBlacklist[c] and c or " ") .. " " .. GLib.Unicode.GetCharacterName(c))
					gMsgN()
				end
			end
			InternalPrintValue(value, true, false)
			gMsgN()
		else
			InternalPrintValue(value, true, false)
			gMsgN()
		end
	end
end

-- Hacky way of creating a pretty string from the above code
-- because I don't feel like refactoring the entire thing
local strResult
local toStringMsgF = function(txt)
	strResult[#strResult + 1] = txt
end

local toStringMsgN = function()
	strResult[#strResult + 1] = "\n"
end

local toStringMsgC = function(_, txt)
	strResult[#strResult + 1] = txt
end

local toStringMsgC2 = function(col, txt)
	if col then
		local outcol = ("\x0E%s\x0F"):format(table.concat(col:ToTable(), " "))
		strResult[#strResult + 1] = outcol
	end
	strResult[#strResult + 1] = txt
end

function toString(...)
	local oldF, oldN, oldMsgC, oldMsgN = gMsgF, gMsgN, MsgC, MsgN
	gMsgF, gMsgN, MsgC, MsgN = toStringMsgF, toStringMsgN, toStringMsgC, toStringMsgN

	strResult = {}
	show(...)

	gMsgF, gMsgN, MsgC, MsgN = oldF, oldN, oldMsgC, oldMsgN

	return table_concat(strResult, "")
end

function toStringWithColor(...)
	local oldF, oldN, oldC, oldMsgC, oldMsgN = gMsgF, gMsgN, gMsgC, MsgC, MsgN
	gMsgF, gMsgN, gMsgC, MsgC, MsgN = toStringMsgF, toStringMsgN, toStringMsgC2, toStringMsgC2, toStringMsgN

	strResult = {}
	show(...)

	gMsgF, gMsgN, gMsgC, MsgC, MsgN = oldF, oldN, oldC, oldMsgC, oldMsgN

	return table_concat(strResult, "")
end

_G.oldPrintTable = _G.oldPrintTable or _G.PrintTable
_G.PrintTable = function(...)
	StartPrintTable()
	show(...)
	EndPrintTable()
end
