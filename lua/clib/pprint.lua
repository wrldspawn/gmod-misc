-- Based on MDave's thing
-- https://gist.github.com/mentlerd/d56ad9e6361f4b86af84
AddCSLuaFile()
module("prettyprint", package.seeall)

local type_colors = {
	[TYPE_BOOL]     = Color(230, 138, 193),
	[TYPE_NUMBER]   = Color(180, 164, 222),
	[TYPE_STRING]   = Color(162, 186, 168),
	[TYPE_FUNCTION] = Color(245,  93, 143),
}

local color_global  = Color(180, 164, 222)

local color_neutral = Color(222, 219, 235)
local color_name    = Color(170, 186, 231)

local color_comment = Color( 93,  93,  93)

-- 'nil' value
local NIL = {}

-- Localise for faster access
local pcall              = pcall
local next               = next
local pairs              = pairs
local ipairs             = ipairs

local isstring           = isstring
local isnumber           = isnumber
local isvector           = isvector
local isangle            = isangle
local isentity           = isentity
local isfunction         = isfunction
local ispanel            = ispanel

local IsColor            = IsColor
local IsValid            = IsValid

local tonumber           = tonumber
local tostring           = tostring

local string_len         = string.len
local string_sub         = string.sub
local string_find        = string.find
local string_byte        = string.byte
local string_match       = string.match
local string_gsub        = string.gsub
local string_char        = string.char
local string_format      = string.format
local string_rep         = string.rep
local string_split       = string.Split
local string_lower       = string.lower

local table_concat       = table.concat
local table_insert       = table.insert
local table_sort         = table.sort

local math_min           = math.min
local math_max           = math.max

local debug_getinfo      = debug.getinfo
local debug_getlocal     = debug.getlocal
local debug_getmetatable = debug.getmetatable

-- Stream interface
local gMsgF -- Print fragment
local gMsgN -- Print newline
local gMsgC -- Set print color

local _MsgC = _G.MsgC
local _MsgN = _G.MsgN

do
	local grep_color   = Color(235, 70, 70)

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
	local function gCheckMatch( buffer )
		local raw = table_concat(buffer)

		return raw, string_find(raw, grep, 0, grep_raw)
	end

	local function gFlushEx( raw, markers, colors, baseColor )

		-- Print entire buffer
		local len = string_len(raw)

		-- Keep track of the current line properties
		local index  = 1
		local marker = 1

		local currColor = baseColor

		-- Method to print to a preset area
		local function printToIndex( limit, color )
			local mark = markers and markers[marker]

			-- Print all marker areas until we would overshoot
			while mark and mark < limit do

				-- Catch up to the marker
				MsgC(color or currColor or color_neutral, string_sub(raw, index, mark))
				index = mark +1

				-- Set new color
				currColor = colors[marker]

				-- Select next marker
				marker = marker +1
				mark   = markers[marker]

			end

			-- Print the remaining between the last marker and the limit
			MsgC(color or currColor or color_neutral, string_sub(raw, index, limit))
			index = limit +1
		end

		-- Grep!
		local match, last = 1
		local from, to = string_find(raw, grep, 0, grep_raw)

		while from do
			printToIndex(from -1)
			printToIndex(to, grep_color)

			last     = to +1
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

					for index = len -1, 1, -1 do
						local entry = history[index]
							history[index] = nil

						gFlushEx( entry[1], entry[2], entry[3], entry[4] )
					end

					history[len] = nil
				end

				-- Flush line, allow next X lines to get printed
				gFlushEx( raw, markers, colors, baseColor )
				remain = grep_proximity -1

				history[grep_proximity +1] = nil
			elseif remain > 0 then
				-- Flush immediately
				gFlushEx( raw, markers, colors, baseColor )
				remain = remain -1
			else
				-- Store in history
				table_insert(history, 1, {raw, markers, colors, baseColor})
				history[grep_proximity +1] = nil
			end
		else
			-- Flush anyway
			gFlushEx( table_concat(buffer), markers, colors, baseColor )
		end

		-- Reset state
		length = 0
		buffer = {}

		markers = nil
		colors  = nil

		baseColor = nil
		currColor = nil
	end

	-- State machine
	function gBegin( new, prox )
		grep = isstring(new) and new

		if grep then
			grep_raw       = not pcall(string_find, ' ', grep)
			grep_proximity = isnumber(prox) and prox

			-- Reset everything
			buffer  = {}
			history = {}
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


	function gMsgC( color )
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
				table_insert(markers, length)
				table_insert(colors,  color)
			end
		end

		currColor = color
	end

	function gMsgF( str )

		if grep then

			-- Split multiline fragments to separate ones
			local fragColor = currColor or baseColor

			local last = 1
			local from, to = string_find(str, '\n')

			while from do
				local frag = string_sub(str, last, from -1)
				local len  = from - last

				-- Merge fragment to the line
				length = length + len
				table_insert(buffer, frag)

				-- Print finished line
				gCommit()

				-- Assign base color as previous fragColor
				baseColor = fragColor

				-- Look for more
				last     = to +1
				from, to = string_find(str, '\n', last)
			end

			-- Push last fragment
			local frag = string_sub(str, last)
			local len  = string_len(str) - last +1

			length = length + len
			table_insert(buffer, frag)
		else
			-- Push immediately
			MsgC(currColor or baseColor or color_neutral, str)
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

