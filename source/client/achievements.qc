/* ================================
    Achievement code by MotoLegacy
   ================================ */

void() Achievement_Init = {
    //define all of the achivements
    activeachievement = -1; //-1 = no achievement to display
    achievementname[0] = "Ready..";
    achievementdesc[0] = "Reach Round 5";
    achievementimg[0] = strcat(achievementdir, "ready.tga");
    achievementname[1] = "Steady..";
    achievementdesc[1] = "Reach Round 10";
    achievementimg[1] = strcat(achievementdir, "steady.tga");
    achievementname[2] = "Go? Hell No...";
    achievementdesc[2] = "Reach Round 15";
    achievementimg[2] = strcat(achievementdir, "go_hell_no.tga");
    achievementname[3] = "Where Did Legs Go?";
    achievementdesc[3] = "Turn a zombie into a crawler";
    achievementimg[3] = strcat(achievementdir, "where_legs_go.tga");
    achievementname[4] = "The F Bomb";
    achievementdesc[4] = "Use the Nuke power-up to kill a single Zombie";
    achievementimg[4] = strcat(achievementdir, "the_f_bomb.tga");

    //unlock the achievements that we already have
    local float file, i;
    local string val;
    file = fopen("ach.dat", FILE_READ);

    if (file == -1) {
        fclose(file);
        file = fopen("ach.dat", FILE_WRITE);

        for (i = 0; i < MAX_ACHIEVEMENTS; i++) {
            fputs(file, "0\n");
        }

        fclose(file);
        file = fopen("ach.dat", FILE_READ);
    }

    for (i = 0; i < MAX_ACHIEVEMENTS; i++) {
        val = fgets(file);
        achievementunlocked[i] = stof(val);
    }

    fclose(file);
}

void(float ach) Unlock_Achievement = {
    local float file, i;

    achievementunlocked[ach] = 1;

    file = fopen("ach.dat", FILE_WRITE);

    for (i = 0; i < MAX_ACHIEVEMENTS; i++) {
        if (achievementunlocked[i])
            fputs(file, "1\n");
        else
            fputs(file, "0\n");
    }

    fclose(file);

    activeachievement = ach;
}
