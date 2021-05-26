
float backupWepSkin;
float sound_perk_delay; 
void() W_Switch;
void() W_TakeOut;
void() mystery_touch;

//
// --------------------
// Lights
// --------------------
//

//
// Light_Red(e)
// RGB: 255, 56, 56
//
void(entity e) Light_Red =
{
    e.effects = e.effects | EF_FULLBRIGHT;
    #ifndef PC
    e.effects = e.effects | EF_RED;
    #else
    {
        e.pflags = PFLAGS_FULLDYNAMIC;
       	e.light_lev = 100;
	    e.color_x = 2;	
	    e.color_y = 0.25;	
	    e.color_z = 0.25;
    }
    #endif
}

//
// Light_Green(e)
// RGB: 56, 255, 56
//
void(entity e) Light_Green =
{
    e.effects = e.effects | EF_FULLBRIGHT;
    #ifndef PC
    e.effects = e.effects | EF_GREEN;
    #else
    {
        e.pflags = PFLAGS_FULLDYNAMIC;
       	e.light_lev = 100;
	    e.color_x = 0.25;	
	    e.color_y = 2;	
	    e.color_z = 0.25;
    }
    #endif
}

//
// Light_Blue(e)
// RGB: 56, 56, 255
//
void(entity e) Light_Blue =
{
    e.effects = e.effects | EF_FULLBRIGHT;
    #ifndef PC
    e.effects = e.effects | EF_BLUE;
    #else
    {
        e.pflags = PFLAGS_FULLDYNAMIC;
       	e.light_lev = 100;
	    e.color_x = 0.25;	
	    e.color_y = 0.25;	
	    e.color_z = 2;
    }
    #endif
}

//
// Light_Orange(e)
// RGB: 255, 128, 0
//
void(entity e) Light_Orange =
{
    e.effects = e.effects | EF_FULLBRIGHT;
    #ifndef PC
    e.effects = e.effects | EF_ORANGELIGHT;
    #else
    {
        e.pflags = PFLAGS_FULLDYNAMIC;
       	e.light_lev = 100;
	    e.color_x = 2;	
	    e.color_y = 1;	
	    e.color_z = 0;
    }
    #endif
}

//
// Light_Purple(e)
// RGB: 255, 28, 255
//
void(entity e) Light_Purple =
{
    e.effects = e.effects | EF_FULLBRIGHT;
    #ifndef PC
    e.effects = e.effects | EF_PURPLELIGHT;
    #else
    {
        e.pflags = PFLAGS_FULLDYNAMIC;
       	e.light_lev = 100;
	    e.color_x = 2;	
	    e.color_y = 0.25;	
	    e.color_z = 2;
    }
    #endif
}

//
// Light_None(e)
// Resets all Perk Light Effects.
//
void(entity e) Light_None =
{
	e.effects = 0;
	#ifdef PC
	{
		e.pflags = 0;
		e.light_lev = 0;
		e.color_x = 0;
		e.color_y = 0;
		e.color_z = 0;
	}
	#endif
}

//
// Light_Custom(e, r, g, b)
// For custom Perk Light Effects, generally not recommended
// unless you're testing a cool selection of colors and do not
// want to constantly recompile the client, or the client is
// inaccessible. Only functional on PC/FTE atm (TODO?)
//
void(entity e, float r, float g, float b) Light_Custom =
{
	e.effects = e.effects | EF_FULLBRIGHT;
	#ifdef PC
	{
		e.pflags = PFLAGS_FULLDYNAMIC;
		e.light_lev = 100;
		e.color_x = r/255;
		e.color_y = g/255;
		e.color_z = b/255;
	}
	#endif
}

//
// --------------------
// Core Perk System
// --------------------
//

//
// GivePerk(p)
// Restores View Model and tells the Client to draw the Perk.
//
void GivePerk(optional float p) {
	local float perk;

	// First of, check if our Client is holding anything, this holds
	// priority to prevent interruption.
	if (self.style != 0) {
		perk = self.style;
		self.style = 0;
	} 
	// Next, check if a perk was explicitly set
	else if (p) {
		perk = p;
	}
	// Executed without context.. Nothing to do.
	else {
		return;
	}

	// No Perks? No Problem tracker
	self.ach_tracker_npnp++;

	switch(perk) {
		case P_REVIVE:
			self.perks = self.perks | 8;
			break;
		case P_FLOP:
			self.perks = self.perks | 16;
			break;
		case P_JUG:
			self.perks = self.perks | 1;
			break;
		case P_STAMIN:
			self.perks = self.perks | 32;
			break;
		case P_SPEED:
			self.perks = self.perks | 4;
			break;
		case P_DOUBLE:
			self.perks = self.perks | 2;
			break;
		case P_DEAD:
			self.perks = self.perks | 64;
			break;
		case P_MULE:
			self.perks = self.perks | 128;
			break;
		default:
			break;
	}

	if (self.perks == 255)
		GiveAchievement(6, self);

  	sound_perk_delay = time + 4.5;
	self.isBuying = false;
	string modelname = GetWeaponModel(self.weapon, 0);

	local float startframe = GetFrame(self.weapon,TAKE_OUT_START);
	local float endframe = GetFrame(self.weapon,TAKE_OUT_END);

	self.weaponskin = backupWepSkin;
	self.perk_delay = self.fire_delay;
	Set_W_Frame (startframe, endframe, 0, 0, 0, SUB_Null, modelname, false, S_BOTH);

	SetPerk(self, self.perks);
}

//
// DrinkPerk(perk)
// Gives Perk Bottle and jumps to GivePerk(p)
//
void DrinkPerk(float perk) {
	// Set the Perk Skin based on the Perk sequence.
	// NOTE: If you add perks, you will either need to append
	// the MDL with a tool like QuArK or add an edge-case
	// after this instruction to have a valid skin.
	other.weaponskin = self.sequence - 1;

	other.isBuying = true;
	entity tempe = self;
	self = other;
	
	if (self.sprinting)
		self.sprinting = 0;

	self.maxspeed *= GetWeaponWalkSpeed(self.perks, self.weapon);
	
	self.knife_delay = self.reload_delay2 = self.fire_delay2 = self.fire_delay = self.reload_delay = 4.5 + time;		
	Set_W_Frame (tempe.weapon_animduration, tempe.weapon2_animduration, 0, 0, PERK, GivePerk, tempe.weapon2model, true, S_RIGHT);
	self = tempe;
	sound(other, CHAN_ITEM, self.oldmodel, 1, ATTN_NORM);

	// Play Perk Sting if we can and it exists
	if (self.aistatus && self.ltime < time) {
		sound(self, CHAN_AUTO, self.aistatus, 0.25, ATTN_IDLE);
		self.ltime = time + self.anim_weapon_time;
	}
}

