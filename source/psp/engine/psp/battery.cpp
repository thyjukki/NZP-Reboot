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

#include <psppower.h>

extern "C"
{
#include "../quakedef.h"
}

extern cvar_t show_bat;

#include "battery.hpp"

namespace quake
{
	namespace battery
	{
		// The previous battery level.
		static int	lastLevel		= scePowerGetBatteryLifePercent();
		static bool	lastCharging	= scePowerGetBatteryChargingStatus();

		void check()
		{
			// No battery?
			if (!scePowerIsBatteryExist())
			{
				// Don't report anything.
				return;
			}

			if (show_bat.value)
		        return;

			// Get the new battery status.
			const int	level		= scePowerGetBatteryLifePercent();
			const bool	charging	= scePowerGetBatteryChargingStatus();

			// Is the level not sensible?
			if ((level < 0) || (level > 100))
			{
				// Hopefully it will be sensible soon.
				return;
			}

			// Has the battery status changed?
			if ((level != lastLevel) || (charging != lastCharging))
			{
				// Charging?
				if (charging)
				{
					// Inform the player.
					Con_Printf("Battery %d%% (charging)\n",
						level);
				}
				else
				{
					// How much time is left?
					const int	timeLeft	= scePowerGetBatteryLifeTime();

					// Is the time sensible?
					if (timeLeft > 0)
					{
						// Convert the time to something readable.
						const int	hoursLeft	= timeLeft / 60;
						const int	minutesLeft	= timeLeft % 60;

						// Inform the player.
						Con_Printf("Battery %d%% (%d hour%s %d minute%s)\n",
							level,
							hoursLeft,
							(hoursLeft == 1) ? "" : "s",	// Handle pluralisation of hour(s).
							minutesLeft,
							(minutesLeft == 1) ? "" : "s");	// Handle pluralisation of minute(s).
					}
					else
					{
						// It's a silly time, just report the battery level.
						Con_Printf("Battery %d%%\n",
							level);
					}
				}

				// Remember the status for next frame.
				lastLevel		= level;
				lastCharging	= charging;
			}
		}
	}
}
