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
// cl.input.c  -- builds an intended movement command to send to the server

// Quake is a trademark of Id Software, Inc., (c) 1996 Id Software, Inc. All
// rights reserved.

#include "quakedef.h"

/*
===============================================================================

KEY BUTTONS

Continuous button event tracking is complicated by the fact that two different
input sources (say, mouse button 1 and the control key) can both press the
same button, but the button should only be released when both of the
pressing key have been released.

When a key event issues a button command (+forward, +attack, etc), it appends
its key number as a parameter to the command so it can be matched up with
the release.

state bit 0 is the current state of the key
state bit 1 is edge triggered on the up to down transition
state bit 2 is edge triggered on the down to up transition

===============================================================================
*/


kbutton_t	in_klook;//Heffo - mlook cvar
kbutton_t	in_left, in_right, in_forward, in_back;
kbutton_t	in_lookup, in_lookdown, in_moveleft, in_moveright;
kbutton_t	in_strafe, in_speed, in_use, in_jump, in_attack, in_grenade, in_reload, in_switch, in_knife, in_aim;
kbutton_t	in_up, in_down;

int			in_impulse;



void KeyDown (kbutton_t *b)
{
	int		k;
	char	*c;

	c = Cmd_Argv(1);
	if (c[0])
		k = atoi(c);
	else
		k = -1;		// typed manually at the console for continuous down

	if (k == b->down[0] || k == b->down[1])
		return;		// repeating key

	if (!b->down[0])
		b->down[0] = k;
	else if (!b->down[1])
		b->down[1] = k;
	else
	{
		Con_Printf ("Three keys down for a button!\n");
		return;
	}

	if (b->state & 1)
		return;		// still down
	b->state |= 1 + 2;	// down + impulse down
}

void KeyUp (kbutton_t *b)
{
	int		k;
	char	*c;

	c = Cmd_Argv(1);
	if (c[0])
		k = atoi(c);
	else
	{ // typed manually at the console, assume for unsticking, so clear all
		b->down[0] = b->down[1] = 0;
		b->state = 4;	// impulse up
		return;
	}

	if (b->down[0] == k)
		b->down[0] = 0;
	else if (b->down[1] == k)
		b->down[1] = 0;
	else
		return;		// key up without coresponding down (menu pass through)
	if (b->down[0] || b->down[1])
		return;		// some other key is still holding it down

	if (!(b->state & 1))
		return;		// still up (this should not happen)
	b->state &= ~1;		// now up
	b->state |= 4; 		// impulse up
}

qboolean croshhairmoving = false;

void IN_KLookDown (void) {KeyDown(&in_klook);}
void IN_KLookUp (void) {KeyUp(&in_klook);}

/*void IN_MLookDown (void) {KeyDown(&in_mlook);}
void IN_MLookUp (void){
KeyUp(&in_mlook);
if ( !(in_mlook.state&1) &&  lookspring.value)
	V_StartPitchDrift();
} Heffo - mlook cvar*/

void IN_UpDown(void) {KeyDown(&in_up);}
void IN_UpUp(void) {KeyUp(&in_up);}
void IN_DownDown(void) {KeyDown(&in_down);}
void IN_DownUp(void) {KeyUp(&in_down);}
void IN_LeftDown(void) {KeyDown(&in_left);}
void IN_LeftUp(void) {KeyUp(&in_left);}
void IN_RightDown(void) {KeyDown(&in_right);}
void IN_RightUp(void) {KeyUp(&in_right);}
void IN_ForwardDown(void) {KeyDown(&in_forward);}
void IN_ForwardUp(void) {KeyUp(&in_forward);Cbuf_AddText("impulse 24\n");}
void IN_BackDown(void) {KeyDown(&in_back);}
void IN_BackUp(void) {KeyUp(&in_back);}
void IN_LookupDown(void) {KeyDown(&in_lookup);}
void IN_LookupUp(void) {KeyUp(&in_lookup);}
void IN_LookdownDown(void) {KeyDown(&in_lookdown);}
void IN_LookdownUp(void) {KeyUp(&in_lookdown);}
void IN_MoveleftDown(void) {KeyDown(&in_moveleft);}
void IN_MoveleftUp(void) {KeyUp(&in_moveleft);}
void IN_MoverightDown(void) {KeyDown(&in_moveright);}
void IN_MoverightUp(void) {KeyUp(&in_moveright);}