//
// touch_perk()
// Executed on touch; prompt purchase and drink if requirements met.
// -----
// MotoLegacy (10-28-20) - Made modular using some existing entity fields we had,
// as the memory is allocated to all entities on load anyway. This comment applies
// to all other relevant jumps as well.
//
void() touch_perk =
{  
	if (other.classname != "player" || other.downed || other.isBuying == true || !isFacing(other, self))
		return;

	// If we're proned and the map permits, collect some spare change
	if (other.stance == 0 && self.collected == false && G_PRONEPOINTS != 0) {
		self.collected = true;
		addmoney(other, G_PRONEPOINTS, 0);
		sound(self, 0,"sounds/misc/ching.wav", 1, 1);
	}

	// Do this after the perk change check
	if (other.stance == 0)
		return;
	  
	// Power's off! Nothing to do here.
	if (self.requirespower == true && !isPowerOn) {
		useprint (other, 8, 0, 0);
		return;
	}

	// Back up weapon skin
	backupWepSkin = other.weaponskin;

	// Don't prompt if our hands or busy or we already have the perk
	if (!(other.perks & self.style) && other.fire_delay < time) {
		// sequence = perk ID in client
		useprint(other, 9, self.cost, self.sequence);

		if (other.points >= self.cost && other.button7) {
			addmoney(other, -self.cost, 0);

			// Pass along the Perk information to the Player to avoid complications later on, then Drink!
			other.style = self.style;
			DrinkPerk(self.style);

			// Do Self-Revive checks
			if (self.classname == "perk_revive" && !coop && !deathmatch) {
				// Increment self-revive count
				other.revivesoda++;

				if (other.revivesoda >= 3) {
					setmodel(self, ""); // We don't want to remove Revive in the event of a Soft_Restart..
				}
			}
		} else if (other.button7) {
			// We tried to use, but we don't have the cash..
			centerprint(other, "Not enough points\n");
		}
	}
}

//
// Turn_PerkLight_On(who)
// Turns on the Perk Lights
//
void(entity who) Turn_PerkLight_On =
{
	if (who.spawnflags & 1) {
		Light_None(who);
	}
	if (who.spawnflags & 2) {
		Light_Red(who);
	}
	if (who.spawnflags & 4) {
		Light_Green(who);
	}
	if (who.spawnflags & 8) {
		Light_Blue(who);
	}
	if (who.spawnflags & 16) {
		Light_Orange(who);
	}
	if (who.spawnflags & 32) {
		Light_Purple(who);
	}
}

//
// Perk_Jingle()
// The Think loop for Perk Jingles
//
void() Perk_Jingle =
{
	// If Revive is gone, don't bother to check anymore
	if (self.revivesoda >= 3)
		return;

	local float jinglewaittime;
	jinglewaittime = rint((random() * 30)) + 30;

	// Just try again later if the Power isn't Activated
	if ((self.requirespower == true && !isPowerOn) || self.ltime > time) {
		self.nextthink = time + jinglewaittime;
	} else {
		// 15% Chance to Play Jingle
		local float chance = random();
		if (chance <= 0.15) {
			sound(self, CHAN_AUTO, self.powerup_vo, 0.25, ATTN_IDLE);
			self.ltime = time + self.anim_weapon2_time;
			jinglewaittime += self.anim_weapon2_time;
		}

		self.nextthink = time + jinglewaittime;
	}
}

//
// setup_perk()
// Readies up misc. Perk aesthetics
//
void() setup_perk =
{
	local entity power = find(world, classname, "power_switch");

	// Check for Revive before Power
	if (self.classname == "perk_revive" && !coop && !deathmatch) {
		Turn_PerkLight_On(self);
	} else {
		// Check for Power
		if (power != world) {
			self.requirespower = true;
		} else {
			// There's no Power Switch, so turn the rest On.
			Turn_PerkLight_On(self);
		}
	}

	// Perk Jingle Timer
	if (self.powerup_vo) {
		self.think = Perk_Jingle;
		self.nextthink = time + rint((random() * 30)) + 30;
	}
}

//
// --------------------
// Perk Entity Spawn Functions
// --------------------
//

// Quick Revive
void() perk_revive =
{
	//
	// Set Default Stats for Compatibility
	//
	
	// Model
	if (!self.model) {
		self.model = "models/machines/quick_revive.mdl";
	}

	// Perk Cost
	if (!self.cost) {
		self.cost = 500;
		self.cost2 = 1500;
	}

	// Player Trigger Sound
	if (!self.oldmodel) {
		self.oldmodel = "sounds/machines/perk_drink.wav";
	}

	// View Model
	if (!self.weapon2model) {
		self.weapon2model = "models/machines/v_perk.mdl";
	}

	// View Model Start Frame
	if (!self.weapon_animduration) {
		self.weapon_animduration = 0;
	}

	// View Model End Frame
	if (!self.weapon2_animduration) {
		self.weapon2_animduration = 22;
	}

	// Light Effect
	if (!self.spawnflags) {
		self.spawnflags = self.spawnflags | 8;
	}

	// Set up the Perk Entity
	self.solid = SOLID_TRIGGER;
	precache_model(self.model);
	precache_model(self.weapon2model);
	precache_sound(self.oldmodel);
	if (self.aistatus) { precache_sound(self.aistatus); }
	if (self.powerup_vo) { precache_sound(self.powerup_vo); }
	precache_sound("sounds/weapons/papfire.wav");
	precache_extra(W_BIATCH);
	setorigin(self, self.origin);
	setmodel(self, self.model);
	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_revive";
	self.touch = touch_perk;
	self.think = setup_perk;
	self.nextthink = time + 0.1;

	// Drink Information
	self.sequence = 1;
	self.style = P_REVIVE;
};

