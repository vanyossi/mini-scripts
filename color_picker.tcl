#! /usr/bin/env tclsh
#
#
# Color picker ring

package require Tk

proc hsvToRgb {h s v} {
    set hi [expr {int(double($h)/60)%6}]
    set f [expr {double($h)/60-$hi}]
    set s [expr {double($s)/255}]
    set v [expr {double($v)/255}]
    set p [expr {double($v)*(1-$s)}]
    set q [expr {double($v)*(1-$f*$s)}]
    set t [expr {double($v)*(1-(1-$f)*$s)}]
    switch -- $hi {
        0 {set r $v; set g $t; set b $p}
        1 {set r $q; set g $v; set b $p}
        2 {set r $p; set g $v; set b $t}
        3 {set r $p; set g $q; set b $v}
        4 {set r $t; set g $p; set b $v}
        5 {set r $v; set g $p; set b $q}
        default {error "[lindex [info level 0] 0]: bad H value"}
    }
    set r [expr {round($r*255)}]
    set g [expr {round($g*255)}]
    set b [expr {round($b*255)}]
    return [list $r $g $b]
}
# Convert RGB to HSV, to calculate contrast colors
# Returns float list => hue, saturation, value, lightness, luma 
proc rgbtohsv { r g b } {
	foreach color {r g b} {
		set ${color}1 [expr {[set ${color}]/255.0}]
	}
	set max [expr {max($r1,$g1,$b1)}]
	set min [expr {min($r1,$g1,$b1)}]
	set delta [expr {$max-$min}]
	set h -1
	set s {}

	lassign [lrepeat 3 $max] v l luma

	if {$delta != 0} {
		set l [expr { ($max + $min) / 2 } ]
		set s [expr { $delta/$v }]
		set luma [expr { (0.2126 * $r1) + (0.7152 * $g1) + (0.0722 * $b1) }]
		if { $max == $r1 } {
			set h [expr { ($g1-$b1) / $delta }]
		} elseif { $max == $g1 } {
			set h [expr { 2 + ($b1-$r1) / $delta }]
		} else {
			set h [expr { 4 + ($r1-$g1) / $delta }]
		}
		set h [expr {round(60 * $h)}]
		if { $h < 0 } { incr h 360 }
	} else {
		set s 0
	}
	return [list $h [format "%0.2f" $s] [format "%0.2f" $v] [format "%0.2f" $l] [format "%0.2f" $luma]]
}

proc mkColor {rgb} {
    set r [lindex $rgb 0]; set g [lindex $rgb 1]; set b [lindex $rgb 2]
    if {$r < 0} {set r 0} elseif {$r > 255} {set r 255}
    if {$g < 0} {set g 0} elseif {$g > 255} {set g 255}
    if {$b < 0} {set b 0} elseif {$b > 255} {set b 255}
    return #[format "%2.2x%2.2x%2.2x" $r $g $b]
}

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

proc makePolyRect { ox oy w {h 0} } {
	# origin is at centre
	set distance_w [expr { $w / 2.0 }]
	set distance_h [expr { $h eq 0 ? $distance_w : $h / 2.0 }]
	set x [expr {$ox - $distance_w}]
	set x1 [expr {$ox + $distance_w}]
	set y [expr {$oy - $distance_h}]
	set y1 [expr {$oy + $distance_h}]

	return [list $x $y $x1 $y $x1 $y1 $x $y1]
}

proc makeTriangle { ox oy r {point 0} } {
	set angle_step [expr {$point / (360.0 / 3)}]

	for {set i 0} { $i < 3 } { incr i } {
		puts [expr {$i + $angle_step}]
		set degree [expr {$i - $angle_step}]
		set angle [expr {( $degree/3 )*(2* 3.1415)}]
		dict set angles x${i} [expr {$r * cos($angle) + $ox}]
		dict set angles y${i} [expr {$r * sin($angle) + $oy}]
	}
	return [dict values $angles]
}

# proc Create canvas {n w h }
proc createCanvas {w wid hei} {
	set ::canvas(main) [canvas $w -width $wid -height $hei]
	$::canvas(main) bind hue <ButtonRelease> {updateSquare %W %x %y}
	# $::canvas(main) bind hue <ButtonRelease> {updateSquare %W %x %y}
	$::canvas(main) bind hue <ButtonPress><Motion> {updateSquare %W %x %y}
	$::canvas(main) bind hue <ButtonRelease><Motion> { 
		foreach id [after info] {
		set Cmd [lindex [after info $id] 0]
		after cancel $Cmd
	}}
	#$::canvas(main) bind hue <ButtonRelease><Motion> {}
	#$::canvas(main) bind hue <Motion> {}
	#$::canvas(main) bind hsv <Button> {selectColor %W %x %y}
	$::canvas(main) bind hsv <ButtonRelease> {selectColor %W %x %y}
	$::canvas(main) bind hsv <ButtonPress><Motion> {selectColor %W %x %y}
	$::canvas(main) bind hsv <ButtonRelease><Motion> { 
		foreach id [after info] {
		set Cmd [lindex [after info $id] 0]
		after cancel $Cmd
	}}
	# $::canvas(main) bind hsv <Motion> {}
	return $w
}

