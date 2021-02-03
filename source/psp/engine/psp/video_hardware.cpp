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

#include <algorithm>
#include <cstddef>

#include <pspdisplay.h>
#include <pspgu.h>
#include <pspgum.h>
#include <pspkernel.h>
#include <psputility.h>
#include <pspdebug.h>
#include <malloc.h>
#include <limits.h>
extern "C"
{
#include "../quakedef.h"
}

#include <vram.h>

#include "video_hardware_images.h"

#include "iridlibs/perflib.h"

#ifdef _WIN32
# define ALIGNED(x)
#else
# define ALIGNED(x) __attribute__((aligned(x)))
#endif

#define DLIST_SIZE_KB 512 //256

namespace quake
{
	namespace video
	{
		// Types.
        //ScePspRGB565;
        //ScePspRGBA8888
		typedef ScePspRGBA8888	pixel;
		typedef u8				texel;
		typedef u16				depth_value;

		// Constants.
		static const std::size_t	screen_width	= 480;
		static const std::size_t	screen_height	= 272;
		static const std::size_t	palette_size	= 256;
		static pixel* 				display_buffer	= 0;
		static pixel*				draw_buffer		= 0;
		static depth_value*			depth_buffer	= 0;

		//! The GU display list.
		//! @note	Aligned to 64 bytes so it doesn't share a cache line with anything.
		unsigned int ALIGNED(64)	display_list[DLIST_SIZE_KB * 1024];
	}
}

using namespace quake;
using namespace quake::video;

extern qboolean depthfl;

void* framebuffer;

// Regular globals.
ScePspRGBA8888 ALIGNED(16)	d_8to24table[palette_size];
ScePspRGBA8888 ALIGNED(16)	d_8to24tableLM[palette_size];
ScePspRGBA8888 ALIGNED(16)	d_8to24tableQ2[palette_size];
ScePspRGBA8888 ALIGNED(16)	d_8to24tableH2[palette_size];
int reloaded_pallete = 1;

extern cvar_t	r_vsync;
extern cvar_t	r_dithering;

void VID_ConvectPalette(ScePspRGBA8888 *out, unsigned char* in)
{
    // Convert the palette to PSP format.
	for (ScePspRGBA8888* color = &out[0]; color < &out[palette_size]; ++color)
	{
		const unsigned int r = *in++;
		const unsigned int g = *in++;
		const unsigned int b = *in++;
		*color = GU_RGBA(r, g, b, 0xff);
	}
}
void VID_InitPaleteLM()
{
	// Convert the palette to PSP format.
	ScePspRGBA8888* color2 = &d_8to24tableLM[0];
	for (unsigned int i=0; color2 < &d_8to24tableLM[palette_size]; ++color2, i++)
	{
		*color2 = GU_RGBA(i, i, i, i);
	}
}

void VID_SetPaletteLM()
{
	// Upload the palette.
	sceGuClutMode(GU_PSM_8888, 0, palette_size - 1, 0);
	sceKernelDcacheWritebackRange(d_8to24tableLM, sizeof(d_8to24tableLM));
	sceGuClutLoad(palette_size / 8, d_8to24tableLM);
    reloaded_pallete = 1;
}

void VID_SetPaletteTX()
{
	// Upload the palette.
	sceGuClutMode(GU_PSM_8888, 0, palette_size - 1, 0);
	sceKernelDcacheWritebackRange(d_8to24table, sizeof(d_8to24table));
	sceGuClutLoad(palette_size / 8, d_8to24table);
	reloaded_pallete = 1;
}

void VID_SetPalette4(unsigned char* clut4pal) {
	sceGuClutMode(GU_PSM_8888, 0, 0xFF, 0);
	sceKernelDcacheWritebackRange(clut4pal, sizeof(clut4pal));
	sceGuClutLoad(2, clut4pal);
}

void VID_SetPalette(unsigned char* palette)
{
	// Convert the palette to PSP format.
	for (ScePspRGBA8888* color = &d_8to24table[0]; color < &d_8to24table[palette_size]; ++color)
	{
		const unsigned int r = *palette++;
		const unsigned int g = *palette++;
		const unsigned int b = *palette++;
		*color = GU_RGBA(r, g, b, 0xff);
	}

	// Color 255 is transparent black.
	// This is a bit of a dirty hack.
	d_8to24table[255] = 0;

	// Upload the palette.
	sceGuClutMode(GU_PSM_8888, 0, palette_size - 1, 0);
	sceKernelDcacheWritebackRange(d_8to24table, sizeof(d_8to24table));
	sceGuClutLoad(palette_size / 8, d_8to24table);
	reloaded_pallete = 1;
}

