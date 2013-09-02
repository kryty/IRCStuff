#------------------------------------------------------------
#
# streams.tcl - script for finding twitch streams
# v1 2.9.2013
#
# This script can be used to search for streams by a
# particular game or just search for streams by a keyword
#
# Written by Toni Järviluoto [git.kryty at gmail.com]
#
# You can find me from QuakeNet irc server
# nick kryty, authed as kry
#
# For help, write !streams -h
#
# Settings:
#
#	basiclimit
# 		how many streams are usually shown
#
#	maxlimit
#		maximum number of streams users are able to query
#
#	defaultgame
#		the game you want the script to default to when no
#		keywords are given
#
#------------------------------------------------------------

# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #
# streams.tcl by Toni Järviluoto. Licensed for unlimited modification     #
# and redistribution as long as this notice is kept intact.               #
# ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### #

package require http
package require tls
package require json

set defaultgame "Quake Live"
set basiclimit "5"
set maxlimit "10"

bind pub - !streams streams:twitchstreams
proc streams:twitchstreams {nick host user chan text} {
	global defaultgame basiclimit maxlimit
	set offset "0"
	set game ""
	set limit $basiclimit
	set search "0"
	
	if {[lindex $text 0] != ""} {
		set i 0
		while {1} {
			if {[lindex $text $i] != ""} {
				puts [lindex $text $i]
				if { [string equal -nocase [lindex $text $i] "-a"] } {
					incr i
					if { [lindex $text $i] != "" } {
						if { [lindex $text $i] > "0" } {
							if {[lindex $text $i] <= $maxlimit} {
								set limit [lindex $text $i]
							} else {
								set limit $maxlimit
							}
						}
					}
				# Didn't manage to get custom queries (like featured streams) to work perhaps because of html embedded into json
				#} elseif { [string equal -nocase [lindex $text $i] "-c"] } {
				#	incr i
				#	if { [lindex $text $i] != "" } {
				#		set customquery [lindex $text $i]
				#	}
				#	incr i
				} elseif { [string equal -nocase [lindex $text $i] "-o"] } {
					incr i
					if { [lindex $text $i] != "" } {
						if {[lindex $text $i] > "0"} {
							set offset [lindex $text $i]
						}
					}
				} elseif { [string equal -nocase [lindex $text $i] "-s"] } {
					set search "1"
				} elseif { [string equal -nocase [lindex $text $i] "-p"] } {
					set chan $nick
				} elseif { [string equal -nocase [lindex $text $i] "-h"] } {
					puthelp "PRIVMSG $nick :Streams script by kryty (authed as kry @QuakeNet)."
					puthelp "PRIVMSG $nick :For default game and query, just use !streams."
					puthelp "PRIVMSG $nick :Currently the script uses $defaultgame as default game and limits the amount of streams to $basiclimit."
					puthelp "PRIVMSG $nick :To change the default game, just do !streams game name here. Notice that this is case sensitive and it needs the full game name."
					puthelp "PRIVMSG $nick :To change the amount of streams shown, add -a # (amount) to the query, # being the number of streams you want. Current maximum of streams shown is $maxlimit."
					puthelp "PRIVMSG $nick :To change the offset of shown streams, use -o # (offset). Shows the streams after given number, for example if you used the basic limit, !streams <optional game name> -o $basiclimit would give the next $basiclimit results."
					puthelp "PRIVMSG $nick :To search for a channel or a game or something, use the handle -s (search). Then just add what you want to search about. Not case sensitive."
					puthelp "PRIVMSG $nick :If you want to keep the channel spam free, add the handle -p (private)."
					#puthelp "PRIVMSG $nick :If you would like to use a custom query, use -c customqueryhere. No spaces allowed, added to query string which asks for results from twitch.tv api. You need to know what you are doing when using this. The query is https://api.twitch.tv/kraken/streams<customqueryhere>&limit=<limithere>&offset=<offsethere>."
					puthelp "PRIVMSG $nick :Examples:"
					puthelp "PRIVMSG $nick :For the basic amount of The Showdown Effect streams with no other setting changed than that, use the following: !streams The Showdown Effect"
					puthelp "PRIVMSG $nick :For top 3 of The Showdown Effect streams on twitch, use the following: !streams The Showdown Effect -c /featured -a 3"
					puthelp "PRIVMSG $nick :Alternative to previous: !streams -a 3 The Showdown Effect"
					puthelp "PRIVMSG $nick :Even this works!: !streams The Showdown -a 3 Effect"
					puthelp "PRIVMSG $nick :For next 3 of The Showdown Effect streams on twitch, use the following: !streams The Showdown Effect -a 3 -o 3"
					puthelp "PRIVMSG $nick :To search for everything unreal on twitch, use the following: !streams -s unreal"
					return
				} else {
					if {$game == ""} {
						set game [lindex $text $i]
					} else {
						append game " " [lindex $text $i]
					}
				}
			} else {
				break
			}
			incr i
		}
	}
	
	if {$game == ""} {
		set game $defaultgame
	}
	
    ::http::register https 443 ::tls::socket
	set gamequery [string map {" " "+"} $game]
	if {$search == "0"} {
		set json_result [json::json2dict [http::data [set t [http::geturl "https://api.twitch.tv/kraken/streams?game=$gamequery&limit=$limit&offset=$offset"]]]]
	} else {
		set json_result [json::json2dict [http::data [set t [http::geturl "https://api.twitch.tv/kraken/search/streams?q=$gamequery&limit=$limit&offset=$offset"]]]]
	}
	#else {
	#	set json_result [json::json2dict [http::data [set t [http::geturl "https://api.twitch.tv/kraken/streams$customquery?limit=$limit&offset=$offset"]]]]
	#}
	
    if {[::http::status $t] != "ok"} { return }
    ::http::cleanup $t
	
	if {$search == "0"} {
		::http::register https 443 ::tls::socket
		set summary [json::json2dict [http::data [set t [http::geturl "https://api.twitch.tv/kraken/streams/summary?game=$gamequery"]]]]
		
		if {[::http::status $t] != "ok"} { return }
		::http::cleanup $t
	}
	
	set streamsfound "0"

	foreach onestream [dict get $json_result "streams"] {
		if {$streamsfound == "0"} {
			puthelp "PRIVMSG $chan :Streams for $game:"

			set streamsfound "1"
		}
		puthelp "PRIVMSG $chan :http://twitch.tv/[dict get $onestream channel name] [dict get $onestream channel status], [dict get $onestream viewers] viewers"
	}
	
	if {$streamsfound == "0"} {
		puthelp "PRIVMSG $chan :No streams for $game"
	} else {
		if {$search == "0"} {
			set streamamount [dict get $summary channels]
			set vieweramount [dict get $summary viewers]
			
			if {$limit > $streamamount} {
				set limit $streamamount
			}
		
			if {$offset == "0"} {
				puthelp "PRIVMSG $chan :Showing $limit out of $streamamount streams. Currently there are $vieweramount unique viewers watching $game. Write !streams -h for help. To prevent channel spam, add -p for private messages."
			} else {
				puthelp "PRIVMSG $chan :Showing $limit out of $streamamount streams after first $offset streams. Currently there are $vieweramount unique viewers watching $game. Write !streams -h for help. To prevent channel spam, add -p for private messages."
			}
		} else {
			puthelp "PRIVMSG $chan :Showing results for search $game. Write !streams -h for help. To prevent channel spam, add -p for private messages."
		}
	}
}

putlog "streams.tcl v1 loaded!"