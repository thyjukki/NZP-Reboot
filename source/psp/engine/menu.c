/*
Copyright (C) 1996-1997 Id Software, Inc.

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

#include <pspgu.h>
#include <pspkernel.h>
#include <psputility.h>
//#include <pspctrl.h>
#include <pspiofilemgr.h>
#include <ctype.h>
#include "net_dgrm.h"
#include "cl_slist.h"
#include "crypter.h"


extern cvar_t	accesspoint;
extern cvar_t	r_wateralpha;
extern cvar_t	r_vsync;
extern cvar_t	in_disable_analog;
extern cvar_t	in_analog_strafe;
extern cvar_t	in_x_axis_adjust;
extern cvar_t	in_y_axis_adjust;
extern cvar_t	crosshair;
extern cvar_t	r_dithering;
extern cvar_t	r_retro;
extern cvar_t	waypoint_mode;

extern qpic_t 		*b_square;
extern qpic_t 		*b_triangle;
extern qpic_t 		*b_cross;
extern qpic_t 		*b_circle;
extern qpic_t 		*b_lt;
extern qpic_t 		*b_rt;
extern qpic_t 		*b_start;
extern qpic_t 		*b_left;
extern qpic_t 		*b_right;

extern qboolean bmg_type_changed;

extern int loadingScreen;
extern int ShowBlslogo;

// Backgrounds
qpic_t *menu_bk;

// Map screens
qpic_t *menu_ndu;
qpic_t *menu_wh;
//qpic_t *menu_kn;
qpic_t *menu_ch;
//qpic_t *menu_wn;
qpic_t *menu_custom;
qpic_t *menu_cuthum;


typedef struct
{
	int 		occupied;
	int 	 	map_allow_game_settings;
	int 	 	map_use_thumbnail;
	char* 		map_name;
	char* 		map_name_pretty;
	char* 		map_desc_1;
	char* 		map_desc_2;
	char* 		map_desc_3;
	char* 		map_desc_4;
	char* 		map_desc_5;
	char* 		map_desc_6;
	char* 		map_desc_7;
	char* 		map_desc_8;
	char* 		map_author;
	char* 		map_thumbnail_path;
} usermap_t;

SceIoStat custom_thumbnail_size;
usermap_t custom_maps[50];

enum
{
m_none,
m_start,
m_main,
m_paused_menu,
m_map,
m_singleplayer,
m_multiplayer,
m_achievement,
m_setup,
m_net,
m_options,
m_audio,
m_gameplay,
m_video,
m_keys,
m_credits,
m_quit,
m_restart,
m_exit,
m_serialconfig,
m_modemconfig,
m_lanconfig,
m_gameoptions,
m_search,
m_slist,
m_sedit,
m_osk
} m_state;

void M_Start_Menu_f (void);
void M_Paused_Menu_f (void);
	void M_Menu_Restart_f (void);
	void M_Menu_Exit_f (void);
void M_Menu_Main_f (void);
	void M_Menu_SinglePlayer_f (void);
		void M_Menu_Load_f (void);
		void M_Menu_Save_f (void);
	void M_Menu_MultiPlayer_f (void);
		void M_Menu_Setup_f (void);
		void M_Menu_Net_f (void);
        void M_Menu_ServerList_f (void);
	void M_Menu_Achievement_f (void);
	void M_Menu_Options_f (void);
		void M_Menu_Keys_f (void);
		void M_Menu_Audio_f (void);
        void M_Menu_Gameplay_f (void);
		void M_Menu_Screen_f (void);
	void M_Menu_Credits_f (void);
	void M_Menu_Quit_f (void);
void M_Menu_SerialConfig_f (void);
	void M_Menu_ModemConfig_f (void);
void M_Menu_LanConfig_f (void);
void M_Menu_GameOptions_f (void);
void M_Menu_Search_f (void);
void M_Menu_ServerList_f (void);

void M_Main_Draw (void);
		void M_Setup_Draw (void);
		void M_Net_Draw (void);
	void M_Options_Draw (void);
		void M_Keys_Draw (void);
	void M_Credits_Draw (void);
	void M_Quit_Draw (void);
void M_SerialConfig_Draw (void);
	void M_ModemConfig_Draw (void);
void M_LanConfig_Draw (void);
void M_GameOptions_Draw (void);
void M_Search_Draw (void);
void M_ServerList_Draw (void);

void M_Main_Key (int key);
void M_SinglePlayer_Key (int key);
void M_MultiPlayer_Key (int key);
	void M_Setup_Key (int key);
	void M_Net_Key (int key);
void M_Options_Key (int key);
	void M_Keys_Key (int key);
void M_Credits_Key (int key);
void M_Quit_Key (int key);
void M_SerialConfig_Key (int key);
void M_ModemConfig_Key (int key);
void M_LanConfig_Key (int key);
void M_GameOptions_Key (int key);
void M_Search_Key (int key);
void M_ServerList_Key (int key);

void Con_SetOSKActive(qboolean active);
void M_Menu_OSK_f (char *input, char *output, int outlen);


qboolean	m_entersound;		// play after drawing a frame, so caching
								// won't disrupt the sound
qboolean	m_recursiveDraw;

int			m_return_state;
qboolean	m_return_onerror;
char		m_return_reason [32];

#define StartingGame	(m_multiplayer_cursor == 1)
#define JoiningGame		(m_multiplayer_cursor == 0)
#define SerialConfig	(m_net_cursor == 0)
#define DirectConfig	(m_net_cursor == 1)
#define	IPXConfig		(m_net_cursor == 2)
#define	TCPIPConfig		(m_net_cursor == 3)

void M_ConfigureNetSubsystem(void);

/*
================
M_DrawCharacter

Draws one solid graphics character
================
*/
void M_DrawCharacter (int cx, int line, int num)
{
	Draw_Character ( cx, line, num);
}
void M_DrawCharacter2 (int cx, int line, int num)
{
	Draw_Character ( cx + ((vid.width - 320)>>1), line, num);
}

void M_PrintOld (int cx, int cy, char *str)
{
	while (*str)
	{
		M_DrawCharacter2 (cx, cy, (*str)+128);
		str++;
		cx += 8;
	}
}

void M_Print (int cx, int cy, char *str)
{
	char str2[80];

	strcpy (str2,"&cD32");//831
	strcat  (str2, str);
	Draw_ColoredString (cx, cy, str2, 255, 255, 255, 255, 1);
}

int	M_ColorForMap (int m)
{
	return m < 128 ? m + 8 : m + 8;
}

void M_PrintWhiteOld (int cx, int cy, char *str)
{
	while (*str)
	{
		M_DrawCharacter2 (cx, cy, *str);
		str++;
		cx += 8;
	}
}
void M_PrintWhite (int cx, int cy, char *str)
{
	while (*str)
	{
		M_DrawCharacter (cx, cy, *str);
		str++;
		cx += 8;
	}
}

void M_DrawTransPic (int x, int y, qpic_t *pic)
{
	Draw_TransPic (x + ((vid.width - 320)>>1), y, pic);
}

void M_DrawPic (int x, int y, qpic_t *pic)
{
	Draw_Pic (x + ((vid.width - 320)>>1), y, pic);
}

byte identityTable[256];
byte translationTable[256];

void M_BuildTranslationTable(int top, int bottom)
{
	int		j;
	byte	*dest, *source;

	for (j = 0; j < 256; j++)
		identityTable[j] = j;
	dest = translationTable;
	source = identityTable;
	memcpy (dest, source, 256);

	if (top < 128)	// the artists made some backwards ranges.  sigh.
		memcpy (dest + TOP_RANGE, source + top, 16);
	else
		for (j=0 ; j<16 ; j++)
			dest[TOP_RANGE+j] = source[top+15-j];

	if (bottom < 128)
		memcpy (dest + BOTTOM_RANGE, source + bottom, 16);
	else
		for (j=0 ; j<16 ; j++)
			dest[BOTTOM_RANGE+j] = source[bottom+15-j];
}


void M_DrawTransPicTranslate (int x, int y, qpic_t *pic)
{
	Draw_TransPicTranslate (x + ((vid.width - 320)>>1), y, pic, translationTable);
}


void M_DrawTextBox (int x, int y, int width, int lines)
{
	qpic_t	*p;
	int		cx, cy;
	int		n;

	// draw left side
	cx = x;
	cy = y;
	p = Draw_CachePic ("gfx/box_tl.lmp");
	M_DrawTransPic (cx, cy, p);
	p = Draw_CachePic ("gfx/box_ml.lmp");
	for (n = 0; n < lines; n++)
	{
		cy += 8;
		M_DrawTransPic (cx, cy, p);
	}
	p = Draw_CachePic ("gfx/box_bl.lmp");
	M_DrawTransPic (cx, cy+8, p);

	// draw middle
	cx += 8;
	while (width > 0)
	{
		cy = y;
		p = Draw_CachePic ("gfx/box_tm.lmp");
		M_DrawTransPic (cx, cy, p);
		p = Draw_CachePic ("gfx/box_mm.lmp");
		for (n = 0; n < lines; n++)
		{
			cy += 8;
			if (n == 1)
				p = Draw_CachePic ("gfx/box_mm2.lmp");
			M_DrawTransPic (cx, cy, p);
		}
		p = Draw_CachePic ("gfx/box_bm.lmp");
		M_DrawTransPic (cx, cy+8, p);
		width -= 2;
		cx += 16;
	}

	// draw right side
	cy = y;
	p = Draw_CachePic ("gfx/box_tr.lmp");
	M_DrawTransPic (cx, cy, p);
	p = Draw_CachePic ("gfx/box_mr.lmp");
	for (n = 0; n < lines; n++)
	{
		cy += 8;
		M_DrawTransPic (cx, cy, p);
	}
	p = Draw_CachePic ("gfx/box_br.lmp");
	M_DrawTransPic (cx, cy+8, p);
}

void M_DrawCheckbox (int x, int y, int on)
{
	if (on)
		Draw_String (x, y, "Enabled");
	else
		Draw_String (x, y, "Disabled");
}

//=============================================================================

/*
================
M_ToggleMenu_f
================
*/
void M_ToggleMenu_f (void)
{
	m_entersound = true;

	if (key_dest == key_menu || key_dest == key_menu_pause)
	{
		if (m_state != m_main && m_state != m_paused_menu)
		{
			M_Menu_Main_f ();
			return;
		}
		key_dest = key_game;
		m_state = m_none;
		return;
	}
	if (key_dest == key_console)
	{
		Con_ToggleConsole_f ();
	}
	else if (sv.active && (svs.maxclients > 1 || key_dest == key_game))
	{
		M_Paused_Menu_f();
	}
	else
	{
		M_Menu_Main_f ();
	}
}

//=============================================================================

int M_Start_Cusor;
#define Max_Start_Iteams 5

void M_Start_Menu_f ()
{
	key_dest = key_menu;
	m_state = m_start;
	m_entersound = true;
	//loadingScreen = 0;
	Load_Achivements();
}

static void M_Start_Menu_Draw ()
{
	// Background
    menu_bk = Draw_CacheImg("gfx/menu/menu_background");
	Draw_Pic (0, 0, menu_bk);

	// Fill black to make everything easier to see
	Draw_FillByColor(0, 0, 480, 272, GU_RGBA(0, 0, 0, 102));

	Draw_ColoredString((vid.width)/2 - 44, (vid.height - 64), "Press Start", 255, 0, 0, 255, 1);
}

void M_Start_Key (int key)
{
	switch (key)
	{
		case K_ESCAPE:
			S_LocalSound ("sounds/menu/enter.wav");
			Cbuf_AddText("togglemenu\n");
			break;
	}
}
//=============================================================================

int M_Paused_Cusor;
#define Max_Paused_Iteams 5

void M_Paused_Menu_f ()
{
	key_dest = key_menu_pause;
	m_state = m_paused_menu;
	m_entersound = true;
	loadingScreen = 0;
	M_Paused_Cusor = 0;
}

static void M_Paused_Menu_Draw ()
{
	// Fill black to make everything easier to see
	Draw_FillByColor(0, 0, 480, 272, GU_RGBA(0, 0, 0, 102));

	// Header
	Draw_ColoredString(10, 10, "PAUSED", 255, 255, 255, 255, 2);

	if ((M_Paused_Cusor == 0))
		Draw_ColoredString(10, 135, "Resume", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 135, "Resume", 255, 255, 255, 255, 1);

	if ((M_Paused_Cusor == 1))
		Draw_ColoredString(10, 145, "Restart", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 145, "Restart", 255, 255, 255, 255, 1);

	if ((M_Paused_Cusor == 2))
		Draw_ColoredString(10, 155, "Settings", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 155, "Settings", 255, 255, 255, 255, 1);

	if (waypoint_mode.value) {
		if ((M_Paused_Cusor == 3))
			Draw_ColoredString(10, 165, "Save Waypoints", 255, 0, 0, 255, 1);
		else
			Draw_ColoredString(10, 165, "Save Waypoints", 255, 255, 255, 255, 1);
	} else {
		if ((M_Paused_Cusor == 3))
			Draw_ColoredString(10, 165, "Achievements", 255, 0, 0, 255, 1);
		else
			Draw_ColoredString(10, 165, "Achievements", 255, 255, 255, 255, 1);
	}

	if ((M_Paused_Cusor == 4))
		Draw_ColoredString(10, 175, "Main Menu", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 175, "Main Menu", 255, 255, 255, 255, 1);
}

static void M_Paused_Menu_Key (int key)
{
	switch (key)
	{
		case K_ESCAPE:
			S_LocalSound ("sounds/menu/enter.wav");
			Cbuf_AddText("togglemenu\n");

		case K_DOWNARROW:
			S_LocalSound ("sounds/menu/navigate.wav");
			if (++M_Paused_Cusor >= Max_Paused_Iteams)
				M_Paused_Cusor = 0;
			break;

		case K_UPARROW:
			S_LocalSound ("sounds/menu/navigate.wav");
			if (--M_Paused_Cusor < 0)
				M_Paused_Cusor = Max_Paused_Iteams - 1;
			break;

		case K_ENTER:
			m_entersound = true;

			switch (M_Paused_Cusor)
			{
			case 0:
				key_dest = key_game;
				m_state = m_none;
				break;
			case 1:
				M_Menu_Restart_f();
				break;
			case 2:
				M_Menu_Options_f();
				key_dest = key_menu_pause;
				break;
			case 3:
				if (waypoint_mode.value)
					Cbuf_AddText("impulse 101\n");
				else
					M_Menu_Achievement_f();
				key_dest = key_menu_pause;
				break;
			case 4:
				M_Menu_Exit_f();
				break;
			}
		}
}

//=============================================================================
/* MAIN MENU */

int	m_main_cursor;
#define	MAIN_ITEMS	5


void M_Menu_Main_f (void)
{
	key_dest = key_menu;
	m_state = m_main;
	m_entersound = true;
}


void M_Main_Draw (void)
{
	// Background
	Draw_Pic (0, 0, menu_bk);

	// Fill black to make everything easier to see
	Draw_FillByColor(0, 0, 480, 272, GU_RGBA(0, 0, 0, 102));

	// Version String
	Draw_ColoredString(vid.width - 40, 5, "v1.0", 255, 255, 255, 255, 1);

	// Header
	Draw_ColoredString(10, 10, "MAIN MENU", 255, 255, 255, 255, 2);

	// Solo
	if (m_main_cursor == 0)
		Draw_ColoredString(10, 45, "Solo", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 45, "Solo", 255, 255, 255, 255, 1);


	// Co-Op (Unfinished, so non-selectable)
	Draw_ColoredString(10, 55, "Co-Op (Coming Soon!)", 128, 128, 128, 255, 1);

	// Divider
	Draw_FillByColor(10, 68, 160, 2, GU_RGBA(130, 130, 130, 255));

	if (m_main_cursor == 1)
		Draw_ColoredString(10, 75, "Settings", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 75, "Settings", 255, 255, 255, 255, 1);

	if (m_main_cursor == 2)
		Draw_ColoredString(10, 85, "Achievements", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 85, "Achievements", 255, 255, 255, 255, 1);

	// Divider
	Draw_FillByColor(10, 98, 160, 2, GU_RGBA(130, 130, 130, 255));

	if (m_main_cursor == 3)
		Draw_ColoredString(10, 105, "Credits", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 105, "Credits", 255, 255, 255, 255, 1);

	// Divider
	Draw_FillByColor(10, 118, 160, 2, GU_RGBA(130, 130, 130, 255));

	if (m_main_cursor == 4)
		Draw_ColoredString(10, 125, "Exit", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 125, "Exit", 255, 255, 255, 255, 1);

	// Descriptions
	switch(m_main_cursor) {
		case 0: // Solo
			Draw_ColoredString(10, 230, "Take on the Hordes by yourself.", 255, 255, 255, 255, 1);
			break;
		case 1: // Settings
			Draw_ColoredString(10, 230, "Adjust your Settings to Optimize your Experience.", 255, 255, 255, 255, 1);
			break;
		case 2: // Achievements
			Draw_ColoredString(10, 230, "View locked or unlocked Achievements.", 255, 255, 255, 255, 1);
			break;
		case 3: // Credits
			Draw_ColoredString(10, 230, "See who made NZ:P possible.", 255, 255, 255, 255, 1);
			break;
		case 4: // Exit
			Draw_ColoredString(10, 230, "Return to XMB.", 255, 255, 255, 255, 1);
			break;
	}
}


void M_Main_Key (int key)
{
	switch (key)
	{
		case K_DOWNARROW:
			S_LocalSound ("sounds/menu/navigate.wav");
			if (++m_main_cursor >= MAIN_ITEMS)
				m_main_cursor = 0;
			break;

		case K_UPARROW:
			S_LocalSound ("sounds/menu/navigate.wav");
			if (--m_main_cursor < 0)
				m_main_cursor = MAIN_ITEMS - 1;
			break;

		case K_ENTER:
			m_entersound = true;

			switch (m_main_cursor)
			{
				case 0:
					M_Menu_SinglePlayer_f ();
					break;

				/*case 1:
					M_Menu_MultiPlayer_f ();
					break;*/

				case 1:
					M_Menu_Options_f ();
					break;

				case 2:
					M_Menu_Achievement_f ();
					break;

				case 3:
					M_Menu_Credits_f ();
					break;

				case 4:
					M_Menu_Quit_f ();
					break;
			}
			break;
	}
}




//=============================================================================
/* RESTART MENU */

qboolean	wasInMenus;


char *restartMessage [] =
{

  " Are you sure you want",
  "  to restart this game? ",  //msg:0
  "                               ",
  "   X :Yes    O : No       "
};


void M_Menu_Restart_f (void)
{
	wasInMenus = (key_dest == key_menu_pause);
	key_dest = key_menu_pause;
	m_state = m_restart;
	m_entersound = true;
}


void M_Restart_Key (int key)
{
	switch (key)
	{
	case K_ESCAPE:
	case 'n':
	case 'N':
		m_state = m_paused_menu;
		m_entersound = true;
		break;

	case 'Y':
	case 'y':
	case K_ENTER:
		key_dest = key_game;
		m_state = m_none;
		// Cbuf_AddText ("restart\n"); // nai -- old, now do soft reset
		PR_ExecuteProgram (pr_global_struct->Soft_Restart);
		break;

	default:
		break;
	}

}


void M_Restart_Draw (void)
{
	m_state = m_paused_menu;
	m_recursiveDraw = true;
	M_Draw ();
	m_state = m_restart;

	M_DrawTextBox (56, 76, 24, 4);
	M_PrintOld (64, 84,  restartMessage[0]);
	M_PrintOld (64, 92,  restartMessage[1]);
	M_PrintOld (64, 100, restartMessage[2]);
	M_PrintOld (64, 108, restartMessage[3]);
}




//=============================================================================
/* EXIT MENU */


char *exitMessage [] =
{

  " Are you sure you want  ",
  "to quit to the Main Menu?",  //msg:0
  "                                  ",
  "   X :Yes    O : No       "
};


void M_Menu_Exit_f (void)
{
	wasInMenus = (key_dest == key_menu_pause);
	key_dest = key_menu_pause;
	m_state = m_exit;
	m_entersound = true;
}


void M_Exit_Key (int key)
{
	switch (key)
	{
	case K_ESCAPE:
	case 'n':
	case 'N':
		m_state = m_paused_menu;
		m_entersound = true;
		break;

	case 'Y':
	case 'y':
	case K_ENTER:
		Cbuf_AddText("disconnect\n");
		M_Menu_Main_f();
		break;

	default:
		break;
	}

}


void M_Exit_Draw (void)
{
	m_state = m_paused_menu;
	m_recursiveDraw = true;
	M_Draw ();
	m_state = m_exit;

	M_DrawTextBox (56, 76, 24, 4);
	M_PrintOld (64, 84,  exitMessage[0]);
	M_PrintOld (64, 92,  exitMessage[1]);
	M_PrintOld (64, 100, exitMessage[2]);
	M_PrintOld (64, 108, exitMessage[3]);
}

//=============================================================================
/* SINGLE PLAYER MENU */

int	m_map_cursor;
int	MAP_ITEMS;
int user_maps_num = 0;
int current_custom_map_page;
int custom_map_pages;
int multiplier;
char  user_levels[256][MAX_QPATH];

