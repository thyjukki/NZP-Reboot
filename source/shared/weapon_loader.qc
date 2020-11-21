//
// weapon_loader.qc - Loads weapon data for both client/server
//

// #defines for frame names
#define FRAME_FIRE_START            0
#define FRAME_FIRE_END              1
#define FRAME_RELOAD_START          2
#define FRAME_RELOAD_END            3
#define FRAME_RELOAD_CANCEL         4
#define FRAME_SPRINT_IN_START       5
#define FRAME_SPRINT_IN_END         6
#define FRAME_SPRINT_START          7
#define FRAME_SPRINT_END            8
#define FRAME_SPRINT_OUT_START      9
#define FRAME_SPRINT_OUT_END        10
#define FRAME_TAKE_OUT_START        11
#define FRAME_TAKE_OUT_END          12
#define FRAME_PUT_OUT_START         13
#define FRAME_PUT_OUT_END           14
#define FRAME_CONTINUE_LOAD_START   15
#define FRAME_CONTINUE_LOAD_END     16
#define FRAME_LOWER_START           17
#define FRAME_LOWER_END             18
#define FRAME_COCK_START            19
#define FRAME_COCK_CANCEL           20
#define FRAME_COCK_END              21

// Struct to hold all Weapon Information.
var struct {
    // details
    string name;
    float weapon_id;
    float is_dual_weapon;
    float model_skin;

    // packed info
    float is_packed;
    float packed_id;
    float non_packed_id;

    // models
    string view_model;
    string view_model_accessory;
    string left_view_model;
    string world_model;
    string fire_sound;

    // stats
    float magazine_size;
    float reserve_size;
    float magazine_low;
    float reserve_low;
    float rounds_per_load;

    // ads vectors
    vector ads_position_pc;
    vector ads_position_console;

    // crosshair
    float crosshair_special;
    float crosshair_minimum_range;
    float crosshair_maximum_range;

    // recoil
    float recoil;
    vector recoil_guaranteed;
    vector recoil_kick_change;

    // muzzle flash
    vector muzzle_flash_offset;
    float muzzle_flash_size;

    // delays
    float fire_delay;
    float reload_delay;
    float continue_reload_delay;
    float lower_delay;
    float cock_delay;

    // penetration
    float penetration_amount;
    float penetration_body_count;

    // misc.
    float damage;
    float bullet_spread;
    float shotcount;
    float fire_type;
    float weapon_weight;
    float continued_reload;

    // cocking
    float no_cock_after_reload;

    // multipliers based on hit location
    float multiplier_head;
    float multiplier_upper_torso;
    float multiplier_lower_torso;
    float multiplier_limbs;

    // frames
    float frames[32];
    float frame_sound_number[8];
    string frame_sound_name[8];

    // precaches
    string precache_models[4];
    string precache_sounds[8];
} weapons[128] =
{

};

