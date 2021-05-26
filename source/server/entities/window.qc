.float rebuild_time;

void() spawn_boxes =
{
	makevectors(self.angles);
	
	self.box1 = self.origin + (v_forward * -30) + (v_up * -32);
	self.box2 = self.box1 + (v_right * 30);	
	self.box3 = self.box1 + (v_right * -30);
	self.idlebox = self.box1 + (v_forward * -30);
	
	self.hop_spot = self.origin + v_forward * 40;
	self.hop_spot_z -= 30;//We want this to be a little bit above the ground still
};

void() screen_shake =
{
	local float r,s,zoom_factor;
	r = crandom();
	s = random();
  if (self.enemy.zoom == 2 || self.enemy.zoom == 1)
    zoom_factor = 0.5;
  else
    zoom_factor = 1;
	
	#ifdef PSP
    self.enemy.punchangle_y = r * 8 * zoom_factor;
    self.enemy.punchangle_x = (4 + (s * 4)) * zoom_factor;
	#else
	self.enemy.punchangle_y = r * 4 * zoom_factor;
    self.enemy.punchangle_x = (4 + (s * 2)) * zoom_factor;
	#endif
};

void() Window_repaired =
{
	if (maxreward > totalreward)
	{
		sound(self, 0,"sounds/misc/ching.wav", 1, 0);
		addmoney(self.enemy, 10, 1);
		totalreward = totalreward + 10;
	}
	screen_shake();
	self.enemy = world;
};

void() Barricade_hit_window =
{
	sound(self, 0, self.oldmodel, 1, 0);
}

void(void() next) checkForSpeed = {
	if (!(other.perks & P_SPEED))
		return;
	
	next();
}

////////////////////////////////////////////////////////////////////////////////////////////  ANIMATIONS
//0-6
//7-13
//14-20
//21-27
//28-34
//35-41
void()	window_anim1_1		=[	1,		window_anim1_2	] 	{self.frame = 0;self.nextthink = time + 0.05;};
void()	window_anim1_2		=[	2,		window_anim1_3	] 	{self.frame = 1;self.nextthink = time + 0.05;};
void()	window_anim1_3		=[	3,		window_anim1_4	] 	{self.frame = 2;self.nextthink = time + 0.05;};
void()	window_anim1_4		=[	4,		window_anim1_5	] 	{self.frame = 3;self.nextthink = time + 0.05;};
void()	window_anim1_5		=[	5,		window_anim1_6	] 	{self.frame = 4;self.nextthink = time + 0.05;};
void()	window_anim1_6		=[	6,		window_anim1_7	] 	{self.frame = 5;self.nextthink = time + 0.05;};
void()	window_anim1_7		=[	7,		SUB_Null		] 	{self.frame = 6;self.nextthink = time + 0.05;};

void()	window_anim2_1		=[	1,		window_anim2_2	] 	{self.frame = 7;self.nextthink = time + 0.05;};
void()	window_anim2_2		=[	2,		window_anim2_3	] 	{self.frame = 8;self.nextthink = time + 0.05;};
void()	window_anim2_3		=[	3,		window_anim2_4	] 	{self.frame = 9;self.nextthink = time + 0.05;};
void()	window_anim2_4		=[	4,		window_anim2_5	] 	{self.frame = 10;self.nextthink = time + 0.05;};
void()	window_anim2_5		=[	5,		window_anim2_6	] 	{self.frame = 11;self.nextthink = time + 0.05;};
void()	window_anim2_6		=[	6,		window_anim2_7	] 	{self.frame = 12;self.nextthink = time + 0.05;};
void()	window_anim2_7		=[	7,		SUB_Null		] 	{self.frame = 13;self.nextthink = time + 0.05;};

