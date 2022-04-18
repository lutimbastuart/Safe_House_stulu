
#To get the mass of the molecule## This returns the total mass of the selected molecule Usage is get_total_mass or get_total_mass 2
proc get_total_mass {{molid top}} {
	eval "vecadd [[atomselect $molid all] get mass]"
}

#To get the charge usage is get_total_charge or get_total_charge2
#To get the total charge of the molecule.
proc get_total_charge {{molid top}} {
	eval "vecadd [[atomselect $molid all] get charge]"
}

#To make a colorscale bar of the presatation
## 
##PROCEDURES:
##color_scale bar
proc color_scale_bar {length width min max label_num } {

display update off

# draw the color bar
set start_y [expr -0.5 * $length]
set step [expr $length / ([colorinfo max] * 1.0) ]

for {set colorid [colorinfo num] } { $colorid <= [colorinfo max] } {incr colorid 1 } {
	draw color $colorid
	set cur_y [ expr $start_y + ($colorid - [colorinfo num]) * $step ]
	draw line " 0 $cur_y 0 "  " $width  $cur_y  0 "
}

# draw the labels
set coord_x [expr 1.2*$width];
set step_size [expr $length / $label_num]
set color_step [expr ([colorinfo max] * 1.0)/$label_num]
set value_step [expr ($max - $min ) / double ($label_num)]

for {set i 0} {$i <= $label_num } { incr i 1} {

	set cur_color_id white
	draw color $cur_color_id
	set coord_y [expr $start_y+$i * $step_size ]
	set cur_text [expr $min + $i * $value_step ]
	draw text  " $coord_x $coord_y 0"  [format %6.2f  $cur_text]
}

display update on
}

proc morph_linear {t N} {
  return [expr {double($t) / double($N)}]
}
proc morph_cycle {t N} {
  global M_PI
  return [expr {(1.0 - cos( $M_PI * double($t) / ($N + 1.0)))/2.0}]
}
proc morph_sin2 {t N} {
  global M_PI
  return [expr {sqrt(sin( $M_PI * double($t) / double($N) / 2.0))}]
}



proc morph {molid N {morph_type morph_linear}} {
    # make sure there are only two animation frames
    if {[molinfo $molid get numframes] != 2} {
	error "Molecule $molid must have 2 animation frames"
    }
    # workaround for the 'animate dup' bug; this will translate
    # 'top' to a number, if needed
    set molid [molinfo $molid get id]

    # Do some error checking on N
    if {$N != int($N)} {
	  error "Need an integer number for the number of frames"
    }
    if {$N <= 2} {
	  error "The number of frames must be greater than 2"
    }

    # Get the coordinates of the first and last frames (there are only 2)
    set sel1 [atomselect $molid "all" frame 0]
    set sel2 [atomselect $molid "all" frame 1]
    set x1 [$sel1 get x]
    set y1 [$sel1 get y]
    set z1 [$sel1 get z]
    set x2 [$sel2 get x]
    set y2 [$sel2 get y]
    set z2 [$sel2 get z]

    # Make N-2 new frames (copied from the last frame)
    for {set i 2} {$i < $N} {incr i} {
	  animate dup frame 1 $molid
    }
    # there are now N frames

    # Do the linear interpolation in steps of 1/N so
    # f(0) = 0.0 and f(N-1) = 1.0
    for {set t 0} {$t < [expr $N -1]} {incr t} {
	  # Here's the call to the user-defined morph function
	  set f [$morph_type $t $N]
	  # calculate the linear interpolation for each coordinate
	  # go to the given frame and set the coordinates
	  $sel1 frame $t
      $sel1 set x [vecadd [vecscale [expr {1.0 - $f}] $x1] [vecscale $f $x2]]
      $sel1 set y [vecadd [vecscale [expr {1.0 - $f}] $y1] [vecscale $f $y2]]
      $sel1 set z [vecadd [vecscale [expr {1.0 - $f}] $z1] [vecscale $f $z2]]
   } 
}


