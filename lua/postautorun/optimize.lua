local overrides = {}

local ownInfo = debug.getinfo(1, "S")

local SysTime = SysTime
local print = print

overrides[#overrides + 1] = function()
	if CLIENT then
		local hook = hook
		local player_manager = player_manager
		local render = render
		local MATERIAL_CULLMODE_CW = MATERIAL_CULLMODE_CW
		local MATERIAL_CULLMODE_CCW = MATERIAL_CULLMODE_CCW

		local ENTITY = FindMetaTable("Entity")
		local Ent_IsValid = ENTITY.IsValid
		local Ent_DrawModel = ENTITY.DrawModel
		local Ent_GetTable = ENTITY.GetTable

		local PLAYER = FindMetaTable("Player")
		local Ply_GetHands = PLAYER.GetHands

		local WEAPON = FindMetaTable("Weapon")
		local Wep_IsScripted = WEAPON.IsScripted

		local hook_Call = hook.Call
		local render_CullMode = render.CullMode
		local player_manager_RunClass = player_manager.RunClass

		local function PostDrawViewModel(self, vm, ply, wep, flags)
			if not (wep and Ent_IsValid(wep)) then return false end

			local wepTable = Ent_GetTable(wep)

			if wepTable.UseHands or not Wep_IsScripted(wep) then
				local hands = Ply_GetHands(ply)
				if Ent_IsValid(hands) and Ent_IsValid(vm) then
					if not hook_Call("PreDrawPlayerHands", self, hands, vm, ply, wep, flags) then
						local flip = wepTable.ViewModelFlip
						if flip then
							render_CullMode(MATERIAL_CULLMODE_CW)
						end
						Ent_DrawModel(hands, flags)
						if flip then
							render_CullMode(MATERIAL_CULLMODE_CCW)
						end
					end

					hook_Call("PostDrawPlayerHands", self, hands, vm, ply, wep, flags)
				end
			end

			player_manager_RunClass(ply, "PostDrawViewModel", vm, wep, flags)

			local wepDrawVM = wepTable.PostDrawViewModel
			if wepDrawVM == nil then return false end
			return wepDrawVM(wep, vm, wep, ply, flags)
		end

		local GM = gmod.GetGamemode()
		local BaseGamemode = GM.BaseClass

		local baseInfo = debug.getinfo(BaseGamemode.PostDrawViewModel, "S")
		local info = debug.getinfo(GM.PostDrawViewModel, "S")
		local activeIsBase = GM.PostDrawViewModel == BaseGamemode.PostDrawViewModel or info.short_src == ownInfo.short_src
		if baseInfo.short_src == "gamemodes/base/gamemode/cl_init.lua" or baseInfo.short_src == ownInfo.short_src then
			BaseGamemode.PostDrawViewModel = PostDrawViewModel
			if activeIsBase then
				GM.PostDrawViewModel = PostDrawViewModel
			end
		end
	end
end

local function do_overrides()
	for _, override in ipairs(overrides) do
		override()
	end
end

hook.Add("Initialize", "_optimizations_", do_overrides)
if GAMEMODE then do_overrides() end
