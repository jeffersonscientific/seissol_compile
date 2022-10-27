#!/bin/bash
#
#
#SBATCH --job-name=compile_seissol
#SBATCH --partition=serc,normal
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --time=12:00:00
#SBATCH --constraint=CPU_MNF:AMD
#SBATCH --output=spack_build_env_%j.out
#SBATCH --error=spack_build_env_%j.err
#
if [[ -z $1 ]]; then
  echo "** ERROR: Must provide an environmant"
  echo "usage:"
  echo "./install_spack_env.sh \{env_name\}"
  exit 42
fi
ENV_NAME=$1
NCPUS=2
if [[ ! -z ${SLURM_CPUS_PER_TASK} ]]; then
  NCPUS=$((${SLURM_CPUS_PER_TASK}*2))
fi

#. /home/groups/s-ees/share/cees/spack_cees/scripts/cees_sw_setup-beta.sh
#
#module purge
#
#module load system math
#
##module load intel-cees-beta/
#module load gcc-cees-beta/
#module load mpich-cees-beta/
#
# assume we're above our spack setup
. spack/share/spack/setup-env.sh
#
spack env activate ${ENV_NAME}
spack concretize --force -U
spack install -j $NCPUS
