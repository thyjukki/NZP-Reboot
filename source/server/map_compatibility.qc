//
// map_compatibility.qc - Entitiy conversions and utility functions in relation to compatibility with several codebases
//
void() Maps_DeleteRequiemEntities;
float() Maps_SeekRequiemWorldspawnValues;

//
// Macros
//
#define MAP_TYPE_REBOOT     0 // Designed for the NZ:P Reboot
#define MAP_TYPE_PATCH      1 // Designed for the NZ:P Demo Unofficial Patch, may ultimately go unused
#define MAP_TYPE_REQUIEM    2 // Designed for the NZ:P Mod 'Requiem'
#define MAP_TYPE_BETA       3 // Designed for the NZ:P Beta

//
// Global variables
//
float Map_Type;               // Store the current Map type

//
// Spawn function re-declarations
//
void() perk_revive;
void() perk_juggernog;
void() perk_speed;
void() perk_double;
void() perk_flopper;
void() perk_staminup;
void() perk_mule;
void() perk_pap;
void() place_model;
void() item_barricade;
void (vector here, float which, string special, string trg, string trg2, string trg3, string trg4, string trg5, string trg6, string trg7, string trg8) Create_Waypoint;

//
// Maps_DetermineMapType()
// Checks the existance and fields of several
// entities in an attempt to determine which
// codebase the map was designed for.
//
float() Maps_DetermineMapType =
{
    entity e;

    // NZ:P Beta check
    e = findfloat(world, fgdtype, MAP_TYPE_BETA);
    if (e != world)
        return MAP_TYPE_BETA;

    // NZ:P Requiem check
    e = findfloat(world, fgdtype, MAP_TYPE_REQUIEM);
    if (e != world) {
        Maps_DeleteRequiemEntities();
        return MAP_TYPE_REQUIEM;
    }

    // Check for Requiem again, by looking at worldspawn
    if (Maps_SeekRequiemWorldspawnValues() == true)
        return MAP_TYPE_REQUIEM;

    // If none of the above, it's safe to proceed without change
    return MAP_TYPE_REBOOT;
}

// ==============================================================================
//
//                          NZ:P Beta Compatibility
//
// ==============================================================================

//
// Maps_LoadBetaWaypointData()
// Attempts to find and parse a waypoint file
// made for NZ:P beta
//
void() Maps_LoadBetaWaypointData =
{
    float file;
    file = fopen(mappath, FILE_READ);

    if (file == -1)
        return;

    float loop;
    string line;
    loop = true;

    vector orig;
    float id;
    float link1, link2, link3, link4;

    while(loop) {
        line = fgets(file);

        if not (line) {
            loop = false;
            break;
        }

        orig = stov(line);
        dprint(strcat("origin: ", line, "\n"));
        line = fgets(file);
        id = stof(line);
        dprint(strcat("id: ", line, "\n"));
        line = fgets(file);
        dprint(strcat("link1: ", line, "\n"));
        link1 = stof(line);
        line = fgets(file);
        dprint(strcat("link2: ", line, "\n"));
        link2 = stof(line);
        line = fgets(file);
        dprint(strcat("link3: ", line, "\n"));
        link3 = stof(line);
        line = fgets(file);
        dprint(strcat("link4: ", line, "\n"));
        link4 = stof(line);
        // ignore 'owner'
        line = fgets(file);
        line = fgets(file);
        line = fgets(file);
        line = fgets(file);
        // end ignorance

        Create_Waypoint(orig, id, "", ftos(link1), ftos(link2), ftos(link3), ftos(link4), "0", "0", "0", "0");
    }

    fclose(file);
}

//
// Maps_ConvertBetaModelProp()
// Converts some of the vanilla NZ:P Beta model
// paths to the Reboot location/model
//
string(string model) Maps_ConvertBetaModelProp =
{
    switch(model) {
        case "progs/g_gewehr.mdl":
            return "models/weapons/gewehr/g_gewehr.mdl";
        case "progs/lamp.mdl":
            return "models/props/lamp_oil.mdl";
        case "progs/g_kars.mdl":
            return "models/weapons/kar/g_kars.mdl";
        case "progs/grenade.mdl":
            return "models/weapons/grenade/g_grenade.mdl";
        case "progs/g_betty.mdl":
            return "models/weapons/grenade/g_betty.mdl";
        case "progs/g_mp40.mdl":
            return "models/weapons/mp40/g_mp40.mdl";
        case "progs/g_db.mdl":
            return "models/weapons/db/g_db.mdl";
        case "progs/g_stg.mdl":
            return "models/weapons/stg/g_stg.mdl";
        case "progs/g_ppsh.mdl":
            return "models/weapons/ppsh/g_ppsh.mdl";
        case "progs/g_bowie.mdl":
            return "progs/GModels/g_bowie.mdl";
        case "progs/g_mp5.mdl":
            return "models/weapons/thomp/g_thomp.mdl";
        case "progs/g_m1a1.mdl":
            return "models/weapons/m1carbine/g_m1a1.mdl";
        case "progs/jeep.mdl":
            return "progs/Props/jeep.mdl";
        case "progs/g_trench.mdl":
            return "models/weapons/trench/g_trench.mdl";
        case "progs/g_fg.mdl":
            return "models/weapons/fg42/g_fg.mdl";
        default:
            return model;
    }

    return model;
}

