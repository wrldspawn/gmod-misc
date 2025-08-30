-- Abstracted from GCompute
if AddCSLuaFile then AddCSLuaFile() end
module("syntaxParser", package.seeall)

local parsers = {}
function registerParser(pattern, callback)
	pattern = istable(pattern) and pattern or { pattern }
	table.insert(parsers, { pattern, callback })
end

function parseText(text, whitespace)
	if whitespace == nil then whitespace = false end

	local parseData = {}
	parseData.commentBreaker = nil
	parseData.stringBreaker = nil
	parseData.lastColor = nil
	parseData.whitespace = whitespace
	parseData.parsed = {}

	function parseData.Append(...)
		for _, val in ipairs({ ... }) do
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
				local matches = { text:match("^(" .. pattern .. ")") }

				if #matches ~= 0 then
					local result = data[2](parseData, text, patternId, unpack(matches))
					if result then
						text = (isstring(result) and result or text:sub(#matches[1] + 1))
						goto endof
					end
				end
			end
		end

		::endof::
	end

	return parseData
end

local WHITESPACE = Color(114, 103, 103)
local COMMENT    = Color(129, 117, 117)
local PUNCT      = Color(168, 152, 152)
local FIELD      = Color(212, 192, 192)
local NEUTRAL    = Color(201, 199, 205)
local STRING     = Color(144, 185, 159)
local GLOBAL     = Color(172, 161, 207)
local NUMBER     = Color(226, 158, 202)
local OPERATOR   = Color(230, 185, 157)
local KEYWORD    = Color(172, 161, 207)
local FUNCTION   = Color(133, 181, 186)
local CSTYLE     = Color(234, 131, 165)
local ARGUMENT   = Color(245, 160, 145)
local CALL       = Color(193, 192, 212)

registerParser("\t", function(parseData, text, id, match)
	if parseData.whitespace then
		parseData.Append(WHITESPACE, "       \xc2\xbb")
		return true
	end
end)
registerParser(" ", function(parseData, text, id, match)
	if parseData.whitespace then
		parseData.Append(WHITESPACE, "\xc2\xb7")
		return true
	end
end)

local escapes = {}
for _, v in ipairs({ "\\", "a", "b", "f", "n", "r", "t", "v", "x", '"', "'", }) do
	escapes[v] = true
end

registerParser({ "\\%d%d?%d?", "\\x[0-9a-fA-F][0-9a-fA-F]" }, function(parseData, text, id, match)
	parseData.Append(NUMBER, match)
	parseData.lastLastChar = nil
	parseData.lastChar = nil
	return true
end)

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
		if result and parseData.lastChar ~= "\\" then
			parseData.stringBreaker = nil
			parseData.lastLastChar = nil
			parseData.lastChar = nil
			parseData.Append(STRING, result)

			return text:sub(#result + 1)
		elseif (parseData.lastLastChar ~= "\\" and parseData.lastChar == "\\" and escapes[match]) or match == "\\" then
			parseData.Append(NUMBER, match)
			parseData.lastLastChar = parseData.lastChar
			parseData.lastChar = match
			return true
		elseif parseData.lastLastChar == "\\" and parseData.lastChar == "\\" and match == '"' then
			parseData.Append(STRING, match)
			parseData.stringBreaker = nil
			parseData.lastLastChar = nil
			parseData.lastChar = nil
			return true
		else
			parseData.Append(STRING, match)
			parseData.lastLastChar = parseData.lastChar
			parseData.lastChar = match
			return true
		end
	end
end)

registerParser({ "%-%-%[(=-)%[", "%-%-", "/%*", "//" }, function(parseData, text, id, match, equals)
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

registerParser({ "%[(=-)%[", '"', "'" }, function(parseData, text, id, match, equals)
	if id == 1 then
		parseData.stringBreaker = "]" .. equals .. "]"
	elseif id == 2 then
		parseData.stringBreaker = '"'
	elseif id == 3 then
		parseData.stringBreaker = "'"
	end

	parseData.Append(STRING, match)
	return true
end)

registerParser({ "\r\n", "\r", "\n" }, function(parseData, text, id, match)
	if parseData.whitespace then
		local str = match:gsub("\n", "\xe2\x86\xb2\n"):gsub("\r", "\xc2\xa4")
		parseData.Append(WHITESPACE, str)
	else
		-- this is to fix newlines from not acting as newlines in epoe
		parseData.Append(Color(0, 0, 0, 0), match)
	end
	return true
end)

registerParser({ "function%((.-)%)", "function (.-)%((.-)%)" }, function(parseData, text, id, match, name, arguments)
	parseData.Append(FUNCTION, "function")

	if name and not arguments then
		arguments = name
		name = nil
	end

	if parseData.functionCount ~= nil then
		parseData.prevFunctionArgs = table.Copy(parseData.functionArgs)
		parseData.functionCount = parseData.functionCount + 1
	else
		parseData.functionCount = 1
		parseData.functionArgs = {}
	end
	if parseData.scopeCount ~= nil then
		parseData.prevScopeCount = parseData.scopeCount
	end
	parseData.scopeCount = 0

	if name then
		parseData.Append(" ")
		local split
		local sep
		if name:find("%.") then
			split = string.Explode(".", name)
			sep = "."
		elseif name:find(":") then
			split = string.Explode(":", name)
			sep = ":"
			parseData.functionArgs.self = true
		end

		if split then
			for i, part in ipairs(split) do
				if i == #split then break end
				parseData.Append(NEUTRAL, part)
				parseData.Append(PUNCT, sep)
			end
			parseData.Append(CALL, split[#split])
		else
			parseData.Append(CALL, name)
		end
	end

	if arguments then
		parseData.Append(PUNCT, "(")

		arguments = arguments:Trim()
		if arguments:find(",") then
			local split = string.Explode(",[%w]*", arguments, true)

			for i, part in ipairs(split) do
				if i == #split then break end
				local p = part:Trim()
				parseData.Append(ARGUMENT, p)
				parseData.functionArgs[p] = true
				parseData.Append(PUNCT, ", ")
			end
			local p = split[#split]:Trim()
			if p ~= "..." then parseData.functionArgs[p] = true end
			parseData.Append(p == "..." and KEYWORD or ARGUMENT, p)
		else
			if arguments ~= "..." then parseData.functionArgs[arguments] = true end
			parseData.Append(arguments == "..." and KEYWORD or ARGUMENT, arguments)
		end

		parseData.Append(PUNCT, ")")
	end
	return text:sub(#match + 1)
end)

registerParser(
	{ "0b[01]+", "0x[0-9a-fA-F]+", "[0-9]+%.[0-9]*e[-+]?[0-9]+%.[0-9]*", "[0-9]+%.[0-9]*e[-+]?[0-9]+", "[0-9]+%.[0-9]*",
		"[0-9]+e[-+]?[0-9]+%.[0-9]*", "[0-9]+e[-+]?[0-9]+", "[0-9]+" },
	function(parseData, text, id, match)
		parseData.Append(NUMBER, match)
		return true
	end
)

local keywordColors = {}
for _, v in ipairs({ "if", "then", "else", "elseif", "while", "for", "in", "do", "break", "repeat", "until", "return", "continue", "function", "local", "not", "and", "or", "goto", "end" }) do
	keywordColors[v] = KEYWORD
end
keywordColors["false"] = OPERATOR
keywordColors["true"] = OPERATOR
keywordColors["nil"] = OPERATOR
keywordColors["NULL"] = KEYWORD

local cstyleOperators = {}
for _, v in ipairs({ "!", "!=", "||", "&&" }) do cstyleOperators[v] = true end

local punctuation = {}
for _, v in ipairs({ "{", "}", "(", ")", ",", ".", "[", "]", ":", ";" }) do punctuation[v] = true end

local operators = {}
for _, v in ipairs({ "+", "-", "/", "*", "%", "^", "#", "..", "=", "<", ">", "<=", ">=", "==", "~=" }) do
	operators[v] = true
end


registerParser("[%a_][%w_]*", function(parseData, text, id, match)
	local targetColor = keywordColors[match] ~= nil and keywordColors[match] or NEUTRAL

	local idx = text:find(match)
	if parseData.functionArgs and parseData.functionArgs[match] and not text:sub(idx - 1, idx - 1):match("[:.]") then
		targetColor = ARGUMENT
	elseif _G[match] then
		targetColor = GLOBAL
	elseif text:sub(match:len() + 1, match:len() + 1) == "(" then
		targetColor = CALL
	end
	if parseData.prevPunct == "." then
		targetColor = FIELD
		parseData.prevPunct = nil
	end

	if match == "then" or match == "do" then
		if parseData.scopeCount == nil then
			parseData.scopeCount = 0
		end
		parseData.scopeCount = parseData.scopeCount + 1
	elseif match == "elseif" then
		parseData.scopeCount = parseData.scopeCount - 1
	elseif match == "end" then
		if parseData.scopeCount == nil or parseData.scopeCount == 0 then
			targetColor = FUNCTION
			parseData.functionCount = parseData.functionCount - 1
			if parseData.prevScopeCount ~= nil then
				parseData.scopeCount = parseData.prevScopeCount
			end
			if parseData.prevFunctionArgs ~= nil then
				parseData.functionArgs = parseData.prevFunctionArgs
			end
		else
			parseData.scopeCount = parseData.scopeCount - 1
		end
	end

	parseData.Append(targetColor, match)
	return true
end)

registerParser("::([%a_][%w_]*)::", function(parseData, text, id, match, label)
	parseData.Append(PUNCT, "::")
	parseData.Append(KEYWORD, label)
	parseData.Append(PUNCT, "::")
	return true
end)

registerParser({ "%p", "%p+" }, function(parseData, text, id, match)
	if cstyleOperators[match] ~= nil then
		parseData.Append(CSTYLE, match)
		return true
	elseif operators[match] ~= nil then
		parseData.Append(OPERATOR, match)
		return true
	elseif match == "..." then
		parseData.Append(KEYWORD, match)
		return true
	elseif punctuation[match] ~= nil then
		parseData.Append(PUNCT, match)
		parseData.prevPunct = match
		return true
	end
end)

registerParser(".", function(parseData, text, id, match)
	parseData.Append(NEUTRAL, match)
	return true
end)

function process(text, whitespace)
	return parseText(text, whitespace).ToTable()
end
