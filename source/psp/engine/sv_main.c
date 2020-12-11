/*
Copyright (C) 1996-1997 Id Software, Inc.

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
// sv_main.c -- server main program

#include "quakedef.h"

server_t		sv;
server_static_t	svs;

char	localmodels[MAX_MODELS][5];			// inline model names for precache

//============================================================================
cvar_t	r_hlbsponly = {"r_hlbsponly","0",true};

/*
===============
SV_Init
===============
*/
void SV_Init (void)
{
	int		i;
	extern	cvar_t	sv_maxvelocity;
	extern	cvar_t	sv_gravity;
	extern	cvar_t	sv_nostep;
	extern	cvar_t	sv_friction;
	extern	cvar_t	sv_edgefriction;
	extern	cvar_t	sv_stopspeed;
	extern	cvar_t	sv_maxspeed;
	extern	cvar_t	sv_accelerate;
	extern	cvar_t	sv_idealpitchscale;
	extern	cvar_t	sv_aim;

	Cvar_RegisterVariable (&sv_maxvelocity);
	Cvar_RegisterVariable (&sv_gravity);
	Cvar_RegisterVariable (&sv_friction);
	Cvar_RegisterVariable (&sv_edgefriction);
	Cvar_RegisterVariable (&sv_stopspeed);
	Cvar_RegisterVariable (&sv_maxspeed);
	Cvar_RegisterVariable (&sv_accelerate);
	Cvar_RegisterVariable (&sv_idealpitchscale);
	Cvar_RegisterVariable (&sv_aim);
	Cvar_RegisterVariable (&sv_nostep);

	for (i=0 ; i<MAX_MODELS ; i++)
		sprintf (localmodels[i], "*%i", i);
}

/*
=============================================================================

EVENT MESSAGES

=============================================================================
*/

/*
==================
SV_StartParticle

Make sure the event gets sent to all clients
==================
*/
void SV_StartParticle (vec3_t org, vec3_t dir, int color, int count)
{
	int		i, v;

	if (sv.datagram.cursize > MAX_DATAGRAM-16)
		return;
	MSG_WriteByte (&sv.datagram, svc_particle);
	MSG_WriteCoord (&sv.datagram, org[0]);
	MSG_WriteCoord (&sv.datagram, org[1]);
	MSG_WriteCoord (&sv.datagram, org[2]);
	for (i=0 ; i<3 ; i++)
	{
		v = dir[i]*16;
		if (v > 127)
			v = 127;
		else if (v < -128)
			v = -128;
		MSG_WriteChar (&sv.datagram, v);
	}
	MSG_WriteByte (&sv.datagram, count);
	MSG_WriteByte (&sv.datagram, color);
}

/*
==================
SV_StartSound

Each entity can have eight independant sound sources, like voice,
weapon, feet, etc.

Channel 0 is an auto-allocate channel, the others override anything
allready running on that entity/channel pair.

An attenuation of 0 will play full volume everywhere in the level.
Larger attenuations will drop off.  (max 4 attenuation)

==================
*/
void SV_StartSound (edict_t *entity, int channel, char *sample, int volume,
    float attenuation)
{
    int         sound_num;
    int field_mask;
    int			i;
	int			ent;

	if (volume < 0 || volume > 255)
		Sys_Error ("SV_StartSound: volume = %i", volume);

	if (attenuation < 0 || attenuation > 4)
		Sys_Error ("SV_StartSound: attenuation = %f", attenuation);

	if (channel < 0 || channel > 7)
		Sys_Error ("SV_StartSound: channel = %i", channel);

	if (sv.datagram.cursize > MAX_DATAGRAM-16)
		return;

// find precache number for sound
    for (sound_num=1 ; sound_num<MAX_SOUNDS
        && sv.sound_precache[sound_num] ; sound_num++)
        if (!strcmp(sample, sv.sound_precache[sound_num]))
            break;

    if ( sound_num == MAX_SOUNDS || !sv.sound_precache[sound_num] )
    {
        Con_Printf ("SV_StartSound: %s not precacheed\n", sample);
        return;
    }

	ent = NUM_FOR_EDICT(entity);

	channel = (ent<<3) | channel;

	field_mask = 0;
	if (volume != DEFAULT_SOUND_PACKET_VOLUME)
		field_mask |= SND_VOLUME;
	if (attenuation != DEFAULT_SOUND_PACKET_ATTENUATION)
		field_mask |= SND_ATTENUATION;

// directed messages go only to the entity the are targeted on
	MSG_WriteByte (&sv.datagram, svc_sound);
	MSG_WriteByte (&sv.datagram, field_mask);
	if (field_mask & SND_VOLUME)
		MSG_WriteByte (&sv.datagram, volume);
	if (field_mask & SND_ATTENUATION)
		MSG_WriteByte (&sv.datagram, attenuation*64);
	MSG_WriteShort (&sv.datagram, channel);
	MSG_WriteByte (&sv.datagram, sound_num);
	for (i=0 ; i<3 ; i++)
		MSG_WriteCoord (&sv.datagram, entity->v.origin[i]+0.5*(entity->v.mins[i]+entity->v.maxs[i]));
}

/*
==============================================================================

CLIENT SPAWNING

==============================================================================
*/

