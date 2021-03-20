/*
Copyright (C) 2007 Peter Mackay and Chris Swindle.
Copyright (C) 2021 Sergey Galushko

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

#define CLIPPING_DEBUGGING	0
#define CLIP_LEFT			1
#define CLIP_RIGHT			1
#define CLIP_BOTTOM			1
#define CLIP_TOP			1
#define CLIP_NEAR			0
#define CLIP_FAR			0

#include "clipping.hpp"

#include <algorithm>
#include <pspgu.h>
#include <pspgum.h>

#include "math.hpp"

extern "C"
{
#include "../quakedef.h"
}

namespace quake
{
	namespace clipping
	{
		// Plane types are sorted, most likely to clip first.
		enum plane_index
		{
#if CLIP_BOTTOM
			plane_index_bottom,
#endif
#if CLIP_LEFT
			plane_index_left,
#endif
#if CLIP_RIGHT
			plane_index_right,
#endif
#if CLIP_TOP
			plane_index_top,
#endif
#if CLIP_NEAR
			plane_index_near,
#endif
#if CLIP_FAR
			plane_index_far,
#endif
			plane_count
		};

		// Types.
		typedef ScePspFVector4	plane_type;
		typedef plane_type		frustum_t[plane_count];

		// Transformed frustum.
		static ScePspFMatrix4		projection_view_matrix __attribute__((aligned(16)));
		static frustum_t			projection_view_frustum __attribute__((aligned(16)));
		static frustum_t			clipping_frustum __attribute__((aligned(16)));

		// The temporary working buffers.
		static const std::size_t	max_clipped_vertices	= 32;
		static glvert_t				work_buffer[2][max_clipped_vertices] __attribute__((aligned(16)));

		static inline void calculate_frustum(const ScePspFMatrix4& clip, frustum_t* frustum)
		{
			__asm__ (
				".set		push\n"					// save assembler option
				".set		noreorder\n"			// suppress reordering
		#if CLIP_NEAR_FAR
				"lv.q		C000,  0(%6)\n"			// C000 = clip->x
				"lv.q		C010, 16(%6)\n"			// C010 = clip->y
				"lv.q		C020, 32(%6)\n"			// C020 = clip->z
				"lv.q		C030, 48(%6)\n"			// C030 = clip->w
		#else
				"lv.q		C000,  0(%4)\n"			// C000 = clip->x
				"lv.q		C010, 16(%4)\n"			// C010 = clip->y
				"lv.q		C020, 32(%4)\n"			// C020 = clip->z
				"lv.q		C030, 48(%4)\n"			// C030 = clip->w
		#endif
				/* Extract the BOTTOM plane */
				"vadd.s		S100, S003, S001\n"		// S100 = clip->x.w + clip->x.y
				"vadd.s		S101, S013, S011\n"		// S101 = clip->y.w + clip->y.y
				"vadd.s		S102, S023, S021\n"		// S102 = clip->z.w + clip->z.y
				"vadd.s		S103, S033, S031\n"		// S103 = clip->w.w + clip->w.y
				"vdot.q		S110, C100, C100\n"		// S110 = S100*S100 + S101*S101 + S102*S102 + S103*S103
				"vzero.s	S111\n"					// S111 = 0
				"vcmp.s		EZ,   S110\n"			// CC[0] = ( S110 == 0.0f )
				"vrsq.s		S110, S110\n"			// S110 = 1.0 / sqrt( S110 )
				"vcmovt.s	S110, S111, 0\n"		// if ( CC[0] ) S110 = S111
				"vscl.q		C100[-1:1,-1:1,-1:1,-1:1], C100, S110\n"	// C100 = C100 * S110
				"sv.q		C100, %0\n"				// Store plane from register
				/* Extract the LEFT plane */
				"vadd.s		S100, S003, S000\n"		// S100 = clip->x.w + clip->x.x
				"vadd.s		S101, S013, S010\n"		// S101 = clip->y.w + clip->y.x
				"vadd.s		S102, S023, S020\n"		// S102 = clip->z.w + clip->z.x
				"vadd.s		S103, S033, S030\n"		// S103 = clip->w.w + clip->w.x
				"vdot.q		S110, C100, C100\n"		// S110 = S100*S100 + S101*S101 + S102*S102 + S103*S103
				"vzero.s	S111\n"					// S111 = 0
				"vcmp.s		EZ,   S110\n"			// CC[0] = ( S110 == 0.0f )
				"vrsq.s		S110, S110\n"			// S110 = 1.0 / sqrt( S110 )
				"vcmovt.s	S110, S111, 0\n"		// if ( CC[0] ) S110 = S111
				"vscl.q		C100[-1:1,-1:1,-1:1,-1:1], C100, S110\n"	// C100 = C100 * S110
				"sv.q		C100, %1\n"				// Store plane from register
				/* Extract the RIGHT plane */
				"vsub.s		S100, S003, S000\n"		// S100 = clip->x.w - clip->x.x
				"vsub.s		S101, S013, S010\n"		// S101 = clip->y.w - clip->y.x
				"vsub.s		S102, S023, S020\n"		// S102 = clip->z.w - clip->z.x
				"vsub.s		S103, S033, S030\n"		// S103 = clip->w.w - clip->w.x	
				"vdot.q		S110, C100, C100\n"		// S110 = S100*S100 + S101*S101 + S102*S102 + S103*S103
				"vzero.s	S111\n"					// S111 = 0
				"vcmp.s		EZ,   S110\n"			// CC[0] = ( S110 == 0.0f )
				"vrsq.s		S110, S110\n"			// S110 = 1.0 / sqrt( S110 )
				"vcmovt.s	S110, S111, 0\n"		// if ( CC[0] ) S110 = S111
				"vscl.q		C100[-1:1,-1:1,-1:1,-1:1], C100, S110\n"	// C100 = C100 * S110
				"sv.q		C100, %2\n"				// Store plane from register	
				/* Extract the TOP plane */
				"vsub.s		S100, S003, S001\n"		// S100 = clip->x.w - clip->x.y
				"vsub.s		S101, S013, S011\n"		// S101 = clip->y.w - clip->y.y
				"vsub.s		S102, S023, S021\n"		// S102 = clip->z.w - clip->z.y
				"vsub.s		S103, S033, S031\n"		// S103 = clip->w.w - clip->w.y	
				"vdot.q		S110, C100, C100\n"		// S110 = S100*S100 + S101*S101 + S102*S102 + S103*S103
				"vzero.s	S111\n"					// S111 = 0
				"vcmp.s		EZ,   S110\n"			// CC[0] = ( S110 == 0.0f )
				"vrsq.s		S110, S110\n"			// S110 = 1.0 / sqrt( S110 )
				"vcmovt.s	S110, S111, 0\n"		// if ( CC[0] ) S110 = S111
				"vscl.q		C100[-1:1,-1:1,-1:1,-1:1], C100, S110\n"	// C100 = C100 * S110
				"sv.q		C100, %3\n"				// Store plane from register	
		#if CLIP_NEAR_FAR
				/* Extract the NEAR plane */
				"vadd.s		S100, S003, S002\n"		// S100 = clip->x.w + clip->x.z
				"vadd.s		S101, S013, S012\n"		// S101 = clip->y.w + clip->y.z
				"vadd.s		S102, S023, S022\n"		// S102 = clip->z.w + clip->z.z
				"vadd.s		S103, S033, S032\n"		// S103 = clip->w.w + clip->w.z	
				"vdot.q		S110, C100, C100\n"		// S110 = S100*S100 + S101*S101 + S102*S102 + S103*S103
				"vzero.s	S111\n"					// S111 = 0
				"vcmp.s		EZ,   S110\n"			// CC[0] = ( S110 == 0.0f )
				"vrsq.s		S110, S110\n"			// S110 = 1.0 / sqrt( S110 )
				"vcmovt.s	S110, S111, 0\n"		// if ( CC[0] ) S110 = S111
				"vscl.q		C100[-1:1,-1:1,-1:1,-1:1], C100, S110\n"	// C100 = C100 * S110
				"sv.q		C100, %4\n"				// Store plane from register	
				/* Extract the FAR plane */
				"vsub.s		S100, S003, S002\n"		// S100 = clip->x.w - clip->x.z
				"vsub.s		S101, S013, S012\n"		// S101 = clip->y.w - clip->y.z
				"vsub.s		S102, S023, S022\n"		// S102 = clip->z.w - clip->z.z
				"vsub.s		S103, S033, S032\n"		// S103 = clip->w.w - clip->w.z	
				"vdot.q		S110, C100, C100\n"		// S110 = S100*S100 + S101*S101 + S102*S102 + S103*S103
				"vzero.s	S111\n"					// S111 = 0
				"vcmp.s		EZ,   S110\n"			// CC[0] = ( S110 == 0.0f )
				"vrsq.s		S110, S110\n"			// S110 = 1.0 / sqrt( S110 )
				"vcmovt.s	S110, S111, 0\n"		// if ( CC[0] ) S110 = S111
				"vscl.q		C100[-1:1,-1:1,-1:1,-1:1], C100, S110\n"	// C100 = C100 * S110
				"sv.q		C100, %5\n"				// Store plane from register
		#endif
				".set		pop\n"					// Restore assembler option
				:	"=m"( ( *frustum )[plane_index_bottom] ),
					"=m"( ( *frustum )[plane_index_left] ),
					"=m"( ( *frustum )[plane_index_right] ),
		#if CLIP_NEAR_FAR
					"=m"( ( *frustum )[plane_index_top] ),
					"=m"( ( *frustum )[plane_index_near] ),
					"=m"( ( *frustum )[plane_index_far] )
		#else
					"=m"( ( *frustum )[plane_index_top] )
		#endif
				:	"r"( &clip )
			);
		}

		void begin_frame()
		{
			// Get the projection matrix.
			sceGumMatrixMode(GU_PROJECTION);
			ScePspFMatrix4	proj;
			sceGumStoreMatrix(&proj);

			// Get the view matrix.
			sceGumMatrixMode(GU_VIEW);
			ScePspFMatrix4	view;
			sceGumStoreMatrix(&view);

			// Restore matrix mode.
			sceGumMatrixMode(GU_MODEL);

			// Combine the two matrices (multiply projection by view).
			gumMultMatrix(&projection_view_matrix, &proj, &view);

			// Calculate and cache the clipping frustum.
			calculate_frustum(projection_view_matrix, &projection_view_frustum);

			__asm__ volatile (
				"ulv.q		C700, %4\n"				// Load plane into register
				"ulv.q		C710, %5\n"				// Load plane into register
				"ulv.q		C720, %6\n"				// Load plane into register
				"ulv.q		C730, %7\n"				// Load plane into register
				"sv.q		C700, %0\n"				// Store plane from register
				"sv.q		C710, %1\n"				// Store plane from register
				"sv.q		C720, %2\n"				// Store plane from register
				"sv.q		C730, %3\n"				// Store plane from register
				:	"=m"( clipping_frustum[plane_index_bottom] ),
					"=m"( clipping_frustum[plane_index_left] ),
					"=m"( clipping_frustum[plane_index_right] ),
					"=m"( clipping_frustum[plane_index_top] )
				:	"m"( projection_view_frustum[plane_index_bottom] ),
					"m"( projection_view_frustum[plane_index_left] ),
					"m"( projection_view_frustum[plane_index_right] ),
					"m"( projection_view_frustum[plane_index_top] )
			);
		}

		void begin_brush_model()
		{
			// Get the model matrix.
			ScePspFMatrix4	model_matrix;
			sceGumStoreMatrix(&model_matrix);

			// Combine the matrices (multiply projection-view by model).
			ScePspFMatrix4	projection_view_model_matrix;
			gumMultMatrix(&projection_view_model_matrix, &projection_view_matrix, &model_matrix);

			// Calculate the clipping frustum.
			calculate_frustum(projection_view_model_matrix, &clipping_frustum);

			__asm__ volatile (
				"ulv.q	C700, %0\n"	// Load plane into register
				"ulv.q	C710, %1\n"	// Load plane into register
				"ulv.q	C720, %2\n"	// Load plane into register
				"ulv.q	C730, %3\n"	// Load plane into register
				:: "m"(clipping_frustum[plane_index_bottom]),
					"m"(clipping_frustum[plane_index_left]),
					"m"(clipping_frustum[plane_index_right]), 
					"m"(clipping_frustum[plane_index_top])
			);
		}

		void end_brush_model()
		{
			// Restore the clipping frustum.
			__asm__ volatile (
				"ulv.q		C700, %4\n"				// Load plane into register
				"ulv.q		C710, %5\n"				// Load plane into register
				"ulv.q		C720, %6\n"				// Load plane into register
				"ulv.q		C730, %7\n"				// Load plane into register
				"sv.q		C700, %0\n"				// Store plane from register
				"sv.q		C710, %1\n"				// Store plane from register
				"sv.q		C720, %2\n"				// Store plane from register
				"sv.q		C730, %3\n"				// Store plane from register
				:	"=m"( clipping_frustum[plane_index_bottom] ),
					"=m"( clipping_frustum[plane_index_left] ),
					"=m"( clipping_frustum[plane_index_right] ),
					"=m"( clipping_frustum[plane_index_top] )
				:	"m"( projection_view_frustum[plane_index_bottom] ),
					"m"( projection_view_frustum[plane_index_left] ),
					"m"( projection_view_frustum[plane_index_right] ),
					"m"( projection_view_frustum[plane_index_top] )
			);
		}

		// Is clipping required?
		bool is_clipping_required(const struct glvert_s* vertices, std::size_t vertex_count)
		{
			int res;
			__asm__ (
				".set		push\n"					// save assembler option
				".set		noreorder\n"			// suppress reordering
				"move		$8,   %1\n"				// $8 = &vertices[0]
				"move		$9,   %2\n"				// $9 = vertex_count
				"li			$10,  20\n"				// $10 = 20( sizeof(glvert_t) )
				"mul		$10,  $10,   $9\n"		// $10 = $10 * $9
				"addu		$10,  $10,   $8\n"		// $10 = $10 + $8
			"0:\n"									// loop
				"ulv.q		C610, 8($8)\n"			// Load vertex into register skip tex cord 8 byte
				"vone.s		S613\n"					// Now set the 4th entry to be 1 as that is just random
				"vdot.q		S620, C700, C610\n"		// S620 = v[i] * frustrum[0]
				"vdot.q		S621, C710, C610\n"		// S621 = v[i] * frustrum[1]
				"vdot.q		S622, C720, C610\n"		// S622 = v[i] * frustrum[2]
				"vdot.q		S623, C730, C610\n"		// S623 = v[i] * frustrum[3]
				"vzero.q	C610\n"					// C610 = [0.0f, 0.0f, 0.0f. 0.0f]
				"addiu		%0,   $0, 1\n"			// res = 1
				"vcmp.q		LT,   C620, C610\n"		// S620 < 0.0f || S621 < 0.0f || S622 < 0.0f || S623 < 0.0f
				"bvt		4,    1f\n"				// if ( CC[4] == 1 ) jump to exit
				"addiu		$8,   $8,   20\n"		// $8 = $8 + 20( sizeof(glvert_t) )
				"bne		$10,  $8,   0b\n"		// if ( $9 != 0 ) jump to loop
				"move		%0,   $0\n"				// res = 0
			"1:\n"									// exit
				".set		pop\n"					// Restore assembler option
				:	"=r"(res)
				:	"r"(vertices), "r"(vertex_count)
				:	"$8", "$9", "$10"
			);
			return (res == 1) ? true : false;
		}

		// Clips a polygon against a plane.
		// http://hpcc.engin.umich.edu/CFD/users/charlton/Thesis/html/node90.html
		static void clip_to_plane(
			const plane_type& plane,
			const glvert_t* const unclipped_vertices,
			std::size_t const unclipped_vertex_count,
			glvert_t* const clipped_vertices,
			std::size_t* const clipped_vertex_count)
		{
			__asm__ (
				".set		push\n"					// save assembler option
				".set		noreorder\n"			// suppress reordering
				"move		$8,   %1\n"				// $8 = uv[0] is S
				"addiu		$9,   $8,   20\n" 		// $9 = uv[1] is P
				"move		$10,  %2\n"				// $10 = uvc
				"li			$11,  20\n"				// $11 = 20( sizeof( gu_vert_t ) )
				"mul		$11,  $11,  $10\n"		// $11 = $11 * $10
				"addu		$11,  $11,  $8\n"		// $11 = $11 + $8
				"move		$12,  %3\n"				// $12 = &cv[0]
				"move		%0,   $0\n"				// cvc = 0
				"ulv.q		C100, %4\n"				// Load plane into register
				"vzero.s	S110\n"					// Set zero for cmp
			"0:\n"									// loop
				"ulv.q		C000,  0($8)\n"			// Load vertex S TEX(8b) into register
				"vzero.p	C002\n"					// Set the 3th and 4th entry C000 to zero
				"ulv.q		C010,  8($8)\n"			// Load vertex S XYZ(12b) into register
				"vzero.s	S013\n"					// Set the 4th entry C010 to zero
				"ulv.q		C020,  0($9)\n"			// Load vertex P TEX(8b) into register
				"vzero.p	C022\n"					// Set the 3th and 4th entry C020 to zero
				"ulv.q		C030,  8($9)\n"			// Load vertex P XYZ(12b) into register
				"vzero.s	S033\n"					// Set the 4th entry C030 to zero
				"vdot.q		S111, C100, C010\n"		// S111 = plane * S
				"vdot.q		S112, C100, C030\n"		// S112 = plane * P
				"vadd.s		S111, S111, S103\n"		// S111 = S111 + plane->w is S dist
				"vadd.s		S112, S112, S103\n"		// S112 = S112 + plane->w is P dist
				"vcmp.s		LE,   S111, S110\n"		// (S dist <= 0.0f)
				"bvt		0,    2f\n"				// if ( CC[0] == 1 ) jump to 2f
				"nop\n"								// 										( delay slot )
				"vcmp.s		LE,   S112, S110\n"		// (P dist <= 0.0f)
				"bvt		0,    1f\n"				// if ( CC[0] == 1 ) jump to 1f
				"nop\n"								// 										( delay slot )
				"sv.s		S020,  0($12)\n"		// cv->uv[0]  = C020 TEX U
				"sv.s		S021,  4($12)\n"		// cv->uv[1]  = C021 TEX V
				"sv.s		S030,  8($12)\n"		// cv->xyz[0] = C030 XYZ X
				"sv.s		S031, 12($12)\n"		// cv->xyz[1] = C031 XYZ Y
				"sv.s		S032, 16($12)\n"		// cv->xyz[2] = C032 XYZ Z
				"addiu		$12,  $12,  20\n"		// $12 = $12 + 20( sizeof( gu_vert_t ) )
				"j			3f\n"					// jump to next
				"addiu		%0,   %0,	1\n"		// cvc += 1								( delay slot )
			"1:\n"
				"vsub.s		S112, S111, S112\n"		// S112 = ( S dist - P dist )
				"vdiv.s		S112, S111, S112\n"		// S112 = S111 / S112
				"vsub.q		C120, C020, C000\n"		// C120 = C020(P TEX) - C000(S TEX)
				"vsub.q		C130, C030, C010\n"		// C130 = C030(P XYZ) - C010(S XYZ)
				"vscl.q		C120, C120, S112\n"		// C120 = C020 * S112
				"vscl.q		C130, C130, S112\n"		// C130 = C030 * S112
				"vadd.q		C120, C120, C000\n"		// C120 = C120 + C000(S TEX)
				"vadd.q		C130, C130, C010\n"		// C130 = C130 + C010(S XYZ)
				"sv.s		S120,  0($12)\n"		// cv->uv[0]  = S120 TEX U
				"sv.s		S121,  4($12)\n"		// cv->uv[1]  = S121 TEX V
				"sv.s		S130,  8($12)\n"		// cv->xyz[0] = S130 XYZ X
				"sv.s		S131, 12($12)\n"		// cv->xyz[1] = S131 XYZ Y
				"sv.s		S132, 16($12)\n"		// cv->xyz[2] = S132 XYZ Z
				"addiu		$12,  $12,  20\n"		// $12 = $12 + 20( sizeof( gu_vert_t ) )
				"j			3f\n"					// jump to next
				"addiu		%0,   %0,	1\n"		// cvc += 1								( delay slot )
			"2:\n"
				"vcmp.s		LE,   S112, S110\n"		// (P dist <= 0.0f)
				"bvt		0,    3f\n"				// if ( CC[0] == 1 ) jump to next
				"nop\n"								// 										( delay slot )
				"vsub.s		S112, S111, S112\n"		// S112 = ( S dist - P dist )
				"vdiv.s		S112, S111, S112\n"		// S112 = S111 / S112
				"vsub.q		C120, C020, C000\n"		// C120 = C020(P TEX) - C000(S TEX)
				"vsub.q		C130, C030, C010\n"		// C130 = C030(P XYZ) - C010(S XYZ)
				"vscl.q		C120, C120, S112\n"		// C120 = C020 * S112
				"vscl.q		C130, C130, S112\n"		// C130 = C030 * S112
				"vadd.q		C120, C120, C000\n"		// C120 = C120 + C000(S TEX)
				"vadd.q		C130, C130, C010\n"		// C130 = C130 + C010(S XYZ)
				"sv.s		S120,  0($12)\n"		// cv->uv[0]  = S120 TEX U
				"sv.s		S121,  4($12)\n"		// cv->uv[1]  = S121 TEX V
				"sv.s		S130,  8($12)\n"		// cv->xyz[0] = S130 XYZ X
				"sv.s		S131, 12($12)\n"		// cv->xyz[1] = S131 XYZ Y
				"sv.s		S132, 16($12)\n"		// cv->xyz[2] = S132 XYZ Z
				"addiu		$12,  $12,  20\n"		// $12 = $12 + 20( sizeof( gu_vert_t ) )
				"addiu		%0,   %0,	1\n"		// cvc += 1
				"sv.s		S020,  0($12)\n"		// cv->uv[0]  = S020 TEX U
				"sv.s		S021,  4($12)\n"		// cv->uv[1]  = S021 TEX V
				"sv.s		S030,  8($12)\n"		// cv->xyz[0] = S030 XYZ X
				"sv.s		S031, 12($12)\n"		// cv->xyz[1] = S031 XYZ Y
				"sv.s		S032, 16($12)\n"		// cv->xyz[2] = S032 XYZ Z
				"addiu		$12,  $12,  20\n"		// $12 = $12 + 20( sizeof( gu_vert_t ) )
				"addiu		%0,   %0,	1\n"		// cvc += 1
			"3:\n"									// next
				"addiu		$8,   $8,   20\n"		// $8 = $8 + 20( sizeof( gu_vert_t ) )
				"addiu		$9,   $8,   20\n" 		// $9 = $8 + 20( sizeof( gu_vert_t ) )
				"bne		$9,   $11,  4f\n"		// if ( $11 != $9 ) jump to next
				"nop\n"
				"move		$9,   %1\n"				// $9 = &uv[0] set P
			"4:\n"
				"bne		$11,  $8,   0b\n"		// if ( $11 != $8 ) jump to loop
				"nop\n"								// 										( delay slot )
				".set		pop\n"					// Restore assembler option
				:	"+r"( *clipped_vertex_count )
				:	"r"( unclipped_vertices ), "r"( unclipped_vertex_count ), "r"( clipped_vertices ), "m"( plane )
				:	"$8", "$9", "$10", "$11", "$12"
			);
		}

		// Clips a polygon against the frustum.
		void clip(
			const struct glvert_s* unclipped_vertices,
			std::size_t unclipped_vertex_count,
			const struct glvert_s** clipped_vertices,
			std::size_t* clipped_vertex_count)
		{
			// No vertices to clip?
			if (!unclipped_vertex_count)
			{
				// Error.
				Sys_Error("Calling clip with zero vertices");
			}

			// Set up constants.
			const plane_type* const	last_plane		= &clipping_frustum[plane_count];

			// Set up the work buffer pointers.
			const glvert_t*			src				= unclipped_vertices;
			glvert_t*				dst				= work_buffer[0];
			std::size_t				vertex_count	= unclipped_vertex_count;

			// For each frustum plane...
			for (const plane_type* plane = &clipping_frustum[0]; plane != last_plane; ++plane)
			{
				// Clip the poly against this frustum plane.
				clip_to_plane(*plane, src, vertex_count, dst, &vertex_count);

				// No vertices left to clip?
				if (!vertex_count)
				{
					// Quit early.
					*clipped_vertex_count = 0;
					return;
				}

				// Use the next pair of buffers.
				src = dst;
				if (dst == work_buffer[0])
				{
					dst = work_buffer[1];
				}
				else
				{
					dst = work_buffer[0];
				}
			}

			// Fill in the return data.
			*clipped_vertices		= src;
			*clipped_vertex_count	= vertex_count;
		}
	}
}
