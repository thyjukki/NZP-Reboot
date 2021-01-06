/*

Doors are similar to buttons, but can spawn a fat trigger field around them
to open without a touch, and they link together to form simultanious
double/quad doors.
 
Door.owner is the master door.  If there is only one door, it points to itself.
If multiple doors, all will point to a single one.

Door.enemy chains from the master door through all doors linked in the chain.

*/
/*
code for show that you need money EDITASAP
*/
float DOOR_START_OPEN = 1;
float DOOR_DONT_LINK = 4;
float DOOR_DEBRIS = 8;
float DOOR_SILVER_KEY = 16;
float DOOR_TOGGLE = 32;
float DOOR_POWER = 64;

entity activator;
.float delay;
.string killtarget;
.void() think1;
.vector finaldest;
.float dmg;
.entity trigger_field;
.float wait;
.float speed;
.vector pos1;
.vector pos2;
string string_null;
.float cost;
.float attack_delay;
.float lip;

void() print_need_power =
{
	if(other.classname == "player" && !other.downed)
	{
		/*if (self.owner.message)
			centerprint(other, self.owner.message);
		else
			centerprint(other, "Power must be activated first");*/
		
		useprint (other, 8, 0, 0);
	}

};
/*
=============================================================================

THINK FUNCTIONS

=============================================================================
*/

void() door_go_down;
void() door_go_up;

void() door_blocked =
{
			DamageHandler (other, self, self.dmg, S_NORMAL); 
	
// if a door has a negative wait, it would never come back if blocked,
// so let it just squash the object to death real fast
	if (self.wait >= 0)
	{
		if (self.state == STATE_DOWN)
			door_go_up ();
		else
			door_go_down ();
	}
};


void() door_hit_top =
{
	self.state = STATE_TOP;
	if ((self.classname == "door_nzp_cost" || self.classname == "door_nzp" || self.classname == "door_open"))
	{
		//remove (self.owner.trigger_field); //moto - what does this do lol
		if (!(self.spawnflags & 128))
			setmodel(self, "");

		self.isopen = 1;
		return;//so we dont have to reopen doors
	}
	if (self.spawnflags & DOOR_TOGGLE)
		return;		// don't come down automatically
	self.think = door_go_down;
	self.nextthink = self.ltime + self.wait;
};

void() door_hit_bottom =
{
	self.state = STATE_BOTTOM;
};

void() door_go_down =
{
	if ((self.classname == "door_nzp_cost" || self.classname == "door_nzp" || self.classname == "door_open"))
	{
		if (!(self.spawnflags & 128))
			setmodel(self, "");
		self.isopen = 1;
		return;//so we dont have to reopen doors
	}
	if (self.max_health)
	{
		self.takedamage = DAMAGE_YES;
		self.health = self.max_health;
	}
	
	self.state = STATE_DOWN;

	if (self.spawnflags & 256)
		SUB_CalcAngleMove(self.pos1, self.speed, door_hit_bottom);
	else
		SUB_CalcMove (self.pos1, self.speed, door_hit_bottom);
};

void() door_go_up =
{
	if (self.state == STATE_UP)
		return;		// allready going up

	if (self.state == STATE_TOP)
	{	// reset top wait time
		self.nextthink = self.ltime + self.wait;
		return;
	}
	
	self.state = STATE_UP;

	if (self.spawnflags & 256)
		SUB_CalcAngleMove(self.pos2, self.speed, door_hit_top);
	else
		SUB_CalcMove (self.pos2, self.speed, door_hit_top);
	
	#ifndef PC
	Open_Waypoint(self.wayTarget);
	#endif
	SUB_UseTargets();
};


/*
=============================================================================

ACTIVATION FUNCTIONS

=============================================================================
*/

