/*
Copyright (C) 1996-1997 Id Software, Inc.
Copyright (C) 2007 Peter Mackay and Chris Swindle.
Copyright (C) 2008-2009 Crow_bar.

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

// draw.c -- this is the only file outside the refresh that touches the
// vid buffer

#include <valarray>
#include <vector>
#include <malloc.h>
#include <pspgu.h>
#include <pspkernel.h>
#include <pspctrl.h>
#include <ctype.h>

extern "C"
{
#include "../quakedef.h"
}

#include "video_hardware_dxtn.h"
#include "video_hardware_resample.h"

#include "vram.hpp"
#include <vram.hpp>

byte		*draw_chars;				// 8*8 graphic characters
qpic_t		*sniper_scope;

int			translate_texture;
int			char_texture;
int			detail_texture;
int			underwater_texture;
//int			zombie_skins[3][8];
int			zombie_skins[2][2];
int         ref_texture;
int         nonetexture;
typedef byte texel;

bool 	 	tex_scale_down = true;

//Loading Fill by Crow_bar
float 	loading_cur_step;
char	loading_name[32];
float 	loading_num_step;

#define CLUT4

typedef struct
{
	// Source.
	char	identifier[64];
	int		original_width;
	int		original_height;
	bool	stretch_to_power_of_two;

	// Texture description.
	int		format;
	int		filter;
	int		width;
	int		height;
	int 	mipmaps;
	int     bpp;
	int     swizzle;
	qboolean islmp;
#ifdef CLUT4
	unsigned char *palette;
	ScePspRGBA8888 *palette_2;
 #else
    ScePspRGBA8888 *palette;
#endif
    qboolean	palette_active;

	// Buffers.
	texel*	ram;
	texel*	vram;
} gltexture_t;

int loadtextureimage (char* filename, int matchwidth, int matchheight, qboolean complain, int filter);
void VID_SetPalette4(unsigned char* clut4pal);
int vid_palmode;

#define	MAX_GLTEXTURES	1024
gltexture_t	gltextures[MAX_GLTEXTURES];
bool 		gltextures_used[MAX_GLTEXTURES];
int			numgltextures;

typedef struct
{
	int			index;	// index into gltextures[].
} glpic_t;

//cvar_t	png_compression_level = {"png_compression_level", "1"};
//cvar_t	jpeg_compression_level = {"jpeg_compression_level", "75"};

void GL_Bind4Part(int texture_index)
{
	const gltexture_t& texture = gltextures[texture_index];
	VID_SetPalette4(texture.palette);
	vid_palmode = GU_PSM_T4;

	sceGuTexMode(texture.format, 0, 0, GU_FALSE);
	sceGuTexFilter(texture.filter, texture.filter);

	const void* const texture_memory = texture.vram ? texture.vram : texture.ram;
	sceGuTexImage(0, texture.width, texture.height, texture.width, texture_memory);
}

void GL_InitTextureUsage ()
{
	for (int i=0; i<MAX_GLTEXTURES; i++) {
		gltextures_used[i] = false;
	}
	numgltextures = 0;
}

//Crow_bar.
int GL_GetTexSize(int format, int w, int h, int bpp)
{
	int size = 0;
	if(bpp == 0 && (format != -1))
	{
		switch(format)
		{
			case GU_PSM_T4:
			case GU_PSM_DXT1:
				size = w*h/2;
				break;
			case GU_PSM_T8:
			case GU_PSM_DXT3:
			case GU_PSM_DXT5:
				size = w*h;
				break;
			case GU_PSM_5650:
			case GU_PSM_5551:
			case GU_PSM_4444:
				size = w*h*2;
				break;
			case GU_PSM_8888:
				size = w*h*4;
				break;
		}
	}
	else
	{
		size = w*h*bpp;
	}
	return size;
}

void GL_Copy(int texture_index, int dx, int dy, int sx, int sy, int w, int h)
{
	 // Which texture is it?
	 const gltexture_t& texture = gltextures[texture_index];

	 // Set the texture image.
	 void* texture_memory = texture.vram ? texture.vram : texture.ram;

	 // texture.width, texture.height, texture.width

	 sceGuCopyImage(texture.format, sx, sy, 480, 272, 512, (void*)(0x04000000+GL_GetDrawBuffer()), dx, dy, texture.width, texture_memory);

	 sceGuTexSync();
}


void VID_SetPaletteTX();
void GL_Bind (int texture_index)
{
	// Binding the currently bound texture?
	if (currenttexture == texture_index)
	{
		// Don't bother.
		return;
	}

	// Remember the current texture.
	currenttexture = texture_index;

	// Which texture is it?
	const gltexture_t& texture = gltextures[texture_index];
	
	if (texture.format == GU_PSM_T4) {
		VID_SetPalette4(texture.palette);
		vid_palmode = GU_PSM_T4;

		sceGuTexMode(texture.format, 0, 0, GU_TRUE);
		sceGuTexFilter(texture.filter, texture.filter);

		const void* const texture_memory = texture.vram ? texture.vram : texture.ram;
		sceGuTexImage(0, texture.width, texture.height, texture.width, texture_memory);
	} else {
				
		if(texture.palette_active == qtrue)
		{
			// Used for wad3 textures with their own palette
			// 	Upload the palette.
			sceGuClutMode(GU_PSM_8888, 0, 255, 0);
			sceKernelDcacheWritebackRange(texture.palette_2, 256);
			sceGuClutLoad(256 /8 , texture.palette_2);
			reloaded_pallete = 0;
		} else {
			// Used for wad2 textures
			VID_SetPaletteTX();
			vid_palmode = GU_PSM_T8;
		}
		
		// Set the texture mode.
		sceGuTexMode(texture.format, texture.mipmaps , 0, texture.swizzle);

		if (texture.mipmaps > 0 && r_mipmaps.value > 0)
		{
			//Con_Printf("asd\n");
			float slope = 0.4f;
			sceGuTexSlope(slope); // the near from 0 slope is the lower (=best detailed) mipmap it uses
			sceGuTexFilter(GU_LINEAR_MIPMAP_LINEAR, GU_LINEAR_MIPMAP_LINEAR);
			sceGuTexLevelMode(int(r_mipmaps_func.value), r_mipmaps_bias.value);
		}
		else {
			// dr_mabuse1981: "retro filter" start.
			if (r_retro.value)	
				sceGuTexFilter(GU_NEAREST, GU_NEAREST);
			else
				sceGuTexFilter(texture.filter, texture.filter);
			// dr_mabuse1981: "retro filter" end.
		}
		
		// Set the texture image.
		const void* const texture_memory = texture.vram ? texture.vram : texture.ram;
		sceGuTexImage(0, texture.width, texture.height, texture.width, texture_memory);

		if (texture.mipmaps > 0 && r_mipmaps.value > 0) {
			int size = (texture.width * texture.height);
			int offset = size;
			int div = 2;

			for (int i = 1; i <= texture.mipmaps; i++) {
				void* const texture_memory2 = ((byte*)texture_memory) + offset;
				sceGuTexImage(i, texture.width / div, texture.height / div, texture.width / div, texture_memory2);
				offset += size / (div*div);
				div *= 2;
			}
		}
	}


}

void GL_BindLM (int texture_index)
{
	// Binding the currently bound texture?
	if (currenttexture == texture_index)
	{
		// Don't bother.
		return;
	}

	// Remember the current texture.
	currenttexture = texture_index;

	// Which texture is it?
	const gltexture_t& texture = gltextures[texture_index];

	// Set the texture mode.
	sceGuTexMode(texture.format, 0, 0, texture.swizzle);
	sceGuTexFilter(texture.filter, texture.filter);

	// Set the texture image.
	const void* const texture_memory = texture.vram ? texture.vram : texture.ram;
	sceGuTexImage(0, texture.width, texture.height, texture.width, texture_memory);
}

void GL_BindDET (int texture_index)
{
    int tex_m = (int)r_detail_mipmaps_func.value;
	// Binding the currently bound texture?
	if (currenttexture == texture_index)
	{
		// Don't bother.
		return;
	}

	// Remember the current texture.
	currenttexture = texture_index;

	// Which texture is it?
	const gltexture_t& texture = gltextures[texture_index];

	// Set the texture mode.
	sceGuTexMode(texture.format, texture.mipmaps , 0, texture.swizzle);

	if (texture.mipmaps > 0 && r_detail_mipmaps.value > 0)
	{
        float slope = 0.4f;
		sceGuTexSlope(slope); // the near from 0 slope is the lower (=best detailed) mipmap it uses
		sceGuTexFilter(GU_LINEAR_MIPMAP_LINEAR, GU_LINEAR_MIPMAP_LINEAR);
		sceGuTexLevelMode(tex_m, r_detail_mipmaps_bias.value); // manual slope setting
	}
	else
		sceGuTexFilter(texture.filter, texture.filter);


	//sceGuTexLevelMode(1, 1.0f); // manual slope setting
	//sceGuTexSlope(0.2f); // the near from 0 slope is the lower (=best detailed) mipmap it uses

	// Set the texture image.
	const void* const texture_memory = texture.vram ? texture.vram : texture.ram;
	sceGuTexImage(0, texture.width, texture.height, texture.width, texture_memory);


	if (texture.mipmaps > 0 && r_detail_mipmaps.value > 0)
	{
		int size = (texture.width * texture.height * texture.bpp);
		int offset = size;
		int div = 2;

		for (int i = 1; i <= texture.mipmaps; i++)
		{
			void* const texture_memory2 = ((byte*) texture_memory)+offset;
            sceGuTexImage(i, texture.width/div, texture.height/div, texture.width/div, texture_memory2);
			offset += size/(div*div);
			div *=2;
		}
	}

}

//=============================================================================
/* Support Routines */

typedef struct cachepic_s
{
	char		name[MAX_QPATH];
	qpic_t		pic;
	byte		padding[32];	// for appended glpic
} cachepic_t;

#define	MAX_CACHED_PICS		128
cachepic_t	menu_cachepics[MAX_CACHED_PICS];
int			menu_numcachepics;

byte		menuplyr_pixels[4096];

static int GL_LoadPicTexture (qpic_t *pic)
{
	return GL_LoadTexture ("", pic->width, pic->height, pic->data, qfalse, GU_NEAREST, 0);
}

qpic_t *Draw_PicFromWad (char *name)
{
	qpic_t	*p;
	glpic_t	*gl;

	p = static_cast<qpic_t*>(W_GetLumpName (name));
	gl = (glpic_t *)p->data;
	gl->index = GL_LoadPicTexture (p);

	return p;
}


/*
================
Draw_CachePic
================
*/
qpic_t	*Draw_CachePic (char *path)
{
	cachepic_t	*pic;
	int			i;
	qpic_t		*dat;
	glpic_t		*gl;
	char		str[128];

	strcpy (str, path);
	for (pic=menu_cachepics, i=0 ; i<menu_numcachepics ; pic++, i++)
		if (!strcmp (str, pic->name))
			return &pic->pic;

	if (menu_numcachepics == MAX_CACHED_PICS)
		Sys_Error ("menu_numcachepics == MAX_CACHED_PICS");
	menu_numcachepics++;
	strcpy (pic->name, str);

//
// load the pic from disk
//

	int index = loadtextureimage (str, 0, 0, qfalse, GU_LINEAR);
	if(index)
	{
		pic->pic.width  = gltextures[index].original_width;
		pic->pic.height = gltextures[index].original_height;

		gltextures[index].islmp = qfalse;
		gl = (glpic_t *)pic->pic.data;
		gl->index = index;

		return &pic->pic;
	}

	dat = (qpic_t *)COM_LoadTempFile (str);
	if (!dat)
	{
		strcat (str, ".lmp");
		dat = (qpic_t *)COM_LoadTempFile (str);
		if (!dat)
		{
			Con_Printf ("Draw_CachePic: failed to load file %s\n", str);
			return NULL;
		}
	}
	SwapPic (dat);


	pic->pic.width = dat->width;
	pic->pic.height = dat->height;

	gl = (glpic_t *)pic->pic.data;
	gl->index = GL_LoadPicTexture (dat);

	gltextures[gl->index].islmp = qtrue;
	return &pic->pic;
}

