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

#include <sdktools>
#include <tf2>

public Plugin myinfo = {
	name = "Graylmao",
	author = "webb <w@spiderden.org>",
	description = "Sets unassigned player's skins to gray.",
	version = VERSION,
	url = "https://codeberg.org/spiderden/sp"
}

public void OnPluginStart() {
	HookEvent("player_spawn", onPlayerSpawn)
}

void onPlayerSpawn(Event event, char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"))

	if (GetClientTeam(client) == 0) {
		SetEntProp(client, Prop_Send, "m_bForcedSkin", true);
		SetEntProp(client, Prop_Send, "m_nForcedSkin", 8);
	}
}
