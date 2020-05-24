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
// Cell-Rectangle Memberships
struct navgen_cell_rectangle_membership;
void(navgen_cell *cell, navgen_rectangle *rect) remove_cell_from_rectangle;
navgen_cell_rectangle_membership *(navgen_cell *cell, navgen_rectangle *rect) get_membership;
void(navgen_cell *cell, navgen_rectangle *rect) add_cell_to_rectangle;
int(navgen_cell *cell, navgen_rectangle *rect) is_cell_in_rectangle;
void(navgen_rectangle *rect) remove_cells_from_rectangle;
int (navgen_cell *cell1, navgen_cell *cell2) cells_share_membership;
// Data
navgen_rectangle *navgen_rectangles;
navgen_cell *cells_in_rects_list_root_node;
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


	if(navgen_phase == NAVGEN_PHASE_RASTERIZATION)
	{
		cl_navgen_draw_phase_rasterization();
	}
	else if(navgen_phase == NAVGEN_PHASE_RECTANGLE_EXPANSION)
	{
	cl_navgen_draw_phase_rasterization();
	cl_navgen_draw_phase_rectangle_expansion();
	}
	else if(navgen_phase == NAVGEN_PHASE_RECTANGLE_VECTORIZATION)
	{
		cl_navgen_draw_phase_rectangle_expansion();
	cl_navgen_draw_phase_rectangle_vectorization();
}
	else if(navgen_phase == NAVGEN_PHASE_RECTANGLE_TRIANGULATION)
	{
		cl_navgen_draw_phase_rectangle_expansion();
		cl_navgen_draw_phase_rectangle_vectorization();
	}
	else if(navgen_phase == NAVGEN_PHASE_MESH_DETRIANGULATION)
	{
		cl_navgen_draw_phase_rectangle_expansion();
		cl_navgen_draw_phase_rectangle_vectorization();
	}
	else if(navgen_phase == NAVGEN_PHASE_DONE)
	{
		cl_navgen_draw_phase_rectangle_expansion();
		cl_navgen_draw_phase_rectangle_vectorization();
	}

	// All draw methods
	// cl_navgen_draw_phase_rasterization();
	// cl_navgen_draw_phase_rectangle_expansion();
	// cl_navgen_draw_phase_rectangle_vectorization();
	// cl_navgen_draw_phase_rectangle_triangulation();
	// cl_navgen_draw_phase_mesh_detriangulation();
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

	// Pointer to a linked list of which rectangles this cell belongs to
	navgen_cell_rectangle_membership *rect_memberships;
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
	new_cell->rect_memberships = 0;

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
	// if(verbose) print("---- Navgen logic tick start ----\n");

	navgen_cell *cur_open_list = open_list_root_node;
	navgen_cell *new_open_list = 0;

	navgen_cell *cell = cur_open_list;

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
	navgen_cell_rectangle_membership *cells;

	// List of cells to treat as vertices
	navgen_cell *verts;

	// Linked list node
	navgen_rectangle *next;

};

navgen_rectangle *() create_rect = 
{
	navgen_rectangle *new_rect = memalloc(sizeof(navgen_rectangle));
	new_rect->min = 0;
	new_rect->max = 0;
	new_rect->next = 0;
	new_rect->cells = 0;
	new_rect->verts = 0;
	new_rect->next = 0;
	return new_rect;
}

