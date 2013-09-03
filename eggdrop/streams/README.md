A TCL script for eggdrop that gives gets n number Twitch.tv streams for a queried game or query.

You'll need to have your eggdrop configured with tcl8.5 and also install tcllib for json parser.

Write *!streams -h* for help.

Change the variables defaultgame, basiclimit and maxlimit as you see fit. Don't set too high maxlimit, because that is an easy way to get your bot banned from a channel.

Currently defaulted to following values:
set defaultgame "Quake Live"
set basiclimit "5"
set maxlimit "10"
