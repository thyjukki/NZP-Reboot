/*
Copyright (C) 1999,2000  contributors of the QuakeForge project

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

#include "quakedef.h"
#include "cl_slist.h"

server_entry_t	slist[MAX_SERVER_LIST];
//--------------------------------------UTILS-----------------------------------
char *Cmd_MakeArgs (int start)
{
	int i, c;

	static char	text[1024];

	text[0] = 0;
	c = Cmd_Argc();
	for (i = start; i < c; i++) {
		if (i > start)
			strncat (text, " ", sizeof(text) - strlen(text) - 1);
		strncat (text, Cmd_Argv(i), sizeof(text) - strlen(text) - 1);
	}

	return text;
}

char *CreateSpaces(int amount)
{
	static char spaces[1024];
	int size;

	size = bound(1, amount, sizeof(spaces) - 1);
	memset(spaces, ' ', size);
	spaces[size] = 0;

	return spaces;
}
//------------------------------------------------------------------------------
void SList_Init (void)
{
	memset (&slist, 0, sizeof(slist));
}

void SList_Shutdown (void)
{
	FILE	*f;

	// if the first is empty already that means there isn't a single entry
	if (!slist[0].server)
		return;

	//if (!(f = fopen("servers.lst", "wt")))
    if (!(f = fopen(va("%s/servers.lst", com_gamedir), "wt")))
	{
		Con_DPrintf ("Couldn't open servers.lst\n");
		return;
	}
	SList_Save (f);
	fclose (f);
}

void SList_Set (int i, char *addr, char *desc)
{
	if (i >= MAX_SERVER_LIST || i < 0)
		Sys_Error ("SList_Set: Bad index %d", i);

	if (slist[i].server)
		Z_Free (slist[i].server);
	if (slist[i].description)
		Z_Free (slist[i].description);

	slist[i].server = CopyString (addr);
	slist[i].description = CopyString (desc);
}

void SList_Reset_NoFree (int i)
{
	if (i >= MAX_SERVER_LIST || i < 0)
		Sys_Error ("SList_Reset_NoFree: Bad index %d", i);

	slist[i].description = slist[i].server = NULL;
}

void SList_Reset (int i)
{
	if (i >= MAX_SERVER_LIST || i < 0)
		Sys_Error ("SList_Reset: Bad index %d", i);

	if (slist[i].server)
	{
		Z_Free (slist[i].server);
		slist[i].server = NULL;
	}

	if (slist[i].description)
	{
		Z_Free (slist[i].description);
		slist[i].description = NULL;
	}
}

void SList_Switch (int a, int b)
{
	server_entry_t	temp;

	if (a >= MAX_SERVER_LIST || a < 0)
		Sys_Error ("SList_Switch: Bad index %d", a);
	if (b >= MAX_SERVER_LIST || b < 0)
		Sys_Error ("SList_Switch: Bad index %d", b);

	memcpy (&temp, &slist[a], sizeof(temp));
	memcpy (&slist[a], &slist[b], sizeof(temp));
	memcpy (&slist[b], &temp, sizeof(temp));
}

int SList_Length (void)
{
	int	count;

	for (count = 0 ; count < MAX_SERVER_LIST && slist[count].server ; count++)
		;

	return count;
}

void SList_Load (void)
{
	int	c, len, argc, count;
	char	line[128], *desc, *addr;
	FILE	*f;

	if (!(f = fopen (va("%s/servers.lst", com_gamedir), "rt")))
	//if (!(f = fopen("servers.lst", "rt")))
		return;

	count = len = 0;
	while ((c = getc(f)))
	{
		if (c == '\n' || c == '\r' || c == EOF)
		{
			if (c == '\r' && (c = getc(f)) != '\n' && c != EOF)
				ungetc (c, f);

			line[len] = 0;
			len = 0;
			Cmd_TokenizeString (line);

			if ((argc = Cmd_Argc()) >= 1)
			{
				addr = Cmd_Argv(0);
				desc = (argc >= 2) ? Cmd_Args() : "Unknown";
				SList_Set (count, addr, desc);
				if (++count == MAX_SERVER_LIST)
					break;
			}
			if (c == EOF)
				break;	//just in case an EOF follows a '\r'
		}
		else
		{
			if (len + 1 < sizeof(line))
				line[len++] = c;
		}
	}

	fclose (f);
}

void SList_Save (FILE *f)
{
	int	i;

	for (i=0 ; i<MAX_SERVER_LIST ; i++)
	{
		if (!slist[i].server)
			break;

		fprintf (f, "%s\t%s\n", slist[i].server, slist[i].description);
	}
}
