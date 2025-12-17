#!/bin/bash -l

# module environment
source /etc/profile.d/z00_modules.sh
module --force purge
module load ncarenv/23.06
module load intel-classic/2023.0.0
module load ncarcompilers/1.0.0
module load cray-mpich/8.1.25
module load netcdf/4.9.2
module load parallel-netcdf/1.12.3
module load hdf5/1.12.2
module load udunits/2.2.28

# clean previous build
./clean -a

# set environment for WRF Chem build
export WRF_EM_CORE=1
export WRF_KPP=1
export WRF_CHEM=1
export WRF_NMM_CORE=0
export WRFIO_NCD_LARGE_FILE_SUPPORT=1
export FLEX_LIB_DIR=/glade/u/apps/derecho/23.09/opt/view/lib
export FLEX=/glade/u/apps/derecho/23.09/opt/view/bin/flex
export YACC="/glade/u/apps/derecho/23.09/opt/view/bin/yacc -d"
export JASPERLIB=/glade/u/apps/derecho/23.09/spack/opt/spack/jasper/2.0.32/gcc/7.5.0/sptl/lib64
export JASPERINC=/glade/u/apps/derecho/23.09/spack/opt/spack/jasper/2.0.32/gcc/7.5.0/sptl/include
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${JASPERLIB}

# config for option 15 + intel-classic
echo 15 | ./configure

# adding -ltirpc 
awk '/LIB_EXTERNAL[[:space:]]*\+=/{print NR}' configure.wrf | xargs -I {} sed -i '{}a\LIB_EXTERNAL   += -ltirpc' configure.wrf

# adding -DLANDREAD_STUB
sed -i 's/-DMAX_HISTORY=$(MAX_HISTORY) -DNMM_CORE=$(WRF_NMM_CORE)/-DMAX_HISTORY=$(MAX_HISTORY) -DNMM_CORE=$(WRF_NMM_CORE) -DLANDREAD_STUB/g' configure.wrf

# replace bad optimization architecture flags
# (ref: https://ncar-hpc-docs.readthedocs.io/en/latest/compute-systems/derecho/compiling-code-on-derecho/#optimizing-your-code-with-intel-compilers)
sed -i 's/ -xHost/ -march=core-avx2/g' configure.wrf
sed -i 's/ -axHost/ -march=core-avx2/g' configure.wrf
sed -i 's/ -xCORE-AVX2/ -march=core-avx2/g' configure.wrf
sed -i 's/ -axCORE-AVX2/ -march=core-avx2/g' configure.wrf
sed -i 's/-O3/-O3 -march=core-avx2/g' configure.wrf
sed -i 's/-O2/-O2 -march=core-avx2/g' configure.wrf


# compile
./compile em_real 2>&1 |& tee compile-wrf.log
