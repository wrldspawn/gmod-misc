local TAG = "picker3"

local ENTITIES = setmetatable({}, { __mode = "k" })
local MAP_ENTS = {}

hook.Add("EntityRemoved", TAG, function(ent)
	ENTITIES[ent] = nil
end)

local BOUNDS = 8

local function CreateIcon(class, path)
	return CreateMaterial("picker3_icon-" .. class, "UnlitGeneric", {
		["$basetexture"] = path,
		["$alpha"] = 1,
		["$alphatest"] = 1,
		["$vertexcolor"] = 1,
	})
end

local ICON_DEFAULT = Material("icon16/help.png")
local ICON_SPAWNPOINT = Material("icon16/user_add.png")
local ICON_FILTER = Material("icon16/tag_blue.png")
local ICON_NODE = Material("icon16/map_go.png")
local ENT_ICONS = {
	env_entity_maker = Material("icon16/brick_add.png"),
	game_countdown_timer = Material("icon16/hourglass.png"),
	info_waypoint = Material("icon16/exclamation.png"),
	infodecal = Material("icon16/image.png"),
	player_speedmod = Material("icon16/lightning.png"),
	point_clientcommand = Material("icon16/application_xp_terminal.png"),
	point_message_multiplayer = Material("icon16/comment.png"),
	point_servercommand = Material("icon16/application_xp_terminal.png"),
	water_lod_control = Material("icon16/water.png"),
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

local MAP
local function GetMapEnts()
	if NikNaks then
		MAP = NikNaks.CurrentMap

		-- handled by showtriggers
		local IGNORE = {
			point_hurt = true,
			point_teleport = true,
			point_vehiclespawn = true,
			point_trigger = true,
			point_weapon_eater = true,
		}

		local bmodels = MAP:GetBModels()

		for idx, ent in ipairs(MAP:GetEntities()) do
			local class = ent.classname
			if class:find("^trigger_") or IGNORE[class] then continue end

			local info = {
				creationid = idx + 1235, -- see MapCreationID wiki note for this magic number
				class = class,
				name = ent.targetname,
				filter = ent.filtername,
				origin = ent.origin,
				angle = ent.angles,
				model = ent.model,
				texture = ent.texture,
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
					end
				end
			end

			info.color = ent.color or ent._light

			if not info.mins and not info.maxs then
				info.mins = Vector(-BOUNDS, -BOUNDS, -BOUNDS)
				info.maxs = Vector(BOUNDS, BOUNDS, BOUNDS)
				info.bounds_fallback = true
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
	local tw = surface.GetTextSize(str)
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

hook.Add("HUDPaint", TAG, function()
	if PICKER_ENABLED then
		local to_render = {}
		local axes = {}

		local lply = LocalPlayer()
		local eyepos = EyePos()
		local eyeang = EyeAngles()
		local forward = eyeang:Forward() * 32768

		for _, ent in ipairs(MAP_ENTS) do
			local entity = ent.entity
			local isvalid = IsValid(entity)
			local pos = isvalid and entity:GetPos() or ent.origin
			local ang = isvalid and entity:GetAngles() or (ent.angle or ANGLE_ZERO)

			if isvalid then
				if entity:IsWeapon() and entity:GetOwner() == lply then continue end
			end

			local hitpos = util.IntersectRayWithOBB(eyepos, forward, pos, ang, ent.mins, ent.maxs)

			local axis = {
				pos = pos,
				ang = ang,
				hit = false,
			}

			if hitpos ~= nil then
				to_render[#to_render + 1] = ent
				axis.hit = true
			end

			ent.distance = eyepos:Distance(pos)

			axes[#axes + 1] = axis
		end

		for ent in next, ENTITIES do
			if not IsValid(ent) then continue end

			local pos = ent:GetPos()

			if (
						ent == lply or
						ent:GetParent() == lply or
						(ent:IsWeapon() and ent:GetOwner() == lply) or
						ent == lply:GetViewModel() or
						pos == lply:GetPos()
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

			local hitpos = util.IntersectRayWithOBB(eyepos, forward, pos, ang, mins, maxs)

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
					distance = eyepos:Distance(pos),
					outputs = {},
					bounds_fallback = bounds_fallback,
				}

				to_render[#to_render + 1] = info
				axis.hit = true
			end

			axes[#axes + 1] = axis
		end

		for _, axis in ipairs(axes) do
			local pos = axis.pos
			local ang = axis.ang

			local spos = pos:ToScreen()
			if not spos.visible then continue end

			local alpha = axis.hit and 255 or 72
			if #to_render == 0 then
				alpha = 255
			end

			local pos_forward = LocalToWorld(VEC_FORWARD, ANGLE_ZERO, pos, ang)
			local pos_left = LocalToWorld(VEC_LEFT, ANGLE_ZERO, pos, ang)
			local pos_up = LocalToWorld(VEC_UP, ANGLE_ZERO, pos, ang)

			local spos_f = pos_forward:ToScreen()
			local spos_l = pos_left:ToScreen()
			local spos_u = pos_up:ToScreen()

			surface.SetDrawColor(255, 0, 0, alpha)
			surface.DrawLine(spos.x, spos.y, spos_f.x, spos_f.y)
			surface.SetDrawColor(0, 255, 0, alpha)
			surface.DrawLine(spos.x, spos.y, spos_l.x, spos_l.y)
			surface.SetDrawColor(0, 0, 255, alpha)
			surface.DrawLine(spos.x, spos.y, spos_u.x, spos_u.y)
		end

		table.sort(to_render, function(a, b)
			return a.distance < b.distance
		end)

		local mindist, nexty = math.huge, -math.huge
		for _, ent in ipairs(to_render) do
			local entity = ent.entity
			local isvalid = IsValid(entity)
			local pos = isvalid and entity:GetPos() or ent.origin
			local ang = isvalid and entity:GetAngles() or (ent.angle or ANGLE_ZERO)

			local center = pos:ToScreen()

			surface.SetFont("BudgetLabel")

			local lines = {}
			addLine(lines, isvalid and " (_" .. entity:EntIndex() .. ")" or "", ent.class, COLOR_TEXT, COLOR_FIELD)
			if ent.disabled then
				addLine(lines, "Starts Disabled", "", COLOR_INVALID, COLOR_INVALID)
			end

			addLine(lines, ent.name, "Name: ", COLOR_NAME, COLOR_TEXT)

			if ent.filter and MAP then
				local filter = filter_cache[ent.filter]
				if not filter then
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
			end

			addLine(lines, ent.model, "Model: ", COLOR_FIELD, COLOR_TEXT)
			if ent.texture then
				if decal_cache[ent.texture] == nil then
					decal_cache[ent.texture] = file.Exists("materials/" .. ent.texture .. ".vmt", "GAME")
				end
				addLine(lines, ent.texture, "Texture: ", COLOR_FIELD, decal_cache[ent.texture] and COLOR_TEXT or COLOR_INVALID)
			end
			if ent.color then
				local col = Color(unpack(string.Explode(" ", ent.color)))
				col.a = 255
				addLine(lines, ent.color, "Color: ", COLOR_FIELD, col)
			end

			local posStr = string.format(FORMAT_3, pos:Unpack())
			addLine(lines, posStr, "Position: ", COLOR_FIELD, COLOR_TEXT)

			if ent.angle then
				local angle = string.format(FORMAT_3, ang:Unpack())
				addLine(lines, angle, "Angle: ", COLOR_FIELD, COLOR_TEXT)
			end

			if not ent.bounds_fallback then
				local mins = string.format(FORMAT_3, ent.mins:Unpack())
				local maxs = string.format(FORMAT_3, ent.maxs:Unpack())
				addLine(lines, maxs, "Maxs: ", COLOR_FIELD, COLOR_TEXT)
				addLine(lines, mins, "Mins: ", COLOR_FIELD, COLOR_TEXT)
			end

			for on, outputs in next, ent.outputs do
				if isstring(outputs) then
					addLine(lines, outputs, on .. ": ", COLOR_OUTPUT, COLOR_TEXT)
				else
					for _, output in ipairs(outputs) do
						addLine(lines, output, on .. ": ", COLOR_OUTPUT, COLOR_TEXT)
					end
				end
			end

			local _, th = surface.GetTextSize("W")

			local w = lines.longest / 2
			local h = th * (#lines / 2)
			local x = center.x - w
			local y = center.y - h

			if nexty > y then y = nexty end

			if is_outside_circle((ScrW() / 2) - x, (ScrH() / 2) - y, ScrH() - (64 + 48 + 8)) then
				local newpos = keep_inside_circle(x, y, ScrH() - (64 + 48 + 8))
				x = newpos.x
				y = newpos.y
			end

			surface.SetDrawColor(255, 255, 255, 96)
			surface.DrawLine(center.x, center.y, x + w, y + h)

			for _, line in ipairs(lines) do
				surface.SetTextColor(line.pColor:Unpack())
				surface.SetTextPos(x, y)
				surface.DrawText(line.prefix)
				surface.SetTextColor(line.color:Unpack())
				surface.DrawText(line.text)
				y = y + th
			end

			local _x, _y = x - center.x, y - center.y
			local dist = _x * _x + _y * _y * th

			if dist < mindist then
				mindist = dist
			end
			nexty = y + (th / 2)
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
	local forward = eyeang:Forward() * 32768

	for _, ent in ipairs(MAP_ENTS) do
		if ent.model ~= nil then continue end

		local pos = ent.origin
		local ang = ent.angle or ANGLE_ZERO

		local dist = eyepos:Distance(pos)
		if dist > 512 then continue end

		local spos = pos:ToScreen()
		if not spos.visible then continue end

		local hitpos = util.IntersectRayWithOBB(eyepos, forward, pos, ang, ent.mins, ent.maxs)

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

	eyeang:RotateAroundAxis(eyeang:Forward(), 90)
	eyeang:RotateAroundAxis(eyeang:Right(), 90)

	for _, icon in ipairs(to_render) do
		local alpha = icon.hit and 255 or 72
		if not has_hit then
			alpha = 255
		end

		local icon_mat = ENT_ICONS[icon.class] or ICON_DEFAULT

		cam.Start3D2D(icon.pos, eyeang, 0.5)
		render.SuppressEngineLighting(true)
		render.PushFilterMag(TEXFILTER.POINT)
		render.PushFilterMin(TEXFILTER.POINT)

		surface.SetMaterial(icon_mat)
		surface.SetDrawColor(255, 255, 255, alpha)
		surface.DrawTexturedRect(-8, -8, 16, 16)

		render.PopFilterMin()
		render.PopFilterMag()
		render.SuppressEngineLighting(false)
		cam.End3D2D()
	end
end)
