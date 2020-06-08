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
// cl_parse.c  -- parse a message received from the server

#include "quakedef.h"

extern 	cvar_t	bgmtype;

extern 	qboolean 	domaxammo;

char *svc_strings[] =
{
	"svc_bad",
	"svc_nop",
	"svc_disconnect",
	"svc_updatestat",
	"svc_version",		// [long] server version
	"svc_setview",		// [short] entity number
	"svc_sound",			// <see code>
	"svc_time",			// [float] server time
	"svc_print",			// [string] null terminated string
	"svc_stufftext",		// [string] stuffed into client's console buffer
						// the string should be \n terminated
	"svc_setangle",		// [vec3] set the view angle to this absolute value

	"svc_serverinfo",		// [long] version
						// [string] signon string
						// [string]..[0]model cache [string]...[0]sounds cache
						// [string]..[0]item cache
	"svc_lightstyle",		// [byte] [string]
	"svc_updatename",		// [byte] [string]
	"svc_updatepoints",	// [byte] [short]
	"svc_clientdata",		// <shortbits + data>
	"svc_stopsound",		// <see code>
	"",	// [byte] [byte]
	"svc_particle",		// [vec3] <variable>
	"svc_damage",			// [byte] impact [byte] blood [vec3] from

	"svc_spawnstatic",
	"OBSOLETE svc_spawnbinary",
	"svc_spawnbaseline",

	"svc_temp_entity",		// <variable>
	"svc_setpause",
	"svc_signonnum",
	"svc_centerprint",
	"svc_spawnstaticsound",
	"svc_intermission",
	"svc_finale",			// [string] music [string] text
	"svc_cdtrack",			// [byte] track [byte] looptrack
	"svc_sellscreen",
	"svc_cutscene",
	"svc_weaponfire",
	"svc_hitmark",
	"svc_skybox",		   // [string] skyname
	"svc_useprint",
	"svc_updatekills",
	"svc_limbupdate",
    "svc_fog",    // 41		// [byte] start [byte] end [byte] red [byte] green [byte] blue [float] time
    "svc_bspdecal", //42     // [string] name [byte] decal_size [coords] pos
    "svc_achievement", //43
	"svc_songegg", //44 			[string] track name
	"svc_maxammo" //45
};

//=============================================================================

/*
===============
CL_EntityNum

This error checks and tracks the total number of entities
===============
*/
entity_t	*CL_EntityNum (int num)
{
	if (num >= cl.num_entities)
	{
		if (num >= MAX_EDICTS)
			Host_Error ("CL_EntityNum: %i is an invalid number",num);
		while (cl.num_entities<=num)
		{
			cl_entities[cl.num_entities].colormap = vid.colormap;
			cl.num_entities++;
		}
	}

	return &cl_entities[num];
}


/*
==================
CL_ParseStartSoundPacket
==================
*/
void CL_ParseStartSoundPacket(void)
{
    vec3_t  pos;
    int 	channel, ent;
    int 	sound_num;
    int 	volume;
    int 	field_mask;
    float 	attenuation;
 	int		i;

    field_mask = MSG_ReadByte();

    if (field_mask & SND_VOLUME)
		volume = MSG_ReadByte ();
	else
		volume = DEFAULT_SOUND_PACKET_VOLUME;

    if (field_mask & SND_ATTENUATION)
		attenuation = MSG_ReadByte () / 64.0;
	else
		attenuation = DEFAULT_SOUND_PACKET_ATTENUATION;

	channel = MSG_ReadShort ();
	sound_num = MSG_ReadByte ();

	ent = channel >> 3;
	channel &= 7;

	if (ent > MAX_EDICTS)
		Host_Error ("CL_ParseStartSoundPacket: ent = %i", ent);

	for (i=0 ; i<3 ; i++)
		pos[i] = MSG_ReadCoord ();

    S_StartSound (ent, channel, cl.sound_precache[sound_num], pos, volume/255.0, attenuation);
}

/*
==================
CL_ParseBSPDecal

Spawn decals on map
Crow_bar.
==================
*/
void CL_ParseBSPDecal (void)
{
	vec3_t		pos;
	int			decal_size;
	char        *texname;

    texname     = MSG_ReadString ();
    decal_size  = MSG_ReadByte   ();
	pos[0]      = MSG_ReadCoord  ();
    pos[1]      = MSG_ReadCoord  ();
    pos[2]      = MSG_ReadCoord  ();

	if(!texname)
		return;

	Con_Printf("BSPDECAL[tex: %s size: %i pos: %f %f %f]\n", texname, decal_size, pos[0], pos[1], pos[2]);

	R_SpawnDecalBSP(pos, texname, decal_size);
}

