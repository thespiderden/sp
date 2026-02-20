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
#include <tf2>
#include <sdktools>

#if !defined(VERSION)
	#define VERSION "unknown"
#endif

public Plugin myinfo = {
	name = "Condify",
	author = "webb <w@spiderden.org>",
	description = "Condition your friends.",
	version = VERSION,
	url = "https://codeberg.org/spiderden/sp"
}

public void OnPluginStart() {
	RegAdminCmd("sm_condify", cmdAddCond, ADMFLAG_ROOT, "Adds a condition to player.");
	RegAdminCmd("sm_decondify", cmdRemoveCond, ADMFLAG_ROOT, "Removes a condition from a player.");
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

	if (cond < 0 || cond > 134) {
		PrintToChat(client, "[Condify] Invalid condition number. Must be between 0-134")
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
