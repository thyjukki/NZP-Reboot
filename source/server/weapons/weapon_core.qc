void() W_PutOut;
void() GrenadeExplode;

void() ReturnWeaponModel =
{
	self.weaponmodel = GetWeaponModel(self.weapon, 0);

	if (IsDualWeapon(self.weapon)) {
		self.weapon2model = GetLeftWeaponModel(self.weapon);
	} else if (self.weapon == W_KAR_SCOPE || self.weapon == W_HEADCRACKER) {
		self.weapon2model = "models/weapons/kar/v_karscope.mdl";
		UpdateV2model(self.weapon2model, 0);
	}
		
	UpdateVmodel(self.weaponmodel, GetWepSkin(self.weapon));
	UpdateV2model(self.weapon2model, GetWepSkin(self.weapon));
}

.float scopetime;

void() W_AimIn =
{
	if (self.weapon == W_TESLA || self.weapon == W_DG3)
		return;
		
	if (IsDualWeapon(self.weapon) ||
		self.zoom ||
		self.reload_delay > time ||
		self.sprinting ||
		self.new_anim_stop ||
		self.weapon == W_BK) {		
		return;
	}
		
	#ifndef PC
	self.ADS_Offset = GetWeaponADSOfs_PSP(self.weapon);
	#endif
	
	if (self.weapon == W_KAR_SCOPE || self.weapon == W_PTRS ||
	    self.weapon == W_HEADCRACKER || self.weapon == W_PENETRATOR) {
		SetUpdate(self, UT_ZOOM2, 0, 0, 0);
		#ifdef NX
		self.zoom = 1;
		#else
		self.zoom = 2;
		#endif
		self.scopetime = time + 0.3;
	} else {
		self.zoom = 1;
	}
	
	if (!self.downed)	
		playaim();
		
}

void() W_AimOut =
{
	if (!self.zoom ||
		self.new_anim_stop || 
		self.sprinting) {
		return;
	}

	if (self.weapon == W_KAR_SCOPE || self.weapon == W_PTRS ||
	    self.weapon == W_HEADCRACKER || self.weapon == W_PENETRATOR) {
		ReturnWeaponModel();
	}
		
	#ifndef PC
	self.zoom = 0;
	#endif
	
	if (!self.downed)
		playout();
}

void() W_SprintStop =
{
	if (self.sprinting)
	{
		self.sprint_stop_time = time;
		self.sprint_duration = self.sprint_timer;
	}
	
	float startframe = GetFrame(self.weapon,SPRINT_OUT_START);
	float endframe = GetFrame(self.weapon,SPRINT_OUT_END);
	string modelname = GetWeaponModel(self.weapon, 0);
	
	if (self.isBuying || self.damagetimer > time || !self.sprinting)
		return;
	
	//TEMPORARY
	#ifndef PC
	self.zoom = 0;
	#endif

	Set_W_Frame (startframe, endframe, 0, 0, SPRINT, SUB_Null, modelname, false, S_BOTH);  // BUG IS HERE
	
	self.sprinting = 0;
	self.into_sprint = 0;
	self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = 0;
	
	if (self.velocity)
		playwalk();
}


void W_SprintStart () {	
	self.sprint_start_time = time;
	
	if (self.sprint_rest_time > sprint_max_time)
		self.sprint_duration = 0.0;
	else
		self.sprint_duration -= self.sprint_rest_time;

#ifdef NX
	if (!self.sprintflag) {
		return;
	}
#endif
	
	if (self.fire_delay > time ||
		self.fire_delay2 > time ||
		self.new_anim_stop ||
		self.new_anim2_stop ||
		self.isBuying || 
		self.downed ||
		!(self.flags & FL_ONGROUND) || 
		self.sprint_delay > time) {
		return;
	}
		
	float startframe = GetFrame(self.weapon,SPRINT_IN_START);
	float endframe = GetFrame(self.weapon,SPRINT_IN_END);
	string modelname = GetWeaponModel(self.weapon, 0);

	#ifndef PC
	self.zoom = 3;
	#endif
	
	if (startframe || endframe) {
		Set_W_Frame (startframe, endframe, 0, 0, SPRINT, ContinueRun, modelname, false, S_BOTH);
	}

	self.sprint_delay = time + 1;
	self.sprinting = true;
	self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = 0;
}

void() W_Switch =
{
	if (self.secondaryweapon && self.secondaryweapon != 0 && !self.new_anim_stop && !other.button7)
	{      
		float tempf,tempf1,tempf2,tempf3,tempf4;
		float startframe;
		float endframe;
		string modelname;

		// un-zoom camera
		self.zoom = false;

		// fix fire rate exploit
		self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = true;

		// just do normal weapon swapping if we don't have mule..
		if (!(self.perks & P_MULE) || !self.thirdweapon) {
			tempf = self.currentammo;
			self.currentammo = self.secondaryammo;
			self.secondaryammo = tempf;

			tempf1 = self.currentmag;
			self.currentmag = self.secondarymag;
			self.secondarymag = tempf1;

			tempf1 = self.currentmag2;
			self.currentmag2 = self.secondarymag2;
			self.secondarymag2 = tempf1;

			tempf2 = self.weapon;
			self.weapon = self.secondaryweapon;
			self.secondaryweapon = tempf2;

			tempf3 = self.weaponskin;
			self.weaponskin = self.secondaryweaponskin;
			self.secondaryweaponskin = tempf3;
		} else {
			// store primary weapon
			tempf = self.weapon;
			tempf1 = self.currentmag;
			tempf2 = self.currentmag2;
			tempf3 = self.currentammo;
			tempf4 = self.weaponskin;

			// set primary weapon to third weapon
			self.weapon = self.thirdweapon;
			self.currentmag = self.thirdmag;
			self.currentmag2 = self.thirdmag2;
			self.currentammo = self.thirdammo;
			self.weaponskin = self.thirdweaponskin;

			// set third weapon to secondary weapon
			self.thirdweapon = self.secondaryweapon;
			self.thirdmag = self.secondarymag;
			self.thirdmag2 = self.secondarymag2;
			self.thirdammo = self.secondaryammo;
			self.thirdweaponskin = self.secondaryweaponskin;

			// set secondary weapon to primary weapon
			self.secondaryweapon = tempf;
			self.secondarymag = tempf1;
			self.secondarymag2 = tempf2;
			self.secondaryammo = tempf3;
			self.secondaryweaponskin = tempf4;
		}

		startframe = GetFrame(self.weapon,TAKE_OUT_START);
		endframe = GetFrame(self.weapon,TAKE_OUT_END);
		modelname = GetWeaponModel(self.weapon, 0);

		SwitchWeapon(self.weapon);

		if (IsDualWeapon(self.weapon)) {
			self.weapon2model = GetLeftWeaponModel(self.weapon);
		} else if (self.weapon == W_KAR_SCOPE || self.weapon == W_HEADCRACKER)
			self.weapon2model = "models/weapons/kar/v_karscope.mdl";
		else 
			self.weapon2model = "";

		UpdateV2model(self.weapon2model, 0);

		// TEMP
		if (self.weapon == W_M2 || self.weapon == W_FIW)
			UpdateVmodel(modelname, GetWepSkin(self.weapon));
	
		
		//UpdateWeapons(1);
		//if (self.weaponslot1.dualwield)
		//	Set_W2_Frame (self.weaponslot1.TakeWeaponStart, self.weaponslot1.TakeWeaponEnd, 0, 0, 0, SUB_Null, self.weaponslot1.v_model2, false);//FIXME
		Set_W_Frame (startframe, endframe, 0, 0, 0, SUB_Null, modelname, false, S_BOTH);//FIXME
		
		self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = 0; 
		
		
		#ifndef PC
		self.Weapon_Name = GetWeaponName(self.weapon);
		self.Flash_Offset = GetWeaponFlash_Offset(self.weapon);
		self.Flash_Size = GetWeaponFlash_Size(self.weapon);
		#endif
	}
}

void() W_PutOut =
{
	if (self.downed) {
		return;
	}
	
	W_AimOut();
	self.weaponnum = !self.weaponnum;
	
	if (self.secondaryweapon && !self.new_anim_stop)
	{
		float startframe;
		float endframe;
		string modelname;
		startframe = GetFrame(self.weapon,PUT_OUT_START);
		endframe = GetFrame(self.weapon,PUT_OUT_END);
		modelname = GetWeaponModel(self.weapon, 0);
	
		Set_W_Frame (startframe, endframe, (endframe - startframe)/10, 0, SWITCHWEP, W_Switch, modelname, false, S_BOTH);//FIXME
		self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = 0;
	}
}

void() W_TakeOut =
{
	W_AimOut();
	
	float startframe;
	float endframe;
	string modelname;
	startframe = GetFrame(self.weapon,TAKE_OUT_START);
	endframe = GetFrame(self.weapon,TAKE_OUT_END);
	modelname = GetWeaponModel(self.weapon, 0);

    self.isBuying = false;
	
	Set_W_Frame (startframe, endframe, (endframe - startframe)/10, 0, SWITCHWEP, SUB_Null, modelname, false, S_BOTH);//FIXME
	self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = 0;
}