void VID_ShiftPalette(unsigned char* palette)
{
	VID_SetPalette(palette);
}

void VID_Init(unsigned char* palette)
{
	Sys_Printf("VID_Init\n");

	// Allocate the buffers.
	display_buffer	= static_cast<pixel*>(valloc(screen_height * 512 * sizeof(pixel)));
	if (!display_buffer)
	{
		Sys_Error("Couldn't allocate display buffer");
	}

	draw_buffer	= static_cast<pixel*>(valloc(screen_height * 512 * sizeof(pixel)));
	if (!draw_buffer)
	{
		Sys_Error("Couldn't allocate draw buffer");
	}

	depth_buffer	= static_cast<depth_value*>(valloc(screen_height * 512 * sizeof(depth_value)));
	if (!depth_buffer)
	{
		Sys_Error("Couldn't allocate depth buffer");
	}

	// Initialise the GU.
	sceGuInit();

	// Set up the GU.
	sceGuStart(GU_DIRECT, display_list);
	{
		//sceGuDrawBuffer(GU_PSM_5650, vrelptr(draw_buffer), 512);
		sceGuDrawBuffer(GU_PSM_8888, vrelptr(draw_buffer), 512);
		sceGuDispBuffer(screen_width, screen_height, vrelptr(display_buffer), 512);
		sceGuDepthBuffer(vrelptr(depth_buffer), 512);

		// Set the rendering offset and viewport.
		sceGuOffset(2048 - (screen_width / 2), 2048 - (screen_height / 2));
		sceGuViewport(2048, 2048, screen_width, screen_height);

		// Set up scissoring.
		sceGuEnable(GU_SCISSOR_TEST);
		sceGuScissor(0, 0, screen_width, screen_height);

		// Set up texturing.
		sceGuEnable(GU_TEXTURE_2D);

		// Set up clearing.
		sceGuClearDepth(65535);
		sceGuClearColor(GU_RGBA(0x10,0x20,0x40,0xff));

		// Set up depth.
		sceGuDepthRange(0, 65535);
		sceGuDepthFunc(GU_LEQUAL);
		sceGuEnable(GU_DEPTH_TEST);

		// Set the matrices.
		sceGumMatrixMode(GU_PROJECTION);
		sceGumLoadIdentity();
		sceGumUpdateMatrix();
		sceGumMatrixMode(GU_VIEW);
		sceGumLoadIdentity();
		sceGumUpdateMatrix();
		sceGumMatrixMode(GU_MODEL);
		sceGumLoadIdentity();
		sceGumUpdateMatrix();

		// Set up culling.
		sceGuFrontFace(GU_CW);
		sceGuEnable(GU_CULL_FACE);
		sceGuEnable(GU_CLIP_PLANES);

		// Set up blending.
		sceGuBlendFunc(GU_ADD, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, 0, 0);
	}
	
	sceGuFinish();
	sceGuSync(0,0);

	// Turn on the display.
	sceDisplayWaitVblankStart();
	sceGuDisplay(GU_TRUE);

	// Set up Quake's video parameters.
	vid.aspect			= (static_cast<float>(screen_height) / static_cast<float>(screen_width)) * (4.0f / 3.0f);
	vid.buffer			= 0;
	vid.colormap		= host_colormap;
	vid.colormap16		= 0;
	vid.conbuffer		= 0;
	vid.conheight		= screen_height;
	vid.conrowbytes		= 0;
	vid.conwidth		= screen_width;
	vid.direct			= 0;
	vid.fullbright		= palette_size - LittleLong(*((int *) vid.colormap + 2048));
	vid.height			= screen_height;
	vid.maxwarpheight	= screen_width;
	vid.maxwarpwidth	= screen_height;
	vid.numpages		= INT_MAX;
	vid.recalc_refdef	= 0;
	vid.rowbytes		= 0;
	vid.width			= screen_width;
	
	// Start a render.
	sceGuStart(GU_DIRECT, display_list);

	// Set the palette.
	VID_SetPalette(palette);
	VID_InitPaleteLM();
	VID_ConvectPalette(d_8to24tableQ2, host_q2pal);
	VID_ConvectPalette(d_8to24tableH2, host_h2pal);
}