/*
================
SV_SendServerinfo

Sends the first message from the server to a connected client.
This will be sent on the initial connection and upon each server load.
================
*/
void SV_SendServerinfo (client_t *client)
{
	char			**s;
	char			message[2048];

	MSG_WriteByte (&client->message, svc_print);
	sprintf (message, "%c\nVERSION %4.2f SERVER (%i CRC)", 2, VERSION, pr_crc);
	MSG_WriteString (&client->message,message);

	MSG_WriteByte (&client->message, svc_serverinfo);
	MSG_WriteLong (&client->message, PROTOCOL_VERSION);
	MSG_WriteByte (&client->message, svs.maxclients);

	if (!coop.value && deathmatch.value)
		MSG_WriteByte (&client->message, GAME_DEATHMATCH);
	else
		MSG_WriteByte (&client->message, GAME_COOP);

	sprintf (message, pr_strings+sv.edicts->v.message);

	MSG_WriteString (&client->message,message);

	for (s = sv.model_precache+1 ; *s ; s++)
		MSG_WriteString (&client->message, *s);
	MSG_WriteByte (&client->message, 0);

	for (s = sv.sound_precache+1 ; *s ; s++)
		MSG_WriteString (&client->message, *s);
	MSG_WriteByte (&client->message, 0);

// send music
	MSG_WriteByte (&client->message, svc_cdtrack);
	MSG_WriteByte (&client->message, sv.edicts->v.sounds);
	MSG_WriteByte (&client->message, sv.edicts->v.sounds);

// set view
	MSG_WriteByte (&client->message, svc_setview);
	MSG_WriteShort (&client->message, NUM_FOR_EDICT(client->edict));

	MSG_WriteByte (&client->message, svc_signonnum);
	MSG_WriteByte (&client->message, 1);

	client->sendsignon = true;
	client->spawned = false;		// need prespawn, spawn, etc
}

/*
================
SV_ConnectClient

Initializes a client_t for a new net connection.  This will only be called
once for a player each game, not once for each level change.
================
*/
void SV_ConnectClient (int clientnum)
{
	edict_t			*ent;
	client_t		*client;
	int				edictnum;
	struct qsocket_s *netconnection;
	int				i;
	float			spawn_parms[NUM_SPAWN_PARMS];

	client = svs.clients + clientnum;

	//Con_DPrintf ("Client %s connected\n", client->netconnection->address);
	Con_Printf ("Client %s connected\n", client->netconnection->address);

	edictnum = clientnum+1;

	ent = EDICT_NUM(edictnum);

// set up the client_t
	netconnection = client->netconnection;

	if (sv.loadgame)
		memcpy (spawn_parms, client->spawn_parms, sizeof(spawn_parms));
	memset (client, 0, sizeof(*client));
	client->netconnection = netconnection;

	strcpy (client->name, "unconnected");
	client->active = true;
	client->spawned = false;
	client->edict = ent;
	client->message.data = client->msgbuf;
	client->message.maxsize = sizeof(client->msgbuf);
	client->message.allowoverflow = true;		// we can catch it

	client->privileged = false;

	if (sv.loadgame)
		memcpy (client->spawn_parms, spawn_parms, sizeof(spawn_parms));
	else
	{
	// call the progs to get default spawn parms for the new client
		PR_ExecuteProgram (pr_global_struct->SetNewParms);
		for (i=0 ; i<NUM_SPAWN_PARMS ; i++)
			client->spawn_parms[i] = (&pr_global_struct->parm1)[i];
	}

	SV_SendServerinfo (client);
}


/*
===================
SV_CheckForNewClients

===================
*/
void SV_CheckForNewClients (void)
{
	struct qsocket_s	*ret;
	int				i;

//
// check for new connections
//
	while (1)
	{
		ret = NET_CheckNewConnections ();
		if (!ret)
			break;

	//
	// init a new client structure
	//
		for (i=0 ; i<svs.maxclients ; i++)
			if (!svs.clients[i].active)
				break;
		if (i == svs.maxclients)
			Sys_Error ("Host_CheckForNewClients: no free clients");

		svs.clients[i].netconnection = ret;
		SV_ConnectClient (i);

		net_activeconnections++;
	}
}



/*
===============================================================================

FRAME UPDATES

===============================================================================
*/

/*
==================
SV_ClearDatagram

==================
*/
void SV_ClearDatagram (void)
{
	SZ_Clear (&sv.datagram);
}

/*
=============================================================================

The PVS must include a small area around the client to allow head bobbing
or other small motion on the client side.  Otherwise, a bob might cause an
entity that should be visible to not show up, especially when the bob
crosses a waterline.

=============================================================================
*/

int		fatbytes;
byte	fatpvs[MAX_MAP_LEAFS/8];

void SV_AddToFatPVS (vec3_t org, mnode_t *node)
{
	int		i;
	byte	*pvs;
	mplane_t	*plane;
	float	d;

	while (1)
	{
	// if this is a leaf, accumulate the pvs bits
		if (node->contents < 0)
		{
			if (node->contents != CONTENTS_SOLID)
			{
				pvs = Mod_LeafPVS ( (mleaf_t *)node, sv.worldmodel);
				for (i=0 ; i<fatbytes ; i++)
					fatpvs[i] |= pvs[i];
			}
			return;
		}

		plane = node->plane;
		d = DotProduct (org, plane->normal) - plane->dist;
		if (d > 8)
			node = node->children[0];
		else if (d < -8)
			node = node->children[1];
		else
		{	// go down both
			SV_AddToFatPVS (org, node->children[0]);
			node = node->children[1];
		}
	}
}