void M_Menu_Map_f (void)
{
	key_dest = key_menu;
	m_state = m_map;
	m_entersound = true;
	MAP_ITEMS = 13;
	current_custom_map_page = 1;
}


void M_Map_Draw (void)
{
	// Background
	Draw_Pic(0, 0, menu_bk);

	// Fill black to make everything easier to see
	Draw_FillByColor(0, 0, 480, 272, GU_RGBA(0, 0, 0, 102));

	// Version String
	Draw_ColoredString(vid.width - 40, 5, "v1.0", 255, 255, 255, 255, 1);

	// Header
	Draw_ColoredString(10, 10, "CUSTOM MAPS", 255, 255, 255, 255, 2);

	int 	line_increment;

	line_increment = 0;

	if (current_custom_map_page > 1)
		multiplier = (current_custom_map_page - 1) * 15;
	else
		multiplier = 0;

	for (int i = 0; i < 15; i++) {
		if (custom_maps[i + multiplier].occupied == false)
			continue;

		if (m_map_cursor == i) {

			if (custom_maps[i + multiplier].map_use_thumbnail == 1) {
				menu_cuthum = Draw_CacheImg(custom_maps[i + multiplier].map_thumbnail_path);
				Draw_Pic(256, 45, menu_cuthum);
			}
			
			if (custom_maps[i + multiplier].map_name_pretty != 0)
				Draw_ColoredString(10, 45 + (10 * i), custom_maps[i + multiplier].map_name_pretty, 255, 0, 0, 255, 1);
			else
				Draw_ColoredString(10, 45 + (10 * i), custom_maps[i + multiplier].map_name, 255, 0, 0, 255, 1);

			if (custom_maps[i + multiplier].map_desc_1 != 0) {
				if (strcmp(custom_maps[i + multiplier].map_desc_1, " ") != 0) {
					Draw_ColoredString(215, 155, custom_maps[i + multiplier].map_desc_1, 255, 255, 255, 255, 1);
				}
			}
			if (custom_maps[i + multiplier].map_desc_2 != 0) {
				if (strcmp(custom_maps[i + multiplier].map_desc_2, " ") != 0) {
					line_increment++;
					Draw_ColoredString(215, 165, custom_maps[i + multiplier].map_desc_2, 255, 255, 255, 255, 1);
				}
			}
			if (custom_maps[i + multiplier].map_desc_3 != 0) {
				if (strcmp(custom_maps[i + multiplier].map_desc_3, " ") != 0) {
					line_increment++;
					Draw_ColoredString(215, 175, custom_maps[i + multiplier].map_desc_3, 255, 255, 255, 255, 1);
				}
			}
			if (custom_maps[i + multiplier].map_desc_4 != 0) {
				if (strcmp(custom_maps[i + multiplier].map_desc_4, " ") != 0) {
					line_increment++;
					Draw_ColoredString(215, 185, custom_maps[i + multiplier].map_desc_4, 255, 255, 255, 255, 1);
				}
			}
			if (custom_maps[i + multiplier].map_desc_5 != 0) {
				if (strcmp(custom_maps[i + multiplier].map_desc_5, " ") != 0) {
					line_increment++;
					Draw_ColoredString(215, 195, custom_maps[i + multiplier].map_desc_5, 255, 255, 255, 255, 1);
				}
			}
			if (custom_maps[i + multiplier].map_desc_6 != 0) {
				if (strcmp(custom_maps[i + multiplier].map_desc_6, " ") != 0) {
					line_increment++;
					Draw_ColoredString(215, 205, custom_maps[i + multiplier].map_desc_6, 255, 255, 255, 255, 1);
				}
			}
			if (custom_maps[i + multiplier].map_desc_7 != 0) {
				if (strcmp(custom_maps[i + multiplier].map_desc_7, " ") != 0) {
					line_increment++;
					Draw_ColoredString(215, 215, custom_maps[i + multiplier].map_desc_7, 255, 255, 255, 255, 1);
				}
			}
			if (custom_maps[i + multiplier].map_desc_8 != 0) {
				if (strcmp(custom_maps[i + multiplier].map_desc_8, " ") != 0) {
					line_increment++;
					Draw_ColoredString(215, 225, custom_maps[i + multiplier].map_desc_8, 255, 255, 255, 255, 1);
				}
			}
			if (custom_maps[i + multiplier].map_author != 0) {
				if (strcmp(custom_maps[i + multiplier].map_author, " ") != 0) {
					int y = 165 + (10 * line_increment);
					Draw_ColoredString(215, y, custom_maps[i + multiplier].map_author, 255, 255, 0, 255, 1);
				}
			}
		} else {
			if (custom_maps[i + multiplier].map_name_pretty != 0)
				Draw_ColoredString(10, 45 + (10 * i), custom_maps[i + multiplier].map_name_pretty, 255, 255, 255, 255, 1);
			else
				Draw_ColoredString(10, 45 + (10 * i), custom_maps[i + multiplier].map_name, 255, 255, 255, 255, 1);
		}
	}

	if (current_custom_map_page != custom_map_pages) {
		if (m_map_cursor == 15)
			Draw_ColoredString(10, 230, "Next Page", 255, 0, 0, 255, 1);
		else
			Draw_ColoredString(10, 230, "Next Page", 255, 255, 255, 255, 1);
	} else {
		Draw_ColoredString(10, 230, "Next Page", 128, 128, 128, 255, 1);
	}

	if (current_custom_map_page != 1) {
		if (m_map_cursor == 16)
			Draw_ColoredString(10, 240, "Previous Page", 255, 0, 0, 255, 1);
		else
			Draw_ColoredString(10, 240, "Previous Page", 255, 255, 255, 255, 1);
	} else {
		Draw_ColoredString(10, 240, "Previous Page", 128, 128, 128, 255, 1);
	}



	if (m_map_cursor == 17)
		Draw_ColoredString(10, 250, "Back", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 250, "Back", 255, 255, 255, 255, 1);
}


void M_Map_Key (int key)
{
	switch (key)
	{
		case K_ESCAPE:
			M_Menu_SinglePlayer_f ();
			break;
		case K_DOWNARROW:
			S_LocalSound ("sounds/menu/navigate.wav");

			m_map_cursor++;

			if (m_map_cursor < 14 && custom_maps[m_map_cursor + multiplier].occupied == false) {
				m_map_cursor = 15;
			}

			if (m_map_cursor == 15 && current_custom_map_page == custom_map_pages)
				m_map_cursor = 16;
			
			if (m_map_cursor == 16 && current_custom_map_page == 1)
				m_map_cursor = 17;

			if (m_map_cursor >= 18)
				m_map_cursor = 0;
			break;
		case K_UPARROW:
			S_LocalSound ("sounds/menu/navigate.wav");

			m_map_cursor--;

			if (m_map_cursor < 0)
				m_map_cursor = 17;

			if (m_map_cursor == 16 && current_custom_map_page == 1)
				m_map_cursor = 15;

			if (m_map_cursor == 15 && current_custom_map_page == custom_map_pages)
				m_map_cursor = 14;

			if (m_map_cursor <= 14 && custom_maps[m_map_cursor + multiplier].occupied == false) {
				for (int i = 14; i > -1; i--) {
					if (custom_maps[i + multiplier].occupied == true) {
						m_map_cursor = i;
						break;
					}
				}
			}
			break;
		case K_ENTER:
			m_entersound = true;
			if (m_map_cursor == 17) {
				M_Menu_SinglePlayer_f ();
			} else if (m_map_cursor == 16) {
				current_custom_map_page--;
			} else if (m_map_cursor == 15) {
				current_custom_map_page++;
			} else
			{
				key_dest = key_game;
				if (sv.active)
					Cbuf_AddText ("disconnect\n");
				Cbuf_AddText ("maxplayers 1\n");
				Cbuf_AddText (va("map %s\n", custom_maps[m_map_cursor + multiplier].map_name));
				//loadingScreen = 1;
			}
			break;
	}
}


//=============================================================================
/* SINGLE PLAYER MENU */

int	m_singleplayer_cursor;
#define	SINGLEPLAYER_ITEMS	5


void M_Menu_SinglePlayer_f (void)
{
	key_dest = key_menu;
	m_state = m_singleplayer;
	m_entersound = true;
}


void M_SinglePlayer_Draw (void)
{
	menu_ndu 	= Draw_CacheImg("gfx/menu/nacht_der_untoten");
	//menu_kn 	= Draw_CacheImg("gfx/menu/kino_der_toten");
	menu_wh 	= Draw_CacheImg("gfx/menu/warehouse");
	//menu_wn 	= Draw_CacheImg("gfx/menu/wahnsinn");
	menu_ch 	= Draw_CacheImg("gfx/menu/christmas_special");
	menu_custom = Draw_CacheImg("gfx/menu/custom");

	// Background
	Draw_Pic(0, 0, menu_bk);

	// Fill black to make everything easier to see
	Draw_FillByColor(0, 0, 480, 272, GU_RGBA(0, 0, 0, 102));

	// Version String
	Draw_ColoredString(vid.width - 40, 5, "v1.0", 255, 255, 255, 255, 1);

	// Header
	Draw_ColoredString(10, 10, "SOLO", 255, 255, 255, 255, 2);

	// Nacht der Untoten
	if (m_singleplayer_cursor == 0)
		Draw_ColoredString(10, 45, "Nacht der Untoten", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 45, "Nacht der Untoten", 255, 255, 255, 255, 1);

	// Kino der Toten
	Draw_ColoredString(10, 55, "Kino der Toten", 128, 128, 128, 255, 1);

	// Warehouse
	if (m_singleplayer_cursor == 1)
		Draw_ColoredString(10, 65, "Warehouse", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 65, "Warehouse", 255, 255, 255, 255, 1);

	// Wahnsinn
	Draw_ColoredString(10, 75, "Wahnsinn", 128, 128, 128, 255, 1);

	// Christmas Special
	if (m_singleplayer_cursor == 2)
		Draw_ColoredString(10, 85, "Christmas Special", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 85, "Christmas Special", 255, 255, 255, 255, 1);

	// Divider
	Draw_FillByColor(10, 98, 160, 2, GU_RGBA(130, 130, 130, 255));

	// Custom Maps
	if (m_singleplayer_cursor == 3)
		Draw_ColoredString(10, 105, "Custom Maps", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 105, "Custom Maps", 255, 255, 255, 255, 1);

	// Back
	if (m_singleplayer_cursor == 4)
		Draw_ColoredString(10, 250, "Back", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 250, "Back", 255, 255, 255, 255, 1);

	// Map description & pic
	switch(m_singleplayer_cursor) {
		case 0:
			Draw_Pic(256, 45, menu_ndu);
			Draw_ColoredString(215, 155, "Lock and Load; Crashed Plane.", 255, 255, 255, 255, 1);
			Draw_ColoredString(215, 165, "Divided. Thousands of Undead.", 255, 255, 255, 255, 1);
			Draw_ColoredString(215, 175, "This is the Night of the Dead.", 255, 255, 255, 255, 1);
			break;
		case 1:
			Draw_Pic(256, 45, menu_wh);
			Draw_ColoredString(215, 155, "Old Warehouse full of Zombies!", 255, 255, 255, 255, 1);
			Draw_ColoredString(215, 165, "Fight your way to the Power", 255, 255, 255, 255, 1);
			Draw_ColoredString(215, 175, "Switch through the Hordes!", 255, 255, 255, 255, 1);
			break;
		case 2:
			Draw_Pic(256, 45, menu_ch);
			Draw_ColoredString(215, 155, "No Santa this year. Though we're", 255, 255, 255, 255, 1);
			Draw_ColoredString(215, 165, "sure you will get presents from", 255, 255, 255, 255, 1);
			Draw_ColoredString(215, 175, "the undead! Will you accept them?", 255, 255, 255, 255, 1);
			break;
		case 3:
			Draw_Pic(256, 45, menu_custom);
			Draw_ColoredString(215, 155, "Custom Maps made by Community", 255, 255, 255, 255, 1);
			Draw_ColoredString(215, 165, "Members on the Fourm and on", 255, 255, 255, 255, 1);
			Draw_ColoredString(215, 175, "Discord!", 255, 255, 255, 255, 1);
			break;
	}
}


void M_SinglePlayer_Key (int key)
{
	switch (key)
	{
		case K_ESCAPE:
			M_Menu_Main_f ();
			break;

		case K_DOWNARROW:
			S_LocalSound ("sounds/menu/navigate.wav");
			if (++m_singleplayer_cursor >= SINGLEPLAYER_ITEMS)
				m_singleplayer_cursor = 0;
			break;

		case K_UPARROW:
			S_LocalSound ("sounds/menu/navigate.wav");
			if (--m_singleplayer_cursor < 0)
				m_singleplayer_cursor = SINGLEPLAYER_ITEMS - 1;
			break;

		case K_ENTER:
			m_entersound = true;

			switch (m_singleplayer_cursor)
			{
				case 0:
					key_dest = key_game;
					if (sv.active)
						Cbuf_AddText ("disconnect\n");
					Cbuf_AddText ("maxplayers 1\n");
					Cbuf_AddText ("map ndu\n");
					loadingScreen = 1;
					break;
				case 1:
					key_dest = key_game;
					if (sv.active)
						Cbuf_AddText ("disconnect\n");
					Cbuf_AddText ("maxplayers 1\n");
					Cbuf_AddText ("map warehouse\n");
					loadingScreen = 2;
					break;
				case 2:
					key_dest = key_game;
					if (sv.active)
						Cbuf_AddText ("disconnect\n");
					Cbuf_AddText ("maxplayers 1\n");
					Cbuf_AddText ("map christmas_special\n");
					loadingScreen = 3;
					break;
				case 3:
					M_Menu_Map_f ();
					break;
				case 4:
					M_Menu_Main_f ();
					break;
			}
			break;
	}
}

//=============================================================================
/* ACHIEVEMENT MENU */

int m_achievement_cursor;
int m_achievement_selected;
int m_achievement_scroll[2];
int total_unlocked_achievements;
int total_locked_achievements;


achievement_list_t achievement_list[MAX_ACHIEVEMENTS];
qpic_t *achievement_locked;

void Achievement_Init (void)
{
	achievement_list[0].img = Draw_CachePic("gfx/achievement/ready");
	achievement_list[0].unlocked = 0;
	achievement_list[0].progress = 0;
	strcpy(achievement_list[0].name, "Ready..");
	strcpy(achievement_list[0].description, "Reach round 5");

	achievement_list[1].img = Draw_CachePic("gfx/achievement/steady");
	achievement_list[1].unlocked = 0;
	achievement_list[1].progress = 0;
	strcpy(achievement_list[1].name, "Steady..");
	strcpy(achievement_list[1].description, "Reach round 10");

	achievement_list[2].img = Draw_CachePic("gfx/achievement/go_hell_no");
	achievement_list[2].unlocked = 0;
	achievement_list[2].progress = 0;
	strcpy(achievement_list[2].name, "Go? Hell No...");
	strcpy(achievement_list[2].description, "Reach round 15");

	achievement_list[3].img = Draw_CachePic("gfx/achievement/where_legs_go");
	achievement_list[3].unlocked = 0;
	achievement_list[3].progress = 0;
	strcpy(achievement_list[3].name, "Where Did Legs Go?");
	strcpy(achievement_list[3].description, "Turn a zombie into a crawler");

	achievement_list[4].img = Draw_CachePic("gfx/achievement/the_f_bomb");
	achievement_list[4].unlocked = 0;
	achievement_list[4].progress = 0;
	strcpy(achievement_list[4].name, "The F Bomb");
	strcpy(achievement_list[4].description, "Use the Nuke power-up to kill a single Zombie");

	/*achievement_list[3].img = Draw_CachePic("gfx/achievement/beast");
	achievement_list[3].unlocked = 0;
	achievement_list[3].progress = 0;
	strcpy(achievement_list[3].name, "Beast");
	strcpy(achievement_list[3].description, "Survive round after round 5 with knife and grenades only");

	achievement_list[4].img = Draw_CachePic("gfx/achievement/survival");
	achievement_list[4].unlocked = 0;
	achievement_list[4].progress = 0;
	strcpy(achievement_list[4].name, "Survival Expert");
	strcpy(achievement_list[4].description, "Use pistol and knife only to reach round 10");

	achievement_list[5].img = Draw_CachePic("gfx/achievement/boomstick");
	achievement_list[5].unlocked = 0;
	achievement_list[5].progress = 0;
	strcpy(achievement_list[5].name, "Boomstick");
	strcpy(achievement_list[5].description, "3 for 1 with shotgun blast");

	achievement_list[6].img = Draw_CachePic("gfx/achievement/boom_headshots");
	achievement_list[6].unlocked = 0;
	achievement_list[6].progress = 0;
	strcpy(achievement_list[6].name, "Boom Headshots");
	strcpy(achievement_list[6].description, "Get 10 headshots");

	achievement_list[7].img = Draw_CachePic("gfx/achievement/where_did");
	achievement_list[7].unlocked = 0;
	achievement_list[7].progress = 0;
	strcpy(achievement_list[7].name, "Where Did Legs Go?");
	strcpy(achievement_list[7].description, "Make a crawler zombie");

	achievement_list[8].img = Draw_CachePic("gfx/achievement/keep_the_change");
	achievement_list[8].unlocked = 0;
	achievement_list[8].progress = 0;
	strcpy(achievement_list[8].name, "Keep The Change");
	strcpy(achievement_list[8].description, "Purchase everything");

	achievement_list[9].img = Draw_CachePic("gfx/achievement/big_thanks");
	achievement_list[9].unlocked = 0;
	achievement_list[9].progress = 0;
	strcpy(achievement_list[9].name, "Big Thanks To Explosion");
	strcpy(achievement_list[9].description, "Get 10 kills with one grenade");

	achievement_list[10].img = Draw_CachePic("gfx/achievement/warmed-up");
	achievement_list[10].unlocked = 0;
	achievement_list[10].progress = 0;
	strcpy(achievement_list[10].name, "Getting Warmed-Up");
	strcpy(achievement_list[10].description, "Achieve 10 achievements");

	achievement_list[11].img = Draw_CachePic("gfx/achievement/mysterybox_maniac");
	achievement_list[11].unlocked = 0;
	achievement_list[11].progress = 0;
	strcpy(achievement_list[11].name, "Mysterybox Maniac");
	strcpy(achievement_list[11].description, "use mysterybox 20 times");

	achievement_list[12].img = Draw_CachePic("gfx/achievement/instant_help");
	achievement_list[12].unlocked = 0;
	achievement_list[12].progress = 0;
	strcpy(achievement_list[12].name, "Instant Help");
	strcpy(achievement_list[12].description, "Kill 100 zombies with insta-kill");

	achievement_list[13].img = Draw_CachePic("gfx/achievement/blow_the_bank");
	achievement_list[13].unlocked = 0;
	achievement_list[13].progress = 0;
	strcpy(achievement_list[13].name, "Blow The Bank");
	strcpy(achievement_list[13].description, "earn 1,000,000");

	achievement_list[14].img = Draw_CachePic("gfx/achievement/ammo_cost");
	achievement_list[14].unlocked = 0;
	achievement_list[14].progress = 0;
	strcpy(achievement_list[14].name, "Ammo Cost Too Much");
	strcpy(achievement_list[14].description, "After round 5, don't fire a bullet for whole round");

	achievement_list[15].img = Draw_CachePic("gfx/achievement/the_f_bomb");
	achievement_list[15].unlocked = 0;
	achievement_list[15].progress = 0;
	strcpy(achievement_list[15].name, "The F Bomb");
	strcpy(achievement_list[15].description, "Only nuke one zombie");

	achievement_list[16].img = Draw_CachePic("gfx/achievement/why_are");
	achievement_list[16].unlocked = 0;
	achievement_list[16].progress = 0;
	strcpy(achievement_list[16].name, "Why Are We Waiting?");
	strcpy(achievement_list[16].description, "Stand still for 2 minutes");

	achievement_list[17].img = Draw_CachePic("gfx/achievement/never_missed");
	achievement_list[17].unlocked = 0;
	achievement_list[17].progress = 0;
	strcpy(achievement_list[17].name, "Never Missed A Shot");
	strcpy(achievement_list[17].description, "Make it to round 5 without missing a shot");

	achievement_list[18].img = Draw_CachePic("gfx/achievement/300_bastards_less");
	achievement_list[18].unlocked = 0;
	achievement_list[18].progress = 0;
	strcpy(achievement_list[18].name, "300 Bastards less");
	strcpy(achievement_list[18].description, "Kill 300 zombies");

	achievement_list[19].img = Draw_CachePic("gfx/achievement/music_fan");
	achievement_list[19].unlocked = 0;
	achievement_list[19].progress = 0;
	strcpy(achievement_list[19].name, "Music Fan");
	strcpy(achievement_list[19].description, "Turn on radio 20 times");

	achievement_list[20].img = Draw_CachePic("gfx/achievement/one_clip");
	achievement_list[20].unlocked = 0;
	achievement_list[20].progress = 0;
	strcpy(achievement_list[20].name, "One Clip");
	strcpy(achievement_list[20].description, "Complete a round with mg42 without reloading");

	achievement_list[21].img = Draw_CachePic("gfx/achievement/one_20_20");
	achievement_list[21].unlocked = 0;
	achievement_list[21].progress = 0;
	strcpy(achievement_list[21].name, "One Clip, 20 Bullets, 20 Headshots");
	strcpy(achievement_list[21].description, "Score 20 headshots, with 20 bullets, and don't reload");

	achievement_list[22].img = Draw_CachePic("gfx/achievement/and_stay_out");
	achievement_list[22].unlocked = 0;
	achievement_list[22].progress = 0;
	strcpy(achievement_list[22].name, "And Stay out");
	strcpy(achievement_list[22].description, "Don't let zombies in for 2 rounds");*/

	achievement_locked = Draw_CachePic("gfx/achievement/achievement_locked");

	m_achievement_scroll[0] = 0;
	m_achievement_scroll[1] = 0;
}


