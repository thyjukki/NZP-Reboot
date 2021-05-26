string(float wep, float gorvmodel) GetWeaponModel;
void() ReturnWeaponModel;

void() func_wall =
{
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;	// so it doesn't get pushed by anything
	self.solid = SOLID_BSP;
	setmodel (self, self.model);
};

void() func_illusionary =
{
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	setmodel (self, self.model);
	// makestatic (self); // dr_mabuse1981: dont use makestatic, it doesnt show the HL rendermodes then.
};

// button and multiple button

void() button_wait;
void() button_return;

void() button_wait =
{
	self.state = STATE_TOP;
	self.nextthink = self.ltime + self.wait;
	self.think = button_return;
	activator = self.enemy;
	SUB_UseTargets();
	self.frame = 1;			// use alternate textures
};

void() button_done =
{
	self.state = STATE_BOTTOM;
};

void() button_return =
{
	self.state = STATE_DOWN;
	SUB_CalcMove (self.pos1, self.speed, button_done);
	self.frame = 0;			// use normal textures
	if (self.health)
		self.takedamage = DAMAGE_YES;	// can be shot again
};


void() button_blocked =
{	// do nothing, just don't ome all the way back out
};


void() button_fire =
{
	if (self.state == STATE_UP || self.state == STATE_TOP)
		return;

	sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);

	self.state = STATE_UP;
	SUB_CalcMove (self.pos2, self.speed, button_wait);
};


void() button_use =
{
	self.enemy = activator;
	button_fire ();
};

void() button_touch =
{
	if (other.classname != "player")
		return;
	
	if(self.cost)
	{
		if(self.state == STATE_BOTTOM||self.state == STATE_DOWN)
		{
			centerprint(other,"Press use to buy [cost:");
			centerprint(other,ftos(self.cost));
			centerprint(other,"]\n");
			if (other.button7)
			{
				if(other.points >= self.cost)
				{
					self.enemy = other;
					addmoney(other, 0 - self.cost, FALSE);
					button_fire();
					return;
				}
				else
				{
					centerprint(other,"You do not have enough points\n");

				}
			}
		}
	}
	else
	{
	self.enemy = other;
	button_fire ();
	}
};

void() button_killed =
{
	self.health = self.max_health;
	self.takedamage = DAMAGE_NO;	// wil be reset upon return
	button_fire ();
};


/*QUAKED func_button (0 .5 .8) ?
When a button is touched, it moves some distance in the direction of it's angle, triggers all of it's targets, waits some time, then returns to it's original position where it can be triggered again.

"angle"		determines the opening direction
"target"	all entities with a matching targetname will be used
"speed"		override the default 40 speed
"wait"		override the default 1 second wait (-1 = never return)
"lip"		override the default 4 pixel lip remaining at end of move
"health"	if set, the button must be killed instead of touched
"sounds"
0) steam metal
1) wooden clunk
2) metallic click
3) in-out
*/

void() func_button =
{
	SetMovedir ();
	
	self.movetype = MOVETYPE_PUSH;
	self.solid = SOLID_BSP;
	setmodel (self, self.model);

	self.blocked = button_blocked;
	self.use = button_use;
	
	if (self.health)
	{
		self.max_health = self.health;
		self.th_die = button_killed;
		self.takedamage = DAMAGE_YES;
	}
	else
		self.touch = button_touch;

	if (!self.speed)
		self.speed = 40;
	if (!self.wait)
		self.wait = 1;
	if (!self.lip)
		self.lip = 4;

	self.state = STATE_BOTTOM;

	self.pos1 = self.origin;
	self.pos2 = self.pos1 + self.movedir*(fabs(self.movedir*self.size) - self.lip);
};

void() flame_update = {	
	#ifndef PC	
	particle (self.origin, v_up, 111, 0);
	#else
	te_flamejet(self.origin, v_up, 10);
	#endif
	self.think = flame_update;
	self.nextthink = time + random()+0.1;
}
void() place_fire =
{
	#ifndef PC
	particle (self.origin, v_up*8, self.frame, 0);
	#else
	te_flamejet(self.origin, v_up*8, 10);
	#endif
	self.think = flame_update;
	self.nextthink = time + random()+0.1;
};

