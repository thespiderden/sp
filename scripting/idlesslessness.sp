#include <sdktools>
#include <sourcemod>

#if !defined(VERSION)
	#define VERSION "unknown"
#endif

public Plugin myinfo = {
	name = "IDlesslessness",
	author = "webb <w@spiderden.org>",
	description = "To be without without an ID.",
	version = VERSION,
	url = "https://codeberg.org/spiderden/sp"
}

ConVar kickTolerance

public void OnPluginStart() {
	kickTolerance = CreateConVar("sm_idlln_kicktolerance", "5", "Number of seconds after being placed in game to check if a player still has no ID to kick. -1 = skip.")

	RegAdminCmd("sm_kickidless", cmdKickIDless, Admin_Kick)
	RegServerCmd("sm_kickidless", srvCmdKickIDless)

	AddTempEntHook("Player Decal", onPlayerDecal)
}

Action cmdKickIDless(int client, int args) {
	kickAllIDLess()
	return Plugin_Handled
}

Action srvCmdKickIDless(int args) {
	kickAllIDLess()
	return Plugin_Handled
}

void kickAllIDLess() {
	int i
	for (i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || IsFakeClient(i)) {
			continue
		}

		if (!IsClientAuthorized(i)) {
			KickClient(i, "[idlln] Kicked due to no authentication with Steam.")
		}
	}
}

public void OnClientPutInServer(int client) {
	if (IsClientAuthorized(client)) {
		return
	}

	float time = kickTolerance.FloatValue
	if (time < 0) {
		return
	}
	if (time == 0) {
		if (!IsClientAuthorized(client)) {
			KickClient(client, "[idlln] Kicked due to no authentication with Steam.")
		}
		return
	}

	CreateTimer(time, recheckPlayer, GetClientSerial(client))
}

Action recheckPlayer(Handle timer, int serial) {
	int client = GetClientFromSerial(serial)
	if (client == 0) {
		return Plugin_Stop
	}

	if (!IsClientAuthorized(client)) {
		KickClient(client, "[idlln] Kicked due to losing authentication with Steam.")
	}

	return Plugin_Stop
}

Action onPlayerDecal(const char[] name, const int[] clients, int count, float delay) {
	int client = TE_ReadNum("m_nPlayer")

	if (!IsClientAuthorized(client)) {
		PrintToChat(client, "[idlln] You may not spray as you are not authenticated with Steam.")
		return Plugin_Stop
	}

	return Plugin_Continue
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs) {
	if (!IsClientAuthorized(client)) {
		PrintToChat(client, "[idlln] You may not chat as you are not authenticated with Steam.")
		return Plugin_Stop
	}
}
