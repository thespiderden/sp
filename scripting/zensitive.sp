#include <sourcemod>
#include <clientprefs>
#include <tf2c>
#include <sdktools>
#include <scp>

public Plugin myinfo = {
	name = "Zensitive",
	author = "webb <w@spiderden.org>",
	description = "Mark messages as sensitive.",
	version = "v0.0.0",
	url = "https://codeberg.org/moonspub/sp"
}

Handle prefOldConsentedMsg
Handle prefConsentedMsg
Handle prefConsented
Handle prefHideHidden

bool viewedConsent[MAXPLAYERS]

public void OnPluginStart() {
	prefOldConsentedMsg = RegClientCookie("zensitive.consent.message", "Defunct chat message cookie. No functionality.", CookieAccess_Protected)
	prefConsentedMsg = RegClientCookie("zensitive.consent.chat", "Consented to sensitive chat messages.", CookieAccess_Protected)
	prefConsented = RegClientCookie("zensitive.consent", "Currently unused, for a general consent in the future, aside from setting to 'never' to act as a ban from ever consenting for any type.", CookieAccess_Protected)
	prefHideHidden = RegClientCookie("zensitive.hide.chat", "Hides hidden sensitive chat messages", CookieAccess_Public)

	RegConsoleCmd("say", cmdSay)
	RegConsoleCmd("say_team", cmdSayTeam)
	RegConsoleCmd("sm_sensitive", cmdSensitive, "Shows a dialog to enable/disable viewing/sending sensitive messages")
	RegConsoleCmd("sm_hidehidden", cmdHideHidden, "Hide hidden sensitive chat messages")
	RegConsoleCmd("sm_iam18orolderandwishtoseesensitivechatmessages", cmdConsent, "Consent to sensitive messages after running sm_sensitive")

	RegAdminCmd("sm_zensitive_never", cmdNeverConsent, ADMFLAG_BAN, "Makes it so a user cannot ever agree to seeing sensitive messages, and revokes if enabled. Steam ID in quotes.")
	RegAdminCmd("sm_zensitive_reset", cmdResetConsent, ADMFLAG_UNBAN, "Resets agree values to default for a given Steam ID. Steam ID in quotes.")
}

public void OnPluginEnd() {
	CloseHandle(prefOldConsentedMsg)
	CloseHandle(prefConsented)
	CloseHandle(prefConsentedMsg)
}

public void OnClientDisconnect(int client) {
	viewedConsent[client] = false
}

public Action OnChatMessage_Pre(&author, Handle:recipients, String:name[], String:message[]) {
	char msgbuf[255]
	strcopy(msgbuf, sizeof(msgbuf), message)

	StripQuotes(msgbuf)
	TrimString(msgbuf)

	if (msgbuf[0] == ';') {
		return Plugin_Stop
	}

	return Plugin_Handled
}

Action cmdConsent(int client, int args) {
	if (!viewedConsent[client]) {
		PrintToChat(client, "[zensitive] Please type !sensitive and read the message before opting in to sensitive chat.")
		return Plugin_Handled
	}

	if (!AreClientCookiesCached(client)) {
		PrintToChat(client, "[zensitive] Error: Clientprefs have not loaded, cannot set consent preference.")
		return Plugin_Handled
	}

	SetClientCookie(client, prefConsentedMsg, "y")
	PrintToChat(client, "[zensitive] You have opted-in to seeing sensitive chat messages. Type !sensitive to opt out. To send a sensitive message, add a semicolon (;) to the beginning of your message.")

	return Plugin_Handled
}

Action cmdHideHidden(int client, int args) {
	if (!AreClientCookiesCached(client)) {
		PrintToChat(client, "[zensitive] Error: Clientprefs have not loaded, cannot change setting.")
		return Plugin_Handled
	}

	char cookiebuf[6]
	GetClientCookie(client, prefHideHidden, cookiebuf, sizeof(cookiebuf))

	if (cookiebuf[0] == 'y') {
		SetClientCookie(client, prefHideHidden, "n")
		PrintToChat(client, "[zensitive] Re-enabled seeing hidden messages.")
		return Plugin_Handled
	}

	SetClientCookie(client, prefHideHidden, "y")
	PrintToChat(client, "[zensitive] Hidden sensitive chat messages are hidden. Type !hidehidden again to see them. If sensitive chat is enabled, this won't have an effect until you disable it.")
	return Plugin_Handled
}

Action cmdNeverConsent(int client, int args) {
	if (args == 0) {
		PrintToConsole(client, "No user ID supplied.")
	}

	char id[MAX_AUTHID_LENGTH]
	GetCmdArg(1, id, sizeof(id))

	SetAuthIdCookie(id, prefConsented, "never")
	SetAuthIdCookie(id, prefConsentedMsg, "n")

	PrintToConsole(client, "[zensitive] Added ban for Steam ID.")
	return Plugin_Handled
}

Action cmdResetConsent(int client, int args) {
	if (args == 0) {
		PrintToConsole(client, "No user ID supplied.")
	}

	char id[MAX_AUTHID_LENGTH]
	GetCmdArg(1, id, sizeof(id))

	SetAuthIdCookie(id, prefConsented, "")
	SetAuthIdCookie(id, prefConsentedMsg, "n")
	return Plugin_Handled
}

