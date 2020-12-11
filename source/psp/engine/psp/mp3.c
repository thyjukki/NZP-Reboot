/*
 * PSP Software Development Kit - http://www.pspdev.org
 * -----------------------------------------------------------------------
 * Licensed under the BSD license, see LICENSE in PSPSDK root for details.
 *
 * main.c - Basic PRX template
 *
 * Copyright (c) 2005 Marcus R. Brown <mrbrown@ocgnet.org>
 * Copyright (c) 2005 James Forshaw <tyranid@gmail.com>
 * Copyright (c) 2005 John Kelley <ps2dev@kelley.ca>
 * 2012 dr_mabuse1981: well, i just kicked out Crow_bars shitty and buggy mp3 player
 * and re-added the kurok one again and added bakers mp3 fix ;)
 *
 * $Id: main.c 1888 2006-05-01 08:47:04Z tyranid $
 * $HeadURL$
 */
#include <pspkernel.h>
#include <pspsdk.h>
#include <stdio.h>
#include <string.h>
#include <pspaudiocodec.h>
#include <pspaudio.h> 
#include "m33libs/kubridge.h"

int mp3_last_error = 0;

static int initialized = 0;
static SceUID thread_job_sem = -1;
static SceUID thread_busy_sem = -1;
static int thread_exit = 0;

int done = 0;

int mp3_job_started = 0;

int mp3_volume;

static int mp3_src_pos = 0;

int first_run = 0;

// MPEG-1, layer 3
static int bitrates[] = { 0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0 };
//static int samplerates[] = { 44100, 48000, 32000, 0 };

#define MIN_INFRAME_SIZE 96
#define IN_BUFFER_SIZE (2*1024)

static unsigned long mp3_codec_struct[65];// __attribute__((aligned(64)));

static unsigned char mp3_src_buffer[2][IN_BUFFER_SIZE];// __attribute__((aligned(64)));
static short mp3_mix_buffer[2][1152*2];// __attribute__((aligned(64)));
static int working_buf = 0;

static const char *mp3_fname = NULL;
static SceUID mp3_handle = -1;
static int mp3_src_size = 0;

static int decode_thread(SceSize args, void *argp);


static void psp_sem_lock(SceUID sem)
{
	int ret = sceKernelWaitSema(sem, 1, 0);
	if (ret < 0) printf("sceKernelWaitSema(%08x) failed with %08x\n", sem, ret);
}

static void psp_sem_unlock(SceUID sem)
{
	int ret = sceKernelSignalSema(sem, 1);
	if (ret < 0) printf("sceKernelSignalSema(%08x) failed with %08x\n", sem, ret);
}

// only accepts MPEG-1, layer3
static int find_sync_word(unsigned char *data, int len)
{
	int i;
	for (i = 0; i < len-1; i++)
	{
		if ( data[i+0] != 0xff) continue;
		if ((data[i+1] & 0xfe) == 0xfa) return i;
		i++;
	}
	return -1;
}

// Baker: called only by decode_thread
static int read_next_frame(int which_buffer)
{
   int i, bytes_read, frame_offset;
   int bitrate, padding, frame_size = 0;

   for (i = 0; i < 32; i++)
   {
      bytes_read = sceIoRead(mp3_handle, mp3_src_buffer[which_buffer], sizeof(mp3_src_buffer[which_buffer]));
      mp3_src_pos += bytes_read;
      if (bytes_read < MIN_INFRAME_SIZE)
      {
         // Baker: end of file hit, restart + re-read
         mp3_src_pos = 0;
         sceIoLseek32(mp3_handle, mp3_src_pos, PSP_SEEK_SET);
         bytes_read = sceIoRead(mp3_handle, mp3_src_buffer[which_buffer], sizeof(mp3_src_buffer[which_buffer]));
         mp3_src_pos += bytes_read;

      }
      frame_offset = find_sync_word(mp3_src_buffer[which_buffer], bytes_read);
      if (frame_offset < 0) {
         printf("missing syncword, foffs=%i\n", mp3_src_pos - bytes_read);
         mp3_src_pos--;
         sceIoLseek32(mp3_handle, mp3_src_pos, PSP_SEEK_SET);
         continue;
      }
      if (bytes_read - frame_offset < 4) {
         printf("syncword @ EOB, foffs=%i\n", mp3_src_pos - bytes_read);
         mp3_src_pos--;
         sceIoLseek32(mp3_handle, mp3_src_pos, PSP_SEEK_SET);
         continue;
      }

      bitrate =  mp3_src_buffer[which_buffer][frame_offset+2] >> 4;
      padding = (mp3_src_buffer[which_buffer][frame_offset+2] & 2) >> 1;

      frame_size = 144000*bitrates[bitrate]/44100 + padding;
      if (frame_size <= 0) {
         printf("bad frame, foffs=%i\n", mp3_src_pos - bytes_read);
         continue; // bad frame
      }

      if (bytes_read - frame_offset < frame_size)
      {
         printf("unfit, foffs=%i\n", mp3_src_pos - bytes_read);
         mp3_src_pos -= bytes_read - frame_offset;
         if (mp3_src_size - mp3_src_pos < frame_size) {
            mp3_src_pos = mp3_src_size;
            return 0; // EOF
         }
         sceIoLseek32(mp3_handle, mp3_src_pos, PSP_SEEK_SET);
         continue; // didn't fit, re-read..
      }

      if (frame_offset) {
         //printf("unaligned, foffs=%i, offs=%i\n", mp3_src_pos - bytes_read, frame_offset);
         memmove(mp3_src_buffer[which_buffer], mp3_src_buffer[which_buffer] + frame_offset, frame_size);
      }

      // align for next frame read
      mp3_src_pos -= bytes_read - (frame_offset + frame_size);
      sceIoLseek32(mp3_handle, mp3_src_pos, PSP_SEEK_SET);

      break;
   }

   return frame_size > 0 ? frame_size : -1;
}


