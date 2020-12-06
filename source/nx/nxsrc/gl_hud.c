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
// gl_hud.c -- status bar code

#include "quakedef.h"

extern cvar_t	waypoint_mode;

qpic_t      *b_up;
qpic_t      *b_down;
qpic_t      *b_left;
qpic_t      *b_right;
qpic_t      *b_lthumb;
qpic_t      *b_rthumb;
qpic_t      *b_lshoulder;
qpic_t      *b_rshoulder;
qpic_t      *b_abutton;
qpic_t      *b_bbutton;
qpic_t      *b_ybutton;
qpic_t      *b_xbutton;
qpic_t      *b_lt;
qpic_t      *b_rt;

qpic_t		*sb_round[5];
qpic_t		*sb_round_num[10];
qpic_t		*sb_moneyback;
qpic_t		*instapic;
qpic_t		*x2pic;
qpic_t 		*revivepic;
qpic_t		*jugpic;
qpic_t		*floppic;
qpic_t		*staminpic;
qpic_t		*doublepic;
qpic_t		*speedpic;
qpic_t		*deadpic;
qpic_t 		*mulepic;
qpic_t		*fragpic;
qpic_t		*bettypic;

qpic_t      *fx_blood_lu;

qboolean 	horizonal_perk_positioning;
qboolean 	rounds_use_tallies;

int old_points;
int current_points;
int point_change_interval;
int point_change_interval_neg;
int alphabling = 0;
float round_center_x;
float round_center_y;

double HUD_Change_time;//hide hud when not chagned

typedef struct
{
	int points;
	int negative;
	float x;
	float y;
	float move_x;
	float move_y;
	double alive_time;
} point_change_t;

int  x_value, y_value;

point_change_t point_change[10];

void HUD_Init (void) {
	int		i;

	for (i=0 ; i<5 ; i++)
	{
		sb_round[i] = Draw_CachePic (va("gfx/hud/r%i.tga",i + 1));
	}

	for (i=0 ; i<10 ; i++)
	{
		sb_round_num[i] = Draw_CachePic (va("gfx/hud/r_num%i.tga",i));
	}

	sb_moneyback = Draw_CachePic ("gfx/hud/moneyback.tga");
	instapic = Draw_CachePic ("gfx/hud/in_kill.tga");
	x2pic = Draw_CachePic ("gfx/hud/2x.tga");

	revivepic = Draw_CachePic ("gfx/hud/revive.tga");
	jugpic = Draw_CachePic ("gfx/hud/jug.tga");
	floppic = Draw_CachePic ("gfx/hud/flopper.tga");
	staminpic = Draw_CachePic ("gfx/hud/stamin.tga");
	doublepic = Draw_CachePic ("gfx/hud/double.tga");
	speedpic = Draw_CachePic ("gfx/hud/speed.tga");
	deadpic = Draw_CachePic ("gfx/hud/dead.tga");
	mulepic = Draw_CachePic ("gfx/hud/mule.tga");
	fragpic = Draw_CachePic ("gfx/hud/frag.tga");
	bettypic = Draw_CachePic ("gfx/hud/betty.tga");

	b_lt = Draw_CachePic ("gfx/butticons/lt.tga");
	b_rt = Draw_CachePic ("gfx/butticons/rt.tga");
	b_lthumb = Draw_CachePic ("gfx/butticons/lthumb.tga");
	b_rthumb = Draw_CachePic ("gfx/butticons/rthumb.tga");
	b_lshoulder = Draw_CachePic ("gfx/butticons/lshoulder.tga");
	b_rshoulder = Draw_CachePic ("gfx/butticons/rshoulder.tga");
	
	b_left = Draw_CachePic ("gfx/butticons/left.tga");
	b_right = Draw_CachePic ("gfx/butticons/right.tga");
	b_up = Draw_CachePic ("gfx/butticons/up.tga");
	b_down = Draw_CachePic ("gfx/butticons/down.tga");
	b_abutton = Draw_CachePic ("gfx/butticons/abutton.tga");
	b_bbutton = Draw_CachePic ("gfx/butticons/bbutton.tga");
	b_ybutton = Draw_CachePic ("gfx/butticons/ybutton.tga");
	b_xbutton = Draw_CachePic ("gfx/butticons/xbutton.tga");

	fx_blood_lu = Draw_CachePic ("gfx/hud/blood.tga");
}

void HUD_UpdateByte(int byte, int data)
{
	switch(byte) {
		case 0:
			if (data >= 1)
				horizonal_perk_positioning = true;
			else
				horizonal_perk_positioning = false;
			break;
		case 1:
			if (data >= 1)
				rounds_use_tallies = true;
			else
				rounds_use_tallies = false;
			break;
		default:
			break;
	}
}

void HUD_UpdateString(int byte, char* data)
{
	switch(byte) {
		case 0:
			revivepic = Draw_CachePic(data);
			break;
		case 1:
			jugpic = Draw_CachePic(data);
			break;
		case 2:
			speedpic = Draw_CachePic(data);
			break;
		case 3:
			doublepic = Draw_CachePic(data);
			break;
		case 4:
			staminpic = Draw_CachePic(data);
			break;
		case 5:
			floppic = Draw_CachePic(data);
			break;
		case 6:
			deadpic = Draw_CachePic(data);
			break;
		case 7:
			mulepic = Draw_CachePic(data);
			break;
		case 8:
			instapic = Draw_CachePic(data);
			break;
		case 9:
			x2pic = Draw_CachePic(data);
			break;
		case 10:
			fx_blood_lu = Draw_CachePic(data);
			break;
		case 11:
			bettypic = Draw_CachePic(data);
			break;
		case 12:
			fragpic = Draw_CachePic(data);
			break;
		case 14:
			sb_moneyback = Draw_CachePic(data);
			break;
		case 15:
			sb_round[0] = Draw_CachePic(data);
			break;
		case 16:
			sb_round[1] = Draw_CachePic(data);
			break;
		case 17:
			sb_round[2] = Draw_CachePic(data);
			break;
		case 18:
			sb_round[3] = Draw_CachePic(data);
			break;
		case 19:
			sb_round[4] = Draw_CachePic(data);
			break;
		case 20:
			sb_round_num[0] = Draw_CachePic(data);
			break;
		case 21:
			sb_round_num[1] = Draw_CachePic(data);
			break;
		case 22:
			sb_round_num[2] = Draw_CachePic(data);
			break;
		case 23:
			sb_round_num[3] = Draw_CachePic(data);
			break;
		case 24:
			sb_round_num[4] = Draw_CachePic(data);
			break;
		case 25:
			sb_round_num[5] = Draw_CachePic(data);
			break;
		case 26:
			sb_round_num[6] = Draw_CachePic(data);
			break;
		case 27:
			sb_round_num[7] = Draw_CachePic(data);
			break;
		case 28:
			sb_round_num[8] = Draw_CachePic(data);
			break;
		case 29:
			sb_round_num[9] = Draw_CachePic(data);
			break;
		default:
			break;
	}
}

