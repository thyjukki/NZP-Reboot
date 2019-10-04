//========================= Crawling ===========================
void() zombie_crawl1;
void() crawlerify1;

void() Crawler_Walk_Setup
{
	zombie_crawl1();
}


void() crawler_footstep
{
	if(self.laststep == 1)
	{
		self.laststep = 0;
		sound(self,CHAN_VOICE,"sounds/zombie/sc0.wav",1,ATTN_NORM);
	}
	else
	{
		self.laststep = 1;
		sound(self,CHAN_VOICE,"sounds/zombie/sc1.wav",1,ATTN_NORM);
	}
}

//14-28
void()	zombie_crawl1		=[	0,		zombie_crawl2	] 	{Zombie_Walk(2.955);SetZombieHitBox(CRAWLER_BBOX);/*if(freeze_time < time)*/ self.frame = 14;Zombie_Think();};
void()	zombie_crawl2		=[	1,		zombie_crawl3	] 	{Zombie_Walk(3.841); self.frame = 15;Zombie_Think();};
void()	zombie_crawl3		=[	2,		zombie_crawl4	] 	{Zombie_Walk(0.886); self.frame = 16;Zombie_Think();};
void()	zombie_crawl4		=[	3,		zombie_crawl5	] 	{Zombie_Walk(1.871); self.frame = 17;Zombie_Think();};
void()	zombie_crawl5		=[	4,		zombie_crawl6	] 	{Zombie_Walk(3.25); self.frame = 18;Zombie_Think();};
void()	zombie_crawl6		=[	5,		zombie_crawl7	] 	{Zombie_Walk(1.314); self.frame = 19;Zombie_Think();};
void()	zombie_crawl7		=[	6,		zombie_crawl8	] 	{Zombie_Walk(0.908); self.frame = 20;Zombie_Think();crawler_footstep();};//footstep
void()	zombie_crawl8		=[	7,		zombie_crawl9	] 	{Zombie_Walk(0.776); self.frame = 21;Zombie_Think();};
void()	zombie_crawl9		=[	8,		zombie_crawl10	] 	{Zombie_Walk(0.698); self.frame = 22;Zombie_Think();};
void()	zombie_crawl10		=[	9,		zombie_crawl11	] 	{Zombie_Walk(0.641); self.frame = 23;Zombie_Think();};
void()	zombie_crawl11		=[	10,		zombie_crawl12	] 	{Zombie_Walk(0.588); self.frame = 24;Zombie_Think();};
void()	zombie_crawl12		=[	11,		zombie_crawl13	] 	{Zombie_Walk(0.295); self.frame = 25;Zombie_Think();};
void()	zombie_crawl13		=[	12,		zombie_crawl14	] 	{Zombie_Walk(1.182); self.frame = 26;Zombie_Think();};
void()	zombie_crawl14		=[	13,		zombie_crawl15	] 	{Zombie_Walk(0.492); self.frame = 27;Zombie_Think();};
void()	zombie_crawl15		=[	14,		Crawler_Walk_Setup	] 	{Zombie_Walk(2.856); self.frame = 28;Zombie_Think();crawler_footstep();};//footstep

//====================== Zombie To Crawler =======================
//0-4
void() crawlerify1		=[	0,		crawlerify2	] 	{SetZombieHitBox(CRAWLER_BBOX); self.frame = 0;Zombie_Think();};
void() crawlerify2		=[	1,		crawlerify3	] 	{self.frame = 1;Zombie_Think();};
void() crawlerify3		=[	2,		crawlerify4	] 	{self.frame = 2;Zombie_Think();};
void() crawlerify4		=[	3,		crawlerify5	] 	{self.frame = 3;Zombie_Think();crawler_footstep();crawler_footstep();};//hit floor
void() crawlerify5		=[	4,		Crawler_Walk_Setup	] 	{self.frame = 4;Zombie_Think();if(self.health <= 0) self.th_die();};//need to check for death since a grenade will not kill a zombie, only make him a crawler

