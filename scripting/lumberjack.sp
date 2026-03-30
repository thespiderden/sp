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

#include <ripext>
#include <sdktools>

#if !defined(VERSION)
	#define VERSION "unknown"
#endif

public Plugin myinfo = {
	name = "Lumberjack",
	author = "webb <w@spiderden.org>",
	description = "Yet another Discord logging plugin.",
	version = VERSION,
	url = "https://codeberg.org/spiderden/sp"
}

ConVar webhookURL
ConVar callWebhookURL
ConVar callWebhookEmoji
ConVar timeout
ConVar logDecals

bool sprayLogged[MAXPLAYERS]

public void OnPluginStart() {
	webhookURL = CreateConVar("sm_lumberjack_webhook", "", "Webhook URL chat, and connections is logged to.", FCVAR_PROTECTED)
	callWebhookURL = CreateConVar("sm_lumberjack_calladmin_webhook", "", "Webhook URL CallAdmin calls are logged to.", FCVAR_PROTECTED)
	callWebhookEmoji = CreateConVar("sm_lumberjack_calladmin_webhook_emoji", ":point_right:", "Point emoji used for CallAdmin webhooks.", FCVAR_PROTECTED)
	timeout = CreateConVar("sm_lumberjack_timeout", "15", "Timeout for webhook requests.", FCVAR_PROTECTED)
	logDecals = CreateConVar("sm_lumberjack_logdecals", "1", "Log the name of a spray when initially used by a player.")

	RegAdminCmd("sm_lumberjack_calladmin_test", cmdCallAdminTest, Admin_Root)

	HookEvent("player_disconnect", eventPlayerDisconnect, EventHookMode_Pre)
	AddTempEntHook("Player Decal", onPlayerDecal)

	CreateTimer(1.0, hookQueueCleanupTimer, _, TIMER_REPEAT)
}

// For high-frequency things like chat messages/disconnects we use a queue to avoid sending a hook
// for each little thing.
char hookQueueBuf[2000]
int writtenRunes
int lastWrite // for debouncing, will never be earlier than last send
int lastSend

Action hookQueueCleanupTimer(Handle timer) {
	if (!isWebhookSet() || GetTime() - lastWrite < 2 || GetTime() - lastSend < 5 || hookQueueBuf[0] == '\0') {
		return Plugin_Continue
	}

	sendQueue()

	return Plugin_Continue
}

public void OnServerEnterHibernation() {
	if (isWebhookSet() && hookQueueBuf[0] != '\0') {
		sendQueue()
	}
}

void hookQueueAdd(char[] msg) {
	int msgsize = strlen(msg)
	if (msgsize > sizeof(hookQueueBuf)) {
		PrintToServer("[lumberjack] warning: got message too long for Discord")
		return
	}

	if (writtenRunes + msgsize > sizeof(hookQueueBuf)) {
		sendQueue()
	}

	writtenRunes += StrCat(hookQueueBuf, sizeof(hookQueueBuf), msg)
	lastWrite = GetTime()

	if (writtenRunes == sizeof(hookQueueBuf)) {
		sendQueue()
	}
}

void sendQueue() {
	sendWebhook(hookQueueBuf, webhookURL, false)
	writtenRunes = 0
	lastSend = GetTime()

	for (int i = 0; i < sizeof(hookQueueBuf); i++) {
		hookQueueBuf[i] = '\0'
	}
}

void sendWebhook(char[] msg, ConVar url, pingable=false) {
	char urlbuf[128]
	url.GetString(urlbuf, sizeof(urlbuf))

	JSONObject hook = new JSONObject()
    hook.SetString("content", msg)

    JSONObject allowedPings = new JSONObject()
    JSONArray parse = new JSONArray()

    if (pingable) {
    	parse.PushString("everyone")
    }

    allowedPings.Set("parse", parse)

    hook.Set("allowed_mentions", allowedPings)

	HTTPRequest req = new HTTPRequest(urlbuf)
	req.Timeout = timeout.IntValue
	req.SetHeader("User-Agent", "lumberjack/%s", VERSION)
	req.SetHeader("Content-Type", "application/json", VERSION)
	req.Post(hook, onRequestComplete)

	delete hook
	delete allowedPings
	delete parse
}

void onRequestComplete(HTTPResponse response, any value) {
	if (response.Status == HTTPStatus_OK || response.Status == HTTPStatus_NoContent) {
		return
	}

	PrintToServer("[lumberjack] executing webhook got response code %d", response.Status)
}

