-- chat font does not ScreenScaleH easily
local function GetChatFontSize()
	local h = ScrH()

	if h > 480 and h < 600 then
		return 12
	elseif h > 600 and h < 768 then
		return 14
	elseif h > 768 and h < 1024 then
		return 15
	elseif h > 1024 and h < 1200 then
		return 17
	elseif h > 1200 then
		return 22
	end
end

surface.CreateFont("ChatFontUnderline", {
	font = "Verdana",
	size = GetChatFontSize(),
	weight = 700,
	antialias = false,
	shadow = true,
	underline = true,
})

local speed = 500

local max_y
local min_y = ScrH()

local MAIN = {}

--[[function MAIN:Think()
	local x, y = self:GetPos()

	y = math.min(min_y, math.max(max_y, y + (chat.IsOpen() and -1 or 1) * RealFrameTime() * speed))
	self:SetPos(x, y)
end--]]

function MAIN:Paint()
	local alpha_mod = chat.GetInput():GetAlpha() / 255

	surface.SetDrawColor(50, 50, 50, 175 * alpha_mod)
	surface.DrawRect(0, 0, self:GetWide(), self:GetTall())


	surface.SetDrawColor(50, 50, 50, 255 * alpha_mod)
	surface.DrawOutlinedRect(0, 0, self:GetWide(), self:GetTall())

	return true
end

local function OnTextClicked(self, id)
	print(id, string.StartsWith(id, "http"))
	if id and string.StartsWith(id, "http") then
		gui.OpenURL(id)
	end
end

hook.Add("ChatModInitialize", "Example", function(pnl)
	local hist = chat.GetHistory()

	-- easychat RichTextLegacy hacks
	local last_color = hist:GetFGColor()
	local old_InsertColorChange = hist.InsertColorChange
	hist.InsertColorChange = function(self, r, g, b, a)
		last_color = istable(r) and Color(r.r, r.g, r.b) or Color(r, g, b)
		old_InsertColorChange(self, last_color.r, last_color.g, last_color.b, last_color.a)
	end
	hist.GetLastColorChange = function() return last_color end

	local old_IsHovered = hist.IsHovered
	hist.IsHovered = function(self) return old_IsHovered(self) or self:IsChildHovered() end

	hist._click_list = {}
	local old_InsertClickableTextStart = hist.InsertClickableTextStart
	hist.InsertClickableTextStart = function(self, value)
		local prev = self._click_list[#self._click_list]

		table.insert(self._click_list, { value, prev, false })

		if #self._click_list > 1024 then
			table.Empty(self._click_list[1])
			table.remove(self._click_list, 1)
		end

		old_InsertClickableTextStart(self, value)
	end

	local old_OnChildAdded = hist.OnChildAdded or function() end
	hist.OnChildAdded = function(self, child)
		old_OnChildAdded(self, child)

		print("chat child added", child, child:GetParent(), child:GetZPos())
		if child:GetClassName() == "ClickPanel" then
			if not next(self._click_list) then return end
			local click_data = self._click_list[#self._click_list]
			if not click_data or next(click_data) == nil then return end
			local signal_value, click_data_prevpos, clickpanel_old = unpack(click_data)
			click_data[3] = child
			child._click_data = click_data
			child.signal_value = signal_value
			self._think_dirty = true

			for i = 1, 1024 do
				if not IsValid(clickpanel_old) then break end
				child = clickpanel_old
				click_data = click_data_prevpos
				if not click_data or next(click_data) == nil then return end
				signal_value, click_data_prevpos, clickpanel_old = unpack(click_data)
				click_data[3] = child
				child._click_data = click_data
				child.signal_value = signal_value
			end

			child:SetZPos(10)
		end
	end

	hist.CleanupDirtyClickList = function(self)
		local data = self._click_list[#self._click_list]
		if not data then return end
		if not data[3] then return end

		for i = 1, 1025 do
			local data = self._click_list[i]
			if not data then break end
			table.Empty(data)
		end

		table.Empty(self._click_list)
	end

	hist.ThinkLinkHover = function(self)
		if self._think_dirty then
			self._think_dirty = false
			self:CleanupDirtyClickList()
		end

		local hover = vgui.GetHoveredPanel()

		if not hover or hover:GetClassName() ~= "ClickPanel" then
			self._link_hovering = false
			local signal_value = self._last_hover_signal_value

			if signal_value then
				self._last_hover_signal_value = nil
				self:OnTextHover(signal_value, false)
			end

			return
		end

		if hover:GetParent() ~= self then return end
		if self._link_hovering == hover then return end
		self._link_hovering = hover

		if self._last_hover_signal_value then
			local signal_value = self._last_hover_signal_value
			self._last_hover_signal_value = nil
			hook.Run("ChatLinkHover", signal_value, false)
		end

		local signal_value = hover.signal_value
		if not signal_value then return end
		self._last_hover_signal_value = signal_value
		hook.Run("ChatLinkHover", signal_value, true)
	end

	local old_Think = hist.Think or function() end
	hist.Think = function(self)
		old_Think(self)

		local now = RealTime()
		local nt = self._next_think_hover or 0
		if nt > now then return end

		self._next_think_hover = now + 0.1
		self:ThinkLinkHover()
	end
	hist.OnTextClicked = OnTextClicked

	local line = chat.GetInputLine()
	line:SetPos(8, 8)
	line:SetWide(pnl:GetWide() - 16)

	hist:SetPos(8, 16 + line:GetTall())
	hist:SetWide(pnl:GetWide() - 16)
	hist:SetTall(hist:GetTall() + (ScreenScaleH(17) - 8))

	chat.SetFont("ChatFont")
	chat.SetUnderlineFont("ChatFontUnderline")

	chat.GetFilterButton():SetVisible(false)

	chat.GetScrollbar():SetWide(16)

	--chat.Resize(ScrW() / 4 * 3, pnl:GetTall())

	--[[pnl:SetPos(ScrW() / 8, ScrH() - pnl:GetTall() - 50)

	local x, y = pnl:GetPos()
	max_y = y

	local hx, hy = chat.GetHistory():GetPos()
	y = y + hy
	local endy = y + chat.GetHistory():GetTall()
	y = y + ScrH() - endy
	min_y = y--]]

	for k, v in pairs(MAIN) do pnl[k] = v end
end)

if chat.IsActive then
	hook.Run("ChatModInitialize", chat.GetPanel())
end
