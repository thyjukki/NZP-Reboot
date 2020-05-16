
//============================================================================================================
//TEMP REMOVE THIS ( this is for testing walk methods between two problematic points )
float debug_specific_walk = 0;
float debug_walk_printed;


//Vector assignment function, because fteqcc seems to have a broken vec1 = vec2; implementation (works only sometimes)
//Functionally equivalent to saying (*a)=b;
void vec_eq(vector* a, vector b)
{
	a[0][0]=b[0];
	a[0][1]=b[1];
	a[0][2]=b[2];
}

// TODO - NavmeshGen - 2020
// TODO - Create a struct that holds an ENTIRE navmesh, including methods for allocating one, copying one, freeing one.
// TODO   At each step, we should run checks on the entire mesh to ensure the invariants remain intact
// TODO   Then, when a new modification is to be committed to the navmesh, we create a new temporary navmesh with the modification
// TODO   check the invariants, take a backup of the current navmesh, and commit the change (this should increment the version number)

// TODO - When checking walkability from one position to another, consider doing 4 additional checks at corners of a bbox of width: 2*epsilon, height: 2*epislon
// TODO   if some of these fail, then we know we are near an obstruction (a wall, or a ledge)
// TODO   but what should we do with this info?

// TODO - Need to map out and design what the end state for navmesh generation is
// TODO - Need to step through how the strange edge-case in NZP's NDU (by the m1a1 wallbuy) is handled.
// TODO - Need to decide how to detect and what to do when the navmesh intersects itself.
// TODO - Need to decide how to handle ledge-dropping. (I think we decided to not handle them, and let the mapper define where zombies can drop and/or climb up)

//==========================================================================================
//			Temporary Structs Used for Navmesh Generation
//==========================================================================================

//For vertices, we're going to use a doubley linked list, with references to left / right vertices
//There's going to be a lot of insertion / deletion, linked list is ideal for this
struct navgen_vertex
{
	vector pos;
	//Pointer to prev navgen_vertex in global linked list
	navgen_vertex* prev;
	//Pointer to next navgen_vertex in global linked list
	navgen_vertex* next;

	//Vertex's left edge
	navgen_vertex* left;
	//Vertex's right edge
	navgen_vertex* right;

	//Temp debug field
	float id;
};

// This struct contains an entire mesh
// struct navgen_mesh
// {
// 	// TODO
// };

float verts_ids;

//Root node in linked list, where all insertions occur at
navgen_vertex* navgen_verts_root;

//Allocates a new vertex and inserts it into the linked list at root
navgen_vertex* cl_navgen_new_vert(vector pos)
{
	navgen_vertex* new_vert = memalloc(sizeof(navgen_vertex));

	vec_eq(&(new_vert->pos),pos);

	new_vert->left = 0;
	new_vert->right = 0;
	new_vert->next = navgen_verts_root;
	if(navgen_verts_root)
	{
		navgen_verts_root->prev= new_vert;
	}
	new_vert->prev = 0;
	navgen_verts_root = new_vert;

	//fixme: for debug
	new_vert->id = verts_ids++;
	return new_vert;
}

//FOR DEBUG
#define MAX_DEBUG_HULL_COUNT 200
vector debug_hulls[MAX_DEBUG_HULL_COUNT];
vector debug_hull_scales[MAX_DEBUG_HULL_COUNT];
vector debug_hull_colors[MAX_DEBUG_HULL_COUNT];
float debug_hull_alphas[MAX_DEBUG_HULL_COUNT];

float debug_hull_count;

void add_debug_hull(vector pos, vector scale, vector color, float alpha)
{
	//if(debug_hull_count >= MAX_DEBUG_HULL_COUNT)
	//	return;
	debug_hulls[debug_hull_count % MAX_DEBUG_HULL_COUNT] = pos;
	debug_hull_scales[debug_hull_count % MAX_DEBUG_HULL_COUNT] = scale;
	debug_hull_colors[debug_hull_count % MAX_DEBUG_HULL_COUNT] = color;
	debug_hull_alphas[debug_hull_count++ % MAX_DEBUG_HULL_COUNT] = alpha;
}

void clear_debug_hulls()
{
	debug_hull_count = 0;
}

//Removes and frees a vertex from the global vertex linked list
//This does not handle updating left/right vertex references, that depends on how / why we are deleting this vertex
void cl_navgen_free_vert(navgen_vertex* vert)
{
	if(!vert)
	{
		print("Warning: tried freeing a null vertex.\n");
		return;
	}

	if(vert->prev)
		(vert->prev)->next = vert->next;
	if(vert->next)
		(vert->next)->prev = vert->prev;

	//If this vert is root, update root
	if(navgen_verts_root == vert)
		navgen_verts_root = vert->next;

	memfree((navgen_vertex*) vert);
}

void cl_navgen_free_all_verts()
{
	navgen_vertex* vert = navgen_verts_root;
	print("Allocated verts: ",ftos(verts_ids),"\n");
	while(vert)
	{
		print("\tfreeing vert: ",ftos(vert->id),"\n");
		cl_navgen_free_vert(vert);
		vert = navgen_verts_root;
	}

	debug_hull_count = 0;
}


void cl_navmesh_render_vert(navgen_vertex* vert)
{
	cl_navmesh_draw_vert(vert->pos,[0,0,1],0.4);
}


void cl_navmesh_render_point(vector pos,vector color, float alpha)
{
	cl_navmesh_draw_vert(pos,color,alpha);
}

void cl_navmesh_render_edge(navgen_vertex* from, navgen_vertex* to)
{
	cl_navmesh_draw_edge(from->pos, to->pos);
}



vector debug_lines_pos1[200];
vector debug_lines_pos2[200];
vector debug_lines_color[200];
float debug_lines_count;


void add_debug_line(vector p1, vector p2, vector color)
{
	if(debug_lines_count >= 200)
		return;

	debug_lines_pos1[debug_lines_count] = p1;
	debug_lines_pos2[debug_lines_count] = p2;
	debug_lines_color[debug_lines_count++] = color;
}
void clear_debug_lines()
{
	debug_lines_count = 0;
}

//Adds lines from corners of a regular hull
void add_debug_hull_line(vector p1, vector p2, vector color)
{
	//min
	vector ofs;
	vec_eq(&ofs,[VEC_HULL_MIN_x, VEC_HULL_MIN_y,0]);
	add_debug_line(p1 + ofs, p2 + ofs, color);

	//min max
	vec_eq(&ofs,[VEC_HULL_MIN_x, VEC_HULL_MAX_y,0]);
	add_debug_line(p1 + ofs, p2 + ofs, color);

	//max min
	vec_eq(&ofs,[VEC_HULL_MAX_x, VEC_HULL_MIN_y,0]);
	add_debug_line(p1 + ofs, p2 + ofs, color);

	//max max
	vec_eq(&ofs,[VEC_HULL_MAX_x, VEC_HULL_MAX_y,0]);
	add_debug_line(p1 + ofs, p2 + ofs, color);
}


void() cl_navgen_try_next_task;

//============================================================================================================

void() cl_navgen_render_test_walk;
void cl_navgen_gen_drop_to_floor(vector pos);
float cl_navgen_auto_task;


//temp debug
float cl_navgen_calc_midpoint(vector a, vector b);
float cl_navgen_gen_direct_walk(vector start,vector ofs);
float cl_navgen_gen_walk_to_point(vector start, vector point);
float cl_navgen_obstructed(vector pos1, vector pos2);
//FIXME this is for debug
float debug_walk_to_point;
float debug_direct_walk;

float debug_dir;


float debug_check_invariants();

//A TEMP DEBUG METHOD THAT RENDERS INTERMEDIATE NAVMESH GENERATION RESULTS
void cl_navmesh_render_gen()
{
	navgen_vertex* vert = navgen_verts_root;

	while(vert)
	{
		cl_navmesh_render_vert(vert);
		if(vert->left)
			cl_navmesh_render_edge(vert,vert->left);
		if(vert->right)
			cl_navmesh_render_edge(vert,vert->right);

		//This will draw double edges, but this only really for debug, so it doesn't matter

		vert = vert->next;
	}

	//Drawing debug collision hulls
	for(float i = 0; i < ((debug_hull_count < MAX_DEBUG_HULL_COUNT) ? debug_hull_count : MAX_DEBUG_HULL_COUNT); i++)
	{
		cl_navmesh_draw_test_ent(debug_hulls[i],debug_hull_scales[i],debug_hull_colors[i],debug_hull_alphas[i]);
	}

	for(float j = 0; j < debug_lines_count; j++)
	{
		cl_navmesh_draw_line(debug_lines_pos1[j],debug_lines_pos2[j],2,debug_lines_color[j],0.2);
	}


	if(cl_navgen_auto_task && !debug_specific_walk)
		cl_navgen_try_next_task();


	//Used for rendering invariant walks
	//if(!cl_navgen_auto_task)
	//	debug_check_invariants();

	//cl_navgen_render_test_walk();

	//Debug rendering of midpoint

	//vector player_pos;
	//vec_eq(&player_pos,getentity(player_localentnum, GE_ORIGIN));
	//tracebox(player_pos,VEC_HULL_MIN,VEC_HULL_MAX,player_pos ,MOVE_NOMONSTERS,self);

	//print("Res: ss:",ftos(trace_startsolid)," as:",ftos(trace_allsolid)," f:",ftos(trace_fraction),"\n");

	if(debug_specific_walk && !debug_walk_printed)
	{
		debug_walk_printed = 1;
		vector a = [592.165405, -271.912720, -167.968750];
		vector b = [589.914429, -273.100342, -159.968750];

		cl_navmesh_draw_test_ent(a, [1,1,1], [0,1,0], 0.02);
		cl_navmesh_draw_test_ent(b, [1,1,1], [1,0,0], 0.02);

		debug_walk_to_point = 1;
		debug_direct_walk = 1;

		vector start;
		vector end;

		if(debug_dir == 0)
		{
			start = a;
			end = b;
		}
		else
		{
			start = b;
			end = a;
		}

		//float result = cl_navgen_calc_midpoint(start,end);
		//float result = cl_navgen_obstructed(start,end);
		//float result = cl_navgen_gen_direct_walk(start,end-start);
		float result = cl_navgen_gen_walk_to_point(start,end);

		print("Result: ",ftos(result),"\n");

		if(result == 0)
		{
			cl_navmesh_draw_line(a,b,2,[1,0,0],0.2);
		}
		else if(result == 1)
		{
			cl_navmesh_draw_line(a,b,2,[0,0,1],0.2);
		}
		else
			cl_navmesh_draw_line(a,b,2,[0,1,0],0.2);

		debug_walk_to_point = 0;
		debug_direct_walk = 0;
	}
}


