/*
	Structs are MAGICAL!
*/
var struct {
	string name;
	float magSize;
	float reserveSize;
	string vmodel;
	string vmodel2;
	string gmodel;
	float isDual;
	float firetype;
	float nonpap;
	float pap;
	float ispap;
	float damage;
	float shotcount;
	float bodypen;
	float penetration;
	float spread;
	float fdelay;
	float rdelay;
	float walkspeed;
	string firesound;
	float skin;
	float recoil;
	float crossmin;
	float crossmax;
	float lowmag;
	float lowreserve;
	vector flash;
	float flashsize;
	float papWpn;
	vector adsofs;
} CustomWeapons[] =
{

};

// so we know whether to use normal values or pull from our struct!
float(float wep) isCustomWeapon =
{
	if (wep >= 70)
		return TRUE;

	return FALSE;
}

string(float wep) GetWeaponName =
{
	if (isCustomWeapon(wep)) {
		return CustomWeapons[wep - 70].name;
	}

	switch (wep)
	{
		case W_COLT:
			return "Colt M1911";
		case W_BIATCH:
      		return "Mustang & Sally";
		case W_KAR:
			return "Kar 98k";
    	case W_ARMAGEDDON:
			return "Armageddon";
		case W_THOMPSON:
			return "Thompson";
		case W_GIBS:
			return "Gibs-O-Matic";
		case W_357:
			return ".357 Magnum";
		case W_KILLU:
			return ".357 Plus 1 K1L-u";
		case W_BAR:
			return "BAR";
		case W_WIDOW:
			return "The Widow Maker";
		case W_BK:
			return "Ballistic Knife";
		case W_BROWNING:
			return "Browning M1919";
		case W_ACCELERATOR:
			return "B115 Accelerator";
		case W_DB:
			return "Double-Barreled Shotgun";
		case W_BORE:
			return "24 Bore Long Range";
		case W_FG:
			return "FG42";
		case W_IMPELLER:
			return "420 Impeller";
		case W_GEWEHR:
			return "Gewehr 43";
		case W_COMPRESSOR:
			return "G115 Compressor";
		case W_KAR_SCOPE:
			return "Scoped Kar 98k";
		case W_HEADCRACKER:
			return "Headcracker";
		case W_M1:
			return "M1 Garand";
		case W_M1000:
			return "M1000";
		case W_M1A1:
			return "M1A1 Carbine";
		case W_WIDDER:
			return "Widdershins RC-1";
		case W_M2:
			return "M2 Flamethrower";
		case W_FIW:
			return "F1W Nitrogen Cooled";
		case W_MP40:
			return "MP40";
		case W_AFTERBURNER:
			return "The Afterburner";
		case W_MG:
			return "MG42";
		case W_BARRACUDA:
			return "Barracuda FU-A11";
		case W_PANZER:
			return "Panzerschrek";
		case W_LONGINUS:
			return "Longinus";
		case W_PPSH:
			return "PPSh-41";
		case W_REAPER:
			return "The Reaper";
		case W_PTRS:
			return "PTRS-41";
		case W_PENETRATOR:
			return "The Penetrator";
		case W_RAY:
			return "Ray Gun";
		case W_PORTER:
			return "Porter's X2 Ray Gun";
		case W_SAWNOFF:
			return "Sawnoff shotgun";
		case W_SNUFF:
			return "The Snuff Box";
		case W_STG:
			return "STG-44";
		case W_SPATZ:
			return "Spatz-447 +";
		case W_TRENCH:
			return "M1897 Trench Gun";
		case W_GUT:
			return "Gut Shot";
		case W_TYPE:
			return "Type 100";
		case W_SAMURAI:
			return "1001 Samurais";
		case W_BOWIE:
			return "Bowie Knife";
		case W_GRENADE:
			return "Grenades";
		case W_BETTY:
			return "Bouncing Betty";
    	case W_TESLA:
      		return "Wunderwaffe DG-2";
		default:
			return " ";
	}
}

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
		default:
			return "NULL";
	}
}

float(float wep) GetFiretype =
{

	if (isCustomWeapon(wep)) {
		return CustomWeapons[wep - 70].firetype;
	}

	switch (wep)
	{
		case W_COLT:
			return 1;
		case W_BIATCH:
			return 3;
		case W_KAR:
			return 1;
    	case W_ARMAGEDDON:
			return 1;
		case W_THOMPSON:
		case W_GIBS:
			return 0;
		case W_357:
		case W_KILLU:
			return 1;
		case W_BAR:
		case W_WIDOW:
			return 0;
		case W_BROWNING:
		case W_ACCELERATOR:
			return 0;
		case W_DB:
		case W_BORE:
			return 1;
		case W_FG:
		case W_IMPELLER:
			return 0;
		case W_GEWEHR:
		case W_COMPRESSOR:
			return 1;
		case W_KAR_SCOPE:
			return 1;
		case W_HEADCRACKER:
			return 0;
		case W_M1:
		case W_M1000:
			return 1;
		case W_M1A1:
			return 1;
		case W_WIDDER:
			return 0;
		case W_M2:
		case W_FIW:
			return 6;
		case W_MP40:
		case W_AFTERBURNER:
			return 0;
		case W_MG:
		case W_BARRACUDA:
			return 0;
		case W_PANZER:
		case W_LONGINUS:
			return 3;
		case W_PPSH:
		case W_REAPER:
			return 0;
		case W_PTRS:
		case W_PENETRATOR:
			return 0;
		case W_RAY:
		case W_PORTER:
			return 4;
		case W_SAWNOFF:
		case W_SNUFF:
			return 1;
		case W_STG:
		case W_SPATZ:
			return 0;
		case W_TRENCH:
		case W_GUT:
			return 1;
		case W_TYPE:
		case W_SAMURAI:
			return 0;
		case W_TESLA:
			return 5;
    }

    return 0;
}

float(float wep) getWeaponMag =
{

	if (isCustomWeapon(wep)) {
		return CustomWeapons[wep - 70].magSize;
	}

	switch (wep)
	{
		case W_COLT:
			return 8;
		case W_BIATCH:
			return 6;
		case W_KAR:
			return 5;
    	case W_ARMAGEDDON:
			return 8;
		case W_THOMPSON:
			return 20;
		case W_GIBS:
			return 40;
		case W_357:
		case W_KILLU:
			return 6;
		case W_BAR:
			return 20;
		case W_WIDOW:
			return 30;
		case W_BROWNING:
			return 125;
		case W_ACCELERATOR:
			return 125;
		case W_DB:
		case W_BORE:
			return 2;
		case W_FG:
			return 32;
		case W_IMPELLER:
			return 64;
		case W_GEWEHR:
			return 12;
		case W_COMPRESSOR:
			return 10;
		case W_KAR_SCOPE:
			return 5;
		case W_HEADCRACKER:
			return 10;
		case W_M1:
			return 8;
		case W_M1000:
			return 12;
		case W_M1A1:
			return 15;
		case W_WIDDER:
			return 15;
		case W_M2:
			return 200;
		case W_FIW:
			return 200;
		case W_MP40:
			return 32;
		case W_AFTERBURNER:
			return 64;
		case W_MG:
			return 125;
		case W_BARRACUDA:
			return 125;
		case W_PANZER:
			return 1;
		case W_LONGINUS:
			return 3;
		case W_PPSH:
			return 71;
		case W_REAPER:
			return 115;
		case W_PTRS:
			return 5;
		case W_PENETRATOR:
			return 8;
		case W_RAY:
			return 20;
		case W_PORTER:
			return 40;
		case W_SAWNOFF:
		case W_SNUFF:
			return 2;
		case W_STG:
			return 30;
		case W_SPATZ:
			return 60;
		case W_TRENCH:
			return 6;
		case W_GUT:
			return 10;
		case W_TYPE:
			return 30;
		case W_SAMURAI:
			return 60;
		case W_TESLA:
			return 3;
		case W_DG3:
			return 6;
	}
	return 0;
}

