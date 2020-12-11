#include <malloc.h>
#include <pspgu.h>

extern "C"
{
#include "../quakedef.h"
}

#define LERPBYTE(i) r = row1[i]; out[i] = (byte) ((((row2[i] - r) * lerp) >> 16) + r)
#define NOLERPBYTE(i) *out++ = inrow[f + i]

/*
================
Image_Resample32LerpLine
================
*/
static void Image_Resample32LerpLine (byte *in, byte *out, int inwidth, int outwidth)
{
	int j, xi, oldx = 0, f, fstep, endx, lerp;

	fstep = (int) (inwidth * 65536.0f / outwidth);
	endx = (inwidth - 1);
	for (j = 0, f = 0; j < outwidth; j++, f += fstep) {
		xi = (int) f >> 16;
		if (xi != oldx) {
			in += (xi - oldx) * 4;
			oldx = xi;
		}
		if (xi < endx) {
			lerp = f & 0xFFFF;
			*out++ = (byte) ((((in[4] - in[0]) * lerp) >> 16) + in[0]);
			*out++ = (byte) ((((in[5] - in[1]) * lerp) >> 16) + in[1]);
			*out++ = (byte) ((((in[6] - in[2]) * lerp) >> 16) + in[2]);
			*out++ = (byte) ((((in[7] - in[3]) * lerp) >> 16) + in[3]);
		} else  {
			*out++ = in[0];
			*out++ = in[1];
			*out++ = in[2];
			*out++ = in[3];
		}
	}
}

/*
================
Image_Resample32
================
*/
static void Image_Resample32 (void *indata, int inwidth, int inheight,void *outdata, int outwidth, int outheight, int quality)
{
	if (quality)
	{
		int i, j, r, yi, oldy, f, fstep, endy = (inheight - 1), lerp;
		int inwidth4 = inwidth * 4, outwidth4 = outwidth * 4;
		byte *inrow, *out, *row1, *row2, *memalloc;

		out = static_cast<byte*>(outdata);
		fstep = (int) (inheight * 65536.0f / outheight);

		memalloc = static_cast<byte*>(malloc(2 * outwidth4));
		row1 = memalloc;
		row2 = memalloc + outwidth4;
		inrow = (byte *) indata;
		oldy = 0;
		Image_Resample32LerpLine (inrow, row1, inwidth, outwidth);
		Image_Resample32LerpLine (inrow + inwidth4, row2, inwidth, outwidth);
		for (i = 0, f = 0; i < outheight; i++, f += fstep)
		{
			yi = f >> 16;
			if (yi < endy)
			{
				lerp = f & 0xFFFF;
				if (yi != oldy)
				{
					inrow = (byte *) indata + inwidth4 * yi;
					if (yi == oldy + 1)
						memcpy(row1, row2, outwidth4);
					else
					Image_Resample32LerpLine (inrow, row1, inwidth, outwidth);
					Image_Resample32LerpLine (inrow + inwidth4, row2, inwidth, outwidth);
					oldy = yi;
				}
				j = outwidth - 4;
				while(j >= 0)
				{
					LERPBYTE(0); LERPBYTE(1); LERPBYTE(2); LERPBYTE(3);
					LERPBYTE(4); LERPBYTE(5); LERPBYTE(6); LERPBYTE(7);
					LERPBYTE(8); LERPBYTE(9); LERPBYTE(10); LERPBYTE(11);
					LERPBYTE(12); LERPBYTE(13); LERPBYTE(14); LERPBYTE(15);
					out += 16;
					row1 += 16;
					row2 += 16;
					j -= 4;
				}
				if (j & 2)
				{
					LERPBYTE(0); LERPBYTE(1); LERPBYTE(2); LERPBYTE(3);
					LERPBYTE(4); LERPBYTE(5); LERPBYTE(6); LERPBYTE(7);
					out += 8;
					row1 += 8;
					row2 += 8;
				}
				if (j & 1)
				{
					LERPBYTE(0); LERPBYTE(1); LERPBYTE(2); LERPBYTE(3);
					out += 4;
					row1 += 4;
					row2 += 4;
				}
				row1 -= outwidth4;
				row2 -= outwidth4;
			}
			else
			{
				if (yi != oldy)
				{
					inrow = (byte *) indata + inwidth4 * yi;
					if (yi == oldy+1)
						memcpy(row1, row2, outwidth4);
					else
						Image_Resample32LerpLine (inrow, row1, inwidth, outwidth);
					oldy = yi;
				}
				memcpy(out, row1, outwidth4);
			}
		}
		free(memalloc);
	}
	else
	{
		int i, j;
		unsigned int frac, fracstep, *inrow, *out;

		out = static_cast<unsigned int*>(outdata);

		fracstep = inwidth * 0x10000 / outwidth;
		for (i = 0; i < outheight; i++) {
			inrow = (unsigned int*)((int *)indata + inwidth * (i * inheight / outheight));
			frac = fracstep >> 1;
			j = outwidth - 4;
			while (j >= 0)
			{
				out[0] = inrow[frac >> 16]; frac += fracstep;
				out[1] = inrow[frac >> 16]; frac += fracstep;
				out[2] = inrow[frac >> 16]; frac += fracstep;
				out[3] = inrow[frac >> 16]; frac += fracstep;
				out += 4;
				j -= 4;
			}
			if (j & 2)
			{
				out[0] = inrow[frac >> 16]; frac += fracstep;
				out[1] = inrow[frac >> 16]; frac += fracstep;
				out += 2;
			}
			if (j & 1)
			{
				out[0] = inrow[frac >> 16]; frac += fracstep;
				out += 1;
			}
		}
	}
}


