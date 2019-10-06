//
//	Menu stuff.. very ugly :p
// 	Typos FTW!
//


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
	print("loading ndu\n");
	localcmd("map ndu\n");
};

void() menu_loadwh =
{
	print("loading warehouse\n");
	localcmd("map warehouse\n");
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
}

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

//rmb null
void() null = {
	return;
}

/*

	MENU GUIDELINES (to perserve consistency)
	
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
} buttons[] =
{
	//Main
	{[0.025, 0.175, 0], "Solo", -1, menu_single, null, MENU_MAIN},
	{[0.025, 0.225, 0], "Cooperative", -1, menu_multi, null, MENU_MAIN},
	{[0.025, 0.300, 0], "Settings", -1, menu_settings, null, MENU_MAIN},
	{[0.025, 0.375, 0], "Achievements", -1, menu_main, null, MENU_MAIN},
	{[0.025, 0.450, 0], "Credits", -1, menu_about, null, MENU_MAIN},
	{[0.025, 0.525, 0], "Quit", -1, menu_quit, null, MENU_MAIN},

	//Solo
	{[0.025, 0.175, 0], "Nacht der Untoten", -1, menu_loadndu, null, MENU_SINGLE},
	{[0.025, 0.225, 0], "Warehouse", -1, menu_loadwh, null, MENU_SINGLE},
	{[0.025, 0.300, 0], "Custom Maps", -1, menu_customs, null, MENU_SINGLE},

	//Pause
	{[0.025, 0.500, 0], "Resume", -1, menu_resume, null, MENU_PAUSE},
	{[0.025, 0.550, 0], "Restart", -1, menu_restart, null, MENU_PAUSE},
	{[0.025, 0.600, 0], "Settings", -1, menu_settings, null, MENU_PAUSE},
	{[0.025, 0.650, 0], "Main Menu", -1, menu_main, null, MENU_PAUSE},

	//Restart
	{[0.025, 0.500, 0], "Yes", -1, menu_resy, null, MENU_RES},
	{[0.025, 0.550, 0], "No", -1, menu_resn, null, MENU_RES},

	//Settings
	{[0.025, 0.175, 0], "Graphics Settings", -1, menu_graphics, null, MENU_SETTINGS + MENU_IGS},
	{[0.025, 0.225, 0], "Controls", -1, menu_controls, null, MENU_SETTINGS + MENU_IGS},

	//Graphics
	{[0.025, 0.175, 0], "Show FPS", -1, settings_fps, settings_fps, MENU_GSETTINGS},
	{[0.025, 0.225, 0], "Brightness", -1, settings_brite, settings_brite2, MENU_GSETTINGS},

	//Controls
	{[0.025, 0.175, 0], "Walk Forward", -1, bind_walkf, null, MENU_CSETTINGS},
	{[0.025, 0.225, 0], "Walk Backward", -1, bind_walkb, null, MENU_CSETTINGS},
	{[0.025, 0.275, 0], "Walk Left", -1, bind_walkl, null, MENU_CSETTINGS},
	{[0.025, 0.325, 0], "Walk Right", -1, bind_walkr, null, MENU_CSETTINGS},
	{[0.025, 0.375, 0], "Jump", -1, bind_jump, null, MENU_CSETTINGS},
	{[0.025, 0.425, 0], "Sprint", -1, bind_sprint, null, MENU_CSETTINGS},
	{[0.025, 0.475, 0], "Change Stance", -1, bind_stance, null, MENU_CSETTINGS},

	{[0.025, 0.525, 0], "Weapon Next", -1, bind_wpnn, null, MENU_CSETTINGS},
	{[0.025, 0.575, 0], "Weapon Previous", -1, bind_wpnp, null, MENU_CSETTINGS},

	{[0.025, 0.625, 0], "Interact", -1, bind_interact, null, MENU_CSETTINGS},
	{[0.025, 0.675, 0], "Reload", -1, bind_reload, null, MENU_CSETTINGS},
	{[0.025, 0.725, 0], "Melee", -1, bind_knife, null, MENU_CSETTINGS},
	{[0.025, 0.775, 0], "Grenade", -1, bind_nade, null, MENU_CSETTINGS},
	{[0.025, 0.825, 0], "Secondary Grenade", -1, bind_switchnade, null, MENU_CSETTINGS},

	//Everything, pretty much
	{[0.025, 0.925, 0], "Back", -1, menu_back, null, MENU_SINGLE + MENU_MULTI + MENU_SETTINGS + MENU_ABOUT + 
													 MENU_IGS + MENU_GSETTINGS + MENU_CSETTINGS + MENU_CUSTOMS},
};

//REMEMBER TO UPDATE THIS CONST IF YOU ADD BUTTONS
const float BUTTONS_COUNT = 34;
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

	
	if(buttons[index].active > 0) {
		drawstring(pos, buttons[index].text, [g_height * 0.030, g_height * 0.030, 1], [1,0,0], 1, 1);
	} else {
		drawstring(pos, buttons[index].text, [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 1);
	}

	if (cursor_pos_x > pos_x && cursor_pos_x < pos_x + (g_height * 0.6) && cursor_pos_y > pos_y && cursor_pos_y < pos_y + btnscale) {
		if (index != lastActive)
			sound(self, 0, "sounds/menu/navigate.wav", 1, ATTN_NONE);
		
		buttons[index].active = 1;
		lastActive = index;
	}

	if (lastActive == -1) {
		buttons[index].active = 0;
	} else {
		buttons[lastActive].active = 1;
	}
		

	if(buttons[index].active > 0)
	{
		buttons[index].active -= frametime * 15;
		if(buttons[index].active < 0)
			buttons[index].active = 0;
	}
};

float xd;
void() Controller_UpdateButton =
{
	/*if (GPActive[0]) {

	}*/
	drawstring([0.025*g_width, 0.375*g_height, 0], ftos(GPActive[2]), [g_height * 0.020, g_height * 0.020, 1], [0.8,0.8,0.8], 1, 1);
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
	//local vector scale = buttons[index].scale;
	//scale_x *= g_width;
	//scale_y *= g_height;
	
	if (cursor_pos_x > pos_x && cursor_pos_x < pos_x + (g_height * 0.6) && cursor_pos_y > pos_y && cursor_pos_y < pos_y + btnscale) {
		if (type == 0) { //left click
			buttons[index].action();
		} else { //right click
			buttons[index].action2();
		}
		
		lastActive = -1;
		sound(self, 0, "sounds/menu/enter.wav", 1, ATTN_NONE); //FIXME - prevent sound from playing if action2 is null!
	}
};


