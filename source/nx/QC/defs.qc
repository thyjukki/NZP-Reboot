/*
	defs.qc

	global definitions

	Copyright (C) 1996-1997  Id Software, Inc.

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to:

		Free Software Foundation, Inc.
		59 Temple Place - Suite 330
		Boston, MA  02111-1307, USA

*/

/*
==============================================================================

			SOURCE FOR GLOBALVARS_T C STRUCTURE

==============================================================================
*/

#define NX

//
// system globals
//
entity          self;
entity          other;
entity          world;
float           time;
float           frametime;
float           force_retouch;
string          mapname;
float 			deathmatch;
float 			coop;
float 			teamplay;
float           serverflags;
float           rounds;
float           rounds_change;
float           parm1, parm2, parm3, parm4, parm5, parm6, parm7, parm8, parm9, parm10, parm11, parm12, parm13, parm14, parm15, parm16;
vector          v_forward, v_up, v_right;
float           trace_allsolid;
float           trace_startsolid;
float           trace_fraction;
vector          trace_endpos;
vector          trace_plane_normal;
float           trace_plane_dist;
entity          trace_ent;
float           trace_inopen;
float           trace_inwater;
entity          msg_entity;                             // destination of single entity writes
void()          main;                                   // only for testing
void()          StartFrame;
void()          EndFrame;
void()          PlayerPreThink;
void()          PlayerPostThink;
void()          ClientKill;
void()          ClientConnect;
void()          PutClientInServer;            
void()          ClientDisconnect;
void()          SetNewParms;
void()          SetChangeParms;
void            end_sys_globals;


.float          modelindex;
.vector         absmin, absmax;
.float          ltime;
.float          movetype;
.float          solid;
.vector         origin;
.vector         oldorigin;
.vector         velocity;
.vector         angles;
.vector         avelocity;
.vector 		punchangle;
.string         classname;
.string         model;
.float          frame;
.float          skin;
.float          effects;
.vector         mins, maxs;
.vector         size;
.void()         touch;
.void()         use;
.void()         think;
.void()         blocked;
.float          nextthink;
.entity         groundentity;
.float          health;
.float          points;
.float          kills;
.float          weapon;
.string         weaponmodel;
.string         weapon2model;
.float          weaponframe;
.float          weapon2frame;
.float          currentammo;
.float          currentmag;
.float			zoom;
.float          weaponskin;
.float          weapon2skin;
.float          primary_grenades;
.float          secondary_grenades;
.float          grenades;
.float          perks;
.float          takedamage;
.entity         chain;
.float          deadflag;
.vector         view_ofs;
.float          button0;
.float          button1;
.float          button2;
.float 			button3;
.float 			button4;
.float 			button5;
.float 			button6;
.float 			button7;
.float 			button8;
.float          impulse;
.float          fixangle;
.vector         v_angle;
.float 			idealpitch;				// Naievil -- new 
.string         netname;
.entity         enemy;
.float          flags;
.float          colormap;
.float          team;
.float          max_health;
.float          teleport_time;
.float          armortype;
.float          armorvalue;
.float          waterlevel;
.float          watertype;
.float          ideal_yaw;
.float          yaw_speed;
.entity         aiment;
.entity 		head;
.entity			larm;
.entity 		rarm;
.entity         goalentity; 
.float          spawnflags;
.string         target;
.string         targetname;
.float          dmg_take;
.float          dmg_save;
.float           progress_bar;
.entity         dmg_inflictor;
.entity         owner;
.vector         movedir;
.string         message;
.float          sounds;
.string         noise, noise1, noise2, noise3;
.float           x2_icon;
.float           insta_icon;
.string			Weapon_Name_Touch;
.vector			ADS_Offset;
.vector         Flash_Offset;
.float 			Flash_Size;
.float          currentmag2;
.float          maxspeed;
.float          renderGrayscale;
void            end_sys_fields; 

/*
==============================================================================

				VARS NOT REFERENCED BY C CODE

==============================================================================
*/


//
// constants
//

float   FALSE                                   = 0;
float   TRUE                                    = 1;