float(float wep) getWeaponAmmo =
{

	if (isCustomWeapon(wep)) {
		return CustomWeapons[wep - 70].reserveSize;
	}

	switch (wep)
	{
		case W_COLT:
			return 80;
		case W_BIATCH:
			return 80;
		case W_KAR:
			return 50;
    	case W_ARMAGEDDON:
			return 60;
		case W_THOMPSON:
			return 200;
		case W_GIBS:
			return 250;
		case W_357:
		case W_KILLU:
			return 80;
		case W_BAR:
			return 140;
		case W_WIDOW:
			return 180;
		case W_BROWNING:
			return 500;
		case W_ACCELERATOR:
			return 750;
		case W_DB:
			return 60;
		case W_BORE:
			return 60;
		case W_FG:
			return 192;
		case W_IMPELLER:
			return 400;
		case W_GEWEHR:
			return 120;
		case W_COMPRESSOR:
			return 170;
		case W_KAR_SCOPE:
			return 50;
		case W_HEADCRACKER:
			return 100;
		case W_M1:
			return 128;
		case W_M1000:
			return 150;
		case W_M1A1:
			return 120;
		case W_WIDDER:
			return 150;
		case W_M2:
      		return 200;
		case W_FIW:
      		return 200;
		case W_MP40:
			return 192;
		case W_AFTERBURNER:
			return 192;
		case W_MG:
			return 500;
		case W_BARRACUDA:
			return 750;
		case W_PANZER:
			return 20;
		case W_LONGINUS:
			return 30;
		case W_PPSH:
			return 355;
		case W_REAPER:
			return 700;
		case W_PTRS:
			return 60;
		case W_PENETRATOR:
			return 60;
		case W_RAY:
			return 160;
		case W_PORTER:
			return 200;
		case W_SAWNOFF:
			return 60;
		case W_SNUFF:
			return 60;
		case W_STG:
			return 180;
		case W_SPATZ:
			return 300;
		case W_TRENCH:
			return 60;
		case W_GUT:
			return 60;
		case W_TYPE:
			return 160;
		case W_SAMURAI:
			return 220;
		case W_TESLA:
			return 15;
		case W_DG3:
			return 32;
	}
	return 0;
}


float(float wep) getWeaponDamage =
{

	if (isCustomWeapon(wep)) {
		return CustomWeapons[wep - 70].damage;
	}

	switch (wep)
	{
		case W_COLT:
			return 20;
		case W_BIATCH:
			return 1000;
		case W_KAR:
			return 100;
		case W_ARMAGEDDON:
			return 200;
		case W_THOMPSON:
			return 120;
		case W_GIBS:
			return 200;
		case W_357:
			return 1000;
    	case W_KILLU:
			return 1400;
		case W_BAR:
			return 100;
		case W_WIDOW:
			return 200;
		case W_BROWNING:
			return 130;
		case W_ACCELERATOR:
			return 130;
		case W_DB:
			return 160;
		case W_BORE:
			return 320;
		case W_FG:
			return 100;
		case W_IMPELLER:
			return 110;
		case W_GEWEHR:
			return 90;
		case W_COMPRESSOR:
			return 200;
		case W_KAR_SCOPE:
			return 800;
		case W_HEADCRACKER:
			return 1000;
		case W_M1:
			return 105;
		case W_M1000:
			return 200;
		case W_M1A1:
			return 120;
		case W_WIDDER:
			return 200;
		case W_MP40:
			return 100;
		case W_AFTERBURNER:
			return 200;
		case W_MG:
			return 130;
		case W_BARRACUDA:
			return 130;
		case W_PANZER:
			return 600;
		case W_LONGINUS:
			return 1000;
		case W_PPSH:
			return 100;
		case W_REAPER:
			return 150;
		case W_PTRS:
			return 1000;
		case W_PENETRATOR:
			return 1000;
		case W_RAY:
			return 1000;
		case W_PORTER:
			return 1000;
		case W_SAWNOFF:
			return 240;
		case W_SNUFF:
			return 240;
		case W_STG:
			return 100;
		case W_SPATZ:
			return 150;
		case W_TRENCH:
			return 120;
		case W_GUT:
			return 240;
		case W_TYPE:
			return 100;
		case W_SAMURAI:
			return 200;
    }

    return 0;
}

float(float wep) GetWeaponShotcount =
{
	if (isCustomWeapon(wep)) {
		return CustomWeapons[wep - 70].shotcount;
	}

	switch(wep)
	{
		case W_DB:
			return 8;
		case W_BORE:
			return 10;
		case W_SAWNOFF:
		case W_SNUFF:
			return 8;
		case W_TRENCH:
			return 8;
		case W_GUT:
			return 10;
	}

    return 1;
}

float(float wep, float penetration_times) getWeaponPenetration =
{
	if (!penetration_times)
		return 2;

	if (isCustomWeapon(wep)) {
		if (penetration_times >= CustomWeapons[wep - 70].bodypen)
			return 0;

		return CustomWeapons[wep - 70].penetration;
	}

	switch (wep)
	{
		case W_COLT:
		case W_BIATCH:
			if (penetration_times >= 2)
				return 0;
			return 0.75;
		case W_KAR:
		case W_ARMAGEDDON:
			if (penetration_times >= 3)
				return 0;
			return 1;
		case W_THOMPSON:
		case W_GIBS:
			if (penetration_times >= 2)
				return 0;
			return 0.8;
		case W_357:
		case W_KILLU:
			if (penetration_times >= 3)
				return 0;
		case W_BAR:
		case W_WIDOW:
			if (penetration_times >= 3)
				return 0;
			return 1;
		case W_BROWNING:
		case W_ACCELERATOR:
			if (penetration_times >= 3)
				return 0;
			return 1;
		case W_DB:
		case W_BORE:
			if (penetration_times >= 1)
				return 0;
			return 0.5;
		case W_FG:
		case W_IMPELLER:
			if (penetration_times >= 2)
				return 0;
			return 0.9;
		case W_GEWEHR:
		case W_COMPRESSOR:
			if (penetration_times >= 2)
				return 0;
			return 0.9;
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
			if (penetration_times >= 3)
				return 0;
			return 1;
		case W_M1:
		case W_M1000:
			if (penetration_times >= 2)
				return 0;
			return 0.9;
		case W_M1A1:
		case W_WIDDER:
			if (penetration_times >= 2)
				return 0;
			return 0.9;
		case W_MP40:
		case W_AFTERBURNER:
			if (penetration_times >= 2)
				return 0;
			return 0.8;
		case W_MG:
		case W_BARRACUDA:
			if (penetration_times >= 3)
				return 0;
			return 1;
		case W_PPSH:
		case W_REAPER:
			if (penetration_times >= 2)
				return 0;
			return 0.75;
		case W_PTRS:
			if (penetration_times >= 3)
				return 0;
			return 1;
		case W_PENETRATOR:
			if (penetration_times >= 5)
				return 0;
			return 1;
		case W_SAWNOFF:
		case W_SNUFF:
			if (penetration_times >= 1)
				return 0;
			return 0.4;
		case W_STG:
		case W_SPATZ:
			if (penetration_times >= 2)
				return 0;
			return 0.8;
		case W_TRENCH:
		case W_GUT:
			if (penetration_times >= 1)
				return 0;
			return 0.7;
		case W_TYPE:
		case W_SAMURAI:
			if (penetration_times >= 2)
				return 0;
			return 0.8;
		default:
			return 0;
    }
}

