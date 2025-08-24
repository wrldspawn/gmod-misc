local COLOR_PREFIX = Color(128, 128, 255)
local COLOR_WHITE = Color(255, 255, 255)
local COLOR_GRAY = Color(164, 164, 164)
local COLOR_GREEN = Color(128, 255, 128)
local COLOR_RED = Color(255, 128, 128)
hook.Add("CheckPassword", "connection_log", function(steamid, ip, svpw, pw, name)
    ip = ip:gsub(":%d+$", "")
    local steamid16 = util.SteamIDFrom64(steamid)

    MsgC(COLOR_PREFIX, "[Join] ")
    MsgC(COLOR_WHITE, name .. " ")
    MsgC(COLOR_GRAY, "(" .. steamid16 .. ")")
    MsgC(COLOR_WHITE, " - " .. ip)
    if pw and pw ~= "" then
        MsgC(COLOR_WHITE, " - Password: ")
        MsgC(svpw == "" and COLOR_WHITE or (pw == svpw and COLOR_GREEN or COLOR_RED), pw)
    end
    MsgN("")
end)
