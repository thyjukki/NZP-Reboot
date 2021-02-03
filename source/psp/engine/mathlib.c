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
// mathlib.c -- math primitives

#include <math.h>
#include "quakedef.h"

#ifdef PSP_VFPU
#include <pspmath.h>
#endif

void Sys_Error (char *error, ...);

vec3_t vec3_origin = {0,0,0};
int nanmask = 255<<23;

int  _mathlib_temp_int1, _mathlib_temp_int2, _mathlib_temp_int3;
float _mathlib_temp_float1, _mathlib_temp_float2, _mathlib_temp_float3;
vec3_t _mathlib_temp_vec1, _mathlib_temp_vec2, _mathlib_temp_vec3;


/*-----------------------------------------------------------------*/

float rsqrt( float number )
{
#ifdef PSP_VFPU
	float d;
    __asm__ (  //from official pspsdk by sony
		".set			push\n"					// save assember option
		".set			noreorder\n"			// suppress reordering
		"lv.s			s000, %1\n"				// s000 = s
		"vrsq.s			s000, s000\n"			// s000 = 1 / sqrt(s000)
		"sv.s			s000, %0\n"				// d    = s000
		".set			pop\n"					// restore assember option
		: "=m"(d)
		: "m"(number)
	);
	return d;
#else
	int	i;
	float	x, y;

	if( number == 0.0f )
		return 0.0f;

	x = number * 0.5f;
	i = *(int *)&number;	// evil floating point bit level hacking
	i = 0x5f3759df - (i >> 1);	// what the fuck?
	y = *(float *)&i;
	y = y * (1.5f - (x * y * y));	// first iteration

	return y;
#endif
}

/*
=================
SinCos
=================
*/
void SinCos( float radians, float *sine, float *cosine )
{
	#ifdef PSP_VFPU
	vfpu_sincos(radians,sine,cosine);
	#else
	__asm__ volatile (
		"mtv      %2, S002\n"
		"vcst.s   S003, VFPU_2_PI\n"
		"vmul.s   S002, S002, S003\n"
		"vrot.p   C000, S002, [s, c]\n"
		"mfv      %0, S000\n"
		"mfv      %1, S001\n"
	: "=r"(*sine), "=r"(*cosine): "r"(radians));
	#endif
}

void ProjectPointOnPlane( vec3_t dst, const vec3_t p, const vec3_t normal )
{
	float d;
	vec3_t n;
	float inv_denom;

	inv_denom = 1.0F / DotProduct( normal, normal );

	d = DotProduct( normal, p ) * inv_denom;

	n[0] = normal[0] * inv_denom;
	n[1] = normal[1] * inv_denom;
	n[2] = normal[2] * inv_denom;

	dst[0] = p[0] - d * n[0];
	dst[1] = p[1] - d * n[1];
	dst[2] = p[2] - d * n[2];
}

/*
** assumes "src" is normalized
*/
void PerpendicularVector( vec3_t dst, const vec3_t src )
{
	int	pos;
	int i;
	float minelem = 1.0F;
	vec3_t tempvec;

	/*
	** find the smallest magnitude axially aligned vector
	*/
	for ( pos = 0, i = 0; i < 3; i++ )
	{
		#ifdef PSP_VFPU
		if ( vfpu_fabsf( src[i] ) < minelem )
		#else
		if ( fabsf( src[i] ) < minelem )
		#endif
		{
			pos = i;
			#ifdef PSP_VFPU	
			minelem = vfpu_fabsf( src[i] );
			#else
			minelem = fabsf( src[i] );
			#endif
		}
	}
	tempvec[0] = tempvec[1] = tempvec[2] = 0.0F;
	tempvec[pos] = 1.0F;

	/*
	** project the point onto the plane defined by src
	*/
	ProjectPointOnPlane( dst, tempvec, src );

	/*
	** normalize the result
	*/
	VectorNormalize( dst );
}