float(float wep) GetWeaponSpread =
{
	float Weapon_Spread, Total_Spread;

	if (isCustomWeapon(wep)) {
		Weapon_Spread = CustomWeapons[wep - 70].spread;
	}

	switch (wep)
	{
		case W_COLT:
			Weapon_Spread = 7.5;
			break;
		case W_BIATCH:
			Weapon_Spread = 7.5;
			break;
		case W_KAR:
			Weapon_Spread = 25;
			break;
		case W_ARMAGEDDON:
			Weapon_Spread = 25;
			break;
		case W_THOMPSON:
			Weapon_Spread = 5;
			break;
		case W_GIBS:
			Weapon_Spread = 5;
			break;
		case W_RAY:
			Weapon_Spread = 5;
			break;
		case W_PORTER:
			Weapon_Spread = 5;
			break;
		case W_KAR_SCOPE:
			Weapon_Spread = 25;
			break;
		case W_HEADCRACKER:
			Weapon_Spread = 25;
			break;
		case W_BAR:
			Weapon_Spread = 5;
			break;
		case W_WIDOW:
			Weapon_Spread = 5;
			break;
		case W_M1A1:
			Weapon_Spread = 5;
			break;
		case W_WIDDER:
			Weapon_Spread = 5;
			break;
		case W_M2:
			Weapon_Spread = 0;
			break;
		case W_FIW:
			Weapon_Spread = 0;
			break;
		case W_TYPE:
			Weapon_Spread = 5;
			break;
		case W_SAMURAI:
			Weapon_Spread = 5;
			break;
		case W_SAWNOFF:
			Weapon_Spread = 15;
			break;
		case W_SNUFF:
			Weapon_Spread = 15;
			break;
		case W_PPSH:
			Weapon_Spread = 5;
			break;
		case W_REAPER:
			Weapon_Spread = 5;
			break;
		case W_DB:
			Weapon_Spread = 12.5;
			break;
		case W_BORE:
			Weapon_Spread = 12.5;
			break;
		case W_FG:
			Weapon_Spread = 5;
			break;
		case W_IMPELLER:Weapon_Spread = 5;
			break;
		case W_TRENCH:Weapon_Spread = 12.5;
			break;
		case W_GUT:Weapon_Spread = 12.5;
			break;
		case W_MG:Weapon_Spread = 10;
			break;
		case W_BARRACUDA:Weapon_Spread = 10;
			break;
		case W_GEWEHR:
			Weapon_Spread = 5;
			break;
		case W_COMPRESSOR:
			Weapon_Spread = 5;
			break;
		case W_BROWNING:
			Weapon_Spread = 10;
			break;
		case W_ACCELERATOR:
			Weapon_Spread = 10;
			break;
		case W_357:
			Weapon_Spread = 5;
			break;
		case W_KILLU:
			Weapon_Spread = 5;
			break;
		case W_M1:
			Weapon_Spread = 5;
			break;
		case W_M1000:
			Weapon_Spread = 5;
			break;
		case W_MP40:
			Weapon_Spread = 5;
			break;
		case W_AFTERBURNER:
			Weapon_Spread = 5;
			break;
		case W_PTRS:
			Weapon_Spread = 15;
			break;
		case W_PENETRATOR:
			Weapon_Spread = 15;
			break;
		case W_STG:
			Weapon_Spread = 5;
			break;
		case W_SPATZ:
			Weapon_Spread = 5;
			break;
		case W_MP5:
			Weapon_Spread = 5;
			break;
		case W_TESLA:
			Weapon_Spread = 5;
			break;
		case W_M14:
			Weapon_Spread = 5;
		break;
	}

	Total_Spread = Weapon_Spread;
	return Total_Spread;
}

float(float wep, float delaytype) getWeaponDelay =
{

	if (isCustomWeapon(wep)) {
		if (delaytype == RELOAD)
			return CustomWeapons[wep - 70].rdelay;
		else if (delaytype == FIRE)
			return CustomWeapons[wep - 70].fdelay;
	}

	switch (wep)
	{
		case W_COLT:
			if (delaytype == RELOAD)
				return 2.5;
			else if (delaytype == FIRE)
				return 0.185;
		case W_BIATCH:
			if (delaytype == RELOAD)
				return 2.5;
			else if (delaytype == FIRE)
				return 0.075;
    	case W_ARMAGEDDON:
		case W_KAR:
			if (delaytype == RELOAD)
				return 1.6;
			else if (delaytype == FIRE)
				return 0.3;
		case W_THOMPSON:
		case W_GIBS:
			if (delaytype == RELOAD)
				return 2.4;
			else if (delaytype == FIRE)
				return 0.08;
		case W_357:
		case W_KILLU:
			if (delaytype == RELOAD)
				return 2.2;
			else if (delaytype == FIRE)
				return 0.32;
		case W_BAR:
			if (delaytype == RELOAD)
				return 3.5;
			else if (delaytype == FIRE)
				return 0.16;
		case W_WIDOW:
			if (delaytype == RELOAD)
				return 3.5;
			else if (delaytype == FIRE)
				return 0.11;
		case W_BROWNING:
			if (delaytype == RELOAD)
				return 3.3;
			else if (delaytype == FIRE)
				return 0.096;
		case W_ACCELERATOR:
			if (delaytype == RELOAD)
				return 3.3;
			else if (delaytype == FIRE)
				return 0.08;
		case W_DB:
			if (delaytype == RELOAD)
				return 2.8;
			else if (delaytype == FIRE)
				return 0.283;
		case W_BORE:
			if (delaytype == RELOAD)
				return 2.4;
			else if (delaytype == FIRE)
				return 0.283;
		case W_FG:
			if (delaytype == RELOAD)
			  	return 4.5;
			else if (delaytype == FIRE)
				return 0.064;
		case W_IMPELLER:
			if (delaytype == RELOAD)
			  	return 4.5;
			else if (delaytype == FIRE)
				return 0.06;
		case W_GEWEHR:
		case W_COMPRESSOR:
			if (delaytype == RELOAD)
				return 3.5;
			else if (delaytype == FIRE)
				return 0.125;
		case W_M1:
		case W_M1000:
			if (delaytype == RELOAD)
				return 3.8;
			else if (delaytype == FIRE)
				return 0.135;
		case W_M1A1:
			if (delaytype == RELOAD)
				return 2.9;
			else if (delaytype == FIRE)
				return 0.135;
		case W_WIDDER:
			if (delaytype == RELOAD)
				return 2.9;
			else if (delaytype == FIRE)
				return 0.1;
		case W_M2:
		case W_FIW:
			if (delaytype == RELOAD)
				return 2.7;
			else if (delaytype == FIRE)
				return 0.02;
		case W_MP40:
			if (delaytype == RELOAD)
				return 2.2;
			else if (delaytype == FIRE)
				return 0.112;
		case W_AFTERBURNER:
			if (delaytype == RELOAD)
				return 2.2;
			else if (delaytype == FIRE)
				return 0.1;
		case W_MG:
			if (delaytype == RELOAD)
				return 3.6;
			else if (delaytype == FIRE)
				return 0.064;
		case W_BARRACUDA:
			if (delaytype == RELOAD)
				return 3.6;
			else if (delaytype == FIRE)
				return 0.04;
		case W_PANZER:
		case W_LONGINUS:
			if (delaytype == RELOAD)
				return 1.55;
			else if (delaytype == FIRE)
				return 0.331;
		case W_PPSH:
			if (delaytype == RELOAD)
				return 3.3;
			else if (delaytype == FIRE)
				return 0.048;
		case W_REAPER:
			if (delaytype == RELOAD)
				return 3.3;
			else if (delaytype == FIRE)
				return 0.038;
		case W_PTRS:
		case W_PENETRATOR:
			if (delaytype == RELOAD)
				return 2.8;
			else if (delaytype == FIRE)
				return 0.8;
		case W_RAY:
		case W_PORTER:
			if (delaytype == RELOAD)
				return 2.75;
			else if (delaytype == FIRE)
				return 0.35;
		case W_SAWNOFF:
			if (delaytype == RELOAD)
				return 2.8;
			else if (delaytype == FIRE)
				return 0.283;
		case W_SNUFF:
			if (delaytype == RELOAD)
				return 2;
			else if (delaytype == FIRE)
				return 0.283;
		case W_STG:
			if (delaytype == RELOAD)
				return 2.5;
			else if (delaytype == FIRE)
				return 0.102;
		case W_SPATZ:
			if (delaytype == RELOAD)
				return 2.5;
			else if (delaytype == FIRE)
				return 0.08;
		case W_TRENCH:
		case W_GUT:
			if (delaytype == RELOAD)
				return 2.2;
			else if (delaytype == FIRE)
				return 0.283;
		case W_TYPE:
			if (delaytype == RELOAD)
				return 2.3;
			else if (delaytype == FIRE)
				return 0.08;
		case W_SAMURAI:
			if (delaytype == RELOAD)
				return 2.3;
			else if (delaytype == FIRE)
				return 0.065;
		case W_TESLA:
			if (delaytype == RELOAD)
				return 4;
			else if (delaytype == FIRE)
				return 1;
			break;
    }

    return 0;
}