float(entity who) hasWeapon =
{
    if (other.weapon || other.secondaryweapon || other.thirdweapon)
        return true;

    return false;
}



//RELOAD

void(float side) W_Give_Ammo =
{
	float ammo_shot, max_mag, loadammo;
	
	max_mag = getWeaponMag(self.weapon);

	if (side == S_LEFT) {
		ammo_shot = max_mag - self.currentmag2;
	} else {
		ammo_shot = max_mag - self.currentmag;
	}
	if (ammo_shot < self.currentammo)
	{
    	self.currentammo = self.currentammo - ammo_shot;
      
		loadammo = max_mag;
	}
	else
	{
		loadammo = self.currentmag + self.currentammo;
		self.currentammo = 0;
	}

	if (side == S_LEFT) {
		self.currentmag2 = loadammo;
	} else {
		self.currentmag = loadammo;
	}
};

void () W_LoadAmmo;
void() ContinueReload = //Special reloads
{
	if (self.new_anim_stop)
		return;
	
	if (self.weapon == W_GUT && self.currentmag == 10)
    return;

	float delay = 0;
	string modelname = GetWeaponModel(self.weapon, 0);
	float startframe = 0;
	float endframe = 0;
	void(optional float t) endanimfunc = SUB_Null;
	
	if (self.currentmag >= getWeaponMag(self.weapon) || !self.currentammo || self.reloadinterupted) {
		if (self.weapon == W_KAR_SCOPE || self.weapon == W_HEADCRACKER)
		{
			delay = 1; 
			startframe = 24;
			endframe = 28;
		} else if (self.weapon == W_TRENCH || self.weapon == W_GUT) {
			delay = 0.5; 
			startframe = 24;
			endframe = 26;
			endanimfunc = W_LoadAmmo;
		}
		self.reloadinterupted = FALSE;
	} else if (self.currentmag < getWeaponMag(self.weapon)) {
		if (self.weapon == W_BROWNING || self.weapon == W_ACCELERATOR) {
			delay = 4; 
			startframe = 45;
			endframe = 77;
			endanimfunc = W_Give_Ammo;
		} else if (self.weapon == W_KAR_SCOPE || self.weapon == W_HEADCRACKER) {
			self.currentmag++;
        	self.currentammo = self.currentammo - 1;
			delay = 0.8; 
			startframe = 19;
			endframe = 24;
			endanimfunc = ContinueReload;
		} else if (self.weapon == W_TRENCH || self.weapon == W_GUT) {
			if (self.weapon == W_GUT && self.currentammo >= 2 && self.currentmag < 9) {
				self.currentmag = self.currentmag + 2;
				self.currentammo = self.currentammo - 2;
			} else {
				self.currentmag++;
				self.currentammo = self.currentammo - 1;
			}
			delay = 0.5; 
			startframe = 18;
			endframe = 23;
			endanimfunc = ContinueReload;
		}
	}

	if (delay) {
		if (self.perks & P_SPEED) {
			delay *= 0.5;
		}
		self.reload_delay = time + delay;
		Set_W_Frame (startframe, endframe, delay, 0, RELOAD, endanimfunc, modelname, false, S_RIGHT);
	}
}

void(float side) W_Reload =
{
	if (self.weapon == W_M2 || self.weapon == W_FIW)
		return;
	
	if (side == S_BOTH) {
		W_Reload(S_RIGHT);
		if (IsDualWeapon(self.weapon)) {
			W_Reload(S_LEFT);
		}
		return;
	}
	if (side == S_RIGHT &&
		(self.reload_delay > time ||
		self.new_anim_stop ||
		!self.currentammo || 
		self.currentmag >= getWeaponMag(self.weapon))){
		return;
	}
	if (side == S_LEFT &&
		(self.reload_delay2 > time ||
		self.new_anim2_stop || 
		!self.currentammo ||
		self.currentmag2 >= getWeaponMag(self.weapon))) {
		return;
	}

	//TEMPORARY
	#ifdef PC
	self.viewzoom = 1;
	#endif
	self.zoom = false;

	W_AimOut();
	W_SprintStop();

	float endframe, startframe, reloadcancelframe, delay;
	string modelname;
	if (side == S_RIGHT) {
		modelname = GetWeaponModel(self.weapon, 0);
	} else {
		if (IsDualWeapon(self.weapon)) {
			modelname = GetLeftWeaponModel(self.weapon); 
		}
	}
	
	if (self.currentammo)
	{
		playreload();
		
		startframe = GetFrame(self.weapon,RELOAD_START);
		endframe = GetFrame(self.weapon,RELOAD_END);
		reloadcancelframe = GetFrame(self.weapon,RELOAD_CANCEL);
		delay = getWeaponDelay(self.weapon,RELOAD);
		void(optional float t) endanimfunc = SUB_Null;

		if (self.weapon == W_BROWNING || self.weapon ==  W_ACCELERATOR) {
			if (!self.currentmag) {
				startframe = 26;
				endframe = 77;
				reloadcancelframe = 45;
				delay = 6;
				endanimfunc = W_Give_Ammo;
			} else if (self.currentmag > 0) {
				startframe = 4;
				endframe = 25;
				reloadcancelframe = 0;
				delay = 3.5;
				endanimfunc = ContinueReload;
			}
		} else if (self.weapon == W_KAR_SCOPE || self.weapon == W_HEADCRACKER ){
			startframe = 14;
			endframe = 18;
			reloadcancelframe = 0;
			delay = 0.8;
			endanimfunc = ContinueReload;
		} else if (self.weapon == W_M1 || self.weapon == W_M1000) {
			if (self.currentmag > 0) {
				startframe = 4;
				endframe = 44;
				reloadcancelframe = 25;
				delay = 3.9;
				endanimfunc = W_Give_Ammo;
			} else {
				startframe = 8;
				endframe = 44;
				reloadcancelframe = 25;
				delay = 3.6;
				endanimfunc = W_Give_Ammo;
			}
		} else if (self.weapon == W_TRENCH || self.weapon == W_GUT) {
			if (self.currentmag == 0) {
				self.NeedLoad = true;
			}
			startframe = 14;
			endframe = 17;
			reloadcancelframe = 0;
			delay = 0.8;
			endanimfunc = ContinueReload;
		} else {
			endanimfunc = W_Give_Ammo;
		}

		if (self.perks & P_SPEED)
			delay = delay*0.5;
		
		if (side == S_RIGHT) {
			self.reload_delay = delay + time;
		} else {
			self.reload_delay2 = delay + time;
		}
		
		Set_W_Frame (startframe, endframe, delay, reloadcancelframe, RELOAD, endanimfunc, modelname, false, side);
	}
	
	if (self.weapon != W_TRENCH) {
		self.NeedLoad = false;
	}
};

void () W_LoadAmmoDone =
{
	self.NeedLoad = false;
}
void () W_LoadAmmo =
{
	if (!self.NeedLoad)
		return;
	if (!self.currentmag)
	{
		W_Reload(S_BOTH);
		return;
	}

	string modelname;
	float endframe, startframe, reloadcancelframe, delay;

	modelname = GetWeaponModel(self.weapon, 0);
	startframe = GetFrame(self.weapon,RELOAD_START);
	endframe = GetFrame(self.weapon,RELOAD_END);
	reloadcancelframe = GetFrame(self.weapon,RELOAD_CANCEL);
	delay = getWeaponDelay(self.weapon,RELOAD);
	void(optional float t) endanimfunc = SUB_Null;

	if (self.weapon == W_TRENCH || self.weapon == W_GUT)
	{
		startframe = 4;
		endframe = 14;
		reloadcancelframe = 12;
		delay = 1;
		endanimfunc = W_LoadAmmoDone;
	}
	else if (self.weapon == W_KAR || self.weapon == W_ARMAGEDDON || self.weapon == W_KAR_SCOPE || self.weapon == W_HEADCRACKER)
	{
		startframe = 4;
		endframe = 13;
		reloadcancelframe = 9;
		delay = 0.9;
		endanimfunc = W_LoadAmmoDone;
	}	

	if (delay) {
		
		Set_W_Frame (startframe, endframe, delay, reloadcancelframe, FIRE, W_LoadAmmoDone, modelname, false, S_RIGHT);
		self.fire_delay = delay + time;
	}
}

void () CheckReload = 
{
	if (!self.currentmag2 && IsDualWeapon(self.weapon)) {
		W_Reload(S_LEFT);
	}
	if (!self.currentmag && self.currentammo) {
		W_Reload(S_RIGHT);
	}
}