//====================== Crawler Idle ==============================
//4-13
void() crawler_idle1		=[	0,		crawler_idle2	] 	{SetZombieHitBox(CRAWLER_BBOX);Zombie_Walk(0); self.frame = 4;Zombie_Think();};
void() crawler_idle2		=[	1,		crawler_idle3	] 	{Zombie_Walk(0); self.frame = 5;Zombie_Think();};
void() crawler_idle3		=[	2,		crawler_idle4	] 	{Zombie_Walk(0); self.frame = 6;Zombie_Think();};
void() crawler_idle4		=[	3,		crawler_idle5	] 	{Zombie_Walk(0); self.frame = 7;Zombie_Think();};
void() crawler_idle5		=[	4,		crawler_idle6	] 	{Zombie_Walk(0); self.frame = 8;Zombie_Think();};
void() crawler_idle6		=[	5,		crawler_idle7	] 	{Zombie_Walk(0); self.frame = 9;Zombie_Think();};
void() crawler_idle7		=[	6,		crawler_idle8	] 	{Zombie_Walk(0); self.frame = 10;Zombie_Think();};
void() crawler_idle8		=[	7,		crawler_idle9	] 	{Zombie_Walk(0); self.frame = 11;Zombie_Think();};
void() crawler_idle9		=[	8,		crawler_idle10	] 	{Zombie_Walk(0); self.frame = 12;Zombie_Think();};
void() crawler_idle10		=[	9,		crawler_idle1	] 	{Zombie_Walk(0); self.frame = 13;Zombie_Think();};
//===================== Crawler Attack ===========================
//29-36
void() crawler_atk1		=[	0,		crawler_atk2] 	{SetZombieHitBox(CRAWLER_BBOX);self.frame = 29;Zombie_Think();};
void() crawler_atk2		=[	1,		crawler_atk3] 	{self.frame = 30;Zombie_Think();};
void() crawler_atk3		=[	2,		crawler_atk4] 	{self.frame = 31;Zombie_Think();};
void() crawler_atk4		=[	3,		crawler_atk5] 	{self.frame = 32;zombie_attack2();Zombie_Think();};
void() crawler_atk5		=[	4,		crawler_atk6] 	{self.frame = 33;Zombie_Think();};
void() crawler_atk6		=[	5,		crawler_atk7] 	{self.frame = 34;Zombie_Think();};
void() crawler_atk7		=[	6,		crawler_atk8] 	{self.frame = 35;Zombie_Think();};
void() crawler_atk8		=[	7,		zombie_decide] 	{self.frame = 36;Zombie_Think();};

//====================== Crawler Delay Attack ==============================
//4-13

void(float which) crawler_attack_choose =
{
	self.angles_y = vectoyaw(self.enemy.origin - self.origin);
	if(which != 1)
	{
		if(random() > 0.2)
		{
			return;
		}
	}
	if(vlen(self.enemy.origin - self.origin) > 60)//too far, cancel attack
	{
		zombie_decide();
		return;
	}
	play_sound_z(1);
	
	crawler_atk1();
};


void() crawler_da1		=[	0,		crawler_da2	] 	{SetZombieHitBox(CRAWLER_BBOX);crawler_attack_choose(0); self.frame = 4;Zombie_Think();};
void() crawler_da2		=[	1,		crawler_da3	] 	{crawler_attack_choose(0); self.frame = 5;Zombie_Think();};
void() crawler_da3		=[	2,		crawler_da4	] 	{crawler_attack_choose(0); self.frame = 6;Zombie_Think();};
void() crawler_da4		=[	3,		crawler_da5	] 	{crawler_attack_choose(0); self.frame = 7;Zombie_Think();};
void() crawler_da5		=[	4,		crawler_da6	] 	{crawler_attack_choose(0); self.frame = 8;Zombie_Think();};
void() crawler_da6		=[	5,		crawler_da7	] 	{crawler_attack_choose(0); self.frame = 9;Zombie_Think();};
void() crawler_da7		=[	6,		crawler_da8	] 	{crawler_attack_choose(0); self.frame = 10;Zombie_Think();};
void() crawler_da8		=[	7,		crawler_da9	] 	{crawler_attack_choose(0); self.frame = 11;Zombie_Think();};
void() crawler_da9		=[	8,		crawler_da10	] 	{crawler_attack_choose(0); self.frame = 12;Zombie_Think();};
void() crawler_da10		=[	9,		crawler_da1	] 	{crawler_attack_choose(0); self.frame = 13;Zombie_Think();};


