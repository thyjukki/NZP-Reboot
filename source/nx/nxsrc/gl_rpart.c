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
// gl_rpart.c

#include "quakedef.h"

#define	ABSOLUTE_MIN_PARTICLES      64
#define	ABSOLUTE_MAX_PARTICLES		12288

typedef	byte	col_t[4];

typedef	enum
{
	p_spark,
	p_smoke,
	p_fire,
	p_fire2,
	p_bubble,
	p_lavasplash,
	p_gunblast,
	p_chunk,
	p_shockwave,
	p_inferno_flame,
	p_inferno_trail,
	p_sparkray,
	p_staticbubble,
	p_trailpart,
	p_dpsmoke,
	p_dpfire,
	p_teleflare,
	p_blood1,
	p_blood2,
	p_blood3,
	p_bloodcloud,
    p_q3blood,
	p_flame,
	p_lavatrail,
	p_bubble2,
	p_rain,
	p_streak,
	p_streaktrail,
	p_streakwave,
	p_lightningbeam,
	p_glow,
	p_alphatrail,//R00k
	p_torch_flame,
	p_flare,
	p_dot,
	p_muzzleflash,
	p_muzzleflash2,
	p_muzzleflash3,
	p_muzzleflash8,
	p_fly,
    p_q3blood_trail,
	p_q3blood_decal,
	p_q3rocketsmoke,
	p_q3grenadesmoke,
	p_q3explosion,
	p_q3flame,
	p_q3gunshot,
	p_q3teleport,
	num_particletypes
} part_type_t;

typedef	enum
{
	pm_static,
	pm_normal,
	pm_bounce,
	pm_die,
	pm_nophysics,
	pm_float,
	pm_rain,
	pm_streak,
	pm_streakwave,
} part_move_t;

typedef	enum
{
	ptex_none,
	ptex_smoke,
	ptex_bubble,
	ptex_generic,
	ptex_dpsmoke,
	ptex_lava,
	ptex_blueflare,
	ptex_blood1,
	ptex_blood2,
	ptex_blood3,
	ptex_lightning,
	ptex_flame,
	ptex_muzzleflash,
	ptex_muzzleflash2,
	ptex_muzzleflash3,
	ptex_muzzleflash8,
	ptex_bloodcloud,
	ptex_fly,
   	ptex_q3blood,
	ptex_q3blood_trail,
	ptex_q3smoke,
	ptex_q3explosion,
	ptex_q3flame,
	num_particletextures
} part_tex_t;

typedef	enum
{
	pd_spark,
	pd_sparkray,
	pd_billboard,
    pd_billboard_vel,
	pd_hide,
	pd_beam,
    pd_q3flame,
	pd_q3gunshot,
	pd_q3teleport
} part_draw_t;

typedef	struct particle_type_s
{
	particle_t			*start;
	part_type_t			id;
	part_draw_t			drawtype;
	int					SrcBlend;
	int					DstBlend;
	part_tex_t			texture;
	float				startalpha;
	float				grav;
	float				accel;
	part_move_t 		move;
	float				custom;
} particle_type_t;

#define DEFAULT_NUM_DECALS      1024 //*4
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
	double		die;
	double		starttime;

	int			srcblend;
	int			dstblend;

	int			texture;

	// geometry of decal
	int			vertexCount, triangleCount;
	vec3_t		vertexArray[MAX_DECAL_VERTICES];
	float		texcoordArray[MAX_DECAL_VERTICES][2];
	int			triangleArray[MAX_DECAL_TRIANGLES][3];
} decal_t;

static	decal_t	*decals, *active_decals, *free_decals;


#define	MAX_PTEX_COMPONENTS		8

typedef struct particle_texture_s
{
	gltexture_t *gltexture;
	int		components;
	float	coords[MAX_PTEX_COMPONENTS][4];
} particle_texture_t;

static	float	sint[7] = {0.000000, 0.781832, 0.974928, 0.433884, -0.433884, -0.974928, -0.781832};
static	float	cost[7] = {1.000000, 0.623490, -0.222521, -0.900969, -0.900969, -0.222521, 0.623490};

extern particle_t			*particles, *free_particles;
static			particle_type_t		particle_types[num_particletypes];//R00k
static	int		particle_type_index[num_particletypes];
static			particle_texture_t	particle_textures[num_particletextures];

int				lightning_texture;//Vult
float			varray_vertex[16];//Vult
void			R_CalcBeamVerts (float *vert, vec3_t org1, vec3_t org2, float width);//Vult
vec3_t	NULLVEC = {0,0,0};//r00k

static	int		r_numparticles;
static	vec3_t	zerodir = {22, 22, 22};
static	int		particle_count = 0;
static	float	particle_time;

int	decals_enabled;

qboolean		qmb_initialized = false;

int				particle_mode = 0;	// 0: classic (default), 1: QMB, 2: mixed

extern gltexture_t *decal_blood1;
extern gltexture_t *decal_blood2;
extern gltexture_t *decal_blood3;
extern gltexture_t *decal_q3blood;
extern gltexture_t *decal_burn;
extern gltexture_t *decal_mark;
extern gltexture_t *decal_glow;
static	plane_t	leftPlane, rightPlane, bottomPlane, topPlane, backPlane, frontPlane;

#define ADD_PARTICLE_TEXTURE(_ptex, _glpic, _texindex, _components, _s1, _t1, _s2, _t2)\
do {																	\
	particle_textures[_ptex].gltexture = _glpic;							\
	particle_textures[_ptex].components = _components;					\
	particle_textures[_ptex].coords[_texindex][0] = (_s1 + 1) / max_s;	\
	particle_textures[_ptex].coords[_texindex][1] = (_t1 + 1) / max_t;	\
	particle_textures[_ptex].coords[_texindex][2] = (_s2 - 1) / max_s;	\
	particle_textures[_ptex].coords[_texindex][3] = (_t2 - 1) / max_t;	\
} while(0)

#define ADD_PARTICLE_TYPE(_id, _drawtype, _SrcBlend, _DstBlend, _texture, _startalpha, _grav, _accel, _move, _custom)\
do {\
	particle_types[count].id = (_id);\
	particle_types[count].drawtype = (_drawtype);\
	particle_types[count].SrcBlend = (_SrcBlend);\
	particle_types[count].DstBlend = (_DstBlend);\
	particle_types[count].texture = (_texture);\
	particle_types[count].startalpha = (_startalpha);\
	particle_types[count].grav = 9.8 * (_grav);\
	particle_types[count].accel = (_accel);\
	particle_types[count].move = (_move);\
	particle_types[count].custom = (_custom);\
	particle_type_index[_id] = count;\
	count++;\
} while(0)

cvar_t	r_part_gunshots	    = {"r_part_gunshots", "1", CVAR_ARCHIVE};
cvar_t	r_part_spikes	    = {"r_part_spikes", "2", CVAR_ARCHIVE};
cvar_t	r_bounceparticles	= {"r_bounceparticles", "1",CVAR_ARCHIVE};
cvar_t	r_flametype	        = {"r_flametype",        "2",CVAR_ARCHIVE};
cvar_t	r_decal_blood		= {"r_decal_blood", "1",CVAR_ARCHIVE};
cvar_t	r_decal_bullets	    = {"r_decal_bullets","1",CVAR_ARCHIVE};
cvar_t	r_decal_sparks		= {"r_decal_sparks","1",CVAR_ARCHIVE};
cvar_t	r_decal_explosions	= {"r_decal_explosions","1",CVAR_ARCHIVE};
cvar_t	r_particle_count	= {"r_particle_count", "4096", CVAR_ARCHIVE};
cvar_t	r_decaltime = {"r_decaltime", "12", CVAR_ARCHIVE};
extern cvar_t gl_farclip;

void d8to24col (col_t colourv, int colour)
{
	byte	*colourByte;

	colourByte = (byte *)&d_8to24table[colour];
	colourv[0] = colourByte[0];
	colourv[1] = colourByte[1];
	colourv[2] = colourByte[2];
}

float RandomMinMax (float min, float max)
{
	return min + ((rand() % 10000) / 10000.0) * (max - min);
}

