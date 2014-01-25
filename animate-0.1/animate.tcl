# 
# Tcl animate package

package provide animate 0.1

namespace eval ::animate {

	variable animate_values
	variable options
	variable duration 1
	variable fps 60
	variable id 0

	namespace export do
	namespace ensemble create
}

proc ::animate::do { args } {
	package require Tk

	variable animate_values
	variable id

	set anim_sets {}
	set in_values 1
	# args =>
	# 1 list of values*... type, from, to, frames, type... 2 starts with -
	# -fps int, -endscript body,
	foreach el $args {
		if {(![string is double $el] && [string index $el 0] eq {-}) || [llength [split $el] ] > 1 } {
			set in_values 0
			if {[info exist one_value]} {
				lappend anim_sets [::animate::addInterpolationValues $one_value]
				unset one_value
			}
		}
		if {$in_values} {
			if {[lsearch {linear easeinquad easeoutquad easeinoutquad} $el] >= 0 } {
				if {[info exist one_value]} {
					lappend anim_sets [::animate::addInterpolationValues $one_value]
				}
				set one_value $el
				continue
			}
			lappend one_value $el
		} else {
			lappend op_args $el
		}
	}
	if {![info exist op_args]} { return -code error "Missing body argument"}
	set body [::animate::validateOptions $op_args]

	if {[info exist ::animate::options(-time)]} {
			set ::animate::duration $::animate::options(-time)
	} else {
		puts "No -time argument, default 1 second"
	}
	if {[info exist ::animate::options(-fps)]} {
			set ::animate::fps $::animate::options(-fps)
	}

	foreach val $anim_sets {
		lassign $val type from to delay duration
		set frames [expr {ceil(($duration eq {} ? $::animate::duration : $duration) * $::animate::fps)}]
		set frames [expr {$frames < 2 ? 2 : $frames}]
		if {![catch {winfo rgb . $from}]} {
			set interpolated_frames [::animate::getHueEasing $type $from $to $frames] 
		} else {
			set interpolated_frames [::animate::$type $from $to $frames]
		}
		if { $delay ne {} && $delay > 0 } {
			set interpolated_frames [concat [lrepeat [expr {round($delay * $::animate::fps)}] $from] $interpolated_frames]
		}
		lappend interpolated_values $interpolated_frames
	}
	set j 0
	foreach el $interpolated_values {
		incr j
		dict set animate_values $id $j $el
	}
	::animate::doAnimation $body 0 $id
	# puts "this makes linear animation $::animate::animate_values(1) [array names ::animate::options]"
	incr id ; # Give new number for next animation.
}

proc ::animate::doAnimation { body index id } {
	variable animate_values
	variable options

	set array_size [expr {[llength [dict get $animate_values $id] ] / 2 }]
	for {set i 0} { $i < $array_size} { incr i } {
		set j [expr {$i+1}]
		set interp [lindex [dict get $animate_values $id $j] $index]
		set value$j [expr {$interp eq {} ? [lindex [dict get $animate_values $id $j] end] : $interp } ]
		lappend params value$j
		append check_status $interp
	}
	if { $check_status ne {} } {
		eval $body
		# eval [subst $body]
		incr index
		after [expr {1000 / $::animate::fps}] [namespace code [list doAnimation $body $index $id] ]
	} else {
		if {[info exist options(-endscript)]} {
			# we need to wait same amount of time for last command to avoid cutting it in the middle after endscript is unset
			after [expr {1000 / $::animate::fps}] [list eval $options(-endscript)]
			set options(-endscript) {}
		}
		dict unset animate_values $id
	}
}

proc ::animate::addInterpolationValues { alist } {
	if {[llength $alist] > 5} {
		return -code error "More values supplied. type, from, to, seconds"
	} else {
		return $alist
	}
}
proc ::animate::validateOptions { alist } {
	# options: -fps int, -endscript body.
	# last argument is body to run.
	variable options
	# puts $alist
	set ops [lrange $alist 0 end-1]
	if {[llength $ops] % 2 != 0} {
		return -code error "Missing value for arguments $ops"
	} else {
		array set options $ops
	}
	set body [lindex $alist end]
	if { $body eq [lindex $ops end]} {
		return -code error "Missing body to execute"
	}
	return $body
}

