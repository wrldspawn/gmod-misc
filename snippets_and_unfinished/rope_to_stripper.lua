-- use smartsnap and bspsnap to make things easier
-- maybe ill write my own snapping thing some other day

local template = [[
; pole - rope2beam start: %d
add:
{
	"classname" "info_target"
	"origin" "%s"
	"targetname" "rope2beam_%d_start"
}
add:
{
	"classname" "info_target"
	"origin" "%s"
	"targetname" "rope2beam_%d_end"
}
add:
{
	"classname" "env_beam"
	"life" "0"
	"texture" "sprites/laserbeam.vmt"
	"rendercolor" "255 0 255"
	"BoltWidth" "2"
	"LightningStart" "rope2beam_%d_start"
	"LightningEnd" "rope2beam_%d_end"
	"spawnflags" "1"
}
; pole - rope2beam end: %d
]]

if not file.Exists("pole", "DATA") then
	file.CreateDir("pole")
end

concommand.Add("pole_rope_to_beam", function()
	local i = 1

	local stripper = ""

	for _, rope in ipairs(ents.FindByClass("keyframe_rope")) do
		if rope:CreatedByMap() then continue end

		local pos1 = table.concat(rope.LPos1:ToTable(), " ")
		local pos2 = table.concat(rope.LPos2:ToTable(), " ")

		stripper = stripper .. string.format(template, i, pos1, i, pos2, i, i, i, i)

		i = i + 1
	end

	local filename = "pole/rope2beam - " .. game.GetMap() .. ".txt"

	file.Write(filename, stripper)

	print("Stripper data written to data/" .. filename)
end)
