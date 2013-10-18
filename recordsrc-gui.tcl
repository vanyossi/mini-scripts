#!/usr/bin/wish

#TODO Incremental Filename
#TODO Small Gui, one button, 24x24
#TODO Set name of file and date format.
#TODO Documentation
#TODO Set values from GUI

wm title . "ffmpeg"

set ::date [clock format [clock seconds] -format %m%d]

proc getName { name } {
  set filename "${name}${::date}"
  set tmpname $filename
  
  set s 0
  while {[file exists ${filename}.mp4]} {
    set filename $tmpname
    incr s
    set filename [join [list $filename "_$s"] {} ]
  }
  append filename ".mp4"
  return $filename
}

set ::cmd_real [list ffmpeg -f x11grab -s 1680x1050 -r 15 -i :0.0 -f alsa -ac 2 -i default -c:v libx264 -preset ultrafast -pix_fmt yuv420p -vf scale=1280:-1 -an [getName scr_real_] &]

set ::cmd_timelapse [list ffmpeg -f x11grab -s 1680x1050 -r 8 -i :0.0 -f alsa -ac 2 -i default -f yuv4mpegpipe -pix_fmt yuv420p - | yuvfps -s 30:1 -r 30:1 - | ffmpeg -f yuv4mpegpipe -i - -c:v libx264 -preset ultrafast -pix_fmt yuv420p -vf scale=1280:-1 -an [getName scr_tmlps_] &]

proc startCmd { mode } {
  global cmd1 cmdid
  
  set id [list ps x | grep "ffmpeg -f" | col -h | cut -d " " -f 1]
  append cmd ::cmd _ $mode
  catch [exec {*}[subst $$cmd] ]
  exec sleep 1
  
  set cmdres [exec {*}$id]
  puts $cmdres
  set cmdid [split $cmdres \n]
  puts "=============== $cmdid"
  
  pack forget $::action_frame.sttime $::action_frame.streal
  pack $::action_frame.stop -expand 1 -fill both -side top
}

proc stopCmd {} {
  global cmdid
  #foreach i $cmdid {
	#	exec kill $i
	#}
	# set procid [lindex $cmdid 0]
	catch {exec kill {*}$cmdid}
  exit
}

proc startGui {} {
  global fnames
  set ::action_frame [makeGui .actions]
}

proc makeGui { w } {
  ttk::frame $w -borderwidth 5
  ttk::button $w.streal -text "Realtime" -command { startCmd "real" }
  ttk::button $w.sttime -text "Timelapse" -command { startCmd "timelapse" }
  ttk::button $w.stop -text "Stop" -command { stopCmd }

  pack $w
  pack $w.streal $w.sttime -side left
  
  return $w
}

startGui