void() door_fire =
{
	local entity 	oself;
	local entity	starte;

	if (isPowerOn == FALSE)
	{
		if (self.spawnflags & DOOR_POWER )
		{
			if(other.classname == "player" && !other.downed)
			{
				/*if (self.message)
					centerprint(other, self.message);
				else
					centerprint(other, "Power must be activated first");*/
				useprint (other, 8, 0, 0);
				return;
			}
		}
	}
	self.message = string_null;		// no more message
	oself = self;

	if (self.door_model_target)
	{
		entity tempe = find(world, classname, "func_door_model");
		if (tempe != world) {
			///door_model_name, self.door_model_target
			if (tempe.door_model_name == self.door_model_target) {
				setmodel(tempe, "");
				remove(tempe);
			} else {
				bprint(PRINT_HIGH, "Could not find door_model_name: ");
				bprint(PRINT_HIGH, self.door_model_target);
				bprint(PRINT_HIGH, "\n");
			}
		}
	}

	if (self.spawnflags & DOOR_TOGGLE)
	{
		if (self.state == STATE_UP || self.state == STATE_TOP)
		{
			starte = self;
			do
			{
				door_go_down ();
				self = self.enemy;
			} while ( (self != starte) && (self != world) );
			self = oself;
			return;
		}
	}
	
// trigger all paired doors
	starte = self;
	do
	{
		door_go_up ();
		//self.isopen = true;
		self = self.enemy;
	} while ( (self != starte) && (self != world) );
	self = oself;
	
	SUB_UseTargets();
};

void() cost_door =
{
if (self.state == STATE_TOP || self.state == STATE_UP)
	return;

	if (isPowerOn == FALSE)
	{
		if (self.spawnflags & DOOR_POWER )
		{
			if(other.classname == "player" && !other.downed)
			{
				/*if (self.message)
					centerprint(other, self.message);
				else
					centerprint(other, "Power must be activated first");*/
				useprint (other, 8, 0, 0);
				return;
			}
		}
	}

	if (other.button7)
	{
		if (other.points >= self.cost)
		{
			door_fire();
			sound(self, 0,"sounds/misc/ching.wav", 1, 1);
			sound(self, CHAN_ITEM,"sounds/misc/buy.wav", 1, 1);
			switch(self.sounds)
			{
				case 1:
					sound(self, CHAN_ITEM,"sounds/misc/wood_door.wav", 1, 1);
					break;
				case 2:
					sound(self, CHAN_ITEM,"sounds/misc/debris.wav", 1, 1);
					break;
				default:
					break;
			}
			addmoney(other, self.cost*-1, 0);
			self.solid = SOLID_NOT;
			//centerprint (other, "");
			//useprint (other, 0, 0, 0);
			//other.total_bought = other.total_bought + 1;
		}
		else
		{
			if(other.classname == "player" && !other.downed)
			{
				centerprint (other, "You do not have enough points\n");
				other.semiuse = 1;
			}
		}
	}
	else if (!other.button7)
	{
		if(other.classname == "player" && !other.downed)
		{
			/*if (!self.message)
				centerprint3(other, "press use to open door for ", b = ftos (self.cost), " points\n");
			else
				centerprint (other, self.message);*/
			if (self.spawnflags & DOOR_DEBRIS)
				useprint (other, 2, self.cost, 0);
			else
				useprint (other, 1, self.cost, 0);
			return;
		}
	}	
};
void() door_use =
{
	local entity oself;

	oself = self;
	self = self.owner;
	if (self.cost)
		cost_door();
	else
		door_fire ();
	self = oself;
};


void() door_trigger_touch =
{
	if(other.classname != "player")
	{
		return;
	}

	if(cvar("waypoint_mode"))
	{
		if(other.active_door != self.owner)
		{
			bprint(PRINT_HIGH, "Current Door for special waypoints set to ");
			bprint(PRINT_HIGH, self.owner.wayTarget);
			bprint(PRINT_HIGH, "\n");                                          
			other.active_door = self.owner;
		}
		return;
	}
	
	if (other.health <= 20)
		return;

	activator = other;

	self = self.owner;
	door_use ();
};


