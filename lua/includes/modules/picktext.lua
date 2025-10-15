if SERVER then
	AddCSLuaFile()
	return
end

local surface_GetTextSize = surface.GetTextSize
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawLine = surface.DrawLine
local surface_SetFont = surface.SetFont
local surface_SetTextColor = surface.SetTextColor
local surface_SetTextPos = surface.SetTextPos
local surface_DrawText = surface.DrawText

local COLOR = FindMetaTable("Color")
local Color_Unpack = COLOR.Unpack

local TAG = "picktext"
module("picktext", package.seeall)

local function keep_inside_circle(x, y, r)
	local A = {
		x = ScrW() / 2,
		y = ScrH() / 2
	}
	local B = {
		x = x,
		y = y
	}
	local C = {}

	C.x = A.x + (r / 2 * ((B.x - A.x) / math.sqrt(math.pow(B.x - A.x, 2) + math.pow(B.y - A.y, 2))))
	C.y = A.y + (r / 2 * ((B.y - A.y) / math.sqrt(math.pow(B.x - A.x, 2) + math.pow(B.y - A.y, 2))))

	return C
end

local function is_outside_circle(x, y, r)
	return x ^ 2 + y ^ 2 > (r / 2) ^ 2
end

---@class Line
---@field text string
---@field prefix string
---@field color Color
---@field pColor Color

---@class Lines Line[]
---@field longest integer

---Add a line to a table of lines
---@param lines Lines
---@param text string
---@param prefix string
---@param pColor Color
---@param color Color
function AddLine(lines, text, prefix, pColor, color)
	if lines.longest == nil then lines.longest = 0 end
	if not text then return end

	local str = prefix .. text
	surface_SetFont("BudgetLabel")
	local tw = surface_GetTextSize(str)
	if tw > lines.longest then
		lines.longest = tw
	end

	lines[#lines + 1] = {
		text = text,
		prefix = prefix,
		pColor = pColor,
		color = color,
	}
end

---@class Block
---@field x integer
---@field y integer
---@field w integer
---@field h integer
---@field cx integer
---@field cy integer
---@field lines Lines

---@type Block[]
RenderQueue = {}

---Create a Block from Lines and add it to the render queue
---@param lines Lines
---@param cx integer X position of the center of the block
---@param cy integer Y position of the center of the block
function AddBlock(lines, cx, cy)
	surface_SetFont("BudgetLabel")
	local _, tw = surface_GetTextSize("W")

	local w = lines.longest
	local h = tw * #lines
	local x = cx - (w / 2)
	local y = cy - (h / 2)

	RenderQueue[#RenderQueue + 1] = {
		x = x,
		y = y,
		w = w,
		h = h,
		cx = cx,
		cy = cy,
		lines = lines,
	}
end

local SCROLL_ENABLED = false
local SCROLL_ENABLED_LAST = false
local SCROLL_OFFSET = 0

hook.Add("PlayerBindPress", TAG, function(ply, bind, pressed, code)
	if SCROLL_ENABLED and pressed and (code == MOUSE_WHEEL_UP or code == MOUSE_WHEEL_DOWN) then
		surface_SetFont("BudgetLabel")
		local _, th = surface_GetTextSize("W")

		if code == MOUSE_WHEEL_UP then
			SCROLL_OFFSET = SCROLL_OFFSET - th
			if SCROLL_OFFSET < 0 then SCROLL_OFFSET = 0 end
		else
			SCROLL_OFFSET = SCROLL_OFFSET + th
		end

		return true
	end
end)

---Render a Block
---@param block Block
---@param stacking boolean?
---@param mindist integer?
---@param nexty integer?
function RenderBlock(block, stacking, mindist, nexty)
	surface_SetFont("BudgetLabel")
	local _, th = surface_GetTextSize("W")

	local x, y, w, h, cx, cy = block.x, block.y, block.w, block.h, block.cx, block.cy

	if stacking and nexty > y then y = nexty end

	local offset = stacking and SCROLL_OFFSET or 0

	local contain = true
	if stacking then
		contain = not SCROLL_ENABLED
	end
	if contain and is_outside_circle((ScrW() / 2) - x, (ScrH() / 2) - y, ScrH() - (64 + 48 + 8)) then
		local newpos = keep_inside_circle(x, y, ScrH() - (64 + 48 + 8))
		x = newpos.x
		y = newpos.y
	end

	surface_SetDrawColor(255, 255, 255, 96)
	surface_DrawLine(cx, cy, x + (w / 2), (y - offset) + (h / 2))

	for _, line in ipairs(block.lines) do
		surface_SetTextColor(Color_Unpack(line.pColor))
		surface_SetTextPos(x, y - offset)
		surface_DrawText(line.prefix)
		surface_SetTextColor(Color_Unpack(line.color))
		surface_DrawText(line.text)
		y = y + th
	end

	if stacking then
		local _x, _y = x - cx, y - cy
		local dist = _x * _x + _y * _y * th

		if dist < mindist then
			mindist = dist
		end
		nexty = y + (th / 2)

		return mindist, nexty
	end