#Returns a list with all steps evenly distributed
proc ::animate::linear { from to {frames 30} } {
	#remove one frame to allow min and max to match from to
	set d [expr {double($frames) == 1 ? 1 : double($frames)}]
	for {set i 0 ; set b $from; set c [expr {$to-$from}]} {$i <= $d} {incr i} {
		lappend steps [expr { $c * ($i/$d) + $b }]
	}
	return $steps
}

#Returns a list with all steps gently accelerating
proc ::animate::easeinquad { from to {frames 30} } {
	#remove one frame to allow min and max to match from to
	for {set i 0; set d [expr {double($frames-1)}]; set b $from; set c [expr {$to-$from}]} {$i <= $d} {incr i} {
		set t [expr {$i/$d}]
		lappend steps [expr { $c *$t*$t + $b }]
	}
	return $steps
}

#Returns a list with all steps de-accelerating
proc ::animate::easeoutquad { from to {frames 30} } {
	#remove one frame to allow min and max to match from to
	for {set i 0; set d [expr {double($frames-1)}]; set b $from; set c [expr {$from-$to}]} {$i <= $d} {incr i} {
		set t [expr {$i/$d}]
		lappend steps [expr { $c *$t*($t - 2) + $b }]
	}
	return $steps
}

#Returns a list with values accelerating and de-accelerating
proc ::animate::easeinoutquad { from to {frames 30} } {
	#remove one frame to allow min and max to match from to
	for {set i 0; set d [expr {double($frames-1)}]; set b $from; set c [expr {$to-$from}]} {$i <= $d} {incr i} {
		set t [expr {$i/($d/2)}]
		if {$t < 1} {
			lappend steps [expr {($c/2.)*($t**2) + $b}]
		} else {
			set t [expr {$t-1}]
			lappend steps [expr {(-$c/2.)*($t * ($t-2) - 1 ) + $b }]
			#lappend steps [expr {(-$c/2.)*(-$t * ($t-2) - 1 )+ $b }] # causes to bounce back
		}
	}
	return $steps
}

# Color management functions
# return rgb list value as hex formatted string.
proc mkColor { rgb } {
	set r [lindex $rgb 0]; set g [lindex $rgb 1]; set b [lindex $rgb 2]
 	if {$r < 0} {set r 0} elseif {$r > 255} {set r 255}
    if {$g < 0} {set g 0} elseif {$g > 255} {set g 255}
    if {$b < 0} {set b 0} elseif {$b > 255} {set b 255}
    return [format {#%2.2x%2.2x%2.2x} $r $g $b]
}

# Return intermediate hex colors between from and to.
proc ::animate::getHueEasing { type from to frames } {
	set color1 [winfo rgb . $from]
	set color2 [winfo rgb . $to]

	# Make easing with integers and then transform back to hex
	foreach from $color1 to $color2 channel {r g b} {
		set $channel [::animate::$type $from $to $frames]
	}
	foreach rc $r gc $g bc $b {
		lappend result [mkColor [list [expr {round($rc/255)} ] [expr {round($gc/255)} ] [expr {round($bc/255)}] ] ]
	}
	return $result
}

# Cuadratic interpolation variant ??
# proc ::animate::easeinquad { from to {frames 30} } {
# 	#remove one frame to allow min and max to match from to
# 	for {set i 0; set d [expr {double($frames-1)}]; set b [expr {min($to,$from)}]; set c [expr {abs($to-$from)}]} {$i <= $d} {incr i} {
# 		lappend steps [expr { $c ** ($i/$d) + $b }]
# 	}
# 	if {$to - $from < 0} {
# 		return [lreverse $steps]
# 	}
# 	return $steps
# }