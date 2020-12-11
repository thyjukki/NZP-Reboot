
extern"C"
{
#include "../quakedef.h"
}

/*
 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    Half-Life Model Renderer (Experimental) Copyright (C) 2001 James 'Ender' Brown [ender@quakesrc.org] This program is
    free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as
    published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
    details. You should have received a copy of the GNU General Public License along with this program; if not, write
    to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. fromquake.h -

	render.c - apart from calculations (mostly range checking or value conversion code is a mix of standard Quake 1
	meshing, and vertex deforms. The rendering loop uses standard Quake 1 drawing, after SetupBones deforms the vertex.
 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  Also, please note that it won't do all hl models....
  Nor will it work 100%
++++++++++++++++++++++++++
  modify by Crow_bar 2009
  10.08.09
++++++++++++++++++++++++++
 */
#include "video_hardware_hlmdl.h"

#include <pspgu.h>
#include <pspgum.h>
#include <list>
using namespace std;
extern list<int> mapTextureNameList;

extern model_t	*loadmodel;

extern vec3_t lightcolor; // LordHavoc: .lit support
extern entity_t	*currententity;
extern float	*shadedots;
extern vec3_t	shadevector;
extern float	shadelight, ambientlight;
#define NUMVERTEXNORMALS	162
extern float r_avertexnormals[NUMVERTEXNORMALS][3];
#define SHADEDOT_QUANT 16
extern float	r_avertexnormal_dots[SHADEDOT_QUANT][256];

void QuaternionGLMatrix(float x, float y, float z, float w, vec4_t *GLM)
{
    GLM[0][0] = 1 - 2 * y * y - 2 * z * z;
    GLM[1][0] = 2 * x * y + 2 * w * z;
    GLM[2][0] = 2 * x * z - 2 * w * y;
    GLM[0][1] = 2 * x * y - 2 * w * z;
    GLM[1][1] = 1 - 2 * x * x - 2 * z * z;
    GLM[2][1] = 2 * y * z + 2 * w * x;
    GLM[0][2] = 2 * x * z + 2 * w * y;
    GLM[1][2] = 2 * y * z - 2 * w * x;
    GLM[2][2] = 1 - 2 * x * x - 2 * y * y;
}

/*
 =======================================================================================================================
    QuaternionGLAngle - Convert a GL angle to a quaternion matrix
 =======================================================================================================================
 */
void QuaternionGLAngle(const vec3_t angles, vec4_t quaternion)
{
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    float	yaw = angles[2] * 0.5;
    float	pitch = angles[1] * 0.5;
    float	roll = angles[0] * 0.5;
    float	siny = sin(yaw);
    float	cosy = cos(yaw);
    float	sinp = sin(pitch);
    float	cosp = cos(pitch);
    float	sinr = sin(roll);
    float	cosr = cos(roll);
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

    quaternion[0] = sinr * cosp * cosy - cosr * sinp * siny;
    quaternion[1] = cosr * sinp * cosy + sinr * cosp * siny;
    quaternion[2] = cosr * cosp * siny - sinr * sinp * cosy;
    quaternion[3] = cosr * cosp * cosy + sinr * sinp * siny;
}





matrix3x4 transform_matrix[128];	/* Vertex transformation matrix */

int				g_chrome[MAXSTUDIOVERTS][2];	// texture coords for surface normals
int				g_chromeage[MAXSTUDIOBONES];	// last time chrome vectors were updated
vec3_t			g_chromeup[MAXSTUDIOBONES];		// chrome vector "up" in bone reference frames
vec3_t			g_chromeright[MAXSTUDIOBONES];	// chrome vector "right" in bone reference frames
vec3_t          g_vright = { 50, 50, 0 };
vec3_t			*g_pvlightvalues;
vec3_t			g_blightvec[MAXSTUDIOBONES];	// light vectors in bone reference frames
vec3_t			g_lightvalues[MAXSTUDIOVERTS];	// light surface normals
vec3_t			g_lightvec;						// light vector in model reference frame
vec3_t			g_lightcolor;
int				g_smodels_total;				// cookie
vec3_t          m_angles;

void GL_Draw_HL_AliasFrame(short *order, vec3_t *transformed, float tex_w, float tex_h, float				*lv);
void GL_Draw_HL_AliasChrome(short *order, vec3_t *transformed, float tex_w, float tex_h, float				*lv);