void Load_Achivements (void)
{
	int achievement_file;
	achievement_file = sceIoOpen(va("%s/data/ach.dat",com_gamedir), PSP_O_RDONLY, 0);

	if (achievement_file >= 0) {
		char* buffer = (char*)calloc(2, sizeof(char));
		for (int i = 0; i < MAX_ACHIEVEMENTS; i++) {
			sceIoRead(achievement_file, buffer, sizeof(char)*2);
			achievement_list[i].unlocked = atoi(buffer);
			sceIoRead(achievement_file, buffer, sizeof(char)*2);
			achievement_list[i].progress = atoi(buffer);
		}
	} else {
		achievement_file = sceIoOpen(va("%s/data/ach.dat",com_gamedir), PSP_O_WRONLY | PSP_O_CREAT | PSP_O_TRUNC, 0);

		for (int i = 0; i < MAX_ACHIEVEMENTS; i++) {
			sceIoWrite(achievement_file, "0\n", sizeof(char)*2);
			sceIoWrite(achievement_file, "0\n", sizeof(char)*2);
		}
	}
	sceIoClose(achievement_file);
}
void Save_Achivements (void)
{
	int achievement_file;
	achievement_file = sceIoOpen(va("%s/data/ach.dat",com_gamedir), PSP_O_WRONLY, 0);

	if (achievement_file >= 0) {
		for (int i = 0; i < MAX_ACHIEVEMENTS; i++) {
			char* buffer = va("%i\n", achievement_list[i].unlocked);
			char* buffer2 = va("%i\n", achievement_list[i].progress);
			sceIoWrite(achievement_file, va("%i\n", achievement_list[i].unlocked), strlen(buffer));
			sceIoWrite(achievement_file, va("%i\n", achievement_list[i].progress), strlen(buffer2));
		}
	} else {
		Load_Achivements();
	}
}


void M_Menu_Achievement_f (void)
{
	key_dest = key_menu;
	m_state = m_achievement;
	m_entersound = true;
	//Load_Achivements();
}

void M_Achievement_Draw (void)
{
    int i, b, y;
    int unlocked_achievement[MAX_ACHIEVEMENTS];
    int locked_achievement[MAX_ACHIEVEMENTS];
	int maxLenght = floor((vid.width - 155)/8);
	int	stringLenght;
	char *description;
	char *string_line = (char*) malloc(maxLenght);
	int lines;

    y = 0;
    total_unlocked_achievements = 0;
    total_locked_achievements = 0;

    for (i = 0; i < MAX_ACHIEVEMENTS; i++)
    {
        unlocked_achievement[i] = -1;
        locked_achievement[i] = -1;
        if (achievement_list[i].unlocked)
        {
            unlocked_achievement[total_unlocked_achievements] = i;
            total_unlocked_achievements += 1;
        }
        else
        {
            locked_achievement[total_locked_achievements] = i;
            total_locked_achievements += 1;
        }
    }

	// Background
	if (key_dest != key_menu_pause)
		Draw_Pic (0, 0, menu_bk);

	// Fill black to make everything easier to see
	Draw_FillByColor(0, 0, 480, 272, GU_RGBA(0, 0, 0, 102));

	// Version String
	Draw_ColoredString(vid.width - 40, 5, "v1.0", 255, 255, 255, 255, 1);

    if (!m_achievement_selected)
    {
        Draw_FillByColor(15, 8, 225, 12, GU_RGBA(204, 0, 0, 100));
        Draw_FillByColor(240, 8, 225, 12, GU_RGBA(0, 0, 0, 100));

        if (total_unlocked_achievements <= 0)
        {
            Draw_FillByColor(15, 25, vid.width - 30, 60, GU_RGBA (0, 0, 0, 100));
            Draw_Pic (20, 30 + y, achievement_locked);
            Draw_String (125, 30 + y, "No achievements unlocked :(");
        }
        else
        {
            for (i = 0; i < 3; i++)
            {
                if (unlocked_achievement[i + m_achievement_scroll[0]] >= 0)
                {
                    Draw_FillByColor(15, 25 + y, vid.width - 30, 60, GU_RGBA (0, 0, 0, 100));

                    Draw_Pic (20, 30 + y, achievement_list[unlocked_achievement[i + m_achievement_scroll[0]]].img);
                    Draw_String (125, 30 + y, achievement_list[unlocked_achievement[i + m_achievement_scroll[0]]].name);
					description = achievement_list[unlocked_achievement[i + m_achievement_scroll[0]]].description;
					stringLenght = strlen(description);
					lines = stringLenght/maxLenght;
					if ((maxLenght % stringLenght) != 0)
						lines++;
					
					for (b = 0; b < lines; b++) {
						strncpy(string_line, description+maxLenght*b, (maxLenght-1));
						Draw_String (125, 40 + y + b*8, string_line);
					}
					
					//if (stringLenght <= maxLenght)
					//	Draw_String (125, 40 + y, description);

                    y += 75;
                }
            }
        }
    }
    else
    {
        if (total_locked_achievements <= 0)
        {
            Draw_FillByColor(15, 25, vid.width - 30, 60, GU_RGBA (0, 0, 0, 100));
            Draw_Pic (20, 30 + y, achievement_locked);
            Draw_String (125, 30 + y, "All achievements unlocked :)");
        }

        Draw_FillByColor(15, 8, 225, 12, GU_RGBA(0, 0, 0, 100));
        Draw_FillByColor(240, 8, 225, 12, GU_RGBA(204, 0, 0, 100));

        for (i = 0; i < 3; i++)
        {
            if (locked_achievement[i + m_achievement_scroll[1]] >= 0)
            {
                Draw_FillByColor(15, 25 + y, vid.width - 30, 60, GU_RGBA (0, 0, 0, 100));

                Draw_Pic (20, 30 + y, achievement_locked);
                Draw_String (125, 30 + y, achievement_list[locked_achievement[i + m_achievement_scroll[1]]].name);
				description = achievement_list[locked_achievement[i + m_achievement_scroll[1]]].description;
				stringLenght = strlen(description);
				lines = stringLenght/maxLenght;
				if ((maxLenght % stringLenght) != 0)
					lines++;
				
				for (b = 0; b < lines; b++) {
					strncpy(string_line, description+maxLenght*b, (maxLenght-1));
					Draw_String (125, 40 + y + b*8, string_line);
				}
					
					
				//if (stringLenght <= maxLenght)
				//	Draw_String (125, 40 + y, description);

                y += 70;
            }
        }
    }

	free(string_line);
    Draw_String (15, 10, "Unlocked Achievements");
    Draw_String (vid.width - 167, 10, "Locked Achievements");
}

void M_Achievement_Key (int key)
{
	switch (key)
	{
	case K_ESCAPE:
		if (key_dest == key_menu_pause)
			M_Paused_Menu_f();
		else
			M_Menu_Main_f ();
		break;

    case K_AUX1:
    case K_LEFTARROW:
        m_achievement_selected = 0;
        break;

    case K_AUX2:
    case K_RIGHTARROW:
        m_achievement_selected = 1;
        break;

    case K_UPARROW:
        m_achievement_scroll[m_achievement_selected]--;
        if (m_achievement_scroll[m_achievement_selected] < 0)
            m_achievement_scroll[m_achievement_selected] = 0;
        break;

    case K_DOWNARROW:
        m_achievement_scroll[m_achievement_selected]++;

        if (m_achievement_selected)
        {
            if (m_achievement_scroll[1] > total_locked_achievements - 3)
                m_achievement_scroll[1] = total_locked_achievements - 3;
        }
        else
        {
            if (m_achievement_scroll[0] > total_unlocked_achievements - 3)
                m_achievement_scroll[0] = total_unlocked_achievements - 3;
        }
        if (m_achievement_scroll[m_achievement_selected] < 0)
            m_achievement_scroll[m_achievement_selected] = 0;
        break;

	case K_ENTER:
		m_entersound = true;
		switch (m_achievement_cursor)
		{
		}
	}
}

//=============================================================================
/* MULTIPLAYER MENU */

int	m_multiplayer_cursor;

#define	MULTIPLAYER_ITEMS   6

void M_Menu_MultiPlayer_f (void)
{
	key_dest = key_menu;
	m_state = m_multiplayer;
	m_entersound = true;
}

#include <pspwlan.h>
void M_MultiPlayer_Draw (void)
{
	//int		f;


    if (key_dest != key_menu_pause)
		Draw_Pic (0, 0, menu_bk);
	//else
		//Draw_AlphaPic (0, 0, pause_bk, 0.4);
	//f = (int)(host_time * 10)%6;

	//M_DrawTransPic (54, 32 + m_multiplayer_cursor * 20,Draw_CachePic( va("gfx/menudot%i.lmp", f+1 ) ) );


    if (m_multiplayer_cursor == 0)
		M_Print ((vid.width - ((9 * 8) + 16)), (vid.height - 64),  "Join Game");
    else
		M_PrintWhite ((vid.width - ((9 * 8) + 16)), (vid.height - 64),  "Join Game");

    if (m_multiplayer_cursor == 1)
		M_Print ((vid.width - ((9 * 8) + 16)), (vid.height - 56),  "Host Game");
    else
		M_PrintWhite ((vid.width - ((9 * 8) + 16)), (vid.height - 56),  "Host Game");

    if (m_multiplayer_cursor == 2)
		M_Print ((vid.width - ((12 * 8) + 16)), (vid.height - 48),  "Player Setup");
    else
		M_PrintWhite ((vid.width - ((12 * 8) + 16)), (vid.height - 48),  "Player Setup");


    if (m_multiplayer_cursor == 3)
		M_Print ((vid.width - ((11 * 8) + 16)), (vid.height - 40),  "Server List");
    else
		M_PrintWhite ((vid.width - ((11 * 8) + 16)), (vid.height - 40),  "Server List");


   // M_PrintOld (72, 97,  "Slist          ");
    if (m_multiplayer_cursor == 4)
		M_Print ((vid.width - ((14 * 8) + 16)), (vid.height - 32),  "Infrastructure");
    else
		M_PrintWhite ((vid.width - ((14 * 8) + 16)), (vid.height - 32),  "Infrastructure");

    if (m_multiplayer_cursor == 5)
		M_Print ((vid.width - ((5 * 8) + 16)), (vid.height - 24),  "Adhoc");
    else
		M_PrintWhite ((vid.width - ((5 * 8) + 16)), (vid.height - 24),  "Adhoc");

	// M_PrintOld (72, 117, "Infrastructure ");
	//M_DrawCheckboxOld (220, 117, tcpipAvailable && !tcpipAdhoc);
	M_DrawCheckbox (220, vid.height - 32, tcpipAvailable && !tcpipAdhoc);

	//M_PrintOld (72, 137, "Adhoc          ");
	//M_DrawCheckboxOld (220, 137, tcpipAvailable && tcpipAdhoc);
	M_DrawCheckbox (220, vid.height - 24, tcpipAvailable && tcpipAdhoc);

    if (serialAvailable || ipxAvailable || tcpipAvailable)
	    	return;

	//M_PrintWhiteOld ((160) - ((35*8)/2), 180, "No Network Communications Available");
	M_PrintWhiteOld ((160) - ((35*8)/2), 180, "PSP MULTIPLAYER IS NOT OFFICALY SUPPORTED");
	M_PrintWhiteOld ((160) - ((35*8)/2), 188, "DO NOT ASK HOW TO PLAY ONLINE ON PSP");

}


void M_MultiPlayer_Key (int key)
{
	switch (key)
	{
	case K_ESCAPE:
		M_Menu_Main_f ();
		break;

	case K_DOWNARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		if (++m_multiplayer_cursor >= MULTIPLAYER_ITEMS)
			m_multiplayer_cursor = 0;
		break;

	case K_UPARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		if (--m_multiplayer_cursor < 0)
			m_multiplayer_cursor = MULTIPLAYER_ITEMS - 1;
		break;

	case K_ENTER:
		m_entersound = true;
		switch (m_multiplayer_cursor)
		{
		case 0:
			if ((serialAvailable || ipxAvailable || tcpipAvailable) && sceWlanDevIsPowerOn())
			{
				//M_Menu_Net_f ();
				M_Menu_LanConfig_f ();
			}
			break;

		case 1:
			if ((serialAvailable || ipxAvailable || tcpipAvailable) && sceWlanDevIsPowerOn())
			{
				//M_Menu_Net_f ();
				M_Menu_LanConfig_f ();
			}
			break;

		case 2:
			M_Menu_Setup_f ();
			break;

	    case 3:
			M_Menu_ServerList_f();
			break;

		case 4:
			Datagram_Shutdown();

			tcpipAvailable = !tcpipAvailable;

			if(tcpipAvailable && sceWlanDevIsPowerOn())
			{
				tcpipAdhoc = false;
				net_driver_to_use = 0;
				Datagram_Init();
			}
			break;
		case 5:
			Datagram_Shutdown();

			tcpipAvailable = !tcpipAvailable;

			if(tcpipAvailable && sceWlanDevIsPowerOn())
			{
				tcpipAdhoc = true;
				net_driver_to_use = 1;
				Datagram_Init();
			}
			break;
		}
	}
}

//=============================================================================
/* SETUP MENU */

int		setup_cursor = 5;
int		setup_cursor_table[] = {40, 56, 72, 96, 120, 156};

char	setup_hostname[16];
char	setup_myname[16];

// Define PSP specific variables
#define	NUM_SETUP_CMDS	4
extern int totalAccessPoints;
extern int accessPointNumber[100];
char    setup_accesspoint[64];

void M_Menu_Setup_f (void)
{
	key_dest = key_menu;
	m_state = m_setup;
	m_entersound = true;
	Q_strcpy(setup_myname, cl_name.string);
	Q_strcpy(setup_hostname, hostname.string);
	//setup_accesspoint ;

	if(totalAccessPoints)
	{
	    sceUtilityGetNetParam(accessPointNumber[(int)accesspoint.value], 0, (netData*)setup_accesspoint);
	}
}

void M_Setup_Draw (void)
{

    if (key_dest != key_menu_pause)
		Draw_Pic (0, 0, menu_bk);

	if (setup_cursor == 0)
		M_Print (64, 72,  "Access Point");
	else
		M_PrintWhite (64,72,  "Access Point");

	//M_PrintOld (64, 40, "Access Point");
	//M_DrawTextBox (160, 32, 16, 1);
	M_PrintOld (168, 72, setup_accesspoint);

	if (setup_cursor == 1)
		M_Print (64, 92,  "Hostname");
	else
		M_PrintWhite (64,92,  "Hostname");

	M_DrawTextBox (160, 84, 16, 1);
	M_PrintOld (168, 92, setup_hostname);

	if (setup_cursor == 2)
		M_Print (64, 104,  "Player Name");
	else
		M_PrintWhite (64,104,  "Player Name");

	M_DrawTextBox (160, 96, 16, 1);
	M_PrintOld (168, 104, setup_myname);

	if (setup_cursor == 3)
		M_Print (186, 120,  "Accept Changes");
	else
		M_PrintWhite (186,120,  "Accept Changes");
}


void M_Setup_Key (int k)
{
	int	l;
	int	offset = 0;

	switch (k)
	{
	case K_ESCAPE:
		M_Menu_MultiPlayer_f ();
		break;

	case K_UPARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		setup_cursor--;
		if (setup_cursor < 0)
			setup_cursor = NUM_SETUP_CMDS-1;
		break;

	case K_DOWNARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		setup_cursor++;
		if (setup_cursor >= NUM_SETUP_CMDS)
			setup_cursor = 0;
		break;

	case K_LEFTARROW:
		if (setup_cursor == 0)
		{
			S_LocalSound ("sounds/menu/navigate.wav");
			if(accesspoint.value > 1)
			{
				Cvar_SetValue("accesspoint", accesspoint.value-1);
				//blubso
				sceUtilityGetNetParam(accessPointNumber[(int)accesspoint.value], 0, (netData*)setup_accesspoint);
			}
		}
		offset = 1;
		if (setup_cursor < 2+offset)
			return;
		S_LocalSound ("sounds/menu/navigate.wav");
		break;
	case K_RIGHTARROW:
		if (setup_cursor == 0)
		{
			S_LocalSound ("sounds/menu/navigate.wav");
			if(accesspoint.value < totalAccessPoints)
			{
				Cvar_SetValue("accesspoint", accesspoint.value+1);
				//blubso
				sceUtilityGetNetParam(accessPointNumber[(int)accesspoint.value], 0, (netData*)setup_accesspoint);
			}
		}

		offset = 1;

		if (setup_cursor < 2+offset)
			return;

		S_LocalSound ("sounds/menu/navigate.wav");
		break;

	case K_INS:
		offset = 1;
		if (setup_cursor == 0+offset)
		{
			M_Menu_OSK_f(setup_hostname, setup_hostname, 16);
			break;
		}

		if (setup_cursor == 1+offset)
		{
			M_Menu_OSK_f(setup_myname, setup_myname,16);
			break;
		}
		break;

	case K_ENTER:
		offset = 1;
		if (setup_cursor == 0+offset || setup_cursor == 1+offset || setup_cursor== 0)
			return;

		//if (setup_cursor == 2+offset || setup_cursor == 3+offset)
		//	goto forward;

	//	if (setup_cursor < 4+offset)
	//		break;

		// setup_cursor == 4 (OK)
		if (Q_strcmp(cl_name.string, setup_myname) != 0)
			Cbuf_AddText ( va ("name \"%s\"\n", setup_myname) );
		if (Q_strcmp(hostname.string, setup_hostname) != 0)
			Cvar_Set("hostname", setup_hostname);
		m_entersound = true;
		M_Menu_MultiPlayer_f ();
		break;

	case K_BACKSPACE:
		offset = 1;
		if (setup_cursor == 0+offset)
		{
			if (strlen(setup_hostname))
				setup_hostname[strlen(setup_hostname)-1] = 0;
		}

		if (setup_cursor == 1+offset)
		{
			if (strlen(setup_myname))
				setup_myname[strlen(setup_myname)-1] = 0;
		}
		break;

	default:
		if (k < 32 || k > 127)
			break;

		offset = 1;

		if (setup_cursor == 0+offset)
		{
			l = strlen(setup_hostname);
			if (l < 15)
			{
				setup_hostname[l+1] = 0;
				setup_hostname[l] = k;
			}
		}
		if (setup_cursor == 1+offset)
		{
			l = strlen(setup_myname);
			if (l < 15)
			{
				setup_myname[l+1] = 0;
				setup_myname[l] = k;
			}
		}
	}
}

//=============================================================================
/* SERVER LIST MENU */
void M_Menu_SEdit_f (void);

#define	MENU_X	50
#define	MENU_Y	21
#define TITLE_Y 4
#define	STAT_Y	166

int	slist_cursor = 0, slist_mins = 0, slist_maxs = 15, slist_state;

void M_Menu_ServerList_f (void)
{
	key_dest = key_menu;
	m_state = m_slist;
	m_entersound = true;

	slist_state = 0;
}

void M_ServerList_Draw (void)
{
	int	serv, line;

    if (key_dest != key_menu_pause)
		Draw_Pic (0, 0, menu_bk);
	//else
		//Draw_AlphaPic (0, 0, pause_bk, 0.4);

	M_DrawTextBox (MENU_X, TITLE_Y, 23, 1);
	M_PrintWhiteOld (MENU_X + 60, TITLE_Y + 8, "Server List");

	if (!slist[0].server)
	{
		M_PrintWhiteOld (84, MENU_Y + 16 + 16, "Empty server list");
		M_PrintOld (60, MENU_Y + 16 + 32, "Press TRIANGLE to add a server");
		M_PrintOld (60, MENU_Y + 16 + 40, "Press SQUARE to edit a server");
        M_PrintOld (60, MENU_Y + 16 + 48, "Press CIRCLE to exit");
		return;
	}

	M_DrawTextBox (MENU_X, STAT_Y, 23, 1);
	M_DrawTextBox (MENU_X, MENU_Y, 23, slist_maxs - slist_mins + 1);
	for (serv = slist_mins, line = 1 ; serv <= slist_maxs && serv < MAX_SERVER_LIST && slist[serv].server ; serv++, line++)
		M_PrintOld (MENU_X + 18, line * 8 + MENU_Y, va("%1.21s", slist[serv].description));
	M_PrintWhiteOld (MENU_X, STAT_Y - 4, "TRIANGLE = add server, SQUARE = edit");
	M_PrintWhiteOld (MENU_X + 18, STAT_Y + 8, va("%1.22s", slist[slist_cursor].server));
	M_DrawCharacter2 (MENU_X + 8, (slist_cursor - slist_mins + 1) * 8 + MENU_Y, 12+((int)(realtime*4)&1));
}

