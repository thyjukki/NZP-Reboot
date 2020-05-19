//List of all navmesh verts loaded on the server
navmesh_vertex sv_navmesh_verts[NAV_MAX_VERTS];
float sv_navmesh_vert_count;

//List of all navmesh polies loaded on the server
navmesh_poly sv_navmesh_polies[NAV_MAX_POLIES];
float sv_navmesh_poly_count;

void () Navmesh_Editor_Logic =
{
	if (!navmesh_edit_mode) {
		navmesh_edit_mode = 1;

		// ------------------------------------
		// Remove and disable all zombies
		// ------------------------------------
		entity zent;
	
		zent = find (world, classname, "ai_zombie");
		while (zent)
		{
			remove (zent);
			zent = find (zent, classname, "ai_zombie");
		}

		// -----------------------------------------
		// Reset all doors and rename to "door_nzp"
		// -----------------------------------------

		zent = find (world, classname, "door_nzp_cost");
		while (zent)
		{
			zent.solid = SOLID_NOT;
			zent.touch = SUB_Null;
			zent = find (zent, classname, "door_nzp_cost");
		}
		zent = find (world, classname, "door_nzp");
		while (zent)
		{
			zent.solid = SOLID_NOT;
			zent.touch = SUB_Null;
			zent.solid = SOLID_NOT;
			zent = find (zent, classname, "door_nzp");
		}
		zent = find (world, classname, "window");
		while (zent)
		{
			zent.solid = SOLID_NOT;
			zent.touch = SUB_Null;
			zent = find (zent, classname, "window");
		}
		
	}
	// FIXME - Does navmesh need this?
	// We do need to modify the server, as doors need to be set to nonsolid,
	// but the client-side navmesh editor / functions is pretty nifty...
	// Waypoint_Functions();
};


void sv_load_navmesh_data()
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
		
	//First line contains vertex count
	string line = fgets(file);
	
	float vert_count = stof(line);
	
	if(vert_count > sv_navmesh_verts.length)
	{
		print("Error: navmesh file \"",filepath,"\" has an invalid vert count. (" , line, " > ", ftos(sv_navmesh_verts.length),").\n");
		fclose(file);
		return;
	}
	
	//The navmesh appears to be valid (we shouldn't need to clear the current navmesh values)
	sv_navmesh_vert_count = vert_count;
	
	//Temp vector to assign component-wise
	vector temp;
	

	//Reading all of the vertex positions
	for(float i = 0; i < sv_navmesh_vert_count; i++)
	{
		line = fgets(file);
		temp = stov(line);
		sv_navmesh_verts[i].pos.x = temp.x;
		sv_navmesh_verts[i].pos.y = temp.y;
		sv_navmesh_verts[i].pos.z = temp.z;
	}
	
	//Next line contains the number of polygons
	sv_navmesh_poly_count = stof(fgets(file));
	
	//The next lines are each polygon
	for(float i = 0; i < sv_navmesh_poly_count; i++)
	{
		//Getting vertex count
		sv_navmesh_polies[i].vert_count = stof(fgets(file));
		//Getting vertices
		sv_navmesh_polies[i].verts[0] = stof(fgets(file));
		sv_navmesh_polies[i].verts[1] = stof(fgets(file));
		sv_navmesh_polies[i].verts[2] = stof(fgets(file));
		sv_navmesh_polies[i].verts[3] = stof(fgets(file));
		//Getting polygon center
		temp = stov(fgets(file));
		sv_navmesh_polies[i].center.x = temp.x;
		sv_navmesh_polies[i].center.y = temp.y;
		sv_navmesh_polies[i].center.z = temp.z;
		//Getting link count
		sv_navmesh_polies[i].connected_polies_count = stof(fgets(file));
		//Getting links FIXME HANDLE DIRECTIONAL LINKS
		sv_navmesh_polies[i].connected_polies[0] = stof(fgets(file));
		sv_navmesh_polies[i].connected_polies[1] = stof(fgets(file));
		sv_navmesh_polies[i].connected_polies[2] = stof(fgets(file));
		sv_navmesh_polies[i].connected_polies[3] = stof(fgets(file));
		//Getting link edge left vertex
		sv_navmesh_polies[i].connected_polies_left_vert[0] = stof(fgets(file));
		sv_navmesh_polies[i].connected_polies_left_vert[1] = stof(fgets(file));
		sv_navmesh_polies[i].connected_polies_left_vert[2] = stof(fgets(file));
		sv_navmesh_polies[i].connected_polies_left_vert[3] = stof(fgets(file));
		//Getting link edge right vertex
		sv_navmesh_polies[i].connected_polies_right_vert[0] = stof(fgets(file));
		sv_navmesh_polies[i].connected_polies_right_vert[1] = stof(fgets(file));
		sv_navmesh_polies[i].connected_polies_right_vert[2] = stof(fgets(file));
		sv_navmesh_polies[i].connected_polies_right_vert[3] = stof(fgets(file));
	}
	fclose(file);
}


