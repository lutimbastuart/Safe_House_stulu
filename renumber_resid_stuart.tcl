animate goto 0
set num [molinfo top get numframes]
for {set i 0} {$i < $num} {incr i} {
	set sel [atomselect top protein]
	set start 1053 
	set oresid [ $sel get resid ]
	set delta [ expr $start - [ lindex $oresid 0] ]
	set nresid { }
	foreach r $oresid {
		lappend nresid [ expr $r + $delta ]
	}
	$sel set resid $nresid
}
animate write dcd test.dcd
animate write psf test.psf 
