local TAG = "picker3"

local ipairs = ipairs
local isstring = isstring
local unpack = unpack
local Color = Color
local EyePos = EyePos
local EyeAngles = EyeAngles
local Format = Format
local IsValid = IsValid
local LocalPlayer = LocalPlayer
local LocalToWorld = LocalToWorld
local ScrH = ScrH
local ScrW = ScrW
local Vector = Vector
local TEXFILTER_POINT = TEXFILTER.POINT

local cam_Start3D2D = cam.Start3D2D
local cam_End3D2D = cam.End3D2D
local render_SuppressEngineLighting = render.SuppressEngineLighting
local render_PushFilterMag = render.PushFilterMag
local render_PushFilterMin = render.PushFilterMin
local render_PopFilterMag = render.PopFilterMag
local render_PopFilterMin = render.PopFilterMin
local string_Explode = string.Explode
local surface_GetTextSize = surface.GetTextSize
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawLine = surface.DrawLine
local surface_SetFont = surface.SetFont
local surface_SetTextColor = surface.SetTextColor
local surface_SetTextPos = surface.SetTextPos
local surface_DrawText = surface.DrawText
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local table_sort = table.sort
local util_IntersectRayWithOBB = util.IntersectRayWithOBB

local COLOR = FindMetaTable("Color")
local Color_Unpack = COLOR.Unpack

local ANGLE = FindMetaTable("Angle")
local Angle_Forward = ANGLE.Forward
local Angle_Right = ANGLE.Right
local Angle_RotateAroundAxis = ANGLE.RotateAroundAxis
local Angle_Unpack = ANGLE.Unpack

local VECTOR = FindMetaTable("Vector")
local Vector_Distance = VECTOR.Distance
local Vector_ToScreen = VECTOR.ToScreen
local Vector_Unpack = VECTOR.Unpack

local ENTITIES = setmetatable({}, { __mode = "k" })
local MAP_ENTS = {}

hook.Add("EntityRemoved", TAG, function(ent)
	ENTITIES[ent] = nil
end)

local BOUNDS = 8

local function CreateIcon(class, path)
	return CreateMaterial("picker3_icon-" .. class, "UnlitGeneric", {
		["$basetexture"] = path,
		["$vertexalpha"] = 1,
	})
end

local ICON_DEFAULT = Material("icon16/help.png")
local ICON_SPAWNPOINT = Material("icon16/user_add.png")
local ICON_FILTER = Material("icon16/tag_blue.png")
local ICON_NODE = Material("icon16/map_go.png")

local ICON_CLOUDS = Material("icon16/weather_clouds.png")
local ICON_COMMAND = Material("icon16/application_xp_terminal.png")
local ICON_COMMENT = Material("icon16/comment.png")
local ICON_SOUND = Material("icon16/sound.png")
local ICON_TARGET = CreateIcon("info_target", "editor/info_target")
local ICON_WATER = Material("icon16/water.png")
local ICON_WEAPON = Material("icon16/gun.png")
local ICON_VECTOR = Material("icon16/vector.png")

local ENT_ICONS = {
	ambient_generic = ICON_SOUND,
	env_beam = ICON_VECTOR,
	env_entity_maker = Material("icon16/brick_add.png"),
	env_fog_controller = ICON_CLOUDS,
	env_smokestack = Material("icon16/fire.png"),
	env_soundscape_proxy = ICON_SOUND,
	env_soundscape_triggerable = ICON_SOUND,
	env_splash = ICON_WATER,
	env_steam = ICON_CLOUDS,
	game_countdown_timer = Material("icon16/hourglass.png"),
	game_score = Material("icon16/table_add.png"),
	info_ladder_dismount = ICON_TARGET,
	info_target = ICON_TARGET,
	info_waypoint = Material("icon16/exclamation.png"),
	infodecal = Material("icon16/image.png"),
	keyframe_rope = ICON_VECTOR,
	light_spot = Material("icon16/lightbulb.png"),
	logic_merchant_relay = Material("icon16/cart.png"),
	move_rope = ICON_VECTOR,
	npc_bullseye = ICON_TARGET,
	path_track = Material("icon16/chart_line.png"),
	phys_constraint = Material("icon16/link.png"),
	phys_constraintsystem = Material("icon16/link.png"),
	phys_lengthconstraint = Material("icon16/link.png"),
	phys_keepupright = Material("icon16/arrow_up.png"),
	player_speedmod = Material("icon16/lightning.png"),
	point_camera = Material("icon16/camera.png"),
	point_clientcommand = ICON_COMMAND,
	point_message = ICON_COMMENT,
	point_message_multiplayer = ICON_COMMENT,
	point_servercommand = ICON_COMMAND,
	scripted_sequence = Material("icon16/script_go.png"),
	water_lod_control = ICON_WATER,
}

