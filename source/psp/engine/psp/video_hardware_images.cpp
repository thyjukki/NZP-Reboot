/*
Copyright (C) 2008-2009 Crow_bar.

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

#include <png.h>

extern "C"
{
#include <jpeglib.h>
#include "../quakedef.h"
}

cvar_t	jpeg_compression_level = {"jpeg_compression_level", "75"};

int		    image_width;
int		    image_height;
static int  image_palette_type = 0;
static byte image_palette[1024];


#define	IMAGE_MAX_DIMENSIONS	4096

/*
=============
LoadJPG
=============
*/
byte *LoadJPG (FILE *fin, int matchwidth, int matchheight)
{
	int	i, row_stride;
	byte	*data, *scanline, *p;
	struct jpeg_decompress_struct cinfo;
	struct jpeg_error_mgr jerr;

	cinfo.err = jpeg_std_error (&jerr);
	jpeg_create_decompress (&cinfo);
	jpeg_stdio_src (&cinfo, fin);
	jpeg_read_header (&cinfo, true);
	jpeg_start_decompress (&cinfo);

	if (cinfo.image_width > IMAGE_MAX_DIMENSIONS || cinfo.image_height > IMAGE_MAX_DIMENSIONS)
	{
		return NULL;
	}

	if ((matchwidth && cinfo.image_width != matchwidth) || (matchheight && cinfo.image_height != matchheight))
	{
		jpeg_finish_decompress (&cinfo);
		jpeg_destroy_decompress (&cinfo);
		return NULL;
	}

	Con_Printf("JPG: Allocating data\n");
	
	data = static_cast<byte*>(malloc (cinfo.image_width * cinfo.image_height * 4));
	row_stride = cinfo.output_width * cinfo.output_components;
	scanline = static_cast<byte*>(malloc (row_stride));

	Con_Printf("JPG: done allocating data\n");
	
	p = data;
	while (cinfo.output_scanline < cinfo.output_height)
	{
		jpeg_read_scanlines (&cinfo, &scanline, 1);

		// convert the image to RGBA
		switch (cinfo.output_components)
		{
		// RGB images
		case 3:
			for (i=0 ; i<row_stride ; )
			{
				*p++ = scanline[i++];
				*p++ = scanline[i++];
				*p++ = scanline[i++];
				*p++ = 255;
			}
			break;

		// greyscale images (default to it, just in case)
		case 1:
		default:
			for (i=0 ; i<row_stride ; i++)
			{
				*p++ = scanline[i];
				*p++ = scanline[i];
				*p++ = scanline[i];
				*p++ = 255;
			}
			break;
		}
	}

	image_width = cinfo.image_width;
	image_height = cinfo.image_height;

	jpeg_finish_decompress (&cinfo);
	jpeg_destroy_decompress (&cinfo);
	free (scanline);
	fclose (fin);

	return data;
}

/*
=============
Image_WriteJPEG
=============
*/
int Image_WriteJPEG (char *filename, int compression, byte *pixels, int width, int height)
{
	char	name[MAX_OSPATH];
	byte	*scanline;
	FILE	*fout;
	struct jpeg_compress_struct cinfo;
	struct jpeg_error_mgr jerr;

	Q_snprintfz (name, MAX_OSPATH, "%s/%s", com_gamedir, filename);

	if (!(fout = fopen(name, "wb")))
	{
		COM_CreatePath (name);
		if (!(fout = fopen(name, "wb")))
			return false;
	}

	cinfo.err = jpeg_std_error (&jerr);
	jpeg_create_compress (&cinfo);
	jpeg_stdio_dest (&cinfo, fout);

	cinfo.image_width = abs(width);
	cinfo.image_height = height;
	cinfo.input_components = 3;
	cinfo.in_color_space = JCS_RGB;

	jpeg_set_defaults (&cinfo);
	jpeg_set_quality (&cinfo, bound(0, compression, 100), true);
	jpeg_start_compress (&cinfo, true);

	while (cinfo.next_scanline < height)
	{
		scanline = &pixels[cinfo.next_scanline*width*3];
		jpeg_write_scanlines (&cinfo, &scanline, 1);
	}

	jpeg_finish_compress (&cinfo);
	jpeg_destroy_compress (&cinfo);
	fclose (fout);

	return true;
}