// PhD Flopper
void() perk_flopper =
{
	//
	// Set Default Stats for Compatibility
	//
	
	// Model
	if (!self.model) {
		self.model = "models/machines/flopper.mdl";
	}

	// Perk Cost
	if (!self.cost) {
		self.cost = 2000;
	}

	// Player Trigger Sound
	if (!self.oldmodel) {
		self.oldmodel = "sounds/machines/perk_drink.wav";
	}

	// View Model
	if (!self.weapon2model) {
		self.weapon2model = "models/machines/v_perk.mdl";
	}

	// View Model Start Frame
	if (!self.weapon_animduration) {
		self.weapon_animduration = 0;
	}

	// View Model End Frame
	if (!self.weapon2_animduration) {
		self.weapon2_animduration = 22;
	}

	// Light Effect
	if (!self.spawnflags) {
		self.spawnflags = self.spawnflags | 16;
	}

	// Set up the Perk Entity
	self.solid = SOLID_TRIGGER;
	precache_model(self.model);
	precache_model(self.weapon2model);
	precache_sound(self.oldmodel);
	if (self.aistatus) { precache_sound(self.aistatus); }
	if (self.powerup_vo) { precache_sound(self.powerup_vo); }
	setorigin(self, self.origin);
	setmodel(self, self.model);
	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_flopper";
	self.touch = touch_perk;
	self.think = setup_perk;
	self.nextthink = time + 0.1;

	// Drink Information
	self.sequence = 6;
	self.style = P_FLOP;
};

// Jugger-Nog
void() perk_juggernog =
{
	//
	// Set Default Stats for Compatibility
	//
	
	// Model
	if (!self.model) {
		self.model = "models/machines/juggernog.mdl";
	}

	// Perk Cost
	if (!self.cost) {
		self.cost = 2500;
	}

	// Player Trigger Sound
	if (!self.oldmodel) {
		self.oldmodel = "sounds/machines/perk_drink.wav";
	}

	// View Model
	if (!self.weapon2model) {
		self.weapon2model = "models/machines/v_perk.mdl";
	}

	// View Model Start Frame
	if (!self.weapon_animduration) {
		self.weapon_animduration = 0;
	}

	// View Model End Frame
	if (!self.weapon2_animduration) {
		self.weapon2_animduration = 22;
	}

	// Light Effect
	if (!self.spawnflags) {
		self.spawnflags = self.spawnflags | 2;
	}

	// Set up the Perk Entity
	self.solid = SOLID_TRIGGER;
	precache_model(self.model);
	precache_model(self.weapon2model);
	precache_sound(self.oldmodel);
	if (self.aistatus) { precache_sound(self.aistatus); }
	if (self.powerup_vo) { precache_sound(self.powerup_vo); }
	setorigin(self, self.origin);
	setmodel(self, self.model);
	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_juggernog";
	self.touch = touch_perk;
	self.think = setup_perk;
	self.nextthink = time + 0.1;

	// Drink Information
	self.sequence = 2;
	self.style = P_JUG;
};

// Stamin-Up
void() perk_staminup =
{
	//
	// Set Default Stats for Compatibility
	//
	
	// Model
	if (!self.model) {
		self.model = "models/machines/staminup.mdl";
	}

	// Perk Cost
	if (!self.cost) {
		self.cost = 2000;
	}

	// Player Trigger Sound
	if (!self.oldmodel) {
		self.oldmodel = "sounds/machines/perk_drink.wav";
	}

	// View Model
	if (!self.weapon2model) {
		self.weapon2model = "models/machines/v_perk.mdl";
	}

	// View Model Start Frame
	if (!self.weapon_animduration) {
		self.weapon_animduration = 0;
	}

	// View Model End Frame
	if (!self.weapon2_animduration) {
		self.weapon2_animduration = 22;
	}

	// Light Effect
	if (!self.spawnflags) {
		self.spawnflags = self.spawnflags | 16;
	}

	// Set up the Perk Entity
	self.solid = SOLID_TRIGGER;
	precache_model(self.model);
	precache_model(self.weapon2model);
	precache_sound(self.oldmodel);
	if (self.aistatus) { precache_sound(self.aistatus); }
	if (self.powerup_vo) { precache_sound(self.powerup_vo); }
	setorigin(self, self.origin);
	setmodel(self, self.model);
	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_staminup";
	self.touch = touch_perk;
	self.think = setup_perk;
	self.nextthink = time + 0.1;

	// Drink Information
	self.sequence = 5;
	self.style = P_STAMIN;
};

// Speed Cola
void() perk_speed =
{
	//
	// Set Default Stats for Compatibility
	//
	
	// Model
	if (!self.model) {
		self.model = "models/machines/speed_cola.mdl";
	}

	// Perk Cost
	if (!self.cost) {
		self.cost = 3000;
	}

	// Player Trigger Sound
	if (!self.oldmodel) {
		self.oldmodel = "sounds/machines/perk_drink.wav";
	}

	// View Model
	if (!self.weapon2model) {
		self.weapon2model = "models/machines/v_perk.mdl";
	}

	// View Model Start Frame
	if (!self.weapon_animduration) {
		self.weapon_animduration = 0;
	}

	// View Model End Frame
	if (!self.weapon2_animduration) {
		self.weapon2_animduration = 22;
	}

	// Light Effect
	if (!self.spawnflags) {
		self.spawnflags = self.spawnflags | 4;
	}

	// Set up the Perk Entity
	self.solid = SOLID_TRIGGER;
	precache_model(self.model);
	precache_model(self.weapon2model);
	precache_sound(self.oldmodel);
	if (self.aistatus) { precache_sound(self.aistatus); }
	if (self.powerup_vo) { precache_sound(self.powerup_vo); }
	setorigin(self, self.origin);
	setmodel(self, self.model);
	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_speed";
	self.touch = touch_perk;
	self.think = setup_perk;
	self.nextthink = time + 0.1;

	// Drink Information
	self.sequence = 3;
	self.style = P_SPEED;
};

// Double Tap Door Beer
void() perk_double =
{
	//
	// Set Default Stats for Compatibility
	//
	
	// Model
	if (!self.model) {
		self.model = "models/machines/double_tap.mdl";
	}

	// Perk Cost
	if (!self.cost) {
		self.cost = 2000;
	}

	// Player Trigger Sound
	if (!self.oldmodel) {
		self.oldmodel = "sounds/machines/perk_drink.wav";
	}

	// View Model
	if (!self.weapon2model) {
		self.weapon2model = "models/machines/v_perk.mdl";
	}

	// View Model Start Frame
	if (!self.weapon_animduration) {
		self.weapon_animduration = 0;
	}

	// View Model End Frame
	if (!self.weapon2_animduration) {
		self.weapon2_animduration = 22;
	}

	// Light Effect
	if (!self.spawnflags) {
		self.spawnflags = self.spawnflags | 16;
	}

	// Set up the Perk Entity
	self.solid = SOLID_TRIGGER;
	precache_model(self.model);
	precache_model(self.weapon2model);
	precache_sound(self.oldmodel);
	if (self.aistatus) { precache_sound(self.aistatus); }
	if (self.powerup_vo) { precache_sound(self.powerup_vo); }
	setorigin(self, self.origin);
	setmodel(self, self.model);
	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_double";
	self.touch = touch_perk;
	self.think = setup_perk;
	self.nextthink = time + 0.1;

	// Drink Information
	self.sequence = 4;
	self.style = P_DOUBLE;
};

