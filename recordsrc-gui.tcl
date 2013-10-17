#!/usr/bin/wish

#TODO Incremental Filename
#TODO Small Gui, one button, 24x24
#TODO Set name of file and date format.
#TODO Documentation
#TODO Set values from GUI

wm title . "ffmpeg"

set ::date [clock format [clock seconds] -format %m%d]

set cmd1 [list ffmpeg -f x11grab -s 1680x1050 -r 15 -i :0.0 -f alsa -ac 2 -i default -c:v libx264 -preset ultrafast -pix_fmt yuv420p -vf scale=1280:-1 -an n_scr_${::date}.mp4 &]

#set cmd1 {ffmpeg -f x11grab -s 1680x1050 -r 8 -i :0.0 -f alsa -ac 2 -i default -f yuv4mpegpipe -pix_fmt yuv420p - | yuvfps -s 30:1 -r 30:1 - | ffmpeg -f yuv4mpegpipe -i - -c:v libx264 -preset ultrafast -pix_fmt yuv420p -vf scale=1280:-1 -an n_scr_${::date}.mp4 &}

set id [list ps x | grep "ffmpeg -f" | cut -d " " -f 1]

proc startCmd {} {
  global cmd1 id cmdid
  catch [exec {*}$cmd1]
  exec sleep 1
  set cmdres [exec {*}$id]
	set cmdid [split $cmdres \n]
	puts "=============== $cmdid"
  #puts [exec echo $cmdid]
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
  frame .b -bd 5
  pack .b
  #entry .b.input -textvariable comment
  #bind .b.input <Return> { convert $fnames }
  #label .b.label -text "Comment:"
  button .b.start -text "Start" -command { startCmd }
  button .b.submit -text "Stop" -command { stopCmd }
  #button .b.run -text "Select region" -command { takeShot [lindex $fnames 0] }
  #pack .b.label .b.input -side left -expand 1 -fill x
  pack .b.start .b.submit -side left
  #takeShot [lindex $fnames 0]
}

startGui