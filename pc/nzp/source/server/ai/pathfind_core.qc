//===========================================================================================================
//==================================== Navmesh-based Pathfinding Functions ==================================
//===========================================================================================================

//Calculates the heuristic h score value (Our best guess for how far this node is from the goal node)
float sv_pathfind_calc_h_score(float current, float goal)
{
	//FIXME: we could just as easily return vlen()^2 for comparisons... (saves a sqrt operation)
	return vlen(sv_navmesh_polies[goal].center - sv_navmesh_polies[current].center);
}

//Returns the polygon with the lowest f score from polygons the open set
float sv_pathfind_get_lowest_f_score(pathfind_result* res)
{
	//TODO: implement a better algorithm for finding the lowest score
	float best_score = 100000;
	float best_score_index = -1;
	
	for(float i = 0; i < sv_navmesh_poly_count; i++)
	{
		if(res->poly_set[i] == PATHFIND_POLY_SET_OPEN)
		{
			if(res->poly_f_score[i] < best_score)
			{
				best_score = res->poly_f_score[i];
				best_score_index = i;
			}
		}
	}
	return best_score_index;
}

void sv_pathfind_clear_result_data(pathfind_result* res)
{
	//Technically we only need to iterate over navmesh_poly_count...
	for(float i = 0; i < NAV_MAX_POLIES; i++)
	{
		res->poly_set[i] = PATHFIND_POLY_SET_NONE;
		res->poly_prev[i] = -1;
		res->poly_g_score[i] = 0;
		res->poly_f_score[i] = 0;
		res->result_node_path[i] = -1;
		
		res->result_path[i].x = 0;
		res->result_path[i].y = 0;
		res->result_path[i].z = 0;
		
		res->portals_right_vert[i] = -1;
		res->portals_left_vert[i] = -1;
	}
	res->result_node_length = 0;
	res->result_length = 0;
	res->portals_length = 0;
}

