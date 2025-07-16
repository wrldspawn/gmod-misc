if DRC ~= nil then return end

DRC = {}

local GESTURE_TAG = "DRCNetworkGesture"

if SERVER then
	util.AddNetworkString(GESTURE_TAG)
end

-- so much for "legacy and likely removed in an update"
function CTFK(tab, value)
	for _, v in ipairs(tab) do
		if v == value then return true end
	end
	return false
end

function DRC:CallGesture(ply, slot, act, akill, fallback)
	if not SERVER then return end
	if not act then return end
	if not IsValid(ply) then return end
	if not slot or slot == "" then slot = GESTURE_SLOT_CUSTOM end
	if not akill or akill == "" then akill = true end

	if act == -1 then return end
	if ply:SelectWeightedSequence(act) == -1 then act = fallback end
	if fallback and ply:SelectWeightedSequence(act) == -1 then return end
	if act == nil or act == -1 then return end -- what if someone wanted to use ACT_RESET, that fails `if not act`

	if not ply:IsPlayer() then
		timer.Simple(engine.TickInterval(), function()
			if ply.RestartGesture then
				ply:RestartGesture(act, true, akill)
			end
		end)
	end

	net.Start(GESTURE_TAG)
	net.WriteEntity(ply)
	-- why does the original base use floats???
	net.WriteUInt(slot, 3)
	net.WriteUInt(act, 11)
	net.WriteBool(akill)
	net.SendPVS(ply:EyePos())
end

if CLIENT then
	net.Receive(GESTURE_TAG, function(len)
		local ply = net.ReadEntity()
		local slot = net.ReadUInt(3)
		local act = net.ReadUInt(11)
		local akill = net.ReadBool()

		DRC:PlayGesture(ply, slot, act, akill)
	end)

	function DRC:PlayGesture(ply, slot, act, akill)
		if IsValid(ply) and ply:IsPlayer() then
			timer.Simple(engine.TickInterval(), function()
				if IsValid(ply) then
					ply:AnimRestartGesture(slot, act, akill)
				end
			end)
		end
	end
end
