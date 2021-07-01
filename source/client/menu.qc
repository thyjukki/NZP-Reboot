//
//	Menu stuff.. very ugly :p
// 	Typos FTW!
//

float current_custom_map_page;
float custom_map_pages;
float last_active_custom_select;
float active_custom_select;


void() menu_single =
{
	in_menu = MENU_SINGLE;
	time_in_menu = 0;
};

void() menu_restart =
{
	in_menu = MENU_RES;
};

void() menu_resy =
{
	localcmd("restart\n");
};

void() menu_resn =
{
	in_menu = MENU_PAUSE;
};

void() menu_multi =
{
	in_menu = MENU_MULTI;
	time_in_menu = 0;
};

void() menu_settings =
{
	if (in_menu == MENU_PAUSE)
		in_menu = MENU_IGS;
	else
		in_menu = MENU_SETTINGS;
};

void() menu_about =
{
	in_menu = MENU_ABOUT;
	time_in_menu = 0;
};

void() menu_quit =
{
	localcmd("quit\n");
};

void() menu_back =
{
	if (in_menu == MENU_GSETTINGS || in_menu == MENU_CSETTINGS) {
		if (wasigs == TRUE)
			in_menu = MENU_IGS;
		else
			in_menu = MENU_SETTINGS;

		wasigs = FALSE;
	} else if (in_menu == MENU_IGS) {
		in_menu = MENU_PAUSE;
	} else if (in_menu == MENU_CUSTOMS) {
		in_menu = MENU_SINGLE;
	} else
		in_menu = MENU_MAIN;
};

void() menu_loadndu =
{
	localcmd("map ndu\n");
};

void() menu_loadwh =
{
	localcmd("map warehouse\n");
};

void() menu_loadch =
{
	localcmd("map christmas_special\n");
};

void() menu_loadwn =
{
	localcmd("map wahnsinn\n");
};

void() menu_loadkn =
{
	localcmd("map kino\n");
};

void() menu_join =
{
	setcursormode(TRUE,"menu/cursor");
	in_menu = MENU_JOIN;
};

void() game_join =
{	
	localcmd("cmd joingame\n");
	in_menu = MENU_NONE;
	setcursormode(FALSE);
};

void() game_spec =
{
	localcmd("cmd specgame\n");
	in_menu = MENU_NONE;
	setcursormode(FALSE);
};

void() menu_resume =
{
	if (player_count == 0)
		localcmd("pause");
	in_menu = MENU_NONE;
	setcursormode(FALSE);
};

void() menu_main =
{
	in_menu = MENU_MAIN;
	localcmd("disconnect\n");
};

void() menu_graphics =
{
	if (in_menu == MENU_IGS)
		wasigs = TRUE;
	else
		wasigs = FALSE;

	in_menu = MENU_GSETTINGS;
};

void() menu_consettings =
{
	if (in_menu == MENU_IGS)
		wasigs = TRUE;
	else
		wasigs = FALSE;

	in_menu = MENU_CONSETTINGS;
}

void() menu_audsettings =
{
	if (in_menu == MENU_IGS)
		wasigs = TRUE;
	else
		wasigs = FALSE;

	in_menu = MENU_AUDSETTINGS;
}

void() menu_controls =
{
	if (in_menu == MENU_IGS)
		wasigs = TRUE;
	else
		wasigs = FALSE;

	in_menu = MENU_CSETTINGS;
}

void() menu_customs =
{
	in_menu = MENU_CUSTOMS;
	customs_interact = FALSE;
}

void() menu_achievements =
{
    in_menu = MENU_ACHIEVEMENTS;
}

void() menu_waypoint =
{	
	localcmd("waypoint_mode 1");
};

//
//settings adjustments
//

void() settings_fps = {
	local float fps = cvar("show_fps");

	if (fps == 0)
		fps = 1;
	else
		fps = 0;

	cvar_set("show_fps", ftos(fps));
}

void() settings_brite = {
	local float br = cvar("gamma");

	br -= 0.1;
	projBr += 0.1;

	if (br < 0) {
		br = 2;
		projBr = 0;
	}

	cvar_set("gamma", ftos(br));
}

void() settings_brite2 = {
	local float br = cvar("gamma");

	br += 0.1;
	projBr -= 0.1;

	if (br > 2) {
		br = 0;
		projBr = 2;
	}

	cvar_set("gamma", ftos(br));
}

void() settings_fov = {
	// Increase FOV by 5
	local float fov = cvar("fov");

	if (fov < 120)
		fov += 5;

	cvar_set("fov", ftos(fov));
}

void() settings_fov2 = {
	// Decrease FOV by 5
	local float fov = cvar("fov");

	if (fov > 50)
		fov -= 5;

	cvar_set("fov", ftos(fov));
}

void() settings_mfps = {
	// Increase max fps by 5
	if (cvar("vid_vsync"))
		return;

	local float fps = cvar("cl_maxfps");

	if (fps < 500)
		fps += 5;

	cvar_set("cl_maxfps", ftos(fps));
}

void() settings_mfps2 = {
	// Decrease max fps by 5
	if (cvar("vid_vsync"))
		return;

	local float fps = cvar("cl_maxfps");

	if (fps > 20)
		fps -= 5;

	cvar_set("cl_maxfps", ftos(fps));
}

void() settings_vs = {
	local float vs = cvar("vid_vsync");

	if (vs == 0)
		vs = 1;
	else
		vs = 0;

	cvar_set("vid_vsync", ftos(vs));
}

void() settings_fs = {
	if (fullscreenval == 0)
		fullscreenval = 1;
	else
		fullscreenval = 0;
}

void() settings_dc = {
	local float dc = cvar("nzp_decals");

	if (dc == 0)
		dc = 1;
	else
		dc = 0;

	cvar_set("nzp_decals", ftos(dc));
}

void() settings_pt = {
	local float pt = cvar("nzp_particles");

	if (pt == 0)
		pt = 1;
	else
		pt = 0;

	cvar_set("nzp_particles", ftos(pt));
}

void() settings_fb = {
	local float fb = cvar("r_fullbright");

	if (fb == 0)
		fb = 1;
	else
		fb = 0;

	cvar_set("r_fullbright", ftos(fb));
}

void() settings_ro = {
	if (cvar_string("gl_texturemode") == "gl_nearest")
		cvar_set("gl_texturemode", "gl_linear_mipmap_linear");
	else
		cvar_set("gl_texturemode", "gl_nearest");
}

void() UpdateResolutions = {
	switch(aspectratio) {
		case 0:
			active_swidth = screen_width_43[0];
			active_sheight = screen_height_43[0];
			break;
		case 1:
			active_swidth = screen_width_54[0];
			active_sheight = screen_height_54[0];
			break;
		case 2:
			active_swidth = screen_width_169[0];
			active_sheight = screen_height_169[0];
			break;
		case 3:
			active_swidth = screen_width_1610[0];
			active_sheight = screen_height_1610[0];
			break;
		case 4:
			active_swidth = screen_width_219[0];
			active_sheight = screen_height_219[0];
			break;
	}
}

void() settings_ar = {
	// aspect ratio up
	// 0 - 4:3
	// 1 - 5:4
	// 2 - 16:9
	// 3 - 16:10
	// 4 - 21:9
	aspectratio++;

	if (aspectratio > 4)
		aspectratio = 0;

	UpdateResolutions();
}

void() settings_ar2 = {
	// aspect ratio down
	// 0 - 4:3
	// 1 - 5:4
	// 2 - 16:9
	// 3 - 16:10
	// 4 - 21:9
	aspectratio--;

	if (aspectratio < 0)
		aspectratio = 4;

	UpdateResolutions();
}

