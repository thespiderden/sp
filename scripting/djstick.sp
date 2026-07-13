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
#include <halflife>
#include <sdktools_voice>
#include "include/attribution"

#if !defined(VERSION)
	#define VERSION "unknown"
#endif

public Plugin myinfo = {
	name = "DJ Stick",
	author = "webb <w@spiderden.org>",
	description = "I have the micspam stick!",
	version = VERSION,
	url = "https://codeberg.org/spiderden/sp"
}

const int DJ_NONE = -1

int activeDJ = DJ_NONE
int lastDJVoiceTime

ArrayList approvedDJs
bool djApprovalStatus[MAXPLAYERS]

Handle hudSync

ConVar hudTextX
ConVar hudTextY

ConVar hudTextR
ConVar hudTextG
ConVar hudTextB

ConVar djTimeout

public void OnPluginStart() {
	InitAttribution("djstick")

	RegAdminCmd("sm_djstick_reload", cmdReload, ADMFLAG_ROOT), "Reload whitelist."
	RegAdminCmd("sm_djstick_force", cmdForceDJ, ADMFLAG_ROOT, "Force a certain player to be DJ, regardless of whitelist status.")
	RegAdminCmd("sm_forcedj", cmdForceDJ, ADMFLAG_KICK, "Force a certain player to be DJ, regardless of whitelist status")
	RegAdminCmd("sm_djstick_revoke", cmdRevokeDJ, ADMFLAG_KICK, "Forces the current DJ to abandon their active DJ status.")
	RegAdminCmd("sm_revokedj", cmdRevokeDJ, ADMFLAG_KICK, "Forces the current DJ to abandon their active DJ status.")

	RegConsoleCmd("sm_claimdj", cmdClaimDJ, "Claim the active DJ status if you're whitelisted.")
	RegConsoleCmd("sm_abandondj", cmdAbandonDJ, "Remove your own active DJ status.")
	RegConsoleCmd("sm_dj", cmdDJ, "Show the current DJ.")

	hudTextX = CreateConVar("sm_djstick_hudpos_x", "1.0", "The X position of the active DJ hud text. 0.0-1.0")
	hudTextY = CreateConVar("sm_djstick_hudpos_y", "0.005", "The Y position of the active DJ hud text. 0.0-1.0")
	hudTextR = CreateConVar("sm_djstick_hudcolour_r", "255", "Red value for RGBA colour of the active DJ hud text. 0-255")
	hudTextG = CreateConVar("sm_djstick_hudcolour_g", "255", "Green value for RGBA colour of the active DJ hud text. 0-255")
	hudTextB = CreateConVar("sm_djstick_hudcolour_b", "255", "Blue value for RGB colour of the active DJ hud text. 0-255")

	djTimeout = CreateConVar("sm_djstick_timeout", "120", "Number of seconds of voice inactivity before removing active DJ status.")

	HookEvent("player_disconnect", onPlayerDisconnect, EventHookMode_Pre)
	HookEvent("teamplay_round_start", onRoundStart, EventHookMode_Post)
	HookEvent("player_spawn", refreshPlayerHudEvent, EventHookMode_Post)
	HookEvent("player_activate", refreshPlayerHudEvent, EventHookMode_Post)

	approvedDJs = CreateArray(MAX_AUTHID_LENGTH)
	hudSync = CreateHudSynchronizer()

	CreateTimer(3.0, djTimer, 0, TIMER_REPEAT)

	cmdReload(0, 0)
}

public void OnPluginEnd() {
	abandonDJ()
}

Action cmdForceDJ(int client, int args) {
	if (args != 1) {
		ReplyToCommand(client, "[djstick] Wrong number of arguments")
		return Plugin_Handled
	}

	char argBuf[MAX_NAME_LENGTH]
	GetCmdArgString(argBuf, sizeof(argBuf))

	int targets[1]
	char target[MAX_TARGET_LENGTH]
	bool tnIsMl
	int found = ProcessTargetString(argBuf, client, targets, sizeof(targets), COMMAND_FILTER_NO_MULTI | COMMAND_FILTER_NO_BOTS, target, sizeof(target), tnIsMl)
	if (found == 0) {
		ReplyToCommand(client, "[djstick] Couldn't find target.")
		return Plugin_Handled
	}

	changeDJ(targets[0])
	return Plugin_Handled
}

Action cmdDJ(int client, int args) {
	if (activeDJ == DJ_NONE) {
		ReplyToCommand(client, "[djstick] There is no active DJ.")
		return Plugin_Handled
	}

	char nameBuf[MAX_NAME_LENGTH]
	GetClientName(activeDJ, nameBuf, sizeof(nameBuf))

	char replyBuf[192]
	Format(replyBuf, sizeof(replyBuf), "[djstick] The current DJ is %s.", nameBuf)

	ReplyToCommand(client, replyBuf)

	return Plugin_Handled
}

