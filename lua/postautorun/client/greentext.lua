local ENABLED = CreateClientConVar("chat_greentext", "1", true, false, "Enables greentext", 0, 1)

hook.Add("PreChatAddText", "greentext", function(args)
	if not ENABLED:GetBool() then return end

	for i, arg in ipairs(args) do
		local prevArg = args[i - 1]
		if isstring(prevArg) and prevArg == ": " and isstring(arg) and arg:StartsWith(">") then
			table.insert(args, i, Color(175, 201, 96))
			break
		end
	end

	return args
end)
