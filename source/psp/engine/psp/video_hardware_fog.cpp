/*

Fogging system based on FitzQuake's implementation

*/

extern "C"
{
#include "../quakedef.h"
}

#include <pspgu.h>

//==============================================================================
//
//  GLOBAL FOG
//
//==============================================================================

extern refdef_t	r_refdef;

float old_start;
float old_end;
float old_red;
float old_green;
float old_blue;

float fade_time; //duration of fade
float fade_done; //time when fade will be done

/*
=============
Fog_Update

update internal variables
=============
*/
void Fog_Update (float start, float end, float red, float green, float blue, float time)
{
	//save previous settings for fade
	if (time > 0)
	{
		//check for a fade in progress
		if (fade_done > cl.time)
		{
			float f;

			f = (fade_done - cl.time) / fade_time;
			old_start = f * old_start + (1.0 - f) * r_refdef.fog_start;
			old_end = f * old_end + (1.0 - f) * r_refdef.fog_end;
			old_red = f * old_red + (1.0 - f) * r_refdef.fog_red;
			old_green = f * old_green + (1.0 - f) * r_refdef.fog_green;
			old_blue = f * old_blue + (1.0 - f) * r_refdef.fog_blue;
		}
		else
		{
			old_start = r_refdef.fog_start;
			old_end = r_refdef.fog_end;
			old_red = r_refdef.fog_red;
			old_green = r_refdef.fog_green;
			old_blue = r_refdef.fog_blue;
		}
	}

	r_refdef.fog_start = start;
	r_refdef.fog_end = end;
	r_refdef.fog_red = red;
	r_refdef.fog_green = green;
	r_refdef.fog_blue = blue;
	fade_time = time;
	fade_done = cl.time + time;
}

/*
=============
Fog_ParseServerMessage

handle an SVC_FOG message from server
=============
*/
void Fog_ParseServerMessage (void)
{
	float start, end, red, green, blue, time;

	start = MSG_ReadByte() / 255.0;
	end = MSG_ReadByte() / 255.0;
	red = MSG_ReadByte() / 255.0;
	green = MSG_ReadByte() / 255.0;
	blue = MSG_ReadByte() / 255.0;
	time = MSG_ReadShort() / 100.0;

	Fog_Update (start, end, red, green, blue, time);
}

/*
=============
Fog_FogCommand_f

handle the 'fog' console command
=============
*/
void Fog_FogCommand_f (void)
{
	switch (Cmd_Argc())
	{
	default:
	case 1:
		Con_Printf("usage:\n");
		Con_Printf("   fog <fade>\n");
		Con_Printf("   fog <start> <end>\n");
		Con_Printf("   fog <red> <green> <blue>\n");
		Con_Printf("   fog <fade> <red> <green> <blue>\n");
		Con_Printf("   fog <start> <end> <red> <green> <blue>\n");
		Con_Printf("   fog <start> <end> <red> <green> <blue> <fade>\n");
		Con_Printf("current values:\n");
		Con_Printf("   \"start\" is \"%f\"\n", r_refdef.fog_start);
		Con_Printf("   \"end\" is \"%f\"\n", r_refdef.fog_end);
		Con_Printf("   \"red\" is \"%f\"\n", r_refdef.fog_red);
		Con_Printf("   \"green\" is \"%f\"\n", r_refdef.fog_green);
		Con_Printf("   \"blue\" is \"%f\"\n", r_refdef.fog_blue);
		Con_Printf("   \"fade\" is \"%f\"\n", fade_time);
		break;
	case 2: //TEST
		Fog_Update(r_refdef.fog_start,
				   r_refdef.fog_end,
				   r_refdef.fog_red,
				   r_refdef.fog_green,
				   r_refdef.fog_blue,
				   atof(Cmd_Argv(1)));
		break;
	case 3:
		Fog_Update(atof(Cmd_Argv(1)),
				   atof(Cmd_Argv(2)),
				   r_refdef.fog_red,
				   r_refdef.fog_green,
				   r_refdef.fog_blue,
				   0.0);
		break;
	case 4:
		Fog_Update(r_refdef.fog_start,
				   r_refdef.fog_end,
				   CLAMP(0.0, atof(Cmd_Argv(1)), 100.0),
				   CLAMP(0.0, atof(Cmd_Argv(2)), 100.0),
				   CLAMP(0.0, atof(Cmd_Argv(3)), 100.0),
				   0.0);
		break;
	case 5: //TEST
		Fog_Update(r_refdef.fog_start,
				   r_refdef.fog_end,
				   CLAMP(0.0, atof(Cmd_Argv(1)), 100.0),
				   CLAMP(0.0, atof(Cmd_Argv(2)), 100.0),
				   CLAMP(0.0, atof(Cmd_Argv(3)), 100.0),
				   atof(Cmd_Argv(4)));
		break;
	case 6:
		Fog_Update(atof(Cmd_Argv(1)),
				   atof(Cmd_Argv(2)),
				   CLAMP(0.0, atof(Cmd_Argv(3)), 100.0),
				   CLAMP(0.0, atof(Cmd_Argv(4)), 100.0),
				   CLAMP(0.0, atof(Cmd_Argv(5)), 100.0),
				   0.0);
		break;
	case 7:
		Fog_Update(atof(Cmd_Argv(1)),
				   atof(Cmd_Argv(2)),
				   CLAMP(0.0, atof(Cmd_Argv(3)), 100.0),
				   CLAMP(0.0, atof(Cmd_Argv(4)), 100.0),
				   CLAMP(0.0, atof(Cmd_Argv(5)), 100.0),
				   atof(Cmd_Argv(6)));
		break;
	}
}

