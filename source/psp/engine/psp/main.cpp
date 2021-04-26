/*
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

#define CONSOLE_DEBUG 0

#include <stdexcept>
#include <vector>
#include <sys/unistd.h>

#include <pspdisplay.h>
#include <pspdebug.h>
#include <pspkernel.h>
#include <pspmoduleinfo.h>
#include <psppower.h>
#include <psprtc.h>
#include <pspctrl.h>
#include <psphprm.h>
#include <pspsdk.h>
#include <pspge.h>
#include <pspsysevent.h>

extern "C"
{
#include "../quakedef.h"
#include "../thread.h"
#include "m33libs/kubridge.h"
#include "iridlibs/perflib.h"
void VramSetSize(int kb);
}

#include "battery.hpp"
#include "system.hpp"
#include "module.h"

// Running a dedicated server?
qboolean isDedicated = qfalse;

qboolean depthfl = qfalse;

extern	int  com_argc;
extern	char **com_argv;

int 	sys_psp_model;

void Sys_ReadCommandLineFile (char* netpath);

/*
	MOTO - Can't go above heap of 10MB on PHAT models.. which is an issue, in theory 
	we should be able to cap at a heap size 14MB.. oh well.
*/

#define printf	pspDebugScreenPrintf
#define MIN_HEAP_MB	6
#define MAX_HEAP_MB (PSP_HEAP_SIZE_MB-1)

namespace quake
{
	namespace main
	{
	// Clock speeds.
		extern const int		cpuClockSpeed	= scePowerGetCpuClockFrequencyInt();
		extern const int		ramClockSpeed	= cpuClockSpeed;
		extern const int		busClockSpeed	= scePowerGetBusClockFrequencyInt();

#ifdef PSP_SOFTWARE_VIDEO
	#ifdef SLIM
		// How big a heap to allocate.
		static size_t  heapSize	= 16 * 1024 * 1024;
	#else
		static size_t  heapSize	= 17 * 1024 * 1024;
	#endif
#endif // PSP_SOFTWARE_VIDEO
#ifdef KERNEL_MODE
	#ifdef SLIM
		// How big a heap to allocate.
		static size_t  heapSize	= 34 * 1024 * 1024;
	#else
		static size_t  heapSize	= 10 * 1024 * 1024;
	#endif
#else
	#ifdef SLIM
		// How big a heap to allocate.
		static size_t  heapSize	= 34 * 1024 * 1024;
	#else
		static size_t  heapSize	= 10 * 1024 * 1024;
	#endif
#endif

		// Should the main loop stop running?
		static volatile bool	quit			= false;

		// Is the PSP in suspend mode?
		static volatile bool	suspended		= false;

		static int exitCallback(int arg1, int arg2, void* common)
		{
			// Signal the main thread to stop.
			quit = true;
			return 0;
		}

		static int powerCallback(int unknown, int powerInfo, void* common)
		{
			if (powerInfo & PSP_POWER_CB_POWER_SWITCH || powerInfo & PSP_POWER_CB_SUSPENDING)
			{
				suspended = true;
			}
			else if (powerInfo & PSP_POWER_CB_RESUMING)
			{
			}
			else if (powerInfo & PSP_POWER_CB_RESUME_COMPLETE)
			{
				suspended = false;
			}

			return 0;
		}

		static int callback_thread(SceSize args, void *argp)
		{
			// Register the exit callback.
			const SceUID exitCallbackID = sceKernelCreateCallback("exitCallback", exitCallback, NULL);
			sceKernelRegisterExitCallback(exitCallbackID);

			// Register the power callback.
			const SceUID powerCallbackID = sceKernelCreateCallback("powerCallback", powerCallback, NULL);
			scePowerRegisterCallback(0, powerCallbackID);

			// Sleep and handle callbacks.
			sceKernelSleepThreadCB();
			return 0;
		}

		static int setUpCallbackThread(void)
		{
			const int thid = sceKernelCreateThread("update_thread", callback_thread, 0x11, 0xFA0, PSP_THREAD_ATTR_USER, 0);
			if (thid >= 0)
				sceKernelStartThread(thid, 0, 0);
			return thid;
		}
//#endif

