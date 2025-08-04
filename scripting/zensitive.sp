#include <sourcemod>
#include <clientprefs>
#include <tf2c>
#include <sdktools>

public Plugin myinfo = {
	name = "Zensitive",
	author = "webb <w@spiderden.org>",
	description = "Mark messages as sensitive.",
	version = "v0.0.0",
	url = "https://codeberg.org/moonspub/sp"
}

Handle PrefConsentedMsg
Handle PrefConsented

public void OnPluginStart() {
	PrefConsentedMsg = RegClientCookie("zensitive.consent.message", "User consented to seeing/sending sensitive messages, and attests that they are eighteen or older.", CookieAccess_Protected)
	PrefConsented = RegClientCookie("zensitive.consent", "Currently unused, for a general consent in the future, aside from setting to 'never' to act as a ban from ever consenting for any type.", CookieAccess_Protected)

	RegConsoleCmd("say", CmdSay)
	RegConsoleCmd("say_team", CmdSayTeam)
	RegConsoleCmd("sm_sensitive", CmdSensitive, "Shows a dialog to enable/disable viewing/sending sensitive messages")

	RegAdminCmd("sm_zensitive_never", CmdNeverConsent, ADMFLAG_BAN, "Makes it so a user cannot ever agree to seeing sensitive messages, and revokes if enabled. Steam ID in quotes.")
	RegAdminCmd("sm_zensitive_reset", CmdResetConsent, ADMFLAG_UNBAN, "Resets agree values to default for a given Steam ID. Steam ID in quotes.")
}

public void OnPluginEnd() {
	CloseHandle(PrefConsented)
	CloseHandle(PrefConsentedMsg)
}

Action CmdNeverConsent(int client, int args) {
	if (args == 0) {
		PrintToConsole(client, "No user ID supplied.")
	}

	char id[MAX_AUTHID_LENGTH]
	GetCmdArg(1, id, sizeof(id))

	SetAuthIdCookie(id, PrefConsented, "never")
	SetAuthIdCookie(id, PrefConsentedMsg, "n")
	return Plugin_Handled
}

Action CmdResetConsent(int client, int args) {
	if (args == 0) {
		PrintToConsole(client, "No user ID supplied.")
	}

	char id[MAX_AUTHID_LENGTH]
	GetCmdArg(1, id, sizeof(id))

	SetAuthIdCookie(id, PrefConsented, "")
	SetAuthIdCookie(id, PrefConsentedMsg, "n")
	return Plugin_Handled
}

Action CmdSay(int client, int args) {
	return cmdSay(client, args)
}

Action CmdSayTeam(int client, int args) {
	return cmdSay(client, args, true)
}

Action cmdSay(int client, int args, team=false) {
	if (IsFakeClient(client)) {
		return Plugin_Continue
	}

	char msg[256]
	GetCmdArgString(msg, sizeof(msg))
	StripQuotes(msg)

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
	GetClientCookie(client, PrefConsentedMsg, cookiebuf, sizeof(cookiebuf))

	if (cookiebuf[0] != 'y') {
		PrintToChat(client, "[zensitive] You have not agreed to sending/viewing sensitive messages. Please run the !sensitive command if you wish to send or see them.", cookiebuf)
		return Plugin_Handled
	}

	char censmsg[256]
	strcopy(censmsg, sizeof(censmsg), msg)

	int i
	for (i = 0; i <= sizeof(censmsg); i++) {
		if (censmsg[i] == '\0') {
			break
		}

		if (censmsg[i] == ' ') {
			continue
		}

		censmsg[i] = '*'
	}

	char usr[MAX_NAME_LENGTH]
	GetClientName(client, usr, sizeof(usr))

	char fmted[256]
	Format(fmted, sizeof(fmted), "\x07FF0000[!] %s: %s", usr, msg)

	char censfmted[256]
	Format(censfmted, sizeof(censfmted), "\x07FF0000[!] %s: %s", usr, censmsg)

	for (i = 1; i <=MaxClients; i++) {
		if (!IsClientConnected(i) || IsFakeClient(i) || !AreClientCookiesCached(i)) {
			continue
		}

		if (team && GetClientTeam(i) != GetClientTeam(client)) {
			continue
		}

		GetClientCookie(i, PrefConsentedMsg, cookiebuf, sizeof(cookiebuf))

		if (cookiebuf[0] == 'y') {
			PrintToChat(i, fmted)
		} else {
			PrintToChat(i, censfmted)
		}
	}

	return Plugin_Handled
}

Action CmdSensitive(int client, int args) {
	if (!AreClientCookiesCached(client)) {
		PrintToChat(client, "[zensitive] Error: Clientprefs have not loaded, cannot open consent window.")
		return Plugin_Handled
	}

	char cookiebuf[6]
	GetClientCookie(client, PrefConsented, cookiebuf, sizeof(cookiebuf))

	if (StrEqual(cookiebuf, "never", false)) {
		PrintToChat(client, "[zensitive] You are forbidden from using sensitive messages. Submit a ticket for more information.")
		return Plugin_Handled
	}

	GetClientCookie(client, PrefConsentedMsg, cookiebuf, sizeof(cookiebuf))

	Menu consentMenu

	switch (cookiebuf[0]) {
		case 'y': {
			consentMenu = new Menu(RevokeMenuCallback)
			consentMenu.SetTitle("Would you like to disable the viewing/sending of sensitive messages?")
			consentMenu.AddItem("revoke", "Yes")
		}

		default: {
			consentMenu = new Menu(ConsentMenuCallback)
			consentMenu.SetTitle("This will enable the viewing/sending of sensitive messages. \nSensitive messages may contain sexual/adult content, \nand are only visible to other users who have opted in.\n")
			consentMenu.AddItem("consent", "I wish to see sensitive messages, and I am over the age of eighteen.")
		}
	}

	consentMenu.ExitButton = true

	consentMenu.Display(client, 30)

	return Plugin_Handled
}

int ConsentMenuCallback(Menu menu, MenuAction action, int param1, int param2) {
	switch (action) {
		case MenuAction_Select: {
			// There is one option, so selected will always mean consented
			if (!AreClientCookiesCached(param1)) {
				PrintToChat(param1, "[zensitive] Error: Clientprefs have not loaded, cannot set consent preference.")
				return 0
			}

			SetClientCookie(param1, PrefConsentedMsg, "y")
			PrintToChat(param1, "[zensitive] You have opted-in to seeing sensitive messages. Type !sensitive to opt-out. To send a sensitive message, add a semicolon (;) to the beginning of your message.")
		}

		case MenuAction_End: {
			delete menu
		}
	}

	return 0
}

int RevokeMenuCallback(Menu menu, MenuAction action, int param1, int param2) {
	switch (action) {
		case MenuAction_Select: {
			// There is one option, so selected will always mean revoked
			if (!AreClientCookiesCached(param1)) {
				PrintToChat(param1, "[zensitive] Error: Clientprefs have not loaded, cannot set consent preference.")
				return 0
			}

			SetClientCookie(param1, PrefConsentedMsg, "n")
			PrintToChat(param1, "[zensitive] You have opted-out of seeing sensitive messages. Type !sensitive to opt back in.")
		}

		case MenuAction_End: {
			delete menu
		}
	}

	return 0
}
