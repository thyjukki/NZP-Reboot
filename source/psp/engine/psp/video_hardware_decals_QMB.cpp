/*
Copyright (C) 2006, Charles Hollemeersch, Sputnikutah
Copyright (C) 2007-2008 Crow_bar.

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
// gl_decals.c
extern "C"
{
#include "../quakedef.h"
}

#include <list>
#include <pspgu.h>

#include "clipping.hpp"


using namespace std;
using namespace quake;

list<int> TempDecalTextureList;

#ifdef SLIM
#define DEFAULT_NUM_DECALS      1024 //*4
#else
#define DEFAULT_NUM_DECALS      256
#endif

#define ABSOLUTE_MIN_DECALS		256
#define ABSOLUTE_MAX_DECALS		32768
#define MAX_DECAL_VERTICES		128
#define MAX_DECAL_TRIANGLES		64

typedef struct decal_s
{
	vec3_t		origin;
	vec3_t		normal;
	vec3_t		tangent;
	float		radius;
	int         bspdecal;

	struct decal_s	*next;
	float		die;
	float		starttime;

	int			srcblend;
	int			dstblend;

	int			texture;

	// geometry of decal
	int			vertexCount, triangleCount;
	vec3_t		vertexArray[MAX_DECAL_VERTICES];
	float		texcoordArray[MAX_DECAL_VERTICES][2];
	int			triangleArray[MAX_DECAL_TRIANGLES][3];
} decal_t;

extern int		decal_blood1, decal_blood2, decal_blood3, decal_q3blood, decal_burn, decal_mark, decal_glow;

static	decal_t	*decals, *active_decals, *free_decals;
static	int		r_numdecals;

static	plane_t	leftPlane, rightPlane, bottomPlane, topPlane, backPlane, frontPlane;

cvar_t	r_decaltime = {"r_decaltime", "12"};
cvar_t	r_decal_viewdistance = {"r_decal_viewdistance", "1024"};

void DecalClipLeaf (decal_t *dec, mleaf_t *leaf);
void DecalWalkBsp_R (decal_t *dec, mnode_t *node);
int DecalClipPolygonAgainstPlane (plane_t *plane, int vertexCount, vec3_t *vertex, vec3_t *newVertex);
int DecalClipPolygon (int vertexCount, vec3_t *vertices, vec3_t *newVertex);
/*
#define lhrandom(MIN, MAX) ((rand() & 32767) * (((MAX)-(MIN)) * (1.0f / 32767.0f)) + (MIN))

#define VectorRandom(v)				\
{									\
	do {							\
		(v)[0] = lhrandom(-1, 1);	\
		(v)[1] = lhrandom(-1, 1);	\
		(v)[2] = lhrandom(-1, 1);	\
	} while (DotProduct(v, v) > 1);	\
}
*/
float RandomMinMax (float min, float max)
{
	return min + ((rand() % 10000) / 10000.0) * (max - min);
}

/*
===============
R_InitDecals
===============
*/
void R_InitDecals (void)
{
  int	i;

	Cvar_RegisterVariable (&r_decaltime);
	Cvar_RegisterVariable (&r_decal_viewdistance);

	if (!qmb_initialized)
		return;
/*
 decal_blood1  = loadtextureimage("textures/decals/blood_splat01",   0, 0, qfalse, GU_LINEAR);
 decal_blood2  = loadtextureimage("textures/decals/blood_splat02",   0, 0, qfalse, GU_LINEAR);
 decal_blood3  = loadtextureimage("textures/decals/blood_splat03",   0, 0, qfalse, GU_LINEAR);
 decal_q3blood = loadtextureimage("textures/decals/blood_stain",     0, 0, qfalse, GU_LINEAR);
 decal_burn    = loadtextureimage("textures/decals/explo_burn01",    0, 0, qfalse, GU_LINEAR);
 decal_mark    = loadtextureimage("textures/decals/particle_burn01", 0, 0, qfalse, GU_LINEAR);
 decal_glow    = loadtextureimage("textures/decals/glow2",           0, 0, qfalse, GU_LINEAR);

	decal_blood1 = GL_LoadTextureImage ("textures/decals/blood_splat01", "decals:blood_splat01", 128, 128, TEX_ALPHA | TEX_COMPLAIN);
	decal_blood2 = GL_LoadTextureImage ("textures/decals/blood_splat02", "decals:blood_splat02", 128, 128, TEX_ALPHA | TEX_COMPLAIN);
	decal_blood3 = GL_LoadTextureImage ("textures/decals/blood_splat03", "decals:blood_splat03", 128, 128, TEX_ALPHA | TEX_COMPLAIN);
	decal_q3blood = GL_LoadTextureImage ("textures/decals/blood_stain", "decals:blood_stain", 64, 64, TEX_ALPHA | TEX_COMPLAIN);
	decal_burn = GL_LoadTextureImage ("textures/decals/explo_burn01", "decals:explo_burn01", 128, 128, TEX_ALPHA | TEX_COMPLAIN);
	decal_mark = GL_LoadTextureImage ("textures/decals/particle_burn01", "decals:particle_burn01", 64, 64, TEX_ALPHA | TEX_COMPLAIN);
	decal_glow = GL_LoadTextureImage ("textures/decals/glow2", "decals:glow2", 64, 64, TEX_ALPHA | TEX_COMPLAIN);
*/
	if ((i = COM_CheckParm("-decals")) && i + 1 < com_argc)
	{
		r_numdecals = Q_atoi(com_argv[i+1]);
		r_numdecals = bound(ABSOLUTE_MIN_DECALS, r_numdecals, ABSOLUTE_MAX_DECALS);
	}
	else
	{
		r_numdecals = DEFAULT_NUM_DECALS;
	}

	decals = (decal_t*)Hunk_AllocName (r_numdecals * sizeof(decal_t), "decals");
}

