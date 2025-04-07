local string = string

local IsValid = IsValid
local RunConsoleCommand = RunConsoleCommand

local TAG = "actx"
local ACTX_EVENT = 61637478 -- "actx" in hex codepoints

local taunts = {
	forward = ACT_SIGNAL_FORWARD,
	group = ACT_SIGNAL_GROUP,
	halt = ACT_SIGNAL_HALT,
	agree = ACT_GMOD_GESTURE_AGREE,
	becon = ACT_GMOD_GESTURE_BECON,
	bow = ACT_GMOD_GESTURE_BOW,
	disagree = ACT_GMOD_GESTURE_DISAGREE,
	salute = ACT_GMOD_TAUNT_SALUTE,
	wave = ACT_GMOD_GESTURE_WAVE,
	pers = ACT_GMOD_TAUNT_PERSISTENCE,
	muscle = ACT_GMOD_TAUNT_MUSCLE,
	laugh = ACT_GMOD_TAUNT_LAUGH,
	cheer = ACT_GMOD_TAUNT_CHEER,
	zombie = ACT_GMOD_GESTURE_TAUNT_ZOMBIE,
	dance = ACT_GMOD_TAUNT_DANCE,
	robot = ACT_GMOD_TAUNT_ROBOT,
	attack = ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL,
	frenzy = ACT_GMOD_GESTURE_RANGE_FRENZY,
	give = ACT_GMOD_GESTURE_ITEM_GIVE,
	drop = ACT_GMOD_GESTURE_ITEM_DROP,
	place = ACT_GMOD_GESTURE_ITEM_PLACE,
	throw = ACT_GMOD_GESTURE_ITEM_THROW,
	shove = ACT_GMOD_GESTURE_MELEE_SHOVE_1HAND,
	melee = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE,
	melee2 = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2,
	poke = ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM,
	fist = ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST,
	stab = ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE,
	death_1 = ACT_GMOD_DEATH,
	death_2 = ACT_GMOD_DEATH,
	death_3 = ACT_GMOD_DEATH,
	death_4 = ACT_GMOD_DEATH,
}

local sequence_overrides = {
	-- blame custom taunt animations for these two
	dance = "taunt_dance",
	laugh = "taunt_laugh",

	-- randomized death anims cringe
	death_1 = "death_01",
	death_2 = "death_02",
	death_3 = "death_03",
	death_4 = "death_04",
}

local vanilla = {}
for name in next, taunts do
	vanilla[name] = true
end

local categories = {}

local name_overrides = {}

