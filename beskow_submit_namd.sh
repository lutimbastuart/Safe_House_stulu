#!/bin/bash -l
# The -l above is required to get the full environment with modules

# The name of the script is myjob
#SBATCH -J TMD-outward+H+
#SBATCH -A 2018-3-39

# dependency
#SBATCH -d singleton

# Only 1 hour wall-clock time will be given to this job
#SBATCH -t 3:00:00

# Number of nodes
#SBATCH -N 16
# Number of MPI processes per node (the following is actually the default)
#SBATCH --ntasks-per-node=32
# Number of MPI processes.
#SBATCH -n 512


#SBATCH --mail-type=BEGIN,END 
#SBATCH --mail-user=lutimba.stuart@scilifelab.se

#SBATCH -e error_file.e
#SBATCH -o output_file.o

#load the NAMD module
module add namd/2.10 

idx=`ls -1 lac-TMD041_*.out | wc -l`
idx2=$(($idx+41))

# Run the executable named myexe 
# and write the output into my_output_file

aprun -n 512  namd2 "lac-TMD0$idx2.inp" > "lac-TMD041_$idx.out"