void()	window_anim3_1		=[	1,		window_anim3_2	] 	{self.frame = 14;self.nextthink = time + 0.05;};
void()	window_anim3_2		=[	2,		window_anim3_3	] 	{self.frame = 15;self.nextthink = time + 0.05;};
void()	window_anim3_3		=[	3,		window_anim3_4	] 	{self.frame = 16;self.nextthink = time + 0.05;};
void()	window_anim3_4		=[	4,		window_anim3_5	] 	{self.frame = 17;self.nextthink = time + 0.05;};
void()	window_anim3_5		=[	5,		window_anim3_6	] 	{self.frame = 18;self.nextthink = time + 0.05;};
void()	window_anim3_6		=[	6,		window_anim3_7	] 	{self.frame = 19;self.nextthink = time + 0.05;};
void()	window_anim3_7		=[	7,		SUB_Null		] 	{self.frame = 20;self.nextthink = time + 0.05;};

void()	window_anim4_1		=[	1,		window_anim4_2	] 	{self.frame = 21;self.nextthink = time + 0.05;};
void()	window_anim4_2		=[	2,		window_anim4_3	] 	{self.frame = 22;self.nextthink = time + 0.05;};
void()	window_anim4_3		=[	3,		window_anim4_4	] 	{self.frame = 23;self.nextthink = time + 0.05;};
void()	window_anim4_4		=[	4,		window_anim4_5	] 	{self.frame = 24;self.nextthink = time + 0.05;};
void()	window_anim4_5		=[	5,		window_anim4_6	] 	{self.frame = 25;self.nextthink = time + 0.05;};
void()	window_anim4_6		=[	6,		window_anim4_7	] 	{self.frame = 26;self.nextthink = time + 0.05;};
void()	window_anim4_7		=[	7,		SUB_Null		] 	{self.frame = 27;self.nextthink = time + 0.05;};

void()	window_anim5_1		=[	1,		window_anim5_2	] 	{self.frame = 28;self.nextthink = time + 0.05;};
void()	window_anim5_2		=[	2,		window_anim5_3	] 	{self.frame = 29;self.nextthink = time + 0.05;};
void()	window_anim5_3		=[	3,		window_anim5_4	] 	{self.frame = 30;self.nextthink = time + 0.05;};
void()	window_anim5_4		=[	4,		window_anim5_5	] 	{self.frame = 31;self.nextthink = time + 0.05;};
void()	window_anim5_5		=[	5,		window_anim5_6	] 	{self.frame = 32;self.nextthink = time + 0.05;};
void()	window_anim5_6		=[	6,		window_anim5_7	] 	{self.frame = 33;self.nextthink = time + 0.05;};
void()	window_anim5_7		=[	7,		SUB_Null		] 	{self.frame = 34;self.nextthink = time + 0.05;};