void(navgen_rectangle *rect) delete_rect = 
{
	navgen_cell *temp_cell;
	navgen_cell *temp_cell_next;

	// Remove cell memberships
	remove_cells_from_rectangle(rect);

	// // Delete the linked list of cells
	// temp_cell = rect->cells;
	// while(temp_cell != 0)
	// {
	// 	temp_cell_next = temp_cell->next;
	// 	remove_cell_from_list(temp_cell, &(rect->cells));
	// 	delete_cell(temp_cell);
	// 	temp_cell = temp_cell_next;
	// }

	// Delete the linked list of cell vertices
	temp_cell = rect->verts;
	while(temp_cell != 0)
	{
		temp_cell_next = temp_cell->next;
		remove_cell_from_list(temp_cell, &(rect->verts));
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

navgen_cell *(navgen_rectangle *rect) get_top_left_cell = 
{
	// Sweep from top right to top left
	navgen_cell *tl = rect->max;

	while(tl->x > (rect->min)->x)
	{
		// NOTE - This should NEVER happen. If it does, that means the rectangle
		// NOTE   is malformed, and it'll cause problems elsewhere.
		// NOTE   In case it does happen, catch it and print some details.
		if(tl->x_prev == 0)
		{
			print("WARNING: Failed to get rectangle's top left cell. Failed scanning from top right to top left.\n");
			print("\tCell located at: (",ftos(tl->x),",",ftos(tl->y),",",ftos(tl->z),") has no left neighbor.\n");
			print("\tWe were trying to scan all the way to x=",ftos((rect->min)->x),"\n");
			break;
		}

		tl = tl->x_prev;
	}
	return tl;
}

navgen_cell *(navgen_rectangle *rect) get_bottom_right_cell = 
{
	// Sweep from bottom left to bottom right
	navgen_cell *br = rect->min;

	while(br->x < (rect->max)->x)
	{
		// NOTE - This should NEVER happen. If it does, that means the rectangle
		// NOTE   is malformed, and it'll cause problems elsewhere.
		// NOTE   In case it does happen, catch it and print some details.
		if(br->x_next == 0)
		{
			print("WARNING: Failed to get rectangle's bottom right cell. Failed scanning from bottom left to bottom right.\n");
			print("\tCell located at: (",ftos(br->x),",",ftos(br->y),",",ftos(br->z),") has no right neighbor.\n");
			print("\tWe were trying to scan all the way to x=",ftos((rect->max)->x),"\n");
			break;
		}

		br = br->x_next;
	}
	return br;
}

struct navgen_cell_rectangle_membership
{
	// The cell that has membership to a rectangle
	navgen_cell *cell;
	// The rectangle that the cell has membership in
	navgen_rectangle *rect;

	// Linked list node for cells (a cell traverses its memberships via this linked list)
	navgen_cell_rectangle_membership *cell_next_membership;
	// Linked list node for rects (a rect traverses its member cells via this linked list) 
	navgen_cell_rectangle_membership *rect_next_membership;
};


void(navgen_cell *cell, navgen_rectangle *rect) add_cell_to_rectangle =
{
	if(is_cell_in_rectangle(cell, rect))
		return;

	navgen_cell_rectangle_membership *new_membership = memalloc(sizeof(navgen_cell_rectangle_membership));

	new_membership->rect = rect;
	new_membership->cell = cell;

	// Link it into the vert
	new_membership->cell_next_membership = cell->rect_memberships;
	cell->rect_memberships = new_membership;

	// Link it into the rect
	new_membership->rect_next_membership = rect->cells;
	rect->cells = new_membership;
}

navgen_cell_rectangle_membership *(navgen_cell *cell, navgen_rectangle *rect) get_membership =
{
	navgen_cell_rectangle_membership *membership;
	// Traverse the cell's list to find the membership
	// (A cell should belong to fewer rects, so this should be faster)
	membership = cell->rect_memberships;
	while(membership != 0)
	{
		if(membership->rect == rect)
		{
			return membership;
		}
		membership = membership->cell_next_membership;
	}

	return 0;
}

void(navgen_cell *cell, navgen_rectangle *rect) remove_cell_from_rectangle =
{
	navgen_cell_rectangle_membership *membership = get_membership(cell, rect);

	if(membership == 0)
		return;

	navgen_cell_rectangle_membership **prev_cell_membership = &(cell->rect_memberships);
	navgen_cell_rectangle_membership **prev_rect_membership = &(rect->cells);

	while(*prev_cell_membership != membership)
	{
		prev_cell_membership = &((*prev_cell_membership)->cell_next_membership);
		}


	while(*prev_rect_membership != membership)
	{
		prev_rect_membership = &((*prev_rect_membership)->rect_next_membership);
		}

	// Unlink it
	*prev_cell_membership = membership->cell_next_membership;
	*prev_rect_membership = membership->rect_next_membership;
	
	memfree(membership);
}

int(navgen_cell *cell, navgen_rectangle *rect) is_cell_in_rectangle =
{
	return get_membership(cell, rect) != 0;
}

void(navgen_rectangle *rect) remove_cells_from_rectangle =
{
	while(rect->cells != 0)
	{
		navgen_cell_rectangle_membership *membership = rect->cells;
		remove_cell_from_rectangle(membership->cell, rect);
	}
}

// Returns TRUE if cell1 and cell2 share membership in at least rectangle
int (navgen_cell *cell1, navgen_cell *cell2) cells_share_membership =
{
	navgen_cell_rectangle_membership *membership = cell1->rect_memberships;
	while(membership != 0)
	{
		if(is_cell_in_rectangle(cell2, membership->rect))
			return TRUE;
		membership = membership->cell_next_membership;
	}
	return FALSE;
}

// Computes the area of intersecting the rectangle with mins 'r1_min' and maxs 'r1_max', 
// with the rectangle with mins 'r2_min' and maxs 'r2_max'
float (navgen_cell *r1_min, navgen_cell *r1_max, navgen_cell *r2_min, navgen_cell *r2_max) area_of_intersection =
{
	vector r1_min_pos = [r1_min->x, r1_min->y, r1_min->z];
	vector r1_max_pos = [r1_max->x, r1_max->y, r1_max->z];
	vector r2_min_pos = [r2_min->x, r2_min->y, r2_min->z];
	vector r2_max_pos = [r2_max->x, r2_max->y, r2_max->z];

	if(r1_min_pos.x > r2_max_pos.x)
		return 0;
	if(r1_max_pos.x < r2_min_pos.x)
		return 0;
	if(r1_min_pos.y > r2_max_pos.y)
		return 0;
	if(r1_max_pos.y < r2_min_pos.y)
		return 0;

	float width  = min(r1_max_pos.x - r2_min_pos.x, r2_max_pos.x - r1_min_pos.x);
	float height = min(r1_max_pos.y - r2_min_pos.y, r2_max_pos.y - r1_min_pos.y);
	return width * height;
}

// Returns TRUE if rectangle formed by min & max intersects with any rectangles in list 'rectangles'
// If 'skip' is specified, we don't check against that rectangle.
// Returns FALSE if it does not intersect.
int intersects_with_rectangles(navgen_cell *min, navgen_cell *max, navgen_rectangle *rect_list, navgen_rectangle *skip)
{
	navgen_rectangle *rect;

	for(rect = rect_list; rect != 0; rect = rect->next)
	{
		if(rect == skip)
			continue;

		navgen_cell *other_min = rect->min;
		navgen_cell *other_max = rect->max;

		if(area_of_intersection(min,max,other_min,other_max) > 0)
			return TRUE;
	}

	return FALSE;
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

	navgen_cell *temp_cell;
	navgen_cell *temp_cell_next;
	
	// Empty the list of cells added to rectangles
	temp_cell = cells_in_rects_list_root_node;
	while(temp_cell != 0)
	{
		temp_cell_next = temp_cell->next;
		remove_cell_from_list(temp_cell, &cells_in_rects_list_root_node);
		temp_cell = temp_cell_next;
	}

}


void cl_navgen_phase_rectangle_expansion_step()
{
	int verbose = 0;


	navgen_cell *cell = closed_list_root_node;

	// Iterate through the closed list, building and enlarging rectangles
	while(cell != 0)
	{
		navgen_rectangle *rect = create_rect();
		add_rect_to_list(rect, &navgen_rectangles);

		rect->min = cell;
		rect->max = cell;
		
		remove_cell_from_list(cell, &closed_list_root_node);
		add_cell_to_list(cell, &cells_in_rects_list_root_node);
		add_cell_to_rectangle(cell, rect);

		if(verbose)
		{
			print("Created rectangle at: (",ftos(cell->x),",",ftos(cell->y),",",ftos(cell->z),")\n");
			print("\tRectangle bounds: (",ftos((rect->min)->x),",",ftos((rect->min)->y),",",ftos((rect->min)->z),") -> (");
			print(ftos((rect->max)->x),",",ftos((rect->max)->y),",",ftos((rect->max)->z),")\n");
		}

		// Keep track of which edge can no longer be expanded
		int top_can_expand = TRUE;
		int right_can_expand = TRUE;
		int bottom_can_expand = TRUE;
		int left_can_expand = TRUE;

		// Expand the rectangle in each direction as far as possible:
		while(TRUE)
		{
			if(verbose)
			{
				print("\tRectangle bounds: (",ftos((rect->min)->x),",",ftos((rect->min)->y),",",ftos((rect->min)->z),") -> (");
				print(ftos((rect->max)->x),",",ftos((rect->max)->y),",",ftos((rect->max)->z),")\n");
			}

			// Keep track if any side moved on this iteration
			navgen_cell *temp_cell;
			navgen_cell *last_neighbor;

			navgen_cell *temp_min;
			navgen_cell *temp_max;

			// ---------------------------------------------------
			// Increasing in +y direction
			// ---------------------------------------------------
			if(top_can_expand)
			{
				if(verbose) print("\t\t-- Checking +y --\n");
				// ----------------------------------------------------------------------
				// Check if the map geometry allows us to expand
				// ----------------------------------------------------------------------
				last_neighbor = 0;
				// Sweep from top-right to top-left, checking if each node has a valid y_next neighbor
				for(temp_cell = rect->max; temp_cell != 0 && temp_cell->x >= (rect->min)->x; temp_cell = temp_cell->x_prev)
				{
					// If cell doesn't have a y_next neighbor
					if(temp_cell->y_next == 0)
					{
						if(verbose) print("\t\t+y failed. Reason: no neighbor.\n");
						top_can_expand = FALSE;
						break;
					}
					// If this cell's y_next is not neighbors with the last cell's y_next, then we can't expand
					if(last_neighbor != 0 && !cells_are_neighbors(temp_cell->y_next, last_neighbor))
					{
						if(verbose) print("\t\t+y failed. Reason: Two consecutive y_nexts are not neighbors.\n");
						top_can_expand = FALSE;
						break;
					}
					last_neighbor = temp_cell->y_next;					
				}
				// ----------------------------------------------------------------------
				// Check if we are expanding into another rectangle
				// ----------------------------------------------------------------------
				if(top_can_expand)
				{
					temp_min = rect->min;
					temp_max = (rect->max)->y_next;

					if(intersects_with_rectangles(temp_min, temp_max, navgen_rectangles, rect))
					{
						top_can_expand = FALSE;
					}
				}
				// ----------------------------------------------------------------------
				// If we got to the edge and found them all, expand the rectangle
				// ----------------------------------------------------------------------
				if(top_can_expand)
				{
					// Sweep again, adding all the nodes to the rect
					for(temp_cell = rect->max; temp_cell != 0 && temp_cell->x >= (rect->min)->x; temp_cell = temp_cell->x_prev)
					{
						if(cell_in_list(temp_cell->y_next, &closed_list_root_node))
						{
							remove_cell_from_list(temp_cell->y_next, &closed_list_root_node);
							add_cell_to_list(temp_cell->y_next, &cells_in_rects_list_root_node);
						}
						add_cell_to_rectangle(temp_cell->y_next, rect);
					}

					// Update top-right node
					rect->max = (rect->max)->y_next;		
					if(verbose) print("\t\tExpanded rectangle at +y\n");
				}
			}
			// ---------------------------------------------------

			// ---------------------------------------------------
			// Increasing in +x direction
			// ---------------------------------------------------
			if(right_can_expand)
			{
				if(verbose) print("\t\t-- Checking +x --\n");
			    // ----------------------------------------------------------------------
				// Checking if the map geometry allows us to expand
				// ----------------------------------------------------------------------
				last_neighbor = 0;
                // Sweep from top-right to bottom-right, checking if each node has a valid x_next neighbor
				for(temp_cell = rect->max; temp_cell != 0 && temp_cell->y >= (rect->min)->y; temp_cell = temp_cell->y_prev)
				{
					// If cell doesn't have a x_next neighbor
					if(temp_cell->x_next == 0)
					{
						if(verbose) print("\t\t+x failed. Reason: no neighbor.\n");
						right_can_expand = FALSE;
						break;
					}
					// If this cell's x_next is not neighbors with the last cell's x_next, then we can't expand
						if(last_neighbor != 0 && !cells_are_neighbors(temp_cell->x_next, last_neighbor))
					{
						if(verbose) print("\t\t+x failed. Reason: Two consecutive x_nexts are not neighbors.\n");
						right_can_expand = FALSE;
						break;
					}
					last_neighbor = temp_cell->x_next;
				}
				// ----------------------------------------------------------------------
				// Checking if we are expanding into another rectangle
				// ----------------------------------------------------------------------
				if(right_can_expand)
				{
					temp_min = rect->min;
					temp_max = (rect->max)->x_next;

					if(intersects_with_rectangles(temp_min, temp_max, navgen_rectangles, rect))
					{
						right_can_expand = FALSE;
					}
				}
				// ----------------------------------------------------------------------
				// If we got to the edge and found them all, expand the rectangle
				// ----------------------------------------------------------------------
				if(right_can_expand)
				{
					for(temp_cell = rect->max; temp_cell != 0 && temp_cell->y >= (rect->min)->y; temp_cell = temp_cell->y_prev)
					{		
						if(cell_in_list(temp_cell->x_next, &closed_list_root_node))
						{
							remove_cell_from_list(temp_cell->x_next, &closed_list_root_node);
							add_cell_to_list(temp_cell->x_next, &cells_in_rects_list_root_node);
						}
						add_cell_to_rectangle(temp_cell->x_next, rect);
					}

					// Update top-right node
					rect->max = (rect->max)->x_next;
					if(verbose) print("\t\tExpanded rectangle at +x\n");
				}
			}
			// ---------------------------------------------------

			// ---------------------------------------------------
			// Increasing in -y direction
			// ---------------------------------------------------
			if(bottom_can_expand)
			{
				if(verbose) print("\t\t-- Checking -y --\n");
				// ----------------------------------------------------------------------
				// Checking if the map geometry allows us to expand
				// ----------------------------------------------------------------------
				last_neighbor = 0;
				// Sweep from bottom-left to bottom-right, checking if each node has a valid y_prev neighbor
				for(temp_cell = rect->min; temp_cell != 0 && temp_cell->x <= (rect->max)->x; temp_cell = temp_cell->x_next)
				{
					// If cell doesn't have a y_prev neighbor
					if(temp_cell->y_prev == 0)
					{
						if(verbose) print("\t\t-y failed. Reason: no neighbor.\n");
						bottom_can_expand = FALSE;
						break;
					}
					// If this cell's y_prev is not neighbors with the last cell's y_prev, then we can't expand
					if(last_neighbor != 0 && !cells_are_neighbors(temp_cell->y_prev, last_neighbor))
					{
						if(verbose) print("\t\t-y failed. Reason: Two consecutive y_prevs are not neighbors.\n");
						bottom_can_expand = FALSE;
						break;
					}
					last_neighbor = temp_cell->y_prev;
				}
				// ----------------------------------------------------------------------
				// Checking if we are expanding into another rectangle
				// ----------------------------------------------------------------------
				if(bottom_can_expand)
				{
					temp_min = (rect->min)->y_prev;
					temp_max = rect->max;

					if(intersects_with_rectangles(temp_min, temp_max, navgen_rectangles, rect))
					{
						bottom_can_expand = FALSE;
					}
				}
				// ----------------------------------------------------------------------
				// If we got to the edge and found them all, expand the rectangle
				// ----------------------------------------------------------------------
				if(bottom_can_expand)
				{
					// Sweep again, adding all the nodes to the rect
					for(temp_cell = rect->min; temp_cell != 0 && temp_cell->x <= (rect->max)->x; temp_cell = temp_cell->x_next)
					{
						if(cell_in_list(temp_cell->y_prev, &closed_list_root_node))
						{
							remove_cell_from_list(temp_cell->y_prev, &closed_list_root_node);
							add_cell_to_list(temp_cell->y_prev, &cells_in_rects_list_root_node);
						}
						add_cell_to_rectangle(temp_cell->y_prev, rect);
					}

					// Update bottom-left node
					rect->min = (rect->min)->y_prev;
					if(verbose) print("\t\tExpanded rectangle at -y\n");
				}
			}
			// ---------------------------------------------------

			// ---------------------------------------------------
			// Increasing in -x direction
			// ---------------------------------------------------
			if(left_can_expand)
			{
				if(verbose) print("\t\t-- Checking -x --\n");
				// ----------------------------------------------------------------------
				// Checking if the map geometry allows us to expand
				// ----------------------------------------------------------------------
				last_neighbor = 0;
				// Sweep from bottom-left to top-left, checking if each node has a valid x_prev neighbor
				for(temp_cell = rect->min; temp_cell != 0 && temp_cell->y <= (rect->max)->y; temp_cell = temp_cell->y_next)
				{
					// If cell doesn't have a x_prev neighbor
					if(temp_cell->x_prev == 0)
					{
						if(verbose) print("\t\t-x failed. Reason: no neighbor.\n");
						left_can_expand = FALSE;
						break;
					}
					// If this cell's x_prev is not neighbors with the last cell's x_prev, then we can't expand
					if(last_neighbor != 0 && !cells_are_neighbors(temp_cell->x_prev, last_neighbor))
					{
						if(verbose) print("\t\t-x failed. Reason: Two consecutive x_prevs are not neighbors.\n");
						left_can_expand = FALSE;
						break;
					}
						last_neighbor = temp_cell->x_prev;
				}
				// ----------------------------------------------------------------------
				// Checking if we are expanding into another rectangle
				// ----------------------------------------------------------------------
				if(left_can_expand)
				{
					temp_min = (rect->min)->x_prev;
					temp_max = rect->max;

					if(intersects_with_rectangles(temp_min, temp_max, navgen_rectangles, rect))
					{
						left_can_expand = FALSE;
					}
				}
				// ----------------------------------------------------------------------
				// If we got to the edge and found them all, expand the rectangle
				// ----------------------------------------------------------------------
				if(left_can_expand)
				{
					// Sweep again, adding all the nodes to the rect
					for(temp_cell = rect->min; temp_cell != 0 && temp_cell->y <= (rect->max)->y; temp_cell = temp_cell->y_next)
					{
						if(cell_in_list(temp_cell->x_prev, &closed_list_root_node))
						{
							remove_cell_from_list(temp_cell->x_prev, &closed_list_root_node);
							add_cell_to_list(temp_cell->x_prev, &cells_in_rects_list_root_node);
						}
						add_cell_to_rectangle(temp_cell->x_prev, rect);
					}

					// Update bottom-left node
					rect->min = (rect->min)->x_prev;
					if(verbose) print("\t\tExpanded rectangle at -x\n");
				}
			}
			// ---------------------------------------------------

			// If this rectangle can no longer expand in any direction, stop
			if(!top_can_expand && !right_can_expand && !bottom_can_expand && !left_can_expand)
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
		// Get 4 corners
		navgen_cell *tr = rect->max;
		navgen_cell *tl = get_top_left_cell(rect);
		navgen_cell *bl = rect->min;
		navgen_cell *br = get_bottom_right_cell(rect);

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


	// // ------------------------------------------------------------------------
	// // Draw all of the cells that belong to a rectangle
	// // ------------------------------------------------------------------------
	// vector cell_in_rect_color = [0.8,0.8,0.2];
	// float cell_in_rect_alpha = 0.1;
	
	// navgen_cell *cell = cells_in_rects_list_root_node;

	// while(cell != 0)
	// {
	// 	if(cell->rect_memberships != 0)
	// 		cl_navmesh_draw_vert([cell->x, cell->y, cell->z],cell_in_rect_color,cell_in_rect_alpha);
	// 	cell = cell->next;
	// }

}
// ===========================================================================================================
// NAVGEN_PHASE_RECTANGLE_VECTORIZATION
// ===========================================================================================================
void cl_navgen_phase_rectangle_vectorization_start()
{
	// Delete all rectangle vertices
	navgen_rectangle *rect = navgen_rectangles;

	while(rect != 0)
	{
		navgen_cell *vert = rect->verts;
		navgen_cell *vert_next;

		while(vert != 0)
		{
			vert_next = vert->next;
			remove_cell_from_list(vert, &(rect->verts));
			delete_cell(vert);

			vert = vert_next;
}

		rect = rect->next;
	}
}
void cl_navgen_phase_rectangle_vectorization_step()
{
	navgen_rectangle *rect1;
	navgen_rectangle *rect2;

	for(rect1 = navgen_rectangles; rect1 != 0; rect1 = rect1->next)
	{
		// Add the four corners of rect1 to rect1's list of verts
		navgen_cell *tr = rect1->max;
		navgen_cell *br = get_bottom_right_cell(rect1);
		navgen_cell *bl = rect1->min;
		navgen_cell *tl = get_top_left_cell(rect1);

		// Create a cell vert for each of these corners
		navgen_cell *tr_vert = create_cell(tr->x, tr->y, tr->z);
		navgen_cell *br_vert = create_cell(br->x, br->y, br->z);
		navgen_cell *bl_vert = create_cell(bl->x, bl->y, bl->z);
		navgen_cell *tl_vert = create_cell(tl->x, tl->y, tl->z);

		// Add these four cell verts to rect1's list of verts
		add_cell_to_list(tr_vert, &(rect1->verts));
		add_cell_to_list(br_vert, &(rect1->verts));
		add_cell_to_list(bl_vert, &(rect1->verts));
		add_cell_to_list(tl_vert, &(rect1->verts));

		for(rect2 = navgen_rectangles; rect2 != 0; rect2 = rect2->next)
		{
			if(rect1 == rect2)
				continue;

			// Check if the rectangles are neighbors

			// Easy early-out test, Check if the mins / maxs of the rectangles are within 2 cells of each other
			// If they're not, then it's impossible for these rectangles to be neighbors
			vector r1_min_pos = [(rect1->min)->x, (rect1->min)->y, (rect1->min)->z];
			vector r1_max_pos = [(rect1->max)->x, (rect1->max)->y, (rect1->max)->z];
			vector r2_min_pos = [(rect2->min)->x, (rect2->min)->y, (rect2->min)->z];
			vector r2_max_pos = [(rect2->max)->x, (rect2->max)->y, (rect2->max)->z];

			if(r1_min_pos.x > r2_max_pos.x + 2 * navgen_cell_size)
				continue;
			if(r1_max_pos.x < r2_min_pos.x - 2 * navgen_cell_size)
				continue;
			if(r1_min_pos.y > r2_max_pos.y + 2 * navgen_cell_size)
				continue;
			if(r1_max_pos.y < r2_min_pos.y - 2 * navgen_cell_size)
				continue;


			// At this point... the rectangles are close enough that they _might_ be neighbors
			navgen_cell *r1_cell;
			navgen_cell *r2_cell;
			navgen_cell *first_shared_cell = 0;
			navgen_cell *last_shared_cell = 0;

			// ---------------------------------------------------------------------
			// Check rect1's top edge
			// ---------------------------------------------------------------------
			// Only check this if we don't have a shared edge
			// (NOTE: This is always true for the top edge check, but the rest of the edges have it, so keep it.)
			if(first_shared_cell == 0 || last_shared_cell != first_shared_cell)
			{
				// Sweep rect1's top edge from top right to top left
				for(r1_cell = rect1->max; TRUE; r1_cell = r1_cell->x_prev)
				{
					// Sweep rect2's bottom edge from bottom left to bottom right
					for(r2_cell = rect2->min; TRUE; r2_cell = r2_cell->x_next)
					{
						if(cells_are_neighbors(r1_cell, r2_cell))
						{
							first_shared_cell = first_shared_cell == 0 ? r1_cell : first_shared_cell;
							last_shared_cell = r1_cell;
						}
						if(r2_cell->x == (rect2->max)->x) break;
					}
					if(r1_cell->x == (rect1->min)->x) break;
				}
			}

			// ---------------------------------------------------------------------
			// Check rect1's right edge
			// ---------------------------------------------------------------------
			// Only check this if we don't have a shared edge
			if(first_shared_cell == 0 || last_shared_cell != first_shared_cell)
			{
				// Sweep rect1's right edge from top right to bottom right
				for(r1_cell = rect1->max; TRUE; r1_cell = r1_cell->y_prev)
				{
					// Sweep rect2's left edge from bottom left to top left
					for(r2_cell = rect2->min; TRUE; r2_cell = r2_cell->y_next)
					{
						if(cells_are_neighbors(r1_cell, r2_cell))
						{
							first_shared_cell = first_shared_cell == 0 ? r1_cell : first_shared_cell;
							last_shared_cell = r1_cell;
						}
						if(r2_cell->y == (rect2->max)->y) break;
					}
					if(r1_cell->y == (rect1->min)->y) break;
				}
			}

			// ---------------------------------------------------------------------
			// Check rect1's bottom edge
			// ---------------------------------------------------------------------
			// Only check this if we don't have a shared edge
			if(first_shared_cell == 0 || last_shared_cell != first_shared_cell)
			{
				// Sweep rect1's bottom edge from bottom left to bottom right
				for(r1_cell = rect1->min; TRUE; r1_cell = r1_cell->x_next)
				{
					// Sweep rect2's top edge from top right to top left
					for(r2_cell = rect2->max; TRUE; r2_cell = r2_cell->x_prev)
					{
						if(cells_are_neighbors(r1_cell, r2_cell))
						{
							first_shared_cell = first_shared_cell == 0 ? r1_cell : first_shared_cell;
							last_shared_cell = r1_cell;
						}
						if(r2_cell->x == (rect2->min)->x) break;
					}
					if(r1_cell->x == (rect1->max)->x) break;
				}
			}

			// ---------------------------------------------------------------------
			// Check rect1's left edge
			// ---------------------------------------------------------------------
			// Only check this if we don't have a shared edge
			if(first_shared_cell == 0 || last_shared_cell != first_shared_cell)
			{
				// Sweep rect1's left edge from bottom left to top left
				for(r1_cell = rect1->min; TRUE; r1_cell = r1_cell->y_next)
				{
					// Sweep rect2's right edge from top right to bottom right
					for(r2_cell = rect2->max; TRUE; r2_cell = r2_cell->y_prev)
					{
						if(cells_are_neighbors(r1_cell, r2_cell))
						{
							first_shared_cell = first_shared_cell == 0 ? r1_cell : first_shared_cell;
							last_shared_cell = r1_cell;
						}
						if(r2_cell->y == (rect2->min)->y) break;
					}
					if(r1_cell->y == (rect1->max)->y) break;
				}
			}

			// ---------------------------------------------------------------------

			if(first_shared_cell != 0)
			{
				// A single cell does not an edge make
				if(first_shared_cell != last_shared_cell)
				{
					navgen_cell *first_cell_vert;
					navgen_cell *last_cell_vert;

					// Create a cell vert for these two points
					first_cell_vert = create_cell(first_shared_cell->x, first_shared_cell->y, first_shared_cell->z);
					last_cell_vert = create_cell(last_shared_cell->x, last_shared_cell->y, last_shared_cell->z);
		
					// Add these two cell verts to rect1's list of verts
					add_cell_to_list(first_cell_vert, &(rect1->verts));
					add_cell_to_list(last_cell_vert, &(rect1->verts));
				}
			}	
		}
	}
}
int cl_navgen_phase_rectangle_vectorization_finished()
{
	// rectangle vectorization finishes in a single function call, so just return TRUE here
	return TRUE;
}
void cl_navgen_draw_phase_rectangle_vectorization()
{
	vector rect_vert_color = [0,0,1];
	float rect_vert_alpha = 0.5;

	navgen_rectangle *rect = navgen_rectangles;

	while(rect != 0)
	{
		// Draw all of the rect's vertex cells
		navgen_cell *vert = rect->verts;

		while(vert != 0)
		{
			cl_navmesh_draw_vert([vert->x, vert->y, vert->z],rect_vert_color,rect_vert_alpha);
			vert = vert->next;
		}

		rect = rect->next;
	}
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