/*
================
SpawnBlood
================
*/
void(vector org, vector vel, float damage) SpawnBlood =
{
	local entity f;
  
  	#ifdef PC
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_BLOOD);
	WriteCoord(MSG_MULTICAST, org_x);
	WriteCoord(MSG_MULTICAST, org_y);
	WriteCoord(MSG_MULTICAST, org_z);
	msg_entity = self;
	multicast('0 0 0', MULTICAST_ONE);
	#else
	particle (org, vel*0.1, 73, damage*2);
	#endif

	f = find (world, classname, "player");
	f.hitcount = f.hitcount + 1;
};

void(vector where) spawn_gibs = {
	#ifndef PC
	particle(where, where*0.1, 225, 1);
	#else
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_BLOOD);
	WriteCoord(MSG_MULTICAST, where_x);
	WriteCoord(MSG_MULTICAST, where_y);
	WriteCoord(MSG_MULTICAST, where_z);
	msg_entity = self;
	multicast('0 0 0', MULTICAST_ONE);
	#endif
}


void Parse_Damage () = // DO NOT TOUCH
{
	entity ent;
	float total_dmg;

	entity body_ent;
	float head_hit;

	//warn
	head_hit = 0;

	ent = findfloat (world, washit, 1);

	while (ent) {
		if (ent.classname != "radio" && ent.classname != "explosive_barrel") {

			if (ent.classname == "ai_zombie_head")
				head_hit = 1;
			
			if (ent.classname != "ai_zombie" && ent.classname != "ai_dog") //limb
				body_ent = ent.owner;
			else
				body_ent = ent;

			total_dmg = body_ent.hitamount;

			if (body_ent.head.washit) {
				total_dmg += body_ent.head.hitamount;
				body_ent.head.health -= body_ent.head.hitamount;
				head_hit = 1;

				// Head = Gone!
				if (body_ent.head.health <= 0) {
					// Head has already been blown off, bro
					if (!body_ent.head.deadflag)
						return;

					vector where;

					// If our weapon is capable, blow the head off
					if (getWeaponDamage(self.weapon) >= 100) {
						makevectors(body_ent.head.owner.angles);
						where = body_ent.head.owner.origin + (body_ent.head.view_ofs_x * v_right) + (body_ent.head.view_ofs_y * v_forward) + (body_ent.head.view_ofs_z * v_up);
						spawn_gibs(where);

						// Should the Zombie try and walk on?
						if (random() <= 0.01) {
							body_ent.bleedingtime = time + 2;
						} else {
							// Nah, he dead.
							total_dmg *= 5000;
						}
					
						body_ent.head.deadflag = false;
						body_ent.head.solid = SOLID_NOT;
						setmodel(body_ent.head,"");
						body_ent.head.frame = 0;
					
						body_ent.usedent = self;
						body_ent.bleedingtime = time + 2;
					}
				}
				
				body_ent.head.washit = 0;
				body_ent.head.hitamount = 0;
			}
			if (body_ent.larm.washit) {
				total_dmg = total_dmg + body_ent.larm.hitamount;

				body_ent.larm.health = body_ent.larm.health - body_ent.larm.hitamount;
				if (body_ent.larm.health <= 0 && self.weapon != W_COLT && body_ent.larm.owner.rarm.deadflag && body_ent.larm.deadflag)
				{
					
					makevectors(body_ent.larm.owner.angles);
					where = body_ent.larm.owner.origin + (body_ent.larm.view_ofs_x * v_right) + (body_ent.larm.view_ofs_y * v_forward) + (body_ent.larm.view_ofs_z * v_up);
					spawn_gibs(where);
					
					body_ent.larm.deadflag = false;
					body_ent.larm.solid = SOLID_NOT;
					setmodel(body_ent.larm,"");
					body_ent.larm.frame = 0;
					//updateLimb (body_ent.larm.owner, 1, world);
				}

				body_ent.larm.washit = 0;
				body_ent.larm.hitamount = 0;
			}
			if (body_ent.rarm.washit) {
				total_dmg = total_dmg + body_ent.rarm.hitamount;

				body_ent.rarm.health = body_ent.rarm.health - body_ent.rarm.hitamount;
				if (body_ent.rarm.health <= 0 && self.weapon != W_COLT && body_ent.rarm.owner.larm.deadflag && body_ent.rarm.deadflag) {
					
					makevectors(body_ent.rarm.owner.angles);
					where = body_ent.rarm.owner.origin + (body_ent.rarm.view_ofs_x * v_right) + (body_ent.rarm.view_ofs_y * v_forward) + (body_ent.rarm.view_ofs_z * v_up);
					spawn_gibs(where);
					
					body_ent.rarm.deadflag = false;
					body_ent.rarm.solid = SOLID_NOT;
					setmodel(body_ent.rarm,"");
					body_ent.rarm.frame = 0;
					//updateLimb (body_ent.rarm.owner, 2, world);
				}

				body_ent.rarm.washit = 0;
				body_ent.rarm.hitamount = 0;
			}

			if (instakill_finished) {
				if(body_ent.head.deadflag) {
					body_ent.head.deadflag = false;
					body_ent.head.solid = SOLID_NOT;
					setmodel(body_ent.head,"");
					body_ent.head.frame = 0;
				}
			}
			
			if (head_hit)
				DamageHandler(body_ent,self, total_dmg, S_HEADSHOT);
			else
				DamageHandler(body_ent,self, total_dmg, S_NORMAL);
			
			#ifndef PC
			body_ent.washit = 0;
			body_ent.hitamount = 0;
			#else
			ent.washit = 0;
			ent.hitamount = 0;
			#endif

		}
		ent = findfloat (ent, washit, 1);
	}
}

void() LungeKnifeHit =
{		
	vector	source,org;
	float	f_damage;
	entity	hit_ent;

	makevectors (self.v_angle);
	source = self.origin + self.view_ofs;

	if (self.weapon == W_BK)
		traceline (source, source + v_forward*80*1.2, 0, self); // naievil -- added some extra length
	else
		traceline (source, source + v_forward*64*1.2, 0, self); // naievil -- ^^
	
	org = trace_endpos - v_forward*3; // naievil -- changed to factor of 3 from 4
	

	if (trace_ent.takedamage)
	{
		if(trace_ent.classname == "item_radio" || trace_ent.classname == "teddy_spawn")
		{
			entity oldself;
			oldself  = self;
			self = trace_ent;
			self.th_die();
			self = oldself;
			return;
		}
		sound (self, CHAN_WEAPON, "sounds/weapons/knife/knife_hitbod.wav", 1, ATTN_NORM);
		
		if (self.bowie && self.weapon == W_BK)
			f_damage = 1200;
		else if (self.bowie)
			f_damage = 1000;
		else if (self.weapon == W_BK)
			f_damage = 500;
		else
			f_damage = 150;
					
		if (trace_ent.classname == "ai_zombie_head")
		{
			hit_ent = trace_ent.owner;
			f_damage = f_damage*1.5;
		}
		else if (trace_ent.classname == "ai_zombie_larm")
		{
			hit_ent = trace_ent.owner;
		}
		else if (trace_ent.classname == "ai_zombie_rarm")
		{
			hit_ent = trace_ent.owner;
		}
		else
		{
			hit_ent = trace_ent;
		}
		
		if (hit_ent.takedamage)
		{
			org = source + (v_forward * 20);
			SpawnBlood (org, org, 50);
			//hit = 1;
		}
		
		DamageHandler (hit_ent, self, f_damage, S_KNIFE);
	}
}

void(float damage, vector dir, vector org, vector plane, entity hit_ent, float side) TraceAttack =
{
	vector  vel;
	float f_damage;
  
	vel = normalize(dir);
	vel = vel + 2*plane;
	vel = vel * 200;

	if (hit_ent.takedamage) {
		if (trace_fraction >= 1) {
			return;
		}
		if(hit_ent.classname == "item_radio" || hit_ent.classname == "teddy_spawn")
		{
			entity oldself;
			oldself  = self;
			self = hit_ent;
			self.th_die();
			self = oldself;
			return;
		} else if (hit_ent.classname == "explosive_barrel") {
			hit_ent.enemy = self;
			oldself  = self;
			self = hit_ent;
			self.health = self.health - damage;
			
			barrel_hit ();
			
			self = oldself;
			return;
		} else if (hit_ent.classname == "door" || hit_ent.classname == "door_nzp") {
			local entity old;
			old = self;
			self = hit_ent;
			self.health -= damage;

			if (self.health < 0)
				door_use();
			self = old;
			return;
		}
		
		SpawnBlood (org, vel, damage*10);

		switch(hit_ent.classname) {
			case "ai_zombie_head":
				f_damage = damage*getWeaponMultiplier(self.weapon, HEAD_X);
				break;
			case "ai_zombie_larm":
			case "ai_zombie_rarm":
				f_damage = damage*getWeaponMultiplier(self.weapon, LIMBS_X);
				break;
			case "ai_zombie":
				if (trace_endpos_z < hit_ent.origin_z)
					f_damage = damage*getWeaponMultiplier(self.weapon, LOWER_TORSO_X);
				else
					f_damage = damage*getWeaponMultiplier(self.weapon, UPPER_TORSO_X);
				break;
			default:
				f_damage = damage;
				break;
		}

		hit_ent.washit = 1;
		hit_ent.hitamount = hit_ent.hitamount + f_damage;
		
		SetUpdate(self, UT_HM, 0, 0, 0);
		
		#ifndef PC
		msg_entity = self;
		WriteByte(MSG_ONE, SVC_HITMARK);
		#endif
	} else {

	#ifndef PC
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_GUNSHOT);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);
	#endif
	}
	
	#ifdef PC
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_PISTOLFIRE);
	WriteEntity(MSG_MULTICAST, self);
    WriteFloat(MSG_MULTICAST, side);
	WriteCoord(MSG_MULTICAST, org_x);
	WriteCoord(MSG_MULTICAST, org_y);
	WriteCoord(MSG_MULTICAST, org_z);
	WriteCoord(MSG_MULTICAST, plane_x);
	WriteCoord(MSG_MULTICAST, plane_y);
	WriteCoord(MSG_MULTICAST, plane_z);
	WriteEntity(MSG_MULTICAST, hit_ent);
	multicast(trace_endpos, MULTICAST_PHS);
	#endif
	
};

