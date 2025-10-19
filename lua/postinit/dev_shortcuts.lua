_G.hook = setmetatable(_G.hook, {
	__call = function(hook_name, name, func, priority)
		if func ~= nil then
			return hook.Add(hook_name, name, func, priority)
		else
			return hook.Remove(hook_name, name)
		end
	end,
})

do -- better tostrings
	local PLAYER = FindMetaTable("Player")
	function PLAYER:__tostring()
		if not self:IsValid() then
			return "Player [Invalid]"
		end

		return Format(
			"Player [%d]{Name=%q, SteamID=%q, Model=%q}",
			self:EntIndex(), self:Name(), self:SteamID(), self:GetModel()
		)
	end

	local ENTITY = FindMetaTable("Entity")
	function ENTITY:__tostring()
		if not self:IsValid() then
			return "Entity [Invalid]"
		end

		local prefix = "Entity"
		if self:IsWeapon() then
			prefix = "Weapon"
		elseif self:IsVehicle() then
			prefix = "Vehicle"
		end

		local str = Format("%s [%d]{Class=%q", prefix, self:EntIndex(), self:GetClass())

		local name = self:GetName()
		if name and name ~= "" then
			str = str .. Format(", Name=%q", name)
		end

		local model = self:GetModel()
		if model and model ~= "" then
			str = str .. Format(", Model=%q", model)
		end

		local owner = self:GetOwner()
		if IsValid(owner) and owner ~= self then
			str = str .. Format(", Owner=%s", tostring(owner))
		end

		str = str .. "}"

		return str
	end

	local WEAPON = FindMetaTable("Weapon")
	WEAPON.__tostring = ENTITY.__tostring

	local VEHICLE = FindMetaTable("Vehicle")
	VEHICLE.__tostring = ENTITY.__tostring

	local VECTOR = FindMetaTable("Vector")
	function VECTOR:__tostring()
		return Format("Vector(%0.6f, %0.6f, %0.6f)", self:Unpack())
	end

	local ANGLE = FindMetaTable("Angle")
	function ANGLE:__tostring()
		return Format("Angle(%0.3f, %0.3f, %0.3f)", self:Unpack())
	end

	local COLOR = FindMetaTable("Color")
	function COLOR:__tostring()
		return Format("Color(%d, %d, %d, %d)", self:Unpack())
	end

	local dummy_func = function() end
	local FUNCTION = debug.getmetatable(dummy_func) or {}
	function FUNCTION:__tostring()
		local info = debug.getinfo(self, "Su")
		if info.what == "C" then
			return "function(...) [Native]"
		end

		local argStr = ""
		if info.isvararg then
			argStr = "..."
		else
			local args = {}

			local arg = 2
			local last_arg = debug.getlocal(self, 1)
			while last_arg ~= nil do
				args[#args + 1] = last_arg
				last_arg = debug.getlocal(self, arg)
				arg = arg + 1
			end

			argStr = table.concat(args, ", ")
		end

		return Format("function(%s) [%s: %d-%d]", argStr, info.short_src, info.linedefined, info.lastlinedefined)
	end

	debug.setmetatable(dummy_func, FUNCTION)
end
