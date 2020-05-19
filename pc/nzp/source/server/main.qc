//
//	Main.qc - mostly functions that will be called from the engine and are expected to exist
//

//called when starting server/loading the map
void() main =
{
	localcmd("echo Server starting...\n");

}

//called for each frame that QC runs
void() StartFrame =
{
	deathmatch = cvar("deathmatch");
	coop = cvar("coop");
	framecount = framecount + 1;

	if (waypoint_mode) 
	{
		return;
	}
	if (navmesh_edit_mode)
	{
		return;
	}
	
	if (roundinit) 
	{
		Round_Core();
		Do_Zombie_AI ();
	}
	else 
	{
		entity SpawnedIn;
		SpawnedIn = find(world, classname, "player");
	
		if (SpawnedIn)
			InitRounds();
	}
}

//called when map loaded
void() worldspawn =
{
	precache_model ("models/player.mdl");
	
	precache_model ("models/ai/zfull.mdl");
	precache_model ("models/ai/zb#.mdl");
	precache_model ("models/ai/zal(.mdl");
	precache_model ("models/ai/zar(.mdl");
	precache_model ("models/ai/zh^.mdl");
	
	precache_model ("models/ai/zcfull.mdl");
	precache_model ("models/ai/zbc#.mdl");
	precache_model ("models/ai/zalc(.mdl");
	precache_model ("models/ai/zarc(.mdl");
	precache_model ("models/ai/zhc^.mdl");
	
	precache_sound("sounds/player/footstep1.wav");
	precache_sound("sounds/player/footstep2.wav");
	precache_sound("sounds/player/footstep3.wav");
	precache_sound("sounds/player/footstep4.wav");
	precache_sound("sounds/player/footstep5.wav");
	precache_sound("sounds/player/jump.wav");
	precache_sound("sounds/player/land.wav");
	precache_sound("sounds/items/health.wav");
	precache_sound("sounds/items/respawn.wav");

	precache_sound("sounds/weapons/colt/magin.wav");
	precache_sound("sounds/weapons/colt/magout.wav");
	precache_sound("sounds/weapons/colt/shoot.wav");
	precache_sound("sounds/weapons/colt/slide.wav");

	precache_sound("sounds/weapons/papfire.wav");
	
	precache_sound("sounds/weapons/grenade/prime.wav");
	precache_sound("sounds/weapons/grenade/throw.wav");
	
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

	
	precache_model ("models/weapons/m1911/v_colt.mdl");
	precache_model ("models/weapons/m1911/g_colt.mdl");
	precache_model ("progs/VModels/v_nade.mdl");
	precache_model ("progs/GModels/g_grenade.mdl");
	precache_model ("progs/GModels/g_betty.mdl");

	
	
	//sprites
	precache_model ("models/way/current_way.spr");
	precache_model ("models/way/current_way_door.spr");
	precache_model ("models/way/last_way.spr");
	precache_model ("models/way/last_way_door.spr");
	precache_model ("models/way/normal_way.spr");
	precache_model ("models/way/normal_way_door.spr");
	precache_model ("models/way/way_jump.spr");
	precache_model ("models/way/way_land.spr");


	
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

	mappath = strcat("maps/", mapname);
	mappath = strzone(mappath);
	
	sv_gravity = cvar("sv_gravity");
	sv_maxspeed = cvar("sv_maxspeed");
	
	print("Gravity: ",ftos(sv_gravity),", maxspeed: ",ftos(sv_maxspeed),"\n");

	LoadWaypointData();
	sv_load_navmesh_data();
	
	//Allocating memory for the zombie's pathfinding data
	sv_zombie_pathfind_result = memalloc(sizeof(pathfind_result) * MAX_ZOMBIES);
	//I should technically deallocate the memory, but I've nowhere to put this, and it SHOULD be cleared automatically upon vm reset
	//memfree(sv_zombie_pathfind_result);
}

void() SpectatorConnect =
{
	bprint(PRINT_HIGH, self.netname);
	bprint(PRINT_HIGH, " has joined the spectators.\n");
}

