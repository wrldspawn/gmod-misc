local TAG = "trigger_beams"

if SERVER then
	util.AddNetworkString(TAG)

	net.Receive(TAG, function(len, ply)
		local tr = ply:GetEyeTrace()
		local e = ents.FindAlongRay(tr.StartPos, tr.HitPos)

		local trigger = NULL
		for _, ent in ipairs(e) do
			if IsValid(ent) and ent:GetClass():find("^trigger_") then
				trigger = ent
				break
			end
		end

		if not IsValid(trigger) then
			ply:ChatPrint("Failed to find a trigger")
		else
			net.Start(TAG)
			net.WriteString(trigger:GetModel():sub(2))
			net.WriteVector(trigger:GetPos())
			net.Send(ply)
		end
	end)
else
	local bmodels = NikNaks.CurrentMap:GetBModels()

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

	local p1, p2
	local function points_menu(points)
		p1 = points[1]
		p2 = points[2]

		---@class DFrame
		local frame = vgui.Create("DFrame")
		frame:SetTitle("Trigger Beams")
		frame:SetSize(256, 192)
		frame:SetPos(128, ScrH() / 2 - 192 / 2)
		frame:MakePopup()
		function frame:OnClose()
			p1 = nil
			p2 = nil
		end

		---@class DForm
		local form = vgui.Create("DForm", frame)
		form:Dock(FILL)
		form:SetHeaderHeight(0)
		function form:Paint() end

		---@class DTextEntry
		local nameEntry = form:TextEntry("Name", "")

		---@class DNumSlider
		local point1 = form:NumSlider("Point 1", "", 1, #points, 0)
		point1:SetValue(1)
		function point1:OnValueChanged(i)
			i = math.floor(i)
			p1 = points[i]
		end

		---@class DNumSlider
		local point2 = form:NumSlider("Point 2", "", 1, #points, 0)
		point2:SetValue(2)
		function point2:OnValueChanged(i)
			i = math.floor(i)
			p2 = points[i]
		end

		---@class DButton
		local finalize = form:Button("Finalize", "")
		function finalize:DoClick()
			local name = nameEntry:GetValue()
			if name:Trim() == "" then
				LocalPlayer():ChatPrint("Name required")
				return
			end

			local str = Format([[
; trigger beam start: %s
add:
{
	"classname" "info_target"
	"origin" "%s"
	"tragetname" "%s_start"
}
add:
{
	"classname" "info_target"
	"origin" "%s"
	"tragetname" "%s_end"
}
add:
{
	"classname" "env_beam"
	"life" "0"
	"texture" "sprites/laserbeam.vmt"
	"rendercolor" "255 0 255"
	"BoltWidth" "2"
	"LightningStart" "%s_start"
	"LightningEnd" "%s_end"
	"spawnflags" "1"
}
; trigger beam end: %s
]], name, tostring(p1), name, tostring(p2), name, name, name, name):Trim()

			print(str)
			LocalPlayer():ChatPrint("Printed Stripper config to console")
		end
	end

	net.Receive(TAG, function()
		local model = net.ReadString()
		local pos = net.ReadVector()

		local points = {}

		local bmodel = bmodels[tonumber(model)]
		if not bmodel then return end

		for _, face in ipairs(bmodel:GetFaces()) do
			for _, p in ipairs(face:GetVertexs()) do
				points[#points + 1] = p + pos
			end
		end

		points = dedupe(points)

		points_menu(points)
	end)

	local beam = Material("sprites/physgbeamb")
	local col = Color(255, 0, 0)
	hook.Add("PostDrawTranslucentRenderables", TAG, function(depth, skybox)
		if skybox then return end

		if p1 and p2 and p1 ~= p2 then
			render.SetMaterial(beam)
			render.DrawBeam(p1, p2, 4, 0, 1, col)
		end
	end)

	concommand.Add(TAG, function()
		net.Start(TAG)
		net.SendToServer()
	end)
end
