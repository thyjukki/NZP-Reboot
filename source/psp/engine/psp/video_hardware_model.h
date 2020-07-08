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



#ifndef __MODEL__
#define __MODEL__

#include "../modelgen.h"
#include "../spritegn.h"

#ifdef PSP_VFPU
#include <pspmath.h>
#endif


/*

d*_t structures are on-disk representations
m*_t structures are in-memory

*/

// entity effects

#define	EF_BLUELIGHT			1
#define	EF_MUZZLEFLASH 			2
#define	EF_BRIGHTLIGHT 			4
#define	EF_REDLIGHT 			8
#define	EF_ORANGELIGHT			16
#define	EF_GREENLIGHT			32
#define	EF_LIGHT				64
#define	EF_NODRAW				128
#define EF_BRIGHTFIELD			256
#define EF_FULLBRIGHT			512
#define EF_DARKLIGHT			1024
#define EF_DARKFIELD			2048
#define EF_PURPLELIGHT    		4096
#define EF_RAYRED	 			8196			// red trail for porter x2
#define EF_RAYGREEN  			16384			// gree trail for ray gun

/*
==============================================================================

BRUSH MODELS

==============================================================================
*/
//
// in memory representation
//
// !!! if this is changed, it must be changed in asm_draw.h too !!!
typedef struct
{
	vec3_t		position;
} mvertex_t;

#define	SIDE_FRONT	0
#define	SIDE_BACK	1
#define	SIDE_ON		2


// plane_t structure
// !!! if this is changed, it must be changed in asm_i386.h too !!!
typedef struct mplane_s
{
	vec3_t	normal;
	float	dist;
	byte	type;			// for texture axis selection and fast side tests
	byte	signbits;		// signx + signy<<1 + signz<<1
	byte	pad[2];
} mplane_t;

typedef struct texture_s
{
	char		name[16];
	unsigned	width, height;
	int			gl_texturenum;
    int			dt_texturenum;
#ifdef FULLBRIGHT
	int         fullbright;
#endif

	struct 		msurface_s *texturechain;	// for gl_texsort drawing
	int			anim_total;				// total tenths in sequence ( 0 = no)
	int			anim_min, anim_max;		// time for this frame min <=time< max
	struct 		texture_s *anim_next;		// in the animation sequence
	struct 		texture_s *alternate_anims;	// bmodels in frmae 1 use these
	unsigned	offsets[MIPLEVELS];		// four mip maps stored
} texture_t;


#define	SURF_PLANEBACK		2
#define	SURF_DRAWSKY		4
#define SURF_DRAWSPRITE		8
#define SURF_DRAWTURB		0x10
#define SURF_DRAWTILED		0x20
#define SURF_DRAWBACKGROUND	0x40
#define SURF_UNDERWATER		0x80

// !!! if this is changed, it must be changed in asm_draw.h too !!!
typedef struct
{
	unsigned short	v[2];
	unsigned int	cachededgeoffset;
} medge_t;

typedef struct
{
	float		vecs[2][4];
	float		mipadjust;
	texture_t	*texture;
	int			flags;
} mtexinfo_t;

//typedef vec_t vec2_t[2];

typedef struct glvert_s
{
	vec2_t	st;
	vec3_t	xyz;
} glvert_t;

typedef struct glpoly_s
{
	struct		glpoly_s	*next;
	struct		glpoly_s	*chain;
	int			numverts;
	int			flags;		// for SURF_UNDERWATER
    struct glpoly_s	*detail_chain;		// next detail poly in chain
    struct glpoly_s	*caustics_chain;	// next caustic poly in chain
    vec3_t midpoint;//MHQuake
	float fxofs;	//MHQuake
	// This is a variable sized array, and hence must be the last element in
	// this structure.
	//
	// The array is (numverts * 2) in size. The first half are regular
	// vertices, and the second half have copies of the first half's XYZs but
	// keep the light map texture coordinates. This makes the vertices easier
	// to render on the PSP.
	// naievil -- changed from verts[1] to verts[2] in order to not have possible out of bounds error during compilation
	//            and create some sort of condition that causes the verts to not be assigned!
	glvert_t	verts[2];
} glpoly_t;

