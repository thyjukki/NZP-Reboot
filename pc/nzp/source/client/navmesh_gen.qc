//============================================================================================================
// Navgen v2020
//============================================================================================================


// ----------------------------------------------------------------------------------------------------------
// Triangulation
// ----------------------------------------------------------------------------------------------------------

struct navgen_vertex
{
	vector pos;
};


//Either a tri or a quad
struct navgen_poly
{
	int verts[4];
	int vert_count;
	
	//The following fields are only used for actually pathfinding on the navmesh
	//The values are calculated in the editor when the navmesh is saved, but are not assigned in the editor before that.
	//These values are saved in the navmesh file, and loaded into the server's navmesh
	//FIXME: Unhandled edge case when a polygon shares a single edge with more than one polygon (like dropping down from a ledge)
	// float connected_polies_count;//How many polygons we share an edge with
	// float connected_polies[4];//Index of the polygons that we share an edge with (similar to links), more than 4 should be impossible (FIXME: highly unlikely)
	// float connected_polies_left_vert[4];//The left vertex of the shared edge
	// float connected_polies_right_vert[4];//The right vertex of the shared edge
	// vector center;//The center of the polygon in 3D space (pre-calculated because why calculate it at runtime)
};


#define NAVGEN_MAX_VERTS 100000
navgen_vertex *cl_navgen_verts;
int cl_navgen_vert_count;

#define NAVGEN_MAX_POLIES 100000
navgen_poly *cl_navgen_polies;
int cl_navgen_poly_count;

void navgen_draw_poly(int poly_index)
{
	//Assigning the shader as something else so that fte doesn't batch the calls (leading to colors not changing between draw calls)
	R_BeginPolygon("debug/wireframe",0);
	R_BeginPolygon("debug/solid_nocull",0);
	
	vector color = [0.2,0.8,0.2];
	
	float face_alpha = 0.1;
	
	R_PolygonVertex(cl_navgen_verts[cl_navgen_polies[poly_index].verts[0]].pos, [0,0,0], color, face_alpha);
	R_PolygonVertex(cl_navgen_verts[cl_navgen_polies[poly_index].verts[1]].pos, [0,0,0], color, face_alpha);
	R_PolygonVertex(cl_navgen_verts[cl_navgen_polies[poly_index].verts[2]].pos, [0,0,0], color, face_alpha);
	if(cl_navgen_polies[poly_index].vert_count > 3)
		R_PolygonVertex(cl_navgen_verts[cl_navgen_polies[poly_index].verts[3]].pos, [0,0,0], color, face_alpha);
	R_EndPolygon();
	
	
	//Drawing polygon border

	//Vert 0->1
	cl_navmesh_draw_edge(cl_navgen_verts[cl_navgen_polies[poly_index].verts[0]].pos,cl_navgen_verts[cl_navgen_polies[poly_index].verts[1]].pos);
	//Vert 1->2
	cl_navmesh_draw_edge(cl_navgen_verts[cl_navgen_polies[poly_index].verts[1]].pos,cl_navgen_verts[cl_navgen_polies[poly_index].verts[2]].pos);
	
	if(cl_navgen_polies[poly_index].vert_count == 3)
	{
		//Vert 2->0
		cl_navmesh_draw_edge(cl_navgen_verts[cl_navgen_polies[poly_index].verts[2]].pos,cl_navgen_verts[cl_navgen_polies[poly_index].verts[0]].pos);
	}
	else//Quad
	{
		//Vert 2->3
		cl_navmesh_draw_edge(cl_navgen_verts[cl_navgen_polies[poly_index].verts[2]].pos,cl_navgen_verts[cl_navgen_polies[poly_index].verts[3]].pos);
		//Vert 3->0
		cl_navmesh_draw_edge(cl_navgen_verts[cl_navgen_polies[poly_index].verts[3]].pos,cl_navgen_verts[cl_navgen_polies[poly_index].verts[0]].pos);
	}
}



void navgen_add_poly(int v1, int v2, int v3, int v4)
{
	// Iterate through all existing polygons, check if this polygon already exists:
	int verts[4] = {v1, v2, v3, v4};

	for(int i = 0; i < cl_navgen_poly_count; i++)
	{
		int found_verts[4] = {FALSE, FALSE, FALSE, FALSE};
	
		// Iterate through our verts
		for(int j = 0; j < 4; j++)
		{
			// Iterate through the other polygon's verts
			for(int k = 0; k < 4; k++)
			{
				if(verts[j] == cl_navgen_polies[i].verts[k])
				{
					found_verts[j] = TRUE;
					break;
				}
			}	
		}
	
		// If we found all 4 verts, don't add this polygon.
		if(found_verts[0] && found_verts[1] && found_verts[2])
		{
			if(v4 == -1)
			{
				return;
			}
			else if(found_verts[3])
			{
				return;
			}
		}

	}

	cl_navgen_polies[cl_navgen_poly_count].verts[0] = v1;
	cl_navgen_polies[cl_navgen_poly_count].verts[1] = v2;
	cl_navgen_polies[cl_navgen_poly_count].verts[2] = v3;
	cl_navgen_polies[cl_navgen_poly_count].verts[3] = v4;

	if(v4 == -1)
	{
		cl_navgen_polies[cl_navgen_poly_count].vert_count = 3;
	}
	else
	{
		cl_navgen_polies[cl_navgen_poly_count].vert_count = 4;
	}
	cl_navgen_poly_count++;
	
}