/*
===============
R_ClearDecals
===============
*/
static int wadreload = 1;
void R_ClearDecals (void)
{
    int	i;

	if (!qmb_initialized)
		return;

	memset (decals, 0, r_numdecals * sizeof(decal_t));
	free_decals = &decals[0];
	active_decals = NULL;

	for (i = 0 ; i < r_numdecals ; i++)
		decals[i].next = &decals[i+1];

	decals[r_numdecals-1].next = NULL;

	while (TempDecalTextureList.size() > 0)
	{
		int index = TempDecalTextureList.front();
		TempDecalTextureList.pop_front();
		GL_UnloadTexture(index);
	}
    wadreload = 1;
}

void R_SpawnDecal (vec3_t center, vec3_t normal, vec3_t tangent, int tex, int size, int isbsp)
{
    int		a;
	float	width, height, depth, d, one_over_w, one_over_h;
	vec3_t	binormal, test = {0.5, 0.5, 0.5};
	decal_t	*dec;

	if (!qmb_initialized)
		return;

	// allocate decal
	if (!free_decals)
		return;

	dec           = free_decals;
	free_decals   = dec->next;
	dec->next     = active_decals;
	active_decals = dec;

	VectorNormalize (test);
	CrossProduct (normal, test, tangent);

	VectorCopy (center, dec->origin);
	VectorCopy (tangent, dec->tangent);
	VectorCopy (normal, dec->normal);
	VectorNormalize (tangent);
	VectorNormalize (normal);
	CrossProduct (normal, tangent, binormal);
	VectorNormalize (binormal);

	width          = RandomMinMax (size * 0.5, size);
	height         = width;
	depth          = width * 0.5;
	dec->radius    = fmax(fmax(width, height), depth);
	dec->starttime = cl.time;
	dec->bspdecal  = isbsp;
    dec->die       = (isbsp ? 0 : cl.time + r_decaltime.value);
	dec->texture   = tex;

	// Calculate boundary planes
	d = DotProduct (center, tangent);
	VectorCopy (tangent, leftPlane.normal);
	leftPlane.dist  = -(width * 0.5 - d);
	VectorNegate (tangent, tangent);
	VectorCopy (tangent, rightPlane.normal);
	VectorNegate (tangent, tangent);
	rightPlane.dist = -(width * 0.5 + d);

	d = DotProduct (center, binormal);
	VectorCopy (binormal, bottomPlane.normal);
	bottomPlane.dist = -(height * 0.5 - d);
	VectorNegate (binormal, binormal);
	VectorCopy (binormal, topPlane.normal);
	VectorNegate (binormal, binormal);
	topPlane.dist    = -(height * 0.5 + d);

	d = DotProduct (center, normal);
	VectorCopy (normal, backPlane.normal);
	backPlane.dist  = -(depth - d);
	VectorNegate (normal, normal);
	VectorCopy (normal, frontPlane.normal);
	VectorNegate (normal, normal);
	frontPlane.dist = -(depth + d);

	// Begin with empty mesh
	dec->vertexCount   = 0;
	dec->triangleCount = 0;

	// Clip decal to bsp
	DecalWalkBsp_R (dec, cl.worldmodel->nodes);

	// This happens when a decal is to far from any surface or the surface is to steeply sloped
	if (dec->triangleCount == 0)
	{	// deallocate decal
		active_decals = dec->next;
		dec->next   = free_decals;
		free_decals = dec;
		return;
	}

	// Assign texture mapping coordinates
	one_over_w = 1.0F / width;
	one_over_h = 1.0F / height;
	for (a = 0 ; a < dec->vertexCount ; a++)
	{
		float	s, t;
		vec3_t	v;

		VectorSubtract (dec->vertexArray[a], center, v);
		s = DotProduct (v, tangent) * one_over_w + 0.5F;
		t = DotProduct (v, binormal) * one_over_h + 0.5F;
		dec->texcoordArray[a][0] = s;
		dec->texcoordArray[a][1] = t;
	}
}
/*
//back up, pre-blubs
void _R_SpawnDecalStatic (vec3_t org, int tex, int size)
{
	int		i;
	float	frac, bestfrac;
	vec3_t	tangent, v, bestorg, normal, bestnormal, org2;

	if (!qmb_initialized)
		return;

	VectorClear (bestorg);
	VectorClear (bestnormal);

	bestfrac = 10;
	for (i = 0 ; i < 14 ; i++)
	{
		VectorRandom (org2);
		VectorMA (org, 20, org2, org2);
		TraceLineN (org, org2, v, normal);
		frac = 0.5;

		if (bestfrac > frac)
		{
			bestfrac = frac;
			VectorCopy (v, bestorg);
			VectorCopy (normal, bestnormal);
			CrossProduct (normal, bestnormal, tangent);
		}

		if (bestnormal && bestorg)
		{
			continue;
		}
		else
		{
			VectorNegate (org2, org2);
			VectorMA (org, 20, org2, org2);
			TraceLineN (org, org2, v, normal);
			VectorCopy (v, bestorg);
			VectorCopy (normal, bestnormal);
			CrossProduct (normal, bestnormal, tangent);
		}

		if (bestnormal && bestorg)
			continue;

	}

	if (bestfrac < 1)
		R_SpawnDecal (bestorg, bestnormal, tangent, tex, size, 0);
}*/

