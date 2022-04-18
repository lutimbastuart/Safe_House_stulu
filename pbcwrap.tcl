####################################################################
#PBCWRAP:
# --------
#              
# VERSION: 1.4
#
# REQUIREMENTS:
#   The package PBCtools from the VMD script library.
#
# DESCRIPTION:
#   Wraps atoms of selection around PBC unit cell boundaries.  Unit
#   cell geometry is taken from 'molinfo' or can be read from an
#   XST-file.  The first timestep in the XST is omitted, because XST
#   info starts at frame 0 while DCD files start at frame 1 (when both
#   are generated by NAMD). Other than that you must yourself take care
#   that the XST file entries match with the loaded frames.
#
#   If your XST file contains an unitcell with the first vector not
#   being parallel to the x-axis, then VMD will not display the image
#   cells correctly. The reason is, that VMD follows the standard
#   crystallographic conventions for the meaning of
#   a/b/c/alpha/beta/gamma where vector A is assumed to be parallel to
#   X.  Possible problems arise from the fact that NAMD is able to work
#   with nonstandard unitcell geometries. PBCwrap solves this problem by
#   rotating your system accordingly.
#
# PROCEDURES:
#   pbcwrap [OPTIONS...]
#
#   Options:
#     -molid $molid    Wrap molecule $molid (default: "top")
#     -sel $sel	       Wrap the selection $sel of atoms (default: "all")
#     -first $from|now|first
#                      First frame to wrap. "now" denotes the current frame,
#                      "first" denotes the first frame. Otherwise, give the 
#                      number $from of the frame. (default: "now")
#     -last $to|now|last
#                      Last frame to wrap. "now" denotes the current frame, 
#                      "last" denotes the last frame. Otherwise, give the
#                      number $to of the frame. (default: "now")
#     -all             Equal to "-first first -last last".
#     -xst $xstfile    Read the unitcell info from $xstfile. Otherwise, the 
#                      unitcell info has to be set before.
#     -splitresidues   By default atoms will only be wrapped if the entire 
#                      residue lies outside the unit cell. This option can be 
#                      used to override this behaviour.
#     -origin $origin  $origin has to be a Tcl-list containing three numerical 
#                      values $a $b $c. Place the origin of the unitcell at 
#                      ($a*A, $b*B, $c*C). (default: {-0.5 -0.5 -0.5})
#     -positive        Equal to "-origin {0.0 0.0 0.0}".
#     -parallelepiped|-rectangular
#                      Wrap the atoms into the unitcell parallelepiped or the 
#                      corresponding rectangular box. (default: -parallelepiped)
#     (-draw          Draw some test vectors (for debugging))
#
# EXAMPLE USAGE:           
#   require pbcwrap
#   pbcwrap -sel "segname OXY" -xst lox_oxy_equi1-nopi.xst -first 0 -last last
#
#   (This wraps all atoms in the selection $sel around the unitcell defined in the
#    XST file. All loaded frames are processed.)
#
# Author:
#   Jan Saam
#   Institute of Biochemistry, Charite
#   Monbijoustr. 2, Berlin
#   Germany
#   saam@charite.de
#
#   Olaf Lenz
#   olenz _at_ fias.uni-frankfurt.de
#
# Feel free to send comments, bugs, etc.
############################################################
package provide pbcwrap 1.4