/*
===============
HUD_NewMap
===============
*/
void HUD_NewMap (void)
{
	int i;
	alphabling = 0;

	for (i=0 ; i<10 ; i++)
	{
		point_change[i].points = 0;
		point_change[i].negative = 0;
		point_change[i].x = 0.0;
		point_change[i].y = 0.0;
		point_change[i].move_x = 0.0;
		point_change[i].move_y = 0.0;
		point_change[i].alive_time = 0.0;
	}

	old_points = 500;
	current_points = 500;
	point_change_interval = 0;
	point_change_interval_neg = 0;

	round_center_x = (vid.width/2 - sb_round[0]->width) /2;
	round_center_y = vid.height*3/4 - sb_round[0]->height/2;
}


/*
=============
HUD_itoa
=============
*/
int HUD_itoa (int num, char *buf)
{
	char	*str;
	int		pow10;
	int		dig;

	str = buf;

	if (num < 0)
	{
		*str++ = '-';
		num = -num;
	}

	for (pow10 = 10 ; num >= pow10 ; pow10 *= 10)
	;

	do
	{
		pow10 /= 10;
		dig = num/pow10;
		*str++ = '0'+dig;
		num -= dig*pow10;
	} while (pow10 != 1);

	*str = 0;

	return str-buf;
}


//=============================================================================

int		pointsort[MAX_SCOREBOARD];

extern char	scoreboardtext[MAX_SCOREBOARD][20];
extern int		scoreboardtop[MAX_SCOREBOARD];
extern int		scoreboardbottom[MAX_SCOREBOARD];
extern int		scoreboardcount[MAX_SCOREBOARD];
extern int		scoreboardlines;

/*
===============
HUD_Sorpoints
===============
*/
void HUD_Sortpoints (void)
{
	int		i, j, k;

// sort by points
	scoreboardlines = 0;
	for (i=0 ; i<cl.maxclients ; i++)
	{
		if (cl.scores[i].name[0])
		{
			pointsort[scoreboardlines] = i;
			scoreboardlines++;
		}
	}

	for (i=0 ; i<scoreboardlines ; i++)
		for (j=0 ; j<scoreboardlines-1-i ; j++)
			if (cl.scores[pointsort[j]].points < cl.scores[pointsort[j+1]].points)
			{
				k = pointsort[j];
				pointsort[j] = pointsort[j+1];
				pointsort[j+1] = k;
			}
}

/*
===============
HUD_EndScreen
===============
*/
void HUD_EndScreen (void)
{
	scoreboard_t	*s;
	char			str[80];
	int				i, k, l;
	int				y, x, d;

	HUD_Sortpoints ();

	l = scoreboardlines;

	Draw_String ((vid.width/2 - 9*8)/2, vid.height/2 + (vid.height)*40/272, "GAME OVER");

	sprintf (str,"You survived %3i rounds", cl.stats[STAT_ROUNDS]);
	Draw_String ((vid.width/2 - strlen (str)*8)/2, vid.height/2 + (vid.height)*48/272, str);

	sprintf (str,"Name           Kills     Points");
	x = (vid.width/2 - strlen (str)*8)/2;

	Draw_String (x, vid.height/2 + vid.height*68/272, str);
	y = 0;
	for (i=0; i<l ; i++)
	{
		k = pointsort[i];
		s = &cl.scores[k];
		if (!s->name[0])
			continue;

		Draw_String (x, vid.height/2 + vid.height*78/272 + y, s->name);

		d = strlen (va("%i",s->kills));
		Draw_String (x + (20 - d)*8, vid.height/2 + (vid.height)*78/272 + y, va("%i",s->kills));

		d = strlen (va("%i",s->points));
		Draw_String (x + (31 - d)*8, vid.height/2 + (vid.height)*78/272 + y, va("%i",s->points));
		y += 20;
	}

}


//=============================================================================


/*
==================
HUD_Points

==================
*/


void HUD_Parse_Point_Change (int points, int negative, int x_start, int y_start)
{
	int i, f;
	char str[10];
	i=9;
	while (i>0)
	{
		point_change[i] = point_change[i - 1];
		i--;
	}

	point_change[i].points = points;
	point_change[i].negative = negative;

	f = HUD_itoa (points, str);
	point_change[i].x = x_start - 10.0 - 8.0*f;
	point_change[i].y = y_start;
	point_change[i].move_x = 1.0;
	point_change[i].move_y = ((rand ()&0x7fff) / ((float)0x7fff)) - 0.5;

	point_change[i].alive_time = Sys_DoubleTime() + 0.4;
}