// Deadshot Daiquiri
void() perk_deadshot =
{
	//
	// Set Default Stats for Compatibility
	//
	
	// Model
	if (!self.model) {
		self.model = "models/machines/deadshot.mdl";
	}

	// Perk Cost
	if (!self.cost) {
		self.cost = 1500;
		self.cost2 = 1000;
	}

	// Player Trigger Sound
	if (!self.oldmodel) {
		self.oldmodel = "sounds/machines/perk_drink.wav";
	}

	// View Model
	if (!self.weapon2model) {
		self.weapon2model = "models/machines/v_perk.mdl";
	}

	// View Model Start Frame
	if (!self.weapon_animduration) {
		self.weapon_animduration = 0;
	}

	// View Model End Frame
	if (!self.weapon2_animduration) {
		self.weapon2_animduration = 22;
	}

	// Light Effect
	if (!self.spawnflags) {
		self.spawnflags = self.spawnflags | 16;
	}

	// Set up the Perk Entity
	self.solid = SOLID_TRIGGER;
	precache_model(self.model);
	precache_model(self.weapon2model);
	precache_sound(self.oldmodel);
	setorigin(self, self.origin);
	if (self.aistatus) { precache_sound(self.aistatus); }
	if (self.powerup_vo) { precache_sound(self.powerup_vo); }
	setmodel(self, self.model);
	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_deadshot";
	self.touch = touch_perk;
	self.think = setup_perk;
	self.nextthink = time + 0.1;

	// Different price on PC, for lack of Aim Assist
	#ifdef PC
	self.cost = self.cost2;
	#endif

	// Drink Information
	self.sequence = 7;
	self.style = P_DEAD;
};
// naievil -- older maps compatability
void() perk_dead = { perk_deadshot();}

// Mule Kick
void() perk_mule =
{
	//
	// Set Default Stats for Compatibility
	//
	
	// Model
	if (!self.model) {
		self.model = "models/machines/mulekick.mdl";
	}

	// Perk Cost
	if (!self.cost) {
		self.cost = 4000;
	}

	// Player Trigger Sound
	if (!self.oldmodel) {
		self.oldmodel = "sounds/machines/perk_drink.wav";
	}

	// View Model
	if (!self.weapon2model) {
		self.weapon2model = "models/machines/v_perk.mdl";
	}

	// View Model Start Frame
	if (!self.weapon_animduration) {
		self.weapon_animduration = 0;
	}

	// View Model End Frame
	if (!self.weapon2_animduration) {
		self.weapon2_animduration = 22;
	}

	// Light Effect
	if (!self.spawnflags) {
		self.spawnflags = self.spawnflags | 4;
	}

	// Set up the Perk Entity
	self.solid = SOLID_TRIGGER;
	precache_model(self.model);
	precache_model(self.weapon2model);
	precache_sound(self.oldmodel);
	if (self.aistatus) { precache_sound(self.aistatus); }
	if (self.powerup_vo) { precache_sound(self.powerup_vo); }
	setorigin(self, self.origin);
	setmodel(self, self.model);
	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_mule";
	self.touch = touch_perk;
	self.think = setup_perk;
	self.nextthink = time + 0.1;

	// Drink Information
	self.sequence = 8;
	self.style = P_MULE;
}

//
// --------------------
// Power Switch
// --------------------
//

void()	turnpower1	=[	1,		turnpower2	] {self.frame = 1;};
void()	turnpower2	=[	2,		turnpower3	] {self.frame = 2;};
void()	turnpower3	=[	3,		turnpower4	] {self.frame = 3;};
void()	turnpower4	=[	4,		SUB_Null	] {self.frame = 4;};

//
// Turn_Lights()
// Activates Perk Light Effects
//
void() Turn_Lights =
{
	local entity tempe = findfloat(world, requirespower, 1);
	while (tempe)
	{
		Turn_PerkLight_On(tempe);
		tempe = findfloat (tempe, requirespower, 1);
	}
} 

//
// touch_power_Switch()
// Power Switch touch function; play Animation and do Power things..
//
void() touch_power_Switch =
{
	if (other.classname != "player" || other.downed)
		return;

	if (isPowerOn == true)
    	return;
	
	local entity tempe;
	local entity old_self;

	useprint (other, 10, 0, 0);
	if (other.button7 && !isPowerOn) {
		turnpower1();
		isPowerOn = true;
		sound(self, CHAN_ITEM, "sounds/machines/power.wav", 1, ATTN_NONE);

		tempe = find (world, classname, "door_nzp");// trigger all paired doors
		while (tempe) {
			local entity starte;

			if (!tempe.targetname) {
				if (!tempe.cost) {
					old_self = self;
					self = tempe;
					starte = self;
					door_go_up ();
					tempe.classname = "door_open";
					tempe = find (tempe, classname, "door_nzp");// trigger all paired doors
					self = old_self;
				}
			}
			if (tempe.targetname) {
				old_self = self;
				self = tempe;
				remove(self);
				self = old_self;
				tempe = find (tempe, classname, "door_nzp");// trigger all paired doors
			}
		}
		Turn_Lights();
	}
}

void() power_switch =
{
	self.solid = SOLID_TRIGGER;
	precache_model ("models/machines/power_switch.mdl");
	precache_sound ("sounds/machines/power.wav");
	setorigin (self, self.origin);
	setmodel (self, "models/machines/power_switch.mdl");
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "power_switch";
	isPowerOn = false;
	self.touch = touch_power_Switch;
}

//
// --------------------
// Mystery Box
// --------------------
//

void() updateBoxGlow
{
	if(self.goaldummy)
	{
		self.goaldummy.frame = self.frame;
	}
};


void()	box_open1		=[	1,	box_open2	] { self.frame = 1;updateBoxGlow(); Light_Orange(self);};
void()	box_open2		=[	2,	box_open3	] { self.frame = 2;updateBoxGlow();};
void()	box_open3		=[	3,	box_open4	] { self.frame = 3;updateBoxGlow();};
void()	box_open4		=[	4,	box_open5	] { self.frame = 4;updateBoxGlow();};
void()	box_open5		=[	5,	box_open6	] { self.frame = 5;updateBoxGlow();};
void()	box_open6		=[	6,	box_open7	] { self.frame = 6;updateBoxGlow();};
void()	box_open7		=[	7,	box_open8	] { self.frame = 7;updateBoxGlow();};
void()	box_open8		=[	8,	SUB_Null	] { self.frame = 8;updateBoxGlow();};

