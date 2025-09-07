#include <sourcemod>
#include <tf2c>
#include <sdktools>

#if !defined(VERSION)
	#define VERSION "unknown"
#endif

public Plugin myinfo = {
	name = "Class Consciousness",
	author = "webb <w@spiderden.org>",
	description = "A class enforcer.",
	version = VERSION,
	url = "https://codeberg.org/moonspub/sp"
}

char classStr[][]  = {"", "Scout", "Sniper", "Soldier", "Demo", "Medic", "Heavy", "Pyro", "Spy", "Engineer", "Civilian"}
TFClassType classes[6]

int vips[TFTeam_COUNT]

ConVar Enabled
ConVar Rolls
ConVar Uniroll

Handle sdkEquipCall

public OnPluginStart() {
	Enabled = CreateConVar("sm_cc_enable", "0", "Toggles the enforcement of classes.")
	Enabled.AddChangeHook(onEnabledChange)

	Rolls = CreateConVar("sm_cc_rolls", "1", "Whether or not the plugin re-rolls classes on round change and other situations.")

	Uniroll = CreateConVar("sm_cc_unirolls", "0", "If enabled, rolls a single class for all teams.")

	// In the case someone has rolls disabled on startup, have a default value.
	rollClasses(true)

	RegAdminCmd("sm_cc_change", cmdChangeClass, ADMFLAG_ROOT, "Changes the class of a particular team. sm_cc_change <team> <class>")
	RegAdminCmd("sm_cc_roll", cmdRoll, ADMFLAG_ROOT, "Rolls a new set of classes, bypassing sm_cc_rolls 0.")

	RegConsoleCmd("sm_classes", cmdClasses)

	RegServerCmd("sm_cc_roll", cmdRollServer, "Rolls a new set of classes, bypassing sm_cc_rolls 0.")

	HookEvent("player_spawn", onPlayerSpawn)
	HookEvent("teamplay_round_start", onRoundStart)
	HookEvent("vip_assigned", onVIPAssigned)
	HookEvent("post_inventory_application", onInventoryUpdate)

	GameData gameConf = LoadGameConfigFile("sdktools.games/game.tf2classic")
	if (gameConf == INVALID_HANDLE) {
		SetFailState("[CC] Failed to load TF2C gamedata file! Do you have TF2C Tools installed?")
		return
	}

	StartPrepSDKCall(SDKCall_Player)

	if (!PrepSDKCall_SetFromConf(gameConf, SDKConf_Virtual, "WeaponEquip")) {
		SetFailState("[CC] Failed to load TF2C equip virtual function! Is TF2C Tools up-to-date?")
		return
	}

	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer)

	sdkEquipCall = EndPrepSDKCall()

	if (!currentlyVip()) {
		if (Enabled.BoolValue) {
			printClasses("Plugin loaded")
			updatePlayerClasses()
		}
		return
	}

	// Hack: Because there is no way to get the VIP outside of events, we restart the round
	// to force reassign a VIP.
	SetConVarInt(FindConVar("mp_restartgame"), 1)
}

public OnPluginEnd() {
	// Cleanup so that the VIP is changed back
	if (currentlyVip()) {
		SetConVarInt(FindConVar("mp_restartgame"), 1)
	}
}

public void OnMapStart() {
	for (int i = 0; i < sizeof(vips); i++) {
		vips[i] = 0
	}
}

Action cmdClasses(int client, int args) {
	PrintToChat(client,
		"[CC] RED %s vs. BLU %s vs. GRN %s vs. YLW %s",
		classStr[classes[TFTeam_Red]],
		classStr[classes[TFTeam_Blue]],
		classStr[classes[TFTeam_Green]],
		classStr[classes[TFTeam_Yellow]]
	)
	return Plugin_Handled
}

Action cmdRollServer(int args) {
	return cmdRoll(0, args)
}

Action cmdRoll(int client, int args) {
	if (!Enabled.BoolValue) {
		if (client != 0) {
			PrintToConsole(client, "[CC] Please enable the plugin if you wish to use sm_cc_roll.")
		} else {
			PrintToServer("[CC] Please enable the plugin if you wish to use sm_cc_roll.")
		}
		return Plugin_Handled
	}

	rollClasses(true)
	updatePlayerClasses()
	printClasses("Re-rolled")
	return Plugin_Handled
}

Action cmdChangeClass(int client, int args) {
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
		classes[target] = class
		printClasses("Class changed")
	} else {
		// Magic value used here
		classes[TFTeam_Red] = class
		classes[TFTeam_Blue] = class
		classes[TFTeam_Green] = class
		classes[TFTeam_Yellow] = class
		printClasses("Classes changed")
	}

	updatePlayerClasses()

	return Plugin_Handled
}

void onVIPAssigned(Event event, char[] name, bool dontBroadcoast) {
	int userid = event.GetInt("userid")
	int team = event.GetInt("team")
	int client = GetClientOfUserId(userid)
	vips[team] = client

	return
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

bool currentlyVip() {
	char mapBuf[6]
	GetCurrentMap(mapBuf, sizeof(mapBuf))

	if (StrContains(mapBuf, "vip_") != -1 || StrContains(mapBuf, "vipr_") != -1) {
		return true
	}

	return false
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
		printClasses("New Round")
		updatePlayerClasses()
	}
}

void onPlayerSpawn(Event event, char[] name, bool dontBroadcast) {
	if (!Enabled.BoolValue) {
		return
	}

	int client = GetClientOfUserId(event.GetInt("userid"))
	ensureClientClass(client)
}

void onInventoryUpdate(Event event, char[] name, bool dontBroadcast) {
	if (!Enabled.BoolValue) {
		return
	}

	int client = GetClientOfUserId(event.GetInt("userid"))
	int team = TF2_GetClientTeam(client)

	if (vips[team] != client) {
		return
	}

	if (TF2_GetPlayerClass(client) == TFClass_Civilian) {
//		TF2_AddCondition(client, 122)
		return
	}

	TF2_RemoveAllWeapons(client)

	int umbrella = CreateEntityByName("tf_weapon_umbrella")
	DispatchSpawn(umbrella)
	SDKCall(sdkEquipCall, client, umbrella)

	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", umbrella)
}

void rollClasses(force=false) {
	if (!Rolls.BoolValue && !force) {
		return
	}

	classes[TFTeam_Red] = GetRandomInt(1, 10)
	classes[TFTeam_Blue] = GetRandomInt(1, 10)
	classes[TFTeam_Green] = GetRandomInt(1, 10)
	classes[TFTeam_Yellow] = GetRandomInt(1, 10)

	if (Uniroll.BoolValue) {
		TFClassType class = classes[TFTeam_Red]
		classes[TFTeam_Blue] = class
		classes[TFTeam_Green] = class
		classes[TFTeam_Yellow] = class
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
			case TFClass_DemoMan: {
				killClientEntByProp("sticky", "m_hThrower", i, 8)
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