void VID_Shutdown(void)
{
	// Finish rendering.
	sceGuFinish();
	sceGuSync(0,0);

	// Shut down the display.
	sceGuTerm();

	// Free the buffers.
	vfree(depth_buffer);
	depth_buffer = 0;
	vfree(draw_buffer);
	draw_buffer = 0;
	vfree(display_buffer);
	display_buffer = 0;
}

void GL_BeginRendering (int *x, int *y, int *width, int *height)
{
	PFL_BeginGPURecord();
	*x = 2048;
	*y = 2048;
	*width = screen_width;
	*height = screen_height;
	
	if (r_dithering.value)
		sceGuEnable(GU_DITHER);
	else
		sceGuDisable(GU_DITHER);
}

void GL_EndRendering (void)
{
	// Finish rendering.
	sceGuFinish();
	sceGuSync(0, 0);
	PFL_EndGPURecord();

	// At the moment only do this if we are in network mode, once we get above
	// 60fps we might as well leave it on for all games
	if (tcpipAvailable || r_vsync.value)
		sceDisplayWaitVblankStart();

    // Switch the buffers.
	sceGuSwapBuffers();
	std::swap(draw_buffer, display_buffer);

	// Start a new render.
	sceGuStart(GU_DIRECT, display_list);
}

void GL_GetPixelsBGR(byte *buffer, int width, int height, int i)
{
    for (int y = 0; y < height; ++y)
	{
		const pixel* src = display_buffer + ((height - y - 1) * 512);
		for (int x = 0; x < width; ++x)
		{
			const pixel argb = *src++;
#if 0
            buffer[i++]	= ((argb >> 11) & 0x1f) << 3; //B
			buffer[i++]	= ((argb >> 5 ) & 0x3f) << 2; //G
			buffer[i++]	= (argb & 0x1f)         << 3; //R
#else
			buffer[i++]	= (argb >> 16) & 0xff;//B
			buffer[i++]	= (argb >> 8) & 0xff; //G
			buffer[i++]	= argb & 0xff;        //R
#endif
		}
	}

}

void GL_GetPixelsRGB(byte *buffer, int width, int height, int i)
{
    for (int y = 0; y < height; ++y)
	{
		const pixel* src = display_buffer + ((height - y - 1) * 512);
		for (int x = 0; x < width; ++x)
		{
			const pixel argb = *src++;
#if 0
            buffer[i++]	= (argb & 0x1f)         << 3; //R
			buffer[i++]	= ((argb >> 5 ) & 0x3f) << 2; //G
			buffer[i++]	= ((argb >> 11) & 0x1f) << 3; //B
#else
			buffer[i++]	= ((argb)& 0xff);       //R
            buffer[i++]	= ((argb >> 8)& 0xff);  //G
			buffer[i++]	= ((argb >> 16)& 0xff); //B
#endif
		}
	}

}

void GL_GetPixelsRGBA(byte *buffer, int width, int height, int i)
{
    for (int y = 0; y < height; ++y)
	{
		const pixel* src = display_buffer + ((height - y - 1) * 512);
		for (int x = 0; x < width; ++x)
		{
			const pixel argb = *src++;
#if 0
            buffer[i++]	= (argb & 0x1f)         << 3; //R
			buffer[i++]	= ((argb >> 5 ) & 0x3f) << 2; //G
			buffer[i++]	= ((argb >> 11) & 0x1f) << 3; //B
            buffer[i++]	= 0xff;                       //A
#else
			buffer[i++]	= ((argb)& 0xff);       //R
            buffer[i++]	= ((argb >> 8)& 0xff);  //G
			buffer[i++]	= ((argb >> 16)& 0xff); //B
            buffer[i++]	= ((argb >> 24)& 0xff); //A
#endif
		}
	}

}

u32 GL_GetDrawBuffer(void)
{
	return (u32)vrelptr(draw_buffer);
}

void D_StartParticles (void)
{
	sceGuDepthMask(GU_TRUE);
	if (r_particles_simple.value == qtrue)
	{
		sceGuDisable(GU_TEXTURE_2D);
	}
	else
	{
		sceGuDisable(GU_FOG);
		GL_Bind(particletexture);
		sceGuEnable(GU_BLEND);
		sceGuDepthMask(GU_TRUE);
		sceGuBlendFunc(GU_ADD, GU_SRC_ALPHA, GU_FIX, 0, 0xFFFFFFFF);
		sceGuTexFunc(GU_TFX_MODULATE , GU_TCC_RGBA);
	}
}