void() place_model =
{  
	#ifdef PSP
	if (self.spawnflags & 2)
		remove(self);
	#endif

	precache_model (self.model);
	setmodel (self, self.model);
  
	self.skin = 0;
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.angles = self.angles;
	self.solid = SOLID_NOT;
	self.frame = self.sequence;
	
	if (self.spawnflags & 1)
		self.effects = self.effects | EF_FULLBRIGHT;
};




void () buy_weapon_touch =
{
	entity oldent;
	float tempf, tempf1, tempf2, tempf3;
	float startframe,endframe;
	string modelname;

	if (other.classname != "player" || other.downed || other.isBuying/* || !isFacing(other, self)*/) {
		return;
	}
	
	#ifndef PC
	other.Weapon_Name_Touch = GetWeaponName(self.weapon);
	#endif
	
	if (self.weapon == other.weapon || self.weapon == other.secondaryweapon 
	|| self.weapon == EqualNonPapWeapon(other.weapon) 
	|| self.weapon == EqualNonPapWeapon(other.secondaryweapon)) {

		if (self.weapon == EqualNonPapWeapon(other.secondaryweapon) 
		|| self.weapon == EqualNonPapWeapon(other.weapon))
			useprint (other, 3, 4500, other.weapon);
		else
			useprint (other, 3, self.cost2, self.weapon);

		if (!other.button7 || other.semiuse || other.isBuying) {
			return;
		}
		if ((self.weapon == other.weapon && other.currentammo >= getWeaponAmmo(self.weapon))
			||(self.weapon == other.secondaryweapon && other.secondaryammo >= getWeaponAmmo(self.weapon))) {
				return;
			}

		other.semiuse = true;
		if ((other.points < self.cost2 && !IsPapWeapon(other.weapon)) || (other.points < 4500 && IsPapWeapon(other.weapon))) {
			centerprint(other, "You do not have enough points\n");
			return;
		}

		other.ach_tracker_coll++;

		if (self.weapon == other.weapon || (self.weapon == EqualNonPapWeapon(other.weapon))) {
			other.currentammo = getWeaponAmmo(self.weapon);
		} else if (self.weapon == other.secondaryweapon || (self.weapon == EqualNonPapWeapon(other.secondaryweapon)) ) {
			other.secondaryammo = getWeaponAmmo(self.weapon);
		}
		

		sound(other, 0,"sounds/misc/ching.wav", 1, 1);
		other.reload_delay = 0;
		
		if (!IsPapWeapon(other.weapon))
			addmoney(other, -1*self.cost2, 0);
		else
			addmoney(other, -1*4500, 0);
			
		if (self.enemy) {
			oldent = self;
			self = self.enemy;
			self.use();
			self = oldent;
		}
	}
	if (self.weapon == W_BETTY)
	{
		if (other.secondary_grenades < 2)
			useprint (other, 3, self.cost2, self.weapon);
		else
			return;
		if (!other.button7 || other.semiuse)
			return;
		if (other.points < self.cost2)
		{
			centerprint(other, "You do not have enough points\n");
			sound(other, 0,"sounds/misc/denybuy.wav", 1, 1);
			return;
		}
		else
		{
			other.ach_tracker_coll++;
			other.reload_delay = 0;
			sound(other, 0,"sounds/misc/ching.wav", 1, 1);
			//other.boughtweapon = true;
			addmoney(other, 0 - self.cost2, FALSE);
			other.grenades = other.grenades | 2;
			other.secondary_grenades = 2;
			if (self.enemy)
			{
				oldent = self;
				self = self.enemy;
				self.use();
				self = oldent;
			}
		}
		other.semiuse = true;
		return;
	}
	else if (self.weapon == W_GRENADE)
	{
		if (other.primary_grenades < 4)
			useprint (other, 3, self.cost2, self.weapon);
		else
			return;
		if (!other.button7 || other.semiuse)
			return;
		if (other.points < self.cost)
		{
			centerprint(other, "You do not have enough points\n");
			sound(other, 0,"sounds/misc/denybuy.wav", 1, 1);

			return;
		}
		else
		{
			other.ach_tracker_coll++;
			other.reload_delay = 0;
			sound(other, 0,"sounds/misc/ching.wav", 1, 1);
			//other.boughtweapon = true;
			addmoney(other, 0 - self.cost, FALSE);
			other.primary_grenades = 4;
			if (self.enemy)
			{
				oldent = self;
				self = self.enemy;
				self.use();
				self = oldent;
			}
		}
		other.semiuse = true;
		return;
	}
	else if (self.weapon == W_BOWIE)
	{
		if (!other.bowie) {
			useprint(other, 3, self.cost2, self.weapon);
			if (other.button7)
			{
				other.ach_tracker_coll++;
				entity tempz;
				tempz = self;
				self = other;
				Set_W_Frame(15, 30, 0, 0, 0, ReturnWeaponModel, "progs/VModels/v_bowie.mdl", false, S_BOTH);
				self.bowie = 1;
			}
		}
	}
	else
	{
		entity tempe;
      
		//centerprint(other, self.message);
      	useprint (other, 4, self.cost, self.weapon);

		if (!other.button7 || other.semiuse) {
			return;
		}

		other.semiuse = 1;
		if (other.points < self.cost) {
			centerprint (other, "Not enough points\n");
			return;
		}

		other.ach_tracker_coll++;

		if (other.weapon && !other.secondaryweapon) {
			tempf = other.currentammo;
			other.currentammo = other.secondaryammo;
			other.secondaryammo = tempf;

			tempf1 = other.currentmag;
			other.currentmag = other.secondarymag;
			other.secondarymag = tempf1;

			tempf2 = other.weapon;
			other.weapon = other.secondaryweapon;
			other.secondaryweapon = tempf2;

			tempf3 = other.currentmag2;
			other.currentmag2 = other.secondarymag2;
			other.secondarymag2 = tempf3;
		} else if (other.weapon && other.secondaryweapon) {
			if ((other.perks & P_MULE) && !other.thirdweapon) {
				// store secondary weapon
				tempf = other.secondaryweapon;
				tempf1 = other.secondarymag;
				tempf2 = other.secondaryammo;
				tempf3 = other.secondarymag2;
				// move primary to secondary
				other.secondaryweapon = other.weapon;
				other.secondarymag = other.currentmag;
				other.secondarymag2 = other.currentmag2;
				other.secondaryammo = other.currentammo;
				// move secondary to tertiary
				other.thirdweapon = tempf;
				other.thirdmag = tempf1;
				other.thirdammo = tempf2;
				other.thirdmag2 = tempf3;
			}

			// free current slot
			other.currentammo = 0;
			other.currentmag = 0;
			other.weapon = 0;
		}
		
		sound(other, 0,"sounds/misc/ching.wav", 1, 1);
		other.reload_delay = 0;
		addmoney(other, -1*self.cost, 0);
		if (self.enemy) {
			oldent = self;
			self = self.enemy;
			self.use();
			self = oldent;
		}
		other.weapon = self.weapon;
		
		other.currentammo = getWeaponAmmo(self.weapon);
		other.currentmag = getWeaponMag(self.weapon);
		tempe = self;
		self = other;
		startframe = GetFrame(self.weapon,TAKE_OUT_START);
		endframe = GetFrame(self.weapon,TAKE_OUT_END);
		modelname = GetWeaponModel(self.weapon, 0);
		
		if (self.weapon != W_KAR_SCOPE && self.weapon != W_HEADCRACKER && !IsDualWeapon(self.weapon)) {
			self.weapon2model = "";
		}

		SwitchWeapon(self.weapon);
		Set_W_Frame (startframe, endframe, 0, 0, 0, SUB_Null, modelname, false, S_BOTH);//FIXME
		
		#ifndef PC
		self.Flash_Offset = GetWeaponFlash_Offset(self.weapon);
		self.Flash_Size = GetWeaponFlash_Size(self.weapon);
		self.Weapon_Name = GetWeaponName(self.weapon);
		#endif
		
		self = tempe;
	}

	if (other.ach_tracker_coll == ach_tracker_col2) {
		GiveAchievement(12, other);
	}
};