local SPAWNPOINT_CLASSES = {
	"info_player_start",
	"info_player_deathmatch",
	"info_player_rebel",
	"info_coop_spawn",
	"info_player_counterterrorist",
	"info_player_terrorist",
	"info_player_axis",
	"info_player_allies",
	"gmod_player_start",
	"info_player_teamspawn",
	"ins_spawnpoint",
	"aoc_spawnpoint",
	"dys_spawn_point",
	"info_player_pirate",
	"info_player_viking",
	"info_player_knight",
	"diprip_start_team_blue",
	"diprip_start_team_red",
	"info_player_red",
	"info_player_blue",
	"info_player_coop",
	"info_player_human",
	"info_player_zombie",
	"info_player_zombiemaster",
	"info_player_fof",
	"info_player_desperado",
	"info_player_vigilante",
	"info_survivor_rescue",
	"info_survivor_position",
	"info_player_attacker",
	"info_player_defender",
	"info_ff_teamspawn",
}
for _, class in ipairs(SPAWNPOINT_CLASSES) do
	ENT_ICONS[class] = ICON_SPAWNPOINT
end

local FILTER_CLASSES = {
	"filter_activator_attribute_int",
	"filter_activator_class",
	"filter_activator_context",
	"filter_activator_flag",
	"filter_activator_infected_class",
	"filter_activator_mass_greater",
	"filter_activator_model",
	"filter_activator_name",
	"filter_activator_team",
	"filter_activator_tfteam",
	"filter_base",
	"filter_combineball_type",
	"filter_damage_class",
	"filter_damage_type",
	"filter_enemy",
	"filter_health",
	"filter_melee_damage",
	"filter_multi",
	"filter_player_held",
	"filter_tf_bot_has_tag",
	"filter_tf_class",
	"filter_tf_condition",
	"filter_tf_damaged_by_weapon_in_slot",
	"filter_tf_player_can_cap",
	"ttt_filter_role",
}
for _, class in ipairs(FILTER_CLASSES) do
	ENT_ICONS[class] = ICON_FILTER
end

local NODE_CLASSES = {
	"info_node",
	"info_node_air",
	"info_node_air_hint",
	"info_node_climb",
	"info_node_hint",
	"info_node_link",
	"info_node_link_controller",
	"info_radial_link_controller",
	"path_corner",
}
for _, class in ipairs(NODE_CLASSES) do
	ENT_ICONS[class] = ICON_NODE
end

local function getupvalues(f)
	local i, t = 0, {}

	while true do
		i = i + 1
		local key, val = debug.getupvalue(f, i)
		if not key then break end
		t[key] = val
	end

	return t
end

local MAP

-- handled by showtriggers
local IGNORE = {
	point_hurt = true,
	point_teleport = true,
	point_vehiclespawn = true,
	point_trigger = true,
	point_weapon_eater = true,
	point_push = true,
}