void HUD_Points (void)
{
	int				i, k, l;
	int				x, y, f, xplus;
	scoreboard_t	*s;
	char str[12];

// scores
	HUD_Sortpoints ();

// draw the text
	l = scoreboardlines;


    x = vid.width/2 - sb_moneyback->width;
    y = vid.height - 16 - fragpic->height - 4 - 16 - sb_moneyback->height;
	for (i=0 ; i<l ; i++)
	{
		k = pointsort[i];
		s = &cl.scores[k];
		if (!s->name[0])
			continue;

	// draw background

	// draw number
		f = s->points;
		if (f > current_points)
		{
			point_change_interval_neg = 0;
			if (!point_change_interval)
			{
				point_change_interval = (int)(f - old_points)/55;;
			}
			current_points = old_points + point_change_interval;
			if (f < current_points)
			{
				current_points = f;
				point_change_interval = 0;
			}
		}
		else if (f < current_points)
		{
			point_change_interval = 0;
			if (!point_change_interval_neg)
			{
				point_change_interval_neg = (int)(old_points - f)/55;
			}
			current_points = old_points - point_change_interval_neg;
			if (f > current_points)
			{
				current_points = f;
				point_change_interval_neg = 0;
			}
		}
		Draw_Pic (x, y, sb_moneyback);
		xplus = HUD_itoa (f, str);
		Draw_String (vid.width/2 - (xplus*8) - 16, y + 3, va("%i", current_points));

		if (old_points != f)
		{
			if (f > old_points)
				HUD_Parse_Point_Change(f - old_points, 0, vid.width/2 - (xplus*8) - 16, y + 3);
			else
				HUD_Parse_Point_Change(old_points - f, 1, vid.width/2 - (xplus*8) - 16, y + 3);

			old_points = f;
		}



		y += 10;
	}
}


/*
==================
HUD_Point_Change

==================
*/
void HUD_Point_Change (void)
{
	int	i;

	for (i=0 ; i<10 ; i++)
	{
		if (point_change[i].points)
		{
			if (point_change[i].negative)
				Draw_ColoredString (point_change[i].x, point_change[i].y, va ("-%i", point_change[i].points), 1, 0, 0, 1);
			else
				Draw_ColoredString (point_change[i].x, point_change[i].y, va ("+%i", point_change[i].points), 1, 1, 0, 1);
			point_change[i].y = point_change[i].y + point_change[i].move_y;
			point_change[i].x = point_change[i].x - point_change[i].move_x;
			if (point_change[i].alive_time && point_change[i].alive_time < Sys_DoubleTime())
			{
				point_change[i].points = 0;
				point_change[i].negative = 0;
				point_change[i].x = 0.0;
				point_change[i].y = 0.0;
				point_change[i].move_x = 0.0;
				point_change[i].move_y = 0.0;
				point_change[i].alive_time = 0.0;
			}
		}
	}
}

/*
==================
HUD_Blood

==================
*/
void HUD_Blood (void)
{
    float alpha;
	//blubswillrule:
	//this function scales linearly from health = 0 to health = 100
	//alpha = (100.0 - (float)cl.stats[STAT_HEALTH])/100*255;
	//but we want the picture to be fully visible at health = 20, so use this function instead
	alpha = (100.0 - ((1.25 * (float) cl.stats[STAT_HEALTH]) - 25))/100;

    if (alpha <= 0.0)
        return;
    
    float modifier = (sin(cl.time * 10) * 20) - 20;//always negative
    if(modifier < -35.0)
	modifier = -35.0;
    
    alpha += (modifier/255);

    if (alpha > 1) {
    	alpha = 1;
    }
    
    if(alpha < 0.0)
	    return;
    
    Draw_AlphaPic (0, vid.height/2, fx_blood_lu, alpha);
}

//=============================================================================

/*
===============
HUD_Rounds
===============
*/