/*
=============
Fog_ParseWorldspawn

called at map load
=============
*/
void Fog_ParseWorldspawn (void)
{
	char key[128], value[4096];
	char *data;

	//initially no fog
	r_refdef.fog_start = 0;
	old_start = 0;

	r_refdef.fog_end = -1;
	old_end = -1;

	r_refdef.fog_red = 0.0;
	old_red = 0.0;

	r_refdef.fog_green = 0.0;
	old_green = 0.0;

	r_refdef.fog_blue = 0.0;
	old_blue = 0.0;

	fade_time = 0.0;
	fade_done = 0.0;

	data = COM_Parse(cl.worldmodel->entities);
	if (!data)
		return; // error
	if (com_token[0] != '{')
		return; // error
	while (1)
	{
		data = COM_Parse(data);
		if (!data)
			return; // error
		if (com_token[0] == '}')
			break; // end of worldspawn
		if (com_token[0] == '_')
			strcpy(key, com_token + 1);
		else
			strcpy(key, com_token);
		while (key[strlen(key)-1] == ' ') // remove trailing spaces
			key[strlen(key)-1] = 0;
		data = COM_Parse(data);
		if (!data)
			return; // error
		strcpy(value, com_token);

		if (!strcmp("fog", key))
		{
			sscanf(value, "%f %f %f %f %f", &r_refdef.fog_start, &r_refdef.fog_end, &r_refdef.fog_red, &r_refdef.fog_green, &r_refdef.fog_blue);
		}
	}
}

/*
=============
Fog_SetupFrame

called at the beginning of each frame
=============
*/
void Fog_SetupFrame (void)
{
	float c[4];
	float f, s, e;

	if (fade_done > cl.time)
	{
		f = (fade_done - cl.time) / fade_time;
		s = f * old_start + (1.0 - f) * r_refdef.fog_start;
		e = f * old_end + (1.0 - f) * r_refdef.fog_end;
		c[0] = f * old_red + (1.0 - f) * r_refdef.fog_red;
		c[1] = f * old_green + (1.0 - f) * r_refdef.fog_green;
		c[2] = f * old_blue + (1.0 - f) * r_refdef.fog_blue;
		c[3] = 1.0;
        //c[3] = r_skyfog.value;
	}
	else
	{
		s = r_refdef.fog_start;
		e = r_refdef.fog_end;
		c[0] = r_refdef.fog_red;
		c[1] = r_refdef.fog_green;
		c[2] = r_refdef.fog_blue;
		c[3] = 1.0;
        //c[3] = r_skyfog.value;
	}

	if(e == 0)
		e = -1;

	sceGuFog ( s, e, GU_COLOR( c[0]* 0.01f, c[1]* 0.01f, c[2]* 0.01f, c[3] ) );

	if(s == 0 || e < 0)
		sceGuDisable(GU_FOG);
}

