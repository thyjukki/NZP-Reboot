// put custom server-only globals and fields here

#pragma target FTE

#define true 1
#define false 0

const float FL_JUMPRELEASED = 4096;

float framecount;
float deathmatch;
float coop;
.vector oldvelocity;
.float lastsound_time;
.float isspec;
string mappath;


//A few server variables
//assigned once immediately after the map is loaded
float sv_gravity;
float sv_maxspeed;

//money
.float points;
.float cost;
.float cost2;
void(entity person, float expamt , float doublepoint) addmoney;

//doors
.float state;
float STATE_TOP		= 0;
float STATE_BOTTOM	= 1;
float STATE_UP		= 2;
float STATE_DOWN		= 3;
.float /*worldtype,*/ delay, wait, lip, /*light_lev,*/ speed, style/*, skill*/;

entity activator;

//player funcs
.float zoom;
.float sprinting;
.float weaponskin;
.float stamina;
void() W_SprintStop;
.float into_sprint;


//Weaponsystem defines
void SwitchWeapon(float to);
void GetUp();
void Weapon_Logic();
.float downed;
.float fire_delay;
.float fire_delay2;
.float reload_delay;
.float reload_delay2;
.float health_delay;
.float progress_bar;
.float progress_bar_time;
.float progress_bar_percent;
.float weaponbk;
.float currentmag;
.float currentmag2;
.float currentmagbk;
.float currentmagbk2;
.float currentammobk;
.float secondaryammo;
.float semi;
.float semi2;
.float semiuse;
.float semiswitch;
.float semireload;
.float secondarymag;
.float secondarymag2;
.float secondaryweapon;
.float NeedLoad;
.string weapon2model;
.float weapon2frame;
.float reloadinterupted;
.float hitcount;

#define S_LEFT 0
#define S_RIGHT 1
#define S_BOTH 2

//Knife 
.float semiknife;
.float knife_delay;
.float bowie;

//Grenades
.float grenades;
.float pri_grenade_state;
.float bk_nade;
.float grenade_delay;
.float secondary_grenades;
.float primary_grenades;
.float throw_delay;

//weapon frames
void Set_W_Frame (float startframe, float endframe, float duration, float funccalledin, float animtype, void(optional float t) endanimfunc, string set_model, float dontstartnew, float side);
.float weapon_animduration;
.float weapon2_animduration;
.float weapon_anim_type;
.float weapon2_anim_type;
.float anim_weapon_time;
.float anim_weapon2_time;
.float weaponframe_end;
.float weapon2frame_end;
.float callfuncat;
.float callfuncat2;
.float new_anim_stop;
.float new_anim2_stop;
.float anim_reversed;
.float anim2_reversed;
.void() animend;
.void(optional float t) animend2;


//Null functions
void() SUB_Null = {};
void() SUB_Null2 = {};



vector	VEC_HULL_MIN = '-16 -16 -32';
vector	VEC_HULL_MAX = '16 16 40';
vector	VEC_HULL2_MIN = '-32 -32 -24';
vector	VEC_HULL2_MAX = '32 32 64';
vector  VEC_VIEW_OFS  = '0 0 32';
vector	trace_plane_normal;


// AI definitions
//Used for global one-zombie-at-a-time type ai
void Do_Zombie_AI();
.string aistatus;
entity lastzombie;
//Other AI definitions
.vector box1, box2, box3;//used for windows and zombies
.vector idlebox;
.vector hop_spot;//used for windows (zombies hop to these)
.vector goalorigin;
//==== Reference Vars ====
const float WWINDOW = 1; 
const float WBOX1 = 2;
const float WBOX2 = 4;
const float WBOX3 = 8;
const float WIDLEBOX = 16;
//========================

//we're using usedent for who is currently hopping the window
//Used for windows to keep track of what zombies are at windows
.entity box1owner, box2owner, box3owner;

