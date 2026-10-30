if not NikNaks then return end

local TAG = "map in map haha get it"

mim_leaves = mim_leaves or {}
mim_skybox_meshes = mim_skybox_meshes or {}

local function destroy()
	for _, leaf in next, mim_leaves do
		for _, obj in next, leaf.meshes do
			obj:Destroy()
		end
	end
	for _, obj in ipairs(mim_skybox_meshes) do
		obj:Destroy()
	end
end
destroy()

table.Empty(mim_leaves)
table.Empty(mim_skybox_meshes)

collectgarbage()
collectgarbage()

hook.Add("ShutDown", TAG, function()
	destroy()
end)

local MAX_COORD = 16384
local VEC_ZERO = Vector()

mim_leaves[0] = {
	sky = true,
	mins = Vector(-MAX_COORD, -MAX_COORD, -MAX_COORD),
	maxs = Vector(MAX_COORD, MAX_COORD, MAX_COORD),
	meshes = {},
	lights = {},
	verts = {},
}

-- correct(-ish) lighting example when no skybox
--local MAP = NikNaks.Map("oc_stitches_1")
--local OFFSET = Vector(-5120, 2048, 2048) -- in gm_construct

--local MAP = NikNaks.CurrentMap
local MAP = NikNaks.Map("oc_lobby")

-- in gm_construct
--local OFFSET = Vector(-384, 128, 1024)
--local OFFSET = Vector(-2048, 2048, 3072)
--local OFFSET = Vector(0, 0, 3072)
--local OFFSET = Vector(MAX_COORD * 2, 0, 0)

-- in gm_landmass_aurora
--local OFFSET = Vector(0, 0, 4200)
--local OFFSET = Vector(0, 0, 4200 + 2100)
--local OFFSET = Vector(0, 0, MAX_COORD + 4200)

-- in gm_flatgrass
--local OFFSET = Vector(0, 0, -10000)
--local OFFSET = Vector(0, 0, 6384)

-- hacked map gm_wireconstruct_rc_2x/8x
local OFFSET = Vector()

local SCALE_FACTOR = 1

if InfMap then
	SCALE_FACTOR = 1
	OFFSET = Vector()
end

local MAP_MIN = Vector(1, 1, 1)
local MAP_MAX = Vector(1, 1, 1)
MAP_MIN:Mul(MAX_COORD)
MAP_MIN:Mul(-1)
MAP_MAX:Mul(MAX_COORD)

local MAP_LEAVES, NUM_CLUSTERS = MAP:GetLeafs()
local MAP_BMODELS = MAP:GetBModels()

local SKYBOX_POS, SKYBOX_SCALE
local skybox_leaves = {}
local skycam = MAP:FindByClass("^sky_camera$")[1]
if skycam then
	SKYBOX_POS = skycam.origin / SCALE_FACTOR
	SKYBOX_SCALE = skycam.scale
end

local co_resume = coroutine.resume
local co_yield = coroutine.yield
local co_isyieldable = coroutine.isyieldable or function() return false end

local VECTOR = FindMetaTable("Vector")
local V_LengthSqr = VECTOR.LengthSqr
local WithinAABox = VECTOR.WithinAABox

local skip_textures = {
	--["tools/toolsskybox"] = true,
	--["tools/toolsskybox2d"] = true,
}

local fallback_texture = CreateMaterial("mim_fallback", "VertexLitGeneric", {
	["$basetexture"] = "dev/dev_measuregeneric01b"
})