float 	color_shift[3];
float 	color_shift_end[3];
float 	color_shift_steps[3];
int		color_shift_init;
float 	blinking;
void HUD_Rounds (void)
{
	int i, x_offset, icon_num, savex;
	int num[3];
	x_offset = 0;
	savex = 0;

	if (cl.stats[STAT_ROUNDCHANGE] == 1)//this is the rounds icon at the middle of the screen
	{
		if (rounds_use_tallies)
			Draw_ColorPic ((vid.width/2 - sb_round[0]->width) /2, vid.height*3/4 - sb_round[0]->height/2, sb_round[0], 0.4196, 0.004, 0, alphabling/255);
		else
			Draw_ColorPic ((vid.width/2 - sb_round_num[1]->width) /2, vid.height*3/4 - sb_round_num[1]->height/2, sb_round_num[1], 0.4196, 0.004, 0, alphabling/255);

		alphabling = alphabling + 15;

		if (alphabling < 0)
			alphabling = 0;
		else if (alphabling > 255)
			alphabling = 255;
	}
	else if (cl.stats[STAT_ROUNDCHANGE] == 2)//this is the rounds icon moving from middle
	{
		if (rounds_use_tallies)
			Draw_ColorPic (round_center_x, round_center_y, sb_round[0], 0.4196, 0.004, 0, 1);
		else
			Draw_ColorPic (round_center_x, round_center_y, sb_round_num[1], 0.4196, 0.004, 0, 1);
		round_center_x = round_center_x - ((229/108)*2 - 0.2)*(vid.width/2)/480;
		round_center_y = round_center_y + ((vid.height*1.015)/272);
		if (round_center_x <= 5)
			round_center_x = 5;
		if (round_center_y >= 250*vid.height/272)
			round_center_y = 250*vid.height/272;
	}
	else if (cl.stats[STAT_ROUNDCHANGE] == 3)//shift to white
	{
		if (!color_shift_init)
		{
			color_shift[0] = 107;
			color_shift[1] = 1;
			color_shift[2] = 0;
			for (i = 0; i < 3; i++)
			{
				color_shift_end[i] = 255;
				color_shift_steps[i] = (color_shift_end[i] - color_shift[i])/60;
			}
			color_shift_init = 1;
		}
		for (i = 0; i < 3; i++)
		{
			if (color_shift[i] < color_shift_end[i])
				color_shift[i] = color_shift[i] + color_shift_steps[i];

			if (color_shift[i] >= color_shift_end[i])
				color_shift[i] = color_shift_end[i];
		}
		if (cl.stats[STAT_ROUNDS] > 0 && cl.stats[STAT_ROUNDS] < 11)
		{
			if (rounds_use_tallies) {
				for (i = 0; i < cl.stats[STAT_ROUNDS]; i++)
				{
					if (i == 4)
					{
						Draw_ColorPic (5*(vid.width/2)/272, vid.height - sb_round[4]->height - 4, sb_round[4], (color_shift[0]/255), (color_shift[1]/255), (color_shift[2]/255), 1);
						savex = x_offset + 10;
						x_offset = x_offset + 10;
						continue;
					}
					if (i == 9)
					{
						Draw_ColorPic ((5 + savex/2)*(vid.width/2)/272, vid.height - sb_round[4]->height - 4, sb_round[4], (color_shift[0]/255), (color_shift[1]/255), (color_shift[2]/255), 1);
						continue;
					}
					if (i > 4)
						icon_num = i - 5;
					else
						icon_num = i;

					Draw_ColorPic ((5 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round[icon_num]->height - 4, sb_round[icon_num], (color_shift[0]/255), (color_shift[1]/255), (color_shift[2]/255), 1);

					x_offset = x_offset + sb_round[icon_num]->width + 3;
				}
			} else {
				Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[cl.stats[STAT_ROUNDS]]->height - 4, sb_round_num[cl.stats[STAT_ROUNDS]], (color_shift[0]/255), (color_shift[1]/255), (color_shift[2]/255), 1);
			}
			
		}
		else
		{
			if (cl.stats[STAT_ROUNDS] >= 100)
			{
				num[2] = (int)(cl.stats[STAT_ROUNDS]/100);
				Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[num[2]]->height - 4, sb_round_num[num[2]], (color_shift[0]/255), (color_shift[1]/255), (color_shift[2]/255), 1);
				x_offset = x_offset + sb_round_num[num[2]]->width - 8;
			}
			else
				num[2] = 0;
			if (cl.stats[STAT_ROUNDS] >= 10)
			{
				num[1] = (int)((cl.stats[STAT_ROUNDS] - num[2]*100)/10);
				Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[num[1]]->height - 4, sb_round_num[num[1]], (color_shift[0]/255), (color_shift[1]/255), (color_shift[2]/255), 1);
				x_offset = x_offset + sb_round_num[num[1]]->width - 8;
			}
			else
				num[1] = 0;

			num[0] = cl.stats[STAT_ROUNDS] - num[2]*100 - num[1]*10;
			Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[num[0]]->height - 4, sb_round_num[num[0]], (color_shift[0]/255), (color_shift[1]/255), (color_shift[2]/255), 1);
			x_offset = x_offset + sb_round_num[num[0]]->width - 8;
		}
	}
	else if (cl.stats[STAT_ROUNDCHANGE] == 4)//blink white
	{
		blinking = (float)(((int)(realtime*1000)&510) - 255);
		blinking = abs(blinking);
		if (cl.stats[STAT_ROUNDS] > 0 && cl.stats[STAT_ROUNDS] < 11)
		{
			if (rounds_use_tallies) {
				for (i = 0; i < cl.stats[STAT_ROUNDS]; i++)
				{
					if (i == 4)
					{
						Draw_ColorPic (5*(vid.width/2)/272, vid.height - sb_round[4]->height - 4, sb_round[4], 1, 1, 1, blinking/255);
						savex = x_offset + 10;
						x_offset = x_offset + 10;
						continue;
					}
					if (i == 9)
					{
						Draw_ColorPic ((5 + savex/2)*(vid.width/2)/272, vid.height - sb_round[4]->height - 4, sb_round[4], 1, 1, 1, blinking/255);
						continue;
					}
					if (i > 4)
						icon_num = i - 5;
					else
						icon_num = i;

					Draw_ColorPic ((5 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round[icon_num]->height - 4, sb_round[icon_num], 1, 1, 1, blinking/255);

					x_offset = x_offset + sb_round[icon_num]->width + 3;
				}
			} else {
				Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[cl.stats[STAT_ROUNDS]]->height - 4, sb_round_num[cl.stats[STAT_ROUNDS]], 1, 1, 1, blinking/255);
			}
		}
		else
		{
			if (cl.stats[STAT_ROUNDS] >= 100)
			{
				num[2] = (int)(cl.stats[STAT_ROUNDS]/100);
				Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[num[2]]->height - 4, sb_round_num[num[2]], 1, 1, 1, blinking/255);
				x_offset = x_offset + sb_round_num[num[2]]->width - 8;
			}
			else
				num[2] = 0;
			if (cl.stats[STAT_ROUNDS] >= 10)
			{
				num[1] = (int)((cl.stats[STAT_ROUNDS] - num[2]*100)/10);
				Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[num[1]]->height - 4, sb_round_num[num[1]], 1, 1, 1, blinking/255);
				x_offset = x_offset + sb_round_num[num[1]]->width - 8;
			}
			else
				num[1] = 0;

			num[0] = cl.stats[STAT_ROUNDS] - num[2]*100 - num[1]*10;
			Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[num[0]]->height - 4, sb_round_num[num[0]], 1, 1, 1, blinking/255);
			x_offset = x_offset + sb_round_num[num[0]]->width - 8;
		}
	}
	else if (cl.stats[STAT_ROUNDCHANGE] == 5)//blink white
	{
		if (blinking > 0)
			blinking = blinking - 10;
		if (blinking < 0)
			blinking = 0;
		if (cl.stats[STAT_ROUNDS] > 0 && cl.stats[STAT_ROUNDS] < 11)
		{
			if (rounds_use_tallies) {
				for (i = 0; i < cl.stats[STAT_ROUNDS]; i++)
				{
					if (i == 4)
					{
						Draw_ColorPic (5*(vid.width/2)/272, vid.height - sb_round[4]->height - 4, sb_round[4], 1, 1, 1, blinking/255);
						savex = x_offset + 10;
						x_offset = x_offset + 10;
						continue;
					}
					if (i == 9)
					{
						Draw_ColorPic ((5 + savex/2)*(vid.width/2)/272, vid.height - sb_round[4]->height - 4, sb_round[4], 1, 1, 1, blinking/255);
						continue;
					}
					if (i > 4)
						icon_num = i - 5;
					else
						icon_num = i;

					Draw_ColorPic ((5 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round[icon_num]->height - 4, sb_round[icon_num], 1, 1, 1, blinking/255);

					x_offset = x_offset + sb_round[icon_num]->width + 3;
				}
			} else {
				Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[cl.stats[STAT_ROUNDS]]->height - 4, sb_round_num[cl.stats[STAT_ROUNDS]], 1, 1, 1, blinking/255);
			}
			
		}
		else
		{
			if (cl.stats[STAT_ROUNDS] >= 100)
			{
				num[2] = (int)(cl.stats[STAT_ROUNDS]/100);
				Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[num[2]]->height - 4, sb_round_num[num[2]], 1, 1, 1, blinking/255);
				x_offset = x_offset + sb_round_num[num[2]]->width - 8;
			}
			else
				num[2] = 0;
			if (cl.stats[STAT_ROUNDS] >= 10)
			{
				num[1] = (int)((cl.stats[STAT_ROUNDS] - num[2]*100)/10);
				Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[num[1]]->height - 4, sb_round_num[num[1]], 1, 1, 1, blinking/255);
				x_offset = x_offset + sb_round_num[num[1]]->width - 8;
			}
			else
				num[1] = 0;

			num[0] = cl.stats[STAT_ROUNDS] - num[2]*100 - num[1]*10;
			Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[num[0]]->height - 4, sb_round_num[num[0]], 1, 1, 1, blinking/255);
			x_offset = x_offset + sb_round_num[num[0]]->width - 8;
		}
	}
	else if (cl.stats[STAT_ROUNDCHANGE] == 6)//blink white while fading back
	{
		color_shift_init = 0;
		blinking = ((int)(realtime*1000)&510) - 255;
		blinking = abs(blinking);
		if (cl.stats[STAT_ROUNDS] > 0 && cl.stats[STAT_ROUNDS] < 11)
		{
			if (rounds_use_tallies) {
				for (i = 0; i < cl.stats[STAT_ROUNDS]; i++)
				{
					if (i == 4)
					{
						Draw_ColorPic (5*(vid.width/2)/272, vid.height - sb_round[4]->height - 4, sb_round[4], 1, 1, 1, blinking/255);
						savex = x_offset + 10;
						x_offset = x_offset + 10;
						continue;
					}
					if (i == 9)
					{
						Draw_ColorPic ((5 + savex/2)*(vid.width/2)/272, vid.height - sb_round[4]->height - 4, sb_round[4], 1, 1, 1, blinking/255);
						continue;
					}
					if (i > 4)
						icon_num = i - 5;
					else
						icon_num = i;

					Draw_ColorPic ((5 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round[icon_num]->height - 4, sb_round[icon_num], 1, 1, 1, blinking/255);

					x_offset = x_offset + sb_round[icon_num]->width + 3;
				}
			} else {
				Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[cl.stats[STAT_ROUNDS]]->height - 4, sb_round_num[cl.stats[STAT_ROUNDS]], 1, 1, 1, blinking/255);
			}
			
		}
		else
		{
			if (cl.stats[STAT_ROUNDS] >= 100)
			{
				num[2] = (int)(cl.stats[STAT_ROUNDS]/100);
				Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[num[2]]->height - 4, sb_round_num[num[2]], 1, 1, 1, blinking/255);
				x_offset = x_offset + sb_round_num[num[2]]->width - 8;
			}
			else
				num[2] = 0;
			if (cl.stats[STAT_ROUNDS] >= 10)
			{
				num[1] = (int)((cl.stats[STAT_ROUNDS] - num[2]*100)/10);
				Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[num[1]]->height - 4, sb_round_num[num[1]], 1, 1, 1, blinking/255);
				x_offset = x_offset + sb_round_num[num[1]]->width - 8;
			}
			else
				num[1] = 0;

			num[0] = cl.stats[STAT_ROUNDS] - num[2]*100 - num[1]*10;
			Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[num[0]]->height - 4, sb_round_num[num[0]], 1, 1, 1, blinking/255);
			x_offset = x_offset + sb_round_num[num[0]]->width - 8;
		}
	}
	else if (cl.stats[STAT_ROUNDCHANGE] == 7)//blink white while fading back
	{
		if (!color_shift_init)
		{
			color_shift_end[0] = 107;
			color_shift_end[1] = 1;
			color_shift_end[2] = 0;
			for (i = 0; i < 3; i++)
			{
				color_shift[i] = 255;
				color_shift_steps[i] = (color_shift[i] - color_shift_end[i])/60;
			}
			color_shift_init = 1;
		}
		for (i = 0; i < 3; i++)
		{
			if (color_shift[i] > color_shift_end[i])
				color_shift[i] = color_shift[i] - color_shift_steps[i];

			if (color_shift[i] < color_shift_end[i])
				color_shift[i] = color_shift_end[i];
		}
		if (cl.stats[STAT_ROUNDS] > 0 && cl.stats[STAT_ROUNDS] < 11)
		{
			if (rounds_use_tallies) {
				for (i = 0; i < cl.stats[STAT_ROUNDS]; i++)
				{
					if (i == 4)
					{
						Draw_ColorPic (5*(vid.width/2)/272, vid.height - sb_round[4]->height - 4, sb_round[4], (color_shift[0]/255), (color_shift[1]/255), (color_shift[2]/255), 1);
						savex = x_offset + 10;
						x_offset = x_offset + 10;
						continue;
					}
					if (i == 9)
					{
						Draw_ColorPic ((5 + savex/2)*(vid.width/2)/272, vid.height - sb_round[4]->height - 4, sb_round[4], (color_shift[0]/255), (color_shift[1]/255), (color_shift[2]/255), 1);
						continue;
					}
					if (i > 4)
						icon_num = i - 5;
					else
						icon_num = i;

					Draw_ColorPic ((5 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round[icon_num]->height - 4, sb_round[icon_num], (color_shift[0]/255), (color_shift[1]/255), (color_shift[2]/255), 1);

					x_offset = x_offset + sb_round[icon_num]->width + 3;
				}
			} else {
				Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[cl.stats[STAT_ROUNDS]]->height - 4, sb_round_num[cl.stats[STAT_ROUNDS]], (color_shift[0]/255), (color_shift[1]/255), (color_shift[2]/255), 1);
			}
		}
		else
		{
			if (cl.stats[STAT_ROUNDS] >= 100)
			{
				num[2] = (int)(cl.stats[STAT_ROUNDS]/100);
				Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[num[2]]->height - 4, sb_round_num[num[2]], (color_shift[0]/255), (color_shift[1]/255), (color_shift[2]/255), 1);
				x_offset = x_offset + sb_round_num[num[2]]->width - 8;
			}
			else
				num[2] = 0;
			if (cl.stats[STAT_ROUNDS] >= 10)
			{
				num[1] = (int)((cl.stats[STAT_ROUNDS] - num[2]*100)/10);
				Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[num[1]]->height - 4, sb_round_num[num[1]], (color_shift[0]/255), (color_shift[1]/255), (color_shift[2]/255), 1);
				x_offset = x_offset + sb_round_num[num[1]]->width - 8;
			}
			else
				num[1] = 0;

			num[0] = cl.stats[STAT_ROUNDS] - num[2]*100 - num[1]*10;
			Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[num[0]]->height - 4, sb_round_num[num[0]], (color_shift[0]/255), (color_shift[1]/255), (color_shift[2]/255), 1);
			x_offset = x_offset + sb_round_num[num[0]]->width - 8;
		}
	}
	else
	{
		color_shift[0] = 107;
		color_shift[1] = 1;
		color_shift[2] = 0;
		color_shift_init = 0;
		alphabling = 0;
		if (cl.stats[STAT_ROUNDS] > 0 && cl.stats[STAT_ROUNDS] < 11)
		{
			if (rounds_use_tallies) {
				for (i = 0; i < cl.stats[STAT_ROUNDS]; i++)
				{
					if (i == 4)
					{
						Draw_ColorPic (5*(vid.width/2)/272, vid.height - sb_round[4]->height - 4, sb_round[4], 0.4196, 0.004, 0, 1);
						savex = x_offset + 10;
						x_offset = x_offset + 10;
						continue;
					}
					if (i == 9)
					{
						Draw_ColorPic ((5 + savex/2)*(vid.width/2)/272, vid.height - sb_round[4]->height - 4, sb_round[4], 0.4196, 0.004, 0, 1);
						continue;
					}
					if (i > 4)
						icon_num = i - 5;
					else
						icon_num = i;

					Draw_ColorPic ((5 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round[icon_num]->height - 4, sb_round[icon_num], 0.4196, 0.004, 0, 1);

					x_offset = x_offset + sb_round[icon_num]->width + 3;
				}
			} else {
				Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[cl.stats[STAT_ROUNDS]]->height - 4, sb_round_num[cl.stats[STAT_ROUNDS]], 0.4196, 0.004, 0, 1);
			}
			
		}
		else
		{
			if (cl.stats[STAT_ROUNDS] >= 100)
			{
				num[2] = (int)(cl.stats[STAT_ROUNDS]/100);
				Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[num[2]]->height - 4, sb_round_num[num[2]], 0.4196, 0.004, 0, 1);
				x_offset = x_offset + sb_round_num[num[2]]->width - 8;
			}
			else
				num[2] = 0;
			if (cl.stats[STAT_ROUNDS] >= 10)
			{
				num[1] = (int)((cl.stats[STAT_ROUNDS] - num[2]*100)/10);
				Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[num[1]]->height - 4, sb_round_num[num[1]], 0.4196, 0.004, 0, 1);
				x_offset = x_offset + sb_round_num[num[1]]->width - 8;
			}
			else
				num[1] = 0;

			num[0] = cl.stats[STAT_ROUNDS] - num[2]*100 - num[1]*10;
			
			if(cl.stats[STAT_ROUNDS] == 0)
				return;
			
			Draw_ColorPic ((2 + x_offset/2)*(vid.width/2)/272, vid.height - sb_round_num[num[0]]->height - 4, sb_round_num[num[0]], 0.4196, 0.004, 0, 1);
			x_offset = x_offset + sb_round_num[num[0]]->width - 8;
		}
	}
}