/*
=======================================================================================================================
    Mod_LoadHLModel - read in the model's constituent parts
=======================================================================================================================
*/

extern char loadname[];
extern int  nonetexture;
qboolean Mod_LoadHLModel (model_t *mod, void *buffer)
{
    /*~~*/
    int i;

	hlmodelcache_t *model;
	hlmdl_header_t *header;
	hlmdl_tex_t	*tex;
	hlmdl_bone_t	*bones;
	hlmdl_bonecontroller_t	*bonectls;
	int					start, end, total;
	/*~~*/
	start = Hunk_LowMark ();
	//load the model into hunk
	model = static_cast<hlmodelcache_t*>(Hunk_Alloc(sizeof(hlmodelcache_t)));

	header = static_cast<hlmdl_header_t*>(Hunk_Alloc(com_filesize));
	memcpy(header, buffer, com_filesize);

	if (header->version != 10)
	{
		Con_Printf("Cannot load model %s - unknown version %i\n", mod->name, header->version);
		Hunk_FreeToLowMark(start);
		return qfalse;
	}

    tex = (hlmdl_tex_t *) ((byte *) header + header->textures);
    bones = (hlmdl_bone_t *) ((byte *) header + header->boneindex);
    bonectls = (hlmdl_bonecontroller_t *) ((byte *) header + header->controllerindex);

	model->header = (char *)header - (char *)model;
    Con_Printf("HLMDL Load: header");

	model->textures = (char *)tex - (char *)model;
    Con_Printf(", tex");

	model->bones = (char *)bones - (char *)model;
    Con_Printf(", bones");

	model->bonectls = (char *)bonectls - (char *)model;
    Con_Printf(", bonectls\n");

	for(i = 0; i < header->numtextures; i++)
    {

		tex[i].i = GL_LoadPalTex (tex[i].name, tex[i].w, tex[i].h, (byte *) header + tex[i].i, qtrue, GU_LINEAR, 0, (byte *) header + tex[i].w * tex[i].h + tex[i].i, PAL_RGB);
	    mapTextureNameList.push_back(tex[i].i); // for unload textures
	}
//
// move the complete, relocatable alias model to the cache
//
	end = Hunk_LowMark ();

	total = end - start;

	mod->type = mod_halflife;

	Cache_Alloc (&mod->cache, total, loadname);

	if (!mod->cache.data)
		return qfalse;

	memcpy (mod->cache.data, model, total);

	Hunk_FreeToLowMark (start);
	return qtrue;
}

/*
======================================================================================================================
    HL_CurSequence - return the current sequence


======================================================================================================================
*/
int HL_CurSequence(hlmodel_t model)
{
    return model.sequence;
}

/*
=======================================================================================================================
    HL_NewSequence - animation control (just some range checking really)
=======================================================================================================================
*/
int HL_NewSequence(hlmodel_t *model, int _inew)
{
    if(_inew < 0)
        _inew = model->header->numseq - 1;
    else if(_inew >= model->header->numseq)
        _inew = 0;

    model->sequence = _inew;
    model->frame = 0;
    {
        /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
        hlmdl_sequencelist_t	*pseqdesc;
        /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

        if(_inew == 0)
        {
            pseqdesc = (hlmdl_sequencelist_t *) ((byte *) model->header + model->header->seqindex) + model->sequence;
        }
        else
        {
            pseqdesc = (hlmdl_sequencelist_t *) ((byte *) model->header + model->header->seqindex) + model->sequence;
        }

        Sys_Printf("Current Sequence: %s\n", pseqdesc->name);
    }

    return model->sequence;
}

/*
=======================================================================================================================
    HL_SetController - control where the model is facing (upper body usually)
=======================================================================================================================
 */
void HL_SetController(hlmodel_t *model, int num, float value)
{
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    int						real, limit;
    hlmdl_bonecontroller_t	*control = (hlmdl_bonecontroller_t *)
                                      ((byte *) model->header + model->header->controllerindex);
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

    if(num >= model->header->numcontrollers) return;

    if(num == 4)
    {
        limit = 64;
    }
    else
    {
        limit = 255;
    }

    if(control->type & (0x0008 | 0x0010 | 0x0020))
    {
        if(control->end < control->start) value = -value;

        if(control->start + 359.0 >= control->end)
        {
            if(value > ((control->start + control->end) / 2.0) + 180) value = value - 360;
            if(value < ((control->start + control->end) / 2.0) - 180) value = value + 360;
        }
        else
        {
            if(value > 360)
                value = value - (int) (value / 360.0) * 360.0;
            else if(value < 0)
                value = value + (int) ((value / -360.0) + 1) * 360.0;
        }
    }

    real = limit * (value - control[num].start) / (control[num].end - control[num].start);
    if(real < 0) real = 0;
    if(real > limit) real = limit;
    model->controller[num] = real;
}

