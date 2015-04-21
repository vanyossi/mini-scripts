#!/bin/sh
# cmus--remote-notify.sh

# ${1?"Usage: $0 ARGUMENT"}
# check argument is present
if test $# -eq 0
then
	echo 'Script needs at least one option!'
	exit
fi

Cmus_remote=$(cmus-remote -Q)

# return index after given string
get_position () {
	local search_string=$@

	while read -r line
	do
		index=$(expr match "$line" "$search_string")
		if [ $index -gt 0 ]
		then
			break
		fi
	done <<< "$Cmus_remote"

	return $index
}


if test ${#Cmus_remote} -eq 0
then
	# xfce4-terminal --maximize --hide-menubar -x cmus &&
  	# exo-open --launch TerminalEmulator cmus &&
	sleep 2
	# cmus-remote -p
else
	if test $1 = "-S"
	then
		Shuffle="Shuffle On"

		get_position "set shuffle"
		shuffle_is=${line:$?}

		if test $shuffle_is = "true"
		then
			Shuffle="Shuffle Off"
		fi
		notify-send -t 1400 "Cmus notifier" "$Shuffle"

	elif test $1 = "-r"
	then

		get_position "position"
		position=${line:$?}

		if test $position -gt 10
		then
			# overwrite arguments to new position
			set -- "-p"
		fi
	fi

	if test $1 != "-Q"
	then
		cmus-remote $1
	fi

	# get current data and declare associative array
	Cur_song=$(cmus-remote -Q)
	declare -A song_tags

	# Go trough each line and populate associative array
	while read -r line
	do
    	pos=$(expr "$line" : '[a-z]*. ')
    	if test $pos -eq 4
    	then
    		tag_info=${line:$pos}
    		tag_pos=$(expr "$tag_info" : '[a-z_]*. ')
    		tag=${tag_info:0:$tag_pos-1}

    		if test $tag != ' '
    		then
    			song_tags[$tag]=${tag_info:$tag_pos}
    		fi
    	fi
	done <<< "$Cur_song"

	if test $1 = "-Q"
	then
		cmus-updatepidgin artist "${song_tags[artist]}" title "${song_tags[title]}"
	fi

	if test $1 != "-S"
	then
		notify-send -i multimedia-volume-control -t 2200 "${song_tags[title]}" "${song_tags[album]}\n${song_tags[artist]}"
	fi
fi