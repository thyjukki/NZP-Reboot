//
// sounds.qc - Sound Entities for Maps.
//
#define AMBIENT_SOUND_STATIC			0	// medium radius attenuation
#define AMBIENT_SOUND_EVERYWHERE		1
#define AMBIENT_SOUND_SMALLRADIUS		2
#define AMBIENT_SOUND_MEDIUMRADIUS		4
#define AMBIENT_SOUND_LARGERADIUS		8
#define AMBIENT_SOUND_START_SILENT		16
#define AMBIENT_SOUND_NOT_LOOPING		32

void() ambient_use =
{
	// volume can only be between 0 - 1 in quake (maybe FTE supports higher.. not sure)
	if (self.health > 1)
		self.health = 1;
	
	if (self.team == 1) {
		if (self.spawnflags & AMBIENT_SOUND_NOT_LOOPING) {
			sound(self, CHAN_VOICE, self.message, self.health, self.stance);
			
		}
		else {
			sound(self, CHAN_VOICE, self.message, self.health, self.stance);
			ambientsound(self.origin, self.message, self.health, self.stance);
		}
		self.team = 0;
	}
	else
	{
		if (self.spawnflags & AMBIENT_SOUND_NOT_LOOPING) {
			sound (self, CHAN_VOICE, self.message, 0, self.stance);
		}
		else {
			sound (self, CHAN_VOICE, self.message, 0, self.stance);
			ambientsound (self.origin, self.message, 0, self.stance);
		}
		self.team = 1;
	}

    self.use = SUB_Null;
};

void () ambient_generic =
{
	local string link;

    // moto - FIXME: typically this is set to upper-case but NX and PSP lack strtoupper(); assume lower-case!
    link = self.message;

	if (link == "nolink") {
		if (substring(self.message, 0, 1) == "*")
			self.message = substring(self.message , 1, strlen(self.message));
	
	
		if (substring(self.message , 0, 1) == "!" || substring(self.message , 0, 1) == "*") {
			remove(self);
			return;
		}
		else
			precache_sound(self.message);
	}
	else {
		// append sounds/ if absent
		if (substring(self.message, 0, 7) != "sounds/")
			self.message = strcat("sounds/", self.message);
			
        // always assume .wav extension..
		precache_sound(self.message);
	}

	if (self.spawnflags & AMBIENT_SOUND_SMALLRADIUS)
		self.stance = ATTN_IDLE;
	else if (self.spawnflags & AMBIENT_SOUND_MEDIUMRADIUS)
		self.stance = ATTN_STATIC;
	else if (self.spawnflags & AMBIENT_SOUND_LARGERADIUS)
		self.stance = ATTN_NORM;
	else if (self.spawnflags & AMBIENT_SOUND_EVERYWHERE)
		self.stance = ATTN_NONE;
	else
		self.stance = ATTN_STATIC;

		
	if (self.health == 0)	// final vol
		self.health = 1;
		
	if (self.spawnflags & AMBIENT_SOUND_START_SILENT)
		self.team = 1;
	else
		ambientsound(self.origin, self.message, self.health, self.stance);
		
	self.use = ambient_use;
};


//
// ambient_bgm() conversion
//
void() ambient_bgm =
{
	// play everywhere
	self.spawnflags = 1;
	// sound to loop
	self.message = self.noise2;
	// call ambient_generic()
	ambient_generic();
}