//
// Maps_ConvertBetaWeaponID(weapon)
// Converts the IDs for NZ:P Beta weapons
// into the current NZ:P Reboot IDs.
//
float(float weapon) Maps_ConvertBetaWeaponID =
{
    switch(weapon) {
        case 1:
            return W_COLT;
        case 64:
            return W_RAY;
        case 129:
            return W_KAR_SCOPE;
        case 130:
            return W_BAR;
        case 131:
            return W_M1A1;
        case 132:
            return W_M2;
        case 133:
            return W_TESLA;
        case 134:
            return W_THOMPSON;
        case 135:
            return W_SAWNOFF;
        case 136:
            return W_PPSH;
        case 137:
            return W_DB;
        case 138:
            return W_KAR;
        case 139:
            return W_FG;
        case 140:
            return W_TRENCH;
        case 141:
            return W_MG;
        case 142:
            return W_GEWEHR;
        case 143:
            return W_BROWNING;
        case 144:
            return W_THOMPSON; // Formerly MP5, just default to thompson (for now?)
        case 145:
            return W_357;
        case 146:
            return W_M1;
        case 147:
            return W_BIATCH;
        case 148:
            return W_MP40;
        case 149:
            return W_PANZER;
        case 150:
            return W_PTRS;
        case 153:
            return W_BK;
        case 154:
            return W_STG;
        case 155:
            return W_BETTY;
        case 156:
            return W_GRENADE;
        case 182:
            return W_TYPE;
        case 157:
            return W_PORTER;
        case 158:
            return W_HEADCRACKER;
        case 159:
            return W_WIDOW;
        case 160:
            return W_WIDDER;
        case 161:
            return W_FIW;
        case 162:
            return W_WUNDER;
        case 163:
            return W_GIBS;
        case 164:
            return W_SNUFF;
        case 165:
            return W_REAPER;
        case 166:
            return W_BORE;
        case 167:
            return W_ARMAGEDDON;
        case 168:
            return W_IMPELLER;
        case 169:
            return W_GUT;
        case 170:
            return W_BARRACUDA;
        case 171:
            return W_COMPRESSOR;
        case 172:
            return W_ACCELERATOR;
        case 173:
            return W_KILLU;
        case 174:
            //return W_KOLLIDER;
            return W_GIBS; // MP5, again -> thompson
        case 175:
            return W_M1000;
        case 176:
            return W_AFTERBURNER;
        case 177:
            return W_LONGINUS;
        case 178:
            return W_PENETRATOR;
        case 179:
            return W_KRAUS;
        case 180:
            return W_SPATZ;
        case 181:
            return W_BOWIE;
        case 183:
            return W_SAMURAI;
        default:
            return 0;
    }

    return 0;
}

//
// NZ:P Beta entity conversions
//

//
// Maps_ConvertEntitiesFromBeta()
// Converts Entities that have the same classnames now
// as they did in NZ:P Beta.
//
void() Maps_ConvertEntitiesFromBeta =
{
    entity e;

    // buy_weapon
    e = find(world, classname, "buy_weapon");
    while(e != world) {
        e.weapon = Maps_ConvertBetaWeaponID(e.weapon);

        e = find(e, classname, "buy_weapon");
    }

    // place_model
    e = find(world, classname, "place_model");
    while(e != world) {
        e.model = Maps_ConvertBetaModelProp(e.model);
        setmodel(e, e.model);

        e = find(e, classname, "place_model");
    }

    // power_switch
    e = find(world, classname, "power_switch");
    while(e != world) {
        #ifdef PC
        e.scale = 0.85;
        #endif
        setsize(e, '-16 -16 0', '16 16 20');

        e = find(e, classname, "power_switch");
    }

    // mystery box
    e = find(world, classname, "mystery");
    while(e != world) {
        #ifdef PC
        e.scale = 0.66;
        #endif

        e = find(e, classname, "mystery");
    }

    // mystery box tp spot
    e = find(world, classname, "mystery_box_tp_spot");
    while(e != world) {
        #ifdef PC
        e.scale = 0.66;
        #endif

        e = find(e, classname, "mystery_box_tp_spot");
    }
}