local function GetMapEnts()
	if NikNaks then
		local parseEntityData = getupvalues(NikNaks.__metatables.BSP.GetEntities).parseEntityData
		local ParseEntity = getupvalues(parseEntityData).ParseEntity
		local _tableTypes = getupvalues(ParseEntity)._tableTypes
		_tableTypes.OnHitMax = true
		NikNaks.CurrentMap._entities = nil

		MAP = NikNaks.CurrentMap

		local bmodels = MAP:GetBModels()

		for idx, ent in ipairs(MAP:GetEntities()) do
			local class = ent.classname
			if class:find("^trigger_") or IGNORE[class] then continue end

			local info = {
				creationid = idx + 1235, -- see MapCreationID wiki note for this magic number
				class = class,
				name = ent.targetname,
				filter = ent.filtername or ent.filterclass or ent.filterteam,
				origin = ent.origin,
				angle = ent.angles,
				model = ent.model,
				texture = ent.texture or ent.image,
				color = ent.color or ent._light,
				text = ent.text or ent.message,
				target = ent.target or ent.landmark or ent.attach1 or ent.entitytemplate,
				disabled = tobool(ent.startdisabled ~= nil and ent.startdisabled or ent.StartDisabled),
				outputs = {},
			}

			if ent.model then
				if ent.model:find("^%*") then
					local bmodel = bmodels[tonumber(ent.model:sub(2))]
					if bmodel then
						info.mins = bmodel.mins
						info.maxs = bmodel.maxs
					end
				elseif ent.model:find("%.mdl$") then
					local mdlinfo = util.GetModelInfo(ent.model)
					if mdlinfo and mdlinfo.HullMin and mdlinfo.HullMax then
						info.mins = mdlinfo.HullMin
						info.maxs = mdlinfo.HullMax
					end
				end
			else
				if not ENT_ICONS[class] then
					local path = "editor/" .. class
					if file.Exists("materials/" .. path .. ".vmt", "GAME") then
						ENT_ICONS[class] = CreateIcon(class, path)
					elseif class:find("^weapon_") then
						ENT_ICONS[class] = ICON_WEAPON
					end
				end
			end

			if not info.mins and not info.maxs then
				info.mins = Vector(-BOUNDS, -BOUNDS, -BOUNDS)
				info.maxs = Vector(BOUNDS, BOUNDS, BOUNDS)
				info.bounds_fallback = true
			end

			if info.target then
				info.target_invalid = MAP:FindByName(info.target)[1] == nil
				if info.target_invalid then
					info.target_invalid = MAP:FindByClass(info.target)[1] == nil
				end
				if info.target == "player" then
					info.target_invalid = false
				end
			end

			for k, v in next, ent do
				if not string.match(k, "^On") then continue end
				info.outputs[k] = v
			end

			table.insert(MAP_ENTS, info)
		end
	end
end

local function CollectEntity(ent)
	if not IsValid(ent) then return end
	if NikNaks and ent:CreatedByMap() then
		local model = ent:GetModel()
		for _, info in ipairs(MAP_ENTS) do
			if info.creationid == ent:MapCreationID() or (model and model:find("^%*") and model == info.model) then
				info.entity = ent
				break
			end
		end
		return
	end
	ENTITIES[ent] = true
end

local PICKER_ENABLED = false
concommand.Add(TAG, function()
	if table.Count(ENTITIES) == 0 then
		LocalPlayer():ChatPrint("Collecting entities, please wait...")
		GetMapEnts()
		for _, ent in ents.Iterator() do
			CollectEntity(ent)
		end

		hook.Add("OnEntityCreated", TAG, function(ent)
			CollectEntity(ent)
		end)
	end

	PICKER_ENABLED = not PICKER_ENABLED
	LocalPlayer():ChatPrint("Picker " .. (PICKER_ENABLED and "en" or "dis") .. "abled.")
end)

local function keep_inside_circle(x, y, r)
	local A = {
		x = ScrW() / 2,
		y = ScrH() / 2
	}
	local B = {
		x = x,
		y = y
	}
	local C = {}

	C.x = A.x + (r / 2 * ((B.x - A.x) / math.sqrt(math.pow(B.x - A.x, 2) + math.pow(B.y - A.y, 2))))
	C.y = A.y + (r / 2 * ((B.y - A.y) / math.sqrt(math.pow(B.x - A.x, 2) + math.pow(B.y - A.y, 2))))

	return C
end

local function is_outside_circle(x, y, r)
	return x ^ 2 + y ^ 2 > (r / 2) ^ 2
end

local function addLine(lines, text, prefix, pColor, color)
	if lines.longest == nil then lines.longest = 0 end
	if not text then return end

	local str = prefix .. text
	local tw = surface_GetTextSize(str)
	if tw > lines.longest then
		lines.longest = tw
	end

	lines[#lines + 1] = {
		text = text,
		prefix = prefix,
		pColor = pColor,
		color = color,
	}
end

local COLOR_TEXT = Color(255, 255, 255)
local COLOR_NAME = Color(0, 192, 0)
local COLOR_OUTPUT = Color(0, 192, 255)
local COLOR_TARGET = Color(255, 128, 0)
local COLOR_INVALID = Color(255, 0, 0)
local COLOR_FILTER = Color(231, 16, 148)
local COLOR_FIELD = Color(192, 192, 192) -- temp color?

