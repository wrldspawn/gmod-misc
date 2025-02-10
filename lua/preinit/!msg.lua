if not _G.Color then include("includes/util/color.lua") end
-- recolor Msg/N to be EPOE's color to discern as a prefix
local COLOR_MSG = Color(255, 181, 80)

function Msg(...)
	local args = { ... }
	local newArgs = {}
	for _, arg in ipairs(args) do
		newArgs[#newArgs + 1] = tostring(arg)
	end

	MsgC(COLOR_MSG, table.concat(newArgs, ""))
end

function MsgN(...)
	Msg(..., "\n")
end
