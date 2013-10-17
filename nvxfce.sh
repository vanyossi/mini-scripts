#!/bin/sh
#First argument is the search string or cmd option
#Folder containing notes
noteDir=/home/tara/nalaf/nala/Dropbox/PlainText/Notational/

#library
_prep_search_res()
{
	#Take substring using sed (or awk)
	#prints entries as newlines, finds line selected, removes extension txt
	#note=$(echo $list | tr ' ' '\n' | sed -n ${1}p | sed 's%^\(.*\)\.txt$%\1%')
	#prints entries as newlines, finds line selected, removes dir characters and extension
	note=$(echo $list | tr ' ' '\n' | sed -n  -e "${1}s%^\./\(.*\)\.txt$%\1%p" -e "${1}s%^\(.*\)\.txt$%\1%p" )
	#prepares selection for open in zim, uses spaces and colons instead of slash
	note=$(echo $note | tr '_' ' ' | tr '/' ':')
	#removes first 2 and last 4
	#echo "${note:2:${#note}-6}"
	#removes last characters
	#"${note%.txt}"
	#Comand to run
	_run_noteApp "$note"
}
_run_noteApp()	
{
	zim Notational "$1"
	exit
}
#Do if argument is
#	-s search
# -c search content
# no argument, creates new list with argument name given ""

#change to note directory to perform searchs
cd $noteDir
#if first argument "-c" searches content and not title
if [ "$1" == "-c" ];then
	list=$(grep -ri "$2" * -l)

elif [ "$1" == "-s" ];then
	#searech and replace: simple "tr ' ' '_'" but prone to error
	#other way "sed 's/\s/_/g'"
	nospace=$(echo "$2" | tr ' ' '_')
	#use "ls -c" if sort by last mod date
	#list=$(ls -1 --show-control-chars | grep -i "$nospace")
	list=$(find . -iname "*${nospace}*")
else
	_run_noteApp "$1"
fi;
#counter
number=0

#List all containing search string
for f in $list;
	do
	number=$(expr $number + 1)
	echo $number $f	
done

#exits program if no results
if [ $number == "0" ]; then
	echo "No results found!"
	exit
#if only one item in list, select it
elif [ $number == "1" ];then
	_prep_search_res $number
	exit
fi

#promt user for selection
echo -n "		Enter your choice (1-${number}) then press [enter] :"
read selection

# If user press empty enter or emulator skips selection,
# this ensures at least one valid selection.
if [ -z "$selection" ];then
	selection=1
fi

_prep_search_res $selection

