/*
Copyright (C) 1996-2001 Id Software, Inc.
Copyright (C) 2002-2009 John Fitzgibbons and others
Copyright (C) 2007-2008 Kristian Duske
Copyright (C) 2010-2014 QuakeSpasm developers

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
// gl_vidsdl.c -- SDL GL vid component

#include "quakedef.h"
#include "cfgfile.h"
#include "bgmusic.h"
#include "resource.h"

#include <switch.h>
#include <SDL2/SDL.h>
#include <EGL/egl.h>
#include "glad/glad.h"

#define MAX_MODE_LIST	600 //johnfitz -- was 30
#define MAX_BPPS_LIST	5
#define MAX_RATES_LIST	20
#define WARP_WIDTH		320
#define WARP_HEIGHT		200
#define MAXWIDTH		10000
#define MAXHEIGHT		10000

#define DEFAULT_SDL_FLAGS	SDL_OPENGL

#define DEFAULT_REFRESHRATE	60

Framebuffer fb;

typedef struct {
	int			width;
	int			height;
	int			refreshrate;
	int			bpp;
} vmode_t;

static const char *gl_vendor;
static const char *gl_renderer;
static const char *gl_version;
static int gl_version_major;
static int gl_version_minor;
static const char *gl_extensions;
static char * gl_extensions_nice;

static vmode_t	modelist[MAX_MODE_LIST];
static int		nummodes;

static qboolean	vid_initialized = false;

static SDL_Window	*draw_context;
static SDL_Renderer	*draw_renderer;

static EGLDisplay s_display;
static EGLSurface s_surface;
static EGLContext s_context;

static qboolean	vid_locked = false; //johnfitz
static qboolean	vid_changed = false;

static qboolean fb_big = false;

static void VID_Menu_Init (void); //johnfitz
static void VID_Menu_f (void); //johnfitz
static void VID_MenuDraw (void);
static void VID_MenuKey (int key);

static void ClearAllStates (void);
static void GL_Init (void);
static void GL_SetupState (void); //johnfitz

viddef_t	vid;				// global video state
modestate_t	modestate = MS_UNINIT;
qboolean	scr_skipupdate;

qboolean gl_mtexable = false;
qboolean gl_texture_env_combine = false; //johnfitz
qboolean gl_texture_env_add = false; //johnfitz
qboolean gl_swap_control = false; //johnfitz
qboolean gl_anisotropy_able = false; //johnfitz
float gl_max_anisotropy; //johnfitz
qboolean gl_texture_NPOT = false; //ericw
qboolean gl_vbo_able = false; //ericw
qboolean gl_glsl_able = false; //ericw
GLint gl_max_texture_units = 0; //ericw
qboolean gl_glsl_gamma_able = false; //ericw
qboolean gl_glsl_alias_able = false; //ericw
int gl_stencilbits;

PFNGLMULTITEXCOORD2FARBPROC GL_MTexCoord2fFunc = NULL; //johnfitz
PFNGLACTIVETEXTUREARBPROC GL_SelectTextureFunc = NULL; //johnfitz
PFNGLCLIENTACTIVETEXTUREARBPROC GL_ClientActiveTextureFunc = NULL; //ericw
PFNGLBINDBUFFERARBPROC GL_BindBufferFunc = NULL; //ericw
PFNGLBUFFERDATAARBPROC GL_BufferDataFunc = NULL; //ericw
PFNGLBUFFERSUBDATAARBPROC GL_BufferSubDataFunc = NULL; //ericw
PFNGLDELETEBUFFERSARBPROC GL_DeleteBuffersFunc = NULL; //ericw
PFNGLGENBUFFERSARBPROC GL_GenBuffersFunc = NULL; //ericw

QS_PFNGLCREATESHADERPROC GL_CreateShaderFunc = NULL; //ericw
QS_PFNGLDELETESHADERPROC GL_DeleteShaderFunc = NULL; //ericw
QS_PFNGLDELETEPROGRAMPROC GL_DeleteProgramFunc = NULL; //ericw
QS_PFNGLSHADERSOURCEPROC GL_ShaderSourceFunc = NULL; //ericw
QS_PFNGLCOMPILESHADERPROC GL_CompileShaderFunc = NULL; //ericw
QS_PFNGLGETSHADERIVPROC GL_GetShaderivFunc = NULL; //ericw
QS_PFNGLGETSHADERINFOLOGPROC GL_GetShaderInfoLogFunc = NULL; //ericw
QS_PFNGLGETPROGRAMIVPROC GL_GetProgramivFunc = NULL; //ericw
QS_PFNGLGETPROGRAMINFOLOGPROC GL_GetProgramInfoLogFunc = NULL; //ericw
QS_PFNGLCREATEPROGRAMPROC GL_CreateProgramFunc = NULL; //ericw
QS_PFNGLATTACHSHADERPROC GL_AttachShaderFunc = NULL; //ericw
QS_PFNGLLINKPROGRAMPROC GL_LinkProgramFunc = NULL; //ericw
QS_PFNGLBINDATTRIBLOCATIONFUNC GL_BindAttribLocationFunc = NULL; //ericw
QS_PFNGLUSEPROGRAMPROC GL_UseProgramFunc = NULL; //ericw
QS_PFNGLGETATTRIBLOCATIONPROC GL_GetAttribLocationFunc = NULL; //ericw
QS_PFNGLVERTEXATTRIBPOINTERPROC GL_VertexAttribPointerFunc = NULL; //ericw
QS_PFNGLENABLEVERTEXATTRIBARRAYPROC GL_EnableVertexAttribArrayFunc = NULL; //ericw
QS_PFNGLDISABLEVERTEXATTRIBARRAYPROC GL_DisableVertexAttribArrayFunc = NULL; //ericw
QS_PFNGLGETUNIFORMLOCATIONPROC GL_GetUniformLocationFunc = NULL; //ericw
QS_PFNGLUNIFORM1IPROC GL_Uniform1iFunc = NULL; //ericw
QS_PFNGLUNIFORM1FPROC GL_Uniform1fFunc = NULL; //ericw
QS_PFNGLUNIFORM3FPROC GL_Uniform3fFunc = NULL; //ericw
QS_PFNGLUNIFORM4FPROC GL_Uniform4fFunc = NULL; //ericw

//====================================

//johnfitz -- new cvars
static cvar_t	vid_fullscreen = {"vid_fullscreen", "0", CVAR_ARCHIVE};	// QuakeSpasm, was "1"
static cvar_t	vid_width = {"vid_width", "800", CVAR_ARCHIVE};		// QuakeSpasm, was 640
static cvar_t	vid_height = {"vid_height", "600", CVAR_ARCHIVE};	// QuakeSpasm, was 480
static cvar_t	vid_bpp = {"vid_bpp", "16", CVAR_ARCHIVE};
static cvar_t	vid_refreshrate = {"vid_refreshrate", "60", CVAR_ARCHIVE};
static cvar_t	vid_vsync = {"vid_vsync", "0", CVAR_ARCHIVE};
static cvar_t	vid_fsaa = {"vid_fsaa", "0", CVAR_ARCHIVE}; // QuakeSpasm
static cvar_t	vid_desktopfullscreen = {"vid_desktopfullscreen", "0", CVAR_ARCHIVE}; // QuakeSpasm
static cvar_t	vid_borderless = {"vid_borderless", "0", CVAR_ARCHIVE}; // QuakeSpasm
//johnfitz

cvar_t		vid_gamma = {"gamma", "1", CVAR_ARCHIVE}; //johnfitz -- moved here from view.c
cvar_t		vid_contrast = {"contrast", "1", CVAR_ARCHIVE}; //QuakeSpasm, MarkV

//==========================================================================
//
//  HARDWARE GAMMA -- johnfitz
//
//==========================================================================

#define	USE_GAMMA_RAMPS			0

#if USE_GAMMA_RAMPS
static unsigned short vid_gamma_red[256];
static unsigned short vid_gamma_green[256];
static unsigned short vid_gamma_blue[256];

static unsigned short vid_sysgamma_red[256];
static unsigned short vid_sysgamma_green[256];
static unsigned short vid_sysgamma_blue[256];
#endif

static qboolean	gammaworks = false;	// whether hw-gamma works
static int fsaa;

int		texture_mode = GL_LINEAR;
int		texture_extension_number = 1;

/*
================
SWITCH EGL STUFF
================
*/

static void SetMesaConfig (void)
{
	// Uncomment below to disable error checking and save CPU time (useful for production):
	// setenv("MESA_NO_ERROR", "1", 1);

	// Uncomment below to enable Mesa logging:
	// setenv("EGL_LOG_LEVEL", "debug", 1);
	// setenv("MESA_VERBOSE", "all", 1);
	// setenv("NOUVEAU_MESA_DEBUG", "1", 1);

	// Uncomment below to enable shader debugging in Nouveau:
	// setenv("NV50_PROG_OPTIMIZE", "0", 1);
	// setenv("NV50_PROG_DEBUG", "1", 1);
	// setenv("NV50_PROG_CHIPSET", "0x120", 1);
	setenv("MESA_GL_VERSION_OVERRIDE", "3.2COMPAT", 1);
}