void() resetbox = 
{
	self.frame = 0;
	self.boxstatus = 0;
};


void()	box_close1	=[	9,	box_close2	] { self.frame = 9;updateBoxGlow();sound (self, CHAN_ITEM, "sounds/machines/mbox_close.wav", 1, ATTN_NORM); Light_None(self);};
void()	box_close2	=[	10,	box_close3	] { self.frame = 10;updateBoxGlow();};
void()	box_close3	=[	11,	box_close4	] { self.frame = 11;updateBoxGlow();};
void()	box_close4	=[	12,	resetbox	] { self.frame = 12;updateBoxGlow();};

//
// Getweaponid()
// Returns weapon ID from Mbox ID, as they are slightly different
// because.. reasons..
//
float(float r) Getweaponid =
{	
	switch(r) {
		case 0:
			return W_COLT;
			break;
		case 1:
			return W_KAR;
			break;
		case 2:
			return W_DB;
			break;
		case 3:
			return W_MG;
			break;
		case 4:
			return W_RAY;
			break;
		case 5:
			return W_THOMPSON;
			break;
		case 6:
			return W_M2;
			break;
		case 7:
			return W_PPSH;
			break;
		case 8:
			return W_SAWNOFF;
			break;
		case 9:
			return W_TESLA;
			break;
		case 10:
			return W_M1A1;
			break;
		case 11:
			return W_GEWEHR;
			break;
		case 12:
			return W_FG;
			break;
		case 13:
			return W_BROWNING;
			break;
		case 14:
			return W_KAR_SCOPE;
			break;
		case 15:
			return W_357;
			break;
		case 16:
			return W_STG;
			break;
		case 17:
			return W_PANZER;
			break;
		case 18:
			return W_BK;
			break;
		case 19:
			return W_PTRS;
			break;
		case 20:
			return W_MP40;
			break;
		case 21:
			return W_TRENCH;
			break;
		case 22:
			return W_BAR;
			break;
		case 23:
			return W_M1;
			break;
		case 24:
			return W_TYPE;
			break;
	}

	return r;
}

//
// randomweapon()
// Returns a Weapon if permitted by the map's MBOX data file.
//
float() randomweapon =
{
	local float r;
	r = rint((random() * 24));

	// If this weapon is in our Box Array, we can return it.
	if (BoxWeapons[r] == 1) {
		return r;
	} else { // It's not in the Array, try again until we find one.
		return randomweapon();
	}
};

//
// CheckWeapon(w, user)
// Checks all 3 weapon slots to see if the Player is holding specified
// Weapon, ensures we do not give Duplicates.
//
float CheckWeapon (float w, entity user) =
{
	// Non-PaP Weapons
	if (user.weapon == w || user.secondaryweapon == w || user.thirdweapon == w)
		return 0;
	
	// PaP Weapons
	if (EqualNonPapWeapon(user.weapon) == w || EqualNonPapWeapon(user.secondaryweapon) == w || EqualNonPapWeapon(user.thirdweapon) == w)
		return 0;
	
	// We passed both, this weapon is okay
	return 1;
};

//
// Reset_MBox()
// Resets the Mystery Box to it's inital State.
//
void() Reset_MBox =
{
	entity tempe;
	self.velocity = '0 0 0';
	tempe = self;
	self = self.owner;
	box_close1();
	self = tempe;
	self.owner.owner = world;
	self.owner.boxstatus = 0;
	remove (self);
}

//
// Float_Decreate()
// Make the Gun in the Box slowly descend, eventually
// resetting the Box.
//
void() Float_Decrease =
{
	makevectors(self.angles);
	self.velocity = v_up*-5;
	self.nextthink = time + 7;
	self.think = Reset_MBox;
}

//
// findboxspot()
// Locate a new MBox spot and turn this spot into
// a tp_spot.
//
void() findboxspot =
{	
	local entity newspot;
	local float box = rint(random(boxCount));
	newspot = boxLocations[box];

	// Ensure the spot we choose is valid.
	while(newspot == world || newspot == self.owner) {
		box = rint(random(boxCount));
		newspot = boxLocations[box];
	}

	// Make our current spot a tp_spot
	self.owner.model = "progs/Misc/teddy.mdl";
	self.owner.frame = 1;
	setmodel(self.owner, self.owner.model);
	self.owner.classname = "mystery_box_tp_spot";
	self.owner.touch = SUB_Null;
	self.owner.angles_y -= 90;
	Light_None(self.owner);
	
	newspot.angles_y += 90;

	// Spawn the Box Glow if permitted
	#ifndef PC
	if (!(self.owner.spawnflags & 2))
	{
		local entity g;
		g = spawn();
		newspot.goaldummy = g;
		setmodel(g,"models/machines/mglow$.mdl");
		setorigin(g,newspot.origin);
		g.angles = newspot.angles;
	}
	#endif
	
	// Remove teddy
	remove(self);
	
	// Set some values and change the found Spot to an MBox
	newspot.spins = 0;
	newspot.boxstatus = 0;
	newspot.touch = mystery_touch;
	newspot.solid=SOLID_TRIGGER;
	newspot.classname = "mystery";
	setorigin(newspot, newspot.origin);
	setmodel (newspot, "models/machines/mystery.mdl");
	newspot.frame = 0;
	setsize (newspot, VEC_HULL2_MIN, VEC_HULL2_MAX);
}

void() remove_box =
{
	//setmodel(self.owner.goaldummy, "");
	self.owner.frame = 0;	// set box frame
	makevectors(self.angles);
	self.velocity = v_up*100;
	self.think = findboxspot;
	self.nextthink = time + 2;
}

