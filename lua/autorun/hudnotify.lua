local TAG = "HUDNotify"

if SERVER then
	util.AddNetworkString(TAG)

	function AddHUDNotify(str)
		net.Start(TAG)
		net.WriteString(tostring(str))
		net.Broadcast()
	end

	local PLAYER = FindMetaTable("Player")

	function PLAYER:AddHUDNotify(str)
		net.Start(TAG)
		net.WriteString(tostring(str))
		net.Send(self --[[@as Player]])
	end
elseif CLIENT then
	local messages = {}

	function AddHUDNotify(str)
		str = tostring(str)
		local parts = string.Explode(" ", str)
		for i, part in ipairs(parts) do
			if part:find("\7#") then
				local phrase = part:gsub("\7#", "")
				local period = phrase:find("%.$")
				if period then
					phrase = phrase:gsub("%.$", "")
				end
				parts[i] = language.GetPhrase(phrase)
				if period then
					parts[i] = parts[i] .. "."
				end
			end
		end
		str = table.concat(parts, " ")

		local msg = {}
		msg.time = CurTime()
		msg.text = str

		table.insert(messages, msg)
		local lply = LocalPlayer()
		if IsValid(lply) and lply.PrintMessage then
			lply:PrintMessage(HUD_PRINTNOTIFY, str .. "\n")
		else
			MsgC(Color(255, 255, 255), str .. "\n")
		end
	end

	net.Receive(TAG, function()
		AddHUDNotify(net.ReadString())
	end)

	local hud_notify_time = CreateClientConVar("hud_notify_time", "6", true, false)
	hook.Add("HUDPaint", TAG, function()
		local time = hud_notify_time:GetFloat()
		local reset = messages[1] ~= nil

		local x = ScrW() - 2
		local y = 2

		local now = CurTime()
		for _, msg in ipairs(messages) do
			local t = msg.time + time
			if t > now then
				local text = msg.text

				surface.SetFont("ChatFont")
				local w, h = surface.GetTextSize(text)
				surface.SetTextPos(x - w, y)
				surface.SetTextColor(255, 180, 0, 255)
				surface.DrawText(text)

				y = math.ceil(y + h + 2)
				reset = false
			end
		end

		if reset then
			messages = {}
		end
	end)
end