// perk_revive
void() item_revive =
{
    perk_revive();
    self.fgdtype = MAP_TYPE_BETA;

    #ifdef PC
    self.scale = 0.85;
    #endif
}

// perk_juggernog
void() item_juggernog =
{
    perk_juggernog();
    self.fgdtype = MAP_TYPE_BETA;

    #ifdef PC
    self.scale = 0.85;
    #endif
}

// perk_speed
void() item_speed =
{
    perk_speed();
    self.fgdtype = MAP_TYPE_BETA;

    #ifdef PC
    self.scale = 0.85;
    #endif
}

// perk_double
void() item_douple =
{
    perk_double();
    self.fgdtype = MAP_TYPE_BETA;

    #ifdef PC
    self.scale = 0.85;
    #endif
}

// perk_flopper
void() item_flopper =
{
    perk_flopper();
    self.fgdtype = MAP_TYPE_BETA;

    #ifdef PC
    self.scale = 0.85;
    #endif
}

// perk_staminup
void() item_staminup =
{
    perk_staminup();
    self.fgdtype = MAP_TYPE_BETA;

    #ifdef PC
    self.scale = 0.85;
    #endif
}

// perk_pap
void() item_pap =
{
    perk_pap();
    self.fgdtype = MAP_TYPE_BETA;

    #ifdef PC
    self.scale = 0.85;
    #endif

    self.origin_z += 25;
}

// place_model
void() func_model =
{
    self.model = Maps_ConvertBetaModelProp(self.model);
    place_model();
}

// item_barricade
void() item_cover =
{
    item_barricade();
    #ifdef PC
    self.scale = 0.62;
    #endif
    self.origin_z += 56;
    makevectors(self.angles);
    setsize(self, '-30 -30 -10','30 30 10');
    setorigin(self, self.origin);
    self.box1 = self.origin + (v_forward * -50) + (v_up * -50);
	self.box2 = self.box1 + (v_right * 50);	
	self.box3 = self.box1 + (v_right * -50);
	self.idlebox = self.box1 + (v_forward * -50);
    self.hop_spot = self.origin + v_forward * 50;
    self.hop_spot_x -= 5;
	self.hop_spot_z -= 25;

    self.fgdtype = MAP_TYPE_BETA;
}

// ==============================================================================
//
//                       NZ:P Requiem Compatibility
//
// ==============================================================================

//
// Maps_SeekRequiemWorldspawnValues()
// Looks through various NZ:P Requiem worldspawn values
// to try to find any that exist.
//
float() Maps_SeekRequiemWorldspawnValues =
{
    // 'Time Between Rounds'
    if (world.roundtime != 0)
        return true;

    // 'Round Zombies Begin Running'
    if (world.runround != 0)
        return true;

    // 'Powerup Rarity'
    if (world.puchance != 0)
        return true;

    // 'Perk Shader Design'
    if (world.hudtype != 0)
        return true;

    // 'Round Sound Style'
    if (world.roundsnd != 0)
        return true;

    // 'Crew'
    if (world.chartype != 0)
        return true;

    // 'Perk Limit'
    if (world.limit != 0)
        return true;

    // 'Starting Weapon'
    if (world.weapon != 0)
        return true;

    // 'Starting Magazine'
    if (world.currentmag != 0)
        return true;

    // 'Starting Reserve Ammo'
    if (world.currentammo != 0)
        return true;

    // 'Starting Points'
    if (world.points != 0)
        return true;

    // 'Zombie Style'
    if (world.walktype != 0)
        return true;
    
    return false;
}

//
// Maps_ConvertEntitiesFromRequiem()
// Converts Entities that have the same classnames now
// as they did in NZ:P Requiem.
//
void() Maps_ConvertEntitiesFromRequiem =
{
    entity e;

    e = find(world, classname, "buy_weapon");
    while(e != world) {

        switch(e.sequence) {
            case 26:
                e.sequence = 1;
                e.weapon = 2;
                break;
            case 27:
                e.sequence = 12;
                e.weapon = 13;
                break;
            case 28:
                e.sequence = 22;
                e.weapon = 23;
                break;
            default: 
                break;
        }

        e = find(e, classname, "buy_weapon");
    }

    // * weapon chalks were out of sequence! fix them
    // * redirect bo1 weapons
    e = find(world, classname, "weapon_wall");
    while(e != world) {

        switch(e.sequence) {
            case 29:
                e.sequence = 11;
                break;
            case 31:
                e.sequence = 14;
                break;
            case 36:
                e.sequence = 17;
                break;
            case 37:
                e.sequence = 18;
                break;
            case 30:
                e.sequence = 21;
                break;
            case 35:
                e.sequence = 23;
                break;
            case 34:
                e.sequence = 24;
                break;
            case 32:
                e.sequence = 26;
                break;
            // convert bo1 weapons to counterparts
            case 26:
                // olympia -> kar98
                e.sequence = 1;
                break;
            case 27:
                // m14 -> m1a1 carbine
                e.sequence = 12;
                break;
            case 28:
                // stakeout -> trenchgun
                e.sequence = 22;
                break;
            default:
                break;
        }

        e.frame = e.sequence;
        e = find(e, classname, "weapon_wall");
    }
}

