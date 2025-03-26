if CLIENT then
	CreateClientConVar("gmod_tool_playerclip", "0", true, true, "Allow toolgun traces to hit clip brushes")
end
local function modify()
	local SWEP = weapons.GetStored("gmod_tool")

	local toolmask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_MONSTER, CONTENTS_WINDOW, CONTENTS_DEBRIS,
		CONTENTS_GRATE, CONTENTS_AUX)
	function SWEP:_Shoot(right)
		local owner = self:GetOwner()

		local tr = util.GetPlayerTrace(owner)
		tr.mask = toolmask
		if owner:GetInfoNum("gmod_tool_playerclip", "0") == 1 then
			tr.mask = bit.bor(tr.mask, CONTENTS_PLAYERCLIP)
		end
		tr.mins = vector_origin
		tr.maxs = vector_origin

		local trace = util.TraceLine(tr)
		if not trace.Hit then trace = util.TraceHull(tr) end
		if not trace.Hit then return end

		local tool = self:GetToolObject()
		if not tool then return end

		tool:CheckObjects()

		if not tool:Allowed() then return end

		local mode = self:GetMode()
		if not gamemode.Call("CanTool", owner, trace, mode, tool, right and 2 or 1) then return end

		local click = right and tool.RightClick or tool.LeftClick
		if not click(tool, trace) then return end

		self:DoShootEffect(trace.HitPos, trace.HitNormal, trace.Entity, trace.PhysicsBone, IsFirstTimePredicted())
	end

	function SWEP:PrimaryAttack()
		self:_Shoot(false)
	end

	function SWEP:SecondaryAttack()
		self:_Shoot(true)
	end
end

hook.Add("Initialize", "gmod_tool_playerclip", modify)
if GAMEMODE then modify() end