//=============================================================================

/*
===============
HUD_Perks
===============
*/
#define 	P_JUG		1
#define 	P_DOUBLE	2
#define 	P_SPEED		4
#define 	P_REVIVE	8
#define 	P_FLOP		16
#define 	P_STAMIN	32
#define 	P_DEAD 		64
#define 	P_MULE 		128

int perk_order[9];
int current_perk_order;

void HUD_Perks (void)
{
	int i;
	int x;
	int y;
	x = 2;
	y = vid.height - sb_round[1]->height - jugpic->height - 14;

	for (i = 0; i < 9; i++)
	{
		if (perk_order[i])
		{
			if (perk_order[i] == P_JUG)
			{
				Draw_Pic (x, y, jugpic);
				if (horizonal_perk_positioning)
					x = x + 34;
				else
					y = y - 34;
			}
			else if (perk_order[i] == P_DOUBLE)
			{
				Draw_Pic (x, y, doublepic);
				if (horizonal_perk_positioning)
					x = x + 34;
				else
					y = y - 34;
			}
			else if (perk_order[i] == P_SPEED)
			{
				Draw_Pic (x, y, speedpic);
				if (horizonal_perk_positioning)
					x = x + 34;
				else
					y = y - 34;
			}
			else if (perk_order[i] == P_REVIVE)
			{
				Draw_Pic (x, y, revivepic);
				if (horizonal_perk_positioning)
					x = x + 34;
				else
					y = y - 34;
			}
			else if (perk_order[i] == P_FLOP)
			{
				Draw_Pic (x, y, floppic);
				if (horizonal_perk_positioning)
					x = x + 34;
				else
					y = y - 34;
			}
			else if (perk_order[i] == P_STAMIN)
			{
				Draw_Pic (x, y, staminpic);
				if (horizonal_perk_positioning)
					x = x + 34;
				else
					y = y - 34;
			}
			else if (perk_order[i] == P_DEAD)
			{
				Draw_Pic (x, y, deadpic);
				if (horizonal_perk_positioning)
					x = x + 34;
				else
					y = y - 34;
			}
			else if (perk_order[i] == P_MULE)
			{
				Draw_Pic (x, y, mulepic);
				if (horizonal_perk_positioning)
					x = x + 34;
				else
					y = y - 34;
			}
		}
	}
}