void IN_SpeedDown(void) {KeyDown(&in_speed);}
void IN_SpeedUp(void) {KeyUp(&in_speed);}
void IN_StrafeDown(void) {KeyDown(&in_strafe);}
void IN_StrafeUp(void) {KeyUp(&in_strafe);}

void IN_AttackDown(void) {KeyDown(&in_attack);}
void IN_AttackUp(void) {KeyUp(&in_attack);}

void IN_UseDown (void) {KeyDown(&in_use);}
void IN_UseUp (void) {KeyUp(&in_use);}
void IN_JumpDown (void) {KeyDown(&in_jump);}
void IN_JumpUp (void) {KeyUp(&in_jump);}
void IN_GrenadeDown (void) {KeyDown(&in_grenade);}
void IN_GrenadeUp (void) {KeyUp(&in_grenade);}
void IN_SwitchDown (void) {KeyDown(&in_switch);}
void IN_SwitchUp (void) {KeyUp(&in_switch);}
void IN_ReloadDown (void) {KeyDown(&in_reload);}
void IN_ReloadUp (void) {KeyUp(&in_reload);}
void IN_KnifeDown (void) {KeyDown(&in_knife);}
void IN_KnifeUp (void) {KeyUp(&in_knife);}
void IN_AimDown (void) {KeyDown(&in_aim);}
void IN_AimUp (void) {KeyUp(&in_aim);}

void IN_Impulse (void) {in_impulse=Q_atoi(Cmd_Argv(1));}

/*
===============
CL_KeyState

Returns 0.25 if a key was pressed and released during the frame,
0.5 if it was pressed and held
0 if held then released, and
1.0 if held for the entire time
===============
*/
float CL_KeyState (kbutton_t *key)
{
	float		val;
	qboolean	impulsedown, impulseup, down;

	impulsedown = key->state & 2;
	impulseup = key->state & 4;
	down = key->state & 1;
	val = 0;

	if (impulsedown && !impulseup)
	{
		if (down)
			val = 0.5;	// pressed and held this frame
		else
			val = 0;	//	I_Error ();
	}
	if (impulseup && !impulsedown)
	{
		if (down)
			val = 0;	//	I_Error ();
		else
			val = 0;	// released this frame
	}
	if (!impulsedown && !impulseup)
	{
		if (down)
			val = 1.0;	// held the entire frame
		else
			val = 0;	// up the entire frame
	}
	if (impulsedown && impulseup)
	{
		if (down)
			val = 0.75;	// released and re-pressed this frame
		else
			val = 0.25;	// pressed and released this frame
	}

	key->state &= 1;		// clear impulses

	return val;
}




//==========================================================================

cvar_t	cl_upspeed = {"cl_upspeed","200"};
float	cl_forwardspeed;
float	cl_backspeed;
float	cl_sidespeed;

cvar_t	cl_movespeedkey = {"cl_movespeedkey","2.0"};

cvar_t	cl_yawspeed = {"cl_yawspeed","140"};
cvar_t	cl_pitchspeed = {"cl_pitchspeed","150"};

cvar_t	cl_anglespeedkey = {"cl_anglespeedkey","1.5"};

cvar_t	in_mlook = {"in_mlook", "1", true}; //Heffo - mlook cvar
cvar_t	in_aimassist = {"in_aimassist", "1", true};


//Shpuld - Porting over lower sens for lower fov
extern cvar_t scr_fov;

/*
================
CL_AdjustAngles

Moves the local angle positions
================
*/


extern int original_fov, final_fov;
void CL_AdjustAngles (void)
{
	float	speed;
	float	up, down;

	if (in_speed.state & 1)
		speed = host_frametime * cl_anglespeedkey.value;
	else
		speed = host_frametime;

	//shpuld begin
	speed = speed * scr_fov.value/90;
	//speed = speed*final_fov/original_fov;
	//shpuld end


	if (!(in_strafe.state & 1))
	{
		cl.viewangles[YAW] -= speed*cl_yawspeed.value*CL_KeyState (&in_right);
		cl.viewangles[YAW] += speed*cl_yawspeed.value*CL_KeyState (&in_left);
		cl.viewangles[YAW] = anglemod(cl.viewangles[YAW]);
	}
	if (in_klook.state & 1)
	{
		V_StopPitchDrift ();
		cl.viewangles[PITCH] -= speed*cl_pitchspeed.value * CL_KeyState (&in_forward);
		cl.viewangles[PITCH] += speed*cl_pitchspeed.value * CL_KeyState (&in_back);
	}

	up = CL_KeyState (&in_lookup);
	down = CL_KeyState(&in_lookdown);

	cl.viewangles[PITCH] -= speed*cl_pitchspeed.value * up;
	cl.viewangles[PITCH] += speed*cl_pitchspeed.value * down;

	if (up || down)
		V_StopPitchDrift ();

	if (cl.viewangles[PITCH] > 80)
		cl.viewangles[PITCH] = 80;
	if (cl.viewangles[PITCH] < -70)
		cl.viewangles[PITCH] = -70;

	if (cl.viewangles[ROLL] > 50)
		cl.viewangles[ROLL] = 50;
	if (cl.viewangles[ROLL] < -50)
		cl.viewangles[ROLL] = -50;

}