float GetWeaponWalkSpeed (float weapontype)
{

	if (isCustomWeapon(weapontype)) {
		return CustomWeapons[weapontype - 70].walkspeed;
	}

	switch(weapontype) {
		default: return 1;
		case W_KAR: 
		case W_357:
		case W_GEWEHR:
		case W_M1:
		case W_M1A1:
		case W_KAR_SCOPE:
		case W_KILLU:
		case W_COMPRESSOR:
		case W_M1000:
		case W_WIDDER:
		case W_ARMAGEDDON:
		case W_HEADCRACKER:
			return 0.9;
		case W_M2:
			return 0.67;
		case W_MG:
		case W_BROWNING:
		case W_PANZER:
		case W_PTRS:
		case W_BARRACUDA:
		case W_ACCELERATOR:
		case W_PENETRATOR:
			return 0.75;
		case W_FIW:
			return 0.85;
	}
}

vector GetWeaponADSPos(float wep) {

	if (isCustomWeapon(wep)) {
		return CustomWeapons[wep - 70].adsofs;
	}

	switch (wep) {
		case W_COLT:
			return [-2.99, 2.77, 0.92];
		case W_KAR:
		case W_ARMAGEDDON:
			return [-2.19, 2.77, 1.42];
		case W_THOMPSON:
		case W_GIBS:
			return [-2.9, 3.16, 1.71];
		case W_357:
		case W_KILLU:
			return [-2.6, 4.16, 0.5];
		case W_BAR:
		case W_WIDOW:
			return [-0.6, 2, 1.47];
		case W_BROWNING:
		case W_ACCELERATOR:
			return [-1.6, 7.7, 6.5];
		case W_DB:
		case W_BORE:
		case W_SAWNOFF:
			return [-0.6, 2.9, 1.47];
		case W_FG:
		case W_IMPELLER:
			return [-6.5, 7.4, 3.27];
		case W_GEWEHR:
		case W_COMPRESSOR:
			return [-0.2, 3.28, 2.57];
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
			return [-2.19, 2.67, 0.42];
		case W_M1:
		case W_M1000:
			return [-2.6, 1.46, 1.12];
		case W_M1A1:
		case W_WIDDER:
			return [-0.6, 2.7, 1.94];
		case W_MP40:
		case W_AFTERBURNER:
			return [-3.79, 6.1, 4.04];
		case W_MG:
		case W_BARRACUDA:
			return [-3.9, 3.5, 1.84];
		case W_PPSH:
		case W_REAPER:
			return [-9.79, 5.5, 2.94];
		case W_PTRS:
		case W_PENETRATOR:
			return [-9.79, 6.6, 2.44];
		case W_STG:
		case W_SPATZ:
			return [-9.79, 7.3, 4.94];
		case W_TRENCH:
		case W_GUT:
			return [0, 2.85, 1.4];
		case W_M2:
		case W_FIW:
			return [0, 0.89, 0.82];
		case W_RAY:
		case W_PORTER:
			return [-1.50, 6.40, 0.87];
		default:
			return [0, 0, 0];
	}
}

/*
===========================
Weapon PSP ADS Declarations
===========================
*/

vector GetWeaponADSOfs_PSP(float wep) = 
{
		
	switch(wep)
	{
		case W_COLT:
		case W_BIATCH:
			return [-5479.2, 1650, 0];
		case W_KAR:
		case W_ARMAGEDDON:
			return [-5495.9, 3186.9, 0];
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
			return [-5286, 706.1, 0];
		case W_THOMPSON:
		case W_GIBS:
			return [-6069.3, 3007.6, 0]; 
		case W_TRENCH:
		case W_GUT:
			return [-5527.1, 2880.3, 0];
		case W_357:
		case W_KILLU:
			return [-8306.5, 879.2, 0];
		case W_MG:
		case W_BARRACUDA:
			return [-6643.7, 3509.2, 0];
		case W_DB:
		case W_BORE:
		case W_SAWNOFF:
			return [-5801.7, 2912.1, 0];
		case W_M1A1:
		case W_WIDDER:
			return [-5387.8, 3671.9, 0];
		case W_BAR:
		case W_WIDOW:
			return [-3883.3, 2674.5, 0];
		case W_FG:
		case W_IMPELLER:
			return [-14800, 6000, 0];
		case W_RAY:
		case W_PORTER:
			return [-12700, 2086.9, 0];
		case W_GEWEHR:
		case W_COMPRESSOR:
			return [-6550, 4400, 0];
		case W_PPSH:
		case W_REAPER:
			return [-11000, 3700, 0];
		case W_MP40:
		case W_AFTERBURNER:
			return [-12320, 7600, 0];
		case W_TYPE:
		case W_SAMURAI:
			return [-0400, -200, 0];
		case W_STG:
		case W_SPATZ:
			return [-14534, 8920, 0];
		case W_M1:
		case W_M1000:
			return [-2860, 2000, 0];
		case W_BROWNING:
		case W_ACCELERATOR:
			return [-15200, 11620, 0];
		case W_PTRS:
		case W_PENETRATOR:
			return [-14000, 5386.9, 0];
		case W_PANZER:
		case W_LONGINUS:
			return [-3479.2, -650, 0];
		default:
			//Large values > 20ish cause weapon to flicker, scale model down if we encounter!
			//Scale better be 4.3, or else viewbobbing is going to be inaccurate.
			return [-5.4792, 1.6500, 0];
	}
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
					return 0;
				case TAKE_OUT_END:
					return 0;
				case PUT_OUT_START:
					return 0;
				case PUT_OUT_END:
					return 0;
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
					return 5;
				case RELOAD_START:
					return 5;
				case RELOAD_END:
					return 47;
				case SPRINT_IN_START:
					return 78;
				case SPRINT_IN_END:
					return 80;
				case SPRINT_OUT_START:
					return 80;
				case SPRINT_OUT_END:
					return 83;
				case TAKE_OUT_START:
					return 80;
				case TAKE_OUT_END:
					return 83;
				case PUT_OUT_START:
					return 77;
				case PUT_OUT_END:
					return 80;
				case RELOAD_CANCEL:
					return 16;
			}
			break;
	}

    return 0;
}

