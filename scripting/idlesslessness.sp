/*
Copyright (C) 2026 webb

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

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
	kickTolerance = CreateConVar("sm_idlln_kicktolerance", "10", "Number of seconds after being placed in game to check if a player still has no ID to kick. -1 = skip.")

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
