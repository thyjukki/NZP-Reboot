/*
Copyright (C) 2009 Crow_bar.

Used code from "Fuhquake" modify by Crow_bar

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

extern "C"
{
#include "../quakedef.h"
}
#include <pspgu.h>

#include <list>

using namespace std;

list<FILE*> UnloadFileList;

#define TEXWAD_MAXIMAGES 16384
typedef struct
{
	char name[16];
	FILE *file;
	int position;
	int size;
} texwadlump_t;

texwadlump_t	texwadlump[TEXWAD_MAXIMAGES];
int numwadtextures;

//By Crow_bar
void UnloadWads (void)
{
	FILE *files;

	while (UnloadFileList.size() > 0)
	{
		files = UnloadFileList.front();
		UnloadFileList.pop_front();
		fclose(files);
	}
	numwadtextures = 0;
}

void WAD3_LoadTextureWadFile (char *filename)
{
	lumpinfo_t *lumps, *lump_p;
	wadinfo_t header;
	int i, j, infotableofs, numlumps, lowmark;
	FILE *file;

	if (FS_FOpenFile (va("textures/wad3/%s", filename), &file) != -1)
		goto loaded;
	if (FS_FOpenFile (va("textures/halflife/%s", filename), &file) != -1)
		goto loaded;
	if (FS_FOpenFile (va("textures/%s", filename), &file) != -1)
		goto loaded;
	if (FS_FOpenFile (filename, &file) != -1)
		goto loaded;


 	Host_Error ("Couldn't load halflife wad \"%s\"\n", filename);

loaded:
	if (fread(&header, 1, sizeof(wadinfo_t), file) != sizeof(wadinfo_t))
	{
		Con_Printf ("WAD3_LoadTextureWadFile: unable to read wad header");
        fclose(file);
		return;
	}

	if (memcmp(header.identification, "WAD3", 4))
	{
		Con_Printf ("WAD3_LoadTextureWadFile: Wad file %s doesn't have WAD3 id\n",filename);
        fclose(file);
		return;
	}

	numlumps = LittleLong(header.numlumps);

	if (numlumps < 1 || numlumps > TEXWAD_MAXIMAGES)
	{
		Con_Printf ("WAD3_LoadTextureWadFile: invalid number of lumps (%i)\n", numlumps);
        fclose(file);
		return;
	}

	infotableofs = LittleLong(header.infotableofs);

	if (fseek(file, infotableofs, SEEK_SET))
	{
		Con_Printf ("WAD3_LoadTextureWadFile: unable to seek to lump table");
        fclose(file);
		return;
	}

	lowmark = Hunk_LowMark();

	if (!(lumps = static_cast<lumpinfo_t*>(Hunk_Alloc(sizeof(lumpinfo_t) * numlumps))))
	{
		Con_Printf ("WAD3_LoadTextureWadFile: unable to allocate temporary memory for lump table");
        fclose(file);
		return;
	}

	if (fread(lumps, 1, sizeof(lumpinfo_t) * numlumps, file) != sizeof(lumpinfo_t) * numlumps)
	{
		Con_Printf ("WAD3_LoadTextureWadFile: unable to read lump table");
        fclose(file);
		Hunk_FreeToLowMark(lowmark);
		return;
	}

	UnloadFileList.push_back(file); //Crow_bar. UnloadWads code

	for (i = 0, lump_p = lumps; i < numlumps; i++,lump_p++)
	{
        W_CleanupName (lump_p->name, lump_p->name);
		for (j = 0;j < numwadtextures;j++)
		{
			if (!strcmp(lump_p->name, texwadlump[j].name)) // name match, replace old one
				break;
		}
		if (j >= TEXWAD_MAXIMAGES)
			break; // abort loading
		if (j == numwadtextures)
		{
			W_CleanupName (lump_p->name, texwadlump[j].name);
			texwadlump[j].file = file;
			texwadlump[j].position = LittleLong(lump_p->filepos);
			texwadlump[j].size = LittleLong(lump_p->disksize);
			numwadtextures++;
		}
	}

	Hunk_FreeToLowMark(lowmark);
	//leaves the file open
}

//converts paletted to rgba
int ConvertWad3ToRGBA(miptex_t *tex)
{
	byte *in, *data, *pal;
	int i, p, image_size;

	if (!tex->offsets[0])
		Sys_Error("ConvertWad3ToRGBA: tex->offsets[0] == 0");

	image_size = tex->width * tex->height;

	in = (byte *) ((byte *) tex + tex->offsets[0]);
    pal = in + ((image_size * 85) >> 6) + 2;


	data = (byte*)malloc(image_size);
    for (i = 0; i < image_size; i++)
	{
        p = *in++;
/*
		if (tex->name[0] == '{' && p == 255)
			data[i] = 0;
		else
*/
			data[i] = p;
	}



	int level = 0;
    if (r_mipmaps.value > 0)
		level = 3;

	int index = GL_LoadPalTex (tex->name, tex->width, tex->height, (const byte*)data, qtrue, GU_LINEAR, level, (byte *)pal, PAL_RGB);

	free(data);

	return index;

}

