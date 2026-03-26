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

#include <sourcemod>
#include <sdktools>
#include <adt_array>
#include <files>

#if !defined(VERSION)
	#define VERSION "unknown"
#endif

public Plugin myinfo = {
	name = "Rat Poison",
	author = "webb <w@spiderden.org>",
	description = "Only allow certain players to spray.",
	version = VERSION,
	url = "https://codeberg.org/spiderden/sp"
}

ArrayList allowedSprayers
bool sprayStatus[MAXPLAYERS]

ConVar enabled

public void OnPluginStart() {
	allowedSprayers = CreateArray(MAX_AUTHID_LENGTH)

	enabled = CreateConVar("sm_ratpoison_enable", "1", "Whether the plugin prevents non-whitelisted players from spraying.", ADMFLAG_ROOT)
	RegServerCmd("sm_ratpoison_reload", cmdReload, "Reloads the whitelist in configs/ratpoison.whitelist.cfg.")
	AddTempEntHook("Player Decal", onPlayerDecal)

	readList()
}

Action cmdReload(int args) {
	readList()
	return Plugin_Handled
}

void readList() {
	allowedSprayers.Clear()

	char path[PLATFORM_MAX_PATH]
	BuildPath(Path_SM, path, sizeof(path), "configs/ratpoison.whitelist.cfg")

	if (!FileExists(path)) {
		PrintToServer("[ratpoison] warning: No configuration file, will treat whitelist as empty.")
		return
	}

	Handle file = OpenFile(path, "r")
	if (file == null) {
		PrintToServer("[ratpoison] error: There was a problem opening the configuration file.")
		return
	}

	char line[MAX_AUTHID_LENGTH]
	while (!IsEndOfFile(file) && ReadFileLine(file, line, sizeof(line))) {
		TrimString(line)
		allowedSprayers.PushString(line)
	}

	applyToConnected()
}

void applyToConnected() {
	int i
	for (i = 1; i < MaxClients; i++) {
		sprayStatus[i] = false
		char id[MAX_AUTHID_LENGTH]
		if (!IsClientConnected(i) || !IsClientAuthorized(i) || IsFakeClient(i) || !GetClientAuthId(i, AuthId_Steam2, id, sizeof(id))) {
			continue
		}

		if (allowedSprayers.FindString(id) != -1) {
			sprayStatus[i] = true
		}
	}
}

public void OnClientAuthorized(int client, const char[] auth) {
	if (allowedSprayers.FindString(auth) != -1) {
		sprayStatus[client] = true
	}
}

public void OnClientDisconnect(int client) {
	sprayStatus[client] = false
}

Action onPlayerDecal(const char[] name, const int[] clients, int count, float delay) {
	if (!enabled.BoolValue) {
		return Plugin_Continue
	}

	int client = TE_ReadNum("m_nPlayer")

	if (!sprayStatus[client]) {
		PrintToChat(client, "[ratpoison] You are not allowed to spray.")
		return Plugin_Stop
	}

	return Plugin_Continue
}