//Revamped by blubs
void R_SpawnDecalStatic (vec3_t org, int tex, int size)
{
	int		i;
	float	frac, bestfrac;
	vec3_t	tangent, v, bestorg, normal, bestnormal, org2;
	vec3_t tempVec;

	if (!qmb_initialized)
		return;

	VectorClear (bestorg);
	VectorClear (bestnormal);
	VectorClear(tempVec);

	bestfrac = 10;
	for (i = 0 ; i < 26 ; i++)
	{
		//Reference: i = 0: check straight up, i = 1: check straight down
			//1 < i < 10: Check sideways in increments of 45 degrees
			//9 < i < 18: Check angled 45 degrees down in increments of 45 degrees
			//17 < i : Check angled 45 degrees up in increments of 45 degrees
		org2[0] = (((((i - 2) % 8) < 2) ||  (((i - 2) % 8) == 7)) ? 1 : 0 ) + ((((i - 2) % 8) > 2 &&  ((i - 2) % 8) < 6) ? -1 : 0 );
		org2[1] = ((((i - 2) % 8) > 0 &&  ((i - 2) % 8) < 4) ? 1 : 0 ) + ((((i - 2) % 8) > 4 && ((i - 2) % 8) < 7) ? -1 : 0 );
		org2[2] = ((i == 0) ? 1 : 0) + ((i == 1) ? -1 : 0) + (((i > 9) && (i < 18)) ? 1 : 0) + ((i > 17) ? -1 : 0);

		VectorCopy(org,tempVec);
		VectorMA(tempVec, -0.1,org2,tempVec);

		VectorMA (org, 20, org2, org2);
		TraceLineN (tempVec, org2, v, normal);

		VectorSubtract(org2,tempVec,org2);//goal
		VectorSubtract(v,tempVec,tempVec);//collision

		if(VectorLength(org2) == 0)
			return;

		frac = VectorLength(tempVec) / VectorLength(org2);

		if(frac < 1 && frac < bestfrac)
		{
			bestfrac = frac;
			VectorCopy(v,bestorg);
			VectorCopy(normal, bestnormal);
			CrossProduct(normal,bestnormal,tangent);
		}
	}

	if (bestfrac < 1)
		R_SpawnDecal (bestorg, bestnormal, tangent, tex, size, 0);
}