/*
==================
CL_KeepaliveMessage

When the client is taking a long time to load stuff, send keepalive messages
so the server doesn't disconnect.
==================
*/
void CL_KeepaliveMessage (void)
{
	double	time;
	static double lastmsg;//BLUBSFIX, this was a float
	int		ret;
	sizebuf_t	old;
	byte		olddata[8192];

	if (sv.active)
	{
		//Con_Printf("Active Server...exit keepalive\n");
		return;		// no need if server is local
	}
	if (cls.demoplayback)
	{
		//Con_Printf("Demo Playback...exit keepalive\n");
		return;
	}

// read messages from server, should just be nops
	old = net_message;
	memcpy (olddata, net_message.data, net_message.cursize);

	do
	{
		ret = CL_GetMessage ();
		switch (ret)
		{
		default:
			Host_Error ("CL_KeepaliveMessage: CL_GetMessage failed");
		case 0:
			break;	// nothing waiting
		case 1:
			Host_Error ("CL_KeepaliveMessage: received a message");
			break;
		case 2:
			if (MSG_ReadByte() != svc_nop)
				Host_Error ("CL_KeepaliveMessage: datagram wasn't a nop");
			break;
		}
	} while (ret);

	net_message = old;
	memcpy (net_message.data, olddata, net_message.cursize);

// check time
	time = Sys_FloatTime ();
	if (time - lastmsg < 5)
		return;
	//Con_Printf("Time since last keepAlive msg = %f\n",time - lastmsg);

	lastmsg = time;

// write out a nop
	Con_Printf ("--> client to server keepalive\n");

	MSG_WriteByte (&cls.message, clc_nop);
	NET_SendMessage (cls.netcon, &cls.message);
	SZ_Clear (&cls.message);
}

