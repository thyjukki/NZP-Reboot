#define NAVGEN_PHASE_RASTERIZATION					1
#define NAVGEN_PHASE_RECTANGLE_EXPANSION			2
#define NAVGEN_PHASE_RECTANGLE_VECTORIZATION		3
#define NAVGEN_PHASE_RECTANGLE_TRIANGULATION		4
#define NAVGEN_PHASE_MESH_DETRIANGULATION			5
#define NAVGEN_PHASE_DONE							6
int navgen_phase;

// ---------------------------------------------------------------------------
// NAVGEN_PHASE_RASTERIZATION
// ---------------------------------------------------------------------------
void cl_navgen_phase_rasterization_start();
void cl_navgen_phase_rasterization_step();
int cl_navgen_phase_rasterization_finished();
void cl_navgen_draw_phase_rasterization();
// Cells
struct navgen_cell;
navgen_cell *(int x, int y, int z) create_cell;
void(navgen_cell *cell) delete_cell;
void(navgen_cell *cell, navgen_cell **list_root) add_cell_to_list;
void(navgen_cell *cell, navgen_cell **list_root) remove_cell_from_list;
navgen_cell *(int x, int y, int z, navgen_cell **list_root) get_cell_from_list;
// Boundaries
struct navgen_boundary;
navgen_boundary *(int x, int y, int z, int ofs_x, int ofs_y) create_boundary;
void(navgen_boundary *boundary) delete_boundary;
void(navgen_boundary *boundary, navgen_boundary **list_root) add_boundary_to_list;
void(navgen_boundary *boundary, navgen_boundary **list_root) remove_boundary_from_list;
navgen_boundary *(int x, int y, int z, int ofs_x, int ofs_y, navgen_boundary **list_root) get_boundary_from_list;
// Data
navgen_cell *open_list_root_node;
navgen_cell *closed_list_root_node;
navgen_boundary *boundary_list_root_node;
// ---------------------------------------------------------------------------
// NAVGEN_PHASE_RECTANGLE_EXPANSION
// ---------------------------------------------------------------------------
void cl_navgen_phase_rectangle_expansion_start();
void cl_navgen_phase_rectangle_expansion_step();
int cl_navgen_phase_rectangle_expansion_finished();
void cl_navgen_draw_phase_rectangle_expansion();
// ---------------------------------------------------------------------------
// NAVGEN_PHASE_RECTANGLE_VECTORIZATION
// ---------------------------------------------------------------------------
void cl_navgen_phase_rectangle_vectorization_start();
void cl_navgen_phase_rectangle_vectorization_step();
int cl_navgen_phase_rectangle_vectorization_finished();
void cl_navgen_draw_phase_rectangle_vectorization();
// ---------------------------------------------------------------------------
// NAVGEN_PHASE_RECTANGLE_TRIANGULATION
// ---------------------------------------------------------------------------
void cl_navgen_phase_rectangle_triangulation_start();
void cl_navgen_phase_rectangle_triangulation_step();
int cl_navgen_phase_rectangle_triangulation_finished();
void cl_navgen_draw_phase_rectangle_triangulation();
// ---------------------------------------------------------------------------
// NAVGEN_PHASE_MESH_DETRIANGULATION
// ---------------------------------------------------------------------------
void cl_navgen_phase_mesh_detriangulation_start();
void cl_navgen_phase_mesh_detriangulation_step();
int cl_navgen_phase_mesh_detriangulation_finished();
void cl_navgen_draw_phase_mesh_detriangulation();
// ---------------------------------------------------------------------------
// NAVGEN_PHASE_DONE
// ---------------------------------------------------------------------------
navgen_cell *navgen_cells_to_add_verts_to;
navgen_cell *navgen_cells_to_add_quads_to;


void() navgen_start =
{
	navgen_phase = NAVGEN_PHASE_RASTERIZATION;
	cl_navgen_phase_rasterization_start();
}