//=============================================================================

/*
===============
HUD_Powerups
===============
*/
void HUD_Powerups (void)
{
	if(cl.stats[STAT_X2])
		Draw_Pic ((vid.width/4) - 32, vid.height/2, x2pic);
	if(cl.stats[STAT_INSTA])
		Draw_Pic ((vid.width/4) + 2, vid.height/2, instapic);
}

//=============================================================================


/*
===============
HUD_ProgressBar
===============
*/
void HUD_ProgressBar (void)
{
	float progressbar;

	if (cl.progress_bar)
	{
		progressbar = 100 - ((cl.progress_bar-sv.time)*10);
		if (progressbar >= 100)
			progressbar = 100;
		Draw_FillByColor  ((vid.width)/4 - 51, vid.height/2 + (vid.height/2)*0.75 - 1, 102, 5, 0, 100/255.0);
		Draw_FillByColor ((vid.width)/4 - 50, vid.height/2 + (vid.height/2)*0.75, progressbar, 3, 1, 100/255.0);

		Draw_String ((vid.width/2 - (88))/2, vid.height/2 + (vid.height/2)*0.75 + 10, "Reviving...");
	}
}

//=============================================================================


/*
===============
HUD_Ammo
===============
*/

int GetLowAmmo(int weapon, int type)
{
	switch (weapon)
	{
		case W_COLT: if (type) return 2; else return 16;
		case W_KAR: if (type) return 1; else return 10;
		case W_KAR_SCOPE: if (type) return 1; else return 10;
		case W_M1A1: if (type) return 4; else return 24;
		case W_SAWNOFF: if (type) return 1; else return 12;
		case W_DB: if (type) return 1; else return 12;
		case W_THOMPSON: if (type) return 6; else return 40;
		case W_BAR: if (type) return 6; else return 28;
		default: return 0;
	}
}

