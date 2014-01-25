#! /usr/bin/env tclsh
#
#
set script_dir [file dirname [file normalize [info script]]]
lappend auto_path [file join $script_dir]

package require animate
package require Tk

proc moveSquare { tag x y mode {end 1} } {
	lassign [makePolygon $x $y 20 4 45] dx1 dy1 dx2 dy2 dx3 dy3 dx4 dy4
	lassign [.c coords $tag] ox1 oy1 ox2 oy2 ox3 oy3 ox4 oy4
	set fill_color [winfo rgb . [.c itemcget $tag -fill]]
	set color_from [expr {$fill_color eq {65535 0 0} ? "red" : "blue" }]
	set color_to [expr {$color_from eq {red} ? "blue" : "red" }]
	set endscript [expr {$end ? {moveSquare rectangle 100 100 easeoutquad 0} : {} }]
	animate do $mode $ox1 $dx1 .02 $mode $oy1 $dy1 $mode $ox2 $dx2 .02 $mode $oy2 $dy2 .02 \
		$mode $ox3 $dx3 $mode $oy3 $dy3 .02 $mode $ox4 $dx4 $mode $oy4 $dy4 $mode $color_from $color_to .5 -time .5 -fps 60 \
			-endscript {} \
		{
			# puts "$value1 $value2 $value3 $value4 $value5 $value6 $value7 $value8"
			.c coords rectangle $value1 $value2 $value3 $value4 $value5 $value6 $value7 $value8
			.c itemconfigure rectangle -fill $value9
		}
	# animate do easeinquad 10 120 linear 30 140 -endscript {puts in} {.c coords rectangle $value1 10 $value2 30}
}
# linear easeinquad easeoutquad

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

canvas .c -width 600 -height 200

.c create polygon [makePolygon 100 100 20 4 45] -fill red -tag rectangle
.c create rect 0 190 600 200 -fill gray40 -tag reset

pack .c

# animate do linear 12 30 linear 20 30 linear 216 25 {puts "$value1 $value2 $value3"}

bind .c <Button-1> { moveSquare rectangle %x %y easeinquad }
.c bind reset <Button-3> {.c coords rectangle [makePolygon 100 100 20 4 45]}

