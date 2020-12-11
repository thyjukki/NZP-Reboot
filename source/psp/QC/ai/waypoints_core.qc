float waypoint_action;

void () Waypoint_Functions =
{
	switch (self.impulse)
	{
		case 15:
			Make_Special_Waypoint();
			break;
		case 10:
			Move_Waypoint();
			break;
		case 18:
			Remove_Waypoint ();
			break;
		case 21:
			Link_Waypoints ();
			break;
		case 20: 
			Dual_Link_Waypoints();
			break;
		case 22: 
			Auto_Link_Waypoints();
			break;
		case 101:
			Save_Waypoints();
			break;
		case 102:
			Load_Waypoints();
			break;
	}
	
	if(self.button8 && !self.semi)
	{
		self.semi = true;
		Dual_Link_Waypoints();
		waypoint_action = waypoint_action + 1;
	}
	if (self.button0 && !self.semi)
	{
		Create_New_Waypoint();
		waypoint_action = waypoint_action + 1;
		self.semi = true;
	}
	
	if (self.button7 && !self.semiuse)
	{
		Select_Waypoint();
		waypoint_action = waypoint_action + 1;
		self.semiuse = true;
	}
	
	if(self.button4 && !self.semiuse)
	{
		self.semiuse = true;
		waypoint_action = waypoint_action + 1;
		Move_Waypoint();
	}
	if(self.button6 && !self.semiuse)
	{
		Remove_Waypoint ();
		waypoint_action = waypoint_action + 1;
		self.semiuse = true;
	}
	if(self.button5 && !self.semiuse)
	{
		Make_Special_Waypoint();
		waypoint_action = waypoint_action + 1;
		self.semiuse = true;
	}
	
	if(!self.button0 && !self.button7 && !self.button4 && !self.button5 && !self.button6 && !self.button8)
	{
		self.semiuse = false;
		self.semi = false;
	}
	
	self.impulse = 0;
};

void () Waypoint_Logic =
{
	if (waypoint_action > 20) {
		if (cvar("autosave_waypoint"))
			Save_Waypoints();
		waypoint_action = 0;
	}
		
	Waypoint_Functions();
};