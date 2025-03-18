if not NikNaks then require("niknaks") end

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

local brushes = {}
for _, brush in ipairs(NikNaks.CurrentMap:GetBrushes()) do
	local invis = true
	for i = 1, brush.numsides do
		local tex = brush:GetTexture(i)
		if tex:lower() ~= "tools/toolsinvisible" then
			invis = false
			break
		end
	end

	if invis == false and not (brush:HasContents(CONTENTS_PLAYERCLIP) or brush:HasContents(CONTENTS_MONSTERCLIP)) then continue end

	brushes[#brushes + 1] = brush
end

-- this implementation is not perfect but it at least works
-- (theres a weird ring on surf_adrift_fix)
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

	clipBrushes[#clipBrushes + 1] = brush_verts
end

-- triggers
local triggerBrushes = {}
local bmodels = NikNaks.CurrentMap:GetBModels()
for _, trigger in ipairs(NikNaks.CurrentMap:FindByClass("^trigger_*")) do
	if not trigger.model then
		print("wtf")
		PrintTable(trigger)
		continue
	end
	local model = tonumber(trigger.model:sub(2))
	if not model then
		print("wtf", trigger.model)
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
end

-- hotreload
showclips_clipMeshes = showclips_clipMeshes or {}

for _, obj in ipairs(showclips_clipMeshes) do
	if obj:IsValid() then obj:Destroy() end
end

table.Empty(showclips_clipMeshes)


-- draw translucent triangles for every face
for _, brush in ipairs(clipBrushes) do
	local obj = Mesh()
	local contents = brush.contents
	local r = 255
	local g = 0
	local b = 255
	if bit.band(contents, CONTENTS_MONSTERCLIP) ~= 0 and bit.band(contents, CONTENTS_PLAYERCLIP) == 0 then
		r = 128
	end
	if bit.band(contents, CONTENTS_MONSTERCLIP) ~= 0 and bit.band(contents, CONTENTS_PLAYERCLIP) ~= 0 then
		b = 0
	end
	if bit.band(contents, CONTENTS_TRANSLUCENT) ~= 0 then
		g = 255
	end

	local vertCount = 0
	for _, side in ipairs(brush) do
		vertCount = vertCount + #side
	end

	mesh.Begin(obj, MATERIAL_TRIANGLES, vertCount / 3)
	for _, side in ipairs(brush) do
		for _, vert in ipairs(side) do
			mesh.Color(r, g, b, 32)
			mesh.Position(vert)
			mesh.AdvanceVertex()
		end
	end
	mesh.End()

	showclips_clipMeshes[#showclips_clipMeshes + 1] = obj
end

-- outline
for _, brush in ipairs(clipBrushes) do
	local obj = Mesh()
	local contents = brush.contents
	local r = 255
	local g = 0
	local b = 255
	if bit.band(contents, CONTENTS_MONSTERCLIP) ~= 0 and bit.band(contents, CONTENTS_PLAYERCLIP) == 0 then
		r = 128
	end
	if bit.band(contents, CONTENTS_MONSTERCLIP) ~= 0 and bit.band(contents, CONTENTS_PLAYERCLIP) ~= 0 then
		b = 0
	end
	if bit.band(contents, CONTENTS_TRANSLUCENT) ~= 0 then
		g = 255
	end

	local vertCount = 0
	local newBrush = {}

	for _, side in ipairs(brush) do
		newBrush[#newBrush + 1] = dedupe(side)
	end

	for _, side in ipairs(newBrush) do
		vertCount = vertCount + #side
	end

	mesh.Begin(obj, MATERIAL_LINES, vertCount)
	for i, side in ipairs(newBrush) do
		--local col = cols[(i - 1) % #cols]
		for j, vert in ipairs(side) do
			--mesh.Color(col[1], col[2], col[3], 255)
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
	[TYPE_UNKNOWN] = Color(255, 128, 0),
	[TYPE_MULTIPLE] = Color(0, 255, 0),
	[TYPE_ANTIPRE] = Color(192, 255, 0),
	[TYPE_SPEED] = Color(255, 255, 0),
	[TYPE_TELEPORT] = Color(0, 128, 255),
	[TYPE_ONCE] = Color(255, 96, 0),
	[TYPE_OC] = Color(0, 255, 255),
	[TYPE_HURT] = Color(255, 0, 0),
}

local function classify_trigger(brush)
	local classname = brush.classname
	local type = TYPE_UNKNOWN

	if classname == "trigger_multiple" then
		type = TYPE_MULTIPLE

		if brush.outputs.OnStartTouch then
			for _, data in ipairs(brush.outputs.OnStartTouch) do
				if data:find("gravity 40") then -- Gravity anti-prespeed https://gamebanana.com/prefabs/6760.
					type = TYPE_ANTIPRE
					break
				elseif data:find("basevelocity") then -- some surf map boosters (e.g. surf_quirky)
					type = TYPE_SPEED
					break
				end
			end
		end

		if brush.outputs.OnEndTouch then
			for _, data in ipairs(brush.outputs.OnEndTouch) do
				if
						data:find("gravity -") -- Gravity booster https://gamebanana.com/prefabs/6677.
						or
						data:find("basevelocity") -- Basevelocity booster https://gamebanana.com/prefabs/7118.
				then
					type = TYPE_SPEED
					break
				end
			end
		end
	elseif classname == "trigger_push" then
		type = TYPE_SPEED
	elseif classname == "trigger_teleport" then
		type = TYPE_TELEPORT
	elseif classname == "trigger_once" then
		type = TYPE_ONCE
	elseif classname == "trigger_hurt" then
		type = TYPE_HURT
	elseif classname:find("_oc$") then
		type = TYPE_OC
	end

	return TRIGGER_COLORS[type]
end

for _, brush in ipairs(triggerBrushes) do
	local obj = Mesh()

	local col = classify_trigger(brush)

	local vertCount = 0
	for _, side in ipairs(brush) do
		vertCount = vertCount + #side
	end

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
end

-- outline
for _, brush in ipairs(triggerBrushes) do
	local obj = Mesh()

	local col = classify_trigger(brush)

	local vertCount = 0
	local newBrush = {}

	for _, side in ipairs(brush) do
		newBrush[#newBrush + 1] = dedupe(side)
	end

	for _, side in ipairs(newBrush) do
		vertCount = vertCount + #side
	end

	mesh.Begin(obj, MATERIAL_LINES, vertCount)
	for i, side in ipairs(newBrush) do
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
		end
	end
end)
