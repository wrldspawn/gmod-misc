local TAG = "spray_preview"

local decalfrequency = GetConVar("decalfrequency")

local function GetSprayTrace(ply)
	local pos = ply:EyePos()
	local forward = ply:GetAimVector()

	return util.TraceLine({
		start = pos,
		endpos = pos + forward * 128,
		mask = MASK_SOLID_BRUSHONLY,
		filter = { ply },
		collisiongroup = COLLISION_GROUP_NONE,
	})
end

local holding = false

hook.Add("PlayerBindPress", TAG, function(ply, bind, pressed, code)
	if pressed and bind ~= nil then
		if bind:find("impulse 201") then
			local trace = GetSprayTrace(ply)
			if trace.StartPos:Distance(trace.HitPos) <= 128 then
				holding = true
				return true
			end
		elseif bind == "+attack" and holding then
			holding = false
			return true
		end
	end
end)

local spraying = false
local nextSpray = 0
hook.Add("CreateMove", TAG, function(cmd)
	local key = input.LookupBinding("impulse 201")
	if not key then return end
	local keyCode = input.GetKeyCode(key)

	if holding and input.WasKeyReleased(keyCode) then
		spraying = true
		holding = false
	elseif spraying then
		cmd:SetImpulse(201)
		if CurTime() > nextSpray then
			nextSpray = CurTime() + decalfrequency:GetFloat()
		end
		timer.Simple(0, function()
			spraying = false
		end)
	end
end)

local spray = GetConVar("cl_logofile"):GetString():gsub("%.vtf$", ""):gsub("^materials/", "")
local spray_mat = Material(spray)

hook.Add("HUDPaint", TAG, function()
	if not holding then return end

	surface.SetFont("CloseCaption_Normal")

	local _, h = surface.GetTextSize("W")
	local y = ScrH() / 2 + h * 6

	local trace = GetSprayTrace(LocalPlayer())
	local str = ""
	local r, g, b = 0, 255, 0
	if not trace.Hit then
		str = "Too far from a surface"
		r = 255
		g = 0

		surface.SetMaterial(spray_mat)
		surface.SetDrawColor(255, 255, 255)
		surface.DrawTexturedRect(ScrW() / 2 - 128, ScrH() / 2 - 128, 256, 256)
	elseif LocalPlayer():GetNW2Float("spray_preview_next", nextSpray) > CurTime() then
		str = "Spray on cooldown"
		r = 255
		g = 0
	else
		local sprayKeyName = input.LookupBinding("impulse 201")
		str = "Release " .. sprayKeyName:upper() .. " to spray"
	end
	local w = surface.GetTextSize(str)
	local x = ScrW() / 2 - w / 2

	surface.SetTextPos(x, y)
	surface.SetTextColor(r, g, b)
	surface.DrawText(str, true)

	y = y + h + 4

	surface.SetFont("HudSelectionText")

	local keyName = input.LookupBinding("+attack", true)
	local bound = false

	if not keyName then
		keyName = "<+attack not bound>"
	else
		keyName = "[" .. keyName:upper() .. "]"
		bound = true
	end

	local keyText = keyName
	local helpText = " to cancel"

	local tw = surface.GetTextSize(keyText .. helpText)

	x = ScrW() / 2 - tw / 2

	r, g, b = 255, 255, 255
	if not bound then
		g = 192
		b = 192
	end
	surface.SetTextPos(x, y)
	surface.SetTextColor(r, g, b)
	local kw = surface.GetTextSize(keyText)
	surface.DrawText(keyText)

	surface.SetTextPos(x + kw, y)
	surface.SetTextColor(192, 192, 192)
	surface.DrawText(helpText)
end)

local SPRAY_CAN_OFFSET = Vector(0, 0, 4)
local NO_HDR = Vector(0.8, 0, 0)
hook.Add("PostDrawTranslucentRenderables", TAG, function()
	if not holding then return end

	local trace = GetSprayTrace(LocalPlayer())
	local pos = trace.HitPos
	local norm = trace.HitNormal

	if not trace.Hit then return end

	local up = Vector(0, 0, 1)
	if norm.z == 1 then
		up.y = 1
		up.z = 0
	elseif norm.z == -1 then
		up.y = -1
		up.z = 0
	end
	if norm.z == 0 then
		pos = pos + SPRAY_CAN_OFFSET
	end

	local ang = norm:AngleEx(up)
	ang:RotateAroundAxis(ang:Up(), 90)
	ang:RotateAroundAxis(ang:Forward(), 90)

	cam.Start3D2D(pos + ang:Up() * 0.1, ang, 1)
	local tone = render.GetToneMappingScaleLinear()
	render.SetToneMappingScaleLinear(NO_HDR)
	surface.SetAlphaMultiplier(0.5)

	surface.SetMaterial(spray_mat)
	surface.SetDrawColor(255, 255, 255)
	surface.DrawTexturedRect(-32, -32, 64, 64)

	surface.SetAlphaMultiplier(1)
	render.SetToneMappingScaleLinear(tone)
	cam.End3D2D()
end)
