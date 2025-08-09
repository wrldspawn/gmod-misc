local function vm_fix()
	function GAMEMODE:CalcViewModelView(wep, vm, oldPos, oldAng, vm_origin, vm_angles)
		local ply = wep:GetOwner()
		if IsValid(ply) and IsValid(ply:GetVehicle()) then
			local vehicle = ply:GetVehicle()
			if self:VehicleIsPassengerSeat(vehicle) == true then
				local ang = oldAng
				local eyeAng = ply:GetAimVector():Angle()
				ang:Set(eyeAng + ply:GetViewPunchAngles())
				local _, localang = WorldToLocal(Vector(0, 0, 0), ang, Vector(0, 0, 0), vehicle:GetAngles())
				ang:RotateAroundAxis(ang:Forward() * -1, localang.r)
				oldAng = ang
			end
		end

		if not IsValid(wep) then return end
		-- Controls the position of all viewmodels
		local func = wep.GetViewModelPosition
		if func ~= nil and isfunction(func) then
			local pos, ang = func(wep, vm_origin, vm_angles)
			vm_origin = pos or vm_origin
			vm_angles = ang or vm_angles
		end

		-- Controls the position of individual viewmodels
		func = wep.CalcViewModelView
		if func ~= nil and isfunction(func) then
			local pos, ang = func(wep, vm, oldPos * 1, oldAng * 1, vm_origin * 1, vm_angles * 1)
			vm_origin = pos or vm_origin
			vm_angles = ang or vm_angles
		end

		if wep:IsScripted() then return vm_origin, vm_angles end -- Skip applying view bob/lag for scripted weapon.
		local newPos = oldPos
		local newAng = oldAng
		newPos, newAng = self:CalcViewModelBob(wep, vm, newPos, newAng, vm_origin, vm_angles)
		newPos, newAng = self:CalcViewModelLag(wep, vm, newPos, newAng, vm_origin, vm_angles)

		return newPos, newAng
	end
end

hook.Add("PostGamemodeLoaded", "vm_fix", vm_fix)
if GAMEMODE then vm_fix() end