/*
==================
CL_ParseServerInfo
==================
*/
void CL_ParseServerInfo (void)
{
	char	*str, tempname[MAX_QPATH];;
	int		i;
	int		nummodels, numsounds;
	char	model_precache[MAX_MODELS][MAX_QPATH];
	char	sound_precache[MAX_SOUNDS][MAX_QPATH];
	extern qboolean r_loadq3player;

	//void R_PreMapLoad (char *);

	//char	mapname[MAX_QPATH];

	Con_DPrintf ("Serverinfo packet received.\n");
	//Con_Printf ("Serverinfo packet received.\n");
//
// wipe the client_state_t struct
//
	CL_ClearState ();

// parse protocol version number
	i = MSG_ReadLong ();
	if (i != PROTOCOL_VERSION)
	{
		Con_Printf ("Server returned version %i, not %i", i, PROTOCOL_VERSION);
		return;
	}

// parse maxclients
	cl.maxclients = MSG_ReadByte ();
	if (cl.maxclients < 1 || cl.maxclients > MAX_SCOREBOARD)
	{
		Con_Printf("Bad maxclients (%u) from server\n", cl.maxclients);
		return;
	}
	cl.scores = Hunk_AllocName (cl.maxclients*sizeof(*cl.scores), "scores");

// parse gametype
	cl.gametype = MSG_ReadByte ();

// parse signon message
	str = MSG_ReadString ();
	strncpy (cl.levelname, str, sizeof(cl.levelname)-1);

// seperate the printfs so the server message can have a color
	Con_Printf("\n\n\35\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\37\n\n");
	Con_Printf ("%c%s\n", 2, str);

//
// first we go through and touch all of the precache data that still
// happens to be in the cache, so precaching something else doesn't
// needlessly purge it
//

// precache models
	for (i=0 ; i<NUM_MODELINDEX ; i++)
		cl_modelindex[i] = -1;

// precache models
	memset (cl.model_precache, 0, sizeof(cl.model_precache));
	//Con_Printf("GotModelsToLoad: ");
	for (nummodels=1 ; ; nummodels++)
	{
		str = MSG_ReadString ();

		if (!str[0])
			break;

		if (nummodels==MAX_MODELS)
		{
			Con_Printf ("Server sent too many model precaches\n");
			return;
		}

		if (r_loadq3models.value)
		{
			if (!strcmp(str, "models/player.mdl") &&
			    FS_FindFile("models/player/head.md3") &&
			    FS_FindFile("models/player/upper.md3") &&
			    FS_FindFile("models/player/lower.md3"))
			{
				Q_strncpyz (tempname, "models/player/lower.md3", MAX_QPATH);
				str = tempname;
				cl_modelindex[mi_player] = nummodels;
				r_loadq3player = true;
			}
			else
			{
				COM_StripExtension (str, tempname);
				strcat (tempname, ".md3");

				if (FS_FindFile(tempname))
					str = tempname;
			}
		}

		Q_strncpyz (model_precache[nummodels], str, sizeof(model_precache[nummodels]));
		//Con_Printf("%i,",nummodels);

		Mod_TouchModel (str);

		if (!strcmp(model_precache[nummodels], "models/player.mdl"))
			cl_modelindex[mi_player] = nummodels;
		else if (!strcmp(model_precache[nummodels], "progs/flame.mdl"))
			cl_modelindex[mi_flame1] = nummodels;
		else if (!strcmp(model_precache[nummodels], "progs/flame2.mdl"))
			cl_modelindex[mi_flame2] = nummodels;
  }
	//Con_Printf("...\n");

    if (r_loadq3player)
	{
		if (nummodels + 1 >= MAX_MODELS)
		{
			Con_Printf ("Server sent too many model precaches -> can't load Q3 player model\n");
			Q_strncpyz (model_precache[cl_modelindex[mi_player]], cl_modelnames[mi_player], sizeof(model_precache[cl_modelindex[mi_player]]));
		}
		else
		{
			Q_strncpyz (model_precache[nummodels], "models/player/upper.md3", sizeof(model_precache[nummodels]));
			cl_modelindex[mi_q3torso] = nummodels++;
			Q_strncpyz (model_precache[nummodels], "models/player/head.md3", sizeof(model_precache[nummodels]));
			cl_modelindex[mi_q3head] = nummodels++;
		}
	}

// precache sounds
	//Con_Printf("Got Sounds to load: ");
	memset (cl.sound_precache, 0, sizeof(cl.sound_precache));
	for (numsounds=1 ; ; numsounds++)
	{

		str = MSG_ReadString ();
		if (!str[0])
			break;
		if (numsounds==MAX_SOUNDS)
		{
			Con_Printf ("Server sent too many sound precaches\n");
			return;
		}
		strcpy (sound_precache[numsounds], str);
		S_TouchSound (str);
		//Con_Printf("%i,",numsounds);
	}
	//Con_Printf("\n");
    //COM_StripExtension (COM_SkipPath(model_precache[1]), mapname);
	//R_PreMapLoad (mapname);

//
// now we try to load everything else until a cache allocation fails
//

   loading_num_step = loading_num_step +nummodels + numsounds;

	//Con_Printf("Loaded Model: ");

	for (i=1 ; i<nummodels ; i++)
	{
		cl.model_precache[i] = Mod_ForName (model_precache[i], false);
		if (cl.model_precache[i] == NULL)
		{
			Con_Printf("Model %s not found\n", model_precache[i]);
			return;
		}
		CL_KeepaliveMessage ();
		loading_cur_step++;
		strcpy(loading_name, model_precache[i]);
		//Con_Printf("%i,",i);
		SCR_UpdateScreen ();
	}

	//Con_Printf("\n");
	//Con_Printf("Total Models loaded: %i\n",nummodels);
	SCR_UpdateScreen ();

	// load the extra "no-flamed-torch" model
	//cl.model_precache[nummodels] = Mod_ForName ("progs/flame0.mdl", false);
	//cl_modelindex[mi_flame0] = nummodels++;

	S_BeginPrecaching ();
	//Con_Printf("Loaded Sounds: ");
	for (i=1 ; i<numsounds ; i++)
	{
		cl.sound_precache[i] = S_PrecacheSound (sound_precache[i]);
		CL_KeepaliveMessage ();
		loading_cur_step++;
		//Con_Printf("%i,",i);
		strcpy(loading_name, sound_precache[i]);
		SCR_UpdateScreen ();
	}
	S_EndPrecaching ();

	//Con_Printf("...\n");
	//Con_Printf("Total Sounds Loaded: %i\n",numsounds);
	SCR_UpdateScreen ();

   	Clear_LoadingFill ();

// local state
	cl_entities[0].model = cl.worldmodel = cl.model_precache[1];

	R_NewMap ();

	Hunk_Check ();		// make sure nothing is hurt
	HUD_NewMap ();

	noclip_anglehack = false;		// noclip is turned off at start
}


/*
==================
CL_ParseUpdate

Parse an entity update message from the server
If an entities model or origin changes from frame to frame, it must be
relinked.  Other attributes can change without relinking.
==================
*/
int	bitcounts[16];