void()	window_anim6_1		=[	1,		window_anim6_2	] 	{self.frame = 35;self.nextthink = time + 0.05;};
void()	window_anim6_2		=[	2,		window_anim6_3	] 	{self.frame = 36;self.nextthink = time + 0.05;};
void()	window_anim6_3		=[	3,		window_anim6_4	] 	{self.frame = 37;self.nextthink = time + 0.05;};
void()	window_anim6_4		=[	4,		window_anim6_5	] 	{self.frame = 38;self.nextthink = time + 0.05;};
void()	window_anim6_5		=[	5,		window_anim6_6	] 	{self.frame = 39;self.nextthink = time + 0.05;};
void()	window_anim6_6		=[	6,		window_anim6_7	] 	{self.frame = 40;self.nextthink = time + 0.05;};
void()	window_anim6_7		=[	7,		SUB_Null		] 	{self.frame = 41;self.nextthink = time + 0.05;};
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//speed cola repair
//81-88
void()	window_srepair1_1	=[	1,		window_srepair1_2 ]	{self.frame = 81;};
void()	window_srepair1_2	=[	2,		window_srepair1_4 ]	{self.frame = 84;};
void()	window_srepair1_4	=[	3,		window_srepair1_5 ]	{self.frame = 87;Barricade_hit_window();};
void()	window_srepair1_5	=[	4,		SUB_Null 		  ]	{self.frame = 88; Window_repaired();};
//73-80
void()	window_srepair2_1	=[	1,		window_srepair2_2 ]	{self.frame = 73;};
void()	window_srepair2_2	=[	2,		window_srepair2_4 ]	{self.frame = 75;};
void()	window_srepair2_4	=[	3,		window_srepair2_5 ]	{self.frame = 79;Barricade_hit_window();};
void()	window_srepair2_5	=[	4,		SUB_Null 		  ]	{self.frame = 80; Window_repaired();};
//65-72
void()	window_srepair3_1	=[	1,		window_srepair3_2 ]	{self.frame = 65;};
void()	window_srepair3_2	=[	2,		window_srepair3_4 ]	{self.frame = 67;};
void()	window_srepair3_4	=[	3,		window_srepair3_5 ]	{self.frame = 71;Barricade_hit_window();};
void()	window_srepair3_5	=[	4,		SUB_Null 		  ]	{self.frame = 72; Window_repaired();};
//57-64
void()	window_srepair4_1	=[	1,		window_srepair4_2 ]	{self.frame = 57;};
void()	window_srepair4_2	=[	2,		window_srepair4_4 ]	{self.frame = 69;};
void()	window_srepair4_4	=[	3,		window_srepair4_5 ]	{self.frame = 63;Barricade_hit_window();};
void()	window_srepair4_5	=[	4,		SUB_Null 		  ]	{self.frame = 64; Window_repaired();};
//49-56
void()	window_srepair5_1	=[	1,		window_srepair5_2 ]	{self.frame = 49;};
void()	window_srepair5_2	=[	2,		window_srepair5_4 ]	{self.frame = 51;};
void()	window_srepair5_4	=[	3,		window_srepair5_5 ]	{self.frame = 55;Barricade_hit_window();};
void()	window_srepair5_5	=[	4,		SUB_Null 		  ]	{self.frame = 56; Window_repaired();};
//41-48
void()	window_srepair6_1	=[	1,		window_srepair6_2 ]	{self.frame = 41;};
void()	window_srepair6_2	=[	2,		window_srepair6_4 ]	{self.frame = 43;};
void()	window_srepair6_4	=[	3,		window_srepair6_5 ]	{self.frame = 47;Barricade_hit_window();};
void()	window_srepair6_5	=[	4,		SUB_Null 		  ]	{self.frame = 48; Window_repaired();};


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void()	window_repair1_1	=[	1,		window_repair1_2 ]	{self.frame = 81;};
void()	window_repair1_2	=[	2,		window_repair1_3 ]	{self.frame = 82;};
void()	window_repair1_3	=[	3,		window_repair1_4 ]	{self.frame = 83;};
void()	window_repair1_4	=[	4,		window_repair1_5 ]	{self.frame = 84;};
void()	window_repair1_5	=[	5,		window_repair1_6 ]	{self.frame = 85;};
void()	window_repair1_6	=[	6,		window_repair1_7 ]	{self.frame = 86;};
void()	window_repair1_7	=[	7,		window_repair1_8 ]	{self.frame = 87;Barricade_hit_window();};
void()	window_repair1_8	=[	8,		SUB_Null		 ]	{self.frame = 88; Window_repaired();};

void()	window_repair2_1	=[	1,		window_repair2_2 ]	{self.frame = 73;};
void()	window_repair2_2	=[	2,		window_repair2_3 ]	{self.frame = 74;};
void()	window_repair2_3	=[	3,		window_repair2_4 ]	{self.frame = 75;};
void()	window_repair2_4	=[	4,		window_repair2_5 ]	{self.frame = 76;};
void()	window_repair2_5	=[	5,		window_repair2_6 ]	{self.frame = 77;};
void()	window_repair2_6	=[	6,		window_repair2_7 ]	{self.frame = 78;};
void()	window_repair2_7	=[	7,		window_repair2_8 ]	{self.frame = 79;Barricade_hit_window();};
void()	window_repair2_8	=[	8,		SUB_Null		 ]	{self.frame = 80; Window_repaired();};