/*
=============
Fog_SetColorForSkyS
Start called before drawing flat-colored sky
Crow_bar*
=============
*/
void Fog_SetColorForSkyS (void)
{
	if (r_refdef.fog_end > 0.0f && r_skyfog.value)
	{
		float a = r_refdef.fog_end * 0.00025f;
		float r = r_refdef.fog_red * 0.01f + (a * 0.25f);
		float g = r_refdef.fog_green * 0.01f + (a * 0.25f);
		float b = r_refdef.fog_blue * 0.01f + (a * 0.25f);
		
		if (a > 1.0f)
			a = 1.0f;
		if (r > 1.0f)
			r = 1.0f;
		if (g > 1.0f)
			g = 1.0f;
		if (b > 1.0f)
			b = 1.0f;
		
		sceGuTexFunc(GU_TFX_REPLACE, GU_TCC_RGBA);
		sceGuColor(GU_COLOR(r,g,b,a));
		
		//sceGuEnable(GU_BLEND);
		//sceGuBlendFunc(GU_ADD, GU_FIX, GU_FIX, GU_COLOR(r,g,b,a), GU_COLOR(r,g,b,a));
	}
}

/*
=============
Fog_SetColorForSky
End called before drawing flat-colored sky
Crow_bar*
=============
*/
void Fog_SetColorForSkyE (void)
{
	if (r_refdef.fog_end > 0.0f && r_skyfog.value)
	{
		sceGuTexFunc(GU_TFX_REPLACE, GU_TCC_RGBA);
		sceGuColor(0xffffffff);
		//sceGuDisable(GU_BLEND);
		//sceGuBlendFunc(GU_ADD, GU_SRC_ALPHA, GU_ONE_MINUS_SRC_ALPHA, 0, 0);
	}
}

/*
=============
Fog_GetStart

returns current start of fog
=============
*/
float Fog_GetStart (void)
{
	float f;

	if (fade_done > cl.time)
	{
		f = (fade_done - cl.time) / fade_time;
		return f * old_start + (1.0 - f) * r_refdef.fog_start;
	}
	else
		return r_refdef.fog_start;
}

/*
=============
Fog_GetEnd

returns current end of fog
=============
*/
float Fog_GetEnd (void)
{
	float f;

	if (fade_done > cl.time)
	{
		f = (fade_done - cl.time) / fade_time;
		return f * old_start + (1.0 - f) * r_refdef.fog_end;
	}
	else
		return r_refdef.fog_end;
}

/*
=============
Fog_EnableGFog

called before drawing stuff that should be fogged
=============
*/
void Fog_EnableGFog (void)
{
	if (!Fog_GetStart() == 0 || !Fog_GetEnd() <= 0)
		sceGuEnable(GU_FOG);
}

/*
=============
Fog_DisableGFog

called after drawing stuff that should be fogged
=============
*/
void Fog_DisableGFog (void)
{
	if (!Fog_GetStart() == 0 || !Fog_GetEnd() <= 0)
		sceGuDisable(GU_FOG);
}

/*
=============
Fog_SetColorForSky

called before drawing flat-colored sky
=============
*/
/*
void Fog_SetColorForSky (void)
{
	float c[3];
	float f, d;

	if (fade_done > cl.time)
	{
		f = (fade_done - cl.time) / fade_time;
		d = f * old_density + (1.0 - f) * fog_density;
		c[0] = f * old_red + (1.0 - f) * fog_red;
		c[1] = f * old_green + (1.0 - f) * fog_green;
		c[2] = f * old_blue + (1.0 - f) * fog_blue;
	}
	else
	{
		d = fog_density;
		c[0] = fog_red;
		c[1] = fog_green;
		c[2] = fog_blue;
	}

	if (d > 0)
		glColor3fv (c);
}
*/
//==============================================================================
//
//  VOLUMETRIC FOG
//
//==============================================================================
/*

void Fog_DrawVFog (void){}
void Fog_MarkModels (void){}
*/
//==============================================================================
//
//  INIT
//
//==============================================================================

/*
=============
Fog_NewMap

called whenever a map is loaded
=============
*/

void Fog_NewMap (void)
{
	Fog_ParseWorldspawn (); //for global fog
//	Fog_MarkModels (); //for volumetric fog
}

/*
=============
Fog_Init

called when quake initializes
=============
*/
void Fog_Init (void)
{
	Cmd_AddCommand ("fog",Fog_FogCommand_f);

	//set up global fog
	r_refdef.fog_start = 0;
	r_refdef.fog_end = -1;
	r_refdef.fog_red = 0.5;
	r_refdef.fog_green = 0.5;
	r_refdef.fog_blue = 0.5;
	fade_time = 1;
}