if wOS and wOS.DynaBase then
	if wOS.DynaBase.Registers["Vuthakral's Extended Player Animations"] then
		taunts.flinch = ACT_GESTURE_FLINCH_BLAST
		taunts.kick = ACT_MP_STAND_MELEE
		taunts.curbstomp = ACT_MP_ATTACK_STAND_MELEE_SECONDARY
		taunts.pickup = ACT_PICKUP_GROUND

		categories["Extended Player Animations"] = {
			flinch = true,
			kick = true,
			curbstomp = true,
			pickup = true,
		}
	end

	if wOS.DynaBase.Registers["Custom Taunt Extension"] then
		local mmd_names = {
			"Deep Blue Town",
			"Suki Yuki Maji Magic",
			"Marine Dreamin",
			"Happy Halloween",
			"Marine Bloomin",
			"Onegai Darling",
			"Project DIVA - Shake it!",
			"Project DIVA - World is Mine",
			"O-share is Noko-ism！",
			"Project DIVA - Ai no Uta (Love Song)",
			"Project DIVA - Popipo",
			"Project DIVA - Ievan Polkka",
			"Project DIVA - Cute Medley",
			"Project DIVA - Age Age Again",
			"Project DIVA - Skeleton Orchestra and Lilia",
			"Project DIVA - Beauty Medley 1",
			"Project DIVA - Beauty Medley 2",
			"Project DIVA - Beauty Medley 3",
			"Project DIVA - Chaos Medley 1",
			"Project DIVA - Chaos Medley 2",
			"Project DIVA - Chaos Medley 3",
			"Kimagure Mercy",
			"Project DIVA - Melancholic",
			"Project DIVA - Luka Luka★Night Fever",
			"Project DIVA - Meltdown",
			"Project DIVA - Weekender Girl",
			"Project DIVA - Satisfaction",
			"Project DIVA - Hand in Hand",
			"Project DIVA - Yellow",
			"Project DIVA - Double Lariat",
		}
		categories["Custom Taunt - MMD"] = {}
		for i = 1, 30 do
			local taunt = "ct_dance_" .. i
			taunts[taunt] = ACT_GMOD_TAUNT_DANCE
			sequence_overrides[taunt] = "original_dance" .. i
			name_overrides[taunt] = mmd_names[i]
			categories["Custom Taunt - MMD"][taunt] = true
		end

		local fortnite = {
			"f_Hit_The_Woah",
			"f_Dust_Off_Shoulders",
			"f_DJ_Drop",
			"f_Luchador",
			"f_Spray",
			"f_Toss",
			"f_TreadmillDance",
			"f_Dance_Worm",
			"f_Peely_Blender",
			"f_PogoTraversal",
			"f_Calculated",
			"f_RobotDance",
			"f_Llama",
			"f_Trophy_Celebration",
			"f_Dunk",
			"f_GolfClap",
			"f_Pump_Dance",
			"f_TRex",
			"f_Fresh",
			"f_Rooster_Mech",
			"f_Dance_Disco_T3",
			"f_Hotstuff",
			"f_UkuleleTime",
			"f_CrazyDance",
			"f_ThighSlapper",
			"f_Assassin_Vest",
			"f_AirHorn",
			"f_Dust_Off_Hands",
			"f_Headbanger",
			"f_IDontKnow",
			"f_Octopus",
			"f_LivingLarge",
			"f_Hip_Hop",
			"f_Flamenco",
			"f_Wrist_Flick",
			"f_CrazyFeet",
			"f_TPose",
			"f_Juggler",
			"f_Shaka",
			"f_Yeet",
			"f_Crackshot",
			"f_LlamaMarch",
			"f_Head_Bounce",
			"f_Hitchhiker",
			"f_Dance_SwipeIt",
			"f_Epic_Sax_Guy",
			"f_TaiChi",
			"f_BandOfTheFort",
			"f_BlackMonday_Female",
			"f_Salute",
			"f_JumpingJack",
			"f_WackyInflatable",
			"f_BunnyHop",
			"f_PraiseTheTomato",
			"f_Blow_Kiss",
			"f_Hi_Five_Slap",
			"f_Happy_Wave",
			"f_HoldOnAMinute",
			"f_TechnoZombie",
			"f_Halloween_Candy",
			"f_Eastern_Bloc",
			"f_The_Alien",
			"f_Lazy_Shuffle",
			"f_Mime",
			"f_StatuePose",
			"f_Kpop_03",
			"f_Smooth_Ride",
			"f_IceKing",
			"f_RideThePony",
			"f_Candy_Dance",
			"f_Take_The_Elf",
			"f_HandstandLeg_Dab",
			"f_Dancing_Girl",
			"f_OneArmFloss",
			"f_Gabby_HipHop",
			"f_Strawberry_Pilot",
			"f_RespectThePeace",
			"f_Battle_Horn",
			"f_Hula",
			"f_HiLoWave",
			"f_Sprinkler",
			"f_Basketball_Tricks",
			"f_RideThePony_v2",
			"f_Switch_Witch_Bad2Good",
			"f_Switch_Witch_Good2Bad",
			"f_Golfer_Clap",
			"f_YayExcited",
			"f_Zippy_Dance",
			"f_DarkFireLegends",
			"f_Present_Opening",
			"f_Spyglass",
			"f_TheQuickSweeper",
			"f_GoatDance",
			"f_PumpkinDance",
			"f_HappySkipping",
			"f_CactusTpose",
			"f_Bring_It_On",
			"f_GlowStickDance",
			"f_Dance_Shoot",
			"f_Wave_Dance",
			"f_Breakboy",
			"f_Torch_Snuffer",
			"f_BlackMonday",
			"f_Flex_02",
			"f_Texting",
			"f_PopLock",
			"f_Laugh",
			"f_Regal_Wave",
			"f_Chicken_Moves",
			"f_OG_RunningMan",
			"f_Maracas",
			"f_Accolades",
			"f_SomethingStinks",
			"f_GothDance",
			"f_KungFu_Salute",
			"f_RockPaperScissor_Rock",
			"f_KungFu_Shadowboxing",
			"f_Running",
			"f_Shinobi",
			"f_KoreanEagle",
			"f_BlackMondayFight",
			"f_ThumbsUp",
			"f_HulaHoopChallenge",
			"f_RageQuit",
			"f_SpeedRun",
			"f_WarehouseDance",
			"f_Flex",
			"f_Hopper",
			"f_Assassin_Salute",
			"f_Burpee",
			"f_AerobicChamp",
			"f_Rock_Guitar",
			"f_StageBow",
			"f_HipHop_01",
			"f_Conga",
			"f_Grooving",
			"f_WindmillFloss",
			"f_Chug",
			"f_Eating_Popcorn",
			"f_FlippnSexy",
			"f_Ashton_Boardwalk_v2",
			"f_Mic_Drop",
			"f_MartialArts",
			"f_Cheerleader",
			"f_Basketball",
			"f_Hip_Hop_Gestures_1",
			"f_Cry",
			"f_Celebration",
			"f_SoccerJuggling",
			"f_Kitty_Cat",
			"f_FancyFeet",
			"f_Festivus",
			"f_ZombieWalk",
			"f_Bendi",
			"f_Funk_Time",
			"f_PizzaTime",
			"f_BlowingBubbles",
			"f_TacoTime",
			"f_Jaywalk",
			"f_ClapperBoard",
			"f_GunSpinnerTeacup",
			"f_Fistpump_Celebration",
			"f_Drum_Major",
			"f_Dumbbell_Lift",
			"f_DreamFeet",
			"f_Facepalm",
			"f_ElectroShuffle2",
			"f_Rocket_Rodeo",
			"f_ArmWave",
			"f_BBD",
			"f_Hooked",
			"f_IrishJig",
			"f_Wiggle",
			"f_Swim_Dance",
			"f_FingerGunsV2",
			"f_Kpop_02",
			"f_IndiaDance",
			"f_SuckerPunch",
			"f_ShadowBoxer",
			"f_BalletSpin",
			"f_HillBilly_Shuffle",
			"f_Sad_Trombone",
			"f_Mello",
			"f_Take_the_W",
			"f_Pirate_Gold",
			"f_Sit_and_Spin",
			"f_Mind_Blown",
			"f_Charleston",
			"f_Chicken",
			"f_BurgerFlipping",
			"f_Dance_Off",
			"f_HandSignals",
			"f_ThumbsDown",
			"f_Scorecard",
			"f_Touchdown_Dance",
			"f_Wheres_Matt",
			"f_SmokeBombFail",
			"f_DanceMoves",
			"f_Wave2",
			"f_Runningv3",
			"f_FrisbeeShow",
			"f_Hip_Hop_S7",
			"f_Look_At_This",
			"f_Wizard",
			"f_Youre_Awesome",
			"f_Mask_Off",
			"f_Twist",
			"f_TimetravelBackflip",
			"f_Sneaky",
			"f_Break_Dance",
			"f_ProtestAlien",
			"f_Sparkles",
			"f_Cowbell",
			"f_Doublesnap",
			"f_FlossDance",
			"f_DeepDab",
			"f_Moonwalking",
			"f_I_Break_You",
			"f_FireStick",
			"f_NeedToPee",
			"f_DG_Disco",
			"f_Acrobatic_Superhero",
			"f_GrooveJam",
			"f_Floppy_Dance",
			"f_InfiniDab",
			"f_LazerDance",
			"f_AfroHouse",
			"f_Break_Dance_v2",
			"f_HulaHoop",
			"f_Intensity",
			"f_Make_It_Rain_V2",
			"f_Guitar_Walk",
			"f_LazerFlex",
			"f_KPop_Dance03",
			"f_Shaolin",
			"f_Davinci",
			"f_Wolf_Howl",
			"f_HipToBeSquare",
			"f_Marat",
			"f_SignSpinner",
			"f_ElectroSwing",
			"f_Cartwheel",
			"f_Jazz_Hands",
			"f_TimeOut",
			"f_Heelclick",
			"f_Snap",
			"f_Fonzie_Pistol",
			"f_CowboyDance",
			"f_Loser_Dance",
			"f_Chopstick",
			"f_Kpop_04",
			"f_Banana",
			"f_SkeletonDance",
			"f_You_Bore_Me",
			"f_Cool_Robot",
			"f_PinWheelSpin",
			"f_Jazz_Dance",
			"f_Security_Guard",
			"f_Showstopper_Dance",
			"f_MyIdol",
			"f_Disagree",
			"f_RedCard",
			"f_Crab_Dance",
			"f_ArmUp",
			"f_IHeartYou",
			"f_Capoeira",
			"f_SwingDance",
			"f_Confused",
			"f_Cross_Legs",
			"f_FancyWorkout",
			"f_Dance_NoBones",
			"f_Jammin",
			"f_Boogie_Down",
			"f_DivinePose",
			"f_TomatoThrow",
			"f_Salt",
		}

		categories["Custom Taunt - Fortnite"] = {}
		for _, taunt in ipairs(fortnite) do
			taunts[taunt] = ACT_GMOD_TAUNT_LAUGH
			categories["Custom Taunt - Fortnite"][taunt] = true
			sequence_overrides[taunt] = taunt
		end
	end