static qboolean InitEGL (NWindow *input_win)
{

	// Connect to the EGL default display
	s_display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
	if (!s_display)
	{
		Sys_Error("Could not connect to display! error: %d", eglGetError());
		goto _fail0;
	}

	// Initialize the EGL display connection
	eglInitialize(s_display, NULL, NULL);

	if (eglBindAPI(EGL_OPENGL_API) == EGL_FALSE)
	{
		Sys_Error("Could not set API! error: %d", eglGetError());
		goto _fail1;
	}



	// Get an appropriate EGL framebuffer configuration
	EGLConfig config;
	EGLint numConfigs;
	static const EGLint attributeList[] =
	{
		EGL_RED_SIZE, 8,
		EGL_GREEN_SIZE, 8,
		EGL_BLUE_SIZE, 8,
		EGL_DEPTH_SIZE, 24,
		EGL_NONE
	};
	eglChooseConfig(s_display, attributeList, &config, 1, &numConfigs);
	if (numConfigs == 0)
	{
		Sys_Error("No config found! error: %d", eglGetError());
		goto _fail1;
	}


	// Create an EGL window surface
	s_surface = eglCreateWindowSurface(s_display, config, input_win, NULL);
	
	if (!s_surface)
	{
		Sys_Error("Surface creation failed! error: %d", eglGetError());
		goto _fail1;
	}

	static const EGLint ctxAttributeList[] = 
	{
		EGL_CONTEXT_OPENGL_PROFILE_MASK, EGL_CONTEXT_OPENGL_COMPATIBILITY_PROFILE_BIT,
		EGL_NONE
	};


	// Create an EGL rendering context
	s_context = eglCreateContext(s_display, config, EGL_NO_CONTEXT, ctxAttributeList);
	if (!s_context)
	{
		Sys_Error("Context creation failed! error: %d", eglGetError());
		goto _fail2;
	}


	// Connect the context to the surface
	eglMakeCurrent(s_display, s_surface, s_surface, s_context);


	return true;

_fail2:
	eglDestroySurface(s_display, s_surface);
	s_surface = NULL;
_fail1:
	eglTerminate(s_display);
	s_display = NULL;
_fail0:
	return false;
}

