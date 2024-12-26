-- Abstracted from GCompute
AddCSLuaFile()
module("syntaxParser", package.seeall)

local parsers = {}
function registerParser(pattern, callback)
	pattern = istable(pattern) and pattern or {pattern}
	table.insert(parsers, {pattern, callback})
end

function parseText(text)
	local parseData = {}
	parseData.commentBreaker = nil
	parseData.stringBreaker = nil
	parseData.lastColor = nil
	parseData.parsed = {}

	function parseData.Append(...)
		for _, val in ipairs({...}) do
			local lastVal = parseData.parsed[#parseData.parsed]

			if isstring(lastVal) and isstring(val) then
				parseData.parsed[#parseData.parsed] = lastVal .. val
				continue
			elseif IsColor(lastVal) and IsColor(val) then
				parseData.parsed[#parseData.parsed] = val
				parseData.lastColor = val
				continue
			end

			if IsColor(val) then
				if val ~= parseData.lastColor then
					parseData.lastColor = val
				else
					continue
				end
			end

			table.insert(parseData.parsed, val)
		end
	end

	function parseData.Print()
		local copy = table.Copy(parseData.parsed)
		repeat MsgC(table.remove(copy, 1), table.remove(copy, 1)) until #copy == 0
	end

	function parseData.ToTable()
		return table.Copy(parseData.parsed)
	end

	local steps = 100000
	while text ~= "" do
		if steps == 0 then error("failed") end
		steps = steps - 1

		for _, data in ipairs(parsers) do
			for patternId, pattern in ipairs(data[1]) do
				local matches = {text:match("^(" .. pattern .. ")")}

				if #matches ~= 0 then
					local result = data[2](parseData, text, patternId, unpack(matches))
					if result then
						text = (isstring(result) and result or text:sub(#matches[1]+1))
						goto endof
					end
				end
			end
		end

		::endof::
	end

	return parseData
end

local COMMENT  = Color( 93,  93,  93)
local NEUTRAL  = Color(222, 219, 235)
local STRING   = Color(162, 186, 168)
local GLOBAL   = Color(180, 164, 222)
local NUMBER   = Color(180, 164, 222)
local KEYWORD  = Color(245,  93, 143)
local FUNCTION = Color(170, 186, 231)
local CSTYLE   = Color(232,  63, 128)
local ARGUMENT = Color(234, 202, 192)

registerParser(".", function(parseData, text, id, match)
	if parseData.commentBreaker then
		local result = text:match("^" .. parseData.commentBreaker)
		if result then
			parseData.commentBreaker = nil
			parseData.Append(result)
			return text:sub(#result + 1)
		else
			parseData.Append(COMMENT, match)
			return true
		end

	elseif parseData.stringBreaker then
		local result = text:match("^" .. parseData.stringBreaker)
		if result and parseData.lastChar ~= [[\]] then
			parseData.stringBreaker = nil
			parseData.lastChar = nil
			parseData.Append(result)

			return text:sub(#result + 1)
		else
			parseData.Append(STRING, match)
			parseData.lastChar = match
			return true
		end

	end
end)

registerParser({"%-%-%[(=-)%[", "%-%-", "/%*", "//"}, function(parseData, text, id, match, equals)
	if id == 1 then
		parseData.commentBreaker = "]" .. equals .. "]"
	elseif id == 2 or id == 4 then
		parseData.commentBreaker = "\n"
	elseif id == 3 then
		parseData.commentBreaker = "*/"
	end

	parseData.Append(COMMENT, match)
	return true
end)

registerParser({"%[(=-)%[", "\"", "'"}, function(parseData, text, id, match, equals)
	if id == 1 then
		parseData.stringBreaker = "]" .. equals .. "]"
	elseif id == 2 then
		parseData.stringBreaker = "\""
	elseif id == 3 then
		parseData.stringBreaker = "'"
	end

	parseData.Append(STRING, match)
	return true
end)

-- this is to fix newlines from not acting as newlines in epoe
registerParser({"\r\n", "\r", "\n"}, function(parseData, text, id, match)
	parseData.Append(Color(0, 0, 0, 0), match)
	return true
end)

registerParser("function(.-)%((.-)%)", function (parseData, text, id, match, name, arguments)
	parseData.Append(KEYWORD, "function")

	if name:find("%.") then
		local split = string.Explode(".", name)

		for i, part in ipairs(split) do
			if i == #split then break end
			parseData.Append(NEUTRAL, part .. ".")
		end
		parseData.Append(FUNCTION, split[#split])
	else
		parseData.Append(FUNCTION, name)
	end

	if arguments then
		parseData.Append(NEUTRAL, "(")

		arguments = arguments:Trim()
		if arguments:find(",") then
			local split = string.Explode(",[%w]*", arguments, true)

			for i, part in ipairs(split) do
				if i == #split then break end
				parseData.Append(ARGUMENT, part:Trim())
				parseData.Append(NEUTRAL, ", ")
			end
			parseData.Append(ARGUMENT, split[#split]:Trim())
		else
			parseData.Append(ARGUMENT, arguments)
		end

		parseData.Append(NEUTRAL, ")")
	end
	return text:sub(#match + 1)
end)

registerParser({"0b[01]+", "0x[0-9a-fA-F]+", "[0-9]+%.[0-9]*e[-+]?[0-9]+%.[0-9]*", "[0-9]+%.[0-9]*e[-+]?[0-9]+", "[0-9]+%.[0-9]*", "[0-9]+e[-+]?[0-9]+%.[0-9]*", "[0-9]+e[-+]?[0-9]+", "[0-9]+"}, function(parseData, text, id, match)
	parseData.Append(NUMBER, match)
	return true
end)

local keywordColors = {}
for _, v in pairs({"if", "then", "else", "elseif", "end", "while", "for", "in", "do", "break", "repeat", "until", "return", "continue", "function", "local", "not", "and", "or", "goto"}) do keywordColors[v] = KEYWORD end
keywordColors["false"] = NUMBER
keywordColors["true"] = NUMBER
keywordColors["nil"] = NUMBER
keywordColors["NULL"] = NUMBER

local cstyleOperators = {}
for _, v in pairs({"!", "!=", "||", "&&", "!"}) do cstyleOperators[v] = true end

registerParser("[%a_][%w_]*", function(parseData, text, id, match)
	local targetColor = keywordColors[match] ~= nil and keywordColors[match] or NEUTRAL
	if _G[match] then
		targetColor = GLOBAL
	end
	if text:sub(match:len() + 1, match:len() + 1) == "(" then
		targetColor = FUNCTION
	end
	parseData.Append(targetColor, match)
	return true
end)

registerParser("%p+", function(parseData, text, id, match)
	if cstyleOperators[match] ~= nil then
		parseData.Append(CSTYLE, match)
		return true
	end
end)

registerParser({".", "::([%a_][%w_]*)::"}, function(parseData, text, id, match)
	parseData.Append(NEUTRAL, match)
	return true
end)

function process(txt)
	return parseText(txt).ToTable()
end