string(float wep, float gorvmodel) GetWeaponModel =
{

	if (isCustomWeapon(wep)) {
		if (gorvmodel)
			return CustomWeapons[wep - 70].gmodel;
		else
			return CustomWeapons[wep - 70].vmodel;
	}

	switch (wep)
	{
		case W_COLT:
			if (gorvmodel)
				return ("models/weapons/m1911/g_colt.mdl");
			else
				return ("models/weapons/m1911/v_colt.mdl");
		case W_BIATCH:
			if (gorvmodel)
				return ("models/weapons/m1911/g_colt.mdl");
			else
				return ("models/weapons/m1911/v_biatch_right.mdl");
		case W_KAR:
		case W_ARMAGEDDON:
			if (gorvmodel)
				return ("models/weapons/kar/g_kar.mdl");
			else
				return ("models/weapons/kar/v_kar.mdl");
		case W_THOMPSON:
		case W_GIBS:
			if (gorvmodel)
				return ("models/weapons/thomp/g_thomp.mdl");
			else
				return ("models/weapons/thomp/v_thomp.mdl");
		case W_357:
		case W_KILLU:
			if (gorvmodel)
				return ("models/weapons/357/g_357.mdl");
			else
				return ("models/weapons/357/v_357.mdl");
		case W_BAR:
		case W_WIDOW:
			if (gorvmodel)
				return ("models/weapons/bar/g_bar.mdl");
			else
				return ("models/weapons/bar/v_bar.mdl");
		case W_BROWNING:
    	case W_ACCELERATOR:
			if (gorvmodel)
				return ("models/weapons/browning/g_browning.mdl");
			else
				return ("models/weapons/browning/v_browning.mdl");
		case W_DB:
    	case W_BORE:
			if (gorvmodel)
				return ("models/weapons/db/g_db.mdl");
			else
				return ("models/weapons/db/v_db.mdl");
		case W_FG:
    	case W_IMPELLER:
			if (gorvmodel)
				return ("models/weapons/fg42/g_fg.mdl");
			else
				return ("models/weapons/fg42/v_fg.mdl");
		case W_GEWEHR:
    	case W_COMPRESSOR:
			if (gorvmodel)
				return ("models/weapons/gewehr/g_gewehr.mdl");
			else
				return ("models/weapons/gewehr/v_gewehr.mdl");
		case W_KAR_SCOPE:
    	case W_HEADCRACKER:
			if (gorvmodel)
				return ("models/weapons/kar/g_kars.mdl");
			else
				return ("models/weapons/kar/v_kar.mdl");
		case W_M1:
    	case W_M1000:
			if (gorvmodel)
				return ("models/weapons/garand/g_m1.mdl");
			else
				return ("models/weapons/garand/v_m1.mdl");
		case W_M1A1:
    	case W_WIDDER:
			if (gorvmodel)
				return ("models/weapons/m1carbine/g_m1a1.mdl");
			else
				return ("models/weapons/m1carbine/v_m1a1.mdl");
		case W_M2:
			if (gorvmodel)
				return ("models/weapons/m2flame/g_m2flame.mdl");
			else
				return ("models/weapons/m2flame/v_m2flame.mdl");
		case W_MP40:
    	case W_AFTERBURNER:
			if (gorvmodel)
				return ("models/weapons/mp40/g_mp40.mdl");
			else
				return ("models/weapons/mp40/v_mp40.mdl");
		case W_MG:
    	case W_BARRACUDA:
			if (gorvmodel)
				return ("models/weapons/mg/g_mg.mdl");
			else
				return ("models/weapons/mg/v_mg.mdl");
		case W_PANZER:
    	case W_LONGINUS:
			if (gorvmodel)
				return ("models/weapons/panzer/g_panzer.mdl");
			else
				return ("models/weapons/panzer/v_panzer.mdl");
		case W_PPSH:
    	case W_REAPER:
			if (gorvmodel)
				return ("models/weapons/ppsh/g_ppsh.mdl");
			else
				return ("models/weapons/ppsh/v_ppsh.mdl");
		case W_PTRS:
    	case W_PENETRATOR:
			if (gorvmodel)
				return ("models/weapons/ptrs/g_ptrs.mdl");
			else
				return ("models/weapons/ptrs/v_ptrs.mdl");
		case W_RAY:
    	case W_PORTER:
			if (gorvmodel)
				return ("models/weapons/ray/g_ray.mdl");
			else
				return ("models/weapons/ray/v_ray.mdl");
		case W_SAWNOFF:
			if (gorvmodel)
				return ("models/weapons/sawnoff/g_sawnoff.mdl");
			else
				return ("models/weapons/sawnoff/v_sawnoff.mdl");
    	case W_SNUFF:
			if (gorvmodel)
				return ("models/weapons/sawnoff/g_sawnoff.mdl");
			else
				return ("models/weapons/sawnoff/v_snuff_right.mdl");
		case W_STG:
    	case W_SPATZ:
			if (gorvmodel)
				return ("models/weapons/stg/g_stg.mdl");
			else
				return ("models/weapons/stg/v_stg.mdl");
		case W_TRENCH:
    	case W_GUT:
			if (gorvmodel)
				return ("models/weapons/trench/g_trench.mdl");
			else
				return ("models/weapons/trench/v_trench.mdl");
		case W_TYPE:
    	case W_SAMURAI:
			if (gorvmodel)
				return ("models/weapons/type/g_type.mdl");
			else
				return ("models/weapons/type/v_type.mdl");
		case W_GRENADE:
			return ("models/weapons/grenade/g_grenade.mdl");
		case W_BETTY:
			return ("models/weapons/grenade/g_betty.mdl");
		case W_DG3:
		case W_TESLA:
			if (gorvmodel)
				return ("models/weapons/tesla/g_tesla.mdl");
			else
				return ("models/weapons/tesla/v_tesla.mdl");
		case W_BK:
			if (gorvmodel)
				return ("models/weapons/bk/g_bk.mdl");
			else
				return ("models/weapons/bk/v_bk.mdl");
    }

    return ("");
}

string(float wep) GetWeaponSound =
{

	if (isCustomWeapon(wep)) {
		return CustomWeapons[wep - 70].firesound;
	}

	switch (wep)
	{
		case W_BIATCH:
		case W_COLT:
			return "sounds/weapons/colt/shoot.wav";
		case W_KAR:
		case W_ARMAGEDDON:
			return "sounds/weapons/kar/shoot.wav";
		case W_THOMPSON:
		case W_GIBS:
			return "sounds/weapons/thomp/shoot.wav";
		case W_357:
		case W_KILLU:
			return "sounds/weapons/357/shoot.wav";
		case W_BAR:
    	case W_WIDOW:
			return "sounds/weapons/bar/shoot.wav";
		case W_BROWNING:
    	case W_ACCELERATOR:
			return "sounds/weapons/browning/shoot.wav";
		case W_DB:
    	case W_BORE:
			return "sounds/weapons/shotgun/shoot.wav";
		case W_FG:
    	case W_IMPELLER:
			return "sounds/weapons/fg42/shoot.wav";
		case W_GEWEHR:
    	case W_COMPRESSOR:
			return "sounds/weapons/gewehr/shoot.wav";
		case W_KAR_SCOPE:
    	case W_HEADCRACKER:
			return "sounds/weapons/kar/shoot.wav";
		case W_M1:
    	case W_M1000:
			return "sounds/weapons/garand/shoot.wav";
		case W_M1A1:
    	case W_WIDDER:
			return "sounds/weapons/m1carbine/shoot.wav";
		case W_M2:
			return "sounds/weapons/m2flame/flamethrower.wav";
		case W_MP40:
    	case W_AFTERBURNER:
			return "sounds/weapons/mp40/shoot.wav";
		case W_MG:
    	case W_BARRACUDA:
			return "sounds/weapons/mg42/shoot.wav";
		case W_PANZER:
   		case W_LONGINUS:
			return "sounds/weapons/panzer/shoot.wav";
		case W_PPSH:
    	case W_REAPER:
			return "sounds/weapons/ppsh/shoot.wav";
		case W_PTRS:
    	case W_PENETRATOR:
			return "sounds/weapons/ptrs/shoot.wav";
		case W_RAY:
    	case W_PORTER:
			return "sounds/weapons/raygun/shoot.wav";
		case W_SAWNOFF:
    	case W_SNUFF:
			return "sounds/weapons/shotgun/shoot.wav";
		case W_STG:
    	case W_SPATZ:
			return "sounds/weapons/stg/shoot.wav";
		case W_TRENCH:
    	case W_GUT:
			return "sounds/weapons/shotgun/shoot.wav";
		case W_TYPE:
    	case W_SAMURAI:
			return "sounds/weapons/type100/shoot.wav";
		case W_TESLA:
		case W_DG3:
      		return "sounds/weapons/tesla/shoot.wav";
    }

    return "";
}

float(float wep) IsDualWeapon = {

	if (isCustomWeapon(wep)) {
		return CustomWeapons[wep - 70].isDual;
	}

	switch(wep) {
		case W_BIATCH:
			return 1;
		case W_SNUFF:
			return 1;
		default:
			return 0;
	}
}

string(float wep) GetLeftWeaponModel = {

	if (isCustomWeapon(wep)) {
		return CustomWeapons[wep - 70].vmodel2;
	}

	switch(wep) {
		case W_BIATCH:
			return "models/weapons/m1911/v_biatch_left.mdl";
		case W_SNUFF:
			return "models/weapons/sawnoff/v_snuff_left.mdl";
		default:
			return "";
	}
}

