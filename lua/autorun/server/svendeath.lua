if not AddHUDNotify then return end

local PHRASES_DMG = {
	[DMG_CRUSH] = "was crushed",
	[DMG_BULLET] = "was shot",
	[DMG_SLASH] = "has been chopped",
	[DMG_BURN] = "burned down",
	[DMG_VEHICLE] = "became roadkill",
	[DMG_FALL] = "fell",
	[DMG_BLAST] = "blew up",
	[DMG_CLUB] = "was bludgeoned",
	[DMG_SHOCK] = "was electrocuted",
	[DMG_SONIC] = "went deaf",
	[DMG_ENERGYBEAM] = "was cut by a laser",
	[DMG_NEVERGIB] = "was poked to death",
	--[DMG_ALWAYSGIB] = "was gibbed",
	[DMG_DROWN] = "drank too much",
	[DMG_PARALYZE] = "was paralyzed",
	[DMG_NERVEGAS] = "inhaled nerve gas",
	[DMG_POISON] = "has been poisoned",
	[DMG_RADIATION] = "went nuclear",
	[DMG_ACID] = "has been dissolved",
	[DMG_SLOWBURN] = "was baked like a cake",
	[DMG_REMOVENORAGDOLL] = "was never seen again",
	[DMG_PHYSGUN] = "was flung into another dimension",
	[DMG_PLASMA] = "found the fourth state of matter",
	[DMG_AIRBOAT] = "was a victim of a drive-by",
	[DMG_DISSOLVE] = "got dunked on",
	[DMG_SNIPER] = "found out their head just Does That",
	[DMG_MISSILEDEFENSE] = "was blown to shreds by a mortar",
}

hook.Add("DoPlayerDeath", "svendeath", function(ply, atk, dmg)
	local inf = dmg:GetInflictor()
	local infClass = inf:IsValid() and inf:GetClass()

	local suicide = ply == atk
	local mountedGun = infClass and infClass:find("^func_tank")

	local phrase = "died mysteriously"

	if atk == game.GetWorld() then
		phrase = "fell or something"
		if dmg:IsDamageType(DMG_DROWN) then
			phrase = "drowned"
		end
	elseif suicide then
		phrase = "committed suicide"
		if dmg:IsDamageType(DMG_BLAST) then
			phrase = "blew themselves up"
		end
	elseif
			mountedGun or
			(atk:IsNPC() and atk:Classify() == CLASS_COMBINE_GUNSHIP and not dmg:IsDamageType(DMG_BLAST))
	then
		phrase = "was gunned down"
	else
		for type, str in next, PHRASES_DMG do
			if dmg:IsDamageType(type) then
				phrase = str
				break
			end
		end
	end

	local attacker = ""
	if
			atk:IsValid() and
			(atk:IsNPC() or atk:IsPlayer()) and
			not suicide and
			not dmg:IsDamageType(DMG_REMOVENORAGDOLL)
	then
		local prefix = "by"

		if dmg:IsDamageType(DMG_RADIATION) then
			phrase = "was irradiated"
		elseif dmg:IsDamageType(DMG_BLAST) then
			phrase = "was blown up"
		elseif dmg:IsDamageType(DMG_BUCKSHOT) then
			phrase = "ate pellets of lead"
			prefix = "from"
		elseif dmg:IsDamageType(DMG_BURN) then
			phrase = "was burnt"
		elseif
				phrase == PHRASES_DMG[DMG_SONIC] or
				phrase == PHRASES_DMG[DMG_ENERGYBEAM] or
				phrase == PHRASES_DMG[DMG_NERVEGAS] or
				phrase == PHRASES_DMG[DMG_SNIPER] or
				phrase == PHRASES_DMG[DMG_MISSILEDEFENSE] or
				phrase == PHRASES_DMG[DMG_DROWN]
		then
			prefix = "from"
		elseif atk:IsNPC() and atk:Classify() == CLASS_ZOMBIE then
			phrase = "was mauled"
			prefix = "by"
		end

		local name = "\7#" .. atk:GetClass()
		local displayname = atk:GetNW2String("displayname", "")
		if atk:IsPlayer() then
			name = atk:Name()
		elseif displayname ~= "" then
			name = displayname
		end

		attacker = prefix .. " " .. name
	end

	local str = ply:Name() .. " " .. phrase .. " " .. attacker
	AddHUDNotify(string.Trim(str) .. ".")
end)
