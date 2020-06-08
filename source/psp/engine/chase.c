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
// chase.c -- chase camera code

#include "quakedef.h"

cvar_t	chase_back = {"chase_back", "100"};
cvar_t	chase_up = {"chase_up", "16"};
cvar_t	chase_right = {"chase_right", "0"};
cvar_t	chase_active = {"chase_active", "0"};
cvar_t  chase_roll = {"chase_roll", "0"};
cvar_t  chase_yaw = {"chase_yaw", "0"};
cvar_t  chase_pitch = {"chase_pitch", "0"};

vec3_t	chase_pos;
vec3_t	chase_angles;

vec3_t	chase_dest;
vec3_t	chase_dest_angles;


void Chase_Init (void)
{
	Cvar_RegisterVariable (&chase_back);
	Cvar_RegisterVariable (&chase_up);
	Cvar_RegisterVariable (&chase_right);
	Cvar_RegisterVariable (&chase_active);
    Cvar_RegisterVariable (&chase_roll);
    Cvar_RegisterVariable (&chase_yaw);
    Cvar_RegisterVariable (&chase_pitch);
}

void Chase_Reset (void)
{
	// for respawning and teleporting
//	start position 12 units behind head
}

void TraceLine (vec3_t start, vec3_t end, vec3_t impact)
{
	trace_t	trace;

	memset (&trace, 0, sizeof(trace));
	SV_RecursiveHullCheck (cl.worldmodel->hulls, 0, 0, 1, start, end, &trace);

	VectorCopy (trace.endpos, impact);
}

/*
#define NUM_TESTS 64 (delete)
#define CHASE_DEST_OFFSET 2.0f
*/

qboolean chase_nodraw;

#define NUM_TESTS 64
#define CHASE_DEST_OFFSET 2.0f

void Chase_Update (void)
{
   int      i;
   float   dist;
   vec3_t   forward, up, right;
   vec3_t   dest, stop;
   int best;
   int viewcontents;

   // if can't see player, reset
   AngleVectors (cl.viewangles, forward, right, up);

   // calc exact destination
   for (i = 0; i < 3; i++)
      chase_dest[i] = r_refdef.vieworg[i] - forward[i] * chase_back.value - right[i] * chase_right.value;

   chase_dest[2] = r_refdef.vieworg[2] + chase_up.value;

   // take the contents of the view leaf
   viewcontents = (Mod_PointInLeaf (r_refdef.vieworg, cl.worldmodel))->contents;

   for (best = 0; best < NUM_TESTS; best++)
   {
      float chase_newdest[3];

      chase_newdest[0] = r_refdef.vieworg[0] + (chase_dest[0] - r_refdef.vieworg[0]) * best / NUM_TESTS;
      chase_newdest[1] = r_refdef.vieworg[1] + (chase_dest[1] - r_refdef.vieworg[1]) * best / NUM_TESTS;
      chase_newdest[2] = r_refdef.vieworg[2] + (chase_dest[2] - r_refdef.vieworg[2]) * best / NUM_TESTS;

      // check for a leaf hit with different contents
      if ((Mod_PointInLeaf (chase_newdest, cl.worldmodel))->contents != viewcontents)
      {
         // go back to the previous best as this one is bad
         // unless the first one was also bad, (viewleaf contents != viewleaf contents!!!)
         if (best > 0)
            best--;
         else best = NUM_TESTS;
         break;
      }
   }

   // certain surfaces can be viewed at an oblique enough angle that they are partially clipped
   // by znear, so now we fix that too...
   for (; best >= 0; best--)
   {
      // number of matches
      int nummatches = 0;

      // adjust
      chase_dest[0] = r_refdef.vieworg[0] + (chase_dest[0] - r_refdef.vieworg[0]) * best / NUM_TESTS;
      chase_dest[1] = r_refdef.vieworg[1] + (chase_dest[1] - r_refdef.vieworg[1]) * best / NUM_TESTS;
      chase_dest[2] = r_refdef.vieworg[2] + (chase_dest[2] - r_refdef.vieworg[2]) * best / NUM_TESTS;

      // move x to neg
      chase_dest[0] -= CHASE_DEST_OFFSET;
      if ((Mod_PointInLeaf (chase_dest, cl.worldmodel))->contents == viewcontents) nummatches++;
      chase_dest[0] += CHASE_DEST_OFFSET;

      // move x to pos
      chase_dest[0] += CHASE_DEST_OFFSET;
      if ((Mod_PointInLeaf (chase_dest, cl.worldmodel))->contents == viewcontents) nummatches++;
      chase_dest[0] -= CHASE_DEST_OFFSET;

      // move y to neg
      chase_dest[1] -= CHASE_DEST_OFFSET;
      if ((Mod_PointInLeaf (chase_dest, cl.worldmodel))->contents == viewcontents) nummatches++;
      chase_dest[1] += CHASE_DEST_OFFSET;

      // move y to pos
      chase_dest[1] += CHASE_DEST_OFFSET;
      if ((Mod_PointInLeaf (chase_dest, cl.worldmodel))->contents == viewcontents) nummatches++;
      chase_dest[1] -= CHASE_DEST_OFFSET;

      // move z to neg
      chase_dest[2] -= CHASE_DEST_OFFSET;
      if ((Mod_PointInLeaf (chase_dest, cl.worldmodel))->contents == viewcontents) nummatches++;
      chase_dest[2] += CHASE_DEST_OFFSET;

      // move z to pos
      chase_dest[2] += CHASE_DEST_OFFSET;
      if ((Mod_PointInLeaf (chase_dest, cl.worldmodel))->contents == viewcontents) nummatches++;
      chase_dest[2] -= CHASE_DEST_OFFSET;

      // all tests passed so we're good!
      if (nummatches == 6) break;
   }

   // find the spot the player is looking at
   VectorMA (r_refdef.vieworg, 4096, forward, dest);
   TraceLine (r_refdef.vieworg, dest, stop);

   // calculate pitch to look at the same spot from camera
   VectorSubtract (stop, r_refdef.vieworg, stop);
   dist = DotProduct (stop, forward);
   if (dist < 1)
      dist = 1;

   #ifdef PSP_VFPU
   r_refdef.viewangles[PITCH] = -vfpu_atanf(stop[2] / dist) / M_PI * 180;
   #else
   r_refdef.viewangles[PITCH] = -atan(stop[2] / dist) / M_PI * 180;
   #endif

   // move towards destination
   VectorCopy (chase_dest, r_refdef.vieworg);
}

