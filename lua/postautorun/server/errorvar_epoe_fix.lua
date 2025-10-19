if not ErrorVar then return end
if not epoe then return end

hook.Add("OnLuaError", "epoe_errorvar_fix", function(err, realm, stack, addon, wsid)
	local str = { "[ERROR] " .. err }
	for i, line in ipairs(stack) do
		str[#str + 1] = Format("%s%d. %s- %s:%d", " " .. string.rep(" ", i), i, line.Function, line.File, line.Line)
	end

	epoe.api.error(table.concat(str, "\n"))
end)