/*
=======================================================================================================================
    HL_CalculateBones - calculate bone positions - quaternion+vector in one function
=======================================================================================================================
 */
void HL_CalculateBones(int offset, int frame, vec4_t adjust, hlmdl_bone_t	*bone, hlmdl_anim_t	*animation, float *destination)
{
    /*~~~~~~~~~~*/
    int		i;
    vec3_t	angle;
    /*~~~~~~~~~~*/

    /* For each vector */
    for(i = 0; i < 3; i++)
    {
        /*~~~~~~~~~~~~~~~*/
        int o = i + offset;        /* Take the value offset - allows quaternion & vector in one function */
        /*~~~~~~~~~~~~~~~*/

        angle[i] = bone->value[o];	/* Take the bone value */

        if(animation->offset[o] != 0)
        {
            /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
            int					tempframe = frame;
            hlmdl_animvalue_t	*animvalue = (hlmdl_animvalue_t *) ((byte *) animation + animation->offset[o]);
            /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

            /* find values including the required frame */
            while(animvalue->num.total <= tempframe)
            {
                tempframe -= animvalue->num.total;
                animvalue += animvalue->num.valid + 1;
            }
            if(animvalue->num.valid > tempframe)
            {
                if(animvalue->num.valid > (tempframe + 1))
                    angle[i] += animvalue[tempframe + 1].value * 1; // + 0 * animvalue[tempframe + 2].value * bone->scale[o];
                else
                    angle[i] = animvalue[animvalue->num.valid].value;
                angle[i] = bone->value[o] + angle[i] * bone->scale[o];
            }
            else
            {
                if(animvalue->num.total <= tempframe + 1)
                {
                    angle[i] +=
                        (animvalue[animvalue->num.valid].value * 1 +
                         0 * animvalue[animvalue->num.valid + 2].value) *
                        bone->scale[o];
                }
                else
                {
                    angle[i] += animvalue[animvalue->num.valid].value * bone->scale[o];
                }
            }
        }

        if(bone->bonecontroller[o] != -1) {	/* Add the programmable offset. */
            angle[i] += adjust[bone->bonecontroller[o]];
        }
    }

    if(offset < 3)
    {
        VectorCopy(angle, destination);			/* Just a standard vector */
    }
    else
    {
        QuaternionGLAngle(angle, destination);	/* A quaternion */
    }
}

/*
=======================================================================================================================
    HL_CalcBoneAdj - Calculate the adjustment values for the programmable controllers
=======================================================================================================================
 */
void HL_CalcBoneAdj(hlmodel_t *model)
{
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    int						i;
    float					value;
    hlmdl_bonecontroller_t	*control = (hlmdl_bonecontroller_t *)
                                      ((byte *) model->header + model->header->controllerindex);
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

    for(i = 0; i < model->header->numcontrollers; i++)
    {
        /*~~~~~~~~~~~~~~~~~~~~~*/
        int j = control[i].index;
        /*~~~~~~~~~~~~~~~~~~~~~*/
/*
        if(control[i].type & 0x8000)
        {
            value = model->controller[j] + control[i].start;
        }
        else
        {
            value = model->controller[j];
            if(value < 0)
                value = 0;
            else if(value > 1.0)
                value = 1.0;
            value = (1.0 - value) * control[i].start + value * control[i].end;
        }
*/

		if (j <= 3)
		{
			// check for 360% wrapping
			if (control[i].type & STUDIO_RLOOP)
			{
				value = model->controller[j] * (360.0/256.0) + control[i].start;
			}
			else
			{
				value = model->controller[j] / 255.0;
				if (value < 0)
				 value = 0;
				if (value > 1.0)
				 value = 1.0;
				value = (1.0 - value) * control[i].start + value * control[i].end;
			}
			// Con_DPrintf( "%d %d %f : %f\n", m_controller[i], m_prevcontroller[i], value, dadt );
		}
		else
		{
			value = /*model->mouth*/1 / 64.0;
			if (value > 1.0)
			 value = 1.0;
			value = (1.0 - value) * control[i].start + value * control[i].end;
			// Con_DPrintf("%d %f\n", mouthopen, value );
		}

	    /* Rotational controllers need their values converted */
		switch(control[i].type & STUDIO_TYPES)
		{
		case STUDIO_XR:
		case STUDIO_YR:
		case STUDIO_ZR:
			model->adjust[i] = value * (M_PI / 180.0);
			break;
		case STUDIO_X:
		case STUDIO_Y:
		case STUDIO_Z:
			model->adjust[i] = value;
			break;
		}
	}
}

