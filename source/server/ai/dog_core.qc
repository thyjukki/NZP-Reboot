void() Dog_Think;
void() Dog_Death;

// DOG RUN
// 0-6
$frame dogrun1 dogrun2 dogrun3 dogrun4 dogrun5 dogrun6 dogrun7
void()	dog_runanim		=[	$dogrun1,	dog_runanim2	] {Dog_Think();Zombie_Walk(25);self.frame = 0;};
void()	dog_runanim2	=[	$dogrun2,	dog_runanim3	] {Dog_Think();Zombie_Walk(15);self.frame = 1;};
void()	dog_runanim3	=[	$dogrun3,	dog_runanim4	] {Dog_Think();Zombie_Walk(15);self.frame = 2;};
void()	dog_runanim4	=[	$dogrun4,	dog_runanim5	] {Dog_Think();Zombie_Walk(15);self.frame = 3;};
void()	dog_runanim5	=[	$dogrun5,	dog_runanim6	] {Dog_Think();Zombie_Walk(15);self.frame = 4;};
void()	dog_runanim6	=[	$dogrun6,	dog_runanim7	] {Dog_Think();Zombie_Walk(15);self.frame = 5;};
void()	dog_runanim7	=[	$dogrun7, 	dog_runanim 	] {Dog_Think();Zombie_Walk(15);self.frame = 6;};

// DOG WALK
// 7-18
$frame dogwalk1 dogwalk2 dogwalk3 dogwalk4 dogwalk5 dogwalk6 dogwalk7 dogwalk8 dogwalk9 dogwalk10 dogwalk11 dogwalk12
void()	dog_walkanim	=[	$dogwalk1,		dog_walkanim2	] {Dog_Think();Zombie_Walk(8);self.frame = 7;};
void()	dog_walkanim2	=[	$dogwalk2,		dog_walkanim3	] {Dog_Think();Zombie_Walk(8);self.frame = 8;};
void()	dog_walkanim3	=[	$dogwalk3,		dog_walkanim4	] {Dog_Think();Zombie_Walk(8);self.frame = 9;};
void()	dog_walkanim4	=[	$dogwalk4,		dog_walkanim5	] {Dog_Think();Zombie_Walk(8);self.frame = 10;};
void()	dog_walkanim5	=[	$dogwalk5,		dog_walkanim6	] {Dog_Think();Zombie_Walk(8);self.frame = 11;};
void()	dog_walkanim6	=[	$dogwalk6,		dog_walkanim7	] {Dog_Think();Zombie_Walk(8);self.frame = 12;};
void()	dog_walkanim7	=[	$dogwalk7,		dog_walkanim8	] {Dog_Think();Zombie_Walk(8);self.frame = 13;};
void()	dog_walkanim8	=[	$dogwalk8,		dog_walkanim9	] {Dog_Think();Zombie_Walk(8);self.frame = 14;};
void()	dog_walkanim9	=[	$dogwalk9,		dog_walkanim10	] {Dog_Think();Zombie_Walk(8);self.frame = 15;};
void()	dog_walkanim10	=[	$dogwalk10,	dog_walkanim11	] {Dog_Think();Zombie_Walk(8);self.frame = 16;};
void()	dog_walkanim11 	=[	$dogwalk11,	dog_walkanim12	] {Dog_Think();Zombie_Walk(8);self.frame = 17;};
void()	dog_walkanim12	=[	$dogwalk12,	dog_walkanim	] {Dog_Think();Zombie_Walk(8);self.frame = 18;};

// DOG IDLE
// 19-24
$frame dogstand1 dogstand2 dogstand3 dogstand4 dogstand5 dogstand6
void()	dog_idleanim	=[	$dogstand1,	dog_idleanim2	] {self.frame = 19;};
void()	dog_idleanim2	=[	$dogstand2,	dog_idleanim3	] {self.frame = 20;};
void()	dog_idleanim3	=[	$dogstand3,	dog_idleanim4	] {self.frame = 21;};
void()	dog_idleanim4	=[	$dogstand4,	dog_idleanim5	] {self.frame = 22;};
void()	dog_idleanim5	=[	$dogstand5,	dog_idleanim6	] {self.frame = 23;};
void()	dog_idleanim6	=[	$dogstand6,	dog_idleanim	] {self.frame = 24;};