/*
=============
SV_FatPVS

Calculates a PVS that is the inclusive or of all leafs within 8 pixels of the
given point.
=============
*/
byte *SV_FatPVS (vec3_t org)
{
	fatbytes = (sv.worldmodel->numleafs+31)>>3;
	Q_memset (fatpvs, 0, fatbytes);
	SV_AddToFatPVS (org, sv.worldmodel->nodes);
	return fatpvs;
}

//=============================================================================


/*
=============
SV_WriteEntitiesToClient

=============
*/
void SV_WriteEntitiesToClient (edict_t	*clent, sizebuf_t *msg, qboolean nomap)
{
	int		e, i;
	int		bits;
	byte	*pvs;
	vec3_t	org;
	float	miss;
	edict_t	*ent;

	// Tomaz - QC Alpha Scale Glow Begin
		eval_t  *val;
		float	renderamt  = 0;
		float	rendermode = 0;

		float	rendercolor[3];
		memset(rendercolor, 0, sizeof(rendercolor));
	// Tomaz - QC Alpha Scale Glow End

	// find the client's PVS
	VectorAdd (clent->v.origin, clent->v.view_ofs, org);
	pvs = SV_FatPVS (org);

// send over all entities (excpet the client) that touch the pvs
	ent = NEXT_EDICT(sv.edicts);
	for (e=1 ; e<sv.num_edicts ; e++, ent = NEXT_EDICT(ent))
	{
		// don't send if flagged for NODRAW and there are no lighting effects
		if (ent->v.effects == EF_NODRAW)
			continue;

// ignore if not touching a PV leaf
		if (ent != clent)	// clent is ALLWAYS sent
		{
// ignore ents without visible models
			if (!ent->v.modelindex || !pr_strings[ent->v.model])
				continue;

			for (i=0 ; i < ent->num_leafs ; i++)
			{
				if (pvs[ent->leafnums[i] >> 3] & (1 << (ent->leafnums[i]&7) ))
					break;
			}
			if (i == ent->num_leafs)
				continue;		// not visible
            // joe, from ProQuake: don't send updates if the client doesn't have the map
			if (nomap)
				continue;
		}
		if (msg->maxsize - msg->cursize < 16)
		{
			Con_Printf ("SV_WriteEntitiesToClient: packet overflow->big_value\n");
			return;
		}
// send an update
		bits = 0;

		for (i=0 ; i<3 ; i++)
		{
			miss = ent->v.origin[i] - ent->baseline.origin[i];
			if ( miss < -0.1 || miss > 0.1 )
				bits |= U_ORIGIN1<<i;
		}

		if ( ent->v.angles[0] != ent->baseline.angles[0] )
			bits |= U_ANGLE1;

		if ( ent->v.angles[1] != ent->baseline.angles[1] )
			bits |= U_ANGLE2;

		if ( ent->v.angles[2] != ent->baseline.angles[2] )
			bits |= U_ANGLE3;

		//if (ent->v.movetype == MOVETYPE_STEP) JUkki removed to test interploation
		//	bits |= U_NOLERP;	// don't mess up the step animation

		if (ent->baseline.colormap != ent->v.colormap)
			bits |= U_COLORMAP;

		if (ent->baseline.skin != ent->v.skin)
			bits |= U_SKIN;

		if (ent->v.iframetime != 0.1)
			bits |= U_FRAMETIME;

		if (ent->baseline.frame != ent->v.frame)
			bits |= U_FRAME;

		if (ent->baseline.effects != ent->v.effects)
			bits |= U_EFFECTS;

		if (ent->baseline.modelindex != ent->v.modelindex)
			bits |= U_MODEL;
        // Tomaz - QC Alpha Scale Glow Begin

	{
		//Smal Size
		if ((val = GETEDICTFIELDVALUE(ent, eval_renderamt)) && val->_float != 255.0) // HalfLife support
			 renderamt = val->_float / 255.0f;

		if ((val = GETEDICTFIELDVALUE(ent, eval_rendermode)) && val->_float != 0) // HalfLife support
			rendermode = val->_float;

		if ((val = GETEDICTFIELDVALUE(ent, eval_rendercolor))) // HalfLife support
		{
			rendercolor[0] = val->vector[0] / 255.0f;
			rendercolor[1] = val->vector[1] / 255.0f;
			rendercolor[2] = val->vector[2] / 255.0f;
		}

		if (renderamt > 0)
			bits |= U_RENDERAMT;

		if (rendermode > 0)
			bits |= U_RENDERMODE;

		if (rendercolor[0] > 0)
		{
			bits |= U_RENDERCOLOR1;
		}

		if (rendercolor[1] > 0 )
		{
			bits |= U_RENDERCOLOR2;
		}

		if (rendercolor[2] > 0 )
		{
			bits |= U_RENDERCOLOR3;
		}
	}

	// Tomaz - QC Alpha Scale Glow End
		if (e >= 256)//We have more than 256 entities
			bits |= U_LONGENTITY;

		if (bits >= 256)//this is we've exceded some old 8-bit message
			bits |= U_MOREBITS;

		// Tomaz - QC Control Begin
		if (bits >= 65536)//this is if we've excited the original 16-bit message
			bits |= U_EXTEND1;
		if (bits >= 16777216)
			bits |= U_EXTEND2;
		// Tomaz - QC Control End

	//
	// write the message
	//
		MSG_WriteByte (msg,bits | U_SIGNAL);

		if (bits & U_MOREBITS)
			MSG_WriteByte (msg, bits>>8);

		 // Tomaz - QC Control Begin
		if (bits & U_EXTEND1)
			MSG_WriteByte (msg, bits>>16);
		if (bits & U_EXTEND2)
			MSG_WriteByte (msg, bits>>24);
		 // Tomaz - QC Control End

		if (bits & U_LONGENTITY)
			MSG_WriteShort (msg,e);
		else
			MSG_WriteByte (msg,e);

		if (bits & U_MODEL)
			MSG_WriteByte (msg,	ent->v.modelindex);
		if (bits & U_FRAME)
			MSG_WriteShort (msg, ent->v.frame);
		if (bits & U_COLORMAP)
			MSG_WriteByte (msg, ent->v.colormap);
		if (bits & U_SKIN)
			MSG_WriteByte (msg, ent->v.skin);
		if (bits & U_FRAMETIME)
			MSG_WriteFloat (msg, ent->v.iframetime);
		if (bits & U_EFFECTS)
			MSG_WriteShort (msg, ent->v.effects);
		if (bits & U_ORIGIN1)
			MSG_WriteCoord (msg, ent->v.origin[0]);
		if (bits & U_ANGLE1)
			MSG_WriteAngle(msg, ent->v.angles[0]);
		if (bits & U_ORIGIN2)
			MSG_WriteCoord (msg, ent->v.origin[1]);
		if (bits & U_ANGLE2)
			MSG_WriteAngle(msg, ent->v.angles[1]);
		if (bits & U_ORIGIN3)
			MSG_WriteCoord (msg, ent->v.origin[2]);
		if (bits & U_ANGLE3)
			MSG_WriteAngle(msg, ent->v.angles[2]);
		// Tomaz - QC Alpha Scale Glow Begin
		if (bits & U_RENDERAMT)
			MSG_WriteFloat(msg, renderamt);

		if (bits & U_RENDERMODE)
			MSG_WriteFloat(msg, rendermode);

		if (bits & U_RENDERCOLOR1)
			MSG_WriteFloat(msg, rendercolor[0]);

		if (bits & U_RENDERCOLOR2)
			MSG_WriteFloat(msg, rendercolor[1]);

		if (bits & U_RENDERCOLOR3)
			MSG_WriteFloat(msg, rendercolor[2]);
		// Tomaz - QC Alpha Scale Glow End
 	}
}

