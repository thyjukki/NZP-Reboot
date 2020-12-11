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

#define ENABLE_PRINTF 0

#include "system.hpp"

#include <cstddef>
#include <stdexcept>

#include <stdarg.h>
#include <string.h>
#include <stdio.h>
#include <sys/stat.h>
#include <dirent.h>

#include <pspctrl.h>
#include <pspdebug.h>
#include <pspkernel.h>
#include <psppower.h>
#include <psprtc.h>
#include <psputility.h>
#include <pspdisplay.h>
#include <pspgu.h>
#include <pspgum.h>

extern "C"
{
#include "../sys.h"
#include "../quakedef.h"
void Host_WriteConfiguration (void);
}
#include "fnmatch.h"

void CDAudio_Stop(void);

namespace quake
{
	namespace main
	{
		extern const int	cpuClockSpeed;
		extern const int	ramClockSpeed;
		extern const int	busClockSpeed;
	}

	namespace system
	{
		struct file
		{
			// Set on open.
			char	name[MAX_OSPATH + 1];
			bool	write;

			// Set on open, suspend, restore.
			FILE*	handle;

			// Set on suspend.
			long	offset;
		};

		static bool					debugScreenInitialized	= false;
		static const std::size_t	file_count	= 64;
		static file					files[file_count];

		void suspend()
		{
			Con_Printf("Suspend requested \n");
			CDAudio_Pause();
			// Close each file.
			for (std::size_t file_index = 0; file_index < file_count; ++file_index)
			{
				// Is the file in use?
				file& file = files[file_index];
				if (file.name[0])
				{
					// Save the offset;
					file.offset = ftell(file.handle);

					// Close the file.
					fclose(file.handle);
					file.handle = 0;
				}
			}
			
			Con_Printf("Filesystem sunspended\n");
		}

		void resume()
		{
			Con_Printf("Resume requested\n");
			// Check each file.
			for (std::size_t file_index = 0; file_index < file_count; ++file_index)
			{
				// Is the file in use?
				file& file = files[file_index];
				if (file.name[0])
				{
					// Reopen the file. This can repeatedly fail, so we keep trying.
					const char* mode = file.write ? "ab" : "rb";
					do
					{
						file.handle = fopen(file.name, mode);
					}
					while (!file.handle);

					// Restore the offset;
					if (fseek(file.handle, file.offset, SEEK_SET) != 0)
					{
						throw std::runtime_error("Couldn't seek in file");
					}
				}
			}
			
			CDAudio_Resume();
			Con_Printf("Filesystem resumed\n");
			
		}
	}
}

using namespace quake;
using namespace quake::system;


int Sys_FileOpenRead (char *path, int *hndl)
{
	// Find an unused file.
	for (std::size_t file_index = 1; file_index < file_count; ++file_index)
	{
		// Is the file in use?
		file& file = files[file_index];
		if (file.name[0])
		{
			continue;
		}

		// Open the file.
		file.handle = fopen(path, "rb");
		if (!file.handle)
		{
			*hndl = -1;
			return -1;
		}

		// Get the length.
		if (fseek(file.handle, 0, SEEK_END) != 0)
		{
			Sys_Error("fseek failed");
		}
		const long length = ftell(file.handle);
		if (fseek(file.handle, 0, SEEK_SET) != 0)
		{
			Sys_Error("fseek failed");
		}

		// The file is now in use!
		Q_strncpy(file.name, path, MAX_OSPATH);
		file.write = false;

		// Done.
		*hndl = file_index;
		return length;
	}

	Sys_Error("Out of file slots");
	return -1;
}

int Sys_FileOpenWrite (char *path)
{
	// Find an unused file.
	for (std::size_t file_index = 1; file_index < file_count; ++file_index)
	{
		// Is the file in use?
		file& file = files[file_index];
		if (file.name[0])
		{
			continue;
		}

		// Open the file.
		file.handle = fopen(path, "wb");
		if (!file.handle)
		{
			return -1;
		}

		// The file is now in use!
		Q_strncpy(file.name, path, MAX_OSPATH);
		file.write = true;

		// Done.
		return file_index;
	}

	Sys_Error("Out of file slots");
	return -1;
}

void Sys_FileClose (int handle)
{
	// Close the file.
	file& file = files[handle];
	fclose(file.handle);
	file.handle = 0;
	file.name[0] = 0;
}

void Sys_FileSeek (int handle, int position)
{
	file& file = files[handle];
	if (fseek(file.handle, position, SEEK_SET) != 0)
	{
		Sys_Error("fseek failed");
	}
}

int Sys_FileRead (int handle, void *dest, int count)
{
	file& file = files[handle];
	return fread(dest, 1, count, file.handle);
}

int Sys_FileWrite (int handle, void *data, int count)
{
	file& file = files[handle];
	return fwrite(data, 1, count, file.handle);
}

int	Sys_FileTime (char *path)
{
	/*
#ifdef _WIN32
	return -1;
#else
	*/
	struct stat s;
	memset(&s, 0, sizeof(s));

	if (stat(path, &s) < 0)
	{
		return -1;
	}

	return s.st_ctime;
	/*
#endif
	*/
}


void Sys_mkdir (char *path)
{
	Sys_Printf("Mkdir: %s\n", path);
	sceIoMkdir(path, 0x777);
}
#if 0 //bad
//Crow_bar.
void Sys_Error (char *error, ...)
{
	char msg[MAX_OSPATH];
	// Clear the sound buffer.
	S_ClearBuffer();

	// Put the error message in a buffer.
	va_list args;
	va_start(args, error);
	char buffer[1024];
	memset(buffer, 0, sizeof(buffer));
	vsnprintf(buffer, sizeof(buffer) - 1, error, args);
	va_end(args);

	sprintf(msg,"        SYSTEM ERROR       \n\n%s ",buffer);

	ShowMessageDialog(msg, 0);

	Sys_Quit();
}
#endif

