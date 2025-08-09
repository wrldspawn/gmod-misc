local map = game.GetMap()
if not string.match(map, "^d[1-3]_") and not string.match(map, "^ep[1-2]_") then return end

local PISTOL = {
    "weapon_swcs_cz75",
    "weapon_swcs_elite",
    "weapon_swcs_fiveseven",
    "weapon_swcs_glock",
    "weapon_swcs_hkp2000",
    "weapon_swcs_p250",
    "weapon_swcs_tec9",
    "weapon_swcs_usp_silencer"
}

local HEAVY_PISTOL = {
    "weapon_swcs_deagle",
    "weapon_swcs_revolver",

    "weapon_swcs_ragingbull",
}

local SHOTGUN = {
    "weapon_swcs_mag7",
    "weapon_swcs_nova",
    "weapon_swcs_sawedoff",
    "weapon_swcs_xm1014",

    "weapon_swcs_winchester",
    "weapon_swcs_aa12",
}

local SMG = {
    "weapon_swcs_mac10",
    "weapon_swcs_mp5sd",
    "weapon_swcs_mp7",
    "weapon_swcs_mp9",
    "weapon_swcs_p90",
    "weapon_swcs_bizon",
    "weapon_swcs_ump45",
}

local RIFLE = {
    "weapon_swcs_ak47",
    "weapon_swcs_aug",
    "weapon_swcs_famas",
    "weapon_swcs_galilar",
    "weapon_swcs_m4a1_silencer",
    "weapon_swcs_m4a1",
    "weapon_swcs_sg556",

    "weapon_swcs_asval",
    "weapon_swcs_gry",
}

local SNIPER = {
    "weapon_swcs_awp",
    "weapon_swcs_g3sg1",
    "weapon_swcs_scar20",
    "weapon_swcs_ssg08",

    "weapon_swcs_g2",
}

hook.Add("OnEntityCreated", "swcs_hl2", function(ent)
    if not IsValid(ent) then return end

    timer.Simple(0, function()
        if not IsValid(ent) then return end
        if ent:IsNPC() then
            local wep = ent:GetActiveWeapon()

            if IsValid(wep) then
                local class = wep:GetClass()
                local newWep
                if class == "weapon_pistol" then
                    newWep = PISTOL[math.random(#PISTOL)]
                elseif class == "weapon_357" then
                    newWep = HEAVY_PISTOL[math.random(#HEAVY_PISTOL)]
                elseif class == "weapon_smg1" then
                    newWep = SMG[math.random(#SMG)]
                elseif class == "weapon_ar2" then
                    newWep = RIFLE[math.random(#RIFLE)]
                elseif class == "weapon_shotgun" then
                    newWep = SHOTGUN[math.random(#SHOTGUN)]
                elseif class == "weapon_crossbow" then
                    newWep = SNIPER[math.random(#SNIPER)]
                end

                if newWep then
                    local wepEnt = ent:Give(newWep)
                    ent:SelectWeapon(wepEnt)
                end
            end
        elseif ent:IsWeapon() then
            if IsValid(ent:GetOwner()) then return end

            local class = ent:GetClass()
            local newWep
            if class == "weapon_pistol" then
                newWep = PISTOL[math.random(#PISTOL)]
            elseif class == "weapon_357" then
                newWep = HEAVY_PISTOL[math.random(#HEAVY_PISTOL)]
            elseif class == "weapon_smg1" then
                newWep = SMG[math.random(#SMG)]
            elseif class == "weapon_ar2" then
                newWep = RIFLE[math.random(#RIFLE)]
            elseif class == "weapon_shotgun" then
                newWep = SHOTGUN[math.random(#SHOTGUN)]
            elseif class == "weapon_crossbow" then
                newWep = SNIPER[math.random(#SNIPER)]
            elseif class == "weapon_frag" then
                newWep = "weapon_swcs_hegrenade"
            end

            if newWep then
                local wep = ents.Create(newWep)
                wep:SetAngles(ent:GetAngles())
                wep:SetPos(ent:GetPos())
                wep:Spawn()

                SafeRemoveEntity(ent)
            end
        end
    end)
end)

--[[hook.Add("PlayerSpawn", "swcs_hl2", function(ply)
    ply:StripWeapon("weapon_pistol")
    ply:StripWeapon("weapon_357")
    ply:StripWeapon("weapon_smg1")
    ply:StripWeapon("weapon_ar2")
    ply:StripWeapon("weapon_shotgun")
    ply:StripWeapon("weapon_crossbow")
    ply:StripWeapon("weapon_grenade")
end)--]]

local STOCK = {
    weapon_pistol = true,
    weapon_357 = true,
    weapon_smg1 = true,
    weapon_ar2 = true,
    weapon_shotgun = true,
    weapon_crossbow = true,
}
hook.Add("PlayerCanPickupWeapon", "swcs_hl2", function(ply, wep)
    local class = wep:GetClass()
    if STOCK[class] then return false end
    if class == "weapon_frag" then
        if not ply:HasWeapon("weapon_swcs_hegrenade") then ply:Give("weapon_swcs_hegrenade") end
        SafeRemoveEntity(wep)
        return false
    elseif class == "weapon_swcs_hegrenade" then
        if ply:HasWeapon("weapon_swcs_hegrenade") and ply:GetAmmoCount("Grenade") < game.GetAmmoMax(game.GetAmmoID("Grenade")) then
            ply:GiveAmmo(1, "Grenade")
            SafeRemoveEntity(wep)
            return false
        else
            return true
        end
    end
end)