static SceUID load_start_module(const char *prxname)
{
	SceUID mod, mod1;
	int status, ret;

	mod = pspSdkLoadStartModule(prxname, PSP_MEMORY_PARTITION_KERNEL);
	if (mod < 0) {
		printf("failed to load %s (%08x), trying kuKernelLoadModule\n", prxname, mod);
		mod1 = kuKernelLoadModule(prxname, 0, NULL);
		if (mod1 < 0) printf("kuKernelLoadModule failed with %08x\n", mod1);
		else {
			ret = sceKernelStartModule(mod1, 0, NULL, &status, 0);
			if (ret < 0) printf("sceKernelStartModule failed with %08x\n", ret);
			else mod = mod1;
		}
	}
	return mod;
}


int mp3_init(void)
{
	SceUID thid, mod;
	int ret;

	/* load modules */
	/* <= 1.5 (and probably some other, not sure which) fw need this to for audiocodec to work,
	 * so if it fails, assume we are just on new enough firmware and continue.. */
	load_start_module("flash0:/kd/me_for_vsh.prx");

	if (sceKernelDevkitVersion() < 0x02070010)
	     mod = load_start_module("flash0:/kd/audiocodec.prx");
	else mod = load_start_module("flash0:/kd/avcodec.prx");
	if (mod < 0) {
		ret = mod = load_start_module("flash0:/kd/audiocodec_260.prx"); // last chance..
		if (mod < 0) goto fail;
	}

	/* audiocodec init */
	memset(mp3_codec_struct, 0, sizeof(mp3_codec_struct));
	ret = sceAudiocodecCheckNeedMem(mp3_codec_struct, 0x1002);
	if (ret < 0) {
		printf("sceAudiocodecCheckNeedMem failed with %08x\n", ret);
		goto fail;
	}

	ret = sceAudiocodecGetEDRAM(mp3_codec_struct, 0x1002);
	if (ret < 0) {
		printf("sceAudiocodecGetEDRAM failed with %08x\n", ret);
		goto fail;
	}

	ret = sceAudiocodecInit(mp3_codec_struct, 0x1002);
	if (ret < 0) {
		printf("sceAudiocodecInit failed with %08x\n", ret);
		goto fail1;
	}

	/* thread and stuff */
	thread_job_sem = sceKernelCreateSema("p_mp3job_sem", 0, 0, 1, NULL);
	if (thread_job_sem < 0) {
		printf("sceKernelCreateSema() failed: %08x\n", thread_job_sem);
		ret = thread_job_sem;
		goto fail1;
	}

	thread_busy_sem = sceKernelCreateSema("p_mp3busy_sem", 0, 1, 1, NULL);
	if (thread_busy_sem < 0) {
		printf("sceKernelCreateSema() failed: %08x\n", thread_busy_sem);
		ret = thread_busy_sem;
		goto fail2;
	}

	thread_exit = 0;
	thid = sceKernelCreateThread("mp3decode_thread", decode_thread, 30, 0x2000, 0, 0); /* use slightly higher prio then main */
	if (thid < 0) {
		printf("failed to create decode thread: %08x\n", thid);
		ret = thid;
		goto fail3;
	}
	ret = sceKernelStartThread(thid, 0, 0);
	if (ret < 0) {
		printf("failed to start decode thread: %08x\n", ret);
		goto fail3;
	}

	mp3_last_error = 0;
	initialized = 1;
	return 0;

fail3:
	sceKernelDeleteSema(thread_busy_sem);
	thread_busy_sem = -1;
fail2:
	sceKernelDeleteSema(thread_job_sem);
	thread_job_sem = -1;
fail1:
	sceAudiocodecReleaseEDRAM(mp3_codec_struct);
fail:
	mp3_last_error = ret;
	initialized = 0;
	return 1;
}

