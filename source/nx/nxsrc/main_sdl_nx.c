/*
Copyright (C) 1996-2001 Id Software, Inc.
Copyright (C) 2002-2005 John Fitzgibbons and others
Copyright (C) 2007-2008 Kristian Duske
Copyright (C) 2010-2014 QuakeSpasm developers

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

#include "quakedef.h"
#include <switch.h>
#include <SDL2/SDL.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/iosupport.h>
#include <errno.h>

#define SDL_MIN_X	2
#define SDL_MIN_Y	0
#define SDL_MIN_Z	0
#define SDL_REQUIREDVERSION	(SDL_VERSIONNUM(SDL_MIN_X,SDL_MIN_Y,SDL_MIN_Z))
#define SDL_NEW_VERSION_REJECT	(SDL_VERSIONNUM(3,0,0))

void userAppInit (void)
{
	socketInitializeDefault();
}

void userAppExit (void)
{
	if (SDL_WasInit(0))
		SDL_Quit();
	socketExit();
}

SDL_Window	*draw_context;

static void Sys_InitSDL (void)
{
	SDL_version v;
	SDL_version *sdl_version = &v;
	SDL_GetVersion(&v);

	Sys_Printf("Found SDL version %i.%i.%i\n",sdl_version->major,sdl_version->minor,sdl_version->patch);
	if (SDL_VERSIONNUM(sdl_version->major,sdl_version->minor,sdl_version->patch) < SDL_REQUIREDVERSION)
	{	/*reject running under older SDL versions */
		Sys_Error("You need at least v%d.%d.%d of SDL to run this game.", SDL_MIN_X,SDL_MIN_Y,SDL_MIN_Z);
	}
	if (SDL_VERSIONNUM(sdl_version->major,sdl_version->minor,sdl_version->patch) >= SDL_NEW_VERSION_REJECT)
	{	/*reject running under newer (1.3.x) SDL */
		Sys_Error("Your version of SDL library is incompatible with me.\n"
			  "You need a library version in the line of %d.%d.%d\n", SDL_MIN_X,SDL_MIN_Y,SDL_MIN_Z);
	}

	if (SDL_Init(SDL_INIT_VIDEO) < 0)
	{
		Sys_Error("Couldn't init SDL: %s", SDL_GetError());
	}

	char		caption[50];
	q_snprintf(caption, sizeof(caption), "QuakeSpasm " QUAKESPASM_VER_STRING);
	int flags = SDL_WINDOW_OPENGL | SDL_WINDOW_FULLSCREEN;
	draw_context = SDL_CreateWindow (caption, 0, 0, 1280, 720, 0);

	if (!draw_context) {
		Sys_Error ("SDLINIT: SDL_CreateWindow: Couldn't create window | %s", SDL_GetError());
	}
}

#define DEFAULT_MEMORY (512 * 1024 * 1024) // ericw -- was 72MB (64-bit) / 64MB (32-bit)

static quakeparms_t	parms;

// returns in megabytes
static int MemAvailable(void)
{
	// use a syscall to get available memory
	u64 avail = 0;

	// id0 = 6, id1 = 0 => TotalMemoryAvailable
	Result rc = svcGetInfo( &avail, 6, CUR_PROCESS_HANDLE, 0 );

	// applets get at least like 300 mb, so that's the minimum
	if ( R_FAILED(rc) ) avail = 304 * 1024 * 1024;

	int mb = (int)( avail / ( 1024 * 1024 ) );
	// round to the nearest 16Mb
	mb = ( mb + 8 ) & ~15;
	return mb;
}

static int	fake_argc;
static char	*fake_argv[MAX_NUM_ARGVS + 1];
static char	autoload_game[64];

// checks for launch.rc in cwd and if it's there reads the gamedir from it
static void CheckAutoload(void)
{
	FILE *rc = fopen("launch.rc", "r");
	if (!rc) return;
	fscanf(rc, "%63s", autoload_game);
	fclose(rc);

	// don't do -game id1, it doesn't load quakespasm.pak then
	if (!autoload_game[0] || !strcasecmp(autoload_game, "nzp"))
		return;

	if (fake_argc >= MAX_NUM_ARGVS) return;

	fake_argv[fake_argc++] = "-game";
	fake_argv[fake_argc++] = autoload_game;
}

