
float backupWepSkin;
float sound_perk_delay; 
void() W_Switch;
void() W_TakeOut;
void() mystery_touch;

void GivePerk(float perk) {
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
		default:
			break;
	}
  	sound_perk_delay = time + 4.5;
	self.isBuying = false;
	string modelname = GetWeaponModel(self.weapon, 0);
	float startframe = GetFrame(self.weapon,TAKE_OUT_START);
	float endframe = GetFrame(self.weapon,TAKE_OUT_END);
	self.weaponskin = backupWepSkin;
	self.perk_delay = self.fire_delay;
	Set_W_Frame (startframe, endframe, 0, 0, 0, SUB_Null, modelname, false, S_BOTH);
	SetPerk(self, self.perks);
}

void() give_revive = { GivePerk(P_REVIVE); }
void() give_juggernog = { GivePerk(P_JUG); }
void() give_doubletap = { GivePerk(P_DOUBLE); }
void() give_speedcola = { GivePerk(P_SPEED); }
void() give_flopper = { GivePerk(P_FLOP); }
void() give_staminup = { GivePerk(P_STAMIN); }
void() give_deadshot = { GivePerk(P_DEAD); }


void DrinkPerk(float perk) {

	void(optional float f) func;

	switch(perk) {
		case P_REVIVE:
			other.weaponskin = 3;	
			func = give_revive;
			break;
		case P_FLOP:
			other.weaponskin = 4;	
			func = give_flopper;
			break;
		case P_JUG:
			other.weaponskin = 2;	
			func = give_juggernog;
			break;
		case P_STAMIN:
			other.weaponskin = 2;	
			func = give_staminup;
			break;
		case P_SPEED:
			other.weaponskin = 1;	
			func = give_speedcola;
			break;
		case P_DOUBLE:
			other.weaponskin = 0;	
			func = give_doubletap;
			break;
		case P_DEAD:
			other.weaponskin = 5;
			func = give_deadshot;
			break;
		default:
			break;
	}
	other.isBuying = true;
	entity tempe = self;
	self = other;
	
	if (self.sprinting)
		W_SprintStop();
	
	self.knife_delay = self.reload_delay2 = self.fire_delay2 = self.fire_delay = self.reload_delay = 4.5 + time;		
	Set_W_Frame (0, 22, 0, 0, PERK, func, "models/machines/v_perk.mdl", true, S_RIGHT);
	self = tempe;
	sound (other, CHAN_ITEM, "sounds/machines/perk_drink.wav", 1, ATTN_NORM);

}

