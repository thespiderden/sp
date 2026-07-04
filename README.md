# sp

This repository contains plugins written for the spider den and Moon's Pub.  

Unless specified otherwise, code in this repository is licensed under the AGPLv3 license. You can find this in the COPYING file.

The code style should be roughly in line with Go's.

To build, use the makefile with SPCOMP64 set to the absolute path to your spcomp64 binary under scripting/. If you're running Windows you can run make using WSL, or manually compile the file. You may need to manually install dependencies.

## Class Consciousness

A stable class wars plugin for TF2C, properly supporting all classes and four-team with no known exploits. Depends on a patched TF2C Sourcemod extension.

Under the hood, it internally stores class values for each team instead of using a ConVar.

### ConVars

``sm_cc_enable <0/1>`` - Toggles enforcement of class restrictions

``sm_cc_rolls <0/1>`` - Toggles whether the plugin automatically rerolls the selected classes on each round.

``sm_cc_unirolls <0/1>`` - When sm_cc_rolls is enabled, role one class for all teams.

### Commands

``sm_cc_change <red/blue/green/yellow/all> <class>`` - Changes the selected class for all or one particular team (also accessible via ``!cc_change``)

``sm_classes``/``!classes`` - Prints the currently selected classes for each team.

``sm_cc_roll``/``!cc_roll`` - Rerolls classes, regardless of if ``sm_cc_rolls`` is enabled.

## Zensitive

Implements the sensitive chat system. Users can mark chat messages as sensitive by prefixing it with a semicolon (``;``.) Only users who have opted in can see sensitive chat messages.

Either works standalone, or with Meta Chat Processor. 

### Commands

``sm_sensitive``/``!sensitive`` - Display opt-in consent dialog.

``sm_hidehidden``/``!hidehidden`` - Hide sensitive chat message placeholders if not opted in. 

``sm_zensitive_never <Steam ID in quotes>`` - Makes it so a user cannot ever agree to seeing sensitive messages, and revokes if enabled. Effectively acts as a ban.

``sm_zensitive_reset <Steam ID in quotes>`` - "Factory resets" a user to default values. Undoes the effects of *``sm_zensitive_never``* (so can also act like an unban.)

## IDlesslessness

Makes players without Steam IDs unable to chat or spray. Includes a command to kick all IDless players. Optionally can kick them after a period of time after being put in game if they don't still have one.

### ConVars

``sm_idlln_kicktolerance <time in seconds>`` - How many seconds after a player joins should their Steam ID be checked and kicked if they don't have one? Lower value means more false positives, higher 
value means bad actors can stay in the server longer. Negative values means this feature is disabled.

### Commands

``sm_kickidless`` - Kicks all IDless players

## Lumberjack