proc pbcwrap { args } {
    # Set the defaults
    set molid		"top"
    set userseltext	"all";             # Selection to be wrapped
    set first		"now";             # The first frame to process
    set last		"now";             # The last frame to process
    set xstfile          "";                # Unitcell info from XST file
    set logfile          "stdout";          # Logging output goes here
    set splitresidues	"same residue as"; # Shift entire residues?
    set origin_rel        {-0.5 -0.5 -0.5}; # origin of the unit cell
    set rectangular       0;                # wrap into the rectangular box?
    set draw              0;                # Graphics for debugging?
    
    # Parse options
    for { set argnum 0 } { $argnum < [llength $args] } { incr argnum } {
	set arg [ lindex $args $argnum ]
	set val [ lindex $args [expr $argnum + 1]]
	switch -- $arg {
	    "-molid"      { set molid $val; incr argnum }
	    "-sel"        { set userseltext $val; incr argnum }
            "-first"      { set first $val; incr argnum }
            "-last"       { set last $val; incr argnum }
	    "-all"        { set last "last"; set first "first" }
	    "-log"        { set logfile $val; incr argnum }
	    "-xst"        { set xstfile $val; incr argnum }
	    "-splitresidues" { set splitresidues "" }
	    "-origin"     { set origin_rel $val; incr argnum }
	    "-positive"   { set origin_rel "0.0 0.0 0.0" }
	    "-parallelepiped" { set rectangular 0 }
	    "-rectangular" { set rectangular 1 }
	    "-draw"       { set draw 1 }
	    "-orthogonal" { set rectangular 1 }
    	    "-sheared"    {
		switch -- $val {
		    "yes" { set rectangular 0 }
		    "no" { set rectangular 1 }
		    default { set rectangular [expr ! $val] }
		}
		incr argnum
	    }
	    default { puts "unknown option: $arg"; return }
	}
    }
    
    # Save the current frame number
    set frame_before [ molinfo $molid get frame ]

    if { $molid=="top" } then { set molid [ molinfo top ] }
    if { $first=="now" }   then { set first $frame_before }
    if { $first=="first" } then { set first 0 }
    if { $last=="now" }    then { set last $frame_before }
    if { $last=="last" }   then {
	set last [expr [molinfo $molid get numframes]-1]
    }

    # Set the logging target
    set log "stdout"
    if {$logfile!="none" && $logfile!=0 && $logfile!="stdout"} {
	set log [open $logfile a]
    }
    puts $log "PBCwrap log"
    puts $log "==========="

    # Read the unitcell info from xst file:
    if { [llength $xstfile] }  then {
	puts $log "Reading unit cell info from XST file:"
	puts $log "$xstfile"
	set_unitcell_xst $xstfile -molid $molid -log $log
    }

    display update off

    # Loop over all frames
    for { set frame $first } { $frame <= $last } { incr frame } {
	
	# Switch to the next frame
	molinfo $molid set frame $frame
	
	# get the unit cell data
	set cell [ get_unitcell $molid ]
	set A   [lindex $cell 0]
	set B   [lindex $cell 1]
	set C   [lindex $cell 2]
	set origin [lindex $cell 3]
	set origin [vecadd $origin [ vecscale [lindex $origin_rel 0] $A ] ]
	set origin [vecadd $origin [ vecscale [lindex $origin_rel 1] $B ] ]
	set origin [vecadd $origin [ vecscale [lindex $origin_rel 2] $C ] ]

	# Wrap it
	if { $rectangular } then {
	    set wrapped_atoms \
		[ wrap_to_rectangular_unitcell \
		      $molid $A $B $C $origin $userseltext $splitresidues $draw ]
	} else {
	    set wrapped_atoms \
		[ wrap_to_unitcell \
		      $molid $A $B $C $origin $userseltext $splitresidues $draw ]
	}

	puts $log "frame $frame: Wrapped $wrapped_atoms atoms."
    }
    
    if {$logfile!="none" && $logfile!=0 && $logfile!="stdout"} {
       close $log
    }

    # Rewind to original frame
    animate goto $frame_before
    display update on
    return
}

########################################################
# Wrap the selection $userseltext of molecule $molid   #
# in the current frame into the unitcell parallelepiped#
# defined by $A, $B, $C and $origin.                   #
# When $draw is set, draw some test vectors (for       #
# debugging).                                          #
# $splitresidue contains a partial selection text that #
# is used to avoid splitting resiudes.                 #
# Return the number of atoms that were wrapped.        #
########################################################