/*
=======================================================================================================================
    HL_SetupBones - determine where vertex should be using bone movements
=======================================================================================================================
 */
void HL_SetupBones(hlmodel_t *model)
{
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    int						i;
    float					matrix[3][4];
    static vec3_t			positions[128];
    static vec4_t			quaternions[128];
    hlmdl_sequencelist_t	*sequence = (hlmdl_sequencelist_t *) ((byte *) model->header + model->header->seqindex) +
                                     model->sequence;
    hlmdl_sequencedata_t	*sequencedata = (hlmdl_sequencedata_t *)
                                         ((byte *) model->header + model->header->seqgroups) +
                                         sequence->seqindex;
    hlmdl_anim_t			*animation = (hlmdl_anim_t *)
                                ((byte *) model->header + sequencedata->data + sequence->index);
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

    HL_CalcBoneAdj(model);	/* Deal with programmable controllers */

    if(sequence->motiontype & STUDIO_X)
	 positions[sequence->motionbone][0] = 0.0;
    if(sequence->motiontype & STUDIO_Y)
	 positions[sequence->motionbone][1] = 0.0;
    if(sequence->motiontype & STUDIO_Z)
	 positions[sequence->motionbone][2] = 0.0;

    /* Sys_Printf("Frame: %i\n", model->frame); */
    for(i = 0; i < model->header->numbones; i++)
    {
        /*
         * There are two vector offsets in the structure. The first seems to be the
         * positions of the bones, the second the quats of the bone matrix itself. We
         * convert it inside the routine - Inconsistant, but hey.. so's the whole model
         * format.
         */
        HL_CalculateBones(0, model->frame, model->adjust, model->bones + i, animation + i, positions[i]);
        HL_CalculateBones(3, model->frame, model->adjust, model->bones + i, animation + i, quaternions[i]);

        /* FIXME: Blend the bones and make them cry :) */
        QuaternionGLMatrix(quaternions[i][0], quaternions[i][1], quaternions[i][2], quaternions[i][3], matrix);
        matrix[0][3] = positions[i][0];
        matrix[1][3] = positions[i][1];
        matrix[2][3] = positions[i][2];

        /* If we have a parent, take the addition. Otherwise just copy the values */
        if(model->bones[i].parent>=0)
        {
            R_ConcatTransforms(transform_matrix[model->bones[i].parent], matrix, transform_matrix[i]);
        }
        else
        {
            memcpy(transform_matrix[i], matrix, 12 * sizeof(float));
        }
    }
}

/*
=======================================================================================================================
    Chrome
=======================================================================================================================
*/
/*
================
TransformFinalVert
================
*/
void Lighting (float *lv, int bone, int flags, vec3_t normal)
{
	float 	illum;
	float	lightcos;

	illum = ambientlight;

	if (flags & STUDIO_NF_FLATSHADE)
	{
		illum += shadelight * 0.8;
	}
	else
	{
		float r;
		lightcos = DotProduct (normal, g_blightvec[bone]); // -1 colinear, 1 opposite

		if (lightcos > 1.0)
			lightcos = 1;

		illum += shadelight;

		//r = g_lambert;
		//if (r <= 1.0)
		  r = 1.0;

		lightcos = (lightcos + (r - 1.0)) / r; 		// do modified hemispherical lighting
		if (lightcos > 0.0)
		{
			illum -= shadelight * lightcos;
		}
		if (illum <= 0)
			illum = 0;
	}

	if (illum > 255)
		illum = 255;
	*lv = illum / 255.0;	// Light from 0 to 1.0
}

void VectorIRotate (const vec3_t in1, const float in2[3][4], vec3_t out)
{
	out[0] = in1[0]*in2[0][0] + in1[1]*in2[1][0] + in1[2]*in2[2][0];
	out[1] = in1[0]*in2[0][1] + in1[1]*in2[1][1] + in1[2]*in2[2][1];
	out[2] = in1[0]*in2[0][2] + in1[1]*in2[1][2] + in1[2]*in2[2][2];
}