		static void disableFloatingPointExceptions()
		{
#ifndef _WIN32
			asm(
				".set push\n"
				".set noreorder\n"
				"cfc1    $2, $31\n"		// Get the FP Status Register.
				"lui     $8, 0x80\n"	// (?)
				"and     $8, $2, $8\n"	// Mask off all bits except for 23 of FCR. (? - where does the 0x80 come in?)
				"ctc1    $8, $31\n"		// Set the FP Status Register.
				".set pop\n"
				:						// No inputs.
				:						// No outputs.
				: "$2", "$8"			// Clobbered registers.
				);
#endif
		}
	}
}

using namespace quake;
using namespace quake::main;

#define MAX_NUM_ARGVS	50
#define MAX_ARG_LENGTH  64
static char *empty_string = "";
char    *f_argv[MAX_NUM_ARGVS];
int     f_argc;
int 	user_main(SceSize argc, void* argp);

int CheckParm (char **args, int argc, char *parm)
{
	int  i;

	for (i=1 ; i<argc ; i++)
	{
		if (!args[i])
			continue;               // NEXTSTEP sometimes clears appkit vars.
		if (!Q_strcmp (parm,args[i]))
			return i;
	}

	return 0;
}

void StartUpParams(char **args, int argc, char *cmdlinePath, char *currentDirectory, char *gameDirectory)
{

	if (CheckParm(args, f_argc,"-prompt"))
      {
		SceCtrlData pad;
		pspDebugScreenInit();

		sceCtrlSetSamplingCycle(0);
		sceCtrlSetSamplingMode(PSP_CTRL_MODE_ANALOG);

		bool done = false;

		int menu_min[3] = {0,0,0};
		int menu_max[3] = {0,1,(MAX_HEAP_MB - MIN_HEAP_MB)-1};
		int menu_cur[3] = {0,0,0};

		int menu_item_min = 0;
		int menu_item_max = 2;
		int menu_item_cur = 0;

		char temp_str[16];

		char *cpus[2];
		cpus[0] = strdup("222");
		cpus[1] = strdup("333");

		char *heaps[MAX_HEAP_MB - MIN_HEAP_MB];
		for (int i = 0 ;i < MAX_HEAP_MB - MIN_HEAP_MB; i++) {
			sprintf(temp_str, "%d", MIN_HEAP_MB+i);
			heaps[i] = strdup(temp_str);
		}

		//++ dirs setup
		char *dirs[64];
		dirs[0] = strdup("");
		int dir_fd = sceIoDopen(gameDirectory);
		int j = 1;

 		if (dir_fd >= 0) {
 			SceIoDirent* p_dir_de = new SceIoDirent;
 			int res = -1;

 			do {
 				res = sceIoDread(dir_fd, p_dir_de);
 				if ((res > 0) && (p_dir_de->d_stat.st_attr & FIO_SO_IFDIR)) {
 					if (!(stricmp(p_dir_de->d_name, ".") == 0 || stricmp(p_dir_de->d_name, "..") == 0 ||
 					      stricmp(p_dir_de->d_name, "mp3") == 0 || stricmp(p_dir_de->d_name, "id1") == 0)) {
 						dirs[j++] = strdup( p_dir_de->d_name);
 					}
 				}
 			} while (res > 0);
 			delete p_dir_de;
 		}
		sceIoDclose(dir_fd);
		//-- dirs setup

		menu_max[0] = j-1;

		if (CheckParm(args, f_argc, "-cpu333"))
			menu_cur[1] = 1;

		if (CheckParm(args, f_argc, "-heap")) {
			int idx = CheckParm(args, f_argc, "-heap");

			if (idx+1 < f_argc) {
				for (int i = 0 ;i < MAX_HEAP_MB - MIN_HEAP_MB; i++) {
					if (stricmp(heaps[i], args[idx+1]) == 0) {
						menu_cur[2] = i;
					}

					if (args[idx+1][0] == '-') {
						args[idx][0] = '\0';
					}
				}
			}
		} else {
			for (int i = 0 ;i < MAX_HEAP_MB - MIN_HEAP_MB; i++) {
				sprintf(temp_str, "%d", heapSize/(1024*1024));
				if (stricmp(heaps[i],temp_str) == 0) {
					menu_cur[2] = i;
				}
			}
		}

		if (CheckParm(args, f_argc, "-game")) {
			int idx = CheckParm(args, f_argc, "-game");

			if (idx+1 < f_argc) {
				for (int i = 0 ;i < j; i++) {
					if (stricmp(args[idx+1],dirs[i]) == 0) {
						menu_cur[0] = i;
					}

					if (args[idx+1][0] == '-') {
						args[idx][0] = '\0';
					}
				}
			}
		}

		while(!done) {
			sceDisplayWaitVblankStart();
    		sceDisplayWaitVblankStart();
    		sceDisplayWaitVblankStart();
			sceDisplayWaitVblankStart();
    		sceDisplayWaitVblankStart();
    		sceDisplayWaitVblankStart();

			pspDebugScreenSetXY(0, 2);
			sceCtrlReadBufferPositive(&pad, 1);

			pspDebugScreenSetTextColor(0xffffff);

			printf("DQuake v%4.2f \n", (float)VERSION);
			printf("---------------- \n");
			printf("Command line file : %s \n", cmdlinePath);
			printf("Startup directory : %s \n", currentDirectory);
			printf("Game directory    : %s \n", gameDirectory);
			printf("\n");
			printf("Press [X]Cross to Continue [O]Circle to Quit\n");
			printf("\n");

			pspDebugScreenSetTextColor(0x00ffff);

			if (j > -1) {
				if (menu_item_cur == 0)
					pspDebugScreenSetTextColor(0x00ff00);
				printf("Mod directory     : [%d/%d] '%s' \t \n", 1+menu_cur[0], 1+menu_max[0], dirs[menu_cur[0]]);
				pspDebugScreenSetTextColor(0x00ffff);
			}
			if (menu_item_cur == 1)
				pspDebugScreenSetTextColor(0x00ff00);
			printf("CPU Speed         : [%d/%d] '%s' \t \n", 1+menu_cur[1], 1+menu_max[1], cpus[menu_cur[1]]);
			pspDebugScreenSetTextColor(0x00ffff);

			if (menu_item_cur == 2)
				pspDebugScreenSetTextColor(0x00ff00);
			printf("Heap Size         : [%d/%d] '%s' \t \n", 1+menu_cur[2], 1+menu_max[2], heaps[menu_cur[2]]);
			pspDebugScreenSetTextColor(0xffffff);

			if (pad.Buttons != 0) {
				if (pad.Buttons & PSP_CTRL_CIRCLE){
                    pspDebugScreenSetTextColor(0x0000ff);
                    printf("\n");
					printf("Shutting down...\n");
                    printf("\n");
					pspDebugScreenSetTextColor(0x00ffff);
					Sys_Quit();
				}
				if (pad.Buttons & PSP_CTRL_CROSS){
					done = true;
				}
				if (pad.Buttons & PSP_CTRL_UP){
					menu_item_cur--;
					menu_item_cur = (menu_item_cur < menu_item_min ? menu_item_min : menu_item_cur);
				}
				if (pad.Buttons & PSP_CTRL_DOWN){
					menu_item_cur++;
					menu_item_cur = (menu_item_cur > menu_item_max ? menu_item_max : menu_item_cur);
				}
				if (pad.Buttons & PSP_CTRL_LEFT){
					menu_cur[menu_item_cur]--;
					menu_cur[menu_item_cur] = (menu_cur[menu_item_cur] < menu_min[menu_item_cur] ? menu_min[menu_item_cur] : menu_cur[menu_item_cur]);
				}
				if (pad.Buttons & PSP_CTRL_RIGHT){
					menu_cur[menu_item_cur]++;
					menu_cur[menu_item_cur] = (menu_cur[menu_item_cur] > menu_max[menu_item_cur] ? menu_max[menu_item_cur] : menu_cur[menu_item_cur]);
				}
			}
			if(sceHprmIsRemoteExist()){
               unsigned int hprmkey;
	           sceHprmPeekCurrentKey(&hprmkey);
			   if (hprmkey != 0){
                   if (hprmkey & PSP_HPRM_BACK){
                      menu_cur[menu_item_cur]--;
					  menu_cur[menu_item_cur] = (menu_cur[menu_item_cur] < menu_min[menu_item_cur] ? menu_min[menu_item_cur] : menu_cur[menu_item_cur]);
				   }
				   if (hprmkey & PSP_HPRM_FORWARD){
                      menu_cur[menu_item_cur]++;
					  menu_cur[menu_item_cur] = (menu_cur[menu_item_cur] > menu_max[menu_item_cur] ? menu_max[menu_item_cur] : menu_cur[menu_item_cur]);
				   }
				   if (hprmkey & PSP_HPRM_PLAYPAUSE){
					done = true;
				   }
				}
			}

		}
		if (CheckParm(args, f_argc, "-game")) {
			int idx = CheckParm(args, f_argc, "-game");
			if (stricmp(args[idx+1],dirs[menu_cur[0]]) != 0) {

				if (strlen(dirs[menu_cur[0]]) > 0) {
					int len2 = strlen(dirs[menu_cur[0]]);
					args[idx+1] = new char[len2+1];
					strcpy(args[idx+1], dirs[menu_cur[0]]);
				} else {
					strcpy(args[idx], "");
					strcpy(args[idx+1], "");
				}
			}
		}
		else {
			if (strlen(dirs[menu_cur[0]]) > 0) {
				int len1 = strlen("-game");
				int len2 = strlen(dirs[menu_cur[0]]);

				args[f_argc] = new char[len1+1];
				args[f_argc+1] = new char[len2+1];

				strcpy(args[f_argc], "-game");
				strcpy(args[f_argc+1], dirs[menu_cur[0]]);

				f_argc += 2;
			}
		}

		if (stricmp(cpus[menu_cur[1]],"333") == 0) {

			if (!CheckParm(args, f_argc, "-cpu333")) {
				int len1 = strlen("-cpu333");

				args[f_argc] = new char[len1+1];
				strcpy(args[f_argc], "-cpu333");

				f_argc += 1;
			}
		} else {
			if (CheckParm(args, f_argc, "-cpu333")) {
				int idx = CheckParm(args, f_argc, "-cpu333");
				strcpy(args[idx], "-cpu222");
			}
		}

		if (CheckParm(args, f_argc, "-heap")) {

			int idx = CheckParm(args, f_argc, "-heap");

			int len2 = strlen(heaps[menu_cur[2]]);

			args[idx+1] = new char[len2+1];
			strcpy(args[idx+1], heaps[menu_cur[2]]);
		}
		else {
			int len1 = strlen("-heap");
			int len2 = strlen(heaps[menu_cur[2]]);

			args[f_argc] = new char[len1+1];
			args[f_argc+1] = new char[len2+1];

			strcpy(args[f_argc], "-heap");
			strcpy(args[f_argc+1], heaps[menu_cur[2]]);

			f_argc += 2;
		}

		// get rid of temp. alloc memory
		for (int i = 0 ;i < MAX_HEAP_MB - MIN_HEAP_MB; i++) {
			free(heaps[i]);
		}
		for (int i = 0 ;i < j; i++) {
			free(dirs[i]);
		}
		free(cpus[0]);
		free(cpus[1]);
		pspDebugScreenClear();
	}
}

