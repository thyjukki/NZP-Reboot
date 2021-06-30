//*********************************************************************/
//							HUD Drawing Code						   /
//																	   /
//*********************************************************************/			

//return hud images, makes drawpic slightly cleaner..
string(string img) getImage = {
	return strcat(huddir, img);
}


/*******************
*    HUD_Health   *
*******************/

void(float width, float height) HUD_Health = 
{
	local float health;	
	float alpha;
	
	health = getstatf(STAT_HEALTH); 

	if (health < 100)
	{
		alpha = (100.0 - ((1.25 * health) - 25))/100*255;
		if (alpha <= 0.0)
			return;
		float modifier = (sin(time * 10) * 20) - 20;//always negative
		if(modifier < -35.0)
		modifier = -35.0;
    
		alpha += modifier;
    
		if(alpha < 0.0)
			return;
		float color = 255.0 + modifier;
    
		drawpic([0,0,0], getImage("blood.tga"), [width, height, 0], [10,0,0], alpha/2000); // naievil -- alpha factor division here makes it easy to use legacy code
	}
	
}

/*******************
*    HUD_Ammo      *
*******************/

void(float width, float height) HUD_Ammo =
{
	local float ammo, curmag, benis, benis2;
	string ammostring, ammostring_1, ammostring_2;
	vector color;
	
	curmag = getstatf(STAT_CURRENTMAG);		
	ammo = getstatf(STAT_AMMO);	
	
	benis = strlen(ftos(ammo));
	benis2 = strlen(ftos(curmag));
	benis = benis + benis2;
	
	if (GetLowAmmo(getstatf(STAT_ACTIVEWEAPON), 1) >= getstatf(STAT_CURRENTMAG))
		color = [215/255, 0, 0];
	else
		color = [1, 1, 1];
	
	if (GetLowAmmo(getstatf(STAT_ACTIVEWEAPON), 0) >= getstatf(STAT_AMMO))
		vector color_2 = [215/255, 0, 0];
	else
		color_2 = [1, 1, 1];


	if (IsDualWeapon(getstatf(STAT_ACTIVEWEAPON))) {
		float curmag2 = getstatf(STAT_CURRENTMAG2);
		
		ammostring = strcat(ftos(curmag2), " ", ftos(curmag), "/", ftos(ammo));
		drawstring([width - (42/480)*width - (benis*20*width/1024), 0.96*height, 0], ammostring, [0.02*width, 0.02*width, 0], [1,1,1], 1, 0);
	} else {
		ammostring_1 = ftos(curmag);
		ammostring_2 = strcat("/",ftos(ammo));
		drawstring([width - (42/480)*width - (benis*20*width/1024), 0.96*height, 0], ammostring_1, [0.02*width, 0.02*width, 0], color, 1, 0);
		drawstring([width - (42/480)*width - ((benis-strlen(ftos(curmag)))*20*width/1024), 0.96*height, 0], ammostring_2, [0.02*width, 0.02*width, 0], color_2, 1, 0);
	}
}

float ammoopac, ammoloop;
void() HUD_AmmoString =
{
	vector textcolor = [1, 1, 1];
	string message = "";
	
	if (GetLowAmmo(getstatf(STAT_ACTIVEWEAPON), 1) >= getstatf(STAT_CURRENTMAG) && getstatf(STAT_WEAPONZOOM) != 2)
	{
		if (0 < getstatf(STAT_AMMO) && getstatf(STAT_CURRENTMAG) >= 0) {
			message = "Reload";
			textcolor = [1, 1, 1];
		} else if (0 < getstatf(STAT_CURRENTMAG)) {
			message = "LOW AMMO";
			textcolor = [219/255, 203/255, 19/255];		
		} else {
			message = "NO AMMO";
			textcolor = [215/255, 0, 0];
		}

		if (ammoloop == 0) {
			ammoopac -= frametime;
			if (ammoopac < 0.5) {
				ammoopac = 0.5;
				ammoloop = 1;
			}
		} else {
			ammoopac += frametime;
			if (ammoopac >= 1) {
				ammoopac = 1;
				ammoloop = 0;
			}
		}

		drawstring([g_width/2, g_height/2 + (30/272)*g_height, 0], message, [0.02*g_width, 0.02*g_width, 0], textcolor, ammoopac, 0);
	} else {
		ammoopac = 1;
		ammoloop = 0;
	}
}

/*******************
*    HUD_Points    *
*******************/

#define MAX_POINT_ELEMENTS 		64 		// the maximum amount of point differential elements that can be spawned before
								   		// we iterate back from 0

var struct
{
	float 	difference; 				// the difference of points
	float 	x_position; 				// current x position
	float 	y_position; 				// current y position
	float 	x_velocity; 				// how fast the element moves on the x axis
	float 	y_velocity 					// how fast the element moves on the y axis
	float 	opacity; 					// the opacity of the text_string as it progresses
	float 	string_width 				// the width of text_string
	string 	text_string; 				// either '+(difference)' or '-(difference)'
} point_elements[MAX_POINT_ELEMENTS];

float last_point_element_index;

void(float amount) RegisterPointChange =
{
	if (last_point_element_index >= MAX_POINT_ELEMENTS)
		last_point_element_index = 0;

	float index = last_point_element_index;

	// set the difference amount
	point_elements[index].difference = amount;

	// fill our text string
	if (point_elements[index].difference > 0) {
		point_elements[index].text_string = strcat("+", ftos(point_elements[index].difference));
	} else {
		point_elements[index].text_string = ftos(point_elements[index].difference);
	}

	// determine the width of the text string
	point_elements[index].string_width = stringwidth(point_elements[index].text_string, 0, [0.022*g_width, 0.022*g_width, 0]);

	// generate a velocity
	point_elements[index].y_velocity = random()/4;
	while (point_elements[index].x_velocity < 0.33) {
		point_elements[index].x_velocity = random();
	}

	if (point_elements[index].x_velocity > 0.70)
		point_elements[index].x_velocity -= 0.2;

	// should the vertical velocity be positive or negative?
	float rng = random();

	// negative
	if (rng < 0.5) {
		point_elements[index].y_velocity = -point_elements[index].y_velocity;
	}

	// set our x and y positions
	point_elements[index].x_position = 0;
	point_elements[index].y_position = 0.720 * g_height;

	// start with an opacity of 1
	point_elements[index].opacity = 1;

	// iterate
	last_point_element_index++;
}

