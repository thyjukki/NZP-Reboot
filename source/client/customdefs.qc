//Various globals that are used in this FTEQW example are defined here, they are not used by the engine itself

#pragma warning disable Q302

#define true    1
#define false   0

vector cursor_pos; /* Current mouse cursor position, updated in csqc_inputevent */
float g_width, g_height; /* Globals for screen width and height */

float walk;

//Menu stuff
float in_menu; //what menu are we in
float time_in_menu;

entity player;
entity vmodel;
entity v2model;
entity mzlflash;
entity dummy;

float weapon;

float tracercounter;
.float rate;
.vector targetpos;

vector vmodel_targetpos;
vector v2model_targetpos;
vector vmodel_currentpos;
vector v2model_currentpos;
vector vmodel_velocity;
vector v2model_velocity;
vector vmodel_avelocity;
vector v2model_avelocity;
vector vmodel_muzzleoffset;
vector v2model_muzzleoffset;

const float MENU_NONE = 0;
const float MENU_MAIN = 1;
const float MENU_SINGLE = 2;
const float MENU_MULTI = 4;
const float MENU_SETTINGS = 8;
const float MENU_ABOUT = 16;
const float MENU_JOIN = 32;
const float MENU_PAUSE = 64;
const float MENU_IGS = 128;
const float MENU_RES = 256;
const float MENU_GSETTINGS = 512;
const float MENU_CSETTINGS = 1024;
const float MENU_CUSTOMS = 2048;
const float MENU_ACHIEVEMENTS = 4096;
const float MENU_CONSETTINGS = 8192;
const float MENU_AUDSETTINGS = 16384;


float useprint_type;
float useprint_weapon;
float useprint_cost;
float useprint_time;

string scrolltext;
float stext;
float scrollopacity;
float scrollheight;

float HUD_Change_time; 
float Hitmark_time;
float crosshair_spread_time;
float zoom_2_time;
float broadcast_time;
float broadcast_type;

float weaponframetime;
float weapon2frametime;
float oldweaponframe;
float oldweapon2frame;
float curweaponframe;
float curweapon2frame;
float interpolating;
float interpolating2;


float rounds;
float perks;
float rounds_change;

float playerpoints[4]; 			// player point holders, player 1 points are index 0, player 2 at 1...
float playerkills[4];           // player kill holders, player 1 points are index 0, player 2 at 1...
string playernames[4]; 			// player name holders, player 1 name at index 0, player 2 at 1...
float player_count;
float score_show;

#define MAX_ACHIEVEMENTS    42

var struct achievementlist_t
{
    string      img;
    float       unlocked;
    string      name;
    string      description;
    float       progress;
} achievements[MAX_ACHIEVEMENTS];

float active_achievement;
float current_achievement_page;
float achievement_pages;


float K_LEFTDOWN, K_RIGHTDOWN, K_BACKDOWN, K_FORWARDDOWN;

#define 	P_JUG		1
#define 	P_DOUBLE	2
#define 	P_SPEED		4
#define 	P_REVIVE	8
#define 	P_FLOP		16
#define 	P_STAMIN	32

vector TEXT_LIGHTBLUE = [(2/255), (118/255), (181/255)];
vector TEXT_ORANGE    = [(235/255), (189/255), 0];
vector TEXT_GREEN     = [0, (230/255), (34/255)];
vector TEXT_RED       = [1, 0, 0];

float fade_time;
float fade_type;

float menu_initialized;

float customs_interact;

vector camang;		// used for punches

//world text
string chaptertitle;
string location;
string date;
string person;

//custom hud
string huddir;

//this just cleans up settings a bit..
#define     S_ENABLED       "Enabled"
#define     S_DISABLED      "Disabled"
float projBr;
float wasigs;

//controls
#define MAX_BINDS   14

float editBind[MAX_BINDS];
string buttonBind[MAX_BINDS];
string tempBind[MAX_BINDS];

// resolution
#define MAX_43      3
#define MAX_54      1
#define MAX_1610    5
#define MAX_169     10
#define MAX_219     2
float aspectratio;
float fullscreenval;
float active_swidth;
float active_sheight;
float screen_width_43[MAX_43];
float screen_height_43[MAX_43];
float screen_width_54[MAX_54];
float screen_height_54[MAX_54];
float screen_width_1610[MAX_1610];
float screen_height_1610[MAX_1610];
float screen_width_169[MAX_169];
float screen_height_169[MAX_169];
float screen_width_219[MAX_219];
float screen_height_219[MAX_219];

//controller buttons

/*
    reference:
    0: A
    1: B
    2: X
    3: Y
    4: DPAD UP
    5: DPAD DOWN
    6: DPAD LEFT
    7: DPAD RIGHT

*/
float GPActive[32];

#define VERSION_STRING  "v1.0"