//====================== Crawler Death ============================
//37-39
void() crawler_die1		=[	0,		crawler_die2] 	{SetZombieHitBox(CRAWLER_BBOX);self.frame = 37;};
void() crawler_die2		=[	1,		crawler_die3] 	{self.frame = 38;};
void() crawler_die3		=[	2,		SUB_Null] 	{self.frame = 39;self.nextthink = time + 3;self.think = removeZombie; addmoney(other, 60, true); if (crawler_num > 0) {crawler_num = crawler_num - 1;}};

//======================== Climb Over Barricade ====================
//40-70
void() crawler_climbBarricade1	=[	0,		crawler_climbBarricade2] 	{self.movetype = MOVETYPE_STEP;self.zoom = 1;self.frame = 40;Zombie_Think();};
void() crawler_climbBarricade2	=[	1,		crawler_climbBarricade3] 	{self.frame = 41;	moveforwardalittle(0);Zombie_Think();};
void() crawler_climbBarricade3	=[	2,		crawler_climbBarricade4] 	{self.frame = 42;	moveforwardalittle(0);Zombie_Think();};
void() crawler_climbBarricade4	=[	3,		crawler_climbBarricade5] 	{self.frame = 43;	moveforwardalittle(1);Zombie_Think();};
void() crawler_climbBarricade5	=[	4,		crawler_climbBarricade6] 	{self.frame = 44;	moveforwardalittle(0);Zombie_Think();};
void() crawler_climbBarricade6	=[	5,		crawler_climbBarricade7] 	{self.frame = 45;	moveforwardalittle(0);Zombie_Think();};
void() crawler_climbBarricade7	=[	6,		crawler_climbBarricade8] 	{self.frame = 46;	moveforwardalittle(1);Zombie_Think();};
void() crawler_climbBarricade8	=[	7,		crawler_climbBarricade9] 	{self.frame = 47;	moveforwardalittle(0);Zombie_Think();};
void() crawler_climbBarricade9	=[	8,		crawler_climbBarricade10] 	{self.frame = 48;	moveforwardalittle(0);Zombie_Think();};
void() crawler_climbBarricade10	=[	9,		crawler_climbBarricade11] 	{self.frame = 49;	moveforwardalittle(1);Zombie_Think();};
void() crawler_climbBarricade11	=[	10,		crawler_climbBarricade12] 	{self.frame = 50;	moveforwardalittle(0);Zombie_Think();};
void() crawler_climbBarricade12	=[	11,		crawler_climbBarricade13] 	{self.frame = 51;	moveforwardalittle(0);Zombie_Think();};
void() crawler_climbBarricade13	=[	12,		crawler_climbBarricade14] 	{self.frame = 52;	moveforwardalittle(1);Zombie_Think();};
void() crawler_climbBarricade14	=[	13,		crawler_climbBarricade15] 	{self.frame = 53;	moveforwardalittle(0);Zombie_Think();};
void() crawler_climbBarricade15	=[	14,		crawler_climbBarricade16] 	{self.frame = 54;	moveforwardalittle(0);Zombie_Think();};
void() crawler_climbBarricade16	=[	15,		crawler_climbBarricade17] 	{self.frame = 55;	moveforwardalittle(1);Zombie_Think();};
void() crawler_climbBarricade17	=[	16,		crawler_climbBarricade18] 	{self.frame = 56;	moveforwardalittle(0);Zombie_Think();};
void() crawler_climbBarricade18	=[	17,		crawler_climbBarricade19] 	{self.frame = 57;	moveforwardalittle(0);Zombie_Think();};
void() crawler_climbBarricade19	=[	18,		crawler_climbBarricade20] 	{self.frame = 58;	moveforwardalittle(1);Zombie_Think();};
void() crawler_climbBarricade20	=[	19,		crawler_climbBarricade21] 	{self.frame = 59;	moveforwardalittle(0);Zombie_Think();};
void() crawler_climbBarricade21	=[	20,		crawler_climbBarricade22] 	{self.frame = 60;	moveforwardalittle(0);Zombie_Think();};
void() crawler_climbBarricade22	=[	21,		crawler_climbBarricade23] 	{self.frame = 61;	moveforwardalittle(1);Zombie_Think();};
void() crawler_climbBarricade23	=[	22,		crawler_climbBarricade24] 	{self.frame = 62;	moveforwardalittle(0);Zombie_Think();};
void() crawler_climbBarricade24	=[	23,		crawler_climbBarricade25] 	{self.frame = 63;	moveforwardalittle(0);Zombie_Think();};
void() crawler_climbBarricade25	=[	24,		crawler_climbBarricade26] 	{self.frame = 64;	moveforwardalittle(1);Zombie_Think();};
void() crawler_climbBarricade26	=[	25,		crawler_climbBarricade27] 	{self.frame = 65;	moveforwardalittle(0);Zombie_Think();};
void() crawler_climbBarricade27	=[	26,		crawler_climbBarricade28] 	{self.frame = 66;	moveforwardalittle(0);Zombie_Think();};
void() crawler_climbBarricade28	=[	27,		crawler_climbBarricade29] 	{self.frame = 67;	moveforwardalittle(1);Zombie_Think();};
void() crawler_climbBarricade29	=[	28,		crawler_climbBarricade30] 	{self.frame = 68;	moveforwardalittle(1);Zombie_Think();};
void() crawler_climbBarricade30	=[	29,		crawler_climbBarricade31] 	{self.frame = 69;	moveforwardalittle(1);Zombie_Think();};
void() crawler_climbBarricade31	=[	30,		SUB_Null] 	{self.frame = 70;	self.movetype = MOVETYPE_WALK; self.zoom = 1;self.state = 0;self.hop_step = 6; self.th_walk();Zombie_Think();};

