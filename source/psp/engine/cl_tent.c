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
// cl_tent.c -- client side temporary entities

#include "quakedef.h"

static	vec3_t	playerbeam_end;		// added by joe

int			num_temp_entities;
entity_t	cl_temp_entities[MAX_TEMP_ENTITIES];
beam_t		cl_beams[MAX_BEAMS];

model_t		*cl_q3gunshot_mod, *cl_q3teleport_mod;

sfx_t			*cl_sfx_r_exp3;

extern sfx_t			*cl_sfx_step[4];
/*
=================
CL_ParseTEnt
=================
*/
void CL_InitTEnts (void)
{
	cl_sfx_r_exp3 = S_PrecacheSound ("sounds/weapons/r_exp3.wav");
	cl_sfx_step[0] = S_PrecacheSound ("sounds/player/steps/step_1.wav");
	cl_sfx_step[1] = S_PrecacheSound ("sounds/player/steps/step_2.wav");
	cl_sfx_step[2] = S_PrecacheSound ("sounds/player/steps/step_3.wav");
	cl_sfx_step[3] = S_PrecacheSound ("sounds/player/steps/step_4.wav");
}

/*
=================
CL_ClearTEnts
=================
*/
void CL_ClearTEnts (void)
{
	//cl_bolt1_mod = cl_bolt2_mod = cl_bolt3_mod = cl_beam_mod = NULL;
	cl_q3gunshot_mod = cl_q3teleport_mod = NULL;

	memset (&cl_beams, 0, sizeof(cl_beams));
}

/*
=================
CL_ParseBeam
=================
*/
void CL_ParseBeam (model_t *m)
{
	int		ent;
	vec3_t	start, end;
	beam_t	*b;
	int		i;

	ent = MSG_ReadShort ();

	start[0] = MSG_ReadCoord ();
	start[1] = MSG_ReadCoord ();
	start[2] = MSG_ReadCoord ();

	end[0] = MSG_ReadCoord ();
	end[1] = MSG_ReadCoord ();
	end[2] = MSG_ReadCoord ();

    if (ent == cl.viewentity)
		VectorCopy(end, playerbeam_end);	// for cl_truelightning

// override any beam with the same entity
	for (i=0, b=cl_beams ; i< MAX_BEAMS ; i++, b++)
		if (b->entity == ent)
		{
			b->entity = ent;
			b->model = m;
			b->endtime = cl.time + 0.2;
			VectorCopy (start, b->start);
			VectorCopy (end, b->end);
			return;
		}

// find a free beam
	for (i=0, b=cl_beams ; i< MAX_BEAMS ; i++, b++)
	{
		if (!b->model || b->endtime < cl.time)
		{
			b->entity = ent;
			b->model = m;
			b->endtime = cl.time + 0.2;
			VectorCopy (start, b->start);
			VectorCopy (end, b->end);
			return;
		}
	}
	Con_Printf ("beam list overflow!\n");
}

enum
{
	DECAL_NONE,
	DECAL_BULLTMRK,
	DECAL_BLOODMRK1,
	DECAL_BLOODMRK2,
	DECAL_BLOODMRK3,
	DECAL_EXPLOMRK
};
//==============================================================================
extern cvar_t	r_decal_bullets;
extern cvar_t   r_decal_explosions;

