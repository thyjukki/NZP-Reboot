
//=================================================================================================================
//						Navmesh editing functions
//=================================================================================================================

#define NAV_MAX_SELECTED_VERTS 4
float selected_verts[NAV_MAX_SELECTED_VERTS];
float selected_vert_count;

navmesh_vertex cl_navmesh_verts[NAV_MAX_VERTS];
float cl_navmesh_vert_count;

navmesh_poly cl_navmesh_polies[NAV_MAX_POLIES];
float cl_navmesh_poly_count;


float cl_navmesh_place_corner_state;
#define NAVMESH_PLACE_CORNER_PLACING 1
#define NAVMESH_PLACE_CORNER_CONFIRM 2

//Pre-defs
void(vector pos, vector scale, vector color, float alpha) cl_navmesh_draw_test_ent;
void() cl_navmesh_delete_verts;
void(float poly_index) cl_navmesh_delete_poly_at_index;
float(vector pos) cl_navmesh_get_containing_poly;


//This is for placing a temp entity to test the pathfinding
vector goalent_pos;
float goalent_set;
vector startent_pos;
float startent_set;

void cl_navmesh_draw_box(vector pos,vector size, vector color, float alpha)
{
	//Assigning the shader as something else so that fte doesn't batch the calls (leading to colors not changing between draw calls)
	R_BeginPolygon("debug/wireframe",0);
	R_BeginPolygon("debug/solid_nocull",0);

	// Size is radius:
	size = size * 0.5;
	
	//bottom face
	R_PolygonVertex(pos + [-size.x,size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,-size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-size.x,-size.y,-size.z], [0,0,0], color,alpha);
	R_EndPolygon();
	//Top face
	R_PolygonVertex(pos + [-size.x,size.y,size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,size.y,size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,-size.y,size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-size.x,-size.y,size.z], [0,0,0], color,alpha);
	R_EndPolygon();
	//Front face
	R_PolygonVertex(pos + [-size.x,-size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,-size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,-size.y,size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-size.x,-size.y,size.z], [0,0,0], color,alpha);
	R_EndPolygon();
	//Back face
	R_PolygonVertex(pos + [-size.x,size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,size.y,size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-size.x,size.y,size.z], [0,0,0], color,alpha);
	R_EndPolygon();
	//Left face
	R_PolygonVertex(pos + [-size.x,-size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-size.x,size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-size.x,size.y,size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-size.x,-size.y,size.z], [0,0,0], color,alpha);
	R_EndPolygon();
	//Right face
	R_PolygonVertex(pos + [size.x,-size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,size.y,size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,-size.y,size.z], [0,0,0], color,alpha);
	R_EndPolygon();
}

void cl_navmesh_draw_vert(vector pos,vector color, float alpha)
{
	//Assigning the shader as something else so that fte doesn't batch the calls (leading to colors not changing between draw calls)
	R_BeginPolygon("debug/wireframe",0);
	R_BeginPolygon("debug/solid_nocull",0);
	
	//bottom face
	R_PolygonVertex(pos + [-5,5,-5], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [5,5,-5], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [5,-5,-5], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-5,-5,-5], [0,0,0], color,alpha);
	R_EndPolygon();
	//Top face
	R_PolygonVertex(pos + [-5,5,5], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [5,5,5], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [5,-5,5], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-5,-5,5], [0,0,0], color,alpha);
	R_EndPolygon();
	//Front face
	R_PolygonVertex(pos + [-5,-5,-5], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [5,-5,-5], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [5,-5,5], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-5,-5,5], [0,0,0], color,alpha);
	R_EndPolygon();
	//Back face
	R_PolygonVertex(pos + [-5,5,-5], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [5,5,-5], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [5,5,5], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-5,5,5], [0,0,0], color,alpha);
	R_EndPolygon();
	//Left face
	R_PolygonVertex(pos + [-5,-5,-5], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-5,5,-5], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-5,5,5], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-5,-5,5], [0,0,0], color,alpha);
	R_EndPolygon();
	//Right face
	R_PolygonVertex(pos + [5,-5,-5], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [5,5,-5], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [5,5,5], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [5,-5,5], [0,0,0], color,alpha);
	R_EndPolygon();
}

void cl_navmesh_draw_line(vector start, vector end, float edge_width, vector color, float alpha)
{
	R_BeginPolygon("debug/wireframe",0);
	R_BeginPolygon("debug/solid_nocull",0);
	
	R_PolygonVertex(end + [0,0,-edge_width], [0,0,0], color, alpha);
	R_PolygonVertex(end + [0,0,edge_width], [0,0,0], color, alpha);
	R_PolygonVertex(start + [0,0,edge_width], [0,0,0], color, alpha);
	R_PolygonVertex(start + [0,0,-edge_width], [0,0,0], color, alpha);
	R_EndPolygon();
}

void cl_navmesh_draw_edge(vector start, vector end)
{
	cl_navmesh_draw_line(start,end,2,[0.5,0.5,0.5],0.2);
}

void cl_navmesh_draw_quad(vector a, vector b, vector c, vector d, vector color, float alpha, int draw_edges)
{
	//Assigning the shader as something else so that fte doesn't batch the calls (leading to colors not changing between draw calls)
	R_BeginPolygon("debug/wireframe",0);
	R_BeginPolygon("debug/solid_nocull",0);
		
	R_PolygonVertex(a, [0,0,0], color, alpha);
	R_PolygonVertex(b, [0,0,0], color, alpha);
	R_PolygonVertex(c, [0,0,0], color, alpha);
	R_PolygonVertex(d, [0,0,0], color, alpha);
	R_EndPolygon();
	
	//Drawing polygon border
	if(draw_edges == TRUE)
	{
		cl_navmesh_draw_edge(a,b);
		cl_navmesh_draw_edge(b,c);
		cl_navmesh_draw_edge(c,d);
		cl_navmesh_draw_edge(d,a);
	}
}

void cl_navmesh_draw_tri(vector a, vector b, vector c, vector color, float alpha, int draw_edges)
{
//Assigning the shader as something else so that fte doesn't batch the calls (leading to colors not changing between draw calls)
	R_BeginPolygon("debug/wireframe",0);
	R_BeginPolygon("debug/solid_nocull",0);
	
	R_PolygonVertex(a, [0,0,0], color, alpha);
	R_PolygonVertex(b, [0,0,0], color, alpha);
	R_PolygonVertex(c, [0,0,0], color, alpha);
	R_EndPolygon();
	
	//Drawing polygon border
	if(draw_edges == TRUE)
	{
		cl_navmesh_draw_edge(a,b);
		cl_navmesh_draw_edge(b,c);
		cl_navmesh_draw_edge(c,a);
	}
}

void cl_navmesh_draw_poly(float poly_index)
{	
	vector face_color = [0.2,0.8,0.2];	
	float face_alpha = 0.1;
	
	vector a = cl_navmesh_verts[cl_navmesh_polies[poly_index].verts[0]].pos;
	vector b = cl_navmesh_verts[cl_navmesh_polies[poly_index].verts[1]].pos;
	vector c = cl_navmesh_verts[cl_navmesh_polies[poly_index].verts[2]].pos;

	if(cl_navmesh_polies[poly_index].vert_count == 3)
	{
		cl_navmesh_draw_tri(a,b,c,face_color,face_alpha,TRUE);
	}
	else
	{
		vector d = cl_navmesh_verts[cl_navmesh_polies[poly_index].verts[3]].pos;
		cl_navmesh_draw_quad(a,b,c,d,face_color,face_alpha,TRUE);
	}
}

float cl_navmesh_is_vert_selected(float vert_index)
{
	for(float i = 0; i < selected_vert_count; i++)
	{
		if(selected_verts[i] == vert_index)
			return TRUE;
	}
	return FALSE;
}


void() cl_navmesh_pathfind_draw_result_node_path;
void() cl_navmesh_pathfind_draw_result_portals;
void() cl_navmesh_pathfind_draw_result_path;