static void DeinitEGL (void)
{
	if (s_display)
	{
		eglMakeCurrent(s_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
		if (s_context)
		{
			eglDestroyContext(s_display, s_context);
			s_context = NULL;
		}
		if (s_surface)
		{
			eglDestroySurface(s_display, s_surface);
			s_surface = NULL;
		}
		eglTerminate(s_display);
		s_display = NULL;
	}
}

static void CreateUselessSDLWindow (void)
{
	int flags = SDL_WINDOW_SHOWN | SDL_WINDOW_FULLSCREEN;
	draw_context = SDL_CreateWindow("", 0, 0, 1280, 720, flags);
	if (!draw_context) printf("draw_context == NULL!\n%s\n", SDL_GetError());
	draw_renderer = SDL_CreateRenderer(draw_context, -1, 0);
	if (!draw_renderer) printf("draw_renderer == NULL!\n%s\n", SDL_GetError());
}

/*
================
VID_Gamma_SetGamma -- apply gamma correction
================
*/
static void VID_Gamma_SetGamma (void)
{
	if (gl_glsl_gamma_able)
		return;
	/*
	if (draw_context && gammaworks)
	{
		float	value = 0;

		if (vid_gamma.value > (1.0f / GAMMA_MAX))
			value = 1.0f / vid_gamma.value;
		else
			value = GAMMA_MAX;
	}
	*/
}

/*
================
VID_Gamma_Restore -- restore system gamma
================
*/
static void VID_Gamma_Restore (void)
{
	if (gl_glsl_gamma_able)
		return;

	if (draw_context && gammaworks)
	{
	}
}

/*
================
VID_Gamma_Shutdown -- called on exit
================
*/
static void VID_Gamma_Shutdown (void)
{
	VID_Gamma_Restore ();
}

/*
================
VID_Gamma_f -- callback when the cvar changes
================
*/
static void VID_Gamma_f (cvar_t *var)
{
	if (gl_glsl_gamma_able)
		return;

#if USE_GAMMA_RAMPS
	int i;

	for (i = 0; i < 256; i++)
	{
		vid_gamma_red[i] =
			CLAMP(0, (int) ((255 * pow((i + 0.5)/255.5, vid_gamma.value) + 0.5) * vid_contrast.value), 255) << 8;
		vid_gamma_green[i] = vid_gamma_red[i];
		vid_gamma_blue[i] = vid_gamma_red[i];
	}
#endif
	VID_Gamma_SetGamma ();
}

/*
================
VID_Gamma_Init -- call on init
================
*/
static void VID_Gamma_Init (void)
{
	Cvar_RegisterVariable (&vid_gamma);
	Cvar_RegisterVariable (&vid_contrast);
	Cvar_SetCallback (&vid_gamma, VID_Gamma_f);
	Cvar_SetCallback (&vid_contrast, VID_Gamma_f);

	if (gl_glsl_gamma_able)
		return;
}

/*
======================
VID_GetCurrentWidth
======================
*/
static int VID_GetCurrentWidth (void)
{
	return fb_big ? 1920 : 1280;
}

/*
=======================
VID_GetCurrentHeight
=======================
*/
static int VID_GetCurrentHeight (void)
{
	return fb_big ? 1080 : 720;
}

/*
====================
VID_GetCurrentRefreshRate
====================
*/
static int VID_GetCurrentRefreshRate (void)
{
	return DEFAULT_REFRESHRATE;
}


/*
====================
VID_GetCurrentBPP
====================
*/
static int VID_GetCurrentBPP (void)
{
	return 32;
}

/*
====================
VID_GetFullscreen
 
returns true if we are in regular fullscreen or "desktop fullscren"
====================
*/
static qboolean VID_GetFullscreen (void)
{
	return true;
}

/*
====================
VID_GetDesktopFullscreen
 
returns true if we are specifically in "desktop fullscreen" mode
====================
*/
static qboolean VID_GetDesktopFullscreen (void)
{
	return false;
}

/*
====================
VID_GetVSync
====================
*/
static qboolean VID_GetVSync (void)
{
	return true;
}

/*
====================
VID_GetWindow

used by pl_win.c
====================
*/
void *VID_GetWindow (void)
{
	return NULL;
}

/*
====================
VID_HasMouseOrInputFocus
====================
*/
qboolean VID_HasMouseOrInputFocus (void)
{
	return true;
}

/*
====================
VID_IsMinimized
====================
*/
qboolean VID_IsMinimized (void)
{
	return false;
}

#if defined(USE_SDL2)
/*
================
VID_SDL2_GetDisplayMode

Returns a pointer to a statically allocated SDL_DisplayMode structure
if there is one with the requested params on the default display.
Otherwise returns NULL.

This is passed to SDL_SetWindowDisplayMode to specify a pixel format
with the requested bpp. If we didn't care about bpp we could just pass NULL.
================
*/
static SDL_DisplayMode *VID_SDL2_GetDisplayMode(int width, int height, int refreshrate, int bpp)
{
	static SDL_DisplayMode mode;
	const int sdlmodes = SDL_GetNumDisplayModes(0);
	int i;

	for (i = 0; i < sdlmodes; i++)
	{
		if (SDL_GetDisplayMode(0, i, &mode) != 0)
			continue;
		
		if (mode.w == width && mode.h == height
			&& SDL_BITSPERPIXEL(mode.format) == bpp
			&& mode.refresh_rate == refreshrate)
		{
			return &mode;
		}
	}
	return NULL;
}
#endif /* USE_SDL2 */

/*
================
VID_ValidMode
================
*/
static qboolean VID_ValidMode (int width, int height, int refreshrate, int bpp, qboolean fullscreen)
{
// ignore width / height / bpp if vid_desktopfullscreen is enabled
	if (fullscreen && vid_desktopfullscreen.value)
		return true;

	if (width < 320)
		return false;

	if (height < 200)
		return false;

#if defined(USE_SDL2)
	if (fullscreen && VID_SDL2_GetDisplayMode(width, height, refreshrate, bpp) == NULL)
		bpp = 0;
#else
	{
		Uint32 flags = DEFAULT_SDL_FLAGS;
		if (fullscreen)
			flags |= SDL_FULLSCREEN;

		bpp = SDL_VideoModeOK(width, height, bpp, flags);
	}
#endif

	switch (bpp)
	{
	case 16:
	case 24:
	case 32:
		break;
	default:
		return false;
	}

	return true;
}

/*
================
VID_SetMode
================
*/
static qboolean VID_SetMode (int width, int height, int refreshrate, int bpp, qboolean fullscreen)
{
	int		temp;
	int		depthbits;
	int		fsaa_obtained;

	// so Con_Printfs don't mess us up by forcing vid and snd updates
	temp = scr_disabled_for_loading;
	scr_disabled_for_loading = true;

	CDAudio_Pause ();
	BGM_Pause ();

	gl_swap_control = true;
	vid.width = VID_GetCurrentWidth();
	vid.height = VID_GetCurrentHeight();
	vid.conwidth = vid.width & 0xFFFFFFF8;
	vid.conheight = vid.conwidth * vid.height / vid.width;
	vid.numpages = 2;

	depthbits = 24;
	fsaa_obtained = 0;
	gl_stencilbits = 0;

	modestate = VID_GetFullscreen() ? MS_FULLSCREEN : MS_WINDOWED;

	CDAudio_Resume ();
	BGM_Resume ();
	scr_disabled_for_loading = temp;

// fix the leftover Alt from any Alt-Tab or the like that switched us away
	ClearAllStates ();

	Con_SafePrintf ("Video mode %dx%dx%d %dHz (%d-bit z-buffer, %dx FSAA) initialized\n",
				VID_GetCurrentWidth(),
				VID_GetCurrentHeight(),
				VID_GetCurrentBPP(),
				VID_GetCurrentRefreshRate(),
				depthbits,
				fsaa_obtained);

	vid.recalc_refdef = 1;

// no pending changes
	vid_changed = false;

	return true;
}

/*
===================
VID_Changed_f -- kristian -- notify us that a value has changed that requires a vid_restart
===================
*/
static void VID_Changed_f (cvar_t *var)
{
	vid_changed = true;
}

/*
===================
VID_Restart -- johnfitz -- change video modes on the fly
===================
*/
static void VID_Restart (void)
{
	int width, height, refreshrate, bpp;
	qboolean fullscreen;

	if (vid_locked)
		return;

	// who cares
	Cvar_SetValueQuick (&vid_fullscreen, 1.f);
	Cvar_SetValueQuick (&vid_refreshrate, -1.f);
	Cvar_SetValueQuick (&vid_bpp, 32);

	if (!fb_big)
	{
		Cvar_SetValueQuick (&vid_width, 1920.f);
		Cvar_SetValueQuick (&vid_height, 1080.f);
		fb_big = true;
	}
	else
	{
		Cvar_SetValueQuick (&vid_width, 1280.f);
		Cvar_SetValueQuick (&vid_height, 720.f);
		fb_big = false;
	}

	width = (int)vid_width.value;
	height = (int)vid_height.value;
	refreshrate = (int)vid_refreshrate.value;
	bpp = (int)vid_bpp.value;
	fullscreen = vid_fullscreen.value ? true : false;

// ericw -- OS X, SDL1: textures, VBO's invalid after mode change
//          OS X, SDL2: still valid after mode change
// To handle both cases, delete all GL objects (textures, VBO, GLSL) now.
// We must not interleave deleting the old objects with creating new ones, because
// one of the new objects could be given the same ID as an invalid handle
// which is later deleted.

	TexMgr_DeleteTextureObjects ();
	GLSLGamma_DeleteTexture ();
	R_ScaleView_DeleteTexture ();
	R_DeleteShaders ();
	GL_DeleteBModelVertexBuffer ();
	GLMesh_DeleteVertexBuffers ();

//
// set new mode
//
	VID_SetMode (width, height, refreshrate, bpp, fullscreen);

	// gfxConfigureResolution (width, height); -- DONE 
	//NWindow* win = nwindowGetDefault();
	//framebufferCreate(&fb, win, width, height, PIXEL_FORMAT_RGBA_8888, 1);
	//framebufferMakeLinear(&fb);

	GL_Init ();
	TexMgr_ReloadImages ();
	GL_BuildBModelVertexBuffer ();
	GLMesh_LoadVertexBuffers ();
	GL_SetupState ();
	Fog_SetupState ();

	//warpimages needs to be recalculated
	TexMgr_RecalcWarpImageSize ();

	//conwidth and conheight need to be recalculated
	vid.conwidth = (scr_conwidth.value > 0) ? (int)scr_conwidth.value : (scr_conscale.value > 0) ? (int)(vid.width/scr_conscale.value) : vid.width;
	vid.conwidth = CLAMP (320, vid.conwidth, vid.width);
	vid.conwidth &= 0xFFFFFFF8;
	vid.conheight = vid.conwidth * vid.height / vid.width;
//
// keep cvars in line with actual mode
//
	VID_SyncCvars();
//
// update mouse grab
//
	if (key_dest == key_console || key_dest == key_menu)
	{
		if (modestate == MS_WINDOWED)
			IN_Deactivate(true);
		else if (modestate == MS_FULLSCREEN)
			IN_Activate();
	}
}

/*
================
VID_Test -- johnfitz -- like vid_restart, but asks for confirmation after switching modes
================
*/
static void VID_Test (void)
{
	int old_width, old_height, old_refreshrate, old_bpp, old_fullscreen;

	if (vid_locked || !vid_changed)
		return;
//
// now try the switch
//
	old_width = VID_GetCurrentWidth();
	old_height = VID_GetCurrentHeight();
	old_refreshrate = VID_GetCurrentRefreshRate();
	old_bpp = VID_GetCurrentBPP();
	old_fullscreen = VID_GetFullscreen() ? true : false;

	VID_Restart ();

	//pop up confirmation dialoge
	if (!SCR_ModalMessage("Would you like to keep this\nvideo mode? (y/n)\n", 5.0f))
	{
		//revert cvars and mode
		Cvar_SetValueQuick (&vid_width, old_width);
		Cvar_SetValueQuick (&vid_height, old_height);
		Cvar_SetValueQuick (&vid_refreshrate, old_refreshrate);
		Cvar_SetValueQuick (&vid_bpp, old_bpp);
		Cvar_SetQuick (&vid_fullscreen, old_fullscreen ? "1" : "0");
		VID_Restart ();
	}
}

/*
================
VID_Unlock -- johnfitz
================
*/
static void VID_Unlock (void)
{
	vid_locked = false;
	VID_SyncCvars();
}

/*
================
VID_Lock -- ericw

Subsequent changes to vid_* mode settings, and vid_restart commands, will
be ignored until the "vid_unlock" command is run.

Used when changing gamedirs so the current settings override what was saved
in the config.cfg.
================
*/
void VID_Lock (void)
{
	vid_locked = true;
}

//==============================================================================
//
//	OPENGL STUFF
//
//==============================================================================

/*
===============
GL_MakeNiceExtensionsList -- johnfitz
===============
*/
static char *GL_MakeNiceExtensionsList (const char *in)
{
	char *copy, *token, *out;
	int i, count;

	if (!in) return Z_Strdup("(none)");

	//each space will be replaced by 4 chars, so count the spaces before we malloc
	for (i = 0, count = 1; i < (int) strlen(in); i++)
	{
		if (in[i] == ' ')
			count++;
	}

	out = (char *) Z_Malloc (strlen(in) + count*3 + 1); //usually about 1-2k
	out[0] = 0;

	copy = (char *) Z_Strdup(in);
	for (token = strtok(copy, " "); token; token = strtok(NULL, " "))
	{
		strcat(out, "\n   ");
		strcat(out, token);
	}

	Z_Free (copy);
	return out;
}

/*
===============
GL_Info_f -- johnfitz
===============
*/
static void GL_Info_f (void)
{
	Con_SafePrintf ("GL_VENDOR: %s\n", gl_vendor);
	Con_SafePrintf ("GL_RENDERER: %s\n", gl_renderer);
	Con_SafePrintf ("GL_VERSION: %s\n", gl_version);
	Con_Printf ("GL_EXTENSIONS: %s\n", gl_extensions_nice);
}

/*
===============
GL_CheckExtensions
===============
*/
static qboolean GL_ParseExtensionList (const char *list, const char *name)
{
	const char	*start;
	const char	*where, *terminator;

	if (!list || !name || !*name)
		return false;
	if (strchr(name, ' ') != NULL)
		return false;	// extension names must not have spaces

	start = list;
	while (1) {
		where = strstr (start, name);
		if (!where)
			break;
		terminator = where + strlen (name);
		if (where == start || where[-1] == ' ')
			if (*terminator == ' ' || *terminator == '\0')
				return true;
		start = terminator;
	}
	return false;
}

static void GL_CheckExtensions (void)
{
	// ARB_vertex_buffer_object
	//
	if (COM_CheckParm("-novbo"))
		Con_Warning ("Vertex buffer objects disabled at command line\n");
	else if (gl_version_major < 1 || (gl_version_major == 1 && gl_version_minor < 5))
		Con_Warning ("OpenGL version < 1.5, skipping ARB_vertex_buffer_object check\n");
	else
	{
		GL_BindBufferFunc = (PFNGLBINDBUFFERARBPROC) eglGetProcAddress("glBindBuffer");
		GL_BufferDataFunc = (PFNGLBUFFERDATAARBPROC) eglGetProcAddress("glBufferData");
		GL_BufferSubDataFunc = (PFNGLBUFFERSUBDATAARBPROC) eglGetProcAddress("glBufferSubData");
		GL_DeleteBuffersFunc = (PFNGLDELETEBUFFERSARBPROC) eglGetProcAddress("glDeleteBuffers");
		GL_GenBuffersFunc = (PFNGLGENBUFFERSARBPROC) eglGetProcAddress("glGenBuffers");
		if (GL_BindBufferFunc && GL_BufferDataFunc && GL_BufferSubDataFunc && GL_DeleteBuffersFunc && GL_GenBuffersFunc)
		{
			Con_Printf("FOUND: ARB_vertex_buffer_object\n");
			gl_vbo_able = true;
		}
		else
		{
			Con_Warning ("ARB_vertex_buffer_object not available\n");
		}
	}

	// multitexture
	//
	if (COM_CheckParm("-nomtex"))
		Con_Warning ("Mutitexture disabled at command line\n");
	else
	{
		GL_MTexCoord2fFunc = (PFNGLMULTITEXCOORD2FARBPROC) eglGetProcAddress("glMultiTexCoord2f");
		GL_SelectTextureFunc = (PFNGLACTIVETEXTUREARBPROC) eglGetProcAddress("glActiveTexture");
		GL_ClientActiveTextureFunc = (PFNGLCLIENTACTIVETEXTUREARBPROC) eglGetProcAddress("glClientActiveTexture");
		if (GL_MTexCoord2fFunc && GL_SelectTextureFunc && GL_ClientActiveTextureFunc)
		{
			Con_Printf("FOUND: ARB_multitexture\n");
			gl_mtexable = true;
			
			glGetIntegerv(GL_MAX_TEXTURE_UNITS, &gl_max_texture_units);
			Con_Printf("GL_MAX_TEXTURE_UNITS: %d\n", (int)gl_max_texture_units);
		}
		else
		{
			Con_Warning ("Couldn't link to multitexture functions\n");
		}
	}

	// texture_env_combine
	//
	if (COM_CheckParm("-nocombine"))
		Con_Warning ("texture_env_combine disabled at command line\n");
	else if (GL_ParseExtensionList(gl_extensions, "GL_ARB_texture_env_combine"))
	{
		Con_Printf("FOUND: ARB_texture_env_combine\n");
		gl_texture_env_combine = true;
	}
	else if (GL_ParseExtensionList(gl_extensions, "GL_EXT_texture_env_combine"))
	{
		Con_Printf("FOUND: EXT_texture_env_combine\n");
		gl_texture_env_combine = true;
	}
	else
	{
		Con_Warning ("texture_env_combine not supported\n");
	}

	// texture_env_add
	//
	if (COM_CheckParm("-noadd"))
		Con_Warning ("texture_env_add disabled at command line\n");
	else if (GL_ParseExtensionList(gl_extensions, "GL_ARB_texture_env_add"))
	{
		Con_Printf("FOUND: ARB_texture_env_add\n");
		gl_texture_env_add = true;
	}
	else if (GL_ParseExtensionList(gl_extensions, "GL_EXT_texture_env_add"))
	{
		Con_Printf("FOUND: EXT_texture_env_add\n");
		gl_texture_env_add = true;
	}
	else
	{
		Con_Warning ("texture_env_add not supported\n");
	}

	// swap control
	//
	gl_swap_control = true;

	Con_Printf("FOUND: eglSetSwapInterval\n");

	// anisotropic filtering
	//
	if (GL_ParseExtensionList(gl_extensions, "GL_EXT_texture_filter_anisotropic"))
	{
		float test1,test2;
		GLuint tex;

		// test to make sure we really have control over it
		// 1.0 and 2.0 should always be legal values
		glGenTextures(1, &tex);
		glBindTexture (GL_TEXTURE_2D, tex);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 1.0f);
		glGetTexParameterfv (GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, &test1);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, 2.0f);
		glGetTexParameterfv (GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, &test2);
		glDeleteTextures(1, &tex);

		if (test1 == 1 && test2 == 2)
		{
			Con_Printf("FOUND: EXT_texture_filter_anisotropic\n");
			gl_anisotropy_able = true;
		}
		else
		{
			Con_Warning ("anisotropic filtering locked by driver. Current driver setting is %f\n", test1);
		}

		//get max value either way, so the menu and stuff know it
		glGetFloatv (GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &gl_max_anisotropy);
		if (gl_max_anisotropy < 2)
		{
			gl_anisotropy_able = false;
			gl_max_anisotropy = 1;
			Con_Warning ("anisotropic filtering broken: disabled\n");
		}
	}
	else
	{
		gl_max_anisotropy = 1;
		Con_Warning ("texture_filter_anisotropic not supported\n");
	}

	// texture_non_power_of_two
	//
	if (COM_CheckParm("-notexturenpot"))
		Con_Warning ("texture_non_power_of_two disabled at command line\n");
	else if (GL_ParseExtensionList(gl_extensions, "GL_ARB_texture_non_power_of_two"))
	{
		Con_Printf("FOUND: ARB_texture_non_power_of_two\n");
		gl_texture_NPOT = true;
	}
	else
	{
		Con_Warning ("texture_non_power_of_two not supported\n");
	}
	
	// GLSL
	//
	if (COM_CheckParm("-noglsl"))
		Con_Warning ("GLSL disabled at command line\n");
	else if (gl_version_major >= 2)
	{
		GL_CreateShaderFunc = (QS_PFNGLCREATESHADERPROC) eglGetProcAddress("glCreateShader");
		GL_DeleteShaderFunc = (QS_PFNGLDELETESHADERPROC) eglGetProcAddress("glDeleteShader");
		GL_DeleteProgramFunc = (QS_PFNGLDELETEPROGRAMPROC) eglGetProcAddress("glDeleteProgram");
		GL_ShaderSourceFunc = (QS_PFNGLSHADERSOURCEPROC) eglGetProcAddress("glShaderSource");
		GL_CompileShaderFunc = (QS_PFNGLCOMPILESHADERPROC) eglGetProcAddress("glCompileShader");
		GL_GetShaderivFunc = (QS_PFNGLGETSHADERIVPROC) eglGetProcAddress("glGetShaderiv");
		GL_GetShaderInfoLogFunc = (QS_PFNGLGETSHADERINFOLOGPROC) eglGetProcAddress("glGetShaderInfoLog");
		GL_GetProgramivFunc = (QS_PFNGLGETPROGRAMIVPROC) eglGetProcAddress("glGetProgramiv");
		GL_GetProgramInfoLogFunc = (QS_PFNGLGETPROGRAMINFOLOGPROC) eglGetProcAddress("glGetProgramInfoLog");
		GL_CreateProgramFunc = (QS_PFNGLCREATEPROGRAMPROC) eglGetProcAddress("glCreateProgram");
		GL_AttachShaderFunc = (QS_PFNGLATTACHSHADERPROC) eglGetProcAddress("glAttachShader");
		GL_LinkProgramFunc = (QS_PFNGLLINKPROGRAMPROC) eglGetProcAddress("glLinkProgram");
		GL_BindAttribLocationFunc = (QS_PFNGLBINDATTRIBLOCATIONFUNC) eglGetProcAddress("glBindAttribLocation");
		GL_UseProgramFunc = (QS_PFNGLUSEPROGRAMPROC) eglGetProcAddress("glUseProgram");
		GL_GetAttribLocationFunc = (QS_PFNGLGETATTRIBLOCATIONPROC) eglGetProcAddress("glGetAttribLocation");
		GL_VertexAttribPointerFunc = (QS_PFNGLVERTEXATTRIBPOINTERPROC) eglGetProcAddress("glVertexAttribPointer");
		GL_EnableVertexAttribArrayFunc = (QS_PFNGLENABLEVERTEXATTRIBARRAYPROC) eglGetProcAddress("glEnableVertexAttribArray");
		GL_DisableVertexAttribArrayFunc = (QS_PFNGLDISABLEVERTEXATTRIBARRAYPROC) eglGetProcAddress("glDisableVertexAttribArray");
		GL_GetUniformLocationFunc = (QS_PFNGLGETUNIFORMLOCATIONPROC) eglGetProcAddress("glGetUniformLocation");
		GL_Uniform1iFunc = (QS_PFNGLUNIFORM1IPROC) eglGetProcAddress("glUniform1i");
		GL_Uniform1fFunc = (QS_PFNGLUNIFORM1FPROC) eglGetProcAddress("glUniform1f");
		GL_Uniform3fFunc = (QS_PFNGLUNIFORM3FPROC) eglGetProcAddress("glUniform3f");
		GL_Uniform4fFunc = (QS_PFNGLUNIFORM4FPROC) eglGetProcAddress("glUniform4f");

		if (GL_CreateShaderFunc &&
			GL_DeleteShaderFunc &&
			GL_DeleteProgramFunc &&
			GL_ShaderSourceFunc &&
			GL_CompileShaderFunc &&
			GL_GetShaderivFunc &&
			GL_GetShaderInfoLogFunc &&
			GL_GetProgramivFunc &&
			GL_GetProgramInfoLogFunc &&
			GL_CreateProgramFunc &&
			GL_AttachShaderFunc &&
			GL_LinkProgramFunc &&
			GL_BindAttribLocationFunc &&
			GL_UseProgramFunc &&
			GL_GetAttribLocationFunc &&
			GL_VertexAttribPointerFunc &&
			GL_EnableVertexAttribArrayFunc &&
			GL_DisableVertexAttribArrayFunc &&
			GL_GetUniformLocationFunc &&
			GL_Uniform1iFunc &&
			GL_Uniform1fFunc &&
			GL_Uniform3fFunc &&
			GL_Uniform4fFunc)
		{
			Con_Printf("FOUND: GLSL\n");
			gl_glsl_able = true;
		}
		else
		{
			Con_Warning ("GLSL not available\n");
		}
	}
	else
	{
		Con_Warning ("OpenGL version < 2, GLSL not available\n");
	}
	
	// GLSL gamma
	//
	if (COM_CheckParm("-noglslgamma"))
		Con_Warning ("GLSL gamma disabled at command line\n");
	else if (gl_glsl_able)
	{
		gl_glsl_gamma_able = true;
	}
	else
	{
		Con_Warning ("GLSL gamma not available, using hardware gamma\n");
	}
    
    // GLSL alias model rendering
    //
	if (COM_CheckParm("-noglslalias"))
		Con_Warning ("GLSL alias model rendering disabled at command line\n");
	else if (gl_glsl_able && gl_vbo_able && gl_max_texture_units >= 3)
	{
		gl_glsl_alias_able = true;
	}
	else
	{
		Con_Warning ("GLSL alias model rendering not available, using Fitz renderer\n");
	}
}

