local ENABLED = CreateConVar("sv_debug_io_enabled", "0", FCVAR_ARCHIVE)

local TAG = "debug_io"
local COLOR = Color(192, 128, 192)

local MODE = CreateConVar("sv_debug_io_mode", "0")

local function SetupLuaRun()
	local ent = ents.Create("lua_run")
	ent:SetName("debug_io_lua")
	ent:Spawn()
end

hook.Add("InitPostEntity", TAG, SetupLuaRun)
hook.Add("PostCleanupMap", TAG, SetupLuaRun)

local ENTITY_OUTPUTS = {
	-- lambda's original list
	"OnAnimationBegun",
	"OnAnimationDone",
	"OnIgnite",
	"OnBreak",
	"OnTakeDamage",
	"OnHealthChanged",
	"OnPhysCannonDetach",
	"OnPhysCannonAnimatePreStarted",
	"OnPhysCannonAnimatePullStarted",
	"OnPhysCannonAnimatePostStarted",
	"OnPhysCannonPullAnimFinished",
	"OnUser1",
	"OnUser2",
	"OnUser3",
	"OnUser4",
	"OnKilled",
	"OnDeploy",
	"OnTipped",
	"OnMotionEnabled",
	"OnAwakened",
	"OnPhysGunOnlyPickup",
	"OnPhysGunPickup",
	"OnPlayerPickup",
	"OnPlayerTouch",
	"OnPhysGunDrop",
	"OnPlayerUse",
	"OnHitByTank",
	"OnFinishInteractWithObject",
	"OnDamaged",
	"OnDeath",
	"OnHalfHealth",
	"OnHalfEmpty",
	"OnEmpty",
	"OnFull",
	"OnHearWorld",
	"OnCacheInteraction",
	"OnNPCPickup",
	"OnHearPlayer",
	"OnHearCombat",
	"OnFoundEnemy",
	"OnLostEnemyLOS",
	"OnLostEnemy",
	"OnFoundPlayer",
	"OnLostPlayerLOS",
	"OnLostPlayer",
	"OnDamagedByPlayer",
	"OnDamagedByPlayerSquad",
	"OnDenyCommanderUse",
	"OnWake",
	"OnSpawnNPC",
	"OnSpawn",
	"OnAllSpawned",
	"OnAllLiveChildrenDead",
	"ImpactForce",
	"OnStartTouch",
	"OnTrigger",
	"OnTrigger1",
	"OnTrigger2",
	"OnTrigger3",
	"OnTrigger4",
	"OnTrigger5",
	"OnTrigger6",
	"OnTrigger7",
	"OnTrigger8",
	"OnTrigger9",
	"OnTrigger10",
	"OnTrigger11",
	"OnTrigger12",
	"OnTrigger13",
	"OnTrigger14",
	"OnTrigger15",
	"OnTrigger16",
	"OnStartTouchAll",
	"OnEndTouch",
	"OnEndTouchAll",
	"OnEqualTo",
	"OnGreaterThan",
	"OnLessThan",
	"OnNotEqualTo",
	"NoValidActor",
	"OnConditionsSatisfied",
	"OnConditionsTimeout",
	"OnIn",
	"OnPressed",
	"OnOut",
	"OnUseLocked",
	"OnBackgroundMap",
	"OnLoadGame",
	"OnMapSpawn",
	"OnMapTransition",
	"OnMultiNewMap",
	"OnMultiNewRound",
	"OnNewGame",
	"OnGetValue",
	"OnHitMax",
	"OnHitMin",
	"PlayerOff",
	"PlayerOn",
	"OnCompanionEnteredVehicle",
	"OnCompanionExitedVehicle",
	"OnHostileEnteredVehicle",
	"OnHostileExitedVehicle",
	"PressedAttack",
	"PressedAttack2",
	"AttackAxis",
	"Attack2Axis",
	"OnPass",
	"OnChangeLevel",

	-- obsidian conflict
	"OnCashReduced",
	"OnPurchased",
	"OnNotEnoughCash",
	"OnPlayerEntered",
	"OnAllPlayersEntered",
	"OnRedPlayerEntered",
	"OnAllRedPlayersEntered",
	"OnBluePlayerEntered",
	"OnAllBluePlayersEntered",
	"OnPlayerLeave",
	"OnRedPlayerLeave",
	"OnBluePlayerLeave",
	"OnTouching",
	"OnNotTouching",
	"OnTrue",
	"OnFalse",
}

if ENABLED:GetBool() then
	hook.Add("OnEntityCreated", TAG, function(ent)
		if not IsValid(ent) then return end
		for _, output in ipairs(ENTITY_OUTPUTS) do
			if not IsValid(ent) then return end
			ent:Input("AddOutput",
				nil,
				nil,
				output ..
				" debug_io_lua:RunPassedCode:local args={'OutputTriggered'}args[#args+1]='" ..
				output .. "' hook.Run(unpack(args)):0:-1")
		end
	end)

	for _, ent in ents.Iterator() do
		if not IsValid(ent) then continue end
		for _, output in ipairs(ENTITY_OUTPUTS) do
			ent:Fire("AddOutput",
				output ..
				" debug_io_lua:RunPassedCode:local args={'OutputTriggered'}args[#args+1]='" ..
				output .. "' hook.Run(unpack(args)):0:-1")
		end
	end
end

local function formatEnt(ent)
	if ent == game.GetWorld() then
		return "<world>"
	end
	if not IsValid(ent) then
		return "<unknown>"
	end

	local str = string.format("[%d] %s", ent:EntIndex(), ent:GetClass())

	if ent.GetName then
		local name = ent:GetName()
		if name and name ~= "" then
			str = str .. string.format(" (%q)", name)
		end
	end

	return str
end

hook.Add("AcceptInput", TAG, function(ent, inp, actor, caller, data)
	local mode = MODE:GetInt()
	if mode ~= 1 and mode ~= 2 then return end
	if inp == "AddOutput" and data and data:find("debug_io_lua:RunPassedCode") then return end

	local str = string.format("(%0.2f) input: %q %s -> %s", CurTime(), inp, formatEnt(caller), formatEnt(ent))

	if data and data ~= "" then
		str = str .. string.format(" %q", data)
	end

	MsgC(COLOR, str .. "\n")
end)
hook.Add("OutputTriggered", TAG, function(output)
	local mode = MODE:GetInt()
	if mode ~= 1 and mode ~= 3 then return end
	local ent, actor = CALLER, ACTIVATOR

	local str = string.format("(%0.2f) output: %q %s -> %s", CurTime(), output, formatEnt(actor), formatEnt(ent))

	MsgC(COLOR, str .. "\n")
end)
