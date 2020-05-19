//============================================================================================================
// Navgen v2020
//============================================================================================================

// TODO - Should implement K-D trees to speed up map rasterization
// Need to implement the following K-D tree functions:
//		insertion
//		deletion
//		search

void(vector start, vector end) navgen_tracebox
{
	tracebox(start,VEC_HULL_MIN,VEC_HULL_MAX,end,MOVE_NOMONSTERS,self);
}

struct navgen_dummy_entity
{
	vector origin;
	vector velocity;
	vector goal;
	int on_ground;
};


//Returns the length of the x & y components of this vector
float xy_vlen(vector v)
{
	return vlen([v.x,v.y,0]);
}



// Steps dummy_ent ent from ent->origin to ent->goal
// Returns 1 if ent moved some amount, 0 if it couldn't move at all.
int(navgen_dummy_entity *ent) ai_step
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


int(vector start, vector end) navgen_tracemove
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

int(vector start, vector end) navgen_obstructed
{
	if(navgen_tracemove(end,start) == 0)
	{
		return 1;
	}

	if(navgen_tracemove(start,end) == 0)
	{
		return 1;
	}
	return 0;
}

// ------------------------------------------------------------------------------------------------------
// navgen_cell struct and linked list logic
// ------------------------------------------------------------------------------------------------------
struct navgen_cell
{
	int x;
	int y;
	int z;

	// Linked list node
	navgen_cell *next;
};

navgen_cell *(int x, int y, int z) create_cell = 
{
	navgen_cell *new_cell = memalloc(sizeof(navgen_cell));
	new_cell->x = x;
	new_cell->y = y;
	new_cell->z = z;
	new_cell->next = 0;
	return new_cell;
}

void(navgen_cell *cell) delete_cell = 
{
	memfree(cell);
}

void(navgen_cell *cell, navgen_cell **list_root) add_cell_to_list = 
{
	if(*list_root != 0)
	{
		cell->next = *list_root;
	}
	*list_root = cell;
}

void(navgen_cell *cell, navgen_cell **list_root) remove_cell_from_list =
{
	if(cell == *list_root)
	{
		*list_root = (*list_root)->next;
		cell->next = 0;
		return;
	}

	navgen_cell *prev_cell = *list_root;
	navgen_cell *cur_cell = (*list_root)->next;

	while(cur_cell != 0)
	{
		if(cur_cell == cell)
		{
			prev_cell->next = cur_cell->next;
			cur_cell->next = 0;
			return;
		}

		prev_cell = cur_cell;
		cur_cell = cur_cell->next;
	}
}

navgen_cell *(int x, int y, int z, navgen_cell **list_root) get_cell_from_list =
{
	navgen_cell *cur_cell = *list_root;

	int iters = 0;

	while(cur_cell != 0)
	{
		// HACK HACK HACK HACK HACK HACK 
		// Easy hack to bypass 10k runaway loop error
		// HACK HACK HACK HACK HACK HACK 
		if(iters > 9000)
		{
			return get_cell_from_list(x,y,z,&cur_cell);
		}
		iters++;
		// HACK HACK HACK HACK HACK HACK 
		if(cur_cell->x == x && cur_cell->y == y && cur_cell->z == z)
		{
			return cur_cell;
		}
		cur_cell = cur_cell->next;
	}
	return 0;
}
// ------------------------------------------------------------------------------------------------------

// ------------------------------------------------------------------------------------------------------
// navgen_boundary struct and linked list logic
// ------------------------------------------------------------------------------------------------------

struct navgen_boundary
{
	int x;
	int y;
	int z;
	int ofs_x;
	int ofs_y;

	// Linked list node
	navgen_boundary *next;
};

navgen_boundary *(int x, int y, int z, int ofs_x, int ofs_y) create_boundary = 
{
	navgen_boundary *new_boundary = memalloc(sizeof(navgen_boundary));
	new_boundary->x = x;
	new_boundary->y = y;
	new_boundary->z = z;
	new_boundary->ofs_x = ofs_x;
	new_boundary->ofs_y = ofs_y;
	new_boundary->next = 0;
	return new_boundary;
}

