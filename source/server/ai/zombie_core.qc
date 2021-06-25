void() Zombie_Walk_Setup;
void() crawler_rip_board1;
void() crawler_da1;
void() crawler_die1;


float EMPTY_BBOX = 0;
float BASE_BBOX = 1;
float IDLE_BBOX = 2;
//Rising from ground bbox
float WALK1_BBOX = 4;
float WALK2_BBOX = 5;
float WALK3_BBOX = 6;
float JOG_BBOX = 7;
float RUN_BBOX = 8;
float CRAWLER_BBOX = 9;

void(float what) play_sound_z =
{
	if(self.classname == "ai_zombie")
	{
		local float e;
		e = random();
		
		if(what == 1)//attack
		{
			if (e < 0.125)
				sound(self,CHAN_VOICE,"sounds/zombie/a0.wav",1,ATTN_NORM);
			else if (e < 0.25)
				sound(self,CHAN_VOICE,"sounds/zombie/a1.wav",1,ATTN_NORM);
			else if (e < 0.375)
				sound(self,CHAN_VOICE,"sounds/zombie/a2.wav",1,ATTN_NORM);   
			else if( e < 0.5)
				sound(self,CHAN_VOICE,"sounds/zombie/a3.wav",1,ATTN_NORM);   
			else if( e < 0.625)
				sound(self,CHAN_VOICE,"sounds/zombie/a4.wav",1,ATTN_NORM);   
			else if( e < 0.75)
				sound(self,CHAN_VOICE,"sounds/zombie/a5.wav",1,ATTN_NORM);   
			else if( e < 0.875)
				sound(self,CHAN_VOICE,"sounds/zombie/a6.wav",1,ATTN_NORM);  
			else
				sound(self,CHAN_VOICE,"sounds/zombie/a7.wav",1,ATTN_NORM);   
			return;
		}
		if(what == 2)//walking!
		{
			
			if(self.s_time < time && self.s_time > 0)
			{
				sounds_playing --;
				self.s_time = 0;
			}
			if(sounds_playing >= 3)
			{
				return;
			}
			sounds_playing++;
			self.s_time = time + 1;
			
			
			if(self.sound_time < time)
			{
				play_sound_z(4);
				
				if(self.crawling == TRUE)
				{
					self.sound_time = time + 3 + random()*2;
					if(e < 0.2)
						sound(self,CHAN_VOICE,"sounds/zombie/t0.wav",1,ATTN_NORM);   
					else if (e < 0.4)
						sound(self,CHAN_VOICE,"sounds/zombie/t1.wav",1,ATTN_NORM);  
					else if (e < 0.6)
						sound(self,CHAN_VOICE,"sounds/zombie/t2.wav",1,ATTN_NORM);  
					else if (e < 0.8)
						sound(self,CHAN_VOICE,"sounds/zombie/t3.wav",1,ATTN_NORM);  
					else
						sound(self,CHAN_VOICE,"sounds/zombie/t4.wav",1,ATTN_NORM);  
					return;
				}					
				if(self.walktype == 1 || self.walktype == 2 || self.walktype == 3)
				{
					self.sound_time = time + 3 + random();
					if (e < 0.1)
						sound(self,CHAN_VOICE,"sounds/zombie/w0.wav",1,ATTN_NORM);   
					else if (e < 0.2)
						sound(self,CHAN_VOICE,"sounds/zombie/w1.wav",1,ATTN_NORM);   
					else if (e < 0.3)
						sound(self,CHAN_VOICE,"sounds/zombie/w2.wav",1,ATTN_NORM);   
					else if( e < 0.4)
						sound(self,CHAN_VOICE,"sounds/zombie/w3.wav",1,ATTN_NORM);   
					else if( e < 0.5)
						sound(self,CHAN_VOICE,"sounds/zombie/w4.wav",1,ATTN_NORM);   
					else if( e < 0.6)
						sound(self,CHAN_VOICE,"sounds/zombie/w5.wav",1,ATTN_NORM);
					else if( e < 0.7)
						sound(self,CHAN_VOICE,"sounds/zombie/w6.wav",1,ATTN_NORM);
					else if( e < 0.8)
						sound(self,CHAN_VOICE,"sounds/zombie/w7.wav",1,ATTN_NORM);
					else if( e < 0.9)
						sound(self,CHAN_VOICE,"sounds/zombie/w8.wav",1,ATTN_NORM);
					else
						sound(self,CHAN_VOICE,"sounds/zombie/w9.wav",1,ATTN_NORM);
					return;
				}
				else if(self.walktype == 4 || self.walktype == 5)
				{
					self.sound_time = time + 4 + random()*2;
					if (e < 0.1)
						sound(self,CHAN_VOICE,"sounds/zombie/r0.wav",1,ATTN_NORM);   
					else if (e < 0.2)
						sound(self,CHAN_VOICE,"sounds/zombie/r1.wav",1,ATTN_NORM);   
					else if (e < 0.3)
						sound(self,CHAN_VOICE,"sounds/zombie/r2.wav",1,ATTN_NORM);   
					else if( e < 0.4)
						sound(self,CHAN_VOICE,"sounds/zombie/r3.wav",1,ATTN_NORM);   
					else if( e < 0.5)
						sound(self,CHAN_VOICE,"sounds/zombie/r4.wav",1,ATTN_NORM);   
					else if( e < 0.6)
						sound(self,CHAN_VOICE,"sounds/zombie/r5.wav",1,ATTN_NORM);
					else if( e < 0.7)
						sound(self,CHAN_VOICE,"sounds/zombie/r6.wav",1,ATTN_NORM);
					else if( e < 0.8)
						sound(self,CHAN_VOICE,"sounds/zombie/r7.wav",1,ATTN_NORM);
					else if( e < 0.9)
						sound(self,CHAN_VOICE,"sounds/zombie/r8.wav",1,ATTN_NORM);
					else
						sound(self,CHAN_VOICE,"sounds/zombie/r9.wav",1,ATTN_NORM);
					return;
				}
				
			}
		}
		if(what == 3)//death!
		{
			if (e < 0.125)
				sound(self,CHAN_VOICE,"sounds/zombie/d0.wav",1,ATTN_NORM);
			else if (e < 0.25)
				sound(self,CHAN_VOICE,"sounds/zombie/d1.wav",1,ATTN_NORM);
			else if (e < 0.375)
				sound(self,CHAN_VOICE,"sounds/zombie/d2.wav",1,ATTN_NORM);   
			else if( e < 0.5)
				sound(self,CHAN_VOICE,"sounds/zombie/d3.wav",1,ATTN_NORM);   
			else if( e < 0.625)
				sound(self,CHAN_VOICE,"sounds/zombie/d4.wav",1,ATTN_NORM);   
			else if( e < 0.75)
				sound(self,CHAN_VOICE,"sounds/zombie/d5.wav",1,ATTN_NORM);   
			else if( e < 0.875)
				sound(self,CHAN_VOICE,"sounds/zombie/d6.wav",1,ATTN_NORM);  
			else
				sound(self,CHAN_VOICE,"sounds/zombie/d7.wav",1,ATTN_NORM);   
			return;
			
		}
		if(what == 4)//Taunt!
		{
			if(random() < 0.83)
				return;
			
			if(e < 0.2)
				sound(self,CHAN_VOICE,"sounds/zombie/t0.wav",1,ATTN_NORM);   
			else if (e < 0.4)
				sound(self,CHAN_VOICE,"sounds/zombie/t1.wav",1,ATTN_NORM);  
			else if (e < 0.6)
				sound(self,CHAN_VOICE,"sounds/zombie/t2.wav",1,ATTN_NORM);  
			else if (e < 0.8)
				sound(self,CHAN_VOICE,"sounds/zombie/t3.wav",1,ATTN_NORM);  
			else
				sound(self,CHAN_VOICE,"sounds/zombie/t4.wav",1,ATTN_NORM);  
			return;
		}
	}
};