void SetupLighting ( hlmodel_t *model )
{ // dr_mabuse1981: edited abit to make halflife model NOT look ughly and for Shpulds model brightness cvar
	int i;
	if(r_model_brightness.value)
	ambientlight = 256;	
	else
	ambientlight = 128;
	shadelight = 33;

	g_lightvec[0] = shadevector[0];
	g_lightvec[1] = shadevector[1];
	g_lightvec[2] = shadevector[2];

	g_lightcolor[0] = lightcolor[0];
	g_lightcolor[1] = lightcolor[1];
	g_lightcolor[2] = lightcolor[2];

	// TODO: only do it for bones that actually have textures
	for (i = 0; i < model->header->numbones; i++)
	{
		VectorIRotate( g_lightvec, transform_matrix[i], g_blightvec[i] );
	}
}

void Chrome (int *pchrome, int bone, vec3_t normal)
{
	float n;

	if (g_chromeage[bone] != g_smodels_total)
	{
		// calculate vectors from the viewer to the bone. This roughly adjusts for position
		vec3_t chromeupvec;		// g_chrome t vector in world reference frame
		vec3_t chromerightvec;	// g_chrome s vector in world reference frame
		vec3_t tmp;				// vector pointing at bone in world reference frame
		VectorScale( m_angles, -1, tmp );
		tmp[0] += transform_matrix[bone][0][3];
		tmp[1] += transform_matrix[bone][1][3];
		tmp[2] += transform_matrix[bone][2][3];
		VectorNormalize( tmp );
		CrossProduct( tmp, g_vright, chromeupvec );
		VectorNormalize( chromeupvec );
		CrossProduct( tmp, chromeupvec, chromerightvec );
		VectorNormalize( chromerightvec );
		VectorIRotate( chromeupvec, transform_matrix[bone], g_chromeup[bone] );
		VectorIRotate( chromerightvec, transform_matrix[bone], g_chromeright[bone] );
		g_chromeage[bone] = g_smodels_total;
	}
	// calc s coord
	n = DotProduct( normal, g_chromeright[bone] );
	pchrome[0] = (n + 1.0) * 32; // FIX: make this a float
	// calc t coord
	n = DotProduct( normal, g_chromeup[bone] );
	pchrome[1] = (n + 1.0) * 32; // FIX: make this a float
}