end

hook.Add("HUDPaint", TAG, function()
	if #RenderQueue == 0 then return end

	SCROLL_ENABLED_LAST = SCROLL_ENABLED
	SCROLL_ENABLED = input.IsKeyDown(KEY_LALT)
	if SCROLL_ENABLED_LAST and not SCROLL_ENABLED then
		SCROLL_OFFSET = 0
	end

	surface_SetFont("BudgetLabel")
	local _, th = surface_GetTextSize("W")

	local _toRender = {}
	local toStack = {}

	for i, block in ipairs(RenderQueue) do
		if #RenderQueue == 1 then
			_toRender[#_toRender + 1] = block
			break
		end

		local x1, y1, w1, h1 = block.x, block.y, block.w, block.h
		local x2, y2, w2, h2
		if i == 1 then
			local next_data = RenderQueue[2]
			x2, y2, w2, h2 = next_data.x, next_data.y, next_data.w, next_data.h
		else
			local prev_data = RenderQueue[i - 1]
			x2, y2, w2, h2 = prev_data.x, prev_data.y, prev_data.w, prev_data.h
		end

		if is_outside_circle((ScrW() / 2) - x1, (ScrH() / 2) - y1, ScrH() - (64 + 48 + 8)) then
			local newpos = keep_inside_circle(x1, y1, ScrH() - (64 + 48 + 8))
			x1 = newpos.x
			y1 = newpos.y
		end
		if is_outside_circle((ScrW() / 2) - x2, (ScrH() / 2) - y2, ScrH() - (64 + 48 + 8)) then
			local newpos = keep_inside_circle(x2, y2, ScrH() - (64 + 48 + 8))
			x2 = newpos.x
			y2 = newpos.y
		end

		if
				(x2 >= x1 and x2 <= x1 + w1) or (x1 >= x2 and x1 <= x2 + w2) and
				(y1 >= y2 and y1 <= y2 + h2) or (y2 >= y1 and y2 <= y1 + h1)
		then
			toStack[#toStack + 1] = block
		else
			_toRender[#_toRender + 1] = block
		end
	end

	local toRender = {}
	if #_toRender > 1 and #toStack > 0 then
		for _, block in ipairs(_toRender) do
			local x1, y1, w1, h1 = block.x, block.y, block.w, block.h
			local x2, y2, w2, h2

			local add_to_new = true

			local ay = 0
			for j, otherBlock in ipairs(toStack) do
				h2 = otherBlock.h
				local _y2 = otherBlock.y
				x2, y2, w2 = otherBlock.x, ay, otherBlock.w
				if j == 1 then y2 = _y2 end
				if is_outside_circle((ScrW() / 2) - x2, (ScrH() / 2) - y2, ScrH() - (64 + 48 + 8)) then
					local newpos = keep_inside_circle(x2, y2, ScrH() - (64 + 48 + 8))
					x2 = newpos.x
					y2 = newpos.y
				end

				if
						(x2 >= x1 and x2 <= x1 + w1) or (x1 >= x2 and x1 <= x2 + w2) and
						(y1 >= ay and y1 <= ay + h2) or (_y2 >= y1 and _y2 <= y1 + h1)
				then
					toStack[#toStack + 1] = block
					add_to_new = false
					break
				end

				ay = ay + _y2 + h2 + (th / 2)
			end

			if add_to_new then
				toRender[#toRender + 1] = block
			end
		end
	else
		toRender = _toRender
	end

	for _, block in ipairs(toRender) do
		RenderBlock(block)
	end

	local mindist, nexty = math.huge, -math.huge
	for _, block in ipairs(toStack) do
		mindist, nexty = RenderBlock(block, true, mindist, nexty)
	end

	table.Empty(RenderQueue)
end)