/*
=============
SV_CleanupEnts

=============
*/
void SV_CleanupEnts (void)
{
	int		e;
	edict_t	*ent;

	ent = NEXT_EDICT(sv.edicts);
	for (e=1 ; e<sv.num_edicts ; e++, ent = NEXT_EDICT(ent))
	{
		ent->v.effects = (int)ent->v.effects & ~EF_MUZZLEFLASH;
	}

}

/*
==================
SV_WriteClientdataToMessage

==================
*/
void SV_WriteClientdataToMessage (edict_t *ent, sizebuf_t *msg)
{
	int		bits;
	int		i;

//
// send the current viewpos offset from the view entity
//
	SV_SetIdealPitch ();		// how much to look up / down ideally

// a fixangle might get lost in a dropped packet.  Oh well.
	if ( ent->v.fixangle )
	{
		MSG_WriteByte (msg, svc_setangle);
		for (i=0 ; i < 3 ; i++)
			MSG_WriteAngle (msg, ent->v.angles[i] );
		ent->v.fixangle = 0;
	}

	bits = 0;

	if (ent->v.view_ofs[2] != DEFAULT_VIEWHEIGHT)
		bits |= SU_VIEWHEIGHT;

	if (ent->v.idealpitch)
		bits |= SU_IDEALPITCH;

	if (ent->v.perks)
		bits |= SU_PERKS;

	if ( (int)ent->v.flags & FL_ONGROUND)
		bits |= SU_ONGROUND;

	if ( ent->v.waterlevel >= 2)
		bits |= SU_INWATER;

	for (i=0 ; i<3 ; i++)
	{
		if (ent->v.punchangle[i])
			bits |= (SU_PUNCH1<<i);
		if (ent->v.velocity[i])
			bits |= (SU_VELOCITY1<<i);
	}

	if (ent->v.weaponframe)
		bits |= SU_WEAPONFRAME;

	if (ent->v.weaponskin)
		bits |= SU_WEAPONSKIN;

	if (ent->v.weapon)
		bits |= SU_WEAPON;

	//if (ent->v.perks)
	//	bits |= SU_PERKS;

	if (ent->v.primary_grenades)
		bits |= SU_PRIGRENADES;

	//Think this is out of range of a short
	//if (ent->v.secondary_grenades)
	//	bits |= SU_SECGRENADES;

	if (ent->v.grenades)
		bits |= SU_GRENADES;

// send the data

	MSG_WriteByte (msg, svc_clientdata);
	MSG_WriteShort (msg, bits);

	if (bits & SU_VIEWHEIGHT)
		MSG_WriteChar (msg, ent->v.view_ofs[2]);

	if (bits & SU_IDEALPITCH)
		MSG_WriteChar (msg, ent->v.idealpitch);

	if (bits & SU_PERKS)
		MSG_WriteLong (msg, ent->v.perks);

	for (i=0 ; i<3 ; i++)
	{
		if (bits & (SU_PUNCH1<<i))
			MSG_WriteChar (msg, ent->v.punchangle[i]);
		if (bits & (SU_VELOCITY1<<i))
			MSG_WriteChar (msg, ent->v.velocity[i]/16);
	}


	if (bits & SU_WEAPONFRAME)
		MSG_WriteByte (msg, ent->v.weaponframe);
	if (bits & SU_WEAPONSKIN)
		MSG_WriteByte (msg, ent->v.weaponskin);
	if (bits & SU_WEAPON)
		MSG_WriteByte (msg, SV_ModelIndex(pr_strings+ent->v.weaponmodel));

	if (bits & SU_GRENADES)
		MSG_WriteLong (msg, ent->v.grenades);

	MSG_WriteShort (msg, ent->v.primary_grenades);
	MSG_WriteShort (msg, ent->v.secondary_grenades);
	MSG_WriteShort (msg, ent->v.health);
	MSG_WriteShort (msg, ent->v.currentammo);
	MSG_WriteByte (msg, ent->v.currentmag);
	MSG_WriteByte (msg, ent->v.zoom);

	MSG_WriteByte (msg, ent->v.weapon);
	MSG_WriteByte (msg, pr_global_struct->rounds);
	MSG_WriteByte (msg, pr_global_struct->rounds_change);
	MSG_WriteByte (msg, ent->v.x2_icon);
	MSG_WriteByte (msg, ent->v.insta_icon);
	MSG_WriteByte (msg, ent->v.progress_bar);
	MSG_WriteByte (msg, SV_ModelIndex(pr_strings+ent->v.weapon2model));
	MSG_WriteByte (msg, ent->v.weapon2skin);
	MSG_WriteByte (msg, ent->v.weapon2frame);
	MSG_WriteByte (msg, ent->v.currentmag2);
}

