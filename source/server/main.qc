//
//	Main.qc - mostly functions that will be called from the engine and are expected to exist
//
void() LightStyles_setup;
void() SUB_Remove = {remove(self);}

//called when starting server/loading the map
void() main =
{
	localcmd("echo Server starting...\n");
}

//called for each frame that QC runs
float zombie_cleaned_w;
void() StartFrame =
{
	deathmatch = cvar("deathmatch");
	//coop = cvar("coop");
	framecount = framecount + 1;

	if (waypoint_mode) {
		if (!zombie_cleaned_w) {
				entity zent;
				zent = find (world, classname, "ai_zombie");
				while (zent)
				{
					/*
					if (zent.head)
						remove (zent.head);
					if (zent.larm)
						remove (zent.larm);
					if (zent.rarm)
						remove (zent.rarm);
					*/
					remove (zent);
					zent = find (zent, classname, "ai_zombie");
				}
				zombie_cleaned_w = true;
				
				zent = find (world, classname, "waypoint");
				while (zent)
				{
					if (zent.targetname)
						setmodel(zent, "models/way/normal_way_door.spr");
					else
						setmodel(zent, "models/way/normal_way.spr");
					zent = find (zent, classname, "waypoint");
				}
				zent = find (world, classname, "door_nzp_cost");
				while (zent)
				{
					zent.solid = SOLID_NOT;
					zent.touch = SUB_Null;
					zent = find (zent, classname, "door_nzp_cost");
				}
				zent = find (world, classname, "door_nzp");
				while (zent)
				{
					zent.solid = SOLID_NOT;
					zent.touch = SUB_Null;
					zent.solid = SOLID_NOT;
					zent = find (zent, classname, "door_nzp");
				}
				zent = find (world, classname, "window");
				while (zent)
				{
					zent.solid = SOLID_NOT;
					zent.touch = SUB_Null;
					zent = find (zent, classname, "window");
				}
			}
			return;
		}
		
	
	if (roundinit) {
		Round_Core();
		Do_Zombie_AI ();
	} else {
	
		entity SpawnedIn;
		SpawnedIn = find(world, classname, "player");
	
		if (SpawnedIn) {
			entity getdog = find(world, classname, "spawn_dog");
			if (getdog)
				gotdog = 1;
			else 
				gotdog = 0;
				
			updateDogRound();
			InitRounds();
		}
	}
}
string(string s) precache_model         = #20;

