/*
Copyright (C) 1996-2001 Id Software, Inc.
Copyright (C) 2002-2009 John Fitzgibbons and others
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

// screen.c -- master for refresh, status bar, console, chat, notify, etc

#include "quakedef.h"

/*

background clear
rendering
turtle/net/ram icons
sbar
centerprint / slow centerprint
notify lines
intermission / finale overlay
loading plaque
console
menu

required background clears
required update regions


syncronous draw mode or async
One off screen buffer, with updates either copied or xblited
Need to double buffer?


async draw will require the refresh area to be cleared, because it will be
xblited, but sync draw can just ignore it.

sync
draw

CenterPrint ()
SlowPrint ()
Screen_Update ();
Con_Printf ();

net
turn off messages option

the refresh is allways rendered, unless the console is full screen


console is:
	notify lines
	half
	full

*/


int			glx, gly, glwidth, glheight;

int			scr_copytop;
int 		loadingScreen;

float		scr_con_current;
float		scr_conlines;		// lines of console to display

//johnfitz -- new cvars
cvar_t		scr_menuscale = {"scr_menuscale", "1", CVAR_ARCHIVE};
cvar_t		scr_sbarscale = {"scr_sbarscale", "1", CVAR_ARCHIVE};
cvar_t		scr_sbaralpha = {"scr_sbaralpha", "0.75", CVAR_ARCHIVE};
cvar_t		scr_conwidth = {"scr_conwidth", "0", CVAR_ARCHIVE};
cvar_t		scr_conscale = {"scr_conscale", "1", CVAR_ARCHIVE};
cvar_t		scr_crosshairscale = {"scr_crosshairscale", "1", CVAR_ARCHIVE};
cvar_t		scr_showfps = {"scr_showfps", "0", CVAR_NONE};
cvar_t		scr_clock = {"scr_clock", "0", CVAR_NONE};
//johnfitz

cvar_t		scr_viewsize = {"viewsize","100", CVAR_ARCHIVE};
cvar_t		scr_fov = {"fov","70",CVAR_NONE};	// 10 - 170
cvar_t		scr_fov_adapt = {"fov_adapt","1",CVAR_ARCHIVE};
cvar_t		scr_conspeed = {"scr_conspeed","500",CVAR_ARCHIVE};
cvar_t		scr_centertime = {"scr_centertime","2",CVAR_NONE};
cvar_t		scr_showram = {"showram","1",CVAR_NONE};
cvar_t		scr_showturtle = {"showturtle","0",CVAR_NONE};
cvar_t		scr_showpause = {"showpause","1",CVAR_NONE};
cvar_t		scr_printspeed = {"scr_printspeed","8",CVAR_NONE};
cvar_t		gl_triplebuffer = {"gl_triplebuffer", "1", CVAR_ARCHIVE};

extern	cvar_t	crosshair;

qboolean	scr_initialized;		// ready to draw

qpic_t		*scr_ram;
qpic_t		*scr_net;
qpic_t		*scr_turtle;

qpic_t      *hitmark;
qpic_t      *ls_wahnsinn;
qpic_t      *ls_anstieg;

extern qpic_t		*sniper_scope;

int			clearconsole;
int			clearnotify;

vrect_t		scr_vrect;

qboolean	scr_disabled_for_loading;
qboolean	scr_drawloading;
float		scr_disabled_time;

int	scr_tileclear_updates = 0; //johnfitz

char		scr_usestring[1024];
float		scr_usetime_off = 0.0f;
int			button_pic_x;

void SCR_ScreenShot_f (void);


/*
==============
SCR_UsePrint

Similiar to above, but will also print the current button for the action.
==============
*/

extern qpic_t      *b_up;
extern qpic_t      *b_down;
extern qpic_t      *b_left;
extern qpic_t      *b_right;
extern qpic_t      *b_lthumb;
extern qpic_t      *b_rthumb;
extern qpic_t      *b_lshoulder;
extern qpic_t      *b_rshoulder;
extern qpic_t      *b_abutton;
extern qpic_t      *b_bbutton;
extern qpic_t      *b_ybutton;
extern qpic_t      *b_xbutton;
extern qpic_t      *b_lt;
extern qpic_t      *b_rt;

qpic_t *GetButtonIcon (char *buttonname)
{

	int		j;
	int		l;
	char	*b;
	l = strlen(buttonname);

	for (j=0 ; j<256 ; j++)
	{
		b = keybindings[j];
		if (!b)
			continue;
		if (!strncmp (b, buttonname, l) )
		{
			if (!strcmp(Key_KeynumToString(j), "UPARROW"))
				return b_up;
			else if (!strcmp(Key_KeynumToString(j), "DOWNARROW"))
				return b_down;
			else if (!strcmp(Key_KeynumToString(j), "LEFTARROW"))
				return b_left;
			else if (!strcmp(Key_KeynumToString(j), "RIGHTARROW"))
				return b_right;
			else if (!strcmp(Key_KeynumToString(j), "LTHUMB"))
				return b_lthumb;
			else if (!strcmp(Key_KeynumToString(j), "RTHUMB"))
				return b_rthumb;
			else if (!strcmp(Key_KeynumToString(j), "LSHOULDER"))
				return b_lshoulder;
			else if (!strcmp(Key_KeynumToString(j), "RSHOULDER"))
				return b_rshoulder;
			else if (!strcmp(Key_KeynumToString(j), "ABUTTON"))
				return b_abutton;
			else if (!strcmp(Key_KeynumToString(j), "BBUTTON"))
				return b_bbutton;
			else if (!strcmp(Key_KeynumToString(j), "YBUTTON"))
				return b_ybutton;
			else if (!strcmp(Key_KeynumToString(j), "XBUTTON"))
				return b_xbutton;
			else if (!strcmp(Key_KeynumToString(j), "LTRIGGER"))
				return b_lt;
			else if (!strcmp(Key_KeynumToString(j), "RTRIGGER"))
				return b_rt;
		}
	}
	return b_abutton;
}