void() buy_weapon_link_wall =
{
	entity ent;
	
	ent = find (world, targetname, self.target);
	
	if (ent.classname == "weapon_wall")
		self.enemy = ent;
}

void() buy_weapon =
{
	local string weaponname;
	InitTrigger ();
	weaponname = GetWeaponModel (self.weapon, 0);
	if (weaponname != "")
		precache_model (weaponname);
	weaponname = GetWeaponModel(self.weapon, 1);
	if (weaponname != "")
		precache_model (weaponname);
	
	
	precache_extra (self.weapon);
	self.touch = buy_weapon_touch;
	
	self.think = buy_weapon_link_wall;
	self.nextthink = time + 0.2; 

	ach_tracker_col2++;

	precache_sound("sounds/misc/ching.wav");
};



void() BarrelExplode =
{
	sound (self, CHAN_WEAPON, "sounds/weapons/grenade/explode.wav", 1, ATTN_NORM);	
	DamgageExplode (self, self.enemy, 500, 650, 200);
	
	#ifdef PC
    te_customflash(self.origin, 128, 300, '1 1 1');
	#endif

    CallExplosion(self.origin);

	SUB_Remove ();
};

void() barrel_hit =
{
	if (self.health <= 0) {
		BarrelExplode();
	} else if (self.health <= 200) {
		makevectors(self.angles);
		self.think = barrel_hit;
		self.nextthink = time + 0.1;
		self.health = self.health - 1;
		if (self.health > 100)
			particle (self.origin + '0 0 30', v_up*8, 111, 0);
		else
			particle (self.origin + '0 0 30', v_up*8, 112, 0);
    
	}
}