/*
================
Draw_CachePic
================
*/
qpic_t	*Draw_CacheImg (char *path)
{
	cachepic_t	*pic;
	int			i;
	qpic_t		*dat;
	glpic_t		*gl;

	for (pic=menu_cachepics, i=0 ; i<menu_numcachepics ; pic++, i++)
		if (!strcmp (path, pic->name))
			return &pic->pic;

	if (menu_numcachepics == MAX_CACHED_PICS)
		Sys_Error ("menu_numcachepics == MAX_CACHED_PICS");
	menu_numcachepics++;
	strcpy (pic->name, path);

//
// load the pic from disk
//

	int index = loadtextureimage (path, 0, 0, qfalse, GU_LINEAR);
	if(index != -1)
	{
		pic->pic.width  = gltextures[index].original_width;
		pic->pic.height = gltextures[index].original_height;

		gl = (glpic_t *)pic->pic.data;
		gl->index = index;

		return &pic->pic;
	}

	dat = (qpic_t *)COM_LoadTempFile (path);
	if (!dat)
		dat = (qpic_t *)COM_LoadTempFile ("gfx/error.lmp");
	SwapPic (dat);

	// HACK HACK HACK --- we need to keep the bytes for
	// the translatable player picture just for the menu
	// configuration dialog
	if (!strcmp (path, "gfx/menuplyr.lmp"))
		memcpy (menuplyr_pixels, dat->data, dat->width*dat->height);

	pic->pic.width = dat->width;
	pic->pic.height = dat->height;

	gl = (glpic_t *)pic->pic.data;
	gl->index = GL_LoadPicTexture (dat);

	return &pic->pic;
}


byte nontexdt[8][8] =
{
	{0x43,0x43,0x43,0x43, 0x53,0x53,0x53,0x53},
	{0x43,0x43,0x43,0x43, 0x53,0x53,0x53,0x53},
	{0x43,0x43,0x43,0x43, 0x53,0x53,0x53,0x53},
	{0x43,0x43,0x43,0x43, 0x53,0x53,0x53,0x53},

	{0x53,0x53,0x53,0x53, 0x43,0x43,0x43,0x43},
	{0x53,0x53,0x53,0x53, 0x43,0x43,0x43,0x43},
	{0x53,0x53,0x53,0x53, 0x43,0x43,0x43,0x43},
	{0x53,0x53,0x53,0x53, 0x43,0x43,0x43,0x43},

};

/*
================
R_CreateDlightImage
from Quake3
================
*/
#define	DLIGHT_SIZE	16
static void R_CreateDlightImage( void )
{
	int		x,y;
	byte	data[DLIGHT_SIZE][DLIGHT_SIZE];
	int		b;

	// make a centered inverse-square falloff blob for dynamic lighting
	for (x=0 ; x<DLIGHT_SIZE ; x++)
	{
		for (y=0 ; y<DLIGHT_SIZE ; y++)
		{
			float	d;

			d = ( DLIGHT_SIZE/2 - 0.5f - x ) * ( DLIGHT_SIZE/2 - 0.5f - x ) +
				( DLIGHT_SIZE/2 - 0.5f - y ) * ( DLIGHT_SIZE/2 - 0.5f - y );
			b = 4000 / d;

			if (b > 255)
			{

				b = 255;
			}
			else if ( b < 75 )
			{
				b = 0;
			}

			data[y][x] = b;
		}
	}
	ref_texture = GL_LoadTexture ("reftexture", DLIGHT_SIZE, DLIGHT_SIZE, (byte*)data, qfalse, GU_LINEAR, 0);
}

/*
===============
Draw_Init
===============
*/
void Draw_Init (void)
{
	byte	*detail, *uw;
	int i;

  	// load the console background and the charset
	// by hand, because we need to write the version
	// string into the background before turning
	// it into a texture

	nonetexture = GL_LoadTexture ("nonetexture", 8, 8, (byte*)nontexdt, qfalse, GU_NEAREST, 0);
	R_CreateDlightImage();

	// now turn them into textures
	char_texture = loadtextureimage ("gfx/charset", 0, 0, qfalse, GU_NEAREST);
	if (char_texture == 0)// did not find a matching TGA...
		Sys_Error ("Could not load charset, make sure you have every folder and file installed properly\nDouble check that all of your files are in their correct places\nAnd that you have installed the game properly.\nRefer to the readme.txt file for help\n");

	detail_texture = loadtextureimage ("gfx/detail", 0, 0, qfalse, GU_LINEAR);

	if (detail_texture == 0)// did not find a matching TGA...
	{
		detail = static_cast<byte*>(COM_LoadTempFile ("gfx/detail.lmp"));
		if (!detail)
		{
			//Con_Printf ("Couldn't load gfx/detail \n"); FIXME no point?
			detail_texture = nonetexture;
		}
		else
			detail_texture = GL_LoadTexture ("Detail", 256, 256, detail, qfalse, GU_LINEAR, 3);
	}

	underwater_texture = loadtextureimage ("gfx/uwater", 0, 0, qfalse, GU_LINEAR);
	if (underwater_texture == 0)// did not find a matching TGA...
	{

		uw = static_cast<byte*>(COM_LoadTempFile ("gfx/uwater.lmp"));
		if (!uw)
		{
			Con_Printf ("Couldn't load gfx/uwater \n");
			underwater_texture = nonetexture;
		}
		else
			underwater_texture = GL_LoadTexture ("Underwater", 256, 256, uw, qfalse, GU_LINEAR, 0);
	}

	sniper_scope = Draw_CachePic ("gfx/hud/scope");
	
	zombie_skins[0][0] = loadtextureimage("/textures/ai/z0",0,0,qfalse,GU_LINEAR);
	zombie_skins[0][1] = loadtextureimage("/textures/ai/z0",0,0,qfalse,GU_LINEAR);
	zombie_skins[1][0] = loadtextureimage("/textures/ai/z0",0,0,qfalse,GU_LINEAR);
	zombie_skins[1][1] = loadtextureimage("/textures/ai/z0",0,0,qfalse,GU_LINEAR);
	
	Clear_LoadingFill ();
}



/*
================
Draw_Character

Draws one 8*8 graphics character with 0 being transparent.
It can be clipped to the top of the screen to allow the console to be
smoothly scrolled off.
================
*/
void Draw_Character (int x, int y, int num)
{
   	int	row, col;

	if (num == 32)
		return;		// space

	num &= 255;

	if (y <= -8)
		return;			// totally off screen

	row = num>>4;
	col = num&15;

	GL_Bind (char_texture);

	struct vertex
	{
		short u, v;
		short x, y, z;
	};

	vertex* const vertices = static_cast<vertex*>(sceGuGetMemory(sizeof(vertex) * 2));

	vertices[0].u = col * 8;
	vertices[0].v = row * 8;
	vertices[0].x = x;
	vertices[0].y = y;
	vertices[0].z = 0;

	vertices[1].u = (col + 1) * 8;
	vertices[1].v = (row + 1) * 8;
	vertices[1].x = x + 8;
	vertices[1].y = y + 8;
	vertices[1].z = 0;

	sceGuDrawArray(GU_SPRITES, GU_TEXTURE_16BIT | GU_VERTEX_16BIT | GU_TRANSFORM_2D, 2, 0, vertices);
}


/*
================
Draw_CharacterRGBA

This is the same as Draw_Character, but with RGBA color codes.
- MotoLegacy
================
*/
extern cvar_t scr_coloredtext;
void Draw_CharacterRGBA(int x, int y, int num, float r, float g, float b, float a)
{
	int	row, col;

	if (num == 32)
		return;		// space

	num &= 255;

	if (y <= -8)
		return;			// totally off screen

	row = num>>4;
	col = num&15;

	GL_Bind (char_texture);

	if (scr_coloredtext.value)
		sceGuTexFunc(GU_TFX_MODULATE , GU_TCC_RGBA);

	struct vertex
	{
		short u, v;
		short x, y, z;
	};

	vertex* const vertices = static_cast<vertex*>(sceGuGetMemory(sizeof(vertex) * 2));

	vertices[0].u = col * 8;
	vertices[0].v = row * 8;
	vertices[0].x = x;
	vertices[0].y = y;
	vertices[0].z = 0;

	vertices[1].u = (col + 1) * 8;
	vertices[1].v = (row + 1) * 8;
	vertices[1].x = x + 8;
	vertices[1].y = y + 8;
	vertices[1].z = 0;

	sceGuColor(GU_COLOR(r/255, g/255, b/255, a/255));
	sceGuDrawArray(GU_SPRITES, GU_TEXTURE_16BIT | GU_VERTEX_16BIT | GU_TRANSFORM_2D, 2, 0, vertices);

	if (scr_coloredtext.value)
        sceGuTexFunc(GU_TFX_REPLACE , GU_TCC_RGBA);
}

/*
================
Draw_String
================
*/
void Draw_String (int x, int y, char *str)
{
	while (*str)
	{
		Draw_Character (x, y, *str);
		str++;
		x += 8;
	}
}

/*
=============
Draw_AlphaPic
=============
*/
void Draw_AlphaPic (int x, int y, qpic_t *pic, float alpha)
{
	if (alpha != 1.0f)
	{
		sceGuTexFunc(GU_TFX_DECAL, GU_TCC_RGBA);
	}

	glpic_t			*gl;

	gl = (glpic_t *)pic->data;
	if (!gl->index)
        GL_Bind (nonetexture);
	else
        GL_Bind (gl->index);

	struct vertex
	{
		short			u, v;
		short			x, y, z;
	};

	vertex* const vertices = static_cast<vertex*>(sceGuGetMemory(sizeof(vertex) * 2));

   	vertices[0].u		= 0;
	vertices[0].v		= 0;
	vertices[0].x		= x;
	vertices[0].y		= y;
	vertices[0].z		= 0;

	const gltexture_t& glt = gltextures[gl->index];
	if (gltextures[gl->index].islmp)
	{
		vertices[1].u	= glt.original_width;
		vertices[1].v	= glt.original_height;
	}
	else
	{
		vertices[1].u 	= glt.width;
		vertices[1].v 	= glt.height;
	}
	vertices[1].x		= x + pic->width;
	vertices[1].y		= y + pic->height;
	vertices[1].z		= 0;

	sceGuColor(GU_RGBA(0xff, 0xff, 0xff, static_cast<unsigned int>(alpha * 255.0f)));

	sceGuDrawArray(
		GU_SPRITES,
		GU_TEXTURE_16BIT | GU_VERTEX_16BIT | GU_TRANSFORM_2D,
		2, 0, vertices);

    sceGuColor(0xffffffff);

	if (alpha != 1.0f)
	{
		sceGuTexFunc(GU_TFX_REPLACE, GU_TCC_RGBA);
	}
}


/*
=============
Draw_ColorPic
=============
*/
void Draw_ColorPic (int x, int y, qpic_t *pic, float r, float g , float b, float a)
{
	sceGuTexFunc(GU_TFX_MODULATE, GU_TCC_RGBA);

	glpic_t			*gl;

	gl = (glpic_t *)pic->data;
	if (!gl->index)
        GL_Bind (nonetexture);
	else
        GL_Bind (gl->index);

	struct vertex
	{
		short			u, v;
		short			x, y, z;
	};

	vertex* const vertices = static_cast<vertex*>(sceGuGetMemory(sizeof(vertex) * 2));

	vertices[0].u		= 0;
	vertices[0].v		= 0;

	vertices[0].x		= x;
	vertices[0].y		= y;
	vertices[0].z		= 0;

	const gltexture_t& glt = gltextures[gl->index];
	if (gltextures[gl->index].islmp)
	{
		vertices[1].u		= glt.original_width;
		vertices[1].v		= glt.original_height;
	}
	else
	{
		vertices[1].u 		= glt.width;
		vertices[1].v 		= glt.height;
	}

	vertices[1].x		= x + pic->width;
	vertices[1].y		= y + pic->height;
	vertices[1].z		= 0;

	sceGuColor(GU_RGBA(
	static_cast<unsigned int>(r),
	static_cast<unsigned int>(g),
	static_cast<unsigned int>(b),
	static_cast<unsigned int>(a)));

	sceGuDrawArray(
		GU_SPRITES,
		GU_TEXTURE_16BIT | GU_VERTEX_16BIT | GU_TRANSFORM_2D,
		2, 0, vertices);

    sceGuColor(0xffffffff);
	sceGuTexFunc(GU_TFX_REPLACE, GU_TCC_RGBA);
}