void()	window_repair3_1	=[	1,		window_repair3_2 ]	{self.frame = 65;};
void()	window_repair3_2	=[	2,		window_repair3_3 ]	{self.frame = 66;};
void()	window_repair3_3	=[	3,		window_repair3_4 ]	{self.frame = 67;};
void()	window_repair3_4	=[	4,		window_repair3_5 ]	{self.frame = 68;};
void()	window_repair3_5	=[	5,		window_repair3_6 ]	{self.frame = 69;};
void()	window_repair3_6	=[	6,		window_repair3_7 ]	{self.frame = 70;};
void()	window_repair3_7	=[	7,		window_repair3_8 ]	{self.frame = 71;Barricade_hit_window();};
void()	window_repair3_8	=[	8,		SUB_Null		 ]	{self.frame = 72; Window_repaired();};

void()	window_repair4_1	=[	1,		window_repair4_2 ]	{self.frame = 57;};
void()	window_repair4_2	=[	2,		window_repair4_3 ]	{self.frame = 58;};
void()	window_repair4_3	=[	3,		window_repair4_4 ]	{self.frame = 59;};
void()	window_repair4_4	=[	4,		window_repair4_5 ]	{self.frame = 60;};
void()	window_repair4_5	=[	5,		window_repair4_6 ]	{self.frame = 61;};
void()	window_repair4_6	=[	6,		window_repair4_7 ]	{self.frame = 62;};
void()	window_repair4_7	=[	7,		window_repair4_8 ]	{self.frame = 63;Barricade_hit_window();};
void()	window_repair4_8	=[	8,		SUB_Null		 ]	{self.frame = 64; Window_repaired();};

void()	window_repair5_1	=[	1,		window_repair5_2 ]	{self.frame = 49;};
void()	window_repair5_2	=[	2,		window_repair5_3 ]	{self.frame = 50;};
void()	window_repair5_3	=[	3,		window_repair5_4 ]	{self.frame = 51;};
void()	window_repair5_4	=[	4,		window_repair5_5 ]	{self.frame = 52;};
void()	window_repair5_5	=[	5,		window_repair5_6 ]	{self.frame = 53;};
void()	window_repair5_6	=[	6,		window_repair5_7 ]	{self.frame = 54;};
void()	window_repair5_7	=[	7,		window_repair5_8 ]	{self.frame = 55;Barricade_hit_window();};
void()	window_repair5_8	=[	8,		SUB_Null		 ]	{self.frame = 56; Window_repaired();};

void()	window_repair6_1	=[	1,		window_repair6_2 ]	{self.frame = 41;};
void()	window_repair6_2	=[	2,		window_repair6_3 ]	{self.frame = 42;};
void()	window_repair6_3	=[	3,		window_repair6_4 ]	{self.frame = 43;};
void()	window_repair6_4	=[	4,		window_repair6_5 ]	{self.frame = 44;};
void()	window_repair6_5	=[	5,		window_repair6_6 ]	{self.frame = 45;};
void()	window_repair6_6	=[	6,		window_repair6_7 ]	{self.frame = 46;};
void()	window_repair6_7	=[	7,		window_repair6_8 ]	{self.frame = 47;Barricade_hit_window();};
void()	window_repair6_8	=[	8,		SUB_Null		 ]	{self.frame = 48; Window_repaired();};

