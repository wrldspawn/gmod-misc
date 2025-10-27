local col = Color(192, 128, 192)
local dev = GetConVar("developer")

hook.Add("EngineSpew", "ExtraSpews", function(a, msg, c, d, r, g, b)
	if dev:GetInt() ~= 4 then return end
	if not epoe then return end
	if epoe.InEPOE then return end

	if msg:match("^%([%d%.]-%) input") or msg:match("^%([%d%.]-%) output") or msg:match("^unhandled input:") then
		epoe.PushMsgC(col, "[dev 4] " .. msg:gsub("%([%d%.]-%) ", ""))
	end
end)
