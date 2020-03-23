// 37 - 47
$frame dogdeath1 dogdeath2 dogdeath3 dogdeath4 dogdeath5 dogdeath6 dogdeath7 dogdeath8
void()	dog_deathanim		=[	$dogdeath1,		dog_deathanim2	] 	{self.frame = 37;};
void()	dog_deathanim2		=[	$dogdeath2,		dog_deathanim3	] 	{self.frame = 38;};
void()	dog_deathanim3		=[	$dogdeath3,		dog_deathanim4	] 	{self.frame = 39;};
void()	dog_deathanim4		=[	$dogdeath4,		dog_deathanim5	] 	{self.frame = 41;};
void()	dog_deathanim5		=[	$dogdeath5,		dog_deathanim6	] 	{self.frame = 44;};
void()	dog_deathanim6		=[	$dogdeath6,		dog_deathanim7	] 	{self.frame = 45;};
void()	dog_deathanim7		=[	$dogdeath7,		dog_deathanim8	] 	{self.frame = 46;};
void()	dog_deathanim8		=[	$dogdeath8,		SUB_Null	] 	{self.nextthink = time + 3; self.think = removeZombie;  self.frame = 36;};


void() Dog_Walk_Setup = 
{	
	if(self.walktype == 1)
	{
		zombie_walk1();
	}
	
	else if(self.walktype == 2)
	{
		zombie_walkb1();
	}
	
	else if(self.walktype == 3)
	{
		zombie_walkc1();
	}
	
	else if(self.walktype == 4)
	{
		zombie_jog1();
	}
	else if(self.walktype == 5)
	{
		zombie_run1();
	}
};
void() Dog_Death =
{
	self.aistatus = "0";
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.takedamage = DAMAGE_NO;
	
	sound(self,CHAN_WEAPON,"sounds/null.wav",1,ATTN_NORM);
	
	self.usedent = world;
	
	self.health = 0;
	Remaining_Zombies = Remaining_Zombies - 1;
	
	play_sound_z(3);
	//Gotta' make sure we set it back down instead of glitching it up, yo'
	if(self.s_time > 0 && sounds_playing > 0)
	{
		sounds_playing --;
		self.s_time = 0;
	}
	
	if (rounds == dogRound)
	{
		if (!Remaining_Zombies)
			Spawn_Powerup(self.origin + '0 0 12', 1);
	}
	
	dog_deathanim();		// FIXME real animation
};

void(entity where) spawn_a_dogB =
{
	local entity sdog;//USED FOR WHAT TO SPAWN
	
	sdog = getFreeZombieEnt(self);
	if(sdog == world)
	{
		return;
	}

	sdog.origin = where.origin;
	sdog.frame = 0;
	
	sdog.target = where.target;	
	
	sdog.solid = SOLID_SLIDEBOX;
	sdog.movetype = MOVETYPE_WALK;
	setmodel(sdog, "models/ai/dog.mdl");
	sdog.hop_step = 0;
	sdog.gravity = 1.0;
	
	sdog.mins = '-8 -8 -32';//-16 16 -32
	sdog.maxs = '8 8 30';//16 16 40
	setsize (sdog, sdog.mins, sdog.maxs);
		
	if(pointcontents(sdog.origin - '0 0 36') == -2)
	{
		while(pointcontents (sdog.origin - '0 0 36') == -2)
		{
			sdog.origin = sdog.origin + '0 0 1';
			setorigin(sdog,sdog.origin );
		}
	}

	sdog.classname = "ai_dog";
	sdog.aistatus = "1";
	setorigin (sdog.goaldummy, '0 0 0');
	sdog.origin_z = sdog.origin_z + 1;
	sdog.takedamage = DAMAGE_YES;
	setorigin(sdog, sdog.origin);
	sdog.flags = sdog.flags | FL_PARTIALGROUND | FL_MONSTER;

	sdog.spawnflags = where.spawnflags;
	sdog.spawnflags = sdog.spawnflags | 1;
	
	sdog.ideal_yaw = sdog.angles_y;
	sdog.yaw_speed = 20;
	sdog.health = z_health;
	sdog.th_die = Dog_Death;
	sdog.th_walk = Zombie_Walk_Setup;	// Naievil FIXME
	sdog.outside = FALSE;
	
	sdog.th_melee = zombie_attack;
	sdog.th_idle = zombie_idle;
	sdog.th_windowhop = zombie_hop1;
	
	sdog.th_fall = zombie_fall1;
	sdog.th_land = zombie_land1;
	
	SetZombieWalk(sdog);
	sdog.walktype = 5;
	
	sdog.reload_delay = 30 + time;//save  floats, equals respawn time.
	local entity old_self;
	old_self = self;
	self = sdog;
	//droptofloor();
	self.th_walk();
	self = old_self;
};

float() spawn_a_dogA =
{
	local float pcount;
	local entity thing, szombie;
	local float FAIL;
	
	FAIL = false;
	pcount = 0;
	szombie = getFreeZombieEnt(self);
	if(szombie == world)
	{
		return 0;
	}
	lastspawn = find(lastspawn, classname, "spawn_dog");
	while (random() < 0.4)
	{
		lastspawn = find(lastspawn, classname, "spawn_dog");
	}
	
	while(lastspawn)
	{
		thing = findradius(lastspawn.origin, 60);
		while (thing)
		{
			pcount = 0;
			if (thing.classname == "ai_dog")
			{
				pcount = 1;
				break;
			}
			thing = thing.chain;
		}
		if (!pcount && random() < 0.6)
		{
			spawn_a_dogB(lastspawn);
			spawn_delay = time + delay_at_round;
			return true;
		}
		lastspawn = find(lastspawn, classname, "spawn_dog");
	}
	return 0; //no free locations fround
};

void() spawn_dog =
{
	setsize(self, '0 0 0', '0 0 0');
	if (self.spawnflags & INACTIVE)
	{
		if (cvar("developer"))
			setmodel(self, "models/player.mdl");
		self.classname = "spawn_dog_in";
	}
	else
	{
		if (cvar("developer"))
			setmodel(self, "models/ai/dog.mdl");
		self.classname = "spawn_dog";
	}
	
	self.solid = SOLID_NOT;
};