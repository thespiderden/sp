#include <sourcemod>
#include <tf2c>
#include <sdktools>

public Plugin myinfo =
{
	name = "Class Consciousness",
	author = "webb <w@spiderden.org>",
	description = "A class enforcer.",
	version = "v0.0.0",
	url = "https://codeberg.org/moonspub/sp"
}

char classStr[][]  = {"", "Scout", "Sniper", "Soldier", "Demo", "Medic", "Heavy", "Pyro", "Spy", "Engineer", "Civilian"}
TFClassType classes[6]

ConVar Enabled
ConVar Rolls

public OnPluginStart() {
	Enabled = CreateConVar("sm_cc_enable", "0", "Toggles the enforcement of classes.")
	Enabled.AddChangeHook(onEnabledChange)

	Rolls = CreateConVar("sm_cc_rolls", "1", "Whether or not the plugin re-rolls classes on round change and other situations.")

	// In the case someone has rolls disabled on startup, have a default value.
	rollClasses(true)

	RegServerCmd("sm_cc_change", cmdChangeClass, "Changes the class of a particular team. sm_cc_change <team> <class>")
	RegServerCmd("sm_cc_roll", cmdRoll, "Rolls a new set of classes, bypassing sm_cc_rolls 0.")

	HookEvent("player_spawn", onPlayerSpawn)
	HookEvent("teamplay_round_start", onRoundStart)
}

public Action cmdRoll(int args) {
	if (!Enabled.BoolValue) {
		PrintToServer("[CC] Please enable the plugin if you wish to use sm_cc_roll.")
		return Plugin_Handled
	}

	rollClasses(true)
	updatePlayerClasses()
	printClasses("Re-rolled")
	return Plugin_Handled
}

public Action cmdChangeClass(int args) {
	if (!Enabled.BoolValue) {
		PrintToServer("[CC] Please enable the plugin if you wish to use sm_cc_change.")
		return Plugin_Handled
	}
	if (args != 2) {
		PrintToServer("[CC] Invalid number of arguments for change class.")
		return Plugin_Handled
	}

	char buf[16]
	GetCmdArg(1, buf, sizeof(buf))

	TFTeam target
	if (StrEqual(buf, "red", false)) {
		target = TFTeam_Red
	} else if (StrEqual(buf, "blue", false)) {
		target = TFTeam_Blue
	} else if (StrEqual(buf, "green", false)) {
		target = TFTeam_Green
	} else if (StrEqual(buf, "yellow", false)) {
		target = TFTeam_Yellow
	} else if (StrEqual(buf, "all", false)) {
		target = TFTeam_Unassigned // Magic value later for "all"
	} else {
		PrintToServer("[CC] Invalid team name specified")
		return Plugin_Handled
	}

	buf = ""
	GetCmdArg(2, buf, sizeof(buf))

	TFClassType class
	int i
	for (i = 1; i < sizeof(classStr); i++) {
		if (StrEqual(classStr[i], buf, false)) {
			class = i
			break
		}
	}

	if (class == 0) {
		PrintToServer("[CC] Invalid class name specified.")
		return Plugin_Handled
	}

	if (target != TFTeam_Unassigned) {
		classes[target] = i
		printClasses("Class changed")
	} else {
		// Magic value used here
		classes[TFTeam_Red] = i
		classes[TFTeam_Blue] = i
		classes[TFTeam_Green] = i
		classes[TFTeam_Yellow] = i
		printClasses("Classes changed")
	}

	updatePlayerClasses()

	return Plugin_Handled
}

void onEnabledChange(ConVar cvar, char[] oldv, char[] newv) {
	if (StrEqual(oldv, newv, false)) {
		return
	}

	if (cvar.BoolValue) {
		if (Rolls.BoolValue) {
			rollClasses()
		}
		updatePlayerClasses()
		printClasses("Class restrictions enabled")
	}
}

void printClasses(char[] msg="Classes") {
	PrintToChatAll(
		"[CC] %s: RED %s vs. BLU %s vs. GRN %s vs. YLW %s",
		msg,
		classStr[classes[TFTeam_Red]],
		classStr[classes[TFTeam_Blue]],
		classStr[classes[TFTeam_Green]],
		classStr[classes[TFTeam_Yellow]]
	)
}

void onRoundStart(Event event, char[] name, bool dontBroadcast) {
	rollClasses()
	if (Enabled.BoolValue == true) {
		PrintToChatAll(
			"[CC] New Round: RED %s vs. BLU %s vs. GRN %s vs. YLW %s",
			classStr[classes[TFTeam_Red]],
			classStr[classes[TFTeam_Blue]],
			classStr[classes[TFTeam_Green]],
			classStr[classes[TFTeam_Yellow]]
		)
		updatePlayerClasses()
	}
}

void onPlayerSpawn(Event event, char[] name, bool dontBroadcast) {
	if (Enabled.BoolValue == true) {
		ensureClientClass(GetClientOfUserId(event.GetInt("userid")))
	}
}

void rollClasses(force=false) {
	if (Rolls.BoolValue || force) {
		classes[TFTeam_Blue] = GetRandomInt(1, 10)
		classes[TFTeam_Red] = GetRandomInt(1, 10)
		classes[TFTeam_Green] = GetRandomInt(1, 10)
		classes[TFTeam_Yellow] = GetRandomInt(1, 10)
	}
}

// num=0 means search unlimited entities.
void killClientEntByProp(char[] entName, char[] entPropWithClientNo, int client, num=0) {
	int ent = -1
	int found = 0
	while ((ent = FindEntityByClassname(ent, entName)) != INVALID_ENT_REFERENCE) {
		if (GetEntPropEnt(ent, Prop_Send, entPropWithClientNo) == client) {

			AcceptEntityInput(ent, "Kill")
			found++
			if (num != 0 && found == num) {
				return
			}
		}
	}
}

void updatePlayerClasses() {
	int i
	for (i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || GetClientTeam(i) == TFTeam_Spectator || GetClientTeam(i) == TFTeam_Unassigned || TF2_GetPlayerClass(i) == classes[GetClientTeam(i)]) {
			continue
		}

		switch (TF2_GetPlayerClass(i)) {
			case TFClass_Engineer: {
				killClientEntByProp("obj_dispenser", "m_hBuilder", i, 1)
				killClientEntByProp("obj_teleporter", "m_hBuilder", i, 2)
				killClientEntByProp("obj_sentrygun", "m_hBuilder", i, 1)
				killClientEntByProp("obj_jumppad", "m_hBuilder", i, 2)
			}
			case TFClass_Spy: {
				killClientEntByProp("obj_attachment_sapper", "m_hOwner", i)
			}
			case TFClass_DemoMan: {
				killClientEntByProp("sticky", "m_hThrower", 8)
			}
		}

		TF2_RespawnPlayer(i)
	}
}

void ensureClientClass(int client) {
	TFClassType tclass = classes[TF2_GetClientTeam(client)]
	if (TF2_GetPlayerClass(client) != tclass) {
		TF2_SetPlayerClass(client, tclass, _, true);
		TF2_RespawnPlayer(client)
	}
}
