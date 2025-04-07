local ammoTypes = {
    ["Pistol"] = true,
    ["SMG1"] = true,
    ["grenade"] = true,
    ["Buckshot"] = true,
    ["357"] = true,
    ["XBowBolt"] = true,
    ["AR2AltFire"] = true,
    ["AR2"] = true,
}

hook.Add("PlayerLoadout", "OverrideLoadout", function(ply)
    ply:RemoveAllAmmo()

    for ammo in pairs(ammoTypes) do
        local id = game.GetAmmoID(ammo)
        ply:GiveAmmo(game.GetAmmoMax(id), ammo, true)
    end

    ply:Give("gmod_tool")
    ply:Give("gmod_camera")
    ply:Give("weapon_physgun")
    ply:Give("weapon_physcannon")
    ply:Give("weapon_crowbar")
    ply:Give("hands")

    ply:SelectWeapon("hands")

    return true
end)