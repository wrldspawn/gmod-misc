local COL_SET = Color(0, 196, 0)
local COL_UNSET = Color(196, 0, 0)
local COL_CHAR = "█\t"

local function FindFlags(inp, enum_name)
	if not isnumber(inp) then return end
	if not isstring(enum_name) then return end
	if #enum_name:Trim() == 0 then return end

	local ENUM = {}
	local largest = 0

	if enum_name:sub(#enum_name) == "." then
		local prefix = enum_name:sub(0, #enum_name - 1)
		if not _G[prefix] then return end

		for k, v in next, _G[prefix] do
			if not isstring(k) then continue end
			if not isnumber(v) then continue end

			ENUM[enum_name .. k] = v
			ENUM[v] = enum_name .. k

			if v > largest then
				largest = v
			end
		end
	else
		local pattern = string.format("^%s", string.PatternSafe(enum_name))

		-- populate enum field
		for k, v in next, _G do
			if not isstring(k) then continue end
			if not k:find(pattern) then continue end
			if not isnumber(v) then continue end

			ENUM[k] = v
			ENUM[v] = k

			if v > largest then
				largest = v
			end
		end
	end

	local bits = math.ceil(math.log(largest) / math.log(2))

	-- iterate over enum, checking if our input has the flags
	for i = 0, bits do
		local val = bit.lshift(1, i)

		if bit.band(inp, val) == val then
			MsgC(COL_SET, COL_CHAR)
			print("SET", val, ENUM[val])
		else
			MsgC(COL_UNSET, COL_CHAR)
			print("UNSET", val, ENUM[val])
		end
	end
end

FindFlags(8452, "SF_")
