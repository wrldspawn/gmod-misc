if _G.gterm_sock then
	_G.gterm_sock:shutdown()
	_G.gterm_sock:close()
end

local sock = assert(socket.tcp())
sock:settimeout(0)
sock:connect("127.0.0.1", "27514")

local function StringToInt(str)
	local a, b, c, d = string.byte(str, 1, 4)

	if d then
		return bit.bor(bit.lshift(d, 24), bit.lshift(c, 16), bit.lshift(b, 8), a)
	elseif c then
		return bit.bor(bit.lshift(c, 16), bit.lshift(b, 8), a)
	elseif b then
		return bit.bor(bit.lshift(b, 8), a)
	else
		return a
	end
end

local buffer = {}
local hasNewline = true
hook.Add("Think", "gterm_sock", function()
	if not sock then return end

	local head, err = sock:receive(4)
	if head then
		local length = StringToInt(head)
		if length > 0 then
			local body, berr = sock:receive(length)
			if body then
				local part = {
					type = StringToInt(body:sub(1, 4)),
					level = StringToInt(body:sub(5, 8)),
				}
				local i = 9
				local group = ""
				while string.byte(body, i, i) ~= 0 do
					group = group .. body:sub(i, i)
					i = i + 1
				end
				part.group = group

				i = i + 1
				part.color = Color(
					string.byte(body, i, i),
					string.byte(body, i + 1, i + 1),
					string.byte(body, i + 2, i + 2),
					string.byte(body, i + 3, i + 3)
				)
				i = i + 4
				local msg = ""
				while string.byte(body, i, i) ~= 0 do
					msg = msg .. body:sub(i, i)
					i = i + 1
				end
				part.msg = msg

				buffer[#buffer + 1] = part

				if hasNewline then
					epoe.ProcessMessage(epoe.IS_MSG, "[GTerm] ")
				end
				epoe.ProcessMessage(part.type == 1 and epoe.IS_ERROR or epoe.IS_MSGC,
					part.type == 1 and part.msg:Trim() or part.msg, part.color)
				hasNewline = part.msg:find("\n") ~= nil

				--sock:shutdown()
				--sock:close()
				--hook.Remove("Think", "gterm_sock")
			elseif berr == "closed" then
				sock:shutdown()
				sock:close()
			elseif berr ~= "timeout" then
				ErrorNoHalt("gterm failed: " .. err)
				sock:shutdown()
				sock:close()
			end
		end
	elseif err == "closed" then
		sock:shutdown()
		sock:close()
	elseif err ~= "timeout" then
		ErrorNoHalt("gterm failed: " .. err)
		sock:shutdown()
		sock:close()
	end
end)

_G.gterm_sock = sock
_G.gterm_buffer = buffer
