-- recolor Msg/N to be EPOE's color to discern as a prefix
local COLOR_MSG = { r = 255, g = 181, b = 80, a = 255 }

local MsgC = MsgC
local table_concat = table.concat
local tostring = tostring
local ipairs = ipairs

function Msg(...)
	local args = { ... }
	local newArgs = {}
	for _, arg in ipairs(args) do
		newArgs[#newArgs + 1] = tostring(arg)
	end

	MsgC(COLOR_MSG, table_concat(newArgs, ""))
end

function MsgN(...)
	local args = { ... }
	if #args == 0 then
		Msg("\n")
	else
		Msg(..., "\n")
	end
end
