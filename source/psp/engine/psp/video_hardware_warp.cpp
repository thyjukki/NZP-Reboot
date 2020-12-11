/*
Copyright (C) 1996-1997 Id Software, Inc.
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
// gl_warp.c -- sky and water polygons

#include <pspgu.h>

extern "C"
{
#include "../quakedef.h"
}

#include "clipping.hpp"

using namespace quake;

extern	model_t	*loadmodel;

/*int		skytexturenum;*/

int		solidskytexture	= -1;
int		alphaskytexture	= -1;

float	speedscale;		// for top sky and bottom sky

int	    skytexorder[6] = {0,2,1,3,4,5};
int	    skyimage[6]; // Where sky images are stored
char	skybox_name[32] = ""; //name of current skybox, or "" if no skybox
char	*suf[6] = {"rt", "bk", "lf", "ft", "up", "dn"};

msurface_t	*warpface;

extern cvar_t gl_subdivide_size;

static void BoundPoly (int numverts, float *verts, vec3_t mins, vec3_t maxs)
{
	int		i, j;
	float	*v;

	mins[0] = mins[1] = mins[2] = 9999;
	maxs[0] = maxs[1] = maxs[2] = -9999;
	v = verts;
	for (i=0 ; i<numverts ; i++)
	{
		for (j=0 ; j<3 ; j++, v++)
		{
			if (*v < mins[j])
				mins[j] = *v;
			if (*v > maxs[j])
				maxs[j] = *v;
		}
    }
}

static void SubdividePolygon (int numverts, float *verts)
{
	int		i, j, k;
	vec3_t	mins, maxs;
	float	m;
	float	*v;
	vec3_t	front[64], back[64];
	int		f, b;
	float	dist[64];
	float	frac;
	glpoly_t	*poly;
	float	s, t, subdivide_size;;

	if (numverts > 60)
		Sys_Error ("numverts = %i", numverts);

	subdivide_size = fmax(1, gl_subdivide_size.value);
	BoundPoly (numverts, verts, mins, maxs);

	for (i=0 ; i<3 ; i++)
	{
		m = (mins[i] + maxs[i]) * 0.5;
		m = subdivide_size * floorf (m / subdivide_size + 0.5);
		if (maxs[i] - m < 8)
			continue;
		if (m - mins[i] < 8)
			continue;

		// cut it
		v = verts + i;
		for (j=0 ; j<numverts ; j++, v+= 3)
			dist[j] = *v - m;

		// wrap cases
		dist[j] = dist[0];
		v-=i;
		VectorCopy (verts, v);

		f = b = 0;
		v = verts;
		for (j=0 ; j<numverts ; j++, v+= 3)
		{
			if (dist[j] >= 0)
			{
				VectorCopy (v, front[f]);
				f++;
			}
			if (dist[j] <= 0)
			{
				VectorCopy (v, back[b]);
				b++;
			}
			if (dist[j] == 0 || dist[j+1] == 0)
				continue;
			if ( (dist[j] > 0) != (dist[j+1] > 0) )
			{
				// clip point
				frac = dist[j] / (dist[j] - dist[j+1]);
				for (k=0 ; k<3 ; k++)
					front[f][k] = back[b][k] = v[k] + frac*(v[3+k] - v[k]);
				f++;
				b++;
			}
		}

		SubdividePolygon (f, front[0]);
		SubdividePolygon (b, back[0]);
		return;
	}

	poly = static_cast<glpoly_t*>(Hunk_Alloc (sizeof(glpoly_t) + (numverts - 1) * sizeof(glvert_t)));
	poly->next = warpface->polys;
	warpface->polys = poly;
	poly->numverts = numverts;
	for (i=0 ; i<numverts ; i++, verts+= 3)
	{
		VectorCopy (verts, poly->verts[i].xyz);
		s = DotProduct (verts, warpface->texinfo->vecs[0]);
		t = DotProduct (verts, warpface->texinfo->vecs[1]);
		poly->verts[i].st[0] = s;
		poly->verts[i].st[1] = t;
	}
}

/*
================
GL_SubdivideSurface

Breaks a polygon up along axial 64 unit
boundaries so that turbulent and sky warps
can be done reasonably.
================
*/
void GL_SubdivideSurface (msurface_t *fa)
{
	vec3_t		verts[64];
	int			numverts;
	int			i;
	int			lindex;
	float		*vec;

	warpface = fa;

	//
	// convert edges back to a normal polygon
	//
	numverts = 0;
	for (i=0 ; i<fa->numedges ; i++)
	{
		lindex = loadmodel->surfedges[fa->firstedge + i];

		if (lindex > 0)
			vec = loadmodel->vertexes[loadmodel->edges[lindex].v[0]].position;
		else
			vec = loadmodel->vertexes[loadmodel->edges[-lindex].v[1]].position;
		VectorCopy (vec, verts[numverts]);
		numverts++;
	}

	SubdividePolygon (numverts, verts[0]);
}

//=========================================================


#define	TURBSINSIZE	128
#define	TURBSCALE	((float)TURBSINSIZE / (2 * M_PI))