void(float which) SetZombieHitBox =
{

	//Zombie's bbox is constant across all hitbox setups, so we don't update it.
	
	if(self.currentHitBoxSetup == which)
		return;
	
	switch(which)
	{
		case EMPTY_BBOX:
		{
			/*setorigin(self.head,'0 0 0');
			setsize (self.head, '0 0 0', '0 0 0');
			
			setorigin(self.larm, '0 0 0');
			setsize (self.larm, '0 0 0','0 0 0');
			
			setorigin(self.rarm, '0 0 0');
			setsize (self.rarm, '0 0 0','0 0 0');*/
			
			self.head.view_ofs = '0 0 0';
			self.rarm.view_ofs = '0 0 0';
			self.larm.view_ofs = '0 0 0';
			
			self.currentHitBoxSetup = EMPTY_BBOX;
			return;
		}
		case IDLE_BBOX: 
		{
			//setsize (self.head, '-5 -5 -5', '5 5 5');
			self.head.bbmins = '-5 -5 -5';
			self.head.bbmaxs = '5 5 5';
			self.head.view_ofs = '0 10 35';
	
			//setsize (self.larm, '-5 -5 -15', '5 5 15');
			self.larm.bbmins = '-5 -5 -15';
			self.larm.bbmaxs  = '5 5 15';
			self.larm.view_ofs = '-10 10 10';
	
			//setsize (self.rarm, '-5 -5 -15', '5 5 15');
			self.rarm.bbmins = '-5 -5 -15';
			self.rarm.bbmaxs = '5 5 15';
			self.rarm.view_ofs = '10 10 10';
			
			self.currentHitBoxSetup = IDLE_BBOX;
			return;
		}
		case WALK1_BBOX:
		{
			//setsize (self.head, '-5 -5 -5', '5 5 5');
			self.head.bbmins = '-5 -5 -5';
			self.head.bbmaxs = '5 5 5';
			self.head.view_ofs = '2 -3 35';
			
			//setsize (self.head, '-3 -8 30', '7 2 40');
			//self.head.view_ofs = '0 0 0';

			//setsize (self.larm, '-5 -7 -15', '5 7 15');
			self.larm.bbmins = '-5 -7 -15';
			self.larm.bbmaxs = '5 7 15';
			self.larm.view_ofs = '-10 -4 15';

			//setsize (self.rarm, '-5 -8 -11', '5 8 11');
			self.rarm.bbmins = '-5 -8 -11';
			self.rarm.bbmaxs = '5 8 11';
			self.rarm.view_ofs = '10 11 11';
			
			self.currentHitBoxSetup = WALK1_BBOX;
			return;
		}
		case WALK2_BBOX:
		{
			//setsize (self.head, '-7 -5 -5', '7 5 5');
			self.head.bbmins = '-7 -5 -5';
			self.head.bbmaxs = '7 5 5';
			self.head.view_ofs = '-11 6 36';

			//setsize (self.larm, '-5 -6 -15', '5 6 15');
			self.larm.bbmins = '-5 -6 -15';
			self.larm.bbmaxs = '5 6 15';
			self.larm.view_ofs = '-14 3 15';
	
			//setsize (self.rarm, '-5 -5 -11', '5 5 11');
			self.rarm.bbmins = '-5 -5 -11';
			self.rarm.bbmaxs = '5 5 11';
			self.rarm.view_ofs = '4 13 11';
			
			self.currentHitBoxSetup = WALK2_BBOX;
			return;
		}
		case WALK3_BBOX:
		{
			//setsize (self.head, '-5 -5 -5', '5 5 5');
			self.head.bbmins = '-5 -5 -5';
			self.head.bbmaxs = '5 5 5';
			self.head.view_ofs = '-2 13 31';
	
			//setsize (self.larm, '-4 -6 -14', '4 6 14');
			self.larm.bbmins = '-4 -6 -14';
			self.larm.bbmaxs = '4 6 14';
			self.larm.view_ofs = '-12 3 11';
	
			//setsize (self.rarm, '-5 -5 -11', '5 5 11');
			self.rarm.bbmins = '-5 -5 -11';
			self.rarm.bbmaxs = '5 5 11';
			self.rarm.view_ofs = '14 6 12';
			
			self.currentHitBoxSetup = WALK3_BBOX;
			return;
		}
		case JOG_BBOX:
		{
			//setsize (self.head, '-5 -5 -5', '5 5 5');
			self.head.bbmins = '-5 -5 -5';
			self.head.bbmaxs = '5 5 5';
			self.head.view_ofs = '0 5 36';
			
			//setsize (self.larm, '-5 -13 -5', '5 13 5');
			self.larm.bbmins = '-5 -13 -5';
			self.larm.bbmaxs = '5 13 5';
			self.larm.view_ofs = '-8 19 24';
			
			//setsize (self.rarm, '-5 -13 -5', '5 13 5');
			self.rarm.bbmins = '-5 -13 -5';
			self.rarm.bbmaxs = '5 13 5';
			self.rarm.view_ofs = '10 19 24';
			
			self.currentHitBoxSetup = JOG_BBOX;
			return;
		}
		case RUN_BBOX:
		{
			//setsize (self.head, '-5 -5 -5', '5 5 5');
			self.head.bbmins = '-5 -5 -5';
			self.head.bbmaxs = '5 5 5';
			self.head.view_ofs = '3 17 32';
	
			//setsize (self.larm, '-4 -10 -9', '4 10 9');
			self.larm.bbmins = '-4 -10 -9';
			self.larm.bbmaxs = '4 10 9';
			self.larm.view_ofs = '-12 28 18';
			
			//setsize (self.rarm, '-4 -13 -10', '4 13 10');
			self.rarm.bbmins = '-4 -13 -10';
			self.rarm.bbmaxs = '4 13 10';
			self.rarm.view_ofs = '12 -2 19';
			
			self.currentHitBoxSetup = RUN_BBOX;
			return;
		}
		case CRAWLER_BBOX:
		{
			self.head.bbmins = '-5 -5 -5';
			self.head.bbmaxs = '5 5 5';
			self.head.view_ofs = '2 18 -14';
	
			self.larm.bbmins = '-4 -10 -9';
			self.larm.bbmaxs = '4 10 9';
			self.larm.view_ofs = '-9 24 -27';
			
			self.rarm.bbmins = '-4 -13 -10';
			self.rarm.bbmaxs = '4 13 10';
			self.rarm.view_ofs = '12 15 -25';
			
			self.currentHitBoxSetup = CRAWLER_BBOX;
			return;
		}
		default:  //also known as BASE_BBOX
		{
			//setsize (self.head, '-5 -5 -5', '5 5 5');
			self.head.bbmins = '-5 -5 -5';
			self.head.bbmaxs = '5 5 5';
			self.head.view_ofs = '0 0 35';
			
			//setsize (self.larm, '-5 -5 -15', '5 5 15');
			self.larm.bbmins = '-5 -5 -15';
			self.larm.bbmaxs = '5 5 15';
			self.larm.view_ofs = '-10 0 5';
			
			//setsize (self.rarm, '-5 -5 -15', '5 5 15');
			self.rarm.bbmins = '-5 -5 -15';
			self.rarm.bbmaxs = '5 5 15';
			self.rarm.view_ofs = '10 0 5';
			
			self.currentHitBoxSetup = BASE_BBOX;
			return;
		}
	}
};

void() Zombie_Think = //called every frame for zombies
{
	if (self.onfire) {
		#ifdef PC
		te_flamejet(self.origin, v_up*8, 10);
		#else
		particle (self.origin, v_up*8, 0, 0);
		#endif

		if (self.ltime < time && self.onfire){
			DamageHandler(self, self.firer, 300, S_NORMAL);
			self.ltime = time + 2;

			self.spins++;
			if (self.spins >= 5) {
				self.spins = 0;
				self.onfire = false;
			}
		}
	}

	if (self.classname == "wunder") {
		self.th_diewunder();
		return;
	}

	if (self.bleedingtime < time && !self.head.deadflag)
	{
		self.bleedingtime = time + 2;
		DamageHandler (self, self.usedent, z_health * 0.05, S_HEADSHOT);
	}
}

//////////////////////////////////////////////////////////////////////
//37-51
/*
$frame walk1 walk2 walk3 walk4 walk5 walk6 walk7 walk8 walk9 walk10 walk11 walk12 walk13 walk14 walk15
void()	zombie_walk1		=[	$walk1,		zombie_walk2	] 	{self.nextthink = time + 0.1;Zombie_Walk(3.95);*/		/*if(freeze_time < time)*/		/* self.frame = 37;};
void()	zombie_walk2		=[	$walk2,		zombie_walk3	] 	{self.nextthink = time + 0.1;Zombie_Walk(1); self.frame = 38;};
void()	zombie_walk3		=[	$walk3,		zombie_walk4	] 	{self.nextthink = time + 0.1;Zombie_Walk(9.472); self.frame = 39;};
void()	zombie_walk4		=[	$walk4,		zombie_walk5	] 	{self.nextthink = time + 0.1;Zombie_Walk(5.046); self.frame = 40;};//FOOTSTEP
void()	zombie_walk5		=[	$walk5,		zombie_walk6	] 	{self.nextthink = time + 0.1;Zombie_Walk(6.425); self.frame = 41;};//
void()	zombie_walk6		=[	$walk6,		zombie_walk7	] 	{self.nextthink = time + 0.1;Zombie_Walk(6.299); self.frame = 42;};
void()	zombie_walk7		=[	$walk7,		zombie_walk8	] 	{self.nextthink = time + 0.1;Zombie_Walk(6.788); self.frame = 43;};
void()	zombie_walk8		=[	$walk8,		zombie_walk9	] 	{self.nextthink = time + 0.1;Zombie_Walk(5.516); self.frame = 44;};//FOOTSTEP
void()	zombie_walk9		=[	$walk9,		zombie_walk10	] 	{self.nextthink = time + 0.1;Zombie_Walk(2.191); self.frame = 45;};
void()	zombie_walk10		=[	$walk10,		zombie_walk11	] 	{self.nextthink = time + 0.1;Zombie_Walk(5.845); self.frame = 46;};
void()	zombie_walk11		=[	$walk11,		zombie_walk12	] 	{self.nextthink = time + 0.1;Zombie_Walk(7.42); self.frame = 47;};//FOOTSTEP
void()	zombie_walk12		=[	$walk12,		zombie_walk13	] 	{self.nextthink = time + 0.1;Zombie_Walk(2.683); self.frame = 48;};
void()	zombie_walk13		=[	$walk13,		zombie_walk14	] 	{self.nextthink = time + 0.1;Zombie_Walk(6.001); self.frame = 49;};
void()	zombie_walk14		=[	$walk14,		zombie_walk15	] 	{self.nextthink = time + 0.1;Zombie_Walk(5.845); self.frame = 50;};
void()	zombie_walk15		=[	$walk15,		Zombie_Walk_Setup	] 	{self.nextthink = time + 0.1;Zombie_Walk(6.793); self.frame = 51;};//FOOTSTEP
*/

void() zombie_footstep
{
	if(self.laststep == 1)
	{
		self.laststep = 0;
		sound(self,5,"sounds/zombie/s0.wav",1,ATTN_NORM);
	}
	else
	{
		self.laststep = 1;
		sound(self,5,"sounds/zombie/s1.wav",1,ATTN_NORM);
	}
}

