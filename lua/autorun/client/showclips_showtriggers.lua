if not NikNaks then pcall(require, "niknaks") end
if not NikNaks then return end

-- hack for triggers cause i dont feel like making a pr
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

local parseEntityData = getupvalues(NikNaks.__metatables.BSP.GetEntities).parseEntityData
local ParseEntity = getupvalues(parseEntityData).ParseEntity
local _tableTypes = getupvalues(ParseEntity)._tableTypes
_tableTypes.OnEndTouch = true
NikNaks.CurrentMap._entities = nil

local MAP = NikNaks.CurrentMap

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

-- {{{ functions translated to niknaks from https://github.com/h3xcat/gmod-luabsp/blob/master/luabsp.lua
local function PlaneIntersect(p1, p2, p3)
	local norm1, d1 = p1.normal, p1.dist
	local norm2, d2 = p2.normal, p2.dist
	local norm3, d3 = p3.normal, p3.dist
	local a1, b1, c1 = norm1:Unpack()
	local a2, b2, c2 = norm2:Unpack()
	local a3, b3, c3 = norm3:Unpack()

	local det = a1 * (b2 * c3 - c2 * b3) - b1 * (a2 * c3 - c2 * a3) + c1 * (a2 * b3 - b2 * a3)

	-- is parallel
	if math.abs(det) < 0.001 then return end

	local x = d1 * (b2 * c3 - c2 * b3) - b1 * (d2 * c3 - c2 * d3) + c1 * (d2 * b3 - b2 * d3)
	local y = a1 * (d2 * c3 - c2 * d3) - d1 * (a2 * c3 - c2 * a3) + c1 * (a2 * d3 - d2 * a3)
	local z = a1 * (b2 * d3 - d2 * b3) - b1 * (a2 * d3 - d2 * a3) + d1 * (a2 * b3 - b2 * a3)

	return Vector(x, y, z) / det
end

local function IsPointInside(planes, point)
	for _, plane in ipairs(planes) do
		local norm = plane.normal

		local t = point.x * norm.x + point.y * norm.y + point.z * norm.z
		if t - plane.dist > 0.01 then return false end
	end

	return true
end

local function VerticiesFromPlanes(planes)
	local verts = {}

	for i = 1, #planes do
		local p1 = planes[i]
		for j = i + 1, #planes do
			local p2 = planes[j]
			for k = j + 1, #planes do
				local p3 = planes[k]

				local vert = PlaneIntersect(p1, p2, p3)
				if vert and IsPointInside(planes, vert) then
					verts[#verts + 1] = vert
				end
			end
		end
	end

	local deduped = dedupe(verts)

	return deduped
end
-- }}}

local function collectClipBrushes()
	local brushes = {}
	for _, brush in ipairs(MAP:GetBrushes()) do
		local invis = true
		local sky = false
		local nodraw = true
		for i = 1, brush.numsides do
			local tex = brush:GetTexture(i):lower()
			if tex ~= "tools/toolsinvisible" then
				invis = false
			end
			if tex ~= "tools/toolsnodraw" then
				nodraw = false
			end
			if tex == "tools/toolsskybox" or tex == "tools/toolsskybox2d" then
				sky = true
			end
		end

		if invis == false and sky == false and nodraw == false and not (brush:HasContents(CONTENTS_PLAYERCLIP) or brush:HasContents(CONTENTS_MONSTERCLIP)) then continue end

		if sky then
			local skySides = {}
			for i = 1, brush.numsides do
				local tex = brush:GetTexture(i):lower()
				if tex == "tools/toolsskybox" or tex == "tools/toolsskybox2d" then
					skySides[i] = true
				end
			end
			brush.skySides = skySides
		end

		brush.invis = invis
		brush.sky = sky
		brush.nodraw = nodraw
		brushes[#brushes + 1] = brush
	end

	-- this implementation is not perfect but it at least works
	-- (theres a weird ring on surf_adrift_fix, a lot of maps have brushes at origin)
	local clipBrushes = {}
	for _, brush in ipairs(brushes) do
		local planes = {}
		for _, side in ipairs(brush.sides) do
			planes[#planes + 1] = side.plane
		end

		local verts = VerticiesFromPlanes(planes)

		local brush_verts = {}
		for _, side in ipairs(brush.sides) do
			local plane = side.plane
			local norm = plane.normal

			local points = {}

			for _, vert in ipairs(verts) do
				local t = vert.x * norm.x + vert.y * norm.y + vert.z * norm.z;
				if math.abs(t - plane.dist) > 0.01 then continue end -- not on a plane

				points[#points + 1] = vert
			end

			-- sort them in clockwise order
			local c = points[1]
			table.sort(points, function(a, b)
				local dot = norm:Dot((c - a):Cross(b - c))
				return dot > 0.001
			end)

			local sidePoints = {}
			for i = 1, #points - 2 do
				sidePoints[#sidePoints + 1] = points[1] + norm * 0
				sidePoints[#sidePoints + 1] = points[i + 1] + norm * 0
				sidePoints[#sidePoints + 1] = points[i + 2] + norm * 0
			end

			-- somehow ended up with empty sides
			if #sidePoints > 0 then
				brush_verts[#brush_verts + 1] = sidePoints
				sidePoints.norm = norm
			end
		end
		brush_verts.contents = brush:GetContents()
		brush_verts.invis = brush.invis
		brush_verts.sky = brush.sky
		brush_verts.nodraw = brush.nodraw
		brush_verts.skySides = brush.skySides

		clipBrushes[#clipBrushes + 1] = brush_verts
	end

	return clipBrushes
end

local trigger_info = {}
local point_triggers = {}
local POINT_TYPES = { "point_trigger", "point_vehiclespawn", "point_hurt", "point_teleport", "point_weapon_eater" }

local function collectTriggerBrushes()
	local triggerBrushes = {}
	local bmodels = MAP:GetBModels()
	for _, trigger in ipairs(MAP:FindByClass("^trigger_*")) do
		if not trigger.model then
			print("trigger with bad model")
			PrintTable(trigger)
			continue
		end
		local model = tonumber(trigger.model:sub(2))
		if not model then
			print("trigger with bad model", trigger.model)
			continue
		end
		local bmodel = bmodels[model]

		if not bmodel then continue end

		local faces = bmodels[model]:GetFaces()

		local brush_verts = {}

		for _, face in ipairs(faces) do
			local verts = face:GenerateVertexTriangleData()
			local side = {}
			for _, vert in ipairs(verts) do
				side[#side + 1] = vert.pos
			end
			brush_verts[#brush_verts + 1] = side
		end

		--local origin = trigger.origin

		brush_verts.classname = trigger.classname
		brush_verts.outputs = {
			OnStartTouch = trigger.OnStartTouch,
			OnEndTouch = trigger.OnEndTouch,
		}

		triggerBrushes[#triggerBrushes + 1] = brush_verts
		local info = {
			class = trigger.classname,
			name = trigger.targetname,
			filter = trigger.filtername,
			target = trigger.target or trigger.landmark,
			origin = trigger.origin,
			mins = bmodel.mins,
			maxs = bmodel.maxs,
			disabled = tobool(trigger.startdisabled ~= nil and trigger.startdisabled or trigger.StartDisabled),
			speed = trigger.speed,
			outputs = {},
		}
		for k, v in next, trigger do
			if not string.match(k, "^On") then continue end
			info.outputs[k] = v
		end

		if trigger.target then
			local target = MAP:FindByName(trigger.target)[1]

			local landmark
			if trigger.landmark then
				landmark = MAP:FindByName(trigger.landmark)[1]
			end

			if target then
				info.target_pos = landmark and target.origin - landmark.origin or target.origin
			else
				info.target_invalid = true
			end
		end

		if trigger.pushdir then
			info.dir = Vector(trigger.pushdir)
		end

		trigger_info[#trigger_info + 1] = info
	end
	for _, class in ipairs(POINT_TYPES) do
		for _, trigger in ipairs(MAP:FindByClass(class)) do
			local radius = trigger.radius or trigger.TriggerRadius or trigger.DamageRadius or trigger.EatRadius
			if not radius then continue end

			local point = {
				classname = trigger.classname,
				pos = trigger.origin,
				radius = radius,
				once = tobool(trigger.TriggerOnce),
				outputs = {}
			}
			point_triggers[#point_triggers + 1] = point

			local info = {
				class = trigger.classname,
				name = trigger.targetname,
				filter = trigger.filtername,
				target = trigger.target or trigger.landmark,
				origin = trigger.origin,
				mins = Vector(-1, -1, -1) * radius,
				maxs = Vector(1, 1, 1) * radius,
				radius = radius,
				once = tobool(trigger.TriggerOnce),
				disabled = tobool(trigger.startdisabled ~= nil and trigger.startdisabled or trigger.StartDisabled),
				outputs = {},
			}
			for k, v in next, trigger do
				if not string.match(k, "^On") then continue end
				info.outputs[k] = v
				point.outputs[k] = v
			end

			if trigger.target then
				local target = MAP:FindByName(trigger.target)[1]

				local landmark
				if trigger.landmark then
					landmark = MAP:FindByName(trigger.landmark)[1]
				end

				if target then
					info.target_pos = landmark and target.origin - landmark.origin or target.origin
				else
					info.target_invalid = true
				end
			end

			trigger_info[#trigger_info + 1] = info
		end
	end

	return triggerBrushes
end

-- hotreload
showclips_clipMeshes = showclips_clipMeshes or {}

for _, obj in ipairs(showclips_clipMeshes) do
	if obj:IsValid() then obj:Destroy() end
end

table.Empty(showclips_clipMeshes)

local function generateClipMeshes()
	local clipBrushes = collectClipBrushes()

	for _, brush in ipairs(clipBrushes) do
		local contents = brush.contents
		local r = 231
		local g = 16
		local b = 148
		if brush.invis then
			r = 255
			g = 255
			b = 255
		elseif brush.nodraw then
			r = 251
			g = 218
			b = 36
		elseif brush.sky then
			r = 178
			g = 225
			b = 255
		end

		if bit.band(contents, CONTENTS_MONSTERCLIP) ~= 0 then
			if bit.band(contents, CONTENTS_PLAYERCLIP) == 0 then
				r = 140
				g = 32
				b = 211
			else
				r = 211
				g = 57
				b = 32
			end
		elseif bit.band(contents, CONTENTS_PLAYERCLIP) ~= 0 then
			r = 231
			g = 16
			b = 148
		end

		-- face
		local vertCount = 0
		for _, side in ipairs(brush) do
			vertCount = vertCount + #side
		end

		local obj = Mesh()
		mesh.Begin(obj, MATERIAL_TRIANGLES, vertCount / 3)
		for i, side in ipairs(brush) do
			local skySide = true
			if brush.sky and not brush.skySides[i] then
				skySide = false
			end

			for _, vert in ipairs(side) do
				mesh.Color(r, g, b, skySide and 32 or 0)
				mesh.Position(vert)
				mesh.AdvanceVertex()
			end
		end
		mesh.End()

		showclips_clipMeshes[#showclips_clipMeshes + 1] = obj

		-- outline
		local lineCount = 0
		local newBrush = {}

		for _, side in ipairs(brush) do
			newBrush[#newBrush + 1] = dedupe(side)
		end
		for _, side in ipairs(newBrush) do
			lineCount = lineCount + #side
		end

		obj = Mesh()
		mesh.Begin(obj, MATERIAL_LINES, vertCount)
		for _, side in ipairs(newBrush) do
			for j, vert in ipairs(side) do
				mesh.Color(r, g, b, 255)
				mesh.Position(vert)
				mesh.AdvanceVertex()

				-- spent hours doing complicated math and then upon giving up i went "what does valve do?"
				-- this.
				local nextVert = side[j + 1 % #side]
				if not nextVert then nextVert = side[1] end
				mesh.Position(nextVert)
				mesh.AdvanceVertex()
			end
		end
		mesh.End()

		showclips_clipMeshes[#showclips_clipMeshes + 1] = obj
	end
end

-- triggers
showtriggers_triggerMeshes = showtriggers_triggerMeshes or {}

for _, obj in ipairs(showtriggers_triggerMeshes) do
	if obj:IsValid() then obj:Destroy() end
end

table.Empty(showtriggers_triggerMeshes)

local TYPE_UNKNOWN = -1
local TYPE_MULTIPLE = 0
local TYPE_ANTIPRE = 1
local TYPE_SPEED = 2
local TYPE_TELEPORT = 3
local TYPE_ONCE = 4
local TYPE_OC = 5
local TYPE_HURT = 6

local TRIGGER_COLORS = {
	[TYPE_UNKNOWN] = Color(255, 156, 0),
	[TYPE_MULTIPLE] = Color(0, 255, 0),
	[TYPE_ANTIPRE] = Color(128, 192, 0),
	[TYPE_SPEED] = Color(192, 255, 0),
	[TYPE_TELEPORT] = Color(0, 128, 255),
	[TYPE_ONCE] = Color(164, 100, 0),
	[TYPE_OC] = Color(0, 255, 255),
	[TYPE_HURT] = Color(164, 0, 0),
}

local OC_TRIGGERS = {
	trigger_once_oc = true,
	trigger_multiple_oc = true,
	trigger_auto_crouch = true,
	trigger_nocollide = true,
	trigger_player_count = true,
	trigger_vehiclespawn = true,
	point_vehiclespawn = true,
	point_weapon_eater = true
}

local function classify_trigger(brush)
	local classname = brush.classname
	local type = TYPE_UNKNOWN

	if classname == "trigger_multiple" or classname == "point_trigger" then
		type = TYPE_MULTIPLE

		if brush.outputs.OnStartTouch then
			for _, data in ipairs(brush.outputs.OnStartTouch) do
				local output = data:lower()
				if output:find("gravity 40") then -- Gravity anti-prespeed https://gamebanana.com/prefabs/6760.
					type = TYPE_ANTIPRE
					break
				elseif
						output:find("basevelocity") -- some surf map boosters (e.g. surf_quirky)
						or
						output:find("modifyspeed") -- player_speedmod
				then
					type = TYPE_SPEED
					break
				end
			end
		end

		if brush.outputs.OnEndTouch then
			for _, data in ipairs(brush.outputs.OnEndTouch) do
				local output = data:lower()
				if
						output:find("gravity -") -- Gravity booster https://gamebanana.com/prefabs/6677.
						or
						output:find("basevelocity") -- Basevelocity booster https://gamebanana.com/prefabs/7118.
						or
						output:find("modifyspeed") -- player_speedmod
				then
					type = TYPE_SPEED
					break
				end
			end
		end
	elseif classname == "trigger_push" then
		type = TYPE_SPEED
	elseif classname == "trigger_teleport" or classname == "point_teleport" then
		type = TYPE_TELEPORT
	elseif classname == "trigger_once" then
		type = TYPE_ONCE
	elseif classname == "trigger_hurt" or classname == "trigger_waterydeath" or classname == "point_hurt" then
		type = TYPE_HURT
	elseif OC_TRIGGERS[classname] then
		type = TYPE_OC
	end

	if classname == "point_trigger" and brush.once then
		type = TYPE_ONCE
	end

	return TRIGGER_COLORS[type]
end

local function generateTriggerMeshes()
	local triggerBrushes = collectTriggerBrushes()

	for _, brush in ipairs(triggerBrushes) do
		local col = classify_trigger(brush)

		-- face
		local vertCount = 0
		for _, side in ipairs(brush) do
			vertCount = vertCount + #side
		end

		local obj = Mesh()
		mesh.Begin(obj, MATERIAL_TRIANGLES, vertCount / 3)
		for _, side in ipairs(brush) do
			for _, vert in ipairs(side) do
				mesh.Color(col.r, col.g, col.b, 32)
				mesh.Position(vert)
				mesh.AdvanceVertex()
			end
		end
		mesh.End()

		showtriggers_triggerMeshes[#showtriggers_triggerMeshes + 1] = obj

		-- outline
		local lineCount = 0
		local newBrush = {}
		for _, side in ipairs(brush) do
			newBrush[#newBrush + 1] = dedupe(side)
		end

		for _, side in ipairs(newBrush) do
			lineCount = lineCount + #side
		end

		obj = Mesh()
		mesh.Begin(obj, MATERIAL_LINES, vertCount)
		for _, side in ipairs(newBrush) do
			for j, vert in ipairs(side) do
				mesh.Color(col.r, col.g, col.b, 255)
				mesh.Position(vert)
				mesh.AdvanceVertex()

				local nextVert = side[j + 1 % #side]
				if not nextVert then nextVert = side[1] end
				mesh.Position(nextVert)
				mesh.AdvanceVertex()
			end
		end
		mesh.End()

		showtriggers_triggerMeshes[#showtriggers_triggerMeshes + 1] = obj
	end
end

local showclips = false
local showtriggers = false

local clip_commands = {
	sm_showbrushes = true,
	sm_showclips = true,
	sm_showclipbrushes = true,
	sm_showplayerclips = true,
	sm_scb = true,
	sm_spc = true,
}

local function toggleclips()
	if #showclips_clipMeshes == 0 then
		LocalPlayer():ChatPrint("Generating clip brush meshes, please wait...")
		generateClipMeshes()
	end

	if showclips then
		showclips = false
		LocalPlayer():ChatPrint("No longer showing clip brushes.")
	else
		showclips = true
		LocalPlayer():ChatPrint("Showing clip brushes.")
	end
end

for cmd in next, clip_commands do
	concommand.Add(cmd, toggleclips)
end

local trigger_commands = {
	sm_showtriggers = true,
	sm_triggers = true,
	sm_st = true,
}

local function toggletriggers()
	if #showtriggers_triggerMeshes == 0 then
		LocalPlayer():ChatPrint("Generating trigger meshes, please wait...")
		generateTriggerMeshes()
	end

	if showtriggers then
		showtriggers = false
		LocalPlayer():ChatPrint("No longer showing triggers.")
	else
		showtriggers = true
		LocalPlayer():ChatPrint("Showing triggers.")
	end
end

for cmd in next, trigger_commands do
	concommand.Add(cmd, toggletriggers)
end


-- draw the meshes
hook.Add("PostDrawTranslucentRenderables", "showclips", function(depth, skybox, skybox3d)
	if skybox then return end

	if showclips or showtriggers then
		render.SetColorMaterial()

		if showclips then
			for _, obj in ipairs(showclips_clipMeshes) do
				if not obj:IsValid() then continue end
				obj:Draw()
			end
		end

		if showtriggers then
			for _, obj in ipairs(showtriggers_triggerMeshes) do
				if not obj:IsValid() then continue end
				obj:Draw()
			end

			render.SetColorMaterial()
			for _, point in ipairs(point_triggers) do
				local col = classify_trigger(point)
				render.DrawSphere(point.pos, point.radius, 32, 16, ColorAlpha(col, 32))
				render.DrawWireframeSphere(point.pos, point.radius, 32, 16, col, true)
			end
		end
	end
end)

-- i was told to yoink this from oc for offscreen text :^)
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
local COLOR_DEST = Color(255, 128, 0)
local COLOR_INVALID = Color(255, 0, 0)
local COLOR_FILTER = Color(231, 16, 148)

local developer = GetConVar("developer")
local ANGLE_ZERO = Angle()

local filter_cache = {}

hook.Add("HUDPaint", "showtriggers", function()
	if showtriggers and developer:GetBool() then
		local to_render = {}

		local eyepos = LocalPlayer():EyePos()
		local forward = LocalPlayer():EyeAngles():Forward() * 32768

		for _, trigger in ipairs(trigger_info) do
			local hitpos = util.IntersectRayWithOBB(eyepos, forward, trigger.origin, ANGLE_ZERO, trigger.mins, trigger.maxs)
			if hitpos ~= nil then
				to_render[#to_render + 1] = trigger
			end
			trigger.distance = eyepos:Distance(trigger.origin)
		end

		table.sort(to_render, function(a, b)
			return a.distance < b.distance
		end)

		local mindist, nexty = math.huge, -math.huge
		for _, trigger in ipairs(to_render) do
			local center = trigger.origin:ToScreen()

			surface.SetFont("BudgetLabel")

			if trigger.target_pos then
				local targetScr = trigger.target_pos:ToScreen()
				surface.SetDrawColor(255, 128, 0, 255)
				surface.DrawLine(center.x, center.y, targetScr.x, targetScr.y)

				if targetScr.visible then
					local tw = surface.GetTextSize(trigger.target)
					surface.SetTextColor(255, 128, 0, 255)
					surface.SetTextPos(targetScr.x - (tw / 2), targetScr.y)
					surface.DrawText(trigger.target)
				end
			end

			local lines = {}
			addLine(lines, trigger.class, "", COLOR_TEXT, COLOR_TEXT)
			if trigger.disabled then
				addLine(lines, "Starts Disabled", "", COLOR_INVALID, COLOR_INVALID)
			end
			addLine(lines, trigger.name, "Name: ", COLOR_NAME, COLOR_TEXT)
			if trigger.filter then
				local filter = filter_cache[trigger.filter]
				if not filter then
					local ent = MAP:FindByName(trigger.filter)[1]
					if ent then
						filter = trigger.filter
						local badFilter = string.format("<bad filter: %s>", trigger.filter)
						if ent.classname == "filter_activator_class" then
							filter = "By class: " .. (ent.filterclass or badFilter)
						elseif ent.classname == "filter_activator_name" then
							filter = "By name: " .. (ent.filtername or badFilter)
						elseif ent.classname == "filter_activator_team" then
							filter = "By team: " .. ent.filterteam and team.GetName(ent.filterteam) or badFilter
						end
						filter_cache[trigger.filter] = filter
					else
						filter_cache[trigger.filter] = false
						filter = false
					end
				end
				if filter == false then
					addLine(lines, trigger.filter, "Filter: ", COLOR_FILTER, COLOR_INVALID)
				else
					addLine(lines, filter, "Filter: ", COLOR_FILTER, COLOR_TEXT)
				end
			end
			addLine(lines, trigger.target, "Destination: ", COLOR_DEST, trigger.target_invalid and COLOR_INVALID or COLOR_TEXT)

			for on, outputs in next, trigger.outputs do
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
