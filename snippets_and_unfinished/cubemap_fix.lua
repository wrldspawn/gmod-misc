local function FixCubemaps()
	local mats = game.GetWorld():GetMaterials()

	local count = 0

	for _, path in ipairs(mats) do
		--if not path:StartsWith("maps/") then continue end

		local mat = Material(path)
		local cubemap = mat:GetString("$envmap")
		if not cubemap then continue end

		local cubemap_mat = Material(cubemap)
		if cubemap_mat and not cubemap_mat:IsError() then continue end

		mat:SetString("$envmap", "engine/defaultcubemap")
		count = count + 1
	end

	if count > 0 then
		print(Format("Fixed %i cubemaps", count))
	end
end

hook.Add("CalcView", "__CubemapFixer__", function()
	hook.Remove("CalcView", "__CubemapFixer__")

	FixCubemaps()
end)