byte turbsin[TURBSINSIZE] =
{
	127, 133, 139, 146, 152, 158, 164, 170, 176, 182, 187, 193, 198, 203, 208, 213,
	217, 221, 226, 229, 233, 236, 239, 242, 245, 247, 249, 251, 252, 253, 254, 254,
	255, 254, 254, 253, 252, 251, 249, 247, 245, 242, 239, 236, 233, 229, 226, 221,
	217, 213, 208, 203, 198, 193, 187, 182, 176, 170, 164, 158, 152, 146, 139, 133,
	127, 121, 115, 108, 102, 96, 90, 84, 78, 72, 67, 61, 56, 51, 46, 41,
	37, 33, 28, 25, 21, 18, 15, 12, 9, 7, 5, 3, 2, 1, 0, 0,
	0, 0, 0, 1, 2, 3, 5, 7, 9, 12, 15, 18, 21, 25, 28, 33,
	37, 41, 46, 51, 56, 61, 67, 72, 78, 84, 90, 96, 102, 108, 115, 121,
};

__inline static float SINTABLE_APPROX (float time)
{
	float	sinlerpf, lerptime, lerp;
	int	sinlerp1, sinlerp2;

	sinlerpf = time * TURBSCALE;
	sinlerp1 = floor(sinlerpf);
	sinlerp2 = sinlerp1 + 1;
	lerptime = sinlerpf - sinlerp1;

	lerp = turbsin[sinlerp1 & (TURBSINSIZE - 1)] * (1 - lerptime) + turbsin[sinlerp2 & (TURBSINSIZE - 1)] * lerptime;
	return -8 + 16 * lerp / 255.0;
}

/*
================
GL_Surface
================
*/
void GL_Surface (msurface_t *fa)
{
	vec3_t		verts[64];
	int			numverts;
	int			i;
	int			lindex;
	float		*vec;
	glpoly_t	*poly;
	//float	texscale;
	float	s, t;

	//texscale = (1.0/32.0);

	//
	// convert edges back to a normal polygon
	//
	numverts = 0;
	for (i=0 ; i<fa->numedges ; i++)
	{
		lindex = loadmodel->surfedges[fa->firstedge + i];

		if (lindex > 0)
			vec = loadmodel->vertexes[loadmodel->edges[lindex].v[0]].position;
		else
			vec = loadmodel->vertexes[loadmodel->edges[-lindex].v[1]].position;
		VectorCopy (vec, verts[numverts]);
		numverts++;
	}

	//create the poly
	poly = static_cast<glpoly_t*>(Hunk_Alloc (sizeof(glpoly_t) + (numverts - 1) * sizeof(glvert_t)));
	poly->next = NULL;
	fa->polys = poly;
	poly->numverts = numverts;
	for (i=0, vec=(float *)verts; i<numverts; i++, vec+= 3)
	{
		VectorCopy (vec, poly->verts[i].xyz);
		s = DotProduct(vec, fa->texinfo->vecs[0]);// * texscale;
		t = DotProduct(vec, fa->texinfo->vecs[1]);// * texscale;
		poly->verts[i].st[0] = s;
		poly->verts[i].st[1] = t;
	}
}

/*
=============
EmitFlatPoly
=============
*/
void EmitFlatPoly (msurface_t *fa)
{
	// For each polygon...
	for (const glpoly_t* p = fa->polys; p; p = p->next)
	{
		// Allocate memory for this polygon.
		const int		unclipped_vertex_count	= p->numverts;
		glvert_t* const	unclipped_vertices		=
			static_cast<glvert_t*>(sceGuGetMemory(sizeof(glvert_t) * unclipped_vertex_count));

		// Generate each vertex.
		const glvert_t*	src			= p->verts;
		const glvert_t*	last_vertex = src + unclipped_vertex_count;
		glvert_t*		dst			= unclipped_vertices;

		while (src != last_vertex)
		{
     		// Fill in the vertex data.
			dst->st[0] = src->st[0];    //Tex
			dst->st[1] = src->st[1];

			dst->xyz[0] = src->xyz[0];  //Verts
			dst->xyz[1] = src->xyz[1];
            dst->xyz[2] = src->xyz[2];

			// Next vertex.
			++src;
			++dst;
		}

		// Do these vertices need clipped?
		if (clipping::is_clipping_required(unclipped_vertices, unclipped_vertex_count))
		{
			// Clip the polygon.
			const glvert_t*	clipped_vertices;
			std::size_t		clipped_vertex_count;
			clipping::clip(
				unclipped_vertices,
				unclipped_vertex_count,
				&clipped_vertices,
				&clipped_vertex_count);

			// Any vertices left?
			if (clipped_vertex_count)
			{
				// Copy the vertices to the display list.
				const std::size_t buffer_size = clipped_vertex_count * sizeof(glvert_t);
				glvert_t* const display_list_vertices = static_cast<glvert_t*>(sceGuGetMemory(buffer_size));
				memcpy(display_list_vertices, clipped_vertices, buffer_size);

				// Draw the clipped vertices.
				sceGuDrawArray(
					GU_TRIANGLE_FAN,
					GU_TEXTURE_32BITF | GU_VERTEX_32BITF,
					clipped_vertex_count, 0, display_list_vertices);
			}
		}
		else
		{
			// Draw the vertices.
			sceGuDrawArray(
				GU_TRIANGLE_FAN,
				GU_TEXTURE_32BITF | GU_VERTEX_32BITF,
				unclipped_vertex_count, 0, unclipped_vertices);
		}
	}
}