/*
=================================================================

  PCX Loading
  mem fix by Crow_bar.
=================================================================
*/

typedef struct
{
    char	manufacturer;
    char	version;
    char	encoding;
    char	bits_per_pixel;
    unsigned short	xmin,ymin,xmax,ymax;
    unsigned short	hres,vres;
    unsigned char	palette[48];
    char	reserved;
    char	color_planes;
    unsigned short	bytes_per_line;
    unsigned short	palette_type;
    char	filler[58];
    unsigned char	data;			// unbounded
} pcx_t;

byte* LoadPCX (FILE *f, int matchwidth, int matchheight)
{
	pcx_t	*pcx, pcxbuf;
	byte	palette[768];
	byte	*pix, *image_rgba;
	int		x, y;
	int		dataByte, runLength;
	int		count;

//
// parse the PCX file
//
	fread (&pcxbuf, 1, sizeof(pcxbuf), f);

	pcx = &pcxbuf;

	if (pcx->manufacturer != 0x0a
		|| pcx->version != 5
		|| pcx->encoding != 1
		|| pcx->bits_per_pixel != 8
		|| pcx->xmax >= 320
		|| pcx->ymax >= 256)
	{
		Con_Printf ("Bad pcx file\n");
		return NULL;
	}

	if (matchwidth && (pcx->xmax+1) != matchwidth)
	{
	    fclose (f);
		return NULL;
	}

	if (matchheight && (pcx->ymax+1) != matchheight)
	{
		fclose (f);
		return NULL;
	}

	// seek to palette
	fseek (f, -768, SEEK_END);
	fread (palette, 1, 768, f);

	fseek (f, sizeof(pcxbuf) - 4, SEEK_SET);

	count = (pcx->xmax+1) * (pcx->ymax+1);

	image_rgba = static_cast<byte*>(malloc( count ));

	for (y=0 ; y<=pcx->ymax ; y++)
	{
		pix = image_rgba + y  * (pcx->xmax+1);
		for (x=0 ; x<=pcx->xmax ; ) // muff - fixed - was referencing ymax
		{
			dataByte = fgetc(f);

			if((dataByte & 0xC0) == 0xC0)
			{
				runLength = dataByte & 0x3F;
				dataByte = fgetc(f);
			}
			else
				runLength = 1;

			while(runLength-- > 0)
				pix[x++] = dataByte;
		}
	}
	image_width = pcx->xmax+1;
	image_height = pcx->ymax+1;

	memcpy(image_palette, palette, sizeof(palette));
	image_palette_type = PAL_RGB;

	fclose (f);

	return image_rgba;
}

/*
================
LoadWal
================
*/

typedef struct miptexq2_s
{
	char		name[32];
	unsigned	width, height;
	unsigned	offsets[4];		// four mip maps stored
	char		animname[32];			// next frame in animation chain
	int			flags;
	int			contents;
	int			value;
} miptexq2_t;

byte *LoadWAL (char *name)
{
	miptexq2_t	*mt;
	int			width, height, ofs, size;
	byte        *data;

	mt = (miptexq2_t*)COM_LoadFile (name, 0);
	if (!mt)
	{
	      return NULL;
	}

	width = LittleLong (mt->width);
	height = LittleLong (mt->height);
	ofs = LittleLong (mt->offsets[0]);

	size = width * height;

	data = static_cast<byte*>(malloc(size));
	memcpy(data, (byte *)mt + ofs, size);

	image_palette_type = PAL_Q2;

	Z_Free(mt);

	return data;
}

/*
=========================================================

			Targa

=========================================================
*/

#define TGA_MAXCOLORS 16384

