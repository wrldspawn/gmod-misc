if not NikNaks then require("niknaks") end

-- functions translated to niknaks from https://github.com/h3xcat/gmod-luabsp/blob/master/luabsp.lua

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

	return dedupe(verts)
end

local brushes = {}
for _, brush in ipairs(NikNaks.CurrentMap:GetBrushes()) do
	if not (brush:HasContents(CONTENTS_PLAYERCLIP) or brush:HasContents(CONTENTS_MONSTERCLIP)) then continue end

	brushes[#brushes + 1] = brush
end

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

-- this is where the original code ends and my mess of oddly specific rendering begins

-- hotreload
showclips_clipMeshes = showclips_clipMeshes or {}

for _, obj in ipairs(showclips_clipMeshes) do
	if obj:IsValid() then obj:Destroy() end
end

table.Empty(showclips_clipMeshes)

-- debug colors
local cols = {
	{ 255, 128, 0 },
	{ 255, 255, 0 },
	{ 128, 255, 0 },
	{ 0,   255, 0 },
	{ 0,   255, 128 },
	{ 0,   255, 255 },
	{ 0,   128, 255 },
	{ 0,   0,   255 },
	{ 128, 0,   255 },
	{ 255, 0,   255 },
	{ 255, 0,   128 },
}
cols[0] = { 255, 0, 0 }

-- draw translucent triangles for every face
for _, brush in ipairs(clipBrushes) do
	local obj = Mesh()
	local contents = brush.contents
	local r = 255
	local b = 255
	if bit.band(contents, CONTENTS_MONSTERCLIP) ~= 0 and bit.band(contents, CONTENTS_PLAYERCLIP) == 0 then
		r = 128
	end
	if bit.band(contents, CONTENTS_MONSTERCLIP) ~= 0 and bit.band(contents, CONTENTS_PLAYERCLIP) ~= 0 then
		b = 0
	end

	local vertCount = 0
	for _, side in ipairs(brush) do
		vertCount = vertCount + #side
	end

	mesh.Begin(obj, MATERIAL_TRIANGLES, vertCount / 3)
	for _, side in ipairs(brush) do
		for i, vert in ipairs(side) do
			--local col = cols[i - 1 % #cols]
			--mesh.Color(col[1], col[2], col[3], 32)
			mesh.Color(r, 0, b, 32)
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
	local b = 255
	if bit.band(contents, CONTENTS_MONSTERCLIP) ~= 0 and bit.band(contents, CONTENTS_PLAYERCLIP) == 0 then
		r = 128
	end
	if bit.band(contents, CONTENTS_MONSTERCLIP) ~= 0 and bit.band(contents, CONTENTS_PLAYERCLIP) ~= 0 then
		b = 0
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
			mesh.Color(r, 0, b, 255)
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

-- draw the meshes
hook.Add("PostDrawTranslucentRenderables", "showclips", function(depth, skybox, skybox3d)
	if skybox then return end

	render.SetColorMaterial()
	for _, obj in ipairs(showclips_clipMeshes) do
		if not obj:IsValid() then continue end
		obj:Draw()
	end
end)
