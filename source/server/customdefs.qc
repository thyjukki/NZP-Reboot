// put custom server-only globals and fields here

#ifndef PSP
#ifndef NX
#pragma target FTE
#endif
#endif 

#define true 1
#define false 0

#define FL_JUMPRELEASED  4096

// achievement tracking
.float 	ach_tracker_npnp;
.float 	ach_tracker_abst;
float 	ach_tracker_spin;
float 	ach_tracker_luck;
.float 	ach_tracker_coll;
float 	ach_tracker_col2;
float 	ach_tracker_barr;

float framecount;
float deathmatch;
float coop;
.vector oldvelocity;
.float lastsound_time;
.float isspec;
string mappath;
.float playernum;
.float ads_toggle;
float player_count;
entity pl1;
.string fog;		// used for hacking in changing fog from world.fog for legacy maps

entity local_client;
.float stance;
.float stancereset;
.float changestance;
.vector new_ofs;

//money
.float points;
.float cost;
.float cost2;
void(entity person, float expamt , float doublepoint) addmoney;

//stats
.float score;
.float kills;
.float headshots;
#ifdef PC
.float facingenemy;
#endif

//doors
.float state;
#define STATE_TOP		0
#define STATE_BOTTOM	1
#define STATE_UP		2
#define STATE_DOWN		3
.float /*worldtype,*/ delay, wait, lip, /*light_lev,*/ speed, style/*, skill*/;

entity activator;
.float requirespower;

//player funcs
#ifdef PC
.float zoom;
#endif

float sprint_max_time = 4.0;
.float sprinting;
.float weaponskin;
.float secondaryweaponskin;
.float thirdweaponskin;
.float stamina;
.float sprint_timer;
.float sprint_duration;
.float sprint_timer_stopped;
.float sprint_start_time;
.float sprint_stop_time;
.float sprint_rest_time;
void() W_SprintStop;
.float into_sprint;
.float dive;
.float dive_delay;
.float damagetimer;
.vector movement;

//Weaponsystem defines
void SwitchWeapon(float to);
void GetUp();
void Weapon_Logic();
.float downed;
.float fire_delay;
.float fire_delay2;
.float reload_delay;
.float reload_delay2;
.float switch_delay;
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
.float thirdammo;
.float semi;
.float semi2;
.float semiuse;
.float semiswitch;
.float semireload;
.float secondarymag;
.float secondarymag2;
.float secondaryweapon;
.float thirdmag;
.float thirdmag2;
.float thirdweapon;
.float NeedLoad;
.string weapon2model;
.float weapon2frame;
.float reloadinterupted;
.float hitcount;
.float weaponnum;	// 0 for weapon one, 1 for second weapon...we invert value for easy comparison, a third gun would need to be hardwired

//Reviving
.float invoke_revive;
.float reviving;
.float revived;
.float beingrevived;
.float downedloop;

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

#define 	VEC_HULL_MIN  		'-16 -16 -32'
#define 	VEC_HULL_MAX  		'16 16 40'
#define 	VEC_HULL2_MIN   	'-32 -32 -24'
#define 	VEC_HULL2_MAX  		'32 32 64'

#define     VEC_VIEW_OFS  '0 0 32'

#ifdef PSP
#define 	MAX_ZOMB 	  12
#else
#define 	MAX_ZOMB 	  24
#endif

vector	trace_plane_normal;


// AI definitions
//Used for global one-zombie-at-a-time type ai
void Do_Zombie_AI();
.string aistatus;
entity lastzombie;
float zombie_spawn_delay; // time before spawning, in seconds.
float zombie_spawn_timer; // the actual timer for spawn delay
//Other AI definitions
.vector box1, box2, box3;//used for windows and zombies
.vector idlebox;
.vector hop_spot;//used for windows (zombies hop to these)
.vector goalorigin;
.float teslacount;
.float iszomb;
.float onfire;
.entity firer;
float crawler_num;
//==== Reference Vars ====
#define 	WWINDOW		1
#define 	WBOX1 		2
#define 	WBOX2 		4
#define 	WBOX3 		8
#define		WIDLEBOX 	16
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

.float washit;
.float hitamount;

.float laststep;
void(entity who) makeCrawler;
.float state;//used to delay making a crawler, ex) when zombie is rising from ground or climbing over barrier, turn zombie into a crawler afterwards

void() spawnAllZombEnts;
void() set_z_health;
float() spawn_a_zombieA;
float gotdog;
float dogRound;
float dogWave;
float z_health;
.float bleedingtime;
.float time_to_die;


float crandom();


// Door
.string killtarget;
.void() think1;
.vector finaldest;
.vector pos1, pos2/*, mangle*/;
.vector finalangle;
.float distance;
.float sequence;
.entity active_door;
.string door_model_target;
.string door_model_name;

//Perk and Power system
float isPowerOn;
.float isBuying; // naievil -- used for checking if a perk is being consumed, limits glitching
.float perks;
.float perk_delay;
.float revivesoda;
.float collected;

.float boxstatus;
.entity boxweapon;
.float spins;
.float papState;
float BoxWeapons[25];
entity boxLocations[32];
float boxCount;
vector boxOrigin;

#ifndef PSP
//powerups
.float x2_icon;
.float insta_icon;
#endif
.string powerup_vo;
float instakill_finished;
float insta_blink;
float x2_finished;
float x2_blink;
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

//Waypoints
void () Waypoint_Logic;
entity current_way;
float waypoint_mode;
entity active_way;

#define MAX_WAY_TARGETS		10
.string waynum;
.string targets[MAX_WAY_TARGETS];


//pathfinds
#define MAX_WAYPOINTS 256 //max waypoints
void LoadWaypointData();
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

#ifdef PC
waypoint_ai waypoints[MAX_WAYPOINTS];

// fog
string world_fog;

// lights 
#define EF_PURPLELIGHT		256		// fte already has some effect styles defined...
#endif

#define UT_HUD 				1
#define UT_ROUNDS_CHANGE 	2
#define UT_HM				3
#define UT_ZOOM2			4
#define UT_CROSSHAIR		5

//Misc patch definitions
.string teddyremovetarget;

.float oldz;		// used for fall damage that does not truly work correctly

.float sprint_delay;

//soft restart stuff for doors
.string oldmodel;
.vector oldorigin;
.float oldstate;
.float state;
.float isopen;

//world
.string chaptertitle;
.string location;
.string date;
.string person;
.string song;

//altered game elements
float G_STARTPOINTS;
float G_STARTROUND;
float G_PRONEPOINTS;
float G_STARTWEAPON[3];
float G_WORLDTEXT;
float G_PERKS;
float G_PERKPOWER;

//song easter egg
float sndTriggerCnt;
float sndActivCnt;
.float activated;

//teleporter
.entity tele_target;
.float mode;
.float cooldown;
.float isLinked;
.float waitLink;
.float tpTimer;
.float isTimed;
.entity host;

// GIBBING
#ifdef PC
.entity larm;
.entity rarm;
.entity head;
.vector	bbmins, bbmaxs;	
.float currentHitBoxSetup;
#endif

// PC Fog force
.float PC_fog;