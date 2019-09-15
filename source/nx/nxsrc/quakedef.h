/*
Copyright (C) 1996-2001 Id Software, Inc.
Copyright (C) 2002-2009 John Fitzgibbons and others
Copyright (C) 2007-2008 Kristian Duske
Copyright (C) 2010-2017 QuakeSpasm developers

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#ifndef QUAKEDEFS_H
#define QUAKEDEFS_H

// quakedef.h -- primary header for client

#define	QUAKE_GAME		// as opposed to utilities

#define	VERSION			1.09
#define	GLQUAKE_VERSION		1.00
#define	D3DQUAKE_VERSION	0.01
#define	WINQUAKE_VERSION	0.996
#define	LINUX_VERSION		1.30
#define	X11_VERSION		1.10

#define	FITZQUAKE_VERSION	0.85	//johnfitz
#define	QUAKESPASM_VERSION	0.93
#define	QUAKESPASM_VER_PATCH	1	// helper to print a string like 0.93.1
#ifndef	QUAKESPASM_VER_SUFFIX
#define	QUAKESPASM_VER_SUFFIX		// optional version suffix string literal like "-beta1"
#endif

#define	QS_STRINGIFY_(x)	#x
#define	QS_STRINGIFY(x)	QS_STRINGIFY_(x)

// combined version string like "0.92.1-beta1"
#define	QUAKESPASM_VER_STRING	QS_STRINGIFY(QUAKESPASM_VERSION) "." QS_STRINGIFY(QUAKESPASM_VER_PATCH) QUAKESPASM_VER_SUFFIX

//define	PARANOID			// speed sapping error checking

#define	GAMENAME	"nzp"		// directory to look in by default

#include "q_stdinc.h"

// !!! if this is changed, it must be changed in d_ifacea.h too !!!
#define CACHE_SIZE	32	// used to align key data structures

#define Q_UNUSED(x)	(x = x)	// for pesky compiler / lint warnings

#define	MINIMUM_MEMORY	0x550000
#define	MINIMUM_MEMORY_LEVELPAK	(MINIMUM_MEMORY + 0x100000)

#define MAX_NUM_ARGVS	50

// up / down
#define	PITCH		0

// left / right
#define	YAW		1

// fall over
#define	ROLL		2


#define	MAX_QPATH	64		// max length of a quake game pathname

#define	ON_EPSILON	0.1		// point on plane side epsilon

#define	DIST_EPSILON	(0.03125)	// 1/32 epsilon to keep floating point happy (moved from world.c)

#define	MAX_MSGLEN	64000		// max length of a reliable message //ericw -- was 32000
#define	MAX_DATAGRAM	32000		// max length of unreliable message //johnfitz -- was 1024

#define	DATAGRAM_MTU	1400		// johnfitz -- actual limit for unreliable messages to nonlocal clients

//
// per-level limits
//
#define	MIN_EDICTS	256		// johnfitz -- lowest allowed value for max_edicts cvar
#define	MAX_EDICTS	32000		// johnfitz -- highest allowed value for max_edicts cvar
						// ents past 8192 can't play sounds in the standard protocol
#define	MAX_LIGHTSTYLES	64
#define	MAX_MODELS	2048		// johnfitz -- was 256
#define	MAX_SOUNDS	2048		// johnfitz -- was 256

#define	SAVEGAME_COMMENT_LENGTH	39

#define	MAX_STYLESTRING		64

//
// stats are integers communicated to the client by the server
//
#define	MAX_CL_STATS		32
#define	STAT_HEALTH		    0
#define	STAT_FRAGS		    1
#define	STAT_WEAPON		    2
#define	STAT_AMMO		    3
#define	STAT_SECGRENADES	4
#define	STAT_WEAPONFRAME	5
#define	STAT_CURRENTMAG		6
#define	STAT_ZOOM		    7
#define	STAT_WEAPONSKIN		8
#define	STAT_GRENADES		9
#define	STAT_ACTIVEWEAPON	10
#define	STAT_ROUNDS         11
#define STAT_ROUNDCHANGE    12
#define	STAT_X2				13
#define	STAT_INSTA			14
#define	STAT_PRIGRENADES	15
#define	STAT_WEAPON2		17
#define	STAT_WEAPON2SKIN	18
#define	STAT_WEAPON2FRAME	19
#define STAT_CURRENTMAG2 	20

// stock defines
//


#define W_COLT 		1
#define W_KAR 		2
#define W_THOMPSON 	3
#define W_357		4
#define W_BAR		5
#define W_BK		6
#define W_BROWNING	7
#define W_DB		8
#define W_FG		9
#define W_GEWEHR	10
#define W_KAR_SCOPE	11
#define W_M1		12
#define W_M1A1		13
#define W_M2		14
#define W_MP40		15
#define W_MG		16
#define W_PANZER	17
#define W_PPSH		18
#define W_PTRS		19
#define W_RAY		20
#define W_SAWNOFF	21
#define W_STG		22
#define W_TRENCH	23
#define W_TYPE		24

#define W_BIATCH  28
#define W_KILLU   29 //357
#define W_COMPRESSOR 30 // Gewehr
#define W_M1000  31 //garand
//#define W_KOLLIDER  32
#define W_PORTER  33 // Ray
#define W_WIDDER  34 // M1A1
#define W_FIW  35 //upgraded flamethrower
#define W_ARMAGEDDON  36 //Kar
//#define W_WUNDER  37
#define W_GIBS  38 // thompson
#define W_SAMURAI  39 //Type
#define W_AFTERBURNER  40 //mp40
#define W_SPATZ  41 // stg
#define W_SNUFF  42 // sawn off
#define W_BORE  43 // double barrel
#define W_IMPELLER  44 //fg
#define W_BARRACUDA  45 //mg42
#define W_ACCELERATOR  46 //M1919 browning
#define W_GUT  47 //trench
#define W_REAPER  48 //ppsh
#define W_HEADCRACKER  49 //scoped kar
#define W_LONGINUS  50 //panzer
#define W_PENETRATOR  51 //ptrs
#define W_WIDOW  52 //bar
//#define W_KRAUS  53 //ballistic
#define W_MP5   54
#define W_M14   55

#define W_TESLA  56

#define W_NOWEP   420
#define	IT_SHOTGUN		1
#define	IT_SUPER_SHOTGUN	2
#define	IT_NAILGUN		4
#define	IT_SUPER_NAILGUN	8
#define	IT_GRENADE_LAUNCHER	16
#define	IT_ROCKET_LAUNCHER	32
#define	IT_LIGHTNING		64
#define	IT_SUPER_LIGHTNING	128
#define	IT_SHELLS		256
#define	IT_NAILS		512
#define	IT_ROCKETS		1024
#define	IT_CELLS		2048
#define	IT_AXE			4096
#define	IT_ARMOR1		8192
#define	IT_ARMOR2		16384
#define	IT_ARMOR3		32768
#define	IT_SUPERHEALTH		65536
#define	IT_KEY1			131072
#define	IT_KEY2			262144
#define	IT_INVISIBILITY		524288
#define	IT_INVULNERABILITY	1048576
#define	IT_SUIT			2097152
#define	IT_QUAD			4194304
#define	IT_SIGIL1		(1<<28)
#define	IT_SIGIL2		(1<<29)
#define	IT_SIGIL3		(1<<30)
#define	IT_SIGIL4		(1<<31)

//===========================================
//rogue changed and added defines

#define	RIT_SHELLS		128
#define	RIT_NAILS		256
#define	RIT_ROCKETS		512
#define	RIT_CELLS		1024
#define	RIT_AXE			2048
#define	RIT_LAVA_NAILGUN	4096
#define	RIT_LAVA_SUPER_NAILGUN	8192
#define	RIT_MULTI_GRENADE	16384
#define	RIT_MULTI_ROCKET	32768
#define	RIT_PLASMA_GUN		65536
#define	RIT_ARMOR1		8388608
#define	RIT_ARMOR2		16777216
#define	RIT_ARMOR3		33554432
#define	RIT_LAVA_NAILS		67108864
#define	RIT_PLASMA_AMMO		134217728
#define	RIT_MULTI_ROCKETS	268435456
#define	RIT_SHIELD		536870912
#define	RIT_ANTIGRAV		1073741824
#define	RIT_SUPERHEALTH		2147483648

//MED 01/04/97 added hipnotic defines
//===========================================
//hipnotic added defines
#define	HIT_PROXIMITY_GUN_BIT	16
#define	HIT_MJOLNIR_BIT		7
#define	HIT_LASER_CANNON_BIT	23
#define	HIT_PROXIMITY_GUN	(1<<HIT_PROXIMITY_GUN_BIT)
#define	HIT_MJOLNIR		(1<<HIT_MJOLNIR_BIT)
#define	HIT_LASER_CANNON	(1<<HIT_LASER_CANNON_BIT)
#define	HIT_WETSUIT		(1<<(23+2))
#define	HIT_EMPATHY_SHIELDS	(1<<(23+3))

//===========================================

#define	MAX_SCOREBOARD		16
#define	MAX_SCOREBOARDNAME	32

#define	SOUND_CHANNELS		8

typedef struct
{
	const char *basedir;
	const char *userdir;	// user's directory on UNIX platforms.
				// if user directories are enabled, basedir
				// and userdir will point to different
				// memory locations, otherwise to the same.
	int	argc;
	char	**argv;
	void	*membase;
	int	memsize;
	int	numcpus;
	int	errstate;
} quakeparms_t;

#include "common.h"
#include "bspfile.h"
#include "sys.h"
#include "zone.h"
#include "mathlib.h"
#include "cvar.h"

#include "protocol.h"
#include "net.h"

#include "cmd.h"
#include "crc.h"

#include "progs.h"
#include "server.h"

#include "platform.h"
#ifdef __SWITCH__
#include <SDL2/SDL.h>
#include <EGL/egl.h>
#include "glad/glad.h"
#else
#if defined(SDL_FRAMEWORK) || defined(NO_SDL_CONFIG)
#if defined(USE_SDL2)
#include <SDL2/SDL.h>
#include <SDL2/SDL_opengl.h>
#else
#include <SDL/SDL.h>
#include <SDL/SDL_opengl.h>
#endif
#else
#include "SDL.h"
#include "SDL_opengl.h"
#endif
#endif // __SWITCH__
#ifndef APIENTRY
#define	APIENTRY
#endif

#include "console.h"
#include "wad.h"
#include "vid.h"
#include "screen.h"
#include "render.h"
#include "view.h"
#include "sbar.h"
#include "q_sound.h"
#include "client.h"

#include "gl_model.h"
#include "world.h"
#include "gl_hud.h"
#include "gl_rpart.h"

#include "image.h"	//johnfitz
#include "gl_texmgr.h"	//johnfitz
#include "draw.h"
#include "input.h"
#include "keys.h"
#include "menu.h"
#include "cdaudio.h"
#include "glquake.h"


//=============================================================================

// the host system specifies the base of the directory tree, the
// command line parms passed to the program, and the amount of memory
// available for the program to use

extern qboolean noclip_anglehack;

//
// host
//
extern	quakeparms_t *host_parms;

extern	cvar_t		sys_ticrate;
extern	cvar_t		sys_throttle;
extern	cvar_t		sys_nostdout;
extern	cvar_t		developer;
extern	cvar_t		max_edicts; //johnfitz

extern	qboolean	host_initialized;	// true if into command execution
extern	double		host_frametime;
extern	byte		*host_colormap;
extern	int		host_framecount;	// incremented every frame, never reset
extern	double		realtime;		// not bounded in any way, changed at
							// start of every frame, never reset

typedef struct filelist_item_s
{
	char			name[32];
	struct filelist_item_s	*next;
} filelist_item_t;

extern filelist_item_t	*modlist;
extern filelist_item_t	*extralevels;
extern filelist_item_t	*demolist;

void Host_ClearMemory (void);
void Host_ServerFrame (void);
void Host_InitCommands (void);
void Host_Init (void);
void Host_Shutdown(void);
void Host_Callback_Notify (cvar_t *var);	/* callback function for CVAR_NOTIFY */
FUNC_NORETURN void Host_Error (const char *error, ...) FUNC_PRINTF(1,2);
FUNC_NORETURN void Host_EndGame (const char *message, ...) FUNC_PRINTF(1,2);
#ifdef __WATCOMC__
#pragma aux Host_Error aborts;
#pragma aux Host_EndGame aborts;
#endif
void Host_Frame (float time);
void Host_Quit_f (void);
void Host_ClientCommands (const char *fmt, ...) FUNC_PRINTF(1,2);
void Host_ShutdownServer (qboolean crash);
void Host_WriteConfiguration (void);

