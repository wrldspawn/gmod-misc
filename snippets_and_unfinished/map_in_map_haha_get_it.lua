if not NikNaks then return end

local TAG = "map in map haha get it"

mim_meshes = mim_meshes or {}
mim_leaves = mim_leaves or {}

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

	collectgarbage()
	collectgarbage()
end
destroy()

table.Empty(mim_meshes)
table.Empty(mim_leaves)

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

local skip_textures = {
	["tools/toolsskybox"] = true,
	["tools/toolsskybox2d"] = true,
}

--local MAP = NikNaks.Map("oc_stitches_1")
--local OFFSET = Vector(-5120, 2048, 2048)
--local SCALE_FACTOR = 1

--local MAP = NikNaks.CurrentMap
local MAP = NikNaks.Map("pl_upward")
local OFFSET = Vector(-384, 128, 1024)
local SCALE_FACTOR = 1

local MAX_COORD = 16384
local MAP_MIN = Vector(1, 1, 1)
local MAP_MAX = Vector(1, 1, 1)
MAP_MIN:Mul(MAX_COORD)
MAP_MIN:Mul(-1)
MAP_MAX:Mul(MAX_COORD)

mim_leaves[0] = {
	sky = MAP:HasSkyBox(),
	mins = MAP_MIN,
	maxs = MAP_MAX,
	meshes = {},
	lights = {},
	verts = {},
}

local MAX_TRIANGLES = 21845

--[[if InfMap then
	SCALE_FACTOR = 1
	OFFSET = false
end--]]

local function do_face(pos, vert, vmid)
	mesh.Position(pos)
	mesh.TexCoord(0, vert.u, vert.v)
	mesh.TexCoord(1, vert.u1, vert.v1)
	mesh.Normal(vert.normal)
	local tx = vert.tangent and vert.tangent.x or 0
	local ty = vert.tangent and vert.tangent.y or 0
	local tz = vert.tangent and vert.tangent.z or 0
	mesh.UserData(tx, ty, tz, 0)
	mesh.Specular(1, 1, 1, 1)
	--mesh.Color(calc_lighting(pos + (vmid - pos):GetNormalized(), vert.normal))
	mesh.AdvanceVertex()
end

local co_resume = coroutine.resume
local co_yield = coroutine.yield

local VECTOR = FindMetaTable("Vector")
local V_LengthSqr = VECTOR.LengthSqr
local WithinAABox = VECTOR.WithinAABox

