if not NikNaks then return end

local TAG = "map in map haha get it"

mim_meshes = mim_meshes or {}

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
end
destroy()

table.Empty(mim_meshes)

hook.Add("ShutDown", TAG, function()
	destroy()
end)

local function calc_lighting(pos, normal)
	local surface = render.GetLightColor(pos + normal)

	local final = (surface)
	final[1] = math.min(final[1] ^ (1 / 2.2), 1)
	final[2] = math.min(final[2] ^ (1 / 2.2), 1)
	final[3] = math.min(final[3] ^ (1 / 2.2), 1)
	final = final * 255

	return math.abs(normal.x * 127) + final[1] / 255 * 127,
			math.abs(normal.y * 127) + final[2] / 255 * 127,
			math.abs(normal.z * 127) + final[3] / 255 * 127,
			255
end

local skip_textures = {
	["tools/toolsskybox"] = true,
	["tools/toolsskybox2d"] = true,
}

--local MAP = NikNaks.CurrentMap
local MAP = NikNaks.Map("gm_construct")

local MAX_TRIANGLES = 10922
local OFFSET = Vector(-384, 128, 1024)
local SCALE_FACTOR = 16

local function generate_map_meshes()
	local function do_face(pos, vert, vmid)
		mesh.Position(pos)
		mesh.TexCoord(0, vert.u, vert.v)
		mesh.TexCoord(1, vert.u1, vert.v1)
		mesh.Normal(vert.normal)
		local tx = vert.tangent and vert.tangent.x or 0
		local ty = vert.tangent and vert.tangent.y or 0
		local tz = vert.tangent and vert.tangent.z or 0
		mesh.UserData(tx, ty, tz, 0)
		mesh.Color(calc_lighting(pos + (vmid - pos):GetNormalized(), vert.normal))
		mesh.AdvanceVertex()
	end

	local texture_verts = {}
	for _, face in ipairs(MAP:GetFaces(true)) do
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

	for texture, verts in next, texture_verts do
		local imeshes = {}
		local imesh = Mesh()
		mesh.Begin(imesh, MATERIAL_TRIANGLES, MAX_TRIANGLES)
		for _, face_vertices in ipairs(verts) do
			for v = 1, #face_vertices, 3 do
				local succ, str = pcall(function()
					local v1 = face_vertices[v]
					local v2 = face_vertices[v + 1]
					local v3 = face_vertices[v + 2]

					local pos1 = v1.pos * 1
					local pos2 = v2.pos * 1
					local pos3 = v3.pos * 1

					pos1:Div(SCALE_FACTOR)
					pos2:Div(SCALE_FACTOR)
					pos3:Div(SCALE_FACTOR)

					pos1:Add(OFFSET)
					pos2:Add(OFFSET)
					pos3:Add(OFFSET)

					local vmid = (pos1 + pos2 + pos3) / 3

					do_face(pos1, v1, vmid)
					do_face(pos2, v2, vmid)
					do_face(pos3, v3, vmid)
				end)

				if not succ then print(str) end
			end

			if mesh.VertexCount() >= MAX_TRIANGLES then
				mesh.End()
				table.insert(imeshes, imesh)

				imesh = Mesh()
				mesh.Begin(imesh, MATERIAL_TRIANGLES, MAX_TRIANGLES)
			end
		end
		mesh.End()
		table.insert(imeshes, imesh)

		mim_meshes[texture] = imeshes
	end
end

generate_map_meshes()

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

mim_mat_cache = {}
mim_mat_cache_trans = {}

hook.Add("PreDrawOpaqueRenderables", TAG, function()
	for texture in next, mim_meshes do
		if not mim_mat_cache[texture] and not mim_mat_cache_trans[texture] then
			local mat = Material(texture)
			local shader = mat:GetShader()
			local is_water = shader == "Water_DX9_HDR"

			if mat:IsError() then
				mim_mat_cache[texture] = fallback_texture
				continue
			end

			local vmt = file.Read("materials/" .. texture .. ".vmt", "GAME")
			local kv = {}
			if vmt then
				kv = util.KeyValuesToTable(vmt)
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
		end
	end
end)


hook.Add("PostDrawOpaqueRenderables", TAG, function(depth, skybox, skybox3d)
	if skybox then return end

	for texture, meshes in next, mim_meshes do
		for _, obj in ipairs(meshes) do
			if not mim_mat_cache[texture] then continue end
			if not obj:IsValid() then continue end
			render.SetMaterial(mim_mat_cache[texture])
			obj:Draw()
			render.RenderFlashlights(function() obj:Draw() end)
		end
	end
end)

hook.Add("PreDrawTranslucentRenderables", TAG, function(depth, skybox, skybox3d)
	if skybox then return end

	for texture, meshes in next, mim_meshes do
		for _, obj in ipairs(meshes) do
			if not mim_mat_cache_trans[texture] then continue end
			if not obj:IsValid() then continue end
			render.SetMaterial(mim_mat_cache_trans[texture])
			obj:Draw()
			render.RenderFlashlights(function() obj:Draw() end)
		end
	end
end)