void ExtraMaps_Init (void);
void Modlist_Init (void);
void DemoList_Init (void);

void DemoList_Rebuild (void);

extern int		current_skill;	// skill level for currently loaded level (in case
					//  the user changes the cvar while the level is
					//  running, this reflects the level actually in use)

extern qboolean		isDedicated;

extern func_t	EndFrame;

extern int		minimum_memory;

#define ISUNDERWATER(x) ((x) == CONTENTS_WATER || (x) == CONTENTS_SLIME || (x) == CONTENTS_LAVA)
#define TruePointContents(p) SV_HullPointContents(&cl.worldmodel->hulls[0], 0, p)

//ZOMBIE AI STUFF
#define MAX_WAYPOINTS 256 //max waypoints
typedef struct
{
	int pathlist [MAX_WAYPOINTS];
	int zombienum;
} zombie_ai;

typedef struct
{
	vec3_t origin;
	int id;
	float g_score, f_score;
	int open; // Determine if the waypoint is "open" a.k.a avaible
	int target_id [8]; // Targets array number
	char special[64]; //special tag is required for the closed waypoints
	int target [8]; //Each waypoint can have up to 8 targets
	float dist [8]; // Distance to the next waypoints
	int came_from; // Used for pathfinding store where we got here to this
	qboolean used; //if the waypoint is in use
} waypoint_ai;

extern waypoint_ai waypoints[MAX_WAYPOINTS];

#endif	/* QUAKEDEFS_H */