/*
=============
EmitWaterPolys

Does a water warp on the pre-fragmented glpoly_t chain
=============
*/
void EmitWaterPolys (msurface_t *fa)
{
	//const float real_time	= static_cast<float>(realtime);
	const float scale		= (1.0f / 64);
/*
	//jkrige - clamp waterripple values
	if(r_waterripple.value>10)
	   r_waterripple.value=10;

	if(r_waterripple.value<0)
	   r_waterripple.value=0;
    //jkrige - clamp waterripple values
*/

	// For each polygon...
	for (const glpoly_t* p = fa->polys; p; p = p->next)
	{
		// Allocate memory for this polygon.
		const int		unclipped_vertex_count	= p->numverts;
		glvert_t* const	unclipped_vertices		=
			static_cast<glvert_t*>(sceGuGetMemory(sizeof(glvert_t) * unclipped_vertex_count));

		// Generate each vertex.
		const glvert_t*	src			= p->verts;
		const glvert_t*	last_vertex = src + unclipped_vertex_count;
		glvert_t*		dst			= unclipped_vertices;

		while (src != last_vertex)
		{
			// Get the input UVs.
			const float	os = src->st[0];
			const float	ot = src->st[1];

			// Fill in the vertex data.
			dst->st[0] = (os + SINTABLE_APPROX(ot * 0.125 + cl.time)) * scale;
			dst->st[1] = (ot + SINTABLE_APPROX(os * 0.125 + cl.time)) * scale;

			dst->xyz[0] = src->xyz[0];
			dst->xyz[1] = src->xyz[1];
            dst->xyz[2] = src->xyz[2];
            //dst->xyz[2] = src->xyz[2] + r_waterripple.value * sin(src->xyz[0]*0.05+realtime)*sin(src->xyz[2]*0.05+realtime);
			// Next vertex.
			++src;
			++dst;
		}

		// Do these vertices need clipped?
		if (clipping::is_clipping_required(unclipped_vertices, unclipped_vertex_count))
		{
			// Clip the polygon.
			const glvert_t*	clipped_vertices;
			std::size_t		clipped_vertex_count;
			clipping::clip(
				unclipped_vertices,
				unclipped_vertex_count,
				&clipped_vertices,
				&clipped_vertex_count);

			// Any vertices left?
			if (clipped_vertex_count)
			{
				// Copy the vertices to the display list.
				const std::size_t buffer_size = clipped_vertex_count * sizeof(glvert_t);
				glvert_t* const display_list_vertices = static_cast<glvert_t*>(sceGuGetMemory(buffer_size));
				memcpy(display_list_vertices, clipped_vertices, buffer_size);

				// Draw the clipped vertices.
				sceGuDrawArray(
					GU_TRIANGLE_FAN,
					GU_TEXTURE_32BITF | GU_VERTEX_32BITF,
					clipped_vertex_count, 0, display_list_vertices);
			}
		}
		else
		{
			// Draw the vertices.
			sceGuDrawArray(
				GU_TRIANGLE_FAN,
				GU_TEXTURE_32BITF | GU_VERTEX_32BITF,
				unclipped_vertex_count, 0, unclipped_vertices);
		}
	}
}

/*
=============
EmitUnderWaterPolys
based on water polys!
By Crow_bar.
=============
*/
extern int underwater_texture;
void EmitUnderWaterPolys (void)
{
   	const float scale		= (-3 * (0.5 / 64));
    extern glpoly_t	*caustics_polys;

	sceGuEnable(GU_BLEND);
	sceGuBlendFunc (GU_ADD, GU_DST_COLOR, GU_SRC_COLOR, 0, 0);
    sceGuTexFunc(GU_TFX_DECAL, GU_TCC_RGBA);

	GL_Bind(underwater_texture);


	// For each polygon...
    for (const glpoly_t* p = caustics_polys ; p ; p = p->caustics_chain)
	{
		// Allocate memory for this polygon.
		const int		unclipped_vertex_count	= p->numverts;
		glvert_t* const	unclipped_vertices		=
			static_cast<glvert_t*>(sceGuGetMemory(sizeof(glvert_t) * unclipped_vertex_count));

		// Generate each vertex.
		const glvert_t*	src			= p->verts;
		const glvert_t*	last_vertex = src + unclipped_vertex_count;
		glvert_t*		dst			= unclipped_vertices;

		while (src != last_vertex)
		{
			// Get the input UVs.
			const float	os = src->st[0];
			const float	ot = src->st[1];

			// Fill in the vertex data.
			dst->st[0] = (os + SINTABLE_APPROX(0.465 * (cl.time + ot))) * scale;
			dst->st[1] = (ot + SINTABLE_APPROX(0.465 * (cl.time + os))) * scale;

			dst->xyz[0] = src->xyz[0];
			dst->xyz[1] = src->xyz[1];
			dst->xyz[2] = src->xyz[2];

			// Next vertex.
			++src;
			++dst;
		}

		// Do these vertices need clipped?
		if (clipping::is_clipping_required(unclipped_vertices, unclipped_vertex_count))
		{
			// Clip the polygon.
			const glvert_t*	clipped_vertices;
			std::size_t		clipped_vertex_count;
			clipping::clip(
				unclipped_vertices,
				unclipped_vertex_count,
				&clipped_vertices,
				&clipped_vertex_count);

			// Any vertices left?
			if (clipped_vertex_count)
			{
				// Copy the vertices to the display list.
				const std::size_t buffer_size = clipped_vertex_count * sizeof(glvert_t);
				glvert_t* const display_list_vertices = static_cast<glvert_t*>(sceGuGetMemory(buffer_size));
				memcpy(display_list_vertices, clipped_vertices, buffer_size);

				// Draw the clipped vertices.
				sceGuDrawArray(
					GU_TRIANGLE_FAN,
					GU_TEXTURE_32BITF | GU_VERTEX_32BITF,
					clipped_vertex_count, 0, display_list_vertices);
			}
		}
		else
		{
			// Draw the vertices.
			sceGuDrawArray(
				GU_TRIANGLE_FAN,
				GU_TEXTURE_32BITF | GU_VERTEX_32BITF,
				unclipped_vertex_count, 0, unclipped_vertices);
		}
	}

	sceGuTexFunc(GU_TFX_REPLACE, GU_TCC_RGBA);
	sceGuBlendFunc(GU_ADD, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, 0, 0);
    sceGuDisable (GU_BLEND);

	caustics_polys = NULL;
}