/*
===============
GL_SetupState -- johnfitz

does all the stuff from GL_Init that needs to be done every time a new GL render context is created
===============
*/
static void GL_SetupState (void)
{
	glClearColor (0.15,0.15,0.15,0); //johnfitz -- originally 1,0,0,0
	glCullFace(GL_BACK); //johnfitz -- glquake used CCW with backwards culling -- let's do it right
	glFrontFace(GL_CW); //johnfitz -- glquake used CCW with backwards culling -- let's do it right
	glEnable(GL_TEXTURE_2D);
	glEnable(GL_ALPHA_TEST);
	glAlphaFunc(GL_GREATER, 0.666);
	glPolygonMode (GL_FRONT_AND_BACK, GL_FILL);
	glShadeModel (GL_FLAT);
	glHint (GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST); //johnfitz
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	glDepthRange (0, 1); //johnfitz -- moved here becuase gl_ztrick is gone.
	glDepthFunc (GL_LEQUAL); //johnfitz -- moved here becuase gl_ztrick is gone.
}

/*
===============
GL_Init
===============
*/
static void GL_Init (void)
{
	gl_vendor = (const char *) glGetString (GL_VENDOR);
	gl_renderer = (const char *) glGetString (GL_RENDERER);
	gl_version = (const char *) glGetString (GL_VERSION);
	gl_extensions = (const char *) glGetString (GL_EXTENSIONS);

	Con_SafePrintf ("GL_VENDOR: %s\n", gl_vendor);
	Con_SafePrintf ("GL_RENDERER: %s\n", gl_renderer);
	Con_SafePrintf ("GL_VERSION: %s\n", gl_version);
	
	if (gl_version == NULL || sscanf(gl_version, "%d.%d", &gl_version_major, &gl_version_minor) < 2)
	{
		gl_version_major = 0;
		gl_version_minor = 0;
	}

	if (gl_extensions_nice != NULL)
		Z_Free (gl_extensions_nice);
	gl_extensions_nice = GL_MakeNiceExtensionsList (gl_extensions);

	GL_CheckExtensions (); //johnfitz

#ifdef __APPLE__
	// ericw -- enable multi-threaded OpenGL, gives a decent FPS boost.
	// https://developer.apple.com/library/mac/technotes/tn2085/
	if (host_parms->numcpus > 1 &&
	    kCGLNoError != CGLEnable(CGLGetCurrentContext(), kCGLCEMPEngine))
	{
		Con_Warning ("Couldn't enable multi-threaded OpenGL");
	}
#endif

	//johnfitz -- intel video workarounds from Baker
	if (!strcmp(gl_vendor, "Intel"))
	{
		Con_Printf ("Intel Display Adapter detected, enabling gl_clear\n");
		Cbuf_AddText ("gl_clear 1");
	}
	//johnfitz

	GLAlias_CreateShaders ();
	GLWorld_CreateShaders ();
	GL_ClearBufferBindings ();	
}

