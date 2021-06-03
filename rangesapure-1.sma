#include < amxmodx.inc >
#include < amxmisc.inc >
#include < cstrike.inc >
#include < hamsandwich.inc> 
#include < fakemeta.inc >
#include < fun.inc >
#include < adv_vault.inc >
#include < geoip.inc >
#include < jctf.inc >

// estos format se hacen para leer los %s %d %.2f%% 
// MAMAGUEBO :v

new g_plugin[][] = { "Rangos | knifes | hh", "1.0 Beta", "lol.- (YovannyH)" }

new const g_iPrefix[] = "^4Cs-Apure |^1"

new const g_hours[] = { 20, 21, 22, 23, 00, 01, 02, 03, 04, 05, 06, 07 }

new g_playername[MAX_PLAYERS+1][32]
new g_playerauthid[MAX_PLAYERS+1][32]

new g_ranges[MAX_PLAYERS+1]
new g_frags[MAX_PLAYERS+1]
new g_knifes[MAX_PLAYERS+1]

new g_showhud[3]
new gSzTagH[ 33 ][ 32 ], gSzTagM[ 33 ][ 32 ], gMaxPlayers, gGender[33];

new szPAIS[33][46], szIP[33][32];

new bool:g_happyhour

enum _:DATAMOD
{
	RANGES_NAMES[33],
	RANGES_FRAGS
}

enum _:DATAKNIFE
{
	KNIFE_NAME[64],
	KNIFE_VMDL[64],
	KNIFE_PMDL[64],
	Float:KNIFE_DAMAGE,
	KNIFE_RANGES
}
/*guardado*/

enum
{
	GUARD_RANGOS,
	GUARD_FRAGS,
	GUARD_KNIFE,
	GUARD_GENDR,
	CAMPO_MAX
}

new g_iCampo[CAMPO_MAX]
new g_vaultall

/*guardado*/

new const ranges[][_:DATAMOD] =
{
	{ "Ninguno",1 },
	{ "Novato", 50 },
	{ "Principiante",250 },
	{ "Recluta", 1000 },
	{ "Cabo", 2500 },
	{ "Sub-Cabo", 5000 },
	{ "Cabo-Mayor", 10000 },
	{ "Teniente", 15000 },
	{ "Sub-Teniente", 30000 },
	{ "Capitan", 50000 },
	{ "General en Jefe", 100000 },
	{ "Mercenario Asesino", 250000 },
	{ "Global Sentinel", 500000 }
}

/*new const Comandos_RS[ ][ ] = 
{
    "say /rs", "say rs", "say .rs",
    "say_team  /rs", "say_team rs", "say_team .rs",
    "say /resetscore", "say_team /resetscore",
}*/

new const knife[][_:DATAKNIFE] =
{
	{ "Regular", "models/cs_apure/v_regular.mdl", "models/cs_apure/p_regular.mdl", 1.0, 0 },
	//{ "Coil", "models/v_coil.mdl", "models/p_coil.mdl", 3.0, 1 },
	//{ "Kura", "models/v_kura.mdl", "models/p_kura.mdl", 2.5, 3 },
	//{ "Katana Blue Laser", "models/v_katana_blue_laser.mdl", "models/p_katana_blue_laser.mdl", 1.6 },
	//{ "Horse Blue Dragon", "models/v_blue_dragon.mdl", "models/p_blue_dragon.mdl", 1.6 }
}

enum _:__TagData
{ 
	SZTAGH[32],
	SZTAGM[32],
	SZFLAG[2]
};
new const __Tags[][__TagData] =
{
	{ "Fundador" , "Fundadora" , "l" },
	{ "Staff" , "Staff" , "n" },
	{ "Encargado" , "Encargada" , "r" },
	{ "V.I.P" , "V.I.P" , "g" },
	{ "Administrador" ,  "Administradora" , "k" },
	{ "Ayudante",  "Moderadora", "p" }
}

enum (+=100)
{
	TASK_SHOWHUD
}

#define id_SHOWHUD (taskid - TASK_SHOWHUD)
#define TASK_CONNMSJ 4199

public plugin_precache()
{
	for(new i = 0; i < sizeof knife; i++)
	{
		precache_model(knife[i][KNIFE_VMDL]);
		precache_model(knife[i][KNIFE_PMDL]);
	}
}

