
//float current_special;
entity active_way, current_way;


float (entity way1, entity way2) progs_Link_Waypoints =
{
	
	if (way1 == world)
		return 0;
	if (way2 == world)
		return 0;
	if (way2 == way1)
		return 0;
	
	if(
		way1.target == way2.waynum ||
		way1.target2 == way2.waynum ||
		way1.target3 == way2.waynum ||
		way1.target4 == way2.waynum ||
		way1.target5 == way2.waynum ||
		way1.target6 == way2.waynum ||
		way1.target7 == way2.waynum ||
		way1.target8 == way2.waynum
		)
	{
		//bprint(PRINT_HIGH, "These waypoints are already linked!\n");
		return 2;//already linked
	}
	
	if (way1.target == "")
	{
		way1.target = way2.waynum;
		way1.target = strzone(way1.target);
	}
	else if (way1.target2 == "")
	{
		way1.target2 = way2.waynum;
		way1.target2 = strzone(way1.target2);
	}
	else if (way1.target3 == "")
	{
		way1.target3 = way2.waynum;
		way1.target3 = strzone(way1.target3);
	}
	else if (way1.target4 == "")
	{
		way1.target4 = way2.waynum;
		way1.target4 = strzone(way1.target4);
	}
	else if (way1.target5 == "")
	{
		way1.target5 = way2.waynum;
		way1.target5 = strzone(way1.target5);
	}
	else if (way1.target6 == "")
	{
		way1.target6 = way2.waynum;
		way1.target6 = strzone(way1.target6);
	}
	else if (way1.target7 == "")
	{
		way1.target7 = way2.waynum;
		way1.target7 = strzone(way1.target7);
	}
	else if (way1.target8 == "")
	{
		way1.target8 = way2.waynum;
		way1.target8 = strzone(way1.target8);
	}
	else
	{
		//bprint(PRINT_HIGH, "no targets remaining!\n");
		return -1;//no targets
	}
	
	return 1;
}

//alter auto_link_waypoints to iterate through the closest waypoints from closest to furthest
// on the innermost loop, we find the next closest waypoint that is further away from the last closest waypoint, and we use that!

void() Auto_Link_Waypoints =
{
	entity tempe1, tempe2;
	
	tempe1 = find(world,classname,"waypoint");
	while(tempe1 != world)
	{
		tempe2 = find(world,classname,"waypoint");
		while(tempe2 != world)
		{
			if(tempe1 == tempe2)
			{
				tempe2 = find(tempe2,classname,"waypoint");
				continue;
			}
			
			if(tracemove(tempe1.origin,VEC_HULL_MIN,VEC_HULL_MAX,tempe2.origin,TRUE,self))
			{
				progs_Link_Waypoints(tempe1,tempe2);
			}
			
			tempe2 = find(tempe2,classname,"waypoint");
		}
		tempe1 = find(tempe1,classname,"waypoint");
	}
}

void() Remove_Waypoint =
{
	entity tempe;
	if (!active_way)
		return;
		
	tempe = find (world, classname, "waypoint");
	while (tempe)
	{
		if (tempe.targetname != "")
			setmodel(tempe, "models/way/normal_way_door.spr");
		else
			setmodel(tempe, "models/way/normal_way.spr"); //restore the original one, shall we
		tempe = find (tempe, classname, "waypoint");
	}

	tempe = find (world, target, active_way.waynum);
	if (tempe)
		tempe.target = "";
	tempe = find (world, target2, active_way.waynum);
	if (tempe)
		tempe.target2 = "";
	tempe = find (world, target3, active_way.waynum);
	if (tempe)
		tempe.target3 = "";
	tempe = find (world, target4, active_way.waynum);
	if (tempe)
		tempe.target4 = "";
	tempe = find (world, target5, active_way.waynum);
	if (tempe)
		tempe.target5 = "";
	tempe = find (world, target6, active_way.waynum);
	if (tempe)
		tempe.target6 = "";
	tempe = find (world, target7, active_way.waynum);
	if (tempe)
		tempe.target7 = "";
	tempe = find (world, target8, active_way.waynum);
	if (tempe)
		tempe.target8 = "";


	//if (active_way.targetname != "")
	//	current_special--;
		
	bprint (PRINT_HIGH, "Removed waypoint ");
	bprint (PRINT_HIGH, active_way.waynum);
	bprint (PRINT_HIGH, "\n");

	strunzone (active_way.classname);
	strunzone (active_way.targetname);
	strunzone (active_way.waynum);
	strunzone (active_way.target);
	strunzone (active_way.target2);
	strunzone (active_way.target3);
	strunzone (active_way.target4);
	strunzone (active_way.target5);
	strunzone (active_way.target6);
	strunzone (active_way.target7);
	strunzone (active_way.target8);
	remove (active_way);
}