// edict.flags
float   FL_FLY                                  = 1;
float   FL_SWIM                                 = 2;
float   FL_CLIENT                               = 8;    // set for all client edicts
float   FL_INWATER                              = 16;   // for enter / leave water splash
float   FL_MONSTER                              = 32;
float   FL_GODMODE                              = 64;   // player cheat
float   FL_NOTARGET                             = 128;  // player cheat
float   FL_ITEM                                 = 256;  // extra wide size for bonus items
float   FL_ONGROUND                             = 512;  // standing on something
float   FL_PARTIALGROUND                		= 1024; // not all corners are valid
float   FL_WATERJUMP                    		= 2048; // player jumping out of water
float   FL_JUMPRELEASED                 		= 4096; // for jump debouncing

// edict.movetype values
float   MOVETYPE_NONE                   		= 0;    // never moves
//float MOVETYPE_ANGLENOCLIP    				= 1;
//float MOVETYPE_ANGLECLIP              		= 2;
float   MOVETYPE_WALK                   		= 3;    // players only
float   MOVETYPE_STEP                   		= 4;    // discrete, not real time unless fall
float   MOVETYPE_FLY                    		= 5;
float   MOVETYPE_TOSS                   		= 6;    // gravity
float   MOVETYPE_PUSH                   		= 7;    // no clip to world, push and crush
float   MOVETYPE_NOCLIP                 		= 8;
float   MOVETYPE_FLYMISSILE             		= 9;    // fly with extra size against monsters
float   MOVETYPE_BOUNCE                 		= 10;
float   MOVETYPE_BOUNCEMISSILE  				= 11;   // bounce with extra size

// edict.solid values
float   SOLID_NOT                               = 0;    // no interaction with other objects
float   SOLID_TRIGGER                   		= 1;    // touch on edge, but not blocking
float   SOLID_BBOX                              = 2;    // touch on edge, block
float   SOLID_SLIDEBOX                 			= 3;    // touch on edge, but not an onground
float   SOLID_BSP                               = 4;    // bsp clip, touch on edge, block

float   DEAD_NO                                 = 0;
float   DEAD_DYING                              = 1;
float   DEAD_DEAD                               = 2;
float   DEAD_RESPAWNABLE               			= 3;

// takedamage values
float   DAMAGE_NO                               = 0;
float   DAMAGE_YES                              = 1;
float   DAMAGE_AIM                              = 2;

// point content values
float   CONTENT_EMPTY                   		= -1;
float   CONTENT_SOLID                   		= -2;
float   CONTENT_WATER                   		= -3;
float   CONTENT_SLIME                  			= -4;
float   CONTENT_LAVA                    		= -5;
float   CONTENT_SKY                             = -6;

float   STATE_TOP              					= 0;
float   STATE_BOTTOM   							= 1;
float   STATE_UP                				= 2;
float   STATE_DOWN              				= 3;

vector  VEC_ORIGIN 								= '0 0 0';

// protocol bytes
float   SVC_TEMPENTITY          				= 23;
float   SVC_KILLEDMONSTER       				= 27;
float   SVC_FOUNDSECRET         				= 28;
float   SVC_INTERMISSION        				= 30;
float   SVC_FINALE                     			= 31;
float   SVC_CDTRACK                    			= 32;
float   SVC_SELLSCREEN          				= 33;
float   SVC_SMALLKICK           				= 34;
float   SVC_BIGKICK                     		= 35;
float   SVC_MUZZLEFLASH         				= 39;

// sound channels
// channel 0 never willingly overrides
// other channels (1-7) allways override a playing sound on that channel
float   CHAN_AUTO              					= 0;
float   CHAN_WEAPON             				= 1;
float   CHAN_VOICE             					= 2;
float   CHAN_ITEM               				= 3;
float   CHAN_BODY               				= 4;
float   CHAN_NO_PHS_ADD 						= 8;    // ie: CHAN_BODY+CHAN_NO_PHS_ADD

float   ATTN_NONE               				= 0;
float   ATTN_NORM               				= 1;
float   ATTN_IDLE               				= 2;
float   ATTN_STATIC            					= 3;