void D_EndParticles (void)
{
	sceGuDepthMask(GU_FALSE);
	if (r_particles_simple.value == qtrue)
	{
		 sceGuEnable(GU_TEXTURE_2D);
	}
	else
	{
	     sceGuEnable(GU_FOG);
		 sceGuDisable(GU_BLEND);
	     sceGuDepthMask(GU_FALSE);
		 sceGuTexFunc(GU_TFX_REPLACE, GU_TCC_RGBA);
		 sceGuBlendFunc(GU_ADD, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, 0, 0);
	}
}



static int BufIdx  = 0;
static int BufSize = 0;

psp_particle* D_CreateBuffer (int size)
{
	psp_particle* const vertices = static_cast<psp_particle*>(sceGuGetMemory(size*sizeof(psp_particle)));
	
	BufSize = size;
	BufIdx  = 0;
	
	return vertices;
}


void D_DeleteBuffer (psp_particle* vertices)
{
    if (BufIdx > 0)
	{
    	sceGuDrawArray(GU_SPRITES, GU_VERTEX_32BITF|GU_TEXTURE_32BITF|GU_COLOR_8888, BufIdx, 0, vertices);
    	BufIdx = 0;
    	BufSize = -1;
    }
		
}

int D_DrawParticleBuffered (psp_particle* vertices, particle2_t *pparticle, vec3_t up, vec3_t right, float scale)
{
	unsigned int color = d_8to24table[static_cast<int>(pparticle->color)];
	int i = BufIdx;
	
	vertices[i].first.x = pparticle->org[0];
	vertices[i].first.y = pparticle->org[1];
	vertices[i].first.z = pparticle->org[2];
	vertices[i].first.s = 0.0;              
	vertices[i].first.t = 0.0;              
	vertices[i].first.color = color;        
			
	vertices[i].second.x = pparticle->org[0] + scale*(up[0] + right[0]);        
	vertices[i].second.y = pparticle->org[1] + scale*(up[1] + right[1]);        
	vertices[i].second.z = pparticle->org[2] + scale*(up[2] + right[2]);        
	vertices[i].second.s = 1.0;                                                 
	vertices[i].second.t = 1.0;                                                 
	vertices[i].second.color = color;                                           
               
    BufIdx++;
    
    if (BufIdx >= BufSize)
	{
    	sceGuDrawArray(GU_SPRITES, GU_VERTEX_32BITF|GU_TEXTURE_32BITF|GU_COLOR_8888, BufSize, 0, vertices);
    	BufIdx = 0;
    	BufSize = -1;
    	return -1;
    }
    
    return BufIdx;    	            
}                      
                       
                       
void D_DrawParticle (particle2_t *pparticle, vec3_t up, vec3_t right, float scale)
{
	unsigned int color = d_8to24table[static_cast<int>(pparticle->color)];
	
	struct part_vertex
	{
		float s, t;
		unsigned int color;
		float x, y, z;
	};

	part_vertex* const vertices = static_cast<part_vertex*>(sceGuGetMemory(2*sizeof(part_vertex)));

	vertices[0].x = pparticle->org[0];
	vertices[0].y = pparticle->org[1];
	vertices[0].z = pparticle->org[2];
	vertices[0].s = 0.0;
	vertices[0].t = 0.0;
	vertices[0].color = color;
	
	vertices[1].x = pparticle->org[0] + scale*(up[0] + right[0]);
	vertices[1].y = pparticle->org[1] + scale*(up[1] + right[1]);
	vertices[1].z = pparticle->org[2] + scale*(up[2] + right[2]);
	vertices[1].s = 1.0;
	vertices[1].t = 1.0;
	vertices[1].color = color;
	
	sceGuDrawArray(GU_SPRITES, GU_VERTEX_32BITF|GU_TEXTURE_32BITF|GU_COLOR_8888, 2, 0, vertices);

}


/* 
============================================================================== 
 
						SCREEN SHOTS 
 
============================================================================== 
*/
typedef struct _TargaHeader {
	unsigned char 	id_length, colormap_type, image_type;
	unsigned short	colormap_index, colormap_length;
	unsigned char	colormap_size;
	unsigned short	x_origin, y_origin, width, height;
	unsigned char	pixel_size, attributes;
} TargaHeader;