void RotatePointAroundVector( vec3_t dst, const vec3_t dir, const vec3_t point, float degrees )
{
	float	m[3][3];
	float	im[3][3];
	float	zrot[3][3];
	float	tmpmat[3][3];
	float	rot[3][3];
	int	i;
	vec3_t vr, vup, vf;

	vf[0] = dir[0];
	vf[1] = dir[1];
	vf[2] = dir[2];

	PerpendicularVector( vr, dir );
	CrossProduct( vr, vf, vup );

	m[0][0] = vr[0];
	m[1][0] = vr[1];
	m[2][0] = vr[2];

	m[0][1] = vup[0];
	m[1][1] = vup[1];
	m[2][1] = vup[2];

	m[0][2] = vf[0];
	m[1][2] = vf[1];
	m[2][2] = vf[2];

	memcpy( im, m, sizeof( im ) );

	im[0][1] = m[1][0];
	im[0][2] = m[2][0];
	im[1][0] = m[0][1];
	im[1][2] = m[2][1];
	im[2][0] = m[0][2];
	im[2][1] = m[1][2];

	memset( zrot, 0, sizeof( zrot ) );
	zrot[0][0] = zrot[1][1] = zrot[2][2] = 1.0F;

	#ifdef PSP_VFPU
	zrot[0][0] = vfpu_cosf( DEG2RAD( degrees ) );
	zrot[0][1] = vfpu_sinf( DEG2RAD( degrees ) );
	zrot[1][0] = -vfpu_sinf( DEG2RAD( degrees ) );
	zrot[1][1] = vfpu_cosf( DEG2RAD( degrees ) );
	#else
	zrot[0][0] = cosf( DEG2RAD( degrees ) );
	zrot[0][1] = sinf( DEG2RAD( degrees ) );
	zrot[1][0] = -sinf( DEG2RAD( degrees ) );
	zrot[1][1] = cosf( DEG2RAD( degrees ) );
	#endif

	R_ConcatRotations( m, zrot, tmpmat );
	R_ConcatRotations( tmpmat, im, rot );

	for ( i = 0; i < 3; i++ )
	{
		dst[i] = rot[i][0] * point[0] + rot[i][1] * point[1] + rot[i][2] * point[2];
	}
}

/*-----------------------------------------------------------------*/


float	anglemod(float a)
{
#if 0
	if (a >= 0)
		a -= 360*(int)(a/360);
	else
		a += 360*( 1 + (int)(-a/360) );
#endif
	a = (360.0/65536) * ((int)(a*(65536/360.0)) & 65535);
	return a;
}

/*
==================
BOPS_Error

Split out like this for ASM to call.
==================
*/
void BOPS_Error (void)
{
	Sys_Error ("BoxOnPlaneSide:  Bad signbits");
}