typedef struct msurface_s
{
	int			visframe;		// should be drawn when node is crossed

	mplane_t	*plane;
	int			flags;

	int			firstedge;	// look up in model->surfedges[], negative numbers
	int			numedges;	// are backwards edges

	short		texturemins[2];
	short		extents[2];

	int			light_s, light_t;	// gl lightmap coordinates

	glpoly_t	*polys;				// multiple if warped
	struct	msurface_s	*texturechain;

	mtexinfo_t	*texinfo;
	int draw_this_frame;

// lighting info
	int			dlightframe;
	int			dlightbits;

	int			lightmaptexturenum;
	byte		styles[MAXLIGHTMAPS];
	int			cached_light[MAXLIGHTMAPS];	// values currently used in lightmap
	qboolean	cached_dlight;				// true if dynamic light in cache
	byte		*samples;		// [numstyles*surfsize]
} msurface_t;

typedef struct mnode_s
{
// common with leaf
	int			contents;		// 0, to differentiate from leafs
	int			visframe;		// node needs to be traversed if current

	float		minmaxs[6];		// for bounding box culling

	struct mnode_s	*parent;

// node specific
	mplane_t	*plane;
	struct mnode_s	*children[2];

	unsigned short		firstsurface;
	unsigned short		numsurfaces;
} mnode_t;



typedef struct mleaf_s
{
// common with node
	int			contents;		// wil be a negative contents number
	int			visframe;		// node needs to be traversed if current

	float		minmaxs[6];		// for bounding box culling

	struct mnode_s	*parent;

// leaf specific
	byte		*compressed_vis;
	efrag_t		*efrags;

	msurface_t	**firstmarksurface;
	int			nummarksurfaces;
	int			key;			// BSP sequence number for leaf's contents
	byte		ambient_sound_level[NUM_AMBIENTS];
} mleaf_t;

// !!! if this is changed, it must be changed in asm_i386.h too !!!
typedef struct
{
	dclipnode_t	*clipnodes;
	mplane_t	*planes;
	int			firstclipnode;
	int			lastclipnode;
	vec3_t		clip_mins;
	vec3_t		clip_maxs;
} hull_t;

/*
==============================================================================

SPRITE MODELS

==============================================================================
*/


// FIXME: shorten these?
typedef struct mspriteframe_s
{
	int		width;
	int		height;
	float	up, down, left, right;
	int		gl_texturenum;
} mspriteframe_t;


typedef struct
{
	int				numframes;
	float			*intervals;
	mspriteframe_t	*frames[1];
} mspritegroup_t;

typedef struct
{
	spriteframetype_t	type;
	mspriteframe_t		*frameptr;
} mspriteframedesc_t;

typedef struct
{
	int					type;
	int					maxwidth;
	int					maxheight;
	int					numframes;
	float				beamlength;		// remove? no! and it!
	void				*cachespot;		// remove? no! and it!
	mspriteframedesc_t	frames[1];
} msprite_t;



/*
==============================================================================

ALIAS MODELS

Alias models are position independent, so the cache manager can move them.
==============================================================================
*/

typedef struct
{
	int					firstpose;
	int					numposes;
	float				interval;
	trivertx_t			bboxmin;
	trivertx_t			bboxmax;
	int					frame;
	char				name[16];
} maliasframedesc_t;

typedef struct
{
	trivertx_t			bboxmin;
	trivertx_t			bboxmax;
	int					frame;
} maliasgroupframedesc_t;

typedef struct
{
	int						numframes;
	int						intervals;
	maliasgroupframedesc_t	frames[1];
} maliasgroup_t;

// !!! if this is changed, it must be changed in asm_draw.h too !!!
typedef struct mtriangle_s {
	int					facesfront;
	int					vertindex[3];
} mtriangle_t;

typedef struct mh2triangle_s
{
	int					facesfront;
	unsigned short		vertindex[3];
    unsigned short		stindex[3];
} mh2triangle_t;