end

do -- animation sequence overrides
	hook.Add("CalcMainActivity", TAG, function(ply)
		if not IsValid(ply) then return end
		local taunt = ply:GetNW2String("actx_taunt", "")
		if not taunt or taunt == "" then return end
		local start = ply:GetNW2Float("actx_start", 0)
		if not start or start == 0 then return end

		local act = taunts[taunt]
		if not act then return end
		local seq = sequence_overrides[taunt]
		if not seq then return end

		local seq_id = ply:LookupSequence(seq)
		if not seq_id or seq_id == -1 then return end

		local len = ply:SequenceDuration(seq_id)
		if CurTime() > start + len then
			if SERVER then
				ply:SetNW2String("actx_taunt", "")
				ply:SetNW2Float("actx_start", 0)
			end
			return
		end

		return ACT_INVALID, seq_id
	end)

	hook.Add("DoAnimationEvent", TAG, function(ply, event, data)
		if not IsValid(ply) then return end

		local taunt = ply:GetNW2String("actx_taunt", "")
		local act = taunts[taunt]
		local seq = sequence_overrides[taunt]

		-- prevent animation resetting when we get a new event (e.g. jumping)
		if taunt and taunt ~= "" and act and seq and data ~= ACTX_EVENT then
			return act
		end

		if event == PLAYERANIMEVENT_CUSTOM_SEQUENCE and data == ACTX_EVENT then
			if not taunt or taunt == "" then return ACT_INVALID end

			if not act then return ACT_INVALID end
			if not seq then return ACT_INVALID end

			local seq_id = ply:LookupSequence(seq)
			if not seq_id or seq_id == -1 then return ACT_INVALID end

			ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
			ply:AnimSetGestureSequence(GESTURE_SLOT_CUSTOM, seq_id)
			ply:AnimRestartMainSequence()

			return act
		end
	end)

	hook.Add("UpdateAnimation", TAG, function(ply, vel, ground)
		local taunt = ply:GetNW2String("actx_taunt", "")
		local act = taunts[taunt]
		local seq = sequence_overrides[taunt]

		if taunt and taunt ~= "" and act and seq then
			ply:SetPlaybackRate(1)
			return true
		end
	end)
