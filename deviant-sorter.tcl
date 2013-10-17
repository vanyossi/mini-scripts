#!/usr/bin/wish
#
# Common variables
#set ::targetDir {/home/tara/data/discos/Odisea/images/stocks/}
#set ::targetDir {/home/tara/data/discos/Odisea/images/d-artist/}
set ::targetDir {/home/tara/nalaf/nala/proyectos/wback/script-testing/deviantSort/}

proc splitIndex { lista } {
 foreach i $lista {
 set pos [string first "_by_" $i]
  if {$pos >= 0} {
   incr pos 4
   lappend elist [concat [string range $i 0 $pos-1] [string range $i $pos end]]
  }
 }
 return $elist
}

proc getAutorDir { str } {
	set autorName [lindex $str 1]
	set divisor [string first "-" $autorName]
	if {$divisor >= 0} {
		set dirName [string range $autorName 0 $divisor-1]
	} else {
		set dirName [file rootname $autorName]
	}
	return $dirName
}

proc makeDirs { elist } {
	foreach i $elist {
		lappend dirlist [file join $::targetDir [getAutorDir $i]]
	}
	#creamos lista con folders únicos
	set unilist [lsort -unique $dirlist]
	#comparamos la lista creada con la original. si encuentra dupicados, crea el directorio.
	foreach i $unilist {
		if { [llength [lsearch -all $dirlist $i]] > 1 } {
			lappend mkdirlist $i
		}
	}
	catch {file mkdir {*}[split $mkdirlist " "]}

	#Si se creo la lista, imprimimos mensaje.
	if { ![catch {llength $mkdirlist}] } {
		puts "mkdirs done"
	}
}

proc moveFiles { elist target } {
	foreach i $elist {
		set dest [getAutorDir $i]
		# dest, probamos que exista el directorio, si no existe, dir== targetDir
		if { [file exists $dest] } {
			set ftarget [file join $target $dest]
		} else {
			set ftarget $target
		}
		set name [join $i ""]
		#puts "[file normalize $name] $ftarget"
		catch {file rename [file normalize $name] $ftarget}
	}
	puts "moving files success! \nexiting..."
	exit
}

#Run program
set sourceList [splitIndex $argv]
makeDirs $sourceList
moveFiles $sourceList $::targetDir
