//
// nzdparser.qc - parses NZData files for map variety.. yeah, that's a good way to put it.
//

/*
    For what ever reason, this has no affect on PSP.
    The function is called, yet absolotely NOTHING
    in the game changes. FIXME.

	ok moto from 6 months ago i will fix.. later! FIXME
*/

//custom weapon search
void(string weaponFile) nzd_defineweapon = {
	float f, p, l, fnum, wepnum, framenum, fsnd;
	string line;

	line = strcat(strcat("data/maps/", weaponFile), ".cw");
	f = fopen(line, FILE_READ);

	if (f == -1) { //no custom weapons
		return;
	}
	wepnum = currentWeaponTracker - 1;
	p = 0;
	l = 1;

	while(l) {
		string li;
		li = fgets(f);

		if not (li) {
			l = 0;
			break;
		}

		line = strtrim(li);

		if (line == "")
			continue;

		switch(p) {
			case 0:
				wepnum += 1;
				currentWeaponTracker = wepnum;
				if (line == "weapon")
					p = 1;
				break;
			case 1:
				if (line == "{")
					p = 2;
				else
					bprint(PRINT_HIGH, strcat("Error: unknown variable ", strcat(line, " expected {\n")));
				break;
			case 2:
				tokenize(line);

				string v, vari;
				vari = strtrim(argv(0));
				v = strtrim(argv(2));

				switch(vari) {
					case "name":
						CustomWeapons[wepnum].name = v;
						break;
					case "mag":
						CustomWeapons[wepnum].magSize = stof(v);
						break;
					case "reserve":
						CustomWeapons[wepnum].reserveSize = stof(v);
						break;
					case "vmodel":
						CustomWeapons[wepnum].vmodel = v;
						break;
					case "vmodel2":
						CustomWeapons[wepnum].vmodel2 = v;
						break;
					case "gmodel":
						CustomWeapons[wepnum].gmodel = v;
						break;
					case "ads":
						CustomWeapons[wepnum].adsofs = stov(v);
						break;
					case "firetype":
						CustomWeapons[wepnum].firetype = stof(v);
						break;
					case "ispap":
						CustomWeapons[wepnum].ispap = stof(v);
						break;
					case "nonpap":
						CustomWeapons[wepnum].nonpap = stof(v);
						break;
					case "pap":
						CustomWeapons[wepnum].papWpn = stof(v);
						break;
					case "dmg":
						CustomWeapons[wepnum].damage = stof(v);
						break;
					case "shotcount":
						CustomWeapons[wepnum].shotcount = stof(v);
						break;
					case "bodypen":
						CustomWeapons[wepnum].bodypen = stof(v);
						break;
					case "penetration":
						CustomWeapons[wepnum].penetration = stof(v);
						break;
					case "spread":
						CustomWeapons[wepnum].spread = stof(v);
						break;
					case "fdelay":
						CustomWeapons[wepnum].fdelay = stof(v);
						break;
					case "rdelay":
						CustomWeapons[wepnum].rdelay = stof(v);
						break;
					case "walkspeed":
						CustomWeapons[wepnum].walkspeed = stof(v);
						break;
					case "firesound":
						CustomWeapons[wepnum].firesound = v;
						break;
					case "skin":
						CustomWeapons[wepnum].skin = stof(v);
						break;
					case "recoil":
						CustomWeapons[wepnum].recoil = stof(v);
						break;
					case "crossmin":
						CustomWeapons[wepnum].crossmin = stof(v);
						break;
					case "crossmax":
						CustomWeapons[wepnum].crossmax = stof(v);
						break;
					case "lowmag":
						CustomWeapons[wepnum].lowmag = stof(v);
						break;
					case "lowreserve":
						CustomWeapons[wepnum].lowreserve = stof(v);
						break;
					case "flash":
						CustomWeapons[wepnum].flash = stov(v);
						break;
					case "flashsize":
						CustomWeapons[wepnum].flashsize = stof(v);
				}

				#ifdef PC
				/*sendCustomWeapon(wepnum, CustomWeapons[wepnum].name, CustomWeapons[wepnum].magSize, 
				CustomWeapons[wepnum].reserveSize, CustomWeapons[wepnum].vmodel, CustomWeapons[wepnum].vmodel2, 
				CustomWeapons[wepnum].gmodel, CustomWeapons[wepnum].isDual, CustomWeapons[wepnum].firetype, 
				CustomWeapons[wepnum].nonpap, CustomWeapons[wepnum].pap, CustomWeapons[wepnum].ispap, 
				CustomWeapons[wepnum].damage, CustomWeapons[wepnum].shotcount, CustomWeapons[wepnum].bodypen, 
				CustomWeapons[wepnum].penetration, CustomWeapons[wepnum].spread, CustomWeapons[wepnum].fdelay, 
				CustomWeapons[wepnum].rdelay, CustomWeapons[wepnum].walkspeed, CustomWeapons[wepnum].firesound, 
				CustomWeapons[wepnum].skin, CustomWeapons[wepnum].recoil, CustomWeapons[wepnum].crossmin, 
				CustomWeapons[wepnum].crossmax, CustomWeapons[wepnum].lowmag, CustomWeapons[wepnum].lowreserve, 
				CustomWeapons[wepnum].flash, CustomWeapons[wepnum].flashsize, CustomWeapons[wepnum].papWpn, 
				CustomWeapons[wepnum].adsofs);*/
				#endif

				break;
			case 3:
                if (line == "[") {
                    p = 4;
                } else {
                    bprint(PRINT_HIGH, strcat("Error: unknown variable ", strcat(line, " expected [\n")));
                }
                break;
            case 4:
                if (line == "]") {
                    p = 2;
                } else {
					switch(wepnum) {
						/*case 0: W_C1FRAMES[fnum] = stof(line); break;
						case 1: W_C2FRAMES[fnum] = stof(line); break;
						case 2: W_C3FRAMES[fnum] = stof(line); break;
						case 3: W_C4FRAMES[fnum] = stof(line); break;*/
					}
					fnum++;
                }
				break;
			case 5:
                if (line == "[") {
                    p = 6;
                } else {
                    bprint(PRINT_HIGH, strcat("Error: unknown variable ", strcat(line, " expected [\n")));
                }
                break;
            case 6:
                if (line == "]") {
                    p = 2;
                } else {
					switch(wepnum) {
						/*case 0: W_C1XSNDFRAME[framenum] = stof(line); break;
						case 1: W_C2XSNDFRAME[framenum] = stof(line); break;
						case 2: W_C3XSNDFRAME[framenum] = stof(line); break;
						case 3: W_C4XSNDFRAME[framenum] = stof(line); break;*/
					}
					framenum++;
                }
				break;
			case 7:
                if (line == "[") {
                    p = 8;
                } else {
                    bprint(PRINT_HIGH, strcat("Error: unknown variable ", strcat(line, " expected [\n")));
                }
                break;
            case 8:
                if (line == "]") {
                    p = 2;
                } else {
					switch(wepnum) {
						/*case 0: W_C1XTRASND[fsnd] = line; break;
						case 1: W_C2XTRASND[fsnd] = line; break;
						case 2: W_C3XTRASND[fsnd] = line; break;
						case 3: W_C4XTRASND[fsnd] = line; break;*/
					}
					fsnd++;
                }
				break;
		}
	}
	fclose(f);
}