// DOG MELEE
// 25-34
$frame dogmelee1 dogmelee2 dogmelee3 dogmelee4 dogmelee5 dogmelee6 dogmelee7 dogmelee8 dogmelee9 dogmelee10
void()	dog_meleeanim	=[	$dogmelee1, 	dog_meleeanim2	] {Zombie_Walk(0);self.frame = 25;};
void()	dog_meleeanim2	=[	$dogmelee2, 	dog_meleeanim3	] {Zombie_Walk(0);self.frame = 26;};
void()	dog_meleeanim3	=[	$dogmelee3, 	dog_meleeanim4	] {Zombie_Walk(0);self.frame = 27;};
void()	dog_meleeanim4	=[	$dogmelee4, 	dog_meleeanim5	] {Zombie_Walk(0);self.frame = 28;};
void()	dog_meleeanim5	=[	$dogmelee5, 	dog_meleeanim6	] {Zombie_Walk(0);self.frame = 29;};
void()	dog_meleeanim6	=[	$dogmelee6, 	dog_meleeanim7	] {Zombie_Walk(0);zombie_attack2();self.frame = 30;};
void()	dog_meleeanim7	=[	$dogmelee7, 	dog_meleeanim8	] {Zombie_Walk(0);self.frame = 31;};
void()	dog_meleeanim8	=[	$dogmelee8, 	dog_meleeanim9	] {Zombie_Walk(0);self.frame = 32;};
void()	dog_meleeanim9	=[	$dogmelee9, 	dog_meleeanim10	] {Zombie_Walk(0);self.frame = 33;};
void()	dog_meleeanim10	=[	$dogmelee10, 	dog_runanim 	] {Zombie_Walk(0);self.frame = 34;};

// DOG DEATH
// 35 - 36
$frame dogdeath1 dogdeath2
void()	dog_deathanim		=[	$dogdeath1,		dog_deathanim2	] 	{self.frame = 35;};
void()	dog_deathanim2		=[	$dogdeath2,		SUB_Null 		] 	{self.nextthink = time + 3; self.think = removeZombie;  self.frame = 36;};

// DOG WAFFE DEATH
// 37-46
$frame dogwunder1 dogwunder2 dogwunder3 dogwunder4 dogwunder5 dogwunder6 dogwunder7 dogwunder8 dogwunder9 dogwunder10 
void() die_dog_wunder1 	=[ $dogwunder1, 	die_dog_wunder2 	] {Zombie_Walk(0);Zombie_Tesla_Light();self.frame = 37;};
void() die_dog_wunder2 	=[ $dogwunder2, 	die_dog_wunder3 	] {Zombie_Walk(0);self.frame = 38;};
void() die_dog_wunder3 	=[ $dogwunder3, 	die_dog_wunder4 	] {Zombie_Walk(0);self.frame = 39;};
void() die_dog_wunder4 	=[ $dogwunder4, 	die_dog_wunder5 	] {Zombie_Walk(0);self.frame = 40;};
void() die_dog_wunder5 	=[ $dogwunder5, 	die_dog_wunder6 	] {Zombie_Walk(0);self.frame = 41;};
void() die_dog_wunder6 	=[ $dogwunder6, 	die_dog_wunder7 	] {Zombie_Walk(0);Zombie_Find_Tesla_Target();self.frame = 42;};
void() die_dog_wunder7 	=[ $dogwunder7, 	die_dog_wunder8 	] {Zombie_Walk(0);self.frame = 43;};
void() die_dog_wunder8 	=[ $dogwunder8, 	die_dog_wunder9 	] {Zombie_Walk(0);self.frame = 44;};
void() die_dog_wunder9 	=[ $dogwunder9, 	die_dog_wunder10 	] {Zombie_Walk(0);self.frame = 45;};
void() die_dog_wunder10 =[ $dogwunder10, 	die_dog_wunder10 	] {Zombie_Walk(0);self.frame = 46;self.health = 0; self.th_die();};

// DOG LIGHTNING SPAWN
// 1-13
$frame dls1 dls2 dls3 dls4 dls5 dls6 dls7 dls8 dls9 dls10 dls11 dls12 dls13
void() 	dog_lightninganim     =[  $dls1, 			dog_lightninganim2 	] {self.frame = 1;};
void() 	dog_lightninganim2    =[  $dls2, 			dog_lightninganim3 	] {self.frame = 2;};
void() 	dog_lightninganim3    =[  $dls3, 			dog_lightninganim4 	] {self.frame = 3;};
void() 	dog_lightninganim4    =[  $dls4, 			dog_lightninganim5 	] {self.frame = 4;};
void() 	dog_lightninganim5    =[  $dls5, 			dog_lightninganim6 	] {self.frame = 5;};
void() 	dog_lightninganim6    =[  $dls6, 			dog_lightninganim7 	] {self.frame = 6;};
void() 	dog_lightninganim7    =[  $dls7, 			dog_lightninganim8 	] {self.frame = 7;};
void() 	dog_lightninganim8    =[  $dls8, 			dog_lightninganim9 	] {self.frame = 8;};
void() 	dog_lightninganim9    =[  $dls9, 			dog_lightninganim10 ] {self.frame = 9;};
void() 	dog_lightninganim10   =[  $dls10, 			dog_lightninganim11 ] {self.frame = 10;};
void() 	dog_lightninganim11   =[  $dls11, 			dog_lightninganim12 ] {self.frame = 11;};
void() 	dog_lightninganim12   =[  $dls12, 			dog_lightninganim13 ] {self.frame = 12;};
void() 	dog_lightninganim13   =[  $dls13, 			SUB_Null		 	] {self.frame = 13; remove(self);};