//Applies a funnel algorithm to the path defined by the array res->result_node_path 
// and populates pathfind result path
void sv_pathfind_smooth_path(vector start_point, vector goal_point, pathfind_result* res)
{
	//Evaluate portals and identify left / right portal vertices
	for(float i = 1; i < res->result_node_length; i++)
	{
		float prev_poly = res->result_node_path[i-1];
		float poly = res->result_node_path[i];
		
		//TODO: find link index of portal
		
		//Finding what index prev_poly is linked to poly
		
		float link_index = -1;
		
		for(float j = 0; j < sv_navmesh_polies[prev_poly].connected_polies_count; j++)
		{
			if(sv_navmesh_polies[prev_poly].connected_polies[j] == poly)
			{
				link_index = j;
				break;
			}
		}
		
		//Use that index to get left and right vertices
		res->portals_left_vert[res->portals_length] = sv_navmesh_polies[prev_poly].connected_polies_left_vert[link_index];
		res->portals_right_vert[res->portals_length++] = sv_navmesh_polies[prev_poly].connected_polies_right_vert[link_index];
	}
	//the last left edge / right edge is the goal position
	
	/*print("Portals: ");
	for(float i = 0; i < res->portals_length; i++)
	{
		print("[");
		print(ftos(i));
		print("] = (");
		print(ftos(res->portals_left_vert[i]));
		print(" , ");
		print(ftos(res->portals_right_vert[i]));
		print(") , ");
	}*/
	
	//starting at start_pos (not at start center point)
	//get vectors that point to first left edge and first right edge
	
	vector funnel_apex = start_point;
	float funnel_left_index = 0;
	//Index of the funnel's left vertex in the portal list
	vector funnel_left = sv_navmesh_verts[res->portals_left_vert[0]].pos;
	//Index of the funnel's right vertex in the portal list
	float funnel_right_index = 0;
	vector funnel_right = sv_navmesh_verts[res->portals_right_vert[0]].pos;
	
	vector next_funnel_left;
	vector next_funnel_right;
	
	
	float inside_right_edge;
	float inside_left_edge;
	
	while(1)
	{
		//print("=============Funnel iteration.==========\n");
		//Check if we have reached the end of the portals, consider the goal position as the last portal
		//If we are not at the last index of the left portal
		
		//Keeping track of whether or not advancing the left edge or right edge narrows the funnel
		float advanced_left = FALSE;
		float advanced_right = FALSE;
		
		
		
		//Consider the end goal point as the last portal
		//================ Checking left funnel edge =================
		if(funnel_left_index < res->portals_length)
		{
			//print("Trying to advance left edge.\n");
			
			if(funnel_left_index < res->portals_length - 1)
			{
				next_funnel_left = sv_navmesh_verts[res->portals_left_vert[funnel_left_index+1]].pos;
			//	print("Next left edge is vert: ",ftos(res->portals_left_vert[funnel_left_index+1],".\n");
			}
			else
			{
			//	print("Trying next left edge as goal point.\n");
				//If funnel_left is pointing to the last portal in the array, consider the goal_point the last portal
				next_funnel_left = goal_point;
			}

			inside_right_edge = pathfind_point_is_to_left(funnel_apex,funnel_right,next_funnel_left);
			//If the next left edge crosses the current right edge
			if(inside_right_edge < 0)
			{
				//print("next left edge crosses current right edge.\n");
				//Add funnel right point to path
				res->result_path[res->result_length++] = funnel_right;
				
				//Check if we are at the end of our portal list
				if(funnel_right_index >= res->portals_length - 1)
				{
					res->result_path[res->result_length++] = goal_point;
					return;
				}
				
				
				//Restart algorithm with the portal after the right point
				funnel_apex = funnel_right;
				
				funnel_left_index = funnel_right_index + 1;
				funnel_left = sv_navmesh_verts[res->portals_left_vert[funnel_left_index]].pos;
				funnel_right_index = funnel_right_index + 1;
				funnel_right = sv_navmesh_verts[res->portals_right_vert[funnel_right_index]].pos;
				continue;
			}
			//If the next left edge is in the funnel
			inside_left_edge = pathfind_point_is_to_left(funnel_left,funnel_apex,next_funnel_left);
			if(inside_left_edge >= 0 && inside_right_edge >= 0)
			{
				//print("next left edge is in the funnel.\n");
				//Advance the left edge
				funnel_left = next_funnel_left;
				funnel_left_index++;
				
				advanced_left = TRUE;
				
				//Check if the portal we just added was the goal point (will be after the list)
				if(funnel_left_index >= res->portals_length)
				{
					res->result_path[res->result_length++] = goal_point;
					return;
				}
			}
		}
		//================ Checking right funnel edge =================
		if(funnel_right_index < res->portals_length)
		{
			//print("Trying to advance right edge:.\n");
			
			if(funnel_right_index < res->portals_length - 1)
			{
				next_funnel_right = sv_navmesh_verts[res->portals_right_vert[funnel_right_index+1]].pos;
				//print("Next right edge is vert: ",ftos(res->portals_right_vert[funnel_right_index+1]),".\n");
			}
			else
			{
				//print("Trying next right edge as goal point.\n");
				//If funnel_right is pointing to the last portal in the array, consider the goal_point the last portal
				next_funnel_right = goal_point;
			}
			
			//If the next right edge crosses the current left edge
			inside_left_edge = pathfind_point_is_to_left(funnel_left,funnel_apex,next_funnel_right);
			if(inside_left_edge < 0)
			{
				//print("next right edge crosses current left edge.\n");
				//Add funnel left point to path
				res->result_path[res->result_length++] = funnel_left;
				
				//Check if we are at the end of our portal list
				if(funnel_left_index >= res->portals_length - 1)
				{
					res->result_path[res->result_length++] = goal_point;
					return;
				}
				
				
				//Restart algorithm with the portal after the right point
				funnel_apex = funnel_left;
				
				funnel_right_index = funnel_left_index + 1;
				funnel_right = sv_navmesh_verts[res->portals_right_vert[funnel_right_index]].pos;
				funnel_left_index = funnel_left_index + 1;
				funnel_left = sv_navmesh_verts[res->portals_left_vert[funnel_left_index]].pos;
				continue;
			}
			//If the next right edge is in the funnel
			inside_right_edge = pathfind_point_is_to_left(funnel_apex,funnel_right,next_funnel_right);			
			if(inside_left_edge >= 0 && inside_right_edge >= 0)
			{
				//print("next right edge is in the funnel.\n");
				//Advance the left edge
				funnel_right = next_funnel_right;
				funnel_right_index++;
				
				advanced_right = TRUE;
				
				//Check if the portal we just added was the goal point (will be after the list)
				if(funnel_right_index >= res->portals_length)
				{
					res->result_path[res->result_length++] = goal_point;
					return;
				}
			}
		}
		if(advanced_left == FALSE && advanced_right == FALSE)
		{
			//print("Hit funnel freeze condition.\n");
			
			float left_vert = -1;
			float left_type;
			float left_portal_index;//index of the vertex in the list of portals
			
			float right_vert = -1;
			float right_type;
			float right_portal_index;//index of the vertex in the list of portals
			
			float crossed = 1;//Indicates the vert crossed the funnel
			float contained = 2;//Indicates a vert is in the funnel
			
			float last_vert = -1;//used to skip calculating the same vertex more than once
			
			
			//Find the closest vertex in the portal left with the lowest index that crosses the funnel or is in the funnel
			for(float i = funnel_left_index + 1; i < res->portals_length + 1; i++)
			{
				if(i < res->portals_length - 1)
				{
					//Don't calculate the same vertex again
					if(last_vert == res->portals_left_vert[i])
						continue;
					last_vert = res->portals_left_vert[i];
					next_funnel_left = sv_navmesh_verts[last_vert].pos;
				}
				else//consider goal pos as last portal edge
				{
					next_funnel_left = goal_point;
				}
				
				inside_right_edge = pathfind_point_is_to_left(funnel_apex,funnel_right,next_funnel_left);
				
				//If the left vertex crosses the funnel (left vertex is outside the funnel's right edge)
				if(inside_right_edge < 0)
				{
					left_vert = res->portals_left_vert[i];
					left_type = crossed;
					break;
				}
				
				inside_left_edge = pathfind_point_is_to_left(funnel_left,funnel_apex,next_funnel_left);
				
				//If the left vertex is within the funnel
				if(inside_left_edge >= 0 && inside_right_edge >= 0)
				{
					left_vert = res->portals_left_vert[i];
					left_type = contained;
					left_portal_index = i;
					break;
				}
			}
			
			last_vert = -1;
			
			//Find the closest vertex in the portal right with the lowest index that crosses the funnel or is in the funnel
			for(float i = funnel_right_index + 1; i < res->portals_length; i++)
			{
				if(i < res->portals_length - 1)
				{
					//Don't calculate the same vertex again
					if(last_vert == res->portals_right_vert[i])
						continue;
					last_vert = res->portals_right_vert[i];
					next_funnel_right = sv_navmesh_verts[last_vert].pos;
				}
				else//consider goal pos as last portal edge
				{
					next_funnel_right = goal_point;
				}
				
				inside_left_edge = pathfind_point_is_to_left(funnel_left,funnel_apex,next_funnel_right);
				
				//If the right vertex crosses the funnel (right vertex is outside the funnel's left edge)
				if(inside_left_edge < 0)
				{
					right_vert = res->portals_right_vert[i];
					right_type = crossed;
					break;
				}
				
				inside_right_edge = pathfind_point_is_to_left(funnel_apex,funnel_right,next_funnel_right);
				
				//If the right vertex is within the funnel
				if(inside_left_edge >= 0 && inside_right_edge >= 0)
				{
					right_vert = res->portals_right_vert[i];
					right_type = contained;
					right_portal_index = i;
					break;
				}
			}
			
			//If no vertices were found, goal is reachable from here
			if(left_vert == -1 && right_vert == -1)
			{
				res->result_path[res->result_length++] = goal_point;
				return;
			}
			
			
			float use_left;
			
			//If both verts were found
			//Find which vertex has a lower index
			if(left_vert != -1 && right_vert != -1) 
			{
				if(left_portal_index < right_portal_index)
				{	
					use_left = TRUE;
				}
				else
				{	
					use_left = FALSE;
				}	
			}
			
			//if left vert was found
			else if(left_vert != -1)
			{
				use_left = TRUE;
			}
			//else right vert was found
			else
			{
				use_left = FALSE;
			}
			
			if(use_left)
			{
				if(left_type == crossed)
				{
					//Place corner at current right funnel edge
					res->result_path[res->result_length++] = funnel_right;
					
					//Restart algorithm with the portal after the right point
					funnel_apex = funnel_right;
					
					//Check if portal after this portal is goal:
					funnel_right_index++;
					if(funnel_right_index >= res->portals_length)
					{
						res->result_path[res->result_length++] = goal_point;
						return;
					}
					
					funnel_right = sv_navmesh_verts[res->portals_right_vert[funnel_right_index]].pos;
					funnel_left_index = funnel_right_index;
					funnel_left = sv_navmesh_verts[res->portals_left_vert[funnel_left_index]].pos;
					continue;
				}
				else//in funnel
				{
					//If the next funnel right is the goal, we are done
					//Check if portal after this portal is goal:
					if(right_portal_index >= res->portals_length)
					{
						res->result_path[res->result_length++] = goal_point;
						return;
					}
					//Update current left funnel edge to use this vertex
					funnel_left = next_funnel_left;
					funnel_left_index = left_portal_index;
					
					continue;
				}
			}
			else//use right
			{
				if(right_type == crossed)
				{
					//Place corner at current left funnel edge
					res->result_path[res->result_length++] = funnel_left;
					
					//Restart algorithm with the portal after the left point
					funnel_apex = funnel_left;
					
					//Check if portal after this portal is goal:
					funnel_left_index++;
					if(funnel_left_index >= res->portals_length)
					{
						res->result_path[res->result_length++] = goal_point;
						return;
					}
					
					funnel_left = sv_navmesh_verts[res->portals_left_vert[funnel_left_index]].pos;
					funnel_right_index = funnel_left_index;
					funnel_right = sv_navmesh_verts[res->portals_right_vert[funnel_right_index]].pos;
					continue;
				}
				else//in funnel
				{
					//If the next funnel right is the goal, we are done
					//Check if portal after this portal is goal:
					if(right_portal_index >= res->portals_length)
					{
						res->result_path[res->result_length++] = goal_point;
						return;
					}
					//Update current right funnel edge to use this vertex
					funnel_right = next_funnel_right;
					funnel_right_index = right_portal_index;
					
					continue;
				}
			}			
		}
	//print("==========================\n");
	}
}

