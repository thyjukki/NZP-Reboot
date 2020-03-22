void() Load_Waypoints_Legacy;

float Distance (vector from, vector to) {
	return vlen(from - to);
}

float HeuristicCostEstimate (float start_way, float end_way)
{
	//for now we will just look the distance between.
	return Distance(waypoints[start_way].org, waypoints[end_way].org);
}

void ReconstructPath(entity z, float start_way, float end_way) {

}

float open_first;
float open;
float closed_init;
float closed;
float closed_first;
void SV_WP_ClearSet()
{
	float i;

	for (i = 0; i < MAX_WAYPOINTS; i = i + 1)
	{
		waypoints[i].set = 0;
	}
}

float IsActive(float way) {
	if (waypoints[way].targetdoor != "") {
		entity door;

		door = find(world, wayTarget, waypoints[way].targetdoor);

		if (door != world) {
			if (door.state == STATE_BOTTOM) {
				return 0;
			}
		}
	}

	return 1;
}

void SV_WP_SetAdd(float wp, float isopen)
{
	if (isopen)
	{
		// we only get added here from none, so no cleanup required
		// gotta check if last entry was removed before this call
		if (waypoints[open_first].set == SET_CLOSED)
		{
			//Con_Printf("Empty set: %i is new first\n", wp);
			open_first = wp;
			waypoints[wp].prev = wp;
		}
		else
		{
			waypoints[wp].prev = open;
			waypoints[open].next = wp;
		}
		waypoints[wp].next = wp;
		waypoints[wp].set = SET_OPEN;
		open = wp;
	}
	else
	{
		// even if wp is the only one in the set, it doesn't really matter
		if (wp == open_first)
			open_first = waypoints[wp].next;
		if (wp == open)
			open = waypoints[wp].prev;

		// update links so open set doesn't get fucked
		waypoints[waypoints[wp].prev].next = waypoints[wp].next;
		waypoints[waypoints[wp].next].prev = waypoints[wp].prev;

		if (!closed_init)
		{
			closed_first = wp;
			waypoints[wp].prev = wp;
			closed_init = true;
		}
		else
		{
			waypoints[closed].next = wp;
			waypoints[wp].prev = closed;
		}
		waypoints[wp].next = wp;
		waypoints[wp].set = SET_CLOSED;
		closed = wp;
	}
}

float Pathfind (entity z, float s_wp, float e_wp) {
	float current;
	float i, j;
	float bestf;


	if (s_wp == e_wp) {
		return 2;
	}

	SV_WP_ClearSet();

	open_first = s_wp;
	open = s_wp;
	waypoints[s_wp].next = s_wp;
	waypoints[s_wp].prev = s_wp;
	waypoints[s_wp].set = SET_OPEN;
	waypoints[s_wp].g = 0;
	waypoints[s_wp].f = HeuristicCostEstimate(s_wp, e_wp);
	waypoints[s_wp].step = s_wp;
	current = s_wp;

	closed_init = false;

	// while openset is not empty
	while (waypoints[open_first].set == SET_OPEN) {
		i = open_first;

		bestf = 320000;
		//print("Current ", ftos(current), "\n");

		// go from first open to last, pick the one with lowest f
		do {
			if (waypoints[i].f < bestf) {
				current = i;
				bestf = waypoints[i].f;
			}
			i = waypoints[i].next;
		} while (i != open);

		// mark node as visited
		//print("Removing ", ftos(current), " from open\n");
		SV_WP_SetAdd(current, false);

		// we found a result, loop back with pathlength
		if (current == e_wp) {
			j = i = current;
			// walk constructed path backwards
			// keep 2 next steps with us
			//print("Result\n");
			//print(ftos(current), "\n");
			while (waypoints[current].step != current)
			{
				j = i;
				i = current;
				current = waypoints[current].step;
			}

			// go to the furthest one on the path that we can actually see
			
			if (tracemove(waypoints[s_wp].org,VEC_HULL_MIN,VEC_HULL_MAX,waypoints[i].org,TRUE,z))
			{
				//VectorCopy(waypoints[i].origin, res);
				//print("Giving third wp ", ftos(i), "\n");
				return i;
			}
			else if (tracemove(waypoints[s_wp].org,VEC_HULL_MIN,VEC_HULL_MAX,waypoints[j].org,TRUE,z))
			{
				//VectorCopy(waypoints[j].origin, res);
				//print("Giving second wp ", ftos(j), "\n");
				return j;
			}
			else
			{
				//VectorCopy(waypoints[current].origin, res);
				//print("Giving first wp ", ftos(current), "\n");
				return current;
			}
		}


		// check neighbours to add to openset
		for (j = 0; j < MAX_WAY_TARGETS; j++)
		{
			i = waypoints[current].target_id[j];
			if (waypoints[i].set != SET_CLOSED && i != current && IsActive(i))
			{
				bestf = waypoints[current].g + HeuristicCostEstimate(i, current);
				if (waypoints[i].set == SET_NONE || bestf < waypoints[i].g)
				{
					waypoints[i].step = current;
					waypoints[i].g = bestf;
					waypoints[i].f = bestf + HeuristicCostEstimate(i, e_wp);

					if (waypoints[i].set == SET_NONE)
					{
						//print("Adding ", ftos(i), " into open\n");
						SV_WP_SetAdd(i, true);
					}
				}
			}
		}
	}
	print("Waypointing failed\n");
	return -1;
}


