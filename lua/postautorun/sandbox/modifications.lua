local overrides = {}

do -- options to utilities
	if CLIENT then
		spawnmenu._AddToolMenuOption = spawnmenu._AddToolMenuOption or spawnmenu.AddToolMenuOption
		local orig = spawnmenu._AddToolMenuOption

		function spawnmenu.AddToolMenuOption(tab, category, class, name, cmd, config, cpanel, data)
			if tab == "Options" then tab = "Utilities" end

			return orig(tab, category, class, name, cmd, config, cpanel, data)
		end
	end
end