// entity effects
#define	EF_BLUE					1
#define	EF_MUZZLEFLASH 			2
#define	EF_BRIGHTLIGHT 			4
#define	EF_RED		 			8
#define	EF_ORANGELIGHT			16
#define	EF_GREEN				32
#define	EF_LIGHT				64
#define	EF_NODRAW				128
#define EF_BRIGHTFIELD			256
#define EF_FULLBRIGHT 			512
#define EF_DARKLIGHT			1024
#define EF_DARKFIELD			2048
#define EF_PURPLELIGHT    		4096
#define EF_RAYRED		 	8196
#define EF_RAYGREEN		 	16384

// messages
float   MSG_BROADCAST  							= 0;            // unreliable to all
float   MSG_ONE                 				= 1;            // reliable to one (msg_entity)
float   MSG_ALL                 				= 2;            // reliable to all
float   MSG_INIT                				= 3;            // write to the init string
float   MSG_MULTICAST   						= 4;            // for multicast() call

// message levels
float   PRINT_LOW               				= 0;            // pickup messages
float   PRINT_MEDIUM    						= 1;            // death messages
float   PRINT_HIGH              				= 2;            // critical messages
float   PRINT_CHAT              				= 3;            // also goes to chat console

// multicast sets
float   MULTICAST_ALL   						= 0;            // every client
float   MULTICAST_PHS   						= 1;            // within hearing
float   MULTICAST_PVS   						= 2;            // within sight
float   MULTICAST_ALL_R 						= 3;            // every client, reliable
float   MULTICAST_PHS_R 						= 4;            // within hearing, reliable
float   MULTICAST_PVS_R 						= 5;            // within sight, reliable




//================================================

//
// globals
//
string  string_null;    		// null string, nothing should be held here
entity  activator;              // the entity that activated a trigger or brush
float   framecount;

//
// cvars checked each frame
//
float           teamplay;
float           deathmatch;

//================================================

//
// world fields (FIXME: make globals)
//
.string         wad;
.string         map;
.float          worldtype;      // 0=medieval 1=metal 2=base

//================================================

.string         killtarget;

//
// quakeed fields
//
.float          light_lev;              // not used by game, but parsed by light util
.float          style;


//
// monster ai
//
.void()         th_stand;
.void()         th_walk;
.void()         th_run;
.void()         th_missile;
.void()         th_melee;
.void(entity attacker, float damage)            th_pain;
.void()         th_die;

.entity         oldenemy;               // mad at this player before taking damage

.float          speed;

.float  lefty;

.float  search_time;
.float  attack_state;

float   AS_STRAIGHT             = 1;
float   AS_SLIDING              = 2;
float   AS_MELEE                = 3;
float   AS_MISSILE              = 4;

//
// player only fields
//
.float          voided;
.float          walkframe;

// Zoid Additions
.float		gravity;		// Gravity Multiplier (0 to 1.0)



.float          attack_finished;
.float          pain_finished;

.float          invincible_finished;
.float          invisible_finished;
.float          super_damage_finished;
.float          radsuit_finished;

.float          invincible_time, invincible_sound;
.float          invisible_time, invisible_sound;
.float          super_time, super_sound;
.float          rad_time;
.float          fly_sound;

.float          axhitme;

.float          show_hostile;   // set to time+0.2 whenever a client fires a
							// weapon or takes damage.  Used to alert
							// monsters that otherwise would let the player go
.float          jump_flag;              // player jump flag
.float          swim_flag;              // player swimming sound flag
.float          air_finished;   // when time > air_finished, start drowning
.float          bubble_count;   // keeps track of the number of bubbles
.string         deathtype;              // keeps track of how the player died

//
// object stuff
//
.string         mdl;
.vector         mangle;                 // angle at start

.vector         oldorigin;              // only used by secret door

.float          t_length, t_width;


//
// doors, etc
//
.vector         dest, dest1, dest2;
.float          wait;                   // time from firing to restarting
.float          delay;                  // time from activation to firing
.entity         trigger_field;  // door's trigger entity
.string         noise4;

//
// monsters
//
.float          pausetime;
.entity         movetarget;


//
// doors
//
.float          aflag;
.float          dmg;                    // damage done by door when hit
	
