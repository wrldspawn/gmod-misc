hook.Add("CalcMainActivity", "misc_animations", function(ply, vel)
	if not IsValid(ply) then return end

	local shouldCancel = ply:IsOnGround() or ply:WaterLevel() > 0

	if shouldCancel and ply:GetNWBool("ma_falling") then
		ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
		if SERVER then
			ply:SetNWBool("ma_falling", false)
		end
	end

	if ply:GetMoveType() == MOVETYPE_WALK and not shouldCancel then
		local v = Vector(vel)
		v.x = 0
		v.y = 0

		if v.z <= -1000 then
			if not ply:GetNWBool("ma_falling") then
				ply:AnimRestartGesture(GESTURE_SLOT_CUSTOM, ACT_ZOMBIE_LEAPING, false)
				ply:SetPlaybackRate(1)

				if SERVER then
					ply:SetNWBool("ma_falling", true)
				end
			end

			return ACT_ZOMBIE_LEAPING
		end
	end
end)