char *GetUseButtonL ()
{
	int		j;
	int		l;
	char	*b;
	l = strlen("+use");

	for (j=0 ; j<256 ; j++)
	{
		b = keybindings[j];
		if (!b)
			continue;
		if (!strncmp (b, "+use", l) )
		{
			if (!strcmp(Key_KeynumToString(j), "LSHOULDER") ||
				!strcmp(Key_KeynumToString(j), "RSHOULDER"))
				return "    ";
			else
				return "  ";
		}
	}
	return " ";
}

char *GetPerkName (int perk)
{
	switch (perk)
	{
		case 1:
			return "Quick Revive";
		case 2:
			return "Juggernog";
		case 3:
			return "Speed Cola";
		case 4:
			return "Double Tap";
		case 5:
			return "Stamin-Up";
		case 6:
			return "PhD Flopper";
		case 7:
			return "Deadshot Daiquiri";
		default:
			return "NULL";
	}
}

void SCR_UsePrint (int type, int cost, int weapon)
{
	char w[128];
    char s[128];

    switch (type)
	{
		case 0://clear
			strcpy(s, "");
			break;
		case 1://door
			strcpy(s, va("Hold %s to open door [Cost:%i]\n", GetUseButtonL(), cost));
			button_pic_x = 5;
			break;
		case 2://debris
			strcpy(s, va("Hold %s to remove debris [Cost:%i]\n", GetUseButtonL(), cost));
			button_pic_x = 5;
			break;
		case 3://ammo
			strcpy(w, PR_GetString(sv_player->v.Weapon_Name_Touch));
			strcpy(s, va("Hold %s to buy ammo for %s [Cost:%i]\n", GetUseButtonL(), w, cost));
			button_pic_x = 5;
			break;
		case 4://weapon
			strcpy(w, PR_GetString(sv_player->v.Weapon_Name_Touch));
			strcpy(s, va("Hold %s to buy %s [Cost:%i]\n", GetUseButtonL(), w, cost));
			button_pic_x = 5;
			break;
		case 5://window
			strcpy(s, va("Hold %s to Rebuild Barrier\n", GetUseButtonL()));
			button_pic_x = 5;
			break;
		case 6://box
			strcpy(s, va("Hold %s to buy a random weapon [cost:%i]\n", GetUseButtonL(), cost));
			button_pic_x = 5;
			break;
		case 7://box take
			strcpy(s, va("Press %s to take weapon\n", GetUseButtonL()));
			button_pic_x = 6;
			break;
		case 8://power
			strcpy(s, "The power must be activated first\n");
			button_pic_x = 100;
			break;
		case 9://perk
			strcpy(s, va("Hold %s to buy %s [Cost:%i]\n", GetUseButtonL(), GetPerkName(weapon), cost));
			button_pic_x = 5;
			break;
		case 10://turn on power
			strcpy(s, va("Hold %s to turn on the power\n", GetUseButtonL()));
			button_pic_x = 5;
			break;
		case 11://turn on trap
			strcpy(s, va("Hold %s to activate the electric barrier [Cost:%i]\n", GetUseButtonL(), cost));
			button_pic_x = 5;
			break;
		case 12://PAP
			strcpy(s, va("Hold %s to Pack a Punch [Cost:%i]\n", GetUseButtonL(), cost));
			button_pic_x = 5;
			break;
		case 13://revive
			strcpy(s, va("Hold %s to Fix your Code.. :)\n", GetUseButtonL()));
			button_pic_x = 5;
			break;
		case 14://use teleporter (free)
			strcpy(s, va("Hold %s to use Teleporter\n", GetUseButtonL()));
			button_pic_x = 5;
			break;
		case 15://use teleporter (cost)
			strcpy(s, va("Hold %s to use Teleporter [Cost:%i]\n", GetUseButtonL(), cost));
			button_pic_x = 5;
			break;
		case 16://tp cooldown
			strcpy(s, "Teleporter is cooling down\n");
			button_pic_x = 100;
			break;
		case 17://link
			strcpy(s, va("Hold %s to initiate link to pad\n", GetUseButtonL()));
			button_pic_x = 5;
			break;
		case 18://no link
			strcpy(s, "Link not active\n");
			button_pic_x = 100;
			break;
		case 19://finish link
			strcpy(s, va("Hold %s to link pad with core\n", GetUseButtonL()));
			button_pic_x = 5;
			break;
		case 20://buyable ending
			strcpy(s, va("Hold %s to End the Game [Cost:%i]\n", GetUseButtonL(), cost));
			button_pic_x = 5;
			break;
		default:
			Con_Printf ("No type defined in engine for useprint\n");
			break;
	}

	strncpy (scr_usestring, va(s), sizeof(scr_usestring)-1);
	scr_usetime_off = 0.1;
}

void SCR_DrawUseString (void)
{
	int		l;
	int		x, y;

	if (cl.stats[STAT_HEALTH] < 0) {
		return;
	}

	// The scale is double, so basically subtract the difference here...
	y = vid.height*0.85;
	l = strlen (scr_usestring);
    x = ((vid.width/2 - l*8)/2);

    GL_SetCanvas(CANVAS_USEPRINT);
    Draw_String (x, y, scr_usestring);

    GL_SetCanvas(CANVAS_DEFAULT);
	Draw_Pic (x*2 + button_pic_x*16, y*0.8125, GetButtonIcon("+use"));
}

void SCR_CheckDrawUseString (void)
{
	scr_copytop = 1;

	scr_usetime_off -= host_frametime;

	if (scr_usetime_off <= 0 && !cl.intermission) {
		return;
	}
	if (key_dest != key_game) {
		return;
	}
    if (cl.stats[STAT_HEALTH] <= 0) {
        return;
    }

	SCR_DrawUseString ();
}


/*
===============================================================================

CENTER PRINTING

===============================================================================
*/

char		scr_centerstring[1024];
float		scr_centertime_start;	// for slow victory printing
float		scr_centertime_off;
int			scr_center_lines;
int			scr_erase_lines;
int			scr_erase_center;