void cl_navmesh_editor_draw()
{
	//===================================================================================================
	//Debug logic of navmesh generation
	navgen_logic();
	//===================================================================================================

	//===================================================================================================
	// Debug rendering navmesh generation intermediate results
	// cl_navmesh_render_gen();
	//===================================================================================================
	
	
	for(float i = 0; i < cl_navmesh_vert_count; i++)
	{
		vector color = [0,0,1];
		if(cl_navmesh_is_vert_selected(i))
			color = [1,1,0];
			
		cl_navmesh_draw_vert(cl_navmesh_verts[i].pos,color,0.4 );
	}
	
	for(float i = 0; i < cl_navmesh_poly_count; i++)
	{
		cl_navmesh_draw_poly(i);
	}
	
	cl_navmesh_draw_test_ent(startent_pos, [1,1,1], [0,1,0], 0.4);
	cl_navmesh_draw_test_ent(goalent_pos, [1,1,1], [1,0,0], 0.4);
	
	cl_navmesh_pathfind_draw_result_node_path();
	cl_navmesh_pathfind_draw_result_portals();
	cl_navmesh_pathfind_draw_result_path();
	
	
	//The following code block is for detecting and placing waypoints at bsp map corners
	if(cl_navmesh_place_corner_state == NAVMESH_PLACE_CORNER_PLACING || cl_navmesh_place_corner_state == NAVMESH_PLACE_CORNER_CONFIRM)
	{
		
		//vector vorg = getentity(player_localentnum, GE_ORIGIN);
		//vector vorg = getviewprop(VF_ORIGIN) - VEC_VIEW_OFS;
		vector vorg = getviewprop(VF_ORIGIN);
		vector vang = getviewprop(VF_ANGLES);
	
		vector vang_left1 = vang + [0,6,0];//Two degrees to the left
		vector vang_left2 = vang + [0,5,0];//Three degrees to the left
		vector vang_right1 = vang + [0,-6,0];//Two degrees to the right
		vector vang_right2 = vang + [0,-5,0];//Three degrees to the right
		
		makevectors(vang);
		vector vang_fwd = v_forward;
		
		makevectors(vang_left1);
		vector vang_left1_fwd = v_forward;
		//Trace out to wall
		tracebox(vorg,VEC_HULL_MIN,VEC_HULL_MAX,vorg+(vang_left1_fwd * 2000),1,self);
		vector wall_hit_left1 = vorg+(vang_left1_fwd * 2000)*trace_fraction;
		//Trace down to ground
		tracebox(wall_hit_left1,VEC_HULL_MIN,VEC_HULL_MAX,wall_hit_left1+([0,0,-1] * 2000),1,self);
		
		vector hit_left1 = wall_hit_left1 + (([0,0,-1] * 2000) * trace_fraction);
		
		makevectors(vang_left2);
		vector vang_left2_fwd = v_forward;
		//Trace out to wall
		tracebox(vorg,VEC_HULL_MIN,VEC_HULL_MAX,vorg+(vang_left2_fwd * 2000),1,self);
		vector wall_hit_left2 = vorg+(vang_left2_fwd * 2000)*trace_fraction;
		//Trace down to ground
		tracebox(wall_hit_left2,VEC_HULL_MIN,VEC_HULL_MAX,wall_hit_left2+([0,0,-1] * 2000),1,self);
		
		vector hit_left2 = wall_hit_left2 + (([0,0,-1] * 2000) * trace_fraction);
		
		
		makevectors(vang_right1);
		vector vang_right1_fwd = v_forward;
		//Trace out to wall
		tracebox(vorg,VEC_HULL_MIN,VEC_HULL_MAX,vorg+(vang_right1_fwd * 2000),1,self);
		vector wall_hit_right1 = vorg+(vang_right1_fwd * 2000)*trace_fraction;
		//Trace down to ground
		tracebox(wall_hit_right1,VEC_HULL_MIN,VEC_HULL_MAX,wall_hit_right1+([0,0,-1] * 2000),1,self);
		
		vector hit_right1 = wall_hit_right1 + (([0,0,-1] * 2000) * trace_fraction);
		
		
		makevectors(vang_right2);
		vector vang_right2_fwd = v_forward;
		//Trace out to wall
		tracebox(vorg,VEC_HULL_MIN,VEC_HULL_MAX,vorg+(vang_right2_fwd * 2000),1,self);
		vector wall_hit_right2 = vorg+(vang_right2_fwd * 2000)*trace_fraction;
		//Trace down to ground
		tracebox(wall_hit_right2,VEC_HULL_MIN,VEC_HULL_MAX,wall_hit_right2+([0,0,-1] * 2000),1,self);
		
		vector hit_right2 = wall_hit_right2 + (([0,0,-1] * 2000) * trace_fraction);
		
		cl_navmesh_draw_vert(hit_left1, [0,0,1],0.4 );
		cl_navmesh_draw_vert(hit_left2, [0,0,1],0.4 );
		cl_navmesh_draw_vert(hit_right1, [0,0,1],0.4 );
		cl_navmesh_draw_vert(hit_right2, [0,0,1],0.4 );
		
		//TODO: draw walls that we have hit (2 flat planes on the walls we hit)
		
		//===================== Calculate the resolved vertex pos =======================
		//This solution only works for 90 degree corners
		
		//Line 1 extends from l1a in direction l1_dir
		/*vector l1a;
		l1a = hit_left2;
		vector l1_dir = normalize(hit_left1 - l1a);
		//The third point
		vector p2 = hit_right1;
		
		//Considering only l1_dir in the 2d plane of z=0
		
		vector vert_loc;
		vert_loc.z = l1a.z;
		
		//Is the line vertical?
		if(l1_dir.x == 0)//Is the line vertical?
		{
			vert_loc.x = l1a.x;
			vert_loc.y = p2.y;
			//FIXME
		}
		else if(l1_dir.y == 0)//Is the line horizontal?
		{
			vert_loc.x = p2.x;
			vert_loc.y = l1a.y;
			//FIXME
		}
		else
		{
			//Getting slope of line 1
			float m = (hit_left1.y - hit_left2.y) / (hit_left1.x - hit_left2.x);
			
			float x1 = p2.x - l1a.x;
			float y1 = p2.y - l1a.y;
			
			vert_loc.x = (x1 + m*y1)/(m*m + 1);
			vert_loc.y = (-1/m) * (vert_loc.x-x1) + y1;
		}
		
		vert_loc.x += l1a.x;
		vert_loc.y += l1a.y;*/
		
		
		//===============================================================================
		//This solution should work with any corner
		//===============================================================================
		
		//Line 1: hit_left1 -> hit_left2
		//Line 2: hit_right1 -> hit_right2
		vector vert_loc;
		
		float skew = 0;
		float horizontal = 1;
		float vertical = 2;
		
		float line_1_orient = skew;
		float line_2_orient = skew;
		
		//Check left wall is horizontal
		if(hit_left1.y == hit_left2.y)
		{
			line_1_orient = horizontal;
		}
		//Check if the left wall is vertical
		else if(hit_left1.x == hit_left2.x)
		{
			line_1_orient = vertical;
		}
		
		//Check if the right wall is horizontal
		if(hit_right1.y == hit_right2.y)
		{
			line_2_orient = horizontal;
		}
		//Check if the right wall is vertical
		else if(hit_right1.x == hit_right2.x)
		{
			line_2_orient = vertical;
		}
		
		//Checking if the lines are parallel and not skew
		if(line_1_orient == line_2_orient && line_1_orient != skew)
		{
			if(cl_navmesh_place_corner_state == NAVMESH_PLACE_CORNER_CONFIRM)
			{
				print("Cannot place corner for parallel walls (there is no corner).\n");
				cl_navmesh_place_corner_state = NAVMESH_PLACE_CORNER_PLACING;
			}
			return;
		}
		
		//Checking other special cases
		else if(line_1_orient == horizontal && line_2_orient == vertical)
		{
			vert_loc.x = hit_right1.x;
			vert_loc.y = hit_left1.y;
		}
		else if(line_1_orient == vertical && line_2_orient == horizontal)
		{
			vert_loc.x = hit_left1.x;
			vert_loc.y = hit_right1.y;
		}
		else if(line_1_orient == vertical)//line 2 is skew
		{
			vert_loc.x = hit_left1.x;
			//Plugging in vert_loc.x into equation of line 2 to get vert_loc.y
			//Slope of line 2
			float m2_a = (hit_right2.y - hit_right1.y)/(hit_right2.x - hit_right1.x);
			vert_loc.y = m2_a*(vert_loc.x - hit_right1.x) + hit_right1.y;
		}

		else if(line_2_orient == vertical)//line 1 is skew
		{
			vert_loc.x = hit_right1.x;
			//P;ugging in vert_loc.x into equation of line 1 to get vert_loc.y
			//Slope of line 1
			float m1_a = (hit_left2.y - hit_left1.y)/(hit_left2.x - hit_left1.x);
			vert_loc.y = m1_a*(vert_loc.x - hit_left1.x) + hit_left1.y;
		}
		else//Both lines are skew or horizontal
		{
			//Slope of line 1
			float m1 = (hit_left2.y - hit_left1.y)/(hit_left2.x - hit_left1.x);
			//Slope of line 2
			float m2 = (hit_right2.y - hit_right1.y)/(hit_right2.x - hit_right1.x);
			
			//Checking if the walls are parallel
			if(m1 == m2)
			{
				if(cl_navmesh_place_corner_state == NAVMESH_PLACE_CORNER_CONFIRM)
				{
					print("Cannot place corner for skew parallel walls (there is no corner).\n");
					cl_navmesh_place_corner_state = NAVMESH_PLACE_CORNER_PLACING;
				}
				return;
			}
			
			//Resolving the corner vertex location (this is derived from the solution of the two lines)
			vert_loc.x = ((m1 * hit_left1.x) - (m2 * hit_right1.x) + hit_right1.y - hit_left1.y) / (m1 - m2);
			//Plugging in vert_loc.x to the equation of the first line to get vert_loc.y
			vert_loc.y = m1*(vert_loc.x - hit_left1.x) + hit_left1.y;
		}
		
		//Placing the vert as the highest z-value
		float highest_z = hit_left1.z;
		
		if(hit_left2.z > highest_z)
			highest_z = hit_left2.z;
		if(hit_right1.z > highest_z)
			highest_z = hit_right1.z;
		if(hit_right2.z > highest_z)
			highest_z = hit_right2.z;
		vert_loc.z = highest_z;
		
		//Traceboxing down from that vert position to get actual height
		tracebox(vert_loc,VEC_HULL_MIN,VEC_HULL_MAX,vert_loc+([0,0,-1] * 2000),1,self);
		vert_loc.z = vert_loc.z + (-2000 * trace_fraction);
		
		
		//================================================================================
		
		//Render the resolved vertex pos
		cl_navmesh_draw_vert(vert_loc, [1,1,0],0.4 );
			
		if(cl_navmesh_place_corner_state == NAVMESH_PLACE_CORNER_CONFIRM)
		{	
			cl_navmesh_verts[cl_navmesh_vert_count].pos.x = vert_loc.x;
			cl_navmesh_verts[cl_navmesh_vert_count].pos.y = vert_loc.y;
			cl_navmesh_verts[cl_navmesh_vert_count].pos.z = vert_loc.z;
			
			cl_navmesh_vert_count++;
			
			cl_navmesh_place_corner_state = 0;
		}
		
	}
	
	//For using tracebox to place vertices
	/*vector vorg = getviewprop(VF_ORIGIN);
	vector vang = getviewprop(VF_ANGLES);
	
	makevectors(vang);
	
	//v_forward, v_right, v_up
	getviewprop(VF_ACTIVESEAT);
	
	//Tracebox out from there
	//Zombie dimensions
	tracebox(vorg,[-8,-8,-32],[8,8,30],vorg+(v_forward * 2000),1,self);
	
	
	//Tracebox down from there
	vector vpos1 = vorg+(v_forward*2000)*trace_fraction;
	cl_navmesh_draw_vert(vpos1, [0,0,1],0.4 );
	
	tracebox(vpos1,[-8,-8,-32],[8,8,30],vpos1+([0,0,-1] * 2000),1,self);
	vector vpos2 = vpos1+(([0,0,-1] * 2000) * trace_fraction);
	
	cl_navmesh_draw_vert(vpos2, [1,1,0],0.4 );*/
	
	//Tracebox down from there	
}

//Places a vertex at player position
void cl_navmesh_place_vert()
{
	if(cl_navmesh_vert_count >= cl_navmesh_verts.length)
	{
		print("Can't add vertex, max vert count has been reached.\n");
		return;
	}
	
	//Placing the vert at player origin
	vector vert_pos = getentity(player_localentnum, GE_ORIGIN);
	
	cl_navmesh_verts[cl_navmesh_vert_count].pos.x = vert_pos.x;
	cl_navmesh_verts[cl_navmesh_vert_count].pos.y = vert_pos.y;
	cl_navmesh_verts[cl_navmesh_vert_count].pos.z = vert_pos.z;

	print("Vertex ");
	print(ftos(cl_navmesh_vert_count));
	print(" created at ", vtos(vert_pos),"\n");
	
	cl_navmesh_vert_count++;
}

//Deletes all selected vertices
void cl_navmesh_delete_verts()
{
	if(selected_vert_count <= 0)
	{
		print("No vertices selected.\n");
		return;
	}
	
	for(float i = 0; i < selected_vert_count; i++)
	{
		float vert = selected_verts[i];
		print("Deleting vert: ");
		print(ftos(vert));
		print(".\n");
		//Check if vertex is in any polygons, if so delete that polygon
		for(float j = 0; j < cl_navmesh_poly_count; j++)
		{
			for(float k = 0; k < cl_navmesh_polies[j].vert_count; k++)
			{
				if(cl_navmesh_polies[j].verts[k] == vert)
				{
					cl_navmesh_delete_poly_at_index(j);	
					j -= 1;
					break;
			}
		}
		}
		
		
		//Bringing all vertices down to not leave any holes in the array
		//Moving down every index to the right of what we deselected to not leave any holes
		for(float j = vert; j < cl_navmesh_vert_count - 1; j++)
		{
			cl_navmesh_verts[j].pos.x = cl_navmesh_verts[j+1].pos.x;
			cl_navmesh_verts[j].pos.y = cl_navmesh_verts[j+1].pos.y;
			cl_navmesh_verts[j].pos.z = cl_navmesh_verts[j+1].pos.z;
		}
		//Clearing the last one
		cl_navmesh_verts[cl_navmesh_vert_count-1].pos = [0,0,0];
		cl_navmesh_vert_count--;
		
		
		//Fixing references to verts in all polygons
		for(float j = 0; j < cl_navmesh_poly_count; j++)
		{
			for(float k = 0; k < cl_navmesh_polies[j].vert_count; k++)
			{
				if(cl_navmesh_polies[j].verts[k] >= vert)
					cl_navmesh_polies[j].verts[k]--;
			}
		}
		//Fixing references of selected verts
		for(float j = i; j < selected_vert_count; j++)
		{
			if(selected_verts[j] >= vert)
				selected_verts[j]--;
		}
	}
	selected_vert_count = 0;
	for(float i = 0; i < selected_verts.length; i++)
	{
		selected_verts[i] = -1;
	}
}