void(float type) Menu_Click =
{
	float i;
	for(i = 0; i < BUTTONS_COUNT; i++)
	{
		Button_Click(i, type);
	}
};


//FIXME -- credits look ugly, font scaling & such
void() Draw_Extra_Credits = 
{
	drawstring([0.03*g_width, 0.15*g_height, 0], "Blubswillrule: Coding, Models, GFX, Sounds,", [g_height * 0.025, g_height * 0.025, 1], [0.8, 0.8, 0.8], 1, 1);
	drawstring([0.03*g_width, 0.185*g_height, 0], "               Animations, Music", [g_height * 0.025, g_height * 0.025, 1], [0.8, 0.8, 0.8], 1, 1);
	drawfill ([.03*g_width, 0.15*g_height + g_height*0.025 + 3, 0], [strlen("Blubswillrule")*12.5, 0.0025*g_height, 0], [0.8, 0.8, 0.8], 1);
			
	drawstring([0.03*g_width, 0.25*g_height, 0], "Ju[s]tice:     Maps, Models, GFX", [g_height * 0.025, g_height * 0.025, 1], [0.8, 0.8, 0.8], 1, 1);
	drawfill ([.03*g_width, 0.25*g_height + g_height*0.025 + 3, 0], [strlen("Ju[s]tice")*12.5, 0.0025*g_height, 0], [0.8, 0.8, 0.8], 1);

				
	drawstring([0.03*g_width, 0.35*g_height, 0], "Jukki:         Coding", [g_height * 0.025, g_height * 0.025, 1], [0.8, 0.8, 0.8], 1, 1);
	drawfill ([.03*g_width, 0.35*g_height + g_height*0.025 + 3, 0], [strlen("Jukki")*12.5, 0.0025*g_height, 0], [0.8, 0.8, 0.8], 1);
												
	drawstring([0.03*g_width, 0.45*g_height, 0], "Special Thanks:", [g_height * 0.025, g_height * 0.025, 1], [0.8, 0.8, 0.8], 1, 1);
	drawfill ([.03*g_width, 0.45*g_height + g_height*0.025 + 3, 0], [strlen("Special Thanks")*12.5, 0.0025*g_height, 0], [0.8, 0.8, 0.8], 1);
			
	drawstring([0.25*g_width, 0.525*g_height, 0], "- Spike", [g_height * 0.025, g_height * 0.025, 1], [0.8, 0.8, 0.8], 1, 1);
	drawstring([0.25*g_width, 0.575*g_height, 0], "- Shpuld", [g_height * 0.025, g_height * 0.025, 1], [0.8, 0.8, 0.8], 1, 1);
	drawstring([0.25*g_width, 0.625*g_height, 0], "- DR_Mabuse1981", [g_height * 0.025, g_height * 0.025, 1], [0.8, 0.8, 0.8], 1, 1);
	drawstring([0.25*g_width, 0.675*g_height, 0], "- Naievil", [g_height * 0.025, g_height * 0.025, 1], [0.8, 0.8, 0.8], 1, 1); 
	drawstring([0.25*g_width, 0.725*g_height, 0], "- Biodude", [g_height * 0.025, g_height * 0.025, 1], [0.8, 0.8, 0.8], 1, 1);
	drawstring([0.25*g_width, 0.775*g_height, 0], "- MotoLegacy", [g_height * 0.025, g_height * 0.025, 1], [0.8, 0.8, 0.8], 1, 1);
}