/*
==============
SCR_CenterPrint

Called for important messages that should stay in the center of the screen
for a few moments
==============
*/
void SCR_CenterPrint (const char *str) //update centerprint data
{
	strncpy (scr_centerstring, str, sizeof(scr_centerstring)-1);
	scr_centertime_off = scr_centertime.value;
	scr_centertime_start = cl.time;

// count the number of lines for centering
	scr_center_lines = 1;
	str = scr_centerstring;
	while (*str)
	{
		if (*str == '\n')
			scr_center_lines++;
		str++;
	}
}

void SCR_DrawCenterString (void) //actually do the drawing
{
	char	*start;
	int		l;
	int		j;
	int		x, y;
	int		remaining;

	GL_SetCanvas (CANVAS_MENU); //johnfitz

// the finale prints the characters one at a time
	if (cl.intermission)
		remaining = scr_printspeed.value * (cl.time - scr_centertime_start);
	else
		remaining = 9999;

	scr_erase_center = 0;
	start = scr_centerstring;

	if (scr_center_lines <= 4)
		y = 200*0.35;	//johnfitz -- 320x200 coordinate system
	else
		y = 48;
	if (crosshair.value)
		y -= 8;

	do
	{
	// scan the width of the line
		for (l=0 ; l<40 ; l++)
			if (start[l] == '\n' || !start[l])
				break;
		x = (320 - l*8)/2;	//johnfitz -- 320x200 coordinate system
		for (j=0 ; j<l ; j++, x+=8)
		{
			Draw_Character (x, y, start[j]);	//johnfitz -- stretch overlays
			if (!remaining--)
				return;
		}

		y += 8;

		while (*start && *start != '\n')
			start++;

		if (!*start)
			break;
		start++;		// skip the \n
	} while (1);
}

void SCR_CheckDrawCenterString (void)
{
	if (scr_center_lines > scr_erase_lines)
		scr_erase_lines = scr_center_lines;

	scr_centertime_off -= host_frametime;

	if (scr_centertime_off <= 0 && !cl.intermission)
		return;
	if (key_dest != key_game)
		return;
	if (cl.paused) //johnfitz -- don't show centerprint during a pause
		return;

	SCR_DrawCenterString ();
}

//=============================================================================

/*
====================
AdaptFovx
Adapt a 4:3 horizontal FOV to the current screen size using the "Hor+" scaling:
2.0 * atan(width / height * 3.0 / 4.0 * tan(fov_x / 2.0))
====================
*/
float AdaptFovx (float fov_x, float width, float height)
{
	float	a, x;

	if (fov_x < 1 || fov_x > 179)
		Sys_Error ("Bad fov: %f", fov_x);

	if (!scr_fov_adapt.value)
		return fov_x;
	if ((x = height / width) == 0.75)
		return fov_x;
	a = atan(0.75 / x * tan(fov_x / 360 * M_PI));
	a = a * 360 / M_PI;
	return a;
}

/*
====================
CalcFovy
====================
*/
float CalcFovy (float fov_x, float width, float height)
{
	float	a, x;

	if (fov_x < 1 || fov_x > 179)
		Sys_Error ("Bad fov: %f", fov_x);

	x = width / tan(fov_x / 360 * M_PI);
	a = atan(height / x);
	a = a * 360 / M_PI;
	return a;
}

/*
=================
SCR_CalcRefdef

Must be called whenever vid changes
Internal use only
=================
*/
static void SCR_CalcRefdef (void)
{
	float		size, scale; //johnfitz -- scale

// force the status bar to redraw
	Sbar_Changed ();

	scr_tileclear_updates = 0; //johnfitz

// bound viewsize
	if (scr_viewsize.value < 30)
		Cvar_SetQuick (&scr_viewsize, "30");
	if (scr_viewsize.value > 120)
		Cvar_SetQuick (&scr_viewsize, "120");

// bound fov
	if (scr_fov.value < 10)
		Cvar_SetQuick (&scr_fov, "10");
	if (scr_fov.value > 170)
		Cvar_SetQuick (&scr_fov, "170");

	vid.recalc_refdef = 0;

	//johnfitz -- rewrote this section
	size = scr_viewsize.value;
	scale = CLAMP (1.0, scr_sbarscale.value, (float)glwidth / 320.0);

	if (size >= 120 || cl.intermission || scr_sbaralpha.value < 1) //johnfitz -- scr_sbaralpha.value
		sb_lines = 0;
	else if (size >= 110)
		sb_lines = 24 * scale;
	else
		sb_lines = 48 * scale;

	size = q_min(scr_viewsize.value, 100) / 100;
	//johnfitz

	//johnfitz -- rewrote this section
	r_refdef.vrect.width = q_max(glwidth * size, 96); //no smaller than 96, for icons
	r_refdef.vrect.height = q_min(glheight * size, glheight - sb_lines); //make room for sbar
	r_refdef.vrect.x = (glwidth - r_refdef.vrect.width)/2;
	r_refdef.vrect.y = (glheight - sb_lines - r_refdef.vrect.height)/2;
	//johnfitz

	r_refdef.fov_x = AdaptFovx(scr_fov.value, vid.width, vid.height);
	r_refdef.fov_y = CalcFovy (r_refdef.fov_x, r_refdef.vrect.width, r_refdef.vrect.height);

	scr_vrect = r_refdef.vrect;
}


/*
=================
SCR_SizeUp_f

Keybinding command
=================
*/
void SCR_SizeUp_f (void)
{
	Cvar_SetValueQuick (&scr_viewsize, scr_viewsize.value+10);
}


/*
=================
SCR_SizeDown_f

Keybinding command
=================
*/
void SCR_SizeDown_f (void)
{
	Cvar_SetValueQuick (&scr_viewsize, scr_viewsize.value-10);
}

static void SCR_Callback_refdef (cvar_t *var)
{
	vid.recalc_refdef = 1;
}

/*
==================
SCR_Conwidth_f -- johnfitz -- called when scr_conwidth or scr_conscale changes
==================
*/
void SCR_Conwidth_f (cvar_t *var)
{
	vid.recalc_refdef = 1;
	vid.conwidth = (scr_conwidth.value > 0) ? (int)scr_conwidth.value : (scr_conscale.value > 0) ? (int)(vid.width/scr_conscale.value) : vid.width;
	vid.conwidth = CLAMP (320, vid.conwidth, vid.width);
	vid.conwidth &= 0xFFFFFFF8;
	vid.conheight = vid.conwidth * vid.height / vid.width;
}