/*
=============
Draw_Pic
=============
*/
void Draw_Pic (int x, int y, qpic_t *pic)
{
	Draw_AlphaPic(x, y, pic, 1.0f);
}

/*
=============
Draw_StretchPic
=============
*/
void Draw_StretchPic (int x, int y, qpic_t *pic, int x_value, int y_value)
{

	glpic_t			*gl;

	gl = (glpic_t *)pic->data;
	if (!gl->index)
        GL_Bind (nonetexture);
	else
        GL_Bind (gl->index);

	struct vertex
	{
		unsigned short			u, v;
		short			x, y, z;
	};


	vertex* const vertices = static_cast<vertex*>(sceGuGetMemory(sizeof(vertex) * 2));
	const gltexture_t& glt = gltextures[gl->index];
	vertices[0].u = 0;
	vertices[0].v = 0;
	vertices[0].x = x;
	vertices[0].y = y;
	vertices[0].z = 0;

	if (gltextures[gl->index].islmp)
	{
		vertices[1].u		= glt.original_width;
		vertices[1].v		= glt.original_height;
	}
	else
	{
		vertices[1].u = glt.width;
		vertices[1].v = glt.height;
	}
	vertices[1].x = x + x_value;
	vertices[1].y = y + y_value;
	vertices[1].z = 0;

	sceGuDrawArray(GU_SPRITES, GU_TEXTURE_16BIT | GU_VERTEX_16BIT | GU_TRANSFORM_2D, 2, 0, vertices);

}
/*
=============
Draw_TransPic
=============
*/
void Draw_TransPic (int x, int y, qpic_t *pic)
{

	if (x < 0 || (unsigned)(x + pic->width) > vid.width || y < 0 ||
		 (unsigned)(y + pic->height) > vid.height)
	{
		Sys_Error ("Draw_TransPic: bad coordinates");
	}

	Draw_Pic (x, y, pic);
}

/*
=============
Draw_TransPicTranslate

Only used for the player color selection menu
=============
*/
void Draw_TransPicTranslate (int x, int y, qpic_t *pic, byte *translation)
{
	int				v, c;
	unsigned	    trans[64*64];
	int				p;

	c = pic->width * pic->height;

	for(v = 0; v < c ; v++)
	{
       	p = menuplyr_pixels[v];
		if (p == 255)
			trans[v] = p;
		else
			trans[v] = translation[p];
	}
    int translate_texture = GL_LoadTexture ("Player_Trl", pic->width, pic->height, (const byte*)trans, qtrue, GU_LINEAR, 0);

	GL_Bind (translate_texture);

	struct vertex
	{
		short u, v;
		short x, y, z;
	};

	vertex* const vertices = static_cast<vertex*>(sceGuGetMemory(sizeof(vertex) * 2));

	vertices[0].u = 0;
	vertices[0].v = 0;
	vertices[0].x = x;
	vertices[0].y = y;
	vertices[0].z = 0;

	vertices[1].u = 64;
	vertices[1].v = 64;
	vertices[1].x = x + pic->width;
	vertices[1].y = y + pic->height;
	vertices[1].z = 0;

	sceGuDrawArray(GU_SPRITES, GU_TEXTURE_16BIT | GU_VERTEX_16BIT | GU_TRANSFORM_2D, 2, 0, vertices);

    GL_UnloadTexture(translate_texture);
}


/*
================
Draw_ConsoleBackground

================
*/
void Draw_ConsoleBackground (int lines)
{
	//int y = (vid.height * 3) >> 2;

	if (con_forcedup)
		Draw_Fill(0, 0, vid.width, lines, 0);
	else
		Draw_Fill(0, 0, vid.width, lines, 0);



}
/*
================
Draw_LoadingFill
By Crow_bar
================
*/
void Draw_LoadingFill(void)
{
    if(!loading_num_step)
		return;

	int size       	= 8;
	int max_step   	= 350;
    int x          	= (vid.width  / 2) - (max_step / 2);
    int y          	= vid.height - (size/ 2) - 10;
	int l;
	char str[64];


	if(loading_cur_step > loading_num_step)
	      loading_cur_step = loading_num_step;

    float loadsize = loading_cur_step * (max_step / loading_num_step);
	Draw_FillByColor (x - 2, y - 2, max_step + 4, size + 4, GU_RGBA(255, 255, 255, 200));
	Draw_FillByColor (x, y, loadsize, size, GU_RGBA(0, 0, 0, 200));

	strcpy (str, "Loading: ");
	strcat (str, loading_name);
	l = strlen (str);
	Draw_String((vid.width - l*8)/2, y, str);
}

void Clear_LoadingFill (void)
{
    //it is end loading
	loading_cur_step = 0;
	loading_num_step = 0;
	memset(loading_name, 0, sizeof(loading_name));
}

/*
=============
Draw_FillByColor

Fills a box of pixels with a single color
=============
*/
void Draw_FillByColor (int x, int y, int w, int h, unsigned int c)
{
	struct vertex
	{
		short x, y, z;
	};

	vertex* const vertices = static_cast<vertex*>(sceGuGetMemory(sizeof(vertex) * 2));

	vertices[0].x = x;
	vertices[0].y = y;
	vertices[0].z = 0;

	vertices[1].x = x + w;
	vertices[1].y = y + h;
	vertices[1].z = 0;

	sceGuDisable(GU_TEXTURE_2D);
	sceGuColor(c);
	sceGuDrawArray(GU_SPRITES, GU_VERTEX_16BIT | GU_TRANSFORM_2D, 2, 0, vertices);
	sceGuColor(0xffffffff);
	sceGuEnable(GU_TEXTURE_2D);
}

void Draw_Fill (int x, int y, int w, int h, int c)
{
	struct vertex
	{
		short x, y, z;
	};

	vertex* const vertices = static_cast<vertex*>(sceGuGetMemory(sizeof(vertex) * 2));

	vertices[0].x = x;
	vertices[0].y = y;
	vertices[0].z = 0;

	vertices[1].x = x + w;
	vertices[1].y = y + h;
	vertices[1].z = 0;

	sceGuDisable(GU_TEXTURE_2D);
	sceGuColor(GU_RGBA(host_basepal[c*3], host_basepal[c*3+1], host_basepal[c*3+2], 0xff));
	sceGuDrawArray(GU_SPRITES, GU_VERTEX_16BIT | GU_TRANSFORM_2D, 2, 0, vertices);
	sceGuColor(0xffffffff);
	sceGuEnable(GU_TEXTURE_2D);
}

byte *StringToRGB (char *s)
{
	byte		*col;
	static	byte	rgb[4];

	Cmd_TokenizeString (s);
	if (Cmd_Argc() == 3)
	{
		rgb[0] = (byte)Q_atoi(Cmd_Argv(0));
		rgb[1] = (byte)Q_atoi(Cmd_Argv(1));
		rgb[2] = (byte)Q_atoi(Cmd_Argv(2));
	}
	else
	{
		col = (byte *)&d_8to24table[(byte)Q_atoi(s)];
		rgb[0] = col[0];
		rgb[1] = col[1];
		rgb[2] = col[2];
	}
	rgb[3] = 255;

	return rgb;
}

extern "C"	cvar_t	crosshair;
extern cvar_t crosshair;
extern qboolean croshhairmoving;
//extern cvar_t cl_zoom;
extern qpic_t *hitmark;
double Hitmark_Time, crosshair_spread_time;
float cur_spread;
float crosshair_offset_step;

int CrossHairWeapon (void)
{
    int i;
	switch(cl.stats[STAT_ACTIVEWEAPON])
	{
		case W_COLT:
		case W_BIATCH:
			i = 15;
			break;
		case W_KAR:
		case W_ARMAGEDDON:
			i = 50;
			break;
		case W_THOMPSON:
		case W_GIBS:
			i = 10;
			break;
		case W_357:
		case W_KILLU:
			i = 10;
			break;
		case W_BAR:
		case W_WIDOW:
			i = 10;
			break;
		case W_BROWNING:
		case W_ACCELERATOR:
			i = 20;
			break;
		case W_DB:
		case W_BORE:
			i = 25;
			break;
		case W_FG:
		case W_IMPELLER:
			i = 10;
			break;
		case W_GEWEHR:
		case W_COMPRESSOR:
			i = 10;
			break;
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
			i = 50;
			break;
		case W_M1:
		case W_M1000:
			i = 10;
			break;
		case W_M1A1:
		case W_WIDDER:
			i = 10;
			break;
		case W_MP40:
		case W_AFTERBURNER:
			i = 10;
			break;
		case W_MG:
		case W_BARRACUDA:
			i = 20;
			break;
		case W_PANZER:
		case W_LONGINUS:
			i = 0;
			break;
		case W_PPSH:
		case W_REAPER:
			i = 10;
			break;
		case W_PTRS:
		case W_PENETRATOR:
			i = 50;
			break;
		case W_RAY:
		case W_PORTER:
			i = 10;
			break;
		case W_SAWNOFF:
		case W_SNUFF:
			i = 30;
			break;
		case W_STG:
		case W_SPATZ:
			i = 10;
			break;
		case W_TRENCH:
		case W_GUT:
			i = 25;
			break;
		case W_TYPE:
		case W_SAMURAI:
			i = 10;
			break;
		case W_MP5:
			i = 10;
			break;
		case W_TESLA:
			i = 0;
			break;
		default:
			i = 0;
			break;
	}

    if (cl.perks & 64)
        i *= 0.65;

    return i;
}
int CrossHairMaxSpread (void)
{
	int i;
	switch(cl.stats[STAT_ACTIVEWEAPON])
	{
		case W_COLT:
		case W_BIATCH:
			i = 30;
			break;
		case W_KAR:
		case W_ARMAGEDDON:
			i = 75;
			break;
		case W_THOMPSON:
		case W_GIBS:
			i = 25;
			break;
		case W_357:
		case W_KILLU:
			i = 20;
			break;
		case W_BAR:
		case W_WIDOW:
			i = 35;
			break;
		case W_BROWNING:
		case W_ACCELERATOR:
			i = 50;
			break;
		case W_DB:
		case W_BORE:
			i = 25;
			break;
		case W_FG:
		case W_IMPELLER:
			i = 40;
			break;
		case W_GEWEHR:
		case W_COMPRESSOR:
			i = 35;
			break;
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
			i = 75;
			break;
		case W_M1:
		case W_M1000:
			i = 35;
			break;
		case W_M1A1:
		case W_WIDDER:
			i = 35;
			break;
		case W_MP40:
		case W_AFTERBURNER:
			i = 25;
			break;
		case W_MG:
		case W_BARRACUDA:
			i = 50;
			break;
		case W_PANZER:
		case W_LONGINUS:
			i = 0;
			break;
		case W_PPSH:
		case W_REAPER:
			i = 25;
			break;
		case W_PTRS:
		case W_PENETRATOR:
			i = 75;
			break;
		case W_RAY:
		case W_PORTER:
			i = 20;
			break;
		case W_SAWNOFF:
		case W_SNUFF:
			i = 30;
			break;
		case W_STG:
		case W_SPATZ:
			i = 35;
			break;
		case W_TRENCH:
		case W_GUT:
			i = 25;
			break;
		case W_TYPE:
		case W_SAMURAI:
			i = 25;
			break;
		case W_MP5:
			i = 25;
			break;
		case W_TESLA:
			i = 0;
			break;
		default:
			i = 0;
			break;
	}

    if (cl.perks & 64)
        i *= 0.65;

    return i;
}

/*
================
Draw_Crosshair
================
*/