int ctrl_kernel = 0;
SceUID mod[2];
char mod_names[2][64];

void InitExtModules (void)
{
	char 	currentDirectory[1024];
	char 	gameDirectory[1024];
	char   	path_f[256];

	memset(gameDirectory, 0, sizeof(gameDirectory));
	memset(currentDirectory, 0, sizeof(currentDirectory));
	getcwd(currentDirectory, sizeof(currentDirectory) - 1);

	strcpy(path_f,currentDirectory);
	strcat(path_f,"/hooks/vramext.prx");
	sprintf(mod_names[1], path_f);

	mod[1] = pspSdkLoadStartModule(mod_names[1], PSP_MEMORY_PARTITION_KERNEL);
	if (mod[1] >= 0)
	{
		if (kuKernelGetModel() != 0)
			VramSetSize(4096);
		else
			VramSetSize(2048);
	}
}

void ShutdownExtModules (void)
{
  	if(mod[0] < 0)
	   return;

	sceKernelStopModule(mod[0], 0, 0, 0, 0);
	sceKernelUnloadModule(mod[0]);
}

int main(int argc, char *argv[])
{
#ifdef KERNEL_MODE
	// Load the network modules

    	// create user thread, tweek stack size here if necessary
    	SceUID thid = sceKernelCreateThread("User Mode Thread", user_main,
            0x20, // default priority
            512 * 1024, // stack size (256KB is regular default)
            PSP_THREAD_ATTR_USBWLAN | PSP_THREAD_ATTR_USER  | PSP_THREAD_ATTR_VFPU , NULL);

	// start user thread, then wait for it to do everything else
	sceKernelStartThread(thid, 0, NULL);
	sceKernelWaitThreadEnd(thid, NULL);

	sceKernelExitGame();
}