// DOG EXPLODE SPRITE
// 1-5
$frame des1 des2 des3 des4 des5 des6
void() dog_explodeanim 		=[ 	$des1, 				dog_explodeanim2	] {self.frame = 1;};
void() dog_explodeanim2 	=[ 	$des2, 				dog_explodeanim3	] {self.frame = 2;};
void() dog_explodeanim3 	=[ 	$des3, 				dog_explodeanim4	] {self.frame = 3;};
void() dog_explodeanim4 	=[ 	$des4, 				dog_explodeanim5	] {self.frame = 4;};
void() dog_explodeanim5 	=[ 	$des5, 				dog_explodeanim6 	] {self.frame = 5;};
void() dog_explodeanim6 	=[ 	$des5, 				SUB_Null 		 	] {remove(self);};

void() Dog_Walk_Setup = 
{	
	if (self.walktype == 1)
		dog_walkanim();
	else
		dog_runanim();
};

// decide our walktype based on player distance
void() Dog_Think =
{
	// FIXME - crash
	self.walktype = 2;
	/*
	if(vlen(self.enemy.origin - self.origin) < 300)
		self.walktype = 2;
	else
		self.walktype = 1;*/
}

float dogCount;
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
	dogCount -= 1;
	
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
	
	float r = random();

	// explode chance
	if (r < 0.75) {
		self.frame = 0;
		setmodel (self, "models/misc/explosion.spr");
		sound (self, CHAN_WEAPON, "sounds/weapons/grenade/explode.wav", 1, ATTN_NORM);
		dog_explodeanim();
	} else {
		dog_deathanim();
	}
	
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
	
	sdog.solid = SOLID_CORPSE;
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
	sdog.th_walk = Dog_Walk_Setup;
	sdog.outside = FALSE;
	
	sdog.th_melee = dog_meleeanim;
	sdog.th_idle = dog_idleanim;
	sdog.th_diewunder = die_dog_wunder1;

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

void() dogsprite_think =
{
	self.frame++;

	if (self.frame >= 3)
		self.frame = 0;
	
	// suicide timer!
	if(self.ltime < time) {
		spawn_a_dogB(self.owner);
		remove(self);
	}

	self.nextthink = time + 0.05;
}

void(entity where) spawn_dog_lightning =
{
	local entity tempe;
	local entity doglight;
	local entity dogsprite;

	// lightning model
	doglight = spawn();
	setmodel(doglight, "models/ai/dog_lightning.mdl");
	setorigin(doglight, where.origin - '0 0 20');
	tempe = self;
	self = doglight;
	dog_lightninganim();
	self = tempe;

	// lightning sprite
	dogsprite = spawn();
	setmodel(dogsprite, "models/misc/lightning.spr");
	setorigin(dogsprite, where.origin);
	dogsprite.owner = where;
	dogsprite.think = dogsprite_think;
	dogsprite.nextthink = time + 0.05;
	dogsprite.ltime = time + 1.3; // we use ltime here to be out remove timer,
								  // since using frames interrupts think()
}

float() spawn_a_dogA =
{
	local float pcount;
	local entity thing, szombie;
	local float FAIL;
	
	FAIL = false;
	pcount = 0;
	szombie = getFreeZombieEnt(self);
	if(szombie == world || dogCount >= (2 * (player_count + 1)))
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
			//spawn_a_dogB(lastspawn);
			spawn_dog_lightning(lastspawn);
			dogCount++;
			spawn_delay = time + 2;
			return true;
		}
		lastspawn = find(lastspawn, classname, "spawn_dog");
	}
	return 0; //no free locations fround
};

void() spawn_dog =
{
	precache_model("models/ai/dog.mdl");
	precache_model("models/ai/dog_lightning.mdl");
	precache_model("models/misc/lightning.spr");
	precache_model("models/misc/explosion.spr");

	precache_sound("sounds/rounds/droundend.wav");
	precache_sound("sounds/rounds/droundstart.wav");
	
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