void CL_ParseUpdate (int bits)
{
	int			i;
	model_t		*model;
	int			modnum;
	qboolean	forcelink;
	entity_t	*ent;
	int			num;
    //int		    skin;

	if (cls.signon == SIGNONS - 1)
	{	// first update is the final signon stage
		Con_DPrintf("First Update\n");
		cls.signon = SIGNONS;
		CL_SignonReply (); //disabling this temp-mortem
	}
	//Con_Printf("2\n");


	if (bits & U_MOREBITS)
	{
		i = MSG_ReadByte ();
		bits |= (i<<8);
	}

	// Tomaz - QC Control Begin
	if (bits & U_EXTEND1)
	{
		bits |= MSG_ReadByte() << 16;

		if (bits & U_EXTEND2)
		{
			bits |= MSG_ReadByte() << 24;
		}
	}
	// Tomaz - QC Control End

	if (bits & U_LONGENTITY)
		num = MSG_ReadShort ();
	else
		num = MSG_ReadByte ();

	ent = CL_EntityNum (num);

	for (i=0 ; i<16 ; i++)
		if (bits&(1<<i))
			bitcounts[i]++;

	if (ent->msgtime != cl.mtime[1])
		forcelink = true;	// no previous frame to lerp from
	else
		forcelink = false;

	ent->msgtime = cl.mtime[0];

	if (bits & U_MODEL)
	{
		modnum = MSG_ReadByte ();
		if (modnum >= MAX_MODELS)
			Host_Error ("CL_ParseModel: bad modnum");
	}
	else
		modnum = ent->baseline.modelindex;

	model = cl.model_precache[modnum];
	if (model != ent->model)
	{
		ent->model = model;
	// automatic animation (torches, etc) can be either all together
	// or randomized
		if (model)
		{
			if (model->synctype == ST_RAND)
				ent->syncbase = (float)(rand()&0x7fff) / 0x7fff;
			else
				ent->syncbase = 0.0;
		}
		else
			forcelink = true;	// hack to make null model players work
	}

	if (bits & U_FRAME)
		ent->frame = MSG_ReadShort ();
	else
		ent->frame = ent->baseline.frame;

	if (bits & U_COLORMAP)
		i = MSG_ReadByte();
	else
		i = ent->baseline.colormap;
	if (!i)
		ent->colormap = vid.colormap;
	else
	{
		if (i > cl.maxclients)
			Sys_Error ("i >= cl.maxclients");
	}

	if (bits & U_SKIN)
		ent->skinnum = MSG_ReadByte();
	else
		ent->skinnum = ent->baseline.skin;

	if (bits & U_FRAMETIME)
		ent->iframetime = MSG_ReadFloat();
	else
		ent->iframetime = 0.1;

	if (bits & U_EFFECTS)
		ent->effects = MSG_ReadShort();
	else
		ent->effects = ent->baseline.effects;

// shift the known values for interpolation
	VectorCopy (ent->msg_origins[0], ent->msg_origins[1]);
	VectorCopy (ent->msg_angles[0], ent->msg_angles[1]);
	if (bits & U_ORIGIN1)
		ent->msg_origins[0][0] = MSG_ReadCoord ();
	else
		ent->msg_origins[0][0] = ent->baseline.origin[0];
	if (bits & U_ANGLE1)
		ent->msg_angles[0][0] = MSG_ReadAngle();
	else
		ent->msg_angles[0][0] = ent->baseline.angles[0];

	if (bits & U_ORIGIN2)
		ent->msg_origins[0][1] = MSG_ReadCoord ();
	else
		ent->msg_origins[0][1] = ent->baseline.origin[1];
	if (bits & U_ANGLE2)
		ent->msg_angles[0][1] = MSG_ReadAngle();
	else
		ent->msg_angles[0][1] = ent->baseline.angles[1];

	if (bits & U_ORIGIN3)
		ent->msg_origins[0][2] = MSG_ReadCoord ();
	else
		ent->msg_origins[0][2] = ent->baseline.origin[2];
	if (bits & U_ANGLE3)
		ent->msg_angles[0][2] = MSG_ReadAngle();
	else
		ent->msg_angles[0][2] = ent->baseline.angles[2];
// Tomaz - QC Alpha Scale Glow Begin
	if (bits & U_RENDERAMT)
	    ent->renderamt = MSG_ReadFloat();
    else
	    ent->renderamt = 0;

    if (bits & U_RENDERMODE)
	    ent->rendermode = MSG_ReadFloat();
    else
	    ent->rendermode = 0;

	if (bits & U_RENDERCOLOR1)
	    ent->rendercolor[0] = MSG_ReadFloat();
    else
	    ent->rendercolor[0] = 0;

	if (bits & U_RENDERCOLOR2)
	    ent->rendercolor[1] = MSG_ReadFloat();
    else
	    ent->rendercolor[1] = 0;

	if (bits & U_RENDERCOLOR3)
	    ent->rendercolor[2] = MSG_ReadFloat();
    else
	    ent->rendercolor[2] = 0;
// Tomaz - QC Alpha Scale Glow End
    if ( bits & U_NOLERP )//there's no data for nolerp, it is the value itself
		ent->forcelink = true;

	if ( forcelink )
	{	// didn't have an update last message
		VectorCopy (ent->msg_origins[0], ent->msg_origins[1]);
		VectorCopy (ent->msg_origins[0], ent->origin);
		VectorCopy (ent->msg_angles[0], ent->msg_angles[1]);
		VectorCopy (ent->msg_angles[0], ent->angles);
		ent->forcelink = true;
	}
}

/*
==================
CL_ParseBaseline
==================
*/
void CL_ParseBaseline (entity_t *ent)
{
	int			i;

	ent->baseline.modelindex = MSG_ReadByte ();
	ent->baseline.frame = MSG_ReadByte ();
	ent->baseline.colormap = MSG_ReadByte();
	ent->baseline.skin = MSG_ReadByte();
	for (i=0 ; i<3 ; i++)
	{
		ent->baseline.origin[i] = MSG_ReadCoord ();
		ent->baseline.angles[i] = MSG_ReadAngle ();
	}
}