#define	MAX_SKINS	32
typedef struct {
	int			ident;
	int			version;
	vec3_t		scale;
	vec3_t		scale_origin;
	float		boundingradius;
	vec3_t		eyeposition;
	int			numskins;
	int			skinwidth;
	int			skinheight;
	int			numverts;
	int			numtris;
	int			numframes;
	synctype_t	synctype;
	int			flags;
	float		size;

	int					numposes;
	int					poseverts;
	int					posedata;	// numposes*poseverts trivert_t
	int					commands;	// gl command list with embedded s/t
	int					gl_texturenum[MAX_SKINS][4];
	int					texels[MAX_SKINS];	// only for player skins
	maliasframedesc_t	frames[1];	// variable sized
} aliashdr_t;

// MOTO - ADQuake has MAXALIASVERTS set to 5120.. why?
#define	MAXALIASVERTS	2048
#define	MAXALIASFRAMES	256
#define	MAXALIASTRIS	2048
extern	aliashdr_t	*pheader;
extern	stvert_t	stverts[MAXALIASVERTS];
extern	mtriangle_t	triangles[MAXALIASTRIS];
extern	mh2triangle_t	h2triangles[MAXALIASTRIS];
extern	trivertx_t	*poseverts[MAXALIASFRAMES];

//===================================================================

//
// Whole model
//

typedef enum
{
mod_brush,
mod_sprite,
mod_alias,
mod_halflife,
mod_md3
}
modtype_t;

#define	EF_ROCKET	 1				// leave a trail
#define	EF_GRENADE	 2				// leave a trail
#define	EF_GIB		 4				// leave a trail
#define	EF_ROTATE	 8				// rotate (bonus items)
#define	EF_TRACER	 16				// green split trail
#define	EF_ZOMGIB	 32				// small blood trail
#define	EF_TRACER2	 64				// orange split trail + rotate
#define	EF_TRACER3	 128			// purple trail
#define	EF_Q3TRANS	 256		    // Q3 model containing transparent surface(s)

/*
========================================================================
.MD2 triangle model file format
========================================================================
*/

// LordHavoc: grabbed this from the Q2 utility source,
// renamed a things to avoid conflicts

#define MD2IDALIASHEADER		(('2'<<24)+('P'<<16)+('D'<<8)+'I')
#define MD2ALIAS_VERSION	8

#define	MD2MAX_TRIANGLES	4096
#define MD2MAX_VERTS		2048
#define MD2MAX_FRAMES		512
#define MD2MAX_SKINS		32
#define	MD2MAX_SKINNAME		64
// sanity checking size
#define MD2MAX_SIZE	(1024*4200)

typedef struct
{
	short	s;
	short	t;
} md2stvert_t;

typedef struct
{
	short	index_xyz[3];
	short	index_st[3];
} md2triangle_t;

typedef struct
{
	byte	v[3];			// scaled byte to fit in frame mins/maxs
	byte	lightnormalindex;
} md2trivertx_t;

#define MD2TRIVERTX_V0   0
#define MD2TRIVERTX_V1   1
#define MD2TRIVERTX_V2   2
#define MD2TRIVERTX_LNI  3
#define MD2TRIVERTX_SIZE 4

typedef struct
{
	float		scale[3];	// multiply byte verts by this
	float		translate[3];	// then add this
	char		name[16];	// frame name from grabbing
	md2trivertx_t	verts[1];	// variable sized
} md2frame_t;


// the glcmd format:
// a positive integer starts a tristrip command, followed by that many
// vertex structures.
// a negative integer starts a trifan command, followed by -x vertexes
// a zero indicates the end of the command list.
// a vertex consists of a floating point s, a floating point t,
// and an integer vertex index.


typedef struct
{
	int			ident;
	int			version;

	int			skinwidth;
	int			skinheight;
	int			framesize;		// byte size of each frame

	int			num_skins;
	int			num_xyz;
	int			num_st;			// greater than num_xyz for seams
	int			num_tris;
	int			num_glcmds;		// dwords in strip/fan command list
	int			num_frames;

	int			ofs_skins;		// each skin is a MAX_SKINNAME string
	int			ofs_st;			// byte offset from start for stverts
	int			ofs_tris;		// offset for dtriangles
	int			ofs_frames;		// offset for first frame
	int			ofs_glcmds;
	int			ofs_end;		// end of file

	int			gl_texturenum[MAX_SKINS];
} md2_t;