/*
=============
EmitSkyPolys
=============
*/
void EmitSkyPolys (msurface_t *fa)
{
	for (const glpoly_t* p = fa->polys; p; p = p->next)
	{
		// Allocate memory for this polygon.
		const int		unclipped_vertex_count	= p->numverts;
		glvert_t* const	unclipped_vertices		= static_cast<glvert_t*>(sceGuGetMemory(sizeof(glvert_t) * unclipped_vertex_count));

		vec3_t	dir;
		// Generate each vertex.
		const glvert_t*	src			= p->verts;
		const glvert_t*	last_vertex = src + unclipped_vertex_count;
		glvert_t*		dst			= unclipped_vertices;
		while (src != last_vertex)
		{

			VectorSubtract(src->xyz, r_origin, dir);
			dir[2] *= 3;	// flatten the sphere

			const float length = 6 * 63 / sqrtf(DotProduct(dir, dir));

            dir[0] *= length;
			dir[1] *= length;

            dst->st[0] = (speedscale + dir[0]) * (1.0f / 128.0f);
			dst->st[1] = (speedscale + dir[1]) * (1.0f / 128.0f);
			dst->xyz[0] = src->xyz[0];
			dst->xyz[1] = src->xyz[1];
			dst->xyz[2] = src->xyz[2];

			// Next vertex.
			++src;
			++dst;
		}

		// Do these vertices need clipped?
		if (clipping::is_clipping_required(unclipped_vertices, unclipped_vertex_count))
		{
			// Clip the polygon.
			const glvert_t*	clipped_vertices;
			std::size_t		clipped_vertex_count;
			clipping::clip(
				unclipped_vertices,
				unclipped_vertex_count,
				&clipped_vertices,
				&clipped_vertex_count);

			// Any vertices left?
			if (clipped_vertex_count)
			{
				// Copy the vertices to the display list.
				const std::size_t buffer_size = clipped_vertex_count * sizeof(glvert_t);
				glvert_t* const display_list_vertices = static_cast<glvert_t*>(sceGuGetMemory(buffer_size));
				memcpy(display_list_vertices, clipped_vertices, buffer_size);

				// Draw the clipped vertices.
				sceGuDrawArray(
					GU_TRIANGLE_FAN,
					GU_TEXTURE_32BITF | GU_VERTEX_32BITF,
					clipped_vertex_count, 0, display_list_vertices);
			}
		}
		else
		{
			// Draw the vertices.
			sceGuDrawArray(
				GU_TRIANGLE_FAN,
				GU_TEXTURE_32BITF | GU_VERTEX_32BITF,
				unclipped_vertex_count, 0, unclipped_vertices);
		}
	}

}


/*
=============
EmitScrollPolys

Does a scroll on the pre-fragmented glpoly_t chain
=============
*/
void EmitScrollPolys (msurface_t *fa)
{
	const float real_time	= static_cast<float>(realtime);
    const float scroll      = (-64 * ((real_time*0.5) - (int)(real_time*0.5)));

	// For each polygon...
	for (const glpoly_t* p = fa->polys; p; p = p->next)
	{
		// Allocate memory for this polygon.
		const int		unclipped_vertex_count	= p->numverts;
		glvert_t* const	unclipped_vertices		=
			static_cast<glvert_t*>(sceGuGetMemory(sizeof(glvert_t) * unclipped_vertex_count));

		// Generate each vertex.
		const glvert_t*	src			= p->verts;
		const glvert_t*	last_vertex = src + unclipped_vertex_count;
		glvert_t*		dst			= unclipped_vertices;

		while (src != last_vertex)
		{
			// Fill in the vertex data.
			dst->st[0] = src->st[0] + scroll;
			dst->st[1] = src->st[1];
			dst->xyz[0] = src->xyz[0];
			dst->xyz[1] = src->xyz[1];
			dst->xyz[2] = src->xyz[2];

			// Next vertex.
			++src;
			++dst;
		}

		// Do these vertices need clipped?
		if (clipping::is_clipping_required(unclipped_vertices, unclipped_vertex_count))
		{
			// Clip the polygon.
			const glvert_t*	clipped_vertices;
			std::size_t		clipped_vertex_count;
			clipping::clip(
				unclipped_vertices,
				unclipped_vertex_count,
				&clipped_vertices,
				&clipped_vertex_count);

			// Any vertices left?
			if (clipped_vertex_count)
			{
				// Copy the vertices to the display list.
				const std::size_t buffer_size = clipped_vertex_count * sizeof(glvert_t);
				glvert_t* const display_list_vertices = static_cast<glvert_t*>(sceGuGetMemory(buffer_size));
				memcpy(display_list_vertices, clipped_vertices, buffer_size);

				// Draw the clipped vertices.
				sceGuDrawArray(
					GU_TRIANGLE_FAN,
					GU_TEXTURE_32BITF | GU_VERTEX_32BITF,
					clipped_vertex_count, 0, display_list_vertices);
			}
		}
		else
		{
			// Draw the vertices.
			sceGuDrawArray(
				GU_TRIANGLE_FAN,
				GU_TEXTURE_32BITF | GU_VERTEX_32BITF,
				unclipped_vertex_count, 0, unclipped_vertices);
		}
	}
}


