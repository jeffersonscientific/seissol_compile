#!/bin/bash
#
#SBATCH --job-name=ss_spack_install
#SBATCH --output=ss_installer_%j.out
#SBATCH --error=ss_installer_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --time=12:00:00
#SBATCH --partition=serc
#
ROOT_PATH=`pwd`
SS_ENV='seissol'
NCPUS=16
if [[ ! -z ${SLURM_CPUS_PER_TASK} ]]; then
  NCPUS=${SLURM_CPUS_PER_TASK}
fi

. spack/share/spack/setup-env.sh
spack env activate ${SS_ENV}
#
if [[ ! $? -eq 0 ]]; then
  echo "something broke activating."
  exit 42
fi
#
spack concretize --force -U
#
# we have "install missing compilers=True", but it seem to be an unreliable feature. Eg, it may
#  install the compiler (but maybe install as a compiler and also as a package?), then install
#  a bunch of stuff successfully, then throw a "no compiler defined" error down the way a bit.
#  so let's install out compiler(s) and 'find' them.
#spack install -j $NCPUS gcc

#spack install -j $NCPUS gcc@9.5.0
#spack load gcc@9.5.0
#spack compiler find --scope=env:${SS_ENV}

#spack install -j $NCPUS gcc@12.2.0%gcc@9.5.0
spack install -j $NCPUS gcc@11.2.0
spack load gcc
spack compiler find --scope=env:${SS_ENV}
#
if [[ ! $? -eq 0 ]]; then
  echo "something broke activating."
  exit 42
fi
#
spack concretize --force -U
spack install -j $NCPUS
# ${SLURM_CPUS_PER_TASK}
#
# optional:
spack module lmod refresh --delete-tree -y