//============================================================================

/*
==================
SCR_LoadPics -- johnfitz
==================
*/
void SCR_LoadPics (void)
{
	scr_ram = Draw_PicFromWad ("ram");
	scr_net = Draw_PicFromWad ("net");
	scr_turtle = Draw_PicFromWad ("turtle");

	hitmark = Draw_CachePic("gfx/hud/hit_marker.tga");
	//ls_wahnsinn = Draw_CachePic ("gfx/lscreen/psp_wahnsinn.lmp");
	//ls_anstieg = Draw_CachePic ("gfx/lscreen/psp_anstieg.tga");
}

/*
==================
SCR_Init
==================
*/
void SCR_Init (void)
{
	//johnfitz -- new cvars
	Cvar_RegisterVariable (&scr_menuscale);
	Cvar_RegisterVariable (&scr_sbarscale);
	Cvar_SetCallback (&scr_sbaralpha, SCR_Callback_refdef);
	Cvar_RegisterVariable (&scr_sbaralpha);
	Cvar_SetCallback (&scr_conwidth, &SCR_Conwidth_f);
	Cvar_SetCallback (&scr_conscale, &SCR_Conwidth_f);
	Cvar_RegisterVariable (&scr_conwidth);
	Cvar_RegisterVariable (&scr_conscale);
	Cvar_RegisterVariable (&scr_crosshairscale);
	Cvar_RegisterVariable (&scr_showfps);
	Cvar_RegisterVariable (&scr_clock);
	//johnfitz
	Cvar_SetCallback (&scr_fov, SCR_Callback_refdef);
	Cvar_SetCallback (&scr_fov_adapt, SCR_Callback_refdef);
	Cvar_SetCallback (&scr_viewsize, SCR_Callback_refdef);
	Cvar_RegisterVariable (&scr_fov);
	Cvar_RegisterVariable (&scr_fov_adapt);
	Cvar_RegisterVariable (&scr_viewsize);
	Cvar_RegisterVariable (&scr_conspeed);
	Cvar_RegisterVariable (&scr_showram);
	Cvar_RegisterVariable (&scr_showturtle);
	Cvar_RegisterVariable (&scr_showpause);
	Cvar_RegisterVariable (&scr_centertime);
	Cvar_RegisterVariable (&scr_printspeed);
	Cvar_RegisterVariable (&gl_triplebuffer);

	Cmd_AddCommand ("screenshot",SCR_ScreenShot_f);
	Cmd_AddCommand ("sizeup",SCR_SizeUp_f);
	Cmd_AddCommand ("sizedown",SCR_SizeDown_f);

	SCR_LoadPics (); //johnfitz

	scr_initialized = true;
}

//============================================================================

/*
==============
SCR_DrawFPS -- johnfitz
==============
*/
void SCR_DrawFPS (void)
{
	static double	oldtime = 0;
	static double	lastfps = 0;
	static int	oldframecount = 0;
	double	elapsed_time;
	int	frames;

	elapsed_time = realtime - oldtime;
	frames = r_framecount - oldframecount;

	if (elapsed_time < 0 || frames < 0)
	{
		oldtime = realtime;
		oldframecount = r_framecount;
		return;
	}
	// update value every 3/4 second
	if (elapsed_time > 0.75)
	{
		lastfps = frames / elapsed_time;
		oldtime = realtime;
		oldframecount = r_framecount;
	}

	if (scr_showfps.value)
	{
		char	st[16];
		int	x, y;
		sprintf (st, "%4.0f fps", lastfps);
		x = 320 - (strlen(st)<<3);
		y = 200 - 8;
		if (scr_clock.value) y -= 8; //make room for clock
		GL_SetCanvas (CANVAS_BOTTOMRIGHT);
		Draw_String (x, y, st);
		scr_tileclear_updates = 0;
	}
}

/*
==============
SCR_DrawClock -- johnfitz
==============
*/
void SCR_DrawClock (void)
{
	char	str[12];

	if (scr_clock.value == 1)
	{
		int minutes, seconds;

		minutes = cl.time / 60;
		seconds = ((int)cl.time)%60;

		sprintf (str,"%i:%i%i", minutes, seconds/10, seconds%10);
	}
	else
		return;

	//draw it
	GL_SetCanvas (CANVAS_BOTTOMRIGHT);
	Draw_String (320 - (strlen(str)<<3), 200 - 8, str);

	scr_tileclear_updates = 0;
}

/*
==============
SCR_DrawDevStats
==============
*/
void SCR_DrawDevStats (void)
{
	char	str[40];
	int		y = 25-9; //9=number of lines to print
	int		x = 0; //margin

	if (!devstats.value)
		return;

	GL_SetCanvas (CANVAS_BOTTOMLEFT);

	Draw_Fill (x, y*8, 19*8, 9*8, 0, 0.5); //dark rectangle

	sprintf (str, "devstats |Curr Peak");
	Draw_String (x, (y++)*8-x, str);

	sprintf (str, "---------+---------");
	Draw_String (x, (y++)*8-x, str);

	sprintf (str, "Edicts   |%4i %4i", dev_stats.edicts, dev_peakstats.edicts);
	Draw_String (x, (y++)*8-x, str);

	sprintf (str, "Packet   |%4i %4i", dev_stats.packetsize, dev_peakstats.packetsize);
	Draw_String (x, (y++)*8-x, str);

	sprintf (str, "Visedicts|%4i %4i", dev_stats.visedicts, dev_peakstats.visedicts);
	Draw_String (x, (y++)*8-x, str);

	sprintf (str, "Efrags   |%4i %4i", dev_stats.efrags, dev_peakstats.efrags);
	Draw_String (x, (y++)*8-x, str);

	sprintf (str, "Dlights  |%4i %4i", dev_stats.dlights, dev_peakstats.dlights);
	Draw_String (x, (y++)*8-x, str);

	sprintf (str, "Beams    |%4i %4i", dev_stats.beams, dev_peakstats.beams);
	Draw_String (x, (y++)*8-x, str);

	sprintf (str, "Tempents |%4i %4i", dev_stats.tempents, dev_peakstats.tempents);
	Draw_String (x, (y++)*8-x, str);
}