void M_ServerList_Key (int key)
{
	int	slist_length;

	if (!slist[0].server && key != K_ESCAPE && key != K_DEL)
		return;

	switch (key)
	{
	case K_ESCAPE:
		M_Menu_MultiPlayer_f ();
		break;

	case K_UPARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		if (slist_cursor > 0)
		{
			if (keydown[K_CTRL])
				SList_Switch (slist_cursor, slist_cursor - 1);
			slist_cursor--;
		}
		break;

	case K_DOWNARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		if (keydown[K_CTRL])
		{
			if (slist_cursor != SList_Length() - 1)
			{
				SList_Switch (slist_cursor, slist_cursor + 1);
				slist_cursor++;
			}
		}
		else if (slist_cursor < MAX_SERVER_LIST - 1 && slist[slist_cursor+1].server)
			slist_cursor++;
		break;

	case K_HOME:
		S_LocalSound ("sounds/menu/navigate.wav");
		slist_cursor = 0;
		break;

	case K_END:
		S_LocalSound ("sounds/menu/navigate.wav");
		slist_cursor = SList_Length() - 1;
		break;

	case K_PGUP:
		S_LocalSound ("sounds/menu/navigate.wav");
		slist_cursor -= (slist_maxs - slist_mins);
		if (slist_cursor < 0)
			slist_cursor = 0;
		break;

	case K_PGDN:
		S_LocalSound ("sounds/menu/navigate.wav");
		slist_cursor += (slist_maxs - slist_mins);
		if (slist_cursor >= MAX_SERVER_LIST)
			slist_cursor = MAX_SERVER_LIST - 1;
		while (!slist[slist_cursor].server)
			slist_cursor--;
		break;

	case K_ENTER:
		if (keydown[K_CTRL])
		{
			M_Menu_SEdit_f ();
			break;
		}
		m_state = m_main;
		M_ToggleMenu_f ();
		Cbuf_AddText (va("connect \"%s\"\n", slist[slist_cursor].server));
		break;

	//case 'e':
	//case 'E':
	case K_INS:
		M_Menu_SEdit_f ();
		break;

	case K_DEL:
		S_LocalSound ("sounds/menu/enter.wav");
		if ((slist_length = SList_Length()) < MAX_SERVER_LIST)
		{
			if (keydown[K_CTRL] && slist_length > 0)
			{
				if (slist_cursor < slist_length - 1)
					memmove (&slist[slist_cursor+2], &slist[slist_cursor+1], (slist_length - slist_cursor - 1) * sizeof(slist[0]));
				SList_Reset_NoFree (slist_cursor + 1);
				SList_Set (slist_cursor + 1, "127.0.0.1", "<BLANK>");
				if (slist_length)
					slist_cursor++;
			}
			else
			{
				memmove (&slist[slist_cursor+1], &slist[slist_cursor], (slist_length - slist_cursor) * sizeof(slist[0]));
				SList_Reset_NoFree (slist_cursor);
				SList_Set (slist_cursor, "127.0.0.1", "<BLANK>");
			}
		}
		break;

	case K_LEFTARROW:
		S_LocalSound("sounds/menu/enter.wav");
		if ((slist_length = SList_Length()) > 0)
		{
			SList_Reset (slist_cursor);
			if (slist_cursor > 0 && slist_length - 1 == slist_cursor)
			{
				slist_cursor--;
			}
			else
			{
				memmove (&slist[slist_cursor], &slist[slist_cursor+1], (slist_length - slist_cursor - 1) * sizeof(slist[0]));
				SList_Reset_NoFree (slist_length - 1);
			}
		}
		break;
	}

	if (slist_cursor < slist_mins)
	{
		slist_maxs -= (slist_mins - slist_cursor);
		slist_mins = slist_cursor;
	}
	if (slist_cursor > slist_maxs)
	{
		slist_mins += (slist_cursor - slist_maxs);
		slist_maxs = slist_cursor;
	}
}

#define	SERV_X	60
#define	SERV_Y	64
#define	DESC_X	60
#define	DESC_Y	40
#define	SERV_L	23
#define	DESC_L	23

#define	SLIST_BUFSIZE	128

static	char	slist_serv[SLIST_BUFSIZE], slist_desc[SLIST_BUFSIZE];
static	int	slist_serv_max, slist_serv_min, slist_desc_max, slist_desc_min, sedit_state;

void M_Menu_SEdit_f (void)
{
	int	size;

	key_dest = key_menu;
	m_state = m_sedit;
	m_entersound = true;

	sedit_state = 0;
	Q_strncpyz (slist_serv, slist[slist_cursor].server, sizeof(slist_serv));
	Q_strncpyz (slist_desc, slist[slist_cursor].description, sizeof(slist_desc));
	slist_serv_max = (size = strlen(slist_serv)) > SERV_L ? size : SERV_L;
	slist_serv_min = slist_serv_max - SERV_L;
	slist_desc_max = (size = strlen(slist_desc)) > DESC_L ? size : DESC_L;
	slist_desc_min = slist_desc_max - DESC_L;
}

void M_SEdit_Draw (void)
{

    if (key_dest != key_menu_pause)
		Draw_Pic (0, 0, menu_bk);
	//else
		//Draw_AlphaPic (0, 0, pause_bk, 0.4);

	M_DrawTextBox (SERV_X, SERV_Y, 23, 1);
	M_DrawTextBox (DESC_X, DESC_Y, 23, 1);
	M_PrintWhiteOld (SERV_X, SERV_Y - 4, "Hostname/IP:");
	M_PrintWhiteOld (DESC_X, DESC_Y - 4, "Description:");
	M_PrintOld (SERV_X + 9, SERV_Y + 8, va("%1.23s", slist_serv + slist_serv_min));
	M_PrintOld (DESC_X + 9, DESC_Y + 8, va("%1.23s", slist_desc + slist_desc_min));
	if (sedit_state == 0)
		M_DrawCharacter2 (SERV_X + 9 + 8*(strlen(slist_serv) - slist_serv_min), SERV_Y + 8, 10+((int)(realtime*4)&1));
	else
		M_DrawCharacter2 (DESC_X + 9 + 8*(strlen(slist_desc) - slist_desc_min), DESC_Y + 8, 10+((int)(realtime*4)&1));
}

void M_SEdit_Key (int key)
{
	int	l;

	switch (key)
	{
	case K_ESCAPE:
		M_Menu_ServerList_f ();
		break;

	case K_ENTER:
		SList_Set (slist_cursor, slist_serv, slist_desc);
		M_Menu_ServerList_f ();
		break;

	case K_UPARROW:
	case K_DOWNARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		sedit_state = !sedit_state;
		break;

	case K_INS:
        if (sedit_state == 0)
		   M_Menu_OSK_f(slist_serv, slist_serv, 16);
		else
		   M_Menu_OSK_f(slist_desc, slist_desc, 16);
		break;

	case K_BACKSPACE:
		if (sedit_state == 0)
		{
			if ((l = strlen(slist_serv)))
				slist_serv[--l] = 0;
			if (strlen(slist_serv) - 6 < slist_serv_min && slist_serv_min)
			{
				slist_serv_min--;
				slist_serv_max--;
			}
		}
		else
		{
			if ((l = strlen(slist_desc)))
				slist_desc[--l] = 0;
			if (strlen(slist_desc) - 6 < slist_desc_min && slist_desc_min)
			{
				slist_desc_min--;
				slist_desc_max--;
			}
		}
		break;

	default:
		if (key < 32 || key > 127)
			break;

		if (sedit_state == 0)
		{
			l = strlen (slist_serv);
			if (l < SLIST_BUFSIZE - 1)
			{
				slist_serv[l+1] = 0;
				slist_serv[l] = key;
				l++;
			}
			if (l > slist_serv_max)
			{
				slist_serv_min++;
				slist_serv_max++;
			}
		}
		else
		{
			l = strlen (slist_desc);
			if (l < SLIST_BUFSIZE - 1)
			{
				slist_desc[l+1] = 0;
				slist_desc[l] = key;
				l++;
			}
			if (l > slist_desc_max)
			{
				slist_desc_min++;
				slist_desc_max++;
			}
		}
		break;
	}
}

//=============================================================================
/* NET MENU */

int	m_net_cursor;
int m_net_items;
int m_net_saveHeight;

char *net_helpMessage [] =
{
/* .........1.........2.... */
  "                        ",
  " Two computers connected",
  "   through two modems.  ",
  "                        ",

  "                        ",
  " Two computers connected",
  " by a null-modem cable. ",
  "                        ",

  " Novell network LANs    ",
  " or Windows 95 DOS-box. ",
  "                        ",
  "(LAN=Local Area Network)",

  " Commonly used to play  ",
  " over the Internet, but ",
  " also used on a Local   ",
  " Area Network.          "
};

void M_Menu_Net_f (void)
{
	key_dest = key_menu;
	m_state = m_net;
	m_entersound = true;
	m_net_items = 4;

	if (m_net_cursor >= m_net_items)
		m_net_cursor = 0;
	m_net_cursor--;
	M_Net_Key (K_DOWNARROW);
}


void M_Net_Draw (void)
{
	int		f;

    if (key_dest != key_menu_pause)
		Draw_Pic (0, 0, menu_bk);
	//else
		//Draw_AlphaPic (0, 0, pause_bk, 0.4);

	f = 32;
	qpic_t *p;

	if (serialAvailable)
	{
		p = Draw_CachePic ("gfx/netmen1.lmp");
	}
	else
	{
		p = Draw_CachePic ("gfx/dim_modm.lmp");
	}

	if (p)
		M_DrawTransPic (72, f, p);

	f += 19;

	if (serialAvailable)
	{
		p = Draw_CachePic ("gfx/netmen2.lmp");
	}
	else
	{
		p = Draw_CachePic ("gfx/dim_drct.lmp");
	}

	if (p)
		M_DrawTransPic (72, f, p);

	f += 19;
	if (ipxAvailable)
		p = Draw_CachePic ("gfx/netmen3.lmp");
	else
		p = Draw_CachePic ("gfx/dim_ipx.lmp");
	M_DrawTransPic (72, f, p);

	f += 19;
	if (tcpipAvailable)
		p = Draw_CachePic ("gfx/netmen4.lmp");
	else
		p = Draw_CachePic ("gfx/dim_tcp.lmp");
	M_DrawTransPic (72, f, p);

	if (m_net_items == 5)	// JDC, could just be removed
	{
		f += 19;
		p = Draw_CachePic ("gfx/netmen5.lmp");
		M_DrawTransPic (72, f, p);
	}

	f = (320-26*8)/2;
	M_DrawTextBox (f, 134, 24, 4);
	f += 8;
	M_PrintOld (f, 142, net_helpMessage[m_net_cursor*4+0]);
	M_PrintOld (f, 150, net_helpMessage[m_net_cursor*4+1]);
	M_PrintOld (f, 158, net_helpMessage[m_net_cursor*4+2]);
	M_PrintOld (f, 166, net_helpMessage[m_net_cursor*4+3]);

	f = (int)(host_time * 10)%6;
	M_DrawTransPic (54, 32 + m_net_cursor * 20,Draw_CachePic( va("gfx/menudot%i.lmp", f+1 ) ) );
}


void M_Net_Key (int k)
{
again:
	switch (k)
	{
	case K_ESCAPE:
		M_Menu_MultiPlayer_f ();
		break;

	case K_DOWNARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		if (++m_net_cursor >= m_net_items)
			m_net_cursor = 0;
		break;

	case K_UPARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		if (--m_net_cursor < 0)
			m_net_cursor = m_net_items - 1;
		break;

	case K_ENTER:
		m_entersound = true;

		switch (m_net_cursor)
		{
		case 0:
			M_Menu_SerialConfig_f ();
			break;

		case 1:
			M_Menu_SerialConfig_f ();
			break;

		case 2:
			M_Menu_LanConfig_f ();
			break;

		case 3:
			M_Menu_LanConfig_f ();
			break;

		case 4:
// multiprotocol
			break;
		}
	}

	if (m_net_cursor == 0 && !serialAvailable)
		goto again;
	if (m_net_cursor == 1 && !serialAvailable)
		goto again;
	if (m_net_cursor == 2 && !ipxAvailable)
		goto again;
	if (m_net_cursor == 3 && !tcpipAvailable)
		goto again;
}

//=============================================================================
/* OPTIONS MENU */
#define	SLIDER_RANGE	10


enum //video menu
{
	OPT_SHOWFPS,
	OPT_MAXFPS,
	OPT_FOV,
	OPT_GAMMA,
	OPT_DECALS,
	OPT_PARTICLES,
	OPT_FULLBRIGHT,
	OPT_DITHERING,
	OPT_RETRO,
	VID_ITEMS
};

enum //audio menu
{
	OPT_MUSICVOL,
	OPT_SNDVOL,
    OPT_MUSICTYPE,
	AUDIO_ITEMS
};

enum //gameplay menu
{
    OPT_CROSSHAIR,
    OPT_AIMASSIST,
    OPT_IN_SPEED,
    OPT_IN_ACCELERATION,    
    OPT_INVMOUSE,
	OPT_IN_TOLERANCE,
    OPT_MOUSELOOK,
    GAMEPLAY_ITEMS
};



extern cvar_t show_fps;
extern cvar_t show_bat;

void M_AdjustSliders (int dir, int m_submenu, int options_cursor)
{
	S_LocalSound ("sounds/menu/navigate.wav");


    if (m_submenu == 0)
    {
    	switch (options_cursor)
        {
			case OPT_GAMMA:	// gamma
				v_gamma.value -= dir * 0.05;
				if (v_gamma.value < 0.5)
					v_gamma.value = 0.5;
				if (v_gamma.value > 1)
					v_gamma.value = 1;
				Cvar_SetValue ("gamma", v_gamma.value);
				break;
			case OPT_MAXFPS:
				cl_maxfps.value = cl_maxfps.value + dir * 5;
				if (cl_maxfps.value < 30)
					cl_maxfps.value = 30;
				if (cl_maxfps.value > 65)
					cl_maxfps.value = 65;
				Cvar_SetValue ("cl_maxfps", cl_maxfps.value);
				break;
			case OPT_FOV:
				scr_fov.value += dir * 5;
				if (scr_fov.value < 50)
					scr_fov.value = 50;
				if (scr_fov.value > 120 && dir > 0)
					scr_fov.value = 120;
				Cvar_SetValue ("scr_fov", scr_fov.value);
				break;
			case OPT_DECALS:
				Cvar_SetValue ("nzp_decals", !nzp_decals.value);
				break;
			case OPT_PARTICLES:
				Cvar_SetValue ("nzp_particles", !nzp_decals.value);
				break;
			case OPT_FULLBRIGHT:
				Cvar_SetValue ("r_fullbright", !nzp_decals.value);
				break;
			case OPT_DITHERING:
				Cvar_SetValue ("r_dithering", !r_dithering.value);
				break;
			case OPT_RETRO:
				Cvar_SetValue ("r_retro", !r_retro.value);
				break;
			case OPT_SHOWFPS:
				Cvar_SetValue ("show_fps", !show_fps.value);
				break;
        }
    }
    else if (m_submenu == 1)
    {
       	switch (options_cursor)
        {
			case OPT_MUSICVOL:	// music volume
				bgmvolume.value += dir * 0.1;
				if (bgmvolume.value < 0)
					bgmvolume.value = 0;
				if (bgmvolume.value > 1)
					bgmvolume.value = 1;
				Cvar_SetValue ("bgmvolume", bgmvolume.value);
				break;
			case OPT_SNDVOL:	// sfx volume
				volume.value += dir * 0.1;
				if (volume.value < 0)
					volume.value = 0;
				if (volume.value > 1)
					volume.value = 1;
				Cvar_SetValue ("volume", volume.value);
				break;
			case OPT_MUSICTYPE: // bgm type
				if (strcmp(bgmtype.string,"cd") == 0)
				{
						Cvar_Set("bgmtype","none");
						bmg_type_changed = true;
				}
				else
				{
						Cvar_Set("bgmtype","cd");
						bmg_type_changed = true;
				}
				break;
        }
    }
    else if (m_submenu == 2)
    {
       	switch (options_cursor)
        {
		case OPT_CROSSHAIR:
				Cvar_SetValue ("crosshair", !crosshair.value);
				break;
		case OPT_AIMASSIST:
				Cvar_SetValue ("in_aimassist", !in_aimassist.value);
				break;

       		case OPT_IN_SPEED:	// mouse speed
				in_sensitivity.value += dir * 0.5;
				if (in_sensitivity.value < 1)
					in_sensitivity.value = 1;
				if (in_sensitivity.value > 11)
					in_sensitivity.value = 11;
				Cvar_SetValue ("sensitivity", in_sensitivity.value);
				break;

       		case OPT_IN_ACCELERATION:	// mouse tolerance
				in_acceleration.value -= dir * 0.25;
				if (in_acceleration.value < 0.5)
					in_acceleration.value = 0.5;
				if (in_acceleration.value > 2)
					in_acceleration.value = 2;
				Cvar_SetValue ("acceleration", in_acceleration.value);
				break;

       		case OPT_IN_TOLERANCE:	// mouse tolerance
				in_tolerance.value += dir * 0.05;
				if (in_tolerance.value < 0)
					in_tolerance.value = 0;
				if (in_tolerance.value > 1)
					in_tolerance.value = 1;
				Cvar_SetValue ("tolerance", in_tolerance.value);
				break;
			case OPT_INVMOUSE:	// invert mouse
				Cvar_SetValue ("m_pitch", -m_pitch.value);
				break;
			case OPT_MOUSELOOK:
				Cvar_SetValue ("in_mlook", !in_mlook.value);
				Cvar_SetValue ("in_analog_strafe", !in_analog_strafe.value);
				break;
        }
    }
}

void M_DrawSlider (int x, int y, float range)
{
	int	i;

	if (range < 0)
		range = 0;
	if (range > 1)
		range = 1;
	Draw_Character (x-8, y, 128);
	for (i=0 ; i<SLIDER_RANGE ; i++)
		Draw_Character (x + i*8, y, 129);
	Draw_Character (x+i*8, y, 130);
	Draw_Character (x + (SLIDER_RANGE-1)*8 * range, y, 131);
}



int	video_cursor;
//=============================================================================
/* Screen Setting menu */
void M_Menu_Screen_f (void)
{
	m_state = m_video;
	m_entersound = true;
	video_cursor = 0;
}

void M_Screen_Draw (void)
{
	float 	  r;

	// Background
	if (key_dest != key_menu_pause)
		Draw_Pic (0, 0, menu_bk);

	// Fill black to make everything easier to see
	Draw_FillByColor(0, 0, 480, 272, GU_RGBA(0, 0, 0, 102));

	// Version String
	Draw_ColoredString(vid.width - 40, 5, "v1.0", 255, 255, 255, 255, 1);

	// Header
	Draw_ColoredString(10, 10, "GRAPHICS SETTINGS", 255, 255, 255, 255, 2);

	// Show FPS
	if (video_cursor == 0)
		Draw_ColoredString(10, 45, "Show FPS", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 45, "Show FPS", 255, 255, 255, 255, 1);
	M_DrawCheckbox(225, 45, show_fps.value);
	
	// Max FPS
	if (video_cursor == 1)
		Draw_ColoredString(10, 55, "Max FPS", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 55, "Max FPS", 255, 255, 255, 255, 1);
	r = (cl_maxfps.value - 30.0)*(1.0/35.0);
	M_DrawSlider (225, 55, r);

	// FOV
	if (video_cursor == 2)
		Draw_ColoredString(10, 65, "Field of View", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 65, "Field of View", 255, 255, 255, 255, 1);
	r = (scr_fov.value - 50.0)*(1.0/70.0);
	M_DrawSlider (225, 65, r);

	// Brightness
	if (video_cursor == 3)
		Draw_ColoredString(10, 75, "Brightness", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 75, "Brightness", 255, 255, 255, 255, 1);
	r = (1.0 - v_gamma.value) / 0.5;
	M_DrawSlider (225, 75, r);

	// Decals
	if (video_cursor == 4)
		Draw_ColoredString(10, 85, "Decals", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 85, "Decals", 255, 255, 255, 255, 1);
	M_DrawCheckbox(225, 85, nzp_decals.value);

	// Particles
	if (video_cursor == 5)
		Draw_ColoredString(10, 95, "Particles", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 95, "Particles", 255, 255, 255, 255, 1);
	M_DrawCheckbox(225, 95, nzp_particles.value);

	// Fullbright
	if (video_cursor == 6)
		Draw_ColoredString(10, 105, "Fullbright", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 105, "Fullbright", 255, 255, 255, 255, 1);
	M_DrawCheckbox(225, 105, r_fullbright.value);

	// Dithering
	if (video_cursor == 7)
		Draw_ColoredString(10, 115, "Dithering", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 115, "Dithering", 255, 255, 255, 255, 1);
	M_DrawCheckbox(225, 115, r_dithering.value);

	// Retro
	if (video_cursor == 8)
		Draw_ColoredString(10, 125, "Retro", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 125, "Retro", 255, 255, 255, 255, 1);
	M_DrawCheckbox(225, 125, r_retro.value);

	// Back
	if (video_cursor == 9)
		Draw_ColoredString(10, 250, "Back", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 250, "Back", 255, 255, 255, 255, 1);

	// Descriptions
	switch(video_cursor) {
		case 0: // Show FPS
			Draw_ColoredString(10, 230, "Toggle Framerate Overlay.", 255, 255, 255, 255, 1);
			break;
		case 1: // Max FPS
			Draw_ColoredString(10, 230, "Increase of Decrease Max Frames per Second.", 255, 255, 255, 255, 1);
			break;
		case 2: // FOV
			Draw_ColoredString(10, 230, "Adjust Game Field of View.", 255, 255, 255, 255, 1);
			break;
		case 3: // Brightness
			Draw_ColoredString(10, 230, "Increase or Decrease Game Brightness.", 255, 255, 255, 255, 1);
			break;
		case 4: // Decals
			Draw_ColoredString(10, 230, "Toggle Bullet and Explosive Decals.", 255, 255, 255, 255, 1);
			break;
		case 5: // Particles
			Draw_ColoredString(10, 230, "Toggle Appearence of (most) Particles.", 255, 255, 255, 255, 1);
			break;
		case 6: // Fullbright
			Draw_ColoredString(10, 230, "Toggle all non-realtime lights (Requires Map Restart).", 255, 255, 255, 255, 1);
			break;
		case 7: // Dithering
			Draw_ColoredString(10, 230, "Toggle decrease in Color Banding.", 255, 255, 255, 255, 1);
			break;
		case 8: // Retro
			Draw_ColoredString(10, 230, "Toggle texture filtering.", 255, 255, 255, 255, 1);
			break;
	}
}


