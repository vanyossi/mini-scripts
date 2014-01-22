#! /usr/bin/env tclsh
#
# Small countdown test
#
package require Tk

set ::zerotime [clock scan 00:00:00 -format %T]
set ::timer_control(previous_y) 0

scan 5:00 %d:%d m s
set ::timer [expr {($m * 60) + $s}]
set ::time [clock format [expr {$::zerotime + $::timer}] -format %T]

puts [clock format [clock seconds] -format %T]

proc makeRect { ox oy w {h 0} } {
	# origin is at centre
	set distance_w [expr { $w / 2.0 }]
	set distance_h [expr { $h eq 0 ? $distance_w : $h / 2.0 }]
	set x [expr {$ox - $distance_w}]
	set x1 [expr {$ox + $distance_w}]
	set y [expr {$oy - $distance_h}]
	set y1 [expr {$oy + $distance_h}]

	return [list $x $y $x1 $y1]
}

# Creates a regular polygon with (s)= sides
proc makePolygon { ox oy r s {rotation 0} } {
	set pi [expr {acos(-1)}]
	set angle_step [expr {$rotation * ($pi / 180)}]

	for {set i 0} { $i < $s } { incr i } {
		set angle [expr {( $i/($s/1.0) )*(2 * $pi)}]
		lappend vectors [expr {($r * cos($angle - $angle_step)) + $ox }]
		lappend vectors [expr {($r * sin($angle - $angle_step)) + $oy }]
	}
	return $vectors
}
# Create acute triangle (w)idth (h)eight (r)otation
proc makeTriangle { ox oy w h {r 0} } {
	set distance [expr { $w / 2.0 }]
	set x [expr {$ox - $distance}]
	# set y $oy
	# set x1 $ox
	if {$r} {
		set y1 [expr {$oy + $h}]
	} else {
		set y1 [expr {$oy - $h}]
	}
	set x2 [expr {$ox + $distance}]
	# set y2 $oy
	return [list $x $oy $ox $y1 $x2 $oy]
}

# Rotate polygonal object
# from http://wiki.tcl.tk/8595
proc rotatePoly {w tag Ox Oy ang} {
	#foreach {Ox Oy} [object_center $w $tag] break
	set ang [expr {$ang * atan(1) / 45.0}] ;# Radians
	set sin [expr {sin($ang)}]
	set cos [expr {cos($ang)}]
	foreach id [$w find withtag $tag] {     ;# Do each component separately
		set xy {}
		foreach {x y} [$w coords $id] {
			# rotates vector (Ox,Oy)->(x,y) by angle clockwise
			set x [expr {$x - $Ox}] ;# Shift to origin
			set y [expr {$y - $Oy}]
			set xx [expr {($x * $cos - $y * $sin) + $Ox}] ;# Rotate and shift back
            set yy [expr {(-$x * $sin + $y * $cos) + $Oy}]
			lappend xy $xx $yy
		}
		$w coords $id $xy
	}
 }

set arc_size [makeRect 128 118 196]
set ::window_thumb [canvas .thumbnail -width 256 -height 256 -background grey88]
$::window_thumb create oval $arc_size -outline gray94 -width 26
set ::canvas_arc_object_bg [$::window_thumb create oval $arc_size -outline {lime green} -width 20]
set ::canvas_arc_object [$::window_thumb create arc $arc_size -width 20 -style arc -start 90 -extent -360 -outline {lime green} ]

$::window_thumb create oval 12 210 52 250 -outline gray60 -fill gray94 -width 2 -tag stop
$::window_thumb create oval 206 210 246 250 -outline gray60 -fill gray94 -width 2 -tag start
$::window_thumb create polygon [makePolygon 226 230 12 3] -fill gray60 -tag {start start_button start_style}

$::window_thumb create polygon [makePolygon 32 230 13 4 45] -fill gray60 -outline {} -tag {stop stop_button}

$::window_thumb create rect [makeRect 220 230 7 18] -fill gray60 -outline {} -tag {start pause_button start_style}
$::window_thumb create rect [makeRect 232 230 7 18] -fill gray60 -outline {} -tag {start pause_button start_style}
# hide pause button below button circle
$::window_thumb lower pause_button start

set ::canvas_text_object [$::window_thumb create text 128 118 -text $::time -justify center \
 	-font "FiraSans 32" -tag texto]
 	puts [$::window_thumb bbox texto]