/*
==================
CL_ParseClientdata

Server information pertaining to this client only
==================
*/
extern int perk_order[9];
extern int current_perk_order;
void CL_ParseClientdata (int bits)
{
	int		i, s;

	if (bits & SU_VIEWHEIGHT)
		cl.viewheight = MSG_ReadChar ();
	else
		cl.viewheight = DEFAULT_VIEWHEIGHT;

	if (bits & SU_IDEALPITCH)
		cl.idealpitch = MSG_ReadChar ();
	else
		cl.idealpitch = 0;


	if (bits & SU_PERKS)
		i = MSG_ReadLong ();
	else
		i = 0;
	if (cl.perks != i)
	{
		if (i & 1 && !(cl.perks & 1))
		{
			perk_order[current_perk_order] = 1;
			current_perk_order++;
		}
		if (i & 2 && !(cl.perks & 2))
		{
			perk_order[current_perk_order] = 2;
			current_perk_order++;
		}
		if (i & 4 && !(cl.perks & 4))
		{
			perk_order[current_perk_order] = 4;
			current_perk_order++;
		}
		if (i & 8 && !(cl.perks & 8))
		{
			perk_order[current_perk_order] = 8;
			current_perk_order++;
		}
		if (i & 16 && !(cl.perks & 16))
		{
			perk_order[current_perk_order] = 16;
			current_perk_order++;
		}
		if (i & 32 && !(cl.perks & 32))
		{
			perk_order[current_perk_order] = 32;
			current_perk_order++;
		}
		if (i & 64 && !(cl.perks & 64))
		{
			perk_order[current_perk_order] = 64;
			current_perk_order++;
		}
		if (i & 128 && !(cl.perks & 128))
		{
			perk_order[current_perk_order] = 128;
			current_perk_order++;
		}
		if (cl.perks & 1 && !(i & 1))
		{
			for (s = 0; s < 9; s++)
			{
				if (perk_order[s] == 1)
				{
					perk_order[s] = 0;
					while (perk_order[s+1])
					{
						perk_order[s] = perk_order[s+1];
						perk_order[s+1] = 0;
					}
					break;
				}
			}
			current_perk_order--;
		}
		if (cl.perks & 2 && !(i & 2))
		{
			for (s = 0; s < 9; s++)
			{
				if (perk_order[s] == 2)
				{
					perk_order[s] = 0;
					while (perk_order[s+1])
					{
						perk_order[s] = perk_order[s+1];
						perk_order[s+1] = 0;
					}
					break;
				}
			}
			current_perk_order--;
		}
		if (cl.perks & 4 && !(i & 4))
		{
			for (s = 0; s < 9; s++)
			{
				if (perk_order[s] == 4)
				{
					perk_order[s] = 0;
					while (perk_order[s+1])
					{
						perk_order[s] = perk_order[s+1];
						perk_order[s+1] = 0;
					}
					break;
				}
			}
			current_perk_order--;
		}
		if (cl.perks & 8 && !(i & 8))
		{
			for (s = 0; s < 9; s++)
			{
				if (perk_order[s] == 8)
				{
					perk_order[s] = 0;
					while (perk_order[s+1])
					{
						perk_order[s] = perk_order[s+1];
						perk_order[s+1] = 0;
					}
					break;
				}
			}
			current_perk_order--;
		}
		if (cl.perks & 16 && !(i & 16))
		{
			for (s = 0; s < 9; s++)
			{
				if (perk_order[s] == 16)
				{
					perk_order[s] = 0;
					while (perk_order[s+1])
					{
						perk_order[s] = perk_order[s+1];
						perk_order[s+1] = 0;
					}
					break;
				}
			}
			current_perk_order--;
		}
		if (cl.perks & 32 && !(i & 32))
		{
			for (s = 0; s < 9; s++)
			{
				if (perk_order[s] == 32)
				{
					perk_order[s] = 0;
					while (perk_order[s+1])
					{
						perk_order[s] = perk_order[s+1];
						perk_order[s+1] = 0;
					}
					break;
				}
			}
			current_perk_order--;
		}
		if (cl.perks & 64 && !(i & 64))
		{
			for (s = 0; s < 9; s++)
			{
				if (perk_order[s] == 64)
				{
					perk_order[s] = 0;
					while (perk_order[s+1])
					{
						perk_order[s] = perk_order[s+1];
						perk_order[s+1] = 0;
					}
					break;
				}
			}
			current_perk_order--;
		}
		if (cl.perks & 128 && !(i & 128))
		{
			for (s = 0; s < 9; s++)
			{
				if (perk_order[s] == 128)
				{
					perk_order[s] = 0;
					while (perk_order[s+1])
					{
						perk_order[s] = perk_order[s+1];
						perk_order[s+1] = 0;
					}
					break;
				}
			}
			current_perk_order--;
		}
		cl.perks = i;
	}

	cl.onground = (bits & SU_ONGROUND) != 0;
	cl.inwater = (bits & SU_INWATER) != 0;

	VectorCopy (cl.mvelocity[0], cl.mvelocity[1]);
	for (i=0 ; i<3 ; i++)
	{
		if (bits & (SU_PUNCH1<<i) )
			cl.punchangle[i] = MSG_ReadChar();
		else
			cl.punchangle[i] = 0;
		if (bits & (SU_VELOCITY1<<i) )
			cl.mvelocity[0][i] = MSG_ReadChar()*16;
		else
			cl.mvelocity[0][i] = 0;
	}

	if (bits & SU_WEAPONFRAME)
		cl.stats[STAT_WEAPONFRAME] = MSG_ReadByte ();
	else
		cl.stats[STAT_WEAPONFRAME] = 0;

	if (bits & SU_WEAPONSKIN)
		cl.stats[STAT_WEAPONSKIN] = MSG_ReadByte ();
	else
		cl.stats[STAT_WEAPONSKIN] = 0;


	if (bits & SU_WEAPON)
		i = MSG_ReadByte ();
	else
		i = 0;

	if (cl.stats[STAT_WEAPON] != i)
		cl.stats[STAT_WEAPON] = i;


	if (bits & SU_GRENADES)
		i = MSG_ReadLong ();
	else
		i = 0;

	if (cl.stats[STAT_GRENADES] != i)
	{
		HUD_Change_time = Sys_FloatTime() + 6;
		cl.stats[STAT_GRENADES] = i;
	}

	i = MSG_ReadShort ();
	if (cl.stats[STAT_PRIGRENADES] != i)
	{
		HUD_Change_time = Sys_FloatTime() + 6;
		cl.stats[STAT_PRIGRENADES] = i;
	}


	i = MSG_ReadShort ();
	if (cl.stats[STAT_SECGRENADES] != i)
	{
		HUD_Change_time = Sys_FloatTime() + 6;
		cl.stats[STAT_SECGRENADES] = i;
	}

	i = MSG_ReadShort ();
	if (cl.stats[STAT_HEALTH] != i)
		cl.stats[STAT_HEALTH] = i;

	i = MSG_ReadShort ();
	if (cl.stats[STAT_AMMO] != i)
	{
		HUD_Change_time = Sys_FloatTime() + 6;
		cl.stats[STAT_AMMO] = i;
	}

	i = MSG_ReadByte ();
	if (cl.stats[STAT_CURRENTMAG] != i)
	{
		HUD_Change_time = Sys_FloatTime() + 6;
		cl.stats[STAT_CURRENTMAG] = i;
	}

	i = MSG_ReadByte ();
	if (cl.stats[STAT_ZOOM] != i)
		cl.stats[STAT_ZOOM] = i;

	i = MSG_ReadByte ();
	if (cl.stats[STAT_ACTIVEWEAPON] != i)
	{
		HUD_Change_time = Sys_FloatTime() + 6;
		cl.stats[STAT_ACTIVEWEAPON] = i;
	}

	i = MSG_ReadByte ();
	if (cl.stats[STAT_ROUNDS] != i)
		cl.stats[STAT_ROUNDS] = i;

	i = MSG_ReadByte ();
	if (cl.stats[STAT_ROUNDCHANGE] != i)
		cl.stats[STAT_ROUNDCHANGE] = i;

	i = MSG_ReadByte ();
	if (cl.stats[STAT_X2] != i)
		cl.stats[STAT_X2] = i;

	i = MSG_ReadByte ();
	if (cl.stats[STAT_INSTA] != i)
		cl.stats[STAT_INSTA] = i;

	i = MSG_ReadByte ();
	if (cl.progress_bar != i)
		cl.progress_bar = i;

	i = MSG_ReadByte ();
	if (cl.stats[STAT_WEAPON2] != i)
		cl.stats[STAT_WEAPON2] = i;

	i = MSG_ReadByte ();
	if (cl.stats[STAT_WEAPON2SKIN] != i)
		cl.stats[STAT_WEAPON2SKIN] = i;

	i = MSG_ReadByte ();
	if (cl.stats[STAT_WEAPON2FRAME] != i)
		cl.stats[STAT_WEAPON2FRAME] = i;

	i = MSG_ReadByte ();
	if (cl.stats[STAT_CURRENTMAG2] != i)
		cl.stats[STAT_CURRENTMAG2] = i;
}

