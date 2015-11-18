#!/usr/bin/wish

#TODO Small Gui, one button, 24x24
#TODO Set name of file and date format.
#TODO Documentation
#TODO Set values from GUI
package require Tk

# We only take one argument, if is a folder and writable
# return folder path
proc parseArgs {} {
    set home [file normalize ~]
    foreach argument $::argv {
        if { [file isdirectory $argument] && [file writable $argument]} {
            return [file normalize $argument]
        }
    }
    return $home
}

# Select folder to save recordings
proc chooseFolder { args } {
    set file [tk_chooseDirectory -initialdir $::tclRecord(record_dir) -title "Choose a directory"]
    # If user press Cancel check if not empty
    if { [file isdirectory $file] } {
        set ::tclRecord(record_dir) $file
    }
    return 0
}

# With all values arrange them into a nice commandline
proc buildCommands { } {

    set ::tclRecord(cmd_real) [list ffmpeg -f x11grab -s 1680x1050 -r 15 -i :0.0 \
        -c:v libx264 -preset ultrafast -pix_fmt yuv420p -vf scale=1280:-1 \
        -an [getName scr_real_] &]

    set ::tclRecord(cmd_timelapse) [list ffmpeg -f x11grab -s 1680x1050 -r 8 -i :0.0 \
        -f yuv4mpegpipe -pix_fmt yuv420p - | yuvfps -s 30:1 -r 30:1 \
        - | ffmpeg -f yuv4mpegpipe -i - -c:v libx264 -preset ultrafast -pix_fmt yuv420p \
        -vf scale=1280:-1 -an [getName scr_tmlps_] &]
}

proc getName { name } {

    cd $::tclRecord(record_dir)
    append outName $name $::tclRecord(date)

    set tmpname $outName

    set s 0
    while {[file exists ${outName}.mp4]} {
        set outName $tmpname
        incr s
        set outName [join [list $outName "_$s"] {} ]
    }
    append outName ".mp4"
    return [file join $::tclRecord(record_dir) $outName]
}

proc startCmd { mode } {

    buildCommands

    catch { set ::tclRecord(cmd_id) [exec {*}$::tclRecord($mode) ]} 
    puts "=============== $::tclRecord(cmd_id)"

    pack forget $::tclRecord(g_ops) $::tclRecord(g_actions).sttime $::tclRecord(g_actions).streal
    pack $::tclRecord(g_actions) $::tclRecord(g_actions).stop -expand 1 -fill both -side top

    lower .
}

proc stopCmd {} {
    catch {exec kill {*}$::tclRecord(cmd_id)}
    exit
}

proc startGui {} {
    set ::tclRecord(g_main) .main

    ttk::frame $::tclRecord(g_main) -borderwidth 5
    pack $::tclRecord(g_main)
    set ::tclRecord(g_actions) [makeActions $::tclRecord(g_main)]
    set ::tclRecord(g_ops) [makeOptions $::tclRecord(g_main)]

    # Do not show .dot files by default. (this does not work for OSX)
    catch { tk_getOpenFile foo bar }
    set ::tk::dialog::file::showHiddenVar 0
    set ::tk::dialog::file::showHiddenBtn 1
}

proc makeActions { w {child ".a"} } {
    append w $child
    ttk::frame $w
    ttk::button $w.streal -text "Realtime" -command { startCmd "cmd_real" }
    ttk::button $w.sttime -text "Timelapse" -command { startCmd "cmd_timelapse" }
    ttk::button $w.stop -text "Stop" -command { stopCmd }

    pack $w
    pack $w.streal $w.sttime -side left

    return $w
}

proc makeOptions { w {child ".o"} } {
    append w $child
    ttk::frame $w
    ttk::button $w.cho_folder -text "Record Dir" -command { chooseFolder }

    pack $w -fill both -expand 1
    pack $w.cho_folder -side top -fill x

    return $w
}

wm title . "Record ffmpeg"

set ::tclRecord(record_dir) [ parseArgs ]
set ::tclRecord(date) [clock format [clock seconds] -format %m%d]

startGui



