#include <ripext>

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
ConVar timeout

public void OnPluginStart() {
	webhookURL = CreateConVar("sm_lumberjack_webhook", "", "Webhook URL everything is logged to.", FCVAR_PROTECTED)
	timeout = CreateConVar("sm_lumberjack_timeout", "15", "Timeout for webhook requests.", FCVAR_PROTECTED)
}

void sendWebhook(char[] msg) {
	char urlbuf[128]
	webhookURL.GetString(urlbuf, sizeof(urlbuf))

	JSONObject hook = new JSONObject();
    hook.SetString("content", msg);

	HTTPRequest req = new HTTPRequest(urlbuf)
	req.Timeout = timeout.IntValue
	req.SetHeader("User-Agent", "lumberjack/%s", VERSION)
	req.SetHeader("Content-Type", "application/json", VERSION)
	req.Post(hook, onRequestComplete)

	delete hook
}

void onRequestComplete(HTTPResponse response, any value) {
	if (response.Status == HTTPStatus_OK || response.Status == HTTPStatus_NoContent) {
		return
	}

	PrintToServer("[lumberjack] executing webhook got response code %d", response.Status)
}

bool isPluginOk() {
	char urlbuf[2]
	webhookURL.GetString(urlbuf, sizeof(urlbuf))

	if (urlbuf[0] == '\0') {
		return false
	}

	return true
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs) {
	if (!isPluginOk) {
		return Plugin_Continue
	}

	char idbuf[MAX_AUTHID_LENGTH] = "Console"
	char namebuf[MAX_NAME_LENGTH] = "Server"

	if (client != 0) {
		GetClientAuthString(client, idbuf, sizeof(idbuf))
		GetClientName(client, namebuf, sizeof(namebuf))
	}

	char messagebuf[512]
	Format(messagebuf, sizeof(messagebuf), "**%s** (``%s``) : %s", namebuf, idbuf, sArgs)
	sendWebhook(messagebuf)

	return Plugin_Continue
}

public void OnClientAuthorized(int client, const char[] auth) {
	if (!isPluginOk) {
		return
	}

	char idbuf[MAX_AUTHID_LENGTH]
	GetClientAuthString(client, idbuf, sizeof(idbuf))

	char namebuf[MAX_NAME_LENGTH]
	GetClientName(client, namebuf, sizeof(namebuf))

	char messagebuf[256]
	Format(messagebuf, sizeof(messagebuf), "Connect: **%s** (``%s``)", namebuf, idbuf)

	sendWebhook(messagebuf)
}

public void OnClientDisconnect(int client) {
	if (!isPluginOk) {
		return
	}

	char idbuf[MAX_AUTHID_LENGTH]
	GetClientAuthString(client, idbuf, sizeof(idbuf))

	char namebuf[MAX_NAME_LENGTH]
	GetClientName(client, namebuf, sizeof(namebuf))

	char messagebuf[256]
	Format(messagebuf, sizeof(messagebuf), "Disconnect: **%s** (``%s``)", namebuf, idbuf)

	sendWebhook(messagebuf)
}