proc drawColorRing { w size } {
	set hues [getHueSwatches $size]
	set arc_size [ makeRect 128 128 220]
	#arc color
	# set ::selected_prev [.c create oval [ makeRect 128 128 300] -outline white -outline gray30 -width 90]
	.c create oval $arc_size -outline gray40 -width 26
	for {set i 0} { $i < $size } { incr i } {
		$::canvas(main) create arc $arc_size -width 22 -style arc -start [expr {$i*360./$size}] -extent [expr {360./$size}] -outline [lindex $hues $i] -tag hue
	}
	set ::selected_hue [.c create arc $arc_size -outline white -start [expr {$i*360./$size}] -style arc -width 22 -extent 1.2]
	set ::selected_prev [.c create polygon 180 256 256 256 256 180 -outline gray40 -fill gray40]
}

proc updateSquare { c x y } {
	# $c delete hsv
	if {[validateSel $c $x $y hue]} {
		set selected [$c find closest $x $y]
		set hex_color [$c itemcget $selected -outline]
		set color_pos [$c itemcget $selected -start]
		set rgb_color [winfo rgb . $hex_color]
		set hue [lindex [rgbtohsv {*}$rgb_color] 0]
		# place cursor on selected color
		puts $color_pos
		set color_pos [expr {$color_pos + (360/($::color_ring_res*2))}]
		puts $color_pos
		$::canvas(main) itemconfigure $::selected_hue -start $color_pos
		changeHSVSquare $::square_res $hue 
		after 10 updateSwatch
	}
}

proc validateSel { c x y group } {
	set selected [$c find closest $x $y]
	set filter [$c find withtag $group]
	return [expr {[lsearch $filter $selected] >= 0 ? 1 : 0}]
}

proc selectColor { c x y } {
	lassign $::canvas_dimension xb yb a ab xb1 yb1 ; # boudaries
	if { $x < $xb }  { set x [expr {$xb+2}]  }
	if { $x > $xb1 } { set x [expr {$xb1-2}] }
	if { $y < $yb }  { set y [expr {$yb+2}]  }
	if { $y > $yb1 } { set y [expr {$yb1-2}] }

	set hex_color [$c itemcget [$c find closest $x $y] -fill]

	$c coords color_cursor [makeRect $x $y 8]
	$c raise color_cursor hsv
	if {[validateSel $c $x $y hsv]} {
		updateSwatch
	}
}

proc updateSwatch {args} {
	set c $::canvas(main)
	#puts [lrange [$c coords color_cursor] 0 1]
	set cursor_origin [getBBoxCenter 8 [lrange [$c coords color_cursor] 0 1]]
	set sel_color [$c find closest {*}$cursor_origin]
	$c itemconfigure $::selected_prev -fill [$c itemcget $sel_color -fill]
	# arc
	# $c itemconfigure $::selected_prev -outline [$c itemcget $sel_color -fill]
}

proc getBBoxCenter { wid xy {h  {}} } {
	lassign $xy x y
	set w [expr {$wid / 2.}]
	set ox [expr {$x + $w}]
	set oy [expr {$y + ($h eq {} ? $w : $h) }]
	return [list $ox $oy]
}
proc drawHSV_Triangle { w wid } {
	set dimension [ makeTriangle 128 128 [expr {$wid/2.}] ]
	$::canvas(main) create polygon $dimension -fill gray40 -tag {hsv}
}

proc drawHSV_Square { w wid hue {res 16} } {
	set ::canvas_dimension [ makePolyRect 128 128 $wid ]
	set ::canvas_steps [getStepsValSat 0 255 $res]
	# set inverse_steps [lreverse $::canvas_steps]
	set width_factor [expr {$wid / double($res)}]
	set origin [lindex $::canvas_dimension 0]
	set width [expr {$origin + $width_factor}]
	set ::canvas(hsv_backdrop) [$::canvas(main) create polygon $::canvas_dimension -fill {} -outline gray40 -width 2]
	# lappend ::canvas_dimension {*}[lrange $::canvas_dimension 0 3]
	# puts $::canvas_dimension
	# for {set i 0} {$i < 8} {incr i} {
	# 	if {[lindex $::canvas_dimension $i+3] eq {}} { break }
	# 	$::canvas(main) create line [lindex $::canvas_dimension $i] [lindex $::canvas_dimension $i+1] [lindex $::canvas_dimension $i+2] [lindex $::canvas_dimension $i+3]
	# }

	drawTiles_Square $origin $width $width_factor $hue $res
}

