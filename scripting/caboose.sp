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
	url = "https://codeberg.org/moonspub/sp"
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

	int found = ProcessTargetString(targetBuf, client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_NO_MULTI, target, sizeof(target), tnIsMl)
	if (found == 0) {
		PrintToChat(client, "[Caboose] Couldn't find target.")
		return Plugin_Handled
	}

	int i
	for (i = 0; i < found; i++) {
		char name[MAX_NAME_LENGTH]
		GetClientName(targets[i], name, sizeof(name))

		char authid[MAX_AUTHID_LENGTH]
		AuthIdType authtype = AuthId_Steam2

		if (steamHistory) {
			authtype = AuthId_SteamID64
		}

		GetClientAuthId(targets[i], authtype, authid, MAX_AUTHID_LENGTH, true)

		char buf[256]
		if (!steamHistory) {
			Format(buf, sizeof(buf), "%s -> %s", name, authid)
		} else {
			Format(buf, sizeof(buf), "%s -> https://steamhistory.net/id/%s ", name, authid)
		}

		PrintToChat(client, buf)
	}

	return Plugin_Handled
}