local ANGLE_ZERO = Angle()
local VEC_ZERO = Vector()
local VEC_FORWARD = Vector(BOUNDS, 0, 0)
local VEC_LEFT = Vector(0, BOUNDS, 0)
local VEC_UP = Vector(0, 0, BOUNDS)

local FORMAT_3 = "%.2f, %.2f, %.2f"

local filter_cache = {}
local decal_cache = {}

local function sortdist(a, b)
	return a.distance < b.distance
end

local lply = LocalPlayer()

local SCROLL_ENABLED = false
local SCROLL_ENABLED_LAST = false
local SCROLL_OFFSET = 0

hook.Add("PlayerBindPress", TAG, function(ply, bind, pressed, code)
	if SCROLL_ENABLED and pressed and (code == MOUSE_WHEEL_UP or code == MOUSE_WHEEL_DOWN) then
		surface_SetFont("BudgetLabel")
		local _, th = surface_GetTextSize("W")


		if code == MOUSE_WHEEL_UP then
			SCROLL_OFFSET = SCROLL_OFFSET - th
			if SCROLL_OFFSET < 0 then SCROLL_OFFSET = 0 end
		else
			SCROLL_OFFSET = SCROLL_OFFSET + th
		end

		return true
	end
end)

local function render_data(data, stacking, mindist, nexty)
	surface_SetFont("BudgetLabel")
	local _, th = surface_GetTextSize("W")

	local x, y, w, h, cx, cy = data.x, data.y, data.w, data.h, data.cx, data.cy

	if stacking and nexty > y then y = nexty end

	local offset = stacking and SCROLL_OFFSET or 0

	local contain = true
	if stacking then
		contain = not SCROLL_ENABLED
	end
	if contain and is_outside_circle((ScrW() / 2) - x, (ScrH() / 2) - y, ScrH() - (64 + 48 + 8)) then
		local newpos = keep_inside_circle(x, y, ScrH() - (64 + 48 + 8))
		x = newpos.x
		y = newpos.y
	end

	surface_SetDrawColor(255, 255, 255, 96)
	surface_DrawLine(cx, cy, x + w, (y - offset) + h)

	for _, line in ipairs(data.lines) do
		surface_SetTextColor(Color_Unpack(line.pColor))
		surface_SetTextPos(x, y - offset)
		surface_DrawText(line.prefix)
		surface_SetTextColor(Color_Unpack(line.color))
		surface_DrawText(line.text)
		y = y + th
	end

	if stacking then
		local _x, _y = x - cx, y - cy
		local dist = _x * _x + _y * _y * th

		if dist < mindist then
			mindist = dist
		end
		nexty = y + (th / 2)
		return mindist, nexty
	end
end

