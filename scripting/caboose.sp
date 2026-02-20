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

#if !defined(VERSION)
	#define VERSION "unknown"
#endif

public Plugin myinfo = {
	name = "Admin Caboose",
	author = "webb <w@spiderden.org>",
	description = "A plugin with miscellanious tools for admins.",
	version = VERSION,
	url = "https://codeberg.org/spiderden/sp"
}

public OnPluginStart() {
	RegAdminCmd("sm_uid", cmdUID, ADMFLAG_KICK, "Gets the Steam ID of one or more players in a standard format.")
	RegAdminCmd("sm_steamhistory", cmdHistory, ADMFLAG_KICK, "Gets the steamhistory.net URL of one or more players.")
}

Action cmdHistory(int client, int args) {
	return _cmdID(client, args, true)
}

Action cmdUID(int client, int args) {
	return _cmdID(client, args)
}

Action _cmdID(int client, int args, steamHistory=false) {
	char targetBuf[MAX_TARGET_LENGTH]
	GetCmdArg(1, targetBuf, sizeof(targetBuf))

	int targets[MAXPLAYERS]
	char target[MAX_TARGET_LENGTH]
	bool tnIsMl

	int found = ProcessTargetString(targetBuf, client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS, target, sizeof(target), tnIsMl)
	if (found == 0) {
		PrintToChat(client, "[Caboose] Couldn't find target.")
		return Plugin_Handled
	}
	if (found > 1) {
		PrintToChat(client, "[Caboose] Multiple targets found.")
		return Plugin_Handled
	}

	char name[MAX_NAME_LENGTH]
	GetClientName(targets[0], name, sizeof(name))

	char authid[MAX_AUTHID_LENGTH]
	AuthIdType authtype = AuthId_Steam2

	if (steamHistory) {
		authtype = AuthId_SteamID64
	}

	GetClientAuthId(targets[0], authtype, authid, MAX_AUTHID_LENGTH, true)

	char buf[256]
	if (!steamHistory) {
		Format(buf, sizeof(buf), "%s -> %s", name, authid)
	} else {
		Format(buf, sizeof(buf), "%s -> https://steamhistory.net/id/%s ", name, authid)
	}

	PrintToChat(client, buf)

	return Plugin_Handled
}
