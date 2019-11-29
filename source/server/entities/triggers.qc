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
	string temps;
	
	precache_model ("models/misc/chalk.mdl");
	//temps = GetWeaponModel(self.sequence + 1, 1);
	//precache_model (temps);

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