void() explosive_barrel = 
{
	precache_model ("models/props/barrel_m.mdl");

	self.movetype = MOVETYPE_NONE;	// so it doesn't get pushed by anything
	self.solid=SOLID_BBOX;
	self.classname = "explosive_barrel";
	setmodel (self, "models/props/barrel_m.mdl");
	setsize (self, '-10 -10 ', '10 10 38');

	self.takedamage = DAMAGE_YES;
	self.health = 300;
};

.float radioState;
.float length;
.string tune;
void() radioPlay =
{
	self.health = 1;

	if (self.radioState == 1) {
		sound (self, CHAN_ITEM, self.tune, 1, ATTN_NORM);
		self.nextthink = time + self.length;
		self.think = radioPlay;
	} else if (self.radioState == 0) {
		sound (self, CHAN_ITEM, "sounds/null.wav", 1, ATTN_NONE);
		self.nextthink = 0;
		self.think = SUB_Null;
	}
}

void() radio_hit =
{
	self.health = 1;

	sound (self, CHAN_ITEM, "sounds/misc/radio.wav", 1, ATTN_NORM);
	self.nextthink = time + 1;//getSoundLen("sounds/music/tune1.wav");
	self.think = radioPlay;
	
	if (self.radioState == 0)
		self.radioState = 1;
	else if (self.radioState == 1)
		self.radioState = 0;
}

void() item_radio = 
{
	precache_model ("models/props/radio.mdl");
	precache_sound ("sounds/misc/radio.wav");

	if(self.tune) {
		precache_sound (self.tune);
	}

	self.movetype = MOVETYPE_NONE;	// so it doesn't get pushed by anything
	self.solid=SOLID_BBOX;
	self.classname = "item_radio";
	setmodel (self, "models/props/radio.mdl");
	setsize (self, '-8 -8 -4', '8 8 4');

	self.takedamage = DAMAGE_YES;
	self.health = 1;
	self.radioState = 0;
	self.th_die = radio_hit;
};

.string zappername;
void()	turnswitch1	=[	1,		turnswitch2	] {self.frame = 0;};
void()	turnswitch2	=[	2,		turnswitch3	] {self.frame = 1;};
void()	turnswitch3	=[	3,		turnswitch4	] {self.frame = 2;};
void()	turnswitch4	=[	4,		SUB_Null	] {self.frame = 2;};