extern float crosshair_opacity;
void Draw_Crosshair (void)
{
	if (cl.stats[STAT_HEALTH] < 20)
		return;

	if (!crosshair_opacity)
		crosshair_opacity = 255;

	float col;

	if (sv_player->v.facingenemy == 1) {
		col = 0;
	} else {
		col = 255;
	}

	// crosshair moving
	if (crosshair_spread_time > sv.time && crosshair_spread_time)
    {
        cur_spread = cur_spread + 10;
		crosshair_opacity = 128;

		if (cur_spread >= CrossHairMaxSpread())
			cur_spread = CrossHairMaxSpread();
    }
	// crosshair not moving
    else if (crosshair_spread_time < sv.time && crosshair_spread_time)
    {
        cur_spread = cur_spread - 4;
		crosshair_opacity = 255;

		if (cur_spread <= 0) {
			cur_spread = 0;
			crosshair_spread_time = 0;
		}
    }

	if (cl.stats[STAT_ACTIVEWEAPON] == W_M2 || cl.stats[STAT_ACTIVEWEAPON] == W_TESLA || cl.stats[STAT_ACTIVEWEAPON] == W_DG3)
	{
		Draw_CharacterRGBA((vid.width)/2-4, (vid.height)/2, 'O', 255, col, col, crosshair_opacity);
	}
	else if (crosshair.value == 1 && cl.stats[STAT_ZOOM] != 1 && cl.stats[STAT_ZOOM] != 2 && cl.stats[STAT_ACTIVEWEAPON] != W_PANZER)
    {
        int x_value, y_value;
        int crosshair_offset = CrossHairWeapon() + cur_spread;
		if (CrossHairMaxSpread() < crosshair_offset || croshhairmoving)
			crosshair_offset = CrossHairMaxSpread();

		if (sv_player->v.view_ofs[2] == 8) {
			crosshair_offset *= 0.80;
		} else if (sv_player->v.view_ofs[2] == -10) {
			crosshair_offset *= 0.65;
		}

		crosshair_offset_step += (crosshair_offset - crosshair_offset_step) * 0.5;

		x_value = (vid.width - 8)/2 - crosshair_offset_step;
		y_value = (vid.height - 8)/2;
		Draw_CharacterRGBA(x_value, y_value, 158, 255, col, col, crosshair_opacity);

		x_value = (vid.width - 8)/2 + crosshair_offset_step;
		y_value = (vid.height - 8)/2;
		Draw_CharacterRGBA(x_value, y_value, 158, 255, col, col, crosshair_opacity);

		x_value = (vid.width - 8)/2;
		y_value = (vid.height - 8)/2 - crosshair_offset_step;
		Draw_CharacterRGBA(x_value, y_value, 157, 255, col, col, crosshair_opacity);

		x_value = (vid.width - 8)/2;
		y_value = (vid.height - 8)/2 + crosshair_offset_step;
		Draw_CharacterRGBA(x_value, y_value, 157, 255, col, col, crosshair_opacity);
    }
    else if (crosshair.value && cl.stats[STAT_ZOOM] != 1 && cl.stats[STAT_ZOOM] != 2)
		Draw_CharacterRGBA((vid.width - 8)/2, (vid.height - 8)/2, '.', 255, col, col, crosshair_opacity);
	if (cl.stats[STAT_ZOOM] == 2)
		Draw_Pic (0, 0, sniper_scope);
   	if (Hitmark_Time > sv.time)
        Draw_Pic ((vid.width - hitmark->width)/2,(vid.height - hitmark->height)/2, hitmark);
}

/*
================
Draw_ColoredString
================
*/

static int HexToInt(char c)
{
	if (isdigit(c))
		return c - '0';
	else if (c >= 'a' && c <= 'f')
		return 10 + c - 'a';
	else if (c >= 'A' && c <= 'F')
		return 10 + c - 'A';
	else
		return -1;
}

// Creds to UP Team for scale code - Moto
void Draw_ColoredString(int x, int y, char *text, float r, float g, float b, float a, int scale)
{
	int num;
	qboolean white = qtrue;

	if (y <= -8)
		return;			// totally off screen

	if (!*text)
		return;
	
	GL_Bind (char_texture);
	
	
	
	if (scr_coloredtext.value)
		sceGuTexFunc(GU_TFX_MODULATE , GU_TCC_RGBA);

	for ( ; *text; text++)
	{

		// MotoLegacy - Added 0-255 RGBA support (5/26/2020)
		sceGuColor(GU_COLOR(r/255, g/255, b/255, a/255));

		num = *text & 255;
		
		if (num != 32 && num != (32 | 128))
		{
            float frow, fcol;

	        frow = num>>4;
	        fcol = num&15;

		 	struct vertex
	        {
		      short u, v;
		      short x, y, z;
	        };

         	vertex* const vertices = static_cast<vertex*>(sceGuGetMemory(sizeof(vertex) * 2));

	        vertices[0].u = fcol * 8;
	        vertices[0].v = frow * 8;
	        vertices[0].x = x;
	        vertices[0].y = y;
	        vertices[0].z = 0;

	        vertices[1].u = (fcol + 1) * 8;
	        vertices[1].v = (frow + 1) * 8;
	        vertices[1].x = x + (8*scale);
	        vertices[1].y = y + (8*scale);
	        vertices[1].z = 0;

	        sceGuDrawArray(GU_SPRITES, GU_TEXTURE_16BIT | GU_VERTEX_16BIT | GU_TRANSFORM_2D, 2, 0, vertices);
		}
		x += 8*scale;
	}

	if (!white)
		sceGuColor(GU_COLOR(1,1,1,1));

	if (scr_coloredtext.value)
        sceGuTexFunc(GU_TFX_REPLACE , GU_TCC_RGBA);
}

//=============================================================================
#ifdef NAA
//font.c : font.raw
//	bin2c font.raw font.c font
//font.c
extern"C"
{
 #include "font.c"
}
,.,.,
static int fontwidthtab[128] =
{
	10, 10, 10, 10,
	10, 10, 10, 10,
	10, 10, 10, 10,
	10, 10, 10, 10,

	10, 10, 10, 10,
	10, 10, 10, 10,
	10, 10, 10, 10,
	10, 10, 10, 10,

	10,  6,  8, 10, //   ! " #
	10, 10, 10,  6, // $ % & '
	10, 10, 10, 10, // ( ) * +
	 6, 10,  6, 10, // , - . /

	10, 10, 10, 10, // 0 1 2 3
	10, 10, 10, 10, // 6 5 8 7
	10, 10,  6,  6, // 10 9 : ;
	10, 10, 10, 10, // < = > ?

	16, 10, 10, 10, // @ A B C
	10, 10, 10, 10, // D E F G
	10,  6,  8, 10, // H I J K
	 8, 10, 10, 10, // L M N O

	10, 10, 10, 10, // P Q R S
	10, 10, 10, 12, // T U V W
	10, 10, 10, 10, // X Y Z [
	10, 10,  8, 10, // \ ] ^ _

	 6,  8,  8,  8, // ` a b c
	 8,  8,  6,  8, // d e f g
	 8,  6,  6,  8, // h i j k
	 6, 10,  8,  8, // l m n o

	 8,  8,  8,  8, // p q r s
	 8,  8,  8, 12, // t u v w
	 8,  8,  8, 10, // x y z {
	 8, 10,  8, 12  // | } ~
};

void Draw_FrontText(const char* text, int x, int y, unsigned int color, int fw) //Crow_bar
{
	int len = (int)strlen(text);

	if(!len)
	{
		return;
	}

	// Set the texture mode.
	sceGuTexMode(GU_PSM_8888, 0, 0, 0);
	sceGuTexImage(0, 256, 128, 256, font);
    sceGuTexFilter(GU_NEAREST, GU_NEAREST);

	sceGuShadeModel(GU_SMOOTH);

    sceGuTexFunc(GU_TFX_MODULATE, GU_TCC_RGBA);
	sceGuDepthMask(GU_TRUE);

	typedef struct
	{
		float s, t;
		unsigned int c;
		float x, y, z;
	} vertex;

	vertex* const v = static_cast<vertex*>(sceGuGetMemory(sizeof(vertex) * 2 * len));

	int i;
	for(i = 0; i < len; i++)
	{
		unsigned char c = (unsigned char)text[i];
		if(c < 32)
		{
			c = 0;
		}
		else if(c >= 128)
		{
			c = 0;
		}

		int tx = (c & 0x0F) << 4;
		int ty = (c & 0xF0);

		vertex* v0 = &v[i*2+0];
		vertex* v1 = &v[i*2+1];

		v0->s = (float)(tx + (fw ? ((16 - fw) >> 1) : ((16 - fontwidthtab[c]) >> 1)));
		v0->t = (float)(ty);
		v0->c = color;
		v0->x = (float)(x);
		v0->y = (float)(y);
		v0->z = 0.0f;

		v1->s = (float)(tx + 16 - (fw ? ((16 - fw) >> 1) : ((16 - fontwidthtab[c]) >> 1)));
		v1->t = (float)(ty + 16);
		v1->c = color;
		v1->x = (float)(x + (fw ? fw : fontwidthtab[c]));
		v1->y = (float)(y + 16);
		v1->z = 0.0f;

		x += (fw ? fw : fontwidthtab[c]);
	}
   	sceGuDrawArray(GU_SPRITES, GU_TEXTURE_32BITF | GU_COLOR_8888 | GU_VERTEX_32BITF | GU_TRANSFORM_2D, len * 2, 0, v);

	sceGuShadeModel(GU_FLAT);

	sceGuDepthMask(GU_FALSE);
	sceGuTexFunc(GU_TFX_REPLACE, GU_TCC_RGBA);
}

void Draw_FrontTest (void)
{
   	Draw_FrontText("red",   0,  0, 0xFF0000FF, 0);
	Draw_FrontText("green", 0, 16, 0xFF00FF00, 0);
	Draw_FrontText("blue",  0, 32, 0xFFFF0000, 0);

	Draw_FrontText("free char width",     0, 64, 0xFFFFFFFF, 0);
	Draw_FrontText("block char width 10", 0, 80, 0xFFFFFFFF, 10);
	Draw_FrontText("block char width 16", 0, 96, 0xFFFFFFFF, 16);

	Draw_FrontText("opacity 100%", 0, 128, 0xFFFFFFFF, 0);
	Draw_FrontText("opacity  50%", 0, 144, 0x7FFFFFFF, 0);
	Draw_FrontText("opacity  10%", 0, 160, 0x18FFFFFF, 0);

	Draw_FrontText("I'm Crow_bar", 2, 194, 0x40FFFFFF, 0);
	Draw_FrontText("I'm Crow_bar", 0, 192, 0xFFFFFFFF, 0);

	static float t = 0.0f;
	t += 0.1f;

	unsigned int c = 0xFF000000 |
		(unsigned int)((sinf(t * 0.393f + 0.086f) / 2.0f + 0.5f) * 255.0f) << 16 |
		(unsigned int)((sinf(t * 0.444f + 0.854f) / 2.0f + 0.5f) * 255.0f) <<  8 |
		(unsigned int)((sinf(t * 0.117f + 1.337f) / 2.0f + 0.5f) * 255.0f) <<  0;

	Draw_FrontText("Hello World from pspdev", 0, 224, c, 0);
}
#endif
//=============================================================================

/*
================
Draw_FadeScreen

================
*/
void Draw_FadeScreen (void)
{
	struct vertex
	{
		short	x, y, z;
	};

	vertex* const vertices = static_cast<vertex*>(sceGuGetMemory(sizeof(vertex) * 2));

	vertices[0].x		= 0;
	vertices[0].y		= 0;
	vertices[0].z		= 0;
	vertices[1].x		= vid.width;
	vertices[1].y		= vid.height;
	vertices[1].z		= 0;

	sceGuDisable(GU_TEXTURE_2D);

	sceGuColor(GU_RGBA(0, 0, 0, 0x80));
	sceGuDrawArray(
		GU_SPRITES,
		GU_VERTEX_16BIT | GU_TRANSFORM_2D,
		2, 0, vertices);

	sceGuEnable(GU_TEXTURE_2D);
}

//=============================================================================

/*
================
GL_Set2D

Setup as if the screen was 320*200
================
*/
void GL_Set2D (void)
{
	sceGuViewport (glx, gly, glwidth, glheight);
	sceGuScissor(0, 0, glwidth, glheight);

	sceGuEnable(GU_BLEND);
	sceGuTexFunc(GU_TFX_REPLACE, GU_TCC_RGBA);
}


/*
================
swizzle_slow
================
*/
void swizzle(u8* out, const u8* in, unsigned int width, unsigned int height)
{
   unsigned int i,j;
   unsigned int rowblocks = (width / 16);

   for (j = 0; j < height; ++j)
   {
      for (i = 0; i < width; ++i)
      {
         unsigned int blockx = i / 16;
         unsigned int blocky = j / 8;

         unsigned int x = (i - blockx*16);
         unsigned int y = (j - blocky*8);
         unsigned int block_index = blockx + ((blocky) * rowblocks);
         unsigned int block_address = block_index * 16 * 8;

         out[block_address + x + y * 16] = in[i+j*width];
      }
   }
}

