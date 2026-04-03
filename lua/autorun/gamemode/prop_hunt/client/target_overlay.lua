local USABLE_PROP_ENTITIES = {
	prop_physics = true,
	prop_physics_multiplayer = true,
}

local OVERLAY = Color(0, 192, 0)
hook.Add("PreDrawHalos", "ph_target_overlay", function()
	local ply = LocalPlayer()
	if ply:Team() ~= TEAM_PROPS then return end

	local ent = ply:GetUseEntity()
	if not IsValid(ent) then return end
	if not USABLE_PROP_ENTITIES[ent:GetClass()] then return end

	halo.Add({ ent }, OVERLAY, 1, 1, 2, true, false)
end)