int WAD3_LoadTexture(miptex_t *mt)
{
	char texname[MAX_QPATH];
	int i, j, lowmark = 0;
	FILE *file;
	miptex_t *tex;
	int index;

	if (mt->offsets[0])
 	    return ConvertWad3ToRGBA(mt);

	texname[sizeof(texname) - 1] = 0;
	W_CleanupName (mt->name, texname);

	for (i = 0;i < numwadtextures;i++)
	{
		if (!texwadlump[i].name[0])
			break;

	    if (strcmp(texname, texwadlump[i].name))
			continue;

		file = texwadlump[i].file;

		if (fseek(file, texwadlump[i].position, SEEK_SET))
		{
			fclose(file);
			Con_Printf("WAD3_LoadTexture: corrupt WAD3 file");
            return 0;
		}

		lowmark = Hunk_LowMark();
		tex = static_cast<miptex_t*>(Hunk_Alloc(texwadlump[i].size));

		if (fread(tex, 1, texwadlump[i].size, file) < texwadlump[i].size)
		{
            Con_Printf("WAD3_LoadTexture: corrupt WAD3 file");
			Hunk_FreeToLowMark(lowmark);
            return 0;
		}

		tex->width = LittleLong(tex->width);
		tex->height = LittleLong(tex->height);

		if (tex->width != mt->width || tex->height != mt->height)
		{
			Hunk_FreeToLowMark(lowmark);
			return 0;
		}

		for (j = 0;j < MIPLEVELS;j++)
			tex->offsets[j] = LittleLong(tex->offsets[j]);

	    index = ConvertWad3ToRGBA(tex);

		Hunk_FreeToLowMark(lowmark);

	    return index;
	}
 	return  0;
}

int WAD3_LoadTextureName(char *name)
{
	char texname[MAX_QPATH];
	int i, j, lowmark = 0;
	FILE *file;
    miptex_t *tex;
	int index;

	texname[sizeof(texname) - 1] = 0;
    W_CleanupName (name, texname);

	for (i = 0;i < numwadtextures;i++)
	{
		if (!texwadlump[i].name[0])
			break;

	    if (strcmp(texname, texwadlump[i].name))
			continue;

		file = texwadlump[i].file;

		if (fseek(file, texwadlump[i].position, SEEK_SET))
		{
			fclose(file);
			Con_Printf("WAD3_LoadTexture: corrupt WAD3 file");
            return 0;
		}

		lowmark = Hunk_LowMark();
		tex = static_cast<miptex_t*>(Hunk_Alloc(texwadlump[i].size));

		if (fread(tex, 1, texwadlump[i].size, file) < texwadlump[i].size)
		{
            Con_Printf("WAD3_LoadTexture: corrupt WAD3 file");
            fclose(file);
			Hunk_FreeToLowMark(lowmark);
            return 0;
		}

		tex->width = LittleLong(tex->width);
		tex->height = LittleLong(tex->height);
#if 0
		if (tex->width != mt->width || tex->height != mt->height)
		{
            fclose(file);
			Hunk_FreeToLowMark(lowmark);
			return 0;
		}
#endif
		for (j = 0;j < MIPLEVELS;j++)
			tex->offsets[j] = LittleLong(tex->offsets[j]);

	    index = ConvertWad3ToRGBA(tex);

		UnloadFileList.push_back(file); //Crow_bar. UnloadWads code
/*
        fclose(file);
*/
		Hunk_FreeToLowMark(lowmark);

	    return index;
	}
 	return  0;
}