void Sys_Error (char *error, ...)
{
	// Clear the sound buffer.
	S_ClearBuffer();
	
	// Put the error message in a buffer.
	va_list args;
	va_start(args, error);
	char buffer[1024];
	memset(buffer, 0, sizeof(buffer));
	vsnprintf(buffer, sizeof(buffer) - 1, error, args);
	va_end(args);

	Con_Printf(buffer);
	// Print the error message to the debug screen.
	if (!debugScreenInitialized)
	{
		pspDebugScreenInit();
		debugScreenInitialized = true;
	}

	pspDebugScreenSetTextColor(0x0000af);
	pspDebugScreenPrintf("PSP NZP v:%4.2f \n",(float)VERSION);
	pspDebugScreenSetTextColor(0x10ffae);
	pspDebugScreenPrintf("The following error occurred:\n");
	pspDebugScreenSetTextColor(0x00ffff);
	pspDebugScreenPrintData(buffer, strlen(buffer));
	pspDebugScreenSetTextColor(0x40ff00);
	pspDebugScreenPrintf("\n\nPress CROSS to quit.\n");

	// Wait for a button press.
	sceCtrlSetSamplingCycle(0);
	sceCtrlSetSamplingMode(PSP_CTRL_MODE_ANALOG);
	SceCtrlData pad;
	do
	{
		sceCtrlReadBufferPositive(&pad, 1);
	} while (pad.Buttons & PSP_CTRL_CROSS);
	do
	{
		sceCtrlReadBufferPositive(&pad, 1);
	} while ((pad.Buttons & PSP_CTRL_CROSS) == 0);
	do
	{
		sceCtrlReadBufferPositive(&pad, 1);
	} while (pad.Buttons & PSP_CTRL_CROSS);

	// Quit.
	pspDebugScreenPrintf("Shutting down...\n");

	Sys_Quit();

}

void Sys_Printf (char *fmt, ...)
{
#if ENABLE_PRINTF
	char buffer[1024];

	va_list args;
	va_start(args, fmt);
	memset(buffer, 0, sizeof(buffer));
	vsnprintf(buffer, sizeof(buffer) - 1, fmt, args);
	va_end(args);

	if (!debugScreenInitialized)
	{
		pspDebugScreenInit();
		debugScreenInitialized = true;
	}
	pspDebugScreenPrintData(buffer, strlen(buffer));
#endif
}

void ShutdownExtModules (void);

void Sys_Quit (void)
{
	// Shut down the host system.
	if (host_initialized)
	{
		Host_Shutdown();
	}
#if 0
	// Remove modules from ram
    ShutdownExtModules ();
#endif
	// Restore the old clock frequency.
	scePowerSetClockFrequency(main::cpuClockSpeed, main::ramClockSpeed, main::busClockSpeed);

	// Insert a false delay so files and stuff can be saved before the kernel kills us.
	sceKernelDelayThread(50 * 1000);

	// Exit.
	sceKernelExitGame();
}

double Sys_FloatTime (void)
{
	u64 ticks;
	sceRtcGetCurrentTick(&ticks);
	return ticks * 0.000001;
}

char *Sys_ConsoleInput (void)
{
	return 0;
}

void Sys_SendKeyEvents (void)
{
}

void Sys_LowFPPrecision (void)
{
}

void Sys_HighFPPrecision (void)
{
}

/*
=================================================
simplified findfirst/findnext implementation:
Sys_FindFirstFile and Sys_FindNextFile return
filenames only, not a dirent struct. this is
what we presently need in this engine.
=================================================
*/

static DIR		*finddir;
static struct dirent	*finddata;
static char		*findpath, *findpattern;

char *Sys_FindFirstFile (char *path, char *pattern);
void Sys_FindClose (void);
char *Sys_FindNextFile (void);

char *Sys_FindFirstFile (char *path, char *pattern)
{
	size_t	tmp_len;

	if (finddir)
		Sys_Error ("Sys_FindFirst without FindClose");

	finddir = opendir (path);
	if (!finddir)
		return NULL;

	tmp_len = strlen (pattern);
	findpattern = (char*) malloc (tmp_len + 1);
	if (!findpattern)
		return NULL;
	strcpy (findpattern, pattern);
	findpattern[tmp_len] = '\0';
	tmp_len = strlen (path);
	findpath = (char*) malloc (tmp_len + 1);
	if (!findpath)
		return NULL;
	strcpy (findpath, path);
	findpath[tmp_len] = '\0';

	return Sys_FindNextFile();
}

char *Sys_FindNextFile (void)
{
	struct stat	test;

	if (!finddir)
		return NULL;

	do {
		finddata = readdir(finddir);
		if (finddata != NULL)
		{
			if (!fnmatch (findpattern, finddata->d_name, FNM_PATHNAME))
			{
				if ( (stat(va("%s/%s", findpath, finddata->d_name), &test) == 0) && S_ISREG(test.st_mode) )
					return finddata->d_name;
			}
		}
	} while (finddata != NULL);

	return NULL;
}

void Sys_FindClose (void)
{
	if (finddir != NULL)
		closedir(finddir);
	if (findpath != NULL)
		free (findpath);
	if (findpattern != NULL)
		free (findpattern);
	finddir = NULL;
	findpath = NULL;
	findpattern = NULL;
}