extern int ref_texture;

/*
=============
EmitReflectivePolys

Does a reflective warp on the pre-fragmented glpoly_t chain
=============
*/
void EmitReflectivePolys (msurface_t *fa)
{
	// For each polygon...
	for (const glpoly_t* p = fa->polys; p; p = p->next)
	{
		// Allocate memory for this polygon.
		const int		unclipped_vertex_count	= p->numverts;
		glvert_t* const	unclipped_vertices		=
			static_cast<glvert_t*>(sceGuGetMemory(sizeof(glvert_t) * unclipped_vertex_count));

		// Generate each vertex.
		const glvert_t*	src			= p->verts;
		const glvert_t*	last_vertex = src + unclipped_vertex_count;
		glvert_t*		dst			= unclipped_vertices;

		while (src != last_vertex)
		{
			vec3_t	dir;
			VectorSubtract(src->xyz, r_origin, dir);
			dir[2] *= 3;	// flatten the sphere

			const float length = 6 * 63 / sqrtf(DotProduct(dir, dir));

			dir[0] *= length;
			dir[1] *= length;

			dst->st[0] = (dir[0]) * (1.0f / 256.0f);
			dst->st[1] = (dir[1]) * (1.0f / 256.0f);
			dst->xyz[0] = src->xyz[0];
			dst->xyz[1] = src->xyz[1];
			dst->xyz[2] = src->xyz[2];

			// Next vertex.
			++src;
			++dst;
		}

		// Do these vertices need clipped?
		if (clipping::is_clipping_required(unclipped_vertices, unclipped_vertex_count))
		{
			// Clip the polygon.
			const glvert_t*	clipped_vertices;
			std::size_t		clipped_vertex_count;
			clipping::clip(
				unclipped_vertices,
				unclipped_vertex_count,
				&clipped_vertices,
				&clipped_vertex_count);

			// Any vertices left?
			if (clipped_vertex_count)
			{
				// Copy the vertices to the display list.
				const std::size_t buffer_size = clipped_vertex_count * sizeof(glvert_t);
				glvert_t* const display_list_vertices = static_cast<glvert_t*>(sceGuGetMemory(buffer_size));
				memcpy(display_list_vertices, clipped_vertices, buffer_size);

				// Draw the clipped vertices.
				sceGuDrawArray(
					GU_TRIANGLE_FAN,
					GU_TEXTURE_32BITF | GU_VERTEX_32BITF,
					clipped_vertex_count, 0, display_list_vertices);
			}
		}
		else
		{
			// Draw the vertices.
			sceGuDrawArray(
				GU_TRIANGLE_FAN,
				GU_TEXTURE_32BITF | GU_VERTEX_32BITF,
				unclipped_vertex_count, 0, unclipped_vertices);
		}
	}
}

/*
===============
EmitBothSkyLayers

Does a sky warp on the pre-fragmented glpoly_t chain
This will be called for brushmodels, the world
will have them chained together.
===============
*/
void EmitBothSkyLayers (msurface_t *fa)
{
	GL_Bind (solidskytexture);

	speedscale = realtime*8;
	speedscale -= (int)speedscale & ~127 ;

	EmitSkyPolys (fa);

	sceGuEnable(GU_BLEND);

	GL_Bind (alphaskytexture);
    speedscale = realtime*16;
	speedscale -= (int)speedscale & ~127 ;

	EmitSkyPolys (fa);

	sceGuDisable(GU_BLEND);
}

/*
===============
R_DrawScroll_SkyChain
===============
*/
void R_DrawScroll_SkyChain (msurface_t *s)
{
	msurface_t	*fa;

	GL_Bind(solidskytexture);

    speedscale = realtime*8;
    speedscale -= (int)speedscale & ~127 ;

    for (fa=s ; fa ; fa=fa->texturechain)
        EmitSkyPolys (fa);

    sceGuEnable(GU_BLEND);

    GL_Bind (alphaskytexture);

    speedscale = realtime*16;
    speedscale -= (int)speedscale & ~127 ;

    for (fa=s ; fa ; fa=fa->texturechain)
        EmitSkyPolys (fa);

    sceGuDisable(GU_BLEND);
}

/*
===============
R_DrawFlat_SkyChain
===============
*/
void R_DrawFlat_SkyChain (msurface_t *s)
{
    msurface_t	*fa;

	sceGuDisable (GU_TEXTURE_2D);

    byte *sky_color = StringToRGB (r_skycolor.string); //Get color
	sceGuColor(GU_RGBA(sky_color[0], sky_color[1], sky_color[2], 255));

	for (fa = s ; fa ; fa = fa->texturechain)
		EmitFlatPoly (fa);

    sceGuColor(0xffffffff);
	sceGuEnable (GU_TEXTURE_2D);
}

/*
=================================================================

  Quake 2 environment sky

=================================================================
*/
void UnloadSkyTexture (void)
{
	for (int i = 0; i < 6; i++)
	{
	    if (skyimage[i])
            GL_UnloadTexture(skyimage[i]);
		skyimage[i] = NULL;
	}
}

