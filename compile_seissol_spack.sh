#!/bin/bash
#
#SBATCH --job-name=compile_seissol
#SBATCH --partition=serc
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --time=12:00:00
#SBATCH --constraint=CPU_MNF:AMD
#SBATCH --output=seissol_spack_compile_%j.out
#SBATCH --error=seissol_spack_compile_%j.err
#
module purge
#
module use /home/groups/s-ees/share/cees/spack_cees/spack/share/spack/lmod_seissol/linux-centos7-x86_64/gcc/12.1.0
module load seissol/
module load cmake-seissol/

#module load system math
#module load gcc/12.1.0
##
#module load python-seissol/
#module load cmake-seissol/
#module load metis-seissol/
#module load eigen-seissol/
## also available on Sherlock system. Maybe we'll see if we
##  can add those as external packages to streamline?
#module load libxsmm-seissol/
#module load yaml-cpp-seissol/
#module load lua-seissol/
## yoder, 30 sept:
#module load bison-seissol/
#module load flex-seissol/
##
## MPI and deps:
#module load mpich-seissol/
#module load hdf5-seissol/
#module load netcdf-c-seissol/
#module load parmetis-seissol/
#module load asagi-seissol/
#
#COMPILE_ARCH="hsw"
COMPILE_ARCH="rome"
SS_ORDER=6
#
echo "DIAG: $(which gcc) :: $(which g++)"
DO_LIBXSMM=0
DO_PSPAMM=0
DO_EASI=0
DO_IMPALA=0
DO_PUMGEN=0
DO_SEISSOL=1
#
SS_EQNS="elastic"
#SS_EQNS="viscoelastic2"
#
while getopts a:o:p:P:e:E:i:s:x:h flg
do
  case "$flg" in
    a) COMPILE_ARCH=${OPTARG};;
    o) SS_ORDER=${OPTARG};;
    p) DO_PSPAMM=${OPTARG};;
    P) DO_PUMGEN=${OPTARG};;
    e) DO_EASI=${OPTARG};;
    i) DO_IMPALA=${OPTARG};;
    s) DO_SEISSOL=${OPTARG};;
    x) DO_LIBXSMM=${OPTARG};;
    E) SS_EQNS=${OPTARG};;
    h) echo "-a vl (ss arch), -o vl (ss order), -p (do_pspam), -e (do_easi), -i (do_impala), -s) (do_seissol), -x (do libxmss), -h (display this message)."
  esac
done
#
SS_EQNS_STR="-DEQUATIONS=elastic"
case ${SS_EQNS} in
  "viscoelastic2") SS_EQNS_STR=" -DEQUATIONS=viscoelastic2 -DNUMBER_OF_MECHANISMS=3 ";;
  *) SS_EQNS_STR="-DEQUATIONS=elastic";;
esac
#
echo "**DIAG: COMPILE_ARTCH=${COMPILE_ARCH}, SS_ORDER=${SS_ORDER}, DO_SPAMM=${DO_PSPAMM}, DO_EASI=${DO_EASI}, DO_IMPALA=${DO_IMPALA}, DO_SEISSOL=${DO_SEISSOL}, DO_LIBXSMM=${DO_LIBXSMM}, SS_EQNS_STR=${SS_EQNS_STR}"
#module list

#exit 42


# GCC
CC=gcc
CXX=g++
FC=gfortran
MPICC=mpicc
MPICXX=mpicxx
MPIFC=mpif90
#
ROOT_PATH=`pwd`
BUILD_PATH=$(dirname $ROOT_PATH)/SS_build
#SW_PREFIX="`pwd`/seissol"
CMAKE_PP=$SCRATCH/.local/seissol
PKG_CFG=${CMAKE_PP}/lib/pkgconfig
#SW_TARGET_PATH=${BUILD_PATH}/.local
SEISSOL_VER="1.0.1"
SEISSOL_TARGET_PREFIX="/home/groups/s-ees/share/cees/software/no_arch/seissol/${SEISSOL_VER}"
#SEISSOL_TARGET_PREFIX="${BUILD_PATH}/local/seissol/${SEISSOL_VER}"
export CPATH=${SEISSOL_TARGET_PREFIX}/include:${CPATH}
export LD_LIBRARY_PATH=${SEISSOL_TARGET_PREFIX}/lib:${SEISSOL_TARGET_PREFIX}/lib64:${LD_LIBRARY_PATH}
export LIBRARY_PATH=${SEISSOL_TARGET_PREFIX}/lib:${SEISSOL_TARGET_PREFIX}/lib64:${LIBRARY_PATH}
export PATH=${SEISSOL_TARGET_PREFIX}/bin:${PATH}
#
METIS_ROOT=$(dirname $(dirname $(which ndmetis)))
METIS_LIBRARY=${METIS_ROOT}/lib
METIS_INCLUDE_DIR=${METIS_ROOT}/include
#
# we don't alwasy want to do this, but for a clean start...
#rm -rf ${SEISSOL_TARGET_PREFIX}
#mkdir ${SEISSOL_TARGET_PREFIX}
for dr in lib bin include
do
  if [[ ! -d ${SEISSOL_TARGET_PREFIX}/$dr ]]; then
    mkdir -p ${SEISSOL_TARGET_PREFIX}/$dr
  fi
