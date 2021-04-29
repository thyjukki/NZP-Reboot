//
// achievements.qc - main achievement code
//

void(float id, string graphic, string name, string description) Achievement_Create =
{
    if (id >= MAX_ACHIEVEMENTS)
        return;
    
    achievements[id].img = strcat("gfx/achievement/", graphic, ".tga");
    achievements[id].name = name;
    achievements[id].description = description;
}

void() Achievement_Save =
{
    local float file, i;

    // re-write the achievement file
    file = fopen("ach.dat", FILE_WRITE);
    for (i = 0; i < MAX_ACHIEVEMENTS; i++) {
        fputs(file, strcat(ftos(achievements[i].unlocked), "\n"));
        fputs(file, strcat(ftos(achievements[i].progress), "\n"));
    }

    fclose(file);
}

void() Achievement_Load =
{
    float file, i;
    string val;

    file = fopen("ach.dat", FILE_READ);

    if (file == -1) {
        fclose(file);
        file = fopen("ach.dat", FILE_WRITE);

        for (i = 0; i < MAX_ACHIEVEMENTS * 2; i++) {
            fputs(file, "0\n");
        }

        fclose(file);
        file = fopen("ach.dat", FILE_READ);
    }

    for (i = 0; i < MAX_ACHIEVEMENTS; i++) {
        val = fgets(file);
        achievements[i].unlocked = stof(val);
        val = fgets(file);
        achievements[i].progress = stof(val);
    }

    fclose(file);
}

void() Achievement_Init = 
{
    Achievement_Create(0, "ready", "Ready..", "Reach Round 5");
    Achievement_Create(1, "steady", "Steady..", "Reach Round 10");
    Achievement_Create(2, "go_hell_no", "Go? Hell No...", "Reach Round 15");
    Achievement_Create(3, "where_legs_go", "Where Did Legs Go?", "Turn a Zombie into a Crawler");
    Achievement_Create(4, "the_f_bomb", "The F Bomb", "Use the Nuke Power-Up to kill a single Zombie");

    Achievement_Load();

    active_achievement = -1;
}

void(float id) Achievement_Unlock = 
{
    local float file, i;

    achievements[id].unlocked = 1;

    // tell the HUD to start drawing
    active_achievement = id;

    Achievement_Save();
}

void(float id, float pg) Achievement_UpdateProgress =
{
    achievements[id].progress = pg;

    Achievement_Save();
}