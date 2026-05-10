local function init()
	function GAMEMODE:GetTeamColor(ent)
		local team = TEAM_UNASSIGNED
		if not IsValid(ent) then
			return self:GetTeamNumColor(team)
		end

		if ent:IsPlayer() then
			if ent:IsBot() then
				team = ent:Team()
				return self:GetTeamNumColor(team)
			end

			return ent:GetPlayerColor():ToColor()
		else
			if ent.Team then
				team = ent:Team()
			end

			return self:GetTeamNumColor(team)
		end
	end
end

hook.Add("Initialize", "teamcolor_init", init)
if GAMEMODE then init() end