/*
==================
BoxOnPlaneSide

Returns 1, 2, or 1 + 2
==================
*/
// crow_bar's enhanced boxonplaneside 
int BoxOnPlaneSide(vec3_t emins, vec3_t emaxs, mplane_t *p)
{
#ifdef PSP_VFPU
	int	sides;
	__asm__ (
		".set		push\n"					// save assembler option
		".set		noreorder\n"			// suppress reordering
		"lv.s		S000,  0 + %[normal]\n"	// S000 = p->normal[0]
		"lv.s		S001,  4 + %[normal]\n"	// S001 = p->normal[1]
		"lv.s		S002,  8 + %[normal]\n"	// S002 = p->normal[2]
		"vzero.p	C030\n"					// C030 = [0.0f, 0.0f]
		"lv.s		S032, %[dist]\n"		// S032 = p->dist
		"move		$8,   $0\n"				// $8 = 0
		"beq		%[signbits], $8, 0f\n"	// jump to 0
		"addiu		$8,   $8,   1\n"		// $8 = $8 + 1							( delay slot )
		"beq		%[signbits], $8, 1f\n"	// jump to 1
		"addiu		$8,   $8,   1\n"		// $8 = $8 + 1							( delay slot )
		"beq		%[signbits], $8, 2f\n"	// jump to 2
		"addiu		$8,   $8,   1\n"		// $8 = $8 + 1							( delay slot )
		"beq		%[signbits], $8, 3f\n"	// jump to 3
		"addiu		$8,   $8,   1\n"		// $8 = $8 + 1							( delay slot )
		"beq		%[signbits], $8, 4f\n"	// jump to 4
		"addiu		$8,   $8,   1\n"		// $8 = $8 + 1							( delay slot )
		"beq		%[signbits], $8, 5f\n"	// jump to 5
		"addiu		$8,   $8,   1\n"		// $8 = $8 + 1							( delay slot )
		"beq		%[signbits], $8, 6f\n"	// jump to 6
		"addiu		$8,   $8,   1\n"		// $8 = $8 + 1							( delay slot )
		"beq		%[signbits], $8, 7f\n"	// jump to 7
		"nop\n"								// 										( delay slot )
		"j			8f\n"					// jump to SetSides
		"nop\n"								// 										( delay slot )
	"0:\n"
/*
		dist1 = p->normal[0]*emaxs[0] + p->normal[1]*emaxs[1] + p->normal[2]*emaxs[2];
		dist2 = p->normal[0]*emins[0] + p->normal[1]*emins[1] + p->normal[2]*emins[2];
*/
		"lv.s		S010,  0 + %[emaxs]\n"	// S010 = emaxs[0]
		"lv.s		S011,  4 + %[emaxs]\n"	// S011 = emaxs[1]
		"lv.s		S012,  8 + %[emaxs]\n"	// S012 = emaxs[2]
		"lv.s		S020,  0 + %[emins]\n"	// S020 = emins[0]
		"lv.s		S021,  4 + %[emins]\n"	// S021 = emins[1]
		"lv.s		S022,  8 + %[emins]\n"	// S022 = emins[2]
		"vdot.t		S030, C000, C010\n"		// S030 = C000 * C010
		"vdot.t		S031, C000, C020\n"		// S030 = C000 * C020
		"j			8f\n"					// jump to SetSides
		"nop\n"								// 										( delay slot )
	"1:\n"
/*
		dist1 = p->normal[0]*emins[0] + p->normal[1]*emaxs[1] + p->normal[2]*emaxs[2];
		dist2 = p->normal[0]*emaxs[0] + p->normal[1]*emins[1] + p->normal[2]*emins[2];
*/
		"lv.s		S010,  0 + %[emins]\n"	// S010 = emins[0]
		"lv.s		S011,  4 + %[emaxs]\n"	// S011 = emaxs[1]
		"lv.s		S012,  8 + %[emaxs]\n"	// S012 = emaxs[2]
		"lv.s		S020,  0 + %[emaxs]\n"	// S020 = emaxs[0]
		"lv.s		S021,  4 + %[emins]\n"	// S021 = emins[1]
		"lv.s		S022,  8 + %[emins]\n"	// S022 = emins[2]
		"vdot.t		S030, C000, C010\n"		// S030 = C000 * C010
		"vdot.t		S031, C000, C020\n"		// S030 = C000 * C020
		"j			8f\n"					// jump to SetSides
		"nop\n"								// 										( delay slot )
	"2:\n"
/*
		dist1 = p->normal[0]*emaxs[0] + p->normal[1]*emins[1] + p->normal[2]*emaxs[2];
		dist2 = p->normal[0]*emins[0] + p->normal[1]*emaxs[1] + p->normal[2]*emins[2];
*/
		"lv.s		S010,  0 + %[emaxs]\n"	// S010 = emaxs[0]
		"lv.s		S011,  4 + %[emins]\n"	// S011 = emins[1]
		"lv.s		S012,  8 + %[emaxs]\n"	// S012 = emaxs[2]
		"lv.s		S020,  0 + %[emins]\n"	// S020 = emins[0]
		"lv.s		S021,  4 + %[emaxs]\n"	// S021 = emaxs[1]
		"lv.s		S022,  8 + %[emins]\n"	// S022 = emins[2]
		"vdot.t		S030, C000, C010\n"		// S030 = C000 * C010
		"vdot.t		S031, C000, C020\n"		// S030 = C000 * C020
		"j			8f\n"					// jump to SetSides
		"nop\n"								// 										( delay slot )
	"3:\n"
/*
		dist1 = p->normal[0]*emins[0] + p->normal[1]*emins[1] + p->normal[2]*emaxs[2];
		dist2 = p->normal[0]*emaxs[0] + p->normal[1]*emaxs[1] + p->normal[2]*emins[2];
*/
		"lv.s		S010,  0 + %[emins]\n"	// S010 = emins[0]
		"lv.s		S011,  4 + %[emins]\n"	// S011 = emins[1]
		"lv.s		S012,  8 + %[emaxs]\n"	// S012 = emaxs[2]
		"lv.s		S020,  0 + %[emaxs]\n"	// S020 = emaxs[0]
		"lv.s		S021,  4 + %[emaxs]\n"	// S021 = emaxs[1]
		"lv.s		S022,  8 + %[emins]\n"	// S022 = emins[2]
		"vdot.t		S030, C000, C010\n"		// S030 = C000 * C010
		"vdot.t		S031, C000, C020\n"		// S030 = C000 * C020
		"j			8f\n"					// jump to SetSides
		"nop\n"								// 										( delay slot )
	"4:\n"
/*
		dist1 = p->normal[0]*emaxs[0] + p->normal[1]*emaxs[1] + p->normal[2]*emins[2];
		dist2 = p->normal[0]*emins[0] + p->normal[1]*emins[1] + p->normal[2]*emaxs[2];
*/
		"lv.s		S010,  0 + %[emaxs]\n"	// S010 = emaxs[0]
		"lv.s		S011,  4 + %[emaxs]\n"	// S011 = emaxs[1]
		"lv.s		S012,  8 + %[emins]\n"	// S012 = emins[2]
		"lv.s		S020,  0 + %[emins]\n"	// S020 = emins[0]
		"lv.s		S021,  4 + %[emins]\n"	// S021 = emins[1]
		"lv.s		S022,  8 + %[emaxs]\n"	// S022 = emaxs[2]
		"vdot.t		S030, C000, C010\n"		// S030 = C000 * C010
		"vdot.t		S031, C000, C020\n"		// S030 = C000 * C020
		"j			8f\n"					// jump to SetSides
		"nop\n"								// 										( delay slot )
	"5:\n"
/*
		dist1 = p->normal[0]*emins[0] + p->normal[1]*emaxs[1] + p->normal[2]*emins[2];
		dist2 = p->normal[0]*emaxs[0] + p->normal[1]*emins[1] + p->normal[2]*emaxs[2];
*/
		"lv.s		S010,  0 + %[emins]\n"	// S010 = emins[0]
		"lv.s		S011,  4 + %[emaxs]\n"	// S011 = emaxs[1]
		"lv.s		S012,  8 + %[emins]\n"	// S012 = emins[2]
		"lv.s		S020,  0 + %[emaxs]\n"	// S020 = emaxs[0]
		"lv.s		S021,  4 + %[emins]\n"	// S021 = emins[1]
		"lv.s		S022,  8 + %[emaxs]\n"	// S022 = emaxs[2]
		"vdot.t		S030, C000, C010\n"		// S030 = C000 * C010
		"vdot.t		S031, C000, C020\n"		// S030 = C000 * C020
		"j			8f\n"					// jump to SetSides
		"nop\n"								// 										( delay slot )
	"6:\n"
/*
		dist1 = p->normal[0]*emaxs[0] + p->normal[1]*emins[1] + p->normal[2]*emins[2];
		dist2 = p->normal[0]*emins[0] + p->normal[1]*emaxs[1] + p->normal[2]*emaxs[2];
*/
		"lv.s		S010,  0 + %[emaxs]\n"	// S010 = emaxs[0]
		"lv.s		S011,  4 + %[emins]\n"	// S011 = emins[1]
		"lv.s		S012,  8 + %[emins]\n"	// S012 = emins[2]
		"lv.s		S020,  0 + %[emins]\n"	// S020 = emins[0]
		"lv.s		S021,  4 + %[emaxs]\n"	// S021 = emaxs[1]
		"lv.s		S022,  8 + %[emaxs]\n"	// S022 = emaxs[2]
		"vdot.t		S030, C000, C010\n"		// S030 = C000 * C010
		"vdot.t		S031, C000, C020\n"		// S030 = C000 * C020
		"j			8f\n"					// jump to SetSides
		"nop\n"								// 										( delay slot )
	"7:\n"
/*
		dist1 = p->normal[0]*emins[0] + p->normal[1]*emins[1] + p->normal[2]*emins[2];
		dist2 = p->normal[0]*emaxs[0] + p->normal[1]*emaxs[1] + p->normal[2]*emaxs[2];
*/
		"lv.s		S010,  0 + %[emins]\n"	// S010 = emins[0]
		"lv.s		S011,  4 + %[emins]\n"	// S011 = emins[1]
		"lv.s		S012,  8 + %[emins]\n"	// S012 = emins[2]
		"lv.s		S020,  0 + %[emaxs]\n"	// S020 = emaxs[0]
		"lv.s		S021,  4 + %[emaxs]\n"	// S021 = emaxs[1]
		"lv.s		S022,  8 + %[emaxs]\n"	// S022 = emaxs[2]
		"vdot.t		S030, C000, C010\n"		// S030 = C000 * C010
		"vdot.t		S031, C000, C020\n"		// S030 = C000 * C020
	"8:\n"									// SetSides
/*
		if( dist1 >= p->dist )
			sides = 1;
		if( dist2 < p->dist )
			sides |= 2;
*/
		"addiu		%[sides], $0, 0\n"		// sides = 0
		"vcmp.s		LT,   S030, S032\n"		// S030 < S032
		"bvt		0,    9f\n"				// if ( CC[0] == 1 ) jump to 9
		"nop\n"								// 										( delay slot )
		"addiu		%[sides], %[sides], 1\n"// sides = 1
	"9:\n"	
		"vcmp.s		GE,   S031, S032\n"		// S031 >= S032
		"bvt		0,    10f\n"			// if ( CC[0] == 1 ) jump to 10
		"nop\n"								// 										( delay slot )
		"addiu		%[sides], %[sides], 2\n"// sides = sides + 2
	"10:\n"
		".set		pop\n"					// restore assembler option
		:	[sides]    "=r" ( sides )
		:	[normal]   "m"  (*(p->normal)),
			[emaxs]    "m"  ( *emaxs ), 
			[emins]    "m"  ( *emins ),
			[signbits] "r"  ( p->signbits ), 
			[dist]     "m"  ( p->dist )
		:	"$8"
	);
	return sides;
#else
	int	sides = 0;
	float	dist1, dist2;

	// general case
	switch( p->signbits )
	{
	case 0:
		dist1 = p->normal[0]*emaxs[0] + p->normal[1]*emaxs[1] + p->normal[2]*emaxs[2];
		dist2 = p->normal[0]*emins[0] + p->normal[1]*emins[1] + p->normal[2]*emins[2];
		break;
	case 1:
		dist1 = p->normal[0]*emins[0] + p->normal[1]*emaxs[1] + p->normal[2]*emaxs[2];
		dist2 = p->normal[0]*emaxs[0] + p->normal[1]*emins[1] + p->normal[2]*emins[2];
		break;
	case 2:
		dist1 = p->normal[0]*emaxs[0] + p->normal[1]*emins[1] + p->normal[2]*emaxs[2];
		dist2 = p->normal[0]*emins[0] + p->normal[1]*emaxs[1] + p->normal[2]*emins[2];
		break;
	case 3:
		dist1 = p->normal[0]*emins[0] + p->normal[1]*emins[1] + p->normal[2]*emaxs[2];
		dist2 = p->normal[0]*emaxs[0] + p->normal[1]*emaxs[1] + p->normal[2]*emins[2];
		break;
	case 4:
		dist1 = p->normal[0]*emaxs[0] + p->normal[1]*emaxs[1] + p->normal[2]*emins[2];
		dist2 = p->normal[0]*emins[0] + p->normal[1]*emins[1] + p->normal[2]*emaxs[2];
		break;
	case 5:
		dist1 = p->normal[0]*emins[0] + p->normal[1]*emaxs[1] + p->normal[2]*emins[2];
		dist2 = p->normal[0]*emaxs[0] + p->normal[1]*emins[1] + p->normal[2]*emaxs[2];
		break;
	case 6:
		dist1 = p->normal[0]*emaxs[0] + p->normal[1]*emins[1] + p->normal[2]*emins[2];
		dist2 = p->normal[0]*emins[0] + p->normal[1]*emaxs[1] + p->normal[2]*emaxs[2];
		break;
	case 7:
		dist1 = p->normal[0]*emins[0] + p->normal[1]*emins[1] + p->normal[2]*emins[2];
		dist2 = p->normal[0]*emaxs[0] + p->normal[1]*emaxs[1] + p->normal[2]*emaxs[2];
		break;
	default:
		// shut up compiler
		dist1 = dist2 = 0;
		break;
	}

	if( dist1 >= p->dist )
		sides = 1;
	if( dist2 < p->dist )
		sides |= 2;

	return sides;
#endif
}