void M_Screen_Key (int key)
{
	switch (key)
	{
		case K_ESCAPE:
			if (key_dest == key_menu_pause)
			{
				M_Menu_Options_f ();
				key_dest = key_menu_pause;
			}
			else
				M_Menu_Options_f ();
			break;

		case K_ENTER:
			m_entersound = true;
			switch (video_cursor)
			{
				case VID_ITEMS:
					if (key_dest == key_menu_pause)
					{
						M_Menu_Options_f ();
						key_dest = key_menu_pause;
					}
					else
						M_Menu_Options_f ();
					break;

				default:
					M_AdjustSliders (1, 0, video_cursor);
					break;
			}
			return;

		case K_UPARROW:
			S_LocalSound ("sounds/menu/navigate.wav");
			video_cursor--;
			if (video_cursor < 0)
				video_cursor = VID_ITEMS;
			break;

		case K_DOWNARROW:
			S_LocalSound ("sounds/menu/navigate.wav");
			video_cursor++;
			if (video_cursor >= VID_ITEMS+1)
				video_cursor = 0;
			break;

		case K_LEFTARROW:
			M_AdjustSliders (-1, 0, video_cursor);
			break;

		case K_RIGHTARROW:
			M_AdjustSliders (1, 0, video_cursor);
			break;
	}
}



//=============================================================================
/* Audio Setting menu */

int	audio_cursor;
void M_Menu_Audio_f (void)
{
	m_state = m_audio;
	m_entersound = true;
	audio_cursor = 0;
}


void M_Audio_Draw (void)
{
	float	 r;

	if (key_dest != key_menu_pause)
		Draw_Pic (0, 0, menu_bk);
	//else
		//Draw_AlphaPic (0, 0, pause_bk, 0.4);


    Draw_String (352, 30, 	   "Sound Settings");

	if (audio_cursor == OPT_MUSICVOL)
      M_Print (172, 50+(OPT_MUSICVOL*8), "       CD Music Volume");
    else
      Draw_String (172, 50+(OPT_MUSICVOL*8), "       CD Music Volume");
	r = bgmvolume.value;
	M_DrawSlider (376, 50+(OPT_MUSICVOL*8), r);

	if (audio_cursor == OPT_SNDVOL)
      M_Print (172, 50+(OPT_SNDVOL*8),   "          Sound Volume");
    else
      Draw_String (172, 50+(OPT_SNDVOL*8),   "          Sound Volume");
	r = volume.value;
	M_DrawSlider (376, 50+(OPT_SNDVOL*8), r);

	if (audio_cursor == OPT_MUSICTYPE)
      M_Print (172, 50+(OPT_MUSICTYPE*8),"            Music Type");
    else
      Draw_String (172, 50+(OPT_MUSICTYPE*8),"            Music Type");
	if (strcmp(bgmtype.string,"cd") == 0)
		Draw_String (424, 50+(OPT_MUSICTYPE*8), "CD/MP3");
	else
		Draw_String (432, 50+(OPT_MUSICTYPE*8), "None");

	if (audio_cursor == AUDIO_ITEMS)
       M_Print (432, 58+(AUDIO_ITEMS*8),      "Back");
    else
       Draw_String (432, 58+(AUDIO_ITEMS*8),      "Back");
}


void M_Audio_Key (int key)
{
	switch (key)
	{
	case K_ESCAPE:
		if (key_dest == key_menu_pause)
        {
            M_Menu_Options_f ();
            key_dest = key_menu_pause;
        }
        else
            M_Menu_Options_f ();
		break;

	case K_ENTER:
		m_entersound = true;
		switch (audio_cursor)
		{
            case AUDIO_ITEMS:
                if (key_dest == key_menu_pause)
                {
                    M_Menu_Options_f ();
                    key_dest = key_menu_pause;
                }
                else
                    M_Menu_Options_f ();
                break;

			default:
				M_AdjustSliders (1, 1, audio_cursor);
				break;
		}
		return;

	case K_UPARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		audio_cursor--;
		if (audio_cursor < 0)
			audio_cursor = AUDIO_ITEMS;
		break;

	case K_DOWNARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		audio_cursor++;
        if (audio_cursor >= AUDIO_ITEMS+1)
			audio_cursor = 0;
		break;

	case K_LEFTARROW:
		M_AdjustSliders (-1, 1, audio_cursor);
		break;

	case K_RIGHTARROW:
		M_AdjustSliders (1, 1, audio_cursor);
		break;
	}
}

//=============================================================================
/* Gameplay Setting menu */

int	gameplay_cursor;
void M_Menu_Gameplay_f (void)
{
	m_state = m_gameplay;
	m_entersound = true;
	gameplay_cursor = 0;
}

/*
	float 	  r;

	// Background
	if (key_dest != key_menu_pause)
		Draw_Pic (0, 0, menu_bk);

	// Fill black to make everything easier to see
	Draw_FillByColor(0, 0, 480, 272, GU_RGBA(0, 0, 0, 102));

	// Version String
	Draw_ColoredString(vid.width - 40, 5, "v1.0", 255, 255, 255, 255, 1);

	// Header
	Draw_ColoredString(10, 10, "GRAPHICS SETTINGS", 255, 255, 255, 255, 2);

	// Show FPS
	if (video_cursor == 0)
		Draw_ColoredString(10, 45, "Show FPS", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 45, "Show FPS", 255, 255, 255, 255, 1);
	M_DrawCheckbox(225, 45, show_fps.value);
	
	// Max FPS
	if (video_cursor == 1)
		Draw_ColoredString(10, 55, "Max FPS", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 55, "Max FPS", 255, 255, 255, 255, 1);
	r = (cl_maxfps.value - 30.0)*(1.0/35.0);
	M_DrawSlider (225, 55, r);

	// FOV
	if (video_cursor == 2)
		Draw_ColoredString(10, 65, "Field of View", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 65, "Field of View", 255, 255, 255, 255, 1);
	r = (scr_fov.value - 50.0)*(1.0/70.0);
	M_DrawSlider (225, 65, r);

	// Brightness
	if (video_cursor == 3)
		Draw_ColoredString(10, 75, "Brightness", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 75, "Brightness", 255, 255, 255, 255, 1);
	r = (1.0 - v_gamma.value) / 0.5;
	M_DrawSlider (225, 75, r);

	// Decals
	if (video_cursor == 4)
		Draw_ColoredString(10, 85, "Decals", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 85, "Decals", 255, 255, 255, 255, 1);
	M_DrawCheckbox(225, 85, nzp_decals.value);

	// Particles
	if (video_cursor == 5)
		Draw_ColoredString(10, 95, "Particles", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 95, "Particles", 255, 255, 255, 255, 1);
	M_DrawCheckbox(225, 95, nzp_particles.value);

	// Fullbright
	if (video_cursor == 6)
		Draw_ColoredString(10, 105, "Fullbright", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 105, "Fullbright", 255, 255, 255, 255, 1);
	M_DrawCheckbox(225, 105, r_fullbright.value);

	// Dithering
	if (video_cursor == 7)
		Draw_ColoredString(10, 115, "Dithering", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 115, "Dithering", 255, 255, 255, 255, 1);
	M_DrawCheckbox(225, 115, r_dithering.value);

	// Retro
	if (video_cursor == 8)
		Draw_ColoredString(10, 125, "Retro", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 125, "Retro", 255, 255, 255, 255, 1);
	M_DrawCheckbox(225, 125, r_retro.value);

	// Back
	if (video_cursor == 9)
		Draw_ColoredString(10, 250, "Back", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 250, "Back", 255, 255, 255, 255, 1);

	// Descriptions
	switch(video_cursor) {
		case 0: // Show FPS
			Draw_ColoredString(10, 230, "Toggle Framerate Overlay.", 255, 255, 255, 255, 1);
			break;
		case 1: // Max FPS
			Draw_ColoredString(10, 230, "Increase of Decrease Max Frames per Second.", 255, 255, 255, 255, 1);
			break;
		case 2: // FOV
			Draw_ColoredString(10, 230, "Adjust Game Field of View.", 255, 255, 255, 255, 1);
			break;
		case 3: // Brightness
			Draw_ColoredString(10, 230, "Increase or Decrease Game Brightness.", 255, 255, 255, 255, 1);
			break;
		case 4: // Decals
			Draw_ColoredString(10, 230, "Toggle Bullet and Explosive Decals.", 255, 255, 255, 255, 1);
			break;
		case 5: // Particles
			Draw_ColoredString(10, 230, "Toggle Appearence of (most) Particles.", 255, 255, 255, 255, 1);
			break;
		case 6: // Fullbright
			Draw_ColoredString(10, 230, "Toggle all non-realtime lights (Requires Map Restart).", 255, 255, 255, 255, 1);
			break;
		case 7: // Dithering
			Draw_ColoredString(10, 230, "Toggle decrease in Color Banding.", 255, 255, 255, 255, 1);
			break;
		case 8: // Retro
			Draw_ColoredString(10, 230, "Toggle texture filtering.", 255, 255, 255, 255, 1);
			break;
	}
	*/


void M_Gameplay_Draw (void)
{
	float r;

	// Background
	if (key_dest != key_menu_pause)
		Draw_Pic (0, 0, menu_bk);

	// Fill black to make everything easier to see
	Draw_FillByColor(0, 0, 480, 272, GU_RGBA(0, 0, 0, 102));

	// Version String
	Draw_ColoredString(vid.width - 40, 5, "v1.0", 255, 255, 255, 255, 1);

	// Header
	Draw_ColoredString(10, 10, "CONTROL SETTINGS", 255, 255, 255, 255, 2);

	// Draw Crosshair
	if (gameplay_cursor == OPT_CROSSHAIR) {
		Draw_ColoredString(10, 45, "Draw Crosshair", 255, 0, 0, 255, 1);
	} else {
		Draw_ColoredString(10, 45, "Draw Crosshair", 255, 255, 255, 255, 1);
	}
	M_DrawCheckbox(225, 45, crosshair.value);

	// Aim Assist
	if (gameplay_cursor == OPT_AIMASSIST) {
		Draw_ColoredString(10, 55, "Aim Assist", 255, 0, 0, 255, 1);
	} else {
		Draw_ColoredString(10, 55, "Aim Assist", 255, 255, 255, 255, 1);
	}
	M_DrawCheckbox(225, 55, in_aimassist.value);

	// Look Sensitivity
	if (gameplay_cursor == OPT_IN_SPEED) {
		Draw_ColoredString(10, 65, "Look Sensitivity", 255, 0, 0, 255, 1);
	} else {
		Draw_ColoredString(10, 65, "Look Sensitivity", 255, 255, 255, 255, 1);
	}
	r = (in_sensitivity.value - 1)/10;
	M_DrawSlider (225, 65, r);

	// Look Acceleration
	if (gameplay_cursor == OPT_IN_ACCELERATION) {
		Draw_ColoredString(10, 75, "Look Acceleration", 255, 0, 0, 255, 1);
	} else {
		Draw_ColoredString(10, 75, "Look Acceleration", 255, 255, 255, 255, 1);
	}
	r = 1.0f -((in_acceleration.value - 0.5f)/1.5f);
	M_DrawSlider (225, 75, r);

	// Look Inversion
	if (gameplay_cursor == OPT_INVMOUSE) {
		Draw_ColoredString(10, 85, "Look Inversion", 255, 0, 0, 255, 1);
	} else {
		Draw_ColoredString(10, 85, "Look Inversion", 255, 255, 255, 255, 1);
	}
	M_DrawCheckbox(225, 85, m_pitch.value < 0);

	// A-Nub Deadzone
	if (gameplay_cursor == OPT_IN_TOLERANCE) {
		Draw_ColoredString(10, 95, "A-Nub Tolerance", 255, 0, 0, 255, 1);
	} else {
		Draw_ColoredString(10, 95, "A-Nub Tolerance", 255, 255, 255, 255, 1);
	}
	r = (in_tolerance.value )/1.0f;
	M_DrawSlider (225, 95, r);

	// A-Nub Mode
	if (gameplay_cursor == OPT_MOUSELOOK) {
		Draw_ColoredString(10, 105, "A-Nub Mode", 255, 0, 0, 255, 1);
	} else {
		Draw_ColoredString(10, 105, "A-Nub Mode", 255, 255, 255, 255, 1);
	}
	if (in_mlook.value) {
		Draw_ColoredString(225, 105, "Look", 255, 255, 255, 255, 1);
	} else {
		Draw_ColoredString(225, 105, "Move (Buggy!)", 255, 255, 255, 255, 1);
	}

	// Back
	if (gameplay_cursor == GAMEPLAY_ITEMS) {
		Draw_ColoredString(10, 250, "Back", 255, 0, 0, 255, 1);
	} else {
		Draw_ColoredString(10, 250, "Back", 255, 255, 255, 255, 1);
	}

	// Descriptions
	switch(gameplay_cursor) {
		case OPT_CROSSHAIR:
			Draw_ColoredString(10, 230, "Toggle Crosshair in-game.", 255, 255, 255, 255, 1);
			break;
		case OPT_AIMASSIST:
			Draw_ColoredString(10, 230, "Toggle Assisted Aim to improve Targeting.", 255, 255, 255, 255, 1);
			break;	
		case OPT_IN_SPEED:
			Draw_ColoredString(10, 230, "Adjust Look Sensitivity.", 255, 255, 255, 255, 1);
			break;
		case OPT_IN_ACCELERATION:
			Draw_ColoredString(10, 230, "Adjust Acceleration when A-Nub Mode is set to 'Look'.", 255, 255, 255, 255, 1);
			break;
		case OPT_INVMOUSE:
			Draw_ColoredString(10, 230, "Invert A-Nub Look.", 255, 255, 255, 255, 1);
			break;
		case OPT_IN_TOLERANCE:
			Draw_ColoredString(10, 230, "Adjust how Tolerant the A-Nub is to change.", 255, 255, 255, 255, 1);
			break;
		case OPT_MOUSELOOK:
			Draw_ColoredString(10, 230, "Toggle whether to use the A-Nub for Look or Movement.", 255, 255, 255, 255, 1);
			break;
	}

}


void M_Gameplay_Key (int key)
{
	switch (key)
	{
	case K_ESCAPE:
		if (key_dest == key_menu_pause)
        {
            M_Menu_Options_f ();
            key_dest = key_menu_pause;
        }
        else
            M_Menu_Options_f ();
		break;

	case K_ENTER:
		m_entersound = true;
		switch (gameplay_cursor)
		{
            case GAMEPLAY_ITEMS:
                if (key_dest == key_menu_pause)
                {
                    M_Menu_Options_f ();
                    key_dest = key_menu_pause;
                }
                else
                    M_Menu_Options_f ();
                break;
			default:
				M_AdjustSliders (1, 2, gameplay_cursor);
				break;
		}
		return;

	case K_UPARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		gameplay_cursor--;
		if (gameplay_cursor < 0)
			gameplay_cursor = GAMEPLAY_ITEMS;
		break;

	case K_DOWNARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		gameplay_cursor++;
        if (gameplay_cursor >= GAMEPLAY_ITEMS+1)
			gameplay_cursor = 0;
		break;

	case K_LEFTARROW:
		M_AdjustSliders (-1, 2, gameplay_cursor);
		break;

	case K_RIGHTARROW:
		M_AdjustSliders (1, 2, gameplay_cursor);
		break;
	}
}

int options_cursor;
#define OPTIONS_ITEMS 5

void M_Menu_Options_f (void)
{
	key_dest = key_menu;
	m_state = m_options;
	m_entersound = true;
}

void M_Options_Draw (void)
{
	// Background
	if (key_dest != key_menu_pause)
		Draw_Pic (0, 0, menu_bk);

	// Fill black to make everything easier to see
	Draw_FillByColor(0, 0, 480, 272, GU_RGBA(0, 0, 0, 102));

	// Version String
	Draw_ColoredString(vid.width - 40, 5, "v1.0", 255, 255, 255, 255, 1);

	// Header
	Draw_ColoredString(10, 10, "SETTINGS", 255, 255, 255, 255, 2);

	// Graphics Settings
	if (options_cursor == 0)
		Draw_ColoredString(10, 45, "Graphics Settings", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 45, "Graphics Settings", 255, 255, 255, 255, 1);

	// Controls
	if (options_cursor == 1)
		Draw_ColoredString(10, 55, "Controls", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 55, "Controls", 255, 255, 255, 255, 1);

	// Control Settings
	if (options_cursor == 2)
		Draw_ColoredString(10, 65, "Control Settings", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 65, "Control Settings", 255, 255, 255, 255, 1);

	// Divider
	Draw_FillByColor(10, 78, 160, 2, GU_RGBA(130, 130, 130, 255));

	// Console
	if (options_cursor == 3)
		Draw_ColoredString(10, 85, "Console", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 85, "Console", 255, 255, 255, 255, 1);

	// Back
	if (options_cursor == 4)
		Draw_ColoredString(10, 250, "Back", 255, 0, 0, 255, 1);
	else
		Draw_ColoredString(10, 250, "Back", 255, 255, 255, 255, 1);

	// Descriptions
	switch(options_cursor) {
		case 0: // Graphics Settings
			Draw_ColoredString(10, 230, "Adjust settings relating to Graphical Fidelity.", 255, 255, 255, 255, 1);
			break;
		case 1: // Controls
			Draw_ColoredString(10, 230, "Customize your Control Scheme.", 255, 255, 255, 255, 1);
			break;
		case 2: // Control Settings
			Draw_ColoredString(10, 230, "Adjust settings in relation to how NZ:P Controls.", 255, 255, 255, 255, 1);
			break;
		case 3: // Console
			Draw_ColoredString(10, 230, "Open the Console to input Commands.", 255, 255, 255, 255, 1);
			break;
	}
}


extern qboolean console_enabled;
void M_Options_Key (int k)
{
	switch (k)
	{
	case K_ESCAPE:
		if (key_dest == key_menu_pause)
			M_Paused_Menu_f();
		else
			M_Menu_Main_f ();
		break;

	case K_ENTER:
		m_entersound = true;
		switch (options_cursor)
		{
			case 0:
				M_Menu_Screen_f();
				break;
			case 1:
				M_Menu_Keys_f();
				break;
			case 2:
                M_Menu_Gameplay_f ();
                break;
			case 3:
				m_state = m_none;
                console_enabled = true;
                Con_ToggleConsole_f ();
				break;
			case 4:
				if (key_dest == key_menu_pause)
                    M_Paused_Menu_f();
                else
                    M_Menu_Main_f ();
                break;
            /*case 0:
                M_Menu_Keys_f();
                break;

            case 1:
                M_Menu_Screen_f ();
                break;

            case 2:
                M_Menu_Audio_f ();
                break;

            case 3:
                M_Menu_Gameplay_f ();
                break;

            case 4:
                m_state = m_none;
                console_enabled = true;
                Con_ToggleConsole_f ();
                break;

            case 5:
                if (key_dest == key_menu_pause)
                    M_Paused_Menu_f();
                else
                    M_Menu_Main_f ();
                break;*/
		}
		return;

	case K_UPARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		options_cursor--;
		if (options_cursor < 0) {
			options_cursor = OPTIONS_ITEMS-1;
		}
		break;

	case K_DOWNARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		options_cursor++;
        if (options_cursor >= OPTIONS_ITEMS)
            options_cursor = 0;
		break;
	}
}

//=============================================================================
/* KEYS MENU */

char *bindnames[][2] =
{
	{"+forward", 		"Walk Forward"},
	{"+back", 			"Walk Backward"},
	{"+moveleft", 		"Move Left"},
	{"+moveright", 		"Move Right"},
	{"+lookup", 		"Look Up"},
	{"+lookdown", 		"Look Down"},
	{"+left", 			"Look Left"},
	{"+right", 			"Look Right"},
	{"+jump",			"Jump"},
	{"+attack",			"Fire"},
	{"+aim", 			"Aim Down Sight"},
	{"+switch", 		"Switch Weapon"},
	{"+use", 			"Interact"},
	{"+reload", 		"Reload"},
	{"+knife", 			"Melee"},
	{"+grenade", 		"Grenade"}
};

