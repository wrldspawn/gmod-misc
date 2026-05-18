chat.ExtraHooks = chat.ExtraHooks or {}

chat.ExtraHooks.AddText = chat.ExtraHooks.AddText or chat.AddText
local origChatAddText = chat.ExtraHooks.AddText

local function runHooks(name, args)
	local hooks = hook.GetTable()[name] or {}
	for id, callback in next, hooks do
		local function catch(err)
			ErrorNoHalt(Format("Failed to run %s hook %q: %s", name, id, err))
		end

		local ok, ret = xpcall(callback, catch, args)
		if not ok then continue end

		if ret ~= nil then
			if not istable(ret) then
				ErrorNoHalt(Format("Return value for %s hook %q was not a table.", name, id))
				continue
			end

			args = ret
		end
	end

	return args
end

function chat.AddText(...)
	local args = { ... }
	args = runHooks("PreChatAddText", args)

	origChatAddText(unpack(args))
	hook.Run("OnChatAddText", args)
end

local function DetourOnPlayerChat()
	chat.ExtraHooks.OnPlayerChat = chat.ExtraHooks.OnPlayerChat or GAMEMODE.OnPlayerChat
	local origOnPlayerChat = chat.ExtraHooks.OnPlayerChat

	function GAMEMODE:OnPlayerChat(ply, text, is_team, is_dead, ...)
		local oldChatAddText = chat.AddText
		local args = {}
		chat.AddText = function(...)
			args = { ... }
		end
		origOnPlayerChat(self, ply, text, is_team, is_dead, ...)
		chat.AddText = oldChatAddText

		local new_args = {}
		for i, arg in ipairs(args) do
			new_args[i] = arg

			if isstring(arg) then
				if arg:StartsWith(": ") and #arg > 2 then
					local str = arg:sub(3)
					new_args[i] = ": "
					table.insert(new_args, i + 1, str)
				end
			end
		end

		new_args = runHooks("PrePlayerChat", new_args)
		chat.AddText(unpack(new_args))

		return true
	end
end

hook.Add("Initialize", "chat_extrahooks", function()
	DetourOnPlayerChat()
end)
if GAMEMODE then
	DetourOnPlayerChat()
end