void() Float_Change =
{
	entity tpspot;
	float r, tempf, teddygen;
	string temps;

	tempf = randomweapon();
	r = Getweaponid(tempf);
	while (!CheckWeapon (r, self.owner.owner))
	{
		tempf = randomweapon();
		r = Getweaponid(tempf);
	}
	temps = GetWeaponModel(r, 1);
	setmodel (self, temps);

	self.boxstatus = self.boxstatus + 0.01;
	if (self.wait <= time)
	{
		tpspot = find(world, classname, "mystery_box_tp_spot");
		if (tpspot && self.owner.spins > 3) {
				teddygen = random();
		} else {
			teddygen = 0;
			//bprint(PRINT_HIGH, "no spots\n");
		}
				
		self.velocity = '0 0 0';
		
		if (!teddygen || teddygen < 0.7) {		//teddy gen threshold, high means less chance
			self.owner.boxstatus = 2;
			self.weapon = r;
			self.nextthink = time + 5;
			self.think = Float_Decrease;
			return;
		}
		else {
			addmoney(self.owner.owner, 950, 0);
			self.model = "progs/Misc/teddy.mdl";
			setmodel(self, self.model);
			self.angles_y = self.angles_y - 90;
			self.nextthink = time + 5;
			self.think = remove_box;
			sound (self, CHAN_ITEM, "sounds/pu/byebye.wav", 1, ATTN_NORM);	//naievil FIXME -- change sound
			ach_tracker_luck++;

			if (ach_tracker_luck >= 10)
				GiveAchievement(11);
			return;
		}
	}
	if (self.ltime <= time)
	{
		self.velocity_z = self.velocity_z*0.5;
		self.ltime = 0.5;
	}
	self.nextthink = time + self.boxstatus;
	self.think = Float_Change;
}

void() Create_Floating_Weapon =
{
	entity gun;
	float r, tempf;
	string temps;

	tempf = randomweapon();
	r = Getweaponid(tempf);
	while (!CheckWeapon (r, self.owner.owner))
	{
		tempf = randomweapon();
		r = Getweaponid(tempf);
	}
	temps = GetWeaponModel(r, 1);
		
	gun = spawn();
	
	setorigin (gun, self.origin);
	setmodel (gun, temps);
	setsize (gun, '0 0 0', '0 0 0');
	gun.angles = self.angles;
	gun.effects = EF_FULLBRIGHT;
	
	gun.movetype = MOVETYPE_NOCLIP;
	gun.solid = SOLID_NOT;
	makevectors(self.angles);
	gun.velocity = v_up*15;
	
	gun.owner = self;
	self.boxweapon = gun;
	
	gun.ltime = time+2;
	gun.boxstatus = 0.01;
	gun.wait = time + 5;
	gun.nextthink = time + 0.01;
	gun.think = Float_Change;
}

void() mystery_box_tp_spot = 
{
	entity mbox;
	mbox = find(world, classname, "mystery");
	if (!mbox)	
		remove(self);		// if we don't have a mystery box why do we have a teleport spot
		
	precache_model ("progs/Misc/teddy.mdl"); 
	
	self.solid=SOLID_TRIGGER;
	self.classname = "mystery_box_tp_spot";
	setorigin(self, self.origin);
	setmodel (self, "progs/Misc/teddy.mdl");
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	
	if (self.model == "progs/Misc/teddy.mdl") {
		self.frame = 1;
		self.angles_y -= 90;
	}
	
	boxLocations[boxCount] = self;
	boxCount++;
};