/*
=====================
CL_ParseStatic
=====================
*/
void CL_ParseStatic (void)
{
	entity_t *ent;
	int		i;

	i = cl.num_statics;
	if (i >= MAX_STATIC_ENTITIES)
		Host_Error ("Too many static entities");
	ent = &cl_static_entities[i];
	cl.num_statics++;
	CL_ParseBaseline (ent);

// copy it to the current state
	ent->model = cl.model_precache[ent->baseline.modelindex];
	ent->frame = ent->baseline.frame;
	ent->colormap = vid.colormap;
	ent->skinnum = ent->baseline.skin;
	ent->effects = ent->baseline.effects;

	VectorCopy (ent->baseline.origin, ent->origin);
	VectorCopy (ent->baseline.angles, ent->angles);
	R_AddEfrags (ent);
}

/*
===================
CL_ParseStaticSound
===================
*/
void CL_ParseStaticSound (void)
{
	vec3_t		org;
	int			sound_num, vol, atten;
	int			i;

	for (i=0 ; i<3 ; i++)
		org[i] = MSG_ReadCoord ();
	sound_num = MSG_ReadByte ();
	vol = MSG_ReadByte ();
	atten = MSG_ReadByte ();

	S_StaticSound (cl.sound_precache[sound_num], org, vol, atten);
}