//Crow_bar.
void R_SpawnDecalBSP (vec3_t org, char *texname, int size)
{
	int		i;
	float	frac, bestfrac;
	vec3_t	tangent, v, bestorg, normal, bestnormal, org2;
	vec3_t	tempVec;

	if (!qmb_initialized)
		return;

	int tex = loadtextureimage(va("decals/%s",texname),   0, 0, qfalse, GU_LINEAR);
	if(!tex) //find in decals.wad
	{
		if(wadreload)
		{
			WAD3_LoadTextureWadFile ("decals.wad");
			wadreload = 0;
		}
		tex = WAD3_LoadTextureName(texname);
		if(!tex)
		{
			return;
		}
	}

	//don't free static decals
	if((tex != decal_q3blood) &&
	   (tex != decal_blood1)  &&
	   (tex != decal_blood2)  &&
	   (tex != decal_blood3)  &&
	   (tex != decal_q3blood) &&
	   (tex != decal_burn)    &&
	   (tex != decal_mark)    &&
	   (tex != decal_glow))
	{
	   TempDecalTextureList.push_back(tex); //write to list ,for unload
	}

	VectorClear (bestorg);
	VectorClear (bestnormal);
	VectorClear(tempVec);

	bestfrac = 10;
	for (i = 0 ; i < 26 ; i++)
	{
		//Reference: i = 0: check straight up, i = 1: check straight down
			//1 < i < 10: Check sideways in increments of 45 degrees
			//9 < i < 18: Check angled 45 degrees down in increments of 45 degrees
			//17 < i : Check angled 45 degrees up in increments of 45 degrees
		org2[0] = (((((i - 2) % 8) < 2) ||  (((i - 2) % 8) == 7)) ? 1 : 0 ) + ((((i - 2) % 8) > 2 &&  ((i - 2) % 8) < 6) ? -1 : 0 );
		org2[1] = ((((i - 2) % 8) > 0 &&  ((i - 2) % 8) < 4) ? 1 : 0 ) + ((((i - 2) % 8) > 4 && ((i - 2) % 8) < 7) ? -1 : 0 );
		org2[2] = ((i == 0) ? 1 : 0) + ((i == 1) ? -1 : 0) + (((i > 9) && (i < 18)) ? 1 : 0) + ((i > 17) ? -1 : 0);

		VectorCopy(org,tempVec);
		VectorMA(tempVec, -0.1,org2,tempVec);

		VectorMA (org, 20, org2, org2);
		TraceLineN (tempVec, org2, v, normal);

		VectorSubtract(org2,tempVec,org2);//goal
		VectorSubtract(v,tempVec,tempVec);//collision

		if(VectorLength(org2) == 0)
			return;

		frac = VectorLength(tempVec) / VectorLength(org2);

		if(frac < 1 && frac < bestfrac)
		{
			bestfrac = frac;
			VectorCopy(v,bestorg);
			VectorCopy(normal, bestnormal);
			CrossProduct(normal,bestnormal,tangent);
		}
	}

	if (bestfrac < 1)
		R_SpawnDecal (bestorg, bestnormal, tangent, tex, size, 1);
}

void DecalWalkBsp_R (decal_t *dec, mnode_t *node)
{
	float		dist;
	mplane_t	*plane;
	mleaf_t		*leaf;

	if (node->contents < 0)
	{	//we are in a leaf
		leaf = (mleaf_t *)node;
		DecalClipLeaf (dec, leaf);
		return;
	}

	plane = node->plane;
	dist = DotProduct (dec->origin, plane->normal) - plane->dist;

	if (dist > dec->radius)
	{
		DecalWalkBsp_R (dec, node->children[0]);
		return;
	}
	if (dist < -dec->radius)
	{
		DecalWalkBsp_R (dec, node->children[1]);
		return;
	}

	DecalWalkBsp_R (dec, node->children[0]);
	DecalWalkBsp_R (dec, node->children[1]);
}