void() Draw_Extra_Restart =
{
	drawstring([0.025*g_width, 0.375*g_height, 0], "Are you sure you want to restart?", [g_height * 0.020, g_height * 0.020, 1], [0.8,0.8,0.8], 1, 1);
	drawstring([0.02*g_width, 0.425*g_height, 0], "Your current progress will be lost!", [g_height * 0.020, g_height * 0.020, 1], [0.8,0.8,0.8], 1, 1);
}

void() Draw_Extra_GSettings =
{
	local string fpsval;

	if (cvar("show_fps") == 0)
		fpsval = S_DISABLED;
	else
		fpsval = S_ENABLED;

	drawstring([0.475*g_width, 0.175*g_height, 0], fpsval, [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 1);

	//have to use a drawfill because of how gamma values are subtracted.. for some reason
	drawfill ([0.475*g_width, 0.2255*g_height, 0], [g_height * (projBr/3), g_height * 0.030, 1], [0.8, 0.8, 0.8], 1);
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

		drawstring([0.475*g_width, (0.175+(0.05*i))*g_height, 0], buttoncon[i], [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 1);
	}
}

float page;
string custom_map_name[10];
float custom_map_index[10];
void() Draw_Extra_Customs =
{
	// get all .BSPs in the maps folder
	searchhandle maps = search_begin("maps/*.bsp", 0, 0);
	// the amount of maps in the folder
	//float mapcount = search_getsize(maps);

	// the number of maps in the last page < 10
	//float remain = mapcount % 10;

	/*

	0.025, 0.175, 0], "Solo", -1, menu_single, null, MENU_MAIN},
	{[0.025, 0.225,
	*/

	float a;

	//if (a < 10)
	//	a = mapcount;
	//else
	a = 9;

	for(float i = 0; i < a; i++) {
		custom_map_name[i] = search_getfilename(maps, i);
		drawstring([0.025*g_width, (0.175 + (0.05 * i))*g_height, 0], custom_map_name[a], [g_height * 0.030, g_height * 0.030, 1], [0.8,0.8,0.8], 1, 1);
	}

	//drawstring([0.025*g_width, 0.375*g_height, 0], ftos(remain), [g_height * 0.020, g_height * 0.020, 1], [0.8,0.8,0.8], 1, 1);
}

void() Draw_Menu =
{
	//background
	if(serverkey("constate") == "disconnected")
	{
		if(g_width <= g_height * 1.77778)
			drawpic([0,0,0], "menu/bg", [g_height * 1.77778, g_height, 1], [1, 1, 1], 1);
		else
			drawpic([0,0,0], "menu/bg", [g_width, g_height, 1], [1, 1, 1], 1);
	}

	//Gradient on the background
	drawpic([0,0,0], "menu/gradient_l2r", [0.75*g_width, g_height, 1], [1, 1, 1], 1);

	//menu title
	local string title = "";
	switch(in_menu)
	{
		case MENU_MAIN:
			title = "MAIN MENU";
			break;
		case MENU_SINGLE:
			title = "SOLO";
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
		default:
			title = "Nazi Zombies: Portable";
	}
	
	drawstring([0.025*g_width, 0.025*g_width, 0], title, [g_height * 0.045, g_height * 0.045, 1], [0.8, 0.8, 0.8], 1, 1);

	//Update buttons
	local float i;

	for(i = 0; i < BUTTONS_COUNT; i++)
	{
		Update_Button(i);
	}

	if (cvar("in_xinput")) {
		Controller_UpdateButton();
	}
};