//Evaluates the path that is found in the pathfinding algorithm and populates an array with the nodes in the path from start to goal
void sv_pathfind_trace_path(float start, float goal, pathfind_result* res)
{
	float current = start;
	//Count the length of the path (how many polygons the path traverses)
	current = goal;
	res->result_node_length = 1;
	do
	{
		//print("Poly ");
		//print(ftos(current));
		//print(" came from  ");
		//print(ftos(res->poly_prev[current]));
		//print(".\n");
		current = res->poly_prev[current];
		res->result_node_length++;
	} while(current != start);
	
	
	//Starting at goal waypoint, add the traversed waypoints to the result path in reverse order
	current = goal;
	for(float i = 0; i < res->result_node_length; i++)
	{
		res->result_node_path[res->result_node_length - 1 - i] = current;
		current = res->poly_prev[current];
	}
	
	print("Pathfind success, path length: ");
	print(ftos(res->result_node_length));
	print(".\n");
	
	print("Path: ");
	for(float i = 0; i < res->result_node_length; i++)
	{
		if(i > 0)
			print(" , ");
		print(ftos(res->result_node_path[i]));
	}
	print(" .\n");
}

//Accepts start polygon and goal polygon
//Returns 1 on success.
//Returns 0 on fail.
float sv_navmesh_pathfind_start(float start, float goal, vector start_pos, vector end_pos, pathfind_result* res)
{
	if(start == -1)
	{
		//print("Error: pathfind start node invalid.\n");
		return 0;
	}
	if(goal == -1)
	{
		//print("Error: pathfind goal node invalid.\n");
		return 0;
	}
	if(start == goal)
	{
		//Calculating node path
		res->result_node_path[0] = start;
		res->result_node_length = 1;
		print("Pathind success: trivial case (start = goal).\n");
		
		//Calculating vector based path (go directly to goal)
		res->result_path[0].x = end_pos.x;
		res->result_path[0].y = end_pos.y;
		res->result_path[0].z = end_pos.z;
		res->result_length = 1;
		return 1;
	}
	
	//Clearing previous data
	sv_pathfind_clear_result_data(res);
	
	//Adding start polygon to the open set
	res->poly_set[start] = PATHFIND_POLY_SET_OPEN;
	res->poly_g_score[start] = 0;
	res->poly_f_score[start] = 0 + sv_pathfind_calc_h_score(start , goal);
	
	//Fields that need to be set:
	//res->poly_set[NAV_MAX_POLIES];
	//res->prev_poly[NAV_MAX_POLIES];
	//res->poly_g_score[NAV_MAX_POLIES];
	//res->poly_f_score[NAV_MAX_POLIES];
	
	print("Pathfind init. Start: ");
	print(ftos(start));
	print(" , Goal: ");
	print(ftos(goal));
	print(".\n");
	
	float current = start;
	
	float pathfind_success = FALSE;
	
	while(current != -1)
	{
		if(current == goal)
		{
			//print("Current is now goal. Breaking.\n");
			pathfind_success = TRUE;
			break;
		}
		//Add current node to the closed set
		res->poly_set[current] = PATHFIND_POLY_SET_CLOSED;
		//Add connected nodes to the open set
		for(float i = 0; i < sv_navmesh_polies[current].connected_polies_count; i++)
		{
			float neighbor = sv_navmesh_polies[current].connected_polies[i];
			
			//print("Checking poly ");
			//print(ftos(current));
			//print("'s neighbor ");
			//print(ftos(neighbor));
			//print(".\n");
			
			if(res->poly_set[neighbor] != PATHFIND_POLY_SET_CLOSED)
			{
				//print("Neighbor is not in closed list.\n");
				//Calculate tentative f score
				//Calculate tentative g score (distance from start to current + distance from current to neighbor)
				float tentative_g_score = res->poly_g_score[current] + vlen(sv_navmesh_polies[neighbor].center - sv_navmesh_polies[current].center);
				
				if(res->poly_set[neighbor] != PATHFIND_POLY_SET_OPEN || tentative_g_score < res->poly_g_score[neighbor])
				{
					//print("Neighbor is not in open list, or a better g score has been found.\n");
					//Adding neighbor to open set
					res->poly_set[neighbor] = PATHFIND_POLY_SET_OPEN;
					
					//Updating scores for neighbor node
					float tentative_f_score = tentative_g_score + sv_pathfind_calc_h_score(neighbor , goal);
					res->poly_g_score[neighbor] = tentative_g_score;
					res->poly_f_score[neighbor] = tentative_f_score;
					
					//Linking neighbor node to current node (for tracing path)
					res->poly_prev[neighbor] = current;
					
					//print("Assigning Poly ");
					//print(ftos(neighbor));
					//print(" came from  ");
					//print(ftos(current));
					//print(".\n");
				}
				
			}
		}		
		
		current = sv_pathfind_get_lowest_f_score(res);
	}
	
	
	//Tracing the pathfind results
	if(pathfind_success == TRUE)
	{
		sv_pathfind_trace_path(start,goal,res);
		sv_pathfind_smooth_path(start_pos,end_pos,res);
		
		return 1;
	}
	print("Pathfind fail");
	return 0;
}