/*
================
CL_BaseMove

Send the intended movement message to the server
================
*/

cvar_t waypoint_mode;
float crosshair_opacity;
void CL_BaseMove (usercmd_t *cmd)
{
	if (cls.signon != SIGNONS)//BLUBS CHANGED HERE
		return;

	CL_AdjustAngles ();

	Q_memset (cmd, 0, sizeof(*cmd));

	// Moto - we handle movespeed in QC now.
	cl_backspeed = cl_forwardspeed = cl_sidespeed = sv_player->v.maxspeed;

	// Throttle side and back speeds
	cl_sidespeed *= 0.8;
	cl_backspeed *= 0.7;
	
	if (waypoint_mode.value)
		cl_backspeed = cl_forwardspeed = cl_sidespeed *= 1.5;
		
	if (in_strafe.state & 1)
	{
		cmd->sidemove += cl_sidespeed * CL_KeyState (&in_right);
		cmd->sidemove -= cl_sidespeed * CL_KeyState (&in_left);
	}

	// crosshair stuff
	croshhairmoving = true;
	crosshair_opacity -= 8;
	if (crosshair_opacity <= 128)
		crosshair_opacity = 128;

	cmd->sidemove += cl_sidespeed * CL_KeyState (&in_moveright);
	cmd->sidemove -= cl_sidespeed * CL_KeyState (&in_moveleft);

	cmd->upmove += cl_upspeed.value * CL_KeyState (&in_up);
	cmd->upmove -= cl_upspeed.value * CL_KeyState (&in_down);

	if (! (in_klook.state & 1) )
	{
		cmd->forwardmove += cl_forwardspeed * CL_KeyState (&in_forward);
		cmd->forwardmove -= cl_backspeed * CL_KeyState (&in_back);
	}

//
// adjust for speed key
//
	if (in_speed.state & 1)
	{
		cmd->forwardmove *= cl_movespeedkey.value;
		cmd->sidemove *= cl_movespeedkey.value;
		cmd->upmove *= cl_movespeedkey.value;
	}

	// reset crosshair
	if (!CL_KeyState (&in_moveright) && !CL_KeyState (&in_moveleft) && !CL_KeyState (&in_forward) && !CL_KeyState (&in_back)) {
		croshhairmoving = false;

		crosshair_opacity += 22;

		if (crosshair_opacity >= 255)
			crosshair_opacity = 255;
	}	
}

int infront(edict_t *ent1, edict_t *ent2)
{
	vec3_t vec;
	float dot;
	VectorSubtract(ent2->v.origin,ent1->v.origin,vec);
	VectorNormalize(vec);

	vec3_t temp_angle,temp_forward,temp_right,temp_up;
	VectorCopy(cl.viewangles,temp_angle);

	AngleVectors(temp_angle,temp_forward,temp_right,temp_up);

	dot = DotProduct(vec,temp_forward);
	if(dot > 0.98)
	{
		return 1;
	}
	return 0;
}

int EN_Find(int num,char *string)
{
	edict_t *ed;

	int e;
	e = num;

	for(e++; e < sv.num_edicts; e++)
	{
		ed = EDICT_NUM(e);
		if(ed->free)
			continue;
		if(!strcmp(pr_strings + ed->v.classname,string))
		{
			return e;
		}
	}
	return 0;
}