/* Definitions for image types. */
#define TGA_Null	0	/* no image data */
#define TGA_Map		1	/* Uncompressed, color-mapped images. */
#define TGA_RGB		2	/* Uncompressed, RGB images. */
#define TGA_Mono	3	/* Uncompressed, black and white images. */
#define TGA_RLEMap	9	/* Runlength encoded color-mapped images. */
#define TGA_RLERGB	10	/* Runlength encoded RGB images. */
#define TGA_RLEMono	11	/* Compressed, black and white images. */
#define TGA_CompMap	32	/* Compressed color-mapped data, using Huffman, Delta, and runlength encoding. */
#define TGA_CompMap4	33	/* Compressed color-mapped data, using Huffman, Delta, and runlength encoding. 4-pass quadtree-type process. */

/* Definitions for interleave flag. */
#define TGA_IL_None	0	/* non-interleaved. */
#define TGA_IL_Two	1	/* two-way (even/odd) interleaving */
#define TGA_IL_Four	2	/* four way interleaving */
#define TGA_IL_Reserved	3	/* reserved */

/* Definitions for origin flag */
#define TGA_O_UPPER	0	/* Origin in lower left-hand corner. */
#define TGA_O_LOWER	1	/* Origin in upper left-hand corner. */

typedef struct _TargaHeader
{
	unsigned char 	id_length, colormap_type, image_type;
	unsigned short	colormap_index, colormap_length;
	unsigned char	colormap_size;
	unsigned short	x_origin, y_origin, width, height;
	unsigned char	pixel_size, attributes;
} TargaHeader;

int fgetLittleShort (FILE *f)
{
	byte	b1, b2;

	b1 = fgetc(f);
	b2 = fgetc(f);

	return (short)(b1 + b2*256);
}

int fgetLittleLong (FILE *f)
{
	byte	b1, b2, b3, b4;

	b1 = fgetc(f);
	b2 = fgetc(f);
	b3 = fgetc(f);
	b4 = fgetc(f);

	return b1 + (b2<<8) + (b3<<16) + (b4<<24);
}

