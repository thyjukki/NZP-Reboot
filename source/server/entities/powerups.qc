.float zombie_drop_id;
.float flashtime;
.float flash_step;

void() maxammo =
{
	entity tempe, temp;
	
	tempe = find (world, classname, "player");
	while (tempe)
	{	
		if (!tempe.downed)
		{
			if (tempe.weapon)
			{
				tempe.currentammo = getWeaponAmmo(tempe.weapon);
				if (!tempe.currentmag)
				{
					temp = self;
					self = tempe;
					W_Reload(S_BOTH);
					self = temp;
				}
			}
			if (tempe.secondaryweapon)
				tempe.secondaryammo = getWeaponAmmo(tempe.secondaryweapon);
			
			tempe.primary_grenades = 4;
			
			if (tempe.grenades & 2)
        tempe.secondary_grenades = 2;
		}
		#ifdef PC
		ScrollText("MAX AMMO!", tempe);
		#endif
		
		tempe = find (tempe, classname, "player");
	}
}


void() nuke =
{
	local entity oldself;
	local entity who;
	local float killcount;
	oldself = self;
	
	killcount = 0;
	
	who = find(world,classname,"ai_zombie");
	while(who != world)
	{
		if(who.health)
		{
			self = who;
			self.th_die();
			self = oldself;
			killcount++;
		}
		
		who = find(who,classname,"ai_zombie");
	}

	#ifndef PSP
	if (killcount == 1) {
		GiveAchievement(4, pl1);
	}
	#endif
	
	who = find(world,classname,"player");
	while(who)
	{
		addmoney(who, 400, 1);
		who = find(who,classname,"player");
	}
}

void() carpenter =
{
	local entity oldself;
	local entity who;
	oldself = self;
	local float exp;
  
	if (x2_finished > time)
		exp = 2;
	else
		exp = 1;
	
	
	who = find(world,classname,"window");
	while(who != world)
	{
		if(who.health < 6 && who.health != -10)//-10 is for boardless windows
		{
			self = who;
			window_carpenter_1 ();
			who.health = 6;
			self = oldself;
		}
		
		who = find(who,classname,"window");
	}
	
	who = find(world,classname,"player");
	while(who)
	{
		addmoney(who,200*exp,1);
		
		who = find(who,classname,"player");
	}
	total_windows_down = 0;
}

void() give_perk =
{
  	local float t;
  
  	t = random();
  	
  	if (t < 0.166 && !(other.perks & P_REVIVE)) {
  		other.perks = other.perks | 8;
  	} else if (t < 0.333 && !(other.perks & P_JUG)) {
  		other.perks = other.perks | 1;
  	} else if (t < 0.5 && !(other.perks & P_DOUBLE)) {
		other.perks = other.perks | 2;
  	} else if (t < 0.6666 && !(other.perks & P_SPEED)) {
  		other.perks = other.perks | 4;
  	} else if (t < 0.8333 && !(other.perks & P_FLOP)) {
  		other.perks = other.perks | 16;
  	} else if (t < 1 && !(other.perks & P_STAMIN)) {
  		other.perks = other.perks | 32;
  	} else if (t <= 1 && (other.perks & P_STAMIN) && (other.perks & P_REVIVE) && (other.perks & P_JUG) && (other.perks & P_DOUBLE) && (other.perks & P_SPEED) && (other.perks & P_FLOP))
		return;
	else
    	give_perk();
}




void() powerup_flash =
{
	if(self.flash_step == 0)
	{
		self.flash_step = 1;
		self.flashtime = time + 3;
		self.nextthink = time + 0.6;
	}
	else if(self.flash_step == 1)
	{
		self.nextthink = time + 0.6;
		
		if(self.flashtime < time)
		{
			self.flash_step = 2;
			self.nextthink = time + 0.3;
			self.flashtime = time + 3;
		}

	}
	else if(self.flash_step == 2)
	{
		self.nextthink = time + 0.3;
		
		if(self.flashtime < time)
		{
			self.flash_step = 3;
			self.nextthink = time + 0.15;
			self.flashtime = time + 3;
		}
		
	}
	else if(self.flash_step == 3)
	{
		self.nextthink = time + 0.15;
		if(self.flashtime < time)
		{
			// moto - we used to setmodel blank here too, but it caused errors with the sprite.
			remove(self.owner);
			remove(self);
			return;
		}
	}
	
	if(self.model == "")
	{
		if(self.zombie_drop_id == 1)
			setmodel(self,"progs/Misc/maxammo!.mdl");
		if(self.zombie_drop_id == 2)
			setmodel(self,"progs/Misc/x2!.mdl");
		if(self.zombie_drop_id == 3)
			setmodel(self,"progs/Misc/instakill!.mdl");
		if(self.zombie_drop_id == 4)
			setmodel(self,"progs/Misc/nuke!.mdl");
		if(self.zombie_drop_id == 5)
			setmodel(self,"progs/Misc/carpenter!.mdl");
	}
	else
	{
		setmodel(self,"");
	}
};

void() powerup_play_sound =
{
	// play the VO clip
	sound(self, CHAN_VOICE, self.powerup_vo, 1, ATTN_NONE);

	// finally, remove the (invisible/inactive) powerup.
	remove(self);
}

