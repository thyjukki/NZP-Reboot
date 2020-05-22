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
navgen_cell *(navgen_cell *cell, navgen_cell **list_root) cell_in_list;
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
int navgen_cell_size = 8;
// ---------------------------------------------------------------------------
// NAVGEN_PHASE_RECTANGLE_EXPANSION
// ---------------------------------------------------------------------------
void cl_navgen_phase_rectangle_expansion_start();
void cl_navgen_phase_rectangle_expansion_step();
int cl_navgen_phase_rectangle_expansion_finished();
void cl_navgen_draw_phase_rectangle_expansion();
// Rectangles
struct navgen_rectangle;
navgen_rectangle *() create_rect;
void(navgen_rectangle *rect) delete_rect;
void(navgen_rectangle *rect, navgen_rectangle **list_root) add_rect_to_list;
void(navgen_rectangle *rect, navgen_rectangle **list_root) remove_rect_from_list;
// Data
navgen_rectangle *navgen_rectangles;
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

	// Cached pointer to the list containing this cell
	navgen_cell **containing_list;
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
	new_cell->containing_list = 0;

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
	cell->containing_list = list_root;
}

void(navgen_cell *cell, navgen_cell **list_root) remove_cell_from_list =
{
	if(cell->containing_list != list_root)
		return;
	
	if(cell == *list_root)
	{
		*list_root = (*list_root)->next;
		cell->next = 0;
		cell->containing_list = 0;
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
			cell->containing_list = 0;
			return;
		}

		prev_cell = cur_cell;
		cur_cell = cur_cell->next;
	}
}