float(float wep) IsPapWeapon = {

	if (isCustomWeapon(wep)) {
		return CustomWeapons[wep - 70].ispap;
	}

	switch(wep) {
		case W_BIATCH:
		case W_ARMAGEDDON:
		case W_GIBS:
		case W_KILLU:
		case W_WIDOW:
		case W_ACCELERATOR:
		case W_BORE:
		case W_IMPELLER:
		case W_COMPRESSOR:
		case W_HEADCRACKER:
		case W_M1000:
		case W_WIDDER:
		case W_AFTERBURNER:
		case W_BARRACUDA:
		case W_LONGINUS:
		case W_REAPER:
		case W_PENETRATOR:
		case W_PORTER:
		case W_SNUFF:
		case W_SPATZ:
		case W_GUT:
		case W_SAMURAI:
			return 1;
		default:
			return 0;
	}
}

float(float wep) GetWepSkin = {

	if (isCustomWeapon(wep)) {
		return CustomWeapons[wep - 70].skin;
	}

	switch(wep) {
		case W_BIATCH:
			return 0;
		case W_SNUFF:
			return 0;
		default:
			if (IsPapWeapon(wep)) {
				return 1;
			} else {
				return 0;
			}
	}
}


float(float wep)  EqualNonPapWeapon = 
{

	if (isCustomWeapon(wep)) {
		return CustomWeapons[wep - 70].nonpap;
	}

	switch (wep) {
		case W_BIATCH:
			return W_COLT;
		case W_ARMAGEDDON:
			return W_KAR;
		case W_GIBS:
			return W_THOMPSON;
		case W_KILLU:
			return W_357;
		case W_WIDOW:
			return W_BAR;
		case W_ACCELERATOR:
			return W_BROWNING;
		case W_BORE:
			return W_DB;
		case W_IMPELLER:
			return W_FG;
		case W_COMPRESSOR:
			return W_GEWEHR;
		case W_HEADCRACKER:
			return W_KAR_SCOPE;
		case W_M1000:
			return W_M1;
		case W_WIDDER:
			return W_M1A1;
		case W_AFTERBURNER:
			return W_MP40;
		case W_BARRACUDA:
			return W_MG;
		case W_LONGINUS:
			return W_PANZER;
		case W_REAPER:
			return W_PPSH;
		case W_PENETRATOR:
			return W_PTRS;
		case W_PORTER:
			return W_RAY;
		case W_SNUFF:
			return W_SAWNOFF;
		case W_SPATZ:
			return W_STG;
		case W_GUT:
			return W_TRENCH;
		case W_SAMURAI:
			return W_TYPE;
		case W_MP5:
			return W_MP5;
		case W_M14:
			return W_M14;
		case W_CUSTOM2:
			return W_CUSTOM1;
		case W_CUSTOM4:
			return W_CUSTOM3;
		case W_DG3:
			return W_TESLA;
		default:
			return 0;
	}
}
float(float wep)  EqualPapWeapon = 
{

	if (isCustomWeapon(wep)) {
		return CustomWeapons[wep - 70].pap;
	}

	switch (wep) {
		case W_COLT:
			return W_BIATCH;
		case W_KAR:
      		return W_ARMAGEDDON;
		case W_THOMPSON:
			return W_GIBS;
		case W_357:
			return W_KILLU;
		case W_BAR:
			return W_WIDOW;
		case W_BROWNING:
			return W_ACCELERATOR;
		case W_DB:
			return W_BORE;
		case W_FG:
			return W_IMPELLER;
		case W_GEWEHR:
			return W_COMPRESSOR;
		case W_KAR_SCOPE:
			return W_HEADCRACKER;
		case W_M1:
			return W_M1000;
		case W_M1A1:
			return W_WIDDER;
		case W_MP40:
			return W_AFTERBURNER;
		case W_MG:
			return W_BARRACUDA;
		case W_PANZER:
			return W_LONGINUS;
		case W_PPSH:
			return W_REAPER;
		case W_PTRS:
			return W_PENETRATOR;
		case W_RAY:
			return W_PORTER;
		case W_SAWNOFF:
			return W_SNUFF;
		case W_STG:
			return W_SPATZ;
		case W_TRENCH:
			return W_GUT;
		case W_TYPE:
			return W_SAMURAI;
		case W_MP5:
			return W_MP5;
		case W_TESLA:
			return W_DG3;
		case W_M14:
			return W_M14;
		default:
			return wep;
	}
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
			if (curweaponframe == 10)
				sound (self ,5, "sounds/weapons/tesla/switchoff.wav", 1, ATTN_NORM);
			else if (curweaponframe == 16)
				sound (self ,5, "sounds/weapons/tesla/pulllever.wav", 1, ATTN_NORM);
			else if (curweaponframe == 22)
				sound (self ,5, "sounds/weapons/tesla/glassbreak.wav", 1, ATTN_NORM);
			else if (curweaponframe == 29)
				sound (self ,5, "sounds/weapons/tesla/clipin.wav", 1, ATTN_NORM);
			else if (curweaponframe == 32)
				sound (self ,5, "sounds/weapons/tesla/clipoff.wav", 1, ATTN_NORM);
			else if (curweaponframe == 41)
				sound (self ,5, "sounds/weapons/tesla/switchon.wav", 1, ATTN_NORM);
	}
}


void(float weptype) precache_extra =
{

	if (isCustomWeapon(weptype)) {
		precache_model(CustomWeapons[weptype - 70].vmodel);
	}

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
			//precache_model ("progs/flame_main2.spr");	// sprite explosion
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
			precache_model ("progs/shark.mdl");
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
			precache_sound("sounds/weapons/tesla/switchoff.wav");
			precache_sound("sounds/weapons/tesla/pulllever.wav");
			precache_sound("sounds/weapons/tesla/glassbreak.wav");
			precache_sound("sounds/weapons/tesla/clipin.wav");
			precache_sound("sounds/weapons/tesla/clipoff.wav");
			precache_sound("sounds/weapons/tesla/switchon.wav");
			break;
	}
}

float(float wep) getWeaponRecoilReturn =
{

	if (isCustomWeapon(wep)) {
		return CustomWeapons[wep - 70].recoil;
	}

	switch (wep)
	{
		case W_COLT:
			return 750;
			break;
		case W_BIATCH:
			return 750;
			break;
		case W_KAR:
			return 750;
			break;
		case W_ARMAGEDDON:
			return 750;
			break;
		case W_THOMPSON:
			return 950;
			break;
		case W_GIBS:
			return 950;
			break;
		case W_357:
			return 1500;
			break;
		case W_KILLU:
			return 1500;
			break;
		case W_BAR:
			return 460;
			break;
		case W_WIDOW:
			return 460;
			break;
		case W_BROWNING:
			return 950;
			break;
		case W_ACCELERATOR:
			return 950;
			break;
		case W_DB:
			return 1000;
			break;
		case W_BORE:
			return 1000;
			break;
		case W_FG:
			return 1129;
			break;
		case W_IMPELLER:
			return 1129;
			break;
		case W_GEWEHR:
			return 1500;
			break;
		case W_COMPRESSOR:
			return 1500;
			break;
		case W_KAR_SCOPE:
			return 750;
			break;
		case W_HEADCRACKER:
			return 750;
			break;
		case W_M1:
			return 1500;
			break;
		case W_M1000:
			return 1500;
			break;
		case W_M1A1:
			return 1500;
			break;
		case W_WIDDER:
			return 1500;
			break;
		case W_MP40:
			return 2538;
			break;
		case W_AFTERBURNER:
			return 2538;
			break;
		case W_MG:
			return 1778;
			break;
		case W_BARRACUDA:
			return 1778;
			break;
		case W_PANZER:
			return 0;
			break;
		case W_LONGINUS:
			return 0;
			break;
		case W_PPSH:
			return 1255;
			break;
		case W_REAPER:
			return 1255;
			break;
		case W_PTRS:
			return 1500;
			break;
		case W_PENETRATOR:
			return 1500;
			break;
		case W_RAY:
			return 0;
			break;
		case W_PORTER:
			return 0;
			break;
		case W_SAWNOFF:
			return 1000;
			break;
		case W_SNUFF:
			return 1000;
			break;
		case W_STG:
			return 2400;
			break;
		case W_SPATZ:
			return 2400;
			break;
		case W_TRENCH:
			return 500;
			break;
		case W_GUT:
			return 500;
			break;
		case W_TYPE:
			return 1813;
			break;
		case W_SAMURAI:
			return 1813;
			break;
		case W_MP5:
			return 1255;
			break;
		case W_TESLA:
			return 1813;
			break;
	}
	return 0;
}