#define ALIASTYPE_MDL 1
#define ALIASTYPE_MD2 2

//==============================================================================
//===================================Q3 Models==================================
//==============================================================================

#define MD3IDHEADER		(('3'<<24)+('P'<<16)+('D'<<8)+'I')
#define	MD3_VERSION	15

typedef struct
{
	int		ident;
	int		version;
	char		name[MAX_QPATH];
	int      	flags;
	int		numframes;
	int		numtags;
	int		numsurfs;
	int		numskins;
	int		ofsframes;
	int		ofstags;
	int		ofssurfs;
	int		ofsend;
} md3header_t;

typedef struct
{
	vec3_t		mins, maxs;
	vec3_t		pos;
	float		radius;
	char		name[16];
} md3frame_t;

typedef struct
{
	char		name[MAX_QPATH];
	vec3_t		pos;
	vec3_t		rot[3];
} md3tag_t;

typedef struct
{
	int		ident;
	char		name[MAX_QPATH];
	int		flags;
	int		numframes;
	int		numshaders;
	int		numverts;
	int		numtris;
	int		ofstris;
	int		ofsshaders;
	int		ofstc;
	int		ofsverts;
	int		ofsend;
} md3surface_t;

typedef struct
{
	char		name[MAX_QPATH];
	int		index;
} md3shader_t;

typedef struct
{
	char		name[MAX_QPATH];
	int		index;
	int		gl_texnum, fb_texnum;
} md3shader_mem_t;

typedef struct
{
	int		indexes[3];
} md3triangle_t;

typedef struct
{
	float		s, t;
} md3tc_t;

typedef struct
{
	short		vec[3];
	unsigned short	normal;
} md3vert_t;

typedef struct
{
	vec3_t		vec;
	vec3_t		normal;
	byte		anorm_pitch, anorm_yaw;
	unsigned short	oldnormal;	// needed for normal lighting
} md3vert_mem_t;

#define	MD3_XYZ_SCALE	(1.0 / 64)

#define	MAXMD3FRAMES	1024
#define	MAXMD3TAGS	16
#define	MAXMD3SURFS	32
#define	MAXMD3SHADERS	256
#define	MAXMD3VERTS	4096
#define	MAXMD3TRIS	8192

typedef struct animdata_s
{
	int	offset;
	int	num_frames;
	int	loop_frames;
	float	interval;
} animdata_t;

typedef enum animtype_s
{
	both_death1, both_death2, both_death3, both_dead1, both_dead2, both_dead3,
	torso_attack, torso_attack2, torso_stand, torso_stand2,
	legs_walk,legs_run, legs_idle,
	NUM_ANIMTYPES
} animtype_t;

extern	animdata_t	anims[NUM_ANIMTYPES];

//==============================================================================

// some models are special
typedef enum
{
	MOD_NORMAL,
	MOD_PLAYER,
	MOD_EYES,
	MOD_FLAME,
	MOD_THUNDERBOLT,
	MOD_WEAPON,
	MOD_LAVABALL,
	MOD_SPIKE,
	MOD_SHAMBLER,
	MOD_SPR,
	MOD_SPR32,
//	MOD_GKEY,
//	MOD_SKEY,
} modhint_t;



typedef struct model_s
{
	char		name[MAX_QPATH];
	qboolean	needload;		// bmodels and sprites don't cache normally

	modhint_t			modhint;

	modtype_t	type;
    int			aliastype; // LordHavoc: Q2 model support
	int			numframes;
	synctype_t	synctype;

	int			flags;

//
// volume occupied by the model graphics
//
	vec3_t		mins, maxs;
	float		radius;

//
// solid volume for clipping
//
	qboolean	clipbox;
	vec3_t		clipmins, clipmaxs;

//
// brush model
//
	int			firstmodelsurface, nummodelsurfaces;

	int			numsubmodels;
	dmodel_t	*submodels;

	int			numplanes;
	mplane_t	*planes;

	int			numleafs;		// number of visible leafs, not counting 0
	mleaf_t		*leafs;

	int			numvertexes;
	mvertex_t	*vertexes;

	int			numedges;
	medge_t		*edges;

	int			numnodes;
	mnode_t		*nodes;

	int			numtexinfo;
	mtexinfo_t	*texinfo;

	int			numsurfaces;
	msurface_t	*surfaces;

	int			numsurfedges;
	int			*surfedges;

	int			numclipnodes;
	dclipnode_t	*clipnodes;

	int			nummarksurfaces;
	msurface_t	**marksurfaces;

	hull_t		hulls[MAX_MAP_HULLS];

	int			numtextures;
	texture_t	**textures;

	byte		*visdata;
	byte		*lightdata;
	char		*entities;
    int			bspversion;
    qboolean	isworldmodel;
//
// additional model data
//
	cache_user_t	cache;		// only access through Mod_Extradata

} model_t;