proc wrap_to_unitcell { molid A B C origin userseltext splitresidues draw } {
    # The wrapping of atoms is done by transforming the unit cell to a 
    # orthonormal cell which allows to easily select atoms outside the 
    # cell (x<1 or x>1, ...). After wrapping them along the coordinate axes 
    # into the cell, the system is transformed back.
    
    set a1 $A
    set a2 $B
    set a3 $C
    
    if {$draw} {
	# Draw the unitcell vectors.
	#draw delete all
	draw color red
	draw arrow $origin [vecadd $origin $a1]
	draw arrow $origin [vecadd $origin $a2]
	draw arrow $origin [vecadd $origin $a3]
	#set offset [transoffset $ori]
    }
    
    # Orthogonalize system:
    # Find an orthonormal basis (in cartesian coords)
    set obase [orthonormal_basis $a1 $a2 $a3]
    
    if {$draw} {
	# Draw the orthonormal base vectors (scaled by the 
	# length of $a1 to make it visible).
	set ob1 [lindex $obase 0]
	set ob2 [lindex $obase 1]
	set ob3 [lindex $obase 2]
	draw color yellow
	draw arrow $origin [vecadd $origin [vecscale $ob1 [veclength $a1]]]
	draw arrow $origin [vecadd $origin [vecscale $ob2 [veclength $a1]]]
	draw arrow $origin [vecadd $origin [vecscale $ob3 [veclength $a1]]]
    }
    
    # Get $obase in cartesian coordinates (it is the inverse of the
    # $obase->cartesian transformation):
    set obase_cartcoor  [basis_change $obase [list {1 0 0} {0 1 0} {0 0 1}] ]
    
    # Transform into 4x4 matrix:
    set obase2cartinv [trans_from_rotate $obase_cartcoor]
    
    # This is the matrix for the $obase->cartesian transformation:
    set obase2cart  [measure inverse $obase2cartinv]
    
    # Get coordinates of $a in terms of $obase
    set m [basis_change [list $a1 $a2 $a3] $obase]
    set rmat [measure inverse [trans_from_rotate $m]]
    
    # actually: [transmult $obase2cart $obase2cartinv $rmat $obase2cart]
    set mat4 [transmult $rmat $obase2cart [transoffset [vecinvert $origin]]]
    
    # apply the user selection
    set usersel [atomselect $molid $userseltext]

    # Transform the unit cell to a orthonormal cell
    $usersel move $mat4
    
    # Now we can easily select the atoms outside the cell:
    set wrapped_atoms \
	[ expr \
	      [shift_sel $molid "$userseltext and (not $splitresidues (x<1))" {-1 0 0}] + \
	      [shift_sel $molid "$userseltext and (not $splitresidues (x>0))" {1 0 0}] + \
	      [shift_sel $molid "$userseltext and (not $splitresidues (y<1))" {0 -1 0}] + \
	      [shift_sel $molid "$userseltext and (not $splitresidues (y>0))" {0 1 0}] + \
	      [shift_sel $molid "$userseltext and (not $splitresidues (z<1))" {0 0 -1}] + \
	      [shift_sel $molid "$userseltext and (not $splitresidues (z>0))" {0 0 1}] \
	     ]
    
    $usersel move [measure inverse $mat4]
    
    if {$draw} {
	# Draw the transformed unitcell vectors (scaled by the length of $a1)
	# They should lie exactly on top of the orthogonal basis 
	# (drawn before in yellow).
	set c1 [vecscale [coordtrans $mat4 $a1] [veclength $a1]]
	set c2 [vecscale [coordtrans $mat4 $a2] [veclength $a1]]
	set c3 [vecscale [coordtrans $mat4 $a3] [veclength $a1]]
	draw color green
	draw arrow $origin [vecadd $origin $c1]
	draw arrow $origin [vecadd $origin $c2]
	draw arrow $origin [vecadd $origin $c3]
    }

    return $wrapped_atoms
}

########################################################
# Wrap the selection $userseltext of molecule $molid   #
# in the current frame into the rectangular unitcell   #
# defined by $A, $B, $C and $origin.                   #
# When $draw is set, draw some test vectors (for       #
# debugging).                                          #
# $splitresidue contains a partial selection text that #
# is used to avoid splitting resiudes.                 #
# Return the number of atoms that were wrapped.        #
########################################################

proc wrap_to_rectangular_unitcell { molid A B C origin userseltext splitresidues draw } {
    set Ax [lindex $A 0]
    set By [lindex $B 1]
    set Cz [lindex $C 2]

    # apply the user selection
    set usersel [atomselect $molid $userseltext]

    $usersel moveby [vecinvert $origin]

    set wrapped_atoms \
	[ expr \
	      [shift_sel $molid \
		   "$userseltext and (not $splitresidues (z < $Cz))" [vecinvert $C]] + \
	      [shift_sel $molid \
		   "$userseltext and (not $splitresidues (z > 0))" $C] + \
	      [shift_sel $molid \
		   "$userseltext and (not $splitresidues (y < $By))" [vecinvert $B]] + \
	      [shift_sel $molid \
		   "$userseltext and (not $splitresidues (y > 0))" $B] + \
	      [shift_sel $molid \
		   "$userseltext and (not $splitresidues (x < $Ax))" [vecinvert $A]] + \
	      [shift_sel $molid \
		   "$userseltext and (not $splitresidues (x > 0))" $A] \
	     ]

    $usersel moveby $origin
    return $wrapped_atoms
}

########################################################
# Shift the selection $seltext of molecule $molid in   #
# the current frame by $shift, until the selection is  #
# empty.                                               #
########################################################
proc shift_sel { molid seltext shift } {
    set sel [atomselect $molid $seltext]
    set shifted_atoms [$sel num]
    while { [$sel num] > 0 } {
	$sel moveby $shift
	set sel [atomselect $molid $seltext]
    }
    return $shifted_atoms
}


########################################################
# Scale a 4x4 matrix by factors $s1 $s2 $s3 along the  #
# coordinate axes.                                     #
########################################################

proc scale_mat { s1 s2 s3 } {
    set v1 [list $s1 0 0 0]
    set v2 [list 0 $s2 0 0]
    set v3 [list 0 0 $s3 0]
    return [list $v1 $v2 $v3 {0.0 0.0 0.0 1.0}]
}

########################################################
# Returns vector $vec in coordinates of an orthonormal #
# basis $obase.                                        #
########################################################