void() creator_way_touch =
{
	if (cvar("waypoint_mode"))
	{
		if (other.classname != "player")
			return;

		current_way = self;
	}
}

void () Create_New_Waypoint =
{
	float way_count;
	float tempf;
	entity tempe;
	entity new_way;
	string temps;
	new_way = spawn();

	setorigin(new_way, self.origin);
	
	
	//new_way.flags = FL_ITEM;
	new_way.solid = SOLID_TRIGGER;

	
	setmodel(new_way, "models/way/normal_way.spr");
	new_way.classname = "waypoint";

	tempe = find (world, classname, "waypoint");
	while (tempe)
	{
		tempf = stof (tempe.waynum);
		if (tempf > way_count)
			way_count = tempf;
		tempe = find (tempe, classname, "waypoint");
	}
	
	temps = ftos(way_count + 1);
	new_way.waynum = temps;
	new_way.waynum = strzone(new_way.waynum);
	new_way.targetname = strzone(new_way.targetname);
	bprint (PRINT_HIGH, "Created waypoint  ");
	bprint (PRINT_HIGH, new_way.waynum);
	bprint (PRINT_HIGH, "\n");

	new_way.touch = creator_way_touch;
}
void () Move_Waypoint =
{
	if (!active_way)
		return;

	setorigin (active_way, self.origin);
	bprint(PRINT_HIGH, "Moved waypoint ");
	bprint(PRINT_HIGH, active_way.waynum);
	bprint(PRINT_HIGH, "\n");
	
}

void() Dual_Link_Waypoints =
{
	if (self.classname != "player")
		return;
	if (!current_way)
		return;
	if (!active_way)
		return;
	if (current_way == active_way)
		return;
	
	local float result1,result2;
	result1 = progs_Link_Waypoints(current_way,active_way);
	result2 = progs_Link_Waypoints(active_way,current_way);
	
	if(result1 == 2 && result2 == 2)
	{
		bprint(PRINT_HIGH, "Both waypoints already linked!\n");
	}
	
	if(result1 == 1)
	{
		bprint(PRINT_HIGH, "	Linked waypoint ");
		bprint(PRINT_HIGH, current_way.waynum);
		bprint(PRINT_HIGH, " to ");
		bprint(PRINT_HIGH, active_way.waynum);
		bprint(PRINT_HIGH, "\n");
	}
	if(result2 == 1)
	{
		bprint(PRINT_HIGH, "	Linked waypoint ");
		bprint(PRINT_HIGH, active_way.waynum);
		bprint(PRINT_HIGH, " to ");
		bprint(PRINT_HIGH, current_way.waynum);
		bprint(PRINT_HIGH, "\n");
	}
	
	if(result1 == 2 && result2 != 2)//if both are already linked, we only want the simple message above, not detailed one
	{
		bprint(PRINT_HIGH, "	Waypoint ");
		bprint(PRINT_HIGH, current_way.waynum);
		bprint(PRINT_HIGH, " already linked to ");
		bprint(PRINT_HIGH, active_way.waynum);
		bprint(PRINT_HIGH, "\n");
	}
	if(result2 == 2 && result1 != 2)//if both are already linked, we only want the simple message above, not detailed one
	{
		bprint(PRINT_HIGH, "	Waypoint ");
		bprint(PRINT_HIGH, active_way.waynum);
		bprint(PRINT_HIGH, " already linked to ");
		bprint(PRINT_HIGH, current_way.waynum);
		bprint(PRINT_HIGH, "\n");
	}
	if(result1 == -1)
	{
		bprint(PRINT_HIGH, "	Waypoint ");
		bprint(PRINT_HIGH, current_way.waynum);
		bprint(PRINT_HIGH, " has no open targets remaining\n");
	}
	if(result2 == -1)
	{
		bprint(PRINT_HIGH, "	Waypoint ");
		bprint(PRINT_HIGH, active_way.waynum);
		bprint(PRINT_HIGH, " has no open targets remaining!\n");
	}
	if(result1 == 1 && result2 == 1)
	{
		bprint(PRINT_HIGH, "Both waypoints linked succesfully!\n");
	}
	
	if (current_way.targetname != "")
		setmodel(current_way, "models/way/last_way_door.spr");
	else
		setmodel(current_way, "models/way/last_way.spr");
	
	if (active_way.targetname != "")
		setmodel(active_way, "models/way/current_way_door.spr");
	else
		setmodel(active_way, "models/way/current_way.spr");
}