//======================== Crawler Fall =============================
//71 - 77
void() crawler_fall1		=[	0,		crawler_fall2] 	{SetZombieHitBox(CRAWLER_BBOX);self.fall = TRUE;CheckLand();self.frame=71;Zombie_Think();};
void() crawler_fall2		=[	1,		crawler_fall3] 	{self.fall = TRUE;CheckLand();self.frame=72;Zombie_Think();};
void() crawler_fall3		=[	2,		crawler_fall4] 	{self.fall = TRUE;CheckLand();self.frame=73;Zombie_Think();};
void() crawler_fall4		=[	3,		crawler_fall5] 	{self.fall = TRUE;CheckLand();self.frame=74;Zombie_Think();};
void() crawler_fall5		=[	4,		crawler_fall6] 	{self.fall = TRUE;CheckLand();self.frame=75;Zombie_Think();};
void() crawler_fall6		=[	5,		crawler_fall7] 	{self.fall = TRUE;CheckLand();self.frame=76;Zombie_Think();};
void() crawler_fall7		=[	6,		crawler_fall1] 	{self.fall = TRUE;CheckLand();self.frame=77;Zombie_Think();};
//======================== Crawler Land ============================
//77-86
void() crawler_land1		=[	0,		crawler_land2] 	{SetZombieHitBox(CRAWLER_BBOX);self.frame=77;Zombie_Think();};
void() crawler_land2		=[	1,		crawler_land3] 	{self.frame=78;Zombie_Think();};
void() crawler_land3		=[	2,		crawler_land4] 	{self.frame=79;Zombie_Think();};
void() crawler_land4		=[	3,		crawler_land5] 	{self.frame=80;Zombie_Think();};
void() crawler_land5		=[	4,		crawler_land6] 	{self.frame=81;Zombie_Think();};
void() crawler_land6		=[	5,		crawler_land7] 	{self.frame=82;Zombie_Think();};
void() crawler_land7		=[	6,		crawler_land8] 	{self.frame=83;Zombie_Think();};
void() crawler_land8		=[	7,		crawler_land9] 	{self.frame=84;Zombie_Think();};
void() crawler_land9		=[	8,		crawler_land10] 	{self.frame=85;Zombie_Think();};
void() crawler_land10		=[	9,		Crawler_Walk_Setup] 	{self.frame=86;Zombie_Think();};
//======================== Crawler Rip Board =======================
//103-126

