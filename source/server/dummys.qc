/*
+------+
|Dummys|
+------+-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+
| Scratch                                      Http://www.admdev.com/scratch |
+=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+
| This file contains remove(self); statements for entities not yet coded.    |
| This avoids Quake spewing out pages and pages of error messages when       |
| loading maps.                                                              |
+=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+
*/

// Triggers
void() trigger_relay            = {remove(self);};
void() trigger_changelevel      = {remove(self);};
void() trigger_counter          = {remove(self);};
void() trigger_secret           = {remove(self);};
void() trigger_setskill         = {remove(self);};
void() trigger_monsterjump      = {remove(self);};
void() trigger_onlyregistered   = {remove(self);};
void() trigger_push             = {remove(self);};
void() trigger_hurt             = {remove(self);};
// Player Starts
void() info_player_start        = {};
void() info_player_start2       = {};
void() info_player_deathmatch   = {};
void() info_player_coop         = {};
void() info_player_tank         = {};
void() info_player_nikolai		= {};
void() info_player_doctor		= {};
void() info_player_takeo		= {};

void() zapper1 = {remove(self);};
void() zapper2 = {remove(self);};
void() item_switch = {remove(self);};
void() zap_light = {remove(self);};
void() info_end = {remove(self);};

//// beta removal 
void() monster_dog = {remove(self);};
void() item_pap = {remove(self);};
//void() item_juggernog = {remove(self);};
//void() item_flopper = {remove(self);};
//void() item_douple = {remove(self);};
//void() item_speed = {remove(self);};
//void() item_revive = {remove(self);};
void() palm_tree_closed = {remove(self);};
void() func_model = {remove(self);};
void() wooden_crate = {remove(self);};

void() change_frame;
void() change_frame2 =
{
	self.frame++;
	self.think = change_frame;
	self.nextthink = time + 1;
}
void() change_frame =
{
	self.frame++;
	self.think = change_frame2;
	self.nextthink = time + 1;
}

#ifdef PSP
void LoadWaypointData() = {};
#endif

// Old Demo defs
.float fogdogs;
.float MaxRange;
void() trigger_teleport = {remove(self);};
void() tigger_mainframe = {remove(self);}; //lol this typo is in their old fgd too, apparently.
void() trigger_teleport_area = {remove(self);};