//
// misc
//
.float          cnt;                    // misc flag
	
//
// subs
//
.void()         think1;
.vector         finaldest, finalangle;

//
// triggers
//
.float          count;                  // for counting triggers


//
// plats / doors / buttons
//
.float          lip;
.float          state;
.vector         pos1, pos2;             // top and bottom positions
.float          height;

//
// sounds
//
.float          waitmin, waitmax;
.float          distance;
.float          volume;
	
.float 			sprintflag;

//
// builtin functions
//

void(vector ang)        makevectors             						    = #1;           // sets v_forward, etc globals
void(entity e, vector o) setorigin     									    = #2;
void(entity e, string m) setmodel           							    = #3;           // set movetype and solid first
void(entity e, vector min, vector max) setsize     						    = #4;

void() break                                            				    = #6;
float() random                                          				    = #7;           // returns 0 - 1
void(entity e, float chan, string samp, float vol, float atten) sound 	    = #8;
vector(vector v) normalize                      						    = #9;
void(string e) error                            						    = #10;
void(string e) objerror                         						    = #11;
float(vector v) vlen                             						    = #12;
float(vector v) vectoyaw                         						    = #13;
entity() spawn                                           				    = #14;
void(entity e) remove                            						    = #15;
void(vector v1, vector v2, float nomonsters, entity forent) traceline 	    = #16;    
entity() checkclient                            						    = #17;  // returns a client to look for
entity(entity start, .string fld, string match) find 					    = #18;
string(string s) precache_sound         								    = #19;
string(string s) precache_model         								    = #20;
void(entity client, string s)stuffcmd 									    = #21;
entity(vector org, float rad) findradius 								    = #22;
void(float level, string s) bprint                              		    = #23;
void(entity client, float level, string s) sprint 						    = #24;
void(string s) dprint                           						    = #25;
string(float f) ftos                            						    = #26;
string(vector v) vtos                           						    = #27;
void() coredump                                         				    = #28;          // prints all edicts
void() traceon                                          				    = #29;          // turns statment trace on
void() traceoff                                         				    = #30;
void(entity e) eprint                          							    = #31;          // prints an entire edict
float(float yaw, float dist) walkmove   								    = #32;  // returns TRUE or FALSE
float(entity zombie, float which, entity limb) updateLimb		            = #33;
float(float yaw, float dist) droptofloor 								    = #34;  // TRUE if landed on floor
void(float style, string value) lightstyle 								    = #35;
float(float v) rint                                     				    = #36;          // round to nearest int
float(float v) floor                            						    = #37;          // largest integer <= v
float(float v) ceil                                     				    = #38;          // smallest integer >= v
float(entity e) checkbottom                     						    = #40;          // true if self is on ground
float(vector v) pointcontents           								    = #41;          // returns a CONTENT_*
float(float f) fabs 													    = #43;
vector(entity e, float speed) aim 										    = #44;                // returns the shooting vector
float(string s) cvar 													    = #45;                                             // return cvar.value
void(string s) localcmd 												    = #46;                                  // put string into local que
entity(entity e) nextent 												    = #47;                                 // for looping through all ents
void() ChangeYaw 														    = #49;                                         // turn towards self.ideal_yaw
vector(vector v) vectoangles                   							    = #51;
void(float to, float f) WriteByte               						    = #52;
void(float to, float f) WriteChar               						    = #53;
void(float to, float f) WriteShort              						    = #54;
void(float to, float f) WriteLong               						    = #55;
void(float to, float f) WriteCoord              						    = #56;
void(float to, float f) WriteAngle              						    = #57;
void(float to, string s) WriteString    								    = #58;
void(float to, entity s) WriteEntity    								    = #59;
void(float step) movetogoal                             				    = #67;
string(string s) precache_file          								    = #68;  // no effect except for -copy
void(entity e) makestatic               								    = #69;
void(string s) changelevel 												    = #70;
void(string var, string val) cvar_set 									    = #72;    // sets cvar.value
void(entity client, string s) centerprint 								    = #73;        // sprint, but in middle
void(vector pos, string samp, float vol, float atten) ambientsound 		    = #74;
string(string s) precache_model2        								    = #75;          // registered version only
string(string s) precache_sound2        								    = #76;          // registered version only
string(string s) precache_file2         								    = #77;          // registered version only
void(entity e) setspawnparms            								    = #78;          // set parm1... to the
void(entity killer, entity killee) logfrag 								    = #79;       // add to stats
string(entity e, string key) infokey    								    = #80;  // get a key value (world = serverinfo)
float(string s) stof                            						    = #81;          // convert string to float
void(vector where, float set) multicast 								    = #82;
vector(entity what) Get_Waypoint_Near                                       = #83;
float(entity zombie, entity target) Do_Pathfind_psp                         = #84;
void(string s) Open_Waypoint                                                = #85;
vector(entity zombie,vector start,vector min, vector max) Get_Next_Waypoint = #86;
void(entity client, float type, float cost, float weapon) useprint 		    = #87; 
vector(entity zombie,vector start,vector min, vector max) Get_First_Waypoint = #88; 
entity (entity start, .float field, float match) findfloat 				    = #98;