Action cmdSay(int client, int args) {
	return _cmdSay(client, args)
}

Action cmdSayTeam(int client, int args) {
	return _cmdSay(client, args, true)
}

Action _cmdSay(int client, int args, team=false) {
	if (IsFakeClient(client)) {
		return Plugin_Continue
	}

	char msg[256]
	GetCmdArgString(msg, sizeof(msg))
	StripQuotes(msg)
	TrimString(msg)

	if (msg[0] != ';') {
		return Plugin_Continue
	}

	msg[0] = ' '
	TrimString(msg)

	if (msg[0] == '\0') {
		return Plugin_Handled
	}

	if (!AreClientCookiesCached(client)) {
		PrintToChat(client, "[zensitive] Error: Clientprefs have not loaded, cannot send sensitive message.")
		return Plugin_Handled
	}

	char cookiebuf[2]
	GetClientCookie(client, prefConsentedMsg, cookiebuf, sizeof(cookiebuf))

	if (cookiebuf[0] != 'y') {
		PrintToChat(client, "[zensitive] You have not agreed to sending/viewing sensitive messages. Please run the !sensitive command if you wish to send or see them.", cookiebuf)
		return Plugin_Handled
	}

	char censmsg[256]
	strcopy(censmsg, sizeof(censmsg), msg)

	char usr[MAX_NAME_LENGTH]
	GetClientName(client, usr, sizeof(usr))

	char fmted[256]
	Format(fmted, sizeof(fmted), "\x07FF0000[!] %s: %s", usr, msg)

	char censfmted[256]
	Format(censfmted, sizeof(censfmted), "\x07FF0000[!] %s: [Hidden, type !sensitive for more information.]", usr)

	int i
	for (i = 1; i <=MaxClients; i++) {
		if (!IsClientConnected(i) || IsFakeClient(i) || !AreClientCookiesCached(i)) {
			continue
		}

		if (team && GetClientTeam(i) != GetClientTeam(client)) {
			continue
		}

		GetClientCookie(i, prefConsentedMsg, cookiebuf, sizeof(cookiebuf))

		if (cookiebuf[0] == 'y') {
			PrintToChat(i, fmted)
			continue
		}

		GetClientCookie(i, prefHideHidden, cookiebuf, sizeof(cookiebuf))
		if (cookiebuf[0] == 'y') {
			continue
		}

		PrintToChat(i, censfmted)
	}

	return Plugin_Handled
}

Action cmdSensitive(int client, int args) {
	if (!AreClientCookiesCached(client)) {
		PrintToChat(client, "[zensitive] Error: Clientprefs have not loaded, cannot open consent window.")
		return Plugin_Handled
	}

	char cookiebuf[6]
	GetClientCookie(client, prefConsented, cookiebuf, sizeof(cookiebuf))

	if (StrEqual(cookiebuf, "never", false)) {
		PrintToChat(client, "[zensitive] You are forbidden from using sensitive messages. Submit a ticket for more information.")
		return Plugin_Handled
	}

	GetClientCookie(client, prefConsentedMsg, cookiebuf, sizeof(cookiebuf))

	Menu consentMenu

	switch (cookiebuf[0]) {
		case 'y': {
			consentMenu = new Menu(revokeMenuCallback)
			consentMenu.SetTitle("Would you like to disable the viewing/sending of sensitive messages?")
			consentMenu.AddItem("revoke", "Yes")
		}

		default: {
			consentMenu = new Menu(consentMenuCallback)
			char msg[512]
			Format(msg, sizeof(msg), "%s\n%s\n \n%s\n%s\n \n%s\n%s\n \n%s\n%s\n ",
				"Sensitive chat allows you to send messages individually",
				"marked as sensitive by prefixing it with a semicolon (;).",
				"Sensitive chat messages may contain sexual/adult content",
				"and are only visible to other users who have opted in.",
				"[!] Opting in and/or using sensitive chat below the age",
				"[!] of eighteen will result in a PERMANENT BAN.",
				"To opt in, type !iam18orolderandwishtoseesensitivechatmessages in chat.",
				"You may opt out at any time by typing !sensitive again."
			)

			consentMenu.SetTitle(msg)
			consentMenu.AddItem("dummy", "I understand.")
		}
	}

	consentMenu.Display(client, MENU_TIME_FOREVER)
	consentMenu.ExitButton = false

	viewedConsent[client] = true

	return Plugin_Handled
}

int consentMenuCallback(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_End) {
			delete menu
	}

	return 0
}

int revokeMenuCallback(Menu menu, MenuAction action, int param1, int param2) {
	switch (action) {
		case MenuAction_Select: {
			// There is one option, so selected will always mean revoked
			if (!AreClientCookiesCached(param1)) {
				PrintToChat(param1, "[zensitive] Error: Clientprefs have not loaded, cannot set consent preference.")
				return 0
			}

			SetClientCookie(param1, prefConsentedMsg, "n")
			PrintToChat(param1, "[zensitive] You have opted-out of seeing sensitive messages. Type !sensitive to opt back in.")
		}

		case MenuAction_End: {
			delete menu
		}
	}

	return 0
}