public plugin_init()
{
	register_plugin(g_plugin[0], g_plugin[1], g_plugin[2])
	
	register_concmd("amx_frags", "cmd_frags", ADMIN_IMMUNITY, "<nombre> <frags>")
	
	register_clcmd("say rs", "reset_score")
	register_clcmd("say /kf", "menu_cuchillos")
	register_clcmd("say /gn", "generoxd")
	register_clcmd("say /menu", "ctf_menu_principal")
	
	register_clcmd( "say" , "clcmdSay" );
	register_clcmd( "say_team" , "clcmdSayTeam" );

	RegisterHam(Ham_Killed, "player", "player_killed_post")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	
	// probando
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	
	gMaxPlayers = get_maxplayers();
	
	g_showhud[0] = CreateHudSyncObj();
	g_showhud[1] = CreateHudSyncObj();
	g_showhud[2] = CreateHudSyncObj();

	g_vaultall = adv_vault_open("all")
	g_iCampo[GUARD_RANGOS] = adv_vault_register_field(g_vaultall, "Rangos")
	g_iCampo[GUARD_FRAGS] = adv_vault_register_field(g_vaultall, "Frags")
	g_iCampo[GUARD_KNIFE] = adv_vault_register_field(g_vaultall, "Knife")
	g_iCampo[GUARD_GENDR] = adv_vault_register_field(g_vaultall, "Genero")
	adv_vault_init(g_vaultall)

}

public plugin_natives()
{
	register_native("Check_Gender", "GenderNative", 1)
}

public GenderNative(id)
{
	return gGender[id]
}

public plugin_cfg()
{
	set_task(0.1, "happy_hour")
}

public ctf_menu_principal(id)
{
	new menuid[128];
	formatex(menuid, charsmax(menuid), "\rCs-Apure | \wCapture The Flag (#1)^n\r* \wJugadores Online: \y%d\d/\y%d", get_playersnum(), get_maxplayers());
	new menu = menu_create(menuid, "handler_ctf_menu_n")
	
	if(is_user_alive(id) && jctf_get_adrenaline(id) >= 100)
		format(menuid, charsmax(menuid), "Usar Adrenlina \y(100%%)")
	else
		format(menuid, charsmax(menuid), "\dUsar Adrenalina")
	menu_additem(menu, menuid)
	
	format(menuid, charsmax(menuid), "Reiniciar Puntuacion")
	menu_additem(menu, menuid)
	
	format(menuid, charsmax(menuid), "Mutear\d/\wSilenciar \d| \wJugador Fastidioso")
	menu_additem(menu, menuid)
	
	format(menuid, charsmax(menuid), "Género\d/\wKnifes \yTienda")
	menu_additem(menu, menuid)
	
	format(menuid, charsmax(menuid), "Tienda de Articulos^n")
	menu_additem(menu, menuid)
	
	if(is_user_admin(id))
		format(menuid, charsmax(menuid), "Panel \d(\yADMINISTRATIVO\d)")
	else
		format(menuid, charsmax(menuid), "Panel \d(\yADMINISTRATIVO\d) \d- \r(SIN ACCESO)")
	menu_additem(menu, menuid)
	
	menu_setprop(menu, MPROP_EXITNAME, "Salir.")
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
	
	return PLUGIN_HANDLED;
}

public handler_ctf_menu_n(id, menu, item)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;

	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}

	switch(item)
	{
		case 0:
		{
			client_cmd(id, "say /adrenaline")
		}
		case 1:
		{
			reset_score(id)
		}
		case 2:
		{
			client_cmd(id, "say /mute")
		}
		case 3:
		{
			menu_aparence(id)
		}
		case 4:
		{
			articulos(id)
		}
		case 5:
		{
			client_cmd(id, "amxmodmenu")
		}
	}
	return PLUGIN_HANDLED;
}

