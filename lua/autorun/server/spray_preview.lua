hook.Add("PlayerSpray", "spray_preview", function(ply)
    -- wait two ticks because you can call AllowImmediateDecalPainting on the first tick, bypassing decalfrequency
    timer.Simple(0, function()
        timer.Simple(0, function()
            ply:SetNW2Float("spray_preview_next", CurTime() + ply:GetInternalVariable("m_flNextDecalTime"))
        end)
    end)
end)