/*
==================
R_LoadSkys
==================
*/
extern int nonetexture;
void Sky_LoadSkyBox (char *name)
{
	if (strcmp(skybox_name, name) == 0)
		return; //no change

    //purge old sky textures
    UnloadSkyTexture ();

	//turn off skybox if sky is set to ""
	if (name[0] == '0')
	{
		skybox_name[0] = 0;

		//if map don't have sky
		if (solidskytexture == -1)
		    solidskytexture = nonetexture;
		if (alphaskytexture == -1)
		    alphaskytexture = nonetexture;

		return;
	}

    for (int i = 0; i < 6; i++)
    {
        int mark = Hunk_LowMark ();
		if(!(skyimage[i] = loadtextureimage (va("gfx/env/%s%s", name, suf[i]), 0, 0, qfalse, GU_LINEAR)) &&
           !(skyimage[i] = loadtextureimage (va("gfx/env/%s_%s", name, suf[i]), 0, 0, qfalse, GU_LINEAR)))
		{
			Con_Printf("Sky: %s[%s] not found, used std\n", name, suf[i]);
		    if(!(skyimage[i] = loadtextureimage (va("gfx/env/skybox%s", suf[i]), 0, 0, qfalse, GU_LINEAR)))
		    {
			    Sys_Error("STD SKY NOT FOUND!");
			}

		}
        Hunk_FreeToLowMark (mark);
    }
    strcpy(skybox_name, name);
}

/*
=================
Sky_NewMap
=================
*/
void Sky_NewMap (void)
{
	char	key[128], value[4096];
	char	*data;

    //purge old sky textures
    UnloadSkyTexture ();

	//
	// initially no sky
	//
	Sky_LoadSkyBox (""); //not used

	//
	// read worldspawn (this is so ugly, and shouldn't it be done on the server?)
	//
	data = cl.worldmodel->entities;
	if (!data)
		return; //FIXME: how could this possibly ever happen? -- if there's no
	// worldspawn then the sever wouldn't send the loadmap message to the client

	data = COM_Parse(data);

	if (!data) //should never happen
		return; // error

	if (com_token[0] != '{') //should never happen
		return; // error

	while (1)
	{
		data = COM_Parse(data);

		if (!data)
			return; // error

		if (com_token[0] == '}')
			break; // end of worldspawn

		if (com_token[0] == '_')
			strcpy(key, com_token + 1);
		else
			strcpy(key, com_token);
		while (key[strlen(key)-1] == ' ') // remove trailing spaces
			key[strlen(key)-1] = 0;

		data = COM_Parse(data);
		if (!data)
			return; // error

		strcpy(value, com_token);

        if (!strcmp("sky", key))
            Sky_LoadSkyBox(value);
        else if (!strcmp("skyname", key)) //half-life
            Sky_LoadSkyBox(value);
        else if (!strcmp("qlsky", key)) //quake lives
            Sky_LoadSkyBox(value);
	}
}

/*
=================
Sky_SkyCommand_f
=================
*/
void Sky_SkyCommand_f (void)
{
	switch (Cmd_Argc())
	{
	case 1:
		Con_Printf("\"sky\" is \"%s\"\n", skybox_name);
		break;
	case 2:
		Sky_LoadSkyBox(Cmd_Argv(1));
		break;
	default:
		Con_Printf("usage: sky <skyname>\n");
	}
}

/*
=============
Sky_Init
=============
*/
void Sky_Init (void)
{
	int		i;

	Cmd_AddCommand ("sky",Sky_SkyCommand_f);

	for (i=0; i<6; i++)
		skyimage[i] = NULL;
}

static vec3_t	skyclip[6] = {
	{1,1,0},
	{1,-1,0},
	{0,-1,1},
	{0,1,1},
	{1,0,1},
	{-1,0,1}
};
int	c_sky;

// 1 = s, 2 = t, 3 = 2048
static int	st_to_vec[6][3] =
{
	{3,-1,2},
	{-3,1,2},

	{1,3,2},
	{-1,-3,2},

	{-2,-1,3},		// 0 degrees yaw, look straight up
	{2,-1,-3}		// look straight down

//	{-1,2,3},
//	{1,2,-3}
};

// s = [0]/[2], t = [1]/[2]
static int	vec_to_st[6][3] =
{
	{-2,3,1},
	{2,3,-1},

	{1,3,2},
	{-1,3,-2},

	{-2,-1,3},
	{-2,1,-3}

//	{-1,2,3},
//	{1,2,-3}
};

static float	skymins[2][6], skymaxs[2][6];

static void DrawSkyPolygon (int nump, vec3_t vecs)
{
	int		i,j,axis;
	float 	s,t,dv,*vp;
	vec3_t	v, av;

	c_sky++;

	// decide which face it maps to
	VectorCopy (vec3_origin, v);
	for (i=0, vp=vecs ; i<nump ; i++, vp+=3)
		VectorAdd (vp, v, v);
	
	av[0] = fabs(v[0]);
	av[1] = fabs(v[1]);
	av[2] = fabs(v[2]);
	
	if (av[0] > av[1] && av[0] > av[2])
		axis = (v[0] < 0) ? 1 : 0;
	else if (av[1] > av[2] && av[1] > av[0])
		axis = (v[1] < 0) ? 3 : 2;
	else
		axis = (v[2] < 0) ? 5 : 4;

	// project new texture coords
	for (i=0 ; i<nump ; i++, vecs+=3)
	{
		j = vec_to_st[axis][2];
		dv = (j > 0) ? vecs[j - 1] : -vecs[-j - 1];

		j = vec_to_st[axis][0];
		s = (j < 0) ? -vecs[-j -1] / dv : vecs[j-1] / dv;

		j = vec_to_st[axis][1];
		t = (j < 0) ? -vecs[-j -1] / dv : vecs[j-1] / dv;

		if (s < skymins[0][axis])
			skymins[0][axis] = s;
		if (t < skymins[1][axis])
			skymins[1][axis] = t;
		if (s > skymaxs[0][axis])
			skymaxs[0][axis] = s;
		if (t > skymaxs[1][axis])
			skymaxs[1][axis] = t;
	}
}

