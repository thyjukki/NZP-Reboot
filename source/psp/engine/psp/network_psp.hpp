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

#ifndef QUAKE_NETWORK_PSP_HPP
#define QUAKE_NETWORK_PSP_HPP

extern "C"
{
#include "../quakedef.h"
}

namespace quake
{
	namespace network
	{
		namespace infrastructure
		{
			int  init (void);
			void shut_down (void);
			void listen (qboolean state);
			int  open_socket (int port);
			int  close_socket (int socket);
			int  connect (int socket, struct qsockaddr *addr);
			int  check_new_connections (void);
			int  read (int socket, byte *buf, int len, struct qsockaddr *addr);
			int  write (int socket, byte *buf, int len, struct qsockaddr *addr);
			int  broadcast (int socket, byte *buf, int len);
			char* addr_to_string (struct qsockaddr *addr);
			int  string_to_addr (char *string, struct qsockaddr *addr);
			int  get_socket_addr (int socket, struct qsockaddr *addr);
			int  get_name_from_addr (struct qsockaddr *addr, char *name);
			int  get_addr_from_name (char *name, struct qsockaddr *addr);
			int  addr_compare (struct qsockaddr *addr1, struct qsockaddr *addr2);
			int  get_socket_port (struct qsockaddr *addr);
			int  set_socket_port (struct qsockaddr *addr, int port);

			int connect_to_apctl(int config);
			int PartialIPAddress (char *in, struct qsockaddr *hostaddr);
		}
		namespace adhoc
		{
			int  init (void);
			void shut_down (void);
			void listen (qboolean state);
			int  open_socket (int port);
			int  close_socket (int socket);
			int  connect (int socket, struct qsockaddr *addr);
			int  check_new_connections (void);
			int  read (int socket, byte *buf, int len, struct qsockaddr *addr);
			int  write (int socket, byte *buf, int len, struct qsockaddr *addr);
			int  broadcast (int socket, byte *buf, int len);
			char* addr_to_string (struct qsockaddr *addr);
			int  string_to_addr (char *string, struct qsockaddr *addr);
			int  get_socket_addr (int socket, struct qsockaddr *addr);
			int  get_name_from_addr (struct qsockaddr *addr, char *name);
			int  get_addr_from_name (char *name, struct qsockaddr *addr);
			int  addr_compare (struct qsockaddr *addr1, struct qsockaddr *addr2);
			int  get_socket_port (struct qsockaddr *addr);
			int  set_socket_port (struct qsockaddr *addr, int port);
			int pspSdkAdhocInit(char *product);
			void pspSdkAdhocTerm();
		}
	}
}

#endif