local function generate_map_meshes()
	for i, leaf in ipairs(MAP:GetLeafs()) do
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
					if fixed then tex = fixed end
				end
			end
			tex = tex:gsub("%.vmt$", "")
			if skip_textures[tex] then continue end

			if not texture_verts[tex] then texture_verts[tex] = {} end
			local verts = texture_verts[tex]
			verts[#verts + 1] = face_vertices
		end
		co_yield(false, "split all faces in leaf " .. i .. " by texture")

		for texture, verts in next, texture_verts do
			local imeshes = {}
			print(i, "BUILD", texture)

			local imesh = Mesh()
			local vertcount = 0
			for _, fv in ipairs(verts) do
				vertcount = vertcount + #fv
			end
			if vertcount > 65535 then
				print("overflow, how", i, texture, vertcount)
			end

			mesh.Begin(imesh, MATERIAL_TRIANGLES, vertcount / 3)
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

						--[[if InfMap then
							pos1:Set(InfMap.unlocalize_vector(pos1, OFFSET))
							pos2:Set(InfMap.unlocalize_vector(pos2, OFFSET))
							pos3:Set(InfMap.unlocalize_vector(pos3, OFFSET))
						else--]]
						if OFFSET then
							pos1:Add(OFFSET)
							pos2:Add(OFFSET)
							pos3:Add(OFFSET)
						end
						--end

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

				--[[if mesh.VertexCount() >= MAX_TRIANGLES then
					print(i, "BUILD (overflow)", texture)
					mesh.End()
					table.insert(imeshes, imesh)
					print(i, "IsValid (overflow)", texture, imesh:IsValid())

					imesh = Mesh()
					mesh.Begin(imesh, MATERIAL_TRIANGLES, MAX_TRIANGLES)
				end--]]
			end
			mesh.End()
			table.insert(imeshes, imesh)
			print(i, "IsValid", texture, imesh:IsValid())

			--mim_meshes[texture] = imeshes
			mim_leaves[i].meshes[texture] = imeshes
			co_yield(false, "built meshes for " .. texture .. " - leaf: " .. i)
		end
	end
end

--[[local map_unlit = CreateMaterial("map_unlit", "UnlitGeneric", {
	["$basetexture"] = "lights/white",
	["$vertexcolor"] = 1,
})

local map_lit = CreateMaterial("map_lit", "VertexLitGeneric", {
	["$basetexture"] = map_unlit:GetString("$basetexture")
})--]]

local fallback_texture = CreateMaterial("mim_fallback", "VertexLitGeneric", {
	["$basetexture"] = "dev/dev_measuregeneric01b"
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
					local mat_kv = {
						["$model"] = 1,
						["$basetexture"] = mat:GetString("$basetexture"),
						["$bumpmap"] = mat:GetString("$bumpmap"),
						["$normalmap"] = mat:GetString("$normalmap"),
					}
					if trans then
						mat_kv[trans_var] = 1
					end

					if is_water then
						mat_kv["$dudvmap"] = mat:GetString("$dudvmap") or mat:GetString("$bumpmap")
						mat_kv["$refractamount"] = mat:GetFloat("$reflectamount")
						mat_kv["$bumpframe"] = 0
						mat_kv.Proxies = {
							AnimatedTexture = {
								animatedtexturevar = "$normalmap",
								animatedtextureframenumvar = "$bumpframe",
								animatedtextureframerate = 30,
							}
						}
					end

					target[texture] = CreateMaterial("___mim___/" .. texture, is_water and "Refract" or "VertexLitGeneric", mat_kv)
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

local function get_lights()
	if LIGHT_ENV then
		local r, g, b, scaler = parseLightString(LIGHT_ENV._light)

		local intensity = Vector()
		intensity.x = math.pow(r / 255, 2.2) * 255
		intensity.y = math.pow(g / 255, 2.2) * 255
		intensity.z = math.pow(b / 255, 2.2) * 255

		intensity:Mul(scaler / 255)
		intensity:Div(255)

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
			target_light:Set(aintensity)
			SKY_HAS_AMBIENT = true
		else
			aintensity:Set(intensity)
			aintensity:Mul(0.5)
		end

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
	else
		target_light:Set(vector_origin)
	end
	co_yield(false, "sky lighting done")

	--local FIRST_LIGHT = MAP:FindByClass("light")[1]
	--if FIRST_LIGHT then
	for li, FIRST_LIGHT in ipairs(MAP:FindByClass("^light")) do
		if FIRST_LIGHT.classname == "light_environment" then continue end

		print(li, FIRST_LIGHT.origin)

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
		}

		if light.fiftyPercentDistance ~= nil then
			if light.fiftyPercentDistance <= 0 or light.zeroPercentDistance <= 0 then
				light.fiftyPercentDistance = nil
				light.zeroPercentDistance = nil
			else
				light.fiftyPercentDistance = light.fiftyPercentDistance / SCALE_FACTOR
				light.zeroPercentDistance = light.zeroPercentDistance / SCALE_FACTOR
			end
		end

		if light.fiftyPercentDistance == nil and light.zeroPercentDistance == nil then
			light.quadraticFalloff = (FIRST_LIGHT._quadratic_attn or 0) / SCALE_FACTOR
			light.linearFalloff = (FIRST_LIGHT._linear_attn or 0) / SCALE_FACTOR
			light.constantFalloff = (FIRST_LIGHT._constant_attn or 1) / SCALE_FACTOR
		end

		local pvs = MAP:PVSForOrigin(FIRST_LIGHT.origin)
		for _, _leaf in ipairs(pvs:GetLeafs()) do
			local i = _leaf.__id
			local leaf = mim_leaves[i]
			if not leaf then continue end
			if #leaf.verts < 1 then continue end

			leaf.lights[#leaf.lights + 1] = light
		end

		--mim_leaves[target_leaf].lights[#mim_leaves[target_leaf].lights + 1] = light
		--LIGHTS[#LIGHTS + 1] = light
		--co_yield(false, "lights for leaf " .. target_leaf .. " done")
	end

	for i, leaf in next, mim_leaves do
		if #leaf.lights > 4 then
			print("leaf " .. i .. " has over 4 lights:", #leaf.lights)
		end
	end

	co_yield(false, "lights done")
end

local threads = {}
local THREAD_THRESHOLD = 0.03

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
	get_lights()
	co_yield(true)
end))

local function draw_meshes(target)
	render.SuppressEngineLighting(true)

	for i, leaf in next, mim_leaves do
		--print("rendering leaf", i)
		if leaf.sky then
			if SKY_HAS_AMBIENT then
				render.ResetModelLighting(LIGHT_SKY_AMB.color:Unpack())
			else
				render.ResetModelLighting(target_light:Unpack())
			end
			render.SetLocalModelLights({
				LIGHT_SKY,
				LIGHT_SKY_AMB,
				leaf.lights[1],
				leaf.lights[2],
			})
		else
			render.ResetModelLighting(0, 0, 0)
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

local ANG_ZERO = Angle()
local LEAF_COLOR = Color(0, 0, 255)
local SHOW_LEAVES = true
hook.Add("PostDrawOpaqueRenderables", TAG, function(depth, skybox, skybox3d)
	if skybox then return end

	draw_meshes(mim_mat_cache)

	if SHOW_LEAVES then
		for i, leaf in next, mim_leaves do
			if #leaf.verts < 1 then continue end

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
end)

hook.Add("PreDrawTranslucentRenderables", TAG, function(depth, skybox, skybox3d)
	if skybox then return end

	draw_meshes(mim_mat_cache_trans)
end)