void() navgen_logic =
{
	if(navgen_phase == NAVGEN_PHASE_RASTERIZATION)
	{
		cl_navgen_phase_rasterization_step();

		if(cl_navgen_phase_rasterization_finished())
		{
			navgen_phase = NAVGEN_PHASE_RECTANGLE_EXPANSION;
			cl_navgen_phase_rectangle_expansion_start();
		}
	}
	else if(navgen_phase == NAVGEN_PHASE_RECTANGLE_EXPANSION)
	{
		cl_navgen_phase_rectangle_expansion_step();

		if(cl_navgen_phase_rectangle_expansion_finished())
		{
			navgen_phase = NAVGEN_PHASE_RECTANGLE_VECTORIZATION;
			cl_navgen_phase_rectangle_vectorization_start();
		}
	}
	else if(navgen_phase == NAVGEN_PHASE_RECTANGLE_VECTORIZATION)
	{
		cl_navgen_phase_rectangle_vectorization_step();

		if(cl_navgen_phase_rectangle_vectorization_finished())
		{
			navgen_phase = NAVGEN_PHASE_RECTANGLE_TRIANGULATION;
			cl_navgen_phase_rectangle_triangulation_start();
		}
	}
	else if(navgen_phase == NAVGEN_PHASE_RECTANGLE_TRIANGULATION)
	{
		cl_navgen_phase_rectangle_triangulation_step();

		if(cl_navgen_phase_rectangle_triangulation_finished())
		{
			navgen_phase = NAVGEN_PHASE_MESH_DETRIANGULATION;
			cl_navgen_phase_mesh_detriangulation_start();
		}
	}
	else if(navgen_phase == NAVGEN_PHASE_MESH_DETRIANGULATION)
	{
		cl_navgen_phase_mesh_detriangulation_step();

		if(cl_navgen_phase_mesh_detriangulation_finished())
		{
			navgen_phase = NAVGEN_PHASE_DONE;
		}
	}

	cl_navgen_draw_phase_rasterization();
	cl_navgen_draw_phase_rectangle_expansion();
	cl_navgen_draw_phase_rectangle_vectorization();
	cl_navgen_draw_phase_rectangle_triangulation();
	cl_navgen_draw_phase_mesh_detriangulation();
}




// ===========================================================================================================
// NAVGEN_PHASE_RASTERIZATION
// ===========================================================================================================

// TODO - Should implement K-D trees to speed up map rasterization
// Need to implement the following K-D tree functions:
//		insertion
//		deletion
//		search

// ------------------------------------------------------------------------------------------------------
// navgen_cell struct and linked list logic
// ------------------------------------------------------------------------------------------------------
struct navgen_cell
{
	int x;
	int y;
	int z;