//
// Maps_DeleteRequiemEntities()
// Deletes all NZ:P Requiem entities that
// are not currently a part of the game to
// save on resources.
//
void() Maps_DeleteRequiemEntities =
{
    entity e;

    e = find(world, classname, "perk_bloodbullets");
    while (e != world) {
        remove(e);
        e = find(e, classname, "perk_bloodbullets");
    }

    e = find(world, classname, "perk_candolier");
    while (e != world) {
        remove(e);
        e = find(e, classname, "perk_candolier");
    }

    e = find(world, classname, "perk_tombstone");
    while (e != world) {
        remove(e);
        e = find(e, classname, "perk_tombstone");
    }

    e = find(world, classname, "perk_ammomatic");
    while (e != world) {
        remove(e);
        e = find(e, classname, "perk_ammomatic");
    }

    e = find(world, classname, "perk_cherry");
    while (e != world) {
        remove(e);
        e = find(e, classname, "perk_cherry");
    }

    e = find(world, classname, "perk_gobblegum");
    while (e != world) {
        remove(e);
        e = find(e, classname, "perk_gobblegum");
    }

    e = find(world, classname, "func_bank_withdrawl");
    while (e != world) {
        remove(e);
        e = find(e, classname, "func_bank_withdrawl");
    }

    e = find(world, classname, "func_bank_deposit");
    while (e != world) {
        remove(e);
        e = find(e, classname, "func_bank_deposit");
    }

    e = find(world, classname, "func_soulbox");
    while (e != world) {
        remove(e);
        e = find(e, classname, "func_soulbox");
    }

    e = find(world, classname, "func_lava");
    while (e != world) {
        remove(e);
        e = find(e, classname, "func_lava");
    }

    e = find(world, classname, "crafting_table");
    while (e != world) {
        remove(e);
        e = find(e, classname, "crafting_table");
    }

    e = find(world, classname, "part_dolly");
    while (e != world) {
        remove(e);
        e = find(e, classname, "part_dolly");
    }

    e = find(world, classname, "part_grate");
    while (e != world) {
        remove(e);
        e = find(e, classname, "part_grate");
    }

    e = find(world, classname, "part_clamp");
    while (e != world) {
        remove(e);
        e = find(e, classname, "part_clamp");
    }

    e = find(world, classname, "item_jeep");
    while (e != world) {
        remove(e);
        e = find(e, classname, "item_jeep");
    }

    e = find(world, classname, "egg_music");
    while (e != world) {
        remove(e);
        e = find(e, classname, "egg_music");
    }
}

//
// NZ:P Requiem Entity Conversions
//

// dummy entities
void() perk_bloodbullets        = {self.fgdtype = MAP_TYPE_REQUIEM;}
void() perk_candolier           = {self.fgdtype = MAP_TYPE_REQUIEM;}
void() perk_tombstone           = {self.fgdtype = MAP_TYPE_REQUIEM;}
void() perk_ammomatic           = {self.fgdtype = MAP_TYPE_REQUIEM;}
void() perk_whoswho             = {self.fgdtype = MAP_TYPE_REQUIEM;}
void() perk_cherry              = {self.fgdtype = MAP_TYPE_REQUIEM;}
void() perk_gobblegum           = {self.fgdtype = MAP_TYPE_REQUIEM;}
void() func_bank_widthdrawl     = {self.fgdtype = MAP_TYPE_REQUIEM;}
void() func_bank_deposit        = {self.fgdtype = MAP_TYPE_REQUIEM;}
void() func_soulbox             = {self.fgdtype = MAP_TYPE_REQUIEM;}
void() func_lava                = {self.fgdtype = MAP_TYPE_REQUIEM;}
void() crafting_table           = {self.fgdtype = MAP_TYPE_REQUIEM;}
void() part_dolly               = {self.fgdtype = MAP_TYPE_REQUIEM;}
void() part_grate               = {self.fgdtype = MAP_TYPE_REQUIEM;}
void() part_clamp               = {self.fgdtype = MAP_TYPE_REQUIEM;}
void() item_jeep                = {self.fgdtype = MAP_TYPE_REQUIEM;}
void() egg_music                = {self.fgdtype = MAP_TYPE_REQUIEM;}

// perk_mule
void() perk_mulekick =
{
    perk_mule();
    self.fgdtype = MAP_TYPE_REQUIEM;
}