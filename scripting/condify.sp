#include <sourcemod>
#include <tf2c>
#include <sdktools>

public Plugin myinfo = {
	name = "Condify",
	author = "webb <w@spiderden.org>",
	description = "Condition your friends.",
	version = "v0.0.0",
	url = "https://codeberg.org/moonspub/sp"
}

public void OnPluginStart() {
	RegAdminCmd("sm_condify", cmdAddCond, ADMFLAG_SLAY, "Adds a condition to player.");
	RegAdminCmd("sm_decondify", cmdRemoveCond, ADMFLAG_SLAY, "Removes a condition from a player.");
}

Action cmdAddCond(int client, int args) {
	return cmdCond(client, args)
}

Action cmdRemoveCond(int client, int args) {
	return cmdCond(client, args, true)
}

Action cmdCond(int client, int args, remove=false) {
	if (args != 2) {
		PrintToChat(client, "[Condify] Invalid number of arguments.")
		return Plugin_Handled
	}

	int cond
	if (!GetCmdArgIntEx(2, cond)) {
		PrintToChat(client, "[Condify] Condition is invalid, must be number.")
		return Plugin_Handled
	}

	char targetBuf[MAX_TARGET_LENGTH]
	GetCmdArg(1, targetBuf, sizeof(targetBuf))

	int targets[MAXPLAYERS]
	char target[MAX_TARGET_LENGTH]
	bool tnIsMl

	int found = ProcessTargetString(targetBuf, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, target, sizeof(target), tnIsMl)
	if (found == 0) {
		PrintToChat(client, "[Condify] Couldn't find target.")
		return Plugin_Handled
	}

	for (int i = 0; i < found; i++) {
		if (targets[i] == 0) {
			break
		}

		if (remove) {
			TF2_RemoveCondition(targets[i], cond)
		} else {
			TF2_AddCondition(targets[i], cond)
		}
	}

	return Plugin_Handled
}
