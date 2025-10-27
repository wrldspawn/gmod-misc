if not picktext then pcall(require, "picktext") end
if not picktext then return end

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
local Vector = Vector
local TEXFILTER_POINT = TEXFILTER.POINT

local cam_Start3D2D = cam.Start3D2D
local cam_End3D2D = cam.End3D2D
local render_PushFilterMag = render.PushFilterMag
local render_PushFilterMin = render.PushFilterMin
local render_PopFilterMag = render.PopFilterMag
local render_PopFilterMin = render.PopFilterMin
local string_Explode = string.Explode
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawLine = surface.DrawLine
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local table_sort = table.sort
local util_IntersectRayWithOBB = util.IntersectRayWithOBB

local ANGLE = FindMetaTable("Angle")
local Angle_Forward = ANGLE.Forward
local Angle_Right = ANGLE.Right
local Angle_RotateAroundAxis = ANGLE.RotateAroundAxis
local Angle_Unpack = ANGLE.Unpack

local VECTOR = FindMetaTable("Vector")
local Vector_Distance = VECTOR.Distance
local Vector_ToScreen = VECTOR.ToScreen
local Vector_Unpack = VECTOR.Unpack

local BOUNDS = 8
local ANGLE_ZERO = Angle()
local VEC_ZERO = Vector()
local VEC_FORWARD = Vector(BOUNDS, 0, 0)
local VEC_LEFT = Vector(0, BOUNDS, 0)
local VEC_UP = Vector(0, 0, BOUNDS)

if picker3_axis_mesh and picker3_axis_mesh:IsValid() then
	picker3_axis_mesh:Destroy()
end
if picker3_axis_inactive_mesh and picker3_axis_inactive_mesh:IsValid() then
	picker3_axis_inactive_mesh:Destroy()
end

do -- axis mesh
	for i = 1, 2 do
		local a = i == 2 and 72 or 255

		local obj = Mesh()
		mesh.Begin(obj, MATERIAL_LINES, 6)

		mesh.Color(255, 0, 0, a)
		mesh.Position(VEC_ZERO)
		mesh.AdvanceVertex()
		mesh.Color(255, 0, 0, a)
		mesh.Position(VEC_FORWARD)
		mesh.AdvanceVertex()

		mesh.Color(0, 255, 0, a)
		mesh.Position(VEC_ZERO)
		mesh.AdvanceVertex()
		mesh.Color(0, 255, 0, a)
		mesh.Position(VEC_LEFT)
		mesh.AdvanceVertex()

		mesh.Color(0, 0, 255, a)
		mesh.Position(VEC_ZERO)
		mesh.AdvanceVertex()
		mesh.Color(0, 0, 255, a)
		mesh.Position(VEC_UP)
		mesh.AdvanceVertex()
		mesh.End()

		if i == 2 then
			picker3_axis_inactive_mesh = obj
		else
			picker3_axis_mesh = obj
		end
	end
end

picker3_meshes = picker3_meshes or {}
for _, obj in pairs(picker3_meshes) do
	if obj:IsValid() then obj:Destroy() end
end

local ENTITIES = setmetatable({}, { __mode = "k" })
local MAP_ENTS = {}

hook.Add("EntityRemoved", TAG, function(ent)
	ENTITIES[ent] = nil
end)

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

local ICON_CAMERA = Material("icon16/camera.png")
local ICON_CAR = Material("icon16/car.png")
local ICON_CHOREO = Material("icon16/script_go.png")
local ICON_CLOUDS = Material("icon16/weather_clouds.png")
local ICON_COMMAND = Material("icon16/application_xp_terminal.png")
local ICON_COMMENT = Material("icon16/comment.png")
local ICON_EFFECT = Material("icon16/wand.png")
local ICON_GO = Material("icon16/bullet_go.png")
local ICON_ITEM = Material("icon16/box.png")
local ICON_LINK = Material("icon16/link.png")
local ICON_MAKER = Material("icon16/brick_add.png")
local ICON_MATERIAL = Material("icon16/image.png")
local ICON_NPC = Material("icon16/monkey.png")
local ICON_POINT = Material("icon16/arrow_down.png")
local ICON_SOUND = Material("icon16/sound.png")
local ICON_TARGET = CreateIcon("info_target", "editor/info_target")
local ICON_UP = Material("icon16/arrow_up.png")
local ICON_WATER = Material("icon16/water.png")
local ICON_WEAPON = Material("icon16/gun.png")
local ICON_VECTOR = Material("icon16/vector.png")

