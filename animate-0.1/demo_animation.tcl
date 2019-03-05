#! /usr/bin/env tclsh
#
#
set script_dir [file dirname [file normalize [info script]]]
lappend auto_path [file join $script_dir]

package require animate
package require Tk

# load images.
proc loadImages {} {
	set image_clouds [image create photo -file [file join . demo castle_clouds.gif]]
	set image_castle [image create photo -file [file join . demo castle_view.gif]]
	set image_hero [image create photo -file [file join . demo castle_hero.gif]]

	.c create image 900 350 -image $image_clouds -tag clouds
	.c create image 700 300 -image $image_castle -tag castle
	.c create image -200 300 -image $image_hero -tag hero

	run_animation1
}
proc run_animation1 {} {
	.c raise moon bg
	animate do linear #010006 #130f35 linear 700 600 .2 4 easeinoutquad 0 400 0 4.2 linear 900 600 -time 5 -fps 30 -endscript {run_animation2 0} {
		.c itemconfigure bg -fill $value1
		.c coords castle $value2 300
		.c coords hero $value3 300
		.c coords clouds $value4 350
	}
	# clouds advance 120 each second
	# Double animation break al subsequent animations.
	# animate do linear 900 300 -time 7.8 -fps 12 {
	#  	.c coords clouds $value1 350
	# }
}
proc run_animation2 { index } {
	incr index
	set cloud_coords [lindex [.c coords clouds] 0]
	if { $index <= 2 } {
		animate do linear #d4d4a4 #130f35 linear $cloud_coords [expr {$cloud_coords - (.1 * 8 * 7.5)}] -time .1 -fps 30 -endscript [list run_animation2 $index] {
			.c itemconfigure bg -fill $value1
			.c coords clouds $value2 350
		}
	} else {
		.c raise bg hero
		animate do linear #e4e4a4 black -time 2.2 -fps 12 -endscript run_animation3 {
		 	.c itemconfigure bg -fill $value1
		}
	}
}
proc run_animation3 { } {
	.c create text [expr {1310/2}] 250 -text {} -fill white -font "Arial 20 bold" -tag text

	after 800
	set string "And this is how it all began..."
	animate do linear 0 [expr {[string length $string]-1}] -time 3 -fps 14 -endscript run_animation4 {
		set string_s [.c itemcget text -text]
		#we duplicate string as current implementation does not import variable scopes.
		set letter [string index "And this is how it all began..." [expr { round($value1)}] ]
		if {[string length $string_s] <= [expr round($value1)] } {
			.c itemconfigure text -text [append string_s $letter]
		}
	}
}
proc run_animation4 {args} {
	animate do easeoutquad white black 1 -time 2 -fps 50 {
		.c itemconfigure text -fill $value1
	}
}
canvas .c -width 1310 -height 546 -highlightthickness 0 -borderwidth 0 -insertborderwidth 0 -insertwidth 0
pack .c

.c create oval 128 128 150 150 -fill #d4d4a4 -outline {} -tag moon
.c create rect 0 0 1310 546  -fill black -tag bg

after 10 loadImages