/*
=============
LoadTGA
=============
*/
byte *LoadTGA (FILE *fin, int matchwidth, int matchheight)
{
	int		w, h, x, y, realrow, truerow, baserow, i, temp1, temp2, pixel_size, map_idx;
	int		RLE_count, RLE_flag, size, interleave, origin;
	bool	mapped, rlencoded;
	byte		*data, *dst, r, g, b, a, j, k, l, *ColorMap;
	TargaHeader	header;

	header.id_length = fgetc (fin);
	header.colormap_type = fgetc (fin);
	header.image_type = fgetc (fin);
	header.colormap_index = fgetLittleShort (fin);
	header.colormap_length = fgetLittleShort (fin);
	header.colormap_size = fgetc (fin);
	header.x_origin = fgetLittleShort (fin);
	header.y_origin = fgetLittleShort (fin);
	header.width = fgetLittleShort (fin);
	header.height = fgetLittleShort (fin);
	header.pixel_size = fgetc (fin);
	header.attributes = fgetc (fin);

	if (header.width > IMAGE_MAX_DIMENSIONS || header.height > IMAGE_MAX_DIMENSIONS)
	{
		Con_DPrintf ("TGA image %s exceeds maximum supported dimensions\n");
		fclose (fin);
		return NULL;
	}

	if ((matchwidth && header.width != matchwidth) || (matchheight && header.height != matchheight))
	{
		fclose (fin);
		return NULL;
	}

	if (header.id_length != 0)
		fseek (fin, header.id_length, SEEK_CUR);

	/* validate TGA type */
	switch (header.image_type)
	{
	case TGA_Map:
	case TGA_RGB:
	case TGA_Mono:
	case TGA_RLEMap:
	case TGA_RLERGB:
	case TGA_RLEMono:
		break;

	default:
		Con_DPrintf ("Unsupported TGA image %s: Only type 1 (map), 2 (RGB), 3 (mono), 9 (RLEmap), 10 (RLERGB), 11 (RLEmono) TGA images supported\n");
		fclose (fin);
		return NULL;
	}

	/* validate color depth */
	switch (header.pixel_size)
	{
	case 8:
	case 15:
	case 16:
	case 24:
	case 32:
		break;

	default:
		Con_DPrintf ("Unsupported TGA image %s: Only 8, 15, 16, 24 or 32 bit images (with colormaps) supported\n");
		fclose (fin);
		return NULL;
	}

	r = g = b = a = l = 0;

	/* if required, read the color map information. */
	ColorMap = NULL;
	mapped = (header.image_type == TGA_Map || header.image_type == TGA_RLEMap) && header.colormap_type == 1;
	if (mapped)
	{
		/* validate colormap size */
		switch (header.colormap_size)
		{
		case 8:
		case 15:
		case 16:
		case 32:
		case 24:
			break;

		default:
			Con_DPrintf ("Unsupported TGA image %s: Only 8, 15, 16, 24 or 32 bit colormaps supported\n");
			fclose (fin);
			return NULL;
		}

		temp1 = header.colormap_index;
		temp2 = header.colormap_length;
		if ((temp1 + temp2 + 1) >= TGA_MAXCOLORS)
		{
			fclose (fin);
			return NULL;
		}
		ColorMap = static_cast<byte*>(malloc (TGA_MAXCOLORS * 4));
		map_idx = 0;
		for (i = temp1 ; i < temp1 + temp2 ; ++i, map_idx += 4)
		{
			/* read appropriate number of bytes, break into rgb & put in map. */
			switch (header.colormap_size)
			{
			case 8:	/* grey scale, read and triplicate. */
				r = g = b = getc (fin);
				a = 255;
				break;

			case 15:	/* 5 bits each of red green and blue. */
						/* watch byte order. */
				j = getc (fin);
				k = getc (fin);
				l = ((unsigned int)k << 8) + j;
				r = (byte)(((k & 0x7C) >> 2) << 3);
				g = (byte)((((k & 0x03) << 3) + ((j & 0xE0) >> 5)) << 3);
				b = (byte)((j & 0x1F) << 3);
				a = 255;
				break;

			case 16:	/* 5 bits each of red green and blue, 1 alpha bit. */
						/* watch byte order. */
				j = getc (fin);
				k = getc (fin);
				l = ((unsigned int)k << 8) + j;
				r = (byte)(((k & 0x7C) >> 2) << 3);
				g = (byte)((((k & 0x03) << 3) + ((j & 0xE0) >> 5)) << 3);
				b = (byte)((j & 0x1F) << 3);
				a = (k & 0x80) ? 255 : 0;
				break;

			case 24:	/* 8 bits each of blue, green and red. */
				b = getc (fin);
				g = getc (fin);
				r = getc (fin);
				a = 255;
				l = 0;
				break;

			case 32:	/* 8 bits each of blue, green, red and alpha. */
				b = getc (fin);
				g = getc (fin);
				r = getc (fin);
				a = getc (fin);
				l = 0;
				break;
			}
			ColorMap[map_idx+0] = r;
			ColorMap[map_idx+1] = g;
			ColorMap[map_idx+2] = b;
			ColorMap[map_idx+3] = a;
		}
	}

	/* check run-length encoding. */
	rlencoded = (header.image_type == TGA_RLEMap || header.image_type == TGA_RLERGB || header.image_type == TGA_RLEMono);
	RLE_count = RLE_flag = 0;

	image_width = w = header.width;
	image_height = h = header.height;

	size = w * h * 4;
	data = static_cast<byte*>(calloc (size, 1));

	/* read the Targa file body and convert to portable format. */
	pixel_size = header.pixel_size;
	origin = (header.attributes & 0x20) >> 5;
	interleave = (header.attributes & 0xC0) >> 6;
	truerow = baserow = 0;
	for (y=0 ; y<h ; y++)
	{
		realrow = truerow;
		if (origin == TGA_O_UPPER)
			realrow = h - realrow - 1;

		dst = data + realrow * w * 4;

		for (x=0 ; x<w ; x++)
		{
			/* check if run length encoded. */
			if (rlencoded)
			{
				if (!RLE_count)
				{
					/* have to restart run. */
					i = getc (fin);
					RLE_flag = (i & 0x80);
					if (!RLE_flag)	// stream of unencoded pixels
						RLE_count = i + 1;
					else		// single pixel replicated
						RLE_count = i - 127;
					/* decrement count & get pixel. */
					--RLE_count;
				}
				else
				{
					/* have already read count & (at least) first pixel. */
					--RLE_count;
					if (RLE_flag)
						/* replicated pixels. */
						goto PixEncode;
				}
			}

			/* read appropriate number of bytes, break into RGB. */
			switch (pixel_size)
			{
			case 8:	/* grey scale, read and triplicate. */
				r = g = b = l = getc (fin);
				a = 255;
				break;

			case 15:	/* 5 bits each of red green and blue. */
						/* watch byte order. */
				j = getc (fin);
				k = getc (fin);
				l = ((unsigned int)k << 8) + j;
				r = (byte)(((k & 0x7C) >> 2) << 3);
				g = (byte)((((k & 0x03) << 3) + ((j & 0xE0) >> 5)) << 3);
				b = (byte)((j & 0x1F) << 3);
				a = 255;
				break;

			case 16:	/* 5 bits each of red green and blue, 1 alpha bit. */
						/* watch byte order. */
				j = getc (fin);
				k = getc (fin);
				l = ((unsigned int)k << 8) + j;
				r = (byte)(((k & 0x7C) >> 2) << 3);
				g = (byte)((((k & 0x03) << 3) + ((j & 0xE0) >> 5)) << 3);
				b = (byte)((j & 0x1F) << 3);
				a = (k & 0x80) ? 255 : 0;
				break;

			case 24:	/* 8 bits each of blue, green and red. */
				b = getc (fin);
				g = getc (fin);
				r = getc (fin);
				a = 255;
				l = 0;
				break;

			case 32:	/* 8 bits each of blue, green, red and alpha. */
				b = getc (fin);
				g = getc (fin);
				r = getc (fin);
				a = getc (fin);
				l = 0;
				break;

			default:
				Con_DPrintf ("Malformed TGA image: Illegal pixel_size '%d'\n", pixel_size);
				fclose (fin);
				free (data);
				if (mapped)
					free (ColorMap);
				return NULL;
			}

PixEncode:
			if (mapped)
			{
				map_idx = l * 4;
				*dst++ = ColorMap[map_idx+0];
				*dst++ = ColorMap[map_idx+1];
				*dst++ = ColorMap[map_idx+2];
				*dst++ = ColorMap[map_idx+3];
			}
			else
			{
				*dst++ = r;
				*dst++ = g;
				*dst++ = b;
				*dst++ = a;
			}
		}

		if (interleave == TGA_IL_Four)
			truerow += 4;
		else if (interleave == TGA_IL_Two)
			truerow += 2;
		else
			truerow++;
		if (truerow >= h)
			truerow = ++baserow;
	}

	if (mapped)
		free (ColorMap);

	fclose (fin);

	return data;
}

