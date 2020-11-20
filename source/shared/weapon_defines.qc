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

float(float wep, float frametype, optional float z) GetFrame =
{
	switch (wep)
	{
		case W_COLT:
			switch (frametype)
			{
				case FIRE_START:
				#ifndef PC
					return 1;
				#else 
					return 0;
				#endif
				case FIRE_END:
					return 2;
				case RELOAD_START:
					return 3;
				case RELOAD_END:
					return 26;
				case SPRINT_IN_START:
					return 33;
				case SPRINT_IN_END:
					return 34;
				case SPRINT_START:
					return 35;
				case SPRINT_END:
					return 40;
				case SPRINT_OUT_START:
					return 41;
				case SPRINT_OUT_END:
					return 42;
				case TAKE_OUT_START:
					return 29;
				case TAKE_OUT_END:
					return 32;
				case PUT_OUT_START:
					return 26;
				case PUT_OUT_END:
					return 29;
				case RELOAD_CANCEL:
					return 13;
			}
			break;
		case W_BIATCH:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 2;
				case RELOAD_START:
					return 3;
				case RELOAD_END:
					return 36;
				case SPRINT_IN_START:
					return 33;
				case SPRINT_IN_END:
					return 34;
				case SPRINT_START:
					return 44;
				case SPRINT_END:
					return 43;
				case SPRINT_OUT_START:
					return 50;
				case SPRINT_OUT_END:
					return 42;
				case TAKE_OUT_START:
					return 39;
				case TAKE_OUT_END:
					return 42;
				case PUT_OUT_START:
					return 36;
				case PUT_OUT_END:
					return 39;
				case RELOAD_CANCEL:
					return 13;
			}
			break;
		case W_KAR:
		case W_ARMAGEDDON:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 3;
				case RELOAD_START:
					return 14;
				case RELOAD_END:
					return 28;
				case SPRINT_IN_START:
					return 29;
				case SPRINT_IN_END:
					return 30;
				case SPRINT_OUT_START:
					return 30;
				case SPRINT_OUT_END:
					return 29;
				case TAKE_OUT_START:
					return 33;
				case TAKE_OUT_END:
					return 35;
				case PUT_OUT_START:
					return 32;
				case PUT_OUT_END:
					return 33;
				case RELOAD_CANCEL:
					return 21;
			}	
			break;
		case W_THOMPSON:
		case W_GIBS:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 2;
				case RELOAD_START:
					return 3;
				case RELOAD_END:
					return 25;
				case SPRINT_IN_START:
					return 26;
				case SPRINT_IN_END:
					return 27;
				case SPRINT_OUT_START:
					return 28;
				case SPRINT_OUT_END:
					return 29;
				case TAKE_OUT_START:
					return 32;
				case TAKE_OUT_END:
					return 35;
				case PUT_OUT_START:
					return 29;
				case PUT_OUT_END:
					return 32;
				case RELOAD_CANCEL:
					return 15;
			}
			break;
		case W_357:
		case W_KILLU:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 3;
				case RELOAD_START:
					return 4;
				case RELOAD_END:
					return 25;
				case SPRINT_IN_START:
					return 32;
				case SPRINT_IN_END:
					return 33;
				case SPRINT_START:
					return 35;
				case SPRINT_END:
					return 40;
				case SPRINT_OUT_START:
					return 41;
				case SPRINT_OUT_END:
					return 42;
				case TAKE_OUT_START:
					return 29;
				case TAKE_OUT_END:
					return 31;
				case PUT_OUT_START:
					return 26;
				case PUT_OUT_END:
					return 28;
				case RELOAD_CANCEL:
					return 14;
			}
			break;
		case W_BAR:
		case W_WIDOW:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 2;
				case RELOAD_START:
					return 3;
				case RELOAD_END:
					return 36;
				case SPRINT_IN_START:
					return 37;
				case SPRINT_IN_END:
					return 38;
				case SPRINT_OUT_START:
					return 38;
				case SPRINT_OUT_END:
					return 37;
				case TAKE_OUT_START:
					return 41;
				case TAKE_OUT_END:
					return 39;
				case PUT_OUT_START:
					return 39;
				case PUT_OUT_END:
					return 41;
				case RELOAD_CANCEL:
					return 21;
			}
			break;
		case W_BROWNING:
		case W_ACCELERATOR:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 3;
				case RELOAD_START:
					return 4;
				case RELOAD_END:
					return 37;
				case SPRINT_IN_START:
					return 92;
				case SPRINT_IN_END:
					return 93;
				case SPRINT_OUT_START:
					return 95;
				case SPRINT_OUT_END:
					return 96;
				case TAKE_OUT_START:
					return 100;
				case TAKE_OUT_END:
					return 103;
				case PUT_OUT_START:
					return 97;
				case PUT_OUT_END:
					return 100;
				case RELOAD_CANCEL:
					return 16;
			}
			break;
		case W_SAWNOFF:
		case W_DB:
		case W_BORE:
				switch (frametype)
				{
					case FIRE_START:
						return 1;
					case FIRE_END:
						return 4;
					case RELOAD_START:
						return 5;
					case RELOAD_END:
						return 31;
					case SPRINT_IN_START:
						return 32;
					case SPRINT_IN_END:
						return 33;
					case SPRINT_OUT_START:
						return 33;
					case SPRINT_OUT_END:
						return 31;
					case TAKE_OUT_START:
						return 38;
					case TAKE_OUT_END:
						return 41;
					case PUT_OUT_START:
						return 35;
					case PUT_OUT_END:
						return 37;
					case RELOAD_CANCEL:
						return 22;
				}
				break;
		case W_SNUFF:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 4;
				case RELOAD_START:
					return 5;
				case RELOAD_END:
					return 45;
				case SPRINT_IN_START:
					return 53;
				case SPRINT_IN_END:
					return 58;
				case SPRINT_OUT_START:
					return 33;
				case SPRINT_OUT_END:
					return 31;
				case TAKE_OUT_START:
					return 46;
				case TAKE_OUT_END:
					return 49;
				case PUT_OUT_START:
					return 59;
				case PUT_OUT_END:
					return 52;
				case RELOAD_CANCEL:
					return 34;
			}
			break;
		case W_FG:
		case W_IMPELLER:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 3;
				case RELOAD_START:
					return 41;
				case RELOAD_END:
					return 88;
				case SPRINT_IN_START:
					return 29;
				case SPRINT_IN_END:
					return 33;
				case SPRINT_OUT_START:
					return 34;
				case SPRINT_OUT_END:
					return 37;
				case TAKE_OUT_START:
					return 8;
				case TAKE_OUT_END:
					return 15;
				case PUT_OUT_START:
					return 3;
				case PUT_OUT_END:
					return 7;
				case RELOAD_CANCEL:
					return 64;
			}
			break;
		case W_GEWEHR:
		case W_COMPRESSOR:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 2;
				case RELOAD_START:
					return 3;
				case RELOAD_END:
					return 38;
				case SPRINT_IN_START:
					return 49;
				case SPRINT_IN_END:
					return 49;
				case SPRINT_OUT_START:
					return 51;
				case SPRINT_OUT_END:
					return 52;
				case TAKE_OUT_START:
					return 55;
				case TAKE_OUT_END:
					return 59;
				case PUT_OUT_START:
					return 53;
				case PUT_OUT_END:
					return 56;
				case RELOAD_CANCEL:
					return 16;
			}
			break;
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
				switch (frametype)
				{
					case FIRE_START:
						return 1;
					case FIRE_END:
						return 3;
					case SPRINT_IN_START:
						return 36;
					case SPRINT_IN_END:
						return 37;
					case SPRINT_OUT_START:
						return 37;
					case SPRINT_OUT_END:
						return 36;
					case TAKE_OUT_START:
						return 33;
					case TAKE_OUT_END:
						return 35;
					case PUT_OUT_START:
						return 32;
					case PUT_OUT_END:
						return 33;
					case RELOAD_CANCEL:
						return 21;
				}
				break;
		case W_M1:
		case W_M1000:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 3;
				case RELOAD_START:
					return 8;
				case RELOAD_END:
					return 44;
				case SPRINT_IN_START:
					return 58;
				case SPRINT_IN_END:
					return 59;
				case SPRINT_OUT_START:
					return 60;
				case SPRINT_OUT_END:
					return 61;
				case TAKE_OUT_START:
					return 59;
				case TAKE_OUT_END:
					return 63;
				case PUT_OUT_START:
					return 56;
				case PUT_OUT_END:
					return 59;
				case RELOAD_CANCEL:
					return 16;
			}
			break;
		case W_M1A1:
		case W_WIDDER:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 2;
				case RELOAD_START:
					return 3;
				case RELOAD_END:
					return 29;
				case SPRINT_IN_START:
					return 37;
				case SPRINT_IN_END:
					return 38;
				case SPRINT_OUT_START:
					return 38;
				case SPRINT_OUT_END:
					return 37;
				case TAKE_OUT_START:
					return 33;
				case TAKE_OUT_END:
					return 36;
				case PUT_OUT_START:
					return 30;
				case PUT_OUT_END:
					return 33;
				case RELOAD_CANCEL:
					return 17;
			}
			break;
		case W_FIW:
		case W_M2:
			switch (frametype)
			{
				case FIRE_START:
					return 0;
				case FIRE_END:
					return 0;
				case SPRINT_IN_START:
					return 0;
				case SPRINT_IN_END:
					return 0;
				case SPRINT_OUT_START:
					return 8;
				case SPRINT_OUT_END:
					return 0;
				case TAKE_OUT_START:
					return 2;
				case TAKE_OUT_END:
					return 1;
				case PUT_OUT_START:
					return 1;
				case PUT_OUT_END:
					return 2;
				case RELOAD_CANCEL:
					return 0;
			}
			break;
		case W_MP40:
		case W_AFTERBURNER:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 2;
				case RELOAD_START:
					return 3;
				case RELOAD_END:
					return 21;
				case SPRINT_IN_START:
					return 37;
				case SPRINT_IN_END:
					return 38;
				case SPRINT_OUT_START:
					return 39;
				case SPRINT_OUT_END:
					return 40;
				case TAKE_OUT_START:
					return 32;
				case TAKE_OUT_END:
					return 35;
				case PUT_OUT_START:
					return 30;
				case PUT_OUT_END:
					return 32;
				case RELOAD_CANCEL:
					return 16;
			}
			break;
		case W_MG:
		case W_BARRACUDA:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 2;
				case RELOAD_START:
					return 3;
				case RELOAD_END:
					return 38;
				case SPRINT_IN_START:
					return 39;
				case SPRINT_IN_END:
					return 40;
				case SPRINT_OUT_START:
					return 40;
				case SPRINT_OUT_END:
					return 38;
				case TAKE_OUT_START:
					return 43;
				case TAKE_OUT_END:
					return 47;
				case PUT_OUT_START:
					return 42;
				case PUT_OUT_END:
					return 43;
				case RELOAD_CANCEL:
					return 21;
			}
			break;
		case W_PANZER:
		case W_LONGINUS:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 6;
				case RELOAD_START:
					return 7;
				case RELOAD_END:
					return 28;
				case SPRINT_IN_START:
					return 37;
				case SPRINT_IN_END:
					return 38;
				case SPRINT_OUT_START:
					return 45;
				case SPRINT_OUT_END:
					return 45;
				case TAKE_OUT_START:
					return 44;
				case TAKE_OUT_END:
					return 45;
				case PUT_OUT_START:
					return 39;
				case PUT_OUT_END:
					return 42;
				case RELOAD_CANCEL:
					return 16;
				case AIM_IN_END:
					return 33;
			}
			break;
		case W_PPSH:
		case W_REAPER:
			switch (frametype)
			{
				case FIRE_START:
					return 0;
				case FIRE_END:
					return 0;
				case RELOAD_START:
					return 4;
				case RELOAD_END:
					return 34;
				case SPRINT_IN_START:
					return 44;
				case SPRINT_IN_END:
					return 45;
				case SPRINT_OUT_START:
					return 47;
				case SPRINT_OUT_END:
					return 49;
				case TAKE_OUT_START:
					return 46;
				case TAKE_OUT_END:
					return 49;
				case PUT_OUT_START:
					return 43;
				case PUT_OUT_END:
					return 46;
				case RELOAD_CANCEL:
					return 16;
			}
			break;
		case W_PTRS:
		case W_PENETRATOR:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 4;
				case RELOAD_START:
					return 5;
				case RELOAD_END:
					return 32;
				case SPRINT_IN_START:
					return 48;
				case SPRINT_IN_END:
					return 50;
				case SPRINT_OUT_START:
					return 51;
				case SPRINT_OUT_END:
					return 54;
				case TAKE_OUT_START:
					return 44;
				case TAKE_OUT_END:
					return 47;
				case PUT_OUT_START:
					return 41;
				case PUT_OUT_END:
					return 44;
				case RELOAD_CANCEL:
					return 16;
			}
			break;
    	case W_RAY:
    	case W_PORTER:
			switch (frametype)
			{
				case FIRE_START:
					return 3;
				case FIRE_END:
					return 7;
				case RELOAD_START:
					return 9;
				case RELOAD_END:
					return 54;
				case SPRINT_IN_START:
					return 60;
				case SPRINT_IN_END:
					return 64;
				case SPRINT_OUT_START:
					return 70;
				case SPRINT_OUT_END:
					return 73;
				case TAKE_OUT_START:
					return 57;
				case TAKE_OUT_END:
					return 59;
				case PUT_OUT_START:
					return 54;
				case PUT_OUT_END:
					return 56;
				case RELOAD_CANCEL:
					return 36;
			}
			break;
		case W_STG:
   	 	case W_SPATZ:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 2;
				case RELOAD_START:
					return 3;
				case RELOAD_END:
					return 24;
				case SPRINT_IN_START:
					return 40;
				case SPRINT_IN_END:
					return 42;
				case SPRINT_OUT_START:
					return 43;
				case SPRINT_OUT_END:
					return 45;
				case TAKE_OUT_START:
					return 42;
				case TAKE_OUT_END:
					return 46;
				case PUT_OUT_START:
					return 39;
				case PUT_OUT_END:
					return 42;
				case RELOAD_CANCEL:
					return 16;
			}
			break;
		case W_TRENCH:
   	 	case W_GUT:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 3;
				case SPRINT_IN_START:
					return 27;
				case SPRINT_IN_END:
					return 28;
				case SPRINT_OUT_START:
					return 27;
				case SPRINT_OUT_END:
					return 26;
				case TAKE_OUT_START:
					return 32;
				case TAKE_OUT_END:
					return 36;
				case PUT_OUT_START:
					return 30;
				case PUT_OUT_END:
					return 32;
				case RELOAD_CANCEL:
					return 20;
			}
			break;
		case W_TYPE:
   	 	case W_SAMURAI:
			switch (frametype)
			{
				case FIRE_START:
					return 0;
				case FIRE_END:
					return 1;
				case RELOAD_START:
					return 2;
				case RELOAD_END:
					return 24;
				case SPRINT_IN_START:
					return 35;
				case SPRINT_IN_END:
					return 37;
				case SPRINT_OUT_START:
					return 38;
				case SPRINT_OUT_END:
					return 40;
				case TAKE_OUT_START:
					return 38;
				case TAKE_OUT_END:
					return 41;
				case PUT_OUT_START:
					return 35;
				case PUT_OUT_END:
					return 38;
				case RELOAD_CANCEL:
					return 16;
				case AIM_IN_END:
					return 28;
				case AIM_IN_START:
					return 27;
			}
			break;
		case W_TESLA:
		case W_DG3:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 4;
				case RELOAD_START:
					return 9;
				case RELOAD_END:
					return 58;
				case SPRINT_IN_START:
					return 60;
				case SPRINT_IN_END:
					return 63;
				case SPRINT_OUT_START:
					return 63;
				case SPRINT_OUT_END:
					return 66;
				case TAKE_OUT_START:
					return 72;
				case TAKE_OUT_END:
					return 76;
				case PUT_OUT_START:
					return 66;
				case PUT_OUT_END:
					return 71;
				case RELOAD_CANCEL:
					return 16;
			}
			break;
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
	if (anim_style == FIRE)
	{
		if (wep == W_KAR || wep == W_ARMAGEDDON || wep == W_KAR_SCOPE || wep == W_HEADCRACKER)
		{
			if (curweaponframe == 6)
				sound (self ,5, "sounds/weapons/kar/boltup.wav", 1, ATTN_NORM);
			else if (curweaponframe == 7)
				sound (self ,5, "sounds/weapons/kar/boltback.wav", 1, ATTN_NORM);
			else if (curweaponframe == 9)
				sound (self ,5, "sounds/weapons/kar/boltforward.wav", 1, ATTN_NORM);
			else if (curweaponframe == 10)
				sound (self ,5, "sounds/weapons/kar/boltdown.wav", 1, ATTN_NORM);
		}
		else if (wep == W_TRENCH || wep == W_GUT)
		{
			if (curweaponframe == 7)
				sound (self ,5, "sounds/weapons/shotgun/pump.wav", 1, ATTN_NORM);
		}
	} else if (anim_style != RELOAD) {
		return;
	}


	switch (wep) {
		case W_COLT:
			if (curweaponframe == 5) {
				sound (self ,5, "sounds/weapons/colt/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 12) {
				sound (self ,5, "sounds/weapons/colt/magin.wav", 1, ATTN_NORM);
			} else if(curweaponframe == 18) {
				sound (self ,5, "sounds/weapons/colt/slide.wav", 1, ATTN_NORM);
			}
			break;
		case W_KAR:
		case W_ARMAGEDDON:
			if (curweaponframe == 15) {
				sound (self ,5, "sounds/weapons/kar/boltup.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 16) {
				sound (self ,5, "sounds/weapons/kar/boltback.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 20) {
				sound (self ,5, "sounds/weapons/kar/clipin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 25) {
				sound (self ,5, "sounds/weapons/kar/boltforward.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 26) {
				sound (self ,5, "sounds/weapons/kar/clipoff.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 27) {
				sound (self ,5, "sounds/weapons/kar/boltdown.wav", 1, ATTN_NORM);
			}
			break;
		case W_THOMPSON:
		case W_GIBS:
			if (curweaponframe == 6) {
				sound (self ,5, "sounds/weapons/thomp/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 12) {
				sound (self ,5, "sounds/weapons/thomp/magin.wav", 1, ATTN_NORM);}
			else if (curweaponframe == 19) {
				sound (self ,5, "sounds/weapons/thomp/boltback.wav", 1, ATTN_NORM);
			}
			break;
		case W_357:
		case W_KILLU:
			if (curweaponframe == 5) {
				sound (self ,5, "sounds/weapons/357/open.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 9) {
				sound (self ,5, "sounds/weapons/357/out.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 15) {
				sound (self ,5, "sounds/weapons/357/in.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 20) {
				sound (self ,5, "sounds/weapons/357/close.wav", 1, ATTN_NORM);
			}
			break;
		case W_BAR:
    	case W_WIDOW:
			if (curweaponframe == 6  || curweaponframe == 31) {
				sound (self ,5, "sounds/weapons/bar/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 19 || curweaponframe == 29) {
				sound (self ,5, "sounds/weapons/bar/magin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 23) {
				sound (self ,5, "sounds/weapons/bar/maghit.wav", 1, ATTN_NORM);
			}
			break;
		case W_BROWNING:
		case W_ACCELERATOR:
			if (curweaponframe == 9) {
				sound (self ,5, "sounds/weapons/browning/boltback.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 16) {
				sound (self ,5, "sounds/weapons/browning/topopen.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 22) {
				sound (self ,5, "sounds/weapons/browning/chainoff.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 32) {
				sound (self ,5, "sounds/weapons/browning/boltback.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 39) {
				sound (self ,5, "sounds/weapons/browning/topopen.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 49) {
				sound (self ,5, "sounds/weapons/browning/chainon.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 53) {
				sound (self ,5, "sounds/weapons/browning/chainplace.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 58) {
				sound (self ,5, "sounds/weapons/browning/topclose.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 61) {
				sound (self ,5, "sounds/weapons/browning/tophit.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 70) {
				sound (self ,5, "sounds/weapons/browning/boltforward.wav", 1, ATTN_NORM);
			}
			break;
		case W_DB:
		case W_SAWNOFF:
		case W_BORE:
			if (curweaponframe == 6) {
				sound (self ,5, "sounds/weapons/shotgun/open.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 12) {
				sound (self ,5, "sounds/weapons/shotgun/out.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 20) {
				sound (self ,5, "sounds/weapons/shotgun/in.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 26) {
				sound (self ,5, "sounds/weapons/shotgun/close.wav", 1, ATTN_NORM);
			}
			break;
		case W_SNUFF:
			if (curweaponframe == 15) {
				sound (self ,5, "sounds/weapons/shotgun/open.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 23) {
				sound (self ,5, "sounds/weapons/shotgun/out.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 33) {
				sound (self ,5, "sounds/weapons/shotgun/in.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 40) {
				sound (self ,5, "sounds/weapons/shotgun/close.wav", 1, ATTN_NORM);
			}
			break;
		case W_FG:
		case W_IMPELLER:
			if (curweaponframe == 43) {
				sound (self ,5, "sounds/weapons/fg42/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 60) {
				sound (self ,5, "sounds/weapons/fg42/magin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 72) {
				sound (self ,5, "sounds/weapons/fg42/boltback.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 77) {
				sound (self ,5, "sounds/weapons/fg42/boltforward.wav", 1, ATTN_NORM);
			}
			break;
		case W_GEWEHR:
		case W_COMPRESSOR:
			if (curweaponframe == 10) {
				sound (self ,5, "sounds/weapons/gewehr/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 24) {
				sound (self ,5, "sounds/weapons/gewehr/magin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 27) {
				sound (self ,5, "sounds/weapons/gewehr/maghit.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 33) {
				sound (self ,5, "sounds/weapons/gewehr/boltrelease.wav", 1, ATTN_NORM);
			}
			break;
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
			if (curweaponframe == 15) {
				sound (self ,5, "sounds/weapons/kar/boltup.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 16) {
				sound (self ,5, "sounds/weapons/kar/boltback.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 20) {
				sound (self ,5, "sounds/weapons/kar/insert.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 25) {
				sound (self ,5, "sounds/weapons/kar/boltforward.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 27) {
				sound (self ,5, "sounds/weapons/kar/boltdown.wav", 1, ATTN_NORM);
			}
			break;
		case W_M1:
		case W_M1000:
			if (curweaponframe == 6) {
				sound (self ,5, "sounds/weapons/garand/clipout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 20) {
				sound (self ,5, "sounds/weapons/garand/clipin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 26) {
				sound (self ,5, "sounds/weapons/garand/clippush.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 37) {
				sound (self ,5, "sounds/weapons/garand/boltrelease.wav", 1, ATTN_NORM);
			}
			break;
		case W_M1A1:
		case W_WIDDER:
			if (curweaponframe == 6) {
				sound (self ,5, "sounds/weapons/m1carbine/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 14) {
				sound (self ,5, "sounds/weapons/m1carbine/magin.wav", 1, ATTN_NORM);
			} else if(curweaponframe == 16) {
				sound (self ,5, "sounds/weapons/m1carbine/maghit.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 24) {
				sound (self ,5, "sounds/weapons/m1carbine/bolt.wav", 1, ATTN_NORM);
			}
			break;
		case W_MP40:
		case W_AFTERBURNER:
			if (curweaponframe == 10) {
				sound (self ,5, "sounds/weapons/mp40/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 17) {
				sound (self ,5, "sounds/weapons/mp40/magin.wav", 1, ATTN_NORM);
			}
			break;
		case W_PANZER:
		case W_LONGINUS:
			if (curweaponframe == 12) {
				sound (self ,5, "sounds/weapons/panzer/move.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 16) {
				sound (self ,5, "sounds/weapons/panzer/insert.wav", 1, ATTN_NORM);
			}
			break;
		case W_MG:
		case W_BARRACUDA:
			if (curweaponframe == 8) {
				sound (self ,5, "sounds/weapons/mg42/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 19) {
				sound (self ,5, "sounds/weapons/mg42/magin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 29) {
				sound (self ,5, "sounds/weapons/mg42/charge.wav", 1, ATTN_NORM);
			}
			break;
		case W_PPSH:
    	case W_REAPER:
				if (curweaponframe == 7) {
				sound (self ,5, "sounds/weapons/ppsh/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 15) {
				sound (self ,5, "sounds/weapons/ppsh/magin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 19) {
				sound (self ,5, "sounds/weapons/ppsh/maghit.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 26) {
				sound (self ,5, "sounds/weapons/ppsh/boltback.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 28) {
				sound (self ,5, "sounds/weapons/ppsh/boltrelease.wav", 1, ATTN_NORM);
			}
			break;
		case W_PTRS:
		case W_PENETRATOR:
			if (curweaponframe == 6) {
				sound (self ,5, "sounds/weapons/ptrs/open.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 18) {
				sound (self ,5, "sounds/weapons/ptrs/magin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 21) {
				sound (self ,5, "sounds/weapons/ptrs/maghit.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 27) {
				sound (self ,5, "sounds/weapons/ptrs/close.wav", 1, ATTN_NORM);
			}
			break;
		case W_RAY:
		case W_PORTER:
			if (curweaponframe == 14) {
				sound (self ,5, "sounds/weapons/raygun/open.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 23) {
				sound (self ,5, "sounds/weapons/raygun/out.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 36) {
				sound (self ,5, "sounds/weapons/raygun/in.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 45) {
				sound (self ,5, "sounds/weapons/raygun/close.wav", 1, ATTN_NORM);
			}
			break;
		case W_STG:
		case W_SPATZ:
			if (curweaponframe == 11) {
				sound (self ,5, "sounds/weapons/stg/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 21) {
				sound (self ,5, "sounds/weapons/stg/magin.wav", 1, ATTN_NORM);
			}
			break;
		case W_TRENCH:
		case W_GUT:
			if (curweaponframe == 19) {
				sound (self ,5, "sounds/weapons/shotgun/insert.wav", 1, ATTN_NORM);
			}
			break;
		case W_TYPE:
		case W_SAMURAI:
			if (curweaponframe == 6) {
				sound (self ,5, "sounds/weapons/type100/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 15) {
				sound (self ,5, "sounds/weapons/type100/magin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 20) {
				sound (self ,5, "sounds/weapons/type100/boltpull.wav", 1, ATTN_NORM);
			}
			break;
		case W_BIATCH:
			if (curweaponframe == 10) {
				sound (self ,5, "sounds/weapons/colt/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 19) {
				sound (self ,5, "sounds/weapons/colt/magin.wav", 1, ATTN_NORM);
			} else if(curweaponframe == 26) {
				sound (self ,5, "sounds/weapons/colt/slide.wav", 1, ATTN_NORM);
			}
			break;
		case W_TESLA:
		case W_DG3:
			if (curweaponframe == 20)
				sound (self ,5, "sounds/weapons/tesla/switchoff.wav", 1, ATTN_NORM);
			else if (curweaponframe == 25)
				sound (self ,5, "sounds/weapons/tesla/pulllever.wav", 1, ATTN_NORM);
			else if (curweaponframe == 31)
				sound (self ,5, "sounds/weapons/tesla/glassbreak.wav", 1, ATTN_NORM);
			else if (curweaponframe == 38)
				sound (self ,5, "sounds/weapons/tesla/clipin.wav", 1, ATTN_NORM);
			else if (curweaponframe == 43)
				sound (self ,5, "sounds/weapons/tesla/clipoff.wav", 1, ATTN_NORM);
			else if (curweaponframe == 51)
				sound (self ,5, "sounds/weapons/tesla/switchon.wav", 1, ATTN_NORM);
	}
}


void(float weptype) precache_extra =
{

	switch (weptype) {
		case W_COLT:
		case W_BIATCH:
			precache_sound("sounds/weapons/colt/shoot.wav");
			precache_sound("sounds/weapons/colt/magout.wav");
			precache_sound("sounds/weapons/colt/magin.wav");
			precache_sound("sounds/weapons/colt/slide.wav");
			precache_model ("models/weapons/m1911/v_biatch_right.mdl");	// sprite explosion
			precache_model ("models/weapons/m1911/v_biatch_left.mdl");
			break;
		case W_KAR_SCOPE:
		case W_KAR:
		case W_ARMAGEDDON:
			precache_sound ("sounds/weapons/kar/boltup.wav");
			precache_sound ("sounds/weapons/kar/boltback.wav");
			precache_sound ("sounds/weapons/kar/boltforward.wav");
			precache_sound ("sounds/weapons/kar/boltdown.wav");
			precache_sound ("sounds/weapons/kar/clipin.wav");
			precache_sound ("sounds/weapons/kar/clipoff.wav");
			precache_sound ("sounds/weapons/kar/shoot.wav");
			precache_sound ("sounds/weapons/kar/insert.wav");
			precache_model ("models/weapons/kar/v_karscope.mdl");
			break;
		case W_THOMPSON:
		case W_GIBS:
			precache_sound("sounds/weapons/thomp/magout.wav");
			precache_sound("sounds/weapons/thomp/magin.wav");
			precache_sound("sounds/weapons/thomp/boltback.wav");
			precache_sound("sounds/weapons/thomp/shoot.wav");
			break;
		case W_357:
		case W_KILLU:
			precache_sound("sounds/weapons/357/open.wav");
			precache_sound("sounds/weapons/357/out.wav");
			precache_sound("sounds/weapons/357/in.wav");
			precache_sound("sounds/weapons/357/close.wav");
			precache_sound("sounds/weapons/357/shoot.wav");
			break;
		case W_BAR:
		case W_WIDOW:
			precache_sound("sounds/weapons/bar/shoot.wav");
			precache_sound("sounds/weapons/bar/magout.wav");
			precache_sound("sounds/weapons/bar/magin.wav");
			precache_sound("sounds/weapons/bar/maghit.wav");
			break;
		case W_BROWNING:
		case W_ACCELERATOR:
			precache_sound ("sounds/weapons/browning/boltback.wav");
			precache_sound ("sounds/weapons/browning/topopen.wav");
			precache_sound ("sounds/weapons/browning/chainoff.wav");
			precache_sound ("sounds/weapons/browning/boltback.wav");
			precache_sound ("sounds/weapons/browning/topopen.wav");
			precache_sound ("sounds/weapons/browning/chainon.wav");
			precache_sound ("sounds/weapons/browning/chainplace.wav");
			precache_sound ("sounds/weapons/browning/topclose.wav");
			precache_sound ("sounds/weapons/browning/tophit.wav");
			precache_sound ("sounds/weapons/browning/boltforward.wav");
			precache_sound ("sounds/weapons/browning/shoot.wav");
			break;
		case W_SAWNOFF:
		case W_SNUFF:
		case W_DB:
		case W_BORE:
			precache_sound("sounds/weapons/shotgun/open.wav");
			precache_sound("sounds/weapons/shotgun/out.wav");
			precache_sound("sounds/weapons/shotgun/in.wav");
			precache_sound("sounds/weapons/shotgun/close.wav");
			precache_sound("sounds/weapons/shotgun/shoot.wav");

			//lotta stuff here, so let's make sure we don't add unless ABSOLUTELY necessary..
			if (weptype == W_SAWNOFF || weptype == W_SNUFF)
				precache_model("models/weapons/sawnoff/v_snuff_right.mdl");
				precache_model("models/weapons/sawnoff/v_snuff_left.mdl");
			break;
		case W_FG:
		case W_IMPELLER:
			precache_sound("sounds/weapons/fg42/magout.wav");
			precache_sound("sounds/weapons/fg42/magin.wav");
			precache_sound("sounds/weapons/fg42/boltback.wav");
			precache_sound("sounds/weapons/fg42/boltforward.wav");
			precache_sound("sounds/weapons/fg42/shoot.wav");
			break;
		case W_GEWEHR:
		case W_COMPRESSOR:
			precache_sound("sounds/weapons/gewehr/magout.wav");
			precache_sound("sounds/weapons/gewehr/magin.wav");
			precache_sound("sounds/weapons/gewehr/maghit.wav");
			precache_sound("sounds/weapons/gewehr/boltrelease.wav");
			precache_sound("sounds/weapons/gewehr/shoot.wav");
			break;
		case W_M1:
		case W_M1000:
			precache_sound ("sounds/weapons/garand/clipout.wav");
			precache_sound ("sounds/weapons/garand/clipin.wav");
			precache_sound ("sounds/weapons/garand/clippush.wav");
			precache_sound ("sounds/weapons/garand/boltrelease.wav");
			precache_sound ("sounds/weapons/garand/shoot.wav");
			break;
		case W_M1A1:
		case W_WIDDER:
			precache_sound("sounds/weapons/m1carbine/shoot.wav");
			precache_sound("sounds/weapons/m1carbine/magout.wav");
			precache_sound("sounds/weapons/m1carbine/magin.wav");
			precache_sound("sounds/weapons/m1carbine/maghit.wav");
			precache_sound("sounds/weapons/m1carbine/bolt.wav");
			break;
		case W_M2:
			precache_sound("sounds/weapons/m2flame/flamethrower.wav");
			precache_model("models/misc/flame.spr");
			break;
		case W_MP40:
		case W_AFTERBURNER:
			precache_sound ("sounds/weapons/mp40/shoot.wav");
			precache_sound ("sounds/weapons/mp40/magout.wav");
			precache_sound ("sounds/weapons/mp40/magin.wav");
			break;
		case W_MG:
		case W_BARRACUDA:
			precache_sound("sounds/weapons/mg42/magout.wav");
			precache_sound("sounds/weapons/mg42/magin.wav");
			precache_sound("sounds/weapons/mg42/charge.wav");
			precache_sound("sounds/weapons/mg42/shoot.wav");
			break;
		case W_PANZER:
		case W_LONGINUS:
			precache_sound ("sounds/weapons/panzer/move.wav");
			precache_sound ("sounds/weapons/panzer/insert.wav");
			precache_sound ("sounds/weapons/panzer/shoot.wav");
			//precache_model ("progs/shark.mdl");
			break;
		case W_PPSH:
		case W_REAPER:
			precache_sound("sounds/weapons/ppsh/magout.wav");
			precache_sound("sounds/weapons/ppsh/magin.wav");
			precache_sound("sounds/weapons/ppsh/maghit.wav");
			precache_sound("sounds/weapons/ppsh/boltback.wav");
			precache_sound("sounds/weapons/ppsh/boltrelease.wav");
			precache_sound("sounds/weapons/ppsh/shoot.wav");
			break;
		case W_PTRS:
		case W_PENETRATOR:
			precache_sound ("sounds/weapons/ptrs/open.wav");
			precache_sound ("sounds/weapons/ptrs/maghit.wav");
			precache_sound ("sounds/weapons/ptrs/magin.wav");
			precache_sound ("sounds/weapons/ptrs/close.wav");
			precache_sound ("sounds/weapons/ptrs/shoot.wav");
			break;
		case W_RAY:
		case W_PORTER:
			precache_sound("sounds/weapons/raygun/open.wav");
			precache_sound("sounds/weapons/raygun/out.wav");
			precache_sound("sounds/weapons/raygun/in.wav");
			precache_sound("sounds/weapons/raygun/close.wav");
			precache_sound("sounds/weapons/raygun/shoot.wav");
			precache_model ("progs/raybeam.mdl");
			break;
		case W_STG:
		case W_SPATZ:
			precache_sound ("sounds/weapons/stg/magout.wav");
			precache_sound ("sounds/weapons/stg/magin.wav");
			precache_sound ("sounds/weapons/stg/shoot.wav");
			break;
		case W_TRENCH:
		case W_GUT:
			precache_sound ("sounds/weapons/shotgun/pump.wav");
			precache_sound ("sounds/weapons/shotgun/insert.wav");
			precache_sound ("sounds/weapons/shotgun/shoot.wav");
			break;
		case W_TYPE:
		case W_SAMURAI:
			precache_sound("sounds/weapons/type100/magout.wav");
			precache_sound("sounds/weapons/type100/magin.wav");
			precache_sound("sounds/weapons/type100/boltpull.wav");
			precache_sound("sounds/weapons/type100/shoot.wav");
			break;
		case W_TESLA:
		case W_DG3:
			precache_model("models/misc/lightning.spr");
			precache_sound("sounds/weapons/tesla/switchoff.wav");
			precache_sound("sounds/weapons/tesla/pulllever.wav");
			precache_sound("sounds/weapons/tesla/glassbreak.wav");
			precache_sound("sounds/weapons/tesla/clipin.wav");
			precache_sound("sounds/weapons/tesla/clipoff.wav");
			precache_sound("sounds/weapons/tesla/switchon.wav");
			precache_sound("sounds/weapons/tesla/shoot.wav");
			break;
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