//////////////////////////////////////////////////////////////////////
//37-52
$frame walk1 walk2 walk3 walk4 walk5 walk6 walk7 walk8 walk9 walk10 walk11 walk12 walk13 walk14 walk15 walk16
//walk15
//walk 1!
void()	zombie_walk1		=[	$walk1,		zombie_walk2	] 	{self.nextthink = time + 0.12;Zombie_Walk(8);SetZombieHitBox(WALK1_BBOX);/*if(freeze_time < time)*/ self.frame = 37;Zombie_Think();};
void()	zombie_walk2		=[	$walk2,		zombie_walk3	] 	{self.nextthink = time + 0.12;Zombie_Walk(3.5); self.frame = 38;Zombie_Think();};
void()	zombie_walk3		=[	$walk3,		zombie_walk4	] 	{self.nextthink = time + 0.12;Zombie_Walk(3.5); self.frame = 39;Zombie_Think();};
void()	zombie_walk4		=[	$walk4,		zombie_walk5	] 	{self.nextthink = time + 0.12;Zombie_Walk(3.5); self.frame = 40;Zombie_Think();};
void()	zombie_walk5		=[	$walk5,		zombie_walk6	] 	{self.nextthink = time + 0.12;Zombie_Walk(3.5); self.frame = 41;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_walk6		=[	$walk6,		zombie_walk7	] 	{self.nextthink = time + 0.12;Zombie_Walk(3.5); self.frame = 42;Zombie_Think();};
void()	zombie_walk7		=[	$walk7,		zombie_walk8	] 	{self.nextthink = time + 0.12;Zombie_Walk(8.8); self.frame = 43;Zombie_Think();};
void()	zombie_walk8		=[	$walk8,		zombie_walk9	] 	{self.nextthink = time + 0.12;Zombie_Walk(9); self.frame = 44;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_walk9		=[	$walk9,		zombie_walk10	] 	{self.nextthink = time + 0.12;Zombie_Walk(4); self.frame = 45;Zombie_Think();};
void()	zombie_walk10		=[	$walk10,		zombie_walk11	] 	{self.nextthink = time + 0.12;Zombie_Walk(4); self.frame = 46;Zombie_Think();};
void()	zombie_walk11		=[	$walk11,		zombie_walk12	] 	{self.nextthink = time + 0.12;Zombie_Walk(7.8); self.frame = 47;Zombie_Think();};
void()	zombie_walk12		=[	$walk12,		zombie_walk13	] 	{self.nextthink = time + 0.12;Zombie_Walk(5.2); self.frame = 48;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_walk13		=[	$walk13,		zombie_walk14	] 	{self.nextthink = time + 0.12;Zombie_Walk(2.4); self.frame = 49;Zombie_Think();};
void()	zombie_walk14		=[	$walk14,		zombie_walk15	] 	{self.nextthink = time + 0.12;Zombie_Walk(2.8); self.frame = 50;Zombie_Think();};
void()	zombie_walk15		=[	$walk15,		zombie_walk16	] 	{self.nextthink = time + 0.12;Zombie_Walk(6.5); self.frame = 51;Zombie_Think();};
void()	zombie_walk16		=[	$walk16,		Zombie_Walk_Setup	] 	{self.nextthink = time + 0.12;Zombie_Walk(7.7); self.frame = 52;Zombie_Think();zombie_footstep();};//footstep

/////////////////////////////////////////////////////////////////////////
//53-66
//Walk 2!
$frame bwalk1 bwalk2 bwalk3 bwalk4 bwalk5 bwalk6 bwalk7 bwalk8 bwalk9 bwalk10 bwalk11 bwalk12 bwalk13 bwalk14

void()	zombie_walkb1		=[	$bwalk1,		zombie_walkb2	] 	{self.nextthink = time + 0.13;Zombie_Walk(4.2);SetZombieHitBox(WALK2_BBOX);/*if(freeze_time < time)*/ self.frame = 53;Zombie_Think();};
void()	zombie_walkb2		=[	$bwalk2,		zombie_walkb3	] 	{self.nextthink = time + 0.13;Zombie_Walk(5.9); self.frame = 54;Zombie_Think();};
void()	zombie_walkb3		=[	$bwalk3,		zombie_walkb4	] 	{self.nextthink = time + 0.13;Zombie_Walk(3); self.frame = 55;Zombie_Think();};
void()	zombie_walkb4		=[	$bwalk4,		zombie_walkb5	] 	{self.nextthink = time + 0.13;Zombie_Walk(5.7); self.frame = 56;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_walkb5		=[	$bwalk5,		zombie_walkb6	] 	{self.nextthink = time + 0.13;Zombie_Walk(4.2); self.frame = 57;Zombie_Think();};
void()	zombie_walkb6		=[	$bwalk6,		zombie_walkb7	] 	{self.nextthink = time + 0.13;Zombie_Walk(7.2); self.frame = 58;Zombie_Think();};
void()	zombie_walkb7		=[	$bwalk7,		zombie_walkb8	] 	{self.nextthink = time + 0.13;Zombie_Walk(4.5); self.frame = 59;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_walkb8		=[	$bwalk8,		zombie_walkb9	] 	{self.nextthink = time + 0.13;Zombie_Walk(3.4); self.frame = 60;Zombie_Think();};
void()	zombie_walkb9		=[	$bwalk9,		zombie_walkb10	] 	{self.nextthink = time + 0.13;Zombie_Walk(1.2); self.frame = 61;Zombie_Think();};
void()	zombie_walkb10		=[	$bwalk10,		zombie_walkb11	] 	{self.nextthink = time + 0.13;Zombie_Walk(6.7); self.frame = 62;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_walkb11		=[	$bwalk11,		zombie_walkb12	] 	{self.nextthink = time + 0.13;Zombie_Walk(8.4); self.frame = 63;Zombie_Think();};
void()	zombie_walkb12		=[	$bwalk12,		zombie_walkb13	] 	{self.nextthink = time + 0.13;Zombie_Walk(1.3); self.frame = 64;Zombie_Think();};
void()	zombie_walkb13		=[	$bwalk13,		zombie_walkb14	] 	{self.nextthink = time + 0.13;Zombie_Walk(6.3); self.frame = 65;Zombie_Think();};
void()	zombie_walkb14		=[	$bwalk14,		Zombie_Walk_Setup	] 	{self.nextthink = time + 0.13;Zombie_Walk(3.6); self.frame = 66;Zombie_Think();zombie_footstep();};//footstep

/////////////////////////////////////////////////////////////////////////
//67-82
//Walk 3!
$frame cwalk1 cwalk2 cwalk3 cwalk4 cwalk5 cwalk6 cwalk7 cwalk8 cwalk9 cwalk10 cwalk11 cwalk12 cwalk13 cwalk14 cwalk15 cwalk16

void()	zombie_walkc1		=[	$cwalk1,		zombie_walkc2	] 	{self.nextthink = time + 0.13;Zombie_Walk(3.4);SetZombieHitBox(WALK3_BBOX);/*if(freeze_time < time)*/ self.frame = 67;Zombie_Think();};
void()	zombie_walkc2		=[	$cwalk2,		zombie_walkc3	] 	{self.nextthink = time + 0.13;Zombie_Walk(2); self.frame = 68;Zombie_Think();};
void()	zombie_walkc3		=[	$cwalk3,		zombie_walkc4	] 	{self.nextthink = time + 0.13;Zombie_Walk(5.4); self.frame = 69;Zombie_Think();};
void()	zombie_walkc4		=[	$cwalk4,		zombie_walkc5	] 	{self.nextthink = time + 0.13;Zombie_Walk(5.6); self.frame = 70;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_walkc5		=[	$cwalk5,		zombie_walkc6	] 	{self.nextthink = time + 0.13;Zombie_Walk(3); self.frame = 71;Zombie_Think();};
void()	zombie_walkc6		=[	$cwalk6,		zombie_walkc7	] 	{self.nextthink = time + 0.13;Zombie_Walk(3.1); self.frame = 72;Zombie_Think();};
void()	zombie_walkc7		=[	$cwalk7,		zombie_walkc8	] 	{self.nextthink = time + 0.13;Zombie_Walk(3); self.frame = 73;Zombie_Think();};
void()	zombie_walkc8		=[	$cwalk8,		zombie_walkc9	] 	{self.nextthink = time + 0.13;Zombie_Walk(2.9); self.frame = 74;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_walkc9		=[	$cwalk9,		zombie_walkc10	] 	{self.nextthink = time + 0.13;Zombie_Walk(3.3); self.frame = 75;Zombie_Think();};
void()	zombie_walkc10		=[	$cwalk10,		zombie_walkc11	] 	{self.nextthink = time + 0.13;Zombie_Walk(2.2); self.frame = 76;Zombie_Think();};
void()	zombie_walkc11		=[	$cwalk11,		zombie_walkc12	] 	{self.nextthink = time + 0.13;Zombie_Walk(3.7); self.frame = 77;Zombie_Think();};
void()	zombie_walkc12		=[	$cwalk12,		zombie_walkc13	] 	{self.nextthink = time + 0.13;Zombie_Walk(4.2); self.frame = 78;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_walkc13		=[	$cwalk13,		zombie_walkc14	] 	{self.nextthink = time + 0.13;Zombie_Walk(5.3); self.frame = 79;Zombie_Think();};
void()	zombie_walkc14		=[	$cwalk14,		zombie_walkc15	] 	{self.nextthink = time + 0.13;Zombie_Walk(5.2); self.frame = 80;Zombie_Think();};
void()	zombie_walkc15		=[	$cwalk15,		zombie_walkc16	] 	{self.nextthink = time + 0.13;Zombie_Walk(2.2); self.frame = 81;Zombie_Think();};
void()	zombie_walkc16		=[	$cwalk16,		Zombie_Walk_Setup	] 	{self.nextthink = time + 0.13;Zombie_Walk(2.4); self.frame = 82;Zombie_Think();zombie_footstep();};//footstep


/////////////////////////////////////////////////////////////////////
//116- 129
$frame jog1 jog2 jog3 jog4 jog5 jog6 jog7 jog8

void()	zombie_jog1		=[	$jog1,		zombie_jog2	] 	{self.nextthink = time + 0.08;Zombie_Walk(6);SetZombieHitBox(JOG_BBOX);/*if(freeze_time < time)*/ self.frame = 83;Zombie_Think();};//FOOTSTEP
void()	zombie_jog2		=[	$jog2,		zombie_jog3	] 		{self.nextthink = time + 0.08;Zombie_Walk(6); self.frame = 84;Zombie_Think();};
void()	zombie_jog3		=[	$jog3,		zombie_jog4	] 		{self.nextthink = time + 0.08;Zombie_Walk(6); self.frame = 85;Zombie_Think();};
void()	zombie_jog4		=[	$jog4,		zombie_jog5	] 		{self.nextthink = time + 0.08;Zombie_Walk(6); self.frame = 86;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_jog5		=[	$jog5,		zombie_jog6	] 		{self.nextthink = time + 0.08;Zombie_Walk(6); self.frame = 87;Zombie_Think();};
void()	zombie_jog6		=[	$jog6,		zombie_jog7	] 		{self.nextthink = time + 0.08;Zombie_Walk(6); self.frame = 88;Zombie_Think();};
void()	zombie_jog7		=[	$jog7,		zombie_jog8	] 		{self.nextthink = time + 0.08;Zombie_Walk(6); self.frame = 89;Zombie_Think();};
void()	zombie_jog8		=[	$jog8,		Zombie_Walk_Setup	] 	{self.nextthink = time + 0.08;Zombie_Walk(6); self.frame = 90;Zombie_Think();zombie_footstep();};//footstep

/////////////////////////////////////////////////////////////////////
//78-85
$frame run1 run2 run3 run4 run5 run6 run7 run8 run9 run10 
//12 unless 14
void()	zombie_run1		=[	$run1,		zombie_run2	] 	{Zombie_Walk(15);/*if(freeze_time < time)*/ self.frame = 92;SetZombieHitBox(RUN_BBOX);Zombie_Think();zombie_footstep();};//footstep
void()	zombie_run2		=[	$run2,		zombie_run3	] 	{Zombie_Walk(15);self.frame = 93;Zombie_Think();};
void()	zombie_run3		=[	$run3,		zombie_run4	] 	{Zombie_Walk(15); self.frame = 94;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_run4		=[	$run4,		zombie_run5	] 	{Zombie_Walk(15); self.frame = 95;Zombie_Think();};
void()	zombie_run5		=[	$run5,		zombie_run6	] 	{Zombie_Walk(15); self.frame = 96;Zombie_Think();};
void()	zombie_run6		=[	$run6,		zombie_run7	] 	{Zombie_Walk(15); self.frame = 97;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_run7		=[	$run7,		zombie_run8	] 	{Zombie_Walk(15); self.frame = 98;Zombie_Think();};
void()	zombie_run8		=[	$run8,		zombie_run9	] 	{Zombie_Walk(15); self.frame = 99;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_run9		=[	$run9,		zombie_run10	] 	{Zombie_Walk(15); self.frame = 100;Zombie_Think();};
void()	zombie_run10		=[	$run10,	Zombie_Walk_Setup	] 	{Zombie_Walk(15); self.frame = 101;Zombie_Think();};

void() Zombie_Walk_Setup = 
{
	if(Remaining_Zombies == 1 && rounds >= 4)
	{
		self.walktype = 5;
	}
	
	if(self.walktype == 1)
	{
		zombie_walk1();
	}
	
	else if(self.walktype == 2)
	{
		zombie_walkb1();
	}
	
	else if(self.walktype == 3)
	{
		zombie_walkc1();
	}
	
	else if(self.walktype == 4)
	{
		zombie_jog1();
	}
	else if(self.walktype == 5)
	{
		zombie_run1();
	}
};
///////////////////////////////////////////////////////////////////// ZOMBIE IDLE 1
//0-12
$frame idle1 idle2 idle3 idle4 idle5 idle6 idle7 idle8 idle9 idle10 idle11 idle12 idle13 idle14
void() zombie_idle		=[	$idle1, 		zombie_idle1	]		{Zombie_Walk(0);self.frame = 0;SetZombieHitBox(IDLE_BBOX);Zombie_Think();};
void() zombie_idle1		=[	$idle2, 		zombie_idle2	]		{Zombie_Walk(0);self.frame = 1;Zombie_Think();};
void() zombie_idle2		=[	$idle3, 		zombie_idle3	]		{Zombie_Walk(0);self.frame = 2;Zombie_Think();};
void() zombie_idle3		=[	$idle4, 		zombie_idle4	]		{Zombie_Walk(0);self.frame = 3;Zombie_Think();};
void() zombie_idle4		=[	$idle5, 		zombie_idle5	]		{Zombie_Walk(0);self.frame = 4;Zombie_Think();};
void() zombie_idle5		=[	$idle6, 		zombie_idle6	]		{Zombie_Walk(0);self.frame = 5;Zombie_Think();};
void() zombie_idle6		=[	$idle7, 		zombie_idle7	]		{Zombie_Walk(0);self.frame = 6;Zombie_Think();};
void() zombie_idle7		=[	$idle8, 		zombie_idle8	]		{Zombie_Walk(0);self.frame = 7;Zombie_Think();};
void() zombie_idle8		=[	$idle9, 		zombie_idle9	]		{Zombie_Walk(0);self.frame = 8;Zombie_Think();};
void() zombie_idle9		=[	$idle10, 		zombie_idle10	]		{Zombie_Walk(0);self.frame = 9;Zombie_Think();};
void() zombie_idle10		=[	$idle12, 		zombie_idle11	]		{Zombie_Walk(0);self.frame = 10;Zombie_Think();};
void() zombie_idle11		=[	$idle13, 		zombie_idle12	]		{Zombie_Walk(0);self.frame = 11;Zombie_Think();};
void() zombie_idle12		=[	$idle14, 		zombie_idle1	]		{Zombie_Walk(0);self.frame = 12;Zombie_Think();};

void() zombie_decide = 
{
	if(self.outside == TRUE)
	{
		self.th_idle();
	}
	else
	{
		self.th_walk();
	}
};
/////////////////////////////////////////////////////////

void() Window_Damage;
void() Window_Damage_Setup =
{
	local entity old_self;
	old_self = self;
	self = self.goalentity;
	Window_Damage();
	self = old_self;
};
void() zombie_attack2 =
{
	if(self.outside == TRUE)
	{
		if(self.goalentity.classname == "window")
		{
			if(self.enemy.classname != "window")
			{
				self.enemy = self.goalentity;
			}
		}
	}
	
	if(self.goalentity.classname == "window")
	{
		Window_Damage_Setup();
	}
	else if (self.enemy.classname == "player")
	{
		if(vlen(self.enemy.origin - self.origin) < 60)
		{
			if (self.classname == "ai_dog")
				DamageHandler (self.enemy, self, 40, S_ZOMBIE);
			else
				DamageHandler (self.enemy, self, 50, S_ZOMBIE);
		}
	}
	else return;
};

//////////////////////////////WINDOW HOPPING
//113-122
void(float pushaway) moveforwardalittle =
{
	makevectors(self.angles);
	local float amount;
	amount = 4.35;//was 8.7, but running twice as much so...
	if(self.crawling == TRUE)
		amount = 2.33;
	
	self.origin = self.origin + (v_forward * amount);
	setorigin(self, self.origin);
	self.zoom = 1;
	
	if(pushaway == 1)
	{
		local entity ent;
		ent = findradius(self.origin,50);
		while(ent)
		{
			if(ent.classname == "player" && !ent.downed)
			{
				ent.velocity = ent.velocity + (v_forward * 250);
			}
			ent = ent.chain;
		}
	}
};

$frame hop1 hop2 hop3 hop4 hop5 hop6 hop7 hop8 hop9 hop10
void() zombie_hop1	=[	$hop1,	zombie_hop1_5	] {self.movetype = self.head.movetype = MOVETYPE_STEP;self.frame = self.head.frame = 113;self.nextthink = time + 0.05;moveforwardalittle(1); self.state = 1;Zombie_Think();};
void() zombie_hop1_5	=[	$hop1,	zombie_hop2	] {self.frame = self.head.frame = 113;self.nextthink = time + 0.05;moveforwardalittle(0); };
void() zombie_hop2	=[	$hop2,	zombie_hop2_5	] {self.frame = self.head.frame = 114;self.nextthink = time + 0.05;moveforwardalittle(1);Zombie_Think();};	
void() zombie_hop2_5	=[	$hop2,	zombie_hop3	] {self.frame = self.head.frame = 114;self.nextthink = time+0.05;moveforwardalittle(0);};	
void() zombie_hop3	=[	$hop3,	zombie_hop3_5	] {self.frame = self.head.frame = 115;self.nextthink = time+0.05;moveforwardalittle(1);Zombie_Think();};
void() zombie_hop3_5	=[	$hop3,	zombie_hop4	] {self.frame = self.head.frame = 115;self.nextthink = time+0.05;moveforwardalittle(0);};
void() zombie_hop4	=[	$hop4,	zombie_hop4_5	] {self.frame = self.head.frame = 116;self.nextthink = time+0.05;moveforwardalittle(1);Zombie_Think();};
void() zombie_hop4_5	=[	$hop4,	zombie_hop5	] {self.frame = self.head.frame = 116;self.nextthink = time+0.05;moveforwardalittle(0);};
void() zombie_hop5	=[	$hop5,	zombie_hop5_5	] {self.frame = self.head.frame = 117;self.nextthink = time+0.05;moveforwardalittle(1);Zombie_Think();};
void() zombie_hop5_5	=[	$hop5,	zombie_hop6	] {self.frame = self.head.frame = 117;self.nextthink = time+0.05;moveforwardalittle(0);};
void() zombie_hop6	=[	$hop6,	zombie_hop6_5	] {self.frame = self.head.frame = 118;self.nextthink = time+0.05;moveforwardalittle(1);Zombie_Think();};
void() zombie_hop6_5	=[	$hop6,	zombie_hop7	] {self.frame = self.head.frame = 118;self.nextthink = time+0.05;moveforwardalittle(0);};
void() zombie_hop7	=[	$hop7,	zombie_hop7_5	] {self.frame = self.head.frame = 119;self.nextthink = time+0.05;moveforwardalittle(1);Zombie_Think();};
void() zombie_hop7_5	=[	$hop7,	zombie_hop8	] {self.frame = self.head.frame = 119;self.nextthink = time+0.05;moveforwardalittle(0);};
void() zombie_hop8	=[	$hop8,	zombie_hop8_5	] {self.frame = self.head.frame = 120;self.nextthink = time+0.05;moveforwardalittle(1);Zombie_Think();zombie_footstep();};
void() zombie_hop8_5	=[	$hop8,	zombie_hop9	] {self.frame = self.head.frame = 120;self.nextthink = time+0.05;moveforwardalittle(0);};
void() zombie_hop9	=[	$hop9,	zombie_hop9_5	] {self.frame = self.head.frame = 121;self.nextthink = time+0.05;moveforwardalittle(1);Zombie_Think();};
void() zombie_hop9_5	=[	$hop9,	zombie_hop10	] {self.frame = self.head.frame = 121;self.nextthink = time+0.05;moveforwardalittle(0);};
void() zombie_hop10	=[	$hop10,	zombie_hop10_5	] {self.frame = self.head.frame = 122;self.nextthink = time+0.05;moveforwardalittle(1);Zombie_Think();};
void() zombie_hop10_5=[	$hop10,	SUB_Null		] {self.frame = self.head.frame = 122;	
															self.oldorigin = self.origin = self.goalentity.hop_spot;
															setorigin(self, self.origin); 
															self.state = 0;
															self.hop_step = 6;
															if(self.crawling == 2) 
															{
																makeCrawler(self); 
																return;
															}
															self.movetype = MOVETYPE_WALK;
															self.th_walk();
														};

//ripboard1
//181-191
$frame zrip1 zrip2 zrip3 zrip4 zrip5 zrip6 zrip7 zrip8 zrip9 zrip10 zrip11
void() zombie_ripboardA1			=[	$zrip1,		zombie_ripboardA2		]	{self.frame = 181;SetZombieHitBox(IDLE_BBOX);Zombie_Think();};
void() zombie_ripboardA2			=[	$zrip2,		zombie_ripboardA3		]	{self.frame = 182;Zombie_Think();};
void() zombie_ripboardA3			=[	$zrip3,		zombie_ripboardA4		]	{self.frame = 183;Zombie_Think();};
void() zombie_ripboardA4			=[	$zrip4,		zombie_ripboardA5		]	{self.frame = 184;Zombie_Think();};
void() zombie_ripboardA5			=[	$zrip5,		zombie_ripboardA6		]	{self.frame = 185;Zombie_Think();};
void() zombie_ripboardA6			=[	$zrip6,		zombie_ripboardA7		]	{self.frame = 186;Zombie_Think();};
void() zombie_ripboardA7			=[	$zrip7,		zombie_ripboardA8		]	{self.frame = 187;zombie_attack2();Zombie_Think();};
void() zombie_ripboardA8			=[	$zrip8,		zombie_ripboardA9		]	{self.frame = 188;Zombie_Think();};
void() zombie_ripboardA9			=[	$zrip9,		zombie_ripboardA10		]	{self.frame = 189;Zombie_Think();};
void() zombie_ripboardA10			=[	$zrip10,		zombie_ripboardA11		]	{self.frame = 190;Zombie_Think();};
void() zombie_ripboardA11			=[	$zrip11,		zombie_decide		]	{self.frame = 191;Zombie_Think();};
/////////////////////////////////////////////////////////
//ripboard2
//192-201
$frame zripB1 zripB2 zripB3 zripB4 zripB5 zripB6 zripB7 zripB8 zripB9 zripB10 zripB11
void() zombie_ripboardB1			=[	$zripB1,		zombie_ripboardB2		]	{self.frame = 192;SetZombieHitBox(IDLE_BBOX);Zombie_Think();};
void() zombie_ripboardB2			=[	$zripB2,		zombie_ripboardB3		]	{self.frame = 193;Zombie_Think();};
void() zombie_ripboardB3			=[	$zripB3,		zombie_ripboardB4		]	{self.frame = 194;Zombie_Think();};
void() zombie_ripboardB4			=[	$zripB4,		zombie_ripboardB5		]	{self.frame = 195;Zombie_Think();};
void() zombie_ripboardB5			=[	$zripB5,		zombie_ripboardB6		]	{self.frame = 196;Zombie_Think();};
void() zombie_ripboardB6			=[	$zripB6,		zombie_ripboardB7		]	{self.frame = 197;zombie_attack2();Zombie_Think();};
void() zombie_ripboardB7			=[	$zripB7,		zombie_ripboardB8		]	{self.frame = 198;Zombie_Think();};
void() zombie_ripboardB8			=[	$zripB8,		zombie_ripboardB9		]	{self.frame = 199;Zombie_Think();};
void() zombie_ripboardB9			=[	$zripB9,		zombie_ripboardB10		]	{self.frame = 200;Zombie_Think();};
void() zombie_ripboardB10			=[	$zripB10,		zombie_decide		]	{self.frame = 201;Zombie_Think();};
/////////////////////////////////////////////////////////
//attack through window
//180-181
//181-185
//186-188
void() zombie_attack_through_window =
{
	play_sound_z(1);
	local entity who;
	who = findradius(self.origin,70);
	while(who)
	{
		if(who.classname == "player")
		{
			DamageHandler (who, self, 50, S_ZOMBIE);
		}
		who = who.chain;
	}
};
//202-210
$frame zatkw1 zatkw2 zatkw3 zatkw4 zatkw5 zatkw6 zatkw7 zatkw8 zatkw9
void() zombie_attack_through_w1		=[	$zatkw1,		zombie_attack_through_w2		]	{self.frame = 202;SetZombieHitBox(IDLE_BBOX);Zombie_Think();};//START

void() zombie_attack_through_w2		=[	$zatkw2,		zombie_attack_through_w3		]	{self.frame = 203;zombie_attack_through_window();Zombie_Think();};//SWINGING
void() zombie_attack_through_w3		=[	$zatkw3,		zombie_attack_through_w4		]	{self.frame = 204;Zombie_Think();};//SWINGING
void() zombie_attack_through_w4		=[	$zatkw4,		zombie_attack_through_w5		]	{self.frame = 205;Zombie_Think();};//SWINGING
void() zombie_attack_through_w5		=[	$zatkw5,		zombie_attack_through_w6		]	{self.frame = 206;Zombie_Think();};//SWINGING
void() zombie_attack_through_w6		=[	$zatkw6,		zombie_attack_through_w7		]	{self.frame = 207;Zombie_Think();};//SWINGING

void() zombie_attack_through_w7		=[	$zatkw2,		zombie_attack_through_w8		]	{self.frame = 203;Zombie_Think();};//SWINGING
void() zombie_attack_through_w8		=[	$zatkw3,		zombie_attack_through_w9		]	{self.frame = 204;Zombie_Think();};//SWINGING
void() zombie_attack_through_w9		=[	$zatkw4,		zombie_attack_through_w10		]	{self.frame = 205;Zombie_Think();};//SWINGING
void() zombie_attack_through_w10		=[	$zatkw5,		zombie_attack_through_w11		]	{self.frame = 206;Zombie_Think();};//SWINGING
void() zombie_attack_through_w11		=[	$zatkw6,		zombie_attack_through_w12		]	{self.frame = 207;Zombie_Think();};//SWINGING

void() zombie_attack_through_w12		=[	$zatkw2,		zombie_attack_through_w13		]	{self.frame = 203;Zombie_Think();};//SWINGING
void() zombie_attack_through_w13		=[	$zatkw3,		zombie_attack_through_w14		]	{self.frame = 204;Zombie_Think();};//SWINGING
void() zombie_attack_through_w14		=[	$zatkw4,		zombie_attack_through_w15		]	{self.frame = 205;Zombie_Think();};//SWINGING
void() zombie_attack_through_w15		=[	$zatkw5,		zombie_attack_through_w16		]	{self.frame = 206;zombie_attack_through_window();Zombie_Think();};//SWINGING
void() zombie_attack_through_w16		=[	$zatkw6,		zombie_attack_through_w17		]	{self.frame = 207;Zombie_Think();};//SWINGING

void() zombie_attack_through_w17		=[	$zatkw7,		zombie_attack_through_w18		]	{self.frame = 208;Zombie_Think();};//ENDING
void() zombie_attack_through_w18		=[	$zatkw8,		zombie_attack_through_w19		]	{self.frame = 209;Zombie_Think();};//ENDING
void() zombie_attack_through_w19		=[	$zatkw9,		zombie_decide		]	{self.frame = 210;Zombie_Think();};//ENDING


//////////////////////////////////////////////////////////////////////ZOMBIE DELAY ATTACKS
//zda = zombie delay attack
void() zombie_attackA1;
void() zombie_attackB1;

void(float which)	zombie_attack_choose =
{
	
	self.angles_y = vectoyaw(self.enemy.origin - self.origin);
	
	if(which != 1)
	{
		if(random() > 0.2)
		{
			return;
		}
	}
	
	play_sound_z(1);
	//Don't attack with an arm you don't have, silly
	if(!self.larm.deadflag)
	{
		zombie_attackA1();
		return;
	}
	if(!self.rarm.deadflag)
	{
		zombie_attackB1();
		return;
	}
	
	
	if(random() < 0.5)
		zombie_attackA1();
	else
		zombie_attackB1();
};

$frame zda1 zda2 zda3 zda4 zda5 zda6 zda7 zda8 zda9 zda10 zda11 zda12 zda13 zda14
void() zombie_zda		=[	$zda1, 		zombie_zda1	]		{self.frame = 0;zombie_attack_choose(0);SetZombieHitBox(IDLE_BBOX);Zombie_Think();};
void() zombie_zda1		=[	$zda2, 		zombie_zda2	]		{self.frame = 1;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda2		=[	$zda3, 		zombie_zda3	]		{self.frame = 2;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda3		=[	$zda4, 		zombie_zda4	]		{self.frame = 3;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda4		=[	$zda5, 		zombie_zda5	]		{self.frame = 4;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda5		=[	$zda6, 		zombie_zda6	]		{self.frame = 5;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda6		=[	$zda7, 		zombie_zda7	]		{self.frame = 6;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda7		=[	$zda8, 		zombie_zda8	]		{self.frame = 7;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda8		=[	$zda9, 		zombie_zda9	]		{self.frame = 8;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda9		=[	$zda10, 		zombie_zda10	]		{self.frame = 9;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda10		=[	$zda12, 		zombie_zda11	]		{self.frame = 10;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda11		=[	$zda13, 		zombie_zda12	]		{self.frame = 11;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda12		=[	$zda14, 		zombie_zda1	]		{self.frame = 12;zombie_attack_choose(1);Zombie_Think();};
///////////////////////////////////////////////////////////////////// ZOMBIE ATTACK 1// Swipe with right arm
//86 - 90
void() zombie_attack2;

$frame attack1 attack2 attack3 attack4 attack5

void() zombie_attackA1		=[	$attack1,		zombie_attackA2	]	{self.frame = 102;SetZombieHitBox(BASE_BBOX);Zombie_Think();self.solid = SOLID_BBOX;};
void() zombie_attackA2		=[	$attack2,		zombie_attackA3	]	{self.frame = 103;Zombie_Think();};
void() zombie_attackA3		=[	$attack3,		zombie_attackA4	]	{self.frame = 104;Zombie_Think();};
void() zombie_attackA4		=[	$attack4,		zombie_attackA5	]	{zombie_attack2();self.frame = 105;Zombie_Think();};
void() zombie_attackA5		=[	$attack5,		zombie_decide	]	{self.frame = 106;Zombie_Think();self.solid = SOLID_CORPSE;};

///////////////////////////////////////////////////////////////////////// ZOMBIE ATTACK 2// Swipe with left arm
//91-96
$frame attackb1 attackb2 attackb3 attackb4 attackb5 attackb6

void() zombie_attackB1		=[	$attackb1,		zombie_attackB2	]	{self.frame = 107;SetZombieHitBox(BASE_BBOX);Zombie_Think();self.solid = SOLID_BBOX;};
void() zombie_attackB2		=[	$attackb2,		zombie_attackB3	]	{self.frame = 108;Zombie_Think();};
void() zombie_attackB3		=[	$attackb3,		zombie_attackB4	]	{self.frame = 109;Zombie_Think();};
void() zombie_attackB4		=[	$attackb4,		zombie_attackB5	]	{zombie_attack2(); self.frame = 110;Zombie_Think();};
void() zombie_attackB5		=[	$attackb5,		zombie_attackB6	]	{self.frame = 111;Zombie_Think();};
void() zombie_attackB6		=[	$attackb6,		zombie_decide	]	{self.frame = 112;Zombie_Think();self.solid = SOLID_CORPSE;};


void() zombie_attack =
{
	self.velocity = '0 0 0';

	if (self.classname == "wunder")
		return;

	if(self.outside == TRUE)
	{
		self.angles_y = self.goalentity.angles_y;
	}
	else
	{
		self.angles_y = vectoyaw(self.enemy.origin - self.origin);
	}
		
	
	if(self.crawling == TRUE)
	{
		if(self.outside == TRUE)
			crawler_rip_board1();
		else
			crawler_da1();//crawler delay attack
	}
	else
	{
		//zombie_attack_through_w1();
		
		if(self.outside == TRUE)
		{
			if(random() < 0.30)
			{
				local entity who;
				local float found;
				found = 0;
				who = findradius(self.origin,70);
				while(who && found == 0 )
				{
					if(who.classname == "player")
					{
						found = 1;
					}
					else
						who = who.chain;
				}
				if(found == 1)
				{
					zombie_attack_through_w1();
					return;
				}
			}
			
			if(random() < 0.5)
				zombie_ripboardA1();
			else
				zombie_ripboardB1();
		}
		else
		{
			zombie_zda();//Zombie Delay Attack
		}
	}
	
};

//==========================Falling Code==========================
void CheckLand() =
{
	if ((self.flags & FL_ONGROUND))
	{
		if (self.fall == TRUE)
		{
			self.fall = FALSE;
			self.th_land();
		}
	}
};

//Falling
//149-152
$frame fall1 fall2 fall3 fall4

void() zombie_fall1		=[	$fall1,		zombie_fall2	]	{self.frame = 149;SetZombieHitBox(BASE_BBOX);self.fall = TRUE;CheckLand();Zombie_Think();};
void() zombie_fall2		=[	$fall2,		zombie_fall3	]	{self.frame = 150;CheckLand();Zombie_Think();};
void() zombie_fall3		=[	$fall3,		zombie_fall4	]	{self.frame = 151;CheckLand();Zombie_Think();};
void() zombie_fall4		=[	$fall4,		zombie_fall3	]	{self.frame = 152;CheckLand();Zombie_Think();};

//Landing
//153-159
$frame land1 land2 land3 land4 land5 land6 land7
void() zombie_land1		=[	$land1,		zombie_land2	]	{self.frame = 153;SetZombieHitBox(BASE_BBOX);Zombie_Think();zombie_footstep();zombie_footstep();};
void() zombie_land2		=[	$land2,		zombie_land3	]	{self.frame = 154;Zombie_Think();};
void() zombie_land3		=[	$land3,		zombie_land4	]	{self.frame = 155;Zombie_Think();};
void() zombie_land4		=[	$land4,		zombie_land5	]	{self.frame = 156;Zombie_Think();};
void() zombie_land5		=[	$land5,		zombie_land6	]	{self.frame = 157;Zombie_Think();};
void() zombie_land6		=[	$land6,		zombie_land7	]	{self.frame = 158;Zombie_Think();};
void() zombie_land7		=[	$land7,		Zombie_Walk_Setup	]	{self.frame = 159;Zombie_Think();};

void() removeZombie =
{
	self.classname = "freeZombieEntity";
	self.aistatus = "0";
	setmodel(self,"");
	
	setmodel(self.larm,"");
	setmodel(self.rarm,"");
	setmodel(self.head,"");
	
	#ifndef PC
	updateLimb (self, 0, world);
	updateLimb (self, 1, world);
	updateLimb (self, 2, world);
	#endif
	
	setorigin(self,'0 0 0');
	setorigin (self.goaldummy, '0 0 0');
	
	self.think = SUB_Null;
	
	self.goalentity = world;
	self.enemy = world;
	self.solid = 0;
	self.movetype = 0;

	self.outside = TRUE;
	self.hop_step = 0;
	self.calc_time = 0;
	self.tries = 0;
	self.takedamage = DAMAGE_NO;
	self.flags = 0;
	self.crawling = 0;
	self.bleedingtime = 0;
	self.owner = world;

	self.spawnflags = 0;
	
	
	self.yaw_speed = 0;
	
	self.health = 0;
	self.th_die = SUB_Null;
	self.th_walk = SUB_Null;
	self.th_melee = SUB_Null;
	self.th_idle = SUB_Null;
	self.th_windowhop = SUB_Null;
	
	self.th_fall = SUB_Null;
	self.th_falling = SUB_Null;
	self.th_land = SUB_Null;
	
	self.th_jump = SUB_Null;
	self.th_grabledge = SUB_Null;
	self.th_diewunder = SUB_Null;
	//Disabling collision bboxes
	SetZombieHitBox(EMPTY_BBOX);
};

///////////////////////////////////////////////////////////////////// ZOMBIE DEATH 1
//123-133
$frame death1 death2 death3 death4 death5 death6 death7 death8 death9 death10 death11
void()	zombie_deathA1		=[	$death1,		zombie_death2	] 	{self.frame = 123;};
void()	zombie_death2		=[	$death2,		zombie_death3	] 	{self.frame = 124;};
void()	zombie_death3		=[	$death3,		zombie_death4	] 	{self.frame = 125;};
void()	zombie_death4		=[	$death4,		zombie_death5	] 	{self.frame = 126;};
void()	zombie_death5		=[	$death5,		zombie_death6	] 	{self.frame = 127;};
void()	zombie_death6		=[	$death6,		zombie_death7	] 	{self.frame = 128;};
void()	zombie_death7		=[	$death7,		zombie_death8	] 	{self.frame = 129;};
void()	zombie_death8		=[	$death8,		zombie_death9	] 	{self.frame = 130;};
void()	zombie_death9		=[	$death9,		zombie_death10	] 	{self.frame = 131;};
void()	zombie_death10		=[	$death10,		zombie_death11	] 	{self.frame = 132;zombie_footstep();};
void()	zombie_death11		=[	$death11,		SUB_Null	] 	{self.nextthink = time + 3; self.think = removeZombie;  self.frame = 133;};

//////////////////////////////////////////////////////////////////////////////////// ZOMBIE DEATH 2
//134-138
$frame deathB1 deathB2 deathB3 deathB4 deathB5

void()	zombie_deathB1		=[	$deathB1,		zombie_deathB2	] 	{self.frame = 134;};
void()	zombie_deathB2		=[	$deathB2,		zombie_deathB3	] 	{self.frame = 135;};
void()	zombie_deathB3		=[	$deathB3,		zombie_deathB4	] 	{self.frame = 136;};
void()	zombie_deathB4		=[	$deathB4,		zombie_deathB5	] 	{self.frame = 137;zombie_footstep();};
void()	zombie_deathB5		=[	$deathB5,		SUB_Null		] 	{self.nextthink = time + 3; self.think = removeZombie; self.frame = 138;};


//////////////////////////////////////////////////////////////////////////////////// ZOMBIE DEATH 3
//139-148

$frame deathC1 deathC2 deathC3 deathC4 deathC5 deathC6 deathC7 deathC8 deathC9 deathC10

void()	zombie_deathC1		=[	$deathC1,		zombie_deathC2	] 	{self.frame = 139;};
void()	zombie_deathC2		=[	$deathC2,		zombie_deathC3	] 	{self.frame = 140;};
void()	zombie_deathC3		=[	$deathC3,		zombie_deathC4	] 	{self.frame = 141;};
void()	zombie_deathC4		=[	$deathC4,		zombie_deathC5	] 	{self.frame = 142;};
void()	zombie_deathC5		=[	$deathC5,		zombie_deathC6	] 	{self.frame = 143;};
void()	zombie_deathC6		=[	$deathC6,		zombie_deathC7	] 	{self.frame = 144;};
void()	zombie_deathC7		=[	$deathC7,		zombie_deathC8	] 	{self.frame = 145;};
void()	zombie_deathC8		=[	$deathC8,		zombie_deathC9	] 	{self.frame = 146;zombie_footstep();};
void()	zombie_deathC9		=[	$deathC9,		zombie_deathC10	] 	{self.frame = 147;};
void()	zombie_deathC10		=[	$deathC10,		SUB_Null		] 	{self.nextthink = time + 3; self.think = removeZombie; self.frame = 148;};

void() Zombie_Death =
{
	self.aistatus = "0";
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.takedamage = DAMAGE_NO;
	
	self.head.solid = SOLID_NOT;
	self.head.movetype = MOVETYPE_NONE;
	self.head.takedamage = DAMAGE_NO;
	self.larm.solid = SOLID_NOT;
	self.larm.movetype = MOVETYPE_NONE;
	self.larm.takedamage = DAMAGE_NO;
	self.rarm.solid = SOLID_NOT;
	self.rarm.movetype = MOVETYPE_NONE;
	self.rarm.takedamage = DAMAGE_NO;
	sound(self,CHAN_VOICE,"sounds/null.wav",1,ATTN_NORM);
	
	self.usedent = world;
	
	if(self.goalentity.classname == "window")
	{
		if(self.goalentity.box1owner == self)
			self.goalentity.box1owner = world;
		if(self.goalentity.box2owner == self)
			self.goalentity.box2owner = world;
		if(self.goalentity.box3owner == self)
			self.goalentity.box3owner = world;
		if(self.goalentity.usedent == self)
			self.goalentity.usedent = world;
	}
	
	
	self.health = 0;
	Remaining_Zombies = Remaining_Zombies - 1;
	
	play_sound_z(3);
	//Gotta' make sure we set it back down instead of glitching it up, yo'
	if(self.s_time > 0 && sounds_playing > 0)
	{
		sounds_playing --;
		self.s_time = 0;
	}
	
	//Spawn_Powerup(self.origin, 0);
	if(self.outside == FALSE)
	{
		if (totalpowerups < 4)
		{
			if (total_powerup_points >= powerup_activate)
			{
				Spawn_Powerup(self.origin, 0);
				total_powerup_points = total_powerup_points - powerup_activate;
			}
			else if (random () <= 0.02)
				Spawn_Powerup(self.origin, 0);
		}
	}
	
	if(self.crawling == TRUE)
	{
		crawler_die1();
	}
	else
	{
		if(random() < 0.3)
		{
			zombie_deathA1();
		}
		else if(random() < 0.6)
		{
			zombie_deathB1();
		}
		else 
		{
			zombie_deathC1();
		}
	}
};

/////////////////////ZOMBIE WAFFE STUFF/////////////////////

void() Zombie_Lightning_Think =
{
	self.frame++;

	if (self.frame >= 3)
		self.frame = 0;
	
	// suicide timer!
	if(self.ltime < time) {
		remove(self);
	}

	self.nextthink = time + 0.05;
}

void() Zombie_Tesla_Light =
{
	// lightning sprite
	local entity lightning = spawn();
	setmodel(lightning, "models/misc/lightning.spr");
	setorigin(lightning, self.origin + '0 0 13');
	lightning.think = Zombie_Lightning_Think;
	lightning.nextthink = time + 0.05;
	lightning.ltime = time + 1;
}

void() Zombie_Find_Tesla_Target =
{
	local entity zombs = findradius(self.origin, 200);
	local entity tempe;
	local vector org;
	local vector targetorg;
	local float found_target;

	if (self.teslacount >= 10)
		return;

	found_target = false;
	while(zombs != world || found_target) {
		if (zombs == world) {
			found_target = true;
			return;
		}
		// limb stuff
		if (zombs.classname == "ai_zombie_head" || zombs.classname == "ai_zombie_larm"
		|| zombs.classname == "ai_zombie_rarm") {
			zombs = zombs.owner;
		}

		if (zombs.classname == "ai_zombie" || zombs.classname == "ai_dog") {
			found_target = true;

			zombs.owner = self.owner;

			// remove libs
			if (zombs.head)
				setmodel(zombs.head, "");
			if (zombs.larm)
				setmodel(zombs.larm, "");
			if (zombs.rarm)
				setmodel(zombs.rarm, "");

			// add 50pts
			addmoney(self.owner, 50, true);

			// kill
			self.owner.kills += 1;

			// add to tesla count
			zombs.teslacount = self.teslacount + 1;

			// classname change
			zombs.classname = "wunder";

			org = self.origin + '0 0 13';
			targetorg = zombs.origin + '0 0 13';

			// shoot lightning
			#ifdef PC
			te_lightning2(self, org, targetorg);
			#endif
			#ifdef PSP
			WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
			WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
			WriteEntity (MSG_BROADCAST, self);
			WriteCoord (MSG_BROADCAST, org_x);
			WriteCoord (MSG_BROADCAST, org_y);
			WriteCoord (MSG_BROADCAST, org_z);
			WriteCoord (MSG_BROADCAST, targetorg_x);
			WriteCoord (MSG_BROADCAST, targetorg_y);
			WriteCoord (MSG_BROADCAST, targetorg_z);
			#endif

			// anim play
			tempe = self;
			self = zombs;
			self.th_diewunder();
			self = tempe;
		}
		zombs = zombs.chain;
	}
}

// Wunder'd
// 149-152 (FIXME - animate wunder'd zombies)
$frame wunder1 wunder2 wunder3 wunder4 wunder5 wunder6 wunder7 wunder8 wunder9 wunder10

void() zombie_wunder1		=[	$wunder1,		zombie_wunder2	]	{play_sound_z(4);Zombie_Tesla_Light();Zombie_Walk(0);self.frame = 149;self.solid = SOLID_NOT;};
void() zombie_wunder2		=[	$wunder2,		zombie_wunder3	]	{Zombie_Walk(0);self.frame = 150;};
void() zombie_wunder3		=[	$wunder3,		zombie_wunder4	]	{Zombie_Walk(0);Zombie_Find_Tesla_Target();self.frame = 151;};
void() zombie_wunder4		=[	$wunder4,		zombie_wunder5	]	{Zombie_Walk(0);self.frame = 152;};
void() zombie_wunder5		=[	$wunder5,		zombie_wunder6	]	{Zombie_Walk(0);self.frame = 151;};
void() zombie_wunder6		=[	$wunder6,		zombie_wunder7	]	{Zombie_Walk(0);self.frame = 152;};
void() zombie_wunder7		=[	$wunder7,		zombie_wunder8	]	{Zombie_Walk(0);self.frame = 151;};
void() zombie_wunder8		=[	$wunder8,		zombie_wunder9	]	{play_sound_z(3);Zombie_Walk(0);self.frame = 152;};
void() zombie_wunder9		=[	$wunder9,		zombie_wunder10	]	{Zombie_Walk(0);self.frame = 151;};
void() zombie_wunder10		=[	$wunder10,		SUB_Null 		]	{self.health = 0; self.th_die();Zombie_Walk(0);self.frame = 152;};

/////////////////////ZOMBIE SPAWNING/////////////////////
void() zombieRise =
{
	//better not move wile rising, would happen sometimes
	self.velocity_x = 0;
	self.velocity_y = 0;
	
	if(self.frame < 13)//begin
	{
		self.frame = 12;//since we're going to add one anyways
		self.state = 1;//don't make crawler, yo!
	}
	if(self.frame == 36)
	{
		self.state = 0;
		if(self.crawling == 2)
		{
			makeCrawler(self);
			return;
		}
		self.th_walk();
		return;
	}
	self.frame ++;
	self.think = zombieRise;
	self.nextthink = time + 0.1;
};
void() spawn_zombie =
{
	setsize(self, '0 0 0', '0 0 0');
	if (self.spawnflags & INACTIVE)
	{
		if (cvar("developer"))
			setmodel(self, "models/player.mdl");
		self.classname = "spawn_zombie_in";
	}
	else
	{
		if (cvar("developer"))
			setmodel(self, "models/ai/zfull.mdl");
		self.classname = "spawn_zombie";
	}
	
	//self.think = zombie_spawn_think;
	//self.nextthink = time + 0.5;
	
	self.solid = SOLID_NOT;
};

void(entity where) spawn_a_zombieB;
void() set_z_health =
{
	if(rounds <= 10)
	{
		z_health = 50 + (rounds * 100);
	}
	else
	{	
		local float i;
		i = rounds - 10;
		z_health = 1050;
		while(i > 0)
		{
			z_health *= 1.1; 
			i--;
		}
	}
};

entity(entity me) getFreeZombieEnt =
{
	local entity who;
	who = find(world,classname,"freeZombieEntity");
	
	return who;
};
float() spawn_a_zombieA =
{
	//dprint("Spawn_a_zombieA \n");
	local float pcount;
	local entity thing, szombie;
	local float FAIL;

	//warn
	pcount = 0;
	
	FAIL = false;
	szombie = getFreeZombieEnt(self);
	if(szombie == world || zombie_spawn_timer > time)
	{
		//bprint(PRINT_HIGH, "STOPPED AT A\n");
		//dprint("No avaible zombie entity\n");
		return 0;
	}
	szombie.onfire = false;
	lastspawn = find(lastspawn, classname, "spawn_zombie");
	while (random() < 0.4)
	{
		lastspawn = find(lastspawn, classname, "spawn_zombie");
	}
	
	while(lastspawn)
	{
		thing = findradius(lastspawn.origin, 60);
		while (thing)
		{
			pcount = 0;
			if (thing.classname == "ai_zombie")
			{
				pcount = 1;
				break;
			}
			thing = thing.chain;
		}
		if (!pcount && random() < 0.6)
		{
			spawn_a_zombieB(lastspawn);
			spawn_delay = time + delay_at_round;
			return true;
		}
		lastspawn = find(lastspawn, classname, "spawn_zombie");
	}
	return 0; //no free locations fround
};

void(float i) spawnSingleZombEnt =
{
	local entity zSpawn;
	zSpawn = spawn();
	zSpawn.classname = "freeZombieEntity";
	zSpawn.aistatus = "0";
	zSpawn.goaldummy = spawn();
	zSpawn.goaldummy.classname = "waypoint_target";
	
	zSpawn.head = spawn();
	zSpawn.head.classname = "in_ai_zombie_head";
	zSpawn.head.owner = zSpawn;
	zSpawn.head.solid = SOLID_NOT;
	zSpawn.head.movetype = MOVETYPE_STEP;
	zSpawn.head.takedamage = DAMAGE_NO;
	#ifndef PC
	updateLimb (zSpawn, 0, zSpawn.head);
	#endif
	
	zSpawn.larm = spawn();
	zSpawn.larm.classname = "in_ai_zombie_larm";
	zSpawn.larm.owner = zSpawn;
	zSpawn.larm.solid = SOLID_NOT;
	zSpawn.larm.movetype = MOVETYPE_STEP;
	zSpawn.larm.takedamage = DAMAGE_NO;
	#ifndef PC
	updateLimb (zSpawn, 1, zSpawn.larm);
	#endif
	
	zSpawn.rarm = spawn();
	zSpawn.rarm.classname = "in_ai_zombie_rarm";
	zSpawn.rarm.owner = zSpawn;
	zSpawn.rarm.solid = SOLID_NOT;
	zSpawn.rarm.movetype = MOVETYPE_STEP;
	zSpawn.rarm.takedamage = DAMAGE_NO;
	#ifndef PC
	updateLimb (zSpawn, 2, zSpawn.rarm);
	#endif
};
void(entity szombie)  SetUpHitBoxes =
{
	szombie.head.solid = SOLID_CORPSE;
	szombie.head.movetype = MOVETYPE_STEP;
	szombie.head.classname = "ai_zombie_head";
	szombie.head.takedamage = DAMAGE_YES;

	szombie.larm.solid = SOLID_CORPSE;
	szombie.larm.movetype = MOVETYPE_STEP;
	szombie.larm.classname = "ai_zombie_larm";
	szombie.larm.takedamage = DAMAGE_YES;

	szombie.rarm.solid = SOLID_CORPSE;
	szombie.rarm.movetype = MOVETYPE_STEP;
	szombie.rarm.classname = "ai_zombie_rarm";
	szombie.rarm.takedamage = DAMAGE_YES;
	
	local entity oldself = self;
	self = szombie;
	SetZombieHitBox(BASE_BBOX);
	self = oldself;
};

void(entity szombie) SetZombieWalk =
{	
	local float walk1Percent,walk2Percent,walk3Percent,jogPercent;
	
	walk1Percent = walk2Percent = walk3Percent = ((rounds < 3) ? 1 : 0);//1/x denotes walk types
	walk1Percent += ((rounds >= 3 && rounds <= 7) ? (((-0.5 * rounds)/3) + 1.2) : 0);
	walk2Percent = walk3Percent = walk1Percent;
	
	jogPercent = walk1Percent +	((rounds >= 3 && rounds < 6) ? (((0.5*rounds)/3) - 0.2) : 0);
	jogPercent += ((rounds >= 6 && rounds <= 10) ? (0.6 + ((rounds - 7) / (-5))) : 0);
	
	//Dividing up the walks
	walk1Percent *= 0.33;
	walk2Percent *= 0.67;
	//walk3Percent *= 1; just disabled becuase it doesn't do anything, but I wrote it to show how we're handling it

	local float whichwalk;
	whichwalk = random();

	if(whichwalk <= walk1Percent)
	{
		szombie.walktype = 1;
	}
	else if(whichwalk <= walk2Percent)
	{
		szombie.walktype = 2;
	}
	else if(whichwalk <= walk3Percent)
	{
		szombie.walktype =3;
	}
	else if(whichwalk <= jogPercent)
	{
		szombie.walktype = 4;
	}
	else szombie.walktype = 5;
};

float() getMaxZombies =
{
	if (dogWave == true) {
		return 2;
	} else {
		return MAX_ZOMB;
	}
}

void() spawnAllZombEnts =
{
	local float i;
	i = 0;

	while(i < getMaxZombies())//IMPORTANT VALUE, max zombies allowed in map
	{
		spawnSingleZombEnt(i);
		i++;
	}
};

void(entity where) spawn_a_zombieB =
{
	local entity szombie;//USED FOR WHAT TO SPAWN
	//szombie = spawn();
	
	szombie = getFreeZombieEnt(self);
	if(szombie == world || zombie_spawn_timer > time)
	{
		//bprint(PRINT_HIGH, "STOPPED AT B\n");
		//dprint("Out of zombie entities \n");
		return;
	}

	#ifdef PC
	szombie.head = spawn();
	szombie.rarm = spawn();
	szombie.larm = spawn();

	szombie.head.owner = szombie.rarm.owner = szombie.larm.owner = szombie;
	#endif

	szombie.origin = where.origin;
	
	szombie.frame = 0;
	
	szombie.target = where.target;
	//blubsvel
	//szombie.movetype = MOVETYPE_STEP;

	szombie.head.deadflag = 1;
	szombie.larm.deadflag = 1;
	szombie.rarm.deadflag = 1;

	//setmodel(szombie, "models/ai/zspr.spr");
	setmodel(szombie.head, "models/ai/zhead.mdl");
	setmodel(szombie.rarm, "models/ai/zrarm.mdl");
	setmodel(szombie.larm, "models/ai/zlarm.mdl");
	#ifndef PC
	updateLimb (szombie, 0, szombie.head);
	updateLimb (szombie, 1, szombie.larm);
	updateLimb (szombie, 2, szombie.rarm);
	#endif
	
	
	szombie.solid = szombie.head.solid = SOLID_CORPSE;
	szombie.movetype = MOVETYPE_WALK;
	setmodel(szombie, "models/ai/zbod.mdl");
	szombie.hop_step = 0;
	szombie.gravity = 1.0;
	
	szombie.mins = '-8 -8 -32';//-16 16 -32
	szombie.maxs = '8 8 30';//16 16 40
	setsize (szombie, szombie.mins, szombie.maxs);//-16,-16,-32,16,16,40
	//Setting Uniform skin=================
	/*if(random() > 0.5)
	{
		szombie.skin = 1;
		szombie.larm.skin = 1;
		szombie.rarm.skin = 1;
	}
	//Setting Skin
	if(random() < 0.5)
		szombie.head.skin = 0;
	else
		szombie.head.skin = 1;*/
	
	local float tex;
	tex = random();

	szombie.skin = 0;
		
	
	//====================================
	
	if(pointcontents(szombie.origin - '0 0 36') == -2)
	{
		while(pointcontents (szombie.origin - '0 0 36') == -2)
		{
			szombie.origin = szombie.origin + '0 0 1';
			setorigin(szombie,szombie.origin );
		}
	}

	szombie.classname = "ai_zombie";
	szombie.aistatus = "1";
	setorigin (szombie.goaldummy, '0 0 0');
	szombie.origin_z = szombie.origin_z + 1;
	szombie.outside = true;
	szombie.takedamage = DAMAGE_YES;
	setorigin(szombie, szombie.origin);
	szombie.flags = szombie.flags | FL_PARTIALGROUND | FL_MONSTER;

	szombie.spawnflags = where.spawnflags;
	//////////FIX FOR OUTSIDE
	if(szombie.spawnflags & 4)
	{
		szombie.outside = FALSE;
	}
	
	/////////
	
	szombie.ideal_yaw = szombie.angles_y;
	szombie.yaw_speed = 20;
	szombie.iszomb = 1;
	
	// We used to set different limb health, too, but we now handle any limb damage differences in weapon stats.
	szombie.health = szombie.head.health = szombie.larm.health = szombie.rarm.health = z_health;

	szombie.th_die = Zombie_Death;
	szombie.th_walk = Zombie_Walk_Setup;
	szombie.th_melee = zombie_attack;
	szombie.th_idle = zombie_idle;
	szombie.th_windowhop = zombie_hop1;
	
	szombie.th_fall = zombie_fall1;
	szombie.th_land = zombie_land1;

	szombie.th_diewunder = zombie_wunder1;
	
	//szombie.th_jump = zombie_jump1;
	//szombie.th_grabledge = zombie_grabledge1;
	

	//==================================================================================================
	SetZombieWalk(szombie);
	//==================================================================================================
	
	SetUpHitBoxes(szombie);
	//szombie.walktype = 5;
	////////////////////////////////////////////////////
	szombie.reload_delay = 30 + time;//save  floats, equals respawn time.
	local entity old_self;
	old_self = self;
	self = szombie;
	if (self.spawnflags & 2)//RISER
	{
		zombieRise();
	}
	else
		self.th_walk();
	self = old_self;

	// set up timer for next spawn
	zombie_spawn_timer = zombie_spawn_delay + time;
};

void() zombie_dummy =
{
	self.frame = 0;
	
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	
	setmodel(self, "models/ai/zfull.mdl");
	
	setsize (self, '-8 -8 -32', '8 8 30');
	setorigin(self, self.origin);
	self.classname = "ai_zombie";
	self.takedamage = DAMAGE_YES;
	self.flags = self.flags | FL_PARTIALGROUND | FL_MONSTER;
	self.health = 999999;
	SetUpHitBoxes(self);
};