.entity usedent;
//.float used;//used for the window boxes//not anymore
.float outside;//used for knowing if a zomibe has hopped window yet
.float chase_enemy_time;
.float chase_time;
.float enemy_timeout;
//.float pathing;
.float calc_time; //used as a delay thing (so zombie ai doesn't run 100% of the time
.string target2;
.string target3;
.string target4;
.string target5;
.string target6;
.string target7;
.string target8;
.string wayTarget;
.entity active_door;//Set in waypoint mode
.string targetname;//the name of an entitys
entity lastspawn;//last spawn point used by spawning code
.entity goaldummy; //Used to store the origin of the zombies target
.float goalway; //Used to store the origin of the zombies target
.float walktype;//decides animations and moving speeds for zombies
.void() th_walk;
//.void() th_run;
.void() th_die;
.void() th_melee;
.void() th_idle;
.void() th_windowhop;
.void() th_diewunder;

.void() th_fall;
.void() th_falling;
.void() th_land;

.void() th_jump;
.void() th_grabledge;
.float tries;
.float hop_step;//KEEPS TRACK OF WHERE WE ARE ON THE HOPPING PART

float INACTIVE = 1;

float tracemove(vector start, vector min, vector max, vector end, float nomonsters, entity forent);

.float way_path[40];
.float way_cur;

.float sound_time;
.float s_time;
float sounds_playing;

.float fall;
//.vector lastOrg;//Zombie's last origin, for checking stuckness
//.float OrgStuckCount;
.float crawling;
.float true_org_z;//Zombie's actual current origin (origin_z lerps)

.float washit;
.float hitamount;

.float laststep;
//void(entity who) makeCrawler;
.float state;//used to delay making a crawler, ex) when zombie is rising from ground or climbing over barrier, turn zombie into a crawler afterwards

void() spawnAllZombEnts;
void() set_z_health;
float() spawn_a_zombieA;
float z_health;
.float bleedingtime;
.float time_to_die;
.float index;//Used as a zombie ID (zombie uses it to access it's own AI Pathfinding struct)


float crandom();


// Door
.string killtarget;
.void() think1;
.vector finaldest;
.vector pos1, pos2/*, mangle*/;
.float sequence;
.entity active_door;

//Perk and Power system
float isPowerOn;
.float isBuying; // naievil -- used for checking if a perk is being consumed, limits glitching
.float perks;
.float perk_delay;
.float revivesoda;

.float boxstatus;
.entity boxweapon;

.float papState;

//powerups
float instakill_finished;
//float insta_blink;
float x2_finished;
//float x2_blink;
float total_windows_down;
float total_powerup_points;
float powerup_activate;

//rounds
float roundinit;
float roundtype;
float Current_Zombies;
float Total_Zombies;
float Remaining_Zombies;
float Delay_Time;
float spawn_time;
float round_changetime;
float game_over;
float blink_return;
float delay_at_round;
float spawn_delay;
float maxreward;
float totalreward;
float totalpowerups;
float sounds_playing;

float rounds;
float rounds_change;

#define MAX_ZOMBIES 12

//Waypoints
void () Waypoint_Logic;
entity current_way;
float waypoint_mode;
float navmesh_edit_mode;
entity active_way;

#define MAX_WAY_TARGETS		10
.string waynum;
.string targets[MAX_WAY_TARGETS];




//Pathfind Defs
#define MAX_WAYPOINTS 256 //max waypoints
void() LoadWaypointData;
typedef struct
{
	vector org;
	float id;
	float g, f;
	float next, prev;
	float step;
	float target_id [MAX_WAY_TARGETS]; // Targets array number
	string targetdoor; //special tag is required for the closed waypoints
	float dist [MAX_WAY_TARGETS]; // Distance to the next waypoints
	float set;
} waypoint_ai;

#define SET_NONE	0
#define SET_OPEN	1
#define SET_CLOSED	2

waypoint_ai waypoints[MAX_WAYPOINTS];

#define UT_HUD 				1
#define UT_ROUNDS_CHANGE 	2
#define UT_HM				3

//======================= Navmesh defs ============================
void() Navmesh_Editor_Logic;
void() sv_load_navmesh_data;

