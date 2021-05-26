//
// achievements.qc - main achievement code
//

/*

Thanks to everyone who submitted Achievement ideas in 2019!

- Derped_Crusader
- TheSmashers
- Chyll
- mrFlamist
- mario135790
- Mission
- RedneckHax0r
- Revnova
- EpicFoxx64
- Detwyler_
- DisrespectfulOtter
- xnick2222x
- greg
- Omar Alejandro
- Cosmicrush
- blubs
- Bernerd

*/

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
    Achievement_Create(0,   "ready",                "Ready..",                                      "Reach Round 5");
    Achievement_Create(1,   "steady",               "Steady..",                                     "Reach Round 10");
    Achievement_Create(2,   "go_hell_no",           "Go? Hell No...",                               "Reach Round 15");
    Achievement_Create(3,   "where_legs_go",        "Where Did Legs Go?",                           "Turn a Zombie into a Crawler");
    Achievement_Create(4,   "the_f_bomb",           "The F Bomb",                                   "Use the Nuke Power-Up to kill a     single Zombie");
    Achievement_Create(5,   "no_perks_no_problem",  "No Perks? No Problem",                         "Survive an entire Round without     Perks past Round 15 or higher");
    Achievement_Create(6,   "dipsomaniac",          "Dipsomaniac",                                  "Hold all Perk-A-Colas at once in a  single Game");
    Achievement_Create(7,   "oops",                 "Oops!",                                        "Die from fall damage");
    Achievement_Create(8,   "abstinence_program",   "Abstinence Program",                           "Survive to Round 10 without taking  any enemy damage");
    Achievement_Create(9,   "pro_gamer_move",       "Pro-Gamer Move",                               "Die on Round 1 with no Ammo         remaining");
    Achievement_Create(10,  "spinning_plates",      "Spinning Plates",                              "Keep entry points Barricaded all the way to Round 10");
    Achievement_Create(11,  "unlucky",              "Unlucky",                                      "Have the Mystery Box move 10 times");
    Achievement_Create(12,  "the_collector",        "The Collector",                                "Buy every weapon off the wall in a  single Game");
    Achievement_Create(13,  "barrels_o_fun",        "Barrels o' Fun",                               "In Nacht der Untoten, kill 15       Zombies with Explosive Barrels");
    Achievement_Create(14,  "its_a_trap",           "It's a Trap!",                                 "In Kino der Toten, kill 5 Crawlers  with the use of 1 Trap");
    Achievement_Create(15,  "uplink",               "Up-Link",                                      "In Kino der Toten, teleport to the  Pack-A-Punch 5 times in a single  Game");
    Achievement_Create(16,  "undone",               "Undone",                                       "Survive a total of 150 Rounds on    Nacht der Untoten");
    Achievement_Create(17,  "moviegoer",            "Moviegoer",                                    "Play 10 total Matches on Kino der   Toten");
    Achievement_Create(18,  "cmere_cupcake",        "C'mere, Cupcake!",                             "Kill yourself with your own Grenade");
    Achievement_Create(19,  "orbital_strike",       "Orbital Strike",                               "Kill 5 Zombies at once, with the    Panzerschreck, while in the air");
    Achievement_Create(20,  "long_name",            "A House Divided, Multiplied, then Subtracted", "In Nacht der Untoten, reach Round 10 without going upstairs & without fixing Barriers, then go upstairs & allow those Barriers to be Destroyed");
    Achievement_Create(21,  "colt_hearted_killer",  "Colt-Hearted Killer",                          "Reach Round 10 using only the Colt  M1911");
    Achievement_Create(22,  "cache_and_carry",      "Cannot Cache and Carry",                       "Collected a Max Ammo power-up whilst already being at fully ammo      capacity");
    Achievement_Create(23,  "divide_and_conquer",   "Divide and Conquer",                           "Turn all Zombies into Crawlers in a single Round");
    Achievement_Create(24,  "tough_luck",           "Tough Luck!",                                  "Die before reaching Round 5");
    Achievement_Create(25,  "gregg",                "All Are One with Gregg!",                      "???");
    Achievement_Create(26,  "slasher",              "Slasher",                                      "Perform 100 total Melee kills");
    Achievement_Create(27,  "made_by_children",     "Made by Children",                             "Get a Zombie stuck for 5 minutes");
    Achievement_Create(28,  "increase_firepower",   "Increase your Firepower!",                     "Use the Pack-A-Punch for the first  time");
    Achievement_Create(29,  "kraut_tongue",         "Kraut Got Your Tongue?",                       "Get 25 Headshots");
    Achievement_Create(30,  "mindblowing",          "Mindblowing",                                  "Get 250 Headshots");
    Achievement_Create(31,  "thanks_explosions",    "Big Thanks to Explosions",                     "Kill 10 Zombies with a single       Grenade");
    Achievement_Create(32,  "mbox_maniac",          "Mystery Box Manaic",                           "Use the Mystery Box 20 times in a   single Game");
    Achievement_Create(33,  "instant_help",         "Instant Help",                                 "Get 100 total Kills with the        Insta-Kill Power-Up");
    Achievement_Create(34,  "blow_the_bank",        "Blow the Bank",                                "Earn 1,000,000 Points");
    Achievement_Create(35,  "why_wait",             "..Why Are We Waiting?",                        "Stand Still for 2 minutes");
    Achievement_Create(36,  "one_clip",             "One Clip",                                     "Survive a Round using the MG42 and  without Reloading");
    Achievement_Create(37,  "2021",                 "Twenty-Twenty-One",                            "Land 20 Headshots, with 20 Bullets, with one Clip");
    Achievement_Create(38,  "warmed_up",            "Getting Warmed Up",                            "Earn 10 Achievements");
    Achievement_Create(39,  "half_way",             "About Half-Way",                               "Earn 20 Achievements");
    Achievement_Create(40,  "75_percent",           "I mean.. 75% is Passing",                     "Earn 30 Achievements");
    Achievement_Create(41,  "over_achiever",        "Over-Achiever",                                "Earn all 42 Achievements");

    Achievement_Load();

    achievement_pages = ceil(MAX_ACHIEVEMENTS/3);
    current_achievement_page = 1;

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