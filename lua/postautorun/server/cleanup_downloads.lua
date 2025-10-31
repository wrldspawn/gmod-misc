if not HolyLib then return end

local TO_REMOVE = {
	"materials/icon64/outfitter.png",
	"materials/icon64/new pac icon.png",
	"materials/icon64/pac3.png",
	"3038093543.gma", -- PAC3 develop branch
}

local downloadables = stringtable.FindTable("downloadables")
if downloadables then
	for _, path in ipairs(TO_REMOVE) do
		local idx = downloadables:FindStringIndex(path)
		if idx then
			downloadables:DeleteString(idx)
		end
	end
end