/*
=======================
SV_SendClientDatagram
=======================
*/
qboolean SV_SendClientDatagram (client_t *client)
{
	byte		buf[MAX_DATAGRAM];
	sizebuf_t	msg;

	msg.data = buf;
	msg.maxsize = sizeof(buf);
	msg.cursize = 0;

	MSG_WriteByte (&msg, svc_time);
	MSG_WriteFloat (&msg, sv.time);

// add the client specific data to the datagram
	SV_WriteClientdataToMessage (client->edict, &msg);//This should be good now

	SV_WriteEntitiesToClient (client->edict, &msg, client->nomap);

// copy the server datagram if there is space
	if (msg.cursize + sv.datagram.cursize < msg.maxsize)
		SZ_Write (&msg, sv.datagram.data, sv.datagram.cursize);

// send the datagram
	if (NET_SendUnreliableMessage (client->netconnection, &msg) == -1)
	{
		SV_DropClient (true);// if the message couldn't send, kick off
		return false;
	}

	return true;
}

/*
=======================
SV_UpdateToReliableMessages
=======================
*/
void SV_UpdateToReliableMessages (void)
{
	int			i, j;
	client_t *client;

// check for changes to be sent over the reliable streams
	for (i=0, host_client = svs.clients ; i<svs.maxclients ; i++, host_client++)
	{
		if (host_client->old_points != host_client->edict->v.points)
		{
			for (j=0, client = svs.clients ; j<svs.maxclients ; j++, client++)
			{
				if (!client->active)
					continue;
				MSG_WriteByte (&client->message, svc_updatepoints);
				MSG_WriteByte (&client->message, i);
				MSG_WriteLong (&client->message, host_client->edict->v.points);
			}

			host_client->old_points = host_client->edict->v.points;
		}
	}

	for (i=0, host_client = svs.clients ; i<svs.maxclients ; i++, host_client++)
	{
		if (host_client->old_kills != host_client->edict->v.kills)
		{
			for (j=0, client = svs.clients ; j<svs.maxclients ; j++, client++)
			{
				if (!client->active)
					continue;
				MSG_WriteByte (&client->message, svc_updatekills);
				MSG_WriteByte (&client->message, i);
				MSG_WriteShort (&client->message, host_client->edict->v.kills);
			}

			host_client->old_points = host_client->edict->v.points;
		}
	}

	for (j=0, client = svs.clients ; j<svs.maxclients ; j++, client++)
	{
		if (!client->active)
			continue;
		SZ_Write (&client->message, sv.reliable_datagram.data, sv.reliable_datagram.cursize);
	}

	SZ_Clear (&sv.reliable_datagram);
}


/*
=======================
SV_SendNop

Send a nop message without trashing or sending the accumulated client
message buffer
=======================
*/
void SV_SendNop (client_t *client)
{
	sizebuf_t	msg;
	byte		buf[4];

	msg.data = buf;
	msg.maxsize = sizeof(buf);
	msg.cursize = 0;

	MSG_WriteChar (&msg, svc_nop);

	if (NET_SendUnreliableMessage (client->netconnection, &msg) == -1)
		SV_DropClient (true);	// if the message couldn't send, kick off
	client->last_message = realtime;
}

