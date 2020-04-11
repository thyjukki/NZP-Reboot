void() ContinueRun =
{
	float startframe;
	float endframe;
	string modelname;
	startframe = GetFrame(self.weapon,SPRINT_START);
	endframe = GetFrame(self.weapon,SPRINT_END);
	if(!startframe && !endframe)
	{
		startframe = GetFrame(self.weapon,SPRINT_IN_END);
		endframe = GetFrame(self.weapon,SPRINT_IN_END);
	}
	if (!self.downed) {
		modelname = GetWeaponModel(self.weapon, 0);
	} else
		modelname = "";
	Set_W_Frame (startframe, endframe, 0, 0, SPRINT, ContinueRun, modelname, false, S_BOTH);
}


void () W2_Frame_Update =
{
	local void temp(optional float t);

// note: call whenever weapon frames are called!

	if (self.anim_weapon2_time > time)
		return; //don't call every frame, if it is the animations will play too fast

	#ifndef PC
	if (self.weapon == W_KAR_SCOPE || self.weapon == W_HEADCRACKER) {
		self.weapon2frame = self.weaponframe;
		return;
	}
	#endif
	
	self.anim_weapon2_time = time + self.weapon2_animduration;

	if (self.weapon2frame != self.weapon2frame_end && !self.anim2_reversed)
	{   // continue an animation
        if (self.anim2_reversed) {
		    self.weapon2frame = self.weapon2frame - 1;
        } else {
		    self.weapon2frame = self.weapon2frame + 1;
        }

		if (self.callfuncat2)
		{
			if (self.weapon2frame == self.callfuncat2)
			{
				if (self.animend2)
				{
					temp = self.animend2;
					self.animend2 = SUB_Null2;
					if (temp)
						temp(S_LEFT);
				}
			}
		}
		PlayWeaponSound(self.weapon, self.weapon2_anim_type, FALSE, self.weapon2frame);
		return;
	}
	else
	{
		self.weapon2frame = self.weapon2frame_end = self.weapon2frame = GetFrame(self.weapon,BASE_FRAME);
		self.new_anim2_stop = FALSE;
		self.weapon2_anim_type = 0;
		self.weapon2_animduration = 0;
		self.callfuncat2 = 0;
		temp = self.animend2;
		self.animend2 = SUB_Null;
		if (temp)
			temp(S_LEFT);
	}
};
void () W_Frame_Update =
{
	local void temp(optional float t);

	// note: call whenever weapon frames are called!
	if (self.anim_weapon_time > time)
		return; //don't call every frame, if it is the animations will play too fast

	W2_Frame_Update();
	
	self.anim_weapon_time = time + self.weapon_animduration;



	if (self.weaponframe != self.weaponframe_end && !self.anim_reversed)
	{   // continue an animation

        if (self.anim_reversed) {
		    self.weaponframe = self.weaponframe - 1;
        } else {
		    self.weaponframe = self.weaponframe + 1;
        }

		if (self.weaponmodel == "models/weapons/kar/v_kar.mdl" && (self.weapon == W_KAR_SCOPE ||  self.weapon == W_HEADCRACKER))
		{
			self.weapon2model = "models/weapons/kar/v_karscope.mdl";
			self.weapon2frame = self.weaponframe;
			//self.weapon2skin = self.weaponskin;
		}
		else if (self.weaponmodel == "progs/VModels/v_knife.mdl" || self.weaponmodel == "models/machines/v_perk.mdl") {
			self.weapon2model = "";
			UpdateV2model(self.weapon2model, 0);
		}

		if (self.callfuncat)
		{
			if (self.weaponframe == self.callfuncat)
			{
				if (self.animend)
				{
					temp = self.animend;
					self.animend = SUB_Null;
					if (temp)
						temp(S_RIGHT);
				}
			}
		}
		PlayWeaponSound(self.weapon, self.weapon_anim_type, FALSE, self.weaponframe);
		return;
	}
	else
	{
		self.weaponframe_end = self.weaponframe = GetFrame(self.weapon,BASE_FRAME);
		self.new_anim_stop = FALSE;
		self.weapon_anim_type = 0;
		self.weapon_animduration = 0;
		self.callfuncat = 0;
		temp = self.animend;
		self.animend = SUB_Null;
		if (temp)
			temp(S_RIGHT);
	}
};

void Set_W_Frame (float startframe, float endframe, float duration, float funccalledin, float animtype, void(optional float t) endanimfunc, string set_model, float dontstartnew, float side) =
{
	float math, reversed;

	if (startframe >= endframe) {
		reversed = true;
	} else {
		reversed = false;
	}
	
	math = 0;
	if (duration) {
		math = duration / (fabs(endframe - startframe) + 1);
	} else {
		math = 0.1;
	}

	if (side == S_RIGHT || side == S_BOTH) {
		self.weaponframe = startframe;
		self.weaponframe_end = endframe;
		self.animend = endanimfunc;
		self.callfuncat = funccalledin;
		self.weapon_anim_type = animtype;
		self.new_anim_stop = dontstartnew;
		self.weapon_animduration = math;
		self.anim_reversed = reversed;
	}
	if (side == S_LEFT || side == S_BOTH) {
		self.weapon2frame = startframe;
		self.weapon2frame_end = endframe;
		self.weapon2_anim_type = animtype;
		self.new_anim2_stop = dontstartnew;
		self.weapon2_animduration = math;
		self.anim2_reversed = reversed;

		if (side != S_BOTH) {
			self.animend2 = endanimfunc;
			self.callfuncat2 = funccalledin;
		}
	}
	
	if (set_model && (startframe != endframe) && !(self.zoom == 2)) { // naievil -- latter used for checkhold 
		if (side == S_LEFT) {
			self.weapon2model = set_model;
			UpdateV2model(self.weapon2model, GetWepSkin(self.weapon));
		} else {
			self.weaponmodel = set_model;
			
			if (set_model != "models/machines/v_perk.mdl")
				UpdateVmodel(self.weaponmodel, GetWepSkin(self.weapon));
			else	
				UpdateVmodel(self.weaponmodel, self.weaponskin);

			
			if (set_model == "progs/VModels/v_nade.mdl" || set_model == "progs/VModels/v_betty.mdl") {
				self.weapon2model = "";
				UpdateV2model(self.weapon2model, 0);
			} else if (self.weapon == W_KAR_SCOPE) {	
				self.weapon2model = "models/weapons/kar/v_karscope.mdl";
				UpdateV2model(self.weapon2model, 0);
			} else if (IsDualWeapon(self.weapon)) {	
				self.weapon2model = GetLeftWeaponModel(self.weapon); 
				UpdateV2model(self.weapon2model, 0);
			}
		}
	}
}