public menu_aparence(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;

	static menuid[512];
	formatex(menuid, charsmax(menuid), "\rCs-Apure | \wGénero/Knifes \y- \wSelecciona el mas adecuado^n\r* \yCs-Apure | Community")
	new menu = menu_create(menuid, "handler_aparence")
	
	format(menuid, charsmax(menuid), "Seleccionar Género \d(\y%s\d)", gGender[id] ? "MUJER" : "HOMBRE")
	menu_additem(menu, menuid)
	
	// le hechas al bruto xd
	format(menuid, charsmax(menuid), "Seleccion de Knife \d(\y%s\d)", knife[g_knifes[id]][KNIFE_NAME])
	menu_additem(menu, menuid)
	
	menu_setprop(menu, MPROP_EXITNAME, "Volver.")
	menu_display(id, menu, 0)
	
	return PLUGIN_HANDLED;
}

public handler_aparence(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		ctf_menu_principal(id)
	}
	switch(item)
	{
		case 0:
		{
			generoxd(id)
		}
		case 1:
		{
			menu_cuchillos(id)
		}
	}
	return PLUGIN_HANDLED;
}

public articulos(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;

	static menuid[512];
	formatex(menuid, charsmax(menuid), "\rCs-Apure | \wTienda de articulos \rESPECIALES^n\r* \yPróximamente mas articulos")
	new menu = menu_create(menuid, "handler_articulos")
	
	format(menuid, charsmax(menuid), "Comprar \yAvalanche \rFrost \d(HIELO) \d(\rA: 55 \y- \rD: 0$)")
	menu_additem(menu, menuid)
	
	format(menuid, charsmax(menuid), "Comprar \yBehemoth \rGranade \d(DESCONCENTRADORA) \d(\rA: 55 \y- \rD: 0$)")
	menu_additem(menu, menuid)
	
	menu_setprop(menu, MPROP_EXITNAME, "Volver.")
	menu_display(id, menu, 0)
	
	return PLUGIN_HANDLED;
}

public handler_articulos(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		ctf_menu_principal(id)
	}
	switch(item)
	{
		case 0:
		{
			client_cmd(id, "say /get2")
		}
		case 1:
		{
			client_cmd(id, "say /get")
		}
	}
	return PLUGIN_HANDLED;
}
	
public generoxd(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;

	static menuid[512];
	
	formatex(menuid, charsmax(menuid), "\rCs-Apure |\w Selecciona tú género^n\r* \yCs-Apure | Community")
	
	new menu = menu_create(menuid, "_generoxd")
	
	format(menuid, charsmax(menuid), "Elige tu genero: \d(\y%s\d)^n", gGender[id] ? "MUJER" : "HOMBRE")
	menu_additem(menu, menuid)
	
	menu_setprop(menu, MPROP_EXITNAME, "Volver.")
	menu_display(id, menu, 0)

	return PLUGIN_HANDLED

}

public _generoxd(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_aparence(id)
	}
	switch(item)
	{
		case 0:
		{
			(gGender[id] =! gGender[id])
			generoxd(id)
			client_print_color(id, print_team_default, "%s Has cambiado tu ^4genero ^1a: ^3%s", g_iPrefix, gGender[id] ? "Mujer" : "Hombre")
			Guardar(id)
		}
	}
	return PLUGIN_HANDLED

}

public client_putinserver(id)
{
	get_user_name(id, g_playername[id], charsmax(g_playername[]))
	get_user_authid(id, g_playerauthid[id], charsmax(g_playerauthid[]))

	client_print_color(id, print_team_default, "%s Puedes reinciar tu puntuación útilizando ^4</resetscore>^1.", g_iPrefix)
	
	g_ranges[id] = 0
	g_frags[id] = 0
	g_knifes[id] = 0
	gGender[id] = 0

	gSzTagH[id][0] = EOS;
	gSzTagM[id][0] = EOS;

	new i;
	for( i = 0 ; i < sizeof __Tags ; ++i )
	{
		if( has_flag( id , __Tags[i][SZFLAG]))
		{
			copy( gSzTagH[id] , 31 , __Tags[i][SZTAGH] );
			copy( gSzTagM[id] , 31 , __Tags[i][SZTAGM] );
			break;
		}
	}

	set_task(1.0, "Mensaje_Connect", id + TASK_CONNMSJ)
	set_task(1.0, "ShowHUD", id + TASK_SHOWHUD,  _, _, "b")

	Cargar(id)
}


