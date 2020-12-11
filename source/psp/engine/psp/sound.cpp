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

#include <pspaudiolib.h>
#include <pspkernel.h>

extern "C"
{
#include "../quakedef.h"
}

namespace quake
{
	namespace sound
	{
		struct Sample
		{
			short left;
			short right;
		};

		static const unsigned int		channelCount				= 2;
		static const unsigned int		inputBufferSize				= 16384;
		static const unsigned int		inputFrequency				= 11025;
		static const unsigned int		outputFrequency				= 44100;
		static const unsigned int		inputSamplesPerOutputSample	= outputFrequency / inputFrequency;
		static Sample					inputBuffer[inputBufferSize];
		static volatile unsigned int	samplesRead;

		static inline void copySamples(const Sample* first, const Sample* last, Sample* destination)
		{
			switch (inputSamplesPerOutputSample)
			{
			case 1:
				memcpy(destination, first, (last - first) * sizeof(Sample));
				break;

			case 2:
				for (const Sample* source = first; source != last; ++source)
				{
					const Sample sample = *source;
					*destination++ = sample;
					*destination++ = sample;
				}
				break;

			case 4:
				for (const Sample* source = first; source != last; ++source)
				{
					const Sample sample = *source;
					*destination++ = sample;
					*destination++ = sample;
					*destination++ = sample;
					*destination++ = sample;
				}
				break;

			default:
				break;
			}
		}

		static void fillOutputBuffer(void* buffer, unsigned int samplesToWrite, void* userData)
		{
			// Where are we writing to?
			Sample* const destination = static_cast<Sample*> (buffer);

			// Where are we reading from?
			const Sample* const firstSampleToRead = &inputBuffer[samplesRead];

			// How many samples to read?
			const unsigned int samplesToRead = samplesToWrite / inputSamplesPerOutputSample;

			// Going to wrap past the end of the input buffer?
			const unsigned int samplesBeforeEndOfInput = inputBufferSize - samplesRead;
			if (samplesToRead > samplesBeforeEndOfInput)
			{
				// Yes, so write the first chunk from the end of the input buffer.
				copySamples(
					firstSampleToRead,
					firstSampleToRead + samplesBeforeEndOfInput,
					&destination[0]);

				// Write the second chunk from the start of the input buffer.
				const unsigned int samplesToReadFromBeginning = samplesToRead - samplesBeforeEndOfInput;
				copySamples(
					&inputBuffer[0],
					&inputBuffer[samplesToReadFromBeginning],
					&destination[samplesBeforeEndOfInput * inputSamplesPerOutputSample]);
			}
			else
			{
				// No wrapping, just copy.
				copySamples(
					firstSampleToRead,
					firstSampleToRead + samplesToRead,
					&destination[0]);
			}

			// Update the read offset.
			samplesRead = (samplesRead + samplesToRead) % inputBufferSize;
		}
	}
}

using namespace quake;
using namespace quake::sound;

qboolean SNDDMA_Init(void)
{
	// Set up Quake's audio.
	shm = &sn;
	shm->channels			= channelCount;
	shm->samplebits			= 16;
	shm->speed				= inputFrequency;
	shm->soundalive			= qtrue;
	shm->splitbuffer		= qfalse;
	shm->samples			= inputBufferSize * channelCount;
	shm->samplepos			= 0;
	shm->submission_chunk	= 1;
	shm->buffer				= (unsigned char *) inputBuffer;

	// Initialise the audio system. This initialises it for the CD audio module
	// too.
	pspAudioInit();

	// Set the channel callback.
	// Sound effects use channel 0, CD audio uses channel 1.
	pspAudioSetChannelCallback(0, fillOutputBuffer, 0);

	return qtrue;
}

void SNDDMA_Shutdown(void)
{
	// Clear the mixing buffer so we don't get any noise during cleanup.
	memset(inputBuffer, 0, sizeof(inputBuffer));

	// Clear the channel callback.
	pspAudioSetChannelCallback(0, 0, 0);

	// Stop the audio system?
	pspAudioEndPre();

	// Insert a false delay so the thread can be cleaned up.
	sceKernelDelayThread(50 * 1000);

	// Shut down the audio system.
	pspAudioEnd();
}

int SNDDMA_GetDMAPos(void)
{
	return samplesRead * channelCount;
}

void SNDDMA_Submit(void)
{
}
