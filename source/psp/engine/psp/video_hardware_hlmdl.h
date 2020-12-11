/*
 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Half-Life Model Renderer (Experimental) Copyright (C) 2001 James 'Ender' Brown [ender@quakesrc.org] This program is
    free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as
    published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
    details. You should have received a copy of the GNU General Public License along with this program; if not, write
    to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. fromquake.h -
    
	model_hl.h - halflife model structure
 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */
#define HLPOLYHEADER	(('T' << 24) + ('S' << 16) + ('D' << 8) + 'I')	/* little-endian "IDST" */
#define HLMDLHEADER		"IDST"

#define MAXSTUDIOTRIANGLES	20000	// TODO: tune this
#define MAXSTUDIOVERTS		2048	// TODO: tune this
#define MAXSTUDIOSEQUENCES	256		// total animation sequences
#define MAXSTUDIOSKINS		100		// total textures
#define MAXSTUDIOSRCBONES	512		// bones allowed at source movement
#define MAXSTUDIOBONES		128		// total bones actually used
#define MAXSTUDIOMODELS		32		// sub-models per model
#define MAXSTUDIOBODYPARTS	32
#define MAXSTUDIOGROUPS		4
#define MAXSTUDIOANIMATIONS	512		// per sequence
#define MAXSTUDIOMESHES		256
#define MAXSTUDIOEVENTS		1024
#define MAXSTUDIOPIVOTS		256
#define MAXSTUDIOCONTROLLERS 8

/*
 -----------------------------------------------------------------------------------------------------------------------
    main model header
 -----------------------------------------------------------------------------------------------------------------------
 */
typedef struct
{
    int		filetypeid;	//IDSP
	int		version;	//10
    char	name[64];
    int		filesize;
    vec3_t	unknown3[5];

    int		flags;
	int		numbones;
    int		boneindex;
    int		numcontrollers;
    int		controllerindex;
    int		unknown5[2];
    int		numseq;
    int		seqindex;

    int		numseqgroups;	// demand loaded sequences
    int		seqgroups;

	int		numtextures;
    int		textures;
	int		texturedataindex;
	int		numskinref;		// replaceable textures
	int		numskinfamilies;


	int		skins;
    int     numbodyparts;
    int		bodypartindex;

	int		unknown9[8];
} hlmdl_header_t;

typedef struct
{
	int					id;
	int					version;
	char				name[64];
	int					length;
	vec3_t				eyeposition;	// ideal eye position
	vec3_t				min;			// ideal movement hull size
	vec3_t				max;
	vec3_t				bbmin;			// clipping bounding box
	vec3_t				bbmax;
	int					flags;
	int					numbones;			// bones
	int					boneindex;
	int					numbonecontrollers;		// bone controllers
	int					bonecontrollerindex;
	int					numhitboxes;			// complex bounding boxes
	int					hitboxindex;
	int					numseq;				// animation sequences
	int					seqindex;
	int					numseqgroups;		// demand loaded sequences
	int					seqgroupindex;
	int					numtextures;		// raw textures
	int					textureindex;

	int					texturedataindex;
	int					numskinref;			// replaceable textures
	int					numskinfamilies;

	int					skinindex;
	int					numbodyparts;
	int					bodypartindex;
	int					numattachments;		// queryable attachable points
	int					attachmentindex;
	int					soundtable;
	int					soundindex;
	int					soundgroups;
	int					soundgroupindex;
	int					numtransitions;		// animation node to animation node transition graph
	int					transitionindex;
} studiohdr_t;

/*
 -----------------------------------------------------------------------------------------------------------------------
    skin info
 -----------------------------------------------------------------------------------------------------------------------
*/

// lighting options
#define STUDIO_NF_FLATSHADE		0x0001
#define STUDIO_NF_CHROME		0x0002
#define STUDIO_NF_FULLBRIGHT	0x0004

typedef struct
{
    char	name[64];
    int		flags;
    int		w;	/* width */
    int		h;	/* height */
    int		i;	/* index */
} hlmdl_tex_t;


/*
 -----------------------------------------------------------------------------------------------------------------------
    body part index
 -----------------------------------------------------------------------------------------------------------------------
 */
typedef struct
{
    char	name[64];
    int		nummodels;
    int		base;
    int		modelindex;
} hlmdl_bodypart_t;

/*
 -----------------------------------------------------------------------------------------------------------------------
    meshes
 -----------------------------------------------------------------------------------------------------------------------
 */
typedef struct
{
    int numtris;
    int index;
    int skinindex;
    int numnorms;		// per mesh normals
	int normindex;		// normal vec3_t
} hlmdl_mesh_t;

/*
 -----------------------------------------------------------------------------------------------------------------------
    bones
 -----------------------------------------------------------------------------------------------------------------------
 */
typedef struct
{
    char	name[32];
    int		parent;
    int		unknown1;
    int		bonecontroller[6];
    float	value[6];
    float	scale[6];
} hlmdl_bone_t;

/*
 -----------------------------------------------------------------------------------------------------------------------
    bone controllers
 -----------------------------------------------------------------------------------------------------------------------
 */