//Assumes that the position given is very close to the floor, but might be too low or might be a bit too high
//(this is used for getting the player position, because player position from engine appears to be ofset by some tiny amount)
//Assigns trace_endpos as the position on the floor
void cl_navgen_gen_drop_to_floor(vector pos)
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

			vec_eq(&trace_endpos, pos);
			return;
		}

		//If this is true, we are underneath a very low hanging ceiling (practically touching top of bbox), there is something wrong with this.
		if(height < 0.01)
		{
			vec_eq(&trace_endpos, pos);
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




//Method that checks if pos + ofs is okay to walk
//returns 2 if walk is success
//returns 1 if walk was partial
//returns 0 if walk failed completely
//Assigns trace_endpos as the point as start if fail, or where we got to if success

//debug
float render_walk_to_point;
float cl_navgen_gen_direct_walk(vector start,vector ofs)
{
	float max_step_size = 18;//max stair step pulled straight from engine defs
	float tan_60 = 1.73205080757;//tangent of 60 degrees (max walkable slope) (used to make sure we don't walk up a higher slope)

	//FIXME: fix this when we handle sliding along ledges
	//========================================================================================
	//for now, consider not on ground as a dead stop
	//tracebox(start - [0,0,1],VEC_HULL_MIN,VEC_HULL_MAX,start-[0,0,max_step_size],MOVE_NOMONSTERS,self);
	tracebox(start,VEC_HULL_MIN,VEC_HULL_MAX,start-[0,0,2*max_step_size],MOVE_NOMONSTERS,self);
	if((!trace_allsolid && !trace_startsolid) && trace_fraction > 0.5)
	{
		print("We are not on ground to begin, returning 0\n");
		print("\tTrace fraction: ",ftos(trace_fraction),"\n");
		print("\tstart solid: ",ftos(trace_startsolid)," all solid: ",ftos(trace_allsolid),"\n");

		add_debug_hull(start,[1,1,1],[1,0,1],0.05);

		//cl_navmesh_draw_test_ent(start,[1,1,1],[1,0,0],0.2);

		vec_eq(&(trace_endpos),start);
		return 0;
	}

	//========================================================================================


	if(debug_direct_walk)
	{
		print("Direct walk: start = ",vtos(start), ", ofs = ", vtos(ofs),"\n");
	}


	vector goal;
	vec_eq(&goal,start+ofs);

	float iters = 0;

	float step_up = 0;

	vector cur_trace_end;
	vector cur;
	vector last_cur;
	vec_eq(&cur,start);
	vec_eq(&last_cur,start);

	vector last_ofs;

	float last_failed = 0;
	float cur_failed = 1;

	//Whether or not we moved at least a small amount (1 or 0)
	float moved_some_amount = 0;

	//for debugging
	float test_fraction = 0;

	if(debug_direct_walk)
		print("==== Start direct walk\n");

	//Alternate walking and stepping until we reach goal or hit a failure condition
	while(1)
	{
		if(iters == 9900)
		{
			//do nothing
			print("9900 iters\n");
		}
		if(iters++ > 9990)
		{
			print("Warning: runaway loop in navgen_direct_walk.\n");
			return 0;
		}


		if(!step_up)
		{
			if(debug_direct_walk)
				print("Walk with no step up \n");
			//Try walking straight to goal
			tracebox(cur,VEC_HULL_MIN,VEC_HULL_MAX,[goal_x,goal_y,cur_z],MOVE_NOMONSTERS,self);

			if(debug_direct_walk)
				print("fraction: ",ftos(trace_fraction),", cur: ",vtos(cur),", goal: ",vtos(goal),"\n");

	test_fraction = trace_fraction;
			vec_eq(&cur_trace_end,trace_endpos);

			//Try a move with a step up next time
			step_up  = 1;

			//Get the vector of the last move we did
			vec_eq(&last_ofs, cur_trace_end - cur);
		}
		else
		{
			if(debug_direct_walk)
				print("Walk with a step up \n");
			//Try walking to goal with a step up
			//tracebox up to see if we can move up
			tracebox(cur,VEC_HULL_MIN,VEC_HULL_MAX,cur+[0,0,max_step_size],MOVE_NOMONSTERS,self);
	test_fraction = trace_fraction;
			if(trace_fraction > 0)
			{
				//Try a trace forward from that position

				vector trace_start;
				vec_eq(&trace_start, trace_endpos);

				tracebox(trace_start, VEC_HULL_MIN, VEC_HULL_MAX, [goal_x, goal_y, trace_start_z], MOVE_NOMONSTERS,self);
	test_fraction = trace_fraction;
				vec_eq(&cur_trace_end,trace_endpos);

				//Get the vector of the last move we did
				vec_eq(&last_ofs, cur_trace_end - trace_start);
			}
			//Try a move without a step up next time
			step_up = 0;
		}

		if(debug_direct_walk)
			print("trace_fraction: ",ftos(trace_fraction)," allsolid: ",ftos(trace_allsolid)," startsolid: ",ftos(trace_startsolid),"\n");

		//if we moved at least some amount:
		if(!trace_allsolid && !trace_startsolid && trace_fraction > 0)
		{
			if(!cl_navgen_auto_task)
			{
				//cl_navmesh_draw_test_ent(trace_endpos,[1,1,1],[0,0,1],0.02);
				//cl_navmesh_draw_test_ent(trace_endpos,[0.01,0.01,1],[0,0,1],0.2);
				float width = 12;
				vector color;

				//blue = walk
				//purple = step

				if(step_up == 0)
					color = [1,0,1];
				else
					color = [0,0,1];

				//add_debug_line(cur-[0,0,32] + [0,0,width],trace_endpos-[0,0,32] + [0,0,width],width,color,0.2);
				add_debug_line(cur-[0,0,32] + [0,0,width],trace_endpos-[0,0,32] + [0,0,width],color);
			}

			if(debug_direct_walk)
				print("\t moved some amount (trace_fraction = ",ftos(trace_fraction),")\n");
			cur_failed = 0;
			vec_eq(&last_cur,cur);
			vec_eq(&cur,cur_trace_end);

			//add_debug_hull(cur, [0.01,0.01,1], [0,1,0], 0.35);
			//cl_navmesh_draw_test_ent(cur, [0.01,0.01,1], [0,1,0], 0.35);


			//=============================================== stuff went here


			//Check if we fell at cur result position

			//Height before we consider having fallen
			float fall_height = vlen(last_ofs) * tan_60;

			//Don't let fall height be less than the max step size
			if(fall_height < max_step_size)
				fall_height = max_step_size;

			tracebox(cur,VEC_HULL_MIN,VEC_HULL_MAX,cur- [0,0,2*fall_height] ,MOVE_NOMONSTERS,self);
	test_fraction = trace_fraction;

			//If we moved at all
			if(!trace_allsolid && !trace_startsolid && trace_fraction > 0)
			{
				if(debug_direct_walk)
				{
					print("\t\tbut we may have fallen off of a ledge\n");
					//cl_navmesh_draw_line(cur, cur-[0,0,2*fall_height * trace_fraction], 2, [0,0,1],0.2);
					cl_navmesh_draw_test_ent(cur - [0,0,32], [1,1,0.01], [0,1,0], 0.35);
					cl_navmesh_draw_test_ent(cur-[0,0,2*fall_height * trace_fraction] - [0,0,32], [1,1,0.01], [0,0,1], 0.35);
					cl_navmesh_draw_test_ent(cur - [0,0,fall_height] - [0,0,32], [1,1,0.01], [1,0,0], 0.35);
				}
				//Checking if we stepped down
				//If the angle between the move is greater than 60, we fell, otherwise we stepped down
				//if(vlen(trace_endpos - cur)/vlen(last_ofs) <= tan_60)


				if(trace_fraction <= 0.5)
				{
					if(debug_direct_walk)
						print("\t\t...nevermind, just stepped down\n");
					//We stepped down
					vec_eq(&cur,trace_endpos);
				}
				//We may have fallen down
				else
				{
					//If we hit something and
					//If we can direct walk from trace_endpos to last_cur, then we did not fall
					float did_fall = 1;

					if(trace_fraction < 1)
					{
						vector backup_trace_endpos;
						vec_eq(&backup_trace_endpos, trace_endpos);

						if(cl_navgen_gen_direct_walk(trace_endpos, last_cur - trace_endpos) == 2)
						{
							did_fall = 0;
						}

						if(!cl_navgen_auto_task)
						{
							//cl_navmesh_draw_test_ent(trace_endpos,[1,1,1],[0,0,1],0.02);
							//cl_navmesh_draw_test_ent(trace_endpos,[0.01,0.01,1],[0,0,1],0.2);
							//add_debug_line(backup_trace_endpos-[0,0,32] + [0,0,6],last_cur-[0,0,32] + [0,0,6],6,[0,1,0],0.2);
							add_debug_line(trace_endpos-[0,0,32] + [0,0,6],last_cur-[0,0,32] + [0,0,6],[0,1,0]);
						}

						vec_eq(&trace_endpos, backup_trace_endpos);
						vec_eq(&cur,backup_trace_endpos);
					}


					if(did_fall == 1)
					{
						if(!cl_navgen_auto_task)
						{
							//cl_navmesh_draw_test_ent(trace_endpos,[1,1,1],[0,0,1],0.02);
							//cl_navmesh_draw_test_ent(trace_endpos,[0.01,0.01,1],[0,0,1],0.2);
							//add_debug_line(backup_trace_endpos-[0,0,32] + [0,0,6],last_cur-[0,0,32] + [0,0,6],6,[1,0,0],0.2);
							add_debug_line(trace_endpos-[0,0,32] + [0,0,6],last_cur-[0,0,32] + [0,0,6],[1,0,0]);
						}

						//getting back onto the ground
						//undo the last move from a lowered position
						tracebox(trace_endpos,VEC_HULL_MIN,VEC_HULL_MAX,[last_cur_x,last_cur_y,trace_endpos_z],MOVE_NOMONSTERS,self);

						//then offset the position a tiny bit more and reset the z position back to normal
						vec_eq(&cur, trace_endpos);
						cur_z = last_cur_z;

						vector ledge_hit;
						vec_eq(&ledge_hit, cur);
						vec_eq(&cur,cur - 0.1*normalize(goal-start));

						vec_eq(&trace_endpos, cur);

						if(debug_direct_walk)
						{
							print("\t We fell ",ftos(test_fraction * 2),"x fall height, returning 1\n");
							print(" (fall height = ",ftos(fall_height),")\n");
							if(step_up == 0)
								print("... after stepping up\n");
							else
								print("did not step up\n");
						}

						//If we moved back to start, we were already on ledge, so we did not move on this axis
						//If distance to pushed onto ledge pos is greater than distance to start, we hit dead end
						if(vlen(cur - ledge_hit) >= vlen(start - ledge_hit))
							return 0;//treat this as hitting a dead end

						return 1;
					}
				}
			}


			//Check to make sure the ground was solid for the entire walk
			//We're going to do a trace along the height of cur_z or last_cur_z (whichever is lower)
			float lowest_height = cur_z < last_cur_z ? cur_z : last_cur_z;
			//Check a step below lowest height
			lowest_height -= max_step_size;

			tracebox([last_cur_x,last_cur_y,lowest_height],VEC_HULL_MIN,VEC_HULL_MAX,[cur_x,cur_y,lowest_height] ,MOVE_NOMONSTERS,self);

			vector a = [last_cur_x,last_cur_y,lowest_height];
			vector b = [cur_x,cur_y,lowest_height];

			if(debug_direct_walk)
				print("~~~~~~~~~~~~~~~~~ Printing trace below check: start(",vtos(a),") goal(",vtos(b),")~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");

			if(!trace_allsolid)
			{
				//New test definition of failure
				//=====================================

				if(debug_direct_walk)
					print("\t\t1st trace: startsolid: ",ftos(trace_startsolid)," allsolid: ",ftos(trace_allsolid)," fraction: ",ftos(trace_fraction),"\n");

				vector trace_1_end;
				vec_eq(&trace_1_end, trace_endpos);

				//Try the same trace in the opposite direction
				tracebox([cur_x,cur_y,lowest_height],VEC_HULL_MIN,VEC_HULL_MAX,[last_cur_x,last_cur_y,lowest_height],MOVE_NOMONSTERS,self);
				if(debug_direct_walk)
					print("\t\t2nd trace: startsolid: ",ftos(trace_startsolid)," allsolid: ",ftos(trace_allsolid)," fraction: ",ftos(trace_fraction),"\n");

				vector trace_2_end;
				vec_eq(&trace_2_end, trace_endpos);

				//If trace between these two points is not all solid
				tracebox(trace_1_end,VEC_HULL_MIN,VEC_HULL_MAX,trace_2_end,MOVE_NOMONSTERS,self);
				if(debug_direct_walk)
					print("\t\t3rd trace: startsolid: ",ftos(trace_startsolid)," allsolid: ",ftos(trace_allsolid)," fraction: ",ftos(trace_fraction),"\n");

				if(!trace_allsolid)
				{
					//If the same trace but backwards is not all solid
					tracebox(trace_2_end,VEC_HULL_MIN,VEC_HULL_MAX,trace_1_end,MOVE_NOMONSTERS,self);
					if(debug_direct_walk)
						print("\t\t4th trace: startsolid: ",ftos(trace_startsolid)," allsolid: ",ftos(trace_allsolid)," fraction: ",ftos(trace_fraction),"\n");

					if(!trace_allsolid)
					{
						vec_eq(&trace_endpos, last_cur);
						return moved_some_amount;
					}
				}

				//=====================================

				//AS A TEST
				//============
				//Print first trace results:

				/*print("\n\t\t first trace: allsolid: ", ftos(trace_allsolid), " startsolid: ",ftos(trace_startsolid), " fraction: ", ftos(trace_fraction),"\n");
				//Store endpos that we got to
				vector end1 = trace_endpos;

				//Trace in the other direction
				tracebox([cur_x,cur_y,lowest_height],VEC_HULL_MIN,VEC_HULL_MAX,[last_cur_x,last_cur_y,lowest_height] ,MOVE_NOMONSTERS,self);

				//Print backwards trace results:
				print("\t\t reverse trace: allsolid: ", ftos(trace_allsolid), " startsolid: ",ftos(trace_startsolid), " fraction: ", ftos(trace_fraction),"\n");

				//Store new endpos that we got to
				vector end2 = trace_endpos;

				//Try trace from end results and print results
				tracebox(end1,VEC_HULL_MIN,VEC_HULL_MAX,end2 ,MOVE_NOMONSTERS,self);
				print("\t\t subtrace: allsolid: ", ftos(trace_allsolid), " startsolid: ",ftos(trace_startsolid), " fraction: ", ftos(trace_fraction),"\n");

				//Try the other way, just for posterity
				tracebox(end2,VEC_HULL_MIN,VEC_HULL_MAX,end1 ,MOVE_NOMONSTERS,self);
				print("\t\t reverse subtrace: allsolid: ", ftos(trace_allsolid), " startsolid: ",ftos(trace_startsolid), " fraction: ", ftos(trace_fraction),"\n");

				print("\nEnd tests\n\n");
				//Redo first trace to restore trace variables
				tracebox([last_cur_x,last_cur_y,lowest_height],VEC_HULL_MIN,VEC_HULL_MAX,[cur_x,cur_y,lowest_height] ,MOVE_NOMONSTERS,self);*/
				//============


				//Double check to make sure (this fixes issues along a ledge that has stairs that go downwards)
				/*tracebox(trace_endpos,VEC_HULL_MIN,VEC_HULL_MAX,trace_endpos ,MOVE_NOMONSTERS,self);
				//FIXME: this trace above returns solid in some cases where it should not
				//We need a secondary check (perhaps more in-depth)
				//that checks to make sure there is a place where a tracebox can fit along the move outlined from a to b
				//tracebox(trace_endpos,VEC_HULL_MIN,VEC_HULL_MAX,[cur_x,cur_y,lowest_height] ,MOVE_NOMONSTERS,self);
				if(!trace_allsolid)
				{
					if(!cl_navgen_auto_task)
					{
						add_debug_hull_line([cur_x,cur_y,lowest_height - 32], [last_cur_x,last_cur_y,lowest_height - 32], [1,1,0]);
					}
					//We encountered a hole along the way!
					//Report last_cur as the position we got to
					if(debug_direct_walk)
					{
						print("\t trace below last move was not allsolid, returning: ",ftos(moved_some_amount),"\n");

						print("\t\t trace below details: allsolid: ", ftos(trace_allsolid), " startsolid: ",ftos(trace_startsolid), " fraction: ", ftos(trace_fraction),"\n");

						print("\t\t Trying trace again to check results\n");
						tracebox(trace_endpos,VEC_HULL_MIN,VEC_HULL_MAX,trace_endpos ,MOVE_NOMONSTERS,self);
						print("\t\t trace in-place results: allsolid: ", ftos(trace_allsolid), " startsolid: ",ftos(trace_startsolid), " fraction: ", ftos(trace_fraction),"\n");

						tracebox(trace_endpos,VEC_HULL_MIN,VEC_HULL_MAX,[cur_x,cur_y,lowest_height] ,MOVE_NOMONSTERS,self);
						print("\t\t trace back to start results: allsolid: ", ftos(trace_allsolid), " startsolid: ",ftos(trace_startsolid), " fraction: ", ftos(trace_fraction),"\n");

						cl_navmesh_draw_test_ent(a - [0,0,32], [1,1,0.01], [1,0,1], 0.35);
						cl_navmesh_draw_test_ent(b - [0,0,32], [1,1,0.01], [1,1,0], 0.35);
						cl_navmesh_draw_test_ent(trace_endpos - [0,0,32], [1,1,0.01], [0,1,1], 0.35);

						add_debug_hull(a - [0,0,32], [1,1,0.01], [0,0,1], 0.05);
						add_debug_hull(a - [0,0,32], [0.01,0.01,0.01], [0,0,1], 0.35);
						add_debug_hull(b - [0,0,32], [1,1,0.01], [1,0,0], 0.05);
						add_debug_hull(b - [0,0,32], [0.01,0.01,0.01], [1,0,0], 0.35);

						add_debug_hull(trace_endpos - [0,0,32], [1,1,0.01], [0,1,0], 0.05);
						add_debug_hull(trace_endpos - [0,0,32], [0.01,0.01,0.01], [0,1,0], 0.35);

						if(!cl_navgen_auto_task)
						{
							add_debug_hull(a, [1,1,1], [0,1,0], 0.02);
							add_debug_hull(a, [0.01,0.01,1], [0,1,0], 0.3);
							add_debug_hull(b, [1,1,1], [1,0,0], 0.02);
							add_debug_hull(b, [0.01,0.01,1], [1,0,0], 0.3);
						}
					}
					vec_eq(&trace_endpos, last_cur);
					return moved_some_amount;
				}*/
			}
			else if(debug_direct_walk)
			{
				//add_debug_hull(a - [0,0,32], [1,1,0.01], [0,1,0], 0.05);
				add_debug_hull(a - [0,0,32], [0.01,0.01,0.01], [0,1,0], 0.35);
				//add_debug_hull(b - [0,0,32], [1,1,0.01], [1,0,0], 0.05);
				add_debug_hull(b - [0,0,32], [0.01,0.01,0.01], [0,1,0], 0.35);
			}

			if(debug_direct_walk)
			{
				tracebox(trace_endpos,VEC_HULL_MIN,VEC_HULL_MAX,trace_endpos ,MOVE_NOMONSTERS,self);
				print("\t\t trace in-place results: allsolid: ", ftos(trace_allsolid), " startsolid: ",ftos(trace_startsolid), " fraction: ", ftos(trace_fraction),"\n");
				tracebox(trace_endpos,VEC_HULL_MIN,VEC_HULL_MAX,[cur_x,cur_y,lowest_height] ,MOVE_NOMONSTERS,self);
				print("\t\t trace back to start results: allsolid: ", ftos(trace_allsolid), " startsolid: ",ftos(trace_startsolid), " fraction: ", ftos(trace_fraction),"\n");
			}

			moved_some_amount = 1;
		}



		//Check if we failed on this iteration and the last iteration
		if(last_failed && cur_failed)
		{
			vec_eq(&trace_endpos,cur);
			return moved_some_amount;
		}

		//Check if we reached goal
		if(cur_x == goal_x && cur_y == goal_y)
		{
			//for debug
			//cl_navmesh_draw_test_ent(start,[1,1,1],[0,1,0],0.2);

			vec_eq(&trace_endpos, cur);
			return 2;
		}


		//for debug
		//cl_navmesh_draw_test_ent(cur,[1,1,1],[1,1,0],0.2);

		last_failed = cur_failed;
		cur_failed = 1;
	}

}


//Method that checks if pos + ofs is okay to walk
//returns 2 if walk is success
//returns 1 if walk was partial
//returns 0 if walk failed completely
float cl_navgen_gen_walk(vector start,vector ofs)
{
	float max_step_size = 18;//max stair step size pulled straight from engine defs

	//FIXME: fix this when we handle sliding along ledges
	//========================================================================================
	//for now, consider not on ground as a dead stop
	//tracebox(start - [0,0,1],VEC_HULL_MIN,VEC_HULL_MAX,start-[0,0,max_step_size],MOVE_NOMONSTERS,self);
	tracebox(start,VEC_HULL_MIN,VEC_HULL_MAX,start-[0,0,2*max_step_size],MOVE_NOMONSTERS,self);
	if((!trace_allsolid && !trace_startsolid) && trace_fraction > 0.5)
	{
		print("We are not on ground to begin, returning 0\n");
		print("\tTrace fraction: ",ftos(trace_fraction),"\n");
		print("\tstart solid: ",ftos(trace_startsolid)," all solid: ",ftos(trace_allsolid),"\n");

		add_debug_hull(start,[1,1,1],[1,0,1],0.05);

		vec_eq(&(trace_endpos),start);
		return 0;
	}

	//This is a problem for when we are checking left / right edges, because while walking the edge, we can never get to the vertex that
	//has been pushed off of a ledge
	//so, we must check for falling off of a ledge, but also
	//========================================================================================

	//Assuming we are on the ground

	vector cur;
	vec_eq(&(cur),start);

	vector goal_org;

	vector delta_org;

	//0 means did not walk at all, 1 means we slid, 2 means we completed the move in x & y axis
	float success[2] = {0,0};

	//TODO: if move with move order of x,y fails, try a move with move order of y,x

	//Iterate over x-axis then y-axis
	for(float i = 0; i < 2; i++)
	{

		delta_org = [0,0,0];

		delta_org[i] = ofs[i];

		vec_eq(&(goal_org),cur+delta_org);

		//Push down from a step above goal org to find result position

		vector above_goal;
		vec_eq(&above_goal,goal_org + [0,0,max_step_size]);
		vector below_goal;
		vec_eq(&below_goal, goal_org - [0,0,max_step_size]);

		tracebox(above_goal,VEC_HULL_MIN,VEC_HULL_MAX,below_goal,MOVE_NOMONSTERS,self);

		if(trace_allsolid || trace_startsolid)
		{
			tracebox(goal_org,VEC_HULL_MIN,VEC_HULL_MAX,below_goal,MOVE_NOMONSTERS,self);
			if(trace_allsolid || trace_startsolid)
			{
				//Hit a wall
				success[i] = 0;

				//Try straight tracebox to wall
				tracebox(cur,VEC_HULL_MIN,VEC_HULL_MAX,goal_org,MOVE_NOMONSTERS,self);

				if(trace_fraction > 0)
				{
					//We still moved on this move
					success[i] = 1;
					vec_eq(&(cur),trace_endpos);

				}

				continue;
			}
		}

		if(trace_fraction >= 1)
		{
			//We walked off of a ledge

			//Try straight tracebox back to the ledge from the lowered goal position
			tracebox(below_goal,VEC_HULL_MIN,VEC_HULL_MAX,below_goal-delta_org,MOVE_NOMONSTERS,self);

			vec_eq(&(cur),trace_endpos);
			cur_z += max_step_size;//don't lower the cur_z

			//cur should now be right up against the ledge, push back a tiny bit from the ledge so that we cannot fall
			vector ledge_hit;
			vec_eq(&ledge_hit, cur);
			vec_eq(&(cur),cur - 0.1*normalize(delta_org));

			//If we moved back to start, we were already on ledge, so we did not move on this axis
			//If distance to pushed onto ledge pos is greater than distance to start, we hit dead end
			if(fabs(cur[i] - ledge_hit[i]) >= fabs(start[i] - ledge_hit[i]))
				success[i] = 0;//treat this as hitting a dead end
			else
				success[i] = 2;

			//We are now just barely on a ledge

			continue;
		}

		success[i] = 2;

		//If this is a zero move and the other is not, our success depends entirely on the other move
		if(ofs[i] == 0 && ofs[(i+1)%2] != 0)
		{
			success[i] = -1;
		}

		vec_eq(&(cur),trace_endpos);

		//We are on the ground
	}

	//Assign trace end pos as where we ended up
	vec_eq(&(trace_endpos),cur);

	//If either move was a zero move, the success of the move depends on the other
	if(success[0] == -1)
		return success[1];
	if(success[1] == -1)
		return success[0];

	if(success[0] == success[1])
	{
		return success[0];
	}

	//If we only moved in one direction, retry this move in that direction with a direct walk at the full ofs
	//(so we don't slow down when our ofs is clipped against a wall)
	if(cl_navgen_gen_direct_walk(start,vlen(ofs) * normalize(cur-start)))
	{
		return 1;
	}
	//Otherwise just revert to the position we found in this function
	vec_eq(&(trace_endpos),cur);

	return 1;
}





//Returns the length of the x & y components of this vector
float xy_vlen(vector v)
{
	return vlen([v_x,v_y,0]);
}


string walk_percent(vector start, vector cur, vector goal)
{
	return ftos(xy_vlen(cur-start) / xy_vlen(goal-start));
}
//FIXME: remove the stuff above

//Walks to x & y coordinate of point
//We walk in dist increments, and assume we are unobstructed
//Returns 1 if successful, 0 otherwise
//Assigns the trace_endpos as the actual point we got to (as z-coordinate may be different)


//Issue: these dist increments of 1 are too discrete
//This will fail on some edge cases
//I need to come up with a alternative continuous method for direct walk to point.

float cl_navgen_gen_walk_to_point(vector start, vector point)
{
	float dist = 1;

	vector cur;
	vec_eq(&(cur),start);

	vector cur_ofs;
	vec_eq(&cur_ofs, dist * normalize([point_x,point_y,0] - [start_x,start_y,0]));

	float move;

	float iters = 0;
	vector last_pos;
	vec_eq(&(last_pos),cur);

	if(debug_walk_to_point)
	{
		print("dist: ", ftos(dist),"\n");
		print("Start: ",vtos(start),"\n");
		print("End: ",vtos(point),"\n");
		print("Walk to point started: ",walk_percent(start,cur,point),",\t,",vtos(cur),"\n");

		if(!cl_navgen_auto_task)
		{
			add_debug_hull(start,[1,1,1],[0,0,1],0.05);
			add_debug_hull(start,[0.01,0.01,0.8],[0,0,1],0.3);
			add_debug_hull(point,[1,1,1],[0,0,1],0.05);
			add_debug_hull(point,[0.01,0.01,0.8],[0,0,1],0.3);
		}
	}

	if(!cl_navgen_auto_task)
	{
		add_debug_hull(start,[1,1,1],[0,1,0],0.02);
		add_debug_hull(start,[0.01,0.01,1],[0,1,0],0.2);
	}

	while(1)
	{
		if(iters++ >= 9997)
		{
			print("\n\nWarning: iterations exceeded 9998\n");
			print("Trying to walk from ",vtos(start)," to ",vtos(point),"\n");

			print("Info: cur_ofs:",vtos(cur_ofs)," cur:", vtos(cur)," last pos:",vtos(last_pos),"\n");

			add_debug_hull(start,[1,1,1],[0,1,0],0.05);
			add_debug_hull(start,[0.01,0.01,0.01],[0,1,0],0.2);

			add_debug_hull(point,[1,1,1],[1,0,0],0.05);
			add_debug_hull(point,[0.01,0.01,0.01],[0,1,0],0.2);

			add_debug_hull(cur,[1,1,1],[1,1,1],0.05);
			add_debug_hull(cur,[0.01,0.01,0.01],[1,1,1],0.2);

			add_debug_hull(last_pos,[1,1,1],[0.5,0.5,0.5],0.05);
			add_debug_hull(last_pos,[0.01,0.01,0.01],[0.5,0.5,0.5],0.2);


			print("cur ofs x: ",ftos(cur_ofs_x),", delta x: ",ftos(point_x-cur_x),"\n");
			print("cur ofs y: ",ftos(cur_ofs_y),", delta y: ",ftos(point_y-cur_y),"\n");

			vec_eq(&trace_endpos,start);
			return 0;
		}
		//Don't walk past endpoint



		if(xy_vlen(cur_ofs) > xy_vlen(point - cur))
		{
			vec_eq(&cur_ofs, [point_x,point_y,0] - [cur_x,cur_y,0]);
		}

		//If we are at the endpoint
		if(cur_ofs_x == 0 && cur_ofs_y == 0)
		{
			vec_eq(&(trace_endpos),cur);

			if(!cl_navgen_auto_task)
			{
				add_debug_hull(trace_endpos,[1,1,1],[0,1,0],0.02);
				add_debug_hull(trace_endpos,[0.01,0.01,1],[0,1,0],0.2);
			}
			return 1;
		}


		move = cl_navgen_gen_direct_walk(cur,cur_ofs);


		//Check if we made it
		if(trace_endpos_x == point_x && trace_endpos_y == point_y)
		{
			if(!cl_navgen_auto_task)
			{
				add_debug_hull(trace_endpos,[1,1,1],[0,1,0],0.02);
				add_debug_hull(trace_endpos,[0.01,0.01,1],[0,1,0],0.2);
			}
			//trace_endpos already holds result pos
			return 1;
		}

		if(move == 0 || move ==  1)
		{
			//debug_hulls[debug_hull_count++] = cur;
			//debug_hulls[debug_hull_count++] = cur + cur_ofs;
			//print("cur: ",vtos(cur)," cur_ofs: ",vtos(cur_ofs),"\n");
			//Just doing a temp call to follow the stack trace
			//move = cl_navgen_gen_direct_walk(cur,cur_ofs);

			if(debug_walk_to_point)
			{
				print("Moved is: ",ftos(move));
				//TODO: do a cl_navgen_direct_walk debug call
				if(!cl_navgen_auto_task)
				{
					add_debug_hull(cur,[1,1,1],[1,0,0],0.05);
					add_debug_hull(cur,[0.01,0.01,1],[1,0,0],0.3);
				}

				print("Debug calling direct walk\n");
				debug_direct_walk = 1;
				move = cl_navgen_gen_direct_walk(cur,cur_ofs);
				debug_direct_walk = 0;
			}

			if(!cl_navgen_auto_task)
			{
				add_debug_hull(trace_endpos,[1,1,1],[1,0,0],0.02);
				add_debug_hull(trace_endpos,[0.01,0.01,1],[1,0,0],0.2);
			}

			vec_eq(&trace_endpos,start);

			return 0;
		}

		vec_eq(&(last_pos),cur);
		vec_eq(&(cur),trace_endpos);

		if(!cl_navgen_auto_task)
		{
			//add_debug_hull(trace_endpos,[1,1,1],[0,0,1],0.02);
			//add_debug_hull(trace_endpos,[0.01,0.01,1],[0,0,1],0.2);
		}

		if(debug_walk_to_point)
		{
			print("Walk to point: ",walk_percent(start,cur,point),",\t,",vtos(cur),"\n");
		}
	}
}



//Walks to x & y coordinate of about halfway between start and point
//We walk in dist increments, and assume we are unobstructed
//Returns 1 if successful, 0 otherwise
//Assigns the trace_endpos as the actual point we got to (as z-coordinate may be different)
float cl_navgen_gen_walk_to_midpoint(vector start, vector point)
{
	//If start and point are at the same position, we technically succeeded, but is an error case
	if(xy_vlen(point - start) == 0)
	{
		print("Warning: tried to calculate midpoint of two superimposed points\n");
		vec_eq(&trace_endpos, start);
		return 1;
	}


	//Walk in increments of 3.0 or 1/10th of distance between point and start, whichever is smaller
	float dist;
	dist = xy_vlen(point - start) * 0.1;
	if(dist > 3.0)
		dist = 3.0;

	vector cur;
	vec_eq(&(cur),start);
	vector cur_ofs;
	vec_eq(&cur_ofs, dist * normalize([point_x,point_y,0] - [start_x,start_y,0]));


	float move;

	float iters = 0;
	vector last_pos;
	vec_eq(&(last_pos),cur);

	vector xy_midpoint = ([point_x,point_y,0] + [start_x,start_y,0])/2;

	if(debug_walk_to_point)
	{
		print("dist: ", ftos(dist),"\n");
		print("Start: ",vtos(start),"\n");
		print("End: ",vtos(point),"\n");
		print("\ttentative midpoint: ",vtos(xy_midpoint),"\n");
		print("Walk to midpoint started: ",walk_percent(start,cur,point),",\t,",vtos(cur),"\n");
	}


	//We're going to walk to point as normal, but exit when we've walked over halfway there.
	while(1)
	{
		if(iters++ >= 9998)
		{
			print("\n\nWarning: walk to midpoint iterations exceeded 9998\n");
			print("Trying to walk from ",vtos(start)," to ",vtos(point),"\n");

			print("Info: cur_ofs:",vtos(cur_ofs)," delta:", vtos(point - cur)," last pos:",vtos(last_pos),"\n");

			add_debug_hull(start,[1,1,1],[0,1,0],0.05);
			add_debug_hull(start,[0.01,0.01,0.01],[0,1,0],0.2);

			add_debug_hull(point,[1,1,1],[0,1,0],0.05);
			add_debug_hull(point,[0.01,0.01,0.01],[0,1,0],0.2);

			add_debug_hull(cur,[1,1,1],[1,1,1],0.05);
			add_debug_hull(cur,[0.01,0.01,0.01],[1,1,1],0.2);

			add_debug_hull(last_pos,[1,1,1],[0.5,0.5,0.5],0.05);
			add_debug_hull(last_pos,[0.01,0.01,0.01],[0.5,0.5,0.5],0.2);

			vec_eq(&trace_endpos,start);
			return 0;
		}



		//Don't walk past midpoint
		if(xy_vlen(cur_ofs) > xy_vlen(xy_midpoint - cur))
		{
			vec_eq(&cur_ofs, xy_midpoint - [cur_x,cur_y,0]);
		}

		//If we are at the endpoint
		if(cur_ofs_x == 0 && cur_ofs_y == 0)
		{
			vec_eq(&(trace_endpos),cur);
			return 1;
		}


		move = cl_navgen_gen_direct_walk(cur,cur_ofs);

		//Check if we have reached the midpoint
		if(trace_endpos_x == xy_midpoint_x && trace_endpos_y == xy_midpoint_y)
		{
			return 1;
		}


		//Check if we hit a wall or obstruction along the way
		if(move == 0 || move == 1)//We do not allow sliding or partial moves in this algorithm
		{
			if(debug_walk_to_point)
			{
				//Red
				/*add_debug_hull(cur,[1,1,1],[1,0,0],0.02);
				add_debug_hull(cur,[0.01,0.01,1],[1,0,0],0.2);
				//Green
				add_debug_hull([xy_midpoint_x,xy_midpoint_y,cur_z],[1,1,1],[0,1,0],0.02);
				add_debug_hull([xy_midpoint_x,xy_midpoint_y,cur_z],[0.01,0.01,1],[0,1,0],0.2);
				//Yellow
				add_debug_hull(cur+cur_ofs,[0.01,0.01,1],[1,1,0],0.2);
				add_debug_hull(cur+cur_ofs,[1,1,1],[1,1,0],0.02);
				//Blue
				add_debug_hull(start,[1,1,1],[0,0,1],0.02);
				add_debug_hull(start,[0.01,0.01,1],[0,0,1],0.2);
				add_debug_hull(point,[1,1,1],[0,0,0.5],0.02);
				add_debug_hull(point,[0.01,0.01,1],[0,0,0.5],0.2);*/
				print("Walk to midpoint hit something along the way.\n");
			}
			vec_eq(&trace_endpos,start);
			return 0;
		}

		vec_eq(&(last_pos),cur);
		vec_eq(&(cur),trace_endpos);

		if(debug_walk_to_point)
		{
			print("Walk to midpoint: ",walk_percent(start,cur,point),",\t,",vtos(cur),"\n");
		}
	}
}








//Returns 0 if edge is unobstructed
//Returns 1 if walking directly from pos1 to pos2 fails
//Returns 1 if walking directly from pos2 to pos1 fails
float cl_navgen_obstructed(vector pos1, vector pos2)
{
	//Try walk from pos1 to pos2

	if(!cl_navgen_gen_walk_to_point(pos1,pos2))
	{
		//print("could not walk from pos1 to pos2 (Result was not: ",vtos(pos2),")\n");
		return 1;
	}
	//Try walk from pos2 to pos1
	if(!cl_navgen_gen_walk_to_point(pos2,pos1))
	{
		//print("could not walk from pos2 to pos1\n");
		return 1;
	}

	return 0;
}


//Returns 1 if successful, 0 otherwise
//Assigns the midpoint to trace_endpos
//The issue is that the assumption that we make for this function is that two vertices should NOT be obstructed from each other, ergo: there should be no issue here, but at some point in time before this call
//we are invalidating this assumed invariant
float cl_navgen_calc_midpoint(vector a, vector b)
{
	vector mid;
	vector backup_trace_endpos;

	//This debug code checks if two vertices  are obstructed, but we should not be calling calc_midpoint when two are obstructed, ergo an invariant is being violated
	/*if(cl_navgen_obstructed(a,b))//this is sometimes triggered (most likely due to floating point error)
	{
		print("Warning: a and b are obstructed, abort midpoint calculation\n");
		vec_eq(&trace_endpos,a);

		add_debug_hull(a,[1.0,1.0,1.0],[0,1,0],0.05);
		add_debug_hull(a,[0.01,0.01,1.0],[0,1,0],0.3);
		add_debug_hull(b,[1.0,1.0,1.0],[1,0,0],0.05);
		add_debug_hull(b,[0.01,0.01,1.0],[1,0,0],0.3);

		//TODO: debug exactly why this fails
		print("\n\tCalling obstructed check with debug enabled.\n");
		debug_walk_to_point = 1;
		cl_navgen_obstructed(a,b);
		debug_walk_to_point = 0;
		print("\n\tDone calling obstructed check with debug enabled.\n");

		return 0;
	}*/

	if(cl_navgen_gen_walk_to_midpoint(a,b))
	{
		print("\tmidpoint Success: ",vtos(trace_endpos),"\n");
		vec_eq(&backup_trace_endpos,trace_endpos);


		//TEMP DEBUG STUFF
		//==================
		//If we found midpoint, check to verify that we can walk from a to midpoint and b to midpoint
		//The assumption for this function is that we can from a to b, and from b to a

		if(cl_navgen_obstructed(a,b))
		{
			print("Warning: a <-> b obstructed\n");

			cl_navgen_auto_task = 1;
			debug_walk_to_point = 0;


			if(!cl_navgen_gen_walk_to_point(a,b))
			{
				print("\ta cannot walk to b\n");
				cl_navgen_auto_task = 0;
				debug_walk_to_point = 1;
				cl_navgen_gen_walk_to_point(a,b);
				cl_navgen_auto_task = 0;
				debug_walk_to_point = 0;
			}
			if(!cl_navgen_gen_walk_to_point(b,a))
			{
				print("\tb cannot walk to a\n");
				cl_navgen_auto_task = 0;
				debug_walk_to_point = 1;
				cl_navgen_gen_walk_to_point(b,a);
				cl_navgen_auto_task = 0;
				debug_walk_to_point = 0;
			}
		}
		if(cl_navgen_obstructed(backup_trace_endpos,a))
		{
			print("Warning: found midpoint <-> a obstructed\n");
			cl_navgen_auto_task = 1;
			debug_walk_to_point = 0;


			if(!cl_navgen_gen_walk_to_point(backup_trace_endpos,a))
			{
				print("\tmidpoint cannot walk to a\n");
				cl_navgen_auto_task = 0;
				debug_walk_to_point = 1;
				cl_navgen_gen_walk_to_point(backup_trace_endpos,a);
				cl_navgen_auto_task = 0;
				debug_walk_to_point = 0;
			}
			if(!cl_navgen_gen_walk_to_point(a,backup_trace_endpos))
			{
				print("\ta cannot walk to midpoint\n");
				cl_navgen_auto_task = 0;
				debug_walk_to_point = 1;
				cl_navgen_gen_walk_to_point(a,backup_trace_endpos);
				cl_navgen_auto_task = 0;
				debug_walk_to_point = 0;
			}
		}
		if(cl_navgen_obstructed(backup_trace_endpos,b))
		{
			print("Warning: found midpoint <-> b obstructed\n");
			cl_navgen_auto_task = 1;
			debug_walk_to_point = 0;


			if(!cl_navgen_gen_walk_to_point(backup_trace_endpos,b))
			{
				print("\tmidpoint cannot walk to b\n");
				cl_navgen_auto_task = 0;
				debug_walk_to_point = 1;
				cl_navgen_gen_walk_to_point(backup_trace_endpos,b);
				cl_navgen_auto_task = 0;
				debug_walk_to_point = 0;
			}
			if(!cl_navgen_gen_walk_to_point(b,backup_trace_endpos))
			{
				print("\tb cannot walk to midpoint\n");
				cl_navgen_auto_task = 0;
				debug_walk_to_point = 1;
				cl_navgen_gen_walk_to_point(b,backup_trace_endpos);
				cl_navgen_auto_task = 0;
				debug_walk_to_point = 0;
			}
		}

		if(!cl_navgen_auto_task)
		{
			add_debug_hull(a, [1,1,1],[1,0,0],0.03);
			add_debug_hull(a, [1,1,2],[1,0,1],0.03);
			add_debug_hull(a, [0.01,0.01,2],[1,0,0],0.5);
			add_debug_hull(backup_trace_endpos, [1,1,1],[0,1,0],0.03);
			add_debug_hull(backup_trace_endpos, [0.01,0.01,2],[0,1,0],0.5);
			add_debug_hull(b, [1,1,1],[0,0,1],0.03);
			add_debug_hull(b, [0.01,0.01,2],[0,0,1],0.5);
		}

		//TODO: if something is obstructed, debug what happened here

		//==================

		//trace_endpos is already midpoint
		vec_eq(&trace_endpos,backup_trace_endpos);
		return 1;
	}
	else
	{
		//sometimes walk to midpoint fails flat out (happens with staircases)
		//(can also happen on corners)

		//TODO: debug what happens here
		//vec_eq(&backup_trace_endpos,trace_endpos);


		//for(float i = 0; i < 40; i++)print("=");print("\n");
		//print("Warning: could not walk to mid from min.\n");
		//for(float i = 0; i < 40; i++)print("=");print("\n");

		//if(cl_navgen_gen_walk_to_point(a,b))
		//{
		//	print("\tCan walk from a to b\n");
		//}
		//else
		//	print("\tCannot walk from a to b\n");

		//Calling cl_navgen_gen_walk_to_midpoint again with debug turned on
		/*for(float i = 0; i < 40; i++)print("=");print("\n");
		for(float i = 0; i < 40; i++)print("=");print("\n");
		print("start debug call \n\n");*/
		//float temp = disable_print;

		//disable_print = 0;
		//debug_walk_to_point = 1;
		//cl_navgen_gen_walk_to_point(a,b);
		//print("\n");
		//cl_navgen_gen_walk_to_midpoint(a,b);
		//debug_walk_to_point = 0;
		//disable_print = 1;
		//print("\n end debug call \n");
		//for(float i = 0; i < 40; i++)print("=");print("\n");
		//for(float i = 0; i < 40; i++)print("=");print("\n");
		//print("\n");

		//FIXME: sometimes walk to midpoint fails even though we can walk from a to b
		//vec_eq(&trace_endpos,backup_trace_endpos);
		return 0;
	}
}


//Variables for test walk state data
float cl_navgen_render_test_walk_function;
float cl_navgen_render_test_walk_radius;
vector cl_navgen_render_test_walk_goal;
vector cl_navgen_render_test_walk_start;
float cl_navgen_render_test_walk_start_placed;

void cl_navgen_render_test_walk()
{
	//return;
	//Walk functions:
	//0	float cl_navgen_gen_walk(vector start,vector ofs);			//0 for fail, 1 partial, 2 success
	//1	float cl_navgen_gen_direct_walk(vector start,vector ofs);		//0 for fail, 1 partial, 2 success
	//2	float cl_old_navgen_gen_direct_walk(vector start,vector ofs);		//0 for fail, 1 partial, 2 success
	//3	float cl_navgen_gen_walk_to_point(vector start, vector point);		//0 fail, 1 success
	//4	float cl_navgen_obstructed(vector pos1, vector pos2);			//0 unobstruced, 1 if either direction is obstructed
	//5	float cl_navgen_calc_midpoint(vector a, vector b);			//0 fail, 1 success
	//6	float cl_navgen_gen_walk_to_midpoint(vector start, vector point);	//0 fail, 1 success

	vector player_pos;
	vec_eq(&player_pos, getentity(player_localentnum, GE_ORIGIN));
	//Find floor at pos
	cl_navgen_gen_drop_to_floor(player_pos);
	vec_eq(&player_pos,trace_endpos);


	//If start ent has been placed:
	if(cl_navgen_render_test_walk_start_placed)
	{
		vec_eq(&player_pos, cl_navgen_render_test_walk_start);
	}

	//Drawing the ground position of the player
	//cl_navmesh_draw_test_ent(player_pos,[1,1,1],[1,1,1],0.2);

	//debug_direct_walk = 1;

	/*float dist = cl_navgen_render_test_walk_radius;

	vector ofs;
	vec_eq(&ofs,[dist * cos(time), dist * sin(time), 0]);

	//cl_navgen_gen_drop_to_floor(player_pos + ofs + 2*[0,0,18]);


	//For those walk functions that require a second vector, walk to ofs to get trace_endpos
	vector point;
	cl_navgen_gen_direct_walk(player_pos,ofs);
	vec_eq(&point, trace_endpos);*/


	//========================
	//The following code is for testing to a placed vector
	vector point;
	vector ofs;
	vec_eq(&point, cl_navgen_render_test_walk_goal);
	vec_eq(&ofs, point - player_pos);
	//========================

	float result = 0;
	vector color = [0,0,0];

	switch(cl_navgen_render_test_walk_function)
	{
		case 0:
			result = cl_navgen_gen_walk(player_pos,ofs);
			break;
		case 1:
			result = cl_navgen_gen_direct_walk(player_pos,ofs);
			break;
		case 2:
			result = cl_navgen_gen_walk_to_point(player_pos,point);
			break;
		case 3:
			result = cl_navgen_obstructed(player_pos, point);
			break;
		case 4:
			result = cl_navgen_calc_midpoint(player_pos, point);
			break;
		case 5:
			result = cl_navgen_gen_walk_to_midpoint(player_pos, point);
			break;
		default:
			return;
	}

	switch(cl_navgen_render_test_walk_function)
	{
		case 0:
		case 1:
			if(result != 2)
				color[0] = 1;
			if(result != 0)
				color[1] = 1;
			break;
		case 3:
			if(result == 0)
				color[1] = 1;
			else
				color[0] = 1;
			break;
		case 2:
		case 4:
		case 5:
			if(result == 1)
				color[1] = 1;
			else
				color[0] = 1;
			break;
		default:
			return;
	}

	//If we failed on walk to point, render some stuff
	if(cl_navgen_render_test_walk_function == 2)
	{
		if(cl_navgen_render_test_walk_start_placed == 1)
		{
			cl_navmesh_draw_line(player_pos,point,2,color,0.2);
			cl_navmesh_draw_test_ent(trace_endpos,[1,1,1],color,0.02);
			cl_navmesh_draw_test_ent(player_pos,[1,1,1],[0,1,0],0.02);
			cl_navmesh_draw_test_ent(point,[1,1,1],[1,0,0],0.02);

			render_walk_to_point = 1;
			debug_direct_walk = 1;
			cl_navgen_gen_walk_to_point(player_pos,point);
			debug_direct_walk = 0;
			render_walk_to_point = 0;


			return;
		}
	}

	cl_navmesh_draw_line(player_pos,player_pos+ofs,2,color,0.2);
	cl_navmesh_draw_test_ent(trace_endpos,[1,1,1],color,0.2);

	if(trace_endpos != point)
		cl_navmesh_draw_test_ent(point,[1,1,1],[0,0,1],0.2);

	//Case 5 and 6's trace_endpos is a midpoint, make sure we still draw the calculated point
	if(cl_navgen_render_test_walk_function == 4 || cl_navgen_render_test_walk_function == 5)
	{
		cl_navmesh_draw_test_ent(point,[1,1,1],color,0.2);
	}
}

//Restructuring find_min algorithm:
//Given pos1 pos2 and pos3, alternates moving pos2 towards pos1 and pos3 a tiny amount until we cannot walk to the one we are not moving towards
//Assigns trace_endpos as resulting minimum
//Returns 0 if we encountered an error / issue, 1 if we successfully found the minimum (I'm not yet sure if this error handling is useful in any way)
float cl_navgen_find_min(vector pos1, vector pos2, vector pos3)
{
	float mid1_minimized = 0;
	float mid3_minimized = 0;

	vector min;
	vec_eq(&min,pos2);

	vector mid1;
	vector mid3;

	float delta = 0.01;//how close does the min and max have to be for us to accept min as the desired point?

	float iters = 0;
	float iters2 = 0;

	print("\nFind min Start\n\n");
	print("pos1: ",vtos(pos1),"\nmin: ",vtos(min),"\n pos3:",vtos(pos3),"\n");

	vec_eq(&mid1,pos1);
	vec_eq(&mid3,pos3);

	while(1)
	{
		if(iters++ >= 9999)
		{
			print("Warning: iters exceeded 9998\n");
			vec_eq(&trace_endpos,min);
			return 0;
		}

		iters2 = 0;
		mid1_minimized = 0;

		//Subdivide min to pos1 until we can walk to pos3 from mid1
		while(1)
		{
			if(iters2++ >= 9999)
			{
				print("Warning iters2 exceeded 9998 on 1\n");
				return 0;
			}

			//Check if mid1 and min are so close that we have minimized this edge
			if(xy_vlen(mid1 - min) < delta)
			{
				mid1_minimized = 1;
				vec_eq(&(mid3),pos3);
				break;
			}

			//if we can walk from mid1 to pos3, stop minimizing
			if(!cl_navgen_obstructed(mid1,pos3))
			{
				vec_eq(&(mid3),pos3);
				vec_eq(&(min),mid1);
				break;
			}

			//Subdivide
			cl_navgen_calc_midpoint(min,mid1);
			vec_eq(&(mid1),trace_endpos);
		}

		//Check if we are done
		if(mid1_minimized && mid3_minimized)
		{
			vec_eq(&trace_endpos,min);
			return 1;
		}

		iters2 = 0;
		mid3_minimized = 0;

		//Subdivide min to pos3 until we can walk to pos1 from mid3
		while(1)
		{
			if(iters2++ >= 9999)
			{
				print("Warning iters2 exceeded 9998 on 3\n");
				return 0;
			}

			//Check if mid3 and min are so close that we have minimized this edge
			if(xy_vlen(mid3 - min) < delta)
			{
				mid3_minimized = 1;
				vec_eq(&(mid1),pos1);
				break;
			}

			//if we can walk from mid3 to pos1, stop minimizing
			if(!cl_navgen_obstructed(mid3,pos1))
			{
				vec_eq(&(mid1),pos1);
				vec_eq(&(min),mid3);
				break;
			}

			//Subdivide
			cl_navgen_calc_midpoint(min,mid3);
			vec_eq(&(mid3),trace_endpos);
		}

		//Check if we are done
		if(mid1_minimized && mid3_minimized)
		{
			vec_eq(&trace_endpos,min);
			return 1;
		}
	}
}


void cl_navgen_gen_floodfill(navgen_vertex* vert)
{
	//Incrementally walk vertex away from it's edges until it stops or our edges are obstructed

	//calculate direction from edges
	vector walk_dir = [0,0,0]; //take line tangent to line normalize(vert->right->pos - vert->left->pos)

	float walk_dist = 3;//how many qu to walk at each step

	//Calculating walk_dir
	//===========================
	vector tangent;
	vec_eq(&(tangent),((vert->right)->pos - (vert->left)->pos));

	//Don't care about z-difference
	tangent_z = 0;
	vec_eq(&(tangent),normalize(tangent));


	//Getting edge normal
	walk_dir[0] = -tangent[1];
	walk_dir[1] = tangent[0];
	walk_dir *= walk_dist;

	//if walk_dir is zero vector, something is horribly wrong
	if(walk_dir == [0,0,0])
	{
		print("Navmesh generation Error: walk_dir is zero vector for vert at pos: ",vtos(vert->pos)," with edges ");
		if(vert->left)
			print("L: ",vtos((vert->left)->pos));
		else
			print("L: null");
		if(vert->right)
			print(" R: ",vtos((vert->right)->pos));
		else
			print(" R: null");
		print("\n");
		return;
	}
	//===========================

	float did_move = 0;

	float move;

	print("Walk dir: ",vtos(walk_dir),"\n");

	vector last_vert_pos;

	navgen_vertex* new_vert;


	float iters = 0;

	//walk the vertex in the direction a small amount
	while(1)
	{
		if(iters++ > 9998)
		{
			print("Warning: floodfill algorithm runaway loop\n");
			return;
		}
		//Try walking a small amount forward
		vec_eq(&(last_vert_pos),vert->pos);

		move = cl_navgen_gen_walk(vert->pos,walk_dir);

		vec_eq(&(vert->pos),trace_endpos);
		if(!move && !did_move)
		{
			break;
		}
		did_move = 1;



		//check if left edge was obstructed
		//print("Checking left to vert edge\n");
		if(cl_navgen_obstructed((vert->left)->pos,vert->pos))
		{
			print("Left edge obstructed.\n");

			//Subdivide the left edge
			//Insert the new vertex at our last vertex position
			new_vert = cl_navgen_new_vert(last_vert_pos);

			new_vert->left = vert->left;
			(vert->left)->right = new_vert;
			new_vert->right = vert;
			vert->left = new_vert;


			//Getting the vertex as close to the corner as possible
			cl_navgen_find_min(vert->pos,new_vert->pos,(new_vert->left)->pos);
			vec_eq(&(new_vert->pos), trace_endpos);



			//Get new_vert as close as possible to our vert such that we can still walk to our left vert
//			print("Before: ",vtos(new_vert->pos));



			//vec_eq(&(new_vert->pos), cl_navgen_find_min(new_vert->pos,vert->pos,(new_vert->left)->pos));
			//cl_navgen_find_min(new_vert->pos,vert->pos,(new_vert->left)->pos);
			//vec_eq(&(new_vert->pos), trace_endpos);
//			print("After: ",vtos(new_vert->pos));


			//Get new_vert as close as possible to our left vert such that we can still walk to our vert
			//vec_eq(&(new_vert->pos), cl_navgen_find_min(new_vert->pos,(new_vert->left)->pos,vert->pos));
			//cl_navgen_find_min(new_vert->pos,(new_vert->left)->pos,vert->pos);
			//vec_eq(&(new_vert->pos), trace_endpos);

			vec_eq(&(vert->pos), last_vert_pos);


			//Check if the new vertex didn't move
			//if(vert->pos == new_vert->pos)
			/*{
				print("Subdivided vertex did not move, subdivision undone\n");
				//Undo the subdivision
				vert->left = new_vert->left;
				(new_vert->left)->right = vert;

				cl_navgen_free_vert(new_vert);
			}
			else
			{
				//cl_navgen_gen_floodfill(vert);
			}*/

			return;
		}

		//check if right edge was obstructed
		//print("Checking vert to right edge\n");
		if(cl_navgen_obstructed(vert->pos,(vert->right)->pos))
		{
			print("Right edge obstructed.\n");

			//Subdivide the right edge
			//Insert the new vertex at our last vertex position
			new_vert = cl_navgen_new_vert(last_vert_pos);

			new_vert->right = vert->right;
			(vert->right)->left = new_vert;
			new_vert->left = vert;
			vert->right = new_vert;

			//Getting the vertex as close to the corner as possible
			cl_navgen_find_min(new_vert->pos,vert->pos,(new_vert->right)->pos);
			vec_eq(&(new_vert->pos), trace_endpos );

			vec_eq(&(vert->pos), last_vert_pos);

			//Check if the new vertex didn't move
			/*if(vert->pos == new_vert->pos)
			{
				print("Subdivided vertex did not move, subdivision undone\n");
				//Undo the subdivision
				vert->right = new_vert->right;
				(new_vert->right)->left = vert;

				cl_navgen_free_vert(new_vert);
			}
			else
			{
				//cl_navgen_gen_floodfill(vert);
			}*/

			return;
		}


		//check if we intersected with any other vertex edge
			//walk along the edge and see if we hit one of the verts
		//check if we hit any other vertex

		//Check if we moved but hit a dead end without obstruction
		if(!move)
		{
			//=========================
			//Subdivide left edge
			//=========================
			vector edge_center;
			vec_eq(&(edge_center), (vert->pos + (vert->left)->pos)/2 );

			if(cl_navgen_gen_walk_to_point(vert->pos,edge_center))
			{
				//This should always run
				vec_eq(&(edge_center), trace_endpos);

			}
			else
			{
				print("Warning: could not walk to vertex midpoint.\n");
			}

			new_vert = cl_navgen_new_vert(edge_center);
			new_vert->left = vert->left;
			(vert->left)->right = new_vert;
			new_vert->right = vert;
			vert->left = new_vert;

			//=========================
			//Subdivide right edge
			//=========================
			vec_eq(&(edge_center), (vert->pos + (vert->right)->pos)/2 );

			if(cl_navgen_gen_walk_to_point(vert->pos,edge_center))
			{
				//This should always run
				vec_eq(&(edge_center), trace_endpos );
			}
			else
			{
				print("Warning: could not walk to vertex midpoint.\n");
			}

			new_vert = cl_navgen_new_vert(edge_center);
			new_vert->right = vert->right;
			(vert->right)->left = new_vert;
			new_vert->left = vert;
			vert->right = new_vert;

			break;
		}
	}

	if(!did_move)
		return;

	//Call cl_navgen_gen_floodfill on left and right verts
	/*cl_navgen_gen_floodfill(vert->left);
	cl_navgen_gen_floodfill(vert->right);*/


	//if left / right edge was obstructed
		//regress to last unobstructed position
		//hone in on corner position,
		//etc...
}

//========================================= Navgen Task Division Code ===========================================

//Temp structs for work scheduling
//Types of work tasks to do

//===== Float values for whether or not to break up tasks =====
float navgen_segment_task_type_walk_vertex = 1;
//Whether or not to segment the outer loop
float navgen_segment_task_type_resolve_corner1 = 1;
//Whether or not to segment the inner loop
float navgen_segment_task_type_resolve_corner2 = 1;
//===== FLOAT VALUES FOR TASK TYPES =====
float navgen_task_type_walk_vertex = 1;
float navgen_task_type_resolve_corner = 3;

//===== STRUCTS FOR TASK TYPES =====
struct navgen_task_data_walk_vertex
{
	navgen_vertex* vert;

	float dir_specified;
	vector walk_dir;

	//data for continuing walk_vertex
	float is_cont;
	float did_move;
};

struct navgen_task_data_resolve_corner
{
	navgen_vertex* vert;

	//Data for task to call after finishing
	navgen_vertex* vert_to_walk;
	vector vert_walk_dir;

	//data for continuing resolve_corner
	float is_cont;
	float task_state;
	vector min;
	vector mid1;
	vector mid3;
	float minimized_mid1;
	float minimized_mid3;
};


//=================================
//Task forward declarations
void(navgen_task_data_walk_vertex* data) cl_navgen_do_task_walk_vert;
void(navgen_task_data_resolve_corner* data) cl_navgen_do_task_resolve_corner;
//=================================


//Generic struct
struct navgen_task_data
{
	//just a placeholder
	float nodata;
};

struct navgen_task
{
	float type;
	navgen_task_data* data;

	//Structs for the stack of tasks
	navgen_task* next;

	//temp for debug memory
	float id;
};

float navgen_task_ids;

navgen_task* navgen_tasks_root;

//Allocates a new task and inserts it into the stack at the root
navgen_task* cl_navgen_push_task(float task_type, navgen_task_data* task_data)
{
	navgen_task* new_task = memalloc(sizeof(navgen_task));

	new_task->id = navgen_task_ids++;

	new_task->type = task_type;
	new_task->data = task_data;

	new_task->next = navgen_tasks_root;
	navgen_tasks_root = new_task;

	return new_task;
}

navgen_task* cl_navgen_peek_task()
{
	return navgen_tasks_root;
}


//Pops the navgen task from the stack
//Removes the task from the stack, returns pointer to task
//DOES NOT ACTUALLY FREE THE TASK MEMORY
navgen_task* cl_navgen_pop_task()
{
	if(navgen_tasks_root == 0)
		return 0;

	navgen_task* task = navgen_tasks_root;
	navgen_tasks_root = task->next;
	task->next = 0;
	return task;
}

void cl_navgen_free_task(navgen_task* task)
{
	switch(task->type)
	{
		case navgen_task_type_walk_vertex:
		{
			memfree((navgen_task_data_walk_vertex*) task->data);
			break;
		}
		case navgen_task_type_resolve_corner:
		{
			memfree((navgen_task_data_resolve_corner*) task->data);
			break;
		}
		default:
			print("NavGen ERROR: attempted to clear task with unkown task type: ",ftos(task->type),"\n");
			break;
	}
	memfree(task);

}


//This function deletes everything from the stack and all of the data associated with it
void cl_navgen_clear_task_stack()
{
	print("Pre clear task stack.\n");
	while(navgen_tasks_root != 0)
	{
		navgen_task* task = cl_navgen_pop_task();
		cl_navgen_free_task(task);
	}
	print("Post clear task stack.\n");
}


//Checks to make sure we have not violated the navmesh generation invariant (that we can walk from a vertex to it's left & right neighbors)
//Returns 1 if true, 0 if false
float debug_check_invariants()
{
	navgen_vertex* vert = navgen_verts_root;

	//Don't render the invariant checks
	//float backup_auto_task = cl_navgen_auto_task;
	//cl_navgen_auto_task = 1;

	float invariant_violated = 0;

	while(vert)
	{
		//Check if we can walk from vert to vert->left
		if(!cl_navgen_gen_walk_to_point(vert->pos,(vert->left)->pos))
		{
			//Add debug hulls
			add_debug_hull(vert->pos,[1,1,1],[0,1,0],0.02);
			add_debug_hull(vert->pos,[0.01,0.01,1],[0,1,0],0.3);
			add_debug_hull((vert->left)->pos,[1,1,1],[1,0,0],0.02);
			add_debug_hull((vert->left)->pos,[0.01,0.01,1],[1,0,0],0.3);

			add_debug_line(vert->pos,(vert->left)->pos,[1,0,0]);

			//return 0; don't stop, check all verts
			invariant_violated = 1;
		}
		//Check if we can walk from vert to vert->right
		if(!cl_navgen_gen_walk_to_point(vert->pos,(vert->right)->pos))
		{
			//Add debug hulls
			add_debug_hull(vert->pos,[1,1,1],[0,1,0],0.02);
			add_debug_hull(vert->pos,[0.01,0.01,1],[0,1,0],0.3);
			add_debug_hull((vert->right)->pos,[1,1,1],[1,0,0],0.02);
			add_debug_hull((vert->right)->pos,[0.01,0.01,1],[1,0,0],0.3);

			add_debug_line(vert->pos,(vert->right)->pos,[1,0,0]);

			//return 0; don't stop, check all verts
			invariant_violated = 1;
		}

		vert = vert->next;
	}

	//cl_navgen_auto_task = backup_auto_task;

	if(invariant_violated)
		return 0;
	return 1;
}



//Removes the next task from the stack and delegates it to function depending on type
void cl_navgen_do_next_task()
{
	navgen_task* task = cl_navgen_pop_task();

	if(task == 0)
	{
		print("NavGen: Nothing to do.\n");
		return;
	}

	float type = task->type;

	switch(type)
	{
		case navgen_task_type_walk_vertex:
		{
			//print("dispatched walk vertex\n");
			cl_navgen_do_task_walk_vert((navgen_task_data_walk_vertex*) task->data);
			break;
		}
		case navgen_task_type_resolve_corner:
		{
			//print("dispatched resolve corner\n");
			cl_navgen_do_task_resolve_corner((navgen_task_data_resolve_corner*) task->data);
			break;
		}
		default:
			print("NavGen: unkown task type: ",ftos(type),"\n");
			break;
	}

	//TEMP DEBUG
	//at the end of each task performed, we shall check each vertex and make sure it's not obstructed with its neighbor vertices
	if(debug_check_invariants() == 0)
	{
		print("pre secondary task clear\n");
		cl_navgen_clear_task_stack();
		print("post secondary task clear\n");
		print("Error: invariant violated on task type ",ftos(type),"\n");
	}
	//TEMP DEBUG

	cl_navgen_free_task(task);
}


//If there is another task to do, calls cl_navgen_do_next_task
void cl_navgen_try_next_task()
{
	if(cl_navgen_peek_task() != 0)
	{
		cl_navgen_do_next_task();
	}
}


//Functions for scheduling walk vert
void cl_navgen_task_walk_vert(navgen_vertex* vert)
{
	navgen_task_data_walk_vertex* data = memalloc(sizeof(navgen_task_data_walk_vertex));
	data->vert = vert;
	data->dir_specified = 0;
	data->is_cont = 0;

	cl_navgen_push_task(navgen_task_type_walk_vertex, (navgen_task_data*) data);
}

//Functions for scheduling walk vert in a specified direction
void cl_navgen_task_walk_vert_in_dir(navgen_vertex* vert, vector dir)
{
	navgen_task_data_walk_vertex* data = memalloc(sizeof(navgen_task_data_walk_vertex));
	data->vert = vert;
	data->dir_specified = 1;
	vec_eq(&(data->walk_dir),dir);

	data->is_cont = 0;

	cl_navgen_push_task(navgen_task_type_walk_vertex, (navgen_task_data*) data);
}


//Function for scheduling a continue walk vert
void cl_navgen_task_cont_walk_vert(navgen_vertex* vert, vector dir, float did_move)
{
	navgen_task_data_walk_vertex* data = memalloc(sizeof(navgen_task_data_walk_vertex));
	data->vert = vert;
	data->dir_specified = 1;
	vec_eq(&(data->walk_dir),dir);
	data->did_move = did_move;
	data->is_cont = 1;

	cl_navgen_push_task(navgen_task_type_walk_vertex, (navgen_task_data*) data);
}

//Function for scheduling resolve corner
void cl_navgen_task_resolve_corner(navgen_vertex* vert, navgen_vertex* vert_to_walk, vector vert_walk_dir)
{
	navgen_task_data_resolve_corner* data = memalloc(sizeof(navgen_task_data_resolve_corner));
	data->vert = vert;

	data->vert_to_walk = vert_to_walk;
	vec_eq(&(data->vert_walk_dir), vert_walk_dir);

	data->is_cont = 0;

	cl_navgen_push_task(navgen_task_type_resolve_corner, (navgen_task_data*) data);
}

//Function for scheduling a continue resolve corner
void cl_navgen_task_cont_resolve_corner(navgen_vertex* vert, float task_state, vector min, vector mid1, vector mid3, float minimized_mid1, float minimized_mid3, navgen_vertex* vert_to_walk, vector vert_walk_dir)
{
	navgen_task_data_resolve_corner* data = memalloc(sizeof(navgen_task_data_resolve_corner));

	data->vert = vert;

	data->vert_to_walk = vert_to_walk;
	vec_eq(&(data->vert_walk_dir), vert_walk_dir);

	data->is_cont = 1;

	data->task_state = task_state;
	vec_eq(&(data->min),min);
	vec_eq(&(data->mid1),mid1);
	vec_eq(&(data->mid3),mid3);
	data->minimized_mid1 = minimized_mid1;
	data->minimized_mid3 = minimized_mid3;

	cl_navgen_push_task(navgen_task_type_resolve_corner, (navgen_task_data*) data);
}

//=====================================================================================================================

//Navgen task functions

//Incrementally walk vertex away from it's edges until it stops or our edges are obstructed
void cl_navgen_do_task_walk_vert(navgen_task_data_walk_vertex* data)
{
	navgen_vertex* vert = data->vert;

	//calculate direction from edges
	vector walk_dir = [0,0,0]; //take line tangent to line normalize(vert->right->pos - vert->left->pos)

	float walk_dist = 3;//how many qu to walk at each step

	float has_moved = 0;

	//If we are continuing a previous walk, use data from it
	if(data->is_cont)
	{
		has_moved = data->did_move;
	}
	//If walk direction is specified, use it, otherwise calculate it
	if(data->dir_specified)
	{
		vec_eq(&walk_dir, (data->walk_dir));
	}
	else
	{
		//Calculating walk_dir
		//===========================
		vector tangent;
		vec_eq(&(tangent),((vert->right)->pos - (vert->left)->pos));

		//Don't care about z-difference
		tangent_z = 0;
		vec_eq(&(tangent),normalize(tangent));


		//Getting edge normal
		walk_dir[0] = -tangent[1];
		walk_dir[1] = tangent[0];
		walk_dir *= walk_dist;


		//if walk_dir is zero vector, something is horribly wrong
		if(walk_dir == [0,0,0])
		{
			print("Navmesh generation Error: walk_dir is zero vector for vert at pos: ",vtos(vert->pos)," with edges ");
			if(vert->left)
				print("L: ",vtos((vert->left)->pos));
			else
				print("L: null");
			if(vert->right)
				print(" R: ",vtos((vert->right)->pos));
			else
				print(" R: null");
			print("\n");
			return;
		}
		//===========================
	}

	float move;

	vector last_vert_pos;

	navgen_vertex* new_vert;

	vector tentative_vert_pos;

	float iters = 0;

	//walk the vertex in the direction a small amount
	while(1)
	{
		if(iters++ > 9998)
		{
			print("Warning: walk vert runaway loop\n");
			return;
		}
		//Try walking a small amount forward
		vec_eq(&(last_vert_pos),vert->pos);

		move = cl_navgen_gen_walk(vert->pos,walk_dir);

		vec_eq(&tentative_vert_pos, trace_endpos);

		//(This check fixes issues with convex corners, i.e. we can walk to next vert pos, but cannot direct walk to it)
		//If we cannot direct walk to trace_endpos from vert->pos, we consider that the vert did not move
		//FIXME (1/2): this seems to have fixed concave corners, but we need to fix some other errors before verifying that this
		//FIXME (2/2): functions properly and handles wrapping around and corner-resolving those concave corners that we now avoid
		if(cl_navgen_obstructed(vert->pos, tentative_vert_pos))
		{
			//Don't move the vertex
			vec_eq(&tentative_vert_pos, vert->pos);
			move = 0;
			print("Warning: about to walk past a concave corner\n");
		}

		vec_eq(&(vert->pos),tentative_vert_pos);

		if(!move && !has_moved)
		{
			break;
		}
		has_moved = 1;

		float left_obstructed = cl_navgen_obstructed((vert->left)->pos,vert->pos);
		float right_obstructed = cl_navgen_obstructed(vert->pos,(vert->right)->pos);

		//check if left edge was obstructed
		if(left_obstructed)
		{
			print("Left edge obstructed.\n");

			//Subdivide the left edge
			//Insert the new vertex at our last vertex position
			new_vert = cl_navgen_new_vert(last_vert_pos);
			new_vert->left = vert->left;
			(vert->left)->right = new_vert;
			new_vert->right = vert;
			vert->left = new_vert;

			//Getting the vertex as close to the corner as possible
			cl_navgen_task_resolve_corner(new_vert,vert,walk_dir);
		}

		//check if right edge was obstructed
		if(right_obstructed)
		{
			print("Right edge obstructed.\n");
			//Doing a debug invariant check on right edge
			print("Pre-subdivision checks: \n");
			print("Vert to right obstructed: ",ftos(cl_navgen_obstructed(vert->pos,(vert->right)->pos)),"\n");
			print("Vert to left obstructed: ",ftos(cl_navgen_obstructed((vert->left)->pos,vert->pos)),"\n");
			print("right to right's right obstructed: ",ftos(cl_navgen_obstructed((vert->right)->pos,((vert->right)->right)->pos)),"\n");


			//Subdivide the right edge
			//Insert the new vertex at our last vertex position
			new_vert = cl_navgen_new_vert(last_vert_pos);

			new_vert->right = vert->right;
			(vert->right)->left = new_vert;
			new_vert->left = vert;
			vert->right = new_vert;

			//Getting the vertex as close to the corner as possible
			cl_navgen_task_resolve_corner(new_vert,vert,walk_dir);

			//Doing a debug invariant check on right edge
			print("Post-subdivision checks: \n");
			print("Vert to right obstructed: ",ftos(cl_navgen_obstructed(vert->pos,(vert->right)->pos)),"\n");
			print("Vert to left obstructed: ",ftos(cl_navgen_obstructed((vert->left)->pos,vert->pos)),"\n");
			print("right to right's right obstructed: ",ftos(cl_navgen_obstructed((vert->right)->pos,((vert->right)->right)->pos)),"\n");

		}

		if(left_obstructed || right_obstructed)
			return;

		//check if we intersected with any other vertex edge
			//walk along the edge and see if we hit one of the verts
		//check if we hit any other vertex

		//Check if we moved but hit a dead end without obstruction
		if(!move)
		{
			//FIXME: this is so we don't keep subdividing the navmesh
			//return;
			//=========================
			//Subdivide left edge
			//=========================

			//Insert the new vertex at the midpoint between vert and vert's left vert
			cl_navgen_calc_midpoint(vert->pos, (vert->left)->pos);
			navgen_vertex* new_left_vert = cl_navgen_new_vert(trace_endpos);
			new_left_vert->left = vert->left;
			(vert->left)->right = new_left_vert;
			new_left_vert->right = vert;
			vert->left = new_left_vert;

			//=========================
			//Subdivide right edge
			//=========================

			//Insert the new vertex at the midpoint between vert and vert's left vert
			cl_navgen_calc_midpoint(vert->pos, (vert->right)->pos);
			navgen_vertex* new_right_vert = cl_navgen_new_vert(trace_endpos);
			new_right_vert->right = vert->right;
			(vert->right)->left = new_right_vert;
			new_right_vert->left = vert;
			vert->right = new_right_vert;


			//Add task to walk right vertex out
			cl_navgen_task_walk_vert(new_right_vert);
			//Add task to walk left vertex out
			cl_navgen_task_walk_vert(new_left_vert);

			break;
		}

		//If we are segmenting walk vertex task, only do a small walk per task
		if(navgen_segment_task_type_walk_vertex)
		{
			//Add a task to continue walking the vertex
			cl_navgen_task_cont_walk_vert(vert,walk_dir,has_moved);
			return;
		}

	}

	if(!has_moved)
		return;

	//Call cl_navgen_gen_floodfill on left and right verts
	/*cl_navgen_gen_floodfill(vert->left);
	recursive_depth--;
	recursive_depth++;
	cl_navgen_gen_floodfill(vert->right);*/


	//if left / right edge was obstructed
		//regress to last unobstructed position
		//hone in on corner position,
		//etc...
}

//Assumes data->vert is not obstructed to its left/right verts, and its left/right verts are obstructed to each other
//Assigns data->vert's position to the resolved corner
void cl_navgen_do_task_resolve_corner(navgen_task_data_resolve_corner* data)
{
	vector pos1, pos2, pos3;
	float mid1_minimized;
	float mid3_minimized;
	vector mid1;
	vector mid3;

	float find_min_state;
	vector min;

	navgen_vertex* vert = data->vert;

	vec_eq(&pos1, (vert->left)->pos);
	vec_eq(&pos2, vert->pos);
	vec_eq(&pos3, (vert->right)->pos);

	if(data->is_cont)
	{
		find_min_state = data->task_state;
		vec_eq(&min, data->min);
		vec_eq(&mid1, data->mid1);
		vec_eq(&mid3, data->mid3);
		mid1_minimized = data->minimized_mid1;
		mid3_minimized = data->minimized_mid3;
	}
	else
	{
		find_min_state = 0;
		vec_eq(&min,pos2);
		vec_eq(&mid1,pos1);
		vec_eq(&mid3,pos3);
		mid1_minimized = 0;
		mid3_minimized = 0;
	}


	float delta = 0.1;//how close does the min and max have to be for us to accept min as the desired point?

	float iters = 0;
	float iters2 = 0;

	//Temp vectors for assigning
	vector *edge;
	vector *mid_a;
	vector *mid_b;
	float *minimized;

	while(1)
	{
		if(iters++ >= 9999)
		{
			print("Warning: iters exceeded 9998\n");
			vec_eq(&trace_endpos,min);
			return;//fail
		}

		//mid1, pos3
		//Subdivide min to mid_a until we can walk to mid_a from edge
		if(find_min_state == 0)
		{
			edge = &pos3;
			mid_a = &mid1;
			mid_b = &mid3;
			minimized = &mid1_minimized;
			find_min_state = 1;
		}
		else
		{
			edge = &pos1;
			mid_a = &mid3;
			mid_b = &mid1;
			minimized = &mid3_minimized;
			find_min_state = 0;
		}

		iters2 = 0;

		*minimized = 0;

		while(1)
		{
			if(iters2++ >= 9999)
			{
				print("Warning iters2 exceeded 9998 on ",ftos(find_min_state),"\n");
				return;//fail
			}

			//Check if mid1 and min are so close that we have minimized this edge
			if(xy_vlen(*mid_a - min) < delta)
			{
				*minimized = 1;
				vec_eq(mid_b,*edge);
				print("\tMinimized: ",ftos(1+(find_min_state*2)),"\n");

				if(!cl_navgen_auto_task)
				{
					add_debug_hull(*mid_a,[1,1,1],[0,1,0],0.02);
					add_debug_hull(*mid_a,[0.01,0.01,1],[0,1,0],0.2);
					add_debug_hull(min,[1,1,1],[0,0,1],0.02);
					add_debug_hull(min,[0.01,0.01,1],[0,0,1],0.2);
				}

				break;
			}

			//if we can walk from mid1 to pos3, stop minimizing
			if(!cl_navgen_obstructed(*mid_a,*edge))
			{
				vec_eq(mid_b,*edge);
				vec_eq(&(min),*mid_a);
				vec_eq(&(vert->pos),min);

				//Debug invariant checks:
				print("minimized subdivision checks: \n");
				print("Vert to right obstructed: ",ftos(cl_navgen_obstructed(vert->pos,(vert->right)->pos)),"\n");
				print("right to right's right obstructed: ",ftos(cl_navgen_obstructed((vert->right)->pos,((vert->right)->right)->pos)),"\n");
				print("Vert to left obstructed: ",ftos(cl_navgen_obstructed((vert->left)->pos,vert->pos)),"\n");
				print("left to left's left obstructed: ",ftos(cl_navgen_obstructed((vert->left)->pos,((vert->left)->left)->pos)),"\n");

				if(!cl_navgen_auto_task)
				{
					add_debug_hull_line(*mid_a,*edge,[1,1,0]);
				}

				break;
			}

			//Subdivide
			float debug_result = cl_navgen_calc_midpoint(min,*mid_a);
			if(debug_result == 0)
			{
				print("Warning: Resolve Corner error: calc_midpoint failed.\n");

				debug_walk_to_point = 1;
				debug_direct_walk = 1;
				cl_navgen_calc_midpoint(min,*mid_a);
				debug_walk_to_point = 0;
				debug_direct_walk = 0;


				//add_debug_hull(min,[1,1,1],[0,1,0],0.2);
				//add_debug_hull(*mid_a,[1,1,1],[1,0,0],0.2);
				//add_debug_hull(trace_endpos,[1,1,0.5],[0,0,1],0.2);

				//Purging the task stack so we stop here
				print("pre preliminary task clear\n");
				cl_navgen_clear_task_stack();
				print("post preliminary task clear\n");


				//TODO: do a more in-depth debug to figure out why calc_midpoint is failing in this case.
				return;
			}
			vec_eq(mid_a,trace_endpos);


			//If we are segmenting the inner loop, tell this to stop and resume from here
			if(navgen_segment_task_type_resolve_corner2)
			{
				//Make sure we continue this same loop (revert find_min_state)
				find_min_state = (find_min_state == 0) ? 1 : 0;
				cl_navgen_task_cont_resolve_corner(vert,find_min_state,min,mid1,mid3,mid1_minimized,mid3_minimized,data->vert_to_walk,data->vert_walk_dir);
				return;
			}
		}

		//Check if we are done
		if(mid1_minimized && mid3_minimized)
		{
			if(!cl_navgen_auto_task)
			{
				add_debug_hull(pos1,[1,1,1],[1,0,0],0.02);
				add_debug_hull(pos1,[0.01,0.01,1],[1,0,0],0.2);
				add_debug_hull(min,[1,1,1],[0,1,0],0.02);
				add_debug_hull(min,[0.01,0.01,1],[0,1,0],0.2);
				add_debug_hull(pos3,[1,1,1],[0,0,1],0.02);
				add_debug_hull(pos3,[0.01,0.01,1],[0,0,1],0.2);
			}
			vec_eq(&(vert->pos),min);
			cl_navgen_task_walk_vert_in_dir(data->vert_to_walk,data->vert_walk_dir);
			return;//success
		}

		//Segment outer loop
		if(navgen_segment_task_type_resolve_corner1)
		{
			cl_navgen_task_cont_resolve_corner(vert,find_min_state,min,mid1,mid3,mid1_minimized,mid3_minimized,data->vert_to_walk,data->vert_walk_dir);
			return;
		}
	}
}

//=====================================================================================================================


void cl_navmesh_gen_navmesh()
{
	debug_dir = debug_dir == 0 ? 1 : 0;
	debug_walk_printed = 0;
	cl_navgen_auto_task = 1;
	print("Pre start task clear\n");
	cl_navgen_clear_task_stack();
	print("Post start task clear\n");

	vector player_pos;

	vec_eq(&player_pos,getentity(player_localentnum, GE_ORIGIN));

	//Find floor pos at pos
	cl_navgen_gen_drop_to_floor(player_pos);
	//player_pos = trace_endpos;
	vec_eq(&player_pos,trace_endpos);

	float initial_tri_size = 10;//40 for test

	print("Navgen started at position: ",vtos(player_pos),"\n");
	/* player_pos_x = 130.861374;
	player_pos_y = -250.209213;
	player_pos_z = -159.968750; */

	navgen_vertex* v1 = cl_navgen_new_vert(player_pos + [0,initial_tri_size,0]);
	navgen_vertex* v2 = cl_navgen_new_vert(player_pos + [-initial_tri_size,-initial_tri_size,0]);
	navgen_vertex* v3 = cl_navgen_new_vert(player_pos + [initial_tri_size,-initial_tri_size,0]);

	v1->left = v2;
	v1->right = v3;

	v2->right = v1;
	v2->left = v3;

	v3->left = v1;
	v3->right = v2;

	cl_navgen_task_walk_vert(v1);
	//cl_navgen_gen_floodfill(v1);

	//TODO: add tasks to walk v2 and v3
}

//====================================================================================================================================
//============================================ Testing navmesh generation ============================================================
//====================================================================================================================================


//Duplicate of ai_physics_movement, but does the move in x-axis first then y-axis (for sliding along walls, etc)
/*
void() ai_component_wise_physics_movement =
{
	float max_step_size = 18;//max stair step size pulled straight from engine defs
	float max_slope = 10.4;//18/tan(60) = 10.4, the length of the triangle formed by the max walkable slope of 60 degrees, and the max step height

	vector goal_org;

	vector org = [self.origin_x, self.origin_y, self.true_org_z];

	vector delta_org;

	//Iterate over x-axis then y-axis
	for(float i = 0; i < 2; i++)
	{
		delta_org = [0,0,0];

		delta_org[i] = self.velocity[i] * frametime;

		goal_org = org + delta_org;

		//Push down from a step above goal org to find result position

		vector above_goal = goal_org + [0,0,max_step_size];
		vector below_goal = goal_org - [0,0,max_step_size];

		tracebox(above_goal,self.mins,self.maxs,below_goal,MOVE_NOMONSTERS,self);

		if(trace_allsolid)
			continue;

		if(trace_startsolid)
		{
			tracebox(goal_org,self.mins,self.maxs,below_goal,MOVE_NOMONSTERS,self);
			if(trace_allsolid || trace_startsolid)
				continue;
		}

		if(trace_fraction >= 1)
		{
			//We walked off of a ledge
			self.true_org_z = goal_org_z;
			setorigin(self,goal_org);
			self.flags &= ~FL_ONGROUND;
			continue;
		}

		self.origin_x = trace_endpos_x;
		self.origin_y = trace_endpos_y;
		self.true_org_z = trace_endpos_z;
		self.origin_z += 0.05*(self.true_org_z - self.origin_z);
		setorigin(self, self.origin);
		self.flags |= FL_ONGROUND;
	}
}

//TODO: change these methods to not actually move an entity, but to just check whether a move is possible (following these rules)
void() ai_physics_movement =
{
	if(self.think && self.nextthink < time)
	{
		self.think();
	}

	//Don't run movement on non-instantiated zombie ents
	if(strncmp(self.aistatus,"1"))
	{
		return;
	}

	if(self.health <= 0)
	{
		self.velocity.x = self.velocity.y = 0;
	}

	float max_step_size = 18;//max stair step size pulled straight from engine defs
	float max_slope = 10.4;//18/tan(60) = 10.4, the length of the triangle formed by the max walkable slope of 60 degrees, and the max step height

	vector goal_org;

	vector org = [self.origin_x, self.origin_y, self.true_org_z];


	if(!(self.flags & FL_ONGROUND))
	{
		self.velocity_z  -= self.gravity * sv_gravity * frametime;

		//Clamping to server terminal velocity (-sv_maxspeed -> sv_maxspeed)
		self.velocity_z = max(min(self.velocity_z, sv_maxspeed), -sv_maxspeed);

		goal_org = org + [0,0,self.velocity.z] * frametime;

		tracebox(org,self.mins,self.maxs,goal_org,MOVE_NOMONSTERS,self);

		//If falling and hit something
		if(self.velocity.z < 0 && trace_fraction < 1)
		{
			self.flags |= FL_ONGROUND;
		}

		self.true_org_z = trace_endpos_z;
		setorigin(self, trace_endpos);
		return;
	}

	//=======================================================================================================================================
	//This code is a translated version of dquake's step movetype

	goal_org = org + self.velocity * frametime;

	//Push down from a step above goal org to find result position

	vector above_goal = goal_org + [0,0,max_step_size];
	vector below_goal = goal_org - [0,0,max_step_size];

	tracebox(above_goal,self.mins,self.maxs,below_goal,MOVE_NOMONSTERS,self);

	if(trace_allsolid)
	{
		//Try sliding along walls
		ai_component_wise_physics_movement();
		return;
	}

	if(trace_startsolid)
	{
		tracebox(goal_org,self.mins,self.maxs,below_goal,MOVE_NOMONSTERS,self);
		if(trace_allsolid || trace_startsolid)
		{
			//Try sliding along walls
			ai_component_wise_physics_movement();
			return;
		}
	}

	if(trace_fraction >= 1)
	{
		//We walked off of a ledge
		self.true_org_z = goal_org_z;
		setorigin(self,goal_org);
		self.flags &= ~FL_ONGROUND;
		return;
	}

	self.origin_x = trace_endpos_x;
	self.origin_y = trace_endpos_y;
	self.true_org_z = trace_endpos_z;
	//Lerping z-height:
	self.origin_z += 0.05*(self.true_org_z - self.origin_z);

	setorigin(self, self.origin);


	self.flags |= FL_ONGROUND;
	//=======================================================================================================================================
};
*/

void cl_navgen_print_testwalk_func()
{
	print("Current testwalk func: [",ftos(cl_navgen_render_test_walk_function),"], ");
	switch(cl_navgen_render_test_walk_function)
	{
		case 0:
			print("cl_navgen_gen_walk");
			break;
		case 1:
			print("cl_navgen_gen_direct_walk");
			break;
		case 2:
			print("cl_navgen_gen_walk_to_point");
			break;
		case 3:
			print("cl_navgen_obstructed");
			break;
		case 4:
			print("cl_navgen_calc_midpoint");
			break;
		case 5:
			print("cl_navgen_gen_walk_to_midpoint");
			break;
		default:
			return;
	}
	print("\n");
}

/*
float cl_navgen_render_test_walk_function;
float cl_navgen_render_test_walk_radius;

void cl_navgen_render_test_walk()
{
	//Walk functions:
	//1	float cl_navgen_gen_walk(vector start,vector ofs);			//0 for fail, 1 partial, 2 success
	//0	float cl_navgen_gen_direct_walk(vector start,vector ofs);		//0 for fail, 1 partial, 2 success
	//2	float cl_old_navgen_gen_direct_walk(vector start,vector ofs);		//0 for fail, 1 partial, 2 success
	//3	float cl_navgen_gen_walk_to_point(vector start, vector point);		//0 fail, 1 success
	//4	float cl_navgen_obstructed(vector pos1, vector pos2);			//0 unobstruced, 1 if either direction is obstructed
	//5	float cl_navgen_calc_midpoint(vector a, vector b);			//0 fail, 1 success
	//6	float cl_navgen_gen_walk_to_midpoint(vector start, vector point);	//0 fail, 1 success
*/

void cl_navgen_register_commands()
{
	registercommand("navgen_tw_next");
	registercommand("navgen_tw_prev");
	registercommand("navgen_tw_grow");
	registercommand("navgen_tw_shrink");
	registercommand("navgen_tw_place_ent");
	registercommand("navgen_tw_place_start");
	registercommand("navgen_toggle_auto_task");
	registercommand("navgen_next_task");

}
float cl_navgen_console_commands(string cmd) =
{
	tokenize(cmd);
	switch(argv(0))
	{
		case "navgen_toggle_auto_task":
			cl_navgen_auto_task = (cl_navgen_auto_task == 1) ? 0 : 1;
			break;
		case "navgen_next_task":
			clear_debug_hulls();
			clear_debug_lines();
			cl_navgen_try_next_task();
			break;
		case "navgen_tw_next":
			cl_navgen_render_test_walk_function = ( cl_navgen_render_test_walk_function + 1 ) % 6;
			cl_navgen_print_testwalk_func();
			return TRUE;
		case "navgen_tw_prev":
			cl_navgen_render_test_walk_function = ( cl_navgen_render_test_walk_function - 1 ) % 6;
			if(cl_navgen_render_test_walk_function < 0)//negative modulus doesn't work????
				cl_navgen_render_test_walk_function += 6;
			cl_navgen_print_testwalk_func();
			return TRUE;
		case "navgen_tw_grow":
			cl_navgen_render_test_walk_radius += 5;
			print("Testwalk radius: ",ftos(cl_navgen_render_test_walk_radius),"\n");
			return TRUE;
		case "navgen_tw_shrink":
			if(cl_navgen_render_test_walk_radius > 5)
				cl_navgen_render_test_walk_radius -= 5;
			print("Testwalk radius: ",ftos(cl_navgen_render_test_walk_radius),"\n");
			return TRUE;
		case "navgen_tw_place_ent":
			{
				//Set cl_navgen_render_test_walk_goal to player pos
				vector player_pos;
				vec_eq(&player_pos, getentity(player_localentnum, GE_ORIGIN));
				//Find floor at pos
				cl_navgen_gen_drop_to_floor(player_pos);
				vec_eq(&cl_navgen_render_test_walk_goal,trace_endpos);
				return TRUE;
			}
		case "navgen_tw_place_start":
			{
				//Set cl_navgen_render_test_walk_goal to player pos
				vector player_pos2;
				vec_eq(&player_pos2, getentity(player_localentnum, GE_ORIGIN));
				//Find floor at pos
				cl_navgen_gen_drop_to_floor(player_pos2);
				vec_eq(&cl_navgen_render_test_walk_start,trace_endpos);
				cl_navgen_render_test_walk_start_placed = 1;
				return TRUE;
			}
		default:
			break;
	}
	return FALSE;
}