//=================================== Navmesh vertex selection functions ===================================
//Returns index of the vertex that is nearest to the player
float cl_navmesh_get_nearest_vert()
{
	if(cl_navmesh_vert_count <= 0)
	{
		return -1;
	}
	
	vector player_pos = getentity(player_localentnum, GE_ORIGIN);
	float closest_dist = vlen(player_pos - cl_navmesh_verts[0].pos);
	float closest_index = 0;
	
	float temp_dist;
	
	for(float i = 1; i < cl_navmesh_vert_count; i++)
	{
		temp_dist = vlen(player_pos - cl_navmesh_verts[i].pos);
		
		if(temp_dist < closest_dist)
		{
			closest_dist = temp_dist;
			closest_index = i;
		}
	}
	return closest_index;
}

//Selects the nearest vertex
void cl_navmesh_select_vert()
{
	if(selected_vert_count >= selected_verts.length)
	{
		print("Can't select another vertex, max vertices selected.\n");
		return;
	}
	
	float vert = cl_navmesh_get_nearest_vert();
	if(vert == -1)
	{
		print("No vertices to select");
		return;
	}
	if(cl_navmesh_is_vert_selected(vert))
	{
		print("Vert is already selected.\n");
		return;
	}
	
	print("Vertex ");
	print(ftos(vert));
	print(" selected.\n");
	selected_verts[selected_vert_count++] = vert;
}


//Deselects the nearest vertex
void cl_navmesh_deselect_vert()
{
	float vert = cl_navmesh_get_nearest_vert();
	
	if(vert == -1)
	{
		print("No vertices to select.\n");
		return;
	}
	
	for(float i = 0; i < selected_vert_count; i++)
	{
		if(selected_verts[i] == vert)
		{
			selected_verts[i] = -1;
			
			//Moving down every index to the right of what we deselected to not leave any holes
			for(float j = i; j < selected_vert_count - 1; j++)
			{
				selected_verts[j] = selected_verts[j+1];
			}
			selected_verts[selected_vert_count - 1] = -1;
			selected_vert_count--;
			
			print("Vertex ");
			print(ftos(i));
			print(" deselected.\n");
			return;
		}
	}
	print("Vertex is not selected.\n");
}

//Deselects all vertices
void cl_navmesh_deselect_all()
{
	for(float i = 0; i < selected_verts.length; i++)
	{
		selected_verts[i] = -1;
	}
	selected_vert_count = 0;
	
	
	//print("All vertices deselected.\n");
}

//=============================================================================================================

float cl_navmesh_is_poly_selected()
{
	//Check if this polygon already exists
	float verts_selected[4];
	
	for(float i = 0; i < cl_navmesh_poly_count; i++)
	{
		verts_selected[0] = FALSE;
		verts_selected[1] = FALSE;
		verts_selected[2] = FALSE;
		verts_selected[3] = FALSE;
		
		//Check each of the poly's verts
		for(float j = 0; j < cl_navmesh_polies[i].vert_count; j++)
		{
			//Check each of our selected verts to see if they are in this polygon
			for(float k = 0; k < selected_vert_count; k++)
			{
				if(cl_navmesh_polies[i].verts[j] == selected_verts[k])
				{
					verts_selected[j] = TRUE;
				}
			}
			
			//This poly vert was not selected
			if(verts_selected[j] == FALSE)
			{
				break;
			}
		}
		
		if(cl_navmesh_polies[i].vert_count == 3)
		{
			if(verts_selected[0] == TRUE && verts_selected[1] == TRUE && verts_selected[2] == TRUE)
			{
				return TRUE;
			}
		}
		else if(cl_navmesh_polies[i].vert_count == 4)
		{
			if(verts_selected[0] == TRUE && verts_selected[1] == TRUE && verts_selected[2] == TRUE && verts_selected[3] == TRUE)
			{
				return TRUE;
			}
		}
	}
	return FALSE;
}


void cl_navmesh_make_poly()
{
	if(selected_vert_count < 3)
	{
		print("Not enough selected vertices to make a polygon (need 3).\n");
		return;
	}
	
	if(cl_navmesh_poly_count >= cl_navmesh_polies.length)
	{
		print("Max polygon count reached.\n");
		return;
	}
	
	if(cl_navmesh_is_poly_selected())
	{
		print("This polygon already exists.\n");
		return;
	}
	
	
	//Sorting the verts so the polygon is build consecutively (i.e. vert 0 -> vert 1 is an edge, 1->2, 2->3, and 3->0 are all edges)
	//Furthermore, this sorting will ensure the verts are sorted in a clockwise order, so we also apply it to tris
	
	
	//Printing all polygon vertices
	print("Selected Verts: [");
	for(float j = 0; j < selected_vert_count; j++)
	{
		print("(",ftos(j),", ",ftos(selected_verts[j]),", ",vtos(cl_navmesh_verts[selected_verts[j]].pos),") , ");
	}
	print("]\n\n");
	
	//Calculating center of the polygon
	local vector center = [0,0,0];
	for(float j = 0; j < selected_vert_count; j++)
	{
		center += cl_navmesh_verts[selected_verts[j]].pos;
	}
	center /= selected_vert_count;
	
	print("Center of selected polygon: ",vtos(center),".\n\n");
	
	float vert_angle[NAV_MAX_SELECTED_VERTS];
	
	//For suppressing uninitialised vert_angle compiler warning
	vert_angle[0] = 0;
	
	//Calculating vertex angles:
	for(float j = 0; j < selected_vert_count; j++)
	{
		//Calculating angle of vert
		vert_angle[j] = atan2(cl_navmesh_verts[selected_verts[j]].pos.y - center.y,cl_navmesh_verts[selected_verts[j]].pos.x - center.x);
	}
	
	//Sorting from least to greatest
	for(float j = 0; j < selected_vert_count; j++)
	{
		//Finding lowest value from j to selected_vert_count
		float lowest_value = vert_angle[j];
		float lowest_index = j;
		for(float k = j; k < selected_vert_count; k++)
		{
			if(vert_angle[k] < lowest_value)
			{
				lowest_value = vert_angle[k];
				lowest_index = k;
			}
		}
		//Swapping the lowest value with index j
		float temp_angle = vert_angle[j];
		vert_angle[j] = vert_angle[lowest_index];
		vert_angle[lowest_index] = temp_angle;
		
		float temp_vert = selected_verts[j];
		selected_verts[j] = selected_verts[lowest_index];
		selected_verts[lowest_index] = temp_vert;
	}
	
	//Vert angles
	print("Sorted Verts: [");
	for(float j = 0; j < selected_vert_count; j++)
	{
		print("(",ftos(j),", ",ftos(selected_verts[j]),", ",vtos(cl_navmesh_verts[selected_verts[j]].pos),") ,");
	}
	print("]\n\n");
	
	print("Sorted Vert angles: [");
	for(float j = 0; j < selected_vert_count; j++)
	{
		print(", ",ftos(vert_angle[j]));
	}
	print("]\n\n");
	
	
	

	for(float i = 0; i < selected_vert_count; i++)
	{
		cl_navmesh_polies[cl_navmesh_poly_count].verts[i] = selected_verts[i];
	}
	cl_navmesh_polies[cl_navmesh_poly_count].vert_count = selected_vert_count;
	cl_navmesh_poly_count++;
}

void cl_navmesh_delete_poly_at_index(float poly_index)
{
	//Starting at this polygon, move every polygon after in the array down one (leave no holes in the array)
	//Moving down every index to the right of what we deselected to not leave any holes
	for(float i = poly_index; i < cl_navmesh_poly_count - 1; i++)
	{
		cl_navmesh_polies[i].vert_count = cl_navmesh_polies[i+1].vert_count;
		for(float j = 0; j < cl_navmesh_polies[i].verts.length; j++)
		{
			cl_navmesh_polies[i].verts[j] = cl_navmesh_polies[i+1].verts[j];
		}
	}
	//Clearing the last one
	cl_navmesh_polies[cl_navmesh_poly_count-1].vert_count = 0;
	for(float j = 0; j < cl_navmesh_polies[cl_navmesh_poly_count-1].verts.length; j++)
	{
		cl_navmesh_polies[cl_navmesh_poly_count-1].verts[j] = -1;
	}
	cl_navmesh_poly_count--;
}

void cl_navmesh_delete_poly()
{
	float verts_selected[4];
	float poly_index = -1;
	//Find index of the polygon whose vertices are all selected
	for(float i = 0; i < cl_navmesh_poly_count; i++)
	{
		verts_selected[0] = FALSE;
		verts_selected[1] = FALSE;
		verts_selected[2] = FALSE;
		verts_selected[3] = FALSE;
		
		//Check each of the poly's verts
		for(float j = 0; j < cl_navmesh_polies[i].vert_count; j++)
		{
			//Check each of our selected verts to see if they are in this polygon
			for(float k = 0; k < selected_vert_count; k++)
			{
				if(cl_navmesh_polies[i].verts[j] == selected_verts[k])
				{
					verts_selected[j] = TRUE;
				}
			}
			
			//This poly vert was not selected
			if(verts_selected[j] == FALSE)
			{
				break;
			}
		}
		
		if(cl_navmesh_polies[i].vert_count == 3)
		{
			if(verts_selected[0] == TRUE && verts_selected[1] == TRUE && verts_selected[2] == TRUE)
			{
				poly_index = i;
				break;
			}
		}
		else if(cl_navmesh_polies[i].vert_count == 4)
		{
			if(verts_selected[0] == TRUE && verts_selected[1] == TRUE && verts_selected[2] == TRUE && verts_selected[3] == TRUE)
			{
				poly_index = i;
				break;
			}
		}
	}
	if(poly_index == -1)
	{
		print("A polygon is not selected.\n");
		return;
	}
	
	//Starting at this polygon, move every polygon after in the array down one (leave no holes in the array)
	//Moving down every index to the right of what we deselected to not leave any holes
	for(float i = poly_index; i < cl_navmesh_poly_count - 1; i++)
	{
		cl_navmesh_polies[i].vert_count = cl_navmesh_polies[i+1].vert_count;
		for(float j = 0; j < cl_navmesh_polies[i].verts.length; j++)
		{
			cl_navmesh_polies[i].verts[j] = cl_navmesh_polies[i+1].verts[j];
		}
	}
	//Clearing the last one
	cl_navmesh_polies[cl_navmesh_poly_count-1].vert_count = 0;
	for(float j = 0; j < cl_navmesh_polies[cl_navmesh_poly_count-1].verts.length; j++)
	{
		cl_navmesh_polies[cl_navmesh_poly_count-1].verts[j] = -1;
	}
	cl_navmesh_poly_count--;			
	print("Deleted polygon.\n");
}

//Treats 1st and 2nd selected verts as line 1, 3rd and 4th verts as line 2, places a new vertex at the intersection of these lines
void cl_navmesh_resolve_corner()
{
	if(selected_vert_count < 3)
	{
		print("You need to select at least 3 vertices to resolve a corner.\n");
		return;
	}
	
	//Line 1 extends from l1a in direction l1_dir
	vector l1a;
	l1a = cl_navmesh_verts[selected_verts[0]].pos;
	vector l1_dir = normalize(cl_navmesh_verts[selected_verts[1]].pos - l1a);
	//The third point
	vector p2 = cl_navmesh_verts[selected_verts[2]].pos;
	
	
	//Considering only l1_dir in the 2d plane of z=0
	
	vector vert_loc;
	vert_loc.z = l1a.z;
	
	//Is the line vertical?
	if(l1_dir.x == 0)//Is the line vertical?
	{
		vert_loc.x = l1a.x;
		vert_loc.y = p2.y;
	}
	else if(l1_dir.y == 0)//Is the line horizontal?
	{
		vert_loc.x = p2.x;
		vert_loc.y = l1a.y;
	}
	else
	{
		//Getting slope of line 1
		float m = l1_dir.y / l1_dir.x;
		
		float x1 = p2.x - l1a.x;
		float y1 = p2.y - l1a.y;
		
		vert_loc.x = (x1 + m*y1)/(m*m + 1);
		vert_loc.y = (-1/m) * (vert_loc.x-x1) + y1;
	}
	
	vert_loc.x += l1a.x;
	vert_loc.y += l1a.y;
	
	
	//Place a new vert at the location
	cl_navmesh_verts[cl_navmesh_vert_count].pos.x = vert_loc.x;
	cl_navmesh_verts[cl_navmesh_vert_count].pos.y = vert_loc.y;
	cl_navmesh_verts[cl_navmesh_vert_count].pos.z = vert_loc.z;
	
	print("Resolved corner with vertex ");
	print(ftos(cl_navmesh_vert_count));
	print(" at (");
	print(ftos(vert_loc.x));
	print(" , ");
	print(ftos(vert_loc.y));
	print(" , ");
	print(ftos(vert_loc.z));
	print(").\n");
	
	
	cl_navmesh_vert_count++;
}