void mp3_deinit(void)
{
	printf("mp3_deinit, initialized=%i\n", initialized);

	if (!initialized) return;
	thread_exit = 1;
	psp_sem_lock(thread_busy_sem);
	psp_sem_unlock(thread_busy_sem);

	sceKernelSignalSema(thread_job_sem, 1);
	sceKernelDelayThread(100*1000);

	if (mp3_handle >= 0) sceIoClose(mp3_handle);
	mp3_handle = -1;
	mp3_fname = NULL;
	
	psp_sem_lock(thread_job_sem);
	psp_sem_unlock(thread_job_sem);

	sceKernelDeleteSema(thread_busy_sem);
	thread_busy_sem = -1;
	sceKernelDeleteSema(thread_job_sem);
	thread_job_sem = -1;
	sceAudiocodecReleaseEDRAM(mp3_codec_struct);
	initialized = 0;
	
}


short mp3_output_buffer[4][1152 * 2] __attribute__((aligned(64)));
int mp3_output_index = 0; 

// may overflow stack?
static int decode_thread(SceSize args, void *argp)
{
	int ret, frame_size;
	
	int audio_channel = sceAudioChReserve(1, 1152, PSP_AUDIO_FORMAT_STEREO); 

	printf("decode_thread started with id %08x, priority %i\n",
                sceKernelGetThreadId(), sceKernelGetThreadCurrentPriority());

	while (!thread_exit)
	{
		psp_sem_lock(thread_job_sem);
		
		if (thread_exit) {
			psp_sem_unlock(thread_job_sem);
			break;
			}

		psp_sem_lock(thread_busy_sem);

		frame_size = read_next_frame(working_buf);
		
		while (mp3_job_started)
		{
		
			if (thread_exit) break;

			if(frame_size > 0)
			{
				mp3_codec_struct[6] = (unsigned long)mp3_src_buffer[working_buf];
				mp3_codec_struct[8] = (unsigned long)mp3_mix_buffer[working_buf];
				mp3_codec_struct[7] = mp3_codec_struct[10] = frame_size;
				mp3_codec_struct[9] = 1152 * 4;

				ret = sceAudiocodecDecode(mp3_codec_struct, 0x1002);
				if (ret < 0) printf("sceAudiocodecDecode failed with %08x\n", ret);
				
				memcpy(mp3_output_buffer[mp3_output_index], mp3_mix_buffer[working_buf], 1152*4);
				sceAudioOutputBlocking(audio_channel, mp3_volume, mp3_output_buffer[mp3_output_index]);
				mp3_output_index = (mp3_output_index+1)%4; 
				
				memset(mp3_mix_buffer, 0, 1152*2*2);
				
				frame_size = read_next_frame(working_buf);
			}
			
			
		}

		if (!mp3_job_started) {
			
			if (mp3_handle >= 0) sceIoClose(mp3_handle);
			mp3_handle = -1;
			mp3_fname = NULL;
		}
		
		psp_sem_unlock(thread_busy_sem);
		
		
	}

	printf("leaving decode thread\n");
	sceKernelExitDeleteThread(0);
	return 0;
}

static int mp3_samples_ready = 0, mp3_buffer_offs = 0, mp3_play_bufsel = 0;

int mp3_start_play(char *fname, int pos)
{

	printf("mp3_start_play(%s) @ %i\n", fname, pos);
	psp_sem_lock(thread_busy_sem);

	if (mp3_fname != fname || mp3_handle < 0)
	{
		if (mp3_handle >= 0) sceIoClose(mp3_handle);
		mp3_handle = sceIoOpen(fname, PSP_O_RDONLY, 0777);
		if (mp3_handle < 0) {
			printf("sceIoOpen(%s) failed\n", fname);
			psp_sem_unlock(thread_busy_sem);
			sceIoClose(mp3_handle);
			return 2;
		}
		mp3_src_size = sceIoLseek32(mp3_handle, 0, PSP_SEEK_END);
		mp3_fname = fname;
	}

	// seek..
	mp3_src_pos = (int) (((float)pos / 1023.0f) * (float)mp3_src_size);
	sceIoLseek32(mp3_handle, mp3_src_pos, PSP_SEEK_SET);
	printf("seek %i: %i/%i\n", pos, mp3_src_pos, mp3_src_size);

	mp3_job_started = 1;
	mp3_samples_ready = mp3_buffer_offs = mp3_play_bufsel = 0;
	working_buf = 0;

	/* send a request to decode first frame */
	psp_sem_unlock(thread_busy_sem);
	psp_sem_unlock(thread_job_sem);
	sceKernelDelayThread(1); // reschedule
	
	return 0;
}