void() precaches = 
{
	precache_model ("models/player.mdl");
	
	#ifndef PSP
	#ifndef NX
	precache_model ("models/v_morphine.mdl");

	if (world.song != "")
		precache_sound (world.song);
	#endif
	#endif
	
	precache_model ("progs/Sprites/revive.spr");
	precache_model ("progs/Sprites/revive_white.spr");
	
	precache_model ("models/ai/zfull.mdl");
	precache_model ("models/ai/zlarm.mdl");
	precache_model ("models/ai/zrarm.mdl");
	precache_model ("models/ai/zbod.mdl");
	precache_model ("models/ai/zhead.mdl");
	
	precache_model ("models/ai/zcfull.mdl");
	precache_model ("models/ai/zcbod.mdl");
	precache_model ("models/ai/zclarm.mdl");
	precache_model ("models/ai/zcrarm.mdl");
	precache_model ("models/ai/zchead.mdl");

	precache_model ("progs/Misc/maxammo!.mdl");
	precache_model ("progs/Misc/x2!.mdl");
	precache_model ("progs/Misc/instakill!.mdl");
	precache_model ("progs/Misc/nuke!.mdl");
	precache_model ("progs/Misc/carpenter!.mdl");
	precache_model ("progs/Misc/perkbottle!.mdl");
	
	precache_sound("sounds/player/footstep1.wav");
	precache_sound("sounds/player/footstep2.wav");
	precache_sound("sounds/player/footstep3.wav");
	precache_sound("sounds/player/footstep4.wav");
	precache_sound("sounds/player/footstep5.wav");
	precache_sound("sounds/player/jump.wav");
	precache_sound("sounds/player/land.wav");
	precache_sound("sounds/player/pain4.wav");

	precache_sound("sounds/weapons/colt/magin.wav");
	precache_sound("sounds/weapons/colt/magout.wav");
	precache_sound("sounds/weapons/colt/shoot.wav");
	precache_sound("sounds/weapons/colt/slide.wav");

	precache_sound("sounds/weapons/papfire.wav");
	
	precache_sound("sounds/weapons/grenade/prime.wav");
	precache_sound("sounds/weapons/grenade/throw.wav");
	precache_sound("sounds/weapons/grenade/explode.wav");
	
	precache_sound("sounds/weapons/knife/knife_hitbod.wav");
	precache_sound("sounds/weapons/knife/knife.wav");
	precache_sound("sounds/weapons/knife/knife_hit.wav");
	
	precache_sound("sounds/rounds/eround.wav");
	precache_sound("sounds/rounds/nround.wav");
	precache_sound("sounds/rounds/splash.wav");
	precache_sound("sounds/music/end.wav");
	precache_sound("sounds/null.wav");

	precache_sound("sounds/misc/buy.wav");
	precache_sound("sounds/misc/wood_door.wav");
	precache_sound("sounds/misc/debris.wav");
	precache_sound("sounds/misc/denybuy.wav");
	
	precache_sound("sounds/misc/what.wav");

	precache_model ("models/weapons/m1911/v_colt.mdl");
	precache_model ("models/weapons/m1911/g_colt.mdl");
	precache_model ("progs/VModels/v_knife.mdl");
	precache_model ("progs/VModels/v_nade.mdl");
	precache_model ("progs/GModels/g_grenade.mdl");
	precache_model ("progs/GModels/g_betty.mdl");	
	precache_model ("progs/VModels/v_betty.mdl");	

	//sprites
	precache_model ("models/way/current_way.spr");
	precache_model ("models/way/current_way_door.spr");
	precache_model ("models/way/last_way.spr");
	precache_model ("models/way/last_way_door.spr");
	precache_model ("models/way/normal_way.spr");
	precache_model ("models/way/normal_way_door.spr");
	precache_model ("models/way/way_jump.spr");
	precache_model ("models/way/way_land.spr");
	precache_model ("progs/Sprites/sprkle.spr");


	
	//Walk
	
	precache_sound ("sounds/zombie/w0.wav");
	precache_sound ("sounds/zombie/w1.wav");
	precache_sound ("sounds/zombie/w2.wav");
	precache_sound ("sounds/zombie/w3.wav");
	precache_sound ("sounds/zombie/w4.wav");
	precache_sound ("sounds/zombie/w5.wav");
	precache_sound ("sounds/zombie/w6.wav");
	precache_sound ("sounds/zombie/w7.wav");
	precache_sound ("sounds/zombie/w8.wav");
	precache_sound ("sounds/zombie/w9.wav");
	//Run
	precache_sound ("sounds/zombie/r0.wav");
	precache_sound ("sounds/zombie/r1.wav");
	precache_sound ("sounds/zombie/r2.wav");
	precache_sound ("sounds/zombie/r3.wav");
	precache_sound ("sounds/zombie/r4.wav");
	precache_sound ("sounds/zombie/r5.wav");
	precache_sound ("sounds/zombie/r6.wav");
	precache_sound ("sounds/zombie/r7.wav");
	precache_sound ("sounds/zombie/r8.wav");
	precache_sound ("sounds/zombie/r9.wav");
	//Attack
	precache_sound ("sounds/zombie/a0.wav");
	precache_sound ("sounds/zombie/a1.wav");
	precache_sound ("sounds/zombie/a2.wav");
	precache_sound ("sounds/zombie/a3.wav");
	precache_sound ("sounds/zombie/a4.wav");
	precache_sound ("sounds/zombie/a5.wav");
	precache_sound ("sounds/zombie/a6.wav");
	precache_sound ("sounds/zombie/a7.wav");
	//Death
	precache_sound ("sounds/zombie/d0.wav");
	precache_sound ("sounds/zombie/d1.wav");
	precache_sound ("sounds/zombie/d2.wav");
	precache_sound ("sounds/zombie/d3.wav");
	precache_sound ("sounds/zombie/d4.wav");
	precache_sound ("sounds/zombie/d5.wav");
	precache_sound ("sounds/zombie/d6.wav");
	precache_sound ("sounds/zombie/d7.wav");
	//Taunt
	precache_sound ("sounds/zombie/t0.wav");
	precache_sound ("sounds/zombie/t1.wav");
	precache_sound ("sounds/zombie/t2.wav");
	precache_sound ("sounds/zombie/t3.wav");
	precache_sound ("sounds/zombie/t4.wav");
	//Footsteps
	precache_sound ("sounds/zombie/s0.wav");
	precache_sound ("sounds/zombie/s1.wav");
	precache_sound ("sounds/zombie/sc0.wav");
	precache_sound ("sounds/zombie/sc1.wav");
	//Announce
	precache_sound ("sounds/pu/pickup.wav");
	precache_sound ("sounds/pu/carpenter.wav");
	precache_sound ("sounds/pu/maxammo.wav");
	precache_sound ("sounds/pu/double_points.wav");
	precache_sound ("sounds/pu/insta_kill.wav");
	precache_sound ("sounds/pu/nuke.wav");
	precache_sound ("sounds/pu/byebye.wav");
	precache_sound ("sounds/pu/powerup.wav");
	precache_sound ("sounds/pu/drop.wav");

	#ifdef PC
	// Moto -- FIXME: compile FTE to remove this engine sound request
	precache_sound ("demon/dland2.wav");
	#endif
}