/*
================
swizzle_fast
================
*/
static void swizzle_fast(u8* out, const u8* in, unsigned int width, unsigned int height)
{
	unsigned int blockx, blocky;
	unsigned int j;

	unsigned int width_blocks = (width / 16);
	unsigned int height_blocks = (height / 8);

	unsigned int src_pitch = (width-16)/4;
	unsigned int src_row = width * 8;

	const u8* ysrc = in;
	u32* dst = (u32*)out;

	for (blocky = 0; blocky < height_blocks; ++blocky)
	{
		const u8* xsrc = ysrc;
		for (blockx = 0; blockx < width_blocks; ++blockx)
		{
			const u32* src = (u32*)xsrc;
			for (j = 0; j < 8; ++j)
			{
				*(dst++) = *(src++);
				*(dst++) = *(src++);
				*(dst++) = *(src++);
				*(dst++) = *(src++);
				src += src_pitch;
			}
			xsrc += 16;
		}
		ysrc += src_row;
	}
}



/*
================
GL_ResampleTexture for 8 bit
================
*/
void GL_ResampleTexture(const byte *in, int inwidth, int inheight, unsigned char *out,  int outwidth, int outheight)
{
	const unsigned int fracstep = inwidth * 0x10000 / outwidth;
	for (int i = 0; i < outheight ; ++i, out += outwidth)
	{
		const byte*		inrow	= in + inwidth * (i * inheight / outheight);
		unsigned int	frac	= fracstep >> 1;
		for (int j = 0; j < outwidth; ++j, frac += fracstep)
		{
			out[j] = inrow[frac >> 16];
		}
	}
}

/*
================
GL_Upload8
================
*/
void GL_Upload8(int texture_index, const byte *data, int width, int height)
{
	if ((texture_index < 0) || (texture_index >= MAX_GLTEXTURES) || gltextures_used[texture_index] == false)
	{
		Sys_Error("Invalid texture index %d", texture_index);
	}

	const gltexture_t& texture = gltextures[texture_index];

	// Check that the texture matches.
	if ((width != texture.original_width) != (height != texture.original_height))
	{
		Sys_Error("Attempting to upload a texture which doesn't match the destination");
	}

	// Create a temporary buffer to use as a source for swizzling.
	std::size_t buffer_size = GL_GetTexSize(texture.format, texture.width, texture.height, 0);
	std::vector<byte> unswizzled(buffer_size);


	if (texture.mipmaps > 0) {
		int size_incr = buffer_size/4;
		for (int i= 1;i <= texture.mipmaps;i++) {
			buffer_size += size_incr;
			size_incr = size_incr/4;
		}
	}

	// Do we need to resize?
	if (texture.stretch_to_power_of_two)
	{
		// Resize.
		GL_ResampleTexture(data, width, height, &unswizzled[0], texture.width, texture.height);
	}
	else
	{
		// Straight copy.
		for (int y = 0; y < height; ++y)
		{
			const byte* const	src	= data + (y * width);
			byte* const			dst = &unswizzled[y * texture.width];
			memcpy(dst, src, width);
		}
	}

	// Swizzle to system RAM.
	swizzle_fast(texture.ram, &unswizzled[0], texture.width, texture.height);

	if (texture.mipmaps > 0)
	{
		int size = (texture.width * texture.height);
		int offset = size;
		int div = 2;

		for (int i = 1; i <= texture.mipmaps;i++)
		{
			GL_ResampleTexture(data, width, height, &unswizzled[0], texture.width/div, texture.height/div);
			swizzle_fast(texture.ram+offset, &unswizzled[0], texture.width/div, texture.height/div);
			offset += size/(div*div);
			div *=2;
		}
	}

	unswizzled.clear();

	// Copy to VRAM?
	if (texture.vram)
	{
		// Copy.
		memcpy(texture.vram, texture.ram, buffer_size);

		// Flush the data cache.
		sceKernelDcacheWritebackRange(texture.vram, buffer_size);
	}

	// Flush the data cache.
	sceKernelDcacheWritebackRange(texture.ram, buffer_size);
}

/*
================
GL_Upload8_A
================
*/
void GL_Upload8_A(int texture_index, const byte *data, int width, int height)
{
	if ((texture_index < 0) || (texture_index >= MAX_GLTEXTURES) || gltextures_used[texture_index] == false)
	{
		Sys_Error("Invalid texture index %d", texture_index);
	}

	const gltexture_t& texture = gltextures[texture_index];

	// Check that the texture matches.
	if ((width != texture.original_width) != (height != texture.original_height))
	{
		Sys_Error("Attempting to upload a texture which doesn't match the destination");
	}

	// Create a temporary buffer to use as a source for swizzling.
	const std::size_t buffer_size = GL_GetTexSize(texture.format, texture.width, texture.height, 0);
	memcpy((void *) texture.ram, (void *) data, buffer_size);


	// Copy to VRAM?
	if (texture.vram)
	{
		// Copy.
		memcpy(texture.vram, texture.ram, buffer_size);

		// Flush the data cache.
		sceKernelDcacheWritebackRange(texture.vram, buffer_size);
	}

	// Flush the data cache.
	sceKernelDcacheWritebackRange(texture.ram, buffer_size);
}
/*
================
GL_Upload16_A
================
*/
void GL_Upload16_A(int texture_index, const byte *data, int width, int height)
{
	if ((texture_index < 0) || (texture_index >= MAX_GLTEXTURES) || gltextures_used[texture_index] == false)
	{
		Sys_Error("Invalid texture index %d", texture_index);
	}

	const gltexture_t& texture = gltextures[texture_index];

	// Check that the texture matches.
	if ((width != texture.original_width) != (height != texture.original_height))
	{
		Sys_Error("Attempting to upload a texture which doesn't match the destination");
	}

	// Create a temporary buffer to use as a source for swizzling.
	const std::size_t buffer_size = GL_GetTexSize(texture.format, texture.width, texture.height, 0);
	memcpy((void *) texture.ram, (void *) data, buffer_size);

	// Copy to VRAM?
	if (texture.vram)
	{
		// Copy.
		memcpy(texture.vram, texture.ram, buffer_size);

		// Flush the data cache.
		sceKernelDcacheWritebackRange(texture.vram, buffer_size);
	}

	// Flush the data cache.
	sceKernelDcacheWritebackRange(texture.ram, buffer_size);
}

/*
=======================================
TextureConvector
=======================================
From DE2 by Christoph Arnold "charnold"
modify by Crow_bar
=======================================
*/
void TextureConvector(unsigned char *in32, unsigned char *out16, int w, int h, int format)
{
	int texel;

	int size = w * h;

	for (texel = 0; texel < size; texel++)
	{
		if (format == GU_PSM_4444)
		{
			*(out16)    = (*in32>>4) & 0x0f; in32++; // r
			*(out16++) |= (*in32)    & 0xf0; in32++; // g
			*(out16)    = (*in32>>4) & 0x0f; in32++; // b
			*(out16++) |= (*in32)    & 0xf0; in32++; // a
		}
		else if (format == GU_PSM_5650)
		{
			unsigned char r,g,b;

			r = (*in32>>3) & 0x1f; in32++;	// r = 5 bit
			g = (*in32>>2) & 0x3f; in32++;	// g = 6 bit
			b = (*in32>>3) & 0x1f; in32++;	// b = 5 bit
								   in32++;	// a = 0 bit

			*(out16)	= r;				// alle   5 bits von r auf lower  5 bits von out16
			*(out16++) |= (g<<5) & 0xe0;	// lower  3 bits von g auf higher 3 bits von out16
			*(out16)	= (g>>3) & 0x07;	// higher 3 bits von g auf lower  3 bits von out16
			*(out16++) |= (b<<3) & 0xf8;    // alle   5 bits von b auf higher 5 bits von out16

		}
		else if (format == GU_PSM_5551)
		{
			unsigned char r,g,b,a;

			r = (*in32>>3) & 0x1f; in32++;	// r = 5 bit
			g = (*in32>>3) & 0x1f; in32++;	// g = 5 bit
			b = (*in32>>3) & 0x1f; in32++;	// b = 5 bit
			a = (*in32>>7) & 0x01; in32++;	// a = 1 bit

			*(out16)	= r;				// alle   5 bits von r auf lower  5 bits von out16
			*(out16++) |= (g<<5) & 0xe0;	// lower  3 bits von g auf higher 3 bits von out16
			*(out16)	= (g>>3) & 0x03;	// higher 2 bits von g auf lower  2 bits von out16
			*(out16)   |= (b<<2) & 0x7c;    // alle   5 bits von b auf bits 3-7      von out16
			*(out16++) |= (a<<7) & 0x80;    //        1 bit  von a auf bit    8      von out16
		}
	}
}

/*
================
GL_Upload16_B
================
*/
void GL_Upload32_16(int texture_index, const byte *data, int width, int height)
{
	if ((texture_index < 0) || (texture_index >= MAX_GLTEXTURES) || gltextures_used[texture_index] == false)
	{
		Sys_Error("Invalid texture index %d", texture_index);
	}

	const gltexture_t& texture = gltextures[texture_index];

	// Check that the texture matches.
	if ((width != texture.original_width) != (height != texture.original_height))
	{
		Sys_Error("Attempting to upload a texture which doesn't match the destination");
	}

	// Create a temporary buffer to use as a source for swizzling.
	std::size_t buffer_sizesrc = GL_GetTexSize(-1, texture.width, texture.height, 4);
    std::vector<byte> unswizzled(buffer_sizesrc);

	std::size_t buffer_sizedst = GL_GetTexSize(texture.format, texture.width, texture.height, 0);
	std::vector<byte> bpp(buffer_sizesrc);


	if (texture.stretch_to_power_of_two)
	{
	  // Resize.
	  Image_Resample ((void*)data, width, height, &unswizzled[0], texture.width, texture.height, texture.bpp, int(r_restexf.value));
  	}
	else
	{
		// Straight copy.
		for (int y = 0; y < height; ++y)
		{
			const byte* const	src	= data + (y * width * texture.bpp);
			byte* const			dst = &unswizzled[y * texture.width * texture.bpp];
			memcpy(dst, src, width * texture.bpp);
		}
	}

	TextureConvector((unsigned char*)&unswizzled[0], (unsigned char*)&bpp[0], texture.width, texture.height, texture.format);
    unswizzled.clear();

	// Swizzle to system RAM.
	swizzle_fast(texture.ram, &bpp[0], texture.width * 2, texture.height);
    bpp.clear();


	// Copy to VRAM?
	if (texture.vram)
	{
		// Copy.
		memcpy(texture.vram, texture.ram, buffer_sizedst);

		// Flush the data cache.
		sceKernelDcacheWritebackRange(texture.vram, buffer_sizedst);
	}

	// Flush the data cache.
	sceKernelDcacheWritebackRange(texture.ram, buffer_sizedst);
}


/*
================
GL_Upload16
================
*/
void GL_Upload16(int texture_index, const byte *data, int width, int height)
{
	if ((texture_index < 0) || (texture_index >= MAX_GLTEXTURES) || gltextures_used[texture_index] == false)
	{
		Sys_Error("Invalid texture index %d", texture_index);
	}

	const gltexture_t& texture = gltextures[texture_index];

	// Check that the texture matches.
	if ((width != texture.original_width) != (height != texture.original_height))
	{
		Sys_Error("Attempting to upload a texture which doesn't match the destination");
	}

	// Create a temporary buffer to use as a source for swizzling.
	const std::size_t buffer_size = GL_GetTexSize(texture.format, texture.width, texture.height, 0);
    std::vector<byte> unswizzled(buffer_size);


	// Straight copy.
	for (int y = 0; y < height; ++y)
	{
		const byte* const	src	= data + (y * width * texture.bpp);
		byte* const			dst = &unswizzled[y * texture.width * texture.bpp];
		memcpy(dst, src, width * texture.bpp);
	}

	// Swizzle to system RAM.
	swizzle_fast(texture.ram, &unswizzled[0], texture.width * texture.bpp, texture.height);
	unswizzled.clear();


	// Copy to VRAM?
	if (texture.vram)
	{
		// Copy.
		memcpy(texture.vram, texture.ram, buffer_size);

		// Flush the data cache.
		sceKernelDcacheWritebackRange(texture.vram, buffer_size);
	}

	// Flush the data cache.
	sceKernelDcacheWritebackRange(texture.ram, buffer_size);
}

