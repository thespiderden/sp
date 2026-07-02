#include <sourcemod>
#include <halflife>
#include <sdktools_voice>

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
	RegAdminCmd("sm_djstick_reload", cmdReload, ADMFLAG_ROOT)
	RegAdminCmd("sm_djstick_force", cmdForceDJ, ADMFLAG_ROOT)
	RegAdminCmd("sm_forcedj", cmdForceDJ, ADMFLAG_KICK)
	RegAdminCmd("sm_djstick_revoke", cmdRevokeDJ, ADMFLAG_KICK)
	RegAdminCmd("sm_revokedj", cmdRevokeDJ, ADMFLAG_KICK)

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

	approvedDJs = CreateArray(MAX_AUTHID_LENGTH)
	hudSync = CreateHudSynchronizer()

	CreateTimer(3.0, djTimer, 0, TIMER_REPEAT)

	readList()
}

Action cmdForceDJ(int client, int args) {
	if (args != 1) {
		ReplyToCommand(client, "[djs] Wrong number of arguments")
		return Plugin_Handled
	}

	char argBuf[MAX_NAME_LENGTH]
	GetCmdArgString(argBuf, sizeof(argBuf))

	int targets[1]
	char target[MAX_TARGET_LENGTH]
	bool tnIsMl
	int found = ProcessTargetString(argBuf, client, targets, sizeof(targets), COMMAND_FILTER_NO_MULTI | COMMAND_FILTER_NO_BOTS, target, sizeof(target), tnIsMl)
	if (found == 0) {
		ReplyToCommand(client, "[djs] Couldn't find target.")
		return Plugin_Handled
	}

	changeDJ(targets[0])
	return Plugin_Handled
}

Action cmdDJ(int client, int args) {
	if (activeDJ == DJ_NONE) {
		ReplyToCommand(client, "[djs] There is no active DJ.")
		return Plugin_Handled
	}

	char nameBuf[MAX_NAME_LENGTH]
	GetClientName(activeDJ, nameBuf, sizeof(nameBuf))

	char replyBuf[192]
	Format(replyBuf, sizeof(replyBuf), "[djs] The current DJ is %s.", nameBuf)

	ReplyToCommand(client, replyBuf)

	return Plugin_Handled
}

Action cmdReload(int client, int args) {
	readList()
	return Plugin_Handled
}

Action cmdAbandonDJ(int client, int args) {
	if (client != activeDJ) {
		ReplyToCommand(client, "[djs] You cannot abandon DJ status as you are not the DJ.")
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
		ReplyToCommand(client, "[djs] You are not approved to claim DJ status.")
		return Plugin_Handled
	}

	if (activeDJ != -1) {
		ReplyToCommand(client, "[djs] DJ status has already been claimed.")
		return Plugin_Handled
	}

	changeDJ(client)
	return Plugin_Handled
}

void refreshHudText() {
	int i
	if (activeDJ == DJ_NONE) {
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

	for (i = 1; i <= MaxClients; i++) {
		if (!IsClientConnected(i) || !IsClientAuthorized(i) || !IsClientInGame(i) || IsFakeClient(i)) {
			continue
		}

		SetHudTextParams(
			hudTextX.FloatValue,
		 	hudTextY.FloatValue,
			4.0,
		 	hudTextR.IntValue,
			hudTextG.IntValue,
		 	hudTextB.IntValue,
			255
		)
		ShowSyncHudText(i, hudSync, hudTextBuf)
	}
}

public void djTimer(Handle timer) {
	if (activeDJ != DJ_NONE && djTimeout.IntValue > 0) {
		if ((GetTime() - lastDJVoiceTime) >= djTimeout.IntValue) {
			PrintToChat(activeDJ, "[djs] You are no longer the active DJ due to voice inactivity.")
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
	PrintToChatAll("[djs] %s is now the DJ.", nameBuf)
	refreshHudText()
}

void abandonDJ() {
	char nameBuf[MAX_NAME_LENGTH]
	GetClientName(activeDJ, nameBuf, sizeof(nameBuf))
	PrintToChatAll("[djs] %s is no longer DJ.", nameBuf)

	activeDJ = DJ_NONE
	refreshHudText()
}

void onPlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
	if (activeDJ == GetClientOfUserId(event.GetInt("userid"))) {
		abandonDJ()
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

void readList() {
	approvedDJs.Clear()

	char path[PLATFORM_MAX_PATH]
	BuildPath(Path_SM, path, sizeof(path), "configs/djstick.whitelist.cfg")

	if (!FileExists(path)) {
		PrintToServer("[djstick] warning: No configuration file, will treat whitelist as empty.")
		return
	}

	Handle file = OpenFile(path, "r")
	if (file == null) {
		PrintToServer("[djstick] error: There was a problem opening the configuration file.")
		return
	}

	char line[MAX_AUTHID_LENGTH]
	while (!IsEndOfFile(file) && ReadFileLine(file, line, sizeof(line))) {
		TrimString(line)
		approvedDJs.PushString(line)
	}

	applyToConnected()
}

void applyToConnected() {
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
}