/*
=========================================================

			PNG

=========================================================
*/

static void PNG_IO_user_read_data (png_structp png_ptr, png_bytep data, png_size_t length)
{
	FILE	*f = (FILE *)png_get_io_ptr(png_ptr);

	fread (data, 1, length, f);
}

/*
static void PNG_IO_user_write_data (png_structp png_ptr, png_bytep data, png_size_t length)
{
	FILE	*f = (FILE *)png_get_io_ptr(png_ptr);

	fwrite (data, 1, length, f);
}

static void PNG_IO_user_flush_data (png_structp png_ptr)
{
	FILE	*f = (FILE *)png_get_io_ptr(png_ptr);

	fflush (f);
}
*/

/*
=============
LoadPNG
=============
*/
byte *LoadPNG (FILE *fin, int matchwidth, int matchheight)
{
	int		y, width, height, bitdepth, colortype;
	int		interlace, compression, filter, bytesperpixel;
	byte		header[8], **rowpointers, *data;
	png_structp	png_ptr;
	png_infop	pnginfo;
	unsigned long	rowbytes;

	fread (header, 1, 8, fin);

	if (png_sig_cmp(header, 0, 8))
	{
		Con_DPrintf ("Invalid PNG image\n");
		fclose (fin);
		return NULL;
	}

	if (!(png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL)))
	{
		fclose (fin);
		return NULL;
	}

	if (!(pnginfo = png_create_info_struct(png_ptr)))
	{
		png_destroy_read_struct (&png_ptr, &pnginfo, NULL);
		fclose (fin);
		return NULL;
	}

	/* naievil -- invalid use of incomplete type
	if (setjmp(png_ptr->jmpbuf))
	{
		png_destroy_read_struct (&png_ptr, &pnginfo, NULL);
		fclose (fin);
		return NULL;
	}
	*/

	png_set_read_fn (png_ptr, fin, PNG_IO_user_read_data);
	png_set_sig_bytes (png_ptr, 8);
	png_read_info (png_ptr, pnginfo);
	png_get_IHDR (png_ptr, pnginfo, (png_uint_32 *)&width, (png_uint_32 *)&height, &bitdepth, &colortype, &interlace, &compression, &filter);

	if (width > IMAGE_MAX_DIMENSIONS || height > IMAGE_MAX_DIMENSIONS)
	{
		Con_DPrintf ("PNG image  exceeds maximum supported dimensions\n");
		png_destroy_read_struct (&png_ptr, &pnginfo, NULL);
		fclose (fin);
		return NULL;
	}

	if ((matchwidth && width != matchwidth) || (matchheight && height != matchheight))
	{
		png_destroy_read_struct (&png_ptr, &pnginfo, NULL);
		fclose (fin);
		return NULL;
	}

	if (colortype == PNG_COLOR_TYPE_PALETTE)
	{
		png_set_palette_to_rgb (png_ptr);
		png_set_filler (png_ptr, 255, PNG_FILLER_AFTER);
	}

	if (colortype == PNG_COLOR_TYPE_GRAY && bitdepth < 8)
		png_set_expand_gray_1_2_4_to_8 (png_ptr);

	if (png_get_valid(png_ptr, pnginfo, PNG_INFO_tRNS))
		png_set_tRNS_to_alpha (png_ptr);

	if (colortype == PNG_COLOR_TYPE_GRAY || colortype == PNG_COLOR_TYPE_GRAY_ALPHA)
		png_set_gray_to_rgb (png_ptr);

	if (colortype != PNG_COLOR_TYPE_RGBA)
		png_set_filler (png_ptr, 255, PNG_FILLER_AFTER);

	if (bitdepth < 8)
		png_set_expand (png_ptr);
	else if (bitdepth == 16)
		png_set_strip_16 (png_ptr);

	png_read_update_info (png_ptr, pnginfo);
	rowbytes = png_get_rowbytes (png_ptr, pnginfo);
	bytesperpixel = png_get_channels (png_ptr, pnginfo);
	bitdepth = png_get_bit_depth (png_ptr, pnginfo);

	if (bitdepth != 8 || bytesperpixel != 4)
	{
		Con_DPrintf ("Unsupported PNG image: Bad color depth and/or bpp\n");
		png_destroy_read_struct (&png_ptr, &pnginfo, NULL);
		fclose (fin);
		return NULL;
	}

	data = static_cast<byte*>(malloc (height * rowbytes));
	rowpointers = static_cast<byte**>(malloc (height * sizeof(*rowpointers)));

	for (y=0 ; y<height ; y++)
		rowpointers[y] = data + y * rowbytes;

	image_width = width;
	image_height = height;

	png_read_image (png_ptr, rowpointers);
	png_read_end (png_ptr, NULL);
	png_destroy_read_struct (&png_ptr, &pnginfo, NULL);
	free (rowpointers);
	fclose (fin);

	return data;
}

