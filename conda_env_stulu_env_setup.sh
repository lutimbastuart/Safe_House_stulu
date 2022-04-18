#!/usr/bin/bash

#Installation of Conda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh  #minconda
wget https://repo.anaconda.com/archive/Anaconda3-2021.05-Linux-x86_64.sh  #Anaconda

bash Miniconda3-latest-Linux-x86_64.sh

bash Anaconda3-2021.05-Linux-x86_64.sh


#conda create -n htmd1.26.5 htmd=1.26.5 -c acellera -c conda-forge
conda install -c conda-forge -c intbio gromacs=2018.3
amber.python -m pip install gmx_MMPBSA #Installation of mmpbsa 
conda install htmd -c acellera -c conda-forge  #Updating the htmd software. 
conda update -n base conda 
conda install -c anaconda tk
conda install -c conda-forge -c acellera acemd3
conda install -c acellera -c conda-forge htmd 
conda install -c conda-forge openmm
conda install -c conda-forge plumed py-plumed  mdanalysis git
conda install -c conda-forge vmd-python
conda install -c conda-forge ipyleaflet
#jupyter nbextension enable --py --sys-prefix ipyleaflet
#conda install -c conda-forge nglview
#conda install -c conda-forge -c schrodinger pymol-bundle

###Supervised MOlecualr Dyanmics
# Install get_contact_ticc.py dependencies
conda install scipy numpy scikit-learn matplotlib pandas cython
#pip install ticc==0.1.4

# Set up vmd-python library
#conda install -c https://conda.anaconda.org/rbetz vmd-python

# Set up getcontacts library
#git clone https://github.com/getcontacts/getcontacts.git
#echo "export PATH=`pwd`/getcontacts:\$PATH" >> ~/.bashrc
#source ~/.bashrc
#########################
Bechmarking
conda install -c conda-forge mdbenchmark
git clone https://github.com/jgreener64/mmterm
pip install -e .


#NGS anlaysis tool Kit AND Environment 
conda activate NGS_stulu
conda install -c bioconda bwa
conda install -c bioconda samtools
conda install -c bioconda tophat
conda install -c bioconda cufflinks
conda install -c bioconda gatk4
conda install -c bioconda blast
conda install -c bioconda fastqc
conda install -c bioconda bcl2fastq-nextseq
conda install -c bioconda vcftools


 #!/usr/bin/bash

conda config --add channels conda-forge
conda config --set channel_priority strict

conda search r-base

conda install -c conda-forge r-base
conda install -c conda-forge r-tidyverse
conda install -c conda-forge r-ggally

