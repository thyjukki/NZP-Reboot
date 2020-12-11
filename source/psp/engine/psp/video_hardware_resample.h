void Image_Resample (void *indata, int inwidth, int inheight,void *outdata, int outwidth, int outheight, int bpp, int quality);          //resample from fuh quake
void ResampleTexture (unsigned *indata, int inwidth, int inheight, unsigned *outdata, int outwidth, int outheight, qboolean quality); //resample from joe quake
void Image_MipReduce (byte *in, byte *out, int *width, int *height, int bpp); //from fuh quake