end

local function actx_autocomplete(cmd, argStr)
	local completions = {}

	for name in next, taunts do
		if string.find(name, string.sub(argStr, 2, -1), 1, true) or #argStr < 2 then
			completions[#completions + 1] = cmd .. " " .. name
		end
	end

	return completions
end

if SERVER then
	concommand.Add(TAG, function(ply, cmd, args, argStr)
		local taunt = args[1]
		if not taunt or taunt == "" then return end

		local act = taunts[taunt]
		if act == nil then
			ply:ChatPrint(string.format("Unknown act: %q", taunt))
			return
		end

		if hook.Run("PlayerShouldTaunt", ply, act) == false then return end

		local sequence = sequence_overrides[taunt]
		if sequence ~= nil then
			ply:SetNW2String("actx_taunt", taunt)
			ply:SetNW2Float("actx_start", CurTime())
			ply:DoCustomAnimEvent(PLAYERANIMEVENT_CUSTOM_SEQUENCE, ACTX_EVENT)
		else
			ply:DoAnimationEvent(act)
		end
	end, actx_autocomplete, "Extended act command")
elseif CLIENT then
	concommand.Add(TAG, function(ply, cmd, args, argStr)
		RunConsoleCommand("cmd", cmd, unpack(args))
	end, actx_autocomplete, "Extended act command")

	local function nice_name(str)
		local override = name_overrides[str]
		if override then return override end

		if string.find(str, "^f_") then
			str = string.sub(str, 3)
		end

		local parts = string.Explode("_", str, false)
		for i, p in ipairs(parts) do
			parts[i] = string.gsub(p, "^.", string.upper)
		end

		return table.concat(parts, " ")
	end

	hook.Add("PopulateMenuBar", TAG, function(menubar)
		local sorted_taunts = table.GetKeys(taunts)
		table.sort(sorted_taunts)

		local act = menubar:AddOrGetMenu("Act")

		for _, taunt in ipairs(sorted_taunts) do
			if vanilla[taunt] then
				act:AddOption(nice_name(taunt), function()
					RunConsoleCommand("actx", taunt)
				end)
			end
		end

		if table.Count(categories) > 0 then
			act:AddSpacer()

			for c_name, category in next, categories do
				local sorted = table.GetKeys(category)
				table.sort(sorted)

				local submenu = act:AddSubMenu(c_name)
				submenu:SetDeleteSelf(false)

				for _, taunt in ipairs(sorted) do
					submenu:AddOption(nice_name(taunt), function()
						RunConsoleCommand("actx", taunt)
					end)
				end
			end
		end
	end)
end