void (float shotcount, float sprd, float Damage, float side) FireTrace =
{
	float count, r, ru, penetration_times, do_break;
	vector dir, src, trace_start_org;
	entity hitent;
	
	makevectors(self.v_angle);
	
	src = self.origin + self.view_ofs;
	
	#ifndef PC
	CL_SendWeaponFire();
	#endif

	while (count < shotcount)
	{
		dir = aim (self,0);
		r = random() * sprd*10;
		if (random() < 0.5)
			r = r*-1;
		ru = random() * sprd*10;
		if (random() < 0.5)
			ru = ru*-1;

		dir = dir*2048;
		dir = dir + v_right*r + v_up*ru;
		trace_start_org = src;
		trace_ent = self;
		do_break = 0;
		penetration_times = 0;
		hitent = world;
		while (!do_break && random() < getWeaponPenetration(self.weapon, penetration_times))
		{
			while (1)
			{
				traceline (trace_start_org, trace_start_org + dir, MOVE_HITMODEL, trace_ent);
				
				if (hitent == world)
					break;
				/*if (hitent.larm == trace_ent || hitent.rarm == trace_ent || hitent.head == trace_ent)
				{
					hitent = trace_ent;
					trace_start_org = trace_endpos + normalize(dir)*10;
					//break;
				}*/
				else
					break;
			}
			
			if (trace_fraction != 1.0)
				TraceAttack (Damage, dir, trace_endpos, trace_plane_normal, trace_ent, side);
			trace_start_org = trace_endpos;
			penetration_times++;
			if (!trace_ent.takedamage)
				do_break = 1;
			
			if (trace_ent.classname == "ai_zombie_head" || trace_ent.classname == "ai_zombie_larm" || trace_ent.classname == "ai_zombie_rarm")
				hitent = trace_ent.owner;
			else
				hitent = trace_ent;

		}
		hitent = world;

		count++;
	}
	if (self.weapon != W_TESLA)
		Parse_Damage();

}

void(float side) W_FireGrenade = 
{
	entity nade = spawn();
	nade.owner = self;
	nade.movetype = MOVETYPE_BOUNCE;
	nade.solid = SOLID_BBOX;
	nade.classname = "explosiveNade";

	makevectors (self.v_angle);

	nade.velocity = v_forward*1000;		
	nade.avelocity = '50 -50 50';

	centerprint(self, vtos(nade.angles));

	nade.touch = GrenadeExplode;
	setsize(nade, '0 0 0', '0 0 0');
	nade.origin = self.origin + self.view_ofs;

	setorigin(nade, nade.origin);
}

//
// RAY GUN - modified from patch <3
//

void() RayBulletExplode =
{
	DamgageExplode (self, self.owner, 1800, 1800, 64);//we want A SMALL radius of explosion

	// MOTO - FTE explosions are.. large, let's flash instead.
	
	#ifdef PC
	te_smallflash(self.origin);
	#else
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	#ifdef PSP
	if (self.effects & EF_RAYGREEN)
		WriteByte (MSG_BROADCAST, TE_RAYSPLASHGREEN);
	else
		WriteByte (MSG_BROADCAST, TE_RAYSPLASHRED);
	#else
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	#endif
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
	#endif
	
	SUB_Remove ();
};

void() velocity_increase_ray =
{
	if (!other.solid || other.solid == SOLID_TRIGGER)
		if (other != world)
			return;
				
	if (other == self.owner)
		return;
				
	if (other.solid == SOLID_NOT) {
		RayBulletExplode();
	}

	self.velocity = self.velocity*1.5;
		
	RayBulletExplode();
};

void() W_FireRay =
{
	local entity porter;

	porter = spawn();
	porter.owner = self;
	porter.movetype = MOVETYPE_FLY;
	porter.solid = SOLID_BBOX;

	makevectors(self.v_angle);

	porter.velocity = v_forward*2000;
	porter.avelocity = '0 0 0';

	porter.angles = vectoangles(porter.velocity);
	porter.angles_z += (porter.angles_z + 180 < 360)? 180 : -180;
	porter.angles = vectoangles(v_forward);

	porter.v_angle = '0 0 200';

	porter.touch = velocity_increase_ray;
	setmodel(porter, "progs/raybeam.mdl");
	setsize(porter, '0 0 0', '0 0 0');

	
	if (self.weapon == W_PORTER) {
		#ifdef PSP
		porter.effects = EF_RAYRED;
		#else
		porter.effects = EF_RED;
		#endif
	} else {
		#ifdef PSP
		porter.effects = EF_RAYGREEN;
		#else
		porter.effects = EF_GREEN;
		#endif
	}
	

	porter.origin = self.origin + self.view_ofs;
	porter.origin += v_forward * 0;

	setorigin(porter, porter.origin);

	self.animend = ReturnWeaponModel;
	self.callfuncat = 0;
}

// Remove zombie, add money, request clone spawn.
void(entity hit_ent) LightningHit =
{
	local entity tempe;

	// 50 points for waffe kills
	addmoney(self, 50, true);

	// set lib models to null
	// (if we remove them RelinkZombies will cry)
	if (hit_ent.head)
		setmodel(hit_ent.head, "");
	if (hit_ent.larm)
		setmodel(hit_ent.larm, "");
	if (hit_ent.rarm)
		setmodel(hit_ent.rarm, "");

	// window hop fix
	if (self.state == 1 || self.hop_step != 0) {
		self.state = self.hop_step = 0;
	}

	// change classname so it can't be re-targted
	hit_ent.classname = "wunder";

	// own it!
	hit_ent.owner = self;

	// we're the start of a chain
	hit_ent.teslacount = 1;

	// play our wunder-ful anim
	tempe = self;
	self = hit_ent;
	self.th_diewunder();
	self = tempe;

	// kill
	self.kills += 1;
};

// Initial Zombie impact, creds to Naievil/UP
void(vector p1, vector p2, entity from, float damage) LightningDamage =
{
	local entity            e1, e2;
	local vector            f;
	entity hit_ent;
	
	f = p2 - p1;
	normalize (f);
	f_x = 0 - f_y;
	f_y = f_x;
	f_z = 0;
	f = f*16;

	e1 = e2 = world;

	//traceline (p1, p2, false, self);
	
	hit_ent = trace_ent;

	if (hit_ent == world)
		return;

	if (hit_ent.classname == "ai_zombie_head" || hit_ent.classname == "ai_zombie_larm" || hit_ent.classname == "ai_zombie_rarm")
		hit_ent = hit_ent.owner;

	if (trace_ent.takedamage)
	{
		LightningHit (hit_ent);
	}
	e1 = trace_ent;
	
	traceline (p1 + f, p2 + f, FALSE, self);
	if (trace_ent != e1 && trace_ent.takedamage)
	{
		LightningHit (hit_ent);
	}
	e2 = trace_ent;
	

	traceline (p1 - f, p2 - f, FALSE, self);
	if (trace_ent != e1 && trace_ent != e2 && trace_ent.takedamage)
	{
		LightningHit (hit_ent);
	}
};

// Fire lightning out of the gun
void() W_FireTesla =
{
	local vector source;

	makevectors (self.v_angle);
	source = self.origin + self.view_ofs;

	FireTrace(1, 0, 0, 0);

	#ifdef PC
	te_lightning2(self, source, trace_endpos);
	#endif
	#ifdef PSP
	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
	WriteEntity (MSG_BROADCAST, self);
	WriteCoord (MSG_BROADCAST, source_x);
	WriteCoord (MSG_BROADCAST, source_y);
	WriteCoord (MSG_BROADCAST, source_z);
	WriteCoord (MSG_BROADCAST, trace_endpos_x);
	WriteCoord (MSG_BROADCAST, trace_endpos_y);
	WriteCoord (MSG_BROADCAST, trace_endpos_z);
	#endif

	LightningDamage (self.origin, trace_endpos + v_forward*4, self, 30);
}