float Do_Pathfind(entity from, entity to) {

	float i;
	float TraceResult;

	float dist, best_dist, best, best_target;

	dist = 0;
	best_dist = 100000000;

	#ifndef PSP
	for (i = 0; i < MAX_WAYPOINTS; i = i + 1) {
		if (IsActive(i)) {
			TraceResult = tracemove (from.origin, VEC_HULL_MIN, VEC_HULL_MAX, waypoints[i].org, TRUE ,from);
			if (TraceResult) {
				dist = Distance(waypoints[i].org, from.origin);

				if(dist < best_dist) {
					best_dist = dist;
					best = i;
				}
			}
		}
	}
	dist = 0;
	best_dist = 100000000;

	for (i = 0; i < MAX_WAYPOINTS; i = i + 1) {
		if (IsActive(i)) {
			TraceResult = tracemove (to.origin, VEC_HULL_MIN, VEC_HULL_MAX, waypoints[i].org, TRUE ,to);
			if (TraceResult) {
				dist = Distance(waypoints[i].org, to.origin);

				if(dist < best_dist) {
					best_dist = dist;
					best_target = i;
				}
			}
		}
	}

	//print("Starting waypoint: ", ftos(best)," Ending waypoint: ", ftos(best_target), "\n");




	return Pathfind(from, best, best_target);
	#else 
	return 0;
	#endif
}

void CalcDistances() {
	float i, s;

	for (i = 1; i < MAX_WAYPOINTS; i++) {
		waypoint_ai way;
		way = waypoints[i];
		if (way.id > 0) {
			for (s = 0; s < MAX_WAY_TARGETS; s++) {
				float targ;
				targ = way.target_id[s];
				if (targ > 0) {
					way.dist[s] = Distance(way.org, waypoints[targ].org);
				}
			}
		}
	}
}
			

void creator_way_touch();
void LoadWaypointData() { 
    float file, point;
	string h;
	float targetcount, loop, waycount;
	entity new_way;

	h = strcat(mappath, ".way");
	file = fopen (h, FILE_READ);

	if (file == -1)
	{
		dprint("Error: file not found \n");
		return;
	}

    float i, s;
	

	#ifndef PSP 
    for (i = 0; i < MAX_WAYPOINTS; i = i + 1) {
		waypoint_ai way; 
		
		way = waypoints[i];
        way.org = '0 0 0';
        way.id = 0;
        way.g = 0;
        way.f = 0;
		way.set = 0;
        way.targetdoor = "";

        for (s = 0; s < MAX_WAY_TARGETS; s = s + 1) {
            way.target_id[s] = 0;
            way.dist[s] = 0;
        }
		
    }
	#endif

	new_way = spawn();
	point = 0;
	waycount = 0;
	targetcount = 0;
	loop = 1;
	while (loop)
	{
		string line;
		line = fgets(file);
		if not (line) {
			//bprint(PRINT_HIGH, "End of file\n");
			loop = 0;
			break;
		}
		h = strtrim(line);

		//print(h, "\n");
		if (h == "") {
			continue;
		}

		switch (point) {
			case 0:
				if (h == "waypoint") {
					new_way = spawn();
					new_way.solid = SOLID_TRIGGER;

					setmodel(new_way, "models/way/normal_way.spr");
					new_way.classname = "waypoint";

					new_way.touch = creator_way_touch;
					point = 1;
					targetcount = 0;
				} else if (h == "Waypoint") {
					bprint(PRINT_HIGH, "Identified .way as legacy..\n");
					point = 99;
					Load_Waypoints_Legacy();
				} else {
					bprint(PRINT_HIGH, strcat("Error: unknown point ", strcat(h, "\n")));
				}
				break;
			case 1:
				if (h == "{") {
					point = 2;
				} else {
					bprint(PRINT_HIGH, strcat("Error: unknown variable ", strcat(h, " expected {\n")));
				}
				break;
			case 2:
				tokenize(h);

				string value, variable;
				variable = strtrim(argv(0));
				value = strtrim(argv(2));

				switch (variable) {
					case "origin":
						setorigin(new_way, stov(value));
						break;
					case "id":
						new_way.waynum = value;
						break;
					case "door":
						new_way.targetname = value;
						break;
					case "targets":
						point = 3;
						break;
					case "}":
						float id = stof(new_way.waynum);
						waypoint_ai waypoint;
						waypoint = waypoints[id];

						waypoints[id].id = id;
						waypoints[id].org = new_way.origin;
						waypoints[id].targetdoor = new_way.targetname;

						for (i = 0; i < MAX_WAY_TARGETS; i++) {
							waypoints[id].target_id[i] = stof(new_way.targets[i]);
						}

						if (!cvar("waypoint_mode")) {
							remove(new_way);
						}
						

						point = 0;
						break;
					default:
						bprint(PRINT_HIGH, strcat("Error: unknown variable ", strcat(variable, "\n")));
						break;
				}
				break;
			case 3:
				if (h == "[") {
					point = 4;
				} else {
					bprint(PRINT_HIGH, strcat("Error: unknown variable ", strcat(h, " expected [\n")));
				}
				break;
			case 4:
				if (targetcount >= MAX_WAY_TARGETS) {
					bprint(PRINT_HIGH, "Error: Target count too high for waypoint\n");
				} else if (h == "]") {
					point = 2;
				} else  {
					new_way.targets[targetcount] = h;
					targetcount++;
				}
				break;
		}
	}

	if (new_way) {
		if (!cvar("waypoint_mode")) {
			remove(new_way);
		}
	}

	fclose(file);

	#ifndef PSP
	CalcDistances();
	#endif
}