/*
================
Image_Resample24LerpLine
================
*/
static void Image_Resample24LerpLine (byte *in, byte *out, int inwidth, int outwidth) {
	int j, xi, oldx = 0, f, fstep, endx, lerp;

	fstep = (int) (inwidth * 65536.0f / outwidth);
	endx = (inwidth - 1);
	for (j = 0, f = 0; j < outwidth; j++, f += fstep) {
		xi = (int) f >> 16;
		if (xi != oldx) {
			in += (xi - oldx) * 3;
			oldx = xi;
		}
		if (xi < endx) {
			lerp = f & 0xFFFF;
			*out++ = (byte) ((((in[3] - in[0]) * lerp) >> 16) + in[0]);
			*out++ = (byte) ((((in[4] - in[1]) * lerp) >> 16) + in[1]);
			*out++ = (byte) ((((in[5] - in[2]) * lerp) >> 16) + in[2]);
		} else  {
			*out++ = in[0];
			*out++ = in[1];
			*out++ = in[2];
  }
	}
}

/*
================
Image_Resample24
================
*/
static void Image_Resample24 (void *indata, int inwidth, int inheight,
					 void *outdata, int outwidth, int outheight, int quality) {
	if (quality) {
		int i, j, r, yi, oldy, f, fstep, endy = (inheight - 1), lerp;
		int inwidth3 = inwidth * 3, outwidth3 = outwidth * 3;
		byte *inrow, *out, *row1, *row2, *memalloc;

		out = static_cast<byte*>(outdata);
		fstep = (int) (inheight * 65536.0f / outheight);

		memalloc = static_cast<byte*>(malloc(2 * outwidth3));
		row1 = memalloc;
		row2 = memalloc + outwidth3;
		inrow = (byte *) indata;
		oldy = 0;
		Image_Resample24LerpLine (inrow, row1, inwidth, outwidth);
		Image_Resample24LerpLine (inrow + inwidth3, row2, inwidth, outwidth);
		for (i = 0, f = 0; i < outheight; i++, f += fstep)	{
			yi = f >> 16;
			if (yi < endy) {
				lerp = f & 0xFFFF;
				if (yi != oldy) {
					inrow = (byte *) indata + inwidth3 * yi;
					if (yi == oldy + 1)
						memcpy(row1, row2, outwidth3);
					else
						Image_Resample24LerpLine (inrow, row1, inwidth, outwidth);
					Image_Resample24LerpLine (inrow + inwidth3, row2, inwidth, outwidth);
					oldy = yi;
				}
				j = outwidth - 4;
				while(j >= 0) {
					LERPBYTE(0); LERPBYTE(1); LERPBYTE(2);
					LERPBYTE(3); LERPBYTE(4); LERPBYTE(5);
					LERPBYTE(6); LERPBYTE(7); LERPBYTE(8);
					LERPBYTE(9); LERPBYTE(10); LERPBYTE(11);
					out += 12;
					row1 += 12;
					row2 += 12;
					j -= 4;
				}
				if (j & 2) {
					LERPBYTE(0); LERPBYTE(1); LERPBYTE(2);
					LERPBYTE(3); LERPBYTE(4); LERPBYTE(5);
					out += 6;
					row1 += 6;
					row2 += 6;
				}
				if (j & 1) {
					LERPBYTE(0); LERPBYTE(1); LERPBYTE(2);
					out += 3;
					row1 += 3;
					row2 += 3;
				}
				row1 -= outwidth3;
				row2 -= outwidth3;
			}
			else
			{
				if (yi != oldy) {
					inrow = (byte *) indata + inwidth3 * yi;
					if (yi == oldy+1)
						memcpy(row1, row2, outwidth3);
					else
						Image_Resample24LerpLine (inrow, row1, inwidth, outwidth);
					oldy = yi;
				}
				memcpy(out, row1, outwidth3);
			}
		}
		free(memalloc);
	}
	else
	{
		int i, j, f;
		unsigned int frac, fracstep, inwidth3 = inwidth * 3;
		byte *inrow, *out;

		out = static_cast<byte*>(outdata);

		fracstep = inwidth * 0x10000 / outwidth;
		for (i = 0; i < outheight; i++) {
			inrow = (byte *) indata + inwidth3 * (i * inheight / outheight);
			frac = fracstep >> 1;
			j = outwidth - 4;
			while (j >= 0)
			{
				f = (frac >> 16) * 3; NOLERPBYTE(0); NOLERPBYTE(1); NOLERPBYTE(2); frac += fracstep;
				f = (frac >> 16) * 3; NOLERPBYTE(0); NOLERPBYTE(1); NOLERPBYTE(2); frac += fracstep;
				f = (frac >> 16) * 3; NOLERPBYTE(0); NOLERPBYTE(1); NOLERPBYTE(2); frac += fracstep;
				f = (frac >> 16) * 3; NOLERPBYTE(0); NOLERPBYTE(1); NOLERPBYTE(2); frac += fracstep;
				j -= 4;
			}
			if (j & 2)
			{
				f = (frac >> 16) * 3; NOLERPBYTE(0); NOLERPBYTE(1); NOLERPBYTE(2); frac += fracstep;
				f = (frac >> 16) * 3; NOLERPBYTE(0); NOLERPBYTE(1); NOLERPBYTE(2); frac += fracstep;
				out += 2;
			}
			if (j & 1)
			{
				f = (frac >> 16) * 3; NOLERPBYTE(0); NOLERPBYTE(1); NOLERPBYTE(2); frac += fracstep;
				out += 1;

			}
		}
	}
}


