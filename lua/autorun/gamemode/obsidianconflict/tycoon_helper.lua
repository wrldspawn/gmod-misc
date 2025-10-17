local TAG = "tycoon_helper"
local MAPNAME = game.GetMap():lower()

local SUPPORTED = {
	oc_harvest = true,
	oc_paysan_b11 = true,
	oc_restaurant_v33_25_1 = true,
	oc_diving_v9 = true,
}

if not SUPPORTED[MAPNAME] then return end

if SERVER then
	if MAPNAME == "oc_harvest" then
		local function setup_map()
			timer.Simple(engine.TickInterval() * 2, function()
				local Clock = ents.FindByName("Clock")[1]
				if not Clock then
					Msg("[Tycoon Helper] ")
					print("BAD MAP VERSION, missing countdown timer entity")
					return
				end

				Clock:SetLabel("Day Ends In")

				local Day_Timer = ents.FindByName("Day_Timer")[1]
				if not Day_Timer then
					Msg("[Tycoon Helper] ")
					print("BAD MAP VERSION, missing day timer somehow")
					return
				end
				local Day_TimerAlarm = ents.FindByName("Day_TimerAlarm")[1]
				if not Day_TimerAlarm then
					Msg("[Tycoon Helper] ")
					print("BAD MAP VERSION, missing alarm day timer somehow")
					return
				end

				Day_Timer:Fire("AddOutput", "OnTrigger Clock:StartTimer:151:0:-1")
				Day_TimerAlarm:Fire("AddOutput", "OnTrigger Clock:StartTimer:301:0:-1")
			end)
		end

		hook.Add("InitPostEntity", TAG, setup_map)
		hook.Add("PostCleanupMap", TAG, setup_map)
	elseif MAPNAME == "oc_paysan_b11" then
		local function setup_map()
			timer.Simple(engine.TickInterval() * 2, function()
				local Clock = ents.Create("game_countdown_timer")
				Clock:SetName("Clock")
				Clock:Spawn()
				Clock:SetLabel("Day Ends In")

				local day = ents.FindByName("day")[1]
				if not day then
					Msg("[Tycoon Helper] ")
					print("BAD MAP VERSION, missing day timer somehow")
					return
				end

				day:Fire("AddOutput", "OnTimer Clock:StartTimer:301:25:-1")

				local close_pawn = ents.FindByName("close_pawn")[1]
				if not close_pawn then
					Msg("[Tycoon Helper] ")
					print("BAD MAP VERSION, missing pawn shop counter")
					return
				end

				close_pawn:Fire("AddOutput", "OnHitMax !self:TycoonHelper_PawnShop:1:0:-1")

				local tunel_count = ents.FindByName("tunel_count")[1]
				if not tunel_count then
					Msg("[Tycoon Helper] ")
					print("BAD MAP VERSION, missing tunnel counter")
					return
				end

				tunel_count:Fire("AddOutput", "OnHitMax !self:TycoonHelper_CityOpen:1:0:-1")

				local case_evennements = ents.FindByName("case_evennements")[1]
				if not case_evennements then
					Msg("[Tycoon Helper] ")
					print("BAD MAP VERSION, missing random events logic")
					return
				end

				case_evennements:Fire("AddOutput", "OnCase02 !self:TycoonHelper_CityClose:1:0:-1")
			end)
		end

		hook.Add("InitPostEntity", TAG, setup_map)
		hook.Add("PostCleanupMap", TAG, setup_map)

		hook.Add("AcceptInput", TAG, function(ent, inp, actor, caller, data)
			if inp == "TycoonHelper_PawnShop" then
				PrintMessage(HUD_PRINTTALK, "Pawn shop is closed today")
			elseif inp == "TycoonHelper_CityOpen" then
				PrintMessage(HUD_PRINTTALK, "The tunnel to the city is clear")
			elseif inp == "TycoonHelper_CityClose" then
				PrintMessage(HUD_PRINTTALK, "The tunnel to the city needs to be cleared")
			end
		end)
	end
end