/*
===============
GL_Upload24_A
===============
*/
void GL_Upload24_A(int texture_index, const byte *data, int width, int height)
{
	if ((texture_index < 0) || (texture_index >= MAX_GLTEXTURES) || gltextures_used[texture_index] == false)
	{
		Sys_Error("Invalid texture index %d", texture_index);
	}

	const gltexture_t& texture = gltextures[texture_index];

	// Check that the texture matches.
	if ((width != texture.original_width) != (height != texture.original_height))
	{
		Sys_Error("Attempting to upload a texture which doesn't match the destination");
	}

	// Create a temporary buffer to use as a source for swizzling.
	const std::size_t buffer_size = GL_GetTexSize(-1, texture.width, texture.height, texture.bpp);

	//resize Crow_bar PSP port 24BIT RESAMPLER
	if (texture.stretch_to_power_of_two)
	{
	   Image_Resample ((void*)data, width, height, (void *) texture.ram, texture.width, texture.height, texture.bpp, int(r_restexf.value));
    }
	else
	{
	   memcpy((void *) texture.ram, (void *) data, buffer_size);
	}


	// Copy to VRAM?
	if (texture.vram)
	{
		// Copy.
		memcpy(texture.vram, texture.ram, buffer_size);

		// Flush the data cache.
		sceKernelDcacheWritebackRange(texture.vram, buffer_size);
	}

	// Flush the data cache.
	sceKernelDcacheWritebackRange(texture.ram, buffer_size);
}

/*
================
GL_Upload24
================
*/
void GL_Upload24(int texture_index, const byte *data, int width, int height)
{
	if ((texture_index < 0) || (texture_index >= MAX_GLTEXTURES) || gltextures_used[texture_index] == false)
	{
		Sys_Error("Invalid texture index %d", texture_index);
	}

	const gltexture_t& texture = gltextures[texture_index];

	// Check that the texture matches.
	if ((width != texture.original_width) != (height != texture.original_height))
	{
		Sys_Error("Attempting to upload a texture which doesn't match the destination");
	}

	// Create a temporary buffer to use as a source for swizzling.
	std::size_t buffer_size = GL_GetTexSize(-1, texture.width, texture.height, texture.bpp);
	std::vector<byte> unswizzled(buffer_size);

	if (texture.mipmaps > 0)
	{
		int size_incr = buffer_size/4;

		for (int i= 1;i <= texture.mipmaps;i++)
		{
			buffer_size += size_incr;
			size_incr = size_incr/4;
		}
	}

	//32BIT resize and swizzler by Crow_bar PSP port
	// Do we need to resize?
	if (texture.stretch_to_power_of_two)
	{
	  // Resize.
	  Image_Resample ((void*)data, width, height, &unswizzled[0], texture.width, texture.height, texture.bpp, int(r_restexf.value));
  	}
	else
	{
		// Straight copy.
		for (int y = 0; y < height; ++y)
		{
			const byte* const	src	= data + (y * width * texture.bpp);
			byte* const			dst = &unswizzled[y * texture.width * texture.bpp];
			memcpy(dst, src, width * texture.bpp);
		}
	}

	// Swizzle to system RAM.
	swizzle_fast(texture.ram, &unswizzled[0], texture.width * texture.bpp, texture.height);

	if (texture.mipmaps > 0)
	{
		int size = GL_GetTexSize(-1, texture.width, texture.height, texture.bpp);
		int offset = size;
		int div = 2;

		for (int i = 1; i <= texture.mipmaps;i++)
		{
			Image_Resample((void*)data, width, height, &unswizzled[0],
			texture.width/div, texture.height/div, texture.bpp, int(r_restexf.value));
			swizzle_fast(texture.ram+offset, &unswizzled[0], (texture.width/div) * texture.bpp, texture.height/div);
			offset += size/(div*div);
			div *=2;
		}
	}

	unswizzled.clear();

	// Copy to VRAM?
	if (texture.vram)
	{
		// Copy.
		memcpy(texture.vram, texture.ram, buffer_size);

		// Flush the data cache.
		sceKernelDcacheWritebackRange(texture.vram, buffer_size);
	}

	// Flush the data cache.
	sceKernelDcacheWritebackRange(texture.ram, buffer_size);
}

/*
===============
GL_Upload32_A
===============
*/
void GL_Upload32_A(int texture_index, const byte *data, int width, int height)
{
	if ((texture_index < 0) || (texture_index >= MAX_GLTEXTURES) || gltextures_used[texture_index] == false)
	{
		Sys_Error("Invalid texture index %d", texture_index);
	}

	gltexture_t& texture = gltextures[texture_index];

	// Check that the texture matches.
	if ((width != texture.original_width) != (height != texture.original_height))
	{
		Sys_Error("Attempting to upload a texture which doesn't match the destination");
	}

	// Create a temporary buffer to use as a source for swizzling.
	std::size_t buffer_size = GL_GetTexSize(texture.format, texture.width, texture.height, 0);

	//resize Crow_bar PSP port 32BIT RESAMPLER
    if (texture.stretch_to_power_of_two)
	{
       Image_Resample ((void*)data, width, height, (void *) texture.ram, texture.width, texture.height, texture.bpp, int(r_restexf.value));
    }
	else
	{
	   memcpy((void *) texture.ram, (void *) data, buffer_size);
	}

	// Copy to VRAM?
	if (texture.vram)
	{
		// Copy.
		memcpy(texture.vram, texture.ram, buffer_size);

		// Flush the data cache.
		sceKernelDcacheWritebackRange(texture.vram, buffer_size);
	}

	// Flush the data cache.
	sceKernelDcacheWritebackRange(texture.ram, buffer_size);
}

/*
================
GL_Upload32
================
*/
void GL_Upload32(int texture_index, const byte *data, int width, int height)
{
	if ((texture_index < 0) || (texture_index >= MAX_GLTEXTURES) || gltextures_used[texture_index] == false)
	{
		Sys_Error("Invalid texture index %d", texture_index);
	}

	//const
	gltexture_t& texture = gltextures[texture_index];

	// Check that the texture matches.
	if ((width != texture.original_width) != (height != texture.original_height))
	{
		Sys_Error("Attempting to upload a texture which doesn't match the destination");
	}

	// Create a temporary buffer to use as a source for swizzling.
	std::size_t buffer_size = GL_GetTexSize(texture.format, texture.width, texture.height, 0);
	std::vector<byte> unswizzled(buffer_size);

	if (texture.mipmaps > 0)
	{
		int size_incr = buffer_size/4;

		for (int i= 1;i <= texture.mipmaps;i++)
		{
			buffer_size += size_incr;
			size_incr = size_incr/4;
		}
	}

	//32BIT resize and swizzler by Crow_bar PSP port
	// Do we need to resize?
	if (texture.stretch_to_power_of_two)
	{
	  // Resize.
	  Image_Resample ((void*)data, width, height, &unswizzled[0], texture.width, texture.height, texture.bpp, int(r_restexf.value));
  	}
	else
	{
		// Straight copy.
		for (int y = 0; y < height; ++y)
		{
			const byte* const	src	= data + (y * width * texture.bpp);
			byte* const			dst = &unswizzled[y * texture.width * texture.bpp];
			memcpy(dst, src, width * texture.bpp);
		}
	}

	// Swizzle to system RAM.
	swizzle_fast(texture.ram, &unswizzled[0], texture.width * texture.bpp, texture.height);


    if (texture.mipmaps > 0)
	{
		int size = GL_GetTexSize(texture.format, texture.width, texture.height, 0);
		int offset = size;
		int div = 2;

		for (int i = 1; i <= texture.mipmaps;i++)
		{
			Image_Resample((void*)data, width, height, &unswizzled[0],
			texture.width/div, texture.height/div, texture.bpp, int(r_restexf.value));
			swizzle_fast(texture.ram+offset, &unswizzled[0], (texture.width/div) * texture.bpp, texture.height/div);
			offset += size/(div*div);
			div *=2;
		}
	}

	unswizzled.clear();

	// Copy to VRAM?
	if (texture.vram)
	{
		// Copy.
		memcpy(texture.vram, texture.ram, buffer_size);

		// Flush the data cache.
		sceKernelDcacheWritebackRange(texture.vram, buffer_size);
	}

	// Flush the data cache.
	sceKernelDcacheWritebackRange(texture.ram, buffer_size);
}

/*
================
GL_UploadDXT
================
*/
void GL_UploadDXT(int texture_index, const byte *data, int width, int height)
{
	if ((texture_index < 0) || (texture_index >= MAX_GLTEXTURES) || gltextures_used[texture_index] == false)
	{
		Sys_Error("Invalid texture index %d", texture_index);
	}
	
	const gltexture_t& texture = gltextures[texture_index];

	// Check that the texture matches.
	if ((width != texture.original_width) != (height != texture.original_height))
	{
		Sys_Error("Attempting to upload a texture which doesn't match the destination");
	}
	
	// Create a temporary buffer to use as a source for swizzling.
	std::size_t buffer_sizesrc = GL_GetTexSize(-1, texture.width, texture.height, texture.bpp);
	std::vector<byte> unswizzled(buffer_sizesrc);

    // New compressed texture
	std::size_t buffer_sizedst = GL_GetTexSize(texture.format, texture.width, texture.height, 0);

	if (texture.stretch_to_power_of_two)
	{
		// Resize.
		Image_Resample ((void*)data, width, height, &unswizzled[0], texture.width, texture.height, texture.bpp, int(r_restexf.value));
  	}
	else
	{
		// Straight copy.
		for (int y = 0; y < height; ++y)
		{
			const byte* const	src	= data + (y * width * texture.bpp);
			byte* const			dst = &unswizzled[y * texture.width * texture.bpp];
			memcpy(dst, src, width * texture.bpp);
		}
	}

	tx_compress_dxtn(texture.bpp, texture.width, texture.height,(const unsigned char *)&unswizzled[0], texture.format, (unsigned char *)texture.ram);
	unswizzled.clear();
	// Copy to VRAM?
	if (texture.vram)
	{
		// Copy.
		memcpy(texture.vram, texture.ram, buffer_sizedst);
		// Flush the data cache.
		sceKernelDcacheWritebackRange(texture.vram, buffer_sizedst);
	}
	// Flush the data cache.
	sceKernelDcacheWritebackRange(texture.ram, buffer_sizedst);
}

static std::size_t round_up(std::size_t size)
{
	static const float	denom	= 1.0f / logf(2.0f);
	const float			logged	= logf(size) * denom;
	const float			ceiling	= ceilf(logged);
	return 1 << static_cast<int>(ceiling);
}


static std::size_t round_down(std::size_t size)
{
	static const float	denom	= 1.0f / logf(2.0f);
	const float			logged	= logf(size) * denom;
	const float			floor	= floorf(logged);
	return 1 << static_cast<int>(floor);
}

/*
================
GL_UnloadTexture
================
*/
void GL_UnloadTexture(int texture_index)
{

	if (gltextures_used[texture_index] == true)
	{
		gltexture_t& texture = gltextures[texture_index];

		Con_DPrintf("Unloading: %s,%d\n",texture.identifier, texture.bpp);
		// Source.
		strcpy(texture.identifier,"");
		texture.original_width = 0;
		texture.original_height = 0;
		texture.stretch_to_power_of_two = qfalse;

        // Fill in the texture description.
		texture.format  = GU_PSM_T8;
        texture.bpp     = 0;
		texture.filter  = GU_LINEAR;
		texture.width   = 0;
		texture.height  = 0;
		texture.mipmaps = 0;
		texture.swizzle = 0;
#ifdef STATIC_PAL
		memset(texture.palette, 0, sizeof(texture.palette));
#else
        if (texture.palette != NULL)
		{
            free(texture.palette);
            texture.palette = NULL;
        }
		if (texture.palette_2 != NULL)
		{
            free(texture.palette_2);
            texture.palette_2 = NULL;
        }
#endif
		texture.palette_active = qfalse;
		if (texture.palette != NULL)
		{
			free(texture.palette);
			texture.palette = NULL;
		}
		if (texture.palette_2 != NULL)
		{
			free(texture.palette_2);
			texture.palette_2 = NULL;
		}
		
		// Buffers.
		if (texture.ram != NULL)
		{
			free(texture.ram);
			texture.ram = NULL;
		}
		/*if (texture.vram != NULL)
		{
			vfree(texture.vram);
			texture.vram = NULL;
		} */

	}

	gltextures_used[texture_index] = false;
	numgltextures--;
	
}

