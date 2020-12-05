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

        // Main Parser
        if (point == 0) {
            tokenize(h);

            switch(argv(0)) {
                case "starting_points":
                    G_STARTPOINTS = stof(argv(2));
                    break;
                case "starting_round":
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
        strunzone(h);
    }
    fclose(file);
}