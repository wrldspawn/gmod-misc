local Unstuck = util.UnstuckPlayer
local IsStuck

hook.Add("PlayerSay", "unstuck", function(ply, str)
	if Unstuck == nil then
		return
	elseif IsStuck == nil then
		IsStuck = select(2, debug.getupvalue(Unstuck, 1))
	end

	if str:find("stuck") and IsStuck and IsStuck(ply) then
		Unstuck(ply)
	end

	if str:find("^[!/%.]stuck") then
		return ""
	end
end)