/*
=================
GL_BeginRendering -- sets values of glx, gly, glwidth, glheight
=================
*/
void GL_BeginRendering (int *x, int *y, int *width, int *height)
{
	*x = 0;
	//*y = fb_big ? 0 : 720 / 2
	// Naievil -- fixed the width offest when using handheld mode, causing the screen to only show half
	*y = 0;
	*width = vid.width;
	*height = vid.height;
}

/*
=================
GL_EndRendering
=================
*/
void GL_EndRendering (void)
{
	if (!scr_skipupdate)
	{
		eglSwapBuffers(s_display, s_surface);
	}
}


void	VID_Shutdown (void)
{
	if (vid_initialized)
	{
		VID_Gamma_Shutdown (); //johnfitz

		SDL_QuitSubSystem(SDL_INIT_VIDEO);
		draw_context = NULL;
		draw_renderer = NULL;
		DeinitEGL();
		PL_VID_Shutdown();
	}
}

/*
===================================================================

MAIN WINDOW

===================================================================
*/

/*
================
ClearAllStates
================
*/
static void ClearAllStates (void)
{
	Key_ClearStates ();
	IN_ClearStates ();
}


//==========================================================================
//
//  COMMANDS
//
//==========================================================================

/*
=================
VID_DescribeCurrentMode_f
=================
*/
static void VID_DescribeCurrentMode_f (void)
{
	if (draw_context)
		Con_Printf("%dx%dx%d %dHz %s\n",
			VID_GetCurrentWidth(),
			VID_GetCurrentHeight(),
			VID_GetCurrentBPP(),
			VID_GetCurrentRefreshRate(),
			VID_GetFullscreen() ? "fullscreen" : "windowed");
}

/*
=================
VID_DescribeModes_f -- johnfitz -- changed formatting, and added refresh rates after each mode.
=================
*/
static void VID_DescribeModes_f (void)
{
	int	i;
	int	lastwidth, lastheight, lastbpp, count;

	lastwidth = lastheight = lastbpp = count = 0;

	for (i = 0; i < nummodes; i++)
	{
		if (lastwidth != modelist[i].width || lastheight != modelist[i].height || lastbpp != modelist[i].bpp)
		{
			if (count > 0)
				Con_SafePrintf ("\n");
			Con_SafePrintf ("   %4i x %4i x %i : %i", modelist[i].width, modelist[i].height, modelist[i].bpp, modelist[i].refreshrate);
			lastwidth = modelist[i].width;
			lastheight = modelist[i].height;
			lastbpp = modelist[i].bpp;
			count++;
		}
	}
	Con_Printf ("\n%i modes\n", count);
}

/*
===================
VID_FSAA_f -- ericw -- warn that vid_fsaa requires engine restart
===================
*/
static void VID_FSAA_f (cvar_t *var)
{
	// don't print the warning if vid_fsaa is set during startup
	if (vid_initialized)
		Con_Printf("%s %d requires engine restart to take effect\n", var->name, (int)var->value);
}

//==========================================================================
//
//  INIT
//
//==========================================================================