Lumberjack is yet another Discord connection plugin. It has the ability to log connects/disconnects and chat messages to a Discord channel via a webhook. It also has support for [CallAdmin](https://github.com/Impact123/CallAdmin), acting as an optional replacement for ZipCore's Discord CallAdmin module. Only depends on [ripext](https://github.com/ErikMinekus/sm-ripext) which has official amd64 builds.

The intended way to use this plugin is to create a webhook for each individual server, filling out the avatar and nickname as you see fit on Discord's end, and using each unique webhook URL in the server's respective ``server.cfg``.

### ConVars

``sm_lumberjack_webhook <URL in quotes>`` - URL to log connections, disconnections, and chat messages to.

``sm_lumberjack_calladmin_webhook <URL in quotes>`` - URL to log CallAdmin requests to

``sm_lumberjack_calladmin_webhook_emoji <symbol>`` - Custom symbol to use in place of the ``👉`` in the CallAdmin message. To use a custom emoji, set value to the output in Discord of the custom emoji name prefixed with a backslash (should be something like ``<:foo:69420694206942069420>``.) 

``sm_lumberjack_calladmin_test <0/1>`` - Sends a dummy CallAdmin webhook for troubleshooting purposes.

``sm_lumberjack_timeout <number in seconds>`` - Timeout for HTTP requests, in case they get stuck. Defaults to ``15``.

``sm_lumberjack_log_chat <0/1>``- Toggles logging of chat messages.

``sm_lumberjack_log_connections <0/1>`` - Toggles logging of player connections.

``sm_lumberjack_log_disconnections <0/1>`` - Toggles logging of player disconnections.

``sm_lumberjack_log_decals <0/1>`` - Toggles spray logging. When enabled, the first occurance of a spray for a given map/connection will log the spray hex/file. Useful for determining sprays manually from the server without the use of other plugins.

``sm_lumberjack_log_mapchanges <0/1>`` - Toggles logging of map changes.

``sm_lumberjack_log_renames <0/1>`` - Toggles logging of player name changes/renames.

## Stuffify

Do various stuff to players. Depends on a patched TF2C Sourcemod extension.

### Commands

``sm_condify <target> <condition number>`` - Applies condition to player.

``sm_decondify <target> <condition number>`` - Removes condition from player.

``sm_classify <target> <class>`` - Change player's class in-place without changing weapons

``sm_reclassify <target> <class>`` - Change player's class and change/restock weapons

``sm_regenify <target>`` - Regenerates a player, behaves as if they touched a resupply cabinet

``sm_respawnify <target>`` - Immediately respawns player

``sm_teamify <target> <team>`` - Changes player's team, killing them in the process

## Admin Caboose

Random utilities for admins.

### Commands

``sm_uid <target>`` - Get Steam ID from target.

``sm_uid64 <target>`` - Get 64-bit/community Steam ID from target.

``sm_steamhistory/sm_history <target>`` - Gets the steamhistory.net URL of target.

``sm_opensteamhistory/sm_openhistory <target>`` - Shows steamhistory.net URL of target in-game via a MOTD panel.

``sm_sprayid <target>`` - Gets the spray hex/ID/filename from a player.

## Rat Poison

Specify which players are allowed to spray. Whitelisted players are specified in the ``sourcemod/configs/ratpoison.whitelist.cfg`` file. One Steam ID per line.

``sm_ratpoison_enable <0/1>`` - Whether the plugin enforces the whitelist or not.

``sm_ratpoison_reload`` - Reloads the configuration file.

## Drug Test

Adds ``@green`` and ``@yellow`` target strings for commands. Simply load the plugin to enable.


## Nag

Lets you show custom webpages via the MOTD panel alongside a text fallback in case they have HTML MOTDs disabled.

The configuration is located at sourcemod/configs/nags.cfg.

```
// Moon's Pub sample

"nags"
{
	"nsfw"
	{
		"url"	"https://moonspub.github.io/nag/nsfw/"
		"textfallback" "[MP] WARNING: We don't allow NSFW content in sprays, text chat, or voice chat. Posting NSFW content can result in a sprayban, mute, or permanent removal from our community."
		"forcespec" "y"
	}

	"micspam"
	{
		"url"	"https://moonspub.github.io/nag/micspam/"
		"textfallback" "[MP] WARNING: We don't allow micspam for most players outside of proximity voice chat as it can render global voice chat difficult to use, especially for admins who cannot mute people."
		"forcespec" "y"
	}
}
```

### Commands

``sm_nag <target> <nag name>`` - Shows specified nag to player

``sm_nag_reload`` - Reloads the nag configuration file

## DJ Stick

DJ Stick implements the "Current DJ" system on Moon's Pub. It allows whitelisted DJs
to mark themselves as the current micspammer.

The whitelist is located at ``sourcemod/configs/djstick.whitelist.cfg``. One Steam ID
per line.

### ConVars

``sm_djstick_timeout`` - Number of seconds of voice inactivity before removing active DJ status (default: 120.)

``sm_djstick_hudcolour_r/g/b <0-255>`` - Colour to use for HUD text.

``sm_djstick_hudpos_x/y <0.0-1.0/-1.0>`` - Position to use for HUD text (-1.0 is centred.)

### Commands

#### Admin

``sm_djstick_reload`` - Reload whitelist

``sm_djstick_force/sm_forcedj <target>`` - Force a certain player to be DJ, regardless of whitelist status

``sm_djstick_revoke/sm_revokedj <target>`` - Forces the current DJ to abandon their active DJ status.

#### User

``sm_dj`` - Prints the current DJ.

``sm_claimdj`` - Claim DJ if whitelisted.

``sm_abandondj`` - Abandon DJ status if currently the DJ.