public client_infochanged( index )
{
	new oldname[32], newname[32];
	get_user_name( index , oldname, 31 );
	get_user_info( index , "name", newname, 31 );

	if( !equal(oldname, newname))
		copy( g_playername[index], 31, newname );
}

public Mensaje_Connect(id)
{
	id -= TASK_CONNMSJ
	remove_task(id + TASK_CONNMSJ)
	

	if(is_user_admin(id))
	{
		if(gGender[id])
		{
			client_print_color(0, print_team_default, "%s La ^4%s ^3%s ^1Se ha conectado desde: ^4[%s] ^1| ^3[%s] ^1| Rango: ^3[%s]", g_iPrefix, gSzTagM[id], g_playername[id] ,szPAIS[id], get_player_steam(id) ? "STEAM" : "ID_LAN", ranges[g_ranges[id]][RANGES_NAMES])
		}
		else
		{
			client_print_color(0, print_team_default, "%s El ^4%s ^3%s ^1Se ha conectado desde: ^4[%s] ^1| ^3[%s] ^1| Rango: ^3[%s]", g_iPrefix, gSzTagH[id], g_playername[id] ,szPAIS[id], get_player_steam(id) ? "STEAM" : "ID_LAN", ranges[g_ranges[id]][RANGES_NAMES])
		}
	}
	else
	{
		if(gGender[id])
		{
			client_print_color(0, print_team_default, "%s La Jugadora ^3%s ^1Se ha conectado desde: ^4[%s] ^1| ^3[%s] ^1| Rango: ^3[%s]", g_iPrefix, g_playername[id] ,szPAIS[id], get_player_steam(id) ? "STEAM" : "ID_LAN", ranges[g_ranges[id]][RANGES_NAMES])
		}
		else
		{
			client_print_color(0, print_team_default, "%s El Jugador ^3%s ^1Se ha conectado desde: ^4[%s] ^1| ^3[%s] ^1| Rango: ^3[%s]", g_iPrefix, g_playername[id] ,szPAIS[id], get_player_steam(id) ? "STEAM" : "ID_LAN", ranges[g_ranges[id]][RANGES_NAMES])
		}
	}

	get_client_info(id)


	client_cmd(0, "spk buttons/bell1.wav")
}
public client_disconnected(id)
{
	remove_task(id + TASK_SHOWHUD)

	if(task_exists(id))
		remove_task(id)

	if(is_user_admin(id))
	{
		if(gGender[id])
		{
			client_print_color(0, print_team_default, "%s La ^4%s ^3%s ^1Se ha desconectado. ^1| ^4[%s] ^1| ^3[%s] ^1| Rango: ^3[%s]", g_iPrefix, gSzTagM[id], g_playername[id] ,szPAIS[id], get_player_steam(id) ? "STEAM" : "ID_LAN", ranges[g_ranges[id]][RANGES_NAMES])
		}
		else
		{
			client_print_color(0, print_team_default, "%s El ^4%s ^3%s ^1Se ha desconectado. ^1| ^4[%s] ^1| ^3[%s] ^1| Rango: ^3[%s]", g_iPrefix, gSzTagH[id], g_playername[id] ,szPAIS[id], get_player_steam(id) ? "STEAM" : "ID_LAN", ranges[g_ranges[id]][RANGES_NAMES])
		}
	}
	else
	{
		if(gGender[id])
		{
			client_print_color(0, print_team_default, "%s La Jugadora ^3%s ^1Se ha desconectado. ^1| ^4[%s] ^1| ^3[%s] ^1| Rango: ^3[%s]", g_iPrefix, g_playername[id] ,szPAIS[id], get_player_steam(id) ? "STEAM" : "ID_LAN", ranges[g_ranges[id]][RANGES_NAMES])
		}
		else
		{
			client_print_color(0, print_team_default, "%s El Jugador ^3%s ^1Se ha desconectado. ^1| ^4[%s] ^1| ^3[%s] ^1| Rango: ^3[%s]", g_iPrefix, g_playername[id] ,szPAIS[id], get_player_steam(id) ? "STEAM" : "ID_LAN", ranges[g_ranges[id]][RANGES_NAMES])
		}
	}

	get_client_info(id)
	client_cmd(0, "spk fvox/blip.wav")
	Guardar(id)

}

