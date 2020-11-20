//
// weapon_defines.qc - Wrapper for Weapon Stat Retrieval
//

// #defines for limb multipliers
#define	HEAD_X			0
#define	UPPER_TORSO_X	1
#define	LOWER_TORSO_X	2
#define	LIMBS_X			3

string(float perk) GetPerkName =
{
	switch (perk)
	{
		case 1:
			return "Quick Revive";
		case 2:
			return "Juggernog";
		case 3:
			return "Speed Cola";
		case 4:
			return "Double Tap";
		case 5:
			return "Stamin-Up";
		case 6:
			return "PhD Flopper";
		case 7:
			return "Deadshot Daiquiri";
		case 8:
			return "Mule Kick";
		default:
			return "NULL";
	}
}

string(float wep) GetWeaponName =
{
	return weapons[wep].name;
}

float(float wep) GetFiretype =
{
	return weapons[wep].fire_type;
}

float(float wep, float type) getWeaponMultiplier =
{
	switch(type) {
		case HEAD_X: return weapons[wep].multiplier_head;
		case UPPER_TORSO_X: return weapons[wep].multiplier_upper_torso;
		case LOWER_TORSO_X: return weapons[wep].multiplier_lower_torso;
		case LIMBS_X: return weapons[wep].multiplier_limbs;
	}

	return 0;
}

float(float wep) getWeaponMag =
{
	return weapons[wep].magazine_size;
}

float(float wep) getWeaponAmmo =
{
	return weapons[wep].reserve_size;
}


float(float wep) getWeaponDamage =
{
	return weapons[wep].damage;
}

float(float wep) GetWeaponShotcount =
{
	return weapons[wep].shotcount;
}

float(float wep, float penetration_times) getWeaponPenetration =
{
	if (!penetration_times)
		return 2;

	if (penetration_times >= weapons[wep].penetration_body_count) {
		return 0;
	} else {
		return weapons[wep].penetration_amount;
	}
}

float(float wep) GetWeaponSpread =
{
	return weapons[wep].bullet_spread;
}

float(float wep, float delaytype) getWeaponDelay =
{
	if (delaytype == RELOAD) {
		return weapons[wep].reload_delay;
	} else {
		return weapons[wep].fire_delay;
	}
}

float GetWeaponWalkSpeed(float perks, float wep)
{
	// get initial weapon walk speed
	local float weapon_speed;
	weapon_speed = weapons[wep].weapon_weight;

	// stamin-up multiplies this by 7%
	if (perks & P_STAMIN)
		weapon_speed *= 1.07;

	return weapon_speed;
}

vector GetWeaponADSPos(float wep) {
	return weapons[wep].ads_position_pc;
}

/*
===========================
Weapon PSP ADS Declarations
===========================
*/

vector GetWeaponADSOfs_PSP(float wep) = 
{
	return weapons[wep].ads_position_console;
};

// MotoLegacy - what is 'z'??
float(float wep, float frametype, optional float z) GetFrame =
{
	switch(frametype) {
		case FIRE_START:
			return weapons[wep].frames[FRAME_FIRE_START];
		case FIRE_END:
			return weapons[wep].frames[FRAME_FIRE_END];
		case RELOAD_START:
			return weapons[wep].frames[FRAME_RELOAD_START];
		case RELOAD_END:
			return weapons[wep].frames[FRAME_RELOAD_END];
		case RELOAD_CANCEL:
			return weapons[wep].frames[FRAME_RELOAD_CANCEL];
		case SPRINT_IN_START:
			return weapons[wep].frames[FRAME_SPRINT_IN_START];
		case SPRINT_IN_END:
			return weapons[wep].frames[FRAME_SPRINT_IN_END];
		case SPRINT_START:
			return weapons[wep].frames[FRAME_SPRINT_START];
		case SPRINT_END:
			return weapons[wep].frames[FRAME_SPRINT_END];
		case SPRINT_OUT_START:
			return weapons[wep].frames[FRAME_SPRINT_OUT_START];
		case SPRINT_OUT_END:
			return weapons[wep].frames[FRAME_SPRINT_OUT_END];
		case TAKE_OUT_START:
			return weapons[wep].frames[FRAME_TAKE_OUT_START];
		case TAKE_OUT_END:
			return weapons[wep].frames[FRAME_TAKE_OUT_END];
		case PUT_OUT_START:
			return weapons[wep].frames[FRAME_PUT_OUT_START];
		case PUT_OUT_END:
			return weapons[wep].frames[FRAME_PUT_OUT_END];
	}

	return 0;
}

string(float wep, float gorvmodel) GetWeaponModel =
{
	if (gorvmodel) {
		return weapons[wep].world_model;
	} else {
		return weapons[wep].view_model;
	}
}

string(float wep) GetWeapon2Model =
{
	return weapons[wep].view_model_accessory;
}

string(float wep) GetWeaponSound =
{
	return weapons[wep].fire_sound;
}

