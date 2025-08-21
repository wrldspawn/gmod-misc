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

	local has_uap = false
	for k in next, wOS.DynaBase.Registers do
		if k:find("^Ultimate Animation Pack - ") then
			has_uap = true
			break
		end
	end

	if has_uap then
		local function uap_nice_name(str)
			str = str:gsub("^wOS_UAP_[a-zA-Z0-9]+_", "")

			local parts = string.Explode("_", str, false)
			for i, p in ipairs(parts) do
				parts[i] = string.gsub(p, "^.", string.upper)
			end

			return table.concat(parts, " ")
		end

		local fortnite = {
			"wOS_UAP_Fortnite_resistance_thumbs_up",
			"wOS_UAP_Fortnite_respect",
			"wOS_UAP_Fortnite_respect_the_peace",
			"wOS_UAP_Fortnite_revel",
			"wOS_UAP_Fortnite_ribbon_dancer",
			"wOS_UAP_Fortnite_ride_the_pony",
			"wOS_UAP_Fortnite_rock_out",
			"wOS_UAP_Fortnite_running_man",
			"wOS_UAP_Fortnite_sad_claps",
			"wOS_UAP_Fortnite_salute",
			"wOS_UAP_Fortnite_sasquatchin",
			"wOS_UAP_Fortnite_savor_the_w",
			"wOS_UAP_Fortnite_scenario",
			"wOS_UAP_Fortnite_secret_hand_shake",
			"wOS_UAP_Fortnite_shadow_boxer",
			"wOS_UAP_Fortnite_shadow_spar",
			"wOS_UAP_Fortnite_shake_it_up",
			"wOS_UAP_Fortnite_shaolin_sit_up",
			"wOS_UAP_Fortnite_sharpshooter",
			"wOS_UAP_Fortnite_shimmer",
			"wOS_UAP_Fortnite_showstopper",
			"wOS_UAP_Fortnite_side_hustle",
			"wOS_UAP_Fortnite_sign_protest",
			"wOS_UAP_Fortnite_sign_spinner",
			"wOS_UAP_Fortnite_signature_shuffle",
			"wOS_UAP_Fortnite_sizzlin",
			"wOS_UAP_Fortnite_slap_happy",
			"wOS_UAP_Fortnite_slick",
			"wOS_UAP_Fortnite_slitherin",
			"wOS_UAP_Fortnite_slow_clap",
			"wOS_UAP_Fortnite_smooth_moves",
			"wOS_UAP_Fortnite_snap",
			"wOS_UAP_Fortnite_snoozefest",
			"wOS_UAP_Fortnite_so_square",
			"wOS_UAP_Fortnite_something_stinks",
			"wOS_UAP_Fortnite_spike_it",
			"wOS_UAP_Fortnite_spring_loaded",
			"wOS_UAP_Fortnite_springy",
			"wOS_UAP_Fortnite_sprinkler",
			"wOS_UAP_Fortnite_squat_kick",
			"wOS_UAP_Fortnite_squat_kick_intro",
			"wOS_UAP_Fortnite_star_power",
			"wOS_UAP_Fortnite_statuesque",
			"wOS_UAP_Fortnite_step_it_up",
			"wOS_UAP_Fortnite_stride",
			"wOS_UAP_Fortnite_strut",
			"wOS_UAP_Fortnite_sugar_rush",
			"wOS_UAP_Fortnite_swipe_it",
			"wOS_UAP_Fortnite_switch_step",
			"wOS_UAP_Fortnite_t_pose",
			"wOS_UAP_Fortnite_taco_time",
			"wOS_UAP_Fortnite_tai_chi",
			"wOS_UAP_Fortnite_take_the_l",
			"wOS_UAP_Fortnite_taxi",
			"wOS_UAP_Fortnite_the_renegade",
			"wOS_UAP_Fortnite_the_robot",
			"wOS_UAP_Fortnite_thumbs_down",
			"wOS_UAP_Fortnite_thumbs_up",
			"wOS_UAP_Fortnite_tidy",
			"wOS_UAP_Fortnite_time_out",
			"wOS_UAP_Fortnite_tippy_tap",
			"wOS_UAP_Fortnite_toosie_slide",
			"wOS_UAP_Fortnite_tra_la_la",
			"wOS_UAP_Fortnite_travis_stage_dance",
			"wOS_UAP_Fortnite_true_heart",
			"wOS_UAP_Fortnite_tsss",
			"wOS_UAP_Fortnite_turbocharged",
			"wOS_UAP_Fortnite_twist",
			"wOS_UAP_Fortnite_unification",
			"wOS_UAP_Fortnite_verve",
			"wOS_UAP_Fortnite_very_sneaky",
			"wOS_UAP_Fortnite_vibin",
			"wOS_UAP_Fortnite_vivacious",
			"wOS_UAP_Fortnite_waddle_away",
			"wOS_UAP_Fortnite_waterworks",
			"wOS_UAP_Fortnite_wave",
			"wOS_UAP_Fortnite_wavy_t",
			"wOS_UAP_Fortnite_well_rounded",
			"wOS_UAP_Fortnite_where_is_matt",
			"wOS_UAP_Fortnite_whirlwind",
			"wOS_UAP_Fortnite_widows_pirouette",
			"wOS_UAP_Fortnite_wiggle",
			"wOS_UAP_Fortnite_windmill_floss",
			"wOS_UAP_Fortnite_work_it",
			"wOS_UAP_Fortnite_work_it_out",
			"wOS_UAP_Fortnite_worm",
			"wOS_UAP_Fortnite_yay",
			"wOS_UAP_Fortnite_you_are_awesome",
			"wOS_UAP_Fortnite_zany",
			"wOS_UAP_Fortnite_zombified_still",
			"wOS_UAP_Fortnite_go_go_go",
			"wOS_UAP_Fortnite_golf_clap",
			"wOS_UAP_Fortnite_groove_jam",
			"wOS_UAP_Fortnite_ground_pound",
			"wOS_UAP_Fortnite_guitar_walk",
			"wOS_UAP_Fortnite_gun_show",
			"wOS_UAP_Fortnite_hand_signals",
			"wOS_UAP_Fortnite_hang_loose",
			"wOS_UAP_Fortnite_hang_on",
			"wOS_UAP_Fortnite_harmony",
			"wOS_UAP_Fortnite_headbanger",
			"wOS_UAP_Fortnite_headbanger_alt",
			"wOS_UAP_Fortnite_hello_friend",
			"wOS_UAP_Fortnite_hemlock_bad_to_good",
			"wOS_UAP_Fortnite_hemlock_good_to_bad",
			"wOS_UAP_Fortnite_hitchhiker",
			"wOS_UAP_Fortnite_hoop_master",
			"wOS_UAP_Fortnite_hootenanny",
			"wOS_UAP_Fortnite_hot_marat",
			"wOS_UAP_Fortnite_howl",
			"wOS_UAP_Fortnite_hula",
			"wOS_UAP_Fortnite_hype",
			"wOS_UAP_Fortnite_idk",
			"wOS_UAP_Fortnite_idle_astro_jack",
			"wOS_UAP_Fortnite_idle_catwoman",
			"wOS_UAP_Fortnite_idle_director",
			"wOS_UAP_Fortnite_idle_eternal_voyager",
			"wOS_UAP_Fortnite_idle_grim_fable",
			"wOS_UAP_Fortnite_idle_ice_king",
			"wOS_UAP_Fortnite_idle_star_lord",
			"wOS_UAP_Fortnite_idle_stratus",
			"wOS_UAP_Fortnite_idle_tempest",
			"wOS_UAP_Fortnite_idle_the_devourer",
			"wOS_UAP_Fortnite_idle_zero",
			"wOS_UAP_Fortnite_infectious",
			"wOS_UAP_Fortnite_infinidab",
			"wOS_UAP_Fortnite_intensity",
			"wOS_UAP_Fortnite_introducing",
			"wOS_UAP_Fortnite_its_complicated",
			"wOS_UAP_Fortnite_jamboree",
			"wOS_UAP_Fortnite_jaywalking",
			"wOS_UAP_Fortnite_jazz_hands",
			"wOS_UAP_Fortnite_jitterbug",
			"wOS_UAP_Fortnite_job_well_done",
			"wOS_UAP_Fortnite_jubilation",
			"wOS_UAP_Fortnite_jump_jets",
			"wOS_UAP_Fortnite_jumping_jacks",
			"wOS_UAP_Fortnite_keep_it_mello",
			"wOS_UAP_Fortnite_keep_it_mello_2",
			"wOS_UAP_Fortnite_keep_it_mello_3",
			"wOS_UAP_Fortnite_kiss_kiss",
			"wOS_UAP_Fortnite_knee_slapper",
			"wOS_UAP_Fortnite_laid_back_shuffle",
			"wOS_UAP_Fortnite_laugh_it_up",
			"wOS_UAP_Fortnite_lavish",
			"wOS_UAP_Fortnite_lazer_blast",
			"wOS_UAP_Fortnite_lazy_shuffle",
			"wOS_UAP_Fortnite_leapin",
			"wOS_UAP_Fortnite_levitate",
			"wOS_UAP_Fortnite_living_large",
			"wOS_UAP_Fortnite_llama_conga",
			"wOS_UAP_Fortnite_lock_it_up",
			"wOS_UAP_Fortnite_make_it_rain",
			"wOS_UAP_Fortnite_marsh_walk",
			"wOS_UAP_Fortnite_martial_arts_master",
			"wOS_UAP_Fortnite_mime_time",
			"wOS_UAP_Fortnite_mind_blown",
			"wOS_UAP_Fortnite_moon_bounce",
			"wOS_UAP_Fortnite_my_idol",
			"wOS_UAP_Fortnite_nana_nana",
			"wOS_UAP_Fortnite_never_gonna",
			"wOS_UAP_Fortnite_ninja_style",
			"wOS_UAP_Fortnite_no_sweat",
			"wOS_UAP_Fortnite_old_school",
			"wOS_UAP_Fortnite_orange_justice",
			"wOS_UAP_Fortnite_out_west",
			"wOS_UAP_Fortnite_overdrive",
			"wOS_UAP_Fortnite_party_hips",
			"wOS_UAP_Fortnite_paws_and_claws",
			"wOS_UAP_Fortnite_peace_out",
			"wOS_UAP_Fortnite_peely_pulse",
			"wOS_UAP_Fortnite_phew",
			"wOS_UAP_Fortnite_pick_it_up",
			"wOS_UAP_Fortnite_pirouette",
			"wOS_UAP_Fortnite_planetary_vibe",
			"wOS_UAP_Fortnite_point_it_out",
			"wOS_UAP_Fortnite_poki",
			"wOS_UAP_Fortnite_pop_lock",
			"wOS_UAP_Fortnite_power_roar",
			"wOS_UAP_Fortnite_prickly_pose",
			"wOS_UAP_Fortnite_primo_moves",
			"wOS_UAP_Fortnite_pump_it_up",
			"wOS_UAP_Fortnite_pumpernickel",
			"wOS_UAP_Fortnite_punched_up",
			"wOS_UAP_Fortnite_pure_salt",
			"wOS_UAP_Fortnite_rage_quit",
			"wOS_UAP_Fortnite_rambunctious",
			"wOS_UAP_Fortnite_rawr",
			"wOS_UAP_Fortnite_reanimated",
			"wOS_UAP_Fortnite_regal_wave",
			"wOS_UAP_Fortnite_advanced_math",
			"wOS_UAP_Fortnite_balletic",
			"wOS_UAP_Fortnite_be_seeing_you",
			"wOS_UAP_Fortnite_behold",
			"wOS_UAP_Fortnite_best_mates",
			"wOS_UAP_Fortnite_bhangra_boogie",
			"wOS_UAP_Fortnite_billy_bounce",
			"wOS_UAP_Fortnite_blinding_lights",
			"wOS_UAP_Fortnite_bobbin",
			"wOS_UAP_Fortnite_bold_stance",
			"wOS_UAP_Fortnite_bombastic",
			"wOS_UAP_Fortnite_boneless",
			"wOS_UAP_Fortnite_boogie_bomb",
			"wOS_UAP_Fortnite_boogie_down",
			"wOS_UAP_Fortnite_breakdown",
			"wOS_UAP_Fortnite_breakin",
			"wOS_UAP_Fortnite_breakneck",
			"wOS_UAP_Fortnite_breezy",
			"wOS_UAP_Fortnite_bring_it_on",
			"wOS_UAP_Fortnite_brush_your_shoulders",
			"wOS_UAP_Fortnite_buckle_up",
			"wOS_UAP_Fortnite_bulletproof",
			"wOS_UAP_Fortnite_bunny_hop",
			"wOS_UAP_Fortnite_burpee",
			"wOS_UAP_Fortnite_business_hips",
			"wOS_UAP_Fortnite_calculated",
			"wOS_UAP_Fortnite_call_me",
			"wOS_UAP_Fortnite_cap_kick",
			"wOS_UAP_Fortnite_cap_kick_fail",
			"wOS_UAP_Fortnite_capoeira",
			"wOS_UAP_Fortnite_cartwheelin",
			"wOS_UAP_Fortnite_cat_flip",
			"wOS_UAP_Fortnite_cheer_up",
			"wOS_UAP_Fortnite_chicken",
			"wOS_UAP_Fortnite_clean_groove",
			"wOS_UAP_Fortnite_click",
			"wOS_UAP_Fortnite_cluck_strut",
			"wOS_UAP_Fortnite_cmere",
			"wOS_UAP_Fortnite_confused",
			"wOS_UAP_Fortnite_conga",
			"wOS_UAP_Fortnite_crabby",
			"wOS_UAP_Fortnite_crackdown",
			"wOS_UAP_Fortnite_crazy_feet",
			"wOS_UAP_Fortnite_crazyboy",
			"wOS_UAP_Fortnite_criss_cross",
			"wOS_UAP_Fortnite_dab",
			"wOS_UAP_Fortnite_dabstand",
			"wOS_UAP_Fortnite_dance_moves",
			"wOS_UAP_Fortnite_dance_off",
			"wOS_UAP_Fortnite_dance_therapy",
			"wOS_UAP_Fortnite_daydream",
			"wOS_UAP_Fortnite_death",
			"wOS_UAP_Fortnite_deep_dab",
			"wOS_UAP_Fortnite_deep_end",
			"wOS_UAP_Fortnite_denied",
			"wOS_UAP_Fortnite_disc_spinner",
			"wOS_UAP_Fortnite_disco_fever",
			"wOS_UAP_Fortnite_distracted",
			"wOS_UAP_Fortnite_double_up",
			"wOS_UAP_Fortnite_dragon_stance",
			"wOS_UAP_Fortnite_dream_feet",
			"wOS_UAP_Fortnite_droop",
			"wOS_UAP_Fortnite_drop_the_bass",
			"wOS_UAP_Fortnite_drum_major",
			"wOS_UAP_Fortnite_dynamic_shuffle",
			"wOS_UAP_Fortnite_eagle",
			"wOS_UAP_Fortnite_electro_shuffle",
			"wOS_UAP_Fortnite_electro_swing",
			"wOS_UAP_Fortnite_extraterrestial",
			"wOS_UAP_Fortnite_facepalm",
			"wOS_UAP_Fortnite_fanciful",
			"wOS_UAP_Fortnite_fancy_feet",
			"wOS_UAP_Fortnite_fandangle",
			"wOS_UAP_Fortnite_feelin_jaunty",
			"wOS_UAP_Fortnite_fierce",
			"wOS_UAP_Fortnite_finger_guns",
			"wOS_UAP_Fortnite_finger_wag",
			"wOS_UAP_Fortnite_fishin",
			"wOS_UAP_Fortnite_fist_pump",
			"wOS_UAP_Fortnite_flamenco",
			"wOS_UAP_Fortnite_flapper",
			"wOS_UAP_Fortnite_flex_on_em",
			"wOS_UAP_Fortnite_flippin_away",
			"wOS_UAP_Fortnite_flippin_incredible",
			"wOS_UAP_Fortnite_flippin_sexy",
			"wOS_UAP_Fortnite_floss",
			"wOS_UAP_Fortnite_flux",
			"wOS_UAP_Fortnite_free_flow",
			"wOS_UAP_Fortnite_free_mix",
			"wOS_UAP_Fortnite_freestylin",
			"wOS_UAP_Fortnite_freewheelin",
			"wOS_UAP_Fortnite_fresh",
			"wOS_UAP_Fortnite_fright_funk",
			"wOS_UAP_Fortnite_full_tilt",
			"wOS_UAP_Fortnite_gentlemans_dab",
			"wOS_UAP_Fortnite_get_funky",
			"wOS_UAP_Fortnite_get_loose",
			"wOS_UAP_Fortnite_glitter",
			"wOS_UAP_Fortnite_glowsticks",
			"wOS_UAP_Fortnite_glyphic",
		}

		categories["UAP - Fortnite"] = {}
		for _, taunt in ipairs(fortnite) do
			local name = taunt:gsub("^wOS_UAP_Fortnite", "uap_f")
			taunts[name] = ACT_GMOD_TAUNT_LAUGH
			categories["UAP - Fortnite"][name] = true
			sequence_overrides[name] = taunt
			name_overrides[name] = uap_nice_name(taunt)
		end

		local tf2 = {
			"wOS_UAP_TF2_all_aerobic",
			"wOS_UAP_TF2_demoman_aerobic",
			"wOS_UAP_TF2_demoman_conga",
			"wOS_UAP_TF2_demoman_russian",
			"wOS_UAP_TF2_engineer_aerobic",
			"wOS_UAP_TF2_engineer_conga",
			"wOS_UAP_TF2_engineer_russian",
			"wOS_UAP_TF2_heavy_aerobic",
			"wOS_UAP_TF2_heavy_conga",
			"wOS_UAP_TF2_heavy_russian",
			"wOS_UAP_TF2_medic_aerobic",
			"wOS_UAP_TF2_medic_conga",
			"wOS_UAP_TF2_medic_russian",
			"wOS_UAP_TF2_pyro_aerobic",
			"wOS_UAP_TF2_pyro_conga",
			"wOS_UAP_TF2_pyro_russian",
			"wOS_UAP_TF2_scout_aerobic",
			"wOS_UAP_TF2_scout_conga",
			"wOS_UAP_TF2_scout_russian",
			"wOS_UAP_TF2_sniper_aerobic",
			"wOS_UAP_TF2_sniper_conga",
			"wOS_UAP_TF2_sniper_russian",
			"wOS_UAP_TF2_soldier_aerobic",
			"wOS_UAP_TF2_soldier_conga",
			"wOS_UAP_TF2_soldier_russian",
			"wOS_UAP_TF2_spy_aerobic",
			"wOS_UAP_TF2_spy_conga",
			"wOS_UAP_TF2_spy_russian",
		}

		categories["UAP - TF2"] = {}
		for _, taunt in ipairs(tf2) do
			local name = taunt:gsub("^wOS_UAP_TF2", "uap_t")
			taunts[name] = ACT_GMOD_TAUNT_DANCE
			categories["UAP - TF2"][name] = true
			sequence_overrides[name] = taunt
			name_overrides[name] = uap_nice_name(taunt)
		end

		local other = {
			"wOS_UAP_Other_shadow_dances_love_me_if_you_can",
			"wOS_UAP_Other_shadow_dances_love_trial",
			"wOS_UAP_Other_shadow_dances_me_me_me",
			"wOS_UAP_Other_shadow_dances_mic_drop",
			"wOS_UAP_Other_shadow_dances_more_harder_better_faster_stronger",
			"wOS_UAP_Other_shadow_dances_nekomim_switch",
			"wOS_UAP_Other_shadow_dances_pop_stars",
			"wOS_UAP_Other_shadow_dances_scream_side_1",
			"wOS_UAP_Other_shadow_dances_scream_side_2",
			"wOS_UAP_Other_shadow_dances_smile",
			"wOS_UAP_Other_shadow_dances_solo",
			"wOS_UAP_Other_shadow_dances_sweet_devil",
			"wOS_UAP_Other_shadow_dances_taki_taki",
			"wOS_UAP_Other_shadow_dances_the_other_side",
			"wOS_UAP_Other_shadow_dances_the_zombie_song",
			"wOS_UAP_Other_shadow_dances_toxic",
			"wOS_UAP_Other_shadow_dances_umbrella_remix",
			"wOS_UAP_Other_shadow_dances_yeah_oh_ahhh_oh",
			"wOS_UAP_Other_shadow_dances_yes_or_yes",
			"wOS_UAP_Other_shadow_dances_zutter",
			"wOS_UAP_Other_shadow_dances_a_light_that_never_comes",
			"wOS_UAP_Other_shadow_dances_addiction",
			"wOS_UAP_Other_shadow_dances_all_eyes_on_me",
			"wOS_UAP_Other_shadow_dances_bad_romance",
			"wOS_UAP_Other_shadow_dances_bamm",
			"wOS_UAP_Other_shadow_dances_beep_beep_im_a_sheep",
			"wOS_UAP_Other_shadow_dances_boombayah",
			"wOS_UAP_Other_shadow_dances_broken",
			"wOS_UAP_Other_shadow_dances_classic",
			"wOS_UAP_Other_shadow_dances_confident",
			"wOS_UAP_Other_shadow_dances_ddu_du_ddu_du",
			"wOS_UAP_Other_shadow_dances_diamonds",
			"wOS_UAP_Other_shadow_dances_dna",
			"wOS_UAP_Other_shadow_dances_everybody_do_the_flop",
			"wOS_UAP_Other_shadow_dances_fighter",
			"wOS_UAP_Other_shadow_dances_follow_the_leader",
			"wOS_UAP_Other_shadow_dances_get_lucky",
			"wOS_UAP_Other_shadow_dances_in_the_name_of_love",
			"wOS_UAP_Other_shadow_dances_it_stains_in_your_color",
			"wOS_UAP_Other_shadow_dances_lips_are_movin",
			"wOS_UAP_Other_0_to_100",
			"wOS_UAP_Other_arona_dance",
			"wOS_UAP_Other_badger_dance",
			"wOS_UAP_Other_badger_snake_dance",
			"wOS_UAP_Other_bubbletop",
			"wOS_UAP_Other_car_shearer_dance",
			"wOS_UAP_Other_caramelldansen",
			"wOS_UAP_Other_chika_riley",
			"wOS_UAP_Other_club_penguin_dance",
			"wOS_UAP_Other_dao_ankha_dance",
			"wOS_UAP_Other_dao_dr_livesey_walk_back",
			"wOS_UAP_Other_dao_dr_livesey_walk_front",
			"wOS_UAP_Other_dao_dr_livesey_walk_mid",
			"wOS_UAP_Other_distraction_dance",
			"wOS_UAP_Other_francium_mmd",
			"wOS_UAP_Other_friday_night",
			"wOS_UAP_Other_gentleman",
			"wOS_UAP_Other_get_down",
			"wOS_UAP_Other_head_spin",
			"wOS_UAP_Other_internet_yamero",
			"wOS_UAP_Other_jack_o_pose",
			"wOS_UAP_Other_kakalupa_shuffle_dance_1",
			"wOS_UAP_Other_kakalupa_shuffle_dance_2",
			"wOS_UAP_Other_kakalupa_shuffle_dance_3",
			"wOS_UAP_Other_kakalupa_shuffle_dance_4",
			"wOS_UAP_Other_kakalupa_shuffle_dance_5",
			"wOS_UAP_Other_kakalupa_shuffle_dance_6",
			"wOS_UAP_Other_kakalupa_shuffle_dance_7",
			"wOS_UAP_Other_kakalupa_shuffle_dance_8",
			"wOS_UAP_Other_kakalupa_shuffle_dance_9",
			"wOS_UAP_Other_kakalupa_sims_dance_1",
			"wOS_UAP_Other_kakalupa_sims_dance_2",
			"wOS_UAP_Other_kakalupa_sims_dance_3",
			"wOS_UAP_Other_kakalupa_sims_dance_4",
			"wOS_UAP_Other_kakalupa_sims_dance_5",
			"wOS_UAP_Other_kakalupa_sims_dance_6",
			"wOS_UAP_Other_kakalupa_sims_dance_7",
			"wOS_UAP_Other_kami_dance",
			"wOS_UAP_Other_laydown_lying_back",
			"wOS_UAP_Other_laydown_prone",
			"wOS_UAP_Other_laydown_sit",
			"wOS_UAP_Other_lethal_company_dance",
			"wOS_UAP_Other_lights_camera_action",
			"wOS_UAP_Other_macarena_dance",
			"wOS_UAP_Other_malo_mart_dance",
			"wOS_UAP_Other_naruto_run",
			"wOS_UAP_Other_omae_wa_mou",
			"wOS_UAP_Other_over_the_top",
			"wOS_UAP_Other_rickroll",
			"wOS_UAP_Other_shake_it",
			"wOS_UAP_Other_shoulder_shake",
			"wOS_UAP_Other_simp_walk",
			"wOS_UAP_Other_skibidi_pa_pa_pa",
			"wOS_UAP_Other_specialist",
			"wOS_UAP_Other_super_animal_royale_dance",
			"wOS_UAP_Other_take_on_me",
			"wOS_UAP_Other_toca_toca",
			"wOS_UAP_Other_toothless_dance",
			"wOS_UAP_Other_twerk",
			"wOS_UAP_Other_vmd_feelings",
			"wOS_UAP_Other_vmd_fighter",
			"wOS_UAP_Other_vmd_galaxias",
			"wOS_UAP_Other_vmd_sweet_dreams",
			"wOS_UAP_Other_vmd_the_other_side",
			"wOS_UAP_Other_vmd_work_bitch",
			"wOS_UAP_Other_who_put_you_on_the_planet",
			"wOS_UAP_Other_zufolo_impazzito_dance",
		}

		categories["UAP - Other"] = {}
		for _, taunt in ipairs(other) do
			local name = taunt:gsub("^wOS_UAP_Other", "uap_o")
			taunts[name] = ACT_GMOD_TAUNT_DANCE
			categories["UAP - Other"][name] = true
			sequence_overrides[name] = taunt
			name_overrides[name] = uap_nice_name(taunt)
		end

		local mocap = {
			"wOS_UAP_MoCap_breaking",
			"wOS_UAP_MoCap_choreography",
			"wOS_UAP_MoCap_fast_movement_test_1",
			"wOS_UAP_MoCap_fast_movement_test_2",
			"wOS_UAP_MoCap_fast_movement_test_3",
			"wOS_UAP_MoCap_freestyle_1",
			"wOS_UAP_MoCap_freestyle_2",
			"wOS_UAP_MoCap_freestyle_3",
			"wOS_UAP_MoCap_freestyle_4",
			"wOS_UAP_MoCap_freestyle_5",
			"wOS_UAP_MoCap_freestyle_6",
			"wOS_UAP_MoCap_freestyle_7",
			"wOS_UAP_MoCap_freestyle_8",
			"wOS_UAP_MoCap_freestyle_9",
			"wOS_UAP_MoCap_freestyle_10",
			"wOS_UAP_MoCap_freestyle_11",
			"wOS_UAP_MoCap_freestyle_12",
			"wOS_UAP_MoCap_freestyle_13",
			"wOS_UAP_MoCap_freestyle_14",
			"wOS_UAP_MoCap_freestyle_15",
			"wOS_UAP_MoCap_freestyle_16",
			"wOS_UAP_MoCap_freestyle_17",
			"wOS_UAP_MoCap_freestyle_18",
			"wOS_UAP_MoCap_freestyle_19",
			"wOS_UAP_MoCap_hip_hop",
			"wOS_UAP_MoCap_house_dance",
			"wOS_UAP_MoCap_locking",
			"wOS_UAP_MoCap_medusa_intro",
			"wOS_UAP_MoCap_popping",
			"wOS_UAP_MoCap_soft_bounce_1",
			"wOS_UAP_MoCap_soft_bounce_2",
			"wOS_UAP_MoCap_soft_bounce_3",
			"wOS_UAP_MoCap_soft_bounce_4",
			"wOS_UAP_MoCap_soft_bounce_5",
			"wOS_UAP_MoCap_soft_bounce_6",
			"wOS_UAP_MoCap_soft_bounce_7",
			"wOS_UAP_MoCap_soft_bounce_8",
			"wOS_UAP_MoCap_soft_bounce_9",
			"wOS_UAP_MoCap_soft_bounce_10",
			"wOS_UAP_MoCap_soft_bounce_11",
			"wOS_UAP_MoCap_soft_bounce_12",
			"wOS_UAP_MoCap_soft_bounce_13",
			"wOS_UAP_MoCap_soft_bounce_14",
			"wOS_UAP_MoCap_soft_bounce_15",
			"wOS_UAP_MoCap_soft_bounce_16",
			"wOS_UAP_MoCap_soft_bounce_17",
		}

		categories["UAP - MoCap"] = {}
		for _, taunt in ipairs(mocap) do
			local name = taunt:gsub("^wOS_UAP_MoCap", "uap_m")
			taunts[name] = ACT_GMOD_TAUNT_DANCE
			categories["UAP - MoCap"][name] = true
			sequence_overrides[name] = taunt
			name_overrides[name] = uap_nice_name(taunt)
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

		local loop = ply:GetNW2Bool("actx_loop", false)

		local act = taunts[taunt]
		if not act then
			ply:SetNW2String("actx_taunt", "")
			ply:SetNW2Float("actx_start", 0)
			return
		end
		local override = sequence_overrides[taunt]
		local seq = override or act
		if not seq then
			ply:SetNW2String("actx_taunt", "")
			ply:SetNW2Float("actx_start", 0)
			return
		end

		local seq_id = ply:LookupSequence(seq)
		if not seq_id or seq_id == -1 and override == nil then
			seq_id = ply:SelectWeightedSequence(act)
		end
		if not seq_id or seq_id == -1 then
			ply:SetNW2String("actx_taunt", "")
			ply:SetNW2Float("actx_start", 0)
			return
		end

		local len = ply:SequenceDuration(seq_id)
		if CurTime() > start + len then
			if SERVER then
				if loop then
					timer.Simple(0, function()
						ply:SetNW2Float("actx_start", CurTime())
						if override ~= nil then
							ply:DoCustomAnimEvent(PLAYERANIMEVENT_CUSTOM_SEQUENCE, ACTX_EVENT)
						else
							ply:DoAnimationEvent(act)
						end
					end)
				else
					ply:SetNW2String("actx_taunt", "")
					ply:SetNW2Float("actx_start", 0)
				end
				return
			end
		end

		if override == nil then return end
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

	for name in SortedPairs(taunts) do
		if string.find(name, string.sub(argStr, 2, -1), 1, true) or #argStr < 2 then
			completions[#completions + 1] = cmd .. " " .. name
		end
	end

	return completions
end

if SERVER then
	concommand.Add(TAG, function(ply, cmd, args, argStr)
		local taunt = args[1]
		local loop = args[2] == "loop"
		if not taunt or taunt == "" then return end

		if taunt == "stop" then
			ply:SetNW2String("actx_taunt", "")
			ply:SetNW2Float("actx_start", 0)
			ply:SetNW2Bool("actx_loop", false)
			ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
			ply:AnimRestartMainSequence()
			return
		end

		local act = taunts[taunt]
		if act == nil then
			ply:ChatPrint(string.format("Unknown act: %q", taunt))
			return
		end

		if hook.Run("PlayerShouldTaunt", ply, act) == false then return end

		ply:SetNW2String("actx_taunt", taunt)
		ply:SetNW2Float("actx_start", CurTime())
		ply:SetNW2Bool("actx_loop", loop)

		local sequence = sequence_overrides[taunt]
		if sequence ~= nil then
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
