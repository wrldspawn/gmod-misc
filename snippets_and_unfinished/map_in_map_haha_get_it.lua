if not NikNaks then return end

local TAG = "map in map haha get it"

mim_meshes = mim_meshes or {}
mim_leaves = mim_leaves or {}
mim_skybox_meshes = mim_skybox_meshes or {}

local function destroy()
	for _, obj in next, mim_meshes do
		if type(obj) == "table" then
			for _, obj2 in next, obj do
				if obj2:IsValid() then obj2:Destroy() end
			end
		else
			if obj:IsValid() then obj:Destroy() end
		end
	end
	for _, leaf in next, mim_leaves do
		for _, obj in next, leaf.meshes do
			if type(obj) == "table" then
				for _, obj2 in next, obj do
					if obj2:IsValid() then obj2:Destroy() end
				end
			else
				if obj:IsValid() then obj:Destroy() end
			end
		end
	end
	for _, obj in ipairs(mim_skybox_meshes) do
		if type(obj) == "table" then
			for _, obj2 in next, obj do
				if obj2:IsValid() then obj2:Destroy() end
			end
		else
			if obj:IsValid() then obj:Destroy() end
		end
	end
end
destroy()

table.Empty(mim_meshes)
table.Empty(mim_leaves)
table.Empty(mim_skybox_meshes)

collectgarbage()
collectgarbage()

hook.Add("ShutDown", TAG, function()
	destroy()
end)

--[[local function calc_lighting(pos, normal)
	local surface = render.ComputeLighting(pos, normal)

	local final = surface * 1
	final.x = math.min(final.x ^ (1 / 2.2), 1)
	final.y = math.min(final.y ^ (1 / 2.2), 1)
	final.z = math.min(final.z ^ (1 / 2.2), 1)
	final = final * 255

	return math.abs(normal.x * 127) + final[1] / 255 * 127,
			math.abs(normal.y * 127) + final[2] / 255 * 127,
			math.abs(normal.z * 127) + final[3] / 255 * 127,
			255
end--]]

local MAX_COORD = 16384

-- correct(-ish) lighting example when no skybox
--local MAP = NikNaks.Map("oc_stitches_1")
--local OFFSET = Vector(-5120, 2048, 2048) -- in gm_construct

--local MAP = NikNaks.CurrentMap
local MAP = NikNaks.Map("gm_construct_m3_401")

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
local OFFSET = Vector(0, 0, -10000)
--local OFFSET = Vector(0, 0, 6384)

local SCALE_FACTOR = 8

if InfMap then
	SCALE_FACTOR = 1
	OFFSET = Vector()
end

local MAP_MIN = Vector(1, 1, 1)
local MAP_MAX = Vector(1, 1, 1)
MAP_MIN:Mul(MAX_COORD)
MAP_MIN:Mul(-1)
MAP_MAX:Mul(MAX_COORD)

local MAP_LEAVES = MAP:GetLeafs()

local SKYBOX_POS, SKYBOX_SCALE
local skybox_leaves = {}
local skycam = MAP:FindByClass("^sky_camera$")[1]
if skycam then
	SKYBOX_POS = skycam.origin / SCALE_FACTOR
	SKYBOX_SCALE = skycam.scale
end

local MAX_TRIANGLES = 21845

local function do_face(pos, vert, vmid)
	mesh.Position(pos)
	mesh.TexCoord(0, vert.u, vert.v)
	mesh.TexCoord(1, vert.u1, vert.v1)
	mesh.Normal(vert.normal)
	if vert.binormal then
		mesh.TangentS(vert.binormal)
	end
	if vert.tangent then
		mesh.TangentT(vert.tangent)
	end
	mesh.UserData(unpack(vert.userdata))
	if vert.color then
		mesh.Specular(vert.color:Unpack())
	end
	--mesh.Color(calc_lighting(pos + (vmid - pos):GetNormalized(), vert.normal))
	mesh.AdvanceVertex()
end

local co_resume = coroutine.resume
local co_yield = coroutine.yield

local VECTOR = FindMetaTable("Vector")
local V_LengthSqr = VECTOR.LengthSqr
local WithinAABox = VECTOR.WithinAABox

