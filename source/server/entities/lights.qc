
/*
+------+
|Lights|
+------+-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+
| Scratch                                      Http://www.admdev.com/scratch |
+=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+
| Spawns and handles Quake's lights and torches                              |
+=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+
*/

float START_OFF = 1;                            // Light on/off spawnflag
void() Light_setup;                             // Definition from Lights.qc

void(string modelname) Precache_Set = // Precache model, and set myself to it
{
    precache_model(modelname);
    setmodel(self, modelname);
};


void() light =                       // Basic Light
{
    Light_setup();                          // Setup Light
}

void() light_fluoro =                // Light with hum ambient
{
    Light_setup();                          // Setup Light
};

void() light_environment =                       // Basic Light
{
    makestatic(self);                       // Static entity. Never changes.
}

void() light_fluorospark =           // Light with buzz ambient
{
    Light_setup();                          // Setup Light
}; 

void() light_globe =                 // Light with visible globe
{
    Precache_Set("progs/s_light.spr");      // Set model
    makestatic(self);                       // Static entity. Never changes.
}

void() light_torch_small_walltorch = // Light with visible wall torch
{
    Precache_Set("progs/flame.mdl");        // Set model
    makestatic(self);                       // Static entity. Never changes.
};
                                      
void() light_flame_small_yellow =    // Light with small flame & fire sound
{                                        
    Precache_Set("progs/flame2.mdl");       // Set model
    makestatic(self);                       // Static entity. Never changes.
};

void() light_flame_large_yellow =    // Light with larger flame & fire sound
{
    Precache_Set("progs/flame2.mdl");       // Set model
    self.frame = 1;                         // Switch to second frame (large)
    makestatic(self);                       // Static entity. Never changes.
};

void() light_flame_small_white =     // Light with small flame & fire sound
{
    Precache_Set("progs/flame2.mdl");       // Set model
    makestatic(self);                       // Static entity. Never changes.
}; 
                       
void() Light_setup =   // Set light on or off, as per spawnflags
{
    if (self.style < 32) {
        return;
    } // Dont switch other styles.

    if (self.spawnflags & START_OFF)  
        lightstyle(self.style, "a");    // If light starts off, set it off.
    else
        lightstyle(self.style, "m");    // If light starts ON, turn in ON. Simple :)
}

void() LightStyles_setup =
{
    // Setup light animation tables. 'a' is total darkness, 'z' is maxbright.

    lightstyle(0,"m");                                   // Style 0: Normal
    lightstyle(1,"mmnmmommommnonmmonqnmmo");             // Style 1: Flicker
    lightstyle(2,"abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba"); // Style 2: Slow Strong Pulse
    lightstyle(3,"mmmmmaaaaammmmmaaaaaabcdefgabcdefg");  // Style 3: Candle
    lightstyle(4,"mamamamamama");                        // Style 4: Fast Strobe
    lightstyle(5,"jklmnopqrstuvwxyzyxwvutsrqponmlkj");    // Style 5: Gentle Pulse
    lightstyle(6,"nmonqnmomnmomomno");                   // Style 6: Flicker 2
    lightstyle(7,"mmmaaaabcdefgmmmmaaaammmaamm");        // Style 7: Candle 2
    lightstyle(8,"mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa");  // Style 8: Candle 3
    lightstyle(9,"aaaaaaaazzzzzzzz");                    // Style 9: Slow Strobe
    lightstyle(10,"mmamammmmammamamaaamammma");          // Style 10: Fluro
    lightstyle(11,"abcdefghijklmnopqrrqponmlkjihgfedcba"); // Style 11: Slow Pulse (no black)
};
  