void()	offswitch2		=[	2,		offswitch3		] {self.frame = 2;};
void()	offswitch3		=[	3,		offswitch4		] {self.frame = 1;};
void()	offswitch4		=[	4,		SUB_Null		] {self.frame = 0;};


void zap_zombie () {
	entity tempe;

	if (other.classname == "ai_zombie") {
		tempe = self;
		self = other;
		self.th_die();
		self = tempe;	
	} else if (other.classname == "player") {
		if (other.damagetimer < time) {
			DamageHandler (other, self, 50, S_ZAPPER);
			other.damagetimer = time + 1.5;
		}
	}
}


void zapper_play () {
	entity zents = find(world, targetname, self.target);
	local vector org = self.origin;
	local vector targetorg = zents.origin;

	if (zents) {
		#ifdef PC
		te_lightning2(self, self.origin, zents.origin);
		#endif
		#ifdef PSP
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
		WriteEntity (MSG_BROADCAST, self);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
		WriteCoord (MSG_BROADCAST, targetorg_x);
		WriteCoord (MSG_BROADCAST, targetorg_y);
		WriteCoord (MSG_BROADCAST, targetorg_z);
		#endif
	}

	zents.touch = zap_zombie;
	
	self.think = zapper_play;
	self.nextthink = time + (0.5*random());
}

void() zapper_touch;
void() zapper_cooldown =
{
	offswitch2();
	self.touch = zapper_touch;
}

void zapper_stop() {
	entity zents;
	entity tempe;

	zents = find(world, zappername, self.zappername);
	while (zents)
	{
		if (zents.classname == "zapper_light") {
			zents.skin = 0;
		} else if (zents.classname == "zapper_switch") {
			tempe = self;
			self = zents;
			self.state = 0;
			self.think = zapper_cooldown;
			self.nextthink = time + 30;
			self = tempe;
		} else if (zents.classname == "zapper_node" && zents.target) {
			zents.think = SUB_Null;
			zents.nextthink = 0;
		}
		zents.touch = SUB_Null;
		zents = find(zents, zappername, self.zappername);
	}

	remove(self);
}

void zapper_start(string zapper) {
	entity zents;
	entity tempe;

	zents = find(world, zappername, zapper);
	while (zents)
	{
		if (zents.classname == "zapper_light") {
			zents.skin = 1;
		} else if (zents.classname == "zapper_switch") {
			tempe = self;
			self = zents;
			self.state = 1;
			turnswitch1();
			self = tempe;
		} else if (zents.classname == "zapper_node" && zents.target) {
			zents.think = zapper_play;
			zents.nextthink = time + 0.1;
		}
		zents = find(zents, zappername, zapper);
	}

	tempe = spawn();
	tempe.think = zapper_stop;
	tempe.nextthink = time + 30;
	tempe.zappername = zapper;
}

void zapper_touch () {
	if (other.classname != "player") {
		return;
	}

	if (self.requirespower == true && !isPowerOn) {
		useprint (other, 8, 0, 0);
		return;
	}	

	if (self.state == 0) {
		useprint (other, 11, self.cost, self.weapon);

		if (!other.button7) {
			return;
		}

		if (other.points < self.cost) {
			centerprint(other, "You do not have enough points\n");
			return;
		}

		zapper_start(self.zappername);
		addmoney(other, -1*self.cost, false);
	}
}

void() zapper_switch = 
{
	precache_model ("models/machines/zapper/z_switch.mdl");
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_TRIGGER;
	self.classname = "zapper_switch";
	setmodel(self, "models/machines/zapper/z_switch.mdl");
	setsize (self, '-4 -4 -4', '4 4 4');

	self.state = 0;
	self.touch = zapper_touch;
};

void() zapper_node = 
{
	precache_model ("models/machines/zapper/z_zap.mdl");
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_TRIGGER;
	self.classname = "zapper_node";
	setmodel(self, "models/machines/zapper/z_zap.mdl");
	setsize (self, '-4 -4 -4', '4 4 4');
};