void() Flame_LingerThink =
{
	#ifdef PC
	te_flamejet(self.origin, v_up*8, 5);
	#else
	particle (self.origin, v_up*8, 0, 0);
	#endif

	if (self.ltime < time)
		remove(self);

	self.nextthink = time + 0.1;
}

// spawn linger effect/entity
void(vector org, entity whodunit) Flame_Linger =
{
	local entity linger = spawn();

	setorigin(linger, org);

	linger.owner = whodunit.owner;
	linger.think = Flame_LingerThink;
	linger.nextthink = time + 0.1;
	linger.ltime = time + 5;
}

void() Flame_Touch =
{
	if (other == world) {
		Flame_Linger(self.origin, self);
		remove(self);
	} else {
		if (other.onfire || other.owner.onfire)
			return;
		if (other.classname == "ai_zombie_head" || other.classname == "ai_zombie_larm" 
		|| other.classname == "ai_zombie_rarm") {
			other.owner.onfire = true;
			other.owner.ltime = time + 2;
			addmoney(self.owner, 10, true);
		} else if (other.classname == "ai_zombie" || other.classname == "ai_dog") {
			other.onfire = true;
			other.firer = self.owner;
			other.ltime = time + 2;
			addmoney(self.owner, 10, true);
		}
	}
}

// fallen flame touches something
void() Flame_DropCatch =
{
	if (other == world) {
		Flame_Linger(self.origin + '0 0 5', self);
		remove(self);
	}
}

// drop didn't make it to the ground in time to spread
void() Flame_DropDissapate =
{
	remove(self);
}

// rare chance some falls
void() Flame_Drop =
{
	local entity drop = spawn();

	drop.owner = self.owner;

	setmodel(drop, "models/misc/flame.spr");
	setsize(drop, '0 0 0', '0 0 0');
	setorigin(drop, self.origin);

	drop.touch = Flame_DropCatch;
	drop.think = Flame_DropDissapate;
	drop.nextthink = time + 0.8;
	drop.solid = SOLID_TRIGGER;
	drop.movetype = MOVETYPE_BOUNCE;

	drop.velocity = v_up*-55;
}

// increase frames, remove/drop
void() Flame_Buildup =
{
	self.frame++;

	if (self.frame > 11) {
		if (random() > 0.75)
			Flame_Drop();
		remove(self);
	}

	self.nextthink = time + 0.05;
}

void() W_FireM2 =
{

	local entity flamespr;
	local vector rand_angle;

	flamespr = spawn();
	flamespr.owner = self;
	flamespr.movetype = MOVETYPE_FLYMISSILE;
	flamespr.solid = SOLID_TRIGGER;
	flamespr.classname = "flamethrower_sprite";
	flamespr.state = 0;
	flamespr.finaldest = self.v_angle;

	// calc some randomness
	rand_angle = self.v_angle;
	rand_angle_x += random()*10;
	rand_angle_y += random()*10;

	makevectors(rand_angle);
	flamespr.velocity = aim(self, 1000);
	flamespr.velocity *= 600;

	flamespr.owner = self;

	flamespr.think = Flame_Buildup;
	flamespr.nextthink = time + 0.01;
	flamespr.touch = Flame_Touch;

	setmodel(flamespr, "models/misc/flame.spr");
	setorigin(flamespr, self.origin + self.view_ofs - '0 0 10');
	setsize(flamespr, '0 0 0', '0 0 0');
}

void(float side) W_Fire =
{
	if (self.weapon == W_M2 || self.weapon == W_FIW && self.cooldown)
		return;

	//First check that we can actualy fire
	if (side == S_RIGHT &&
		(time < self.fire_delay ||
		self.new_anim_stop ||
		self.reload_delay > time || (!self.currentammo && !self.currentmag))) {
		return;
	}

	if (side == S_LEFT &&
		(time < self.fire_delay2 ||
		self.new_anim2_stop ||
		self.reload_delay2 > time)) {
		return;
	}

	if (self.sprinting) {
		W_SprintStop();
		return;
	}

	float startframe;
	float endframe;
	float firetype;
	float damage;
	float shotcount;
	string modelname;
	string soundname;
	float spread;
	float sprdstance;
	float delay;

	//Update the basic vectors
	makevectors(self.v_angle);

	//make sure magazine is loading
	if (!self.currentmag && side == S_RIGHT)
	{
		W_Reload(S_RIGHT);
		return;
	} else if (!self.currentmag2 && side == S_LEFT)
	{
		W_Reload(S_LEFT);
		return;
	}

	//Dont fire if the gun has to cycle
	if (self.NeedLoad && (self.weapon == W_TRENCH || self.weapon == W_GUT || self.weapon == W_KAR_SCOPE || self.weapon == W_KAR || self.weapon == W_ARMAGEDDON || self.weapon == W_HEADCRACKER))
	{
		W_LoadAmmo();
		return;
	}
	
	//get some basic info
	damage = getWeaponDamage(self.weapon);   
	firetype = GetFiretype (self.weapon);
	if (side == S_RIGHT) {
		modelname = GetWeaponModel(self.weapon, 0);
	} else {
		if (IsDualWeapon(self.weapon)) {
			modelname = GetLeftWeaponModel(self.weapon); 
		}
	}
	shotcount = GetWeaponShotcount(self.weapon);
    soundname = GetWeaponSound(self.weapon);
	delay = getWeaponDelay(self.weapon, FIRE);

	// Double Tap 2.0
	if (self.perks & P_DOUBLE)
		shotcount *= 2;

	switch(self.stance) {
		case 2:
			sprdstance = 0;
			break;
		case 1:
			sprdstance = 2;
			break;
		case 0:
			sprdstance = 4;
			break;
		default:
			sprdstance = 0;
			break;
	}

	spread = (1.5*GetWeaponSpread(self.weapon))-sprdstance;

	if (self.perks & P_DEAD) {
		spread *= 0.65;
	}

	if (self.zoom == 1) {
		if (self.weapon == W_TRENCH ||
			self.weapon == W_DB ||
			self.weapon == W_SAWNOFF ||
			self.weapon == W_GUT ||
			self.weapon == W_BORE) {
				spread = spread * 0.75;
			} else {
				spread = spread * 0.1;
			}
	} else if (self.zoom == 2) {
		spread = spread * 0.05;
	} else if (self.velocity || !(self.flags & FL_ONGROUND))
		spread *= 2;

	if (self.downed)
		playdownfire();

	// MOTO - should probably reorganize this whole firetype chunk in the future..

	//Fire weapons
	if (firetype == 1 || firetype == 3)
	{
		if (side == S_RIGHT) {
			if (self.semi) {
				return;
			}
			self.semi = TRUE;
		} else if (side == S_LEFT) {
			if (self.semi2) {
				return;
			}
			self.semi2 = TRUE;
		}

		if (firetype == 3) {
			W_FireGrenade(side);
		}
	} else if (firetype == 4) {
		W_FireRay();
	} else if (firetype == 5) {
		W_FireTesla();
	} else if (firetype == 6) {
		W_FireM2();
	}

    // FIXME - clean this up lol
	if (firetype == 1 || firetype == 0 || firetype == 3) {
		FireTrace(shotcount, spread, damage, side);
	}

	//Play weapon animation and sound
	startframe = GetFrame(self.weapon,FIRE_START);
	endframe = GetFrame(self.weapon,FIRE_END);
	

	if (self.perks & P_DOUBLE) {
		delay *= 0.66;
	}

	if (self.weapon == W_GUT || self.weapon == W_KAR_SCOPE || self.weapon == W_TRENCH || self.weapon == W_KAR || self.weapon == W_ARMAGEDDON || self.weapon == W_HEADCRACKER)
	{
		Set_W_Frame (startframe, endframe, delay, 0, FIRE, W_LoadAmmo, modelname, FALSE, side);
		self.NeedLoad = true;
	} else {
		Set_W_Frame (startframe, endframe, delay, 0, FIRE, CheckReload, modelname, FALSE, side);
	}


	sound (self, CHAN_WEAPON, soundname, 1, ATTN_NORM);

	if (side == S_RIGHT) {
		self.currentmag = self.currentmag - 1;
		self.fire_delay = getWeaponDelay(self.weapon, FIRE) + time;
	} else {
		self.currentmag2 = self.currentmag2 - 1;
		self.fire_delay2 = getWeaponDelay(self.weapon, FIRE) + time;
	}

	if (IsPapWeapon(self.weapon)) {
		sound (self, 0, "sounds/weapons/papfire.wav", 1, ATTN_NORM);
	}
	
	SetUpdate(self, UT_HUD, 6, 0, 0);
	SetUpdate(self, UT_CROSSHAIR, 5, 0, 0);
	

	// REFORMAT THIS 
	#ifndef PC
	self.effects = self.effects | EF_MUZZLEFLASH;
	#else 
	// psp takes care of this in engine
	if (self.perks & P_DEAD)
		return;

	vector Wep_Recoil;
	Wep_Recoil = GetWeaponRecoil(self.weapon)*0.5;

	self.punchangle_x = Wep_Recoil_x;
	self.punchangle_y = Wep_Recoil_y;
	self.punchangle_z = Wep_Recoil_z;
	#endif
}