#define	NUMCOMMANDS	(sizeof(bindnames)/sizeof(bindnames[0]))

int		keys_cursor;
int		bind_grab;

void M_Menu_Keys_f (void)
{
	m_state = m_keys;
	m_entersound = true;
}


void M_FindKeysForCommand (char *command, int *twokeys)
{
	int		count;
	int		j;
	int		l;
	char	*b;

	twokeys[0] = twokeys[1] = -1;
	l = strlen(command);
	count = 0;

	for (j=0 ; j<256 ; j++)
	{
		b = keybindings[j];
		if (!b)
			continue;
		if (!strncmp (b, command, l) )
		{
			twokeys[count] = j;
			count++;
			if (count == 2)
				break;
		}
	}
}

void M_UnbindCommand (char *command)
{
	int		j;
	int		l;
	char	*b;

	l = strlen(command);

	for (j=0 ; j<256 ; j++)
	{
		b = keybindings[j];
		if (!b)
			continue;
		if (!strncmp (b, command, l) )
			Key_SetBinding (j, "");
	}
}


void M_Keys_Draw (void)
{
	int		i, j;
	int		y;
	char    *b;

	// Background
	if (key_dest != key_menu_pause)
		Draw_Pic(0, 0, menu_bk);

	// Fill black to make everything easier to see
	Draw_FillByColor(0, 0, 480, 272, GU_RGBA(0, 0, 0, 102));

	// Version String
	Draw_ColoredString(vid.width - 40, 5, "v1.0", 255, 255, 255, 255, 1);

	// Header
	Draw_ColoredString(10, 10, "CONTROLS", 255, 255, 255, 255, 2);

	if (bind_grab)
    {
		Draw_ColoredString(70, 230, "Press a button for this action,    to cancel", 255, 255, 255, 255, 1);
		Draw_Pic (268, 230, b_start);
    }
	else
    {
		Draw_ColoredString(48 + ((vid.width - 320)>>1), 230, "Press   to change,   to clear", 255, 255, 255, 255, 1);
		Draw_Pic (96 + ((vid.width - 320)>>1), 230, b_cross);
		Draw_Pic (200 + ((vid.width - 320)>>1), 230, b_square);
    }

	// search for known bindings
	for (i = 0; i < NUMCOMMANDS; i++)
	{
		y = 45 + 10 * i;

		if (i == keys_cursor)
			Draw_ColoredString(10, y, bindnames[i][1], 255, 0, 0, 255, 1);
		else
			Draw_ColoredString(10, y, bindnames[i][1], 255, 255, 255, 255, 1);

		for (j = 0; j < 256; j++)
		{
			b = keybindings[j];

			if (!b) {
				continue;
			}	
				
			if (!strcmp (b, bindnames[i][0]))
			{
                Draw_Pic (140 + ((vid.width - 320)>>1), y, GetButtonIcon(bindnames[i][0]));
                break;
			}
		}
	}

	if (keys_cursor == NUMCOMMANDS) {
		Draw_ColoredString(10, 250, "Back", 255, 0, 0, 255, 1);
	} else {
		Draw_ColoredString(10, 250, "Back", 255, 255, 255, 255, 1);
		M_DrawCharacter2 (130, 45 + keys_cursor*10, 12+((int)(realtime*4)&1));
	}
}


void M_Keys_Key (int k)
{
	char	cmd[80];
	int		keys[2];

	if (bind_grab)
	{	// defining a key
		S_LocalSound ("sounds/menu/navigate.wav");
		if (k == K_ESCAPE)
		{
			bind_grab = false;
		}
		else if (k != '`')
		{
			sprintf (cmd, "bind \"%s\" \"%s\"\n", Key_KeynumToString (k), bindnames[keys_cursor][0]);
			Cbuf_InsertText (cmd);
		}

		bind_grab = false;
		return;
	}

	switch (k)
	{
	case K_ESCAPE:
		if (key_dest == key_menu_pause)
		{
			M_Menu_Options_f ();
			key_dest = key_menu_pause;
		}
		else
			M_Menu_Options_f ();
		break;

	case K_LEFTARROW:
	case K_UPARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		keys_cursor--;
		if (keys_cursor < 0)
			keys_cursor = NUMCOMMANDS;
		break;

	case K_DOWNARROW:
	case K_RIGHTARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		keys_cursor++;
		if (keys_cursor >= NUMCOMMANDS + 1)
			keys_cursor = 0;
		break;

	case K_ENTER:
		S_LocalSound ("sounds/menu/enter.wav");
		if (keys_cursor != NUMCOMMANDS) { // go into bind mode
			M_FindKeysForCommand (bindnames[keys_cursor][0], keys);
			if (keys[1] != -1)
				M_UnbindCommand (bindnames[keys_cursor][0]);
			bind_grab = true;
		} else { // return to menu
			if (key_dest == key_menu_pause)
			{
				M_Menu_Options_f ();
				key_dest = key_menu_pause;
			}
			else
				M_Menu_Options_f ();
		}
		break;

	case K_BACKSPACE:		// delete bindings
	case K_DEL:				// delete bindings
		S_LocalSound ("sounds/menu/enter.wav");
		M_UnbindCommand (bindnames[keys_cursor][0]);
		break;
	}
}

//=============================================================================
/* CREDITS MENU */


void M_Menu_Credits_f (void)
{
	key_dest = key_menu;
	m_state = m_credits;
	m_entersound = true;
}



void M_Credits_Draw (void)
{
   	// Background
	Draw_Pic(0, 0, menu_bk);

	// Fill black to make everything easier to see
	Draw_FillByColor(0, 0, 480, 272, GU_RGBA(0, 0, 0, 102));

	// Version String
	Draw_ColoredString(vid.width - 40, 5, "v1.0", 255, 255, 255, 255, 1);

	// Header
	Draw_ColoredString(10, 10, "CREDITS", 255, 255, 255, 255, 2);


	Draw_ColoredString(10, 45, "Blubswillrule:   Coding, Models, GFX, Sounds, Music", 255, 255, 255, 255, 1);
	Draw_ColoredString(10, 55, "Ju[s]tice:       Maps, Models, GFX", 255, 255, 255, 255, 1);
	Draw_ColoredString(10, 65, "Jukki:           Coding", 255, 255, 255, 255, 1);
	Draw_ColoredString(10, 75, "Biodude:         Sounds", 255, 255, 255, 255, 1);
	Draw_ColoredString(10, 85, "Dr_Mabuse1981:   Coding", 255, 255, 255, 255, 1);
	Draw_ColoredString(10, 95, "Naievil:         Coding, NX Maintaining", 255, 255, 255, 255, 1);
	Draw_ColoredString(10, 105, "MotoLegacy:      Coding, GFX, Music", 255, 255, 255, 255, 1);
	Draw_ColoredString(10, 115, "Derped_Crusader: Models, GFX", 255, 255, 255, 255, 1);

	Draw_ColoredString(10, 135, "Special Thanks:", 255, 255, 255, 255, 1);
	Draw_ColoredString(10, 145, "- Spike:     FTEQW", 255, 255, 255, 255, 1);
	Draw_ColoredString(10, 155, "- Shpuld:    Clean-CSQC", 255, 255, 255, 255, 1);
	Draw_ColoredString(10, 165, "- Crow_Bar:  DQuake", 255, 255, 255, 255, 1);
	Draw_ColoredString(10, 175, "- st1x51:    DQuakePlus", 255, 255, 255, 255, 1);
	Draw_ColoredString(10, 185, "- fgsfdsfgs: QuakespasmNX", 255, 255, 255, 255, 1);
	Draw_ColoredString(10, 195, "- Azenn:     GFX help", 255, 255, 255, 255, 1);
	Draw_ColoredString(10, 205, "- tavo:      Music help", 255, 255, 255, 255, 1);
	Draw_ColoredString(10, 215, "- BCDeshiG:  Heavy bug testing", 255, 255, 255, 255, 1);

	Draw_ColoredString(10, 250, "Back", 255, 0, 0, 255, 1);
}


void M_Credits_Key (int key)
{
	switch (key)
	{
		case K_ENTER:
        case K_ESCAPE:
            M_Menu_Main_f ();
            break;
	}
}

//=============================================================================
/* QUIT MENU */

int		msgNumber;
int		m_quit_prevstate;

int	m_quit_cursor;
int m_quit_items;


char *quitMessage [] =
{

  "  Are you gonna quit    ",
  "  this game just like   ",  //msg:0
  "   everything else?     ",
  "                        ",

  " Milord, methinks that  ",
  "   thou art a lowly     ",  //msg:1
  " quitter. Is this true? ",
  "                        ",

  " Do I need to bust your ",
  "  face open for trying  ",  //msg:2
  "        to quit?        ",
  "                        ",

  " Man, I oughta smack you",
  "   for trying to quit!  ",  //msg:3
  "     Press X to get     ",
  "      smacked out.      ",

  " Press X to quit like a ",
  "   big loser in life.   ",  //msg:4
  "  Press O to stay proud ",
  "    and successful!     ",

  "   If you press X to    ",
  "  quit, I will summon   ",  //msg:5
  "  Satan all over your   ",
  "      hard drive!       ",

  "  Um, Asmodeus dislikes ",
  " his children trying to ",  //msg:6
  " quit. Press X to return",
  "   to your Tinkertoys.  ",

  "      Really quit?      ",
  "                        ",  //msg:7
  "  Press X to quit,      ",
  " or O to continue.      ",

  "  If you quit now, I'll ",
  "  throw a blanket-party ",  //msg:8
  "   for you next time!   ",
  "                        ",

  " You are Crazy?         ",
  " Press X for Yes        ",  //msg:9
  " or O for no!           ",
  " Global Random Ha Ha Ha  "
};


void M_Menu_Quit_f (void)
{
	if (m_state == m_quit)
		return;
	wasInMenus = (key_dest == key_menu);
	key_dest = key_menu;
	m_quit_prevstate = m_state;
	m_state = m_quit;
	m_entersound = true;
	msgNumber = rand()&7;
/*
    Con_Printf ("open source\n");

	FILE *fd = fopen("credits.txt","rb");
	FILE *fd1 = fopen("credits.dat","wb");

	fseek (fd, 0, SEEK_END);
	int len = ftell (fd);
	fseek (fd, 0, SEEK_SET);

	char *str = malloc(len);

	fread (str, 1, len, fd);
    Con_Printf ("source: %s\n",str);

	char *out = strencrypt(str, 110901, len);
    Con_Printf ("enc: %s\n", out);
	fwrite(out, len, 1, fd1);

	Con_Printf ("write encrypted\n");

    //char *out2 = strdecrypt(out, 110901, sizeof(strf));
    //Con_Printf ("dec: %s\n", out2);

    free(out);
    //free(out2);
*/
}


void M_Quit_Key (int key)
{
	switch (key)
	{
	case K_ESCAPE:
	case 'n':
	case 'N':
		if (wasInMenus)
		{
			m_state = m_quit_prevstate;
			m_entersound = true;
		}
		else
		{
			key_dest = key_game;
			m_state = m_none;
		}
		break;

	case 'Y':
	case 'y':
	case K_ENTER:
		key_dest = key_console;
		Host_Quit_f ();
		break;

	default:
		break;
	}

}


void M_Quit_Draw (void)
{
	if (wasInMenus)
	{
		if (key_dest != key_menu_pause)
			Draw_Pic (0, 0, menu_bk);
		//else
			//Draw_AlphaPic (0, 0, pause_bk, 0.4);

		m_state = m_quit_prevstate;
		m_recursiveDraw = true;
		M_Draw ();
		m_state = m_quit;
	}

	M_DrawTextBox (56, 76, 24, 4);
	M_PrintOld (64, 84,  quitMessage[msgNumber*4+0]);
	M_PrintOld (64, 92,  quitMessage[msgNumber*4+1]);
	M_PrintOld (64, 100, quitMessage[msgNumber*4+2]);
	M_PrintOld (64, 108, quitMessage[msgNumber*4+3]);
}
//=============================================================================
/* OSK IMPLEMENTATION */
#define CHAR_SIZE 8
#define MAX_Y 8
#define MAX_X 12

#define MAX_CHAR_LINE 36
#define MAX_CHAR      72

int  osk_pos_x = 0;
int  osk_pos_y = 0;
int  max_len   = 0;
int  m_old_state = 0;

char* osk_out_buff = NULL;
char  osk_buffer[128];

char *osk_text [] =
	{
		" 1 2 3 4 5 6 7 8 9 0 - = ` ",
		" q w e r t y u i o p [ ]   ",
		"   a s d f g h j k l ; ' \\ ",
		"     z x c v b n m   , . / ",
		"                           ",
		" ! @ # $ % ^ & * ( ) _ + ~ ",
		" Q W E R T Y U I O P { }   ",
		"   A S D F G H J K L : \" | ",
		"     Z X C V B N M   < > ? "
	};

char *osk_help [] =
	{
		"CONFIRM: ",
		" SQUARE  ",
		"CANCEL:  ",
		" CIRCLE  ",
		"DELETE:  ",
		" TRIAGLE ",
		"ADD CHAR:",
		" CROSS   ",
		""
	};

void M_Menu_OSK_f (char *input, char *output, int outlen)
{
	key_dest = key_menu;
	m_old_state = m_state;
	m_state = m_osk;
	m_entersound = false;
	max_len = outlen;
	strncpy(osk_buffer,input,max_len);
	osk_buffer[outlen] = '\0';
	osk_out_buff = output;
}

void Con_OSK_f (char *input, char *output, int outlen)
{
	max_len = outlen;
	strncpy(osk_buffer,input,max_len);
	osk_buffer[outlen] = '\0';
	osk_out_buff = output;
}


void M_OSK_Draw (void)
{
	int x,y;
	int i;

	char *selected_line = osk_text[osk_pos_y];
	char selected_char[2];

	selected_char[0] = selected_line[1+(2*osk_pos_x)];
	selected_char[1] = '\0';
	if (selected_char[0] == ' ' || selected_char[0] == '\t')
		selected_char[0] = 'X';

	y = 20;
	x = 16;

	M_DrawTextBox (10, 10, 		     26, 10);
	M_DrawTextBox (10+(26*CHAR_SIZE),    10,  10, 10);
	M_DrawTextBox (10, 10+(10*CHAR_SIZE),36,  3);

	for(i=0;i<=MAX_Y;i++)
	{
		M_PrintWhiteOld (x, y+(CHAR_SIZE*i), osk_text[i]);
		if (i % 2 == 0)
			M_PrintOld      (x+(27*CHAR_SIZE), y+(CHAR_SIZE*i), osk_help[i]);
		else
			M_PrintWhiteOld (x+(27*CHAR_SIZE), y+(CHAR_SIZE*i), osk_help[i]);
	}

	int text_len = strlen(osk_buffer);
	if (text_len > MAX_CHAR_LINE) {

		char oneline[MAX_CHAR_LINE+1];
		strncpy(oneline,osk_buffer,MAX_CHAR_LINE);
		oneline[MAX_CHAR_LINE] = '\0';

		M_PrintOld (x+4, y+4+(CHAR_SIZE*(MAX_Y+2)), oneline );

		strncpy(oneline,osk_buffer+MAX_CHAR_LINE, text_len - MAX_CHAR_LINE);
		oneline[text_len - MAX_CHAR_LINE] = '\0';

		M_PrintOld (x+4, y+4+(CHAR_SIZE*(MAX_Y+3)), oneline );
		M_PrintWhiteOld (x+4+(CHAR_SIZE*(text_len - MAX_CHAR_LINE)), y+4+(CHAR_SIZE*(MAX_Y+3)),"_");
	}
	else {
		M_PrintOld (x+4, y+4+(CHAR_SIZE*(MAX_Y+2)), osk_buffer );
		M_PrintWhiteOld (x+4+(CHAR_SIZE*(text_len)), y+4+(CHAR_SIZE*(MAX_Y+2)),"_");
	}
	M_PrintOld      (x+((((osk_pos_x)*2)+1)*CHAR_SIZE), y+(osk_pos_y*CHAR_SIZE), selected_char);

}

void M_OSK_Key (int key)//blubswillrule: making console cursor wrap around
{
	switch (key)
	{
	case K_RIGHTARROW:
		osk_pos_x++;
		if (osk_pos_x > MAX_X)
			osk_pos_x = 0;//MAX_X
		break;
	case K_LEFTARROW:
		osk_pos_x--;
		if (osk_pos_x < 0)
			osk_pos_x = MAX_X;//0
		break;
	case K_DOWNARROW:
		osk_pos_y++;
		if (osk_pos_y > MAX_Y)
			osk_pos_y = 0;//MAX_Y
		break;
	case K_UPARROW:
		osk_pos_y--;
		if (osk_pos_y < 0)
			osk_pos_y = MAX_Y;//0
		break;
	case K_ENTER:
		if (max_len > strlen(osk_buffer)) {
			char *selected_line = osk_text[osk_pos_y];
			char selected_char[2];

			selected_char[0] = selected_line[1+(2*osk_pos_x)];

			if (selected_char[0] == '\t')
				selected_char[0] = ' ';

			selected_char[1] = '\0';
			strcat(osk_buffer,selected_char);
		}
		break;
	case K_DEL:
		if (strlen(osk_buffer) > 0) {
			osk_buffer[strlen(osk_buffer)-1] = '\0';
		}
		break;
	case K_INS:
		strncpy(osk_out_buff,osk_buffer,max_len);

		m_state = m_old_state;
		break;
	case K_ESCAPE:
		m_state = m_old_state;
		break;
	default:
		break;
	}
}

void Con_OSK_Key (int key)////blubswillrule: making console cursor wrap around
{
	switch (key)
	{
	case K_RIGHTARROW:
		osk_pos_x++;
		if (osk_pos_x > MAX_X)
			osk_pos_x = 0;//MAX_X
		break;
	case K_LEFTARROW:
		osk_pos_x--;
		if (osk_pos_x < 0)
			osk_pos_x = MAX_X;//0
		break;
	case K_DOWNARROW:
		osk_pos_y++;
		if (osk_pos_y > MAX_Y)
			osk_pos_y = 0;//MAX_Y
		break;
	case K_UPARROW:
		osk_pos_y--;
		if (osk_pos_y < 0)
			osk_pos_y = MAX_Y;//0
		break;
	case K_ENTER:
		if (max_len > strlen(osk_buffer)) {
			char *selected_line = osk_text[osk_pos_y];
			char selected_char[2];

			selected_char[0] = selected_line[1+(2*osk_pos_x)];

			if (selected_char[0] == '\t')
				selected_char[0] = ' ';

			selected_char[1] = '\0';
			strcat(osk_buffer,selected_char);
		}
		break;
	case K_DEL:
		if (strlen(osk_buffer) > 0) {
			osk_buffer[strlen(osk_buffer)-1] = '\0';
		}
		break;
	case K_INS:
		strncpy(osk_out_buff,osk_buffer,max_len);
		Con_SetOSKActive(false);
		break;
	case K_ESCAPE:
		Con_SetOSKActive(false);
		break;
	default:
		break;
	}
}

//=============================================================================

/* SERIAL CONFIG MENU */

int		serialConfig_cursor;
int		serialConfig_cursor_table[] = {48, 64, 80, 96, 112, 132};
#define	NUM_SERIALCONFIG_CMDS	6

static int ISA_uarts[]	= {0x3f8,0x2f8,0x3e8,0x2e8};
static int ISA_IRQs[]	= {4,3,4,3};
int serialConfig_baudrate[] = {9600,14400,19200,28800,38400,57600};

int		serialConfig_comport;
int		serialConfig_irq ;
int		serialConfig_baud;
char	serialConfig_phone[16];

void M_Menu_SerialConfig_f (void)
{
	int		n;
	int		port;
	int		baudrate;
	qboolean	useModem;

	key_dest = key_menu;
	m_state = m_serialconfig;
	m_entersound = true;
	if (JoiningGame && SerialConfig)
		serialConfig_cursor = 4;
	else
		serialConfig_cursor = 5;

	(*GetComPortConfig) (0, &port, &serialConfig_irq, &baudrate, &useModem);

	// map uart's port to COMx
	for (n = 0; n < 4; n++)
		if (ISA_uarts[n] == port)
			break;
	if (n == 4)
	{
		n = 0;
		serialConfig_irq = 4;
	}
	serialConfig_comport = n + 1;

	// map baudrate to index
	for (n = 0; n < 6; n++)
		if (serialConfig_baudrate[n] == baudrate)
			break;
	if (n == 6)
		n = 5;
	serialConfig_baud = n;

	m_return_onerror = false;
	m_return_reason[0] = 0;
}