void cl_navmesh_place_corner()
{
	cl_navmesh_place_corner_state = NAVMESH_PLACE_CORNER_PLACING;
}
void cl_navmesh_cancel_corner()
{
	cl_navmesh_place_corner_state = 0;
}
void cl_navmesh_confirm_corner()
{
	if(cl_navmesh_place_corner_state == NAVMESH_PLACE_CORNER_PLACING)
		cl_navmesh_place_corner_state = NAVMESH_PLACE_CORNER_CONFIRM;
}


void cl_navmesh_clear_connected_polies()
{
	for(float i = 0; i < cl_navmesh_poly_count; i++)
	{
		cl_navmesh_polies[i].connected_polies_count = 0;

		for(float j = 0; j < 4; j++)
		{
			cl_navmesh_polies[i].connected_polies[j] = -1;
			cl_navmesh_polies[i].connected_polies_left_vert[j] = -1;
			cl_navmesh_polies[i].connected_polies_right_vert[j] = -1;
		}
	}
}


void cl_navmesh_calc_connected_polies()
{
	cl_navmesh_clear_connected_polies();

	for(float i = 0; i < cl_navmesh_poly_count; i++)
	{
		for(float j = i + 1; j < cl_navmesh_poly_count; j++)
		{
			
			//Check if poly j shares an edge with poly i
			
			//Edge case: where two opposite corners (two corners not on the same edge) of a quad are shared with another poly
			//but this edge case is a result of terrible topology, so I will not consider it
			
			//Check if poly j shares at least 2 vertices with poly i
			//I'm not sure what sharing more than 2 verts means... but it's a result of bad topology, so I will not consider it
			//		if two quads share 4: they are the same 			-> bad topology
			//		if two quads share 3: one of them is convex, one is concave 	-> bad topology
			//		if a quad shares 3 with a tri: the tri is within the quad 	-> bad topology
			//		if two tris share 3: they are the same 				-> bad topology
			
			
			float shared_verts[2];
			shared_verts[0] = -1;
			shared_verts[1] = -1;
			float shared_verts_index[2];//The index of the vert in previous poly's vert list
			shared_verts_index[0] = -1;
			shared_verts_index[1] = -1;
			float verts_found = 0;
				
			for(float k = 0; k < cl_navmesh_polies[i].vert_count; k++)
			{
				for(float l = 0; l < cl_navmesh_polies[j].vert_count; l++)
				{
					if(cl_navmesh_polies[i].verts[k] == cl_navmesh_polies[j].verts[l])
					{
						//If we have found more verts than should be allowed, count them for error print
						if(verts_found > 2)
						{
							verts_found++;
							continue;
						}
						
						shared_verts[verts_found] = cl_navmesh_polies[i].verts[k];
						shared_verts_index[verts_found++] = k;
					}
				}
			}
			
			//Print a warning if more than 2, should be impossible
			if(verts_found > 2)
			{
				print("Warning: polygon ");
				print(ftos(i));
				print(" shares ");
				print(ftos(verts_found));
				print(" vertices with polygon ");
				print(ftos(j));
				print(". There is an issue somewhere.\n");
			}
			else if(verts_found == 2)
			{
				//Setting the polygons as connected to each other
				if(cl_navmesh_polies[i].connected_polies_count >= 4)
				{
					print("Warning: polygon ");
					print(ftos(i));
					print(" shares an edge with more than 4 other polygons.\n");
					break;
				}
				if(cl_navmesh_polies[j].connected_polies_count >= 4)
				{
					print("Warning: polygon ");
					print(ftos(j));
					print(" shares an edge with more than 4 other polygons.\n");
					break;
				}
				cl_navmesh_polies[i].connected_polies[cl_navmesh_polies[i].connected_polies_count] = j;
				cl_navmesh_polies[j].connected_polies[cl_navmesh_polies[j].connected_polies_count] = i;
				
				
				//=======================================================================================
				//Calculating shared edge left / right vertices

				//Calculating from the perspective of moving from poly[i] to poly[j]
				
				//Because polygon's vertices are stored in a ccw winding order:
				//connected polygons must share two consecutive verts.
				//the CCW winding of the triangle dictates that the next shared vertex is to the left of, and in the index after the first shared vertex
				//i.e. of the two consecutive verts shard, the former is to the right, the latter is to the left
				
				//if first one is a quad: shared edge must be, where the first index is right and second index is left
				//3-0, 0-1, 1-2, 2-3
				//if first one is a tri: shared edge must be, where the first index is right and second index is left
				//2-0, 0-1, 1-2
				
				//Two distinct cases:
				//The index of second is one greater than the index of the first
				//OR
				//The index of the first is 0, and index of second is 2 or 3
				
				float left_vert = -1;
				float right_vert = -1;
				
				if(shared_verts_index[0] == 0 && shared_verts_index[1] >= 2)
				{
					//then right is the second, left is the first
					right_vert = shared_verts[1];
					left_vert = shared_verts[0];
					
				}
				else
				{
					//Else, right is the first, left is the second
					left_vert = shared_verts[1];
					right_vert = shared_verts[0];
				}
				
				
				//Assigning the link's left/right edges
				cl_navmesh_polies[i].connected_polies_left_vert[cl_navmesh_polies[i].connected_polies_count] = left_vert;
				cl_navmesh_polies[i].connected_polies_right_vert[cl_navmesh_polies[i].connected_polies_count++] = right_vert;
				
				//From j to i, left vert is on the right, and right vert is on the left
				cl_navmesh_polies[j].connected_polies_left_vert[cl_navmesh_polies[j].connected_polies_count] = right_vert;
				cl_navmesh_polies[j].connected_polies_right_vert[cl_navmesh_polies[j].connected_polies_count++] = left_vert;
				
				//=======================================================================================
				
				print("Poly ");
				print(ftos(i));
				print(" is connected to ");
				print(ftos(j));
				print(" and poly ");
				print(ftos(j));
				print(" is connected to ");
				print(ftos(i));
				print(".\n");
			}	
		}
	}
	print("Connected polygons calculated.\n");
}

//We calculate this outside of polygon creation / editing because the polygon centers are not important to creation, only to actually using in pathfinding
void cl_navmesh_calc_polies_centers()
{
	for(float i = 0; i < cl_navmesh_poly_count; i++)
	{
		local vector cen = [0,0,0];
		for(float j = 0; j < cl_navmesh_polies[i].vert_count; j++)
		{
			cen += cl_navmesh_verts[cl_navmesh_polies[i].verts[j]].pos;
		}
		cen /= cl_navmesh_polies[i].vert_count;
		cl_navmesh_polies[i].center.x = cen.x;
		cl_navmesh_polies[i].center.y = cen.y;
		cl_navmesh_polies[i].center.z = cen.z;
	}
	print("Centers calculated.\n");
}


//Navmesh file specification:
//Vertex count
//For each vert:
	//Vertex position vector
//Polygon count
//For each polygon:
		//vertex count (must be 3 or 4)
		//vertex 0 index
		//vertex 1 index
		//vertex 2 index
		//vertex 3 index (will be -1 for a tri)
		//center (vector)
		//link count
		//link 0 index (will be set or -1 for a tri)
		//link 1 index (will be set or -1 for a tri)
		//link 2 index (will be set or -1 for a tri)
		//link 3 index (will be set or -1 for a tri)
		//link 0 left vert index (will be set or -1 for a tri)
		//link 1 left vert index (will be set or -1 for a tri)
		//link 2 left vert index (will be set or -1 for a tri)
		//link 3 left vert index (will be set or -1 for a tri)
		//link 0 right vert index (will be set or -1 for a tri)
		//link 1 right vert index (will be set or -1 for a tri)
		//link 2 right vert index (will be set or -1 for a tri)
		//link 3 right vert index (will be set or -1 for a tri)