// Checks if 'cell' is in the linked list starting at 'list_root'
// If it is, returns a pointer to cell,
// Otherwise, returns 0
navgen_cell *(navgen_cell *cell, navgen_cell **list_root) cell_in_list =
{
	if(cell->containing_list == list_root)
	{
			return cell;
		}
	return 0;
	// navgen_cell *cur_cell = *list_root;

	// int iters = 0;

	// while(cur_cell != 0)
	// {
	// 	// HACK HACK HACK HACK HACK HACK 
	// 	// Easy hack to bypass 10k runaway loop error
	// 	// HACK HACK HACK HACK HACK HACK 
	// 	if(iters > 9000)
	// 	{
	// 		return cell_in_list(cell,&cur_cell);
	// 	}
	// 	iters++;
	// 	// HACK HACK HACK HACK HACK HACK 
	// 	if(cur_cell == cell)
	// 	{
	// 		return cell;
	// 	}
	// 	cur_cell = cur_cell->next;
	// }
	// return 0;
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

int cells_are_neighbors(navgen_cell *a, navgen_cell *b) =
{
	if(a->x_next == b && b->x_prev == a)
		return TRUE;
	if(a->x_prev == b && b->x_next == a)
		return TRUE;
	if(a->y_next == b && b->y_prev == a)
		return TRUE;
	if(a->y_prev == b && b->y_next == a)
		return TRUE;
	return FALSE;
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
			int ofs_x = ofs_x_vals[i] * navgen_cell_size;
			int ofs_y = ofs_y_vals[i] * navgen_cell_size;
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

			// Lift up above the floor, snap to grid of size 'navgen_cell_size'
			int z_pos = cell->z + navgen_cell_size * floor((ceil(trace_endpos.z) - cell->z) / navgen_cell_size);

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

	// 	// Draw the neighbors:
	// 	vector pos = [cell->x, cell->y, cell->z];
	// 	// Offset start pos by -8, to show direction
	// 	pos.z -= 8;
	// 	vector neighbor_pos;
	// 	navgen_cell *neighbor;

	// 	if(cell->y_next != 0)
	// 	{
	// 		neighbor = cell->y_next;
	// 		neighbor_pos = [neighbor->x, neighbor->y, neighbor->z];
	// 		cl_navmesh_draw_edge(pos, neighbor_pos);
	// 	}
	// 	if(cell->x_next != 0)
	// 	{
	// 		neighbor = cell->x_next;
	// 		neighbor_pos = [neighbor->x, neighbor->y, neighbor->z];
	// 		cl_navmesh_draw_edge(pos, neighbor_pos);
	// 	}
	// 	if(cell->y_prev != 0)
	// 	{
	// 		neighbor = cell->y_prev;
	// 		neighbor_pos = [neighbor->x, neighbor->y, neighbor->z];
	// 		cl_navmesh_draw_edge(pos, neighbor_pos);
	// 	}
	// 	if(cell->x_prev != 0)
	// 	{
	// 		neighbor = cell->x_prev;
	// 		neighbor_pos = [neighbor->x, neighbor->y, neighbor->z];
	// 		cl_navmesh_draw_edge(pos, neighbor_pos);
	// 	}




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

// ------------------------------------------------------------------------------------------------------
// navgen_rectangle struct and linked list logic
// ------------------------------------------------------------------------------------------------------
struct navgen_rectangle
{
	navgen_cell *min;
	navgen_cell *max;

	// List of the cells contained in this rectangle
	navgen_cell *cells;

	// Linked list node
	navgen_rectangle *next;
};

navgen_rectangle *() create_rect = 
{
	navgen_rectangle *new_rect = memalloc(sizeof(navgen_rectangle));
	new_rect->min = 0;
	new_rect->max = 0;
	new_rect->next = 0;
	return new_rect;
}

void(navgen_rectangle *rect) delete_rect = 
{
	// Delete the linked list of cells
	navgen_cell *temp_cell = rect->cells;
	while(temp_cell != 0)
	{
		navgen_cell *temp_cell_next = temp_cell->next;
		remove_cell_from_list(temp_cell, &(rect->cells));
		delete_cell(temp_cell);
		temp_cell = temp_cell_next;
	}

	memfree(rect);
}

void(navgen_rectangle *rect, navgen_rectangle **list_root) add_rect_to_list = 
{
	if(*list_root != 0)
	{
		rect->next = *list_root;
	}
	*list_root = rect;
}

void(navgen_rectangle *rect, navgen_rectangle **list_root) remove_rect_from_list =
{
	if(rect == *list_root)
	{
		*list_root = (*list_root)->next;
		rect->next = 0;
		return;
	}

	navgen_rectangle *prev_rect = *list_root;
	navgen_rectangle *cur_rect = (*list_root)->next;

	while(cur_rect != 0)
	{
		if(cur_rect == rect)
		{
			prev_rect->next = cur_rect->next;
			cur_rect->next = 0;
			return;
		}

		prev_rect = cur_rect;
		cur_rect = cur_rect->next;
	}
}
// ------------------------------------------------------------------------------------------------------



void cl_navgen_phase_rectangle_expansion_start()
{
	// If the lists have any previous nodes, delete them all
	navgen_rectangle *temp_rect;
	navgen_rectangle *temp_rect_next;

	// Empty the list
	temp_rect = navgen_rectangles;

	while(temp_rect != 0)
	{
		temp_rect_next = temp_rect->next;
		remove_rect_from_list(temp_rect, &navgen_rectangles);
		delete_rect(temp_rect);
		temp_rect = temp_rect_next;
	}
}
void cl_navgen_phase_rectangle_expansion_step()
{
	int verbose = 0;
	if(verbose) print("---- Navgen logic tick start ----\n");


	navgen_cell *cell = closed_list_root_node;

	// Iterate through the closed list, building and enlarging rectangles
	while(cell != 0)
	{
		navgen_rectangle *rect = create_rect();
		add_rect_to_list(rect, &navgen_rectangles);

		rect->min = cell;
		rect->max = cell;
		
		remove_cell_from_list(cell, &closed_list_root_node);
		add_cell_to_list(cell, &(rect->cells));

		if(verbose)
		{
			print("\tCreated rectangle at: (",ftos(cell->x),",",ftos(cell->y),",",ftos(cell->z),")\n");
			print("\t\tRectangle bounds: (",ftos((rect->min)->x),",",ftos((rect->min)->y),",",ftos((rect->min)->z),") -> (");
			print(ftos((rect->max)->x),",",ftos((rect->max)->y),",",ftos((rect->max)->z),")\n");
		}

		// Expand the rectangle in each direction as far as possible:
		while(TRUE)
		{
			if(verbose)
			{
				print("\t-- Sweep iteration --\n");
				print("\t\tRectangle bounds: (",ftos((rect->min)->x),",",ftos((rect->min)->y),",",ftos((rect->min)->z),") -> (");
				print(ftos((rect->max)->x),",",ftos((rect->max)->y),",",ftos((rect->max)->z),")\n");
			}

			// Keep track if any side moved on this iteration
			int expanded = FALSE;
			int can_expand;
			navgen_cell *temp_cell;
			navgen_cell *last_temp_cell;

			// ---------------------------------------------------
			// Increasing in +y direction
			// ---------------------------------------------------
			if(verbose) print("\t\t-- Checking +y --\n");
			can_expand = TRUE;
			last_temp_cell = 0;

			// Sweep from top-right to top-left, checking if each node has a y_next neighbor in the closed list
			temp_cell = rect->max;
			// if(verbose) print("\t\tSweeping from ",ftos(temp_cell->x)," to ",ftos((rect->min)->x),"\n");

			while(temp_cell != 0 && temp_cell->x >= (rect->min)->x)
			{
				// If cell doesn't have a y_next neighbor
				if(temp_cell->y_next == 0)
				{
					if(verbose) print("\t\t+y failed. Reason: no neighbor.\n");
					can_expand = FALSE;
					break;
				}
				// If neighbor is not in closed list, then it already belongs to another rectangle
				if(!cell_in_list(temp_cell->y_next, &closed_list_root_node))
				{
					if(verbose) print("\t\t+y failed. Reason: neighbor not in closed list.\n");
					can_expand = FALSE;
					break;
				}
				// If this cell's y_next is not neighbors with the last cell's y_next, then we can't expand
				if(last_temp_cell != 0 && !cells_are_neighbors(temp_cell->y_next, last_temp_cell->y_next))
				{
					if(verbose) print("\t\t+y failed. Reason: Two consecutive y_nexts are not neighbors.\n");
					can_expand = FALSE;
					break;

				}

				last_temp_cell = temp_cell;
				temp_cell = temp_cell->x_prev;
			}
			// if(verbose) print("\t\tFound all neighbors, can_expand: ",ftos(can_expand),"\n");

			// If we got to the edge and found them all, expand the rectangle
			if(can_expand)
			{
				// Sweep again, adding all the nodes to the rect
				temp_cell = rect->max;
				// if(verbose) print("\t\tSweeping from ",ftos(temp_cell->x)," to ",ftos((rect->min)->x),"\n");

				while(temp_cell != 0 && temp_cell->x >= (rect->min)->x)
				{
					remove_cell_from_list(temp_cell->y_next, &closed_list_root_node);
					add_cell_to_list(temp_cell->y_next, &(rect->cells));
					temp_cell = temp_cell->x_prev;
				}

				// Update top-right node
				rect->max = (rect->max)->y_next;
				expanded = TRUE;		
				
				if(verbose) print("\t\tExpanded rectangle at +y\n");
			}
			// ---------------------------------------------------

			// ---------------------------------------------------
			// Increasing in +x direction
			// ---------------------------------------------------
			if(verbose) print("\t\t-- Checking +x --\n");
			can_expand = TRUE;
			last_temp_cell = 0;

			// Sweep from top-right to bottom-right, checking if each node has a x_next neighbor in the closed list
			temp_cell = rect->max;
			while(temp_cell != 0 && temp_cell->y >= (rect->min)->y)
			{
				// If cell doesn't have a x_next neighbor
				if(temp_cell->x_next == 0)
				{
					if(verbose) print("\t\t+x failed. Reason: no neighbor.\n");
					can_expand = FALSE;
					break;
				}
				// If neighbor is not in closed list, then it already belongs to another rectangle
				if(!cell_in_list(temp_cell->x_next, &closed_list_root_node))
				{
					if(verbose) print("\t\t+x failed. Reason: neighbor not in closed list.\n");
					can_expand = FALSE;
					break;
				}
				// If this cell's x_next is not neighbors with the last cell's x_next, then we can't expand
				if(last_temp_cell != 0 && !cells_are_neighbors(temp_cell->x_next, last_temp_cell->x_next))
				{
					if(verbose) print("\t\t+x failed. Reason: Two consecutive x_nexts are not neighbors.\n");
					can_expand = FALSE;
					break;
				}

			    last_temp_cell = temp_cell;
				temp_cell = temp_cell->y_prev;
			}
			// If we got to the edge and found them all, expand the rectangle
			if(can_expand)
			{
				// Sweep again, adding all the nodes to the rect
				temp_cell = rect->max;
				while(temp_cell != 0 && temp_cell->y >= (rect->min)->y)
				{
					remove_cell_from_list(temp_cell->x_next, &closed_list_root_node);
					add_cell_to_list(temp_cell->x_next, &(rect->cells));
					temp_cell = temp_cell->y_prev;
				}

				// Update top-right node
				rect->max = (rect->max)->x_next;
				expanded = TRUE;

				if(verbose) print("\t\tExpanded rectangle at +x\n");
			}
			// ---------------------------------------------------

			// ---------------------------------------------------
			// Increasing in -y direction
			// ---------------------------------------------------
			if(verbose) print("\t\t-- Checking -y --\n");
			can_expand = TRUE;
			last_temp_cell = 0;

			// Sweep from bottom-left to bottom-right, checking if each node has a y_prev neighbor in the closed list
			temp_cell = rect->min;
			while(temp_cell != 0 && temp_cell->x <= (rect->max)->x)
			{
				// If cell doesn't have a y_prev neighbor
				if(temp_cell->y_prev == 0)
				{
					if(verbose) print("\t\t-y failed. Reason: no neighbor.\n");
					can_expand = FALSE;
					break;
				}
				// If neighbor is not in closed list, then it already belongs to another rectangle
				if(!cell_in_list(temp_cell->y_prev, &closed_list_root_node))
				{
					if(verbose) print("\t\t-y failed. Reason: neighbor not in closed list.\n");
					can_expand = FALSE;
					break;
				}
				// If this cell's y_prev is not neighbors with the last cell's y_prev, then we can't expand
				if(last_temp_cell != 0 && !cells_are_neighbors(temp_cell->y_prev, last_temp_cell->y_prev))
				{
					if(verbose) print("\t\t-y failed. Reason: Two consecutive y_prevs are not neighbors.\n");
					can_expand = FALSE;
					break;
				}

				last_temp_cell = temp_cell;
				temp_cell = temp_cell->x_next;
			}
			// If we got to the edge and found them all, expand the rectangle
			if(can_expand)
			{
				// Sweep again, adding all the nodes to the rect
				temp_cell = rect->min;
				while(temp_cell != 0 && temp_cell->x <= (rect->max)->x)
				{
					remove_cell_from_list(temp_cell->y_prev, &closed_list_root_node);
					add_cell_to_list(temp_cell->y_prev, &(rect->cells));
					temp_cell = temp_cell->x_next;
				}

				// Update bottom-left node
				rect->min = (rect->min)->y_prev;
				expanded = TRUE;

				if(verbose) print("\t\tExpanded rectangle at -y\n");
			}
			// ---------------------------------------------------

			// ---------------------------------------------------
			// Increasing in -x direction
			// ---------------------------------------------------
			if(verbose) print("\t\t-- Checking -x --\n");
			can_expand = TRUE;
			last_temp_cell = 0;

			// Sweep from bottom-left to top-left, checking if each node has a x_prev neighbor in the closed list
			temp_cell = rect->min;
			while(temp_cell != 0 && temp_cell->y <= (rect->max)->y)
			{
				// If cell doesn't have a x_prev neighbor
				if(temp_cell->x_prev == 0)
				{
					if(verbose) print("\t\t-x failed. Reason: no neighbor.\n");
					can_expand = FALSE;
					break;
				}
				// If neighbor is not in closed list, then it already belongs to another rectangle
				if(!cell_in_list(temp_cell->x_prev, &closed_list_root_node))
				{
					if(verbose) print("\t\t-x failed. Reason: neighbor not in closed list.\n");
					can_expand = FALSE;
					break;
				}
				// If this cell's x_prev is not neighbors with the last cell's x_prev, then we can't expand
				if(last_temp_cell != 0 && !cells_are_neighbors(temp_cell->x_prev, last_temp_cell->x_prev))
				{
					if(verbose) print("\t\t-x failed. Reason: Two consecutive x_prevs are not neighbors.\n");
					can_expand = FALSE;
					break;
				}

				last_temp_cell = temp_cell;
				temp_cell = temp_cell->y_next;
			}
			// If we got to the edge and found them all, expand the rectangle
			if(can_expand)
			{
				// Sweep again, adding all the nodes to the rect
				temp_cell = rect->min;
				while(temp_cell != 0 && temp_cell->y <= (rect->max)->y)
				{
					remove_cell_from_list(temp_cell->x_prev, &closed_list_root_node);
					add_cell_to_list(temp_cell->x_prev, &(rect->cells));
					temp_cell = temp_cell->y_next;
				}

				// Update bottom-left node
				rect->min = (rect->min)->x_prev;
				expanded = TRUE;

				if(verbose) print("\t\tExpanded rectangle at -x\n");
			}
			// ---------------------------------------------------

			// If we were unable to expand on this iteration, stop
			if(!expanded)
			{
				break;
			}
		}

		// We may have removed several cells from the closed linked list,
		// so pull the next cell from the top of the linked list
		cell = closed_list_root_node;
		// FIXME - remove this
		// Only do 1 rectangle at all
		// navgen_phase = NAVGEN_PHASE_DONE;
		// Only do 1 rectangle per frame
		return;
	}
}
int cl_navgen_phase_rectangle_expansion_finished()
{
	return closed_list_root_node == 0;
}
void cl_navgen_draw_phase_rectangle_expansion()
{
	vector color = [0.2,0.8,0.2];
	float alpha = 0.1;

	navgen_rectangle *rect = navgen_rectangles;

	while(rect != 0)
	{
		// Find 4 corners
		navgen_cell *tl;
		navgen_cell *tr;
		navgen_cell *bl;
		navgen_cell *br;

		tr = rect->max;
		bl = rect->min;

		// Sweep from top right to top left
		tl = rect->max;
		while(tl->x > (rect->min)->x)
		{
			// NOTE - This should NEVER happen. If it does, that means the rectangle
			// NOTE   is malformed, and it'll cause problems elsewhere.
			// NOTE   In case it does happen, catch it and print some details.
			if(tl->x_prev == 0)
			{
				print("WARNING: Failed to draw rectangle. Failed scanning from top right to top left.\n");
				print("\tCell located at: (",ftos(tl->x),",",ftos(tl->y),",",ftos(tl->z),") has no left neighbor.\n");
				print("\tWe were trying to scan all the way to x=",ftos((rect->min)->x),"\n");
				break;
			}

			tl = tl->x_prev;
		}

		// Sweep from bottom left to bottom right
		br = rect->min;
		while(br->x < (rect->max)->x)
		{
			// NOTE - This should NEVER happen. If it does, that means the rectangle
			// NOTE   is malformed, and it'll cause problems elsewhere.
			// NOTE   In case it does happen, catch it and print some details.
			if(br->x_next == 0)
		{
				print("WARNING: Failed to draw rectangle. Failed scanning from bottom left to bottom right.\n");
				print("\tCell located at: (",ftos(br->x),",",ftos(br->y),",",ftos(br->z),") has no right neighbor.\n");
				print("\tWe were trying to scan all the way to x=",ftos((rect->max)->x),"\n");
				break;
			}

			br = br->x_next;
		}

		vector a = [bl->x, bl->y, bl->z];
		vector b = [br->x, br->y, br->z];
		vector c = [tr->x, tr->y, tr->z];
		vector d = [tl->x, tl->y, tl->z];

		cl_navmesh_draw_quad(a,b,c,d,color,alpha,TRUE);


		// // Draw rectangle cells:
		// navgen_cell *cell = rect->cells;

		// while(cell != 0)
		// {
		// 	// cl_navmesh_draw_vert([cell->x, cell->y, cell->z],closed_cell_color,closed_cell_alpha);

		// 	// Draw the neighbors:
		// 	vector pos = [cell->x, cell->y, cell->z];
		// 	// Offset start pos by -8, to show direction
		// 	pos.z -= 8;
		// 	vector neighbor_pos;
		// 	navgen_cell *neighbor;

		// 	if(cell->y_next != 0)
		// 	{
		// 		neighbor = cell->y_next;
		// 		neighbor_pos = [neighbor->x, neighbor->y, neighbor->z];
		// 		cl_navmesh_draw_edge(pos, neighbor_pos);
		// 	}
		// 	if(cell->x_next != 0)
		// 	{
		// 		neighbor = cell->x_next;
		// 		neighbor_pos = [neighbor->x, neighbor->y, neighbor->z];
		// 		cl_navmesh_draw_edge(pos, neighbor_pos);
		// 	}
		// 	if(cell->y_prev != 0)
		// 	{
		// 		neighbor = cell->y_prev;
		// 		neighbor_pos = [neighbor->x, neighbor->y, neighbor->z];
		// 		cl_navmesh_draw_edge(pos, neighbor_pos);
		// 	}
		// 	if(cell->x_prev != 0)
		// 	{
		// 		neighbor = cell->x_prev;
		// 		neighbor_pos = [neighbor->x, neighbor->y, neighbor->z];
		// 		cl_navmesh_draw_edge(pos, neighbor_pos);
		// 	}

		// 	cell = cell->next;
		// }

		rect = rect->next;
	}
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