/******************************
* W_Knife                     *
******************************/

// FIXME - knife & nade vmodels change skin on PSP!
void () W_Knife =
{
	if (time < self.knife_delay || self.new_anim_stop ||
	  self.zoom || self.health == 10 || 
	  (!(self.flags & FL_ONGROUND)))
		return;

	vector	source;
	entity	hit_ent = world;
	//entity	oldself;
	float	r, backupSkin;
	vector	org;
	float hit = false;
		
	if (self.sprinting) {
		W_SprintStop();
	}
	
	backupSkin = self.weaponskin;
	self.weaponskin = 0;
	sound (self, CHAN_WEAPON, "sounds/weapons/knife/knife.wav", 1, ATTN_NORM);
	makevectors (self.v_angle);
	source = self.origin + self.view_ofs;
	if (self.weapon == W_BK)
		traceline (source, source + v_forward*128, 0, self);
	else
		traceline (source, source + v_forward*100, 0, self);
	
	org = trace_endpos - v_forward*4;

	r = fabs(vlen(source - org));

	if (trace_ent.takedamage)
	{
		if (trace_ent.classname == "ai_zombie_head")
			hit_ent = trace_ent.owner;
		else if (trace_ent.classname == "ai_zombie_larm")
			hit_ent = trace_ent.owner;
		else if (trace_ent.classname == "ai_zombie_rarm")
			hit_ent = trace_ent.owner;
		else
			hit_ent = trace_ent;
		if (hit_ent.classname == "ai_zombie")
			hit = true;

		// if zombie has a head and it's instakill, gib for  a e s t h e t i c
		if (hit_ent.head && instakill_finished >= time) {
			spawn_gibs(hit_ent.head.origin);
			setmodel(hit_ent.head, "");
		}
	}
	else if (trace_fraction < 1.0)
	{	// hit wall
		sound (self, CHAN_WEAPON, "sounds/weapons/knife/knife_hit.wav", 1, ATTN_NORM);			
		
		/* naievil (FIXME) add weapon decal here */

		#ifdef PC
		if (self.weapon != W_RAY && self.weapon != W_PORTER) {
			WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
			WriteByte(MSG_MULTICAST, EVENT_PISTOLFIRE);
			WriteEntity(MSG_MULTICAST, self);
            WriteFloat(MSG_MULTICAST, 0);
			WriteCoord(MSG_MULTICAST, org_x);
			WriteCoord(MSG_MULTICAST, org_y);
			WriteCoord(MSG_MULTICAST, org_z);
			WriteCoord(MSG_MULTICAST, trace_plane_normal_x);
			WriteCoord(MSG_MULTICAST, trace_plane_normal_y);
			WriteCoord(MSG_MULTICAST, trace_plane_normal_z);
			WriteEntity(MSG_MULTICAST, hit_ent);
			multicast(trace_endpos, MULTICAST_PHS);
		}	
		#else
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
		#endif
	}

	if (r > 40 && hit)//lunge
	{
		if (self.weapon == W_BK)
		{
			Set_W_Frame (14, 24, 1.4, 0, KNIFE, SUB_Null, "progs/VModels/v_bk.mdl", false, S_RIGHT);
			self.fire_delay = time + 1.5;
			self.knife_delay = time + 1.75;
		}
		else if (self.bowie)
		{
			Set_W_Frame (4, 10, 0.7, 0, KNIFE, ReturnWeaponModel, "progs/VModels/v_bowie.mdl", false, S_RIGHT);
			self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = time + 0.8;
			self.knife_delay = time + 1.3;
		}
		else
		{
			self.punchangle_x = -5;
			self.punchangle_y = -10;
			Set_W_Frame (4, 12, 0.7, 0, KNIFE, ReturnWeaponModel, "progs/VModels/v_knife.mdl", false, S_RIGHT);
			self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = time + 0.8;
			self.knife_delay = time + 1;
		}
		self.velocity = v_forward * 200;
		
	}
	else
	{
		if (self.weapon == W_BK)//slash
		{
			Set_W_Frame (8, 13, 0, 0.4, KNIFE, SUB_Null, "progs/VModels/v_bk.mdl", false, S_RIGHT);
			self.fire_delay = time + 0.5;
			self.knife_delay = time + 0.8;
		}
		else if (self.bowie)
		{
			Set_W_Frame (0, 3, 0.3, 0, KNIFE, ReturnWeaponModel, "progs/VModels/v_bowie.mdl", false, S_RIGHT);
			self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = time + 0.4;
			self.knife_delay = time + 0.9;
		}
		else
		{
			self.punchangle_x = -5;
			self.punchangle_y = -10;
			//self.punchangle_z = 5;
			Set_W_Frame (0, 3, 0.3, 0, KNIFE, ReturnWeaponModel, "progs/VModels/v_knife.mdl", false, S_RIGHT);
			self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = time + 0.4;
			self.knife_delay = time + 0.7;
		}
	}
	self.reload_delay2 = self.reload_delay = 0;
	self.weaponskin = backupSkin;
	
	LungeKnifeHit();

};




/******************************
* W_Grenade                   *
******************************/

void() switch_nade = 
{ 
	if (self.downed || self.isBuying || !(self.grenades & 2) || self.semiswitch)
      return;

	if (self.pri_grenade_state == 0)
	{
		centerprint (self, "Bouncing Betties Selected");
		self.bk_nade = 1;
    }
    if (self.pri_grenade_state == 1)
    {
		centerprint (self, "Frag Grenades Selected");
		self.bk_nade = 0;
    }  	
	
	self.pri_grenade_state = self.bk_nade;

};

void() GrenadeExplode =
{
	sound (self, CHAN_WEAPON, "sounds/weapons/grenade/explode.wav", 1, ATTN_NORM);	

	if (self.classname == "grenade")
		DamgageExplode (self, self.owner, 225, 75, 128);//was 256 inch radius, kicked it down to 128 because 21 feet exploding radius is... a bit overkill...	
	else
		DamgageExplode (self, self.owner, 1200, 1000, 128); //explosive weapons are more powerful :)
	
	#ifdef PC
    te_customflash(self.origin, 178, 300, '1 1 1');
	#endif

    CallExplosion(self.origin);
	
	SUB_Remove ();
};
void() NadeStraighten =
{
	self.angles_x = (self.angles_x > 0) ? 90 : -90;	
	
	if (self.pri_grenade_state == 1)
    return;
};
void() Velocity_reduce =
{
	if (!other.solid || other.solid == SOLID_TRIGGER)
		if (other != world)
			return;

	self.velocity = self.velocity*0.5;
	
	NadeStraighten();
};

void() betty_touch = 
{
  	//centerprint (other, "wow\n"); <- THIS

	if (other.classname == "grenade")
		return;

  	if (other == self.owner || other.solid == SOLID_TRIGGER)
    	if (other != world)
      		return;
  
  	GrenadeExplode();
}

void() W_ThrowBetty =
{
	local entity betty;
	betty = spawn ();
	betty.owner = self;
	betty.grenade_delay = betty.owner.grenade_delay;
	betty.owner.grenade_delay = 0;
	betty.movetype = MOVETYPE_NONE;
	betty.solid = SOLID_TRIGGER;
	betty.classname = "betty";

	// set betty speed	
	betty.velocity = v_forward*0;

	betty.think = GrenadeExplode;
	betty.touch = betty_touch;

	setmodel (betty, "progs/GModels/g_betty.mdl");
	setsize (betty, '-16 -16 -4', '16 16 1');

	betty.origin = betty.owner.origin - self.view_ofs + '0 0 1';
	//if player isn't on ground, drop the betty to the floor.
	if (!(self.flags & FL_ONGROUND)) {
		local entity oldself;
		oldself = self;
		self = betty;
		
		#ifdef PC
		droptofloor();
		#else
		droptofloor(0, 0);
		#endif
		self = oldself;
	}
	betty.origin += v_forward * 0;
	setorigin (betty, betty.origin);

	self.animend = ReturnWeaponModel;
	self.callfuncat = 0;
	self.isBuying = false;  
}

