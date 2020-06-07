float() spawn_a_dogA;

void() Spawn_Enemy = 
{
	if (roundtype == 1)
	{
		if (spawn_a_zombieA())
		{
			Current_Zombies = Current_Zombies + 1;
		}
	}
	else if (roundtype == 2)
	{
		if (spawn_a_dogA())
		{
			Current_Zombies = Current_Zombies + 1;
		}
	}
}

float() getZombieTotal = {
	if (roundtype == 1) {
		local float count;

		count = 0;

		if(player_count == 0) {
			count += 24;
		} else {
			count += rint((player_count) * 24);
		}

		//bprint(PRINT_HIGH, strcat("STARTING WITH: ", ftos(count), "\n"));

		if (rounds == 1) {
			count = rint(count * 0.25);
		} else if (rounds < 3) {
			count = rint(count * 0.3);
		} else if (rounds < 4) {
			count = rint(count * 0.5);
		} else if (rounds < 5){
			count = rint(count * 0.7);
		} else if (rounds < 6) {
			count = rint(count * 0.9);
		}

		//bprint(PRINT_HIGH, strcat("GOT TOTAL AS: ", ftos(count), "\n"));

		return count;
	} else { //dogs
		// 2 waves
		if (rounds <= 14)
			return 6 * (player_count + 1);

		return 8 * (player_count + 1);
	}
	return 0;
}

void(string s) playSoundAtPlayers =
{
	local entity p;
	p = find(world,classname,"player");
	while(p)
	{
		sound(p,CHAN_AUTO,s,1,ATTN_NONE);
		p = find(p,classname,"player");
	}
}

void() updateDogRound =
{
	float r = random();

	if (r < 0.33) {
		dogRound = rounds + 5;
	} else if (r < 0.66) {
		dogRound = rounds + 6;
	} else {
		dogRound = rounds + 7;
	}
}

void() EndRound =
{
	rounds_change = 4;
	SetUpdate(self, UT_ROUNDS_CHANGE, rounds_change, 0, 0);
	if (gotdog && rounds == dogRound) {
		playSoundAtPlayers("sounds/rounds/droundend.wav");
		dogWave = false;
	} else {
		playSoundAtPlayers("sounds/rounds/eround.wav");
	}
	round_changetime = time + 5;
}

void() PlayerSpawn;

void() NewRound =
{		
	entity who = find(world,classname,"spectator");
	while(who != world)
	{
		if(who.isspec)
		{
			self = who;
			PlayerSpawn();
			break;
		}
		
	}

	entity tempe;
	round_changetime = 0;
	spawn_time = time + 5;
	sounds_playing = 0;//just in case it ever somehow glitches
	if (delay_at_round > 0.08)
	{
		delay_at_round = delay_at_round*0.95;
		if (delay_at_round < 0.08)
			delay_at_round = 0.08;
	}
	if (rounds != 0)
	{
		if (gotdog && rounds == (dogRound - 1)) {
			playSoundAtPlayers("sounds/rounds/droundstart.wav");
			dogWave = true;
		} else {
			playSoundAtPlayers("sounds/rounds/nround.wav");
		}
		rounds_change = 6;
		SetUpdate(self, UT_ROUNDS_CHANGE, rounds_change, 0, 0);
		blink_return = time + 2;
	}

	// if we just had a dog round, set the next
	if (gotdog && rounds == dogRound) {
		updateDogRound();
	}

	rounds = rounds + 1;

	NotifyNewRound(rounds);
	tempe = find(world, classname, "player");
	while (tempe)
	{
		if(tempe.grenades & 1)
		{
			tempe.primary_grenades = tempe.primary_grenades + 2;
			if (tempe.primary_grenades > 4)
				tempe.primary_grenades = 4;
		}
		tempe = find(tempe, classname, "player");
	}

	set_z_health();
	
	maxreward = 50 * rounds;
	if (maxreward > 500)
		maxreward = 500;

	totalreward = 0;
	Current_Zombies = 0;
	spawn_delay = 0;
	totalpowerups = 0;
	powerup_activate = powerup_activate*1.14;
	
	if (rounds == dogRound && gotdog) {
		roundtype = 2;
		localcmd("fog 0.25\n"); 
	} else {
		roundtype = 1;
		
		if (world.fog) {
			#ifdef PSP
			localcmd(strcat("fog ", world.fog));
			#else
			#ifdef PC
			localcmd(strcat("fog ", world_fog));
			#endif
			#endif
		}
	}

	Remaining_Zombies = Total_Zombies = getZombieTotal();
	#ifndef NX
	#ifdef PSP
	local entity e = find(world, classname, "player");
	switch(rounds) {
		case 5: achievement(e, 0); break;
		case 10: achievement(e, 1); break;
		case 15: achievement(e, 2); break;
	}
	#else
	switch(rounds) {
		case 5: GiveAchievement(0, pl1); break;
		case 10: GiveAchievement(1, pl1); break;
		case 15: GiveAchievement(2, pl1); break;
	}
	#endif
	#endif

	// Set up delay for zombie spawning
	local float spawndelay;

	spawndelay = zombie_spawn_delay;

	if (spawndelay > 0.08) {
		zombie_spawn_delay *= 0.95;
	} else {
		zombie_spawn_delay = 0.08;
	}

	// 2 seconds by default
	if (rounds == 1)
		zombie_spawn_delay = 2;

	// Actually start the timer
	zombie_spawn_timer = 2 + time;
}
void() Round_Core =
{
	if (game_over)
		return;
	
	if (round_changetime <= (time + 2) && !rounds && round_changetime) {
		rounds_change = 2;
	}

	if (round_changetime <= (time + 2) && rounds && round_changetime) {
		rounds_change = 5;
	}

	if (blink_return && blink_return < time && rounds_change == 6)
	{
		blink_return = time + 3;
		rounds_change = 7;
	}
	if (blink_return && blink_return < time && rounds_change == 7)
	{
		blink_return = 0;
		rounds_change = 0;
	}
	if (round_changetime >= time)
		return;
	if (round_changetime)
	{
		roundtype = 1;
			
		NewRound();
		return;
	}
	if (Total_Zombies > Current_Zombies && spawn_time < time)
	{
		Spawn_Enemy();
	}
	if (Remaining_Zombies < 1 && !Delay_Time)
	{
		Delay_Time = time + 2;
		rounds_change = 3;
	}
	else if (Delay_Time && Delay_Time < time)
	{
		Delay_Time = 0;
		EndRound();
	}
	
	SetUpdate(self, UT_ROUNDS_CHANGE, rounds_change, 0, 0);
}

void() InitRounds =
{		
	roundtype = 1;
	delay_at_round = 2/0.95;
	totalpowerups = 0;
	powerup_activate = 2000/1.14;
	spawnAllZombEnts();
	round_changetime = time + 3.5;
	rounds_change = 1;
	roundinit = 1;
	SetUpdate(self, UT_ROUNDS_CHANGE, rounds_change, 0, 0);
}