int main(int argc, char *argv[])
{
	int		t, need_autoload;
	double		time, oldtime, newtime;

#ifdef DEBUG
	nxlinkStdio ();
#endif

	// make a copy of argv to inject args into it later
	// also check if we need to autoload the previously played mod
	need_autoload = 1;
	fake_argc = 1;
	fake_argv[0] = argv[0];
	for (t = 1; t < argc; ++t)
	{
		if (t >= MAX_NUM_ARGVS) break;
		if (!strncmp(argv[t], "-game", 5))
			need_autoload = 0;
		fake_argv[t] = argv[t];
		fake_argc++;
	}

	// if there's no -game arg, try to do that via injecting -game into argv
	if (need_autoload)
		CheckAutoload();

	host_parms = &parms;
	parms.basedir = ".";

	parms.argc = fake_argc;
	parms.argv = fake_argv;

	parms.errstate = 0;

	COM_InitArgv(parms.argc, parms.argv);

	Sys_InitSDL ();

	Sys_Init();

	int mem_mb = MemAvailable();
	// leave at least 256 MB for stuff, or else it crashes on taxing maps in applet mode
	parms.memsize = (mem_mb > 512) ? DEFAULT_MEMORY : DEFAULT_MEMORY / 2;

	if (COM_CheckParm("-heapsize"))
	{
		t = COM_CheckParm("-heapsize") + 1;
		if (t < com_argc)
			parms.memsize = Q_atoi(com_argv[t]) * 1024;
	}

	parms.membase = malloc (parms.memsize);

	if (!parms.membase) {

		Sys_Error ("Not enough memory free; check disk space\ntried to allocate %d bytes\nOnly have %d MB available\nerrno = %s\n", parms.memsize, mem_mb, strerror(errno));
	}

	Sys_Printf("Quake %1.2f (c) id Software\n", VERSION);
	Sys_Printf("GLQuake %1.2f (c) id Software\n", GLQUAKE_VERSION);
	Sys_Printf("FitzQuake %1.2f (c) John Fitzgibbons\n", FITZQUAKE_VERSION);
	Sys_Printf("FitzQuake SDL port (c) SleepwalkR, Baker\n");
	Sys_Printf("NZPortable " QUAKESPASM_VER_STRING " (c) Ozkan Sezer, Eric Wasylishen & others\n");
	Sys_Printf("Available memory: %d MB\n", mem_mb);
	Sys_Printf("Allocated %d MB for mem base\n", parms.memsize);

	Sys_Printf("Host_Init\n");
	Host_Init();

	oldtime = Sys_DoubleTime();
	if (isDedicated)
	{
		while (appletMainLoop ())
		{
			newtime = Sys_DoubleTime ();
			time = newtime - oldtime;

			while (time < sys_ticrate.value )
			{
				SDL_Delay(1);
				newtime = Sys_DoubleTime ();
				time = newtime - oldtime;
			}

			Host_Frame (time);
			oldtime = newtime;
		}
	}
	else
	while (appletMainLoop ())
	{
		/* If we have no input focus at all, sleep a bit */
		if (!VID_HasMouseOrInputFocus() || cl.paused)
		{
			SDL_Delay(16);
		}
		/* If we're minimised, sleep a bit more */
		if (VID_IsMinimized())
		{
			scr_skipupdate = 1;
			SDL_Delay(32);
		}
		else
		{
			scr_skipupdate = 0;
		}
		newtime = Sys_DoubleTime ();
		time = newtime - oldtime;

		Host_Frame (time);

		if (time < sys_throttle.value && !cls.timedemo)
			SDL_Delay(1);

		oldtime = newtime;
	}

	// due to appletLockExit, main loop will terminate if user exits via HOME
	// so we clean shit up
	Sys_Quit ();

	return 0;
}
