hook.Add("Initialize", "ReplacePhyscannon", function()
	local copy = weapons.Get("weapon_physcannon2")
	if copy then
		weapons.Register(copy, "weapon_physcannon")
		weapons.Register({}, "weapon_physcannon2")
	end
end)