//One struct for temp pathfinding calculations per zombie 
//pathfind_result sv_zombie_pathfind_result[MAX_ZOMBIES];
pathfind_result* sv_zombie_pathfind_result;

//=================================================================

//FIXME(Jukki) Place in better place
void(entity to, float type, float cost, float weapon) useprint = {
	
    
    msg_entity = to;
	WriteByte(MSG_ONE, SVC_CGAMEPACKET);
	WriteByte(MSG_ONE, EVENT_USEPRINT);
	WriteByte(MSG_ONE, type);
	WriteShort(MSG_ONE, cost);
	WriteByte(MSG_ONE, weapon);
}

float() crandom =
{
	return 2*(random() - 0.5);
}

void NotifyNewRound(float to) {
	WriteByte(MSG_ALL, SVC_CGAMEPACKET);
	WriteByte(MSG_ALL, EVENT_NEWROUND);
	WriteByte(MSG_ALL, to);
}

void SetRound(entity client, float to) {
    msg_entity = client;
	WriteByte(MSG_ONE, SVC_CGAMEPACKET);
	WriteByte(MSG_ONE, EVENT_SETROUND);
	WriteByte(MSG_ONE, to);
}

void SetPerk(entity client, float to) 
{
    msg_entity = client;
	WriteByte(MSG_ONE, SVC_CGAMEPACKET);
	WriteByte(MSG_ONE, EVENT_PERK);
	WriteLong(MSG_ONE, to);
}

void(float to) SwitchWeapon =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_WEAPONCHANGE);
	WriteByte(MSG_MULTICAST, to);
	msg_entity = self;
	multicast('0 0 0', MULTICAST_ONE);
}

void(string to, float skin) UpdateVmodel =
{
	
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_UPDATEVMODEL);
	WriteString(MSG_MULTICAST, to);
	WriteByte(MSG_MULTICAST, skin);
	msg_entity = self;
	multicast('0 0 0', MULTICAST_ONE);
}

void(string to, float skin) UpdateV2model =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_UPDATEV2MODEL);
	WriteString(MSG_MULTICAST, to);
	WriteByte(MSG_MULTICAST, skin);
	msg_entity = self;
	multicast('0 0 0', MULTICAST_ONE);
}

void SetUpdate(entity client, float type, float val1, float val2, float val3)
{
	if (type != 2)
	{
		msg_entity = client;
		WriteByte(MSG_ONE, SVC_CGAMEPACKET);
		WriteByte(MSG_ONE, EVENT_UPDATE);
		WriteByte(MSG_ONE, type); // UT_HUD, UT_ROUNDS_CHANGE
		WriteByte(MSG_ONE, val1); 
		WriteByte(MSG_ONE, val2);
		WriteByte(MSG_ONE, val3); // misc flags/vars for later if needed
	}
	else
	{
		WriteByte(MSG_ALL, SVC_CGAMEPACKET);
		WriteByte(MSG_ALL, EVENT_UPDATE);
		WriteByte(MSG_ALL, type); // UT_HUD, UT_ROUNDS_CHANGE
		WriteByte(MSG_ALL, val1); 
		WriteByte(MSG_ALL, val2);
		WriteByte(MSG_ALL, val3); // misc flags/vars for later if needed
	}
}

void WeaponSwitch(entity player) {
	float wep, cmag, cmag2, cammo;

	wep = other.weapon;
	other.weapon = other.secondaryweapon;
	other.secondaryweapon = wep;

	cmag = other.currentmag;
	other.currentmag = other.secondarymag;
	other.secondarymag = cmag;

	cmag2 = other.currentmag2;
	other.currentmag2 = other.secondarymag2;
	other.secondarymag2 = cmag2;

	cammo = other.currentammo;
	other.currentammo = other.secondaryammo;
	other.secondaryammo = cammo;

	entity tempe = self;
	self = player;
	SwitchWeapon(other.weapon);
	self = tempe;
}

//naievil (FIXME) No idea where this should go, maybe a dummys
void() SUB_Remove = {remove(self);}