float(float weapon, float stance) CrossHairWeapon =
{

	float sprd;

	if (isCustomWeapon(weapon)) {
		sprd = CustomWeapons[weapon - 70].crossmin;
	}

	switch(weapon)
	{
		case W_COLT:
		case W_BIATCH:
			sprd = 15;
			break;
		case W_KAR:
		case W_ARMAGEDDON:
			sprd = 50;
			break;
		case W_THOMPSON:
		case W_GIBS:
			sprd = 10;
			break;
		case W_357:
		case W_KILLU:
			sprd = 10;
			break;
		case W_BAR:
		case W_WIDOW:
			sprd = 10;
			break;
		case W_BROWNING:
		case W_ACCELERATOR:
			sprd = 20;
			break;
		case W_DB:
		case W_BORE:
			sprd = 25;
			break;
		case W_FG:
		case W_IMPELLER:
			sprd = 10;
			break;
		case W_GEWEHR:
		case W_COMPRESSOR:
			sprd = 10;
			break;
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
			sprd = 50;
			break;
		case W_M1:
		case W_M1000:
			sprd = 10;
			break;
		case W_M1A1:
		case W_WIDDER:
			sprd = 10;
			break;
		case W_MP40:
		case W_AFTERBURNER:
			sprd = 10;
			break;
		case W_MG:
		case W_BARRACUDA:
			sprd = 20;
			break;
		case W_PANZER:
		case W_LONGINUS:
			sprd = 0;
			break;
		case W_PPSH:
		case W_REAPER:
			sprd = 10;
			break;
		case W_PTRS:
		case W_PENETRATOR:
			sprd = 50;
			break;
		case W_RAY:
		case W_PORTER:
			sprd = 10;
			break;
		case W_SAWNOFF:
		case W_SNUFF:
			sprd = 30;
			break;
		case W_STG:
		case W_SPATZ:
			sprd = 10;
			break;
		case W_TRENCH:
		case W_GUT:
			sprd = 25;
			break;
		case W_TYPE:
		case W_SAMURAI:
			sprd = 10;
			break;
		case W_MP5:
			sprd = 10;
			break;
		case W_TESLA:
			sprd = 0;
			break;
		default:
			sprd = 0;
			break;
	}
	
	if (sprd == 0)
		return 0;
	else {
		switch(stance) {
			case 2:
				return sprd;
			case 1:
				return sprd - 2;
			case 0:
				return sprd - 4;
			default: return 0;
		}
	}
}

float(float weapon, float stance) CrossHairMaxSpread =
{
	float sprd;

	if (isCustomWeapon(weapon)) {
		return CustomWeapons[weapon - 70].crossmax;
	}

	switch(weapon)
	{
		case W_COLT:
		case W_BIATCH:
			sprd = 30;
			break;
		case W_KAR:
		case W_ARMAGEDDON:
			sprd = 75;
			break;
		case W_THOMPSON:
		case W_GIBS:
			sprd = 25;
			break;
		case W_357:
		case W_KILLU:
			sprd = 20;
			break;
		case W_BAR:
		case W_WIDOW:
			sprd = 35;
			break;
		case W_BROWNING:
		case W_ACCELERATOR:
			sprd = 50;
			break;
		case W_DB:
		case W_BORE:
			sprd = 25;
			break;
		case W_FG:
		case W_IMPELLER:
			sprd = 40;
			break;
		case W_GEWEHR:
		case W_COMPRESSOR:
			sprd = 35;
			break;
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
			sprd = 75;
			break;
		case W_M1:
		case W_M1000:
			sprd = 35;
			break;
		case W_M1A1:
		case W_WIDDER:
			sprd = 35;
			break;
		case W_MP40:
		case W_AFTERBURNER:
			sprd = 25;
			break;
		case W_MG:
		case W_BARRACUDA:
			sprd = 50;
			break;
		case W_PANZER:
		case W_LONGINUS:
			sprd = 0;
			break;
		case W_PPSH:
		case W_REAPER:
			sprd = 25;
			break;
		case W_PTRS:
		case W_PENETRATOR:
			sprd = 75;
			break;
		case W_RAY:
		case W_PORTER:
			sprd = 20;
			break;
		case W_SAWNOFF:
		case W_SNUFF:
			sprd = 30;
			break;
		case W_STG:
		case W_SPATZ:
			sprd = 35;
			break;
		case W_TRENCH:
		case W_GUT:
			sprd = 25;
			break;
		case W_TYPE:
		case W_SAMURAI:
			sprd = 25;
			break;
		case W_MP5:
			sprd = 25;
			break;
		case W_TESLA:
			sprd = 0;
			break;
		default:
			sprd = 0;
			break;
	}

	if (sprd == 0)
		return 0;
	else {
		switch(stance) {
			case 2:
				return sprd;
			case 1:
				return sprd - 2;
			case 0:
				return sprd - 4;
			default:
				return 0;
		}
	}
}

float(float weapon, float type) GetLowAmmo = // determine what ammo value you should have that turns shells red
{

	if (isCustomWeapon(weapon)) {
		if (type) return CustomWeapons[weapon - 70].lowmag; else return CustomWeapons[weapon - 70].lowreserve;
	}

	switch (weapon)
	{
		case W_COLT: if (type) return 2; else return 16; 
		case W_KAR: if (type) return 1; else return 10;
		case W_KAR_SCOPE: if (type) return 1; else return 10;
		case W_M1A1: if (type) return 4; else return 24;
		case W_SAWNOFF: if (type) return 1; else return 12;
		case W_DB: if (type) return 1; else return 12;
		case W_THOMPSON: if (type) return 6; else return 40;
		case W_BAR: if (type) return 6; else return 28;
		case W_BIATCH: if (type) return 2; else return 16;
		case W_FG: if (type) return 8; else return 32;
		case W_357: if (type) return 2; else return 12; 
		case W_BROWNING: if (type) return 25; else return 125;
		case W_GEWEHR: if (type) return 3; else return 20;
		case W_M1: if (type) return 2; else return 24;
		case W_MP40: if (type) return 8; else return 64; 
		case W_MG: if (type) return 25; else return 125;
		case W_PANZER: if (type) return 0; else return 4;
		case W_PPSH: if (type) return 25; else return 71;
		case W_PTRS: if (type) return 2; else return 12; 
		case W_RAY: if (type) return 5; else return 40;
		case W_STG: if (type) return 12; else return 60;
		case W_TRENCH: if (type) return 2; else return 12;
		case W_TYPE: if (type) return 12; else return 60;
		case W_COMPRESSOR: if (type) return 3; else return 36;
		case W_M1000: if (type) return 3; else return 36;
		case W_GIBS: if (type) return 8; else return 80;
		case W_SAMURAI: if (type) return 12; else return 60;
		case W_AFTERBURNER: if (type) return 12; else return 64;
		case W_SPATZ: if (type) return 12; else return 120;
		case W_SNUFF: if (type) return 1; else return 14;
		case W_BORE: if (type) return 1; else return 14;
		case W_IMPELLER: if (type) return 12; else return 128;
		case W_BARRACUDA: if (type) return 25; else return 125;
		case W_ACCELERATOR: if (type) return 25; else return 125;
		case W_GUT: if (type) return 3; else return 15;
		case W_REAPER: if (type) return 23; else return 115;
		case W_HEADCRACKER: if (type) return 2; else return 16;
		case W_LONGINUS: if (type) return 1; else return 12;
		case W_PENETRATOR: if (type) return 2; else return 16;
		case W_WIDOW: if (type) return 6; else return 60;
		case W_PORTER: if (type) return 8; else return 40;
		case W_ARMAGEDDON: if (type) return 2; else return 15;
		case W_WIDDER: if (type) return 4; else return 30;
		case W_KILLU: if (type) return 2; else return 20;
		case W_TESLA: if (type) return 1; else return 6;
		case 0: if (type) return -1; else return -1;
		default: return 0;
	}
}