set type [list hour minute second]
for {set i 0} {$i < 3} { incr i } {
	$::window_thumb create rect [expr {52 + ($i * 53)}] 100 [expr {96 + ($i * 53)}] 136 -fill {} -outline {} -tag [list [lindex $type $i] text]
	$::window_thumb create polygon [makeTriangle [expr {75 + ($i * 53)}] 100 30 12] -fill gray80 -tag [list [lindex $type $i]_add add mod_time]
	$::window_thumb create polygon [makeTriangle [expr {75 + ($i * 53)}] 136 30 12 1] -fill gray80 -tag [list [lindex $type $i]_less less mod_time]
}
$::window_thumb create text 128 58 -text "" -justify center -font "FiraSans 16" -tag hover_text
#rotatePoly $::window_thumb point_down 128 128 180

bind . <KeyPress> { keySetTime %K }
bind . <KeyPress-m> { convertTime %K }
bind . <KeyPress-h> { convertTime %K }
bind . <KeyPress-s> { convertTime %K }
# bind . <Key> { puts %K }
bind . <Return> { startTimer $::timer }
bind . <KP_Enter> { startTimer $::timer }
bind . <space> { startTimer $::timer }

bind . <BackSpace> { stopTimer }

$::window_thumb bind start <Button-1> {startTimer $::timer}
$::window_thumb bind start <Enter> {$::window_thumb itemconfigure start_style -fill gray40}
$::window_thumb bind start <Leave> {$::window_thumb itemconfigure start_style -fill gray60}
$::window_thumb bind stop <Enter> {$::window_thumb itemconfigure stop_button -fill gray40}
$::window_thumb bind stop <Leave> {$::window_thumb itemconfigure stop_button -fill gray60}
$::window_thumb bind stop <Button> {stopTimer}
$::window_thumb bind text <ButtonPress> { $::window_thumb bind text <Motion> {defineDirection %W x %x  y %y Y %%y} }
$::window_thumb bind text <ButtonRelease> { $::window_thumb bind text <Motion> {} }
$::window_thumb bind text <Button-4> {defineDirection %W x %x y %y dir 1}
$::window_thumb bind text <Button-5> {defineDirection %W x %x y %y dir 0}
$::window_thumb bind add <Button-1> {defineDirection %W x %x y %y dir 1}
$::window_thumb bind less <Button-1> {defineDirection %W x %x y %y dir 0}
$::window_thumb bind mod_time <Enter> {elementHover $::window_thumb %x %y mod_time {-fill #b80000} {-fill gray80} }
$::window_thumb bind mod_time <Motion> {elementHover $::window_thumb %x %y mod_time {-fill #b80000} {-fill gray80} }
$::window_thumb bind mod_time <Leave> {elementHover $::window_thumb %x %y mod_time {-fill gray80} {-fill gray80} }
$::window_thumb bind mod_time <Button-1> {elementHover $::window_thumb %x %y mod_time {-fill #f82a2a} {-fill gray80} }
$::window_thumb bind mod_time <Button-1><ButtonRelease> {elementHover $::window_thumb %x %y mod_time {-fill #b80000} {-fill #b80000} }

proc validateSel { c x y group } {
	set selected [$c find closest $x $y]
	set filter [$c find withtag $group]
	return [expr {[lsearch $filter $selected] >= 0 ? 1 : 0}]
}

proc elementHover { c x y tag value value2} {
	if {[validateSel $c $x $y $tag]} {
		$c itemconfigure [$c find closest $x $y] {*}$value
	} else {
		foreach item  [$c find withtag $tag] {
			$c itemconfigure $item {*}$value2
		}
	}
}
proc markerTurnRed { c type dir } {
	catch {after cancel $::timer_cmds(button_active)}
	set dir [expr {$dir ? "add" : "less"}]
	$c itemconfigure ${type}_$dir -fill #f82a2a
	set ::timer_cmds(button_active) [after 200 [list $c itemconfigure ${type}_$dir -fill gray80] ]
}
proc keySetTime { k } {
	catch {after cancel $::timer_cmds(key_set)}
	if {[string is digit $k]} {
		set text [$::window_thumb itemcget hover_text -text]
		append text $k
		$::window_thumb itemconfigure hover_text -text $text
	}
	set ::timer_cmds(key_set) [after 5000 [list $::window_thumb itemconfigure hover_text -text {}]]
}

proc convertTime { k } {
	set time [$::window_thumb itemcget hover_text -text]
	if {[string is digit -strict $time]} {
		set text $time$k
		$::window_thumb itemconfigure hover_text -text $text
		switch -nocase -- $k {
			s { }
			m { set time [expr {$time *60}] }
			h { set time [expr {$time *3600}] }
		}
		$::window_thumb itemconfigure $::canvas_text_object -text [clock format [expr {$::zerotime + $time}] -format %T]
		set ::timer $time
		after 1000 [list $::window_thumb itemconfigure hover_text -text {}]
	}
}

# x y && (Y || dir )
proc defineDirection { c args } {
	array set vars $args

	set type [lindex [$c itemcget [$c find closest $vars(x) $vars(y)] -tag] 0]
	switch -glob -- $type {
		hour*   { set ops [list 3600 6] }
		minute* { set ops [list 60 4] }
		second* { set ops [list 1 2] }
	}
	lassign $ops multiplier rate

	if {![info exist vars(dir)]} {
		if {($vars(Y) % $rate) != 0 } { 
			set ::timer_control(previous_y) $vars(Y)
			return
		} ; # dont do anything if movement to close.
		set vars(dir) [expr {$::timer_control(previous_y) > $vars(Y) ? 1 : 0}]
	}
	addTime $c $multiplier $vars(dir)
	markerTurnRed $c $type $vars(dir)
}

# Adds n number of seconds to timer and display the results
proc addTime { c multiplier dir } {
	set op [expr {$dir ? {(1 * %1$d ) + %2$d} : {%2$d - (1 * %1$d )} }]

	set work_time [expr [format $op $multiplier [expr {$::running ? $::seconds : $::timer }] ]]
	# calculate new time. we check if supplied time is less than our zero time to add a day.
	set new_time [expr {($::zerotime + $work_time) < $::zerotime ? $::zerotime + 86400 + $work_time : $::zerotime + $work_time} ]
	#Before setting global seconds: conform time to one day time frame.
	set one_day_time [expr {$new_time - $::zerotime}]
	set work_time [expr { $one_day_time > 86400 ? $one_day_time - 86400 : $one_day_time }]

	$::window_thumb itemconfigure $::canvas_text_object -text [clock format $new_time -format %T]

	if {$::running} {
		calcRoundRate $work_time
	} else {
		set ::timer $work_time
	}
}

# Exit safe function, called when windo is destroyed
# sets global stop to on, then exit.
proc killrunning {args} {
	set ::big_break 1
	exit
}
# We dont use every in this case
#-- The indispensable [every] timer:
# proc every {ms body} {
# 	{*}$body
# 	if {$::big_break} { return }
# 	lappend ::cmds [after $ms [info level 0] ]
# }

# Set counter to current seconds, and reduce by one afterweards
proc minusOne {args} {
	set time [clock format [expr {$::zerotime + $::seconds}] -format %T]
	$::window_thumb itemconfigure $::canvas_text_object -text $time
	if {[clock scan $time -format %T] eq $::zerotime} {
		set ::big_break 1
		stopTimer
	}
	incr ::seconds -1
}

# return rgb list value as hex formatted string.
proc mkColor { rgb } {
	set r [lindex $rgb 0]; set g [lindex $rgb 1]; set b [lindex $rgb 2]
 	if {$r < 0} {set r 0} elseif {$r > 255} {set r 255}
    if {$g < 0} {set g 0} elseif {$g > 255} {set g 255}
    if {$b < 0} {set b 0} elseif {$b > 255} {set b 255}
    return [format {#%2.2x%2.2x%2.2x} $r $g $b]
}

#Returns a list with all steps evenly distributed
proc linearEase { from to {frames 24} } {
	#remove one frame to allow min and max to match from to
	for {set i 0; set d [expr {double($frames-1)}]; set b $from; set c [expr {$to-$from}]} {$i <= $d} {incr i} {
		lappend steps [expr { $c * ($i/$d) + $b }]
	}
	return $steps
}

# Return intermediate hex colors between from and to.
proc getHueEasing { from to size } {
	set color1 [winfo rgb . $from]
	set color2 [winfo rgb . $to]

	# Make easing with integers and then transform back to hex
	foreach from $color1 to $color2 channel {r g b} {
		set $channel [linearEase $from $to $size]
	}
	foreach rc $r gc $g bc $b {
		lappend result [mkColor [list [expr {round($rc/255)} ] [expr {round($gc/255)} ] [expr {round($bc/255)}] ] ]
	}
	return $result
}

# cancel cue commands by name
proc cancelIdle { string } {
	set findings [list]
	foreach id [after info] {
		set Cmd [lindex [after info $id] 0]
		if {[lsearch -glob $Cmd $string ] >= 0 } {
			after cancel $Cmd
			lappend findings $Cmd
			puts $Cmd
		}
	}
	return $findings
}

proc applyColor { color_list i } { 
	if {[set color [lindex $color_list $i]] ne {} } {
		$::window_thumb itemconfigure $::canvas_arc_object -outline $color
		incr i
		lappend ::cmds [after 33 [list applyColor $color_list $i]]
	}
}

proc goRound { } {
	set ::timer_cmds(main_cmd) [info level 0]
	if {$::j == 0} {
		set ::j $::round_step
		# we run colorchange animation when time matches
		if { $::seconds == $::half } { set colors [getHueEasing {lime green} #0bb269 30] }
		if { $::seconds == $::quarter } { set colors [getHueEasing [$::window_thumb itemcget $::canvas_arc_object -outline] #e8a407 30] }
		if { $::seconds == $::quarter2} { set colors [getHueEasing [$::window_thumb itemcget $::canvas_arc_object -outline] #f0520f 30] }
		if { $::seconds == $::quarter4} { set colors [getHueEasing [$::window_thumb itemcget $::canvas_arc_object -outline] #c11217 30] }
		if {[info exists colors]} {
			# for small times we first cancel pending operations
			cancelIdle *applyColor*
			applyColor $colors 0
		}
		minusOne
	}
	set ::current [expr {$::current + $::step}]
	$::window_thumb itemconfigure $::canvas_arc_object -extent $::current
	incr ::j -1
	if {!$::big_break} {
		after $::every_step [list goRound]
	}
}

proc calcRoundRate { seconds } {
	# We reset the bar back to 100% if user modifies time more than original.
	if { [info exists ::total] && $seconds > $::total } {
		set ::current -360.
		set color [$::window_thumb itemcget $::canvas_arc_object -outline]
		set colors [getHueEasing $color {lime green} 30]
		applyColor $colors 0
	}
	set ::seconds $seconds
	if { $::seconds < 60 } {        set multi 1
	} elseif { $::seconds < 301 } { set multi 10
	} elseif { $::seconds < 601 } { set multi 50
	} else {
		set multi 100
	}

	set ::total $::seconds
	set ::half [expr {int($::total / 2.)}]
	set ::quarter [expr {int($::total / 4.)}]
	set ::quarter2 [expr {int($::total / 8.)}]
	set ::quarter4 [expr {int($::total / 16.)}]
	set ::quarter8 [expr {int($::total / 32.)}]

	set extent_steps [expr {abs($::current / $::seconds)}]
	set ::every_step [expr { 10 * $multi }]

	set ::round_step [expr { 100 / $multi }]
	set ::step [expr {$extent_steps / $::round_step}]
}

proc startTimer {seconds} {
	catch {stopTimer}
	set ::running 1
	set ::big_break 0
	set ::pause 0
	$::window_thumb bind start <Button-1> {pauseTimer}
	$::window_thumb lower start_button start
	$::window_thumb raise pause_button start
	$::window_thumb itemconfigure $::canvas_arc_object_bg -outline white
	$::window_thumb itemconfigure $::canvas_arc_object -outline {lime green}
	bind . <KP_Enter> {pauseTimer}
	bind . <Return> {pauseTimer}
	bind . <space> { pauseTimer }

	set ::current -360.
	calcRoundRate $seconds

	set ::j 0 ; #for goRound first check

	after idle goRound
}

proc pauseTimer {} {
	switch -- $::pause {
		0 {
			# Cancel all time operations but store the cmd for resume
			set ::timer_cmds(resume) [cancelIdle *goRound*]
			set ::pause 1
		}
		1 {
			# Resume all operations
			foreach process $::timer_cmds(resume) { after idle $process }
			set ::pause 0
		}
	}
}
proc stopTimer {args} {
	puts [clock format [clock seconds] -format %T]
	# First we stop all timing operations pending
	set ::running 0
	cancelIdle *goRound*

	$::window_thumb bind start <Button-1> {startTimer $::timer}
	$::window_thumb raise start_button start
	$::window_thumb lower pause_button start
	$::window_thumb itemconfigure $::canvas_text_object -text [clock format [expr {$::zerotime + $::timer}] -format %T]
	$::window_thumb itemconfigure $::canvas_arc_object -extent 360 -outline {lime green}
	$::window_thumb itemconfigure $::canvas_arc_object_bg -outline {lime green} ; # or #35b200

	bind . <Return> { startTimer $::timer }
	bind . <KP_Enter> { startTimer $::timer }
	bind . <space> {  }
}

wm protocol . WM_DELETE_WINDOW { killrunning }
pack $::window_thumb
set ::running 0