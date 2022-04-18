proc centering {molwork} {
	set todo [atomselect $molwork "all"]
	set n [molinfo $molwork get numframes]
	for {set i 0} {$i < $n} {incr i} {
		$todo frame $i
		$todo update
		set centro [measure center $todo weight mass]
		$todo moveby [vecscale -1 $centro]
		puts "processing frame $i"
	}
}

proc centering_bila {molwork} {
        set todo [atomselect $molwork "all"]
	set bila [atomselect $molwork "lipid"]
        set n [molinfo $molwork get numframes]
        for {set i 0} {$i < $n} {incr i} {
                $todo frame $i
		$bila frame $i
                set centro [measure center $bila weight mass]
                $todo moveby [vecscale -1 $centro]
                puts "processing frame $i"
        }
}                                  
proc centering1 {molwork} {
        set todo [atomselect $molwork  "all"]
                $todo frame now
                set centro [measure center $todo weight mass]
                $todo moveby [vecscale -1 $centro]
                puts "processing frame"
}

proc selfit1 {molwork sele sel0} {
	        set todo [atomselect $molwork "all"]
	        set sel [atomselect $molwork $sele]
                $sel frame now
                $sel update
                $todo frame now
                $todo move [measure fit $sel $sel0 weight mass]
}

proc selfit {molwork sele} {
	set todo [atomselect $molwork "all"]  
	set sel [atomselect $molwork $sele]
	set sel0 [atomselect $molwork $sele frame 0]
	set nframes [molinfo $molwork get numframes]
	for {set i 0} {$i < $nframes} {incr i} {
		$sel frame $i
		$sel update
		$todo frame $i
		$todo update
		$todo move [measure fit $sel $sel0 weight mass]
	}
}

proc selfitref {molwork molref sele} {
        set todo [atomselect $molwork "all"]
        set sel [atomselect $molwork $sele]
        set sel0 [atomselect $molref $sele]
        set nframes [molinfo $molwork get numframes]
        for {set i 0} {$i < $nframes} {incr i} {
                $sel frame $i
                $sel update
                $todo frame $i
                $todo update
                $todo move [measure fit $sel $sel0 weight mass]
        }
}
		
