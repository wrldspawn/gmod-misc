if not AddHUDNotify then return end

local TAG = "npcmaker_counter"

local function SetupLuaRun()
	local ent = ents.Create("lua_run")
	ent:SetName("npcmaker_counter_lua")
	ent:Spawn()

	for _, e in ipairs(table.Add(ents.FindByClass("npc_maker"), ents.FindByClass("npc_template_maker"))) do
		e:Fire("AddOutput", "OnSpawnNPC npcmaker_counter_lua:RunPassedCode:hook.Run('NPCMakerSpawn'):0:-1")
	end
end

hook.Add("InitPostEntity", TAG, SetupLuaRun)
hook.Add("PostCleanupMap", TAG, SetupLuaRun)

hook.Add("NPCMakerSpawn", TAG, function()
	local maker = CALLER
	local npc = ACTIVATOR

	local total = maker:GetInternalVariable("MaxNPCCount")
	if maker._counter == nil then
		maker._counter = total + 1
	end
	maker._counter = maker._counter - 1

	local plural = maker._counter == 1 and "" or "s"

	local class = IsValid(npc) and npc:GetClass()
	if not class then
		class = maker:GetInternalVariable("NPCType")
	end

	if GAMEMODE.NPCReplacements then
		class = GAMEMODE.NPCReplacements[class] or class
	end

	local name = maker:GetName()
	if name and name ~= "" then
		AddHUDNotify(string.format("\7#%s spawner %q has %d NPC%s left.", class, name, maker._counter, plural))
	else
		AddHUDNotify(string.format("\7#%s spawner has %d NPC%s left.", class, maker._counter, plural))
	end
end)
