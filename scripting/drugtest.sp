/*
Copyright (C) 2026 webb

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
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
