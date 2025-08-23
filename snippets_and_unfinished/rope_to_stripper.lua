-- use smartsnap and bspsnap to make things easier
-- maybe ill write my own snapping thing some other day

local template = [[
; rope2beam start: %d
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
; rope2beam end: %d
]]

if not file.Exists("pole", "DATA") then
	file.CreateDir("pole")
end

concommand.Add("pole_rope_to_beam", function()
	local i = 1

	local stripper = ""

	for _, rope in ipairs(ents.FindByClass("keyframe_rope")) do
		if rope:CreatedByMap() then continue end

		local pos1 = rope:GetInternalVariable("StartOffset")
		local ent1 = rope:GetInternalVariable("m_hStartPoint")
		local pos2 = rope:GetInternalVariable("EndOffset")
		local ent2 = rope:GetInternalVariable("m_hEndPoint")

		if not ent1:IsWorld() then
			pos1 = ent1:LocalToWorld(pos1)
		end
		if not ent2:IsWorld() then
			pos2 = ent2:LocalToWorld(pos2)
		end

		pos1 = table.concat(pos1:ToTable(), " ")
		pos2 = table.concat(pos2:ToTable(), " ")

		stripper = stripper .. string.format(template, i, pos1, i, pos2, i, i, i, i)

		i = i + 1
	end

	local filename = "pole/rope2beam - " .. game.GetMap() .. ".txt"

	file.Write(filename, stripper)

	print("Stripper data written to data/" .. filename)
end)