void() settings_re = {
	float neww, newh;
	neww = 0;
	newh = 0;

	switch(aspectratio) {
		case 0:
			if (active_swidth == screen_width_43[MAX_43-1]) {
				neww = screen_width_43[0];
				newh = screen_height_43[0];
			} else {
				for(float i = 0; i < MAX_43; i++) {
					if (active_swidth == screen_width_43[i]) {
						neww = screen_width_43[i+1];
						newh = screen_height_43[i+1];
					}
				}

				// if still 0, different aspect ratio
				if (neww == 0) {
					neww = screen_width_43[0];
					newh = screen_height_43[0];
				}
			}
			break;
		case 1:
			if (active_swidth == screen_width_43[MAX_54-1]) {
				neww = screen_width_54[0];
				newh = screen_height_54[0];
			} else {
				for(float i = 0; i < MAX_54; i++) {
					if (active_swidth == screen_width_54[i]) {
						neww = screen_width_54[i+1];
						newh = screen_height_54[i+1];
					}
				}

				// if still 0, different aspect ratio
				if (neww == 0) {
					neww = screen_width_54[0];
					newh = screen_height_54[0];
				}
			}
			break;
		case 2:
			if (active_swidth == screen_width_169[MAX_169-1]) {
				neww = screen_width_169[0];
				newh = screen_height_169[0];
			} else {
				for(float i = 0; i < MAX_169; i++) {
					if (active_swidth == screen_width_169[i]) {
						neww = screen_width_169[i+1];
						newh = screen_height_169[i+1];
					}
				}

				// if still 0, different aspect ratio
				if (neww == 0) {
					neww = screen_width_169[0];
					newh = screen_height_169[0];
				}
			}
			break;
		case 3:
			if (active_swidth == screen_width_1610[MAX_1610-1]) {
				neww = screen_width_1610[0];
				newh = screen_height_1610[0];
			} else {
				for(float i = 0; i < MAX_1610; i++) {
					if (active_swidth == screen_width_1610[i]) {
						neww = screen_width_1610[i+1];
						newh = screen_height_1610[i+1];
					}
				}

				// if still 0, different aspect ratio
				if (neww == 0) {
					neww = screen_width_1610[0];
					newh = screen_height_1610[0];
				}
			}
			break;
		case 4:
			if (active_swidth == screen_width_219[MAX_219-1]) {
				neww = screen_width_219[0];
				newh = screen_height_219[0];
			} else {
				for(float i = 0; i < MAX_219; i++) {
					if (active_swidth == screen_width_219[i]) {
						neww = screen_width_219[i+1];
						newh = screen_height_219[i+1];
					}
				}

				// if still 0, different aspect ratio
				if (neww == 0) {
					neww = screen_width_219[0];
					newh = screen_height_219[0];
				}
			}
			break;
		default:
			break;
	}

	active_swidth = neww;
	active_sheight = newh;
}

void() settings_apply = {
	if (in_menu == MENU_GSETTINGS) {
		localcmd(strcat("vid_width ", ftos(active_swidth), "\n"));
		localcmd(strcat("vid_height ", ftos(active_sheight), "\n"));
		localcmd(strcat("vid_fullscreen_standalone ", ftos(fullscreenval), "\n"));
		localcmd("vid_restart\n");
	}

}

void() bind_walkf = {
	if (editBind[0] == FALSE)
		editBind[0] = TRUE;
	else
		editBind[0] = FALSE;
}

void() bind_walkb = {
	if (editBind[1] == FALSE)
		editBind[1] = TRUE;
	else
		editBind[1] = FALSE;
}

void() bind_walkl = {
	if (editBind[2] == FALSE)
		editBind[2] = TRUE;
	else
		editBind[2] = FALSE;
}

void() bind_walkr = {
	if (editBind[3] == FALSE)
		editBind[3] = TRUE;
	else
		editBind[3] = FALSE;
}

void() bind_jump = {
	if (editBind[4] == FALSE)
		editBind[4] = TRUE;
	else
		editBind[4] = FALSE;
}

void() bind_sprint = {
	if (editBind[5] == FALSE)
		editBind[5] = TRUE;
	else
		editBind[5] = FALSE;
}

void() bind_stance = {
	if (editBind[6] == FALSE)
		editBind[6] = TRUE;
	else
		editBind[6] = FALSE;
}

void() bind_wpnn = {
	if (editBind[7] == FALSE)
		editBind[7] = TRUE;
	else
		editBind[7] = FALSE;
}

void() bind_wpnp = {
	if (editBind[8] == FALSE)
		editBind[8] = TRUE;
	else
		editBind[8] = FALSE;
}

void() bind_interact = {
	if (editBind[9] == FALSE)
		editBind[9] = TRUE;
	else
		editBind[9] = FALSE;
}

void() bind_reload = {
	if (editBind[10] == FALSE)
		editBind[10] = TRUE;
	else
		editBind[10] = FALSE;
}

void() bind_knife = {
	if (editBind[11] == FALSE)
		editBind[11] = TRUE;
	else
		editBind[11] = FALSE;
}

void() bind_nade = {
	if (editBind[12] == FALSE)
		editBind[12] = TRUE;
	else
		editBind[12] = FALSE;
}

void() bind_switchnade = {
	if (editBind[13] == FALSE)
		editBind[13] = TRUE;
	else
		editBind[13] = FALSE;
}

float next_gray_out;
float back_gray_out;

void() menu_custom_next =
{
	if (in_menu == MENU_CUSTOMS) {
		if (current_custom_map_page < custom_map_pages) {
			current_custom_map_page++;
			back_gray_out = 0;

			if (current_custom_map_page == custom_map_pages)
				next_gray_out = 1;
		}
	} else {
		if (current_achievement_page < achievement_pages) {
			current_achievement_page++;
			back_gray_out = 0;

			if (current_achievement_page == achievement_pages)
				next_gray_out = 1;
		}
	}
}

void() menu_custom_back =
{
	if (in_menu == MENU_CUSTOMS) {
		if (current_custom_map_page > 1) {
			current_custom_map_page--;
			next_gray_out = 0;

			if (current_custom_map_page == 1)
				back_gray_out = 1;
		}
	} else {
		if (current_achievement_page > 1) {
			current_achievement_page--;
			next_gray_out = 0;

			if (current_achievement_page == 1)
				back_gray_out = 1;
		}
	}	
}

void() settings_sens = {
	float sens = cvar("sensitivity");

	sens += 0.5;

	cvar_set("sensitivity", ftos(sens));
}

void() settings_sens2 = {
	float sens = cvar("sensitivity");

	sens -= 0.5;

	cvar_set("sensitivity", ftos(sens));
}

void() settings_adsmode =
{
	float adsmode = cvar("cl_adsmode");

	if (adsmode == 0)
		cvar_set("cl_adsmode", ftos(1));
	else
		cvar_set("cl_adsmode", ftos(0));
}

void() setting_mastervol =
{
	float vol = cvar("volume");

	vol += 0.1;

	if (vol > 1)
		vol = 1;

	cvar_set("volume", ftos(vol));
}

void() setting_mastervol2 =
{
	float vol = cvar("volume");

	vol -= 0.1;

	if (vol < 0)
		vol = 0;

	cvar_set("volume", ftos(vol));
}

void() setting_chann1vol =
{
	float vol = cvar("snd_channel1volume");

	vol += 0.1;

	if (vol > 1)
		vol = 1;

	cvar_set("snd_channel1volume", ftos(vol));
}

void() setting_chann1vol2 =
{
	float vol = cvar("snd_channel1volume");

	vol -= 0.1;

	if (vol < 0)
		vol = 0;

	cvar_set("snd_channel1volume", ftos(vol));
}

void() setting_chann2vol =
{
	float vol = cvar("snd_channel2volume");

	vol += 0.1;

	if (vol > 1)
		vol = 1;

	cvar_set("snd_channel2volume", ftos(vol));
}

void() setting_chann2vol2 =
{
	float vol = cvar("snd_channel2volume");

	vol -= 0.1;

	if (vol < 0)
		vol = 0;

	cvar_set("snd_channel2volume", ftos(vol));
}

void() setting_chann3vol =
{
	float vol = cvar("snd_channel3volume");

	vol += 0.1;

	if (vol > 1)
		vol = 1;

	cvar_set("snd_channel3volume", ftos(vol));
}

void() setting_chann3vol2 =
{
	float vol = cvar("snd_channel3volume");

	vol -= 0.1;

	if (vol < 0)
		vol = 0;

	cvar_set("snd_channel3volume", ftos(vol));
}

void() setting_chann4vol =
{
	float vol = cvar("snd_channel4volume");

	vol += 0.1;

	if (vol > 1)
		vol = 1;

	cvar_set("snd_channel4volume", ftos(vol));
}

void() setting_chann4vol2 =
{
	float vol = cvar("snd_channel4volume");

	vol -= 0.1;

	if (vol < 0)
		vol = 0;

	cvar_set("snd_channel4volume", ftos(vol));
}

void() setting_chann5vol =
{
	float vol = cvar("snd_channel5volume");

	vol += 0.1;

	if (vol > 1)
		vol = 1;

	cvar_set("snd_channel5volume", ftos(vol));
}

void() setting_chann5vol2 =
{
	float vol = cvar("snd_channel5volume");

	vol -= 0.1;

	if (vol < 0)
		vol = 0;

	cvar_set("snd_channel5volume", ftos(vol));
}

void() setting_chann6vol =
{
	float vol = cvar("snd_channel6volume");

	vol += 0.1;

	if (vol > 1)
		vol = 1;

	cvar_set("snd_channel6volume", ftos(vol));
}