void() crawler_rip_board1		=[	0,		crawler_rip_board2] 	{SetZombieHitBox(CRAWLER_BBOX);self.frame=103;Zombie_Think();};
void() crawler_rip_board2		=[	1,		crawler_rip_board3] 	{self.frame=104;Zombie_Think();};
void() crawler_rip_board3		=[	2,		crawler_rip_board4] 	{self.frame=105;Zombie_Think();};
void() crawler_rip_board4		=[	3,		crawler_rip_board5] 	{self.frame=106;Zombie_Think();};
void() crawler_rip_board5		=[	4,		crawler_rip_board6] 	{self.frame=107;Zombie_Think();};
void() crawler_rip_board6		=[	5,		crawler_rip_board7] 	{self.frame=108;Zombie_Think();};
void() crawler_rip_board7		=[	6,		crawler_rip_board8] 	{self.frame=109;Zombie_Think();};
void() crawler_rip_board8		=[	7,		crawler_rip_board9] 	{self.frame=110;Zombie_Think();};
void() crawler_rip_board9		=[	8,		crawler_rip_board10] 	{self.frame=111;Zombie_Think();};
void() crawler_rip_board10		=[	9,		crawler_rip_board11] 	{self.frame=112;Zombie_Think();};
void() crawler_rip_board11		=[	10,		crawler_rip_board12] 	{self.frame=113;Zombie_Think();};
void() crawler_rip_board12		=[	11,		crawler_rip_board13] 	{self.frame=114;Zombie_Think();};
void() crawler_rip_board13		=[	12,		crawler_rip_board14] 	{self.frame=115;zombie_attack2();};
void() crawler_rip_board14		=[	13,		crawler_rip_board15] 	{self.frame=116;Zombie_Think();};
void() crawler_rip_board15		=[	14,		crawler_rip_board16] 	{self.frame=117;Zombie_Think();};
void() crawler_rip_board16		=[	15,		crawler_rip_board17] 	{self.frame=118;Zombie_Think();};
void() crawler_rip_board17		=[	16,		crawler_rip_board18] 	{self.frame=119;Zombie_Think();};
void() crawler_rip_board18		=[	17,		crawler_rip_board19] 	{self.frame=120;Zombie_Think();};
void() crawler_rip_board19		=[	18,		crawler_rip_board20] 	{self.frame=121;Zombie_Think();};
void() crawler_rip_board20		=[	19,		crawler_rip_board21] 	{self.frame=122;Zombie_Think();};
void() crawler_rip_board21		=[	20,		crawler_rip_board22] 	{self.frame=123;Zombie_Think();};
void() crawler_rip_board22		=[	21,		crawler_rip_board23] 	{self.frame=124;Zombie_Think();};
void() crawler_rip_board23		=[	22,		crawler_rip_board24] 	{self.frame=125;Zombie_Think();};
void() crawler_rip_board24		=[	23,		zombie_decide] 	{self.frame=126;Zombie_Think();};

void(entity who) makeCrawler =
{         
	if(who.state == 1)
	{
		who.crawling = 2;
		return;
	}
	who.crawling = 2;//this means we haven't technically initiated it, but we're going to...
	
	who.th_die = Zombie_Death;
	who.th_walk = Crawler_Walk_Setup;
	who.th_melee = zombie_attack;
	who.th_idle = crawler_idle1;
	who.th_windowhop = crawler_climbBarricade1;
	
	who.th_fall = crawler_fall1;
	who.th_land = crawler_land1;
	
	//who.th_jump = zombie_jump1;
	//who.th_grabledge = zombie_grabledge1;
	//who.th_diewunder = die_wunder1;
	
	setmodel(who,"models/ai/zcbod.mdl");
	if(who.head.deadflag)
	{
		setmodel(who.head,"models/ai/zchead.mdl");
		//updateLimb (who, 0, world);
	}
	if(who.larm.deadflag)
	{
		setmodel(who.larm,"models/ai/zclarm.mdl");
		//updateLimb (who, 1, world);
	}
	if(who.rarm.deadflag)
	{
		setmodel(who.rarm,"models/ai/zcrarm.mdl");
		//updateLimb (who, 2, world);
	}
	who.crawling = 1;
	
	setsize(who,'-8 -8 -32','8 8 -15');
	
	local entity oself;
	oself = self;
	self = who;
	crawlerify1();
	self = oself;
	
	crawler_num = crawler_num + 1;
}