//Saves the current cl_navmesh to a file
void cl_navmesh_editor_save_navmesh()
{
	float file;
	string h;
	
	h = strcat(mappath, ".nav");
	file = fopen(h,FILE_WRITE);
	
	if(file == -1)
	{
		print("Error: unable to write to file \"",h,"\".\n");
		return;
	}
	
	
	//Calculating all links and polygon centers
	//===========================================
	cl_navmesh_calc_polies_centers();
	cl_navmesh_calc_connected_polies();
	//===========================================

	//Write vertex count
	fputs(file,ftos(cl_navmesh_vert_count),"\n");
	
	//Write all vertex positions
	for(float i = 0; i < cl_navmesh_vert_count; i++)
	{
		fputs(file,vtos(cl_navmesh_verts[i].pos),"\n");
	}
	
	//Write polygon count
	fputs(file,ftos(cl_navmesh_poly_count),"\n");
	
	//Write all polygon data to file
	for(float i = 0; i < cl_navmesh_poly_count; i++)
	{
		//Writing vert count
		fputs(file,ftos(cl_navmesh_polies[i].vert_count),"\n");
		//Writing vertices
		fputs(file,ftos(cl_navmesh_polies[i].verts[0]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].verts[1]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].verts[2]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].verts[3]),"\n");
		fputs(file,vtos(cl_navmesh_polies[i].center),"\n");
		
		//Writing link count
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_count),"\n");
		//Writing links
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies[0]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies[1]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies[2]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies[3]),"\n");
		//Writing left vertices of the links
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_left_vert[0]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_left_vert[1]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_left_vert[2]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_left_vert[3]),"\n");
		//Writing right vertices of the links
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_right_vert[0]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_right_vert[1]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_right_vert[2]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_right_vert[3]),"\n");	
	}
	
	fclose(file);
	
	print("Navmesh saved to file \"",h,"\".\n");
}
//Overwrites current navmesh with an empty navmesh
void cl_navmesh_editor_clear_navmesh()
{
	cl_navmesh_vert_count = 0;
	for(float i = 0; i < cl_navmesh_verts.length; i++)
	{
		cl_navmesh_verts[i].pos.x = 0;
		cl_navmesh_verts[i].pos.y = 0;
		cl_navmesh_verts[i].pos.z = 0;
	}
	cl_navmesh_poly_count = 0;
	for(float i = 0; i < cl_navmesh_polies.length; i++)
	{
		cl_navmesh_polies[i].vert_count = 0;
		
		cl_navmesh_polies[i].verts[0] = -1;
		cl_navmesh_polies[i].verts[1] = -1;
		cl_navmesh_polies[i].verts[2] = -1;
		cl_navmesh_polies[i].verts[3] = -1;
		
		cl_navmesh_polies[i].center.x = 0;
		cl_navmesh_polies[i].center.y = 0;
		cl_navmesh_polies[i].center.z = 0;
		
		cl_navmesh_polies[i].connected_polies_count = 0;
		
		cl_navmesh_polies[i].connected_polies[0] = -1;
		cl_navmesh_polies[i].connected_polies[1] = -1;
		cl_navmesh_polies[i].connected_polies[2] = -1;
		cl_navmesh_polies[i].connected_polies[3] = -1;
		
		cl_navmesh_polies[i].connected_polies_left_vert[0] = -1;
		cl_navmesh_polies[i].connected_polies_left_vert[1] = -1;
		cl_navmesh_polies[i].connected_polies_left_vert[2] = -1;
		cl_navmesh_polies[i].connected_polies_left_vert[3] = -1;
		
		cl_navmesh_polies[i].connected_polies_right_vert[0] = -1;
		cl_navmesh_polies[i].connected_polies_right_vert[1] = -1;
		cl_navmesh_polies[i].connected_polies_right_vert[2] = -1;
		cl_navmesh_polies[i].connected_polies_right_vert[3] = -1;
	}
}
//Overwrites currently loaded navmesh with navmesh stored in fail
void cl_navmesh_editor_load_navmesh()
{
	string filepath;
	float file;
	
	filepath = strcat(mappath, ".nav");
	file = fopen(filepath,FILE_READ);
	
	if(file == -1)
	{
		print("Error: file \"",filepath,"\" not found.\n");
		return;
	}
	
	float v;
	
	//First line contains vertex count
	string line = fgets(file);
	
	float vert_count = stof(line);
	
	if(vert_count > cl_navmesh_verts.length)
	{
		print("Error: navmesh file \"",filepath,"\" has an invalid vert count. (" , line, " > ", ftos(cl_navmesh_verts.length),").\n");
		fclose(file);
		return;
	}
	
	//It appears to be valid, so clear the current navmesh before continuing.
	cl_navmesh_editor_clear_navmesh();
	
	cl_navmesh_vert_count = vert_count;
	
	print("Vert count: ",line,"\n");

	//Temp vector to assign component-wise
	vector temp;
	

	//Reading all of the vertex positions
	for(float i = 0; i < cl_navmesh_vert_count; i++)
	{
		line = fgets(file);
		temp = stov(line);
		cl_navmesh_verts[i].pos.x = temp.x;
		cl_navmesh_verts[i].pos.y = temp.y;
		cl_navmesh_verts[i].pos.z = temp.z;
		//TODO: if something goes wrong, clear the partially loaded navmesh
	}
	
	//Next line contains the number of polygons
	cl_navmesh_poly_count = stof(fgets(file));
	
	//The next lines are each polygon
	for(float i = 0; i < cl_navmesh_poly_count; i++)
	{
		//Getting vertex count
		cl_navmesh_polies[i].vert_count = stof(fgets(file));
		//Getting vertices
		cl_navmesh_polies[i].verts[0] = stof(fgets(file));
		cl_navmesh_polies[i].verts[1] = stof(fgets(file));
		cl_navmesh_polies[i].verts[2] = stof(fgets(file));
		cl_navmesh_polies[i].verts[3] = stof(fgets(file));
		//Don't care about polygon center
		fgets(file);
		//Don't care about link count
		fgets(file);
		//Don't care about links for now FIXME HANDLE DIRECTIONAL LINKS
		fgets(file);//0
		fgets(file);//1
		fgets(file);//2
		fgets(file);//3
		//Don't care about link's left vertices
		fgets(file);//0
		fgets(file);//1
		fgets(file);//2
		fgets(file);//3
		//Don't care about link's right vertices
		fgets(file);//0
		fgets(file);//1
		fgets(file);//2
		fgets(file);//3
	}
	
	fclose(file);
}


//==================================================================


//==========================================================================================================================
//============================ The following methods are methods required in the pathfinding code ==========================
//==========================================================================================================================


float(float start, float goal, vector start_pos, vector end_pos) cl_navmesh_pathfind_start;