//Other wad3 loaders
void W_LoadTextureWadFileHL (char *filename, int complain)
{
	lumpinfo_t		*lumps, *lump_p;
	wadinfo_t		header;
	unsigned		i, j;
	int				infotableofs;
	FILE			*file;
	int				numlumps;

	FS_FOpenFile (filename, &file);
	if (!file)
	{
		if (complain)
			Con_Printf ("W_LoadTextureWadFile: couldn't find %s\n", filename);
		return;
	}

	if (fread(&header, sizeof(wadinfo_t), 1, file) != 1)
	{Con_Printf ("W_LoadTextureWadFile: unable to read wad header");return;}

	if(header.identification[0] != 'W'
	|| header.identification[1] != 'A'
	|| header.identification[2] != 'D'
	|| header.identification[3] != '3')
	{
		fclose(file);
		Con_Printf ("W_LoadTextureWadFile: Wad file %s doesn't have WAD3 id\n",filename);
		return;
	}

	numlumps = LittleLong(header.numlumps);

	if (numlumps < 1 || numlumps > TEXWAD_MAXIMAGES)
	{
    fclose(file);
	Con_Printf ("W_LoadTextureWadFile: invalid number of lumps (%i)\n", numlumps);
	return;
	}
	infotableofs = LittleLong(header.infotableofs);

	if (fseek(file, infotableofs, SEEK_SET))
	{
    fclose(file);
	Con_Printf ("W_LoadTextureWadFile: unable to seek to lump table");
	return;
	}

	if (!(lumps = static_cast<lumpinfo_t*>(malloc(sizeof(lumpinfo_t)*numlumps))))
	{
    fclose(file);
	Con_Printf ("W_LoadTextureWadFile: unable to allocate temporary memory for lump table");
	return;
	}

	if (fread(lumps, sizeof(lumpinfo_t), numlumps, file) != (unsigned)numlumps)
	{
    fclose(file);
	Con_Printf ("W_LoadTextureWadFile: unable to read lump table");
	return;
	}

	for (i=0, lump_p = lumps ; i<(unsigned)numlumps ; i++,lump_p++)
	{
		W_CleanupName (lump_p->name, lump_p->name);
		for (j = 0;j < TEXWAD_MAXIMAGES;j++)
		{
			if (texwadlump[j].name[0]) // occupied slot, check the name
			{
				if (!strcmp(lump_p->name, texwadlump[j].name)) // name match, replace old one
					break;
			}
			else // empty slot
				break;
		}
		if (j >= TEXWAD_MAXIMAGES)
			break; // abort loading

		W_CleanupName (lump_p->name, texwadlump[j].name);
		texwadlump[j].file = file;
		texwadlump[j].position = LittleLong(lump_p->filepos);
		texwadlump[j].size = LittleLong(lump_p->disksize);
	}
	free(lumps);
    //fclose(file);
	// leaves the file open
}

byte *W_ConvertWAD3TextureHL(miptex_t *tex)
{
	byte	*in, *data, *out, *pal;
	int		d, p, image_size;

	in		= (byte *)((int) tex + tex->offsets[0]);
	data	= out = static_cast<byte*>(malloc(tex->width * tex->height * 4));

	if (!data)
		return NULL;

	image_size = tex->width * tex->height;

	pal				= in + (((image_size) * 85) >> 6);
	pal				+= 2;

	for (d = 0;d < image_size;d++)
	{
		p = *in++;
		if (tex->name[0] == '{' && p == 255)
			out[0] = out[1] = out[2] = out[3] = 0;
		else
		{
			p *= 3;
			out[0] = pal[p];
			out[1] = pal[p+1];
			out[2] = pal[p+2];
			out[3] = 255;
		}
		out += 4;
	}
	return data;
}

byte *W_GetTextureHL(char *name)
{
	char		texname[17];
	int			i, j;
	FILE		*file;
	miptex_t	*tex;
	byte		*data;

	texname[16] = 0;

	W_CleanupName (name, texname);

	for (i = 0;i < TEXWAD_MAXIMAGES;i++)
	{
		if (texwadlump[i].name[0])
		{
			if (!strcmp(texname, texwadlump[i].name)) // found it
			{
				file = texwadlump[i].file;
				if (fseek(file, texwadlump[i].position, SEEK_SET))
				{
					Con_Printf("W_GetTexture: corrupt WAD3 file");
					return NULL;
				}

				tex = static_cast<miptex_t*>(malloc(texwadlump[i].size));

				if (!tex)
					return NULL;

				if (fread(tex, 1, texwadlump[i].size, file) < (unsigned)texwadlump[i].size)
				{
					Con_Printf("W_GetTexture: corrupt WAD3 file");
					return NULL;
				}

				tex->width = LittleLong(tex->width);
				tex->height = LittleLong(tex->height);
				for (j = 0;j < MIPLEVELS;j++)
					tex->offsets[j] = LittleLong(tex->offsets[j]);

				data = W_ConvertWAD3TextureHL(tex);

				free(tex);
                fclose(file);
				return data;
			}
		}
		else
			break;
	}

	return NULL;
}
