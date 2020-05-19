//
//	Player.qc - Various stuff done for the player, including per-frame functions like PlayerPreThink and PlayerPostThink, also client specific stuff like PutClientInServer etc.
//

void() PlayerJump =
{
	if (!(self.flags & FL_ONGROUND))
		return;

	if ( !(self.flags & FL_JUMPRELEASED) )
		return;

	if (self.downed) {
		return;
	}
			
	self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
	sound(self, CHAN_VOICE, "sounds/player/jump.wav", 1, 1.75);
	self.button2 = 0;
}

void() PlayerPreThink =
{

	if (self.downed) {
		self.maxspeed = 30;
	} else {
		self.maxspeed = 175;
		if (self.sprinting) {
			self.maxspeed *= 1.66;
		} else if (self.zoom == 1) {
			self.maxspeed *= 0.5;
		}

		self.maxspeed *= GetWeaponWalkSpeed(self.weapon);
	}
	if(self.isspec != 0)
	{
		if(self.button0)
		{
			self.aiment = find(self.aiment, classname, "player");
			if(self.aiment != world)
			{
				sprint(self, PRINT_HIGH, "Now spectating ");
				sprint(self, PRINT_HIGH, self.aiment.netname);
				sprint(self, PRINT_HIGH, "\n");
				
				self.solid = SOLID_NOT;
				self.movetype = MOVETYPE_NONE;
			}
			else
			{
				sprint(self, PRINT_HIGH, "Freefly spectate\n");
				self.movetype = MOVETYPE_FLY;
			}
		}
		if(self.aiment != world)
		{
			self.origin = self.aiment.origin;
			self.angles = self.aiment.v_angle;
			self.velocity = self.aiment.velocity;
			self.fixangle = TRUE;
		}
		return;
	}
	
	if (cvar("waypoint_mode")) {
		Waypoint_Logic();
	} else if (cvar("navmesh_edit_mode")) {
		Navmesh_Editor_Logic();
	} else {
		Weapon_Logic();
	}
	

	if(self.button2)
	{
		PlayerJump ();
	}
	else
		self.flags = self.flags | FL_JUMPRELEASED;
};

void() PlayerPostThink =
{
	if(self.isspec)
		return;
	
	//landsound
	if((self.oldvelocity_z < -10) && (self.flags & FL_ONGROUND))
	{
		if(self.oldvelocity_z < -270)
			sound(self, CHAN_BODY, "sounds/player/land.wav", 1, 1.75);
		self.lastsound_time = time - 0.15;
	}
	
	//footsteps
	if((vlen(self.velocity) > 315) &&( time - self.lastsound_time > 0.3) && (self.flags & FL_ONGROUND))
	{
		local float movelen = vlen(input_movevalues);
		if(movelen > 300)
		{
			local float ran = random();
			if(ran > 0.8)
				sound(self, CHAN_BODY, "sounds/player/footstep1.wav", 0.6, 2.5);
			else if(ran > 0.6)
				sound(self, CHAN_BODY, "sounds/player/footstep2.wav", 0.6, 2.5);
			else if(ran > 0.4)
				sound(self, CHAN_BODY, "sounds/player/footstep3.wav", 0.6, 2.5);
			else if(ran > 0.2)
				sound(self, CHAN_BODY, "sounds/player/footstep4.wav", 0.6, 2.5);
			else
				sound(self, CHAN_BODY, "sounds/player/footstep5.wav", 0.6, 2.5);
			self.lastsound_time = time;
		}
	}
	
	if (self.health_delay < time && self.health != self.max_health && !self.downed)
	{
		self.health = self.health + 5;
		if (self.max_health < self.health)
			self.health = self.max_health;
	}
	
	if (self.progress_bar) {
		if (self.progress_bar < time) {
			GetUp();
			self.progress_bar = 0;
			self.progress_bar_time = 0;
			self.progress_bar_percent = 0;
		} else {
			float remaining = self.progress_bar - time;
			self.progress_bar_percent = (remaining / self.progress_bar_time);
		}
	}


	if (self.sprinting) {
		if (!self.velocity) {
			W_SprintStop();
		}
		
		if (self.perks & P_STAMIN) {
			self.stamina = self.stamina - 5*frametime;
		} else {
			self.stamina = self.stamina - (10*frametime);
		}

		if (self.stamina <= 0) {
			W_SprintStop();
		}
	} else if (self.stamina < 3) 	{
		self.stamina = self.stamina + 10*frametime;
		if (self.stamina > 3) {
			self.stamina = 3;
		}
	}

	self.oldvelocity = self.velocity;
};

void() ClientKill =
{
};