void CL_Aim_Snap(void)
{
	edict_t *z,*bz,*player;
	int znum;
	trace_t trace;
	float bestDist = 10000;
	vec3_t distVec, zOrg, pOrg;
	//32 is v_ofs num

	bz = sv.edicts;

	int vofs = 32;//32 is actual v_ofs num
	int aimOfs = -10;//30 is top of bbox, 20 is our goal, so -10
	//Zombie body bbox vert max = 30
	//20 is the offset of the height of the zombie that we're aiming at, 20 above the origin
	//Crawler body bbox vert max = -15

	//Equation = origin + bbox vertical offset - 20

	player = EDICT_NUM(cl.viewentity);
	VectorCopy(player->v.origin,pOrg);
	pOrg[2] += vofs;

	if (cl.perks & 64)
    	znum = EN_Find(0,"ai_zombie_head");
  	else
    	znum = EN_Find(0,"ai_zombie");

	z = EDICT_NUM(znum);
	VectorCopy(z->v.origin,zOrg);
	zOrg[2] += z->v.maxs[2];//Setting to top of zomb ent
	zOrg[2] += aimOfs;

	while(znum != 0)
	{
		if((z->v.health > 0) && infront(player,z))
		{
			VectorCopy(z->v.origin,zOrg);
			zOrg[2] += aimOfs;
			VectorSubtract(pOrg,zOrg,distVec);
			if(VectorLength(distVec) < bestDist)
			{
				trace = SV_Move (pOrg, vec3_origin, vec3_origin,zOrg, 1, player);
				if (trace.fraction >= 1)
				{
					bestDist = VectorLength(distVec);
					bz = z;
				}
			}
		}
		if (cl.perks & 64)
		  	znum = EN_Find(znum,"ai_zombie_head");
    	else
      		znum = EN_Find(znum,"ai_zombie");
		z = EDICT_NUM(znum);
	}

	if(bz != sv.edicts)
	{
		VectorCopy(bz->v.origin,zOrg);
		zOrg[2] += bz->v.maxs[2];//Setting to top of bbox
		zOrg[2] += aimOfs;
		VectorSubtract(zOrg,pOrg,distVec);
		VectorNormalize(distVec);
		vectoangles(distVec,distVec);
		distVec[0] += (distVec[0]  > 180)? -360 : 0;//Need to bound pitch around 0, from -180, to + 180
		distVec[0] *= -1;//inverting pitch

		if(distVec[0] < -70 || distVec[0] > 80)
			return;

		VectorCopy(distVec,cl.viewangles);
	}
}


/*
==============
CL_SendMove
==============
*/
int zoom_snap;
float angledelta(float a);
float deltaPitch,deltaYaw;
void CL_SendMove (usercmd_t *cmd)
{
	int		i;
	long int		bits;
	sizebuf_t	buf;
	byte	data[128];
	vec3_t tempv;
	buf.maxsize = 128;
	buf.cursize = 0;
	buf.data = data;

	cl.cmd = *cmd;

	//==== Aim Assist Code ====
	if((cl.stats[STAT_ZOOM]==1 || cl.stats[STAT_ZOOM]==2) && ((in_aimassist.value) || (cl.perks & 64)))
	{
		if(!zoom_snap)
		{

			CL_Aim_Snap();
			zoom_snap = 1;
		}
	}
	else
		zoom_snap = 0;

	//==== Sniper Scope Swaying ====
	if(cl.stats[STAT_ZOOM] == 2)
	{
		vec3_t vang;

		VectorCopy(cl.viewangles,vang);

		vang[0] -= deltaPitch;
		vang[1] -= deltaYaw;

		#ifdef PSP_VFPU
		deltaPitch =(vfpu_cosf(cl.time/0.7) + vfpu_cosf(cl.time) + vfpu_sinf(cl.time/1.1)) * 0.5;
		deltaYaw = (vfpu_sinf(cl.time/0.4) + vfpu_cosf(cl.time/0.56) + vfpu_sinf(cl.time)) * 0.5;
		#else
		deltaPitch =(cos(cl.time/0.7) + cos(cl.time) + sin(cl.time/1.1)) * 0.5;
		deltaYaw = (sin(cl.time/0.4) + cos(cl.time/0.56) + sin(cl.time)) * 0.5;
		#endif

		vang[0] += deltaPitch;
		vang[1] += deltaYaw;
		vang[0] = angledelta(vang[0]);
		vang[1] = angledelta(vang[1]);

		VectorCopy(vang,cl.viewangles);
		//return 0;
	}

//
// send the movement message
//
    MSG_WriteByte (&buf, clc_move);

	MSG_WriteFloat (&buf, cl.mtime[0]);	// so server can get ping times

	VectorAdd(cl.gun_kick, cl.viewangles, tempv);
	for (i=0 ; i<3 ; i++)
		MSG_WriteFloat (&buf, tempv[i]);

    MSG_WriteShort (&buf, cmd->forwardmove);
    MSG_WriteShort (&buf, cmd->sidemove);
    MSG_WriteShort (&buf, cmd->upmove);

//
// send button bits
//
	bits = 0;

	if (in_attack.state & 3 )
		bits |= 1;
	in_attack.state &= ~2;

	if (in_jump.state & 3)
		bits |= 2;
	in_jump.state &= ~2;

	if (in_grenade.state & 3)
		bits |= 8;
	in_grenade.state &= ~2;

	if (in_switch.state & 3)
		bits |= 16;
	in_switch.state &= ~2;

	if (in_reload.state & 3)
		bits |= 32;
	in_reload.state &= ~2;

	if (in_knife.state & 3)
		bits |= 64;
	in_knife.state &= ~2;
	
	if (in_use.state & 3)
		bits |= 128;
	in_use.state &= ~2;
	
	if (in_aim.state & 3)
		bits |= 256;
	in_aim.state &= ~2; 

    MSG_WriteLong (&buf, bits);

    MSG_WriteByte (&buf, in_impulse);
	in_impulse = 0;

//
// deliver the message
//
	if (cls.demoplayback)
		return;

//
// allways dump the first two message, because it may contain leftover inputs
// from the last level
//
	if (++cl.movemessages <= 2)
		return;

	if (NET_SendUnreliableMessage (cls.netcon, &buf) == -1)
	{
		Con_Printf ("CL_SendMove: lost server connection\n");
		CL_Disconnect ();
	}
}