/*
=========================================================
BMP LOADING
from Q3,
modify by Crow_bar!
=========================================================
*/
typedef struct
{
	char id[2];
	unsigned long fileSize;
	unsigned long reserved0;
	unsigned long bitmapDataOffset;
	unsigned long bitmapHeaderSize;
	unsigned long width;
	unsigned long height;
	unsigned short planes;
	unsigned short bitsPerPixel;
	unsigned long compression;
	unsigned long bitmapDataSize;
	unsigned long hRes;
	unsigned long vRes;
	unsigned long colors;
	unsigned long importantColors;
	unsigned char palette[256][4];
} BMPHeader_t;

/*
=============
LoadBMP
=============
*/
byte *LoadBMP (FILE *fin, int matchwidth, int matchheight)
{
	int		columns, rows, numPixels;
	byte	*pixbuf;
	int		row, column;
	BMPHeader_t bmpHeader;
	byte		*bmpRGBA;


	bmpHeader.id[0]            = fgetc(fin);
	bmpHeader.id[1]            = fgetc(fin);
	bmpHeader.fileSize         = fgetLittleLong(fin);
	bmpHeader.reserved0        = fgetLittleLong(fin);
	bmpHeader.bitmapDataOffset = fgetLittleLong(fin);
	bmpHeader.bitmapHeaderSize = fgetLittleLong(fin);
	bmpHeader.width            = fgetLittleLong(fin);
	bmpHeader.height           = fgetLittleLong(fin);
	bmpHeader.planes           = fgetLittleShort(fin);
	bmpHeader.bitsPerPixel     = fgetLittleShort(fin);
	bmpHeader.compression      = fgetLittleLong(fin);
	bmpHeader.bitmapDataSize   = fgetLittleLong(fin);
	bmpHeader.hRes             = fgetLittleLong(fin);
	bmpHeader.vRes             = fgetLittleLong(fin);
	bmpHeader.colors           = fgetLittleLong(fin);
	bmpHeader.importantColors  = fgetLittleLong(fin);

	if ((matchwidth && bmpHeader.width != matchwidth) || (matchheight && bmpHeader.height != matchheight))
	{
		fclose (fin);
		return NULL;
	}

	//if (bmpHeader.fileSize != 0 )
	//{
	//	fseek (fin, bmpHeader.fileSize, SEEK_CUR);
	//}
	if ( bmpHeader.bitsPerPixel == 8 )
	{
		//buf_p += 1024;
		memcpy( bmpHeader.palette, (const void*)fgetc(fin), sizeof( bmpHeader.palette ) );
		//Con_Printf("Not support 8bpp\n");
	}
	if ( bmpHeader.id[0] != 'B' && bmpHeader.id[1] != 'M' )
	{
		Sys_Error("LoadBMP: only Windows-style BMP files supported \n");
	}

	if ( bmpHeader.compression != 0 )
	{
		Sys_Error("LoadBMP: only uncompressed BMP files supported \n");
	}
	if ( bmpHeader.bitsPerPixel < 8 )
	{
		Sys_Error("LoadBMP: monochrome and 4-bit BMP files not supported \n");
	}

	image_width  = columns = bmpHeader.width;
	image_height = rows    = bmpHeader.height;

	if ( rows < 0 )
		rows = -rows;

	numPixels = columns * rows;

	bmpRGBA = static_cast<byte*>(malloc(numPixels * 4));

	for ( row = rows-1; row >= 0; row-- )
	{
		pixbuf = bmpRGBA + row*columns*4;

		for ( column = 0; column < columns; column++ )
		{
			unsigned char red, green, blue, alpha;
			int palIndex;
			unsigned short shortPixel;

			switch ( bmpHeader.bitsPerPixel )
			{
			case 8:
				palIndex  = getc(fin);
				*pixbuf++ = bmpHeader.palette[palIndex][2];
				*pixbuf++ = bmpHeader.palette[palIndex][1];
				*pixbuf++ = bmpHeader.palette[palIndex][0];
				*pixbuf++ = 0xff;
				break;
			case 16:
				shortPixel = * ( unsigned short * ) pixbuf;
				pixbuf += 2;
				*pixbuf++ = ( shortPixel & ( 31 << 10 ) ) >> 7;
				*pixbuf++ = ( shortPixel & ( 31 << 5 ) ) >> 2;
				*pixbuf++ = ( shortPixel & ( 31 ) ) << 3;
				*pixbuf++ = 0xff;
				break;

			case 24:
				blue  = getc (fin);
				green = getc (fin);
				red   = getc (fin);
				*pixbuf++ = red;
				*pixbuf++ = green;
				*pixbuf++ = blue;
				*pixbuf++ = 255;
				break;
			case 32:
				blue  = getc (fin);
				green = getc (fin);
				red   = getc (fin);
				alpha = getc (fin);
				*pixbuf++ = red;
				*pixbuf++ = green;
				*pixbuf++ = blue;
				*pixbuf++ = alpha;
				break;
			default:
				Sys_Error("LoadBMP: illegal pixel_size '%d' in file\n", bmpHeader.bitsPerPixel);
				break;
			}
		}
	}

	fclose(fin);

	return bmpRGBA;
}