int user_main(SceSize argc, void* argp)
	{
#endif
	// Set up the callback thread, this is not appropriate for use with
	// the loader, so don't bother calling it as it apparently seems to
	// cause problems with firmware 2.0+
	setUpCallbackThread();


	// Disable floating point exceptions.
	// If this isn't done, Quake crashes from (presumably) divide by zero
	// operations.
	disableFloatingPointExceptions();

	// init perflib
	PFL_Init(true);

	// Initialise the Common module.
    InitExtModules ();

	// Get the current working dir.
	char currentDirectory[1024];
	char gameDirectory[1024];

	memset(gameDirectory, 0, sizeof(gameDirectory));
	memset(currentDirectory, 0, sizeof(currentDirectory));
	getcwd(currentDirectory, sizeof(currentDirectory) - 1);

	char   path_f[256];
	strcpy(path_f,currentDirectory);
	strcat(path_f,"/setup.ini");
	Sys_ReadCommandLineFile(path_f);

	char *args[MAX_NUM_ARGVS];

	for (int k =0; k < f_argc; k++) {
		int len = strlen(f_argv[k]);
		args[k] = new char[len+1];
		strcpy(args[k], f_argv[k]);
	}

	if (CheckParm(args, f_argc,"-32depth"))
		depthfl = qtrue;

	if (CheckParm(args, f_argc, "-gamedir")) 
	{
		char* tempStr = args[CheckParm(args, f_argc,"-gamedir")+1];
		strncpy(gameDirectory, tempStr, sizeof(gameDirectory)-1);
	}
	else
	{
		strncpy(gameDirectory,currentDirectory,sizeof(gameDirectory)-1);
	}

	/////
	StartUpParams(args, f_argc, path_f, currentDirectory, gameDirectory);

	if (CheckParm(args, f_argc, "-heap")) {
		char* tempStr = args[CheckParm(args, f_argc,"-heap")+1];
		int heapSizeMB = atoi(tempStr);

		if (heapSizeMB < MIN_HEAP_MB )
			heapSizeMB = MIN_HEAP_MB;

		if (heapSizeMB > MAX_HEAP_MB )
			heapSizeMB = MAX_HEAP_MB;

		heapSize = heapSizeMB * 1024 * 1024;
	}
	// Allocate the heap.
	std::vector<unsigned char>	heap(heapSize, 0);

#if CONSOLE_DEBUG
	if (f_argc > 1) {
		args[f_argc++] = "-condebug";
		COM_InitArgv(f_argc, args);
	}
	else {
		args[0] = "";
		args[1] = "-condebug";
		COM_InitArgv(2, args);
	}
#else
	if (f_argc > 1)
		COM_InitArgv(f_argc, args);
	else {
		args[0] = "";
		COM_InitArgv(0, NULL);
	}
#endif

#ifdef PSP_SOFTWARE_VIDEO
	// Bump up the clock frequency.
	if (!COM_CheckParm("-cpu222")) {
		scePowerSetClockFrequency(333, 333, 166);
		//PFL_SetCPUFrequency(222);
	}
#else
	if (COM_CheckParm("-cpu333")) {
		scePowerSetClockFrequency(333, 333, 166);
		//PFL_SetCPUFrequency(333);
	}
#endif

	// Catch exceptions from here.
	try
	{
		// Initialise the Host module.
		quakeparms_t parms;
		memset(&parms, 0, sizeof(parms));
		parms.argc		= com_argc;
		parms.argv		= com_argv;
		parms.basedir	= gameDirectory;
		parms.memsize	= heap.size();
		parms.membase	= &heap.at(0);
		Host_Init(&parms);

		// Precalculate the tick rate.
		const float oneOverTickRate = 1.0f / sceRtcGetTickResolution();

		// Record the time that the main loop started.
		u64 lastTicks;
		sceRtcGetCurrentTick(&lastTicks);

		// Set up threads
		Sys_InitThreads();

		// Enter the main loop.
		while (!quit)
		{
			// start cpu profiling
			PFL_BeginCPURecord();

			// Handle suspend & resume.
			if (suspended)
			{
				// Suspend.
				S_ClearBuffer();
				quake::system::suspend();

				// Wait for resume.
				while (suspended && !quit)
				{
					sceDisplayWaitVblankStart();
				}

				// Resume.
				quake::system::resume();

				// Reset the clock.
				sceRtcGetCurrentTick(&lastTicks);
			}

			// What is the time now?
			u64 ticks;
			sceRtcGetCurrentTick(&ticks);

			// How much time has elapsed?
			const unsigned int	deltaTicks		= ticks - lastTicks;
			const float			deltaSeconds	= deltaTicks * oneOverTickRate;

			// Check the battery status.
			battery::check();

			// Run the frame.
			Host_Frame(deltaSeconds);
			// Remember the time for next frame.
			lastTicks = ticks;

			// end cpu profiling
			PFL_EndCPURecord();
		}
	}
	catch (const std::exception& e)
	{
		// Report the error and quit.
		Sys_Error("C++ Exception: %s", e.what());
		return 0;
	}

	// Quit.
	Sys_Quit();
	return 0;
}