qboolean DecalAddPolygon (decal_t *dec, int vertcount, vec3_t *vertices)
{
	int a, b, count, *triangle;

	count = dec->vertexCount;
	if (count + vertcount >= MAX_DECAL_VERTICES)
		return qfalse;

	if (dec->triangleCount + vertcount - 2 >= MAX_DECAL_TRIANGLES)
		return qfalse;

	// Add polygon as a triangle fan
	triangle = &dec->triangleArray[dec->triangleCount][0];
	for (a = 2 ; a < vertcount ; a++)
	{
		dec->triangleArray[dec->triangleCount][0] = count;
		dec->triangleArray[dec->triangleCount][1] = (count + a - 1);
		dec->triangleArray[dec->triangleCount][2] = (count + a );
		dec->triangleCount++;
	}

	// Assign vertex colors
	for (b = 0 ; b < vertcount ; b++)
	{
		VectorCopy(vertices[b], dec->vertexArray[count]);
		count++;
	}

	dec->vertexCount = count;
	return qtrue;
}

const double decalEpsilon = 0.001;

void DecalClipLeaf (decal_t *dec, mleaf_t *leaf)
{
 	int			c;
	vec3_t		newVertex[64], t3;
	msurface_t	**surf;

	c = leaf->nummarksurfaces;
	surf = leaf->firstmarksurface;

	// for all surfaces in the leaf
	for (c = 0 ; c < leaf->nummarksurfaces ; c++, surf++)
	{
		int		i, count;
		glpoly_t *poly;

		poly = (*surf)->polys;
		for (i = 0 ; i < poly->numverts ; i++)
		{
			newVertex[i][0] = poly->verts[i].xyz[0];
			newVertex[i][1] = poly->verts[i].xyz[1];
			newVertex[i][2] = poly->verts[i].xyz[2];
		}

		VectorCopy ((*surf)->plane->normal, t3);

		if ((*surf)->flags & SURF_PLANEBACK)
			VectorNegate (t3, t3);

		// avoid backfacing and ortogonal facing faces to recieve decal parts
		if (DotProduct(dec->normal, t3) > decalEpsilon)
		{
			count = DecalClipPolygon (poly->numverts, newVertex, newVertex);
			if (count != 0 && !DecalAddPolygon(dec, count, newVertex))
				break;
		}
	}
}

int DecalClipPolygon (int vertexCount, vec3_t *vertices, vec3_t *newVertex)
{
	vec3_t	tempVertex[64];

	// Clip against all six planes
	int count = DecalClipPolygonAgainstPlane (&leftPlane, vertexCount, vertices, tempVertex);
	if (count != 0)
	{
		count = DecalClipPolygonAgainstPlane (&rightPlane, count, tempVertex, newVertex);
		if (count != 0)
		{
			count = DecalClipPolygonAgainstPlane (&bottomPlane, count, newVertex, tempVertex);
			if (count != 0)
			{
				count = DecalClipPolygonAgainstPlane (&topPlane, count, tempVertex, newVertex);
				if (count != 0)
				{
					count = DecalClipPolygonAgainstPlane (&backPlane, count, newVertex, tempVertex);
					if (count != 0)
					{
						count = DecalClipPolygonAgainstPlane (&frontPlane, count, tempVertex, newVertex);
					}
				}
			}
		}
	}

	return count;
}

int DecalClipPolygonAgainstPlane (plane_t *plane, int vertexCount, vec3_t *vertex, vec3_t *newVertex)
{
	int		a, b, c, count, negativeCount = 0;
	float	t;
	bool negative[65];
	vec3_t	v1, v2;

	// Classify vertices
	for (a = 0 ; a < vertexCount ; a++)
	{
		bool neg = ((DotProduct(plane->normal, vertex[a]) - plane->dist) < 0.0);
		negative[a] = neg;
		negativeCount += neg;
	}

	// Discard this polygon if it's completely culled
	if (negativeCount == vertexCount)
		return 0;

	count = 0;
	for (b = 0 ; b < vertexCount ; b++)
	{
		// c is the index of the previous vertex
		c = (b != 0) ? b - 1 : vertexCount - 1;

		if (negative[b])
		{
			if (!negative[c])
			{
				// Current vertex is on negative side of plane, but previous vertex is on positive side.
				VectorCopy (vertex[c], v1);
				VectorCopy (vertex[b], v2);

				t = (DotProduct(plane->normal, v1) - plane->dist) /
					 (plane->normal[0] * (v1[0] - v2[0])
					+ plane->normal[1] * (v1[1] - v2[1])
					+ plane->normal[2] * (v1[2] - v2[2]));

				VectorScale (v1, (1.0 - t), newVertex[count]);
				VectorMA (newVertex[count], t, v2, newVertex[count]);

				count++;
			}
		}
		else
		{
			if (negative[c])
			{
				// Current vertex is on positive side of plane, but previous vertex is on negative side.
				VectorCopy (vertex[b], v1);
				VectorCopy (vertex[c], v2);

				t = (DotProduct(plane->normal, v1) - plane->dist) /
					 (plane->normal[0] * (v1[0] - v2[0])
					+ plane->normal[1] * (v1[1] - v2[1])
					+ plane->normal[2] * (v1[2] - v2[2]));

				VectorScale (v1, (1.0 - t), newVertex[count]);
				VectorMA (newVertex[count], t, v2, newVertex[count]);

				count++;
			}

			// Include current vertex
			VectorCopy (vertex[b], newVertex[count]);
			count++;
		}
	}

	// Return number of vertices in clipped polygon
	return count;
}

