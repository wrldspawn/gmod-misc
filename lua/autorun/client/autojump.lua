local gamemodes = {
	sandbox = true,
	obsidian_conflict = true,
}

if not gamemodes[engine.ActiveGamemode()] then return end

local enabled = CreateClientConVar("autojump", "0")
hook.Add("CreateMove", "autojump", function(cmd)
	local ply = LocalPlayer()

	if not enabled:GetBool() then return end
	if ply:GetMoveType() ~= MOVETYPE_WALK or ply:WaterLevel() > 1 then return end

	local ret = hook.Run("PreventAutojump")
	if ret == true then return end

	local buttons = cmd:GetButtons()
	if bit.band(buttons, IN_JUMP) ~= 0 and not ply:IsOnGround() then
		cmd:SetButtons(bit.band(buttons, bit.bnot(IN_JUMP)))
	end
end)

