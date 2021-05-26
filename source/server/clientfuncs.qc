// 
//		Clientfuncs -- used to communicate between server and client
//

void SetUpdate(entity client, float type, float val1, float val2, float val3)
{
	#ifndef PSP
	#ifndef NX
	if (type != 2)
	{
		msg_entity = client;
		WriteByte(MSG_ONE, SVC_CGAMEPACKET);
		WriteByte(MSG_ONE, EVENT_UPDATE);
		WriteByte(MSG_ONE, type); // UT_HUD
		WriteByte(MSG_ONE, val1); 
		WriteByte(MSG_ONE, val2);
		WriteByte(MSG_ONE, val3); // misc flags/vars for later if needed
	}
	else
	{
		WriteByte(MSG_ALL, SVC_CGAMEPACKET);
		WriteByte(MSG_ALL, EVENT_UPDATE);
		WriteByte(MSG_ALL, type); // UT_ROUNDS_CHANGE
		WriteByte(MSG_ALL, val1); 
		WriteByte(MSG_ALL, val2);
		WriteByte(MSG_ALL, val3); // misc flags/vars for later if needed
	}
	#endif
	#endif
}

#ifndef PSP
#ifndef NX
void(entity to, float type, float cost, float weapon) useprint = {
	
    msg_entity = to;
	WriteByte(MSG_ONE, SVC_CGAMEPACKET);
	WriteByte(MSG_ONE, EVENT_USEPRINT);
	WriteByte(MSG_ONE, type);
	WriteShort(MSG_ONE, cost);
	WriteByte(MSG_ONE, weapon);
	
}
#endif
#endif

void(vector org) CallExplosion = {
    #ifndef PC
    WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);
    #else
    WriteByte(MSG_ALL, SVC_CGAMEPACKET);
	WriteByte(MSG_ALL, EVENT_EXPLOSION);
	WriteCoord(MSG_ALL, org_x);
	WriteCoord(MSG_ALL, org_y);
	WriteCoord(MSG_ALL, org_z);
    #endif
}

void NotifyNewRound(float to) {
	#ifndef PSP
	#ifndef NX
	
	WriteByte(MSG_ALL, SVC_CGAMEPACKET);
	WriteByte(MSG_ALL, EVENT_NEWROUND);
	WriteByte(MSG_ALL, to);
	
	#endif
	#endif
}

void SetRound(entity client, float to) {
	#ifndef PSP
	#ifndef NX
	
    msg_entity = client;
	WriteByte(MSG_ONE, SVC_CGAMEPACKET);
	WriteByte(MSG_ONE, EVENT_SETROUND);
	WriteByte(MSG_ONE, to);
	
	#endif
	#endif
}

void SetPerk(entity client, float to) 
{
	#ifndef PSP
	#ifndef NX
	
    	msg_entity = client;
	WriteByte(MSG_ONE, SVC_CGAMEPACKET);
	WriteByte(MSG_ONE, EVENT_PERK);
	WriteLong(MSG_ONE, to);
	
	#endif
	#endif
}

void(float to) SwitchWeapon =
{
	#ifndef PSP
	#ifndef NX
	
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_WEAPONCHANGE);
	WriteByte(MSG_MULTICAST, to);
	msg_entity = self;
	multicast('0 0 0', MULTICAST_ONE);

	// hotfix for weapon2models not reseting
	self.weapon2model = GetWeapon2Model(to);
	
	#endif
	#endif
}

void(string to, float skin) UpdateVmodel =
{
	#ifndef PSP
	#ifndef NX
	
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_UPDATEVMODEL);
	WriteString(MSG_MULTICAST, to);
	WriteByte(MSG_MULTICAST, skin);
	msg_entity = self;
	multicast('0 0 0', MULTICAST_ONE);
	
	#endif
	#endif
}