// PSP Specific!!
vector(float wep) GetWeaponRecoil =
{
	vector guaranteed, kick_change, final_kick;
	float change_1, change_2, change_3,total_recoil, r, temp1, temp2;
	switch (wep)
	{
		case W_COLT:
			guaranteed = '0 35 0';
			kick_change = '25 15 25';
			break;
		case W_BIATCH:
			guaranteed = '0 35 0';
			kick_change = '25 15 25';
			break;
		case W_357:
			guaranteed = '0 80 50';
			kick_change = '0 60 40';
			break;
		case W_KILLU:
			guaranteed = '0 80 50';
			kick_change = '0 60 40';
			break;
		case W_THOMPSON:
			kick_change = '74 74 85';
			break;
		case W_GIBS:
			kick_change = '74 74 85';
			break;
		case W_MP40:
			kick_change = '44 44 44';
			break;
		case W_AFTERBURNER:
			kick_change = '44 44 44';
			break;
		case W_TYPE:
			kick_change = '44 44 44';
			break;
		case W_SAMURAI:
			kick_change = '24 74 24';
			break;
		case W_PPSH:
			kick_change = '4 22 4';
			break;
		case W_REAPER:
			kick_change = '4 22 4';
			break;
		case W_GEWEHR:
			kick_change = '50 60 50';
			break;
		case W_COMPRESSOR:
			kick_change = '50 60 50';
			break;
		case W_M1:
			guaranteed = '0 35 0';
			kick_change = '30 30 30';
			break;
		case W_M1000:
			guaranteed = '0 35 0';
			kick_change = '30 30 30';
			break;
		case W_STG:
			kick_change = '15 44 15';
			break;
		case W_SPATZ:
			kick_change = '15 44 15';
			break;
		case W_M1A1:
			kick_change = '50 60 50';
			break;
		case W_WIDDER:
			kick_change = '50 60 50';
			break;
		case W_KAR:
			guaranteed = '0 50 0';
			kick_change = '25 30 25';
			break;
		case W_ARMAGEDDON:
			guaranteed = '0 50 0';
			kick_change = '25 30 25';
			break;
		case W_KAR_SCOPE:
			guaranteed = '0 50 0';
			kick_change = '25 30 25';
			break;
		case W_HEADCRACKER:
			guaranteed = '0 50 0';
			kick_change = '25 30 25';
			break;
		case W_PTRS:
			guaranteed = '0 100 85';
			kick_change = '0 95 75';
			break;
		case W_PENETRATOR:
			guaranteed = '0 100 85';
			kick_change = '0 95 75';
			break;
		case W_TRENCH:
			guaranteed = '0 100 85';
			kick_change = '0 95 75';
			break;
		case W_GUT:
			guaranteed = '0 100 85';
			kick_change = '0 95 75';
			break;
		case W_DB:
			guaranteed = '0 95 0';
			kick_change = '45 85 45';
			break;
		case W_BORE:
			guaranteed = '0 95 0';
			kick_change = '45 85 45';
			break;
		case W_SAWNOFF:
			guaranteed = '0 95 0';
			kick_change = '45 85 45';
			break;
		case W_SNUFF:
			guaranteed = '0 95 0';
			kick_change = '45 85 45';
			break;
		case W_BAR:
			kick_change = '0 50 0';
			break;
		case W_WIDOW:
			kick_change = '0 50 0';
			break;
		case W_MG:
			kick_change = '40 30 40';
			break;
		case W_BARRACUDA:
			kick_change = '40 30 40';
			break;
		case W_FG:
			kick_change = '30 45 0';
			break;
		case W_IMPELLER:
			kick_change = '30 45 0';
			break;
		case W_BROWNING:
			kick_change = '50 66 50';
			break;
		case W_ACCELERATOR:
			kick_change = '50 66 50';
			break;
		case W_TESLA:
			kick_change = '74 74 85';
			break;
	}
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
	//bprint	(vtos(final_kick));
	//bprint	("\n");
	return final_kick;
}

// Flash offset is multiplied because vectors have limited precision within qc
vector (float wep) GetWeaponFlash_Offset = 
{
		switch(wep) {
			case W_COLT:
			case W_BIATCH:
				return [5488, -2742, 35300];
			case W_KAR:
			case W_KAR_SCOPE:
			case W_HEADCRACKER:
			case W_ARMAGEDDON:
				return [5560, -4582, 75833];
			case W_THOMPSON:
			case W_GIBS:
				return [6203, -5740, 57670];
			case W_TRENCH:
			case W_GUT:
				return [5550, -4118, 62364];
			case W_357:
			case W_KILLU:
				return [8193, -2353, 50527];
			case W_MG:
			case W_BARRACUDA:
				return [6806, -9375, 81713];
			case W_DB: 
			case W_BORE:
				return [5801, -4300, 83174];
			case W_SAWNOFF:
				return [5801, -4414, 44820];
			case W_M1A1:
			case W_WIDDER:
				return [5317, -5331, 70583];
			case W_BAR:
			case W_WIDOW:
				return [3899, -5021, 78199];
			case W_FG:
			case W_IMPELLER:
				return [14000, -12000, 110000];
			case W_GEWEHR:
			case W_COMPRESSOR:
				return [6500, -8500, 65000];
			case W_PPSH:
				return [11100, -9000, 86300];
			case W_MP40:
			case W_AFTERBURNER:
				return [11300, -11300, 80000];
			case W_STG:
			case W_SPATZ:
				return [14300, -16230, 100000];
			case W_M1:
			case W_M1000:
				return [2896, -4142, 28300];
			case W_BROWNING:
			case W_ACCELERATOR:
				return [15726, -23375, 170713];
			case W_PTRS:
			case W_PENETRATOR:
				return [10988, -14242, 180300];
			case W_TYPE:
			case W_SAMURAI:
				return [488, -2300, 25300];
			default:
				return [5488, -2742, 35300];
		}
}

float (float wep) GetWeaponFlash_Size = {

	if (isCustomWeapon(wep)) {
		return CustomWeapons[wep - 70].flashsize;
	}

	switch(wep) {
		case W_COLT:
		case W_BIATCH:
			return 5;
		case W_KAR:
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
		case W_ARMAGEDDON:
			return 15;
		case W_THOMPSON:
		case W_GIBS:
			return 8;
		case W_TRENCH:
		case W_GUT:
			return 19;
		case W_357:
		case W_KILLU:
			return 7;
		case W_MG:
		case W_BARRACUDA:
			return 16;
		case W_DB: 
		case W_BORE:
			return 18;
		case W_SAWNOFF:
			return 20;
		case W_M1A1:
		case W_WIDDER:
			return 14;
		case W_BAR:
		case W_WIDOW:
			return 16;
		case W_FG:
		case W_IMPELLER:
			return 18;
		case W_GEWEHR:
		case W_COMPRESSOR:
			return 12;
		case W_PPSH:
			return 14;
		case W_MP40:
		case W_AFTERBURNER:
			return 14;
		case W_STG:
		case W_SPATZ:
			return 16;
		case W_M1:
		case W_M1000:
			return 5;
		case W_BROWNING:
		case W_ACCELERATOR:
			return 27;
		case W_PTRS:
		case W_PENETRATOR:
			return 30;
		case W_TYPE:
		case W_SAMURAI:
			return 5;
		default:
			return 5;
	}
}