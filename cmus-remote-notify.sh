#!/bin/sh
Cmus_remote=$(cmus-remote -Q)

Instance=$(echo -e "$Cmus_remote" | wc -l)
if [ $Instance = 1 ]; then
	# xfce4-terminal --maximize --hide-menubar -x cmus &&
  	# exo-open --launch TerminalEmulator --fullscreen cmus &&
	terminal -e cmus &&
	sleep 2
	cmus-remote -p
else
	if [ $1 == "-S" ]; then
		Shuffle="Shuffle On"
		if [ `echo "$Cmus_remote" | grep shuffle | cut -d ' ' -f 3` == true ]; then
			Shuffle="Shuffle Off"
		fi
		notify-send -t 800 "Cmus notifies:" "$Shuffle"
	elif [ $1 == "-r" ]; then
		position=$(echo "$Cmus_remote" | grep position | cut -d ' ' -f 2)
		if [ $position -gt 10 ]; then
			# overwrite arguments to new position
			set -- "-p"
		fi
	fi

	if [ $1 != "-Q" ]; then
		cmus-remote $1
	fi

	# get current data and declare associative array
	Cur_song=$(cmus-remote -Q)
	declare -A song_tags

	# Go trough each line and populate associative array
	while read -r line; do
    	pos=$(expr "$line" : '[a-z]*. ')
    	if [ $pos -eq 4 ]; then
    		tag_info=${line:$pos}
    		tag_pos=$(expr "$tag_info" : '[a-z_]*. ')
    		tag=${tag_info:0:$tag_pos-1}
    		if [ $tag != ' ' ]; then
    			song_tags[$tag]=${tag_info:$tag_pos}
    		fi
    	fi
	done <<< "$Cur_song"

	if [ $1 == "-Q" ]; then
		cmus-updatepidgin artist "${song_tags[artist]}" title "${song_tags[title]}"
	fi

	notify-send -i multimedia-volume-control -t 2200 "${song_tags[title]}" "${song_tags[album]}\n${song_tags[artist]}"
fi