void() setting_chann6vol2 =
{
	float vol = cvar("snd_channel6volume");

	vol -= 0.1;

	if (vol < 0)
		vol = 0;

	cvar_set("snd_channel6volume", ftos(vol));
}

//rmb null
void() null = {
	return;
}

/*

	MENU GUIDELINES (to preserve consistency)
	
	* Buttons that belong to the same category should have a spacing
	difference of 0.05.

	* Buttons that do not belong to the same category should have
	a spacing difference of 0.075.

*/

//struct for all buttons, note scale is going to be multiplied w/ width/height in draw step, keep between 0 and 1
var struct
{
	vector pos;
	string text;
	float active; //used for mouseover hilight (positive values) and alpha (negative values)
	void() action; //function that is called when the button is pressed with lmb
	void() action2; //rmb function
	float group; //a bit field, button will be usable/visible when these bits are active
	float gray_out; // if not to be accessed
} buttons[] =
{
	//Main
	{[0.025, 0.175, 0], "Solo", -1, menu_single, null, MENU_MAIN, 0},
	//{[0.025, 0.225, 0], "Cooperative", -1, menu_multi, null, MENU_MAIN},
	{[0.025, 0.300, 0], "Settings", -1, menu_settings, null, MENU_MAIN, 0},
	{[0.025, 0.350, 0], "Achievements", -1, menu_achievements, null, MENU_MAIN, 0},
	{[0.025, 0.425, 0], "Credits", -1, menu_about, null, MENU_MAIN, 0},
	{[0.025, 0.500, 0], "Exit", -1, menu_quit, null, MENU_MAIN, 0},

	//Solo
	{[0.025, 0.175, 0], "Nacht der Untoten", -1, menu_loadndu, null, MENU_SINGLE, 0},
	{[0.025, 0.275, 0], "Warehouse", -1, menu_loadwh, null, MENU_SINGLE, 0},
	{[0.025, 0.450, 0], "Custom Maps", -1, menu_customs, null, MENU_SINGLE, 0},

	//Pause
	{[0.025, 0.500, 0], "Resume", -1, menu_resume, null, MENU_PAUSE, 0},
	{[0.025, 0.550, 0], "Restart", -1, menu_restart, null, MENU_PAUSE, 0},
	{[0.025, 0.600, 0], "Settings", -1, menu_settings, null, MENU_PAUSE, 0},
	{[0.025, 0.650, 0], "Main Menu", -1, menu_main, null, MENU_PAUSE, 0},
	{[0.025, 0.850, 0], "Waypoint Menu", -1, menu_waypoint, null, MENU_PAUSE, 0},

	//Restart
	{[0.025, 0.500, 0], "Yes", -1, menu_resy, null, MENU_RES, 0},
	{[0.025, 0.550, 0], "No", -1, menu_resn, null, MENU_RES, 0},

	//Settings
	{[0.025, 0.175, 0], "Graphics Settings", -1, menu_graphics, null, MENU_SETTINGS + MENU_IGS, 0},
	{[0.025, 0.350, 0], "Controls", -1, menu_controls, null, MENU_SETTINGS + MENU_IGS, 0},

	//Graphics
	{[0.025, 0.175, 0], "Resolution", -1, settings_re, settings_re, MENU_GSETTINGS, 0},
	{[0.025, 0.225, 0], "Aspect Ratio", -1, settings_ar, settings_ar2, MENU_GSETTINGS, 0},
	{[0.025, 0.275, 0], "Fullscreen", -1, settings_fs, settings_fs, MENU_GSETTINGS, 0},
	{[0.025, 0.325, 0], "Show FPS", -1, settings_fps, settings_fps, MENU_GSETTINGS, 0},
	{[0.025, 0.375, 0], "Max FPS", -1, settings_mfps, settings_mfps2, MENU_GSETTINGS, 0},
	{[0.025, 0.425, 0], "VSync", -1, settings_vs, settings_vs, MENU_GSETTINGS, 0},
	{[0.025, 0.475, 0], "Field of View", -1, settings_fov, settings_fov2, MENU_GSETTINGS, 0},
	{[0.025, 0.525, 0], "Brightness", -1, settings_brite, settings_brite2, MENU_GSETTINGS, 0},	
	{[0.025, 0.575, 0], "Decals", -1, settings_dc, settings_dc, MENU_GSETTINGS, 0},
	{[0.025, 0.625, 0], "Particles", -1, settings_pt, settings_pt, MENU_GSETTINGS, 0},
	{[0.025, 0.675, 0], "Fullbright", -1, settings_fb, settings_fb, MENU_GSETTINGS, 0},
	{[0.025, 0.725, 0], "Retro", -1, settings_ro, settings_ro, MENU_GSETTINGS, 0},
	{[0.025, 0.800, 0], "Save & Apply", -1, settings_apply, settings_apply, MENU_GSETTINGS + MENU_CONSETTINGS +
																			MENU_AUDSETTINGS, 0},

	//Controls
	{[0.025, 0.175, 0], "Walk Forward", -1, bind_walkf, null, MENU_CSETTINGS, 0},
	{[0.025, 0.225, 0], "Walk Backward", -1, bind_walkb, null, MENU_CSETTINGS, 0},
	{[0.025, 0.275, 0], "Walk Left", -1, bind_walkl, null, MENU_CSETTINGS, 0},
	{[0.025, 0.325, 0], "Walk Right", -1, bind_walkr, null, MENU_CSETTINGS, 0},
	{[0.025, 0.375, 0], "Jump", -1, bind_jump, null, MENU_CSETTINGS, 0},
	{[0.025, 0.425, 0], "Sprint", -1, bind_sprint, null, MENU_CSETTINGS, 0},
	{[0.025, 0.475, 0], "Change Stance", -1, bind_stance, null, MENU_CSETTINGS, 0},

	{[0.025, 0.525, 0], "Weapon Next", -1, bind_wpnn, null, MENU_CSETTINGS, 0},
	{[0.025, 0.575, 0], "Weapon Previous", -1, bind_wpnp, null, MENU_CSETTINGS, 0},

	{[0.025, 0.625, 0], "Interact", -1, bind_interact, null, MENU_CSETTINGS, 0},
	{[0.025, 0.675, 0], "Reload", -1, bind_reload, null, MENU_CSETTINGS, 0},
	{[0.025, 0.725, 0], "Melee", -1, bind_knife, null, MENU_CSETTINGS, 0},
	{[0.025, 0.775, 0], "Grenade", -1, bind_nade, null, MENU_CSETTINGS, 0},
	{[0.025, 0.825, 0], "Secondary Grenade", -1, bind_switchnade, null, MENU_CSETTINGS, 0},

	// Custom Maps
	{[0.025, 0.825, 0], "Next Page", -1, menu_custom_next, null, MENU_CUSTOMS + MENU_ACHIEVEMENTS, 0},
	{[0.025, 0.875, 0], "Previous Page", -1, menu_custom_back, null, MENU_CUSTOMS + MENU_ACHIEVEMENTS, 0},

	//Everything, pretty much
	{[0.025, 0.925, 0], "Back", -1, menu_back, null, MENU_SINGLE + MENU_MULTI + MENU_SETTINGS + MENU_ABOUT + 
													 MENU_IGS + MENU_GSETTINGS + MENU_CSETTINGS + MENU_CUSTOMS +
                                                     MENU_ACHIEVEMENTS + MENU_CONSETTINGS + MENU_AUDSETTINGS, 0},

	{[0.025, 0.275, 0], "Control Settings", -1, menu_consettings, null, MENU_SETTINGS + MENU_IGS, 0}, // 47
	{[0.025, 0.175, 0], "ADS Mode", -1, settings_adsmode, null, MENU_CONSETTINGS, 0}, // 48
	{[0.025, 0.225, 0], "Look Sensitivity", -1, settings_sens, settings_sens2, MENU_CONSETTINGS, 0}, // 49

	{[0.025, 0.325, 0], "Wahnsinn", -1, menu_loadwn, null, MENU_SINGLE, 1}, // 50
	{[0.025, 0.375, 0], "Christmas Special", -1, menu_loadch, null, MENU_SINGLE, 0}, // 51
	{[0.025, 0.225, 0], "Kino der Toten", -1, menu_loadch, null, MENU_SINGLE, 1}, // 52

	{[0.025, 0.225, 0], "Audio Settings", -1, menu_audsettings, null, MENU_SETTINGS + MENU_IGS, 0}, // 53
	{[0.025, 0.175, 0], "Master Volume", -1, setting_mastervol, setting_mastervol2, MENU_AUDSETTINGS, 0}, // 54
	{[0.025, 0.225, 0], "Music Volume", -1, setting_chann1vol, setting_chann1vol2, MENU_AUDSETTINGS, 0}, // 55
	{[0.025, 0.275, 0], "SFX Volume", -1, setting_chann2vol, setting_chann2vol2, MENU_AUDSETTINGS, 0}, // 56
	{[0.025, 0.325, 0], "Channel 3 Volume", -1, setting_chann3vol, setting_chann3vol2, MENU_AUDSETTINGS, 0}, // 57
	{[0.025, 0.375, 0], "Channel 4 Volume", -1, setting_chann4vol, setting_chann4vol2, MENU_AUDSETTINGS, 0}, // 58
	{[0.025, 0.425, 0], "Channel 5 Volume", -1, setting_chann5vol, setting_chann5vol2, MENU_AUDSETTINGS, 0}, // 59
	{[0.025, 0.475, 0], "Channel 6 Volume", -1, setting_chann6vol, setting_chann6vol2, MENU_AUDSETTINGS, 0}, // 60
};