/*
=======================
SV_SendClientMessages
=======================
*/
void SV_SendClientMessages (void)
{
	int			i;

// update points, names, etc
	SV_UpdateToReliableMessages ();

// build individual updates
	for (i=0, host_client = svs.clients ; i<svs.maxclients ; i++, host_client++)
	{
		if (!host_client->active)
			continue;

		if (host_client->spawned)
		{
			if (!SV_SendClientDatagram (host_client))
				continue;
		}
		else
		{
		// the player isn't totally in the game yet
		// send small keepalive messages if too much time has passed
		// send a full message when the next signon stage has been requested
		// some other message data (name changes, etc) may accumulate
		// between signon stages
			if (!host_client->sendsignon)
			{
				if (realtime - host_client->last_message > 5)
					SV_SendNop (host_client);
				continue;	// don't send out non-signon messages
			}
		}

		// check for an overflowed message.  Should only happen
		// on a very fucked up connection that backs up a lot, then
		// changes level
		if (host_client->message.overflowed)
		{
			SV_DropClient (true);
			host_client->message.overflowed = false;
			continue;
		}

		if (host_client->message.cursize || host_client->dropasap)
		{
			if (!NET_CanSendMessage (host_client->netconnection))
			{
//				I_Printf ("can't write\n");
				continue;
			}

			if (host_client->dropasap)
				SV_DropClient (false);	// went to another level
			else
			{
				if (NET_SendMessage (host_client->netconnection
				, &host_client->message) == -1)
					SV_DropClient (true);	// if the message couldn't send, kick off
				SZ_Clear (&host_client->message);
				host_client->last_message = realtime;
				host_client->sendsignon = false;
			}
		}
	}


// clear muzzle flashes
	SV_CleanupEnts ();
}


/*
==============================================================================

SERVER SPAWNING

==============================================================================
*/

/*
================
SV_ModelIndex

================
*/
int SV_ModelIndex (char *name)
{
	int		i;

	if (!name || !name[0])
		return 0;

	for (i=0 ; i<MAX_MODELS ; i++)
	{
		if (!sv.model_precache[i])
		{
			Con_Printf ("Model (%s) was not precached, precaching\n", name);
			sv.model_precache[i] = name;
			sv.models[i] = Mod_ForName (name, true);
			return i;
		}
		if (!strcmp(sv.model_precache[i], name))
			return i;
	}

	Sys_Error ("SV_ModelIndex: model %s not precached", name);
	return -1;
}

/*
================
SV_CreateBaseline

================
*/
void SV_CreateBaseline (void)
{
	int			i;
	edict_t			*svent;
	int				entnum;

	for (entnum = 0; entnum < sv.num_edicts ; entnum++)
	{
	// get the current server version
		svent = EDICT_NUM(entnum);
		if (svent->free)
			continue;
		if (entnum > svs.maxclients && !svent->v.modelindex)
			continue;

	//
	// create entity baseline
	//
		VectorCopy (svent->v.origin, svent->baseline.origin);
		VectorCopy (svent->v.angles, svent->baseline.angles);
		svent->baseline.frame = svent->v.frame;
		svent->baseline.skin = svent->v.skin;
		if (entnum > 0 && entnum <= svs.maxclients)
		{
			svent->baseline.colormap = entnum;
			svent->baseline.modelindex = SV_ModelIndex("models/player.mdl");
		}
		else
		{
			svent->baseline.colormap = 0;
			svent->baseline.modelindex =
				SV_ModelIndex(pr_strings + svent->v.model);
		}

	//
	// add to the message
	//
		MSG_WriteByte (&sv.signon,svc_spawnbaseline);
		MSG_WriteShort (&sv.signon,entnum);

		MSG_WriteByte (&sv.signon, svent->baseline.modelindex);
		MSG_WriteByte (&sv.signon, svent->baseline.frame);
		MSG_WriteByte (&sv.signon, svent->baseline.colormap);
		MSG_WriteByte (&sv.signon, svent->baseline.skin);
		for (i=0 ; i<3 ; i++)
		{
			MSG_WriteCoord(&sv.signon, svent->baseline.origin[i]);
			MSG_WriteAngle(&sv.signon, svent->baseline.angles[i]);
		}
	}
}


/*
================
SV_SendReconnect

Tell all the clients that the server is changing levels
================
*/
void SV_SendReconnect (void)
{
	char	data[128];
	sizebuf_t	msg;

	msg.data = (byte*)data;
	msg.cursize = 0;
	msg.maxsize = sizeof(data);

	MSG_WriteChar (&msg, svc_stufftext);
	MSG_WriteString (&msg, "reconnect\n");
	NET_SendToAll (&msg, 5);

	if (cls.state != ca_dedicated)
        Cmd_ExecuteString ("reconnect\n", src_command);
}


/*
================
SV_SaveSpawnparms

Grabs the current state of each client for saving across the
transition to another level
================
*/
void SV_SaveSpawnparms (void)
{
	int		i, j;

	svs.serverflags = pr_global_struct->serverflags;

	for (i=0, host_client = svs.clients ; i<svs.maxclients ; i++, host_client++)
	{
		if (!host_client->active)
			continue;

	// call the progs to get default spawn parms for the new client
		pr_global_struct->self = EDICT_TO_PROG(host_client->edict);
		PR_ExecuteProgram (pr_global_struct->SetChangeParms);
		for (j=0 ; j<NUM_SPAWN_PARMS ; j++)
			host_client->spawn_parms[j] = (&pr_global_struct->parm1)[j];
	}
}


/*
================
SV_SpawnServer

This is called at the start of each level
================
*/
extern float		scr_centertime_off;
void Load_Waypoint ();

