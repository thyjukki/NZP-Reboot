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

// the status bar is only redrawn if something has changed, but if anything
// does, the entire thing will be redrawn for the next vid.numpages frames.

void HUD_Init (void);

// call whenever any of the client stats represented on the sbar changes

void HUD_Draw (void);
// called every frame by screen

// called each frame after the level has been completed
void HUD_NewMap (void);

extern double HUD_Change_time;



//achievement stuff
#define MAX_ACHIEVEMENTS 3//23
typedef struct achievement_list_s
{
    qpic_t      *img;
    int         unlocked;
    char        name[64];
    char        description[256];
    int         progress;
} achievement_list_t;

void Achievement_Init (void);
extern achievement_list_t achievement_list[MAX_ACHIEVEMENTS];
extern qpic_t *achievement_locked;

void HUD_Parse_Achievement (int ach);
