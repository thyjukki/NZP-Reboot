void() Do_Zombie_A = {};
void() func_door_nzp;
void() mystery_box;

entity windows[32];
float wincnt;

void () CL_SendWeaponFire =
{
	float return_time;
	vector Wep_Recoil;
	
	Wep_Recoil = GetWeaponRecoil(self.weapon);

	msg_entity = self;
	WriteByte(MSG_ONE, SVC_WEAPONFIRE);
	return_time = getWeaponRecoilReturn(self.weapon);
	WriteLong(MSG_ONE, return_time);
	WriteCoord (MSG_ONE, Wep_Recoil_x);
	WriteCoord (MSG_ONE, Wep_Recoil_y);
	WriteCoord (MSG_ONE, Wep_Recoil_z);
	//self.punchangle = Wep_Recoil;
	self.recoil_delay = 60/return_time + time;
}

void() trigger_activator = {};

void() ParseClientCommand = {SV_ParseClientCommand(CMD_STRING);}

void() PutClientInServer;
void() InitRounds;

//moto -- put this here because it keeps soft_restart somewhat clean..
void(entity door) reclose_door = {
	entity  oldself;
	oldself = self;

	self = door;
	setmodel(self, self.oldmodel);
	self.solid = SOLID_BSP;
	setorigin(self, self.oldorigin);
	self.isopen = 0;
	func_door_nzp();

	//Close_Waypoint(self.wayTarget);

	self = oldself;
}

void() Soft_Restart = {
	entity who, oldself, doors, box, revive, endgame;
	self = find(world,classname,"player");
	oldself = self;
	
	//remove all zombies
	who = find(world,classname,"ai_zombie");
	while(who != world)
	{
		if(who.health)
		{
			self = who;
			self.th_die();

			// hide bodies
			setmodel(self, "");
			if (self.head)
				setmodel(self.head, "");
			if (self.larm)
				setmodel(self.larm, "");
			if (self.rarm)
				setmodel(self.rarm, "");

			self = oldself;
		}
		
		who = find(who,classname,"ai_zombie");
	}

	//repair all windows
	for(float i = 0; i < wincnt; i++) {
		if (windows[i].health != -10) {
			windows[i].health = 6;
			windows[i].frame = 0;
		}
	}

	//close doors
	doors = findfloat(world, isopen, 1);
	while (doors) {
		if (doors.isopen)
			reclose_door(doors);
		doors = findfloat(world, isopen, 1);
	}

	//revert mystery box
	box = find(world, classname, "mystery");
	if (box) {
		box.boxstatus = 0;
		box.frame = 0;
		box.goaldummy.frame = 0;
		boxCount = 0;
		box.origin = boxOrigin;
		//self = box;

		if (box.boxweapon)
			remove(box.boxweapon);

		//mystery_box();
		//self = oldself;
	}

	//reset quick revive
	revive = find(world, classname, "perk_revive");
	if (revive) {
		setmodel(revive, revive.model);
		oldself.revivesoda = 0;
	}

	//reset buyable ending
	endgame = find(world, classname, "func_ending");
	if (endgame) {
		endgame.activated = false;
	}

	//reset teleporters
	local entity tp;
	tp = find(world, classname, "func_teleporter_entrance");

	if (tp) {
		tp.activated = false;
		tp.isLinked = false;
		tp.cooldown = false;
		tp.waitLink = false;
		tp.think = SUB_Null;
	}

	local entity power;
	power = find(world, classname, "power_switch");
	if(power) {
		isPowerOn = false;
		power.frame = 0;
	}



	self = oldself;
	self.downed = 0;
	game_over = false;
	rounds = 0;
	self.score = 0;
	self.points = 0;
	self.secondaryweapon = 0;
	InitRounds();
	self.isspec = false;
	PutClientInServer();
}