void SV_SpawnServer (char *server)
{
	edict_t		*ent;
	int			i;

	// let's not have any servers with no name
	if (hostname.string[0] == 0)
		Cvar_Set ("hostname", "UNNAMED");
	scr_centertime_off = 0;

	Con_DPrintf ("SpawnServer: %s\n",server);
	svs.changelevel_issued = false;		// now safe to issue another

//
// tell all connected clients that we are going to a new level
//
	if (sv.active)
	{
		SV_SendReconnect ();
	}

//
// make cvars consistant
//
	if (coop.value)
		Cvar_SetValue ("deathmatch", 0);
	current_skill = (int)(skill.value + 0.5);
	if (current_skill < 0)
		current_skill = 0;
	if (current_skill > 3)
		current_skill = 3;

	Cvar_SetValue ("skill", (float)current_skill);

//
// set up the new server
//
	Host_ClearMemory ();

	memset (&sv, 0, sizeof(sv));

	strcpy (sv.name, server);

// load progs to get entity field count
	PR_LoadProgs ();

// allocate server memory
	sv.max_edicts = MAX_EDICTS;

	sv.edicts = Hunk_AllocName (sv.max_edicts*pr_edict_size, "edicts");

	sv.datagram.maxsize = sizeof(sv.datagram_buf);
	sv.datagram.cursize = 0;
	sv.datagram.data = sv.datagram_buf;

	sv.reliable_datagram.maxsize = sizeof(sv.reliable_datagram_buf);
	sv.reliable_datagram.cursize = 0;
	sv.reliable_datagram.data = sv.reliable_datagram_buf;

	sv.signon.maxsize = sizeof(sv.signon_buf);
	sv.signon.cursize = 0;
	sv.signon.data = sv.signon_buf;

// leave slots at start for clients only
	sv.num_edicts = svs.maxclients+1;
	for (i=0 ; i<svs.maxclients ; i++)
	{
		ent = EDICT_NUM(i+1);
		svs.clients[i].edict = ent;
	}

	sv.state = ss_loading;
	sv.paused = false;

	sv.time = 1.0;

	strcpy (sv.name, server);
	sprintf (sv.modelname,"maps/%s.bsp", server);
	sv.worldmodel = Mod_ForName (sv.modelname, false);
	if (!sv.worldmodel)
	{
		Con_Printf ("Couldn't spawn server %s\n", sv.modelname);
		sv.active = false;
		return;
	}
	sv.models[1] = sv.worldmodel;


//
// clear world interaction links
//
	SV_ClearWorld ();

	sv.sound_precache[0] = pr_strings;

	sv.model_precache[0] = pr_strings;
	sv.model_precache[1] = sv.modelname;
	for (i=1 ; i<sv.worldmodel->numsubmodels ; i++)
	{
		sv.model_precache[1+i] = localmodels[i];
		sv.models[i+1] = Mod_ForName (localmodels[i], false);
	}

//
// load the rest of the entities
//
	ent = EDICT_NUM(0);
	memset (&ent->v, 0, progs->entityfields * 4);
	ent->free = false;
	ent->v.model = sv.worldmodel->name - pr_strings;
	ent->v.modelindex = 1;		// world model
	ent->v.solid = SOLID_BSP;
	ent->v.movetype = MOVETYPE_PUSH;

	if (coop.value)
		pr_global_struct->coop = coop.value;
	else
		pr_global_struct->deathmatch = deathmatch.value;

	pr_global_struct->mapname = sv.name - pr_strings;

// serverflags are for cross level information (sigils)
	pr_global_struct->serverflags = svs.serverflags;

	ED_LoadFromFile (sv.worldmodel->entities);

	sv.active = true;

// all setup is completed, any further precache statements are errors
	sv.state = ss_active;

// run two frames to allow everything to settle
	host_frametime = 0.1;
	SV_Physics ();
	SV_Physics ();

// create a baseline for more efficient communications
	SV_CreateBaseline ();

// send serverinfo to all connected clients
	for (i=0,host_client = svs.clients ; i<svs.maxclients ; i++, host_client++)
		if (host_client->active)
			SV_SendServerinfo (host_client);

	Load_Waypoint ();
	Con_DPrintf ("Server spawned.\n");
}



//ZOMBIE AI THINGS BELOVE THIS!!!
#define W_MAX_TEMPSTRING 2048
char	*w_string_temp;
int W_fopen (void)
{
	int h = 0;

	Sys_FileOpenRead (va("%s/maps/%s.way",com_gamedir, sv.name), &h);
	return h;
}

void W_fclose (int h)
{
	Sys_FileClose(h);
}

char *W_fgets (int h)
{
	// reads one line (up to a \n) into a string
	int		i;
	int		count;
	char	buffer;

	count = Sys_FileRead(h, &buffer, 1);
	if (count && buffer == '\r')	// carriage return
	{
		count = Sys_FileRead(h, &buffer, 1);	// skip
	}
	if (!count)	// EndOfFile
	{
		return "";
	}

	i = 0;
	while (count && buffer != '\n')
	{
		if (i < 128-1)	// no place for character in temp string
		{
			w_string_temp[i++] = buffer;
		}

		// read next character
		count = Sys_FileRead(h, &buffer, 1);
		if (count && buffer == '\r')	// carriage return
		{
			count = Sys_FileRead(h, &buffer, 1);	// skip
		}
	};
	w_string_temp[i] = 0;

	return (w_string_temp);
}

char *W_substring (char *p, int offset, int length)
{
	int		maxoffset;		// 2001-10-25 Enhanced temp string handling by Maddes

	// cap values
	maxoffset = strlen(p);
	if (offset > maxoffset)
	{
		offset = maxoffset;
	}
	if (offset < 0)
		offset = 0;
// 2001-10-25 Enhanced temp string handling by Maddes  start
	if (length >= maxoffset)
		length = maxoffset-1;
// 2001-10-25 Enhanced temp string handling by Maddes  end
	if (length < 0)
		length = 0;

	p += offset;
	strncpy(w_string_temp, p, length);
	w_string_temp[length]=0;

	return w_string_temp;
}

