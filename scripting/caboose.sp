/*
Copyright (C) 2026 webb

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License version 3.0,
as published by the Free Software Foundation,

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

As a special exception, AlliedModders gives you permission to link the
code of this program (as well as its derivative works) to "Half-Life 2,"
the "Source Engine" and any Game MODs that run on software by the
Valve Corporation. Additionally, AlliedModders grants this exception to
all derivative works.
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
	RegConsoleCmd("sm_uid", cmdUID, "Gets the Steam ID of one or more players in a standard format.")
	RegConsoleCmd("sm_uid64", cmdUID64, "Gets the Steam ID of one or more players in the 64-bit/community format.")
	RegConsoleCmd("sm_steamhistory", cmdHistory, "Gets the steamhistory.net URL of one or more players.")
	RegConsoleCmd("sm_opensteamhistory", cmdOpenHistory, "Opens the steam history page for a given user in a MOTD panel.")
	RegConsoleCmd("sm_sprayid", cmdSprayHex, "Gets the hex of a spray.")
}

Action cmdHistory(int client, int args) {
	return _cmdID(client, args, true)
}

Action cmdUID(int client, int args) {
	return _cmdID(client, args)
}

Action cmdUID64(int client, int args) {
	return _cmdID(client, args, false, AuthId_SteamID64)
}

Action _cmdID(int client, int args, steamHistory=false, AuthIdType authType=AuthId_Steam2) {
	char targetBuf[MAX_TARGET_LENGTH]
	GetCmdArg(1, targetBuf, sizeof(targetBuf))

	int targets[MAXPLAYERS]
	char target[MAX_TARGET_LENGTH]
	bool tnIsMl

	int found = ProcessTargetString(targetBuf, client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS, target, sizeof(target), tnIsMl)
	if (found == 0) {
		PrintToChat(client, "[caboose] Couldn't find target.")
		return Plugin_Handled
	}
	if (found > 1) {
		PrintToChat(client, "[caboose] Multiple targets found.")
		return Plugin_Handled
	}

	char name[MAX_NAME_LENGTH]
	GetClientName(targets[0], name, sizeof(name))

	char authid[MAX_AUTHID_LENGTH]

	if (steamHistory) {
		authType = AuthId_SteamID64
	}

	GetClientAuthId(targets[0], authType, authid, MAX_AUTHID_LENGTH, true)

	char buf[256]
	if (!steamHistory) {
		Format(buf, sizeof(buf), "%s -> %s", name, authid)
	} else {
		Format(buf, sizeof(buf), "%s -> https://steamhistory.net/id/%s ", name, authid)
	}

	PrintToChat(client, buf)

	return Plugin_Handled
}

Action cmdOpenHistory(int client, int args) {
	char targetBuf[MAX_TARGET_LENGTH]
	GetCmdArg(1, targetBuf, sizeof(targetBuf))

	int targets[MAXPLAYERS]
	char target[MAX_TARGET_LENGTH]
	bool tnIsMl

	int found = ProcessTargetString(targetBuf, client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS, target, sizeof(target), tnIsMl)
	if (found == 0) {
		PrintToChat(client, "[caboose] Couldn't find target.")
		return Plugin_Handled
	}
	if (found > 1) {
		PrintToChat(client, "[caboose] Multiple targets found.")
		return Plugin_Handled
	}

	char authID[MAX_AUTHID_LENGTH]
	bool ok = GetClientAuthId(targets[0], AuthId_SteamID64, authID, sizeof(authID))
	if (!ok) {
		PrintToChat(client, "[caboose] Could not get Steam ID of user")
		return Plugin_Handled
	}

	char urlBuf[128]
	Format(urlBuf, sizeof(urlBuf), "https://steamhistory.net/id/%s", authID)

	ShowMOTDPanel(client, "Steam History", urlBuf, MOTDPANEL_TYPE_URL)

	return Plugin_Handled
}

Action cmdSprayHex(int client, int args) {
	char targetBuf[MAX_TARGET_LENGTH]
	GetCmdArg(1, targetBuf, sizeof(targetBuf))

	int targets[MAXPLAYERS]
	char target[MAX_TARGET_LENGTH]
	bool tnIsMl
	int found = ProcessTargetString(targetBuf, client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_NO_MULTI, target, sizeof(target), tnIsMl)
	if (found == 0) {
		PrintToChat(client, "[caboose] Couldn't find target.")
		return Plugin_Handled
	}

	return Plugin_Handled
}