public player_killed_post(victim, attacker)
{
	if(attacker == victim || !is_user_connected(victim) || !is_user_connected(attacker))
		return;

	if(is_user_admin(attacker))
	{
		if(g_happyhour)
		{
			check_range_levelup(attacker, 4)
		}
		else
		{
			check_range_levelup(attacker, 2)
		}
	}
	else
	{
		if(g_happyhour)
		{
			check_range_levelup(attacker, 2)
		}
		else 
		{
			check_range_levelup(attacker, 1)
		}
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(attacker == victim || !is_user_connected(victim) || !is_user_connected(attacker))
		return HAM_IGNORED;
		
	if(get_user_weapon(attacker) == CSW_KNIFE)
	{
		SetHamParamFloat(4, Float:damage * knife[g_knifes[attacker]][KNIFE_DAMAGE])
		return HAM_IGNORED;
	}
	
	return HAM_IGNORED;
}

public check_range_levelup(id, frags)
{
	g_frags[id] += frags
	
	set_hudmessage(0, 255, -1, 0.5, 0.3, 0, 6.0, 1.1, 0.0, 0.0)
	ShowSyncHudMsg(id, g_showhud[2], "+%d Frag(s)", frags)
	
	new range_levelup = false

	while(g_frags[id] >= ranges[g_ranges[id]][RANGES_FRAGS])
	{
		g_ranges[id]++
		range_levelup = true
	}

	if(range_levelup)
	{
		if(gGender[id])
		{
			client_print_color(0, print_team_red, "%s La ^3Jugadora ^4%s ^1acaba de subir su ^3rango ^1a: ^4%s", g_iPrefix, g_playername[id], ranges[g_ranges[id]][RANGES_NAMES])
			show_screenfade(id, 150, 0, 0)
		}
		else
		{
			client_print_color(0, print_team_blue, "%s El ^3Jugador ^4%s ^1acaba de subir su ^3rango ^1a: ^4%s", g_iPrefix, g_playername[id], ranges[g_ranges[id]][RANGES_NAMES])
			show_screenfade(id, 0, 150, 0)
		}
	}
}

public ShowHUD(taskid)
{
	new id = id_SHOWHUD;
	
	if(!is_user_alive(id)) id = pev(id, pev_iuser2)
	
	if(id != id_SHOWHUD)
	{
		set_hudmessage(255, 255, 255, 0.02, 0.17, 0, 6.0, 1.1, 0.0, 0.0)
		ShowSyncHudMsg(id_SHOWHUD, g_showhud[1], "")
	}
	else
	{
		new Float:porcentage = (g_frags[id_SHOWHUD] * 100.0)/ranges[g_ranges[id_SHOWHUD]][RANGES_FRAGS]
		set_hudmessage(255, 255, 255, 0.02, 0.17, 0, 6.0, 1.1, 0.0, 0.0)
		ShowSyncHudMsg(id_SHOWHUD, g_showhud[0], "| Rango: %s |^n| Frags: %d/%d (%.2f%%) |^n| Hora Feliz: %sctivado|", ranges[g_ranges[id_SHOWHUD]][RANGES_NAMES], g_frags[id_SHOWHUD], (ranges[g_ranges[id_SHOWHUD]][RANGES_FRAGS]), porcentage, g_happyhour ? "A" : "Desa")
	}
}

public happy_hour()
{
	new time_data[12]
	get_time("%H", time_data, 12)

	new g_time = str_to_num(time_data)
 
	// Time function
	for(new i = 0; i <= sizeof(g_hours)- 1; i++)
	{	
		// Hour isn't the same?
		if(g_time != g_hours[i]) continue;
		
		// Enable happy time
		g_happyhour = true
		
		break;
	}
}

public menu_cuchillos(id)
{
	new menu, menuid[50]
	menu = menu_create("\rCs-Apure | \wSelecciona tú cuchillo^n\r* \yNOTA: \wLos \yCuchillos se desbloquean por \rRANGO\w.", "handler_menu_cuchillos")
	
	for(new i = 0; i < sizeof knife; i++)
	{
		if(g_knifes[id] == i)
			format(menuid, charsmax(menuid), "%s \d(\yACTUAL\d)", knife[i][KNIFE_NAME])
		else if(g_ranges[id] < knife[i][KNIFE_RANGES])
			format(menuid, charsmax(menuid), "%s \r| \wRango Necesario: \d(\y%s\d)", knife[i][KNIFE_NAME], ranges[knife[i][KNIFE_RANGES]][RANGES_NAMES])
		else
			format(menuid, charsmax(menuid), "%s", knife[i][KNIFE_NAME])
			
		menu_additem(menu, menuid, "");
	}
	
	menu_display(id, menu);
}

public reset_score(id)
{
    new mu = get_user_deaths(id)
    new ki = get_user_frags(id)
    
    if(mu == 0 && ki == 0)
    {
    	
        //client_print_color(id, print_team_default, "%s No puedes reiniciar tu puntuacion. Todo ya en^3 0-0.",prefix);
        client_print_color(id, print_team_default, "%s ¡No puedes reiniciar tú puntuación! ya es^3 0-0.", g_iPrefix)
        return PLUGIN_HANDLED;
    }
    else
    {
        cs_set_user_deaths(id, 0)
        set_user_frags(id, 0)
        cs_set_user_deaths(id, 0)
        set_user_frags(id, 0)
        if(gGender[id])
        {
        	client_print_color(id, print_team_red, "%s ¡La ^3Jugadora ^4%s ^1ha reiniciado sú ^4puntuación^1!", g_iPrefix, g_playername[id])

        }
        else 
        {
        	client_print_color(id, print_team_blue, "%s ¡El ^3Jugador ^4%s ^1ha reiniciado sú ^4puntuación^1!", g_iPrefix, g_playername[id])
        }
    }
    return PLUGIN_HANDLED;
}

public handler_menu_cuchillos(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	if(g_ranges[id] < knife[item][KNIFE_RANGES])
	{
		client_print_color(id, print_team_default, "%s ^1Necesitas ser ^3rango: ^4%s ^1para usar el ^3cuchillo: ^4%s", g_iPrefix, ranges[knife[item][KNIFE_RANGES]][RANGES_NAMES], knife[item][KNIFE_NAME])
		return PLUGIN_HANDLED;
	}
	
	if(g_knifes[id] == item)
	{
		client_print_color(id, print_team_default, "%s ^1Ya estas utilizando el ^3cuchillo: ^4%s", g_iPrefix, knife[item][KNIFE_NAME])
		return PLUGIN_HANDLED;
	}
	
	g_knifes[id] = item
	client_print_color(id, print_team_default, "%s ^1Has elegido el ^3cuchillo: ^4%s", g_iPrefix, knife[item][KNIFE_NAME])
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public get_player_steam(id)
{
	if(contain(g_playerauthid[id], "STEAM_0:") != -1)
		return true;
	
	return false;
}

public cmd_frags(id, frags, cid)
{
    if (!cmd_access(id, frags, cid, 3))
        return PLUGIN_HANDLED;
        
    new arg[33], arg2[10]
    read_argv(1, arg, charsmax(arg))
    read_argv(2, arg2, charsmax(arg2))
    
    new Player = cmd_target(id, arg,CMDTARGET_ONLY_ALIVE)
    
    if (!Player)
    {
        client_print(id, print_console, "Player no encontrado.")
        return PLUGIN_HANDLED;
    }
    
    //g_frags[Player] += str_to_num(arg2) // yo puse g_level , no se como lo tendras tu.
    check_range_levelup(Player, str_to_num(arg2))
    
    return PLUGIN_HANDLED;
}

public show_screenfade(id, red, green, blue)
{
	// Screen fading
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id)
	write_short(1<<10)
	write_short(1<<10)
	write_short(0x0000)
	write_byte(red) // rrr
	write_byte(green) // ggg
	write_byte(blue) // bbb
	write_byte(75)
	message_end()
}

/***********PREFIX****************/
public clcmdSay(index)
{
	static said[191]; read_args(said, 190); remove_quotes(said); replace_all(said, 190, "%", ""); replace_all(said, 190, "#", "");
	/*
	static Stats1[8], Stats2[8], Posicion;
	Posicion = get_user_stats(index, Stats1, Stats2);
	*/	
	if (!ValidMessage(said, 1)) return PLUGIN_CONTINUE;

	static color[11], prefix[128]; get_user_team(index, color, 10);
	
	if(is_user_admin(index))
	{
		if(gGender[index])
		{
			formatex(prefix, 127, "%s^x03[^x04*%s*^x03][^x04%s^x03] %s", is_user_alive(index)?"^x01":"^x01*MUERTO* ", gSzTagM[index], ranges[g_ranges[index]][RANGES_NAMES], g_playername[index]);
		}
		else
		{
			formatex(prefix, 127, "%s^x03[^x04*%s*^x03][^x04%s^x03] %s", is_user_alive(index)?"^x01":"^x01*MUERTO* ", gSzTagH[index], ranges[g_ranges[index]][RANGES_NAMES], g_playername[index]);
		}
	}
	else
	{
		if(gGender[index])
		{
			formatex(prefix, 127, "%s^x03[^x04*Jugadora*^x03][^x04%s^x03] %s", is_user_alive(index)?"^x01":"^x01*MUERTO* ", ranges[g_ranges[index]][RANGES_NAMES], g_playername[index]);
		}
		else
		{
			formatex(prefix, 127, "%s^x03[^x04*Jugador*^x03][^x04%s^x03] %s", is_user_alive(index)?"^x01":"^x01*MUERTO* ", ranges[g_ranges[index]][RANGES_NAMES], g_playername[index]);
		}
	}

	if (is_user_admin(index)) format(said, charsmax(said), "^x04%s", said);

	format(said, charsmax(said), "%s^x01 : %s", prefix, said);
	

	static i, team[11];

	for (i = 1; i <= gMaxPlayers; ++i)
	{
		if (!is_user_connected(i)) continue;

		get_user_team(i, team, 10);
		changeTeamInfo(i, color);
		writeMessage(i, said);
		changeTeamInfo(i, team);
	}
    
	return PLUGIN_HANDLED_MAIN;
}

public clcmdSayTeam( index )
{
	static said[191]; read_args(said, 190); remove_quotes(said); replace_all(said, 190, "%", ""); replace_all(said, 190, "#", "");
	/*
	static Stats1[8], Stats2[8], Posicion;
	Posicion = get_user_stats(index, Stats1, Stats2);
	*/
	if (!ValidMessage(said, 1)) return PLUGIN_CONTINUE;

	static playerTeam, playerTeamName[20]; playerTeam = get_user_team(index);

	switch (playerTeam)
	{
		case 1: formatex( playerTeamName, 19, "^x01(^x03 TT^x01 ) " );
		case 2: formatex( playerTeamName, 19, "^x01(^x03 CT^x01 ) " );
		default: formatex( playerTeamName, 19, "^x01(^x03 SPEC^x01 ) " );
	}

	static color[11], prefix[128]; get_user_team(index, color, 10);

	if(is_user_admin(index))
	{
		if(gGender[index])
		{
			formatex(prefix, 127, "%s%s^x04[*%s*][%s]^x03 %s", is_user_alive(index)?"^x01":"^x01*MUERTO* ", playerTeamName, gSzTagM[index], ranges[g_ranges[index]][RANGES_NAMES], g_playername[index]);
		}
		else
		{
			formatex(prefix, 127, "%s%s^x04[*%s*][%s]^x03 %s", is_user_alive(index)?"^x01":"^x01*MUERTO* ", playerTeamName, gSzTagH[index], ranges[g_ranges[index]][RANGES_NAMES], g_playername[index]);
		}

	}
	else
	{
		if(gGender[index])
		{
			formatex(prefix, 127, "%s%s^x04[*Jugadora*][%s]^x03 %s", is_user_alive(index)?"^x01":"^x01*MUERTO* ", playerTeamName, ranges[g_ranges[index]][RANGES_NAMES], g_playername[index]);
		}
		else
		{
			formatex(prefix, 127, "%s%s^x04[*Jugador*][%s]^x03 %s", is_user_alive(index)?"^x01":"^x01*MUERTO* ", playerTeamName, ranges[g_ranges[index]][RANGES_NAMES], g_playername[index]);
		}
	}
	
	
	if (is_user_admin(index))
	{
		format(said, charsmax(said), "^x04%s", said);
		format(said, charsmax(said), "%s^x01 : %s", prefix, said);
	}
	else
	{
		format(said, charsmax(said), "^x04%s", said);
		format(said, charsmax(said), "%s^x01 : %s", prefix, said);
	}
	static i, team[11];
	for (i = 1; i <= gMaxPlayers; ++i)
	{
		if (!is_user_connected(i) || get_user_team(i) != playerTeam) continue;

		get_user_team(i, team, 10);
		changeTeamInfo(i, color);
		writeMessage(i, said);
		changeTeamInfo(i, team);
	}	

	return PLUGIN_HANDLED_MAIN;
}

stock ValidMessage(text[], maxcount) 
{
	static len, i, count;
	len = strlen(text);
	count = 0;

	if (!len) return false;

	for (i = 0; i < len; ++i) 
	{
		if (text[i] != ' ') 
		{
			++count;
			
			if (count >= maxcount)
				return true;
		}
	}

	return false;
}

public changeTeamInfo(player, team[])
{
	static msgteamInfo;
	if( !msgteamInfo ) msgteamInfo = get_user_msgid( "TeamInfo" );

	message_begin(MSG_ONE, msgteamInfo, _, player);
	write_byte(player);
	write_string(team);
	message_end();
}

public writeMessage(player, message[])
{
	static msgSayText;
	if( !msgSayText ) msgSayText = get_user_msgid( "SayText" );

	message_begin(MSG_ONE, msgSayText, {0, 0, 0}, player);
	write_byte(player);
	write_string(message);
	message_end();
}
stock get_weapon_ent_owner(ent)
{
    if (pev_valid(ent) != 2)
        return -1;
    
    return get_pdata_cbase(ent, 41, 4);
}


Guardar(id)
{
	adv_vault_set_start(g_vaultall)
	
	adv_vault_set_field(g_vaultall, g_iCampo[GUARD_RANGOS], g_ranges[id])
	adv_vault_set_field(g_vaultall, g_iCampo[GUARD_FRAGS], g_frags[id])
	adv_vault_set_field(g_vaultall, g_iCampo[GUARD_KNIFE], g_knifes[id])
	adv_vault_set_field(g_vaultall, g_iCampo[GUARD_GENDR], gGender[id])
	
	adv_vault_set_end(g_vaultall, 0, g_playername[id])
}


Cargar(id)
{
	if(!adv_vault_get_prepare(g_vaultall, _, g_playername[id]))
		return;
		
	g_ranges[id] = adv_vault_get_field(g_vaultall, g_iCampo[GUARD_RANGOS])
	g_frags[id] = adv_vault_get_field(g_vaultall, g_iCampo[GUARD_FRAGS])
	g_knifes[id] = adv_vault_get_field(g_vaultall, g_iCampo[GUARD_KNIFE])
	gGender[id] = adv_vault_get_field(g_vaultall, g_iCampo[GUARD_GENDR])
	
}

stock get_client_info(id)
{    
	get_user_ip(id, szIP[id], 31);
	geoip_country_ex(szIP[id], szPAIS[id], charsmax(szPAIS[]), -1);
 
	if(equal(szPAIS[id], "Error"))
	{

		if(contain(szIP[id],"192.168.") == 0 || contain(szIP[id],"127.0.0.1") == 0 || contain(szIP[id],"10.") == 0 ||  contain(szIP[id],"172.") == 0)
		{
			szPAIS[id] = "LAN";
		}
		if(equal(szIP[id],"loopback"))
		{
			szPAIS[id] = "ListenServer User";
		}
		else
		{
			szPAIS[id] = "País Desconocido";
		}
	}
}

public CurrentWeapon(id)
{
	if(get_user_weapon(id) == CSW_KNIFE)
	{
		if(g_knifes[id] == knife[id][KNIFE_RANGES])
		{
			set_pev(id, pev_viewmodel2, knife[id][KNIFE_VMDL])
			set_pev(id, pev_weaponmodel2, knife[id][KNIFE_PMDL])
		}
	}
}

// Ham Player Use Stationary Post
public fw_UseStationary_Post(entity, caller, activator, use_type)
{	
	// Player disconnected?
	if (!is_user_connected(caller)) return;

	// Usnig the knife
	if (use_type == 0) 
		CurrentWeapon(caller)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang8202\\ f0\\ fs16 \n\\ par }
*/
