//
// triggers.qc - Misc. Trigger functions
//
#define SPAWNFLAG_NOMESSAGE 	1
#define SPAWNFLAG_NOTOUCH 		1

// the wait time has passed, so set back up for another activation
void() multi_wait =
{
	if (self.max_health)
	{
		self.health = self.max_health;
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
	}
};


// the trigger was just touched/killed/used
// self.enemy should be set to the activator so it can be held through a delay
// so wait for the delay time before firing
void() multi_trigger =
{
	if (self.nextthink > time)
	{
		return;		// already been triggered
	}

	if (self.noise)
		sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);

// don't trigger again until reset
	self.takedamage = DAMAGE_NO;

	activator = self.enemy;

	SUB_UseTargets();

	if (self.wait > 0)	
	{
		self.think = multi_wait;
		self.nextthink = time + self.wait;
	}
	else
	{	
		// we can't just remove(self) here, because this is a touch function
		// called while C code is looping through area links...
		self.touch = SUB_Null;
		self.nextthink = time + 0.1;
		self.think = SUB_Remove;
	}
};

void() multi_killed =
{
	// motolegacy - FIXME
	//self.enemy = damage_attacker;
	multi_trigger();
};

void() multi_use =
{
	self.enemy = activator;
	multi_trigger();
};

void() multi_touch =
{
	if (other.classname != "player")
		return;

	// if the trigger has an angles field, check player's facing direction
	if (self.movedir != '0 0 0')
	{
		makevectors (other.angles);
		if (v_forward * self.movedir < 0)
			return;		// not facing the right way
	}
	
	self.enemy = other;
	multi_trigger();
};

void() SetMovedir =
{
	if (self.angles == '0 -1 0')
		self.movedir = '0 0 1';
	else if (self.angles == '0 -2 0')
		self.movedir = '0 0 -1';
	else
	{
		makevectors (self.angles);
		self.movedir = v_forward;
	}
	
	self.angles = '0 0 0';
};

void() InitTrigger =
{
// trigger angles are used for one-way touches.  An angle of 0 is assumed
// to mean no restrictions, so use a yaw of 360 instead.
	if (self.angles != '0 0 0')
		SetMovedir ();
	self.solid = SOLID_TRIGGER;
	setmodel (self, self.model);	// set size and link into world
	self.movetype = MOVETYPE_NONE;
	self.modelindex = 0;
	self.model = "";
};

#ifndef PSP
entity last_act_trigger;
void() trigger_activator_touch =
{
	other.cost = other.cost +1; //hack, we can only touch one of thease at the time
	if (other.classname != "player" || last_act_trigger == self || other.cost > 1)
		return;
	last_act_trigger = self;

	entity t;
	float tempcount, temptotal,breakthis;
	string tempstring;
	temptotal = 0;
	breakthis = 0;
	tempcount = 1;
	tempstring = "";
	t = world;
	do
	{
		t = find (t, classname, "spawn_zombie");
		if (!t)
		{
			breakthis = 1;
		}
		if (t.classname == "spawn_zombie")
		{
			t.classname = "spawn_zombie_away";
			/*if (cvar("developer"))
				setmodel(t, "progs/player.mdl");*/
		}
	} while (!breakthis);
	
	if (self.target2)
		tempcount =+ 1;
	if (self.target3)
		tempcount =+ 1;
	if (self.target4)
		tempcount =+ 1;
	if (self.target5)
		tempcount =+ 1;
	if (self.target6)
		tempcount =+ 1;
	if (self.target7)
		tempcount =+ 1;
	if (self.target8)
		tempcount =+ 1;
	if (self.target2)
		tempcount = tempcount + 1;
	if (self.target3)
		tempcount = tempcount + 1;
	if (self.target4)
		tempcount = tempcount + 1;
	if (self.target5)
		tempcount = tempcount + 1;
	if (self.target6)
		tempcount = tempcount + 1;
	if (self.target7)
		tempcount = tempcount + 1;
	if (self.target8)
		tempcount = tempcount + 1;

	while(tempcount > temptotal)
	{
		temptotal = temptotal + 1;
		if (temptotal == 1)
			tempstring = self.target;
		if (temptotal == 2)
			tempstring = self.target2;
		if (temptotal == 3)
			tempstring = self.target3;
		if (temptotal == 4)
			tempstring = self.target4;
		if (temptotal == 5)
			tempstring = self.target5;
		if (temptotal == 6)
			tempstring = self.target6;
		if (temptotal == 7)
			tempstring = self.target7;
		if (temptotal == 8)
			tempstring = self.target8;
		if (tempstring)
		{
			t = find (world, targetname, tempstring);
			breakthis = 0;
			while (!breakthis)
			{
				if (!t)
				{
					breakthis = true;
				}
				if (t.classname == "spawn_zombie_away")
				{
					t.classname = "spawn_zombie";
					/*if (cvar("developer"))
						setmodel(t, "progs/ai/zfull.mdl");*/
				}
				t = find (t, targetname, tempstring);
			} 
		}
	}
}