/*
===============
R_DrawDecals
===============
*/
void R_DrawDecals (void)
{
	int			i;
	float		dcolor;
	vec3_t		decaldist;
	decal_t		*p, *kill;
	float *point_tex, *point_xyz;

	if (!qmb_initialized)
		return;


	sceGuEnable (GU_BLEND);
	sceGuTexFunc(GU_TFX_MODULATE, GU_TCC_RGBA);
	sceGuDepthMask (GU_TRUE);
	sceGuShadeModel (GU_SMOOTH);
    sceGuDepthOffset(-256);


	for ( ; ; )
	{
		kill = active_decals;

		if (kill && (kill->die < cl.time) && (!kill->bspdecal))
		{
			active_decals = kill->next;
			kill->next = free_decals;
			free_decals = kill;
			continue;
		}
		break;
	}

	for (p = active_decals ; p ; p = p->next)
	{

		for ( ; ; )
		{
			kill = p->next;

			if (kill && (kill->die < cl.time) && (!kill->bspdecal))
			{
				p->next = kill->next;
				kill->next = free_decals;
				free_decals = kill;
				continue;
			}
			break;
		}
		VectorSubtract (r_refdef.vieworg, p->origin, decaldist);

		if (VectorLength(decaldist) > r_decal_viewdistance.value)
			continue;

		if (p->texture == decal_q3blood)
		  sceGuBlendFunc (GU_ADD, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, 0, 0);
		else
          sceGuBlendFunc(GU_ADD, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, 0, 0);


		GL_Bind (p->texture);

		dcolor = 1;
		if (((p->die - cl.time) < 0.5) && (!p->bspdecal))
		{
			float scale = 2 * (p->die - cl.time);
			sceGuColor(GU_COLOR(dcolor * scale, dcolor * scale, dcolor * scale, scale));
		}
		else
		{
			dcolor = (1 - (VectorLength(decaldist) / r_decal_viewdistance.value));
			sceGuColor(GU_COLOR(dcolor, dcolor, dcolor, dcolor));
		}

		for (i = 0 ; i < p->triangleCount ; i++)
		{
		    // Allocate memory for this polygon.
		    const int		unclipped_vertex_count	= 3;
		    glvert_t* const	unclipped_vertices		= static_cast<glvert_t*>(sceGuGetMemory(sizeof(glvert_t) * unclipped_vertex_count));
			for(int v = 0; v < unclipped_vertex_count ; v++)
			{
				point_tex = &p->texcoordArray[p->triangleArray[i][v]][0];
	 			point_xyz = &p->vertexArray  [p->triangleArray[i][v]][0];
				unclipped_vertices[v].st[0] = point_tex[0];
				unclipped_vertices[v].st[1] = point_tex[1];
				unclipped_vertices[v].xyz[0] = point_xyz[0];
				unclipped_vertices[v].xyz[1] = point_xyz[1];
				unclipped_vertices[v].xyz[2] = point_xyz[2];
            }

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
	}

    sceGuDepthOffset(0);

   	sceGuDisable (GU_BLEND);
	sceGuBlendFunc(GU_ADD, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, 0, 0);
	sceGuDepthMask (GU_FALSE);

	sceGuColor(GU_COLOR(1,1,1,1));
	sceGuTexFunc(GU_TFX_REPLACE, GU_TCC_RGBA);
	sceGuShadeModel (GU_FLAT);
}