extern double Hitmark_Time;
extern int crosshair_spread;
extern double crosshair_spread_time;
double return_time;
/*
===================
CL_ParseWeaponFire
===================
*/
void CL_ParseWeaponFire (void)
{
	vec3_t		kick;
	return_time = (double)6/MSG_ReadLong ();
	crosshair_spread_time = return_time + sv.time;

	kick[0] = MSG_ReadCoord()/5;
	kick[1] = MSG_ReadCoord()/5;
	kick[2] = MSG_ReadCoord()/5;

	if (!(cl.perks & 64)) {
		cl.gun_kick[0] += kick[0];
		cl.gun_kick[1] += kick[1];
		cl.gun_kick[2] += kick[2];
	}
}
/*
===================
CL_ParseLimbUpdate
===================
*/
void CL_ParseLimbUpdate (void)
{
    int limb = MSG_ReadByte();
    int zombieent = MSG_ReadShort();
    int limbent = MSG_ReadShort();
    switch (limb)
    {
        case 0://head
            cl_entities[zombieent].z_head = limbent;
            break;
        case 1://larm
            cl_entities[zombieent].z_larm = limbent;
            break;
        case 2://rarm
            cl_entities[zombieent].z_rarm = limbent;
            break;

    }
}


#define SHOWNET(x) if(cl_shownet.value==2)Con_Printf ("%3i:%s\n", msg_readcount-1, x);

