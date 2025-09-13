-- based on https://github.com/wootguy/AntiBlock
local TAG = "svenstuck"
local SWAP_COOLDOWN = 1
local SWAP_MAX_DISTANCE = 128

local function isSwappable(ent)
	if not ent:IsValid() or not ent:Alive() then return false end
	local mt = ent:GetMoveType()
	if mt ~= MOVETYPE_WALK and mt ~= MOVETYPE_STEP and mt ~= MOVETYPE_NONE then
		return false
	end
	return ent:IsPlayer() or ent:IsNPC()
end

local function canSwap(ent1, ent2)
	ent1._lastSwap = ent1._lastSwap or 0
	ent2._lastSwap = ent2._lastSwap or 0
	return CurTime() - math.max(ent1._lastSwap, ent2._lastSwap) >= SWAP_COOLDOWN
end

local function isPositionSafe(pos, ignore)
	local tr = util.TraceHull({
		start = pos,
		endpos = pos,
		mins = Vector(-16, -16, 0),
		maxs = Vector(16, 16, 72),
		filter = ignore
	})
	return not tr.Hit
end

local function swapEntities(ent1, ent2)
	if not isSwappable(ent1) or not isSwappable(ent2) then return false end
	if not canSwap(ent1, ent2) then return false end

	local pos1, pos2 = ent1:GetPos(), ent2:GetPos()
	if pos1:Distance(pos2) > SWAP_MAX_DISTANCE then return false end
	if not isPositionSafe(pos2, { ent1, ent2 }) or not isPositionSafe(pos1, { ent1, ent2 }) then return false end

	ent1:SetPos(pos2)
	ent2:SetPos(pos1)

	if ent1:IsPlayer() then ent1:AddFlags(FL_DUCKING) end
	if ent2:IsPlayer() then ent2:AddFlags(FL_DUCKING) end
	timer.Simple(engine.TickInterval() * 2, function()
		if ent1:IsValid() and ent1:IsPlayer() then ent1:RemoveFlags(FL_DUCKING) end
		if ent2:IsValid() and ent2:IsPlayer() then ent2:RemoveFlags(FL_DUCKING) end
	end)

	ent1._lastSwap = CurTime()
	ent2._lastSwap = CurTime()

	return true
end

hook.Add("KeyPress", TAG, function(ply, key)
	if not ply:IsValid() then return end
	local tr = ply:GetEyeTraceNoCursor()
	local ent = tr.Entity
	if not ent:IsValid() then return end

	if ent:IsPlayer() and key == IN_USE then
		swapEntities(ply, ent)
	elseif ent:IsNPC() and ent:Disposition(ply) == D_LI and key == IN_RELOAD then
		swapEntities(ply, ent)
	end
end)
