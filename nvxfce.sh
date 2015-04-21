#!/bin/sh
# First argument is the search string or cmd option

# Folder containing notes
zimConfig="${HOME}/.config/zim/notebooks.list"

# Save selected notbook and rearrange args.
if test $(expr $1 : '[-].*') = 0
	then
	let notebook="$1"
	set -- "${@:2:${#@}}"
else
	notebook="D"
fi

while read -r line
do
	if test "${line::1}" = "$notebook"
	then
		# echo "$line ${line::1}"
		index=$(expr "$line" : '.*.=.')
		noteDir=${HOME}${line:$index}
		# ger last string after '/'
		noteName=${line##*/}
	fi
	# echo $line
done < $zimConfig

cd $noteDir
# ========================

_run_noteApp()	
{
	nohup zim --standalone $noteName "$1" & disown
	exit
}

# USAGE: nvxfce.sh [Notebook number] [option] String to search
# -s search
# -c search content
# no argument, creates new list with argument name given ""

let i=1

# if first argument "-c" searches content and not title
if test $1 = "-c"
then
	search_str="${@:2:${#@}}"
	for filename in $(grep -Hrli "$search_str" *)
	do
		list[$i]="${filename}"
		let i++
	done

elif test $1 = "-s"
then
	# search and replace spaces for '_'
	printf -v nospace "_%s" "${@:2:${#@}}"
	nospace=${nospace:1}

	for filename in *
	do
		if test $(expr match "$filename" "$nospace") -gt 0
			then
			list[$i]="${filename}"
			let i++
		fi
	done
	# printf "%s\n" ${list[@]}
else
	_run_noteApp "$1"
fi

# reset counter
let i=0

# List all containing search string
for f in ${list[@]};
	do
	let i++
	printf "%3d %s\n" $i $f
done

# exits program if no results
if test $i = "0"
	then
	echo "No results found!"
	exit

# if only one item in list, select it
elif test $i = "1"
then
	_run_noteApp ${list[1]%.txt}
	exit
fi

# promt user for selection
printf "\n%s" "Enter your choice (1-${i}) then press [enter] :"
read selection

# If user press empty enter or emulator skips selection,
# this ensures at least one valid selection.
if test -z "$selection"
then
	selection=1
fi

_run_noteApp ${list[$selection]%.txt}

