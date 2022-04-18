##measure of bond  over trajectories
measure bond {3 5} molid 4 frame all

## Calculation of dihedral angles in the LacY system over the simulation length (trajectories)
measure dihed {3 2 6 5} molid 4 frame all
set dihelist [measure dihed {3 2 6 5} molid 4 frame all]

#For the selection of specific atoms (Phe27) in the LacY system following TMD.

set dihelist [measure dihed {385 374 371 391} molid 4 frame all] #This calculates the dihedrals of the specified list given throuhg the entire trajectory. If the trajectory file is morethan one refere to the dihedral script.


#The calculation of the center of mass of substrate molecule at last configilation from the equilbration steps.
set sel [atomselect "serial 1 to 105"] # This conciders the list of atoms not the integers.
set center [measure center $sel weight mass]

set sel [atomselect top "segname CARB"]
set center [measure center $sel weight mass]