/*
================
Image_Resample
================
*/
void Image_Resample (void *indata, int inwidth, int inheight,void *outdata, int outwidth, int outheight, int bpp, int quality)
{
	if (bpp == 4)
		Image_Resample32(indata, inwidth, inheight, outdata, outwidth, outheight, quality);
	else if (bpp == 3)
		Image_Resample24(indata, inwidth, inheight, outdata, outwidth, outheight, quality);
	else
		Sys_Error("Image_Resample: unsupported bpp (%d)", bpp);
}

/*
================
Image_MipReduce
================
*/
void Image_MipReduce (byte *in, byte *out, int *width, int *height, int bpp)
{
	int x, y, nextrow;

	nextrow = *width * bpp;

	if (*width > 1)
	{
		*width >>= 1;
		if (*height > 1)
		{

			*height >>= 1;
			if (bpp == 4)
			{
				for (y = 0; y < *height; y++)
				{
					for (x = 0; x < *width; x++)
					{
						out[0] = (byte) ((in[0] + in[4] + in[nextrow] + in[nextrow + 4]) >> 2);
						out[1] = (byte) ((in[1] + in[5] + in[nextrow + 1] + in[nextrow + 5]) >> 2);
						out[2] = (byte) ((in[2] + in[6] + in[nextrow + 2] + in[nextrow + 6]) >> 2);
						out[3] = (byte) ((in[3] + in[7] + in[nextrow + 3] + in[nextrow + 7]) >> 2);
						out += 4;
						in += 8;
					}
					in += nextrow;
				}
			}
			else if (bpp == 3)
			{
				for (y = 0; y < *height; y++)
				{
					for (x = 0; x < *width; x++)
					{
						out[0] = (byte) ((in[0] + in[3] + in[nextrow] + in[nextrow + 3]) >> 2);
						out[1] = (byte) ((in[1] + in[4] + in[nextrow + 1] + in[nextrow + 4]) >> 2);
						out[2] = (byte) ((in[2] + in[5] + in[nextrow + 2] + in[nextrow + 5]) >> 2);
						out += 3;
						in += 6;
					}
					in += nextrow;
				}
			}
			else
			{
				Sys_Error("Image_MipReduce: unsupported bpp (%d)", bpp);
			}
		}
		else
		{

			if (bpp == 4)
			{
				for (y = 0; y < *height; y++)
				{
					for (x = 0; x < *width; x++)
					{
						out[0] = (byte) ((in[0] + in[4]) >> 1);
						out[1] = (byte) ((in[1] + in[5]) >> 1);
						out[2] = (byte) ((in[2] + in[6]) >> 1);
						out[3] = (byte) ((in[3] + in[7]) >> 1);
						out += 4;
						in += 8;
					}
				}
			}
			else if (bpp == 3)
			{
				for (y = 0; y < *height; y++)
				{
					for (x = 0; x < *width; x++)
					{
						out[0] = (byte) ((in[0] + in[3]) >> 1);
						out[1] = (byte) ((in[1] + in[4]) >> 1);
						out[2] = (byte) ((in[2] + in[5]) >> 1);
						out += 3;
						in += 6;
					}
				}
			}
			else
			{
				Sys_Error("Image_MipReduce: unsupported bpp (%d)", bpp);
			}
		}
	}
	else if (*height > 1)
	{

		*height >>= 1;
		if (bpp == 4)
		{
			for (y = 0; y < *height; y++)
			{
				for (x = 0; x < *width; x++)
				{
					out[0] = (byte) ((in[0] + in[nextrow]) >> 1);
					out[1] = (byte) ((in[1] + in[nextrow + 1]) >> 1);
					out[2] = (byte) ((in[2] + in[nextrow + 2]) >> 1);
					out[3] = (byte) ((in[3] + in[nextrow + 3]) >> 1);
					out += 4;
					in += 4;
				}
				in += nextrow;
			}
		}
		else if (bpp == 3)
		{
			for (y = 0; y < *height; y++)
			{
				for (x = 0; x < *width; x++)
				{
					out[0] = (byte) ((in[0] + in[nextrow]) >> 1);
					out[1] = (byte) ((in[1] + in[nextrow + 1]) >> 1);
					out[2] = (byte) ((in[2] + in[nextrow + 2]) >> 1);
					out += 3;
					in += 3;
				}
				in += nextrow;
			}
		}
		else
		{
			Sys_Error("Image_MipReduce: unsupported bpp (%d)", bpp);
		}
	}
	else
	{
		Sys_Error("Image_MipReduce: Input texture has dimensions %dx%d", width, height);
	}
}