void () Link_Waypoints =
{
	if (self.classname != "player")
		return;
	if (!current_way)
		return;
	if (!active_way)
		return;
	if (current_way == active_way)
		return;
	
	if(
		active_way.target == current_way.waynum ||
		active_way.target2 == current_way.waynum ||
		active_way.target3 == current_way.waynum ||
		active_way.target4 == current_way.waynum ||
		active_way.target5 == current_way.waynum ||
		active_way.target6 == current_way.waynum ||
		active_way.target7 == current_way.waynum ||
		active_way.target8 == current_way.waynum
		)
	{
		bprint(PRINT_HIGH, "These waypoints are already linked!\n");
		return;
	}
	
	if (active_way.target == "")
	{
		active_way.target = current_way.waynum;
		active_way.target = strzone(active_way.target);
	}
	else if (active_way.target2 == "")
	{
		active_way.target2 = current_way.waynum;
		active_way.target2 = strzone(active_way.target2);
	}
	else if (active_way.target3 == "")
	{
		active_way.target3 = current_way.waynum;
		active_way.target3 = strzone(active_way.target3);
	}
	else if (active_way.target4 == "")
	{
		active_way.target4 = current_way.waynum;
		active_way.target4 = strzone(active_way.target4);
	}
	else if (active_way.target5 == "")
	{
		active_way.target5 = current_way.waynum;
		active_way.target5 = strzone(active_way.target5);
	}
	else if (active_way.target6 == "")
	{
		active_way.target6 = current_way.waynum;
		active_way.target6 = strzone(active_way.target6);
	}
	else if (active_way.target7 == "")
	{
		active_way.target7 = current_way.waynum;
		active_way.target7 = strzone(active_way.target7);
	}
	else if (active_way.target8)
	{
		active_way.target8 = current_way.waynum;
		active_way.target8 = strzone(active_way.target8);
	}
	else
	{
		bprint(PRINT_HIGH, "no targets remaining!\n");
		return;
	}
			
	bprint(PRINT_HIGH, "Linked waypoint ");
	bprint (PRINT_HIGH, current_way.waynum);
	bprint(PRINT_HIGH, " to ");
	bprint (PRINT_HIGH, active_way.waynum);
	bprint(PRINT_HIGH, "\n");
	if (current_way.targetname != "")
		setmodel(current_way, "models/way/last_way_door.spr");
	else
		setmodel(current_way, "models/way/last_way.spr");
}
void () Select_Waypoint =
{
	if (self.classname != "player")
		return;
	if (!current_way)
		return;

	entity tempe;

	if (current_way == active_way)
		active_way = world;
	else
		active_way = current_way;

	tempe = find (world, classname, "waypoint");
	while (tempe)
	{
		if (tempe.targetname != "")
			setmodel(tempe, "models/way/normal_way_door.spr");
		else
			setmodel(tempe, "models/way/normal_way.spr");
		tempe = find (tempe, classname, "waypoint");
	}
	if (active_way)
	{
		if (active_way.targetname != "")
			setmodel(active_way, "models/way/current_way_door.spr");
		else
			setmodel(active_way, "models/way/current_way.spr");
		
		bprint(PRINT_HIGH, "Selected waypoint ");
		bprint(PRINT_HIGH, active_way.waynum);
		if(active_way.targetname != "")
		{
			bprint(PRINT_HIGH, ", special tag ");
			bprint(PRINT_HIGH, active_way.targetname);
		}
		bprint(PRINT_HIGH, "\n");
		
		if(active_way.target != "")
		{
			tempe = find (world, waynum, active_way.target);
			if (tempe)
			{
				if (tempe.targetname != "")
					setmodel(tempe, "models/way/last_way_door.spr");
				else
					setmodel(tempe, "models/way/last_way.spr");
				bprint(PRINT_HIGH, active_way.target);
				bprint(PRINT_HIGH, "\n");
			}
			else
			{
				active_way.target = "";
			}
		}
		if(active_way.target2 != "")
		{
			tempe = find (world, waynum, active_way.target2);
			if (tempe)
			{
				if (tempe.targetname != "")
					setmodel(tempe, "models/way/last_way_door.spr");
				else
					setmodel(tempe, "models/way/last_way.spr");
				bprint(PRINT_HIGH, active_way.target2);
				bprint(PRINT_HIGH, "\n");
			}
			else
			{
				active_way.target2 = "";
			}
		}
		if(active_way.target3 != "")
		{
			tempe = find (world, waynum, active_way.target3);
			if (tempe)
			{
				if (tempe.targetname != "")
					setmodel(tempe, "models/way/last_way_door.spr");
				else
					setmodel(tempe, "models/way/last_way.spr");
				bprint(PRINT_HIGH, tempe.target3);
				bprint(PRINT_HIGH, "\n");
			}
			else
			{
				active_way.target3 = "";
			}
		}
		if(active_way.target4 != "")
		{
			tempe = find (world, waynum, active_way.target4);
			if (tempe)
			{
				if (tempe.targetname != "")
					setmodel(tempe, "models/way/last_way_door.spr");
				else
					setmodel(tempe, "models/way/last_way.spr");
				bprint(PRINT_HIGH, active_way.target4);
				bprint(PRINT_HIGH, "\n");
			}
			else
			{
				active_way.target4 = "";
			}
		}
		if(active_way.target5 != "")
		{
			tempe = find (world, waynum, active_way.target5);
			if (tempe)
			{
				if (tempe.targetname != "")
					setmodel(tempe, "models/way/last_way_door.spr");
				else
					setmodel(tempe, "models/way/last_way.spr");
				bprint(PRINT_HIGH, active_way.target5);
				bprint(PRINT_HIGH, "\n");
			}
			else
			{
				active_way.target5 = "";
			}
		}
		if(active_way.target6 != "")
		{
			tempe = find (world, waynum, active_way.target6);
			if (tempe)
			{
				if (tempe.targetname != "")
					setmodel(tempe, "models/way/last_way_door.spr");
				else
					setmodel(tempe, "models/way/last_way.spr");
				bprint(PRINT_HIGH, "\n");
			}
			else
			{
				active_way.target6 = "";
			}
		}
		if(active_way.target7 != "")
		{
			tempe = find (world, waynum, active_way.target7);
			if (tempe)
			{
				if (tempe.targetname != "")
					setmodel(tempe, "models/way/last_way_door.spr");
				else
					setmodel(tempe, "models/way/last_way.spr");
				bprint(PRINT_HIGH, active_way.target7);
				bprint(PRINT_HIGH, "\n");
			}
			else
			{
				active_way.target7 = "";
			}
		}
		if(active_way.target8 != "")
		{
			tempe = find (world, waynum, active_way.target8);
			if (tempe)
			{
				if (tempe.targetname != "")
					setmodel(tempe, "models/way/last_way_door.spr");
				else
					setmodel(tempe, "models/way/last_way.spr");
				bprint(PRINT_HIGH, active_way.target8);
				bprint(PRINT_HIGH, "\n");
			}
			else
			{
				active_way.target8 = "";
			}
		}
	}
}
entity() closestDoor =
{
	local float bestdist,dist;
	bestdist = 10000;
	dist = 0;
	local entity d,best;
	d = find(world,classname,"door_nzp");
	while(d)
	{
		bprint(PRINT_HIGH, "Door! ");
		dist = vlen(self.origin - d.pos1);//door origin is world, so use pos1 for start pos
		bprint(PRINT_HIGH, ftos(bestdist));
		bprint(PRINT_HIGH, ", ");
		bprint(PRINT_HIGH, ftos(dist));
		bprint(PRINT_HIGH, "\n");
		if(dist < bestdist)
		{
			bestdist = dist;
			best = d;
		}
		bprint(PRINT_HIGH, "\n");
		d = find(d,classname,"door_nzp");
	}
	return best;
}
void () Make_Special_Waypoint =
{
	if (self.classname != "player")
		return;
	if (!active_way)
		return;
	if (active_way.targetname != "")//Toggling it back off
	{
		setmodel(active_way, "models/way/current_way.spr");
		active_way.targetname = "";
		bprint(PRINT_HIGH, "Waypoint ");
		bprint(PRINT_HIGH, active_way.waynum);
		bprint(PRINT_HIGH, " is no longer a special waypoint\n");
		return;
	}
	if (active_way)
	{
		strunzone(active_way.targetname);
		//local entity nearDoor;
		//nearDoor = closestDoor();
		if(self.active_door == world)
		{
			bprint(PRINT_HIGH, "Error: no door selected!\n");
			return;
		}
		if(self.active_door.wayTarget == "")
		{
			bprint(PRINT_HIGH, "Error: Door has no wayTarget value!\n");
			return;
		}
		setmodel(active_way, "models/way/current_way_door.spr");
		active_way.targetname = self.active_door.wayTarget;
		//active_way.targetname = ftos(current_special);
		//active_way.targetname = strzone(active_way.targetname);
		//active_way.targetname = strcat("d", active_way.targetname);
		//active_way.targetname = strzone(active_way.targetname);
		bprint(PRINT_HIGH, "special waypoint ");
		bprint (PRINT_HIGH, active_way.waynum);
		bprint(PRINT_HIGH, " named ");
		bprint (PRINT_HIGH, active_way.targetname);
		bprint(PRINT_HIGH, "\n");
		//current_special++;
	}
}

