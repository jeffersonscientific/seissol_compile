#!/bin/bash
#
#SBATCH --name=compile_seissol
#SBATCH --partition=serc
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --time=12:00:00
#SBATCH --constraint=CPU_MNF:AMD
#
# WHAT IS THIS?
# an early prototype compile script for SeisSol. It falls apart pretty quickly, but with improved understanding SeisSol using the Spack
#  build packages, maybe we could make this (or something like it) work. That said, i'd skip to using Spack for the core elements.
#
#. /home/groups/s-ees/share/cees/spack_cees/scripts/cees_sw_setup-beta.sh
#
module purge
#
module load system math
#
##module load intel-cees-beta/
#module load gcc-cees-beta/
#module load mpich-cees-beta/
##
#module load hdf5-cees-beta/
#module load netcdf-c-cees-beta/
#module load netcdf-fortran-cees-beta/
#module load parmetis-cees-beta/
#module load metis-cees-beta/
#  METIS_LIBRARY=${METIS_LIB}
#  METIS_INCLUDE_DIR=${METIS_INC}
##module load eigen-cees-beta
#
# this stack quickly switches up a bunch of modules; builds easi just fine, but then crashes hard and early on
#  hdf5 related problems. also kicks down to openmpi2.0. basically, it's  a mess.
module load gcc/12.
module load openmpi/
module load hdf5/1.12.2
module load netcdf-c/
module load netcdf-fortran/
module load parmetis/
module load metis/
  METIS_ROOT=$(dirname $(dirname $(which ndmetis)))
  METIS_LIBRARY=${METIS_ROOT}/lib
  METIS_INCLUDE_DIR=${METIS_ROOT}/include
#
# use these modules for both Sherlock and cees-beta stack
module load eigen/3.4
module load libxsmm
module load yaml-cpp/0.7.0
#
module load cmake/
module load lua/
#
#exit 42
#module load gcc-cees-beta/
# for GNU:
#export PATH=$HOME/bin:$PATH
#export LIBRARY_PATH=$HOME/lib:$LIBRARY_PATH
#export LD_LIBRARY_PATH=$HOME/lib:$LD_LIBRARY_PATH
#export PKG_CONFIG_PATH=$HOME/lib/pkgconfig:$PKG_CONFIG_PATH
#export CMAKE_PREFIX_PATH=$HOME
#export EDITOR=vi
#export CPATH=$HOME/include:$CPATH
#
# For intel compiler
# source /opt/intel/compiler/VERSION/bin/compilervars.sh intel64
# Intel:
#CC=icc
#CXX=cxx
#FC=ifort
#MPICC=mpicc
#MPICXX=mpicxx
#MPIFC=mpif90
#
# GCC
CC=gcc
CXX=g++
FC=gfortran
MPICC=mpicc
MPICXX=mpicxx
MPIFC=mpif90
#
ROOT_PATH=`pwd`
SW_PREFIX="`pwd`/seissol"
CMAKE_PP=$SCRATCH/.local/seissol
PKG_CFG=${CMAKE_PP}/lib/pkgconfig
SW_TARGET_PATH=${ROOT_PATH}/.local
#
#METIS_LIBRARY=${PARMETIS_ROOT}/lib
#METIS_INCLUDE_DIR=${PARMETIS_ROOT}/include
#
#PSpaMM:
if [[ ! -d PSpaMM ]]; then
	git clone https://github.com/SeisSol/PSpaMM.git
	# make sure $HOME/bin exists or create it with "mkdir ~/bin"
	#ln -s $(pwd)/PSpaMM/pspamm.py $HOME/bin/pspamm.py
fi
export PATH=`pwd`/PSpaMM:$PATH

#EASI (and friends):
# https://easyinit.readthedocs.io/en/latest/getting_started.html
# TODO (this should be done, but needs testing. keep a close eye on compiler name variables).:
#yaml-cpp (dependency):
# (load sherlock module)
#if [[ ! -d yuaml-cpp ]]; then
#	git clone --recursive git@github.com:jbeder/yaml-cpp.git
#fi
## (then see install instructions)
#cd yaml-cpp
#rm -rf build
#mkdir build
## ?? -DCMAKE_PREFIX= ??
##cmake -DYAML_BUILD_SHARED_LIBS=on
#cd build
#CC=icc CXX=icpc FC=ifort MPICC=mpicc MPICXX=MPICXX MPIFC=mpif90 cmake -DYAML_BUILD_SHARED_LIBS=on -DCMAKE_INSTALL_PREFIX=$CMAKE_PP:$CMAKE_INSTALL_PREFIX ../
##cd build
#make -j ${SLURM_CPUS_PER_TASK}
#make -j ${SLURM_CPUS_PER_TASK} install
## end yaml-cpp
#
# TODO:
#EASI:

