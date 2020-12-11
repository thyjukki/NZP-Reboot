/*
Copyright (C) 2007 Peter Mackay and Chris Swindle.

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
		static ScePspFMatrix4		projection_view_matrix;
		static frustum_t			projection_view_frustum;
		static frustum_t			clipping_frustum;

		// The temporary working buffers.
		static const std::size_t	max_clipped_vertices	= 32;
		static glvert_t				work_buffer[2][max_clipped_vertices];

		static inline void calculate_frustum(const ScePspFMatrix4& clip, frustum_t* frustum)
		{
#if CLIP_NEAR
			/* Extract the NEAR plane */
			plane_type* const near = &(*frustum)[plane_index_near];
			near->x = clip.x.w + clip.x.z;
			near->y = clip.y.w + clip.y.z;
			near->z = clip.z.w + clip.z.z;
			near->w = clip.w.w + clip.w.z;

			/* Normalize the result */
			math::normalise(near);
#endif

#if CLIP_FAR
			/* Extract the FAR plane */
			plane_type* const far = &(*frustum)[plane_index_far];
			far->x = clip.x.w - clip.x.z;
			far->y = clip.y.w - clip.y.z;
			far->z = clip.z.w - clip.z.z;
			far->w = clip.w.w - clip.w.z;

			/* Normalize the result */
			math::normalise(far);
#endif

#if CLIP_LEFT
			/* Extract the numbers for the LEFT plane */
			plane_type* const left = &(*frustum)[plane_index_left];
			left->x = clip.x.w + clip.x.x;
			left->y = clip.y.w + clip.y.x;
			left->z = clip.z.w + clip.z.x;
			left->w = clip.w.w + clip.w.x;

			/* Normalize the result */
			math::normalise(left);
#endif

#if CLIP_RIGHT
			/* Extract the numbers for the RIGHT plane */
			plane_type* const right = &(*frustum)[plane_index_right];
			right->x = clip.x.w - clip.x.x;
			right->y = clip.y.w - clip.y.x;
			right->z = clip.z.w - clip.z.x;
			right->w = clip.w.w - clip.w.x;

			/* Normalize the result */
			math::normalise(right);
#endif

#if CLIP_BOTTOM
			/* Extract the BOTTOM plane */
			plane_type* const bottom = &(*frustum)[plane_index_bottom];
			bottom->x = clip.x.w + clip.x.y;
			bottom->y = clip.y.w + clip.y.y;
			bottom->z = clip.z.w + clip.z.y;
			bottom->w = clip.w.w + clip.w.y;

			/* Normalize the result */
			math::normalise(bottom);
#endif

#if CLIP_TOP
			/* Extract the TOP plane */
			plane_type* const top = &(*frustum)[plane_index_top];
			top->x = clip.x.w - clip.x.y;
			top->y = clip.y.w - clip.y.y;
			top->z = clip.z.w - clip.z.y;
			top->w = clip.w.w - clip.w.y;

			/* Normalize the result */
			math::normalise(top);
