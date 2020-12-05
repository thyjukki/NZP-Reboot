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

#include "math.hpp"

namespace quake
{
	namespace math
	{
		void multiply(const ScePspFMatrix4& a, const ScePspFMatrix4& b, ScePspFMatrix4* out)
		{
			out->x.x = a.x.x * b.x.x + a.x.y * b.y.x + a.x.z * b.z.x + a.x.w * b.w.x;
			out->x.y = a.x.x * b.x.y + a.x.y * b.y.y + a.x.z * b.z.y + a.x.w * b.w.y;
			out->x.z = a.x.x * b.x.z + a.x.y * b.y.z + a.x.z * b.z.z + a.x.w * b.w.z;
			out->x.w = a.x.x * b.x.w + a.x.y * b.y.w + a.x.z * b.z.w + a.x.w * b.w.w;

			out->y.x = a.y.x * b.x.x + a.y.y * b.y.x + a.y.z * b.z.x + a.y.w * b.w.x;
			out->y.y = a.y.x * b.x.y + a.y.y * b.y.y + a.y.z * b.z.y + a.y.w * b.w.y;
			out->y.z = a.y.x * b.x.z + a.y.y * b.y.z + a.y.z * b.z.z + a.y.w * b.w.z;
			out->y.w = a.y.x * b.x.w + a.y.y * b.y.w + a.y.z * b.z.w + a.y.w * b.w.w;

			out->z.x = a.z.x * b.x.x + a.z.y * b.y.x + a.z.z * b.z.x + a.z.w * b.w.x;
			out->z.y = a.z.x * b.x.y + a.z.y * b.y.y + a.z.z * b.z.y + a.z.w * b.w.y;
			out->z.z = a.z.x * b.x.z + a.z.y * b.y.z + a.z.z * b.z.z + a.z.w * b.w.z;
			out->z.w = a.z.x * b.x.w + a.z.y * b.y.w + a.z.z * b.z.w + a.z.w * b.w.w;

			out->w.x = a.w.x * b.x.x + a.w.y * b.y.x + a.w.z * b.z.x + a.w.w * b.w.x;
			out->w.y = a.w.x * b.x.y + a.w.y * b.y.y + a.w.z * b.z.y + a.w.w * b.w.y;
			out->w.z = a.w.x * b.x.z + a.w.y * b.y.z + a.w.z * b.z.z + a.w.w * b.w.z;
			out->w.w = a.w.x * b.x.w + a.w.y * b.y.w + a.w.z * b.z.w + a.w.w * b.w.w;
		}
	}
}
