-- port of ecsr/showtriggers
local TAG = "showtriggers"

local TYPE_UNKNOWN = -1
local TYPE_MULTIPLE = 0
local TYPE_ANTIPRE = 1
local TYPE_SPEED = 2
local TYPE_TELEPORT = 3
local TYPE_ONCE = 4
local TYPE_OC = 5

local TRIGGER_COLORS = {
	[TYPE_UNKNOWN] = Color(255, 255, 255),
	[TYPE_MULTIPLE] = Color(0, 255, 0),
	[TYPE_ANTIPRE] = Color(128, 255, 0),
	[TYPE_SPEED] = Color(128, 255, 0),
	[TYPE_TELEPORT] = Color(255, 0, 0),
	[TYPE_ONCE] = Color(0, 0, 255),
	[TYPE_OC] = Color(0, 255, 255),
}

if SERVER then
	util.AddNetworkString(TAG)

	showtriggers_triggers = showtriggers_triggers or setmetatable({}, { __mode = "k" })
	showtriggers_players = showtriggers_players or setmetatable({}, { __mode = "k" })

	hook.Add("EntityKeyValue", TAG, function(ent, key, val)
		if not IsValid(ent) then return end
		local classname = ent:GetClass()
		if not classname:find("^trigger_") then return end

		if not showtriggers_triggers[ent] then showtriggers_triggers[ent] = {} end
		local outputs = showtriggers_triggers[ent]

		if key:sub(0, 2) == "On" then
			if not outputs[key] then outputs[key] = {} end
			local out = outputs[key]

			out[#out + 1] = val
		end
	end)

	local function SetupTriggers()
		for ent, kv in next, showtriggers_triggers do
			local classname = ent:GetClass()
			local type = TYPE_UNKNOWN

			if classname == "trigger_multiple" then
				type = TYPE_MULTIPLE

				if kv.OnStartTouch then
					for _, data in ipairs(kv.OnStartTouch) do
						if data:find("gravity 40") then -- Gravity anti-prespeed https://gamebanana.com/prefabs/6760.
							type = TYPE_ANTIPRE
							break
						elseif data:find("basevelocity") then -- some surf map boosters (e.g. surf_quirky)
							type = TYPE_SPEED
							break
						end
					end
				end

				if kv.OnEndTouch then
					for _, data in ipairs(kv.OnEndTouch) do
						if
								data:find("gravity -") -- Gravity booster https://gamebanana.com/prefabs/6677.
								or
								data:find("basevelocity") -- Basevelocity booster https://gamebanana.com/prefabs/7118.
						then
							type = TYPE_SPEED
							break
						end
					end
				end
			elseif classname == "trigger_push" then
				type = TYPE_SPEED
			elseif classname == "trigger_teleport" then
				type = TYPE_TELEPORT
			elseif classname == "trigger_once" then
				type = TYPE_ONCE
			elseif classname:find("_oc$") then
				type = TYPE_OC
			end

			ent:SetColor(TRIGGER_COLORS[type])
			ent:SetNoDraw(false)
		end

		local filter = RecipientFilter(true)
		filter:AddAllPlayers()
		local filter_on = RecipientFilter(true)
		for ply in next, showtriggers_players do
			filter:RemovePlayer(ply)
			filter_on:AddPlayer(ply)
		end
		for ent in next, showtriggers_triggers do
			if not IsValid(ent) then continue end
			ent:SetPreventTransmit(filter, true)
			ent:SetPreventTransmit(filter_on, false)
		end
	end

	hook.Add("PostCleanupMap", TAG, SetupTriggers)
	hook.Add("InitPostEntity", TAG, SetupTriggers)
	hook.Add("PlayerAuthed", TAG, function(ply)
		for ent in next, showtriggers_triggers do
			if not IsValid(ent) then continue end
			ent:SetPreventTransmit(ply, true)
		end
	end)

	net.Receive(TAG, function(len, ply)
		if not IsValid(ply) then return end

		if showtriggers_players[ply] then
			showtriggers_players[ply] = nil
			for ent in next, showtriggers_triggers do
				if not IsValid(ent) then continue end
				ent:SetPreventTransmit(ply, true)
			end
			ply:ChatPrint("No longer showing triggers")
		else
			showtriggers_players[ply] = true
			for ent in next, showtriggers_triggers do
				if not IsValid(ent) then continue end
				ent:SetPreventTransmit(ply, false)
			end
			ply:ChatPrint("Showing triggers")
		end
	end)
elseif CLIENT then
	local function RequestTriggers()
		net.Start(TAG)
		net.SendToServer()
	end
	concommand.Add("sm_showtriggers", RequestTriggers)
	concommand.Add("sm_triggers", RequestTriggers)
end