local skip_textures = {
	--["tools/toolsskybox"] = true,
	--["tools/toolsskybox2d"] = true,
}
local displacementTextures = {}
local function generate_map_meshes()
	--for i, cluster in next, mim_clusters do
	--local faces = cluster.faces
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

		local texture_verts = {}
		for _, face in ipairs(faces) do
			if not face:IsWorld() then continue end

			local face_vertices = face:GenerateVertexTriangleData()
			if not face_vertices then continue end

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

			if face.dispinfo ~= -1 then
				displacementTextures[tex] = true
			end

			if not texture_verts[tex] then texture_verts[tex] = {} end
			local verts = texture_verts[tex]
			verts[#verts + 1] = face_vertices
		end
		co_yield(false, "split all faces in cluster " .. i .. " by texture")

		for texture, verts in next, texture_verts do
			local imeshes = {}
			--print(i, "BUILD", texture)

			local imesh = Mesh()
			local vertcount = 0
			for _, fv in ipairs(verts) do
				vertcount = vertcount + #fv
			end
			--[[if vertcount > 65535 then
				print("overflow, how", i, texture, vertcount)
			end--]]

			mesh.Begin(imesh, MATERIAL_TRIANGLES, math.min(vertcount / 3, MAX_TRIANGLES))
			for _, fv in ipairs(verts) do
				for v = 1, #fv, 3 do
					local succ, str = pcall(function()
						local v1 = fv[v]
						local v2 = fv[v + 1]
						local v3 = fv[v + 2]

						local pos1 = v1.pos * 1
						local pos2 = v2.pos * 1
						local pos3 = v3.pos * 1

						if SCALE_FACTOR > 1 then
							pos1:Div(SCALE_FACTOR)
							pos2:Div(SCALE_FACTOR)
							pos3:Div(SCALE_FACTOR)
						end

						if InfMap then
							pos1:Set(InfMap.unlocalize_vector(pos1, OFFSET))
							pos2:Set(InfMap.unlocalize_vector(pos2, OFFSET))
							pos3:Set(InfMap.unlocalize_vector(pos3, OFFSET))
						else
							if OFFSET then
								pos1:Add(OFFSET)
								pos2:Add(OFFSET)
								pos3:Add(OFFSET)
							end
						end

						local vmid = (pos1 + pos2 + pos3) / 3

						do_face(pos1, v1, vmid)
						do_face(pos2, v2, vmid)
						do_face(pos3, v3, vmid)

						local lv = mim_leaves[i].verts
						lv[#lv + 1] = v1.pos
						lv[#lv + 1] = v2.pos
						lv[#lv + 1] = v3.pos
						mim_leaves[i].verts = lv
					end)

					if not succ then print(str) end
				end

				if mesh.VertexCount() >= MAX_TRIANGLES then
					local o = 1
					while vertcount > MAX_TRIANGLES do
						--print(i, "BUILD (overflow) " .. o, texture)
						mesh.End()
						table.insert(imeshes, imesh)
						--print(i, "IsValid (overflow) " .. o, texture, imesh:IsValid())

						imesh = Mesh()
						mesh.Begin(imesh, MATERIAL_TRIANGLES, math.min(vertcount - MAX_TRIANGLES, MAX_TRIANGLES))
						vertcount = vertcount - MAX_TRIANGLES
						o = o + 1
						co_yield(false, "mesh overflow " .. (o - 1) .. " for " .. texture .. " - leaf: " .. i)
					end
				end
			end
			mesh.End()
			table.insert(imeshes, imesh)
			--print(i, "IsValid", texture, imesh:IsValid())

			--mim_meshes[texture] = imeshes
			if texture == "tools/toolsskybox" or texture == "tools/toolsskybox2d" then
				mim_skybox_meshes[i] = imeshes
			else
				mim_leaves[i].meshes[texture] = imeshes
			end
			--cluster.meshes[texture] = imeshes
			co_yield(false, "built meshes for " .. texture .. " - leaf: " .. i)
		end
	end
end

local fallback_texture = CreateMaterial("mim_fallback", "VertexLitGeneric", {
	["$basetexture"] = "dev/dev_measuregeneric01b"
})
local water_texture = CreateMaterial("mim_water", "Refract", {
	["$refractamount"] = 0.25,
	["$refracttint"] = "{205 225 255}",
	["$refractblur"] = 1,

	["$model"] = 1,
	["$nowritez"] = 1,

	["$scale"] = "[1 1]",

	["$bumpmap"] = "dev/water_dudv",
	["$normalmap"] = "dev/water_normal",

	["$bumpframe"] = 0,

	Proxies = {
		AnimatedTexture = {
			animatedtexturevar = "$normalmap",
			animatedtextureframenumvar = "$bumpframe",
			animatedtextureframerate = 30,
		},
		TextureScroll = {
			texturescrollvar = "$bumptransform",
			texturescrollrate = 0.1,
			texturescrollangle = 45,
		}
	}
})

local shader_blacklist = {
	LightmappedGeneric = true,
	WorldVertexTransition_DX9 = true,
	Water_DX9_HDR = true,
}

mim_mat_processed = {}
mim_mat_cache = {}
mim_mat_cache_trans = {}

--hook.Add("PreDrawOpaqueRenderables", TAG, function()
local function fix_materials()
	--for i, leaf in next, mim_clusters do
	for i, leaf in next, mim_leaves do
		for texture in next, leaf.meshes do
			if mim_mat_processed[texture] then continue end
			if not mim_mat_cache[texture] and not mim_mat_cache_trans[texture] then
				if not file.Exists("materials/" .. texture .. ".vmt", "GAME") then
					mim_mat_cache[texture] = fallback_texture
					mim_mat_processed[texture] = true
					continue
				end

				local mat = Material(texture)
				local shader = mat:GetShader()
				local is_water = shader == "Water_DX9_HDR"

				if is_water then
					print("water", texture)
					mim_mat_cache_trans[texture] = water_texture
					mim_mat_processed[texture] = true
					continue
				end

				if mat:IsError() then
					mim_mat_cache[texture] = fallback_texture
					mim_mat_processed[texture] = true
					continue
				end

				local vmt = file.Read("materials/" .. texture .. ".vmt", "GAME")
				local kv = {}
				if vmt then
					kv = util.KeyValuesToTable(vmt)
				end

				if not kv then
					mim_mat_cache[texture] = fallback_texture
					mim_mat_processed[texture] = true
				end

				local target = mim_mat_cache
				local trans = false
				local trans_var = "$translucent"
				if is_water or kv["$translucent"] or kv["$alphatest"] or kv["$additive"] then
					target = mim_mat_cache_trans
					trans = true
					if kv["$additive"] then
						trans_var = "$additive"
					end
				end

				if not shader_blacklist[shader] then
					print(texture, shader)
					target[texture] = mat
				else
					--print("blacklisted shader", texture, shader)
					local mat_kv = {
						["$model"] = 1,
						["$basetexture"] = mat:GetString("$basetexture"),
						["$bumpmap"] = mat:GetString("$bumpmap"),
						["$normalmap"] = mat:GetString("$normalmap"),
					}
					if trans then
						mat_kv[trans_var] = 1
					end

					local newShader = "VertexLitGeneric"
					if is_water then
						newShader = "Refract"

						mat_kv["$dudvmap"] = mat:GetString("$dudvmap") or mat:GetString("$bumpmap")
						mat_kv["$refractamount"] = mat:GetFloat("$reflectamount")
						mat_kv["$bumpframe"] = 0
						mat_kv.Proxies = {
							AnimatedTexture = {
								animatedtexturevar = "$normalmap",
								animatedtextureframenumvar = "$bumpframe",
								animatedtextureframerate = 30,
							},
							TextureScroll = {
								texturescrollvar = "$bumptransform",
								texturescrollrate = 0.1,
								texturescrollangle = 45.00,
							}
						}
					end

					target[texture] = CreateMaterial("___mim___/" .. texture, newShader, mat_kv)
					target[texture]:Recompute()
				end

				mim_mat_processed[texture] = true
				co_yield(false, "fixed texture: " .. texture)
			end
		end
		co_yield(false, "textures for leaf " .. i .. " done")
	end
end
--end)

--local LIGHTS = {}
local LIGHT_ENV = MAP:FindByClass("light_environment")[1]
local target_light = Vector(0.5, 0.5, 0.5)
local LIGHT_SKY
local LIGHT_SKY_AMB
local SKY_HAS_AMBIENT = false

local function parseLightString(str)
	local r, g, b, scaler = unpack(string.Split(str, " "))
	r = tonumber(r)
	g = tonumber(g)
	b = tonumber(b)
	scaler = tonumber(scaler)

	if r == nil then r = 255 end
	if g == nil then g = r end
	if b == nil then b = r end
	if scaler == nil then scaler = 200 end

	return r, g, b, scaler
end

local function FLerp5(f1, f2, i1, i2, x)
	return f1 + (f2 - f1) * (x - i1) / (i2 - i1)
end

local function SolveInverseQuadratic(x1, y1, x2, y2, x3, y3, a, b, c)
	local det = (x1 - x2) * (x1 - x3) * (x2 - x3)

	if det == 0 then return false, a, b, c end

	a = (x3 * (-y1 + y2) + x2 * (y1 - y3) + x1 * (-y2 + y3)) / det
	b = (x3 * x3 * (y1 - y2) + x1 * x1 * (y2 - y3) + x2 * x2 * (-y1 + y3)) / det
	c = (x1 * x3 * (-x1 + x3) * y2 + x2 * x2 * (x3 * y1 - x1 * y3) + x2 * (-(x3 * x3 * y1) + x1 * x1 * y3)) / det

	return true, a, b, c
end

local function SolveInverseQuadraticMonotonic(x1, y1, x2, y2, x3, y3, a, b, c)
	local ok

	if x1 > x2 then
		local _x2 = x2
		x2 = x1
		x1 = _x2
		local _y2 = y2
		y2 = y1
		y1 = _y2
	end
	if x2 > x3 then
		local _x3 = x3
		x3 = x2
		x2 = _x3
		local _y3 = y3
		y3 = y2
		y2 = _y3
	end
	if x1 > x2 then
		local _x2 = x2
		x2 = x1
		x1 = _x2
		local _y2 = y2
		y2 = y1
		y1 = _y2
	end

	for blend = 0, 1, 0.05 do
		local tempy2 = (1 - blend) * y2 + blend * FLerp5(y1, y3, x1, x3, x2)
		ok, a, b, c = SolveInverseQuadratic(x1, y1, x2, tempy2, x3, y3, a, b, c)
		if not ok then return false, a, b, c end

		local deriv = 2 * a + b

		if y1 < y2 and y2 < y3 then
			if deriv >= 0 then return true, a, b, c end
		elseif y1 > y2 and y2 > y3 then
			if deriv <= 0 then return true, a, b, c end
		else
			return true, a, b, c
		end
	end

	return true, a, b, c
end

local hasAnySkyLight = SKYBOX_POS == nil
local function process_lights()
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
			if #l.verts < 1 then continue end

			skybox_leaves[i] = true
		end
	end

	if LIGHT_ENV then
		for i in next, skybox_leaves do
			local leaf = mim_leaves[i]

			if leaf and leaf.sky then
				hasAnySkyLight = true
				break
			end
		end

		local r, g, b, scaler = parseLightString(LIGHT_ENV._light)

		local intensity = Vector()
		intensity.x = math.pow(r / 255, 2.2) * 255
		intensity.y = math.pow(g / 255, 2.2) * 255
		intensity.z = math.pow(b / 255, 2.2) * 255

		intensity:Mul(scaler / 255)
		intensity:Div(255)
		intensity:Mul(0.5)

		local ang = Angle()
		ang:Set(LIGHT_ENV.angles)
		if LIGHT_ENV.pitch then
			ang.p = LIGHT_ENV.pitch * -1
		else
			ang.p = -90
		end

		local light = {
			type = MATERIAL_LIGHT_DIRECTIONAL,
			color = intensity,
			pos = OFFSET,
			dir = ang:Forward(),
		}
		target_light:Set(intensity)

		local aintensity = Vector()

		if LIGHT_ENV._ambient then
			local ar, ag, ab, ascaler = parseLightString(LIGHT_ENV._ambient)

			aintensity.x = math.pow(ar / 255, 2.2) * 255
			aintensity.y = math.pow(ag / 255, 2.2) * 255
			aintensity.z = math.pow(ab / 255, 2.2) * 255

			aintensity:Mul(ascaler / 255)
			aintensity:Div(255)
			aintensity:Mul(0.5)
			SKY_HAS_AMBIENT = true
		else
			aintensity:Set(intensity)
			aintensity:Mul(0.5)
		end
		target_light:Set(aintensity)

		local ambient = {
			type = MATERIAL_LIGHT_DIRECTIONAL,
			color = aintensity,
			pos = light.pos,
			dir = light.dir,
		}
		LIGHT_SKY = light
		LIGHT_SKY_AMB = ambient
		--LIGHTS[#LIGHTS + 1] = ambient
		--LIGHTS[#LIGHTS + 1] = light

		for i, leaf in next, mim_leaves do
			if leaf.sky then continue end
			local realLeaf = MAP_LEAVES[i]

			local adj = realLeaf:GetAdjacentLeafs()
			local adjc = 0
			for _, aleaf in ipairs(adj) do
				if aleaf:HasSkyboxInPVS() then
					adjc = adjc + 1
				end
			end

			leaf.sky = adjc / #adj >= 0.3
			co_yield(false, "bias correcting leaves that can see sky - " .. i)
		end
	else
		target_light:Set(vector_origin)
	end
	co_yield(false, "sky lighting done")

	--local FIRST_LIGHT = MAP:FindByClass("light")[1]
	--if FIRST_LIGHT then
	--for li, FIRST_LIGHT in ipairs(ALL_LIGHTS) do
	for li, FIRST_LIGHT in ipairs(MAP:FindByClass("^light")) do
		if FIRST_LIGHT.classname == "light_environment" then continue end
		if FIRST_LIGHT.spawnflags == 1 then continue end -- off by default

		--print(li, FIRST_LIGHT.origin)

		local r, g, b, scaler = parseLightString(FIRST_LIGHT._light)

		local intensity = Vector()
		intensity.x = math.pow(r / 255, 2.2) * 255
		intensity.y = math.pow(g / 255, 2.2) * 255
		intensity.z = math.pow(b / 255, 2.2) * 255

		intensity:Mul(scaler / 255)
		intensity:Div(255)
		intensity:Div(SCALE_FACTOR)

		--[[if not LIGHT_ENV and li == 1 then
			target_light:Set(intensity)
		end--]]

		local isSpot = FIRST_LIGHT.classname == "light_spot"

		local light = {
			type = isSpot and MATERIAL_LIGHT_SPOT or MATERIAL_LIGHT_POINT,
			color = intensity,
			pos = (FIRST_LIGHT.origin / SCALE_FACTOR) + OFFSET,
			dir = isSpot and FIRST_LIGHT.angles:Forward() or nil,
			range = (FIRST_LIGHT._distance or 0) / SCALE_FACTOR,
			angularFalloff = (FIRST_LIGHT._exponent or 5) / SCALE_FACTOR,
			fiftyPercentDistance = FIRST_LIGHT._fifty_percent_distance,
			zeroPercentDistance = FIRST_LIGHT._zero_percent_distance,
			innerAngle = FIRST_LIGHT._inner_cone or 45,
			outerAngle = FIRST_LIGHT._cone or 45,
			_realpos = FIRST_LIGHT.origin,
		}

		if light.fiftyPercentDistance ~= nil then
			if light.fiftyPercentDistance <= 0 or (light.zeroPercentDistance ~= nil and light.zeroPercentDistance <= 0) then
				light.fiftyPercentDistance = nil
				light.zeroPercentDistance = nil
			else
				if light.fiftyPercentDistance == light.zeroPercentDistance then
					light.fiftyPercentDistance = nil
					light.zeroPercentDistance = nil
				else
					if light.fiftyPercentDistance ~= nil then
						light.fiftyPercentDistance = light.fiftyPercentDistance / SCALE_FACTOR
					end
					if light.zeroPercentDistance ~= nil then
						light.zeroPercentDistance = light.zeroPercentDistance / SCALE_FACTOR
					end
				end
			end
		end

		if light.fiftyPercentDistance == nil or light.zeroPercentDistance == nil then
			light.fiftyPercentDistance = nil
			light.zeroPercentDistance = nil
			light.quadraticFalloff = (FIRST_LIGHT._quadratic_attn or 0) / SCALE_FACTOR
			light.linearFalloff = (FIRST_LIGHT._linear_attn or 0) / SCALE_FACTOR
			light.constantFalloff = (FIRST_LIGHT._constant_attn or 1) / SCALE_FACTOR
		end

		local d50 = FIRST_LIGHT._fifty_percent_distance
		local maxDist = -1
		if d50 ~= nil and d50 > 0 then
			local d0 = FIRST_LIGHT._zero_percent_distance or 0
			if d0 <= d50 then
				d0 = 2 * d50
			end
			local x, y, z = 0, 1, 0
			local ok
			ok, x, y, z = SolveInverseQuadraticMonotonic(0, 1, d50, 2, d0, 256, x, y, z)
			if not ok then
				print(li, "can't solve quadratic", d50, d0)
			end

			local v50 = z + d50 * (y + d50 * x)
			local scale = 2 / v50
			y = y * scale
			x = x * scale
			z = z * scale

			if FIRST_LIGHT._hardfalloff then
				maxDist = d0
			else
				if math.abs(x) > 0 then
					local flMax = y / (-2 * x)
					if flMax > 0 then
						maxDist = 10 * flMax
					end
				end
			end
		else
			-- FIXME: find an actual distance cutoff that doesnt rely on 0/50% and doesnt rely on quad/linear/constant falloff
			maxDist = MAX_COORD
		end
		maxDist = maxDist * maxDist

		local pvs = MAP:PVSForOrigin(FIRST_LIGHT.origin)
		for _, _leaf in ipairs(pvs:GetLeafs()) do
			local i = _leaf.__id
			local leaf = mim_leaves[i]
			if not leaf then continue end
			if #leaf.verts < 1 then continue end
			--if leaf.sky and LIGHT_ENV then continue end

			--local center = (leaf.mins + leaf.maxs) / 2
			--local len = V_LengthSqr(light._realpos, center)
			local len = _leaf:DistToSqr(light._realpos)

			--print(li, i, math.sqrt(len), math.sqrt(maxDist))

			if len > maxDist then continue end

			leaf.lights[#leaf.lights + 1] = light
		end

		--local cluster = mim_clusters[li]
		--cluster.lights[#cluster.lights + 1] = light

		--mim_leaves[target_leaf].lights[#mim_leaves[target_leaf].lights + 1] = light
		--LIGHTS[#LIGHTS + 1] = light
		--co_yield(false, "lights for leaf " .. target_leaf .. " done")
	end

	for i, leaf in next, mim_leaves do
		--[[if #leaf.lights > 4 then
			print("leaf " .. i .. " has over 4 lights:", #leaf.lights)
		end--]]

		local realLeaf = MAP_LEAVES[i]

		for _, aleaf in ipairs(realLeaf:GetAdjacentLeafs(0)) do
			local li = aleaf.__id
			local l = mim_leaves[li]
			if not l then continue end
			if #l.lights < 1 then continue end

			for _, light in ipairs(l.lights) do
				leaf.lights[#leaf.lights + 1] = light
			end
		end

		local has = {}
		local newLights = {}
		for _, v in ipairs(leaf.lights) do
			if not has[v] then
				newLights[#newLights + 1] = v
				has[v] = true
			end
		end
		leaf.lights = newLights

		if #leaf.lights < 1 then continue end
		if leaf.sky and LIGHT_ENV and hasAnySkyLight then continue end -- FIXME: hack for winter_lobby_2012 and maybe some other maps idk

		--local center = (leaf.mins + leaf.maxs) / 2
		table.sort(leaf.lights, function(a, b)
			--return V_LengthSqr(a._realpos, center) < V_LengthSqr(b._realpos, center)
			local da = realLeaf:DistToSqr(a._realpos)
			local db = realLeaf:DistToSqr(b._realpos)
			return da < db
		end)

		--[[for l = 1, math.min(#leaf.lights, 4) do
			local p = leaf.lights[l]._realpos
			print(i, "light", l, p, math.sqrt(V_LengthSqr(p, center)))
		end--]]
		co_yield(false, "sorting lights - " .. i)
	end

	--[[for i, cluster in next, mim_clusters do
		if #cluster.lights > 4 then
			print("cluster " .. i .. " has over 4 lights:", #cluster.lights)
		end
	end--]]

	co_yield(false, "lights done")
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
		else
			print("thread msg:", i, msg)
		end

		break
	end
end)

table.insert(threads, coroutine.create(function()
	generate_map_meshes()
	fix_materials()
	process_lights()
	co_yield(true)
end))

local ambientColors = {}
local function draw_meshes(target, skybox)
	if skybox == nil then skybox = false end

	render.SuppressEngineLighting(true)

	--for i, leaf in next, mim_clusters do
	for i, leaf in next, mim_leaves do
		if not skybox and skybox_leaves[i] then continue end
		if skybox and not skybox_leaves[i] then continue end

		local realLeaf = MAP_LEAVES[i]

		local ambCol = ambientColors[i]
		if not ambCol then
			local center = (leaf.mins + leaf.maxs) / 2
			ambCol = realLeaf:CalculateAmbientColor(center, render.GetHDREnabled() and MAP:HasBakedHDRStaticPropLighting())
			ambientColors[i] = ambCol
		end
		render.ResetModelLighting(ambCol.r / 255, ambCol.g / 255, ambCol.b / 255)

		--print("rendering leaf", i)
		if ambCol.r == 0 and ambCol.g == 0 and ambCol.b == 0 and leaf.sky and LIGHT_ENV and hasAnySkyLight then
			if SKY_HAS_AMBIENT then
				render.ResetModelLighting(LIGHT_SKY_AMB.color:Unpack())
			else
				render.ResetModelLighting(target_light:Unpack())
			end
		end

		if leaf.sky and LIGHT_ENV and hasAnySkyLight then
			render.SetLocalModelLights({
				LIGHT_SKY,
				LIGHT_SKY_AMB,
				leaf.lights[1],
				leaf.lights[2],
			})
		else
			render.SetLocalModelLights(leaf.lights)
		end
		--render.SetModelLighting(BOX_FRONT, 1, 1, 1)
		--render.SetModelLighting(BOX_LEFT, 1, 0, 0)
		--render.SetModelLighting(BOX_RIGHT, 0, 1, 0)
		--render.SetModelLighting(BOX_TOP, 0, 0, 1)

		for texture, meshes in next, leaf.meshes do
			if not target[texture] then continue end
			if #meshes < 1 then continue end

			for _, obj in ipairs(meshes) do
				if not obj:IsValid() then continue end
				render.SetMaterial(target[texture])
				obj:Draw()
				render.RenderFlashlights(function() obj:Draw() end)
			end
		end
	end

	render.SuppressEngineLighting(false)
end

local function draw_meshes_for_stencil(target, skybox)
	if skybox == nil then skybox = false end

	render.SuppressEngineLighting(true)
	render.ResetModelLighting(0, 0, 0)
	render.SetLocalModelLights()
	render.SetMaterial(fallback_texture)
	render.OverrideColorWriteEnable(true, false)
	for i, leaf in next, mim_leaves do
		if not skybox and skybox_leaves[i] then continue end
		if skybox and not skybox_leaves[i] then continue end

		for texture, meshes in next, leaf.meshes do
			if not target[texture] then continue end
			if #meshes < 1 then continue end

			for _, obj in ipairs(meshes) do
				if not obj:IsValid() then continue end
				obj:Draw()
			end
		end
	end
	render.OverrideColorWriteEnable(false, false)
	render.SuppressEngineLighting(false)
end

local ANG_ZERO = Angle()
local LEAF_COLOR = Color(0, 0, 255)
local SHOW_LEAVES = false
local SHOW_LIGHTS = false
local DEBUG_MAXS = Vector(16, 16, 16)
local DEBUG_MINS = DEBUG_MAXS * -1

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

local function draw_world(target)
	-- skybox carving
	-- FIXME: doesn't work on flatgrass and construct
	-- FIXME: bad zindexing (flashlight fixes it???)
	if SKYBOX_POS then
		render.ClearStencil()
		render.SetStencilWriteMask(255)
		render.SetStencilTestMask(255)
		render.SetStencilPassOperation(STENCILOPERATION_KEEP)
		render.SetStencilZFailOperation(STENCILOPERATION_KEEP)

		render.SetStencilEnable(true)

		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
		render.SetStencilPassOperation(STENCILOPERATION_REPLACE)

		draw_meshes_for_stencil(target)

		render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
		render.SetStencilPassOperation(STENCILOPERATION_ZERO)
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)

		render.ClearBuffersObeyStencil(0, 0, 0, 255, true)

		cam.PushModelMatrix(SKYBOX_MATRIX, true)
		draw_meshes(target, true)
		cam.PopModelMatrix()

		render.SetStencilEnable(false)
	end

	draw_meshes(target)
end

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

	local VEC_ZERO = Vector()
	local VEC_UP = Vector(0, 0, 1)
	local VEC_NORM_DOWN = Vector(0, 0, -1)
	local COLOR_WHITE = Color(255, 255, 255)

	local function draw_skybox_for_stencil()
		render.SuppressEngineLighting(true)
		render.ResetModelLighting(0, 0, 0)
		render.SetLocalModelLights()
		render.SetMaterial(fallback_texture)
		render.OverrideColorWriteEnable(true, false)

		for leaf, meshes in next, mim_skybox_meshes do
			local leaf3d = skybox_leaves[leaf]

			if leaf3d then
				cam.PushModelMatrix(SKYBOX_MATRIX, true)
			end

			for _, obj in ipairs(meshes) do
				if not obj:IsValid() then continue end
				obj:Draw()
			end

			if leaf3d then
				cam.PopModelMatrix()
			end
		end
		render.OverrideColorWriteEnable(false, false)
		render.SuppressEngineLighting(false)
	end

	draw_skybox = function()
		local sky = mim_sky_precache[skyname]

		if sky then
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

			render.SetStencilEnable(false)
		end
	end
end


hook.Add("PostDrawOpaqueRenderables", TAG, function(depth, skybox, skybox3d)
	if skybox then return end

	local oldFog = render.GetFogMode()
	render.FogMode(MATERIAL_FOG_NONE)
	local tone = render.GetToneMappingScaleLinear()
	render.SetToneMappingScaleLinear(NO_HDR)

	draw_skybox()

	draw_world(mim_mat_cache)

	for i, leaf in next, mim_leaves do
		if #leaf.verts < 1 then continue end

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

		if SHOW_LIGHTS then
			local center = (leaf.mins + leaf.maxs) / 2
			for l = 1, math.min(#leaf.lights, 4) do
				local light = leaf.lights[l]
				render.DrawLine(light.pos, center + OFFSET, LEAF_COLOR)
				render.DrawWireframeBox(light.pos, ANG_ZERO, DEBUG_MINS, DEBUG_MAXS)
			end
		end
	end

	render.SetToneMappingScaleLinear(tone)
	render.FogMode(oldFog)
end)

hook.Add("PreDrawTranslucentRenderables", TAG, function(depth, skybox, skybox3d)
	if skybox then return end

	local oldFog = render.GetFogMode()
	render.FogMode(MATERIAL_FOG_NONE)
	local tone = render.GetToneMappingScaleLinear()
	render.SetToneMappingScaleLinear(NO_HDR)

	-- TODO: transparent skybox carving
	-- dont know how to make a stencil render whats behind it normally

	cam.PushModelMatrix(SKYBOX_MATRIX, true)
	draw_meshes(mim_mat_cache_trans, true)
	cam.PopModelMatrix()

	draw_meshes(mim_mat_cache_trans)

	render.SetToneMappingScaleLinear(tone)
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