done
#
if [[ ! -d ${BUILD_PATH} ]]; then
  mkdir -p ${BUILD_PATH}
fi
#
cd ${BUILD_PATH}
if [[ $DO_LIBXSMM == 1 ]]; then
  if [[ ! -d libxsmm ]]; then
    #git clone https://github.com/hfp/libxsmm
    git clone --branch 1.17 https://github.com/hfp/libxsmm
  fi
  #
  cd libxsmm
  make clean
  CFLAGS=-fPIC CXXFLAGS=-fPIC make -j generator
  #
  cp -rf bin/* ${SEISSOL_TARGET_PREFIX}/bin/
  cp -rf lib/* ${SEISSOL_TARGET_PREFIX}/lib/
  cp -rf include/* ${SEISSOL_TARGET_PREFIX}/include/
  
  #
fi
#
cd ${BUILD_PATH}
if [[ $DO_PSPAMM == 1 ]]; then
  #PSpaMM:
  if [[ ! -d PSpaMM ]]; then
    git clone https://github.com/SeisSol/PSpaMM.git
    # make sure $HOME/bin exists or create it with "mkdir ~/bin"
    #ln -s $(pwd)/PSpaMM/pspamm.py $HOME/bin/pspamm.py
  fi
  #export PATH=`pwd`/PSpaMM:$PATH
  cp -rf PSpaMM ${SEISSOL_TARGET_PREFIX}/bin
fi

cd ${BUILD_PATH}
# ImpalaJIT:
if [[ $DO_IMPALA == 1 ]]; then
  # TODO: figure out an install PREFIX.
  #   For now, let's put everything in the seissol path.
  # also requires bison, flex which can (presumably) be build in Spack (see new modules added).
  if [[ ! -d ImpalaJIT ]]; then
    git clone --recursive git@github.com:uphoffc/ImpalaJIT.git
  fi
  #
  IMPALA_PATH=${SEISSOL_TARGET_PREFIX}
  if [[ 1 -eq 1 ]]; then
    cd ImpalaJIT
    rm -rf build
    mkdir build
    cd build
    CFLAGS=-fPIC CXXFLAGS=-fPIC CC=$CC CXX=$CXX FC=$FC MPICC=$MPICC MPICXX=$MPICXX MPIFC=$MPIF90 cmake ../ -DCMAKE_INSTALL_PREFIX=${IMPALA_PATH}
    CFLAGS=-fPIC CXXFLAGS=-fPIC make -j ${SLURM_CPUS_PER_TASK}
    make -j ${SLURM_CPUS_PER_TASK} install
  fi
#
fi
################
#
cd ${BUILD_PATH}
# NOTE: this could also be accompilished via submodule...
if [[ $DO_EASI == 1 ]]; then
  #EASI:
  if [[ ! -d easi ]]; then
    # https://easyinit.readthedocs.io/en/latest/getting_started.html
    git clone --recursive git@github.com:SeisSol/easi.git
  fi
  #
  EASI_PATH=${SEISSOL_TARGET_PREFIX}
  if [[ 1 -eq 1 ]]; then
    cd easi
    rm -rf build
    mkdir build
    cd build
    # there is an error/ommission in the yaml-cpp module. For now, we'll hard(ish) cod it:
    CFLAGS=-fPIC CXXFLAGS=-fPIC CC=$CC CXX=$CXX FC=$FC MPICC=$MPICC MPICXX=$MPICXX MPIFC=$MPIF90 cmake -DCMAKE_INSTALL_PREFIX=${EASI_PATH} -DASAGI=ON -DIMPALAJIT=ON -DLUA=ON -DBUILD_SHARED_LIBS=ON ../
    CFLAGS=-fPIC CXXFLAGS=-fPIC make -j ${SLURM_CPUS_PER_TASK} install
  fi
  #
  CMAKE_PREFIX_PATH=${EASI_PATH}/lib64/cmake/easi:${CMAKE_PREFIX_PATH}
  LD_LIBRARY_PATH=${EASI_PATH}/lib64:${LD_LIBRARY_PATH}
  CPATH=${EASI_PATH}/include:${EASI_PATH}/include/easi:${CPATH}
fi
#############################
# PUMGEN
# TODO: check and test this...
cd ${BUILD_PATH}
#
if [[ ${DO_PUMGEN} ]]; then
  PUMGEN_BUILD_DIR=${BUILD_PATH}/PUMGen
  PUMGEN_PREFIX=${SEISSOL_TARGET_PREFIX}
  # with the gmsh and pumi dependencies installed via Spack, this appears to be an easy build. Should still sort out the prefixes and stuff, but cmake, make should do the trick.
  # git clone PUMGEN
  #
  #if [[ -d ${PUMGEN_BUILD_DIR} ]]; then
  #  rm -rf ${PUMGEN_BUILD_DIR}
  #fi
  #
  if [[ ! -d ${PUMGEN_BUILD_DIR} ]]; then
    # clone PUMGEN. NOTE: this will probably require a bunch of SSH key passphrase query-responses, so will not batch.
    git clone --recursive git@github.com:SeisSol/PUMGen.git
  fi
  cd ${PUMGEN_BUILD_DIR}
  if [[ -d build ]]; then
    rm -rf build
  fi
  mkdir build
  cd build
  #
  cmake ../ -DCMAKE_INSTALL_PREFIX=${PUMGEN_PREFIX}
  make -j ${SLURM_CPUS_PER_TASK}
  make -j ${SLURM_CPUS_PER_TASK} install
fi
#############################
#
cd ${BUILD_PATH}
# NOTE: this could also be accompilished via submodule...
if [[ $DO_SEISSOL == 1 ]]; then
  # SeisSol:
  if [[ ! -d SeisSol ]]; then
    git clone https://github.com/SeisSol/SeisSol.git
  fi
  cd SeisSol
  git submodule update --init
  #
  echo "and do the cmake..."
  #
  rm -rf build-release
  mkdir build-release
  #
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

  METIS_LIBRARY=${METIS_LIBRARY} METIS_INCLUDE_DIR=${METIS_INCLUDE_DIR} CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH} LD_LIBRARY_PATH=$LD_LIBRARY_PATH LIBRARY_PATH=$LIBRARY_PATH CPATH=$CPATH CC=$MPICC CXX=$MPICXX FC=$MPIF90\
   cmake -DNETCDF=ON -DMETIS=ON -DASAGI=ON -DCMAKE_BUILD_TYPE=Release -DHOST_ARCH=${COMPILE_ARCH} -DPRECISION=double -DORDER=${SS_ORDER} -DHDF5=ON -DTESTING=OFF  -DLOG_LEVEL=warning -DLOG_LEVEL_MASTER=info -DCMAKE_INSTALL_PREFIX=${SEISSOL_TARGET_PREFIX} -DCOMMTHREAD=ON  -DNUMA_AWARE_PINNING=ON -DGEMM_TOOLS_LIST=LIBXSMM,PSpaMM\
   ${SS_EQNS_STR}\
    ..
   
  # -DGEMM_TOOLS_LIST=LIBXSMM,PSpaMM,eigen  -DCOMMTHREAD=ON  -DNUMA_AWARE_PINNING=ON
  #

  # for SuperMUC-NG:
  #cmake -DCOMMTHREAD=ON -DNUMA_AWARE_PINNING=ON -DASAGI=ON -DCMAKE_BUILD_TYPE=Release -DHOST_ARCH=skx -DPRECISION=double -DORDER=4 -DGEMM_TOOLS_LIST=LIBXSMM,PSpaMM ..

  make -j ${SLURM_CPUS_PER_TASK} VERBOSE=1
  #
  # copy executable to target path?
  cp SeisSol_* ${SEISSOL_TARGET_PREFIX}/bin/
fi


