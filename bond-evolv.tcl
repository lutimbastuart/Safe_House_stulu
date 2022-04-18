ource /nethome/lutimba/vmd/vmd.tcl
set directory /nethome/lutimba/out_ward_fng-systm/simulation/
set mypsf LacY_POPE-combined-FN.psf
set fileprefix npt
set firstdcd 1
set lastdcd 13
set dt 0
set tinit 0.1
set tstep 0.1
set nframes 0
set step 100
set myreference 1
set outfile /nethome/lutimba/out_ward_fng-systm/simulation/analysis/traj/
set ref "protein and backbone"
set idf1 [open MA_set.dat r]
catch {set list [split [read -nonewline $idf1] \n]}
close $idf1
set framefile "$directory$fileprefix"
set molwork [mol new "$directory$mypsf"]
set ref "protein and backbone"
set sel0 [atomselect $molwork $ref frame 0]
animate delete all
foreach object $list {
        set current($object) [atomselect $molwork "protein and ((name [lindex $object 0] and resid [lindex $object 1]) or (name [lindex $object 2] and resid [lindex $object 3]))"]
        puts [$current($object) get {name resid}]
}
foreach object $list {
        set joined [join $object ""]
        set idf2($object) [open LacY-H-outward-${joined}-evol-${firstdcd}-${lastdcd}.dat w]
}
for {set dcdfile $firstdcd} {$dcdfile <= $lastdcd} {incr dcdfile} {
        if {$dcdfile < 10} {
                lappend thefiles "0$dcdfile"
        } else {
                lappend thefiles $dcdfile
        }
}
foreach dcdfile $thefiles {
        set frame 0
        animate read dcd $framefile${dcdfile}.dcd beg $frame end $frame $molwork
while {[molinfo $molwork get numframes] == 1} {
selfit1 $molwork $ref $sel0
                centering1 $molwork
foreach object $list {
                        $current($object) update
                        set coords [$current($object) get {x y z}]
                        set dist [vecdist [lindex $coords 0] [lindex $coords 1]]
                        puts $idf2($object) "[expr {$tinit + $tstep*$dt}] $dist"
                }

                        puts "file $dcdfile frame $frame"
                incr dt
                animate delete all $molwork
                incr frame $step


                animate read dcd $framefile${dcdfile}.dcd beg $frame end $frame $molwork
  }
}
foreach object $list {
        close $idf2($object)
}
puts "I will go build my cluster with black jack and ........."

exit

