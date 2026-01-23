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

## Lumberjack

Lumberjack is yet another Discord connection plugin. It has the ability to log connects/disconnects and chat messages to a Discord channel via a webhook. It also has support for [CallAdmin](https://github.com/Impact123/CallAdmin), acting as an optional replacement for ZipCore's CallAdmin plugin.

The intended way to use this plugin is to create a webhook for each individual server, filling out the avatar and nickname as you see fit on Discord's end, and using each unique webhook URL in the server's respective ``server.cfg``.

### ConVars

``sm_lumberjack_webhook <URL in quotes>`` - URL to log connections, disconnections, and chat messages to.

``sm_lumberjack_calladmin_webhook <URL in quotes>`` - URL to log CallAdmin requests to

``sm_lumberjack_calladmin_webhook_emoji <symbol>`` - Custom symbol to use in place of the ``👉`` in the CallAdmin message. To use a custom emoji, set value to the output in Discord of the custom emoji name prefixed with a backslash (should be something like ``<:foo:69420694206942069420>``.) 

``sm_lumberjack_timeout <number in seconds>`` - Timeout for HTTP requests, in case they get stuck. Defaults to ``15``.

``sm_lumberjack_calladmin_test`` - Sends a dummy CallAdmin webhook for troubleshooting purposes.

## Condify

Apply/remove conditions from other players. Depends on a patched TF2C Sourcemod extension.

### Commands

``sm_condify <target> <condition number>`` - Applies condition to player.

``sm_decondify <target> <condition number>`` - Removes condition from player.

## Admin Caboose

Random utilities for admins.

### Commands

``sm_uid <target>`` - Get Steam ID from target

``sm_steamhistory <target>`` - Gets the steamhistory.net URL of one or more players.