Action cmdReload(int client, int args) {
	approvedDJs.Clear()

	char path[PLATFORM_MAX_PATH]
	BuildPath(Path_SM, path, sizeof(path), "configs/djstick.whitelist.cfg")

	if (!FileExists(path)) {
		ReplyToCommand(client, "[djstick] warning: No configuration file, will treat whitelist as empty.")
		return Plugin_Handled
	}

	Handle file = OpenFile(path, "r")
	if (file == null) {
		ReplyToCommand(client, "[djstick] error: There was a problem opening the configuration file.")
		return Plugin_Handled
	}

	char line[MAX_AUTHID_LENGTH]
	while (!IsEndOfFile(file) && ReadFileLine(file, line, sizeof(line))) {
		TrimString(line)
		approvedDJs.PushString(line)
	}

	int i
	for (i = 1; i <= MaxClients; i++) {
		djApprovalStatus[i] = false
		char id[MAX_AUTHID_LENGTH]
		if (!IsClientConnected(i) || !IsClientAuthorized(i) || IsFakeClient(i) || !GetClientAuthId(i, AuthId_Steam2, id, sizeof(id))) {
			continue
		}

		if (approvedDJs.FindString(id) != -1) {
			djApprovalStatus[i] = true
		}
	}

	return Plugin_Handled
}

Action cmdAbandonDJ(int client, int args) {
	if (client != activeDJ) {
		ReplyToCommand(client, "[djstick] You cannot abandon DJ status as you are not the DJ.")
		return Plugin_Handled
	}

	abandonDJ()
	return Plugin_Handled
}

Action cmdRevokeDJ(int client, int args) {
	abandonDJ()
	return Plugin_Handled
}

Action cmdClaimDJ(int client, int args) {
	if (!djApprovalStatus[client]) {
		ReplyToCommand(client, "[djstick] You are not approved to claim DJ status.")
		return Plugin_Handled
	}

	if (activeDJ != -1) {
		ReplyToCommand(client, "[djstick] DJ status has already been claimed.")
		return Plugin_Handled
	}

	changeDJ(client)
	return Plugin_Handled
}

void refreshHudText(int client = -1) {
	int i
	if (activeDJ == DJ_NONE) {
		if (client != -1) {
			ClearSyncHud(client, hudSync)
			return
		}

		for (i = 1; i <= MaxClients; i++) {
			if (!IsClientConnected(i) || !IsClientInGame(i) || !IsClientAuthorized(i) || IsFakeClient(i)) {
				continue
			}

			ClearSyncHud(i, hudSync)
		}

		return
	}

	char nameBuf[MAX_NAME_LENGTH]
	GetClientName(activeDJ, nameBuf, sizeof(nameBuf))

	char hudTextBuf[128]
	Format(hudTextBuf, sizeof(hudTextBuf), "Current DJ: %s ", nameBuf)

	SetHudTextParams(
		hudTextX.FloatValue,
	 	hudTextY.FloatValue,
		4.0,
	 	hudTextR.IntValue,
		hudTextG.IntValue,
	 	hudTextB.IntValue,
		255
	)

	if (client != -1) {
		ShowSyncHudText(client, hudSync, hudTextBuf)
		return
	}

	for (i = 1; i <= MaxClients; i++) {
		if (!IsClientConnected(i) || !IsClientAuthorized(i) || !IsClientInGame(i) || IsFakeClient(i)) {
			continue
		}

		ShowSyncHudText(i, hudSync, hudTextBuf)
	}
}

public void djTimer(Handle timer) {
	if (activeDJ != DJ_NONE && djTimeout.IntValue > 0) {
		if ((GetTime() - lastDJVoiceTime) >= djTimeout.IntValue) {
			PrintToChat(activeDJ, "[djstick] You are no longer the active DJ due to voice inactivity.")
			abandonDJ()
			return
		}
	}

	refreshHudText()
}

void changeDJ(int client) {
	activeDJ = client
	lastDJVoiceTime = GetTime()

	char nameBuf[MAX_NAME_LENGTH]
	GetClientName(activeDJ, nameBuf, sizeof(nameBuf))
	PrintToChatAll("[djstick] %s is now the DJ.", nameBuf)
	refreshHudText()
}

void abandonDJ() {
	char nameBuf[MAX_NAME_LENGTH]
	GetClientName(activeDJ, nameBuf, sizeof(nameBuf))
	PrintToChatAll("[djstick] %s is no longer DJ.", nameBuf)

	activeDJ = DJ_NONE
	refreshHudText()
}

void onPlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
	if (activeDJ == GetClientOfUserId(event.GetInt("userid"))) {
		abandonDJ()
	}
}

void onRoundStart(Event event, const char[] name, bool dontBroadcast) {
	if (activeDJ != DJ_NONE) {
		refreshHudText()
	}
}

void refreshPlayerHudEvent(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"))
	if (activeDJ != DJ_NONE) {
		refreshHudText(client)
	}
}

public void OnClientAuthorized(int client, const char[] auth) {
	if (approvedDJs.FindString(auth) != -1) {
		djApprovalStatus[client] = true
	}
}

public void OnClientSpeaking(int client) {
	if (client != activeDJ) {
		return
	}

	lastDJVoiceTime = GetTime()
}