#define	MAX_CLIP_VERTS	64
void ClipSkyPolygon (int nump, vec3_t vecs, int stage)
{
	float	*norm;
	float	*v;
	qboolean	front, back;
	float	d, e;
	float	dists[MAX_CLIP_VERTS];
	int		sides[MAX_CLIP_VERTS];
	vec3_t	newv[2][MAX_CLIP_VERTS];
	int		newc[2];
	int		i, j;

	if (nump > MAX_CLIP_VERTS-2)
		Sys_Error ("ClipSkyPolygon: MAX_CLIP_VERTS");
	if (stage == 6)
	{	// fully clipped, so draw it
		DrawSkyPolygon (nump, vecs);
		return;
	}

	front = back = qfalse;
	norm = skyclip[stage];
	for (i=0, v = vecs ; i<nump ; i++, v+=3)
	{
		d = DotProduct (v, norm);
		if (d > ON_EPSILON)
		{
			front = qtrue;
			sides[i] = SIDE_FRONT;
		}
		else if (d < ON_EPSILON)
		{
			back = qtrue;
			sides[i] = SIDE_BACK;
		}
		else
			sides[i] = SIDE_ON;
		dists[i] = d;
	}

	if (!front || !back)
	{	// not clipped
		ClipSkyPolygon (nump, vecs, stage+1);
		return;
	}

	// clip it
	sides[i] = sides[0];
	dists[i] = dists[0];
	VectorCopy (vecs, (vecs+(i*3)) );
	newc[0] = newc[1] = 0;

	for (i=0, v = vecs ; i<nump ; i++, v+=3)
	{
		switch (sides[i])
		{
		case SIDE_FRONT:
			VectorCopy (v, newv[0][newc[0]]);
			newc[0]++;
			break;
		case SIDE_BACK:
			VectorCopy (v, newv[1][newc[1]]);
			newc[1]++;
			break;
		case SIDE_ON:
			VectorCopy (v, newv[0][newc[0]]);
			newc[0]++;
			VectorCopy (v, newv[1][newc[1]]);
			newc[1]++;
			break;
		}

		if (sides[i] == SIDE_ON || sides[i+1] == SIDE_ON || sides[i+1] == sides[i])
			continue;

		d = dists[i] / (dists[i] - dists[i+1]);
		for (j=0 ; j<3 ; j++)
		{
			e = v[j] + d*(v[j+3] - v[j]);
			newv[0][newc[0]][j] = e;
			newv[1][newc[1]][j] = e;
		}
		newc[0]++;
		newc[1]++;
	}

	// continue
	ClipSkyPolygon (newc[0], newv[0][0], stage+1);
	ClipSkyPolygon (newc[1], newv[1][0], stage+1);
}
/*
==============
R_ClearSkyBox
==============
*/
void R_ClearSkyBox (void)
{
	int		i;

	for (i=0 ; i<6 ; i++)
	{
		skymins[0][i] = skymins[1][i] = 9999;
		skymaxs[0][i] = skymaxs[1][i] = -9999;
	}
}

static float s_axis;
static float t_axis;
static vec3_t v_axis;

void MakeSkyVec (float s, float t, int axis)
{
	vec3_t		b;
	int			j, k;

	b[0] = s*r_skydis.value;
	b[1] = t*r_skydis.value;
	b[2] = r_skydis.value;

	for (j=0 ; j<3 ; j++)
	{
		k = st_to_vec[axis][j];
		if (k < 0)
			v_axis[j] = -b[-k - 1];
		else
			v_axis[j] = b[k - 1];
		v_axis[j] += r_origin[j];
	}

	// avoid bilerp seam
	s = (s+1.0f)*0.5f;
	t = (t+1.0f)*0.5f;

	if (s < 1.0f/512.0f)
		s = 1.0f/512.0f;
	else if (s > 511.0f/512.0f)
		s = 511.0f/512.0f;

	if (t < 1.0f/512.0f)
		t = 1.0f/512.0f;
	else if (t > 511.0f/512.0f)
		t = 511.0f/512.0f;

	t = 1.0f - t;

	s_axis = s;
	t_axis = t;
}