//REMEMBER TO UPDATE THIS CONST IF YOU ADD BUTTONS
const float BUTTONS_COUNT = 61;
float lastActive;


//this function handles drawing the buttons and checking if they should be active/hilighted
void(float index) Update_Button = 
{
	float btnscale = 0.030*g_height;

	if(in_menu != in_menu & buttons[index].group) 
		buttons[index].active = -1;
		
	if(buttons[index].active == -1)
	{
		if(in_menu == in_menu & buttons[index].group)
			buttons[index].active = 1;
		else
			return;
	}
	
	local vector pos = buttons[index].pos;
	pos_x *= g_width;
	pos_y *= g_height;

	if (next_gray_out == 1)
		buttons[44].gray_out = 1;
	else
		buttons[44].gray_out = 0;

	if (back_gray_out == 1)
		buttons[45].gray_out = 1;
	else
		buttons[45].gray_out = 0;

	if (buttons[index].gray_out == 0) {
		if(buttons[index].active > 0) {
			drawstring(pos, buttons[index].text, [g_height * 0.030, g_height * 0.030, 1], [1,0,0], 1, 0);
		} else {
			drawstring(pos, buttons[index].text, [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 0);
		}
	} else {
		drawstring(pos, buttons[index].text, [g_height * 0.030, g_height * 0.030, 1], [0.5,0.5,0.5], 1, 0);
	}
	

	if (cursor_pos_x > pos_x && cursor_pos_x < pos_x + (g_height * 0.6) && cursor_pos_y > pos_y && cursor_pos_y < pos_y + btnscale && buttons[index].gray_out == 0) {
		if (index != lastActive)
			localsound_enhanced("sounds/menu/navigate.wav", CHAN_SFX, 1);
		
		buttons[index].active = 1;
		lastActive = index;
		last_active_custom_select = active_custom_select = -1;
	}

	if (lastActive == -1) {
		buttons[index].active = 0;
	} else {
		buttons[lastActive].active = 1;
	}
		

	if(buttons[index].active > 0)
	{
		buttons[index].active = 0;
	}
};

float xd;
void() Controller_UpdateButton =
{
	/*if (GPActive[0]) {

	}*/
	drawstring([0.025*g_width, 0.375*g_height, 0], ftos(GPActive[2]), [g_height * 0.020, g_height * 0.020, 1], [0.8,0.8,0.8], 1, 0);
}


void(float index, float type) Button_Click = 
{
	float btnscale = 0.030*g_height;

	//don't click if not active
	if(buttons[index].active == -1)
		return;
		
	local vector pos = buttons[index].pos;
	pos_x *= g_width;
	pos_y *= g_height;
	
	if (cursor_pos_x > pos_x && cursor_pos_x < pos_x + (g_height * 0.6) && cursor_pos_y > pos_y && cursor_pos_y < pos_y + btnscale) {
		if (type == 0) { //left click
			buttons[index].action();
		} else { //right click
			buttons[index].action2();
		}
		
		lastActive = -1;
		localsound_enhanced("sounds/menu/enter.wav", CHAN_SFX, 1);
	}

	if (in_menu == MENU_CUSTOMS)
		customs_interact = FALSE;
};


void(float type) Menu_Click =
{
	float i;
	for(i = 0; i < BUTTONS_COUNT; i++)
	{
		Button_Click(i, type);
	}
};

void() Menu_Click_Custom =
{
	customs_interact = TRUE;
};

void() Draw_Extra_Main =
{
	local string main_desc = "";

	// Draw darkened co-op button
	drawstring([0.025*g_width, 0.225*g_height, 0], "Co-Op (Coming Soon!)", [g_height * 0.03, g_height * 0.03, 1], [0.5, 0.5, 0.5], 1, 0);
	
	// Division lines
	drawfill ([0.025*g_width, 0.275*g_height, 0], [g_height * 0.600, g_height * 0.005, 1], [0.4, 0.4, 0.4], 1, 0);
	drawfill ([0.025*g_width, 0.400*g_height, 0], [g_height * 0.600, g_height * 0.005, 1], [0.4, 0.4, 0.4], 1, 0);
	drawfill ([0.025*g_width, 0.475*g_height, 0], [g_height * 0.600, g_height * 0.005, 1], [0.4, 0.4, 0.4], 1, 0);

	// Get description for menu option
	switch(lastActive) {
		case 0:
			main_desc = "Take on the Hordes by yourself.";
			break;
		case 1:
			main_desc = "Adjust your Settings to Optimize your Experience.";
			break;
		case 2:
			main_desc = "View locked or unlocked Achievements.";
			break;
		case 3:
			main_desc = "See who made NZ:P possible.";
			break;
		case 4:
			main_desc = "Return to System.";
			break;
		default:
			main_desc = "";
			break;
	}

	// Draw desc
	drawstring([0.025*g_width, 0.865*g_height, 0], main_desc, [g_height * 0.03, g_height * 0.03, 1], [0.8, 0.8, 0.8], 1, 0);
}

void() Draw_Extra_Solo =
{
	local string solo_desc = "";
	local string solo_desc2 = "";
	local string solo_desc3 = "";
	local string solo_img = "";

	// Division lines
	drawfill ([0.025*g_width, 0.425*g_height, 0], [g_height * 0.600, g_height * 0.005, 1], [0.4, 0.4, 0.4], 1, 0);

	// Map descriptions
	switch(lastActive) {
		case 5:
			solo_desc = "Lock and Load; Crashed Plane.";
			solo_desc2 = "Divided. Thousands of Undead.";
			solo_desc3 = "This is the Night of the Dead.";
			solo_img = "gfx/menu/nacht_der_untoten.png";
			break;
		case 6:
			solo_desc = "Old Warehouse full of Zombies!";
			solo_desc2 = "Fight your way to the Power";
			solo_desc3 = "Switch through the Hordes!";
			solo_img = "gfx/menu/warehouse.png";
			break;
		case 50:
			solo_desc = "An abandoned and bleak mental house";
			solo_desc2 = "surrounded by debris and fog. Teddy";
			solo_desc3 = "is deceitful, find him.";
			solo_img = "gfx/menu/wahnsinn.png";
			break;
		case 51:
			solo_desc = "No Santa this year. Though we're";
			solo_desc2 = "sure you will get presents from";
			solo_desc3 = "the undead! Will you accept them?";
			solo_img = "gfx/menu/christmas_special.png";
			break;
		case 52:
			solo_desc = "A WW2-era theatre left to rot in";
			solo_desc2 = "West Berlin. See what secrets await";
			solo_desc3 = "in this Theatre of the Damned.";
			solo_img = "gfx/menu/kino_der_toten.png";
			break;
		case 7:
			solo_desc = "Custom Maps made by Community on";
			solo_desc2 = "the Forum and Discord!";
			solo_img = "gfx/menu/custom.png";
			break;
		default:
			solo_desc = "";
			solo_img = "";
			break;
	}

	// Map img
	if (solo_img != "")
		drawpic([0.490*g_width, 0.115*g_height, 0], solo_img, [0.425*g_width, 0.385*g_height, 0], [1,1,1], 1);

	// Draw desc
	drawstring([0.425*g_width, 0.540*g_height, 0], solo_desc, [g_height * 0.03, g_height * 0.03, 1], [0.8, 0.8, 0.8], 1, 0);
	drawstring([0.425*g_width, 0.580*g_height, 0], solo_desc2, [g_height * 0.03, g_height * 0.03, 1], [0.8, 0.8, 0.8], 1, 0);
	drawstring([0.425*g_width, 0.620*g_height, 0], solo_desc3, [g_height * 0.03, g_height * 0.03, 1], [0.8, 0.8, 0.8], 1, 0);
}

void() Draw_Extra_Settings =
{

	// Division lines
	drawfill ([0.025*g_width, 0.325*g_height, 0], [g_height * 0.600, g_height * 0.005, 1], [0.4, 0.4, 0.4], 1, 0);

	local string set_desc = "";

	// Descriptions
	switch(lastActive) {
		case 15:
			set_desc = "Adjust settings relating to Graphical Fidelity.";
			break;
		case 16:
			set_desc = "Customize your Control Scheme.";
			break;
		case 47:
			set_desc = "Adjust settings in relation to how NZ:P Controls.";
			break;
		case 53:
			set_desc = "Adjust Audio Levels.";
			break;
		default:
			set_desc = "";
			break;
	}

	// Draw desc
	drawstring([0.025*g_width, 0.865*g_height, 0], set_desc, [g_height * 0.03, g_height * 0.03, 1], [0.8, 0.8, 0.8], 1, 0);
}

//FIXME -- credits look ugly, font scaling & such
void() Draw_Extra_Credits = 
{
	drawstring([0.03*g_width, 0.15*g_height, 0], "Blubswillrule:   Coding, Models, GFX, Sounds, Music", [g_height * 0.025, g_height * 0.025, 1], [0.8, 0.8, 0.8], 1, 0);
	drawfill ([.03*g_width, 0.15*g_height + g_height*0.025 + 3, 0], [strlen("Blubswillrule")*12.5, 0.0025*g_height, 0], [0.8, 0.8, 0.8], 1, 0);
			
	drawstring([0.03*g_width, 0.20*g_height, 0], "Ju[s]tice:       Maps, Models, GFX", [g_height * 0.025, g_height * 0.025, 1], [0.8, 0.8, 0.8], 1, 0);
	drawfill ([.03*g_width, 0.20*g_height + g_height*0.025 + 3, 0], [strlen("Ju[s]tice")*12.5, 0.0025*g_height, 0], [0.8, 0.8, 0.8], 1, 0);
	
	drawstring([0.03*g_width, 0.25*g_height, 0], "Jukki:           Coding", [g_height * 0.025, g_height * 0.025, 1], [0.8, 0.8, 0.8], 1, 0);
	drawfill ([.03*g_width, 0.25*g_height + g_height*0.025 + 3, 0], [strlen("Jukki")*12.5, 0.0025*g_height, 0], [0.8, 0.8, 0.8], 1, 0);

	drawstring([0.03*g_width, 0.30*g_height, 0], "Biodude:         Sounds", [g_height * 0.025, g_height * 0.025, 1], [0.8, 0.8, 0.8], 1, 0);
	drawfill ([.03*g_width, 0.30*g_height + g_height*0.025 + 3, 0], [strlen("Biodude")*12.5, 0.0025*g_height, 0], [0.8, 0.8, 0.8], 1, 0);

	drawstring([0.03*g_width, 0.35*g_height, 0], "Dr_Mabuse1981:   Coding", [g_height * 0.025, g_height * 0.025, 1], [0.8, 0.8, 0.8], 1, 0);
	drawfill ([.03*g_width, 0.35*g_height + g_height*0.025 + 3, 0], [strlen("Dr_Mabuse1981")*12.5, 0.0025*g_height, 0], [0.8, 0.8, 0.8], 1, 0);

	drawstring([0.03*g_width, 0.40*g_height, 0], "Naievil:         Coding, NX Maintaining", [g_height * 0.025, g_height * 0.025, 1], [0.8, 0.8, 0.8], 1, 0);
	drawfill ([.03*g_width, 0.40*g_height + g_height*0.025 + 3, 0], [strlen("Naievil")*12.5, 0.0025*g_height, 0], [0.8, 0.8, 0.8], 1, 0);

	drawstring([0.03*g_width, 0.45*g_height, 0], "MotoLegacy:      Coding, GFX, Music", [g_height * 0.025, g_height * 0.025, 1], [0.8, 0.8, 0.8], 1, 0);
	drawfill ([.03*g_width, 0.45*g_height + g_height*0.025 + 3, 0], [strlen("MotoLegacy")*12.5, 0.0025*g_height, 0], [0.8, 0.8, 0.8], 1, 0);

	drawstring([0.03*g_width, 0.50*g_height, 0], "Derped_Crusader: Models, GFX", [g_height * 0.025, g_height * 0.025, 1], [0.8, 0.8, 0.8], 1, 0);
	drawfill ([.03*g_width, 0.50*g_height + g_height*0.025 + 3, 0], [strlen("Derped_Crusader")*12.5, 0.0025*g_height, 0], [0.8, 0.8, 0.8], 1, 0);

	drawstring([0.03*g_width, 0.60*g_height, 0], "Special Thanks:", [g_height * 0.025, g_height * 0.025, 1], [0.8, 0.8, 0.8], 1, 0);
	drawfill ([.03*g_width, 0.60*g_height + g_height*0.025 + 3, 0], [strlen("Special Thanks")*12.5, 0.0025*g_height, 0], [0.8, 0.8, 0.8], 1, 0);
			
	drawstring([0.03*g_width, 0.640*g_height, 0], "- Spike:     FTEQW", [g_height * 0.020, g_height * 0.020, 1], [0.8, 0.8, 0.8], 1, 0);
    drawstring([0.03*g_width, 0.660*g_height, 0], "- Shpuld:    Clean-CSQC", [g_height * 0.020, g_height * 0.020, 1], [0.8, 0.8, 0.8], 1, 0);
    drawstring([0.03*g_width, 0.680*g_height, 0], "- Crow_Bar:  DQuake", [g_height * 0.020, g_height * 0.020, 1], [0.8, 0.8, 0.8], 1, 0);
    drawstring([0.03*g_width, 0.700*g_height, 0], "- st1x51:    DQuakePlus", [g_height * 0.020, g_height * 0.020, 1], [0.8, 0.8, 0.8], 1, 0);
	drawstring([0.03*g_width, 0.720*g_height, 0], "- fgsfdsfgs: QuakespasmNX", [g_height * 0.020, g_height * 0.020, 1], [0.8, 0.8, 0.8], 1, 0);
	drawstring([0.03*g_width, 0.740*g_height, 0], "- Azenn:     GFX help", [g_height * 0.020, g_height * 0.020, 1], [0.8, 0.8, 0.8], 1, 0); 
	drawstring([0.03*g_width, 0.760*g_height, 0], "- tavo:      Music help", [g_height * 0.020, g_height * 0.020, 1], [0.8, 0.8, 0.8], 1, 0);
	drawstring([0.03*g_width, 0.780*g_height, 0], "- BCDeshiG:  Heavy bug testing", [g_height * 0.020, g_height * 0.020, 1], [0.8, 0.8, 0.8], 1, 0);
}

void() Draw_Extra_Restart =
{
	drawstring([0.025*g_width, 0.375*g_height, 0], "Are you sure you want to restart?", [g_height * 0.020, g_height * 0.020, 1], [0.8,0.8,0.8], 1, 0);
	drawstring([0.02*g_width, 0.425*g_height, 0], "Your current progress will be lost!", [g_height * 0.020, g_height * 0.020, 1], [0.8,0.8,0.8], 1, 0);
}

void() Draw_Extra_CSettings =
{
	string cset_desc;
	cset_desc = "";

	// ADS Mode
	if (cvar("cl_adsmode") == 0)
		drawstring([0.475*g_width, 0.175*g_height, 0], "HOLD", [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 0);
	else
		drawstring([0.475*g_width, 0.175*g_height, 0], "TOGGLE", [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 0);

	// Look Sensitivity
	drawfill ([0.475*g_width, 0.2255*g_height, 0], [g_height * (cvar("sensitivity")/6), g_height * 0.030, 1], [0.8, 0.8, 0.8], 0, 0);


	// Descriptions
	switch(lastActive) {
		case 48:
			cset_desc = "Switch between Toggle/Hold to Aim Down Sight.";
			break;
		case 49:
			cset_desc = "Change Look Sensitivity to change Cursor Responsiveness.";
			break;
		default:
			cset_desc = "";
			break;
	}

	// Division lines
	drawfill ([0.025*g_width, 0.775*g_height, 0], [g_height * 0.600, g_height * 0.005, 1], [0.4, 0.4, 0.4], 1, 0);

	// Draw desc
	drawstring([0.025*g_width, 0.865*g_height, 0], cset_desc, [g_height * 0.03, g_height * 0.03, 1], [0.8, 0.8, 0.8], 1, 0);
}

void() Draw_Extra_GSettings =
{
	local string fpsval;
	local string vsyncval;
	local string decalval;
	local string partval;
	local string fullval;
	local string retroval;
	local string sval;
	local string arval = "";
	local string resval;
	local string gset_desc = "";

	// Resolution
	resval = strcat(ftos(active_swidth), "x", ftos(active_sheight));
	drawstring([0.475*g_width, 0.175*g_height, 0], resval, [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 0);

	// Aspect Ratio
	switch(aspectratio) {
		case 0:
			arval = "4:3";
			break;
		case 1:
			arval = "5:4";
			break;
		case 2:
			arval = "16:9";
			break;
		case 3:
			arval = "16:10";
			break;
		case 4:
			arval = "21:9";
			break;
		default:
			arval = "ERR";
			break;
	}
	drawstring([0.475*g_width, 0.225*g_height, 0], arval, [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 0);

	// Fullscreen
	if (fullscreenval == 0)
		sval = S_DISABLED;
	else
		sval = S_ENABLED;

	drawstring([0.475*g_width, 0.275*g_height, 0], sval, [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 0);

	// Show FPS
	if (cvar("show_fps") == 0)
		fpsval = S_DISABLED;
	else
		fpsval = S_ENABLED;

	drawstring([0.475*g_width, 0.325*g_height, 0], fpsval, [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 0);

	// Max FPS
	// can't adjust when vsync is enabled, so grey out
	if (!cvar("vid_vsync"))
		drawstring([0.475*g_width, 0.375*g_height, 0], ftos(cvar("cl_maxfps")), [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 0);
	else 
		drawstring([0.475*g_width, 0.375*g_height, 0], ftos(cvar("cl_maxfps")), [g_height * 0.030, g_height * 0.030, 1], [0.4,0.4,0.4], 1, 0);

	// VSync
	if (cvar("vid_vsync") == 0)
		vsyncval = S_DISABLED;
	else
		vsyncval = S_ENABLED;

	drawstring([0.475*g_width, 0.425*g_height, 0], vsyncval, [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 0);
	
	// Field of View
	drawstring([0.475*g_width, 0.475*g_height, 0], ftos(cvar("fov")), [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 0);

	// Brightness
	// have to use a drawfill because of how gamma values are subtracted.. for some reason
	drawfill ([0.475*g_width, 0.5255*g_height, 0], [g_height * (projBr/3), g_height * 0.030, 1], [0.8, 0.8, 0.8], 1, 0);

	// Decals
	if (cvar("nzp_decals") == 0)
		decalval = S_DISABLED;
	else
		decalval = S_ENABLED;

	drawstring([0.475*g_width, 0.575*g_height, 0], decalval, [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 0);

	// Particles
	if (cvar("nzp_particles") == 0)
		partval = S_DISABLED;
	else
		partval = S_ENABLED;

	drawstring([0.475*g_width, 0.625*g_height, 0], partval, [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 0);

	// Fullbright
	if (cvar("r_fullbright") == 0)
		fullval = S_DISABLED;
	else
		fullval = S_ENABLED;

	drawstring([0.475*g_width, 0.675*g_height, 0], fullval, [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 0);

	// Retro
	if (cvar_string("gl_texturemode") == "gl_nearest")
		retroval = S_ENABLED;
	else
		retroval = S_DISABLED;

	drawstring([0.475*g_width, 0.725*g_height, 0], retroval, [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 0);

	// Descriptions
	switch(lastActive) {
		case 17:
			gset_desc = "Adjust Window Resolution.";
			break;
		case 18:
			gset_desc = "Change Window Aspect Ratio.";
			break;
		case 19:
			gset_desc = "Toggle Fullscreen (May fail depending on GPU).";
			break;
		case 20:
			gset_desc = "Toggle Framerate Overlay.";
			break;
		case 21:
			gset_desc = "Increase of Decrease Max Frames per Second.";
			break;
		case 22:
			gset_desc = "Toggle Vertical Sync.";
			break;
		case 23:
			gset_desc = "Adjust Game Field of View.";
			break;
		case 24:
			gset_desc = "Increase or Decrease Game Brightness.";
			break;
		case 25:
			gset_desc = "Toggle Bullet and Explosive Decals.";
			break;
		case 26:
			gset_desc = "Toggle Appearence of (most) Particles.";
			break;
		case 27:
			gset_desc = "Toggle all non-realtime lights (Requires Map Restart).";
			break;
		case 28:
			gset_desc = "Toggle texture filtering.";
			break;
		default:
			gset_desc = "";
			break;
	}

	// Division lines
	drawfill ([0.025*g_width, 0.775*g_height, 0], [g_height * 0.600, g_height * 0.005, 1], [0.4, 0.4, 0.4], 1, 0);

	// Draw desc
	drawstring([0.025*g_width, 0.865*g_height, 0], gset_desc, [g_height * 0.03, g_height * 0.03, 1], [0.8, 0.8, 0.8], 1, 0);
}

void() Draw_Extra_Controls =
{
	local string buttoncon[MAX_BINDS];
	local string binding = "_";

	//prevent warning
	buttoncon[0] = "";

	for (int i = 0; i < MAX_BINDS; i += 1) {
		tokenize(findkeysforcommand(buttonBind[i]));

		if (editBind[i] == FALSE)
			buttoncon[i] = strtoupper(keynumtostring(stof(argv(0))));
		else
			buttoncon[i] = binding;

		if (buttoncon[i] == "01")
			buttoncon[i] = "UNBOUND";

		drawstring([0.475*g_width, (0.175+(0.05*i))*g_height, 0], buttoncon[i], [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 0);
	}
}

// remove prefix and suffix from custom map line
// (maps/) & (.bsp)
string(string s) strip_custominfo =
{
	string s2;
	s2 = substring(s, 5, strlen(s)); // maps/
	s2 = substring(s2, 0, strlen(s2) - 4); // .bsp

	return s2;
}

var struct
{
	float 	occupied;
	float 	map_allow_game_settings;
	float 	map_use_thumbnail;
	string 	map_name;
	string 	map_name_pretty;
	string 	map_desc_1;
	string 	map_desc_2;
	string 	map_desc_3;
	string 	map_desc_4;
	string 	map_desc_5;
	string 	map_desc_6;
	string 	map_desc_7;
	string 	map_desc_8;
	string 	map_author;
} custom_maps[500];

void() Customs_Get =
{
	searchhandle 	maps;
	float 			map_count;

	maps 		= search_begin("maps/*.bsp", 0, 0);
	map_count 	= search_getsize(maps);

	custom_map_pages = ceil(map_count/10);

	for (float i = 0; i < map_count; i++) {
		custom_maps[i].occupied = TRUE;
		custom_maps[i].map_name = strip_custominfo(search_getfilename(maps, i));

		float settings = fopen(strcat("maps/", custom_maps[i].map_name, ".txt"), FILE_READ);
		if (settings != -1) {
			custom_maps[i].map_name_pretty = fgets(settings);
			custom_maps[i].map_desc_1 = fgets(settings);
			custom_maps[i].map_desc_2 = fgets(settings);
			custom_maps[i].map_desc_3 = fgets(settings);
			custom_maps[i].map_desc_4 = fgets(settings);
			custom_maps[i].map_desc_5 = fgets(settings);
			custom_maps[i].map_desc_6 = fgets(settings);
			custom_maps[i].map_desc_7 = fgets(settings);
			custom_maps[i].map_desc_8 = fgets(settings);
			custom_maps[i].map_author = fgets(settings);
			custom_maps[i].map_use_thumbnail = stof(fgets(settings));
			custom_maps[i].map_allow_game_settings = stof(fgets(settings));
			fclose(settings);
		}
		
	}

	current_custom_map_page = 1;

	search_end(maps);
}

void() Draw_Extra_Customs =
{
	string 	custom_map_names[10];
	float 	custom_map_active[10];
	float 	multiplier;

	if (current_custom_map_page > 1)
		multiplier = (current_custom_map_page - 1) * 10;
	else
		multiplier = 0;

	for (float i = 0; i < 10; i++) {
		if (custom_maps[i + multiplier].occupied) {
			custom_map_names[i] = custom_maps[i + multiplier].map_name;
		}
	}

	for (float i = 0; i < 10; i++) {
		if (cursor_pos_x > 0.025*g_width && cursor_pos_x < (0.025*g_width + g_height * 0.6) && 
			cursor_pos_y > (0.175 + (0.05 * i))*g_height && cursor_pos_y < (0.175 + (0.05 * i))*g_height + 
			(0.030*g_height)) {

			if (i != last_active_custom_select)
				localsound_enhanced("sounds/menu/navigate.wav", CHAN_SFX, 1);

			if (customs_interact)
				localcmd(strcat("map "), custom_map_names[i]);
			
			if (last_active_custom_select != -1)
				custom_map_active[last_active_custom_select] = FALSE;
			custom_map_active[i] = TRUE;
			last_active_custom_select = i;
			lastActive = -1;
		}
	}

	for (float i = 0; i < 10; i++) {
		if (custom_map_active[i] == TRUE || last_active_custom_select == i) {
			if (custom_maps[i + multiplier].map_name_pretty)
				drawstring([0.025*g_width, (0.175 + (0.05 * i))*g_height, 0], custom_maps[i + multiplier].map_name_pretty, [g_height * 0.030, g_height * 0.030, 1], [1,0,0], 1, 0);
			else
				drawstring([0.025*g_width, (0.175 + (0.05 * i))*g_height, 0], custom_map_names[i], [g_height * 0.030, g_height * 0.030, 1], [1,0,0], 1, 0);

			float line_increment;
			line_increment = 0;

			if (custom_maps[i + multiplier].map_desc_1 != "" && custom_maps[i + multiplier].map_desc_1 != " ") {
				drawstring([0.425*g_width, 0.540*g_height, 0], custom_maps[i + multiplier].map_desc_1, [g_height * 0.03, g_height * 0.03, 1], [0.8, 0.8, 0.8], 1, 0);
			}
			if (custom_maps[i + multiplier].map_desc_2 != "" && custom_maps[i + multiplier].map_desc_2 != " ") {
				line_increment++;
				drawstring([0.425*g_width, (0.540 + (0.040*line_increment))*g_height, 0], custom_maps[i + multiplier].map_desc_2, [g_height * 0.03, g_height * 0.03, 1], [0.8, 0.8, 0.8], 1, 0);
			}
			if (custom_maps[i + multiplier].map_desc_3 != "" && custom_maps[i + multiplier].map_desc_3 != " ") {
				line_increment++;
				drawstring([0.425*g_width, (0.540 + (0.040*line_increment))*g_height, 0], custom_maps[i + multiplier].map_desc_3, [g_height * 0.03, g_height * 0.03, 1], [0.8, 0.8, 0.8], 1, 0);
			}
			if (custom_maps[i + multiplier].map_desc_4 != "" && custom_maps[i + multiplier].map_desc_4 != " ") {
				line_increment++;
				drawstring([0.425*g_width, (0.540 + (0.040*line_increment))*g_height, 0], custom_maps[i + multiplier].map_desc_4, [g_height * 0.03, g_height * 0.03, 1], [0.8, 0.8, 0.8], 1, 0);
			}
			if (custom_maps[i + multiplier].map_desc_5 != "" && custom_maps[i + multiplier].map_desc_5 != " ") {
				line_increment++;
				drawstring([0.425*g_width, (0.540 + (0.040*line_increment))*g_height, 0], custom_maps[i + multiplier].map_desc_5, [g_height * 0.03, g_height * 0.03, 1], [0.8, 0.8, 0.8], 1, 0);
			}
			if (custom_maps[i + multiplier].map_desc_6 != "" && custom_maps[i + multiplier].map_desc_6 != " ") {
				line_increment++;
				drawstring([0.425*g_width, (0.540 + (0.040*line_increment))*g_height, 0], custom_maps[i + multiplier].map_desc_6, [g_height * 0.03, g_height * 0.03, 1], [0.8, 0.8, 0.8], 1, 0);
			}
			if (custom_maps[i + multiplier].map_desc_7 != "" && custom_maps[i + multiplier].map_desc_7 != " ") {
				line_increment++;
				drawstring([0.425*g_width, (0.540 + (0.040*line_increment))*g_height, 0], custom_maps[i + multiplier].map_desc_7, [g_height * 0.03, g_height * 0.03, 1], [0.8, 0.8, 0.8], 1, 0);
			}
			if (custom_maps[i + multiplier].map_desc_8 != "" && custom_maps[i + multiplier].map_desc_8 != " ") {
				line_increment++;
				drawstring([0.425*g_width, (0.540 + (0.040*line_increment))*g_height, 0], custom_maps[i + multiplier].map_desc_8, [g_height * 0.03, g_height * 0.03, 1], [0.8, 0.8, 0.8], 1, 0);
			}
			if (custom_maps[i + multiplier].map_author != "" && custom_maps[i + multiplier].map_author != " ") {
				line_increment++;
				drawstring([0.425*g_width, (0.560 + (0.040*line_increment))*g_height, 0], custom_maps[i + multiplier].map_author, [g_height * 0.03, g_height * 0.03, 1], [0.8, 0.8, 0], 1, 0);
			}

			if (custom_maps[i + multiplier].map_use_thumbnail) {
				drawpic([0.490*g_width, 0.115*g_height, 0], strcat("menu/custom/", custom_map_names[i], ".png"), [0.425*g_width, 0.385*g_height, 0], [1,1,1], 1);
			}

		} else {
			if (custom_maps[i + multiplier].map_name_pretty)
				drawstring([0.025*g_width, (0.175 + (0.05 * i))*g_height, 0], custom_maps[i + multiplier].map_name_pretty, [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 0);
			else
				drawstring([0.025*g_width, (0.175 + (0.05 * i))*g_height, 0], custom_map_names[i], [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 0);
		}
			
	}

	customs_interact = FALSE;
}

void() Draw_Extra_Achievements =
{
	float multiplier;

	if (current_achievement_page > 1) {
		multiplier = (current_achievement_page - 1) * 3;
	} else {
		multiplier = 0;
		back_gray_out = true;
	}

	for (float i = 0; i < 3; i++) {
		if (i + multiplier > MAX_ACHIEVEMENTS - 1)
			continue;

		string name1, name2;
		string desc1, desc2, desc3, desc4;
		name2 = "";
		desc2 = "";
		desc3 = "";
		desc4 = "";

		if (strlen(achievements[i + multiplier].name) >= 33) {
			name1 = substring(achievements[i + multiplier].name, 0, 33);
			name2 = substring(achievements[i + multiplier].name, 33, strlen(achievements[i + multiplier].name));
		} else {
			name1 = achievements[i + multiplier].name;
		}

		if (substring(name2, 0, 1) == " ")
			name2 = substring(name2, 1, strlen(name2));

		desc1 = substring(achievements[i + multiplier].description, 0, 36);
		desc2 = substring(achievements[i + multiplier].description, 36, 34);
		desc3 = substring(achievements[i + multiplier].description, 70, 35);
		desc4 = substring(achievements[i + multiplier].description, 105, strlen(achievements[i + multiplier].description));

		if (substring(desc2, 0, 1) == " ")
			desc2 = substring(desc2, 1, strlen(desc2));
		
		if (substring(desc3, 0, 1) == " ")
			desc3 = substring(desc3, 1, strlen(desc3));

		if (substring(desc4, 0, 1) == " ")
			desc4 = substring(desc4, 1, strlen(desc4));

		if (achievements[i + multiplier].unlocked == false) {
			int lock_width_pos;

			drawstring([0.450*g_height, (0.150 + (0.212 * i))*g_height, 0], name1, [g_height * 0.030, g_height * 0.030, 1], [0.5,0.5,0.5], 1, 0);
			drawstring([0.450*g_height, (0.180 + (0.212 * i))*g_height, 0], name2, [g_height * 0.030, g_height * 0.030, 1], [0.5,0.5,0.5], 1, 0);

			if (name2 == "") {
				lock_width_pos = stringwidth(name1, 0, [g_height * 0.030, g_height * 0.030, 1]);
				drawstring([0.450*g_height + lock_width_pos, (0.150 + (0.212 * i))*g_height, 0], " (LOCKED)", [g_height * 0.030, g_height * 0.030, 1], [1,0,0], 1, 0);
			} else {
				lock_width_pos = stringwidth(name2, 0, [g_height * 0.030, g_height * 0.030, 1]);
				drawstring([0.450*g_height + lock_width_pos, (0.180 + (0.212 * i))*g_height, 0], " (LOCKED)", [g_height * 0.030, g_height * 0.030, 1], [1,0,0], 1, 0);
			}

			drawstring([0.450*g_height, (0.210 + (0.212 * i))*g_height, 0], desc1, [g_height * 0.030, g_height * 0.030, 1], [1,1,1], 1, 0);
			drawstring([0.450*g_height, (0.240 + (0.212 * i))*g_height, 0], desc2, [g_height * 0.030, g_height * 0.030, 1], [1,1,1], 1, 0);
			drawstring([0.450*g_height, (0.270 + (0.212 * i))*g_height, 0], desc3, [g_height * 0.030, g_height * 0.030, 1], [1,1,1], 1, 0);
			drawstring([0.450*g_height, (0.300 + (0.212 * i))*g_height, 0], desc4, [g_height * 0.030, g_height * 0.030, 1], [1,1,1], 1, 0);

			drawpic([0.025*g_width, (0.150 + (0.212 * i))*g_height, 0], "gfx/achievement/achievement_locked.tga", [0.38*g_height, 0.19*g_height, 0], [1,1,1], 1);
		} else {
			drawstring([0.450*g_height, (0.150 + (0.212 * i))*g_height, 0], name1, [g_height * 0.030, g_height * 0.030, 1], [1,1,0], 1, 0);
			drawstring([0.450*g_height, (0.180 + (0.212 * i))*g_height, 0], name2, [g_height * 0.030, g_height * 0.030, 1], [1,1,0], 1, 0);

			drawstring([0.450*g_height, (0.210 + (0.212 * i))*g_height, 0], desc1, [g_height * 0.030, g_height * 0.030, 1], [1,1,1], 1, 0);
			drawstring([0.450*g_height, (0.240 + (0.212 * i))*g_height, 0], desc2, [g_height * 0.030, g_height * 0.030, 1], [1,1,1], 1, 0);
			drawstring([0.450*g_height, (0.270 + (0.212 * i))*g_height, 0], desc3, [g_height * 0.030, g_height * 0.030, 1], [1,1,1], 1, 0);
			drawstring([0.450*g_height, (0.300 + (0.212 * i))*g_height, 0], desc4, [g_height * 0.030, g_height * 0.030, 1], [1,1,1], 1, 0);

			drawpic([0.025*g_width, (0.150 + (0.212 * i))*g_height, 0], achievements[i + multiplier].img, [0.38*g_height, 0.19*g_height, 0], [1,1,1], 1);
		}
	}
}

void() Draw_Extra_ASettings =
{
	string aset_desc = "";
	float master_volume = cvar("volume");
	float chann1_volume = cvar("snd_channel1volume");
	float chann2_volume = cvar("snd_channel2volume");
	float chann3_volume = cvar("snd_channel3volume");
	float chann4_volume = cvar("snd_channel4volume");
	float chann5_volume = cvar("snd_channel5volume");
	float chann6_volume = cvar("snd_channel6volume");

	// Master Volume
	drawfill ([0.475*g_width, 0.1755*g_height, 0], [g_height * (master_volume/3), g_height * 0.030, 1], [0.8, 0.8, 0.8], 1, 0);

	// Music Volume
	drawfill ([0.475*g_width, 0.2255*g_height, 0], [g_height * (chann1_volume/3), g_height * 0.030, 1], [0.8, 0.8, 0.8], 1, 0);

	// SFX Volume
	drawfill ([0.475*g_width, 0.2755*g_height, 0], [g_height * (chann2_volume/3), g_height * 0.030, 1], [0.8, 0.8, 0.8], 1, 0);

	// Channel 3 Volume
	drawfill ([0.475*g_width, 0.3255*g_height, 0], [g_height * (chann3_volume/3), g_height * 0.030, 1], [0.8, 0.8, 0.8], 1, 0);

	// Channel 4 Volume
	drawfill ([0.475*g_width, 0.3755*g_height, 0], [g_height * (chann4_volume/3), g_height * 0.030, 1], [0.8, 0.8, 0.8], 1, 0);

	// Channel 5 Volume
	drawfill ([0.475*g_width, 0.4255*g_height, 0], [g_height * (chann5_volume/3), g_height * 0.030, 1], [0.8, 0.8, 0.8], 1, 0);

	// Channel 6 Volume
	drawfill ([0.475*g_width, 0.4755*g_height, 0], [g_height * (chann6_volume/3), g_height * 0.030, 1], [0.8, 0.8, 0.8], 1, 0);

	// Descriptions
	switch(lastActive) {
		case 54:
			aset_desc = "Adjusts the overall volume of the game.";
			break;
		case 55:
			aset_desc = "Adjusts the volume of the music in the game.";
			break;
		case 56:
			aset_desc = "Adjusts the volume of sound effects in the game.";
			break;
		case 57:
			aset_desc = "Audio Level for Channel 3.";
			break;
		case 58:
			aset_desc = "Audio Level for Channel 4.";
			break;
		case 59:
			aset_desc = "Audio Level for Channel 5.";
			break;
		case 60:
			aset_desc = "Audio Level for Channel 6.";
			break;
		default:
			aset_desc = "";
			break;
	}

	// Division lines
	drawfill ([0.025*g_width, 0.775*g_height, 0], [g_height * 0.600, g_height * 0.005, 1], [0.4, 0.4, 0.4], 1, 0);

	// Draw desc
	drawstring([0.025*g_width, 0.865*g_height, 0], aset_desc, [g_height * 0.03, g_height * 0.03, 1], [0.8, 0.8, 0.8], 1, 0);
}

float menu_sound_length;

void() Draw_Menu =
{
	// main menu theme iterating
	if (menu_initialized == false && in_menu == MENU_MAIN) {
		localsound_enhanced("tracks/tensioned_by_the_damned.mp3", CHAN_MUSIC, 1);
		menu_sound_length = 490; // have to hard code because soundlength() doesn't like MP3 media it seems..
		menu_initialized = true;
	}

	// restart the track if it has ended
	if (menu_initialized == true && (getsoundtime(self, 1) >= menu_sound_length - 1)) {
		localsound_enhanced("tracks/tensioned_by_the_damned.mp3", CHAN_MUSIC, 1);
	}
	
	// background
	if(serverkey("constate") == "disconnected")
	{
		if(g_width <= g_height * 1.77778)
			drawpic([0,0,0], "menu/bg", [g_height * 1.77778, g_height, 1], [1, 1, 1], 1);
		else
			drawpic([0,0,0], "menu/bg", [g_width, g_height, 1], [1, 1, 1], 1);
	}

	// Darken the BG
	drawfill ([0, 0, 0], [g_width, g_height, 1], [0, 0, 0], 0.4, 0);

	// version string
	if (in_menu == MENU_MAIN || in_menu == MENU_ABOUT || in_menu == MENU_SINGLE || in_menu == MENU_ACHIEVEMENTS 
		|| in_menu == MENU_CUSTOMS || in_menu == MENU_SETTINGS)
		drawstring([(0.925*g_width - strlen(VERSION_STRING)*5*g_width/480), 0.025*g_height, 0], VERSION_STRING, [g_height * 0.03, g_height * 0.03, 1], [0.8, 0.8, 0.8], 1, 0);

	//menu title
	local string title = "";
	switch(in_menu)
	{
		case MENU_MAIN:
			title = "MAIN MENU";
			Draw_Extra_Main();
			break;
		case MENU_SINGLE:
			title = "SOLO";
			Draw_Extra_Solo();
			break;
		case MENU_MULTI:
			title = "COOP";
			break;
		case MENU_ABOUT:
			title = "CREDITS";
			Draw_Extra_Credits();
			break;
		case MENU_PAUSE:
			title = "PAUSED";
			break;
		case MENU_IGS:
		case MENU_SETTINGS:
			title = "SETTINGS";
			Draw_Extra_Settings();
			break;
		case MENU_GSETTINGS:
			title = "GRAPHICS SETTINGS";
			Draw_Extra_GSettings();
			break;
		case MENU_CSETTINGS:
			title = "CONTROLS";
			Draw_Extra_Controls();
			break;
		case MENU_RES:
			title = "RESTART";
			Draw_Extra_Restart();
			break;
		case MENU_CUSTOMS:
			title = "CUSTOM MAPS";
			Draw_Extra_Customs();
			break;
        case MENU_ACHIEVEMENTS:
            title = "ACHIEVEMENTS";
            Draw_Extra_Achievements();
            break;
		case MENU_CONSETTINGS:
			title = "CONTROL SETTINGS";
			Draw_Extra_CSettings();
			break;
		case MENU_AUDSETTINGS:
			title = "AUDIO SETTINGS";
			Draw_Extra_ASettings();
			break;
		default:
			title = "Nazi Zombies: Portable";
	}
	
	drawstring([0.025*g_width, 0.025*g_width, 0], title, [g_height * 0.045, g_height * 0.045, 1], [0.8, 0.8, 0.8], 1, 0);

	//Update buttons
	local float i;

	for(i = 0; i < BUTTONS_COUNT; i++)
	{
		Update_Button(i);
	}

	// TODO - Controller Support
	/*if (cvar("in_xinput")) {
		Controller_UpdateButton();
	}*/
};
