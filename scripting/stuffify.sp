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

// Yes the code in this is dogshit. Some day I will deduplicate shit.

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>

#if !defined(VERSION)
	#define VERSION "unknown"
#endif

public Plugin myinfo = {
	name = "Stuffify",
	author = "webb <w@spiderden.org>",
	description = "Do stuff to other players.",
	version = VERSION,
	url = "https://codeberg.org/spiderden/sp"
}

ConVar windowsVscriptWorkaround

public void OnPluginStart() {
	RegAdminCmd("sm_condify", cmdAddCond, ADMFLAG_ROOT, "Adds a condition to player.")
	RegAdminCmd("sm_decondify", cmdRemoveCond, ADMFLAG_ROOT, "Removes a condition from a player.")
	RegAdminCmd("sm_classify", cmdClassify, ADMFLAG_ROOT, "Changes a player's class without removing weapons.")
	RegAdminCmd("sm_reclassify", cmdReclassify, ADMFLAG_ROOT, "Changes a player's class and switches weapons.")
	RegAdminCmd("sm_regenify", cmdRegenify, ADMFLAG_ROOT, "Heals/restocks player as if they touched a resupply cabinet.")
	RegAdminCmd("sm_respawnify", cmdRespawnify, ADMFLAG_ROOT, "Respawns player if dead.")
	RegAdminCmd("sm_teamify", cmdTeamify, ADMFLAG_ROOT, "Changes a player's team.")

	windowsVscriptWorkaround = CreateConVar("sm_stuffify_windows_workaround", "0", "Use Vscript for Condify/Decondify to workaround broken gamedata on Windows.")
}

Action cmdAddCond(int client, int args) {
	return cmdCond(client, args)
}

Action cmdRemoveCond(int client, int args) {
	return cmdCond(client, args, true)
}

Action cmdCond(int client, int args, remove=false) {
	if (args != 2) {
		PrintToChat(client, "[stuffify] Invalid number of arguments.")
		return Plugin_Handled
	}

	int cond
	if (!GetCmdArgIntEx(2, cond)) {
		PrintToChat(client, "[stuffify] Condition is invalid, must be number.")
		return Plugin_Handled
	}

	if (cond < 0 || cond > 134) {
		PrintToChat(client, "[stuffify] Invalid condition number. Must be between 0-134")
		return Plugin_Handled
	}

	char targetBuf[MAX_TARGET_LENGTH]
	GetCmdArg(1, targetBuf, sizeof(targetBuf))

	int targets[MAXPLAYERS]
	char target[MAX_TARGET_LENGTH]
	bool tnIsMl

	int found = ProcessTargetString(targetBuf, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, target, sizeof(target), tnIsMl)
	if (found == 0) {
		PrintToChat(client, "[stuffify] Couldn't find target.")
		return Plugin_Handled
	}

	char cmd[32]
	if (windowsVscriptWorkaround.BoolValue) {
		if (!remove) {
			Format(cmd, sizeof(cmd), "self.AddCond(%d);", cond)
		} else {
			Format(cmd, sizeof(cmd), "self.RemoveCond(%d);", cond)
		}
	}

	for (int i = 0; i < found; i++) {
		if (targets[i] == 0) {
			break
		}

		if (windowsVscriptWorkaround.BoolValue) {
			SetVariantString(cmd)
			AcceptEntityInput(targets[i], "RunScriptCode")
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

Action cmdClassify(int client, int args) {
	return cmdClass(client, args, false)
}

Action cmdReclassify(int client, int args) {
	return cmdClass(client, args, true)
}

char classStr[][]  = {"", "Scout", "Sniper", "Soldier", "Demo", "Medic", "Heavy", "Pyro", "Spy", "Engineer", "Civilian"}

Action cmdClass(int client, int args, regenerate=false) {
	if (args != 2) {
		PrintToChat(client, "[stuffify] Invalid number of arguments.")
		return Plugin_Handled
	}

	char buf[16]
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
		PrintToConsole(client, "[stuffify] Invalid class name specified.")
		return Plugin_Handled
	}

	char targetBuf[MAX_TARGET_LENGTH]
	GetCmdArg(1, targetBuf, sizeof(targetBuf))

	int targets[MAXPLAYERS]
	char target[MAX_TARGET_LENGTH]
	bool tnIsMl

	int found = ProcessTargetString(targetBuf, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, target, sizeof(target), tnIsMl)
	if (found == 0) {
		PrintToChat(client, "[stuffify] Couldn't find target.")
		return Plugin_Handled
	}

	for (int i = 0; i < found; i++) {
		if (targets[i] == 0) {
			break
		}

		TF2_SetPlayerClass(targets[i], class)
		if (regenerate) {
			TF2_RegeneratePlayer(targets[i])
		}
	}

	return Plugin_Handled
}

Action cmdRegenify(int client, int args) {
	char targetBuf[MAX_TARGET_LENGTH]
	GetCmdArg(1, targetBuf, sizeof(targetBuf))

	int targets[MAXPLAYERS]
	char target[MAX_TARGET_LENGTH]
	bool tnIsMl

	int found = ProcessTargetString(targetBuf, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, target, sizeof(target), tnIsMl)
	if (found == 0) {
		PrintToChat(client, "[stuffify] Couldn't find target.")
		return Plugin_Handled
	}

	for (int i = 0; i < found; i++) {
		TF2_RegeneratePlayer(targets[i])
	}

	return Plugin_Handled
}

Action cmdRespawnify(int client, int args) {
	char targetBuf[MAX_TARGET_LENGTH]
	GetCmdArg(1, targetBuf, sizeof(targetBuf))

	int targets[MAXPLAYERS]
	char target[MAX_TARGET_LENGTH]
	bool tnIsMl

	int found = ProcessTargetString(targetBuf, client, targets, sizeof(targets), 0, target, sizeof(target), tnIsMl)
	if (found == 0) {
		PrintToChat(client, "[stuffify] Couldn't find target.")
		return Plugin_Handled
	}

	for (int i = 0; i < found; i++) {
		TF2_RespawnPlayer(targets[i])
	}

	return Plugin_Handled
}

char teamStr[][]  = {"unassigned", "spectator", "red", "blue", "green", "yellow"}

Action cmdTeamify(int client, int args) {
	char targetBuf[MAX_TARGET_LENGTH]
	GetCmdArg(1, targetBuf, sizeof(targetBuf))

	char buf[16]
	GetCmdArg(2, buf, sizeof(buf))

	TFTeam team
	int i = -1
	for (i = 1; i < sizeof(teamStr); i++) {
		if (StrEqual(teamStr[i], buf, false)) {
			team = i
			break
		}
	}

	if (team == -1) {
		PrintToConsole(client, "[stuffify] Invalid class name specified.")
		return Plugin_Handled
	}

	int targets[MAXPLAYERS]
	char target[MAX_TARGET_LENGTH]
	bool tnIsMl

	int found = ProcessTargetString(targetBuf, client, targets, sizeof(targets), 0, target, sizeof(target), tnIsMl)
	if (found == 0) {
		PrintToChat(client, "[stuffify] Couldn't find target.")
		return Plugin_Handled
	}

	for (i = 0; i < found; i++) {
		TF2_ChangeClientTeam(targets[i], team)
	}

	return Plugin_Handled
}
