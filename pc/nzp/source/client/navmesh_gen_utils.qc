
//Returns the length of the x & y components of this vector, ignoring the z-component
float xy_vlen(vector v)
{
	return vlen([v.x,v.y,0]);
}


// Sets trace_endpos to the position of a bbox dropped to the floor from position 'pos'
//Assumes that the position given is very close to the floor, but might be too low or might be a bit too high
//(this is used for getting the player position, because player position from engine appears to be ofset by some tiny amount)
//Assigns trace_endpos as the position on the floor
void navgen_drop_to_floor(vector pos)
{
	float max_step_height = 18;

	float iters = 0;

	float height = max_step_height;

	trace_startsolid = 1;

	while(trace_startsolid || trace_allsolid)
	{
		if(iters++ > 9998)
		{
			print("Warning: navgen drop to floor iters exceeded 9998\n");
			trace_endpos = pos;
			return;
		}

		//If this is true, we are underneath a very low hanging ceiling (practically touching top of bbox), there is something wrong with this.
		if(height < 0.01)
		{
			trace_endpos = pos;
			return;
		}

		//Try tracebox from +height to -max_step_height

		tracebox(pos + [0,0,height], VEC_HULL_MIN, VEC_HULL_MAX, pos - [0,0,max_step_height],MOVE_NOMONSTERS,self);

		if(trace_fraction > 0)
		{
			//trace_endpos is already the result
			return;
		}

		height = height * 0.5;
	}
}

// Fake entity used for ai_step() and navgen_tracemove()
struct navgen_dummy_entity
{
	vector origin;
	vector velocity;
	vector goal;
	int on_ground;
};


// Steps dummy_ent 'ent' from ent->origin towards ent->goal
// Returns 1 if ent moved some amount, 0 if it couldn't move at all.
int(navgen_dummy_entity *ent) ai_step = 
{
	float static_frametime = 0.1;
	float max_step_size = 18;//max stair step size pulled straight from engine defs
	// float max_slope = 10.4;//18/tan(60) = 10.4, the length of the triangle formed by the max walkable slope of 60 degrees, and the max step height
	float sv_gravity = cvar("sv_gravity");
	float sv_maxspeed = cvar("sv_maxspeed");

	vector goal_org;

	if(ent->on_ground == FALSE)
	{
		ent->velocity.z -= sv_gravity * static_frametime;
		ent->velocity.z = max(min(ent->velocity.z, sv_maxspeed), -sv_maxspeed);

		goal_org = ent->origin + [0, 0, ent->velocity.z] * static_frametime;

		tracebox(ent->origin,VEC_HULL_MIN,VEC_HULL_MAX,goal_org,MOVE_NOMONSTERS,self);
	
		//If falling and hit something
		if(ent->velocity.z < 0 && trace_fraction < 1)
		{
			ent->on_ground = TRUE;
			ent->velocity.z = 0;
		}
		
		ent->origin = trace_endpos;
		return 1;
	}

	// Do a cast down at our position, see if we are not on the ground
	vector step_down = [0,0,-1] * max_step_size;
	
	tracebox(ent->origin + step_down, VEC_HULL_MIN, VEC_HULL_MAX, ent->origin + 2 * step_down, MOVE_NOMONSTERS, self);

	if(!trace_allsolid && trace_fraction > 0.0)
	{
		ent->origin = trace_endpos;
		ent->on_ground = FALSE;
		return 1;
	}

	//=============================================================
	//This code is a translated version of dquake's step movetype
	//=============================================================
	goal_org = ent->origin + ent->velocity * static_frametime;
	
	// If we moved past the goal, move directly to the goal
	if(xy_vlen(goal_org - ent->origin) > xy_vlen(ent->goal - ent->origin))
	{
		goal_org.x = ent->goal.x;
		goal_org_y = ent->goal.y;
		// Don't update the z goal
	}

	// Push down from a step above goal origin to find result position
	vector above_goal = goal_org + [0,0,max_step_size];
	vector below_goal = goal_org - [0,0,max_step_size];
	tracebox(above_goal, VEC_HULL_MIN, VEC_HULL_MAX, below_goal, MOVE_NOMONSTERS, self);
	
	if(trace_allsolid)
	{
		// Try sliding along walls
		// ai_component_wise_physics_movement();
		trace_endpos = ent->origin;
		return 0;
	}
	if(trace_startsolid)
	{
		tracebox(goal_org, VEC_HULL_MIN, VEC_HULL_MAX, below_goal, MOVE_NOMONSTERS, self);
		if(trace_allsolid || trace_startsolid)
		{
			// Try sliding along walls
			// ai_component_wise_physics_movement();
			trace_endpos = ent->origin;
			return 0;
		}
	}
	if(trace_fraction >= 1)
	{
		// We walked off of a ledge
		ent->origin = goal_org;
		ent->on_ground = FALSE;
		trace_endpos = ent->origin;
		return 1;
	}

	ent->origin = trace_endpos;
	ent->on_ground = TRUE;
	ent->velocity.z = 0;
	return 1;
}

// Checks if a fake entity can walk directly from 'start' to 'end', stops if it reaches a dead end.
// Returns 1 if the walk was completed from 'start' to 'end'
// Returns 0 if the walk hit a dead-end at some point
// Sets trace_endpos to the final entity position
int(vector start, vector end) navgen_tracemove = 
{
	float max_step_size = 18;//max stair step size pulled straight from engine defs

	navgen_dummy_entity ent;
	float ent_speed = 50;

	ent.origin = start;
	ent.velocity = normalize(end - start) * ent_speed;
	ent.goal = end;
	ent.on_ground = TRUE;

	// print("-- Created ent --\n");
	// print("\torigin: ",vtos(ent.origin),"\n");
	// print("\tvelocity: ",vtos(ent.velocity),"\n");
	// print("\tgoal: ",vtos(ent.goal),"\n");
	// print("\ton_ground: ",ftos(ent.on_ground),"\n");

	int iterations = 0;
	int result = 0;

	// print("-- Tracemove start --\n");

	while(1)
	{
		if(iterations > 500)
		{
			print("Took more than ",ftos(iterations)," iterations, exiting.\n");
			break;
		}
		iterations++;

		int walked_some_amount = ai_step(&ent);

		if(iterations > 200)
		{
			float percent = 100 * xy_vlen(ent.origin - start) / xy_vlen(end - start);
			print("Movestep ",ftos(iterations), " , percent: ", ftos(percent));
			print(", pos (",vtos(ent.origin),"), goal (",vtos(ent.goal),"), vel (",vtos(ent.velocity),")\n");
		}

		if(ent.origin.x == end.x && ent.origin.y == end.y)
		{
			// If we are "close enough" on the z-axis
			if(fabs(ent.origin.z - end.z) < 2 * max_step_size)
			{
				trace_endpos = ent.origin;
				result = 1;
				break;	
			}
		}

		// If we've fallen too far from the goal, stop
		if(fabs(ent.origin.z - end.z) > 2 * max_step_size)
		{
			result = 0;
			break;	
		}


		if(!walked_some_amount)
		{
			break;
		}
	}

	return result;
}


// Checks if an entity can walk from 'start' to 'end' and 'end' to 'start'
// Returns FALSE if the entity can walk
// Returns TRUE if the entity couldn't make it to the endpoint for any reason
//          (meaning there is an obstruction somewhere along the path)
int(vector start, vector end) navgen_obstructed = 
{
	if(navgen_tracemove(end,start) == 0)
	{
		return TRUE;
	}

	if(navgen_tracemove(start,end) == 0)
	{
		return TRUE;
	}
	return FALSE;
}