//called when a client connects to the server
void() ClientConnect =
{
	stuffcmd(self, "fog 0.075\n"); // naievil -- temp reliable fog

	bprint(PRINT_HIGH, self.netname); //print player name
	bprint(PRINT_HIGH, " connected.\n");
};

void() PlayerSpawn =
{
	local entity spawnpoint;
	spawnpoint = find(world, classname, "info_player_start");
	
	self.isspec = FALSE;
	self.classname = "player";
	self.solid = SOLID_SLIDEBOX;
	setmodel(self, "models/player.mdl");
	self.movetype = MOVETYPE_WALK;
	self.max_health = self.health = 100;
	self.origin = spawnpoint.origin + [0,0,1];
	self.angles = spawnpoint.angles;
	self.fixangle = TRUE;
	setsize(self, [-16, -16, -24], [16, 16, 32]);
	self.view_ofs = VEC_VIEW_OFS; // naievil -- set view_ofs to 32 to maintain half life (64) sizes

	self.currentammo = 32;
	self.currentmag = 8;
	self.weapon = W_COLT;
	self.grenades = self.grenades | 1;  // add frag grenades to player inventory
	self.primary_grenades = 0; 			// start off without grenades
	self.pri_grenade_state = 0; 		// defines that frag grenades are for player first, not betty
	self.secondary_grenades = 0;

	/*self.secondaryweapon = W_KAR_SCOPE;
	self.secondaryammo = getWeaponAmmo(self.secondaryweapon);
	self.secondarymag = getWeaponMag(self.secondaryweapon);*/
	//self.secondarymag2 = getWeaponMag(self.secondaryweapon);

	addmoney(self, 500, 0);

	self.weaponmodel = GetWeaponModel(self.weapon, 0);// Give weapon model

	SwitchWeapon(self.weapon);
	UpdateV2model("", 0);
	stuffcmd(self, "cl_gunx 8;cl_guny 16;cl_gunz 25\n");

	SetRound(self, rounds);

	self.stamina = 3;

	if (rounds < 1) {
		sound (self, CHAN_AUTO, "sounds/rounds/splash.wav", 1, ATTN_NONE);//temporarily here.
	}
};

void() SpectatorSpawn =
{
	local entity spawnpoint;
	spawnpoint = find(world, classname, "info_player_start");
	
	self.isspec = TRUE;
	self.classname = "spectator";
	self.solid = SOLID_NOT;
	setmodel(self, "");
	self.movetype = MOVETYPE_FLY;
	self.origin = spawnpoint.origin + [0,0,1];
	self.fixangle = TRUE;
	setsize(self, [-16, -16, -24], [16, 16, 32]);
	self.view_ofs = '0 0 22';
	self.aiment = world;
};

//called when a client loads a map
void() PutClientInServer =
{
	stuffcmd(self, "promptjoin\n");
	SpectatorSpawn();
};

//called when client disconnects from the server
void() ClientDisconnect =
{
	bprint(PRINT_HIGH, self.netname);
	bprint(PRINT_HIGH, " has left the game.\n");
	remove(self);
};


void() SetNewParms =
{
};

void() SetChangeParms =
{
};

void() info_player_start =
{
	
};

void(string com) SV_ParseClientCommand =
{
	if(com == "joingame")
	{
		if(self.isspec)
		{
			bprint(PRINT_HIGH, self.netname);
			bprint(PRINT_HIGH, " has joined the game.\n");
			PlayerSpawn();
		}
		else
			sprint(self, PRINT_HIGH, "You're already in game!\n");
	}
	else if(com == "specgame")
	{
		if(self.isspec)
			return;
		else
		{
			/*SpectatorSpawn();
			bprint(PRINT_HIGH, self.netname); //print player name
			bprint(PRINT_HIGH, " has joined the spectators.\n");*/
			
			PlayerSpawn();
		}
	}
	else
	{
		tokenize(com);

		switch(argv(0))
		{
			case "give":
				float wep = stof(argv(1));

				if (wep) {
					if (!self.secondaryweapon) {
						WeaponSwitch(self);
					}
					float startframe, endframe;
					string modelname;

					self.weapon = wep;
					self.currentammo = getWeaponAmmo(wep);
					self.currentmag = getWeaponMag(wep);
					if (IsDualWeapon(wep)) {
						self.currentmag2 = self.currentmag;
					}

					startframe = GetFrame(self.weapon,TAKE_OUT_START);
					endframe = GetFrame(self.weapon,TAKE_OUT_END);
					modelname = GetWeaponModel(wep, 0);

					SwitchWeapon(wep);
					
					Set_W_Frame (startframe, endframe, 0, 0, 0, SUB_Null, modelname, false, S_BOTH);//FIXME
					
					self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = 0;
				}
		}
	}
};

void() SV_RunClientCommand =
{
	runstandardplayerphysics(self);
}