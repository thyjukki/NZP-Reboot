//
// damage.qc -- used for any sort of down, hit, etc that the player or entity experiences
//
#ifndef NX
void (float achievement_id, optional entity who) GiveAchievement;
#endif // NX

void() EndGame_Restart = 
{
	localcmd("restart");
}

// Fade to black function, creates another think for restart
void() EndGame_FadePrompt =
{
	PromptLevelChange(time + 6, 2, self);
	#ifdef PC
	self.think = EndGame_Restart;
	#else
	self.think = Soft_Restart;
	#endif
	self.nextthink = time + 5;
}

//Actual endgame function, all zombies die, music plays
void() EndGame =
{
	local entity oldself;
	local entity who;

	self.health = 0;
	self.origin = '0 0 0';
	setorigin (self, self.origin);
	self.velocity = '0 0 0';
	sound (self, CHAN_AUTO, "sounds/music/end.wav", 1, ATTN_NORM);

	oldself = self;
	
	who = find(world,classname,"ai_zombie");
	while(who != world)
	{
		if(who.health)
		{
			self = who;
			self.th_die();
			self = oldself;
		}
		
		who = find(who,classname,"ai_zombie");
	}
	
	self.think = EndGame_FadePrompt;
	self.nextthink = time + 33;
}

// removes revive icon from downed player heads, used as a recursive think function
void() remove_revive =
{
	if (self.owner.beingrevived)
		setmodel (self, "progs/Sprites/revive_white.spr");
	else
		setmodel (self, "progs/Sprites/revive.spr");

	if (!self.owner.downed || self.owner.isspec)
		SUB_Remove ();
	else {
		self.think = remove_revive;
		self.nextthink = time + 0.1;
	}
}

// when dead and other players exist and are alive, throw user into spectate mode
void() startspectate =
{
	if (!self.downed)
		return;
		
	if (self.beingrevived)
	{
		self.think = startspectate;
		self.nextthink = time + 0.1;
		return;
	}
	
	self.downedloop = 0;
	self.beingrevived = false;
	self.model = "";
	setmodel(self, self.model);
	self.health = 100;
	self.weaponmodel = "";
	self.weapon2model = "";
	self.downed = 0;
	self.frame = 0;

	UpdateVmodel(self.weaponmodel, GetWepSkin(self.weapon));
	UpdateV2model(self.weapon2model, GetWepSkin(self.weapon));
	
	SpectatorSpawn();
}

// searches for players that are alive given which clients have which playernumbers
//      Returns 1 if there IS someone in the world that's not downed
float() PollPlayersAlive = 
{
	float i, gotalive;
	entity playerent;
	
	gotalive = 0;
	
	for (i = 1; i <= 4; i++)
	{
		playerent = findfloat(world, playernum, i);
		
		if (playerent) {
			if (!playerent.downed && !playerent.isspec) {
				gotalive = 1;
				break;
			}
		}
	}
	
	return gotalive;
}

// Endgamesetup -- think function for setting up the death of everyone
void() EndGameSetup =
{
	game_over = true;
	self.health = 10;
	self.think = EndGame;
	self.nextthink = time + 5;
	self.weapon = 0;
	self.currentammo = 0;
	self.currentmag = 0;
	self.weaponmodel = "";
	self.weapon2model = "";
	self.animend = SUB_Null;
	self.perks = 0;
	self.isspec = true;
	SetPerk(self, self.perks);
	SwitchWeapon(0);	
	addmoney(self, -self.points, 0);
	addmoney(self, self.score, 0);	
    return;
}

// rec_downed is used as a recursive loop where we consistently check to see if ALL players are downed
//    if they aren't dead, we keep looping until our OWN death (45 seconds, so 450 loops)
void() rec_downed = 
{
	self.downedloop++;
	if (self.downedloop == 450) {
		startspectate();
		return;
	}
	
	float gotalive = PollPlayersAlive();
	
	if (!gotalive && !self.progress_bar) {
		EndGameSetup();
		return;
	}
	
	self.think = rec_downed;
	self.nextthink = time + 0.1;
}

