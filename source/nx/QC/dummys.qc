// Dummys that should be here
void GiveAchievement(float achievement_id, optional entity who) = {};
void print(string s) = {};

float tracemove(vector start, vector min, vector max, vector end, float nomonsters, entity forent) = {return 0;};

void(vector o, vector d, float color, float count) particle = {};

#define MOVE_HITMODEL 0

void() LoadWaypointData = {};

void() Soft_Restart = {
	/*
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
			remove(self); //so dead bodies don't remain
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
		setmodel(revive, "models/machines/quick_revive.mdl");
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
	*/
}

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