void() mystery_touch =
{
	entity tempe;
	float startframe, endframe;
	string modelname;
	
	if (other.classname != "player" || other.downed)
		return;
		
	if (!self.boxstatus) {
		useprint (other, 6, 950, 0);
	}
	if (self.boxstatus == 2 && self.owner == other) {
		useprint (other, 7, 0, 0);
	}
	
	if (other.button7 && !other.semiuse)
	{
		if (!self.boxstatus)
		{
			if (other.points >= 950)
			{					
				sound (self, CHAN_ITEM, "sounds/machines/mbox_open.wav", 1, ATTN_NORM);
				addmoney(other, -950, FALSE);
				self.boxstatus = 1;
				self.owner = other;
				box_open1 ();
				Create_Floating_Weapon();
				self.spins++;
			}
			else {
        		centerprint (other, "Not enough points\n");
			}
		}
		if (self.boxstatus == 2)
		{
			other.semiuse = 1;
			if (self.owner == other)
			{
				other.reload_delay = 0;
				self.boxstatus = 0;
				self.owner = world;
				if (other.weapon != self.boxweapon.weapon && other.secondaryweapon != self.boxweapon.weapon && other.secondaryweapon && other.thirdweapon != self.boxweapon.weapon)
				{	
					if ((other.perks & P_MULE) && !other.thirdweapon) {
						// store secondary weapon
						local float tempf = other.secondaryweapon;
						local float tempf1 = other.secondarymag;
						local float tempf2 = other.secondaryammo;
						local float tempf3 = other.secondarymag2;
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

					// give boxweapon
					other.weapon = self.boxweapon.weapon;
          			other.currentammo = getWeaponAmmo(self.boxweapon.weapon);
					other.currentmag = getWeaponMag(self.boxweapon.weapon);
					other.weaponskin = 0;

					if (other.weapon != W_KAR_SCOPE && other.weapon != W_HEADCRACKER && !IsDualWeapon(other.weapon)) {
						other.weapon2model = "";
					}
					
					#ifndef PC
					other.Flash_Offset = GetWeaponFlash_Offset(self.boxweapon.weapon);
					other.Flash_Size = GetWeaponFlash_Size(self.boxweapon.weapon);
					other.Weapon_Name = GetWeaponName(self.boxweapon.weapon);
					#endif
				}
				else if (other.weapon == self.boxweapon.weapon)
				{
					other.currentammo = getWeaponAmmo(self.boxweapon.weapon);
					other.currentmag = getWeaponMag(self.boxweapon.weapon);
				}
				else if (other.secondaryweapon == self.boxweapon.weapon)
				{
					other.secondaryammo = getWeaponAmmo(self.boxweapon.weapon);
					other.secondarymag = getWeaponMag(self.boxweapon.weapon);
				}
				else if (other.thirdweapon == self.boxweapon.weapon)
				{
					other.thirdammo = getWeaponAmmo(self.boxweapon.weapon);
					other.thirdmag = getWeaponMag(self.boxweapon.weapon);
				}
				else if (!other.secondaryweapon)
				{
					WeaponSwitch(other);
					other.weapon = self.boxweapon.weapon;
					other.currentammo = getWeaponAmmo(self.boxweapon.weapon);
					other.currentmag = getWeaponMag(self.boxweapon.weapon);
					other.weaponskin = GetWepSkin(self.boxweapon.weapon);
					#ifndef PC
					other.Flash_Offset = GetWeaponFlash_Offset(self.boxweapon.weapon);
					other.Flash_Size = GetWeaponFlash_Size(self.boxweapon.weapon);
					other.Weapon_Name = GetWeaponName(self.boxweapon.weapon);
					#endif
				}
				else if (!other.thirdweapon && (other.perks & P_MULE))
				{
					
				}
				sound(self, 0,"sounds/misc/ching.wav", 1, 1);
				tempe = self;
				self = other;
				startframe = GetFrame(self.weapon,TAKE_OUT_START);
				endframe = GetFrame(self.weapon,TAKE_OUT_END);
				modelname = GetWeaponModel(self.weapon, 0);
				Set_W_Frame (startframe, endframe, 0, 0, 0, SUB_Null, modelname, false, S_BOTH);//FIXME
				SwitchWeapon(self.weapon);
				self = tempe;
				remove (self.boxweapon);
				box_close1();
			}
		}
	}
}


//
// Load_Mbox_Data()
// Opens the map's MBOX Data File and adds parsed data
// into the Box's weapon Array.
// ----------
// TODO: Possibly investigate making this a little better and more modular
// so adding MBOX Weapons can be easier?
//
void() Load_Mbox_Data =
{
	local float file;
	local string h;
	local int weapons_all_disabled = 1;

	// Attempt to Open the File
	h = strcat(mapname, ".mbox");
	h = strcat("maps/",  h);
	file = fopen (h, FILE_READ);

	// There was no MBOX Data, enable all Weapons!
	// R.I.P. PSP Memory 90% of the time in this case..
	if (file == -1) {
		for (float i = 0; i < 25; i++) {
			BoxWeapons[i] = 1;
		}
	} else {
		// Parse each Line and write the Data into our Array.
		for (float i = 0; i < 25; i++) {
			h = strtrim((fgets(file)));
			BoxWeapons[i] = stof(h);
			
			if (stof(h) == 1)
				weapons_all_disabled = 0;

			// Precache Weapon Data if enabled
			if (BoxWeapons[i]) {
				precache_model(GetWeaponModel(Getweaponid(i), 0));
				precache_model(GetWeaponModel(Getweaponid(i), 1));
				precache_extra(Getweaponid(i));
			}	
		}
	}
	
	if (weapons_all_disabled) {
		for (float i = 0; i < 25; i++) {
			BoxWeapons[i] = 1;
		}
	}
}

void() mystery_box =
{
	Load_Mbox_Data();

	precache_model ("models/machines/mystery.mdl");
	precache_model ("models/machines/mglow$.mdl");
	precache_model ("progs/Misc/teddy.mdl"); 
	precache_sound ("sounds/machines/mbox_open.wav"); 
	precache_sound ("sounds/machines/mbox_close.wav"); 
	
	self.solid = SOLID_TRIGGER;
	self.classname = "mystery";
	setorigin(self, self.origin);
	setmodel (self, "models/machines/mystery.mdl");
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	
	#ifndef PC
	if (!(self.spawnflags & 2))
	{
		local entity g;
		g = spawn();
		self.goaldummy = g;
		setmodel(g,"models/machines/mglow$.mdl");
		setorigin(g,self.origin);
		g.angles = self.angles;
	}
	#endif

	self.touch = mystery_touch;
	boxOrigin = self.origin;

	boxLocations[boxCount] = self;
	boxCount++;
}

//
// --------------------
// Pack-a-Punch
// --------------------
//

void removeinpap() {
	//remove(self);
};

//Self = floating gun
void velocity_reduce_output() {
    makevectors(self.owner.angles);
	self.velocity = [0,0,0];
	setorigin(self, self.owner.origin + v_forward*25);

    //start floating back into pap
    self.velocity = v_forward*-1.5;
}

//Self = floating gun
void velocity_reduce_output_in() {
	self.velocity = [0,0,0];
	setorigin(self, self.owner.origin);
}

void() reset_pap =
{
	self.weapon = 0;
	self.owner = 0;


	if (self.goaldummy) {
		remove(self.goaldummy);
		self.goaldummy = 0;
	}


	self.papState = 0;
}

//Self = pap
void PapSendOut() {
    makevectors(self.angles);
	setorigin(self.goaldummy, self.origin);
    self.goaldummy.velocity = v_forward*25;
    
    self.goaldummy.think = velocity_reduce_output;
    self.goaldummy.nextthink = time + 1;

	self.papState = 2;
	self.nextthink = time + 15;
    self.think = reset_pap;
}

void PapUpgrade(entity pap, entity buyer) {
   	entity tempe;
   	string modelname; 

	tempe = self;
	self = buyer;
	addmoney (self, -5000, 0);

	//////////WepModel IN Floating test////////    

	entity floatmodelin;

	modelname = GetWeaponModel(self.weapon, 1);

	floatmodelin = spawn ();


	//model goes in
	makevectors(pap.angles);
	setorigin (floatmodelin, pap.origin + v_forward*25);
	setmodel (floatmodelin, modelname);
	setsize (floatmodelin, '0 0 0', '0 0 0');
	floatmodelin.angles = pap.angles;
	floatmodelin.angles_y = 90 + pap.angles_y;

	floatmodelin.movetype = MOVETYPE_NOCLIP;
	floatmodelin.solid = SOLID_NOT;

	floatmodelin.owner = pap;
    floatmodelin.velocity = v_forward*-25;
    
    floatmodelin.think = velocity_reduce_output_in;
    floatmodelin.nextthink = time + 1;

	//model goes velocity_reduce_output
    pap.owner = self;
	pap.goaldummy = floatmodelin;
    pap.think = PapSendOut;
    pap.nextthink = time + 3.5;


	////////////////////////////////////////

	self.fire_delay = self.reload_delay = 4.0 + time;
	sound(self,CHAN_WEAPON,"sounds/machines/papsound.wav",1,ATTN_NONE);

	pap.weapon = self.weapon;

	self.weapon = self.secondaryweapon;
	self.currentammo = self.secondaryammo;
	self.currentmag = self.secondarymag;
	self.currentmag2 = self.secondarymag2;
	self.secondaryweapon = 0;
	self.secondaryammo = 0;
	self.secondarymag = 0;
	self.secondarymag2 = 0;

    self.isBuying = true;

	Set_W_Frame (0, 39, 0, 0, 0, W_TakeOut, "models/machines/v_pap.mdl", true, S_BOTH);
	self.weapon2model = "";
	UpdateV2model(self.weapon2model, 0);

	#ifndef PC
	self.Weapon_Name = "";
	#endif

	self = tempe;

	self.papState = 1;
	
}

void touch_pap() {
  
	if (other.classname != "player" || other.downed || !isFacing(other, self)) {
		return;
	}
    
	if (self.requirespower == true && !isPowerOn) {
		useprint (other, 8, 0, 0);
		return;
	}
  
	if (!self.papState) {
		if (IsPapWeapon(other.weapon) == 1) {
			return;
		}
		useprint (other, 12, 5000, 5);
		if (other.points >= 5000 && other.button7 && other.weapon)
		{
			PapUpgrade(self, other);
		
		}
		else if (other.button7 && other.weapon) {
			centerprint (other, "Not enough points\n");
		}
	} else if (self.papState == 2) {
		float startframe;
		float endframe;
		string modelname;

		useprint (other, 7, 0, 0);

		if (other.button7) {
			if (!other.secondaryweapon) {
				WeaponSwitch(other);
			}

			other.weapon = EqualPapWeapon(self.weapon);
			other.currentammo = getWeaponAmmo(other.weapon);
			other.currentmag = getWeaponMag(other.weapon);

			if (IsDualWeapon(other.weapon)) {
				other.currentmag2 = other.currentmag;
			}

			entity tempe = self;
			startframe = GetFrame(other.weapon,TAKE_OUT_START);
			endframe = GetFrame(other.weapon,TAKE_OUT_END);
			modelname = GetWeaponModel(other.weapon, 0);
			other.weaponmodel = GetWeaponModel(other.weapon, 0);// Give weapon model
		
			// Kar Scope
			if (other.weapon == W_HEADCRACKER)
				other.weapon2model = "models/weapons/kar/v_karscope.mdl";

			self = other;
			SwitchWeapon(self.weapon);
			UpdateV2model(other.weapon2model, 0);
			Set_W_Frame (startframe, endframe, 0, 0, 0, SUB_Null, modelname, true, S_BOTH);//FIXME

			#ifndef PC
			self.Flash_Offset = GetWeaponFlash_Offset(self.weapon);
			self.Flash_Size = GetWeaponFlash_Size(self.weapon);
			self.Weapon_Name = GetWeaponName(self.weapon);
			self.weaponskin = GetWepSkin(self.weapon);
			#endif

			self = tempe;

			// because PaP broke itself
			self.think = reset_pap;
			self.nextthink = time + 0.1;
		}
	}
}	

void() perk_pap = 
{ 
	entity tempe; 

	tempe = find (world, classname, "power_switch");// trigger all paired doors

	self.solid = SOLID_TRIGGER;

	if (tempe) {
		self.requirespower = true;
	} else {
		self.requirespower = false;
	}

	precache_model ("models/machines/pap.mdl");
	precache_model ("models/machines/v_pap.mdl");
	precache_sound ("sounds/machines/papsound.wav");
	precache_sound ("sounds/machines/papsound.wav");
	setorigin(self, self.origin);
	setmodel (self, "models/machines/pap.mdl");
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_pap";
	self.touch = touch_pap;
}

// Sorta ugly function but whatever
void() perk_random =
{
	float i;
	float foundperk;
	
	// remove perks from our selection if they already exist
	// ugly ugly
	if ((find(world,classname,"perk_revive") && (self.spawnflags & 1))) {
		self.spawnflags -= self.spawnflags & 1;
	}
	if ((find(world,classname,"perk_juggernog") && (self.spawnflags & 2))) {
		self.spawnflags -= self.spawnflags & 2;
	}
	if ((find(world,classname,"perk_speed") && (self.spawnflags & 4))) {
		self.spawnflags -= self.spawnflags & 4;
	}
	if ((find(world,classname,"perk_double") && (self.spawnflags & 8))) {
		self.spawnflags -= self.spawnflags & 8;
	}
	if ((find(world,classname,"perk_flopper") && (self.spawnflags & 16))) {
		self.spawnflags -= self.spawnflags & 16;
	}
	if ((find(world,classname,"perk_staminup") && (self.spawnflags & 32))) {
		self.spawnflags -= self.spawnflags & 32;
	}
	if ((find(world,classname,"perk_deadshot") && (self.spawnflags & 64))) {
		self.spawnflags -= self.spawnflags & 64;
	}
	if ((find(world,classname,"perk_mule") && (self.spawnflags & 128))) {
		self.spawnflags -= self.spawnflags & 128;
	}

	// obj error because there are no possible perks for us to obtain
	if (self.spawnflags == 0) {
		objerror("No available Perks to choose from!");
	}

	foundperk = false;
	while (foundperk == false) {
		i = random();
		// Quick Revive
		if (i < (1/8) && (self.spawnflags & 1)) {
			if !(find(world, classname, "perk_revive")) {
				perk_revive();
				foundperk = true;
			}
		}
		// Jugger-Nog 
		else if (i < (2/8) && (self.spawnflags & 2)) {
			if !(find(world, classname, "perk_juggernog")) {
				perk_juggernog();
				foundperk = true;
			}
		}
		// Speed Cola
		else if (i < (3/8) && (self.spawnflags & 4)) {
			if !(find(world, classname, "perk_speed")) {
				perk_speed();
				foundperk = true;
			}
		}
		// Double Tap
		else if (i < (4/8) && (self.spawnflags & 8)) {
			if !(find(world, classname, "perk_double")) {
				perk_double();
				foundperk = true;
			}
		}
		// PhD Flopper
		else if (i < (5/8) && (self.spawnflags & 16)) {
			if !(find(world, classname, "perk_flopper")) {
				perk_flopper();
				foundperk = true;
			}
		}
		// Stamin-Up
		else if (i < (6/8) && (self.spawnflags & 32)) {
			if !(find(world, classname, "perk_staminup")) {
				perk_staminup();
				foundperk = true;
			}
		}
		// Deadshot Daiquiri
		else if (i < (7/8) && (self.spawnflags & 64)) {
			if (!find(world, classname, "perk_deadshot")) {
				perk_deadshot();
				foundperk = true;
			}
		}
		// Mule Kick
		else if (i < 1 && (self.spawnflags & 128)) {
			if (!find(world, classname, "perk_mule")) {
				perk_mule();
				foundperk = true;
			}
		}
	}
}

void() item_revive =
{
	perk_revive();
	self.origin_z += 8;
}

void() item_juggernog =
{
	perk_juggernog();
	self.origin_z += 8;
}

void() item_speed =
{
	perk_speed();
	self.origin_z += 8;
}

void() item_douple =
{
	perk_double();
	self.origin_z += 8;
}

void() item_flopper =
{
	perk_flopper();
	self.origin_z += 8;
}