void() zapper_light = 
{
	precache_model ("models/machines/zapper/z_light.mdl");
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_TRIGGER;
	//self.touch = switch_touch;
	self.classname = "zapper_light";
	setmodel(self, "models/machines/zapper/z_light.mdl");
	setsize (self, '-4 -4 -4', '4 4 4');
};


void() trigger_electro =
{
	self.classname = "zapper_field";
	InitTrigger ();
	//self.touch = electro_touch;
	self.solid = SOLID_TRIGGER;
};

/* ================
   Custom Teddy Code
   ================*/

void() teddy_spawn = 
{
	precache_model ("progs/Props/teddy.mdl");

	self.movetype = MOVETYPE_NONE;	// so it doesn't get pushed by anything
	self.solid=SOLID_BBOX;
	self.classname = "teddy_spawn";
	setmodel (self, "progs/Props/teddy.mdl");
	setsize (self, '-8 -8 -4', '8 8 4');

	self.takedamage = DAMAGE_YES;
	self.health = 0;
	self.th_die = teddy_react;
};

/* ==================
    Custom Song Code
   ================== */

void() touch_songtrigger = {
	if (other.classname != "player" || self.activated)
		return;

	if (other.button7) {
		sound(self, CHAN_VOICE, self.tune, 1, ATTN_NORM);
		self.activated = true;
		sndActivCnt++;

		if (sndTriggerCnt == sndActivCnt)
			playSoundAtPlayers(world.song);
	}
	
}

void() trigger_song = {
	#ifndef PC
	remove(self);
	#endif

	precache_model(self.model);
	precache_sound(self.tune);

	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_TRIGGER;
	self.classname = "trigger_song";
	setmodel(self, self.model);
	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);

	self.touch = touch_songtrigger;

	sndTriggerCnt++;
}

/* 
   ============
    Teleporter
   ============ 

	Teleporters have 3 different modes

	0: Default Patch 1.0.4 Mode
		- Interact with teleporter and go to pad (credit: Naievil and PerikiyoXD)

	1: Linked Mode
		- One-Time-Link teleporter with pad, teleport to pad

	2: Timed Mode
		- Link teleporter with pad, teleport to other destination
		  for a set amount of time, then return to pad. Link every time.
   
   TODO:
		- Sounds
		- Keep track of whether player is touching instead of locking movement
*/

void() teleporter_cooldown =
{
	self.activated = false;

	if (self.mode == 2) {
		self.isLinked = false;
	}

	self.cooldown = false;
}

void() start_cooldown =
{
	self.cooldown = true;
	self.think = teleporter_cooldown;
	self.nextthink = time + 5;
}

void() teleport_entity =
{
  	local entity who, en; 
  
  	who = find(world, classname ,"player");
	en = find(world, targetname, self.target2);
  
  
    SUB_UseTargets ();
        
    setorigin (who, who.tele_target.origin);

	if (self.isTimed || en.classname == "func_teleporter_pad") {
		setorigin(who, who.origin + '0 0 40');
	}

    who.fire_delay = who.reload_delay = 3.0 + time;
    who.zoom = 0;
    who.weaponmodel = "";
    who.weapon2model = ""; 
	who.movetype = MOVETYPE_WALK;
      
    if (who.classname == "player") {
      if (who.flags & FL_ONGROUND)
        who.flags = who.flags - FL_ONGROUND;
      who.velocity = v_forward * 0;
      
    }

    who.flags = who.flags - who.flags & FL_ONGROUND;

	if (self.mode == 0) {
		self.activated = false;
	} else if (self.mode == 2 && !self.isTimed) {
		who.tele_target = find(world, targetname, self.target2);

		self.nextthink = time + self.tpTimer;
		self.think = teleport_entity;
		self.isTimed = true;
	} else {
		start_cooldown();
		self.isTimed = false;
	}
}