void M_SerialConfig_Draw (void)
{
	int		basex;
	char	*startJoin;
	char	*directModem;

    if (key_dest != key_menu_pause)
		Draw_Pic (0, 0, menu_bk);
	//else
		//Draw_AlphaPic (0, 0, pause_bk, 0.4);

	basex = (320)/2;

	if (StartingGame)
		startJoin = "New Game";
	else
		startJoin = "Join Game";
	if (SerialConfig)
		directModem = "Modem";
	else
		directModem = "Direct Connect";
	M_PrintOld (basex, 32, va ("%s - %s", startJoin, directModem));
	basex += 8;

	M_PrintOld (basex, serialConfig_cursor_table[0], "Port");
	M_DrawTextBox (160, 40, 4, 1);
	M_PrintOld (168, serialConfig_cursor_table[0], va("COM%u", serialConfig_comport));

	M_PrintOld (basex, serialConfig_cursor_table[1], "IRQ");
	M_DrawTextBox (160, serialConfig_cursor_table[1]-8, 1, 1);
	M_PrintOld (168, serialConfig_cursor_table[1], va("%u", serialConfig_irq));

	M_PrintOld (basex, serialConfig_cursor_table[2], "Baud");
	M_DrawTextBox (160, serialConfig_cursor_table[2]-8, 5, 1);
	M_PrintOld (168, serialConfig_cursor_table[2], va("%u", serialConfig_baudrate[serialConfig_baud]));

	if (SerialConfig)
	{
		M_PrintOld (basex, serialConfig_cursor_table[3], "Modem Setup...");
		if (JoiningGame)
		{
			M_PrintOld (basex, serialConfig_cursor_table[4], "Phone number");
			M_DrawTextBox (160, serialConfig_cursor_table[4]-8, 16, 1);
			M_PrintOld (168, serialConfig_cursor_table[4], serialConfig_phone);
		}
	}

	if (JoiningGame)
	{
		M_DrawTextBox (basex, serialConfig_cursor_table[5]-8, 7, 1);
		M_PrintOld (basex+8, serialConfig_cursor_table[5], "Connect");
	}
	else
	{
		M_DrawTextBox (basex, serialConfig_cursor_table[5]-8, 2, 1);
		M_PrintOld (basex+8, serialConfig_cursor_table[5], "OK");
	}

	M_DrawCharacter2 (basex-8, serialConfig_cursor_table [serialConfig_cursor], 12+((int)(realtime*4)&1));

	if (serialConfig_cursor == 4)
		M_DrawCharacter2 (168 + 8*strlen(serialConfig_phone), serialConfig_cursor_table [serialConfig_cursor], 10+((int)(realtime*4)&1));

	if (*m_return_reason)
		M_PrintWhiteOld (basex, 148, m_return_reason);
}


void M_SerialConfig_Key (int key)
{
	int		l;

	switch (key)
	{
	case K_ESCAPE:
		M_Menu_Net_f ();
		break;

	case K_UPARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		serialConfig_cursor--;
		if (serialConfig_cursor < 0)
			serialConfig_cursor = NUM_SERIALCONFIG_CMDS-1;
		break;

	case K_DOWNARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		serialConfig_cursor++;
		if (serialConfig_cursor >= NUM_SERIALCONFIG_CMDS)
			serialConfig_cursor = 0;
		break;

	case K_LEFTARROW:
		if (serialConfig_cursor > 2)
			break;
		S_LocalSound ("sounds/menu/navigate.wav");

		if (serialConfig_cursor == 0)
		{
			serialConfig_comport--;
			if (serialConfig_comport == 0)
				serialConfig_comport = 4;
			serialConfig_irq = ISA_IRQs[serialConfig_comport-1];
		}

		if (serialConfig_cursor == 1)
		{
			serialConfig_irq--;
			if (serialConfig_irq == 6)
				serialConfig_irq = 5;
			if (serialConfig_irq == 1)
				serialConfig_irq = 7;
		}

		if (serialConfig_cursor == 2)
		{
			serialConfig_baud--;
			if (serialConfig_baud < 0)
				serialConfig_baud = 5;
		}

		break;

	case K_RIGHTARROW:
		if (serialConfig_cursor > 2)
			break;
forward:
		S_LocalSound ("sounds/menu/navigate.wav");

		if (serialConfig_cursor == 0)
		{
			serialConfig_comport++;
			if (serialConfig_comport > 4)
				serialConfig_comport = 1;
			serialConfig_irq = ISA_IRQs[serialConfig_comport-1];
		}

		if (serialConfig_cursor == 1)
		{
			serialConfig_irq++;
			if (serialConfig_irq == 6)
				serialConfig_irq = 7;
			if (serialConfig_irq == 8)
				serialConfig_irq = 2;
		}

		if (serialConfig_cursor == 2)
		{
			serialConfig_baud++;
			if (serialConfig_baud > 5)
				serialConfig_baud = 0;
		}

		break;

	case K_ENTER:
		if (serialConfig_cursor < 3)
			goto forward;

		m_entersound = true;

		if (serialConfig_cursor == 3)
		{
			(*SetComPortConfig) (0, ISA_uarts[serialConfig_comport-1], serialConfig_irq, serialConfig_baudrate[serialConfig_baud], SerialConfig);

			M_Menu_ModemConfig_f ();
			break;
		}

		if (serialConfig_cursor == 4)
		{
			serialConfig_cursor = 5;
			break;
		}

		// serialConfig_cursor == 5 (OK/CONNECT)
		(*SetComPortConfig) (0, ISA_uarts[serialConfig_comport-1], serialConfig_irq, serialConfig_baudrate[serialConfig_baud], SerialConfig);

		M_ConfigureNetSubsystem ();

		if (StartingGame)
		{
			M_Menu_GameOptions_f ();
			break;
		}

		m_return_state = m_state;
		m_return_onerror = true;
		key_dest = key_game;
		m_state = m_none;

		if (SerialConfig)
			Cbuf_AddText (va ("connect \"%s\"\n", serialConfig_phone));
		else
			Cbuf_AddText ("connect\n");
		break;

	case K_BACKSPACE:
		if (serialConfig_cursor == 4)
		{
			if (strlen(serialConfig_phone))
				serialConfig_phone[strlen(serialConfig_phone)-1] = 0;
		}
		break;

	default:
		if (key < 32 || key > 127)
			break;
		if (serialConfig_cursor == 4)
		{
			l = strlen(serialConfig_phone);
			if (l < 15)
			{
				serialConfig_phone[l+1] = 0;
				serialConfig_phone[l] = key;
			}
		}
	}

	if (DirectConfig && (serialConfig_cursor == 3 || serialConfig_cursor == 4))
	{
		if (key == K_UPARROW)
			serialConfig_cursor = 2;
		else
			serialConfig_cursor = 5;
	}
	if (SerialConfig && StartingGame && serialConfig_cursor == 4)
	{
		if (key == K_UPARROW)
			serialConfig_cursor = 3;
		else
			serialConfig_cursor = 5;
	}
}

//=============================================================================
/* MODEM CONFIG MENU */

int		modemConfig_cursor;
int		modemConfig_cursor_table [] = {40, 56, 88, 120, 156};
#define NUM_MODEMCONFIG_CMDS	5

char	modemConfig_dialing;
char	modemConfig_clear [16];
char	modemConfig_init [32];
char	modemConfig_hangup [16];

void M_Menu_ModemConfig_f (void)
{
	key_dest = key_menu;
	m_state = m_modemconfig;
	m_entersound = true;
	(*GetModemConfig) (0, &modemConfig_dialing, modemConfig_clear, modemConfig_init, modemConfig_hangup);
}


void M_ModemConfig_Draw (void)
{
	int		basex;

    if (key_dest != key_menu_pause)
		Draw_Pic (0, 0, menu_bk);
	//else
		//Draw_AlphaPic (0, 0, pause_bk, 0.4);

	basex = (320)/2;
	basex += 8;

	if (modemConfig_dialing == 'P')
		M_PrintOld (basex, modemConfig_cursor_table[0], "Pulse Dialing");
	else
		M_PrintOld (basex, modemConfig_cursor_table[0], "Touch Tone Dialing");

	M_PrintOld (basex, modemConfig_cursor_table[1], "Clear");
	M_DrawTextBox (basex, modemConfig_cursor_table[1]+4, 16, 1);
	M_PrintOld (basex+8, modemConfig_cursor_table[1]+12, modemConfig_clear);
	if (modemConfig_cursor == 1)
		M_DrawCharacter2 (basex+8 + 8*strlen(modemConfig_clear), modemConfig_cursor_table[1]+12, 10+((int)(realtime*4)&1));

	M_PrintOld (basex, modemConfig_cursor_table[2], "Init");
	M_DrawTextBox (basex, modemConfig_cursor_table[2]+4, 30, 1);
	M_PrintOld (basex+8, modemConfig_cursor_table[2]+12, modemConfig_init);
	if (modemConfig_cursor == 2)
		M_DrawCharacter2 (basex+8 + 8*strlen(modemConfig_init), modemConfig_cursor_table[2]+12, 10+((int)(realtime*4)&1));

	M_PrintOld (basex, modemConfig_cursor_table[3], "Hangup");
	M_DrawTextBox (basex, modemConfig_cursor_table[3]+4, 16, 1);
	M_PrintOld (basex+8, modemConfig_cursor_table[3]+12, modemConfig_hangup);
	if (modemConfig_cursor == 3)
		M_DrawCharacter2 (basex+8 + 8*strlen(modemConfig_hangup), modemConfig_cursor_table[3]+12, 10+((int)(realtime*4)&1));

	M_DrawTextBox (basex, modemConfig_cursor_table[4]-8, 2, 1);
	M_PrintOld (basex+8, modemConfig_cursor_table[4], "OK");

	M_DrawCharacter2 (basex-8, modemConfig_cursor_table [modemConfig_cursor], 12+((int)(realtime*4)&1));
}


void M_ModemConfig_Key (int key)
{
	int		l;

	switch (key)
	{
	case K_ESCAPE:
		M_Menu_SerialConfig_f ();
		break;

	case K_UPARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		modemConfig_cursor--;
		if (modemConfig_cursor < 0)
			modemConfig_cursor = NUM_MODEMCONFIG_CMDS-1;
		break;

	case K_DOWNARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		modemConfig_cursor++;
		if (modemConfig_cursor >= NUM_MODEMCONFIG_CMDS)
			modemConfig_cursor = 0;
		break;

	case K_LEFTARROW:
	case K_RIGHTARROW:
		if (modemConfig_cursor == 0)
		{
			if (modemConfig_dialing == 'P')
				modemConfig_dialing = 'T';
			else
				modemConfig_dialing = 'P';
			S_LocalSound ("sounds/menu/navigate.wav");
		}
		break;

	case K_ENTER:
		if (modemConfig_cursor == 0)
		{
			if (modemConfig_dialing == 'P')
				modemConfig_dialing = 'T';
			else
				modemConfig_dialing = 'P';
			m_entersound = true;
		}

		if (modemConfig_cursor == 4)
		{
			(*SetModemConfig) (0, va ("%c", modemConfig_dialing), modemConfig_clear, modemConfig_init, modemConfig_hangup);
			m_entersound = true;
			M_Menu_SerialConfig_f ();
		}
		break;

	case K_BACKSPACE:
		if (modemConfig_cursor == 1)
		{
			if (strlen(modemConfig_clear))
				modemConfig_clear[strlen(modemConfig_clear)-1] = 0;
		}

		if (modemConfig_cursor == 2)
		{
			if (strlen(modemConfig_init))
				modemConfig_init[strlen(modemConfig_init)-1] = 0;
		}

		if (modemConfig_cursor == 3)
		{
			if (strlen(modemConfig_hangup))
				modemConfig_hangup[strlen(modemConfig_hangup)-1] = 0;
		}
		break;

	default:
		if (key < 32 || key > 127)
			break;

		if (modemConfig_cursor == 1)
		{
			l = strlen(modemConfig_clear);
			if (l < 15)
			{
				modemConfig_clear[l+1] = 0;
				modemConfig_clear[l] = key;
			}
		}

		if (modemConfig_cursor == 2)
		{
			l = strlen(modemConfig_init);
			if (l < 29)
			{
				modemConfig_init[l+1] = 0;
				modemConfig_init[l] = key;
			}
		}

		if (modemConfig_cursor == 3)
		{
			l = strlen(modemConfig_hangup);
			if (l < 15)
			{
				modemConfig_hangup[l+1] = 0;
				modemConfig_hangup[l] = key;
			}
		}
	}
}

//=============================================================================
/* LAN CONFIG MENU */

int		lanConfig_cursor = -1;
int		lanConfig_cursor_table [] = {72, 92, 124};
#define NUM_LANCONFIG_CMDS	3

int 	lanConfig_port;
char	lanConfig_portname[6];
char	lanConfig_joinname[22];

void M_Menu_LanConfig_f (void)
{
	key_dest = key_menu;
	m_state = m_lanconfig;
	m_entersound = true;
	if (lanConfig_cursor == -1)
	{
		if (JoiningGame && TCPIPConfig)
			lanConfig_cursor = 2;
		else
			lanConfig_cursor = 1;
	}
	if (StartingGame && lanConfig_cursor == 2)
		lanConfig_cursor = 1;
	lanConfig_port = DEFAULTnet_hostport;
	sprintf(lanConfig_portname, "%u", lanConfig_port);

	m_return_onerror = false;
	m_return_reason[0] = 0;
}


void M_LanConfig_Draw (void)
{
	int		basex;
	char	*startJoin;
	char	*protocol;

    if (key_dest != key_menu_pause)
		Draw_Pic (0, 0, menu_bk);
	//else
		//Draw_AlphaPic (0, 0, pause_bk, 0.4);

	basex = (320)/2;

	if (StartingGame)
		startJoin = "New Game";
	else
		startJoin = "Join Game";
	if (IPXConfig)
		protocol = "IPX";
	else
		protocol = "TCP/IP";
	M_PrintOld (basex, 32, va ("%s - %s", startJoin, protocol));
	basex += 8;

	M_PrintOld (basex, 52, "Address:");
	if (IPXConfig)
		M_PrintOld (basex+9*8, 52, my_ipx_address);
	else
		M_PrintOld (basex+9*8, 52, my_tcpip_address);

	M_PrintOld (basex, lanConfig_cursor_table[0], "Port");
	M_DrawTextBox (basex+8*8, lanConfig_cursor_table[0]-8, 6, 1);
	M_PrintOld (basex+9*8, lanConfig_cursor_table[0], lanConfig_portname);

	if (JoiningGame)
	{
		M_PrintOld (basex, lanConfig_cursor_table[1], "Search for local games...");
		M_PrintOld (basex, 108, "Join game at:");
		M_DrawTextBox (basex+8, lanConfig_cursor_table[2]-8, 22, 1);
		M_PrintOld (basex+16, lanConfig_cursor_table[2], lanConfig_joinname);
	}
	else
	{
		M_DrawTextBox (basex, lanConfig_cursor_table[1]-8, 2, 1);
		M_PrintOld (basex+8, lanConfig_cursor_table[1], "OK");
	}

	M_DrawCharacter2 (basex-8, lanConfig_cursor_table [lanConfig_cursor], 12+((int)(realtime*4)&1));

	if (lanConfig_cursor == 0)
		M_DrawCharacter2 (basex+9*8 + 8*strlen(lanConfig_portname), lanConfig_cursor_table [0], 10+((int)(realtime*4)&1));

	if (lanConfig_cursor == 2)
		M_DrawCharacter2 (basex+16 + 8*strlen(lanConfig_joinname), lanConfig_cursor_table [2], 10+((int)(realtime*4)&1));

	if (*m_return_reason)
		M_PrintWhiteOld (basex, 148, m_return_reason);
}


void M_LanConfig_Key (int key)
{
	int		l;

	switch (key)
	{
	case K_ESCAPE:
		M_Menu_Net_f ();
		break;

	case K_UPARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		lanConfig_cursor--;
		if (lanConfig_cursor < 0)
			lanConfig_cursor = NUM_LANCONFIG_CMDS-1;
		break;

	case K_DOWNARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		lanConfig_cursor++;
		if (lanConfig_cursor >= NUM_LANCONFIG_CMDS)
			lanConfig_cursor = 0;
		break;

	case K_INS:
		if (lanConfig_cursor == 0)
		{
			M_Menu_OSK_f(lanConfig_portname, lanConfig_portname, 6);
			break;
		}

		if (lanConfig_cursor == 2)
		{
			M_Menu_OSK_f(lanConfig_joinname, lanConfig_joinname, 22);
			break;
		}
		break;

	case K_ENTER:
		if (lanConfig_cursor == 0)
			break;

		m_entersound = true;

		M_ConfigureNetSubsystem ();

		if (lanConfig_cursor == 1)
		{
			if (StartingGame)
			{
				M_Menu_GameOptions_f ();
				break;
			}
			M_Menu_Search_f();
			break;
		}

		if (lanConfig_cursor == 2)
		{
			m_return_state = m_state;
			m_return_onerror = true;
			key_dest = key_game;
			m_state = m_none;
			Cbuf_AddText ( va ("connect \"%s\"\n", lanConfig_joinname) );
			break;
		}

		break;

	case K_BACKSPACE:
		if (lanConfig_cursor == 0)
		{
			if (strlen(lanConfig_portname))
				lanConfig_portname[strlen(lanConfig_portname)-1] = 0;
		}

		if (lanConfig_cursor == 2)
		{
			if (strlen(lanConfig_joinname))
				lanConfig_joinname[strlen(lanConfig_joinname)-1] = 0;
		}
		break;

	default:
		if (key < 32 || key > 127)
			break;

		if (lanConfig_cursor == 2)
		{
			l = strlen(lanConfig_joinname);
			if (l < 21)
			{
				lanConfig_joinname[l+1] = 0;
				lanConfig_joinname[l] = key;
			}
		}

		if (key < '0' || key > '9')
			break;
		if (lanConfig_cursor == 0)
		{
			l = strlen(lanConfig_portname);
			if (l < 5)
			{
				lanConfig_portname[l+1] = 0;
				lanConfig_portname[l] = key;
			}
		}
	}

	if (StartingGame && lanConfig_cursor == 2)
	{
		if (key == K_UPARROW)
			lanConfig_cursor = 1;
		else
			lanConfig_cursor = 0;
	}

	l =  Q_atoi(lanConfig_portname);
	if (l > 65535)
		l = lanConfig_port;
	else
		lanConfig_port = l;
	sprintf(lanConfig_portname, "%u", lanConfig_port);
}

//=============================================================================
/* GAME OPTIONS MENU */

typedef struct
{
	char	*name;
	char	*description;
} level_t;

level_t		levels[] =
{
	{"start", "Entrance"},	// 0

	{"e1m1", "Slipgate Complex"},				// 1
	{"e1m2", "Castle of the Damned"},
	{"e1m3", "The Necropolis"},
	{"e1m4", "The Grisly Grotto"},
	{"e1m5", "Gloom Keep"},
	{"e1m6", "The Door To Chthon"},
	{"e1m7", "The House of Chthon"},
	{"e1m8", "Ziggurat Vertigo"},

	{"e2m1", "The Installation"},				// 9
	{"e2m2", "Ogre Citadel"},
	{"e2m3", "Crypt of Decay"},
	{"e2m4", "The Ebon Fortress"},
	{"e2m5", "The Wizard's Manse"},
	{"e2m6", "The Dismal Oubliette"},
	{"e2m7", "Underearth"},

	{"e3m1", "Termination Central"},			// 16
	{"e3m2", "The Vaults of Zin"},
	{"e3m3", "The Tomb of Terror"},
	{"e3m4", "Satan's Dark Delight"},
	{"e3m5", "Wind Tunnels"},
	{"e3m6", "Chambers of Torment"},
	{"e3m7", "The Haunted Halls"},

	{"e4m1", "The Sewage System"},				// 23
	{"e4m2", "The Tower of Despair"},
	{"e4m3", "The Elder God Shrine"},
	{"e4m4", "The Palace of Hate"},
	{"e4m5", "Hell's Atrium"},
	{"e4m6", "The Pain Maze"},
	{"e4m7", "Azure Agony"},
	{"e4m8", "The Nameless City"},

	{"end", "Shub-Niggurath's Pit"},			// 31

	{"dm1", "Place of Two Deaths"},				// 32
	{"dm2", "Claustrophobopolis"},
	{"dm3", "The Abandoned Base"},
	{"dm4", "The Bad Place"},
	{"dm5", "The Cistern"},
	{"dm6", "The Dark Zone"}
};

typedef struct
{
	char	*description;
	int		firstLevel;
	int		levels;
} episode_t;

episode_t	episodes[] =
{
	{"Welcome to Quake", 0, 1},
	{"Doomed Dimension", 1, 8},
	{"Realm of Black Magic", 9, 7},
	{"Netherworld", 16, 7},
	{"The Elder World", 23, 8},
	{"Final Level", 31, 1},
	{"Deathmatch Arena", 32, 6}
};

int	startepisode;
int	startlevel;
int maxplayers;
qboolean m_serverInfoMessage = false;
double m_serverInfoMessageTime;

//==================== Map Find System By Crow_bar =============================

