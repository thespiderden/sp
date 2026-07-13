#include <sourcemod>

#define ATTRIBUTION_FMT "[%s] (C) webb 2026 // To view the source code and copyright info of this plugin, visit https://codeberg.org/spiderden/sp in your browser."

char attributionMsg[192]
bool seenAttributionMsg[MAXPLAYERS]

void printAttribution(int client) {
	PrintToConsole(client, attributionMsg)
	seenAttributionMsg[client] = true
}

void eventActivateAttribution(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"))

	if (!seenAttributionMsg[client]) {
		printAttribution(client)
	}
}

void eventDisconnectAttribution(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"))
	seenAttributionMsg[client] = false
}

void InitAttribution(char[] name) {
	Format(attributionMsg, sizeof(attributionMsg), ATTRIBUTION_FMT, name)

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientConnected(i) || IsFakeClient(i) || !IsClientInGame(i)) {
			continue
		}

		printAttribution(i)
		seenAttributionMsg[i] = true
	}

	HookEvent("player_activate", eventActivateAttribution)
	HookEvent("player_disconnect", eventDisconnectAttribution)
}
