#!/usr/bin/wish
#cmus remote control
#variables
set cmus "/usr/bin/cmus"
set cmusr "/usr/bin/cmus-remote"
global cmus
global cmusr

#widow name
wm title . "Cmus control"

#procesos

#puts $test
if { [catch {exec cmus-remote -Q} ] } {
 exec terminal -e cmus ; exec sleep 2; exec cmus-remote -p
}

proc stop {} {
  global cmusr
  exec killall cmus &
}

proc next {} {
  global cmusr
  exec $cmusr -n &
  notify
  Log
}

proc prev {} {
  global cmusr
  exec $cmusr -r &
}

proc pause {} {
  global cmusr
  exec $cmusr -u &
}
#shuffle functions
proc shuffleon { } {
  global cmusr Shuffle
  set Shuffle "Shuffle On"
  exec $cmusr -S &
  set isshuf [eval exec "cmus-remote -Q | grep shuffle | cut -d { } -f 3"] ;
  if { $isshuf == "false" } {
    set Shuffle "Shuffle off"
  }
}

#notify-osd
proc notify { } {
  set Cur_song [ exec cmus-remote -Q | grep tag | head -n 3 | sort -r | cut -d { } -f 3-]
  exec notify-send -i multimedia-volume-control -t 1800 $Cur_song
}
#log music
proc Log { } {
  global log
  set line [exec cmus-remote -Q | grep tag | head -n 3 | sort -r | cut -d { } -f 3- | column -c 150]
  $log insert end $line\n
  $log see end
  #puts [exec cmus-remote -Q | grep tag | cut -d { } -f 3- | column]
}
#cmus-remote -Q | grep tag | head -n 3 | sort -r | cut -d ' ' -f 3- | column -c 100
#open file
set types {
    {"Music Files"          {.mp3 .ogg } }
    {"All files"            *}
}

proc onSelect { } {
    global types   
    set file [tk_getOpenFile -filetypes $types -parent .]
    exec cmus-remote -f $file
}

wm title . "openfile"

proc screen {} {
  frame .top -borderwidth 10
  pack .top -fill x	
  button .top.shuffle -text "Shuffle" -textvariable Shuffle -command shuffleon
  button .top.next -text "Next" -command next
  button .top.prev -text "Prev" -command prev
  button .top.pause -text "Pause" -command pause
  button .top.file -text "Select a file" \
        -command "onSelect"
  pack .top.prev .top.pause .top.next .top.shuffle .top.file -side left -padx 0p -pady 0
  global log
  frame .t
  set log [text .t.log -width 130 -height 10 \
	-borderwidth 2 -relief raised -setgrid true \
	-yscrollcommand {.t.scroll set}]
  scrollbar .t.scroll -command {.t.log yview}
  pack .t.scroll -side right -fill y
  pack .t.log -side left -fill both -expand true
  pack .t -side top -fill both -expand true
}
screen
shuffleon