void Map_Finder(void)
{

#ifdef KERNEL_MODE
	SceUID dir = sceIoDopen(va("%s/maps", com_gamedir));
#else
	SceUID dir = sceIoDopen(va("nzp/maps"));
#endif // KERNEL_MODE

	if(dir < 0)
	{
		Sys_Error ("Map_Finder");
		return;
	}

	SceIoDirent dirent;

    memset(&dirent, 0, sizeof(SceIoDirent));

	for (int i = 0; i < 50; i++) {
		custom_maps[i].occupied = false;
	}

	while(sceIoDread(dir, &dirent) > 0)
	{
		if(dirent.d_name[0] == '.')
		{
			continue;
		}

		if(!strcmp(COM_FileExtension(dirent.d_name),"bsp")|| !strcmp(COM_FileExtension(dirent.d_name),"BSP"))
	    {
			char ntype[32];

			COM_StripExtension(dirent.d_name, ntype);
			custom_maps[user_maps_num].occupied = true;
			custom_maps[user_maps_num].map_name = malloc(sizeof(char)*32);
			sprintf(custom_maps[user_maps_num].map_name, "%s", ntype);

			char* 		setting_path;
			int 		setting_file;
			SceIoStat	setting_info;

			setting_path 								  	= malloc(sizeof(char)*64);
			custom_maps[user_maps_num].map_thumbnail_path 	= malloc(sizeof(char)*64);
#ifdef KERNEL_MODE
			strcpy(setting_path, 									va("%s/maps/", com_gamedir));
#else
			strcpy(setting_path, 									va("nzp/maps/"));
#endif // KERNEL_MODE
			strcpy(custom_maps[user_maps_num].map_thumbnail_path, 	"gfx/menu/custom/");
			strcat(setting_path, 									custom_maps[user_maps_num].map_name);
			strcat(custom_maps[user_maps_num].map_thumbnail_path, 	custom_maps[user_maps_num].map_name);
			strcat(setting_path, ".txt");

			sceIoGetstat(setting_path, &setting_info);
			setting_file = sceIoOpen(setting_path, PSP_O_RDONLY, 0);

			if (setting_file >= 0) {

				int state;
				state = 0;
				int value;

				custom_maps[user_maps_num].map_name_pretty = malloc(sizeof(char)*32);
				custom_maps[user_maps_num].map_desc_1 = malloc(sizeof(char)*40);
				custom_maps[user_maps_num].map_desc_2 = malloc(sizeof(char)*40);
				custom_maps[user_maps_num].map_desc_3 = malloc(sizeof(char)*40);
				custom_maps[user_maps_num].map_desc_4 = malloc(sizeof(char)*40);
				custom_maps[user_maps_num].map_desc_5 = malloc(sizeof(char)*40);
				custom_maps[user_maps_num].map_desc_6 = malloc(sizeof(char)*40);
				custom_maps[user_maps_num].map_desc_7 = malloc(sizeof(char)*40);
				custom_maps[user_maps_num].map_desc_8 = malloc(sizeof(char)*40);
				custom_maps[user_maps_num].map_author = malloc(sizeof(char)*40);

				char* buffer = (char*)calloc(setting_info.st_size+1, sizeof(char));
				sceIoRead(setting_file, buffer, setting_info.st_size);

				strtok(buffer, "\n");
				while(buffer != NULL) {
					switch(state) {
						case 0: strcpy(custom_maps[user_maps_num].map_name_pretty, buffer); break;
						case 1: strcpy(custom_maps[user_maps_num].map_desc_1, buffer); break;
						case 2: strcpy(custom_maps[user_maps_num].map_desc_2, buffer); break;
						case 3: strcpy(custom_maps[user_maps_num].map_desc_3, buffer); break;
						case 4: strcpy(custom_maps[user_maps_num].map_desc_4, buffer); break;
						case 5: strcpy(custom_maps[user_maps_num].map_desc_5, buffer); break;
						case 6: strcpy(custom_maps[user_maps_num].map_desc_6, buffer); break;
						case 7: strcpy(custom_maps[user_maps_num].map_desc_7, buffer); break;
						case 8: strcpy(custom_maps[user_maps_num].map_desc_8, buffer); break;
						case 9: strcpy(custom_maps[user_maps_num].map_author, buffer); break;
						case 10: value = 0; sscanf(buffer, "%d", &value); custom_maps[user_maps_num].map_use_thumbnail = value; break;
						case 11: value = 0; sscanf(buffer, "%d", &value); custom_maps[user_maps_num].map_allow_game_settings = value; break;
						default: break;
					}
					state++;
					buffer = strtok(NULL, "\n");
				}
				free(buffer);
				buffer = 0;
				sceIoClose(setting_file);
			}
			user_maps_num++;
		}
	    memset(&dirent, 0, sizeof(SceIoDirent));
	}
    sceIoDclose(dir);

	custom_map_pages = (int)ceil((double)(user_maps_num + 1)/15);
}
//==============================================================================
void M_Menu_GameOptions_f (void)
{
	key_dest = key_menu;
	m_state = m_gameoptions;
	m_entersound = true;
	if (maxplayers == 0)
		maxplayers = svs.maxclients;
	if (maxplayers < 2)
		maxplayers = svs.maxclientslimit;
}


int gameoptions_cursor_table[] = {40, 56, 64, 72, 80, 88, 96, 112, 120};
#define	NUM_GAMEOPTIONS	9
int		gameoptions_cursor;

void M_GameOptions_Draw (void)
{
	int		x;

    if (key_dest != key_menu_pause)
		Draw_Pic (0, 0, menu_bk);
	//else
		//Draw_AlphaPic (0, 0, pause_bk, 0.4);

	M_DrawTextBox (152, 32, 10, 1);
	M_PrintOld (160, 40, "begin game");

	M_PrintOld (0, 56, "      Max players");
	M_PrintOld (160, 56, va("%i", maxplayers) );

	M_PrintOld (0, 64, "        Game Type");
	if (coop.value)
		M_PrintOld (160, 64, "Cooperative");
	else
		M_PrintOld (160, 64, "Deathmatch");

	M_PrintOld (0, 72, "        Teamplay");

	char *msg;

	switch((int)teamplay.value)
	{
		case 1: msg = "No Friendly Fire"; break;
		case 2: msg = "Friendly Fire"; break;
		default: msg = "Off"; break;
	}
	M_PrintOld (160, 72, msg);


	M_PrintOld (0, 80, "            Skill");
	if (skill.value == 0)
		M_PrintOld (160, 80, "Easy difficulty");
	else if (skill.value == 1)
		M_PrintOld (160, 80, "Normal difficulty");
	else if (skill.value == 2)
		M_PrintOld (160, 80, "Hard difficulty");
	else
		M_PrintOld (160, 80, "Nightmare difficulty");

	M_PrintOld (0, 88, "       Frag Limit");
	if (fraglimit.value == 0)
		M_PrintOld (160, 88, "none");
	else
		M_PrintOld (160, 88, va("%i points", (int)fraglimit.value));

	M_PrintOld (0, 96, "       Time Limit");
	if (timelimit.value == 0)
		M_PrintOld (160, 96, "none");
	else
		M_PrintOld (160, 96, va("%i minutes", (int)timelimit.value));

	M_PrintOld (0, 112, "         Episode");

	if(user_maps)
		M_PrintOld (160, 112, "User Maps");
	else
		M_PrintOld (160, 112, episodes[startepisode].description);

	M_PrintOld (0, 120, "           Level");

   if(user_maps)
	{
		M_PrintOld (160, 120, user_levels[startlevel]);
	}
	else
	{
		M_PrintOld (160, 120, levels[episodes[startepisode].firstLevel + startlevel].description);
        M_PrintOld (160, 128, levels[episodes[startepisode].firstLevel + startlevel].name);
    }

// line cursor
	M_DrawCharacter2 (144, gameoptions_cursor_table[gameoptions_cursor], 12+((int)(realtime*4)&1));

	if (m_serverInfoMessage)
	{
		if ((realtime - m_serverInfoMessageTime) < 5.0)
		{
			x = (320-26*8)/2;
			M_DrawTextBox (x, 138, 24, 4);
			x += 8;
			M_PrintOld (x, 146, "  More than 4 players   ");
			M_PrintOld (x, 154, " requires using command ");
			M_PrintOld (x, 162, "line parameters; please ");
			M_PrintOld (x, 170, "   see techinfo.txt.    ");
		}
		else
		{
			m_serverInfoMessage = false;
		}
	}
}


void M_NetStart_Change (int dir)
{
	int count;

	switch (gameoptions_cursor)
	{
	case 1:
		maxplayers += dir;
		if (maxplayers > svs.maxclientslimit)
		{
			maxplayers = svs.maxclientslimit;
			m_serverInfoMessage = true;
			m_serverInfoMessageTime = realtime;
		}
		if (maxplayers < 2)
			maxplayers = 2;
		break;

	case 2:
		Cvar_SetValue ("coop", coop.value ? 0 : 1);
		break;

	case 3:
		count = 2;

		Cvar_SetValue ("teamplay", teamplay.value + dir);
		if (teamplay.value > count)
			Cvar_SetValue ("teamplay", 0);
		else if (teamplay.value < 0)
			Cvar_SetValue ("teamplay", count);
		break;

	case 4:
		Cvar_SetValue ("skill", skill.value + dir);
		if (skill.value > 3)
			Cvar_SetValue ("skill", 0);
		if (skill.value < 0)
			Cvar_SetValue ("skill", 3);
		break;

	case 5:
		Cvar_SetValue ("fraglimit", fraglimit.value + dir*10);
		if (fraglimit.value > 100)
			Cvar_SetValue ("fraglimit", 0);
		if (fraglimit.value < 0)
			Cvar_SetValue ("fraglimit", 100);
		break;

	case 6:
		Cvar_SetValue ("timelimit", timelimit.value + dir*5);
		if (timelimit.value > 60)
			Cvar_SetValue ("timelimit", 0);
		if (timelimit.value < 0)
			Cvar_SetValue ("timelimit", 60);
		break;

	case 7:
		startepisode += dir;
		if (user_maps)
		{
		    count = 1;
		}
		else
		{
			count = 2;
        }
		if (startepisode < 0)
			startepisode = count - 1;

		if (startepisode >= count)
			startepisode = 0;

		startlevel = 0;
		break;

	case 8:
		startlevel += dir;
		if(user_maps)
			count = user_maps_num;
		else
			count = episodes[startepisode].levels;
		if (startlevel < 0)
			startlevel = count - 1;

		if (startlevel >= count)
			startlevel = 0;
		break;
	}
}

void M_GameOptions_Key (int key)
{
	switch (key)
	{
	case K_ESCAPE:
		M_Menu_Net_f ();
		break;

	case K_UPARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		gameoptions_cursor--;
		if (gameoptions_cursor < 0)
			gameoptions_cursor = NUM_GAMEOPTIONS-1;
		break;

	case K_DOWNARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		gameoptions_cursor++;
		if (gameoptions_cursor >= NUM_GAMEOPTIONS)
			gameoptions_cursor = 0;
		break;

	case K_LEFTARROW:
		if (gameoptions_cursor == 0)
			break;
		S_LocalSound ("sounds/menu/navigate.wav");
		M_NetStart_Change (-1);
		break;

	case K_RIGHTARROW:
		if (gameoptions_cursor == 0)
			break;
		S_LocalSound ("sounds/menu/navigate.wav");
		M_NetStart_Change (1);
		break;

	case K_ENTER:
		S_LocalSound ("sounds/menu/enter.wav");
		if (gameoptions_cursor == 0)
		{
			if (sv.active)
				Cbuf_AddText ("disconnect\n");
			Cbuf_AddText ("listen 0\n");	// so host_netport will be re-examined
			Cbuf_AddText ( va ("maxplayers %u\n", maxplayers) );
			SCR_BeginLoadingPlaque ();

			if(user_maps)
				Cbuf_AddText ( va ("map %s\n", user_levels[startlevel]));
            else
			    Cbuf_AddText ( va ("map %s\n", levels[episodes[startepisode].firstLevel + startlevel].name) );
			return;
		}

		M_NetStart_Change (1);
		break;
	}
}

//=============================================================================
/* SEARCH MENU */

qboolean	searchComplete = false;
double		searchCompleteTime;

void M_Menu_Search_f (void)
{
	key_dest = key_menu;
	m_state = m_search;
	m_entersound = false;
	slistSilent = true;
	slistLocal = false;
	searchComplete = false;
	NET_Slist_f();

}


void M_Search_Draw (void)
{
	int x;

    if (key_dest != key_menu_pause)
		Draw_Pic (0, 0, menu_bk);
	//else
		//Draw_AlphaPic (0, 0, pause_bk, 0.4);

	x = (320/2) - ((12*8)/2) + 4;
	M_DrawTextBox (x-8, 32, 12, 1);
	M_PrintOld (x, 40, "Searching...");

	if(slistInProgress)
	{
		NET_Poll();
		return;
	}

	if (! searchComplete)
	{
		searchComplete = true;
		searchCompleteTime = realtime;
	}

	if (hostCacheCount)
	{
		M_Menu_ServerList_f ();
		return;
	}

	M_PrintWhiteOld ((320/2) - ((22*8)/2), 64, "No Quake servers found");
	if ((realtime - searchCompleteTime) < 3.0)
		return;

	M_Menu_LanConfig_f ();
}


void M_Search_Key (int key)
{
}

//=============================================================================
/* SLIST MENU

int		slist_cursor;
qboolean slist_sorted;

void M_Menu_ServerList_f (void)
{
	key_dest = key_menu;
	m_state = m_slist;
	m_entersound = true;
	slist_cursor = 0;
	m_return_onerror = false;
	m_return_reason[0] = 0;
	slist_sorted = false;
}


void M_ServerList_Draw (void)
{
	int		n;
	char	string [64];
	qpic_t	*p;

	if (!slist_sorted)
	{
		if (hostCacheCount > 1)
		{
			int	i,j;
			hostcache_t temp;
			for (i = 0; i < hostCacheCount; i++)
				for (j = i+1; j < hostCacheCount; j++)
					if (strcmp(hostcache[j].name, hostcache[i].name) < 0)
					{
						Q_memcpy(&temp, &hostcache[j], sizeof(hostcache_t));
						Q_memcpy(&hostcache[j], &hostcache[i], sizeof(hostcache_t));
						Q_memcpy(&hostcache[i], &temp, sizeof(hostcache_t));
					}
		}
		slist_sorted = true;
	}

	p = Draw_CachePic ("gfx/p_multi.lmp");
	M_DrawPic ( (320-p->width)/2, 4, p);
	for (n = 0; n < hostCacheCount; n++)
	{
		if (hostcache[n].maxusers)
			sprintf(string, "%-15.15s %-15.15s %2u/%2u\n", hostcache[n].name, hostcache[n].map, hostcache[n].users, hostcache[n].maxusers);
		else
			sprintf(string, "%-15.15s %-15.15s\n", hostcache[n].name, hostcache[n].map);
		M_PrintOld (16, 32 + 8*n, string);
	}
	M_DrawCharacter2 (0, 32 + slist_cursor*8, 12+((int)(realtime*4)&1));

	if (*m_return_reason)
		M_PrintWhiteOld (16, 148, m_return_reason);
}


void M_ServerList_Key (int k)
{
	switch (k)
	{
	case K_ESCAPE:
		M_Menu_LanConfig_f ();
		break;

	case K_SPACE:
		M_Menu_Search_f ();
		break;

	case K_UPARROW:
	case K_LEFTARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		slist_cursor--;
		if (slist_cursor < 0)
			slist_cursor = hostCacheCount - 1;
		break;

	case K_DOWNARROW:
	case K_RIGHTARROW:
		S_LocalSound ("sounds/menu/navigate.wav");
		slist_cursor++;
		if (slist_cursor >= hostCacheCount)
			slist_cursor = 0;
		break;

	case K_ENTER:
		S_LocalSound ("sounds/menu/enter.wav");
		m_return_state = m_state;
		m_return_onerror = true;
		slist_sorted = false;
		key_dest = key_game;
		m_state = m_none;
		Cbuf_AddText ( va ("connect \"%s\"\n", hostcache[slist_cursor].cname) );
		break;

	default:
		break;
	}

}
*/
//=============================================================================
/* Menu Subsystem */


void M_Init (void)
{
	Cmd_AddCommand ("togglemenu", M_ToggleMenu_f);

	Cmd_AddCommand ("menu_main", M_Menu_Main_f);
	Cmd_AddCommand ("menu_singleplayer", M_Menu_SinglePlayer_f);
	Cmd_AddCommand ("menu_multiplayer", M_Menu_MultiPlayer_f);
	Cmd_AddCommand ("menu_setup", M_Menu_Setup_f);
	Cmd_AddCommand ("menu_options", M_Menu_Options_f);
	Cmd_AddCommand ("menu_keys", M_Menu_Keys_f);
    Cmd_AddCommand ("menu_slist", M_Menu_ServerList_f);
	Cmd_AddCommand ("credits", M_Menu_Credits_f);
	Cmd_AddCommand ("menu_quit", M_Menu_Quit_f);
	Cmd_AddCommand ("savea", Save_Achivements);
	Cmd_AddCommand ("loada", Load_Achivements);

	Map_Finder();

}


void M_Draw (void)
{
	if (m_state == m_none || (key_dest != key_menu && key_dest != key_menu_pause))
		return;

	if (!m_recursiveDraw)
	{
		scr_copyeverything = 1;

		if (scr_con_current)
		{
			Draw_ConsoleBackground (vid.height);
			VID_UnlockBuffer ();
			S_ExtraUpdate ();
			VID_LockBuffer ();
		}
		else
			Draw_FadeScreen ();

		scr_fullupdate = 0;
	}
	else
	{
		m_recursiveDraw = false;
	}

	switch (m_state)
	{
	case m_none:
		break;

	case m_start:
		M_Start_Menu_Draw();
		break;

	case m_paused_menu:
		M_Paused_Menu_Draw();
		break;

	case m_main:
		M_Main_Draw ();
		break;

	case m_map:
		M_Map_Draw ();
		break;

	case m_singleplayer:
		M_SinglePlayer_Draw ();
		break;

	case m_multiplayer:
		M_MultiPlayer_Draw ();
		break;

	case m_achievement:
		M_Achievement_Draw ();
		break;

	case m_setup:
		M_Setup_Draw ();
		break;

	case m_net:
		M_Net_Draw ();
		break;

	case m_options:
		M_Options_Draw ();
		break;

	case m_keys:
		M_Keys_Draw ();
		break;

	case m_video:
		M_Screen_Draw ();
		break;

	case m_audio:
		M_Audio_Draw ();
		break;

	case m_gameplay:
		M_Gameplay_Draw ();
		break;

	case m_credits:
		M_Credits_Draw ();
		break;

	case m_quit:
		M_Quit_Draw ();
		break;

	case m_restart:
		M_Restart_Draw ();
		break;

	case m_exit:
		M_Exit_Draw ();
		break;

	case m_serialconfig:
		M_SerialConfig_Draw ();
		break;

	case m_modemconfig:
		M_ModemConfig_Draw ();
		break;

	case m_lanconfig:
		M_LanConfig_Draw ();
		break;

	case m_gameoptions:
		M_GameOptions_Draw ();
		break;

	case m_search:
		M_Search_Draw ();
		break;

	case m_slist:
		M_ServerList_Draw ();
		break;

	case m_sedit:
		M_SEdit_Draw ();
		break;

	case m_osk:
		M_OSK_Draw();
		break;
	}

	if (m_entersound)
	{
		S_LocalSound ("sounds/menu/enter.wav");
		m_entersound = false;
	}

	VID_UnlockBuffer ();
	S_ExtraUpdate ();
	VID_LockBuffer ();
}


void M_Keydown (int key)
{
	switch (m_state)
	{
	case m_none:
		return;

	case m_paused_menu:
		M_Paused_Menu_Key (key);
		break;

	case m_start:
		M_Start_Key (key);
		break;
	case m_main:
		M_Main_Key (key);
		return;

	case m_map:
		M_Map_Key (key);
		return;

	case m_singleplayer:
		M_SinglePlayer_Key (key);
		return;

	case m_multiplayer:
		M_MultiPlayer_Key (key);
		return;

	case m_achievement:
		M_Achievement_Key (key);
		return;

	case m_setup:
		M_Setup_Key (key);
		return;

	case m_net:
		M_Net_Key (key);
		return;

	case m_options:
		M_Options_Key (key);
		return;

	case m_keys:
		M_Keys_Key (key);
		return;

	case m_video:
		M_Screen_Key (key);
		return;

	case m_audio:
		M_Audio_Key (key);
		return;

	case m_gameplay:
		M_Gameplay_Key (key);
		return;

	case m_credits:
		M_Credits_Key (key);
		return;

	case m_quit:
		M_Quit_Key (key);
		return;

	case m_restart:
		M_Restart_Key (key);
		return;

	case m_exit:
		M_Exit_Key (key);
		return;

	case m_serialconfig:
		M_SerialConfig_Key (key);
		return;

	case m_modemconfig:
		M_ModemConfig_Key (key);
		return;

	case m_lanconfig:
		M_LanConfig_Key (key);
		return;

	case m_gameoptions:
		M_GameOptions_Key (key);
		return;

	case m_search:
		M_Search_Key (key);
		break;


	case m_slist:
		M_ServerList_Key (key);
		return;

	case m_sedit:
		M_SEdit_Key (key);
		break;

	case m_osk:
		M_OSK_Key(key);
	}
}


void M_ConfigureNetSubsystem(void)
{
// enable/disable net systems to match desired config

	Cbuf_AddText ("stopdemo\n");
	if (SerialConfig || DirectConfig)
	{
		Cbuf_AddText ("com1 enable\n");
	}

	if (IPXConfig || TCPIPConfig)
		net_hostport = lanConfig_port;
}