void()	window_carpenter_1	=[	1,		window_carpenter_2 	]	{self.frame = 47;sound(self, 0, self.oldmodel, 1, 1);};
void()	window_carpenter_2	=[	2,		window_carpenter_3 	]	{self.frame = 48;};
void()	window_carpenter_3	=[	3,		window_carpenter_4 	]	{self.frame = 55;sound(self, 1, self.oldmodel, 1, 1);};
void()	window_carpenter_4	=[	4,		window_carpenter_5 	]	{self.frame = 56;};
void()	window_carpenter_5	=[	5,		window_carpenter_6 	]	{self.frame = 63;sound(self, 2, self.oldmodel, 1, 1);};
void()	window_carpenter_6	=[	6,		window_carpenter_7 	]	{self.frame = 64;};
void()	window_carpenter_7	=[	7,		window_carpenter_8 	]	{self.frame = 71;sound(self, 0, self.oldmodel, 1, 1);};
void()	window_carpenter_8	=[	8,		window_carpenter_9 	]	{self.frame = 72;};
void()	window_carpenter_9	=[	7,		window_carpenter_10 ]		{self.frame = 79;sound(self, 1, self.oldmodel, 1, 1);};
void()	window_carpenter_10	=[	8,		window_carpenter_11	]	{self.frame = 80;};
void()	window_carpenter_11	=[	7,		window_carpenter_12 ]		{self.frame = 87;sound(self, 2, self.oldmodel, 1, 1);};
void()	window_carpenter_12	=[	8,		SUB_Null		 	]	{self.frame = 88;};


void() Window_Damage =
{
	if(self.health == 0)
		return;

	sound(self, CHAN_VOICE, self.aistatus, 1, 0);
	
	self.health = self.health - 1;
	
	if(self.health == 5)
	{
		window_anim1_1();
		total_windows_down = total_windows_down + 1;
	}
	else if(self.health == 4)
		window_anim2_1();
	else if(self.health == 3)
		window_anim3_1();
	else if(self.health == 2)
		window_anim4_1();
	else if(self.health == 1)
		window_anim5_1();
	else if(self.health == 0)
		window_anim6_1();

	ach_tracker_spin = 1;
};

void() Rebuild_Anims =
{
	if(self.health == 5)
	{
		if (other.perks & P_SPEED)
			window_srepair1_1();
		else
			window_repair1_1();

		total_windows_down = total_windows_down - 1;
	}
	else if(self.health == 4)
	{
		if (other.perks & P_SPEED)
			window_srepair2_1();
		else
			window_repair2_1();
	}
	else if(self.health == 3)
	{
		if (other.perks & P_SPEED)
			window_srepair3_1();
		else
			window_repair3_1();
	}
	else if(self.health == 2)
	{
		if (other.perks & P_SPEED)
			window_srepair4_1();
		else
			window_repair4_1();
	}
	else if(self.health == 1)
	{
		if (other.perks & P_SPEED)
			window_srepair5_1();
		else
			window_repair5_1();
	}
	else if(self.health == 0)
	{
		if (other.perks & P_SPEED)
			window_srepair6_1();
		else
			window_repair6_1();
	}
};
void() window_touch =
{
	if(other.classname == "player" && !other.downed && self.health != -10)
	{
		if(self.health < 6)
		{
			useprint (other, 5, 0, 0);
			
			if(other.button7)
			{
				if(self.rebuild_time < time)
				{
					self.enemy = other;
					Rebuild_Anims();
					self.health = self.health + 1;

					self.rebuild_time = time + 0.75;
				}
			}
		}
	}
};

void() item_barricade =
{
	if (self.spawnflags & 1) {
		self.health = -10; // Window is deactivated, to only hop over it
	} else {
		if (!self.model)
			self.model = "models/Misc/window.mdl";
		if (!self.oldmodel)
			self.oldmodel = "sounds/misc/barricade.wav";
		if (!self.aistatus)
			self.aistatus = "sounds/misc/barricade_destroy.wav";

		precache_model(self.model);
		precache_sound(self.oldmodel);
		precache_sound(self.aistatus);
	}

	self.classname = "window";
	self.touch = window_touch;
	self.solid = SOLID_TRIGGER;

	if (self.health != -10) {
		self.health = 6;
		setmodel(self, self.model);
	}

	setsize(self, '-20 -20 -64', '20 20 16');
	setorigin(self, self.origin);
	spawn_boxes();

	#ifndef PC
	windows[wincnt] = self;
	wincnt++;
	#endif
};

void() item_cover = {item_barricade();};