void() touch_perk =
{  
	if (other.classname != "player" || other.downed || other.isBuying == true)
		return;

	if (other.stance == 0 && self.collected == false && G_PRONEPOINTS != 0) {
		self.collected = true;
		addmoney(other, G_PRONEPOINTS, 0);
		sound(self, 0,"sounds/misc/ching.wav", 1, 1);
	}

	if (other.stance == 0)
		return;
	  
	if (self.requirespower == true && !isPowerOn) {
		useprint (other, 8, 0, 0);
		return;
	}

	if (other.weaponskin == 0)
      	backupWepSkin = 0;
    else 
      	backupWepSkin = 1;

	
	if (self.classname == "perk_revive" && !(other.perks & P_REVIVE) && other.fire_delay < time)
	{

		if (!deathmatch && !coop)
		{
			useprint (other, 9, 500, 1);
		}
		else if ((coop || deathmatch))
		{
			useprint (other, 9, 1500, 1);
		}
		if (!deathmatch && !coop && other.points >= 500 && other.button7)
		{

			addmoney (other, -500, 0);
			DrinkPerk(P_REVIVE);

			other.revivesoda++;
			if (other.revivesoda == 3) {
				setmodel(self, ""); //we don't want to remove revive in case of soft_restart..
			}
		}
		else if ((coop || deathmatch) && other.points >= 1500 && other.button7)
		{
			addmoney (other, -1500, 0);
			DrinkPerk(P_REVIVE);
		}
		else if (other.button7)
		{
			centerprint (other, "Not enough points\n");
		}
	}
	if (self.classname == "perk_flopper" && !(other.perks & P_FLOP) && self.fire_delay < time)
	{
		useprint (other, 9, 2000, 6);
		if (other.points >= 2000 && other.button7)
		{
			addmoney (other, -2000, 0);
			DrinkPerk(P_FLOP);
		}
		else if (other.button7)
		{
			centerprint (other, "Not enough points\n");
		}
	}
	if (self.classname == "perk_juggernog" && !(other.perks & P_JUG) && self.fire_delay < time)
	{
		useprint (other, 9, 2500, 2);
		if (other.points >= 2500 && other.button7)
		{
			addmoney (other, -2500, 0);
			DrinkPerk(P_JUG);
		}
		else if (other.button7)
		{
			centerprint (other, "Not enough points\n");
		}
	}
	if (self.classname == "perk_staminup" && !(other.perks & P_STAMIN) && self.fire_delay < time)
	{
		useprint (other, 9, 2000, 5);
		if (other.points >= 2000 && other.button7)
		{
			addmoney (other, -2000, 0);
			DrinkPerk(P_STAMIN);
		}
		else if (other.button7)
		{
			centerprint (other, "Not enough points\n");
		}
	}
	if (self.classname == "perk_speed" && !(other.perks & P_SPEED) && self.fire_delay < time)
	{
		useprint (other, 9, 3000, 3);
		if (other.points >= 3000 && other.button7)
		{
			addmoney (other, -3000, 0);
			DrinkPerk(P_SPEED);
		}
		else if (other.button7)
		{
			centerprint (other, "Not enough points\n");
		}
	}
	if (self.classname == "perk_double" && !(other.perks & P_DOUBLE) && self.fire_delay < time)
	{
		useprint (other, 9, 2000, 4);
		if (other.points >= 2000 && other.button7)
		{
			addmoney (other, -2000, 0);
			DrinkPerk(P_DOUBLE);
		}
		else if (other.button7)
		{
			centerprint (other, "Not enough points\n");
		}
	}
	if (self.classname == "perk_deadshot" && !(other.perks & P_DEAD) && self.fire_delay < time)
	{
		useprint (other, 9, self.cost, 7);
		if (other.points >= self.cost && other.button7)
		{
			addmoney (other, -self.cost, 0);
			DrinkPerk(P_DEAD);
		}
		else if (other.button7)
		{
			centerprint (other, "Not enough points\n");
		}
	}
}

void() setup_perk =
{
	if (find (world, classname, "power_switch"))
	{
		if (self.classname == "perk_revive" && !coop && !deathmatch) {
			self.effects = self.effects | EF_BLUE;
		} else
			self.requirespower = true;
	}
	else
	{
		self.effects = self.effects | EF_FULLBRIGHT;
		switch(self.classname)
		{
			case "perk_revive": 
				self.effects = self.effects |  EF_BLUE;
				break;
			case "perk_juggernog":
				self.effects = self.effects |  EF_RED;
				break;
			case "perk_speed":
				self.effects = self.effects |  EF_GREEN;
				break;
			case "perk_flopper":
				self.effects = self.effects |  EF_PURPLELIGHT;
				break;
			case "perk_staminup":
			case "perk_double":
			case "perk_deadshot":
			#ifndef PC
				self.effects = self.effects |  EF_ORANGELIGHT;
			#else 
				self.effects = self.effects |  EF_ORANGE;
			#endif
				break;
			default: break;
		
		}
	} 
}
void() perk_revive =
{
	self.solid = SOLID_TRIGGER;
	precache_model ("models/machines/quick_revive.mdl");
	precache_model ("models/machines/v_perk.mdl");
	precache_sound ("sounds/machines/perk_drink.wav");
  	precache_sound ("sounds/weapons/papfire.wav");
	setorigin (self, self.origin);
	setmodel (self, "models/machines/quick_revive.mdl");
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_revive";
	self.touch = touch_perk;

	self.think = setup_perk;
	self.nextthink = time + 0.1;
};
void() perk_flopper =
{
	self.solid = SOLID_TRIGGER;
	precache_model ("models/machines/flopper.mdl");
	precache_model ("models/machines/v_perk.mdl");
	precache_sound ("sounds/machines/perk_drink.wav");
	setorigin (self, self.origin);
	setmodel (self, "models/machines/flopper.mdl");
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_flopper";
	self.touch = touch_perk;

	self.think = setup_perk;
	self.nextthink = time + 0.1;
};