/*
=======================================================================================================================
    R_Draw_HL_AliasModel - main drawing function
=======================================================================================================================
*/
void R_DrawHLModel(entity_t	*curent)
{
    /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
	hlmodelcache_t *modelc = static_cast<hlmodelcache_t*>(Mod_Extradata(curent->model));
	hlmodel_t model;
    int						b, m, v;
    short					*skins;
    hlmdl_sequencelist_t	*sequence;
    float				*lv;
    float				lv_tmp;
	int			lnum;
	vec3_t		dist;
	float		add;
	/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

	//general model
	model.header	= (hlmdl_header_t *)			((char *)modelc + modelc->header);
	model.textures	= (hlmdl_tex_t *)				((char *)modelc + modelc->textures);
	model.bones		= (hlmdl_bone_t *)				((char *)modelc + modelc->bones);
	model.bonectls	= (hlmdl_bonecontroller_t *)	((char *)modelc + modelc->bonectls);

	//specific to entity
	model.sequence	= curent->frame;
	model.frame		= 0;
	model.frametime	= 0;

	HL_NewSequence(&model, curent->frame);

    skins = (short *) ((byte *) model.header + model.header->skins);
    sequence = (hlmdl_sequencelist_t *) ((byte *) model.header + model.header->seqindex) +
                                     model.sequence;

	model.controller[0] = curent->bonecontrols[0];
	model.controller[1] = curent->bonecontrols[1];
	model.controller[2] = curent->bonecontrols[2];
	model.controller[3] = curent->bonecontrols[3];

    model.frametime += (cl.time /* - cl.lerpents[curent->keynum].framechange*/)*sequence->timing;

	if (model.frametime>=1)
	{
		model.frame += (int) model.frametime;
		model.frametime -= (int)model.frametime;
	}

	if (!sequence->numframes)
		return;
/*
	if(model.frame >= sequence->numframes)
		model.frame %= sequence->numframes;
*/
		model.frame = curent->frame; // dr_mabuse1981: This makes your Halflife model frame based (only for sequence 0 atm but better than the old shit.)
	if (sequence->motiontype)
		model.frame = sequence->numframes-1;

    sceGuTexFunc(GU_TFX_MODULATE, GU_TCC_RGBA);
    sceGuShadeModel(GU_SMOOTH);

	Con_Printf("%s %i\n", sequence->name, sequence->unknown1[0]);

    sceGumPushMatrix();

	for(int i = 0; i < 3; i++) m_angles[i] = currententity->angles[i];

    R_LightPoint(curent->origin); // LordHavoc: lightcolor is all that matters from this

	for (lnum=0 ; lnum<MAX_DLIGHTS ; lnum++)
	{
		if (cl_dlights[lnum].die >= cl.time)
		{
			VectorSubtract (currententity->origin,
							cl_dlights[lnum].origin,
							dist);
			add = cl_dlights[lnum].radius - Length(dist);

			// LordHavoc: .lit support begin
			if (add > 0)
			{
				lightcolor[0] += add * cl_dlights[lnum].color[0];
				lightcolor[1] += add * cl_dlights[lnum].color[1];
				lightcolor[2] += add * cl_dlights[lnum].color[2];
			}
			// LordHavoc: .lit support end
		}
	}

    VectorScale(lightcolor, 1.0f / 200.0f, lightcolor);

    float an;
	an = curent->angles[1]/180*M_PI;
	shadevector[0] = cosf(-an);
	shadevector[1] = sinf(-an);
	shadevector[2] = 1;
	VectorNormalize (shadevector);

	R_BlendedRotateForEntity(curent, 0);

    HL_SetupBones(&model);	/* Setup the bones */
    SetupLighting(&model);	/* Setup the light */

    g_smodels_total++; // render data cache cookie

	g_pvlightvalues = &g_lightvalues[0];

    /* Manipulate each mesh directly */
    for(b = 0; b < model.header->numbodyparts; b++)
    {
        /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
        hlmdl_bodypart_t	*bodypart = (hlmdl_bodypart_t *) ((byte *) model.header + model.header->bodypartindex) +
                                     b;
        int					bodyindex = (0 / bodypart->base) % bodypart->nummodels;
        hlmdl_model_t		*amodel = (hlmdl_model_t *) ((byte *) model.header + bodypart->modelindex) + bodyindex;
        byte				*bone = ((byte *) model.header + amodel->vertinfoindex);
        byte				*nbone = ((byte *) model.header + amodel->norminfoindex);
        vec3_t				*verts = (vec3_t *) ((byte *) model.header + amodel->vertindex);
        vec3_t				*norms = (vec3_t *) ((byte *) model.header + amodel->normindex);
        vec3_t				transformed[2048];
        /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


        for(v = 0; v < amodel->numverts; v++)			// Transform per the matrix
		{
            VectorTransform(verts[v], transform_matrix[bone[v]], transformed[v]);
		}

 		lv = (float *)g_pvlightvalues;
        for(m = 0; m < amodel->nummesh; m++)
        {
			/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
            hlmdl_mesh_t	*mesh = (hlmdl_mesh_t *) ((byte *) model.header + amodel->meshindex) + m;
            float			tex_w = 1.0f / model.textures[skins[mesh->skinindex]].w;
            float			tex_h = 1.0f / model.textures[skins[mesh->skinindex]].h;
            int             flags = model.textures[skins[mesh->skinindex]].flags;
            /*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

		    for (int c = 0; c < mesh->numnorms; c++, lv += 3, norms++, nbone++)
			{
                Lighting (&lv_tmp, *nbone, flags, (float *)norms);
				// FIX: move this check out of the inner loop
				if (flags & STUDIO_NF_CHROME)
				 	Chrome(g_chrome[(float (*)[3])lv - g_pvlightvalues], *nbone, (float *)norms );

			    lv[0] = lv_tmp * g_lightcolor[0];
			    lv[1] = lv_tmp * g_lightcolor[1];
			    lv[2] = lv_tmp * g_lightcolor[2];
			}

			if (model.textures[skins[mesh->skinindex]].flags & STUDIO_NF_CHROME)
		    {
   			    GL_Bind(model.textures[skins[mesh->skinindex]].i);
				GL_Draw_HL_AliasChrome((short *) ((byte *) model.header + mesh->index), transformed, tex_w, tex_h, lv);
			}
		    else
		    {
                GL_Bind(model.textures[skins[mesh->skinindex]].i);
				GL_Draw_HL_AliasFrame((short *) ((byte *) model.header + mesh->index), transformed, tex_w, tex_h, lv);
			}
		}
    }
    sceGuShadeModel(GU_FLAT);
    sceGumPopMatrix();
    sceGumUpdateMatrix();
    sceGuTexFunc(GU_TFX_REPLACE, GU_TCC_RGBA);
}

/*
 =======================================================================================================================
    GL_Draw_HL_AliasFrame - clip and draw all triangles
 =======================================================================================================================
 */
void GL_Draw_HL_AliasFrame(short *order, vec3_t *transformed, float tex_w, float tex_h, float				*lv)
{
    int count = 0;
    while (1)
	{
        count = *order++;

		if (!count)
			break;		// done

		int prim;

        if(count < 0)
        {
            count = -count;
            prim = GU_TRIANGLE_FAN;
        }
        else
		{
            prim = GU_TRIANGLE_STRIP;
		}

        // Allocate the vertices.
		struct vertex
		{
			float u, v;
            unsigned int color;
			float x, y, z;
		};

		vertex* const out = static_cast<vertex*>(sceGuGetMemory(sizeof(vertex) * count));

		for (int vertex_index = 0; vertex_index < count; ++vertex_index)
		{
            float	*verts = transformed[order[0]];

			out[vertex_index].u = order[2] * tex_w;
			out[vertex_index].v = order[3] * tex_h;
			order += 4;

			lv = g_pvlightvalues[order[1]];
			//color clamp
			for(int i = 0; i < 3; i++)
			{
				if(lv[i] > 1)
				   lv[i] = 1;

				if(lv[i] < 0)
				   lv[i] = 0;
            }
			out[vertex_index].x = verts[0];
            out[vertex_index].y = verts[1];
            out[vertex_index].z = verts[2];
            out[vertex_index].color = GU_COLOR(lv[0], lv[1], lv[2], 1.0f);
		}
        if(r_showtris.value)
		{
		   sceGuDisable(GU_TEXTURE_2D);
		}
		sceGuDrawArray(r_showtris.value ? GU_LINE_STRIP : prim, GU_TEXTURE_32BITF | GU_VERTEX_32BITF | GU_COLOR_8888, count, 0, out);
        if(r_showtris.value)
		{
		   sceGuEnable(GU_TEXTURE_2D);
		}
	}
}

void GL_Draw_HL_AliasChrome(short *order, vec3_t *transformed, float tex_w, float tex_h, float				*lv)
{
    int count = 0;
    while (1)
	{
        count = *order++;

		if (!count)
			break;		// done

		int prim;

        if(count < 0)
        {
            count = -count;
            prim = GU_TRIANGLE_FAN;
        }
        else
		{
            prim = GU_TRIANGLE_STRIP;
		}

        // Allocate the vertices.
		struct vertex
		{
			float u, v;
            unsigned int color;
			float x, y, z;
		};

		vertex* const out = static_cast<vertex*>(sceGuGetMemory(sizeof(vertex) * count));

		for (int vertex_index = 0; vertex_index < count; ++vertex_index)
		{
            float	*verts = transformed[order[0]];

			out[vertex_index].u = g_chrome[order[1]][0] * tex_w;
			out[vertex_index].v = g_chrome[order[1]][1] * tex_h;
			order += 4;

			lv = g_pvlightvalues[order[1]];
			//color clamp
			for(int i = 0; i < 3; i++)
			{
				if(lv[i] > 1)
				   lv[i] = 1;

				if(lv[i] < 0)
				   lv[i] = 0;
            }
			out[vertex_index].x = verts[0];
            out[vertex_index].y = verts[1];
            out[vertex_index].z = verts[2];
            out[vertex_index].color = GU_COLOR(lv[0], lv[1], lv[2], 1.0f);
		}
        if(r_showtris.value)
		{
		   sceGuDisable(GU_TEXTURE_2D);
		}
		sceGuDrawArray(r_showtris.value ? GU_LINE_STRIP : prim, GU_TEXTURE_32BITF | GU_VERTEX_32BITF | GU_COLOR_8888, count, 0, out);
        if(r_showtris.value)
		{
		   sceGuEnable(GU_TEXTURE_2D);
		}
	}
}

