#include <pspkernel.h>

#include "quakedef.h"
#include "thread.h"

SceUID sound_thread;
qboolean threads_should_quit;
soundstruct_t snd_thread_struct[10];

void Thread_UpdateSound(vec3_t origin, vec3_t forward, vec3_t right, vec3_t up)
{
    int index;
    index = -1;
    for (int i = 0; i < 10; i++) {
        if (snd_thread_struct[i].ready == false) {
            index = i;
            break;
        }
    }

    snd_thread_struct[index].origin[0] = origin[0];
    snd_thread_struct[index].origin[1] = origin[1];
    snd_thread_struct[index].origin[2] = origin[2];
    snd_thread_struct[index].forward[0] = forward[0];
    snd_thread_struct[index].forward[1] = forward[1];
    snd_thread_struct[index].forward[2] = forward[2];
    snd_thread_struct[index].right[0] = right[0];
    snd_thread_struct[index].right[1] = right[1];
    snd_thread_struct[index].right[2] = right[2];
    snd_thread_struct[index].up[0] = up[0];
    snd_thread_struct[index].up[1] = up[1];
    snd_thread_struct[index].up[2] = up[2];
    snd_thread_struct[index].ready = true;
}

int Thread_Sound(SceSize args, void *argp)
{
    while (!threads_should_quit) {
        // loop and see sound processes in the queue
        for (int i = 0; i < 10; i++) {
            if (snd_thread_struct[i].ready == true) {
                snd_thread_struct[i].ready = false;
                S_Update(snd_thread_struct[i].origin, snd_thread_struct[i].forward, snd_thread_struct[i].right, snd_thread_struct[i].up);
            }
        }

        // sleep for 10ms
        sceKernelDelayThread(10);
    }

    return 0;
}

void Sys_InitThreads(void)
{
    threads_should_quit = false;
    sound_thread = sceKernelCreateThread("sound_thread", Thread_Sound, 0x18, 0x10000, PSP_THREAD_ATTR_USER | PSP_THREAD_ATTR_VFPU, NULL);
    sceKernelStartThread(sound_thread, 0, NULL);
}