/*
================
GL_LoadTexture
================
*/
int GL_LoadTexture (const char *identifier, int width, int height, const byte *data, qboolean stretch_to_power_of_two, int filter, int mipmap_level)
{
	int texture_index = -1;

	tex_scale_down = r_tex_scale_down.value == qtrue;
	// See if the texture is already present.
	if (identifier[0])
	{
		for (int i = 0; i < MAX_GLTEXTURES; ++i)
		{
			if (gltextures_used[i] == true)
			{
				const gltexture_t& texture = gltextures[i];
				if (!strcmp (identifier, texture.identifier))
				{
					return i;
				}
			}
		}
	}

	// Out of textures?
	if (numgltextures == MAX_GLTEXTURES)
	{
		Sys_Error("Out of OpenGL textures");
	}

	// Use the next available texture.
	numgltextures++;
	texture_index = numgltextures;

	for (int i = 0; i < MAX_GLTEXTURES; ++i)
	{
		if (gltextures_used[i] == false) {
			texture_index = i;
			break;
		}
	}
	gltexture_t& texture = gltextures[texture_index];
	gltextures_used[texture_index] = true;

	// Fill in the source data.
	strcpy(texture.identifier, identifier);
	texture.original_width			= width;
	texture.original_height			= height;
	texture.stretch_to_power_of_two	= stretch_to_power_of_two != qfalse;

	// Fill in the texture description.
	texture.format			= GU_PSM_T8;
	texture.filter			= filter;
	texture.mipmaps			= mipmap_level;
	texture.swizzle         = GU_TRUE;
	texture.bpp             = 1;
#ifdef STATIC_PAL
	memset(texture.palette, 0, sizeof(texture.palette));
#endif
    texture.palette_active          = qfalse;

	if (tex_scale_down == true && texture.stretch_to_power_of_two == true)
	{
		texture.width			= std::max(round_down(width), 32U);
		texture.height			= std::max(round_down(height),32U);
	}
	else
	{
		texture.width			= std::max(round_up(width), 32U);
		texture.height			= std::max(round_up(height),32U);
	}

	for (int i=0; i <= mipmap_level;i++)
	{
		int div = (int) powf(2,i);
		if ((texture.width / div) > 16 && (texture.height / div) > 16 ) {
			texture.mipmaps = i;
		}
	}

	// Do we really need to resize the texture?
	if (texture.stretch_to_power_of_two)
	{
		// Not if the size hasn't changed.
		texture.stretch_to_power_of_two = (texture.width != width) || (texture.height != height);
	}

	Con_DPrintf("Loading: %s [%dx%d](%0.2f KB)\n",texture.identifier,texture.width,texture.height, (float) (texture.width*texture.height)/1024);

	// Allocate the RAM.
	std::size_t buffer_size = texture.width * texture.height;

	if (texture.mipmaps > 0) {
		int size_incr = buffer_size/4;
		for (int i= 1;i <= texture.mipmaps;i++) {
			buffer_size += size_incr;
			size_incr = size_incr/4;
		}
	}

	texture.ram	= static_cast<texel*>(memalign(16, buffer_size));

	if (!texture.ram)
	{
		Sys_Error("Out of RAM for textures.");
	}

	// Allocate the VRAM.
	texture.vram = static_cast<texel*>(valloc(buffer_size));

	// Upload the texture.
	GL_Upload8(texture_index, data, width, height);

	if (texture.vram && texture.ram)
	{
		free(texture.ram);
		texture.ram = NULL;
	}
	// Done.
	return texture_index;
}

/*
================
GL_LoadPalTex
================
*/
int GL_LoadPalTex (const char *identifier, int width, int height, const byte *data, qboolean stretch_to_power_of_two, int filter, int mipmap_level, byte *palette, int paltype)
{
	
	int texture_index = -1;

	tex_scale_down = r_tex_scale_down.value == qtrue;
	// See if the texture is already present.
	if (identifier[0])
	{
		for (int i = 0; i < MAX_GLTEXTURES; ++i)
		{
			if (gltextures_used[i] == true)
			{
				const gltexture_t& texture = gltextures[i];
				if (!strcmp (identifier, texture.identifier))
				{
					return i;
				}
			}
		}
	}

	// Out of textures?
	if (numgltextures == MAX_GLTEXTURES)
	{
		Sys_Error("Out of OpenGL textures");
	}

	// Use the next available texture.
	numgltextures++;
	texture_index = numgltextures;

	for (int i = 0; i < MAX_GLTEXTURES; ++i)
	{
		if (gltextures_used[i] == false)
		{
			texture_index = i;
			break;
		}
	}
	gltexture_t& texture = gltextures[texture_index];
	gltextures_used[texture_index] = true;

	// Fill in the source data.
	strcpy(texture.identifier, identifier);
	texture.original_width			= width;
	texture.original_height			= height;
	texture.stretch_to_power_of_two	= stretch_to_power_of_two != qfalse;

	// Fill in the texture description.
	texture.format			= GU_PSM_T8;
	texture.filter			= filter;
	texture.mipmaps			= mipmap_level;
    texture.swizzle         = GU_TRUE;
	texture.bpp             = 1;

	// Upload the Palette
    if((paltype == PAL_RGB  && palette) ||
       (paltype == PAL_RGBA && palette) ||
	   (paltype == PAL_Q2   && palette == NULL) ||
	   (paltype == PAL_H2   && palette == NULL) )
    {
#ifndef STATIC_PAL
        if(paltype == PAL_Q2)
	    {
              texture.palette_2 = d_8to24tableQ2; //hard coded palette
		}
	    else if(paltype == PAL_H2)
	    {
              texture.palette_2 = d_8to24tableH2; //hard coded palette
		}
		else
		{
			texture.palette_2 = static_cast<ScePspRGBA8888*>(memalign(16, sizeof(ScePspRGBA8888) * 256));
			if(!texture.palette_2)
			{
	            Sys_Error("Out of RAM for palettes.");
			}
#endif
			if(paltype == PAL_RGBA)
			{
				  // Convert the palette to PSP format.
			      for (ScePspRGBA8888* color = &texture.palette_2[0]; color < &texture.palette_2[256]; ++color)
				  {
					const unsigned int r = gammatable[*palette++];
					const unsigned int g = gammatable[*palette++];
					const unsigned int b = gammatable[*palette++];
					const unsigned int a = gammatable[*palette++];
					*color = GU_RGBA(r, g, b, a);
				  }
	        }
			else if(paltype == PAL_RGB)
			{
				  // Convert the palette to PSP format.
			      for (ScePspRGBA8888* color = &texture.palette_2[0]; color < &texture.palette_2[256]; ++color)
				  {
					const unsigned int r = gammatable[*palette++];
					const unsigned int g = gammatable[*palette++];
					const unsigned int b = gammatable[*palette++];
					*color = GU_RGBA(r, g, b, 0xff);
				  }
		    }
#ifndef STATIC_PAL
		}
#endif
		texture.palette_2[255] = 0;  //alpha color
		texture.palette_active  = qtrue;
	}
	else
    {
	    Sys_Error("GL_LoadPalTex: Unknow palette type");
	}


	if (tex_scale_down == true && texture.stretch_to_power_of_two == true)
	{
		texture.width			= std::max(round_down(width), 32U);
		texture.height			= std::max(round_down(height),32U);
	}
	else
	{
		texture.width			= std::max(round_up(width), 32U);
		texture.height			= std::max(round_up(height),32U);
	}

	for (int i=0; i <= mipmap_level;i++)
	{
		int div = (int) powf(2,i);
		if ((texture.width / div) > 16 && (texture.height / div) > 16 )
		{
			texture.mipmaps = i;
		}
	}

	// Do we really need to resize the texture?
	if (texture.stretch_to_power_of_two)
	{
		// Not if the size hasn't changed.
		texture.stretch_to_power_of_two = (texture.width != width) || (texture.height != height);
	}

	Con_DPrintf("Loading TEX_PAL: %s [%dx%d](%0.2f KB)\n",texture.identifier,texture.width,texture.height, (float) ((texture.width*texture.height)/1024) + 256);

	// Allocate the RAM.
	std::size_t buffer_size = texture.width * texture.height;

	if (texture.mipmaps > 0)
	{
		int size_incr = buffer_size/4;
		for (int i= 1;i <= texture.mipmaps;i++)
		{
			buffer_size += size_incr;
			size_incr = size_incr/4;
		}
	}

	texture.ram	= static_cast<texel*>(memalign(16, buffer_size));

	if (!texture.ram)
	{
		Sys_Error("Out of RAM for textures.");
	}

	// Allocate the VRAM.
	texture.vram = static_cast<texel*>(valloc(buffer_size));

	// Upload the texture.
	GL_Upload8(texture_index, data, width, height);

	if (texture.vram && texture.ram)
	{
		free(texture.ram);
		texture.ram = NULL;
	}
	// Done.
	return texture_index;
}


/*
================
GL_LoadTextureLM
================
*/
int GL_LoadTextureLM (const char *identifier, int width, int height, const byte *data, int bpp, int filter, qboolean update, int forcopy)
{
	tex_scale_down = r_tex_scale_down.value == qtrue;
	int texture_index = -1;
	// See if the texture is already present.
	if (identifier[0])
	{
		for (int i = 0; i < MAX_GLTEXTURES; ++i)
		{
			if (gltextures_used[i] == true)
			{
				const gltexture_t& texture = gltextures[i];
				if (!strcmp (identifier, texture.identifier))
				{
					if (update == qfalse)
					{
						return i;
					}
					else
					{
						texture_index = i;
						break;
					}
				}
			}
		}
	}

	if (update == qfalse || texture_index == -1)
	{
		// Out of textures?
		if (numgltextures == MAX_GLTEXTURES)
		{
			Sys_Error("Out of OpenGL textures");
		}

		// Use the next available texture.
		numgltextures++;
		texture_index = numgltextures;

		for (int i = 0; i < MAX_GLTEXTURES; ++i)
		{
			if (gltextures_used[i] == false)
			{
				texture_index = i;
				break;
			}
		}
		gltexture_t& texture = gltextures[texture_index];
		gltextures_used[texture_index] = true;

		// Fill in the source data.
		strcpy(texture.identifier, identifier);
		texture.original_width			= width;
		texture.original_height			= height;
		texture.stretch_to_power_of_two	= false;
        texture.bpp                     = bpp;

#ifdef STATIC_PAL
        memset(texture.palette, 0, sizeof(texture.palette));
#endif
	    texture.palette_active          = qfalse;

	    // Fill in the texture description.
		switch(texture.bpp)
		{
			case 1:
				texture.format		= GU_PSM_T8;
				break;
			case 2:
				texture.format		= GU_PSM_4444;
				break;
	        case 3:
				texture.format		= GU_PSM_8888;
				break;
	        case 4:
				texture.format		= GU_PSM_8888;
				break;
			default:
				Sys_Error("Failed bpp!");
		}

		texture.filter			= filter;
		texture.mipmaps			= 0;

		if(forcopy)
		{
			texture.swizzle	        = GU_FALSE;
		}
		else
		{
			texture.swizzle	        = GU_TRUE;
		}

		if (tex_scale_down == true && texture.stretch_to_power_of_two == true)
		{
			texture.width			= std::max(round_down(width),  16U);
			texture.height			= std::max(round_down(height), 16U);
		}
		else
		{
			texture.width			= std::max(round_up(width),  16U);
			texture.height			= std::max(round_up(height), 16U);
		}

		// Allocate the RAM.
		const std::size_t buffer_size = GL_GetTexSize(texture.format, texture.width, texture.height, 0);
		texture.ram	= static_cast<texel*>(memalign(16, buffer_size));
		if (!texture.ram)
		{
			Sys_Error("Out of RAM for lightmap textures.");
		}

		// Allocate the VRAM.
		texture.vram = static_cast<texel*>(valloc(buffer_size));

	    // Upload the texture.
		if(!texture.swizzle)
		{
			switch(texture.bpp)
			{
				case 1:
					GL_Upload8_A(texture_index, data, width, height);
					break;
				case 2:
					GL_Upload16_A(texture_index, data, width, height);
					break;
				case 3:
					GL_Upload24_A(texture_index, data, width, height);
					break;
				case 4:
					GL_Upload32_A(texture_index, data, width, height);
					break;
				default:
					Sys_Error("Failed bpp!");
			}
		}
		else
		{
			switch(texture.bpp)
			{
				case 1:
					GL_Upload8(texture_index, data, width, height);
					break;
		     	case 2:
					GL_Upload16(texture_index, data, width, height);
					break;
				case 3:
					GL_Upload24(texture_index, data, width, height);
					break;
				case 4:
					GL_Upload32(texture_index, data, width, height);
					break;
				default:
					Sys_Error("Failed bpp!");
			}
		}

		if (texture.vram && texture.ram)
		{
			free(texture.ram);
			texture.ram = NULL;
		}
	}
	else
	{
		gltexture_t& texture = gltextures[texture_index];

		if ((width == texture.original_width) && (height == texture.original_height))
		{
	
			    // Upload the texture.
			if(!texture.swizzle)
			{
				switch(texture.bpp)
				{
					case 1:
						GL_Upload8_A(texture_index, data, width, height);
						break;
					case 2:
						GL_Upload16_A(texture_index, data, width, height);
						break;
					case 3:
						GL_Upload24_A(texture_index, data, width, height);
						break;
					case 4:
						GL_Upload32_A(texture_index, data, width, height);
						break;
					default:
						Sys_Error("Failed bpp!");
				}
			}
			else
			{
				switch(texture.bpp)
				{
					case 1:
						GL_Upload8(texture_index, data, width, height);
						break;
					case 2:
						GL_Upload16(texture_index, data, width, height);
						break;
					case 3:
						GL_Upload24(texture_index, data, width, height);
						break;
					case 4:
						GL_Upload32(texture_index, data, width, height);
						break;
					default:
						Sys_Error("Failed bpp!");
				}
			}
		}
		if (texture.vram && texture.ram)
		{
			free(texture.ram);
			texture.ram = NULL;
		}
	}
	// Done.
	return texture_index;
}