bool isWebhookSet() {
	char urlbuf[2]
	webhookURL.GetString(urlbuf, sizeof(urlbuf))

	if (urlbuf[0] == '\0') {
		return false
	}

	return true
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs) {
	if (!isWebhookSet) {
		return Plugin_Continue
	}

	char idbuf[MAX_AUTHID_LENGTH] = "Console"
	char namebuf[MAX_NAME_LENGTH] = "Server"

	if (client != 0) {
		GetClientAuthString(client, idbuf, sizeof(idbuf))
		GetClientName(client, namebuf, sizeof(namebuf))
	}

	char messagebuf[512]
	Format(messagebuf, sizeof(messagebuf), "**%s** (``%s``) : %s\n", namebuf, idbuf, sArgs)
	hookQueueAdd(messagebuf)

	return Plugin_Continue
}

public void OnClientAuthorized(int client, const char[] auth) {
	if (!isWebhookSet || client == 0) {
		return
	}

	char idbuf[MAX_AUTHID_LENGTH]
	GetClientAuthString(client, idbuf, sizeof(idbuf))

	char namebuf[MAX_NAME_LENGTH]
	GetClientName(client, namebuf, sizeof(namebuf))

	char messagebuf[256]
	Format(messagebuf, sizeof(messagebuf), "Connect: **%s** (``%s``)\n", namebuf, idbuf)

	hookQueueAdd(messagebuf)
}

void eventPlayerDisconnect(Event event, const char[] name, bool dontBroadcast) {
	if (!isWebhookSet) {
		return
	}

	int userid = event.GetInt("userid")
	int client = GetClientOfUserId(userid)

	if (client == 0) {
		return
	}

	char idbuf[MAX_AUTHID_LENGTH]
	GetClientAuthString(client, idbuf, sizeof(idbuf))

	char namebuf[MAX_NAME_LENGTH]
	GetClientName(client, namebuf, sizeof(namebuf))

	char messagebuf[256]
	Format(messagebuf, sizeof(messagebuf), "Disconnect: **%s** (``%s``)\n", namebuf, idbuf)

	hookQueueAdd(messagebuf)
}

public void OnClientDisconnect(int client) {
	sprayLogged[client] = false
}

Action onPlayerDecal(const char[] name, const int[] clients, int count, float delay) {
	int client = TE_ReadNum("m_nPlayer")
	char spraybuf[64]
	if (sprayLogged[client] || !GetConVarBool(logDecals) || !GetPlayerDecalFile(client, spraybuf, sizeof(spraybuf))) {
		return Plugin_Continue
	}

	char namebuf[MAX_NAME_LENGTH]
	GetClientName(client, namebuf, sizeof(namebuf))

	char idbuf[MAX_AUTHID_LENGTH]
	GetClientAuthString(client, idbuf, sizeof(idbuf))

	char messagebuf[256]
	Format(messagebuf, sizeof(messagebuf), "Spray: **%s** (``%s``) -> <Spray: ``%s``>\n", namebuf, idbuf, spraybuf)

	hookQueueAdd(messagebuf)

	sprayLogged[client] = true

	return Plugin_Continue
}

// We only use a couple of constants from the CallAdmin headers.
// A little copying is better than a little dependency.
#define REPORTER_CONSOLE 1679124
#define REASON_MAX_LENGTH 128

Action cmdCallAdminTest(int client, int args) {
	CallAdmin_OnReportPost(REPORTER_CONSOLE, REPORTER_CONSOLE, "<Test command>")
    return Plugin_Handled
}

public void CallAdmin_OnReportPost(int client, int target, const char[] reason) {
	char url[1024]
	GetConVarString(callWebhookURL, url, sizeof(url))

	if (url[0] == '\0') {
	    return
	}

	char reporter[MAX_NAME_LENGTH+1] = "Console"
	char reporterID[MAX_AUTHID_LENGTH] = "NONE"
	char reportee[MAX_NAME_LENGTH+1] = "Console"
	char reporteeID[MAX_AUTHID_LENGTH] = "NONE"

	if (client != REPORTER_CONSOLE) {
		GetClientName(client, reporter, sizeof(reporter))
		GetClientAuthId(client, AuthId_Steam2, reporterID, 21)
	}

	if (target != REPORTER_CONSOLE) {
	    GetClientName(target, reportee, sizeof(reportee))
	    GetClientAuthId(target, AuthId_Steam2, reporteeID, sizeof(reporteeID))
	}

	char pointSymbol[64]
	callWebhookEmoji.GetString(pointSymbol, sizeof(pointSymbol))

	char messageBuf[512]

	Format(messageBuf, sizeof(messageBuf), "# Admin requested\n## %s (``%s``) %s %s (``%s``)\n``%s``\n\n@everyone",
		reporter,
		reporterID,
		pointSymbol,
		reportee,
		reporteeID,
		reason
	)

	sendWebhook(messageBuf, callWebhookURL, true)
}