void() W_ThrowGrenade =
{
	string modelname;
	float startframe;
	float endframe;
	local	entity nade;

	if (self.pri_grenade_state == 0) {
		nade = spawn ();
		nade.owner = self;
		nade.grenade_delay = nade.owner.grenade_delay;
		nade.owner.grenade_delay = 0;
		nade.movetype = MOVETYPE_BOUNCE;
		nade.solid = SOLID_BBOX;
		nade.classname = "grenade";

		// set nade speed	

		makevectors (self.v_angle);

		#ifndef PSP
		nade.velocity = v_forward*500;
		#else
		nade.velocity = v_forward*800;	// on PSP, we need more OOMFPH
		#endif
		
		nade.avelocity = '400 -400 400';

		//nade.angles = vectoangles(nade.velocity);
		//nade.angles_z += (nade.angles_z + 180 < 360)? 180 : -180;
		nade.angles = vectoangles(v_forward);
		nade.angles_z -= 15;
		// set nade duration
		nade.nextthink = nade.grenade_delay;
		nade.think = GrenadeExplode;

		nade.touch = Velocity_reduce;
		setmodel (nade, "progs/GModels/g_grenade.mdl");
		setsize (nade, '0 0 0', '0 0 0');
		nade.origin = self.origin + self.view_ofs;
		nade.origin += v_forward * 12;
		setorigin (nade, nade.origin);

		self.animend = ReturnWeaponModel;
		self.callfuncat = 0;
		self.isBuying = false;
	} else if (self.pri_grenade_state == 1) {
		W_ThrowBetty();
	} else  {
		centerprint (other, "No grenadetype defined...\n");
	}

	//if (!(self.flags & FL_ONGROUND)) {
	//	self.secondary_grenades = self.secondary_grenades + 1;
	//}

	startframe = GetFrame(self.weapon,TAKE_OUT_START);
	endframe = GetFrame(self.weapon,TAKE_OUT_END);
	modelname = GetWeaponModel(self.weapon, 0);
	Set_W_Frame (startframe, endframe, 0, 0, 0, SUB_Null, modelname, false, S_BOTH);
	self.semiswitch = false;

	SetUpdate(self, UT_HUD, 6, 0, 0);
}


void() checkHoldB =
{
	if (!self.button3)
	{
		if(self.grenade_delay < time)
			self.grenade_delay = time + 0.05;
		self.isBuying = true;
		Set_W_Frame (18, 23, 0, 5, GRENADE, W_ThrowBetty, "progs/VModels/v_betty.mdl", true, S_RIGHT);
		sound (self, CHAN_WEAPON, "sounds/weapons/grenade/throw.wav", 1, ATTN_NORM);
		self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = time + 0.4;
		self.throw_delay = time + 0.9;
	}
	else
	{    
		self.isBuying = true;
		Set_W_Frame (18, 18, 0, 0, GRENADE, checkHoldB, "progs/VModels/v_betty.mdl", true, S_RIGHT);
	}	
}

void() checkHold =
{
	if (self.pri_grenade_state == 1) {
		checkHoldB();
		return;
	}

	if (!self.button3 || self.grenade_delay < time)
	{
		if(self.grenade_delay < time)
			self.grenade_delay = time + 0.05;
			
		self.isBuying = true;  
		Set_W_Frame (3, 6, 0, 5, GRENADE, W_ThrowGrenade, "progs/VModels/v_nade.mdl", true, S_RIGHT);
		sound (self, CHAN_WEAPON, "sounds/weapons/grenade/throw.wav", 1, ATTN_NORM);
		self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = time + 0.4;
		self.throw_delay = time + 0.9;
	}
	else
	{
    	self.isBuying = true;
		Set_W_Frame (2, 2, 0, 0, GRENADE, checkHold, "progs/VModels/v_nade.mdl", true, S_RIGHT);
	}
}


void() W_Betty = {
	if (self.throw_delay > time || self.zoom || self.downed || self.secondary_grenades < 1 || self.isBuying)
		return;

	Set_W_Frame (0, 18, 0, 0, GRENADE, checkHoldB, "progs/VModels/v_betty.mdl", true, S_RIGHT);
	sound (self, CHAN_WEAPON, "sounds/weapons/grenade/prime.wav", 1, ATTN_NORM);	
	self.secondary_grenades -= 1;
	self.reload_delay2 = self.fire_delay2 = self.throw_delay = self.reload_delay = self.fire_delay = time + 6;
	self.semiswitch = true;
}

void() W_Grenade =
{
	if (self.throw_delay > time || self.zoom || self.downed || self.primary_grenades < 1 || self.isBuying)
		return;

	Set_W_Frame (0, 2, 0, 0, GRENADE, checkHold, "progs/VModels/v_nade.mdl", true, S_RIGHT);
	sound (self, CHAN_WEAPON, "sounds/weapons/grenade/prime.wav", 1, ATTN_NORM);	
	self.primary_grenades -= 1;
	self.reload_delay2 = self.fire_delay2 = self.throw_delay = self.reload_delay = self.fire_delay = time + 6;
	self.grenade_delay = time + 5;
    self.semiswitch = true;
} 

void(float wepnum) CheckButton = {
	W_PutOut();
}

void() Change_Stance = {

	if (self.downed || !(self.flags & FL_ONGROUND) || self.changestance == true || self.new_ofs_z != self.view_ofs_z)
		return;

	switch(self.stance) {
		case 2: 
			self.new_ofs_z = self.view_ofs_z - 24;
			self.stance = 1;
			break;
		case 1:
			if (self.isBuying) { //don't want to prone while buying a perk..
				self.stance = 2;
				self.new_ofs_z = self.view_ofs_z + 24;
			} else if (!self.stancereset) {
				self.new_ofs_z = self.view_ofs_z - 18;
				self.stance = 0;
			} else {
				self.new_ofs_z = self.view_ofs_z + 24;
				self.stance = 2;
				self.stancereset = 0;
			}
			break;
		case 0:
			self.new_ofs_z = self.view_ofs_z + 18;
			self.stance = self.stancereset = 1;
			break;
		default: break;
	}

}

void() dolphin_dive =		//naievil
{    
	if (self.stance != 2)
		return;
 	if (self.flags & FL_WATERJUMP)
		return;

	if (self.waterlevel >= 2)
	{
		if (self.watertype == CONTENT_WATER)
			self.velocity_z = 100;
		else if (self.watertype == CONTENT_SLIME)
			self.velocity_z = 80;
		else
			self.velocity_z = 50;
	}

	if (!(self.flags & FL_ONGROUND))
		return;
		
	if ( !(self.flags & FL_JUMPRELEASED) )
		return;		// don't pogo stick
		
  
	self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
	self.flags = self.flags - FL_ONGROUND;	// don't stairwalk
	makevectors (self.v_angle);
    self.velocity = self.velocity * 1.2;		
	self.velocity_z = self.velocity_z + 270;

	if (self.button2)
		self.button2 = 0;

	self.dive = 1;
	W_SprintStop();

	self.oldz = self.origin_z;
	self.new_ofs_z = self.view_ofs_z - 42;
	self.stance = 0;
}


void () Impulse_Functions =
{
	if (!self.impulse)
		return;
		
	switch (self.impulse)
	{		
		case 10:
			#ifdef PC
			// FTE handles jumping on PC, which we don't want.. so we use impulses to override.
			JumpCheck(1);
			#endif
			break;
		case 22:
			addmoney(self, 10000, 0);
			rounds += 4;
			break;
		case 23:
			#ifdef PC
			if (!checkMovement(forward))
				return;
			#endif
			if (self.dive || self.downed)
				return;
			switch(self.stance) {
				case 0:
					self.new_ofs_z = self.view_ofs_z + 42;
					self.stance = 2;
					break;
				case 1:
					self.new_ofs_z = self.view_ofs_z + 24;
					self.stance = 2;
					break;
				default: break;
			}
			W_SprintStart();
			break;
		case 24:
			W_SprintStop();
			break;
		case 25:
			#ifdef PSP
			switch_nade();
			#else
			W_Betty();
			#endif
			break;
		case 26:
		case 30:
			if (self.sprinting)
				dolphin_dive();
			else
				Change_Stance();
			break;
		#ifdef NX
		case 31:
			self.sprintflag = 0;
			break;
		case 32:
			self.sprintflag = 1;
			break;
		#endif
		/*case 110:
			CheckButton(1);
			break;
		case 111:
			CheckButton(0);
			break;	*/
		case 110:
		case 111:
			W_PutOut();
			break;	
		case 100:
			cvar_set("waypoint_mode", "1");
			
			local entity d;
			d = find(world,classname,"door_nzp_cost");
			while(d != world)
			{
				d.classname = "door_nzp";
				d = find(d,classname,"door_nzp_cost");
			}
			d = find(world,classname,"door_open");
			while(d != world)
			{
				d.classname = "door_nzp";
				d = find(d,classname,"door_open");
			}
			
			waypoint_mode = 1;
			break;
		default:
			#ifdef PC
			bprint(PRINT_HIGH, "Unknown impulse: ", ftos(self.impulse));
			#endif
			break;
	}
	
	self.impulse = 0;
};

void() CheckImpulses =
{
	self.impulse = 0;
}