proc getaxes {xst} {
	global axis
	set idf [open $xst]
	set step 0
	foreach line [split [read $idf] \n] {
		if {[string first # $line] == -1 && [string first 0 $line] != 0} {
		set axis(a,$step) [lindex $line 1]
		set axis(b,$step) [lindex $line 5]
		set axis(c,$step) [lindex $line 9]
		set step [expr {$step + 1}]
		}
	}
	close $idf
}
proc num_density1 {sel zmin zmax nbins {frame1 0} {frame2 -1} {mag 1}} {
	global axis
	set dz [expr {($zmax - $zmin)/$nbins}]
	for {set i 1} {$i <= $nbins} {incr i} {
		set rho($i) 0.0
	}
	set n [molinfo top get numframes]
	if {$frame2 == -1} {
		set frame2 [expr {$n - 1}]
	}
	set totframe [expr {$frame2 - $frame1 + 1}]
	for {set i $frame1} {$i <= $frame2} {incr i} {
		$sel frame $i
		$sel update
#		set step [expr {$i + 1}]
# 		set binvol [expr {$axis(a,$step) * $axis(b,$step) * $dz}]
		set binvol [expr {$axis(a,$i) * $axis(b,$i) * $dz}]
		set coordz [$sel get z]
		foreach coor $coordz {
			set ibin [expr {int(($coor - $zmin)/$dz) + 1}]	
			set rho($ibin) [expr {$rho($ibin) + (1.0/$binvol)}]
		}
		puts "frame $i processed"
			
	}
	set filename num_density
	set idf [open [append filename $sel] w]
	for {set i 1} {$i <= $nbins} {incr i} {
		set zi [expr {$zmin + ($i - 0.5) * $dz}]
		puts $idf "$zi [expr {$mag * $rho($i)/$totframe}]"
	}
	close $idf
}
		
proc get_rmsd_prot {mol frame0 frame1 frame2 step} {
	set ref [atomselect $mol "protein and noh" frame $frame0]
	set curr [atomselect top "protein and noh"]
	set totf [molinfo top get numframes]
       	set filename rmsd_evol
        set idf [open [append filename $mol] w]
        for {set i $frame1} {$i <= $frame2} {incr i} {
	        $curr frame $i
                $curr update
		set matriz [measure fit $curr $ref]
		$curr move $matriz
		set rmsd [measure rmsd $curr $ref]
                puts $idf "[expr {$step*$i}] $rmsd"
		puts "frame $i processed"
        }
        close $idf
}

proc get_rmsd_bb {mol frame0 frame1 frame2 step} {
        set ref [atomselect $mol "protein and alpha" frame $frame0]
        set curr [atomselect top "protein and alpha"]
        set totf [molinfo top get numframes]
        set filename rmsd_alpha_evol
        set idf [open [append filename $mol] w]
        for {set i $frame1} {$i <= $frame2} {incr i} {       
                $curr frame $i
                $curr update
                set matriz [measure fit $curr $ref]
                $curr move $matriz
                set rmsd [measure rmsd $curr $ref]
                puts $idf "[expr {$step*$i}] $rmsd"
                puts "frame $i processed"
        }
        close $idf
}
proc setres {sel key} {
        set i 1
        foreach resid [$sel get resid] name [$sel get name]  {
                if {[string equal $name $key]} {
                        set junk [atomselect top "[$sel text] and resid $resid"]
                        $junk set resid $i
                        incr i
                }
        }
}


atomselect macro dppc "resname DPPC"
atomselect macro lipid2 "lipid or resname DPPC"
atomselect macro headgroup "name P N C11 C12 C13 C14 C15 O11 O12 O13 O14 H1A H2A H1B H2B H3A H3B H3C H4A H4B H4C H5A H5B H5C"
#atomselect macro phosphate "name P O11 O12 O13 O14"
#atomselect macro choline "name N C11 C12 C13 C14 C15 H1A H2A H1B H2B H3A H3B H3C H4A H4B H4C H5A H5B H5C"
#atomselect macro glycerol "name C1 C2 C3 HX HY HR HA HB" 
#atomselect macro carboxyl "name C21 O21 O22 C31 O31 O32"
atomselect macro aromatic2 "aromatic or resname HSD"
atomselect macro mcil "resname MET CYS ILE LEU"
atomselect macro qpn "resname GLN PRO ASN"
atomselect macro hydro2 "resname ALA SER VAL THE GLY HSD"
atomselect macro c16 "name C31 C32 C33 C34 C35 C36 C37 C38 C39 C310 C311 C312 C313 C314 C315 C316"
atomselect macro c18 "name C21 C22 C23 C24 C25 C26 C27 C28 C29 C210 C211 C212 C213 C214 C215 C216 C217 C218"
atomselect macro c316 "name C32 C33 C34 C35 C36 C37 C38 C39 C310 C311 C312 C313 C314 C315 C316"
atomselect macro c216 "name C22 C23 C24 C25 C26 C27 C28 C29 C210 C211 C212 C213 C214 C215 C216"
atomselect macro c218 "name C22 C22 C23 C24 C25 C26 C27 C28 C29 C210 C211 C212 C213 C214 C215 C216 C217 C218"
atomselect macro chain316 "lipid2 and name C32 H2X H2Y C33 H3X H3Y C34 H4X H4Y C35 H5X H5Y C36 H6X H6Y C37 H7X H7Y C38 H8X H8Y C39 H9X H9Y C310 H10X H10Y C311 H11X H11Y C312 H12X H12Y C313 H13X H13Y C314 H14X H14Y C315 H15X H15Y C316 H16X H16Y H16Z"
atomselect macro chain216 "lipid2 and name C22 H2R H2S C23 H3R H3S C24 H4R H4S C25 H5R H5S C26 H6R H6S C27 H7R H7S C28 H8R H8S C29 H9R H9S C210 H10R H10S C211 H11R H11S C212 H12R H12S C213 H13R H13S C214 H14R H14S C215 H15R H15S C216 H16R H16S H16T"
atomselect macro newcholine "name C11 C12 C13 C14 C15 H11 H12 H21 H22 H23 H31 H32 H33 H41 H42 H43 H51 H52 N"
atomselect macro newphosphate "name P1 O1 O2 O3 O4"
atomselect macro newglycerol "name C1 C2 C3 HA HB HS HX HY"
atomselect macro newcarboxyl "name C21 O21 O22 C31 O31 O32"
atomselect macro newheadgroup "name C11 C12 C13 C14 C15 H11 H12 H21 H22 H23 H31 H32 H33 H41 H42 H43 H51 H52 N P1 O1 O2 O3 O4"
atomselect macro guanadine "resname ARG and name CZ NH1 NH2 NE HH11 HH12 HH21 HH22 HE"
atomselect macro newch3 "name C218 H18R H18S H18T C316 H16X H16Y H16Z"
atomselect macro c2a "name C22 H2R H2S C23 H3R H3S C24 H4R H4S C25 H5R H5S C26 H6R H6S C27 H7R H7S C28 H8R H8S"
atomselect macro c2b "name C211 H11R H11S C212 H12R H12S C213 H13R H13S C214 H14R H14S C215 H15R H15S C216 H16R H16S C217 H17R H17S"
atomselect macro cc "name C29 H9R C210 H10R"
atomselect macro c2term "name C218 H18R H18S H18T"
atomselect macro c3a "name C32 H2X H2Y C33 H3X H3Y C34 H4X H4Y C35 H5X H5Y C36 H6X H6Y C37 H7X H7Y C38 H8X H8Y C39 H9X H9Y C310 H10X H10Y C311 H11X H11Y C312 H12X H12Y C313 H13X H13Y C314 H14X H14Y C315 H15X H15Y"
atomselect macro c3term "name C316 H16X H16Y H16Z"



#set env(MSMSSERVER) /Users/jfreites/Code/msms.ppcDarwin6.2.5.5 