int IsDualWeapon(int weapon)
{
	switch(weapon) {
		case W_BIATCH:
		case W_SNUFF:
			return 1;
		default:
			return 0;
	}

	return 0;
}


void HUD_Ammo (void)
{
	char str[12];
	char str2[12];
    int xplus, xplus2;
	char *magstring;
	char *mag2string;

	y_value = vid.height - 16;
	if (GetLowAmmo(cl.stats[STAT_ACTIVEWEAPON], 1) >= cl.stats[STAT_CURRENTMAG])
		magstring = va ("%i",cl.stats[STAT_CURRENTMAG]);
	else
		magstring = va ("%i",cl.stats[STAT_CURRENTMAG]);

	xplus = HUD_itoa (cl.stats[STAT_CURRENTMAG], str);
	Draw_ColoredString (vid.width/2 - 42 - (xplus*8), y_value, magstring, 1, 1, 1, 1);

	mag2string = va("%i", cl.stats[STAT_CURRENTMAG2]);
	xplus2 = HUD_itoa (cl.stats[STAT_CURRENTMAG2], str2);

	if (IsDualWeapon(cl.stats[STAT_ACTIVEWEAPON])) {
		Draw_ColoredString (vid.width/2 - 56 - (xplus2*8), y_value, mag2string, 1, 1, 1, 1);
	}

	if (GetLowAmmo(cl.stats[STAT_ACTIVEWEAPON], 0) >= cl.stats[STAT_AMMO])
	{
		Draw_ColoredString (vid.width/2 - 42, y_value, "/", 1, 0, 0, 1);
		Draw_ColoredString (vid.width/2 - 34, y_value, va ("%i",cl.stats[STAT_AMMO]), 1, 0, 0, 1);
	}
	else
	{
		Draw_Character (vid.width/2 - 42, y_value, '/');
		Draw_String (vid.width/2 - 34, y_value, va ("%i",cl.stats[STAT_AMMO]));
	}
}

/*
===============
HUD_AmmoString
===============
*/

void HUD_AmmoString (void)
{
	int len = 0;
	
	if (GetLowAmmo(cl.stats[STAT_ACTIVEWEAPON], 1) >= cl.stats[STAT_CURRENTMAG])
	{
		if (0 < cl.stats[STAT_AMMO] && cl.stats[STAT_CURRENTMAG] >= 0) {
			Draw_String ((vid.width)/4, (vid.height)*3/4 + 40, "Reload");
		} else if (0 < cl.stats[STAT_CURRENTMAG]) {
			Draw_ColoredString ((vid.width/2 - len*8)/2, (vid.height)*3/4 + 40, "LOW AMMO", 1, 1, 0, 1);
		} else {
			Draw_ColoredString ((vid.width/2 - len*8)/2, (vid.height)*3/4 + 40, "NO AMMO", 1, 0, 0, 1);
		}
	}

}

//=============================================================================

/*
===============
HUD_Grenades
===============
*/
#define 	UI_FRAG		1
#define 	UI_BETTY	2