//Navmesh functions used in pathfinding

//Returns 1 if pos is inside poly at index poly_index, 0 otherwise
float sv_navmesh_is_inside_poly(vector pos, float poly_index)
{
	//TODO: check if z coord is close enough to poly
	
	local vector vert_to_pos;//points from vert to pos
	local vector vert_to_next;//points from vert to the next vertex
	local vector vert;
	local vector next_vert;
	float vert_count = sv_navmesh_polies[poly_index].vert_count;
	//We are considered to be in the polygon, if pos is on the left of all edges of the polygon (if verts are ordered in CW order)
	for(float i = 0; i < vert_count; i++)
	{
		vert = sv_navmesh_verts[sv_navmesh_polies[poly_index].verts[i]].pos;
		next_vert = sv_navmesh_verts[sv_navmesh_polies[poly_index].verts[(i + 1) % vert_count]].pos;
		
		vert_to_pos = pos - vert;
		vert_to_next = next_vert - vert;
		
		//Check if vert_to_pos is to the left of vert_to_next
		if(vert_to_next.x * vert_to_pos.y - vert_to_next.y * vert_to_pos.x < 0)
			return 0;
	}
	
	return 1;
}


//Returns distance from pos to an edge of the poly if pos is very close to an edge of the poly at index poly_index, -1 otherwise
float sv_navmesh_dist_to_poly(vector pos, float poly_index)
{
	float leeway = 30;//Must be within 30 qu of edge to be considered close
	
	//TODO: check if close enough on z-axis
	local vector vert;
	local vector next_vert;
	float vert_count = sv_navmesh_polies[poly_index].vert_count;
	
	float shortest_dist = 100000;
	
	//Only considering 2D
	//pos.z = 0;
	
	//We are considered to be in the polygon, if pos is on the left of all edges of the polygon (if verts are ordered in CW order)
	for(float i = 0; i < vert_count; i++)
	{
		vert = sv_navmesh_verts[sv_navmesh_polies[poly_index].verts[i]].pos;
		next_vert = sv_navmesh_verts[sv_navmesh_polies[poly_index].verts[(i + 1) % vert_count]].pos;
		
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
float sv_navmesh_get_containing_poly(vector pos)
{
	//Get nearest polygon, and check if pos is in that polygon
	float closest_poly = -1;
	float closest_poly_dist = 1000000;
	
	//In reality, there's no need to try ALL polygons, the one we are in should be within the nearest 10 or so, but checking all to be safe
	for(float i = 0; i < sv_navmesh_poly_count; i++)
	{
		//Check if we are sufficiently close enough to polygon i in the z-axis
		//Current method of checking: if pos is within 30 qu of polygon z-axis bounds
		float poly_min_z = sv_navmesh_verts[sv_navmesh_polies[i].verts[0]].pos.z;
		float poly_max_z = poly_min_z;

		for(float j = 0; j < sv_navmesh_polies[i].vert_count; j++)
		{
			float vert_z = sv_navmesh_verts[sv_navmesh_polies[i].verts[j]].pos.z;
			poly_min_z = min(poly_min_z, vert_z);
			poly_max_z = max(poly_max_z, vert_z);
		}

		// If we NOT between [min - 30, max + 30], skip this polygon
		// if(fabs(sv_navmesh_polies[0].center.z - pos.z) >= 30)
		if(pos.z < poly_min_z - 30 || pos.z > poly_max_z + 30)
		{
			continue;
		}
		
		
		//Check if we are in polygon i
		if(sv_navmesh_is_inside_poly(pos,i))
		{
			// NOTE - Because is_inside_poly only checks if we are in it on X & Y axes,
			// NOTE   we may have found a polygon on a floor below us or above us.
			// NOTE   However, this may not be an issue. A polygon on a floor below
			// NOTE   us would be at least about 80-ish qu away, and the checks done for 
			// NOTE   z proximity might be enough to stop us from choosing polygons on 
			// NOTE   different floors. I shall assume this works fine, and wait for a 
			// NOTE   counter-example that shows we'll need a more sophisticated strategy.
			//print("Ent pos is inside poly: ",ftos(i),".\n");
			return i;
		}
		
		//If we are not in polygon i, check if we arse very close to one of its edges
		float dist = sv_navmesh_dist_to_poly(pos,i);
		
		if(dist >= 0)
		{
			if(dist < closest_poly_dist)
			{
				closest_poly = i;
				closest_poly_dist = dist;
			}
		}

	}
	//============================================
	
	/*if(closest_poly == -1)
	{
		print("Ent pos is not in or near any polygons.\n");
	}
	else
	{
		print("Ent pos is near but not in poly: closest_poly.\n");
	}*/
	
	return closest_poly;
}