/*
=================
VID_InitModelist
=================
*/
static void VID_InitModelist (void)
{
#if defined(USE_SDL2)
	const int sdlmodes = SDL_GetNumDisplayModes(0);
	int i;

	nummodes = 0;
	for (i = 0; i < sdlmodes; i++)
	{
		SDL_DisplayMode mode;

		if (nummodes >= MAX_MODE_LIST)
			break;
		if (SDL_GetDisplayMode(0, i, &mode) == 0)
		{
			modelist[nummodes].width = mode.w;
			modelist[nummodes].height = mode.h;
			modelist[nummodes].bpp = SDL_BITSPERPIXEL(mode.format);
			modelist[nummodes].refreshrate = mode.refresh_rate;
			nummodes++;
		}
	}
#else /* !defined(USE_SDL2) */
	SDL_PixelFormat	format;
	SDL_Rect	**modes;
	Uint32		flags;
	int		i, j, k, originalnummodes, existingmode;
	int		bpps[] = {16, 24, 32}; // enumerate >8 bpp modes

	originalnummodes = nummodes = 0;
	format.palette = NULL;

	// enumerate fullscreen modes
	flags = DEFAULT_SDL_FLAGS | SDL_FULLSCREEN;
	for (i = 0; i < (int)(sizeof(bpps)/sizeof(bpps[0])); i++)
	{
		if (nummodes >= MAX_MODE_LIST)
			break;

		format.BitsPerPixel = bpps[i];
		modes = SDL_ListModes(&format, flags);

		if (modes == (SDL_Rect **)0 || modes == (SDL_Rect **)-1)
			continue;

		for (j = 0; modes[j]; j++)
		{
			if (modes[j]->w > MAXWIDTH || modes[j]->h > MAXHEIGHT || nummodes >= MAX_MODE_LIST)
				continue;

			modelist[nummodes].width = modes[j]->w;
			modelist[nummodes].height = modes[j]->h;
			modelist[nummodes].bpp = bpps[i];
			modelist[nummodes].refreshrate = DEFAULT_REFRESHRATE;

			for (k=originalnummodes, existingmode = 0 ; k < nummodes ; k++)
			{
				if ((modelist[nummodes].width == modelist[k].width)   &&
				    (modelist[nummodes].height == modelist[k].height) &&
				    (modelist[nummodes].bpp == modelist[k].bpp))
				{
					existingmode = 1;
					break;
				}
			}

			if (!existingmode)
			{
				nummodes++;
			}
		}
	}

	if (nummodes == originalnummodes)
		Con_SafePrintf ("No fullscreen DIB modes found\n");
#endif /* !defined(USE_SDL2) */
}

/*
===================
VID_Init
===================
*/
void	VID_Init (void)
{
	static char vid_center[] = "SDL_VIDEO_CENTERED=center";
	int		p, width, height, refreshrate, bpp;
	int		display_width, display_height, display_refreshrate, display_bpp;
	qboolean	fullscreen;
	const char	*read_vars[] = { "vid_fullscreen",
					 "vid_width",
					 "vid_height",
					 "vid_refreshrate",
					 "vid_bpp",
					 "vid_vsync",
					 "vid_fsaa",
					 "vid_desktopfullscreen",
					 "vid_borderless"};
#define num_readvars	( sizeof(read_vars)/sizeof(read_vars[0]) )

	Cvar_RegisterVariable (&vid_fullscreen); //johnfitz
	Cvar_RegisterVariable (&vid_width); //johnfitz
	Cvar_RegisterVariable (&vid_height); //johnfitz
	Cvar_RegisterVariable (&vid_refreshrate); //johnfitz
	Cvar_RegisterVariable (&vid_bpp); //johnfitz
	Cvar_RegisterVariable (&vid_vsync); //johnfitz
	Cvar_RegisterVariable (&vid_fsaa); //QuakeSpasm
	Cvar_RegisterVariable (&vid_desktopfullscreen); //QuakeSpasm
	Cvar_RegisterVariable (&vid_borderless); //QuakeSpasm
	Cvar_SetCallback (&vid_fullscreen, VID_Changed_f);
	Cvar_SetCallback (&vid_width, VID_Changed_f);
	Cvar_SetCallback (&vid_height, VID_Changed_f);
	Cvar_SetCallback (&vid_refreshrate, VID_Changed_f);
	Cvar_SetCallback (&vid_bpp, VID_Changed_f);
	Cvar_SetCallback (&vid_vsync, VID_Changed_f);
	Cvar_SetCallback (&vid_fsaa, VID_FSAA_f);
	Cvar_SetCallback (&vid_desktopfullscreen, VID_Changed_f);
	Cvar_SetCallback (&vid_borderless, VID_Changed_f);
	
	Cmd_AddCommand ("vid_unlock", VID_Unlock); //johnfitz
	Cmd_AddCommand ("vid_restart", VID_Restart); //johnfitz
	Cmd_AddCommand ("vid_test", VID_Test); //johnfitz
	Cmd_AddCommand ("vid_describecurrentmode", VID_DescribeCurrentMode_f);
	Cmd_AddCommand ("vid_describemodes", VID_DescribeModes_f);

	putenv (vid_center);	/* SDL_putenv is problematic in versions <= 1.2.9 */

    CreateUselessSDLWindow ();


	if (SDL_InitSubSystem(SDL_INIT_VIDEO) < 0)
		Sys_Error("Couldn't init SDL video: %s", SDL_GetError());

#if defined(USE_SDL2)
	{
		SDL_DisplayMode mode;
		if (SDL_GetDesktopDisplayMode(0, &mode) != 0)
			Sys_Error("Could not get desktop display mode");

		display_width = mode.w;
		display_height = mode.h;
		display_refreshrate = mode.refresh_rate;
		display_bpp = SDL_BITSPERPIXEL(mode.format);
	}
#else
	{
		const SDL_VideoInfo *info = SDL_GetVideoInfo();
		display_width = info->current_w;
		display_height = info->current_h;
		display_refreshrate = DEFAULT_REFRESHRATE;
		display_bpp = info->vfmt->BitsPerPixel;
	}
#endif

	Cvar_SetValueQuick (&vid_bpp, (float)display_bpp);

	if (CFG_OpenConfig("config.cfg") == 0)
	{
		CFG_ReadCvars(read_vars, num_readvars);
		CFG_CloseConfig();
	}
	CFG_ReadCvarOverrides(read_vars, num_readvars);

	VID_InitModelist();

	width = (int)vid_width.value;
	height = (int)vid_height.value;
	refreshrate = (int)vid_refreshrate.value;
	bpp = (int)vid_bpp.value;
	fullscreen = (int)vid_fullscreen.value;
	fsaa = (int)vid_fsaa.value;

	if (COM_CheckParm("-current"))
	{
		width = display_width;
		height = display_height;
		refreshrate = display_refreshrate;
		bpp = display_bpp;
		fullscreen = true;
	}
	else
	{
		p = COM_CheckParm("-width");
		if (p && p < com_argc-1)
		{
			width = Q_atoi(com_argv[p+1]);

			if(!COM_CheckParm("-height"))
				height = width * 3 / 4;
		}

		p = COM_CheckParm("-height");
		if (p && p < com_argc-1)
		{
			height = Q_atoi(com_argv[p+1]);

			if(!COM_CheckParm("-width"))
				width = height * 4 / 3;
		}

		p = COM_CheckParm("-refreshrate");
		if (p && p < com_argc-1)
			refreshrate = Q_atoi(com_argv[p+1]);
		
		p = COM_CheckParm("-bpp");
		if (p && p < com_argc-1)
			bpp = Q_atoi(com_argv[p+1]);

		if (COM_CheckParm("-window") || COM_CheckParm("-w"))
			fullscreen = false;
		else if (COM_CheckParm("-fullscreen") || COM_CheckParm("-f"))
			fullscreen = true;
	}

	p = COM_CheckParm ("-fsaa");
	if (p && p < com_argc-1)
		fsaa = atoi(com_argv[p+1]);

	if (!VID_ValidMode(width, height, refreshrate, bpp, fullscreen))
	{
		width = (int)vid_width.value;
		height = (int)vid_height.value;
		refreshrate = (int)vid_refreshrate.value;
		bpp = (int)vid_bpp.value;
		fullscreen = (int)vid_fullscreen.value;
	}

	if (!VID_ValidMode(width, height, refreshrate, bpp, fullscreen))
	{
		width = 640;
		height = 480;
		refreshrate = display_refreshrate;
		bpp = display_bpp;
		fullscreen = false;
	}

	vid_initialized = true;

	vid.maxwarpwidth = WARP_WIDTH;
	vid.maxwarpheight = WARP_HEIGHT;
	vid.colormap = host_colormap;
	vid.fullbright = 256 - LittleLong (*((int *)vid.colormap + 2048));

	// set window icon
	PL_SetWindowIcon();

	// naievil -- adding new framebuffer code instead of using gfx
	NWindow *win = nwindowGetDefault();

	// naievil -- create temporary frame buffer that is only 720p
	framebufferCreate(&fb, win, 1280, 720, PIXEL_FORMAT_RGBA_8888, 1);
	framebufferMakeLinear(&fb);

	// init 1920x1080 framebuffer to allow 1080p graphics when docked
	if (appletGetOperationMode() == AppletOperationMode_Docked)
	{
		// naievil -- close old frame buffer and start new one 
		framebufferClose(&fb);
		framebufferCreate(&fb, win, 1920, 1080, PIXEL_FORMAT_RGBA_8888, 1);
		framebufferMakeLinear(&fb);

		width = 1920;
		height = 1080;
		fullscreen = true;
		fb_big = true;
	}
	else
	{
		// undocked start, crop to 1280x720
		// naievil -- revert to original video size
		framebufferClose(&fb);
		framebufferCreate(&fb, win, 1280, 720, PIXEL_FORMAT_RGBA_8888, 1);
		framebufferMakeLinear(&fb);
		width = 1280;
		height = 720;
		fullscreen = true;
		fb_big = false;
	}

	// create the SDL stuff right fucking here
	CreateUselessSDLWindow ();

	VID_SetMode (width, height, refreshrate, bpp, fullscreen);

	SetMesaConfig ();
	InitEGL (win);
	gladLoadGL ();
	GL_Init ();
	GL_SetupState ();
	Cmd_AddCommand ("gl_info", GL_Info_f); //johnfitz

	//johnfitz -- removed code creating "glquake" subdirectory

	vid_menucmdfn = VID_Menu_f; //johnfitz
	vid_menudrawfn = VID_MenuDraw;
	vid_menukeyfn = VID_MenuKey;

	VID_Gamma_Init(); //johnfitz
	VID_Menu_Init(); //johnfitz

	//QuakeSpasm: current vid settings should override config file settings.
	//so we have to lock the vid mode from now until after all config files are read.
	vid_locked = true;
}