void() door_killed =
{
	local entity oself;
	
	oself = self;
	self = self.owner;
	self.health = self.max_health;
	self.takedamage = DAMAGE_NO;	// will be reset upon return
	door_use ();
	self = oself;
};


/*
================
door_touch

Prints messages and opens key doors
================
*/
void() door_touch =
{
	if (other.classname != "player")
		return;
	if (other.button7)
	{
		return;
	}
	if (self.owner.message != "")
	{
		centerprint (other, self.owner.message);
	}

	if (isPowerOn == FALSE)
	{
		if (self.owner.spawnflags & DOOR_POWER)
		{
			self.touch = print_need_power;
			return;
		}
	}
	self.touch = SUB_Null;
	if (self.enemy)
		self.enemy.touch = SUB_Null;	// get paired door
	door_use ();
};

/*
=============================================================================

SPAWNING FUNCTIONS

=============================================================================
*/


entity(vector fmins, vector fmaxs) spawn_field =
{
	local entity	trigger;
	local	vector	t1, t2;

	trigger = spawn();
	trigger.movetype = MOVETYPE_NONE;
	trigger.solid = SOLID_TRIGGER;
	trigger.owner = self;
	trigger.touch = door_trigger_touch;
	setorigin(trigger, self.origin);

	t1 = fmins;
	t2 = fmaxs;
	setsize (trigger, t1/* - '15 15 8'*/, t2/* + '15 15 8'*/);
	return (trigger);
};


float (entity e1, entity e2) EntitiesTouching =
{
	if (e1.mins_x > e2.maxs_x)
		return FALSE;
	if (e1.mins_y > e2.maxs_y)
		return FALSE;
	if (e1.mins_z > e2.maxs_z)
		return FALSE;
	if (e1.maxs_x < e2.mins_x)
		return FALSE;
	if (e1.maxs_y < e2.mins_y)
		return FALSE;
	if (e1.maxs_z < e2.mins_z)
		return FALSE;
	return TRUE;
};

/*
=============
LinkDoors


=============
*/
void() LinkDoors =
{
	local entity	t, starte;
	local vector	cmins, cmaxs;

	if (self.enemy)
		return;		// already linked by another door
	if (self.spawnflags & 4)
	{
		self.owner = self.enemy = self;
		return;		// don't want to link this door
	}

	cmins = self.mins;
	cmaxs = self.maxs;
	
	starte = self;
	t = self;
	
	do
	{
		self.owner = starte;			// master door

		if (self.health)
			starte.health = self.health;
		if (self.targetname)
			starte.targetname = self.targetname;
		if (self.message != "")
			starte.message = self.message;

		t = find (t, classname, self.classname);	
		if (!t)
		{
			self.enemy = starte;		// make the chain a loop

		// shootable, fired, or key doors just needed the owner/enemy links,
		// they don't spawn a field
	
			self = self.owner;

			if (self.health)
				return;
			if (self.targetname)
				return;

			self.owner.trigger_field = spawn_field(cmins, cmaxs);

			return;
		}

		if (EntitiesTouching(self,t))
		{
			if (t.enemy)
				objerror ("cross connected doors");
			
			self.enemy = t;
			self = t;

			if (t.mins_x < cmins_x)
				cmins_x = t.mins_x;
			if (t.mins_y < cmins_y)
				cmins_y = t.mins_y;
			if (t.mins_z < cmins_z)
				cmins_z = t.mins_z;
			if (t.maxs_x > cmaxs_x)
				cmaxs_x = t.maxs_x;
			if (t.maxs_y > cmaxs_y)
				cmaxs_y = t.maxs_y;
			if (t.maxs_z > cmaxs_z)
				cmaxs_z = t.maxs_z;
		}
	} while (1 );
};

/*
=====================
SPECIAL DOORS
thease doors can be opened by money or when power is on
=====================
*/