/*
================
GL_LoadImages
================
*/
int GL_LoadImages (const char *identifier, int width, int height, const byte *data, qboolean stretch_to_power_of_two, int filter, int mipmap_level, int bpp)
{
	int texture_index = -1;

	tex_scale_down = r_tex_scale_down.value == qtrue;
	
	// See if the texture is already present.
	if (identifier[0])
	{
		for (int i = 0; i < MAX_GLTEXTURES; ++i)
		{
			if (gltextures_used[i] == true)
			{
				const gltexture_t& texture = gltextures[i];
				if (!strcmp (identifier, texture.identifier))
				{
					return i;
				}
			}
		}
	}
	
	// Out of textures?
	if (numgltextures == MAX_GLTEXTURES)
	{		Sys_Error("Out of OpenGL textures");
	}

	// Use the next available texture.
	numgltextures++;
	texture_index = numgltextures;

	for (int i = 0; i < MAX_GLTEXTURES; ++i)
	{
		if (gltextures_used[i] == false)
		{
			texture_index = i;
			break;
		}
	}
	
	gltexture_t& texture = gltextures[texture_index];
	gltextures_used[texture_index] = true;

	// Fill in the source data.
	strcpy(texture.identifier, identifier);
	texture.original_width			= width;
	texture.original_height			= height;
	texture.stretch_to_power_of_two	= stretch_to_power_of_two != qfalse;
	texture.bpp                     = bpp;
#ifdef STATIC_PAL
	memset(texture.palette, 0, sizeof(texture.palette));
#endif
	texture.palette_active          = qfalse;

	// Fill in the texture description.
	switch(texture.bpp)
	{
		case 1:
			texture.format = GU_PSM_T8;
			break;
		case 2:
			texture.format = GU_PSM_4444; //5650, 5551, T16(pal)
			break;
		case 4:
			switch((int)r_texcompr.value)
			{
				// case 32:
				case 0:
					texture.format		= GU_PSM_8888; //T32(pal)
					break;
				case 1:
					texture.format		= GU_PSM_DXT1;
					break;
				case 3:
					texture.format		= GU_PSM_DXT3;
					break;
				case 16:
					texture.format		= GU_PSM_4444;
					break;
				case 5:
				default:
					texture.format		= GU_PSM_DXT5;
					break;
		}
		break;
	}

	texture.filter = filter;
	if(texture.format < GU_PSM_DXT1)
	{
		texture.mipmaps	= mipmap_level;
	}
	else
	{
		texture.mipmaps	= 0;
	}
	
	switch(texture.format)
	{
		case GU_PSM_T8:
		case GU_PSM_4444:
		case GU_PSM_8888:
			texture.swizzle	= GU_TRUE;
			break;
		case GU_PSM_DXT1:
		case GU_PSM_DXT3:
		case GU_PSM_DXT5:
			texture.swizzle	= GU_FALSE;
			break;
	}

	if (tex_scale_down == true && texture.stretch_to_power_of_two == true)
	{
		texture.width			= std::max(round_down(width), 32U);
		texture.height			= std::max(round_down(height),32U);
	}
	else
	{
		texture.width			= std::max(round_up(width), 32U);
		texture.height			= std::max(round_up(height),32U);
	}

	if(texture.format < GU_PSM_DXT1)
	{
		for (int i=0; i <= mipmap_level;i++)
		{
			int div = (int) powf(2,i);
			if((texture.width / div) > 16 && (texture.height / div) > 16 ) 
			{
				texture.mipmaps = i;
			}
		}
	}

	// Do we really need to resize the texture?
	if (texture.stretch_to_power_of_two)
	{
		// Not if the size hasn't changed.
		texture.stretch_to_power_of_two = (texture.width != width) || (texture.height != height);
	}

	// Allocate the RAM.
	std::size_t buffer_size = GL_GetTexSize(texture.format, texture.width, texture.height, 0);

	Con_DPrintf("Loading: %s [%dx%d](%0.2f KB)\n",texture.identifier,texture.width,texture.height, (float) buffer_size/1024);
	
	//Con_Printf("Loading: %s [%dx%d](%d Bytes) (Format: %d, BPP: %d)\n",texture.identifier,texture.width,texture.height, buffer_size,texture.format,bpp);

	if (texture.mipmaps > 0 && texture.format < GU_PSM_DXT1)
	{
		int size_incr = buffer_size/4;
		for (int i= 1;i <= texture.mipmaps;i++)
		{
			buffer_size += size_incr;
			size_incr = size_incr/4;
		}
	}

	texture.ram	= static_cast<texel*>(memalign(16, buffer_size));

	if (!texture.ram)
	{
		Sys_Error("Out of RAM for images.");
	}

	// Allocate the VRAM.
	texture.vram = static_cast<texel*>(valloc(buffer_size));
	// Upload the texture.
	switch(texture.format)
	{
		case GU_PSM_T8:
			GL_Upload8(texture_index, data, width, height);
			break;
		case GU_PSM_4444:
			GL_Upload16(texture_index, data, width, height);
			break;
		case GU_PSM_8888:
			GL_Upload32(texture_index, data, width, height);
			break;
		case GU_PSM_DXT1:
		case GU_PSM_DXT3:
		case GU_PSM_DXT5:
			GL_UploadDXT(texture_index, data, width, height);
			break;
	}
	if (texture.vram && texture.ram)
	{
		free(texture.ram);
		texture.ram = NULL;
	}
	// Done.
	return texture_index;
}

int GL_LoadTexture8Pal32 (char *identifier, int width, int height, byte *data, byte *pal)
{
	int			i, s;
	s = width*height;

	if (s&3)
		Sys_Error ("GL_Upload8: s&3");

	byte *trans = (byte*)memalign(16, s*4);
	for (i=0 ; i<s ; i++)
	{
		trans[i*4+0] = gammatable[pal[data[i]*4+0]];
		trans[i*4+1] = gammatable[pal[data[i]*4+1]];
		trans[i*4+2] = gammatable[pal[data[i]*4+2]];
		trans[i*4+3] = gammatable[pal[data[i]*4+3]];
	}

    int index = GL_LoadImages (identifier, width, height, trans, qtrue, GU_LINEAR, 0, 4);
	free(trans);
	return index;
}

int GL_LoadTexture8Pal24 (char *identifier, int width, int height, byte *data, byte *pal)
{
	int			i, s;
	s = width*height;

	if (s&3)
		Sys_Error ("GL_Upload8: s&3");

	byte *trans = (byte*)memalign(16, s*4);
	for (i=0 ; i<s ; i++)
	{
		trans[i*4+0] = gammatable[pal[data[i]*3+0]];
		trans[i*4+1] = gammatable[pal[data[i]*3+1]];
		trans[i*4+2] = gammatable[pal[data[i]*3+2]];
		trans[i*4+3] = 255;
	}

    int index = GL_LoadImages (identifier, width, height, trans, qtrue, GU_LINEAR, 0, 4);
	free(trans);
	return index;
}

void GL_Upload4(int texture_index, const byte *data, int width, int height)
{
	if ((texture_index < 0) || (texture_index >= MAX_GLTEXTURES) || gltextures_used[texture_index] == false)
	{
		Sys_Error("Invalid texture index %d", texture_index);
	}

	const gltexture_t& texture = gltextures[texture_index];

	// Check that the texture matches.
	if ((width != texture.original_width) != (height != texture.original_height))
	{
		Sys_Error("Attempting to upload a texture which doesn't match the destination");
	}

	// Create a temporary buffer to use as a source for swizzling.
	std::size_t buffer_size = (width * height) / 2;

	memcpy(texture.ram, data, buffer_size);
	memcpy(texture.palette, data + buffer_size, 16 * 4);
	int i;

	// Copy to VRAM?
	/*if (texture.vram)
	{
		// Copy.
		memcpy(texture.vram, texture.ram, buffer_size);

		// Flush the data cache.
		sceKernelDcacheWritebackRange(texture.vram, buffer_size);
	}*/

	// Flush the data cache.
	sceKernelDcacheWritebackRange(texture.ram, buffer_size);
}

int GL_LoadTexture4(const char *identifier, unsigned int width, unsigned int height, const byte *data, int filter)
{
	int texture_index = -1;

	tex_scale_down = r_tex_scale_down.value == qtrue;
	
	if (identifier[0])
	{
		for (int i = 0; i < MAX_GLTEXTURES; ++i)
		{
			if (gltextures_used[i] == true)
			{
				const gltexture_t& texture = gltextures[i];
				if (!strcmp(identifier, texture.identifier))
				{
					return i;
				}
			}
		}
	}

	// Out of textures?
	if (numgltextures == MAX_GLTEXTURES)
	{
		Sys_Error("Out of OpenGL textures");
	}

	// Use the next available texture.
	numgltextures++;
	texture_index = numgltextures;

	for (int i = 0; i < MAX_GLTEXTURES; ++i)
	{
		if (gltextures_used[i] == false) {
			texture_index = i;
			break;
		}
	}
	gltexture_t& texture = gltextures[texture_index];
	gltextures_used[texture_index] = true;

	// Fill in the source data.
	strcpy(texture.identifier, identifier);
	texture.original_width = texture.width = width;
	texture.original_height = texture.height = height;
	texture.stretch_to_power_of_two = qfalse;

	// Fill in the texture description.
	texture.format = GU_PSM_T4;
	texture.filter = filter;
	texture.mipmaps = 0; // mipmap_level;


	Con_DPrintf("Loading: %s [%dx%d](%0.2f KB)\n", texture.identifier, texture.width, texture.height, (float)(texture.width*texture.height) / 1024);

	// Allocate the RAM.
	std::size_t buffer_size = (texture.width * texture.height) / 2; // 4bpp

	texture.ram = static_cast<texel*>(memalign(16, buffer_size));
	texture.palette = static_cast<unsigned char*>(memalign(16, 16 * 4));

	if (!texture.ram || !texture.palette)
	{
		Sys_Error("Out of RAM for textures.");
	}

	// Allocate the VRAM.
	//texture.vram = static_cast<texel*>(quake::vram::allocate(buffer_size));

	// Upload the texture.
	GL_Upload4(texture_index, data, width, height);

	if (texture.vram && texture.ram) {
		free(texture.ram);
		texture.ram = NULL;
	}
	// Done.
	return texture_index;	
}
