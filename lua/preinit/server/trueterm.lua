-- https://github.com/wrldspawn/gmsv_trueterm/releases
if system.IsLinux() then
	pcall(require, "trueterm")
	
	if not _G.Color then include("includes/util/color.lua") end
	local COLOR_WHITE = Color(255, 255, 255)
	
	-- force print statements to be white so you can use Msg as a prefix
	function print(...)
		local args = {...}
		local newArgs = {}
		for _, arg in ipairs(args) do
			newArgs[#newArgs + 1] = tostring(arg)
		end
		
		MsgC(COLOR_WHITE, table.concat(newArgs, "\t") .. "\n")
	end
end