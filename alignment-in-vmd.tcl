#RMSD computation.
set sel1 [atomselect 0 "backbone"]
        set sel2 [atomselect 1 "backbone"]
        measure rmsd $sel1 $sel2

#A weighting factor can also be calculated.
set weighted_rmsd [measure rmsd $sel1 $sel2 weight mass]

#This measures the rmsd of the two molecules in question. for this case, the in the selection of the sugar "segname CARB" was used for the selection of only the sugar from the system.

## Computing alignment of the for the best fit between molecules. 
#The best  fit alignment to compute for the 4x4 matrix transformation that takes one et of coordinates onto the other.
 set transformation_matrix [measure fit $sel1 $sel2]
# molecule 0 is the same molecule used for $sel1 # To move the whole fragment to which selected molecule is attached
        set move_sel [atomselect 0 all]
        $move_sel move $transformation_matrix
#Then align all molecules of molecule 1 with molecules of 0 using the section made for the specific atoms.

# compute the transformation matrix (A more alternative example) same as the previous.
        set reference_sel  [atomselect 1 all]
        set comparison_sel [atomselect 0 "segname CARB"]
        set transformation_mat [measure fit $comparison_sel $reference_sel]

        # apply it to all of the molecule 1
        set move_sel [atomselect 0 all]
        $move_sel move $transformation_mat

#The refernce atom is the atom to compare to the comparison atom. 