static byte *ColorForParticle (part_type_t type)
{
	static	col_t	color;
    int		lambda;

	switch (type)
	{
	case p_spark:
		color[0] = 224 + (rand() & 31);
		color[1] = 100 + (rand() & 31);
		color[2] = 50;
		break;

	case p_torch_flame:
	case p_glow:
		color[0] = color[1] = color[2] = 255;
		break;

	case p_smoke:
		color[0] = color[1] = color[2] = 128;
		color[3] = 64;
		break;

	case p_q3rocketsmoke:
	case p_q3grenadesmoke:
		color[0] = color[1] = color[2] = 160;
		break;

	case p_q3explosion:
	case p_q3flame:
	case p_q3gunshot:	// not used
	case p_q3teleport:	// not used
		color[0] = color[1] = color[2] = 255;
		break;

	case p_fire:
		color[0] = 255;
		color[1] = 122;
		color[2] = 62;
		break;
	case p_fire2:
		color[0] = 80;
		color[1] = 80;
		color[2] = 80;
		color[3] = 64;
		break;

	case p_bubble:
	case p_bubble2:
	case p_staticbubble:
		color[0] = color[1] = color[2] = 192 + (rand() & 63);
		break;

	case p_teleflare:
	case p_lavasplash:
		color[0] = color[1] = color[2] = 128 + (rand() & 127);
		break;

	case p_gunblast:
		color[0]= 224 + (rand() & 31);
		color[1] = 170 + (rand() & 31);
		color[2] = 0;
		break;

	case p_chunk:
		color[0] = color[1] = color[2] = (32 + (rand() & 127));
		break;

	case p_shockwave:
		color[0] = color[1] = color[2] = 64 + (rand() & 31);
		break;

	case p_inferno_flame:
	case p_inferno_trail:
		color[0] = 255;
		color[1] = 77;
		color[2] = 13;
		break;

	case p_sparkray:
		color[0] = 255;
		color[1] = 102;
		color[2] = 25;
		break;

	case p_dpsmoke:
		color[0] = color[1] = color[2] = 48 + (((rand() & 0xFF) * 48) >> 8);
		break;

	case p_dpfire:
		lambda = rand() & 0xFF;
		color[0] = 160 + ((lambda * 48) >> 8);
		color[1] = 16 + ((lambda * 148) >> 8);
		color[2] = 16 + ((lambda * 16) >> 8);
		break;

	case p_blood1:
	case p_blood2:
		color[0] = 30;
		color[1] = 5;
		color[2] = 5;
		color[3] = 255;
		break;

	case p_blood3:
		color[0] = (50 + (rand() & 31));
		color[1] = color[2] = 0;
		color[3] = 200;
		break;

	case p_q3blood:
	case p_q3blood_trail:
	case p_q3blood_decal:
		color[0] = 180;
		color[1] = color[2] = 0;
		break;

	case p_flame:
		color[0] = 255;
		color[1] = 100;
		color[2] = 25;
		color[3] = 128;
		break;

	case p_lavatrail:
		color[0] = 255;
		color[1] = 102;
		color[2] = 25;
		color[3] = 255;
		break;

	default:
		 //assert (!"ColorForParticle: unexpected type");
		break;
	}

	return color;
}

#define	INIT_NEW_PARTICLE(_pt, _p, _color, _size, _time)	\
	_p = free_particles;			\
	free_particles = _p->next;				\
	_p->next = _pt->start;					\
	_pt->start = _p;					\
	_p->size = _size;					\
	_p->hit = 0;						\
	_p->start = cl.time;					\
	_p->die = cl.time + _time;				\
	_p->growth = 0;						\
	_p->rotspeed = 0;					\
	_p->texindex = (rand() % particle_textures[_pt->texture].components);	\
	_p->bounces = 0;					\
	VectorCopy(_color, _p->color);


void QMB_AllocParticles (void)
{
	extern cvar_t r_particle_count;

	r_numparticles = bound(ABSOLUTE_MIN_PARTICLES, r_particle_count.value, ABSOLUTE_MAX_PARTICLES);

	//if (particles)
	//	Con_Printf("QMB_AllocParticles: internal error >particles<\n");

    if (r_numparticles < 1) {
        Con_Printf("QMB_AllocParticles: internal error >num particles<\n");
    }

	// can't alloc on Hunk, using native memory
	particles = (particle_t *) malloc (r_numparticles * sizeof(particle_t));
}

extern int loading_num_step;
extern int loading_cur_step;
char loading_name[32];

