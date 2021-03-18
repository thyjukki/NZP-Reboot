#ifndef _THREAD_H_
#define _THREAD_H_

#include <pspkernel.h>

extern SceUID sound_thread;
extern qboolean threads_should_quit;

extern void Sys_InitThreads(void);
extern void Thread_UpdateSound(vec3_t origin, vec3_t forward, vec3_t right, vec3_t up);

#endif