// New NZP custom ones
float(string filename, float mode) fopen 								    = #110;
void(float fhandle) fclose 												    = #111;
string(float fhandle) fgets 											    = #112;
void(float fhandle, string s) fputs 									    = #113;
float(string s) strlen 													    = #114;
string(string s1, string s2) strcat 									    = #115;
string(string s, float start, float length) substring 					    = #116;
vector(string s) stov 													    = #117;
string(string s) strzone 												    = #118;
string(string s) strunzone 												    = #119;
string(string s) strtrim 												    = #120;
float(string s) tokenize 												    = #130;	// Was #441
string(float num) argv 													    = #131;	// Was #442

float(entity targ, entity inflictor) CanDamage;


#define		FILE_READ 	 	0
#define		FILE_APPEND 	1
#define		FILE_WRITE 		2
#define		SVC_WEAPONFIRE	35
#define		SVC_HITMARK		36
#define 	SVC_LIMBUPDATE  51 // naievil -- keep me
#define 	SVC_BSPDECAL    50 // naievil -- keep me
#define 	SVC_ACHIEVEMENT 52 

#define	VEC_ORIGIN 	 '0 0 0'

//Standard Quake View Offset
//vector VEC_VIEW_OFS = '0 0 22';

//Half Life View Offset is 64
//64 units above ground, for our purposes it's, 64 - (how low bounding box goes)
vector VEC_VIEW_OFS = '0 0 32';

//Standard Quake Hull
//vector	VEC_HULL_MIN = '-16 -16 -24';
//vector	VEC_HULL_MAX = '16 16 32';

//Half Life 1 Hull Sizes ADDED BY BLUBS, COMMENTED ORIGINAL QUAKE BBOX SIZS OUT
#define	VEC_HULL_MIN  '-16 -16 -32'
#define	VEC_HULL_MAX  '16 16 40'

#define	VEC_HULL2_MIN  '-32 -32 -24'
#define	VEC_HULL2_MAX  '32 32 64'

.string fog;
//string world_fog;

.float button3;
.float button4;
.float button5;
.float button6;
.float button7;
.float button8;

.float		x2_icon;			// double points icon
.float 		insta_icon;
.vector		Flash_Offset;
.float 		Flash_Size;
.string 	Weapon_Name;

.float currentHitBoxSetup;
.vector		bbmins, bbmaxs;		// Used for zombie hitboxes

.entity head;
.entity larm;
.entity rarm;

#define	SOLID_CORPSE			 	5	// bsp clip, touch on edge, block
#define	TE_EXPLOSION	 			3
#define     TE_GUNSHOT                                   2
entity windows[32];
float wincnt;

.float recoil_delay;

float pow(float base, float n) = {
	float temp = base;
	if (n == 0) {
		return 1;
	} else {
		while (n > 0) {
			temp = temp * base;
			n = n - 1;
		}
		return temp;
	}
	return 0;
};

void enableGrayscale(void) = {
	self.renderGrayscale = 1;
}

void disableGrayscale(void) = {
	self.renderGrayscale = 0;
}