void(float pwidth, float width, float height) PointUpdate = 
{
	vector POINT_DIFF_COLOR;

	for (float i = 0; i < MAX_POINT_ELEMENTS; i++) {
		// should the text be red or orange?
		if (point_elements[i].difference > 0) {
			POINT_DIFF_COLOR = TEXT_ORANGE;
		} else {
			POINT_DIFF_COLOR = TEXT_RED;
		}

		if (point_elements[i].difference != 0 && point_elements[i].opacity > 0 /* &&
		(point_elements[i].x_position - point_elements[i].string_width) < g_width * 0.05*/) {

			drawstring([pwidth - point_elements[i].string_width - point_elements[i].x_position, 
			point_elements[i].y_position, 0], point_elements[i].text_string, [0.022*width, 0.022*width, 0], 
			POINT_DIFF_COLOR, point_elements[i].opacity, 0);
		}

		point_elements[i].x_position += point_elements[i].x_velocity * (frametime*375);
		point_elements[i].y_position += point_elements[i].y_velocity * (frametime*375);
		point_elements[i].opacity -= (frametime*4);
	}
}

void(float width, float height) HUD_Points =
{
	local float pointlength = 0, increm = 10, i = 0, pointwidth = 0, x = 0;
	local float backwidth = 0.8*width;
	vector TEXTCOLOR;
	
	for (i = 3; i >= 0; i = i - 1)
	{
		if (playerpoints[i] == -1)
			continue;
			
		switch(i) {
			case 1: TEXTCOLOR = TEXT_LIGHTBLUE; break;
			case 2: TEXTCOLOR = TEXT_ORANGE; break;
			case 3: TEXTCOLOR = TEXT_GREEN; break;
			default: TEXTCOLOR = [1, 1, 1]; break;
		}
		
		if ((i+1) == getstatf(STAT_PLAYERNUM)) {
			pointwidth = stringwidth(ftos(playerpoints[i]), 0, [0.022*width, 0.022*width, 0]);
			x = ((width + backwidth) - pointwidth)/2;
			drawpic([backwidth ,0.70*height - (.061*height*i),0], getImage("moneyback.tga"), [0.2*width, 0.07*height, 0], [1,1,1], 1); 
			drawstring([x, 0.715*height - 0.06*height*i, 0], ftos(playerpoints[i]), [0.022*width, 0.022*width, 0], TEXTCOLOR, 1, 0); 
			PointUpdate(backwidth * 1.025, width, height); 
		}
		else {
			backwidth = 0.85*width;
			pointwidth = stringwidth(ftos(playerpoints[i]), 0, [0.022*width*0.8, 0.022*width*0.8, 0]);
			x = ((width + backwidth) - pointwidth)/2;
			drawpic([backwidth, 0.70*height - (.071*height*i*0.8),0], getImage("moneyback.tga"), [0.2*width*0.8, 0.07*height*0.8, 0], [1,1,1], 0); 
			drawstring([x, 0.715*height - 0.07*height*i*0.8, 0], ftos(playerpoints[i]), [0.022*width*0.8, 0.022*width*0.8, 0], TEXTCOLOR, 1, 0); 
		}
	}
}

/*******************
*    HUD_Grenades  *
*******************/

void(float width, float height) HUD_Grenades =
{
	local float grenades;
	local float betties;

	grenades = getstatf(STAT_GRENADES);
	betties = getstatf(STAT_SECGRENADES);
	drawpic([0.9*width,0.825*height,0], getImage("frag.tga"), [50, 50, 0], [1,1,1], 1);
	drawstring([0.9*width + 28, 0.825*height + 32, 0], ftos(grenades), [0.025*width, 0.025*width, 0], [1, 1, 1], 1, 0);
	
	if (betties != -1) {
		drawpic([0.825*width,0.825*height,0], getImage("betty.tga"), [50, 50, 0], [1,1,1], 1);
		drawstring([0.825*width + 28, 0.825*height + 32, 0], ftos(betties), [0.025*width, 0.025*width, 0], [1, 1, 1], 1, 0);
	}
}

/*******************
*    HUD_Rounds    *
*******************/

float 	color_shift[3];
float 	color_shift_end[3];
float 	color_shift_steps[3];
int		color_shift_init;
int 	blinking;
string sb_round[5];
string sb_round_num[10];
int alphabling;
float endroundchange;
float round_center_x;
float round_center_y;
//motolegacy -- 'round' text
float pwidth;
float rcolor, rinit, ralpha, localpha;