void vectoangles (vec3_t vec, vec3_t ang)
{
	float	forward, yaw, pitch;

	if (!vec[1] && !vec[0])
	{
		yaw = 0;
		pitch = (vec[2] > 0) ? 90 : 270;
	}
	else
	{
		#ifdef PSP_VFPU
		yaw = vec[0] ? (vfpu_atan2f(vec[1], vec[0]) * 180 / M_PI) : (vec[1] > 0) ? 90 : 270;
		#else
		yaw = vec[0] ? (atan2(vec[1], vec[0]) * 180 / M_PI) : (vec[1] > 0) ? 90 : 270;
		#endif
		if (yaw < 0)
			yaw += 360;

		#ifdef PSP_VFPU
		forward = vfpu_sqrtf (vec[0] * vec[0] + vec[1] * vec[1]);
		pitch = vfpu_atan2f (vec[2], forward) * 180 / M_PI;
		#else
		forward = sqrt (vec[0] * vec[0] + vec[1] * vec[1]);
		pitch = atan2 (vec[2], forward) * 180 / M_PI;
		#endif
		if (pitch < 0)
			pitch += 360;
	}

	ang[0] = pitch;
	ang[1] = yaw;
	ang[2] = 0;
}

void AngleVectors (vec3_t angles, vec3_t forward, vec3_t right, vec3_t up)
{
	float		angle;
	float		sr, sp, sy, cr, cp, cy;
	
	angle = angles[YAW] * (M_PI*2 / 360);
	#ifdef PSP_VFPU
	sy = vfpu_sinf(angle);
	cy = vfpu_cosf(angle);
	#else
	sy = sinf(angle);
	cy = cosf(angle);
	#endif
	angle = angles[PITCH] * (M_PI*2 / 360);
	#ifdef PSP_VFPU
	sp = vfpu_sinf(angle);
	cp = vfpu_cosf(angle);
	#else
	sp = sinf(angle);
	cp = cosf(angle);
	#endif
	angle = angles[ROLL] * (M_PI*2 / 360);
	#ifdef PSP_VFPU
	sr = vfpu_sinf(angle);
	cr = vfpu_cosf(angle);
	#else
	sr = sinf(angle);
	cr = cosf(angle);
	#endif

	forward[0] = cp*cy;
	forward[1] = cp*sy;
	forward[2] = -sp;
	right[0] = (-1*sr*sp*cy+-1*cr*-sy);
	right[1] = (-1*sr*sp*sy+-1*cr*cy);
	right[2] = -1*sr*cp;
	up[0] = (cr*sp*cy+-sr*-sy);
	up[1] = (cr*sp*sy+-sr*cy);
	up[2] = cr*cp;
}