void() GetDown =
{
	float startframe;
	float endframe;
	local string modelname;

	if (rounds <= 1 && self.currentmag == 0 && self.currentmag2 == 0 && self.currentammo == 0 && self.secondarymag == 0 &&
	self.secondarymag2 == 0 && self.secondaryammo == 0) {
		GiveAchievement(9, self);
	}
	
	playdown();
	
	switch(self.stance) {
		case 2:
			self.new_ofs_z = self.view_ofs_z - 42;
			self.stance = 0;
			break;
		case 1:
			self.new_ofs_z = self.view_ofs_z - 24;
			self.stance = 0;
			break;
		default: break;
	}

	// remove third weapon
	self.thirdweapon = 0;

	self.velocity = '-80 0 -80';           			// Stop any old movement
	self.zoom = 0;
	self.downed = true;
	self.dive_delay = 0;
	self.movetype = MOVETYPE_NONE;
	
	float gotalive = PollPlayersAlive();	
	
	if ((coop && !gotalive) || (!coop && !(self.perks & P_REVIVE))) {
		EndGameSetup();
		return;
	} else {
		self.health = 19; 
	}
	
	if ((self.perks & P_REVIVE) && !coop) {	
		self.progress_bar = 10 + time;     
		self.progress_bar_time = 10;
		self.progress_bar_percent = 1;
		self.downed = true;
	}
	
	self.points = 10*rint((self.points*0.95)/10);
	addmoney(self, 0, true);						// used to call a broadcast
	BroadcastMessage(time + 3, 2);
	
	self.perks = 0;
	self.weaponbk = self.weapon;
	self.currentammobk = self.currentammo;
	self.currentmagbk = self.currentmag;
	self.currentmagbk2 = self.currentmag2;
	
	if (self.weapon == W_BIATCH || self.secondaryweapon == W_BIATCH || self.progress_bar_percent > 0) {
		self.weapon = W_BIATCH;
		self.currentammo = 12;
		self.currentmag = 6;
		self.currentmag2 = 6;
	} else {
		self.weapon = W_COLT;
		self.currentammo = 16;
		self.currentmag = 8;
	}
      
  	modelname = GetWeaponModel(self.weapon, 0);
	self.weaponmodel = modelname;
	SwitchWeapon(self.weapon);
	
	startframe = GetFrame(self.weapon,TAKE_OUT_START);
	endframe = GetFrame(self.weapon,TAKE_OUT_END);
	Set_W_Frame (startframe, endframe, 0, 0, 0, SUB_Null, modelname, false, S_BOTH);
	
	local entity revive;
	
	revive = spawn ();
	revive.owner = self;
	revive.movetype = MOVETYPE_NONE;
	revive.solid = SOLID_NOT;
	revive.think = remove_revive;
	revive.nextthink = time + 0.1;

	setmodel (revive, "progs/Sprites/revive.spr");
	revive.origin = self.origin + VEC_VIEW_OFS;
	setorigin (revive, revive.origin);
	
	SetPerk(self, 0);
	
	self.think = rec_downed;
	self.nextthink = time + 0.1;
}

void () GetUp =
{
	local string modelname;
	float startframe;
	float endframe;
	
	playgetup();				// animation
	
	self.new_ofs_z = self.view_ofs_z + 42;
	self.stance = 2;
	self.health = 100;
	self.downedloop = 0;		// used for death timing vs endgame
	self.downed = 0;
	self.classname = "player";
	if (self.weaponbk)
	{
		self.weapon = self.weaponbk;
		self.currentammo = self.currentammobk;
		self.currentmag = self.currentmagbk;
		self.currentmag2 = self.currentmagbk2;
	}	
	modelname = GetWeaponModel(self.weapon, 0);
	self.weaponmodel = modelname;
	SwitchWeapon(self.weapon);
	self.weapon2model = GetWeapon2Model(self.weapon);
	self.movetype = MOVETYPE_WALK;
  
  	startframe = GetFrame(self.weapon,TAKE_OUT_START);
	endframe = GetFrame(self.weapon,TAKE_OUT_END);
	Set_W_Frame (startframe, endframe, 0, 0, 0, SUB_Null, modelname, false, S_BOTH);
	
};

// poll checking whether to see if our revive invoke is active
void(entity ent) CheckRevive =
{
	if (self.invoke_revive) {
		GetUp();
		self.invoke_revive = 0;
	}
}

void(entity attacker, float d_style) DieHandler =
{
    float t;

    t = random();

    if (self.classname == "ai_zombie" || self.classname == "ai_dog") {
        self.th_die();
    }

    if (attacker.classname == "player") {
		attacker.kills++;
		if (d_style == S_HEADSHOT) {
			addmoney(attacker, 100, true);
			total_powerup_points = total_powerup_points + 100;
			attacker.headshots++;
		} else if (d_style == S_NORMAL) {
            addmoney(attacker, 60, true);
            total_powerup_points = total_powerup_points + 60;
        }
		else if (d_style == S_KNIFE){
			addmoney(attacker, 130, true);
			total_powerup_points = total_powerup_points + 130;
		} else if (d_style == S_TESLA) {
			addmoney(attacker, 50, true);
			total_powerup_points = total_powerup_points + 50;
		}
    }
}

