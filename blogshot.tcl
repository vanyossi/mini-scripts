#!/usr/bin/wish
#----------------:::: Blogcapture ::::----------------------
# IvanYossi colorathis.wordpress.com ghevan@gmail.com  GPL 3.0
#-----------------------------------------------------------
# Goal : Capture screen in full or slices and add a caption.
# Dependencies (that I know of) : scrot, imagemagick, tk 8.5
#-------------------------------------------------------------
# Disclamer: I'm not a developer, I learn programming on spare time. Caution in use.

wm title . "Blogshot"

#User set variables
set ::delay 0
set ::name [exec date +%F-%N]
set ::extension ".png"
set ::suffix "con_"
set ::ofolder "./"

set ::date [exec date +%F]
set ::autor "http://colorathis.wordpress.com"
set ::comment ""
#note extrametas (short for extra metadatas could be writte in imagemagick formatting
#more info { http://www.imagemagick.org/script/escape.php }
set ::extrametas "\n$autor ($date)"

# If set true file tmp file will be deleted,
# when setting a destination for scrot files in arguments files
#   will be kept
set ::delfile true

#We redefine folder input output based on arguments
# scrot output folder
if { [file isdirectory [lindex $argv 0 ]] } {
  set folder [lindex $argv 0 ]
  set ::delfile false
} else {
  set ::folder "/tmp/"
}
#If last argument is a folder change output folder to match
if { [file isdirectory [lindex $argv [llength $argv]-1] ] } {
  set ofolder [lindex $argv [llength $argv]-1 ]
}

#setInputOutput returns a list containing an input and an output filename w/folder
# change folder "/tmp/" value to match any other
proc setInputOutput { name extension { outext ".png"} ofolder folder } {
  global suffix
  #Contruction of input output
  set input ""
  set output ""
  append input $folder $name $extension
  append output $ofolder $suffix $name $outext
  return [lappend input $output]
}
#Declare variable containing input/ouput pair
set fnames [setInputOutput $name $extension $extension $ofolder $folder]

# takeShot, recieves a string folder name, this folder is destination file
proc takeShot { output } {
  global delay argv
  # argument check
  # Window if set drag cursor or select a window to takescreen
  set window ""
  if { [lsearch $argv ":w"] >= 0 } {
    set window "-sb"
  }
  # set delay between, useful for selecting windows/screenarea and take context menu
  if { [lsearch $argv ":d"] >= 0 } {
    set delay [lindex $argv [lsearch $argv ":d"]+1 ]
  }
  catch [eval exec scrot $window -d $delay $output]
  #startGui
}

# convert, Imagemagick actions
proc convert { fnames } {
  global comment extrametas delfile
  #set location of files origin to destination
  set input [lindex $fnames 0]
  set output [lindex $fnames 1]
  #Drop shadow effect
  exec convert $input -bordercolor white -border 10 -gravity SouthWest -background white -splice 0x36 -annotate +10+8 "$comment $extrametas" \( +clone -background black -shadow 80x4+0+0 \) +swap -background none -layers merge +repage $output
  # We delete temporary files
  if { $delfile } { file delete $input }
  exit
}

proc startGui {} {
  global fnames
  frame .b -bd 5
  pack .b
  entry .b.input -textvariable comment
  bind .b.input <Return> { convert $fnames }
  label .b.label -text "Comment:"
  button .b.submit -text "Tag it!" -command { convert $fnames }
  #button .b.run -text "Select region" -command { takeShot [lindex $fnames 0] }
  pack .b.label .b.input -side left -expand 1 -fill x
  pack .b.submit -side right
  takeShot [lindex $fnames 0]
}

startGui