int Image_WriteJPEG (char *filename, int compression, byte *pixels, int width, int height);

/*
==================
SCR_ScreenShot_f
==================
*/
void SCR_ScreenShot_f (void)
{
	byte		*buffer;
	char		name[80];
	char		checkname[MAX_OSPATH];
    int		    buffersize = glwidth * glheight * 3;
//
// find a file name to save it to
//
	strcpy(name,"shots/DQshot00.jpg");

	int i;

	for (i=0 ; i<=100 ; i++)
	{
        name[12] = i/10 + '0';
		name[13] = i%10 + '0';
		sprintf (checkname, "%s/%s", com_gamedir, name);
		if (Sys_FileTime(checkname) == -1)
			break;	// file doesn't exist
	}

	if (i==100)
	{
		Con_Printf ("SCR_ScreenShot_f: Couldn't create a TGA file\n");
		return;
 	}

	buffer = static_cast<byte*>(malloc(buffersize));
	memset(buffer, 0, buffersize);

	GL_GetPixelsRGB(buffer, glwidth, glheight, 0);

    Image_WriteJPEG (name, 75, buffer + buffersize - 3 * glwidth, -glwidth, glheight);

	free (buffer);

	Con_Printf ("Wrote %s\n", name);
}

#if 0
//======================Utility dialog functions================================

pspUtilityMsgDialogParams dialog;

static void ConfigureDialog(pspUtilityMsgDialogParams *dialog, size_t dialog_size)
{
    memset(dialog, 0, dialog_size);

    dialog->base.size = dialog_size;
    sceUtilityGetSystemParamInt(PSP_SYSTEMPARAM_ID_INT_LANGUAGE,
				&dialog->base.language); // Prompt language
    sceUtilityGetSystemParamInt(PSP_SYSTEMPARAM_ID_INT_UNKNOWN,
				&dialog->base.buttonSwap); // X/O button swap

    dialog->base.graphicsThread = 0x11;
    dialog->base.accessThread = 0x13;
    dialog->base.fontThread = 0x12;
    dialog->base.soundThread = 0x10;
}

void ShowErrorDialog(const unsigned int error)
{
    ConfigureDialog(&dialog, sizeof(dialog));
    dialog.mode = PSP_UTILITY_MSGDIALOG_MODE_ERROR;
	dialog.options = PSP_UTILITY_MSGDIALOG_OPTION_ERROR;
    dialog.errorValue = error;

    sceUtilityMsgDialogInitStart(&dialog);

    for(;;)
	{

	
	switch(sceUtilityMsgDialogGetStatus())
	{

	case PSP_UTILITY_DIALOG_VISIBLE:
	    sceUtilityMsgDialogUpdate(1);
	    break;

	case PSP_UTILITY_DIALOG_QUIT:
	    sceUtilityMsgDialogShutdownStart();
	    break;

	case PSP_UTILITY_DIALOG_NONE:
	    return;

	}

   ..upd main frame
	}
}

void ShowMessageDialog(const char *message, int enableYesno)
{
    ConfigureDialog(&dialog, sizeof(dialog));
    dialog.mode = PSP_UTILITY_MSGDIALOG_MODE_TEXT;
	dialog.options = PSP_UTILITY_MSGDIALOG_OPTION_TEXT;

	if(enableYesno)
		dialog.options |= PSP_UTILITY_MSGDIALOG_OPTION_YESNO_BUTTONS|PSP_UTILITY_MSGDIALOG_OPTION_DEFAULT_NO;

    strcpy(dialog.message, message);

    sceUtilityMsgDialogInitStart(&dialog);

    for(;;)
	{



	switch(sceUtilityMsgDialogGetStatus())
	{

	case 2:
	    sceUtilityMsgDialogUpdate(1);
	    break;

	case 3:
	    sceUtilityMsgDialogShutdownStart();
	    break;

	case 0:
	    return;

	}

	..upd main frame
	}

}

void M_Exit_f (void)
{
    ShowMessageDialog("      Really quit?     ", 1);

	if(dialog.buttonPressed == PSP_UTILITY_MSGDIALOG_RESULT_YES)
	{
		CL_Disconnect ();
	    Host_ShutdownServer(qfalse);
	    Sys_Quit ();
    }
}
#endif
