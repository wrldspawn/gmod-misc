local TAG = "HoldToUndo"

local start = 0
local endTime = 0
local cooldown = 0
hook.Add("InputMouseApply", TAG, function()
	local keyCode = input.GetKeyCode(input.LookupBinding("gmod_undo", true))
	if not keyCode then
		keyCode = input.GetKeyCode(input.LookupBinding("undo", true))
	end
	if not keyCode then return end

	local pressed = input.IsKeyDown(keyCode)
	if CurTime() > cooldown and start == 0 and pressed then
		start = CurTime() + 1
	elseif start ~= 0 and CurTime() > start and (endTime == 0 or endTime > CurTime()) and pressed then
		if endTime == 0 then
			endTime = CurTime() + 3
		end
		notification.AddProgress(TAG, Format("Undoing all in %d", math.floor(endTime - CurTime()) + 1))
	elseif start ~= 0 and endTime ~= 0 and CurTime() > endTime and pressed then
		RunConsoleCommand("gmod_cleanup")
		notification.Kill(TAG)

		start = 0
		endTime = 0
		cooldown = CurTime() + 10
	elseif not pressed then
		notification.Kill(TAG)

		start = 0
		endTime = 0
	end
end)
