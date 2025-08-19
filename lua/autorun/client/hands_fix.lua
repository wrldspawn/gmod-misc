local binds = {
	["+use"] = true,
	["+attack"] = true,
	["+attack2"] = true,
}

hook.Add("PlayerBindPress", "hands_use_fix", function(ply, bind, pressed, code)
	if binds[bind] and pressed then
		local hands = ply:GetHands()
		if not IsValid(hands) then return end
		local mdl = hands:GetModel()
		timer.Simple(0.05, function()
			if not IsValid(hands) then return end
			hands:SetModel("")
			hands:SetModel(mdl)
		end)
	end
end)

hook.Add("PreDrawPlayerHands", "hands_shadow_fix", function(hands, vm, ply, wep)
	hands:DestroyShadow()
end)
