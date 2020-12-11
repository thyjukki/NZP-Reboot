/*
Copyright (C) 1996-2003 A Nourai, Id Software, Inc.

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
// image.h

extern	int	image_width, image_height;

extern	cvar_t	png_compression_level, jpeg_compression_level;

int Image_WriteTGA (char *filename, byte *pixels, int width, int height);
int Image_WritePNG (char *filename, int compression, byte *pixels, int width, int height);
int Image_WritePNGPLTE (char *filename, int compression, byte *pixels, int width, int height, byte *palette);
int Image_WriteJPEG (char *filename, int compression, byte *pixels, int width, int height);
int Image_WritePCX (char *filename, byte *data, int width, int height, byte *palette);

