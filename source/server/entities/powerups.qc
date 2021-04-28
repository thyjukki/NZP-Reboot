.float zombie_drop_id;
.float flashtime;
.float flash_step;

// the powerup's model
string(float type) getPowerupModel = 
{
	switch(type) {
		case 1: return "progs/Misc/maxammo!.mdl"; break;
		case 2: return "progs/Misc/x2!.mdl"; break;
		case 3: return "progs/Misc/instakill!.mdl"; break;
		case 4: return "progs/Misc/nuke!.mdl"; break;
		case 5: return "progs/Misc/carpenter!.mdl"; break;
		case 6: return "progs/Misc/perkbottle!.mdl"; break;
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
		#ifdef PSP
		nzp_maxammo();
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

	#ifndef NX
	if (killcount == 1) {
		GiveAchievement(4);
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
		addmoney(who, 200, 1);
		
		who = find(who,classname,"player");
	}
	total_windows_down = 0;
}

void(entity who) give_perkdrop_logic =
{
	// Return here if we already have all of the Perks
	if ((who.perks & P_REVIVE) && (who.perks & P_JUG) && (who.perks & P_SPEED) && (who.perks & P_DOUBLE) && 
		(who.perks & P_FLOP) && (who.perks & P_STAMIN) && (who.perks & P_DEAD) && (who.perks & P_MULE)) {
		return;
	}

	local float perk;
	perk = 0;

	while(perk == 0) {
		local float num;
		num = rint((random() * 7)) + 1;

		switch(num) {
			case 1:
				if (!(who.perks & P_JUG)) {
					perk = 1;
				}
				break;
			case 2:
				if (!(who.perks & P_DOUBLE)) {
					perk = 2;
				}
				break;
			case 3:
				if (!(who.perks & P_SPEED)) {
					perk = 4;
				}
				break;
			case 4:
				if (!(who.perks & P_REVIVE)) {
					perk = 8;
				}
				break;
			case 5:
				if (!(who.perks & P_FLOP)) {
					perk = 16;
				}
				break;
			case 6:
				if (!(who.perks & P_STAMIN)) {
					perk = 32;
				}
				break;
			case 7:
				if (!(who.perks & P_DEAD)) {
					perk = 64;
				}
				break;
			case 8:
				if (!(who.perks & P_MULE)) {
					perk = 128;
				}
				break;
			default: break;
		}

		who.perks = who.perks | perk;
	}
	SetPerk(who, who.perks);
}

void() give_perk =
{
	// Individual Power-Up
	if (self.style == 1) {
		give_perkdrop_logic(other);
	}
	// OUR Power-Up
	else {
		local entity who;
		who = find(world, classname, "player");

		while(who) {
			give_perkdrop_logic(who);
			who = find(who, classname, "player");
		}
	}
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
	
	if(self.model == "") {
		setmodel(self, getPowerupModel(self.zombie_drop_id));
	} else {
		setmodel(self,"");
	}
};

void() powerup_play_sound =
{
	// play the VO clip if its not the perk bottle
	if (self.zombie_drop_id != 6)
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

		// add a slight delay before VO play
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

//
// GetPowerupID()
// Returns a powerup id, checks if the game allows for
// one and if requirements for said powerup are met.
//
float() GetPowerupID =
{
	float found;
	float carpenter_able;
	float perk_able;
	float id;

	id = carpenter_able = perk_able = 0;

	// Check if we can get a carpenter or a free perk drop
	if (total_windows_down >= 5)
		carpenter_able = true;
	if (rounds >= 15)
		perk_able = true;

	float total_powerups = 5; // nuke, insta, 2x, maxammo, carpenter, free perk

	// Start ID loop
	found = false;
	while(found == false) {
		float t = random();

		// loop through all IDs
		for (float i = 0; i < total_powerups + 1; i++) {
			// check if the ID we got was viable
			if (t > (i/total_powerups)) {
				switch(i) {
					case 1:
						found = true;
						id = i;
						break;
					case 2:
						found = true;
						id = i;
						break;
					case 3:
						found = true;
						id = i;
						break;
					case 4:
						found = true;
						id = i;
						break;
					case 5:
						if (carpenter_able) {
							found = true;
							id = i;
						}
						break;
					case 6:
						/*if (perk_able) {
							found = true;
							id = i;
						}*/
						break;
					default:
						break;
				}
			}
		}
	}

	return id;
}

float last_pu;
void(vector where, float type) Spawn_Powerup =
{
	entity new_powerup;
	float id;

	new_powerup = spawn();
	new_powerup.origin = where;
	setorigin(new_powerup, new_powerup.origin);
	new_powerup.solid = SOLID_TRIGGER;
	new_powerup.classname = "item_powerup";

	
	setsize (new_powerup, VEC_HULL_MIN, VEC_HULL_MAX);
	new_powerup.movetype = MOVETYPE_NONE;
    Light_Green(new_powerup);
	
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

	// Specific Power-Ups (for dogs)
	if (type) {
		setmodel(new_powerup, getPowerupModel(type));
		new_powerup.zombie_drop_id = type;
		new_powerup.powerup_vo = getPowerupVO(type);
	} else {
		// Grab a powerup ID
		id = GetPowerupID();

		// Should perk drops be individual?
		if (id == 6) {
			// Yes!
			if (random() > (1/2)) {
				// Set Style and make light Blue to symbolize it is an individual drop
				// TODO: Make a sprite too??
				new_powerup.style = 1;
				Light_None(new_powerup);
				Light_Blue(new_powerup);
			}
			// No!
			else {
				// failsafe
				new_powerup.style = 0;
			}
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
	totalpowerups++;
}