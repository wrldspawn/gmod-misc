local binds = {
	["+use"] = true,
	["+attack"] = true,
	["+attack2"] = true,
}

hook.Add("PlayerBindPress", "hands_use_fix", function(ply, bind, pressed, code)
	if binds[bind] and pressed then
		local hands = ply:GetHands()
		local mdl = hands:GetModel()
		timer.Simple(0.05, function()
			hands:SetModel("")
			hands:SetModel(mdl)
		end)
	end
end)