proc basis_change { vec obase } {
   set dim1 [llength $vec]
   set dim2 [llength [lindex $obase 0]]
   if {$dim1!=$dim2} {
      error "basis_change: dim of vector and basis differ; $dim1, $dim2"
   }
   set cc ""
   foreach i $obase {
      set c ""
      foreach j $vec {
	 lappend c [vecdot $j $i]
      }
      lappend cc $c
   }
   return $cc
}

###################################################
# Find an orthogonal basis R^3 with $ob1=$b1      #
###################################################

proc orthogonal_basis { b1 b2 b3 } {
   set ob1 $b1
   set e1  [vecnorm $ob1]
   set ob2 [vecsub $b2  [vecscale [vecdot $e1 $b2] $e1]]
   set e2  [vecnorm $ob2]
   set ob3 [vecsub $b3  [vecscale [vecdot $e1 $b3] $e1]]
   set ob3 [vecsub $ob3 [vecscale [vecdot $e2 $b3] $e2]]
   #draw color red
   #draw arrow {0 0 0} $b1
   #draw arrow {0 0 0} $b2
   #draw arrow {0 0 0} $b3
   #draw color yellow
   #draw arrow {0 0 1} $ob1
   #draw arrow {0 0 1} $ob2
   #draw arrow {0 0 1} $ob3
   return [list $ob1 $ob2 $ob3]
}


###################################################
# Find an orthogonal basis R^3 with $ob1 || $b1   #
###################################################

proc orthonormal_basis { b1 b2 b3 } {
   set ob1 $b1
   set e1  [vecnorm $ob1]
   set ob2 [vecsub $b2  [vecscale [vecdot $e1 $b2] $e1]]
   set e2  [vecnorm $ob2]
   set ob3 [vecsub $b3  [vecscale [vecdot $e1 $b3] $e1]]
   set ob3 [vecsub $ob3 [vecscale [vecdot $e2 $b3] $e2]]
   set e3  [vecnorm $ob3]
   #draw color red
   #draw arrow {0 0 0} $b1
   #draw arrow {0 0 0} $b2
   #draw arrow {0 0 0} $b3
   #draw color yellow
   #draw arrow {0 0 1} $ob1
   #draw arrow {0 0 1} $ob2
   #draw arrow {0 0 1} $ob3
   return [list $e1 $e2 $e3]
}


######################################
# Just a test for my algorithm...    #
######################################

proc orthogonalizationtest { } {
   package require vmd_draw_arrow
   draw delete all
   set a1 {2 0 3}
   set a2 {0 3 0}
   set a3 {0 2 4}
   # Find an orthonormal basis (in cartesian coords)
   set b [orthonormal_basis $a1 $a2 $a3]
   set b1 [lindex $b 0]
   set b2 [lindex $b 1]
   set b3 [lindex $b 2]
   puts "b = $b"
   # Get coordinates of $b in terms of cartesian coords
   set obase_cartcoor  [basis_change $b [list {1 0 0} {0 1 0} {0 0 1}] ]
   set obase2cartinv [trans_from_rotate $obase_cartcoor]
   set obase2cart  [measure inverse $obase2cartinv]
   set c1  [coordtrans $obase2cart $b1]
   set c2  [coordtrans $obase2cart $b2]
   set c3  [coordtrans $obase2cart $b3]

   draw color purple
   draw arrow {0 0 0} {1 0 0} 0.1
   draw arrow {0 0 0} {0 1 0} 0.1
   draw arrow {0 0 0} {0 0 1} 0.11
   if {0} {
      draw color yellow
      draw arrow {0 0 0} $c1 0.1
      draw arrow {0 0 0} $c2 0.1
      draw arrow {0 0 0} $c3 0.1
   }
   # Get coordinates of $a in terms of $b
   set m [basis_change [list $a1 $a2 $a3] $b]
   puts "m = $m"

   set rmat [measure inverse [trans_from_rotate $m]]
   puts $rmat

   # Scale vectors to their original length
   set smat [scale_mat [veclength $a1] [veclength $a2] [veclength $a3]]
   puts "smat = $smat"

   # Get transformation in cartesian coords
   # actually: [transmult $obase2cart $obase2cartinv $smat $rmat $obase2cart]
   set mat4 [transmult $smat $rmat $obase2cart]
   set c1  [coordtrans $mat4 $a1]
   set c2  [coordtrans $mat4 $a2]
   set c3  [coordtrans $mat4 $a3]

   draw color red
   draw arrow {0 0 0} $a1 0.1
   draw arrow {0 0 0} $a2 0.1
   draw arrow {0 0 0} $a3 0.1
   draw color yellow
   draw arrow {0 0 0} $b1 0.1
   draw arrow {0 0 0} $b2 0.1
   draw arrow {0 0 0} $b3 0.1
   draw color green
   draw arrow {0 0 0} $c1 0.09
   draw arrow {0 0 0} $c2 0.09
   draw arrow {0 0 0} $c3 0.09

}

