local TAG = "!MsgAll"
local CLIENT_COLOR = Color(160, 160, 255)

if SERVER then
	util.AddNetworkString(TAG)
end

local table_concat = table.concat
local tostring = tostring
local ipairs = ipairs
local Msg = epoe and epoe.RealMsg or Msg
local MsgC = MsgC

function MsgAll(...)
	local args = { ... }
	local newArgs = {}
	for _, arg in ipairs(args) do
		newArgs[#newArgs + 1] = tostring(arg)
	end
	local str = table_concat(newArgs, "")

	if SERVER then
		Msg(str)
		net.Start(TAG)
		net.WriteString(str)
		net.Broadcast()
	else
		MsgC(CLIENT_COLOR, str)
	end
end

if CLIENT then
	net.Receive(TAG, function()
		local str = net.ReadString()
		if str == nil or #str == 0 or str == "\n" then return end

		MsgC(CLIENT_COLOR, str)
	end)
end