void() powerup_touch =
{
  local float t;
  
  t = random();
  
	if(other.classname == "player")
	{
		// pickup sound
		sound(self.owner,CHAN_VOICE,"sounds/pu/pickup.wav",1,ATTN_NONE);

		// add a slight delay before sound play
		self.think = powerup_play_sound;
		self.nextthink = time + 1;

		// hide powerup until we remove (after sound)
		setmodel(self, "");
		self.effects = 0;
		self.touch = SUB_Null;
		remove(self.owner);

		// slight screen flash
		stuffcmd(other, "bf\n");

		// powerup effects
		switch(self.zombie_drop_id) {
			// max ammo
			case 1:
				maxammo();
				break;
			// double points
			case 2:
				x2_finished = time + 30;
				other.x2_icon = true;
				break;
			// insta kill
			case 3:
				instakill_finished = time + 30;
				other.insta_icon = true;
				break;
			// nuke
			case 4:
				nuke();
				break;
			// carpenter
			case 5:
				carpenter();
				break;
			// free perk
			case 6:
				give_perk();
				break;
			// broken!
			default:
				centerprint(other, strcat("INVALID POWER-UP ID: ", ftos(self.zombie_drop_id)));
				break;
		}
	}
};

void() sparkle_think =
{
	local float f;
	f = self.frame;
	local float r;
	while(f == self.frame)
	{
		r = random();
		r = ((r > 0.2) ? 1 : 0) + ((r > 0.4) ? 1 : 0) + ((r > 0.6) ? 1 : 0) + ((r > 0.8) ? 1 : 0);
		f = r;
	}
	self.frame = f;
	
	self.think = sparkle_think;
	self.nextthink = time + 0.1;
	
	if(self.calc_time <= time)
	{
		sound(self,CHAN_VOICE,"sounds/pu/powerup.wav",0.6,ATTN_NORM);
		self.calc_time = time + 2.998;
	}
	
};

// the powerup's model
string(float type) getPowerupModel = 
{
	switch(type) {
		case 1: return "progs/Misc/maxammo!.mdl"; break;
		case 2: return "progs/Misc/x2!.mdl"; break;
		case 3: return "progs/Misc/instakill!.mdl"; break;
		case 4: return "progs/Misc/nuke!.mdl"; break;
		case 5: return "progs/Misc/carpenter!.mdl"; break;
		default: return ""; break;
	}
}

// the powerup's pick up voice clip
string(float type) getPowerupVO =
{
	switch(type) {
		case 1: return "sounds/pu/maxammo.wav"; break;
		case 2: return "sounds/pu/double_points.wav"; break;
		case 3: return "sounds/pu/insta_kill.wav"; break;
		case 4: return "sounds/pu/nuke.wav"; break;
		case 5: return "sounds/pu/carpenter.wav"; break;
		default: return ""; break;
	}

}

float last_pu;
void(vector where, float type) Spawn_Powerup =
{
	entity new_powerup;
	float t, total_powerups, id;

	new_powerup = spawn();
	new_powerup.origin = where;
	setorigin(new_powerup, new_powerup.origin);
	new_powerup.solid = SOLID_TRIGGER;
	new_powerup.classname = "item_powerup";

	
	setsize (new_powerup, VEC_HULL_MIN, VEC_HULL_MAX);
	new_powerup.movetype = MOVETYPE_NONE;

    new_powerup.effects = EF_FULLBRIGHT;
    #ifndef PC
    new_powerup.effects = EF_GREEN;
    #else
    Light_Green(new_powerup);
    #endif
	
	//=================== Sparkle Effects =====================
	
	entity twlt_Sparkle;
	twlt_Sparkle = spawn();
	new_powerup.owner = twlt_Sparkle; //just a reference so power up can delete the sparkle later on
	
	setorigin(twlt_Sparkle,where);
	#ifndef PC
	setmodel(twlt_Sparkle,"progs/Sprites/sprkle.spr");
	#endif
	twlt_Sparkle.think = sparkle_think;
	twlt_Sparkle.nextthink = time + 0.1;
	sound(twlt_Sparkle,CHAN_VOICE,"sounds/pu/powerup.wav",0.6,ATTN_NORM);
	
	sound(new_powerup,CHAN_AUTO,"sounds/pu/drop.wav",1,ATTN_NONE);
	
	//========================================================
	t = random();

	// Specific Power-Ups (for dogs)
	if (type) {
		setmodel(new_powerup, getPowerupModel(type));
		new_powerup.zombie_drop_id = type;
		new_powerup.powerup_vo = getPowerupVO(type);
	} else {
		//
		// Instead of making weird checks to change our divisible number, let's just
		// check all of that stuff afterwards, to avoid any bad math/logic..
		//

		total_powerups = 5; // nuke, insta, 2x, maxammo

		// determine id
		for (float i = 1; i < total_powerups + 1; i++) {
			if (t > (i/total_powerups)) {
				id = i;
			}
		}

		// check if we are elligible for a carpenter, and if so see if we want it. (override)
		if (total_windows_down >= 5) {
			t = random();

			if (t > (1/3)) {
				id = 5;
			}
		}

		// another elligibility check for the perk drop
		if (G_PERKPOWER && rounds >= 15) {
			t = random();

			if (t > (1/10)) {
				id = 6;
			}
		}

		// failsafe in case my logic is still horrible
		if (id == 0 || id > 7) {
			id = 3;
		}

		// finally, assign the id and model to our id.
		setmodel(new_powerup, getPowerupModel(id));
		new_powerup.zombie_drop_id = id;
		new_powerup.powerup_vo = getPowerupVO(id);
	}
	
	last_pu = new_powerup.zombie_drop_id;
	new_powerup.touch = powerup_touch;
	
	new_powerup.think = powerup_flash;
	new_powerup.nextthink = time + 21;
	totalpowerups = 1;
}