-- stolen from gcompute
local escapeTable = {}
local multilineEscapeTable = {}
for i = 0, 255 do
	local c = string_char(i)

	if i < string_byte(" ") then escapeTable[c] = string_format("\\x%02x", i)
	elseif i >= 127 then escapeTable[c] = string_format("\\x%02x", i) end
end
escapeTable["\\"] = "\\"
escapeTable["\t"] = "\\t"
escapeTable["\r"] = "\\r"
escapeTable["\n"] = "\\n"
escapeTable["\""] = "\""

for k, v in pairs(escapeTable) do
	multilineEscapeTable[k] = v
end
multilineEscapeTable["\t"] = nil
multilineEscapeTable["\n"] = "\\n"

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

	return function ()
		if offset > #str then return nil, #str + 1 end

		local length
		local byte = string_byte(str, offset)
		if not byte then length = 0
		elseif byte >= 240 then length = 4
		elseif byte >= 224 then length = 3
		elseif byte >= 192 then length = 2
		else length = 1 end

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

local function InternalPrintValue( value, shouldComment, shouldComma )
	if shouldComment == nil then
		shouldComment = true
	end

	if shouldComma == nil then
		shouldComma = true
	end

	local strOut = {}

	-- 'nil' values can also be printed
	if value == NIL then
		gMsgC(type_colors[TYPE_NUMBER])
		gMsgF("nil")
		strOut[#strOut + 1] = "nil"

		return table_concat(strOut, "")
	end

	local color = type_colors[ TypeID(value) ]

	-- For strings, place quotes
	if isstring(value) then
		local escapedString = string_gsub(value, ".", multiline and multilineEscapeTable or escapeTable)
		value = string_format("%q", escapedString)

		gMsgC(color)
		gMsgF(value)
		strOut[#strOut + 1] = value

		if shouldComma then
			gMsgC(color_neutral)
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
			gMsgC(color_neutral)
			gMsgF("{ ")
			strOut[#strOut + 1] = "{ "

			gMsgC(color_comment)
			gMsgF(string_format("--[[ %s: %p ]]", classname, value))
			strOut[#strOut + 1] = string_format("--[[ %s: %p ]]", classname, value)

			gMsgC(color_neutral)
			gMsgF(" }")
			strOut[#strOut + 1] = " }"

			if shouldComma then
				gMsgC(color_neutral)
				gMsgF(",")
				strOut[#strOut + 1] = ","
			end
		else
			gMsgC(color_neutral)
			gMsgF("{}")
			strOut[#strOut + 1] = "{}"

			if shouldComma then
				gMsgC(color_neutral)
				gMsgF(",")
				strOut[#strOut + 1] = ","
			end

			if shouldComment then
				gMsgC(color_comment)
				gMsgF(string_format(" -- %s: %p", classname, value))
				strOut[#strOut + 1] = string_format(" -- %s: %p", classname, value)
			end
		end

		return table_concat(strOut, "")
	end

	-- Vectors/Angles/Colors
	if isvector(value) then
		local tbl = {}
		tbl[1] = value.x
		tbl[2] = value.y
		tbl[3] = value.z

		gMsgC(color_global)
		gMsgF("Vector")
		strOut[#strOut + 1] = "Vector"

		gMsgC(color_neutral)
		gMsgF("(")
		strOut[#strOut + 1] = "("

		for k, v in pairs(tbl) do
			gMsgC(type_colors[TYPE_NUMBER])
			gMsgF(v)
			strOut[#strOut + 1] = v

			if k ~= #tbl then
				gMsgC(color_neutral)
				gMsgF(", ")
				strOut[#strOut + 1] = ", "
			end
		end

		gMsgC(color_neutral)
		gMsgF(")")
		strOut[#strOut + 1] = ")"

		if shouldComma then
			gMsgC(color_neutral)
			gMsgF(",")
			strOut[#strOut + 1] = ","
		end

		return table_concat(strOut, "")
	end

	if isangle(value) then
		local tbl = {}
		tbl[1] = value.x
		tbl[2] = value.y
		tbl[3] = value.z

		gMsgC(color_global)
		gMsgF("Angle")
		strOut[#strOut + 1] = "Angle"

		gMsgC(color_neutral)
		gMsgF("(")
		strOut[#strOut + 1] = "("

		for k, v in pairs(tbl) do
			gMsgC(type_colors[TYPE_NUMBER])
			gMsgF(v)
			strOut[#strOut + 1] = v

			if k ~= #tbl then
				gMsgC(color_neutral)
				gMsgF(", ")
				strOut[#strOut + 1] = ", "
			end
		end

		gMsgC(color_neutral)
		gMsgF(")")
		strOut[#strOut + 1] = ")"

		if shouldComma then
			gMsgC(color_neutral)
			gMsgF(",")
			strOut[#strOut + 1] = ","
		end

		return table_concat(strOut, "")
	end

	if IsColor(value) then
		local tbl = {}
		tbl[1] = value.r
		tbl[2] = value.g
		tbl[3] = value.b
		tbl[4] = value.a

		gMsgC(color_global)
		gMsgF("Color")
		strOut[#strOut + 1] = "Color"

		gMsgC(color_neutral)
		gMsgF("(")
		strOut[#strOut + 1] = "("

		for k, v in pairs(tbl) do
			gMsgC(type_colors[TYPE_NUMBER])
			gMsgF(v)
			strOut[#strOut + 1] = v

			if k ~= #tbl then
				gMsgC(color_neutral)
				gMsgF(", ")
				strOut[#strOut + 1] = ", "
			end
		end

		gMsgC(color_neutral)
		gMsgF(")")
		strOut[#strOut + 1] = ")"

		if shouldComma then
			gMsgC(color_neutral)
			gMsgF(",")
			strOut[#strOut + 1] = ","
		end

		if shouldComment then
			gMsgC(color_comment)
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
			gMsgC(color_global)
			gMsgF("NULL")
			strOut[#strOut + 1] = "NULL"
			return table_concat(strOut, "")
		elseif value == game.GetWorld() then
			gMsgC(color_global)
			gMsgF("game.GetWorld")
			strOut[#strOut + 1] = "game.GetWorld"

			gMsgC(color_neutral)
			gMsgF("()")
			strOut[#strOut + 1] = "()"

			if shouldComma then
				gMsgC(color_neutral)
				gMsgF(",")
				strOut[#strOut + 1] = ","
			end

			if shouldComment then
				gMsgC(color_comment)
				gMsgF(string_format(" -- %s, %s", value:GetClass(), value:GetModel()))
				strOut[#strOut + 1] = string_format(" -- %s, %s", value:GetClass(), value:GetModel())
			end

			return table_concat(strOut, "")
		elseif value:EntIndex() < 0 and value:GetModel() and value:GetModel() ~= "" then
			gMsgC(color_global)
			gMsgF("ClientsideModel")
			strOut[#strOut + 1] = "ClientsideModel"

			gMsgC(color_neutral)
			gMsgF("(")
			strOut[#strOut + 1] = "("

			gMsgC(type_colors[TYPE_STRING])
			gMsgF(string_format("%q", value:GetModel()))
			strOut[#strOut + 1] = string_format("%q", value:GetModel())

			gMsgC(color_neutral)
			gMsgF(")")
			strOut[#strOut + 1] = ")"

			if shouldComma then
				gMsgC(color_neutral)
				gMsgF(",")
				strOut[#strOut + 1] = ","
			end

			return table_concat(strOut, "")
		elseif value:IsPlayer() then
			gMsgC(color_global)
			gMsgF("player.GetByID")
			strOut[#strOut + 1] = "player.GetByID"

			gMsgC(color_neutral)
			gMsgF("(")
			strOut[#strOut + 1] = "("

			gMsgC(type_colors[TYPE_NUMBER])
			gMsgF(value:EntIndex())
			strOut[#strOut + 1] = value:EntIndex()

			gMsgC(color_neutral)
			gMsgF(")")
			strOut[#strOut + 1] = ")"

			if shouldComma then
				gMsgC(color_neutral)
				gMsgF(",")
				strOut[#strOut + 1] = ","
			end

			if shouldComment then
				gMsgC(color_comment)
				gMsgF(string_format(" -- %s, %s", value:SteamID(), value:Name()))
				strOut[#strOut + 1] = string_format(" -- %s, %s", value:SteamID(), value:Name())
			end

			return table_concat(strOut, "")
		else
			gMsgC(color_global)
			gMsgF("Entity")
			strOut[#strOut + 1] = "Entity"

			gMsgC(color_neutral)
			gMsgF("(")
			strOut[#strOut + 1] = "("

			gMsgC(type_colors[TYPE_NUMBER])
			gMsgF(value:EntIndex())
			strOut[#strOut + 1] = value:EntIndex()

			gMsgC(color_neutral)
			gMsgF(")")
			strOut[#strOut + 1] = ")"

			if shouldComma then
				gMsgC(color_neutral)
				gMsgF(",")
				strOut[#strOut + 1] = ","
			end

			if shouldComment then
				gMsgC(color_comment)
				gMsgF(string_format(" -- %s", value:GetClass()))
				strOut[#strOut + 1] = string_format(" -- %s", value:GetClass())

				if value:GetModel() then
					gMsgF(string_format(", %s", value:GetModel()))
					strOut[#strOut + 1] = string_format(", %s", value:GetModel())
				end

				if #value:GetChildren() > 0 then
					gMsgF(string_format(", %d child" .. (#value:GetChildren() ~= 1 and "ren" or ""), #value:GetChildren()))
					strOut[#strOut + 1] = string_format(", %d child" .. (#value:GetChildren() ~= 1 and "ren" or ""), #value:GetChildren())
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

		gMsgC(color_neutral)
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
					table_insert(args, last_arg)
					last_arg = debug_getlocal(value, arg)
					arg = arg + 1
				end

				gMsgF(table_concat(args, ", "))
				strOut[#strOut + 1] = table_concat(args, ", ")
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
			gMsgC(color_neutral)
			gMsgF(",")
			strOut[#strOut + 1] = ","
		end

		if shouldComment then
			gMsgC(color_comment)
			gMsgF(aux)
			strOut[#strOut + 1] = aux
		end

		return table_concat(strOut, "")
	end

	-- Panels
	if ispanel(value) then
		gMsgC(color_neutral)
		gMsgF("{ ")
		strOut[#strOut + 1] = "{"

		gMsgC(color_global)
		gMsgF("Panel")
		strOut[#strOut + 1] = "Panel"

		gMsgC(color_neutral)
		gMsgF(": ")
		strOut[#strOut + 1] = ": "

		local class = "NULL Panel"
		if IsValid(value) then
			class = value:GetClassName()
		end
		gMsgC(color_global)
		gMsgF(class)
		strOut[#strOut + 1] = class

		gMsgC(color_neutral)
		gMsgF(" }")
		strOut[#strOut + 1] = " }"

		if shouldComma then
			gMsgC(color_neutral)
			gMsgF(",")
			strOut[#strOut + 1] = ","
		end

		if shouldComment and IsValid(value) then
			gMsgC(color_comment)
			gMsgF(string_format(" -- %s%s", value:IsVisible() and "Visible" or "Invisible", #value:GetChildren() > 0 and string_format(", %d child" .. (#value:GetChildren() ~= 1 and "ren" or ""), #value:GetChildren()) or ""))
			strOut[#strOut + 1] = string_format(" -- %s%s", value:IsVisible() and "Visible" or "Invisible", #value:GetChildren() > 0 and string_format(", %d child" .. (#value:GetChildren() ~= 1 and "ren" or ""), #value:GetChildren()) or "")
		end
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
		gMsgC(color_neutral)
		gMsgF(",")
		strOut[#strOut + 1] = ","
	end

	return table_concat(strOut, "")
end


-- Associated to object keys
local objID

local function isprimitive( value )
	local id = TypeID(value)

	return id <= TYPE_FUNCTION and id ~= TYPE_TABLE
end

local function InternalPrintTable( table, path, prefix, names, todo, recursive )

	-- Collect keys and some info about them
	local keyList  = {}
	local keyStr   = {}
	local shouldPrintKey = {}

	local keyCount = 0

	for key, value in pairs( table ) do
		-- Add to key list for later sorting
		table_insert(keyList, key)

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
		gMsgC(color_neutral)
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
		str = IsValidVariableName(str) and str or "[" .. (shouldPrintKey[key] and str or (isnumber(tonumber(str)) and str or string_format("%q", str))) .. "]"

		keyLen = math_max(keyLen, string_len(str))
	end

	-- Sort table keys
	if keyCount > 1 then
		table_sort( keyList, function( A, B )
			-- Sort numbers numerically correct
			if isnumber(A) and isnumber(B) then
				return A < B
			end

			-- Order by string representation
			return string_lower(keyStr[A]) < string_lower(keyStr[B])

		end )
	end

	-- Mark object as done
	todo[table] = nil

	if not recursive and IsColor(table) then
		gMsgC(color_comment)
		gMsgF("-- Color: ")
		gMsgC(value)
		gMsgF("█")
		gMsgN()
	end

	gMsgC(color_neutral)
	gMsgF("{")
	gMsgN()
	gMsgC(Color(255, 255, 255))

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
				gMsgC(color_name)
				gMsgF(sKey)
			else
				gMsgC(color_neutral)
				gMsgF("[")

				gMsgC(isnumber(tonumber(sKey)) and type_colors[TYPE_NUMBER] or type_colors[TYPE_STRING])
				gMsgF(isnumber(tonumber(sKey)) and sKey or string_format("%q", sKey))

				gMsgC(color_neutral)
				gMsgF("]")

				sKey = "[" .. (isnumber(tonumber(sKey)) and sKey or string_format("%q", sKey)) .. "]"
			end
		else
			gMsgC(color_neutral)
			gMsgF("[")

			local str = InternalPrintValue(key, false, false)

			gMsgC(color_neutral)
			gMsgF("]")

			sKey = "[" .. str .. "]"
		end

		-- Describe non primitives
		--describe = istable(value) and ( not names[value] or todo[value] ) and value ~= NIL

		-- Print key postfix
		local padding = keyLen - string_len(sKey)
		local postfix = string_format("%s = ", string_rep(' ', padding))

		gMsgC(color_neutral)
		gMsgF(postfix)

		-- Print the value (or the reference name)
		if vName and not todo[value] then
			gMsgC(color_global)
			gMsgF(vName)
		else
			if istable(value) then
				if printtable then
					if IsColor(value) then
						InternalPrintValue(value)
					else
						local base = {
							[_G]    = "_G",
							[table] = "root",
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
		gMsgC(Color(255, 255, 255))
	end

	if not recursive then
		if maxKeyIndex > -1 and keyCount > maxKeyIndex then
			gMsgC(color_comment)
			gMsgF(string_format(prefix .. "  -- %s more...", keyCount - maxKeyIndex))
			gMsgN()
		end
	end

	gMsgF(prefix)
	gMsgC(color_neutral)
	gMsgF("}")
	if not recursive then
		gMsgN()
	end

	if not recursive then
		gMsgC(color_comment)
		gMsgF(string_format("-- %d total entr%s.", keyCount, keyCount == 1 and "y" or "ies"))
		gMsgN()
	end
end

function PrintTableGrep( table, grep, proximity )
	local base = {
		[_G]    = "_G",
		[table] = "root"
	}

	gBegin(grep, proximity)
		objID = 0
		InternalPrintTable(table, nil, "", base, {})
	gFinish()
end

function PrintLocals( level )
	local level = level or 2
	local hash  = {}

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

	PrintTableGrep( hash )
end

function show(...)
	local n = select('#', ...)
	local tbl = {...}


	for i = 1, n do
		local value = tbl[i]
		if not value then
			InternalPrintValue(NIL, true, false)
			gMsgN()

			continue
		end

		local addr = string_format("%p", value)
		if addr ~= "NULL" and not isstring(value) then
			gMsgC(color_comment)
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
						gMsgC(color_comment)
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
				if value:IsPlayer() then
					gMsgC(color_comment)
					gMsgF("-- " .. value:Name())
					gMsgN()

					gMsgC(color_comment)
					gMsgF("-- " .. value:SteamID())
					gMsgN()
				end

				gMsgC(color_comment)
				gMsgF("-- " .. value:GetClass())
				gMsgN()

				if value:GetModel() then
					gMsgC(color_comment)
					gMsgF("-- " .. value:GetModel())
					gMsgN()
				end

				if value == game.GetWorld() then
					gMsgC(type_colors[TYPE_FUNCTION])
					gMsgF("game.GetWorld")

					gMsgC(color_neutral)
					gMsgF("()")
				else
					gMsgC(color_global)
					gMsgF("Entity")

					gMsgC(color_neutral)
					gMsgF("(")

					gMsgC(type_colors[TYPE_NUMBER])
					gMsgF(value:EntIndex())

					gMsgC(color_neutral)
					gMsgF(")")
				end

				gMsgN()

				PrintTableGrep(value:GetTable())

				if #value:GetChildren() > 0 and not value:IsPlayer() then
					gMsgC(color_comment)
					gMsgF("-- Children:")
					gMsgN()
					PrintTableGrep(value:GetChildren())
				end
			end
		elseif ispanel(value) then
			if not IsValid(value) then
				InternalPrintValue(value, true, false)
				gMsgN()
			else
				PrintTableGrep(value:GetTable())

				if #value:GetChildren() > 0 then
					gMsgC(color_comment)
					gMsgF("-- Children:")
					gMsgN()
					PrintTableGrep(value:GetChildren())
				end
			end
		elseif isfunction(value) then
			if GLib and syntaxParser then
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

						local lines = string_split(data, "\n")
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
							gMsgC(color_comment)
							gMsgF(string_format("-- Failed to decompile: %s",out))
							gMsgN()
							code = ""
						else
							code = out
						end
					end

					local info = f.InfoTable
					if info.linedefined ~= info.lastlinedefined then
						gMsgC(color_comment)
						gMsgF(string_format("-- %s: %i-%i", info.short_src, info.linedefined, info.lastlinedefined))
					else
						gMsgC(color_comment)
						gMsgF(string_format("-- %s: %i", info.short_src, info.linedefined))
					end
					gMsgN()

					local formatted = syntaxParser.process(code)
					for k, v in pairs(formatted) do
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
				gMsgC(color_comment)
				gMsgF("-- " .. tostring (codePointCount) .. " code point" .. (codePointCount == 1 and "" or "s"))
				gMsgN()

				local j = 0
				for c in UTF8_Iterator(value) do
					if j >= 5 then
						gMsgC(color_comment)
						gMsgF("-- ...")
						gMsgN()
						break
					end
					j = j + 1

					gMsgC(color_comment)
					gMsgF("-- " .. string_format("U+%06X ", UTF8_Byte(c)) .. (not characterPrintingBlacklist[c] and c or " ") .. " " .. GLib.Unicode.GetCharacterName(c))
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
	table_insert(strResult, txt)
end

local toStringMsgN = function()
	table_insert(strResult, "\n")
end

local toStringMsgC = function(_, txt)
	table_insert(strResult, txt)
end

local toStringMsgC2 = function(col, txt)
	local outcol = ("\x0E%s\x0F"):format(tostring(col))
	table_insert(strResult, outcol)
	table_insert(strResult, txt)
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