/*
=============
loadimagepixels
=============
*/
byte* loadimagepixels (char* filename, qboolean complain, int matchwidth, int matchheight)
{
	FILE	*f;
	char	basename[128], name[128];
	byte	 *c;
	COM_StripExtension(filename, basename); // strip the extension to allow TGA and PCX
	c = (byte*)(basename);

	while (*c)
	{
		if (*c == '*')
			*c = '+';
		c++;
	}

	com_netpath[0] = 0;
/*
    sprintf (name, "%s.wal", basename);
	if (data = LoadWAL(name))
		return data;
*/

	sprintf (name, "%s.tga", basename);
	FS_FOpenFile (name, &f);
	if (f)
		return LoadTGA (f, matchwidth, matchheight);
		
	sprintf (name, "%s.pcx", basename);
	FS_FOpenFile (name, &f);
	if (f)
		return LoadPCX (f, matchwidth, matchheight);
	
	sprintf (name, "%s.jpg", basename);
	FS_FOpenFile (name, &f);
	if (f)
	{
		return LoadJPG (f, matchwidth, matchheight);
	}
	sprintf (name, "%s.png", basename);
	FS_FOpenFile (name, &f);
	if (f)
		return LoadPNG (f, matchwidth, matchheight);
	
	sprintf (name, "%s.bmp", basename);
	FS_FOpenFile (name, &f);
	if (f)
		return LoadBMP (f, matchwidth, matchheight);
	if (complain)
		Con_Printf ("Couldn't load %s .tga .jpg .bmp .png \n", filename);
	
	return NULL;
}

/*
=============
loadtextureimage
=============
*/

int loadtextureimage (char* filename, int matchwidth, int matchheight, qboolean complain, int filter)
{
	int texture_index;
	byte *data;
	data = loadimagepixels (filename, complain, matchwidth, matchheight);
	if(!data)
	{
		return 0;
	}
	
	if(image_palette_type)
	{
		texture_index = GL_LoadPalTex (filename, image_width, image_height, data, qtrue, filter, 0, (byte *)image_palette, image_palette_type);
		memset(image_palette, 0, sizeof(image_palette)); // clear temp pal
		image_palette_type = 0;
	}
	else
	{
		texture_index = GL_LoadImages (filename, image_width, image_height, data, qtrue, filter, 0, 4);
	}
	free(data);
	return texture_index;
}