float(float wep) IsDualWeapon = {
	return weapons[wep].is_dual_weapon;
}

string(float wep) GetLeftWeaponModel = {
	return weapons[wep].left_view_model;
}

float(float wep) IsPapWeapon = {
	return weapons[wep].is_packed;
}

float(float wep) GetWepSkin = {
	return weapons[wep].model_skin;
}


float(float wep)  EqualNonPapWeapon = 
{
	return weapons[wep].non_packed_id;
}

float(float wep)  EqualPapWeapon = 
{
	return weapons[wep].packed_id;
}

void (float wep, float anim_style, float dualwep, float curweaponframe)	PlayWeaponSound =
{
#ifndef NX
	if (anim_style == KNIFE) {
		if (curweaponframe == 6) {
			self.punchangle_x = -2;
			self.punchangle_y = -5;	
		} else if (curweaponframe == 7) {
			self.punchangle_x = 5;
			self.punchangle_y = 10;
		}
	}
#endif

	local float iterate;
	for (iterate = 0; iterate < 8; iterate++) {
		if (curweaponframe == weapons[wep].frame_sound_number[iterate])
			sound(self, 5, weapons[wep].frame_sound_name[iterate], 1, ATTN_NORM);
	}
}


void(float wep) precache_extra =
{
	local float iterate;

	// models
	for (iterate = 0; iterate < 4; iterate++) {
		if (weapons[wep].precache_models[iterate] != "")
			precache_model(weapons[wep].precache_models[iterate]);
	}

	// sounds
	for (iterate = 0; iterate < 8; iterate++) {
		if (weapons[wep].precache_sounds[iterate] != "")
			precache_sound(weapons[wep].precache_sounds[iterate]);
	}
}

float(float wep) getWeaponRecoilReturn =
{
	return weapons[wep].recoil;
}

float(float wep, float stance) CrossHairWeapon =
{
	local float crosshair_minimum;
	crosshair_minimum = weapons[wep].crosshair_minimum_range;

	// MotoLegacy - FIXME - this is dumb and inconsistent
	if (crosshair_minimum == 0)
		return 0;
	else {
		switch(stance) {
			case 2:
				return crosshair_minimum;
			case 1:
				return crosshair_minimum - 2;
			case 0:
				return crosshair_minimum - 4;
			default: return 0;
		}
	}
}

float(float wep, float stance) CrossHairMaxSpread =
{
	local float crosshair_maximum;
	crosshair_maximum = weapons[wep].crosshair_maximum_range;

	// MotoLegacy - FIXME - this is dumb and inconsistent
	if (crosshair_maximum == 0)
		return 0;
	else {
		switch(stance) {
			case 2:
				return crosshair_maximum;
			case 1:
				return crosshair_maximum - 2;
			case 0:
				return crosshair_maximum - 4;
			default: return 0;
		}
	}
}

float(float wep, float type) GetLowAmmo = // determine what ammo value you should have that turns shells red
{
	if (type) {
		return weapons[wep].magazine_low;
	} else {
		return weapons[wep].reserve_low;
	}
}

// PSP Specific!!
vector(float wep) GetWeaponRecoil =
{
	local vector guaranteed, kick_change, final_kick;
	local float change_1, change_2, change_3,total_recoil, r, temp1, temp2;

	guaranteed = weapons[wep].recoil_guaranteed;
	kick_change = weapons[wep].recoil_kick_change;

	total_recoil = kick_change_x + kick_change_y + kick_change_z;

	change_1 = (kick_change_x)/total_recoil;
	change_2 = (kick_change_y)/total_recoil;
	change_3 = (kick_change_z)/total_recoil;

	r = random();
	temp1 = change_1 + change_2;
	temp2 = change_1 + change_2 + change_3;
	
	#ifndef PSP
	if (r < change_1)
		final_kick_y = kick_change_x*0.25;
	else if (r < temp1)
		final_kick_x = kick_change_y*-1*.25;
	else if (r < temp2)
		final_kick_y = kick_change_z*-1*0.25;
	#else
	if (r < change_1)
		final_kick_y = kick_change_x;
	else if (r < temp1)
		final_kick_x = kick_change_y*-1;
	else if (r < temp2)
		final_kick_y = kick_change_z*-1;
	#endif

	final_kick_y = final_kick_y + guaranteed_x;
	final_kick_x = final_kick_x - guaranteed_y;
	final_kick_y = final_kick_y - guaranteed_z;

	final_kick_x = final_kick_x / 10;
	final_kick_y = final_kick_y / 10;
	final_kick_z = final_kick_z / 10;

	return final_kick;
}

// Flash offset is multiplied because vectors have limited precision within qc
vector (float wep) GetWeaponFlash_Offset = 
{
	// MotoLegacy - FIXME: why does NX use different values?
	return weapons[wep].muzzle_flash_offset;
}

float (float wep) GetWeaponFlash_Size = {
	return weapons[wep].muzzle_flash_size;
}