void() func_door_model = 
{
	place_model();
}

void() func_door =

{

	SetMovedir ();

	self.max_health = self.health;
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	setorigin (self, self.origin);	
	setmodel (self, self.model);
	self.classname = "door";

	self.blocked = door_blocked;
	self.use = door_use;
	

	
	if (!self.speed)
		self.speed = 100;
	if (!self.wait)
		self.wait = 3;
	if (!self.lip)
		self.lip = 8;
	if (!self.dmg)
		self.dmg = 2;

	self.pos1 = self.origin;
	self.pos2 = self.pos1 + self.movedir*(fabs(self.movedir*self.size) - self.lip);

// DOOR_START_OPEN is to allow an entity to be lighted in the closed position
// but spawn in the open position
	if (self.spawnflags & DOOR_START_OPEN)
	{
		setorigin (self, self.pos2);
		self.pos2 = self.pos1;
		self.pos1 = self.origin;
	}

	self.state = STATE_BOTTOM;

	if (self.health)
	{
		self.takedamage = DAMAGE_YES;
		self.th_die = door_killed;
	}
		
	self.touch = door_touch;

// LinkDoors can't be done until all of the doors have been spawned, so
// the sizes can be detected properly.
	self.think = LinkDoors;
	self.nextthink = self.ltime + 0.1;
};

void() func_door_nzp =
{
	#ifdef PSP
	if (!self.renderamt)
		self.renderamt = 255;
	
	if (!self.rendermode)
		self.rendermode = 4;
	
	if (!self.rendercolor)
		self.rendercolor = '0 0 0'; 
	
	if (!self.mapversion)
		self.mapversion = 0; 
	
	if (!self.ammo)
		self.ammo = 0; //thease are just here because they can be sp there is no error message. serve no real purpose
	#endif
	 
	// naievil (FIXME) ^^^^ hl rendermodes, mapversion
	makevectors(self.angles);
	SetMovedir ();
	
	self.target2 = self.target;
	self.target3 = self.target;
	self.target4 = self.target;
	self.target5 = self.target;
	self.target6 = self.target;
	self.target7 = self.target;
	self.target8 = self.target;

	self.max_health = self.health;
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	self.oldmodel = self.model;
	self.oldorigin = self.origin;
	self.oldstate = self.state;
	setorigin (self, self.origin);
	setmodel (self, self.model);

	self.blocked = door_blocked;
	self.use = door_use;
	
	if (self.cost)
	{
		self.classname = "door_nzp_cost";
	//	total_buy = total_buy +1;
	}
	else
		self.classname = "door_nzp";
	
	if (!self.speed)
		self.speed = 100;
	if (!self.wait)
		self.wait = 3;
	if (!self.lip)
		self.lip = 8;
	if (!self.dmg)
		self.dmg = 2;

	// only rotate on the Y axis.. potentially change?
	if (self.spawnflags & 256) {
		self.pos1 = self.angles;
		self.pos2 = self.pos1;
		self.pos2_y = self.pos1_y + self.distance;
	} else {
		self.pos1 = self.origin;
		self.pos2 = self.pos1 + self.movedir*(fabs(self.movedir*self.size) - self.lip);
	}

// DOOR_START_OPEN is to allow an entity to be lighted in the closed position
// but spawn in the open position
	if (self.spawnflags & DOOR_START_OPEN)
	{
		setorigin (self, self.pos2);
		self.pos2 = self.pos1;
		self.pos1 = self.origin;
	}

	self.state = STATE_BOTTOM;

	if (self.health)
	{
		self.takedamage = DAMAGE_YES;
		self.th_die = door_killed;
	}
	

	self.touch = door_touch;

// LinkDoors can't be done until all of the doors have been spawned, so
// the sizes can be detected properly.
	self.think = LinkDoors;
	self.nextthink = self.ltime + 0.1;
};