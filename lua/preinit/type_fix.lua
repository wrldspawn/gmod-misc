local C_type = type
local getmetatable = getmetatable
function type(v)
	local v_type = C_type(v)
	if v_type ~= "userdata" then return v_type end

	local mt = getmetatable(v)
	if not mt then return "UserData" end

	local mt_name = mt.MetaName
	if C_type(mt_name) ~= "string" then return "UserData" end

	return mt_name
end