void(navgen_boundary *boundary) delete_boundary = 
{
	memfree(boundary);
}

void(navgen_boundary *boundary, navgen_boundary **list_root) add_boundary_to_list = 
{
	if(*list_root != 0)
	{
		boundary->next = *list_root;
	}
	*list_root = boundary;
}

void(navgen_boundary *boundary, navgen_boundary **list_root) remove_boundary_from_list =
{
	if(boundary == *list_root)
	{
		*list_root = (*list_root)->next;
		boundary->next = 0;
		return;
	}

	navgen_boundary *prev_boundary = *list_root;
	navgen_boundary *cur_boundary = (*list_root)->next;

	while(cur_boundary != 0)
	{
		if(cur_boundary == boundary)
		{
			prev_boundary->next = cur_boundary->next;
			cur_boundary->next = 0;
			return;
		}

		prev_boundary = cur_boundary;
		cur_boundary = cur_boundary->next;
	}
}

navgen_boundary *(int x, int y, int z, int ofs_x, int ofs_y, navgen_boundary **list_root) get_boundary_from_list =
{
	navgen_boundary *cur_boundary = *list_root;

	while(cur_boundary != 0)
	{
		if(cur_boundary->x == x && cur_boundary->y == y && cur_boundary->z == z && cur_boundary->ofs_x == ofs_x && cur_boundary->ofs_y == ofs_y)
		{
			return cur_boundary;
		}
		cur_boundary = cur_boundary->next;
	}
	return 0;
}
// ------------------------------------------------------------------------------------------------------

navgen_cell *open_list_root_node;
navgen_cell *closed_list_root_node;
navgen_boundary *boundary_list_root_node;

void() navgen_start =
{
	// If the lists have any previous nodes, delete them all
	navgen_cell *temp_cell;
	navgen_cell *temp_cell_next;
	// Empty the open list
	temp_cell = open_list_root_node;
	while(temp_cell != 0)
	{
		temp_cell_next = temp_cell->next;
		remove_cell_from_list(temp_cell, &open_list_root_node);
		delete_cell(temp_cell);
		temp_cell = temp_cell_next;
	}

	// Empty the closed list
	temp_cell = closed_list_root_node;
	while(temp_cell != 0)
	{
		temp_cell_next = temp_cell->next;
		remove_cell_from_list(temp_cell, &closed_list_root_node);
		temp_cell = temp_cell_next;
	}

	// Empty the boundary list
	navgen_boundary *temp_boundary = boundary_list_root_node;
	navgen_boundary *temp_boundary_next;
	while(temp_boundary != 0)
	{
		temp_boundary_next = temp_boundary->next;
		remove_boundary_from_list(temp_boundary, &boundary_list_root_node);
		temp_boundary = temp_boundary_next;
	}



	print("navgen start\n");

	// Create a cell at the player's position:
	vector player_pos;
	vec_eq(&player_pos, getentity(player_localentnum, GE_ORIGIN));
	// Make sure it's at the floor
	cl_navgen_gen_drop_to_floor(player_pos);
	vec_eq(&player_pos,trace_endpos);

	int pos_x = floor(player_pos.x);
	int pos_y = floor(player_pos.y);
	// Lift up above the floor
	int pos_z = ceil(player_pos.z);

	navgen_cell *cell = create_cell(pos_x, pos_y, pos_z);

	// Add it to the open list
	add_cell_to_list(cell, &open_list_root_node);
}