void (vector here, float which, string special, string trg, string trg2, string trg3, string trg4, string trg5, string trg6, string trg7, string trg8) Create_Waypoint =
{
	entity new_way;
	new_way = spawn();

	setorigin(new_way, here);
	
	
	//new_way.flags = FL_ITEM;
	new_way.solid = SOLID_TRIGGER;

	if (cvar("waypoint_mode"))
		setmodel(new_way, "models/way/normal_way.spr");
	new_way.classname = "waypoint";
	new_way.classname = strzone(new_way.classname);

	new_way.waynum = ftos(which);
	new_way.waynum = strzone(new_way.waynum);
	dprint ("Created waypoint  ");
	dprint (new_way.waynum);
	dprint ("\n");
	
	if (special != "")
	{
		if (!cvar("waypoint_mode"))
			new_way.classname = "waypoint_s";
		if (cvar("waypoint_mode"))
			setmodel(new_way, "models/way/normal_way_door.spr");
		new_way.targetname = special;
		new_way.targetname = strzone(new_way.targetname);
		dprint ("Special waypoint  ");
		dprint (new_way.targetname);
		dprint ("\n");
		//current_special++;
	}
	if (trg)
	{
		new_way.target = trg;
		new_way.target = strzone(new_way.target);
		dprint ("Waypoint target  ");
		dprint (new_way.target);
		dprint ("\n");
	}
	if (trg2)
	{
		new_way.target2 = trg2;
		new_way.target2 = strzone(new_way.target2);
		dprint ("Waypoint target2  ");
		dprint (new_way.target2);
		dprint ("\n");
	}
	if (trg3)
	{
		new_way.target3 = trg3;
		new_way.target3 = strzone(new_way.target3);
		dprint ("Waypoint target3  ");
		dprint (new_way.target3);
		dprint ("\n");
	}
	if (trg4)
	{
		new_way.target4 = trg4;
		new_way.target4 = strzone(new_way.target4);
		dprint ("Waypoint target4  ");
		dprint (new_way.target4);
		dprint ("\n");
	}
	if (trg5)
	{
		new_way.target5 = trg5;
		new_way.target5 = strzone(new_way.target5);
		dprint ("Waypoint target5  ");
		dprint (new_way.target5);
		dprint ("\n");
	}
	if (trg6)
	{
		new_way.target6 = trg6;
		new_way.target6 = strzone(new_way.target6);
		dprint ("Waypoint target6  ");
		dprint (new_way.target6);
		dprint ("\n");
	}
	if (trg7)
	{
		new_way.target7 = trg7;
		new_way.target7 = strzone(new_way.target7);
		dprint ("Waypoint target7  ");
		dprint (new_way.target7);
		dprint ("\n");
	}
	if (trg8)
	{
		new_way.target8 = trg8;
		new_way.target8 = strzone(new_way.target8);
		dprint ("Waypoint target8  ");
		dprint (new_way.target8);
		dprint ("\n");
	}
	
	new_way.touch = creator_way_touch;
}