/*
============
CL_InitInput
============
*/
void CL_InitInput (void)
{
	Cmd_AddCommand ("+moveup",IN_UpDown);
	Cmd_AddCommand ("-moveup",IN_UpUp);
	Cmd_AddCommand ("+movedown",IN_DownDown);
	Cmd_AddCommand ("-movedown",IN_DownUp);
	Cmd_AddCommand ("+left",IN_LeftDown);
	Cmd_AddCommand ("-left",IN_LeftUp);
	Cmd_AddCommand ("+right",IN_RightDown);
	Cmd_AddCommand ("-right",IN_RightUp);
	Cmd_AddCommand ("+forward",IN_ForwardDown);
	Cmd_AddCommand ("-forward",IN_ForwardUp);
	Cmd_AddCommand ("+back",IN_BackDown);
	Cmd_AddCommand ("-back",IN_BackUp);
	Cmd_AddCommand ("+lookup", IN_LookupDown);
	Cmd_AddCommand ("-lookup", IN_LookupUp);
	Cmd_AddCommand ("+lookdown", IN_LookdownDown);
	Cmd_AddCommand ("-lookdown", IN_LookdownUp);
	Cmd_AddCommand ("+strafe", IN_StrafeDown);
	Cmd_AddCommand ("-strafe", IN_StrafeUp);
	Cmd_AddCommand ("+moveleft", IN_MoveleftDown);
	Cmd_AddCommand ("-moveleft", IN_MoveleftUp);
	Cmd_AddCommand ("+moveright", IN_MoverightDown);
	Cmd_AddCommand ("-moveright", IN_MoverightUp);
	Cmd_AddCommand ("+speed", IN_SpeedDown);
	Cmd_AddCommand ("-speed", IN_SpeedUp);
	Cmd_AddCommand ("+attack", IN_AttackDown);
	Cmd_AddCommand ("-attack", IN_AttackUp);
	Cmd_AddCommand ("+use", IN_UseDown);
	Cmd_AddCommand ("-use", IN_UseUp);
	Cmd_AddCommand ("+jump", IN_JumpDown);
	Cmd_AddCommand ("-jump", IN_JumpUp);
	Cmd_AddCommand ("+grenade", IN_GrenadeDown);
	Cmd_AddCommand ("-grenade", IN_GrenadeUp);
	Cmd_AddCommand ("+switch", IN_SwitchDown);
	Cmd_AddCommand ("-switch", IN_SwitchUp);
	Cmd_AddCommand ("+reload", IN_ReloadDown);
	Cmd_AddCommand ("-reload", IN_ReloadUp);
	Cmd_AddCommand ("+knife", IN_KnifeDown);
	Cmd_AddCommand ("-knife", IN_KnifeUp);
	Cmd_AddCommand ("+aim", IN_AimDown);
	Cmd_AddCommand ("-aim", IN_AimUp);
	Cmd_AddCommand ("impulse", IN_Impulse);
	Cmd_AddCommand ("+klook", IN_KLookDown);
	Cmd_AddCommand ("-klook", IN_KLookUp);



}