void() teleport_pad_touch =
{
	if (other.classname != "player" || self.host.isLinked)
		return;

	if (!isPowerOn) {
     	useprint(other, 8, 0, 0);
    	return;
    } 

	if (self.host.waitLink) {
		useprint(other, 19, 0, 0);

		if (other.button7) {
			self.host.isLinked = true;
			self.host.waitLink = false;
		}
	} else {
		if (self.host.mode == 2) {
			useprint(other, 18, 0, 0);
		}
	}
}

void() teleporter_link_touch =
{

	if (!self.waitLink)
		useprint(other, 17, 0, 0);

	if (other.button7) {
		local entity en;

		en = find(world, targetname, self.target2);
		self.waitLink = true;
		en.host = self;
	}
}

void() teleport_touch =
{
	if (self.cooldown) {
		useprint(other, 16, 0, 0);
		return;
	}

  	if (other.classname != "player" || self.activated)
    	return;  
  
  	if (!isPowerOn) {
     	useprint(other, 8, 0, 0);
    	return;
    } 

	if (self.mode != 0 && !self.isLinked) {
		teleporter_link_touch();
		return;
	}
    
	if (!self.cost)
  		useprint(other, 14, 0, 0);
	else
		useprint(other, 15, self.cost, 0);
	

	if (other.button7) {

		if (other.points < self.cost) {
			centerprint(other, "Not enough points");
			return;
		}

		addmoney(other, -self.cost, 0);

		SUB_UseTargets();
		other.tele_target = find(world, targetname, self.target);

		if (!other.tele_target)
			objerror("Couldn't find target!");

		self.activated = true;

		other.movetype = MOVETYPE_NONE;

		self.think = teleport_entity;
		self.nextthink = time + 3;
	}

	if (other.button1) {
    	if (self.targetname) {
      		if (self.nextthink < time)
        		return;		// not fired yet
      	}
    }
}

void() teleport_use =
{
	self.nextthink = time + 2;
	force_retouch = 2;		// make sure even still objects get hit
	self.think = SUB_Null;
}

void() func_teleporter_entrance =
{		
	precache_model ("progs/Props/teleporter.mdl");
	
	self.movetype = MOVETYPE_NONE;	// so it doesn't get pushed by anything
	self.solid = SOLID_TRIGGER;
	self.classname = "func_teleporter_entrance";
  	setmodel(self, "progs/Props/teleporter.mdl");
  	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	
    self.touch = teleport_touch;

    // find the destination 
    if (!self.target)
		objerror("No target!");

	if (self.mode != 0) {
		if (!self.target2)
			objerror("No mainframe!");

		if (self.mode == 2) {
			local entity tempe;
			tempe = find(world, targetname, self.target2);
			tempe.host = self;
		}
	}

    self.use = teleport_use;
}

void() func_teleporter_destination =
{
	// this does nothing, just serves as a target spot
	self.origin = self.origin + '0 0 40';
	self.classname = "func_teleporter_destination";
}

void() func_teleporter_timed =
{
	// this does nothing, just serves as a target spot
	self.origin = self.origin + '0 0 40';
	self.classname = "func_teleporter_timed";
}


void() func_teleporter_pad =
{
	precache_model ("progs/Props/mainframe_pad.mdl");
	
	self.movetype = MOVETYPE_NONE;	// so it doesn't get pushed by anything
	self.solid = SOLID_TRIGGER;
	self.classname = "func_teleporter_pad";
  	setmodel(self, "progs/Props/mainframe_pad.mdl");
  	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	
    self.touch = teleport_pad_touch;
}

/* ================
    Buyable Ending
   ================ */
void() touch_ending =
{
	if (other.classname != "player" || self.activated)
		return;
	
	useprint(other, 20, self.cost, 0);

	if (other.button7) {

		if (other.points < self.cost)
			return;

		addmoney(other, -self.cost, 0);

		local entity tempe;
		tempe = self;
		self = other;
		EndGameSetup();
		self = tempe;

		self.activated = true;
	}
}

void() func_ending =
{  
	precache_model (self.model);
	
	self.movetype = MOVETYPE_NONE;	// so it doesn't get pushed by anything
	self.solid = SOLID_TRIGGER;
	self.classname = "func_ending";
  	setmodel(self, self.model);
  	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	
    self.touch = touch_ending;
};