void cl_navmesh_draw_test_ent(vector pos, vector scale, vector color, float alpha)
{
	//Assigning the shader as something else so that fte doesn't batch the calls (leading to colors not changing between draw calls)
	R_BeginPolygon("debug/wireframe",0);
	R_BeginPolygon("debug/solid_nocull",0);
	
	//vector	VEC_HULL_MIN = '-16 -16 -32';
	//vector	VEC_HULL_MAX = '16 16 40';
	
	float min_x = -16 * scale_x;
	float min_y = -16 * scale_y;
	float min_z = -32 * scale_z;
	float max_x = 16 * scale_x;
	float max_y = 16 * scale_y;
	float max_z = 40 * scale_z;
	
	
	
	//bottom face
	R_PolygonVertex(pos + [min_x,max_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,max_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,min_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [min_x,min_y,min_z], [0,0,0], color,alpha);
	R_EndPolygon();
	//Top face
	R_PolygonVertex(pos + [min_x,max_y,max_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,max_y,max_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,min_y,max_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [min_x,min_y,max_z], [0,0,0], color,alpha);
	R_EndPolygon();
	//Front face
	R_PolygonVertex(pos + [min_x,min_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,min_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,min_y,max_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [min_x,min_y,max_z], [0,0,0], color,alpha);
	R_EndPolygon();
	//Back face
	R_PolygonVertex(pos + [min_x,max_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,max_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,max_y,max_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [min_x,max_y,max_z], [0,0,0], color,alpha);
	R_EndPolygon();
	//Left face
	R_PolygonVertex(pos + [min_x,min_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [min_x,max_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [min_x,max_y,max_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [min_x,min_y,max_z], [0,0,0], color,alpha);
	R_EndPolygon();
	//Right face
	R_PolygonVertex(pos + [max_x,min_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,max_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,max_y,max_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,min_y,max_z], [0,0,0], color,alpha);
	R_EndPolygon();
}

void cl_navmesh_place_test_goalent()
{
	goalent_pos = getentity(player_localentnum, GE_ORIGIN);
	
	goalent_set = TRUE;
	
	
	//Calculate data that the navmesh exporer will calculate
	cl_navmesh_calc_polies_centers();
	cl_navmesh_calc_connected_polies();
	
	if(goalent_set == TRUE && startent_set == TRUE)
	{
		print("Getting start poly.");
		float start = cl_navmesh_get_containing_poly(startent_pos);
		print("Getting goal poly.");
		float goal = cl_navmesh_get_containing_poly(goalent_pos);
		cl_navmesh_pathfind_start(start,goal,startent_pos,goalent_pos);
	}
	

}
void cl_navmesh_place_test_startent()
{
	startent_pos = getentity(player_localentnum, GE_ORIGIN);
	
	startent_set = TRUE;
	
	//Calculate data that the navmesh exporer will calculate
	cl_navmesh_calc_polies_centers();
	cl_navmesh_calc_connected_polies();
	
	if(goalent_set == TRUE && startent_set == TRUE)
	{
		float start = cl_navmesh_get_containing_poly(startent_pos);
		float goal = cl_navmesh_get_containing_poly(goalent_pos);
		cl_navmesh_pathfind_start(start,goal,startent_pos,goalent_pos);
	}
}

//Returns 1 if pos is inside poly at index poly_index, 0 otherwise
float cl_navmesh_is_inside_poly(vector pos, float poly_index)
{
	
	//TODO: check if z coord is close enough to poly
	
	local vector vert_to_pos;//points from vert to pos
	local vector vert_to_next;//points from vert to the next vertex
	local vector vert;
	local vector next_vert;
	float vert_count = cl_navmesh_polies[poly_index].vert_count;
	//We are considered to be in the polygon, if pos is on the left of all edges of the polygon (if verts are ordered in CW order)
	for(float i = 0; i < vert_count; i++)
	{
		vert = cl_navmesh_verts[cl_navmesh_polies[poly_index].verts[i]].pos;
		next_vert = cl_navmesh_verts[cl_navmesh_polies[poly_index].verts[(i + 1) % vert_count]].pos;
		
		vert_to_pos = pos - vert;
		vert_to_next = next_vert - vert;
		
		//Check if vert_to_pos is to the left of vert_to_next
		if(vert_to_next.x * vert_to_pos.y - vert_to_next.y * vert_to_pos.x < 0)
			return 0;
	}
	
	
	//FOR DEBUG: select that polygon if succesfull
	cl_navmesh_deselect_all();
	selected_vert_count = cl_navmesh_polies[poly_index].vert_count;
	for(float i = 0; i < selected_vert_count; i++)
	{
		selected_verts[i] = cl_navmesh_polies[poly_index].verts[i];
	}	
	//============================================
	
	
	return 1;
}

//Returns distance from pos to an edge of the poly if pos is very close to an edge of the poly at index poly_index, -1 otherwise
float cl_navmesh_dist_to_poly(vector pos, float poly_index)
{
	float leeway = 30;//Must be within 30 qu of edge to be considered close
	
	//TODO: check if close enough on z-axis
	
	local vector vert_to_pos;//points from vert to pos
	local vector vert_to_next;//points from vert to the next vertex
	
	
	local vector vert;
	local vector next_vert;
	float vert_count = cl_navmesh_polies[poly_index].vert_count;
	
	float shortest_dist = 100000;
	
	//Only considering 2D
	//pos.z = 0;
	
	//We are considered to be in the polygon, if pos is on the left of all edges of the polygon (if verts are ordered in CW order)
	for(float i = 0; i < vert_count; i++)
	{
		vert = cl_navmesh_verts[cl_navmesh_polies[poly_index].verts[i]].pos;
		next_vert = cl_navmesh_verts[cl_navmesh_polies[poly_index].verts[(i + 1) % vert_count]].pos;
		
		//Calculating in 2D:
		//vert.z = 0;
		//next_vert.z = 0;
		
		float temp_dist = navmesh_2D_line_point_dist(vert, next_vert, pos);
		
		if(temp_dist < shortest_dist)
		{
			shortest_dist = temp_dist;
		}	
	}
	
	if(shortest_dist < leeway)
		return shortest_dist;
	
	return -1;
}

//Returns polygon that pos is inside of. 
//If we are in no polygon, returns a polygon whose edge we are sufficiently close to (might be in but are not due to a small error)
//Otherwise, returns -1
float cl_navmesh_get_containing_poly(vector pos)
{
	//Get nearest polygon, and check if pos is in that polygon
	float closest_poly = -1;
	float closest_poly_dist = 1000000;
	
	//In reality, there's no need to try ALL polygons, the one we are in should be within the nearest 10 or so, but checking all to be safe
	for(float i = 0; i < cl_navmesh_poly_count; i++)
	{	
		//Check if we are sufficiently close enough to polygon i in the z-axis
		//Current method of checking: if pos is within 30 qu of polygon z-axis bounds
		float poly_min_z = cl_navmesh_verts[cl_navmesh_polies[i].verts[0]].pos.z;
		float poly_max_z = poly_min_z;

		for(float j = 0; j < cl_navmesh_polies[i].vert_count; j++)
		{
			float vert_z = cl_navmesh_verts[cl_navmesh_polies[i].verts[j]].pos.z;
			poly_min_z = min(poly_min_z, vert_z);
			poly_max_z = max(poly_max_z, vert_z);
		}

		// If we NOT between [min - 30, max + 30], skip this polygon
		// if(fabs(sv_navmesh_polies[0].center.z - pos.z) >= 30)
		if(pos.z < poly_min_z - 30 || pos.z > poly_max_z + 30)
		{
			continue;
		}
		
		//Check if we are in the 2d plane of polygon i
		if(cl_navmesh_is_inside_poly(pos,i))
		{
			// NOTE - Because is_inside_poly only checks if we are in it on X & Y axes,
			// NOTE   we may have found a polygon on a floor below us or above us.
			// NOTE   However, this may not be an issue. A polygon on a floor below
			// NOTE   us would be at least about 80-ish qu away, and the checks done for 
			// NOTE   z proximity might be enough to stop us from choosing polygons on 
			// NOTE   different floors. I shall assume this works fine, and wait for a 
			// NOTE   counter-example that shows we'll need a more sophisticated strategy.
			print("Ent pos is inside poly: ");
			print(ftos(i));
			print(".\n");
			return i;
		}
		
		//If we are not in polygon i, check if we are very close to one of its edges
		float dist = cl_navmesh_dist_to_poly(pos,i);
		
		if(dist >= 0)
		{
			if(dist < closest_poly_dist)
			{
				closest_poly = i;
				closest_poly_dist = dist;
			}
		}

	}
	
	
	//FOR DEBUG: select that polygon if successful
	if(closest_poly != -1)
	{
		cl_navmesh_deselect_all();
		selected_vert_count = cl_navmesh_polies[closest_poly].vert_count;
		for(float i = 0; i < selected_vert_count; i++)
		{
			selected_verts[i] = cl_navmesh_polies[closest_poly].verts[i];
		}
	}
	//============================================
	
	if(closest_poly == -1)
	{
		print("Ent pos is not in or near any polygons.\n");
	}
	else
	{
		print("Ent pos is near but not in poly: closest_poly.\n");
	}
	
	return closest_poly;
}




//================================================================================================================
//=============================================== Actual A* functions ============================================
//================================================================================================================

//Calculates the heuristic h score value (Our best guess for how far this node is from the goal node)
float cl_pathfind_calc_h_score(float current, float goal)
{
	//FIXME: we could just as easily return vlen()^2 for comparisons... (saves a sqrt operation)
	return vlen(cl_navmesh_polies[goal].center - cl_navmesh_polies[current].center);
}

//Struct containing all arrays that the pathfind code requires to operate
pathfind_result cl_test_pathfind_result;

//Returns the polygon with the lowest f score from polygons the open set
float cl_pathfind_get_lowest_f_score()
{
	//TODO: implement a better algorithm for finding the lowest score
	
	float best_score = 100000;
	float best_score_index = -1;
	
	for(float i = 0; i < cl_navmesh_poly_count; i++)
	{
		if(cl_test_pathfind_result.poly_set[i] == PATHFIND_POLY_SET_OPEN)
		{
			if(cl_test_pathfind_result.poly_f_score[i] < best_score)
			{
				best_score = cl_test_pathfind_result.poly_f_score[i];
				best_score_index = i;
			}
		}
	}
	
	return best_score_index;
}

void cl_pathfind_clear_result_data()
{
	//Technically we only need to iterate over navmesh_poly_count...
	for(float i = 0; i < NAV_MAX_POLIES; i++)
	{
		cl_test_pathfind_result.poly_set[i] = PATHFIND_POLY_SET_NONE;
		cl_test_pathfind_result.poly_prev[i] = -1;
		cl_test_pathfind_result.poly_g_score[i] = 0;
		cl_test_pathfind_result.poly_f_score[i] = 0;
		cl_test_pathfind_result.result_node_path[i] = -1;
		
		cl_test_pathfind_result.result_path[i].x = 0;
		cl_test_pathfind_result.result_path[i].y = 0;
		cl_test_pathfind_result.result_path[i].z = 0;
		
		cl_test_pathfind_result.portals_right_vert[i] = -1;
		cl_test_pathfind_result.portals_left_vert[i] = -1;
	}
	cl_test_pathfind_result.result_node_length = 0;
	cl_test_pathfind_result.result_length = 0;
	cl_test_pathfind_result.portals_length = 0;
}

//Applies a funnel algorithm to the path defined by the array cl_test_pathfind_result.result_node_path 
// and populates pathfind result path
void cl_pathfind_smooth_path(vector start_point, vector goal_point)
{
	//Evaluate portals and identify left / right portal vertices
	for(float i = 1; i < cl_test_pathfind_result.result_node_length; i++)
	{
		float prev_poly = cl_test_pathfind_result.result_node_path[i-1];
		float poly = cl_test_pathfind_result.result_node_path[i];
		
		//Finding what index prev_poly is linked to poly
		
		float link_index = -1;
		
		for(float j = 0; j < cl_navmesh_polies[prev_poly].connected_polies_count; j++)
		{
			if(cl_navmesh_polies[prev_poly].connected_polies[j] == poly)
			{
				link_index = j;
				break;
			}
		}
		
		//Use that index to get left and right vertices
		cl_test_pathfind_result.portals_left_vert[cl_test_pathfind_result.portals_length] = cl_navmesh_polies[prev_poly].connected_polies_left_vert[link_index];
		cl_test_pathfind_result.portals_right_vert[cl_test_pathfind_result.portals_length++] = cl_navmesh_polies[prev_poly].connected_polies_right_vert[link_index];
	}
	//the last left edge / right edge is the goal position
	
	print("Portals: ");
	for(float i = 0; i < cl_test_pathfind_result.portals_length; i++)
	{
		print("[");
		print(ftos(i));
		print("] = (");
		print(ftos(cl_test_pathfind_result.portals_left_vert[i]));
		print(" , ");
		print(ftos(cl_test_pathfind_result.portals_right_vert[i]));
		print(") , ");
	}
	
	//starting at start_pos (not at start center point)
	//get vectors that point to first left edge and first right edge
	
	vector funnel_apex = start_point;
	float funnel_left_index = 0;
	//Index of the funnel's left vertex in the portal list
	vector funnel_left = cl_navmesh_verts[cl_test_pathfind_result.portals_left_vert[0]].pos;
	//Index of the funnel's right vertex in the portal list
	float funnel_right_index = 0;
	vector funnel_right = cl_navmesh_verts[cl_test_pathfind_result.portals_right_vert[0]].pos;
	
	vector next_funnel_left;
	vector next_funnel_right;
	
	
	float inside_right_edge;
	float inside_left_edge;
	
	while(1)
	{
		print("=============Funnel iteration.==========\n");
		print("\tCurrent left edge: ");
		print(ftos(cl_test_pathfind_result.portals_left_vert[funnel_left_index]));
		print("\n");
		print("\tCurrent right edge: ");
		print(ftos(cl_test_pathfind_result.portals_right_vert[funnel_right_index]));
		print("\n");
		
		//Check if we have reached the end of the portals, consider the goal position as the last portal
		//If we are not at the last index of the left portal
		
		//Keeping track of whether or not advancing the left edge or right edge narrows the funnel
		float advanced_left = FALSE;
		float advanced_right = FALSE;
		
		
		
		//Consider the end goal point as the last portal
		//================ Checking left funnel edge =================
		if(funnel_left_index < cl_test_pathfind_result.portals_length)
		{
			print("\t-- Trying to advance left edge. --\n");
			
			if(funnel_left_index < cl_test_pathfind_result.portals_length - 1)
			{
				next_funnel_left = cl_navmesh_verts[cl_test_pathfind_result.portals_left_vert[funnel_left_index+1]].pos;
				print("\t\tNext left edge is vert: ");
				print(ftos(cl_test_pathfind_result.portals_left_vert[funnel_left_index+1]));
				print(".\n");
			}
			else
			{
				print("\t\tTrying next left edge as goal point.\n");
				//If funnel_left is pointing to the last portal in the array, consider the goal_point the last portal
				next_funnel_left = goal_point;
			}

			inside_right_edge = pathfind_point_is_to_left(funnel_apex,funnel_right,next_funnel_left);
			//If the next left edge crosses the current right edge
			if(inside_right_edge < 0)
			{
				print("\t\tnext left edge crosses current right edge.\n");
				//Add funnel right point to path
				cl_test_pathfind_result.result_path[cl_test_pathfind_result.result_length++] = funnel_right;
				
				//Check if we are at the end of our portal list
				if(funnel_right_index >= cl_test_pathfind_result.portals_length - 1)
				{
					cl_test_pathfind_result.result_path[cl_test_pathfind_result.result_length++] = goal_point;
					return;
				}
				
				
				print("\t\tnew funnel apex is now vert: ");
				print(ftos(cl_test_pathfind_result.portals_right_vert[funnel_right_index]));
				print("\n");

				//Restart algorithm with the portal after the right point
				funnel_apex = funnel_right;
				
				funnel_left_index = funnel_right_index + 1;
				funnel_left = cl_navmesh_verts[cl_test_pathfind_result.portals_left_vert[funnel_left_index]].pos;
				funnel_right_index = funnel_right_index + 1;
				funnel_right = cl_navmesh_verts[cl_test_pathfind_result.portals_right_vert[funnel_right_index]].pos;
				continue;
			}
			//If the next left edge is in the funnel
			inside_left_edge = pathfind_point_is_to_left(funnel_left,funnel_apex,next_funnel_left);
			if(inside_left_edge >= 0 && inside_right_edge >= 0)
			{
				print("\t\tnext left edge is in the funnel, narrowing funnel.\n");
				//Advance the left edge
				funnel_left = next_funnel_left;
				funnel_left_index++;
				
				advanced_left = TRUE;
				
				//Check if the portal we just added was the goal point (will be after the list)
				if(funnel_left_index >= cl_test_pathfind_result.portals_length)
				{
					cl_test_pathfind_result.result_path[cl_test_pathfind_result.result_length++] = goal_point;
					return;
				}
			}
		}
		//================ Checking right funnel edge =================
		if(funnel_right_index < cl_test_pathfind_result.portals_length)
		{
			print("\t -- Trying to advance right edge --\n");
			
			if(funnel_right_index < cl_test_pathfind_result.portals_length - 1)
			{
				next_funnel_right = cl_navmesh_verts[cl_test_pathfind_result.portals_right_vert[funnel_right_index+1]].pos;
				print("\t\tNext right edge is vert: ");
				print(ftos(cl_test_pathfind_result.portals_right_vert[funnel_right_index+1]));
				print(".\n");
			}
			else
			{
				print("\t\tTrying next right edge as goal point.\n");
				//If funnel_right is pointing to the last portal in the array, consider the goal_point the last portal
				next_funnel_right = goal_point;
			}
			
			//If the next right edge crosses the current left edge
			inside_left_edge = pathfind_point_is_to_left(funnel_left,funnel_apex,next_funnel_right);
			if(inside_left_edge < 0)
			{
				print("\t\tnext right edge crosses current left edge.\n");
				//Add funnel left point to path
				cl_test_pathfind_result.result_path[cl_test_pathfind_result.result_length++] = funnel_left;
				
				//Check if we are at the end of our portal list
				if(funnel_left_index >= cl_test_pathfind_result.portals_length - 1)
				{
					cl_test_pathfind_result.result_path[cl_test_pathfind_result.result_length++] = goal_point;
					return;
				}
				
				
				//Restart algorithm with the portal after the right point
				funnel_apex = funnel_left;
				print("\t\tnew funnel apex is now vert: ");
				print(ftos(cl_test_pathfind_result.portals_left_vert[funnel_left_index]));
				print("\n");
				
				funnel_right_index = funnel_left_index + 1;
				funnel_right = cl_navmesh_verts[cl_test_pathfind_result.portals_right_vert[funnel_right_index]].pos;
				funnel_left_index = funnel_left_index + 1;
				funnel_left = cl_navmesh_verts[cl_test_pathfind_result.portals_left_vert[funnel_left_index]].pos;
				continue;
			}
			//If the next right edge is in the funnel
			inside_right_edge = pathfind_point_is_to_left(funnel_apex,funnel_right,next_funnel_right);			
			if(inside_left_edge >= 0 && inside_right_edge >= 0)
			{
				print("\t\tnext right edge is in the funnel, narrowing funnel.\n");
				//Advance the left edge
				funnel_right = next_funnel_right;
				funnel_right_index++;
				
				advanced_right = TRUE;
				
				//Check if the portal we just added was the goal point (will be after the list)
				if(funnel_right_index >= cl_test_pathfind_result.portals_length)
				{
					cl_test_pathfind_result.result_path[cl_test_pathfind_result.result_length++] = goal_point;
					return;
				}
			}
		}
		if(advanced_left == FALSE && advanced_right == FALSE)
		{
			print("Hit funnel freeze condition.\n");
			
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
			for(float i = funnel_left_index + 1; i < cl_test_pathfind_result.portals_length + 1; i++)
			{
				if(i < cl_test_pathfind_result.portals_length - 1)
				{
					//Don't calculate the same vertex again
					if(last_vert == cl_test_pathfind_result.portals_left_vert[i])
						continue;
					last_vert = cl_test_pathfind_result.portals_left_vert[i];
					next_funnel_left = cl_navmesh_verts[last_vert].pos;
				}
				else//consider goal pos as last portal edge
				{
					next_funnel_left = goal_point;
				}
				
				inside_right_edge = pathfind_point_is_to_left(funnel_apex,funnel_right,next_funnel_left);
				
				//If the left vertex crosses the funnel (left vertex is outside the funnel's right edge)
				if(inside_right_edge < 0)
				{
					left_vert = cl_test_pathfind_result.portals_left_vert[i];
					left_type = crossed;
					break;
				}
				
				inside_left_edge = pathfind_point_is_to_left(funnel_left,funnel_apex,next_funnel_left);
				
				//If the left vertex is within the funnel
				if(inside_left_edge >= 0 && inside_right_edge >= 0)
				{
					left_vert = cl_test_pathfind_result.portals_left_vert[i];
					left_type = contained;
					left_portal_index = i;
					break;
				}
			}
			
			last_vert = -1;
			
			//Find the closest vertex in the portal right with the lowest index that crosses the funnel or is in the funnel
			for(float i = funnel_right_index + 1; i < cl_test_pathfind_result.portals_length; i++)
			{
				if(i < cl_test_pathfind_result.portals_length - 1)
				{
					//Don't calculate the same vertex again
					if(last_vert == cl_test_pathfind_result.portals_right_vert[i])
						continue;
					last_vert = cl_test_pathfind_result.portals_right_vert[i];
					next_funnel_right = cl_navmesh_verts[last_vert].pos;
				}
				else//consider goal pos as last portal edge
				{
					next_funnel_right = goal_point;
				}
				
				inside_left_edge = pathfind_point_is_to_left(funnel_left,funnel_apex,next_funnel_right);
				
				//If the right vertex crosses the funnel (right vertex is outside the funnel's left edge)
				if(inside_left_edge < 0)
				{
					right_vert = cl_test_pathfind_result.portals_right_vert[i];
					right_type = crossed;
					break;
				}
				
				inside_right_edge = pathfind_point_is_to_left(funnel_apex,funnel_right,next_funnel_right);
				
				//If the right vertex is within the funnel
				if(inside_left_edge >= 0 && inside_right_edge >= 0)
				{
					right_vert = cl_test_pathfind_result.portals_right_vert[i];
					right_type = contained;
					right_portal_index = i;
					break;
				}
			}
			
			//If no vertices were found, goal is reachable from here
			if(left_vert == -1 && right_vert == -1)
			{
				cl_test_pathfind_result.result_path[cl_test_pathfind_result.result_length++] = goal_point;
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
					cl_test_pathfind_result.result_path[cl_test_pathfind_result.result_length++] = funnel_right;
					
					//Restart algorithm with the portal after the right point
					funnel_apex = funnel_right;
					
					//Check if portal after this portal is goal:
					funnel_right_index++;
					if(funnel_right_index >= cl_test_pathfind_result.portals_length)
					{
						cl_test_pathfind_result.result_path[cl_test_pathfind_result.result_length++] = goal_point;
						return;
					}
					
					funnel_right = cl_navmesh_verts[cl_test_pathfind_result.portals_right_vert[funnel_right_index]].pos;
					funnel_left_index = funnel_right_index;
					funnel_left = cl_navmesh_verts[cl_test_pathfind_result.portals_left_vert[funnel_left_index]].pos;
					continue;
				}
				else//in funnel
				{
					//If the next funnel right is the goal, we are done
					//Check if portal after this portal is goal:
					if(right_portal_index >= cl_test_pathfind_result.portals_length)
					{
						cl_test_pathfind_result.result_path[cl_test_pathfind_result.result_length++] = goal_point;
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
					cl_test_pathfind_result.result_path[cl_test_pathfind_result.result_length++] = funnel_left;
					
					//Restart algorithm with the portal after the left point
					funnel_apex = funnel_left;
					
					//Check if portal after this portal is goal:
					funnel_left_index++;
					if(funnel_left_index >= cl_test_pathfind_result.portals_length)
					{
						cl_test_pathfind_result.result_path[cl_test_pathfind_result.result_length++] = goal_point;
						return;
					}
					
					funnel_left = cl_navmesh_verts[cl_test_pathfind_result.portals_left_vert[funnel_left_index]].pos;
					funnel_right_index = funnel_left_index;
					funnel_right = cl_navmesh_verts[cl_test_pathfind_result.portals_right_vert[funnel_right_index]].pos;
					continue;
				}
				else//in funnel
				{
					//If the next funnel right is the goal, we are done
					//Check if portal after this portal is goal:
					if(right_portal_index >= cl_test_pathfind_result.portals_length)
					{
						cl_test_pathfind_result.result_path[cl_test_pathfind_result.result_length++] = goal_point;
						return;
					}
					//Update current right funnel edge to use this vertex
					funnel_right = next_funnel_right;
					funnel_right_index = right_portal_index;
					
					continue;
				}
			}			
		}
	print("==========================\n");
	}
}

//Evaluates the path that is found in the pathfinding algorithm and populates an array with the nodes in the path from start to goal
void pathfind_trace_path(float start, float goal)
{
	float current = start;
	//Count the length of the path (how many polygons the path traverses)
	current = goal;
	cl_test_pathfind_result.result_node_length = 1;
	do
	{
		//print("Poly ");
		//print(ftos(current));
		//print(" came from  ");
		//print(ftos(cl_test_pathfind_result.poly_prev[current]));
		//print(".\n");
		current = cl_test_pathfind_result.poly_prev[current];
		cl_test_pathfind_result.result_node_length++;
	} while(current != start);
	
	
	//Starting at goal waypoint, add the traversed waypoints to the result path in reverse order
	current = goal;
	for(float i = 0; i < cl_test_pathfind_result.result_node_length; i++)
	{
		cl_test_pathfind_result.result_node_path[cl_test_pathfind_result.result_node_length - 1 - i] = current;
		current = cl_test_pathfind_result.poly_prev[current];
	}
	
	print("Pathfind success, path length: ");
	print(ftos(cl_test_pathfind_result.result_node_length));
	print(".\n");
	
	print("Path: ");
	for(float i = 0; i < cl_test_pathfind_result.result_node_length; i++)
	{
		if(i > 0)
			print(" , ");
		print(ftos(cl_test_pathfind_result.result_node_path[i]));
	}
	print(" .\n");
}

//Accepts start polygon and goal polygon
//Returns 1 on success.
//Returns 0 on fail.
float cl_navmesh_pathfind_start(float start, float goal, vector start_pos, vector end_pos)
{
	if(start == -1)
	{
		print("Error: pathfind start node invalid.\n");
		return 0;
	}
	if(goal == -1)
	{
		print("Error: pathfind goal node invalid.\n");
		return 0;
	}
	if(start == goal)
	{
		//Calculating node path
		cl_test_pathfind_result.result_node_path[0] = start;
		cl_test_pathfind_result.result_node_length = 1;
		print("Pathind success: trivial case (start = goal).\n");
		
		//Calculating vector based path (go directly to goal)
		cl_test_pathfind_result.result_path[0].x = end_pos.x;
		cl_test_pathfind_result.result_path[0].y = end_pos.y;
		cl_test_pathfind_result.result_path[0].z = end_pos.z;
		cl_test_pathfind_result.result_length = 1;
		return 1;
	}
	
	//Clearing previous data
	cl_pathfind_clear_result_data();
	
	//Adding start polygon to the open set
	cl_test_pathfind_result.poly_set[start] = PATHFIND_POLY_SET_OPEN;
	cl_test_pathfind_result.poly_g_score[start] = 0;
	cl_test_pathfind_result.poly_f_score[start] = 0 + cl_pathfind_calc_h_score(start , goal);
	
	//Fields that need to be set:
	//cl_test_pathfind_result.poly_set[NAV_MAX_POLIES];
	//cl_test_pathfind_result.prev_poly[NAV_MAX_POLIES];
	//cl_test_pathfind_result.poly_g_score[NAV_MAX_POLIES];
	//cl_test_pathfind_result.poly_f_score[NAV_MAX_POLIES];
	
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
		cl_test_pathfind_result.poly_set[current] = PATHFIND_POLY_SET_CLOSED;
		//Add connected nodes to the open set
		for(float i = 0; i < cl_navmesh_polies[current].connected_polies_count; i++)
		{
			float neighbor = cl_navmesh_polies[current].connected_polies[i];
			
			/*print("Checking poly ");
			print(ftos(current));
			print("'s neighbor ");
			print(ftos(neighbor));
			print(".\n");*/
			
			if(cl_test_pathfind_result.poly_set[neighbor] != PATHFIND_POLY_SET_CLOSED)
			{
				//print("Neighbor is not in closed list.\n");
				//Calculate tentative f score
				//Calculate tentative g score (distance from start to current + distance from current to neighbor)
				float tentative_g_score = cl_test_pathfind_result.poly_g_score[current] + vlen(cl_navmesh_polies[neighbor].center - cl_navmesh_polies[current].center);
				
				if(cl_test_pathfind_result.poly_set[neighbor] != PATHFIND_POLY_SET_OPEN || tentative_g_score < cl_test_pathfind_result.poly_g_score[neighbor])
				{
					//print("Neighbor is not in open list, or a better g score has been found.\n");
					//Adding neighbor to open set
					cl_test_pathfind_result.poly_set[neighbor] = PATHFIND_POLY_SET_OPEN;
					
					//Updating scores for neighbor node
					float tentative_f_score = tentative_g_score + cl_pathfind_calc_h_score(neighbor , goal);
					cl_test_pathfind_result.poly_g_score[neighbor] = tentative_g_score;
					cl_test_pathfind_result.poly_f_score[neighbor] = tentative_f_score;
					
					//Linking neighbor node to current node (for tracing path)
					cl_test_pathfind_result.poly_prev[neighbor] = current;
					
					/*print("Assigning Poly ");
					print(ftos(neighbor));
					print(" came from  ");
					print(ftos(current));
					print(".\n");*/
				}
				
			}
		}		
		
		current = cl_pathfind_get_lowest_f_score();
	}
	
	
	//Tracing the pathfind results
	if(pathfind_success == TRUE)
	{
		pathfind_trace_path(start,goal);
		
		cl_pathfind_smooth_path(start_pos,end_pos);
		
		return 1;
	}
	print("Pathfind fail");
	return 0;
}


//This renders the raw pathfind results (polygon center to polygon center)
void cl_navmesh_pathfind_draw_result_node_path()
{
	//FIXME: don't call if length is 0
	if(cl_test_pathfind_result.result_node_length < 1)
		return;
	//================= Drawing Polygon Center ======================
	//=======================================
	//Assigning the shader as something else so that fte doesn't batch the calls (leading to colors not changing between draw calls)
	R_BeginPolygon("debug/wireframe",0);
	R_BeginPolygon("debug/solid_nocull",0);
	
	vector color;
	color = [1,0.1,0.5];
	float alpha = 0.2;//0.3
	float edge_width = 2;
	float edge_alpha = 0.2;//0.3
	
	for(float i = 0; i < cl_test_pathfind_result.result_node_length; i++)
	{
		vector pos = cl_navmesh_polies[cl_test_pathfind_result.result_node_path[i]].center + [0,0,-5];
		//bottom face
		R_PolygonVertex(pos + [-5,5,-5], [0,0,0], color,alpha);
		R_PolygonVertex(pos + [5,5,-5], [0,0,0], color,alpha);
		R_PolygonVertex(pos + [5,-5,-5], [0,0,0], color,alpha);
		R_PolygonVertex(pos + [-5,-5,-5], [0,0,0], color,alpha);
		R_EndPolygon();
		//Top face
		R_PolygonVertex(pos + [-5,5,5], [0,0,0], color,alpha);
		R_PolygonVertex(pos + [5,5,5], [0,0,0], color,alpha);
		R_PolygonVertex(pos + [5,-5,5], [0,0,0], color,alpha);
		R_PolygonVertex(pos + [-5,-5,5], [0,0,0], color,alpha);
		R_EndPolygon();
		//Front face
		R_PolygonVertex(pos + [-5,-5,-5], [0,0,0], color,alpha);
		R_PolygonVertex(pos + [5,-5,-5], [0,0,0], color,alpha);
		R_PolygonVertex(pos + [5,-5,5], [0,0,0], color,alpha);
		R_PolygonVertex(pos + [-5,-5,5], [0,0,0], color,alpha);
		R_EndPolygon();
		//Back face
		R_PolygonVertex(pos + [-5,5,-5], [0,0,0], color,alpha);
		R_PolygonVertex(pos + [5,5,-5], [0,0,0], color,alpha);
		R_PolygonVertex(pos + [5,5,5], [0,0,0], color,alpha);
		R_PolygonVertex(pos + [-5,5,5], [0,0,0], color,alpha);
		R_EndPolygon();
		//Left face
		R_PolygonVertex(pos + [-5,-5,-5], [0,0,0], color,alpha);
		R_PolygonVertex(pos + [-5,5,-5], [0,0,0], color,alpha);
		R_PolygonVertex(pos + [-5,5,5], [0,0,0], color,alpha);
		R_PolygonVertex(pos + [-5,-5,5], [0,0,0], color,alpha);
		R_EndPolygon();
		//Right face
		R_PolygonVertex(pos + [5,-5,-5], [0,0,0], color,alpha);
		R_PolygonVertex(pos + [5,5,-5], [0,0,0], color,alpha);
		R_PolygonVertex(pos + [5,5,5], [0,0,0], color,alpha);
		R_PolygonVertex(pos + [5,-5,5], [0,0,0], color,alpha);
		R_EndPolygon();
		
		if(i > 0)
		{
			//Draw an edge connecting ith node to previous node
			R_PolygonVertex(cl_navmesh_polies[cl_test_pathfind_result.result_node_path[i]].center + [0,0,-5] + [0,0,-edge_width], [0,0,0], color, edge_alpha);
			R_PolygonVertex(cl_navmesh_polies[cl_test_pathfind_result.result_node_path[i]].center + [0,0,-5] + [0,0,edge_width], [0,0,0], color, edge_alpha);
			R_PolygonVertex(cl_navmesh_polies[cl_test_pathfind_result.result_node_path[i-1]].center + [0,0,-5] + [0,0,edge_width], [0,0,0], color, edge_alpha);
			R_PolygonVertex(cl_navmesh_polies[cl_test_pathfind_result.result_node_path[i-1]].center + [0,0,-5] + [0,0,-edge_width], [0,0,0], color, edge_alpha);
			R_EndPolygon();
		}
	}
	
	
}


void cl_navmesh_pathfind_draw_result_portals()
{
	if(cl_test_pathfind_result.portals_length < 1)
		return;
	vector color;
	color = [0.5,0.5,1.0];
	float edge_width = 4;
	float edge_alpha = 0.2;//0.3
	
	for(float i = 0; i < cl_test_pathfind_result.portals_length; i++)
	{
		cl_navmesh_draw_vert(cl_navmesh_verts[cl_test_pathfind_result.portals_left_vert[i]].pos + [0,0,-10],[0.5,0.5,1],0.4);
		cl_navmesh_draw_vert(cl_navmesh_verts[cl_test_pathfind_result.portals_right_vert[i]].pos + [0,0,-8],[0.5,1,0.5],0.4);
		
		R_BeginPolygon("debug/wireframe",0);
		R_BeginPolygon("debug/solid_nocull",0);
		
		//Draw an edge connecting portals
		R_PolygonVertex(cl_navmesh_verts[cl_test_pathfind_result.portals_left_vert[i]].pos + [0,0,-10] + [0,0,-edge_width], [0,0,0], color, edge_alpha);
		R_PolygonVertex(cl_navmesh_verts[cl_test_pathfind_result.portals_left_vert[i]].pos + [0,0,-10] + [0,0,edge_width], [0,0,0], color, edge_alpha);
		R_PolygonVertex(cl_navmesh_verts[cl_test_pathfind_result.portals_right_vert[i]].pos + [0,0,-8] + [0,0,edge_width], [0,0,0], color, edge_alpha);
		R_PolygonVertex(cl_navmesh_verts[cl_test_pathfind_result.portals_right_vert[i]].pos + [0,0,-8] + [0,0,-edge_width], [0,0,0], color, edge_alpha);
		R_EndPolygon();
	}
}

void cl_navmesh_pathfind_draw_result_path()
{		
	if(cl_test_pathfind_result.result_length < 1)
		return;
		
	vector color;
	color = [1.0,0.0,0.0];
	float edge_width = 4;
	float edge_alpha = 0.2;//0.3
	
	//Drawing the a line connecting the start and first path node
	cl_navmesh_draw_vert(startent_pos + [0,0,10],[1,0,0],0.4);
	R_BeginPolygon("debug/wireframe",0);
	R_BeginPolygon("debug/solid_nocull",0);
	
	//Draw an edge connecting portals
	R_PolygonVertex(cl_test_pathfind_result.result_path[0] + [0,0,10] + [0,0,-edge_width], [0,0,0], color, edge_alpha);
	R_PolygonVertex(cl_test_pathfind_result.result_path[0] + [0,0,10] + [0,0,edge_width], [0,0,0], color, edge_alpha);
	R_PolygonVertex(startent_pos + [0,0,10] + [0,0,edge_width], [0,0,0], color, edge_alpha);
	R_PolygonVertex(startent_pos + [0,0,10] + [0,0,-edge_width], [0,0,0], color, edge_alpha);
	R_EndPolygon();
	
	
	for(float i = 0; i < cl_test_pathfind_result.result_length; i++)
	{
		cl_navmesh_draw_vert(cl_test_pathfind_result.result_path[i] + [0,0,10],[1,0,0],0.4);
		
		if(i > 0)
		{
			R_BeginPolygon("debug/wireframe",0);
			R_BeginPolygon("debug/solid_nocull",0);
			
			//Draw an edge connecting portals
			R_PolygonVertex(cl_test_pathfind_result.result_path[i] + [0,0,10] + [0,0,-edge_width], [0,0,0], color, edge_alpha);
			R_PolygonVertex(cl_test_pathfind_result.result_path[i] + [0,0,10] + [0,0,edge_width], [0,0,0], color, edge_alpha);
			R_PolygonVertex(cl_test_pathfind_result.result_path[i-1] + [0,0,10] + [0,0,edge_width], [0,0,0], color, edge_alpha);
			R_PolygonVertex(cl_test_pathfind_result.result_path[i-1] + [0,0,10] + [0,0,-edge_width], [0,0,0], color, edge_alpha);
			R_EndPolygon();
		}
	}
}

void cl_toggle_navmesh_editor()
{
	
	if(cl_navmesh_mode == TRUE)
	{
		print("cl_navmesh editor: 0\n");
		cl_navmesh_mode = FALSE;
		
		//TEST NAVMESH CLEARING
		// cl_navgen_free_all_verts();
	}
	else
	{
		print("cl_navmesh editor: 1\n");
		cl_navmesh_mode = TRUE;
		cl_navmesh_deselect_all();

		//TEST NAVMESH GENERATION
		navgen_start();
		
		//TEST NAVMESH GENERATION
		// cl_navmesh_gen_navmesh();
	}
}


void() cl_register_navmesh_commands = 
{
	registercommand("nav_editor");
	registercommand("nav_place_vert");
	registercommand("nav_delete_verts");
	registercommand("nav_select_vert");
	registercommand("nav_deselect_vert");
	registercommand("nav_deselect_all");
	registercommand("nav_make_poly");
	registercommand("nav_delete_poly");
	registercommand("nav_resolve_corner");
	registercommand("nav_place_corner");
	registercommand("nav_cancel_corner");
	registercommand("nav_confirm_corner");
	registercommand("nav_calc_connected_polies");
	registercommand("nav_calc_poly_centers");
	registercommand("navtest_place_goal");
	registercommand("navtest_place_start");
	registercommand("nav_save_navmesh");
	registercommand("nav_clear_navmesh");
	registercommand("y");
	registercommand("yes");
	registercommand("nav_load_navmesh");
	
	// cl_navgen_register_commands();
}

float cl_confirm_clear_navmesh;

float(string cmd) cl_navmesh_console_commands = 
{
	tokenize(cmd);
	switch(argv(0))
	{
		case "nav_editor":
			cl_toggle_navmesh_editor();
			return TRUE;
		default:
			break;
	}
	
	//nav_clear_navmesh must be run twice consecutively to execute it (for safety)
	switch(argv(0))
	{
		case "nav_clear_navmesh":
			cl_confirm_clear_navmesh = 1;
			print("Are you sure you want to clear the navmesh? All unsaved changes will be lost.\n");
			return TRUE;
		case "y":
		case "yes":
			if(cl_confirm_clear_navmesh == 1)
			{
				print("Navmesh cleared.\n");
				cl_navmesh_editor_clear_navmesh();
			}
			cl_confirm_clear_navmesh = 0;
			return TRUE;
		default:
			cl_confirm_clear_navmesh = 0;
			break;
	}	
	
	if(!cl_navmesh_mode)
		return FALSE;
	switch(argv(0))
	{
		case "nav_place_vert":
			cl_navmesh_place_vert();
			return TRUE;
		case "nav_delete_verts":
			cl_navmesh_delete_verts();
			return TRUE;
		case "nav_select_vert":
			cl_navmesh_select_vert();
			return TRUE;
		case "nav_deselect_vert":
			cl_navmesh_deselect_vert();
			return TRUE;
		case "nav_deselect_all":
			cl_navmesh_deselect_all();
			print("All vertices deselected.\n");
			return TRUE;
		case "nav_make_poly":
			cl_navmesh_make_poly();
			return TRUE;
		case "nav_delete_poly":
			cl_navmesh_delete_poly();
			return TRUE;
		case "nav_resolve_corner":
			cl_navmesh_resolve_corner();
			return TRUE;
		case "nav_place_corner":
			cl_navmesh_place_corner();
			return TRUE;
		case "nav_cancel_corner":
			cl_navmesh_cancel_corner();
			return TRUE;
		case "nav_confirm_corner":
			cl_navmesh_confirm_corner();
			return TRUE;
		case "nav_calc_connected_polies":
			cl_navmesh_calc_connected_polies();
			return TRUE;
		case "nav_calc_poly_centers":
			cl_navmesh_calc_polies_centers();
			return TRUE;
		case "navtest_place_goal":
			cl_navmesh_place_test_goalent();
			return TRUE;
		case "navtest_place_start":
			cl_navmesh_place_test_startent();
			return TRUE;
		case "nav_save_navmesh":
			cl_navmesh_editor_save_navmesh();
			return TRUE;
		case "nav_load_navmesh":
			cl_navmesh_editor_load_navmesh();
			return TRUE;
		default:
			break;
	}
	// return cl_navgen_console_commands(cmd);
	return FALSE;
}