// //A single navmesh vertex
// struct navgen_vertex
// {
// 	vector pos;

// 	// Linked list node
// 	navgen_vertex *next;
// };


// // //Either a tri or a quad
// // struct navgen_poly
// // {
// // 	float verts[4];
// // 	float vert_count;
	
// // 	//The following fields are only used for actually pathfinding on the navmesh
// // 	//The values are calculated in the editor when the navmesh is saved, but are not assigned in the editor before that.
// // 	//These values are saved in the navmesh file, and loaded into the server's navmesh
// // 	//FIXME: Unhandled edge case when a polygon shares a single edge with more than one polygon (like dropping down from a ledge)
// // 	float connected_polies_count;//How many polygons we share an edge with
// // 	float connected_polies[4];//Index of the polygons that we share an edge with (similar to links), more than 4 should be impossible (FIXME: highly unlikely)
// // 	float connected_polies_left_vert[4];//The left vertex of the shared edge
// // 	float connected_polies_right_vert[4];//The right vertex of the shared edge
// // 	vector center;//The center of the polygon in 3D space (pre-calculated because why calculate it at runtime)

// // 	// Linked list node
// // 	navgen_vertex *next;
// // };


// navgen_vertex *(vector pos) navgen_create_vertex = 
// {
// 	navgen_vertex *new_vert = memalloc(sizeof(navgen_vertex));
// 	new_vert->pos = pos;
// 	new_vert->next = 0;
// 	return new_vert;
// }

// void(navgen_vertex *vert) navgen_delete_vertex = 
// {
// 	memfree(vert);
// }

// void(navgen_vertex *vert, navgen_vertex **list_root) navgen_add_vert_to_list = 
// {
// 	if(*list_root != 0)
// 	{
// 		vert->next = *list_root;
// 	}
// 	*list_root = vert;
// }

// void(navgen_vertex *vert, navgen_vertex **list_root) navgen_remove_vert_from_list =
// {
// 	if(vert == *list_root)
// 	{
// 		*list_root = (*list_root)->next;
// 		vert->next = 0;
// 		return;
// 	}

// 	navgen_vertex *prev_vert = *list_root;
// 	navgen_vertex *cur_vert = (*list_root)->next;

// 	while(cur_vert != 0)
// 	{
// 		if(cur_vert == vert)
// 		{
// 			prev_vert->next = cur_vert->next;
// 			cur_vert->next = 0;
// 			return;
// 		}

// 		prev_vert = cur_vert;
// 		cur_vert = cur_vert->next;
// 	}
// }

// // navgen_vertex *(int x, int y, int z, navgen_cell **list_root) get_vert_from_list =
// // {
// // 	navgen_vertex *cur_cell = *list_root;

// // 	int iters = 0;

// // 	while(cur_cell != 0)
// // 	{
// // 		// HACK HACK HACK HACK HACK HACK 
// // 		// Easy hack to bypass 10k runaway loop error
// // 		// HACK HACK HACK HACK HACK HACK 
// // 		if(iters > 9000)
// // 		{
// // 			return get_cell_from_list(x,y,z,&cur_cell);
// // 		}
// // 		iters++;
// // 		// HACK HACK HACK HACK HACK HACK 
// // 		if(cur_cell->x == x && cur_cell->y == y && cur_cell->z == z)
// // 		{
// // 			return cur_cell;
// // 		}
// // 		cur_cell = cur_cell->next;
// // 	}
// // 	return 0;
// // }

// navgen_vertex *navgen_vert_list_root_node;

// // Array
// navgen_vertex *navgen_verts;
// int navgen_verts_count;

// ----------------------------------------------------------------------------------------------------------

// ----------------------------------------------------------------------------------------------------------
// Rasterization
// ----------------------------------------------------------------------------------------------------------

// TODO - Should implement K-D trees to speed up map rasterization
// Need to implement the following K-D tree functions:
//		insertion
//		deletion
//		search

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