/*
==============
SCR_DrawRam
==============
*/
void SCR_DrawRam (void)
{
	if (!scr_showram.value)
		return;

	if (!r_cache_thrash)
		return;

	GL_SetCanvas (CANVAS_DEFAULT); //johnfitz

	Draw_Pic (scr_vrect.x+32, scr_vrect.y, scr_ram);
}

/*
==============
SCR_DrawTurtle
==============
*/
void SCR_DrawTurtle (void)
{
	static int	count;

	if (!scr_showturtle.value)
		return;

	if (host_frametime < 0.1)
	{
		count = 0;
		return;
	}

	count++;
	if (count < 3)
		return;

	GL_SetCanvas (CANVAS_DEFAULT); //johnfitz

	Draw_Pic (scr_vrect.x, scr_vrect.y, scr_turtle);
}

/*
==============
SCR_DrawNet
==============
*/
void SCR_DrawNet (void)
{
	if (realtime - cl.last_received_message < 0.3)
		return;
	if (cls.demoplayback)
		return;

	GL_SetCanvas (CANVAS_DEFAULT); //johnfitz

	Draw_Pic (scr_vrect.x+64, scr_vrect.y, scr_net);
}

/*
==============
DrawPause
==============
*/
void SCR_DrawPause (void)
{
	qpic_t	*pic;

	if (!cl.paused)
		return;

	if (!scr_showpause.value)		// turn off for screenshots
		return;

	GL_SetCanvas (CANVAS_MENU); //johnfitz

	scr_tileclear_updates = 0; //johnfitz
}

/*
==============
SCR_DrawLoading
==============
*/
void SCR_DrawLoading (void)
{
	qpic_t	*pic;

	if (!scr_drawloading)
		return;

	scr_tileclear_updates = 0; //johnfitz
}

//cvar_t	crosshair;
extern cvar_t crosshair;
extern qboolean croshhairmoving;
//extern cvar_t cl_zoom;
extern qpic_t *hitmark;
double Hitmark_Time, crosshair_spread_time;
float cur_spread;
float crosshair_offset_step;

int CrossHairWeapon (void)
{
    int i;
	switch(cl.stats[STAT_ACTIVEWEAPON])
	{
		case W_COLT:
		case W_BIATCH:
			i = 15;
			break;
		case W_KAR:
		case W_ARMAGEDDON:
			i = 50;
			break;
		case W_THOMPSON:
		case W_GIBS:
			i = 10;
			break;
		case W_357:
		case W_KILLU:
			i = 10;
			break;
		case W_BAR:
		case W_WIDOW:
			i = 10;
			break;
		case W_BROWNING:
		case W_ACCELERATOR:
			i = 20;
			break;
		case W_DB:
		case W_BORE:
			i = 25;
			break;
		case W_FG:
		case W_IMPELLER:
			i = 10;
			break;
		case W_GEWEHR:
		case W_COMPRESSOR:
			i = 10;
			break;
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
			i = 50;
			break;
		case W_M1:
		case W_M1000:
			i = 10;
			break;
		case W_M1A1:
		case W_WIDDER:
			i = 10;
			break;
		case W_MP40:
		case W_AFTERBURNER:
			i = 10;
			break;
		case W_MG:
		case W_BARRACUDA:
			i = 20;
			break;
		case W_PANZER:
		case W_LONGINUS:
			i = 0;
			break;
		case W_PPSH:
		case W_REAPER:
			i = 10;
			break;
		case W_PTRS:
		case W_PENETRATOR:
			i = 50;
			break;
		case W_RAY:
		case W_PORTER:
			i = 10;
			break;
		case W_SAWNOFF:
		case W_SNUFF:
			i = 30;
			break;
		case W_STG:
		case W_SPATZ:
			i = 10;
			break;
		case W_TRENCH:
		case W_GUT:
			i = 25;
			break;
		case W_TYPE:
		case W_SAMURAI:
			i = 10;
			break;
		case W_MP5:
			i = 10;
			break;
		case W_TESLA:
			i = 0;
			break;
		default:
			i = 0;
			break;
	}

    if (cl.perks & 64)
        i *= 0.65;

    return i;
}
int CrossHairMaxSpread (void)
{
	int i;
	switch(cl.stats[STAT_ACTIVEWEAPON])
	{
		case W_COLT:
		case W_BIATCH:
			i = 30;
			break;
		case W_KAR:
		case W_ARMAGEDDON:
			i = 75;
			break;
		case W_THOMPSON:
		case W_GIBS:
			i = 25;
			break;
		case W_357:
		case W_KILLU:
			i = 20;
			break;
		case W_BAR:
		case W_WIDOW:
			i = 35;
			break;
		case W_BROWNING:
		case W_ACCELERATOR:
			i = 50;
			break;
		case W_DB:
		case W_BORE:
			i = 25;
			break;
		case W_FG:
		case W_IMPELLER:
			i = 40;
			break;
		case W_GEWEHR:
		case W_COMPRESSOR:
			i = 35;
			break;
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
			i = 75;
			break;
		case W_M1:
		case W_M1000:
			i = 35;
			break;
		case W_M1A1:
		case W_WIDDER:
			i = 35;
			break;
		case W_MP40:
		case W_AFTERBURNER:
			i = 25;
			break;
		case W_MG:
		case W_BARRACUDA:
			i = 50;
			break;
		case W_PANZER:
		case W_LONGINUS:
			i = 0;
			break;
		case W_PPSH:
		case W_REAPER:
			i = 25;
			break;
		case W_PTRS:
		case W_PENETRATOR:
			i = 75;
			break;
		case W_RAY:
		case W_PORTER:
			i = 20;
			break;
		case W_SAWNOFF:
		case W_SNUFF:
			i = 30;
			break;
		case W_STG:
		case W_SPATZ:
			i = 35;
			break;
		case W_TRENCH:
		case W_GUT:
			i = 25;
			break;
		case W_TYPE:
		case W_SAMURAI:
			i = 25;
			break;
		case W_MP5:
			i = 25;
			break;
		case W_TESLA:
			i = 0;
			break;
		default:
			i = 0;
			break;
	}

    if (cl.perks & 64)
        i *= 0.65;

    return i;
}