/*
=====================
CL_ParseServerMessage
=====================
*/
void CL_ParseServerMessage (void)
{
	int			cmd;
	int			i;

//
// if recording demos, copy the message out
//
	if (cl_shownet.value == 1)
		Con_Printf ("%i ",net_message.cursize);
	else if (cl_shownet.value == 2)
		Con_Printf ("------------------\n");

	cl.onground = false;	// unless the server says otherwise
//
// parse the message
//
	MSG_BeginReading ();

	while (1)
	{
		if (msg_badread)
			Host_Error ("CL_ParseServerMessage: Bad server message");

		cmd = MSG_ReadByte ();

		if (cmd == -1)
		{
			SHOWNET("END OF MESSAGE");
			return;		// end of message
		}

	// if the high bit of the command byte is set, it is a fast update
		if (cmd & 128)//checking if it's an entity update, if it is the 7th bit will be on, this is checking for that
		{
			SHOWNET("fast update");
			CL_ParseUpdate (cmd&127);//here we strip the cmd from the value of the 7th (128) bit, to only give the rest of the commands
			continue;
		}

		SHOWNET(svc_strings[cmd]);

	// other commands
		switch (cmd)
		{
		default:
			Host_Error ("CL_ParseServerMessage: Illegible server message (%i)\n", cmd);
			break;

		case svc_nop:
			break;

		case svc_time:
			cl.mtime[1] = cl.mtime[0];
			cl.mtime[0] = MSG_ReadFloat ();
			break;

		case svc_clientdata:
			i = MSG_ReadShort ();
			CL_ParseClientdata (i);
			break;

		case svc_version:
			i = MSG_ReadLong ();
			if (i != PROTOCOL_VERSION)
				Host_Error ("CL_ParseServerMessage: Server is protocol %i instead of %i\n", i, PROTOCOL_VERSION);
			break;

		case svc_disconnect:
			Host_EndGame ("Server disconnected\n");

		case svc_print:
			Con_Printf ("%s", MSG_ReadString ());
			break;

		case svc_centerprint:
			SCR_CenterPrint (MSG_ReadString ());
			break;

		case svc_useprint:
			SCR_UsePrint (MSG_ReadByte (),MSG_ReadShort (),MSG_ReadByte ());
			break;
		case svc_maxammo:
			domaxammo = true;
			break;
		case svc_stufftext:
			Cbuf_AddText (MSG_ReadString ());
			break;
		case svc_serverinfo:
			CL_ParseServerInfo ();
			vid.recalc_refdef = true;	// leave intermission full screen
			break;

		case svc_setangle:
			for (i=0 ; i<3 ; i++)
				cl.viewangles[i] = MSG_ReadAngle ();
			break;

		case svc_setview:
			cl.viewentity = MSG_ReadShort ();
			break;

		case svc_lightstyle:
			i = MSG_ReadByte ();
			if (i >= MAX_LIGHTSTYLES)
				Sys_Error ("svc_lightstyle > MAX_LIGHTSTYLES");
			Q_strcpy (cl_lightstyle[i].map,  MSG_ReadString());
			cl_lightstyle[i].length = Q_strlen(cl_lightstyle[i].map);
			break;

		case svc_sound:
			CL_ParseStartSoundPacket();
			break;

		case svc_stopsound:
			i = MSG_ReadShort();
			S_StopSound(i>>3, i&7);
			break;

		case svc_updatename:
			i = MSG_ReadByte ();
			if (i >= cl.maxclients)
				Host_Error ("CL_ParseServerMessage: svc_updatename > MAX_SCOREBOARD");
			strcpy (cl.scores[i].name, MSG_ReadString ());
			break;

		case svc_updatepoints:
			i = MSG_ReadByte ();
			if (i >= cl.maxclients)
				Host_Error ("CL_ParseServerMessage: svc_updatepoints > MAX_SCOREBOARD");
			cl.scores[i].points = MSG_ReadLong ();
			break;

		case svc_updatekills:
			i = MSG_ReadByte ();
			if (i >= cl.maxclients)
				Host_Error ("CL_ParseServerMessage: svc_updatepoints > MAX_SCOREBOARD");
			cl.scores[i].kills = MSG_ReadShort ();
			break;


		case svc_particle:
			R_ParseParticleEffect ();
			break;

		case svc_spawnbaseline:
			i = MSG_ReadShort ();
			// must use CL_EntityNum() to force cl.num_entities up
			CL_ParseBaseline (CL_EntityNum(i));
			break;
		case svc_spawnstatic:
			CL_ParseStatic ();
			break;
		case svc_temp_entity:
			CL_ParseTEnt ();
			break;

		case svc_setpause:
			{
				cl.paused = MSG_ReadByte ();

				if (cl.paused)
				{
					CDAudio_Pause ();
				}
				else
				{
					CDAudio_Resume ();
				}
			}
			break;

		case svc_signonnum:
			i = MSG_ReadByte ();
			if (i <= cls.signon)
				Host_Error ("Received signon %i when at %i", i, cls.signon);
			cls.signon = i;
			Con_DPrintf("Signon: %i \n",i);
			CL_SignonReply ();
			break;

		case svc_updatestat:
			i = MSG_ReadByte ();
			if (i < 0 || i >= MAX_CL_STATS)
				Sys_Error ("svc_updatestat: %i is invalid", i);
			cl.stats[i] = MSG_ReadLong ();
			break;

		case svc_spawnstaticsound:
			CL_ParseStaticSound ();
			break;

		case svc_cdtrack:
			cl.cdtrack = MSG_ReadByte ();
			cl.looptrack = MSG_ReadByte ();

			if (strcmpi(bgmtype.string,"cd") == 0)
			{
				if ( (cls.demoplayback || cls.demorecording) && (cls.forcetrack != -1) )
					CDAudio_Play ((byte)cls.forcetrack, true);
				else
					CDAudio_Play ((byte)cl.cdtrack, true);
			}
			else
			   CDAudio_Stop();
			break;

		case svc_intermission:
			cl.intermission = 1;
			cl.completed_time = cl.time;
			vid.recalc_refdef = true;	// go to full screen
			break;

		case svc_finale:
			cl.intermission = 2;
			cl.completed_time = cl.time;
			vid.recalc_refdef = true;	// go to full screen
			SCR_CenterPrint (MSG_ReadString ());
			break;

		case svc_cutscene:
			cl.intermission = 3;
			cl.completed_time = cl.time;
			vid.recalc_refdef = true;	// go to full screen
			SCR_CenterPrint (MSG_ReadString ());
			break;

		case svc_sellscreen:
			Cmd_ExecuteString ("help", src_command);
			break;

	    case svc_skybox:
			Sky_LoadSkyBox(MSG_ReadString());
			break;
		case svc_songegg:
			CDAudio_Track(MSG_ReadString());
			break;
		case svc_fog:
			Fog_ParseServerMessage ();
			break;

		case svc_achievement:
			HUD_Parse_Achievement (MSG_ReadByte());
			break;

		case svc_hitmark:
			Hitmark_Time = sv.time + 0.2;
			break;

		case svc_weaponfire:
			CL_ParseWeaponFire();
			break;

		case svc_limbupdate:
			CL_ParseLimbUpdate();
			break;

		case svc_bspdecal:
			CL_ParseBSPDecal ();
			break;
		}
	}
}

