local overrides = {}

do -- pointless hooks
	hook.Remove("PlayerTick", "TickWidgets")
	function widgets.PlayerTick() end

	if CLIENT then
		hook.Remove("RenderScreenspaceEffects", "RenderColorModify")
		hook.Remove("RenderScreenspaceEffects", "RenderBloom")
		hook.Remove("RenderScreenspaceEffects", "RenderToyTown")
		hook.Remove("RenderScreenspaceEffects", "RenderTexturize")
		hook.Remove("RenderScreenspaceEffects", "RenderSunbeams")
		hook.Remove("RenderScreenspaceEffects", "RenderSobel")
		hook.Remove("RenderScreenspaceEffects", "RenderSharpen")
		hook.Remove("RenderScreenspaceEffects", "RenderMaterialOverlay")
		hook.Remove("RenderScreenspaceEffects", "RenderMotionBlur")
		hook.Remove("RenderScene", "RenderStereoscopy")
		hook.Remove("RenderScene", "RenderSuperDoF")
		hook.Remove("GUIMousePressed", "SuperDOFMouseDown")
		hook.Remove("GUIMouseReleased", "SuperDOFMouseUp")
		hook.Remove("PreventScreenClicks", "SuperDOFPreventClicks")
		hook.Remove("PostRender", "RenderFrameBlend")
		hook.Remove("PreRender", "PreRenderFrameBlend")
		hook.Remove("Think", "DOFThink")
		hook.Remove("RenderScreenspaceEffects", "RenderBokeh")
		hook.Remove("NeedsDepthPass", "NeedsDepthPass_Bokeh")

		hook.Remove("PostDrawEffects", "RenderWidgets")
	end
end

do -- optimized animation stuff
	local math = math
	local math_Clamp = math.Clamp
	local math_min = math.min
	local math_max = math.max
	local math_NormalizeAngle = math.NormalizeAngle

	local VECTOR = FindMetaTable("Vector")
	local vec_Length = VECTOR.Length
	local vec_Dot = VECTOR.Dot
	local vec_Angle = VECTOR.Angle

	local SpeakFlexes = {
		["jaw_drop"] = true,
		["right_part"] = true,
		["left_part"] = true,
		["right_mouth_drop"] = true,
		["left_mouth_drop"] = true
	}

	local VEC_UP = Vector(0, 0, 1)

	overrides[#overrides + 1] = function()
		function GAMEMODE:UpdateAnimation(ply, vel, maxspeed)
			local plyTable = ply:GetTable()

			local len = vec_Length(vel)
			local movement = 1.0

			if len > 0.2 then
				movement = len / maxspeed
			end

			local rate = math_min(movement, 2)

			if ply:WaterLevel() >= 2 then
				rate = math_max(rate, 0.5)
			elseif not ply:IsOnGround() and len >= 1000 then
				rate = 0.1
			end

			ply:SetPlaybackRate(rate)

			if CLIENT then
				if ply:InVehicle() then
					local veh = ply:GetVehicle()
					local veh_vel = veh:GetVelocity()
					local fwd = veh:GetUp()
					local dp = vec_Dot(fwd, VEC_UP)

					ply:SetPoseParameter("vertical_velocity", (dp < 0 and dp or 0) + vec_Dot(fwd, veh_vel) * 0.005)

					local steer = veh:GetPoseParameter("vehicle_steer")
					steer = steer * 2 - 1
					if veh:GetClass() == "prop_vehicle_prisoner_pod" then
						steer = 0
						local yaw = math_NormalizeAngle(vec_Angle(ply:GetAimVector()).y - veh:GetAngles().y - 90)
						ply:SetPoseParameter("aim_yaw", yaw)
					end
					ply:SetPoseParameter("vehicle_steer", steer)
				end

				self:GrabEarAnimation(ply, plyTable)
				self:MouthMoveAnimation(ply, plyTable)
			end
		end

		function GAMEMODE:MouthMoveAnimation(ply, plyTable)
			if not plyTable then plyTable = ply:GetTable() end

			local num = ply:GetFlexNum() - 1
			if num <= 0 then return end

			if ply:IsSpeaking() then
				plyTable.m_bWasSpeaking = true

				local weight = math_Clamp(ply:VoiceVolume() * 2, 0, 2)
				for i = 0, num - 1 do
					local name = ply:GetFlexName(i)
					if SpeakFlexes[name] then
						ply:SetFlexWeight(i, weight)
					end
				end
			elseif plyTable.m_bWasSpeaking then
				plyTable.m_bWasSpeaking = false

				for i = 0, num - 1 do
					local name = ply:GetFlexName(i)
					if SpeakFlexes[name] then
						ply:SetFlexWeight(i, 0)
					end
				end
			end
		end
	end
end

local function do_overrides()
	for _, override in ipairs(overrides) do
		override()
	end
end

hook.Add("Initialize", "_optimizations_", do_overrides)
if GAMEMODE then do_overrides() end
