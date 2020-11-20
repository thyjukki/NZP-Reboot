//
// weapon_loader.qc - Loads weapon data for both client/server
//

// #defines for frame names
#define FRAME_FIRE_START        0
#define FRAME_FIRE_END          1
#define FRAME_RELOAD_START      2
#define FRAME_RELOAD_END        3
#define FRAME_RELOAD_CANCEL     4
#define FRAME_SPRINT_IN_START   5
#define FRAME_SPRINT_IN_END     6
#define FRAME_SPRINT_START      7
#define FRAME_SPRINT_END        8
#define FRAME_SPRINT_OUT_START  9
#define FRAME_SPRINT_OUT_END    10
#define FRAME_TAKE_OUT_START    11
#define FRAME_TAKE_OUT_END      12
#define FRAME_PUT_OUT_START     13
#define FRAME_PUT_OUT_END       14

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

    // penetration
    float penetration_amount;
    float penetration_body_count;

    // misc.
    float damage;
    float bullet_spread;
    float shotcount;
    float fire_type;
    float weapon_weight;

    // multipliers based on hit location
    float multiplier_head;
    float multiplier_upper_torso;
    float multiplier_lower_torso;
    float multiplier_limbs;

    // frames
    float frames[16];
    float frame_sound_number[8];
    string frame_sound_name[8];

    // precaches
    string precache_models[4];
    string precache_sounds[8];
} weapons[128] =
{

};

void() do_test_weapon_stuff =
{
    weapons[1].name = "Colt M1911";
    weapons[1].weapon_id = 1;
    weapons[1].is_packed = 0;
    weapons[1].is_dual_weapon = 0;
    weapons[1].packed_id = 0;
    weapons[1].model_skin = 0;
    weapons[1].view_model = "models/weapons/m1911/v_colt.mdl";
    weapons[1].world_model = "models/weapons/m1911/g_colt.mdl";
    weapons[1].fire_sound = "sounds/weapons/colt/shoot.wav";
    weapons[1].magazine_size = 8;
    weapons[1].reserve_size = 32;
    weapons[1].magazine_low = 2;
    weapons[1].reserve_low = 16;
    weapons[1].ads_position_pc = [-2.99, 2.77, 0.92];
    weapons[1].ads_position_console = [-5479.2, 1650, 0];
    weapons[1].crosshair_special = 0;
    weapons[1].crosshair_minimum_range = 15;
    weapons[1].crosshair_maximum_range = 30;
    weapons[1].recoil = 750;
    weapons[1].recoil_guaranteed = [0, 35, 0];
    weapons[1].recoil_kick_change = [25, 15, 25];
    weapons[1].muzzle_flash_offset = [5488, -2742, 35300];
    weapons[1].muzzle_flash_size = 5;
    weapons[1].fire_delay = 0.100;
    weapons[1].reload_delay = 1.9;
    weapons[1].penetration_amount = 0.75;
    weapons[1].penetration_body_count = 2;
    weapons[1].damage = 20;
    weapons[1].bullet_spread = 7.5;
    weapons[1].shotcount = 1;
    weapons[1].fire_type = 1;
    weapons[1].weapon_weight = 1;
    weapons[1].multiplier_head = 3;
    weapons[1].multiplier_upper_torso = 1;
    weapons[1].multiplier_lower_torso = 1;
    weapons[1].multiplier_limbs = 1;

    weapons[1].frames[FRAME_FIRE_START] = 0;
    weapons[1].frames[FRAME_FIRE_END] = 2;
    weapons[1].frames[FRAME_RELOAD_START] = 3;
    weapons[1].frames[FRAME_RELOAD_END] = 26;
    weapons[1].frames[FRAME_RELOAD_CANCEL] = 13;
    weapons[1].frames[FRAME_SPRINT_IN_START] = 33;
    weapons[1].frames[FRAME_SPRINT_IN_END] = 34;
    weapons[1].frames[FRAME_SPRINT_START] = 35;
    weapons[1].frames[FRAME_SPRINT_END] = 40;
    weapons[1].frames[FRAME_SPRINT_OUT_START] = 41;
    weapons[1].frames[FRAME_SPRINT_OUT_END] = 42;
    weapons[1].frames[FRAME_TAKE_OUT_START] = 29;
    weapons[1].frames[FRAME_TAKE_OUT_END] = 32;
    weapons[1].frames[FRAME_PUT_OUT_START] = 26;
    weapons[1].frames[FRAME_PUT_OUT_END] = 29;

    weapons[1].frame_sound_number[0] = 5;
    weapons[1].frame_sound_number[1] = 12;
    weapons[1].frame_sound_number[2] = 18;
    weapons[1].frame_sound_name[0] = "sounds/weapons/colt/magout.wav";
    weapons[1].frame_sound_name[1] = "sounds/weapons/colt/magin.wav";
    weapons[1].frame_sound_name[2] = "sounds/weapons/colt/slide.wav";

    weapons[1].precache_models[0] = "models/weapons/m1911/g_colt.mdl";
    weapons[1].precache_models[1] = "models/weapons/m1911/v_colt.mdl";
    weapons[1].precache_sounds[0] = "sounds/weapons/colt/shoot.wav";
    weapons[1].precache_sounds[1] = "sounds/weapons/colt/magout.wav";
    weapons[1].precache_sounds[2] = "sounds/weapons/colt/magin.wav";
    weapons[1].precache_sounds[3] = "sounds/weapons/colt/slide.wav";
}