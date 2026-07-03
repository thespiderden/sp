// This one is all rights reserved due to advanced_motd not having a license

#include <sourcemod>
#include <advanced_motd>
#include <keyvalues>
#include <tf2_stocks>
#include <tf2>

#if !defined(VERSION)
	#define VERSION "unknown"
#endif

public Plugin myinfo = {
	name = "Nag",
	author = "webb <w@spiderden.org>",
	description = "Bother your players.",
	version = VERSION,
	url = "https://codeberg.org/spiderden/sp"
}

KeyValues conf

public void OnPluginStart() {
	conf = new KeyValues("nags")
	if (!reloadConfig()) {
		SetFailState("Could not parse configuration file.")
	}

	RegAdminCmd("sm_nag_reload", cmdReload, ADMFLAG_ROOT)
	RegAdminCmd("sm_nag", cmdNag, ADMFLAG_KICK)
}

bool reloadConfig() {
	char path[PLATFORM_MAX_PATH]
	BuildPath(Path_SM, path, sizeof(path), "configs/nags.cfg")
	return conf.ImportFromFile(path)
}

Action cmdReload(int client, int args) {
	if (!reloadConfig()) {
		ReplyToCommand(client, "[nag] failed to reload config file!")
	}

	return Plugin_Handled
}

enum struct record {
	bool found;
	bool forceSpec;
	char url[256];
	char textFallback[192];
}

record getRecord(const char[] name){
	conf.Rewind()

	record rec
	rec.found = false
	if (conf == null || !KvJumpToKey(conf, name)) {
		return rec
	}

	conf.GetString("url", rec.url, sizeof(rec.url))

	if (rec.url[0] == '\0') {
		return rec
	}

	conf.GetString("textFallback", rec.textFallback, sizeof(rec.textFallback))

	char frcspc[2]
	conf.GetString("forceSpec", frcspc, sizeof(frcspc))
	if (frcspc[0] != '\0' && CharToLower(frcspc[0]) != 'n') {
		rec.forceSpec = true
	}

	rec.found = true
	return rec
}

Action cmdNag(int client, int args) {
	if (args != 2) {
		ReplyToCommand(client, "[nag] Invalid number of arguments.")
		return Plugin_Handled
	}

	char nagKey[32]
	GetCmdArg(2, nagKey, sizeof(nagKey))

	record rec
	rec = getRecord(nagKey)

	if (!rec.found) {
		ReplyToCommand(client, "[nag] Could not find nag.")
		return Plugin_Handled
	}

	char targetBuf[MAX_TARGET_LENGTH]
	GetCmdArg(1, targetBuf, sizeof(targetBuf))

	int targets[MAXPLAYERS]
	char target[MAX_TARGET_LENGTH]
	bool tnIsMl

	int found = ProcessTargetString(targetBuf, client, targets, sizeof(targets), COMMAND_TARGET_NONE, target, sizeof(target), tnIsMl)
	if (found == 0) {
		ReplyToCommand(client, "[nag] Couldn't find target.")
		return Plugin_Handled
	}

	for (int i = 0; i < found; i++) {
		int targ = targets[i]
		if (targ == 0 || !IsClientConnected(targ) || !IsClientInGame(targ) || IsFakeClient(targ)) {
			continue
		}

		AdvMOTD_ShowMOTDPanel(targ, "Nag", rec.url, MOTDPANEL_TYPE_URL, true, false, true)
		PrintToChat(targ, rec.textFallback)
		PrintToChat(targ, rec.url)

		if (rec.forceSpec) {
			TF2_ChangeClientTeam(targ, TFTeam_Spectator)
		}
	}

	return Plugin_Handled
}
