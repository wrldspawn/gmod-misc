local hooks = hook.GetTable()

local fixPostDrawViewModel
if CLIENT then
	local ownInfo = debug.getinfo(1, "S")

	fixPostDrawViewModel = function()
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

-- until https://github.com/Xerasin/Sit-Anywhere/pull/58 is merged
local SIT_TAG = "SitAnyG_"
local function fixSitAnywhere()
	hook.Add("SetupMove", SIT_TAG .. "SetupMove", function(ply, mv)
		if not ply:GetNWBool(SIT_TAG) then
			return
		end

		local butts = mv:GetButtons()
		local getUp = bit.band(butts, IN_JUMP) == IN_JUMP or ply:GetMoveType() ~= MOVETYPE_WALK or ply:InVehicle() or
				not ply:Alive()

		if getUp then
			ply:SetNWBool(SIT_TAG, false)
		end

		local move = bit.band(butts, IN_DUCK) == IN_DUCK

		butts = bit.bxor(bit.bor(butts, bit.bor(IN_JUMP, IN_DUCK)), IN_JUMP)

		if move then
			butts = bit.bxor(bit.bor(bit.bor(butts, IN_WALK), IN_SPEED), IN_SPEED)

			mv:SetButtons(butts)
			return
		end

		mv:SetButtons(butts)
		mv:SetSideSpeed(0)
		mv:SetForwardSpeed(0)
		mv:SetUpSpeed(0)
	end)

	hook.Add("CalcMainActivity", SIT_TAG .. "CalcMainActivity", function(ply, vel)
		if ply:GetNWBool(SIT_TAG) and vel:Length2DSqr() < 1 then
			local seq = ply:LookupSequence("pose_ducking_02")

			if seq then
				return ACT_MP_SWIM, seq
			end
		end
	end)
end

local function do_overrides()
	if hooks.CalcMainActivity[SIT_TAG .. "CalcMainActivity"] then
		fixSitAnywhere()
	end

	if CLIENT then
		fixPostDrawViewModel()
	end
end

hook.Add("Initialize", "_optimizations_", do_overrides)
if GAMEMODE then do_overrides() end