local ENT_ICONS = {
	ai_battle_line = ICON_GO,
	ai_goal_actbusy = Material("icon16/cog_go.png"),
	ai_goal_assault = ICON_GO,
	ai_script_conditions = Material("icon16/script_gear.png"),
	ambient_generic = ICON_SOUND,
	assault_assaultpoint = ICON_POINT,
	assault_rallypoint = ICON_POINT,
	combine_mine = ICON_WEAPON,
	env_ar2explosion = Material("icon16/bomb.png"),
	env_beam = ICON_VECTOR,
	env_entity_maker = ICON_MAKER,
	env_fog_controller = ICON_CLOUDS,
	env_gunfire = ICON_EFFECT,
	env_physimpact = ICON_EFFECT,
	env_smokestack = Material("icon16/fire.png"),
	env_soundscape_proxy = ICON_SOUND,
	env_soundscape_triggerable = ICON_SOUND,
	env_speaker = ICON_SOUND,
	env_splash = ICON_WATER,
	env_steam = ICON_CLOUDS,
	func_ladderendpoint = ICON_TARGET,
	func_useableladder = ICON_UP,
	game_countdown_timer = Material("icon16/hourglass.png"),
	game_score = Material("icon16/table_add.png"),
	info_hint = ICON_GO,
	info_ladder_dismount = ICON_TARGET,
	info_target = ICON_TARGET,
	info_teleport_destination = ICON_TARGET,
	info_waypoint = Material("icon16/exclamation.png"),
	infodecal = ICON_MATERIAL,
	keyframe_rope = ICON_VECTOR,
	light_spot = Material("icon16/lightbulb.png"),
	logic_choreographed_scene = ICON_CHOREO,
	logic_merchant_relay = Material("icon16/cart.png"),
	logic_playerproxy = Material("icon16/user_go.png"),
	material_modify_control = ICON_MATERIAL,
	move_rope = ICON_VECTOR,
	npc_antlion_template_maker = ICON_MAKER,
	npc_apcdriver = ICON_CAR,
	npc_bullseye = ICON_TARGET,
	npc_enemyfinder = Material("icon16/magnifier.png"),
	path_track = Material("icon16/chart_line.png"),
	phys_constraint = ICON_LINK,
	phys_constraintsystem = ICON_LINK,
	phys_lengthconstraint = ICON_LINK,
	phys_keepupright = ICON_UP,
	player_speedmod = Material("icon16/lightning.png"),
	point_camera = ICON_CAMERA,
	point_devshot_camera = ICON_CAMERA,
	point_clientcommand = ICON_COMMAND,
	point_message = ICON_COMMENT,
	point_message_multiplayer = ICON_COMMENT,
	point_servercommand = ICON_COMMAND,
	point_viewcontrol = ICON_CAMERA,
	scripted_sequence = ICON_CHOREO,
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

local function dedupe(verts)
	local dedupedVerts = {}
	for _, v1 in ipairs(verts) do
		local exists = false
		for _, v2 in ipairs(dedupedVerts) do
			local sub = v1 - v2
			if sub:LengthSqr() < 0.001 then
				exists = true
				break
			end
		end

		if not exists then
			dedupedVerts[#dedupedVerts + 1] = v1
		end
	end

	return dedupedVerts
end
local function create_bmodel_mesh(bmodel, idx)
	local faces = bmodel:GetFaces()

	local brush_verts = {}

	for _, face in ipairs(faces) do
		local verts = face:GenerateVertexTriangleData()
		local side = {}
		for _, vert in ipairs(verts) do
			side[#side + 1] = vert.pos
		end
		brush_verts[#brush_verts + 1] = side
	end

	local vertCount = 0
	local newBrush = {}
	for _, side in ipairs(brush_verts) do
		newBrush[#newBrush + 1] = dedupe(side)
		vertCount = vertCount + #side
	end

	local count = vertCount * 2
	if count > 32768 then
		print("[picker3] BRUSH MODEL TOO BIG TO OUTLINE", idx, count .. " > 32768")
		return
	end

	local obj = Mesh()
	mesh.Begin(obj, MATERIAL_LINES, vertCount)
	for _, side in ipairs(newBrush) do
		for j, vert in ipairs(side) do
			mesh.Color(255, 128, 0, 255)
			mesh.Position(vert)
			mesh.AdvanceVertex()

			local nextVert = side[j + 1 % #side]
			if not nextVert then nextVert = side[1] end
			mesh.Color(255, 128, 0, 255)
			mesh.Position(nextVert)
			mesh.AdvanceVertex()
		end
	end
	mesh.End()

	picker3_meshes[idx] = obj
end

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
		_tableTypes.OutValue = true
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
				startvalue = ent.startvalue or ent.InitialValue,
				maxvalue = ent.max,
				minvalue = ent.min,
				compvalue = ent.CompareValue,
				disabled = tobool(ent.startdisabled ~= nil and ent.startdisabled or ent.StartDisabled),
				outputs = {},
			}

			if ent.model then
				if ent.model:find("^%*") then
					local bmidx = tonumber(ent.model:sub(2))
					local bmodel = bmodels[bmidx]
					if bmodel then
						info.mins = bmodel.mins
						info.maxs = bmodel.maxs

						create_bmodel_mesh(bmodel, bmidx)
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
					elseif class:find("^item_") then
						ENT_ICONS[class] = ICON_ITEM
					elseif class:find("^vehicle_") then
						ENT_ICONS[class] = ICON_CAR
					elseif class:find("^npc_") then
						ENT_ICONS[class] = ICON_NPC
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
				if not string.match(k, "^On") and k ~= "OutValue" then continue end
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

local COLOR_TEXT = Color(255, 255, 255)
local COLOR_NAME = Color(0, 192, 0)
local COLOR_OUTPUT = Color(0, 192, 255)
local COLOR_TARGET = Color(255, 128, 0)
local COLOR_INVALID = Color(255, 0, 0)
local COLOR_FILTER = Color(231, 16, 148)
local COLOR_FIELD = Color(192, 192, 192) -- temp color?

local FORMAT_3 = "%.2f, %.2f, %.2f"

local filter_cache = {}
local decal_cache = {}

local function sortdist(a, b)
	return a.distance < b.distance
end

local lply = LocalPlayer()
local MATRIX = Matrix()

hook.Add("HUDPaint", TAG, function()
	if PICKER_ENABLED then
		local to_process = {}
		local axes = {}
		local has_hit = false

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
				has_hit = true
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
				has_hit = true
			end

			axes[#axes + 1] = axis
		end

		if false then
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
		end

		cam.Start3D()
		for _, axis in ipairs(axes) do
			local spos = Vector_ToScreen(axis.pos)
			if not spos.visible then continue end

			local obj = has_hit and (axis.hit and picker3_axis_mesh or picker3_axis_inactive_mesh) or picker3_axis_mesh

			MATRIX:Identity()
			MATRIX:Translate(axis.pos)
			MATRIX:Rotate(axis.ang)

			render.SetColorMaterial()
			cam.PushModelMatrix(MATRIX)
			if obj and obj:IsValid() then
				obj:Draw()
			end
			cam.PopModelMatrix()
		end
		cam.End3D()

		table_sort(to_process, sortdist)

		for _, ent in ipairs(to_process) do
			local entity = ent.entity
			local isvalid = IsValid(entity)
			local pos = isvalid and entity:GetPos() or ent.origin
			local ang = isvalid and entity:GetAngles() or (ent.angle or ANGLE_ZERO)

			local center = pos:ToScreen()

			local lines = {}
			picktext.AddLine(lines, isvalid and " (_" .. entity:EntIndex() .. ")" or "", ent.class, COLOR_TEXT, COLOR_FIELD)
			if ent.disabled then
				picktext.AddLine(lines, "Starts Disabled", "", COLOR_INVALID, COLOR_INVALID)
			end

			picktext.AddLine(lines, ent.name, "Name: ", COLOR_NAME, COLOR_TEXT)

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
					picktext.AddLine(lines, ent.filter, "Filter: ", COLOR_FILTER, COLOR_INVALID)
				else
					picktext.AddLine(lines, filter, "Filter: ", COLOR_FILTER, COLOR_TEXT)
				end
			elseif is_filter then
				picktext.AddLine(lines, ent.filter, "Filter: ", COLOR_FILTER, COLOR_TEXT)
			end

			picktext.AddLine(lines, ent.model, "Model: ", COLOR_FIELD, COLOR_TEXT)
			if ent.texture then
				if decal_cache[ent.texture] == nil then
					local path = "materials/" .. ent.texture
					path = path:gsub("%.spr$", "")
					if not ent.texture:find("%.vmt$") then
						path = path .. ".vmt"
					end
					decal_cache[ent.texture] = file.Exists(path, "GAME")
				end
				picktext.AddLine(lines, ent.texture, "Texture: ", COLOR_FIELD,
					decal_cache[ent.texture] and COLOR_TEXT or COLOR_INVALID)
			end
			if ent.color then
				local col = Color(unpack(string_Explode(" ", ent.color)))
				col.a = 255
				picktext.AddLine(lines, ent.color, "Color: ", COLOR_FIELD, col)
			end

			local posStr = Format(FORMAT_3, Vector_Unpack(pos))
			picktext.AddLine(lines, posStr, "Position: ", COLOR_FIELD, COLOR_TEXT)

			if ent.angle then
				local angle = Format(FORMAT_3, Angle_Unpack(ang))
				picktext.AddLine(lines, angle, "Angle: ", COLOR_FIELD, COLOR_TEXT)
			end

			if not ent.bounds_fallback then
				local mins = Format(FORMAT_3, Vector_Unpack(ent.mins))
				local maxs = Format(FORMAT_3, Vector_Unpack(ent.maxs))
				picktext.AddLine(lines, maxs, "Maxs: ", COLOR_FIELD, COLOR_TEXT)
				picktext.AddLine(lines, mins, "Mins: ", COLOR_FIELD, COLOR_TEXT)
			end

			picktext.AddLine(lines, ent.text, "Text: ", COLOR_FIELD, COLOR_TEXT)
			picktext.AddLine(lines, ent.startvalue, "Starting Value: ", COLOR_FIELD, COLOR_TEXT)
			picktext.AddLine(lines, ent.minvalue, "Min Value: ", COLOR_FIELD, COLOR_TEXT)
			picktext.AddLine(lines, ent.maxvalue, "Max Value: ", COLOR_FIELD, COLOR_TEXT)
			picktext.AddLine(lines, ent.compvalue, "Compare Value: ", COLOR_FIELD, COLOR_TEXT)

			picktext.AddLine(lines, ent.target, "Target: ", COLOR_TARGET, ent.target_invalid and COLOR_INVALID or COLOR_TEXT)

			for on, outputs in next, ent.outputs do
				if isstring(outputs) then
					picktext.AddLine(lines, outputs, on .. ": ", COLOR_OUTPUT, COLOR_TEXT)
				else
					for _, output in ipairs(outputs) do
						picktext.AddLine(lines, output, on .. ": ", COLOR_OUTPUT, COLOR_TEXT)
					end
				end
			end

			picktext.AddBlock(lines, center.x, center.y)
		end
	end
end)

local NO_HDR = Vector(0.6, 0, 0)
hook.Add("PostDrawTranslucentRenderables", TAG, function(depth, skybox, skybox3d)
	if skybox then return end
	if not PICKER_ENABLED then return end

	local to_render = {}
	local meshes = {}
	local has_hit = false

	local eyepos = EyePos()
	local eyeang = EyeAngles()
	local fwd = Angle_Forward(eyeang)
	local forward = fwd * 32768

	for _, ent in ipairs(MAP_ENTS) do
		local entity = ent.entity
		local isvalid = IsValid(entity)
		local pos = isvalid and entity:GetPos() or ent.origin
		local ang = isvalid and entity:GetAngles() or (ent.angle or ANGLE_ZERO)

		local hitpos = util_IntersectRayWithOBB(eyepos, forward, pos, ang, ent.mins, ent.maxs)

		local dist = Vector_Distance(eyepos, pos)
		if dist > 32768 then continue end

		if ent.model ~= nil then
			if ent.model:find("^%*") and hitpos ~= nil then
				local idx = tonumber(ent.model:sub(2))
				local obj = picker3_meshes[idx]
				if obj and obj:IsValid() then
					meshes[#meshes + 1] = obj
				end
			end
			continue
		end
		local mdl = isvalid and entity:GetModel()
		if isvalid and mdl and mdl ~= "" then continue end

		if dist > 512 then continue end

		local spos = Vector_ToScreen(pos)
		if not spos.visible then continue end

		local hit = hitpos ~= nil
		if hit then
			has_hit = hit
		end

		local icon = {
			class = ent.class,
			pos = pos,
			hit = hit,
		}

		to_render[#to_render + 1] = icon
	end

	Angle_RotateAroundAxis(eyeang, fwd, 90)
	Angle_RotateAroundAxis(eyeang, Angle_Right(eyeang), 90)

	local tone = render.GetToneMappingScaleLinear()
	render.SetToneMappingScaleLinear(NO_HDR)
	for _, icon in ipairs(to_render) do
		local alpha = icon.hit and 255 or 72
		if not has_hit then
			alpha = 255
		end

		local icon_mat = ENT_ICONS[icon.class] or ICON_DEFAULT

		cam_Start3D2D(icon.pos, eyeang, 0.5)
		render_PushFilterMag(TEXFILTER_POINT)
		render_PushFilterMin(TEXFILTER_POINT)

		surface_SetMaterial(icon_mat)
		surface_SetDrawColor(255, 255, 255, alpha)
		surface_DrawTexturedRect(-8, -8, 16, 16)

		render_PopFilterMin()
		render_PopFilterMag()
		cam_End3D2D()
	end

	render.SetColorMaterial()
	for _, obj in ipairs(meshes) do
		if not obj:IsValid() then continue end
		obj:Draw()
	end
	render.SetToneMappingScaleLinear(tone)
end)
