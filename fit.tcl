proc fitframes { molid seltext } {
  set ref [atomselect $molid $seltext frame 0]
  set sel [atomselect $molid $seltext]
  set all [atomselect $molid all]
  set n [molinfo $molid get numframes]
   
  for { set i 1 } { $i < $n } { incr i } {
    $sel frame $i
    $all frame $i
    $all move [measure fit $sel $ref]
  }
  return
}