void(string to, float skin) UpdateV2model =
{
	#ifndef PSP
	#ifndef NX
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_UPDATEV2MODEL);
	WriteString(MSG_MULTICAST, to);
	WriteByte(MSG_MULTICAST, skin);
	msg_entity = self;
	multicast('0 0 0', MULTICAST_ONE);
	#endif	
	#endif
}

void(float broadcast_time, float type) BroadcastMessage =
{
	#ifndef PSP
	#ifndef NX
	WriteByte(MSG_ALL, SVC_CGAMEPACKET);
	WriteByte(MSG_ALL, EVENT_BROADCAST);
	WriteByte(MSG_ALL, broadcast_time);
	WriteByte(MSG_ALL, type);
	
	#endif
	#endif
}

void(float playernum, float points, float am, float kills, string name, entity person) UpdatePlayerPoints =
{
	#ifndef PSP
	#ifndef NX
	if (player_count == 0) {
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_POINTUPDATE);
		WriteByte(MSG_MULTICAST, playernum);
		WriteLong(MSG_MULTICAST, points);
		WriteLong(MSG_MULTICAST, am);
		WriteLong(MSG_MULTICAST, kills);
		WriteString(MSG_MULTICAST, name);
		msg_entity = person;
		multicast('0 0 0', MULTICAST_ONE);
	}
	else {
		WriteByte(MSG_ALL, SVC_CGAMEPACKET);
		WriteByte(MSG_ALL, EVENT_POINTUPDATE);
		WriteByte(MSG_ALL, playernum);
		WriteLong(MSG_ALL, points);
		WriteLong(MSG_ALL, am);
		WriteLong(MSG_ALL, kills);
		WriteString(MSG_ALL, name);
	}
	
	#endif
	#endif
}

void(float count) UpdatePlayerCount = {
	#ifndef PSP
	#ifndef NX
	if (count == 0)
		return;
	else {
		WriteByte(MSG_ALL, SVC_CGAMEPACKET);
		WriteByte(MSG_ALL, EVENT_PLAYERUPDATE);
		WriteByte(MSG_ALL, count);
	}

	#endif
	#endif
}

void(float newtime, float newtype, entity change) PromptLevelChange = 
{
	#ifndef PSP
	#ifndef NX
	
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_BLACKOUT);
	WriteByte(MSG_MULTICAST, newtime);
	WriteByte(MSG_MULTICAST, newtype);
	msg_entity = change;
	multicast('0 0 0', MULTICAST_ONE);
	
	#endif
	#endif
}

void(entity who) UpdatePunchangle =	
{		

	// naievil -- shit logic lol...but result looks clean as fuck...
	#ifndef PSP
	#ifndef NX
	WriteByte(MSG_ONE, SVC_CGAMEPACKET);
	WriteByte(MSG_ONE, EVENT_PUNCHANGLE);
	WriteCoord(MSG_ONE, who.punchangle_x);
	WriteCoord(MSG_ONE, who.punchangle_y);
	WriteCoord(MSG_ONE, who.punchangle_z);
	
	vector tempv = who.punchangle;
		
	if (fabs(who.punchangle_x) > 0.01) {
		if (who.punchangle_x >= 0.05*tempv_x)
			who.punchangle_x -= 0.05*tempv_x;
		else if (who.punchangle_x <= -0.05*tempv_x)
			who.punchangle_x -= 0.05*tempv_x;
		else
			who.punchangle_x = 0;
	} else 
		who.punchangle_x = 0;
		
	if (fabs(who.punchangle_y) > 0.01) {
		if (who.punchangle_y >= 0.05*tempv_y)
			who.punchangle_y -= 0.05*tempv_y;
		else if (who.punchangle_y <= -0.05*tempv_y)
			who.punchangle_y -= 0.05*tempv_y;
		else 
			who.punchangle_y = 0;
	} else 
		who.punchangle_y = 0;
		
	if (fabs(who.punchangle_z) > 0.01) {
		if (who.punchangle_z >= 0.05*tempv_z)
			who.punchangle_z -= 0.05*tempv_z;
		else if (who.punchangle_z <= -0.05*tempv_z)
			who.punchangle_z -= 0.05*tempv_z;
		else 
			who.punchangle_z = 0;
	} else 
		who.punchangle_z = 0;
		
	#endif
	#endif
}

