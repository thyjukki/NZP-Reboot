//
// nzd_loader.qc - Loads .NZD data for both client/server
//

//
// NZD_LoadDefaultSettings()
// Called when mapname.nzd isn't found, loads
// the default settings for Gameplay.
//
void() NZD_LoadDefaultSettings =
{
    G_STARTPOINTS = 500;
    G_STARTROUND = 1;
    G_PERKCHANGE = 0;
    G_STARTWEAPON[0] = W_COLT;
    G_STARTWEAPON[1] = 8;
    G_STARTWEAPON[2] = 32;
    G_PERKLIMIT = 0;
    G_MAXSOLOREVIVES = 3;
    G_REVIVEMULTIPLIER = 0.5;
    G_SPEEDREBUILD = 1;
    G_SPEEDMULTIPLIER = 0.5;
    G_DTMULTIPLIER = 0.66;
    G_DOUBLETAP2 = 1;
    G_STAMINSPEED = 1.07;
    G_STAMINMULTIPLIER = 0.5;
    G_DEADMULTIPLIER = 0.65;
    G_MAXPUS = 4;
    G_PUCHANCE = 0.02;
    G_ALLOWMAXAMMO = 1;
    G_ALLOWINSTA = 1;
    G_ALLOWNUKE = 1;
    G_ALLOW2X = 1;
    G_ALLOWCARPENTER = 1;
    G_ALLOWPERK = 0;
    G_MAXHEALTH = 100;
    G_WALKSPEED = 1;
    G_REGENDELAY = 2;
    G_BLEEDTIME = 45;
    G_POINTDOWN = 0;
    G_PERKDOWN = 1;
    G_SOUNDS.ROUND_SPLASH = "sounds/rounds/splash.wav";
    G_SOUNDS.ROUND_NEW = "sounds/rounds/nround.wav";
    G_SOUNDS.ROUND_END = "sounds/rounds/eround.wav";
    G_SOUNDS.ROUND_NEW_DOG = "sounds/rounds/droundstart.wav";
    G_SOUNDS.ROUND_END_DOG = "sounds/rounds/droundend.wav";
    G_SOUNDS.PU_DROP = "sounds/pu/drop.wav";
    G_SOUNDS.PU_LOOP = "sounds/pu/powerup.wav";
    G_SOUNDS.PU_PICKUP = "sounds/pu/pickup.wav";
    G_SOUNDS.PU_INSTAKILL = "sounds/pu/insta_kill.wav";
    G_SOUNDS.PU_2X = "sounds/pu/double_points.wav";
    G_SOUNDS.PU_CARPENTER = "sounds/pu/carpenter.wav";
    G_SOUNDS.PU_NUKE = "sounds/pu/nuke.wav";
    G_SOUNDS.PU_MAXAMMO = "sounds/pu/maxammo.wav";
    G_SOUNDS.PU_PERKDROP = "";
    G_SOUNDS.ZM_ATTACK_COUNT = 8;
    G_SOUNDS.ZM_ATTACK = "sounds/zombie/a";
    G_SOUNDS.ZM_ATTACK_COUNT = 8;
    G_SOUNDS.ZM_DEATH = "sounds/zombie/d";
    G_SOUNDS.ZM_RUN_COUNT = 10;
    G_SOUNDS.ZM_RUN = "sounds/zombie/r";
    G_SOUNDS.ZM_TAUNT_COUNT = 5;
    G_SOUNDS.ZM_TAUNT = "sounds/zombie/t";
    G_SOUNDS.ZM_WALK_COUNT = 10;
    G_SOUNDS.ZM_WALK = "sounds/zombie/w";
    G_SOUNDS.MISC_CHING = "sounds/misc/ching.wav";
}