void Sys_ReadCommandLineFile (char* netpath)
{
	int 	in;
	int     remaining, count;
	char    buf[4096];
	int     argc = 1;

	remaining = Sys_FileOpenRead (netpath, &in);

	if (in > 0 && remaining > 0) {
		count = Sys_FileRead (in, buf, 4096);
		f_argv[0] = empty_string;

		char* lpCmdLine = buf;

		while (*lpCmdLine && (argc < MAX_NUM_ARGVS))
		{
			while (*lpCmdLine && ((*lpCmdLine <= 32) || (*lpCmdLine > 126)))
				lpCmdLine++;

			if (*lpCmdLine)
			{
				f_argv[argc] = lpCmdLine;
				argc++;

				while (*lpCmdLine && ((*lpCmdLine > 32) && (*lpCmdLine <= 126)))
					lpCmdLine++;

				if (*lpCmdLine)
				{
					*lpCmdLine = 0;
					lpCmdLine++;
				}
			}
		}
		f_argc = argc;
	} else {
		f_argc = 0;
	}

	if (in > 0)
		Sys_FileClose (in);
}

char* Sys_GetPSPModel(void) 
{
	// check for the vita prx
	int vitaprx = sceIoOpen("flash0:/kd/registry.prx", PSP_O_RDONLY | PSP_O_WRONLY, 0777);

	if (vitaprx >= 0) {
		sceIoClose(vitaprx);
		return "PS Vita (PSP2)";
	}

	// normal psp models
	char* modelstring;

	sys_psp_model = kuKernelGetModel();
	switch(sys_psp_model) {
		case 0:
			modelstring = "PSP Phat (1000)";
			break;
		case 1:
			modelstring = "PSP Slim (2000)";
			break;
		case 2:
			modelstring = "PSP Brite (3000)";
			break;
		case 4:
			modelstring = "PSP GO (4000)";
			break;
		case 10:
			modelstring = "PSP Street (E1000)";
			break;
		default:
			break;
	}

	return modelstring;
}