/*
================
Draw_Crosshair
================
*/
void SCR_DrawCrosshair (void)
{
	if (cl.stats[STAT_HEALTH] < 20) {
		return;
	}

	GL_SetCanvas(CANVAS_USEPRINT);

	if (crosshair_spread_time > sv.time && crosshair_spread_time)
    {
        cur_spread = cur_spread + 10;
		if (cur_spread >= CrossHairMaxSpread())
			cur_spread = CrossHairMaxSpread();
    }
    else if (crosshair_spread_time < sv.time && crosshair_spread_time)
    {
        cur_spread = cur_spread - 4;
		if (cur_spread <= 0)
		{
			cur_spread = 0;
			crosshair_spread_time = 0;
		}
    }

	if (cl.stats[STAT_ACTIVEWEAPON] == W_M2)
	{
		Draw_Character ((vid.width)/4-4, (vid.height)*3/4, 'O');
	}
	else if (crosshair.value == 1 && cl.stats[STAT_ZOOM] != 1 && cl.stats[STAT_ZOOM] != 2 && cl.stats[STAT_ACTIVEWEAPON] != W_PANZER)
    {
        int x_value, y_value;
        int crosshair_offset = CrossHairWeapon() + cur_spread;
		if (CrossHairMaxSpread() < crosshair_offset || croshhairmoving)
			crosshair_offset = CrossHairMaxSpread();

		crosshair_offset_step += (crosshair_offset - crosshair_offset_step) * 0.5;

		x_value = ((vid.width - 8)/4) - crosshair_offset_step;
		y_value = (vid.height - 8)*3/4;
		Draw_Character (x_value, y_value, 158);

		x_value = ((vid.width - 8)/4) + crosshair_offset_step;
		y_value = (vid.height - 8)*3/4;
		Draw_Character (x_value, y_value, 158);

		x_value = ((vid.width - 8)/4);
		y_value = (vid.height - 8)*3/4 - crosshair_offset_step;
		Draw_Character (x_value, y_value, 157);

		x_value = ((vid.width - 8)/4);
		y_value = (vid.height - 8)*3/4 + crosshair_offset_step;
		Draw_Character (x_value, y_value, 157);
    }
    else if (crosshair.value && cl.stats[STAT_ZOOM] != 1 && cl.stats[STAT_ZOOM] != 2)
		Draw_Character ((vid.width - 8)/4/* + crosshair_x*/, (vid.height - 8)*3/4/* + crosshair_y*/, '.');
	if (cl.stats[STAT_ZOOM] == 2) {
		Draw_AlphaPic (0, vid.height/2, sniper_scope, 1);
	}
   if (Hitmark_Time > sv.time) {
        Draw_Pic ((vid.width/2 - hitmark->width)/2,vid.height/2 + (vid.height/2 - hitmark->height)/2, hitmark);
   }

   	GL_SetCanvas(CANVAS_DEFAULT);
}



//=============================================================================


/*
==================
SCR_SetUpToDrawConsole
==================
*/
void SCR_SetUpToDrawConsole (void)
{
	//johnfitz -- let's hack away the problem of slow console when host_timescale is <0
	extern cvar_t host_timescale;
	float timescale;
	//johnfitz

	Con_CheckResize ();

	if (scr_drawloading)
		return;		// never a console with loading plaque

// decide on the height of the console
	con_forcedup = !cl.worldmodel || cls.signon != SIGNONS;

	if (con_forcedup)
	{
		scr_conlines = glheight; //full screen //johnfitz -- glheight instead of vid.height
		scr_con_current = scr_conlines;
	}
	else if (key_dest == key_console)
		scr_conlines = glheight/2; //half screen //johnfitz -- glheight instead of vid.height
	else
		scr_conlines = 0; //none visible

	timescale = (host_timescale.value > 0) ? host_timescale.value : 1; //johnfitz -- timescale

	if (scr_conlines < scr_con_current)
	{
		// ericw -- (glheight/600.0) factor makes conspeed resolution independent, using 800x600 as a baseline
		scr_con_current -= scr_conspeed.value*(glheight/600.0)*host_frametime/timescale; //johnfitz -- timescale
		if (scr_conlines > scr_con_current)
			scr_con_current = scr_conlines;
	}
	else if (scr_conlines > scr_con_current)
	{
		// ericw -- (glheight/600.0)
		scr_con_current += scr_conspeed.value*(glheight/600.0)*host_frametime/timescale; //johnfitz -- timescale
		if (scr_conlines < scr_con_current)
			scr_con_current = scr_conlines;
	}

	if (clearconsole++ < vid.numpages)
		Sbar_Changed ();

	if (!con_forcedup && scr_con_current)
		scr_tileclear_updates = 0; //johnfitz
}

/*
==================
SCR_DrawConsole
==================
*/
void SCR_DrawConsole (void)
{
	if (scr_con_current)
	{
		Con_DrawConsole (scr_con_current, true);
		clearconsole = 0;
	}
	else
	{
		if (key_dest == key_game || key_dest == key_message)
			Con_DrawNotify ();	// only draw notify in game
	}
}


/*
==============================================================================

SCREEN SHOTS

==============================================================================
*/

static void SCR_ScreenShot_Usage (void)
{
	Con_Printf ("usage: screenshot <format> <quality>\n");
	Con_Printf ("   format must be \"png\" or \"tga\" or \"jpg\"\n");
	Con_Printf ("   quality must be 1-100\n");
	return;
}