//
// NZD_Load()
// Loads mapname.nzd
//
void() NZD_Load =
{
    float file;
    string h;

    h = strcat(mappath, ".nzd");
    file = fopen(h, FILE_READ);

    // Load all of the default settings before all else
    NZD_LoadDefaultSettings();

    // File doesn't exist, so don't try to parse.
    if (file == -1) {
        return;
    }

    float loop;
    float point;
    float starting_weapon_point;
    starting_weapon_point = 0;
    point = 0;
    loop = 1;

    while(loop) {
        // Retrieve readied Line
        string line;
        line = fgets(file);

        // End of File
        if not (line) {
            loop = 0;
            break;
        }

        h = strzone(strtrim(line));

        // Ignore the Line if its a Comment or White Space.
        if (substring(h, 0, 2) == "//" || h == "") {
            continue;
        }

        // Jump to Sounds
        if (h == "sounds")
            point = 3;

        // Main Parser
        if (point == 0) {
            tokenize(h);

            switch(argv(0)) {
                case "starting_points":
                    G_STARTPOINTS = stof(argv(2));
                    break;
                case "start_round":
                    G_STARTROUND = stof(argv(2));
                    break;
                case "starting_weapon":
                    point = 1;
                    break;
                case "starting_perks":
                    point = 2;
                    break;
                case "perk_change":
                    G_PERKCHANGE = stof(argv(2));
                    break;
                case "perk_purchase_limit":
                    G_PERKLIMIT = stof(argv(2));
                    break;
                case "perk_revive_solo_max_uses":
                    G_MAXSOLOREVIVES = stof(argv(2));
                    break;
                case "perk_revive_time_reduction_multiplier":
                    G_REVIVEMULTIPLIER = stof(argv(2));
                    break;
                case "perk_juggernog_damage_reduction_multiplier":
                    G_JUGMULTIPLIER = stof(argv(2));
                    break;
                case "perk_speedcola_reduce_barricade_rebuild_time":
                    G_SPEEDREBUILD = stof(argv(2));
                    break;
                case "perk_speedcola_reload_speed_reduction_multiplier":
                    G_SPEEDMULTIPLIER = stof(argv(2));
                    break;
                case "perk_doubletap_rof_multiplier":
                    G_DTMULTIPLIER = stof(argv(2));
                    break;
                case "perk_doubletap_enable_double_fire":
                    G_DOUBLETAP2 = stof(argv(2));
                    break;
                case "perk_staminup_walkspeed_multiplier":
                    G_STAMINSPEED = stof(argv(2));
                    break;
                case "perk_staminup_stamina_usage_reduction_multiplier":
                    G_STAMINMULTIPLIER = stof(argv(2));
                    break;
                case "perk_deadshot_weapon_spread_multiplier":
                    G_DEADMULTIPLIER = stof(argv(2));
                    break;
                case "max_per_round":
                    G_MAXPUS = stof(argv(2));
                    break;
                case "drop_rate_percent":
                    G_PUCHANCE = stof(argv(2));
                    break;
                case "allow_maxammo":
                    G_ALLOWMAXAMMO = stof(argv(2));
                    break;
                case "allow_2xpoints":
                    G_ALLOW2X = stof(argv(2));
                    break;
                case "allow_carpenter":
                    G_ALLOWCARPENTER = stof(argv(2));
                    break;
                case "allow_nuke":
                    G_ALLOWNUKE = stof(argv(2));
                    break;
                case "allow_instakill":
                    G_ALLOWINSTA = stof(argv(2));
                    break;
                case "allow_perkdrop":
                    G_ALLOWPERK = stof(argv(2));
                    break;
                case "gravity":
                    #ifndef CLIENT
                    localcmd(strcat("sv_gravity ", argv(2)));
                    #endif
                    break;
                case "max_health":
                    G_MAXHEALTH = stof(argv(2));
                    break;
                case "walkspeed_multiplier":
                    G_WALKSPEED = stof(argv(2));
                    break;
                case "health_regeneration_delay":
                    G_REGENDELAY = stof(argv(2));
                    break;
                case "downed_bleedout_time":
                    G_BLEEDTIME = stof(argv(2));
                    break;
                case "lose_perks_on_down":
                    G_PERKDOWN = stof(argv(2));
                    break;
                case "earn_points_while_down":
                    G_POINTDOWN = stof(argv(2));
                    break;
                default: 
                    break;
            }
        } 
        // Starting Weapon
        else if (point == 1) {
            // Ignore the Starting Bracket
            if (h == "[")
                continue;
            // End on End Bracket or if there's more than 3 fields in the starting weapon
            if (h == "]" || starting_weapon_point >= 3) {
                point = 0;
                continue;
            }
            G_STARTWEAPON[starting_weapon_point] = stof(h);
            starting_weapon_point += 1;
        }
        // Starting Perks
        else if (point == 2) {
            // Ignore the Starting Bracked
            if (h == "[")
                continue;
            // End on End Bracket
            if (h == "]") {
                point = 0;
                continue;
            }

            switch(h) {
                case "juggernog":
                    G_PERKS = G_PERKS | 1;
                    spawn_perk_count++;
                    break;
                case "doubletap":
                    G_PERKS = G_PERKS | 2;
                    spawn_perk_count++;
                    break;
                case "speedcola":
                    G_PERKS = G_PERKS | 4;
                    spawn_perk_count++;
                    break;
                case "revive":
                    G_PERKS = G_PERKS | 8;
                    spawn_perk_count++;
                    break;
                case "flopper":
                    G_PERKS = G_PERKS | 16;
                    spawn_perk_count++;
                    break;
                case "staminup":
                    G_PERKS = G_PERKS | 32;
                    spawn_perk_count++;
                    break;
                case "deadshot":
                    G_PERKS = G_PERKS | 64;
                    spawn_perk_count++;
                    break;
                case "mulekick":
                    G_PERKS = G_PERKS | 128;
                    spawn_perk_count++;
                    break;
                default:
                    string temps = "Unknown Perk: ";
                    temps = strcat(temps, h);
                    error(temps);
                    break;
            }
        }
        // Sounds
        else if (point == 3) {
            // End on the End Bracket
            if (h == "}") {
                point = 0;
                continue;
            }

            tokenize(h);

            switch(argv(0)) {
                case "splash":
                    G_SOUNDS.ROUND_SPLASH = strzone(argv(2));
                    break;
                case "new":
                    G_SOUNDS.ROUND_NEW = strzone(argv(2));
                    break;
                case "end":
                    G_SOUNDS.ROUND_END = strzone(argv(2));
                    break;
                case "new_dog":
                    G_SOUNDS.ROUND_NEW_DOG = strzone(argv(2));
                    break;
                case "end_dog":
                    G_SOUNDS.ROUND_END_DOG = strzone(argv(2));
                    break;
                case "drop":
                    G_SOUNDS.PU_DROP = strzone(argv(2));
                    break;
                case "loop":
                    G_SOUNDS.PU_LOOP = strzone(argv(2));
                    break;
                case "pickup":
                    G_SOUNDS.PU_PICKUP = strzone(argv(2));
                    break;
                case "pu_instakill":
                    G_SOUNDS.PU_INSTAKILL = strzone(argv(2));
                    break;
                case "pu_doublepoints":
                    G_SOUNDS.PU_2X = strzone(argv(2));
                    break;
                case "pu_carpenter":
                    G_SOUNDS.PU_CARPENTER = strzone(argv(2));
                    break;
                case "pu_nuke":
                    G_SOUNDS.PU_NUKE = strzone(argv(2));
                    break;
                case "pu_maxammo":
                    G_SOUNDS.PU_MAXAMMO = strzone(argv(2));
                    break;
                case "pu_perkdrop":
                    G_SOUNDS.PU_PERKDROP = strzone(argv(2));
                    break;
                case "attack_sound_count":
                    G_SOUNDS.ZM_ATTACK_COUNT = stof(argv(2));
                    break;
                case "attack":
                    G_SOUNDS.ZM_ATTACK = strzone(argv(2));
                    break;
                case "death_sound_count":
                    G_SOUNDS.ZM_DEATH_COUNT = stof(argv(2));
                    break;
                case "death":
                    G_SOUNDS.ZM_DEATH = strzone(argv(2));
                    break;
                case "run_sound_count":
                    G_SOUNDS.ZM_RUN_COUNT = stof(argv(2));
                    break;
                case "run":
                    G_SOUNDS.ZM_RUN = strzone(argv(2));
                    break;
                case "taunt_sound_count":
                    G_SOUNDS.ZM_TAUNT_COUNT = stof(argv(2));
                    break;
                case "taunt":
                    G_SOUNDS.ZM_TAUNT = strzone(argv(2));
                    break;
                case "walk_sound_count":
                    G_SOUNDS.ZM_WALK_COUNT = stof(argv(2));
                    break;
                case "walk":
                    G_SOUNDS.ZM_WALK = strzone(argv(2));
                    break;
                case "ching":
                    G_SOUNDS.MISC_CHING = strzone(argv(2));
                    break;
                default:
                    break;
            }
        }
        strunzone(h);
    }
    fclose(file);
}