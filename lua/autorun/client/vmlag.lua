local gamemode = engine.ActiveGamemode()
if gamemode == "obsidianconflict" then return end

local enabled = CreateClientConVar("cl_vm_lag_enabled", "1", true, false, "Enable Half-Life 2 viewmodel sway/lag", 0,
	1)
local _maxLag = CreateClientConVar("cl_vm_lag_max", "1.5", true, false,
	"Ratio for the catch-up algorithm (also known as scale in other implementations)")
local _speed = CreateClientConVar("cl_vm_lag_speed", "5", true, false, "Viewmodel sway/lag speed")
local altAngles = CreateClientConVar("cl_vm_lag_alt_angles", "0", true, false,
	"Alternative angles that make the down angles move the viewmodel upwards", 0, 1)
local svft = CreateClientConVar("cl_vm_lag_sv_frametime", "0", true, false,
	"Use server frametime. Authentic but may look jittery", 0, 1)

local host_timescale = GetConVar("host_timescale")

local function VectorMA(start, scale, direction, dest)
	dest.x = start.x + scale * direction.x
	dest.y = start.y + scale * direction.y
	dest.z = start.z + scale * direction.z
end

hook.Add("CalcViewModelView", "vmlag", function(wep, vm, pos_orig, ang_orig, pos, ang)
	if not enabled:GetBool() then return pos, ang end

	local maxLag = _maxLag:GetFloat()

	local origPos = pos_orig * 1
	local origAng = ang_orig * 1

	local frametime = 0
	if svft:GetBool() then
		frametime = FrameTime()
	else
		frametime = RealFrameTime() * math.ceil(host_timescale:GetFloat()) * game.GetTimeScale()
	end
	local forward = ang:Forward()
	local vmTable = vm:GetTable()

	if vmTable.m_vecLastFacing == nil then
		vmTable.m_vecLastFacing = forward
	end
	local m_vecLastFacing = vmTable.m_vecLastFacing

	if frametime ~= 0 then
		local diff = forward - m_vecLastFacing

		local speed = _speed:GetFloat()

		local diffLen = diff:LengthSqr()
		if diffLen > maxLag * maxLag and maxLag > 0 then
			local scale = diffLen / maxLag
			speed = speed * scale
		end

		VectorMA(m_vecLastFacing, speed * frametime, diff, m_vecLastFacing)
		m_vecLastFacing:Normalize()
		VectorMA(pos, 5, diff * -1, pos)
		vmTable.m_vecLastFacing = m_vecLastFacing
	end

	local right = ang_orig:Right()
	local up = ang_orig:Up()

	local pitch = ang_orig.x
	if pitch > 180 then
		pitch = pitch - 360
	elseif pitch < -180 then
		pitch = pitch + 360
	end

	if maxLag == 0 then
		pos = origPos
		ang = origAng
	end

	if altAngles:GetBool() then
		VectorMA(pos, -pitch * 0.0035, forward, pos)
		VectorMA(pos, -pitch * -0.03, right, pos)
		VectorMA(pos, pitch * 0.04, up, pos)
	else
		VectorMA(pos, -pitch * 0.035, forward, pos)
		VectorMA(pos, -pitch * 0.03, right, pos)
		VectorMA(pos, -pitch * 0.02, up, pos)
	end

	return pos, ang
end)
