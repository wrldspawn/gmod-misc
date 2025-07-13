local TAG = "mapicon"

local inProcess = false

local startCapture = false
local takeCapture = false

local takeIcon = false
local iconX, iconY, iconW, iconH = 0, 0, 512, 512

local function showResult()
	inProcess = true

	local img = vgui.Create("DImage")
	img:SetSize(ScrW(), ScrH())
	img:SetImage("../data/mapicon_tmp.png")

	---@class DFrame
	local iconArea = vgui.Create("DFrame")
	iconArea:SetSize(512, 512)
	iconArea:Center()
	iconArea:MakePopup()
	iconArea:SetTitle("Icon Capture")
	iconArea:SetScreenLock(true)
	---@diagnostic disable: undefined-field
	iconArea.btnClose:SetVisible(false)
	iconArea.btnMinim:SetVisible(false)
	iconArea.btnMaxim:SetVisible(false)
	---@diagnostic enable: undefined-field

	local closeButton = vgui.Create("DImageButton", iconArea)
	closeButton:SetImage("icon16/cross.png")
	closeButton:SizeToContents()
	closeButton:SetPos(iconArea:GetWide() - 20, 4)
	closeButton:SetTooltip("Close")
	function closeButton:DoClick()
		iconArea:Close()
	end

	local resizeButton = vgui.Create("DImageButton", iconArea)
	resizeButton:SetImage("icon16/arrow_out.png")
	resizeButton:SizeToContents()
	resizeButton:SetPos(iconArea:GetWide() - 40, 4)
	resizeButton:SetTooltip("Resize between 512 and 1024")

	local captureButton = vgui.Create("DImageButton", iconArea)
	captureButton:SetImage("icon16/camera.png")
	captureButton:SizeToContents()
	captureButton:SetPos(iconArea:GetWide() - 60, 4)
	captureButton:SetTooltip("Save Icon")
	function captureButton:DoClick()
		iconX, iconY = iconArea:GetPos()
		iconW, iconH = iconArea:GetSize()

		iconArea:SetVisible(false)
		startCapture = true
		timer.Simple(0.5, function()
			takeIcon = true

			timer.Simple(0.5, function()
				iconArea:SetVisible(true)
			end)
		end)
	end

	function resizeButton:DoClick()
		if iconArea:GetWide() == 512 and iconArea:GetTall() == 512 then
			iconArea:SetSize(1024, 1024)
			self:SetImage("icon16/arrow_in.png")
		else
			iconArea:SetSize(512, 512)
			self:SetImage("icon16/arrow_out.png")
		end
		closeButton:SetPos(iconArea:GetWide() - 20, 4)
		self:SetPos(iconArea:GetWide() - 40, 4)
		captureButton:SetPos(iconArea:GetWide() - 60, 4)
	end

	function iconArea:OnClose()
		img:Remove()
		inProcess = false
	end

	function iconArea:Paint(w, h)
		surface.SetDrawColor(0, 0, 0, 128)
		surface.DrawRect(0, 0, w, 24)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 2)
	end
end

hook.Add("HUDShouldDraw", TAG, function()
	if startCapture then return false end
end)
hook.Add("PreDrawViewModel", TAG, function()
	if startCapture then return true end
end)
hook.Add("PostRender", TAG, function()
	if takeCapture then
		startCapture = false
		takeCapture = false

		local data = render.Capture({
			format = "png",
			x = 0,
			y = 0,
			w = ScrW(),
			h = ScrH(),
			alpha = false,
		})

		file.Write("mapicon_tmp.png", data)

		showResult()
	elseif takeIcon then
		startCapture = false
		takeIcon = false

		local data = render.Capture({
			format = "png",
			x = iconX,
			y = iconY,
			w = iconW,
			h = iconH,
			alpha = false,
		})

		file.Write("mapicons/thumb/" .. game.GetMap() .. ".png", data)
	end
end)

concommand.Add("mapicon", function()
	if inProcess then return end

	startCapture = true
	timer.Simple(0.5, function()
		takeCapture = true
	end)
end)