void QMB_InitParticles (void)
{
	int	i, j, ti, count = 0;
	gltexture_t *glpic;
    float	max_s, max_t; //For ADD_PARTICLE_TEXTURE

	particle_mode = pm_classic;

	Cvar_RegisterVariable (&r_bounceparticles);
	Cvar_RegisterVariable (&r_flametype);
	Cvar_RegisterVariable (&r_decal_blood);
	Cvar_RegisterVariable (&r_decal_bullets);
	Cvar_RegisterVariable (&r_decal_sparks);
	Cvar_RegisterVariable (&r_decal_explosions);
	Cvar_RegisterVariable (&r_particle_count);
	Cvar_RegisterVariable (&r_decaltime);

	loading_num_step = loading_num_step + 24;

	loading_cur_step++;
	strcpy(loading_name, "Particles");
	SCR_UpdateScreen ();

	if (!(glpic = loadtextureimage("textures/particles/particlefont")))
	{
		Clear_LoadingFill ();
		Sys_Error("Cannot load textures/particles/particlefont\n");
		return;
	}

	max_s = max_t = 256.0;
	ADD_PARTICLE_TEXTURE(ptex_none, 0, 0, 1, 0, 0, 0, 0);
	ADD_PARTICLE_TEXTURE(ptex_blood1, glpic, 0, 1, 0, 0, 64, 64);
	ADD_PARTICLE_TEXTURE(ptex_blood2, glpic, 0, 1, 64, 0, 128, 64);
	ADD_PARTICLE_TEXTURE(ptex_lava, glpic, 0, 1, 128, 0, 192, 64);
	ADD_PARTICLE_TEXTURE(ptex_blueflare, glpic, 0, 1, 192, 0, 256, 64);
	ADD_PARTICLE_TEXTURE(ptex_generic, glpic, 0, 1, 0, 96, 96, 192);
	//ADD_PARTICLE_TEXTURE(ptex_smoke, glpic, 0, 1, 96, 96, 192, 192);
	ADD_PARTICLE_TEXTURE(ptex_blood3, glpic, 0, 1, 192, 96, 256, 160);
	ADD_PARTICLE_TEXTURE(ptex_bubble, glpic, 0, 1, 192, 160, 224, 192);

	for (i=0 ; i<8 ; i++)
		ADD_PARTICLE_TEXTURE(ptex_dpsmoke, glpic, i, 8, i * 32, 64, (i + 1) * 32, 96);

	if (!(glpic = loadtextureimage("textures/particles/smoke")))
	{
		Clear_LoadingFill ();
		Sys_Error("Cannot load textures/particles/smoke\n");
		return;
	}

	ADD_PARTICLE_TEXTURE(ptex_smoke, glpic, 0, 1, 96, 96, 192, 192);


	loading_cur_step++;
	SCR_UpdateScreen ();

	// load the rest of the images
	if(!(glpic = loadtextureimage("textures/particles/q3particlefont")))
	{
		Clear_LoadingFill ();
		Sys_Error("Cannot load textures/particles/q3particlefont\n");
		return;
	}
	
	max_s = 384.0; max_t = 192.0;
	for (i = 0, ti = 0 ; i < 2 ; i++)
		for (j = 0 ; j < 4 ; j++, ti++)
			ADD_PARTICLE_TEXTURE(ptex_q3explosion, glpic, ti, 8, j * 64, i * 64, (j + 1) * 64, (i + 1) * 64);
		
	
	loading_cur_step++;
	SCR_UpdateScreen ();

	for (i = 0 ; i < 5 ; i++)
		ADD_PARTICLE_TEXTURE(ptex_q3blood, glpic, i, 5, i * 64, 128, (i + 1) * 64, 192);
		ADD_PARTICLE_TEXTURE(ptex_q3smoke, glpic, 0, 1, 256, 0, 384, 128);
		ADD_PARTICLE_TEXTURE(ptex_q3blood_trail, glpic, 0, 1, 320, 128, 384, 192);
	
	loading_cur_step++;
	SCR_UpdateScreen ();
	
	max_s = max_t = 128.0;

	if (!(glpic = loadtextureimage("textures/particles/flame")))
	{
		Clear_LoadingFill ();
		Sys_Error("Cannot load textures/particles/flame\n");
		return;
	}
	
	max_s = max_t = 64.0;
	ADD_PARTICLE_TEXTURE(ptex_q3flame, glpic, 0, 1, 0, 0, 64, 64);
    loading_cur_step++;
	SCR_UpdateScreen ();

	if (!(glpic = loadtextureimage("textures/particles/inferno")))
	{
		Clear_LoadingFill ();
		Sys_Error("Cannot load textures/particles/inferno\n");
		return;
	}
    max_s = max_t = 256.0;
	ADD_PARTICLE_TEXTURE(ptex_flame, glpic, 0, 1, 0, 0, 256, 256);

	loading_cur_step++;
	SCR_UpdateScreen ();

	if (!(glpic = loadtextureimage("textures/particles/zing1")))
	{
        Clear_LoadingFill ();
       	Sys_Error("Cannot load textures/particles/zing1\n");
		return;
	}

	max_s = 256.0; max_t = 128.0;
	ADD_PARTICLE_TEXTURE(ptex_lightning, glpic, 0, 1, 0, 0, 256, 128);//R00k changed

    loading_cur_step++;
	SCR_UpdateScreen ();
	max_s = max_t = 128.0;
	
	if (!(glpic = loadtextureimage("textures/mzfl/mzfl0")))
	{
		Clear_LoadingFill ();
		Sys_Error("Cannot load textures/particles/mzfl0\n");
		return;
	}

	//max_s = max_t = 256.0;
	ADD_PARTICLE_TEXTURE(ptex_muzzleflash, glpic, 0, 1, 0, 0, 128, 128);

	loading_cur_step++;
	SCR_UpdateScreen ();

	if (!(glpic = loadtextureimage("textures/mzfl/mzfl1")))
	{
		Clear_LoadingFill ();
		Sys_Error("Cannot load textures/particles/mzfl1\n");
		return;
	}
	//max_s = max_t = 256.0;
	ADD_PARTICLE_TEXTURE(ptex_muzzleflash2, glpic, 0, 1, 0, 0, 128, 128);

    loading_cur_step++;	
	SCR_UpdateScreen ();
	if (!(glpic = loadtextureimage("textures/mzfl/mzfl2")))
	{
        Clear_LoadingFill ();
		Sys_Error("Cannot load textures/particles/mzfl2\n");
		return;
	}
	//max_s = max_t = 256.0;
	ADD_PARTICLE_TEXTURE(ptex_muzzleflash3, glpic, 0, 1, 0, 0, 128, 128);

    loading_cur_step++;
	SCR_UpdateScreen ();

	if (!(glpic = loadtextureimage("textures/mzfl/muzzleflash8")))
	{
		Clear_LoadingFill ();
		Sys_Error("Cannot load textures/particles/muzzleflash8\n");
		return;
	}
	//max_s = max_t = 256.0;
	ADD_PARTICLE_TEXTURE(ptex_muzzleflash8, glpic, 0, 1, 0, 0, 128, 128);

    loading_cur_step++;
	SCR_UpdateScreen ();
	
	max_s = max_t = 64.0;
	if (!(glpic = loadtextureimage("textures/particles/bloodcloud")))
	{
        Clear_LoadingFill ();
		Sys_Error("Cannot load textures/particles/bloodcloud\n");
		return;
	}
	//max_s = max_t = 256.0;
	ADD_PARTICLE_TEXTURE(ptex_bloodcloud, glpic, 0, 1, 0, 0, 64, 64);

	loading_cur_step++;
	SCR_UpdateScreen ();

	if (!(glpic = loadtextureimage("textures/particles/fly")))
	{
		Clear_LoadingFill ();
		Sys_Error("Cannot load textures/particles/fly\n");
		return;
	}
	max_s = max_t = 256.0;
	ADD_PARTICLE_TEXTURE(ptex_fly, glpic, 0, 1, 0, 0, 256, 256);

    loading_cur_step++;
	SCR_UpdateScreen ();

	QMB_AllocParticles ();

	ADD_PARTICLE_TYPE(p_spark, pd_spark, GL_SRC_ALPHA, GL_FIXED_ONLY, ptex_none, 255, -8, 0, pm_normal, 1.3);
	ADD_PARTICLE_TYPE(p_gunblast, pd_spark, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_none, 255, 0, 0, pm_normal, 1.3);
	ADD_PARTICLE_TYPE(p_sparkray, pd_sparkray, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_none,	255, -0, 0, pm_nophysics, 0);
	ADD_PARTICLE_TYPE(p_fire, pd_billboard, GL_SRC_ALPHA, GL_FIXED_ONLY, ptex_smoke, 204, 0, -2.95, pm_die, 0);

    loading_cur_step++;
	SCR_UpdateScreen ();

	ADD_PARTICLE_TYPE(p_fire2,	pd_billboard, GL_SRC_ALPHA, GL_FIXED_ONLY, ptex_smoke, 204, 0, -2.95, pm_die, 0);
	ADD_PARTICLE_TYPE(p_chunk, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_generic, 255, -16, 0, pm_bounce, 1.475);
	ADD_PARTICLE_TYPE(p_shockwave, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_generic, 255, 0, -4.85, pm_nophysics, 0);
	ADD_PARTICLE_TYPE(p_inferno_flame, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_generic,	153, 0, 0, pm_static, 0);

    loading_cur_step++;
	SCR_UpdateScreen ();

	ADD_PARTICLE_TYPE(p_inferno_trail, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_generic, 204, 0, 0, pm_die, 0);
	ADD_PARTICLE_TYPE(p_trailpart, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_generic, 230, 0, 0, pm_static, 0);
	ADD_PARTICLE_TYPE(p_smoke, pd_billboard, GL_SRC_ALPHA, GL_FIXED_ONLY, ptex_smoke, 140, 3, 0, pm_normal, 0);
	ADD_PARTICLE_TYPE(p_dpfire, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_dpsmoke, 144, 0, 0, pm_die, 0);

	loading_cur_step++;
	SCR_UpdateScreen ();

	ADD_PARTICLE_TYPE(p_dpsmoke, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_dpsmoke, 85, 3, 0, pm_die, 0);
	ADD_PARTICLE_TYPE(p_teleflare, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_blueflare, 255, 0, 0, pm_die, 0);
	ADD_PARTICLE_TYPE(p_flare, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_bubble, 255, 0, 0, pm_die, 0);
	ADD_PARTICLE_TYPE(p_fly, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_fly, 255, 0, 0, pm_die, 0);
	
	loading_cur_step++;
	SCR_UpdateScreen();
	
	ADD_PARTICLE_TYPE(p_dot, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_generic, 255, 0, 0, pm_static, 0);
	ADD_PARTICLE_TYPE(p_blood1, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_COLOR, ptex_blood1, 255, -20, 0, pm_die, 0);
	ADD_PARTICLE_TYPE(p_blood2, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_blood3, 255, -45, 0, pm_normal, 0.018);//disisgonnabethegibchunks
	ADD_PARTICLE_TYPE(p_blood3, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_blood3, 255, -30, 0, pm_normal, 0);
	
	loading_cur_step++;
	SCR_UpdateScreen();
	
	ADD_PARTICLE_TYPE(p_lavasplash, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_lava, 170, 0, 0, pm_nophysics, 0);
	ADD_PARTICLE_TYPE(p_bubble, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_bubble, 204, 8, 0, pm_float, 0);
	ADD_PARTICLE_TYPE(p_staticbubble, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_bubble, 204, 0, 0, pm_static, 0);
	ADD_PARTICLE_TYPE(p_flame, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_generic, 200, 10, 0, pm_die, 0);
	
	loading_cur_step++;
	SCR_UpdateScreen();
	
	ADD_PARTICLE_TYPE(p_lavatrail, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_dpsmoke, 255, 3, 0, pm_normal, 0);//R00k
	ADD_PARTICLE_TYPE(p_bubble2, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_bubble, 204, 1, 0, pm_float, 0);
	ADD_PARTICLE_TYPE(p_glow, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_generic, 204, 0, 0, pm_die, 0);
	ADD_PARTICLE_TYPE(p_alphatrail, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_generic, 100, 0, 0, pm_static, 0);
	
	loading_cur_step++;
	SCR_UpdateScreen();
	
	ADD_PARTICLE_TYPE(p_torch_flame, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_flame, 255, 12, 0, pm_die, 0);
	ADD_PARTICLE_TYPE(p_streak, pd_hide, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_none, 255, -64, 0, pm_streak, 1.5);
	ADD_PARTICLE_TYPE(p_streakwave, pd_hide, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_none, 255, 0, 0, pm_streakwave, 0);
	ADD_PARTICLE_TYPE(p_streaktrail, pd_beam, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_none, 255, 0, 0, pm_die, 0);
	
	loading_cur_step++;
	SCR_UpdateScreen();
	
	ADD_PARTICLE_TYPE(p_lightningbeam, pd_beam, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_lightning, 255, 0, 0, pm_die, 0);
	ADD_PARTICLE_TYPE(p_muzzleflash, pd_billboard, GL_SRC_ALPHA, GL_FIXED_ONLY, ptex_muzzleflash, 255, 0, 0, pm_static, 0);
	ADD_PARTICLE_TYPE(p_muzzleflash2, pd_billboard, GL_SRC_ALPHA, GL_FIXED_ONLY, ptex_muzzleflash2, 255, 0, 0, pm_static, 0);
	ADD_PARTICLE_TYPE(p_muzzleflash3, pd_billboard, GL_SRC_ALPHA, GL_FIXED_ONLY, ptex_muzzleflash3, 255, 0, 0, pm_static, 0);
	ADD_PARTICLE_TYPE(p_muzzleflash8, pd_billboard, GL_SRC_ALPHA, GL_FIXED_ONLY, ptex_muzzleflash8, 220, 0, 0, pm_static, 0);
	ADD_PARTICLE_TYPE(p_rain, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_generic, 255, -16, 0, pm_rain, 0);
	
	loading_cur_step++;
	SCR_UpdateScreen();
	
	//shpuldeditedthis(GI_ONE_MINUS_DST_ALPHA->GL_ONE_MINUS_SRC_ALPHA) (edited one right after this comment)
	ADD_PARTICLE_TYPE(p_bloodcloud, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_bloodcloud, 255, -2, 0, pm_normal, 0);
	ADD_PARTICLE_TYPE(p_q3blood, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_q3blood, 255, 0, 0, pm_static, -1);
	ADD_PARTICLE_TYPE(p_q3blood_trail, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_q3blood_trail, 255, -1.5, 0, pm_die, -1);
	ADD_PARTICLE_TYPE(p_q3rocketsmoke, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_q3smoke, 80, 0, 0, pm_die, 0);
	
	loading_cur_step++;
	SCR_UpdateScreen();
	
	ADD_PARTICLE_TYPE(p_q3grenadesmoke, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, ptex_q3smoke, 80, 0, 0, pm_die, 0);
	ADD_PARTICLE_TYPE(p_q3explosion, pd_billboard, GL_SRC_ALPHA, GL_ONE_MINUS_DST_ALPHA, ptex_q3explosion, 204, 0, 0, pm_static, -1);
	//old: ADD_PARTICLE_TYPE(p_q3flame, pd_q3flame, GL_SRC_ALPHA, GU_ONE_MINUS_DST_ALPHA, ptex_q3flame, 204, 0, 0, pm_static, -1);
	ADD_PARTICLE_TYPE(p_q3flame, pd_billboard, GL_SRC_ALPHA, GL_FIXED_ONLY, ptex_q3flame, 180, 0.66, 0, pm_nophysics, 0);
	ADD_PARTICLE_TYPE(p_q3gunshot, pd_q3gunshot, GL_SRC_ALPHA, GL_ONE_MINUS_DST_ALPHA, ptex_none, 255, 0, 0, pm_static, -1);
	ADD_PARTICLE_TYPE(p_q3teleport, pd_q3teleport, GL_SRC_ALPHA, GL_ONE_MINUS_DST_ALPHA, ptex_none, 255, 0, 0, pm_static, -1);

	loading_cur_step++;
	strcpy(loading_name, "Standard particles");
	SCR_UpdateScreen ();

	Clear_LoadingFill ();

	qmb_initialized = true;

}