void() navgen_logic =
{	
	int verbose = 0;
	if(verbose) print("---- Navgen logic tick start ----\n");
	navgen_cell *cur_open_list = open_list_root_node;
	navgen_cell *new_open_list = 0;

	navgen_cell *cell = cur_open_list;

	int cell_size = 8;
	// int num_ofs = 8;
	// // One entry for each of the 8 cardinal + intercardinal directions
	// int ofs_x_vals[8] = { 0, 1, 1, 1, 0,-1,-1,-1};
	// int ofs_y_vals[8] = { 1, 1, 0,-1,-1,-1, 0, 1};
	
	int num_ofs = 4;
	int ofs_x_vals[4] = { 0, 1, 0,-1};
	int ofs_y_vals[4] = { 1, 0,-1, 0};


	while(cell != 0)
	{
		if(verbose) 
		{
			print("\t-- Handling cell at: (");
			print(ftos(cell->x));
			print(",");
			print(ftos(cell->y));
			print(",");
			print(ftos(cell->z));
			print(") --\n");
		}

		// For each of the eight directions:
		for(int i = 0; i < num_ofs; i++)
		{
			int ofs_x = ofs_x_vals[i] * cell_size;
			int ofs_y = ofs_y_vals[i] * cell_size;
			int next_cell_x = cell->x + ofs_x;
			int next_cell_y = cell->y + ofs_y;
			
			if(verbose) print("\t\tCell was not in any list, continuing.\n");

			// If we can't fully walk from cell to next_cell, this is a boundary
			vector cell_pos;
			cell_pos.x = cell->x;
			cell_pos.y = cell->y;
			cell_pos.z = cell->z;

			vector next_cell_pos;
			next_cell_pos.x = next_cell_x;
			next_cell_pos.y = next_cell_y;
			next_cell_pos.z = cell->z;

			int obstructed = navgen_obstructed(cell_pos, next_cell_pos);

			// Lift up above the floor, snap to grid of size 'cell_size'
			int z_pos = cell->z + cell_size * floor((ceil(trace_endpos.z) - cell->z) / cell_size);

			// If we can't walk to it, convert it to an boundary
			if(obstructed)
			{
				if(verbose) print("\t\tCell was obstructed, logging boundary.\n");
				// Add it to our list of boundaries
				navgen_boundary *new_boundary = create_boundary(cell->x, cell->y, cell->z, ofs_x, ofs_y);
				add_boundary_to_list( new_boundary, &boundary_list_root_node);
			}
			// If we can walk to it, add it to the new open list
			else
			{
				// If this cell is already in the closed list, skip it
				if(get_cell_from_list(next_cell_x, next_cell_y, z_pos, &closed_list_root_node) != 0)
				{
					if(verbose) print("\t\tCell was in closed list, skipping...\n");
					continue;
				}

				// If this cell is already in the cur open list, skip it
				if(get_cell_from_list(next_cell_x, next_cell_y, z_pos, &cur_open_list) != 0)
				{
					if(verbose) print("\t\tCell was in cur open list, skipping...\n");
					continue;
				}

				// If this cell is already in the new open list, skip it
				if(get_cell_from_list(next_cell_x, next_cell_y, z_pos, &new_open_list) != 0)
				{
					if(verbose) print("\t\tCell was in new open list, skipping...\n");
					continue;
				}

				if(verbose) print("\t\tCell was good, adding new cell to open list.\n");
				navgen_cell *new_cell = create_cell(next_cell_x, next_cell_y, z_pos);
				add_cell_to_list(new_cell, &new_open_list);
			}
		}
		
		// Get the next cell
		navgen_cell *next_cell = cell->next;

		// Remove cell from the current open list
		if(verbose) print("\t\tRemove it from the current open list\n");
		remove_cell_from_list(cell, &cur_open_list);		

		// Add cell to closed list
		if(verbose) print("\t\tAdding cell to closed list.\n");
		add_cell_to_list(cell, &closed_list_root_node);

		// Updating the loop variable
		cell = next_cell;
	}

	// Swap the open list:
	if(verbose) print("Swapping open lists.\n");
	open_list_root_node = new_open_list;
	

	// We have now exhausted the current open set and created a new open set
	
	// ------------------------------------------------------------------------
	// Draw the open list
	// ------------------------------------------------------------------------
	cell = open_list_root_node;

	while(cell != 0)
	{
		cl_navmesh_draw_vert([cell->x, cell->y, cell->z],[0,0,1],0.4);
		cell = cell->next;
	}

	// ------------------------------------------------------------------------
	// Draw the closed list
	// ------------------------------------------------------------------------
	navgen_boundary *boundary = boundary_list_root_node;

	while(boundary != 0)
	{
		cl_navmesh_draw_vert([boundary->x, boundary->y, boundary->z],[1,0,0],0.4);
		boundary = boundary->next;
	}
	if(verbose) print("---- Navgen logic tick end ----\n");
}