/*
==================
SCR_ScreenShot_f -- johnfitz -- rewritten to use Image_WriteTGA
==================
*/
void SCR_ScreenShot_f (void)
{
	byte	*buffer;
	char	ext[4];
	char	imagename[16];  //johnfitz -- was [80]
	char	checkname[MAX_OSPATH];
	int	i, quality;
	qboolean	ok;

	Q_strncpy (ext, "png", sizeof(ext));

	if (Cmd_Argc () >= 2)
	{
		const char	*requested_ext = Cmd_Argv (1);

		if (!q_strcasecmp ("png", requested_ext)
		    || !q_strcasecmp ("tga", requested_ext)
		    || !q_strcasecmp ("jpg", requested_ext))
			Q_strncpy (ext, requested_ext, sizeof(ext));
		else
		{
			SCR_ScreenShot_Usage ();
			return;
		}
	}

// read quality as the 3rd param (only used for JPG)
	quality = 90;
	if (Cmd_Argc () >= 3)
		quality = Q_atoi (Cmd_Argv(2));
	if (quality < 1 || quality > 100)
	{
		SCR_ScreenShot_Usage ();
		return;
	}
	
// find a file name to save it to
	for (i=0; i<10000; i++)
	{
		q_snprintf (imagename, sizeof(imagename), "spasm%04i.%s", i, ext);	// "fitz%04i.tga"
		q_snprintf (checkname, sizeof(checkname), "%s/%s", com_gamedir, imagename);
		if (Sys_FileTime(checkname) == -1)
			break;	// file doesn't exist
	}
	if (i == 10000)
	{
		Con_Printf ("SCR_ScreenShot_f: Couldn't find an unused filename\n");
		return;
	}

//get data
	if (!(buffer = (byte *) malloc(glwidth*glheight*3)))
	{
		Con_Printf ("SCR_ScreenShot_f: Couldn't allocate memory\n");
		return;
	}

	glPixelStorei (GL_PACK_ALIGNMENT, 1);/* for widths that aren't a multiple of 4 */
	glReadPixels (glx, gly, glwidth, glheight, GL_RGB, GL_UNSIGNED_BYTE, buffer);

// now write the file
	if (!q_strncasecmp (ext, "png", sizeof(ext)))
		ok = Image_WritePNG (imagename, buffer, glwidth, glheight, 24, false);
	else if (!q_strncasecmp (ext, "tga", sizeof(ext)))
		ok = Image_WriteTGA (imagename, buffer, glwidth, glheight, 24, false);
	else if (!q_strncasecmp (ext, "jpg", sizeof(ext)))
		ok = Image_WriteJPG (imagename, buffer, glwidth, glheight, 24, quality, false);
	else
		ok = false;

	if (ok)
		Con_Printf ("Wrote %s\n", imagename);
	else
		Con_Printf ("SCR_ScreenShot_f: Couldn't create %s\n", imagename);

	free (buffer);
}


//=============================================================================


/*
===============
SCR_BeginLoadingPlaque

================
*/
void SCR_BeginLoadingPlaque (void)
{
	S_StopAllSounds (true);

	if (cls.state != ca_connected)
		return;
	if (cls.signon != SIGNONS)
		return;

// redraw with no console and the loading plaque
	Con_ClearNotify ();
	scr_centertime_off = 0;
	scr_con_current = 0;

	scr_drawloading = true;
	Sbar_Changed ();
	SCR_UpdateScreen ();
	scr_drawloading = false;

	scr_disabled_for_loading = true;
	scr_disabled_time = realtime;
}

/*
===============
SCR_EndLoadingPlaque

================
*/
void SCR_EndLoadingPlaque (void)
{
	scr_disabled_for_loading = false;
	Con_ClearNotify ();
}

//=============================================================================

const char	*scr_notifystring;
qboolean	scr_drawdialog;

void SCR_DrawNotifyString (void)
{
	const char	*start;
	int		l;
	int		j;
	int		x, y;

	GL_SetCanvas (CANVAS_MENU); //johnfitz

	start = scr_notifystring;

	y = 200 * 0.35; //johnfitz -- stretched overlays

	do
	{
	// scan the width of the line
		for (l=0 ; l<40 ; l++)
			if (start[l] == '\n' || !start[l])
				break;
		x = (320 - l*8)/2; //johnfitz -- stretched overlays
		for (j=0 ; j<l ; j++, x+=8)
			Draw_Character (x, y, start[j]);

		y += 8;

		while (*start && *start != '\n')
			start++;

		if (!*start)
			break;
		start++;		// skip the \n
	} while (1);
}

/*
==================
SCR_ModalMessage

Displays a text string in the center of the screen and waits for a Y or N
keypress.
==================
*/
int SCR_ModalMessage (const char *text, float timeout) //johnfitz -- timeout
{
	double time1, time2; //johnfitz -- timeout
	int lastkey, lastchar;

	if (cls.state == ca_dedicated)
		return true;

	scr_notifystring = text;

// draw a fresh screen
	scr_drawdialog = true;
	SCR_UpdateScreen ();
	scr_drawdialog = false;

	S_ClearBuffer ();		// so dma doesn't loop current sound

	time1 = Sys_DoubleTime () + timeout; //johnfitz -- timeout
	time2 = 0.0f; //johnfitz -- timeout

	Key_BeginInputGrab ();
	do
	{
		Sys_SendKeyEvents ();
		Key_GetGrabbedInput (&lastkey, &lastchar);
		Sys_Sleep (16);
		if (timeout) time2 = Sys_DoubleTime (); //johnfitz -- zero timeout means wait forever.
	} while (lastchar != 'y' && lastchar != 'Y' &&
		 lastchar != 'n' && lastchar != 'N' &&
		 lastkey != K_ESCAPE &&
		 lastkey != K_ABUTTON &&
		 lastkey != K_BBUTTON &&
		 time2 <= time1);
	Key_EndInputGrab ();

//	SCR_UpdateScreen (); //johnfitz -- commented out

	//johnfitz -- timeout
	if (time2 > time1)
		return false;
	//johnfitz

	return (lastchar == 'y' || lastchar == 'Y' || lastkey == K_ABUTTON);
}


//=============================================================================

//johnfitz -- deleted SCR_BringDownConsole