//called when map loaded
void() worldspawn =
{
	precaches();
	LightStyles_setup();

	#ifdef PC
	clientstat(STAT_CURRENTMAG, EV_FLOAT, currentmag);
	clientstat(STAT_CURRENTMAG2, EV_FLOAT, currentmag2);
	clientstat(STAT_POINTS, EV_FLOAT, points);
	clientstat(STAT_WEAPON2FRAME, EV_FLOAT, weapon2frame);
	clientstat(STAT_WEAPON2MODEL, EV_STRING, weapon2model);
	clientstat(STAT_GRENADES, EV_FLOAT, primary_grenades);
	clientstat(STAT_SECGRENADES, EV_FLOAT, secondary_grenades);
	clientstat(STAT_PROGRESSBAR, EV_FLOAT, progress_bar_percent);
	clientstat(STAT_WEAPONDURATION, EV_FLOAT, weapon_animduration);
	clientstat(STAT_WEAPON2DURATION, EV_FLOAT, weapon2_animduration);
	clientstat(STAT_WEAPONZOOM, EV_FLOAT, zoom);
	clientstat(STAT_INSTA, EV_FLOAT, insta_icon);
	clientstat(STAT_X2, EV_FLOAT, x2_icon);
	clientstat(STAT_SPECTATING, EV_FLOAT, isspec);
	clientstat(STAT_PLAYERNUM, EV_FLOAT, playernum);		// literally useless but will be kept in case
	clientstat(STAT_PLAYERSTANCE, EV_FLOAT, stance);
	clientstat(STAT_FACINGENEMY, EV_FLOAT, facingenemy);
	#endif
	
	mappath = strcat("maps/", mapname);
	mappath = strzone(mappath);

	LoadWaypointData();
		
	//set game elements
	G_STARTPOINTS = 500;
	G_STARTROUND = 1;
	G_PRONEPOINTS = 0;
	G_STARTWEAPON[0] = W_COLT;
	G_STARTWEAPON[1] = 8;
	G_STARTWEAPON[2] = 32;
	G_WORLDTEXT = 1;
	G_PERKS = 0;
	G_PERKPOWER = 0;
	load_nzd();
	
}

void() SpectatorConnect =
{
	bprint(PRINT_HIGH, self.netname);
	bprint(PRINT_HIGH, " has joined the spectators.\n");
}

void() RelinkZombies =
{
	entity ent,ent2;
	local float i;
	local vector min, max;


	//warn
	ent = ent2 = world;

	while ((ent = find (ent, classname, "ai_zombie")))
	{
		if(ent.currentHitBoxSetup == 0)//empty bbox, we don't care to update
			continue;
		
		makevectors (ent.angles);
		
		for(i = 0; i < 3; i++)
		{
			if(i == 0)
				ent2 = ent.head;
			if(i == 1)
				ent2 = ent.larm;
			if(i == 2)
				ent2 = ent.rarm;
				
			
			if (ent2)
			{
				//setorigin (ent.head, ent.origin + v_right * ent.head.view_ofs_x + v_forward * ent.head.view_ofs_y + v_up * ent.head.view_ofs_z);
				setorigin (ent2, ent.origin);
				//fixme, move angles set and frame set to below the continue, we only want to update origin (maybe angles too?)
				ent2.angles = ent.angles;
				
				if(ent2.deadflag)
					ent2.frame = ent.frame; 
				
				//if(OnlyOrigin)
				//	continue;
					
				min = ent2.bbmins + (v_right * ent2.view_ofs_x) + (v_forward * ent2.view_ofs_y) + (v_up * ent2.view_ofs_z);
				max = ent2.bbmaxs + (v_right * ent2.view_ofs_x) + (v_forward * ent2.view_ofs_y) + (v_up * ent2.view_ofs_z);
				
				if(min_x > max_x) { min_x += max_x; max_x = min_x - max_x; min_x -= max_x; }
				if(min_y > max_y) { min_y += max_y; max_y = min_y - max_y; min_y -= max_y; }
				if(min_z > max_z) { min_z += max_z; max_z = min_z - max_z; min_z -= max_z; }
				
				setsize(ent2,min,max);
			}

		}
	}
}

void() EndFrame =
{
	RelinkZombies();
};