proc drawTiles_line { alist index} {
	# set values [lindex $alist $index]
	# if { $values ne {} } {
	# 	incr index
		# lassign $values hue saturation value coord
		# array set v $values
		# $::canvas(main) create rect \
		# 	$v(x) $v(y) $v(x1) $v(y1) -fill [mkColor [hsvToRgb $v(hue) $v(saturation) $v(value) ]] -outline {} -tag {hsv}
		# $::canvas(main) create rect \
		# 	$x $y $x1 $y1 -fill [mkColor [hsvToRgb $hue $saturation $value ]] -outline {} -tag {hsv}
		# set i 0
		# set tag_holder [$::canvas(main) find withtag hsv]
		foreach values $alist {
			lassign $values hue saturation value coord
			$::canvas(main) itemconfigure $::color_hsv_coords($coord) -fill [mkColor [hsvToRgb $hue $saturation $value ]]
		}

		# after idle [list after 0 [list drawTiles_line $alist $index]]
	# }
}

proc drawTiles_Modules { calcs type res } {
	lassign $calcs steps origin width width_factor
	# type will be used to draw either triangle or square
	for {set i 0} { $i < $res } { incr i } {
	 	for {set j 0} { $j < $res } { incr j } {
	 		# apend x y x1 y1 hue saturation value position
	 		lappend coords [list \
				[expr {$origin+($i*$width_factor)}] \
				[expr {$origin+($j*$width_factor)}] \
				[expr {$width+($i*$width_factor)}] \
				[expr {$width+($j*$width_factor)}] \
				$i.$j \
			]
		}
	}
	foreach el $coords {
		lassign $el x y x1 y1 coord
		set ::color_hsv_coords($coord) [$::canvas(main) create rect \
		 	$x $y $x1 $y1 -fill grey60 -outline {} -tag {hsv} ]
	}
}

proc drawTiles_Square { origin width width_factor hue res } {
	if { [$::canvas(main) type hsv] eq {} } {
		drawTiles_Modules [list $::canvas_steps $origin $width $width_factor] square $res
		$::canvas(main) create oval [makeRect 128 128 8] -outline white -tag {color_cursor}
	}
	
	changeHSVSquare $res $hue
	
}

proc changeHSVSquare { res hue } {
	set reverse_list [lreverse $::canvas_steps] ; # ensures correct progression of value
	for {set i 0} { $i < $res } { incr i } {
	 	for {set j 0} { $j < $res } { incr j } {
			lappend colors [list \
				$hue \
				[lindex $::canvas_steps $i] \
				[lindex $reverse_list $j] \
				$i.$j \
			]
	 	}
	}
	after idle [list drawTiles_line $colors 0]
}

# get color swatches based on divider (256, 512)
proc getHueSwatches { size } {
	set saturation 255
	set value 255
	for {set i 0} { $i < $size } { incr i } {
		lappend values [mkColor [hsvToRgb [expr { $i * (360. / $size)} ] $saturation $value]]
	}
	return $values
}

proc getStepsValSat { origin dest size } {
	set c [expr {$dest - $origin}]
	for {set i 0} { $i <= $size } { incr i } {
		lappend values [expr { ($i * (double($c) / $size)) + $origin } ]
	}
	return $values
}


pack [createCanvas .c 256 256]
set ::color_ring_res 180
drawColorRing $::canvas(main) $::color_ring_res
# drawHSV_Triangle $::canvas(main) 198
set ::square_res 36 ; # 36
set ::square_size 134
drawHSV_Square $::canvas(main) $::square_size 0 $::square_res
# set initial color tests
set hsv_vals [rgbtohsv {*}[winfo rgb . "#45a845"]]
set ihue [lindex $hsv_vals 0]
set isat [lindex $hsv_vals 1]
set ivalue [lindex $hsv_vals 2]

changeHSVSquare $::square_res $ihue
#puts [expr {abs($::square_size * (($ivalue/257)-1) - 61)}]
#puts [format {%f %f} [expr {$::square_size * $isat + 61 }] [expr {abs($::square_size * (($ivalue/257)-1) - 61)}]]
$::canvas(main) coords color_cursor [makeRect [expr {$::square_size * $isat + 61 }] [expr {abs($::square_size * (($ivalue/257)-1) - 61)}] 8]
$::canvas(main) itemconfigure $::selected_hue -start $ihue
after 10 updateSwatch