// new proc by S.A., called by alt-return key binding.
void	VID_Toggle (void)
{
	// disabling the fast path completely because SDL_SetWindowFullscreen was changing
	// the window size on SDL2/WinXP and we weren't set up to handle it. --ericw
	//
	// TODO: Clear out the dead code, reinstate the fast path using SDL_SetWindowFullscreen
	// inside VID_SetMode, check window size to fix WinXP issue. This will
	// keep all the mode changing code in one place.
	static qboolean vid_toggle_works = false;
	qboolean toggleWorked;
#if defined(USE_SDL2)
	Uint32 flags = 0;
#endif

	S_ClearBuffer ();

	if (!vid_toggle_works)
		goto vrestart;
	else if (gl_vbo_able)
	{
		// disabling the fast path because with SDL 1.2 it invalidates VBOs (using them
		// causes a crash, sugesting that the fullscreen toggle created a new GL context,
		// although texture objects remain valid for some reason).
		//
		// SDL2 does promise window resizes / fullscreen changes preserve the GL context,
		// so we could use the fast path with SDL2. --ericw
		vid_toggle_works = false;
		goto vrestart;
	}

#if defined(USE_SDL2)
	if (!VID_GetFullscreen()) {
		flags = vid_desktopfullscreen.value ? SDL_WINDOW_FULLSCREEN_DESKTOP : SDL_WINDOW_FULLSCREEN;
	}

	toggleWorked = SDL_SetWindowFullscreen(draw_context, flags) == 0;
#else
	toggleWorked = SDL_WM_ToggleFullScreen(draw_context) == 1;
#endif

	if (toggleWorked)
	{
		Sbar_Changed ();	// Sbar seems to need refreshing

		modestate = VID_GetFullscreen() ? MS_FULLSCREEN : MS_WINDOWED;

		VID_SyncCvars();

		// update mouse grab
		if (key_dest == key_console || key_dest == key_menu)
		{
			if (modestate == MS_WINDOWED)
				IN_Deactivate(true);
			else if (modestate == MS_FULLSCREEN)
				IN_Activate();
		}
	}
	else
	{
		vid_toggle_works = false;
		Con_DPrintf ("SDL_WM_ToggleFullScreen failed, attempting VID_Restart\n");
	vrestart:
		Cvar_SetQuick (&vid_fullscreen, VID_GetFullscreen() ? "0" : "1");
		Cbuf_AddText ("vid_restart\n");
	}
}

/*
================
VID_SyncCvars -- johnfitz -- set vid cvars to match current video mode
================
*/
void VID_SyncCvars (void)
{
	if (draw_context)
	{
		if (!VID_GetDesktopFullscreen())
		{
			Cvar_SetValueQuick (&vid_width, VID_GetCurrentWidth());
			Cvar_SetValueQuick (&vid_height, VID_GetCurrentHeight());
		}
		Cvar_SetValueQuick (&vid_refreshrate, VID_GetCurrentRefreshRate());
		Cvar_SetValueQuick (&vid_bpp, VID_GetCurrentBPP());
		Cvar_SetQuick (&vid_fullscreen, VID_GetFullscreen() ? "1" : "0");
		// don't sync vid_desktopfullscreen, it's a user preference that
		// should persist even if we are in windowed mode.
		Cvar_SetQuick (&vid_vsync, VID_GetVSync() ? "1" : "0");
	}

	vid_changed = false;
}

//==========================================================================
//
//  NEW VIDEO MENU -- johnfitz
//
//==========================================================================

enum {
	VID_OPT_MODE,
	VID_OPT_BPP,
	VID_OPT_REFRESHRATE,
	VID_OPT_FULLSCREEN,
	VID_OPT_VSYNC,
	VID_OPT_TEST,
	VID_OPT_APPLY,
	VIDEO_OPTIONS_ITEMS
};

static int	video_options_cursor = 0;

typedef struct {
	int width,height;
} vid_menu_mode;

//TODO: replace these fixed-length arrays with hunk_allocated buffers
static vid_menu_mode vid_menu_modes[MAX_MODE_LIST];
static int vid_menu_nummodes = 0;

static int vid_menu_bpps[MAX_BPPS_LIST];
static int vid_menu_numbpps = 0;

static int vid_menu_rates[MAX_RATES_LIST];
static int vid_menu_numrates=0;

/*
================
VID_Menu_Init
================
*/
static void VID_Menu_Init (void)
{
	int i, j, h, w;

	for (i = 0; i < nummodes; i++)
	{
		w = modelist[i].width;
		h = modelist[i].height;

		for (j = 0; j < vid_menu_nummodes; j++)
		{
			if (vid_menu_modes[j].width == w &&
				vid_menu_modes[j].height == h)
				break;
		}

		if (j == vid_menu_nummodes)
		{
			vid_menu_modes[j].width = w;
			vid_menu_modes[j].height = h;
			vid_menu_nummodes++;
		}
	}
}

/*
================
VID_Menu_RebuildBppList

regenerates bpp list based on current vid_width and vid_height
================
*/
static void VID_Menu_RebuildBppList (void)
{
	int i, j, b;

	vid_menu_numbpps = 0;

	for (i = 0; i < nummodes; i++)
	{
		if (vid_menu_numbpps >= MAX_BPPS_LIST)
			break;

		//bpp list is limited to bpps available with current width/height
		if (modelist[i].width != vid_width.value ||
			modelist[i].height != vid_height.value)
			continue;

		b = modelist[i].bpp;

		for (j = 0; j < vid_menu_numbpps; j++)
		{
			if (vid_menu_bpps[j] == b)
				break;
		}

		if (j == vid_menu_numbpps)
		{
			vid_menu_bpps[j] = b;
			vid_menu_numbpps++;
		}
	}

	//if there are no valid fullscreen bpps for this width/height, just pick one
	if (vid_menu_numbpps == 0)
	{
		Cvar_SetValueQuick (&vid_bpp, (float)modelist[0].bpp);
		return;
	}

	//if vid_bpp is not in the new list, change vid_bpp
	for (i = 0; i < vid_menu_numbpps; i++)
		if (vid_menu_bpps[i] == (int)(vid_bpp.value))
			break;

	if (i == vid_menu_numbpps)
		Cvar_SetValueQuick (&vid_bpp, (float)vid_menu_bpps[0]);
}

/*
================
VID_Menu_RebuildRateList

regenerates rate list based on current vid_width, vid_height and vid_bpp
================
*/
static void VID_Menu_RebuildRateList (void)
{
	int i,j,r;
	
	vid_menu_numrates=0;
	
	for (i=0;i<nummodes;i++)
	{
		//rate list is limited to rates available with current width/height/bpp
		if (modelist[i].width != vid_width.value ||
		    modelist[i].height != vid_height.value ||
		    modelist[i].bpp != vid_bpp.value)
			continue;
		
		r = modelist[i].refreshrate;
		
		for (j=0;j<vid_menu_numrates;j++)
		{
			if (vid_menu_rates[j] == r)
				break;
		}
		
		if (j==vid_menu_numrates)
		{
			vid_menu_rates[j] = r;
			vid_menu_numrates++;
		}
	}
	
	//if there are no valid fullscreen refreshrates for this width/height, just pick one
	if (vid_menu_numrates == 0)
	{
		Cvar_SetValue ("vid_refreshrate",(float)modelist[0].refreshrate);
		return;
	}
	
	//if vid_refreshrate is not in the new list, change vid_refreshrate
	for (i=0;i<vid_menu_numrates;i++)
		if (vid_menu_rates[i] == (int)(vid_refreshrate.value))
			break;
	
	if (i==vid_menu_numrates)
		Cvar_SetValue ("vid_refreshrate",(float)vid_menu_rates[0]);
}

