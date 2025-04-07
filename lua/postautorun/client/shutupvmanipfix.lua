local hooks = hook.GetTable()
if hooks.InitPostEntity and hooks.InitPostEntity.InitializeVManipPatch then
	local _ChenVManipPatch = hooks.InitPostEntity.InitializeVManipPatch
	local PLAYER = FindMetaTable("Player")

	local function ChenVManipPatch(...)
		local oldPrintMessage = PLAYER.PrintMessage
		PLAYER.PrintMessage = function(self, t, msg)
			local info = debug.getinfo(2, "S")
			if info.short_src == "lua/autorun/sh_vmanip_chenpatch.lua" then
				t = HUD_PRINTCONSOLE
			end

			return oldPrintMessage(self, t, msg)
		end
		_ChenVManipPatch(...)
		timer.Simple(1, function()
			PLAYER.PrintMessage = oldPrintMessage
		end)
	end

	concommand.Add("cl_vmanip_patch_reinitialize", ChenVManipPatch)
	hook.Add("InitPostEntity", "InitializeVManipPatch", ChenVManipPatch)
end