if [[ ! -d easi ]]; then
  # https://easyinit.readthedocs.io/en/latest/getting_started.html
  git clone --recursive git@github.com:SeisSol/easi.git
fi
EASI_PATH=${SW_TARGET_PATH}/easi
if [[ 1 -eq 1 ]]; then
  cd easi
  rm -rf $EASI_PATH
  rm -rf build
  mkdir build
  cd build
  # there is an error/ommission in the yaml-cpp module. For now, we'll hard(ish) cod it:
  CC=$CC CXX=$CXX FC=$FC MPICC=$MPICC MPICXX=$MPICXX MPIFC=$MPIF90 cmake  -DCMAKE_INSTALL_PREFIX=${EASI_PATH} -DASAGI=OFF -DIMPALAJIT=OFF -DLUA=ON -DBUILD_SHARED_LIBS=on ../
  make -j ${SLURM_CPUS_PER_TASK} install
fi
#
CMAKE_PREFIX_PATH=${EASI_PATH}/lib64/cmake/easi:${CMAKE_PREFIX_PATH}
LD_LIBRARY_PATH=${EASI_PATH}/lib64:${LD_LIBRARY_PATH}
CPATH=${EASI_PATH}/include:${EASI_PATH}/include/easi:${CPATH}
#
#CMAKE_PREFIX_PATH="/share/software/user/open/yaml-cpp/0.7.0/share/cmake/yaml-cpp:${CMAKE_PREFIX_PATH}"
#CPATH="/share/software/user/open/yaml-cpp/0.7.0/include/yaml-cpp:${CPATH}"
#LD_LIBRARY_PATH="/share/software/user/open/yaml-cpp/0.7.0/lib64:${LD_LIBRARY_PATH}"
#LIBRARY_PATH="/share/software/user/open/yaml-cpp/0.7.0/lib64:${LIBRARY_PATH}"
#YAML_CPP_INCLUDE_DIR="/share/software/user/open/yaml-cpp/0.7.0/include/yaml-cpp"
#
cd $ROOT_PATH

#exit 42

#
# SeisSol:
if [[ ! -d SeisSol ]]; then
  git clone https://github.com/SeisSol/SeisSol.git
fi
cd SeisSol
git submodule update --init

echo "and do the cmake..."

rm -rf build-release
mkdir build-release

cd build-release
#
#exit 42
#
#CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH_EASI}:${EASI_PATH}/lib64/cmake/easi:${CMAKE_PREFIX_PATH}
#CMAKE_PREFIX_PATH=${EASI_PATH}/lib64/cmake/easi:${CMAKE_PREFIX_PATH}

echo "CMAKE_PREFIX_PATH: $CMAKE_PREFIX_PATH"
echo "PARMETIS: ${PARMETIS_LIB} :: ${PARMETIS_INC}"
echo "METIS: ${METIS_LIB} :: $ ${METIS_INC}"
echo "*** *** "
echo "LD_LIBRARY_PATH: ${LD_LIBRARY_PATH}"
echo "*** *** "
echo "CPATH: ${CPATH}"
#
# allowed HOST_ARCH=noarch;wsm;snb;hsw;knc;knl;skx;rome;thunderx2t99;power9
#exit 42

# modify CMAKE_PREFIX_PATHS?
#CC=$MPICC CXX=$MPICXX FC=$MPIF90  CMAKE_PREFIX_PATH=$CMAKE_PP:$CMAKE_PREFIX_PATH PKG_CONFIG_PATH=${PKG_CFG}:$PKG_CONFIG_PATH cmake -DNETCDF=ON -DMETIS=ON -DCOMMTHREAD=ON -DASAGI=OFF -DHDF5=ON -DCMAKE_BUILD_TYPE=Release -DTESTING=OFF  -DLOG_LEVEL=warning -DLOG_LEVEL_MASTER=info -DHOST_ARCH=skx -DPRECISION=double ..

METIS_LIBRARY=${METIS_LIBRARY} METIS_INCLUDE_DIR=${METIS_INCLUDE_DIR} CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH} LD_LIBRARY_PATH=$LD_LIBRARY_PATH LIBRARY_PATH=$LIBRARY_PATH CPATH=$CPATH CC=$MPICC CXX=$MPICXX FC=$MPIF90 cmake -DNETCDF=ON -DMETIS=ON -DCOMMTHREAD=ON -DASAGI=OFF -DHDF5=ON -DCMAKE_BUILD_TYPE=Release -DTESTING=OFF  -DLOG_LEVEL=warning -DLOG_LEVEL_MASTER=info -DHOST_ARCH=noarch -DPRECISION=double ..
make -j ${SLURM_CPUS_PER_TASK} VERBOSE=1

