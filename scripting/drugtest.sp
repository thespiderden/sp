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

#include <commandfilters>
#include <tf2>

public Plugin myinfo = {
	name = "Drug Test",
	author = "webb <w@spiderden.org>",
	description = "Adds target strings for the GRN and YLW teams.",
	version = VERSION,
	url = "https://codeberg.org/spiderden/sp"
}

public void OnPluginStart() {
	AddMultiTargetFilter("@green", filterClients, "Green Team", false)
	AddMultiTargetFilter("@yellow", filterClients, "Yellow Team", false)
}

public void OnPluginEnd() {
	RemoveMultiTargetFilter("@green", filterClients)
	RemoveMultiTargetFilter("@yellow", filterClients)
}

bool filterClients(const char[] pattern, ArrayList clients) {
	int team = 4 // GRN
	if (StrEqual(pattern, "@yellow")) {
		team = 5 // YLW
	}

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == team) {
			clients.Push(i)
		}
	}

	return true
}