typedef struct
{
    int		name;
    int		type;
    float	start;
    float	end;
    int		unknown1;
    int		index;
} hlmdl_bonecontroller_t;

/*
 -----------------------------------------------------------------------------------------------------------------------
    halflife model descriptor
 -----------------------------------------------------------------------------------------------------------------------
 */
typedef struct
{
    char	name[64];

    int		type;

    float	boundingradius;

    int		nummesh;
    int		meshindex;

    int		numverts;
    int		vertinfoindex;
    int		vertindex;

	int		numnorms;
	int		norminfoindex;	
	int		normindex;

    int		numgroups;
	int		groupindex;
} hlmdl_model_t;

/*
 -----------------------------------------------------------------------------------------------------------------------
    animation
 -----------------------------------------------------------------------------------------------------------------------
 */
typedef struct
{
    unsigned short	offset[6];
} hlmdl_anim_t;

/*
 -----------------------------------------------------------------------------------------------------------------------
    animation frames
 -----------------------------------------------------------------------------------------------------------------------
 */
typedef union
{
    struct
	{
        byte	valid;
        byte	total;
	} num;
    short	value;
} hlmdl_animvalue_t;

/*
 -----------------------------------------------------------------------------------------------------------------------
    sequence descriptions
 -----------------------------------------------------------------------------------------------------------------------
 */
typedef struct
{
    char	name[32];
    float	timing;
    int		unknown1[5];
    int		numframes;
    int		unknown2[2];
    int		motiontype;
    int		motionbone;
    vec3_t	unknown3;
    int		unknown4[2];
    vec3_t	unknown5[2];
    int		unknown6;
    int		index;
    int		unknown7[2];
    float	unknown[4];
    int		unknown8;
    int		seqindex;
    int		unknown9[4];
} hlmdl_sequencelist_t;

/*
 -----------------------------------------------------------------------------------------------------------------------
    sequence groups
 -----------------------------------------------------------------------------------------------------------------------
 */
typedef struct
{
    char			name[96];	/* should be split label[32] and name[64] */
    void *		cache;
    int				data;
} hlmdl_sequencedata_t;

/*
 -----------------------------------------------------------------------------------------------------------------------
    halflife model internal structure
 -----------------------------------------------------------------------------------------------------------------------
 */
typedef struct
{
    int		sequence;
    int		frame;					/* Current animation sequence and frame */
    float	frametime;				/* Time of last frame drawn */
    float	controller[4];			/* Position of bone controllers */
    float	adjust[4];

    /* Static pointers */
    hlmdl_header_t			*header;
    hlmdl_tex_t				*textures;
    hlmdl_bone_t			*bones;
    hlmdl_bonecontroller_t		*bonectls;
} hlmodel_t;

typedef struct	//this is stored as the cache. an hlmodel_t is generated when drawing
{
    int header;
    int textures;
    int bones;
    int bonectls;
} hlmodelcache_t;

// lighting options
#define STUDIO_NF_FLATSHADE		0x0001
#define STUDIO_NF_CHROME		0x0002
#define STUDIO_NF_FULLBRIGHT	0x0004

// motion flags
#define STUDIO_X		0x0001
#define STUDIO_Y		0x0002
#define STUDIO_Z		0x0004
#define STUDIO_XR		0x0008
#define STUDIO_YR		0x0010
#define STUDIO_ZR		0x0020
#define STUDIO_LX		0x0040
#define STUDIO_LY		0x0080
#define STUDIO_LZ		0x0100
#define STUDIO_AX		0x0200
#define STUDIO_AY		0x0400
#define STUDIO_AZ		0x0800
#define STUDIO_AXR		0x1000
#define STUDIO_AYR		0x2000
#define STUDIO_AZR		0x4000
#define STUDIO_TYPES	0x7FFF
#define STUDIO_RLOOP	0x8000	// controller that wraps shortest distance

// sequence flags
#define STUDIO_LOOPING	0x0001

// bone flags
#define STUDIO_HAS_NORMALS	0x0001
#define STUDIO_HAS_VERTICES 0x0002
#define STUDIO_HAS_BBOX		0x0004
#define STUDIO_HAS_CHROME	0x0008	// if any of the textures have chrome on them

#define RAD_TO_STUDIO		(32768.0/M_PI)
#define STUDIO_TO_RAD		(M_PI/32768.0)

/* HL mathlib prototypes: */
void	QuaternionGLAngle(const vec3_t angles, vec4_t quaternion);
void	QuaternionGLMatrix(float x, float y, float z, float w, vec4_t *GLM);
//void	UploadTexture(hlmdl_tex_t *ptexture, qbyte *data, qbyte *pal);

/* HL drawing */
qboolean Mod_LoadHLModel (model_t *mod, void *buffer);
int	HL_CurSequence(hlmodel_t model);
int	HL_NewSequence(hlmodel_t * model, int _inew);
void	HL_SetController(hlmodel_t *model, int num, float value);
void R_DrawHLModel(entity_t	*curent);