void W_stov (char *v, vec3_t out)
{
	int i;
	vec3_t d;

	for (i=0; i<3; i++)
	{
		while(v && (v[0] == ' ' || v[0] == '\'')) //skip unneeded data
			v++;
		d[i] = atof(v);
		while (v && v[0] != ' ') // skip to next space
			v++;
	}
	VectorCopy (d, out);
}


waypoint_ai waypoints[MAX_WAYPOINTS];
void Load_Waypoint ()
{
	char temp[64];
	int i, p, s;
	vec3_t d;
	int h = 0;

	h = W_fopen();

	w_string_temp = Z_Malloc(128);
	if (h == -1)
	{
		Con_DPrintf("No waypoint file (%s/maps/%s.way) found\n", com_gamedir, sv.name);
		return;
	}
	for (i = 1; i < MAX_WAYPOINTS; i++)
	{
		waypoints[i].used = 0;
	}

	i = 1;
	Con_DPrintf("Loading waypoints\n");
	while (1)
	{
		if (strncmp(W_fgets (h), "Waypoint", 8))
		{
			Con_DPrintf("Last waypoint\n");
			break;
		}
		else
		{
			if (i == MAX_WAYPOINTS)
				Sys_Error ("Maximum waypoints loaded {%i)\n", MAX_WAYPOINTS);
			W_fgets (h);

			W_stov (W_substring (W_fgets (h), 9, 20), d);

			strcpy(temp, W_substring (W_fgets (h), 5, 20));

			i = atoi (temp);
			waypoints[i].id = atoi (temp);
			VectorCopy (d, waypoints[i].origin);

			strcpy(waypoints[i].special, W_substring (W_fgets (h), 10, 20));

			if (waypoints[i].special[0])
				waypoints[i].open = 0;
			else
				waypoints[i].open = 1;

			strcpy(temp, W_substring (W_fgets (h), 9, 20));
			waypoints[i].target[0] = atoi (temp);

			strcpy(temp, W_substring (W_fgets (h), 10, 20));
			waypoints[i].target[1] = atoi (temp);


			strcpy(temp, W_substring (W_fgets (h), 10, 20));
			waypoints[i].target[2] = atoi (temp);


			strcpy(temp, W_substring (W_fgets (h), 10, 20));
			waypoints[i].target[3] = atoi (temp);


			strcpy(temp, W_substring (W_fgets (h), 10, 20));
			waypoints[i].target[4] = atoi (temp);


			strcpy(temp, W_substring (W_fgets (h), 10, 20));
			waypoints[i].target[5] = atoi (temp);


			strcpy(temp, W_substring (W_fgets (h), 10, 20));
			waypoints[i].target[6] = atoi (temp);


			strcpy(temp, W_substring (W_fgets (h), 10, 20));
			waypoints[i].target[7] = atoi (temp);

			W_fgets (h);
			W_fgets (h);
			waypoints[i].used = 1;


			Con_DPrintf("Waypoint (%i) id: %i, tag: %s, open: %i, target: %i, target2: %i, target3: %i, target4: %i, target5: %i, target6: %i, target7: %i, target8: %i\n",
			i,
			waypoints[i].id,
			waypoints[i].special,
			waypoints[i].open,
			waypoints[i].target[0],
			waypoints[i].target[1],
			waypoints[i].target[2],
			waypoints[i].target[3],
			waypoints[i].target[4],
			waypoints[i].target[5],
			waypoints[i].target[6],
			waypoints[i].target[7]);
		}
	}
	Con_DPrintf("Total waypoints: %i\n", i);
	for (i = 1;i < MAX_WAYPOINTS; i++) //for sake of saving time later we are now going to save each targets array position and distace to each waypoint
	{
		for (p = 0;waypoints[i].target[p]; p++)
		{
			for (s = 1; s < MAX_WAYPOINTS; s++)
			{
				if (s == MAX_WAYPOINTS)
					Sys_Error ("Waypoint (%i) without a target!\n", s);
				if (waypoints[i].target[p] == waypoints[s].id)
				{
					waypoints[i].dist[p] = VecLength2(waypoints[s].origin, waypoints[i].origin);
					waypoints[i].target_id[p] = s;
					break;
				}
			}
		}
			Con_DPrintf("Waypoint (%i)target: %i (%i, %f), target2: %i (%i, %f), target3: %i (%i, %f), target4: %i (%i, %f), target5: %i (%i, %f), target6: %i (%i, %f), target7: %i (%i, %f), target8: %i (%i, %f)\n",
			waypoints[i].id,
			waypoints[i].target[0],
			waypoints[i].target_id[0],
			waypoints[i].dist[0],
			waypoints[i].target[1],
			waypoints[i].target_id[1],
			waypoints[i].dist[1],
			waypoints[i].target[2],
			waypoints[i].target_id[2],
			waypoints[i].dist[2],
			waypoints[i].target[3],
			waypoints[i].target_id[3],
			waypoints[i].dist[3],
			waypoints[i].target[4],
			waypoints[i].target_id[4],
			waypoints[i].dist[4],
			waypoints[i].target[5],
			waypoints[i].target_id[5],
			waypoints[i].dist[5],
			waypoints[i].target[6],
			waypoints[i].target_id[6],
			waypoints[i].dist[6],
			waypoints[i].target[7],
			waypoints[i].target_id[7],
			waypoints[i].dist[7]);
	}
	W_fclose(h);
	//Z_Free (w_string_temp);
}
