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

#include "network_psp.hpp"

extern "C"
{
#include "../net_dgrm.h"
#include "../net_loop.h"
}

net_driver_t net_drivers[MAX_NET_DRIVERS] =
{
	{
		"Loopback",
			qfalse,
			Loop_Init,
			Loop_Listen,
			Loop_SearchForHosts,
			Loop_Connect,
			Loop_CheckNewConnections,
			Loop_GetMessage,
			Loop_SendMessage,
			Loop_SendUnreliableMessage,
			Loop_CanSendMessage,
			Loop_CanSendUnreliableMessage,
			Loop_Close,
			Loop_Shutdown
	}
	,
	{
		"Datagram",
			qfalse,
			Datagram_Init,
			Datagram_Listen,
			Datagram_SearchForHosts,
			Datagram_Connect,
			Datagram_CheckNewConnections,
			Datagram_GetMessage,
			Datagram_SendMessage,
			Datagram_SendUnreliableMessage,
			Datagram_CanSendMessage,
			Datagram_CanSendUnreliableMessage,
			Datagram_Close,
			Datagram_Shutdown
	}
};

int net_numdrivers = 2;

using namespace quake;
using namespace quake::network;

net_landriver_t	net_landrivers[MAX_NET_DRIVERS] =
{
	{
		"Infrastructure",
		qfalse,
		0,
		infrastructure::init,
		infrastructure::shut_down,
		infrastructure::listen,
		infrastructure::open_socket,
		infrastructure::close_socket,
		infrastructure::connect,
		infrastructure::check_new_connections,
		infrastructure::read,
		infrastructure::write,
		infrastructure::broadcast,
		infrastructure::addr_to_string,
		infrastructure::string_to_addr,
		infrastructure::get_socket_addr,
		infrastructure::get_name_from_addr,
		infrastructure::get_addr_from_name,
		infrastructure::addr_compare,
		infrastructure::get_socket_port,
		infrastructure::set_socket_port
	},
	{
		"Adhoc",
		qfalse,
		0,
		adhoc::init,
		adhoc::shut_down,
		adhoc::listen,
		adhoc::open_socket,
		adhoc::close_socket,
		adhoc::connect,
		adhoc::check_new_connections,
		adhoc::read,
		adhoc::write,
		adhoc::broadcast,
		adhoc::addr_to_string,
		adhoc::string_to_addr,
		adhoc::get_socket_addr,
		adhoc::get_name_from_addr,
		adhoc::get_addr_from_name,
		adhoc::addr_compare,
		adhoc::get_socket_port,
		adhoc::set_socket_port
	}
};

int net_numlandrivers = 2;