extern int decal_blood1, decal_blood2, decal_blood3, decal_burn, decal_mark, decal_glow;
//==============================================================================
/*
=================
CL_ParseTEnt
=================
*/
void CL_ParseTEnt (void)
{
	int		type;
	vec3_t	pos;
	dlight_t	*dl;
	//int		rnd;
	int		colorStart, colorLength;

	type = MSG_ReadByte ();
	switch (type)
	{
	case TE_WIZSPIKE:			// spike hitting wall
		pos[0] = MSG_ReadCoord ();
		pos[1] = MSG_ReadCoord ();
		pos[2] = MSG_ReadCoord ();
        if (r_part_spikes.value == 2 && !cl_q3gunshot_mod)
			cl_q3gunshot_mod = Mod_ForName ("progs/bullet.md3", true);
		R_RunParticleEffect (pos, vec3_origin, 20, 30);
		//S_StartSound (-1, 0, cl_sfx_wizhit, pos, 1, 1);
		break;

	case TE_KNIGHTSPIKE:			// spike hitting wall
		pos[0] = MSG_ReadCoord ();
		pos[1] = MSG_ReadCoord ();
		pos[2] = MSG_ReadCoord ();
        if (r_part_spikes.value == 2 && !cl_q3gunshot_mod)
			cl_q3gunshot_mod = Mod_ForName ("progs/bullet.md3", true);
		R_RunParticleEffect (pos, vec3_origin, 226, 20);
		//S_StartSound (-1, 0, cl_sfx_knighthit, pos, 1, 1);
		break;

	case TE_SPIKE:			// spike hitting wall
		pos[0] = MSG_ReadCoord ();
		pos[1] = MSG_ReadCoord ();
		pos[2] = MSG_ReadCoord ();
        if (r_part_spikes.value == 2 && !cl_q3gunshot_mod)
			cl_q3gunshot_mod = Mod_ForName ("progs/bullet.md3", true);
		//R00k--start
		if (r_decal_bullets.value)
		{
			R_SpawnDecalStatic(pos, decal_mark, 8);
		}
		//R00k--end

		R_RunParticleEffect (pos, vec3_origin, 0, 10);

		break;
	case TE_SUPERSPIKE:			// super spike hitting wall
		pos[0] = MSG_ReadCoord ();
		pos[1] = MSG_ReadCoord ();
		pos[2] = MSG_ReadCoord ();
        if (r_part_spikes.value == 2 && !cl_q3gunshot_mod)
			cl_q3gunshot_mod = Mod_ForName ("progs/bullet.md3", true);
		R_RunParticleEffect (pos, vec3_origin, 0, 20);

		//R00k--start
		if (r_decal_bullets.value)
		{
			R_SpawnDecalStatic(pos, decal_mark, 10);
		}
		//R00k--end

		break;

	case TE_GUNSHOT:			// bullet hitting wall
		pos[0] = MSG_ReadCoord ();
		pos[1] = MSG_ReadCoord ();
		pos[2] = MSG_ReadCoord ();
        if (r_part_gunshots.value == 2 && !cl_q3gunshot_mod)
			cl_q3gunshot_mod = Mod_ForName ("progs/bullet.md3", true);

		//R00k--start
		if (r_decal_bullets.value)
		{
			R_SpawnDecalStatic(pos, decal_mark, 8);
		}
		//R00k--end
		R_RunParticleEffect (pos, vec3_origin, 0, 20);
		break;

	case TE_EXPLOSION:			// rocket explosion
		pos[0] = MSG_ReadCoord ();
		pos[1] = MSG_ReadCoord ();
		pos[2] = MSG_ReadCoord ();
		R_ParticleExplosion (pos);
        if (r_decal_explosions.value)
		{
			R_SpawnDecalStatic(pos, decal_burn, 100);
		}
		dl = CL_AllocDlight (0);
		VectorCopy (pos, dl->origin);
		dl->radius = 350;
		dl->die = cl.time + 0.5;
		dl->decay = 300;
		S_StartSound (-1, 0, cl_sfx_r_exp3, pos, 1, 0.5);
		break;
	case TE_RAYSPLASHGREEN:
		pos[0] = MSG_ReadCoord ();
		pos[1] = MSG_ReadCoord ();
		pos[2] = MSG_ReadCoord ();
		dl = CL_AllocDlight (0);
		VectorCopy (pos, dl->origin);
		dl->radius = 65;
		dl->die = cl.time + 0.3;
		dl->decay = 300;
		dl->color[0] = 0;
		dl->color[1] = 255;
		dl->color[2] = 0; 
		R_RunParticleEffect (pos, vec3_origin, 0, 256);
		//S_StartSound (-1, 0, cl_sfx_r_exp3, pos, 1, 0.5); // NZPFIXME - add raygun hum
		break;
	case TE_RAYSPLASHRED:
		pos[0] = MSG_ReadCoord ();
		pos[1] = MSG_ReadCoord ();
		pos[2] = MSG_ReadCoord ();
		dl = CL_AllocDlight (0);
		VectorCopy (pos, dl->origin);
		dl->radius = 65;
		dl->die = cl.time + 0.3;
		dl->decay = 300;
		dl->color[0] = 255;
		dl->color[1] = 0;
		dl->color[2] = 0; 
		R_RunParticleEffect (pos, vec3_origin, 0, 512);
		//S_StartSound (-1, 0, cl_sfx_r_exp3, pos, 1, 0.5); // NZPFIXME - add raygun hum
		break;
	case TE_TAREXPLOSION:			// tarbaby explosion
		pos[0] = MSG_ReadCoord ();
		pos[1] = MSG_ReadCoord ();
		pos[2] = MSG_ReadCoord ();
		R_BlobExplosion (pos);
		S_StartSound (-1, 0, cl_sfx_r_exp3, pos, 1, 1);
		break;

	case TE_LIGHTNING1:				// lightning bolts
		CL_ParseBeam (Mod_ForName("progs/bolt.mdl", true));
		break;

	case TE_LIGHTNING2:				// lightning bolts
		CL_ParseBeam (Mod_ForName("progs/bolt2.mdl", true));
		break;

	case TE_LIGHTNING3:				// lightning bolts
		CL_ParseBeam (Mod_ForName("progs/bolt3.mdl", true));
		break;

// PGM 01/21/97
	case TE_BEAM:				// grappling hook beam
		CL_ParseBeam (Mod_ForName("progs/beam.mdl", true));
		break;
// PGM 01/21/97

	case TE_LAVASPLASH:
		pos[0] = MSG_ReadCoord ();
		pos[1] = MSG_ReadCoord ();
		pos[2] = MSG_ReadCoord ();
		R_LavaSplash (pos);
        dl = CL_AllocDlight (0);
		VectorCopy (pos, dl->origin);
		dl->radius = 150;
		dl->die = cl.time + 0.75;
		dl->decay = 200;
		break;

	case TE_TELEPORT:
		pos[0] = MSG_ReadCoord ();
		pos[1] = MSG_ReadCoord ();
		pos[2] = MSG_ReadCoord ();
        if (r_part_telesplash.value == 2 && !cl_q3teleport_mod)
			cl_q3teleport_mod = Mod_ForName ("progs/telep.md3", true);
		R_TeleportSplash (pos);
		break;

	case TE_EXPLOSION2:				// color mapped explosion
		pos[0] = MSG_ReadCoord ();
		pos[1] = MSG_ReadCoord ();
		pos[2] = MSG_ReadCoord ();
		colorStart = MSG_ReadByte ();
		colorLength = MSG_ReadByte ();
		R_ParticleExplosion2 (pos, colorStart, colorLength);

		if (r_decal_explosions.value)
		{
			R_SpawnDecalStatic(pos, decal_burn, 100);
		}

		dl = CL_AllocDlight (0);
		VectorCopy (pos, dl->origin);
		dl->radius = 350;
		dl->die = cl.time + 0.5;
		dl->decay = 300;
		S_StartSound (-1, 0, cl_sfx_r_exp3, pos, 1, 1);
		break;

	default:
		Sys_Error ("CL_ParseTEnt: bad type");
	}
}