void() perk_juggernog =
{
	self.solid = SOLID_TRIGGER;
	precache_model ("models/machines/juggernog.mdl");
	precache_model ("models/machines/v_perk.mdl");
	precache_sound ("sounds/machines/perk_drink.wav");
	setorigin (self, self.origin);
	setmodel (self, "models/machines/juggernog.mdl");
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_juggernog";
	self.touch = touch_perk;

	self.think = setup_perk;
	self.nextthink = time + 0.1;
};

void() perk_staminup =
{
	self.solid = SOLID_TRIGGER;
	precache_model ("models/machines/staminup.mdl");
	precache_model ("models/machines/v_perk.mdl");
	precache_sound ("sounds/machines/perk_drink.wav");
	setorigin (self, self.origin);
	setmodel (self, "models/machines/staminup.mdl");
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_staminup";
	self.touch = touch_perk;

	self.think = setup_perk;
	self.nextthink = time + 0.1;
};

void() perk_speed =
{
	self.solid = SOLID_TRIGGER;
	precache_model ("models/machines/speed_cola.mdl");
	precache_model ("models/machines/v_perk.mdl");
	precache_sound ("sounds/machines/perk_drink.wav");
	setorigin (self, self.origin);
	setmodel (self, "models/machines/speed_cola.mdl");
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_speed";
	self.touch = touch_perk;

	self.think = setup_perk;
	self.nextthink = time + 0.1;
};

void() perk_double =
{
	self.solid = SOLID_TRIGGER;
	precache_model ("models/machines/double_tap.mdl");
	precache_model ("models/machines/v_perk.mdl");
	precache_sound ("sounds/machines/perk_drink.wav");
	setorigin (self, self.origin);
	setmodel (self, "models/machines/double_tap.mdl");
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_double";
	self.touch = touch_perk;

	self.think = setup_perk;
	self.nextthink = time + 0.1;
};

void() perk_deadshot =
{
	self.solid = SOLID_TRIGGER;
	precache_model ("models/machines/deadshot.mdl");
	precache_model ("models/machines/v_perk.mdl");
	precache_sound ("sounds/machines/perk_drink.wav");
	setorigin (self, self.origin);
	setmodel (self, "models/machines/deadshot.mdl");
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_deadshot";
	self.touch = touch_perk;

	self.think = setup_perk;
	self.nextthink = time + 0.1;

	#ifdef PC
	self.cost = 1000;
	#else
	self.cost = 1500;
	#endif
};

void()	turnpower1	=[	1,		turnpower2	] {self.frame = 1;};
void()	turnpower2	=[	2,		turnpower3	] {self.frame = 2;};
void()	turnpower3	=[	3,		turnpower4	] {self.frame = 3;};
void()	turnpower4	=[	4,		SUB_Null	] {self.frame = 4;};

void() Turn_Lights =
{
	entity tempe = findfloat (world, requirespower, 1);// trigger all paired doors
	while (tempe)
	{
		switch(tempe.classname) {
			case "perk_revive": 
				tempe.effects = self.effects |  EF_FULLBRIGHT;
				tempe.effects = self.effects |  EF_BLUE;
				break;
			case "perk_juggernog":
				tempe.effects = self.effects |  EF_FULLBRIGHT;
				tempe.effects = self.effects |  EF_RED;
				break;
			case "perk_speed":
				tempe.effects = self.effects |  EF_FULLBRIGHT;
				tempe.effects = self.effects |  EF_GREEN;
				break;
			case "perk_flopper":
				tempe.effects = self.effects |  EF_FULLBRIGHT;
				tempe.effects = self.effects |  EF_PURPLELIGHT;
				break;
			case "perk_staminup":
			case "perk_double":
			case "perk_deadshot":
			#ifndef PC
				tempe.effects = self.effects |  EF_FULLBRIGHT;
				tempe.effects = self.effects |  EF_ORANGELIGHT;
			#else 
				tempe.effects = self.effects |  EF_ORANGE;
			#endif
				break;
			default: break;
		}
      
		tempe = findfloat (tempe, requirespower, 1);// trigger all paired doors
	}
} 