#endif
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
			math::multiply(view, proj, &projection_view_matrix);

			// Calculate and cache the clipping frustum.
			calculate_frustum(projection_view_matrix, &projection_view_frustum);
			memcpy(clipping_frustum, projection_view_frustum, sizeof(frustum_t));

			__asm__ volatile (
				"ulv.q	C700, %0\n"	// Load plane into register
				"ulv.q	C710, %1\n"	// Load plane into register
				"ulv.q	C720, %2\n"	// Load plane into register
				"ulv.q	C730, %3\n"	// Load plane into register
				:: "m"(clipping_frustum[0]),"m"(clipping_frustum[1]),"m"(clipping_frustum[2]),"m"(clipping_frustum[3])
			);


		}

		void begin_brush_model()
		{
			// Get the model matrix.
			ScePspFMatrix4	model_matrix;
			sceGumStoreMatrix(&model_matrix);

			// Combine the matrices (multiply projection-view by model).
			ScePspFMatrix4	projection_view_model_matrix;
			math::multiply(model_matrix, projection_view_matrix, &projection_view_model_matrix);

			// Calculate the clipping frustum.
			calculate_frustum(projection_view_model_matrix, &clipping_frustum);

			__asm__ volatile (
				"ulv.q	C700, %0\n"	// Load plane into register
				"ulv.q	C710, %1\n"	// Load plane into register
				"ulv.q	C720, %2\n"	// Load plane into register
				"ulv.q	C730, %3\n"	// Load plane into register
				:: "m"(clipping_frustum[0]),
					"m"(clipping_frustum[1]),
					"m"(clipping_frustum[2]),
					"m"(clipping_frustum[3])
			);
		}

		void end_brush_model()
		{
			// Restore the clipping frustum.
			memcpy(clipping_frustum, projection_view_frustum, sizeof(frustum_t));

			__asm__ volatile (
				"ulv.q	C700, %0\n"	// Load plane into register
				"ulv.q	C710, %1\n"	// Load plane into register
				"ulv.q	C720, %2\n"	// Load plane into register
				"ulv.q	C730, %3\n"	// Load plane into register
				:: "m"(clipping_frustum[0]),
					"m"(clipping_frustum[1]),
					"m"(clipping_frustum[2]),
					"m"(clipping_frustum[3])
			);
		}

		// Is a point on the front side of the plane?
		static inline bool point_in_front_of_plane(const vec3_t point, const plane_type& plane)
		{
			return ((plane.x * point[0]) + (plane.y * point[1]) + (plane.z * point[2]) + plane.w) > 0.0f;
		}

		// Is clipping required?
		bool is_clipping_required(const struct glvert_s* vertices, std::size_t vertex_count)
		{
			float out1, out2, out3, out4;
			const glvert_t* const	last_vertex	= &vertices[vertex_count];

			// For each vertex...
			for (const glvert_t* vertex = vertices; vertex != last_vertex; ++vertex)
			{
				__asm__ volatile (
					"ulv.q	C610, %4\n"			// Load vertex into register
					"vone.s	S613\n"				// Now set the 4th entry to be 1 as that is just random
					"vdot.q	S620, C700, C610\n"	// s620 = vertex->xyx . frustrum[0]
					"vdot.q	S621, C710, C610\n"	// s621 = vertex->xyx . frustrum[1]
					"vdot.q	S622, C720, C610\n"	// s622 = vertex->xyx . frustrum[2]
					"vdot.q	S623, C730, C610\n"	// s623 = vertex->xyx . frustrum[3]
					"mfv	%0, S620\n"			// out1 = s620
					"mfv	%1, S621\n"			// out2 = s621
					"mfv	%2, S622\n"			// out3 = s622
					"mfv	%3, S623\n"			// out4 = s623
					: "=r"(out1), "=r"(out2), "=r"(out3), "=r"(out4) : "m"(*vertex->xyz)
				);

				// Should be possible to move this within the VFPU code and just check one value here
				if ((out1 < 0.0f) || (out2 < 0.0f) || (out3 < 0.0f) || (out4 < 0.0f))
				{
					return true;
				}
			}

			// This polygon is all inside the frustum.
			return false;
		}

		static inline glvert_t calculate_intersection(const plane_type& plane, const glvert_t& v1, const glvert_t& v2)
		{
			// Work out the difference between the vertices.
			const glvert_t delta =
			{
				{
					v2.st[0] - v1.st[0],
						v2.st[1] - v1.st[1]
				},
				{
					v2.xyz[0] - v1.xyz[0],
						v2.xyz[1] - v1.xyz[1],
						v2.xyz[2] - v1.xyz[2]
				}
			};

			// Horrible math.
			const float top		= (plane.x * v1.xyz[0]) + (plane.y * v1.xyz[1]) + (plane.z * v1.xyz[2]) + plane.w;
			const float bottom	= (plane.x * delta.xyz[0]) + (plane.y * delta.xyz[1]) + (plane.z * delta.xyz[2]);
			const float time	= -top / bottom;
#if CLIPPING_DEBUGGING
			if (time < -0.001f || time > 1.001f)
			{
				Sys_Error("time out of range,\n\t%f,\n\tv1 (%f %f %f)\n\tv2 (%f %f %f)\n\tdelta (%f %f %f)",
					time,
					v1.xyz[0], v1.xyz[1], v1.xyz[2],
					v2.xyz[0], v2.xyz[1], v2.xyz[2],
					delta.xyz[0], delta.xyz[1], delta.xyz[2]
				);
			}
#endif

			// Interpolate a new vertex.
			const glvert_t	v =
			{
				{
					v1.st[0] + time * delta.st[0],
						v1.st[1] + time * delta.st[1]
				},
				{
					v1.xyz[0] + time * delta.xyz[0],
						v1.xyz[1] + time * delta.xyz[1],
						v1.xyz[2] + time * delta.xyz[2]
				},
			};

			return v;
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
			// Set up.
			const glvert_t* const	last_unclipped_vertex	= &unclipped_vertices[unclipped_vertex_count];

			// For each polygon edge...
			const glvert_t*	s				= unclipped_vertices;
			const glvert_t* p				= s + 1;
			glvert_t*		clipped_vertex	= clipped_vertices;
			do
			{
				// Check both nodal values, s and p. If the point values are:
				const bool s_inside = point_in_front_of_plane(s->xyz, plane);
				const bool p_inside = point_in_front_of_plane(p->xyz, plane);
				if (s_inside)
				{
					if (p_inside)
					{
						// 1. Inside-inside, append the second node, p.
						*clipped_vertex++ = *p;
					}
					else
					{
						// 2. Inside-outside, compute and append the
						// intersection, i of edge sp with the clipping plane.
						*clipped_vertex++ = calculate_intersection(plane, *s, *p);
					}
				}
				else
				{
					if (p_inside)
					{
						// 4. Outside-inside, compute and append the
						// intersection i of edge sp with the clipping plane,
						// then append the second node p.
						*clipped_vertex++ = calculate_intersection(plane, *s, *p);
						*clipped_vertex++ = *p;
					}
					else
					{
						// 3. Outside-outside, no operation.
					}
				}

				// Next edge.
				s = p++;
				if (p == last_unclipped_vertex)
				{
					p = unclipped_vertices;
				}
			}
			while (s != unclipped_vertices);

			// Return the data.
			*clipped_vertex_count = clipped_vertex - clipped_vertices;
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