/*
=================
CL_NewTempEntity
=================
*/
entity_t *CL_NewTempEntity (void)
{
	entity_t	*ent;

	if (cl_numvisedicts == MAX_VISEDICTS)
		return NULL;
	if (num_temp_entities == MAX_TEMP_ENTITIES)
		return NULL;
	ent = &cl_temp_entities[num_temp_entities];
	memset (ent, 0, sizeof(*ent));
	num_temp_entities++;
	cl_visedicts[cl_numvisedicts] = ent;
	cl_numvisedicts++;

	ent->colormap = vid.colormap;
	return ent;
}

/*
=================
TraceLineN
=================
*/
qboolean TraceLineN (vec3_t start, vec3_t end, vec3_t impact, vec3_t normal)
{
	trace_t	trace;

	memset (&trace, 0, sizeof(trace));
	if (!SV_RecursiveHullCheck(cl.worldmodel->hulls, 0, 0, 1, start, end, &trace))
	{
		if (trace.fraction < 1)
		{
			VectorCopy (trace.endpos, impact);
			if (normal)
				VectorCopy (trace.plane.normal, normal);

			return true;
		}
	}

	return false;
}

void QMB_Lightning_Splash (vec3_t org);
extern cvar_t scr_ofsy;
/*
=================
CL_UpdateTEnts
=================
*/
void CL_UpdateTEnts (void)
{
	int			i;
	beam_t		*b;
	vec3_t		dist, org, beamstart;
	float		d;
	entity_t	*ent;
	float		yaw, pitch;
	float		forward;

	int			j;
	vec3_t		beamend;
//	qboolean	sparks = false;

	num_temp_entities = 0;

// update lightning
	for (i=0, b=cl_beams ; i< MAX_BEAMS ; i++, b++)
	{
		if (!b->model || b->endtime < cl.time)
			continue;

		// if coming from the player, update the start position
		if (b->entity == cl.viewentity)
		{
			VectorCopy (cl_entities[cl.viewentity].origin, b->start);

			b->start[2] += cl.crouch + bound(-7, scr_ofsy.value, 4);
			b->start[2] += bound(0, cl_lightning_zadjust.value, 20);//progs.dat aims from 20 for traceline

			if (cl_truelightning.value)
			{
				vec3_t	forward, v, org, ang;
				float	f, delta;
				trace_t	trace;

				f = fmax(0, fmin(1, cl_truelightning.value));

				VectorSubtract (playerbeam_end, cl_entities[cl.viewentity].origin, v);
				//v[2] -= 22;		// adjust for view height
				v[2] -= cl.crouch; //
				v[2] -= bound(0, cl_lightning_zadjust.value, 20);

				vectoangles (v, ang);

				// lerp pitch
				ang[0] = -ang[0];
				if (ang[0] < -180)
					ang[0] += 360;
				ang[0] += (cl.viewangles[0] - ang[0]) * f;

				// lerp yaw
				delta = cl.viewangles[1] - ang[1];
				if (delta > 180)
					delta -= 360;
				if (delta < -180)
					delta += 360;
				ang[1] += delta * f;
				ang[2] = 0;

				AngleVectors (ang, forward, NULLVEC, NULLVEC);
				VectorScale(forward, 600, forward);
				VectorCopy(cl_entities[cl.viewentity].origin, org);
				org[2] += bound(0, cl_lightning_zadjust.value, 20);//progs.dat aims from 20 for teaceline
				VectorAdd(org, forward, b->end);

				memset (&trace, 0, sizeof(trace_t));
				if (!SV_RecursiveHullCheck(cl.worldmodel->hulls, 0, 0, 1, org, b->end, &trace))
					VectorCopy(trace.endpos, b->end);
			}
		}

/*
	// if coming from the player, update the start position
		if (b->entity == cl.viewentity)
		{
			VectorCopy (cl_entities[cl.viewentity].origin, b->start);
		}
*/
	// calculate pitch and yaw
		VectorSubtract (b->end, b->start, dist);

		if (dist[1] == 0 && dist[0] == 0)
		{
			yaw = 0;
			if (dist[2] > 0)
				pitch = 90;
			else
				pitch = 270;
		}
		else
		{
			yaw = (int) (atan2f(dist[1], dist[0]) * 180 / M_PI);
			if (yaw < 0)
				yaw += 360;

			forward = sqrtf (dist[0]*dist[0] + dist[1]*dist[1]);
			pitch = (int) (atan2f(dist[2], forward) * 180 / M_PI);
			if (pitch < 0)
				pitch += 360;
		}
        // add new entities for the lightning
		VectorCopy(b->start, org);
		VectorCopy(b->start, beamstart);
		d = VectorNormalize (dist);
		VectorScale (dist, 30, dist);

		if (key_dest == key_game)
		{
			for ( ; d > 0 ; d -= 30)
			{
				if ((qmb_initialized && r_part_lightning.value) && (!cl.paused))
				{
					VectorAdd(org, dist, beamend);
					for (j=0 ; j<3 ; j++)
						beamend[j] += ((rand()%10)-5);
					QMB_LightningBeam (beamstart, beamend);
					//if ((r_glowlg.value) && (r_dynamic.value))
					//	CL_NewDlight (i, beamstart, 100, 0.1, lt_blue);
					VectorCopy(beamend, beamstart);
				}
				else
				{
					if (!(ent = CL_NewTempEntity()))
						return;
					VectorCopy(org, ent->origin);
					ent->model = b->model;
					ent->angles[0] = pitch;
					ent->angles[1] = yaw;
					ent->angles[2] = rand() % 360;
				}
				VectorAdd(org, dist, org);
			}
		}
/*
	// add new entities for the lightning
		VectorCopy (b->start, org);
		d = VectorNormalize(dist);
     	while (d > 0)
		{
			ent = CL_NewTempEntity ();
			if (!ent)
				return;
			VectorCopy (org, ent->origin);
			ent->model = b->model;
			ent->angles[0] = pitch;
			ent->angles[1] = yaw;
			ent->angles[2] = rand()%360;

			for (i=0 ; i<3 ; i++)
				org[i] += dist[i]*30;
			d -= 30;
		}
*/
	}

}