/*
==================
SCR_TileClear
johnfitz -- modified to use glwidth/glheight instead of vid.width/vid.height
	    also fixed the dimentions of right and top panels
	    also added scr_tileclear_updates
==================
*/
void SCR_TileClear (void)
{
	//ericw -- added check for glsl gamma. TODO: remove this ugly optimization?
	if (scr_tileclear_updates >= vid.numpages && !gl_clear.value && !(gl_glsl_gamma_able && vid_gamma.value != 1))
		return;
	scr_tileclear_updates++;

	if (r_refdef.vrect.x > 0)
	{
		// left
		Draw_TileClear (0,
						0,
						r_refdef.vrect.x,
						glheight - sb_lines);
		// right
		Draw_TileClear (r_refdef.vrect.x + r_refdef.vrect.width,
						0,
						glwidth - r_refdef.vrect.x - r_refdef.vrect.width,
						glheight - sb_lines);
	}

	if (r_refdef.vrect.y > 0)
	{
		// top
		Draw_TileClear (r_refdef.vrect.x,
						0,
						r_refdef.vrect.width,
						r_refdef.vrect.y);
		// bottom
		Draw_TileClear (r_refdef.vrect.x,
						r_refdef.vrect.y + r_refdef.vrect.height,
						r_refdef.vrect.width,
						glheight - r_refdef.vrect.y - r_refdef.vrect.height - sb_lines);
	}
}

/*
==================
SCR_UpdateScreen

This is called every frame, and can also be called explicitly to flush
text to the screen.

WARNING: be very careful calling this from elsewhere, because the refresh
needs almost the entire 256k of stack space!
==================
*/

int GetWeaponZoomAmmount (void)
{
    switch (cl.stats[STAT_ACTIVEWEAPON])
    {
        case W_357:
        case W_SAWNOFF:
        case W_TRENCH:
        case W_PANZER:
        case W_RAY:
        case W_THOMPSON:
        case W_COLT:
        case W_PPSH:
        case W_TYPE:
        //case W_TESLA:
            return 5;
            break;
        case W_STG:
        case W_BROWNING:
        case W_MP40:
            return 10;
            break;
        case W_KAR:
        case W_GEWEHR:
        case W_M1:
        case W_M1A1:
        case W_FG:
        case W_KAR_SCOPE:
        case W_PTRS:
        //case W_HEADCRACKER:
        //case W_PENETRATOR:
            return 20;
            break;
        default:
            return 5;
            break;
    }
}
float zoomin_time;
int original_fov;

void SCR_UpdateScreen (void)
{
	vid.numpages = (gl_triplebuffer.value) ? 3 : 2;

	if (scr_disabled_for_loading)
	{
		if (realtime - scr_disabled_time > 60)
		{
			scr_disabled_for_loading = false;
			Con_Printf ("load failed.\n");
		}
		else
			return;
	}

	if (!scr_initialized || !con_initialized)
		return;				// not initialized yet
	
	scr_copytop = 0;


	GL_BeginRendering (&glx, &gly, &glwidth, &glheight);


	if (cl.stats[STAT_ZOOM] == 1)
	{
		if(!original_fov)
			original_fov = scr_fov.value;
		if(scr_fov.value > (GetWeaponZoomAmmount() + 1))//+1 for accounting for floating point inaccurraces
		{
			scr_fov.value += ((original_fov - GetWeaponZoomAmmount()) - scr_fov.value) * 0.25;
			Cvar_SetValue("fov",scr_fov.value);
		}
	}
	else if (cl.stats[STAT_ZOOM] == 2)
	{
		Cvar_SetValue ("fov", 30);
		zoomin_time = 0;
	}
	else if (cl.stats[STAT_ZOOM] == 3)
	{
		if(!original_fov)
			original_fov = scr_fov.value;
		//original_fov = scr_fov.value;
		scr_fov.value += (original_fov - 10 - scr_fov.value) * 0.3;
		Cvar_SetValue("fov",scr_fov.value);
	}
	else if (cl.stats[STAT_ZOOM] == 0 && original_fov != 0)
	{
		if(scr_fov.value < (original_fov + 1))//+1 for accounting for floating point inaccuracies
		{
			scr_fov.value += (original_fov - scr_fov.value) * 0.25;
			Cvar_SetValue("fov",scr_fov.value);
		}
		else
		{
			original_fov = 0;
		}
	}

	//
	// determine size of refresh window
	//
	if (vid.recalc_refdef)
		SCR_CalcRefdef ();

//
// do 3D refresh drawing, and then update the screen
//
	SCR_SetUpToDrawConsole ();

	V_RenderView ();

	GL_Set2D ();

	//FIXME: only call this when needed
	SCR_TileClear ();

	if (scr_drawdialog) //new game confirm
	{
		if (con_forcedup)
			Draw_ConsoleBackground ();
		// else
		// 	Sbar_Draw ();
		Draw_FadeScreen ();
		SCR_DrawNotifyString ();
	}
	else if (scr_drawloading) //loading
	{
		SCR_DrawLoading ();
		// Sbar_Draw ();
	}
	else if (cl.intermission == 1 && key_dest == key_game) //end of level
	{
		Sbar_IntermissionOverlay ();
	}
	else if (cl.intermission == 2 && key_dest == key_game) //end of episode
	{
		Sbar_FinaleOverlay ();
		SCR_CheckDrawCenterString ();
	}
	else
	{
		SCR_DrawCrosshair (); //johnfitz
		SCR_DrawRam ();
		SCR_DrawNet ();
		SCR_DrawTurtle ();
		SCR_DrawPause ();
		SCR_CheckDrawCenterString ();
		SCR_CheckDrawUseString ();
		SCR_DrawDevStats (); //johnfitz
		HUD_Draw ();
		SCR_DrawFPS (); //johnfitz
		SCR_DrawClock (); //johnfitz
		SCR_DrawConsole ();
		M_Draw ();
	}

	V_UpdateBlend (); //johnfitz -- V_UpdatePalette cleaned up and renamed

	GLSLGamma_GammaCorrect ();

	GL_EndRendering ();
}

