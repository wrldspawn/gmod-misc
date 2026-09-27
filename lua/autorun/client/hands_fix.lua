hook.Add("PreDrawPlayerHands", "hands_shadow_fix", function(hands, vm, ply, wep)
	hands:DestroyShadow()
	local target = LocalPlayer():GetObserverTarget()
	if target:IsValid() then
		hands:SetModel(target:GetHands():GetModel())
		hands:SetColor(target:GetPlayerColor():ToColor())
	else
		local mdl = hands:GetModel()
		hands:SetModel("")
		hands:SetModel(mdl)
	end
end)

hook.Add("PreDrawViewModels", "holylib_viewmodel_fix", function()
	local lply = LocalPlayer()
	local target = lply:GetObserverTarget()
	local in_eye = lply:GetObserverMode() == OBS_MODE_IN_EYE

	for _, ply in player.Iterator() do
		if ply == LocalPlayer() and not (target:IsValid() and not in_eye) then continue end

		local shouldHide = true
		if ply == target and in_eye then
			shouldHide = false
		end

		local vm = ply:GetViewModel()
		if IsValid(vm) then
			vm:SetNoDraw(shouldHide)
		end
	end
end)

-- i guess we doing legs now
hook.Add("ShouldDisableLegs", "prop_vehicle_choreo_generic", function()
	local veh = LocalPlayer():GetVehicle()
	if IsValid(veh) and veh:GetClass() == "prop_vehicle_choreo_generic" then
		return true
	end
end)