float VectorLength (vec3_t v)
{
	#ifdef PSP_VFPU
	return vfpu_sqrtf(DotProduct(v, v));
	#else
	return sqrtf(DotProduct(v, v));
	#endif
}

int VectorCompare (vec3_t v1, vec3_t v2)
{
	int		i;

	for (i=0 ; i<3 ; i++)
		if (v1[i] != v2[i])
			return 0;

	return 1;
}

void VectorMA (vec3_t veca, float scale, vec3_t vecb, vec3_t vecc)
{
	vecc[0] = veca[0] + scale*vecb[0];
	vecc[1] = veca[1] + scale*vecb[1];
	vecc[2] = veca[2] + scale*vecb[2];
}


vec_t _DotProduct (vec3_t v1, vec3_t v2)
{
	return v1[0]*v2[0] + v1[1]*v2[1] + v1[2]*v2[2];
}

void _VectorSubtract (vec3_t veca, vec3_t vecb, vec3_t out)
{
	out[0] = veca[0]-vecb[0];
	out[1] = veca[1]-vecb[1];
	out[2] = veca[2]-vecb[2];
}

void _VectorAdd (vec3_t veca, vec3_t vecb, vec3_t out)
{
	out[0] = veca[0]+vecb[0];
	out[1] = veca[1]+vecb[1];
	out[2] = veca[2]+vecb[2];
}