string tempstest;
void() Save_Waypoints
{
	local float file;
	string h;

	h = strcat(mappath, ".way");
	file = fopen (h, FILE_WRITE);
	
	local entity dway;
	//fputs(file, "begin\n");
	dway = find(world, classname, "waypoint");
	while (dway)
	{
		dprint ("Saving waypoints\n");
		fputs(file,"Waypoint\n");
		fputs(file,"{\norigin = ");
		tempstest = vtos(dway.origin);
		tempstest = strzone(tempstest);
		fputs(file,tempstest);
		strunzone (tempstest);
		fputs(file,"\nid = ");
		fputs(file,dway.waynum);
		fputs(file,"\nspecial = ");
		fputs(file,dway.targetname);
		fputs(file,"\ntarget = ");
		fputs(file,dway.target);
		fputs(file,"\ntarget2 = ");
		fputs(file,dway.target2);
		fputs(file,"\ntarget3 = ");
		fputs(file,dway.target3);
		fputs(file,"\ntarget4 = ");
		fputs(file,dway.target4);
		fputs(file,"\ntarget5 = ");
		fputs(file,dway.target5);
		fputs(file,"\ntarget6 = ");
		fputs(file,dway.target6);
		fputs(file,"\ntarget7 = ");
		fputs(file,dway.target7);
		fputs(file,"\ntarget8 = ");
		fputs(file,dway.target8);
		fputs(file,"\n");
		fputs(file,"}\n");
		
		
		dway = find(dway, classname, "waypoint");
		if (dway)
			fputs(file,"\n");
	}
	fclose(file);
}
void() Load_Waypoints
{
	float file, which;
	string h, special, trg, trg2, trg3, trg4, trg5, trg6, trg7, trg8;
	local vector where;

	h = strcat(mappath, ".way");
	file = fopen (h, FILE_READ);

	if (file == -1)
	{
		dprint("Error: file not found \n");
		return;
	}

	while (1)
	{
		dprint("Loading waypoint\n");
		// the first line is just a comment, ignore it
		h = fgets(file);	
		if (h != "Waypoint")
		{
			bprint(PRINT_HIGH, "Last waypoint\n");
			fclose(file);
			return;
		}
		h = fgets(file);
		h = fgets(file);
		h = substring(h, 9, 20);
		where = stov(h);
		
		h = (fgets(file));
		h = substring(h, 5, 20);
		which = stof(h);
	
		h = (fgets(file));
		special = substring(h, 10, 20);
		special = strzone(special);
	
		h = (fgets(file));
		trg = substring(h, 9, 20);
		trg = strzone(trg);

		h = (fgets(file));
		trg2 = substring(h, 10, 20);
		trg2 = strzone(trg2);

		h = (fgets(file));
		trg3 = substring(h, 10, 20);
		trg3 = strzone(trg3);

		h = (fgets(file));
		trg4 = substring(h, 10, 20);
		trg4 = strzone(trg4);

		h = (fgets(file));
		trg5 = substring(h, 10, 20);
		trg5 = strzone(trg5);

		h = (fgets(file));
		trg6 = substring(h, 10, 20);
		trg6 = strzone(trg6);

		h = (fgets(file));
		trg7 = substring(h, 10, 20);
		trg7 = strzone(trg7);

		h = (fgets(file));
		trg8 = substring(h, 10, 20);
		trg8 = strzone(trg8);
		
		Create_Waypoint(where, which, special, trg, trg2, trg3, trg4, trg5, trg6, trg7, trg8);

		strunzone (trg);
		strunzone (trg2);
		strunzone (trg3);
		strunzone (trg4);
		strunzone (trg5);
		strunzone (trg6);
		strunzone (trg7);
		strunzone (trg8);
		h = (fgets(file));
		h = (fgets(file));
	}
}