void AddParticle (part_type_t type, vec3_t org, int count, float size, double time, col_t col, vec3_t dir)
{
	byte			*color;
	int				i, j, k;
	float			tempSize; //stage;
	particle_t		*p;
	particle_type_t	*pt;
    static unsigned long q3blood_texindex = 0;

	if (!qmb_initialized)
		Sys_Error ("QMB particle added without initialization");

	//assert (size > 0 && time > 0);

	if (type < 0 || type >= num_particletypes)
		Sys_Error ("AddParticle: Invalid type (%d)", type);

	pt = &particle_types[particle_type_index[type]];

	for (i=0 ; i < count && free_particles ; i++)
	{
		color = col ? col : ColorForParticle (type);

		INIT_NEW_PARTICLE(pt, p, color, size, time);

		switch (type)
		{
		case p_spark:
			p->size = 1.175;
			VectorCopy (org, p->org);
			tempSize = size * 2;
			p->vel[0] = (rand() % (int)tempSize) - ((int)tempSize / 2);
			p->vel[1] = (rand() % (int)tempSize) - ((int)tempSize / 2);
			p->vel[2] = (rand() % (int)tempSize) - ((int)tempSize / 2);
			break;

		case p_smoke:
			for (j=0 ; j<3 ; j++)
				p->org[j] = org[j] + ((rand() & 31) - 16) / 2.0;
			for (j=0 ; j<3 ; j++)
				p->vel[j] = ((rand() % 10) - 5) / 20.0;
			p->growth = 4.5;
			break;

		case p_fire:
			VectorCopy (org, p->org);
			for (j=0 ; j<3 ; j++)
				p->vel[j] = (rand() & 159) - 80;
			p->org[0] = org[0] + ((rand() & 63) - 32);
			p->org[1] = org[1] + ((rand() & 63) - 32);
			p->org[2] = org[2] + ((rand() & 63) - 10);
			break;

		case p_fire2:
			VectorCopy (org, p->org);
			for (j=0 ; j<3 ; j++)
				p->vel[j] = (rand() & 199) - 100;
			p->org[0] = org[0] + ((rand() & 99) - 50);
			p->org[1] = org[1] + ((rand() & 99) - 50);
			p->org[2] = org[2] + ((rand() & 99) - 18);
			p->growth = 12;
			break;

		case p_bubble:
			p->start += (rand() & 15) / 36.0;
			p->org[0] = org[0] + ((rand() & 31) - 16);
			p->org[1] = org[1] + ((rand() & 31) - 16);
			p->org[2] = org[2] + ((rand() & 63) - 32);
			VectorClear (p->vel);
			break;

		case p_lavasplash:
		case p_streak:
		case p_streakwave:
		case p_shockwave:
		case p_q3teleport:
			VectorCopy (org, p->org);
			VectorCopy (dir, p->vel);
			break;

		case p_gunblast:
			p->size = 1;
			VectorCopy (org, p->org);
			p->vel[0] = (rand() & 159) - 80;
			p->vel[1] = (rand() & 159) - 80;
			p->vel[2] = (rand() & 159) - 80;
			break;

		case p_chunk:
			VectorCopy (org, p->org);
			p->vel[0] = (rand() % 40) - 20;
			p->vel[1] = (rand() % 40) - 20;
			p->vel[2] = (rand() % 40) - 5;
			break;

		case p_rain:
			VectorCopy(org, p->org);
			p->vel[0] = (rand() % 180) - 90;
			p->vel[1] = (rand() % 180) - 90;
			p->vel[2] = (rand() % -100 - 1200);
			break;

		case p_inferno_trail:
			for (j=0 ; j<3 ; j++)
				p->org[j] = org[j] + (rand() & 15) - 8;
			for (j=0 ; j<3 ; j++)
				p->vel[j] = (rand() & 3) - 2;
			p->growth = -1.5;
			break;

		case p_inferno_flame:
			VectorCopy (org, p->org);
			VectorClear (p->vel);
			p->growth = -30;
			break;

		case p_q3explosion:
				p->texindex = 0;
				VectorCopy (org, p->org);
				VectorClear (p->vel);
				p->growth = 50;
				for (j=1 ; j<8 ; j++)
				{
					INIT_NEW_PARTICLE(pt, p, color, size, time);
					p->size = size + j * 2;
					p->start = cl.time + (j * time / 2.0);
					p->die = p->start + time;
					p->texindex = j;
					VectorCopy (org, p->org);
					VectorClear (p->vel);
					p->growth = 50;
				}
				break;

		case p_sparkray:
			VectorCopy (org, p->endorg);
			VectorCopy (dir, p->org);
			for (j=0 ; j<3 ; j++)
				p->vel[j] = (rand() & 127) - 64;
			p->growth = -16;
			break;

		case p_bloodcloud: //shpuld
			VectorCopy (org, p->org);
			p->vel[0] = (rand() & 39) - 20;
			p->vel[1] = (rand() & 39) - 20;
			p->vel[2] = (rand() & 39) - 20;
			p->growth = 24;
			break;

		case p_staticbubble:
			VectorCopy (org, p->org);
			VectorClear (p->vel);
			break;

		case p_muzzleflash:
		case p_muzzleflash2:
		case p_muzzleflash3:
		case p_muzzleflash8:
			VectorCopy (org, p->org);
			p->rotspeed = (rand() & 45) - 90;
			//p->size = size * (rand() % 6) / 4;//r00k
			p->size = size * (0.85 +((0.05 * (rand() % 16)) * 0.35));//naievil: resultant size range: [size * 0.85, size * 1.1125)
			break;

		case p_teleflare:
		case p_flare:
		case p_fly:
			VectorCopy (org, p->org);
			VectorCopy (dir, p->vel);
			p->growth = 1.75;
			break;

		case p_blood1:
			p->size = size * (rand() % 2) + 0.50;//r00k
			for (j=0 ; j<3 ; j++)
				p->org[j] = org[j] + (rand() & 15) - 8;
			for (j=0 ; j<3 ; j++)
				p->vel[j] = (rand() & 63) - 32;
			break;
			
		case p_blood2: //shpuld
			VectorCopy (org, p->org);
			p->vel[0] = (rand() & 200) - 100;
			p->vel[1] = (rand() & 200) - 100;
			p->vel[2] = (rand() & 250) - 70;
			//p->growth = 24;
			break;

		case p_blood3:
			p->size = size * (rand() % 20) / 5.0;
			VectorCopy (org, p->org);
			for (j=0 ; j<3 ; j++)
				p->vel[j] = (rand() % 40) - 20;
			break;

		case p_q3blood:
			p->texindex = q3blood_texindex++ % 5;
			for (k=0 ; k<3 ; k++)
				p->org[k] = org[k] + (rand() & 15) - 8;
			VectorClear (p->vel);
			for (j=1 ; j<3 ; j++)
			{
				INIT_NEW_PARTICLE(pt, p, color, size, time);
				p->start = cl.time + (j * time);
				p->die = p->start + time;
				p->texindex = q3blood_texindex++ % 5;
				for (k=0 ; k<3 ; k++)
					p->org[k] = org[k] + (rand() & 15) - 8;
				VectorClear (p->vel);
			}
			break;

		case p_flame:
			VectorCopy (org, p->org);
			p->growth = -p->size / 2;
			VectorClear (p->vel);
			for (j=0 ; j<2 ; j++)
				p->vel[j] = (rand() % 6) - 3;
			break;

		case p_q3flame: //shpuld
			VectorCopy (org, p->org);
			p->vel[0] = (rand() & 3) - 2;
			p->vel[1] = (rand() & 3) - 2;
			p->vel[2] = (rand() & 2);
			p->growth = 6;
			break;

		case p_q3gunshot:
			p->texindex = 0;	// used for animation here
			VectorCopy (org, p->org);
			for (j=1 ; j<3 ; j++)
			{
				INIT_NEW_PARTICLE(pt, p, color, size, time);
				p->start = cl.time + (j * time / 2.0);
				p->die = p->start + time;
				p->texindex = j + 1;
				VectorCopy (org, p->org);
			}
			break;

		case p_torch_flame:
			for (j=0 ; j<3 ; j++)
				p->org[j] = org[j] + (rand() & 3) - 2;
			p->vel[0] = rand() % 15 - 8;
			p->vel[1] = rand() % 15 - 8;
			p->vel[2] = rand() % 15;
			p->rotspeed = (rand() & 31) + 32;
			break;

		case p_dot:
		case p_glow:
			VectorCopy (org, p->org);
			VectorCopy (dir, p->vel);
			p->growth = -1.5;
			break;

		case p_streaktrail:
		case p_lightningbeam:
			VectorCopy(org, p->org);
			VectorCopy(dir, p->endorg);
			VectorClear(p->vel);
			p->growth = -p->size/time;
			p->bounces = color[3];
			break;

		default:
			//assert (!"AddParticle: unexpected type");
			break;
		}
	}
}