void Fog_EnableGFog (void);
void Fog_DisableGFog (void);
void Fog_SetColorForSkyS (void);
void Fog_SetColorForSkyE (void);
/*
==============
R_DrawSkyBox
==============
*/
void R_DrawSkyBox (void)
{
    int		i;

	Fog_DisableGFog();     //setup for Sky
	Fog_SetColorForSkyS(); //setup for Sky

	//sceGuDepthRange(32767, 65535); //not used

	for (i=0 ; i<6 ; i++)
	{
		// Allocate memory for this polygon.
		const int		unclipped_vertex_count	= 4;
		glvert_t* const	unclipped_vertices  =
			static_cast<glvert_t*>(sceGuGetMemory(sizeof(glvert_t) * unclipped_vertex_count));

		if (skymins[0][i] >= skymaxs[0][i]
		|| skymins[1][i] >= skymaxs[1][i])
			continue;

        GL_Bind (skyimage[skytexorder[i]]);

		MakeSkyVec (skymins[0][i], skymins[1][i], i);

        unclipped_vertices[0].st[0]	    = s_axis;
        unclipped_vertices[0].st[1]	    = t_axis;
        unclipped_vertices[0].xyz[0]	= v_axis[0];
        unclipped_vertices[0].xyz[1]	= v_axis[1];
        unclipped_vertices[0].xyz[2]	= v_axis[2];

	    MakeSkyVec (skymins[0][i], skymaxs[1][i], i);

        unclipped_vertices[1].st[0]	    = s_axis;
        unclipped_vertices[1].st[1]	    = t_axis;
        unclipped_vertices[1].xyz[0]	= v_axis[0];
        unclipped_vertices[1].xyz[1]	= v_axis[1];
        unclipped_vertices[1].xyz[2]	= v_axis[2];

        MakeSkyVec (skymaxs[0][i], skymaxs[1][i], i);

        unclipped_vertices[2].st[0]	    = s_axis;
        unclipped_vertices[2].st[1]	    = t_axis;
        unclipped_vertices[2].xyz[0]	= v_axis[0];
        unclipped_vertices[2].xyz[1]	= v_axis[1];
        unclipped_vertices[2].xyz[2]	= v_axis[2];

		MakeSkyVec (skymaxs[0][i], skymins[1][i], i);

        unclipped_vertices[3].st[0]	    = s_axis;
        unclipped_vertices[3].st[1]	    = t_axis;
        unclipped_vertices[3].xyz[0]	= v_axis[0];
        unclipped_vertices[3].xyz[1]	= v_axis[1];
        unclipped_vertices[3].xyz[2]	= v_axis[2];

        if (clipping::is_clipping_required(
            unclipped_vertices,
            unclipped_vertex_count))
        {
            // Clip the polygon.
            const glvert_t*	clipped_vertices;
            std::size_t		clipped_vertex_count;
            clipping::clip(
                unclipped_vertices,
                unclipped_vertex_count,
                &clipped_vertices,
                &clipped_vertex_count);

            // Did we have any vertices left?
            if (clipped_vertex_count)
            {
                // Copy the vertices to the display list.
                const std::size_t buffer_size = clipped_vertex_count * sizeof(glvert_t);
                glvert_t* const display_list_vertices = static_cast<glvert_t*>(sceGuGetMemory(buffer_size));
                memcpy(display_list_vertices, clipped_vertices, buffer_size);

                // Draw the clipped vertices.
                sceGuDrawArray(
                    GU_TRIANGLE_FAN,
                    GU_TEXTURE_32BITF | GU_VERTEX_32BITF,
                    clipped_vertex_count, 0, display_list_vertices);
            }
        }
        else
        {
            // Draw the poly directly.
            sceGuDrawArray(
                GU_TRIANGLE_FAN,
                GU_TEXTURE_32BITF | GU_VERTEX_32BITF,
                unclipped_vertex_count, 0, unclipped_vertices);
        }
    }
    //sceGuDepthRange(0, 65535);
	Fog_SetColorForSkyE(); //setup for Sky
	Fog_EnableGFog(); //setup for Sky

}

//===============================================================

/*
=================
R_DrawSkyChain
=================
*/
void R_DrawSkyChain (msurface_t *s)
{
	  msurface_t	*fa;
      int		    i;
      vec3_t	    verts[MAX_CLIP_VERTS];
      glpoly_t	    *p;

	  if (r_fastsky.value || !skybox_name[0])
	  {
			R_DrawFlat_SkyChain (s);
	  }
	  else
	  {
		    if (skybox_name[0]) // if the skybox has a name, draw the skybox
			{
		        c_sky = 0;

		        // calculate vertex values for sky box
		        for (fa=s ; fa ; fa=fa->texturechain)
		        {
		            for (p=fa->polys ; p ; p=p->next)
		            {
		                for (i=0 ; i<p->numverts ; i++)
		                {
		                    VectorSubtract (p->verts[i].xyz, r_origin, verts[i]);
		                }
		                ClipSkyPolygon (p->numverts, verts[0], 0);
		            }

		        }
			}
		    else // otherwise, draw the normal quake sky
			{
                R_DrawScroll_SkyChain (s);
			}
	  }
}

//===============================================================

/*
=============
R_InitSky

A sky texture is 256*128, with the right side being a masked overlay
==============
*/
void R_InitSky (byte *mt)
{
	byte	trans[128*128];

	const byte* const src = (byte *)mt;

	for (int i=0 ; i<128 ; i++)
	{
		for (int j=0 ; j<128 ; j++)
		{
			const byte p = src[i*256 + j + 128];
			trans[(i*128) + j] = p;
		}
	}

	if (solidskytexture == -1)
		solidskytexture = GL_LoadTexture("solidskytexture", 128, 128, trans, qfalse, GU_LINEAR, 0);

	for (int i=0 ; i<128 ; i++)
	{
		for (int j=0 ; j<128 ; j++)
		{
			const byte p = src[i*256 + j];
			if (p == 0)
				trans[(i*128) + j] = 255;
			else
				trans[(i*128) + j] = p;
		}
	}

	if (alphaskytexture == -1)
		alphaskytexture = GL_LoadTexture("alphaskytexture", 128, 128, trans, qfalse, GU_LINEAR, 0);
}