void HUD_Grenades (void)
{
	if (cl.stats[STAT_GRENADES])
	{	
		x_value = vid.width/2 - 50;
		y_value = vid.height - 16 - fragpic->height - 4;
	}
	if (cl.stats[STAT_GRENADES] & UI_FRAG)
	{
		Draw_Pic (x_value, y_value, fragpic);
		if (cl.stats[STAT_PRIGRENADES] <= 0)
			Draw_ColoredString (x_value + 24, y_value + 28, va ("%i",cl.stats[STAT_PRIGRENADES]), 1, 0, 0, 1);
		else
			Draw_String (x_value + 24, y_value + 28, va ("%i",cl.stats[STAT_PRIGRENADES]));
	}
	if (cl.stats[STAT_GRENADES] & UI_BETTY)
	{
		Draw_Pic (x_value - fragpic->width - 5, y_value, bettypic);
		if (cl.stats[STAT_PRIGRENADES] <= 0) {
			Draw_ColoredString (x_value + 24, y_value + 28, va ("%i",cl.stats[STAT_SECGRENADES]), 1, 0, 0, 1);
		} else {
			Draw_String (x_value - fragpic->width + 20, y_value + 28, va ("%i",cl.stats[STAT_SECGRENADES]));
		}
	}
}

//=============================================================================

/*
===============
HUD_Weapon
===============
*/


char *GetWeaponName (int wep)
{
	switch (wep)
	{
		case W_COLT:
			return "Colt M1911";
		case W_BIATCH:
      		return "Mustang & Sally";
		case W_KAR:
			return "Kar 98k";
    	case W_ARMAGEDDON:
			return "Armageddon";
		case W_THOMPSON:
			return "Thompson";
		case W_GIBS:
			return "Gibs-O-Matic";
		case W_357:
			return ".357 Magnum";
		case W_KILLU:
			return ".357 Plus 1 K1L-u";
		case W_BAR:
			return "BAR";
		case W_WIDOW:
			return "The Widow Maker";
		case W_BK:
			return "Ballistic Knife";
		case W_BROWNING:
			return "Browning M1919";
		case W_ACCELERATOR:
			return "B115 Accelerator";
		case W_DB:
			return "Double-Barreled Shotgun";
		case W_BORE:
			return "24 Bore Long Range";
		case W_FG:
			return "FG42";
		case W_IMPELLER:
			return "420 Impeller";
		case W_GEWEHR:
			return "Gewehr 43";
		case W_COMPRESSOR:
			return "G115 Compressor";
		case W_KAR_SCOPE:
			return "Scoped Kar 98k";
		case W_HEADCRACKER:
			return "Headcracker";
		case W_M1:
			return "M1 Garand";
		case W_M1000:
			return "M1000";
		case W_M1A1:
			return "M1A1 Carbine";
		case W_WIDDER:
			return "Widdershins RC-1";
		case W_M2:
			return "M2 Flamethrower";
		case W_FIW:
			return "F1W Nitrogen Cooled";
		case W_MP40:
			return "MP40";
		case W_AFTERBURNER:
			return "The Afterburner";
		case W_MG:
			return "MG42";
		case W_BARRACUDA:
			return "Barracuda FU-A11";
		case W_PANZER:
			return "Panzerschrek";
		case W_LONGINUS:
			return "Longinus";
		case W_PPSH:
			return "PPSh-41";
		case W_REAPER:
			return "The Reaper";
		case W_PTRS:
			return "PTRS-41";
		case W_PENETRATOR:
			return "The Penetrator";
		case W_RAY:
			return "Ray Gun";
		case W_PORTER:
			return "Porter's X2 Ray Gun";
		case W_SAWNOFF:
			return "Sawnoff shotgun";
		case W_SNUFF:
			return "The Snuff Box";
		case W_STG:
			return "STG-44";
		case W_SPATZ:
			return "Spatz-447 +";
		case W_TRENCH:
			return "M1897 Trench Gun";
		case W_GUT:
			return "Gut Shot";
		case W_TYPE:
			return "Type 100";
		case W_SAMURAI:
			return "1001 Samurais";
    	case W_TESLA:
      		return "Wunderwaffe DG-2";
		default:
			return " ";
	}
}

void HUD_Weapon (void)
{
	char str[32];
	float l;
	y_value = vid.height - 16 - fragpic->height - 4 - 16;

	strcpy(str, GetWeaponName(cl.stats[STAT_ACTIVEWEAPON]));
	l = strlen(str);

	x_value = vid.width/2 - 8 - l*8;
	Draw_String (x_value, y_value, str);
}

//=============================================================================


void HUD_Draw (void) {
	if (key_dest == key_menu_pause) {
		return;
	}

	GL_SetCanvas(CANVAS_USEPRINT);

	if (waypoint_mode.value) {
		Draw_String (vid.width/2 - 112, vid.height/2 + 0, "WAYPOINTMODE");
		Draw_String (vid.width/2 - 240, vid.height/2 + 8, "Press fire to create waypoint");
		Draw_String (vid.width/2 - 232, vid.height/2 + 16, "Press use to select waypoint");
		Draw_String (vid.width/2 - 216, vid.height/2 + 24, "Press aim to link waypoint");
		Draw_String (vid.width/2 - 248, vid.height/2 + 32, "Press knife to remove waypoint");
		Draw_String (vid.width/2 - 272, vid.height/2 + 40, "Press switch to move waypoint here");
		Draw_String (vid.width/2 - 304, vid.height/2 + 48, "Press reload to make special waypoint");
		GL_SetCanvas (CANVAS_DEFAULT);
		return;
	}

	if (cl.stats[STAT_HEALTH] <= 0)
	{
		HUD_EndScreen ();
		GL_SetCanvas(CANVAS_DEFAULT);
		return;
	}

	HUD_Blood(); 
	HUD_Rounds();
	HUD_Perks();
	HUD_Powerups();
	HUD_ProgressBar();
	if ((HUD_Change_time > Sys_DoubleTime() || GetLowAmmo(cl.stats[STAT_ACTIVEWEAPON], 1) >= cl.stats[STAT_CURRENTMAG] || GetLowAmmo(cl.stats[STAT_ACTIVEWEAPON], 0) >= cl.stats[STAT_AMMO]) && cl.stats[STAT_HEALTH] >= 20)
	{ //these elements are only drawn when relevant for few seconds
		HUD_Ammo();
		HUD_Grenades();
		HUD_Weapon();
		HUD_AmmoString();
	}
	HUD_Points();
	HUD_Point_Change();
/*
	HUD_Achievement();
*/

	GL_SetCanvas(CANVAS_DEFAULT);
}