/*
================
VID_Menu_ChooseNextMode

chooses next resolution in order, then updates vid_width and
vid_height cvars, then updates bpp and refreshrate lists
================
*/
static void VID_Menu_ChooseNextMode (int dir)
{
	int i;

	if (vid_menu_nummodes)
	{
		for (i = 0; i < vid_menu_nummodes; i++)
		{
			if (vid_menu_modes[i].width == vid_width.value &&
				vid_menu_modes[i].height == vid_height.value)
				break;
		}

		if (i == vid_menu_nummodes) //can't find it in list, so it must be a custom windowed res
		{
			i = 0;
		}
		else
		{
			i += dir;
			if (i >= vid_menu_nummodes)
				i = 0;
			else if (i < 0)
				i = vid_menu_nummodes-1;
		}

		Cvar_SetValueQuick (&vid_width, (float)vid_menu_modes[i].width);
		Cvar_SetValueQuick (&vid_height, (float)vid_menu_modes[i].height);
		VID_Menu_RebuildBppList ();
		VID_Menu_RebuildRateList ();
	}
}

/*
================
VID_Menu_ChooseNextBpp

chooses next bpp in order, then updates vid_bpp cvar
================
*/
static void VID_Menu_ChooseNextBpp (int dir)
{
	int i;

	if (vid_menu_numbpps)
	{
		for (i = 0; i < vid_menu_numbpps; i++)
		{
			if (vid_menu_bpps[i] == vid_bpp.value)
				break;
		}

		if (i == vid_menu_numbpps) //can't find it in list
		{
			i = 0;
		}
		else
		{
			i += dir;
			if (i >= vid_menu_numbpps)
				i = 0;
			else if (i < 0)
				i = vid_menu_numbpps-1;
		}

		Cvar_SetValueQuick (&vid_bpp, (float)vid_menu_bpps[i]);
	}
}

/*
================
VID_Menu_ChooseNextRate

chooses next refresh rate in order, then updates vid_refreshrate cvar
================
*/
static void VID_Menu_ChooseNextRate (int dir)
{
	int i;
	
	for (i=0;i<vid_menu_numrates;i++)
	{
		if (vid_menu_rates[i] == vid_refreshrate.value)
			break;
	}
	
	if (i==vid_menu_numrates) //can't find it in list
	{
		i = 0;
	}
	else
	{
		i+=dir;
		if (i>=vid_menu_numrates)
			i = 0;
		else if (i<0)
			i = vid_menu_numrates-1;
	}
	
	Cvar_SetValue ("vid_refreshrate",(float)vid_menu_rates[i]);
}

/*
================
VID_MenuKey
================
*/
static void VID_MenuKey (int key)
{
	switch (key)
	{
	case K_ESCAPE:
	case K_BBUTTON:
		VID_SyncCvars (); //sync cvars before leaving menu. FIXME: there are other ways to leave menu
		S_LocalSound ("misc/menu1.wav");
		M_Menu_Options_f ();
		break;

	case K_UPARROW:
		S_LocalSound ("misc/menu1.wav");
		video_options_cursor--;
		if (video_options_cursor < 0)
			video_options_cursor = VIDEO_OPTIONS_ITEMS-1;
		break;

	case K_DOWNARROW:
		S_LocalSound ("misc/menu1.wav");
		video_options_cursor++;
		if (video_options_cursor >= VIDEO_OPTIONS_ITEMS)
			video_options_cursor = 0;
		break;

	case K_LEFTARROW:
		S_LocalSound ("misc/menu3.wav");
		switch (video_options_cursor)
		{
		case VID_OPT_MODE:
			VID_Menu_ChooseNextMode (1);
			break;
		case VID_OPT_BPP:
			VID_Menu_ChooseNextBpp (1);
			break;
		case VID_OPT_REFRESHRATE:
			VID_Menu_ChooseNextRate (1);
			break;
		case VID_OPT_FULLSCREEN:
			Cbuf_AddText ("toggle vid_fullscreen\n");
			break;
		case VID_OPT_VSYNC:
			Cbuf_AddText ("toggle vid_vsync\n"); // kristian
			break;
		default:
			break;
		}
		break;

	case K_RIGHTARROW:
		S_LocalSound ("misc/menu3.wav");
		switch (video_options_cursor)
		{
		case VID_OPT_MODE:
			VID_Menu_ChooseNextMode (-1);
			break;
		case VID_OPT_BPP:
			VID_Menu_ChooseNextBpp (-1);
			break;
		case VID_OPT_REFRESHRATE:
			VID_Menu_ChooseNextRate (-1);
			break;
		case VID_OPT_FULLSCREEN:
			Cbuf_AddText ("toggle vid_fullscreen\n");
			break;
		case VID_OPT_VSYNC:
			Cbuf_AddText ("toggle vid_vsync\n");
			break;
		default:
			break;
		}
		break;

	case K_ENTER:
	case K_KP_ENTER:
	case K_ABUTTON:
		m_entersound = true;
		switch (video_options_cursor)
		{
		case VID_OPT_MODE:
			VID_Menu_ChooseNextMode (1);
			break;
		case VID_OPT_BPP:
			VID_Menu_ChooseNextBpp (1);
			break;
		case VID_OPT_REFRESHRATE:
			VID_Menu_ChooseNextRate (1);
			break;
		case VID_OPT_FULLSCREEN:
			Cbuf_AddText ("toggle vid_fullscreen\n");
			break;
		case VID_OPT_VSYNC:
			Cbuf_AddText ("toggle vid_vsync\n");
			break;
		case VID_OPT_TEST:
			Cbuf_AddText ("vid_test\n");
			break;
		case VID_OPT_APPLY:
			Cbuf_AddText ("vid_restart\n");
			key_dest = key_game;
			m_state = m_none;
			IN_Activate();
			break;
		default:
			break;
		}
		break;

	default:
		break;
	}
}

/*
================
VID_MenuDraw
================
*/
static void VID_MenuDraw (void)
{
	int i, y;
	qpic_t *p;
	const char *title;

	y = 4;

	// plaque
	// p = Draw_CachePic ("gfx/qplaque.lmp");
	// M_DrawTransPic (16, y, p);

	// //p = Draw_CachePic ("gfx/vidmodes.lmp");
	// p = Draw_CachePic ("gfx/p_option.lmp");
	// M_DrawPic ( (320-p->width)/2, y, p);

	y += 28;

	// title
	title = "Video Options";
	M_PrintWhite ((320-8*strlen(title))/2, y, title);

	y += 16;

	// options
	for (i = 0; i < VIDEO_OPTIONS_ITEMS; i++)
	{
		switch (i)
		{
		case VID_OPT_MODE:
			M_Print (16, y, "        Video mode");
			M_Print (184, y, va("%ix%i", (int)vid_width.value, (int)vid_height.value));
			break;
		case VID_OPT_BPP:
			M_Print (16, y, "       Color depth");
			M_Print (184, y, va("%i", (int)vid_bpp.value));
			break;
		case VID_OPT_REFRESHRATE:
			M_Print (16, y, "      Refresh rate");
			M_Print (184, y, va("%i", (int)vid_refreshrate.value));
			break;
		case VID_OPT_FULLSCREEN:
			M_Print (16, y, "        Fullscreen");
			M_DrawCheckbox (184, y, (int)vid_fullscreen.value);
			break;
		case VID_OPT_VSYNC:
			M_Print (16, y, "     Vertical sync");
			if (gl_swap_control)
				M_DrawCheckbox (184, y, (int)vid_vsync.value);
			else
				M_Print (184, y, "N/A");
			break;
		case VID_OPT_TEST:
			y += 8; //separate the test and apply items
			M_Print (16, y, "      Test changes");
			break;
		case VID_OPT_APPLY:
			M_Print (16, y, "     Apply changes");
			break;
		}

		if (video_options_cursor == i)
			M_DrawCharacter (168, y, 12+((int)(realtime*4)&1));

		y += 8;
	}
}

/*
================
VID_Menu_f
================
*/
static void VID_Menu_f (void)
{
	IN_Deactivate(modestate == MS_WINDOWED);
	key_dest = key_menu;
	m_state = m_video;
	m_entersound = true;

	//set all the cvars to match the current mode when entering the menu
	VID_SyncCvars ();

	//set up bpp and rate lists based on current cvars
	VID_Menu_RebuildBppList ();
	VID_Menu_RebuildRateList ();
}