void() touch_power_Switch =
{
	entity tempe;
	entity old_self;

	if (other.classname != "player" || other.downed)
		return;

	if (isPowerOn == true)
    return;
	useprint (other, 10, 0, 0);
	if (other.button7 && !isPowerOn)
	{
		turnpower1();
		isPowerOn = true;
		sound (self, CHAN_ITEM, "sounds/machines/power.wav", 1, ATTN_NONE);

		tempe = find (world, classname, "door_nzp");// trigger all paired doors
		while (tempe)
		{
			local entity starte;

      if (!tempe.targetname)
      {
        if (!tempe.cost)
        {
          old_self = self;
          self = tempe;
          starte = self;
          door_go_up ();
          tempe.classname = "door_open";
          tempe = find (tempe, classname, "door_nzp");// trigger all paired doors
          self = old_self;
        }
      }
      if (tempe.targetname)
      {
        old_self = self;
        self = tempe;
        remove(self);
        self = old_self;
        tempe = find (tempe, classname, "door_nzp");// trigger all paired doors
       }
		}

		Turn_Lights ();
		
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


void() updateBoxGlow
{
	if(self.goaldummy)
	{
		self.goaldummy.frame = self.frame;
	}
};


void()	box_open1		=[	1,	box_open2	] { self.frame = 1;updateBoxGlow();};
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


void()	box_close1	=[	9,	box_close2	] { self.frame = 9;updateBoxGlow();sound (self, CHAN_ITEM, "sounds/machines/mbox_close.wav", 1, ATTN_NORM);};
void()	box_close2	=[	10,	box_close3	] { self.frame = 10;updateBoxGlow();};
void()	box_close3	=[	11,	box_close4	] { self.frame = 11;updateBoxGlow();};
void()	box_close4	=[	12,	resetbox	] { self.frame = 12;updateBoxGlow();};

float colt, kar, db,bar, mg, ray, thomp, flame, ppsh, sawn, tesla, m1a1, ptrs, panz, stg, mp40, revolver, gewehr, fg, browning, kars, bknife, trench, m1, type100;

float (float r) Getweaponid =
{	

	switch (r) {
	case 1: 
		return W_RAY;
		break;
	case 2:
		return W_COLT;
		break;
	case 3:
		return W_KAR;
		break;
	case 4:
		return W_M1A1;
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
		return W_FG;
		break;
	case 11:
		return W_TRENCH;
		break;
	case 12:
		return W_MG;
		break;
	case 13:
		return W_DB;
		break;
	case 14:
		return W_BAR;
		break;
	case 15:
		return W_GEWEHR;
		break;
	case 16:
		return W_BROWNING;
		break;
	case 17:
		return W_357;
		break;
	case 18:
		return W_TYPE;
		break;
	case 19:
		return W_KAR_SCOPE;
		break;
	case 20:
		return W_PANZER;
		break;
	case 21:
		return W_PTRS;
		break;
	case 22:
		return W_MP40;
		break;
	case 23:
		return W_STG;
		break;
	case 24:
		return W_BK;
		break;
	case 25:
		return W_M1;
		break;
	
	}
	
	return r;
}

// naievil -- wow...just fucking fix this
float() randomweapon = //this function is for making random box weapon system, currently it acts as just random thing
{
	local float r;
	r =rint((random() * 24)) + 1;

	if (r == 1)
	{
		if (ray)
			return 1;
		else
			return randomweapon();
	}
	else if (r == 2)
	{
		if (colt)
			return 2;	
		else
			return randomweapon();
	}
	else if (r == 3)
	{
		if (kar)
			return 3;
		else
			return randomweapon();
	}
	else if (r == 4)
	{
		if (m1a1)
			return 4;
		else
			return randomweapon();
	}
	else if (r == 5)
	{
		if (thomp)
			return 5;
		else
			return randomweapon();
	}
	else if (r == 6)
	{
		if (flame)
			return 6;
		else
			return randomweapon();
	}
	else if (r == 7)
	{
		if (ppsh)
			return 7;
		else
			return randomweapon();
	}
	else if (r == 8)
	{
		if (sawn)
			return 8;
		else
			return randomweapon();
	}
	else if (r == 9)
	{
		if (tesla)
			return 9;
		else
			return randomweapon();
	}
	else if (r == 10)
	{
		if (fg)
			return 10;
		else
			return randomweapon();
	}
	else if (r == 11)
	{
		if (trench)
			return 11;
		else
			return randomweapon();
	}
	else if (r == 12)
	{
		if (mg)
			return 12;
		else
			return randomweapon();
	}
	else if (r == 13)
	{
		if (db)
			return 13;
		else
			return randomweapon();
	}
	else if (r == 14)
	{
		if (bar)
			return 14;
		else
			return randomweapon();
	}
	else if (r == 15)
	{
		if (gewehr)
			return 15;
		else
			return randomweapon();
	}
	else if (r == 16)
	{
		if (browning)
			return 16;
		else
			return randomweapon();
	}
	else if (r == 17)
	{
		if (revolver)
			return 17;
		else
			return randomweapon();
	}
	else if (r == 18)
	{
		if (type100)
			return 18;
		else
			return randomweapon();
	}
	else if (r == 19)
	{
		if (kars)
			return 19;
		else
			return randomweapon();
	}
	else if (r == 20)
	{
		if (panz)
			return 20;
		else
			return randomweapon();
	}
	else if (r == 21)
	{
		if (ptrs)
			return 21;
		else
			return randomweapon();
	}
	else if (r == 22)
	{
		if (mp40)
			return 22;
		else
			return randomweapon();
	}
	else if (r == 23)
	{
		if (stg)
			return 23;
		else
			return randomweapon();
	}
	else if (r == 24)
	{
		if (bknife)
			return 24;
		else
			return randomweapon();
	}
	else if (r == 25)
	{
		if (m1)
			return 25;
		else
			return randomweapon();
	}
	else
		return randomweapon();
	
};

float CheckWeapon (float w, entity user) =
{
	//entity check;
	/*if (w == W_TESLA || w == W_BK || w == W_M2)
	{
		check = find(world, classname, "player");
		while (check)
		{
			if (check.weapon == w || check.weapon2 == w)
				return 0;
			check = find(check, classname, "player");
		}
		return 1;
	}
	else*/
		if (user.weapon == w || user.secondaryweapon == w)
			return 0;
		else if (EqualNonPapWeapon(user.weapon) == w || EqualNonPapWeapon(user.secondaryweapon == w))
      return 0;
		else
			return 1;

	return 1;
};

void() Finalize_box =
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

void() Float_Decrease =
{
	makevectors(self.angles);
	self.velocity = v_up*-5;
	self.nextthink = time + 7;
	self.think = Finalize_box;
}

void() findboxspot =
{	
	entity newspot;
	float box = rint(random(boxCount));

	newspot = boxLocations[box];

	// make sure our spot is valid
	while(newspot == world || newspot == self.owner) {
		box = rint(random(boxCount));
		newspot = boxLocations[box];
	}

	self.owner.model = "progs/Misc/teddy.mdl";
	self.owner.frame = 1;
	setmodel(self.owner, self.owner.model);
	self.owner.classname = "mystery_box_tp_spot";
	self.owner.touch = SUB_Null;
	self.owner.angles_y -= 90;
	
	newspot.angles_y += 90;
	if (!(self.owner.spawnflags & 2))
	{
		local entity g;
		g = spawn();
		newspot.goaldummy = g;
		setmodel(g,"models/machines/mglow$.mdl");
		setorigin(g,newspot.origin);
		g.angles = newspot.angles;
	}
	
	remove(self);      // remove teddy
	
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
	setmodel(self.owner.goaldummy, "");
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

	tempf = randomweapon ();
	r = Getweaponid(tempf);
	while (!CheckWeapon (r, self.owner.owner))
	{
		tempf = randomweapon ();
		r = Getweaponid(tempf);
	}
	temps = GetWeaponModel(r, 1);
	setmodel (self, temps);

	self.boxstatus = self.boxstatus + 0.01;
	if (self.wait <= time)
	{
		tpspot = find(world, classname, "mystery_box_tp_spot");
		if (tpspot && self.owner.spins >= 3) {
				teddygen = /*random()*/1;
			}
			else
				teddygen = 0;
				
		self.velocity = '0 0 0';
		
		if (!teddygen || teddygen < 0.9) {		//teddy gen threshold, high means less chance
			self.owner.boxstatus = 2;
			self.weapon = r;
			self.nextthink = time + 5;
			self.think = Float_Decrease;
			return;
		}
		else {
			self.model = "progs/Misc/teddy.mdl";
			setmodel(self, self.model);
			self.angles_y = self.angles_y - 90;
			self.nextthink = time + 5;
			self.think = remove_box;
			sound (self, CHAN_ITEM, "sounds/music/end.wav", 1, ATTN_NORM);	//naievil FIXME -- change sound
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

	tempf = randomweapon ();
	r = Getweaponid(tempf);
	while (!CheckWeapon (r, self.owner.owner))
	{
		tempf = randomweapon ();
		r = Getweaponid(tempf);
	}
	temps = GetWeaponModel(r, 1);
		
	gun = spawn();
	
	setorigin (gun, self.origin);
	setmodel (gun, temps);
	setsize (gun, '0 0 0', '0 0 0');
	gun.angles = self.angles;
	
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
				if (other.weapon != self.boxweapon.weapon && other.secondaryweapon != self.boxweapon.weapon && other.secondaryweapon)
				{		
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


// naievil -- fucking wow...FIXME and make me not look absolutely fucking awful
// moto -- just saw this comment lol
void() Load_Mbox_Data =
{
    
	local float file;
	local string h;
	string temps;

	h = strcat(mapname, ".mbox");
	h = strcat("maps/",  h);
	file = fopen (h, FILE_READ);
	
	if (file == -1) {
		colt = kar = db =bar = mg = ray = thomp = flame = ppsh = sawn = tesla = m1a1 = ptrs = panz = stg = mp40 = revolver = gewehr = fg = browning = kars = bknife = trench = m1 = type100 = 1;
	} else {

		h = (fgets(file));
		colt = stof(h);
		h = (fgets(file));
		kar = stof(h);
		h = (fgets(file));
		db = stof(h);
		h = (fgets(file));
		mg = stof(h);
		h = (fgets(file));
		ray = stof(h);
		h = (fgets(file));
		thomp = stof(h);
		h = (fgets(file));
		flame = stof(h);
		h = (fgets(file));
		ppsh = stof(h);
		h = (fgets(file));
		sawn = stof(h);
		h = (fgets(file));
		tesla = stof(h);
		h = (fgets(file));
		m1a1 = stof(h);
		h = (fgets(file));
		gewehr = stof(h);
		h = (fgets(file));
		fg = stof(h);
		h = (fgets(file));
		browning = stof(h);
		h = (fgets(file));
		kars = stof(h);
		h = (fgets(file));
		revolver = stof(h);
		h = (fgets(file));
		stg = stof(h);
		h = (fgets(file));
		panz = stof(h);
		h = (fgets(file));
		bknife = stof(h);
		h = (fgets(file));
		ptrs = stof(h);
		h = (fgets(file));
		mp40 = stof(h);
		h = (fgets(file));
		trench = stof(h);
		h = (fgets(file));
		bar = stof(h);
		h = (fgets(file));
		m1 = stof(h);
		h = (fgets(file));
		type100 = stof(h);
		h = (fgets(file));
	}

	if (colt)
	{
		temps = GetWeaponModel(W_COLT, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_COLT, 0);
		precache_model (temps);
		precache_extra(W_COLT);
		precache_extra(W_BIATCH);
	}
	if (kar)
	{
		temps = GetWeaponModel(W_KAR, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_KAR, 0);
		precache_model (temps);
		precache_extra(W_KAR);
	}
	if (db)
	{
		temps = GetWeaponModel(W_DB, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_DB, 0);
		precache_model (temps);
		precache_extra(W_DB);
	}
	if (mg)
	{
		temps = GetWeaponModel(W_MG, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_MG, 0);
		precache_model (temps);
		precache_extra(W_MG);
	}
	if (ray)
	{
		temps = GetWeaponModel(W_RAY, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_RAY, 0);
		precache_model (temps);
		precache_extra(W_RAY);
	}
	if (thomp)
	{
		temps = GetWeaponModel(W_THOMPSON, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_THOMPSON, 0);
		precache_model (temps);
		precache_extra(W_THOMPSON);
	}
	if (flame)
	{
		temps = GetWeaponModel(W_M2, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_M2, 0);
		precache_model (temps);
		precache_extra(W_M2);
	}
	if (ppsh)
	{
		temps = GetWeaponModel(W_PPSH, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_PPSH, 0);
		precache_model (temps);
		precache_extra(W_PPSH);
	}
	if (sawn)
	{
		temps = GetWeaponModel(W_SAWNOFF, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_SAWNOFF, 0);
		precache_model (temps);
		precache_extra(W_SAWNOFF);
	}
	if (tesla)
	{
		temps = GetWeaponModel(W_TESLA, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_TESLA, 0);
		precache_model (temps);
		precache_extra(W_TESLA);
	}
	if (m1a1)
	{
		temps = GetWeaponModel(W_M1A1, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_M1A1, 0);
		precache_model (temps);
		precache_extra(W_M1A1);
	}
	if (gewehr)
	{
		temps = GetWeaponModel(W_GEWEHR, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_GEWEHR, 0);
		precache_model (temps);
		precache_extra(W_GEWEHR);
	}
	if (fg)
	{
		temps = GetWeaponModel(W_FG, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_FG, 0);
		precache_model (temps);
		precache_extra(W_FG);
	}
	if (browning)
	{
		temps = GetWeaponModel(W_BROWNING, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_BROWNING, 0);
		precache_model (temps);
		precache_extra(W_BROWNING);
	}
	if (kars)
	{
		temps = GetWeaponModel(W_KAR_SCOPE, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_KAR_SCOPE, 0);
		precache_model (temps);
		precache_extra(W_KAR_SCOPE);
	}
	if (revolver)
	{
		temps = GetWeaponModel(W_357, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_357, 0);
		precache_model (temps);
		precache_extra(W_357);
	}
	if (stg)
	{
		temps = GetWeaponModel(W_STG, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_STG, 0);
		precache_model (temps);
		precache_extra(W_STG);
	}
	if (panz)
	{
		temps = GetWeaponModel(W_PANZER, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_PANZER, 0);
		precache_model (temps);
		precache_extra(W_PANZER);
	}
	if (bknife)
	{
		temps = GetWeaponModel(W_BK, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_BK, 0);
		precache_model (temps);
		precache_extra(W_BK);
	}
	if (ptrs)
	{
		temps = GetWeaponModel(W_PTRS, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_PTRS, 0);
		precache_model (temps);
		precache_extra(W_PTRS);
	}
	if (mp40)
	{
		temps = GetWeaponModel(W_MP40, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_MP40, 0);
		precache_model (temps);
		precache_extra(W_MP40);
	}
	if (bar)
	{
		temps = GetWeaponModel(W_BAR, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_BAR, 0);
		precache_model (temps);
		precache_extra(W_BAR);
	}
	if (trench)
	{
		temps = GetWeaponModel(W_TRENCH, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_TRENCH, 0);
		precache_model (temps);
		precache_extra(W_TRENCH);
	}
	if (m1)
	{
		temps = GetWeaponModel(W_M1, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_M1, 0);
		precache_model (temps);
		precache_extra(W_M1);
	}
	if (type100)
	{
		temps = GetWeaponModel(W_TYPE, 1);
		precache_model (temps);
		temps = GetWeaponModel(W_TYPE, 0);
		precache_model (temps);
		precache_extra(W_TYPE);
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
	
	self.solid=SOLID_TRIGGER;
	self.classname = "mystery";
	setorigin(self, self.origin);
	setmodel (self, "models/machines/mystery.mdl");
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	
	if (!(self.spawnflags & 2))
	{
		//self.effects = EF_BLUELIGHT;
		local entity g;
		g = spawn();
		self.goaldummy = g;
		setmodel(g,"models/machines/mglow$.mdl");
		setorigin(g,self.origin);
		g.angles = self.angles;
	}

	self.touch = mystery_touch;
	boxOrigin = self.origin;

	boxLocations[boxCount] = self;
	boxCount++;
}

//PACK A PUNCH
void removeinpap() {
	//remove(self);
};

//Self = floating gun
void velocity_reduce_output() {
    makevectors(self.owner.angles);
	self.velocity = [0,0,0];
	setorigin(self, self.owner.origin + v_forward*25);
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

	Set_W_Frame (0, 39, 0, 0, 0, W_TakeOut, "models/machines/v_pap.mdl", true, S_BOTH);

	#ifndef PC
	self.Weapon_Name = "";
	#endif

	self = tempe;

	self.papState = 1;
	
}

void touch_pap() {
  
	if (other.classname != "player" || other.downed) {
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

			self = other;
			SwitchWeapon(self.weapon);
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