local function split_faces_by_texture(faces, id)
	local texture_faces = {}
	for _, face in ipairs(faces) do
		local tex = face:GetTexture():lower()
		if tex:match("^maps/") then
			local fixed = tex:match("^maps/.-/(.-)_[-0-9]+_[-0-9]+_[-0-9]+$")
			if fixed then
				tex = fixed
			else
				fixed = tex:match("^maps/.-/(.-)_wvt_patch$")
				if fixed then
					tex = fixed
				else
					print("huh?", tex)
				end
			end
		end
		tex = tex:gsub("%.vmt$", "")
		if skip_textures[tex] then continue end

		local m = Material(tex)
		if m:IsError() then
			tex = face.dispinfo ~= -1 and "dev/dev_blendmeasure" or "dev/dev_measuregeneric01b"
		end

		--if face.dispinfo ~= -1 then
		--	displacementTextures[tex] = true
		--end

		if not texture_faces[tex] then texture_faces[tex] = {} end
		local tfaces = texture_faces[tex]
		tfaces[#tfaces + 1] = face
	end
	--co_yield(false)
	co_yield(false, "split all faces in by texture for " .. id)

	return texture_faces
end

local function generate_map_meshes()
	for i, leaf in ipairs(MAP_LEAVES) do
		local faces = leaf:GetFaces(true)
		if #faces < 1 then continue end

		local l = {
			sky = leaf:HasSkyboxInPVS(),
			mins = leaf.mins,
			maxs = leaf.maxs,
			meshes = {},
			lights = {},
			verts = {},
		}
		mim_leaves[i] = l

		local filtered_faces = {}
		for _, face in ipairs(faces) do
			if not face:IsWorld() then continue end

			filtered_faces[#filtered_faces + 1] = face
		end

		local texture_faces = split_faces_by_texture(filtered_faces, "leaf " .. i)

		local builder = NikNaks.MeshBuilder()
		local sky_builder = NikNaks.MeshBuilder()
		for texture, faces in next, texture_faces do
			if texture == "tools/toolsskybox" or texture == "tools/toolsskybox2d" then
				sky_builder:AddFaces(faces, { material = fallback_texture, light = false })
				mim_skybox_meshes[i] = sky_builder:Build()
			else
				local m = texture == "__missing__" and fallback_texture or Material(texture)
				builder:AddFaces(faces, { material = m, light = true })
				mim_leaves[i].meshes[texture] = builder:Build()
			end
			--co_yield(false)
			co_yield(false, "built meshes for " .. texture .. " - leaf: " .. i)
		end
	end
	--co_yield(false, "built meshes for " .. table.Count(mim_leaves) .. " leaves")

	local lods = MAP:FindByClass("func_lod")
	for i, e in ipairs(lods) do
		if not e.model:find("^%*") then continue end

		local bidx = tonumber(e.model:sub(2))

		local bmodel = MAP_BMODELS[bidx]
		if bmodel == nil then continue end

		local faces = bmodel:GetFaces()
		if #faces < 1 then continue end

		local texture_faces = split_faces_by_texture(faces, "func_lod " .. i)

		for texture, tfaces in next, texture_faces do
			local builder = NikNaks.MeshBuilder()

			local m = texture == "__missing__" and fallback_texture or Material(texture)
			builder:AddFaces(tfaces, { material = m, light = true })
			local meshObj = builder:Build()

			local meshes = mim_leaves[0].meshes
			if meshes[texture] ~= nil then
				local origObj = meshes[texture]
				origObj._triangles = origObj._triangles + meshObj._triangles
				table.Add(origObj._meshes, meshObj._meshes)
				table.Add(origObj._lightMeshes, meshObj._lightMeshes)
			else
				meshes[texture] = meshObj
			end

			--co_yield(false)
			co_yield(false, "built meshes for " .. texture .. " - func_lod: " .. i)
		end
	end
	--co_yield(false, "builts " .. #lods .. " meshes for func_lod")
end

local mdlface_meta = {}
mdlface_meta.__index = mdlface_meta
function mdlface_meta:GenerateVertexTriangleData()
	return self._verts
end

function mdlface_meta:GetMaterial()
	if not self._material then
		self._material = Material(self._mesh.material)
	end

	return self._material
end

function mdlface_meta:IsDisplacement()
	return false
end

function mdlface_meta:GenerateLightColors(verts, hdr)
	local colors = self._colors
	if colors == nil then
		colors = {}
		verts = verts or self:GenerateVertexTriangleData()
		if verts then
			for i = 1, #verts do
				local vert = verts[i]
				local r, g, b = 255, 255, 255

				--[[local light = MAP:FindNearestLight(vert.pos, hdr)
				if co_isyieldable then co_yield(false) end
				if light then
					r, g, b = light:GetColor():Unpack()
				end--]]

				colors[i] = { r = r, g = g, b = b }
			end
		end

		self._colors = colors
	end

	return colors
end

local function makeMdlMeshes(prop)
	local meshes = util.GetModelMeshes(prop.PropType, 0, 0, prop.Skin)
	if not meshes then return end

	local out = {}

	local scale = prop.UniformScale or 1

	for i, mesh in ipairs(meshes) do
		local verts = {}

		for vi, vert in ipairs(mesh.triangles) do
			-- why does this fix transforms breaking???
			local newPos = vert.pos * 1
			newPos:Rotate(prop.Angles)
			if scale ~= 1 then
				newPos:Mul(scale)
			end
			if SCALE_FACTOR ~= 1 then
				newPos:Div(SCALE_FACTOR)
			end
			newPos:Add(prop.Origin)

			-- this also fixes transforms breaking???????????
			verts[vi] = {
				normal = vert.normal,
				pos = newPos,
				userdata = vert.userdata,
				tangent = vert.tangent,
				u = vert.u,
				v = vert.v,
				u1 = 0,
				v1 = 0,
				--weights = vert.weights
			}
		end

		local obj = setmetatable({ _mesh = mesh, _verts = verts }, mdlface_meta)
		out[i] = obj

		--co_yield(false, "fake face for " .. prop.PropType .. ": " .. i .. " - " .. mesh.material)
	end

	return out
end

local function bake_static_props()
	local props = MAP:GetStaticProps()
	for i, prop in next, props do
		local meshes = makeMdlMeshes(prop)
		if not meshes then continue end

		local tleaf = MAP:PointInLeaf(0, prop.Origin)
		local li = tleaf and tleaf.__id or 0

		if tleaf and not mim_leaves[li] then
			local l = {
				sky = tleaf:HasSkyboxInPVS(),
				mins = tleaf.mins,
				maxs = tleaf.maxs,
				meshes = {},
				lights = {},
				verts = {},
			}
			mim_leaves[li] = l
		end

		local leaf = mim_leaves[li]

		for _, mesh in ipairs(meshes) do
			local builder = NikNaks.MeshBuilder()

			local texture = mesh._mesh.material
			builder:AddFace(mesh, { material = Material(texture), light = true })
			local meshObj = builder:Build()

			local lm = leaf.meshes
			if lm[texture] ~= nil then
				local origObj = lm[texture]
				origObj._triangles = origObj._triangles + meshObj._triangles
				table.Add(origObj._meshes, meshObj._meshes)
				table.Add(origObj._lightMeshes, meshObj._lightMeshes)
			else
				lm[texture] = meshObj
			end

			--co_yield(false)
			co_yield(false, "baking static props: " .. i .. " - " .. prop.PropType .. " - " .. texture)
		end
	end
	--co_yield(false, "baked " .. table.Count(props) .. " static props")
end

local leaves_pvs = {}
local function calculate_visibility()
	for i = 0, NUM_CLUSTERS do
		local pvsLeaves = {}

		for li in next, mim_leaves do
			if skybox_leaves[li] then continue end

			local leaf = MAP_LEAVES[li]
			if leaf.cluster ~= i then continue end

			pvsLeaves[li] = true
		end

		if next(pvsLeaves) ~= nil then
			leaves_pvs[i] = pvsLeaves
		end

		co_yield(false, "collecting initial clusters: " .. i)
	end

	for pass = 1, 3 do
		for i, pvs in next, leaves_pvs do
			local new_pvs = {}
			local checked_clusters = {}
			for li in next, pvs do
				local leaf = MAP_LEAVES[li]

				local adj = leaf:GetAdjacentLeafs()
				for ai, aleaf in ipairs(adj) do
					if skybox_leaves[ai] then continue end

					local c = aleaf.cluster
					if c == -1 then continue end
					if c == i then continue end
					if checked_clusters[c] then continue end

					if not leaves_pvs[c] then continue end

					for sli in next, leaves_pvs[c] do
						new_pvs[sli] = true
					end
					checked_clusters[c] = true
				end
			end

			for li in next, new_pvs do
				pvs[li] = true
			end
			--co_yield(false)
			co_yield(false, "calculating visibility by cluster: " .. i .. " - pass " .. pass)
		end
		--co_yield(false, "calculating visibility by cluster - pass: " .. pass)
	end
end

local threads = {}
local THREAD_THRESHOLD = 0.01

hook.Add("Think", "mim_threader", function()
	for i, thread in ipairs(threads) do
		local start = SysTime()
		local ok, done, msg
		while SysTime() - start < THREAD_THRESHOLD do
			ok, done, msg = co_resume(thread)

			if not ok then break end
			if done then break end
		end

		if not ok then
			table.remove(threads, i)
			error(done)
		elseif done then
			table.remove(threads, i)
			print("thread " .. i .. " done")
		elseif msg then
			print("thread msg:", i, msg)
		end

		break
	end
end)

local DONE_LOADING = false
table.insert(threads, coroutine.create(function()
	generate_map_meshes()
	bake_static_props()

	if SKYBOX_POS then
		local startleaf = MAP:PointInLeaf(0, SKYBOX_POS * SCALE_FACTOR)
		for _, leaf in next, MAP_LEAVES do
			if leaf.cluster ~= startleaf.cluster then continue end
			skybox_leaves[leaf.__id] = true
		end

		-- FIXME: recurse
		local adj = startleaf:GetAdjacentLeafs(0)
		for _, aleaf in ipairs(adj) do
			local i = aleaf.__id
			local l = mim_leaves[i]
			if not l then continue end
			if next(l.meshes) == nil then continue end

			skybox_leaves[i] = true
		end
	end

	calculate_visibility()

	DONE_LOADING = true

	co_yield(true)
end))

local ANG_ZERO = Angle()
local LEAF_COLOR = Color(0, 0, 255)
local SHOW_LEAVES = false

local SKYBOX_MATRIX = Matrix()
if SKYBOX_POS then
	local s = SKYBOX_SCALE

	local o = Vector()
	o:Set(OFFSET)
	o:Mul(-s)
	o:Add(OFFSET)

	local p = Vector()
	p:Set(SKYBOX_POS)
	p:Mul(-s)
	p:Add(o)

	SKYBOX_MATRIX:Translate(p)
	SKYBOX_MATRIX:Scale(Vector(s, s, s))
end
local NO_HDR = Vector(0.6, 0, 0)

local HAS_HDR = MAP:HasBakedHDRStaticPropLighting()
local RENDER_OPTIONS = {
	depthNudge = 0.999995,
	hdr = HAS_HDR,
	translucent = false,
}
local RENDER_OPTIONS_TRANS = {
	depthNudge = 0.999995,
	hdr = HAS_HDR,
	translucent = true,
	--light = false,
}

local DEFAULT_SKY = "militia_hdr"
local skyname = MAP:FindByClass("^worldspawn$")[1].skyname or DEFAULT_SKY
if not file.Exists("materials/skybox/" .. skyname .. "up.vmt", "GAME") then
	skyname = DEFAULT_SKY
end
if skyname == "painted" then
	skyname = DEFAULT_SKY
end

mim_sky_precache = mim_sky_precache or {}

local function precache_sky(name)
	mim_sky_precache[name] = {
		back = Material("skybox/" .. name .. "bk"),
		front = Material("skybox/" .. name .. "ft"),
		left = Material("skybox/" .. name .. "lf"),
		right = Material("skybox/" .. name .. "rt"),
		up = Material("skybox/" .. name .. "up"),
		down = Material("skybox/" .. name .. "dn")
	}
end
if not mim_sky_precache[skyname] then precache_sky(skyname) end

local draw_skybox
do
	local mappings = {
		back = {
			pos = Vector(0, 1, 0),
			norm = Vector(0, -1, 0)
		},
		front = {
			pos = Vector(0, -1, 0),
			norm = Vector(0, 1, 0)
		},
		left = {
			pos = Vector(-1, 0, 0),
			norm = Vector(1, 0, 0)
		},
		right = {
			pos = Vector(1, 0, 0),
			norm = Vector(-1, 0, 0)
		},
		up = {
			pos = Vector(0, 0, 1),
			norm = Vector(0, 0, -1)
		},
		down = {
			pos = Vector(0, 0, -1),
			norm = Vector(0, 0, 1)
		}
	}

	local VEC_UP = Vector(0, 0, 1)
	local VEC_NORM_DOWN = Vector(0, 0, -1)
	local COLOR_WHITE = Color(255, 255, 255)

	local function draw_skybox_for_stencil()
		render.SuppressEngineLighting(true)
		render.ResetModelLighting(0, 0, 0)
		render.SetLocalModelLights()
		render.SetMaterial(fallback_texture)
		render.OverrideColorWriteEnable(true, false)

		for leaf, meshObj in next, mim_skybox_meshes do
			--if skybox_leaves[leaf] then continue end

			for _, obj in ipairs(meshObj:GetMeshes()) do
				local m = obj.mesh
				if not m or not m:IsValid() then continue end
				m:Draw()
			end
		end
		render.OverrideColorWriteEnable(false, false)
		render.SuppressEngineLighting(false)
	end

	draw_skybox = function()
		local sky = mim_sky_precache[skyname]

		if sky and next(mim_skybox_meshes) ~= nil then
			render.ClearStencil()
			render.SetStencilWriteMask(255)
			render.SetStencilTestMask(255)
			render.SetStencilPassOperation(STENCILOPERATION_KEEP)
			render.SetStencilZFailOperation(STENCILOPERATION_KEEP)

			render.SetStencilEnable(true)

			render.SetStencilReferenceValue(1)
			render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
			render.SetStencilPassOperation(STENCILOPERATION_REPLACE)

			draw_skybox_for_stencil()

			render.SetStencilFailOperation(STENCILOPERATION_KEEP)
			render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)

			render.ClearBuffersObeyStencil(0, 0, 0, 255, true)

			local tone = render.GetToneMappingScaleLinear()
			render.SetToneMappingScaleLinear(NO_HDR)
			render.SuppressEngineLighting(true)
			render.OverrideDepthEnable(true, false)
			render.SetWriteDepthToDestAlpha(false)

			cam.Start3D(VEC_ZERO, EyeAngles())

			for side, mat in next, sky do
				local map = mappings[side]
				local pos = map and map.pos or VEC_UP
				local norm = map and map.norm or VEC_NORM_DOWN

				render.SetMaterial(mat)
				render.DrawQuadEasy(pos * 5120, norm, 10240, 10240, COLOR_WHITE, (side == "up" or side == "down") and 0 or 180)
			end

			cam.End3D()

			render.SetWriteDepthToDestAlpha(true)
			render.OverrideDepthEnable(false, false)
			render.SuppressEngineLighting(false)
			render.SetToneMappingScaleLinear(tone)

			for i in next, skybox_leaves do
				local leaf = mim_leaves[i]
				if not leaf then continue end

				for texture, meshObj in next, leaf.meshes do
					meshObj:DrawOpaque(SKYBOX_MATRIX, RENDER_OPTIONS)
					meshObj:DrawTranslucent(SKYBOX_MATRIX, RENDER_OPTIONS_TRANS)
					--render.RenderFlashlights(function() meshObj:DrawOpaque(SKYBOX_MATRIX, RENDER_OPTIONS) end)
				end
			end

			render.SetStencilEnable(false)
		end
	end
end

local tried_skyinfo = false
local skyinfo
hook.Add("PostDrawOpaqueRenderables", TAG, function(depth, skybox, skybox3d)
	if not DONE_LOADING then return end

	if not tried_skyinfo then
		skyinfo = game.Get3DSkyboxInfo()
		tried_skyinfo = true
	end
	if skyinfo and skybox then return end

	local oldFog = render.GetFogMode()
	render.FogMode(MATERIAL_FOG_NONE)
	--local tone = render.GetToneMappingScaleLinear()
	--render.SetToneMappingScaleLinear(NO_HDR)

	draw_skybox()

	local pos = EyePos() * SCALE_FACTOR

	local cluster = MAP:ClusterFromPoint(pos)
	local hasPvs = cluster > -1
	local pvsLeaves = {}

	if leaves_pvs[cluster] then
		pvsLeaves = leaves_pvs[cluster]
	end
	if next(pvsLeaves) == nil then
		hasPvs = false
	end

	for i, leaf in next, mim_leaves do
		--if skybox_leaves[i] then continue end
		if hasPvs and i > 0 then
			if not pvsLeaves[i] then continue end
		end

		for texture, meshObj in next, leaf.meshes do
			meshObj:DrawOpaque(nil, RENDER_OPTIONS)
			render.RenderFlashlights(function() meshObj:DrawOpaque(nil, RENDER_OPTIONS) end)
		end
	end

	for i, leaf in next, mim_leaves do
		if next(leaf.meshes) == nil then continue end

		if SHOW_LEAVES then
			local mins, maxs = leaf.mins, leaf.maxs
			mins:Div(SCALE_FACTOR)
			maxs:Div(SCALE_FACTOR)

			local center = Vector()
			center:Add(mins)
			center:Add(maxs)
			center:Div(2)
			center:Add(OFFSET)

			render.SuppressEngineLighting(true)
			render.DrawWireframeBox(OFFSET, ANG_ZERO, mins, maxs, LEAF_COLOR, false)
			cam.Start2D()
			surface.SetFont("BudgetLabel")
			local p = center:ToScreen()
			surface.SetTextPos(p.x, p.y)
			surface.SetTextColor(255, 255, 255)
			surface.DrawText("leaf " .. i)
			cam.End2D()
			render.SuppressEngineLighting(false)
		end
	end

	--render.SetToneMappingScaleLinear(tone)
	render.FogMode(oldFog)
end)

hook.Add("PreDrawTranslucentRenderables", TAG, function(depth, skybox, skybox3d)
	if not DONE_LOADING then return end

	if not tried_skyinfo then
		skyinfo = game.Get3DSkyboxInfo()
		tried_skyinfo = true
	end
	if skyinfo and skybox then return end

	local oldFog = render.GetFogMode()
	render.FogMode(MATERIAL_FOG_NONE)
	--local tone = render.GetToneMappingScaleLinear()
	--render.SetToneMappingScaleLinear(NO_HDR)

	local pos = EyePos() * SCALE_FACTOR

	local cluster = MAP:ClusterFromPoint(pos)
	local hasPvs = cluster > -1
	local pvsLeaves = {}

	if leaves_pvs[cluster] then
		pvsLeaves = leaves_pvs[cluster]
	end
	if next(pvsLeaves) == nil then
		hasPvs = false
	end

	for i, leaf in next, mim_leaves do
		--if skybox_leaves[i] then continue end
		if hasPvs and i > 0 then
			if not pvsLeaves[i] then continue end
		end

		for texture, meshObj in next, leaf.meshes do
			meshObj:DrawTranslucent(nil, RENDER_OPTIONS_TRANS)
			render.RenderFlashlights(function() meshObj:DrawTranslucent(nil, RENDER_OPTIONS_TRANS) end)
		end
	end

	--render.SetToneMappingScaleLinear(tone)
	render.FogMode(oldFog)
end)

local inCalcView = false
hook.Add("CalcView", TAG, function(...)
	if inCalcView then return end

	inCalcView = true
	local t = hook.Run("CalcView", ...)
	inCalcView = false

	t.zfar = 9e9

	return t
end)