float sv_navmesh_pathfind(entity from, entity to)
{
	pathfind_result* res = &(sv_zombie_pathfind_result[from.index]);
	
	float start = sv_navmesh_get_containing_poly(from.origin);
	float goal = sv_navmesh_get_containing_poly(to.origin);
	
	return sv_navmesh_pathfind_start(start,goal,from.origin,to.origin,res);
}

//===========================================================================================================

//===========================================================================================================
//==================================== Waypoint-based Pathfinding Functions =================================
//===========================================================================================================
float Distance (vector from, vector to) {
	return vlen(from - to);
}

float HeuristicCostEstimate (float start_way, float end_way)
{
	//for now we will just look the distance between.
	return Distance(waypoints[start_way].org, waypoints[end_way].org);
}

void ReconstructPath(entity z, float start_way, float end_way) 
{

}

float open_first;
float open;
float closed_init;
float closed;
float closed_first;
void SV_WP_ClearSet()
{
	int i;

	for (i = 0; i < MAX_WAYPOINTS; i++)
	{
		waypoints[i].set = 0;
	}
}


float IsActive(float way) 
{
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

float Pathfind (entity z, float s_wp, float e_wp) 
{
	float current;
	float i, j;
	float bestf;


	if (s_wp == e_wp) 
	{
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
	while (waypoints[open_first].set == SET_OPEN) 
	{
		i = open_first;

		bestf = 320000;
		//print("Current ", ftos(current), "\n");

		// go from first open to last, pick the one with lowest f
		do
		{
			if (waypoints[i].f < bestf) 
			{
				current = i;
				bestf = waypoints[i].f;
			}
			i = waypoints[i].next;
		} while (i != open);

		// mark node as visited
		//print("Removing ", ftos(current), " from open\n");
		SV_WP_SetAdd(current, false);

		// we found a result, loop back with pathlength
		if (current == e_wp) 
		{
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

	for (i = 0; i < MAX_WAYPOINTS; i++) 
	{
		if (IsActive(i)) 
		{
			TraceResult = tracemove (from.origin, VEC_HULL_MIN, VEC_HULL_MAX, waypoints[i].org, TRUE ,from);
			if (TraceResult) 
			{
				dist = Distance(waypoints[i].org, from.origin);

				if(dist < best_dist) 
				{
					best_dist = dist;
					best = i;
				}
			}
		}
	}
	dist = 0;
	best_dist = 100000000;

	for (i = 0; i < MAX_WAYPOINTS; i++) 
	{
		if (IsActive(i)) 
		{
			TraceResult = tracemove (to.origin, VEC_HULL_MIN, VEC_HULL_MAX, waypoints[i].org, TRUE ,to);
			if (TraceResult) 
			{
				dist = Distance(waypoints[i].org, to.origin);

				if(dist < best_dist) 
				{
					best_dist = dist;
					best_target = i;
				}
			}
		}
	}

	//print("Starting waypoint: ", ftos(best)," Ending waypoint: ", ftos(best_target), "\n");




	return Pathfind(from, best, best_target);
}

void CalcDistances() {
	float i, s;

	for (i = 1; i < MAX_WAYPOINTS; i++) 
	{
		waypoint_ai way;
		way = waypoints[i];
		if (way.id > 0) 
		{
			for (s = 0; s < MAX_WAY_TARGETS; s++) 
			{
				float targ;
				targ = way.target_id[s];
				if (targ > 0) 
				{
					way.dist[s] = Distance(way.org, waypoints[targ].org);
				}
			}
		}
	}
}
			

void creator_way_touch();
void LoadWaypointData() 
{
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

	for (i = 0; i < MAX_WAYPOINTS; i++) 
	{
		waypoint_ai way;
		way = waypoints[i];
		way.org = '0 0 0';
		way.id = 0;
		way.g = 0;
		way.f = 0;
		way.set = 0;
		way.targetdoor = "";

		for (s = 0; s < MAX_WAY_TARGETS; s++) 
		{
			way.target_id[s] = 0;
			way.dist[s] = 0;
		}
	}

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
				} else {
					bprint(PRINT_HIGH, "Error: unknown point ", h, "\n");
				}
				break;
			case 1:
				if (h == "{") {
					point = 2;
				} else {
					bprint(PRINT_HIGH, "Error: unknown variable ", h, " expected {\n");
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
						bprint(PRINT_HIGH, "Error: unknown variable ", variable, "\n");
						break;
				}
				break;
			case 3:
				if (h == "[") {
					point = 4;
				} else {
					bprint(PRINT_HIGH, "Error: unknown variable ", h, " expected [\n");
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


	CalcDistances();
}