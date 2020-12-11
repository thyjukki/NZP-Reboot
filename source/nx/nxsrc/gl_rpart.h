/*
Copyright (C) 2002-2003, Dr Labman, A. Nourai
Copyright (C) 2009, Crow_bar psp port

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
// gl_rpart.h

#include "quakedef.h"

void QMB_MuzzleFlash(vec3_t org);
void QMB_InitParticles (void);
void QMB_DrawParticles (void);
void R_SpawnDecal (vec3_t center, vec3_t normal, vec3_t tangent, int tex, int size, int isbsp);

void R_RunParticleEffect (vec3_t org, vec3_t dir, int color, int count);
void QMB_RunParticleEffect (vec3_t org, vec3_t dir, int col, int count);
extern qboolean		qmb_initialized;

#define RunParticleEffect(org, dir, color, count)		\
	if (qmb_initialized /*&& r_part_##var.value*/)				\
		QMB_RunParticleEffect (org, dir, color, count);		\
	else													\
		R_RunParticleEffect (org, dir, color, count);


typedef	enum
{
	pm_classic, pm_qmb, pm_quake3, pm_mixed
} part_mode_t;

