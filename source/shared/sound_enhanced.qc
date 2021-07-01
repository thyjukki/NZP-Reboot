//
// sound_enhanced.qc -- mainly serves as a QC middleground for sound to adjust volume per channel.
//

#define CHAN_MUSIC      1
#define CHAN_SFX        2

#ifndef PSP
#ifndef NX
void(string soundname, optional float channel, optional float volume) localsound_enhanced =
{
    if (!volume)
        volume = 1;

    switch(channel) {
        case 1: volume *= cvar("snd_channel1volume"); break;
        case 2: volume *= cvar("snd_channel2volume"); break;
        case 3: volume *= cvar("snd_channel3volume"); break;
        case 4: volume *= cvar("snd_channel4volume"); break;
        case 5: volume *= cvar("snd_channel5volume"); break;
        case 6: volume *= cvar("snd_channel6volume"); break;
        default: break;
    }

    localsound(soundname, channel, volume);
}
#endif
#endif