int DecalClipPolygonAgainstPlane (plane_t *plane, int vertexCount, vec3_t *vertex, vec3_t *newVertex);

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
	qboolean negative[65];
	vec3_t	v1, v2;

	// Classify vertices
	for (a = 0 ; a < vertexCount ; a++)
	{
		qboolean neg = ((DotProduct(plane->normal, vertex[a]) - plane->dist) < 0.0);
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


qboolean DecalAddPolygon (decal_t *dec, int vertcount, vec3_t *vertices)
{
	int a, b, count, *triangle;

	count = dec->vertexCount;
	if (count + vertcount >= MAX_DECAL_VERTICES)
		return false;

	if (dec->triangleCount + vertcount - 2 >= MAX_DECAL_TRIANGLES)
		return false;

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
	return true;
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
			newVertex[i][0] = poly->verts[i][0];
			newVertex[i][1] = poly->verts[i][1];
			newVertex[i][2] = poly->verts[i][2];
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

void QMB_Blood_Splat(part_type_t type, vec3_t org) //Shpuldified
{
	int			j;
	col_t		color;
	vec3_t		neworg, angle;

	VectorClear (angle);

	color[0]=100;
	color[1]=0;
	color[2]=0;
	color[3]=255;

	if(type == p_blood1)
	{
		AddParticle(p_bloodcloud, org, 3, 5, 0.3, color, zerodir);
	}
	
	else if(type == p_blood2)
	{
		AddParticle(p_bloodcloud, org, 3, 7, 0.3, color, zerodir);
		color[0] = 40;
		AddParticle(p_blood2, org, 16, 3, 1.0, color, zerodir);
	}

	else //p_blood3, trail?
	{
		AddParticle(p_bloodcloud, org, 3, 5, 0.6, color, zerodir);
		for (j=0 ; j<4 ; j++)
		{
			AngleVectors (angle, NULLVEC, NULLVEC, neworg);
			VectorMA (org, 70, neworg, neworg);

			AddParticle (type, org, 5, 1, 2, color, neworg);
			angle[1] += 360 / 4;
		}
	}
}


void QMB_RunParticleEffect (vec3_t org, vec3_t dir, int col, int count)
{
	col_t	color;
	vec3_t	neworg, newdir;
	int		i, j, particlecount;
	int		contents;//R00k Added

	if (col == 73)
	{
		QMB_Blood_Splat(p_blood1, org);
		return;
	}
	else if (col == 225)
	{
		QMB_Blood_Splat(p_blood2, org);
		return;
	}
	else if (col == 20 && count == 30)
	{
		color[0] = color[2] = 51;
		color[1] = 255;
		AddParticle (p_chunk, org, 1, 1, 0.75, color, zerodir);
		AddParticle (p_spark, org, 12, 75, 0.4, color, zerodir);
		return;
	}
	else if (col == 226 && count == 20)
	{
		color[0] = 230;
		color[1] = 204;
		color[2] = 26;
		AddParticle (p_chunk, org, 1, 1, 0.75, color, zerodir);
		AddParticle (p_spark, org, 12, 75, 0.4, color, zerodir);
		return;
	}
	else if(col == 111) //we will use this color for flames
	{
		color[0] = color[1] = color[2] = 255;
		AddParticle (p_q3flame, org, 3, 3, 2, color, dir);
		return;
	}
	else if(col == 112) //we will use this color for big flames
	{
		color[0] = color[1] = color[2] = 255;
		AddParticle (p_q3flame, org, 3, 6, 2, color, dir);
		return;
	}

	switch (count)
	{
	case 9:
	case 10://nailgun
		{
			color[0] = 200;	color[1] = 200;	color[2] = 125;

			if (r_part_spikes.value == 2)
				AddParticle (p_q3gunshot, org, 1, 1, 0.3, NULL, zerodir);
			else
				AddParticle (p_spark, org, 6, 70, 0.6, NULL, zerodir);

			AddParticle (p_chunk, org, 3, 1, 0.75, NULL, zerodir);

			contents = TruePointContents (org);//R00k Added

			if (ISUNDERWATER(contents))//R00k
			{
				AddParticle (p_bubble, org, 1, 2, 0.825f + ((rand() % 10) - 5) / 40.0, NULL, zerodir);
			}
			else

			{
				// type, origin, count, size, time, color, dir
				AddParticle (p_smoke, org, 1, 4, 0.825f + ((rand() % 10) - 5) / 40.0, NULL, zerodir);
			}
		}
		break;

	case 20://super nailgun
		color[0] = 200;	color[1] = 200;	color[2] = 125;

		if (r_part_spikes.value == 2)
			AddParticle (p_q3gunshot, org, 1, 1, 0.3, NULL, zerodir);
		else
		    //AddParticle (p_spark, org, 2, 85, 0.4, color, zerodir);
            AddParticle (p_spark, org, 22, 100, 0.2, NULL, zerodir);

		//AddParticle (p_chunk, org, 6, 2, 0.75, NULL, zerodir);

		contents = TruePointContents (org);//R00k Added

		if (ISUNDERWATER(contents))//R00k
		{
			AddParticle (p_bubble, org, 1, 2, 0.825f + ((rand() % 10) - 5) / 40.0, NULL, zerodir);
		}
		else
		{
			AddParticle (p_smoke, org, 3, 12, 1.225 + ((rand() % 10) - 5) / 40.0, NULL, zerodir);
		}
		break;

	case 24:// gunshot
      if (r_part_gunshots.value == 2)
	  {
		AddParticle (p_q3gunshot, org, 1, 1, 0.3, NULL, zerodir);
	  }
	  else
	  {
		particlecount = count >> 1;
		AddParticle (p_gunblast, org, 1, 1.04, 0.2, NULL, zerodir);
		for (i=0 ; i<particlecount ; i++)
		{
        	for (j=0 ; j<3 ; j++)
				neworg[j] = org[j] + ((rand() & 3) - 2);
			contents = TruePointContents (neworg);//R00k Added

			if (ISUNDERWATER(contents))//R00k
			{
				AddParticle (p_bubble, neworg, 1, 2, 0.825f + ((rand() % 10) - 5) / 40.0, NULL, zerodir);
			}
			else

			{
				AddParticle (p_smoke, neworg, 1, 6, 0.825f + ((rand() % 10) - 5) / 40.0, NULL, zerodir);
			}

			if ((i % particlecount) == 0)
			{
				AddParticle (p_chunk, neworg, 1, 0.75, 3.75, NULL, zerodir);
			}

		}
	  }
		break;

	case 30:
		if (r_part_spikes.value == 2)
		{
			AddParticle (p_q3gunshot, org, 1, 1, 0.3, NULL, zerodir);
		}
		else
		{
			AddParticle (p_chunk, org, 10, 1, 4, NULL, zerodir);
			AddParticle (p_spark, org, 8, 105, 0.9, NULL, zerodir);
		}
		break;

	case 128:	// electric sparks (R00k added from QMB)
		color[2] = 1.0f;
		for (i=0; i<count; i++)
		{
			color[0] = color[1] = 0.4 + ((rand()%90)/255.0);
			AddParticle (p_spark, org, 1, 100, 1.0f,  color, zerodir);//modified
		}
		break;

	default:

		particlecount = fmax(1, count>>1);
		for (i=0 ; i<particlecount ; i++)
		{
			for (j=0 ; j<3 ; j++)
			{
				neworg[j] = org[j] + ((rand() % 20) - 10);
				newdir[j] = dir[j] * (10 + (rand() % 5));
			}
			d8to24col (color, (col & ~7) + (rand() & 7));
			AddParticle (p_glow, neworg, 1, 3, 0.2 + 0.1 * (rand() % 4), color, newdir);
		}
		break;
	}
}


void QMB_ClearParticles (void)
{
	int	i;

	if (!qmb_initialized)
		return;

	free (particles);		// free
	QMB_AllocParticles ();	// and alloc again
	particle_count = 0;
	memset (particles, 0, r_numparticles * sizeof(particle_t));
	free_particles = &particles[0];

	for (i=0 ; i+1 < r_numparticles ; i++)
		particles[i].next = &particles[i + 1];
	particles[r_numparticles-1].next = NULL;

	for (i=0 ; i < num_particletypes ; i++)
		particle_types[i].start = NULL;
}

qboolean OnChange_gl_particle_count (cvar_t *var, char *string)
{
	float	f;

	f = bound(ABSOLUTE_MIN_PARTICLES, (atoi(string)), ABSOLUTE_MAX_PARTICLES);
	Cvar_SetValue("r_particle_count", f);

	QMB_ClearParticles ();		// also re-allocc particles

	return true;
}

extern	cvar_t	sv_gravity;

inline static void QMB_UpdateParticles(void)
{
	int		i, c;
	float	grav, bounce, distance[3];
	double  frametime;
	vec3_t	oldorg, stop, normal;
	particle_type_t	*pt;
	particle_t	*p, *kill;

	if (!qmb_initialized)
		return;

	particle_count = 0;
	frametime = fabs(cl.time - cl.oldtime);
	grav = sv_gravity.value / 800.0;

	for (i=0 ; i<num_particletypes ; i++)
	{
		pt = &particle_types[i];

		if (pt->start)
		{
			p = pt->start;
			while (p && p->next)
			{
				kill = p->next;
				if (kill->die <= particle_time)
				{
					p->next = kill->next;
					kill->next = free_particles;
					free_particles = kill;
				}
				else
				{
					p = p->next;
				}
			}
			if (pt->start->die <= particle_time)
			{
				kill = pt->start;
				pt->start = kill->next;
				kill->next = free_particles;
				free_particles = kill;
			}
		}

		for (p = pt->start ; (p); p = p->next)
		{
			if (particle_time < p->start)
				continue;

			particle_count++;

			p->size += p->growth * frametime;

			if (p->size <= 0)
			{
				p->die = 0;
				continue;
			}
			VectorCopy (p->org, oldorg);
			VectorSubtract(r_refdef.vieworg,oldorg, distance);
			if (VectorLengthf(distance) >= gl_farclip.value) {
				p->die = 0;
			}

			switch (pt->id)
			{

			case p_q3blood:	// avoid alpha for q3blood
				p->color[3] = 255;
				break;

			case p_q3explosion:
			case p_q3gunshot:
				if (particle_time < (p->start + (p->die - p->start) / 2.0))
				{
					if (pt->id == p_q3gunshot && !p->texindex)
						p->color[3] = 255;
					else
						p->color[3] = pt->startalpha * ((particle_time - p->start) / (p->die - p->start) * 2);
				}
				else
				{
					p->color[3] = pt->startalpha * ((p->die - particle_time) / (p->die - p->start) * 2);
				}
				break;
			case p_streaktrail://R00k
			case p_lightningbeam:
					p->color[3] = p->bounces * ((p->die - particle_time) / (p->die - p->start));
					break;
			
			//shpuld
			case p_q3flame:
				p->color[3] = pt->startalpha * ((p->die - particle_time) / (p->die - p->start));
				p->color[0] = p->color[1] = p->color[2] = pt->startalpha * ((p->die - particle_time) / (p->die - p->start));
				break;

			default:
					p->color[3] = pt->startalpha * ((p->die - particle_time) / (p->die - p->start));
					break;
			}

			p->rotangle += p->rotspeed * frametime;

			if (p->hit)
				continue;

			p->vel[2] += pt->grav * grav * frametime;

			VectorScale (p->vel, 1 + pt->accel * frametime, p->vel);

			switch (pt->move)
			{
			case pm_static:
				break;

			case pm_normal:
				VectorCopy (p->org, oldorg);
				VectorMA (p->org, frametime, p->vel, p->org);

				if (CONTENTS_SOLID == TruePointContents(p->org))
				{
					p->hit = 1;

					if ((pt->id == p_blood3)&&(r_decal_blood.value) && (decals_enabled) && (particle_mode))
					{
						TraceLineN(oldorg, p->org, stop, normal);

						if ((stop != p->org)&&(VectorLengthf(stop)!=0))
						{
							vec3_t tangent;
							VectorCopy(stop, p->org);
							VectorCopy(normal, p->vel);
							CrossProduct(normal,p->vel,tangent);
							R_SpawnDecal(p->org, normal, tangent, decal_blood3, 12, 0);
						}
						p->die = 0;
					}
					VectorCopy (oldorg, p->org);
					VectorClear (p->vel);
				}

			break;

			case pm_float:
				VectorMA (p->org, frametime, p->vel, p->org);
				p->org[2] += p->size + 1;
				if (!ISUNDERWATER(TruePointContents(p->org)))
					p->die = 0;
				p->org[2] -= p->size + 1;
				break;

			case pm_nophysics:
				VectorMA (p->org, frametime, p->vel, p->org);
				break;

			case pm_die:
				VectorCopy (p->org, oldorg);
				VectorMA (p->org, frametime, p->vel, p->org);

				if (CONTENTS_SOLID == TruePointContents(p->org))
				{
					if ((decals_enabled) && (particle_mode))
					{
						TraceLineN(oldorg, p->org, stop, normal);

						if ((stop != p->org)&&(VectorLengthf(stop)!=0))
						{
							vec3_t tangent;

							VectorCopy(stop, p->org);
							VectorCopy(normal, p->vel);
							CrossProduct(normal,p->vel,tangent);
/*
							if ((pt->id == p_blood1)&&(r_decal_blood.value))
							{
								R_SpawnDecal(p->org, normal, tangent, decal_blood1, 12, 0);
							}
							else
							{
								if ((pt->id == p_blood2)&&(r_decal_blood.value))
								{
									R_SpawnDecal(p->org, normal, tangent, decal_blood2, 12, 0);
								}
							}
*/
							if ((pt->id == p_fire || pt->id == p_dpfire) && r_decal_explosions.value)
							  R_SpawnDecal (p->org, normal, tangent, decal_burn, 32, 0);
						    else if (pt->id == p_blood1 && r_decal_blood.value)
							  R_SpawnDecal (p->org, normal, tangent, decal_blood1, 12, 0);
						    else if (pt->id == p_blood2 && r_decal_blood.value)
							  R_SpawnDecal (p->org, normal, tangent, decal_blood2, 12, 0);
						    else if (pt->id == p_q3blood_trail && r_decal_blood.value)
							  R_SpawnDecal (p->org, normal, tangent, decal_q3blood, 48, 0);

						}
					}
					VectorCopy (oldorg, p->org);
					VectorClear (p->vel);//R00k added Needed?
					p->die = 0;
				}

				break;

			case pm_bounce:
				if (!r_bounceparticles.value || p->bounces)
				{
					VectorMA(p->org, frametime, p->vel, p->org);
					if (CONTENTS_SOLID == TruePointContents(p->org))
					{
						p->die = 0;
					}
				}
				else
				{
					VectorCopy (p->org, oldorg);
					VectorMA (p->org, frametime, p->vel, p->org);

					if (CONTENTS_SOLID == TruePointContents(p->org))
					{
						if (TraceLineN(oldorg, p->org, stop, normal))
						{
							VectorCopy (stop, p->org);
							bounce = -pt->custom * DotProduct(p->vel, normal);
							VectorMA(p->vel, bounce, normal, p->vel);
							p->bounces++;
						}
					}

				}
				break;

			case pm_streak:
				VectorCopy(p->org, oldorg);
				VectorMA(p->org, frametime, p->vel, p->org);
				if (CONTENTS_SOLID == TruePointContents(p->org))
				{
					if (TraceLineN(oldorg, p->org, stop, normal))
					{
						VectorCopy(stop, p->org);
						bounce = -pt->custom * DotProduct(p->vel, normal);
						VectorMA(p->vel, bounce, normal, p->vel);
					}
				}

				AddParticle (p_streaktrail, oldorg, 1, p->size, 0.2, p->color, p->org);

				if (!VectorLengthf(p->vel))
					p->die = 0;
				break;

			case pm_rain:
				VectorCopy(p->org, oldorg);
				VectorMA(p->org, frametime, p->vel, p->org);

				VectorSubtract(r_refdef.vieworg,oldorg, distance);

				if (VectorLengthf(distance) < gl_farclip.value)
				{
					if ((rand()%10+1 > 6))
						AddParticle (p_streaktrail, oldorg, 1, ((rand() % 1) + 0.5), 0.2, p->color, p->org);

					c = TruePointContents(p->org);

					if ((CONTENTS_SOLID == c) || (ISUNDERWATER(c)))
					{
						VectorClear (p->vel);
						p->die = 0;
					}
				}
				break;

			case pm_streakwave:
				VectorCopy(p->org, oldorg);
				VectorMA(p->org, frametime, p->vel, p->org);
				AddParticle (p_streaktrail, oldorg, 1, p->size, 0.5, p->color, p->org);
				p->vel[0] = 19 * p->vel[0] / 20;
				p->vel[1] = 19 * p->vel[1] / 20;
				p->vel[2] = 19 * p->vel[2] / 20;
				break;

			default:
				//assert (!"QMB_UpdateParticles: unexpected pt->move");
				break;
			}
		}
	}
}

// naievil -- hacky particle drawing...NOT OPTIMIZED
void DRAW_PARTICLE_BILLBOARD(particle_texture_t *ptex, particle_t *p, vec3_t *coord) {

	float			scale;
	vec3_t			up, right, p_up, p_right, p_upright;
	GLubyte			color[4], *c;

	VectorScale (vup, 1.5, up);
	VectorScale (vright, 1.5, right);

	glEnable (GL_BLEND);
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glDepthMask (GL_FALSE);
	glBegin (GL_QUADS);

	scale = p->size;
	color[0] = p->color[0];
	color[1] = p->color[1];
	color[2] = p->color[2];
	color[3] = p->color[3];
	glColor4ubv(color);

	glTexCoord2f (0,0);
	glVertex3fv (p->org);

	glTexCoord2f (1,0);
	VectorMA (p->org, scale, up, p_up);
	glVertex3fv (p_up);

	glTexCoord2f (1,1);
	VectorMA (p_up, scale, right, p_upright);
	glVertex3fv (p_upright);

	glTexCoord2f (0,1);
	VectorMA (p->org, scale, right, p_right);
	glVertex3fv (p_right);

	glEnd ();


	glDepthMask (GL_TRUE);
	glDisable (GL_BLEND);
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
	glColor3f(1,1,1);
}

                          
	
    

void QMB_DrawParticles (void)
{
	int		j, i;
	vec3_t		up, right, billboard[4], velcoord[4], neworg;
	particle_t		*p;
	particle_type_t		*pt;
	particle_texture_t	*ptex;

	float	varray_vertex[16];
	vec3_t	distance;

	if (!qmb_initialized)
		return;

	particle_time = cl.time;

	if (!cl.paused) {
		QMB_UpdateParticles ();
	}

	VectorAdd (vup, vright, billboard[2]);
	VectorSubtract (vright, vup, billboard[3]);
	VectorNegate (billboard[2], billboard[0]);
	VectorNegate (billboard[3], billboard[1]);

	for (i = 0 ; i < num_particletypes ; i++)
	{
		pt = &particle_types[i];

		if (!pt->start)
			continue;

		//glBlendFunc(pt->SrcBlend, pt->DstBlend);

		switch (pt->drawtype)
		{/*
			case pd_hide:
				break;
			case pd_beam:
				ptex = &particle_textures[pt->texture];
				GL_Bind (ptex->texnum);
				for (p = pt->start ; p ; p = p->next)
				{
					if (particle_time < p->start || particle_time >= p->die)
						continue;

					VectorSubtract(r_refdef.vieworg, p->org, distance);
					if (VectorLengthf(distance) > gl_farclip.value)
						continue;
					// Allocate the vertices.
					struct vertex
					{
						float u, v;
						float x, y, z;
					};

					vertex* const out = static_cast<vertex*>(sceGuGetMemory(sizeof(vertex) * 4));

					sceGuColor(GU_RGBA(p->color[0], p->color[1], p->color[2], p->color[3]));
					R_CalcBeamVerts (varray_vertex, p->org, p->endorg, p->size / 3.0);

					out[0].u = 1;
					out[0].v = 0;

					out[0].x = varray_vertex[0];
					out[0].y = varray_vertex[1];
					out[0].z = varray_vertex[2];

					out[1].u = 1;
					out[1].v = 1;

					out[1].x = varray_vertex[4];
					out[1].y = varray_vertex[5];
					out[1].z = varray_vertex[6];

					out[2].u = 0;
					out[2].v = 1;

					out[2].x = varray_vertex[8];
					out[2].y = varray_vertex[9];
					out[2].z = varray_vertex[10];

					out[3].u = 0;
					out[3].v = 0;

					out[3].x = varray_vertex[12];
					out[3].y = varray_vertex[13];
					out[3].z = varray_vertex[14];

					sceGuDrawArray(GU_TRIANGLE_FAN,GU_TEXTURE_32BITF | GU_VERTEX_32BITF,4, 0, out);
					sceGuColor(GU_RGBA(0xff,0xff,0xff,0xff)); //return to normal color
				}
				break;
			case pd_spark:
				sceGuDisable (GU_TEXTURE_2D);
				for (p = pt->start ; p ; p = p->next)
				{
					if (particle_time < p->start || particle_time >= p->die)
						continue;

					VectorSubtract(r_refdef.vieworg, p->org, distance);
					if (VectorLengthf(distance) > gl_farclip.value)
						continue;

					struct vertex
					{
						vec3_t xyz;
					};

					vertex* const out = static_cast<vertex*>(sceGuGetMemory(sizeof(vertex) * 9));

					sceGuColor(GU_RGBA(p->color[0], p->color[1], p->color[2], p->color[3]));

					for (int gh=0 ; gh<3 ; gh++)
						out[0].xyz[gh] = p->org[gh];

					sceGuColor(GU_RGBA(p->color[0] >> 1, p->color[1] >> 1, p->color[2] >> 1, p->color[3] >> 1));

					int vt = 1;

					for (j=7; j>=0 ; j--)
					{

					  for (int k=0 ; k<3 ; k++)
						out[vt].xyz[k] = p->org[k] - p->vel[k] / 8 + vright[k] * cost[1%7] * p->size + vup[k] * sint[j%7] * p->size;
					  vt = vt + 1;
					}
				    sceGuDrawArray(GU_TRIANGLE_FAN, GU_VERTEX_32BITF, 9, 0, out);

					sceGuColor(GU_RGBA(0xff,0xff,0xff,0xff)); //return to normal color
				}
				sceGuEnable (GU_TEXTURE_2D);
				break;
			case pd_sparkray:
				sceGuDisable (GU_TEXTURE_2D);
				for (p = pt->start ; p ; p = p->next)
				{
					if (particle_time < p->start || particle_time >= p->die)
						continue;

					VectorSubtract(r_refdef.vieworg, p->org, distance);
					if (VectorLengthf(distance) > gl_farclip.value)
						continue;

					if (!TraceLineN(p->endorg, p->org, neworg, NULLVEC))
						VectorCopy(p->org, neworg);

					//R00k added -start-
					//sceGuEnable (GU_BLEND);
					//p->color[3] = bound(0, 0.3, 1) * 255;
					//R00k added -end-
					//glColor4ubv (p->color);

					struct vertex
		            {
					 vec3_t xyz;
		            };

		            vertex* const out = static_cast<vertex*>(sceGuGetMemory(sizeof(vertex) * 9));

				    sceGuColor(GU_RGBA(p->color[0], p->color[1], p->color[2], p->color[3]));

					for (int gh=0 ; gh<3 ; gh++)
					  out[0].xyz[gh] = p->endorg[gh];


					sceGuColor(GU_RGBA(p->color[0] >> 1, p->color[1] >> 1, p->color[2] >> 1, p->color[3] >> 1));

					int vt = 1;

					for (j=7 ; j>=0 ; j--)
					{
                      for (int k=0 ; k<3 ; k++)
						out[vt].xyz[k] = neworg[k] + vright[k] * cost[j%7] * p->size + vup[k] * sint[j%7] * p->size;

					  vt = vt + 1;
					}
					sceGuDrawArray(GU_TRIANGLE_FAN, GU_VERTEX_32BITF, 9, 0, out);

					sceGuColor(GU_RGBA(0xff,0xff,0xff,0xff)); //return to normal color

				}
				sceGuEnable (GU_TEXTURE_2D);
				break;
		*/
		case pd_billboard:
			ptex = &particle_textures[pt->texture];
			GL_Bind (ptex->gltexture);			

			for (p = pt->start ; p ; p = p->next)
			{
				if (particle_time < p->start || particle_time >= p->die) {
					continue;
				}

				for (j = 0 ; j < cl.maxclients ; j++)
				{
					if (pt->custom != -1 && VectorSupCompare(p->org, cl_entities[1+j].origin, 40))
					{
						p->die = 0;
						continue;
					}
				}
				
				DRAW_PARTICLE_BILLBOARD(ptex, p, billboard);

			}
			break;

		case pd_billboard_vel:
			ptex = &particle_textures[pt->texture];
			GL_Bind (ptex->gltexture);
			for (p = pt->start ; p ; p = p->next)
			{
				if (particle_time < p->start || particle_time >= p->die)
					continue;

				VectorCopy (p->vel, up);
				CrossProduct (vpn, up, right);
				VectorNormalizeFast (right);
				VectorScale (up, pt->custom, up);

				VectorAdd (up, right, velcoord[2]);
				VectorSubtract (right, up, velcoord[3]);
				VectorNegate (velcoord[2], velcoord[0]);
				VectorNegate (velcoord[3], velcoord[1]);
				DRAW_PARTICLE_BILLBOARD(ptex, p, velcoord);
			}
			break;
			/*
		case pd_q3flame:
			ptex = &particle_textures[pt->texture];
			GL_Bind (ptex->texnum);
			for (p = pt->start ; p ; p = p->next)
			{
				float	varray_vertex[16];
				float	xhalf = p->size / 2.0, yhalf = p->size;
			//	vec3_t	org, v, end, normal;

				if (particle_time < p->start || particle_time >= p->die)
					continue;

				sceGuDisable (GU_CULL_FACE);

				for (j=0 ; j<2 ; j++)
				{
					sceGumPushMatrix ();

					const ScePspFVector3 translation =
	                {
		            p->org[0], p->org[1], p->org[2]
	                };
	                sceGumTranslate(&translation);

					//glRotatef (!j ? 45 : -45, 0, 0, 1);

	                sceGumRotateZ(!j ? 45 : -45 * (GU_PI / 180.0f));

					sceGuColor(GU_RGBA(p->color[0], p->color[1], p->color[2], p->color[3]));

					sceGumUpdateMatrix();

			// sigh. The best would be if the flames were always orthogonal to their surfaces
			// but I'm afraid it's impossible to get that work (w/o progs modification of course)
					varray_vertex[0] = 0;
					varray_vertex[1] = xhalf;
					varray_vertex[2] = -yhalf;
					varray_vertex[4] = 0;
					varray_vertex[5] = xhalf;
					varray_vertex[6] = yhalf;
					varray_vertex[8] = 0;
					varray_vertex[9] = -xhalf;
					varray_vertex[10] = yhalf;
					varray_vertex[12] = 0;
					varray_vertex[13] = -xhalf;
					varray_vertex[14] = -yhalf;

                    struct vertex
		            {
                    float u, v;
					float x, y, z;
		            };

					vertex* const out = static_cast<vertex*>(sceGuGetMemory(sizeof(vertex) * 4));

					out[0].u = ptex->coords[p->texindex][0];
					out[0].v = ptex->coords[p->texindex][3];
					out[0].x = varray_vertex[0];
                    out[0].y = varray_vertex[1];
                    out[0].z = varray_vertex[2];


					out[1].u = ptex->coords[p->texindex][0];
					out[1].v = ptex->coords[p->texindex][1];
					out[1].x = varray_vertex[4];
                    out[1].y = varray_vertex[5];
                    out[1].z = varray_vertex[6];


					out[2].u = ptex->coords[p->texindex][2];
					out[2].v = ptex->coords[p->texindex][1];
					out[2].x = varray_vertex[8];
                    out[2].y = varray_vertex[9];
                    out[2].z = varray_vertex[10];


					out[3].u = ptex->coords[p->texindex][2];
					out[3].v = ptex->coords[p->texindex][3];
					out[3].x = varray_vertex[12];
                    out[3].y = varray_vertex[13];
                    out[3].z = varray_vertex[14];

					sceGuDrawArray(GU_TRIANGLE_FAN, GU_TEXTURE_32BITF | GU_VERTEX_32BITF, 4, 0, out);

					sceGumPopMatrix ();
					sceGumUpdateMatrix();
				}
				sceGuEnable (GU_CULL_FACE);
                sceGuColor(GU_RGBA(0xff,0xff,0xff,0xff)); //return to normal color
			}
			break;

		case pd_q3gunshot:
			for (p = pt->start ; p ; p = p->next)
				QMB_Q3Gunshot (p->org, (int)p->texindex, (float)p->color[3] / 255.0);
			break;

		case pd_q3teleport:
			for (p = pt->start ; p ; p = p->next)
				QMB_Q3Teleport (p->org, (float)p->color[3] / 255.0);
			break;
		*/
		default:
				//assert (!"QMB_DrawParticles: unexpected drawtype");
				break;
		}
	}

//	glDepthMask (GL_FALSE);
//	glDisable (GL_BLEND);
//	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
//	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
//	glShadeModel (GL_FLAT);

}

float pap_detr(int weapon)
{

	switch (weapon)
	{
		case W_COLT:
		case W_KAR:
		case W_THOMPSON:
		case W_357:
		case W_BAR:
		case W_BK:
		case W_BROWNING:
		case W_DB:
		case W_FG:
		case W_GEWEHR:
		case W_KAR_SCOPE:
		case W_M1:
		case W_M1A1:
		case W_MP40:
		case W_MG:
		case W_PANZER:
		case W_PPSH:
		case W_PTRS:
		case W_RAY:
		case W_SAWNOFF:
		case W_STG:
		case W_TRENCH:
		case W_TYPE:
		case W_M2:
		case W_MP5:
	    case W_TESLA:
	      	return 0;
	    case W_BIATCH:
		case W_COMPRESSOR:  	
	    case W_M1000:  	
	    case W_GIBS:
	    case W_SAMURAI:
	    case W_AFTERBURNER:
	    case W_SPATZ:
	    case W_SNUFF:
	    case W_BORE:
	    case W_IMPELLER:
	    case W_BARRACUDA:
	    case W_ACCELERATOR:
	    case W_GUT:
	    case W_REAPER:
	    case W_HEADCRACKER:
	    case W_LONGINUS:
	    case W_PENETRATOR:
	    case W_WIDOW:
	    case W_PORTER:
	    case W_ARMAGEDDON:
	    case W_WIDDER:
	    case W_KILLU:
			return 1;
		default:
			return 0;
	}
}

//R00k added particle muzzleflashes
void QMB_MuzzleFlash(vec3_t org)
{
	double	frametime = fabs(cl.time - cl.oldtime);
	col_t	color;

	if (pap_detr(cl.stats[STAT_ACTIVEWEAPON]) == 0) {
    	color[0] = color[1] = color[2] = 255;
	} else {
	  color[0] = 132;
	  color[1] = 44;
	  color[2] = 139;
	}

	if (!qmb_initialized) {
		return;
	}

	float size, timemod;

	timemod = 0.04;

	if(!(ISUNDERWATER(TruePointContents(org))))
	{
		size = sv_player->v.Flash_Size;

		if(size == 0 || cl.stats[STAT_ZOOM] == 2)
			return;

        switch(rand() % 3 + 1)
        {
            case 1:
                AddParticle (p_muzzleflash, org, 1, size, timemod * frametime, color, zerodir);
                break;
            case 2:
                AddParticle (p_muzzleflash2, org, 1, size, timemod * frametime, color, zerodir);
                break;
            case 3:
                AddParticle (p_muzzleflash3, org, 1, size, timemod * frametime, color, zerodir);
                break;
            default:
                AddParticle (p_muzzleflash, org, 1, size, timemod * frametime, color, zerodir);
                break;
        }
	}
}

/*

void R_GetParticleMode (void)
{
	if (!r_part_explosions.value && !r_part_trails.value && !r_part_spikes.value &&
	    !r_part_gunshots.value && !r_part_blood.value && !r_part_telesplash.value &&
	    !r_part_blobs.value && !r_part_lavasplash.value && !r_part_flames.value &&
	    !r_part_lightning.value)
		particle_mode = pm_classic;
	else if (r_part_explosions.value == 1 && r_part_trails.value == 1 && r_part_spikes.value == 1 &&
		r_part_gunshots.value == 1 && r_part_blood.value == 1 && r_part_telesplash.value == 1 &&
		r_part_blobs.value == 1 && r_part_lavasplash.value == 1 && r_part_flames.value == 1 &&
		r_part_lightning.value == 1)
		particle_mode = pm_qmb;
	else if (r_part_explosions.value == 2 && r_part_trails.value == 2 && r_part_spikes.value == 2 &&
		r_part_gunshots.value == 2 && r_part_blood.value == 2 && r_part_telesplash.value == 2 &&
		r_part_blobs.value == 2 && r_part_lavasplash.value == 2 && r_part_flames.value == 2 &&
		r_part_lightning.value == 2)
		particle_mode = pm_quake3;
	else
		particle_mode = pm_mixed;
}

void R_SetParticleMode (part_mode_t val)
{
	particle_mode = val;

	Cvar_SetValue ("r_part_explosions",  particle_mode);
	Cvar_SetValue ("r_part_trails",      particle_mode);
	Cvar_SetValue ("r_part_sparks",      particle_mode);
	Cvar_SetValue ("r_part_spikes",      particle_mode);
	Cvar_SetValue ("r_part_gunshots",    particle_mode);
	Cvar_SetValue ("r_part_blood",       particle_mode);
	Cvar_SetValue ("r_part_telesplash",  particle_mode);
	Cvar_SetValue ("r_part_blobs",       particle_mode);
	Cvar_SetValue ("r_part_lavasplash",  particle_mode);
	Cvar_SetValue ("r_part_flames",      particle_mode);
	Cvar_SetValue ("r_part_lightning",   particle_mode);
	Cvar_SetValue ("r_part_flies",       particle_mode);
    Cvar_SetValue ("r_part_muzzleflash", particle_mode);
}

char *R_NameForParticleMode (void)
{
	char *name;

	switch (particle_mode)
	{
	case pm_classic:
		name = "Classic";
		break;

	case pm_qmb:
		name = "QMB";
		break;

	case pm_quake3:
		name = "Quake3";
		break;

	case pm_mixed:
		name = "mixed";
		break;

	default:
		name = "derp";
		break;
	}

	return name;
}

*/

/*
===============
R_ToggleParticles_f

function that toggles between classic and QMB particles
===============
*/

/*
void R_ToggleParticles_f (void)
{
	if (cmd_source != src_command)
		return;

	if (particle_mode == pm_classic)
		R_SetParticleMode (pm_qmb);
	else if (particle_mode == pm_qmb)
		R_SetParticleMode (pm_quake3);
	else
		R_SetParticleMode (pm_classic);

	if (key_dest != key_menu && key_dest != key_menu_pause)
		Con_Printf ("Using %s particles\n", R_NameForParticleMode());
}
*/

void CheckDecals (void)
{
	if	(!r_decal_bullets.value && !r_decal_explosions.value && !r_decal_sparks.value && !r_decal_blood.value)
		decals_enabled = 0;
	else
		if	(r_decal_bullets.value && r_decal_explosions.value && r_decal_sparks.value && r_decal_blood.value)
		decals_enabled = 1;
		else
			decals_enabled = 2;
}

void R_SetDecals (int val)
{
	decals_enabled = val;
	Cvar_SetValue ("r_decal_bullets",    val);
	Cvar_SetValue ("r_decal_explosions", val);
	Cvar_SetValue ("r_decal_sparks",     val);
	Cvar_SetValue ("r_decal_blood",      val);
}


/*
===============
R_ToggleDecals_f
===============
*/

void R_ToggleDecals_f (void)
{
	if (cmd_source != src_command)
		return;
	CheckDecals ();
	R_SetDecals (!(decals_enabled));
	Con_Printf ("All Decals are %s.\n", !decals_enabled ? "disabled" : "enabled");
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