#ifndef PSP
#ifndef NX
void(string h, float h2, entity who) pushHUD = {
	if (player_count == 0) {
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_HUDUPDATE);
		WriteString(MSG_MULTICAST, h);
		WriteByte(MSG_MULTICAST, h2);
		msg_entity = who;
		multicast('0 0 0', MULTICAST_ONE);
	} else {
		WriteByte(MSG_ALL, SVC_CGAMEPACKET);
		WriteByte(MSG_ALL, EVENT_WEAPONUPDATE);
		WriteString(MSG_ALL, h);
		WriteByte(MSG_ALL, h2);
	}
}

void (float wepnum, string wepname, string wvmodel, float mag, float reserve, string ads, float min, float max, string flash, float flashsize, string v2, float isd, entity who) sendCustomWeapon = {
	if (player_count == 0) {
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_WEAPONUPDATE);
		WriteByte(MSG_MULTICAST, wepnum);
		WriteString(MSG_MULTICAST, wepname);
		WriteString(MSG_MULTICAST, wvmodel);
		WriteByte(MSG_MULTICAST, mag);
		WriteByte(MSG_MULTICAST, reserve);
		WriteString(MSG_MULTICAST, ads);
		WriteByte(MSG_MULTICAST, min);
		WriteByte(MSG_MULTICAST, max);
		WriteString(MSG_MULTICAST, flash);
		WriteByte(MSG_MULTICAST, flashsize);
		WriteString(MSG_MULTICAST, v2);
		WriteByte(MSG_MULTICAST, isd);
		msg_entity = who;
		multicast('0 0 0', MULTICAST_ONE);
	} else {
		WriteByte(MSG_ALL, SVC_CGAMEPACKET);
		WriteByte(MSG_ALL, EVENT_WEAPONUPDATE);
		WriteByte(MSG_ALL, wepnum);
		WriteString(MSG_ALL, wepname);
		WriteString(MSG_ALL, wvmodel);
		WriteByte(MSG_ALL, mag);
		WriteByte(MSG_ALL, reserve);
		WriteString(MSG_ALL, ads);
		WriteByte(MSG_ALL, min);
		WriteByte(MSG_ALL, max);
		WriteString(MSG_ALL, flash);
		WriteByte(MSG_ALL, flashsize);
		WriteString(MSG_ALL, v2);
		WriteByte(MSG_ALL, isd);
	}
}

void(string msg, entity who) ScrollText = {
	if (player_count == 0) {
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_SCROLLTEXT);
		WriteString(MSG_MULTICAST, msg);
		msg_entity = who;
		multicast('0 0 0', MULTICAST_ONE);
	} else {
		WriteByte(MSG_ALL, SVC_CGAMEPACKET);
		WriteByte(MSG_ALL, EVENT_SCROLLTEXT);
		WriteString(MSG_ALL, msg);
	}
}

void(string chaptertitle, string location, string date, string person, entity who) WorldText = {
	if (player_count == 0) {
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_WORLDDATA);
		WriteString(MSG_MULTICAST, chaptertitle);
		WriteString(MSG_MULTICAST, location);
		WriteString(MSG_MULTICAST, date);
		WriteString(MSG_MULTICAST, person);
		msg_entity = who;
		multicast('0 0 0', MULTICAST_ONE);
	} else {
		WriteByte(MSG_ALL, SVC_CGAMEPACKET);
		WriteByte(MSG_ALL, EVENT_WORLDDATA);
		WriteString(MSG_ALL, chaptertitle);
		WriteString(MSG_ALL, location);
		WriteString(MSG_ALL, date);
		WriteString(MSG_ALL, person);
	}
}
#endif
#endif

