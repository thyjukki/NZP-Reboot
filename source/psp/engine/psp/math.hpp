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

#ifndef QUAKE_MATH_HPP
#define QUAKE_MATH_HPP

#include <math.h>
#include <psptypes.h>

#ifdef PSP_VFPU
#include <pspmath.h>
#endif

namespace quake
{
	namespace math
	{
		static inline float dot(const ScePspFVector4& a, const ScePspFVector4& b)
		{
			return (a.x * b.x) + (a.y * b.y) + (a.z * b.z);
		}

		static inline void normalise(ScePspFVector4* v)
		{
			const float scale = 1.0f / sqrtf(dot(*v, *v));

			v->x *= scale;
			v->y *= scale;
			v->z *= scale;
			v->w *= scale;
		}

		void multiply(const ScePspFMatrix4& a, const ScePspFMatrix4& b, ScePspFMatrix4* out);
	}
}

#endif