/*
==============================================================================

  .BSP Q2 file format

==============================================================================
*/

#define kIDBSPHEADER	(('P'<<24)+('S'<<16)+('B'<<8)+'I')
		// little-endian "IBSP"
#define Q2_BSPVERSION	38


// upper design bounds
// leaffaces, leafbrushes, planes, and verts are still bounded by
// 16 bit short limits
#define	Q2_MAX_MAP_MODELS		1024
#define	Q2_MAX_MAP_BRUSHES		8192
#define	Q2_MAX_MAP_ENTITIES	2048
#define	Q2_MAX_MAP_ENTSTRING	0x40000
#define	Q2_MAX_MAP_TEXINFO		8192

#define	Q2_MAX_MAP_AREAS		256
#define	Q2_MAX_MAP_AREAPORTALS	1024
#define	Q2_MAX_MAP_PLANES		65536
#define	Q2_MAX_MAP_NODES		65536
#define	Q2_MAX_MAP_BRUSHSIDES	65536
#define	Q2_MAX_MAP_LEAFS		65536
#define	Q2_MAX_MAP_VERTS		65536
#define	Q2_MAX_MAP_FACES		65536
#define	Q2_MAX_MAP_LEAFFACES	65536
#define	Q2_MAX_MAP_LEAFBRUSHES 65536
#define	Q2_MAX_MAP_PORTALS		65536
#define	Q2_MAX_MAP_EDGES		128000
#define	Q2_MAX_MAP_SURFEDGES	256000
#define	Q2_MAX_MAP_LIGHTING	0x200000
#define	Q2_MAX_MAP_VISIBILITY	0x100000

// key / value pair sizes

#define	Q2_MAX_KEY		32
#define	Q2_MAX_VALUE	1024

#define	Q2_LUMP_ENTITIES	0
#define	Q2_LUMP_PLANES		1
#define	Q2_LUMP_VERTEXES	2
#define	Q2_LUMP_VISIBILITY	3
#define	Q2_LUMP_NODES		4
#define	Q2_LUMP_TEXINFO		5
#define	Q2_LUMP_FACES		6
#define	Q2_LUMP_LIGHTING	7
#define	Q2_LUMP_LEAFS		8
#define	Q2_LUMP_LEAFFACES	9
#define	Q2_LUMP_LEAFBRUSHES	10
#define	Q2_LUMP_EDGES		11
#define	Q2_LUMP_SURFEDGES	12
#define	Q2_LUMP_MODELS		13
#define	Q2_LUMP_BRUSHES		14
#define	Q2_LUMP_BRUSHSIDES	15
#define	Q2_LUMP_POP			16
#define	Q2_LUMP_AREAS		17
#define	Q2_LUMP_AREAPORTALS	18
#define	Q2_HEADER_LUMPS		19

//=============================================================================

//============================================================================


void	Mod_Init (void);
void	Mod_ClearAll (void);
model_t *Mod_ForName (char *name, qboolean crash);
void	*Mod_Extradata (model_t *mod);	// handles caching
void	Mod_TouchModel (char *name);

mleaf_t *Mod_PointInLeaf (float *p, model_t *model);
byte	*Mod_LeafPVS (mleaf_t *leaf, model_t *model);

void CL_AddDecal (vec3_t n, vec3_t pt, int type);
#endif	// __MODEL__