//
// Load_Weapon(name)
// Loads a Weapon File.
//
void(string name, optional float base) Load_Weapon =
{
    local float file;
    local string filename;

    // Base weapons use the root weapons/ directory, as opposed to weapons/mapname/.
    if (base)
        filename = strcat("weapons/", name);
    
    file = fopen(filename, FILE_READ);

    // If the file isn't found, 100% halt here to avoid further errors.
    if (file == -1) {
        error(strcat("Load_Weapon: Could not find Weapon file ", name));
    }

    local float pre_wav_iter;
    local float pre_mdl_iter;
    local float pre_snd_iter;
    local float loop;
    local float point;
    local float i;
    loop = 1;

    while(loop) {
        // Retrieve readied line
        local string line;
        local string h;
        line = fgets(file);

        // End of file
        if not (line) {
            loop = 0;
            break;
        }

        h = strzone(strtrim(line));

        // Ignore the line if its a Comment or white space.
        if (substring(h, 0, 2) == "//" || h == "") {
            continue;
        }

        // Mandatory check for weapon_id field.
        if (point == 0) {
            tokenize(h);

            // Alert the lack of weapon_id
            if (argv(0) != "weapon_id") {
                local string temps;
                temps = "Load_Weapon: Weapon file '";
                temps = strcat(temps, filename);
                temps = strcat(temps, "' has no weapon_id or weapon_id is not the first variable!");
                error(temps);
            }

            i = stof(argv(2));
            point = 1;
        } 
        // Main Parser
        else if (point == 1) {
            // Go to Precaches
            if (h == "precaches") {
                point = 2;
                continue;
            }
            // Go to Damage Multipliers
            if (h == "damage_multiplier") {
                point = 3;
                continue;
            }
            // Go to Frame Sounds
            if (h == "frame_sounds") {
                point = 4;
                continue;
            }

            tokenize(h);

            switch(argv(0)) {
                // Details
                case "name":
                    weapons[i].name = strzone(argv(2));
                    break;
                case "is_packed":
                    weapons[i].is_packed = stof(argv(2));
                    break;
                case "is_dual_weapon":
                    weapons[i].is_dual_weapon = stof(argv(2));
                    break;
                case "packed_id":
                    weapons[i].packed_id = stof(argv(2));
                    break;
                case "model_skin":
                    weapons[i].model_skin = stof(argv(2));
                    break;
                case "view_model":
                    weapons[i].view_model = strzone(argv(2));
                    break;
                case "view_model_accessory":
                    weapons[i].view_model_accessory = strzone(argv(2));
                    break;
                case "left_view_model":
                    weapons[i].left_view_model = strzone(argv(2));
                    break;
                case "world_model":
                    weapons[i].world_model = strzone(argv(2));
                    break;
                case "fire_sound":
                    weapons[i].fire_sound = strzone(argv(2));
                    break;
                case "no_cock_after_reload":
                    weapons[i].no_cock_after_reload = stof(argv(2));
                    break;
                // Stats
                case "magazine_size":
                    weapons[i].magazine_size = stof(argv(2));
                    break;
                case "reserve_size":
                    weapons[i].reserve_size = stof(argv(2));
                    break;
                case "magazine_low":
                    weapons[i].magazine_low = stof(argv(2));
                    break;
                case "reserve_low":
                    weapons[i].reserve_low = stof(argv(2));
                    break;
                case "rounds_per_load":
                    weapons[i].rounds_per_load = stof(argv(2));
                    break;
                case "ads_position_pc":
                    local vector vec = stov(argv(2));
                    weapons[i].ads_position_pc[0] = vec[0];
                    weapons[i].ads_position_pc[1] = vec[1];
                    weapons[i].ads_position_pc[2] = vec[2];
                    break;
                case "ads_position_console":
                    local vector vec2 = stov(substring(h, 22, strlen(h)));
                    weapons[i].ads_position_console[0] = vec2[0];
                    weapons[i].ads_position_console[1] = vec2[1];
                    weapons[i].ads_position_console[2] = vec2[2];
                    break;
                case "crosshair_special":
                    weapons[i].crosshair_special = stof(argv(2));
                    break;
                case "crosshair_minimum_range":
                    weapons[i].crosshair_minimum_range = stof(argv(2));
                    break;
                case "crosshair_maximum_range":
                    weapons[i].crosshair_maximum_range = stof(argv(2));
                    break;
                case "recoil":
                    weapons[i].recoil = stof(argv(2));
                    break;
                case "recoil_guaranteed":
                    #ifdef PC
                    local vector vec3 = stov(argv(2));
                    #else
                    local vector vec3 = stov(substring(h, 19, strlen(h)));
                    #endif
                    weapons[i].recoil_guaranteed[0] = vec3[0];
                    weapons[i].recoil_guaranteed[1] = vec3[1];
                    weapons[i].recoil_guaranteed[2] = vec3[2];
                    break;
                case "recoil_kick_change":
                    #ifdef PC
                    local vector vec4 = stov(argv(2));
                    #else
                    local vector vec4 = stov(substring(h, 20, strlen(h)));
                    #endif
                    weapons[i].recoil_kick_change[0] = vec4[0];
                    weapons[i].recoil_kick_change[1] = vec4[1];
                    weapons[i].recoil_kick_change[2] = vec4[2];
                    break;
                case "muzzle_flash_offset":
                    #ifdef PC
                    local vector vec5 = stov(argv(2));
                    #else
                    local vector vec5 = stov(substring(h, 21, strlen(h)));
                    #endif
                    weapons[i].muzzle_flash_offset[0] = vec5[0];
                    weapons[i].muzzle_flash_offset[1] = vec5[1];
                    weapons[i].muzzle_flash_offset[2] = vec5[2];
                    break;
                case "muzzle_flash_size":
                    weapons[i].muzzle_flash_size = stof(argv(2));
                    break;
                case "fire_delay":
                    weapons[i].fire_delay = stof(argv(2));
                    break;
                case "reload_delay":
                    weapons[i].reload_delay = stof(argv(2));
                    break;
                case "continue_reload_delay":
                    weapons[i].continue_reload_delay = stof(argv(2));
                    break;
                case "lower_delay":
                    weapons[i].lower_delay = stof(argv(2));
                    break;
                case "cock_delay":
                    weapons[i].cock_delay = stof(argv(2));
                    break;
                case "penetration_amount":
                    weapons[i].penetration_amount = stof(argv(2));
                    break;
                case "penetration_body_count":
                    weapons[i].penetration_body_count = stof(argv(2));
                    break;
                case "damage":
                    weapons[i].damage = stof(argv(2));
                    break;
                case "bullet_spread":
                    weapons[i].bullet_spread = stof(argv(2));
                    break;
                case "shotcount":
                    weapons[i].shotcount = stof(argv(2));
                    break;
                case "fire_type":
                    weapons[i].fire_type = stof(argv(2));
                    break;
                case "weapon_weight":
                    weapons[i].weapon_weight = stof(argv(2));
                    break;
                case "continued_reload":
                    weapons[i].continued_reload = stof(argv(2));
                    break;
                // Frames
                case "fire_start":
                    weapons[i].frames[FRAME_FIRE_START] = stof(argv(2));
                    break;
                case "fire_end":
                    weapons[i].frames[FRAME_FIRE_END] = stof(argv(2));
                    break;
                case "reload_start":
                    weapons[i].frames[FRAME_RELOAD_START] = stof(argv(2));
                    break;
                case "reload_end":
                    weapons[i].frames[FRAME_RELOAD_END] = stof(argv(2));
                    break;
                case "reload_cancel":
                    weapons[i].frames[FRAME_RELOAD_CANCEL] = stof(argv(2));
                    break;
                case "sprint_in_start":
                    weapons[i].frames[FRAME_SPRINT_IN_START] = stof(argv(2));
                    break;
                case "sprint_in_end":
                    weapons[i].frames[FRAME_SPRINT_IN_END] = stof(argv(2));
                    break;
                case "sprint_start":
                    weapons[i].frames[FRAME_SPRINT_START] = stof(argv(2));
                    break;
                case "sprint_end":
                    weapons[i].frames[FRAME_SPRINT_END] = stof(argv(2));
                    break;
                case "sprint_out_start":
                    weapons[i].frames[FRAME_SPRINT_OUT_START] = stof(argv(2));
                    break;
                case "sprint_out_end":
                    weapons[i].frames[FRAME_SPRINT_OUT_END] = stof(argv(2));
                    break;
                case "take_out_start":
                    weapons[i].frames[FRAME_TAKE_OUT_START] = stof(argv(2));
                    break;
                case "take_out_end":
                    weapons[i].frames[FRAME_TAKE_OUT_END] = stof(argv(2));
                    break;
                case "put_out_start":
                    weapons[i].frames[FRAME_PUT_OUT_START] = stof(argv(2));
                    break;
                case "put_out_end":
                    weapons[i].frames[FRAME_PUT_OUT_END] = stof(argv(2));
                    break;
                case "continue_reload_start":
                    weapons[i].frames[FRAME_CONTINUE_LOAD_START] = stof(argv(2));
                    break;
                case "continue_reload_end":
                    weapons[i].frames[FRAME_CONTINUE_LOAD_END] = stof(argv(2));
                    break;
                case "lower_start":
                    weapons[i].frames[FRAME_LOWER_START] = stof(argv(2));
                    break;
                case "lower_end":
                    weapons[i].frames[FRAME_LOWER_END] = stof(argv(2));
                    break;
                case "cock_start":
                    weapons[i].frames[FRAME_COCK_START] = stof(argv(2));
                    break;
                case "cock_cancel":
                    weapons[i].frames[FRAME_COCK_CANCEL] = stof(argv(2));
                    break;
                case "cock_end":
                    weapons[i].frames[FRAME_COCK_END] = stof(argv(2));
                    break;
                default:
                    break;
            }
        }
        // Precaches
        else if (point == 2) {
            // Return to Main Parser
            if (h == "}") {
                point = 1;
            } else {
                // Ignore start bracked
                if (h == "{")
                    continue;

                // Check extension to determine whether its a Model or a Sound
                local float length = strlen(h);
                local string extension = substring(h, length - 4, length);

                if (extension == ".mdl") {
                    // We hit our model cap
                    if (pre_mdl_iter >= 4) {
                        local string temps2;
                        temps2 = "Load_Weapon: Weapon file '";
                        temps2 = strcat(temps2, filename);
                        temps2 = strcat(temps2, "' has too many models! (Max is 4)");
                        error(temps2);
                    }
                    weapons[i].precache_models[pre_mdl_iter] = strzone(h);
                    pre_mdl_iter++;
                } else if (extension == ".wav") {
                    // We hit our sound cap
                    if (pre_wav_iter >= 8) {
                        local string temps4;
                        temps4 = "Load_Weapon: Weapon file '";
                        temps4 = strcat(temps4, filename);
                        temps4 = strcat(temps4, "' has too many sounds! (Max is 8)");
                        error(temps4);
                    }
                    weapons[i].precache_sounds[pre_wav_iter] = strzone(h);
                    pre_wav_iter++;
                } else {
                    local string temps3;
                    temps3 = "Load_Weapon: Weapon file '";
                    temps3 = strcat(temps3, filename);
                    temps3 = strcat(temps3, "' attempted to precache with an unknown extension (case issue?): ");
                    temps3 = strcat(temps3, extension);
                    error(temps3);
                }
            }
        }
        // Multipliers Based on Hit Location
        else if (point == 3) {
            // Return to Main Parser
            if (h == "]") {
                point = 1;
            } else {
                // Ignore start bracket
                if (h == "[")
                    continue;
                
                tokenize(h);

                switch(argv(0)) {
                    case "head":
                        weapons[i].multiplier_head = stof(argv(2));
                        break;
                    case "upper_torso":
                        weapons[i].multiplier_upper_torso = stof(argv(2));
                        break;
                    case "lower_torso":
                        weapons[i].multiplier_lower_torso = stof(argv(2));
                        break;
                    case "limbs":
                        weapons[i].multiplier_limbs = stof(argv(2));
                        break;
                    default:
                        break;
                }
            }
        }
        // Weapon Frames to play Sounds on
        else if (point == 4) {
            // Return to Main Parser
            if (h == "]") {
                point = 1;
            } else {
                // Ignore start bracket
                if (h == "[")
                    continue;
                
                if (pre_snd_iter >= 8) {
                    local string temps5;
                    temps5 = "Load_Weapon: Weapon file '";
                    temps5 = strcat(temps5, filename);
                    temps5 = strcat(temps5, "' features more than 8 frame_sounds!");
                    error(temps5);
                }

                tokenize(h);
                weapons[i].frame_sound_number[pre_snd_iter] = stof(argv(0));
                weapons[i].frame_sound_name[pre_snd_iter] = strzone(argv(2));
                pre_snd_iter++;
            }
        }
        strunzone(h);
    }
    fclose(file);
} 

//
// Load_Base_Weapons()
// Called by worldspawn(), loads the base weapon files.
//
void() Load_Base_Weapons =
{
    Load_Weapon("m1911", 1);
    Load_Weapon("thompson", 1);
    Load_Weapon("trenchgun", 1);
}

void() do_test_weapon_stuff =
{
}