hook.Add("PostGamemodeLoaded", "SandboxMovementFix", function()
    local PLAYER_CLASS = player_manager.GetPlayerClasses().player_sandbox

    function PLAYER_CLASS:StartMove(mv)
    end

    function PLAYER_CLASS:FinishMove(mv)
    end

    player_manager.RegisterClass("player_sandbox", PLAYER_CLASS, "player_default")
end)