void(float width, float height) HUD_Rounds =
{	
	float roundheight = 48/272*height;
	float roundwidth = 0.02291666*width;
	
	float roundwidth_4 = (60/480)*width;
	float roundheight_4 = (48/272)*height;
	
	float roundheight_num = 48/272*height;
	float roundwidth_num = 48/480*height; // naievil -- was 32, but more square makes it look better

//	drawstring([0.01*width, 0.70*height, 0], ftos(rounds_change), [0.03*width, 0.03*width, 0], [1, 1, 1], 1, 1); // draw roundchange

	int i, x_offset, icon_num, savex;
	int num[3];
	x_offset = 0;
	savex = 0;

	for (float j = 0; j < 10; j++) {
		if (j < 5) {
			sb_round[j] = getImage(strcat("r", ftos(j+1), ".tga"));
		}

		sb_round_num[j] = getImage(strcat("r_num", ftos(j), ".tga"));
	}

	if (rounds_change == 1 || rounds_change == 2) {
		if (!rinit) {
			rcolor = rinit = 1;
			ralpha = 1;
		}

		pwidth = (width - stringwidth("Round", 0, [0.030*width, 0.030*width, 0]))/2;
		drawstring([pwidth, 0.35*height, 0], "Round", [0.030*width, 0.030*width, 0], [1, rcolor, rcolor], ralpha, 0);

		rcolor -= frametime/2.5;
		if (rcolor < 0) {
			rcolor = 0;
			ralpha -= frametime/2.5;
			if (ralpha > 0) {
				localpha += frametime*0.4;
				if (localpha > 1)
					localpha = 1;
			}
			if (ralpha < 0) {
				ralpha = 0;
				localpha -= frametime*0.4;
				if (localpha < 0)
					localpha = 0;
			}
		}

		drawstring([0.01*width, 0.66*height, 0], chaptertitle, [0.015*width, 0.015*width, 0], [1, 1, 1], localpha, 0);
		drawstring([0.01*width, 0.69*height, 0], location, [0.015*width, 0.015*width, 0], [1, 1, 1], localpha, 0);
		drawstring([0.01*width, 0.72*height, 0], date, [0.015*width, 0.015*width, 0], [1, 1, 1], localpha, 0);
		drawstring([0.01*width, 0.75*height, 0], person, [0.015*width, 0.015*width, 0], [1, 1, 1], localpha, 0);
	}

	if (rounds_change == 1)//this is the rounds icon at the middle of the screen
	{
		alphabling = alphabling + (frametime*500);

		if (alphabling < 0)
			alphabling = 0;
		else if (alphabling > 255)
			alphabling = 255;
			
		round_center_x = (g_width - (11*g_width/480)) /2;
		round_center_y = (g_height - (48*g_height/272)) /2;
		
		drawpic([round_center_x,round_center_y,0], sb_round[0], [roundwidth, roundheight, 1], [107/255,1/255,0], alphabling/255);
	}
	else if (rounds_change == 2)//this is the rounds icon moving from middle
	{
		float round_center_y_offset, round_center_x_offset;
				
		drawpic([round_center_x + round_center_x_offset,round_center_y + round_center_y_offset,0], sb_round[0], [roundwidth,roundheight, 1], [107/255,(1/255),0], 1);
		
		round_center_x = round_center_x - (((229/108)*2 - 0.2)*(width/480)/8) * (frametime*250);
		round_center_y = round_center_y + ((2*(height/272))/8) * (frametime*250);
		if (round_center_x <= (5/480)*height)
			round_center_x = (5/480)*height;
		if (round_center_y >= (220/272)*height)
			round_center_y = (220/272)*height;
					
	}
	else if (rounds_change == 3)//shift to white
	{
		if (!color_shift_init)
		{
			color_shift[0] = 107;
			color_shift[1] = 1;
			color_shift[2] = 0;
			for (i = 0; i < 3; i = i + 1)
			{
				color_shift_end[i] = 255;
				color_shift_steps[i] = (color_shift_end[i] - color_shift[i])/60;
			}
			color_shift_init = 1;
		}
		for (i = 0; i < 3; i = i + 1)
		{
			if (color_shift[i] < color_shift_end[i])
				color_shift[i] = color_shift[i] + color_shift_steps[i]*(frametime*100);

			if (color_shift[i] >= color_shift_end[i])
				color_shift[i] = color_shift_end[i];
		}
		if (rounds > 0 && rounds < 11)
		{

			for (i = 0; i < rounds; i = i + 1)
			{
				if (i == 4)
				{
					drawpic([5,height - roundheight, 0], sb_round[4], [roundwidth_4,roundheight_4, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);
					
					savex = x_offset + (10*width/480);
					x_offset = x_offset + (10*width/480);
					continue;
				}
				if (i == 9)
				{
					drawpic([5 + savex, height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);
					continue;
				}
				if (i > 4)
					icon_num = i - 5;
				else
					icon_num = i;

				drawpic([5 + x_offset, height - roundheight - (4*height/272),0], sb_round[icon_num], [roundwidth,roundheight, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

				x_offset = x_offset +  roundwidth + (3*width/480);
			}
		}
		else
		{
			if (rounds >= 100)
			{
				num[2] = (int)(rounds/100);
				drawpic([5 + x_offset, height - roundheight - (4*height/272),0], sb_round_num[num[2]], [roundwidth_num, roundheight_num, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);
								
				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[2] = 0;
			if (rounds >= 10)
			{
				num[1] = (int)((rounds - num[2]*100)/10);
				drawpic([5 + x_offset, height - roundheight - (4*height/272),0], sb_round_num[num[1]], [roundwidth_num,roundheight_num, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[1] = 0;

			num[0] = rounds - num[2]*100 - num[1]*10;
			drawpic([5 + x_offset, height - roundheight - (4*height/272),0], sb_round_num[num[0]], [roundwidth_num,roundheight_num, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

			x_offset = x_offset +  roundwidth_num - (8*width/480);
		}
	}
	else if (rounds_change == 4)//blink white
	{
	
		if (endroundchange > time)
		{
			blinking = ((int)(time*1000)&510) - 255;
			blinking = fabs(blinking);
		}
		else
		{
			if (blinking)
				blinking = blinking - 1;
			else
				blinking = 0;
		}
			
	
		if (rounds > 0 && rounds < 11)
		{
			for (i = 0; i < rounds; i = i + 1)
			{
				if (i == 4)
				{
					drawpic([5, height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [1,1,1], blinking/255);

					savex = x_offset + (10*width/480);
					x_offset = x_offset + (10*width/480);
					continue;
				}
				if (i == 9)
				{
					drawpic([5 + savex, height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [1,1,1], blinking/255);

					continue;
				}
				if (i > 4)
					icon_num = i - 5;
				else
					icon_num = i;

					drawpic([5 + x_offset, height - roundheight - (4*height/272),0], sb_round[icon_num], [roundwidth,roundheight, 1], [1,1,1], blinking/255);

				x_offset = x_offset +  roundwidth + (3*width/480);
			}
		}
		else
		{
			if (rounds >= 100)
			{
				num[2] = (int)(rounds/100);
				drawpic([2 + x_offset, height - roundheight - (4*height/272),0], sb_round_num[num[2]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);
					
				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[2] = 0;
			if (rounds >= 10)
			{
				num[1] = (int)((rounds - num[2]*100)/10);
				drawpic([2 + x_offset, height - roundheight - (4*height/272),0], sb_round_num[num[1]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);
				
				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[1] = 0;

			num[0] = rounds - num[2]*100 - num[1]*10;
			drawpic([2 + x_offset, height - roundheight - (4*height/272),0], sb_round_num[num[0]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);
			
			x_offset = x_offset +  roundwidth_num - (8*width/480);
		}
		
		if (endroundchange == 0)
			endroundchange = time + 2;
	}
	else if (rounds_change == 5)//blink white
	{
		if (blinking > 0)
			blinking = blinking - (frametime*5000);
		if (blinking < 0)
			blinking = 0;
		if (rounds > 0 && rounds < 11)
		{
			for (i = 0; i < rounds; i = i + 1)
			{
				if (i == 4)
				{
					drawpic([5, height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [1,1,1], blinking/255);

					savex = x_offset + (10*width/480);
					x_offset = x_offset + (10*width/480);
					continue;
				}
				if (i == 9)
				{
					drawpic([5 + savex, height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [1,1,1], blinking/255);
					continue;
				}
				if (i > 4)
					icon_num = i - 5;
				else
					icon_num = i;

				drawpic([5 + x_offset, height - roundheight - (4*height/272),0], sb_round[icon_num], [roundwidth,roundheight, 1], [1,1,1], blinking/255);

				x_offset = x_offset +  roundwidth + (3*width/480);
			}
		}
		else
		{
			if (rounds >= 100)
			{
				num[2] = (int)(rounds/100);
				drawpic([2 + x_offset, height - roundheight - (4*height/272),0], sb_round_num[num[2]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);

				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[2] = 0;
			if (rounds >= 10)
			{
				num[1] = (int)((rounds - num[2]*100)/10);
				drawpic([2 + x_offset, height - roundheight - (4*height/272),0], sb_round_num[num[1]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);

				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[1] = 0;

			num[0] = rounds - num[2]*100 - num[1]*10;
			drawpic([2 + x_offset, height - roundheight - (4*height/272),0], sb_round_num[num[0]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);

			x_offset = x_offset +  roundwidth_num - (8*width/480);
		}
	}
	else if (rounds_change == 6)//blink white while fading back
	{
		endroundchange = 0;
		
		color_shift_init = 0;
		blinking = ((int)(time*1000)&510) - 255;
		
		blinking = fabs(blinking);
			
		if (rounds > 0 && rounds < 11)
		{
			for (i = 0; i < rounds; i = i + 1)
			{
				if (i == 4)
				{
					drawpic([5, height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [1,1,1], blinking/255);
								
					savex = x_offset + (10*width/480);
					x_offset = x_offset + (10*width/480);
					continue;
				}
				if (i == 9)
				{
					drawpic([5 + savex, height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [1,1,1], blinking/255);

					continue;
				}
				if (i > 4)
					icon_num = i - 5;
				else
					icon_num = i;

				drawpic([5 + x_offset, height - roundheight - (4*height/272),0], sb_round[icon_num], [roundwidth,roundheight, 1], [1,1,1], blinking/255);

				x_offset = x_offset +  roundwidth + (3*width/480);
			}
		}
		else
		{
			if (rounds >= 100)
			{
				num[2] = (int)(rounds/100);
				drawpic([2 + x_offset, height - roundheight - (4*height/272),0], sb_round_num[num[2]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);
				
				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[2] = 0;
			if (rounds >= 10)
			{
				num[1] = (int)((rounds - num[2]*100)/10);
				drawpic([2 + x_offset, height - roundheight - (4*height/272),0], sb_round_num[num[1]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);

				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[1] = 0;

			num[0] = rounds - num[2]*100 - num[1]*10;
			drawpic([2 + x_offset, height - roundheight - (4*height/272),0], sb_round_num[num[0]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);

			x_offset = x_offset +  roundwidth_num - (8*width/480);
		}
	}
	else if (rounds_change == 7)//blink white while fading back
	{
		if (!color_shift_init)
		{
			color_shift_end[0] = 107;
			color_shift_end[1] = 1;
			color_shift_end[2] = 0;
			for (i = 0; i < 3; i = i + 1)
			{
				color_shift[i] = 255;
				color_shift_steps[i] = (color_shift[i] - color_shift_end[i])*(frametime*1.5);
			}
			color_shift_init = 1;
		}
		for (i = 0; i < 3; i = i + 1)
		{
			if (color_shift[i] > color_shift_end[i])
				color_shift[i] = color_shift[i] - color_shift_steps[i];

			if (color_shift[i] < color_shift_end[i])
				color_shift[i] = color_shift_end[i];
		}
		if (rounds > 0 && rounds < 11)
		{
			for (i = 0; i < rounds; i = i + 1)
			{
				if (i == 4)
				{
					drawpic([5, height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

					savex = x_offset + (10*width/480);
					x_offset = x_offset + (10*width/480);
					continue;
				}
				if (i == 9)
				{
					drawpic([5 + savex, height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

					continue;
				}
				if (i > 4)
					icon_num = i - 5;
				else
					icon_num = i;

				drawpic([5 + x_offset, height - roundheight - (4*height/272),0], sb_round[icon_num], [roundwidth,roundheight, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

				x_offset = x_offset +  roundwidth + (3*width/480);
			}
		}
		else
		{
			if (rounds >= 100)
			{
				num[2] = (int)(rounds/100);
				drawpic([2+x_offset, height - roundheight - (4*height/272),0], sb_round_num[num[2]], [roundwidth_num,roundheight_num, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[2] = 0;
			if (rounds >= 10)
			{
				num[1] = (int)((rounds - num[2]*100)/10);
				drawpic([2+x_offset, height - roundheight - (4*height/272),0], sb_round_num[num[1]], [roundwidth_num,roundheight_num, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[1] = 0;

			num[0] = rounds - num[2]*100 - num[1]*10;
			drawpic([2+x_offset, height - roundheight - (4*height/272),0], sb_round_num[num[0]], [roundwidth_num,roundheight_num, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

			x_offset = x_offset +  roundwidth_num - (8*width/480);
		}
	}
	else
	{
		color_shift[0] = 107;
		color_shift[1] = 1;
		color_shift[2] = 0;
		color_shift_init = 0;
		alphabling = 0;
		if (rounds > 0 && rounds < 11)
		{
			for (i = 0; i < rounds; i = i + 1)
			{
				if (i == 4)
				{
					drawpic([5, height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [107/255,1/255,0], 1);

					savex = x_offset + (10*width/480);
					x_offset = x_offset + (10*width/480);
					continue;
				}
				if (i == 9)
				{
					drawpic([5 + savex, height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [107/255,1/255,0], 1);

					continue;
				}
				if (i > 4)
					icon_num = i - 5;
				else
					icon_num = i;

				drawpic([5 + x_offset, height - roundheight - (4*height/272),0], sb_round[icon_num], [roundwidth,roundheight, 1], [107/255,1/255,0], 1);

				x_offset = x_offset +  roundwidth + (3*width/480);
			}
		}
		else
		{
			if (rounds >= 100)
			{
				num[2] = (int)(rounds/100);
				drawpic([2 + x_offset, height - roundheight - (4*height/272),0], sb_round_num[num[2]], [roundwidth_num,roundheight_num, 1], [107/255,1/255,0], 1);

				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[2] = 0;
			if (rounds >= 10)
			{
				num[1] = (int)((rounds - num[2]*100)/10);
				drawpic([2 + x_offset, height - roundheight - (4*height/272),0], sb_round_num[num[1]], [roundwidth_num,roundheight_num, 1], [107/255,1/255,0], 1);

				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[1] = 0;

			num[0] = rounds - num[2]*100 - num[1]*10;
			
			if(rounds == 0)
				return;
			
			drawpic([2 + x_offset, height - roundheight - (4*height/272),0], sb_round_num[num[0]], [roundwidth_num,roundheight_num, 1], [107/255,1/255,0], 1);

			x_offset = x_offset +  roundwidth_num - (8*width/480);
		}
	}
}

/*******************
*    HUD_Useprint  *
*******************/

void(float width, float height) HUD_Useprint =
{
	string usestring, usebutton, usespace;
	float print_width, x, button_width;
		
	tokenize(findkeysforcommand("+button7"));
	usebutton = strtoupper(keynumtostring(stof(argv(0))));

	for(float i = 0; i < strlen(usebutton); i++) {
		usespace = strcat(usespace, " ");
	}

	switch (useprint_type) {
		case 0://clear
			usestring = "";
			break;
		case 1://door
			usestring = strcat("Hold ",usespace, " to open Door [Cost:", ftos(useprint_cost),"]");
			break;
		case 2://debris
			usestring = strcat("Hold ",usespace, " to remove Debris [Cost:", ftos(useprint_cost),"]");
			break;
		case 3://ammo
			usestring = strcat("Hold ",usespace, " to buy Ammo for ", GetWeaponName(useprint_weapon), " [Cost:", ftos(useprint_cost),"]");
			break;
		case 4://weapon
			usestring = strcat("Hold ",usespace, " to buy ", GetWeaponName(useprint_weapon), " [Cost:", ftos(useprint_cost),"]");
			break;
		case 5://window
			usestring = strcat("Hold ",usespace, " to Rebuild Barrier");
			break;
		case 6://box
			usestring = strcat("Hold ",usespace, " to buy a Random Weapon [Cost:", ftos(useprint_cost),"]");
			break;
		case 7://box take
			usestring = strcat("Hold ",usespace, " to take Weapon");
			break;
		case 8://power
			usestring = "The Power must be Activated first";
			break;
		case 9://perk
			usestring = strcat("Hold ",usespace, " to buy ", GetPerkName(useprint_weapon), " [Cost:", ftos(useprint_cost),"]");
			break;
		case 10://turn on power
			usestring = strcat("Hold ",usespace, " to Turn On the Power");
			break;
		case 11://turn on trap
			usestring = strcat("Hold ",usespace, " to Activate the Trap [Cost:", ftos(useprint_cost), "]");
			break;
		case 12://packapunch
			usestring = strcat("Hold ",usespace, " to Pack-a-Punch [Cost:", ftos(useprint_cost), "]");
			break;
		case 13://revive
			usestring = strcat("Hold ",usespace, " to Revive Player");
			break;
		case 14://use teleporter (free)
			usestring = strcat("Hold ", usespace, " to use Teleporter");
			break;
		case 15://use teleporter (cost)
			usestring = strcat("Hold ", usespace, " to use Teleporter [Cost: ", ftos(useprint_cost), "]");
			break;
		case 16://tp cooldown
			usestring = "Teleporter is cooling down";
			break;
		case 17://link
			usestring = strcat("Hold ", usespace, " to initate link to pad");
			break;
		case 18://no link
			usestring = "Link not active";
			break;
		case 19://finish link
			usestring = strcat("Hold ", usespace, " to link pad with core");
			break;
		case 20://buyable ending
			usestring = strcat("Hold ", usespace, " to End the Game [Cost: ", ftos(useprint_cost), "]");
			break;
		default:
			usestring = "This should not happen you dum fuck"; //yikes
			break;
	}

	print_width = stringwidth (usestring, 0, [0.015*width, 0.015*width, 0]);
	x = (width - print_width)/2;
	drawstring([x, 0.67*height, 0], usestring, [0.015*width, 0.015*width, 0], [1, 1, 1], 1, 0);

	// Draw highlighted usebutton (or button icon in the future)
	if (substring(usestring, 0, 4) == "Hold") {
		button_width = x + stringwidth ("Hold ", 0, [0.015*width, 0.015*width, 0]);
		drawstring([button_width, 0.67*height, 0], usebutton, [0.015*width, 0.015*width, 0], [1, 1, 0], 1, 0);
	}
}

/*******************
*    HUD_Perks     *
*******************/

int perk_order[9];
int current_perk_order;
	
void(float width, float height) HUD_Perks =
{
	
	int i, s;
	int y = height - 100 - 34;
	int x = 2;	
			
	for (i = 0; i < 9; i = i + 1)
	{
		if (perk_order[i])
		{
			if (perk_order[i] == P_JUG)
			{
				drawpic([x,y,0], getImage("jug.tga"), [32, 32, 1], [1,1,1], 1);

				if (G_HUDHOR)
					x += 34;
				else
					y -= 34;
			}
			else if (perk_order[i] == P_DOUBLE)
			{
				drawpic([x,y,0], getImage("double.tga"), [32, 32, 1], [1,1,1], 1);
				if (G_HUDHOR)
					x += 34;
				else
					y -= 34;
			}
			else if (perk_order[i] == P_SPEED)
			{
				drawpic([x,y,0], getImage("speed.tga"), [32, 32, 1], [1,1,1], 1);
				if (G_HUDHOR)
					x += 34;
				else
					y -= 34;
			}
			else if (perk_order[i] == P_REVIVE)
			{
				drawpic([x,y,0], getImage("revive.tga"), [32, 32, 1], [1,1,1], 1);
				if (G_HUDHOR)
					x += 34;
				else
					y -= 34;
			}
			else if (perk_order[i] == P_FLOP)
			{
				drawpic([x,y,0], getImage("flopper.tga"), [32, 32, 1], [1,1,1], 1);
				if (G_HUDHOR)
					x += 34;
				else
					y -= 34;
			}
			else if (perk_order[i] == P_STAMIN)
			{
				drawpic([x,y,0], getImage("stamin.tga"), [32, 32, 1], [1,1,1], 1);
				if (G_HUDHOR)
					x += 34;
				else
					y -= 34;
			}
			else if (perk_order[i] == P_DEAD)
			{
				drawpic([x,y,0], getImage("dead.tga"), [32, 32, 1], [1,1,1], 1);
				if (G_HUDHOR)
					x += 34;
				else
					y -= 34;
			}
			else if (perk_order[i] == P_MULE)
			{
				drawpic([x,y,0], getImage("mule.tga"), [32, 32, 1], [1,1,1], 1);
				if (G_HUDHOR)
					x += 34;
				else
					y -= 34;
			}
		}
	}
}

/*******************
*    HUD Weapons   *
*******************/

void(float width, float height) HUD_Weaponstring =
{
	string weaponstring; 
	float ws_offset;
	
	weaponstring = GetWeaponName(getstatf(STAT_ACTIVEWEAPON));
	ws_offset = (strlen(weaponstring));
		
	drawstring([0.925*width + (40*width/1024) - ws_offset*20*width/1024, 0.75*height + 10, 0], weaponstring, [0.02*width, 0.02*width, 0], [1, 1, 1], 1, 0);
}

/*******************
* HUD Progress Bar *
*******************/

void(float width, float height) HUD_Progressbar =
{
	float percent = getstatf(STAT_PROGRESSBAR);
	if (!percent) {
		return;
	}

	string progress; 
	local float ws_offset;
	
	progress = ftos(percent);
	ws_offset = (strlen(progress) - 1);

	float bar_width = 0.0175*width * 20;
	float bar_height = 0.0175*width;
	float bar_x = (width - bar_width)/2;
	float bar_y = height*0.75;

	drawfill ([bar_x - 1, bar_y - 1, 0], [bar_width+2, bar_height, 0], [0, 0, 0], 0.4, 0);
	drawfill ([bar_x, bar_y, 0], [bar_width * percent, bar_height-2, 0], [1, 1, 1], 0.4, 0);
	
	drawstring([(width - (88))/2, height*0.77 + 10, 0], "Reviving...", [0.0175*width, 0.0175*width, 0], [1, 1, 1], 1, 0); 
}

/*******************
*    HUD Hitmark   *
*******************/

void() HUD_Hitmark =
{
	drawpic([g_width/2 - (8/480)*g_width, g_height/2 - (8/480)*g_width,0], "gfx/hud/hit_marker.tga", [(16/480)*g_width, (16/480)*g_width, 1], [1,1,1], 1);
}

/*******************
*   HUD Crosshair  *
*******************/

float croshhairmoving; // naievil --used t o see if we are moving or not
float cur_spread;
float crosshair_offset_step;
float crosshair_opacity;
vector crosshair_color;

void() Draw_Crosshair =
{
	if (!crosshair_opacity)
		crosshair_opacity = 1;

	if (K_BACKDOWN || K_FORWARDDOWN || K_LEFTDOWN || K_RIGHTDOWN || input_buttons == 2) {
		croshhairmoving = 1;

		crosshair_opacity -= frametime;

		if (crosshair_opacity < 0.5)
			crosshair_opacity = 0.5;
		
		if (cur_spread >= CrossHairMaxSpread(getstatf(STAT_ACTIVEWEAPON), getstatf(STAT_PLAYERSTANCE))) {
			cur_spread = CrossHairMaxSpread(getstatf(STAT_ACTIVEWEAPON), getstatf(STAT_PLAYERSTANCE));
		} else {
			cur_spread += (frametime*80);

		}
	} else {
		croshhairmoving = 0;
		
		if (cur_spread > 0)
			cur_spread -= (frametime*80);
		else 
			cur_spread = 0;

		crosshair_opacity += frametime;

		if (crosshair_opacity > 1)
			crosshair_opacity = 1;
	}

	// Update values to be red if we're facing an enemy
	// FIXME - this should be handled COMPLETELY client side, NOT as a stat.
	if (getstatf(STAT_FACINGENEMY))
		crosshair_color = TEXT_RED;
	else
		crosshair_color = [1, 1, 1];

	if (getstatf(STAT_WEAPONZOOM) == 2 && zoom_2_time < time)
    {
		setmodel(vmodel, "");
		setmodel(v2model, "");
		drawfill('0 0 0',  [g_width/2 - g_height/2, g_height, 0], '0 0 0', 1, 0);
		drawpic([(g_width/2 - g_height/2),0,0], "gfx/hud/scope.tga", [g_height, g_height, 1], [1,1,1], 1);
		drawfill([(g_width/2 + g_height/2),0,0],  [g_width, g_height, 0], '0 0 0', 1, 0);
	}
    
	if (getstatf(STAT_HEALTH) < 11)
		return;
		
	if (crosshair_spread_time > time && crosshair_spread_time)
    {
        cur_spread = cur_spread + 10;
		if (cur_spread >= CrossHairMaxSpread(getstatf(STAT_ACTIVEWEAPON), getstatf(STAT_PLAYERSTANCE)))
			cur_spread = CrossHairMaxSpread(getstatf(STAT_ACTIVEWEAPON), getstatf(STAT_PLAYERSTANCE));
		
		if (!croshhairmoving)
			cur_spread *= 1/2;
    }
    else if (crosshair_spread_time < time && crosshair_spread_time)
    {
        cur_spread = cur_spread - 0.25;
		if (cur_spread <= 0)
		{
			cur_spread = 0;
			crosshair_spread_time = 0;
		}
    }

	if (getstatf(STAT_ACTIVEWEAPON) == W_M2 || getstatf(STAT_ACTIVEWEAPON) == W_TESLA || getstatf(STAT_ACTIVEWEAPON) == W_DG3)
	{
		drawstring([(g_width/2 - g_width*0.0175/2), (g_height/2 - g_height*0.0175/2), 0], "O", [0.0175*g_width, 0.0175*g_width, 0], crosshair_color, 1, 0);
	}
	else if (getstatf(STAT_WEAPONZOOM) != 1 && getstatf(STAT_WEAPONZOOM) != 2 && getstatf(STAT_ACTIVEWEAPON) != W_PANZER && getstatf(STAT_ACTIVEWEAPON) != W_LONGINUS) // naievil (FIXME) crosshair cvar
    {
        int x_value, y_value;
        int crosshair_offset;
        
        crosshair_offset = CrossHairWeapon(getstatf(STAT_ACTIVEWEAPON), getstatf(STAT_PLAYERSTANCE)) + cur_spread;
        
		if (CrossHairMaxSpread(getstatf(STAT_ACTIVEWEAPON), getstatf(STAT_PLAYERSTANCE)) < crosshair_offset)
			crosshair_offset = CrossHairMaxSpread(getstatf(STAT_ACTIVEWEAPON), getstatf(STAT_PLAYERSTANCE));
		
		if (perks & P_DEAD)
			crosshair_offset *= 0.65;

		crosshair_offset_step += (crosshair_offset - crosshair_offset_step) * 0.5;

		// Left
		x_value = g_width/2 - crosshair_offset_step*2;
		y_value = g_height/2;
		drawstring([x_value, y_value, 0], "-", [0.0175*g_width, 0.0175*g_width, 0], crosshair_color, crosshair_opacity, 0); 

		// Right
		x_value = g_width/2 + crosshair_offset_step*2;
		y_value = g_height/2;
		drawstring([x_value, y_value, 0], "-", [0.0175*g_width, 0.0175*g_width, 0], crosshair_color, crosshair_opacity, 0); 

		// Down
		x_value = g_width/2;
		y_value = g_height/2 - crosshair_offset_step*2;
		drawstring([x_value, y_value, 0], "|", [0.0175*g_width, 0.0175*g_width, 0], crosshair_color, crosshair_opacity, 0); 

		// Up
		x_value = g_width/2;
		y_value = g_height/2 + crosshair_offset_step*2;
		drawstring([x_value, y_value, 0], "|", [0.0175*g_width, 0.0175*g_width, 0], crosshair_color, crosshair_opacity, 0); 

    }
    else if (/*crosshair.value && */getstatf(STAT_WEAPONZOOM) != 1 && getstatf(STAT_WEAPONZOOM) != 2) // naievil (FIXME) crosshair cvar
		drawstring([((480 - 8)/2/480)*g_width, ((272 - 8)/2)*(g_height/272), 0], ".", [0.0175*g_width, 0.0175*g_width, 0], [1, 1, 1], 1, 0); 
}

void() HUD_Powerups = {

	if(getstatf(STAT_X2))
		drawpic([(g_width/2 - (28/272)*g_height),0,0], "gfx/hud/2x.tga", [(28/272)*g_height, (28/272)*g_height, 1], [1,1,1], 1);
	if(getstatf(STAT_INSTA))
		drawpic([(g_width/2 + (5/480)*g_width),0,0], "gfx/hud/in_kill.tga", [(28/272)*g_height, (28/272)*g_height, 1], [1,1,1], 1);
}

void() HUD_Broadcast = {

	string broadcast_msg = "";
	float health = getstatf(STAT_HEALTH);
	
		switch(broadcast_type) {
			case 2: broadcast_msg = "A Player needs to be revived"; break;
			default: broadcast_msg = "benis"; break;
		}
	float print_width = stringwidth (broadcast_msg, 0, [0.015*g_width, 0.015*g_width, 0]);
	float x = (g_width - print_width)/2;
	if (broadcast_type == 2 && health > 19)
		drawstring([x, g_height/2, 0], broadcast_msg, [0.015*g_width, 0.015*g_width, 0], [1, 1, 1], 1, 0);
}

void() HUD_Scores =
{
	string subtext = "Name                Kills        Score";
	float xback, i, x;
	vector TEXTCOLOR = [1, 1, 1];
	
	if(serverkey("constate") != "disconnected")
	{
		float print_width = stringwidth(subtext, 0, [0.015*g_width, 0.015*g_width, 0]);
		x = (g_width - print_width)/2;
		drawstring([x,g_height*(5/12), 0], subtext, [0.015*g_width, 0.015*g_width, 0], [1, 1, 1], 1, 0);
	
		xback = x;
	
		for (i = 0; i < 4; i = i + 1)
		{
			if (playerpoints[i] == -1)
				break;
			
			switch(i) {
				case 1: TEXTCOLOR = TEXT_LIGHTBLUE; break;
				case 2: TEXTCOLOR = TEXT_ORANGE; break;
				case 3: TEXTCOLOR = TEXT_GREEN; break;
				default: TEXTCOLOR = [1, 1, 1]; break;
			}
			
			print_width = stringwidth(ftos(playerpoints[i]), 0, [0.015*g_width, 0.015*g_width, 0]);
			x = (g_width + (0.5*g_width) - print_width)/2;
			drawstring([x,g_height*(5.75/12)+(i*g_width*0.03), 0], ftos(playerpoints[i]), [0.015*g_width, 0.015*g_width, 0], TEXTCOLOR, 1, 0);
			drawstring([x/1.36,g_height*(5.75/12)+(i*g_width*0.03), 0], ftos(playerkills[i]), [0.015*g_width, 0.015*g_width, 0], TEXTCOLOR, 1, 0); 
			drawstring([xback,g_height*(5.75/12)+(i*g_width*0.03), 0], playernames[i], [0.015*g_width, 0.015*g_width, 0], TEXTCOLOR, 1, 0); 
		}
	}
}

void() HUD_Endgame = {

	string message = "GAME OVER";
	string rnd = " rounds";

	if (rounds == 1)
		rnd = " round";

	string survive = strcat("You survived ", ftos(rounds), rnd);
	
	// first message
	float print_width = stringwidth(message, 0, [(1/30)*g_width, (1/30)*g_width, 0]);
	float x = (g_width - print_width)/2;
	drawstring([x, g_height*(1/4), 0], message, [(1/30)*g_width, (1/30)*g_width, 0], [1, 1, 1], 1, 0);

	// second message
	print_width = stringwidth(survive, 0, [0.025*g_width, 0.025*g_width, 0]);
	x = (g_width - print_width)/2;
	drawstring([x,g_height*(1/3), 0], survive, [0.025*g_width, 0.025*g_width, 0], [1, 1, 1], 1, 0);
	
	// we can reuse our tab scores for the endgame
	HUD_Scores();
}

float oldfade_alpha;
void() HUD_Fade = 
{  
	float alpha;
	
	if (fade_type == 1) {
		alpha = cos(fade_time - time);
			if (oldfade_alpha > 0.95)
			alpha = 1;
			
			alpha = invertfloat(alpha);
						
		drawfill ([0, 0, 0], [g_width, g_height, 0], [0, 0, 0], alpha, 0);	// background
		oldfade_alpha = alpha;
	}
	else if (fade_type == 2) {
		alpha = sin(((fade_time - time) * 2));
		if (oldfade_alpha > 0.95)
			alpha = 1;
				
		drawfill ([0, 0, 0], [g_width, g_height, 0], [0, 0, 0], alpha, 0);	// background
		oldfade_alpha = alpha;
	}
}

void(float width, float height) HUD_ScrollText = {
	local float print_width = stringwidth (scrolltext, 0, [0.015*width, 0.015*width, 0]);
	local float x = (width - print_width)/2;

	drawstring([x, scrollheight*height, 0], scrolltext, [0.015*width, 0.015*width, 0], [1, 1, 1], scrollopacity, 0); //low
	if (scrollheight > 0.70) {
		scrollheight -= frametime/10;
		if (scrollopacity > 0)
			scrollopacity -= frametime;
	} else {
		stext = 0;
	}
}

float achievement_init;
float achievement_ypos;
float achievement_desc_ypos;
float achievement_img_ypos;
float achievement_time;
void(float width, float height) HUD_Achievements = {
	if (active_achievement == -1)
		return;

	if (!achievement_init) {
		achievement_time 		= 0;
		achievement_ypos 		= -0.16;
		achievement_desc_ypos	= -0.13;
		achievement_img_ypos 	= -0.164;
		achievement_init 		= true;
	}


	drawstring([0.2*width, achievement_ypos*height, 0], "ACHIEVEMENT GET!", [0.015*width, 0.015*width, 0], [1, 1, 0], 1, 0);
	drawstring([0.2*width, achievement_desc_ypos*height, 0], achievements[active_achievement].name, [0.015*width, 0.015*width, 0], [1, 1, 1], 1, 0);
	drawpic([0.005*width, achievement_img_ypos*height,0], achievements[active_achievement].img, [0.16*width, 0.08*width, 0], [1,1,1], 1);

	if (achievement_time <= 120) {
		achievement_ypos 		+= (frametime*0.15);
		achievement_desc_ypos 	+= (frametime*0.15);
		achievement_img_ypos	+= (frametime*0.15);
	} else {
		achievement_ypos 		-= (frametime*0.15);
		achievement_desc_ypos 	-= (frametime*0.15);
		achievement_img_ypos 	-= (frametime*0.15);
		if (achievement_desc_ypos <= -0.13) {
			achievement_init 	= 0;
			active_achievement 	= -1;
		}
	}

	if (achievement_desc_ypos > 0.045) {
		if (achievement_time <= 120) {
			achievement_ypos 		= 0.015;
			achievement_desc_ypos 	= 0.045;
			achievement_img_ypos 	= 0.01;
		}

		achievement_time += (frametime*25);
	}
}

string(float index) GetButtonString =
{
	// place holder
	if (index == 100)
		return "LMOUSE";
	else if (index == 101)
		return "RMOUSE";

	tokenize(findkeysforcommand(buttonBind[index]));
	string temps = strtoupper(keynumtostring(stof(argv(0))));

	return temps;
}

void(float width, float height) HUD_Waypoint =
{
	drawstring([0.015*width, 0.015*height, 0], "WAYPOINT MODE", [0.030*width, 0.030*width, 0], [1, 1, 1], 1, 0);
	drawfill([0.015*width, 0.035*height + height*0.035, 0], [strlen("WAYPOINT MODE")*0.030*width, 0.005*width, 0], [1, 1,1], 1, 0);
	drawstring([0.015*width, 0.095*height, 0], strcat("Press ", GetButtonString(100), " to Create a Waypoint"), [0.015*width, 0.015*width, 0], [1, 1, 1], 1, 0);
	drawstring([0.015*width, 0.125*height, 0], strcat("Press ", GetButtonString(9), " to Select a Waypoint"), [0.015*width, 0.015*width, 0], [1, 1, 1], 1, 0);
	drawstring([0.015*width, 0.155*height, 0], strcat("Press ", GetButtonString(101), " to Link a Waypoint"), [0.015*width, 0.015*width, 0], [1, 1, 1], 1, 0);
	drawstring([0.015*width, 0.185*height, 0], strcat("Press ", GetButtonString(11), " to Remove a Waypoint"), [0.015*width, 0.015*width, 0], [1, 1, 1], 1, 0);
	drawstring([0.015*width, 0.215*height, 0], strcat("Press ", GetButtonString(7), " to Move a Waypoint Here"), [0.015*width, 0.015*width, 0], [1, 1, 1], 1, 0);
	drawstring([0.015*width, 0.245*height, 0], strcat("Press ", GetButtonString(10), " to Create a Special Waypoint"), [0.015*width, 0.015*width, 0], [1, 1, 1], 1, 0);
	drawstring([0.015*width, 0.275*height, 0], strcat("Press ", "=", " to load map waypoints"), [0.015*width, 0.015*width, 0], [1, 1, 1], 1, 0);
	drawstring([0.015*width, 0.305*height, 0], strcat("Press ", "-", " to save current waypoints"), [0.015*width, 0.015*width, 0], [1, 1, 1], 1, 0);
}

/*******************
*     HUD Draw     *
*******************/

void(float width, float height) HUD_Draw = 
{
	if (cvar("cl_cinematic"))
		return;

	HUD_Achievements(width, height);
	
	if (!getstatf(STAT_SPECTATING) && (getstatf(STAT_HEALTH) > 10) && !score_show)
	{
        
        if (vmodel.model == GetWeaponModel(getstatf(STAT_ACTIVEWEAPON), FALSE) && vmodel.model != "" || getstatf(STAT_WEAPONZOOM) == 2)
		    Draw_Crosshair();

		if (!cvar("waypoint_mode")) {
			HUD_Health(width, height);
			HUD_Points(width, height);
			HUD_Rounds(width, height);
			HUD_Perks(width, height);
			HUD_Progressbar(width, height);
			HUD_Powerups();

            if (vmodel.model == GetWeaponModel(getstatf(STAT_ACTIVEWEAPON), FALSE) && vmodel.model != "")
			    HUD_AmmoString();
		
			if (HUD_Change_time > time)
			{
                HUD_Grenades(width, height);

                if (vmodel.model == GetWeaponModel(getstatf(STAT_ACTIVEWEAPON), FALSE) && vmodel.model != "") {
                    HUD_Ammo(width, height);
				    HUD_Weaponstring(width, height);
                }
			}
				
			if (useprint_time > time) 
				HUD_Useprint(width, height);
			
			if (Hitmark_time > time)
				HUD_Hitmark();

			if (stext) {
				HUD_ScrollText(width, height);
			} else {
				scrollopacity = 1;
				scrollheight = 0.80;
			}
		} else {
			HUD_Waypoint(width, height);
		}
	}
	
	// Only keep broadcast messages outside in case they are important
	if (broadcast_time > time)
		HUD_Broadcast();
	
	if (getstatf(STAT_HEALTH) <= 10 && getstatf(STAT_SPECTATING) && !find(world, classname, "ai_zombie"))
		HUD_Endgame();
		
	if (score_show)
		HUD_Scores();
		
	if (fade_time > time)
		HUD_Fade();
}

void UpdatePerks(float newperks) {
	float s;

	// avoids out of bounds err - moto
	if (newperks == 0)
		current_perk_order = 0;

	for(float i = 1; i < 129; i *= 2) {
		if (newperks & i && !(perks & i)) {
			perk_order[current_perk_order] = i;
			current_perk_order += 1;
		}
	}

	for(float i = 1; i < 129; i *= 2) {
		if (perks & i && !(newperks & i)) 
		{
			for(s = 0; s < 8; s++) 
			{
				if (perk_order[s] == i) 
				{
					perk_order[s] = 0;
					while (perk_order[s+1]) 
					{
						perk_order[s] = perk_order[s+1];
						perk_order[s+1] = 0;
					}
					break;
				}
			}
		}
	}
	
	perks = newperks;
}