hook.Add("HUDPaint", TAG, function()
	if PICKER_ENABLED then
		SCROLL_ENABLED_LAST = SCROLL_ENABLED
		SCROLL_ENABLED = input.IsKeyDown(KEY_LALT)
		if SCROLL_ENABLED_LAST and not SCROLL_ENABLED then
			SCROLL_OFFSET = 0
		end

		local to_process = {}
		local processed = {}
		local to_render = {}
		local to_stack = {}
		local axes = {}

		if not IsValid(lply) then
			lply = LocalPlayer()
		end

		local eyepos = EyePos()
		local eyeang = EyeAngles()
		local forward = Angle_Forward(eyeang) * 32768

		for _, ent in ipairs(MAP_ENTS) do
			local entity = ent.entity
			local isvalid = IsValid(entity)
			local pos = isvalid and entity:GetPos() or ent.origin
			local ang = isvalid and entity:GetAngles() or (ent.angle or ANGLE_ZERO)

			local dist = Vector_Distance(eyepos, pos)
			if dist > 32768 then continue end
			ent.distance = dist

			if isvalid then
				if entity:IsWeapon() and entity:GetOwner() == lply then continue end
			end

			local hitpos = util_IntersectRayWithOBB(eyepos, forward, pos, ang, ent.mins, ent.maxs)

			local scrpos = Vector_ToScreen(pos)
			if hitpos == nil and not scrpos.visible then continue end

			local axis = {
				pos = pos,
				ang = ang,
				hit = false,
			}

			if hitpos ~= nil then
				to_process[#to_process + 1] = ent
				axis.hit = true
			end

			axes[#axes + 1] = axis
		end

		for ent in next, ENTITIES do
			if not IsValid(ent) then continue end

			local pos = ent:GetPos()
			local myPos = lply:GetPos()
			local dist = Vector_Distance(pos, eyepos)

			if dist > 32768 then continue end

			if (
						ent == lply or
						ent:GetParent() == lply or
						(ent:IsWeapon() and ent:GetOwner() == lply) or
						ent == lply:GetViewModel() or
						pos == myPos or
						dist < 16 or
						ent == lply:GetVehicle() or
						ent == lply:GetHands()
					) and not lply:ShouldDrawLocalPlayer() then
				continue
			end

			local ang = ent:GetAngles()

			local bounds_fallback
			local mins, maxs = ent:GetCollisionBounds()
			if mins == VEC_ZERO and maxs == VEC_ZERO then
				mins = Vector(-BOUNDS, -BOUNDS, -BOUNDS)
				maxs = Vector(BOUNDS, BOUNDS, BOUNDS)
				bounds_fallback = true
			end

			local hitpos = util_IntersectRayWithOBB(eyepos, forward, pos, ang, mins, maxs)

			local scrpos = Vector_ToScreen(pos)
			if hitpos == nil and not scrpos.visible then continue end

			local axis = {
				pos = pos,
				ang = ang,
				hit = false,
			}

			if hitpos ~= nil then
				local info = {
					entity = ent,
					class = ent:GetClass(),
					origin = pos,
					angle = ang,
					mins = mins,
					maxs = maxs,
					model = ent:GetModel(),
					distance = Vector_Distance(eyepos, pos),
					outputs = {},
					bounds_fallback = bounds_fallback,
				}

				to_process[#to_process + 1] = info
				axis.hit = true
			end

			axes[#axes + 1] = axis
		end

		for _, axis in ipairs(axes) do
			local pos = axis.pos
			local ang = axis.ang

			local spos = Vector_ToScreen(pos)
			if not spos.visible then continue end

			local alpha = axis.hit and 255 or 72
			if #to_process == 0 then
				alpha = 255
			end

			local pos_forward = LocalToWorld(VEC_FORWARD, ANGLE_ZERO, pos, ang)
			local pos_left = LocalToWorld(VEC_LEFT, ANGLE_ZERO, pos, ang)
			local pos_up = LocalToWorld(VEC_UP, ANGLE_ZERO, pos, ang)

			local spos_f = Vector_ToScreen(pos_forward)
			local spos_l = Vector_ToScreen(pos_left)
			local spos_u = Vector_ToScreen(pos_up)

			surface_SetDrawColor(255, 0, 0, alpha)
			surface_DrawLine(spos.x, spos.y, spos_f.x, spos_f.y)
			surface_SetDrawColor(0, 255, 0, alpha)
			surface_DrawLine(spos.x, spos.y, spos_l.x, spos_l.y)
			surface_SetDrawColor(0, 0, 255, alpha)
			surface_DrawLine(spos.x, spos.y, spos_u.x, spos_u.y)
		end

		table_sort(to_process, sortdist)

		surface_SetFont("BudgetLabel")
		local _, th = surface_GetTextSize("W")

		for _, ent in ipairs(to_process) do
			local entity = ent.entity
			local isvalid = IsValid(entity)
			local pos = isvalid and entity:GetPos() or ent.origin
			local ang = isvalid and entity:GetAngles() or (ent.angle or ANGLE_ZERO)

			local center = pos:ToScreen()

			local lines = {}
			addLine(lines, isvalid and " (_" .. entity:EntIndex() .. ")" or "", ent.class, COLOR_TEXT, COLOR_FIELD)
			if ent.disabled then
				addLine(lines, "Starts Disabled", "", COLOR_INVALID, COLOR_INVALID)
			end

			addLine(lines, ent.name, "Name: ", COLOR_NAME, COLOR_TEXT)

			local is_filter = ent.class:find("^filter_")
			if ent.filter and MAP and not is_filter then
				local filter = filter_cache[ent.filter]
				if filter == nil then
					local filterent = MAP:FindByName(ent.filter)[1]
					if filterent then
						filter = ent.filter
						local filterclass = filterent.classname
						if filterclass == "filter_activator_class" then
							filter = "By class: " .. filterent.filterclass
						elseif filterclass == "filter_activator_name" then
							filter = "By name: " .. filterent.filtername
						elseif filterclass == "filter_activator_team" then
							filter = "By team: " .. team.GetName(filterent.filterteam)
						end
						filter_cache[ent.filter] = filter
					else
						filter_cache[ent.filter] = false
						filter = false
					end
				end
				if filter == false then
					addLine(lines, ent.filter, "Filter: ", COLOR_FILTER, COLOR_INVALID)
				else
					addLine(lines, filter, "Filter: ", COLOR_FILTER, COLOR_TEXT)
				end
			elseif is_filter then
				addLine(lines, ent.filter, "Filter: ", COLOR_FILTER, COLOR_TEXT)
			end

			addLine(lines, ent.model, "Model: ", COLOR_FIELD, COLOR_TEXT)
			if ent.texture then
				if decal_cache[ent.texture] == nil then
					local path = "materials/" .. ent.texture
					if not ent.texture:find("%.vmt$") then
						path = path .. ".vmt"
					end
					decal_cache[ent.texture] = file.Exists(path, "GAME")
				end
				addLine(lines, ent.texture, "Texture: ", COLOR_FIELD, decal_cache[ent.texture] and COLOR_TEXT or COLOR_INVALID)
			end
			if ent.color then
				local col = Color(unpack(string_Explode(" ", ent.color)))
				col.a = 255
				addLine(lines, ent.color, "Color: ", COLOR_FIELD, col)
			end

			local posStr = Format(FORMAT_3, Vector_Unpack(pos))
			addLine(lines, posStr, "Position: ", COLOR_FIELD, COLOR_TEXT)

			if ent.angle then
				local angle = Format(FORMAT_3, Angle_Unpack(ang))
				addLine(lines, angle, "Angle: ", COLOR_FIELD, COLOR_TEXT)
			end

			if not ent.bounds_fallback then
				local mins = Format(FORMAT_3, Vector_Unpack(ent.mins))
				local maxs = Format(FORMAT_3, Vector_Unpack(ent.maxs))
				addLine(lines, maxs, "Maxs: ", COLOR_FIELD, COLOR_TEXT)
				addLine(lines, mins, "Mins: ", COLOR_FIELD, COLOR_TEXT)
			end

			addLine(lines, ent.text, "Text: ", COLOR_FIELD, COLOR_TEXT)

			addLine(lines, ent.target, "Target: ", COLOR_TARGET, ent.target_invalid and COLOR_INVALID or COLOR_TEXT)

			for on, outputs in next, ent.outputs do
				if isstring(outputs) then
					addLine(lines, outputs, on .. ": ", COLOR_OUTPUT, COLOR_TEXT)
				else
					for _, output in ipairs(outputs) do
						addLine(lines, output, on .. ": ", COLOR_OUTPUT, COLOR_TEXT)
					end
				end
			end

			local w = lines.longest / 2
			local h = th * (#lines / 2)
			local x = center.x - w
			local y = center.y - h

			local data = {
				x = x,
				y = y,
				w = w,
				h = h,
				cx = center.x,
				cy = center.y,
				lines = lines,
			}

			processed[#processed + 1] = data
		end

		for i, data in ipairs(processed) do
			if #processed == 1 then
				to_render[#to_render + 1] = data
				break
			end

			local x1, y1, w1, h1 = data.x, data.y, data.w, data.h
			local x2, y2, w2, h2
			if i == 1 then
				local next_data = processed[2]
				x2, y2, w2, h2 = next_data.x, next_data.y, next_data.w, next_data.h
			else
				local prev_data = processed[i - 1]
				x2, y2, w2, h2 = prev_data.x, prev_data.y, prev_data.w, prev_data.h
			end

			if is_outside_circle((ScrW() / 2) - x1, (ScrH() / 2) - y1, ScrH() - (64 + 48 + 8)) then
				local newpos = keep_inside_circle(x1, y1, ScrH() - (64 + 48 + 8))
				x1 = newpos.x
				y1 = newpos.y
			end
			if is_outside_circle((ScrW() / 2) - x2, (ScrH() / 2) - y2, ScrH() - (64 + 48 + 8)) then
				local newpos = keep_inside_circle(x2, y2, ScrH() - (64 + 48 + 8))
				x2 = newpos.x
				y2 = newpos.y
			end

			if
					(x2 >= x1 and x2 <= x1 + w1) or (x1 >= x2 and x1 <= x2 + w2) and
					(y1 >= y2 and y1 <= y2 + h2) or (y2 >= y1 and y2 <= y1 + h1)
			then
				to_stack[#to_stack + 1] = data
			else
				to_render[#to_render + 1] = data
			end
		end

		local new_to_render = {}
		if #to_render > 1 and #to_stack > 0 then
			for _, data in ipairs(to_render) do
				local x1, y1, w1, h1 = data.x, data.y, data.w, data.h
				local x2, y2, w2, h2

				local add_to_new = true

				local ay = 0
				for j, other_data in ipairs(to_stack) do
					h2 = other_data.h
					local _y2 = other_data.y
					x2, y2, w2 = other_data.x, ay, other_data.w
					if j == 1 then y2 = _y2 end
					if is_outside_circle((ScrW() / 2) - x2, (ScrH() / 2) - y2, ScrH() - (64 + 48 + 8)) then
						local newpos = keep_inside_circle(x2, y2, ScrH() - (64 + 48 + 8))
						x2 = newpos.x
						y2 = newpos.y
					end

					if
							(x2 >= x1 and x2 <= x1 + w1) or (x1 >= x2 and x1 <= x2 + w2) and
							(y1 >= ay and y1 <= ay + h2) or (_y2 >= y1 and _y2 <= y1 + h1)
					then
						to_stack[#to_stack + 1] = data
						add_to_new = false
						break
					end

					ay = ay + _y2 + h2 + (th / 2)
				end

				if add_to_new then
					new_to_render[#new_to_render + 1] = data
				end
			end
		else
			new_to_render = to_render
		end

		for _, data in ipairs(new_to_render) do
			render_data(data)
		end

		local mindist, nexty = math.huge, -math.huge
		for _, data in ipairs(to_stack) do
			mindist, nexty = render_data(data, true, mindist, nexty)
		end
	end
end)

hook.Add("PostDrawTranslucentRenderables", TAG, function(depth, skybox, skybox3d)
	if skybox then return end
	if not PICKER_ENABLED then return end

	local to_render = {}
	local has_hit = false

	local eyepos = EyePos()
	local eyeang = EyeAngles()
	local fwd = Angle_Forward(eyeang)
	local forward = fwd * 32768

	for _, ent in ipairs(MAP_ENTS) do
		if ent.model ~= nil then continue end

		local pos = ent.origin
		local ang = ent.angle or ANGLE_ZERO

		local dist = Vector_Distance(eyepos, pos)
		if dist > 512 then continue end

		local spos = Vector_ToScreen(pos)
		if not spos.visible then continue end

		local hitpos = util_IntersectRayWithOBB(eyepos, forward, pos, ang, ent.mins, ent.maxs)

		local icon = {
			class = ent.class,
			pos = pos,
			hit = false
		}

		if hitpos ~= nil then
			icon.hit = true
			has_hit = true
		end

		to_render[#to_render + 1] = icon
	end

	Angle_RotateAroundAxis(eyeang, fwd, 90)
	Angle_RotateAroundAxis(eyeang, Angle_Right(eyeang), 90)

	for _, icon in ipairs(to_render) do
		local alpha = icon.hit and 255 or 72
		if not has_hit then
			alpha = 255
		end

		local icon_mat = ENT_ICONS[icon.class] or ICON_DEFAULT

		cam_Start3D2D(icon.pos, eyeang, 0.5)
		render_SuppressEngineLighting(true)
		render_PushFilterMag(TEXFILTER_POINT)
		render_PushFilterMin(TEXFILTER_POINT)

		surface_SetMaterial(icon_mat)
		surface_SetDrawColor(255, 255, 255, alpha)
		surface_DrawTexturedRect(-8, -8, 16, 16)

		render_PopFilterMin()
		render_PopFilterMag()
		render_SuppressEngineLighting(false)
		cam_End3D2D()
	end
end)
