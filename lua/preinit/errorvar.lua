if not HolyLib then return end

-- https://gist.github.com/bjurd/99ed6148307b2172a34079db1e96ee3f

ErrorVar = ErrorVar or {}
local _R = HolyLib.GetRegistry()

ErrorVar.OriginalErrorHandler = ErrorVar.OriginalErrorHandler or _R[1]

local function MsgN(...)
	local args = { ... }
	for i, v in ipairs(args) do
		args[i] = tostring(v)
	end

	local str = table.concat(args, "")

	if epoe then
		epoe.api.error(str)
		epoe.RealPrint(str)
	else
		print(str)
	end
end

function ErrorVar.ErrorHandler(...)
	local Level = 2
	local Info = debug.getinfo(Level)

	while Info do
		local Indent = string.rep("    ", Level - 2)
		local Function = Info.func

		if isfunction(Function) then
			local FunctionName = Info.name or "[Unknown Function]"

			MsgN(Indent, "Traces of level ", Level, " (", FunctionName, ")")

			for i = 1, Info.nups do
				local Name, Value = debug.getupvalue(Function, i)
				MsgN(Indent, "- UpValue ", i, " (", Name, ") (", type(Value), ") = ", Value)
			end

			local Local = 1

			while true do
				local Name, Value = debug.getlocal(Level, Local)
				if not Name then break end

				MsgN(Indent, "- Local ", Local, " (", Name, ") (", type(Value), ") = ", Value)

				Local = Local + 1
			end
		end

		Level = Level + 1

		if Level > 2048 then
			-- Stack overflow

			-- The maximum stack size is dependent on system stuff
			-- Seems to be more around 32767, but not quite that high
			-- 2048 is plenty to get an idea of what's happening without killing the server

			break
		end

		Info = debug.getinfo(Level)
	end

	return ErrorVar.OriginalErrorHandler(...)
end

_R[1] = ErrorVar.ErrorHandler