//basically copying the waypoint code.. yikes
void() load_nzd = {

	#ifndef NX
    float file, point;
    string h;
    float loop;
    float wepdata = 0;

    h = strcat(mappath, ".nzd");
	file = fopen (h, FILE_READ);
	
	if (file == -1)
	{
		if (cvar("developer"))
			dprint(".NZD file not found, using default settings..\n");
		return;
	}

    point = 0;
    loop = 1;

    while(loop) {
        string line;
		line = fgets(file);
		if not (line) {
			bprint(PRINT_HIGH, "End of file\n");
			loop = 0;
			break;
		}
		h = strtrim(line);

		//print(h, "\n");
		if (h == "") {
			continue;
		}

		switch (point) {
			case 0:
                //switch-ception!
                switch(h) {
                    case "mech": point = 1; break;
                    default: bprint(PRINT_HIGH, strcat("Error: unknown variable ", strcat(h, "\n")));
                }
				break;
			case 1:
				if (h == "{") {
					point = 2;
				} else {
					bprint(PRINT_HIGH, strcat("Error: unknown variable ", strcat(h, " expected {\n")));
				}
				break;
			case 2:
				tokenize(h);

				string value, variable;
				variable = strtrim(argv(0));
				value = strtrim(argv(2));
				switch (variable) {
					case "proneperkpoints":
						G_PRONEPOINTS = stof(value);
						break;
					case "spawnpoints":
						G_STARTPOINTS = stof(value);
						break;
                    case "round":
                        G_STARTROUND = stof(value);
                        break;
                    case "worldtext":
                        G_WORLDTEXT = stof(value);
                        break;
					case "perkpower":
						G_PERKPOWER = stof(value);
						break;
					case "includeweapon":
						nzd_defineweapon(value);
						break;
                    case "wep":
                        point = 3;
                        break;
					case "perk":
						point = 5;
						break;
                    case "}":
                        loop = 0;
                        break;
					default:
						bprint(PRINT_HIGH, strcat("Error: unknown variable ", strcat(h, " expected }\n")));
						break;
				}
				break;
            case 3:
                if (h == "[") {
                    point = 4;
                } else {
                    bprint(PRINT_HIGH, strcat("Error: unknown variable ", strcat(h, " expected [\n")));
                }
                break;
            case 4:
                if (h == "]") {
                    point = 2;
                } else {
                    G_STARTWEAPON[wepdata] = stof(h);
                    wepdata++;
                }
                break;
			case 5:
				if (h == "[") {
					point = 6;
				} else {
					bprint(PRINT_HIGH, strcat("Error: unknown variable ", strcat(h, " expected [\n")));
				}
				break;
			case 6:
				if (h == "]") {
					point = 2;
				} else {
					G_PERKS = G_PERKS | stof(h);
				}
				break;
		}
	}

	fclose(file);
	#endif
}