void(entity victim,entity attacker, float damage, float d_style) DamageHandler = {
	// Abstinence Program
	victim.ach_tracker_abst = 1;

	entity old_self;
	if (victim.classname == "ai_zombie" || victim.classname == "ai_dog") {

		if (attacker.classname == "player" && (victim.health - damage)> 0) {
			addmoney(attacker, 10, 1);
        }

		victim.health = victim.health - damage;

		if (d_style == S_EXPLOSIVE) {
			if (victim.health < z_health*0.5)
			{
				if (victim.crawling != TRUE && !(victim.health <= 0) && crawler_num < 5 && victim.classname != "ai_dog")
				{
					makeCrawler(victim);
					#ifndef NX
					GiveAchievement(3, attacker);
					#endif
				}
				else
				{
					if (attacker.classname == "player" && (victim.health - damage) > 0)
						addmoney(attacker, 10, 1);
				}
			}
			// MOTO - explosives seem to work fine without, but with will cause counter and QC errors..
			//else
			//	victim.th_die();	
				
			if (victim.health <= 0)
				addmoney(attacker, 60, 1);
		}

		if (victim.health <= 0 || instakill_finished) {
			old_self = self;
			self = victim;
			DieHandler(attacker, d_style);
			self = old_self;
		}
	} else if (victim.classname == "player" && !victim.downed) {

		if (victim.flags & FL_GODMODE) {
			return;
		}
		
		if (victim.perks & P_JUG)
			damage = ceil(damage*0.5);
		
		victim.health = victim.health - damage;
		victim.health_delay = time + 2;

		// shake the camera on impact
		local vector distance;
		distance = attacker.angles - victim.angles;

		// just to prevent radical punchangles
		while(distance_x > 10 || distance_x < -10) {
			distance_x /= 2;
		}
		while(distance_y > 10 || distance_y < -10) {
			distance_y /= 2;
		}

		// apply
		victim.punchangle_x = distance_x;
		victim.punchangle_y = distance_y;

		// play hurt sound
		sound (self, CHAN_AUTO, "sounds/player/pain4.wav", 1, ATTN_NORM);

		if (victim.health <= 20)
		{
			old_self = self;
			self = victim;
			GetDown();
			self = old_self;
		}
	}
}

/*
============
CanDamage

Returns true if the inflictor can directly damage the target.  Used for
explosions and melee attacks.
============
*/
float(entity targ, entity inflictor) CanDamage =
{
	if (targ.flags == FL_GODMODE)
    return FALSE;
// bmodels need special checking because their origin is 0,0,0
	if (targ.movetype == MOVETYPE_PUSH)
	{
		traceline(inflictor.origin, 0.5 * (targ.absmin + targ.absmax), TRUE, self);
		if (trace_fraction == 1)
			return TRUE;
		if (trace_ent == targ)
			return TRUE;
		return FALSE;
	}
    
	traceline(inflictor.origin, targ.origin, TRUE, self);
	if (trace_fraction == 1)
		return TRUE;
	traceline(inflictor.origin, targ.origin + '15 15 0', TRUE, self);
	if (trace_fraction == 1)
		return TRUE;
	traceline(inflictor.origin, targ.origin + '-15 -15 0', TRUE, self);
	if (trace_fraction == 1)
		return TRUE;
	traceline(inflictor.origin, targ.origin + '-15 15 0', TRUE, self);
	if (trace_fraction == 1)
		return TRUE;
	traceline(inflictor.origin, targ.origin + '15 -15 0', TRUE, self);
	if (trace_fraction == 1)
		return TRUE;

	return FALSE;
};

void(entity inflictor, entity attacker, float damage2, float mindamage, float radius) DamgageExplode =
{
	float 	final_damage;
	entity	ent;

	float 	multi, r;
	ent = findradius(inflictor.origin, radius);
	
	while (ent != world)
	{
		if(ent.classname == "player")
		{
			if (ent.perks & P_FLOP)
				final_damage = 0;
			else
			{
				final_damage = radius - vlen(inflictor.origin - ent.origin);

				if(final_damage < 0)
					continue;
			
				if (final_damage > radius * 0.6)
					final_damage = 100;
			
				if (final_damage < other.health)
				{
					addmoney(self, 10, 0);
				}
				else if (final_damage > other.health)
				{
					addmoney(self, 60, 0);
				}
				else
				{
					final_damage /= radius;
					final_damage *= 60;
				}
				DamageHandler (attacker, attacker, final_damage, S_EXPLOSIVE);
			}
		}
		else if (ent.takedamage && ent.classname != "ai_zombie_head" && ent.classname != "ai_zombie_larm" && ent.classname != "ai_zombie_rarm")
		{			
			// verify we aren't doin anything with a bmodel
			if (ent.solid == SOLID_BSP || ent.movetype == MOVETYPE_PUSH)
				return;

			if (mapname == "ndu" && ent.classname == "ai_zombie" && inflictor.classname == "explosive_barrel") {
				ach_tracker_barr++;

				if (ach_tracker_barr >= 15) {
					GiveAchievement(13);
				}
			}

			r = rounds;
			multi = 1.07;
			while(r > 0)
			{
				multi *= 1.05;
				r --;
			}
			
			if (mindamage == 75)
				final_damage = (200 * multi) + 185;
				else
				final_damage = (mindamage + damage2)/2;
			
			if (final_damage > 0)
			{
				/* ndaekill = true; */
				if (CanDamage (ent, inflictor))
					DamageHandler (ent, attacker, final_damage, S_EXPLOSIVE);
				/* kill = false; */
			}
		}
		ent = ent.chain;
	}
};