	// Neighbor cells
	navgen_cell *y_next;
	navgen_cell *x_next;
	navgen_cell *y_prev;
	navgen_cell *x_prev;

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
	new_cell->y_next = 0;
	new_cell->x_next = 0;
	new_cell->y_prev = 0;
	new_cell->x_prev = 0;

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

void mark_cells_as_neighbors(navgen_cell *a, navgen_cell *b, int ofs_x, int ofs_y) = 
{
	// Assume that (ofs_x,ofs_y) takes us from a to b
	if(ofs_x == 0 && ofs_y == 1)
	{
		a->y_next = b;
		b->y_prev = a;
	}
	else if(ofs_x == 1 && ofs_y == 0)
	{
		a->x_next = b;
		b->x_prev = a;
	}
	else if(ofs_x == 0 && ofs_y == -1)
	{
		a->y_prev = b;
		b->y_next = a;
	}
	else if(ofs_x == -1 && ofs_y == 0)
	{
		a->x_prev = b;
		b->x_next = a;
	}
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

void cl_navgen_phase_rasterization_start()
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
void cl_navgen_phase_rasterization_step()
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
		if(verbose) print("\t-- Handling cell at: (",ftos(cell->x),",",ftos(cell->y),",",ftos(cell->z),") --\n");

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

			// If we can't walk to it, convert it to a boundary
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
				navgen_cell *neighbor;

				// If this cell is already in the closed list, skip it
				neighbor = get_cell_from_list(next_cell_x, next_cell_y, z_pos, &closed_list_root_node);
				if(neighbor != 0)
				{
					mark_cells_as_neighbors(cell, neighbor, ofs_x_vals[i], ofs_y_vals[i]);
					if(verbose) print("\t\tCell was in closed list, skipping...\n");
					continue;
				}

				// If this cell is already in the cur open list, skip it
				neighbor = get_cell_from_list(next_cell_x, next_cell_y, z_pos, &cur_open_list);
				if(neighbor != 0)
				{
					mark_cells_as_neighbors(cell, neighbor, ofs_x_vals[i], ofs_y_vals[i]);
					if(verbose) print("\t\tCell was in cur open list, skipping...\n");
					continue;
				}

				// If this cell is already in the new open list, skip it
				neighbor = get_cell_from_list(next_cell_x, next_cell_y, z_pos, &new_open_list);
				if(neighbor != 0)
				{
					mark_cells_as_neighbors(cell, neighbor, ofs_x_vals[i], ofs_y_vals[i]);
					if(verbose) print("\t\tCell was in new open list, skipping...\n");
					continue;
				}

				if(verbose) print("\t\tCell was good, adding new cell to open list.\n");
				navgen_cell *new_cell = create_cell(next_cell_x, next_cell_y, z_pos);
				mark_cells_as_neighbors(cell, neighbor, ofs_x_vals[i], ofs_y_vals[i]);
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
}

int cl_navgen_phase_rasterization_finished()
{
	return open_list_root_node == 0;
}

void cl_navgen_draw_phase_rasterization()
{
	vector open_cell_color = [0,0,1];
	vector closed_cell_color = [0,1,0];
	vector boundary_color = [1,0,0];

	float open_cell_alpha = 0.2;
	float closed_cell_alpha = 0.01;
	float boundary_alpha = 0.4;

	navgen_cell *cell;

	// ------------------------------------------------------------------------
	// Draw the open list
	// ------------------------------------------------------------------------
	cell = open_list_root_node;

	while(cell != 0)
	{
		cl_navmesh_draw_vert([cell->x, cell->y, cell->z],open_cell_color,open_cell_alpha);
		cell = cell->next;
	}

	// ------------------------------------------------------------------------
	// Draw the closed list
	// ------------------------------------------------------------------------
	// NOTE - The closed list of cells is MASSIVE, this kills FPS.
	// cell = closed_list_root_node;

	// while(cell != 0)
	// {
	// 	cl_navmesh_draw_vert([cell->x, cell->y, cell->z],closed_cell_color,closed_cell_alpha);
	// 	cell = cell->next;
	// }

	// ------------------------------------------------------------------------
	// Draw the boundaries
	// ------------------------------------------------------------------------

	navgen_boundary *boundary = boundary_list_root_node;

	while(boundary != 0)
	{
		cl_navmesh_draw_vert([boundary->x, boundary->y, boundary->z],boundary_color,boundary_alpha);
		boundary = boundary->next;
	}
}
// ===========================================================================================================
// NAVGEN_PHASE_RECTANGLE_EXPANSION
// ===========================================================================================================
void cl_navgen_phase_rectangle_expansion_start()
{
	
}
void cl_navgen_phase_rectangle_expansion_step()
{

}
int cl_navgen_phase_rectangle_expansion_finished()
{
	return TRUE;
}
void cl_navgen_draw_phase_rectangle_expansion()
{

}
// ===========================================================================================================
// NAVGEN_PHASE_RECTANGLE_VECTORIZATION
// ===========================================================================================================
void cl_navgen_phase_rectangle_vectorization_start()
{

}
void cl_navgen_phase_rectangle_vectorization_step()
{

}
int cl_navgen_phase_rectangle_vectorization_finished()
{
	return TRUE;
}
void cl_navgen_draw_phase_rectangle_vectorization()
{

}
// ===========================================================================================================
// NAVGEN_PHASE_RECTANGLE_TRIANGULATION
// ===========================================================================================================
void cl_navgen_phase_rectangle_triangulation_start()
{

}
void cl_navgen_phase_rectangle_triangulation_step()
{

}
int cl_navgen_phase_rectangle_triangulation_finished()
{
	return TRUE;
}
void cl_navgen_draw_phase_rectangle_triangulation()
{

}
// ===========================================================================================================
// NAVGEN_PHASE_MESH_DETRIANGULATION
// ===========================================================================================================
void cl_navgen_phase_mesh_detriangulation_start()
{

}
void cl_navgen_phase_mesh_detriangulation_step()
{

}
int cl_navgen_phase_mesh_detriangulation_finished()
{
	return TRUE;
}
void cl_navgen_draw_phase_mesh_detriangulation()
{

}