#ifndef NX
void (float achievement_id, optional entity who) GiveAchievement =
{
#ifdef PSP
	// temp
	if (achievement_id > 4)
		return;
#endif // PSP

	// this is an achievement specific to an individual
	if ((who && who != world) || player_count == 0) {
		if (player_count == 0) who = find(world, classname, "player");
#ifdef PSP
		achievement(who, achievement_id);
#else
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_ACHIEVEMENT);
		WriteByte(MSG_MULTICAST, achievement_id);
		msg_entity = who;
		multicast('0 0 0', MULTICAST_ONE);
#endif // PSP
	} else {
#ifdef PSP
		entity players;
		players = find(world, classname, "player");
		while(players != world) {
			achievement(players, achievement_id);
			players = find(players, classname, "player");
		}
#else
		WriteByte(MSG_ALL, SVC_CGAMEPACKET);
		WriteByte(MSG_ALL, EVENT_ACHIEVEMENT);
		WriteByte(MSG_ALL, achievement_id);
#endif // PSP
	}
}

void (float achievement_id, float progress_value, optional entity who) UpdateAchievementProgress =
{
#ifdef PSP
	// temp
	if (achievement_id > 4)
		return;
#endif // PSP
	// this is a progress update specific to an individual
	if ((who && who != world) || player_count == 0) {
		if (player_count == 0) who = find(world, classname, "player");
#ifdef PSP
		//achievement_progress(who, achievement_id, progress_value);
#else
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_ACHIEVEMENTPROGRESS);
		WriteByte(MSG_MULTICAST, achievement_id);
		WriteFloat(MSG_MULTICAST, progress_value);
		msg_entity = who;
		multicast('0 0 0', MULTICAST_ONE);
#endif // PSP
	} else {
#ifdef PSP
		entity players;
		players = find(world, classname, "player");
		while(players != world) {
			//achievement_progress(players, achievement_id, progress_value);
			players = find(players, classname, "player");
		}
#else
		WriteByte(MSG_ALL, SVC_CGAMEPACKET);
		WriteByte(MSG_ALL, EVENT_ACHIEVEMENTPROGRESS);
		WriteByte(MSG_ALL, achievement_id);
		WriteFloat(MSG_ALL, progress_value);
#endif // PSP
	}
}
#endif // NX

// *****************************************
// Unrelated to engine, but custom functions
// *****************************************

float(entity who, entity target) isFacing =
{
	float who_angle = who.angles_y;
	float target_angle = target.angles_y;

	float difference_angle = target_angle - who_angle;

	#ifdef PSP
	if (difference_angle < -45) {
		difference_angle += 360;
	}
	#endif

	// 180 = directly facing each other, 30 degree buffer.
	if (difference_angle <= 210 && difference_angle >= 150)
		return true;

	return false;
}

float() crandom =
{
	return 2*(random() - 0.5);
}

void WeaponSwitch(entity player) {
	float wep, cmag, cmag2, cammo;

	wep = other.weapon;
	other.weapon = other.secondaryweapon;
	other.secondaryweapon = wep;

	cmag = other.currentmag;
	other.currentmag = other.secondarymag;
	other.secondarymag = cmag;

	cmag2 = other.currentmag2;
	other.currentmag2 = other.secondarymag2;
	other.secondarymag2 = cmag2;

	cammo = other.currentammo;
	other.currentammo = other.secondaryammo;
	other.secondaryammo = cammo;

	entity tempe = self;
	self = player;
	SwitchWeapon(other.weapon);
	self = tempe;
}

void(entity person, float expamt, float doublepoint) addmoney =
{
	if (person.classname != "player" || person.downed)
		return;

	if (expamt > 0 && doublepoint == TRUE && x2_finished > time) {
		expamt *= 2;
		person.score += expamt;
	}

	person.points += expamt;
		
	UpdatePlayerPoints(person.playernum, person.points, expamt, person.kills, person.netname, person);
};
