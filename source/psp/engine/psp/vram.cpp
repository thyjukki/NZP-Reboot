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

#define VRAM_DEBUGGING 0

#include "vram.hpp"

#include <vector>
#include <pspge.h>

extern "C"
{
#include "../quakedef.h"
}

namespace quake
{
	namespace vram
	{
		typedef std::vector<unsigned short>	allocated_list;

		static char* const			base			= static_cast<char*>(sceGeEdramGetAddr());
		static const std::size_t	block_size		= 32 * 32;
		static const std::size_t	block_count		= sceGeEdramGetSize() / block_size;
		static allocated_list		allocated(block_count, 0);
		static std::size_t			bytes_required	= 0;
		static std::size_t			bytes_allocated	= 0;

		void* allocate(std::size_t size)
		{
			// How many blocks to allocate?
			bytes_required += size;
			std::size_t blocks_required = (size + block_size - 1) / block_size;

#if VRAM_DEBUGGING
			Con_Printf("vram::allocate %u bytes (%u blocks)\n", size, blocks_required);
			Con_Printf("\tblock_size = %u\n", block_size);
			Con_Printf("\tblock_count = %u\n", block_count);
#endif

			// Find a sequential area this big.
			for (std::size_t start = 0; start < (block_count - blocks_required);)
			{
				// Is this block allocated?
				const std::size_t allocated_blocks = allocated.at(start);
				if (allocated_blocks)
				{
					// Skip the allocated block.
					start += allocated_blocks;

#if VRAM_DEBUGGING
					//Con_Printf("\tskipping from block %u to %u\n", start - allocated_blocks, start);
#endif
				}
				else
				{
					// Where would the allocated block end?
					const std::size_t	end	= start + blocks_required;

#if VRAM_DEBUGGING
					//Con_Printf("\ttrying blocks %u to %u\n", start, end - 1);
#endif

					// Check for allocated blocks in the area we want.
					std::size_t free_blocks_here	= 1;
					for (std::size_t b = start + 1; b < end; ++b)
					{
						if (allocated.at(b))
						{
							break;
						}
						else
						{
							++free_blocks_here;
						}
					}

					// Is the block big enough?
					if (free_blocks_here >= blocks_required)
					{
						// Mark it as allocated.
#if VRAM_DEBUGGING
						Con_Printf("\tmarking blocks %u to %u as allocated\n", start, end - 1);
#endif
						bytes_allocated += (blocks_required * block_size);
						for (std::size_t b = start; b < end; ++b)
						{
							allocated.at(b) = blocks_required--;
						}

						// Done.
#if VRAM_DEBUGGING
						Con_Printf("\tdone (%u allocated, %u required)\n", bytes_allocated, bytes_required);
#endif
						return base + (block_size * start);
					}
					else
					{
						// Move on.
						start += free_blocks_here;
#if VRAM_DEBUGGING
						Con_Printf("\tskipping from block %u to %u, because there wasn't a big enough run of free blocks\n",
							start - free_blocks_here, start);
#endif
					}
				}
			}

			// Failed.
#if VRAM_DEBUGGING
			Con_Printf("\tfailed, no free blocks big enough (%u allocated, %u required)\n",
				bytes_allocated, bytes_required);
#endif
			return 0;
		}

		void free(void* memory)
		{
			// Which block is this?
			const std::size_t	relative_address	= static_cast<char*>(memory) - base;
			const std::size_t	block_index			= relative_address / block_size;

#if VRAM_DEBUGGING
			Con_Printf("vram::free freeing blocks starting with %u\n", block_index);
#endif

			// Mark the blocks as deallocated.
			const std::size_t blocks_to_free	= allocated.at(block_index);
#if VRAM_DEBUGGING
			Con_Printf("\tfreeing to %u\n", block_index + blocks_to_free - 1);
#endif
			for (std::size_t block = 0; block < blocks_to_free; ++block)
			{
				allocated.at(block_index + block) = 0;
			}

			const std::size_t bytes_to_free	= blocks_to_free * block_size;
			bytes_allocated -= bytes_to_free;
			bytes_required -= bytes_to_free;
#if VRAM_DEBUGGING
			Con_Printf("\tnow %u allocated, %u required\n", bytes_allocated, bytes_required);
#endif
		}
	}
}