void() trigger_activator =
{
	InitTrigger ();
	self.touch = trigger_activator_touch;
}
#endif

void() use_wall_weapon =
{
	if (self.enemy)
		return;
	entity newent;
	
	newent = spawn();

	newent.movetype = MOVETYPE_NONE;	// so it doesn't get pushed by anything
	newent.solid=SOLID_NOT;
	newent.classname = "wall_weapon";
	setorigin(newent, self.origin);
	setmodel (newent, GetWeaponModel(self.sequence + 1, 1));
	setsize (newent, VEC_HULL2_MIN, VEC_HULL2_MAX);
	newent.angles = self.angles;
	
	self.enemy = newent;
}

void() weapon_wall =
{	
	precache_model ("models/misc/chalk.mdl");

	setmodel (self, "models/misc/chalk.mdl");
	self.skin = 0;
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);

	self.frame = self.sequence;
	self.use = use_wall_weapon;
	self.classname = "weapon_wall";
	//self.effects = EF_WEPLIGHT;
}

/* ===================
   Custom Teddy Triggers
   ===================*/

void() teddy_react =
{
  	local entity t;
	if (self.spawnflags & 1) {
		t = find (world, teddyremovetarget, self.target);
    
		if (t)
			remove(t); 
	}

	remove(self); //this was present in the patch, i like it.
}

/*
	Variable sized repeatable trigger.  Must be targeted at one or more entities.  If "health" is set, the trigger must be killed to activate each time.
	If "delay" is set, the trigger waits some time after activating before firing.
	"wait" : Seconds between triggerings. (.2 default)
	If notouch is set, the trigger is only fired by other entities, not by touching.
	NOTOUCH has been obsoleted by trigger_relay!
	set "message" to text string
*/
void() trigger_multiple =
{	
	if (!self.wait)
		self.wait = 0.2;

	self.use = multi_use;

	InitTrigger ();

	if(self.health)
	{
		if (self.spawnflags & SPAWNFLAG_NOTOUCH)
			objerror("health and notouch don't make sense\n");
		self.max_health = self.health;
		self.th_die = multi_killed;
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
		setorigin(self, self.origin);	// make sure it links into the world
	}
	else
	{
		if (!(self.spawnflags & SPAWNFLAG_NOTOUCH))
		{
			self.touch = multi_touch;
		}
	}
};

/*
	Variable sized trigger. Triggers once, then removes itself.  You must set the key "target" to the name of another object in the level that has a matching
	"targetname".  If "health" is set, the trigger must be killed to activate.
	If notouch is set, the trigger is only fired by other entities, not by touching.
	if "killtarget" is set, any objects that have a matching "target" will be removed when the trigger is fired.
	if "angle" is set, the trigger will only fire when someone is facing the direction of the angle.  Use "360" for an angle of 0.
	set "message" to text string
*/
void() trigger_once =
{
	self.wait = -1;

	trigger_multiple();
}