void _VectorCopy (vec3_t in, vec3_t out)
{
	out[0] = in[0];
	out[1] = in[1];
	out[2] = in[2];
}

void CrossProduct (vec3_t v1, vec3_t v2, vec3_t cross)
{
	cross[0] = v1[1]*v2[2] - v1[2]*v2[1];
	cross[1] = v1[2]*v2[0] - v1[0]*v2[2];
	cross[2] = v1[0]*v2[1] - v1[1]*v2[0];
}

vec_t Length(vec3_t v)
{
	#ifdef PSP_VFPU
	return vfpu_sqrtf(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
	#else
	return sqrtf(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
	#endif
}

float VecLength2(vec3_t v1, vec3_t v2)
{
	vec3_t k;
	VectorSubtract(v1, v2, k);
	return sqrt(k[0]*k[0] + k[1]*k[1] + k[2]*k[2]);
}

float VectorNormalize (vec3_t v)
{
	#ifdef PSP_VFPU
	float length = vfpu_sqrtf(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
	#else
	float length = sqrtf(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
	#endif

	if (length)
	{
		const float ilength = 1.0f / length;
		v[0] *= ilength;
		v[1] *= ilength;
		v[2] *= ilength;
	}
		
	return length;

}

void VectorInverse (vec3_t v)
{
	v[0] = -v[0];
	v[1] = -v[1];
	v[2] = -v[2];
}

void VectorScale (vec3_t in, vec_t scale, vec3_t out)
{
	out[0] = in[0]*scale;
	out[1] = in[1]*scale;
	out[2] = in[2]*scale;
}


int Q_log2(int val)
{
	int answer=0;
	while (val>>=1)
		answer++;
	return answer;
}


/*
================
R_ConcatRotations
================
*/
void R_ConcatRotations (float in1[3][3], float in2[3][3], float out[3][3])
{
	out[0][0] = in1[0][0] * in2[0][0] + in1[0][1] * in2[1][0] +
				in1[0][2] * in2[2][0];
	out[0][1] = in1[0][0] * in2[0][1] + in1[0][1] * in2[1][1] +
				in1[0][2] * in2[2][1];
	out[0][2] = in1[0][0] * in2[0][2] + in1[0][1] * in2[1][2] +
				in1[0][2] * in2[2][2];
	out[1][0] = in1[1][0] * in2[0][0] + in1[1][1] * in2[1][0] +
				in1[1][2] * in2[2][0];
	out[1][1] = in1[1][0] * in2[0][1] + in1[1][1] * in2[1][1] +
				in1[1][2] * in2[2][1];
	out[1][2] = in1[1][0] * in2[0][2] + in1[1][1] * in2[1][2] +
				in1[1][2] * in2[2][2];
	out[2][0] = in1[2][0] * in2[0][0] + in1[2][1] * in2[1][0] +
				in1[2][2] * in2[2][0];
	out[2][1] = in1[2][0] * in2[0][1] + in1[2][1] * in2[1][1] +
				in1[2][2] * in2[2][1];
	out[2][2] = in1[2][0] * in2[0][2] + in1[2][1] * in2[1][2] +
				in1[2][2] * in2[2][2];
}


/*
================
R_ConcatTransforms
================
*/
void R_ConcatTransforms (float in1[3][4], float in2[3][4], float out[3][4])
{
	out[0][0] = in1[0][0] * in2[0][0] + in1[0][1] * in2[1][0] +
				in1[0][2] * in2[2][0];
	out[0][1] = in1[0][0] * in2[0][1] + in1[0][1] * in2[1][1] +
				in1[0][2] * in2[2][1];
	out[0][2] = in1[0][0] * in2[0][2] + in1[0][1] * in2[1][2] +
				in1[0][2] * in2[2][2];
	out[0][3] = in1[0][0] * in2[0][3] + in1[0][1] * in2[1][3] +
				in1[0][2] * in2[2][3] + in1[0][3];
	out[1][0] = in1[1][0] * in2[0][0] + in1[1][1] * in2[1][0] +
				in1[1][2] * in2[2][0];
	out[1][1] = in1[1][0] * in2[0][1] + in1[1][1] * in2[1][1] +
				in1[1][2] * in2[2][1];
	out[1][2] = in1[1][0] * in2[0][2] + in1[1][1] * in2[1][2] +
				in1[1][2] * in2[2][2];
	out[1][3] = in1[1][0] * in2[0][3] + in1[1][1] * in2[1][3] +
				in1[1][2] * in2[2][3] + in1[1][3];
	out[2][0] = in1[2][0] * in2[0][0] + in1[2][1] * in2[1][0] +
				in1[2][2] * in2[2][0];
	out[2][1] = in1[2][0] * in2[0][1] + in1[2][1] * in2[1][1] +
				in1[2][2] * in2[2][1];
	out[2][2] = in1[2][0] * in2[0][2] + in1[2][1] * in2[1][2] +
				in1[2][2] * in2[2][2];
	out[2][3] = in1[2][0] * in2[0][3] + in1[2][1] * in2[1][3] +
				in1[2][2] * in2[2][3] + in1[2][3];
}


/*
===================
FloorDivMod

Returns mathematically correct (floor-based) quotient and remainder for
numer and denom, both of which should contain no fractional part. The
quotient must fit in 32 bits.
====================
*/

void FloorDivMod (float numer, float denom, int *quotient,
		int *rem)
{
	int		q, r;
	float	x;

	if (denom <= 0.0)
		Sys_Error ("FloorDivMod: bad denominator %d\n", denom);

	if (numer >= 0.0)
	{

		x = floorf(numer / denom);
		q = (int)x;
		r = (int)floorf(numer - (x * denom));
	}
	else
	{
	//
	// perform operations with positive values, and fix mod to make floor-based
	//
		x = floorf(-numer / denom);
		q = -(int)x;
		r = (int)floorf(-numer - (x * denom));
		if (r != 0)
		{
			q--;
			r = (int)denom - r;
		}
	}

	*quotient = q;
	*rem = r;
}


/*
===================
GreatestCommonDivisor
====================
*/
int GreatestCommonDivisor (int i1, int i2)
{
	if (i1 > i2)
	{
		if (i2 == 0)
			return (i1);
		return GreatestCommonDivisor (i2, i1 % i2);
	}
	else
	{
		if (i1 == 0)
			return (i2);
		return GreatestCommonDivisor (i1, i2 % i1);
	}
}


#if	!id386

// TODO: move to nonintel.c

/*
===================
Invert24To16

Inverts an 8.24 value to a 16.16 value
====================
*/

fixed16_t Invert24To16(fixed16_t val)
{
	if (val < 256)
		return (0xFFFFFFFF);

	return (fixed16_t)
			(((float)0x10000 * (float)0x1000000 / (float)val) + 0.5);
}

#endif

void VectorTransform (const vec3_t in1, matrix3x4 in2, vec3_t out)
{
	out[0] = DotProduct(in1, in2[0]) + in2[0][3];
	out[1] = DotProduct(in1, in2[1]) +	in2[1][3];
	out[2] = DotProduct(in1, in2[2]) +	in2[2][3];
}

void AngleQuaternion( const vec3_t angles, vec4_t quaternion )
{
	float		angle;
	float		sr, sp, sy, cr, cp, cy;

	// FIXME: rescale the inputs to 1/2 angle
	angle = angles[2] * 0.5;
	#ifdef PSP_VFPU
	sy = vfpu_sinf(angle);
	cy = vfpu_cosf(angle);
	#else
	sy = sin(angle);
	cy = cos(angle);
	#endif
	angle = angles[1] * 0.5;
	#ifdef PSP_VFPU
	sp = vfpu_sinf(angle);
	cp = vfpu_cosf(angle);
	#else
	sp = sin(angle);
	cp = cos(angle);
	#endif
	angle = angles[0] * 0.5;
	#ifdef PSP_VFPU
	sr = vfpu_sinf(angle);
	cr = vfpu_cosf(angle);
	#else
	sr = sin(angle);
	cr = cos(angle);
	#endif

	quaternion[0] = sr*cp*cy-cr*sp*sy; // X
	quaternion[1] = cr*sp*cy+sr*cp*sy; // Y
	quaternion[2] = cr*cp*sy-sr*sp*cy; // Z
	quaternion[3] = cr*cp*cy+sr*sp*sy; // W
}

void QuaternionMatrix( const vec4_t quaternion, float (*matrix)[4] )
{

	matrix[0][0] = 1.0 - 2.0 * quaternion[1] * quaternion[1] - 2.0 * quaternion[2] * quaternion[2];
	matrix[1][0] = 2.0 * quaternion[0] * quaternion[1] + 2.0 * quaternion[3] * quaternion[2];
	matrix[2][0] = 2.0 * quaternion[0] * quaternion[2] - 2.0 * quaternion[3] * quaternion[1];

	matrix[0][1] = 2.0 * quaternion[0] * quaternion[1] - 2.0 * quaternion[3] * quaternion[2];
	matrix[1][1] = 1.0 - 2.0 * quaternion[0] * quaternion[0] - 2.0 * quaternion[2] * quaternion[2];
	matrix[2][1] = 2.0 * quaternion[1] * quaternion[2] + 2.0 * quaternion[3] * quaternion[0];

	matrix[0][2] = 2.0 * quaternion[0] * quaternion[2] + 2.0 * quaternion[3] * quaternion[1];
	matrix[1][2] = 2.0 * quaternion[1] * quaternion[2] - 2.0 * quaternion[3] * quaternion[0];
	matrix[2][2] = 1.0 - 2.0 * quaternion[0] * quaternion[0] - 2.0 * quaternion[1] * quaternion[1];
}

void QuaternionSlerp( const vec4_t p, vec4_t q, float t, vec4_t qt )
{
	int i;
	float omega, cosom, sinom, sclp, sclq;

	// decide if one of the quaternions is backwards
	float a = 0;
	float b = 0;
	for (i = 0; i < 4; i++) {
		a += (p[i]-q[i])*(p[i]-q[i]);
		b += (p[i]+q[i])*(p[i]+q[i]);
	}
	if (a > b) {
		for (i = 0; i < 4; i++) {
			q[i] = -q[i];
		}
	}

	cosom = p[0]*q[0] + p[1]*q[1] + p[2]*q[2] + p[3]*q[3];

	if ((1.0 + cosom) > 0.00000001) {
		if ((1.0 - cosom) > 0.00000001) {
			omega = acos( cosom );
			#ifdef PSP_VFPU
			sinom = vfpu_sinf( omega );
			sclp = vfpu_sinf( (1.0 - t)*omega) / sinom;
			sclq = vfpu_sinf( t*omega ) / sinom;
			#else
			sinom = sin( omega );
			sclp = sin( (1.0 - t)*omega) / sinom;
			sclq = sin( t*omega ) / sinom;
			#endif
		}
		else {
			sclp = 1.0 - t;
			sclq = t;
		}
		for (i = 0; i < 4; i++) {
			qt[i] = sclp * p[i] + sclq * q[i];
		}
	}
	else {
		qt[0] = -p[1];
		qt[1] = p[0];
		qt[2] = -p[3];
		qt[3] = p[2];
		#ifdef PSP_VFPU
		sclp = vfpu_sinf( (1.0 - t) * 0.5 * M_PI);
		sclq = vfpu_sinf( t * 0.5 * M_PI);
		#else
		sclp = sin( (1.0 - t) * 0.5 * M_PI);
		sclq = sin( t * 0.5 * M_PI);
		#endif
		for (i = 0; i < 3; i++) {
			qt[i] = sclp * p[i] + sclq * qt[i];
		}
	}
}