// Steps dummy_ent ent from ent->origin to ent->goal
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

int(vector start, vector end) navgen_obstructed = 
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

	// For navgen, the corresponding vertex this cell spawned
	int navgen_vert;
};

navgen_cell *(int x, int y, int z) create_cell = 
{
	navgen_cell *new_cell = memalloc(sizeof(navgen_cell));
	new_cell->x = x;
	new_cell->y = y;
	new_cell->z = z;
	new_cell->next = 0;
	new_cell->navgen_vert = -1;
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

navgen_cell *navgen_cells_to_add_verts_to;
navgen_cell *navgen_cells_to_add_quads_to;

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

	// Empty the navgen data
	memfree(cl_navgen_polies);
	memfree(cl_navgen_verts);
	cl_navgen_vert_count = 0;
	cl_navgen_poly_count = 0;




	print("navgen start\n");

	// Create a cell at the player's position:
	vector player_pos = getentity(player_localentnum, GE_ORIGIN);
	// Make sure it's at the floor
	navgen_drop_to_floor(player_pos);
	player_pos = trace_endpos;

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

	// ---------------------------------------------------------------------------------
	// Rasterization
	// ---------------------------------------------------------------------------------
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
		cl_navmesh_draw_vert([cell->x, cell->y, cell->z],[0,0,1],0.02);
		cell = cell->next;
	}

	// ------------------------------------------------------------------------
	// Draw the closed list
	// ------------------------------------------------------------------------
	navgen_boundary *boundary = boundary_list_root_node;

	while(boundary != 0)
	{
		cl_navmesh_draw_vert([boundary->x, boundary->y, boundary->z],[1,0,0],0.02);
		boundary = boundary->next;
	}
	// ---------------------------------------------------------------------------------


	// ---------------------------------------------------------------------------------
	// Triangulation
	// ---------------------------------------------------------------------------------

	int i;
	int j;
	int count;
	navgen_cell *node;

	// ----------------------------------------------------
	// Build the geometry per each cell
	// ----------------------------------------------------

	if(open_list_root_node == 0 && cl_navgen_vert_count == 0)
	{
		// Allocate memory for the verts and polies
		cl_navgen_verts = memalloc(sizeof(navgen_vertex) * NAVGEN_MAX_VERTS);
		cl_navgen_polies = memalloc(sizeof(navgen_poly) * NAVGEN_MAX_POLIES);
		cl_navgen_vert_count = 0;
		cl_navgen_poly_count = 0;

		navgen_cells_to_add_verts_to = closed_list_root_node;
		navgen_cells_to_add_quads_to = closed_list_root_node;
	}

	// Add a vertex for each cell
	if(navgen_cells_to_add_verts_to != 0)
	{
		node = navgen_cells_to_add_verts_to;

		// Only process 1000 per frame
		for(count = 0; count < 1; count++)
		{
			cl_navgen_verts[cl_navgen_vert_count].pos = [node->x, node->y, node->z];
			node->navgen_vert = cl_navgen_vert_count;
			cl_navgen_vert_count++;

			node = node->next;
			if(node == 0)
				break;
		}

		navgen_cells_to_add_verts_to = node;
	}

	// Add quads to the cell vertices (only do it after we've added verts to all cells)
	if(navgen_cells_to_add_quads_to != 0 && navgen_cells_to_add_verts_to == 0)
	{
		node = navgen_cells_to_add_quads_to;

		// Only process 1000 per frame
		for(count = 0; count < 1; count++)
		{
			// Check the eight neighbors this node may have:

			// For neighbors, we're going to consider:
			// Nodes immediately North, NE, East, SE, South, SW, West
			// As well as nodes 1 node above those directions, or one node below any of those directions

			int neighbor_ofs_x[8] = { 0, 1, 1, 1, 0,-1,-1,-1};
			int neighbor_ofs_y[8] = { 1, 1, 0,-1,-1,-1, 0, 1};
			int num_neighbors = 8;
			int neighbor_ofs_z[3] = {0, -1, 1};
			int num_ofs_z = 3;

			int neighbor_verts[8] = {-1,-1,-1,-1,-1,-1,-1,-1};

			navgen_cell *neighbor_cell = 0;

			// Check each of our 8 neihgbors
			for(i = 0; i < num_neighbors; i++)
			{
				// First check at the same level, then check one level below, and finally check one level above.
				for(j = 0; j < num_ofs_z; j++)
				{
					int neighbor_x = node->x + neighbor_ofs_x[i] * cell_size;
					int neighbor_y = node->y + neighbor_ofs_y[i] * cell_size;
					int neighbor_z = node->z + neighbor_ofs_z[j] * cell_size;
					
					// First check at the same Z-coordinates
					neighbor_cell = get_cell_from_list(neighbor_x, neighbor_y, neighbor_z, &closed_list_root_node);
					if(neighbor_cell != 0)
					{
						neighbor_verts[i] = neighbor_cell->navgen_vert;
						break;
					}
				}

			}

			// Check which neighbors we found, add the corresponding vertices
			if(neighbor_verts[0] != -1 && neighbor_verts[1] != -1 && neighbor_verts[2] != -1)
			{
				// Add a polygon to the NE
				// (Build the polygon in CCW order, starting at this node's vertex)
				navgen_add_poly(node->navgen_vert, neighbor_verts[2], neighbor_verts[1], neighbor_verts[0]);
			}
			if(neighbor_verts[2] != -1 && neighbor_verts[3] != -1 && neighbor_verts[4] != -1)
			{
				// Add a polygon to the SE
				// (Build the polygon in CCW order, starting at this node's vertex)
				navgen_add_poly(node->navgen_vert, neighbor_verts[4], neighbor_verts[3], neighbor_verts[2]);
			}
			if(neighbor_verts[4] != -1 && neighbor_verts[5] != -1 && neighbor_verts[6] != -1)
			{
				// Add a polygon to the SW
				// (Build the polygon in CCW order, starting at this node's vertex)
				navgen_add_poly(node->navgen_vert, neighbor_verts[6], neighbor_verts[5], neighbor_verts[4]);
			}
			if(neighbor_verts[6] != -1 && neighbor_verts[7] != -1 && neighbor_verts[0] != -1)
			{
				// Add a polygon to the NW
				// (Build the polygon in CCW order, starting at this node's vertex)
				navgen_add_poly(node->navgen_vert, neighbor_verts[0], neighbor_verts[7], neighbor_verts[6]);
			}

			node = node->next;
			if(node == 0)
				break;
		}
		navgen_cells_to_add_quads_to = node;
	}

	print("Num vertices: ",ftos(cl_navgen_vert_count),"\n");
	print("Num polygons: ",ftos(cl_navgen_poly_count),"\n");
	
	for(i = 0; i < cl_navgen_vert_count; i++)
	{
		float vert_diameter = 1.0;
		vector vert_size = [vert_diameter, vert_diameter, vert_diameter];
		cl_navmesh_draw_box(cl_navgen_verts[i].pos,vert_size,[0,0,1],0.5);
	}

	for(i = 0; i < cl_navgen_poly_count; i++)
	{
		navgen_draw_poly(i);
	}


	// if(open_list_root_node == 0 && navgen_vert_list_root_node == 0)
	// {
	// 	print("Finished algorithm\n");
	// 	// navgen_vert_list_root_node


	// 	int num_boundaries = 0;

	// 	navgen_boundary *temp_boundary = boundary_list_root_node;

	// 	while(temp_boundary != 0)
	// 	{
	// 		// vector ofs;
	// 		// navgen_vertex *new_vert;
	// 		// vector boundary_center = [temp_boundary->x, temp_boundary->y, temp_boundary->z];

	// 		// // bottom left
	// 		// ofs = [VEC_HULL_MIN[0], VEC_HULL_MIN[1], 0];
	// 		// new_vert = navgen_create_vertex(boundary_center + ofs);
	// 		// navgen_add_vert_to_list(new_vert, &navgen_vert_list_root_node);

	// 		// // top left
	// 		// ofs = [VEC_HULL_MIN[0], VEC_HULL_MAX[1], 0];
	// 		// new_vert = navgen_create_vertex(boundary_center + ofs);
	// 		// navgen_add_vert_to_list(new_vert, &navgen_vert_list_root_node);

	// 		// // top right
	// 		// ofs = [VEC_HULL_MAX[0], VEC_HULL_MAX[1], 0];
	// 		// new_vert = navgen_create_vertex(boundary_center + ofs);
	// 		// navgen_add_vert_to_list(new_vert, &navgen_vert_list_root_node);

	// 		// // bottom right
	// 		// ofs = [VEC_HULL_MAX[0], VEC_HULL_MIN[1], 0];
	// 		// new_vert = navgen_create_vertex(boundary_center + ofs);
	// 		// navgen_add_vert_to_list(new_vert, &navgen_vert_list_root_node);
		
	// 		temp_boundary = temp_boundary->next;
	// 	}
	// }

	// // Draw the vertices
	// navgen_vertex *vert = navgen_vert_list_root_node;
	// while(vert != 0)
	// {
	// 	float vert_size = 1.0;
	// 	cl_navmesh_draw_box(vert->pos,[vert_size,vert_size,vert_size],[0,0,1],0.5);
	// 	vert = vert->next;
	// }


	if(verbose) print("---- Navgen logic tick end ----\n");
}