void(entity ent) CheckPowerups =
{
	if (instakill_finished >= time)
	{
		if (instakill_finished < 4 + time)
		{
			if (insta_blink< time - 0.25)
				insta_blink = time + 0.25;
		}
		else if (instakill_finished < 7 + time)
		{
			if (insta_blink< time - 0.5)
				insta_blink = time + 0.5;
		}
		else if (instakill_finished < 10 + time)
		{
			if (insta_blink< time - 1)
				insta_blink = time + 1;
		}
		
		if (insta_blink < time)
			ent.insta_icon = true;
		else 
			ent.insta_icon = false;		
	}
	else if(instakill_finished)
	{
		instakill_finished = 0;
		
		ent.insta_icon = false;
	}
	
	if (x2_finished > time)
	{
		if (x2_finished < 4 + time)
		{
			if (x2_blink< time - 0.25)
				x2_blink = time + 0.25;
		}
		else if (x2_finished < 7 + time)
		{
			if (x2_blink< time - 0.5)
				x2_blink = time + 0.5;
		}
		else if (x2_finished < 10 + time)
		{
			if (x2_blink< time - 1)
				x2_blink = time + 1;
		}
		
		if (x2_blink < time)
			ent.x2_icon = true;
		else 
			ent.x2_icon = false;
	}
	else if(x2_finished)
	{
		x2_finished = 0;
		
		ent.x2_icon = false;
	}

}

void() CheckPlayer = 
{
	CheckPowerups(self);
	CheckRevive(self);

#ifdef NX
	if (!self.sprintflag && self.sprinting) {
		W_SprintStop();
	}
#endif 

	// FIXME - can't do frame independent stance changing.. ofs starts spazzing..
	if (self.view_ofs_z > self.new_ofs_z) {
			self.changestance = true;
			self.view_ofs_z = self.view_ofs_z - 1.5;
	} else if (self.view_ofs_z < self.new_ofs_z) {
			self.changestance = true;
			self.view_ofs_z = self.view_ofs_z + 1.5;
	} else {
		self.changestance = false;
	}

	if (self.view_ofs_z > 32) {
		self.view_ofs_z = 32;
		self.changestance = false;
	}
	
	/* Check player push start */
	entity ent;
	ent = findradius(self.origin, 70);
		
	while(ent)
	{
		if(ent.classname == "player" && ent != self && ent.downed && !self.downed)
		{
			useprint (self, 13, 0, 0);
			
			if (self.button7 && !ent.invoke_revive) {
				centerprint(ent, "Another player is reviving you...");
				ent.beingrevived = true;
				
				if (!self.progress_bar_percent) {
					self.movetype = MOVETYPE_NONE;
					Set_W_Frame (0, 21, 0, 0, SPRINT, SUB_Null, "models/v_morphine.mdl", false, S_BOTH);
					
					if !(self.perks & P_REVIVE)
						self.progress_bar_time = 4;
					else
						self.progress_bar_time = 2;
					
					self.progress_bar = self.progress_bar_time + time;     
					self.progress_bar_percent = 1;
					self.reviving = true;
				}
				
				if (self.revived) {
					self.movetype = MOVETYPE_WALK;
					W_TakeOut();
					ent.invoke_revive = 1;
					ent.beingrevived = false;
					self.reviving = 0;
					self.progress_bar = 0;
					self.progress_bar_time = 0;
					self.progress_bar_percent = 0;
					self.revived = 0;
				}
			}
			else if (!self.button7 && self.reviving) {
				self.movetype = MOVETYPE_WALK;
				ent.beingrevived = false;
				W_TakeOut();
				self.progress_bar = 0;
				self.progress_bar_time = 0;
				self.progress_bar_percent = 0;
				self.revived = 0;
				self.reviving = 0;
			}
		}
		else if(ent.classname == "player" && ent != self && !ent.downed) // small player push 
		{
			vector push;
			push =  ent.origin - self.origin;
			push_z = 0;
			push = normalize(push) * 0.5;
			
			ent.velocity += push;
		}
		ent = ent.chain;
	}
	/* Check for player push end */
	
	if (!self.button2 && self.flags & FL_ONGROUND) {
		if (self.dive) {
			if (self.perks & P_FLOP && fabs(self.oldz - self.origin_z) > 90) {
				sound (self, CHAN_WEAPON, "sounds/weapons/grenade/explode.wav", 1, ATTN_NORM);	
				DamgageExplode (self, self, 225, 75, 128);
				#ifdef PC
				te_customflash(self.origin, 128, 300, '1 1 1');
				#endif

				CallExplosion(self.origin);
			}
			self.dive = 0;
		}

		if (fabs(self.oldz - self.origin_z) > 90 && !(self.perks & P_FLOP)) {
			DamageHandler (self, other, 50, S_ZOMBIE);	

			if (self.health <= 10)
				GiveAchievement(7, self);	
		}
		
		self.oldz = self.origin_z;		
	}
}

void () Weapon_Logic =
{
	W_Frame_Update ();
	Impulse_Functions();

	#ifndef PC
	// For PSP only to tell our engine to display the scope 
	if ((self.scopetime < time) && self.scopetime) {
		self.scopetime = 0;
		self.zoom = 2;
		self.weapon2model = "";
		self.weaponmodel = "";
	}
	#else 
	UpdatePunchangle(self);
	#endif
			
	//FIXME - cleanup!
	if (IsDualWeapon(self.weapon)) { 
		if (self.button0) {
			#ifdef PC
			W_Fire(S_LEFT);
			#else
			W_Fire(S_RIGHT);
			#endif
		} else {
			#ifdef PC
			self.semi2 = FALSE;
			#else
			self.semi = FALSE;
			#endif
		}
		
		if (self.button8) {
			#ifdef PC
			W_Fire(S_RIGHT);
			#else
			W_Fire(S_LEFT);
			#endif
		} else {
			#ifdef PC
			self.semi = FALSE;
			#else
			self.semi2 = FALSE;
			#endif
		}
	} else {
		if (self.button0) {
			W_Fire(S_RIGHT);
		} else {
			self.semi = FALSE;
		}
		if (cvar("cl_adsmode")) {
			if (self.button8) {
				self.ads_toggle = !self.ads_toggle;

				if (self.ads_toggle == false) {
					W_AimOut();
					self.zoom = 0;

					#ifdef PC
					self.viewzoom = 1;
					UpdateVmodel(self.weaponmodel, GetWepSkin(self.weapon));
					UpdateV2model(self.weapon2model, 0);
					#endif
				} else {
					W_AimIn();
					self.zoom = 1;

					#ifdef PC
					self.viewzoom = 0.9;
					#endif
				}
			}
		} else {
			if (self.button8) {
				if (!self.zoom) {
					W_AimIn();
				} 
				#ifdef PC
				else {
				
					if (self.weapon == W_KAR_SCOPE || self.weapon == W_PTRS ||
						self.weapon == W_HEADCRACKER || self.weapon == W_PENETRATOR) {
						if (self.viewzoom > 0.5)
							self.viewzoom -= 0.05;
						else 
							self.viewzoom = 0.5;
					} else {
						if (self.viewzoom > 0.9)
							self.viewzoom -= 0.01;
						else
							self.viewzoom = 0.89999;
					}
				}
				#endif
			} else if (!self.button8 && self.zoom) {
			
				#ifdef PC
				if (self.weapon == W_KAR_SCOPE   || self.weapon == W_PTRS ||
					self.weapon == W_HEADCRACKER || self.weapon == W_PENETRATOR) {
					if (self.viewzoom == 0.5) {
						self.viewzoom += 0.05;
						ReturnWeaponModel();
					} else {
						UpdateVmodel(self.weaponmodel, GetWepSkin(self.weapon));
						UpdateV2model(self.weapon2model, 0);
						self.viewzoom += 0.05;
					}
				} else {
					if (self.viewzoom == 0.9) {
						W_AimOut();
					} else {
						self.viewzoom += 0.015;
					}
				}
				
				if (self.viewzoom >= 1) {
					self.viewzoom = 1;
					self.zoom = 0;
				}
				#else
				W_AimOut();
				#endif	
			}
		}
	}

	if (!self.button7) {
		self.semiuse = false;
	}
	
	if (self.button4 && !self.semiswitch && self.secondaryweapon && self.secondaryweapon !=0 && !self.zoom)
	{
		W_PutOut();
		self.semiswitch = true;
	} else if (!self.button4) {
		self.semiswitch = false;
	}
	
	if (self.button3 && self.isBuying != true && self.semiswitch != true)
	{
        if (self.pri_grenade_state == 0)
		    W_Grenade();
        else
            W_Betty();
		self.semiswitch = true;
	}
	else if (!self.button3)
		self.semiswitch = false;

	if (self.button5 && !self.semireload)
	{
		W_Reload(S_BOTH);
		self.semireload = TRUE;
	}
	else if (!self.button5) {
		self.semireload = FALSE;
	}
	
	if (self.button6 && !self.semiknife)
	{ 
		#ifdef PSP
		if (self.sprinting) {
			dolphin_dive();
			return;
		}
		#endif
		W_Knife();
		self.semiknife = true;
	}
	else if (!self.button6)
		self.semiknife = false;
	
	CheckImpulses();
	CheckPlayer();	
}
