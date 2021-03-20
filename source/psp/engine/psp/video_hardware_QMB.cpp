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

extern "C"
{
#include "../quakedef.h"
//entity_t *CL_NewTempEntity (void);
}

#include <pspgu.h>
#include <pspgum.h>

//#define	DEFAULT_NUM_PARTICLES		8192
#define	ABSOLUTE_MIN_PARTICLES      64
#ifdef SLIM
#define	ABSOLUTE_MAX_PARTICLES		12288
#else
#define	ABSOLUTE_MAX_PARTICLES      6144
#endif
extern int decal_blood1, decal_blood2, decal_blood3, decal_q3blood, decal_burn, decal_mark, decal_glow;

typedef	byte	col_t[4];

typedef	enum
{
	p_spark,
	p_rayspark,
	p_raysmoke,
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

typedef struct particle_s
{
	struct	particle_s	*next;
	vec3_t				org, endorg;
	col_t				color;
	float				growth;
	vec3_t				vel;
	float				rotangle;
	float				rotspeed;
	float				size;
	float				start;
	float				die;
	byte				hit;
	byte				texindex;
	byte				bounces;
} particle_t;

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

#define	MAX_PTEX_COMPONENTS		8

typedef struct particle_texture_s
{
	int		texnum;
	int		components;
	float	coords[MAX_PTEX_COMPONENTS][4];
} particle_texture_t;

static	float	sint[7] = {0.000000, 0.781832, 0.974928, 0.433884, -0.433884, -0.974928, -0.781832};
static	float	cost[7] = {1.000000, 0.623490, -0.222521, -0.900969, -0.900969, -0.222521, 0.623490};

static			particle_t			*particles, *free_particles;
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
qboolean		qmb_initialized = qfalse;
int				particle_mode = 0;	// 0: classic (default), 1: QMB, 2: mixed

qboolean OnChange_gl_particle_count (cvar_t *var, char *string)
{
	float	f;

	f = bound(ABSOLUTE_MIN_PARTICLES, (atoi(string)), ABSOLUTE_MAX_PARTICLES);
	Cvar_SetValue("r_particle_count", f);

	QMB_ClearParticles ();		// also re-allocc particles

	return qtrue;
}

extern cvar_t	cl_gun_offset;
#ifdef SLIM
cvar_t	r_particle_count	= {"r_particle_count", "4096", qtrue};
#else
cvar_t	r_particle_count	= {"r_particle_count", "2048", qtrue};
#endif
cvar_t	r_bounceparticles	= {"r_bounceparticles", "1",qtrue};
cvar_t	r_decal_blood		= {"r_decal_blood", "1",qtrue};
cvar_t	r_decal_bullets	    = {"r_decal_bullets","1",qtrue};
cvar_t	r_decal_sparks		= {"r_decal_sparks","1",qtrue};
cvar_t	r_decal_explosions	= {"r_decal_explosions","1",qtrue};

int	decals_enabled;

void R_CalcBeamVerts (float *vert, vec3_t org1, vec3_t org2, float width);

extern	cvar_t	sv_gravity;

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


#define ADD_PARTICLE_TEXTURE(_ptex, _texnum, _texindex, _components, _s1, _t1, _s2, _t2)\
do {																	\
	particle_textures[_ptex].texnum = _texnum;							\
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

void QMB_AllocParticles (void)
{
	extern cvar_t r_particle_count;

	r_numparticles = bound(ABSOLUTE_MIN_PARTICLES, r_particle_count.value, ABSOLUTE_MAX_PARTICLES);

	//if (particles)
	//	Con_Printf("QMB_AllocParticles: internal error >particles<\n");

    if(r_numparticles < 1)
        Con_Printf("QMB_AllocParticles: internal error >num particles<\n");

	// can't alloc on Hunk, using native memory
	particles = (particle_t *) malloc (r_numparticles * sizeof(particle_t));
}

void QMB_InitParticles (void)
{
	int	i, j, ti, count = 0, particleimage;
    float	max_s, max_t; //For ADD_PARTICLE_TEXTURE

	particle_mode = pm_classic;

	Cvar_RegisterVariable (&r_bounceparticles);
	Cvar_RegisterVariable (&r_flametype);
	Cvar_RegisterVariable (&r_decal_blood);
	Cvar_RegisterVariable (&r_decal_bullets);
	Cvar_RegisterVariable (&r_decal_sparks);
	Cvar_RegisterVariable (&r_decal_explosions);
	Cvar_RegisterVariable (&r_particle_count);

	loading_num_step = loading_num_step + 24;
	
	if (!(particleimage = loadtextureimage("textures/particles/particlefont", 0, 0, qfalse, GU_LINEAR)))
	{
		Clear_LoadingFill ();
		return;
	}

	loading_cur_step++;
	strcpy(loading_name, "Particles");
	SCR_UpdateScreen ();

	max_s = max_t = 256.0;
	ADD_PARTICLE_TEXTURE(ptex_none, 0, 0, 1, 0, 0, 0, 0);
	ADD_PARTICLE_TEXTURE(ptex_blood1, particleimage, 0, 1, 0, 0, 64, 64);
	ADD_PARTICLE_TEXTURE(ptex_blood2, particleimage, 0, 1, 64, 0, 128, 64);
	ADD_PARTICLE_TEXTURE(ptex_lava, particleimage, 0, 1, 128, 0, 192, 64);
	ADD_PARTICLE_TEXTURE(ptex_blueflare, particleimage, 0, 1, 192, 0, 256, 64);
	ADD_PARTICLE_TEXTURE(ptex_generic, particleimage, 0, 1, 0, 96, 96, 192);
	ADD_PARTICLE_TEXTURE(ptex_smoke, particleimage, 0, 1, 96, 96, 192, 192);
	ADD_PARTICLE_TEXTURE(ptex_blood3, particleimage, 0, 1, 192, 96, 256, 160);
	ADD_PARTICLE_TEXTURE(ptex_bubble, particleimage, 0, 1, 192, 160, 224, 192);
	
	for (i=0 ; i<8 ; i++)
		ADD_PARTICLE_TEXTURE(ptex_dpsmoke, particleimage, i, 8, i * 32, 64, (i + 1) * 32, 96);

	loading_cur_step++;
	SCR_UpdateScreen ();

	// load the rest of the images
	if(!(particleimage = loadtextureimage("textures/particles/q3particlefont", 0, 0, qfalse, GU_LINEAR)))
	{
		Clear_LoadingFill ();
		return;
	}
	
	max_s = 384.0; max_t = 192.0;
	for (i = 0, ti = 0 ; i < 2 ; i++)
		for (j = 0 ; j < 4 ; j++, ti++)
			ADD_PARTICLE_TEXTURE(ptex_q3explosion, particleimage, ti, 8, j * 64, i * 64, (j + 1) * 64, (i + 1) * 64);
		
	
	loading_cur_step++;
	SCR_UpdateScreen ();

	for (i = 0 ; i < 5 ; i++)
		ADD_PARTICLE_TEXTURE(ptex_q3blood, particleimage, i, 5, i * 64, 128, (i + 1) * 64, 192);
		ADD_PARTICLE_TEXTURE(ptex_q3smoke, particleimage, 0, 1, 256, 0, 384, 128);
		ADD_PARTICLE_TEXTURE(ptex_q3blood_trail, particleimage, 0, 1, 320, 128, 384, 192);
	
	loading_cur_step++;
	SCR_UpdateScreen ();
	
	max_s = max_t = 128.0;

	if (!(particleimage = loadtextureimage("textures/particles/flame", 0, 0, qfalse, GU_LINEAR)))
	{
		Clear_LoadingFill ();
		return;
	}
	
	/*max_s = max_t = 128.0;
	for (i = 0, ti = 0 ; i < 2 ; i++)
		for (j = 0 ; j < 2 ; j++, ti++)
			ADD_PARTICLE_TEXTURE(ptex_q3flame, particleimage, ti, 8, j * 64, i * 64, (j + 1) * 64, (i + 1) * 64);*/
	max_s = max_t = 64.0;
	ADD_PARTICLE_TEXTURE(ptex_q3flame, particleimage, 0, 1, 0, 0, 64, 64);
    loading_cur_step++;
	SCR_UpdateScreen ();

	if (!(particleimage = loadtextureimage("textures/particles/inferno", 0, 0, qfalse, GU_LINEAR)))
	{
		Clear_LoadingFill ();
		return;
	}
    max_s = max_t = 256.0;
	ADD_PARTICLE_TEXTURE(ptex_flame, particleimage, 0, 1, 0, 0, 256, 256);

	loading_cur_step++;
	SCR_UpdateScreen ();

	if (!(particleimage = loadtextureimage("textures/particles/zing1", 0, 0, qfalse, GU_LINEAR)))
	{
        Clear_LoadingFill ();
		return;
	}

	max_s = 256.0; max_t = 128.0;
	ADD_PARTICLE_TEXTURE(ptex_lightning, particleimage, 0, 1, 0, 0, 256, 128);//R00k changed

    loading_cur_step++;
	SCR_UpdateScreen ();
	max_s = max_t = 128.0;
	
	if (!(particleimage = loadtextureimage("textures/mzfl/mzfl0", 0, 0, qfalse, GU_LINEAR)))
	{
		Clear_LoadingFill ();
		return;
	}
	//max_s = max_t = 256.0;
	ADD_PARTICLE_TEXTURE(ptex_muzzleflash, particleimage, 0, 1, 0, 0, 128, 128);

	loading_cur_step++;
	SCR_UpdateScreen ();

	if (!(particleimage = loadtextureimage("textures/mzfl/mzfl1", 0, 0, qfalse, GU_LINEAR)))
	{
		Clear_LoadingFill ();
		return;
	}
	//max_s = max_t = 256.0;
	ADD_PARTICLE_TEXTURE(ptex_muzzleflash2, particleimage, 0, 1, 0, 0, 128, 128);

    loading_cur_step++;	
	SCR_UpdateScreen ();
	if (!(particleimage = loadtextureimage("textures/mzfl/mzfl2", 0, 0, qfalse, GU_LINEAR)))
	{
        Clear_LoadingFill ();
		return;
	}
	//max_s = max_t = 256.0;
	ADD_PARTICLE_TEXTURE(ptex_muzzleflash3, particleimage, 0, 1, 0, 0, 128, 128);

    loading_cur_step++;
	SCR_UpdateScreen ();

	if (!(particleimage = loadtextureimage("textures/mzfl/muzzleflash8", 0, 0, qfalse, GU_LINEAR)))
	{
		Clear_LoadingFill ();
		return;
	}
	//max_s = max_t = 256.0;
	ADD_PARTICLE_TEXTURE(ptex_muzzleflash8, particleimage, 0, 1, 0, 0, 128, 128);

    loading_cur_step++;
	SCR_UpdateScreen ();
	
	max_s = max_t = 64.0;
	if (!(particleimage = loadtextureimage("textures/particles/bloodcloud", 0, 0, qfalse, GU_LINEAR)))
	{
        Clear_LoadingFill ();
		return;
	}
	//max_s = max_t = 256.0;
	ADD_PARTICLE_TEXTURE(ptex_bloodcloud, particleimage, 0, 1, 0, 0, 64, 64);

	loading_cur_step++;
	SCR_UpdateScreen ();
/*
	if (!(particleimage = loadtextureimage("textures/particles/blood1", 0, 0, qfalse, GU_LINEAR)))
	{
        Clear_LoadingFill ();
		return;
	}

    max_s = max_t = 256.0;
	ADD_PARTICLE_TEXTURE(ptex_blood1, particleimage, 0, 1, 0, 0, 256, 256);

    loading_cur_step++;
	SCR_UpdateScreen ();

	if (!(particleimage = loadtextureimage("textures/particles/blood2", 0, 0, qfalse, GU_LINEAR)))
	{
        Clear_LoadingFill ();
		return;
	}
    max_s = max_t = 256.0;
	ADD_PARTICLE_TEXTURE(ptex_blood2, particleimage, 0, 1, 0, 0, 256, 256);

    loading_cur_step++;
	SCR_UpdateScreen ();

*/
	if (!(particleimage = loadtextureimage("textures/particles/fly", 0, 0, qfalse, GU_LINEAR)))
	{
		Clear_LoadingFill ();
		return;
	}
	max_s = max_t = 256.0;
	ADD_PARTICLE_TEXTURE(ptex_fly, particleimage, 0, 1, 0, 0, 256, 256);

    loading_cur_step++;
	SCR_UpdateScreen ();

	QMB_AllocParticles ();

	ADD_PARTICLE_TYPE(p_spark, pd_spark, GU_SRC_ALPHA, GU_FIX, ptex_none, 255, -8, 0, pm_normal, 1.3);
	ADD_PARTICLE_TYPE(p_gunblast, pd_spark, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_none, 255, 0, 0, pm_normal, 1.3);
	ADD_PARTICLE_TYPE(p_sparkray, pd_sparkray, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_none,	255, -0, 0, pm_nophysics, 0);
	ADD_PARTICLE_TYPE(p_fire, pd_billboard, GU_SRC_ALPHA, GU_FIX, ptex_smoke, 204, 0, -2.95, pm_die, 0);

    loading_cur_step++;
	SCR_UpdateScreen ();

	ADD_PARTICLE_TYPE(p_fire2,	pd_billboard, GU_SRC_ALPHA, GU_FIX, ptex_smoke, 204, 0, -2.95, pm_die, 0);
	ADD_PARTICLE_TYPE(p_chunk, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_generic, 255, -16, 0, pm_bounce, 1.475);
	ADD_PARTICLE_TYPE(p_shockwave, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_generic, 255, 0, -4.85, pm_nophysics, 0);
	ADD_PARTICLE_TYPE(p_inferno_flame, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_generic,	153, 0, 0, pm_static, 0);

    loading_cur_step++;
	SCR_UpdateScreen ();

	ADD_PARTICLE_TYPE(p_inferno_trail, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_generic, 204, 0, 0, pm_die, 0);
	ADD_PARTICLE_TYPE(p_trailpart, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_generic, 230, 0, 0, pm_static, 0);
	ADD_PARTICLE_TYPE(p_smoke, pd_billboard, GU_SRC_ALPHA, GU_FIX, ptex_smoke, 140, 3, 0, pm_normal, 0);
	ADD_PARTICLE_TYPE(p_raysmoke, pd_billboard, GU_SRC_ALPHA, GU_FIX, ptex_smoke, 140, 3, 0, pm_normal, 0);
	ADD_PARTICLE_TYPE(p_dpfire, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_dpsmoke, 144, 0, 0, pm_die, 0);

	loading_cur_step++;
	SCR_UpdateScreen ();

	ADD_PARTICLE_TYPE(p_dpsmoke, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_dpsmoke, 85, 3, 0, pm_die, 0);
	ADD_PARTICLE_TYPE(p_teleflare, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_blueflare, 255, 0, 0, pm_die, 0);
	ADD_PARTICLE_TYPE(p_flare, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_bubble, 255, 0, 0, pm_die, 0);
	ADD_PARTICLE_TYPE(p_fly, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_fly, 255, 0, 0, pm_die, 0);
	
	loading_cur_step++;
	SCR_UpdateScreen();
	
	ADD_PARTICLE_TYPE(p_dot, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_generic, 255, 0, 0, pm_static, 0);
	ADD_PARTICLE_TYPE(p_blood1, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_COLOR, ptex_blood1, 255, -20, 0, pm_die, 0);
	ADD_PARTICLE_TYPE(p_blood2, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_blood3, 255, -45, 0, pm_normal, 0.018);//disisgonnabethegibchunks
	ADD_PARTICLE_TYPE(p_blood3, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_blood3, 255, -30, 0, pm_normal, 0);
	
	loading_cur_step++;
	SCR_UpdateScreen();
	
	ADD_PARTICLE_TYPE(p_lavasplash, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_lava, 170, 0, 0, pm_nophysics, 0);
	ADD_PARTICLE_TYPE(p_bubble, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_bubble, 204, 8, 0, pm_float, 0);
	ADD_PARTICLE_TYPE(p_staticbubble, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_bubble, 204, 0, 0, pm_static, 0);
	ADD_PARTICLE_TYPE(p_flame, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_generic, 200, 10, 0, pm_die, 0);
	
	loading_cur_step++;
	SCR_UpdateScreen();
	
	ADD_PARTICLE_TYPE(p_lavatrail, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_dpsmoke, 255, 3, 0, pm_normal, 0);//R00k
	ADD_PARTICLE_TYPE(p_bubble2, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_bubble, 204, 1, 0, pm_float, 0);
	ADD_PARTICLE_TYPE(p_glow, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_generic, 204, 0, 0, pm_die, 0);
	ADD_PARTICLE_TYPE(p_alphatrail, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_generic, 100, 0, 0, pm_static, 0);
	
	loading_cur_step++;
	SCR_UpdateScreen();
	
	ADD_PARTICLE_TYPE(p_torch_flame, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_flame, 255, 12, 0, pm_die, 0);
	ADD_PARTICLE_TYPE(p_streak, pd_hide, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_none, 255, -64, 0, pm_streak, 1.5);
	ADD_PARTICLE_TYPE(p_streakwave, pd_hide, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_none, 255, 0, 0, pm_streakwave, 0);
	ADD_PARTICLE_TYPE(p_streaktrail, pd_beam, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_none, 255, 0, 0, pm_die, 0);
	
	loading_cur_step++;
	SCR_UpdateScreen();
	
	ADD_PARTICLE_TYPE(p_lightningbeam, pd_beam, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_lightning, 255, 0, 0, pm_die, 0);
	ADD_PARTICLE_TYPE(p_muzzleflash, pd_billboard, GU_SRC_ALPHA, GU_FIX, ptex_muzzleflash, 255, 0, 0, pm_static, 0);
	ADD_PARTICLE_TYPE(p_muzzleflash2, pd_billboard, GU_SRC_ALPHA, GU_FIX, ptex_muzzleflash2, 255, 0, 0, pm_static, 0);
	ADD_PARTICLE_TYPE(p_muzzleflash3, pd_billboard, GU_SRC_ALPHA, GU_FIX, ptex_muzzleflash3, 255, 0, 0, pm_static, 0);
	ADD_PARTICLE_TYPE(p_muzzleflash8, pd_billboard, GU_SRC_ALPHA, GU_FIX, ptex_muzzleflash8, 220, 0, 0, pm_static, 0);
	ADD_PARTICLE_TYPE(p_rain, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_generic, 255, -16, 0, pm_rain, 0);
	
	loading_cur_step++;
	SCR_UpdateScreen();
	
	//shpuldeditedthis(GI_ONE_MINUS_DST_ALPHA->GL_ONE_MINUS_SRC_ALPHA) (edited one right after this comment)
	ADD_PARTICLE_TYPE(p_bloodcloud, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_bloodcloud, 255, -2, 0, pm_normal, 0);
	ADD_PARTICLE_TYPE(p_q3blood, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_q3blood, 255, 0, 0, pm_static, -1);
	ADD_PARTICLE_TYPE(p_q3blood_trail, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_q3blood_trail, 255, -1.5, 0, pm_die, -1);
	ADD_PARTICLE_TYPE(p_q3rocketsmoke, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_q3smoke, 80, 0, 0, pm_die, 0);
	
	loading_cur_step++;
	SCR_UpdateScreen();
	
	ADD_PARTICLE_TYPE(p_q3grenadesmoke, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, ptex_q3smoke, 80, 0, 0, pm_die, 0);
	ADD_PARTICLE_TYPE(p_q3explosion, pd_billboard, GU_SRC_ALPHA, GU_ONE_MINUS_DST_ALPHA, ptex_q3explosion, 204, 0, 0, pm_static, -1);
	//old: ADD_PARTICLE_TYPE(p_q3flame, pd_q3flame, GU_SRC_ALPHA, GU_ONE_MINUS_DST_ALPHA, ptex_q3flame, 204, 0, 0, pm_static, -1);
	ADD_PARTICLE_TYPE(p_q3flame, pd_billboard, GU_SRC_ALPHA, GU_FIX, ptex_q3flame, 180, 0.66, 0, pm_nophysics, 0);
	ADD_PARTICLE_TYPE(p_q3gunshot, pd_q3gunshot, GU_SRC_ALPHA, GU_ONE_MINUS_DST_ALPHA, ptex_none, 255, 0, 0, pm_static, -1);
	ADD_PARTICLE_TYPE(p_q3teleport, pd_q3teleport, GU_SRC_ALPHA, GU_ONE_MINUS_DST_ALPHA, ptex_none, 255, 0, 0, pm_static, -1);

	loading_cur_step++;
	strcpy(loading_name, "particles");
	SCR_UpdateScreen ();

	Clear_LoadingFill ();

	qmb_initialized = qtrue;
}

#define	INIT_NEW_PARTICLE(_pt, _p, _color, _size, _time)	\
	_p = free_particles;			\
	free_particles = _p->next;				\
	_p->next = _pt->start;					\
	_pt->start = _p;					\
	_p->size = _size;					\
	_p->hit = 0;						\
	_p->start = cl.time;					\
	_p->die = _p->start + _time;				\
	_p->growth = 0;						\
	_p->rotspeed = 0;					\
	_p->texindex = (rand() % particle_textures[_pt->texture].components);	\
	_p->bounces = 0;					\
	VectorCopy(_color, _p->color);

__inline static void AddParticle (part_type_t type, vec3_t org, int count, float size, float time, col_t col, vec3_t dir)
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
		case p_rayspark:
			p->size = 1.175;
			VectorCopy (org, p->org);
			tempSize = size * 2;
			p->vel[0] = (rand() % (int)tempSize) - ((int)tempSize/6);
			p->vel[1] = (rand() % (int)tempSize) - ((int)tempSize/6);
			p->vel[2] = /*(rand() % (int)tempSize) - (*/(int)tempSize;
			break;
		case p_raysmoke:
			for (j=0 ; j<3 ; j++)
				p->org[j] = org[j] + ((rand() & 31) - 16) / 2.0;

			p->vel[0] = ((rand() % 10)+2);
			p->vel[1] = ((rand() % 10)+2);
			p->vel[2] = ((rand() % 10)+2)*5;
			p->growth = 7.5;
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
			p->size = size * (0.75 +((0.05 * (rand() % 20)) * 0.5));//blubs: resultant size range: [size * 0.75, size * 1.25)
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

__inline static void AddParticleTrail (part_type_t type, vec3_t start, vec3_t end, float size, float time, col_t col)
{
	byte		*color;
	int		i, j, num_particles;
	float		count, length;
	vec3_t		point, delta;
	particle_t	*p;
	particle_type_t	*pt;
	static	float	rotangle = 0;
    count = 0;

	if (!qmb_initialized)
		Sys_Error ("QMB particle added without initialization");

	//assert (size > 0 && time > 0);

	if (type < 0 || type >= num_particletypes)
		Sys_Error ("AddParticle: Invalid type (%d)", type);

	pt = &particle_types[particle_type_index[type]];

	VectorCopy(start, point);
	VectorSubtract(end, start, delta);
	if (!(length = VectorLength(delta)))
		return;

	switch (type)
	{

    case p_q3blood_trail:
	case p_q3rocketsmoke:
		count = length / 40.0;
		break;

	case p_q3grenadesmoke:
		count = length / 12.0;
		break;

	case p_alphatrail:
	case p_trailpart:
	case p_lavatrail:
		count = length / 1.1;
		break;

	case p_blood3:
		count = length / 8;
		break;

	case p_bubble:
	case p_bubble2:
		count = length / 5.0;
		break;

	case p_smoke:
		count = length / 3.8;
		break;

	case p_dpsmoke:
		count = length / 2.5;
		break;

	case p_dpfire:
		count = length / 2.8;
		break;

	default:
		//assert (!"AddParticleTrail: unexpected type");
		break;
	}

	if (!(num_particles = (int)count))
		num_particles = 1;

	VectorScale(delta, 1.0 / num_particles, delta);

	for (i=0 ; i < num_particles && free_particles ; i++)
	{
		color = col ? col : ColorForParticle (type);
		INIT_NEW_PARTICLE(pt, p, color, size, time);

		switch (type)
		{
		case p_alphatrail:
		case p_trailpart:
			VectorCopy (point, p->org);
			VectorClear (p->vel);
			p->growth = -size / time;
			break;

		case p_blood3:
			VectorCopy (point, p->org);
			for (j=0 ; j<3 ; j++)
				p->org[j] += ((rand() & 15) - 8) / 8.0;
			for (j=0 ; j<3 ; j++)
				p->vel[j] = ((rand() & 15) - 8) / 2.0;
			p->size = size * (rand() % 20) / 10.0;
			p->growth = 6;
			break;

		case p_q3blood_trail:
			VectorCopy (point, p->org);
			for (j=0 ; j<3 ; j++)
				p->org[j] += ((rand() & 15) - 8) / 8.0;
			for (j=0 ; j<3 ; j++)
				p->vel[j] = ((rand() & 15) - 8) / 2.0;
			p->growth = 6;
			break;

		case p_bubble2:
			VectorCopy(point, p->org);
			for (j=0 ; j<3 ; j++)
				p->vel[j] = (rand() % 10) - 5;
			break;

		//R00k added
		case p_bubble:
			VectorCopy (point, p->org);

			for (j=0 ; j<3 ; j++)
				p->org[j] += ((rand() & 15) - 8) / 8.0;

			for (j=0 ; j<3 ; j++)
				p->vel[j] = ((rand() & 15) - 8) / 2.0;

			p->size = size * (rand() % 20) / 10.0;
			p->growth = 1;
			break;

		case p_smoke:
			VectorCopy (point, p->org);
			for (j=0 ; j<3 ; j++)
				p->org[j] += ((rand() & 7) - 4) / 8.0;
			p->vel[0] = p->vel[1] = 0;
			p->vel[2] = rand() & 3;
			p->growth = 4.5;
			p->rotspeed = (rand() & 63) + 96;
			break;

        case p_q3rocketsmoke:
		case p_q3grenadesmoke:
			VectorCopy (point, p->org);
			for (j=0 ; j<3 ; j++)
				p->org[j] += ((rand() & 7) - 4) / 8.0;
			VectorClear (p->vel);
			p->growth = 30;
			if (rotangle >= 360)
				rotangle = 0;
			p->rotangle = rotangle;
			rotangle += 30;
			break;

		case p_dpsmoke:
			VectorCopy (point, p->org);
			for (j=0 ; j<3 ; j++)
				p->vel[j] = (rand() % 10) - 5;
			p->growth = 3;
			p->rotspeed = (rand() & 63) + 96;
			break;

		case p_dpfire:
			VectorCopy (point, p->org);
			for (j=0 ; j<3 ; j++)
				p->vel[j] = (rand() % 40) - 20;
			break;

		case p_lavatrail:
			VectorCopy (point, p->org);
			for (j=0 ; j<3 ; j++)
				p->org[j] += ((rand() & 7) - 4);
			p->vel[0] = p->vel[1] = 0;
			p->vel[2] = rand() & 3;
			break;

		default:
			//assert (!"AddParticleTrail: unexpected type");
			break;
		}

		VectorAdd(point, delta, point);
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

inline static void QMB_UpdateParticles(void)
{
	int		i, c;
	float	grav, bounce, frametime, distance[3];
	vec3_t	oldorg, stop, normal;
	particle_type_t	*pt;
	particle_t	*p, *kill;

	if (!qmb_initialized)
		return;

	particle_count = 0;
	frametime = fabs(cl.ctime - cl.oldtime);
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

			if (VectorLength(distance) >= r_farclip.value)
				p->die = 0;

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

						if ((stop != p->org)&&(VectorLength(stop)!=0))
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

						if ((stop != p->org)&&(VectorLength(stop)!=0))
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

				if (!VectorLength(p->vel))
					p->die = 0;
				break;

			case pm_rain:
				VectorCopy(p->org, oldorg);
				VectorMA(p->org, frametime, p->vel, p->org);

				VectorSubtract(r_refdef.vieworg,oldorg, distance);

				if (VectorLength(distance) < r_farclip.value)
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

//from darkplaces engine - finds which corner of a particle goes where, so I don't have to :D
void R_CalcBeamVerts (float *vert, vec3_t org1, vec3_t org2, float width)
{
	vec3_t right1, right2, diff, normal;

	VectorSubtract (org2, org1, normal);
	VectorNormalize (normal);

	//width = width / 2;
	// calculate 'right' vector for start
	VectorSubtract (r_origin, org1, diff);
	VectorNormalize (diff);
	CrossProduct (normal, diff, right1);

	// calculate 'right' vector for end
	VectorSubtract (r_origin, org2, diff);
	VectorNormalize (diff);
	CrossProduct (normal, diff, right2);

	vert[ 0] = org1[0] + width * right1[0];
	vert[ 1] = org1[1] + width * right1[1];
	vert[ 2] = org1[2] + width * right1[2];
	vert[ 4] = org1[0] - width * right1[0];
	vert[ 5] = org1[1] - width * right1[1];
	vert[ 6] = org1[2] - width * right1[2];
	vert[ 8] = org2[0] - width * right2[0];
	vert[ 9] = org2[1] - width * right2[1];
	vert[10] = org2[2] - width * right2[2];
	vert[12] = org2[0] + width * right2[0];
	vert[13] = org2[1] + width * right2[1];
	vert[14] = org2[2] + width * right2[2];
}

#define DRAW_PARTICLE_BILLBOARD(_ptex, _p, _coord)		\
	sceGumPushMatrix ();									\
														\
    const ScePspFVector3 translation =                  \
    {                                                   \
	 _p->org[0], _p->org[1], _p->org[2]                 \
    };                                                  \
    sceGumTranslate(&translation);                      \
														\
    const ScePspFVector3 scale =                        \
	{                                                   \
	 _p->size, _p->size, _p->size                       \
	};                                                  \
	sceGumScale(&scale);			                    \
														\
	if (_p->rotspeed || pt->id == p_q3rocketsmoke || pt->id == p_q3grenadesmoke)\
	{                                                   \
		const ScePspFVector3 rotation =                 \
	    {                                               \
		    vpn[0] * (GU_PI / 180.0f),                  \
		    vpn[1] * (GU_PI / 180.0f),                  \
		    vpn[2] * (GU_PI / 180.0f)                   \
	    };                                              \
	    sceGumRotateZYX(&rotation);   					\
	}                                                   \
	sceGuColor(GU_RGBA(_p->color[0], _p->color[1], _p->color[2], _p->color[3]));\
														\
	sceGumUpdateMatrix();                               \
													    \
	struct vertex                                       \
	{                                                   \
	  float u, v;                                       \
	  float x, y, z;                                    \
	};                                                  \
	vertex* const df = static_cast<vertex*>(sceGuGetMemory(sizeof(vertex) * 4));\
														\
	df[0].u = _ptex->coords[_p->texindex][0]; df[0].v = _ptex->coords[_p->texindex][3];\
	df[0].x = _coord[0][0]; df[0].y = _coord[0][1]; df[0].z = _coord[0][2];            \
	df[1].u = _ptex->coords[_p->texindex][0]; df[1].v = _ptex->coords[_p->texindex][1];\
	df[1].x = _coord[1][0]; df[1].y = _coord[1][1]; df[1].z = _coord[1][2];            \
	df[2].u = _ptex->coords[_p->texindex][2]; df[2].v = _ptex->coords[_p->texindex][1];\
	df[2].x = _coord[2][0]; df[2].y = _coord[2][1]; df[2].z = _coord[2][2];            \
	df[3].u = _ptex->coords[_p->texindex][2]; df[3].v = _ptex->coords[_p->texindex][3];\
	df[3].x = _coord[3][0]; df[3].y = _coord[3][1]; df[3].z = _coord[3][2];            \
	sceGuDrawArray(GU_TRIANGLE_FAN, GU_TEXTURE_32BITF | GU_VERTEX_32BITF, 4, 0, df);   \
    sceGuColor(GU_RGBA(0xff,0xff,0xff,0xff));           \
														\
	sceGumPopMatrix ();                                 \
    sceGumUpdateMatrix();

//extern ScePspFMatrix4	r_world_matrix[16];
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

	if (!cl.paused)
		QMB_UpdateParticles ();

	VectorAdd (vup, vright, billboard[2]);
	VectorSubtract (vright, vup, billboard[3]);
	VectorNegate (billboard[2], billboard[0]);
	VectorNegate (billboard[3], billboard[1]);

   	sceGuDepthMask (GU_TRUE);
	sceGuEnable (GU_BLEND);
	sceGuTexFunc(GU_TFX_MODULATE , GU_TCC_RGBA);
	sceGuShadeModel (GU_SMOOTH);

	for (i = 0 ; i < num_particletypes ; i++)
	{
		pt = &particle_types[i];

		if (!pt->start)
			continue;

		sceGuBlendFunc (GU_ADD, pt->SrcBlend, pt->DstBlend, 0, 0xFFFFFFFF); //edited fixed value to 1 from 0 - shpuld

		switch (pt->drawtype)
		{
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
					if (VectorLength(distance) > r_farclip.value)
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
					if (VectorLength(distance) > r_farclip.value)
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
					if (VectorLength(distance) > r_farclip.value)
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

		case pd_billboard:
			ptex = &particle_textures[pt->texture];
			GL_Bind (ptex->texnum);
			
			for (p = pt->start ; p ; p = p->next)
			{
				if (particle_time < p->start || particle_time >= p->die)
					continue;

				for (j = 0 ; j < cl.maxclients ; j++)
				{
					if (pt->custom != -1 && VectorSupCompare(p->org, cl_entities[1+j].origin, 40))
					{
						p->die = 0;
						continue;
					}
				}
				
				if(pt->texture == ptex_muzzleflash || pt->texture == ptex_muzzleflash2 || pt->texture == ptex_muzzleflash3)
					sceGuDepthRange(0, 19660);
				
				DRAW_PARTICLE_BILLBOARD(ptex, p, billboard);
				
				if(pt->texture == ptex_muzzleflash || pt->texture == ptex_muzzleflash2 || pt->texture == ptex_muzzleflash3)
					sceGuDepthRange(0, 65535);
			}
			break;

		case pd_billboard_vel:
			ptex = &particle_textures[pt->texture];
			GL_Bind (ptex->texnum);
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
		default:
				//assert (!"QMB_DrawParticles: unexpected drawtype");
				break;
		}
	}

	sceGuDepthMask (GU_FALSE);
	sceGuDisable (GU_BLEND);
	sceGuBlendFunc (GU_ADD, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, 0, 0);
	sceGuTexFunc(GU_TFX_REPLACE, GU_TCC_RGBA);
	sceGuShadeModel (GU_FLAT);
}

void QMB_Shockwave_Splash(vec3_t org, int radius)
{
	float	theta;
	vec3_t	angle;

	angle[2] = 0;

	for (theta = 0; theta < 6.283185307179586476925286766559; theta += 0.069813170079773183076947630739545)
	{
		#ifdef PSP_VFPU
		angle[0] = vfpu_cosf(theta) * radius;
		angle[1] = vfpu_sinf(theta) * radius;
		#else
		angle[0] = cos(theta) * radius;
		angle[1] = sin(theta) * radius;
		#endif
		AddParticle(p_shockwave, org, 1, 2, 0.625f, NULL, angle);
	}
}

extern sfx_t		*cl_sfx_thunder;
void QMB_LetItRain(void)
{
	int			i;
	msurface_t	*surf;
	glpoly_t	*p;
	col_t		color;
	float		distance[3], point[3];
	float		frametime = fabs(cl.ctime - cl.oldtime);

	color[0] =  color[1] = color[2] = + (rand() % 25 + 15);
	color[2] += 5;

	if (!qmb_initialized)
		return;

	if (!particle_mode)
		return;

	if (frametime)
	{
		for (i = 0, surf = cl.worldmodel->surfaces; i < cl.worldmodel->numsurfaces; i++, surf++)
		{
			if (!(surf->flags & SURF_DRAWSKY)) continue;

			for (p = surf->polys; p; p = p->next)
			{
				VectorSubtract(r_refdef.vieworg,p->midpoint, distance);

				if (VectorLength(distance) > r_farclip.value)
					continue;

				//R00k let's make some thunder...
				/*if (cl.time > cl.thundertime)
				{
					S_StartSound (-1, 0, cl_sfx_thunder, p->midpoint, 1, 1);
					cl.thundertime = cl.time + (rand()% 60 + 1);
				}*/

				point[0] = p->midpoint[0] + (rand() % 80 - 40);
				point[1] = p->midpoint[1] + (rand() % 80 - 40);
				point[2] = p->midpoint[2];

				AddParticle(p_rain, point, 1, 0.75, 5, color, zerodir);
			}
		}
	}
};

//R00k: revamped to coincide with classic particle style...

void QMB_ParticleExplosion (vec3_t org)
{
	if (r_explosiontype.value == 2)//no explosion what so ever
		return;

	if (ISUNDERWATER(TruePointContents(org)))
	{
		AddParticle (p_bubble, org, 6, 3.0, 2.5, NULL, zerodir);
		AddParticle (p_bubble, org, 4, 2.35, 2.5, NULL, zerodir);

		if (r_part_explosions.value == 2)
		{
			AddParticle (p_q3explosion, org, 1, 36, 0.2, NULL, zerodir);
		}
		else
		{
			if (r_part_explosions.value == 2)
		    {
			AddParticle (p_q3explosion, org, 1, 36, 0.2, NULL, zerodir);
		    }
		    else
		    {
			   AddParticle (p_fire, org, 16, 120, 1, NULL, zerodir);
			   if (r_explosiontype.value != 1)
			   {
				 AddParticle (p_spark, org, 50, 250, 0.925f, NULL, zerodir);
				 AddParticle (p_spark, org, 25, 150, 0.925f, NULL, zerodir);
			   }
		    }
		}
	}
	else

	{
		/*	original
		if (r_explosiontype.value != 3)
		{
			if (r_flametype.value < 1)//R00k
			{
				AddParticle (p_fire2, org, 16, 18, 1, NULL, zerodir);
			}
			else
			{
				AddParticle (p_fire, org, 16, 18, 1, NULL, zerodir);
			}
		}

		if ((r_explosiontype.value == 0) || (r_explosiontype.value == 1) || (r_explosiontype.value == 3))
		{
			AddParticle (p_spark, org, 50, 250, 0.925f, NULL, zerodir);
			AddParticle (p_spark, org, 25, 150, 0.925f, NULL, zerodir);
		}
		*/

		//shpuld
		AddParticle (p_fire, org, 10, 40, 0.5, NULL, zerodir);
		AddParticle (p_fire2, org, 14, 36, 1.8, NULL, zerodir);
	}
}

void d8to24col (col_t colourv, int colour)
{
	byte	*colourByte;

	colourByte = (byte *)&d_8to24table[colour];
	colourv[0] = colourByte[0];
	colourv[1] = colourByte[1];
	colourv[2] = colourByte[2];
}

__inline static void AddColoredParticle (part_type_t type, vec3_t org, int count, float size, float time, int colorStart, int colorLength, vec3_t dir)
{
	col_t		color;
	int		i, j, colorMod = 0;
	float		tempSize;
	particle_t	*p;
	particle_type_t	*pt;


	if (!qmb_initialized)
		Sys_Error ("QMB particle added without initialization");

	//assert (size > 0 && time > 0);

	if (type < 0 || type >= num_particletypes)
		Sys_Error ("AddColoredParticle: Invalid type (%d)", type);

	pt = &particle_types[particle_type_index[type]];

	for (i=0 ; i < count && free_particles ; i++)
	{
		d8to24col (color, colorStart + (colorMod % colorLength));
		colorMod++;
		INIT_NEW_PARTICLE(pt, p, color, size, time);

		switch (type)
		{
		case p_spark:
			p->size = 1.175;
			VectorCopy (org, p->org);
			tempSize = size * 2;
			p->vel[0] = (rand() % (int)tempSize) - ((int)tempSize / 4);
			p->vel[1] = (rand() % (int)tempSize) - ((int)tempSize / 4);
			p->vel[2] = (rand() % (int)tempSize) - ((int)tempSize / 6);
			break;

		case p_fire:
			VectorCopy (org, p->org);
			for (j=0 ; j<3 ; j++)
				p->vel[j] = ((rand() % 160) - 80) * (size / 25.0);
			break;

		default:
		//assert (!"AddColoredParticle: unexpected type");
			break;
		}
	}
}

void QMB_ColorMappedExplosion (vec3_t org, int colorStart, int colorLength)
{

	if (ISUNDERWATER(TruePointContents(org)))
	{
		//AddColoredParticle (p_fire, org, 16, 18, 1, colorStart, colorLength, zerodir);
		AddParticle (p_bubble, org, 6, 3.0, 2.5, NULL, zerodir);
		AddParticle (p_bubble, org, 4, 2.35, 2.5, NULL, zerodir);
		if (r_explosiontype.value != 2)
		{
			AddColoredParticle (p_spark, org, 50, 100, 0.5, colorStart, colorLength, zerodir);
			AddColoredParticle (p_spark, org, 25, 60, 0.5, colorStart, colorLength, zerodir);
		}
	}
	else
	{
		if (r_flametype.value < 1)//R00k
		{
				AddColoredParticle (p_fire2, org, 16, 18, 1, colorStart, colorLength, zerodir);
		}
		else
		{
				AddColoredParticle (p_fire, org, 16, 18, 1, colorStart, colorLength, zerodir);
		}

		if (r_explosiontype.value < 2)
		{
			AddColoredParticle (p_spark, org, 50, 250, 0.625f, colorStart, colorLength, zerodir);
			if (r_explosiontype.value < 1)
				AddColoredParticle (p_spark, org, 25, 150, 0.625f, colorStart, colorLength, zerodir);
		}
	}
}

/* Original

void QMB_Blood_Splat(part_type_t type, vec3_t org) //R00k :)
{
	int			j;
	col_t		color;
	vec3_t		neworg, angle;

	VectorClear (angle);

	color[0]=100;
	color[1]=0;
	color[2]=0;
	color[3]=255;

	AddParticle(p_bloodcloud, org, 1, 6, 0.5, color, zerodir);

	for (j=0 ; j<4 ; j++)
	{
		AngleVectors (angle, NULLVEC, NULLVEC, neworg);
		VectorMA (org, 70, neworg, neworg);

		AddParticle (type, org, 5, 1, 2, color, neworg);
		angle[1] += 360 / 4;
	}
}*/

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
			AddParticle (p_smoke, org, 3, 12, 1.225f + ((rand() % 10) - 5) / 40.0, NULL, zerodir);
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
	case 256:
		color[2] = 1.0f;
		AddParticle (p_raysmoke, org, 3, 25, 1.225f + ((rand() % 10) - 2) / 40.0, color, zerodir);
		AddParticle (p_rayspark, org, 12, 75, 0.6f,  color, zerodir);
		break;
	case 512:
		color[1] = 1.0f;
		color[2] = 0;
		color[3] = 0;
		AddParticle (p_raysmoke, org, 3, 25, 1.225f + ((rand() % 10) - 2) / 40.0, color, zerodir);
		AddParticle (p_rayspark, org, 12, 75, 0.6f,  color, zerodir);
		break;
	default:
/*
		else if (nehahra)
		{
			switch (count)
			{
			case 25:	// slime barrel chunks
				return;

			case 244:	// sewer
				for (i=0 ; i<(count>>3) ; i++)
				{
					for (j=0 ; j<3 ; j++)
						neworg[j] = org[j] + ((rand() % 24) - 12);
					newdir[0] = dir[0] * (10 + (rand() % 5));
					newdir[1] = dir[1] * (10 + (rand() % 5));
					newdir[2] = dir[2] * 15;
					d8to24col (color, (col & ~7) + (rand() & 7));
					AddParticle (p_glow, neworg, 1, 3.5, 0.5 + 0.1 * (rand() % 3), color, newdir);
				}
				return;
			}
		}
*/
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

float pap_detr(int weapon)
{

	switch (weapon)
	{
		case W_COLT:
			return 0;
			break;
		case W_BIATCH:
			return 1;
			break;
		case W_KAR:
			return 0;
			break;
		case W_THOMPSON:
			return 0;
			break;
		case W_357:
			return 0;
			break;
		case W_KILLU:
			return 1;
			break;
		case W_BAR:
			return 0;
			break;
		case W_BK:
			return 0;
			break;
		case W_BROWNING:
			return 0;
			break;
		case W_DB:
			return 0;
			break;
		case W_FG:
			return 0;
			break;
		case W_GEWEHR:
			return 0;
			break;
		case W_KAR_SCOPE:
			return 0;
			break;
		case W_M1:
			return 0;
			break;
		case W_M1A1:
			return 0;
			break;
		case W_MP40:
			return 0;
			break;
		case W_MG:
			return 0;
			break;
		case W_PANZER:
			return 0;
			break;
		case W_PPSH:
			return 0;
			break;
		case W_PTRS:
			return 0;
			break;
		case W_RAY:
			return 0;
			break;
		case W_SAWNOFF:
			return 0;
			break;
		case W_STG:
			return 0;
			break;
		case W_TRENCH:
			return 0;
			break;
		case W_TYPE:
			return 0;
			break;
		case W_M2:
			return 0;
			break;
		case W_COMPRESSOR:
      return 1;
      break;
    case W_M1000:
      return 1;
      break;
    case W_GIBS:
      return 1;
      break;
    case W_SAMURAI:
      return 1;
      break;
    case W_AFTERBURNER:
      return 1;
      break;
    case W_SPATZ:
      return 1;
      break;
    case W_SNUFF:
      return 1;
      break;
    case W_BORE:
      return 1;
      break;
    case W_IMPELLER:
      return 1;
      break;
    case W_BARRACUDA:
      return 1;
      break;
    case W_ACCELERATOR:
      return 1;
      break;
    case W_GUT:
      return 1;
      break;
    case W_REAPER:
      return 1;
      break;
    case W_HEADCRACKER:
      return 1;
      break;
    case W_LONGINUS:
      return 1;
      break;
    case W_PENETRATOR:
      return 1;
      break;
    case W_WIDOW:
      return 1;
      break;
    case W_PORTER:
      return 1;
      break;
    case W_ARMAGEDDON:
      return 1;
      break;
    case W_WIDDER:
      return 1;
      break;
    case W_MP5:
      return 0;
      break;
    case W_TESLA:
      return 0;
      break;
	}
	return 0;
}

// MotoLegacy - Raygun barrel trail
void QMB_RayFlash(vec3_t org, float weapon)
{
	// if we're ADS, just flat out end here to avoid useless calcs/defs
	if (cl.stats[STAT_ZOOM] || !qmb_initialized)
		return;

	col_t 	color;
	vec3_t 	endorg;

	// green trail
	if (weapon == W_RAY) {
		color[0] = 0;
		color[1] = 255;
	} else { // red trail
		color[0] = 255;
		color[1] = 0;
	}
	color[2] = 0;

	QMB_MuzzleFlash(org);
}

//R00k added particle muzzleflashes
void QMB_MuzzleFlash(vec3_t org)
{
	if (!qmb_initialized) {
		return;
	}

	float	frametime = fabs(cl.ctime - cl.oldtime);
	col_t	color;

	// change color if PaP
	if (pap_detr(cl.stats[STAT_ACTIVEWEAPON]) == 0) {
    	color[0] = color[1] = color[2] = 255;
	} else {
	  color[0] = 132;
	  color[1] = 44;
	  color[2] = 139;
	}

	// lower origin based on player stance
	if (sv_player->v.view_ofs[2] >= 0)
		org[2] -= 32 - sv_player->v.view_ofs[2];
	else
		org[2] -= 32 + abs(sv_player->v.view_ofs[2]);
	/*if (sv_player->v.view_ofs[2] == 8) {
		org[2] -= 24;
	} else if (sv_player->v.view_ofs[2] == -10) {
		org[2] -= 42;
	}*/

	float size;

	if(!(ISUNDERWATER(TruePointContents(org))))
	{
		size = sv_player->v.Flash_Size;
		
		if(size == 0 || cl.stats[STAT_ZOOM] == 2)
			return;
        switch(rand() % 3 + 1)
        {
            case 1:
                AddParticle (p_muzzleflash, org, 1, size, 0.04 * frametime, color, zerodir);
                break;
            case 2:
                AddParticle (p_muzzleflash2, org, 1, size, 0.04 * frametime, color, zerodir);
                break;
            case 3:
                AddParticle (p_muzzleflash3, org, 1, size, 0.04 * frametime, color, zerodir);
                break;
            default:
                AddParticle (p_muzzleflash, org, 1, size, 0.04 * frametime, color, zerodir);
                break;
        }
	}
}

void QMB_MuzzleFlashLG(vec3_t org)
{
	float	frametime = fabs(cl.ctime - cl.oldtime);
	col_t	color;

	color[0] = color[1] = 20;
	color[2] = 200;

	if (!qmb_initialized)
		return;

	if (!particle_mode)
		return;

	if (!(ISUNDERWATER(TruePointContents(org))))
	{
		AddParticle (p_muzzleflash8, org, 1, 8, 0.4 * frametime, color, zerodir);
	}
}

void QMB_RocketTrail (vec3_t start, vec3_t end, trail_type_t type)
{
	col_t		color;

	switch (type)
	{
	case GRENADE_TRAIL://r00K mODIFIED

		if (ISUNDERWATER(TruePointContents(start)))
		{
			AddParticleTrail (p_bubble, start, end, 1, 0.30, NULL);
		}
		else

		{
			if (r_part_trails.value > 1)
			{
				color[0] = 15; color[1] = 15; color[2] = 10;
				AddParticleTrail (p_alphatrail, start, end, 8, 1, color);
			}
			else
				AddParticleTrail (p_smoke, start, end, 1.45, 0.825, NULL);
		}
		break;

	case BLOOD_TRAIL:
	case SLIGHT_BLOOD_TRAIL:
		if (r_part_trails.value == 2)
			AddParticleTrail (p_q3blood_trail, start, end, 15, 2, NULL);
		else
			AddParticleTrail (p_blood3, start, end, type == BLOOD_TRAIL ? 1.35 : 2.4, 2, NULL);
		break;

	case TRACER1_TRAIL:
		color[0] = color[2] = 0;
		color[1] = 124;
		AddParticleTrail (p_trailpart, start, end, 3.75, 0.5, color);
		break;

	case TRACER2_TRAIL:
		color[0] = 255;
		color[1] = 77;
		color[2] = 0;
		AddParticleTrail (p_trailpart, start, end, 1.75, 0.2, color);
		break;

	case VOOR_TRAIL:
		color[0] = 77;
		color[1] = 0;
		color[2] = 255;
		AddParticleTrail (p_trailpart, start, end, 3.75, 0.5, color);
		break;

	case ALT_ROCKET_TRAIL:

		if (ISUNDERWATER(TruePointContents(start)))
		{
			AddParticleTrail (p_bubble, start, end, 1, 2.5, NULL);
		}
		else

		{
			if (r_part_trails.value > 1)
			{
				color[0] = 15; color[1] = 15; color[2] = 10;
				AddParticleTrail (p_alphatrail, start, end, 8, 1, color);
			}
			else
			{
				AddParticleTrail (p_dpfire, start, end, 3, 0.26, NULL);
				AddParticleTrail (p_dpsmoke, start, end, 3, 0.825, NULL);
			}
		}
		break;

	case LAVA_TRAIL:
		AddParticleTrail (p_lavatrail, start, end, 5, 0.25, NULL);
		AddParticleTrail (p_dpsmoke, start, end, 5, 0.825, NULL);
		break;

	case BUBBLE_TRAIL:

		if (ISUNDERWATER(TruePointContents(start)))
			AddParticleTrail (p_bubble2, start, end, 1.5, 0.825, NULL);

		break;

	case NEHAHRA_SMOKE:
		AddParticleTrail (p_smoke, start, end, 0.8, 0.825, NULL);
		break;
	case RAYGREEN_TRAIL:
		color[0] = 0;
		color[1] = 255;
		color[2] = 0;
		AddParticleTrail (p_alphatrail, start, end, 8, 0.6, color);
		break;
	case RAYRED_TRAIL:
		color[0] = 255;
		color[1] = 0;
		color[2] = 0;
		AddParticleTrail (p_alphatrail, start, end, 8, 0.6, color);
		break;
	case ROCKET_TRAIL:
	default:
		color[0] = 255;
		color[1] = 56;
		color[2] = 9;
//		AddParticleTrail (p_trailpart, start, end, 6.2, 0.31, color);
		if (ISUNDERWATER(TruePointContents(start)))
		{
			AddParticleTrail (p_trailpart, start, end, 1, 0.30, color);
			AddParticleTrail (p_bubble, start, end, 1, 2.5, NULL);
		}
		else

		{
			if (r_part_trails.value > 1)
			{
				color[0] = 15; color[1] = 15; color[2] = 10;
				AddParticleTrail (p_alphatrail, start, end, 8, 3, color);
			}
			else
			{
				AddParticleTrail (p_trailpart, start, end, 6.2, 0.31, color);
				AddParticleTrail (p_smoke, start, end, 1.8, 0.825, NULL);
			}
		}
		break;
	case NAIL_TRAIL://R00k added

		if (ISUNDERWATER(TruePointContents(start)))
		{
			AddParticleTrail (p_bubble, start, end, 0.25, 0.50, NULL);
		}
		else

		{
			color[0] = 15; color[1] = 15; color[2] = 15;
			AddParticleTrail (p_alphatrail, start, end, 1, 0.25, color);
		}
		break;
	}
}
/*
void QMB_AxeSwoosh(vec3_t start)
{
		col_t		color;
		vec3_t		end, mid;

		mid[0] = 15;mid[1] = 15;mid[2] = 15;
		VectorSubtract(start,mid,end);

		if (ISUNDERWATER(TruePointContents(start)))
		{
			AddParticleTrail (p_bubble, start, end, 0.25, 0.50, NULL);
		}
		else
		{
			color[0] = 255; color[1] = 255; color[2] = 255;
			AddParticleTrail (p_alphatrail, start, end, 50, 0.5, color);
		//	AddParticle (p_spark, start, 50, 250, 0.925f, NULL, zerodir);
		}
};
*/

void QMB_BlobExplosion (vec3_t org)
{
	float	theta;
	col_t	color;
	vec3_t	neworg, vel;

	color[0] = 60;
	color[1] = 100;
	color[2] = 240;
	AddParticle (p_spark, org, 44, 250, 1.15, color, zerodir);

	color[0] = 90;
	color[1] = 47;
	color[2] = 207;
	AddParticle (p_fire, org, 15, 30, 1.4, color, zerodir);

	vel[2] = 0;
	for (theta = 0 ; theta < 6.28318530717958647692528676655901 ; theta += 0.0897597901025655210989326680937001)
	{
		color[0] = (60 + (rand() & 15));
		color[1] = (65 + (rand() & 15));
		color[2] = (200 + (rand() & 15));

		#ifdef PSP_VFPU
		vel[0] = vfpu_cosf(theta) * 125;
		vel[1] = vfpu_sinf(theta) * 125;
		neworg[0] = org[0] + vfpu_cosf(theta) * 6;
		neworg[1] = org[1] + vfpu_sinf(theta) * 6;
		#else
		vel[0] = cos(theta) * 125;
		vel[1] = sin(theta) * 125;
		neworg[0] = org[0] + cos(theta) * 6;
		neworg[1] = org[1] + sin(theta) * 6;
		#endif
		neworg[2] = org[2] + 0 - 10;
		AddParticle (p_shockwave, neworg, 1, 4, 0.8, color, vel);
		neworg[2] = org[2] + 0 + 10;
		AddParticle (p_shockwave, neworg, 1, 4, 0.8, color, vel);

		vel[0] *= 1.15;
		vel[1] *= 1.15;
		#ifdef PSP_VFPU
		neworg[0] = org[0] + vfpu_cosf(theta) * 13;
		neworg[1] = org[1] + vfpu_sinf(theta) * 13;
		#else
		neworg[0] = org[0] + cos(theta) * 13;
		neworg[1] = org[1] + sin(theta) * 13;
		#endif
		neworg[2] = org[2] + 0;
		AddParticle (p_shockwave, neworg, 1, 6, 1.0, color, vel);
	}
}

void QMB_LavaSplash (vec3_t org)
{
	int	i, j;
	float	vel;
	vec3_t	dir, neworg;

	for (i=-16 ; i<16; i++)
	{
		for (j=-16 ; j<16 ; j++)
		{
			dir[0] = j * 8 + (rand() & 7);
			dir[1] = i * 8 + (rand() & 7);
			dir[2] = 256;

			neworg[0] = org[0] + dir[0];
			neworg[1] = org[1] + dir[1];
			neworg[2] = org[2] + (rand() & 63);

			VectorNormalizeFast (dir);
			vel = 50 + (rand() & 63);
			VectorScale (dir, vel, dir);

			AddParticle (p_lavasplash, neworg, 1, 4.5, 2.6 + (rand() & 31) * 0.02, NULL, dir);
		}
	}
}

void QMB_TeleportSplash (vec3_t org)
{
	int		i, j, k;
	vec3_t		neworg, angle;
	col_t		color;

	if (r_part_telesplash.value == 2)
	{
		AddParticle (p_q3teleport, org, 1, 1, 1.0, NULL, zerodir);
		return;
	}

	//QMB_Shockwave_Splash(org, 120);
	for (i=-12 ; i<=12 ; i+=6)
	{
		for (j=-12 ; j<=12 ; j+=6)
		{
			for (k=-24 ; k<=32 ; k+=8)
			{
				neworg[0] = org[0] + i + (rand() & 3) - 1;
				neworg[1] = org[1] + j + (rand() & 3) - 1;
				neworg[2] = org[2] + k + (rand() & 3) - 1;
				angle[0] = (rand() & 15) - 7;
				angle[1] = (rand() & 15) - 7;
				angle[2] = (rand() % 160) - 80;
				AddParticle (p_teleflare, neworg, 1, 1.8, 0.30 + (rand() & 7) * 0.02, NULL, angle);
			}
		}
	}

	VectorSet (color, 140, 140, 255);
	VectorClear (angle);
	for (i=0 ; i<5 ; i++)
	{
		angle[2] = 0;
		for (j=0 ; j<5 ; j++)
		{
			AngleVectors (angle, NULLVEC, NULLVEC, neworg);
			VectorMA (org, 70, neworg, neworg);
			AddParticle (p_sparkray, org, 1, 6 + (i & 3), 5, color, neworg);
			angle[2] += 360 / 5;
		}
		angle[0] += 180 / 5;
	}
}


void QMB_InfernoFlame (vec3_t org)
{
	float	frametime = fabs(cl.ctime - cl.oldtime);

	if (ISUNDERWATER(TruePointContents(org)))
		return;

	if (frametime)
	{
		if (r_flametype.value < 1)
		{
			AddParticle (p_torch_flame, org, 1, 5, 0.5, NULL, zerodir);//R00k
		}
		else
		{
			AddParticle (p_inferno_flame, org, 1, 30, 13.125 * frametime, NULL, zerodir);
			AddParticle (p_inferno_trail, org, 2, 1.75, 45.0 * frametime, NULL, zerodir);
			AddParticle (p_inferno_trail, org, 2, 1.0, 52.5 * frametime, NULL, zerodir);
		}
	}
}

void QMB_StaticBubble (entity_t *ent)
{
	AddParticle (p_staticbubble, ent->origin, 1, ent->frame == 1 ? 1.85 : 2.9, 0.001, NULL, zerodir);
}

void QMB_TorchFlame (vec3_t org)
{
    if (fabs(cl.ctime - cl.oldtime))
	    AddParticle (p_torch_flame, org, 2, 2.5, 0.5, NULL, zerodir);
}

void QMB_FlameGt (vec3_t org, float size, float time)
{
	if (fabs(cl.ctime - cl.oldtime))
		AddParticle (p_flame, org, 1, size, time, NULL, zerodir);
}

void QMB_BigTorchFlame (vec3_t org)
{
	if (fabs(cl.ctime - cl.oldtime))
		AddParticle (p_torch_flame, org, 2, 7, 0.5, NULL, zerodir);
}

void QMB_Q3TorchFlame (vec3_t org, float size)
{
	static double flametime = 0;

	if (flametime + 0.125 < cl.time || flametime >= cl.time)
		flametime = cl.time;
	else
		return;

	if (fabs(cl.ctime - cl.oldtime))
		AddParticle (p_q3flame, org, 1, size, 0.25, NULL, zerodir);
}

void QMB_ShamblerCharge (vec3_t org)
{
	vec3_t	pos, vec, dir;
	col_t	col = {60, 100, 240, 128};
	float	time, len;
	int	i;

	for (i=0 ; i<5 ; i++)
	{
		VectorClear(vec);
		VectorClear(dir);

		VectorCopy(org, pos);
		pos[0] += (rand() % 200) - 100;
		pos[1] += (rand() % 200) - 100;
		pos[2] += (rand() % 200) - 100;

		VectorSubtract(pos, org, vec);
		len = VectorLength (vec);
		VectorNormalize (vec);
		VectorMA(dir, -200, vec, dir);
		time = len / 200;

		AddParticle (p_streakwave, pos, 1, 3, time, col, dir);
	}
}

void QMB_LaserSight (void)
{
	float		frametime	= fabs(cl.time - cl.oldtime);
	col_t		color;
	int			c;

	extern cvar_t	r_laserpoint;
	extern cvar_t	scr_ofsx;
	//extern cvar_t	cl_gun_offset;

	//blubs-- Issue with this is that there's no particle texture assigned, need to either create, or fix rendering of null particle texture.
	vec3_t	dest, start, stop, forward, right,up;
	trace_t	trace;

	if (!particle_mode)
		return;

	if (frametime)
	{
		if (qmb_initialized)
		{
			VectorClear(stop);
			AngleVectors (r_refdef.viewangles,  forward, right, up);
			VectorCopy(cl_entities[cl.viewentity].origin, start);

			start[2] +=  16;
			start[2] += cl.crouch + bound(-7, scr_ofsx.value, 4);

			VectorMA (start, 0, right, start);
			VectorMA (start, 4096, forward, dest);

			c = lt_default;

			switch ((int)r_laserpoint.value)
			{
				case 1:
					color[0] = color[0] = 000;color[1] = 000;color[2] = 255;color[3] = 50;//B
					c = lt_blue;
					break;
				case 2:
					color[0] = 255;color[1] = 000;color[2] = 000;color[3] = 50;//R
					c = lt_red;
					break;
				case 3:
					color[0] = 255;color[1] = 255;color[2] = 000;color[3] = 50;//Y
					//c = lt_yellow;
                    c = lt_red;
					break;
				case 4:
					color[0] = 000;color[1] = 255;color[2] = 000;color[3] = 50;//G
					c = lt_green;
					break;
			}

			memset (&trace, 0, sizeof(trace_t));
			trace.fraction = 1;
			SV_RecursiveHullCheck(cl.worldmodel->hulls, 0, 0, 1, start, dest, &trace);

			start[2]+=cl.crouch;
			AddParticle (p_streaktrail, start, 1, 2, 0.02, color, trace.endpos);// draw the line
			//the 2 value above is size

			if (trace.fraction != 1)
			{
				color[3] = 200;
				AddParticle (p_dot, trace.endpos, 1, 4, 0.01, color, zerodir);//pinpoint on wall
				if ((cl.maxclients < 2) && (cl.time > cl.laser_point_time))
				{
					CL_NewDlight (0, trace.endpos, (rand() % 10 + 30), 0.02, c);
					cl.laser_point_time = cl.time + 0.02;
				}
			}
		}
	}
}

void QMB_Lightning_Splash(vec3_t org)
{
	int      i, j;
	vec3_t   neworg, angle;
	col_t   color;
	col_t	col2 = {200, 100, 100, 255};

	VectorSet (color, 40, 40, 128);
	VectorClear (angle);

	for (i=0 ; i<5 ; i++)
	{
	  angle[2] = 0;
	  for (j=0 ; j<5 ; j++)
	  {
			AngleVectors (angle, NULLVEC, NULLVEC, neworg);
			VectorMA (org, 20, neworg, neworg);
			AddParticle (p_spark, org, 2, 85, 0.05f, NULL, zerodir);
			AddParticle (p_spark, org, 2, 100, 0.1f, col2, neworg);
			angle[2] += 360 / 5;
	  }
	  angle[0] += 180 / 5;
	}
	color[0] = 224 + (rand() & 31);
	color[1] = 100 + (rand() & 31);
	color[2] = 0;

	AddParticle (p_spark, org, 1, 70, 0.2, color, zerodir);
}

void QMB_LightningBeam (vec3_t start, vec3_t end)
{
	float		frametime	= fabs(cl.time - cl.oldtime);
	col_t		color		= {255,255,255,255};
	trace_t		trace;

	if (frametime)
	{
		if (qmb_initialized && r_part_lightning.value )
		{
			if (qmb_initialized && r_part_sparks.value)
			{
				memset (&trace, 0, sizeof(trace_t));
				if (!SV_RecursiveHullCheck(cl.worldmodel->hulls, 0, 0, 1, start, end, &trace))
				{
					if (trace.fraction < 1)
					{
						VectorCopy (trace.endpos, end);
						if ((r_decal_sparks.value) && (particle_mode) && (decals_enabled))
						{
							R_SpawnDecalStatic(end, decal_glow, 10);
						}
						QMB_Lightning_Splash (end);
					}
				}
			}

			//R00k v1.84 moved down here
			AddParticle(p_lightningbeam, start, 1, 80, host_frametime * 2, color, end);
		}
	}
}

void R_DrawQ3Model (entity_t *ent);

void QMB_Q3Gunshot (vec3_t org, int skinnum, float alpha)
{
	vec3_t		neworg, normal, v, newend;
	entity_t	*ent;
	extern model_t *cl_q3gunshot_mod;

	if (!(ent = CL_NewTempEntity()))
		return;

	VectorCopy (org, ent->origin);
	ent->model = cl_q3gunshot_mod;

	VectorCopy (cl_entities[cl.viewentity].origin, neworg);
	VectorSubtract (ent->origin, neworg, v);
	VectorScale (v, 2, v);
	VectorAdd (neworg, v, newend);

	if (TraceLineN(neworg, newend, newend, normal))
		vectoangles (normal, ent->angles);

	ent->skinnum = skinnum;
	ent->rendermode = TEX_ADDITIVE;
	ent->renderamt = alpha;

	R_DrawQ3Model (ent);
}

void QMB_Q3Teleport (vec3_t org, float alpha)
{
	entity_t	*ent;
	extern model_t *cl_q3teleport_mod;

	if (!(ent = CL_NewTempEntity()))
		return;

	VectorCopy (org, ent->origin);
	ent->model = cl_q3teleport_mod;
	ent->rendermode = TEX_ADDITIVE;
	ent->renderamt = alpha;

	R_DrawQ3Model (ent);
}

#define NUMVERTEXNORMALS	162

extern	float	r_avertexnormals[NUMVERTEXNORMALS][3];
extern vec3_t		avelocities[NUMVERTEXNORMALS];

/*
===============
R_EntityParticles
===============
*/
void QMB_EntityParticles (entity_t *ent)
{
	int			i;
	float		angle, dist, sr, sp, sy, cr, cp, cy;
	vec3_t		forward, org;
	col_t		color = {255,255,0,100};

	dist = 64;

	if (!avelocities[0][0])
		for (i=0 ; i<NUMVERTEXNORMALS*3 ; i++)
			avelocities[0][i] = (rand() & 255) * 0.01;

	for (i=0 ; i<NUMVERTEXNORMALS ; i++)
	{
		angle = cl.time * avelocities[i][0];
		#ifdef PSP_VFPU
		sy = vfpu_sinf(angle);
		cy = vfpu_cosf(angle);
		#else
		sy = sin(angle);
		cy = cos(angle);
		#endif
		angle = cl.time * avelocities[i][1];
		#ifdef PSP_VFPU
		sp = vfpu_sinf(angle);
		cp = vfpu_cosf(angle);
		#else
		sp = sin(angle);
		cp = cos(angle);
		#endif
		angle = cl.time * avelocities[i][2];
		#ifdef PSP_VFPU
		sr = vfpu_sinf(angle);
		cr = vfpu_cosf(angle);
		#else
		sr = sin(angle);
		cr = cos(angle);
		#endif

		forward[0] = cp*cy;
		forward[1] = cp*sy;
		forward[2] = -sp;

		org[0] = ent->origin[0] + r_avertexnormals[i][0]*dist + forward[0]*16;
		org[1] = ent->origin[1] + r_avertexnormals[i][1]*dist + forward[1]*16;
		org[2] = ent->origin[2] + r_avertexnormals[i][2]*dist + forward[2]*16;
		AddParticle (p_flare, org, 1, 2,0.005, color, forward);
	}
}

//Modified from Quake2
void QMB_FlyParticles (vec3_t origin, int count)
{
	float		frametime	= fabs(cl.time - cl.oldtime);
    int         i;
    float       angle, sr, sp, sy, cr, cp, cy;
    vec3_t      forward, org;
    float       dist = 64;
	col_t		color = {255,255,255,100};

    if (frametime)
	{
		if (count > NUMVERTEXNORMALS)
			count = NUMVERTEXNORMALS;

		if (!avelocities[0][0])
		{
			for (i=0 ; i<NUMVERTEXNORMALS*3 ; i++)
				avelocities[0][i] = (rand()&255) * 0.01;
		}

		for (i=0 ; i<count ; i+=2)
		{
			angle = cl.time * avelocities[i][0];
			#ifdef PSP_VFPU
			sy = vfpu_sinf(angle);
			cy = vfpu_cosf(angle);
			#else
			sy = sin(angle);
			cy = cos(angle);
			#endif
			angle = cl.time * avelocities[i][1];
			#ifdef PSP_VFPU
			sp = vfpu_sinf(angle);
			cp = vfpu_cosf(angle);
			#else
			sp = sin(angle);
			cp = cos(angle);
			#endif
			angle = cl.time * avelocities[i][2];
			#ifdef PSP_VFPU
			sr = vfpu_sinf(angle);
			cr = vfpu_cosf(angle);
			#else
			sr = sin(angle);
			cr = cos(angle);
			#endif

			forward[0] = cp*cy;
			forward[1] = cp*sy;
			forward[2] = -sp;

			#ifdef PSP_VFPU
			dist = vfpu_sinf(cl.time + i)*64;
			#else
			dist = sin(cl.time + i)*64;
			#endif
			org[0] = origin[0] + r_avertexnormals[i][0]*dist + forward[0]*32;
			org[1] = origin[1] + r_avertexnormals[i][1]*dist + forward[1]*32;
			org[2] = origin[2] + r_avertexnormals[i][2]*dist + forward[2]*32;

			AddParticle (p_fly, org, 1, 1,0.01, color, forward);
		}
	}
}

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

/*
===============
R_ToggleParticles_f

function that toggles between classic and QMB particles
===============
*/
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
