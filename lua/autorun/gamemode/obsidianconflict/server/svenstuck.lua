local TAG = "svenstuck"

hook.Add("FindUseEntity", TAG, function(ply, ent)
	local tr = ply:GetEyeTrace()
	if tr.Entity:IsValid() and tr.Entity:IsPlayer() then
		return tr.Entity
	end
end)

hook.Add("PlayerUse", TAG, function(ply, ent)
	if not (ply:IsValid() and ent:IsValid()) then return end
	if not ent:IsPlayer() then return end
	if CurTime() < (ply._next_svenstuck or 0) then return end

	local pos1 = ply:GetPos()
	local pos2 = ent:GetPos()
	ply:SetPos(pos2)
	ent:SetPos(pos1)

	ply._next_svenstuck = CurTime() + 1

	return true
end)
